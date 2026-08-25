extends KorridorLevel
## Level 10 – "Schleusenwerk"
##
## Ein verfallenes Wasserwerk im Nebelmoor, und zugleich die Schaubühne
## für alles, was das Spiel kann. Jeder Abschnitt stellt EINE Frage und
## nimmt dafür die Bauteile, die sie stellen können; kein Abschnitt
## wiederholt die Frage des vorigen.
##
##     0 –  40  Vorplatz      WALD · weit und offen: laufen, springen, schlagen
##    40 –  78  Taktgang      WALD · Taktflächen, Feuerspeier, Krabbelbalken
##    78 – 116  Bruchstege    MOOR · wegbrechende Platten, SEITENANSICHT
##   116 – 158  Fahrrinne     MOOR · Treibfloß, hängende Minen, Krabbelbalken
##   158 – 204  Maschinenhalle MOOR · Bänder, Drehscheiben, Tor
##                             darüber eine ZWEITE EBENE zur BONUSRUNDE
##   204 – 244  Hangelgasse   MOOR · Gitter über dem Wasser, Schwarm, Deckung
##   244 – 274  Wehr          MOOR · tauchende Bohlen, Blitzzaun
##   274 – 312  Gabelung      EIS  · zwei Wege: unten glatt, oben schmal
##   312 – 344  Eisgrat       EIS  · schmaler Grat, SEITENANSICHT
##   344 – 400  Weites Moor   WALD · der zweite offene Bereich, dicht besetzt
##   400 – 430  Anhöhe        WALD · trockener Abschluss
##
## Drei Untergründe, drei Stimmungen: Waldboden am Anfang und Ende,
## Bohlen über dem Moor in der Mitte, Firn und blankes Eis im Gebirgsstück.
## Der Weg erzählt damit eine Reise, statt 430 m dieselbe Kachel zu zeigen.
##
## Warum ein Wasserwerk: Es rechtfertigt alles auf einmal. Wasser und
## Flöße, Wehre und Tore, Bänder und Drehscheiben, und die Blitzzäune sind
## das, was von der alten Elektrik übrig ist. Ohne diese Klammer wäre das
## Level eine Sammlung von Bauteilen statt ein Ort.
##
## Die beiden offenen Bereiche (Vorplatz und Weites Moor) sind Absicht:
## Zwischen den engen Takten braucht das Auge Platz, und erst im Weiten
## fällt auf, wie eng die Gänge waren.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const EISFLAECHE := preload("res://scenes/hazards/Eisflaeche.tscn")

# Strecken-Marken
const M_VORPLATZ := 0.0
const M_TAKTGANG := 40.0
const M_BRUCHSTEGE := 78.0
const M_FAHRRINNE := 116.0
const M_HALLE := 158.0
const M_HANGELGASSE := 204.0
const M_WEHR := 244.0
const M_GABELUNG := 274.0
const M_EISGRAT := 312.0
const M_MOOR := 344.0
const M_ANHOEHE := 400.0
const M_ENDE := 430.0

# Höhen
const WASSER_HOEHE := -0.55
const MOORGRUND := -2.8
const ABSTURZ := -3.6
const FLOSS_HOEHE := -0.42
const DECK := FLOSS_HOEHE + Wasserplattform.DECK_STAERKE * 0.5
const BOHLE_OBEN := -0.30
const BOHLE_UNTEN := -1.45

## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
## Aufrechte Kapsel 1,30 m, flache 0,76 m.
const KRIECHHOEHE := 0.95
## Lichte Höhe der Hangelgitter. Sohlen hängen dann auf 1,65 m.
const GITTERHOEHE := 3.2


const STRECKE := [
	# --- Vorplatz: der weite Auftakt ---
	{"von": 0.0, "bis": 40.0, "breite": 18.0, "breite_ende": 11.0},
	# --- Taktgang: eng, alles im Takt ---
	{"von": 40.0, "bis": 78.0, "breite": 8.0},
	# --- Bruchstege: kurze feste Stücke, dazwischen Bruchplatten ---
	{"von": 78.0, "bis": 84.0, "breite": 8.0},
	{"von": 96.0, "bis": 102.0, "breite": 8.0},
	{"von": 110.0, "bis": 118.0, "breite": 8.0},
	# --- Fahrrinne: 118 bis 154 offenes Wasser, nur das Floß ---
	{"von": 154.0, "bis": 204.0, "breite": 10.0},
	# --- Hangelgasse: schmaler Steg, das Gitter trägt die Lücken ---
	{"von": 204.0, "bis": 216.0, "breite": 7.0},
	{"von": 230.0, "bis": 246.0, "breite": 7.5},
	# --- Wehr: 246 bis 270 nur Bohlen ---
	{"von": 270.0, "bis": 312.0, "breite": 13.0},
	# --- Eisgrat: der schmalste Abschnitt des Levels ---
	{"von": 312.0, "bis": 344.0, "breite": 5.5},
	# --- Weites Moor und Anhöhe ---
	{"von": 344.0, "bis": 430.0, "breite": 20.0, "breite_ende": 12.0},
]

