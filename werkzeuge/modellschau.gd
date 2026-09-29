extends Node3D
## Stellt mehrere Modelle nebeneinander auf und fotografiert sie.
##
## Zum Beurteilen fremder Assets, bevor sie ins Spiel wandern:
##   MODELLSCHAU=assets/modelle/gegner godot --path . res://werkzeuge/Modellschau.tscn
##
## MODELLSCHAU_NUR=a,b   nur diese Modelle zeigen
## MODELLSCHAU_VORNE=1   von vorn zeigen (Spielkonvention: Figur schaut -Z).
##                       Wer dabei sein Gesicht zeigt, ist richtig gedreht.
##
## Jedes Modell wird auf eine gemeinsame Höhe eingepasst, damit sich die
## Silhouetten vergleichen lassen, und mit seinem Namen beschriftet.
##
## Netzschau (Level 01): MODELLSCHAU_NETZ=1 oder MODELLSCHAU=…natur2 zeigt
## jedes Modell so, wie `Fremdmodelle.netz()` es für die Streuer liefert –
## verschmolzen, im Stoff des Waldes, in Originalgröße der Rolle, unter dem
## Licht von Level 01. Gezeigt werden alle natur2-Modelle und alles, was die
## Rollen M1–M18 heute bekommen (ohne natur2: die Kenney-Rückfälle), dazu
## ein selbstgebautes Prüfmodell für den Weg über texturierte, unbeleuchtete
## und ausgeschnittene Materialien. Drei Bilder: Übersicht, Streuung (als
## MultiMesh, aus der Spielkamera) und Nahaufnahme der harten Flächen.
## Headless werden nur die Prüfungen gerechnet („=== N Abweichungen").
##   MODELLSCHAU_NETZ=1 MODELLSCHAU_BILD=/tmp/netz.png godot --path . res://werkzeuge/Modellschau.tscn

const ZIEL_HOEHE := 1.4
const ABSTAND := 2.2


func _ready() -> void:
	var ordner := OS.get_environment("MODELLSCHAU")
	if OS.get_environment("MODELLSCHAU_NETZ") == "1" or ordner.contains("natur2"):
		await _netzschau()
		return
	if ordner.is_empty():
		ordner = "assets/modelle/gegner"
	# Auch `user://` zulassen – dort liegen die zur Laufzeit hinzugelegten
	# Figuren, und gerade die will man vergleichen können.
	var pfad := ordner
	if not (pfad.begins_with("res://") or pfad.begins_with("user://")):
		pfad = "res://" + pfad

	_licht()
	var namen := _dateien(pfad)
	var nur := OS.get_environment("MODELLSCHAU_NUR")
	if not nur.is_empty():
		var erlaubt := nur.split(",")
		var gefiltert := PackedStringArray()
		for n in namen:
			for e in erlaubt:
				if n.get_basename() == e.strip_edges():
					gefiltert.append(n)
		namen = gefiltert
	print("Modellschau: %d Modelle aus %s" % [namen.size(), pfad])

	# Unsere eigene Figur mit in die Reihe: Nur so lässt sich sagen, ob ein
	# fremdes Modell verdreht ist oder unsere Blickrichtung falsch liegt.
	var eigene := OS.get_environment("MODELLSCHAU_EIGEN") == "1"
	var plaetze := namen.size() + (1 if eigene else 0)
	var x := -(float(plaetze) - 1.0) * ABSTAND * 0.5
	if eigene:
		var beuteldachs := SpielerModell.new()
		beuteldachs.position = Vector3(x, 0.0, 0.0)
		add_child(beuteldachs)
		var schild_eigen := Label3D.new()
		schild_eigen.text = "Beuteldachs (unser)"
		schild_eigen.font_size = 48
		schild_eigen.pixel_size = 0.004
		schild_eigen.position = Vector3(x, ZIEL_HOEHE + 0.5, 0.0)
		schild_eigen.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(schild_eigen)
		x += ABSTAND
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
	# Abstand so, dass die Reihe das Bild füllt – vorher stand die Kamera
	# viel zu weit weg und alles war briefmarkengroß.
	var spanne := maxf(float(plaetze) * ABSTAND, 2.0)
	var weg := spanne * 0.62 + 1.8
	var vorne := OS.get_environment("MODELLSCHAU_VORNE") == "1"
	kamera.position = Vector3(0.0, 1.1, -weg if vorne else weg)
	add_child(kamera)
	# Erst einhängen, dann ausrichten: `look_at` braucht den Knoten im Baum.
	kamera.look_at(Vector3(0.0, 0.7, 0.0), Vector3.UP)
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


