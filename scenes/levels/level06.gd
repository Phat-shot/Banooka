extends KorridorLevel
## Level 06 – "Wettrennen"
##
## Ein Rundkurs gegen vier Gegner-Karts, drei Runden. Anders als die
## Laufstrecken davor ist die Strecke geschlossen: `strecke` läuft am Ende
## einer Runde wieder auf null, gezählt wird `runde * rundenlaenge +
## strecke`. Genau daraus ergibt sich die Platzierung – ein Zahlenvergleich
## statt einer Zielrichtungsprüfung.
##
## Auf der Strecke liegen drei Dinge:
##   Schubfelder – geben sofort Schub, liegen auf der Ideallinie
##   Schubkisten – sammeln eine Ladung, die per Knopfdruck zündet
##   Löcher      – Lücken im Belag; wer nicht springt, dreht sich und
##                 verliert Zeit. Tödlich ist hier nichts, ein Rennen
##                 endet nicht am Streckenrand.
##
## Abschnitte des Kurses (Strecke in Metern):
##     0 –  90  Start und Gegengerade
##    90 – 180  Kehre mit zwei Löchern
##   180 – 280  Waldstück mit Schubfeldern
##   280 – Ende Schlusskurve

const GRASFELD := preload("res://scenes/props/Gras.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const RENNFAHRER := preload("res://scenes/player/Rennfahrer.tscn")
const RENNANZEIGE := preload("res://scenes/ui/Rennanzeige.tscn")

const RUNDEN := 3

## Farben und Namen der Gegner. Der Spieler fährt in Fellfarbe.
const GEGNER := [
	{"name": "Rotfuchs", "farbe": Color(0.86, 0.22, 0.18), "koennen": 0.94},
	{"name": "Blauhäher", "farbe": Color(0.24, 0.45, 0.90), "koennen": 0.97},
	{"name": "Grünspecht", "farbe": Color(0.22, 0.68, 0.32), "koennen": 1.00},
	{"name": "Gelbwiesel", "farbe": Color(0.95, 0.78, 0.16), "koennen": 0.91},
]

## Lücken im Belag, als Anteil der Runde. Absolute Meter gingen hier
## schief: Die geglättete Kurve ist länger als die Summe ihrer Stützpunkte
## (380 m statt der veranschlagten 360), und die Differenz lag hinterher
## als Loch quer über der Start-Ziel-Geraden – alle Karts drehten sich dort
## endlos. Deshalb wird der Belag aus der gemessenen Rundenlänge gebaut.
const LOECHER := [
	{"bei": 0.29, "breite": 5.0},
	{"bei": 0.40, "breite": 5.0},
	{"bei": 0.65, "breite": 5.0},
]
## Bahnbreite, an den Löchern etwas schmaler.
const BAHNBREITE := 15.0

var _fahrer: Array[Rennfahrer] = []
var _anzeige: Rennanzeige
var _rundenlaenge := 0.0
var _abschnitte: Array = []


func abschnitte() -> Array:
	return _abschnitte


func ende() -> float:
	return _rundenlaenge


func absturz_hoehe() -> float:
	# Es gibt keine Absturzzone: In ein Loch zu fallen kostet Zeit, nicht
	# ein Leben. Der Wert steht nur da, damit die Basis etwas hat.
	return -50.0


func _bauschritte() -> Array:
	return [
		{"text": "Kurs wird abgesteckt", "tun": _verlauf_anlegen},
		{"text": "Belag wird gelegt", "tun": _boden_bauen},
		{"text": "Start- und Zielgerade", "tun": _startlinie_bauen},
		{"text": "Schubfelder", "tun": _schubfelder_setzen},
		{"text": "Schubkisten", "tun": _schubkisten_setzen},
		{"text": "Wald am Rand", "tun": _deko_bauen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Die Karts rollen an", "tun": _fahrer_aufstellen},
	]


# =========================================================== Verlauf

## Ein geschlossener Rundkurs. Der letzte Punkt liegt neben dem ersten,
## damit Start und Ziel zusammenfallen; die Glättung zieht den Übergang
## rund. Weite Kurven, weil bei 21 m/s eine enge Kehre nicht zu lesen wäre.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 0),          # Start-Ziel-Linie
		Vector3(0, 0, -40),
		Vector3(6, 0, -76),        # Anbremsen zur ersten Kurve
		Vector3(28, 0, -100),
		Vector3(58, 0, -108),      # Gegengerade
		Vector3(88, 0, -100),
		Vector3(108, 1, -76),      # Kehre
		Vector3(112, 1, -44),
		Vector3(100, 2, -14),      # Waldstück
		Vector3(78, 2, 8),
		Vector3(50, 2, 16),
		Vector3(22, 1, 12),        # Schlusskurve
		Vector3(4, 0, 4),
	])
	_rundenlaenge = verlauf.get_baked_length()
	_abschnitte_bauen()


