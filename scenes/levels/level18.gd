extends KorridorLevel
## Level 18 – "Schwarmpfad"
##
## Steckbrief 4-3 (`doku/level-vorbilder.md`). Ein Dschungelpfad, über den
## in Wellen SCHWÄRME kommen. Ein Schwarm ist kein Gegner mit mehr
## Trefferpunkten, sondern ein Gegner mit anderer Form: Er kommt als
## Gruppe und fällt als Gruppe. Man weicht ihm nicht aus wie einem Käfer –
## man läuft ihm davon, oder man dreht sich einmal richtig.
##
## Die Antwort darauf liegt im Boden: die magentafarbenen DECKUNGSFLECKEN.
## Wer geduckt drinsteht, ist sicher. Das nutzt unser Krabbeln und braucht
## keine eigene Taste. Damit ist das ganze Level ein Wechsel aus RENNEN und
## DUCKEN – und deshalb liegen die Flecken rhythmisch, nicht dekorativ.
##
##     0 –  54  Wegkunde     weit · EIN Schwarm, EIN Fleck, sonst nichts
##    54 – 112  Wellenlauf   eng  · Flecken im 14-m-Takt, Wellen dazwischen
##   112 – 168  Wurzeltore   eng  · geduckt weiter – Krabbeln zweimal genutzt
##   168 – 222  Wurzelsteg   Lücken · springen, während der Schwarm nachkommt
##   222 – 282  Dickicht     eng  · zwei Takte: Rollnuss und Schwarm
##   282 – 336  Nest         weit · alles auf einmal, dann die Lichtung
##
## JEDER ABSCHNITT STELLT EINE FRAGE:
##   Wegkunde    – was ist ein Fleck, und wie steigt man hinein?
##   Wellenlauf  – schaffst du es von Fleck zu Fleck?
##   Wurzeltore  – geht das auch da, wo du ohnehin krabbeln musst?
##   Wurzelsteg  – und wenn unter dir nichts ist?
##   Dickicht    – und wenn zwei Dinge gleichzeitig kommen?
##   Nest        – alles zusammen.
##
## DIE SIGNALFARBE. Magenta kommt in diesem Level NUR auf den
## Deckungsflecken vor – nirgends sonst. Deshalb stehen hier rote Pilze
## statt der üblichen bunten Blumen, und deshalb gibt es keine Seerosen
## (deren Blüte ist magenta). Der Spieler soll einen Fleck an der Farbe
## erkennen, bevor er die Form erkennt.
##
## DAS LEVEL BRICHT SEINE REGEL GENAU EINMAL: Am Wurzelsteg liegt ein
## Fleck abseits über dem Nichts. Magenta hieß bisher "hier bist du
## sicher"; dieser eine ist nur mit einem Sprung ins Leere zu erreichen –
## und trägt dafür den besten Preis. Einmal, nie zweimal.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --------------------------------------------------------- Strecken-Marken
const M_WEGKUNDE := 0.0
const M_WELLEN := 54.0
const M_TORE := 112.0
const M_STEG := 168.0
const M_DICKICHT := 222.0
const M_NEST := 282.0
const M_ENDE := 336.0

# --------------------------------------------------------------- Höhen
const DSCHUNGELGRUND := -6.0
const ABSTURZ := -4.5
## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
## Aufrechte Kapsel 1,30 m, flache 0,76 m (siehe `stachelbalken`).
const KRIECHHOEHE := 0.95

# ------------------------------------------------------------ Leitfarben
# Gemessen aus dem Referenzbild des Steckbriefs; tragend ist das
# Dschungelgrün `#154D2A` gegen das Wegrot `#894113`. Die Werte sind hier
# aufgehellt: `albedo_color` MULTIPLIZIERT die Textur, der gemessene Ton
# ergäbe einen schwarzen Klumpen statt eines Weges.
## Rot-maroon gepflasterter Weg.
const WEG_ROT := Color(0.86, 0.44, 0.31)
## Heller Sandstreifen in der Wegmitte.
const WEG_SAND := Color(1.0, 0.93, 0.74)
## Erdreich unter dem Weg.
const ERDE_ROT := Color(0.72, 0.40, 0.30)
## Sattes Dschungelgrün für Kanten und Blattwerk.
const DSCHUNGEL := Color(0.10, 0.36, 0.18)
const DSCHUNGEL_HELL := Color(0.26, 0.56, 0.22)
## Hut der roten Pilze. Bewusst rot und nicht rosa – Rosa läge zu nah an
## der Signalfarbe der Flecken.
const PILZ_ROT := Color(0.74, 0.15, 0.11)
## Ferne Hügel.
const HUEGEL_NAH := Color(0.14, 0.30, 0.16)
const HUEGEL_FERN := Color(0.36, 0.50, 0.38)


