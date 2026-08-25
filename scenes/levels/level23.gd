extends KorridorLevel
## Level 23 – "Funkenlicht"
##
## Ein Grabgang bei Nacht (Steckbrief 5-3). Das Licht ist hier kein
## Wetter, sondern die Regel: `dunkelheit()` nimmt dem Level das
## Umgebungslicht und hängt der Figur einen Funken an, der ihr mit
## kleiner Verzögerung nachzieht. Sieben Meter weit reicht er, und genau
## sieben Meter weit reicht auch das Level.
##
##     0 –  46  Grabmund     die Schwelle: sehen, wie wenig man sieht
##    46 – 100  Fackelgang   Scheinwerferfelder, die Fallen auslösen
##   100 – 152  Schachtgrube vier Meter Lücke, vier Meter Licht
##   152 – 200  Sargkammer   Takt, den nur das Aufflammen zeigt
##   200 – 250  Totenwasser  Sargdeckel, die untertauchen
##   250 – 300  Grabkammer   die Kristallhalle, der einzige weite Raum
##
## DREI REGELN, DIE HIER ÜBER ALLEM STEHEN – sie kommen aus dem Kopf von
## `Lichtkreis` und sind der Grund, warum dieses Level anders gebaut ist
## als jedes andere:
##
## 1. KEIN SPRUNG WEITER ALS DAS LICHT. Die Reichweite ist 7,0 m; die
##    weiteste Lücke im Level misst 4,0 m. Wer absetzt, sieht die
##    Landekante bereits. Ohne diese Grenze wäre jeder Sprung geraten.
## 2. KEINE VERZWEIGUNG. Der Gang ist von Anfang bis Ende einer. Sich im
##    Dunkeln zu verlaufen ist keine Aufgabe, sondern eine Strafe.
## 3. `dunkelheit()` STEHT GANZ ZULETZT. Der `Leuchtmarker` geht den
##    fertigen Baum durch – was nach ihm entsteht, leuchtet nicht mehr.
##    Deshalb ist "Funke entzünden" der allerletzte Bauschritt.
##
## WARUM HIER KEINE `stimmung()` STEHT: Die `Stimmungszone` tauscht in
## ihrem `_ready()` die `Environment` der Szene gegen eine eigene Kopie
## aus und regelt danach an dieser Kopie. Der `Lichtkreis` tut dasselbe.
## Wer zuletzt tauscht, gewinnt – und weil `dunkelheit()` laut Regel 3
## zuletzt kommt, schriebe jede Stimmungszone anschließend in eine
## Umgebung, die gar nicht mehr hängt. Die Stimmung dieses Levels steckt
## deshalb komplett in `Level23.tscn` und im Funken selbst.
##
## Die Deko ist sparsam, und das ist kein Sparen: Was außerhalb des
## Lichtkreises steht, ist schwarz. Aufwand gehört hier in die wenigen
## Dinge, die von selbst leuchten – Kisten, Früchte, Kantenmarken und die
## Kristalle der Grabkammer.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")

# ----------------------------------------------------------- Palette
# Aus dem Vorbild gemessen (siehe doku/level-vorbilder.md, 5-3). Sie steht
# hier als lokale Konstante und nicht in `Farben`, weil sie außer diesem
# einen Level niemand braucht – ein Grabgang bei Nacht ist kein Biom.
const GRABSCHWARZ := Color(0.071, 0.059, 0.047)   ## #120F0C – füllt das Bild
const OCKER_TIEF := Color(0.322, 0.188, 0.098)    ## #523019 – Fugen, Sockel
const OCKER := Color(0.627, 0.333, 0.141)         ## #A05524 – Farbe des Lichtkreises
const LEHM := Color(0.380, 0.286, 0.184)          ## #61492F – Wandfläche
const STAUBGRAU := Color(0.247, 0.263, 0.290)     ## #3F434A – Staub und Stein
const KRISTALL := Color(0.400, 0.522, 0.792)      ## #6685CA – das einzige kalte Licht

# ----------------------------------------------------------- Marken
const M_GRABMUND := 0.0
const M_FACKELGANG := 46.0
const M_SCHACHTGRUBE := 100.0
const M_SARGKAMMER := 152.0
const M_TOTENWASSER := 200.0
const M_GRABKAMMER := 250.0
const M_ENDE := 300.0

# ----------------------------------------------------------- Höhen
const WASSER_HOEHE := -0.55
const GRABSOHLE := -6.5
const ABSTURZ := -5.0
const BOHLE_OBEN := -0.30
const BOHLE_UNTEN := -1.50
## Trittfläche einer Bohle: der Körper sitzt auf `oben`, das Deck liegt
## eine halbe Deckstärke darüber.
const BOHLE_DECK := BOHLE_OBEN + Wasserplattform.DECK_STAERKE * 0.5