# ================================================================ Netzschau

## Obergrenzen aus dem Plan (Level 01, Abschnitt 9 und 18).
const NETZ_FLAECHEN_MAX := 3
const NAHE_BAEUME_DREIECKE_MAX := 3000
const NETZ_RAND := 0.6

var _abweichungen := 0


func _netzschau() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var kamera := Camera3D.new()
	kamera.fov = 50.0
	kamera.far = 200.0
	add_child(kamera)
	kamera.current = true
	# VRAM: erst die leere Szene, dann nur die Netze samt Stoffen – der
	# Zuwachs ist das, was `netz()` selbst kostet (Moosmuster, Muster der
	# Materialbibliothek, Scheitelpuffer, dazu das kleine Prüfmodell).
	# Himmel, Boden und Schilder kommen erst danach.
	for f in 4:
		await get_tree().process_frame
	var textur_vorher := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var puffer_vorher := Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)
	var zeit := Time.get_ticks_msec()

	_pruefmodell_testen()
	var reihen := _netz_reihen()
	var anzahl := 0
	for reihe in reihen:
		anzahl += (reihe["eintraege"] as Array).size()
	print("Netzschau: %d Modelle in %d Reihen, natur2: %d Dateien, gebaut in %d ms" % [
		anzahl, reihen.size(), Fremdmodelle.natur2_modelle().size(),
		Time.get_ticks_msec() - zeit])
	if Fremdmodelle.natur2_modelle().is_empty():
		print("  natur2 ist leer – die Rollen zeigen ihre Kenney-Rückfälle, der Rest baut prozedural")

	if headless:
		print("=== %d Abweichungen ===" % _abweichungen)
		get_tree().quit(1 if _abweichungen > 0 else 0)
		return

	var mass := _reihen_aufstellen(reihen)
	for f in 4:
		await get_tree().process_frame
	var textur_netz := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var puffer_netz := Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)
	print("VRAM der Netze samt Stoffen: Texturen +%.2f MB, Puffer +%.2f MB" % [
		(textur_netz - textur_vorher) / 1048576.0, (puffer_netz - puffer_vorher) / 1048576.0])
	_schilder(reihen)
	_waldlicht()
	var streu_mitte := Vector3(0.0, 0.0, mass.y - 16.0)
	_streuen(reihen, streu_mitte)
	_waldboden(Vector3(0.0, 0.0, streu_mitte.z * 0.5),
			Vector2(maxf(mass.x, 26.0) + 12.0, absf(streu_mitte.z) + 36.0))

	var ausgabe := OS.get_environment("MODELLSCHAU_BILD")
	if ausgabe.is_empty():
		ausgabe = "/tmp/modellschau.png"
	var stamm := ausgabe.get_basename()

	# 1. Übersicht: alle Reihen von schräg vorn oben.
	var mitte := Vector3(0.0, 0.3, mass.y * 0.5)
	var weg := maxf(mass.x * 0.75, absf(mass.y) * 1.05) + 1.5
	kamera.position = mitte + Vector3(0.0, weg * 0.55, weg * 0.8)
	kamera.look_at(mitte, Vector3.UP)
	if _bild_gewuenscht("uebersicht"):
		await _foto(ausgabe)
	# 2. Streuung aus der Spielkamera: 6 m hoch, 9,5 m zurück, Blick 6 m voraus.
	kamera.position = streu_mitte + Vector3(0.0, 6.0, 9.5)
	kamera.look_at(streu_mitte + Vector3(0.0, 1.0, -6.0), Vector3.UP)
	if _bild_gewuenscht("streu"):
		await _foto(stamm + "_streu.png")
	# 3. und 4. Nah an die harten Flächen und an Laub und Akzente.
	var nah := _nahziel(reihen, ["M8", "M16"])
	kamera.position = nah + Vector3(0.4, 1.7, 3.6)
	kamera.look_at(nah + Vector3(0.0, 0.4, 0.0), Vector3.UP)
	if _bild_gewuenscht("nah"):
		await _foto(stamm + "_nah.png")
	nah = _nahziel(reihen, ["M11", "M14", "M18"])
	kamera.position = nah + Vector3(0.3, 1.5, 3.4)
	kamera.look_at(nah + Vector3(0.0, 0.35, -0.3), Vector3.UP)
	if _bild_gewuenscht("laub"):
		await _foto(stamm + "_laub.png")
	# Das Moosmuster ohne Alpha (der trägt nur die Fleckmaske).
	var moos := Fremdmodelle.moos_bild()
	moos.clear_mipmaps()
	moos.convert(Image.FORMAT_RGB8)
	moos.save_png(stamm + "_moosmuster.png")

	print("=== %d Abweichungen ===" % _abweichungen)
	get_tree().quit(1 if _abweichungen > 0 else 0)


