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
# Gemessen: `#926630` (Messing) gegen `#4D5650` (Stahl), dazu die warmen
# Wandkacheln `#A19279`. Aufgehellt, weil `albedo_color` die Textur
# multipliziert – die gemessenen Werte ergäben einen dunklen Klumpen.
## Warme sandfarbene Wandkachel.
const SANDKACHEL := Color(0.94, 0.83, 0.62)
const SANDKACHEL_DUNKEL := Color(0.66, 0.56, 0.40)
## Messing für Rohre, Ziernähte und Kolbenmäntel.
const MESSING := Color(0.92, 0.66, 0.26)
## Graues Stationsmetall für Böden und Stempel.
const STAHL := Color(0.66, 0.72, 0.68)
const STAHL_DUNKEL := Color(0.40, 0.45, 0.43)
## Grün leuchtende Bildschirme – das kalte Gegenlicht zum warmen Messing.
const SCHIRM_GRUEN := Color(0.24, 1.0, 0.45)
## Ferner Stationsrumpf, wo der Gang sich öffnet.
const RUMPF_NAH := Color(0.20, 0.22, 0.24)
const RUMPF_FERN := Color(0.36, 0.38, 0.42)


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

## Die Gangwände. Sandfarbene Kacheln, Messingadern, Stahlkrone.
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
		{"text": "Kachelwände", "tun": _waende_bauen},
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
		{"text": "Messingrohre", "tun": _rohre_bauen},
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

## Der Boden ist geriffeltes Stationsblech, die Kante eine Messingnaht.
## Die Naht ist nicht Schmuck: Sie zeichnet die Kante des Ganges nach, und
## im Strahlengang ist genau das der Unterschied zwischen Steg und Schacht.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.metall(STAHL),
		"kante": Materialbibliothek.metall(MESSING),
		"klippe": Materialbibliothek.metall(STAHL_DUNKEL),
	}, {"tiefe": 6.0, "schritt": 1.0, "kante_hoehe": 0.22, "kante_breite": 0.6})
	luecken_markieren(MESSING)


func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			_kachelstoff(SANDKACHEL), {
		"schritt": 2.2, "lagen": 3, "block": 2.6,
		"sockel": 8.0, "saat": 2004,
		"adermaterial": Materialbibliothek.metall(MESSING),
		"deckmaterial": _kachelstoff(SANDKACHEL_DUNKEL),
		"aderdichte": 0.3,
	})
	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), w["abstand"] - 0.4, 8.0)


## Die Decke. Ohne sie ist eine Raumstation ein Graben unter freiem Himmel.
##
## Sie trägt Kollision – das ist in einem Innenraum richtig so und kostet
## nichts: Bei 6,2 m liegt sie weit über der Doppelsprunghöhe von rund
## 3,4 m. Über dem Schacht im Strahlengang bleibt sie weg, damit man dort
## nach oben sieht und die Kolben aus dem Dunkeln kommen.
## Wandkachel in einem der beiden Sandtöne. Eigene Kopie, weil die
## Bibliothek keinen sandfarbenen Stein kennt und ihre Materialien geteilt
## sind – ein Eingriff daran träfe jedes andere Level mit.
func _kachelstoff(farbe: Color) -> StandardMaterial3D:
	var m := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	m.roughness = 0.7
	return m


func _decke_bauen() -> void:
	var blech := Materialbibliothek.metall(STAHL_DUNKEL)
	for stueck in [{"von": 0.0, "bis": 196.0}, {"von": 212.0, "bis": 318.0}]:
		var s: float = stueck["von"]
		while s < stueck["bis"]:
			var laenge: float = minf(10.0, stueck["bis"] - s)
			var mitte := s + laenge * 0.5
			plattform(mitte, 0.0, DECKENHOEHE,
					Vector3(breite_bei(mitte) + 3.0, 0.5, laenge + 0.4), blech)
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

## Messingrohre entlang beider Wände. Reine Optik ohne Kollision – sie
## sollen die Länge des Ganges zeichnen, nicht den Fuß aufhalten.
func _rohre_bauen() -> void:
	var messing := Materialbibliothek.metall(MESSING)
	var stuecke := [
		{"von": 4.0, "bis": 100.0, "hoehe": 4.2},
		{"von": 106.0, "bis": 194.0, "hoehe": 4.6},
		{"von": 214.0, "bis": 264.0, "hoehe": 4.4},
		{"von": 270.0, "bis": 314.0, "hoehe": 4.8},
	]
	for stueck in stuecke:
		var s: float = stueck["von"]
		while s < stueck["bis"]:
			var laenge: float = minf(8.0, stueck["bis"] - s)
			var mitte := s + laenge * 0.5
			var rand := rand_bei(mitte, 0.2)
			if rand < 2.0:
				s += laenge
				continue
			for seite: float in [-1.0, 1.0]:
				var walze := CylinderMesh.new()
				walze.top_radius = 0.18
				walze.bottom_radius = 0.18
				walze.height = laenge + 0.3
				walze.radial_segments = 8
				var rohr := MeshInstance3D.new()
				rohr.mesh = walze
				rohr.material_override = messing
				rohr.position = LevelWerkzeuge.punkt(verlauf, mitte,
						seite * (rand + 0.5), float(stueck["hoehe"]))
				rohr.rotation = Vector3(PI * 0.5,
						LevelWerkzeuge.drehung(verlauf, mitte), 0.0)
				deko.add_child(rohr)
			s += laenge


## Grün leuchtende Bildschirme in den Wänden.
##
## Sie sind das kalte Gegenlicht zum warmen Messing – der Steckbrief nennt
## genau diesen Gegensatz als das, was das Vorbild trägt. Gebaut als
## `plattform()` mit `Materialbibliothek.leuchtend()`: eine flache Tafel,
## die selbst leuchtet.
func _bildschirme_setzen() -> void:
	var schirm := Materialbibliothek.leuchtend(SCHIRM_GRUEN, 1.5)
	var stellen := [8.0, 22.0, 34.0, 50.0, 64.0, 74.0, 96.0, 112.0, 128.0,
			142.0, 156.0, 168.0, 180.0, 216.0, 230.0, 248.0, 264.0, 276.0,
			290.0, 306.0]
	for i in stellen.size():
		var s: float = stellen[i]
		var rand := rand_bei(s, 0.2)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		plattform(s, seite * (rand + 0.35), 2.4, Vector3(0.16, 1.1, 1.8),
				schirm)
		# Ein Omni davor, sonst leuchtet die Tafel, ohne zu beleuchten.
		var licht := OmniLight3D.new()
		licht.light_color = SCHIRM_GRUEN
		licht.light_energy = 1.4
		licht.omni_range = 7.0
		licht.shadow_enabled = false
		licht.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand - 0.4), 2.4)
		deko.add_child(licht)


## Innenraumlicht. Der Schleusengang ist warm und gut ausgeleuchtet, der
## Strahlengang kalt und diesig, das Maschinenherz warm und dunstig – man
## soll an der Luft merken, in welchem Teil der Station man steht.
func _stimmungen_setzen() -> void:
	stimmung(M_KAMMER, M_STRAHLEN, Color(0.52, 0.48, 0.38), 0.020, 0.85,
			Color(0.56, 0.52, 0.42), 40.0)
	stimmung(M_STRAHLEN, M_FRACHT, Color(0.30, 0.40, 0.38), 0.030, 0.7,
			Color(0.34, 0.46, 0.44), 40.0)
	stimmung(M_HERZ, M_ENDE, Color(0.50, 0.42, 0.30), 0.026, 0.9,
			Color(0.58, 0.48, 0.34), 44.0)


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