## Unterkante eines Balkens, unter dem nur Krabbeln durchkommt.
## Aufrechte Kapsel 1,30 m, flache 0,76 m.
const KRIECHHOEHE := 0.95

## Reichweite des Funkens. Zugleich die Obergrenze jeder Sprungweite.
const LICHTWEITE := 7.0
## Weiteste Lücke im Level. Muss deutlich unter LICHTWEITE bleiben.
const LUECKE := 4.0


## Der Weg. Nur ein Strang, nirgends eine Wahl – siehe Regel 2 im Kopf.
## Die drei Löcher der Schachtgrube sind exakt `LUECKE` breit.
const STRECKE := [
	{"von": 0.0, "bis": 46.0, "breite": 9.0, "breite_ende": 7.0},
	{"von": 46.0, "bis": 100.0, "breite": 7.0},
	# Schachtgrube: vier Inseln, drei Löcher zu je vier Metern
	{"von": 100.0, "bis": 108.0, "breite": 7.0},
	{"von": 112.0, "bis": 120.0, "breite": 6.5},
	{"von": 124.0, "bis": 132.0, "breite": 6.5},
	{"von": 136.0, "bis": 152.0, "breite": 7.0},
	{"von": 152.0, "bis": 200.0, "breite": 8.0},
	# Totenwasser: zwei Ufer, dazwischen nur Sargdeckel
	{"von": 200.0, "bis": 208.0, "breite": 8.0},
	{"von": 236.0, "bis": 250.0, "breite": 8.0},
	{"von": 250.0, "bis": 300.0, "breite": 14.0, "breite_ende": 11.0},
]

## Wandabstände. Der Gang bleibt eng; erst die Grabkammer öffnet sich.
const WAENDE := [
	{"von": -4.0, "bis": 46.0, "abstand": 5.6, "hoehe": 9.0},
	{"von": 46.0, "bis": 152.0, "abstand": 4.6, "hoehe": 10.0},
	{"von": 152.0, "bis": 200.0, "abstand": 5.2, "hoehe": 10.0},
	{"von": 200.0, "bis": 250.0, "abstand": 6.0, "hoehe": 9.0},
	{"von": 250.0, "bis": 304.0, "abstand": 8.4, "hoehe": 12.0},
]

## Wo eine Leitwand steht, hält sie den Spieler im Gang. Über dem
## Totenwasser steht KEINE – dort soll man hineinfallen können, sonst
## wäre die Fahrt über die Sargdeckel folgenlos.
const LEITWAENDE := [
	{"von": 0.0, "bis": 200.0},
	{"von": 250.0, "bis": 300.0},
]

var _mat_stein: StandardMaterial3D = null
var _mat_boden: StandardMaterial3D = null
var _mat_sockel: StandardMaterial3D = null


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Der Grabgang wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Grabsohle", "tun": _sohle_bauen},
		{"text": "Gänge", "tun": _boden_bauen},
		{"text": "Grabwände", "tun": _waende_bauen},
		{"text": "Totenwasser steigt", "tun": _wasser_fluten},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Grabmund", "tun": _grabmund_bauen},
		{"text": "Fackelgang", "tun": _fackelgang_bauen},
		{"text": "Schachtgrube", "tun": _schachtgrube_bauen},
		{"text": "Sargkammer", "tun": _sargkammer_bauen},
		{"text": "Sargdeckel im Wasser", "tun": _totenwasser_bauen},
		{"text": "Grabkammer", "tun": _grabkammer_bauen},
		{"text": "Kantenmarken", "tun": _kantenmarken_setzen},
		{"text": "Geröll und Staub", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		# MUSS der letzte Schritt bleiben – siehe Regel 3 im Kopf.
		{"text": "Der Funke wird entzündet", "tun": _dunkelheit_setzen},
	]


# =========================================================== Verlauf

## Eine lange, ruhige Schleife, die sich erst senkt und am Ende wieder
## steigt. Bewusst ohne scharfe Knicke: Eine enge Kurve nähme dem Funken
## die Sicht nach vorn, und der Spieler stünde vor Schwarz, wo Weg wäre.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, -0.4, -18),
		Vector3(2, -0.8, -42),        # Grabmund
		Vector3(10, -1.2, -64),       # Fackelgang
		Vector3(24, -1.6, -82),
		Vector3(44, -1.8, -92),       # Schachtgrube
		Vector3(66, -2.0, -92),
		Vector3(86, -2.2, -84),       # Sargkammer
		Vector3(102, -2.4, -68),
		Vector3(110, -2.6, -48),      # Totenwasser, tiefster Punkt
		Vector3(110, -2.4, -26),
		Vector3(102, -1.8, -6),       # Grabkammer
		Vector3(88, -1.0, 10),
		Vector3(70, -0.2, 20),
		Vector3(50, 0.6, 24),
	])


