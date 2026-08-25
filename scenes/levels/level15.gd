extends KorridorLevel
## Level 15 – "Abendruinen"
##
## Das Ausdauerlevel. Kein Abschnitt ist für sich schwer; schwer ist die
## Summe. Wer achtzig Prozent schafft, fängt trotzdem von vorn an – und
## genau deshalb liegen die Checkpoints hier so dicht, wie es geht, ohne
## dass die Strecke ihren Ernst verliert.
##
## Der Weg legt sich als Wendel um einen Ruinenkern und läuft dabei ZWEIMAL
## herum: Das Obergeschoss liegt siebzehn bis zwanzig Meter über dem
## Erdgeschoss, senkrecht darüber. Wer unten durch den Unterhof läuft und
## nach oben schaut, sieht die Galerie, auf der er in vier Minuten stehen
## wird. Das ist die eigentliche Idee dieses Levels; alle Fallen darin
## sind nur die Zeit, die vergeht, bis es so weit ist.
##
##     0 –  66  Unterhof       Heizplatten im Takt, weiter Hof
##    66 – 104  Schieberflur   Blöcke schieben zur Kante
##   104 – 146  Fackelgang     schwenkende Feuerspeier
##   146 – 204  Ruinentreppe   der Aufstieg ins Obergeschoss
##   204 – 284  Säulengalerie  ÜBER dem Unterhof: Drehscheiben, Bruchplatten
##   284 – 360  Abendzinne     Dachgang als dritte Lage, dann das Ziel
##
## Farbe: türkisgrüner Ruinenstein (#34494A) gegen einen warm orange-
## farbenen Abendhimmel (#91531C). Das ist ein Komplementärkontrast, und
## er wird nicht von den Objekten getragen, sondern von der Umgebung –
## Himmel, Nebel und Sonne stehen in Level15.tscn. Die Steine sind kühl
## und stumpf; alles Warme im Bild ist Licht.

const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --- Farben ---------------------------------------------------------
# Gemessen am Vorbild (doku/level-vorbilder.md, 3-5). `Farben` kennt
# weder den türkisgrünen Ruinenstein noch das Abendorange.
const RUINENSTEIN := Color(0.204, 0.286, 0.290)      # #34494A
const RUINENSTEIN_HELL := Color(0.330, 0.451, 0.435)
const RUINENSTEIN_TIEF := Color(0.078, 0.133, 0.094) # #142218
const MOOSFUGE := Color(0.149, 0.278, 0.106)         # #26471B
const ABENDGLUT := Color(0.569, 0.325, 0.110)        # #91531C
const ERDBRAUN := Color(0.322, 0.192, 0.078)         # #523114
const FACKELLICHT := Color(1.0, 0.63, 0.26)

# --- Streckenmarken -------------------------------------------------
const M_UNTERHOF := 0.0
const M_SCHIEBERFLUR := 66.0
const M_FACKELGANG := 104.0
const M_TREPPE := 146.0
const M_GALERIE := 204.0
const M_ZINNE := 284.0
const M_ENDE := 360.0

## Flach gehalten, und das ist hier keine Kleinigkeit: Die Absturzzone
## hängt unter JEDER Weglage. Weil das Obergeschoss über dem Erdgeschoss
## liegt, schwebt seine Zone auch über dem Erdgeschoss – bei -3,2 m liegt
## sie dort neuneinhalb Meter über dem unteren Boden und damit weit über
## allem, was ein Spieler von unten aus erreichen kann. Ein tieferer Wert
## würde den Spieler im Unterhof beim Springen töten.
const ABSTURZ := -3.2

## Deshalb gilt für das Erdgeschoss: nichts Begehbares über 3,2 m.
const UNTEN_HOECHSTE := 3.2

## Höhe, unter der nur Krabbeln durchkommt.
const KRIECHHOEHE := 0.95

const STRECKE := [
	# --- Unterhof: weiter Hof, eine erste Lücke ---
	{"von": 0.0, "bis": 58.0, "breite": 12.0},
	# --- Schieberflur ---
	{"von": 66.0, "bis": 96.0, "breite": 10.5},
	# --- Fackelgang ---
	{"von": 104.0, "bis": 138.0, "breite": 10.0},
	# --- Ruinentreppe: hier geht es hinauf ---
	{"von": 146.0, "bis": 168.0, "breite": 9.0},
	{"von": 176.0, "bis": 196.0, "breite": 8.5},
	# --- Säulengalerie, über dem Unterhof ---
	{"von": 204.0, "bis": 236.0, "breite": 10.0},
	{"von": 244.0, "bis": 272.0, "breite": 10.0},
	# --- Abendzinne ---
	{"von": 280.0, "bis": 312.0, "breite": 11.0},
	{"von": 320.0, "bis": 360.0, "breite": 12.0},
]

## Die acht Lücken. Sie sind kurz – in einem Ausdauerlevel darf kein
## einzelner Sprung die Entscheidung sein.
const LUECKEN := [
	{"von": 58.0, "bis": 66.0},
	{"von": 96.0, "bis": 104.0},
	{"von": 138.0, "bis": 146.0},
	{"von": 168.0, "bis": 176.0},
	{"von": 196.0, "bis": 204.0},
	{"von": 236.0, "bis": 244.0},
	{"von": 272.0, "bis": 280.0},
	{"von": 312.0, "bis": 320.0},
]

