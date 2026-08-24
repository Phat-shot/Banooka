extends Control
## Virtuelle Touch-Steuerung: Joystick links unten, Tasten rechts unten.
## Meldet alle Eingaben an den InputHub, damit Tastatur, Gamepad und Touch
## im Spieler-Controller identisch behandelt werden.
##
## Die vier Tasten liegen als Raute wie die Symboltasten eines
## PlayStation-Controllers und tragen dieselben Zeichen und Farben:
##
##            △ Status
##   □ Spin           ○ Slide
##            ✕ Sprung
##
## Damit stimmt das, was auf dem Schirm klebt, mit dem überein, was unter
## dem Daumen liegt, wenn ein Controller angeschlossen ist.
##
## Die Steuerung erscheint nur auf Geräten mit Touchscreen und blendet sich
## aus, sobald jemand zum Gamepad greift. Zum Testen am Desktop kann
## "erzwingen" gesetzt werden.

## Touch-Steuerung auch ohne Touchscreen anzeigen (nur zum Testen).
@export var erzwingen := false
## Feinjustierung der Tastengröße, falls jemandem die Vorgabe nicht passt.
@export_range(0.6, 2.0, 0.05) var groesse := 1.0

## Angestrebter Tastendurchmesser in Millimetern. Ein Daumen deckt rund
## 15 mm ab; darunter trifft man auf einem Handy schlecht.
const ZIEL_MM := 13.0
## Entwurfshöhe, auf die sich die Grundmaße beziehen.
const REFERENZ := 720.0
## Tastenradius bei Entwurfshöhe, wenn die Bildschirmdichte unbekannt ist.
const RADIUS_BASIS := 46.0
## Obergrenze: nie größer als dieser Anteil der kurzen Bildschirmseite.
const RADIUS_ANTEIL_MAX := 0.115
## Mittenabstand der Tasten als Faktor auf den Radius.
const ABSTAND := 1.4
## Trefferfläche als Faktor auf den Radius (es gewinnt immer die nächste Taste).
const TREFFER := 1.25
## Abstand zum Bildschirmrand als Anteil der kurzen Seite.
const RAND_ANTEIL := 0.05

const BESCHRIFTUNG := {
	"jump": "SPRUNG",
	"slide": "SLIDE",
	"spin": "SPIN",
	"status": "STATUS",
}
## Platz in der Raute, relativ zur Mitte (x = rechts, y = unten).
const PLATZ := {
	"status": Vector2(0.0, -1.0),
	"spin": Vector2(-1.0, 0.0),
	"slide": Vector2(1.0, 0.0),
	"jump": Vector2(0.0, 1.0),
}

## Solange gesperrt, nimmt nur noch die Statustaste Eingaben an – der Rest
## würde sonst durch die offene Statustafel hindurch ins Spiel wirken.
var gesperrt := false:
	set(wert):
		gesperrt = wert
		if wert:
			_alles_loslassen()
		queue_redraw()

var _radius := RADIUS_BASIS
var _rand := 32.0
var _joy_basis := 72.0
var _joy_max := 58.0
var _joy_knauf := 30.0
var _joy_heimat := Vector2.ZERO

var _joy_index := -1
var _joy_zentrum := Vector2.ZERO
var _joy_stick := Vector2.ZERO
var _btn_touches := {}      ## Touch-Index -> Tastenname
var _btn_aktiv := {}        ## Tastenname -> gedrückt


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Auch bei angehaltenem Baum bedienbar, sonst käme man mit dem Finger
	# nicht mehr aus der Statustafel heraus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(_vermessen)
	InputHub.eingabeart_geaendert.connect(_auf_eingabeart)
	_vermessen()
	_sichtbarkeit_pruefen()


# ------------------------------------------------------------ Maße