# =========================================================== Stoffe

## Grabstein: trockener Lehm über dunklem Ocker.
##
## Die Materialien entstehen erst beim ersten Zugriff und werden gemerkt.
## Ein neu gebautes Material je Aufruf hinge mit eigenen Texturen im
## Speicher – bei einer Schluchtwand aus tausenden Blöcken wäre das teuer.
func _grabstein() -> StandardMaterial3D:
	if _mat_stein == null:
		_mat_stein = StandardMaterial3D.new()
		_mat_stein.albedo_texture = Materialbibliothek.rauschtextur(
				2301, 0.055, OCKER_TIEF, LEHM)
		_mat_stein.normal_enabled = true
		_mat_stein.normal_texture = Materialbibliothek.normalmap(2301, 0.13, 1.7)
		_mat_stein.normal_scale = 0.7
		_mat_stein.roughness = 0.94
		_mat_stein.uv1_triplanar = true
		_mat_stein.uv1_scale = Vector3(0.22, 0.22, 0.22)
	return _mat_stein


## Der Gangboden: festgetretener Sand, eine Spur heller als die Wände.
## Er ist die einzige Fläche, die der Funke wirklich beleuchtet – wäre er
## so dunkel wie die Wand, liefe man auf Schwarz.
func _grabboden() -> StandardMaterial3D:
	if _mat_boden == null:
		_mat_boden = StandardMaterial3D.new()
		_mat_boden.albedo_texture = Materialbibliothek.rauschtextur(
				2302, 0.09, LEHM, OCKER.lightened(0.12))
		_mat_boden.normal_enabled = true
		_mat_boden.normal_texture = Materialbibliothek.normalmap(2302, 0.22, 1.2)
		_mat_boden.normal_scale = 0.5
		_mat_boden.roughness = 0.96
		_mat_boden.uv1_triplanar = true
		_mat_boden.uv1_scale = Vector3(0.3, 0.3, 0.3)
	return _mat_boden


## Sockelstein für Kante und Klippe: kühler Staubgrau gegen das Ocker.
func _sockelstein() -> StandardMaterial3D:
	if _mat_sockel == null:
		_mat_sockel = StandardMaterial3D.new()
		_mat_sockel.albedo_texture = Materialbibliothek.rauschtextur(
				2303, 0.07, GRABSCHWARZ, STAUBGRAU)
		_mat_sockel.roughness = 0.92
		_mat_sockel.uv1_triplanar = true
		_mat_sockel.uv1_scale = Vector3(0.26, 0.26, 0.26)
	return _mat_sockel


# =========================================================== Grund

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _grabboden(),
		"kante": _sockelstein(),
		"klippe": _grabstein(),
	}, {"tiefe": 5.0, "schritt": 1.0, "kante_hoehe": 0.28, "kante_breite": 0.65})
	luecken_markieren(OCKER)


## Die Sohle des Grabes, tief unter dem Gang. Man erreicht sie nie – die
## Absturzzone liegt darüber –, aber sie nimmt dem Loch den Boden aus
## Nichts.
func _sohle_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(320.0, 320.0)
	var mi := MeshInstance3D.new()
	mi.name = "Grabsohle"
	mi.mesh = flaeche
	mi.material_override = _sockelstein()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, GRABSOHLE)
	geometrie.add_child(mi)


## Zwei Wände aus Blöcken links und rechts, dahinter die glatte Leitwand.
##
## Über dem Totenwasser fehlt die Leitwand mit Absicht: Dort soll ein
## Fehltritt ins Wasser gehen, sonst wären die Sargdeckel eine Zierde.
func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE, _grabstein(), {
		"schritt": 2.2, "lagen": 4, "block": 2.6,
		"sockel": 9.0, "saat": 2311,
		"adermaterial": _sockelstein(),
		"deckmaterial": Materialbibliothek.einfarbig(GRABSCHWARZ, 0.98),
		"aderdichte": 0.3,
	})
	for w in LEITWAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, w["von"], w["bis"],
				_wandabstand(w["von"]) - 0.5, 6.0)


## Wandabstand an einer Stelle – die Leitwand soll dicht hinter der
## Sichtwand stehen, nicht mitten im Weg.
func _wandabstand(strecke: float) -> float:
	for w in WAENDE:
		if strecke >= w["von"] and strecke <= w["bis"]:
			return w["abstand"]
	return 6.0


