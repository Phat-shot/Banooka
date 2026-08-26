extends KorridorLevel
## Level 19 – "Sturmruinen"
##
## Steckbrief 4-4 (`doku/level-vorbilder.md`). Eine Ruinenstadt nachts im
## Gewitter. Das Thema ist der BODEN, der sich bewegt: Säulen, die sich
## drehen, und Platten, die nach kurzer Standzeit wegkippen. Wer hier
## stehen bleibt, steht nirgends.
##
## Der eigentliche Trick des Vorbilds ist aber nicht die Drehung – es ist,
## was DARAUF steht. Auf einer Drehscheibe steht oft ein Gegner, und der
## Spieler muss zwei bewegte Dinge gleichzeitig lesen: die Scheibe unter
## sich und das Tier darauf. `Drehplattform.aufsetzen()` kann das; ein
## aufgesetzter Gegner braucht `patrouille_weite = 0.0`, weil er sich
## seinen Startpunkt sonst in Weltkoordinaten merkt und von der Scheibe
## marschiert.
##
##     0 –  48  Torhof        fest · EINE Scheibe, sonst nichts
##    48 – 110  Säulengang    Lücke · fünf Scheiben über dem Nichts
##   110 – 168  Götzengang    eng  · Feuertakt aus steinernen Köpfen
##   168 – 228  Kippterrasse  Lücke · Bruchplatten und eine taumelnde Scheibe
##   228 – 288  Affenhof      fest · Gegner AUF den Scheiben, Werfer daneben
##   288 – 344  Sturmtreppe   steigend · alles zusammen, hinauf zum Tor
##
## JEDER ABSCHNITT STELLT EINE FRAGE:
##   Torhof        – was macht eine Drehscheibe mit dir?
##   Säulengang    – und wenn darunter nichts ist?
##   Götzengang    – kannst du einen Takt lesen, statt zu rennen?
##   Kippterrasse  – und wenn der Boden nur kurz trägt?
##   Affenhof      – und wenn der Boden UND der Gegner sich bewegen?
##   Sturmtreppe   – alles zusammen, und dabei aufwärts.
##
## DER BLITZ ist das Erkennungsmerkmal: In unregelmäßigen Abständen wird
## für zwei Zehntelsekunden die ganze Ruine hell. Er wird hier im Level
## gefahren (`_process`), nicht in einem eigenen Bauteil – er gehört zur
## Stimmung dieses einen Levels und nirgendwo sonst hin.
##
## DAS LEVEL BRICHT SEINE REGEL GENAU EINMAL: Im Götzengang steht ein
## Seitengang, der geradewegs in einen Götzenkopf führt. Er sieht aus wie
## der sichere Tod – aber genau dieser eine Kopf ist ausgebrannt und speit
## nie. Dahinter liegt der beste Preis des Levels.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --------------------------------------------------------- Strecken-Marken
const M_TORHOF := 0.0
const M_SAEULEN := 48.0
const M_GOETZEN := 110.0
const M_TERRASSE := 168.0
const M_AFFENHOF := 228.0
const M_TREPPE := 288.0
const M_ENDE := 344.0

# --------------------------------------------------------------- Höhen
const RUINENGRUND := -9.0
const ABSTURZ := -5.0
## Höhe, in der ein Sturz noch keiner ist: Die Drehscheiben im Säulengang
## liegen alle auf Weghöhe, damit der Sprung waagerecht bleibt.
const SCHEIBE_HOEHE := 0.0
## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
const KRIECHHOEHE := 0.95

# ------------------------------------------------------------ Leitfarben
# Gemessen: `#41364F` (Sturmstein) gegen `#6E44B7` (Violett) und `#953720`
# (Fackelfeuer). Die Steinwerte sind hier aufgehellt – `albedo_color`
# MULTIPLIZIERT die Textur, der gemessene Ton ergäbe einen schwarzen
# Klumpen, und auf etwas, das aussieht wie ein Loch, springt niemand.
## Nasses blaugraues Steinwerk.
const STURMSTEIN := Color(0.74, 0.70, 0.86)
const STURMSTEIN_DUNKEL := Color(0.52, 0.49, 0.63)
## Nasses Moos in den Fugen.
const NASSMOOS := Color(0.46, 0.62, 0.58)
## Fackelfeuer – die einzige warme Farbe im Bild.
const FEUER := Color(1.0, 0.47, 0.15)
## Violette Akzente: Zierbänder, Scheibenmarken, ferne Blitzsäume.
const VIOLETT := Color(0.43, 0.27, 0.72)
const VIOLETT_HELL := Color(0.88, 0.77, 0.89)
## Gewitterhimmel als ferne Silhouette.
const HORIZONT_NAH := Color(0.12, 0.11, 0.17)
const HORIZONT_FERN := Color(0.26, 0.24, 0.34)