var _stein_stoff: StandardMaterial3D
var _fugen_stoff: StandardMaterial3D


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Die Ruine wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Höfe und Galerien", "tun": _boden_bauen},
		{"text": "Trittsteine in den Lücken", "tun": _trittsteine_bauen},
		{"text": "Säulen und Bögen", "tun": _saeulen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel im Abendlicht", "tun": _horizont_bauen},
		{"text": "Unterhof", "tun": _unterhof_bauen},
		{"text": "Schieberflur", "tun": _schieberflur_bauen},
		{"text": "Fackelgang", "tun": _fackelgang_bauen},
		{"text": "Ruinentreppe", "tun": _treppe_bauen},
		{"text": "Säulengalerie", "tun": _galerie_bauen},
		{"text": "Abendzinne", "tun": _zinne_bauen},
		{"text": "Dachgang", "tun": _dachgang_bauen},
		{"text": "Fackeln werden entzündet", "tun": _fackeln_setzen},
		{"text": "Abendlicht", "tun": _stimmungen_setzen},
		{"text": "Überwachsene Ruine", "tun": _bewuchs_bauen},
		{"text": "Gestrüpp und Scherben", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Eine Wendel mit zwei Runden um denselben Kern.
##
## Der Grundriss ist kein Kreis, sondern ein abgerundetes Viereck: Der
## Radius schwankt zwischen 26 und 32 Metern, sodass vier Höfe und vier
## Ecken entstehen. Ein reiner Kreis liefe gleichförmig durch und wäre nach
## einer halben Runde nicht mehr zu unterscheiden.
##
## Die Kurve dreht immer nach LINKS. Damit liegt der Ruinenkern stets zur
## Linken und der Abgrund stets zur Rechten – eine Ordnung, die über neun
## Minuten Spielzeit mehr wert ist als jede Abwechslung.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0.0, 0.00, 32.0),
		Vector3(5.8, 0.11, 30.7),
		Vector3(10.7, 0.23, 27.2),
		Vector3(14.6, 0.34, 22.7),
		Vector3(18.6, 0.46, 18.2),
		Vector3(23.1, 0.57, 14.3),
		Vector3(27.6, 0.68, 10.3),
		Vector3(30.9, 0.80, 5.3),
		Vector3(32.0, 0.91, -0.6),
		Vector3(30.4, 1.03, -6.3),
		Vector3(26.8, 1.14, -11.1),
		Vector3(22.3, 1.25, -15.0),
		Vector3(17.8, 1.37, -19.0),
		Vector3(13.9, 1.48, -23.6),
		Vector3(9.9, 1.60, -28.0),
		Vector3(4.8, 1.71, -31.1),
		Vector3(-1.1, 1.82, -32.0),
		Vector3(-6.8, 1.94, -30.1),
		Vector3(-11.5, 2.05, -26.4),
		Vector3(-15.3, 2.17, -21.8),
		Vector3(-19.4, 2.28, -17.4),
		Vector3(-24.0, 2.39, -13.6),
		Vector3(-28.3, 2.51, -9.4),
		Vector3(-31.3, 2.62, -4.3),
		Vector3(-31.9, 2.74, 1.7),
		Vector3(-29.9, 2.85, 7.3),
		Vector3(-26.0, 2.96, 11.8),
		Vector3(-21.4, 5.40, 15.7),
		Vector3(-17.1, 7.80, 19.8),
		Vector3(-13.2, 10.20, 24.4),
		Vector3(-9.0, 12.60, 28.7),
		Vector3(-3.7, 15.00, 31.4),
		Vector3(2.2, 17.40, 31.8),
		Vector3(7.7, 19.06, 29.6),
		Vector3(12.2, 19.26, 25.6),
		Vector3(16.0, 19.45, 21.0),
		Vector3(20.2, 19.64, 16.7),
		Vector3(24.8, 19.83, 12.9),
		Vector3(29.0, 20.02, 8.6),
		Vector3(31.6, 20.22, 3.2),
		Vector3(31.7, 20.41, -2.7),
		Vector3(29.3, 20.60, -8.2),
		Vector3(25.2, 20.79, -12.6),
		Vector3(20.6, 20.98, -16.4),
		Vector3(16.3, 21.18, -20.6),
		Vector3(12.5, 21.37, -25.3),
		Vector3(8.1, 21.56, -29.3),
		Vector3(2.7, 21.75, -31.7),
		Vector3(-3.3, 21.94, -31.6),
		Vector3(-8.6, 22.14, -28.9),
		Vector3(-12.9, 22.33, -24.8),
		Vector3(-16.7, 22.52, -20.2),
		Vector3(-21.0, 22.71, -16.0),
		Vector3(-25.7, 22.90, -12.2),
		Vector3(-29.6, 23.10, -7.7),
		Vector3(-31.8, 23.29, -2.1),
		Vector3(-31.4, 23.48, 3.8),
		Vector3(-28.6, 23.67, 9.1),
		Vector3(-24.4, 23.86, 13.3),
		Vector3(-19.7, 24.06, 17.1),
		Vector3(-15.6, 24.25, 21.5),
		Vector3(-11.8, 24.44, 26.1),
		Vector3(-7.2, 24.63, 29.9),
		Vector3(-1.6, 24.82, 31.9),
	])