func _wasser_fluten() -> void:
	var schritt := 14.0
	var s := M_TOTENWASSER - 2.0
	while s < M_GRABKAMMER:
		var w := wasser(s + schritt * 0.5, Vector2(64.0, schritt + 2.0),
				WASSER_HOEHE)
		w.tiefe = 2.2
		w.toedlich = true
		w.wellen_hoehe = 0.05
		w.wellen_tempo = 0.4
		w.farbe_tief = GRABSCHWARZ
		w.farbe_hell = OCKER_TIEF
		w.spiegelung = 0.35
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


## Auch im Dunkellevel gehört ein Horizont dazu: Der `Lichtkreis` dimmt
## den Himmel auf ein Sechzehntel herunter, aber ganz ohne ferne Silhouette
## endete die Welt hinter der Schluchtwand an einer geraden Linie.
func _horizont_bauen() -> void:
	horizont(220.0, 30.0, GRABSCHWARZ, OCKER_TIEF.darkened(0.4),
			false, GRABSOHLE - 1.0)


# =========================================================== Abschnitte

## 0–46 · Grabmund. Die Frage: Wie weit traust du dich, wenn du nur ein
## paar Meter weit siehst?
##
## Hier steht absichtlich nichts Neues – nur Bekanntes, das plötzlich
## schwer ist, weil man es erst sieht, wenn man davorsteht. Das
## Stachelfeld bei 16 m ist die erste Lektion: Es taucht auf, wenn der
## Funke es erreicht, und nicht früher.
func _grabmund_bauen() -> void:
	stacheln(16.0, -1.4, Vector2(3.2, 2.4), false, OCKER)
	stacheln(21.0, 1.6, Vector2(3.0, 2.4), false, OCKER)

	# Ein gestürzter Deckenbalken als Stufe. Er nimmt dem Gang die
	# Gleichförmigkeit, ohne eine Lücke aufzureißen.
	plattform(28.0, -1.2, 0.55, Vector3(3.4, 1.1, 2.6), _grabstein())
	plattform(31.5, 1.4, 1.05, Vector3(3.0, 2.1, 2.4), _grabstein())

	# Und der Grabgang wird niedrig: Wer hinein will, muss krabbeln.
	stachelbalken(40.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.2))


## 46–100 · Fackelgang. Die Frage: Trittst du auf das Licht?
##
## Das Vorbild hat Scheinwerferfelder, die beim Durchqueren Fallen
## auslösen. Bei uns ist das die `ausloeseplatte()`: Sie leuchtet auf,
## wenn man sie betritt – und genau dieses Aufleuchten ist im Schwarz das
## Einzige, was man von der Falle sieht, bevor sie kommt.
##
## Die Platten liegen so, dass man sie umgehen KANN: Der Gang ist sieben
## Meter breit, die Platte misst 2,6 m. Wer aufmerksam läuft, sieht den
## hellen Fleck am Boden noch rechtzeitig. Wer rennt, tritt drauf.
func _fackelgang_bauen() -> void:
	# Zwei Feuerspeier: die einzigen Lichtquellen dieses Abschnitts außer
	# dem Funken. Ihr Aufflammen zeigt für einen Augenblick den ganzen Gang.
	feuerspeier(52.0, -3.0, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(88.0, 3.0, 1.0, 180.0, 3.4, 0.45)

	# Falle 1: Ein Brocken kommt aus dem Dunkeln entgegen. Er startet weit
	# vorn und rollt auf den Spieler zu – rückwärts auf der Kurve.
	var brocken := rollbrocken(90.0, 56.0, 0.0, 0.0, 1.3, 11.0, 0.0, 0.0)
	brocken.auf_abruf = true
	brocken.abwurf = 3.0
	ausloeseplatte(58.0, -1.0, Vector2(2.6, 2.6), 0.8, false, [brocken])

	# Falle 2: dasselbe noch einmal, aber die Platte liegt jetzt in der
	# Mitte und der Brocken ist schneller. Zweimal dieselbe Falle ist
	# Absicht – beim zweiten Mal ist sie eine Prüfung statt einer
	# Überraschung.
	var brocken_zwei := rollbrocken(98.0, 68.0, -1.2, 0.0, 1.1, 13.0, 0.0, 0.0,
			Rollhindernis.Art.FASS)
	brocken_zwei.auf_abruf = true
	brocken_zwei.abwurf = 3.0
	ausloeseplatte(70.0, 0.0, Vector2(2.8, 2.8), 0.8, false, [brocken_zwei])

	# Ein Tor mitten im Gang, das im Takt zufährt – und eine Platte davor,
	# die es offen hält. Ein Hindernis mit zwei Rollen: Wer die Platte
	# findet, geht durch; wer sie übersieht, wartet auf den Takt.
	var tor := schliesstuer(84.0, 0.0, 3.4, 2.8, 1.8, 1.8)
	ausloeseplatte(79.0, 1.2, Vector2(2.4, 2.4), 1.6, false, [tor])

	# Einfahrbare Speere im Boden – im Dunkeln hört man sie eher, als man
	# sie sieht.
	stacheln(64.0, 1.5, Vector2(3.0, 3.0), true, OCKER)
	stacheln(94.0, -1.5, Vector2(3.0, 3.0), true, OCKER)


## 100–152 · Schachtgrube. Die Frage: Wie weit ist die andere Seite?
##
## Drei Löcher zu je vier Metern. Die Figur schafft im vollen Lauf gut
## fünf – die Lücke ist also nicht knapp, sondern nur unsichtbar. Genau
## das ist die Aufgabe: Der Funke reicht sieben Meter, die Landekante ist
## bei vier Metern also schon da, wenn man absetzt. Wer trotzdem zögert,
## springt zu kurz, und das ist kein Pech, sondern Ungeduld.
##
## Über jedem Loch liegt eine Bruchplatte als Zwischentritt. Sie ist ein
## Angebot, keine Notwendigkeit – wer sie nimmt, muss weiterlaufen; wer
## sie auslässt, springt einmal weit.
func _schachtgrube_bauen() -> void:
	for mitte: float in [110.0, 122.0, 134.0]:
		bruchplatte(mitte, 0.0, -0.08, Vector2(2.4, 2.4), 0.5)

	# Auf den Inseln steht je ein Hindernis, damit die Landung kein
	# Ausruhen ist.
	stacheln(116.0, -1.6, Vector2(2.6, 2.2), true, OCKER)
	feuerspeier(128.0, -2.4, 1.0, 0.0, 2.8, 0.3)
	stachelbalken(146.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.1))


