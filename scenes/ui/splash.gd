extends Control
## Startbildschirm: Waldkulisse in 3D, Titelschriftzug, Menü und
## Fortschrittszeile.
##
## Aufbau (alles zur Laufzeit erzeugt, die Szene enthält nur den
## Wurzelknoten – siehe ARCHITEKTUR.md):
##
##   Kulisse      Node3D mit Wald, Licht, Nebel und wandernder Kamera
##   Schleier     dunkler Verlauf links und unten, damit Text lesbar bleibt
##   Titel        "BANOOKA", plastisch mit Kontur gezeichnet
##   Untertitel   eine Zeile, gesperrt gesetzt, mit Zierlinie
##   Menü         MenueEintrag-Tafeln, Tastatur/Gamepad/Touch
##   Fortschritt  25 Rauten plus Klartext, wie viel freigeschaltet ist
##   Rückfrage    Overlay vor dem Zurücksetzen
##
## Symbole werden gezeichnet (`_draw`) statt geladen – das Projekt kommt
## ohne fremde Assets aus.

# --- Maße (Entwurfsgröße 1280 x 720, Ränder wachsen mit dem Fenster) ---
const RAND := 96.0
const TITEL_OBEN := 104.0
const TITEL_GROESSE := 104
const TITEL_SPERRUNG := 12
const UNTERTITEL_OBEN := 252.0
const UNTERTITEL_GROESSE := 21
const MENUE_OBEN := 344.0
const EINTRAG_BREITE := 412.0
const EINTRAG_HOEHE := 58.0
const EINTRAG_ABSTAND := 14.0
const DIALOG_TAFEL := Vector2(520.0, 240.0)
const DIALOG_EINTRAG := Vector2(360.0, 50.0)

# --- Farben ---
const GOLD := Color(1.0, 0.78, 0.32)
const TITEL_FUELLUNG := Color(1.0, 0.90, 0.66)
const TITEL_TIEFE := Color(0.55, 0.24, 0.06)
const TITEL_KONTUR := Color(0.11, 0.06, 0.03)
const SCHLEIER := Color(0.03, 0.05, 0.05)

const TEXT_TITEL := "BANOOKA"
const TEXT_UNTERTITEL := "Rennen, springen, wirbeln – durch fünf wilde Welten"
const TEXT_HINWEIS := "Pfeiltasten wählen  ·  Enter bestätigt  ·  oder antippen"
const HINWEIS_BREITE := 600.0

var _kulisse: SplashKulisse
var _schleier: Control
var _titel: Control
var _untertitel: Control
var _fortschritt: Control
var _hinweis: Control
var _meldung: Control
var _dialog: Control
var _blende: ColorRect

var _eintraege: Array[MenueEintrag] = []
var _aktionen: Array[Callable] = []
var _index := 0

var _dialog_eintraege: Array[MenueEintrag] = []
var _dialog_aktionen: Array[Callable] = []
var _dialog_index := 0
var _dialog_offen := false

var _blockiert := false        ## während Einblendung und Szenenwechsel
var _meldung_text := ""
var _meldung_zeit := 0.0

var _titelschrift: FontVariation
var _sperrschrift: FontVariation


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_schriften_bauen()
	_kulisse = SplashKulisse.new()
	_kulisse.name = "Kulisse"
	add_child(_kulisse)

	_baue_schleier()
	_baue_titel()
	_baue_menue()
	_baue_fortschritt()
	_baue_dialog()
	_baue_blende()

	Spielfluss.fortschritt_geaendert.connect(_auf_fortschritt)
	_waehle(0)
	_einblenden()
	set_process_unhandled_input(true)


func _schriften_bauen() -> void:
	var grund := get_theme_default_font()
	_titelschrift = FontVariation.new()
	_titelschrift.base_font = grund
	_titelschrift.spacing_glyph = TITEL_SPERRUNG
	_titelschrift.variation_embolden = 0.55
	_sperrschrift = FontVariation.new()
	_sperrschrift.base_font = grund
	_sperrschrift.spacing_glyph = 3


## Legt ein Zeichenfeld an und hängt seine Zeichenroutine ein.
func _feld(ort: Vector2, groesse: Vector2, zeichner: Callable,
		anker: int = Control.PRESET_TOP_LEFT) -> Control:
	var knoten := Control.new()
	knoten.set_anchors_preset(anker)
	knoten.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ränder direkt setzen: `position` würde je nach Ankern und aktueller
	# Elterngröße unterschiedlich umgerechnet.
	knoten.offset_left = ort.x
	knoten.offset_top = ort.y
	knoten.offset_right = ort.x + groesse.x
	knoten.offset_bottom = ort.y + groesse.y
	knoten.draw.connect(zeichner.bind(knoten))
	add_child(knoten)
	return knoten