## MODELLSCHAU_BILDER=nah,laub rendert nur diese (uebersicht, streu, nah,
## laub) – unter Software-GL kostet jedes Bild eine halbe Minute.
func _bild_gewuenscht(name: String) -> bool:
	var liste := OS.get_environment("MODELLSCHAU_BILDER")
	return liste.is_empty() or name in liste.split(",")


func _foto(pfad: String) -> void:
	for f in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pfad)
	print("Bild: %s" % pfad)


## Reihen: je Rolle, was sie heute bekommt, dann die natur2-Modelle ohne
## Rolle. Jeder Eintrag trägt das fertige Netz und ist schon geprüft.
func _netz_reihen() -> Array[Dictionary]:
	var nur := OS.get_environment("MODELLSCHAU_NUR")
	var erlaubt := PackedStringArray()
	if not nur.is_empty():
		for e in nur.split(","):
			erlaubt.append(e.strip_edges())
	var reihen: Array[Dictionary] = []
	var gezeigt := {}
	for kennung: String in Fremdmodelle.ROLLEN:
		var eintrag: Dictionary = Fremdmodelle.ROLLEN[kennung]
		var liste: Array[Dictionary] = []
		var optionen := Fremdmodelle.rolle_optionen(kennung)
		for name in Fremdmodelle.rolle(kennung):
			if not erlaubt.is_empty() and not erlaubt.has(name) \
					and not erlaubt.has(name.get_file()):
				continue
			var fertig := Fremdmodelle.netz(name, optionen)
			_netz_pruefen(name, kennung, fertig, float(optionen.get("hoehe", 0.0)))
			if not fertig.is_empty():
				liste.append({"name": name, "netz": fertig})
			gezeigt[name] = true
		if not liste.is_empty():
			reihen.append({"titel": "%s %s" % [kennung, String(eintrag["name"])],
				"kennung": kennung, "eintraege": liste})
		elif erlaubt.is_empty():
			print("  %-4s %-26s → prozeduraler Rückfall (kein Modell vorhanden)" % [
				kennung, String(eintrag["name"])])
	var rest: Array[Dictionary] = []
	for name in Fremdmodelle.natur2_modelle():
		if gezeigt.has(name):
			continue
		if not erlaubt.is_empty() and not erlaubt.has(name) and not erlaubt.has(name.get_file()):
			continue
		var fertig := Fremdmodelle.netz(name, {"groesse": 1.6})
		_netz_pruefen(name, "–", fertig, 0.0)
		if not fertig.is_empty():
			rest.append({"name": name, "netz": fertig})
	if not rest.is_empty():
		reihen.append({"titel": "natur2 ohne Rolle", "kennung": "", "eintraege": rest})
	if OS.get_environment("MODELLSCHAU_PRUEF") != "0":
		var baum := _pruefmodell()
		var pruef := Fremdmodelle.netz_aus(baum, {"hoehe": 2.6, "wind": 0.05}, "Pruefmodell")
		baum.free()
		reihen.append({"titel": "Prüfmodell (Textur, unbeleuchtet, Alpha)", "kennung": "",
			"eintraege": [{"name": "Prüfmodell", "netz": pruef}]})
	return reihen


