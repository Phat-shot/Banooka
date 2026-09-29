extends Control
## Startbildschirm: Waldkulisse in 3D, Titelschriftzug, Menü und
## Fortschrittszeile.
##
## Aufbau (alles zur Laufzeit erzeugt, die Szene enthält nur den
## Wurzelknoten – siehe ARCHITEKTUR.md):
##
##   Kulisse      Node3D mit Wald, Licht, Himmel, Lichtfahnen und Pollen
##   Schleier     dunkler Verlauf links und unten plus Vignette, damit Text
##                lesbar bleibt und das Bild einen Rahmen hat
##   Titel        "BANOOKA", ein Feld je Buchstabe: plastisch mit Kontur,
##                fällt beim Start einzeln herein, wippt danach sacht und
##                bekommt alle paar Sekunden einen Glanzstreif (Shader)
##   Untertitel   eine Zeile, gesperrt gesetzt, mit wachsender Zierlinie
##   Menü         drei Tafeln: Neues Spiel, Spiel laden, Einstellungen
##   Fortschritt  25 Rauten plus Klartext, wie viel freigeschaltet ist
##   Hinweis      Bedienung – passend zu Tastatur, Controller oder Finger
##   Tafel        Overlay für die vier Speicherplätze und Rückfragen
##
## Aussehen aus `UiStil` (Schriften, Flächen, Text mit Kontur, Blende).
## Symbole werden gezeichnet (`_draw`) statt geladen – das Projekt kommt
## ohne fremde Assets aus.

# --- Maße (Entwurfsgröße 1280 x 720, Ränder wachsen mit dem Fenster) ---
const RAND := 96.0
## Der Schriftzug steht in Lilita One (`UiStil`, &"logo"). Sie läuft
## schmaler als die frühere Grundschrift; mit 116 px statt 104 px steht
## das Wort wieder etwa so breit da wie vorher. Die Grundlinie liegt bei
## `TITEL_OBEN + get_ascent()`, und die Oberlänge wächst mit der Größe –
## das Feld steht deshalb 12 px höher, damit die Grundlinie bleibt, wo sie
## war (y = 217), und die braune Tiefe nicht an den Untertitel stößt.
const TITEL_OBEN := 92.0
const TITEL_GROESSE := 116
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
const SCHLEIER := Color(0.03, 0.05, 0.05)
const UNTERTITEL_FARBE := Color(0.93, 0.89, 0.80)

const TEXT_TITEL := "BANOOKA"
const TEXT_UNTERTITEL := "Rennen, springen, wirbeln – durch fünf wilde Welten"
const TEXT_ZURUECK := "Zurück"
const HINWEIS_BREITE := 720.0
const HINWEIS_GROESSE := 15

## Glanzstreif und Wippen des Schriftzugs – beides im Shader, damit die
## Buchstaben nie neu gezeichnet werden müssen.
##
## Wippen: Jeder Buchstabe hebt und senkt sich um 2,5 px, der Takt hängt
## an seiner Lage im Bild (`MODEL_MATRIX[3].x`) – so läuft eine sanfte
## Welle durch das Wort, und alle teilen sich EIN Material.
## Glanz: ein schräges Band wandert alle ~8,7 s über den Schriftzug. Es
## hellt nur die helle Füllung auf (`hell`), nie die dunklen Konturen und
## die braune Tiefe – sonst sähe es aus wie ein grauer Wischer. Der Rand
## läuft glockenförmig aus: Ein hart begrenztes Band sah im Standbild aus
## wie ein halb weiß gefüllter Buchstabe.
const TITEL_SHADER := """
shader_type canvas_item;

uniform float wippen = 2.5;
uniform float glanz = 0.28;
uniform float glanz_breite = 18.0;

varying vec2 ort;

void vertex() {
	float takt = MODEL_MATRIX[3].x * 0.011;
	VERTEX.y += sin(TIME * 1.9 - takt) * wippen;
	ort = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float x = ort.x - ort.y * 0.35 - mod(TIME * 300.0, 2600.0) + 300.0;
	float band = exp(-x * x / (2.0 * glanz_breite * glanz_breite));
	float hell = smoothstep(0.55, 0.7, max(COLOR.r, COLOR.g));
	COLOR.rgb += band * hell * glanz;
}
"""

