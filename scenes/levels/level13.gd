extends KorridorLevel
## Level 13 – "Pfahlfeste"
##
## Eine Holzfestung, die außen an einer Felsschulter hängt. Der Weg führt
## nicht vorwärts, sondern HINAUF: In sechzehn Absätzen legt er 44 Höhen-
## meter zurück, und zwischen je zwei Absätzen klafft eine Lücke, die nur
## über eine Kette aus Pfahlstufen zu nehmen ist.
##
## Damit stellt das Level eine Frage, die keines der bisherigen stellt:
## Ein Fehler kostet hier nicht Schaden, sondern HÖHE. Wer von der dritten
## Stufe fällt, steht wieder unten am Absatz – der Weg ist derselbe, aber
## er muss noch einmal gegangen werden.
##
##     0 –  55  Sandtor       breiter Vorplatz, das erste geschnitzte Tor
##    55 – 107  Speertreppe   Speersäulen AUF den Stufen
##   107 – 155  Feuergalerie  Feuerdüsen quer über die Lücken
##   155 – 211  Wurfpodeste   Werfer über dem Aufstieg
##   211 – 279  Fackelgrat    alles zugleich, ohne Pause
##   279 – 306  Große Pforte  das Tor am Ende des Aufstiegs
##
## Warum die Fallen AUF den Stufen stehen und nicht daneben: Eine Falle
## neben dem Weg ist ein Hindernis, eine Falle auf der Stufe ist eine
## Frage nach dem Takt. Die Speersäule fährt ein und aus; die Stufe ist
## nur dazwischen begehbar, und die nächste Stufe wartet nicht.
##
## Die Gestaltung ist absichtlich arm an Formen und reich an Farbe: Alles
## hier sind schlichte Kästen aus warmem Holz, und was sie unterscheidet,
## sind die aufgemalten Bänder in Rot, Türkis und Ocker. Die Muster sind
## das Design – so wie beim Vorbild (doku/level-vorbilder.md, 3-3).

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --- Farben ---------------------------------------------------------
# `Farben` kennt keine Stammesfarben; die drei Musterfarben stehen
# deshalb lokal. Sie sind bewusst gesättigter als alles andere im Level:
# Wo Farbe ist, ist etwas gebaut worden.
const MUSTER_ROT := Color(0.74, 0.20, 0.09)
const MUSTER_TUERKIS := Color(0.11, 0.56, 0.52)
const MUSTER_OCKER := Color(0.82, 0.62, 0.20)
## Gemessene Leitfarben des Vorbilds: #935C1A Pfahlholz, #6E4B18 Balken,
## #B19045 Sand, #572A08 Schatten.
const PFAHLHOLZ := Color(0.576, 0.361, 0.102)
const BALKENHOLZ := Color(0.431, 0.294, 0.094)
const SANDSTEIN := Color(0.694, 0.565, 0.271)
const TIEFENHOLZ := Color(0.341, 0.165, 0.031)

# --- Streckenmarken -------------------------------------------------
const M_SANDTOR := 0.0
const M_SPEERTREPPE := 55.0
const M_FEUERGALERIE := 107.0
const M_WURFPODESTE := 155.0
const M_FACKELGRAT := 211.0
const M_PFORTE := 279.0
const M_ENDE := 306.0

## Ab hier abwärts ist der Sturz tödlich. Flach gehalten, weil unter der
## Festung nichts als Luft ist – ein tiefer Wert würde den Sturz nur
## verlängern, ohne ihn spannender zu machen.
const ABSTURZ := -4.2

## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
## Aufrechte Kapsel 1,30 m, flache 0,76 m.
const KRIECHHOEHE := 0.95

## Die neun Absätze. Alles dazwischen ist Lücke und wird über
## Pfahlstufen genommen; die Kurve steigt genau dort am stärksten an.
const STRECKE := [
	{"von": 0.0, "bis": 42.0, "breite": 15.0, "breite_ende": 9.0},
	{"von": 55.0, "bis": 75.0, "breite": 8.5},
	{"von": 87.0, "bis": 107.0, "breite": 8.0},
	{"von": 120.0, "bis": 142.0, "breite": 8.0},
	{"von": 155.0, "bis": 177.0, "breite": 8.5},
	{"von": 190.0, "bis": 211.0, "breite": 8.0},
	{"von": 224.0, "bis": 246.0, "breite": 7.5},
	{"von": 259.0, "bis": 279.0, "breite": 7.5},
	{"von": 292.0, "bis": 306.0, "breite": 13.0},
]

