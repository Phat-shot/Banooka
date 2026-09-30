extends RefCounted
class_name Wegmaske
## Die Wegmaske und die Weltstoffe des Waldbodens (Level 01, Plan 8.1).
##
## Die Wegdecke trägt keinen Bordstein mehr: In der Mitte liegt eine
## ausgetretene Erdspur, die pendelt und ausfranst, zum Rand hin wächst
## Rasen, der bündig an Saum und Gelände anschließt. Wo was ist, sagt die
## WEGMASKE m (0 = Erde, 1 = Rasen). Der Shader (`shaders/wegboden.gdshader`
## über `shaders/wald_gemeinsam.gdshaderinc`) malt danach, die CPU setzt
## danach Halme, Kiesel und Blüten – beide lesen dasselbe Bild:
##
##   `bild()`    Weltrauschen, 256² RGBA8 über 80 m Welt-XZ, kachelbar,
##               EINMAL aus `FastNoiseLite.get_seamless_image()` erzeugt:
##               R Maske · G Makro (20 m) · B Flecken (4 m, wo hoch:
##               trocken) · A Kronenlicht
##   `textur()`  dasselbe Bild als ImageTexture (mit Mipmaps) für die GPU
##
## `NoiseTexture2D` scheidet aus: Sie erzeugt ihr Bild asynchron in einem
## Faden, die CPU hätte beim Aufbau nichts zum Lesen. Hier liest die CPU
## Byte für Byte, was die GPU bekommt, und tastet es genauso bilinear ab
## (Texelmitte bei +0,5). Nahe der Kamera (Mipstufe 0) stimmen `wert()`
## und der Shader überein – gemessen an 20 Punkten einer von oben
## gezeichneten Testebene höchstens 0,009 (Makro 0,006, Kronenlicht 0,019;
## das ist die Genauigkeit des Auslesens, 8 Bit). In der Ferne mittelt die
## GPU über die Mipmaps, dort stehen keine Halme mehr. Die Probe dafür ist
## `werkzeuge/wegmaskenprobe.gd` (Grenze 0,02): `pruefe.sh` zeichnet und
## vergleicht (über xvfb-run), `level_check` vergleicht die Konstanten hier
## mit denen im Include, sobald ein Level "wegmaske" im `pruefprofil()` hat.
##
## Die Maske (Plan 8.1, dazu Pendel und sicherer Rasenrand):
##   d = |q − pendel(s)| + (n − 0,5)·0,45 − 0,12·sin(s·0,09)
##   m = max(smoothstep(0,42; 0,62; d), smoothstep(0,80; 0,97; |q|))
## q = quer / halbe Wegbreite (UV2.x der Decke), s = Strecke (UV2.y),
## n = R-Kanal an der Weltstelle. Das Pendel (±0,24 halbe Breiten, in der
## Bachwiese gut ±1,4 m) lässt die Spur schwingen, das Rauschen macht
## Grasinseln und Erdflecken, und der Rand ist immer Rasen – dort schließt
## das Gelände mit derselben Rasenfarbe an.
##
## Wer die Formeln ändert, ändert sie im Include mit. Die Konstanten hier
## und dort müssen gleich sein; `einrichten()` setzt nur Texturen und
## Kacheln.
##
## Dazu die RASENTEXTUR (`rasen_textur()`, 256² über 2,4 m: RGB Farbe,
## A Halmdichte) – die Rasenfarbe, die Weg, Saum, Gelände und Halme teilen.

## Kantenlänge des Weltrauschens in Bildpunkten.
const KANTE := 256
## Wiederholungen je Meter: eine Kachel über 80 m.
const KACHEL := 1.0 / 80.0
## Rasentextur: Kantenlänge und Wiederholungen je Meter (2,4 m).
const RASEN_KANTE := 256
const RASEN_KACHEL := 1.0 / 2.4
## Feste Saat: gleiche Spur bei jedem Laden, auf jedem Rechner.
const SAAT := 8101