# ------------------------------------------------------------ Schleier

func _baue_schleier() -> void:
	_schleier = Control.new()
	_schleier.name = "Schleier"
	_schleier.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_schleier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_schleier.draw.connect(_zeichne_schleier)
	_schleier.resized.connect(_schleier.queue_redraw)
	add_child(_schleier)


func _zeichne_schleier() -> void:
	var b := _schleier.size.x
	var h := _schleier.size.y
	var dunkel := Color(SCHLEIER.r, SCHLEIER.g, SCHLEIER.b, 0.70)
	var klar := Color(SCHLEIER.r, SCHLEIER.g, SCHLEIER.b, 0.0)

	# Verlauf von links: trägt Titel und Menü
	_verlauf(_schleier, Vector2(0, 0), Vector2(b * 0.56, h), dunkel, klar, true)
	# Fuß und Kopf leicht abdunkeln – rahmt das Bild
	_verlauf(_schleier, Vector2(0, h - 190.0), Vector2(b, 190.0),
			klar, Color(SCHLEIER.r, SCHLEIER.g, SCHLEIER.b, 0.72), false)
	_verlauf(_schleier, Vector2(0, 0), Vector2(b, 130.0),
			Color(SCHLEIER.r, SCHLEIER.g, SCHLEIER.b, 0.40), klar, false)


## Rechteck mit linearem Farbverlauf (waagerecht oder senkrecht).
func _verlauf(auf: Control, ort: Vector2, groesse: Vector2,
		von: Color, bis: Color, waagerecht: bool) -> void:
	var punkte := PackedVector2Array([
		ort,
		ort + Vector2(groesse.x, 0),
		ort + groesse,
		ort + Vector2(0, groesse.y),
	])
	var farben: PackedColorArray
	if waagerecht:
		farben = PackedColorArray([von, bis, bis, von])
	else:
		farben = PackedColorArray([von, von, bis, bis])
	auf.draw_polygon(punkte, farben)


# --------------------------------------------------------------- Titel

func _baue_titel() -> void:
	_titel = _feld(Vector2(RAND, TITEL_OBEN), Vector2(820, 150), _zeichne_titel)
	_untertitel = _feld(Vector2(RAND + 6.0, UNTERTITEL_OBEN), Vector2(720, 56),
			_zeichne_untertitel)


func _zeichne_titel(auf: Control) -> void:
	if _titelschrift == null:
		return
	var ort := Vector2(0.0, _titelschrift.get_ascent(TITEL_GROESSE))

	# Schlagschatten
	_kontur(auf, ort + Vector2(6, 12), TEXT_TITEL, TITEL_GROESSE, 20,
			Color(0, 0, 0, 0.32))
	# Tiefe: mehrere Konturen nach unten versetzt ⇒ plastischer Block
	for d in range(10, 0, -1):
		var t := float(d) / 10.0
		_kontur(auf, ort + Vector2(0, d), TEXT_TITEL, TITEL_GROESSE, 17,
				TITEL_TIEFE.darkened(0.35 * t))
	# Harte Kontur und helle Fläche
	_kontur(auf, ort, TEXT_TITEL, TITEL_GROESSE, 17, TITEL_KONTUR)
	auf.draw_string(_titelschrift, ort, TEXT_TITEL, HORIZONTAL_ALIGNMENT_LEFT,
			-1, TITEL_GROESSE, TITEL_FUELLUNG)
	# Feiner Glanz auf der Oberkante
	auf.draw_string(_titelschrift, ort - Vector2(0, 3), TEXT_TITEL,
			HORIZONTAL_ALIGNMENT_LEFT, -1, TITEL_GROESSE, Color(1, 1, 1, 0.16))


func _kontur(auf: Control, ort: Vector2, text: String, groesse: int,
		staerke: int, farbe: Color) -> void:
	auf.draw_string_outline(_titelschrift, ort, text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse, staerke, farbe)


func _zeichne_untertitel(auf: Control) -> void:
	if _sperrschrift == null:
		return
	# Blatt-Marke vor der Zeile
	_blattmarke(auf, Vector2(8, 12), 9.0)
	var ort := Vector2(30, 20)
	auf.draw_string(_sperrschrift, ort + Vector2(1.5, 2.0), TEXT_UNTERTITEL,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UNTERTITEL_GROESSE, Color(0, 0, 0, 0.65))
	auf.draw_string(_sperrschrift, ort, TEXT_UNTERTITEL,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UNTERTITEL_GROESSE,
			Color(0.93, 0.89, 0.80))
	# Zierlinie darunter
	var breite: float = _sperrschrift.get_string_size(TEXT_UNTERTITEL,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UNTERTITEL_GROESSE).x + 30.0
	auf.draw_line(Vector2(0, 38), Vector2(breite, 38), Color(1.0, 0.78, 0.32, 0.35), 2.0)