## Der Weg. Zwei Lücken: der Säulengang und die Kippterrasse.
const STRECKE := [
	# --- Torhof: der weite, feste Auftakt ---
	{"von": 0.0, "bis": 48.0, "breite": 15.0, "breite_ende": 11.0},
	{"von": 48.0, "bis": 58.0, "breite": 10.0},
	# --- Säulengang: 58–100 ist Luft, dort tragen nur die Scheiben ---
	{"von": 100.0, "bis": 168.0, "breite": 9.5},
	{"von": 168.0, "bis": 178.0, "breite": 9.5},
	# --- Kippterrasse: 178–200 ist Luft, dort tragen nur die Platten ---
	{"von": 200.0, "bis": 228.0, "breite": 10.0},
	# --- Affenhof: der zweite weite Platz ---
	{"von": 228.0, "bis": 288.0, "breite": 13.0},
	# --- Sturmtreppe ---
	{"von": 288.0, "bis": 344.0, "breite": 10.0, "breite_ende": 14.0},
]

## Die Ruinenmauern rechts und links. Sie tragen keine Kollision – dafür
## läuft dahinter eine glatte Leitwand.
const MAUERN := [
	{"von": -6.0, "bis": 48.0, "abstand": 9.0, "hoehe": 7.0},
	{"von": 100.0, "bis": 168.0, "abstand": 6.5, "hoehe": 9.5},
	{"von": 200.0, "bis": 228.0, "abstand": 7.0, "hoehe": 8.0},
	{"von": 288.0, "bis": 348.0, "abstand": 8.5, "hoehe": 6.5},
]

# ------------------------------------------------------------ Der Blitz
## Kürzeste und längste Pause zwischen zwei Entladungen.
const BLITZ_PAUSE_KURZ := 4.0
const BLITZ_PAUSE_LANG := 11.0
## Dauer einer Entladung. Bewusst sehr kurz – ein Blitz, der eine Sekunde
## steht, ist eine Lampe.
const BLITZ_DAUER := 0.22
## Faktor, um den Sonne und Umgebungslicht dabei hochgehen.
const BLITZ_STAERKE := 7.0

var _sonne: DirectionalLight3D
var _umgebung: Environment
var _sonne_ruhe := 1.0
var _licht_ruhe := 1.0
var _blitz_zeit := 3.0
var _blitz_rest := 0.0


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Die Ruine wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Grund unter der Ruine", "tun": _grund_bauen},
		{"text": "Steinplatten und Fugen", "tun": _boden_bauen},
		{"text": "Ruinenmauern", "tun": _mauern_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Gewitterhorizont", "tun": _horizont_bauen},
		{"text": "Torhof", "tun": _torhof_bauen},
		{"text": "Säulengang", "tun": _saeulengang_bauen},
		{"text": "Götzengang", "tun": _goetzengang_bauen},
		{"text": "Kippterrasse", "tun": _kippterrasse_bauen},
		{"text": "Affenhof", "tun": _affenhof_bauen},
		{"text": "Sturmtreppe", "tun": _sturmtreppe_bauen},
		{"text": "Fackeln werden entzündet", "tun": _fackeln_setzen},
		{"text": "Regen und Dunst", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Verwitterung", "tun": _deko_bauen},
	]


# =========================================================== Verlauf

## Ein weiter Bogen nach links, der über die Strecke um zehn Meter
## ansteigt. Die Steigung ist Absicht: Am Ende sieht man über die ganze
## Ruine zurück, und im Blitz sieht man sie ganz.
##
## Der Bogen führt nie an sich selbst vorbei. Bei einem Level, das zur
## Hälfte aus Sprüngen über Abgründe besteht, wäre eine zweite Wegschicht
## unter dem Spieler das Schlimmste, was passieren kann: Man fiele, und
## nichts geschähe.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 8),
		Vector3(-4, 0, -16),
		Vector3(-14, 0.4, -38),        # Torhof
		Vector3(-30, 0.8, -56),
		Vector3(-52, 1.2, -66),        # Säulengang
		Vector3(-76, 1.6, -68),
		Vector3(-100, 2.2, -62),       # Götzengang
		Vector3(-120, 3.0, -48),
		Vector3(-134, 3.8, -28),       # Kippterrasse
		Vector3(-142, 4.6, -6),
		Vector3(-144, 5.6, 18),        # Affenhof
		Vector3(-140, 6.6, 42),
		Vector3(-130, 7.6, 64),        # Sturmtreppe
		Vector3(-114, 8.6, 82),
		Vector3(-94, 9.4, 94),
		Vector3(-72, 10.0, 100),
	])


# =========================================================== Grund

## Nasses Steinwerk. Die Kante bekommt Moos, die Klippe darunter den
## dunkleren Bruchstein: Man soll auf einen Blick sehen, wo die Platte
## aufhört und der Abgrund anfängt.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _steinstoff(STURMSTEIN),
		"kante": _moosstoff(),
		"klippe": _steinstoff(STURMSTEIN_DUNKEL),
	}, {"tiefe": 4.5, "schritt": 1.0, "kante_hoehe": 0.28, "kante_breite": 0.75})
	# Die Pfosten an den Abbruchkanten im hellen Violett: Nachts im Regen
	# ist der dunkle Ton nicht mehr von der Wand zu unterscheiden, und eine
	# Kante, die man nicht sieht, ist keine Markierung.
	luecken_markieren(VIOLETT_HELL)


func _steinstoff(farbe: Color) -> StandardMaterial3D:
	var m := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	# Nass: Ruinen im Gewitter spiegeln. Ohne das sieht der Stein aus wie
	# Beton bei Tag, und der ganze Regen im Bild wäre folgenlos.
	m.roughness = 0.42
	m.metallic_specular = 0.65
	return m


