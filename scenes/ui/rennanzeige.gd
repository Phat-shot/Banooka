extends CanvasLayer
class_name Rennanzeige
## Rennanzeige für Level 05: Platzierung, Runde und Schubvorrat.
##
## Das normale HUD zeigt Früchte, Leben und Kisten – im Rennen sagt keines
## davon, wie man steht. Diese Anzeige liegt darüber und wird vom Level
## mit den Fahrern gefüttert.

const GOLD := Color(1.0, 0.78, 0.32)
const HELL := Color(0.96, 0.95, 0.90)
const MATT := Color(1, 1, 1, 0.55)

## Alle Fahrer, der Spieler zuerst. Setzt das Level.
var fahrer: Array[Rennfahrer] = []
var runden_ziel := 3
## Endstand, sobald das Rennen vorbei ist ("" = läuft noch).
var schlusstext := ""

var _flaeche: Control


func _ready() -> void:
	layer = 2
	_flaeche = Control.new()
	_flaeche.name = "Anzeige"
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flaeche.draw.connect(_zeichnen)
	add_child(_flaeche)


func _process(_delta: float) -> void:
	_flaeche.queue_redraw()


## Platzierung des Spielers, 1-basiert.
func platz() -> int:
	if fahrer.is_empty():
		return 1
	var spieler := fahrer[0]
	var vor := 1
	for f in fahrer:
		if f != spieler and f.gesamtstrecke() > spieler.gesamtstrecke():
			vor += 1
	return vor


func _zeichnen() -> void:
	var schrift := _flaeche.get_theme_default_font()
	if schrift == null or fahrer.is_empty():
		return
	var spieler := fahrer[0]
	var breite := _flaeche.size.x
	var rechts := breite - 28.0

	# --- Platzierung, groß oben rechts ---
	var p := platz()
	_rechts(schrift, Vector2(rechts, 62.0), "%d." % p, 52, GOLD)
	_rechts(schrift, Vector2(rechts, 88.0), "von %d" % fahrer.size(), 16, MATT)

	# --- Runde ---
	var r := mini(spieler.runde + 1, runden_ziel)
	_rechts(schrift, Vector2(rechts, 124.0), "Runde %d / %d" % [r, runden_ziel],
			22, HELL)

	# --- Schubvorrat als Balkenreihe ---
	var vorrat := spieler.boost_vorrat()
	for i in 3:
		var feld := Rect2(rechts - 24.0 - i * 30.0, 140.0, 22.0, 10.0)
		var farbe := Color(1.0, 0.62, 0.18, 0.9) if i < vorrat else Color(1, 1, 1, 0.18)
		_flaeche.draw_rect(feld, farbe)
	if vorrat > 0:
		_rechts(schrift, Vector2(rechts, 172.0), "□ zündet den Schub", 14, MATT)

	# --- Tempo, unten rechts ---
	_rechts(schrift, Vector2(rechts, _flaeche.size.y - 28.0),
			"%d km/h" % int(spieler.tempo * 3.6), 20, HELL)

	if not schlusstext.is_empty():
		var mitte := _flaeche.size * 0.5
		_mittig(schrift, Vector2(mitte.x, mitte.y - 10.0), schlusstext, 46, GOLD)


func _rechts(schrift: Font, ende: Vector2, text: String, groesse: int,
		farbe: Color) -> void:
	var b := schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	_text(schrift, Vector2(ende.x - b, ende.y), text, groesse, farbe)


func _mittig(schrift: Font, mitte: Vector2, text: String, groesse: int,
		farbe: Color) -> void:
	var b := schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	_text(schrift, Vector2(mitte.x - b * 0.5, mitte.y), text, groesse, farbe)


func _text(schrift: Font, pos: Vector2, text: String, groesse: int,
		farbe: Color) -> void:
	_flaeche.draw_string(schrift, pos + Vector2(1.5, 2.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, Color(0, 0, 0, 0.6))
	_flaeche.draw_string(schrift, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse, farbe)
