extends Node
## Meldet, ob ein Level eine Hügelkette hat und wo sie steht.
func _ready() -> void:
	var pfad := "res://scenes/levels/Level06.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	var level: Node3D = load(pfad).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for i in 3:
		await get_tree().physics_frame
	var gefunden := 0
	for k in _alle(level):
		if k is Horizont:
			gefunden += 1
			print("Horizont bei %s, radius %.0f, hoehe %.0f, fuss %.1f"
					% [str(k.global_position.snappedf(0.1)), k.radius, k.hoehe, k.fuss])
			for kind in _alle(k):
				var mi := kind as MeshInstance3D
				if mi == null or mi.mesh == null:
					continue
				var h: AABB = mi.global_transform * mi.get_aabb()
				print("   %-14s y %+.1f .. %+.1f   Breite %.0f m   sichtbar %s"
						% [mi.name, h.position.y, h.position.y + h.size.y,
						h.size.x, str(mi.visible)])
	print("Hügelketten gefunden: %d" % gefunden)
	get_tree().quit(0)

func _alle(w: Node) -> Array[Node]:
	var l: Array[Node] = [w]
	for k in w.get_children():
		l.append_array(_alle(k))
	return l
