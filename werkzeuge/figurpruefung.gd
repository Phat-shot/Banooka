extends Node3D
## Misst und fotografiert eine Figur während ihrer Clips.
##
## Zwei Fragen lassen sich am Standbild nicht beantworten: Sackt die Figur
## in einem Clip unter den Boden, und verzerrt die Haut dabei? Deshalb wird
## über den Clip hinweg die tiefste Stelle gemessen und je Clip ein Bild
## gemacht.
##
## Gemessen wird an den Knochen, nicht an der Netzhülle: Godot meldet für
## gehäutete Netze immer die Hülle der Ruhepose, in jedem Clip dieselbe
## Zahl. Die Knochen dagegen bewegen sich wirklich.
##
##   MODELLTEST_DATEI=x.glb FIGUR_BILD=/tmp/f godot --path . res://werkzeuge/Figurpruefung.tscn
##
## FIGUR_KAMERA wählt den Blick: schraeg (Vorgabe), vorne, seite, fuesse.
## FIGUR_CLIP beschränkt auf einen Clip.
## FIGUR_BUNT=1 färbt jede Netzfläche eigen ein – so ist zu sehen, welche
## Fläche eine Verzerrung verursacht.

func _ready() -> void:
	var datei := OS.get_environment("MODELLTEST_DATEI")
	if datei.is_empty():
		datei = "cash_banooka_rc.glb"
	var pfad := Einstellungen.MITGELIEFERT.path_join(datei)
	var figur := ModellLader.laden(pfad, 1.0)
	if figur == null:
		print("nicht ladbar: ", ModellLader.letzter_fehler)
		get_tree().quit(1)
		return
	add_child(figur)
	var spieler := ModellLader.spieler_von(figur)
	if spieler == null:
		print("kein AnimationPlayer"); get_tree().quit(1); return

	if OS.get_environment("FIGUR_BUNT") == "1":
		_einfaerben(figur)

	_licht()
	var kamera := Camera3D.new()
	kamera.fov = 40.0
	var blick := OS.get_environment("FIGUR_KAMERA")
	var ziel_punkt := Vector3(0.0, 0.65, 0.0)
	match blick:
		"vorne":
			kamera.position = Vector3(0.0, 0.9, 3.4)
		"seite":
			kamera.position = Vector3(3.4, 0.9, 0.0)
		"fuesse":
			# Nah an den Boden, damit Schuhe und Sohlen zu sehen sind.
			kamera.position = Vector3(1.1, 0.30, 1.3)
			ziel_punkt = Vector3(0.0, 0.10, 0.12)
			kamera.fov = 32.0
		_:
			kamera.position = Vector3(2.2, 0.75, 2.6)
	add_child(kamera)
	kamera.look_at(ziel_punkt, Vector3.UP)
	kamera.current = true

	var ziel := OS.get_environment("FIGUR_BILD")
	if ziel.is_empty():
		ziel = "/tmp/figur"
	DirAccess.make_dir_recursive_absolute(ziel)

	print("=== Figurprüfung: %s ===" % datei)
	var nur := OS.get_environment("FIGUR_CLIP")
	for name in spieler.get_animation_list():
		if not nur.is_empty() and name != nur:
			continue
		var anim := spieler.get_animation(name)
		spieler.play(name)
		var tiefste := INF
		var hoechste := -INF
		var wo := ""
		var schritte := 24
		for i in schritte:
			spieler.seek(anim.length * float(i) / float(schritte), true)
			await get_tree().process_frame
			for knochen in _knochen(figur):
				if knochen[1] < tiefste:
					tiefste = knochen[1]
					wo = knochen[0]
				hoechste = maxf(hoechste, knochen[1])
		print("  %-10s tiefster Knochen %+.3f m (%s), höchster %+.3f m%s"
				% [name, tiefste, wo, hoechste,
				"   <-- UNTER DEM BODEN" if tiefste < -0.02 else ""])
		spieler.seek(anim.length * 0.5, true)
		for f in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
				"%s/%s.png" % [ziel, name])
	print("Bilder in %s" % ziel)
	get_tree().quit(0)


## Gibt jeder Netzfläche eine eigene Signalfarbe und nennt sie im Protokoll.
func _einfaerben(wurzel: Node) -> void:
	var farben := [Color(1, 0.2, 0.2), Color(0.2, 1, 0.3), Color(0.3, 0.5, 1),
			Color(1, 0.9, 0.2), Color(1, 0.3, 1)]
	var i := 0
	for knoten in _alle(wurzel):
		var netz := knoten as MeshInstance3D
		if netz == null or netz.mesh == null:
			continue
		for f in netz.mesh.get_surface_count():
			var stoff := StandardMaterial3D.new()
			stoff.albedo_color = farben[i % farben.size()]
			stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			stoff.cull_mode = BaseMaterial3D.CULL_DISABLED
			netz.set_surface_override_material(f, stoff)
			var alt: Material = netz.mesh.surface_get_material(f)
			var wie := alt.resource_name if alt != null else "?"
			print("  Fläche %d von %s (%s) -> %s" % [f, netz.name, wie, farben[i % farben.size()]])
			i += 1


## Alle Knochen als [Name, Welt-Höhe].
func _knochen(wurzel: Node) -> Array:
	var liste := []
	for knoten in _alle(wurzel):
		var skelett := knoten as Skeleton3D
		if skelett == null:
			continue
		for i in skelett.get_bone_count():
			var pos := (skelett.global_transform
					* skelett.get_bone_global_pose(i)).origin
			liste.append([skelett.get_bone_name(i), pos.y])
	return liste


## Hülle aller sichtbaren Netze in Weltmaßen – so, wie es auf dem Schirm steht.
func _huelle_welt(wurzel: Node) -> AABB:
	var gesamt := AABB()
	var erster := true
	for knoten in _alle(wurzel):
		var netz := knoten as MeshInstance3D
		if netz == null or netz.mesh == null or not netz.visible:
			continue
		var kasten: AABB = netz.global_transform * netz.get_aabb()
		gesamt = kasten if erster else gesamt.merge(kasten)
		erster = false
	return gesamt


func _alle(wurzel: Node) -> Array[Node]:
	var liste: Array[Node] = [wurzel]
	for kind in wurzel.get_children():
		liste.append_array(_alle(kind))
	return liste


func _licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(40.0), 0.0)
	sonne.light_energy = 1.3
	add_child(sonne)
	var umgebung := WorldEnvironment.new()
	var welt := Environment.new()
	welt.background_mode = Environment.BG_COLOR
	welt.background_color = Color(0.45, 0.52, 0.58)
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.6, 0.64, 0.7)
	welt.ambient_light_energy = 0.8
	umgebung.environment = welt
	add_child(umgebung)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(6.0, 6.0)
	var stoff := StandardMaterial3D.new()
	stoff.albedo_color = Color(0.30, 0.34, 0.28)
	platte.material = stoff
	boden.mesh = platte
	add_child(boden)
