extends KorridorLevel
## Level 16 – "Kanalgrund"
##
## Die Kanalisation unter der Stadt. Das Besondere ist nicht ein neues
## Hindernis, sondern eine neue Haltung: **Der Boden selbst ist zeitweise
## tödlich.** In den Rinnen takten Stromstöße, und wer läuft, stirbt. Das
## Level bestraft damit genau das Tempo, das alle anderen Level belohnen –
## man wartet, statt zu rennen, und der Rhythmus der Taktflächen gibt das
## Tempo vor, nicht der Spieler.
##
##     0 –  48  Einlaufbecken  weit und trocken: hier wird das Warten gelehrt
##    48 – 108  Stromrinne     zwei Taktwellen, dazwischen eine sichere Insel
##   108 – 162  Fassgang       rollende Giftfässer im engsten Stück
##   162 – 214  Rotorhalle     Rotorblätter als drehender Boden
##   214 – 272  Gabelung       die Sackgasse, die keine ist
##   272 – 340  Klärbecken     offenes Becken, Wände weg, Himmel zu sehen
##
## Die Regel, die dieses Level einmal bricht: Der Seitenweg bei 232 m sieht
## aus wie eine Sackgasse voller Nitro und endet für das Auge an einer
## Wand. Dahinter läuft er weiter. Genau einmal im Level, nie zweimal –
## sonst wäre es keine Ausnahme mehr, sondern eine zweite Regel.
##
## Farbe ist hier Lesbarkeit. Alles ist olivbraun, tealgrün und schwarz;
## der einzige warme Ton sind die rostorangen Kisten. Was warm leuchtet,
## ist gut. Was giftgrün leuchtet, bringt um. Zwei Farben, zwei Aussagen –
## man muss die Form nicht erkennen, um zu wissen, woran man ist.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")


# ------------------------------------------------------------- Palette
#
# Gemessen am Vorbild (doku/level-vorbilder.md, 4-1):
#   #0D1711 #573015 #624E29 #1F4C3F #93481B #BA9455
# Tragend ist #1F4C3F (Kanalgrün) gegen #93481B (Rost). In `Farben` gibt
# es für einen Kanal nichts Passendes – Moorgrün ist zu erdig, Rost zu
# hell –, deshalb stehen die Töne hier als lokale Konstanten.

const KANAL_SCHWARZ := Color(0.051, 0.090, 0.067)   ## #0D1711 Grund und Schatten
const ROHR_BRAUN := Color(0.341, 0.188, 0.082)      ## #573015 Rohre, alte Leitungen
const MESSING := Color(0.384, 0.306, 0.161)         ## #624E29 Beschläge, Laufrost
const KANALGRUEN := Color(0.122, 0.298, 0.247)      ## #1F4C3F Metallwände
const ROSTORANGE := Color(0.576, 0.282, 0.106)      ## #93481B das einzige Warme
const SANDGELB := Color(0.729, 0.580, 0.333)        ## #BA9455 Messingglanz

## Das Gift in der Rinne. Es leuchtet – es soll auch im Dunkeln zu sehen
## sein, dass man da nicht hineinfällt.
const GIFT_TIEF := Color(0.075, 0.235, 0.145)
const GIFT_HELL := Color(0.310, 0.780, 0.330)
## Farbe der Taktfläche in Ruhe und in der Gefahr. Das Giftgrün kommt im
## Level sonst nur im Wasser vor – beides bringt um.
const TAKT_RUHE := Color(0.105, 0.160, 0.145)
const TAKT_GEFAHR := Color(0.360, 0.980, 0.400)


# ------------------------------------------------------------- Marken

const M_EINLAUF := 0.0
const M_STROMRINNE := 48.0
const M_FASSGANG := 108.0
const M_ROTORHALLE := 162.0
const M_GABELUNG := 214.0
const M_KLAERBECKEN := 272.0
const M_ENDE := 340.0

const WASSER_HOEHE := -1.5      ## Spiegel der Giftbrühe unter dem Laufrost
const KANALGRUND := -3.2        ## Sohle des Kanals, reine Kulisse
const ABSTURZ := -4.0

## Höhe, unter der nur noch Krabbeln durchkommt (aufrecht 1,30 m,
## flach 0,76 m).
const KRIECHHOEHE := 0.95


const STRECKE := [
	# --- Einlaufbecken: der einzige weite Raum am Anfang ---
	{"von": 0.0, "bis": 48.0, "breite": 14.0, "breite_ende": 10.0},
	# --- Stromrinne: eng, durchgehend – die Gefahr liegt IM Boden ---
	{"von": 48.0, "bis": 108.0, "breite": 9.0},
	# --- Fassgang: das engste Stück, eine Lücke in der Mitte ---
	{"von": 108.0, "bis": 132.0, "breite": 8.0},
	{"von": 137.0, "bis": 162.0, "breite": 8.0},
	# --- Rotorhalle: breiter, damit die Scheiben Platz haben ---
	{"von": 162.0, "bis": 214.0, "breite": 12.0},
	# --- Gabelung: zwei Lücken, daneben der Seitenweg ---
	{"von": 214.0, "bis": 236.0, "breite": 10.0},
	{"von": 241.0, "bis": 258.0, "breite": 10.0},
	# --- Klärbecken: offen, ohne Wände ---
	{"von": 263.0, "bis": 300.0, "breite": 10.0, "breite_ende": 12.0},
	{"von": 305.0, "bis": 340.0, "breite": 13.0},
]