## 152–200 · Sargkammer. Die Frage: Kannst du dir einen Takt merken, den
## du nur im Aufflammen siehst?
##
## Taktflächen werden hell, bevor sie tödlich werden – im Hellen ist das
## eine Vorwarnung, im Dunkeln ist es die EINZIGE Auskunft, dass die
## Fläche überhaupt da ist. Der Abschnitt dreht die Bedeutung des Bauteils
## also um: Es warnt nicht vor einer Gefahr, es zeigt einen Weg.
func _sargkammer_bauen() -> void:
	taktflaeche(158.0, 0.0, Vector2(3.2, 3.2), 0.0)
	taktwelle(166.0, 184.0, 6, 0.0, Vector2(2.8, 2.8), 0.2)

	feuerspeier(172.0, -3.2, 1.0, 0.0, 3.4, 0.0, true)
	feuerspeier(180.0, 3.2, 1.0, 180.0, 3.2, 0.5)

	# Zwei Sarkophage als Deckung. Der Deckungsfleck nutzt unser Krabbeln:
	# geduckt ist man dort unangreifbar.
	deckungsfleck(163.0, 2.4)
	deckungsfleck(190.0, -2.4)

	plattform(194.0, -2.6, 0.45, Vector3(2.4, 0.9, 4.2), _sockelstein())
	plattform(194.0, 2.6, 0.45, Vector3(2.4, 0.9, 4.2), _sockelstein())
	stachelbalken(198.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.2))