const MASKE_VON := 0.42
const MASKE_BIS := 0.62
const MASKE_RAUSCHEN := 0.45
const MASKE_WELLE := 0.12
const PENDEL_A := 0.17
const PENDEL_B := 0.07
const RAND_VON := 0.80
const RAND_BIS := 0.97
const MAKRO_TIEF := 0.82
const MAKRO_HOCH := 1.12
## Tönung der trockenen Stellen (Faktor je Kanal).
const TROCKEN_TON := Vector3(1.28, 1.08, 0.62)
## Verdeckung am Wegrand (Mitte 1,0). Wer an die Wegkante anschließt
## (Saum, Gelände), dunkelt dort ebenso ab, sonst steht eine Naht im Bild.
const RAND_VERDECKUNG := 0.78
## Mittlere Farbe der Erde in der Spur, LINEAR wie ALBEDO im Shader
## (Waldweg der Bibliothek, sRGB-Mittel 0,60/0,47/0,30, leicht entsättigt) –
## für Halmfüße und Streu auf der Spur.
const ERDE_MITTEL := Color(0.306, 0.192, 0.097)
## Kronenlicht: Feinheit und Drift der treibenden Lage (wie im Include).
const KRONEN_FEIN := 1.7
const KRONEN_DRIFT := Vector2(0.0040, 0.0017)

static var _daten := PackedByteArray()
static var _bild: Image = null
static var _textur: ImageTexture = null
static var _rasen: ImageTexture = null
static var _rasen_mittel := Color(0.04, 0.068, 0.013)


# ================================================================ Bilder

## Das Weltrauschen als Bild (Mipstufe 0, RGBA8). Geteilt – nie verändern.
static func bild() -> Image:
	_sicherstellen()
	return _bild


## Das Weltrauschen für die GPU (mit Mipmaps). Geteilt – nie verändern.
static func textur() -> ImageTexture:
	_sicherstellen()
	return _textur


## Setzt die Uniforms von `wald_gemeinsam.gdshaderinc` an einem Stoff,
## der das Include einbindet. Jeder Stoff braucht den Aufruf einmal.
static func einrichten(stoff: ShaderMaterial) -> void:
	stoff.set_shader_parameter("wald_rauschen", textur())
	stoff.set_shader_parameter("wald_rasen", rasen_textur())
	stoff.set_shader_parameter("wald_kachel", KACHEL)
	stoff.set_shader_parameter("wald_rasen_kachel", RASEN_KACHEL)


static func _sicherstellen() -> void:
	if _bild != null:
		return
	var n := KANTE * KANTE
	# R: die Maske. Vier Oktaven, Grundform um 11 m, die feinste um 1,5 m:
	# Die Spur schwingt weit aus und franst an der Kante trotzdem aus.
	# Dazu Tupfen aus Zellrauschen (1–2,5 m): hohe machen Grasinseln im
	# äußeren Drittel der Spur, tiefe kahle Erdflecken im Rasen daneben.
	# Das reine fbm allein gab nur eine glatt gewellte Kante.
	var grund := _rauschen(SAAT, 0.028, 4, 0.0)
	var tupf_d := _tupfen(SAAT + 4, FastNoiseLite.RETURN_DISTANCE)
	var tupf_w := _tupfen(SAAT + 4, FastNoiseLite.RETURN_CELL_VALUE)
	var maske := PackedByteArray()
	maske.resize(n)
	for i in n:
		var g := float(grund[i]) / 255.0
		var d := float(tupf_d[i]) / 255.0
		var w := float(tupf_w[i]) / 255.0
		var tupf := 1.0 - smoothstep(0.18, 0.5, d)
		var plus := smoothstep(0.8, 0.9, w) * tupf
		var minus := (1.0 - smoothstep(0.1, 0.2, w)) * tupf
		var wert_ := 0.5 + (g - 0.5) * 0.85 + 0.4 * plus - 0.4 * minus
		maske[i] = int(clampf(wert_, 0.0, 1.0) * 255.0 + 0.5)
	# G: Makro, wenige große Flecken um 20 m.
	var makro_r := _rauschen(SAAT + 1, 0.0156, 2, 0.0)
	# B: Flecken um 4 m, verzogen. Sie tragen die mittlere Schwankung des
	# Rasens (zwischen der Kachel von 2,4 m und dem Makro von 20 m – ohne
	# sie las sich der Rasen als Teppich) und, wo sie hoch sind, die
	# trockenen Stellen.
	var trocken_r := _rauschen(SAAT + 2, 0.075, 2, 6.0)
	# A: Kronenlicht, Flecken um 3 m.
	var krone := _rauschen(SAAT + 3, 0.09, 2, 4.0)
	_daten.resize(n * 4)
	for i in n:
		_daten[i * 4] = maske[i]
		_daten[i * 4 + 1] = makro_r[i]
		_daten[i * 4 + 2] = trocken_r[i]
		_daten[i * 4 + 3] = krone[i]
	_bild = Image.create_from_data(KANTE, KANTE, false, Image.FORMAT_RGBA8, _daten)
	var gpu := _bild.duplicate() as Image
	gpu.generate_mipmaps()
	_textur = ImageTexture.create_from_image(gpu)


