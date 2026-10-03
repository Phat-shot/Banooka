extends KorridorLevel
## Level 05 – "Hauerjagd"
##
## Eine Flucht in umgekehrter Blickrichtung: Die Kamera steht vor dem
## Spieler und schaut zurück, er rennt also auf uns zu. Hinter ihm bricht
## ein Riesenkeiler durch die Schlucht.
##
## Warum umgekehrt? Weil die Bedrohung sichtbar sein muss. Läuft die
## Kamera hinterher, sieht man den Verfolger nie und die Aufgabe wäre
## bloß ein Hindernislauf mit Zeitdruck. So hat man ihn die ganze Zeit im
## Bild und sieht an den Hauern, wie knapp es steht – dafür kommen die
## Hindernisse aus dem Rücken und werden erst spät sichtbar. Genau das ist
## der Handel.
##
## Gelaufen wird mit der normalen Figur (`Spieler`, Steuerung, Sprung und
## Animation wie überall, ohne Schwung): Wer die Taste loslässt, steht.
## Weil die Kamera zurückschaut, läuft man auf sie zu.
##
## Der Keiler ist kein Gegner mit Trefferzone, sondern ein Abstand auf der
## Kurve. Er läuft IMMER, mit festem Tempo knapp unter dem Lauftempo
## (`KEILER_TEMPO`), und fällt nie weiter als `HOECHSTABSTAND` zurück. Wer
## läuft, hält ihn auf Abstand; wer stehen bleibt oder stolpert, wird
## eingeholt. Hindernisse sind feste Körper; wer sie berührt, stolpert
## (`Spieler.stolpern`) – kein Schaden, aber ein Moment ohne Vortrieb.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  70  Aufbruch  – weit gestellte Hindernisse, Keiler noch fern
##    70 – 150  Engstelle – Schlucht zieht sich zusammen, erste Spalten
##   150 – 240  Bruch     – dichte Folge, zwei Spalten hintereinander
##   240 – 320  Endspurt  – Höchsttempo, Hindernisse im Wechseltakt
##   320 – 350  Ausgang   – Felsentor, geschafft

const STEIN := preload("res://scenes/props/Stein.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const KEILER := preload("res://scenes/enemies/Keiler.tscn")

const M_ENDE := 350.0
const AUSLAUF := 10.0

## Die Jagd. Lauftempo der Figur ist 8,5 m/s (RUN_SPEED); auf der Kurve
## kommt davon im Geraden fast alles an, in Bögen und beim Ausweichen
## weniger. 7,4 m/s: Wer durchläuft, hält den Keiler hinten; wer steht,
## hat ihn aus 15 m in zwei Sekunden an den Fersen.
const KEILER_TEMPO := 7.4
const VORSPRUNG := 12.0
const HOECHSTABSTAND := 15.0
const TODESABSTAND := 2.0
const STOLPER_DAUER := 0.45

## Bahnbreite und Wandabstand. Wie in Level 02 stehen die Wände an der
## Kante: Seitlich hinunterfallen gibt es nicht, nur die Spalten zählen.
const BAHN := 13.0
const WANDABSTAND := 6.8

const STRECKE := [
	{"von": 0.0, "bis": 70.0, "breite": BAHN},
	# Spalten 3,5 m: Die normale Figur springt aus dem Lauf gut 5,5 m weit
	# (vorher 5 m – genug für den Flüchtling mit bis zu 20 m/s, für die
	# Figur ein Absprung genau an der Kante).
	{"von": 73.5, "bis": 118.0, "breite": BAHN},
	{"von": 121.5, "bis": 150.0, "breite": BAHN},
	{"von": 150.0, "bis": 186.0, "breite": BAHN},
	{"von": 189.5, "bis": 214.0, "breite": BAHN},
	{"von": 217.5, "bis": 240.0, "breite": BAHN},
	{"von": 240.0, "bis": 286.0, "breite": BAHN},
	{"von": 289.5, "bis": 350.0, "breite": BAHN},
]

var _laeufer: Spieler
var _keiler: Keiler
## Stelle des Keilers auf der Kurve.
var _keiler_s := 0.0
var _jagd := false
var _fertig := false
var _neu_stellen := false


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return -5.0


func _bauschritte() -> Array:
	return [
		{"text": "Schlucht wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Felswände", "tun": _waende_bauen},
		{"text": "Boden wird gelegt", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Felsen und Stämme", "tun": _hindernisse_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Rastplätze", "tun": _checkpoints_setzen},
		{"text": "Wald am Rand", "tun": _deko_bauen},
		{"text": "Der Keiler wittert Beute", "tun": _flucht_einrichten},
	]


# =========================================================== Verlauf

## Lange Bögen. Enge Kurven wären hier doppelt unfair: Man sieht ohnehin
## erst spät, was vor einem liegt, weil die Kamera nach hinten schaut.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, 0, -34),
		Vector3(6, 0, -72),
		Vector3(22, 1, -106),
		Vector3(48, 1, -132),
		Vector3(80, 2, -146),
		Vector3(114, 2, -144),
		Vector3(144, 3, -128),
		Vector3(166, 4, -102),
		Vector3(178, 5, -70),
		Vector3(180, 6, -36),
		Vector3(174, 6, -4),
	])