## Belag über die ganze Runde, unterbrochen von den Löchern.
func _abschnitte_bauen() -> void:
	_abschnitte.clear()
	var kanten: Array = []
	for loch in LOECHER:
		var mitte: float = float(loch["bei"]) * _rundenlaenge
		var halb: float = float(loch["breite"]) * 0.5
		kanten.append({"von": mitte - halb, "bis": mitte + halb})
	kanten.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["von"] < b["von"])

	var s := 0.0
	for loch in kanten:
		if loch["von"] > s:
			_abschnitte.append({"von": s, "bis": loch["von"], "breite": BAHNBREITE})
		s = loch["bis"]
	# Letztes Stück bis zurück zur Start-Ziel-Linie
	if s < _rundenlaenge:
		_abschnitte.append({"von": s, "bis": _rundenlaenge, "breite": BAHNBREITE})


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, _abschnitte, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.gras(),
		"klippe": Materialbibliothek.fels(),
	}, {"tiefe": 3.0, "schritt": 1.6, "kante_hoehe": 0.3, "kante_breite": 1.0})
	luecken_markieren()


## Start-und-Ziel-Linie als Schachbrettband quer über die Bahn.
func _startlinie_bauen() -> void:
	var hell := Materialbibliothek.einfarbig(Color(0.95, 0.95, 0.95), 0.7)
	var dunkel := Materialbibliothek.einfarbig(Color(0.12, 0.12, 0.13), 0.7)
	var breite := breite_bei(1.0)
	var felder := 12
	for i in felder:
		for reihe in 2:
			var quer := (float(i) / float(felder) - 0.5) * (breite - 1.2)
			var feld := MeshInstance3D.new()
			var kasten := BoxMesh.new()
			kasten.size = Vector3(breite / float(felder), 0.05, 0.7)
			feld.mesh = kasten
			feld.material_override = hell if (i + reihe) % 2 == 0 else dunkel
			feld.position = LevelWerkzeuge.punkt(verlauf, 1.0 + reihe * 0.7,
					quer, 0.03)
			feld.rotation.y = LevelWerkzeuge.drehung(verlauf, 1.0)
			geometrie.add_child(feld)


# =========================================================== Schub

## Schubfelder liegen auf der Ideallinie – wer die Kurve außen fährt,
## nimmt sie nicht mit.
func _schubfelder_setzen() -> void:
	for eintrag in [
		{"s": 46.0, "q": 0.0}, {"s": 96.0, "q": -3.5},
		{"s": 138.0, "q": 3.5}, {"s": 196.0, "q": 0.0},
		{"s": 258.0, "q": -3.0}, {"s": 318.0, "q": 3.0},
	]:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.position = LevelWerkzeuge.punkt(verlauf, eintrag["s"], eintrag["q"], 0.6)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, eintrag["s"])
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(4.0, 1.6, 3.0)
		form.shape = kasten
		zone.add_child(form)
		zone.body_entered.connect(_auf_schubfeld)
		objekte.add_child(zone)

		var platte := MeshInstance3D.new()
		var flach := BoxMesh.new()
		flach.size = Vector3(4.0, 0.08, 3.0)
		platte.mesh = flach
		platte.material_override = Materialbibliothek.leuchtend(
				Color(1.0, 0.62, 0.18), 1.6)
		platte.position = LevelWerkzeuge.punkt(verlauf, eintrag["s"],
				eintrag["q"], 0.06)
		platte.rotation.y = LevelWerkzeuge.drehung(verlauf, eintrag["s"])
		geometrie.add_child(platte)