## Kleines Blatt als Wortmarke – gezeichnet, kein Bild.
func _blattmarke(auf: Control, mitte: Vector2, r: float) -> void:
	var punkte := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		punkte.append(mitte + Vector2(-r + 2.0 * r * t, -sin(t * PI) * r * 0.62))
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		punkte.append(mitte + Vector2(-r + 2.0 * r * t, sin(t * PI) * r * 0.62))
	auf.draw_colored_polygon(punkte, Farben.LAUB_HELL)
	auf.draw_line(mitte - Vector2(r, 0), mitte + Vector2(r, 0),
			Farben.LAUB_DUNKEL, 1.5)


# ---------------------------------------------------------------- Menü

func _baue_menue() -> void:
	_neuer_eintrag("Spielen", _starten)
	_neuer_eintrag("Einstellungen", Spielfluss.zu_optionen)
	_neuer_eintrag("Fortschritt zurücksetzen", _dialog_oeffnen)
	# Im Browser gibt es kein Beenden – dort bleibt der Eintrag weg.
	if not OS.has_feature("web"):
		_neuer_eintrag("Beenden", func() -> void: get_tree().quit())


func _neuer_eintrag(text: String, tat: Callable) -> void:
	var nummer := _eintraege.size()
	var eintrag := MenueEintrag.new()
	eintrag.beschriftung = text
	eintrag.position = Vector2(RAND, MENUE_OBEN
			+ nummer * (EINTRAG_HOEHE + EINTRAG_ABSTAND))
	eintrag.size = Vector2(EINTRAG_BREITE, EINTRAG_HOEHE)
	eintrag.ueberfahren.connect(func() -> void: _waehle(nummer))
	eintrag.angetippt.connect(func() -> void: _ausloesen())
	add_child(eintrag)
	_eintraege.append(eintrag)
	_aktionen.append(tat)


func _waehle(nummer: int) -> void:
	if _eintraege.is_empty():
		return
	_index = posmod(nummer, _eintraege.size())
	for i in _eintraege.size():
		_eintraege[i].setze_auswahl(i == _index and not _dialog_offen)


func _waehle_dialog(nummer: int) -> void:
	if _dialog_eintraege.is_empty():
		return
	_dialog_index = posmod(nummer, _dialog_eintraege.size())
	for i in _dialog_eintraege.size():
		_dialog_eintraege[i].setze_auswahl(i == _dialog_index)


func _ausloesen() -> void:
	if _blockiert:
		return
	if _dialog_offen:
		_dialog_aktionen[_dialog_index].call()
	else:
		_aktionen[_index].call()


func _starten() -> void:
	_blockiert = true
	var ablauf := create_tween()
	ablauf.tween_property(_blende, "color:a", 1.0, 0.35)
	ablauf.tween_callback(Spielfluss.zum_hub)


# ------------------------------------------------------------ Rückfrage

func _baue_dialog() -> void:
	_dialog = Control.new()
	_dialog.name = "Rueckfrage"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog.draw.connect(_zeichne_dialog)
	_dialog.resized.connect(func() -> void:
		_dialog.queue_redraw()
		_dialog_ausrichten())
	_dialog.visible = false
	add_child(_dialog)

	_neuer_dialog_eintrag("Ja, alles zurücksetzen", 0, _zuruecksetzen)
	_neuer_dialog_eintrag("Nein, doch nicht", 1, _dialog_schliessen)


func _neuer_dialog_eintrag(text: String, nummer: int, tat: Callable) -> void:
	var eintrag := MenueEintrag.new()
	eintrag.beschriftung = text
	eintrag.schriftgroesse = 23
	eintrag.size = DIALOG_EINTRAG
	eintrag.ueberfahren.connect(func() -> void: _waehle_dialog(nummer))
	eintrag.angetippt.connect(func() -> void: _ausloesen())
	_dialog.add_child(eintrag)
	_dialog_eintraege.append(eintrag)
	_dialog_aktionen.append(tat)


## Fläche der Tafel, mittig im Bild.
func _dialog_tafel() -> Rect2:
	var mitte := _dialog.size * 0.5
	return Rect2(Vector2(mitte.x - DIALOG_TAFEL.x * 0.5,
			mitte.y - DIALOG_TAFEL.y * 0.5), DIALOG_TAFEL)


