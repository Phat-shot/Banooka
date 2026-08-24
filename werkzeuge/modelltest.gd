extends Node
## Prüft den Weg für eigene glTF-Figuren von Ende zu Ende.
##
## Erzeugt eine kleine Testfigur, schreibt sie als .glb in den
## Modellordner und lädt sie über `ModellLader` wieder ein. Damit lässt
## sich trennen, ob ein Problem am Lader liegt oder an der Datei bzw. am
## Gerät. Die erzeugte Datei taugt zugleich als bekannt gute Probe, mit
## der man die APK gegentesten kann.
##
##   godot --headless --path . res://werkzeuge/Modelltest.tscn

func _ready() -> void:
	print("=== Modelltest ===")
	# Schritt 1 legt die Probefigur ins Projekt; danach muss einmal
	# importiert werden, bevor Schritt 2 sie als Ressource findet.
	if OS.get_environment("MODELLTEST") == "schreiben":
		_probe_ins_projekt()
		get_tree().quit(0)
		return
	_mitgelieferte_pruefen()

	var ordner := Einstellungen.ORDNER
	DirAccess.make_dir_recursive_absolute(ordner)
	var ziel := ordner.path_join("pruefling.glb")

	# --- 1. Testfigur bauen und als glb schreiben ---
	var figur := _testfigur()
	var papier := GLTFDocument.new()
	var zustand := GLTFState.new()
	var fehler := papier.append_from_scene(figur, zustand)
	if fehler != OK:
		print("FEHLER: append_from_scene = %d" % fehler)
		get_tree().quit(1)
		return
	fehler = papier.write_to_filesystem(zustand, ziel)
	if fehler != OK:
		print("FEHLER: write_to_filesystem = %d" % fehler)
		get_tree().quit(1)
		return
	var groesse := FileAccess.open(ziel, FileAccess.READ).get_length()
	print("  geschrieben: %s (%d Bytes)" % [ziel, groesse])
	print("  echter Ort:  %s" % ProjectSettings.globalize_path(ziel))

	# --- 2. Über den Lader zurückholen ---
	var geladen := ModellLader.laden(ziel, 1.0)
	if geladen == null:
		print("FEHLER: ModellLader.laden() gab null zurück")
		get_tree().quit(1)
		return
	add_child(geladen)
	var huelle := ModellLader.huelle_von(geladen)
	print("  geladen: %d Kindknoten, Netze=%d" % [
			geladen.get_child_count(), _netze(geladen)])
	print("  Hülle nach Einpassung: %.2f × %.2f × %.2f m"
			% [huelle.size.x * geladen.scale.y, huelle.size.y * geladen.scale.y,
			huelle.size.z * geladen.scale.y])

	# --- 3. Auswahl über die Einstellungen ---
	Einstellungen.waehle_modell("pruefling.glb")
	print("  Einstellungen.modell_pfad() = '%s'" % Einstellungen.modell_pfad())
	print("  gefundene Modelle: %s" % str(Einstellungen.modelle()))

	# --- 4. Weg über die Spielfigur ---
	var modell := SpielerModell.new()
	add_child(modell)
	await get_tree().process_frame
	var eigenes := modell.get_node_or_null("Teile/EigeneFigur")
	print("  SpielerModell nutzt eigene Figur: %s"
			% ("ja" if eigenes != null else "NEIN – es baut den Beuteldachs"))

	Einstellungen.waehle_modell("")
	print("=== Modelltest fertig ===")
	get_tree().quit(0)


## Schreibt die Probefigur nach res://assets/modelle. Geht nur, solange
## aus den Quellen gespielt wird – im Export ist res:// schreibgeschützt.
func _probe_ins_projekt() -> void:
	var ziel := Einstellungen.MITGELIEFERT.path_join("pruefling.glb")
	DirAccess.make_dir_recursive_absolute(Einstellungen.MITGELIEFERT)
	var papier := GLTFDocument.new()
	var zustand := GLTFState.new()
	if papier.append_from_scene(_testfigur(), zustand) != OK:
		print("FEHLER: Probefigur ließ sich nicht aufbereiten")
		return
	if papier.write_to_filesystem(zustand, ziel) != OK:
		print("FEHLER: %s nicht schreibbar" % ziel)
		return
	print("  Probefigur geschrieben: %s" % ziel)


## Prüft die mitgelieferten Figuren – das ist der Weg, der in der APK zählt.
func _mitgelieferte_pruefen() -> void:
	var liste := Einstellungen.modelle()
	var mitgeliefert := PackedStringArray()
	for eintrag in liste:
		if eintrag.begins_with("res://"):
			mitgeliefert.append(eintrag)
	print("  mitgelieferte Figuren: %d %s" % [mitgeliefert.size(), str(mitgeliefert)])
	for eintrag in mitgeliefert:
		var da := ResourceLoader.exists(eintrag)
		var figur := ModellLader.laden(eintrag, 1.0)
		print("    %s: importiert=%s, geladen=%s%s" % [
				eintrag.get_file(), "ja" if da else "NEIN",
				"ja" if figur != null else "NEIN",
				"" if figur != null else " (%s)" % ModellLader.letzter_fehler])
		if figur != null:
			figur.queue_free()


func _netze(knoten: Node) -> int:
	var n := 1 if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh != null else 0
	for kind in knoten.get_children():
		n += _netze(kind)
	return n


## Eine schlichte Figur aus drei Kästen – Rumpf, Kopf, Fuß.
func _testfigur() -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Pruefling"
	_kasten(wurzel, "Rumpf", Vector3(0.6, 0.8, 0.4), Vector3(0.0, 0.9, 0.0),
			Color(0.85, 0.35, 0.2))
	_kasten(wurzel, "Kopf", Vector3(0.45, 0.45, 0.45), Vector3(0.0, 1.55, 0.0),
			Color(0.95, 0.75, 0.45))
	_kasten(wurzel, "Fuesse", Vector3(0.55, 0.5, 0.35), Vector3(0.0, 0.25, 0.0),
			Color(0.3, 0.25, 0.22))
	return wurzel


func _kasten(elternteil: Node3D, bezeichnung: String, groesse: Vector3,
		ort: Vector3, farbe: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	var netz := BoxMesh.new()
	netz.size = groesse
	var stoff := StandardMaterial3D.new()
	stoff.albedo_color = farbe
	netz.material = stoff
	mi.mesh = netz
	mi.position = ort
	elternteil.add_child(mi)
	mi.owner = elternteil