# =========================================================== Grund

## Ruinenstein, aus Rauschen gefärbt.
##
## Der Ton ist der gemessene Leitton des Vorbilds und bewusst STUMPF:
## Er muss den warmen Himmel tragen, nicht mit ihm streiten. Ein
## gesättigtes Türkis sähe im Abendlicht giftig aus.
func _ruinenstein() -> StandardMaterial3D:
	if _stein_stoff != null:
		return _stein_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1501, 0.05,
			RUINENSTEIN.darkened(0.3), RUINENSTEIN_HELL)
	m.normal_enabled = true
	m.normal_texture = Materialbibliothek.normalmap(1501, 0.05, 1.8)
	m.uv1_scale = Vector3(0.18, 0.18, 0.18)
	m.uv1_triplanar = true
	m.roughness = 0.95
	_stein_stoff = m
	return m


## Die bewachsene Fuge am Wegrand: dunkelgrünes Kraut aus den Ritzen.
func _fugenkraut() -> StandardMaterial3D:
	if _fugen_stoff != null:
		return _fugen_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1502, 0.09,
			RUINENSTEIN_TIEF, MOOSFUGE)
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)
	m.uv1_triplanar = true
	m.roughness = 0.98
	_fugen_stoff = m
	return m


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _ruinenstein(),
		"kante": _fugenkraut(),
		"klippe": Materialbibliothek.einfarbig(RUINENSTEIN.darkened(0.45), 1.0),
	}, {"tiefe": 3.2, "schritt": 1.0,
			"kante_hoehe": 0.28, "kante_breite": 0.8})
	luecken_markieren(ABENDGLUT)


## Trittsteine in den acht Lücken.
##
## Drei Blöcke je Lücke, seitlich versetzt. Sie sind kein Kunststück,
## sondern Atempausen: In einem Level, das über Minuten geht, muss auch
## eine Lücke ohne Nachdenken zu nehmen sein, sonst wird aus Ausdauer nur
## Zermürbung.
func _trittsteine_bauen() -> void:
	var stein := _ruinenstein()
	for i in LUECKEN.size():
		var l: Dictionary = LUECKEN[i]
		var von: float = l["von"]
		var bis: float = l["bis"]
		for k in 3:
			var t := (float(k) + 1.0) / 4.0
			var s := lerpf(von, bis, t)
			var seit := sin(float(k) * 2.1 + float(i) * 0.7) * 1.9
			plattform(s, seit, -0.3, Vector3(2.6, 0.6, 2.6), stein)
			frucht(s, seit, 1.3)


## Säulen und Bogenreste entlang des ganzen Weges.
##
## Sie stehen auf beiden Seiten, tragen aber keine Kollision: Was in
## einer Ruine im Weg steht, ist Zufall, und Zufall gehört nicht in einen
## Korridor. Sie sind Maßstab – erst an ihnen sieht man von unten, wie
## hoch die Galerie darüber liegt.
func _saeulen_bauen() -> void:
	var wuerfel := randi()
	seed(15001)
	var stein := _ruinenstein()
	var s := 3.0
	while s < M_ENDE - 3.0:
		var breite := breite_bei(s)
		if breite < 0.5:
			s += 4.0
			continue
		for seite: float in [-1.0, 1.0]:
			if randf() > 0.55:
				continue
			var hoch := randf_range(2.2, 5.4)
			var quer := seite * (breite * 0.5 + randf_range(0.9, 2.4))
			var schaft := CylinderMesh.new()
			schaft.top_radius = 0.42
			schaft.bottom_radius = 0.5
			schaft.height = hoch
			schaft.radial_segments = 8
			var mi := MeshInstance3D.new()
			mi.mesh = schaft
			mi.material_override = stein
			mi.position = LevelWerkzeuge.punkt(verlauf, s, quer, hoch * 0.5)
			deko.add_child(mi)
			# Kapitell, wenn die Säule noch steht.
			if hoch > 4.0:
				var kopf := BoxMesh.new()
				kopf.size = Vector3(1.3, 0.45, 1.3)
				var kmi := MeshInstance3D.new()
				kmi.mesh = kopf
				kmi.material_override = stein
				kmi.position = LevelWerkzeuge.punkt(verlauf, s, quer,
						hoch + 0.2)
				kmi.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
				deko.add_child(kmi)
		s += randf_range(5.0, 9.0)
	seed(wuerfel)


func _absturz_spannen() -> void:
	absturzzonen(10.0, 72.0)


## Ferne Hügel im Abendlicht. Sie liegen im Warmen, die Ruine im Kühlen –
## das ist derselbe Komplementärkontrast noch einmal, nur über die
## Entfernung gestaffelt.
func _horizont_bauen() -> void:
	horizont(300.0, 40.0, Color(0.29, 0.22, 0.16), Color(0.62, 0.42, 0.24),
			true, -30.0)


