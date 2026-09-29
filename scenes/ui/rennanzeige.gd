extends CanvasLayer
class_name Rennanzeige
## Rennanzeige für Level 06: Platzierung, Runde, Schubvorrat und Tempo.
##
## Das normale HUD zeigt Früchte, Leben und Kisten – im Rennen sagt keines
## davon, wie man steht. Diese Anzeige liegt oben rechts und wird vom
## Level mit den Fahrern gefüttert.
##
## Ebene 2, also UNTER dem HUD (Ebene 10): Die Statustafel deckt sie beim
## Anhalten ab. Solange angehalten ist, blendet sie sich ganz aus – ihre
## Zahlen stehen dann ohnehin still.
##
## Der Tacho steht unten rechts – außer mit Touch-Steuerung: Dort liegen
## die Daumentasten (HUD, Ebene 10, also darüber), und er wandert unten in
## die Mitte, wo zwischen Joystick und Tasten Platz ist.

## Alle Fahrer, der Spieler zuerst. Setzt das Level.
var fahrer: Array[Rennfahrer] = []
var runden_ziel := 3
## Endstand, sobald das Rennen vorbei ist ("" = läuft noch).
var schlusstext := ""

## Höchsttempo mit Schub, für die Skala des Tachos.
const TEMPO_MAX := Rennfahrer.HOECHST_TEMPO * Rennfahrer.BOOST_FAKTOR

var _flaeche: Control
## Eigene Fläche für das Band, damit es über `modulate` ein- und
## ausblenden kann, ohne die übrige Anzeige mitzunehmen.
var _band_flaeche: Control
var _letzter_platz := 0
var _platz_pop := 0.0
## +1 = gerade überholt (grün), -1 = überholt worden (rot).
var _platz_richtung := 0
var _letzte_runde_gezeigt := false
## Band "LETZTE RUNDE!": 0 = aus, läuft bis 1.
var _band := 0.0
var _tacho := 0.0
var _uhr := 0.0
## Schein hinter einer bereiten Schubkapsel; eigene Kopie, weil ihre
## Deckung jedes Bild pulsiert.
var _glut_stil: StyleBoxFlat
## Geteilte Flächen und Texturen, einmal geholt statt in jedem Bild über
## einen Schlüssel gesucht (nie verändern).
var _kapsel_voll: StyleBoxFlat
var _kapsel_leer: StyleBoxFlat
var _band_stil: StyleBoxFlat
var _hof: GradientTexture2D
## Die Touch-Steuerung des HUD (Gruppe "touchsteuerung"), falls es eine gibt.
var _touch: Control = null


func _ready() -> void:
	layer = 2
	add_to_group(&"rennanzeige")
	# Auch angehalten weiterlaufen – nur um sich dann zu verstecken.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_flaeche = Control.new()
	_flaeche.name = "Anzeige"
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flaeche.theme = UiStil.thema()
	_flaeche.draw.connect(_zeichnen)
	add_child(_flaeche)
	_glut_stil = UiStil.eigene(&"pille")
	_kapsel_voll = UiStil.getoent(&"pille", Color(1.0, 0.62, 0.18))
	# Leer: eine dunkle Mulde mit feinem hellem Rand. Die helle Rinne von
	# &"schalter" verschwand vor hellem Himmel und las sich wie "an".
	_kapsel_leer = UiStil.variante(&"schalter", &"schub_leer", func(st: StyleBoxFlat) -> void:
		st.bg_color = Color(0, 0, 0, 0.38)
		st.border_color = Color(1, 1, 1, 0.26))
	_band_stil = UiStil.getoent(&"band", Farben.WARNUNG)
	# Weicher Hof hinter der Platzierung: Sie steht frei über dem Himmel.
	_hof = UiStil.radialverlauf(Color(Farben.UI_NACHT, 0.5), Color(Farben.UI_NACHT, 0.0))
	_band_flaeche = Control.new()
	_band_flaeche.name = "Band"
	_band_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_band_flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band_flaeche.visible = false
	_band_flaeche.draw.connect(_band_zeichnen)
	_flaeche.add_child(_band_flaeche)


