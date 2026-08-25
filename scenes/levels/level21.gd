extends KorridorLevel
## Level 21 – "Sandgrab" (Raum 5, Vorbild 5-1)
##
## Ein ägyptisches Grab: ein gewöhnliches Laufniveau, das seine
## Schwierigkeit aus zwei Taktgebern zieht – Speerböden, die aus dem Boden
## schießen, und Türen, die sich schließen. Beide fragen dasselbe: Wann
## darf ich los? Beide sind mit demselben Werkzeug zu beantworten: warten,
## lesen, dann in einem Zug durch.
##
##     0 –  15  Sandhang       vor dem Startportal – das Rückwärtsgeheimnis
##    15 –  62  Vorhalle       jedes Bauteil einmal, ohne Strafe
##    62 – 134  Gabelung       zwei Wege: unten leicht, oben nur mit Slide-Sprung
##   134 – 198  Speergang      Speerböden im Wellentakt, dazu eine Grube
##   198 – 260  Torkammern     Zeitfenster hintereinander, eine Platte hält offen
##   260 – 318  Skarabäenhof   der offene Hof, dicht besetzt
##   318 – 356  Grabkammer     Sarkophag, letzte zwei Tore, Zielportal
##
## Warum ein Grab: Es rechtfertigt genau die drei Dinge, die das Level
## braucht – Fallen, die jemand gebaut hat (Speerböden, Tore), Wände, die
## etwas erzählen (die Muster), und einen Grund, warum es dunkel genug
## ist, dass Fackeln der Blickfang sein dürfen.
##
## Drei Entscheidungen, die das Level trägt:
##
## 1. DAS GRÜNE WEGBAND. Der Weg ist sandhell, die Wände sind Muster – in
##    einem durchweg warmen Bild verliert man die Wegkante. Ein schmales
##    grünes Band an beiden Rändern ist die einzige kühle Farbe im Level
##    und sagt auf jeden Blick, wie breit der Weg gerade ist. Es ist aus
##    echten `plattform()`-Streifen gebaut, nicht gemalt: Damit ist es
##    auch eine 6 cm hohe Schwelle, die man unter den Füßen spürt.
##
## 2. DIE GABELUNG BRICHT NICHT AB. Beide Wege laufen bei 130 wieder
##    zusammen, keiner ist schneller. Der obere ist nur mit
##    Slide-Sprung UND Doppelsprung zu erreichen (gerechnet in
##    `_gabelung_bauen`); wer ihn nimmt, bekommt die besseren Kisten, wer
##    ihn verpasst, verliert nichts als die Kisten.
##
## 3. DAS LEVEL BRICHT SEINE REGEL GENAU EINMAL. Alles läuft vorwärts –
##    außer am Start. Hinter dem Startportal liegen 15 m Weg mit sieben
##    Kisten, die nur findet, wer sich umdreht. Danach nie wieder.

const GLETSCHERKRABBE := preload("res://scenes/enemies/Gletscherkrabbe.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")


# =========================================================== Farben
#
# `Farben` kennt Wald, Moor und Eis, aber keinen Wüstensandstein. Die
# Werte hier sind aus dem Steckbrief 5-1 (doku/level-vorbilder.md)
# übernommen und bleiben lokal – eine Farbe in die Bibliothek zu
# schreiben, die nur ein Level nutzt, wäre verfrüht.

const SANDSTEIN := Color(0.61, 0.35, 0.14)          ## #9B501A
const SANDSTEIN_HELL := Color(0.80, 0.62, 0.36)
const SANDSTEIN_DUNKEL := Color(0.38, 0.20, 0.10)   ## #60200E
const GRABDUNKEL := Color(0.15, 0.07, 0.05)         ## #26120D
const OCKER := Color(0.63, 0.25, 0.09)              ## #A03F16
const FACKELLICHT := Color(0.90, 0.55, 0.21)        ## #E68D36 – der Blickfang
const SAND := Color(0.78, 0.65, 0.42)
const SAND_DUNKEL := Color(0.55, 0.43, 0.24)
## Das Erkennungsmerkmal: das grün gefasste Wegband.
const WEGBAND := Color(0.24, 0.44, 0.24)
const WEGBAND_HELL := Color(0.36, 0.58, 0.30)
## Die drei Musterfarben der bemalten Wände.
const MUSTER_ROT := Color(0.63, 0.18, 0.11)
const MUSTER_TUERKIS := Color(0.16, 0.53, 0.48)
const MUSTER_BLAU := Color(0.17, 0.29, 0.58)
## Gold für den Sarkophag – kommt sonst nirgends vor.
const GOLD := Color(0.86, 0.68, 0.24)
## Bronze statt Rost für die Speerspitzen: Ein rostbrauner Zacken
## verschwindet im ockerfarbenen Sand, ein heller Bronzeton nicht.
const BRONZE := Color(0.84, 0.66, 0.30)


# =========================================================== Marken

const M_SANDHANG := 0.0
const M_VORHALLE := 15.0
const M_GABELUNG := 62.0
const M_SPEERGANG := 134.0
const M_TORKAMMERN := 198.0
const M_HOF := 260.0
const M_GRABKAMMER := 318.0
const M_ENDE := 356.0

## Wo der Spieler aus dem Startportal tritt. Alles davor ist Geheimnis.
const START := 15.0

const ABSTURZ := -5.5

## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
## Aufrechte Kapsel 1,30 m, flache 0,76 m (wie in Level 10).
const KRIECHHOEHE := 0.95

## Trittfläche der oberen Galerie in der Gabelung. Siehe die Rechnung in
## `_gabelung_bauen()` – dieser Wert ist die ganze Gabelung.
const GALERIE := 3.6
## Seitlicher Platz der Galerie (links) bzw. des leichten Weges (rechts).
const GALERIE_QUER := -5.5
const LEICHT_QUER := 4.6

## Die elf Absätze der oberen Galerie. Als Konstante, weil außer den
## Plattformen selbst auch Kisten, Balken und Feuerspeier ihre Höhe daraus
## ziehen – von Hand nachgerechnete Höhen driften beim ersten Umbau
## auseinander, und dann schwebt die Kiste über dem Absatz.
const GALERIE_STELLEN := [70.5, 76.0, 81.5, 87.0, 92.5, 98.0, 103.5,
		109.0, 114.5, 120.0, 125.5]
## Wie stark die Galerie je Absatz ansteigt.
const GALERIE_STEIGUNG := 0.08