## Wurde die Eröffnung schon einmal gezeigt? Wer aus den Einstellungen
## zurückkommt, soll nicht noch einmal zwei Sekunden auf das Menü warten.
static var _eroeffnet := false
static var _titelstoff: ShaderMaterial = null

var _kulisse: SplashKulisse
var _schleier: Control
var _titel: Control
var _buchstaben: Array[Control] = []
var _untertitel: Control
var _fortschritt: Control
var _hinweis: Control
var _tafel: Control
var _tafelkoerper: Control
var _blende: UiStil.Blende

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
## Zierlinie unter dem Untertitel, 0..1 – wächst in der Eröffnung.
var _linie := 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStil.thema()

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
	InputHub.eingabeart_geaendert.connect(func(_art: int) -> void:
		_hinweis.queue_redraw())
	_waehle(0, true)
	_einblenden()
	set_process_unhandled_input(true)


## Legt ein Zeichenfeld an und hängt seine Zeichenroutine ein.
func _feld(ort: Vector2, groesse: Vector2, zeichner: Callable,
		anker: int = Control.PRESET_TOP_LEFT, eltern: Control = self) -> Control:
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
	eltern.add_child(knoten)
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
	var dunkel := Color(SCHLEIER, 0.70)
	var klar := Color(SCHLEIER, 0.0)

	# Verlauf von links: trägt Titel und Menü
	UiStil.verlauf(_schleier, Rect2(0, 0, b * 0.56, h), dunkel, klar, true)
	# Fuß und Kopf leicht abdunkeln – rahmt das Bild
	UiStil.verlauf(_schleier, Rect2(0, h - 190.0, b, 190.0), klar,
			Color(SCHLEIER, 0.72))
	UiStil.verlauf(_schleier, Rect2(0, 0, b, 130.0), Color(SCHLEIER, 0.40), klar)
	# Vignette: Die Ecken sinken ab, der Blick bleibt in der Bildmitte –
	# bei der Kamerafahrt wirkt der Wald so wie durch ein Objektiv gesehen.
	UiStil.vignette(_schleier, Rect2(0, 0, b, h), 0.42)


# --------------------------------------------------------------- Titel

## Der Schriftzug besteht aus einem Feld je Buchstabe, damit jeder für
## sich hereinfallen und wippen kann. Die Lage jedes Buchstabens kommt aus
## der Breite des Wortanfangs – so bleiben Sperrung und Unterschneidung
## genau wie beim ganzen Wort.
func _baue_titel() -> void:
	_titel = Control.new()
	_titel.name = "Titel"
	_titel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titel.position = Vector2(RAND, TITEL_OBEN)
	_titel.size = Vector2(820, 150)
	add_child(_titel)
	var zs := UiStil.schrift(&"logo")
	var grundlinie := zs.get_ascent(TITEL_GROESSE)
	for i in TEXT_TITEL.length():
		# Anfang des Buchstabens = Wortanfang bis einschließlich ihm, minus
		# ihm selbst. So stimmt es, ob die Sperrung hinter dem letzten
		# Zeichen mitgezählt wird oder nicht.
		var breite := _wortbreite(zs, TEXT_TITEL[i])
		var links := _wortbreite(zs, TEXT_TITEL.substr(0, i + 1)) - breite
		var buchstabe := _feld(Vector2(links, 0.0), Vector2(breite, 150.0),
				_zeichne_buchstabe.bind(TEXT_TITEL[i]), Control.PRESET_TOP_LEFT, _titel)
		buchstabe.name = "Buchstabe%d" % i
		# Drehpunkt auf der Grundlinie, mittig: Beim Hereinfallen setzt der
		# Buchstabe auf und federt, statt um seine Ecke zu kippen.
		buchstabe.pivot_offset = Vector2(breite * 0.5, grundlinie)
		buchstabe.material = _titel_material()
		_buchstaben.append(buchstabe)
	_untertitel = _feld(Vector2(RAND + 6.0, UNTERTITEL_OBEN), Vector2(720, 56),
			_zeichne_untertitel)


func _wortbreite(zs: Font, text: String) -> float:
	if text.is_empty():
		return 0.0
	return zs.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TITEL_GROESSE).x


static func _titel_material() -> ShaderMaterial:
	if _titelstoff == null:
		var shader := Shader.new()
		shader.code = TITEL_SHADER
		_titelstoff = ShaderMaterial.new()
		_titelstoff.shader = shader
	return _titelstoff


