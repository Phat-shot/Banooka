extends KorridorLevel
## Level 20 – "Kolbengang"
##
## Steckbrief 4-5 (`doku/level-vorbilder.md`). Eine Raumstation, deren
## Gänge von riesigen Kolben durchstoßen werden. Der Gedanke dahinter ist
## der wichtigste der ganzen Steckbriefsammlung:
##
##     EIN HINDERNIS, ZWEI ROLLEN.
##
## Derselbe Kolben, der den Gang versperrt, ist anderswo der Aufzug. Man
## lernt ihn einmal als Wand kennen und muss sich zwanzig Meter später
## darauf stellen. Das kostet kein zusätzliches Bauteil und verdoppelt die
## Fragen, die eines stellen kann.
##
##     0 –  46  Schleusengang  Kolben als WAND: durch, solange er oben ist
##    46 – 104  Steigschacht   Kolben als AUFZUG: hinauf auf die Galerie,
##                             die über den Schleusengang ZURÜCKführt
##   104 – 162  Plattenkammer  Auslöseplatte hält die Schließtür offen
##   162 – 218  Strahlengang   wandernde Laserzäune, dazu der offene Schacht
##   218 – 268  Frachtbucht    der Rückweg: die Platte steht HINTER der Tür
##   268 – 318  Maschinenherz  alles zugleich
##
## JEDER ABSCHNITT STELLT EINE FRAGE:
##   Schleusengang  – wann darfst du losgehen?
##   Steigschacht   – und wenn dasselbe Ding dich trägt?
##   Plattenkammer  – wer hält die Tür auf, während du hindurchgehst?
##   Strahlengang   – kommst du durch eine Lücke, die wandert?
##   Frachtbucht    – bist du bereit, zurückzulaufen?
##   Maschinenherz  – alles zusammen.
##
## RÜCKWEGE sind hier Programm. Zweimal liegen Kisten so, dass man den Weg
## noch einmal gehen muss: einmal oben auf der Galerie über dem
## Schleusengang, einmal in der Frachtbucht, deren Tür von einer Platte
## dreißig Meter WEITER VORN aufgehalten wird. Wer nur vorwärts läuft,
## kommt durch – aber nicht mit allen Kisten.
##
## DAS LEVEL BRICHT SEINE REGEL GENAU EINMAL: Im Strahlengang zweigt ein
## Wartungssteg ab, der geradewegs in einen Laserzaun führt und im Nichts
## endet. Er sieht nach Todesweg aus und ist einer – aber der Zaun dort
## steht still und ist nur Kulisse: eine Attrappe ohne Zone. Wer hingeht,
## holt sich das Extraleben.

const SCHNEEWIESEL := preload("res://scenes/enemies/Schneewiesel.tscn")
const GLETSCHERKRABBE := preload("res://scenes/enemies/Gletscherkrabbe.tscn")
const FROSTMOTTE := preload("res://scenes/enemies/Frostmotte.tscn")

# --------------------------------------------------------- Strecken-Marken
const M_SCHLEUSE := 0.0
const M_SCHACHT := 46.0
const M_KAMMER := 104.0
const M_STRAHLEN := 162.0
const M_FRACHT := 218.0
const M_HERZ := 268.0
const M_ENDE := 318.0

# --------------------------------------------------------------- Höhen
## Lichte Höhe des Ganges, gemessen bis zur MITTE der Deckenplatte.
##
## Sie ist nicht nach dem Sprung bemessen, sondern nach der GALERIE: Wer
## dort oben auf 5,0 m steht, ist mit Kopf bei 6,3 m, und die Kisten neben
## ihm stehen bis 6,15 m. Mit 8,6 m beginnt die Deckenplatte (0,5 m dick)
## erst bei 8,35 m – über der Galerie bleiben gut zwei Meter Luft, und der
## Doppelsprung von rund 3,4 m stößt vom Gangboden aus ohnehin nirgends an.
const DECKENHOEHE := 8.6
## Höhe der Galerie über dem Schleusengang.
const GALERIE := 5.0
const ABSTURZ := -5.0
## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
const KRIECHHOEHE := 0.95
## Der Schacht unter dem Strahlengang – tief genug, dass man ihn sieht.
const SCHACHTGRUND := -14.0

# ------------------------------------------------------------ Leitfarben
# Gemessen an der Vorlage: olivgelbe Fliesen auf blauschwarzem Grund
# `#0C0C18`, davor Kupfer `#A36630` und Bronze `#8D441C`. Aufgehellt, weil
# `albedo_color` die Textur multipliziert – die gemessenen Werte ergäben
# einen dunklen Klumpen.
## Die Fliese und ihre Fuge. Olivgelb, NICHT sandfarben: Sand ist Höhle,
## Oliv ist Station – der Unterschied entscheidet, wo man zu sein glaubt.
const FLIESE_HELL := Color(0.74, 0.65, 0.25)
const FLIESE_DUNKEL := Color(0.46, 0.40, 0.15)
const FUGE := Color(0.29, 0.26, 0.17)
## Die Niete in der Fugenkreuzung: heller als jede Fliese, sonst
## verschwindet sie schon aus zwei Metern Entfernung.
const NIETE := Color(0.88, 0.82, 0.55)
## Kupfer, Bronze und blaugrauer Rohrstahl für die Bündel.
const KUPFER := Color(0.82, 0.42, 0.19)
const BRONZE := Color(0.74, 0.50, 0.24)
const ROHRSTAHL := Color(0.40, 0.47, 0.58)
## Messing für Kolbenmäntel, Tore und die Lückenmarken.
const MESSING := Color(0.92, 0.66, 0.26)
## Gebürsteter Stationsstahl für Stege und Stempel – blaugrau statt
## graugrün, damit er neben der olivgelben Wand nach Metall aussieht.
const STAHL := Color(0.62, 0.69, 0.75)
## Das Deckblech des Ganges. Eigener, wärmerer Ton als der übrige Stahl:
## Der Boden ist die größte Fläche im Bild, und ein rein grauer Boden
## nimmt dem Gang alle Farbe – im Vorbild liegt der Steg im warmen
## Widerschein der Wand, nicht im Neonlicht.
const DECKBLECH := Color(0.72, 0.66, 0.54)
const STAHL_DUNKEL := Color(0.36, 0.40, 0.45)
## Der helle Kantenglanz, den der Steckbrief an jedem Steg verlangt.
const KANTENGLANZ := Color(0.84, 0.90, 0.97)
## Grün leuchtende Schirme, Ventilräder und Sichtscheiben – das kalte
## Gegenlicht zum warmen Messing.
##
## Bewusst ins Blaugrüne gezogen und nicht ins Gelbgrüne: Auf dem warmen
## Deckblech mischt sich das Rot des Umgebungslichts dazu, und ein
## gelbstichiges Grün rutscht dabei bis in den Gelbton zurück. Erst mit
## diesem Blauanteil bleibt der Fleck auf dem Steg grün.
const SCHIRM_GRUEN := Color(0.12, 1.0, 0.58)
## Der matte Grünton der Tankhauben.
const HAUBE_GRUEN := Color(0.20, 0.46, 0.28)
## Ferner Stationsrumpf: blauschwarze Leere.
const RUMPF_NAH := Color(0.07, 0.08, 0.13)
const RUMPF_FERN := Color(0.15, 0.17, 0.26)


## Der Gang. Eine einzige Lücke: der offene Schacht im Strahlengang.
const STRECKE := [
	{"von": 0.0, "bis": 46.0, "breite": 11.0},
	{"von": 46.0, "bis": 104.0, "breite": 10.0},
	{"von": 104.0, "bis": 162.0, "breite": 11.0},
	{"von": 162.0, "bis": 198.0, "breite": 10.0},
	# --- 198–210 ist offener Schacht, dort tragen nur zwei Kolbenköpfe ---
	{"von": 210.0, "bis": 268.0, "breite": 12.0},
	{"von": 268.0, "bis": 318.0, "breite": 11.0, "breite_ende": 14.0},
]