const STRECKE := [
	# --- Sandhang und Vorhalle: ein durchgehender Gang ---
	{"von": 0.0, "bis": 62.0, "breite": 11.0, "breite_ende": 9.5},
	# --- Gabelung: der breiteste Abschnitt, er trägt zwei Wege ---
	{"von": 62.0, "bis": 134.0, "breite": 17.0},
	# --- Speergang: eng, mit einer Grube bei 168 ---
	{"von": 134.0, "bis": 168.0, "breite": 8.5},
	{"von": 172.6, "bis": 198.0, "breite": 8.5},
	# --- Torkammern: eng, mit einer zweiten Grube bei 232 ---
	{"von": 198.0, "bis": 232.0, "breite": 9.5},
	{"von": 236.6, "bis": 260.0, "breite": 9.5},
	# --- Hof und Grabkammer ---
	{"von": 260.0, "bis": 318.0, "breite": 13.0},
	{"von": 318.0, "bis": 356.0, "breite": 11.0, "breite_ende": 14.0},
]

## Die Grabwände. Sie stehen jeweils rund einen Meter außerhalb der
## Wegkante – eng genug, dass das Muster lesbar bleibt, weit genug, dass
## niemand daran hängen bleibt.
const WAENDE := [
	{"von": -8.0, "bis": 62.0, "abstand": 6.4, "hoehe": 9.0},
	{"von": 62.0, "bis": 134.0, "abstand": 9.6, "hoehe": 12.0},
	{"von": 134.0, "bis": 198.0, "abstand": 5.3, "hoehe": 10.0},
	{"von": 198.0, "bis": 260.0, "abstand": 5.9, "hoehe": 9.5},
	{"von": 260.0, "bis": 318.0, "abstand": 7.6, "hoehe": 8.5},
	{"von": 318.0, "bis": 364.0, "abstand": 8.4, "hoehe": 13.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Das Grab wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Sandboden", "tun": _boden_bauen},
		{"text": "Grabwände", "tun": _waende_bauen},
		{"text": "Grünes Wegband", "tun": _wegband_bauen},
		{"text": "Bemalte Wände", "tun": _muster_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Dünen", "tun": _horizont_bauen},
		{"text": "Fackeln werden entzündet", "tun": _fackeln_setzen},
		{"text": "Vorhalle", "tun": _vorhalle_bauen},
		{"text": "Gabelung", "tun": _gabelung_bauen},
		{"text": "Speergang", "tun": _speergang_bauen},
		{"text": "Torkammern", "tun": _torkammern_bauen},
		{"text": "Skarabäenhof", "tun": _hof_bauen},
		{"text": "Grabkammer", "tun": _grabkammer_bauen},
		{"text": "Stimmung", "tun": _stimmungen_setzen},
		{"text": "Krüge und Scherben", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Wächter beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Ein Grab ist gebaut, kein Fluss: Die Strecke besteht deshalb aus
## geraden Gängen mit klaren Ecken, nicht aus einer weichen Schleife. Die
## Ecken liegen bewusst zwischen den Abschnitten – man sieht nie in den
## nächsten hinein und weiß dadurch beim Betreten nur, was der aktuelle
## Takt verlangt.
##
## Der Weg fällt insgesamt um sieben Meter: Es geht ins Grab hinein, nicht
## darum herum.
##
## Die große Schleife darf sich dabei NICHT selbst einholen. Der erste
## Entwurf tat genau das: Nach 340 m lag der Weg wieder sechs Meter neben
## dem Sandhang, nur sechs Meter tiefer – und weil die Grabwand einen
## neun Meter tiefen Sockel hat und die Wegklippe sieben Meter hinunter
## reicht, stand die Vorhalle mitten in der Grabkammer. Auf dem Bild sah
## man dort nichts als eine ockerfarbene Wand. Die Schleife läuft
## deshalb nach außen weiter, statt sich zu schließen; zwischen zwei
## Wegstellen liegen jetzt überall mindestens 22 m.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 1.6, 14),          # Sandhang, oben im Licht
		Vector3(0, 1.2, 0),
		Vector3(0, 0.6, -20),         # Vorhalle
		Vector3(2, 0.2, -44),
		Vector3(12, 0.0, -62),        # Gabelung, der Gang weitet sich
		Vector3(30, 0.0, -76),
		Vector3(52, 0.0, -84),
		Vector3(74, -0.2, -80),
		Vector3(90, -0.6, -66),       # Speergang, es geht hinunter
		Vector3(98, -1.2, -46),
		Vector3(100, -1.8, -24),
		Vector3(94, -2.4, -4),        # Torkammern
		Vector3(80, -2.8, 12),
		Vector3(62, -3.2, 24),
		Vector3(42, -3.6, 32),        # Skarabäenhof
		Vector3(22, -4.0, 42),
		Vector3(2, -4.6, 50),
		Vector3(-20, -5.2, 54),       # Grabkammer, die tiefste Stelle
		Vector3(-42, -5.8, 50),
	])


# =========================================================== Grund

## Sandstein aus Rauschen statt aus einer Vollfarbe.
##
## Eine glatte Fläche in Ocker liest sich als Papier, nicht als Stein –
## und weil das halbe Level aus warmem Sandton besteht, fiele der
## Unterschied zwischen Boden, Wand und Sarkophag ganz weg. Das Rauschen
## gibt jeder Fläche Korn, die Normalmap die Kanten.
func _stein_stoff(saat: int, dunkel: Color, hell: Color,
		frequenz := 0.035, rauheit := 0.92) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(saat, frequenz,
			dunkel, hell)
	m.normal_enabled = true
	m.normal_texture = Materialbibliothek.normalmap(saat, frequenz * 1.6, 1.4)
	m.normal_scale = 0.8
	m.roughness = rauheit
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.18, 0.18, 0.18)
	return m


func _sandboden() -> StandardMaterial3D:
	return _stein_stoff(2101, SAND_DUNKEL, SAND, 0.05, 0.98)


func _mauerwerk() -> StandardMaterial3D:
	return _stein_stoff(2102, SANDSTEIN_DUNKEL, SANDSTEIN_HELL, 0.028)


func _kantenstein() -> StandardMaterial3D:
	return _stein_stoff(2103, OCKER.darkened(0.35), OCKER.lightened(0.15), 0.06)


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _sandboden(),
		"kante": _kantenstein(),
		"klippe": _mauerwerk(),
	}, {"tiefe": 7.0, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.8})
	luecken_markieren(SANDSTEIN_DUNKEL)