## Welcher Untergrund wo liegt. Drei getrennte Aufrufe von
## `LevelWerkzeuge.korridor()`, weil ein Aufruf nur EINEN Materialsatz
## kennt – die Abschnittslisten müssen sich dafür nicht überschneiden.
const BODEN_WALD := [
	{"von": 0.0, "bis": 40.0, "breite": 18.0, "breite_ende": 11.0},
	{"von": 40.0, "bis": 78.0, "breite": 8.0},
	{"von": 344.0, "bis": 430.0, "breite": 20.0, "breite_ende": 12.0},
]
const BODEN_MOOR := [
	{"von": 78.0, "bis": 84.0, "breite": 8.0},
	{"von": 96.0, "bis": 102.0, "breite": 8.0},
	{"von": 110.0, "bis": 118.0, "breite": 8.0},
	{"von": 154.0, "bis": 204.0, "breite": 10.0},
	{"von": 204.0, "bis": 216.0, "breite": 7.0},
	{"von": 230.0, "bis": 246.0, "breite": 7.5},
]
const BODEN_EIS := [
	{"von": 270.0, "bis": 312.0, "breite": 13.0},
	{"von": 312.0, "bis": 344.0, "breite": 5.5},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Schleusenwerk wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Moorgrund", "tun": _grund_bauen},
		{"text": "Stege und Plätze", "tun": _boden_bauen},
		{"text": "Wasser steigt", "tun": _wasser_fluten},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Taktgang", "tun": _taktgang_bauen},
		{"text": "Bruchstege", "tun": _bruchstege_bauen},
		{"text": "Fahrrinne", "tun": _fahrrinne_bauen},
		{"text": "Maschinenhalle", "tun": _halle_bauen},
		{"text": "Hangelgasse", "tun": _hangelgasse_bauen},
		{"text": "Wehr", "tun": _wehr_bauen},
		{"text": "Zweite Ebene", "tun": _obere_ebene_bauen},
		{"text": "Bonusinsel", "tun": _bonusinsel_bauen},
		{"text": "Gabelung im Eis", "tun": _gabelung_bauen},
		{"text": "Eisgrat", "tun": _eisgrat_bauen},
		{"text": "Seitenansichten", "tun": _kamerazonen_setzen},
		{"text": "Stimmungen", "tun": _stimmungen_setzen},
		{"text": "Sumpfwald", "tun": _wald_bauen},
		{"text": "Schilf und Kleinzeug", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Eine große, langsame Schleife. Die engen Abschnitte liegen in den
## Biegungen, die beiden offenen auf den Geraden – im Weiten will man
## sehen, wohin es geht, im Engen soll die Sicht kurz sein.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, 0, -22),
		Vector3(4, 0, -50),          # Vorplatz
		Vector3(18, 0, -74),         # Taktgang
		Vector3(40, 0, -90),
		Vector3(64, -0.2, -94),      # Bruchstege
		Vector3(88, -0.2, -88),
		Vector3(108, -0.2, -72),     # Fahrrinne
		Vector3(120, -0.2, -50),
		Vector3(124, 0.2, -26),      # Maschinenhalle
		Vector3(118, 0.4, -2),
		Vector3(104, 0.4, 18),       # Hangelgasse
		Vector3(84, 0.4, 32),
		Vector3(60, 0.6, 38),        # Wehr
		Vector3(34, 1.2, 40),        # Gabelung, es geht hinauf
		Vector3(8, 2.6, 38),
		Vector3(-16, 4.2, 30),       # Eisgrat, höchste Stelle
		Vector3(-36, 4.6, 16),
		Vector3(-50, 3.4, -4),       # zurück ins Moor
		Vector3(-56, 2.0, -28),
		Vector3(-52, 1.4, -52),      # Weites Moor
		Vector3(-40, 1.8, -74),
		Vector3(-22, 3.2, -90),      # Anhöhe
	])


# =========================================================== Grund

## Drei Untergründe in drei Aufrufen. `korridor()` kennt je Aufruf nur
## einen Materialsatz; drei disjunkte Abschnittslisten ergeben zusammen
## denselben Weg, aber mit wechselndem Belag.
func _boden_bauen() -> void:
	var form := {"tiefe": 2.8, "schritt": 1.0,
			"kante_hoehe": 0.24, "kante_breite": 0.7}
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_WALD, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.moos(),
		"klippe": Materialbibliothek.fels(),
	}, form)
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_MOOR, {
		"oben": Materialbibliothek.bohlen(),
		"kante": Materialbibliothek.algen(),
		"klippe": Materialbibliothek.moorboden(),
	}, form)
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_EIS, {
		"oben": Materialbibliothek.firn(),
		"kante": Materialbibliothek.eis(),
		"klippe": Materialbibliothek.eisfels(),
	}, form)
	luecken_markieren(Farben.BOHLE.darkened(0.3))


func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(400.0, 400.0)
	var mi := MeshInstance3D.new()
	mi.name = "Moorgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.moorboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, MOORGRUND)
	geometrie.add_child(mi)