## Prüft ein Netz gegen die Abnahme: höchstens drei Flächen, alle
## beleuchtet, nahe Bäume höchstens 3k Dreiecke.
func _netz_pruefen(name: String, kennung: String, fertig: Dictionary, hoehe: float) -> void:
	if fertig.is_empty():
		print("  FEHLT: %s (%s)" % [name, kennung])
		_abweichungen += 1
		return
	var flaechen: Array = fertig["flaechen"]
	var arten := PackedStringArray()
	var mangel := PackedStringArray()
	for f: Dictionary in flaechen:
		arten.append("%s%s" % [String(f["art"]), "*" if bool(f["schatten"]) else ""])
		var stoff: Material = f["material"]
		if not _beleuchtet(stoff):
			mangel.append("unbeleuchtet")
	if flaechen.size() > NETZ_FLAECHEN_MAX:
		mangel.append("%d Flächen" % flaechen.size())
	var dreiecke := int(fertig["dreiecke"])
	if kennung in ["M1", "M2", "M3"] and dreiecke > NAHE_BAEUME_DREIECKE_MAX:
		mangel.append("%d Dreiecke" % dreiecke)
	var huelle: AABB = fertig["huelle"]
	print("  %-4s %-26s %d Fl. [%s] %5d Dr.  %.2f × %.2f × %.2f m  Krone ab %.2f%s" % [
		kennung, name, flaechen.size(), ", ".join(arten), dreiecke,
		huelle.size.x, huelle.size.y, huelle.size.z, float(fertig["krone_unten"]),
		"" if mangel.is_empty() else "  FEHLER: " + ", ".join(mangel)])
	if not mangel.is_empty():
		_abweichungen += 1
	if hoehe > 0.0 and absf(huelle.size.y - hoehe) > 0.01:
		print("    FEHLER: Höhe %.2f statt %.2f" % [huelle.size.y, hoehe])
		_abweichungen += 1
	if absf(huelle.position.y) > 0.001:
		print("    FEHLER: Fuß bei %.3f statt 0" % huelle.position.y)
		_abweichungen += 1


func _beleuchtet(stoff: Material) -> bool:
	if stoff == null:
		return false
	var standard := stoff as BaseMaterial3D
	if standard != null:
		return standard.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED
	var shader := stoff as ShaderMaterial
	if shader != null and shader.shader != null:
		return not shader.shader.code.contains("unshaded")
	return false


# ------------------------------------------------------------ Prüfmodell

## Ein Baum aus Godot-Grundkörpern, gebaut wie eine texturierte Paketdatei:
## Stamm mit UNBELEUCHTETEM Rindenmaterial und UV-Textur, Krone aus
## gekreuzten Blattkarten mit Alphaschnitt in einem skalierten, gedrehten
## Unterknoten, dazu einfarbige Blüten und ein Gliederknoten mit Spiegelung.
## Deckt ab, was die Kenney-Dateien nicht haben.
func _pruefmodell() -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Pruefmodell"
	var stamm := MeshInstance3D.new()
	var zylinder := CylinderMesh.new()
	zylinder.top_radius = 0.1
	zylinder.bottom_radius = 0.17
	zylinder.height = 1.7
	stamm.mesh = zylinder
	stamm.position = Vector3(0.0, 0.85, 0.0)
	var borke := StandardMaterial3D.new()
	borke.resource_name = "Bark_Pruef"
	borke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	borke.albedo_texture = _pruefbild(false)
	stamm.material_override = borke
	wurzel.add_child(stamm)

	var krone := Node3D.new()
	krone.position = Vector3(0.0, 1.75, 0.0)
	krone.rotation = Vector3(0.0, 0.4, 0.0)
	krone.scale = Vector3(1.3, 1.1, 1.3)
	wurzel.add_child(krone)
	var blatt := StandardMaterial3D.new()
	blatt.resource_name = "Leaves_Pruef"
	blatt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blatt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	blatt.alpha_scissor_threshold = 0.45
	blatt.cull_mode = BaseMaterial3D.CULL_DISABLED
	blatt.albedo_texture = _pruefbild(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 9:
		var karte := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.1, 0.9)
		karte.mesh = quad
		karte.material_override = blatt
		karte.position = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.25, 0.45),
				rng.randf_range(-0.35, 0.35))
		karte.rotation = Vector3(rng.randf_range(-0.6, 0.6), float(i) * PI / 4.5,
				rng.randf_range(-0.3, 0.3))
		krone.add_child(karte)
	# Gespiegelter Ast: negative Skalierung muss die Dreiecke umdrehen.
	var ast := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.08, 0.08)
	ast.mesh = box
	ast.material_override = borke
	ast.position = Vector3(-0.3, 1.25, 0.0)
	ast.rotation = Vector3(0.0, 0.0, 0.5)
	ast.scale = Vector3(-1.0, 1.0, 1.0)
	wurzel.add_child(ast)
	var bluete := StandardMaterial3D.new()
	bluete.resource_name = "Flower_Pruef"
	bluete.albedo_color = Color(0.85, 0.35, 0.55)
	for i in 5:
		var punkt := MeshInstance3D.new()
		var kugel := SphereMesh.new()
		kugel.radius = 0.07
		kugel.height = 0.14
		kugel.radial_segments = 8
		kugel.rings = 4
		punkt.mesh = kugel
		punkt.material_override = bluete
		var winkel := float(i) * TAU / 5.0
		punkt.position = Vector3(cos(winkel) * 0.55, 1.6 + 0.15 * sin(winkel * 2.0),
				sin(winkel) * 0.55)
		wurzel.add_child(punkt)
	return wurzel