func _moosstoff() -> StandardMaterial3D:
	var m := Materialbibliothek.moos().duplicate() as StandardMaterial3D
	m.albedo_color = NASSMOOS
	m.roughness = 0.55
	return m


## Der Grund tief unter der Ruine. Nicht erreichbar, aber sichtbar: Ohne
## ihn wären die Lücken schwarze Flächen, und über schwarze Flächen springt
## niemand gern.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(400.0, 400.0)
	var mi := MeshInstance3D.new()
	mi.name = "Ruinengrund"
	mi.mesh = flaeche
	mi.material_override = _steinstoff(STURMSTEIN_DUNKEL.darkened(0.4))
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0, RUINENGRUND)
	geometrie.add_child(mi)


## Die Ruinenmauern. Steinquader mit violetten Adern und einer moosigen
## Krone – dasselbe Bauteil wie die Schluchtwände der Naturlevel, nur in
## der Palette dieses Levels.
func _mauern_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, MAUERN,
			_steinstoff(STURMSTEIN), {
		"schritt": 2.4, "lagen": 4, "block": 3.0,
		"sockel": 10.0, "saat": 1904,
		"adermaterial": _steinstoff(VIOLETT),
		"deckmaterial": _moosstoff(),
		"aderdichte": 0.22,
	})
	# Die Sichtmauer ist ein Netz aus Blöcken und taugt nicht als
	# Begrenzung – an ihren Kanten bliebe man hängen. Dahinter läuft eine
	# glatte Leitwand.
	for m in MAUERN:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(m["von"], 0.0),
				minf(m["bis"], M_ENDE), m["abstand"] - 0.4, 5.0)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


func _horizont_bauen() -> void:
	horizont(240.0, 36.0, HORIZONT_NAH, HORIZONT_FERN, false, RUINENGRUND - 1.0)


# =========================================================== Abschnitte

## 0–48 · Torhof. EINE Frage: Was macht eine Drehscheibe mit dir?
##
## Deshalb steht sie hier auf festem Boden, groß, langsam und allein. Wer
## herunterfällt, steht wieder auf der Platte und kann es noch einmal
## versuchen. Eine Scheibe über dem Abgrund als erste Begegnung wäre eine
## Prüfung vor der Lektion.
func _torhof_bauen() -> void:
	# Groß und gemächlich: Man soll sehen, DASS sie sich dreht, und Zeit
	# haben, es zu glauben.
	_scheibe(20.0, 0.0, 0.15, 5.0, 22.0)

	# Die zweite dreht andersherum und hält alle 90 Grad an – daran lernt
	# man, dass eine Scheibe ein Taktgeber sein kann und nicht nur ein
	# Karussell.
	_scheibe(36.0, 0.0, 0.15, 4.4, 34.0, -1, 90.0, 0.9)

	LevelWerkzeuge.torbogen(deko, verlauf, 8.0, 13.0,
			_steinstoff(STURMSTEIN), 13, -0.2)
	LevelWerkzeuge.torbogen(deko, verlauf, 45.0, 10.5,
			_steinstoff(STURMSTEIN), 13, -0.2)


## Drehscheibe in der Palette dieses Levels.
##
## Die Bauhilfe `drehscheibe()` in `korridor_level.gd` kennt weder Farbe
## noch Säulenhöhe, und beides lässt sich NICHT nachträglich setzen: Eine
## `Drehplattform` baut ihre Optik in `_ready()`, also im Moment des
## `add_child()`. Was danach kommt, kommt zu spät. Deshalb hier von Hand,
## mit allen Werten VOR dem Einhängen.
func _scheibe(strecke: float, seitlich: float, hoehe: float,
		durchmesser := 4.2, tempo := 30.0, richtung := 1,
		pausiert_bei := 0.0, pausenzeit := 0.0, saeule := 1.6,
		kippt := false, kipp_winkel := 12.0) -> Drehplattform:
	var d := DREHPLATTFORM.instantiate() as Drehplattform
	d.groesse = Vector2(durchmesser, durchmesser)
	d.tempo = tempo
	d.richtung = richtung
	d.pausiert_bei = pausiert_bei
	d.pausenzeit = pausenzeit
	d.kippt = kippt
	d.kipp_winkel = kipp_winkel
	d.saeule = saeule
	d.steinfarbe = STURMSTEIN
	d.markenfarbe = VIOLETT
	# `hoehe` ist die Trittfläche; der Ursprung liegt in der Mitte des Decks.
	#
	# Gesetzt wird `position` und NICHT `ort`: `Drehplattform._ready()`
	# übernimmt `ort` aus der Position, wenn `ort` noch auf Null steht – und
	# nur so steht der Knoten schon im Moment des `add_child()` an seinem
	# Platz. Setzt man `ort` direkt, bleibt die lokale Transformation bis
	# zum ersten Physikbild auf Null: `sync_to_physics` reicht ein
	# Schreiben auf `transform` erst über den Physikserver weiter. Ein
	# Gegner, der in diesem Moment aufgesetzt wird, merkt sich dann eine
	# Startposition nahe dem Weltnullpunkt und hängt für den Rest des
	# Levels sechs Meter unter der Scheibe.
	d.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
			hoehe - Drehplattform.DECK_STAERKE * 0.5)
	objekte.add_child(d)
	return d