## Die Kanalwände. Ab dem Klärbecken stehen keine mehr – dort öffnet sich
## der Schacht nach oben, und der Horizont übernimmt.
const WAENDE := [
	{"von": -8.0, "bis": 48.0, "abstand": 7.6, "hoehe": 8.0},
	{"von": 48.0, "bis": 108.0, "abstand": 5.2, "hoehe": 9.5},
	{"von": 108.0, "bis": 162.0, "abstand": 4.8, "hoehe": 10.0},
	{"von": 162.0, "bis": 214.0, "abstand": 6.8, "hoehe": 8.5},
	# Weit gestellt, sonst hätte der Geheimweg keinen Platz.
	{"von": 214.0, "bis": 268.0, "abstand": 11.0, "hoehe": 7.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Kanal wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Kanalsohle", "tun": _grund_bauen},
		{"text": "Metallwände", "tun": _waende_bauen},
		{"text": "Laufrost wird verlegt", "tun": _boden_bauen},
		{"text": "Die Brühe steigt", "tun": _wasser_fluten},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferner Schachtrand", "tun": _horizont_bauen},
		{"text": "Strom wird aufgeschaltet", "tun": _stromrinne_bauen},
		{"text": "Fässer rollen an", "tun": _fassgang_bauen},
		{"text": "Rotoren laufen an", "tun": _rotorhalle_bauen},
		{"text": "Gabelung", "tun": _gabelung_bauen},
		{"text": "Klärbecken", "tun": _klaerbecken_bauen},
		{"text": "Rohre und Ventile", "tun": _rohre_bauen},
		{"text": "Messuhren", "tun": _messuhren_bauen},
		{"text": "Schimmel und Moos", "tun": _deko_bauen},
		{"text": "Stimmungen", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Ein Kanal knickt, er schwingt nicht. Die Kurven sind deshalb kürzer und
## härter als in den Naturleveln – und sie liegen genau vor den Taktwellen:
## Was hinter der Ecke taktet, sieht man erst, wenn man drinsteht.
##
## Nach unten geht es fast durchgehend: 0 m am Einlauf, −7 m am Becken.
## Ein Kanal fließt.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, -0.4, -20),
		Vector3(2, -0.9, -44),        # Einlaufbecken
		Vector3(14, -1.6, -64),       # Knick in die Stromrinne
		Vector3(36, -2.2, -74),
		Vector3(60, -2.8, -70),
		Vector3(78, -3.4, -56),       # Fassgang
		Vector3(88, -3.9, -34),
		Vector3(88, -4.3, -10),       # Rotorhalle
		Vector3(78, -4.8, 12),
		Vector3(60, -5.3, 26),        # Gabelung
		Vector3(38, -5.8, 32),
		Vector3(14, -6.3, 30),        # Klärbecken
		Vector3(-8, -6.8, 20),
		Vector3(-24, -7.2, 4),
	], 0.38)


# =========================================================== Grund

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.metall(MESSING.darkened(0.34)),
		"kante": Materialbibliothek.metall(KANALGRUEN),
		"klippe": Materialbibliothek.metall(KANAL_SCHWARZ.lightened(0.12)),
	}, {"tiefe": 2.6, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.65})
	# Die Kantenpfosten an den Lücken sind rostorange – dieselbe Farbe wie
	# die Kisten. Warm heißt in diesem Level: hier ist etwas für dich.
	luecken_markieren(ROSTORANGE)


## Die Wände sind Metall, keine Felsen: Blockplatten in Kanalgrün, darüber
## Bänder aus altem Rohrbraun und oben eine Lage Messing. Drei Töne aus der
## gemessenen Palette – eine einfarbige Wand hätte den Kanal zu einer
## grünen Röhre gemacht, in der keine Kiste mehr auffällt.
func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			Materialbibliothek.metall(KANALGRUEN), {
		"schritt": 2.2, "lagen": 4, "block": 2.8,
		"sockel": 8.0, "saat": 1601,
		"adermaterial": Materialbibliothek.metall(ROHR_BRAUN),
		"deckmaterial": Materialbibliothek.metall(MESSING),
		"aderdichte": 0.20,
	})
	# Die Sichtwand ist ein Blockhaufen und taugt nicht als Begrenzung – an
	# ihren Kanten bliebe man hängen. Dahinter läuft eine glatte Leitwand.
	# In der Gabelung steht sie bewusst weit draußen: Der Geheimweg liegt
	# seitlich neben dem Weg, eine enge Leitwand hätte ihn abgeschnitten.
	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), w["abstand"] - 0.4, 6.0)


## Die Sohle tief unten. Nicht erreichbar – wer fällt, ertrinkt vorher in
## der Brühe – aber sie gibt dem Kanal einen Boden statt eines Lochs.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(320.0, 320.0)
	var mi := MeshInstance3D.new()
	mi.name = "Kanalsohle"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.metall(KANAL_SCHWARZ)
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, KANALGRUND)
	geometrie.add_child(mi)


