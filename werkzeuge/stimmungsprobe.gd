extends Node
## Führt den Spieler durch ein Level und misst Nebel und Licht.
##
## Am Bildschirmfoto ist eine Stimmungszone nicht zu beurteilen: Die
## Überblendung braucht Zeit, und ein Foto trifft irgendeinen Moment darin.
## Hier wird an jeder Stelle gewartet, bis der Wert steht, und dann
## abgelesen.
##
##   bash werkzeuge/lauf.sh res://werkzeuge/Stimmungsprobe.tscn \
##       res://scenes/levels/Level10.tscn

const STELLEN := [20.0, 60.0, 100.0, 170.0, 230.0, 290.0, 325.0, 370.0, 415.0]

func _ready() -> void:
	var pfad := "res://scenes/levels/Level10.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	var level: Node3D = load(pfad).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for i in 4:
		await get_tree().physics_frame

	var verlauf: Curve3D = level.get("verlauf")
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	var welt: WorldEnvironment = null
	for k in level.find_children("*", "WorldEnvironment", true, false):
		welt = k as WorldEnvironment
		break
	if verlauf == null or spieler == null or welt == null:
		print("Level ohne Verlauf, Spieler oder Umgebung"); get_tree().quit(1); return

	var zonen := get_tree().get_nodes_in_group("stimmungszonen")
	print("=== Stimmung entlang %s ===" % pfad.get_file().get_basename())
	print("  Kurvenlänge %.1f m, Level meldet ende() = %.1f m"
			% [verlauf.get_baked_length(), float(level.call("ende"))])
	print("  %d Stimmungszonen gebaut" % zonen.size())
	for z in zonen:
		var a := z as Area3D
		print("     bei Strecke %6.0f m   Nebel %.4f   ueberwacht %s"
				% [verlauf.get_closest_offset(a.global_position),
				float(z.get("nebeldichte")), str(a.monitoring)])
	for s: float in STELLEN:
		# Jedes Bild zurücksetzen und am Leben halten. Beim ersten Versuch
		# wurde der Spieler einfach abgesetzt und 2,5 s stehen gelassen –
		# mitten unter Gegnern und auf Taktflächen. Er starb, erschien am
		# Checkpoint neu und war dann gar nicht mehr in der Zone; die Probe
		# meldete daraufhin "Stimmungszone feuert nicht", obwohl sie
		# funktionierte.
		var ort := LevelWerkzeuge.punkt(verlauf, s, 0.0, 1.2)
		for i in 150:
			# Vom Gitter lösen, sonst geht der Teleport ins Leere: `_hangeln()`
			# setzt die Figur jedes Bild auf das Gitter zurück und überschreibt
			# damit die zugewiesene Position. Beim ersten Versuch blieb die
			# Probe deshalb ab 230 m an derselben Stelle kleben.
			if spieler.has_method("hangeln_beenden"):
				spieler.call("hangeln_beenden")
			spieler.global_position = ort
			spieler.set("velocity", Vector3.ZERO)
			spieler.set("invuln", 5.0)
			GameState.leben = 9
			await get_tree().physics_frame
		var u := welt.environment
		# Mitzählen, in wie vielen Zonen der Spieler laut Physik steckt –
		# nur so lässt sich "Zone feuert nicht" von "Zone trifft nicht" trennen.
		var drin := 0
		for z in zonen:
			var a := z as Area3D
			if a != null and a.overlaps_body(spieler):
				drin += 1
		# Wo der Spieler nach dem Warten WIRKLICH steht. Ohne diese Angabe
		# lässt sich "Zone trifft nicht" nicht von "Spieler ist längst
		# woanders" unterscheiden – er fällt, stirbt und erscheint am
		# Checkpoint neu, während die Probe glaubt, er stehe still.
		# Weltkoordinaten statt Streckenmaß: Bei einem Verlauf, der eine
		# Schleife macht, liegt `get_closest_offset` daneben – der Punkt bei
		# 290 m kann geometrisch dichter am 230-m-Stück liegen.
		var soll_ort := LevelWerkzeuge.punkt(verlauf, s, 0.0, 0.0)
		var abstand := spieler.global_position.distance_to(soll_ort)
		print("  %6.0f m  Soll %s  Ist %s  Abstand %5.1f  Nebel %.4f  in %d Zonen"
				% [s, str(soll_ort.snappedf(0.1)),
				str(spieler.global_position.snappedf(0.1)),
				abstand, u.fog_density, drin])
	get_tree().quit(0)
