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
	# Eine bestimmte Datei prüfen: MODELLTEST_DATEI=meinmodell.glb
	# Gesucht wird in beiden Ordnern. Sagt im Klartext, ob und warum nicht.
	var einzeln := OS.get_environment("MODELLTEST_DATEI")
	if not einzeln.is_empty():
		_eine_datei_pruefen(einzeln)
		get_tree().quit(0)
		return

	_mitgelieferte_pruefen()
	_materialnamen("res://assets/modelle/gegner/kaefer.glb")

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

	# --- 4. Weg über die Rohdaten (so kommt es im Browser herein) ---
	var roh := FileAccess.get_file_as_bytes(ziel)
	var uebernahme := Einstellungen.uebernehmen_daten("hochgeladen.glb", roh)
	if uebernahme.is_empty():
		var geprueft := ModellLader.laden(
				Einstellungen.ORDNER.path_join("hochgeladen.glb"), 1.0)
		print("  Rohdaten übernommen (%d Bytes) und geladen: %s"
				% [roh.size(), "ja" if geprueft != null else "NEIN"])
		if geprueft != null:
			geprueft.queue_free()
		DirAccess.remove_absolute(Einstellungen.ORDNER.path_join("hochgeladen.glb"))
	else:
		print("  FEHLER beim Übernehmen der Rohdaten: %s" % uebernahme)
	Einstellungen.waehle_modell("pruefling.glb")

	# --- 5. Weg über die Spielfigur ---
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


## Zeigt, unter welchem Namen Godot die Materialien einer Datei führt.
## Genau diese Namen brauchen die Umfärbungen in `fremdmodell()`.
func _materialnamen(pfad: String) -> void:
	if not ResourceLoader.exists(pfad):
		print("  %s ist nicht importiert" % pfad)
		return
	var szene := (load(pfad) as PackedScene).instantiate()
	print("  Materialien in %s:" % pfad.get_file())
	_materialnamen_von(szene)
	szene.queue_free()


func _materialnamen_von(knoten: Node) -> void:
	var netz := knoten as MeshInstance3D
	if netz != null and netz.mesh != null:
		for i in netz.mesh.get_surface_count():
			var m := netz.mesh.surface_get_material(i)
			if m != null:
				print("    '%s'  Farbe=%s" % [m.resource_name,
						str((m as StandardMaterial3D).albedo_color)
						if m is StandardMaterial3D else "-"])
	for kind in knoten.get_children():
		_materialnamen_von(kind)


## Prüft eine einzelne Datei in beiden Modellordnern und sagt, woran es
## liegt, wenn sie nicht angezeigt wird.
func _eine_datei_pruefen(name: String) -> void:
	print("=== Prüfung: %s ===" % name)
	var ordner_liste: Array[String] = [Einstellungen.MITGELIEFERT, Einstellungen.ORDNER]
	for ordner in ordner_liste:
		var pfad: String = ordner.path_join(name)
		var da := FileAccess.file_exists(pfad)
		var importiert := ResourceLoader.exists(pfad)
		print("  %s" % ordner)
		print("    Datei liegt dort: %s" % ("ja" if da else "nein"))
		if not da:
			continue
		if ordner.begins_with("res://") and not importiert:
			print("    importiert:       NEIN  <-- deshalb wird sie nicht angezeigt")
			print("    Abhilfe:          godot --headless --path . --import")
			continue
		var figur := ModellLader.laden(pfad, 1.0)
		if figur == null:
			print("    ladbar:           NEIN  (%s)" % ModellLader.letzter_fehler)
			continue
		var huelle := ModellLader.huelle_von(figur)
		print("    ladbar:           ja, %d Netze, eingepasst auf %.2f × %.2f × %.2f m"
				% [_netze(figur), huelle.size.x * figur.scale.x,
				huelle.size.y * figur.scale.y, huelle.size.z * figur.scale.z])
		_clips_pruefen(figur)
		figur.queue_free()
	print("  Auswählbar im Spiel unter Einstellungen -> Figur:")
	print("    %s" % str(Einstellungen.modelle()))


## Gleicht die Clips einer Figur gegen den Standard ab.
## Der Satz steht in assets/modelle/LIESMICH.md.
const SOLL_CLIPS := [
	["idlepose", "Ruhepose", false],
	["idle", "steht still", true],
	["walkslow", "schlendert", true],
	["walk", "geht", true],
	["run", "rennt", true],
	["jump", "springt", false],
	["slide", "rutscht", false],
	["spin", "dreht sich", true],
	["sit", "sitzt im Kart", true],
	["ride", "reitet", true],
	["crawl", "krabbelt", true],
	["hang", "haengt am Gitter", true],
	["hangduck", "haengt mit angezogenen Beinen", true],
	["hangspin", "dreht sich im Haengen", true],
]


func _clips_pruefen(figur: Node3D) -> void:
	var spieler := ModellLader.spieler_von(figur)
	if spieler == null:
		print("    Animationen:      keine (die Figur wird nur als Ganzes bewegt)")
		return
	print("    Clips in der Datei: %s" % str(spieler.get_animation_list()))
	var fehlend: Array[String] = []
	for eintrag: Array in SOLL_CLIPS:
		var wunsch := String(eintrag[0])
		var treffer := ModellLader.clip_fuer(spieler, wunsch)
		if treffer.is_empty():
			fehlend.append(wunsch)
			print("      %-10s FEHLT   (%s)" % [wunsch, eintrag[1]])
			continue
		var anim := spieler.get_animation(treffer)
		var laeuft_endlos := anim.loop_mode != Animation.LOOP_NONE
		var soll_endlos := bool(eintrag[2])
		var hinweis := ""
		if laeuft_endlos != soll_endlos:
			# Kein Fehler: Das Spiel setzt die Schleife beim Laden selbst.
			# Sauberer ist es trotzdem, sie gleich richtig auszugeben.
			hinweis = "  (Schleife wird beim Laden auf %s gesetzt)" % (
					"an" if soll_endlos else "aus")
		print("      %-10s -> '%s'  %.2f s, %d Spuren%s"
				% [wunsch, treffer, anim.length, anim.get_track_count(), hinweis])
	if fehlend.is_empty():
		print("    Alle vierzehn Standardclips vorhanden.")
	else:
		print("    %d von 11 fehlen – dafür greift die Ersatzbewegung."
				% fehlend.size())


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
