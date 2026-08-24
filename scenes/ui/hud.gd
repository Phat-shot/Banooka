extends CanvasLayer
## HUD: Früchte, Leben, Kisten-Zähler und Einblend-Nachrichten.
##
## Die Symbole werden gezeichnet statt aus Bilddateien geladen – das
## Projekt kommt ohne fremde Assets aus (siehe assets/CREDITS.md).

@onready var _anzeige: Control = $Anzeige
@onready var _tafel: Control = $Anzeige/Tafel
@onready var _nachricht: Label = $Anzeige/Nachricht
@onready var _touch: Control = $TouchControls

## Übersicht über Spielstand und Steuerung, Dreieck △ bzw. Tab.
var _status: Statustafel

var _fruechte := 0
var _leben := GameState.START_LEBEN
var _kisten := 0
var _kisten_gesamt := 0

var _nachricht_timer := 0.0
var _puls := 0.0          ## kurzes Aufblitzen beim Einsammeln
var _puls_leben := 0.0


func _ready() -> void:
	GameState.fruechte_geaendert.connect(_auf_fruechte)
	GameState.leben_geaendert.connect(_auf_leben)
	GameState.kisten_geaendert.connect(_auf_kisten)
	GameState.nachricht.connect(_auf_nachricht)

	_fruechte = GameState.fruechte
	_leben = GameState.leben
	_kisten = GameState.kisten_zerbrochen
	_kisten_gesamt = GameState.kisten_gesamt

	_tafel.draw.connect(_zeichne_tafel)
	_nachricht.modulate.a = 0.0

	_status = Statustafel.new()
	_status.name = "Statustafel"
	add_child(_status)
	_status.visibility_changed.connect(_auf_status)
	# Die Touch-Steuerung bleibt ganz oben: bei offener Statustafel steht
	# dort nur noch das Dreieck, mit dem man sie wieder zumacht.
	move_child(_touch, get_child_count() - 1)


func _process(delta: float) -> void:
	if _nachricht_timer > 0.0:
		_nachricht_timer -= delta
		if _nachricht_timer <= 0.0:
			var tween := create_tween()
			tween.tween_property(_nachricht, "modulate:a", 0.0, 0.4)

	if _puls > 0.0 or _puls_leben > 0.0:
		_puls = maxf(_puls - delta * 2.5, 0.0)
		_puls_leben = maxf(_puls_leben - delta * 2.0, 0.0)
		_tafel.queue_redraw()


# ------------------------------------------------------------- Zeichnen

func _zeichne_tafel() -> void:
	var schrift := _tafel.get_theme_default_font()
	# Im Portalraum gibt es keine Kisten – dann entfällt die Zeile,
	# statt "0 / 0" anzuzeigen.
	var zeigt_kisten := _kisten_gesamt > 0
	var breite := 230.0
	var hoehe := 78.0
	if zeigt_kisten:
		hoehe += 26.0

	# Hintergrundtafel mit weicher Kante
	_runde_flaeche(Rect2(0, 0, breite, hoehe), Color(0.04, 0.07, 0.06, 0.55), 14.0)
	_runde_rahmen(Rect2(0, 0, breite, hoehe), Color(1, 1, 1, 0.13), 14.0, 2.0)

	# --- Früchte ---
	var y := 26.0
	_frucht_symbol(Vector2(26, y), 11.0 + _puls * 3.0)
	_text(schrift, Vector2(48, y + 8), "%d" % _fruechte, 26, Farben.FRUCHT.lightened(0.25))
	_text(schrift, Vector2(48 + _breite(schrift, "%d" % _fruechte, 26) + 8, y + 7),
			"/ %d" % GameState.FRUECHTE_PRO_EXTRALEBEN, 13, Color(1, 1, 1, 0.45))

	# --- Leben ---
	y = 58.0
	for i in 5:
		var voll := i < _leben
		var gross := 7.0 + (_puls_leben * 2.0 if i == _leben - 1 else 0.0)
		_herz(Vector2(26 + i * 20, y), gross, voll)
	if _leben > 5:
		_text(schrift, Vector2(26 + 5 * 20 + 4, y + 5), "+%d" % (_leben - 5), 14,
				Color(1, 0.5, 0.5, 0.9))

	# Der Schutz steht nicht mehr hier: Er kreist als Maske um die Figur.
	# Im Spiel schaut man auf die Figur, nicht in die Ecke – wer im Sprung
	# getroffen wird, soll am Bild sehen, dass noch etwas abfängt.
	y = 84.0

	# --- Kisten ---
	if not zeigt_kisten:
		return
	_kisten_symbol(Vector2(26, y), 9.0)
	var voll_text := _kisten >= _kisten_gesamt and _kisten_gesamt > 0
	var farbe := Farben.KISTE_LEBEN.lightened(0.2) if voll_text else Color(0.88, 0.76, 0.55)
	_text(schrift, Vector2(46, y + 6), "%d / %d" % [_kisten, _kisten_gesamt], 17, farbe)