## Ein kachelbares Rauschfeld, ein Byte je Bildpunkt, auf 0..255 gestreckt.
static func _rauschen(saat: int, frequenz: float, oktaven: int, warp: float) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.frequency = frequenz
	r.fractal_type = FastNoiseLite.FRACTAL_FBM
	r.fractal_octaves = oktaven
	r.fractal_gain = 0.5
	r.fractal_lacunarity = 2.0
	if warp > 0.0:
		r.domain_warp_enabled = true
		r.domain_warp_amplitude = warp
		r.domain_warp_frequency = frequenz * 0.7
		r.domain_warp_fractal_octaves = 2
	return _grau(r.get_seamless_image(KANTE, KANTE, false, false, 0.1, true), KANTE)


## Zellrauschen für die Tupfen der Maske (Zellen um 2,5 m, verzogen).
static func _tupfen(saat: int, rueckgabe: int) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_CELLULAR
	r.frequency = 0.12
	r.fractal_type = FastNoiseLite.FRACTAL_NONE
	r.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	r.cellular_return_type = rueckgabe
	r.domain_warp_enabled = true
	r.domain_warp_amplitude = 3.0
	r.domain_warp_frequency = 0.1
	r.domain_warp_fractal_octaves = 1
	return _grau(r.get_seamless_image(KANTE, KANTE, false, false, 0.05, true), KANTE)


## Die Grauwerte eines Rauschbilds, ein Byte je Bildpunkt – unabhängig
## davon, in welchem Format FastNoiseLite es liefert.
static func _grau(bild_: Image, kante: int) -> PackedByteArray:
	if bild_.get_format() != Image.FORMAT_L8:
		bild_.convert(Image.FORMAT_L8)
	var roh := bild_.get_data()
	if roh.size() == kante * kante:
		return roh
	var aus := PackedByteArray()
	aus.resize(kante * kante)
	for i in kante * kante:
		aus[i] = roh[i]
	return aus


# ================================================================ Abfragen

## Das Weltrauschen an einer Weltstelle (x, z), bilinear wie die GPU:
## r Maske, g Makro, b trocken, a Kronenlicht, je 0..1.
static func welt(welt_xz: Vector2) -> Color:
	_sicherstellen()
	var u := welt_xz.x * KACHEL * KANTE - 0.5
	var v := welt_xz.y * KACHEL * KANTE - 0.5
	return _abtasten(u, v)


static func _abtasten(u: float, v: float) -> Color:
	var x0 := floori(u)
	var y0 := floori(v)
	var fx := u - float(x0)
	var fy := v - float(y0)
	x0 = posmod(x0, KANTE)
	y0 = posmod(y0, KANTE)
	var x1 := (x0 + 1) % KANTE
	var y1 := (y0 + 1) % KANTE
	var a := (y0 * KANTE + x0) * 4
	var b := (y0 * KANTE + x1) * 4
	var c := (y1 * KANTE + x0) * 4
	var d := (y1 * KANTE + x1) * 4
	var werte: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for k in 4:
		var oben := lerpf(float(_daten[a + k]), float(_daten[b + k]), fx)
		var unten := lerpf(float(_daten[c + k]), float(_daten[d + k]), fx)
		werte[k] = lerpf(oben, unten, fy) / 255.0
	return Color(werte[0], werte[1], werte[2], werte[3])