## Giftbrühe unter dem ganzen Laufrost. Sie ist tödlich und leuchtet –
## beides gehört zusammen: Was hier grün schimmert, bringt um, und das
## soll man sehen, bevor man springt.
func _wasser_fluten() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ENDE:
		var w := wasser(s + schritt * 0.5, Vector2(56.0, schritt + 2.0),
				WASSER_HOEHE)
		w.tiefe = 1.6
		w.toedlich = true
		w.wellen_hoehe = 0.06
		w.wellen_tempo = 0.45
		w.farbe_tief = GIFT_TIEF
		w.farbe_hell = GIFT_HELL
		w.spiegelung = 0.30
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 76.0)


## Der ferne Rand des Schachts. Ab dem Klärbecken stehen keine Wände mehr;
## ohne diesen Ring endete die Welt dort an einer geraden Linie.
func _horizont_bauen() -> void:
	horizont(260.0, 26.0, KANAL_SCHWARZ.lightened(0.06),
			KANALGRUEN.darkened(0.45), false, KANALGRUND - 1.0)


# =========================================================== Stromrinne

## 48–108 · Stromrinne. Das Herzstück.
##
## Zwei Wellen aus Taktflächen, dazwischen eine sichere Insel. Die Platten
## reichen über die ganze Wegbreite – es gibt kein Vorbeikommen an der
## Seite, nur ein Vorbeikommen in der Zeit. Zwischen zwei Platten bleibt
## gut ein Meter trockener Rost: Das ist die Stufe, auf der man wartet.
##
## Der Versatz je Platte ist klein (0,18 eines Durchlaufs). Damit läuft die
## Gefahr als Welle VOR dem Spieler her statt gegen ihn – wer beim
## Aufleuchten der nächsten Platte losgeht, kommt durch. Das ist die Zusage
## des Bauteils, und dieses Level lebt davon, dass sie stimmt.
func _stromrinne_bauen() -> void:
	# Eine einzelne Platte zum Kennenlernen, noch im Trockenen. Sie liegt
	# schmal in der Wegmitte: Wer sie nicht lesen will, geht außen herum.
	_stromplatte(taktflaeche(42.0, 0.0, Vector2(4.0, 3.0), 0.0))

	# Welle A – vier Platten, volle Breite, kein Vorbei.
	for t in taktwelle(56.0, 68.0, 4, 0.0, Vector2(8.4, 2.9), 0.18):
		_stromplatte(t)

	# Insel 70–82: kein Takt, dafür Kisten und ein Gegner. Nach vier
	# Platten braucht der Kopf eine Pause, sonst wird aus Rhythmus Stress.

	# Welle B – fünf Platten, engerer Takt, längere Gefahrzeit.
	for t in taktwelle(86.0, 104.0, 5, 0.0, Vector2(8.4, 2.9), 0.16):
		_stromplatte(t)
		t.ruhe_zeit = 1.6
		t.gefahr_zeit = 1.4

	# Ein Balken über der Insel: geduckt hindurch, und zwar im Trockenen –
	# Krabbeln auf einer Taktfläche wäre kein Können, sondern Pech.
	stachelbalken(76.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


## Färbt eine Taktfläche auf Kanalgrün ein. Die Vorgabe ist Signalrot; in
## diesem Level ist Rot aber die Farbe der Kisten, und zwei Bedeutungen auf
## einer Farbe sind eine zu viel.
func _stromplatte(t: Taktflaeche) -> void:
	t.farbe_ruhe = TAKT_RUHE
	t.farbe_gefahr = TAKT_GEFAHR


# =========================================================== Fassgang

## 108–162 · Fassgang. Das engste Stück, und darin rollen Fässer.
##
## Sie kommen dem Spieler ENTGEGEN (von hinten nach vorn auf der Kurve
## gerechnet): Ein Fass, das mit einem läuft, holt man nie ein, eines das
## entgegenkommt, zwingt zur Entscheidung. Zwei Bahnen laufen versetzt,
## sodass immer eine Seite frei ist – aber nie dieselbe.
func _fassgang_bauen() -> void:
	_giftfass(130.0, 110.0, -2.2, 0.95, 9.5, 1.8, 0.0)
	_giftfass(130.0, 112.0, 2.2, 0.95, 8.5, 2.2, 0.5)
	_giftfass(160.0, 138.0, 0.0, 1.05, 10.0, 2.6, 0.2)
	_giftfass(158.0, 140.0, -2.4, 0.85, 8.0, 2.0, 0.65)

	# Zwei Taktflächen halten das Thema wach, ohne den Gang zuzustellen.
	_stromplatte(taktflaeche(118.0, 0.0, Vector2(7.4, 2.6), 0.0))
	_stromplatte(taktflaeche(148.0, 0.0, Vector2(7.4, 2.6), 0.45))

	# Über der Lücke bei 132–137 zwei Trittsimse aus alten Rohrstücken.
	var stoff := Materialbibliothek.metall(ROHR_BRAUN)
	plattform(133.6, -1.6, -0.35, Vector3(2.4, 0.5, 2.4), stoff)
	plattform(135.6, 1.6, -0.35, Vector3(2.4, 0.5, 2.4), stoff)


## Giftfass: rollendes Hindernis in der Farbe der Brühe.
##
## Eigener Bau statt `rollbrocken()`, weil `Rollhindernis` seine Optik in
## `_ready()` aufbaut – die Farbe muss VOR `add_child` stehen, und der
## Bauhelfer hängt den Knoten sofort ein. Ein rostiges Fass wäre hier
## zudem falsch: Rostorange ist in diesem Level die Farbe der Kisten.
func _giftfass(von: float, bis: float, seitlich: float, radius: float,
		tempo: float, pause: float, phase: float) -> Rollhindernis:
	var r := ROLLHINDERNIS.instantiate() as Rollhindernis
	r.art = Rollhindernis.Art.FASS
	r.verlauf = verlauf
	r.strecke_von = von
	r.strecke_bis = bis
	r.seitlich = seitlich
	r.hoehe = 0.0
	r.radius = radius
	r.tempo = tempo
	r.pause = pause
	r.phase = phase
	r.farbe = GIFT_TIEF.lightened(0.10)
	r.saat = int(von * 7.0) + 5
	objekte.add_child(r)
	return r


# =========================================================== Rotorhalle

## 162–214 · Rotorhalle. Der Boden dreht sich.
##
## Die Rotorblätter sind Drehscheiben: Man steht darauf und wird
## mitgenommen. Wer stehen bleibt, steht nach zwei Sekunden quer – das ist
## dieselbe Lehre wie in der Stromrinne, nur andersherum. Dort kostet
## Laufen, hier kostet Stehenbleiben.
##
## Zwischen den Scheiben liegt fester Rost. Ein Fehltritt kostet den Weg,
## nicht das Leben – die Scheiben selbst sind schwer genug.
func _rotorhalle_bauen() -> void:
	drehscheibe(170.0, -3.2, 0.15, 5.0, 42.0, 1)
	drehscheibe(178.0, 3.2, 0.15, 5.0, 42.0, -1)
	drehscheibe(188.0, 0.0, 0.15, 6.2, 34.0, 1, 0.0, 0.0, true)
	drehscheibe(198.0, -3.6, 0.15, 4.6, 54.0, -1)
	drehscheibe(206.0, 3.6, 0.15, 4.6, 54.0, 1)

	# Und darüber, quer über den ganzen Gang, der Takt aus der Rinne.
	for t in taktwelle(182.0, 194.0, 3, 0.0, Vector2(11.0, 2.6), 0.33):
		_stromplatte(t)

	# Ein Fass kreuzt die Halle der Länge nach – es zwingt dazu, auf einer
	# Scheibe zu bleiben, statt auf den festen Rost zu flüchten.
	_giftfass(212.0, 166.0, 0.0, 1.0, 11.0, 3.4, 0.3)

	# Der zweite Krabbelbalken, kurz vor der Gabelung.
	stachelbalken(211.0, 0.0, KRIECHHOEHE, Vector2(7.0, 1.1))


# =========================================================== Gabelung

## 214–272 · Die Sackgasse, die keine ist.
##
## Rechts neben dem Weg liegt ein Absatz, auf dem drei Nitro-Kisten stehen,
## und dahinter eine Wand. Von der Hauptstrecke aus sieht das nach einem
## Ende aus, und genau deshalb geht kaum jemand hin. Wer es trotzdem tut –
## mit Doppelsprung über die Nitro-Kisten hinweg – findet eine Kette
## Plattformen, die HINTER der Wand weiterläuft und in einer Nische mit
## Extraleben endet.
##
## Die Wand ist der ganze Trick. Sie steht zwischen Hauptweg und
## Plattformkette, nicht quer über die Kette. Sie verdeckt also nur die
## Auskunft, nicht den Weg. Was offensichtlich falsch aussieht, ist
## manchmal der richtige Weg.
##
## Der Hauptweg daneben bleibt vollwertig: zwei Lücken, eine Bruchplatte,
## nichts, was man verpassen kann.
func _gabelung_bauen() -> void:
	var rohr := Materialbibliothek.metall(ROHR_BRAUN)
	var blech := Materialbibliothek.metall(KANALGRUEN.darkened(0.25))

	# --- Hauptweg: die beiden Lücken ---
	bruchplatten_reihe(237.0, 240.0, 2, 0.0, -0.1, Vector2(2.6, 2.6))
	plattform(260.5, 0.0, -0.35, Vector3(3.0, 0.5, 2.6), rohr)

	# --- Der Absatz mit den Nitro-Kisten ---
	# Oberkante bündig mit dem Laufrost, damit er wie ein Stück Weg wirkt
	# und nicht wie eine Plattform, auf die man springen soll.
	plattform(231.0, 5.6, -0.31, Vector3(4.6, 0.62, 12.0), blech)

	# --- Die Wand, die den Rest verdeckt ---
	# In Stücken, weil ein einziger Kasten dem gebogenen Weg nicht folgt.
	for s: float in [240.0, 244.0, 248.0, 252.0, 256.0]:
		plattform(s, 4.5, 2.4, Vector3(0.7, 5.0, 4.3), blech)

	# --- Die Kette dahinter ---
	plattform(238.5, 6.8, 1.0, Vector3(3.0, 0.5, 3.0), rohr)
	plattform(243.5, 7.5, 1.6, Vector3(3.0, 0.5, 3.0), rohr)
	plattform(248.5, 7.5, 2.2, Vector3(3.0, 0.5, 3.0), rohr)
	plattform(253.5, 6.9, 2.6, Vector3(3.0, 0.5, 3.0), rohr)
	# Die Nische: breit genug zum Ausruhen, das ist der Lohn.
	plattform(259.0, 6.4, 2.8, Vector3(5.2, 0.6, 6.0), blech)
	# Und zurück auf die Hauptstrecke – der Geheimweg ist keine Sackgasse
	# für den, der ihn geht.
	plattform(265.5, 3.2, 1.2, Vector3(3.4, 0.5, 3.4), rohr)

	# Ein Fass auf dem Hauptweg, damit die Gabelung nicht zur Ruhezone wird.
	_giftfass(256.0, 216.0, 0.0, 1.0, 9.0, 3.0, 0.0)
	_stromplatte(taktflaeche(226.0, 0.0, Vector2(9.4, 2.8), 0.0))
	_stromplatte(taktflaeche(250.0, 0.0, Vector2(9.4, 2.8), 0.5))


# =========================================================== Klärbecken

## 272–340 · Klärbecken. Der Kanal mündet, die Wände hören auf.
##
## Nach 270 m Röhre ist das Weite selbst die Belohnung – man sieht zum
## ersten Mal etwas anderes als Metall über sich. Deshalb steht hier auch
## die dichteste Gegnerfolge: Erst im Offenen ist Platz, sich zu wehren.
func _klaerbecken_bauen() -> void:
	# Über die Lücke bei 300–305 zwei Rotorscheiben als Trittsteine. Sie
	# sind dasselbe Bauteil wie in der Halle, jetzt aber über dem Nichts –
	# ein Hindernis, zwei Rollen.
	drehscheibe(301.5, -1.4, -0.15, 3.4, 46.0, 1)
	drehscheibe(303.5, 1.6, -0.15, 3.4, 46.0, -1)

	# Letzte Taktwelle, jetzt im Breiten und mit einer Lücke an der Seite:
	# Wer den Rhythmus gelernt hat, geht durch; wer nicht, geht außen herum
	# und verliert nur Zeit. Ein Level soll seine eigene Lehre am Ende auch
	# einmal freiwillig machen lassen.
	for t in taktwelle(312.0, 324.0, 4, -2.0, Vector2(7.6, 2.8), 0.2):
		_stromplatte(t)

	_giftfass(298.0, 276.0, 2.0, 0.9, 8.5, 2.4, 0.15)
	_giftfass(338.0, 310.0, 3.4, 0.9, 9.0, 3.2, 0.55)


# =========================================================== Kulisse

## Rohrleitungen an beiden Wänden, mit Flanschen und Ventilrädern.
##
## Sie erzählen „Maschine", ohne dass sich etwas bewegt – genau das war die
## Vorgabe. Sie laufen der Wand entlang, nicht quer, damit sie den Blick
## nach vorn führen statt ihn zu zerschneiden.
func _rohre_bauen() -> void:
	var rohrstoff := Materialbibliothek.metall(ROHR_BRAUN)
	var flanschstoff := Materialbibliothek.metall(MESSING)
	var ventilstoff := Materialbibliothek.metall(SANDGELB.darkened(0.25))

	for w in WAENDE:
		var von: float = maxf(w["von"], 0.0)
		var bis: float = minf(w["bis"], M_ENDE)
		var abstand: float = float(w["abstand"]) - 0.55
		var s := von
		var zaehler := 0
		while s < bis:
			var laenge := minf(6.0, bis - s)
			for seite: float in [-1.0, 1.0]:
				# Zwei Leitungen übereinander, leicht versetzt.
				var hoehe: float = 2.6 if zaehler % 2 == 0 else 4.1
				_rohrstueck(s + laenge * 0.5, seite * abstand, hoehe,
						laenge + 0.3, 0.26, rohrstoff)
				if zaehler % 2 == 0:
					_rohrstueck(s + laenge * 0.5, seite * (abstand - 0.15),
							hoehe + 1.6, laenge + 0.3, 0.17, rohrstoff)
				# Flansch am Stoß – eine Leitung ohne Nähte wirkt wie ein
				# gezogener Strich, nicht wie Rohr.
				_flansch(s + laenge, seite * abstand, hoehe, 0.36,
						flanschstoff)
			if zaehler % 3 == 0:
				var seite2: float = -1.0 if zaehler % 6 == 0 else 1.0
				_ventilrad(s + laenge * 0.5, seite2 * (abstand - 0.4), 2.6,
						ventilstoff)
			s += laenge
			zaehler += 1


## Ein liegendes Rohrstück, das dem Weg folgt.
func _rohrstueck(strecke: float, seitlich: float, hoehe: float, laenge: float,
		radius: float, stoff: Material) -> void:
	var walze := CylinderMesh.new()
	walze.top_radius = radius
	walze.bottom_radius = radius
	walze.height = laenge
	walze.radial_segments = 8
	walze.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = walze
	mi.material_override = stoff
	# Die Walze steht auf der Y-Achse; erst kippen, dann mit dem Weg drehen.
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	mi.transform = Transform3D(
			Basis(Vector3.UP, dreh) * Basis(Vector3.RIGHT, PI * 0.5),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))
	deko.add_child(mi)


