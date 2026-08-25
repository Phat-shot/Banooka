extends Node
## Listet alle Wasserplattformen eines Levels mit ihrem Platz auf.
##
## Gebaut, weil sich am Bild nicht ablesen lässt, ob eine bewegte
## Plattform überhaupt an ihren Platz gekommen ist: Steht sie im
## Nullpunkt, sieht man sie schlicht nicht – und sucht den Fehler an der
## falschen Stelle. Diese Liste beantwortet das in einem Lauf.
##
##   godot --headless --path . res://werkzeuge/Plattformschau.tscn \
##       -- res://scenes/levels/Level03.tscn

func _ready() -> void:
	var pfad := "res://scenes/levels/Level03.tscn"
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
	print("=== %s ===" % pfad.get_file().get_basename())
	if verlauf != null:
		print("Kurvenlänge: %.1f m" % verlauf.get_baked_length())

	var nr := 0
	var im_nullpunkt := 0
	for p in get_tree().get_nodes_in_group("wasserplattformen"):
		var w := p as Wasserplattform
		if w == null:
			continue
		nr += 1
		var daheim := w.global_position.length() < 0.01
		if daheim:
			im_nullpunkt += 1
		var fahrt := "steht"
		if w.verlauf != null:
			fahrt = "Strecke %.0f–%.0f m" % [w.strecke_a, w.strecke_b]
		elif w.punkt_a != w.punkt_b:
			fahrt = "%.2f m Hub" % w.punkt_a.distance_to(w.punkt_b)
		print("  %2d  %-8s %-22s %-18s %s"
				% [nr, Wasserplattform.Art.keys()[w.art],
				str(w.global_position.snappedf(0.1)), fahrt,
				"<-- steht im Nullpunkt" if daheim else ""])
	print("%d Plattformen, davon %d im Nullpunkt" % [nr, im_nullpunkt])
	get_tree().quit(1 if im_nullpunkt > 0 else 0)