## Der Weg. Zwei Lücken im Abschnitt "Wurzelsteg", sonst durchgehend.
const STRECKE := [
	# --- Wegkunde: der weite Auftakt, er verengt sich zum Pfad ---
	{"von": 0.0, "bis": 54.0, "breite": 17.0, "breite_ende": 11.0},
	# --- Wellenlauf: der eigentliche Pfad ---
	{"von": 54.0, "bis": 112.0, "breite": 10.0},
	# --- Wurzeltore ---
	{"von": 112.0, "bis": 168.0, "breite": 9.0},
	# --- Wurzelsteg: 179–190 und 200–209 sind Luft ---
	{"von": 168.0, "bis": 179.0, "breite": 8.0},
	{"von": 190.0, "bis": 200.0, "breite": 8.0},
	{"von": 209.0, "bis": 222.0, "breite": 8.5},
	# --- Dickicht ---
	{"von": 222.0, "bis": 282.0, "breite": 8.0},
	# --- Nest und Lichtung ---
	{"von": 282.0, "bis": 336.0, "breite": 14.0, "breite_ende": 18.0},
]

## Der helle Sandstreifen in der Mitte – dieselbe Bauhilfe wie der Weg,
## nur schmal, ohne Kollision und vier Zentimeter höher gelegt. Ein
## eingelegtes Band, kein zweiter Boden.
const SANDBAND := [
	{"von": 2.0, "bis": 52.0, "breite": 3.4},
	{"von": 56.0, "bis": 110.0, "breite": 2.8},
	{"von": 114.0, "bis": 166.0, "breite": 2.6},
	{"von": 170.0, "bis": 177.0, "breite": 2.6},
	{"von": 192.0, "bis": 198.0, "breite": 2.6},
	{"von": 211.0, "bis": 220.0, "breite": 2.6},
	{"von": 224.0, "bis": 280.0, "breite": 2.8},
	{"von": 284.0, "bis": 334.0, "breite": 3.4},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Der Pfad wird abgeschritten", "tun": _verlauf_anlegen},
		{"text": "Dschungelgrund", "tun": _grund_bauen},
		{"text": "Roter Weg mit Sandstreifen", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Wegkunde", "tun": _wegkunde_bauen},
		{"text": "Wellenlauf", "tun": _wellenlauf_bauen},
		{"text": "Wurzeltore", "tun": _wurzeltore_bauen},
		{"text": "Wurzelsteg", "tun": _wurzelsteg_bauen},
		{"text": "Dickicht", "tun": _dickicht_bauen},
		{"text": "Nest", "tun": _nest_bauen},
		{"text": "Stimmung unter dem Blätterdach", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Marken und Wurzelgewölbe", "tun": _bonus_bauen},
		{"text": "Schwärme steigen auf", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Regenwald", "tun": _wald_bauen},
		{"text": "Farne und rote Pilze", "tun": _deko_bauen},
	]


# =========================================================== Verlauf

## Ein weiter, offener Bogen. Kein Rundkurs: Der Pfad soll nie an sich
## selbst vorbeiführen, weil ein Schwarm sonst über die Abkürzung käme und
## der Spieler nicht verstünde, woher.
##
## Die engen Abschnitte liegen in den Biegungen, die beiden weiten
## (Wegkunde und Nest) auf den Geraden. Im Weiten will man sehen, was auf
## einen zukommt; im Engen soll die Sicht kurz sein, damit eine Welle
## überrascht.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 10),
		Vector3(2, 0, -14),
		Vector3(8, -0.4, -38),        # Wegkunde
		Vector3(20, -0.8, -60),
		Vector3(38, -1.0, -78),       # Wellenlauf
		Vector3(60, -1.0, -90),
		Vector3(84, -0.6, -96),       # Wurzeltore
		Vector3(108, 0.0, -94),
		Vector3(130, 0.8, -84),       # Wurzelsteg
		Vector3(148, 1.6, -68),
		Vector3(162, 2.4, -48),       # Dickicht
		Vector3(172, 3.0, -26),
		Vector3(178, 3.6, -2),        # Nest
		Vector3(180, 4.2, 22),
		Vector3(178, 5.0, 46),
		Vector3(172, 5.6, 68),
	])


# =========================================================== Grund

## Der rot-maroon gepflasterte Weg mit dem hellen Sandstreifen.
##
## Zwei Aufrufe von `korridor()`: Der erste baut den Weg mit Kollision, der
## zweite legt als schmales Band den Sandstreifen darüber – vier Zentimeter
## höher, ohne Kollision, damit er nur Zeichnung ist und keine Stufe.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _wegstoff(),
		"kante": Materialbibliothek.moos(),
		"klippe": _erdstoff(),
	}, {"tiefe": 3.0, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.8})

	LevelWerkzeuge.korridor(deko, verlauf, SANDBAND, {
		"oben": _sandstoff(),
		"kante": _sandstoff(),
		"klippe": _wegstoff(),
	}, {"tiefe": 0.3, "schritt": 1.4, "kollision": false,
			"kante_hoehe": 0.0, "kante_breite": 0.24, "hoehe_versatz": 0.04})

	luecken_markieren(WEG_ROT.darkened(0.45))