func _zeichne_buchstabe(auf: Control, zeichen: String) -> void:
	var zs := UiStil.schrift(&"logo")
	var ort := Vector2(0.0, zs.get_ascent(TITEL_GROESSE))

	# Schlagschatten
	auf.draw_string_outline(zs, ort + Vector2(6, 12), zeichen,
			HORIZONTAL_ALIGNMENT_LEFT, -1, TITEL_GROESSE, 20, Color(0, 0, 0, 0.32))
	# Tiefe: mehrere Konturen nach unten versetzt ⇒ plastischer Block
	for d in range(10, 0, -1):
		var t := float(d) / 10.0
		auf.draw_string_outline(zs, ort + Vector2(0, d), zeichen,
				HORIZONTAL_ALIGNMENT_LEFT, -1, TITEL_GROESSE, 17,
				Farben.UI_TITEL_TIEFE.darkened(0.35 * t))
	# Harte Kontur und helle Fläche
	auf.draw_string_outline(zs, ort, zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1,
			TITEL_GROESSE, 17, Farben.UI_TITEL_KONTUR)
	auf.draw_string(zs, ort, zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1,
			TITEL_GROESSE, Farben.UI_TITEL_FUELLUNG)
	# Feiner Glanz auf der Oberkante
	auf.draw_string(zs, ort - Vector2(0, 3), zeichen, HORIZONTAL_ALIGNMENT_LEFT,
			-1, TITEL_GROESSE, Color(1, 1, 1, 0.16))


func _zeichne_untertitel(auf: Control) -> void:
	# Blatt-Marke vor der Zeile
	_blattmarke(auf, Vector2(8, 12), 9.0)
	var ort := Vector2(30, 20)
	var breite := UiStil.text(auf, ort, TEXT_UNTERTITEL, UNTERTITEL_GROESSE,
			UNTERTITEL_FARBE, &"sperr", 4) + 30.0
	# Zierlinie darunter; in der Eröffnung wächst sie von links heraus.
	if _linie > 0.0:
		auf.draw_line(Vector2(0, 38), Vector2(breite * _linie, 38),
				Color(Farben.UI_GOLD, 0.45), 2.0)
		auf.draw_line(Vector2(0, 40), Vector2(breite * _linie, 40),
				Color(0, 0, 0, 0.25), 1.0)


## Kleines Blatt als Wortmarke – gezeichnet, kein Bild.
func _blattmarke(auf: Control, mitte: Vector2, r: float) -> void:
	var punkte := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		punkte.append(mitte + Vector2(-r + 2.0 * r * t, -sin(t * PI) * r * 0.62))
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		punkte.append(mitte + Vector2(-r + 2.0 * r * t, sin(t * PI) * r * 0.62))
	var umriss := punkte.duplicate()
	umriss.append(punkte[0])
	auf.draw_polyline(umriss, Farben.UI_KONTUR, 3.0, true)
	auf.draw_colored_polygon(punkte, Farben.LAUB_HELL)
	auf.draw_line(mitte - Vector2(r, 0), mitte + Vector2(r, 0),
			Farben.LAUB_DUNKEL, 1.5, true)


func _setze_linie(wert: float) -> void:
	_linie = wert
	_untertitel.queue_redraw()


# ---------------------------------------------------------------- Menü

func _baue_menue() -> void:
	_neuer_eintrag("Neues Spiel", _slots_fuer_neues_spiel)
	_neuer_eintrag("Spiel laden", _slots_zum_laden)
	_neuer_eintrag("Einstellungen", func() -> void: _verlassen(Spielfluss.zu_optionen, 0.18))


func _neuer_eintrag(text: String, tat: Callable) -> void:
	var nummer := _eintraege.size()
	var eintrag := MenueEintrag.new()
	eintrag.beschriftung = text
	eintrag.position = Vector2(RAND, MENUE_OBEN
			+ nummer * (EINTRAG_HOEHE + EINTRAG_ABSTAND))
	eintrag.size = Vector2(EINTRAG_BREITE, EINTRAG_HOEHE)
	eintrag.ueberfahren.connect(func() -> void:
		if not _tafel_offen and not _blockiert:
			_waehle(nummer))
	# Ein Tipp während der Eröffnung kürzt sie ab und gilt dann sofort –
	# und zwar für den angetippten Eintrag, auch wenn das Überfahren davor
	# noch gesperrt war.
	eintrag.angetippt.connect(func() -> void:
		_einblendung_abkuerzen()
		if not _tafel_offen and not _blockiert:
			_waehle(nummer, true)
			_ausloesen())
	add_child(eintrag)
	_eintraege.append(eintrag)
	_aktionen.append(tat)