## Die Gangwände. Olivgelbe Fliesen, Stahlsockel, Stahlkrone.
##
## `abstand` ist die Flucht, in der die LEITWAND sperrt (sie steht bei
## `abstand - 0,4`). Davor liegt nichts, dahinter staffelt sich alles:
## Rohrbündel, Rippen, Fliesentafel. Wer hier eine Zahl ändert, ändert
## die Gangbreite und damit jede Kolbenbreite mit.
const WAENDE := [
	{"von": -6.0, "bis": 104.0, "abstand": 6.0, "hoehe": 9.0},
	{"von": 104.0, "bis": 198.0, "abstand": 6.2, "hoehe": 9.0},
	{"von": 210.0, "bis": 268.0, "abstand": 7.0, "hoehe": 9.0},
	{"von": 268.0, "bis": 322.0, "abstand": 7.5, "hoehe": 9.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Der Gang wird ausgemessen", "tun": _verlauf_anlegen},
		{"text": "Stahlboden", "tun": _boden_bauen},
		{"text": "Fliesenwände", "tun": _waende_bauen},
		{"text": "Decke wird geschlossen", "tun": _decke_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Blick in den Rumpf", "tun": _horizont_bauen},
		{"text": "Schleusengang", "tun": _schleuse_bauen},
		{"text": "Steigschacht", "tun": _steigschacht_bauen},
		{"text": "Galerie", "tun": _galerie_bauen},
		{"text": "Plattenkammer", "tun": _plattenkammer_bauen},
		{"text": "Strahlengang", "tun": _strahlengang_bauen},
		{"text": "Frachtbucht", "tun": _frachtbucht_bauen},
		{"text": "Maschinenherz", "tun": _maschinenherz_bauen},
		{"text": "Rohrbündel", "tun": _rohrbuendel_bauen},
		{"text": "Ventilräder und Sichtscheiben", "tun": _ventile_setzen},
		{"text": "Bildschirme gehen an", "tun": _bildschirme_setzen},
		{"text": "Notbeleuchtung", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Roboter fahren hoch", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Ein Gang, der eine weite Kehre beschreibt und dabei um viereinhalb
## Meter ansteigt. Innenräume brauchen Kurven, sonst sieht man vom ersten
## Meter an bis zum letzten – und ein Kolben, den man dreihundert Meter
## vorher kommen sieht, ist kein Hindernis mehr.
##
## Die Kehre führt nie an sich selbst vorbei: Beim Sturz in den Schacht
## soll man fallen und nicht auf dem eigenen Weg landen.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 8),
		Vector3(0, 0, -16),
		Vector3(2, 0, -40),          # Schleusengang
		Vector3(10, 0.2, -62),
		Vector3(24, 0.5, -80),       # Steigschacht
		Vector3(44, 1.0, -92),
		Vector3(68, 1.4, -96),       # Plattenkammer
		Vector3(92, 1.8, -92),
		Vector3(112, 2.4, -80),      # Strahlengang
		Vector3(126, 3.0, -62),
		Vector3(134, 3.4, -40),      # Frachtbucht
		Vector3(138, 3.8, -16),
		Vector3(140, 4.2, 8),        # Maschinenherz
		Vector3(142, 4.4, 32),
		Vector3(144, 4.6, 56),
	])


# =========================================================== Grund

## Der Steg ist gebürsteter Stahl mit hellem Kantenglanz – so verlangt es
## der Steckbrief, und so ist die Kante zugleich nützlich: Sie zeichnet den
## Rand des Ganges nach, und im Strahlengang ist genau das der Unterschied
## zwischen Steg und Schacht. Messing wäre dafür zu dunkel; die helle Naht
## ist die einzige Stelle im Bild, an der etwas fast weiß ist.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.metall(DECKBLECH),
		"kante": Materialbibliothek.metall(KANTENGLANZ),
		"klippe": Materialbibliothek.metall(STAHL_DUNKEL),
	}, {"tiefe": 6.0, "schritt": 1.0, "kante_hoehe": 0.22, "kante_breite": 0.6})
	luecken_markieren(MESSING)


# =========================================================== Fliesenwand

## Die Wandfliese: olivgelb, mit flacher Fuge und einer Niete in jeder
## Fugenkreuzung.
##
## Warum eine eigene Textur und nicht `fels()` mit anderem Anstrich: Das
## Felsrauschen schlägt durch jede Einfärbung durch, und ein Gang aus
## Rauschen liest sich als Höhle, egal welche Farbe er trägt. Eine Station
## ist gebaut und nicht gewachsen – sie braucht ein Raster, das sich
## sichtbar wiederholt. Alles Zufällige steckt hier nur noch im Ton der
## einzelnen Fliese, nicht mehr in ihrer Form.
##
## Dreiseitige Projektion (`uv1_triplanar`): Die Wandtafeln sind
## unterschiedlich lang gestreckte Einheitswürfel in einem MultiMesh. Über
## ihre eigenen UVs bekäme die Fliese mit jeder Tafel eine andere Größe;
## über die Weltkoordinaten bleibt sie überall 78 cm breit.
var _fliesen_stoff: StandardMaterial3D = null


func _fliesenstoff() -> StandardMaterial3D:
	if _fliesen_stoff != null:
		return _fliesen_stoff

	var kante := 256
	var spalten := 4               ## Fliesen je Texturkante
	var zelle := kante / spalten
	var fugenbreite := 5           ## in Pixeln
	var nietradius := 5.5          ## in Pixeln

	var farben := PackedByteArray()
	farben.resize(kante * kante * 3)
	var hoehen := PackedByteArray()
	hoehen.resize(kante * kante)

	# Je Fliese ein eigener Ton. Ohne ihn ist die Wand Karopapier: Das
	# Raster sieht man dann nur an den Fugen, und zwei Fliesen unterscheiden
	# sich durch nichts.
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 2005
	var toene: Array[float] = []
	for i in spalten * spalten:
		toene.append(wuerfel.randf_range(0.80, 1.16))

	for y in kante:
		for x in kante:
			var sx := x % zelle
			var sy := y % zelle
			var zur_fuge := mini(mini(sx, zelle - 1 - sx),
					mini(sy, zelle - 1 - sy))
			# Abstand zur nächsten Fugenkreuzung – dort sitzt die Niete.
			var ex := mini(sx, zelle - sx)
			var ey := mini(sy, zelle - sy)
			var zum_kreuz := sqrt(float(ex * ex + ey * ey))

			var farbe: Color
			var h: int
			if zur_fuge < fugenbreite:
				farbe = FUGE
				# Die Fuge steigt zur Fliese hin an: eine flache Böschung
				# statt einer Kerbe. Eine Kerbe würfe harte Schatten, und
				# harte Schatten sind wieder Rauschen.
				h = 40 + zur_fuge * 24
			else:
				var t := float(sy) / float(zelle)
				var ton: float = toene[(y / zelle) * spalten + (x / zelle)]
				farbe = FLIESE_HELL.lerp(FLIESE_DUNKEL, t * 0.7) * ton
				h = 230
			if zum_kreuz < nietradius:
				farbe = NIETE
				h = 255

			var i := (y * kante + x) * 3
			farben[i] = int(clampf(farbe.r, 0.0, 1.0) * 255.0)
			farben[i + 1] = int(clampf(farbe.g, 0.0, 1.0) * 255.0)
			farben[i + 2] = int(clampf(farbe.b, 0.0, 1.0) * 255.0)
			hoehen[y * kante + x] = h

	var bild := Image.create_from_data(kante, kante, false,
			Image.FORMAT_RGB8, farben)
	bild.generate_mipmaps()

	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(bild)
	m.normal_enabled = true
	m.normal_texture = _normalkarte(hoehen, kante, 2.4)
	m.normal_scale = 0.7
	m.uv1_triplanar = true
	# Weltbezogen, und das ist hier keine Feinheit: Ohne es rechnet die
	# Projektion mit den LOKALEN Koordinaten des Einheitswürfels. Jede Tafel
	# bekäme denselben handtellergroßen Ausschnitt über ihre ganze Fläche
	# gezogen – die Wand wäre gestreift statt gekachelt.
	m.uv1_world_triplanar = true
	# 0,32 heißt: Die Textur wiederholt sich alle 3,1 m; bei vier Fliesen je
	# Kante ist eine Fliese also 78 cm breit, wie in der Vorlage.
	m.uv1_scale = Vector3(0.32, 0.32, 0.32)
	m.roughness = 0.62
	_fliesen_stoff = m
	return m


## Normalmap aus der Höhenkarte, per Sobel über die vier Nachbarn.
##
## Eigenbau statt `Materialbibliothek.normalmap()`: Die baut aus Rauschen,
## und Rauschen ist genau das, was hier nicht hingehört. Gebraucht wird die
## Kante der Fuge und die Wölbung der Niete, sonst nichts. Der Zugriff
## läuft ringförmig (`% kante`), damit die Karte kachelbar bleibt.
func _normalkarte(hoehe: PackedByteArray, kante: int,
		staerke: float) -> ImageTexture:
	var daten := PackedByteArray()
	daten.resize(kante * kante * 3)
	for y in kante:
		for x in kante:
			var links := float(hoehe[y * kante + (x - 1 + kante) % kante])
			var rechts := float(hoehe[y * kante + (x + 1) % kante])
			var oben := float(hoehe[((y - 1 + kante) % kante) * kante + x])
			var unten := float(hoehe[((y + 1) % kante) * kante + x])
			var n := Vector3((links - rechts) / 255.0 * staerke,
					(oben - unten) / 255.0 * staerke, 1.0).normalized()
			var i := (y * kante + x) * 3
			daten[i] = int((n.x * 0.5 + 0.5) * 255.0)
			daten[i + 1] = int((n.y * 0.5 + 0.5) * 255.0)
			daten[i + 2] = int((n.z * 0.5 + 0.5) * 255.0)
	var bild := Image.create_from_data(kante, kante, false,
			Image.FORMAT_RGB8, daten)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Ein Kasten für ein MultiMesh, ausgerichtet am Wegverlauf.
