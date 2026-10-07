extends Node
## Misst, wie lange ein Level zum Laden braucht – Schritt für Schritt.
##
## Gebaut für die Klage „Level lädt lange" vom Handy. Gemessen wird die
## Arbeit auf der CPU: Laden der Szene samt Skripten, Instanziieren, jeder
## Bauschritt (`LevelBasis.bauzeiten`) und der Abschluss. Headless ist der
## Renderer eine Attrappe – Grafikspeicher hochladen und Shader übersetzen
## fehlen also; was hier steht, ist GDScript- und Engine-Arbeit, und genau
## die läuft auf dem Handy (Debug-Vorlage, ein großer Kern) gut drei- bis
## fünfmal langsamer als hier.
##
##   godot --headless --path <Kopie> res://werkzeuge/Bauzeitprobe.tscn
##
## Umgebungsvariablen:
##   BAUZEIT_SZENEN     Szenen mit Komma getrennt (Vorgabe Level 01 und
##                      Portalraum)
##   BAUZEIT_REDUZIERT  1 = Handyweg (`Effekte.reduziert`), wie auf Android
##   BAUZEIT_RUNDEN     wie oft jede Szene geladen wird (Vorgabe 1). Ab der
##                      zweiten Runde zeigt sich, was ein Zwischenspeicher
##                      (statisch oder auf der Platte) spart.
##   BAUZEIT_ZEILEN     wie viele der teuersten Schritte gedruckt werden
##                      (Vorgabe 12)
##   BAUZEIT_WEGDECKE   1 = nach dem Aufbau je Stoff der Wegdecke (Shader
##                      `wegboden`) eine Zeile WEGDECKE mit Lücken und
##                      Kronenlicht-Stützstellen. Zusammen mit mehreren
##                      Szenen zeigt das, ob ein Zwischenspeicher Stoffe
##                      zwischen Leveln teilt (Baukasten Raum 1, Paket G3:
##                      `L01Boden` speichert je Art, `Wegdecke` je Schlüssel).
##
## `aufbau` reicht bis `aufbau_fertig`; im Portalraum sind das seit dem
## Rundgang auch die Bilder bis zum Ausblenden des Ladeschirms (vorher
## endete die Messung mit `_ready`).
##
## Ausgabe je Runde und Szene:
##   BAUZEIT <szene> runde <n>: laden <ms>  instanz <ms>  aufbau <ms>  gesamt <ms>
## und darunter die teuersten Schritte.

const VORGABE := "res://scenes/levels/Level01.tscn,res://scenes/hub/Hub.tscn"


func _ready() -> void:
	if OS.get_environment("BAUZEIT_REDUZIERT") == "1":
		Effekte.reduziert = true
	var szenen := OS.get_environment("BAUZEIT_SZENEN")
	if szenen.is_empty():
		szenen = VORGABE
	var runden := maxi(1, int(OS.get_environment("BAUZEIT_RUNDEN"))) \
			if OS.get_environment("BAUZEIT_RUNDEN").is_valid_int() else 1
	var zeilen := int(OS.get_environment("BAUZEIT_ZEILEN")) \
			if OS.get_environment("BAUZEIT_ZEILEN").is_valid_int() else 12
	print("Bauzeitprobe: reduziert=%s" % str(Effekte.reduziert))
	for runde in runden:
		for pfad in szenen.split(","):
			await _messe(pfad.strip_edges(), runde + 1, zeilen)
	get_tree().quit(0)


func _messe(pfad: String, runde: int, zeilen: int) -> void:
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	if nummer.is_valid_int():
		Spielfluss.aktuelles_level = int(nummer)
	var t0 := Time.get_ticks_usec()
	var paket := load(pfad) as PackedScene
	var t1 := Time.get_ticks_usec()
	if paket == null:
		print("FEHLER: %s nicht ladbar" % pfad)
		return
	var szene := paket.instantiate()
	var t2 := Time.get_ticks_usec()
	var fertig := [false]
	if szene.has_signal("aufbau_fertig"):
		szene.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(szene)
	var t3 := Time.get_ticks_usec()
	var bilder := 0
	while not fertig[0] and bilder < 2000:
		bilder += 1
		await get_tree().process_frame
	var t4 := Time.get_ticks_usec()
	var summe := 0.0
	var liste: Array[Dictionary] = []
	# Level und Portalraum führen `bauzeiten` (der Portalraum: Aufbau und
	# Vorwärmen, das headless nur aus den Bildern danach besteht).
	var zeiten: Variant = szene.get("bauzeiten")
	if zeiten is Array:
		for e: Variant in zeiten as Array:
			if e is Dictionary:
				liste.append(e as Dictionary)
				summe += float((e as Dictionary)["ms"])
	print("BAUZEIT %s runde %d: laden %.0f ms  instanz %.0f ms  ready %.0f ms  aufbau %.0f ms (Schritte %.0f, %d Bilder)  gesamt %.0f ms" % [
			pfad.get_file(), runde, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0,
			(t3 - t2) / 1000.0, (t4 - t2) / 1000.0, summe, bilder, (t4 - t0) / 1000.0])
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["ms"]) > float(b["ms"]))
	for i in mini(zeilen, liste.size()):
		print("   %8.1f ms  %s" % [float(liste[i]["ms"]), String(liste[i]["text"])])
	if OS.get_environment("BAUZEIT_WEGDECKE") == "1":
		_wegdecke_zeigen(szene, pfad.get_file(), runde)
	szene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Je Stoff der Wegdecke (ShaderMaterial mit `wegboden.gdshader`) unter
## `szene` eine Zeile: Anzahl und Lage der Lücken, Zahl der Kronenlicht-
## Stützstellen und ihre Stärken. Jeder Stoff einmal, nach Knotenpfad.
func _wegdecke_zeigen(szene: Node, datei: String, runde: int) -> void:
	var gesehen := {}
	var stapel: Array[Node] = [szene]
	while not stapel.is_empty():
		var k: Node = stapel.pop_back()
		for kind in k.get_children():
			stapel.append(kind)
		var mi := k as MeshInstance3D
		if mi == null:
			continue
		var m := mi.material_override as ShaderMaterial
		if m == null or m.shader == null or m.shader.resource_path != "res://shaders/wegboden.gdshader" \
				or gesehen.has(m):
			continue
		gesehen[m] = true
		var anzahl := int(m.get_shader_parameter("luecken_anzahl"))
		var luecken: PackedVector3Array = m.get_shader_parameter("luecken")
		var teile := PackedStringArray()
		for i in mini(anzahl, luecken.size()):
			teile.append("%.1f-%.1f" % [luecken[i].x, luecken[i].y])
		var kronen := int(m.get_shader_parameter("kronen_anzahl"))
		var stellen: PackedVector2Array = m.get_shader_parameter("kronen_stellen")
		var staerken := PackedStringArray()
		for i in mini(kronen, stellen.size()):
			staerken.append("%.2f" % stellen[i].y)
		print("WEGDECKE %s runde %d %s: Lücken %d [%s], Kronenlicht %d [%s]" % [datei, runde,
				szene.get_path_to(mi), anzahl, ", ".join(teile), kronen, ", ".join(staerken)])