## Unten sandiger Grund, ab der Feuergalerie nur noch Bohlen: Der
## Untergrund erzählt mit, wie weit man vom Boden weg ist.
const BODEN_SAND := [
	{"von": 0.0, "bis": 42.0, "breite": 15.0, "breite_ende": 9.0},
	{"von": 55.0, "bis": 75.0, "breite": 8.5},
	{"von": 87.0, "bis": 107.0, "breite": 8.0},
]
const BODEN_BOHLEN := [
	{"von": 120.0, "bis": 142.0, "breite": 8.0},
	{"von": 155.0, "bis": 177.0, "breite": 8.5},
	{"von": 190.0, "bis": 211.0, "breite": 8.0},
	{"von": 224.0, "bis": 246.0, "breite": 7.5},
	{"von": 259.0, "bis": 279.0, "breite": 7.5},
	{"von": 292.0, "bis": 306.0, "breite": 13.0},
]

## Die acht Lücken, je {"von", "bis", "stufen"}. Nach oben werden die
## Ketten kürzer und die Stufen damit weiter – das Level wird schwerer,
## ohne dass ein neues Bauteil dazukommt.
const LUECKEN := [
	{"von": 42.0, "bis": 55.0, "stufen": 5},
	{"von": 75.0, "bis": 87.0, "stufen": 5},
	{"von": 107.0, "bis": 120.0, "stufen": 5},
	{"von": 142.0, "bis": 155.0, "stufen": 4},
	{"von": 177.0, "bis": 190.0, "stufen": 4},
	{"von": 211.0, "bis": 224.0, "stufen": 4},
	{"von": 246.0, "bis": 259.0, "stufen": 4},
	{"von": 279.0, "bis": 292.0, "stufen": 4},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Die Feste wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Absätze und Stege", "tun": _boden_bauen},
		{"text": "Pfähle werden gerammt", "tun": _pfahlwerk_bauen},
		{"text": "Festungswand", "tun": _festungswand_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Dschungelrücken", "tun": _horizont_bauen},
		{"text": "Pfahlstufen", "tun": _aufstiege_bauen},
		{"text": "Speertreppe", "tun": _speertreppe_bauen},
		{"text": "Feuergalerie", "tun": _feuergalerie_bauen},
		{"text": "Wurfpodeste", "tun": _wurfpodeste_bauen},
		{"text": "Fackelgrat", "tun": _fackelgrat_bauen},
		{"text": "Die große Pforte", "tun": _pforte_bauen},
		{"text": "Licht über der Feste", "tun": _stimmungen_setzen},
		{"text": "Dschungel ringsum", "tun": _wald_bauen},
		{"text": "Gestrüpp und Kleinzeug", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Ein großer Bogen um die Schulter des Berges, gegen den Uhrzeigersinn
## und dabei stetig steigend. Die Kurve dreht IMMER nach links, damit
## rechts vom Weg nie etwas anderes liegt als der Abgrund – das ist die
## Ordnung, an die sich der Spieler gewöhnen soll: Bergseite links,
## Leere rechts.
##
## Die Höhe steigt in Stufen: Auf den Absätzen bleibt sie fast gleich, in
## den Lücken springt sie um dreieinhalb Meter. Genau daraus wird die
## Pfahlstufenkette, denn eine Stufe auf Weghöhe steht dort automatisch
## höher als die davor.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0.0, 0.00, 26.0),
		Vector3(6.0, 0.34, 25.3),
		Vector3(11.9, 0.69, 24.2),
		Vector3(17.7, 1.03, 22.8),
		Vector3(23.5, 1.37, 21.0),
		Vector3(29.1, 1.71, 18.8),
		Vector3(34.6, 2.06, 16.3),
		Vector3(39.9, 2.40, 13.4),
		Vector3(44.9, 4.20, 10.2),
		Vector3(49.8, 6.00, 6.6),
		Vector3(54.9, 6.53, 2.3),
		Vector3(59.7, 7.07, -2.3),
		Vector3(64.2, 7.60, -7.4),
		Vector3(67.8, 9.40, -12.1),
		Vector3(71.2, 11.20, -17.1),
		Vector3(74.5, 11.73, -23.0),
		Vector3(77.3, 12.27, -29.0),
		Vector3(79.7, 12.80, -35.3),
		Vector3(81.4, 14.60, -41.0),
		Vector3(82.7, 16.40, -46.9),
		Vector3(83.6, 16.85, -52.4),
		Vector3(84.1, 17.30, -57.8),
		Vector3(84.2, 17.75, -63.4),
		Vector3(84.0, 18.20, -68.9),
		Vector3(83.4, 20.00, -74.9),
		Vector3(82.3, 21.80, -80.8),
		Vector3(80.9, 22.25, -86.1),
		Vector3(79.2, 22.70, -91.4),
		Vector3(77.2, 23.15, -96.5),
		Vector3(74.8, 23.60, -101.5),
		Vector3(71.8, 25.40, -106.7),
		Vector3(68.4, 27.20, -111.7),
		Vector3(65.0, 27.65, -116.0),
		Vector3(61.3, 28.10, -120.1),
		Vector3(57.3, 28.55, -123.9),
		Vector3(53.0, 29.00, -127.5),
		Vector3(48.2, 30.80, -131.0),
		Vector3(43.0, 32.60, -134.1),
		Vector3(38.1, 33.05, -136.6),
		Vector3(33.0, 33.50, -138.7),
		Vector3(27.8, 33.95, -140.5),
		Vector3(22.4, 34.40, -141.9),
		Vector3(16.5, 36.20, -142.9),
		Vector3(10.5, 38.00, -143.5),
		Vector3(3.8, 38.53, -143.6),
		Vector3(-2.8, 39.07, -143.1),
		Vector3(-9.4, 39.60, -141.9),
		Vector3(-15.3, 41.40, -140.4),
		Vector3(-20.9, 43.20, -138.4),
		Vector3(-26.4, 43.47, -135.9),
		Vector3(-31.7, 43.73, -133.0),
		Vector3(-36.7, 44.00, -129.6),
	])


# =========================================================== Grund

func _boden_bauen() -> void:
	var form := {"tiefe": 3.4, "schritt": 1.0,
			"kante_hoehe": 0.26, "kante_breite": 0.75}
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_SAND, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.kistenholz(BALKENHOLZ),
		"klippe": Materialbibliothek.kistenholz(TIEFENHOLZ),
	}, form)
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_BOHLEN, {
		"oben": Materialbibliothek.bohlen(),
		"kante": Materialbibliothek.kistenholz(PFAHLHOLZ),
		"klippe": Materialbibliothek.kistenholz(TIEFENHOLZ),
	}, form)
	luecken_markieren(MUSTER_ROT)