func _waende_bauen() -> void:
	var stoff := Materialbibliothek.fels()
	var waende := [{
		"von": -6.0, "bis": M_ENDE + 6.0,
		"abstand": WANDABSTAND, "hoehe": 12.0,
	}]
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, waende, stoff, {
		"schritt": 3.0, "neigung": 4.0, "zacken": 3.0, "sockel": 20.0, "saat": 5051,
	})
	LevelWerkzeuge.leitwand(geometrie, verlauf, 0.0, M_ENDE, WANDABSTAND - 0.4, 5.0)
	LevelWerkzeuge.sims(geometrie, verlauf, [{
		"von": -4.0, "bis": M_ENDE, "innen": WANDABSTAND - 2.0,
		"aussen": WANDABSTAND + 0.6, "hoehe": -0.05,
	}], Materialbibliothek.gras())


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.gras(),
		"klippe": Materialbibliothek.fels(),
	}, {"tiefe": 12.0, "schritt": 1.4, "kante_hoehe": 0.3, "kante_breite": 0.7})
	luecken_markieren()


func _absturz_spannen() -> void:
	absturzzonen(20.0, 40.0)


# =========================================================== Hindernisse

## Ein Hindernis ist ein fester Körper (darüber springen oder ausweichen)
## und darum eine etwas größere Zone: Wer ihn berührt, stolpert.
func _hindernis(strecke: float, seitlich: float, breite: float,
		als_stamm: bool) -> void:
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	zone.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	zone.body_entered.connect(_auf_hindernis)
	zone.add_to_group("hindernis")
	zone.set_meta("strecke", strecke)
	zone.set_meta("seitlich", seitlich)
	zone.set_meta("breite", breite)
	objekte.add_child(zone)

	var hoehe := 1.1 if als_stamm else 1.6
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite + 0.3, hoehe + 0.15, 1.7)
	form.shape = kasten
	form.position.y = (hoehe + 0.15) * 0.5
	zone.add_child(form)

	var koerper := StaticBody3D.new()
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	var fest := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(breite, hoehe, 1.2 if als_stamm else 1.4)
	fest.shape = block
	fest.position.y = hoehe * 0.5
	koerper.add_child(fest)
	zone.add_child(koerper)

	if als_stamm:
		var stamm := MeshInstance3D.new()
		var walze := CylinderMesh.new()
		walze.top_radius = hoehe * 0.45
		walze.bottom_radius = hoehe * 0.45
		walze.height = breite
		walze.radial_segments = 10
		stamm.mesh = walze
		stamm.material_override = Materialbibliothek.rinde()
		stamm.rotation.z = PI * 0.5
		stamm.position.y = hoehe * 0.45
		zone.add_child(stamm)
	else:
		var brocken := STEIN.instantiate() as Stein
		brocken.groesse = breite * 0.75
		brocken.kollision = false
		brocken.saat = int(strecke * 5.0) + 3
		zone.add_child(brocken)


func _auf_hindernis(koerper: Node3D) -> void:
	if koerper is Spieler and not _fertig:
		(koerper as Spieler).stolpern(STOLPER_DAUER)


## Zwischen zwei Hindernissen liegen nie weniger als 16 m. Weil die Kamera
## nach hinten schaut, sieht man sie erst spät – enger gesetzt wäre es
## Raten statt Reagieren.
func _hindernisse_setzen() -> void:
	# ---------- Aufbruch ----------
	_hindernis(24.0, -3.4, 3.2, false)
	_hindernis(44.0, 3.4, 3.2, false)
	_hindernis(62.0, 0.0, 3.6, true)

	# ---------- Engstelle ----------
	_hindernis(84.0, -3.8, 3.4, true)
	_hindernis(102.0, 3.8, 3.4, false)
	_hindernis(132.0, 0.0, 4.0, true)

	# ---------- Bruch ----------
	_hindernis(158.0, -3.6, 3.2, false)
	_hindernis(176.0, 3.6, 3.2, true)
	_hindernis(198.0, 0.0, 3.8, false)
	_hindernis(226.0, -3.4, 3.2, true)

	# ---------- Endspurt ----------
	_hindernis(250.0, 3.6, 3.4, false)
	_hindernis(268.0, -3.6, 3.4, true)
	_hindernis(298.0, 0.0, 4.0, false)
	_hindernis(318.0, 3.4, 3.2, true)