func _flansch(strecke: float, seitlich: float, hoehe: float, radius: float,
		stoff: Material) -> void:
	var scheibe := CylinderMesh.new()
	scheibe.top_radius = radius
	scheibe.bottom_radius = radius
	scheibe.height = 0.14
	scheibe.radial_segments = 8
	scheibe.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = scheibe
	mi.material_override = stoff
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	mi.transform = Transform3D(
			Basis(Vector3.UP, dreh) * Basis(Vector3.RIGHT, PI * 0.5),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))
	deko.add_child(mi)


## Rundes Ventilrad an der Wand – Speichen und Kranz.
func _ventilrad(strecke: float, seitlich: float, hoehe: float,
		stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var kranz := TorusMesh.new()
	kranz.inner_radius = 0.34
	kranz.outer_radius = 0.46
	kranz.rings = 10
	kranz.ring_segments = 6
	var reifen := MeshInstance3D.new()
	reifen.mesh = kranz
	reifen.material_override = stoff
	# Das Rad steht senkrecht an der Wand, blickt also quer zum Weg.
	reifen.rotation.z = PI * 0.5
	gruppe.add_child(reifen)

	for i in 3:
		var speiche := BoxMesh.new()
		speiche.size = Vector3(0.07, 0.9, 0.07)
		var stab := MeshInstance3D.new()
		stab.mesh = speiche
		stab.material_override = stoff
		stab.rotation = Vector3(float(i) * PI / 3.0, 0.0, 0.0)
		gruppe.add_child(stab)


## Messuhren an der Wand: kleine leuchtende Zifferblätter.
##
## Sie sind die einzigen Lichtpunkte zwischen den Kisten und geben dem Auge
## in der Dunkelheit einen Anhalt, wie weit die Wand noch reicht.
func _messuhren_bauen() -> void:
	var gehaeuse := Materialbibliothek.metall(MESSING)
	var glas := Materialbibliothek.leuchtend(SANDGELB, 0.9)
	var wuerfel := randi()
	seed(16101)
	for w in WAENDE:
		var von: float = maxf(w["von"], 2.0)
		var bis: float = minf(w["bis"], M_ENDE)
		var abstand: float = float(w["abstand"]) - 0.45
		var anzahl := int((bis - von) / 13.0)
		for i in anzahl:
			var s := lerpf(von, bis, (float(i) + 0.5) / maxf(float(anzahl), 1.0))
			var seite: float = -1.0 if i % 2 == 0 else 1.0
			var hoehe := randf_range(1.9, 3.2)
			# Gehäuse an der Wand, Zifferblatt eine Handbreit davor.
			_scheibe_an_der_wand(s, seite * abstand, hoehe, 0.30, 0.16,
					gehaeuse)
			_scheibe_an_der_wand(s, seite * (abstand - 0.13), hoehe, 0.21,
					0.06, glas)
	seed(wuerfel)


## Flache Scheibe, die quer zum Weg an der Wand klebt.
func _scheibe_an_der_wand(strecke: float, seitlich: float, hoehe: float,
		radius: float, dicke: float, stoff: Material) -> void:
	var topf := CylinderMesh.new()
	topf.top_radius = radius
	topf.bottom_radius = radius
	topf.height = dicke
	topf.radial_segments = 10
	topf.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = topf
	mi.material_override = stoff
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	# Die Walze steht auf der Y-Achse; um Z gekippt zeigt sie quer zum Weg.
	mi.transform = Transform3D(
			Basis(Vector3.UP, dreh) * Basis(Vector3.FORWARD, PI * 0.5),
			LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe))
	deko.add_child(mi)