## Seitlicher Versatz der Spurmitte in halben Wegbreiten (±0,24).
static func pendel(s: float) -> float:
	return PENDEL_A * sin(s * 0.067 + 0.8) + PENDEL_B * sin(s * 0.181 + 2.3)


## Die Maske aus einem schon geholten Rauschwert `n` (R-Kanal).
static func wert_aus(q_norm: float, s: float, n: float) -> float:
	var d := absf(q_norm - pendel(s)) + (n - 0.5) * MASKE_RAUSCHEN \
			- MASKE_WELLE * sin(s * 0.09)
	var m := smoothstep(MASKE_VON, MASKE_BIS, d)
	return maxf(m, smoothstep(RAND_VON, RAND_BIS, absf(q_norm)))


## Die Wegmaske: 0 = ausgetretene Erde, 1 = Rasen. `q_norm` = quer / halbe
## Wegbreite (auch über ±1 hinaus: dort Rasen), `s` = Strecke, `welt_xz` =
## die Weltstelle (x, z) dieses Punkts.
static func wert(q_norm: float, s: float, welt_xz: Vector2) -> float:
	return wert_aus(q_norm, s, welt(welt_xz).r)


## Helligkeitsfaktor der Makrovariation im Rasen, 0,82–1,12 – für die
## Halmfüße, damit sie genau die Farbe des Bodens darunter haben.
static func makro(welt_xz: Vector2) -> float:
	return makro_aus(welt(welt_xz))


## Makro aus einem schon geholten Abgriff: 20-m-Flecken (G) zu zwei
## Dritteln, 4-m-Flecken (B) zu einem Drittel.
static func makro_aus(w: Color) -> float:
	var t := 0.65 * smoothstep(0.18, 0.82, w.g) + 0.35 * smoothstep(0.2, 0.8, w.b)
	return lerpf(MAKRO_TIEF, MAKRO_HOCH, t)


## Anteil der trockenen, strohigen Stellen (0..1).
static func trocken(welt_xz: Vector2) -> float:
	return trocken_aus(welt(welt_xz))


static func trocken_aus(w: Color) -> float:
	return smoothstep(0.68, 0.86, w.b)


## Lichtflecken unter dem Kronendach (0..1) zur Zeit `t` (Sekunden, wie
## TIME im Shader).
static func kronenlicht(welt_xz: Vector2, t: float) -> float:
	var ruhend := welt(welt_xz).a
	var u := (welt_xz.x * KACHEL * KRONEN_FEIN + KRONEN_DRIFT.x * t) * KANTE - 0.5
	var v := (welt_xz.y * KACHEL * KRONEN_FEIN + KRONEN_DRIFT.y * t) * KANTE - 0.5
	var treibend := _abtasten(u, v).a
	return smoothstep(0.55, 0.63, ruhend * 0.5 + treibend * 0.5)


## Verdeckung quer über die Decke: Mitte 1,0, Rand `RAND_VERDECKUNG`.
static func verdeckung(q_norm: float) -> float:
	return lerpf(1.0, RAND_VERDECKUNG, smoothstep(0.3, 1.0, absf(q_norm)))


## Mittlere Bodenfarbe an einer Stelle der Decke, LINEAR wie ALBEDO im
## Shader (ohne Licht, ohne Kronenlicht): Erde und Rasen nach der Maske,
## Makro, trockene Stellen und Verdeckung – was ein Halm als Fußfarbe
## braucht. Ein Halmshader, der COLOR als Albedo nimmt, bekommt sie so,
## wie sie ist; ein StandardMaterial3D mit `vertex_color_is_srgb` braucht
## `linear_to_srgb()`.
static func bodenfarbe(q_norm: float, s: float, welt_xz: Vector2) -> Color:
	var w := welt(welt_xz)
	var m := wert_aus(q_norm, s, w.r)
	return ERDE_MITTEL.lerp(rasen_farbe_aus(rasen_mittel(), w), m) * verdeckung(q_norm)