func _zeichne_dialog() -> void:
	_dialog.draw_rect(Rect2(Vector2.ZERO, _dialog.size), Color(0.02, 0.03, 0.03, 0.72))
	var tafel := _dialog_tafel()
	_runde_flaeche(_dialog, tafel.grow(4.0), Color(1.0, 0.78, 0.32, 0.12), 18)
	_runde_flaeche(_dialog, tafel, Color(0.08, 0.09, 0.08, 0.97), 16)
	_runde_rahmen(_dialog, tafel, Color(1.0, 0.78, 0.32, 0.55), 16, 2.0)

	var schrift := _dialog.get_theme_default_font()
	if schrift == null:
		return
	var mitte_x := tafel.position.x + tafel.size.x * 0.5
	_mittig(_dialog, schrift, Vector2(mitte_x, tafel.position.y + 48.0),
			"Fortschritt zurücksetzen?", 27, Color(1.0, 0.93, 0.74))
	_mittig(_dialog, schrift, Vector2(mitte_x, tafel.position.y + 80.0),
			"Alle freigeschalteten Level gehen verloren.", 18,
			Color(0.84, 0.83, 0.78))


func _dialog_oeffnen() -> void:
	_dialog_offen = true
	_dialog.visible = true
	_dialog.modulate.a = 0.0
	_dialog.queue_redraw()
	_dialog_ausrichten()
	for e in _eintraege:
		e.setze_auswahl(false)
	_waehle_dialog(1)          # Vorauswahl: Nein
	create_tween().tween_property(_dialog, "modulate:a", 1.0, 0.18)


## Legt die beiden Antwort-Tafeln mittig unter den Text der Rückfrage.
func _dialog_ausrichten() -> void:
	var tafel := _dialog_tafel()
	for i in _dialog_eintraege.size():
		_dialog_eintraege[i].position = Vector2(
				tafel.position.x + (tafel.size.x - DIALOG_EINTRAG.x) * 0.5,
				tafel.position.y + 108.0 + i * (DIALOG_EINTRAG.y + 8.0))


func _dialog_schliessen() -> void:
	_dialog_offen = false
	_dialog.visible = false
	_waehle(_index)


func _zuruecksetzen() -> void:
	Spielfluss.zuruecksetzen()
	_dialog_schliessen()
	_zeige_meldung("Fortschritt zurückgesetzt")


# ---------------------------------------------------------- Fortschritt

func _baue_fortschritt() -> void:
	_fortschritt = _feld(Vector2(RAND, -128.0), Vector2(620, 70),
			_zeichne_fortschritt, Control.PRESET_BOTTOM_LEFT)
	_hinweis = _feld(Vector2(-HINWEIS_BREITE - RAND * 0.5, -52.0),
			Vector2(HINWEIS_BREITE, 30), _zeichne_hinweis,
			Control.PRESET_BOTTOM_RIGHT)
	_meldung = _feld(Vector2(RAND, -176.0), Vector2(520, 32),
			_zeichne_meldung, Control.PRESET_BOTTOM_LEFT)


func _zeichne_fortschritt(auf: Control) -> void:
	var schrift := auf.get_theme_default_font()
	if schrift == null:
		return
	var gesamt := Spielfluss.LEVEL_GESAMT
	var frei: int = mini(Spielfluss.freigeschaltet, gesamt)
	var fertig := Spielfluss.geschafft.size()

	# Rautenreihe: gefüllt = geschafft, hell = offen, matt = verschlossen
	var schritt := 15.0
	for i in gesamt:
		var mitte := Vector2(6.0 + i * schritt, 10.0)
		var nummer := i + 1
		if Spielfluss.geschafft.has(nummer):
			_raute(auf, mitte, 5.5, GOLD, true)
		elif nummer <= frei:
			_raute(auf, mitte, 5.5, Color(1.0, 0.93, 0.78, 0.85), false)
		else:
			_raute(auf, mitte, 4.5, Color(1, 1, 1, 0.30), true)

	var zeile := "%d von %d Leveln freigeschaltet  ·  %d geschafft" % [frei, gesamt, fertig]
	auf.draw_string(_sperrschrift, Vector2(0, 44) + Vector2(1, 1.5), zeile,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 0.6))
	auf.draw_string(_sperrschrift, Vector2(0, 44), zeile,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.88, 0.86, 0.80, 0.92))