func _wasser_fluten() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ANHOEHE - 8.0:
		var w := wasser(s + schritt * 0.5, Vector2(64.0, schritt + 2.0),
				WASSER_HOEHE)
		w.tiefe = 2.0
		w.toedlich = true
		w.wellen_hoehe = 0.08
		w.wellen_tempo = 0.6
		w.farbe_tief = Farben.TUEMPEL
		w.farbe_hell = Farben.TUEMPEL_HELL
		w.spiegelung = 0.18
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 80.0)


func _horizont_bauen() -> void:
	horizont(240.0, 34.0, Color(0.30, 0.34, 0.28), Color(0.52, 0.58, 0.53),
			false, MOORGRUND - 1.0)


# =========================================================== Abschnitte

## 40–78 · Taktgang. Alles hier hat einen Takt, und die drei Takte laufen
## gegeneinander: Wer nur auf einen achtet, wird vom nächsten erwischt.
func _taktgang_bauen() -> void:
	# Erst eine einzelne Fläche zum Kennenlernen, dann die Welle.
	taktflaeche(45.0, 0.0, Vector2(3.0, 3.0), 0.0)
	taktwelle(52.0, 66.0, 5, 0.0, Vector2(2.8, 2.8), 0.2)

	# Feuerspeier von beiden Seiten, versetzt – zwischen ihnen ist immer
	# genau ein Fenster offen.
	feuerspeier(56.0, -3.4, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(62.0, 3.4, 1.0, 180.0, 3.2, 0.5)
	feuerspeier(70.0, -3.4, 1.0, 0.0, 3.6, 0.25, true)

	# Und ein Balken, unter dem nur Krabbeln durchkommt.
	stachelbalken(74.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


## 78–118 · Bruchstege. Drei feste Inseln, dazwischen Platten, die nach
## kurzer Frist wegbrechen. Darunter Wasser, keine zweite Chance.
func _bruchstege_bauen() -> void:
	bruchplatten_reihe(86.0, 94.0, 4, 0.0, -0.1)
	bruchplatten_reihe(104.0, 108.0, 3, -1.4, -0.1)
	# Ein sicherer Umweg über Seerosen, dafür länger und enger.
	seerose(104.0, 3.2, FLOSS_HOEHE, 2.2)
	seerose(107.5, 3.6, FLOSS_HOEHE, 2.2)
	# Schwimmende Minen zwischen den Stegen – wer zu weit springt, trifft.
	treibmine(90.0, 3.4, WASSER_HOEHE + 0.3, 1.6, 4.0, 0.0)
	treibmine(100.0, -3.6, WASSER_HOEHE + 0.3, 1.4, 3.4, 0.4)


## 118–154 · Fahrrinne. Das Floß trägt, der Rest kommt entgegen.
func _fahrrinne_bauen() -> void:
	floss(120.0, 152.0, 0.0, FLOSS_HOEHE, Vector2(4.6, 3.4), 13.0, 3.0, 3.0)
	# Ein zweites, kleineres Floß versetzt daneben: Wer will, wechselt
	# unterwegs und kommt an die Kisten am Rand.
	var neben := floss(126.0, 146.0, 3.6, FLOSS_HOEHE, Vector2(2.6, 2.4),
			8.0, 1.4, 1.4)
	neben.phase = 0.5

	stachelbalken(128.0, 0.0, DECK + KRIECHHOEHE, Vector2(6.0, 1.1))
	stachelbalken(142.0, 0.0, DECK + KRIECHHOEHE, Vector2(6.0, 1.1))
	treibmine(124.0, 1.6, DECK + 0.75, 1.8, 3.4, 0.0, 3.2)
	treibmine(134.0, -1.6, DECK + 0.75, 1.8, 3.0, 0.35, 3.2)
	treibmine(138.0, 1.4, DECK + 0.75, 1.6, 2.6, 0.6, 3.2)
	treibmine(148.0, 0.0, DECK + 0.75, 2.2, 3.8, 0.15, 3.2)


## 158–200 · Maschinenhalle. Der Boden ist hier kein Verlass: Er fährt,
## dreht sich oder schiebt. Alles auf festem Grund, damit die Bauteile
## selbst die Schwierigkeit sind und nicht der Abgrund darunter.
func _halle_bauen() -> void:
	laufband(160.0, 170.0, 0.0, 0.06, 3.6, 2.6, 1)
	# Ein Band gegen die Laufrichtung: die einzige Stelle, an der man
	# schneller sein muss als der Boden.
	laufband(174.0, 182.0, 0.0, 0.06, 3.6, 2.2, -1)

	drehscheibe(186.0, -2.4, 0.15, 4.0, 32.0)
	drehscheibe(192.0, 2.4, 0.15, 4.0, 32.0, -1)

	schiebeblock(176.0, -3.0, 0.0, Vector3(1.8, 1.2, 1.8), 3.6, true, 1.4, 1.0)
	schiebeblock(180.0, 3.0, 0.0, Vector3(1.8, 1.2, 1.8), 3.6, true, 1.4, 1.0,
			0.5)

	# Platte und Tor: ein Hindernis, zwei Rollen. Die Platte hält das Tor
	# offen; wer sie verpasst, wartet auf den Takt.
	var tor := schliesstuer(197.0, 0.0, 3.6, 2.8, 2.0, 1.8)
	ausloeseplatte(193.0, 0.0, Vector2(2.6, 2.6), 1.4, false, [tor])


## 200–242 · Hangelgasse. Zwei Lücken, die nur über Kopf zu nehmen sind.
## Hier zeigt sich, wozu Beine anziehen und Drehschlag im Hängen gut sind:
## Unter dem ersten Gitter hängt ein Balken, über dem zweiten schwirrt ein
## Schwarm.
func _hangelgasse_bauen() -> void:
	hangelgitter(223.0, 0.0, GITTERHOEHE, 15.0, 2.2)
	# Der Balken zwingt zum Anziehen der Beine, während man hangelt – und
	# das geht nur, wenn er genau in das Band zwischen baumelnden und
	# angezogenen Beinen passt. Gerechnet:
	#   Sohlen im Hang        3,20 − 1,55 = 1,65 m
	#   Kapsel baumelnd       1,65 … 2,95 m
	#   Kapsel angezogen      2,19 … 2,95 m   (untere 0,54 m fallen weg)
	# Die Zone muss also innerhalb 1,65 … 2,19 liegen. Mit Unterkante 1,70
	# und Dicke 0,23 reicht sie bis 2,05 – 14 cm Luft zur angezogenen
	# Kapsel. Ein Balken der üblichen Dicke 0,55 träfe beide.
	stachelbalken(223.0, 0.0, 1.70, Vector2(5.0, 0.9), 0.23)

	hangelgitter(238.0, 0.0, GITTERHOEHE, 9.0, 2.2)

	# Deckungsflecken auf den festen Stücken davor und danach.
	deckungsfleck(210.0, 1.6)
	deckungsfleck(242.0, -1.6)


## 242–268 · Wehr. Bohlen, die versetzt untertauchen, ein Brocken, der die
## Rinne entlangrollt, und der letzte Rest der alten Elektrik.
func _wehr_bauen() -> void:
	var stellen := [248.0, 252.0, 256.0, 260.0, 263.0, 266.0, 269.0]
	var seiten := [0.0, -1.4, 1.2, -1.0, 1.4, -0.8, 0.0]
	for i in stellen.size():
		wehrbohle(stellen[i], seiten[i], BOHLE_OBEN, BOHLE_UNTEN,
				float(i) * 0.15)
	treibmine(254.0, 2.6, WASSER_HOEHE + 0.3, 1.4, 4.4, 0.25)
	treibmine(265.0, -2.4, WASSER_HOEHE + 0.3, 1.2, 3.6, 0.5)

	# Blitzzaun auf dem festen Stück dahinter: die Lücke wandert, mal muss
	# man krabbeln, mal springen.
	laserzaun(273.0, 6.0, true, 1.2)

	# Und ein Brocken, der das weite Moor hinunterrollt.
	rollbrocken(350.0, 386.0, 0.0, 0.0, 1.2, 8.0, 3.0, 0.0)
	rollbrocken(356.0, 386.0, 5.0, 0.0, 0.9, 6.5, 3.5, 0.45,
			Rollhindernis.Art.FASS)


## 158–204 · Zweite Ebene über der Maschinenhalle.
##
## Ein Steg, der über dem Hallenboden zurückläuft. Wer ihn nimmt, sieht
## den Abschnitt, den er gerade gelaufen ist, von oben – das ist der
## eigentliche Gewinn einer zweiten Ebene und der Grund, warum sie über
## einem BEKANNTEN Stück liegt und nicht über neuem.
##
## Hinauf geht es über die Sprungfeder am Ende der Halle. Herunter kommt
## man überall: Unter dem Steg liegt fester Hallenboden, ein Fehltritt
## kostet also nur den Weg, nicht das Leben.
func _obere_ebene_bauen() -> void:
	var stein := Materialbibliothek.fels()
	# Sprungfeder als Aufgang – sie steht schon in _kisten_setzen bei 202.
	var hoehe := 6.4
	var stellen := [198.0, 192.0, 186.0, 180.0, 174.0, 168.0]
	for i in stellen.size():
		var seitlich: float = -3.0 if i % 2 == 0 else 3.0
		plattform(stellen[i], seitlich, hoehe + float(i) * 0.15,
				Vector3(3.4, 0.5, 3.4), stein)
		frucht(stellen[i], seitlich, hoehe + float(i) * 0.15 + 1.2)
	# Der letzte Absatz ist breiter: von hier führt der Weg zur Bonusinsel.
	plattform(163.0, 0.0, hoehe + 0.9, Vector3(6.0, 0.6, 5.0), stein)
	kiste(Kiste.Art.NORMAL, 168.0, 3.0, hoehe + 1.3)
	kiste(Kiste.Art.NORMAL, 174.0, -3.0, hoehe + 1.2)


## Bonusrunde: eine Insel abseits, nur mit Kisten und ohne einen einzigen
## Gegner.
##
## Sie hängt an der zweiten Ebene und ist damit doppelt versteckt – wer die
## Sprungfeder übersieht, findet sie nie. Das ist der Sinn: Eine Bonusrunde
## ist eine Belohnung fürs Hinsehen, keine Station auf dem Weg.
##
## Kein Abgrund darunter, keine Gefahr darauf. Wer herunterfällt, landet
## auf dem Hallenboden und kann es noch einmal versuchen.
func _bonusinsel_bauen() -> void:
	var stein := Materialbibliothek.fels()
	var hoehe := 7.3
	var seitlich := -11.0
	# Zwei Trittsteine als Brücke von der zweiten Ebene herüber.
	plattform(160.0, -5.0, hoehe - 0.3, Vector3(2.6, 0.5, 2.6), stein)
	plattform(159.0, -8.2, hoehe - 0.1, Vector3(2.6, 0.5, 2.6), stein)
	# Die Insel selbst.
	plattform(158.0, seitlich, hoehe, Vector3(9.0, 0.8, 9.0), stein)
	var schild := Label3D.new()
	schild.text = "Bonusrunde"
	schild.font_size = 84
	schild.pixel_size = 0.011
	schild.modulate = Farben.KISTE_FRAGE
	schild.outline_size = 22
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.position = LevelWerkzeuge.punkt(verlauf, 158.0, seitlich, hoehe + 3.4)
	deko.add_child(schild)

	# Acht Kisten in zwei Reihen, dazu eine Extraleben-Kiste in der Mitte.
	for i in 4:
		kiste(Kiste.Art.NORMAL, 155.0 + float(i) * 2.0, seitlich - 2.0,
				hoehe + 0.9)
		kiste(Kiste.Art.NORMAL, 155.0 + float(i) * 2.0, seitlich + 2.0,
				hoehe + 0.9)
	kiste(Kiste.Art.LEBEN, 158.0, seitlich, hoehe + 0.9)
	fruechte_reihe(154.0, 162.0, 6, seitlich, hoehe + 1.6)


## 274–312 · Gabelung im Eis. Zwei Wege, die wieder zusammenlaufen.
##
## Unten: der breite Firnweg – bequem, aber mit blankem Eis darauf, auf dem
## nichts greift. Oben: eine Reihe schmaler Stege, auf denen der Griff
## stimmt, dafür jeder Sprung sitzen muss.
##
## Beide sind gleich lang. Es geht nicht darum, welcher schneller ist,
## sondern darum, welche Art von Schwierigkeit man lieber hat – erst das
## macht eine Gabelung zu einer Entscheidung statt zu einer Abkürzung.
func _gabelung_bauen() -> void:
	var eisstoff := Materialbibliothek.eis()

	# --- Unterer Weg: blankes Eis auf dem breiten Firn ---
	for stelle in [280.0, 290.0, 300.0]:
		var flaeche := EISFLAECHE.instantiate() as Eisflaeche
		flaeche.flaeche = Vector2(9.0, 8.0)
		flaeche.glaette = 0.9
		flaeche.position = LevelWerkzeuge.punkt(verlauf, stelle, -2.5, 0.02)
		flaeche.rotation.y = LevelWerkzeuge.drehung(verlauf, stelle)
		objekte.add_child(flaeche)
	# Auf dem Eis stehen Schiebeblöcke: Wer keinen Griff hat, wird
	# geschoben – das ist die Pointe des unteren Weges.
	schiebeblock(286.0, -2.5, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.6, 0.8)
	schiebeblock(296.0, -2.5, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.6, 0.8,
			0.5)

	# --- Oberer Weg: schmale Stege am Rand ---
	var stein := Materialbibliothek.frostgestein()
	var stellen := [276.0, 281.0, 286.0, 291.0, 296.0, 301.0, 306.0]
	for i in stellen.size():
		plattform(stellen[i], 5.2, 1.6 + float(i) * 0.12,
				Vector3(2.8, 0.5, 3.0), stein)
	# Der Aufgang: eine Sprungfeder am Anfang der Gabelung.
	kiste(Kiste.Art.SPRUNG, 274.0, 5.2)
	# Belohnung für den oberen Weg – er ist der schwerere.
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 291.0, 5.2, 2.3)
	kiste(Kiste.Art.SCHUTZ, 301.0, 5.2, 2.4)
	fruechte_reihe(278.0, 306.0, 8, 5.2, 2.6)
	fruechte_reihe(278.0, 306.0, 8, -2.5, 0.9)

	# Beide Wege enden am selben Absatz.
	plattform(310.0, 1.4, 0.6, Vector3(7.0, 0.6, 3.0), stein)


## 312–344 · Eisgrat. Der schmalste Abschnitt, dafür ohne Abgrund
## daneben – hier soll die Kamera die Schwierigkeit machen, nicht der Tod.
func _eisgrat_bauen() -> void:
	var eisstoff := Materialbibliothek.eis()
	for stelle in [318.0, 330.0, 340.0]:
		var flaeche := EISFLAECHE.instantiate() as Eisflaeche
		flaeche.flaeche = Vector2(4.4, 7.0)
		flaeche.glaette = 0.85
		flaeche.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, 0.02)
		flaeche.rotation.y = LevelWerkzeuge.drehung(verlauf, stelle)
		objekte.add_child(flaeche)
	# Taktflächen auf dem Eis: rutschen und warten zugleich.
	taktwelle(320.0, 334.0, 4, 0.0, Vector2(2.4, 2.4), 0.25)
	feuerspeier(326.0, -2.6, 1.0, 0.0, 2.8, 0.0)
	stachelbalken(338.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.0))
	kiste(Kiste.Art.CHECKPOINT, 314.0, -1.6)
	kiste(Kiste.Art.NORMAL, 324.0, 1.4)
	kiste(Kiste.Art.NORMAL, 336.0, -1.4)
	fruechte_reihe(314.0, 342.0, 10, 0.0)


