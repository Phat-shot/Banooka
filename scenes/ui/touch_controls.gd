extends Control
## Virtuelle Touch-Steuerung: Joystick links unten, Buttons rechts unten.
## Meldet alle Eingaben an den InputHub, damit Tastatur und Touch
## im Spieler-Controller identisch behandelt werden.
##
## Die Steuerung wird nur auf Geräten mit Touchscreen eingeblendet.
## Zum Testen am Desktop kann "erzwingen" gesetzt werden.

## Touch-Steuerung auch ohne Touchscreen anzeigen (nur zum Testen).
@export var erzwingen := false

const JOY_BASIS := 55.0   ## Radius des Joystick-Rings
const JOY_MAX := 45.0     ## Maximaler Ausschlag des Sticks
const JOY_STICK := 25.0   ## Radius des Sticks
const BTN_RADIUS := 32.0  ## Radius der Aktions-Buttons
const BTN_TREFFER := 1.4  ## Trefferfläche der Buttons (Faktor auf den Radius)

var _joy_index := -1
var _joy_zentrum := Vector2.ZERO
var _joy_stick := Vector2.ZERO
var _btn_touches := {}      ## Touch-Index -> Button-Name
var _btn_aktiv := {"jump": false, "spin": false, "slide": false}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = erzwingen or DisplayServer.is_touchscreen_available()
	resized.connect(queue_redraw)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		var beruehrung := event as InputEventScreenTouch
		if beruehrung.pressed:
			var btn := _button_unter(beruehrung.position)
			if btn != "":
				_btn_touches[beruehrung.index] = btn
				_btn_aktiv[btn] = true
				_melde(btn, true)
			elif _joy_index == -1 and _in_joystick_zone(beruehrung.position):
				_joy_index = beruehrung.index
				_joy_zentrum = beruehrung.position
				_joy_stick = beruehrung.position
		else:
			if _btn_touches.has(beruehrung.index):
				var btn: String = _btn_touches[beruehrung.index]
				_btn_touches.erase(beruehrung.index)
				_btn_aktiv[btn] = false
				_melde(btn, false)
			if beruehrung.index == _joy_index:
				_joy_index = -1
				InputHub.touch_bewegung = Vector2.ZERO
		queue_redraw()

	elif event is InputEventScreenDrag:
		var zug := event as InputEventScreenDrag
		if zug.index != _joy_index:
			return
		var d := zug.position - _joy_zentrum
		if d.length() > JOY_MAX:
			d = d.normalized() * JOY_MAX
		_joy_stick = _joy_zentrum + d
		InputHub.touch_bewegung = d / JOY_MAX
		queue_redraw()


func _melde(btn: String, gedrueckt: bool) -> void:
	match btn:
		"jump":
			InputHub.touch_sprung(gedrueckt)
		"spin":
			InputHub.touch_spin(gedrueckt)
		"slide":
			InputHub.touch_slide(gedrueckt)


## Linke untere Bildschirmhälfte ist die Joystick-Zone.
func _in_joystick_zone(pos: Vector2) -> bool:
	return pos.x < size.x * 0.45 and pos.y > size.y * 0.55


## Mittelpunkte der drei Aktions-Buttons (Layout wie in der HTML-Demo).
func _button_positionen() -> Dictionary:
	return {
		"jump": Vector2(size.x - 52.0, size.y - 128.0),
		"spin": Vector2(size.x - 128.0, size.y - 64.0),
		"slide": Vector2(size.x - 52.0, size.y - 52.0),
	}


func _button_unter(pos: Vector2) -> String:
	for btn in _button_positionen():
		if pos.distance_to(_button_positionen()[btn]) <= BTN_RADIUS * BTN_TREFFER:
			return btn
	return ""


func _draw() -> void:
	# Joystick nur zeichnen, solange er berührt wird
	if _joy_index != -1:
		draw_circle(_joy_zentrum, JOY_BASIS, Color(1, 1, 1, 0.12))
		draw_arc(_joy_zentrum, JOY_BASIS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
		draw_circle(_joy_stick, JOY_STICK, Color(1, 1, 1, 0.45))

	var schrift := get_theme_default_font()
	var farben := {
		"jump": Color(0.31, 0.63, 1.0, 0.45),
		"spin": Color(1.0, 0.55, 0.24, 0.45),
		"slide": Color(0.63, 0.35, 1.0, 0.45),
	}
	var beschriftung := {"jump": "JUMP", "spin": "SPIN", "slide": "SLIDE"}

	for btn in _button_positionen():
		var c: Vector2 = _button_positionen()[btn]
		var farbe: Color = farben[btn]
		if _btn_aktiv.get(btn, false):
			farbe.a = 0.8
		draw_circle(c, BTN_RADIUS, farbe)
		draw_arc(c, BTN_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.3), 2.0)
		if schrift != null:
			draw_string(schrift, Vector2(c.x - 40.0, c.y + 5.0), beschriftung[btn],
					HORIZONTAL_ALIGNMENT_CENTER, 80.0, 14, Color(1, 1, 1, 0.9))