## Rechnet alle Maße aus der Fenstergröße und, wenn bekannt, aus der
## Bildschirmdichte aus. Auf dem Handy zählt der Daumen, nicht die
## Pixelzahl: 13 mm bleiben 13 mm, egal wie fein der Bildschirm ist.
func _vermessen() -> void:
	var kurz := minf(size.x, size.y)
	if kurz <= 0.0:
		return
	var r := RADIUS_BASIS * (kurz / REFERENZ)

	var dpi := DisplayServer.screen_get_dpi()
	var fenster := float(DisplayServer.window_get_size().x)
	if dpi > 40 and fenster > 1.0 and size.x > 1.0:
		# Wie viele echte Pixel eine Zeicheneinheit breit ist (Stretch-Modus).
		var pixel_je_einheit := fenster / size.x
		var ziel_pixel := dpi * (ZIEL_MM * 0.5 / 25.4)
		r = maxf(r, ziel_pixel / pixel_je_einheit)

	_radius = minf(r * groesse, kurz * RADIUS_ANTEIL_MAX)
	_rand = kurz * RAND_ANTEIL
	_joy_basis = _radius * 1.55
	_joy_max = _radius * 1.25
	_joy_knauf = _radius * 0.62
	_joy_heimat = Vector2(_rand + _joy_basis, size.y - _rand - _joy_basis)
	queue_redraw()


## Mittelpunkt der Tastenraute (unten rechts).
func _rautenmitte() -> Vector2:
	var arm := _radius * (1.0 + ABSTAND)
	return Vector2(size.x - _rand - arm, size.y - _rand - arm)


func _tastenpunkte() -> Dictionary:
	var mitte := _rautenmitte()
	var arm := _radius * ABSTAND
	var punkte := {}
	for taste: String in PLATZ:
		punkte[taste] = mitte + (PLATZ[taste] as Vector2) * arm
	return punkte


## Nächstgelegene Taste unter dem Finger – die Trefferflächen der Raute
## überlappen sich, deshalb gewinnt der kürzeste Abstand.
func _taste_unter(pos: Vector2) -> String:
	var punkte := _tastenpunkte()
	var beste := ""
	var kuerzeste := _radius * TREFFER
	for taste: String in punkte:
		var d := pos.distance_to(punkte[taste])
		if d <= kuerzeste:
			kuerzeste = d
			beste = taste
	return beste


## Linke untere Bildschirmhälfte ist die Joystick-Zone.
func _in_joystick_zone(pos: Vector2) -> bool:
	return pos.x < size.x * 0.45 and pos.y > size.y * 0.4


# ------------------------------------------------------------ Eingabe

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		var beruehrung := event as InputEventScreenTouch
		var verbraucht := false
		if beruehrung.pressed:
			var taste := _taste_unter(beruehrung.position)
			if taste != "":
				if gesperrt and taste != "status":
					return
				_btn_touches[beruehrung.index] = taste
				_btn_aktiv[taste] = true
				_melde(taste, true)
				verbraucht = true
			elif not gesperrt and _joy_index == -1 and _in_joystick_zone(beruehrung.position):
				_joy_index = beruehrung.index
				_joy_zentrum = beruehrung.position
				_joy_stick = beruehrung.position
				verbraucht = true
		else:
			if _btn_touches.has(beruehrung.index):
				var taste: String = _btn_touches[beruehrung.index]
				_btn_touches.erase(beruehrung.index)
				_btn_aktiv[taste] = false
				_melde(taste, false)
				verbraucht = true
			if beruehrung.index == _joy_index:
				_joy_index = -1
				InputHub.touch_bewegung = Vector2.ZERO
				verbraucht = true
		queue_redraw()
		# Wer eine Taste getroffen hat, wollte nicht ins Bild tippen –
		# sonst schlösse derselbe Druck die eben geöffnete Statustafel.
		if verbraucht:
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		var zug := event as InputEventScreenDrag
		if zug.index != _joy_index:
			return
		var d := zug.position - _joy_zentrum
		if d.length() > _joy_max:
			d = d.normalized() * _joy_max
		_joy_stick = _joy_zentrum + d
		InputHub.touch_bewegung = d / _joy_max
		queue_redraw()
		get_viewport().set_input_as_handled()


func _melde(taste: String, gedrueckt: bool) -> void:
	match taste:
		"jump":
			InputHub.touch_sprung(gedrueckt)
		"spin":
			InputHub.touch_spin(gedrueckt)
		"slide":
			InputHub.touch_slide(gedrueckt)
		"status":
			InputHub.touch_status(gedrueckt)


