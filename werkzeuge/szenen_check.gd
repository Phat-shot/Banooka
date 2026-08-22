extends Node
## Lädt jede Szene unter res://scenes, hängt sie kurz in den Szenenbaum
## und meldet Fehler. Damit werden auch Fehler in _ready() gefunden,
## die ein reiner Parse-Check nicht sieht.

var _pfade: Array[String] = []
var _index := 0
var _fehler := 0
var _aktuell: Node = null
var _warte := 0


func _ready() -> void:
	_sammle("res://scenes")
	_pfade.sort()
	print("=== Szenen-Check: %d Szenen ===" % _pfade.size())


func _sammle(verzeichnis: String) -> void:
	var d := DirAccess.open(verzeichnis)
	if d == null:
		return
	d.list_dir_begin()
	var eintrag := d.get_next()
	while eintrag != "":
		var voll := verzeichnis.path_join(eintrag)
		if d.current_is_dir():
			_sammle(voll)
		elif eintrag.ends_with(".tscn"):
			_pfade.append(voll)
		eintrag = d.get_next()
	d.list_dir_end()


func _process(_delta: float) -> void:
	if _aktuell != null:
		_warte -= 1
		if _warte > 0:
			return
		_aktuell.queue_free()
		_aktuell = null
		return

	if _index >= _pfade.size():
		print("=== %d Szenen geprüft, %d Fehler ===" % [_pfade.size(), _fehler])
		get_tree().quit(1 if _fehler > 0 else 0)
		return

	var pfad := _pfade[_index]
	_index += 1
	var ps := load(pfad) as PackedScene
	if ps == null:
		print("FEHLER laden: ", pfad)
		_fehler += 1
		return
	var knoten := ps.instantiate()
	if knoten == null:
		print("FEHLER instanziieren: ", pfad)
		_fehler += 1
		return
	add_child(knoten)
	_aktuell = knoten
	_warte = 3
	print("  ok: ", pfad)
