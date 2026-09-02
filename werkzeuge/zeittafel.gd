extends Node
## Druckt die Richtzeiten aller Level für den Zeitmodus.
##
## Aufruf:
##   bash werkzeuge/lauf.sh res://werkzeuge/Zeittafel.tscn
##
## Nicht Teil von `pruefe.sh` – das Werkzeug prüft nichts, es MISST. Es
## baut jedes Level einmal auf und liest ab, welche Richtzeit dabei
## herauskommt, samt Streckenlänge und der Rechnung dahinter. Gedacht für
## den Tag, an dem jemand die Zahlen erspielt und mit der Ableitung
## vergleichen will (siehe `LevelBasis._richtzeit()`).

func _ready() -> void:
	print("=== Richtzeiten (Saphir), Gold = 85 %, Platin = 72 % ===")
	print("%-8s %8s %8s %8s %8s  %s"
			% ["Level", "Weg m", "Saphir", "Gold", "Platin", "Herkunft"])
	for nummer in range(1, Spielfluss.LEVEL_GESAMT + 1):
		if not Spielfluss.level_gebaut(nummer):
			continue
		await _messen(nummer)
	get_tree().quit()


func _messen(nummer: int) -> void:
	var pfad: String = Spielfluss.LEVEL_SZENEN[nummer - 1]
	Spielfluss.aktuelles_level = nummer
	var szene := load(pfad).instantiate() as LevelBasis
	if szene == null:
		print("Level %02d: keine LevelBasis" % nummer)
		return
	add_child(szene)
	if szene.has_signal("aufbau_fertig"):
		await szene.aufbau_fertig
	await get_tree().process_frame

	var laenge := 0.0
	if szene.verlauf != null:
		laenge = szene.verlauf.get_baked_length()
	var richt: float = szene.call("_richtzeit")
	var herkunft := "Lauf (Weg / 8,5 * 2,8)"
	if szene.zielzeit() > 0.0:
		herkunft = "von Hand gesetzt"
	elif laenge <= 1.0:
		herkunft = "Ersatzwert, keine Kurve"
	elif bool(szene.call("_auf_schiene")):
		herkunft = "Schiene (Weg / 15 * 1,5)"
	print("%-8s %8.0f %8s %8s %8s  %s" % [
		"%02d" % nummer, laenge,
		Zeitlauf.als_text(richt),
		Zeitlauf.als_text(richt * Zeitlauf.GOLD_ANTEIL),
		Zeitlauf.als_text(richt * Zeitlauf.PLATIN_ANTEIL),
		herkunft])

	szene.queue_free()
	await get_tree().process_frame