## Alles loslassen – nötig, wenn die Steuerung mitten im Druck verschwindet
## oder gesperrt wird, sonst liefe die Figur ewig weiter.
func _alles_loslassen() -> void:
	for taste in _btn_touches.values():
		_btn_aktiv[taste] = false
		_melde(taste, false)
	_btn_touches.clear()
	_joy_index = -1
	InputHub.touch_bewegung = Vector2.ZERO


func _auf_eingabeart(_art: int) -> void:
	_sichtbarkeit_pruefen()


func _sichtbarkeit_pruefen() -> void:
	var soll := erzwingen or DisplayServer.is_touchscreen_available()
	# Wer zum Controller greift, braucht die Daumentasten nicht mehr;
	# beim nächsten Antippen sind sie wieder da.
	if InputHub.eingabeart == InputHub.Art.PAD:
		soll = false
	if soll == visible:
		return
	if not soll:
		_alles_loslassen()
	visible = soll
	queue_redraw()


# ------------------------------------------------------------ Zeichnen

func _draw() -> void:
	_zeichne_joystick()
	_zeichne_tasten()


func _zeichne_joystick() -> void:
	if gesperrt:
		return
	# In Ruhe ein blasser Ring an der Heimatstelle, damit man weiß, wo der
	# Daumen hingehört; beim Berühren wandert der Ring unter den Finger.
	var zentrum := _joy_zentrum if _joy_index != -1 else _joy_heimat
	var deckung := 1.0 if _joy_index != -1 else 0.45
	draw_circle(zentrum, _joy_basis, Color(1, 1, 1, 0.10 * deckung))
	draw_arc(zentrum, _joy_basis, 0.0, TAU, 48, Color(1, 1, 1, 0.28 * deckung),
			maxf(2.0, _radius * 0.045))
	var knauf := _joy_stick if _joy_index != -1 else _joy_heimat
	draw_circle(knauf, _joy_knauf, Color(1, 1, 1, 0.42 * deckung))
	draw_arc(knauf, _joy_knauf, 0.0, TAU, 32, Color(1, 1, 1, 0.5 * deckung),
			maxf(1.5, _radius * 0.03))


func _zeichne_tasten() -> void:
	var schrift := get_theme_default_font()
	var punkte := _tastenpunkte()
	var strich := maxf(2.0, _radius * 0.075)
	var schriftgroesse := maxi(10, int(_radius * 0.26))

	for taste: String in punkte:
		# Bei offener Statustafel bleibt nur das Dreieck stehen, mit dem
		# man sie wieder zumacht – der Rest wäre dort ohne Wirkung.
		if gesperrt and taste != "status":
			continue
		var mitte: Vector2 = punkte[taste]
		var farbe := PadSymbole.farbe(taste)
		var gedrueckt: bool = _btn_aktiv.get(taste, false)

		var fuellung := Color(0.05, 0.06, 0.08, 0.34)
		if gedrueckt:
			fuellung = Color(farbe.r, farbe.g, farbe.b, 0.55)
		draw_circle(mitte, _radius, fuellung)
		var ring := farbe
		ring.a = 0.95 if gedrueckt else 0.7
		draw_arc(mitte, _radius, 0.0, TAU, 48, ring, strich)

		PadSymbole.zeichne(self, taste, mitte, _radius * 0.44, farbe, strich)

		if schrift != null:
			var text: String = BESCHRIFTUNG[taste]
			var breite := schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
					-1, schriftgroesse).x
			# Die Beschriftung liegt außerhalb der Raute: bei der oberen
			# Taste darüber, sonst darunter – sonst stünde sie zwischen den
			# Nachbartasten.
			var oben: bool = (PLATZ[taste] as Vector2).y < 0.0
			var abstand := _radius + schriftgroesse * (0.5 if oben else 1.15)
			draw_string(schrift,
					mitte + Vector2(-breite * 0.5, -abstand if oben else abstand),
					text, HORIZONTAL_ALIGNMENT_LEFT, -1, schriftgroesse,
					Color(1, 1, 1, 0.65))