## 200–250 · Totenwasser. Die Frage: Trittst du auf etwas, das gleich
## weg ist?
##
## Sieben Sargdeckel im Abstand von viereinhalb Metern, versetzt getaktet.
## Jeder ist unter der Lichtweite entfernt, jeder leuchtet von selbst –
## sonst wäre die Überfahrt ein Blindflug. Das Leuchten kommt aus
## `Leuchtmarker.knoten_markieren()`, dem zweiten Werkzeug des Steckbriefs:
## Was der Spieler treffen soll, bleibt sichtbar, alles andere darf im
## Schwarz verschwinden.
func _totenwasser_bauen() -> void:
	var stellen: Array[float] = [211.0, 215.5, 220.0, 224.5, 229.0, 233.0]
	var seiten: Array[float] = [0.0, -1.6, 1.4, -1.2, 1.6, 0.0]
	for i in stellen.size():
		var deckel := wehrbohle(stellen[i], seiten[i], BOHLE_OBEN, BOHLE_UNTEN,
				float(i) * 0.16, Vector2(3.4, 3.0), 2.6, 1.0)
		Leuchtmarker.knoten_markieren(deckel, 1.1, KRISTALL)

	# Zwei Minen an Ketten von der Decke: Sie pendeln quer über die Rinne
	# und sind das Einzige, was einen vom Warten auf den Takt abhält.
	treibmine(217.0, 1.8, BOHLE_DECK + 0.9, 1.8, 3.6, 0.0, 3.0)
	treibmine(227.0, -1.8, BOHLE_DECK + 0.9, 1.6, 3.0, 0.4, 3.0)

	# Ein Balken über dem ersten Ufer – wer mit Schwung ankommt, wird
	# gebremst, bevor die Überfahrt anfängt.
	stachelbalken(206.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


## 250–300 · Grabkammer. Die Frage: Kämpfen, wo man nur den nächsten
## Schritt sieht.
##
## Der einzige weite Raum des Levels, und er ist die Belohnung: Nach 250 m
## Gang von sieben Metern Breite fühlen sich vierzehn an wie eine Halle.
## Hier stehen die Kristalle – vier eigene Punktlichter, die der
## `Lichtkreis` nicht dimmt (er nimmt nur Umgebungslicht und Sonne). Sie
## sind die einzigen Orte im Level, an denen man weiter sieht als sieben
## Meter, und deshalb liegt an jedem etwas.
func _grabkammer_bauen() -> void:
	for stelle: Array in [[258.0, -4.0], [270.0, 4.2], [282.0, -4.4], [294.0, 3.8]]:
		_kristall(stelle[0], stelle[1])

	# Gestürzte Säulen als Deckung und als Sprungziel.
	plattform(264.0, 0.0, 0.6, Vector3(3.6, 1.2, 3.0), _grabstein())
	plattform(276.0, -2.0, 0.8, Vector3(3.0, 1.6, 3.0), _grabstein())
	plattform(288.0, 2.2, 0.6, Vector3(3.2, 1.2, 3.0), _grabstein())

	taktwelle(256.0, 268.0, 3, 3.0, Vector2(2.6, 2.6), 0.33)
	feuerspeier(280.0, 4.6, 1.0, 180.0, 3.6, 0.2, true)
	deckungsfleck(286.0, -3.6)


## Ein Kristallstock: leuchtende Splitter und ein eigenes Punktlicht.
##
## Das Licht ist bewusst schwach und ohne Schatten. Im
## `gl_compatibility`-Renderer sind Punktlichter in der Zahl begrenzt und
## Schatten dort am teuersten; vier ruhige Lichter sind das Äußerste, was
## neben dem wandernden Funken vertretbar ist.
func _kristall(strecke: float, seitlich: float) -> void:
	var stock := Node3D.new()
	stock.name = "Kristall"
	stock.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	stock.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(stock)

	var leuchtstoff := Materialbibliothek.leuchtend(KRISTALL, 2.6)
	var wuerfel := randi()
	seed(23100 + int(strecke))
	for i in 5:
		var splitter := MeshInstance3D.new()
		var form := PrismMesh.new()
		var hoch := randf_range(0.9, 2.4)
		form.size = Vector3(randf_range(0.28, 0.5), hoch, randf_range(0.28, 0.5))
		splitter.mesh = form
		splitter.material_override = leuchtstoff
		splitter.position = Vector3(randf_range(-0.8, 0.8), hoch * 0.5,
				randf_range(-0.8, 0.8))
		splitter.rotation = Vector3(randf_range(-0.2, 0.2), randf() * TAU,
				randf_range(-0.2, 0.2))
		stock.add_child(splitter)
	seed(wuerfel)

	var licht := OmniLight3D.new()
	licht.light_color = KRISTALL
	licht.light_energy = 0.9
	licht.omni_range = 9.0
	licht.omni_attenuation = 1.4
	licht.shadow_enabled = false
	licht.position.y = 1.4
	stock.add_child(licht)


# =========================================================== Kantenmarken

## Leuchtende Pflöcke an jeder Abbruchkante.
##
## `luecken_markieren()` setzt schon Warnbalken, aber deren Leuchten ist
## für ein helles Level bemessen. Hier kommt je Kante ein Paar kleiner
## Marken dazu, die im Ocker des Lichtkreises glühen. Sie sind die
## Umsetzung des Satzes aus dem `Leuchtmarker`-Kopf: "Sichtbar bleibt, was
## man braucht – Kisten, Früchte, Wegkanten."
func _kantenmarken_setzen() -> void:
	var stoff := Materialbibliothek.leuchtend(OCKER.lightened(0.25), 3.0)
	for i in STRECKE.size() - 1:
		var a: Dictionary = STRECKE[i]
		var b: Dictionary = STRECKE[i + 1]
		if b["von"] - a["bis"] < 0.5:
			continue
		_marke(a["bis"] - 0.35, a.get("breite_ende", a["breite"]), stoff)
		_marke(b["von"] + 0.35, b["breite"], stoff)


func _marke(strecke: float, breite: float, stoff: Material) -> void:
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	for seite: float in [-1.0, 1.0]:
		var pflock := MeshInstance3D.new()
		var form := BoxMesh.new()
		form.size = Vector3(0.22, 0.5, 0.22)
		pflock.mesh = form
		pflock.material_override = stoff
		pflock.position = LevelWerkzeuge.punkt(verlauf, strecke,
				seite * (breite * 0.5 - 0.4), 0.3)
		pflock.rotation.y = dreh
		deko.add_child(pflock)


# =========================================================== Deko

## Geröll am Wegrand. Sehr sparsam: Was außerhalb des Lichtkreises steht,
## ist ohnehin schwarz, und was darin steht, soll den Blick nicht von den
## leuchtenden Dingen abziehen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(23001)
	for i in 34:
		var s := randf_range(3.0, M_ENDE - 6.0)
		var rand := rand_bei(s, 1.2)
		if rand < 1.4:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var brocken := STEIN.instantiate() as Node3D
		brocken.set("saat", 23200 + i)
		brocken.set("groesse", randf_range(0.5, 1.5))
		brocken.set("bemoost", false)
		brocken.set("kollision", false)
		brocken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		brocken.rotation.y = randf() * TAU
		deko.add_child(brocken)
	seed(wuerfel)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 5.0)