## 48–110 · Säulengang. EINE Frage: Und wenn darunter nichts ist?
##
## Von 58 bis 100 gibt es keinen Boden – nur fünf Scheiben auf Säulen.
## Gemessen: Die Mitten liegen 7,4 m auseinander, die Scheiben sind 4,2 m
## breit, zwischen zwei Rändern liegen also 3,2 m Luft. Ein Normalsprung
## trägt bei 8,5 m/s rund 5,5 m weit – die Weite ist NICHT das Problem.
## Das Problem ist, dass die Absprungkante wegdreht, während man zielt.
##
## Deshalb drehen benachbarte Scheiben gegenläufig: Wer den Takt einer
## Scheibe gelernt hat, muss ihn auf der nächsten neu lernen. Und die
## mittlere hält an – sie ist die Verschnaufstelle, ohne die die Reihe
## eine Geduldsprobe wäre.
func _saeulengang_bauen() -> void:
	var stellen := [63.0, 70.4, 77.8, 85.2, 92.6]
	var seiten := [0.0, -1.4, 1.4, -1.2, 0.0]
	for i in stellen.size():
		var haelt := i == 2
		# Lange Säulen: Sie machen die Tiefe sichtbar. Ohne sie schwebten
		# fünf Steinteller im Nichts.
		_scheibe(stellen[i], seiten[i], SCHEIBE_HOEHE, 4.2,
				30.0 + float(i) * 4.0, 1 if i % 2 == 0 else -1,
				90.0 if haelt else 0.0, 1.1 if haelt else 0.0, 6.5)


## 110–168 · Götzengang. EINE Frage: Kannst du einen Takt lesen, statt zu
## rennen?
##
## Steinerne Köpfe in den Mauern speien Feuer quer über den Gang. Drei
## davon stehen fest, zwei schwenken. Ein schwenkender Kopf ist etwas
## anderes als ein fester: Bei einem festen wartet man auf die Pause, bei
## einem schwenkenden auf die Stelle.
##
## HIER BRICHT DAS LEVEL SEINE REGEL. Bei 150 m zweigt eine Nische ab, und
## davor steht ein Kopf, dessen Flamme genau hineinreicht – so sieht es
## aus. Tatsächlich ist dieser eine Kopf ausgebrannt: Er hat `laenge` fast
## null und speit nie. Wer sich das traut, holt sich das Extraleben.
func _goetzengang_bauen() -> void:
	# Feste Köpfe, wechselnde Seiten, versetzte Phase: Zwischen zwei
	# Flammen ist immer genau ein Fenster offen.
	feuerspeier(118.0, -3.6, 1.1, 0.0, 3.4, 0.0)
	feuerspeier(126.0, 3.6, 1.1, 180.0, 3.4, 0.5)
	feuerspeier(134.0, -3.6, 1.1, 0.0, 3.4, 0.25)
	# Zwei schwenkende – der Götzenkopf, der den Kopf dreht.
	feuerspeier(142.0, 3.6, 1.2, 180.0, 4.0, 0.0, true)
	feuerspeier(162.0, -3.6, 1.2, 0.0, 4.0, 0.4, true)

	# Ein Sturzbalken, unter dem nur die flache Kapsel durchkommt. Er
	# liegt zwischen zwei Flammen: Krabbeln kostet Zeit, und die Zeit hat
	# man nur, wenn man den Takt gelesen hat.
	stachelbalken(154.0, 0.0, KRIECHHOEHE, Vector2(7.0, 1.2))

	# --- Der Regelbruch: die Nische mit dem ausgebrannten Kopf ---
	var stein := _steinstoff(STURMSTEIN)
	plattform(150.0, 7.2, 0.0, Vector3(5.0, 0.6, 4.0), stein)
	plattform(150.0, 4.6, 0.0, Vector3(2.6, 0.6, 2.6), stein)
	# Genau EINMAL im Level bricht die Regel; ein zweites Mal wäre keine
	# Ausnahme mehr, sondern Willkür.
	# Der Kopf sieht aus wie die anderen: dieselbe Düse, dieselbe Glut in
	# der Mündung, die vor jedem Stoß anschwillt. Nur seine `laenge` ist
	# null – es kommt nie eine Flamme. Wer das Glühen sieht und trotzdem
	# geht, gewinnt.
	feuerspeier(150.0, 3.0, 1.1, 90.0, 0.0, 0.0)


