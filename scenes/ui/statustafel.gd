extends Control
class_name Statustafel
## Statustafel: Übersicht über Spielstand und Steuerung.
##
## Wird mit Dreieck △ am Controller, mit Tab auf der Tastatur oder mit der
## Statustaste der Touch-Steuerung auf- und zugeklappt und hält das Spiel
## dabei an. Der HUD erzeugt sie; wie überall im Projekt ist alles
## gezeichnet statt geladen.
##
## Sie ist zugleich der einzige Weg AUS einem Level heraus. Ohne den Knopf
## "Level verlassen" saß man bis zum Zielportal fest – am Rechner konnte
## man wenigstens das Fenster schließen, im Browser gab es gar nichts.

## Aufbau der Steuerungslegende: [Aktion, Klartext, Tastatur].
## Leere Aktion = keine Symboltaste, dann steht der Controller-Text rechts.
const LEGENDE := [
	["", "Laufen", "WASD / Pfeile", "Stick / Steuerkreuz"],
	["jump", "Springen (2×) · am Gitter mit Richtung abspringen, ohne loslassen",
			"Leertaste", ""],
	["spin", "Drehschlag · auch im Hängen", "J / Strg", ""],
	["slide", "Slide · gehalten krabbeln · in der Luft Bauchplatscher · am Gitter Beine anziehen",
			"Umschalt", ""],
	["status", "Diese Tafel", "Tab oder Esc", ""],
]

const GOLD := Color(1.0, 0.78, 0.32)
const HELL := Color(0.96, 0.95, 0.90)
const MATT := Color(1, 1, 1, 0.5)

## Kurz nach dem Öffnen schließt kein Tippen. Ein Fingerdruck erzeugt auch
## ein nachgeahmtes Mausereignis; ohne diese Frist klappte die Tafel im
## selben Moment wieder zu, in dem die Statustaste sie geöffnet hat.
const SCHONFRIST := 0.35

var offen := false

var _auf_seit := 0.0
var _verlassen: MenueEintrag


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Muss auch bei angehaltenem Baum auf Eingaben hören, sonst käme man
	# nicht wieder heraus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	draw.connect(_zeichnen)
	resized.connect(func() -> void:
		queue_redraw()
		_knopf_ausrichten())
	InputHub.status_gewuenscht.connect(umschalten)

	_verlassen = MenueEintrag.new()
	_verlassen.name = "LevelVerlassen"
	_verlassen.beschriftung = "Level verlassen"
	_verlassen.unterzeile = "zurück in den Portalraum"
	_verlassen.schriftgroesse = 21
	_verlassen.process_mode = Node.PROCESS_MODE_ALWAYS
	_verlassen.angetippt.connect(_zurueck)
	_verlassen.visible = false
	add_child(_verlassen)


func _exit_tree() -> void:
	# Beim Szenenwechsel darf kein angehaltener Baum zurückbleiben.
	if offen and get_tree() != null:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("status"):
		umschalten()
		get_viewport().set_input_as_handled()
		return
	# Escape öffnet ebenfalls. Im Browser ist Tab die unzuverlässigste
	# Taste, die man wählen kann – dort schiebt sie den Fokus aus dem
	# Spielfeld heraus, und dann kommt gar nichts mehr an. Escape ist der
	# Griff, den jeder zuerst versucht, wenn er heraus will.
	if not offen and (event.is_action_pressed("pause")
			or event.is_action_pressed("ui_cancel")):
		setzen(true)
		get_viewport().set_input_as_handled()
		return
	if not offen:
		return
	# Bestätigen führt eine Ebene zurück: aus dem Level in den Portalraum,
	# aus dem Portalraum ins Hauptmenü.
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_zurueck()
		get_viewport().set_input_as_handled()
		return
	# Offen schließt alles: Abbrechen, Pause oder ein Tippen ins Bild.
	var zu := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
	var frisch := Time.get_ticks_msec() * 0.001 - _auf_seit < SCHONFRIST
	if event is InputEventScreenTouch:
		zu = zu or ((event as InputEventScreenTouch).pressed and not frisch)
	elif event is InputEventMouseButton:
		zu = zu or ((event as InputEventMouseButton).pressed and not frisch)
	if zu:
		umschalten()
		get_viewport().set_input_as_handled()