## Was der Feste ihren Namen gibt: Unter jedem Absatz stehen Pfähle, die
## in die Tiefe reichen. Ohne sie schwebte der Weg – und der Blick nach
## unten ist in diesem Level die halbe Miete.
func _pfahlwerk_bauen() -> void:
	for eintrag in STRECKE:
		var von: float = eintrag["von"]
		var bis: float = eintrag["bis"]
		var s := von + 3.0
		while s < bis:
			var halbe := maxf(breite_bei(s) * 0.5 - 1.2, 1.0)
			for seite: float in [-1.0, 1.0]:
				_pfahl(s, seite * halbe, -3.2, 13.0)
			s += 7.0


## Ein einzelner Pfahl mit drei aufgemalten Bändern. Reine Kulisse.
func _pfahl(strecke: float, seitlich: float, kopf: float,
		laenge: float = 9.0) -> void:
	var stamm := CylinderMesh.new()
	stamm.top_radius = 0.34
	stamm.bottom_radius = 0.26
	stamm.height = laenge
	stamm.radial_segments = 7
	var mi := MeshInstance3D.new()
	mi.mesh = stamm
	mi.material_override = Materialbibliothek.kistenholz(PFAHLHOLZ)
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
			kopf - laenge * 0.5)
	deko.add_child(mi)

	var farben := [MUSTER_ROT, MUSTER_TUERKIS, MUSTER_OCKER]
	for i in 3:
		var ring := CylinderMesh.new()
		ring.top_radius = 0.37
		ring.bottom_radius = 0.37
		ring.height = 0.22
		ring.radial_segments = 7
		var band := MeshInstance3D.new()
		band.mesh = ring
		band.material_override = Materialbibliothek.einfarbig(farben[i], 0.7)
		band.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
				kopf - 0.5 - float(i) * 0.6)
		deko.add_child(band)


## Die Festungswand auf der Bergseite: gestapelte Holzkästen mit
## aufgemalten Bändern.
##
## Ohne Kollision, weil sie außerhalb des Weges steht. Sie steht LINKS,
## also innen in der Kurve – rechts bleibt der Abgrund frei, damit ein
## Sturz immer in dieselbe Richtung geht.
func _festungswand_bauen() -> void:
	var wuerfel := randi()
	seed(13001)
	var holz := Materialbibliothek.kistenholz(PFAHLHOLZ)
	var dunkel := Materialbibliothek.kistenholz(BALKENHOLZ)
	var s := 1.0
	while s < M_ENDE - 2.0:
		var breite := breite_bei(s)
		if breite < 0.5:
			s += 3.0
			continue
		var innen := -(breite * 0.5 + 1.6)
		var lagen := 3 + (randi() % 3)
		for lage in lagen:
			var hoch := 0.9 + float(lage) * 1.7
			var kasten := BoxMesh.new()
			kasten.size = Vector3(2.6 + randf() * 0.8, 1.6,
					2.8 + randf() * 0.6)
			var mi := MeshInstance3D.new()
			mi.mesh = kasten
			mi.material_override = holz if lage % 2 == 0 else dunkel
			mi.position = LevelWerkzeuge.punkt(verlauf, s,
					innen - randf() * 0.5, hoch)
			mi.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
			deko.add_child(mi)
		# Auf jede dritte Wandsäule ein gemaltes Band.
		if int(s) % 9 < 3:
			_musterband(s, innen - 1.4, 2.6, Vector3(0.2, 1.2, 2.2),
					[MUSTER_ROT, MUSTER_TUERKIS, MUSTER_OCKER][randi() % 3])
		s += 3.2
	seed(wuerfel)


