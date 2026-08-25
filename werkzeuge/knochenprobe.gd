extends Node3D
## Meldet, wo jeder Knochen einer Figur in einem Clip steht.
##
## Gebaut, weil sich Python-Rechnung und Bild widersprachen: Die eine Seite
## sagte "Hände auf 1,53 m", die andere zeigte hängende Arme. Wer recht hat,
## klärt nur die Messung an der Stelle, an der es zählt – im Spiel.
##
##   MODELLTEST_DATEI=x.glb KNOCHEN_CLIP=Hang \
##       bash werkzeuge/lauf.sh res://werkzeuge/Knochenprobe.tscn

func _ready() -> void:
	var datei := OS.get_environment("MODELLTEST_DATEI")
	if datei.is_empty():
		datei = "cash_banooka_rc.glb"
	var clip := OS.get_environment("KNOCHEN_CLIP")
	if clip.is_empty():
		clip = "Hang"
	var figur := ModellLader.laden(
			Einstellungen.MITGELIEFERT.path_join(datei), 1.0)
	if figur == null:
		print("nicht ladbar: ", ModellLader.letzter_fehler)
		get_tree().quit(1)
		return
	add_child(figur)
	var spieler := ModellLader.spieler_von(figur)
	if spieler == null:
		print("kein AnimationPlayer"); get_tree().quit(1); return
	if not spieler.has_animation(clip):
		print("Clip fehlt: ", clip); get_tree().quit(1); return

	var anim := spieler.get_animation(clip)
	print("=== %s in %s (%.2f s, %d Spuren) ==="
			% [clip, datei, anim.length, anim.get_track_count()])
	# Welche Knochen der Clip überhaupt anfasst
	var angefasst: Array[String] = []
	for i in anim.get_track_count():
		var pfad := anim.track_get_path(i)
		angefasst.append(str(pfad.get_concatenated_subnames()))
	print("  Spuren: ", ", ".join(angefasst))

	spieler.play(clip)
	spieler.seek(anim.length * 0.5, true)
	await get_tree().process_frame
	await get_tree().process_frame

	for k in _alle(figur):
		var skelett := k as Skeleton3D
		if skelett == null:
			continue
		for i in skelett.get_bone_count():
			var pos := (skelett.global_transform
					* skelett.get_bone_global_pose(i)).origin
			print("  %-12s y %+6.3f   (%.2f, %.2f, %.2f)"
					% [skelett.get_bone_name(i), pos.y, pos.x, pos.y, pos.z])
	get_tree().quit(0)


func _alle(w: Node) -> Array[Node]:
	var l: Array[Node] = [w]
	for k in w.get_children():
		l.append_array(_alle(k))
	return l
