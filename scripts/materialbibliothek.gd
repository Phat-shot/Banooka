extends RefCounted
class_name Materialbibliothek
## Zentrale, prozedurale Material- und Texturbibliothek.
##
## Alle Texturen werden zur Laufzeit aus Rauschen erzeugt (FastNoiseLite),
## es werden also keine fremden Bilddateien benötigt – alles ist Eigenbau
## und damit lizenzfrei (siehe assets/CREDITS.md).
##
## Die Materialien werden zwischengespeichert und von allen Objekten
## gemeinsam genutzt. Nie `Materialbibliothek`-Rückgaben verändern,
## sondern bei Bedarf `.duplicate()` aufrufen.

static var _cache: Dictionary = {}


static func _hole(schluessel: String, erzeuger: Callable) -> Variant:
	if not _cache.has(schluessel):
		_cache[schluessel] = erzeuger.call()
	return _cache[schluessel]


# ---------------------------------------------------------------- Texturen

## Erzeugt eine kachelbare Rauschtextur mit Farbverlauf.
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


# ---------------------------------------------------------------- Umgebung

## Waldboden: Erde mit Grasflecken, dreiachsig projiziert (keine UVs nötig).
static func waldboden() -> StandardMaterial3D:
	return _hole("waldboden", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(101, 0.035, Farben.ERDE, Farben.GRAS)
		m.normal_enabled = true
		m.normal_texture = normalmap(101, 0.09, 1.6)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.35, 0.35, 0.35)
		m.roughness = 1.0
		return m)


## Waldweg: festgetretene Erde mit Kies – hebt sich deutlich vom Grün ab.
static func waldweg() -> StandardMaterial3D:
	return _hole("waldweg", func() -> StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = rauschtextur(1111, 0.09, Farben.ERDE.darkened(0.15),
				Farben.ERDE_HELL.lightened(0.1))
		mat.normal_enabled = true
		mat.normal_texture = normalmap(1111, 0.34, 2.2)
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
		mat.roughness = 1.0
		return mat)


## Grasnarbe für begehbare Plattformen.
static func gras() -> StandardMaterial3D:
	return _hole("gras", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(202, 0.06, Farben.GRAS, Farben.GRAS_HELL)
		m.normal_enabled = true
		m.normal_texture = normalmap(202, 0.16, 1.2)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.5, 0.5, 0.5)
		m.roughness = 1.0
		return m)


## Fels für Klippen, Steine und Felsvorsprünge.
static func fels() -> StandardMaterial3D:
	return _hole("fels", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(303, 0.05, Farben.FELS, Farben.FELS_HELL,
				256, FastNoiseLite.TYPE_CELLULAR)
		m.normal_enabled = true
		m.normal_texture = normalmap(303, 0.12, 2.4)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.4, 0.4, 0.4)
		m.roughness = 0.95
		return m)


## Baumrinde – längs gestreckt, damit die Maserung senkrecht verläuft.
static func rinde() -> StandardMaterial3D:
	return _hole("rinde", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(404, 0.09, Farben.RINDE, Farben.RINDE_HELL)
		m.normal_enabled = true
		m.normal_texture = normalmap(404, 0.22, 2.8)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(1.4, 0.35, 1.4)
		m.roughness = 1.0
		return m)


## Wurzelholz – wie Rinde, aber dunkler und feiner.
static func wurzel() -> StandardMaterial3D:
	return _hole("wurzel", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(505, 0.14, Farben.RINDE * 0.8, Farben.MOOS)
		m.normal_enabled = true
		m.normal_texture = normalmap(505, 0.3, 2.0)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.9, 0.9, 0.9)
		m.roughness = 1.0
		return m)


## Blattwerk – beidseitig sichtbar, damit dünne Flächen von hinten nicht fehlen.
static func laub(farbe: Color = Farben.LAUB) -> StandardMaterial3D:
	var schluessel := "laub_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(606, 0.11, farbe * 0.75, farbe.lightened(0.25))
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.6, 0.6, 0.6)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.9
		return m)


## Kistenholz mit sichtbarer Maserung.
static func kistenholz(farbe: Color = Farben.HOLZ) -> StandardMaterial3D:
	var schluessel := "kistenholz_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(707, 0.28, farbe * 0.8, farbe.lightened(0.15))
		m.normal_enabled = true
		m.normal_texture = normalmap(707, 0.5, 1.4)
		m.uv1_scale = Vector3(1.0, 1.0, 1.0)
		m.roughness = 0.85
		return m)


## Metall für Eisenkisten und Beschläge.
static func metall(farbe: Color = Farben.KISTE_EISEN) -> StandardMaterial3D:
	var schluessel := "metall_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(808, 0.2, farbe * 0.85, farbe.lightened(0.2))
		m.metallic = 0.85
		m.roughness = 0.35
		return m)


## Fell des Beuteldachses.
static func fell(farbe: Color = Farben.FELL) -> StandardMaterial3D:
	var schluessel := "fell_%s" % farbe.to_html()
	return _hole(schluessel, func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = rauschtextur(909, 0.5, farbe * 0.9, farbe.lightened(0.1))
		m.normal_enabled = true
		m.normal_texture = normalmap(909, 1.1, 0.8)
		m.uv1_scale = Vector3(2.0, 2.0, 2.0)
		m.roughness = 0.95
		return m)