## Aufgemaltes Band – ein flacher Kasten in einer der drei Musterfarben.
func _musterband(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, farbe: Color) -> void:
	var kasten := BoxMesh.new()
	kasten.size = groesse
	var mi := MeshInstance3D.new()
	mi.mesh = kasten
	mi.material_override = Materialbibliothek.einfarbig(farbe, 0.65)
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	mi.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(12.0, 74.0)


func _horizont_bauen() -> void:
	horizont(280.0, 52.0, Color(0.29, 0.31, 0.20), Color(0.55, 0.51, 0.35),
			true, -34.0)


# =========================================================== Aufstieg

## Die Pfahlstufen in den acht Lücken.
##
## Sie liegen auf Weghöhe, und weil die Kurve genau in den Lücken steigt,
## bilden sie von selbst eine Treppe: Jede Stufe steht dreiviertel Meter
## über der davor. Das ist der Kniff dieses Levels – die Höhe steckt im
## Verlauf, nicht in von Hand gesetzten Zahlen.
##
## Der seitliche Versatz wechselt die Seite. Eine Treppe geradeaus wäre
## zwar leichter zu treffen, aber der Blick ginge dabei nie zur Seite –
## und genau dort stehen die Werfer.
func _aufstiege_bauen() -> void:
	var holz := Materialbibliothek.kistenholz(PFAHLHOLZ)
	for i in LUECKEN.size():
		var l: Dictionary = LUECKEN[i]
		var von: float = l["von"]
		var bis: float = l["bis"]
		var anzahl: int = l["stufen"]
		# Weiter oben schmalere Stufen: gleiche Aufgabe, weniger Rand.
		var kante := 3.0 - float(i) * 0.12
		for k in anzahl:
			var t := (float(k) + 1.0) / float(anzahl + 1)
			var s := lerpf(von, bis, t)
			var seit := sin(float(k) * 1.7 + float(i)) * 1.7
			plattform(s, seit, -0.25, Vector3(kante, 0.5, kante), holz)
			_pfahl(s, seit, -0.5, 8.0)
			frucht(s, seit, 1.3)


# =========================================================== Abschnitte

## 55–107 · Speertreppe. Auf jeder zweiten Stufe fährt eine Speersäule
## aus dem Holz. Sie tötet nicht sofort – sie kostet den Takt, und der
## Takt kostet die Höhe.
func _speertreppe_bauen() -> void:
	# Erst eine einzelne Säule auf festem Boden zum Kennenlernen.
	stacheln(48.0, 0.0, Vector2(2.0, 2.0), true, MUSTER_ROT)
	stacheln(60.0, -2.2, Vector2(2.4, 2.4), true, MUSTER_ROT)
	stacheln(68.0, 2.0, Vector2(2.4, 2.4), true, MUSTER_ROT)
	# Dann auf den Stufen selbst.
	_stufenstacheln(75.0, 87.0, 5, [1, 3])
	stacheln(93.0, 0.0, Vector2(2.6, 2.6), true, MUSTER_ROT)
	stacheln(101.0, -2.0, Vector2(2.4, 2.4), true, MUSTER_ROT)
	_stufenstacheln(107.0, 120.0, 5, [1, 3])
	# Ein Balken quer über den Absatz: nur krabbelnd kommt man durch,
	# und krabbeln heißt hier stehenbleiben, während die Säule taktet.
	stachelbalken(83.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.1))


## Setzt Speersäulen auf einzelne Stufen einer Lücke.
func _stufenstacheln(von: float, bis: float, anzahl: int,
		welche: Array) -> void:
	for k in welche:
		var index: int = k
		var t := (float(index) + 1.0) / float(anzahl + 1)
		var s := lerpf(von, bis, t)
		var seit := sin(float(index) * 1.7) * 1.7
		stacheln(s, seit, Vector2(1.6, 1.6), true, MUSTER_TUERKIS)