# =========================================================== Abschnitte

## 0–66 · Unterhof. Der Boden wird im Takt heiß.
##
## Die Frage dieses Abschnitts ist die einfachste des Levels und die
## einzige, die es zweimal stellt: WANN. Die Wellen laufen vor dem Spieler
## her; wer im Takt geht, geht durch, wer rennt, holt die Welle ein.
func _unterhof_bauen() -> void:
	# Erst eine einzelne Platte zum Kennenlernen, weit vor dem Rest.
	taktflaeche(12.0, 0.0, Vector2(3.4, 3.4), 0.0)
	taktflaeche(18.0, -2.4, Vector2(3.0, 3.0), 0.35)
	taktwelle(26.0, 40.0, 5, 0.0, Vector2(3.0, 3.0), 0.2)
	# Eine zweite Welle daneben, gegenläufig: Wer der ersten ausweicht,
	# landet auf der zweiten.
	taktwelle(28.0, 40.0, 4, 3.2, Vector2(2.6, 2.6), -0.25)
	taktflaeche(48.0, -1.6, Vector2(3.0, 3.0), 0.5)
	taktflaeche(54.0, 1.6, Vector2(3.0, 3.0), 0.1)
	# Ein Balken quer über den heißen Boden – krabbeln, während es taktet.
	stachelbalken(44.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))
	deckungsfleck(21.0, 2.6)


## 66–104 · Schieberflur. Blöcke fahren quer über den Weg und schieben.
##
## Der Weg ist hier zehneinhalb Meter breit, der Block fährt vier davon
## ab – es bleibt also immer Platz. Nicht der Block ist die Gefahr,
## sondern die KANTE hinter ihm: Wer stehen bleibt, wird über sie
## hinausgeschoben.
func _schieberflur_bauen() -> void:
	schiebeblock(70.0, -2.6, 0.0, Vector3(2.0, 1.3, 2.0), 4.2, true, 1.6, 1.0)
	schiebeblock(76.0, 2.6, 0.0, Vector3(2.0, 1.3, 2.0), 4.2, true, 1.6, 1.0,
			0.5)
	schiebeblock(82.0, 0.0, 0.0, Vector3(2.2, 1.3, 2.2), 5.0, true, 1.4, 0.8,
			0.25)
	# Zwei Blöcke, die LÄNGS fahren: dieselbe Form, andere Frage – hier
	# kommt der Block von vorn und nimmt einen mit.
	schiebeblock(88.0, -2.0, 0.0, Vector3(1.8, 1.3, 1.8), 4.0, false, 1.5, 0.9)
	schiebeblock(92.0, 2.0, 0.0, Vector3(1.8, 1.3, 1.8), 4.0, false, 1.5, 0.9,
			0.5)
	# Eine Auslöseplatte hält das Tor am Ende offen.
	var tor := schliesstuer(94.5, 0.0, 4.2, 3.0, 2.4, 1.8)
	ausloeseplatte(86.0, 0.0, Vector2(2.8, 2.8), 1.6, false, [tor])
	taktflaeche(79.0, -3.4, Vector2(2.8, 2.8), 0.4)
	taktflaeche(79.0, 3.4, Vector2(2.8, 2.8), 0.9)


## 104–146 · Fackelgang. Götzenköpfe speien Feuer, und zwar SCHWENKEND:
## Die Flamme steht nicht still, sondern streicht über den Gang.
##
## Damit ist die Frage eine andere als beim festen Feuerspeier. Dort
## heißt sie "wann", hier heißt sie "wohin" – man muss den Bogen der
## Flamme lesen, nicht ihren Takt.
func _fackelgang_bauen() -> void:
	feuerspeier(110.0, -4.2, 1.1, 0.0, 4.6, 0.0, true)
	feuerspeier(117.0, 4.2, 1.1, 180.0, 4.6, 0.4, true)
	feuerspeier(124.0, -4.2, 1.3, 0.0, 5.0, 0.2, true)
	feuerspeier(131.0, 4.2, 1.3, 180.0, 5.0, 0.7, true)
	# Eine feste Düse dazwischen: der Ruhepunkt, an dem man die
	# schwenkenden wieder lesen kann.
	feuerspeier(136.0, -4.0, 1.0, 0.0, 4.0, 0.0)
	# Der Gang selbst ist eng gestellt: Drehscheiben zwingen zum Warten.
	drehscheibe(114.0, 2.6, 0.2, 3.8, 28.0)
	drehscheibe(128.0, -2.6, 0.2, 3.8, 28.0, -1)
	deckungsfleck(120.0, 3.0)
	taktwelle(140.0, 145.0, 2, 0.0, Vector2(2.8, 2.8), 0.4)


