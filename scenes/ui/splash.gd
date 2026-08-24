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
##   Menü         drei Tafeln: Neues Spiel, Spiel laden, Einstellungen
##   Fortschritt  25 Rauten plus Klartext, wie viel freigeschaltet ist
##   Tafel        Overlay für die vier Speicherplätze und Rückfragen
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
const TAFEL_BREITE := 560.0
const TAFEL_KOPF := 108.0        ## Platz über der ersten Zeile
const TAFEL_FUSS := 26.0
const TAFEL_EINTRAG := Vector2(452.0, 50.0)
const TAFEL_SLOT_HOEHE := 64.0
const TAFEL_LUECKE := 8.0

# --- Farben ---
const GOLD := Color(1.0, 0.78, 0.32)
const TITEL_FUELLUNG := Color(1.0, 0.90, 0.66)
const TITEL_TIEFE := Color(0.55, 0.24, 0.06)
const TITEL_KONTUR := Color(0.11, 0.06, 0.03)
const SCHLEIER := Color(0.03, 0.05, 0.05)

const TEXT_TITEL := "BANOOKA"
const TEXT_UNTERTITEL := "Rennen, springen, wirbeln – durch fünf wilde Welten"
const TEXT_HINWEIS := "Pfeiltasten wählen  ·  Enter bestätigt  ·  oder antippen"
const TEXT_ZURUECK := "Zurück"
const HINWEIS_BREITE := 600.0

var _kulisse: SplashKulisse
var _schleier: Control
var _titel: Control
var _untertitel: Control
var _fortschritt: Control
var _hinweis: Control
var _tafel: Control
var _blende: ColorRect

var _eintraege: Array[MenueEintrag] = []
var _aktionen: Array[Callable] = []
var _index := 0

var _tafel_eintraege: Array[MenueEintrag] = []
var _tafel_aktionen: Array[Callable] = []
var _tafel_index := 0
var _tafel_offen := false
var _tafel_titel := ""
var _tafel_unterzeile := ""
var _tafel_hoehe := 0.0
## Einträge, die nicht ausgewählt werden können (leere Speicherplätze).
var _tafel_gesperrt: Array[bool] = []

var _blockiert := false        ## während Einblendung und Szenenwechsel
## Läuft gerade die Eröffnungs-Einblendung? Sie lässt sich abkürzen; der
## Szenenwechsel am Ende dagegen nicht.
var _einblendung: Tween = null

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
	_baue_tafel()
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
	_neuer_eintrag("Neues Spiel", _slots_fuer_neues_spiel)
	_neuer_eintrag("Spiel laden", _slots_zum_laden)
	_neuer_eintrag("Einstellungen", Spielfluss.zu_optionen)


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
		_eintraege[i].setze_auswahl(i == _index and not _tafel_offen)


## Wählt einen Eintrag. Gesperrte (leere Plätze) werden in Laufrichtung
## übersprungen, damit man nicht auf einem toten Eintrag stehen bleibt.
func _waehle_tafel(nummer: int, richtung: int = 1) -> void:
	if _tafel_eintraege.is_empty():
		return
	var anzahl := _tafel_eintraege.size()
	var ziel := posmod(nummer, anzahl)
	for _i in anzahl:
		if ziel >= _tafel_gesperrt.size() or not _tafel_gesperrt[ziel]:
			break
		ziel = posmod(ziel + signi(richtung), anzahl)
	_tafel_index = ziel
	for i in _tafel_eintraege.size():
		_tafel_eintraege[i].setze_auswahl(i == _tafel_index)


func _ausloesen() -> void:
	if _blockiert:
		return
	if _tafel_offen:
		_tafel_aktionen[_tafel_index].call()
	else:
		_aktionen[_index].call()


## Blendet ab und führt dann die Tat aus – für jeden Szenenwechsel.
func _verlassen(tat: Callable) -> void:
	_blockiert = true
	var ablauf := create_tween()
	ablauf.tween_property(_blende, "color:a", 1.0, 0.35)
	ablauf.tween_callback(tat)


# --------------------------------------------------------- Speicherplätze

## Beschriftung eines Platzes: Abschnitt, Fortschritt und Früchte.
func _slot_zeile(daten: Dictionary) -> String:
	if not bool(daten.get("belegt", false)):
		return "leer"
	var frei: int = mini(int(daten.get("freigeschaltet", 1)), Spielfluss.LEVEL_GESAMT)
	return "%s  ·  Level %02d  ·  %d geschafft  ·  %d Früchte" % [
			String(daten.get("raum", "")), frei,
			int(daten.get("geschafft", 0)), int(daten.get("fruechte", 0))]


func _slots_fuer_neues_spiel() -> void:
	var liste: Array = []
	for slot in range(1, Spielfluss.SLOTS + 1):
		var daten := Spielfluss.slot_daten(slot)
		liste.append({
			"text": "Platz %d" % slot,
			"unter": _slot_zeile(daten),
			"tat": _neues_spiel_auf.bind(slot, bool(daten.get("belegt", false))),
		})
	liste.append({"text": TEXT_ZURUECK, "tat": _tafel_schliessen})
	_tafel_zeigen("Neues Spiel", "Auf welchem Platz soll gespielt werden?", liste)


