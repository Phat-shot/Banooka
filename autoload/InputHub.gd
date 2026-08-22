extends Node
## Bündelt Tastatur- und Touch-Eingaben zu einem gemeinsamen Zustand.
## Der Spieler fragt ausschließlich diese Klasse ab, damit Tastatur und
## virtuelle Touch-Buttons exakt gleich behandelt werden.
## Als Autoload unter dem Namen "InputHub" registriert.

## Bewegungsrichtung vom virtuellen Joystick, Bereich -1..1 (x = seitlich, y = vor/zurück).
var touch_bewegung := Vector2.ZERO

var _touch_sprung_neu := false
var _touch_sprung_gehalten := false
var _touch_spin_neu := false
var _touch_slide_neu := false
var _touch_slide_gehalten := false


func _ready() -> void:
	# Nach allen anderen Knoten laufen, damit die "neu"-Flags erst
	# zurückgesetzt werden, nachdem der Spieler sie gelesen hat.
	process_physics_priority = 1000


func _physics_process(_delta: float) -> void:
	_touch_sprung_neu = false
	_touch_spin_neu = false
	_touch_slide_neu = false


# --- Abfragen für den Spieler ---

## Bewegungseingabe als Vector2(x, z) im Weltkoordinatensystem.
func bewegung() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if v.length() < 0.05:
		v = touch_bewegung
	if v.length() > 1.0:
		v = v.normalized()
	return v


func sprung_gedrueckt() -> bool:
	return Input.is_action_just_pressed("jump") or _touch_sprung_neu


func sprung_gehalten() -> bool:
	return Input.is_action_pressed("jump") or _touch_sprung_gehalten


func spin_gedrueckt() -> bool:
	return Input.is_action_just_pressed("spin") or _touch_spin_neu


func slide_gedrueckt() -> bool:
	return Input.is_action_just_pressed("slide") or _touch_slide_neu


func slide_gehalten() -> bool:
	return Input.is_action_pressed("slide") or _touch_slide_gehalten


# --- Meldungen von der Touch-Steuerung ---

func touch_sprung(gedrueckt: bool) -> void:
	if gedrueckt:
		_touch_sprung_neu = true
	_touch_sprung_gehalten = gedrueckt


func touch_spin(gedrueckt: bool) -> void:
	if gedrueckt:
		_touch_spin_neu = true


func touch_slide(gedrueckt: bool) -> void:
	if gedrueckt:
		_touch_slide_neu = true
	_touch_slide_gehalten = gedrueckt