## 146–204 · Ruinentreppe. Der Aufstieg vom Erd- ins Obergeschoss:
## achtzehn Höhenmeter auf sechzig Metern Weg.
##
## Der Weg selbst steigt hier mit etwa zwanzig Grad – begehbar, aber
## spürbar. Die beiden Lücken darin sind steiler als alle anderen des
## Levels, weil die Trittsteine auf Weghöhe liegen und damit von selbst
## eine Treppe bilden.
##
## Hier stehen zum ersten Mal Bruchplatten: Auf einer Treppe kostet eine
## Platte, die wegbricht, nicht nur den Schritt, sondern die Höhe.
func _treppe_bauen() -> void:
	bruchplatten_reihe(150.0, 156.0, 3, 0.0, -0.14, Vector2(2.6, 2.6))
	feuerspeier(160.0, -3.4, 1.0, 0.0, 3.8, 0.0)
	schiebeblock(164.0, 0.0, 0.0, Vector3(1.8, 1.3, 1.8), 3.6, true, 1.3, 0.8)
	bruchplatten_reihe(180.0, 186.0, 3, 0.0, -0.14, Vector2(2.4, 2.4))
	feuerspeier(190.0, 3.2, 1.0, 180.0, 3.6, 0.4, true)
	taktflaeche(194.0, 0.0, Vector2(3.0, 3.0), 0.3)
	# Ein Podest auf halber Treppe mit Aussicht zurück nach unten: die
	# einzige Stelle, an der das Level ausdrücklich zum Umschauen einlädt.
	plattform(172.0, -4.4, 0.9, Vector3(3.6, 0.7, 3.6), _ruinenstein())
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 172.0, -4.4, 1.8)


## 204–284 · Säulengalerie. Sie liegt senkrecht über dem Unterhof.
##
## Hier stehen zum ersten Mal zwei bewegte Dinge nebeneinander: Auf den
## Drehscheiben steht jeweils ein Gegner. Ein `Gegner` patrouilliert in
## Weltkoordinaten – ein aufgesetzter braucht deshalb `patrouille_weite`
## null, sonst liefe er von der Scheibe.
func _galerie_bauen() -> void:
	drehscheibe(210.0, -2.6, 0.2, 4.0, 30.0)
	_gegner_aufsetzen(drehscheibe(216.0, 2.6, 0.2, 4.0, 30.0, -1))

	laufband(222.0, 230.0, 0.0, 0.06, 3.8, 2.4, -1)
	feuerspeier(226.0, -4.0, 1.1, 0.0, 4.2, 0.0, true)

	bruchplatten_reihe(248.0, 256.0, 4, 0.0, -0.14, Vector2(2.5, 2.5))
	_gegner_aufsetzen(drehscheibe(262.0, 0.0, 0.2, 4.4, 26.0))
	schiebeblock(268.0, 0.0, 0.0, Vector3(2.0, 1.3, 2.0), 4.4, true, 1.4, 0.8)
	taktwelle(206.0, 214.0, 3, 3.6, Vector2(2.6, 2.6), 0.3)
	taktwelle(250.0, 258.0, 3, -3.6, Vector2(2.6, 2.6), 0.3)


## Ein Käfer, der auf einer Drehscheibe mitfährt.
##
## `Drehplattform.aufsetzen()` ist genau dafür da: Es stellt den Gegner
## erst auf das Deck und hängt ihn dann ein – andersherum merkte sich
## `Gegner._ready()` den Mittelpunkt der Scheibe als Startplatz. Die
## Patrouillenweite muss null sein, weil ein `Gegner` in WELTkoordinaten
## patrouilliert und auf einer drehenden Scheibe sonst über die Kante
## liefe.
##
## Ein Käfer und keine Kröte: Er will von oben getroffen werden, und
## "von oben" ist auf einer drehenden Scheibe schon Frage genug. Eine
## hüpfende Kröte hätte zwei Takte auf einmal eingebracht.
func _gegner_aufsetzen(scheibe: Drehplattform) -> Gegner:
	var g := PANZERKAEFER.instantiate() as Gegner
	g.patrouille_weite = 0.0
	scheibe.aufsetzen(g)
	return g


## 284–360 · Abendzinne. Das Finale: alles noch einmal, ohne Pause.
##
## Neu ist hier nichts – neu ist nur die Dichte. Wer bis hierher gekommen
## ist, kennt jedes einzelne Bauteil; die Frage ist, ob er sie auch dann
## noch auseinanderhält, wenn er schon acht Minuten unterwegs ist.
func _zinne_bauen() -> void:
	taktwelle(286.0, 298.0, 5, 0.0, Vector2(2.8, 2.8), 0.22)
	feuerspeier(290.0, -4.2, 1.1, 0.0, 4.6, 0.0, true)
	feuerspeier(296.0, 4.2, 1.1, 180.0, 4.6, 0.5)
	schiebeblock(302.0, 0.0, 0.0, Vector3(2.0, 1.3, 2.0), 4.6, true, 1.2, 0.7)
	drehscheibe(308.0, -2.8, 0.2, 3.8, 34.0)

	bruchplatten_reihe(314.0, 318.0, 3, 0.0, -0.14, Vector2(2.4, 2.4))

	taktwelle(324.0, 336.0, 5, 0.0, Vector2(2.8, 2.8), 0.28)
	feuerspeier(330.0, -4.4, 1.3, 0.0, 4.8, 0.15, true)
	schiebeblock(338.0, 0.0, 0.0, Vector3(2.2, 1.3, 2.2), 5.0, true, 1.1, 0.6)
	laserzaun(344.0, 6.0, true, 1.1)
	# Und dann ist Schluss: die letzten vierzehn Meter sind leer.