func _slots_zum_laden() -> void:
	var liste: Array = []
	var belegt := false
	for slot in range(1, Spielfluss.SLOTS + 1):
		var daten := Spielfluss.slot_daten(slot)
		var voll := bool(daten.get("belegt", false))
		belegt = belegt or voll
		liste.append({
			"text": "Platz %d" % slot,
			"unter": _slot_zeile(daten),
			"gedaempft": not voll,
			"tat": _spiel_laden_von.bind(slot),
		})
	liste.append({"text": TEXT_ZURUECK, "tat": _tafel_schliessen})
	var unterzeile := "Welcher Spielstand soll weitergehen?"
	if not belegt:
		unterzeile = "Noch kein Spielstand vorhanden – erst ein neues Spiel beginnen."
	_tafel_zeigen("Spiel laden", unterzeile, liste)


func _neues_spiel_auf(slot: int, belegt: bool) -> void:
	if belegt:
		_ueberschreiben_fragen(slot)
		return
	_verlassen(Spielfluss.neues_spiel.bind(slot))


func _ueberschreiben_fragen(slot: int) -> void:
	_tafel_zeigen("Platz %d überschreiben?" % slot,
			"Der bisherige Spielstand auf diesem Platz geht verloren.", [
		{"text": "Ja, neu beginnen",
				"tat": func() -> void: _verlassen(Spielfluss.neues_spiel.bind(slot))},
		{"text": "Nein, doch nicht", "tat": _slots_fuer_neues_spiel},
	], 1)


func _spiel_laden_von(slot: int) -> void:
	_verlassen(func() -> void:
		if not Spielfluss.spiel_laden(slot):
			# Sollte nicht vorkommen; dann lieber zurück ins Menü als hängen.
			Spielfluss.zum_splash())


# ---------------------------------------------------------------- Tafel
#
# Ein Overlay für alles, was über dem Menü liegt: die Liste der vier
# Speicherplätze und die Rückfrage vor dem Überschreiben. Die Einträge
# werden bei jedem Öffnen neu gebaut, damit sie den aktuellen Stand der
# Speicherdateien zeigen.

func _baue_tafel() -> void:
	_tafel = Control.new()
	_tafel.name = "Tafel"
	_tafel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tafel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tafel.draw.connect(_zeichne_tafel)
	_tafel.resized.connect(func() -> void:
		_tafel.queue_redraw()
		_tafel_ausrichten())
	_tafel.visible = false
	add_child(_tafel)


## Öffnet das Overlay. `eintraege` ist eine Liste aus Wörterbüchern mit
## "text", wahlweise "unter" (zweite Zeile), "gedaempft" und "tat".
func _tafel_zeigen(titel: String, unterzeile: String, eintraege: Array,
		vorauswahl: int = 0) -> void:
	var war_offen := _tafel_offen
	_tafel_titel = titel
	_tafel_unterzeile = unterzeile
	for alt in _tafel_eintraege:
		alt.queue_free()
	_tafel_eintraege.clear()
	_tafel_aktionen.clear()
	_tafel_gesperrt.clear()

	var hoehe := TAFEL_KOPF
	for eintrag in eintraege:
		var wert: Dictionary = eintrag
		var unter := String(wert.get("unter", ""))
		var tafel := MenueEintrag.new()
		tafel.beschriftung = String(wert.get("text", ""))
		tafel.unterzeile = unter
		tafel.gedaempft = bool(wert.get("gedaempft", false))
		tafel.schriftgroesse = 23
		tafel.size = Vector2(TAFEL_EINTRAG.x,
				TAFEL_SLOT_HOEHE if not unter.is_empty() else TAFEL_EINTRAG.y)
		var nummer := _tafel_eintraege.size()
		tafel.ueberfahren.connect(func() -> void: _waehle_tafel(nummer))
		tafel.angetippt.connect(func() -> void: _ausloesen())
		_tafel.add_child(tafel)
		_tafel_eintraege.append(tafel)
		_tafel_aktionen.append(wert.get("tat", _tafel_schliessen) as Callable)
		_tafel_gesperrt.append(tafel.gedaempft)
		hoehe += tafel.size.y + TAFEL_LUECKE
	_tafel_hoehe = hoehe - TAFEL_LUECKE + TAFEL_FUSS

	_tafel_offen = true
	_tafel.visible = true
	for e in _eintraege:
		e.setze_auswahl(false)
	_tafel_ausrichten()
	_tafel.queue_redraw()
	_waehle_tafel(vorauswahl)
	if not war_offen:
		_tafel.modulate.a = 0.0
		create_tween().tween_property(_tafel, "modulate:a", 1.0, 0.18)


