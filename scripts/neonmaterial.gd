extends RefCounted
class_name Neonmaterial
## Materialsatz der Zukunftsstadt (Steckbrief 5-4 „Neonhöhe").
##
## Die `Materialbibliothek` sammelt, was aus der Natur kommt: Erde, Fels,
## Schnee, Holz. Die Zukunftsstadt ist deren Gegenentwurf und bekommt
## deshalb einen eigenen Satz. Sein Prinzip ist ein anderes: nicht
## Oberfläche mit Struktur, sondern **dunkler Grundton plus leuchtende
## Kante**. Die Stadt selbst besteht fast nur aus Silhouetten; lesbar
## wird sie durch die Streifen, die an ihren Kanten entlanglaufen.
##
## Die Grundtöne sind aus dem Vorbild gemessen (`#1B1424` `#2E2C5B`
## `#4E4E9A`) – tiefes Blau in drei Stufen. Die Neonfarben sind dort zu
## kleinflächig zum Messen und werden hier gesetzt.
##
## Aufbau wie in der `Materialbibliothek`: statische Methoden, Ergebnisse
## im Cache. Ein Material je Aufruf neu zu bauen wäre teuer, weil an ihm
## erzeugte Texturen hängen. Und wie dort gilt: **Nie eine Rückgabe
## verändern** – sie gehört allen. Wer eine eigene Farbe braucht, ruft
## `.duplicate()` auf oder nimmt `streifen()` mit anderer Farbe.
##
## Renderer ist `gl_compatibility`: keine Partikel, kein Volumennebel.
## Das Leuchten trägt hier allein das Material, deshalb sind die Streifen
## unbeleuchtet gesetzt – sie sollen aus jedem Winkel gleich hell sein,
## auch wenn im Level gar kein Licht steht.

# ---------------------------------------------------------------- Palette

const NACHT := Color(0.106, 0.078, 0.141)      ## #1B1424 – Grundton, füllt das Bild
const BLAU_TIEF := Color(0.180, 0.173, 0.357)  ## #2E2C5B – Wandfläche
const BLAU := Color(0.306, 0.306, 0.604)       ## #4E4E9A – Kante, Aufhellung
const MINT := Color(0.42, 0.78, 0.68)          ## mintgrüne Böden aus dem Vorbild

## Die drei Leuchtfarben.
##
## Warum genau diese: Sie stehen im Farbkreis je 120 Grad auseinander und
## keine von ihnen liegt beim Blauviolett des Grundtons. Damit hebt sich
## jeder Streifen von jeder Wand ab, egal welche Farbe vor welcher liegt –
## bei einem Blau als vierter Neonfarbe verschwände sie in der Fassade.
## Drei Farben sind außerdem genau so viele, wie man im Spiel noch als
## Bedeutung auseinanderhält: eine für sicher, eine für Takt, eine für
## Gefahr.
const NEON_CYAN := Color(0.25, 1.00, 0.98)
const NEON_MAGENTA := Color(1.00, 0.20, 0.72)
const NEON_GRUEN := Color(0.42, 1.00, 0.35)

## Reihenfolge für Streifen, die durchgezählt werden sollen.
const NEON := [NEON_CYAN, NEON_MAGENTA, NEON_GRUEN]

## Leuchtstärke eines Streifens. Kräftig, weil er gegen fast Schwarz steht.
const STREIFEN_STAERKE := 3.2

static var _cache: Dictionary = {}


static func _hole(schluessel: String, erzeuger: Callable) -> Variant:
	if not _cache.has(schluessel):
		_cache[schluessel] = erzeuger.call()
	return _cache[schluessel]


# ---------------------------------------------------------------- Materialien

## Grundton der Bauwerke: dunkle Platte mit feiner Fugenstruktur.
##
## Bewusst flau und dunkel. Die Fassade ist Kulisse; alles, was auffällt,
## gehört an die Streifen und an die Spielfläche. Ein kontrastreiches
## Wandmaterial würde in einem Level, das aus Silhouetten besteht, sofort
## mit den Plattformen um Aufmerksamkeit streiten.
static func grund() -> StandardMaterial3D:
	return _hole("neon_grund", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = Materialbibliothek.rauschtextur(5401, 0.045,
				NACHT, BLAU_TIEF)
		m.normal_enabled = true
		m.normal_texture = Materialbibliothek.normalmap(5401, 0.12, 1.4)
		m.normal_scale = 0.55
		m.roughness = 0.58
		m.metallic = 0.25
		m.metallic_specular = 0.6
		# Dreiachsig, weil die Hochhäuser aus Quadern in allen Lagen
		# bestehen und flache UVs an den Seitenwänden ziehen würden.
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 1.8
		m.uv1_scale = Vector3(0.28, 0.28, 0.28)
		return m)


## Glasfront: blauweiß, durchscheinend, mit schwachem Eigenlicht.
##
## Das Eigenlicht ist der Trick, der die Stadt zur Stadt macht: Eine
## Glasfläche ohne es wäre bei Nacht ein schwarzes Loch in der Fassade,
## mit ihm ist sie ein beleuchtetes Stockwerk. Es bleibt schwach – die
## Fenster sollen aus der Ferne wirken, nicht den Weg überstrahlen.
static func glas() -> StandardMaterial3D:
	return _hole("neon_glas", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.62, 0.78, 0.95, 0.42)
		m.emission_enabled = true
		m.emission = Color(0.55, 0.72, 1.0)
		m.emission_energy_multiplier = 0.45
		m.roughness = 0.08
		m.metallic = 0.7
		m.metallic_specular = 0.9
		return m)


## Neonstreifen an einer Kante. `farbe` üblicherweise eine aus `NEON`.
##
## Unbeleuchtet gesetzt: Ein Leuchtstreifen, den ein Punktlicht von der
## Seite noch zusätzlich abschattet, flackert beim Vorbeilaufen in der
## Helligkeit – und wo im Level gar kein Licht steht, wäre er dunkel.
## Albedo UND Emission tragen dieselbe Farbe, damit der Streifen auch
## dann richtig aussieht, wenn irgendwo doch beleuchtet gerechnet wird.
static func streifen(farbe: Color) -> StandardMaterial3D:
	return _hole("neon_streifen_%s" % farbe.to_html(), func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = STREIFEN_STAERKE
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.roughness = 0.2
		return m)


## Mintgrüner Boden der Stege und Dächer.
##
## Die einzige Fläche im Level, die deutlich heller ist als ihre
## Umgebung – und zwar mit Absicht: In einem Level mit viel Leere
## darunter muss man auf einen Blick sehen, wo man stehen kann. Der
## Mintton liegt weit genug vom Blau der Fassaden, dass die Kante
## zwischen Steg und Abgrund keine Auslegungssache ist.
static func boden() -> StandardMaterial3D:
	return _hole("neon_boden", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_texture = Materialbibliothek.rauschtextur(5402, 0.07,
				MINT.darkened(0.45), MINT.lightened(0.12))
		m.normal_enabled = true
		m.normal_texture = Materialbibliothek.normalmap(5402, 0.19, 1.1)
		m.normal_scale = 0.45
		# Nasser Glanz wie auf einer Straße bei Nacht – er nimmt die
		# Reflexe der Streifen auf und bindet Boden und Neon zusammen.
		m.roughness = 0.32
		m.metallic = 0.3
		m.metallic_specular = 0.75
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 1.6
		m.uv1_scale = Vector3(0.34, 0.34, 0.34)
		return m)