## `groesse`: x quer zum Gang, y hoch, z längs – wie bei `plattform()`.
func _tafel(strecke: float, seitlich: float, hoehe: float, groesse: Vector3,
		dreh: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(0.0, dreh, 0.0))
	return Transform3D(
			Basis(b.x * groesse.x, b.y * groesse.y, b.z * groesse.z),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))


## Ein liegendes Rohr für ein MultiMesh.
##
## Die Einheitswalze steht auf ihrer Y-Achse; die Vierteldrehung um X legt
## sie längs des Weges. Skaliert wird über die eigenen Achsen der Basis und
## nicht über `Basis.scaled()` – das skaliert entlang der WELTachsen und
## machte aus jedem gedrehten Rohr ein schiefes Oval.
func _walze(strecke: float, seitlich: float, hoehe: float,
		durchmesser: float, laenge: float, dreh: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(PI * 0.5, dreh, 0.0))
	return Transform3D(
			Basis(b.x * durchmesser, b.y * laenge, b.z * durchmesser),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))


## Dasselbe quer über den Gang – die zusätzliche Vierteldrehung um die
## Hochachse dreht das Rohr aus der Wegrichtung heraus.
func _querwalze(strecke: float, seitlich: float, hoehe: float,
		durchmesser: float, laenge: float, dreh: float) -> Transform3D:
	return _walze(strecke, seitlich, hoehe, durchmesser, laenge,
			dreh + PI * 0.5)


## Dasselbe stehend – für die Steiger, die das Bündel an die Wand binden.
func _steher(strecke: float, seitlich: float, hoehe: float,
		durchmesser: float, laenge: float, dreh: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(0.0, dreh, 0.0))
	return Transform3D(
			Basis(b.x * durchmesser, b.y * laenge, b.z * durchmesser),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))


## Sammelt gleichartige Körper in EINEN Zeichenaufruf.
##
## Zweihundert Wandtafeln als Einzelknoten wären zweihundert Zeichenaufrufe,
## und der Web-Export verzeiht das nicht.
func _haufen(bezeichnung: String, netz: Mesh, stellen: Array[Transform3D],
		stoff: Material) -> void:
	if stellen.is_empty():
		return
	var haufen := MultiMesh.new()
	haufen.transform_format = MultiMesh.TRANSFORM_3D
	haufen.mesh = netz
	haufen.instance_count = stellen.size()
	for i in stellen.size():
		haufen.set_instance_transform(i, stellen[i])
	var anzeige := MultiMeshInstance3D.new()
	anzeige.name = bezeichnung
	anzeige.multimesh = haufen
	anzeige.material_override = stoff
	deko.add_child(anzeige)


## Abstand der Wandflucht an dieser Stelle. Außerhalb aller Wandabschnitte
## kommt ein unerreichbar weiter Wert zurück: Dort hängt nichts an der
## Wand, weil es dort keine gibt.
func _wandabstand(strecke: float) -> float:
	for w in WAENDE:
		if strecke >= w["von"] and strecke <= w["bis"]:
			return w["abstand"]
	return 99.0


## Die Gangwände: ebene Fliesentafeln in einer Flucht.
##
## Kein `schluchtwand()` mehr. Die setzt frei gedrehte Brocken übereinander
## – richtig für eine Schlucht, falsch für einen Innenraum. Eine Station
## hat gerade Wände; die Abwechslung kommt aus der Fliese und aus dem, was
## davor hängt, nicht aus der Wand selbst.
##
## Gestaffelt wird nach hinten, damit vor der Wand Platz für die Rohre
## bleibt: Die Leitwand sperrt bei `abstand - 0,4`, die Fliesentafel steht
## erst bei `abstand + 0,5`. Die 90 cm dazwischen sind das Bündel.
func _waende_bauen() -> void:
	var fliesen := _fliesenstoff()
	var blech := Materialbibliothek.metall(STAHL_DUNKEL)
	var glanz := Materialbibliothek.metall(KANTENGLANZ)

	var tafeln: Array[Transform3D] = []
	var sockel: Array[Transform3D] = []
	var kronen: Array[Transform3D] = []
	var rippen: Array[Transform3D] = []
	var randbleche: Array[Transform3D] = []

	for w in WAENDE:
		var von: float = w["von"]
		var bis: float = w["bis"]
		var abstand: float = w["abstand"]
		var hoehe: float = w["hoehe"]
		var s := von
		var zaehler := 0
		while s < bis:
			var laenge := minf(3.0, bis - s)
			var mitte := s + laenge * 0.5
			var dreh := LevelWerkzeuge.drehung(verlauf, mitte)
			# Etwas länger als der Schritt: In der Kurve klaffte sonst
			# zwischen zwei Tafeln eine Fuge, durch die man ins Leere sieht.
			var tiefe := laenge + 0.9
			for seite: float in [-1.0, 1.0]:
				tafeln.append(_tafel(mitte, seite * (abstand + 1.2),
						(hoehe - 7.0) * 0.5, Vector3(1.4, hoehe + 7.0, tiefe),
						dreh))
				sockel.append(_tafel(mitte, seite * (abstand + 1.05),
						-0.35, Vector3(1.7, 1.1, tiefe), dreh))
				kronen.append(_tafel(mitte, seite * (abstand + 1.05),
						hoehe - 0.35, Vector3(1.8, 0.7, tiefe), dreh))
				# Jede vierte Tafel bekommt eine Rippe. Ein Gang ohne
				# Gliederung hat keine Länge, die man sehen kann – erst an
				# den Rippen merkt man, wie schnell man vorankommt.
				if zaehler % 4 == 0:
					rippen.append(_tafel(mitte, seite * (abstand + 0.35),
							(hoehe - 1.4) * 0.5,
							Vector3(0.6, hoehe - 1.4, 0.9), dreh))
				# Das Randblech schließt die Lücke zwischen Wegkante und
				# Wand. Über den Schächten gibt es keine Wegkante – dort
				# liefert `breite_bei` null, und die Lücke bleibt offen.
				var halb := breite_bei(mitte) * 0.5
				if halb > 1.0 and abstand - halb > 0.3:
					var tief := abstand - halb + 1.4
					randbleche.append(_tafel(mitte,
							seite * (halb + tief * 0.5 - 0.4), -0.3,
							Vector3(tief, 0.4, tiefe), dreh))
			s += laenge
			zaehler += 1

	var wuerfel := BoxMesh.new()
	wuerfel.size = Vector3.ONE
	_haufen("Fliesentafeln", wuerfel, tafeln, fliesen)
	_haufen("Wandsockel", wuerfel, sockel, blech)
	_haufen("Wandkronen", wuerfel, kronen, glanz)
	_haufen("Wandrippen", wuerfel, rippen, blech)
	_haufen("Randbleche", wuerfel, randbleche, blech)

	_tanks_bauen()

	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), w["abstand"] - 0.4, 8.0)


## Gefliese Tanks an den Wänden, jeder mit einer matten grünen Haube.
##
## In der Vorlage ist die Wand gar keine Wand, sondern eine Reihe stehender
## Zylinder. So weit geht es hier nicht – der Gang braucht eine ebene
## Flucht, an der die Kolben dichtschließen. Aber alle sechzehn Meter tritt
## ein Tank aus der Flucht heraus, genau bis an die Sperrebene der
## Leitwand: näher darf er nicht, sonst steht er in der Figur.
##
## Die Haube ist grün und stumpf, nicht leuchtend. Sie ist die RUHIGE
## Hälfte des kalten Gegenparts – das Leuchten übernehmen Ventil und
## Scheibe, und wenn alles leuchtet, leuchtet nichts.
func _tanks_bauen() -> void:
	var fliesen := _fliesenstoff()
	var haube := Materialbibliothek.metall(HAUBE_GRUEN)
	var band := Materialbibliothek.metall(STAHL_DUNKEL)
	var s := 10.0
	var i := 0
	while s < M_ENDE - 6.0:
		var abstand := _wandabstand(s)
		if abstand < 20.0:
			var seite: float = -1.0 if i % 2 == 0 else 1.0
			var quer := seite * (abstand + 1.5)
			var hoch := 5.6 + float(i % 3) * 0.8
			_zylinder("Tank", s, quer, hoch * 0.5 - 1.4, 1.9, hoch + 1.4,
					fliesen, 14)
			for reifen: float in [0.3, hoch - 2.2]:
				_zylinder("Tankreifen", s, quer, reifen, 2.0, 0.36, band, 14)
			_haube_setzen(s, quer, hoch - 1.4, 1.98, haube)
		s += 16.0
		i += 1


func _zylinder(bezeichnung: String, strecke: float, seitlich: float,
		hoehe: float, radius: float, laenge: float, stoff: Material,
		seiten: int = 12) -> MeshInstance3D:
	var form := CylinderMesh.new()
	form.top_radius = radius
	form.bottom_radius = radius
	form.height = laenge
	form.radial_segments = seiten
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = form
	mi.material_override = stoff
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	deko.add_child(mi)
	return mi