## Fläche der Tafel, mittig im Bild.
func _tafel_flaeche() -> Rect2:
	var mitte := _tafel.size * 0.5
	return Rect2(Vector2(mitte.x - TAFEL_BREITE * 0.5,
			mitte.y - _tafel_hoehe * 0.5), Vector2(TAFEL_BREITE, _tafel_hoehe))


func _tafel_ausrichten() -> void:
	var flaeche := _tafel_flaeche()
	var y := flaeche.position.y + TAFEL_KOPF
	for eintrag in _tafel_eintraege:
		eintrag.position = Vector2(
				flaeche.position.x + (flaeche.size.x - TAFEL_EINTRAG.x) * 0.5, y)
		y += eintrag.size.y + TAFEL_LUECKE


func _zeichne_tafel() -> void:
	_tafel.draw_rect(Rect2(Vector2.ZERO, _tafel.size), Color(0.02, 0.03, 0.03, 0.72))
	var flaeche := _tafel_flaeche()
	_runde_flaeche(_tafel, flaeche.grow(4.0), Color(1.0, 0.78, 0.32, 0.12), 18)
	_runde_flaeche(_tafel, flaeche, Color(0.08, 0.09, 0.08, 0.97), 16)
	_runde_rahmen(_tafel, flaeche, Color(1.0, 0.78, 0.32, 0.55), 16, 2.0)

	var schrift := _tafel.get_theme_default_font()
	if schrift == null:
		return
	var mitte_x := flaeche.position.x + flaeche.size.x * 0.5
	_mittig(_tafel, schrift, Vector2(mitte_x, flaeche.position.y + 48.0),
			_tafel_titel, 27, Color(1.0, 0.93, 0.74))
	if not _tafel_unterzeile.is_empty():
		_mittig(_tafel, schrift, Vector2(mitte_x, flaeche.position.y + 78.0),
				_tafel_unterzeile, 17, Color(0.84, 0.83, 0.78))


func _tafel_schliessen() -> void:
	_tafel_offen = false
	_tafel.visible = false
	_waehle(_index)


# ---------------------------------------------------------- Fortschritt

func _baue_fortschritt() -> void:
	_fortschritt = _feld(Vector2(RAND, -128.0), Vector2(620, 70),
			_zeichne_fortschritt, Control.PRESET_BOTTOM_LEFT)
	_hinweis = _feld(Vector2(-HINWEIS_BREITE - RAND * 0.5, -52.0),
			Vector2(HINWEIS_BREITE, 30), _zeichne_hinweis,
			Control.PRESET_BOTTOM_RIGHT)


func _zeichne_fortschritt(auf: Control) -> void:
	var schrift := auf.get_theme_default_font()
	if schrift == null:
		return
	var gesamt := Spielfluss.LEVEL_GESAMT
	# Im Startbildschirm ist noch kein Platz gewählt – gezeigt wird der
	# weiteste Stand über alle vier Plätze.
	var stand := Spielfluss.bester_stand()
	var erledigt: Dictionary = stand["geschafft"]
	var frei: int = mini(int(stand["freigeschaltet"]), gesamt)
	var fertig := erledigt.size()

	# Rautenreihe: gefüllt = geschafft, hell = offen, matt = verschlossen
	var schritt := 15.0
	for i in gesamt:
		var mitte := Vector2(6.0 + i * schritt, 10.0)
		var nummer := i + 1
		if erledigt.has(nummer):
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
	for e in _eintraege:
		e.modulate.a = 0.0

	var ablauf := create_tween()
	_einblendung = ablauf
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
	ablauf.chain().tween_callback(func() -> void:
		_blockiert = false
		_einblendung = null)


## Bricht die Eröffnungs-Einblendung ab und stellt den Endzustand sofort her.
##
## Ohne das schluckte der Startbildschirm die ersten rund zwei Sekunden
## jede Eingabe: Wer gleich Enter drückt, bekam keinerlei Reaktion.
func _einblendung_abkuerzen() -> bool:
	if _einblendung == null:
		return false
	if is_instance_valid(_einblendung) and _einblendung.is_valid():
		_einblendung.kill()
	_einblendung = null
	_blende.color.a = 0.0
	_titel.modulate.a = 1.0
	_titel.scale = Vector2.ONE
	_untertitel.modulate.a = 1.0
	_fortschritt.modulate.a = 1.0
	_hinweis.modulate.a = 1.0
	for e in _eintraege:
		e.modulate.a = 1.0
	_blockiert = false
	return true


# ------------------------------------------------------------- Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if _blockiert:
		# Während der Eröffnung: Einblendung überspringen und den Druck
		# ganz normal weiterbehandeln. Nur der Szenenwechsel bleibt dicht.
		if not _einblendung_abkuerzen():
			return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		_schiebe(1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_schiebe(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_ausloesen()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _tafel_offen:
			_tafel_schliessen()
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()


func _schiebe(richtung: int) -> void:
	if _tafel_offen:
		_waehle_tafel(_tafel_index + richtung, richtung)
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
