extends Node
## Prüft den Zeitmodus: Zeitkisten, laufende Uhr, Standzeit, Tod, Wertung.
##
## Aufruf:
##   godot --headless --path . res://werkzeuge/Zeitprobe.tscn
##
## Geprüft wird an einem echten Level, nicht an einer Kunstszene: Der
## Umbau gewöhnlicher Kisten zu Zeitkisten passiert in `LevelBasis`
## zwischen Aufbau und Kistenzähler, und genau diese Reihenfolge ist das,
## was schiefgehen kann.

const LEVEL := "res://scenes/levels/Level08.tscn"

var _fehler := 0
var _szene: Node


func _ready() -> void:
	# Der Modus muss VOR dem Aufbau stehen – er entscheidet, welche Kisten
	# überhaupt entstehen.
	Zeitlauf.aktiv = true
	Spielfluss.aktuelles_level = 8

	_szene = load(LEVEL).instantiate()
	add_child(_szene)
	if _szene.has_signal("aufbau_fertig"):
		await _szene.aufbau_fertig
	for i in 6:
		await get_tree().process_frame

	print("=== Zeitprobe ===")

	# --- Stehen Zeitkisten im Level, und zählen sie mit? ---
	var zeitkisten := _zeitkisten()
	var zaehlende := 0
	for k in get_tree().get_nodes_in_group("kisten"):
		if k.has_method("zaehlt_mit") and k.call("zaehlt_mit"):
			zaehlende += 1
	print("  Zeitkisten im Level: %d, Kisten gesamt laut Zaehler: %d"
			% [zeitkisten.size(), GameState.kisten_gesamt])
	_pruefe("Zeitkisten stehen im Level", zeitkisten.size() >= 3)
	_pruefe("Zaehler stimmt mit dem Baum ueberein",
			GameState.kisten_gesamt == zaehlende)
	var alle_zaehlen := true
	for k in zeitkisten:
		if not k.zaehlt_mit():
			alle_zaehlen = false
	_pruefe("jede Zeitkiste zaehlt mit", alle_zaehlen)
	# Keine Kiste darf doppelt dastehen: Der Umbau nimmt die alte aus dem
	# Baum, bevor die neue hineinkommt.
	_pruefe("keine Kiste doppelt am selben Platz", not _doppelte_plaetze())

	# --- Läuft die Uhr? ---
	_pruefe("Lauf laeuft nach dem Aufbau", Zeitlauf.laeuft)
	_pruefe("Richtzeit gesetzt", Zeitlauf.richtzeit > 10.0)
	var vorher := Zeitlauf.zeit
	for i in 20:
		await get_tree().process_frame
	print("  Uhr nach 20 Bildern: %.3f s (vorher %.3f s)" % [Zeitlauf.zeit, vorher])
	_pruefe("Uhr laeuft", Zeitlauf.zeit > vorher)

	# --- Zeitkiste zerschlagen: die Uhr steht ---
	var kiste := zeitkisten[0]
	var wert := kiste.zeit_wert
	kiste.zerbrechen(Angriff.SPIN)
	await get_tree().process_frame
	print("  Zeitkiste mit %d s zerschlagen, Standzeit jetzt %.2f s"
			% [wert, Zeitlauf.frost])
	_pruefe("Standzeit aufgenommen", Zeitlauf.frost > float(wert) - 0.2)
	var stand := Zeitlauf.zeit
	for i in 10:
		await get_tree().process_frame
	print("  Uhr waehrend der Standzeit: %.3f s (war %.3f s)" % [Zeitlauf.zeit, stand])
	_pruefe("Uhr steht still", is_equal_approx(Zeitlauf.zeit, stand))

	# --- Zwei Kisten stapeln ihre Standzeit ---
	var vorrat := Zeitlauf.frost
	if zeitkisten.size() > 1:
		zeitkisten[1].zerbrechen(Angriff.SPIN)
		await get_tree().process_frame
		_pruefe("zweite Kiste legt Standzeit drauf", Zeitlauf.frost > vorrat)

	# --- Wertung: dieselbe Zeit ergibt dieselbe Stufe ---
	var richt := 100.0
	_pruefe("Platin unter 72 %", Zeitlauf.stufe_fuer(70.0, richt) == Zeitlauf.Stufe.PLATIN)
	_pruefe("Gold unter 85 %", Zeitlauf.stufe_fuer(80.0, richt) == Zeitlauf.Stufe.GOLD)
	_pruefe("Saphir bis zur Richtzeit",
			Zeitlauf.stufe_fuer(99.0, richt) == Zeitlauf.Stufe.SAPHIR)
	_pruefe("darueber kein Relikt",
			Zeitlauf.stufe_fuer(101.0, richt) == Zeitlauf.Stufe.KEINE)

	# --- Bestzeit wird eingetragen und nur verbessert ---
	Spielfluss.zeiten.clear()
	_pruefe("erste Zeit ist Bestzeit",
			Spielfluss.zeit_eintragen(8, 60.0, Zeitlauf.Stufe.SAPHIR))
	_pruefe("schlechtere Zeit ist keine Bestzeit",
			not Spielfluss.zeit_eintragen(8, 70.0, Zeitlauf.Stufe.KEINE))
	var stand_jetzt := Spielfluss.zeit_von(8)
	print("  Bestzeit nach zwei Laeufen: %.1f s, Stufe %d"
			% [float(stand_jetzt["zeit"]), int(stand_jetzt["stufe"])])
	_pruefe("Bestzeit bleibt die bessere", float(stand_jetzt["zeit"]) < 65.0)
	_pruefe("Stufe geht nicht verloren",
			int(stand_jetzt["stufe"]) == Zeitlauf.Stufe.SAPHIR)

	# --- Der Tod beendet den Lauf ---
	GameState.level_zuruecksetzen.emit(false)
	await get_tree().process_frame
	_pruefe("Tod beendet den Lauf", not Zeitlauf.laeuft)
	var nach_tod := Zeitlauf.zeit
	for i in 6:
		await get_tree().process_frame
	_pruefe("Uhr steht nach dem Tod", is_equal_approx(Zeitlauf.zeit, nach_tod))

	# --- Ohne Zeitmodus stehen keine Zeitkisten im Level ---
	Zeitlauf.aktiv = false
	_szene.queue_free()
	await get_tree().process_frame
	_szene = load(LEVEL).instantiate()
	add_child(_szene)
	if _szene.has_signal("aufbau_fertig"):
		await _szene.aufbau_fertig
	for i in 4:
		await get_tree().process_frame
	print("  ohne Zeitmodus: %d Zeitkisten, Lauf laeuft %s"
			% [_zeitkisten().size(), "ja" if Zeitlauf.laeuft else "nein"])
	_pruefe("ohne Zeitmodus keine Zeitkiste", _zeitkisten().is_empty())
	_pruefe("ohne Zeitmodus keine Uhr", not Zeitlauf.laeuft)

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


func _pruefe(text: String, gut: bool) -> void:
	print("  %-42s %s" % [text, "ja" if gut else "NEIN"])
	if not gut:
		_fehler += 1


func _zeitkisten() -> Array[Kiste]:
	var liste: Array[Kiste] = []
	for k in get_tree().get_nodes_in_group("kisten"):
		var kk := k as Kiste
		if kk != null and kk.art == Kiste.Art.ZEIT and not kk.is_queued_for_deletion():
			liste.append(kk)
	return liste


## Zwei Kisten am selben Platz wären der klassische Fehler beim Umbau:
## Die alte wurde nur zum Freigeben vorgemerkt, steht aber noch da.
func _doppelte_plaetze() -> bool:
	var plaetze := {}
	for k in get_tree().get_nodes_in_group("kisten"):
		var knoten := k as Node3D
		if knoten == null or knoten.is_queued_for_deletion():
			continue
		var schluessel := str(knoten.global_position.snappedf(0.05))
		if plaetze.has(schluessel):
			return true
		plaetze[schluessel] = true
	return false