func _waehle(nummer: int, still: bool = false) -> void:
	if _eintraege.is_empty():
		return
	var neu := posmod(nummer, _eintraege.size())
	if neu != _index and not still:
		MenueEintrag.klang_wahl()
	_index = neu
	for i in _eintraege.size():
		_eintraege[i].setze_auswahl(i == _index and not _tafel_offen)


## Wählt einen Eintrag. Gesperrte (leere Plätze) werden in Laufrichtung
## übersprungen, damit man nicht auf einem toten Eintrag stehen bleibt.
func _waehle_tafel(nummer: int, richtung: int = 1, still: bool = false) -> void:
	if _tafel_eintraege.is_empty():
		return
	var anzahl := _tafel_eintraege.size()
	var ziel := posmod(nummer, anzahl)
	for _i in anzahl:
		if ziel >= _tafel_gesperrt.size() or not _tafel_gesperrt[ziel]:
			break
		ziel = posmod(ziel + signi(richtung), anzahl)
	if ziel != _tafel_index and not still:
		MenueEintrag.klang_wahl()
	_tafel_index = ziel
	for i in _tafel_eintraege.size():
		_tafel_eintraege[i].setze_auswahl(i == _tafel_index)


func _ausloesen() -> void:
	if _blockiert:
		return
	MenueEintrag.klang_ok()
	if _tafel_offen:
		_tafel_eintraege[_tafel_index].druecken()
		_tafel_aktionen[_tafel_index].call()
	else:
		_eintraege[_index].druecken()
		_aktionen[_index].call()


## Blendet ab und führt dann die Tat aus – für jeden Szenenwechsel.
## 0,35 s vor dem Ladeschirm (der Wechsel ins Spiel), kürzer zu den
## Einstellungen: Dort wartet kein Aufbau, nur ein anderes Bild.
func _verlassen(tat: Callable, dauer: float = 0.35) -> void:
	_blockiert = true
	_blende.zu(dauer).tween_callback(tat)


# --------------------------------------------------------- Speicherplätze

## Beschriftung eines Platzes: Abschnitt, Fortschritt und Früchte.
func _slot_zeile(daten: Dictionary) -> String:
	if not bool(daten.get("belegt", false)):
		return "leer"
	var frei: int = mini(int(daten.get("freigeschaltet", 1)), Spielfluss.LEVEL_GESAMT)
	var zeile := "%s  ·  Level %02d  ·  %d geschafft  ·  %d Früchte" % [
			String(daten.get("raum", "")), frei,
			int(daten.get("geschafft", 0)), int(daten.get("fruechte", 0))]
	# Zeitrelikte nur nennen, wenn es welche gibt: Wer den Zeitmodus nie
	# eingeschaltet hat, soll auf dem Platz keine Null lesen müssen.
	var relikte := int(daten.get("relikte", 0))
	if relikte > 0:
		zeile += "  ·  %d Zeitrelikte" % relikte
	return zeile


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
#
# Zwei Ebenen: `_tafel` dunkelt das ganze Bild ab, `_tafelkoerper` trägt
# Tafel und Einträge und federt beim Öffnen auf – so wächst nur die
# Tafel, nicht der Schleier, der sonst an den Bildrändern Lücken zeigte.