func _text(schrift: Font, pos: Vector2, inhalt: String, groesse: int, farbe: Color) -> void:
	if schrift == null:
		return
	# Schatten für Lesbarkeit auf hellem Hintergrund
	_tafel.draw_string(schrift, pos + Vector2(1.5, 1.5), inhalt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, Color(0, 0, 0, 0.6))
	_tafel.draw_string(schrift, pos, inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)


func _breite(schrift: Font, inhalt: String, groesse: int) -> float:
	if schrift == null:
		return 0.0
	return schrift.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x


## Frucht: Beere mit Glanzpunkt und Blatt.
func _frucht_symbol(mitte: Vector2, r: float) -> void:
	_tafel.draw_circle(mitte + Vector2(0, 1), r, Color(0, 0, 0, 0.35))
	_tafel.draw_circle(mitte, r, Farben.FRUCHT)
	_tafel.draw_circle(mitte - Vector2(r * 0.3, r * 0.35), r * 0.3, Color(1, 0.85, 0.6, 0.8))
	_tafel.draw_colored_polygon(PackedVector2Array([
		mitte + Vector2(1, -r),
		mitte + Vector2(r * 0.85, -r * 1.5),
		mitte + Vector2(r * 0.2, -r * 1.35),
	]), Farben.FRUCHT_BLATT.lightened(0.15))


## Herz aus zwei Kreisen und einem Dreieck.
func _herz(mitte: Vector2, r: float, voll: bool) -> void:
	var farbe := Color(1.0, 0.32, 0.36) if voll else Color(1, 1, 1, 0.16)
	_tafel.draw_circle(mitte + Vector2(-r * 0.45, -r * 0.2), r * 0.58, farbe)
	_tafel.draw_circle(mitte + Vector2(r * 0.45, -r * 0.2), r * 0.58, farbe)
	_tafel.draw_colored_polygon(PackedVector2Array([
		mitte + Vector2(-r * 0.98, 0.0),
		mitte + Vector2(r * 0.98, 0.0),
		mitte + Vector2(0.0, r * 1.15),
	]), farbe)


## Kiste: Quadrat mit Kreuzstreben.
func _kisten_symbol(mitte: Vector2, r: float) -> void:
	var feld := Rect2(mitte - Vector2(r, r), Vector2(r * 2, r * 2))
	_tafel.draw_rect(feld, Color(0.55, 0.33, 0.14))
	_tafel.draw_rect(feld, Color(0.24, 0.14, 0.06), false, 2.0)
	_tafel.draw_line(feld.position, feld.position + feld.size, Color(0.24, 0.14, 0.06), 1.5)
	_tafel.draw_line(feld.position + Vector2(feld.size.x, 0),
			feld.position + Vector2(0, feld.size.y), Color(0.24, 0.14, 0.06), 1.5)


func _runde_flaeche(feld: Rect2, farbe: Color, radius: float) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = farbe
	stil.set_corner_radius_all(int(radius))
	stil.draw(_tafel.get_canvas_item(), feld)


func _runde_rahmen(feld: Rect2, farbe: Color, radius: float, staerke: float) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0, 0, 0, 0)
	stil.border_color = farbe
	stil.set_border_width_all(int(staerke))
	stil.set_corner_radius_all(int(radius))
	stil.draw(_tafel.get_canvas_item(), feld)


# ------------------------------------------------------------- Signale

## Solange die Statustafel offen ist, nimmt die Touch-Steuerung nur noch
## die Statustaste an – sonst spränge die Figur durch die Tafel hindurch.
func _auf_status() -> void:
	_touch.set("gesperrt", _status.visible)
	_anzeige.visible = not _status.visible


func _auf_fruechte(anzahl: int) -> void:
	_fruechte = anzahl
	_puls = 1.0
	_tafel.queue_redraw()


func _auf_leben(anzahl: int) -> void:
	_leben = anzahl
	_puls_leben = 1.0
	_tafel.queue_redraw()


func _auf_kisten(zerbrochen: int, gesamt: int) -> void:
	_kisten = zerbrochen
	_kisten_gesamt = gesamt
	_tafel.queue_redraw()


func _auf_nachricht(text: String, dauer: float) -> void:
	_nachricht.text = text
	_nachricht.modulate.a = 1.0
	_nachricht.scale = Vector2(0.85, 0.85)
	_nachricht.pivot_offset = _nachricht.size * 0.5
	var tween := create_tween()
	tween.tween_property(_nachricht, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_nachricht_timer = dauer