## Der rote Pflasterweg. Eigene Kopie, weil die Bibliothek keinen roten
## Weg kennt und ihre Materialien geteilt sind.
func _wegstoff() -> StandardMaterial3D:
	var m := Materialbibliothek.waldweg().duplicate() as StandardMaterial3D
	m.albedo_color = WEG_ROT
	return m


func _sandstoff() -> StandardMaterial3D:
	var m := Materialbibliothek.waldweg().duplicate() as StandardMaterial3D
	m.albedo_color = WEG_SAND
	return m


func _erdstoff() -> StandardMaterial3D:
	var m := Materialbibliothek.wurzelfels().duplicate() as StandardMaterial3D
	m.albedo_color = ERDE_ROT
	return m


## Der Waldboden weit unten. Nicht erreichbar – wer fällt, stirbt in der
## Absturzzone –, aber er macht die Tiefe sichtbar. Ohne ihn sähe man in
## den Lücken des Stegs in ein schwarzes Nichts.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(360.0, 360.0)
	var mi := MeshInstance3D.new()
	mi.name = "Dschungelgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.waldboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0, DSCHUNGELGRUND)
	geometrie.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


func _horizont_bauen() -> void:
	horizont(230.0, 30.0, HUEGEL_NAH, HUEGEL_FERN, false, DSCHUNGELGRUND - 1.0)


# =========================================================== Abschnitte

## 0–54 · Wegkunde. EINE Frage: Was ist ein magentafarbener Fleck?
##
## Deshalb steht hier genau ein Schwarm und genau ein Fleck, und der Fleck
## liegt so, dass der Schwarm über ihn hinwegzieht. Kein zweiter Gegner,
## keine Lücke, kein Balken – wer hier stirbt, hat die eine Regel nicht
## verstanden, und das soll man merken können.
func _wegkunde_bauen() -> void:
	# Der erste Fleck liegt mitten auf dem Weg und ist groß: Man soll ihn
	# nicht suchen müssen, sondern hineinlaufen.
	deckungsfleck(30.0, 0.0, 2.2).grundleuchten = 0.95
	# Der zweite kommt kurz danach und ist schon kleiner – die Übung.
	deckungsfleck(44.0, -1.8, 1.7).grundleuchten = 0.95
	# Zwei Steintore als Wegmarken. Sie tragen nichts, sie zählen den Weg.
	LevelWerkzeuge.torbogen(deko, verlauf, 20.0, 13.0,
			Materialbibliothek.rinde(), 11, -0.2)
	LevelWerkzeuge.torbogen(deko, verlauf, 50.0, 11.0,
			Materialbibliothek.rinde(), 11, -0.2)


## 54–112 · Wellenlauf. EINE Frage: Schaffst du es von Fleck zu Fleck?
##
## Die Flecken liegen im 14-m-Takt. Das ist bewusst knapp: Bei 8,5 m/s
## sind das 1,6 Sekunden reines Rennen zwischen zwei Deckungen – lang
## genug, um Tempo aufzunehmen, kurz genug, dass der Schwarm nie
## abgeschüttelt ist. Wer stehenbleibt, wird eingeholt; wer nur rennt,
## läuft in die nächste Welle.
##
## Die Flecken wechseln die Seite. Sonst wäre der Takt eine gerade Linie
## und der Spieler müsste nur die Taste halten.
func _wellenlauf_bauen() -> void:
	var stellen := [60.0, 74.0, 88.0, 102.0]
	var seiten := [1.6, -1.8, 2.0, -1.6]
	for i in stellen.size():
		deckungsfleck(stellen[i], seiten[i], 1.7).grundleuchten = 0.95
	# Umgestürzte Stämme quer über den Weg: Sie zwingen zum Sprung, genau
	# dort, wo der Schwarm am nächsten ist.
	_querstamm(67.0, 0.9)
	_querstamm(95.0, 0.9)