# =========================================================== Kisten

## 49 Kisten. Sie sind im Dunkellevel mehr als Beute: Der `Leuchtmarker`
## macht jede zu einer Laterne, und ihre Farbe ist im Schwarz die einzige
## Auskunft darüber, womit man es zu tun hat. Deshalb liegen sie hier
## dichter an der Weglinie als sonst – sie zeichnen den Weg.
func _kisten_setzen() -> void:
	# ---------- Grabmund ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.2)
	kiste(Kiste.Art.NORMAL, 9.0, -2.0)
	kiste(Kiste.Art.NORMAL, 9.0, 0.0)
	kiste(Kiste.Art.NORMAL, 9.0, 2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 18.0, 0.0)
	kiste(Kiste.Art.NORMAL, 26.0, -2.0)
	kiste(Kiste.Art.EISEN, 26.0, 1.8)
	kiste(Kiste.Art.NORMAL, 26.0, 1.8, 1.6, true)
	kiste(Kiste.Art.SCHUTZ, 36.0, 0.0)
	kiste(Kiste.Art.NORMAL, 43.0, -1.6)

	# ---------- Fackelgang ----------
	kiste(Kiste.Art.NORMAL, 50.0, -1.8)
	kiste(Kiste.Art.NORMAL, 55.0, 1.8)
	kiste(Kiste.Art.CHECKPOINT, 66.0, -2.0)
	kiste(Kiste.Art.TNT, 74.0, 0.0)
	kiste(Kiste.Art.NORMAL, 74.0, 2.0)
	kiste(Kiste.Art.NORMAL, 81.0, -2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 92.0, 0.0)
	kiste(Kiste.Art.NORMAL, 97.0, 1.8)

	# ---------- Schachtgrube: nur auf den Inseln ----------
	kiste(Kiste.Art.NORMAL, 104.0, -1.5)
	kiste(Kiste.Art.NORMAL, 104.0, 1.5)
	kiste(Kiste.Art.NORMAL, 118.0, 1.4)
	kiste(Kiste.Art.CHECKPOINT, 128.0, -1.6)
	kiste(Kiste.Art.NORMAL, 128.0, 1.6)
	kiste(Kiste.Art.NORMAL, 142.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 148.0, -1.8)
	kiste(Kiste.Art.NORMAL, 150.0, 1.8)

	# ---------- Sargkammer ----------
	kiste(Kiste.Art.NORMAL, 156.0, -2.2)
	kiste(Kiste.Art.NORMAL, 156.0, 2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 162.0, 0.0)
	kiste(Kiste.Art.NORMAL, 176.0, -2.4)
	kiste(Kiste.Art.NORMAL, 176.0, 2.4)
	kiste(Kiste.Art.CHECKPOINT, 196.0, 0.0)
	kiste(Kiste.Art.NORMAL, 188.0, -2.2)

	# ---------- Totenwasser: nur auf den Ufern ----------
	kiste(Kiste.Art.NORMAL, 203.0, -2.0)
	kiste(Kiste.Art.NORMAL, 203.0, 2.0)
	kiste(Kiste.Art.SCHUTZ, 240.0, 1.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 244.0, 0.0)
	kiste(Kiste.Art.NORMAL, 247.0, -1.8)

	# ---------- Grabkammer ----------
	kiste(Kiste.Art.CHECKPOINT, 254.0, -2.6)
	kiste(Kiste.Art.NORMAL, 260.0, -3.0)
	kiste(Kiste.Art.NORMAL, 260.0, 0.0)
	kiste(Kiste.Art.NORMAL, 260.0, 3.0)
	kiste(Kiste.Art.EISEN, 268.0, -2.6)
	kiste(Kiste.Art.NORMAL, 268.0, -2.6, 1.6, true)
	kiste(Kiste.Art.FEDER, 274.0, 3.2)
	kiste(Kiste.Art.LEBEN, 282.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 288.0, -3.2)
	kiste(Kiste.Art.NORMAL, 292.0, 2.6)
	kiste(Kiste.Art.NORMAL, 296.0, 0.0)


