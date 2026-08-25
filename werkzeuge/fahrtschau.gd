extends Node
## Fotografiert eine Floßfahrt von der Seite.
##
## Die normale Levelaufnahme (`foto.sh`) setzt die Figur an eine feste
## Stelle der Strecke. Auf einem Fahrtabschnitt bringt das nichts: Dort
## gibt es keinen Boden, und das Floß ist im Zweifel gerade am anderen
## Ende. Dieses Werkzeug sucht sich stattdessen ein Floß, setzt die Figur
## darauf und fährt mit.
##
##   FAHRT_ZIEL=/tmp/fahrt FAHRT_FLOSS=0 bash werkzeuge/fahrtschau.sh

const BILDER := 8          ## so viele Aufnahmen über die Fahrt verteilt

func _ready() -> void:
	var pfad := "res://scenes/levels/Level03.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	var ziel := OS.get_environment("FAHRT_ZIEL")
	if ziel.is_empty():
		ziel = "/tmp/fahrt"
	DirAccess.make_dir_recursive_absolute(ziel)

	var level: Node3D = load(pfad).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for i in 4:
		await get_tree().physics_frame

	var floesse: Array = []
	for p in get_tree().get_nodes_in_group("wasserplattformen"):
		var w := p as Wasserplattform
		if w != null and w.art == Wasserplattform.Art.FLOSS:
			floesse.append(w)
	if floesse.is_empty():
		print("kein Floß gefunden"); get_tree().quit(1); return
	var nr := int(OS.get_environment("FAHRT_FLOSS"))
	var floss: Wasserplattform = floesse[clampi(nr, 0, floesse.size() - 1)]
	print("Floß %d von %d: Strecke %.0f bis %.0f m"
			% [nr + 1, floesse.size(), floss.strecke_a, floss.strecke_b])

	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	var kamera := Camera3D.new()
	kamera.fov = 52.0
	add_child(kamera)
	kamera.current = true

	# Über die ganze Runde verteilt aufnehmen, damit Hinfahrt, Wartezeit
	# und Rückfahrt alle im Bild landen.
	var runde: float = floss.fahrzeit * 2.0 + floss.pause_a + floss.pause_b
	for i in BILDER:
		var bis := runde / float(BILDER)
		var uhr := 0.0
		while uhr < bis:
			uhr += get_physics_process_delta_time()
			if spieler != null:
				# Die Figur mitfahren lassen, ohne sie zu steuern.
				spieler.global_position = floss.global_position \
						+ Vector3.UP * (Wasserplattform.DECK_STAERKE * 0.5 + 0.05)
				spieler.set("velocity", Vector3.ZERO)
			await get_tree().physics_frame
		var mitte := floss.global_position
		kamera.global_position = mitte + Vector3(0.0, 4.2, 0.0) \
				+ floss.global_transform.basis.x * 11.0
		kamera.look_at(mitte + Vector3.UP * 0.6, Vector3.UP)
		for f in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
				"%s/fahrt_%02d.png" % [ziel, i])
		print("  Bild %d: Floß bei %s" % [i, str(mitte.snappedf(0.1))])
	print("Bilder in %s" % ziel)
	get_tree().quit(0)