## Die Grabwände. Drei Lagen wie in Level 02: warmer Grundstein, hellere
## Bänder aus geschliffenem Kalkstein, oben eine Deckschicht aus
## Flugsand. Ohne die Bänder wird eine Wand aus lauter Sandtönen zur
## Tapete – der Blick findet dann keine Tiefe mehr.
func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE, _mauerwerk(), {
		"schritt": 2.2, "lagen": 6, "block": 2.4,
		"sockel": 9.0, "saat": 2110,
		"adermaterial": _stein_stoff(2104, SANDSTEIN, SANDSTEIN_HELL, 0.02),
		"deckmaterial": _stein_stoff(2105, SAND_DUNKEL, SAND, 0.04),
		"aderdichte": 0.22,
	})
	# Hinter der zerklüfteten Sichtwand eine glatte Leitwand, an der man
	# nicht hängen bleibt. Sie hält den Spieler im Gang – herunterfallen
	# soll man nur in die beiden Gruben.
	for w in WAENDE:
		var von: float = maxf(w["von"], 0.0)
		var bis: float = minf(w["bis"], M_ENDE)
		var abstand: float = w["abstand"]
		LevelWerkzeuge.leitwand(geometrie, verlauf, von, bis, abstand - 0.5, 6.0)
	# Sandbank zwischen Wegkante und Wandfuß: ohne sie klafft dort eine Fuge.
	var baenke: Array = []
	for w in WAENDE:
		var abstand: float = w["abstand"]
		baenke.append({
			"von": maxf(w["von"], -4.0), "bis": minf(w["bis"], M_ENDE),
			"innen": abstand - 2.0, "aussen": abstand + 0.8,
			"hoehe": -0.06,
		})
	LevelWerkzeuge.sims(geometrie, verlauf, baenke, _sandboden())


## Das grüne Wegband – das Erkennungsmerkmal des Vorbilds.
##
## Zwei schmale Streifen dicht an der inneren Wegkante, aus echten
## Plattformen. Sie folgen der Breite des Weges: Wo er sich weitet,
## rücken sie mit nach außen, wo er sich verengt, mit nach innen. Damit
## ist das Band nicht nur Zierde, sondern die Ablesehilfe für die
## Wegbreite – in einem Bild, das sonst durchweg sandfarben ist, die
## einzige kühle Linie.
##
## In Stücken von sechs Metern, weil ein gerader Quader einem gebogenen
## Gang nicht folgt.
func _wegband_bauen() -> void:
	const SCHRITT := 6.0
	const STUECK := 5.7
	var band := Materialbibliothek.einfarbig(WEGBAND, 0.85)
	var band_hell := Materialbibliothek.einfarbig(WEGBAND_HELL, 0.8)
	var s := 1.0
	var i := 0
	while s < M_ENDE - 1.0:
		var breite := breite_bei(s)
		if breite > 2.0:
			# 1,15 m von der Wegmitte aus gerechnet nach innen: genau
			# hinter die Steinkante, die `korridor()` mit 0,8 m Breite
			# aufsetzt.
			var quer := breite * 0.5 - 1.15
			# Jeder dritte Streifen heller: Ein durchgehend gleichfarbiges
			# Band wirkt gedruckt, ein leicht wechselndes wie gelegt.
			var stoff: Material = band_hell if i % 3 == 0 else band
			for seite: float in [-1.0, 1.0]:
				plattform(s + STUECK * 0.5, seite * quer, 0.0,
						Vector3(0.55, 0.12, STUECK), stoff)
		s += SCHRITT
		i += 1


# =========================================================== Muster

## Bemalte Wände: das zweite Erkennungsmerkmal.
##
## Die Formen selbst sind schlichte Kästen – genau wie im Vorbild, wo die
## Bauten Kisten sind und die Muster das ganze Design tragen. Gesetzt
## werden sie als Bänder aus kleinen Quadern an der Innenseite beider
## Wände, in drei Farben auf Sandton.
##
## ALLES in EINEM Netz je Farbe. Ein Feld hat rund ein Dutzend Quader,
## und es gibt an die neunzig Felder – einzeln gesetzt wären das über
## tausend Knoten und ebenso viele Zeichenaufrufe. Drei verschmolzene
## Netze kosten drei.
func _muster_bauen() -> void:
	var toepfe := {
		MUSTER_ROT: PropWerkzeug.bauer(),
		MUSTER_TUERKIS: PropWerkzeug.bauer(),
		MUSTER_BLAU: PropWerkzeug.bauer(),
	}
	var farben: Array[Color] = [MUSTER_ROT, MUSTER_TUERKIS, MUSTER_BLAU]
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 2120

	var s := 4.0
	while s < M_ENDE - 2.0:
		var abstand := _wandabstand(s)
		if abstand > 0.0:
			for seite: float in [-1.0, 1.0]:
				_musterfeld(toepfe, farben, wuerfel, s, seite, abstand)
		s += 7.5

	for farbe: Color in farben:
		var st: SurfaceTool = toepfe[farbe]
		var knoten := PropWerkzeug.mesh_knoten("Muster_" + farbe.to_html(false),
				PropWerkzeug.fertig(st),
				Materialbibliothek.einfarbig(farbe, 0.75), false)
		if knoten != null:
			deko.add_child(knoten)


## Wandabstand an dieser Stelle, 0 wenn dort keine Wand steht.
func _wandabstand(strecke: float) -> float:
	for w in WAENDE:
		var von: float = w["von"]
		var bis: float = w["bis"]
		if strecke >= von and strecke <= bis:
			return w["abstand"]
	return 0.0


## Ein einzelnes bemaltes Feld an der Wand.
##
## Aufbau von unten nach oben: ein durchgehendes Sockelband, darüber vier
## bis sechs Zeilen aus zwei bis vier Zeichen, oben ein Abschlussband.
## Die Zeichen sind bewusst rechteckig und unterschiedlich breit – erst
## die ungleichen Breiten machen aus einem Raster eine Schrift.
func _musterfeld(toepfe: Dictionary, farben: Array[Color],
		wuerfel: RandomNumberGenerator, strecke: float, seite: float,
		abstand: float) -> void:
	# 12 cm vor der Wand: dahinter verschwände die Bemalung im Fels.
	var quer := seite * (abstand - 0.65)
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	var dicke := 0.09

	# Die Bänder oben und unten fassen das Feld ein.
	for hoehe: float in [0.7, 5.3]:
		var ton: Color = farben[0] if hoehe < 1.0 else farben[2]
		PropWerkzeug.anfuegen(toepfe[ton],
				PropWerkzeug.kasten(Vector3(dicke, 0.22, 5.2)),
				Transform3D(Basis(Vector3.UP, dreh),
						LevelWerkzeuge.punkt(verlauf, strecke, quer, hoehe)))

	var zeilen := wuerfel.randi_range(4, 6)
	for z in zeilen:
		var y := 1.25 + float(z) * 0.78
		if y > 5.0:
			break
		var zeichen := wuerfel.randi_range(2, 4)
		# Die Zeile mittig um die Stelle legen, sonst wandern die Felder
		# mit jeder Zufallszahl den Gang entlang.
		var laengs := strecke - 2.2
		for i in zeichen:
			var breite := wuerfel.randf_range(0.5, 1.5)
			var hoch := wuerfel.randf_range(0.28, 0.58)
			var ton: Color = farben[wuerfel.randi_range(0, farben.size() - 1)]
			laengs += breite * 0.5 + 0.16
			PropWerkzeug.anfuegen(toepfe[ton],
					PropWerkzeug.kasten(Vector3(dicke, hoch, breite)),
					Transform3D(Basis(Vector3.UP, dreh),
							LevelWerkzeuge.punkt(verlauf, laengs, quer, y)))
			laengs += breite * 0.5


