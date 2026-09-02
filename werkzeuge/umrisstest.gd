extends Node
## Prüft Umriss- und Auslöserkiste im laufenden Level 19.

const LEVEL := "res://scenes/levels/Level19.tscn"
var _fehler := 0
var _szene: Node


func _ready() -> void:
	_szene = load(LEVEL).instantiate()
	add_child(_szene)
	if _szene.has_signal("aufbau_fertig"):
		await _szene.aufbau_fertig
	for i in 10:
		await get_tree().process_frame

	print("=== Umrisstest ===")
	var umrisse := get_tree().get_nodes_in_group("umrisskisten").size()
	print("  Umrisskisten: %d, Kisten gesamt laut Zaehler: %d"
			% [umrisse, GameState.kisten_gesamt])
	# Nicht gegen eine feste Zahl pruefen: Die braeche beim naechsten
	# zusaetzlichen Kistchen in Level 19 aus dem falschen Grund. Geprueft
	# wird die Aussage selbst - jede Umrisskiste zaehlt von Anfang an mit,
	# sonst waere "alle Kisten" ohne den Ausloeser nie erreichbar.
	var zaehlende := 0
	var umrisse_zaehlen := true
	for k in get_tree().get_nodes_in_group("kisten"):
		if k.has_method("zaehlt_mit") and k.call("zaehlt_mit"):
			zaehlende += 1
	for k in get_tree().get_nodes_in_group("umrisskisten"):
		if not (k.has_method("zaehlt_mit") and k.call("zaehlt_mit")):
			umrisse_zaehlen = false
	_pruefe("Zaehler stimmt mit dem Baum ueberein",
			GameState.kisten_gesamt == zaehlende)
	_pruefe("jede Umrisskiste zaehlt mit", umrisse_zaehlen and umrisse > 0)
	_pruefe("zu Beginn alle koerperlos", _koerperliche() == 0)

	var a := _ausloeser()
	_pruefe("Ausloeser steht", a != null)
	a.zerbrechen(Angriff.SPIN)
	await get_tree().process_frame
	await get_tree().process_frame
	print("  nach dem Auslösen koerperlich: %d von %d" % [_koerperliche(), umrisse])
	_pruefe("nach dem Auslösen alle koerperlich", _koerperliche() == umrisse)

	# Eine der jetzt echten Umrisskisten zerschlagen.
	var eine := _erste_umrisskiste()
	_pruefe("Umrisskiste zerbricht jetzt", eine != null)
	if eine != null:
		eine.zerbrechen(Angriff.SPIN)
	await get_tree().process_frame

	# --- Tod VOR dem nächsten Checkpoint: alles zurück auf Anfang ---
	GameState.level_zuruecksetzen.emit(true)
	for i in 6:
		await get_tree().process_frame
	umrisse = get_tree().get_nodes_in_group("umrisskisten").size()
	print("  nach Tod (von vorn): %d Umrisse, davon koerperlich %d, Ausloeser %s"
			% [umrisse, _koerperliche(), "ja" if _ausloeser() != null else "nein"])
	_pruefe("Ausloeser wieder da", _ausloeser() != null)
	_pruefe("Umrisse warten wieder", _koerperliche() == 0)

	# --- Auslösen, Checkpoint, dann Tod: der Weg bleibt begehbar ---
	_ausloeser().zerbrechen(Angriff.SPIN)
	await get_tree().process_frame
	GameState.setze_checkpoint(Vector3.ZERO)
	_erste_umrisskiste().zerbrechen(Angriff.SPIN)
	await get_tree().process_frame
	GameState.level_zuruecksetzen.emit(false)
	for i in 6:
		await get_tree().process_frame
	umrisse = get_tree().get_nodes_in_group("umrisskisten").size()
	print("  nach Tod (Checkpoint danach): %d Umrisse, davon koerperlich %d, Ausloeser %s"
			% [umrisse, _koerperliche(), "ja" if _ausloeser() != null else "nein"])
	_pruefe("Ausloeser bleibt fort", _ausloeser() == null)
	_pruefe("neu gebaute Umrisse sind sofort echt", _koerperliche() == umrisse)

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


func _pruefe(text: String, gut: bool) -> void:
	print("  %-42s %s" % [text, "ja" if gut else "NEIN"])
	if not gut:
		_fehler += 1


func _koerperliche() -> int:
	var n := 0
	for k in get_tree().get_nodes_in_group("umrisskisten"):
		if (k as CollisionObject3D).collision_layer == 1:
			n += 1
	return n


func _ausloeser() -> Kiste:
	for k in get_tree().get_nodes_in_group("kisten"):
		var kk := k as Kiste
		if kk != null and kk.art == Kiste.Art.AUSLOESER \
				and not kk.is_queued_for_deletion():
			return kk
	return null


func _erste_umrisskiste() -> Kiste:
	for k in get_tree().get_nodes_in_group("umrisskisten"):
		var kk := k as Kiste
		if kk != null and not kk.is_queued_for_deletion():
			return kk
	return null