func _auf_schubfeld(koerper: Node3D) -> void:
	if koerper is Rennfahrer:
		(koerper as Rennfahrer).schubfeld()


## Schubkisten zum Sammeln, meist am Rand – wer sie mitnimmt, verliert
## Linie und gewinnt später Tempo.
func _schubkisten_setzen() -> void:
	for eintrag in [
		{"s": 24.0, "q": -5.0}, {"s": 70.0, "q": 5.0}, {"s": 120.0, "q": 0.0},
		{"s": 168.0, "q": -4.5}, {"s": 212.0, "q": 4.5}, {"s": 288.0, "q": 0.0},
		{"s": 336.0, "q": -4.0},
	]:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.position = LevelWerkzeuge.punkt(verlauf, eintrag["s"], eintrag["q"], 0.9)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, eintrag["s"])
		var form := CollisionShape3D.new()
		var kugel := SphereShape3D.new()
		kugel.radius = 1.2
		form.shape = kugel
		zone.add_child(form)
		zone.body_entered.connect(_auf_schubkiste.bind(zone))
		objekte.add_child(zone)

		var wuerfel := MeshInstance3D.new()
		var kasten := BoxMesh.new()
		kasten.size = Vector3(1.1, 1.1, 1.1)
		wuerfel.mesh = kasten
		wuerfel.material_override = Materialbibliothek.transparent(
				Color(1.0, 0.72, 0.25), 1.4)
		zone.add_child(wuerfel)


## Die Kiste verschwindet kurz und kommt wieder – sonst wäre sie in Runde 1
## verbraucht und der Rest des Rennens ohne Schub.
func _auf_schubkiste(koerper: Node3D, zone: Area3D) -> void:
	if not (koerper is Rennfahrer) or not zone.visible:
		return
	(koerper as Rennfahrer).schub_sammeln()
	zone.visible = false
	zone.set_deferred("monitoring", false)
	await get_tree().create_timer(6.0).timeout
	if is_instance_valid(zone):
		zone.visible = true
		zone.monitoring = true


# =========================================================== Kulisse

## Ferne Hügelkette und ein Untergrund für die Wiese.
##
## Dieses Level hatte als einziges überhaupt keine Bodengeometrie neben der
## Bahn: Das Grün ringsum war die untere Hälfte des Himmel-Shaders, und die
## endete an einem kerzengeraden Horizont auf Augenhöhe. Deshalb hier mit
## Bodenscheibe, anders als im Katzenrennen.
func _horizont_bauen() -> void:
	var h := HORIZONT.instantiate() as Horizont
	h.radius = 190.0
	h.hoehe = 24.0
	h.zacken = 52
	h.farbe_nah = Color(0.30, 0.40, 0.28)
	h.farbe_fern = Color(0.55, 0.65, 0.62)
	h.boden = true
	h.boden_farbe = Color(0.31, 0.44, 0.24)
	h.fuss = -3.0
	h.saat = 4061
	# Mitte des Rundkurses, nicht Streckenmitte: Der Kurs ist eine Schleife.
	h.position = _kursmitte()
	deko.add_child(h)


