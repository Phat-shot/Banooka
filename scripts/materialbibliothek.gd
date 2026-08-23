extends RefCounted
class_name Materialbibliothek
## Zentrale, prozedurale Material- und Texturbibliothek.
##
## Alle Texturen werden zur Laufzeit erzeugt, es werden also keine fremden
## Bilddateien benötigt – alles ist Eigenbau und damit lizenzfrei
## (siehe assets/CREDITS.md).
##
## Aufbau einer Textur: `FastNoiseLite` liefert in C++ mehrere kachelbare
## Rauschbilder (fraktal, zellular, gerichtet gestreckt). Die werden hier
## byteweise zu Albedo-, Höhen-, Rauheits- und Verdeckungskarten
## verrechnet. Aus der Höhenkarte entsteht per Sobel-Filter eine echte
## Normalmap. Dadurch bekommen die Oberflächen erkennbare Struktur
## (Kies im Weg, Schichtung im Fels, Furchen in der Rinde, Bretter am
## Holz) statt nur weichem Rauschen.
##
## Die Materialien werden zwischengespeichert und von allen Objekten
## gemeinsam genutzt. Nie `Materialbibliothek`-Rückgaben verändern,
## sondern bei Bedarf `.duplicate()` aufrufen.
##
## Renderer: `gl_compatibility`. Es werden nur Funktionen von
## `StandardMaterial3D` benutzt, die dort ankommen.

static var _cache: Dictionary = {}

const _B := 1.0 / 255.0   ## Byte -> 0..1


static func _hole(schluessel: String, erzeuger: Callable) -> Variant:
	if not _cache.has(schluessel):
		_cache[schluessel] = erzeuger.call()
	return _cache[schluessel]


# ------------------------------------------------------------ Rauschquellen

## Fraktales Rauschen als kachelbares Graustufenfeld (ein Byte je Pixel).
static func _fbm(saat: int, frequenz: float, oktaven: int, kante: int,
		warp: float = 0.0, typ: int = FastNoiseLite.TYPE_SIMPLEX) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = typ
	r.frequency = frequenz
	r.fractal_octaves = oktaven
	r.fractal_gain = 0.5
	r.fractal_lacunarity = 2.0
	if warp > 0.0:
		r.domain_warp_enabled = true
		r.domain_warp_amplitude = warp
		r.domain_warp_frequency = frequenz * 0.6
		r.domain_warp_fractal_octaves = 2
	return r.get_seamless_image(kante, kante, false, false, 0.1).get_data()


## Zellrauschen – Grundlage für Kies, Blätter, Bruchkanten und Blattwerk.
## `rueckgabe` ist eine `FastNoiseLite.CellularReturnType`-Konstante.
static func _zellen(saat: int, frequenz: float, kante: int, rueckgabe: int,
		warp: float = 0.0, jitter: float = 1.0) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_CELLULAR
	r.frequency = frequenz
	r.fractal_type = FastNoiseLite.FRACTAL_NONE
	r.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	r.cellular_return_type = rueckgabe
	r.cellular_jitter = jitter
	if warp > 0.0:
		r.domain_warp_enabled = true
		r.domain_warp_amplitude = warp
		r.domain_warp_frequency = frequenz * 0.9
		r.domain_warp_fractal_octaves = 2
	return r.get_seamless_image(kante, kante, false, false, 0.05).get_data()


## Gerichtet gestrecktes Rauschen: Streifen für Bretter, Rinde, Halme,
## gebürstetes Metall und Fell. Erzeugt wird ein kleineres kachelbares
## Feld, das anschließend in C++ auf die volle Kantenlänge gezogen wird –
## dadurch bleibt die Kachelung erhalten und es kostet fast nichts.
static func _gestreckt(saat: int, frequenz: float, oktaven: int, kante: int,
		dehnung_x: int, dehnung_y: int) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX
	r.frequency = frequenz
	r.fractal_octaves = oktaven
	var bild := r.get_seamless_image(maxi(8, kante / dehnung_x),
			maxi(8, kante / dehnung_y), false, false, 0.1)
	bild.resize(kante, kante, Image.INTERPOLATE_BILINEAR)
	return bild.get_data()


# ------------------------------------------------------------ Kartenbau

## Baut aus RGB-Bytes eine Textur mit Mipmaps (gegen Flimmern in der Ferne).
static func _farbtextur(daten: PackedByteArray, kante: int) -> ImageTexture:
	var bild := Image.create_from_data(kante, kante, false, Image.FORMAT_RGB8, daten)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Baut aus Graustufen-Bytes eine Textur (Rauheit, Verdeckung, Metallanteil).
static func _grautextur(daten: PackedByteArray, kante: int) -> ImageTexture:
	var bild := Image.create_from_data(kante, kante, false, Image.FORMAT_L8, daten)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Sobel-Filter über die Höhenkarte – ergibt eine echte Normalmap.
## `staerke` steuert, wie plastisch die Oberfläche wirkt.
static func _normal_aus_hoehe(hoehe: PackedByteArray, kante: int,
		staerke: float) -> ImageTexture:
	var aus := PackedByteArray()
	aus.resize(kante * kante * 3)
	var f := staerke * _B
	var i := 0
	for y in kante:
		var zo := ((y + kante - 1) % kante) * kante
		var zu := ((y + 1) % kante) * kante
		var zm := y * kante
		for x in kante:
			var xl := (x + kante - 1) % kante
			var xr := (x + 1) % kante
			var dx := float(hoehe[zm + xr] - hoehe[zm + xl]) * f
			var dy := float(hoehe[zu + x] - hoehe[zo + x]) * f
			var l := 1.0 / sqrt(dx * dx + dy * dy + 1.0)
			aus[i] = int(127.5 - dx * l * 127.0)
			aus[i + 1] = int(127.5 - dy * l * 127.0)
			aus[i + 2] = int(127.5 + l * 127.0)
			i += 3
	var bild := Image.create_from_data(kante, kante, false, Image.FORMAT_RGB8, aus)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Hängt Normal-, Rauheits- und Verdeckungskarte an ein Material.
static func _karten_setzen(m: StandardMaterial3D, hoehe: PackedByteArray,
		rau: PackedByteArray, ao: PackedByteArray, kante: int,
		normal_staerke: float, normal_skala: float = 1.0) -> void:
	m.normal_enabled = true
	m.normal_texture = _normal_aus_hoehe(hoehe, kante, normal_staerke)
	m.normal_scale = normal_skala
	m.roughness_texture = _grautextur(rau, kante)
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = 1.0
	m.ao_enabled = true
	m.ao_texture = _grautextur(ao, kante)
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.ao_light_affect = 0.25
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


# ------------------------------------------------------------ Alte Schnittstelle