## Zwei Abschnitte laufen als Seitenansicht.
##
## Die Kamera schwenkt dafür weich hinüber (`seitenblick_folge` in
## `corridor_camera.gd`) – vorher kippte sie in einem einzigen Bild und
## das mitten im Sprung. Gewählt sind die beiden Abschnitte, in denen es
## nur um Sprungweiten geht: Von der Seite ist eine Lücke abzuschätzen,
## von hinten nicht.
func _kamerazonen_setzen() -> void:
	kamerazone(84.0, 116.0, -15.0, 3.2)
	kamerazone(314.0, 342.0, 14.0, 3.0)


## Licht und Nebel je Landschaft.
##
## Erst damit wird aus drei Bodenbelägen wirklich Wald, Moor und Gebirge.
## Die Grundstimmung der Szene ist das Moor; Wald und Eis weichen davon ab
## und blenden an ihren Rändern weich hinüber.
func _stimmungen_setzen() -> void:
	# Wald: wärmer, klarer, weniger Dunst als im Moor.
	stimmung(0.0, 78.0, Color(0.62, 0.66, 0.48), 0.008, 1.0,
			Color(0.62, 0.66, 0.52), 46.0)
	# Eis: kalt, hell und diesig – im Gebirge steht der Dunst höher.
	stimmung(270.0, 344.0, Color(0.80, 0.87, 0.94), 0.020, 1.25,
			Color(0.72, 0.82, 0.92), 46.0)
	# Rückkehr in den Wald für den Schlussteil.
	stimmung(348.0, M_ENDE, Color(0.60, 0.65, 0.48), 0.009, 1.0,
			Color(0.60, 0.65, 0.50), 52.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

## Eine Kiste auf einem Seerosenblatt.
func kiste_auf_wasser(art: Kiste.Art, strecke: float,
		seitlich: float) -> Kiste:
	seerose(strecke, seitlich, FLOSS_HOEHE, 2.2)
	return kiste(art, strecke, seitlich, DECK + 0.5)


func _kisten_setzen() -> void:
	# ---------- Vorplatz: jedes Werkzeug einmal ----------
	kiste(Kiste.Art.NORMAL, 7.0, -2.2)
	kiste(Kiste.Art.NORMAL, 7.0, 0.0)
	kiste(Kiste.Art.NORMAL, 7.0, 2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 12.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 17.0, -3.0)
	kiste(Kiste.Art.EISEN, 21.0, 2.4)
	kiste(Kiste.Art.NORMAL, 21.0, 2.4, 1.6)
	kiste(Kiste.Art.SCHUTZ, 26.0, -2.0)
	kiste(Kiste.Art.FEDER, 32.0, 0.0)
	kiste(Kiste.Art.NORMAL, 36.0, 3.2)

	# ---------- Taktgang ----------
	kiste(Kiste.Art.CHECKPOINT, 42.0, -2.4)
	kiste(Kiste.Art.NORMAL, 48.0, 2.0)
	kiste(Kiste.Art.TNT, 59.0, -2.0)
	kiste(Kiste.Art.NORMAL, 59.0, 2.0)
	kiste(Kiste.Art.NORMAL, 68.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 76.0, 2.2)

	# ---------- Bruchstege ----------
	kiste(Kiste.Art.CHECKPOINT, 80.0, -2.2)
	kiste(Kiste.Art.NORMAL, 82.0, 1.8)
	kiste_auf_wasser(Kiste.Art.FRUCHT_MEHRFACH, 90.0, -4.4)
	kiste(Kiste.Art.NORMAL, 99.0, 0.0)
	kiste(Kiste.Art.SPRUNG, 113.0, 0.0)
	kiste(Kiste.Art.NORMAL, 116.0, -1.8)

	# ---------- Fahrrinne: alles seitlich der Rinne ----------
	kiste_auf_wasser(Kiste.Art.NORMAL, 127.0, -4.4)
	kiste_auf_wasser(Kiste.Art.NORMAL, 133.0, 4.6)
	kiste_auf_wasser(Kiste.Art.SCHUTZ, 141.0, -4.6)
	kiste_auf_wasser(Kiste.Art.NORMAL, 147.0, 4.4)

	# ---------- Maschinenhalle ----------
	kiste(Kiste.Art.CHECKPOINT, 156.0, -3.0)
	kiste(Kiste.Art.NORMAL, 165.0, 2.6)
	kiste(Kiste.Art.NORMAL, 172.0, -2.6)
	kiste(Kiste.Art.NITRO, 179.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 189.0, 0.0)
	kiste(Kiste.Art.NORMAL, 200.0, -2.8)
	# Aufgang zur zweiten Ebene. Bewusst am ENDE der Halle: Wer sie sieht,
	# hat den Abschnitt schon gelaufen und weiß, was er von oben wiedersieht.
	kiste(Kiste.Art.SPRUNG, 202.0, 0.0)

	# ---------- Hangelgasse ----------
	kiste(Kiste.Art.CHECKPOINT, 207.0, -2.0)
	kiste(Kiste.Art.NORMAL, 213.0, 1.8)
	kiste_auf_wasser(Kiste.Art.NORMAL, 223.0, 4.6)
	kiste(Kiste.Art.NORMAL, 233.0, -1.8)
	kiste(Kiste.Art.SCHUTZ, 244.0, 2.0)

	# ---------- Wehr ----------
	kiste(Kiste.Art.NORMAL, 272.0, -2.4)
	kiste(Kiste.Art.NORMAL, 275.0, 2.4)

	# ---------- Weites Moor: hier ist Platz für Stapel ----------
	kiste(Kiste.Art.CHECKPOINT, 347.0, -3.2)
	kiste(Kiste.Art.EISEN, 354.0, -4.0)
	kiste(Kiste.Art.NORMAL, 354.0, -4.0, 1.6)
	kiste(Kiste.Art.NORMAL, 354.0, -4.0, 2.6)
	kiste(Kiste.Art.NORMAL, 362.0, 4.5)
	kiste(Kiste.Art.NORMAL, 362.0, 6.0)
	kiste(Kiste.Art.TNT, 370.0, 0.0)
	kiste(Kiste.Art.NORMAL, 370.0, -2.0)
	kiste(Kiste.Art.NORMAL, 370.0, 2.0)
	kiste(Kiste.Art.FEDER, 378.0, -5.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 386.0, 3.0)

	# ---------- Anhöhe ----------
	kiste(Kiste.Art.NORMAL, 404.0, -2.4)
	kiste(Kiste.Art.NORMAL, 404.0, 0.0)
	kiste(Kiste.Art.NORMAL, 404.0, 2.4)
	kiste(Kiste.Art.LEBEN, 412.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 420.0, -2.0)
	kiste(Kiste.Art.NORMAL, 425.0, 2.0)


# =========================================================== Gegner

## Gegner stehen nur auf festem Boden.
##
## Auf den Fahrten und über dem Wehr wäre ein patrouillierender Gegner
## unfair: Er stünde still im Raum, während der Boden unter dem Spieler
## wegfährt. Dort übernehmen Minen, Balken und der Takt.
func _gegner_setzen() -> void:
	# ---------- Vorplatz: viel Platz, alle Antworten üben ----------
	gegner(PANZERKAEFER, 11.0, -2.0, 4.0, true)     # draufspringen
	gegner(SUMPFKROETE, 19.0, 1.5, 3.0, true)       # Drehschlag
	gegner(PANZERKAEFER, 29.0, 3.0, 4.5, true)
	werfer(24.0, -5.0)                              # wirft aus der Ferne
	gegner(STELZENSPINNE, 35.0, -2.0, 3.5, true)

	# ---------- Taktgang: eng, deshalb wenige ----------
	gegner(SUMPFKROETE, 50.0, 0.0, 2.0, true)
	gegner(STELZENSPINNE, 64.0, 0.0, 2.5, true)

	# ---------- Bruchstege ----------
	gegner(PANZERKAEFER, 81.0, 0.0, 2.0, true)
	gegner(SUMPFKROETE, 99.0, 0.0, 2.0, true)

	# ---------- Maschinenhalle ----------
	gegner(PANZERKAEFER, 163.0, -2.0, 2.5, true)
	gegner(STELZENSPINNE, 184.0, 2.5, 3.0, true)
	werfer(190.0, -4.0)

	# ---------- Hangelgasse: der Schwarm gehört ans Gitter ----------
	gegner(SUMPFKROETE, 209.0, -1.5, 2.0, true)
	schwarm(236.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 243.0, 1.6, 2.5, true)

	# ---------- Weites Moor: die dichteste Stelle des Levels ----------
	gegner(PANZERKAEFER, 350.0, -3.0, 5.0, true)
	gegner(SUMPFKROETE, 358.0, 2.5, 4.0, true)
	werfer(365.0, 6.5)
	schwarm(372.0, -3.0, 10.0)
	gegner(STELZENSPINNE, 376.0, 3.0, 4.5, true)
	gegner(PANZERKAEFER, 383.0, -4.0, 5.0, true)
	gegner(SUMPFKROETE, 389.0, 0.0, 3.5, true)

	# ---------- Anhöhe ----------
	gegner(STELZENSPINNE, 404.0, 2.5, 3.5, true)
	gegner(PANZERKAEFER, 415.0, -2.5, 3.5, true)


# =========================================================== Früchte

## Früchte führen den Blick. Auf der Fahrrinne liegen sie tiefer, weil der
## Spieler dort auf dem Floßdeck steht; unter den Gittern liegen sie auf
## Hangelhöhe, damit man sieht, wo entlang gehangelt wird.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 24.0, 9, 0.0)
	fruechte_bogen(28.0, 34.0, 5, 0.0, 2.4)
	fruechte_reihe(42.0, 76.0, 12, 0.0)
	fruechte_bogen(84.0, 96.0, 7, 0.0, 2.6)
	fruechte_bogen(102.0, 110.0, 5, -1.4, 2.2)
	fruechte_reihe(120.0, 150.0, 11, 0.0, DECK + 0.9)
	fruechte_reihe(126.0, 146.0, 5, 3.6, DECK + 0.9)
	fruechte_reihe(156.0, 202.0, 14, 0.0)
	# Unter den Gittern: die Spur zeigt den Weg über Kopf an.
	fruechte_reihe(217.0, 230.0, 6, 0.0, 1.9)
	fruechte_reihe(234.0, 242.0, 4, 0.0, 1.9)
	fruechte_bogen(246.0, 270.0, 10, 0.0, 1.8)
	fruechte_reihe(346.0, 392.0, 16, 0.0)
	fruechte_reihe(358.0, 380.0, 7, 5.0)
	fruechte_reihe(396.0, 426.0, 11, 0.0)


# =========================================================== Kulisse

## Sumpfwald. Am Vorplatz und im weiten Moor stehen die Bäume dichter und
## näher am Weg – dort sollen sie den Raum fassen. An den Fahrten stehen
## sie weit draußen, damit die Sicht nach vorn frei bleibt.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(31001)
	for i in 118:
		var s := randf_range(-8.0, M_ENDE + 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var offen := _offener_bereich(s)
		var frei := _fahrt_hier(s)
		var nah: float = 7.0 if offen else (10.0 if frei else 8.0)
		var quer := seite * randf_range(nah, nah + 22.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 3 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(5.0, 13.0)
		baum.staerke = randf_range(0.6, 1.2)
		baum.saat = 7100 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.ALGE, randf())
		baum.kollision = false
		var fuss := WASSER_HOEHE - 0.4 if s < M_ANHOEHE else -0.2
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, fuss)
		deko.add_child(baum)

	# Felsbrocken auf den offenen Flächen – sie geben dem Weiten Maß.
	for i in 26:
		var s: float = randf_range(2.0, 38.0) if i % 2 == 0 \
				else randf_range(M_MOOR, M_ENDE - 6.0)
		var rand := rand_bei(s, 1.6)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate()
		if "saat" in stein:
			stein.set("saat", 7300 + i)
		if "hoehe" in stein:
			stein.set("hoehe", randf_range(0.7, 2.2))
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.5, rand), 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)
	seed(wuerfel)


