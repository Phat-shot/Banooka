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
## Wackeln nach dem Kameravertrag (scripts/effekte.gd), gleich wie in der
## Korridorkamera – siehe `KorridorKamera.wackelbasis()`.
var _wucht := 0.0
var _wucht_zeit := 0.0
var _blick_gesetzt := false
## Sichtfeld laut Szene; das tatsächliche wird für breite Bildschirme
## gedeckelt (`KorridorKamera.sichtfeld_begrenzt()`).
var _szenen_fov := 0.0


func _ready() -> void:
	# Die Kamera wird selbst im Bildtakt gesetzt. Godot darf sie deshalb
	# nicht zusätzlich interpolieren, sonst hinkt sie einen Physikschritt
	# hinterher und alles fühlt sich schwammig an.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_szenen_fov = fov
	get_viewport().size_changed.connect(_sichtfeld_anpassen)
	_sichtfeld_anpassen()
	_ziel_suchen()
	sofort_ausrichten()


func _sichtfeld_anpassen() -> void:
	fov = KorridorKamera.sichtfeld_begrenzt(self, _szenen_fov)


## Kamerawackeln (Kameravertrag): das Maximum zählt, nicht die Summe.
func erschuettern(staerke: float) -> void:
	_wucht = clampf(maxf(_wucht, staerke), 0.0, 1.0)


func _ziel_suchen() -> void:
	if not ziel_pfad.is_empty():
		_ziel = get_node_or_null(ziel_pfad) as Node3D
	if _ziel == null:
		_ziel = get_tree().get_first_node_in_group("spieler") as Node3D


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollposition.
func sofort_ausrichten() -> void:
	_muss_springen = true
	_wucht = 0.0
	_ziel_suchen()
	if _ziel != null and is_instance_valid(_ziel):
		_folgen(1.0)


func _process(delta: float) -> void:
	if _ziel == null or not is_instance_valid(_ziel):
		_ziel_suchen()
		return
	_folgen(delta)
	if _wucht > 0.0:
		_wucht_zeit += delta
		# Nur auf eine frisch gesetzte Blickrichtung – in der Totzone bleibt
		# die Basis stehen, und der Ausschlag sammelte sich sonst an.
		if _blick_gesetzt:
			basis = basis * KorridorKamera.wackelbasis(_wucht, _wucht_zeit)
		_wucht = maxf(_wucht - delta * KorridorKamera.WUCHT_ABKLINGEN, 0.0)


func _folgen(delta: float) -> void:
	_blick_gesetzt = false
	# Den gezeichneten Ort lesen (Bildtakt.ort): `global_position` liefert
	# die Stellung des letzten Physikschritts, also eine Treppe mit 60
	# Stufen je Sekunde. Die Kamera läuft im Bildtakt und würde diese
	# Treppe sonst getreu nachfahren – genau das nimmt man als Ruckeln der
	# Umgebung wahr, im Portalraum am deutlichsten, weil die Kamera dort
	# per `look_at` auf die Figur blickt und die ganze Welt mitspringt.
	var p := Bildtakt.ort(_ziel)
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
	_blick_gesetzt = global_position.distance_squared_to(blickziel) > 0.001
	if _blick_gesetzt:
		look_at(blickziel, Vector3.UP)