func _baue_tafel() -> void:
	_tafel = Control.new()
	_tafel.name = "Tafel"
	_tafel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tafel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tafel.draw.connect(func() -> void:
		_tafel.draw_rect(Rect2(Vector2.ZERO, _tafel.size), Farben.UI_ABDUNKELN))
	_tafel.visible = false
	add_child(_tafel)

	_tafelkoerper = Control.new()
	_tafelkoerper.name = "Koerper"
	_tafelkoerper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tafelkoerper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tafelkoerper.pivot_offset_ratio = Vector2(0.5, 0.5)
	_tafelkoerper.draw.connect(_zeichne_tafel)
	_tafelkoerper.resized.connect(func() -> void:
		_tafel.queue_redraw()
		_tafelkoerper.queue_redraw()
		_tafel_ausrichten())
	_tafel.add_child(_tafelkoerper)


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
		# Nur solange die Tafel offen ist: Beim Ausblenden liegt sie noch
		# kurz im Bild, ein Tipp dort darf nicht das Hauptmenü auslösen.
		tafel.ueberfahren.connect(func() -> void:
			if _tafel_offen:
				_waehle_tafel(nummer))
		# Ein Tipp gilt der angetippten Zeile. Leere Plätze (gesperrt) tun
		# nichts – das Überfahren davor hat die Auswahl schon auf die nächste
		# offene Zeile geschoben, und die soll nicht ungefragt auslösen.
		tafel.angetippt.connect(func() -> void:
			if _tafel_offen and nummer < _tafel_gesperrt.size() \
					and not _tafel_gesperrt[nummer]:
				_waehle_tafel(nummer, 1, true)
				_ausloesen())
		_tafelkoerper.add_child(tafel)
		_tafel_eintraege.append(tafel)
		_tafel_aktionen.append(wert.get("tat", _tafel_schliessen) as Callable)
		_tafel_gesperrt.append(tafel.gedaempft)
		hoehe += tafel.size.y + TAFEL_LUECKE
	_tafel_hoehe = hoehe - TAFEL_LUECKE + TAFEL_FUSS

	_tafel_offen = true
	_hinweis.queue_redraw()
	for e in _eintraege:
		e.setze_auswahl(false)
	_tafel_ausrichten()
	_tafelkoerper.queue_redraw()
	_tafel_index = -1
	_waehle_tafel(vorauswahl, 1, true)
	# Die gewählte Zeile steht sofort, nur die Tafel selbst kommt herein –
	# sonst liefen zwei Bewegungen übereinander.
	if _tafel_index >= 0:
		_tafel_eintraege[_tafel_index].setze_auswahl(true, true)
	if not war_offen or not _tafel.visible:
		UiStil.einblenden(_tafel, 0.18)
		_tafelkoerper.scale = Vector2(0.96, 0.96)
		var t := _tafelkoerper.create_tween()
		t.tween_property(_tafelkoerper, ^"scale", Vector2.ONE, 0.28) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Fläche der Tafel, mittig im Bild.
func _tafel_flaeche() -> Rect2:
	var mitte := _tafelkoerper.size * 0.5
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
	var flaeche := _tafel_flaeche()
	UiStil.zeichne(_tafelkoerper, flaeche, &"tafel")
	var mitte_x := flaeche.position.x + flaeche.size.x * 0.5
	UiStil.text(_tafelkoerper, Vector2(mitte_x, flaeche.position.y + 50.0),
			_tafel_titel, 30, Farben.UI_GOLD_HELL, &"titel", 5,
			HORIZONTAL_ALIGNMENT_CENTER)
	# Zierstrich unter dem Titel: zwei feine Goldlinien mit Raute
	var strich_y := flaeche.position.y + 64.0
	UiStil.raute(_tafelkoerper, Vector2(mitte_x, strich_y), 4.0, Farben.UI_GOLD)
	_tafelkoerper.draw_line(Vector2(mitte_x - 70.0, strich_y),
			Vector2(mitte_x - 10.0, strich_y), Color(Farben.UI_GOLD, 0.45), 1.5, true)
	_tafelkoerper.draw_line(Vector2(mitte_x + 10.0, strich_y),
			Vector2(mitte_x + 70.0, strich_y), Color(Farben.UI_GOLD, 0.45), 1.5, true)
	if not _tafel_unterzeile.is_empty():
		var zs := UiStil.schrift()
		var groesse := UiStil.passend(zs, _tafel_unterzeile, 17,
				flaeche.size.x - 48.0, 13)
		UiStil.text(_tafelkoerper, Vector2(mitte_x, flaeche.position.y + 90.0),
				_tafel_unterzeile, groesse, Farben.UI_TEXT_RUHE, &"text", 3,
				HORIZONTAL_ALIGNMENT_CENTER)


## Schließt das Overlay: Der Zustand wechselt sofort (Eingaben gehen
## wieder ans Menü), nur das Bild blendet kurz aus.
func _tafel_schliessen() -> void:
	_tafel_offen = false
	_hinweis.queue_redraw()
	UiStil.ausblenden(_tafel, 0.12)
	_waehle(_index, true)


# ---------------------------------------------------------- Fortschritt