# =========================================================== Inhalt

func _kisten_setzen() -> void:
	for eintrag in [
		# Nicht vor 17 m: Dort steht die Figur am Start (`start_strecke`).
		{"s": 17.0, "n": 3, "q": 0.0}, {"s": 32.0, "n": 4, "q": 3.0},
		{"s": 52.0, "n": 4, "q": -3.0}, {"s": 92.0, "n": 5, "q": 0.0},
		{"s": 112.0, "n": 4, "q": -2.6}, {"s": 140.0, "n": 4, "q": 2.6},
		{"s": 166.0, "n": 5, "q": 0.0}, {"s": 206.0, "n": 4, "q": 2.8},
		{"s": 234.0, "n": 4, "q": -2.8}, {"s": 258.0, "n": 5, "q": 0.0},
		{"s": 280.0, "n": 4, "q": 3.2}, {"s": 306.0, "n": 5, "q": 0.0},
		{"s": 330.0, "n": 6, "q": 0.0},
	]:
		for i in eintrag["n"]:
			kiste(Kiste.Art.NORMAL, eintrag["s"] + i * 1.6, eintrag["q"])
	kiste(Kiste.Art.LEBEN, 344.0, 0.0)
	# Schutz vor den beiden dichtesten Hindernisfolgen – ein abgefangener
	# Stolperer ist hier bares Vorsprung.
	kiste(Kiste.Art.SCHUTZ, 76.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 244.0, 0.0)


func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 20.0, 8, 0.0)
	fruechte_reihe(28.0, 40.0, 7, 3.0)
	fruechte_reihe(48.0, 60.0, 7, -3.0)
	fruechte_bogen(70.5, 74.5, 6, 0.0, 3.4)
	fruechte_reihe(78.0, 96.0, 8, 0.0)
	fruechte_bogen(118.5, 122.5, 6, 0.0, 3.4)
	fruechte_reihe(126.0, 148.0, 9, -2.6)
	fruechte_reihe(154.0, 184.0, 11, 0.0)
	fruechte_bogen(186.5, 190.5, 6, 0.0, 3.6)
	fruechte_reihe(194.0, 212.0, 8, 2.8)
	fruechte_bogen(214.5, 218.5, 6, 0.0, 3.6)
	fruechte_reihe(222.0, 238.0, 7, -2.8)
	fruechte_reihe(244.0, 284.0, 14, 0.0)
	fruechte_bogen(286.5, 290.5, 6, 0.0, 3.8)
	fruechte_reihe(294.0, 346.0, 16, 0.0)


## Rastplätze wie in Level 04: Der Fluchtläufer braucht eine Strecke als
## Rückkehrpunkt, keine Weltposition.
func _checkpoints_setzen() -> void:
	# ACHTUNG: nicht dicht vor eine Lücke legen. Bei 70.0 begann genau an
	# dieser Stelle die erste Spalte – nach dem Respawn stand man auf der
	# Kante, lief im nächsten Bild hinein, starb und landete wieder auf
	# derselben Kante. Das Spiel hing dann in einer Todesschleife fest.
	for s: float in [60.0, 150.0, 240.0, 300.0]:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, 1.2)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(BAHN + 2.0, 5.0, 1.5)
		form.shape = kasten
		zone.add_child(form)
		zone.body_entered.connect(_auf_checkpoint.bind(s))
		objekte.add_child(zone)

		for seite: float in [-1.0, 1.0]:
			var mast := MeshInstance3D.new()
			var stange := CylinderMesh.new()
			stange.top_radius = 0.08
			stange.bottom_radius = 0.1
			stange.height = 3.0
			mast.mesh = stange
			mast.material_override = Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
			mast.position = LevelWerkzeuge.punkt(verlauf, s, seite * (BAHN * 0.5 - 0.8), 1.5)
			deko.add_child(mast)
			var fahne := MeshInstance3D.new()
			var tuch := BoxMesh.new()
			tuch.size = Vector3(1.0, 0.6, 0.06)
			fahne.mesh = tuch
			fahne.material_override = Materialbibliothek.leuchtend(Farben.PORTAL_START, 0.9)
			fahne.position = mast.position + Vector3(0.0, 1.2, 0.0)
			fahne.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
			deko.add_child(fahne)