func umschalten() -> void:
	setzen(not offen)


func setzen(an: bool) -> void:
	if offen == an:
		return
	offen = an
	visible = an
	_auf_seit = Time.get_ticks_msec() * 0.001
	get_tree().paused = an
	if is_instance_valid(_verlassen):
		# Im Level führt der Knopf in den Portalraum, dort ins Hauptmenü.
		# Ohne die zweite Fassung kam man aus dem Portalraum nur über das
		# Schließen des Fensters heraus – im Browser also gar nicht.
		if _im_level():
			_verlassen.beschriftung = "Level verlassen"
			_verlassen.unterzeile = "zurück in den Portalraum"
		else:
			_verlassen.beschriftung = "Zum Hauptmenü"
			_verlassen.unterzeile = "Fortschritt bleibt gespeichert"
		_verlassen.visible = an
		_verlassen.setze_auswahl(true)
	_knopf_ausrichten()
	queue_redraw()


func _im_level() -> bool:
	return Spielfluss.aktuelles_level > 0


## Eine Ebene zurück. Erst den Baum wieder anlaufen lassen, dann wechseln –
## ein Szenenwechsel bei angehaltenem Baum lässt die neue Szene nie fertig
## aufbauen, weil ihr Aufbau über mehrere Bilder läuft.
func _zurueck() -> void:
	var war_im_level := _im_level()
	setzen(false)
	if war_im_level:
		Spielfluss.zum_hub()
	else:
		Spielfluss.zum_splash()


func _knopf_ausrichten() -> void:
	if not is_instance_valid(_verlassen) or not _verlassen.visible:
		return
	var feld := _tafelfeld()
	_verlassen.size = Vector2(minf(feld.size.x - 68.0, 300.0), 56.0)
	_verlassen.position = Vector2(feld.position.x + 34.0,
			feld.end.y - 56.0 - 46.0)


## Fläche der Tafel. Wird von Zeichnung UND Knopf benutzt, damit beide
## nicht auseinanderlaufen.
func _tafelfeld() -> Rect2:
	var breite := minf(size.x * 0.9, 780.0)
	# Der Knopf steht überall: im Level "Level verlassen", sonst
	# "Zum Hauptmenü".
	var hoehe := 176.0 + LEGENDE.size() * 30.0 + 74.0
	hoehe = minf(size.y * 0.9, hoehe)
	return Rect2((size - Vector2(breite, hoehe)) * 0.5, Vector2(breite, hoehe))


# ------------------------------------------------------------- Zeichnen

func _zeichnen() -> void:
	var schrift := get_theme_default_font()
	if schrift == null:
		return

	# Alles dahinter abdunkeln
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.03, 0.72))

	var feld := _tafelfeld()
	var breite := feld.size.x
	_flaeche(feld, Color(0.05, 0.09, 0.08, 0.94), 18)
	_rahmen(feld, Color(1, 1, 1, 0.16), 18, 2.0)

	var links := feld.position.x + 34.0
	var rechts := feld.position.x + breite * 0.47
	var y := feld.position.y + 52.0

	_text(schrift, Vector2(links, y), "STATUS", 34, GOLD)
	_text_rechts(schrift, Vector2(feld.end.x - 34.0, y - 4.0), _ort(), 19, HELL)
	y += 22.0
	draw_line(Vector2(links, y), Vector2(feld.end.x - 34.0, y), Color(1, 1, 1, 0.14), 1.5)

	_zustand(schrift, Vector2(links, y + 40.0), breite * 0.4)
	_steuerung(schrift, Vector2(rechts, y + 40.0), feld.end.x - 34.0 - rechts)

	var fuss := "Enter führt ins Hauptmenü  ·  Dreieck, Tab oder Esc schließt"
	if _im_level():
		fuss = "Enter verlässt das Level  ·  Dreieck, Tab oder Esc schließt"
	_text_mittig(schrift, Vector2(feld.get_center().x, feld.end.y - 22.0),
			fuss, 14, MATT)