## Erzeugt eine kachelbare Rauschtextur mit Farbverlauf.
## (Weiterhin für einfache Fälle und Fremdaufrufe vorhanden.)
static func rauschtextur(saat: int, frequenz: float, farbe_a: Color, farbe_b: Color,
		groesse: int = 256, typ: int = FastNoiseLite.TYPE_SIMPLEX) -> NoiseTexture2D:
	var rauschen := FastNoiseLite.new()
	rauschen.noise_type = typ
	rauschen.seed = saat
	rauschen.frequency = frequenz
	rauschen.fractal_octaves = 4

	var verlauf := Gradient.new()
	verlauf.set_color(0, farbe_a)
	verlauf.set_color(1, farbe_b)

	var textur := NoiseTexture2D.new()
	textur.width = groesse
	textur.height = groesse
	textur.seamless = true
	textur.generate_mipmaps = true
	textur.noise = rauschen
	textur.color_ramp = verlauf
	return textur


## Erzeugt eine passende Normalmap aus demselben Rauschen.
static func normalmap(saat: int, frequenz: float, staerke: float = 2.0,
		groesse: int = 256) -> NoiseTexture2D:
	var rauschen := FastNoiseLite.new()
	rauschen.noise_type = FastNoiseLite.TYPE_SIMPLEX
	rauschen.seed = saat
	rauschen.frequency = frequenz
	rauschen.fractal_octaves = 4

	var textur := NoiseTexture2D.new()
	textur.width = groesse
	textur.height = groesse
	textur.seamless = true
	textur.generate_mipmaps = true
	textur.noise = rauschen
	textur.as_normal_map = true
	textur.bump_strength = staerke
	return textur


# ---------------------------------------------------------------- Basis

## Einfarbiges Material ohne Textur (für kleine Objekte und Effekte).
static func einfarbig(farbe: Color, rauheit: float = 0.9,
		metallisch: float = 0.0) -> StandardMaterial3D:
	var schluessel := "einfarbig_%s_%.2f_%.2f" % [farbe.to_html(), rauheit, metallisch]
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.roughness = rauheit
		m.metallic = metallisch
		return m)


## Selbstleuchtendes Material für Effekte, Portale und Sammelobjekte.
static func leuchtend(farbe: Color, staerke: float = 1.2) -> StandardMaterial3D:
	var schluessel := "leucht_%s_%.2f" % [farbe.to_html(), staerke]
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = staerke
		m.roughness = 0.4
		return m)


## Durchscheinendes Material (Portale, Wasserflächen, Schockwellen).
static func transparent(farbe: Color, leuchten: float = 0.8) -> StandardMaterial3D:
	var schluessel := "transp_%s_%.2f" % [farbe.to_html(), leuchten]
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = farbe
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = leuchten
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		return m)


# ---------------------------------------------------------------- Sumpf

## Torfboden: nass, dunkel, mit Algenschlieren. Bewusst dunkler als der
## Waldweg – der Steg darüber soll sich klar abheben.
static func moorboden() -> StandardMaterial3D:
	return _hole("moorboden", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(7201, 0.030, Farben.MOOR_DUNKEL, Farben.MOOR_HELL)
		m.normal_enabled = true
		m.normal_texture = normalmap(7201, 0.075, 1.8)
		m.normal_scale = 0.9
		m.roughness = 0.72
		return m)


## Verwittertes Stegholz mit langer Maserung. Die gestreckte UV-Skala legt
## die Maserung längs, damit Bohlen als Bohlen zu erkennen sind.
static func bohlen() -> StandardMaterial3D:
	return _hole("bohlen", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(7202, 0.055,
				Farben.BOHLE.darkened(0.35), Farben.BOHLE.lightened(0.22))
		m.normal_enabled = true
		m.normal_texture = normalmap(7202, 0.11, 1.6)
		m.normal_scale = 0.8
		m.uv1_scale = Vector3(0.45, 2.4, 0.45)
		m.roughness = 0.88
		return m)


## Algenteppich für Uferkanten und schwimmende Inseln.
static func algen() -> StandardMaterial3D:
	return _hole("algen", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(7203, 0.070, Farben.TUEMPEL, Farben.ALGE)
		m.normal_enabled = true
		m.normal_texture = normalmap(7203, 0.16, 1.2)
		m.normal_scale = 0.6
		m.roughness = 0.65
		return m)


# ---------------------------------------------------------------- Winter

## Pulverschnee für die Wegdecke: fast weiß, mit blauen Mulden. Die
## Normalmap ist bewusst kräftig – flacher Schnee sieht sonst aus wie
## weißes Papier, sobald die Sonne flach steht.
static func schnee() -> StandardMaterial3D:
	return _hole("schnee", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(6101, 0.010,
				Farben.SCHNEE_SCHATTEN.lerp(Farben.SCHNEE, 0.45), Farben.SCHNEE_HELL)
		m.normal_enabled = true
		m.normal_texture = normalmap(6101, 0.035, 1.4)
		m.normal_scale = 0.85
		m.uv1_scale = Vector3(0.7, 0.7, 0.7)
		m.roughness = 0.86
		return m)


## Festgetretener Firn für Kanten und Plattformen – körniger und etwas
## dunkler als die Wegdecke, damit sich die Ränder absetzen.
static func firn() -> StandardMaterial3D:
	return _hole("firn", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(6102, 0.045,
				Farben.SCHNEE_SCHATTEN.darkened(0.12), Farben.FIRN)
		m.normal_enabled = true
		m.normal_texture = normalmap(6102, 0.09, 2.2)
		m.normal_scale = 1.0
		m.roughness = 0.78
		return m)


## Schluchtwand aus altem Gletschereis: tiefblau, schrundig, mit hellen
## Kanten. Das ist die Gegenfarbe zum fast weißen Weg – ohne sie
## verschwimmt in einem Schneelevel alles zu einer Fläche.
static func eisfels() -> StandardMaterial3D:
	return _hole("eisfels", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		# Die Kachelung ist zweimal danebengegangen: uv1_scale 0.35 ergab
		# eine blaue Schmiere über den halben Bildschirm, 2.2 ein feines
		# Rauschen ohne Struktur. 1.0 mit grobem Grundrauschen zeigt große
		# Eisformen und behält trotzdem Zeichnung.
		m.albedo_texture = rauschtextur(6104, 0.035, Farben.EIS_TIEF.darkened(0.3),
				Farben.EIS_HELL)
		m.normal_enabled = true
		# Die Normalmap darf jetzt zurücktreten: Die Terrassen der Wand
		# liefern die Form, ein starkes Relief obendrauf ergab nur Flimmern.
		m.normal_texture = normalmap(6104, 0.03, 1.6)
		m.normal_scale = 0.7
		m.uv1_scale = Vector3(0.8, 0.8, 0.8)
		m.roughness = 0.5
		return m)