## Schimmel, Pilze und Algenpolster am Wegrand. Sie sind der einzige
## organische Ton in einem Level aus Blech – ohne sie sieht der Kanal aus
## wie frisch gebaut statt wie seit Jahren vergessen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(16102)
	for i in 64:
		var s := randf_range(3.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.5)
		if rand < 1.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.BUSCH
		kleinzeug.groesse = randf_range(0.3, 0.7)
		kleinzeug.saat = 16200 + i
		kleinzeug.eigene_farbe = true
		kleinzeug.farbe = KANALGRUEN.lerp(GIFT_HELL, randf() * 0.5)
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.75, rand), 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)


## Licht und Nebel je Abschnitt.
##
## Die Grundstimmung der Szene ist der enge Kanal: fast schwarz, dichter
## Dunst. Die beiden weiten Stellen – Einlaufbecken und Klärbecken – heben
## sich davon ab. Erst dadurch fühlt sich das Klärbecken nach Ankommen an
## und nicht nach dem nächsten Rohr.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 46.0, KANALGRUEN.lerp(GIFT_TIEF, 0.4), 0.022, 0.85,
			Color(0.24, 0.32, 0.28), 42.0)
	stimmung(48.0, 214.0, KANAL_SCHWARZ.lightened(0.10), 0.045, 0.55,
			Color(0.16, 0.24, 0.22), 34.0)
	stimmung(216.0, 268.0, KANAL_SCHWARZ.lightened(0.14), 0.036, 0.70,
			Color(0.18, 0.27, 0.25), 44.0)
	stimmung(272.0, M_ENDE, GIFT_TIEF.lightened(0.18), 0.016, 1.05,
			Color(0.30, 0.40, 0.36), 56.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 4.0)


