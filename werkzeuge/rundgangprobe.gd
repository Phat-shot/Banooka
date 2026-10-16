extends Node
## Prüft, ob der Rundgang beim Laden (`Rundgang`) alles ins Bild nimmt, was
## gezeichnet werden kann. Für jedes sichtbare `GeometryInstance3D` der
## Szene wird nachgesehen, ob es in wenigstens einem Blick aus
## `rundgang_blicke()` im Sichtkegel liegt – auf einer Ebene, die die
## Kamera zeichnet, und innerhalb seiner Sichtweite (`visibility_range`).
## Was nie im Bild ist, übersetzt der Renderer erst im Spiel.
##
## Geometrie, keine Messung: Sichtkegel gegen Hüllquader, headless. Was
## verdeckt im Kegel liegt, zählt als gesehen – es wird trotzdem gezeichnet
## (erst der Tiefentest verwirft die Bildpunkte), sein Shader also übersetzt.
##
##   godot --headless --path <Kopie> res://werkzeuge/Rundgangprobe.tscn
##
## Umgebungsvariablen:
##   RUNDGANG_SZENEN  Szenen mit Komma getrennt (Vorgabe Portalraum und
##                    Level 21)
##   RUNDGANG_STAND   "neu" oder "mitte" (Vorgabe), wie RUCKEL_STAND in
##                    `ruckelprobe.gd`: Raum 1 und 2 geschafft, Raum 3 halb
##   RUNDGANG_ZEILEN  so viele ungesehene Gruppen werden gedruckt (Vorgabe 40)
##   RUNDGANG_ORTE    1 = je Gruppe auch Ort, Sichtweite und Abstand zum
##                    nächsten Blick des ersten Objekts
##
## Ausgabe je Szene:
##   RUNDGANG <szene>: <n> Blicke, <a>/<b> Objekte gesehen, <u> ungesehen
##     (<v> verborgen, davon <w> in Effekte.VORWAERM_GRUPPE)
## und darunter die ungesehenen, nach Klasse und Stoff gruppiert.

const VORGABE := "res://scenes/hub/Hub.tscn,res://scenes/levels/Level21.tscn"


func _ready() -> void:
	var stand := OS.get_environment("RUNDGANG_STAND")
	if stand != "neu":
		_stand_mitte()
	var szenen := OS.get_environment("RUNDGANG_SZENEN")
	if szenen.is_empty():
		szenen = VORGABE
	var zeilen := int(OS.get_environment("RUNDGANG_ZEILEN")) \
			if OS.get_environment("RUNDGANG_ZEILEN").is_valid_int() else 40
	for pfad in szenen.split(","):
		await _pruefe(pfad.strip_edges(), zeilen)
	print("FERTIG")
	get_tree().quit(0)


func _stand_mitte() -> void:
	GameState.debug = false
	Spielfluss.aktueller_slot = 0
	Spielfluss.geschafft = {}
	Spielfluss.zeiten = {}
	for nr in range(1, 13):
		Spielfluss.geschafft[nr] = {"kisten": nr % 2 == 1, "ohne_tod": nr % 3 == 0,
				"fruechte": 40}
		if nr <= 9:
			Spielfluss.zeiten[nr] = {"zeit": 60.0 + float(nr) * 7.3, "stufe": nr % 4}
	Spielfluss.freigeschaltet = 13