## Rindenstreifen (RGB) bzw. Blattflecken mit Löchern (RGBA).
func _pruefbild(mit_alpha: bool) -> ImageTexture:
	var k := 64
	var bild := Image.create(k, k, false, Image.FORMAT_RGBA8)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5 if mit_alpha else 6
	rauschen.frequency = 0.12
	for y in k:
		for x in k:
			var r := rauschen.get_noise_2d(float(x), float(y) * (0.35 if not mit_alpha else 1.0))
			if mit_alpha:
				var blatt := 0.5 + 0.5 * r
				bild.set_pixel(x, y, Color(0.30 + 0.2 * blatt, 0.62 + 0.25 * blatt, 0.22,
						1.0 if blatt > 0.42 else 0.0))
			else:
				var furche := 0.5 + 0.5 * r
				bild.set_pixel(x, y, Color(0.42 * furche + 0.18, 0.30 * furche + 0.12,
						0.20 * furche + 0.08, 1.0))
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Rechnet nach, dass `netz_aus` den Knotenbaum richtig verschmilzt:
## Lage eingebacken (Hülle wie die des Baums), Flächen je Art, alles
## beleuchtet, Alphaschnitt übernommen, Spiegelung gedreht, Vereinfachen.
func _pruefmodell_testen() -> void:
	var baum := _pruefmodell()
	var roh := _echte_huelle(baum, Transform3D.IDENTITY, [])
	var fertig := Fremdmodelle.netz_aus(baum, {}, "Pruefmodell")
	var fehler := PackedStringArray()
	if fertig.is_empty():
		fehler.append("kein Netz")
	else:
		var huelle: AABB = fertig["huelle"]
		if (huelle.size - roh.size).length() > 0.01:
			fehler.append("Hülle %s statt %s" % [str(huelle.size), str(roh.size)])
		if absf(huelle.position.y) > 0.001:
			fehler.append("Fuß bei %.3f statt 0" % huelle.position.y)
		var flaechen: Array = fertig["flaechen"]
		var arten := PackedStringArray()
		for f: Dictionary in flaechen:
			arten.append(String(f["art"]))
			if not _beleuchtet(f["material"] as Material):
				fehler.append("%s unbeleuchtet" % String(f["art"]))
		if ", ".join(arten) != "hart, laub, akzent":
			fehler.append("Flächen [%s] statt [hart, laub, akzent]" % ", ".join(arten))
		if flaechen.size() == 3:
			var laub := (flaechen[1] as Dictionary)["material"] as ShaderMaterial
			if not laub.shader.code.contains("ALPHA_SCISSOR_THRESHOLD = schnitt"):
				fehler.append("Blattkarten ohne Alphaschnitt")
			elif absf(float(laub.get_shader_parameter("schnitt")) - 0.45) > 0.001:
				fehler.append("Alphaschwelle %.2f statt 0,45"
						% float(laub.get_shader_parameter("schnitt")))
			var hart := (flaechen[0] as Dictionary)["material"] as ShaderMaterial
			if not bool(hart.get_shader_parameter("grund_ist_farbe")):
				fehler.append("Rindentextur nicht übernommen")
			if not bool((flaechen[0] as Dictionary)["schatten"]) \
					or bool((flaechen[1] as Dictionary)["schatten"]):
				fehler.append("Schattenregel verletzt")
		if not _dreiecke_zeigen_nach_aussen(fertig["mesh"] as ArrayMesh):
			fehler.append("Dreiecke verdreht (Spiegelung)")
		var krone := float(fertig["krone_unten"])
		if krone < 0.8 or krone > 1.7:
			fehler.append("Krone ab %.2f (erwartet 0,8–1,7)" % krone)
	# Vereinfachen: eine dichte Kugel auf ein Viertel.
	var kugel := MeshInstance3D.new()
	var dicht := SphereMesh.new()
	dicht.radial_segments = 96
	dicht.rings = 48
	kugel.mesh = dicht
	var blattstoff := StandardMaterial3D.new()
	blattstoff.resource_name = "Leaves_Dicht"
	kugel.material_override = blattstoff
	var voll := Fremdmodelle.netz_aus(kugel, {}, "Dicht")
	var duenn := Fremdmodelle.netz_aus(kugel, {"max_dreiecke": int(voll["dreiecke"]) / 4},
			"Dicht")
	print("Prüfmodell: Vereinfachen %d → %d Dreiecke (Ziel %d)" % [int(voll["dreiecke"]),
		int(duenn["dreiecke"]), int(voll["dreiecke"]) / 4])
	if int(duenn["dreiecke"]) > int(voll["dreiecke"]) / 2:
		fehler.append("Vereinfachen wirkt nicht")
	kugel.free()
	baum.free()
	if fehler.is_empty():
		print("Prüfmodell: verschmolzen richtig (Hülle, Flächen, Licht, Alpha, Spiegelung)")
	else:
		print("Prüfmodell: FEHLER " + "; ".join(fehler))
		_abweichungen += 1