# =========================================================== Licht

## Fackeln an den Wänden. Sie sind der Blickfang des ganzen Levels
## (`#E68D36` im Steckbrief) und zugleich die Wegmarke: Wo die nächste
## Fackel brennt, geht es weiter.
##
## Klein gehalten – mit weitem Schein überzöge jede Fackel den halben
## Gang mit Orange, und dann trüge keine Farbe mehr Bedeutung. Kein
## Schatten: dreißig schattenwerfende Lichter kosten mehr, als sie zeigen.
func _fackeln_setzen() -> void:
	var s := 8.0
	var i := 0
	while s < M_ENDE - 4.0:
		var abstand := _wandabstand(s)
		if abstand > 0.0:
			var seite: float = -1.0 if i % 2 == 0 else 1.0
			_fackel(s, seite * (abstand - 0.9))
		s += 11.0
		i += 1
	# In der Grabkammer stehen sie paarweise: Der Raum soll heller sein
	# als der Gang davor, damit das Ziel als Ankunft gelesen wird.
	for stelle: float in [326.0, 336.0, 346.0]:
		for seite: float in [-1.0, 1.0]:
			_fackel(stelle, seite * 6.4)


func _fackel(strecke: float, seitlich: float) -> void:
	var gruppe := Node3D.new()
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var halter := MeshInstance3D.new()
	var stab := CylinderMesh.new()
	stab.top_radius = 0.09
	stab.bottom_radius = 0.13
	stab.height = 2.1
	stab.radial_segments = 6
	halter.mesh = stab
	halter.material_override = Materialbibliothek.einfarbig(
			SANDSTEIN_DUNKEL, 0.9)
	halter.position.y = 1.05
	gruppe.add_child(halter)

	var schale := MeshInstance3D.new()
	var kelch := CylinderMesh.new()
	kelch.top_radius = 0.36
	kelch.bottom_radius = 0.18
	kelch.height = 0.3
	kelch.radial_segments = 8
	schale.mesh = kelch
	schale.material_override = Materialbibliothek.metall(BRONZE)
	schale.position.y = 2.2
	gruppe.add_child(schale)

	var flamme := MeshInstance3D.new()
	var zunge := SphereMesh.new()
	zunge.radius = 0.26
	zunge.height = 0.86
	zunge.radial_segments = 8
	zunge.rings = 5
	flamme.mesh = zunge
	flamme.material_override = Materialbibliothek.leuchtend(FACKELLICHT, 2.2)
	flamme.position.y = 2.6
	gruppe.add_child(flamme)

	var licht := OmniLight3D.new()
	licht.light_color = FACKELLICHT
	licht.light_energy = 2.6
	licht.omni_range = 8.5
	licht.shadow_enabled = false
	licht.position.y = 2.6
	gruppe.add_child(licht)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 60.0)


## Ferne Dünen. Über den Grabwänden ist Wüste zu sehen – ohne das endet
## die Welt hinter der obersten Blocklage an einer geraden Linie.
func _horizont_bauen() -> void:
	horizont(230.0, 26.0, SAND_DUNKEL, SAND.lightened(0.2), true, -9.0)


# =========================================================== Vorhalle