# =========================================================== Kisten

## Rostorange Kisten sind das einzige Warme im Bild. Sie stehen deshalb
## nicht nur da, wo etwas zu holen ist, sondern auch da, wo der Weg
## weitergeht – in einem so dunklen Level führt die Farbe besser als jede
## Wegmarke.
func _kisten_setzen() -> void:
	# ---------- Einlaufbecken ----------
	kiste(Kiste.Art.CHECKPOINT, 5.0, -2.8)
	kiste(Kiste.Art.NORMAL, 10.0, -2.5)
	kiste(Kiste.Art.NORMAL, 10.0, 0.0)
	kiste(Kiste.Art.NORMAL, 10.0, 2.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 16.0, 0.0)
	kiste(Kiste.Art.EISEN, 22.0, 2.6)
	kiste(Kiste.Art.NORMAL, 22.0, 2.6, 1.6)
	kiste(Kiste.Art.NORMAL, 28.0, -3.0)
	kiste(Kiste.Art.SCHUTZ, 34.0, 0.0)
	kiste(Kiste.Art.NORMAL, 40.0, 2.4)
	kiste(Kiste.Art.NORMAL, 45.0, -2.4)

	# ---------- Stromrinne: nur auf trockenem Rost ----------
	kiste(Kiste.Art.NORMAL, 50.0, -2.2)
	kiste(Kiste.Art.NORMAL, 50.0, 2.2)
	kiste(Kiste.Art.EISEN, 53.0, 0.0)
	kiste(Kiste.Art.NORMAL, 71.0, -2.0)
	kiste(Kiste.Art.CHECKPOINT, 74.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 79.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 82.0, -2.4)
	kiste(Kiste.Art.NORMAL, 106.0, 2.0)

	# ---------- Fassgang ----------
	kiste(Kiste.Art.NORMAL, 112.0, -2.2)
	kiste(Kiste.Art.NORMAL, 112.0, 2.2)
	kiste(Kiste.Art.TNT, 122.0, 0.0)
	kiste(Kiste.Art.NORMAL, 122.0, -2.0)
	kiste(Kiste.Art.NORMAL, 122.0, 2.0)
	kiste(Kiste.Art.NORMAL, 129.0, 1.8)
	kiste(Kiste.Art.CHECKPOINT, 138.0, -2.2)
	kiste(Kiste.Art.NORMAL, 144.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 152.0, -2.0)
	kiste(Kiste.Art.NORMAL, 158.0, 2.0)

	# ---------- Rotorhalle ----------
	kiste(Kiste.Art.NORMAL, 166.0, -3.4)
	kiste(Kiste.Art.NORMAL, 166.0, 3.4)
	kiste(Kiste.Art.NORMAL, 174.0, 0.0)
	kiste(Kiste.Art.EISEN, 182.0, -4.0)
	kiste(Kiste.Art.NORMAL, 182.0, -4.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 192.0, 3.6)
	kiste(Kiste.Art.CHECKPOINT, 200.0, -3.0)
	kiste(Kiste.Art.SCHUTZ, 210.0, 3.0)
	kiste(Kiste.Art.NORMAL, 213.0, -2.6)

	# ---------- Gabelung: Hauptweg ----------
	kiste(Kiste.Art.NORMAL, 218.0, -2.4)
	kiste(Kiste.Art.NORMAL, 218.0, 2.4)
	kiste(Kiste.Art.TNT, 224.0, 0.0)
	kiste(Kiste.Art.NORMAL, 246.0, 0.0)
	kiste(Kiste.Art.NORMAL, 252.0, -2.4)
	kiste(Kiste.Art.CHECKPOINT, 266.0, -2.6)
	kiste(Kiste.Art.NORMAL, 269.0, 2.2)

	# ---------- Gabelung: der Geheimweg ----------
	# Die drei Nitro-Kisten sind die Warnung, die keine ist. Sie stehen am
	# ENDE des Absatzes, nicht am Anfang – wer den Absatz betritt, steht
	# nicht sofort im Feuer, sondern sieht erst, was ihn erwartet.
	kiste(Kiste.Art.NITRO, 233.0, 4.6)
	kiste(Kiste.Art.NITRO, 233.0, 6.6)
	kiste(Kiste.Art.NITRO, 235.5, 5.6)
	kiste(Kiste.Art.NORMAL, 227.0, 5.6)
	kiste(Kiste.Art.NORMAL, 243.5, 7.5, 2.35)
	kiste(Kiste.Art.NORMAL, 248.5, 7.5, 2.95)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 257.5, 6.4, 3.6)
	kiste(Kiste.Art.LEBEN, 259.0, 6.4, 3.6)
	kiste(Kiste.Art.SCHUTZ, 260.5, 6.4, 3.6)

	# ---------- Klärbecken ----------
	kiste(Kiste.Art.NORMAL, 276.0, -2.6)
	kiste(Kiste.Art.NORMAL, 276.0, 2.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 284.0, 0.0)
	kiste(Kiste.Art.TNT, 292.0, -2.0)
	kiste(Kiste.Art.NORMAL, 292.0, 2.0)
	kiste(Kiste.Art.FEDER, 297.0, 0.0)
	kiste(Kiste.Art.NORMAL, 310.0, -3.2)
	kiste(Kiste.Art.NORMAL, 310.0, 0.0)
	kiste(Kiste.Art.NORMAL, 310.0, 3.2)
	kiste(Kiste.Art.LEBEN, 320.0, 3.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 328.0, -2.4)
	kiste(Kiste.Art.NORMAL, 333.0, 2.4)