## 112–168 · Wurzeltore. EINE Frage: Geht das auch da, wo du ohnehin
## krabbeln musst?
##
## Hier wird das Krabbeln zum zweiten Mal gebraucht – und diesmal nicht
## als Deckung, sondern als Fortbewegung. Unter zwei der vier Torbögen
## hängt ein Dornbalken; darunter kommt nur die flache Kapsel durch. Und
## weil man dort ohnehin geduckt ist, liegt genau dort auch ein Fleck:
## dasselbe Bauteil, zwei Rollen.
func _wurzeltore_bauen() -> void:
	var rinde := Materialbibliothek.rinde()
	for s: float in [118.0, 132.0, 146.0, 160.0]:
		LevelWerkzeuge.torbogen(deko, verlauf, s, 10.0, rinde, 11, -0.2)

	# Zwei Dornbalken – nur krabbelnd passierbar.
	stachelbalken(132.0, 0.0, KRIECHHOEHE, Vector2(7.0, 1.2))
	stachelbalken(160.0, 0.0, KRIECHHOEHE, Vector2(7.0, 1.2))
	# Und genau darunter der Fleck: Wer krabbelt, ist zugleich in Deckung.
	deckungsfleck(132.0, 0.0, 1.8).grundleuchten = 0.95
	deckungsfleck(160.0, 0.0, 1.8).grundleuchten = 0.95
	# Ein dritter Fleck dazwischen, damit der Rhythmus nicht abreißt.
	deckungsfleck(146.0, 1.8, 1.6).grundleuchten = 0.95

	_querstamm(125.0, 0.9)
	_querstamm(153.0, 1.0)


## 168–222 · Wurzelsteg. EINE Frage: Und wenn unter dir nichts ist?
##
## Zwei Lücken, dazwischen Wurzelknollen als Trittsteine. Gemessen: Ein
## Normalsprung trägt bei 8,5 m/s und 12,2 Sprungkraft rund 5,5 m weit –
## die Abstände liegen bei 3,5 bis 4,5 m, also innerhalb eines Sprungs.
## Schwer ist nicht die Weite, schwer ist, dass der Schwarm dabei nachkommt
## und man auf einem Trittstein nicht ausweichen kann.
##
## HIER BRICHT DAS LEVEL SEINE REGEL. Abseits über dem Nichts liegt eine
## Wurzelinsel mit einem Deckungsfleck darauf. Magenta hieß bisher "hier
## bist du sicher" – dieser eine ist nur zu erreichen, indem man ins Leere
## springt. Dafür liegt darauf der beste Preis des Levels. Einmal, nie
## zweimal.
func _wurzelsteg_bauen() -> void:
	var holz := Materialbibliothek.rinde()

	# Erste Lücke, 179–190: zwei Knollen.
	plattform(182.5, 0.0, -0.25, Vector3(3.2, 0.6, 3.2), holz)
	plattform(186.5, -0.8, -0.25, Vector3(3.2, 0.6, 3.2), holz)
	# Zweite Lücke, 200–209: eine Knolle, dafür weiter.
	plattform(204.5, 0.6, -0.25, Vector3(3.4, 0.6, 3.4), holz)

	# Deckungsflecken auf den festen Stücken vor und nach jeder Lücke –
	# der Rhythmus geht weiter, nur die Abstände werden ungleich.
	deckungsfleck(174.0, -1.6, 1.6).grundleuchten = 0.95
	deckungsfleck(196.0, 1.6, 1.6).grundleuchten = 0.95
	deckungsfleck(216.0, -1.8, 1.7).grundleuchten = 0.95

	# --- Der Regelbruch: die Wurzelinsel abseits ---
	# Sie hängt seitlich über dem Abgrund. Von der Kante bei 195 m sind es
	# 5,0 m im Sprung – knapp innerhalb der Normalsprungweite, mit
	# Doppelsprung bequem. Wer den Fleck nur sieht und für sicher hält,
	# springt zu kurz und fällt; wer misst, gewinnt.
	plattform(195.0, 8.6, -0.35, Vector3(6.0, 0.7, 6.0), holz)
	_fleck_abseits(195.0, 8.6, 0.02, 1.8)


## Deckungsfleck OHNE Wegbindung.
##
## Die Bauhilfe `deckungsfleck()` in `korridor_level.gd` zieht einen Fleck
## immer auf den Weg zurück (`rand_bei()`), damit keiner über der
## Abbruchkante hängt – für den Regelfall genau richtig. Der eine Fleck
## auf der Wurzelinsel ist der Ausnahmefall: Er SOLL abseits liegen, sonst
## gäbe es den Regelbruch nicht. Deshalb hier von Hand.
func _fleck_abseits(strecke: float, seitlich: float, hoehe: float,
		radius: float) -> Deckungsfleck:
	var d := DECKUNGSFLECK.instantiate() as Deckungsfleck
	d.radius = radius
	d.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	objekte.add_child(d)
	return d


