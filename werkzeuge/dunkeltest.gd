extends Node3D
## Prüft, ob im Dunkellevel nach einem Tod noch etwas leuchtet.
##
## `LevelBasis` baut Kisten und Früchte nach jedem Tod aus dem Bauplan
## NEU auf. Die frischen Knoten wissen nichts von der Leuchtmarkierung –
## ohne Nachziehen stünde ab dem ersten Tod ein stockdunkler Gang voller
## unsichtbarer Kisten, und das Level wäre unspielbar. Genau deshalb ist
## das kein Schönheitsfehler, sondern der Unterschied zwischen spielbar
## und nicht spielbar.
##
## Gezählt wird das Merkzeichen, das `Leuchtmarker` an jedem markierten
## Knoten hinterlässt – nicht das Aussehen: Ob etwas leuchtet, ist auf
## einem Bild bei Restlicht 0,05 kaum zu messen.
##
##   godot --headless --path . res://werkzeuge/Dunkeltest.tscn

const LEVEL := "res://scenes/levels/Level23.tscn"

var _fehler := 0


func _ready() -> void:
	var szene: Node = load(LEVEL).instantiate()
	add_child(szene)
	for i in 120:
		await get_tree().process_frame

	print("=== Dunkeltest (%s) ===" % LEVEL.get_file())
	var vorher := _markiert(szene)
	print("  nach dem Aufbau      %3d von %3d Kisten markiert" % vorher)
	if vorher[0] == 0 or vorher[0] < vorher[1]:
		_fehler += 1
		print("    <-- FALSCH: schon vor dem ersten Tod nicht alles markiert")

	# Erst ein paar Kisten aus der Welt nehmen: `LevelBasis` stellt beim
	# Zurücksetzen nur wieder auf, was FEHLT. Ohne diesen Schritt liefe
	# der Test ins Leere und bestünde, weil gar nichts neu gebaut wurde –
	# beim ersten Anlauf ist er genau darauf hereingefallen.
	var weg := 0
	for k in get_tree().get_nodes_in_group("kisten"):
		if szene.is_ancestor_of(k) and weg < 8:
			k.queue_free()
			weg += 1
	await get_tree().process_frame
	print("  %d Kisten zerschlagen" % weg)

	# Den Neuaufbau auslösen, wie ihn ein Tod auslöst.
	GameState.level_zuruecksetzen.emit(false)
	for i in 30:
		await get_tree().process_frame

	var nachher := _markiert(szene)
	print("  nach dem Neuaufbau   %3d von %3d Kisten markiert" % nachher)
	if nachher[0] < nachher[1] or nachher[1] == 0:
		_fehler += 1
		print("    <-- FALSCH: unsichtbare Kisten im Dunkellevel")

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


## [markiert, gesamt] über alle Kisten der Szene.
func _markiert(wurzel: Node) -> Array:
	var markiert := 0
	var gesamt := 0
	for k in get_tree().get_nodes_in_group("kisten"):
		if not wurzel.is_ancestor_of(k):
			continue
		gesamt += 1
		if _traegt_merkmal(k):
			markiert += 1
	return [markiert, gesamt]


## Das Merkzeichen sitzt an dem Knoten, der das Material trägt – das ist
## nicht die Kiste selbst, sondern ein Netz irgendwo darunter.
func _traegt_merkmal(knoten: Node) -> bool:
	if knoten.has_meta(Leuchtmarker.MERKMAL):
		return true
	for kind in knoten.get_children():
		if _traegt_merkmal(kind):
			return true
	return false
