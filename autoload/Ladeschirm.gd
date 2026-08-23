extends CanvasLayer
## Ladebildschirm, der Szenenwechsel überdeckt.
##
## Als Autoload unter dem Namen "Ladeschirm" registriert und deshalb über
## Szenenwechsel hinweg vorhanden.
##
## Der Aufbau von Level 01 dauert rund fünf Sekunden, weil Gelände, Wald
## und Objekte im Code erzeugt werden. Damit das nicht als eingefrorenes
## Bild erscheint, meldet `LevelBasis` seinen Fortschritt hierher und gibt
## zwischen den Bauschritten ein Bild frei – so läuft die Anzeige weiter.

const TIPPS := [
	"Slide und dann springen bringt dich höher als ein normaler Sprung.",
	"Die Spin-Attacke zerbricht Kisten auch im Vorbeidrehen.",
	"Der Bauchplatscher zerbricht alle Kisten im Umkreis von zwei Metern.",
	"Die Sumpfkröte spinnen, den Stelzenvogel slidden, auf den Panzerkäfer springen.",
	"Nitrokisten explodieren bei Berührung – aus der Ferne sind sie ungefährlich.",
	"Federkisten geben zehn Früchte, wenn du zehnmal darauf springst.",
	"Hundert Früchte ergeben ein Extraleben.",
	"Gelbe Streifen auf dem Weg warnen vor einem Loch.",
]

var _flaeche: Control
var _hintergrund: GradientTexture2D
var _titel := ""
var _text := ""
var _anteil := 0.0
var _tipp := ""
var _phase := 0.0
var _sichtbar := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_flaeche = Control.new()
	_flaeche.name = "Flaeche"
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_STOP
	_flaeche.draw.connect(_zeichnen)
	add_child(_flaeche)

	# Weicher Verlauf als Textur statt vieler Rechtecke – gestapelte
	# Rechtecke ergaben sichtbare Streifen.
	var verlauf := Gradient.new()
	verlauf.set_color(0, Color(0.07, 0.12, 0.10))
	verlauf.set_color(1, Color(0.02, 0.04, 0.04))
	verlauf.add_point(0.45, Color(0.05, 0.09, 0.08))
	_hintergrund = GradientTexture2D.new()
	_hintergrund.gradient = verlauf
	_hintergrund.width = 4
	_hintergrund.height = 256
	_hintergrund.fill_from = Vector2(0.0, 0.0)
	_hintergrund.fill_to = Vector2(0.0, 1.0)

	_flaeche.modulate.a = 0.0
	_flaeche.visible = false


func ist_sichtbar() -> bool:
	return _sichtbar


## Blendet den Ladebildschirm ein.
func zeigen(titel: String) -> void:
	_titel = titel
	_text = "Wird geladen"
	_anteil = 0.0
	_tipp = TIPPS[randi() % TIPPS.size()]
	_sichtbar = true
	_flaeche.visible = true
	_flaeche.modulate.a = 1.0
	_flaeche.queue_redraw()


## Meldet den Baufortschritt. `anteil` von 0.0 bis 1.0.
func fortschritt(anteil: float, text: String = "") -> void:
	_anteil = clampf(anteil, 0.0, 1.0)
	if not text.is_empty():
		_text = text
	if _sichtbar:
		_flaeche.queue_redraw()


## Blendet den Ladebildschirm weich aus.
func verbergen() -> void:
	if not _sichtbar:
		return
	_sichtbar = false
	var tween := create_tween()
	tween.tween_property(_flaeche, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void: _flaeche.visible = false)


func _process(delta: float) -> void:
	if not _flaeche.visible:
		return
	_phase += delta
	_flaeche.queue_redraw()


# ------------------------------------------------------------- Zeichnen

func _zeichnen() -> void:
	var groesse := _flaeche.size
	var schrift := _flaeche.get_theme_default_font()

	# Hintergrund: weicher Verlauf von oben nach unten
	_flaeche.draw_texture_rect(_hintergrund, Rect2(Vector2.ZERO, groesse), false)

	var mitte := groesse * 0.5

	# Laufende Früchte als Anzeige, dass etwas passiert
	for i in 3:
		var versatz := _phase * 2.2 - float(i) * 0.42
		var hoch := absf(sin(versatz * PI)) * 22.0
		var x := mitte.x - 46.0 + float(i) * 46.0
		var y := mitte.y + 46.0 - hoch
		_flaeche.draw_circle(Vector2(x, y + 3.0), 13.0, Color(0, 0, 0, 0.35))
		_flaeche.draw_circle(Vector2(x, y), 13.0, Farben.FRUCHT)
		_flaeche.draw_circle(Vector2(x - 4.0, y - 4.5), 4.0, Color(1, 0.87, 0.65, 0.85))

	if schrift == null:
		return

	# Titel
	_text_mittig(schrift, _titel, mitte.y - 60.0, 46, Color(1, 0.96, 0.88))
	# Was gerade geschieht
	_text_mittig(schrift, _text, mitte.y - 16.0, 18, Color(0.78, 0.84, 0.78))

	# Fortschrittsbalken
	var breite := minf(groesse.x * 0.46, 460.0)
	var balken := Rect2(mitte.x - breite * 0.5, mitte.y + 88.0, breite, 12.0)
	_flaeche.draw_rect(balken, Color(1, 1, 1, 0.10))
	var gefuellt := balken
	gefuellt.size.x = balken.size.x * _anteil
	_flaeche.draw_rect(gefuellt, Farben.FRUCHT)
	_flaeche.draw_rect(balken, Color(1, 1, 1, 0.22), false, 2.0)
	_text_mittig(schrift, "%d %%" % roundi(_anteil * 100.0),
			balken.position.y + 34.0, 15, Color(0.72, 0.78, 0.72))

	# Tipp am unteren Rand
	_text_mittig(schrift, _tipp, groesse.y - 46.0, 17, Color(0.66, 0.74, 0.66))


func _text_mittig(schrift: Font, inhalt: String, y: float, groesse: int,
		farbe: Color) -> void:
	if inhalt.is_empty():
		return
	var breite := _flaeche.size.x
	_flaeche.draw_string(schrift, Vector2(0.0, y + 2.0), inhalt,
			HORIZONTAL_ALIGNMENT_CENTER, breite, groesse, Color(0, 0, 0, 0.55))
	_flaeche.draw_string(schrift, Vector2(0.0, y), inhalt,
			HORIZONTAL_ALIGNMENT_CENTER, breite, groesse, farbe)
