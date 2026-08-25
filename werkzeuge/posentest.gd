extends Node
## Fährt eine Figur durch die Bewegungszustände und meldet, welcher Clip
## jeweils läuft. Damit lässt sich prüfen, ob nach Sprung und Gehen der
## richtige Zustand folgt – am Standbild sieht man das nicht.
##
##   MODELLTEST_DATEI=meine.glb godot --headless --path . res://werkzeuge/Posentest.tscn

func _ready() -> void:
	var datei := OS.get_environment("MODELLTEST_DATEI")
	if datei.is_empty():
		datei = "cash_banooka_mod.glb"
	Einstellungen.waehle_modell(Einstellungen.MITGELIEFERT.path_join(datei))
	var modell := SpielerModell.new()
	add_child(modell)
	await get_tree().process_frame

	var spieler: AnimationPlayer = modell.get("_eigener_spieler")
	if spieler == null:
		print("FEHLER: Figur ohne AnimationPlayer"); get_tree().quit(1); return

	# [Beschreibung, Tempo, in der Luft, Slide, Bilder]
	var ablauf := [
		["steht still", 0.0, false, false, 6],
		["schlendert", 0.20, false, false, 6],
		["geht", 0.50, false, false, 6],
		["rennt", 1.00, false, false, 6],
		["springt ab", 1.00, true, false, 2],
		["fliegt lange", 1.00, true, false, 90],
		["landet, laeuft weiter", 1.00, false, false, 6],
		["bleibt stehen", 0.0, false, false, 12],
		["springt aus dem Stand", 0.0, true, false, 2],
		["landet im Stand", 0.0, false, false, 12],
	]
	print("=== Posenfolge: %s ===" % datei)
	for schritt: Array in ablauf:
		for i in int(schritt[4]):
			modell.aktualisiere(1.0 / 60.0, float(schritt[1]),
					bool(schritt[2]), 0.0, 0.0)
			await get_tree().process_frame
		print("  %-22s -> %-9s bei %.2f s"
				% [schritt[0], spieler.current_animation,
				spieler.current_animation_position])
	get_tree().quit(0)