func _auf_checkpoint(koerper: Node3D, s: float) -> void:
	if koerper is Spieler and not _fertig:
		var ort := LevelWerkzeuge.punkt(verlauf, s, 0.0, 1.0)
		if GameState.checkpoint.distance_to(ort) > 1.0:
			GameState.setze_checkpoint(ort)
			GameState.zeige_nachricht("Rastplatz", 1.2)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(50511)
	for i in 110:
		var s := randf_range(-8.0, M_ENDE + 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM if i % 4 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(5.0, 11.0)
		baum.saat = 12000 + i
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(WANDABSTAND - 1.8, WANDABSTAND - 0.3), 0.0)
		deko.add_child(baum)

	for i in 50:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(3.5, 3.5)
		horst.saat = 12500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(BAHN * 0.5 - 2.0, BAHN * 0.5 - 0.4), 0.0)
		deko.add_child(horst)
	seed(wuerfel)


# =========================================================== Flucht

func _flucht_einrichten() -> void:
	_laeufer = get_tree().get_first_node_in_group("spieler") as Spieler
	if _laeufer == null:
		push_warning("Level 05 ohne Spielfigur – ist Player.tscn in der Szene?")
		return
	_keiler = KEILER.instantiate() as Keiler
	objekte.add_child(_keiler)
	# Die Figur startet ein Stück im Weg, der Keiler mit VORSPRUNG dahinter –
	# so steht auch er von Anfang an auf dem Weg und nicht im Leeren.
	start_strecke = VORSPRUNG + 2.0
	_keiler_s = start_strecke - VORSPRUNG
	if not _laeufer.gestorben.is_connected(_nach_tod):
		_laeufer.gestorben.connect(_nach_tod)
	_keiler_stellen(start_strecke, 0.0)


## Die Jagd beginnt erst, wenn die Figur losdarf (nach dem Rundgang).
func _vor_dem_start() -> void:
	_jagd = true


## Nach einem Tod steht die Figur am Rastplatz – der Keiler bekommt seinen
## Abstand zurück, sonst stünde sie gleich wieder unter den Hauern.
func _nach_tod() -> void:
	_neu_stellen = true


func _physics_process(delta: float) -> void:
	if not _jagd or _fertig or _laeufer == null or verlauf == null \
			or not is_instance_valid(_keiler):
		return
	var s_spieler := verlauf.get_closest_offset(to_local(_laeufer.global_position))
	if _neu_stellen:
		_neu_stellen = false
		_keiler_s = s_spieler - VORSPRUNG
		_keiler_stellen(s_spieler, 0.0)
		_keiler.reset_physics_interpolation()
		return
	# Er läuft immer – und fällt nie weiter zurück als HOECHSTABSTAND.
	_keiler_s = maxf(_keiler_s + KEILER_TEMPO * delta, s_spieler - HOECHSTABSTAND)
	var abstand := s_spieler - _keiler_s
	var naehe := 1.0 - clampf(abstand / HOECHSTABSTAND, 0.0, 1.0)
	_keiler_stellen(s_spieler, delta)
	_keiler.aktualisiere(delta, 1.0, naehe)
	if s_spieler >= M_ENDE - AUSLAUF:
		_auf_ziel()
		return
	if abstand <= TODESABSTAND and _laeufer.invuln <= 0.0:
		_laeufer.sterben()


## Der Keiler auf der Kurve, seitlich ein Stück zur Figur hin.
func _keiler_stellen(s_spieler: float, _delta: float) -> void:
	var s := maxf(_keiler_s, 0.0)
	var mitte := verlauf.sample_baked(clampf(s_spieler, 0.0, verlauf.get_baked_length()))
	var quer := LevelWerkzeuge.richtung(verlauf, s_spieler).cross(Vector3.UP).normalized()
	var seitlich := (to_local(_laeufer.global_position) - mitte).dot(quer) if _laeufer != null else 0.0
	var ort := verlauf.sample_baked(clampf(s, 0.0, verlauf.get_baked_length()))
	var quer_k := LevelWerkzeuge.richtung(verlauf, s).cross(Vector3.UP).normalized()
	_keiler.global_position = to_global(ort + quer_k * seitlich * 0.4)
	_keiler.rotation.y = LevelWerkzeuge.drehung(verlauf, s)


func _auf_ziel() -> void:
	_fertig = true
	_laeufer.gesperrt = true
	GameState.zeige_nachricht("Entkommen!", 3.0)
	_auf_level_geschafft()