## Frostfels für Vorsprünge und Blöcke – kühler als der Waldfels, damit er
## im Schnee nicht braun aussieht.
static func frostfels() -> StandardMaterial3D:
	return _hole("frostfels", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(6105, 0.05, Farben.FROSTFELS.darkened(0.4),
				Farben.FROSTFELS.lightened(0.3))
		m.normal_enabled = true
		m.normal_texture = normalmap(6105, 0.12, 2.2)
		m.normal_scale = 1.0
		m.roughness = 0.72
		return m)


## Leuchtender Kristall: durchscheinend und selbstleuchtend zugleich.
static func kristall(farbe: Color) -> StandardMaterial3D:
	return _hole("kristall_%s" % farbe.to_html(), func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(farbe.r, farbe.g, farbe.b, 0.72)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = 1.5
		m.roughness = 0.1
		m.metallic_specular = 0.9
		return m)


## Blankes Eis: glatt und leicht durchscheinend. Kein Spiegel – der
## Renderer gl_compatibility hat keine Bildschirmspiegelung, ein hoher
## Metallwert sähe hier nur grau aus.
static func eis() -> StandardMaterial3D:
	return _hole("eis", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(6103, 0.018, Farben.EIS_DUNKEL, Farben.EIS_HELL)
		m.albedo_color = Color(1, 1, 1, 0.86)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.normal_enabled = true
		m.normal_texture = normalmap(6103, 0.020, 0.7)
		m.normal_scale = 0.4
		m.roughness = 0.12
		m.metallic = 0.15
		m.metallic_specular = 0.85
		return m)


# ---------------------------------------------------------------- Umgebung

## Waldweg: warme, festgetretene Waldboden-Erde mit eingestreuten Steinen,
## Kies und angedeuteten Trampelspuren. Bewusst hell und ockerfarben –
## das Himmels-Ambiente zieht dunkle Erde sonst ins Graublaue.
static func waldweg() -> StandardMaterial3D:
	return _hole("waldweg", func() -> StandardMaterial3D: return _baue_waldweg())


static func _baue_waldweg() -> StandardMaterial3D:
	var k := 256
	var gross := _fbm(1101, 0.006, 4, k)
	var mittel := _fbm(1102, 0.024, 4, k, 24.0)
	var fein := _fbm(1103, 0.13, 3, k)
	var korn := _fbm(1104, 0.44, 2, k)
	var stein_d := _zellen(1105, 0.042, k, FastNoiseLite.RETURN_DISTANCE, 6.0)
	var stein_w := _zellen(1105, 0.042, k, FastNoiseLite.RETURN_CELL_VALUE, 6.0)
	var kies_d := _zellen(1106, 0.135, k, FastNoiseLite.RETURN_DISTANCE)
	var kies_w := _zellen(1106, 0.135, k, FastNoiseLite.RETURN_CELL_VALUE)
	# steuert, wo überhaupt Kies liegt – sonst wirkt der Weg wie Mohnkuchen
	var streuung := _fbm(1108, 0.013, 3, k, 16.0)
	# Trampelspur: entlang der Levelachse gestreckte Aufhellung
	var spur := _gestreckt(1107, 0.05, 3, k, 1, 6)

	var d := Farben.WEG_DUNKEL
	var h := Farben.WEG_HELL
	var s0 := Farben.KIES
	var s1 := Farben.KIES_HELL

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var j := 0
	for i in k * k:
		var t := gross[i] * _B
		var mi := mittel[i] * _B
		var f := fein[i] * _B
		var g := korn[i] * _B
		var sp := spur[i] * _B

		# Grundton der Erde – festgetreten in der Spur, lockerer daneben
		var mix := 0.28 * t + 0.42 * mi + 0.18 * f + 0.12 * g
		mix = clampf((mix - 0.23) * 1.95, 0.0, 1.0)
		mix = clampf(mix * (0.82 + 0.34 * sp), 0.0, 1.0)

		var cr := d.r + (h.r - d.r) * mix
		var cg := d.g + (h.g - d.g) * mix
		var cb := d.b + (h.b - d.b) * mix
		var hh := 0.34 + 0.30 * mix + 0.24 * f + 0.12 * g
		var ro := 0.95 - 0.09 * f
		var dichte := clampf((streuung[i] * _B - 0.24) * 2.4, 0.0, 1.0)

		# Grobe Steine im Weg
		var sd := stein_d[i] * _B
		if sd < 0.24:
			var sw := stein_w[i] * _B
			var sel := clampf((sw - 0.46) * 3.2, 0.0, 1.0) * dichte
			var a := clampf((0.24 - sd) * 11.0, 0.0, 1.0) * sel
			if a > 0.0:
				var sn := 0.30 + 0.70 * sw
				var kr := s0.r + (s1.r - s0.r) * sn
				var kg := s0.g + (s1.g - s0.g) * sn
				var kb := s0.b + (s1.b - s0.b) * sn
				cr += (kr - cr) * a
				cg += (kg - cg) * a
				cb += (kb - cb) * a
				hh += (0.42 + 0.26 * sw - hh) * a * 0.9
				ro -= 0.26 * a

		# Feiner Kies / Grus
		var gd := kies_d[i] * _B
		if gd < 0.22:
			var gw := kies_w[i] * _B
			var sel2 := clampf((gw - 0.62) * 3.4, 0.0, 1.0) * dichte
			var a2 := clampf((0.22 - gd) * 13.0, 0.0, 1.0) * sel2 * 0.7
			if a2 > 0.0:
				var kh := 0.46 + 0.36 * gw
				cr += (Farben.KIES_HELL.r * kh + 0.10 - cr) * a2
				cg += (Farben.KIES_HELL.g * kh + 0.09 - cg) * a2
				cb += (Farben.KIES_HELL.b * kh + 0.07 - cb) * a2
				hh += 0.22 * a2
				ro -= 0.14 * a2

		farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
		farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
		farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
		j += 3
		hh = clampf(hh, 0.0, 1.0)
		hoehe[i] = int(hh * 255.0)
		rau[i] = int(clampf(ro, 0.2, 1.0) * 255.0)
		ao[i] = int((0.70 + 0.30 * hh) * 255.0)

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 2.4, 1.4)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.8
	m.uv1_scale = Vector3(0.55, 0.55, 0.55)
	return m


## Grasnarbe: satte Rasenfläche mit Halmstruktur, Büscheln und
## Farbvariation von tiefgrün bis strohig.
static func gras() -> StandardMaterial3D:
	return _hole("gras", func() -> StandardMaterial3D: return _baue_gras())