func _haube_setzen(strecke: float, seitlich: float, hoehe: float,
		radius: float, stoff: Material) -> void:
	var kuppel := SphereMesh.new()
	kuppel.radius = radius
	kuppel.height = radius * 2.0
	kuppel.is_hemisphere = true
	kuppel.radial_segments = 14
	kuppel.rings = 6
	var mi := MeshInstance3D.new()
	mi.name = "Tankhaube"
	mi.mesh = kuppel
	mi.material_override = stoff
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	deko.add_child(mi)


## Die Decke. Ohne sie ist eine Raumstation ein Graben unter freiem Himmel.
##
## Sie trägt Kollision – das ist in einem Innenraum richtig so und kostet
## nichts: Bei 8,6 m liegt sie weit über der Doppelsprunghöhe von rund
## 3,4 m. Über dem Schacht im Strahlengang bleibt sie weg, damit man dort
## nach oben sieht und die Kolben aus dem Dunkeln kommen.
##
## Sie reicht fünf Meter über die Wegbreite hinaus, nicht drei: Seit die
## Wand eine ebene Flucht ist, steht sie weiter draußen als früher die
## Felsblöcke, und eine Decke, die vor der Wand endet, lässt oben einen
## Spalt Himmel stehen.
func _decke_bauen() -> void:
	var blech := Materialbibliothek.metall(STAHL_DUNKEL)
	for stueck in [{"von": 0.0, "bis": 196.0}, {"von": 212.0, "bis": 318.0}]:
		var s: float = stueck["von"]
		while s < stueck["bis"]:
			var laenge: float = minf(10.0, stueck["bis"] - s)
			var mitte := s + laenge * 0.5
			plattform(mitte, 0.0, DECKENHOEHE,
					Vector3(breite_bei(mitte) + 5.0, 0.5, laenge + 0.4), blech)
			s += laenge


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


## Auch ein Innenraum braucht einen Horizont: Wo der Gang sich am Schacht
## und am Ende öffnet, endete die Welt sonst an einer geraden Linie. Der
## ferne Stationsrumpf schließt sie.
func _horizont_bauen() -> void:
	horizont(220.0, 26.0, RUMPF_NAH, RUMPF_FERN, false, SCHACHTGRUND - 2.0)


# =========================================================== Der Kolben

## Ein Kolben: ein Stempel, der aus der Decke fährt.
##
## `Wasserplattform` in der Betriebsart BOHLE ist bereits ein Ding, das
## senkrecht zwischen zwei Punkten pendelt – der Steckbrief nennt sie
## ausdrücklich als vorhandenes Bauteil für den Kolben. Was ihr fehlt, ist
## der KÖRPER: Ihr Deck ist nur 34 cm dick, man liefe einfach darüber
## hinweg. Deshalb hängt hier ein Stempel darunter, als eigener
## Kollisionskasten und eigenes Netz, beides Kind des bewegten Körpers und
## damit von selbst mitfahrend.
##
## `deck_oben`/`deck_unten` sind die Höhen der TRITTFLÄCHE. Der Stempel
## reicht von dort `stempel` Meter nach unten:
##
##   * Steht er unten und reicht der Stempel bis unter den Boden, ist der
##     Gang DICHT – man wartet.
##   * Steht er unten und liegt die Trittfläche niedrig, ist er ein
##     AUFZUG – man steigt auf.
##
## Beides ist derselbe Aufruf mit anderen Zahlen. Genau das ist der Punkt.
func _kolben(strecke: float, seitlich: float, deck_oben: float,
		deck_unten: float, stempel: float, phase: float,
		groesse := Vector2(3.6, 3.0), oben_zeit := 2.2, unten_zeit := 1.8,
		fahrzeit := 1.1) -> Wasserplattform:
	var k := WASSERPLATTFORM.instantiate() as Wasserplattform
	k.art = Wasserplattform.Art.BOHLE
	k.groesse = groesse
	k.punkt_a = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, deck_oben)
	k.punkt_b = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, deck_unten)
	k.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	k.fahrzeit = fahrzeit
	k.pause_a = oben_zeit
	k.pause_b = unten_zeit
	k.phase = phase
	# Kein Wippen: Das ist Maschinenbau und kein Floß.
	k.wippen = 0.0
	k.farbe = MESSING
	objekte.add_child(k)
	if stempel > 0.0:
		_stempel_anhaengen(k, groesse, stempel)
	return k


## Hängt den Stempelkörper unter das Deck einer Kolbenplattform.
##
## Der Ursprung der Plattform liegt in der MITTE ihres Decks; die
## Trittfläche also `DECK_STAERKE * 0.5` darüber, die Unterkante ebenso
## weit darunter. Von dort geht es abwärts.
func _stempel_anhaengen(kolben: Wasserplattform, groesse: Vector2,
		hoehe: float) -> void:
	var oben := -Wasserplattform.DECK_STAERKE * 0.5
	var mitte := oben - hoehe * 0.5

	var kasten := BoxMesh.new()
	kasten.size = Vector3(groesse.x * 0.86, hoehe, groesse.y * 0.86)
	var netz := MeshInstance3D.new()
	netz.name = "Stempel"
	netz.mesh = kasten
	netz.material_override = Materialbibliothek.metall(STAHL)
	netz.position.y = mitte
	kolben.add_child(netz)

	var form := BoxShape3D.new()
	form.size = kasten.size
	var kollision := CollisionShape3D.new()
	kollision.name = "StempelKollision"
	kollision.shape = form
	kollision.position.y = mitte
	kolben.add_child(kollision)

	# Die Stange bis in die Decke. Sie ist lang genug, dass sie oben immer
	# im Deckenschacht verschwindet – ein Kolben, dessen Stange in der Luft
	# endet, sieht aus wie ein Fehler.
	var stange := CylinderMesh.new()
	stange.top_radius = groesse.x * 0.16
	stange.bottom_radius = groesse.x * 0.16
	stange.height = DECKENHOEHE + 2.0
	stange.radial_segments = 10
	var rohr := MeshInstance3D.new()
	rohr.name = "Stange"
	rohr.mesh = stange
	rohr.material_override = Materialbibliothek.metall(MESSING)
	rohr.position.y = stange.height * 0.5
	kolben.add_child(rohr)


# =========================================================== Abschnitte

## 0–46 · Schleusengang. EINE Frage: Wann darfst du losgehen?
##
## Drei Kolben als WAND. Sie fahren bis unter den Boden herunter und
## machen den Gang dicht; oben geben sie 2,4 m Durchgang frei. Nichts
## anderes steht hier – keine Gegner zwischen den Kolben, keine Lücke im
## Boden. Der Abschnitt lehrt genau eine Sache: warten und dann laufen.
##
## Die Phasen sind gestaffelt, nicht gleich. Bei gleicher Phase wäre der
## ganze Gang ein einziges Fenster, und man liefe in einem Zug hindurch,
## ohne je einen Takt gelesen zu haben.
func _schleuse_bauen() -> void:
	# Trittfläche oben 5,0 / unten 1,4; Stempel 3,2 m.
	# Unten reicht er also von −1,8 bis 1,4: der Gang ist dicht.
	# Oben steht seine Unterkante bei 1,8 – bequem zu durchlaufen.
	_kolben(14.0, 0.0, 5.0, 1.4, 3.2, 0.0, Vector2(6.0, 2.6))
	_kolben(26.0, 0.0, 5.0, 1.4, 3.2, 0.35, Vector2(6.0, 2.6))
	_kolben(38.0, 0.0, 5.0, 1.4, 3.2, 0.7, Vector2(6.0, 2.6))


## 46–104 · Steigschacht. EINE Frage: Und wenn dasselbe Ding dich trägt?
##
## Vier Kolben, gleiche Bauart, andere Zahlen: Ihre Trittfläche kommt bis
## auf 0,3 m herunter und fährt bis auf Galeriehöhe hinauf. Man steigt
## auf, statt darunter durchzulaufen. Der letzte trägt bis auf 5,0 m – dort
## beginnt die Galerie.
##
## Damit der Zusammenhang zu sehen ist, sind sie ABSICHTLICH dieselben
## Stempel wie im Schleusengang, nur ohne Körper darunter: Wer den
## Schleusengang gelaufen ist, erkennt die Form wieder und traut dem Ding
## erst nicht.
func _steigschacht_bauen() -> void:
	# Zwei Sperrkolben zur Erinnerung – dieselbe Aufgabe wie eben.
	_kolben(54.0, 0.0, 5.0, 1.4, 3.2, 0.2, Vector2(6.0, 2.6))
	_kolben(66.0, 0.0, 5.0, 1.4, 3.2, 0.55, Vector2(6.0, 2.6))

	# Und dann dieselbe Maschine als Aufzug: dünnes Deck, tiefer Halt.
	_kolben(78.0, -2.6, 3.0, 0.3, 0.4, 0.0, Vector2(3.4, 3.0), 1.6, 2.2, 1.5)
	_kolben(88.0, 2.6, GALERIE, 0.3, 0.4, 0.3, Vector2(3.4, 3.0), 2.6, 2.2, 2.0)
	# Ein Zwischenabsatz, damit der Aufstieg zwei Schritte hat und nicht
	# einer: Wer den zweiten Kolben verpasst, steht nicht wieder unten.
	plattform(83.0, 0.0, 3.2, Vector3(3.6, 0.5, 3.6),
			Materialbibliothek.metall(STAHL))


