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
	if OS.get_environment("PRUEF_ASSETS") == "0":
		Einstellungen.fremde_modelle = false
	print("Level: ", pfad, "  fremde Modelle: ",
			"an" if Einstellungen.fremde_modelle else "aus")
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

	print("=== %s: geometrische Prüfung ===" % pfad.get_file().get_basename())
	_pruefe_objekte("kisten", 0.5)
	_pruefe_objekte("gegner", 0.0)
	_pruefe_baeume()
	_pruefe_gegner_patrouille()
	await _pruefe_absturz()
	print("=== %d Fehler, %d Warnungen ===" % [_fehler, _warnungen])
	get_tree().quit(1 if _fehler > 0 else 0)

func _pruefe_objekte(gruppe: String, soll: float) -> void:
	var liste := get_tree().get_nodes_in_group(gruppe)
	var schlecht := 0
	var absichtlich := 0
	for knoten in liste:
		var n := knoten as Node3D
		if n == null:
			continue
		# Kisten, die als Stufe oder Plattform gedacht sind, stehen
		# absichtlich in der Luft. Sie tragen das Merkmal aus
		# `korridor_level.kiste(..., schwebt = true)`.
		if n.is_in_group("schwebende_kisten"):
			absichtlich += 1
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
	if absichtlich > 0:
		print("  %s: %d geprüft, %d auffällig, %d schweben absichtlich"
				% [gruppe, liste.size(), schlecht, absichtlich])
	else:
		print("  %s: %d geprüft, %d auffällig" % [gruppe, liste.size(), schlecht])

## Prüft, ob Bäume wirklich auf dem Boden stehen.
##
## Anders als bei Kisten reicht der Knotenursprung hier nicht: Ein fremdes
## Modell kann seinen Ursprung irgendwo im Geäst haben. Gemessen wird
## deshalb die SICHTBARE Unterkante – die Hülle aller Netze in Weltmaßen.
func _pruefe_baeume() -> void:
	var baeume: Array[Node3D] = []
	_sammle_baeume(_level, baeume)
	var schlecht := 0
	var ohne_boden := 0
	var kulisse := 0
	for baum in baeume:
		# Deko-Bäume ohne Kollision stecken absichtlich in der Wandkrone
		# oder stehen als Kulisse in der Schlucht – sie sollen gar nicht
		# auf dem Boden stehen.
		if not bool(baum.get("kollision")):
			kulisse += 1
			continue
		# Der eigene Stamm darf den Bodenstrahl nicht abfangen.
		var eigene: Array[RID] = []
		for k in _alle_koerper(baum):
			eigene.append(k)
		var unten := _unterkante_welt(baum)
		if unten == INF:
			continue
		var treffer := _boden_unter_ohne(baum.global_position, eigene)
		if treffer.is_empty():
			# Der Waldbestand neben dem Weg steht auf dem sichtbaren
			# Waldboden, der keine Kollision trägt. Das ist Kulisse und
			# kein Fehler – nur gezählt, nicht gemeldet.
			ohne_boden += 1
			continue
		var abstand: float = unten - treffer["position"].y
		if abstand > MAX_SCHWEBE:
			print("  schwebt %.2f m: Baum bei Strecke %.0f m (unter %s, y=%.1f)"
					% [abstand, _strecke(baum.global_position),
					baum.get_parent().name, baum.global_position.y])
			_warnungen += 1; schlecht += 1
		elif abstand < -1.2:
			print("  steckt %.2f m im Boden: Baum bei Strecke %.0f m"
					% [-abstand, _strecke(baum.global_position)])
			_warnungen += 1; schlecht += 1
	print("  baeume: %d geprüft, %d auffällig (%d Kulisse in der Wand, %d auf dem Waldboden)"
			% [baeume.size(), schlecht, kulisse, ohne_boden])


func _sammle_baeume(wurzel: Node, hinein: Array[Node3D]) -> void:
	for kind in wurzel.get_children():
		if kind is Baum:
			hinein.append(kind as Node3D)
		else:
			_sammle_baeume(kind, hinein)


## Tiefster Punkt aller sichtbaren Netze in Weltmaßen.
func _unterkante_welt(wurzel: Node) -> float:
	var tiefster := INF
	var netz := wurzel as MeshInstance3D
	if netz != null and netz.mesh != null and netz.visible:
		var kasten := netz.global_transform * netz.mesh.get_aabb()
		tiefster = kasten.position.y
	for kind in wurzel.get_children():
		tiefster = minf(tiefster, _unterkante_welt(kind))
	return tiefster


func _alle_koerper(wurzel: Node) -> Array[RID]:
	var liste: Array[RID] = []
	if wurzel is CollisionObject3D:
		liste.append((wurzel as CollisionObject3D).get_rid())
	for kind in wurzel.get_children():
		liste.append_array(_alle_koerper(kind))
	return liste


func _boden_unter_ohne(pos: Vector3, zusatz: Array[RID]) -> Dictionary:
	var frage := PhysicsRayQueryParameters3D.create(
			pos + Vector3.UP * 4.0, pos + Vector3.DOWN * 30.0)
	frage.exclude = _ausschluss + zusatz
	return _raum.intersect_ray(frage)


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
	# In Ritt- und Fluchtleveln klebt der Spieler auf der Kurve und setzt
	# seine Position jedes Bild neu – er lässt sich gar nicht neben den Pfad
	# fallen. Die Probe meldete dort sechs Fehler, wo keiner war.
	if spieler != null and "boden_pruefer" in spieler:
		print("  Absturzzone: entfällt (Schienenlevel, kein Sturz möglich)")
		return
	var stellen := [10.0, 45.0, 90.0, 135.0, 180.0, 225.0]
	var misslungen := 0
	for s: float in stellen:
		# Erst den vorigen Tod ausklingen lassen. Sonst setzt die nächste
		# Stichprobe den Spieler mitten in einen laufenden Respawn – der
		# holt ihn zum Checkpoint zurück, er stirbt nicht, und die Probe
		# meldet einen Fehler, den es nicht gibt.
		for i in 40:
			await get_tree().physics_frame
		var vorher: int = GameState.leben
		spieler.global_position = LevelWerkzeuge.punkt(verlauf, s, 26.0, 2.0)
		spieler.set("velocity", Vector3.ZERO)
		for i in 90:
			await get_tree().physics_frame
			if GameState.leben < vorher:
				break
		if GameState.leben >= vorher:
			# Ohne den Namen dessen, was den Sturz aufhält, ist die Meldung
			# nur ein Rätsel. Also gleich mitliefern.
			var halt := _boden_unter(spieler.global_position)
			var worauf := "nichts"
			if not halt.is_empty() and halt["collider"] != null:
				var c: Node3D = halt["collider"]
				worauf = "%s (%s) bei %s" % [c.name, c.get_class(),
						str(c.global_position.snappedf(0.1))]
			# Wo er liegen bleibt, ist die eigentliche Auskunft: Bei einem
			# Verlauf, der eine Schleife macht, kann seitwärts sehr wohl
			# wieder fester Weg liegen – dann ist die Probe kein Fehler,
			# sondern nur schlecht gezielt.
			print("  FEHLER  Sturz bei %.0f m nicht abgefangen: liegt bei %s "
					% [s, str(spieler.global_position.snappedf(0.1))]
					+ "(Strecke %.0f m) auf %s"
					% [_strecke(spieler.global_position), worauf])
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