static func _baue_gras() -> StandardMaterial3D:
	var k := 256
	var gross := _fbm(2201, 0.009, 3, k)
	var klumpen := _zellen(2202, 0.045, k, FastNoiseLite.RETURN_CELL_VALUE, 20.0)
	var halm_a := _gestreckt(2203, 0.13, 2, k, 1, 7)
	var halm_b := _gestreckt(2204, 0.11, 2, k, 7, 1)
	var fein := _fbm(2205, 0.30, 2, k)
	var trocken := _fbm(2206, 0.016, 3, k, 18.0)

	var d := Farben.GRAS_DUNKEL
	var h := Farben.GRAS_HELL
	var tr := Farben.GRAS_TROCKEN

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var j := 0
	for i in k * k:
		var t := gross[i] * _B
		var kl := klumpen[i] * _B
		var a := halm_a[i] * _B
		var b := halm_b[i] * _B
		var f := fein[i] * _B

		# Halme: die stärkere der beiden Richtungen gibt den Strich vor
		var halm := a if a > b else b
		var mix := 0.30 * t + 0.34 * halm + 0.22 * kl + 0.14 * f
		mix = clampf((mix - 0.26) * 2.05, 0.0, 1.0)

		var cr := d.r + (h.r - d.r) * mix
		var cg := d.g + (h.g - d.g) * mix
		var cb := d.b + (h.b - d.b) * mix

		# Strohige Flecken lockern das Einheitsgrün auf
		var tk := clampf((trocken[i] * _B - 0.62) * 3.6, 0.0, 1.0) * 0.75
		if tk > 0.0:
			cr += (tr.r - cr) * tk
			cg += (tr.g - cg) * tk
			cb += (tr.b - cb) * tk

		var hh := clampf(0.20 + 0.52 * halm + 0.18 * kl + 0.16 * f, 0.0, 1.0)
		farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
		farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
		farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
		j += 3
		hoehe[i] = int(hh * 255.0)
		rau[i] = int(clampf(0.98 - 0.14 * mix, 0.5, 1.0) * 255.0)
		ao[i] = int((0.52 + 0.48 * hh) * 255.0)

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 2.0, 1.2)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(0.7, 0.7, 0.7)
	return m


## Waldboden: Erde mit Laubstreu, Moospolstern und offenen Erdflecken.
static func waldboden() -> StandardMaterial3D:
	return _hole("waldboden", func() -> StandardMaterial3D: return _baue_waldboden())


static func _baue_waldboden() -> StandardMaterial3D:
	var k := 256
	var erde := _fbm(3301, 0.020, 4, k, 22.0)
	var fein := _fbm(3302, 0.18, 3, k)
	var moos := _fbm(3303, 0.014, 3, k, 26.0)
	var blatt_w := _zellen(3304, 0.070, k, FastNoiseLite.RETURN_CELL_VALUE, 26.0)
	var blatt_k := _zellen(3304, 0.070, k, FastNoiseLite.RETURN_DISTANCE2_SUB, 26.0)
	var streu := _fbm(3305, 0.030, 3, k, 20.0)

	var ed := Farben.ERDE_DUNKEL
	var eh := Farben.ERDE_HELL
	var l0 := Farben.LAUBSTREU_ROT
	var l1 := Farben.LAUBSTREU
	var mo := Farben.MOOS
	var mh := Farben.MOOS_HELL

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var j := 0
	for i in k * k:
		var e := erde[i] * _B
		var f := fein[i] * _B

		# Erdgrund
		var mix := clampf((0.62 * e + 0.38 * f - 0.22) * 2.05, 0.0, 1.0)
		var cr := ed.r + (eh.r - ed.r) * mix
		var cg := ed.g + (eh.g - ed.g) * mix
		var cb := ed.b + (eh.b - ed.b) * mix
		var hh := 0.30 + 0.30 * mix + 0.22 * f
		var ro := 0.97 - 0.06 * f

		# Laubstreu: einzelne Blätter aus Zellrauschen, nicht überall
		var bk := blatt_k[i] * _B
		var bw := blatt_w[i] * _B
		var dichte := clampf((streu[i] * _B - 0.34) * 2.6, 0.0, 1.0)
		var ba := clampf((bk - 0.16) * 5.0, 0.0, 1.0) * dichte
		if ba > 0.0:
			var lr := l0.r + (l1.r - l0.r) * bw
			var lg := l0.g + (l1.g - l0.g) * bw
			var lb := l0.b + (l1.b - l0.b) * bw
			var tn := 0.80 + 0.55 * bw
			cr += (lr * tn - cr) * ba
			cg += (lg * tn - cg) * ba
			cb += (lb * tn - cb) * ba
			hh += (0.46 + 0.30 * bw - hh) * ba * 0.85
			ro -= 0.16 * ba

		# Moospolster
		var mk := clampf((moos[i] * _B - 0.60) * 3.4, 0.0, 1.0)
		if mk > 0.0:
			var mn := 0.55 + 0.60 * f
			cr += (mo.r + (mh.r - mo.r) * mn - cr) * mk
			cg += (mo.g + (mh.g - mo.g) * mn - cg) * mk
			cb += (mo.b + (mh.b - mo.b) * mn - cb) * mk
			hh += 0.12 * mk

		farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
		farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
		farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
		j += 3
		hh = clampf(hh, 0.0, 1.0)
		hoehe[i] = int(hh * 255.0)
		rau[i] = int(clampf(ro, 0.4, 1.0) * 255.0)
		ao[i] = int((0.68 + 0.32 * hh) * 255.0)

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 2.4, 1.4)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.6
	m.uv1_scale = Vector3(0.45, 0.45, 0.45)
	return m


## Fels: Grau-Braun mit waagerechter Schichtung, Bruchkanten und
## Flechtenflecken. Kräftige Normalmap, damit Klippen Tiefe bekommen.
static func fels() -> StandardMaterial3D:
	return _hole("fels", func() -> StandardMaterial3D: return _baue_fels())