## 46–96 · Die Galerie: der erste Rückweg.
##
## Ein Laufsteg auf 5,0 m, der über dem Schleusengang ZURÜCKführt. Wer den
## Aufzug nimmt, läuft den Abschnitt, den er gerade unten gegangen ist,
## oben noch einmal – und sieht dabei die Kolben von oben, deren Takt er
## unten gelesen hat. Das ist der Gewinn einer zweiten Ebene, und deshalb
## liegt sie über BEKANNTEM Weg und nicht über neuem.
##
## Herunter kommt man überall: Darunter liegt fester Gangboden, ein
## Fehltritt kostet den Weg und nicht das Leben.
func _galerie_bauen() -> void:
	var blech := Materialbibliothek.metall(STAHL)
	var stellen := [92.0, 84.0, 76.0, 68.0, 60.0, 52.0]
	for i in stellen.size():
		var seitlich: float = 3.0 if i % 2 == 0 else -3.0
		plattform(stellen[i], seitlich, GALERIE + float(i) * 0.05,
				Vector3(3.6, 0.5, 4.6), blech)
	# Das Ende der Galerie ist ein breiter Absatz über dem Schleusengang.
	plattform(44.0, 0.0, GALERIE + 0.35, Vector3(6.0, 0.6, 5.0), blech)


## 104–162 · Plattenkammer. EINE Frage: Wer hält die Tür auf, während du
## hindurchgehst?
##
## Drei Tore, drei Platten. Das erste Paar liegt so, wie man es erwartet:
## Platte davor, Tor dahinter, zwei Meter Weg dazwischen. Beim zweiten ist
## der Abstand größer, als der Nachlauf der Platte trägt – man muss rennen.
## Und das dritte Tor hat gar keine Platte; es läuft im eigenen Takt und
## ist damit die Antwort auf die Frage, was passiert, wenn niemand hilft.
func _plattenkammer_bauen() -> void:
	var tor_a := schliesstuer(114.0, 0.0, 4.0, 2.8, 1.4, 2.6)
	ausloeseplatte(110.0, 0.0, Vector2(2.6, 2.6), 1.6, false, [tor_a])

	var tor_b := schliesstuer(136.0, 0.0, 4.0, 2.8, 1.0, 3.2)
	ausloeseplatte(124.0, 0.0, Vector2(2.6, 2.6), 1.8, false, [tor_b])

	# Das dritte Tor läuft nur im Takt – keine Platte, kein Zutun.
	schliesstuer(154.0, 0.0, 4.0, 2.8, 2.0, 1.8, 0.4)

	# Zwischen den Toren zwei Sperrkolben, damit die Kammer nicht zur
	# Wartehalle wird: Wer auf ein Tor wartet, steht nicht sicher.
	_kolben(120.0, -3.0, 5.0, 1.4, 3.2, 0.15, Vector2(3.0, 2.4))
	_kolben(146.0, 3.0, 5.0, 1.4, 3.2, 0.6, Vector2(3.0, 2.4))

	# Ein Wartungsbalken, unter dem nur die flache Kapsel durchkommt.
	stachelbalken(158.0, 0.0, KRIECHHOEHE, Vector2(7.0, 1.2))


## 162–218 · Strahlengang. EINE Frage: Kommst du durch eine Lücke, die
## wandert?
##
## Vier Laserzäune in der Betriebsart WANDERND: Es fehlt immer genau ein
## Strahl, und die Lücke wandert auf und ab. Mal muss man krabbeln, mal
## springen – die Antwort steht nie fest.
##
## Und dann der Schacht: Von 198 bis 210 fehlt der Boden. Darüber fahren
## zwei Kolben, die als BRÜCKE dienen – dritte Rolle desselben Dings.
##
## HIER BRICHT DAS LEVEL SEINE REGEL. Bei 190 zweigt ein Wartungssteg ab,
## und quer darüber steht ein Laserzaun. Er sieht aus wie die anderen und
## ist doch keiner: Er hat keine Zone, er ist Kulisse aus zwei Balken und
## einem Leuchtstreifen. Wer sich traut hindurchzugehen, findet dahinter
## das Extraleben. Einmal, nie zweimal.
func _strahlengang_bauen() -> void:
	laserzaun(170.0, 6.0, true, 1.3, 0.0)
	laserzaun(182.0, 6.0, true, 1.1, 0.4)
	laserzaun(214.0, 7.0, true, 1.2, 0.2)

	# Die Brücke über den Schacht: zwei Kolbenköpfe, versetzt getaktet.
	# Sie stehen lange oben und kurz unten – wer zögert, wartet, aber er
	# fällt nicht.
	_kolben(201.5, 0.0, 0.0, -3.4, 0.5, 0.0, Vector2(3.6, 3.4), 3.0, 1.2, 1.2)
	_kolben(206.5, 0.0, 0.0, -3.4, 0.5, 0.45, Vector2(3.6, 3.4), 3.0, 1.2, 1.2)

	# --- Der Regelbruch: der Wartungssteg mit der Zaunattrappe ---
	var blech := Materialbibliothek.metall(STAHL)
	plattform(190.0, 5.2, 0.0, Vector3(3.0, 0.5, 3.0), blech)
	plattform(190.0, 9.0, 0.2, Vector3(5.0, 0.5, 4.0), blech)
	_zaunattrappe(190.0, 6.9, 3.2)


## Ein Laserzaun, der keiner ist: zwei Pfosten und drei Leuchtstreifen,
## ohne Zone und ohne Takt.
##
## Er muss von Weitem wie ein echter aussehen, sonst ist der Regelbruch
## keiner – deshalb dieselben Maße und dieselbe Farbe wie beim echten
## Bauteil (`Laserzaun.UNTERSTER`, `STRAHL_DICKE`, `farbe`).
func _zaunattrappe(strecke: float, seitlich: float, breite: float) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Zaunattrappe"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	# Quer zum Steg, also 90 Grad zur Wegrichtung.
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke) + PI * 0.5
	deko.add_child(gruppe)

	var pfostenstoff := Materialbibliothek.metall(STAHL_DUNKEL)
	for seite: float in [-1.0, 1.0]:
		var saeule := CylinderMesh.new()
		saeule.top_radius = 0.16
		saeule.bottom_radius = 0.16
		saeule.height = 3.0
		saeule.radial_segments = 8
		var pfosten := MeshInstance3D.new()
		pfosten.mesh = saeule
		pfosten.material_override = pfostenstoff
		pfosten.position = Vector3(seite * breite * 0.5, 1.5, 0.0)
		gruppe.add_child(pfosten)

	var strahlenstoff := Materialbibliothek.leuchtend(
			Color(0.25, 0.95, 1.0), 1.6)
	for i in 3:
		var balken := BoxMesh.new()
		balken.size = Vector3(breite, 0.1, 0.1)
		var strahl := MeshInstance3D.new()
		strahl.mesh = balken
		strahl.material_override = strahlenstoff
		strahl.position.y = 0.3 + float(i) * 0.85
		gruppe.add_child(strahl)


## 218–268 · Frachtbucht. EINE Frage: Bist du bereit zurückzulaufen?
##
## Die Bucht liegt bei 232 seitlich neben dem Gang, hinter einem Tor, das
## fast immer zu ist. Die Platte, die es aufhält, liegt bei 262 – also
## DREISSIG METER WEITER VORN, in Laufrichtung hinter der Bucht.
##
## Wer nur vorwärts läuft, tritt auf die Platte, hört das Tor aufgehen und
## sieht nichts. Wer sich umdreht, hat bei 8,5 m/s und einem Nachlauf von
## 5 Sekunden etwa 42 m Weg – genug für dreißig Meter zurück, wenn man
## sofort losläuft. Das ist der Rückweg, und er ist bezahlt: In der Bucht
## liegen sechs Kisten.
func _frachtbucht_bauen() -> void:
	var blech := Materialbibliothek.metall(STAHL)

	# Die Bucht selbst: ein Boden seitlich neben dem Gang.
	plattform(232.0, 9.0, -0.25, Vector3(8.0, 0.5, 9.0), blech)
	# Das Tor davor. Fast immer zu – ohne die Platte kommt niemand hinein.
	# Es steht QUER zur Bucht und damit längs zum Gang, deshalb hier von
	# Hand: Die Bauhilfe `schliesstuer()` richtet ein Tor immer quer über
	# den Weg aus, und ihre Drehung lässt sich nachträglich nicht mehr
	# ändern – die Flügel stehen unter `sync_to_physics`.
	var tor := SCHLIESSTUER.instantiate() as Schliesstuer
	tor.breite = 4.2
	tor.hoehe = 3.0
	# Ausnahme vom Taktvertrag, und die einzige: Dieses Tor ist kein
	# Taktgeber, sondern ein Schalter – es hängt an der Auslöseplatte,
	# nicht an einer Uhr. Ein Rasterwert wäre hier sinnlos.
	tor.offen_zeit = 0.6
	tor.zu_zeit = 9.0
	tor.farbe = MESSING
	tor.position = LevelWerkzeuge.punkt(verlauf, 232.0, 5.2, 0.0)
	tor.rotation.y = LevelWerkzeuge.drehung(verlauf, 232.0) + PI * 0.5
	objekte.add_child(tor)

	# Die Platte, dreißig Meter weiter vorn. Langer Nachlauf: Der Rückweg
	# soll knapp sein, nicht unmöglich.
	ausloeseplatte(262.0, 0.0, Vector2(3.0, 3.0), 5.0, false, [tor])

	# Zwei Sperrkolben auf dem Rückweg – zurücklaufen ist kein Spaziergang.
	_kolben(244.0, 0.0, 5.0, 1.4, 3.2, 0.25, Vector2(5.0, 2.6))
	_kolben(256.0, 0.0, 5.0, 1.4, 3.2, 0.65, Vector2(5.0, 2.6))

	laserzaun(224.0, 8.0, true, 1.4, 0.5)