## 168–228 · Kippterrasse. EINE Frage: Und wenn der Boden nur kurz trägt?
##
## Von 178 bis 200 ist Luft. Darüber liegen sechs Bruchplatten, die nach
## kurzer Warnzeit wegkippen und erst nach ein paar Sekunden wiederkommen.
## In der Mitte steht eine taumelnde Drehscheibe als feste Insel – sie ist
## die einzige Stelle, an der man kurz stehen bleiben darf, und selbst die
## steht nicht still.
##
## Die Platten wackeln vor dem Bruch. Diese Vorwarnung ist erlernbar, weil
## `Bruchplatte.saat` aus der Strecke kommt: Dieselbe Platte wackelt bei
## jedem Anlauf gleich.
func _kippterrasse_bauen() -> void:
	bruchplatten_reihe(181.0, 187.5, 3, -1.2, -0.1, Vector2(2.8, 2.8))
	bruchplatten_reihe(193.0, 198.5, 3, 1.2, -0.1, Vector2(2.8, 2.8))

	# Die Insel in der Mitte – taumelnd, aber nicht drehend: Wer hier
	# ankommt, soll verschnaufen können, ohne dass ihm die Kante wegläuft.
	_scheibe(190.5, 0.0, SCHEIBE_HOEHE, 4.6, 9.0, 1, 0.0, 0.0, 6.0, true, 9.0)

	# Auf dem festen Stück davor eine Scheibe, die man NICHT braucht: Sie
	# trägt eine Kiste und ist der Übungsplatz für die Reihe dahinter.
	_scheibe(172.0, 2.6, 0.15, 3.6, 40.0, -1, 0.0, 0.0, 1.4)

	# Und hinter der Lücke ein Feuerspeier, der genau auf die Landeplatte
	# zielt: Der letzte Sprung will getimt sein, nicht nur getroffen.
	feuerspeier(203.0, -4.0, 1.1, 0.0, 3.6, 0.35)


## 228–288 · Affenhof. EINE Frage: Und wenn der Boden UND der Gegner sich
## bewegen?
##
## Das ist der Kern des Vorbilds. Auf drei Scheiben steht je ein Gegner.
## Alle drei sind auf unterschiedliche Weise zu besiegen – Panzerkäfer nur
## von oben, Kröte nur mit dem Drehschlag, Spinne nur mit dem Slide –,
## und man muss die Antwort finden, während sich der Boden dreht.
##
## Der Hof ist bewusst FEST: Hier gibt es keinen Abgrund. Zwei bewegte
## Dinge zugleich und ein Loch darunter wären drei.
func _affenhof_bauen() -> void:
	_gegnerscheibe(238.0, -2.6, 4.4, 26.0, 1, PANZERKAEFER)
	_gegnerscheibe(254.0, 2.8, 4.4, 32.0, -1, SUMPFKROETE)
	_gegnerscheibe(270.0, -2.4, 4.8, 22.0, 1, STELZENSPINNE)

	# Die beiden Werfer am Rand bringen ihr Podest selbst mit
	# (`Werfer.mit_podest`), sie brauchen keins gebaut.

	# Ein gefallener Türsturz quer über den Hof: Deckung gegen die Würfe,
	# aber nur, wenn man sich duckt.
	stachelbalken(262.0, 0.0, KRIECHHOEHE, Vector2(8.0, 1.2))


## Eine Drehscheibe mit einem Gegner darauf.
##
## `Drehplattform.aufsetzen()` hängt ihn als Kind ein; Kinder erben die
## Transformation und drehen von selbst mit. Wichtig dabei:
## `patrouille_weite = 0.0`. Ein `Gegner` merkt sich in `_ready()` seinen
## Startpunkt in WELTkoordinaten – auf einer drehenden Scheibe wandert der
## fort, seine Patrouille aber nicht, und er liefe schräg über den Rand.
## Bewegung liefert hier die Scheibe selbst; ein stehender Gegner auf ihr
## bewegt sich für den Spieler ohnehin.
func _gegnerscheibe(strecke: float, seitlich: float, durchmesser: float,
		tempo: float, richtung: int, szene: PackedScene) -> Drehplattform:
	var scheibe := _scheibe(strecke, seitlich, 0.15, durchmesser, tempo,
			richtung)
	var g := szene.instantiate() as Gegner
	g.patrouille_weite = 0.0
	# Nicht in die Mitte: Am Rand legt der Gegner den längsten Weg zurück,
	# und erst dann sieht man, dass ihn die Scheibe trägt.
	scheibe.aufsetzen(g, durchmesser * 0.22, 0.0)
	return scheibe


## 288–344 · Sturmtreppe. EINE Frage: Alles zusammen, und dabei aufwärts.
##
## Der Weg staffelt sich in Absätzen nach oben. Von der obersten Stufe
## sieht man über die ganze Ruine zurück – im Blitz für einen Moment
## vollständig. Das ist das Erkennungsmerkmal des Vorbilds und der Grund,
## warum der Schluss steigt und nicht fällt.
func _sturmtreppe_bauen() -> void:
	var stein := _steinstoff(STURMSTEIN)

	# Drei Absätze als Treppe. Sie liegen abwechselnd links und rechts,
	# damit der Aufstieg ein Weg bleibt und keine Leiter wird.
	plattform(296.0, -2.8, 1.0, Vector3(4.0, 0.7, 4.0), stein)
	plattform(304.0, 2.8, 2.2, Vector3(4.0, 0.7, 4.0), stein)
	plattform(312.0, -2.6, 3.4, Vector3(4.0, 0.7, 4.0), stein)
	# Der Absatz ganz oben ist breit: Von hier sieht man zurück.
	plattform(322.0, 0.0, 4.4, Vector3(7.0, 0.8, 5.0), stein)

	# Zwischen den Absätzen zwei Bruchplatten – der Aufstieg darf nicht
	# zum Spaziergang werden.
	bruchplatte(300.0, 0.0, 1.6, Vector2(2.6, 2.6))
	bruchplatte(308.0, 0.0, 2.8, Vector2(2.6, 2.6))

	# Eine letzte Scheibe auf halber Höhe, diesmal schnell.
	_scheibe(316.0, 2.4, 3.9, 3.8, 46.0, -1, 0.0, 0.0, 3.4)

	# Und ein Kopf, der den obersten Absatz bestreicht. Er sitzt auf einer
	# Konsole – ein Götzenkopf, der frei in der Luft hinge, sähe aus wie
	# ein Fehler.
	plattform(326.0, -5.6, 4.6, Vector3(1.8, 0.9, 1.8), stein)
	feuerspeier(326.0, -4.8, 5.3, 0.0, 4.2, 0.0, true)

	# Das große Tor am Ende des Aufstiegs.
	LevelWerkzeuge.torbogen(deko, verlauf, 336.0, 12.0, stein, 15, -0.2)


