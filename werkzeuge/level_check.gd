extends Node
## Geometrische Prüfung eines Levels.
##
## Aufruf:
##   godot --headless --path . res://werkzeuge/LevelCheck.tscn
##
## Prüft, ob alle Kisten und Gegner auf festem Boden stehen, ob die
## Patrouillen-Endpunkte der Gegner noch auf dem Weg liegen und ob die
## Absturzzone einen Sturz neben dem Pfad tatsächlich abfängt.
## Beendet sich mit Rückgabewert 1, wenn Fehler gefunden wurden.
## Bodenstrahlen ignorieren Kisten und Gegner, damit gestapelte Kisten
## nicht fälschlich als "Boden" zählen.

const MAX_SCHWEBE := 0.7
const MAX_VERSUNKEN := 0.35

var _level: Node3D
var _raum: PhysicsDirectSpaceState3D
var _fehler := 0
var _warnungen := 0
var _ausschluss: Array[RID] = []

func _ready() -> void:
	var pfad := "res://scenes/levels/Level01.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	print("Level: ", pfad)
	_level = load(pfad).instantiate()
	add_child(_level)
	# Der Aufbau läuft über mehrere Bilder (Ladebildschirm) – abwarten.
	if _level.has_signal("aufbau_fertig"):
		await _level.aufbau_fertig
	for i in 4:
		await get_tree().physics_frame
	_raum = get_viewport().world_3d.direct_space_state
	# Alle Kisten aus den Bodenstrahlen ausschließen
	for k in get_tree().get_nodes_in_group("kisten"):
		if k is CollisionObject3D:
			_ausschluss.append((k as CollisionObject3D).get_rid())

	print("=== Level 01: geometrische Prüfung ===")
	_pruefe_objekte("kisten", 0.5)
	_pruefe_objekte("gegner", 0.0)
	_pruefe_gegner_patrouille()
	await _pruefe_absturz()
	print("=== %d Fehler, %d Warnungen ===" % [_fehler, _warnungen])
	get_tree().quit(1 if _fehler > 0 else 0)

func _pruefe_objekte(gruppe: String, soll: float) -> void:
	var liste := get_tree().get_nodes_in_group(gruppe)
	var schlecht := 0
	for knoten in liste:
		var n := knoten as Node3D
		if n == null:
			continue
		var treffer := _boden_unter(n.global_position)
		if treffer.is_empty():
			print("  FEHLER  %s bei Strecke %.0f m (%s) hat keinen Boden darunter"
					% [gruppe, _strecke(n.global_position), str(n.global_position.snappedf(0.1))])
			_fehler += 1; schlecht += 1
			continue
		var abstand: float = n.global_position.y - soll - treffer["position"].y
		if abstand > MAX_SCHWEBE:
			print("  schwebt %.2f m: %s bei Strecke %.0f m" % [abstand, gruppe, _strecke(n.global_position)])
			_warnungen += 1; schlecht += 1
		elif abstand < -MAX_VERSUNKEN:
			print("  steckt %.2f m im Boden: %s bei %s" % [-abstand, gruppe, str(n.global_position.snappedf(0.1))])
			_warnungen += 1; schlecht += 1
	print("  %s: %d geprüft, %d auffällig" % [gruppe, liste.size(), schlecht])

func _pruefe_gegner_patrouille() -> void:
	var schlecht := 0
	for knoten in get_tree().get_nodes_in_group("gegner"):
		var g := knoten as Node3D
		var achse: Vector3 = g.get("patrouille_achse")
		var weite: float = g.get("patrouille_weite")
		for vorzeichen: float in [-1.0, 1.0]:
			var p: Vector3 = g.global_position + achse.normalized() * weite * vorzeichen
			if _boden_unter(p).is_empty():
				print("  FEHLER  Patrouille endet im Leeren: Gegner bei Strecke %.0f m, Endpunkt %s"
						% [_strecke(g.global_position), str(p.snappedf(0.1))])
				_fehler += 1; schlecht += 1
	print("  Patrouillen-Endpunkte: %d Probleme" % schlecht)

## Lässt an mehreren Stellen einen Testkörper neben den Pfad fallen und
## prüft, ob die Absturzzone ihn tötet.
func _pruefe_absturz() -> void:
	var verlauf = _level.get("verlauf")
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	var stellen := [10.0, 45.0, 90.0, 135.0, 180.0, 225.0]
	var misslungen := 0
	for s: float in stellen:
		var vorher: int = GameState.leben
		spieler.global_position = LevelWerkzeuge.punkt(verlauf, s, 26.0, 2.0)
		spieler.set("velocity", Vector3.ZERO)
		for i in 90:
			await get_tree().physics_frame
			if GameState.leben < vorher:
				break
		if GameState.leben >= vorher:
			print("  FEHLER  Sturz bei %.0f m wurde nicht abgefangen (y=%.1f)"
					% [s, spieler.global_position.y])
			_fehler += 1; misslungen += 1
		GameState.leben = 3
	print("  Absturzzone: %d von %d Stichproben fehlgeschlagen" % [misslungen, stellen.size()])

## Wandelt eine Weltposition in die Strecke auf dem Levelverlauf um.
func _strecke(pos: Vector3) -> float:
	var verlauf = _level.get("verlauf")
	return verlauf.get_closest_offset(pos)


func _boden_unter(pos: Vector3) -> Dictionary:
	var abfrage := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 2.0,
			pos + Vector3.DOWN * 14.0)
	abfrage.collision_mask = 1
	abfrage.collide_with_areas = false
	abfrage.exclude = _ausschluss
	return _raum.intersect_ray(abfrage)