## 268–318 · Maschinenherz. EINE Frage: Alles zusammen.
##
## Kolben, Zaun und Tor auf fünfzig Metern, dazu die dichteste Besetzung
## des Levels. Die letzten zwölf Meter sind leer: Nach einem Level, in dem
## es ums Warten ging, soll der Schluss ein Lauf sein.
func _maschinenherz_bauen() -> void:
	_kolben(274.0, -3.2, 5.0, 1.4, 3.2, 0.0, Vector2(3.4, 2.6))
	_kolben(280.0, 3.2, 5.0, 1.4, 3.2, 0.5, Vector2(3.4, 2.6))
	_kolben(292.0, 0.0, 5.0, 1.4, 3.2, 0.25, Vector2(5.6, 2.6))

	laserzaun(286.0, 8.0, true, 1.0, 0.0)

	var tor := schliesstuer(300.0, 0.0, 4.4, 3.0, 1.2, 2.8)
	ausloeseplatte(296.0, 0.0, Vector2(2.6, 2.6), 1.4, false, [tor])

	# Ein Aufzug zum Schluss: Er trägt auf einen Absatz, von dem aus man
	# über den ganzen Gang zurücksieht.
	_kolben(308.0, -4.0, 4.4, 0.3, 0.4, 0.0, Vector2(3.0, 3.0), 2.4, 2.0, 1.8)
	plattform(312.0, -4.0, 4.4, Vector3(4.0, 0.6, 5.0),
			Materialbibliothek.metall(STAHL))


# =========================================================== Ausstattung

## Rohrbündel entlang beider Wände – das Erkennungsmerkmal des Vorbilds.
##
## Nicht EIN Rohr je Seite, sondern ein BÜNDEL: sieben Stränge in fünf
## Stärken, dicht gestapelt, in Kupfer, Bronze und blaugrauem Rohrstahl.
## Ein einzelnes Rohr ist eine Linie; erst der Stapel liest sich als
## Maschinenraum. Die Muffen an jedem Stoß sind kein Schmuck: Ein Rohr ohne
## Stoßstelle hat keine Länge, es ist nur ein Strich.
##
## Zwischen 1,8 und 3,4 m bleibt eine Bahn frei. Dort hängen die
## Ventilräder, und ein Rad hinter einem Rohr ist kein Gegenlicht mehr.
##
## Reine Optik ohne Kollision. Sie liegen zwischen Sperrebene und
## Fliesentafel, also gerade so weit draußen, dass man sie streift, aber
## nicht durch sie hindurchläuft: In der Kurve schiebt sich das Bündel
## damit vor die Kamera, und man sieht den Steg dahinter durch die Rohre.
func _rohrbuendel_bauen() -> void:
	var kupferstoff := Materialbibliothek.metall(KUPFER)
	var bronzestoff := Materialbibliothek.metall(BRONZE)
	var stahlstoff := Materialbibliothek.metall(ROHRSTAHL)
	var muffenstoff := Materialbibliothek.metall(STAHL_DUNKEL)

	var straenge := [
		{"d": 0.36, "y": 0.48, "q": 0.10, "f": 0},
		{"d": 0.24, "y": 1.10, "q": 0.36, "f": 1},
		{"d": 0.15, "y": 1.52, "q": 0.06, "f": 2},
		{"d": 0.30, "y": 3.78, "q": 0.12, "f": 1},
		{"d": 0.20, "y": 4.36, "q": 0.38, "f": 0},
		{"d": 0.12, "y": 4.84, "q": 0.08, "f": 2},
		{"d": 0.26, "y": 5.50, "q": 0.24, "f": 1},
	]

	var kupfer: Array[Transform3D] = []
	var bronze: Array[Transform3D] = []
	var stahlrohr: Array[Transform3D] = []
	var muffen: Array[Transform3D] = []
	var steiger: Array[Transform3D] = []

	for w in WAENDE:
		var von: float = maxf(w["von"], 0.0)
		var bis: float = minf(w["bis"], M_ENDE)
		var abstand: float = w["abstand"]
		var s := von
		var zaehler := 0
		while s < bis:
			var laenge := minf(6.0, bis - s)
			var mitte := s + laenge * 0.5
			var dreh := LevelWerkzeuge.drehung(verlauf, mitte)
			for seite: float in [-1.0, 1.0]:
				for strang in straenge:
					var d: float = strang["d"]
					var quer: float = seite * (abstand + 0.02 + float(strang["q"]))
					var hoch: float = strang["y"]
					var ort := _walze(mitte, quer, hoch, d, laenge + 0.4, dreh)
					match int(strang["f"]):
						0: kupfer.append(ort)
						1: bronze.append(ort)
						_: stahlrohr.append(ort)
					muffen.append(_walze(s + 0.25, quer, hoch, d + 0.08,
							0.3, dreh))
				# Alle achtzehn Meter ein Steiger. Er bindet das Bündel an
				# die Wand und gibt dem waagerechten Gang eine Senkrechte,
				# an der das Auge die Höhe ablesen kann.
				if zaehler % 3 == 0:
					steiger.append(_steher(mitte, seite * (abstand - 0.16),
							3.0, 0.32, 9.0, dreh))
					steiger.append(_steher(mitte + 0.55,
							seite * (abstand - 0.02), 3.0, 0.2, 9.0, dreh))
			s += laenge
			zaehler += 1

	# Querrohre unter der Decke. Sie sind der einzige Grund, den Blick nach
	# oben zu heben: Ein Gang, dessen Decke leer ist, hat nur zwei Wände.
	# Und sie zerteilen die Flucht – man sieht, wie viele man schon
	# unterquert hat.
	var quer := 12.0
	while quer < M_ENDE - 6.0:
		var dreh := LevelWerkzeuge.drehung(verlauf, quer)
		var spanne := maxf(breite_bei(quer), 8.0) + 6.0
		for lage in 3:
			var hoch := 6.4 + float(lage) * 0.62
			var ort := _querwalze(quer, 0.0, hoch,
					0.30 - float(lage) * 0.06, spanne, dreh)
			if lage == 1:
				bronze.append(ort)
			else:
				kupfer.append(ort)
		quer += 12.0

	var walze := CylinderMesh.new()
	walze.top_radius = 0.5
	walze.bottom_radius = 0.5
	walze.height = 1.0
	walze.radial_segments = 10
	_haufen("RohreKupfer", walze, kupfer, kupferstoff)
	_haufen("RohreBronze", walze, bronze, bronzestoff)
	_haufen("RohreStahl", walze, stahlrohr, stahlstoff)
	_haufen("Rohrmuffen", walze, muffen, muffenstoff)
	_haufen("Steigrohre", walze, steiger, kupferstoff)


## Ventilräder und Sichtscheiben: der kalte Gegenpart.
##
## Der Steckbrief misst am Vorbild zwanzig Prozent kühl gegen
## zweiundsechzig warm; unser Gang kam auf ein halbes Prozent. Ohne diese
## Reihe ist er einfarbig, und einfarbig heißt: Der Blick findet nichts,
## woran er sich festhalten kann – jeder Meter sieht aus wie der vorige.
##
## Jedes Rad leuchtet selbst UND beleuchtet. Ein selbstleuchtendes Netz
## allein wirft kein Grün auf den Stahlsteg davor, und genau dieser grüne
## Fleck auf dem Weg ist das, was man wirklich sieht – die Tafel dahinter
## ist nur seine Ursache.
##
## Alle sieben Meter eines, abwechselnd links und rechts: Wer geht, hat
## immer eines im Bild, aber nie zwei nebeneinander.
func _ventile_setzen() -> void:
	var gruen := Materialbibliothek.leuchtend(SCHIRM_GRUEN, 1.2)
	var stahl := Materialbibliothek.metall(STAHL)
	var dunkel := Materialbibliothek.metall(STAHL_DUNKEL)
	var s := 7.0
	var i := 0
	while s < M_ENDE - 4.0:
		var abstand := _wandabstand(s)
		if abstand < 20.0:
			var seite: float = -1.0 if i % 2 == 0 else 1.0
			var quer := seite * (abstand + 0.1)
			var hoch := 2.5 if i % 2 == 0 else 2.1
			if i % 2 == 0:
				_ventilrad(s, quer, hoch, seite, gruen, stahl)
			else:
				_sichtscheibe(s, quer, hoch, seite, gruen, dunkel)
			_gruenlicht(s, seite * (abstand - 4.0), 1.5, 2.6, 9.0)
		s += 7.0
		i += 1