func _pruefe(pfad: String, zeilen: int) -> void:
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	Spielfluss.aktuelles_level = int(nummer) if nummer.is_valid_int() else 0
	var paket := load(pfad) as PackedScene
	if paket == null:
		print("FEHLER: %s nicht ladbar" % pfad)
		return
	var szene := paket.instantiate()
	var fertig := [false]
	if szene.has_signal("aufbau_fertig"):
		szene.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(szene)
	var bilder := 0
	while not fertig[0] and bilder < 3000:
		bilder += 1
		await get_tree().process_frame
	if not szene.has_method("rundgang_blicke"):
		print("FEHLER: %s hat kein rundgang_blicke()" % pfad)
		szene.queue_free()
		await get_tree().process_frame
		return
	var blicke: Array = szene.call("rundgang_blicke")
	var vorbild := _kamera_in(szene)
	var kamera := Camera3D.new()
	kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if vorbild != null:
		kamera.fov = vorbild.fov
		kamera.near = vorbild.near
		kamera.far = vorbild.far
		kamera.cull_mask = vorbild.cull_mask
		kamera.keep_aspect = vorbild.keep_aspect
	# Der Kegel richtet sich nach dem Viewport der Kamera. Headless ist das
	# Fenster quadratisch (1280 × 1280) – im Spiel ist es breiter. Darum ein
	# eigener, nie gezeichneter Viewport in der Größe aus den
	# Projekteinstellungen (16:9); ein breiteres Handy sieht mehr, nie weniger.
	var buehne := SubViewport.new()
	buehne.render_target_update_mode = SubViewport.UPDATE_DISABLED
	buehne.size = Vector2i(
			int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
			int(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))
	buehne.own_world_3d = false
	add_child(buehne)
	buehne.add_child(kamera)
	# Kegel je Blick einmal ausrechnen. Godot legt die Ebenen mit der
	# Normalen nach außen; geprüft an einem Punkt mitten vor der Kamera.
	var kegel: Array[Array] = []
	var orte: Array[Vector3] = []
	for blick: Variant in blicke:
		kamera.global_transform = blick as Transform3D
		var ebenen := kamera.get_frustum()
		var innen := kamera.global_position - kamera.global_basis.z * (kamera.near + 1.0)
		var vorzeichen := 1.0
		for e in ebenen:
			if e.distance_to(innen) > 0.0:
				vorzeichen = -1.0
				break
		var liste: Array[Plane] = []
		for e in ebenen:
			liste.append(Plane(e.normal * vorzeichen, e.d * vorzeichen))
		kegel.append(liste)
		orte.append(kamera.global_position)
	var maske := kamera.cull_mask
	buehne.queue_free()

	var gesehen := 0
	var gesamt := 0
	var verborgen := 0
	var vorgewaermt := 0
	var gruppen := {}
	for knoten in _alle(szene):
		var gi := knoten as GeometryInstance3D
		if gi == null:
			continue
		if not gi.is_visible_in_tree():
			verborgen += 1
			if gi.is_in_group(Effekte.VORWAERM_GRUPPE):
				vorgewaermt += 1
			continue
		if (gi.layers & maske) == 0:
			continue
		gesamt += 1
		var huelle := gi.global_transform * gi.get_aabb()
		if _im_bild(gi, huelle, kegel, orte):
			gesehen += 1
			continue
		var schluessel := "%s  %s" % [gi.get_class(), _stoffname(gi)]
		if not gruppen.has(schluessel):
			gruppen[schluessel] = []
		var naechster := INF
		for o in orte:
			naechster = minf(naechster, o.distance_to(huelle.get_center()))
		(gruppen[schluessel] as Array).append("%s  (Mitte %s, Größe %s, Sichtweite %.0f, nächster Blick %.1f m)" % [
				String(szene.get_path_to(gi)), str(huelle.get_center().snapped(Vector3.ONE * 0.1)),
				str(huelle.size.snapped(Vector3.ONE * 0.1)), gi.visibility_range_end, naechster]
				if OS.get_environment("RUNDGANG_ORTE") == "1" else String(szene.get_path_to(gi)))
	print("RUNDGANG %s: %d Blicke, %d/%d Objekte gesehen, %d ungesehen (%d verborgen, davon %d in %s)" % [
			pfad.get_file(), blicke.size(), gesehen, gesamt, gesamt - gesehen,
			verborgen, vorgewaermt, Effekte.VORWAERM_GRUPPE])
	var reihe := gruppen.keys()
	reihe.sort_custom(func(a: Variant, b: Variant) -> bool:
		return (gruppen[a] as Array).size() > (gruppen[b] as Array).size())
	for i in mini(zeilen, reihe.size()):
		var liste: Array = gruppen[reihe[i]]
		print("  %3d × %s   z. B. %s" % [liste.size(), String(reihe[i]), String(liste[0])])
	szene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Liegt die Hülle in einem der Kegel, innerhalb der Sichtweite?
static func _im_bild(gi: GeometryInstance3D, huelle: AABB, kegel: Array[Array],
		orte: Array[Vector3]) -> bool:
	var mitte := huelle.get_center()
	for k in kegel.size():
		var abstand := orte[k].distance_to(mitte)
		if gi.visibility_range_end > 0.0 \
				and abstand > gi.visibility_range_end + gi.visibility_range_end_margin:
			continue
		if gi.visibility_range_begin > 0.0 \
				and abstand < gi.visibility_range_begin - gi.visibility_range_begin_margin:
			continue
		var drin := true
		for ebene: Plane in kegel[k]:
			# Ganz draußen, wenn selbst die Ecke, die am weitesten innen
			# liegt, vor der Ebene liegt.
			var naechste := INF
			for ecke in 8:
				naechste = minf(naechste, ebene.distance_to(huelle.get_endpoint(ecke)))
			if naechste > 0.0:
				drin = false
				break
		if drin:
			return true
	return false


static func _stoffname(gi: GeometryInstance3D) -> String:
	var stoff: Material = gi.material_override
	var mi := gi as MeshInstance3D
	if stoff == null and mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
		stoff = mi.get_active_material(0)
	if stoff == null:
		return "-"
	var shader_mat := stoff as ShaderMaterial
	if shader_mat != null and shader_mat.shader != null:
		var weg := shader_mat.shader.resource_path
		return "Shader " + (weg if not weg.is_empty() else "(eigen)")
	return stoff.get_class()


static func _kamera_in(szene: Node) -> Camera3D:
	for kind in szene.get_children():
		if kind is Camera3D:
			return kind as Camera3D
	return szene.get_viewport().get_camera_3d()


static func _alle(wurzel: Node) -> Array[Node]:
	var liste: Array[Node] = []
	for kind in wurzel.get_children():
		liste.append(kind)
		liste.append_array(_alle(kind))
	return liste