# =========================================================== Gegner

## Gegner stehen nur auf festem, trockenem Rost.
##
## Auf einer Taktfläche wäre ein Gegner keine Aufgabe, sondern Zufall: Er
## stirbt selbst, sobald der Strom kommt, oder er steht genau da, wo man
## warten muss. In der Stromrinne stehen deshalb nur zwei, und beide auf
## der sicheren Insel.
func _gegner_setzen() -> void:
	# ---------- Einlaufbecken: Platz, um alle Antworten zu üben ----------
	gegner(PANZERKAEFER, 14.0, -2.2, 4.0, true)
	werfer(20.0, -4.5)
	gegner(SUMPFKROETE, 26.0, 1.8, 3.5, true)
	gegner(STELZENSPINNE, 38.0, -2.0, 3.5, true)

	# ---------- Stromrinne: nur auf der Insel ----------
	gegner(SUMPFKROETE, 73.0, 0.0, 2.0, true)
	gegner(PANZERKAEFER, 105.0, -1.6, 2.0, true)

	# ---------- Fassgang ----------
	gegner(STELZENSPINNE, 116.0, 1.6, 2.0, true)
	gegner(PANZERKAEFER, 146.0, -1.8, 2.2, true)
	gegner(SUMPFKROETE, 156.0, 1.6, 2.0, true)

	# ---------- Rotorhalle ----------
	gegner(PANZERKAEFER, 170.0, 3.0, 3.0, true)
	werfer(186.0, -4.8)
	gegner(STELZENSPINNE, 196.0, 3.2, 3.0, true)
	gegner(SUMPFKROETE, 208.0, -2.8, 2.6, true)

	# ---------- Gabelung ----------
	gegner(PANZERKAEFER, 222.0, -2.2, 2.6, true)
	gegner(SUMPFKROETE, 248.0, 2.2, 2.4, true)

	# ---------- Klärbecken: die dichteste Folge ----------
	gegner(STELZENSPINNE, 279.0, -2.4, 3.0, true)
	schwarm(288.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 312.0, 3.0, 3.6, true)
	gegner(SUMPFKROETE, 322.0, -2.6, 3.0, true)
	werfer(330.0, 4.4)