## 107–155 · Feuergalerie. Düsen speien quer über die Lücken. Sie stehen
## dicht genug beieinander, dass immer nur EIN Fenster offen ist – wer
## das zweite abwarten will, verliert die Stufe unter sich nicht, aber
## den Rhythmus der ganzen Kette.
func _feuergalerie_bauen() -> void:
	feuerspeier(112.0, -3.6, 1.0, 0.0, 4.0, 0.0)
	feuerspeier(117.0, 3.6, 1.0, 180.0, 4.0, 0.5)
	feuerspeier(126.0, -3.4, 1.2, 0.0, 3.6, 0.25)
	feuerspeier(133.0, 3.4, 1.2, 180.0, 3.6, 0.6, true)
	feuerspeier(139.0, -3.4, 1.0, 0.0, 3.4, 0.1)
	feuerspeier(146.0, -3.8, 1.4, 0.0, 4.4, 0.35)
	feuerspeier(151.0, 3.8, 1.4, 180.0, 4.4, 0.8)
	# Und eine Düse, die von unten senkrecht durch die Lücke schießt:
	# der einzige Feuerspeier des Levels, der nicht quer steht.
	feuerspeier(148.5, 0.0, -2.6, -90.0, 5.0, 0.0)
	taktflaeche(122.0, 0.0, Vector2(3.0, 3.0), 0.0)
	taktflaeche(137.0, -1.8, Vector2(2.8, 2.8), 0.4)


## 155–211 · Wurfpodeste. Zwei Werfer stehen über dem Aufstieg und
## halten die Stufen unter Beschuss. Der Drehschlag räumt sie weg – aber
## dafür muss man erst zu ihnen hinauf, und der Weg dahin ist der Weg,
## den sie beschießen.
func _wurfpodeste_bauen() -> void:
	_werfer_podest(160.0, 2.8, 2.6)
	_werfer_podest(172.0, -3.0, 3.4)
	_werfer_podest(196.0, 2.6, 2.8)
	_werfer_podest(206.0, -2.6, 3.6)
	# Gegen die Werfer hilft Deckung: zwei Flecken, in denen man geduckt
	# sicher ist, jeweils kurz vor der nächsten Lücke.
	deckungsfleck(166.0, -2.0)
	deckungsfleck(201.0, 1.8)
	# Und ein Schiebeblock, der genau dort quer fährt, wo man wartet.
	schiebeblock(175.0, 0.0, 0.0, Vector3(1.8, 1.3, 1.8), 3.4, true, 1.5, 0.9)
	schiebeblock(203.0, 0.0, 0.0, Vector3(1.8, 1.3, 1.8), 3.2, true, 1.5, 0.9,
			0.5)


## Werfer auf einem Podest.
##
## `werfer()` setzt immer auf Weghöhe – hier soll er darüber stehen, damit
## die Würfe von oben kommen. Deshalb wird er von Hand gesetzt: Position
## VOR `add_child`, sonst merkt sich `Gegner._ready()` den falschen Platz
## und zieht ihn beim ersten Bild dorthin zurück.
func _werfer_podest(strecke: float, seitlich: float, hoehe: float) -> Werfer:
	var dicke := hoehe + 0.8
	plattform(strecke, seitlich, hoehe - dicke * 0.5,
			Vector3(3.0, dicke, 3.0),
			Materialbibliothek.kistenholz(BALKENHOLZ))
	_musterband(strecke, seitlich, hoehe - 0.7, Vector3(3.1, 0.34, 3.1),
			MUSTER_TUERKIS)
	var w := WERFER.instantiate() as Werfer
	w.patrouille_weite = 0.0
	w.wurftakt = 2.8
	w.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	return w


## 211–279 · Fackelgrat. Die dichteste Stelle: Speersäule, Feuer und
## Wurfgeschoss auf demselben Absatz. Neu ist hier nichts – neu ist nur,
## dass drei Takte gleichzeitig laufen.
func _fackelgrat_bauen() -> void:
	taktwelle(228.0, 242.0, 5, 0.0, Vector2(2.6, 2.6), 0.22)
	feuerspeier(232.0, -3.2, 1.0, 0.0, 3.6, 0.0, true)
	feuerspeier(240.0, 3.2, 1.0, 180.0, 3.6, 0.45)
	stacheln(236.0, 2.0, Vector2(2.2, 2.2), true, MUSTER_ROT)
	_werfer_podest(244.0, -2.4, 3.2)

	_stufenstacheln(246.0, 259.0, 4, [0, 2])

	stachelbalken(263.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.1))
	taktwelle(266.0, 276.0, 4, 0.0, Vector2(2.6, 2.6), 0.3)
	feuerspeier(270.0, -3.2, 1.2, 0.0, 3.6, 0.2)
	feuerspeier(274.0, 3.2, 1.2, 180.0, 3.6, 0.7, true)
	schiebeblock(268.0, 0.0, 0.0, Vector3(1.6, 1.3, 1.6), 3.0, true, 1.3, 0.7)

	# Ein Tor auf halbem Grat als Wegmarke – geschnitzt, nicht gefährlich.
	_tor(255.0, 6.0, 3.4)