## Die Hülle über alle Scheitel, unabhängig von `Fremdmodelle` gerechnet
## (die Hüllen der Netze wären nach dem Drehen zu groß).
func _echte_huelle(knoten: Node, bis_hier: Transform3D, stand: Array) -> AABB:
	var mi := knoten as MeshInstance3D
	var huelle: AABB = stand[0] if not stand.is_empty() else AABB()
	if mi != null and mi.mesh != null:
		for s in mi.mesh.get_surface_count():
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for p in v:
				var q := bis_hier * p
				if stand.is_empty():
					huelle = AABB(q, Vector3.ZERO)
					stand.append(huelle)
				else:
					huelle = huelle.expand(q)
					stand[0] = huelle
	for kind in knoten.get_children():
		var raum := kind as Node3D
		var weiter := bis_hier * raum.transform if raum != null else bis_hier
		huelle = _echte_huelle(kind, weiter, stand)
	return stand[0] if not stand.is_empty() else huelle


## Stichprobe der Wicklung: Bei einem geschlossenen Körper um den Ursprung
## zeigt die Flächennormale (Godot: Vorderseite im Uhrzeigersinn) im Mittel
## nach außen, und die gespeicherten Normalen stimmen mit ihr überein.
func _dreiecke_zeigen_nach_aussen(netz: ArrayMesh) -> bool:
	var falsch := 0
	var gesamt := 0
	for s in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var i: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if netz.surface_get_name(s) != "hart":
			continue
		for t in range(0, i.size() - 2, 3):
			var flaeche := (v[i[t + 2]] - v[i[t]]).cross(v[i[t + 1]] - v[i[t]])
			var gespeichert := n[i[t]] + n[i[t + 1]] + n[i[t + 2]]
			gesamt += 1
			if flaeche.dot(gespeichert) < 0.0:
				falsch += 1
	return gesamt > 0 and falsch * 20 < gesamt


# ------------------------------------------------------------ Aufstellung

const NETZ_REIHEN_ABSTAND := 3.4