## Rasenfarbe aus einer Texturfarbe und einem Abgriff des Weltrauschens,
## wie `rasen_farbe_aus()` im Include.
static func rasen_farbe_aus(textur: Color, w: Color) -> Color:
	var c := textur * makro_aus(w)
	var tr := trocken_aus(w) * 0.7
	return c.lerp(Color(c.r * TROCKEN_TON.x, c.g * TROCKEN_TON.y, c.b * TROCKEN_TON.z), tr)


# ================================================================ Rasen

## Mittlere Farbe der Rasentextur, linear (die Textur ist sRGB-kodiert).
static func rasen_mittel() -> Color:
	rasen_textur()
	return _rasen_mittel


## Rasen, von oben aus sechs bis zehn Metern gesehen: Büschel mit dunklen
## Lücken, Halme in zwei Richtungen, kühle und strohige Büschel, ein paar
## Kleeblätter, kahle Erde in den Lücken. A = Halmdichte (0 Lücke, 1 dichtes
## Büschel) – daran franst der Weg im Shader aus. 256² über 2,4 m; die
## großen Schwankungen bringt das Makrorauschen, nicht die Kachel (sonst
## sähe man die Wiederholung). Geteilt – nie verändern.
static func rasen_textur() -> ImageTexture:
	if _rasen != null:
		return _rasen
	const K := RASEN_KANTE
	# 256 Bildpunkte auf 2,4 m: Büschel um 12 cm, Halme ein bis zwei
	# Bildpunkte breit. Die Kontraste bleiben leise – aus sechs Metern
	# Höhe ist Rasen eine ruhige Fläche mit Körnung, kein Muster. Der erste
	# Wurf mit harten Zellen las sich im Bild als Kunstrasen.
	var zell_d := _zellen(SAAT + 11, 0.07, FastNoiseLite.RETURN_DISTANCE, 5.0)
	var zell_w := _zellen(SAAT + 11, 0.07, FastNoiseLite.RETURN_CELL_VALUE, 5.0)
	var klee_d := _zellen(SAAT + 12, 0.05, FastNoiseLite.RETURN_DISTANCE, 0.0)
	var klee_w := _zellen(SAAT + 12, 0.05, FastNoiseLite.RETURN_CELL_VALUE, 0.0)
	var halm_a := _gestreckt(SAAT + 13, 0.22, 1, 7)
	var halm_b := _gestreckt(SAAT + 14, 0.22, 7, 1)
	var richtung := _rauschen_k(SAAT + 15, 0.012, 2, K)
	var fein := _rauschen_k(SAAT + 16, 0.35, 2, K)
	var kahl := _rauschen_k(SAAT + 17, 0.024, 3, K)
	var flecken := _rauschen_k(SAAT + 18, 0.018, 3, K)

	var dunkel := Color(0.075, 0.112, 0.05)
	var mittel := Color(0.19, 0.265, 0.10)
	var hell := Color(0.31, 0.385, 0.155)
	var kuehl := Color(0.14, 0.235, 0.125)
	var gelb := Color(0.43, 0.41, 0.2)
	var klee := Color(0.22, 0.34, 0.14)
	var erde := Color(0.26, 0.2, 0.125)
	const B := 1.0 / 255.0

	var daten := PackedByteArray()
	daten.resize(K * K * 4)
	var summe := Vector3.ZERO
	for i in K * K:
		var zd := zell_d[i] * B
		var zw := zell_w[i] * B
		var f := fein[i] * B
		var fl := flecken[i] * B
		var w := clampf((richtung[i] * B - 0.5) * 5.0 + 0.5, 0.0, 1.0)
		var sp := lerpf(halm_a[i] * B, halm_b[i] * B, w)
		var halm := 1.0 - absf(sp * 2.0 - 1.0)
		halm *= halm
		# Büschel: dicht in der Mitte der Zelle, lichter in den Fugen
		var bueschel := 1.0 - smoothstep(0.1, 0.85, zd)
		var h := clampf(0.42 * bueschel + 0.32 * halm + 0.18 * (f - 0.5) + 0.2
				+ 0.22 * (fl - 0.5), 0.0, 1.0)
		var c := dunkel.lerp(mittel, smoothstep(0.0, 0.46, h))
		c = c.lerp(hell, smoothstep(0.5, 1.0, h) * 0.85)
		# Büschel verschiedener Art: kühl-blaugrün oder mit strohigen Spitzen
		c = c.lerp(kuehl * (0.6 + 0.6 * h), clampf((0.3 - zw) * 3.0, 0.0, 1.0) * 0.5)
		c = c.lerp(gelb * (0.55 + 0.5 * h), clampf((zw - 0.76) * 3.5, 0.0, 1.0) * 0.45 * h)
		# Kleeblätter: runde, etwas blaugrünere Tupfen über dem Gras
		var kd := klee_d[i] * B
		var kl := clampf((klee_w[i] * B - 0.8) * 6.0, 0.0, 1.0) * (1.0 - smoothstep(0.1, 0.24, kd))
		if kl > 0.0:
			c = c.lerp(klee * (0.85 + 0.3 * (1.0 - kd * 3.0)), kl * 0.7)
			h = maxf(h, kl * 0.75)
		# Kahle Erde in den Lücken
		var ka := clampf((kahl[i] * B - 0.62) * 3.2, 0.0, 1.0) * (1.0 - h)
		if ka > 0.0:
			c = c.lerp(erde, ka * 0.8)
			h *= 1.0 - ka * 0.6
		daten[i * 4] = int(clampf(c.r, 0.0, 1.0) * 255.0)
		daten[i * 4 + 1] = int(clampf(c.g, 0.0, 1.0) * 255.0)
		daten[i * 4 + 2] = int(clampf(c.b, 0.0, 1.0) * 255.0)
		daten[i * 4 + 3] = int(clampf(h, 0.0, 1.0) * 255.0)
		summe += Vector3(c.r, c.g, c.b)
	summe /= float(K * K)
	_rasen_mittel = Color(summe.x, summe.y, summe.z).srgb_to_linear()
	var bild_ := Image.create_from_data(K, K, false, Image.FORMAT_RGBA8, daten)
	bild_.generate_mipmaps()
	_rasen = ImageTexture.create_from_image(bild_)
	return _rasen


