extends Camera3D
## Korridor-Kamera: folgt dem Spieler von schräg hinten oben.
## Werte 1:1 aus plattformer-demo.html übernommen.

## Ziel-Knoten. Bleibt das Feld leer, wird der erste Knoten
## aus der Gruppe "spieler" verwendet.
@export var ziel_pfad: NodePath
## Höhe über dem Spieler.
@export var hoehe := 4.2
## Abstand hinter dem Spieler (in +Z, der Korridor verläuft Richtung -Z).
@export var abstand := 8.0
## Die Kamera folgt seitlichen Bewegungen nur zur Hälfte (Korridor-Optik).
@export var seiten_faktor := 0.5
## Blickpunkt vor dem Spieler.
@export var blick_vorlauf := 4.0
## Glättung: kleinerer Wert = härteres Nachziehen.
@export var glaettung := 0.001

var _ziel: Node3D


func _ready() -> void:
	_ziel_suchen()


func _ziel_suchen() -> void:
	if not ziel_pfad.is_empty():
		_ziel = get_node_or_null(ziel_pfad) as Node3D
	if _ziel == null:
		_ziel = get_tree().get_first_node_in_group("spieler") as Node3D


func _process(delta: float) -> void:
	if _ziel == null or not is_instance_valid(_ziel):
		_ziel_suchen()
		return

	var p := _ziel.global_position
	var wunsch := Vector3(p.x * seiten_faktor, p.y + hoehe, p.z + abstand)
	global_position = global_position.lerp(wunsch, 1.0 - pow(glaettung, delta))

	var blickziel := Vector3(p.x * seiten_faktor, p.y + 1.0, p.z - blick_vorlauf)
	if global_position.distance_squared_to(blickziel) > 0.001:
		look_at(blickziel, Vector3.UP)