func _process(delta: float) -> void:
	_flaeche.visible = not get_tree().paused
	if not _flaeche.visible or fahrer.is_empty():
		return
	_uhr += delta
	var spieler := fahrer[0]

	var p := platz()
	if _letzter_platz != 0 and p != _letzter_platz:
		_platz_pop = 1.0
		_platz_richtung = 1 if p < _letzter_platz else -1
	_letzter_platz = p
	_platz_pop = maxf(_platz_pop - delta * 2.2, 0.0)

	if not _letzte_runde_gezeigt and runden_ziel > 1 \
			and spieler.runde + 1 == runden_ziel and schlusstext.is_empty():
		_letzte_runde_gezeigt = true
		_band = 0.001
	if _band > 0.0:
		_band = minf(_band + delta / 1.8, 1.0)
		if _band >= 1.0:
			_band = 0.0
		# Herein bis 0,15, stehen, ab 0,8 hinaus
		var ein := clampf(_band / 0.15, 0.0, 1.0)
		var aus := clampf((_band - 0.8) / 0.2, 0.0, 1.0)
		_band_flaeche.modulate.a = ein * (1.0 - aus)
		_band_flaeche.visible = _band > 0.0
		_band_flaeche.queue_redraw()

	_tacho = UiStil.annaehern(_tacho, clampf(spieler.tempo / TEMPO_MAX, 0.0, 1.0),
			delta, 6.0, 0.2)
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


static func _podestfarbe(p: int) -> Color:
	match p:
		1:
			return Farben.UI_GOLD
		2:
			return Farben.UI_SILBER
		3:
			return Farben.UI_BRONZE
	return Farben.UI_HELL


func _zeichnen() -> void:
	if fahrer.is_empty():
		return
	var spieler := fahrer[0]
	var groesse := _flaeche.size
	var rechts := groesse.x - 28.0

	# Nach dem Zieleinlauf zeigt die Auswertung des HUD die Platzierung;
	# ohne sie (etwa im Werkzeug) steht der Endstand hier in der Mitte.
	if not schlusstext.is_empty():
		if get_tree().get_nodes_in_group(&"auswertung").is_empty():
			UiStil.text(_flaeche, groesse * 0.5, schlusstext, 46, Farben.UI_GOLD,
					&"titel", -1, HORIZONTAL_ALIGNMENT_CENTER)
		return

	# --- Platzierung, groß oben rechts, auf einem weichen dunklen Hof ---
	_flaeche.draw_texture_rect(_hof, Rect2(rechts - 130.0, -14.0, 200.0, 140.0), false)
	var p := platz()
	var farbe := _podestfarbe(p)
	if _platz_pop > 0.0:
		var blitz := Farben.KISTE_LEBEN.lightened(0.3) if _platz_richtung > 0 \
				else Farben.WARNUNG.lightened(0.2)
		farbe = farbe.lerp(blitz, _platz_pop)
	var ziffer := "%d." % p
	var zb := UiStil.textbreite(ziffer, 58, &"zahl")
	var zmitte := Vector2(rechts - zb * 0.5, 42.0)
	var s := UiStil.federkurve(_platz_pop, 0.35)
	_flaeche.draw_set_transform(zmitte, 0.0, Vector2.ONE * s)
	UiStil.text(_flaeche, Vector2(0.0, 58.0 * 0.36), ziffer, 58, farbe, &"zahl", -1,
			HORIZONTAL_ALIGNMENT_CENTER)
	_flaeche.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Nicht UI_MATT: Das steht frei über dem Himmel, nicht auf einer Tafel.
	UiStil.text(_flaeche, Vector2(rechts, 94.0), "von %d" % fahrer.size(), 16,
			Farben.UI_TEXT_RUHE, &"fett", -1, HORIZONTAL_ALIGNMENT_RIGHT)

	# --- Runde ---
	var r := mini(spieler.runde + 1, runden_ziel)
	var rundenfeld := Rect2(rechts - 150.0, 108.0, 150.0, 38.0)
	UiStil.zeichne(_flaeche, rundenfeld, &"chip")
	UiStil.text(_flaeche, Vector2(rundenfeld.position.x + 18.0, 133.0), "RUNDE", 12,
			Farben.UI_GOLD, &"sperr", 3)
	UiStil.text(_flaeche, Vector2(rundenfeld.end.x - 16.0, 135.0),
			"%d/%d" % [r, runden_ziel], 22, Farben.UI_HELL, &"zahl", -1,
			HORIZONTAL_ALIGNMENT_RIGHT)

	# --- Schubvorrat als Kapseln ---
	var vorrat := spieler.boost_vorrat()
	for i in 3:
		var feld := Rect2(rechts - 34.0 - i * 40.0, 158.0, 34.0, 14.0)
		if i < vorrat:
			# Verfügbar: warm leuchtend und leicht pulsierend
			var glut := 0.5 + 0.5 * sin(_uhr * 5.0 + i * 0.7)
			_glut_stil.bg_color = Color(1.0, 0.6, 0.2, 0.14 + 0.12 * glut)
			_glut_stil.draw(_flaeche.get_canvas_item(), feld.grow(3.0 + glut * 2.5))
			_kapsel_voll.draw(_flaeche.get_canvas_item(), feld)
		else:
			_kapsel_leer.draw(_flaeche.get_canvas_item(), feld)
	if vorrat > 0:
		UiStil.text(_flaeche, Vector2(rechts, 194.0), "□ zündet den Schub", 14,
				Farben.UI_TEXT_RUHE, &"fett", -1, HORIZONTAL_ALIGNMENT_RIGHT)

	# --- Tacho, unten rechts; mit Touch-Steuerung unten in der Mitte ---
	var tacho := Vector2(rechts - 58.0, groesse.y - 70.0)
	if _touch_sichtbar():
		tacho = Vector2(groesse.x * 0.5, groesse.y - 66.0)
	_tacho_zeichnen(tacho, spieler)