func _baue_fortschritt() -> void:
	_fortschritt = _feld(Vector2(RAND, -128.0), Vector2(620, 70),
			_zeichne_fortschritt, Control.PRESET_BOTTOM_LEFT)
	_hinweis = _feld(Vector2(-HINWEIS_BREITE - RAND * 0.5, -52.0),
			Vector2(HINWEIS_BREITE, 30), _zeichne_hinweis,
			Control.PRESET_BOTTOM_RIGHT)


func _zeichne_fortschritt(auf: Control) -> void:
	var gesamt := Spielfluss.LEVEL_GESAMT
	# Im Startbildschirm ist noch kein Platz gewählt – gezeigt wird der
	# weiteste Stand über alle vier Plätze.
	var stand := Spielfluss.bester_stand()
	var erledigt: Dictionary = stand["geschafft"]
	var frei: int = mini(int(stand["freigeschaltet"]), gesamt)
	var fertig := erledigt.size()

	# Rautenreihe: gefüllt = geschafft, hell = offen, matt = verschlossen.
	# Nach je fünf Leveln (ein Raum) eine kleine Lücke – die Reihe liest
	# sich dann als fünf Welten statt als lange Kette.
	var schritt := 15.0
	for i in gesamt:
		var mitte := Vector2(6.0 + i * schritt + floorf(i / 5.0) * 7.0, 10.0)
		var nummer := i + 1
		if erledigt.has(nummer):
			UiStil.raute(auf, mitte, 6.5, Farben.UI_KONTUR)
			UiStil.raute(auf, mitte, 5.5, Farben.UI_GOLD)
		elif nummer <= frei:
			UiStil.raute(auf, mitte, 5.5, Color(1.0, 0.93, 0.78, 0.9), false, 1.8)
		else:
			UiStil.raute(auf, mitte, 4.5, Color(1, 1, 1, 0.30))

	var zeile := "%d von %d Leveln freigeschaltet  ·  %d geschafft" % [frei, gesamt, fertig]
	UiStil.text(auf, Vector2(0, 44), zeile, 16, Color(0.90, 0.88, 0.82), &"sperr", 3)


## Bedienhinweis unten rechts, passend zur zuletzt benutzten Eingabe:
## Tastennamen für die Tastatur, Symboltasten für den Controller, ein
## Wort für den Finger. "Zurück" steht nur da, wo es etwas bewirkt – in
## der Tafel der Speicherplätze.
func _zeichne_hinweis(auf: Control) -> void:
	var farbe := Color(0.92, 0.91, 0.87, 0.85)
	var y := 20.0
	var x := auf.size.x
	var teile: Array = []
	if InputHub.eingabeart == InputHub.Art.PAD:
		teile = [["", "Steuerkreuz wählen"], ["jump", "bestätigen"]]
		if _tafel_offen:
			teile.append(["slide", "zurück"])
	elif InputHub.eingabeart == InputHub.Art.TOUCH:
		teile = [["", "Eintrag antippen"]]
	else:
		teile = [["", "Pfeiltasten wählen"], ["", "Enter bestätigt"]]
		if _tafel_offen:
			teile.append(["", "Esc zurück"])
		elif DisplayServer.is_touchscreen_available():
			teile.append(["", "oder antippen"])
	# Von rechts nach links setzen, damit der Hinweis rechtsbündig bleibt.
	for i in range(teile.size() - 1, -1, -1):
		var teil: Array = teile[i]
		var symbol := String(teil[0])
		var text := String(teil[1])
		x -= UiStil.textbreite(text, HINWEIS_GROESSE, &"sperr")
		UiStil.text(auf, Vector2(x, y), text, HINWEIS_GROESSE, farbe, &"sperr", 3)
		if not symbol.is_empty():
			x -= 24.0
			var mitte := Vector2(x + 9.0, y - 5.0)
			auf.draw_circle(mitte, 10.5, Farben.UI_KONTUR, true, -1.0, true)
			PadSymbole.zeichne(auf, symbol, mitte, 6.0, PadSymbole.farbe(symbol), 2.0)
		if i > 0:
			x -= 34.0
			UiStil.raute(auf, Vector2(x + 17.0, y - 5.0), 2.5, Color(Farben.UI_GOLD, 0.7))


func _auf_fortschritt() -> void:
	_fortschritt.queue_redraw()


