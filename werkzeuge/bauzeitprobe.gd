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
	if szene is LevelBasis:
		liste = (szene as LevelBasis).bauzeiten.duplicate()
		for e in liste:
			summe += float(e["ms"])
	print("BAUZEIT %s runde %d: laden %.0f ms  instanz %.0f ms  ready %.0f ms  aufbau %.0f ms (Schritte %.0f, %d Bilder)  gesamt %.0f ms" % [
			pfad.get_file(), runde, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0,
			(t3 - t2) / 1000.0, (t4 - t2) / 1000.0, summe, bilder, (t4 - t0) / 1000.0])
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["ms"]) > float(b["ms"]))
	for i in mini(zeilen, liste.size()):
		print("   %8.1f ms  %s" % [float(liste[i]["ms"]), String(liste[i]["text"])])
	szene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
