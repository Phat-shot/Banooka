extends Control
class_name MenueEintrag
## Ein Eintrag im Startmenü – vollständig gezeichnet, ohne Bilddateien.
##
## Bedienbar mit Tastatur/Gamepad (der Startbildschirm setzt die Auswahl)
## und mit Maus/Finger (Antippen löst aus, Überfahren wählt aus).

signal angetippt
signal ueberfahren

## Farben: gewählt = warmes Bernsteingelb, sonst gedämpftes Weiß.
const RAHMEN_GEWAEHLT := Color(1.0, 0.78, 0.32)
const SCHRIFT_GEWAEHLT := Color(1.0, 0.93, 0.74)
const SCHRIFT_RUHE := Color(0.86, 0.85, 0.79)
const GRUND_GEWAEHLT := Color(0.10, 0.09, 0.06, 0.86)
const GRUND_RUHE := Color(0.05, 0.06, 0.05, 0.52)

var beschriftung := ""
var schriftgroesse := 27
var gewaehlt := false
var _puls := 0.0          ## läuft nach dem Auswählen kurz aus


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: ueberfahren.emit())
	draw.connect(_zeichne)


func setze_auswahl(an: bool) -> void:
	if gewaehlt == an:
		return
	gewaehlt = an
	if an:
		_puls = 1.0
		set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _puls <= 0.0:
		set_process(false)
		return
	_puls = maxf(_puls - delta * 3.0, 0.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var maus := event as InputEventMouseButton
		if maus.pressed and maus.button_index == MOUSE_BUTTON_LEFT:
			ueberfahren.emit()
			angetippt.emit()
			accept_event()


# ------------------------------------------------------------- Zeichnen

func _zeichne() -> void:
	var feld := Rect2(Vector2.ZERO, size)
	var schwung := _puls * _puls * 6.0

	if gewaehlt:
		# Leichter Schein hinter der Tafel
		_tafel(feld.grow(3.0 + schwung), Color(1.0, 0.78, 0.32, 0.13), 12)
		_tafel(feld, GRUND_GEWAEHLT, 10)
		_rahmen(feld, RAHMEN_GEWAEHLT, 10, 2.0)
		# Bernsteinbalken links als Marke
		draw_rect(Rect2(feld.position + Vector2(0, 8),
				Vector2(4.0, feld.size.y - 16.0)), RAHMEN_GEWAEHLT)
	else:
		_tafel(feld, GRUND_RUHE, 10)
		_rahmen(feld, Color(1, 1, 1, 0.10), 10, 1.0)

	var schrift := get_theme_default_font()
	if schrift == null:
		return
	var farbe := SCHRIFT_GEWAEHLT if gewaehlt else SCHRIFT_RUHE
	var einzug := 26.0 if gewaehlt else 20.0
	var grundlinie := feld.size.y * 0.5 + schriftgroesse * 0.36
	var ort := Vector2(einzug, grundlinie)
	draw_string(schrift, ort + Vector2(1.5, 2.0), beschriftung,
			HORIZONTAL_ALIGNMENT_LEFT, -1, schriftgroesse, Color(0, 0, 0, 0.55))
	draw_string(schrift, ort, beschriftung,
			HORIZONTAL_ALIGNMENT_LEFT, -1, schriftgroesse, farbe)

	if gewaehlt:
		_pfeil(Vector2(feld.size.x - 26.0, feld.size.y * 0.5), 8.0)


## Kleines Dreieck als Auswahlzeiger.
func _pfeil(mitte: Vector2, r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		mitte + Vector2(-r * 0.5, -r),
		mitte + Vector2(r * 0.7, 0.0),
		mitte + Vector2(-r * 0.5, r),
	]), RAHMEN_GEWAEHLT)


func _tafel(feld: Rect2, farbe: Color, radius: int) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = farbe
	stil.set_corner_radius_all(radius)
	stil.draw(get_canvas_item(), feld)


func _rahmen(feld: Rect2, farbe: Color, radius: int, staerke: float) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0, 0, 0, 0)
	stil.border_color = farbe
	stil.set_border_width_all(int(staerke))
	stil.set_corner_radius_all(radius)
	stil.draw(get_canvas_item(), feld)