## 222–282 · Dickicht. EINE Frage: Und wenn zwei Dinge gleichzeitig kommen?
##
## Eine Rollnuss läuft den engen Gang hinunter, während der Schwarm von
## hinten nachsetzt. Der Fleck hilft gegen den Schwarm und NICHT gegen die
## Nuss – wer sich in Deckung wirft, muss trotzdem den Takt der Nuss lesen.
## Das ist der Trick des Vorbilds: Wer nur auf einen Takt achtet, wird vom
## anderen erwischt.
func _dickicht_bauen() -> void:
	# Beide Bahnen laufen durch die MITTE des Gangs. Am Rand liegen die
	# Flecken: Wer in Deckung geht, soll nicht zwangsläufig unter die Nuss
	# geraten – der Fleck hilft gegen den Schwarm, aber er darf nicht die
	# tödliche Antwort sein.
	rollbrocken(280.0, 228.0, 0.0, 0.0, 1.2, 8.0, 2.6, 0.0)
	rollbrocken(276.0, 234.0, -1.4, 0.0, 0.9, 6.5, 3.4, 0.45,
			Rollhindernis.Art.FASS)

	# Die Flecken liegen hier absichtlich AM RAND: In der Mitte läuft die
	# Nuss. Deckung und Rollbahn dürfen sich nicht überlagern, sonst wäre
	# die richtige Antwort zugleich die tödliche.
	deckungsfleck(232.0, -2.4, 1.6).grundleuchten = 0.95
	deckungsfleck(248.0, 2.4, 1.6).grundleuchten = 0.95
	deckungsfleck(264.0, -2.4, 1.6).grundleuchten = 0.95
	deckungsfleck(276.0, 2.4, 1.6).grundleuchten = 0.95

	_querstamm(242.0, 1.0)
	_querstamm(270.0, 1.0)


## 282–336 · Nest. EINE Frage: Alles zusammen.
##
## Der zweite weite Bereich. Hier stehen drei Schwärme, ein Werfer auf
## einem Podest und die dichteste Kistenreihe des Levels – und nur zwei
## Flecken, beide früh. Die letzten zwanzig Meter sind bewusst leer: Nach
## einem Level, das ums Stehenbleiben ging, soll der Schluss ein Lauf sein.
func _nest_bauen() -> void:
	deckungsfleck(288.0, -2.6, 1.8).grundleuchten = 0.95
	deckungsfleck(300.0, 2.6, 1.8).grundleuchten = 0.95

	# Drei Wurzelpodeste als Aussichts- und Sprungpunkte im Weiten.
	var holz := Materialbibliothek.rinde()
	plattform(294.0, 5.4, 0.9, Vector3(4.0, 0.7, 4.0), holz)
	plattform(308.0, -5.6, 1.3, Vector3(4.0, 0.7, 4.0), holz)
	plattform(316.0, 0.0, 2.0, Vector3(4.6, 0.7, 4.6), holz)

	_querstamm(298.0, 1.0)


## Ein umgestürzter Stamm quer über den Weg.
##
## Reine Kulisse ohne Kollision: Er soll den Blick brechen und dem Auge
## den Takt geben, nicht den Fuß aufhalten. Ein Hindernis, das man
## übersieht, weil es aussieht wie Deko, ist die schlechteste Art von
## Schwierigkeit.
func _querstamm(strecke: float, hoehe: float) -> void:
	var breite := maxf(breite_bei(strecke), 6.0) + 3.0
	var stamm := MeshInstance3D.new()
	var zylinder := CylinderMesh.new()
	zylinder.top_radius = 0.42
	zylinder.bottom_radius = 0.50
	zylinder.height = breite
	zylinder.radial_segments = 8
	stamm.mesh = zylinder
	stamm.material_override = Materialbibliothek.rinde()
	stamm.position = LevelWerkzeuge.punkt(verlauf, strecke, 0.0, hoehe)
	stamm.rotation = Vector3(0.0, LevelWerkzeuge.drehung(verlauf, strecke),
			PI * 0.5)
	deko.add_child(stamm)


