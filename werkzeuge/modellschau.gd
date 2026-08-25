extends Node3D
## Stellt mehrere Modelle nebeneinander auf und fotografiert sie.
##
## Zum Beurteilen fremder Assets, bevor sie ins Spiel wandern:
##   MODELLSCHAU=assets/modelle/gegner godot --path . res://werkzeuge/Modellschau.tscn
##
## Jedes Modell wird auf eine gemeinsame Höhe eingepasst, damit sich die
## Silhouetten vergleichen lassen, und mit seinem Namen beschriftet.

const ZIEL_HOEHE := 1.4
const ABSTAND := 2.2


func _ready() -> void:
	var ordner := OS.get_environment("MODELLSCHAU")
	if ordner.is_empty():
		ordner = "assets/modelle/gegner"
	var pfad := "res://" + ordner.trim_prefix("res://")

	_licht()
	var namen := _dateien(pfad)
	print("Modellschau: %d Modelle aus %s" % [namen.size(), pfad])

	var x := -(float(namen.size()) - 1.0) * ABSTAND * 0.5
	for name in namen:
		var figur := ModellLader.laden("%s/%s" % [pfad, name], 1.0)
		if figur == null:
			print("  FEHLT: %s (%s)" % [name, ModellLader.letzter_fehler])
			x += ABSTAND
			continue
		var halter := Node3D.new()
		halter.position = Vector3(x, 0.0, 0.0)
		halter.add_child(figur)
		add_child(halter)
		var huelle := ModellLader.huelle_von(figur)
		print("  %-14s Hülle %.2f × %.2f × %.2f m" % [name,
				huelle.size.x * figur.scale.x, huelle.size.y * figur.scale.y,
				huelle.size.z * figur.scale.z])
		var schild := Label3D.new()
		schild.text = name.get_basename()
		schild.font_size = 48
		schild.pixel_size = 0.004
		schild.position = Vector3(x, ZIEL_HOEHE + 0.5, 0.0)
		schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(schild)
		x += ABSTAND

	_boden(float(namen.size()) * ABSTAND + 2.0)
	var kamera := Camera3D.new()
	kamera.fov = 45.0
	kamera.position = Vector3(0.0, 1.5, float(namen.size()) * ABSTAND * 1.1 + 2.0)
	kamera.look_at(Vector3(0.0, 0.7, 0.0), Vector3.UP)
	add_child(kamera)
	kamera.current = true

	for f in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var ausgabe := OS.get_environment("MODELLSCHAU_BILD")
	if ausgabe.is_empty():
		ausgabe = "/tmp/modellschau.png"
	get_viewport().get_texture().get_image().save_png(ausgabe)
	print("Bild: %s" % ausgabe)
	get_tree().quit()


func _dateien(pfad: String) -> PackedStringArray:
	var liste := PackedStringArray()
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return liste
	for name in ordner.get_files():
		var sauber := name.trim_suffix(".import").trim_suffix(".remap")
		if sauber.get_extension().to_lower() in ["glb", "gltf"] and not liste.has(sauber):
			liste.append(sauber)
	liste.sort()
	return liste


func _licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(35.0), 0.0)
	sonne.light_energy = 1.4
	add_child(sonne)
	var umgebung := WorldEnvironment.new()
	var welt := Environment.new()
	welt.background_mode = Environment.BG_COLOR
	welt.background_color = Color(0.42, 0.55, 0.62)
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.6, 0.65, 0.7)
	welt.ambient_light_energy = 0.7
	umgebung.environment = welt
	add_child(umgebung)


func _boden(breite: float) -> void:
	var mi := MeshInstance3D.new()
	var netz := PlaneMesh.new()
	netz.size = Vector2(breite, 8.0)
	var stoff := StandardMaterial3D.new()
	stoff.albedo_color = Color(0.32, 0.36, 0.30)
	netz.material = stoff
	mi.mesh = netz
	add_child(mi)