## Ein Ventilrad: Kranz, vier Speichen, Nabe.
##
## Die Gruppe ist mit dem Weg gedreht, ihre X-Achse zeigt also quer zum
## Gang. Ein Torus steht auf seiner Y-Achse – die Vierteldrehung um Z legt
## seine Achse quer und stellt das Rad damit flach an die Wand.
func _ventilrad(strecke: float, seitlich: float, hoehe: float, seite: float,
		leuchtstoff: Material, metallstoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Ventilrad"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var kranz := TorusMesh.new()
	kranz.inner_radius = 0.42
	kranz.outer_radius = 0.66
	kranz.rings = 18
	kranz.ring_segments = 8
	var rad := MeshInstance3D.new()
	rad.name = "Kranz"
	rad.mesh = kranz
	rad.material_override = leuchtstoff
	rad.rotation.z = PI * 0.5
	gruppe.add_child(rad)

	for k in 4:
		var speiche := BoxMesh.new()
		speiche.size = Vector3(0.10, 0.07, 1.1)
		var stab := MeshInstance3D.new()
		stab.mesh = speiche
		stab.material_override = metallstoff
		# Um die Radachse gedreht, nicht um die Hochachse: Die Speichen
		# liegen in der Radebene.
		stab.rotation.x = float(k) * PI * 0.25
		gruppe.add_child(stab)

	var nabe := CylinderMesh.new()
	nabe.top_radius = 0.19
	nabe.bottom_radius = 0.19
	nabe.height = 0.55
	nabe.radial_segments = 10
	var mitte := MeshInstance3D.new()
	mitte.name = "Nabe"
	mitte.mesh = nabe
	mitte.material_override = metallstoff
	mitte.rotation.z = PI * 0.5
	mitte.position.x = -seite * 0.2
	gruppe.add_child(mitte)


## Eine Sichtscheibe: grünes Glas in einem Stahlring.
func _sichtscheibe(strecke: float, seitlich: float, hoehe: float,
		seite: float, leuchtstoff: Material, metallstoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Sichtscheibe"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var glas := CylinderMesh.new()
	glas.top_radius = 0.66
	glas.bottom_radius = 0.66
	glas.height = 0.22
	glas.radial_segments = 14
	var scheibe := MeshInstance3D.new()
	scheibe.name = "Glas"
	scheibe.mesh = glas
	scheibe.material_override = leuchtstoff
	scheibe.rotation.z = PI * 0.5
	scheibe.position.x = -seite * 0.26
	gruppe.add_child(scheibe)

	var ring := TorusMesh.new()
	ring.inner_radius = 0.64
	ring.outer_radius = 0.84
	ring.rings = 18
	ring.ring_segments = 6
	var fassung := MeshInstance3D.new()
	fassung.name = "Fassung"
	fassung.mesh = ring
	fassung.material_override = metallstoff
	fassung.rotation.z = PI * 0.5
	fassung.position.x = -seite * 0.24
	gruppe.add_child(fassung)


## Ein grünes Licht ohne Schatten. Schattenwurf kostet hier nur Rechenzeit:
## Was es beleuchten soll, ist der Steg davor, und der liegt frei.
func _gruenlicht(strecke: float, seitlich: float, hoehe: float,
		staerke: float, reichweite: float) -> void:
	var licht := OmniLight3D.new()
	licht.light_color = SCHIRM_GRUEN
	licht.light_energy = staerke
	licht.omni_range = reichweite
	licht.shadow_enabled = false
	licht.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	deko.add_child(licht)


## Grün leuchtende Bildschirme in den Wänden.
##
## Sie sind das kalte Gegenlicht zum warmen Messing – der Steckbrief nennt
## genau diesen Gegensatz als das, was das Vorbild trägt. Gebaut als
## `plattform()` mit `Materialbibliothek.leuchtend()`: eine flache Tafel,
## die selbst leuchtet.
func _bildschirme_setzen() -> void:
	var schirm := Materialbibliothek.leuchtend(SCHIRM_GRUEN, 0.8)
	var stellen := [8.0, 22.0, 34.0, 50.0, 64.0, 74.0, 96.0, 112.0, 128.0,
			142.0, 156.0, 168.0, 180.0, 216.0, 230.0, 248.0, 264.0, 276.0,
			290.0, 306.0]
	for i in stellen.size():
		var s: float = stellen[i]
		var rand := rand_bei(s, 0.2)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		plattform(s, seite * (rand + 0.35), 3.9, Vector3(0.16, 1.3, 2.2),
				schirm)
		# Ein Omni davor, sonst leuchtet die Tafel, ohne zu beleuchten.
		_gruenlicht(s, seite * (rand - 1.6), 1.6, 1.8, 8.0)


## Innenraumlicht. Die Plattenkammer steht in trockener Maschinenluft, der
## Strahlengang ist kalt und diesig, das Maschinenherz staubig – man soll
## an der Luft merken, in welchem Teil der Station man steht.
##
## Alle drei Zonen sind heute NEUTRAL bis kühl. Früher waren sie
## bernsteinfarben, und dann kam das Gelb aus der Luft statt aus der
## Fliese: Ein warmer Dunst über einer warmen Wand macht jedes grüne Licht
## darin unsichtbar.
func _stimmungen_setzen() -> void:
	stimmung(M_KAMMER, M_STRAHLEN, Color(0.16, 0.20, 0.33), 0.020, 1.05,
			Color(0.60, 0.60, 0.58), 40.0)
	stimmung(M_STRAHLEN, M_FRACHT, Color(0.11, 0.20, 0.30), 0.022, 0.95,
			Color(0.44, 0.56, 0.56), 40.0)
	stimmung(M_HERZ, M_ENDE, Color(0.18, 0.20, 0.31), 0.020, 1.1,
			Color(0.64, 0.60, 0.55), 44.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

## Checkpoints stehen bei 4, 70, 134, 194 und 256 m – Abstände zwischen 60
## und 66 m. Der letzte liegt vor dem Maschinenherz, nicht darin: Wer den
## letzten Abschnitt verliert, soll ihn ganz wiederholen und nicht in der
## Mitte wieder einsteigen.
##
## Die Kisten auf der Galerie und in der Frachtbucht sind der Grund, warum
## man zweimal zurücklaufen muss. Sie sind bewusst mehr als anderswo –
## ein Umweg, der weniger einbringt als der direkte Weg, wird nicht gegangen.
func _kisten_setzen() -> void:
	# ---------- Schleusengang ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.6)
	kiste(Kiste.Art.NORMAL, 8.0, -2.6)
	kiste(Kiste.Art.NORMAL, 8.0, 0.0)
	kiste(Kiste.Art.NORMAL, 8.0, 2.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 20.0, 3.0)
	kiste(Kiste.Art.NORMAL, 32.0, -3.0)
	kiste(Kiste.Art.SCHUTZ, 44.0, 2.8)

	# ---------- Steigschacht ----------
	kiste(Kiste.Art.NORMAL, 48.0, -2.8)
	kiste(Kiste.Art.NORMAL, 60.0, 2.8)
	kiste(Kiste.Art.CHECKPOINT, 70.0, -2.8)
	kiste(Kiste.Art.TNT, 72.0, 0.0)
	kiste(Kiste.Art.NORMAL, 72.0, 2.6)
	# Auf dem Zwischenabsatz: Mitte 3,2 + halbe Dicke 0,25 + 0,5.
	kiste(Kiste.Art.NORMAL, 83.0, 0.0, 3.95)
	kiste(Kiste.Art.NORMAL, 96.0, -2.6)
	kiste(Kiste.Art.NORMAL, 100.0, 2.6)

	# ---------- Galerie: der erste Rückweg ----------
	# Absätze: Mitte GALERIE + i·0,05, halbe Dicke 0,25, Kiste 0,5 darüber.
	kiste(Kiste.Art.NORMAL, 92.0, 3.0, GALERIE + 0.75)
	kiste(Kiste.Art.NORMAL, 84.0, -3.0, GALERIE + 0.80)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 76.0, 3.0, GALERIE + 0.85)
	kiste(Kiste.Art.NORMAL, 68.0, -3.0, GALERIE + 0.90)
	kiste(Kiste.Art.NORMAL, 60.0, 3.0, GALERIE + 0.95)
	kiste(Kiste.Art.SCHUTZ, 52.0, -3.0, GALERIE + 1.0)
	# Der breite Absatz am Ende der Galerie: Mitte GALERIE+0,35, Dicke 0,6.
	kiste(Kiste.Art.LEBEN, 44.0, -1.6, GALERIE + 1.15)
	kiste(Kiste.Art.NORMAL, 44.0, 1.6, GALERIE + 1.15)

	# ---------- Plattenkammer ----------
	kiste(Kiste.Art.NORMAL, 108.0, -3.0)
	kiste(Kiste.Art.NORMAL, 118.0, 3.0)
	kiste(Kiste.Art.EISEN, 130.0, 0.0)
	kiste(Kiste.Art.NORMAL, 130.0, 0.0, 1.6, true)
	kiste(Kiste.Art.CHECKPOINT, 134.0, -3.0)
	kiste(Kiste.Art.NORMAL, 140.0, 3.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 150.0, -3.0)
	kiste(Kiste.Art.NORMAL, 160.0, 3.0)

	# ---------- Strahlengang ----------
	kiste(Kiste.Art.NORMAL, 166.0, -2.8)
	kiste(Kiste.Art.NORMAL, 176.0, 2.8)
	kiste(Kiste.Art.NORMAL, 186.0, -2.8)
	kiste(Kiste.Art.CHECKPOINT, 194.0, 2.8)
	kiste(Kiste.Art.NORMAL, 212.0, -3.0)
	kiste(Kiste.Art.FEDER, 216.0, 3.0)
	# Der Preis des Regelbruchs, hinter der Zaunattrappe.
	kiste(Kiste.Art.LEBEN, 190.0, 8.2, 0.95)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 190.0, 10.0, 0.95)

	# ---------- Frachtbucht: der zweite Rückweg ----------
	# Bucht: Mitte −0,25, halbe Dicke 0,25 – Oberkante also genau auf 0.
	kiste(Kiste.Art.NORMAL, 230.0, 7.0)
	kiste(Kiste.Art.NORMAL, 230.0, 9.0)
	kiste(Kiste.Art.NORMAL, 230.0, 11.0)
	kiste(Kiste.Art.NORMAL, 234.0, 7.0)
	kiste(Kiste.Art.LEBEN, 234.0, 9.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 234.0, 11.0)
	# Im Gang davor und danach.
	kiste(Kiste.Art.NORMAL, 222.0, -3.4)
	kiste(Kiste.Art.NORMAL, 240.0, -3.4)
	kiste(Kiste.Art.NORMAL, 250.0, 3.4)
	kiste(Kiste.Art.CHECKPOINT, 256.0, -3.4)
	kiste(Kiste.Art.SCHUTZ, 266.0, 3.4)

	# ---------- Maschinenherz ----------
	kiste(Kiste.Art.NORMAL, 272.0, -3.2)
	kiste(Kiste.Art.NORMAL, 272.0, 0.0)
	kiste(Kiste.Art.NORMAL, 272.0, 3.2)
	kiste(Kiste.Art.TNT, 284.0, 0.0)
	kiste(Kiste.Art.NORMAL, 288.0, -3.2)
	kiste(Kiste.Art.NORMAL, 296.0, 3.2)
	kiste(Kiste.Art.EISEN, 304.0, -3.0)
	kiste(Kiste.Art.NORMAL, 304.0, -3.0, 1.6, true)
	# Auf dem Absatz am Ende: Mitte 4,4 + halbe Dicke 0,3 + 0,5.
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 312.0, -4.0, 5.2)
	kiste(Kiste.Art.NORMAL, 314.0, 3.0)