## Liegen die Daumentasten gerade im Bild? Gefragt wird die Steuerung
## selbst – sie weiß, ob sie erzwungen oder für das Gamepad verborgen ist.
func _touch_sichtbar() -> bool:
	if not is_instance_valid(_touch):
		_touch = get_tree().get_first_node_in_group(&"touchsteuerung") as Control
	return _touch != null and _touch.is_visible_in_tree()


## Bogen von 150° bis 390° (unten offen), Füllung von Hell über Orange
## nach Rot, die Zahl in der Mitte.
func _tacho_zeichnen(mitte: Vector2, spieler: Rennfahrer) -> void:
	var r := 50.0
	var von := deg_to_rad(150.0)
	var bis := deg_to_rad(390.0)
	_flaeche.draw_circle(mitte, r + 12.0, Color(Farben.UI_GRUND_LEICHT, 0.5), true, -1.0, true)
	_flaeche.draw_arc(mitte, r, von, bis, 48, Color(1, 1, 1, 0.14), 8.0, true)
	if _tacho > 0.005:
		var ende := lerpf(von, bis, _tacho)
		var farbe := Farben.UI_HELL.lerp(Farben.FRUCHT, clampf(_tacho * 1.6, 0.0, 1.0))
		if _tacho > 0.66:
			farbe = Farben.FRUCHT.lerp(Farben.WARNUNG, (_tacho - 0.66) / 0.34)
		_flaeche.draw_arc(mitte, r, von, ende, 48, farbe, 8.0, true)
	UiStil.text(_flaeche, mitte + Vector2(0.0, 8.0), "%d" % int(spieler.tempo * 3.6), 26,
			Farben.UI_HELL, &"zahl", -1, HORIZONTAL_ALIGNMENT_CENTER)
	UiStil.text(_flaeche, mitte + Vector2(0.0, 30.0), "km/h", 12, Farben.UI_MATT,
			&"fett", -1, HORIZONTAL_ALIGNMENT_CENTER)


func _band_zeichnen() -> void:
	if _band <= 0.0:
		return
	var groesse := _band_flaeche.size
	var ein := clampf(_band / 0.15, 0.0, 1.0)
	var aus := clampf((_band - 0.8) / 0.2, 0.0, 1.0)
	var skala := lerpf(1.4, 1.0, 1.0 - pow(1.0 - ein, 3.0))
	var mitte := Vector2(groesse.x * 0.5, groesse.y * 0.3 - 20.0 * aus)
	var tb := UiStil.textbreite("LETZTE RUNDE!", 48, &"schwung")
	var bw := tb + 80.0
	_band_flaeche.draw_set_transform(mitte, 0.0, Vector2.ONE * skala)
	_band_stil.draw(_band_flaeche.get_canvas_item(), Rect2(-bw * 0.5, -31.0, bw, 60.0))
	_band_flaeche.draw_rect(Rect2(-bw * 0.5 + 10.0, -26.0, bw - 20.0, 3.0),
			Color(1, 1, 1, 0.28))
	UiStil.text(_band_flaeche, Vector2(0.0, 48.0 * 0.36), "LETZTE RUNDE!", 48,
			Farben.UI_HELL, &"schwung", 10, HORIZONTAL_ALIGNMENT_CENTER)
	_band_flaeche.draw_set_transform_matrix(Transform2D.IDENTITY)