## Licht und Nebel. Unter dem Blätterdach wird es enger und grüner, auf den
## beiden weiten Stücken heller und wärmer.
func _stimmungen_setzen() -> void:
	stimmung(M_WELLEN, M_STEG, Color(0.28, 0.44, 0.26), 0.018, 0.85,
			Color(0.34, 0.50, 0.30), 44.0)
	stimmung(M_DICKICHT, M_NEST, Color(0.22, 0.38, 0.22), 0.018, 0.75,
			Color(0.28, 0.46, 0.26), 40.0)
	stimmung(M_NEST, M_ENDE, Color(0.60, 0.68, 0.46), 0.01, 1.05,
			Color(0.62, 0.70, 0.50), 54.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Bonusraum

## Drei Marken und das Tor ins Wurzelgewölbe.
##
## Der Belohnungsvertrag verlangt eine dritte Ebene neben "ankommen" und
## "alle Kisten": einen eigenen Raum, betreten über gesammelte Marken.
## Level 18 ist das erste Level, das sie hat.
##
## DIE DREI MARKEN LIEGEN AUF DEN DREI FRAGEN, DIE DAS LEVEL SCHON STELLT –
## sie erfinden keine neue Aufgabe, sie bezahlen die vorhandenen:
##
##   44 m   Wegkunde   · offen neben dem Sandstreifen. Die erste soll man finden,
##                       nicht suchen; sonst lernt niemand, was sie ist.
##  195 m   Wurzelsteg · auf der Wurzelinsel abseits über dem Abgrund –
##                       auf dem einen Regelbruch des Levels. Wer den
##                       Sprung ins Leere wagt, bekommt den Sammelpreis
##                       UND den Schlüssel.
##  254 m   Dickicht   · vier Meter über der Federkiste. Nur mit ihrem
##                       Absprung zu holen, und das mitten in der Bahn
##                       der Rollnuss.
##
## Das Tor steht bei 316 m im Nest, SEITLICH neben dem Weg: Solange
## Marken fehlen, hat es einen Riegel, und ein Riegel darf nie im
## Hauptweg stehen. Wer die Marken nicht hat, läuft daran vorbei und
## verliert nichts.
##
## Wie das System arbeitet und was ein weiteres Level dafür tun muss,
## steht in `scenes/bonus/bonusraum.gd`.
func _bonus_bauen() -> void:
	Bonusraum.einbauen(self, [
		Vector3(44.0, 3.0, 1.2),
		Vector3(195.0, 8.6, 1.4),
		Vector3(254.0, 3.0, 4.0),
	], 316.0, -5.0, "Wurzelgewölbe")


# =========================================================== Kisten

## Kisten führen den Weg. In den Deckungsabschnitten stehen sie NEBEN den
## Flecken, nicht darauf: Eine Kiste auf dem Fleck stünde im Weg, wenn man
## sich hineinwerfen will.
func _kisten_setzen() -> void:
	# ---------- Wegkunde ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.4)
	kiste(Kiste.Art.NORMAL, 9.0, -2.4)
	kiste(Kiste.Art.NORMAL, 9.0, 0.0)
	kiste(Kiste.Art.NORMAL, 9.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 15.0, 0.0)
	kiste(Kiste.Art.NORMAL, 24.0, -3.2)
	kiste(Kiste.Art.NORMAL, 24.0, 3.2)
	kiste(Kiste.Art.SCHUTZ, 36.0, 2.6)
	kiste(Kiste.Art.NORMAL, 47.0, 2.4)

	# ---------- Wellenlauf ----------
	kiste(Kiste.Art.NORMAL, 57.0, -2.6)
	kiste(Kiste.Art.NORMAL, 64.0, 2.6)
	kiste(Kiste.Art.CHECKPOINT, 66.0, -2.6)
	kiste(Kiste.Art.EISEN, 71.0, 0.0)
	kiste(Kiste.Art.NORMAL, 71.0, 0.0, 1.6, true)
	kiste(Kiste.Art.NORMAL, 79.0, -2.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 85.0, 2.8)
	kiste(Kiste.Art.NORMAL, 93.0, -2.6)
	kiste(Kiste.Art.NORMAL, 99.0, 2.6)
	kiste(Kiste.Art.SCHUTZ, 108.0, 0.0)

	# ---------- Wurzeltore ----------
	kiste(Kiste.Art.NORMAL, 116.0, -2.4)
	kiste(Kiste.Art.NORMAL, 122.0, 2.4)
	kiste(Kiste.Art.TNT, 128.0, 0.0)
	kiste(Kiste.Art.NORMAL, 128.0, -2.2)
	kiste(Kiste.Art.CHECKPOINT, 130.0, 2.4)
	kiste(Kiste.Art.NORMAL, 139.0, -2.4)
	kiste(Kiste.Art.NORMAL, 139.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 151.0, 0.0)
	kiste(Kiste.Art.NORMAL, 157.0, -2.4)
	kiste(Kiste.Art.NORMAL, 165.0, 2.2)

	# ---------- Wurzelsteg ----------
	kiste(Kiste.Art.NORMAL, 171.0, -2.2)
	kiste(Kiste.Art.NORMAL, 177.0, 2.2)
	# Auf den Trittsteinen: Deckhöhe −0,25 + halbe Dicke 0,3 = 0,05.
	kiste(Kiste.Art.NORMAL, 182.5, 0.0, 0.55)
	kiste(Kiste.Art.NORMAL, 186.5, -0.8, 0.55)
	kiste(Kiste.Art.CHECKPOINT, 194.0, -2.2)
	kiste(Kiste.Art.NORMAL, 198.0, 2.2)
	kiste(Kiste.Art.NORMAL, 204.5, 0.6, 0.55)
	kiste(Kiste.Art.SCHUTZ, 213.0, -2.4)
	kiste(Kiste.Art.NORMAL, 219.0, 2.4)
	# Der Preis des Regelbruchs: Extraleben auf der Wurzelinsel.
	kiste(Kiste.Art.LEBEN, 195.0, 6.6, 0.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 195.0, 10.6, 0.5)

	# ---------- Dickicht ----------
	kiste(Kiste.Art.NORMAL, 226.0, -2.4)
	kiste(Kiste.Art.NORMAL, 238.0, 2.4)
	kiste(Kiste.Art.NORMAL, 245.0, -2.4)
	kiste(Kiste.Art.FEDER, 254.0, 3.0)
	kiste(Kiste.Art.CHECKPOINT, 262.0, 3.0)
	kiste(Kiste.Art.NORMAL, 268.0, -2.4)
	kiste(Kiste.Art.NORMAL, 274.0, 2.4)
	kiste(Kiste.Art.NORMAL, 279.0, -2.4)

	# ---------- Nest ----------
	kiste(Kiste.Art.NORMAL, 285.0, -3.4)
	kiste(Kiste.Art.NORMAL, 285.0, 0.0)
	kiste(Kiste.Art.NORMAL, 285.0, 3.4)
	# Auf den Wurzelpodesten: Deckmitte + halbe Dicke 0,35 + 0,5.
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 294.0, 5.4, 1.75)
	kiste(Kiste.Art.NORMAL, 308.0, -5.6, 2.15)
	kiste(Kiste.Art.SCHUTZ, 316.0, 0.0, 2.85)
	kiste(Kiste.Art.TNT, 304.0, 0.0)
	kiste(Kiste.Art.NORMAL, 304.0, -2.6)
	kiste(Kiste.Art.NORMAL, 304.0, 2.6)
	kiste(Kiste.Art.EISEN, 322.0, -3.0)
	kiste(Kiste.Art.NORMAL, 322.0, -3.0, 1.6, true)
	kiste(Kiste.Art.NORMAL, 328.0, 3.0)


