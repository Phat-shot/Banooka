extends Camera3D
class_name FolgeKamera
## Verfolgerkamera für Räume ohne festen Korridorverlauf (Portalraum).
##
## Die Kamera hält einen festen Winkel zur Welt und folgt dem Spieler
## weich. Weil die Steuerung kamerarelativ arbeitet, bedeutet "vorwärts"
## damit immer "ins Bild hinein" – unabhängig davon, wo der Spieler steht.

## Ziel. Bleibt das Feld leer, wird der erste Knoten der Gruppe
## "spieler" verwendet.
@export var ziel_pfad: NodePath
## Versatz zum Spieler in Weltkoordinaten.
@export var versatz := Vector3(0.0, 7.5, 11.0)
## Blickpunkt liegt so viel über dem Spieler.
@export var blick_hoehe := 1.2
## Glättung: kleiner = härteres Nachziehen.
@export var glaettung := 0.0015
## Innerhalb dieses Radius folgt die Kamera nicht (ruhiges Bild im Raum).
@export var totzone := 0.0

var _ziel: Node3D
var _muss_springen := true


func _ready() -> void:
	_ziel_suchen()
	sofort_ausrichten()


func _ziel_suchen() -> void:
	if not ziel_pfad.is_empty():
		_ziel = get_node_or_null(ziel_pfad) as Node3D
	if _ziel == null:
		_ziel = get_tree().get_first_node_in_group("spieler") as Node3D


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollposition.
func sofort_ausrichten() -> void:
	_muss_springen = true
	_ziel_suchen()
	if _ziel != null and is_instance_valid(_ziel):
		_folgen(1.0)


func _process(delta: float) -> void:
	if _ziel == null or not is_instance_valid(_ziel):
		_ziel_suchen()
		return
	_folgen(delta)


func _folgen(delta: float) -> void:
	var p := _ziel.global_position
	var wunsch := p + versatz
	if totzone > 0.0 and not _muss_springen:
		if global_position.distance_to(wunsch) < totzone:
			return
	if _muss_springen:
		global_position = wunsch
		_muss_springen = false
	else:
		global_position = global_position.lerp(wunsch, 1.0 - pow(glaettung, delta))

	var blickziel := p + Vector3.UP * blick_hoehe
	if global_position.distance_squared_to(blickziel) > 0.001:
		look_at(blickziel, Vector3.UP)