# =========================================================== Gegner

## Roboter mit drei Haltungen – drei verschiedene Antworten.
##
## Der Steckbrief verlangt Gegner, deren Zustand man erst LESEN muss, bevor
## man reagiert. Ein eigener Haltungsgegner, der zwischen zwei Zuständen
## wechselt, existiert noch nicht (siehe Integrationsnotiz); bis dahin
## übernehmen drei Gegner mit eindeutiger, unterschiedlicher Silhouette:
##
##   Schneewiesel    hohe, dünne Läufe  -> nur der Slide
##   Gletscherkrabbe flacher Panzer     -> nur von oben
##   Frostmotte      schwebt in Brusthöhe -> nur der Drehschlag
##
## Sie sind schmal, hell und metallisch gezeichnet und passen damit besser
## in einen Stationsgang als die Waldtiere. Vor jedem Kolben steht nie
## einer: Wer im Fenster eines Kolbens steht, soll nicht gleichzeitig
## kämpfen müssen.
func _gegner_setzen() -> void:
	# ORTSFARBEN. Raumstation: Messing, Stahl und das gruene Leuchten der Anlage.
	# Unser Bestiarium kommt aus Wald, Sumpf und Eis; ungefaerbt liefe hier
	# Getier durchs Bild, das offensichtlich woandershin gehoert. Die
	# Wirkstellen bleiben hell abgesetzt - Naht, Stacheln, Zapfen und die
	# dunklen Streifen sagen weiterhin, was gegen wen hilft.
	gegner_faerbung = {
		"farbe_fell": Color(0.45, 0.48, 0.5),
		"farbe_fell_dunkel": Color(0.26, 0.28, 0.31),
		"farbe_bauch": Color(0.62, 0.5, 0.26),
		"farbe_zapfen": Color(0.86, 0.9, 0.92),
		"farbe_nase": Color(0.25, 0.27, 0.29),
		"farbe_augen": Color(0.24, 1.0, 0.45),
		"farbe_panzer": Color(0.55, 0.42, 0.2),
		"farbe_naht": Color(0.94, 0.96, 0.92),
		"farbe_chitin": Color(0.32, 0.34, 0.33),
		"farbe_klingen": Color(0.72, 0.76, 0.74),
		"farbe_pelz": Color(0.38, 0.4, 0.42),
		"farbe_fluegel": Color(0.72, 0.8, 0.74),
		"farbe_fuehler": Color(0.55, 0.45, 0.22),
	}

	# ---------- Schleusengang: einer je Kolbenpause ----------
	gegner(GLETSCHERKRABBE, 8.0, -2.0, 3.5, true)
	gegner(SCHNEEWIESEL, 20.0, 2.0, 3.0, true)
	gegner(FROSTMOTTE, 32.0, 0.0, 3.0, true)

	# ---------- Steigschacht ----------
	gegner(GLETSCHERKRABBE, 50.0, -2.0, 3.0, true)
	gegner(SCHNEEWIESEL, 72.0, 2.0, 3.0, true)
	gegner(FROSTMOTTE, 96.0, 0.0, 2.6, true)

	# ---------- Plattenkammer: zwischen den Toren ----------
	gegner(SCHNEEWIESEL, 118.0, -2.4, 3.0, true)
	gegner(GLETSCHERKRABBE, 130.0, 2.4, 3.0, true)
	werfer(144.0, -3.4)
	gegner(FROSTMOTTE, 152.0, 0.0, 2.6, true)

	# ---------- Strahlengang ----------
	gegner(SCHNEEWIESEL, 176.0, -2.2, 2.6, true)
	gegner(FROSTMOTTE, 190.0, 2.2, 2.6, true)

	# ---------- Frachtbucht: der Rückweg wird bewacht ----------
	gegner(GLETSCHERKRABBE, 226.0, -3.0, 3.5, true)
	werfer(248.0, 4.2)
	gegner(SCHNEEWIESEL, 260.0, -3.0, 3.4, true)

	# ---------- Maschinenherz: die dichteste Stelle ----------
	gegner(GLETSCHERKRABBE, 276.0, 3.0, 3.4, true)
	gegner(FROSTMOTTE, 288.0, -3.0, 3.0, true)
	werfer(298.0, 4.0)
	gegner(SCHNEEWIESEL, 310.0, 2.6, 3.4, true)


# =========================================================== Früchte

## Früchte führen den Blick. Auf der Galerie liegen sie dichter als unten –
## sie sind das Einzige, was von unten verrät, dass es dort oben überhaupt
## etwas gibt.
func _fruechte_setzen() -> void:
	fruechte_reihe(6.0, 44.0, 12, 0.0)
	fruechte_reihe(48.0, 100.0, 14, 0.0)
	fruechte_reihe(46.0, 94.0, 14, 0.0, GALERIE + 1.0)
	fruechte_reihe(106.0, 160.0, 15, 0.0)
	fruechte_reihe(164.0, 196.0, 10, 0.0)
	fruechte_bogen(197.0, 211.0, 7, 0.0, 2.2)
	fruechte_reihe(212.0, 266.0, 15, 0.0)
	# Die Spur in die Frachtbucht – sie verrät, dass es sie gibt.
	for i in 5:
		var t := float(i) / 4.0
		frucht(232.0, lerpf(4.0, 11.0, t), 0.9)
	fruechte_reihe(270.0, 314.0, 13, 0.0)
