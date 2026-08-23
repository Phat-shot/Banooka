extends Node
## Bündelt Tastatur-, Gamepad- und Touch-Eingaben zu einem gemeinsamen Zustand.
## Der Spieler fragt ausschließlich diese Klasse ab, damit alle drei Wege
## im Controller exakt gleich behandelt werden.
## Als Autoload unter dem Namen "InputHub" registriert.
##
## Gamepad-Belegung (Bezeichnungen wie auf einem PlayStation-Controller):
##   Kreuz ✕    springen        (Godot: JOY_BUTTON_A)
##   Kreis ○    Slide/Bauchplatscher (JOY_BUTTON_B)
##   Viereck □  Drehschlag      (JOY_BUTTON_X)
##   Dreieck △  Statustafel     (JOY_BUTTON_Y)
## Die Zuordnung steckt in der Input-Map in project.godot.

## Womit zuletzt gespielt wurde. Die Touch-Steuerung blendet sich damit
## aus, sobald jemand zum Controller greift, und beim nächsten Antippen
## wieder ein.
enum Art { TASTATUR, PAD, TOUCH }

## Wird ausgelöst, wenn die Statustafel auf- oder zugehen soll.
signal status_gewuenscht
## Wird ausgelöst, wenn sich die zuletzt benutzte Eingabeart ändert.
signal eingabeart_geaendert(art: Art)

## Schwelle, ab der eine Stickbewegung als bewusste Eingabe zählt.
const PAD_SCHWELLE := 0.35

## Bewegungsrichtung vom virtuellen Joystick, Bereich -1..1 (x = seitlich, y = vor/zurück).
var touch_bewegung := Vector2.ZERO

## Zuletzt benutzte Eingabeart (nur lesen, siehe `_input`).
var eingabeart := Art.TASTATUR

var _touch_sprung_neu := false
var _touch_sprung_gehalten := false
var _touch_spin_neu := false
var _touch_slide_neu := false
var _touch_slide_gehalten := false


func _ready() -> void:
	# Nach allen anderen Knoten laufen, damit die "neu"-Flags erst
	# zurückgesetzt werden, nachdem der Spieler sie gelesen hat.
	process_physics_priority = 1000
	# Auch bei angehaltenem Baum weiterlaufen: sonst blieben die Flags
	# stehen, während die Statustafel offen ist, und lösten beim
	# Fortsetzen einen Geistersprung aus.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	_touch_sprung_neu = false
	_touch_spin_neu = false
	_touch_slide_neu = false


## Merkt sich, womit gerade gespielt wird.
func _input(event: InputEvent) -> void:
	var art := eingabeart
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		art = Art.TOUCH
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			art = Art.PAD
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > PAD_SCHWELLE:
			art = Art.PAD
	elif event is InputEventKey:
		art = Art.TASTATUR
	if art != eingabeart:
		eingabeart = art
		eingabeart_geaendert.emit(art)


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


## Die Statustafel wird nicht abgefragt, sondern gemeldet – sie schaltet
## den Baum an und aus, da darf kein Tastendruck verloren gehen.
func touch_status(gedrueckt: bool) -> void:
	if gedrueckt:
		status_gewuenscht.emit()