## Fackeln säumen den Weg – die einzige warme Farbe im Bild und zugleich
## die Wegmarkierung. Reine Optik ohne Kollision: Eine Fackel, an der man
## hängen bleibt, ist ein Ärgernis, kein Schmuck.
func _fackeln_setzen() -> void:
	var stellen := [12.0, 30.0, 44.0, 104.0, 122.0, 140.0, 158.0, 172.0,
			206.0, 222.0, 240.0, 258.0, 276.0, 298.0, 318.0, 334.0]
	for i in stellen.size():
		var s: float = stellen[i]
		var rand := rand_bei(s, 0.6)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		_fackel(s, seite * rand, i)


func _fackel(strecke: float, seitlich: float, nummer: int) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Fackel%d" % nummer
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var saeule := MeshInstance3D.new()
	var stab := CylinderMesh.new()
	stab.top_radius = 0.14
	stab.bottom_radius = 0.19
	stab.height = 2.2
	stab.radial_segments = 6
	saeule.mesh = stab
	saeule.material_override = _steinstoff(STURMSTEIN_DUNKEL)
	saeule.position.y = 1.1
	gruppe.add_child(saeule)

	var schale := MeshInstance3D.new()
	var glut := SphereMesh.new()
	glut.radius = 0.3
	glut.height = 0.5
	glut.radial_segments = 8
	glut.rings = 5
	schale.mesh = glut
	schale.material_override = Materialbibliothek.leuchtend(FEUER, 2.4)
	schale.position.y = 2.35
	gruppe.add_child(schale)

	var licht := OmniLight3D.new()
	licht.light_color = FEUER
	licht.light_energy = 2.6
	licht.omni_range = 11.0
	licht.shadow_enabled = false
	licht.position.y = 2.5
	gruppe.add_child(licht)


## Nacht, Regen und Dunst. Über den beiden Lücken steht der Dunst höher –
## dort soll man die Tiefe ahnen und nicht ausmessen können.
func _stimmungen_setzen() -> void:
	stimmung(M_SAEULEN, M_GOETZEN, Color(0.16, 0.15, 0.24), 0.018, 0.65,
			Color(0.22, 0.20, 0.32), 46.0)
	stimmung(M_TERRASSE, M_AFFENHOF, Color(0.16, 0.15, 0.24), 0.018, 0.65,
			Color(0.22, 0.20, 0.32), 46.0)
	stimmung(M_TREPPE, M_ENDE, Color(0.22, 0.20, 0.30), 0.018, 0.85,
			Color(0.30, 0.27, 0.40), 50.0)


# =========================================================== Der Blitz

## Sucht Sonne und Umgebung, sobald das Level steht.
##
## Der Blitz ist kein eigenes Bauteil geworden, weil er keins sein muss:
## Er ist die Stimmung genau dieses Levels. Ein `Gewitter`-Prop mit
## Exportwerten wäre mehr Verwaltung als Wirkung.
func _nach_aufbau() -> void:
	_sonne = get_node_or_null("Sonne") as DirectionalLight3D
	var welt := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if welt != null:
		_umgebung = welt.environment
	if _sonne != null:
		_sonne_ruhe = _sonne.light_energy
	if _umgebung != null:
		_licht_ruhe = _umgebung.ambient_light_energy
	_blitz_zeit = randf_range(BLITZ_PAUSE_KURZ, BLITZ_PAUSE_LANG)


func _process(delta: float) -> void:
	if _sonne == null and _umgebung == null:
		return
	if _blitz_rest > 0.0:
		_blitz_rest -= delta
		if _blitz_rest <= 0.0:
			_licht_setzen(1.0)
		return
	_blitz_zeit -= delta
	if _blitz_zeit > 0.0:
		return
	_blitz_zeit = randf_range(BLITZ_PAUSE_KURZ, BLITZ_PAUSE_LANG)
	_blitz_rest = BLITZ_DAUER
	_licht_setzen(BLITZ_STAERKE)


func _licht_setzen(faktor: float) -> void:
	if _sonne != null:
		_sonne.light_energy = _sonne_ruhe * faktor
	if _umgebung != null:
		_umgebung.ambient_light_energy = _licht_ruhe * faktor


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