static func _rauschen_k(saat: int, frequenz: float, oktaven: int, kante: int) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX
	r.frequency = frequenz
	r.fractal_octaves = oktaven
	return _grau(r.get_seamless_image(kante, kante, false, false, 0.1, true), kante)


static func _zellen(saat: int, frequenz: float, rueckgabe: int, warp: float) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_CELLULAR
	r.frequency = frequenz
	r.fractal_type = FastNoiseLite.FRACTAL_NONE
	r.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	r.cellular_return_type = rueckgabe
	if warp > 0.0:
		r.domain_warp_enabled = true
		r.domain_warp_amplitude = warp
		r.domain_warp_frequency = frequenz
		r.domain_warp_fractal_octaves = 1
	return _grau(r.get_seamless_image(RASEN_KANTE, RASEN_KANTE, false, false, 0.05, true),
			RASEN_KANTE)


## Gestrecktes Rauschen für Halme: klein erzeugt, dann auf die volle Kante
## gezogen (bleibt kachelbar).
static func _gestreckt(saat: int, frequenz: float, dehnung_x: int, dehnung_y: int) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX
	r.frequency = frequenz
	r.fractal_octaves = 2
	var bild_ := r.get_seamless_image(maxi(8, RASEN_KANTE / dehnung_x),
			maxi(8, RASEN_KANTE / dehnung_y), false, false, 0.1, true)
	bild_.convert(Image.FORMAT_L8)
	bild_.resize(RASEN_KANTE, RASEN_KANTE, Image.INTERPOLATE_BILINEAR)
	return _grau(bild_, RASEN_KANTE)