## Stellt die Reihen in zwei Spalten auf: jede Reihe quer (x), die Reihen
## nach hinten (−z). Gibt Breite (x) und Tiefe (y, negativ) zurück.
func _reihen_aufstellen(reihen: Array[Dictionary]) -> Vector2:
	var spalte_breite := 0.0
	for reihe in reihen:
		spalte_breite = maxf(spalte_breite, _reihenbreite(reihe))
	var spalten := 2 if reihen.size() > 3 else 1
	var z := [0.0, 0.0]
	var tiefste := 0.0
	for r in reihen.size():
		var reihe := reihen[r]
		var sp := r % spalten
		var mitte_x := (float(sp) - float(spalten - 1) * 0.5) * (spalte_breite + 2.5)
		var eintraege: Array = reihe["eintraege"]
		var breite := _reihenbreite(reihe)
		var x := mitte_x - breite * 0.5
		var tiefe := 0.0
		for e: Dictionary in eintraege:
			var netz: Dictionary = e["netz"]
			var huelle: AABB = netz["huelle"]
			var halter := Node3D.new()
			halter.position = Vector3(x + maxf(huelle.size.x, 0.3) * 0.5 - huelle.get_center().x,
					0.0, float(z[sp]) - huelle.get_center().z)
			add_child(halter)
			_netz_zeigen(halter, netz)
			e["halter"] = halter
			x += maxf(huelle.size.x, 0.3) + NETZ_RAND
			tiefe = maxf(tiefe, huelle.size.z)
		reihe["mitte"] = Vector3(mitte_x, 0.0, float(z[sp]))
		reihe["links"] = mitte_x - breite * 0.5
		z[sp] = float(z[sp]) - maxf(NETZ_REIHEN_ABSTAND, tiefe + 1.4)
		tiefste = minf(tiefste, float(z[sp]))
	return Vector2(float(spalten) * (spalte_breite + 2.5), tiefste)


func _reihenbreite(reihe: Dictionary) -> float:
	var breite := 0.0
	for e: Dictionary in reihe["eintraege"]:
		var huelle: AABB = (e["netz"] as Dictionary)["huelle"]
		breite += maxf(huelle.size.x, 0.3) + NETZ_RAND
	return breite


## Namen und Dreieckszahlen über die Modelle, Rollen links der Reihe.
func _schilder(reihen: Array[Dictionary]) -> void:
	for reihe in reihen:
		for e: Dictionary in reihe["eintraege"]:
			var netz: Dictionary = e["netz"]
			var huelle: AABB = netz["huelle"]
			var schild := Label3D.new()
			schild.text = "%s\n%d Dr." % [String(e["name"]).get_file(), int(netz["dreiecke"])]
			schild.font_size = 36
			schild.pixel_size = 0.003
			schild.position = Vector3(huelle.get_center().x, huelle.end.y + 0.25,
					huelle.get_center().z)
			schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			(e["halter"] as Node3D).add_child(schild)
		var titel := Label3D.new()
		titel.text = String(reihe["titel"])
		titel.font_size = 40
		titel.pixel_size = 0.0035
		titel.modulate = Color(1.0, 0.92, 0.7)
		titel.position = Vector3(float(reihe["links"]) - 0.3, 0.2,
				(reihe["mitte"] as Vector3).z)
		titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		titel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(titel)


## Eine Fläche je MeshInstance3D, Schatten nach der Fläche (so wie der
## Streuer es mit MultiMeshes macht).
func _netz_zeigen(eltern: Node3D, netz: Dictionary) -> void:
	for f: Dictionary in netz["flaechen"]:
		var mi := MeshInstance3D.new()
		mi.mesh = f["mesh"]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(f["schatten"]) \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eltern.add_child(mi)