static func _baue_fels() -> StandardMaterial3D:
	var k := 256
	var grob := _fbm(4401, 0.013, 5, k, 26.0)          # große Blöcke
	var fein := _fbm(4402, 0.12, 3, k)
	var korn := _fbm(4403, 0.50, 2, k)
	var bruch := _zellen(4404, 0.021, k, FastNoiseLite.RETURN_DISTANCE2_SUB, 30.0)
	var laengs := _gestreckt(4405, 0.11, 3, k, 5, 1)   # Zug entlang der Schicht
	var flechte := _fbm(4406, 0.019, 3, k, 26.0)
	var welle := _fbm(4407, 0.009, 3, k)               # verbiegt die Schichtlinien
	var welle2 := _fbm(4408, 0.035, 2, k)              # macht die Dicken ungleich

	var fd := Farben.FELS_DUNKEL
	var fh := Farben.FELS_HELL
	var fw := Farben.FELS_WARM
	var fl := Farben.FLECHTE

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var schichten := 4.4
	var j := 0
	var i := 0
	for y in k:
		var v := float(y) / float(k)
		for x in k:
			var g := grob[i] * _B
			var f := fein[i] * _B
			var n := korn[i] * _B
			var la := laengs[i] * _B

			# Schichtung: Bänder in v-Richtung, vom Rauschen verbogen
			var lage := v * schichten + (welle[i] * _B - 0.5) * 2.4 \
					+ (welle2[i] * _B - 0.5) * 0.75 + (g - 0.5) * 0.45
			var band := lage - floorf(lage)
			var stufe := floorf(lage)
			# scharfe Fuge am Bandanfang, weicher Übergang zum Bandende
			var fuge := maxf(clampf(1.0 - band * 14.0, 0.0, 1.0),
					clampf((band - 0.945) * 14.0, 0.0, 1.0))
			# jede Lage bekommt einen eigenen Grundton
			var lagen_ton := fmod(absf(stufe) * 0.3819, 1.0)

			var mix := clampf((0.38 * g + 0.28 * la + 0.22 * f + 0.12 * n - 0.24) * 1.9,
					0.0, 1.0)
			# ganze Lagen kippen heller oder dunkler – erst das macht die
			# Schichtung aus der Ferne sichtbar
			mix = clampf(mix * (0.60 + 0.62 * lagen_ton) + 0.14 * lagen_ton, 0.0, 1.0)

			var cr := fd.r + (fh.r - fd.r) * mix
			var cg := fd.g + (fh.g - fd.g) * mix
			var cb := fd.b + (fh.b - fd.b) * mix
			# warme, eisenhaltige Lagen
			var warm := clampf((lagen_ton - 0.38) * 2.1, 0.0, 1.0) * 0.85
			cr += (fw.r * (0.62 + 0.72 * mix) - cr) * warm
			cg += (fw.g * (0.62 + 0.72 * mix) - cg) * warm
			cb += (fw.b * (0.62 + 0.72 * mix) - cb) * warm

			# Schichtstufe: jede Lage steht unten leicht vor
			var stufenhoehe := 0.16 * band
			var hh := 0.34 + 0.26 * mix + 0.14 * f + 0.08 * n + stufenhoehe
			var ro := 0.90 - 0.10 * f

			# Bruchkanten – bewusst sparsam, sonst wirkt der Fels wie Kopfsteinpflaster
			var riss := clampf(1.0 - bruch[i] * _B * 4.2, 0.0, 1.0) * 0.55
			riss = maxf(riss, fuge)
			if riss > 0.0:
				var dunkel := 1.0 - 0.52 * riss
				cr *= dunkel
				cg *= dunkel
				cb *= dunkel
				hh -= 0.34 * riss
				ro += 0.08 * riss

			# Flechten
			var lk := clampf((flechte[i] * _B - 0.64) * 3.6, 0.0, 1.0) * (1.0 - riss)
			if lk > 0.0:
				var lt := 0.65 + 0.5 * f
				cr += (fl.r * lt - cr) * lk
				cg += (fl.g * lt - cg) * lk
				cb += (fl.b * lt - cb) * lk
				ro += 0.08 * lk

			farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
			farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
			farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
			j += 3
			hh = clampf(hh, 0.0, 1.0)
			hoehe[i] = int(hh * 255.0)
			rau[i] = int(clampf(ro, 0.4, 1.0) * 255.0)
			ao[i] = int((0.62 + 0.38 * hh) * 255.0)
			i += 1

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 3.0, 1.6)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 2.2
	m.uv1_scale = Vector3(0.34, 0.34, 0.34)
	return m


## Baumrinde: senkrechte Furchen mit Rissplatten, deutlich plastisch.
static func rinde() -> StandardMaterial3D:
	return _hole("rinde", func() -> StandardMaterial3D: return _baue_rinde())


static func _baue_rinde() -> StandardMaterial3D:
	var k := 256
	var furche := _gestreckt(5501, 0.070, 3, k, 1, 5)
	var platte := _gestreckt(5502, 0.028, 2, k, 1, 3)
	var quer := _gestreckt(5503, 0.16, 2, k, 4, 1)
	var fein := _fbm(5504, 0.42, 2, k)
	var moos := _fbm(5505, 0.020, 3, k, 22.0)

	var d := Farben.RINDE_DUNKEL
	var h := Farben.RINDE_HELL
	var mo := Farben.MOOS

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var j := 0
	for i in k * k:
		var fu := furche[i] * _B
		var pl := platte[i] * _B
		var qu := quer[i] * _B
		var f := fein[i] * _B

		# Gratfunktion: aus weichem Rauschen werden scharfe Furchenlinien
		var grat := 1.0 - absf(fu * 2.0 - 1.0)
		grat = grat * grat
		var rippe := 1.0 - absf(pl * 2.0 - 1.0)

		var struktur := clampf(0.62 * (1.0 - grat) + 0.26 * rippe + 0.12 * f, 0.0, 1.0)
		# Querrisse brechen die Längsstruktur auf
		struktur *= 0.72 + 0.38 * qu
		struktur = clampf((struktur - 0.18) * 1.55, 0.0, 1.0)

		var cr := d.r + (h.r - d.r) * struktur
		var cg := d.g + (h.g - d.g) * struktur
		var cb := d.b + (h.b - d.b) * struktur

		var mk := clampf((moos[i] * _B - 0.66) * 4.0, 0.0, 1.0) * struktur * 0.8
		if mk > 0.0:
			cr += (mo.r * (0.5 + 0.6 * f) - cr) * mk
			cg += (mo.g * (0.5 + 0.6 * f) - cg) * mk
			cb += (mo.b * (0.5 + 0.6 * f) - cb) * mk

		var hh := clampf(0.12 + 0.66 * struktur + 0.16 * f, 0.0, 1.0)
		farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
		farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
		farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
		j += 3
		hoehe[i] = int(hh * 255.0)
		rau[i] = int(clampf(0.98 - 0.12 * struktur, 0.5, 1.0) * 255.0)
		ao[i] = int((0.34 + 0.66 * hh) * 255.0)

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 4.2, 2.0)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.4
	m.uv1_scale = Vector3(1.4, 0.35, 1.4)
	return m


## Wurzelholz – wie Rinde, aber feiner, dunkler und stärker bemoost.
static func wurzel() -> StandardMaterial3D:
	return _hole("wurzel", func() -> StandardMaterial3D: return _baue_wurzel())


