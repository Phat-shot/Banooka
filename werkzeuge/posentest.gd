extends Node
## Fährt eine Figur durch die Bewegungszustände und meldet, welcher Clip
## jeweils läuft. Damit lässt sich prüfen, ob nach Sprung und Gehen der
## richtige Zustand folgt – am Standbild sieht man das nicht.
##
##   MODELLTEST_DATEI=meine.glb godot --headless --path . res://werkzeuge/Posentest.tscn

func _ready() -> void:
	var datei := OS.get_environment("MODELLTEST_DATEI")
	if datei.is_empty():
		datei = "cash_banooka_rc.glb"
	Einstellungen.waehle_modell(Einstellungen.MITGELIEFERT.path_join(datei))
	var modell := SpielerModell.new()
	add_child(modell)
	await get_tree().process_frame

	var spieler: AnimationPlayer = modell.get("_eigener_spieler")
	if spieler == null:
		print("FEHLER: Figur ohne AnimationPlayer"); get_tree().quit(1); return

	# [Beschreibung, Tempo, in der Luft, Slide, Spin, Bilder, Haltung]
	var ablauf := [
		["steht still", 0.0, false, false, false, 6],
		["schlendert", 0.20, false, false, false, 6],
		["geht", 0.50, false, false, false, 6],
		["rennt", 1.00, false, false, false, 6],
		["springt ab", 1.00, true, false, false, 2],
		["fliegt lange", 1.00, true, false, false, 90],
		["landet, laeuft weiter", 1.00, false, false, false, 6],
		["bleibt stehen", 0.0, false, false, false, 12],
		["slide angesetzt", 0.8, false, true, false, 2],
		["slide gehalten", 0.8, false, true, false, 400],
		["nach dem slide", 0.8, false, false, false, 4],
		["dreht sich", 0.3, false, false, true, 30],
		["nach dem dreh", 0.3, false, false, false, 6],
		["doppelsprung dreht", 0.5, true, false, true, 10],
		["landet danach", 0.5, false, false, false, 6],
		["krabbelt", 0.4, false, false, false, 8, "krabbeln"],
		["krabbelt und springt", 0.4, true, false, false, 6, ""],
		["sitzt im Kart", 0.9, false, false, false, 8, "sitzen"],
		["reitet", 0.9, false, false, false, 8, "reiten"],
		["wieder zu Fuss", 0.9, false, false, false, 6, ""],
	]
	print("=== Posenfolge: %s ===" % datei)
	for schritt: Array in ablauf:
		for i in int(schritt[5]):
			modell.aktualisiere(1.0 / 60.0, float(schritt[1]),
					bool(schritt[2]), 0.42 if bool(schritt[3]) else 0.0,
					0.55 if bool(schritt[4]) else 0.0,
					String(schritt[6]) if schritt.size() > 6 else "")
			await get_tree().process_frame
		print("  %-22s -> %-9s bei %.2f s"
				% [schritt[0], spieler.current_animation,
				spieler.current_animation_position])
	get_tree().quit(0)