## Checkpoints stehen bei 4, 52, 116, 176, 240 und 304 m.
##
## Der erste Abstand ist mit 48 m kürzer als die übrigen: Direkt hinter
## dem Checkpoint bei 52 beginnt der Säulengang, der härteste Abschnitt
## des Levels. Ein Checkpoint gehört VOR die schwere Stelle, nicht
## irgendwo in ein Raster.
func _kisten_setzen() -> void:
	# ---------- Torhof ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.4)
	kiste(Kiste.Art.NORMAL, 10.0, -2.6)
	kiste(Kiste.Art.NORMAL, 10.0, 0.0)
	kiste(Kiste.Art.NORMAL, 10.0, 2.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 16.0, 3.0)
	# Auf der ersten Scheibe: Deckhöhe 0,15 plus 0,5.
	kiste(Kiste.Art.NORMAL, 20.0, 0.0, 0.65)
	kiste(Kiste.Art.SCHUTZ, 28.0, -3.0)
	kiste(Kiste.Art.NORMAL, 36.0, 0.0, 0.65)
	kiste(Kiste.Art.NORMAL, 42.0, 2.4)
	kiste(Kiste.Art.CHECKPOINT, 52.0, -2.4)
	kiste(Kiste.Art.NORMAL, 55.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 54.0, -3.8)

	# ---------- Säulengang: alles auf den Scheiben ----------
	kiste(Kiste.Art.NORMAL, 63.0, 0.0)
	kiste(Kiste.Art.NORMAL, 70.4, -1.4)
	kiste(Kiste.Art.SCHUTZ, 77.8, 1.4)
	kiste(Kiste.Art.NORMAL, 85.2, -1.2)
	kiste(Kiste.Art.NORMAL, 92.6, 0.0)

	# ---------- Götzengang ----------
	kiste(Kiste.Art.NORMAL, 104.0, -2.6)
	kiste(Kiste.Art.NORMAL, 108.0, 2.6)
	kiste(Kiste.Art.CHECKPOINT, 116.0, -2.6)
	kiste(Kiste.Art.EISEN, 122.0, 0.0)
	kiste(Kiste.Art.NORMAL, 122.0, 0.0, 1.6, true)
	kiste(Kiste.Art.NORMAL, 130.0, -2.4)
	kiste(Kiste.Art.TNT, 138.0, 0.0)
	kiste(Kiste.Art.NORMAL, 138.0, 2.4)
	kiste(Kiste.Art.NORMAL, 146.0, -2.4)
	kiste(Kiste.Art.NORMAL, 158.0, 2.4)
	kiste(Kiste.Art.NORMAL, 166.0, -2.4)
	# Der Preis des Regelbruchs, hinter dem ausgebrannten Kopf.
	kiste(Kiste.Art.LEBEN, 150.0, 7.2, 0.85)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 151.4, 7.2, 0.85)

	# ---------- Kippterrasse ----------
	kiste(Kiste.Art.NORMAL, 170.0, -2.6)
	kiste(Kiste.Art.NORMAL, 172.0, 2.6, 0.65)
	kiste(Kiste.Art.CHECKPOINT, 176.0, -2.6)
	# Auf der taumelnden Insel – der Lohn fürs Innehalten.
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 190.5, 0.0)
	kiste(Kiste.Art.NORMAL, 202.0, 2.6)
	kiste(Kiste.Art.SCHUTZ, 208.0, -2.6)
	kiste(Kiste.Art.NORMAL, 214.0, 2.6)
	kiste(Kiste.Art.NORMAL, 220.0, -2.6)
	kiste(Kiste.Art.FEDER, 226.0, 0.0)

	# ---------- Affenhof ----------
	kiste(Kiste.Art.NORMAL, 232.0, -3.4)
	kiste(Kiste.Art.NORMAL, 232.0, 0.0)
	kiste(Kiste.Art.NORMAL, 232.0, 3.4)
	kiste(Kiste.Art.CHECKPOINT, 240.0, 3.6)
	kiste(Kiste.Art.NORMAL, 244.0, 5.0)
	kiste(Kiste.Art.NORMAL, 268.0, -5.0)
	kiste(Kiste.Art.TNT, 250.0, -3.6)
	kiste(Kiste.Art.NORMAL, 258.0, 3.6)
	kiste(Kiste.Art.EISEN, 276.0, -3.6)
	kiste(Kiste.Art.NORMAL, 276.0, -3.6, 1.6, true)
	kiste(Kiste.Art.NORMAL, 284.0, 3.4)

	# ---------- Sturmtreppe ----------
	kiste(Kiste.Art.NORMAL, 291.0, 2.6)
	kiste(Kiste.Art.NORMAL, 296.0, -2.8, 1.85)
	kiste(Kiste.Art.CHECKPOINT, 304.0, 2.8, 3.05)
	kiste(Kiste.Art.NORMAL, 312.0, -2.6, 4.25)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 322.0, -1.6, 5.3)
	kiste(Kiste.Art.LEBEN, 322.0, 1.6, 5.3)
	kiste(Kiste.Art.NORMAL, 332.0, -2.4)
	kiste(Kiste.Art.NORMAL, 338.0, 2.4)


# =========================================================== Gegner

