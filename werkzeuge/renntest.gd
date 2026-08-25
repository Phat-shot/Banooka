extends Node
## Prüft die Startaufstellung von Level 06: Wer steht wo, und auf welchem
## Platz landet der Spieler im ersten Bild?
func _ready() -> void:
	var level: Node = (load("res://scenes/levels/Level06.tscn") as PackedScene).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for f in 3:
		await get_tree().physics_frame

	var fahrer: Variant = level.get("_fahrer")
	if fahrer == null or (fahrer as Array).is_empty():
		print("FEHLER: kein Fahrerfeld"); get_tree().quit(1); return
	var liste: Array = []
	for f in (fahrer as Array):
		liste.append({"name": f.fahrername, "strecke": f.strecke,
				"fortschritt": f.gesamtstrecke(), "spieler": f.ist_spieler})
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["fortschritt"]) > float(b["fortschritt"]))
	print("=== Startaufstellung Level 06 ===")
	var platz := 0
	for e in liste:
		platz += 1
		print("  Platz %d: %-12s Strecke %7.2f  Fortschritt %8.2f%s"
				% [platz, e["name"], e["strecke"], e["fortschritt"],
				"   <-- Spieler" if e["spieler"] else ""])
	get_tree().quit(0)