static func _baue_wurzel() -> StandardMaterial3D:
	var k := 192
	var faser := _gestreckt(6601, 0.10, 3, k, 1, 4)
	var grob := _fbm(6602, 0.06, 3, k, 14.0)
	var fein := _fbm(6603, 0.38, 2, k)
	var moos := _fbm(6604, 0.030, 3, k, 18.0)

	var d := Farben.RINDE_DUNKEL
	var h := Farben.RINDE
	var mo := Farben.MOOS
	var mh := Farben.MOOS_HELL

	var farbe := PackedByteArray()
	farbe.resize(k * k * 3)
	var hoehe := PackedByteArray()
	hoehe.resize(k * k)
	var rau := PackedByteArray()
	rau.resize(k * k)
	var ao := PackedByteArray()
	ao.resize(k * k)

	var j := 0
	for i in k * k:
		var fa := faser[i] * _B
		var g := grob[i] * _B
		var f := fein[i] * _B
		var grat := 1.0 - absf(fa * 2.0 - 1.0)
		var struktur := clampf((0.55 * (1.0 - grat) + 0.28 * g + 0.17 * f - 0.20) * 1.7,
				0.0, 1.0)

		var cr := d.r + (h.r * 1.35 - d.r) * struktur
		var cg := d.g + (h.g * 1.35 - d.g) * struktur
		var cb := d.b + (h.b * 1.35 - d.b) * struktur

		var mk := clampf((moos[i] * _B - 0.55) * 3.2, 0.0, 1.0) * 0.85
		if mk > 0.0:
			cr += (mo.r + (mh.r - mo.r) * f - cr) * mk
			cg += (mo.g + (mh.g - mo.g) * f - cg) * mk
			cb += (mo.b + (mh.b - mo.b) * f - cb) * mk

		var hh := clampf(0.18 + 0.60 * struktur + 0.18 * f, 0.0, 1.0)
		farbe[j] = int(clampf(cr, 0.0, 1.0) * 255.0)
		farbe[j + 1] = int(clampf(cg, 0.0, 1.0) * 255.0)
		farbe[j + 2] = int(clampf(cb, 0.0, 1.0) * 255.0)
		j += 3
		hoehe[i] = int(hh * 255.0)
		rau[i] = int(clampf(0.97 - 0.10 * struktur, 0.5, 1.0) * 255.0)
		ao[i] = int((0.42 + 0.58 * hh) * 255.0)

	var m := StandardMaterial3D.new()
	m.albedo_texture = _farbtextur(farbe, k)
	_karten_setzen(m, hoehe, rau, ao, k, 3.0, 1.6)
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 1.4
	m.uv1_scale = Vector3(0.9, 0.9, 0.9)
	return m


## Farbunabhängige Struktur einer Textur. `mix` ist der Mischfaktor
## zwischen dunklem und hellem Grundton, `mult` ein multiplikativer
## Schatten (Fugen, Astlöcher, Blattzwischenräume). Normal-, Rauheits-
## und Verdeckungskarte hängen nicht an der Farbe und werden von allen
## Farbvarianten gemeinsam benutzt – so kostet eine weitere Kistenfarbe
## nur noch das Einfärben statt eines kompletten Texturaufbaus.
static func _faerben(struktur: Dictionary, dunkel: Color,
		hell: Color) -> ImageTexture:
	var k: int = struktur["kante"]
	var mix: PackedByteArray = struktur["mix"]
	var mult: PackedByteArray = struktur["mult"]
	var daten := PackedByteArray()
	daten.resize(k * k * 3)
	var dr := dunkel.r * 255.0
	var dg := dunkel.g * 255.0
	var db := dunkel.b * 255.0
	var sr := (hell.r - dunkel.r) * 255.0
	var sg := (hell.g - dunkel.g) * 255.0
	var sb := (hell.b - dunkel.b) * 255.0
	var j := 0
	if struktur.has("akzent"):
		# einzelne Flächen kippen in einen abweichenden Ton (z. B. gelbes Laub)
		var maske: PackedByteArray = struktur["akzent"]
		var ton: Color = struktur["akzent_farbe"]
		var ar := ton.r * 255.0
		var ag := ton.g * 255.0
		var ab := ton.b * 255.0
		for i in k * k:
			var t := mix[i] * _B
			var mu := mult[i] * _B
			var a := maske[i] * _B
			var cr := maxf(dr + sr * t, 0.0)
			var cg := maxf(dg + sg * t, 0.0)
			var cb := maxf(db + sb * t, 0.0)
			var f := 0.55 + 0.6 * t
			daten[j] = mini(255, int((cr + (ar * f - cr) * a) * mu))
			daten[j + 1] = mini(255, int((cg + (ag * f - cg) * a) * mu))
			daten[j + 2] = mini(255, int((cb + (ab * f - cb) * a) * mu))
			j += 3
		return _farbtextur(daten, k)
	for i in k * k:
		var t := mix[i] * _B
		var mu := mult[i] * _B
		daten[j] = mini(255, int(maxf(dr + sr * t, 0.0) * mu))
		daten[j + 1] = mini(255, int(maxf(dg + sg * t, 0.0) * mu))
		daten[j + 2] = mini(255, int(maxf(db + sb * t, 0.0) * mu))
		j += 3
	return _farbtextur(daten, k)


## Überträgt die gemeinsam genutzten Karten einer Struktur auf ein Material.
static func _struktur_anwenden(m: StandardMaterial3D, struktur: Dictionary) -> void:
	m.normal_enabled = true
	m.normal_texture = struktur["normal"]
	m.normal_scale = struktur["normal_skala"]
	m.roughness_texture = struktur["rau"]
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = 1.0
	m.ao_enabled = true
	m.ao_texture = struktur["ao"]
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.ao_light_affect = 0.25
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


## Blattwerk – einzelne Blattbüschel statt Einheitsgrün, beidseitig sichtbar.
static func laub(farbe: Color = Farben.LAUB) -> StandardMaterial3D:
	var schluessel := "laub_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var st: Dictionary = _laub_struktur()
		var m := StandardMaterial3D.new()
		m.albedo_texture = _faerben(st, farbe.darkened(0.24), farbe.lightened(0.40))
		_struktur_anwenden(m, st)
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 1.3
		m.uv1_scale = Vector3(1.1, 1.1, 1.1)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		return m)