# =========================================================== Gegner

## Die Schwärme sind das Thema, die übrigen Gegner der Kontrast.
##
## Ein Schwarm ist NUR mit dem Drehschlag zu besiegen und langsamer als der
## Spieler (3,4 gegen 8,5 m/s). Er holt niemanden ein – er wartet darauf,
## dass man zögert. Deshalb steht jeder Schwarm dort, wo man ohnehin
## anhalten muss: vor einer Lücke, an einer Kiste, unter einem Dornbalken.
##
## Die Bodengegner decken die drei anderen Antworten ab, damit das Level
## nicht zur Drehschlag-Übung wird: Panzerkäfer (draufspringen),
## Sumpfkröte (Drehschlag), Stelzenspinne (Slide).
func _gegner_setzen() -> void:
	# ---------- Wegkunde: EIN Schwarm, sonst nichts ----------
	schwarm(34.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 12.0, -2.0, 4.0, true)

	# ---------- Wellenlauf: die Wellen ----------
	schwarm(66.0, 0.0, 11.0)
	gegner(SUMPFKROETE, 76.0, 1.6, 2.6, true)
	schwarm(90.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 104.0, -1.6, 2.6, true)

	# ---------- Wurzeltore: der Schwarm wartet am Balken ----------
	# Direkt hinter dem Dornbalken bei 132: Wer sich unter ihm
	# durchgekrabbelt hat, steht auf und sieht ihn.
	schwarm(136.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 122.0, -1.8, 3.0, true)
	gegner(SUMPFKROETE, 150.0, 1.8, 2.6, true)
	werfer(163.0, -3.2)

	# ---------- Wurzelsteg: einer vor jeder Lücke ----------
	schwarm(176.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 197.0, 1.6, 2.4, true)
	schwarm(212.0, 0.0, 11.0)

	# ---------- Dickicht: der Schwarm gegen die Rollnuss ----------
	schwarm(250.0, 0.0, 12.0)
	gegner(PANZERKAEFER, 236.0, -2.0, 2.6, true)
	gegner(SUMPFKROETE, 266.0, 2.0, 2.6, true)

	# ---------- Nest: die dichteste Stelle ----------
	schwarm(292.0, -3.0, 12.0)
	schwarm(306.0, 3.0, 12.0)
	werfer(312.0, -6.0)
	gegner(STELZENSPINNE, 298.0, 2.4, 3.4, true)
	gegner(PANZERKAEFER, 320.0, -2.6, 4.0, true)


# =========================================================== Früchte

