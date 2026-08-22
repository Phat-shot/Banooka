extends Node3D
class_name LevelBasis
## Gemeinsame Grundlage aller Level.
##
## Ein Level definiert seinen Verlauf als `Curve3D` und baut seinen Inhalt
## in `_baue()` auf. Diese Basisklasse kümmert sich um alles Wiederkehrende:
## Kamera an den Verlauf hängen, Kisten zählen, Zielportal verdrahten,
## Spieler ans Startportal setzen.

## Startpunkt des Spielers relativ zum Verlauf (Strecke auf der Kurve).
@export var start_strecke := 2.0
## Hilfslinien und Zahlen ausgeben (nur zum Bauen des Levels).
@export var debug := false

## Verlauf des Korridors. Wird von `_baue()` gesetzt.
var verlauf: Curve3D
## Knoten, unter dem die Levelgeometrie hängt.
var geometrie: Node3D
## Knoten, unter dem Objekte (Kisten, Gegner, Früchte) hängen.
var objekte: Node3D
## Knoten, unter dem die Deko hängt.
var deko: Node3D

var _pfad_knoten: Path3D
var _spieler: Node3D
var _kamera: Camera3D


func _ready() -> void:
	geometrie = _gruppe("Geometrie")
	objekte = _gruppe("Objekte")
	deko = _gruppe("Deko")

	_baue()

	if verlauf != null:
		_pfad_knoten = Path3D.new()
		_pfad_knoten.name = "Verlauf"
		_pfad_knoten.curve = verlauf
		add_child(_pfad_knoten)

	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	_kamera_verbinden()
	_spieler_setzen()
	_portale_verbinden()
	_kisten_zaehlen()
	_nach_aufbau()


## Haken: Hier baut das konkrete Level seinen Inhalt auf.
func _baue() -> void:
	pass


## Haken: Wird ganz am Schluss aufgerufen, wenn alles steht.
func _nach_aufbau() -> void:
	pass


func _gruppe(bezeichnung: String) -> Node3D:
	var vorhanden := get_node_or_null(NodePath(bezeichnung)) as Node3D
	if vorhanden != null:
		return vorhanden
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	add_child(knoten)
	return knoten


func _kamera_verbinden() -> void:
	for kind in get_children():
		if kind is Camera3D:
			_kamera = kind
			break
	if _kamera == null:
		return
	if _pfad_knoten != null and "kurve_pfad" in _kamera:
		_kamera.kurve_pfad = _kamera.get_path_to(_pfad_knoten)
	if _spieler != null and "ziel_pfad" in _kamera:
		_kamera.ziel_pfad = _kamera.get_path_to(_spieler)
	if _kamera.has_method("_ziel_suchen"):
		_kamera.call("_ziel_suchen")


func _spieler_setzen() -> void:
	if _spieler == null or verlauf == null:
		return
	var start := LevelWerkzeuge.punkt(verlauf, start_strecke, 0.0, 0.6)
	_spieler.global_position = start
	if _spieler.has_method("setze_blickrichtung"):
		_spieler.call("setze_blickrichtung", LevelWerkzeuge.drehung(verlauf, start_strecke))
	GameState.level_starten(start)


## Sucht das Zielportal und hängt sich an dessen Signal.
func _portale_verbinden() -> void:
	for knoten in _alle_knoten(self):
		if knoten.has_signal("level_geschafft"):
			if not knoten.is_connected("level_geschafft", _auf_level_geschafft):
				knoten.connect("level_geschafft", _auf_level_geschafft)


func _auf_level_geschafft() -> void:
	if debug:
		print("Level geschafft – Kisten: %d/%d, Früchte: %d"
				% [GameState.kisten_zerbrochen, GameState.kisten_gesamt, GameState.fruechte])


## Zählt alle zählenden Kisten im Level und meldet sie dem Spielstand.
func _kisten_zaehlen() -> void:
	var anzahl := 0
	for kiste in get_tree().get_nodes_in_group("kisten"):
		if kiste.has_method("zaehlt_mit"):
			if kiste.call("zaehlt_mit"):
				anzahl += 1
		else:
			anzahl += 1
	GameState.kisten_gesamt = anzahl
	GameState.kisten_zerbrochen = 0
	GameState.kisten_geaendert.emit(0, anzahl)
	if debug:
		print("Kisten im Level: ", anzahl)


func _alle_knoten(wurzel: Node) -> Array[Node]:
	var liste: Array[Node] = []
	for kind in wurzel.get_children():
		liste.append(kind)
		liste.append_array(_alle_knoten(kind))
	return liste