## Der Dachgang – die dritte Lage.
##
## Eine Kette von Absätzen ÜBER der Säulengalerie, gestaffelt von vier bis
## acht Metern Höhe. Hinauf geht es über die Sprungfeder bei 240 m; wer
## sie übersieht, verpasst neun Kisten und ein Extraleben, verliert aber
## nichts vom Weg – unter dem Dachgang liegt die Galerie, ein Fehltritt
## kostet also nur den Aufstieg.
##
## Sie liegt bewusst über dem OBERGESCHOSS und nicht über dem Erdgeschoss:
## Unten hätte sie in der Absturzzone der Galerie gehangen (siehe
## `ABSTURZ`), und ein Dachgang, der einen im Sprung tötet, ist keiner.
func _dachgang_bauen() -> void:
	var stein := _ruinenstein()
	var stellen := [246.0, 251.0, 256.0, 261.0, 266.0, 271.0, 278.0]
	for i in stellen.size():
		var seitlich: float = -3.4 if i % 2 == 0 else 3.4
		var hoch := 4.2 + float(i) * 0.55
		plattform(stellen[i], seitlich, hoch, Vector3(3.2, 0.6, 3.2), stein)
		frucht(stellen[i], seitlich, hoch + 1.3)
	# Der letzte Absatz ist breit – hier liegt die Belohnung.
	plattform(284.0, 0.0, 8.4, Vector3(7.0, 0.8, 6.0), stein)
	for i in 4:
		kiste(Kiste.Art.NORMAL, 282.0 + float(i) * 1.4, -1.8, 9.2)
		kiste(Kiste.Art.NORMAL, 282.0 + float(i) * 1.4, 1.8, 9.2)
	kiste(Kiste.Art.LEBEN, 286.5, 0.0, 9.2)
	fruechte_reihe(281.0, 287.0, 6, 0.0, 9.8)


## Fackeln entlang des ganzen Weges.
##
## Sie sind die einzige warme Farbe, die im Level wirklich LEUCHTET, und
## sie stehen bewusst nicht gleichmäßig: Wo eine Falle beginnt, steht
## eine; auf freier Strecke steht keine. Damit ist die Fackel eine
## Ankündigung, nicht Zierde.
func _fackeln_setzen() -> void:
	var stellen := [10.0, 24.0, 42.0, 68.0, 84.0, 108.0, 126.0, 148.0,
			172.0, 192.0, 208.0, 228.0, 250.0, 268.0, 288.0, 306.0,
			326.0, 348.0]
	for i in stellen.size():
		var s: float = stellen[i]
		var breite := breite_bei(s)
		if breite < 0.5:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * (breite * 0.5 - 0.6)
		var saeule := CylinderMesh.new()
		saeule.top_radius = 0.18
		saeule.bottom_radius = 0.24
		saeule.height = 1.8
		saeule.radial_segments = 7
		var mi := MeshInstance3D.new()
		mi.mesh = saeule
		mi.material_override = _ruinenstein()
		mi.position = LevelWerkzeuge.punkt(verlauf, s, quer, 0.9)
		deko.add_child(mi)

		var schale := SphereMesh.new()
		schale.radius = 0.3
		schale.height = 0.6
		var glut := MeshInstance3D.new()
		glut.mesh = schale
		glut.material_override = Materialbibliothek.leuchtend(FACKELLICHT, 2.6)
		glut.position = LevelWerkzeuge.punkt(verlauf, s, quer, 2.0)
		deko.add_child(glut)

		var licht := OmniLight3D.new()
		licht.light_color = FACKELLICHT
		licht.light_energy = 2.6
		licht.omni_range = 11.0
		licht.position = LevelWerkzeuge.punkt(verlauf, s, quer, 2.2)
		deko.add_child(licht)