static func _laub_struktur() -> Dictionary:
	return _hole("struktur_laub", func() -> Dictionary:
		var k := 192
		var blatt_w := _zellen(7701, 0.11, k, FastNoiseLite.RETURN_CELL_VALUE, 16.0)
		var blatt_k := _zellen(7701, 0.11, k, FastNoiseLite.RETURN_DISTANCE2_SUB, 16.0)
		var buschel := _zellen(7702, 0.038, k, FastNoiseLite.RETURN_CELL_VALUE, 18.0)
		var gross := _fbm(7703, 0.024, 3, k)
		var fein := _fbm(7704, 0.28, 2, k)

		var mix := PackedByteArray()
		mix.resize(k * k)
		var mult := PackedByteArray()
		mult.resize(k * k)
		var akzent := PackedByteArray()
		akzent.resize(k * k)
		var hoehe := PackedByteArray()
		hoehe.resize(k * k)
		var rau := PackedByteArray()
		rau.resize(k * k)
		var ao := PackedByteArray()
		ao.resize(k * k)

		for i in k * k:
			var bw := blatt_w[i] * _B
			var bk := blatt_k[i] * _B
			var bu := buschel[i] * _B
			var f := fein[i] * _B

			# Blattkörper hell, Zwischenräume dunkel
			var koerper := clampf(bk * 2.6, 0.0, 1.0)
			var t := clampf(0.40 * koerper + 0.24 * bw + 0.20 * bu
					+ 0.16 * gross[i] * _B, 0.0, 1.0)
			t = clampf((t - 0.14) * 1.45, 0.0, 1.0)
			# einzelne Blätter stehen im Schatten der darüberliegenden
			var schatten := 1.0 - 0.20 * clampf((0.34 - bk) * 3.0, 0.0, 1.0)

			var hh := clampf(0.18 + 0.56 * koerper + 0.16 * bu + 0.14 * f, 0.0, 1.0)
			mix[i] = int(t * 255.0)
			mult[i] = int(schatten * 255.0)
			akzent[i] = int(clampf((bw - 0.76) * 3.6, 0.0, 1.0) * 0.65 * 255.0)
			hoehe[i] = int(hh * 255.0)
			rau[i] = int(clampf(0.94 - 0.22 * t, 0.4, 1.0) * 255.0)
			ao[i] = int((0.84 + 0.16 * hh) * 255.0)

		return {
			"kante": k, "mix": mix, "mult": mult,
			"akzent": akzent, "akzent_farbe": Farben.LAUB_GELB,
			"normal": _normal_aus_hoehe(hoehe, k, 1.2), "normal_skala": 0.55,
			"rau": _grautextur(rau, k), "ao": _grautextur(ao, k),
		})


## Kistenholz: sichtbare Bretter mit dunklen Fugen und Maserung, die
## längs der Bretter läuft. Dazu ein paar Astlöcher.
static func kistenholz(farbe: Color = Farben.HOLZ) -> StandardMaterial3D:
	var schluessel := "kistenholz_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var st: Dictionary = _holz_struktur()
		var m := StandardMaterial3D.new()
		m.albedo_texture = _faerben(st, farbe * 0.55, farbe.lightened(0.34))
		_struktur_anwenden(m, st)
		m.uv1_scale = Vector3(1.0, 1.0, 1.0)
		return m)


static func _holz_struktur() -> Dictionary:
	return _hole("struktur_holz", func() -> Dictionary:
		var k := 256
		var maser := _gestreckt(8801, 0.085, 3, k, 6, 1)
		var maser_fein := _gestreckt(8802, 0.30, 2, k, 8, 1)
		var welle := _gestreckt(8803, 0.030, 2, k, 3, 1)
		var fein := _fbm(8804, 0.45, 2, k)
		var ast_d := _zellen(8805, 0.045, k, FastNoiseLite.RETURN_DISTANCE)
		var ast_w := _zellen(8805, 0.045, k, FastNoiseLite.RETURN_CELL_VALUE)

		var bretter := 4.0
		var mix := PackedByteArray()
		mix.resize(k * k)
		var mult := PackedByteArray()
		mult.resize(k * k)
		var hoehe := PackedByteArray()
		hoehe.resize(k * k)
		var rau := PackedByteArray()
		rau.resize(k * k)
		var ao := PackedByteArray()
		ao.resize(k * k)

		var i := 0
		for y in k:
			var v := float(y) / float(k)
			var lage := v * bretter
			var brett := lage - floorf(lage)
			# weiche Fugenkanten oben und unten am Brett
			var kante := minf(brett, 1.0 - brett) * bretter
			var fugenmix := clampf(1.0 - kante * 5.0, 0.0, 1.0)
			var randschatten := clampf(1.0 - kante * 1.6, 0.0, 1.0)
			for x in k:
				var mf := maser_fein[i] * _B
				var f := fein[i] * _B

				# Maserungslinien: Gratfunktion über das längs gestreckte Rauschen
				var linie := 1.0 - absf((maser[i] * _B * 0.72
						+ welle[i] * _B * 0.28) * 2.0 - 1.0)
				linie = linie * linie
				var t := clampf(0.52 * (1.0 - linie) + 0.28 * mf + 0.20 * f, 0.0, 1.0)
				t = clampf((t - 0.20) * 1.7, 0.0, 1.0)
				var hh := 0.42 + 0.34 * t + 0.16 * f
				var ro := 0.86 - 0.14 * t
				var mu := 1.0 - 0.26 * randschatten

				# Astloch
				var ad := ast_d[i] * _B
				if ad < 0.20 and ast_w[i] > 183:
					var a := clampf((0.20 - ad) * 8.0, 0.0, 1.0)
					mu *= 1.0 - 0.62 * a - 0.2 * (1.0 - absf(a * 2.0 - 1.0))
					hh -= 0.20 * a

				# Brettfuge: nahezu schwarz, damit die Bretter einzeln ablesbar sind
				if fugenmix > 0.0:
					mu *= 1.0 - 0.82 * fugenmix
					hh -= 0.42 * fugenmix
					ro += 0.10 * fugenmix

				mix[i] = int(t * 255.0)
				mult[i] = int(clampf(mu, 0.0, 1.0) * 255.0)
				hoehe[i] = int(clampf(hh, 0.0, 1.0) * 255.0)
				rau[i] = int(clampf(ro, 0.35, 1.0) * 255.0)
				ao[i] = int((0.40 + 0.60 * clampf(hh, 0.0, 1.0)) * 255.0)
				i += 1

		return {
			"kante": k, "mix": mix, "mult": mult,
			"normal": _normal_aus_hoehe(hoehe, k, 3.2), "normal_skala": 1.6,
			"rau": _grautextur(rau, k), "ao": _grautextur(ao, k),
		})


## Metall: gebürstete Streifen, leichte Rostflecken. Rost ist matt und
## nicht metallisch (eigene Metall- und Rauheitskarte).
static func metall(farbe: Color = Farben.KISTE_EISEN) -> StandardMaterial3D:
	var schluessel := "metall_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var st: Dictionary = _metall_struktur()
		var m := StandardMaterial3D.new()
		m.albedo_texture = _metall_faerben(st, farbe)
		_struktur_anwenden(m, st)
		# Nicht voll metallisch: der Compatibility-Renderer hat keine
		# Spiegelungssonden, vollmetallische Flächen werden dort fast schwarz.
		m.metallic = 0.55
		m.metallic_texture = st["metall"]
		m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.metallic_specular = 0.6
		m.uv1_scale = Vector3(1.0, 1.0, 1.0)
		return m)