## Schwerpunkt des Rundkurses. Der Horizont muss um den ganzen Kurs liegen,
## nicht um einen Punkt darauf.
func _kursmitte() -> Vector3:
	var summe := Vector3.ZERO
	var proben := 24
	for i in proben:
		summe += LevelWerkzeuge.punkt(verlauf,
				_rundenlaenge * float(i) / float(proben), 0.0, 0.0)
	return summe / float(proben)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(50501)
	for i in 80:
		var s := randf_range(0.0, _rundenlaenge)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.LAUBBAUM if i % 4 else Baum.Art.NADELBAUM
		baum.hoehe = randf_range(5.0, 11.0)
		baum.saat = 11000 + i
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(11.0, 30.0), -0.2)
		deko.add_child(baum)

	for i in 44:
		var s := randf_range(0.0, _rundenlaenge)
		var rand := rand_bei(s, 0.6)
		if rand < 1.5:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(4.0, 4.0)
		horst.saat = 11500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(horst)
	seed(wuerfel)


# =========================================================== Fahrer

## Der Spieler steht ganz hinten im Feld – vorneweg zu starten wäre kein
## Rennen. Die Startaufstellung ist versetzt, damit sich beim Start
## niemand überlagert.
func _fahrer_aufstellen() -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Rennfahrer
	if spieler == null:
		push_warning("Level 06 ohne Spielerkart – ist Rennfahrer.tscn in der Szene?")
		return
	# Der Spieler steht auf der Linie, das Feld davor. Startstrecken müssen
	# hier nicht-negativ sein – siehe die Warnung in `_einrichten()`.
	_einrichten(spieler, 0.0, 0.0, 1.0)
	spieler.fahrername = "Banooka"
	spieler.farbe = Farben.FELL
	_fahrer.append(spieler)

	for i in GEGNER.size():
		var eintrag: Dictionary = GEGNER[i]
		var gegner := RENNFAHRER.instantiate() as Rennfahrer
		gegner.ist_spieler = false
		gegner.farbe = eintrag["farbe"]
		gegner.fahrername = eintrag["name"]
		objekte.add_child(gegner)
		# Zwei Reihen zu zwei Karts vor dem Spieler
		var reihe := i / 2
		var seite := -3.5 if i % 2 == 0 else 3.5
		_einrichten(gegner, 2.5 + reihe * 4.0, seite, eintrag["koennen"])
		_fahrer.append(gegner)

	_anzeige = RENNANZEIGE.instantiate() as Rennanzeige
	_anzeige.fahrer = _fahrer
	_anzeige.runden_ziel = RUNDEN
	add_child(_anzeige)

	spieler.rennen_beendet.connect(_auf_zieleinlauf)


## Setzt einen Fahrer auf seinen Startplatz.
##
## `s` muss NICHT-NEGATIV sein. Vorher stand hier `fposmod(s, rundenlaenge)`
## und der Spieler startete bei -6: Auf einem Rundkurs wurde daraus
## `rundenlaenge - 6`, also fast eine volle Runde. Die Platzierung rechnet
## über `runde * rundenlaenge + strecke` (rennfahrer.gd) – der Spieler stand
## damit vom ersten Bild an auf Platz 1, obwohl er hinten stehen sollte.
func _einrichten(f: Rennfahrer, s: float, quer: float, koennen: float) -> void:
	f.verlauf = verlauf
	f.rundenlaenge = _rundenlaenge
	f.runden_ziel = RUNDEN
	f.seiten_grenze = func(x: float) -> float: return rand_bei(x, 1.4)
	f.boden_pruefer = func(x: float) -> bool: return breite_bei(x) > 0.0
	if s < 0.0:
		push_warning("Startstrecke %.1f ist negativ – das ergibt auf einem "
				% s + "Rundkurs fast eine ganze Runde Vorsprung.")
	f.strecke = maxf(s, 0.0)
	f._seitlich = quer
	f._seitlich_ziel = quer
	# Das Können skaliert das Wunschtempo der Fahrhilfe.
	f.koennen = koennen
	f.tempo = Rennfahrer.TEMPO_START * koennen


func _auf_zieleinlauf() -> void:
	var platz := _anzeige.platz()
	_anzeige.schlusstext = "Platz %d von %d" % [platz, _fahrer.size()]
	for f in _fahrer:
		f.gesperrt = true
	GameState.zeige_nachricht("Zieleinlauf!", 3.0)
	_auf_level_geschafft()