## Abendlicht in drei Stufen.
##
## Unten im Hof steht der Dunst tief und kühl, auf der Treppe wird er
## wärmer, oben auf der Zinne steht die Figur im vollen Abendlicht. Das
## ist der Lohn für den Aufstieg, und er wird nicht erzählt, sondern
## beleuchtet.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 70.0, Color(0.34, 0.36, 0.32), 0.020, 0.85,
			Color(0.38, 0.44, 0.42), 54.0)
	stimmung(150.0, 200.0, Color(0.52, 0.40, 0.26), 0.014, 1.05,
			Color(0.58, 0.48, 0.34), 54.0)
	stimmung(286.0, M_ENDE, Color(0.72, 0.50, 0.26), 0.009, 1.3,
			Color(0.80, 0.58, 0.32), 58.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Unterhof ----------
	kiste(Kiste.Art.CHECKPOINT, 6.0, -3.0)
	kiste(Kiste.Art.NORMAL, 9.0, -2.4)
	kiste(Kiste.Art.NORMAL, 9.0, 0.0)
	kiste(Kiste.Art.NORMAL, 9.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 16.0, 2.6)
	kiste(Kiste.Art.EISEN, 22.0, -3.2)
	kiste(Kiste.Art.NORMAL, 22.0, -3.2, 1.6)
	kiste(Kiste.Art.SCHUTZ, 33.0, -3.4)
	kiste(Kiste.Art.NORMAL, 38.0, -3.4)
	kiste(Kiste.Art.TNT, 50.0, 0.0)
	kiste(Kiste.Art.NORMAL, 50.0, -2.4)
	kiste(Kiste.Art.NORMAL, 50.0, 2.4)
	kiste(Kiste.Art.NORMAL, 56.0, -2.0)

	# ---------- Schieberflur ----------
	kiste(Kiste.Art.CHECKPOINT, 70.0, 3.2)
	kiste(Kiste.Art.NORMAL, 73.0, -3.4)
	kiste(Kiste.Art.NORMAL, 79.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 85.0, 3.2)
	kiste(Kiste.Art.NORMAL, 90.0, -3.4)
	kiste(Kiste.Art.SCHUTZ, 91.5, 3.4)

	# ---------- Fackelgang ----------
	kiste(Kiste.Art.NORMAL, 107.0, 0.0)
	kiste(Kiste.Art.NORMAL, 112.0, -2.6)
	kiste(Kiste.Art.NORMAL, 119.0, 2.6)
	kiste(Kiste.Art.CHECKPOINT, 132.0, -2.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 134.0, 2.6)
	kiste(Kiste.Art.NORMAL, 137.0, 0.0)

	# ---------- Ruinentreppe ----------
	kiste(Kiste.Art.NORMAL, 148.0, -2.4)
	kiste(Kiste.Art.NORMAL, 158.0, 2.4)
	kiste(Kiste.Art.SCHUTZ, 166.0, -2.2)
	kiste(Kiste.Art.CHECKPOINT, 192.0, 2.4)
	kiste(Kiste.Art.NORMAL, 178.0, 2.2)
	kiste(Kiste.Art.NORMAL, 188.0, -2.2)
	kiste(Kiste.Art.NORMAL, 195.0, 0.0)

	# ---------- Säulengalerie ----------
	kiste(Kiste.Art.NORMAL, 206.0, -3.2)
	kiste(Kiste.Art.NORMAL, 213.0, 0.0)
	kiste(Kiste.Art.NITRO, 220.0, -3.2)
	kiste(Kiste.Art.NORMAL, 233.0, 2.8)
	# Aufgang zum Dachgang. Am Ende des ersten Galeriestücks: Wer sie
	# sieht, hat den Abschnitt schon gelaufen und weiß, was ihn oben
	# erwartet.
	kiste(Kiste.Art.SPRUNG, 234.0, -2.8)
	kiste(Kiste.Art.CHECKPOINT, 256.0, 3.2)
	kiste(Kiste.Art.NORMAL, 246.0, -3.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 260.0, -3.0)
	kiste(Kiste.Art.EISEN, 266.0, 3.0)
	kiste(Kiste.Art.NORMAL, 266.0, 3.0, 1.6)
	kiste(Kiste.Art.NORMAL, 271.0, 0.0)

	# ---------- Abendzinne ----------
	kiste(Kiste.Art.NORMAL, 282.0, -3.4)
	kiste(Kiste.Art.SCHUTZ, 292.0, 3.4)
	kiste(Kiste.Art.NORMAL, 300.0, -3.2)
	kiste(Kiste.Art.NORMAL, 305.0, 3.2)
	kiste(Kiste.Art.TNT, 310.0, 0.0)
	kiste(Kiste.Art.NORMAL, 310.0, -2.6)
	kiste(Kiste.Art.CHECKPOINT, 324.0, -3.6)
	kiste(Kiste.Art.NORMAL, 328.0, 3.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 334.0, -3.6)
	kiste(Kiste.Art.NORMAL, 340.0, 3.4)
	kiste(Kiste.Art.NORMAL, 348.0, -2.6)
	kiste(Kiste.Art.NORMAL, 348.0, 0.0)
	kiste(Kiste.Art.NORMAL, 348.0, 2.6)
	kiste(Kiste.Art.LEBEN, 354.0, 0.0)


# =========================================================== Gegner

## Drei Rollen, drei Antworten – und im Finale alle drei durcheinander.
##
## Die Stelzenspinne verlangt den Slide, die Kröte den Drehschlag, der
## Käfer den Sprung von oben. Der Werfer kommt dazu, wo der Weg schmal
## ist und Ausweichen nicht reicht. Auf den Drehscheiben sitzen zwei
## Kröten (siehe `_galerie_bauen`), damit dort zwei bewegte Dinge
## gleichzeitig zu lesen sind.
func _gegner_setzen() -> void:
	# ---------- Unterhof ----------
	gegner(PANZERKAEFER, 14.0, -2.6, 5.0, true)
	gegner(SUMPFKROETE, 21.0, 2.2, 4.0, true)
	gegner(STELZENSPINNE, 32.0, -2.2, 4.0, true)
	gegner(PANZERKAEFER, 46.0, 2.4, 4.5, true)

	# ---------- Schieberflur ----------
	gegner(STELZENSPINNE, 72.0, 2.2, 3.5, true)
	werfer(80.0, -4.0)

	# ---------- Fackelgang ----------
	gegner(SUMPFKROETE, 108.0, -2.0, 3.0, true)
	gegner(STELZENSPINNE, 122.0, 2.0, 3.0, true)
	schwarm(133.0, 0.0, 10.0)

	# ---------- Ruinentreppe ----------
	gegner(PANZERKAEFER, 152.0, -2.0, 3.0, true)
	gegner(SUMPFKROETE, 163.0, 2.0, 3.0, true)
	gegner(STELZENSPINNE, 184.0, -1.8, 2.8, true)

	# ---------- Säulengalerie ----------
	gegner(PANZERKAEFER, 208.0, 2.4, 3.5, true)
	werfer(224.0, -4.0)
	gegner(STELZENSPINNE, 232.0, 2.2, 3.2, true)
	schwarm(258.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 270.0, 2.4, 3.2, true)

	# ---------- Abendzinne: die dichteste Stelle ----------
	gegner(STELZENSPINNE, 284.0, -2.6, 3.5, true)
	gegner(SUMPFKROETE, 300.0, 2.4, 3.5, true)
	werfer(307.0, -4.2)
	gegner(PANZERKAEFER, 326.0, -2.6, 4.0, true)
	schwarm(333.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 341.0, 2.4, 3.5, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(6.0, 56.0, 16, 0.0)
	fruechte_bogen(58.0, 66.0, 5, 0.0, 2.4)
	fruechte_reihe(68.0, 94.0, 9, 0.0)
	fruechte_bogen(96.0, 104.0, 5, 0.0, 2.4)
	fruechte_reihe(106.0, 136.0, 10, 0.0)
	fruechte_bogen(138.0, 146.0, 5, 0.0, 2.6)
	fruechte_reihe(148.0, 166.0, 7, 0.0)
	fruechte_bogen(168.0, 176.0, 5, 0.0, 2.6)
	fruechte_reihe(178.0, 194.0, 7, 0.0)
	fruechte_bogen(196.0, 204.0, 5, 0.0, 2.6)
	fruechte_reihe(206.0, 234.0, 10, 0.0)
	fruechte_bogen(236.0, 244.0, 5, 0.0, 2.6)
	fruechte_reihe(246.0, 270.0, 9, 0.0)
	fruechte_bogen(272.0, 280.0, 5, 0.0, 2.6)
	fruechte_reihe(282.0, 310.0, 10, 0.0)
	fruechte_bogen(312.0, 320.0, 5, 0.0, 2.6)
	fruechte_reihe(322.0, 356.0, 12, 0.0)


# =========================================================== Kulisse

## Was aus den Fugen wächst.
##
## Dunkelgrüne Pflanzen zwischen den Steinen, dazu einzelne Bäume, die
## sich in der Ruine festgesetzt haben. Sie stehen ohne Kollision und weit
## genug vom Weg, denn eine Ruine, in der man alle drei Meter an einem
## Stamm hängen bleibt, ist ein Hindernisparcours, kein Ort.
func _bewuchs_bauen() -> void:
	var wuerfel := randi()
	seed(15002)
	for i in 64:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 4 == 0 else Baum.Art.LAUBBAUM
		baum.kronenform = Baum.Kronenform.HOCH
		baum.hoehe = randf_range(5.0, 11.0)
		baum.staerke = randf_range(0.6, 1.1)
		baum.saat = 15100 + i
		baum.laubfarbe = Color(0.149, 0.278, 0.106).lerp(
				Farben.LAUB_DUNKEL, randf())
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(9.0, 26.0), -randf_range(1.0, 7.0))
		deko.add_child(baum)

	for i in 42:
		var s := randf_range(0.0, M_ENDE)
		var rand := rand_bei(s, 1.4)
		if rand < 1.8:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate() as Stein
		stein.saat = 15300 + i
		stein.groesse = randf_range(0.4, 1.5)
		stein.flach = i % 3 == 0
		stein.bemoost = true
		stein.kollision = false
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)
	seed(wuerfel)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(15003)
	for i in 78:
		var s := randf_range(1.0, M_ENDE - 1.0)
		var rand := rand_bei(s, 1.1)
		if rand < 1.4:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(2.4, 2.4)
		horst.halm_hoehe = randf_range(0.3, 0.65)
		horst.farbe_unten = RUINENSTEIN_TIEF
		horst.farbe_oben = MOOSFUGE.lightened(0.2)
		horst.saat = 15500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.7, rand), 0.02)
		deko.add_child(horst)

	for i in 52:
		var s := randf_range(1.0, M_ENDE - 1.0)
		var rand := rand_bei(s, 1.2)
		if rand < 1.5:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.FARN if i % 3 == 0 \
				else (Kleinzeug.Art.BUSCH if i % 3 == 1 else Kleinzeug.Art.PILZ)
		kleinzeug.saat = 15700 + i
		kleinzeug.groesse = randf_range(0.4, 0.9)
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)