## Liegt die Stelle in einem der beiden weiten Bereiche?
func _offener_bereich(strecke: float) -> bool:
	return strecke < M_TAKTGANG or strecke > M_MOOR


## Liegt die Stelle auf der Fahrrinne oder über dem Wehr?
func _fahrt_hier(strecke: float) -> bool:
	return (strecke > M_FAHRRINNE and strecke < M_HALLE) \
			or (strecke > M_WEHR and strecke < M_MOOR)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(31002)

	for i in 74:
		var s := randf_range(2.0, M_ANHOEHE)
		var rand := rand_bei(s, 0.4)
		var frei := _fahrt_hier(s)
		var abstand := rand + randf_range(0.6, 3.4) if rand >= 1.0 \
				else randf_range(5.0, 9.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s, seite * abstand,
				WASSER_HOEHE + 0.1)
		horst.flaeche = Vector2(2.4, 2.4) if frei else Vector2(3.0, 3.0)
		horst.halm_hoehe = randf_range(0.5, 0.85) if frei \
				else randf_range(0.7, 1.3)
		horst.farbe_unten = Farben.ALGE.darkened(0.35)
		horst.farbe_oben = Farben.SCHILF
		horst.saat = 7500 + i
		deko.add_child(horst)

	# Farne, Pilze und Blumen auf festem Grund – auf den offenen Flächen
	# dichter, weil dort der Blick Zeit hat.
	for i in 46:
		var s: float = randf_range(2.0, 36.0) if i % 3 == 0 \
				else (randf_range(M_MOOR, M_ENDE - 5.0) if i % 3 == 1
						else randf_range(M_HALLE, M_HANGELGASSE))
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.FARN
		kleinzeug.saat = 7700 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	for i in 30:
		var s := randf_range(M_BRUCHSTEGE, M_WEHR)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate()
		if "saat" in w:
			w.set("saat", 7900 + i)
		w.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(5.0, 15.0), WASSER_HOEHE - 0.2)
		w.rotation.y = randf() * TAU
		deko.add_child(w)
	seed(wuerfel)