# =========================================================== Gegner

## 16 Gegner, und alle auf festem Boden.
##
## Über dem Totenwasser steht keiner: Ein patrouillierender Gegner stünde
## dort still im Raum, während der Sargdeckel unter dem Spieler wegtaucht.
func _gegner_setzen() -> void:
	# ---------- Grabmund ----------
	gegner(PANZERKAEFER, 12.0, -2.0, 3.0, true)
	gegner(SUMPFKROETE, 31.0, 1.5, 2.5, true)

	# ---------- Fackelgang ----------
	gegner(STELZENSPINNE, 54.0, 0.0, 2.2, true)
	gegner(SUMPFKROETE, 76.0, 0.0, 2.0, true)
	werfer(92.0, -2.0)

	# ---------- Schachtgrube ----------
	gegner(PANZERKAEFER, 105.0, 0.0, 1.8, true)
	gegner(STELZENSPINNE, 144.0, 0.0, 2.2, true)

	# ---------- Sargkammer ----------
	gegner(SUMPFKROETE, 160.0, -1.5, 2.4, true)
	gegner(PANZERKAEFER, 178.0, 1.5, 3.0, true)
	schwarm(190.0, 0.0, 10.0)

	# ---------- Totenwasser: nur auf dem Ufer ----------
	gegner(STELZENSPINNE, 205.0, 0.0, 2.0, true)

	# ---------- Grabkammer: die dichteste Stelle ----------
	gegner(PANZERKAEFER, 257.0, -3.0, 4.0, true)
	gegner(SUMPFKROETE, 266.0, 2.5, 3.5, true)
	werfer(272.0, -4.5)
	schwarm(284.0, 0.0, 10.0)
	gegner(STELZENSPINNE, 292.0, 2.5, 3.0, true)


# =========================================================== Früchte

## Früchte sind hier die Wegmarkierung. Der `Leuchtmarker` gibt jeder ihr
## eigenes Leuchten, und eine Reihe leuchtender Punkte ist im Schwarz das,
## was anderswo der Blick nach vorn ist: die Auskunft, wo es langgeht.
func _fruechte_setzen() -> void:
	fruechte_reihe(5.0, 38.0, 13, 0.0)
	fruechte_reihe(48.0, 98.0, 18, 0.0)
	# Über den drei Löchern: der Bogen zeigt die Sprungbahn an.
	fruechte_bogen(107.0, 113.0, 5, 0.0, 1.8)
	fruechte_bogen(119.0, 125.0, 5, 0.0, 1.8)
	fruechte_bogen(131.0, 137.0, 5, 0.0, 1.8)
	fruechte_reihe(139.0, 150.0, 5, 0.0)
	fruechte_reihe(154.0, 198.0, 16, 0.0)
	# Über dem Totenwasser tiefer, weil man dort auf den Deckeln steht.
	fruechte_reihe(211.0, 233.0, 7, 0.0, BOHLE_DECK + 0.9)
	fruechte_reihe(238.0, 249.0, 5, 0.0)
	fruechte_reihe(252.0, 298.0, 17, 0.0)


# =========================================================== Dunkelheit

## Der letzte Bauschritt: Licht aus.
##
## `dunkelheit()` dimmt Umgebungslicht, Himmel und Sonne, hängt der Figur
## den Funken an und lässt danach `Leuchtmarker` über den fertigen Baum
## laufen. Alles, was leuchten soll, muss also VORHER dastehen – deshalb
## kommen Kisten, Früchte, Sargdeckel und Kantenmarken alle vor diesem
## Schritt.
func _dunkelheit_setzen() -> void:
	dunkelheit(LICHTWEITE, 0.05)


## Nach dem Tod baut `LevelBasis` Kisten und Gegner aus dem Bauplan neu
## auf – als frische Knoten mit den geteilten Materialien der Bibliothek.
## Ohne diese Auffrischung stünden ab dem ersten Tod stockdunkle Kisten
## im Gang, und das Level wäre unspielbar.
func _nach_aufbau() -> void:
	GameState.level_zuruecksetzen.connect(_auf_neuaufbau)


func _auf_neuaufbau(_von_vorn: bool) -> void:
	_leuchten_auffrischen.call_deferred()


func _leuchten_auffrischen() -> void:
	Leuchtmarker.markieren(self, ["kisten", "fruechte"], 1.4)