## Eine Waldbodenfläche, auf die jede Rolle als MultiMesh gestreut wird:
## Scheitelfarbe je Instanz, Drehung und Größe gestreut – so sieht das Level
## die Modelle.
func _streuen(reihen: Array[Dictionary], mitte: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var mengen := {"M8": 10, "M9": 40, "M11": 16, "M14": 40, "M16": 5, "M18": 18}
	for reihe in reihen:
		var kennung := String(reihe["kennung"])
		if kennung.is_empty():
			continue
		var menge := int(mengen.get(kennung, 6))
		var eintraege: Array = reihe["eintraege"]
		for e: Dictionary in eintraege:
			var netz: Dictionary = e["netz"]
			var lagen: Array[Transform3D] = []
			var farben: Array[Color] = []
			var stueck := maxi(1, menge / eintraege.size())
			for i in stueck:
				var ort := mitte + Vector3(rng.randf_range(-11.0, 11.0), 0.0,
						rng.randf_range(-16.0, 7.0))
				# Die Mitte bleibt frei: dort liegt der Weg.
				if absf(ort.x - mitte.x) < 2.2:
					ort.x += 4.4 * signf(ort.x - mitte.x + 0.01)
				var groesse := rng.randf_range(0.7, 1.35)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * groesse)
				lagen.append(Transform3D(basis, ort + Vector3(0.0, -0.04 * groesse, 0.0)))
				var hell := rng.randf_range(0.88, 1.1)
				farben.append(Color(hell, hell * rng.randf_range(0.96, 1.04), hell, 1.0))
			for f: Dictionary in netz["flaechen"]:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.use_colors = true
				mm.mesh = f["mesh"]
				mm.instance_count = lagen.size()
				for i in lagen.size():
					mm.set_instance_transform(i, lagen[i])
					mm.set_instance_color(i, farben[i])
				var mmi := MultiMeshInstance3D.new()
				mmi.multimesh = mm
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
						if bool(f["schatten"]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mmi)


func _nahziel(reihen: Array[Dictionary], kennungen: Array) -> Vector3:
	for reihe in reihen:
		if String(reihe["kennung"]) in kennungen:
			return reihe.get("mitte", Vector3.ZERO) as Vector3
	return Vector3.ZERO


## Licht und Umgebung wie in Level01.tscn: Sonne 68°, warm; kühle
## Umgebung; Tiefennebel; ACES.
func _waldlicht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.transform = Transform3D(Basis(Vector3(0.965926, 0.0, -0.258819),
			Vector3(-0.239973, 0.374607, -0.895591), Vector3(0.096955, 0.927184, 0.361842)),
			Vector3(0.0, 30.0, 0.0))
	sonne.light_color = Color(1.0, 0.93, 0.8)
	sonne.light_energy = 0.6
	sonne.light_specular = 0.2
	sonne.shadow_enabled = true
	sonne.shadow_bias = 0.04
	sonne.shadow_normal_bias = 1.5
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sonne.directional_shadow_max_distance = 70.0
	sonne.directional_shadow_split_1 = 0.25
	add_child(sonne)
	var himmel := ShaderMaterial.new()
	himmel.shader = load("res://shaders/himmel.gdshader") as Shader
	himmel.set_shader_parameter("zenit", Color(0.24, 0.46, 0.74))
	himmel.set_shader_parameter("horizont", Color(0.7, 0.8, 0.84))
	himmel.set_shader_parameter("dunst", Color(0.42, 0.52, 0.46))
	himmel.set_shader_parameter("boden", Color(0.17, 0.24, 0.19))
	var sky := Sky.new()
	sky.sky_material = himmel
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	var welt := Environment.new()
	welt.background_mode = Environment.BG_SKY
	welt.sky = sky
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.4, 0.5, 0.7)
	welt.ambient_light_energy = 0.4
	welt.tonemap_mode = Environment.TONE_MAPPER_ACES
	welt.tonemap_exposure = 0.95
	welt.tonemap_white = 6.0
	welt.fog_enabled = true
	welt.fog_mode = Environment.FOG_MODE_DEPTH
	welt.fog_light_color = Color(0.42, 0.52, 0.46)
	welt.fog_sun_scatter = 1.6
	welt.fog_density = 0.9
	welt.fog_sky_affect = 0.0
	welt.fog_depth_curve = 1.1
	welt.fog_depth_begin = 12.0
	welt.fog_depth_end = 140.0
	var umgebung := WorldEnvironment.new()
	umgebung.environment = welt
	add_child(umgebung)


func _waldboden(mitte: Vector3, groesse: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = groesse
	# Gedeckter als der Waldboden des alten Levels, damit die Farben der
	# Modelle nicht gegen Orange beurteilt werden. Die geteilte Vorlage
	# bleibt unverändert.
	var boden := Materialbibliothek.waldboden().duplicate() as StandardMaterial3D
	boden.albedo_color = Color(0.62, 0.7, 0.52)
	ebene.material = boden
	mi.mesh = ebene
	mi.position = mitte
	add_child(mi)