func _raute(auf: Control, mitte: Vector2, r: float, farbe: Color, gefuellt: bool) -> void:
	var ecken := PackedVector2Array([
		mitte + Vector2(0, -r), mitte + Vector2(r, 0),
		mitte + Vector2(0, r), mitte + Vector2(-r, 0),
	])
	if gefuellt:
		auf.draw_colored_polygon(ecken, farbe)
	else:
		var zug := ecken.duplicate()
		zug.append(ecken[0])
		auf.draw_polyline(zug, farbe, 1.6)


func _zeichne_hinweis(auf: Control) -> void:
	if _sperrschrift == null:
		return
	auf.draw_string(_sperrschrift, Vector2(1, 21.5), TEXT_HINWEIS,
			HORIZONTAL_ALIGNMENT_RIGHT, auf.size.x, 15, Color(0, 0, 0, 0.55))
	auf.draw_string(_sperrschrift, Vector2(0, 20), TEXT_HINWEIS,
			HORIZONTAL_ALIGNMENT_RIGHT, auf.size.x, 15, Color(0.90, 0.89, 0.85, 0.72))


func _zeichne_meldung(auf: Control) -> void:
	if _meldung_text.is_empty() or _sperrschrift == null:
		return
	auf.draw_string(_sperrschrift, Vector2(0, 20), _meldung_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)


func _zeige_meldung(text: String) -> void:
	_meldung_text = text
	_meldung_zeit = 2.2
	_meldung.modulate.a = 1.0
	_meldung.queue_redraw()


func _auf_fortschritt() -> void:
	_fortschritt.queue_redraw()


# ------------------------------------------------------------ Einblenden

func _baue_blende() -> void:
	_blende = ColorRect.new()
	_blende.name = "Blende"
	_blende.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blende.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blende.color = Color(0, 0, 0, 1)
	add_child(_blende)


func _einblenden() -> void:
	_blockiert = true
	_titel.modulate.a = 0.0
	_titel.scale = Vector2(1.06, 1.06)
	_untertitel.modulate.a = 0.0
	_fortschritt.modulate.a = 0.0
	_hinweis.modulate.a = 0.0
	_meldung.modulate.a = 0.0
	for e in _eintraege:
		e.modulate.a = 0.0

	var ablauf := create_tween()
	ablauf.set_parallel(true)
	ablauf.tween_property(_blende, "color:a", 0.0, 0.9)
	ablauf.tween_property(_titel, "modulate:a", 1.0, 0.6).set_delay(0.25)
	ablauf.tween_property(_titel, "scale", Vector2.ONE, 0.7) \
			.set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ablauf.tween_property(_untertitel, "modulate:a", 1.0, 0.5).set_delay(0.65)
	for i in _eintraege.size():
		ablauf.tween_property(_eintraege[i], "modulate:a", 1.0, 0.35) \
				.set_delay(0.9 + i * 0.09)
	ablauf.tween_property(_fortschritt, "modulate:a", 1.0, 0.5).set_delay(1.2)
	ablauf.tween_property(_hinweis, "modulate:a", 1.0, 0.5).set_delay(1.4)
	ablauf.chain().tween_callback(func() -> void: _blockiert = false)


func _process(delta: float) -> void:
	if _meldung_zeit > 0.0:
		_meldung_zeit -= delta
		if _meldung_zeit <= 0.0:
			create_tween().tween_property(_meldung, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------- Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if _blockiert:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		_schiebe(1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_schiebe(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_ausloesen()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _dialog_offen:
			_dialog_schliessen()
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()


func _schiebe(richtung: int) -> void:
	if _dialog_offen:
		_waehle_dialog(_dialog_index + richtung)
	else:
		_waehle(_index + richtung)


# ------------------------------------------------------- Zeichenhelfer

func _mittig(auf: Control, schrift: Font, mitte: Vector2, text: String,
		groesse: int, farbe: Color) -> void:
	var breite := schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse).x
	var ort := Vector2(mitte.x - breite * 0.5, mitte.y)
	auf.draw_string(schrift, ort + Vector2(1.0, 1.5), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, Color(0, 0, 0, 0.55))
	auf.draw_string(schrift, ort, text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)


func _runde_flaeche(auf: Control, feld: Rect2, farbe: Color, radius: int) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = farbe
	stil.set_corner_radius_all(radius)
	stil.draw(auf.get_canvas_item(), feld)


func _runde_rahmen(auf: Control, feld: Rect2, farbe: Color, radius: int,
		staerke: float) -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0, 0, 0, 0)
	stil.border_color = farbe
	stil.set_border_width_all(int(staerke))
	stil.set_corner_radius_all(radius)
	stil.draw(auf.get_canvas_item(), feld)