## 15–62 · Vorhalle. Jede der drei Fragen des Levels wird hier einmal
## gestellt, und jede ohne Strafe: Der Boden trägt überall, nebenan ist
## kein Abgrund.
##
##   Speerboden   – ein einzelnes Feld, dahinter Platz zum Stehenbleiben
##   Schließtür   – ein Tor mit langem Fenster
##   Balken       – die erste Stelle, an der gekrabbelt werden muss
func _vorhalle_bauen() -> void:
	# Der erste Speerboden liegt frei im Gang, mit Anlauf davor und
	# Auslauf dahinter. Wer ihn erst beim zweiten Anlauf liest, verliert
	# nichts.
	var erster := stacheln(28.0, 0.0, Vector2(3.4, 3.0), true, BRONZE)
	erster.takt = 2.8

	# Zwei Felder nebeneinander, versetzt getaktet: die erste Stelle, an
	# der der Takt eine Entscheidung verlangt statt nur Geduld.
	var links := stacheln(38.0, -2.0, Vector2(2.6, 3.0), true, BRONZE)
	links.takt = 2.4
	var rechts := stacheln(38.0, 2.0, Vector2(2.6, 3.0), true, BRONZE)
	rechts.takt = 2.4

	# Das erste Tor, mit weit offenem Fenster – es lehrt, wie ein Tor
	# aussieht, nicht wie schnell man sein muss.
	schliesstuer(48.0, 0.0, 4.0, 2.9, 3.0, 1.4, 0.0)

	# Und ein gestürzter Sturzbalken, unter dem nur Krabbeln durchkommt.
	stachelbalken(56.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


# =========================================================== Gabelung

## 62–134 · Die Gabelung. Zwei Wege mit eigenem Anspruch, die am selben
## Absatz wieder zusammenlaufen.
##
## RECHTS (Boden, `LEICHT_QUER`): der Weg der Diener. Er läuft ebenerdig
## durch, hat drei Speerböden und ein Tor – alles bekannt aus der
## Vorhalle, nur enger getaktet.
##
## LINKS (Galerie auf 3,6 m, `GALERIE_QUER`): der Weg der Priester. Der
## Aufstieg ist die ganze Prüfung, danach ist die Galerie bequem.
##
## WARUM 3,6 m. Gerechnet mit den Werten aus CLAUDE.md:
##   Normalsprung  12,2²/(2·38)               = 1,96 m Scheitel
##   + Doppelsprung 10,5²/(2·38) = 1,45 m     = 3,41 m Höchstpunkt
##   Slide-Sprung  14,5²/(2·38)               = 2,77 m Scheitel
##   + Doppelsprung                            = 4,22 m Höchstpunkt
## Eine Trittfläche auf 3,6 m liegt also 19 cm über dem, was Sprung und
## Doppelsprung zusammen schaffen, und 62 cm unter dem, was Slide-Sprung
## und Doppelsprung schaffen. Genau dieses Fenster ist die Gabelung.
##
## Waagerecht: In der Luft trägt `RUN_SPEED · AIR_CTRL` = 6,97 m/s. Die
## Höhe 3,6 m liegt im Fenster von 3,3 m bis 5,2 m hinter dem Absprung –
## die erste Plattform steht deshalb 4,5 m vor der Kante, mit 3,2 m
## Trittiefe. Wer richtig springt, landet mittig.
## Trittfläche des Galerie-Absatzes `i`, gemessen vom Weg aus.
func _galerie_deck(i: int) -> float:
	return GALERIE + float(i) * GALERIE_STEIGUNG


## Wie `gegner()`, aber auf einer Plattform statt auf dem Weg.
##
## `gegner()` setzt jeden Gegner auf Weghöhe – und `Gegner` friert in
## seinem `_ready()` die Starthöhe ein und zieht sich in jedem Bild
## wieder dorthin (`_start_position.y`). Ein nachträgliches Anheben wäre
## also nach einem Physikschritt wieder weg. Deshalb steht die Position
## hier VOR `add_child`.
func _gegner_hoch(szene: PackedScene, strecke: float, seitlich: float,
		hoehe: float, weite: float) -> Gegner:
	var g := szene.instantiate() as Gegner
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized()
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


func _gabelung_bauen() -> void:
	var stein := _mauerwerk()

	# --- Der Aufstieg: die einzige schwere Stelle der Gabelung ---
	# Ein Fruchtbogen zeigt die Flugbahn an. Ohne ihn wäre die Galerie
	# nicht schwer, sondern unsichtbar – und ein Weg, den man nicht sieht,
	# ist kein zweiter Weg, sondern ein Fehler.
	fruechte_bogen(66.0, 70.5, 6, GALERIE_QUER, 3.9)

	for i in GALERIE_STELLEN.size():
		var s: float = GALERIE_STELLEN[i]
		# Ganz leicht ansteigend: Die Galerie soll sichtbar irgendwohin
		# führen, statt waagerecht im Raum zu schweben.
		plattform(s, GALERIE_QUER, _galerie_deck(i) - 0.25,
				Vector3(3.0, 0.5, 3.2), stein)

	# Auf der Galerie liegt genau ein Hindernis, und es ist eins, das
	# oben mehr wehtut als unten: ein Sturzbalken über 4,5 m Luft. Wer
	# krabbelnd darunter durch will, muss vorher landen.
	stachelbalken(GALERIE_STELLEN[4], GALERIE_QUER,
			_galerie_deck(4) + KRIECHHOEHE, Vector2(3.0, 1.0))
	# Und ein Feuerstoß, der quer über die Galerie fegt.
	feuerspeier(GALERIE_STELLEN[7], GALERIE_QUER - 2.6,
			_galerie_deck(7) + 1.0, 0.0, 3.4, 0.35)

	# Abstieg zurück auf den Boden – beide Wege enden auf demselben Absatz.
	plattform(129.0, GALERIE_QUER + 1.4, 1.6, Vector3(4.0, 0.5, 3.2), stein)
	plattform(132.0, 0.0, 0.5, Vector3(9.0, 0.6, 3.4), stein)

	# --- Der leichte Weg: ebenerdig, dafür durchgetaktet ---
	for i in 3:
		var s := 74.0 + float(i) * 14.0
		var feld := stacheln(s, LEICHT_QUER, Vector2(3.2, 3.4), true, BRONZE)
		feld.takt = 2.2
	schliesstuer(104.0, LEICHT_QUER, 4.2, 2.9, 2.0, 1.6, 0.3)
	feuerspeier(118.0, LEICHT_QUER + 3.2, 1.1, 180.0, 3.4, 0.0)

	# --- Was die beiden Wege trennt ---
	# Eine Reihe umgestürzter Säulentrommeln in der Gangmitte. Sie sind
	# kniehoch und niemandes Hindernis; sie sagen nur: Hier sind es zwei
	# Wege und nicht ein breiter.
	for i in 11:
		var s := 68.0 + float(i) * 5.8
		plattform(s, -0.4, 0.3, Vector3(1.5, 0.7, 3.6), _kantenstein())


# =========================================================== Speergang

## 134–198 · Speergang. Der Abschnitt, für den der Speerboden gebaut
## wurde: acht Felder hintereinander, die als WELLE takten.
##
## Der Versatz kommt nicht von Hand, sondern aus der Strecke: `stacheln()`
## setzt `versatz = fmod(strecke, 2.0)`. Die Stellen unten sind deshalb so
## gewählt, dass ihr Rest reihum von 0,0 bis 1,75 läuft – die Welle
## entsteht dadurch aus dem Ort und ist bei jedem Anlauf dieselbe.
##
## Bei 168 klafft eine Grube: die einzige Stelle im Level, an der ein
## verpasster Sprung tödlich ist.
func _speergang_bauen() -> void:
	var stellen := [138.0, 141.75, 145.5, 149.25, 153.0, 156.75, 160.5, 164.25]
	for i in stellen.size():
		var s: float = stellen[i]
		var feld := stacheln(s, 0.0, Vector2(6.2, 2.8), true, BRONZE)
		feld.takt = 2.0

	# Zwei Feuerspeier gegeneinander: zwischen ihnen ist immer genau ein
	# Fenster offen, und es liegt nie da, wo die Speere gerade unten sind.
	feuerspeier(147.0, -3.2, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(158.0, 3.2, 1.0, 180.0, 3.2, 0.5)

	# Die Grube. Beidseits Warnbalken (setzt `luecken_markieren`), davor
	# ein kurzes freies Stück zum Anlauf nehmen.
	fruechte_bogen(167.0, 174.0, 6, 0.0, 2.2)

	# Hinter der Grube wird es enger, und der Takt zieht an.
	var eng := [176.5, 179.25, 182.0, 184.75]
	for s: float in eng:
		var feld := stacheln(s, 0.0, Vector2(6.2, 2.4), true, BRONZE)
		feld.takt = 1.7
	stachelbalken(190.0, 0.0, KRIECHHOEHE, Vector2(6.5, 1.1))
	# Eine Deckungsnische kurz vor den Torkammern: hier darf man atmen.
	deckungsfleck(195.0, -2.2, 1.6)


# =========================================================== Torkammern

## 198–260 · Torkammern. Fünf Tore hintereinander, jedes mit eigenem
## Takt. Das ist der Kern des Vorbilds: „Die Türfenster sind kurz, und
## dahinter geht es sofort weiter."
##
## Die Phasen sind so gelegt, dass ein Spieler, der ohne Halt durchläuft,
## alle fünf schafft – aber nur, wenn er beim ERSTEN richtig einsteigt.
## Wer eins verpasst, verliert den Takt und muss vor dem nächsten warten.
## Das ist Absicht: Der Fehler kostet Zeit, nicht das Leben.
##
## Bei 232 die zweite Grube, und daneben das eine Hindernis mit zwei
## Rollen: eine Auslöseplatte, die das Tor dahinter offen hält. Wer sie
## findet, geht durch, ohne zu warten.
func _torkammern_bauen() -> void:
	var tore := [204.0, 212.0, 220.0, 228.0]
	for i in tore.size():
		var s: float = tore[i]
		# 8 m Abstand, Lauftempo 8,5 m/s: knapp eine Sekunde von Tor zu
		# Tor. Bei 3,4 s Takt ist ein Viertelversatz je Tor genau die
		# Welle, die mit dem Läufer mitwandert.
		schliesstuer(s, 0.0, 3.8, 2.9, 1.9, 1.5, fmod(float(i) * 0.28, 1.0))
		if i < tore.size() - 1:
			# Zwischen den Toren steht je ein Speerboden – man kann also
			# nicht einfach im Torrahmen warten.
			var feld := stacheln(s + 4.0, 0.0, Vector2(5.0, 2.4), true, BRONZE)
			feld.takt = 2.2

	# Die Grube bei 232, davor der Anlauf.
	fruechte_bogen(231.0, 238.0, 6, 0.0, 2.2)

	# Das letzte Tor der Kammern – und die Platte, die es offen hält.
	var tor := schliesstuer(248.0, 0.0, 4.0, 2.9, 1.6, 2.0, 0.0)
	ausloeseplatte(242.0, 0.0, Vector2(2.8, 2.6), 2.2, false, [tor])
	# Damit die Platte auch als Angebot gelesen wird: Sie liegt in einer
	# Bucht seitlich der Ideallinie, mit einer Frucht darauf.
	frucht(242.0, 0.0, 1.1)

	feuerspeier(254.0, -3.0, 1.0, 0.0, 3.0, 0.2, true)


# =========================================================== Hof

## 260–318 · Skarabäenhof. Nach vier engen Abschnitten der offene Raum.
##
## Er ist mit Absicht die dichteste Gegnerstelle des Levels: Erst im
## Weiten fällt auf, wie eng die Gänge waren, und erst im Weiten sind
## mehrere Gegner gleichzeitig überhaupt lesbar. Fallen gibt es hier
## kaum – der Hof stellt die andere Frage.
func _hof_bauen() -> void:
	var stein := _mauerwerk()

	# Vier Säulenstümpfe im Hof. Sie sind Deckung, Aussichtspunkt und
	# Grund dafür, dass man nicht in gerader Linie hindurchläuft.
	var saeulen := [
		[268.0, -3.6], [278.0, 3.8], [292.0, -4.0], [304.0, 3.6],
	]
	for eintrag in saeulen:
		var s: float = eintrag[0]
		var quer: float = eintrag[1]
		plattform(s, quer, 1.1, Vector3(2.6, 2.2, 2.6), stein)
		plattform(s, quer, 2.4, Vector3(3.0, 0.4, 3.0), _kantenstein())

	# Zwei Speerböden an den Rändern – sie halten den Kampf in die Mitte.
	var links := stacheln(284.0, -5.0, Vector2(3.0, 5.0), true, BRONZE)
	links.takt = 2.6
	var rechts := stacheln(298.0, 5.0, Vector2(3.0, 5.0), true, BRONZE)
	rechts.takt = 2.6

	feuerspeier(288.0, 0.0, 1.2, 90.0, 4.0, 0.0, true)
	deckungsfleck(310.0, -3.0, 1.7)


# =========================================================== Grabkammer

## 318–356 · Grabkammer. Der Sarkophag steht in der Mitte, zwei letzte
## Tore stehen davor.
##
## Hier ist zum ersten und einzigen Mal Gold im Bild. Bis hierher war
## alles Sandstein, Ocker und Fackelorange; dass der Sarkophag anders
## aussieht als alles davor, ist der ganze Schluss.
func _grabkammer_bauen() -> void:
	# Zwei Tore kurz hintereinander, gegenphasig: Wer durch das erste
	# kommt, steht vor dem zweiten und muss noch einmal lesen.
	schliesstuer(322.0, 0.0, 4.0, 2.9, 1.7, 1.4, 0.0)
	schliesstuer(328.0, 0.0, 4.0, 2.9, 1.7, 1.4, 0.5)

	# Der Sarkophag: ein Sockel, ein Kasten, ein goldener Deckel.
	var gold := Materialbibliothek.metall(GOLD)
	plattform(340.0, 0.0, 0.35, Vector3(4.4, 0.7, 8.0), _kantenstein())
	plattform(340.0, 0.0, 1.1, Vector3(3.2, 0.8, 6.6), _mauerwerk())
	plattform(340.0, 0.0, 1.65, Vector3(3.4, 0.3, 6.8), gold)

	# Vier goldene Kanopen an den Ecken.
	for laengs: float in [336.5, 343.5]:
		for quer: float in [-3.4, 3.4]:
			var krug := MeshInstance3D.new()
			var form := CylinderMesh.new()
			form.top_radius = 0.3
			form.bottom_radius = 0.4
			form.height = 1.1
			form.radial_segments = 10
			krug.mesh = form
			krug.material_override = gold
			krug.position = LevelWerkzeuge.punkt(verlauf, laengs, quer, 0.55)
			deko.add_child(krug)


# =========================================================== Stimmung

## Zwei Stimmungen, und beide sind warm.
##
## Der Steckbrief sagt „durchweg warm" – es gibt hier bewusst keinen
## Kaltbereich als Kontrast. Der Unterschied liegt in der HELLIGKEIT:
## Die Vorhalle bekommt noch Tageslicht von draußen, ab dem Speergang
## trägt nur noch das Fackellicht. Der Weg ins Grab hinein ist deshalb
## auch ein Weg ins Dunklere.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 62.0, Color(0.86, 0.70, 0.46), 0.006, 1.15,
			Color(0.86, 0.74, 0.54), 34.0)
	stimmung(134.0, M_ENDE, Color(0.42, 0.24, 0.14), 0.013, 0.6,
			Color(0.62, 0.42, 0.26), 30.0)


func _portale() -> void:
	# Startportal bei 15 statt bei 1: Die 15 m davor sind das Geheimnis.
	portale_setzen(START, 6.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Sandhang: das Rückwärtsgeheimnis ----------
	# Sieben Kisten hinter dem Startportal, darunter das einzige
	# Extraleben der ersten Levelhälfte. Kein Schild, kein Pfeil: Wer
	# sich nie umdreht, erfährt nie, dass es sie gibt.
	kiste(Kiste.Art.NORMAL, 3.0, -2.0)
	kiste(Kiste.Art.NORMAL, 3.0, 0.0)
	kiste(Kiste.Art.NORMAL, 3.0, 2.0)
	kiste(Kiste.Art.EISEN, 6.5, 0.0)
	kiste(Kiste.Art.LEBEN, 6.5, 0.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 10.0, -1.8)
	kiste(Kiste.Art.SCHUTZ, 10.0, 1.8)

	# ---------- Vorhalle ----------
	kiste(Kiste.Art.CHECKPOINT, 20.0, -2.4)
	kiste(Kiste.Art.NORMAL, 24.0, 2.2)
	kiste(Kiste.Art.NORMAL, 33.0, 0.0)
	kiste(Kiste.Art.NORMAL, 33.0, 0.0, 1.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 43.0, -2.0)
	kiste(Kiste.Art.NORMAL, 52.0, 2.4)
	kiste(Kiste.Art.NORMAL, 59.0, -2.2)

	# ---------- Gabelung, unterer Weg ----------
	kiste(Kiste.Art.NORMAL, 68.0, LEICHT_QUER)
	# Je ein Checkpoint auf JEDEM der beiden Wege. Einer allein ginge
	# nicht: Wer über die Galerie geht, berührt zwischen 66 und 129 keinen
	# Boden – ein Checkpoint unten wäre für ihn 63 m lang gar keiner.
	kiste(Kiste.Art.CHECKPOINT, 80.0, LEICHT_QUER - 2.0)
	kiste(Kiste.Art.TNT, 82.0, LEICHT_QUER + 2.0)
	kiste(Kiste.Art.NORMAL, 82.0, LEICHT_QUER - 0.4)
	kiste(Kiste.Art.NORMAL, 96.0, LEICHT_QUER + 1.6)
	kiste(Kiste.Art.SCHUTZ, 112.0, LEICHT_QUER - 1.4)
	kiste(Kiste.Art.NORMAL, 126.0, LEICHT_QUER)

	# ---------- Gabelung, obere Galerie: der bessere Lohn ----------
	# Die Höhen kommen aus `_galerie_deck()`, nicht von Hand: Eine Kiste
	# steht mit ihrer Mitte 0,5 m über der Trittfläche.
	for eintrag in [[1, Kiste.Art.NORMAL], [2, Kiste.Art.CHECKPOINT],
			[3, Kiste.Art.FRUCHT_MEHRFACH], [5, Kiste.Art.NORMAL],
			[8, Kiste.Art.LEBEN], [10, Kiste.Art.SCHUTZ]]:
		var i: int = eintrag[0]
		var art: Kiste.Art = eintrag[1]
		kiste(art, GALERIE_STELLEN[i], GALERIE_QUER, _galerie_deck(i) + 0.5)

	# ---------- Speergang ----------
	kiste(Kiste.Art.CHECKPOINT, 136.0, -2.2)
	kiste(Kiste.Art.NORMAL, 143.0, 2.4)
	kiste(Kiste.Art.NORMAL, 152.0, -2.4)
	kiste(Kiste.Art.NORMAL, 162.0, 2.2)
	kiste(Kiste.Art.NORMAL, 166.5, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 174.5, 0.0)
	kiste(Kiste.Art.NORMAL, 188.0, -2.4)
	kiste(Kiste.Art.SCHUTZ, 196.0, 2.4)

	# ---------- Torkammern ----------
	kiste(Kiste.Art.CHECKPOINT, 200.0, -2.6)
	kiste(Kiste.Art.NORMAL, 208.0, 2.6)
	kiste(Kiste.Art.NORMAL, 216.0, -2.6)
	kiste(Kiste.Art.NORMAL, 224.0, 2.6)
	kiste(Kiste.Art.EISEN, 230.0, -2.8)
	kiste(Kiste.Art.NORMAL, 230.0, -2.8, 1.6)
	kiste(Kiste.Art.NORMAL, 238.5, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 245.0, 2.6)
	kiste(Kiste.Art.NORMAL, 256.0, -2.4)

	# ---------- Skarabäenhof: hier ist Platz für Stapel ----------
	kiste(Kiste.Art.CHECKPOINT, 262.0, -3.4)
	kiste(Kiste.Art.NORMAL, 270.0, 4.2)
	kiste(Kiste.Art.NORMAL, 270.0, 5.6)
	kiste(Kiste.Art.TNT, 280.0, 0.0)
	kiste(Kiste.Art.NORMAL, 280.0, -2.2)
	kiste(Kiste.Art.NORMAL, 280.0, 2.2)
	kiste(Kiste.Art.FEDER, 290.0, -4.4)
	kiste(Kiste.Art.NORMAL, 300.0, 0.0)
	kiste(Kiste.Art.NORMAL, 300.0, 0.0, 1.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 312.0, 3.2)
	kiste(Kiste.Art.SCHUTZ, 316.0, -3.2)

	# ---------- Grabkammer ----------
	kiste(Kiste.Art.CHECKPOINT, 320.0, -3.0)
	kiste(Kiste.Art.NORMAL, 332.0, -2.6)
	kiste(Kiste.Art.NORMAL, 332.0, 2.6)
	# Auf dem Sarkophagdeckel: der einzige Ort im Level, an dem eine
	# Kiste erhöht steht, ohne dass eine Plattform dorthin führt.
	kiste(Kiste.Art.LEBEN, 340.0, 0.0, 2.3)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 340.0, -2.6)
	kiste(Kiste.Art.NORMAL, 340.0, 2.6)
	kiste(Kiste.Art.NORMAL, 348.0, -2.2)
	kiste(Kiste.Art.NORMAL, 348.0, 2.2)


# =========================================================== Gegner

## Die Wächter des Grabes.
##
## Es gibt drei Sorten, und jede steht für eine andere Antwort:
##   Gletscherkrabbe  – der Skorpion, quer über den Gang
##   Panzerkaefer     – der Skarabäus, draufspringen
##   Stelzenspinne    – die Grabspinne, Drehschlag
##
## Auf den Speerböden und in den Torkammern stehen bewusst weniger
## Gegner: Wo der Takt schon die Aufgabe ist, wäre ein Gegner obendrauf
## kein zweiter Takt, sondern nur Pech.
func _gegner_setzen() -> void:
	# ---------- Vorhalle: einer je Antwort, mit viel Platz ----------
	gegner(PANZERKAEFER, 22.0, -2.0, 3.5, true)
	gegner(GLETSCHERKRABBE, 32.0, 2.0, 3.5, true)
	gegner(STELZENSPINNE, 45.0, -2.0, 3.0, true)

	# ---------- Gabelung: unten mehr, oben fast keine ----------
	gegner(PANZERKAEFER, 78.0, LEICHT_QUER, 4.0, true)
	gegner(GLETSCHERKRABBE, 92.0, LEICHT_QUER + 1.0, 4.0, true)
	werfer(100.0, LEICHT_QUER + 5.0, Geschoss.Art.TOPF)
	gegner(STELZENSPINNE, 122.0, LEICHT_QUER - 1.0, 3.5, true)
	# Auf der Galerie steht genau EINE Krabbe, und sie patrouilliert nicht:
	# Oben ist kein Platz zum Ausweichen, ein wandernder Gegner auf einem
	# 3 m breiten Absatz wäre keine Frage, sondern ein Würfelwurf.
	_gegner_hoch(GLETSCHERKRABBE, GALERIE_STELLEN[6], GALERIE_QUER,
			_galerie_deck(6) + 0.05, 0.0)

	# ---------- Speergang: zwei, beide auf den festen Stücken ----------
	gegner(GLETSCHERKRABBE, 150.0, 0.0, 2.4, true)
	gegner(PANZERKAEFER, 187.0, 0.0, 2.4, true)

	# ---------- Torkammern: einer vor dem Tor, einer dahinter ----------
	gegner(STELZENSPINNE, 218.0, 2.0, 2.4, true)
	gegner(PANZERKAEFER, 252.0, -2.0, 2.6, true)

	# ---------- Skarabäenhof: die dichteste Stelle ----------
	gegner(PANZERKAEFER, 266.0, -3.0, 4.5, true)
	gegner(GLETSCHERKRABBE, 274.0, 3.0, 4.5, true)
	werfer(286.0, 5.6, Geschoss.Art.TOPF)
	schwarm(294.0, -2.0, 10.0)
	gegner(STELZENSPINNE, 302.0, -3.0, 4.0, true)
	gegner(PANZERKAEFER, 310.0, 3.0, 4.0, true)

	# ---------- Grabkammer: zwei Wächter am Sarkophag ----------
	gegner(STELZENSPINNE, 334.0, -3.4, 3.0, true)
	gegner(GLETSCHERKRABBE, 346.0, 3.4, 3.0, true)


# =========================================================== Früchte

## Früchte führen den Blick. In diesem Level tun sie das zweimal
## besonders: Auf der Galerie zeigen sie, dass es dort weitergeht, und
## im Sandhang sind sie das Einzige, was einen Blick zurück belohnt,
## bevor die Kisten sichtbar werden.
func _fruechte_setzen() -> void:
	fruechte_reihe(2.0, 12.0, 6, 0.0)
	fruechte_reihe(18.0, 60.0, 14, 0.0)
	fruechte_reihe(66.0, 128.0, 16, LEICHT_QUER)
	fruechte_reihe(72.0, 126.0, 12, GALERIE_QUER, _galerie_deck(5) + 0.9)
	fruechte_reihe(136.0, 166.0, 11, 0.0)
	fruechte_reihe(174.0, 196.0, 8, 0.0)
	fruechte_reihe(200.0, 230.0, 10, 0.0)
	fruechte_reihe(238.0, 258.0, 7, 0.0)
	fruechte_reihe(262.0, 316.0, 16, 0.0)
	fruechte_bogen(288.0, 296.0, 5, -4.0, 2.4)
	fruechte_reihe(320.0, 352.0, 10, 0.0)


# =========================================================== Kulisse

## Krüge, Scherben und ein paar Palmwedel am Wandfuß.
##
## Ein Grab ist geräumt worden, bevor man selbst hineinkommt – die
## Scherben erzählen das, ohne dass ein Wort dafür nötig wäre. Alles
## ohne Kollision und außerhalb des Weges: Es soll nichts im Weg stehen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(2130)

	# Zerbrochene Steinblöcke am Wandfuß.
	for i in 44:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var abstand := _wandabstand(s)
		if abstand <= 0.0 or breite_bei(s) < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var brocken := STEIN.instantiate()
		if "saat" in brocken:
			brocken.set("saat", 2200 + i)
		if "groesse" in brocken:
			brocken.set("groesse", randf_range(0.5, 1.4))
		if "bemoost" in brocken:
			brocken.set("bemoost", false)
		if "kollision" in brocken:
			brocken.set("kollision", false)
		brocken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(abstand - 1.8, abstand - 0.7), -0.1)
		brocken.rotation.y = randf() * TAU
		deko.add_child(brocken)

	# Krüge in verschiedenen Größen, paarweise an der Wand.
	var krugstoff := Materialbibliothek.einfarbig(OCKER.darkened(0.15), 0.9)
	for i in 30:
		var s := randf_range(4.0, M_ENDE - 6.0)
		var abstand := _wandabstand(s)
		if abstand <= 0.0 or breite_bei(s) < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var hoehe := randf_range(0.55, 1.05)
		var krug := MeshInstance3D.new()
		var form := CylinderMesh.new()
		form.top_radius = hoehe * 0.24
		form.bottom_radius = hoehe * 0.36
		form.height = hoehe
		form.radial_segments = 8
		krug.mesh = form
		krug.material_override = krugstoff
		krug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (abstand - randf_range(0.8, 1.6)), hoehe * 0.5 - 0.1)
		deko.add_child(krug)

	# Vertrocknete Farne in den Fugen – der einzige Bewuchs im Grab und
	# damit dieselbe Farbfamilie wie das Wegband.
	for i in 26:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var abstand := _wandabstand(s)
		if abstand <= 0.0 or breite_bei(s) < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var busch := KLEINZEUG.instantiate() as Kleinzeug
		busch.art = Kleinzeug.Art.FARN
		busch.groesse = randf_range(0.35, 0.7)
		busch.saat = 2300 + i
		busch.eigene_farbe = true
		busch.farbe = WEGBAND.lerp(SAND_DUNKEL, randf() * 0.5)
		busch.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (abstand - randf_range(0.6, 1.4)), -0.05)
		deko.add_child(busch)
	seed(wuerfel)