## 279–306 · Die große Pforte. Der letzte Aufstieg endet vor einem Tor,
## das doppelt so hoch ist wie alles davor. Dahinter liegt der Absatz
## mit dem Zielportal, breit und ohne eine einzige Falle: Nach 44 Höhen-
## metern gehört dem Spieler die letzte Minute allein.
func _pforte_bauen() -> void:
	_tor(294.0, 9.0, 6.4)
	_musterband(294.0, 0.0, 7.4, Vector3(11.0, 0.6, 0.6), MUSTER_ROT)
	_musterband(294.0, 0.0, 8.2, Vector3(9.0, 0.5, 0.5), MUSTER_TUERKIS)
	# Zwei Wachfackeln, das einzige eigene Licht des Levels.
	for seite: float in [-1.0, 1.0]:
		var glut := OmniLight3D.new()
		glut.light_color = Color(1.0, 0.62, 0.24)
		glut.light_energy = 3.2
		glut.omni_range = 12.0
		glut.position = LevelWerkzeuge.punkt(verlauf, 294.0, seite * 4.6, 4.2)
		deko.add_child(glut)
		var schale := SphereMesh.new()
		schale.radius = 0.34
		schale.height = 0.68
		var mi := MeshInstance3D.new()
		mi.mesh = schale
		mi.material_override = Materialbibliothek.leuchtend(
				Color(1.0, 0.66, 0.24), 2.4)
		mi.position = LevelWerkzeuge.punkt(verlauf, 294.0, seite * 4.6, 4.2)
		deko.add_child(mi)


## Geschnitztes Tor: zwei Pfosten, ein Sturz, drei Bänder.
##
## Die Pfosten tragen Kollision und stehen deshalb am Wegrand – ein Tor,
## durch das man nicht durchpasst, ist kein Tor, sondern eine Wand.
func _tor(strecke: float, breite: float, hoehe: float) -> void:
	var holz := Materialbibliothek.kistenholz(BALKENHOLZ)
	var halb := breite * 0.5
	for seite: float in [-1.0, 1.0]:
		plattform(strecke, seite * halb, hoehe * 0.5,
				Vector3(0.9, hoehe, 0.9), holz)
		_musterband(strecke, seite * halb, hoehe * 0.55,
				Vector3(1.0, 0.5, 1.0), MUSTER_OCKER)
		_musterband(strecke, seite * halb, hoehe * 0.8,
				Vector3(1.0, 0.4, 1.0), MUSTER_TUERKIS)
	plattform(strecke, 0.0, hoehe + 0.5, Vector3(breite + 2.2, 1.0, 1.1), holz)
	_musterband(strecke, 0.0, hoehe + 1.15, Vector3(breite + 2.4, 0.34, 1.2),
			MUSTER_ROT)