## Wie `_faerben`, blendet zusätzlich die fertigen Rostflecken darüber.
static func _metall_faerben(struktur: Dictionary, farbe: Color) -> ImageTexture:
	var k: int = struktur["kante"]
	var mix: PackedByteArray = struktur["mix"]
	var rost: PackedByteArray = struktur["rost"]
	var rostfarbe: PackedByteArray = struktur["rostfarbe"]
	var d := farbe * 0.62
	var h := farbe.lightened(0.36)
	var daten := PackedByteArray()
	daten.resize(k * k * 3)
	var j := 0
	for i in k * k:
		var t := mix[i] * _B
		var rk := rost[i] * _B
		var cr := (d.r + (h.r - d.r) * t) * 255.0
		var cg := (d.g + (h.g - d.g) * t) * 255.0
		var cb := (d.b + (h.b - d.b) * t) * 255.0
		daten[j] = mini(255, int(cr + (rostfarbe[j] - cr) * rk))
		daten[j + 1] = mini(255, int(cg + (rostfarbe[j + 1] - cg) * rk))
		daten[j + 2] = mini(255, int(cb + (rostfarbe[j + 2] - cb) * rk))
		j += 3
	return _farbtextur(daten, k)


static func _metall_struktur() -> Dictionary:
	return _hole("struktur_metall", func() -> Dictionary:
		var k := 192
		var strich := _gestreckt(9901, 0.55, 2, k, 10, 1)
		var strich2 := _gestreckt(9902, 0.20, 2, k, 12, 1)
		var rostn := _fbm(9903, 0.030, 4, k, 20.0)
		var fein := _fbm(9904, 0.40, 2, k)

		var r0 := Farben.ROST
		var r1 := Farben.ROST_HELL

		var mix := PackedByteArray()
		mix.resize(k * k)
		var mult := PackedByteArray()
		mult.resize(k * k)
		var rost := PackedByteArray()
		rost.resize(k * k)
		var rostfarbe := PackedByteArray()
		rostfarbe.resize(k * k * 3)
		var hoehe := PackedByteArray()
		hoehe.resize(k * k)
		var rau := PackedByteArray()
		rau.resize(k * k)
		var met := PackedByteArray()
		met.resize(k * k)
		var ao := PackedByteArray()
		ao.resize(k * k)

		var j := 0
		for i in k * k:
			var f := fein[i] * _B
			var t := clampf(0.58 * strich[i] * _B + 0.30 * strich2[i] * _B
					+ 0.12 * f, 0.0, 1.0)
			t = clampf((t - 0.24) * 1.85, 0.0, 1.0)
			var hh := 0.42 + 0.42 * t + 0.16 * f
			var ro := 0.28 + 0.22 * (1.0 - t)
			var mt := 1.0

			var rk := clampf((rostn[i] * _B - 0.66) * 3.6, 0.0, 1.0)
			if rk > 0.0:
				var rn := 0.35 + 0.75 * f
				ro += (0.94 - ro) * rk
				mt -= 0.85 * rk
				hh += 0.14 * rk * f
			rostfarbe[j] = int(clampf(r0.r + (r1.r - r0.r) * (0.35 + 0.75 * f),
					0.0, 1.0) * 255.0)
			rostfarbe[j + 1] = int(clampf(r0.g + (r1.g - r0.g) * (0.35 + 0.75 * f),
					0.0, 1.0) * 255.0)
			rostfarbe[j + 2] = int(clampf(r0.b + (r1.b - r0.b) * (0.35 + 0.75 * f),
					0.0, 1.0) * 255.0)
			j += 3

			mix[i] = int(t * 255.0)
			mult[i] = 255
			rost[i] = int(rk * 255.0)
			hoehe[i] = int(clampf(hh, 0.0, 1.0) * 255.0)
			rau[i] = int(clampf(ro, 0.1, 1.0) * 255.0)
			met[i] = int(clampf(mt, 0.0, 1.0) * 255.0)
			ao[i] = int((0.66 + 0.34 * clampf(hh, 0.0, 1.0)) * 255.0)

		return {
			"kante": k, "mix": mix, "mult": mult,
			"rost": rost, "rostfarbe": rostfarbe,
			"normal": _normal_aus_hoehe(hoehe, k, 1.1), "normal_skala": 0.8,
			"rau": _grautextur(rau, k), "ao": _grautextur(ao, k),
			"metall": _grautextur(met, k),
		})


## Fell des Beuteldachses – feine Haarstruktur mit Strähnen.
static func fell(farbe: Color = Farben.FELL) -> StandardMaterial3D:
	var schluessel := "fell_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var st: Dictionary = _fell_struktur()
		var m := StandardMaterial3D.new()
		m.albedo_texture = _faerben(st, farbe * 0.74, farbe.lightened(0.24))
		_struktur_anwenden(m, st)
		m.uv1_scale = Vector3(2.0, 2.0, 2.0)
		return m)


static func _fell_struktur() -> Dictionary:
	return _hole("struktur_fell", func() -> Dictionary:
		var k := 192
		var haar := _gestreckt(1201, 0.85, 2, k, 1, 6)
		var straehne := _gestreckt(1202, 0.22, 2, k, 1, 4)
		var fein := _fbm(1203, 1.1, 2, k)
		var wirbel := _fbm(1204, 0.05, 3, k, 16.0)

		var mix := PackedByteArray()
		mix.resize(k * k)
		var mult := PackedByteArray()
		mult.resize(k * k)
		var hoehe := PackedByteArray()
		hoehe.resize(k * k)
		var rau := PackedByteArray()
		rau.resize(k * k)
		var ao := PackedByteArray()
		ao.resize(k * k)

		for i in k * k:
			var f := fein[i] * _B
			var strich := 1.0 - absf(haar[i] * _B * 2.0 - 1.0)
			var t := clampf(0.46 * (1.0 - strich) + 0.26 * straehne[i] * _B
					+ 0.16 * wirbel[i] * _B + 0.12 * f, 0.0, 1.0)
			t = clampf((t - 0.24) * 1.8, 0.0, 1.0)
			var hh := clampf(0.28 + 0.48 * t + 0.24 * f, 0.0, 1.0)
			mix[i] = int(t * 255.0)
			mult[i] = 255
			hoehe[i] = int(hh * 255.0)
			rau[i] = int(clampf(0.95 - 0.12 * t, 0.5, 1.0) * 255.0)
			ao[i] = int((0.62 + 0.38 * hh) * 255.0)

		return {
			"kante": k, "mix": mix, "mult": mult,
			"normal": _normal_aus_hoehe(hoehe, k, 1.8), "normal_skala": 1.1,
			"rau": _grautextur(rau, k), "ao": _grautextur(ao, k),
		})