## Wenige Gegner, dafür jeder an einer Stelle, an der er etwas bedeutet.
##
## In einem Level, dessen Boden schon die Schwierigkeit ist, wäre eine
## dichte Besetzung nur Lärm. Die drei Gegner auf den Scheiben im Affenhof
## sind das Herzstück; alles andere führt darauf hin oder klingt danach aus.
func _gegner_setzen() -> void:
	# ---------- Torhof: die drei Antworten einmal zeigen ----------
	gegner(PANZERKAEFER, 14.0, -2.4, 4.0, true)
	gegner(SUMPFKROETE, 26.0, 2.4, 3.0, true)
	gegner(STELZENSPINNE, 42.0, -2.0, 3.0, true)

	# ---------- Säulengang: der Werfer auf der Kanzel ----------
	# Er steht auf festem Boden neben der Lücke und wirft in die
	# Scheibenreihe hinein.
	werfer(56.0, -3.4)

	# ---------- Götzengang: eng, deshalb wenige ----------
	gegner(SUMPFKROETE, 112.0, 0.0, 2.4, true)
	gegner(STELZENSPINNE, 132.0, 1.8, 2.4, true)
	gegner(PANZERKAEFER, 164.0, -1.8, 2.6, true)

	# ---------- Kippterrasse ----------
	gegner(STELZENSPINNE, 174.0, -2.0, 2.4, true)
	gegner(PANZERKAEFER, 210.0, 2.2, 3.0, true)
	gegner(SUMPFKROETE, 222.0, -2.2, 2.6, true)

	# ---------- Affenhof: die drei Scheibengegner stehen schon ----------
	# Dazu zwei Werfer auf den Podesten und ein Läufer dazwischen.
	werfer(246.0, 4.6)
	werfer(266.0, -4.6)
	gegner(PANZERKAEFER, 280.0, 0.0, 4.0, true)

	# ---------- Sturmtreppe ----------
	gegner(SUMPFKROETE, 292.0, 2.2, 2.6, true)
	gegner(STELZENSPINNE, 332.0, -2.2, 3.0, true)
	gegner(PANZERKAEFER, 339.0, 2.2, 3.0, true)


# =========================================================== Früchte

## Früchte führen den Blick. Über den beiden Lücken liegen sie als Bogen –
## sie zeigen die Sprungweite an, bevor man springt, und das ist bei
## Zielen, die sich drehen, wichtiger als sonst irgendwo.
func _fruechte_setzen() -> void:
	fruechte_reihe(6.0, 46.0, 13, 0.0)
	fruechte_bogen(58.0, 68.0, 5, 0.0, 2.0)
	fruechte_bogen(72.0, 83.0, 5, 0.0, 2.0)
	fruechte_bogen(87.0, 98.0, 5, 0.0, 2.0)
	fruechte_reihe(102.0, 166.0, 18, 0.0)
	fruechte_bogen(179.0, 189.0, 5, -1.2, 2.2)
	fruechte_bogen(192.0, 199.0, 4, 1.2, 2.0)
	fruechte_reihe(202.0, 226.0, 8, 0.0)
	fruechte_reihe(230.0, 286.0, 16, 0.0)
	fruechte_reihe(290.0, 340.0, 14, 0.0)


# =========================================================== Kulisse

## Verwitterung: gestürzte Säulentrommeln, Bewuchs in den Fugen und ein
## paar krumme Bäume, die aus dem Mauerwerk wachsen.
##
## Alle Bäume ohne Kollision – sie stehen in der Mauerkrone und über dem
## Abgrund, sie sollen nichts tragen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(19001)

	for i in 46:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 2 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(4.5, 9.0)
		baum.staerke = randf_range(0.5, 1.0)
		baum.saat = 19100 + i
		baum.laubfarbe = NASSMOOS.darkened(0.35)
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(10.0, 24.0), -1.0)
		deko.add_child(baum)

	# Gestürzte Säulentrommeln am Wegrand. Sie tragen Kollision, deshalb
	# bleibt das mittlere Wegdrittel frei – dort liegen die Kisten.
	for i in 26:
		var s := randf_range(4.0, M_ENDE - 6.0)
		var rand := rand_bei(s, 1.4)
		if rand < 4.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var trommel := STEIN.instantiate()
		if "saat" in trommel:
			trommel.set("saat", 19300 + i)
		if "groesse" in trommel:
			trommel.set("groesse", randf_range(0.7, 1.4))
		if "bemoost" in trommel:
			trommel.set("bemoost", true)
		trommel.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(4.0, rand), 0.0)
		trommel.rotation.y = randf() * TAU
		deko.add_child(trommel)

	# Bewuchs in den Fugen: nasses Gras an den Rändern.
	for i in 56:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.2, 1.4)), -0.05)
		horst.flaeche = Vector2(2.2, 2.2)
		horst.halm_hoehe = randf_range(0.35, 0.75)
		horst.farbe_unten = NASSMOOS.darkened(0.4)
		horst.farbe_oben = NASSMOOS
		horst.saat = 19500 + i
		deko.add_child(horst)

	# Farne aus den Ritzen. Keine Blumen: Deren Palette bringt Rosa und
	# Gelb mit, und beides verwässert das Violett, das hier die Akzentfarbe
	# ist.
	for i in 34:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.4:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.FARN if i % 2 == 0 else Kleinzeug.Art.BUSCH
		kleinzeug.eigene_farbe = true
		kleinzeug.farbe = NASSMOOS.darkened(randf_range(0.1, 0.4))
		kleinzeug.groesse = randf_range(0.4, 0.9)
		kleinzeug.saat = 19700 + i
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)