## Früchte führen den Blick – und hier auch den Takt: Über den Lücken
## liegen sie als Bogen, damit man die Sprungweite sieht, bevor man
## springt.
func _fruechte_setzen() -> void:
	fruechte_reihe(6.0, 48.0, 14, 0.0)
	fruechte_reihe(58.0, 110.0, 16, 0.0)
	fruechte_reihe(114.0, 166.0, 15, 0.0)
	fruechte_bogen(178.0, 191.0, 7, 0.0, 2.4)
	fruechte_bogen(199.0, 210.0, 6, 0.4, 2.2)
	# Die Spur zur Wurzelinsel – sie verrät den Regelbruch dem, der hinsieht.
	# Quer statt längs, deshalb von Hand: `fruechte_reihe()` läuft entlang
	# des Weges, hier soll die Spur von ihm weg führen.
	for i in 5:
		var t := float(i) / 4.0
		frucht(195.0, lerpf(3.4, 7.4, t), 0.9 + sin(t * PI) * 1.6)
	fruechte_reihe(212.0, 220.0, 4, 0.0)
	fruechte_reihe(224.0, 280.0, 16, 0.0)
	fruechte_reihe(284.0, 332.0, 15, 0.0)
	fruechte_reihe(290.0, 312.0, 6, 5.0)


# =========================================================== Kulisse

## Regenwald. Am Rand des Weges dicht und hoch, in den weiten Bereichen
## etwas zurückgesetzt, damit der Blick nach vorn frei bleibt.
##
## Alle Bäume ohne Kollision: Sie stehen neben dem Weg, teils über dem
## Abgrund, und sollen weder den Spieler noch die Absturzprüfung aufhalten.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(18001)
	for i in 132:
		var s := randf_range(-8.0, M_ENDE + 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var offen := _offener_bereich(s)
		var nah: float = 9.0 if offen else 6.5
		var quer := seite * randf_range(nah, nah + 20.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 7 == 0 else Baum.Art.LAUBBAUM
		baum.kronenform = Baum.Kronenform.SCHIRM if i % 3 == 0 \
				else Baum.Kronenform.HOCH
		baum.hoehe = randf_range(8.0, 16.0)
		baum.staerke = randf_range(0.8, 1.6)
		baum.saat = 18100 + i
		baum.laubfarbe = DSCHUNGEL.lerp(DSCHUNGEL_HELL, randf())
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, -1.2)
		deko.add_child(baum)

	# Wurzelanläufe an den Wegkanten – sie binden den Weg an den Wald.
	for i in 34:
		var s := randf_range(4.0, M_ENDE - 6.0)
		var rand := rand_bei(s, 1.0)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate()
		if "saat" in w:
			w.set("saat", 18300 + i)
		if "kollision" in w:
			w.set("kollision", false)
		w.position = LevelWerkzeuge.punkt(verlauf, s, seite * (rand + 1.4), -0.3)
		w.rotation.y = randf() * TAU
		deko.add_child(w)
	seed(wuerfel)


## Liegt die Stelle in einem der beiden weiten Bereiche?
func _offener_bereich(strecke: float) -> bool:
	return strecke < M_WELLEN or strecke > M_NEST


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(18002)

	# Unterholz am Wegrand.
	for i in 78:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.4, 2.6)), -0.05)
		horst.flaeche = Vector2(3.0, 3.0)
		horst.halm_hoehe = randf_range(0.7, 1.4)
		horst.farbe_unten = DSCHUNGEL.darkened(0.25)
		horst.farbe_oben = DSCHUNGEL_HELL
		horst.saat = 18500 + i
		deko.add_child(horst)

	# Farne und ROTE Pilze. Bewusst keine Blumen: Deren Palette enthält
	# Rosa, und Rosa läge zu nah an der Signalfarbe der Deckungsflecken.
	for i in 62:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		if i % 3 == 0:
			kleinzeug.art = Kleinzeug.Art.PILZ
			kleinzeug.eigene_farbe = true
			kleinzeug.farbe = PILZ_ROT
		else:
			kleinzeug.art = Kleinzeug.Art.FARN if i % 3 == 1 \
					else Kleinzeug.Art.BUSCH
			kleinzeug.eigene_farbe = true
			kleinzeug.farbe = DSCHUNGEL.lerp(DSCHUNGEL_HELL, randf())
		kleinzeug.groesse = randf_range(0.5, 1.1)
		kleinzeug.saat = 18700 + i
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	# Ein paar Findlinge auf den weiten Flächen, damit das Weite Maß bekommt.
	#
	# Sie tragen Kollision, stehen also nicht nur herum: Ein Findling
	# zwischen den Kisten wäre ein unsichtbarer Boden unter ihnen, und der
	# Levelcheck meldet dann eine Kiste, die im Boden steckt. Deshalb bleibt
	# das mittlere Wegdrittel frei – dort liegen die Kisten.
	for i in 20:
		var s: float = randf_range(4.0, 40.0) if i % 2 == 0 \
				else randf_range(M_NEST + 8.0, M_ENDE - 8.0)
		var rand := rand_bei(s, 1.6)
		if rand < 5.6:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate()
		if "saat" in stein:
			stein.set("saat", 18900 + i)
		if "groesse" in stein:
			stein.set("groesse", randf_range(0.7, 1.5))
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(5.0, rand), 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)
	seed(wuerfel)