## Wo der Spieler gerade steckt.
func _ort() -> String:
	var nummer: int = Spielfluss.aktuelles_level
	if nummer < 1:
		return "Portalraum"
	var raum := Spielfluss.raum_von_level(nummer)
	return "Level %02d  ·  %s" % [nummer, Spielfluss.RAUM_NAMEN[raum - 1]]


func _zustand(schrift: Font, oben: Vector2, breite: float) -> void:
	var zeilen := [
		["Früchte", "%d / %d" % [GameState.fruechte, GameState.FRUECHTE_PRO_EXTRALEBEN]],
		["Leben", "%d" % GameState.leben],
	]
	if GameState.kisten_gesamt > 0:
		zeilen.append(["Kisten", "%d / %d"
				% [GameState.kisten_zerbrochen, GameState.kisten_gesamt]])
	zeilen.append(["Freigeschaltet", "%d / %d Level"
			% [Spielfluss.freigeschaltet, Spielfluss.LEVEL_GESAMT]])

	_text(schrift, oben, "SPIELSTAND", 14, GOLD)
	var y := oben.y + 34.0
	for zeile in zeilen:
		_text(schrift, Vector2(oben.x, y), String(zeile[0]), 16, MATT)
		_text_rechts(schrift, Vector2(oben.x + breite, y), String(zeile[1]), 19, HELL)
		y += 32.0


func _steuerung(schrift: Font, oben: Vector2, breite: float) -> void:
	_text(schrift, oben, "STEUERUNG", 14, GOLD)
	var y := oben.y + 32.0
	var r := 13.0
	for zeile in LEGENDE:
		var aktion := String(zeile[0])
		var mitte := Vector2(oben.x + r, y - 5.0)
		if aktion.is_empty():
			draw_circle(mitte, 3.0, MATT)
		else:
			var farbe := PadSymbole.farbe(aktion)
			draw_arc(mitte, r, 0.0, TAU, 32, Color(farbe.r, farbe.g, farbe.b, 0.55), 1.5)
			PadSymbole.zeichne(self, aktion, mitte, r * 0.62, farbe, 2.0)
		_text(schrift, Vector2(oben.x + r * 2.0 + 12.0, y), String(zeile[1]), 15, HELL)
		var neben := String(zeile[3]) if not String(zeile[3]).is_empty() else String(zeile[2])
		_text_rechts(schrift, Vector2(oben.x + breite, y), neben, 13, MATT)
		y += 30.0


# --------------------------------------------------------- Zeichenhelfer

func _text(schrift: Font, pos: Vector2, inhalt: String, groesse: int, farbe: Color) -> void:
	draw_string(schrift, pos + Vector2(1.0, 1.5), inhalt, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse, Color(0, 0, 0, 0.55))
	draw_string(schrift, pos, inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)


func _text_rechts(schrift: Font, ende: Vector2, inhalt: String, groesse: int,
		farbe: Color) -> void:
	var breite := schrift.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse).x
	_text(schrift, Vector2(ende.x - breite, ende.y), inhalt, groesse, farbe)


func _text_mittig(schrift: Font, mitte: Vector2, inhalt: String, groesse: int,
		farbe: Color) -> void:
	var breite := schrift.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse).x
	_text(schrift, Vector2(mitte.x - breite * 0.5, mitte.y), inhalt, groesse, farbe)


func _flaeche(feld: Rect2, farbe: Color, radius: int) -> void:
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