## Licht und Dunst über der Feste.
##
## Unten am Sandtor steht die Luft warm und staubig; ganz oben wird sie
## dünner und heller. Das ist der einzige Hinweis darauf, wie weit man
## gestiegen ist, der ohne einen Blick nach unten auskommt.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 60.0, Color(0.68, 0.52, 0.30), 0.016, 1.0,
			Color(0.72, 0.58, 0.36), 52.0)
	stimmung(120.0, 190.0, Color(0.72, 0.60, 0.40), 0.011, 1.1,
			Color(0.78, 0.66, 0.46), 52.0)
	stimmung(240.0, M_ENDE, Color(0.82, 0.74, 0.56), 0.007, 1.25,
			Color(0.86, 0.78, 0.60), 58.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Sandtor: Platz zum Ausprobieren ----------
	kiste(Kiste.Art.CHECKPOINT, 6.0, -2.6)
	kiste(Kiste.Art.NORMAL, 10.0, -2.2)
	kiste(Kiste.Art.NORMAL, 10.0, 0.0)
	kiste(Kiste.Art.NORMAL, 10.0, 2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 16.0, 0.0)
	kiste(Kiste.Art.EISEN, 22.0, 2.6)
	kiste(Kiste.Art.NORMAL, 22.0, 2.6, 1.6)
	kiste(Kiste.Art.NORMAL, 27.0, -2.8)
	kiste(Kiste.Art.SCHUTZ, 33.0, 0.0)
	kiste(Kiste.Art.NORMAL, 38.0, 2.0)
	kiste(Kiste.Art.FEDER, 40.0, -2.0)

	# ---------- Speertreppe ----------
	kiste(Kiste.Art.CHECKPOINT, 68.0, -2.4)
	kiste(Kiste.Art.NORMAL, 63.0, 2.2)
	kiste(Kiste.Art.NORMAL, 66.0, -2.4)
	kiste(Kiste.Art.TNT, 71.0, 0.0)
	kiste(Kiste.Art.NORMAL, 71.0, -2.2)
	kiste(Kiste.Art.NORMAL, 90.0, 2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 96.0, -2.0)
	kiste(Kiste.Art.NORMAL, 99.0, 2.2)
	kiste(Kiste.Art.SCHUTZ, 105.0, 0.0)

	# ---------- Feuergalerie ----------
	kiste(Kiste.Art.CHECKPOINT, 132.0, 0.0)
	kiste(Kiste.Art.NORMAL, 128.0, 2.2)
	kiste(Kiste.Art.NORMAL, 131.0, -2.2)
	kiste(Kiste.Art.EISEN, 135.0, 2.4)
	kiste(Kiste.Art.NORMAL, 135.0, 2.4, 1.6)
	kiste(Kiste.Art.NORMAL, 140.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 158.0, -2.4)
	kiste(Kiste.Art.NORMAL, 163.0, -1.0)

	# ---------- Wurfpodeste ----------
	kiste(Kiste.Art.NORMAL, 169.0, 2.4)
	kiste(Kiste.Art.SCHUTZ, 174.0, -2.4)
	kiste(Kiste.Art.NORMAL, 176.0, 1.2)
	kiste(Kiste.Art.CHECKPOINT, 196.0, -2.2)
	kiste(Kiste.Art.NORMAL, 194.0, 2.2)
	kiste(Kiste.Art.NITRO, 199.0, 0.0)
	kiste(Kiste.Art.NORMAL, 199.0, -2.4)
	kiste(Kiste.Art.NORMAL, 208.0, 2.2)
	kiste(Kiste.Art.LEBEN, 210.0, -2.0)

	# ---------- Fackelgrat ----------
	kiste(Kiste.Art.NORMAL, 226.0, 2.0)
	kiste(Kiste.Art.NORMAL, 226.0, -2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 231.0, 1.6)
	kiste(Kiste.Art.NORMAL, 238.0, -1.8)
	kiste(Kiste.Art.SCHUTZ, 244.0, 2.2)
	kiste(Kiste.Art.CHECKPOINT, 266.0, -2.2)
	kiste(Kiste.Art.NORMAL, 266.0, 2.0)
	kiste(Kiste.Art.TNT, 272.0, 0.0)
	kiste(Kiste.Art.NORMAL, 272.0, -2.2)
	kiste(Kiste.Art.NORMAL, 277.0, 2.0)

	# ---------- Große Pforte ----------
	kiste(Kiste.Art.NORMAL, 296.0, -3.0)
	kiste(Kiste.Art.NORMAL, 296.0, 0.0)
	kiste(Kiste.Art.NORMAL, 296.0, 3.0)
	kiste(Kiste.Art.LEBEN, 300.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 303.0, -2.4)
	kiste(Kiste.Art.NORMAL, 303.0, 2.4)


# =========================================================== Gegner

## Gegner stehen nur auf den Absätzen, nie auf den Pfahlstufen.
##
## Auf einer Stufe von zweieinhalb Metern Kante wäre jeder Gegner ein
## reiner Zufall: Man kommt aus dem Sprung, hat keine Fläche zum
## Ausweichen und ist beim Landen wehrlos. In den Lücken übernehmen
## Speersäulen und Feuerdüsen, weil man denen im Flug ansieht, wann sie
## harmlos sind.
func _gegner_setzen() -> void:
	# ---------- Sandtor ----------
	gegner(PANZERKAEFER, 13.0, -2.0, 4.5, true)
	gegner(SUMPFKROETE, 20.0, 1.6, 3.5, true)
	gegner(STELZENSPINNE, 30.0, -1.6, 3.5, true)
	gegner(PANZERKAEFER, 37.0, 2.0, 3.0, true)

	# ---------- Speertreppe ----------
	gegner(SUMPFKROETE, 62.0, 0.0, 2.6, true)
	gegner(STELZENSPINNE, 71.0, -1.4, 2.4, true)
	gegner(PANZERKAEFER, 92.0, 1.4, 2.6, true)
	gegner(SUMPFKROETE, 102.0, -1.4, 2.4, true)

	# ---------- Feuergalerie ----------
	gegner(STELZENSPINNE, 126.0, 1.4, 2.4, true)
	gegner(PANZERKAEFER, 137.0, -1.4, 2.6, true)

	# ---------- Wurfpodeste (dazu vier Werfer auf Podesten) ----------
	gegner(SUMPFKROETE, 164.0, 1.4, 2.4, true)
	gegner(STELZENSPINNE, 170.0, -1.6, 2.4, true)
	gegner(PANZERKAEFER, 195.0, 1.6, 2.6, true)
	gegner(SUMPFKROETE, 205.0, -1.4, 2.4, true)

	# ---------- Fackelgrat ----------
	gegner(PANZERKAEFER, 229.0, -1.4, 2.4, true)
	gegner(STELZENSPINNE, 240.0, 1.4, 2.2, true)
	gegner(SUMPFKROETE, 265.0, -1.4, 2.4, true)
	gegner(STELZENSPINNE, 274.0, 1.4, 2.2, true)

	# ---------- Große Pforte: einer, als Torwache ----------
	gegner(PANZERKAEFER, 298.0, -2.4, 4.0, true)


# =========================================================== Früchte

## Auf den Absätzen führen Reihen den Blick nach vorn, über den Lücken
## Bögen den Blick nach OBEN – dort geht es weiter, und der Bogen ist die
## einzige Stelle, an der das Level das von sich aus sagt.
func _fruechte_setzen() -> void:
	fruechte_reihe(6.0, 40.0, 12, 0.0)
	fruechte_bogen(42.0, 55.0, 6, 0.0, 3.0)
	fruechte_reihe(57.0, 73.0, 7, 0.0)
	fruechte_bogen(75.0, 87.0, 6, 0.0, 3.0)
	fruechte_reihe(89.0, 105.0, 7, 0.0)
	fruechte_bogen(107.0, 120.0, 6, 0.0, 3.2)
	fruechte_reihe(122.0, 140.0, 8, 0.0)
	fruechte_bogen(142.0, 155.0, 6, 0.0, 3.2)
	fruechte_reihe(157.0, 175.0, 8, 0.0)
	fruechte_bogen(177.0, 190.0, 6, 0.0, 3.4)
	fruechte_reihe(192.0, 209.0, 8, 0.0)
	fruechte_bogen(211.0, 224.0, 6, 0.0, 3.4)
	fruechte_reihe(226.0, 244.0, 8, 0.0)
	fruechte_bogen(246.0, 259.0, 6, 0.0, 3.4)
	fruechte_reihe(261.0, 277.0, 7, 0.0)
	fruechte_bogen(279.0, 292.0, 6, 0.0, 3.6)
	fruechte_reihe(294.0, 304.0, 6, 0.0)


# =========================================================== Kulisse

## Der Dschungel liegt UNTER der Feste, nicht neben ihr.
##
## Deshalb stehen die Bäume weit draußen und tief: Von oben sieht man auf
## ihre Kronen hinunter, und daran misst der Blick die Höhe. Sie tragen
## keine Kollision – sie sollen Tiefe zeigen, nicht Boden vortäuschen.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(13002)
	for i in 96:
		var s := randf_range(-10.0, M_ENDE + 10.0)
		var seite: float = -1.0 if i % 3 == 0 else 1.0
		var quer := seite * randf_range(14.0, 46.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 5 == 0 else Baum.Art.LAUBBAUM
		baum.kronenform = Baum.Kronenform.SCHIRM if i % 3 == 0 \
				else Baum.Kronenform.BREIT
		baum.hoehe = randf_range(7.0, 14.0)
		baum.staerke = randf_range(0.7, 1.4)
		baum.saat = 13100 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.LAUB, randf())
		baum.kollision = false
		# Tief unter dem Weg: der Dschungelboden bleibt zurück, während
		# die Feste steigt.
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer,
				-16.0 - randf() * 12.0)
		deko.add_child(baum)

	for i in 30:
		var s := randf_range(0.0, M_ENDE)
		var rand := rand_bei(s, 1.4)
		if rand < 1.8:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate() as Stein
		stein.saat = 13300 + i
		stein.groesse = randf_range(0.5, 1.4)
		stein.bemoost = false
		stein.kollision = false
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)
	seed(wuerfel)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(13003)
	for i in 54:
		var s := randf_range(1.0, M_ENDE - 1.0)
		var rand := rand_bei(s, 1.1)
		if rand < 1.4:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(2.0, 2.0)
		horst.halm_hoehe = randf_range(0.28, 0.55)
		horst.farbe_unten = Farben.GRAS_DUNKEL
		horst.farbe_oben = Farben.GRAS_TROCKEN
		horst.saat = 13500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.7, rand), 0.02)
		deko.add_child(horst)

	for i in 40:
		var s := randf_range(1.0, M_ENDE - 1.0)
		var rand := rand_bei(s, 1.2)
		if rand < 1.5:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.BUSCH if i % 3 == 0 \
				else (Kleinzeug.Art.BLUME if i % 3 == 1 else Kleinzeug.Art.FARN)
		kleinzeug.saat = 13700 + i
		kleinzeug.groesse = randf_range(0.4, 0.9)
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)
