extends Node
## Zählt die Wasserflächen eines Levels und meldet ihre Welthöhe.
func _ready() -> void:
	var pfad := "res://scenes/levels/Level10.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	var level: Node3D = load(pfad).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for i in 3:
		await get_tree().physics_frame
	var verlauf: Curve3D = level.get("verlauf")
	var n := 0
	for k in get_tree().get_nodes_in_group("wasser"):
		var w := k as Node3D
		n += 1
		print("  Wasser %2d  Welt-y %+6.2f  Strecke %6.1f m"
				% [n, w.global_position.y,
				verlauf.get_closest_offset(w.global_position)])
	print("%d Wasserflächen" % n)
	get_tree().quit(0)