# ------------------------------------------------------------ Einblenden

func _baue_blende() -> void:
	_blende = UiStil.Blende.new()
	add_child(_blende)
	_blende.setzen(1.0)


## Eröffnung: Aus dem Dunkel blendet der Wald auf, die Buchstaben fallen
## einzeln herein und federn auf ihre Grundlinie, dann gleitet das Menü
## von links hinein. Beim zweiten Mal (zurück aus den Einstellungen) läuft
## alles auf gut ein Drittel verkürzt und ohne Buchstabenfall.
func _einblenden() -> void:
	_blockiert = true
	var k := 0.35 if _eroeffnet else 1.0
	for b in _buchstaben:
		b.modulate.a = 0.0
	_untertitel.modulate.a = 0.0
	_fortschritt.modulate.a = 0.0
	_hinweis.modulate.a = 0.0
	_linie = 0.0
	for e in _eintraege:
		e.modulate.a = 0.0
		e.position.x = RAND - 36.0

	var ablauf := create_tween()
	_einblendung = ablauf
	ablauf.set_parallel(true)
	ablauf.tween_property(_blende, ^"color:a", 0.0, 0.9 * k)
	for i in _buchstaben.size():
		var b := _buchstaben[i]
		var start := (0.25 + i * 0.06) * k
		ablauf.tween_property(b, ^"modulate:a", 1.0, 0.25 * k).set_delay(start)
		if not _eroeffnet:
			# Abwechselnd leicht links und rechts gekippt – wie hingeworfen.
			b.position.y = -70.0
			b.rotation = 0.3 if i % 2 == 0 else -0.3
			b.scale = Vector2(0.5, 0.5)
			ablauf.tween_property(b, ^"position:y", 0.0, 0.55).set_delay(start) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ablauf.tween_property(b, ^"rotation", 0.0, 0.55).set_delay(start) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ablauf.tween_property(b, ^"scale", Vector2.ONE, 0.5).set_delay(start) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ablauf.tween_property(_untertitel, ^"modulate:a", 1.0, 0.5 * k).set_delay(0.65 * k)
	ablauf.tween_method(_setze_linie, 0.0, 1.0, 0.6 * k).set_delay(0.75 * k) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in _eintraege.size():
		var start := (0.9 + i * 0.09) * k
		ablauf.tween_property(_eintraege[i], ^"modulate:a", 1.0, 0.35 * k).set_delay(start)
		ablauf.tween_property(_eintraege[i], ^"position:x", RAND, 0.45 * k) \
				.set_delay(start).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ablauf.tween_property(_fortschritt, ^"modulate:a", 1.0, 0.5 * k).set_delay(1.2 * k)
	ablauf.tween_property(_hinweis, ^"modulate:a", 1.0, 0.5 * k).set_delay(1.4 * k)
	ablauf.chain().tween_callback(_einblendung_fertig)


func _einblendung_fertig() -> void:
	_blockiert = false
	_einblendung = null
	_eroeffnet = true
	_blende.setzen(0.0)


## Bricht die Eröffnungs-Einblendung ab und stellt den Endzustand sofort her.
##
## Ohne das schluckte der Startbildschirm die ersten rund zwei Sekunden
## jede Eingabe: Wer gleich Enter drückt, bekam keinerlei Reaktion.
## Der Tween wird dazu ans Ende gespult, nicht abgebrochen – so landet
## jeder Buchstabe und jeder Eintrag genau dort, wo er hingehört, und der
## Schluss-Rückruf läuft wie sonst auch.
func _einblendung_abkuerzen() -> bool:
	if _einblendung == null:
		return false
	if is_instance_valid(_einblendung) and _einblendung.is_valid():
		_einblendung.custom_step(3600.0)
	if _einblendung != null:
		_einblendung_fertig()
	return true


# ------------------------------------------------------------- Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if _blockiert:
		# Während der Eröffnung: Einblendung überspringen und den Druck
		# ganz normal weiterbehandeln. Nur der Szenenwechsel bleibt dicht.
		# Abgekürzt wird nur für einen echten Druck – eine Mausbewegung über
		# der Kulisse oder ein leicht verrutschter Stick (unter halbem
		# Ausschlag gilt er nicht als gedrückt) soll den Buchstabenfall
		# nicht schlucken.
		if not event.is_pressed() or event.is_echo() \
				or not _einblendung_abkuerzen():
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