# =========================================================== Früchte

## Früchte führen den Blick – und zwar bewusst NICHT über die Taktflächen:
## Eine Spur, die über eine tödliche Platte läuft, wäre eine Einladung ins
## Verderben. Über den Wellen liegen sie als Bogen, also auf Sprunghöhe;
## am Boden liegen sie nur da, wo der Rost trocken ist.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 30.0, 11, 0.0)
	fruechte_bogen(33.0, 44.0, 6, 0.0, 2.4)
	fruechte_reihe(48.0, 54.0, 4, 0.0)
	fruechte_bogen(56.0, 68.0, 7, 0.0, 2.8)
	fruechte_reihe(70.0, 82.0, 6, 0.0)
	fruechte_bogen(86.0, 104.0, 9, 0.0, 3.0)
	fruechte_reihe(108.0, 130.0, 9, 0.0)
	fruechte_bogen(132.0, 137.0, 5, 0.0, 2.6)
	fruechte_reihe(139.0, 160.0, 9, 0.0)
	fruechte_reihe(164.0, 212.0, 16, 0.0)
	fruechte_reihe(216.0, 234.0, 7, -1.8)
	fruechte_bogen(236.0, 241.0, 5, 0.0, 2.6)
	fruechte_reihe(243.0, 256.0, 6, 0.0)
	fruechte_bogen(258.0, 263.0, 5, 0.0, 2.6)
	# Über dem Geheimweg – wer bis hierher gekommen ist, soll sehen, dass
	# es weitergeht.
	fruechte_reihe(239.0, 254.0, 6, 7.2, 3.0)
	fruechte_reihe(266.0, 298.0, 12, 0.0)
	fruechte_bogen(300.0, 305.0, 5, 0.0, 2.8)
	fruechte_reihe(307.0, 336.0, 11, 2.6)
