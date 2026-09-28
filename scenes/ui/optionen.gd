extends Control
## Einstellungen: eigene Spielfigur wählen und ihre Größe justieren,
## Lautstärke, Zeitmodus und Debugmodus.
##
## Aufbau wie der Startbildschirm – Tafeln aus MenueEintrag, alles
## gezeichnet statt geladen, Aussehen aus `UiStil`. Links stehen die
## Zeilen, jede mit ihrem Wert rechts (‹ Wert ›, Schalter oder
## Stufenbalken). Rechts steht eine Vorschau in einem eigenen kleinen
## 3D-Bild: ohne sie wäre nicht zu sehen, was die Einpassung mit einer
## fremden Datei anstellt. Darunter der Ablageort und kurze Meldungen.
##
## Bedienung: hoch/runter wählt, links/rechts ändert den Wert, Bestätigen
## löst aus, Abbrechen geht zurück.

const RAND := 96.0
const TITEL_OBEN := 92.0
## Neun Zeilen (mit eigener Figur) enden bei 172 + 8 · 56 + 48 = 668 und
## passen damit in 720 px Höhe – vorher lagen die letzten unter dem Rand.
const MENUE_OBEN := 172.0
const EINTRAG_BREITE := 500.0
const EINTRAG_HOEHE := 48.0
const EINTRAG_ABSTAND := 8.0
## Rechte Spalte: Vorschau (360 x 380, rechts mittig) und darunter Ablage
## und Meldungen, in derselben Breite.
const VORSCHAU := Vector2(360.0, 380.0)
const VORSCHAU_RAND := 70.0
const SPALTE_BREITE := 420.0

## Waldtöne des Hintergrunds, oben heller.
const GRUND_OBEN := Color(0.08, 0.13, 0.10)
const GRUND_UNTEN := Color(0.02, 0.04, 0.035)
const MELDUNG_FARBE := Color(1.0, 0.72, 0.48)
## So lange steht eine Meldung, davon die letzten 0,4 s im Ausblenden.
const MELDUNG_DAUER := 4.0

## Schrittweite der Größenjustierung.
const SCHRITT := 0.05

var _eintraege: Array[MenueEintrag] = []
var _aktionen: Array[Callable] = []
## Schlüssel der Zeilen, so wie sie gerade stehen. Solange sich die Menge
## nicht ändert, werden nur die Werte nachgetragen – ein Neubau ließe
## jede Auswahl-Überblendung von vorn beginnen.
var _schluessel: Array[String] = []
var _index := 0
var _blockiert := false

var _meldung := ""
var _meldung_zeit := 0.0

var _vorschau: SubViewport
var _vorschau_rahmen: SubViewportContainer
var _vorschau_figur: Node3D
var _vorschau_drehung := 0.0
## Was die Vorschau gerade zeigt. Nur wenn sich Figur, Größe oder
## Blickrichtung ändern, wird sie neu bestückt – Zeitmodus und Lautstärke
## lassen die Figur weiterdrehen.
var _vorschau_stand := ""
var _dateiwahl: FileDialog
var _kopf: Control
var _fuss: Control
var _blende: UiStil.Blende
## Eigene Kopie der Meldungsfläche: Sie blendet mit der Meldung aus.
var _meldungsflaeche := UiStil.eigene(&"kachel")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStil.thema()

	var grund := Control.new()
	grund.name = "Grund"
	grund.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grund.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grund.draw.connect(_zeichne_grund.bind(grund))
	grund.resized.connect(grund.queue_redraw)
	add_child(grund)

	_baue_vorschau()
	_baue_kopf()
	_baue_menue()
	_einschweben()

	_blende = UiStil.Blende.new()
	add_child(_blende)
	# Der Startbildschirm blendet ab, bevor er hierher wechselt – also aus
	# dem Dunkel heraus beginnen, dann ist der Wechsel ein Übergang.
	_blende.setzen(1.0)
	_blende.auf(0.3)

	Einstellungen.geaendert.connect(_auf_geaendert)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	_vorschau_drehung += delta * 0.6
	if is_instance_valid(_vorschau_figur):
		_vorschau_figur.rotation.y = _vorschau_drehung
	if _meldung_zeit > 0.0:
		_meldung_zeit -= delta
		if _meldung_zeit <= 0.0:
			_meldung = ""
		_fuss.queue_redraw()


# ------------------------------------------------------------ Aufbau

func _baue_kopf() -> void:
	_kopf = Control.new()
	_kopf.name = "Kopf"
	_kopf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kopf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kopf.draw.connect(_zeichne_kopf.bind(_kopf))
	add_child(_kopf)

	_fuss = Control.new()
	_fuss.name = "Fuss"
	_fuss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fuss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuss.draw.connect(_zeichne_fuss.bind(_fuss))
	_fuss.resized.connect(_fuss.queue_redraw)
	add_child(_fuss)


## Hintergrund: Waldverlauf, ein warmer Lichtfleck hinter der Vorschau
## (die Figur steht im Licht wie auf einer Lichtung), ein paar schräge
## Lichtbahnen von oben rechts wie im Startbildschirm, dazu die Vignette.
func _zeichne_grund(auf: Control) -> void:
	var feld := Rect2(Vector2.ZERO, auf.size)
	UiStil.verlauf(auf, feld, GRUND_OBEN, GRUND_UNTEN)
	var mitte := _vorschau_mitte(auf.size)
	var schein := UiStil.radialverlauf(Color(1.0, 0.85, 0.55, 0.22), Color(1.0, 0.85, 0.55, 0.0))
	auf.draw_texture_rect(schein, Rect2(mitte - Vector2(300, 300), Vector2(600, 600)), false)
	for i in 3:
		_lichtbahn(auf, auf.size.x * (0.55 + 0.13 * i), 90.0 + 40.0 * i,
				0.034 - 0.008 * i)
	UiStil.vignette(auf, feld, 0.5)


## Eine schräge Lichtbahn von oben: in der Mitte am hellsten, zu beiden
## Seiten weich auslaufend, nach unten verlöschend. Zwei Hälften mit
## Farbverlauf je Ecke – ein Vieleck mit harter Kante sähe aus wie ein
## Streifen Tapete.
func _lichtbahn(auf: Control, x: float, breite: float, deckung: float) -> void:
	var neigung := auf.size.y * 0.45
	var h := auf.size.y
	var klar := Color(1.0, 0.88, 0.62, 0.0)
	var hell := Color(1.0, 0.88, 0.62, deckung)
	for seite in [-1.0, 1.0]:
		var aussen := x + float(seite) * breite * 0.5
		auf.draw_polygon(PackedVector2Array([
			Vector2(x, 0.0), Vector2(aussen, 0.0),
			Vector2(aussen - neigung, h), Vector2(x - neigung, h),
		]), PackedColorArray([hell, klar, klar, klar]))


func _zeichne_kopf(auf: Control) -> void:
	UiStil.text(auf, Vector2(RAND, TITEL_OBEN), "EINSTELLUNGEN", 46,
			Farben.UI_GOLD, &"titel")
	UiStil.text(auf, Vector2(RAND + 2.0, TITEL_OBEN + 34.0),
			"Figur, Klang und Spielweise – links/rechts ändert den Wert",
			17, Farben.UI_TEXT_RUHE, &"text", 3)


## Unter der Vorschau: wohin eigene Figuren gehören, und darunter kurze
## Meldungen als Chip, der nach ein paar Sekunden ausblendet.
func _zeichne_fuss(auf: Control) -> void:
	var mitte := _vorschau_mitte(auf.size)
	var links := mitte.x - SPALTE_BREITE * 0.5
	var y := mitte.y + VORSCHAU.y * 0.5 + 30.0
	# Ablageort nennen: ohne ihn weiß niemand, wohin mit der Datei.
	UiStil.text(auf, Vector2(mitte.x, y), "ABLAGE FÜR EIGENE FIGUREN", 13,
			Farben.UI_GOLD, &"sperr", 3, HORIZONTAL_ALIGNMENT_CENTER)
	var pfad := ProjectSettings.globalize_path(Einstellungen.ORDNER)
	pfad = UiStil.kuerzen(UiStil.schrift(), pfad, 14, SPALTE_BREITE, true)
	UiStil.text(auf, Vector2(mitte.x, y + 22.0), pfad, 14, Farben.UI_MATT,
			&"text", 3, HORIZONTAL_ALIGNMENT_CENTER)

	if _meldung.is_empty():
		return
	var deckung := clampf(_meldung_zeit / 0.4, 0.0, 1.0)
	var groesse := 16
	var zs := UiStil.schrift()
	var innen := SPALTE_BREITE - 40.0
	var hoehe := zs.get_multiline_string_size(_meldung, HORIZONTAL_ALIGNMENT_CENTER,
			innen, groesse, 2).y
	var chip := Rect2(links, y + 44.0, SPALTE_BREITE, hoehe + 20.0)
	# Beim Erscheinen gleitet der Chip 8 px herauf.
	var hinein := clampf((MELDUNG_DAUER - _meldung_zeit) / 0.25, 0.0, 1.0)
	chip.position.y += (1.0 - ease(hinein, 0.4)) * 8.0
	var grund := UiStil.flaeche(&"kachel")
	_meldungsflaeche.bg_color = Color(grund.bg_color, grund.bg_color.a * deckung)
	_meldungsflaeche.border_color = Color(grund.border_color, grund.border_color.a * deckung)
	_meldungsflaeche.shadow_color = Color(grund.shadow_color, grund.shadow_color.a * deckung)
	_meldungsflaeche.draw(auf.get_canvas_item(), chip)
	UiStil.absatz(auf, Vector2(chip.position.x + 20.0, chip.position.y + 10.0
			+ zs.get_ascent(groesse)), _meldung, groesse,
			Color(MELDUNG_FARBE, deckung), innen, &"text", 2, 3,
			HORIZONTAL_ALIGNMENT_CENTER)


## Mitte der Vorschau im Bild (rechts, senkrecht mittig).
func _vorschau_mitte(flaeche: Vector2) -> Vector2:
	return Vector2(flaeche.x - VORSCHAU_RAND - VORSCHAU.x * 0.5, flaeche.y * 0.5)


## Die Zeilen, wie sie gerade sein sollen: Schlüssel, Beschriftung, Art,
## Wert und Tat. Blickrichtung und Löschen gibt es nur mit eigener Figur.
func _zeilen() -> Array[Dictionary]:
	var eigen := not Einstellungen.eigenes_modell.is_empty()
	var liste: Array[Dictionary] = []
	liste.append({"schluessel": "figur", "text": "Figur", "art": MenueEintrag.Art.WAHL,
			"wert": _figur_name(), "tat": _figur_weiter})
	liste.append({"schluessel": "groesse", "text": "Größe", "art": MenueEintrag.Art.WAHL,
			"wert": "%.2f ×" % Einstellungen.modell_groesse, "tat": _groesse_weiter})
	liste.append({"schluessel": "lautstaerke", "text": "Lautstärke",
			"art": MenueEintrag.Art.STUFEN, "wert": _lautstaerke_text(),
			"stufe": _lautstaerke_stufe(), "tat": _lautstaerke_weiter})
	if eigen:
		liste.append({"schluessel": "drehung", "text": "Blickrichtung",
				"art": MenueEintrag.Art.WAHL,
				"wert": "%d°" % roundi(Einstellungen.modell_drehung),
				"tat": _drehung_weiter})
	if _dateiwahl_moeglich():
		liste.append({"schluessel": "datei", "text": "Datei wählen …",
				"tat": _datei_waehlen})
	if eigen:
		liste.append({"schluessel": "loeschen", "text": "Diese Figur löschen",
				"tat": _figur_loeschen})
	liste.append({"schluessel": "zeitmodus", "text": "Zeitmodus",
			"art": MenueEintrag.Art.SCHALTER, "an": Einstellungen.zeitmodus,
			"tat": _zeitmodus_umschalten})
	liste.append({"schluessel": "debug", "text": "Debugmodus",
			"art": MenueEintrag.Art.SCHALTER, "an": Einstellungen.debug,
			"tat": _debug_umschalten})
	liste.append({"schluessel": "zurueck", "text": "Zurück", "tat": _zurueck})
	return liste


## Baut die Zeilen auf – oder trägt nur die Werte nach, wenn dieselben
## Zeilen schon stehen.
func _baue_menue() -> void:
	var zeilen := _zeilen()
	var schluessel: Array[String] = []
	for zeile in zeilen:
		schluessel.append(String(zeile["schluessel"]))
	if schluessel == _schluessel:
		for i in zeilen.size():
			_fuelle(_eintraege[i], zeilen[i])
		return

	for eintrag in _eintraege:
		eintrag.queue_free()
	_eintraege.clear()
	_aktionen.clear()
	_schluessel = schluessel
	for zeile in zeilen:
		_neuer_eintrag(zeile)
	_index = mini(_index, _eintraege.size() - 1)
	for i in _eintraege.size():
		_eintraege[i].setze_auswahl(i == _index, true)


func _neuer_eintrag(zeile: Dictionary) -> void:
	var nummer := _eintraege.size()
	var eintrag := MenueEintrag.new()
	eintrag.schriftgroesse = 23
	eintrag.position = Vector2(RAND, MENUE_OBEN
			+ nummer * (EINTRAG_HOEHE + EINTRAG_ABSTAND))
	eintrag.size = Vector2(EINTRAG_BREITE, EINTRAG_HOEHE)
	_fuelle(eintrag, zeile)
	eintrag.ueberfahren.connect(func() -> void: _waehle(nummer))
	eintrag.angetippt.connect(func() -> void: _ausloesen())
	add_child(eintrag)
	_eintraege.append(eintrag)
	_aktionen.append(zeile["tat"] as Callable)


func _fuelle(eintrag: MenueEintrag, zeile: Dictionary) -> void:
	eintrag.beschriftung = String(zeile["text"])
	var art: MenueEintrag.Art = zeile.get("art", MenueEintrag.Art.SCHLICHT)
	eintrag.art = art
	eintrag.wert = String(zeile.get("wert", ""))
	eintrag.eingeschaltet = bool(zeile.get("an", false))
	eintrag.stufe = int(zeile.get("stufe", 0))


## Beim Öffnen gleiten die Zeilen gestaffelt von links herein – kurz, denn
## wer hierher kommt, will etwas einstellen.
func _einschweben() -> void:
	for i in _eintraege.size():
		UiStil.einschweben(_eintraege[i], Vector2(-28.0, 0.0), 0.3, 0.05 + i * 0.03)


## Kleines eigenes 3D-Bild rechts, in dem die Figur sich dreht – auf einem
## Steinsockel, mit Führungslicht, kühlem Kantenlicht und weichem Schatten,
## damit sie aussieht wie im Spiel und nicht wie ausgeschnitten.
func _baue_vorschau() -> void:
	_vorschau_rahmen = SubViewportContainer.new()
	_vorschau_rahmen.name = "Vorschau"
	_vorschau_rahmen.stretch = true
	_vorschau_rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vorschau_rahmen.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_vorschau_rahmen.offset_left = -VORSCHAU_RAND - VORSCHAU.x
	_vorschau_rahmen.offset_top = -VORSCHAU.y * 0.5
	_vorschau_rahmen.offset_right = -VORSCHAU_RAND
	_vorschau_rahmen.offset_bottom = VORSCHAU.y * 0.5
	add_child(_vorschau_rahmen)

	_vorschau = SubViewport.new()
	_vorschau.size = Vector2i(VORSCHAU)
	_vorschau.transparent_bg = true
	# Eigene Welt: Die Vorschau sieht nur, was in ihr steht.
	_vorschau.own_world_3d = true
	_vorschau.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vorschau_rahmen.add_child(_vorschau)

	var umgebung := Environment.new()
	umgebung.background_mode = Environment.BG_CLEAR_COLOR
	umgebung.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	umgebung.ambient_light_color = Color(0.55, 0.60, 0.55)
	umgebung.ambient_light_energy = 0.6
	umgebung.tonemap_mode = Environment.TONE_MAPPER_ACES
	umgebung.tonemap_exposure = 1.1
	var welt := WorldEnvironment.new()
	welt.environment = umgebung
	_vorschau.add_child(welt)

	var licht := DirectionalLight3D.new()
	licht.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	licht.light_energy = 1.25
	licht.light_color = Color(1.0, 0.94, 0.84)
	_vorschau.add_child(licht)
	# Kantenlicht von hinten: zeichnet die Figur vom dunklen Grund ab.
	var kante := DirectionalLight3D.new()
	kante.rotation_degrees = Vector3(-20.0, 160.0, 0.0)
	kante.light_energy = 0.7
	kante.light_color = Color(0.75, 0.85, 1.0)
	_vorschau.add_child(kante)

	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 0.95, 3.1)
	kamera.rotation_degrees.x = -8.0
	kamera.fov = 42.0
	_vorschau.add_child(kamera)

	# Sockel als Größenbezug – ohne ihn schwebt die Figur im Nichts. Ein
	# Baumstumpf wie im Wurzelwald: helle Schnittfläche mit einem Jahresring,
	# darunter die breitere Rinde.
	var sockel := Node3D.new()
	sockel.name = "Sockel"
	_vorschau.add_child(sockel)
	_scheibe(sockel, 0.95, 0.06, -0.03, Farben.RINDE_HELL)
	_scheibe(sockel, 0.58, 0.062, -0.03, Farben.RINDE_HELL.darkened(0.12))
	_scheibe(sockel, 1.02, 0.18, -0.14, Farben.RINDE)
	var schatten := Effekte.blobschatten(sockel, 0.6)
	Effekte.blobschatten_setzen(schatten, Vector3.ZERO, Vector3.UP, 0.5)

	_vorschau_neu_bestuecken()


func _scheibe(eltern: Node3D, radius: float, hoehe: float, mitte_y: float,
		farbe: Color) -> void:
	var scheibe := MeshInstance3D.new()
	var zylinder := CylinderMesh.new()
	zylinder.top_radius = radius
	zylinder.bottom_radius = radius
	zylinder.height = hoehe
	zylinder.radial_segments = 48
	scheibe.mesh = zylinder
	scheibe.position.y = mitte_y
	scheibe.material_override = Materialbibliothek.einfarbig(farbe, 0.8)
	scheibe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eltern.add_child(scheibe)


## Baut die Figur in der Vorschau neu auf – gewählte Datei oder Beuteldachs.
func _vorschau_neu_bestuecken() -> void:
	_vorschau_stand = _vorschau_kennung()
	if is_instance_valid(_vorschau_figur):
		_vorschau_figur.queue_free()
	_vorschau_figur = null
	if _vorschau == null:
		return

	var halter := Node3D.new()
	halter.name = "Figur"
	# Die Figur blickt in -Z, die Kamera steht bei +Z – ohne die halbe
	# Drehung sähe man ihr in der Vorschau auf den Rücken.
	_vorschau_drehung = PI
	var pfad := Einstellungen.modell_pfad()
	var geladen: Node3D = null
	if not pfad.is_empty():
		geladen = ModellLader.laden(pfad, Einstellungen.modell_groesse,
				Einstellungen.modell_drehung)
	if geladen == null:
		# Beuteldachs: baut sich selbst auf und ist damit der Maßstab.
		geladen = SpielerModell.new()
		if not pfad.is_empty():
			# Den echten Grund zeigen statt eines Sammelsatzes – sonst
			# rät man, ob es an der Datei, am Format oder am Gerät liegt.
			var grund := ModellLader.letzter_fehler
			_zeige_meldung("%s – zeige den Beuteldachs"
					% (grund if not grund.is_empty() else "Datei nicht lesbar"))
	halter.add_child(geladen)
	_vorschau.add_child(halter)
	_vorschau_figur = halter


func _vorschau_kennung() -> String:
	return "%s|%.3f|%.1f" % [Einstellungen.modell_pfad(),
			Einstellungen.modell_groesse, Einstellungen.modell_drehung]


# ------------------------------------------------------------ Aktionen

func _figur_name() -> String:
	return Einstellungen.anzeigename(Einstellungen.eigenes_modell)


## Schaltet durch Standard und alle gefundenen Dateien.
func _figur_weiter(richtung: int = 1) -> void:
	var liste := PackedStringArray([""])
	liste.append_array(Einstellungen.modelle())
	if liste.size() <= 1:
		_zeige_meldung("Keine weitere Figur gefunden – eine .glb nach "
				+ "assets/modelle legen oder über 'Datei wählen' laden")
		return
	var jetzt := liste.find(Einstellungen.eigenes_modell)
	if jetzt < 0:
		jetzt = 0
	Einstellungen.waehle_modell(liste[posmod(jetzt + richtung, liste.size())])


## Dreht die Figur in Vierteln. Fremde Modelle schauen fast immer
## entgegen unserer Konvention; wessen Figur dann rückwärts läuft, dreht
## sie hier zurecht.
func _drehung_weiter(richtung: int = 1) -> void:
	Einstellungen.drehe_weiter(90.0 * float(richtung))


## Lautstärke in Zehnteln, ganz unten stumm. Ein Schieberegler wäre hier
## fehl am Platz: Das Bild wird mit Pfeiltasten, Steuerkreuz und Fingertipp
## bedient, und dafür ist ein Durchschalten in Stufen das Passende.
func _lautstaerke_stufe() -> int:
	if Klang.stumm:
		return 0
	return roundi(Klang.lautstaerke * 10.0)


func _lautstaerke_text() -> String:
	if Klang.stumm or Klang.lautstaerke <= 0.001:
		return "stumm"
	return "%d %%" % roundi(Klang.lautstaerke * 100.0)


func _lautstaerke_weiter(richtung: int = 1) -> void:
	var stufe := posmod(_lautstaerke_stufe() + richtung, 11)
	Klang.stumm_schalten(stufe <= 0)
	Klang.setze_lautstaerke(float(stufe) * 0.1)
	# Gleich hörbar machen, sonst stellt man blind ein.
	if stufe > 0:
		Klang.spiele("frucht")
	_baue_menue()


func _groesse_weiter(richtung: int = 1) -> void:
	var wert := Einstellungen.modell_groesse + SCHRITT * float(richtung)
	# Am Ende der Skala umlaufen, damit ein einzelner Knopf reicht.
	if wert > 2.0 + 0.001:
		wert = 0.5
	elif wert < 0.5 - 0.001:
		wert = 2.0
	Einstellungen.setze_groesse(wert)


func _figur_loeschen() -> void:
	var name := Einstellungen.eigenes_modell
	if name.is_empty():
		return
	if not Einstellungen.loeschbar(name):
		_zeige_meldung("Mitgelieferte Figuren lassen sich nicht löschen")
		return
	Einstellungen.entfernen(name)
	_zeige_meldung("%s gelöscht" % name)


func _zeitmodus_umschalten(_richtung: int = 1) -> void:
	Einstellungen.zeitmodus = not Einstellungen.zeitmodus
	Einstellungen.speichern()
	_baue_menue()
	if Einstellungen.zeitmodus:
		_zeige_meldung("Zeitmodus an – Uhr im Level, Zeitkisten halten sie an")
	else:
		_zeige_meldung("Zeitmodus aus")


## Debugmodus: unendlich Leben, immer Schutz, alle Räume offen.
func _debug_umschalten(_richtung: int = 1) -> void:
	Einstellungen.debug = not Einstellungen.debug
	Einstellungen.speichern()
	_baue_menue()
	if Einstellungen.debug:
		_zeige_meldung("Debugmodus an – unendlich Leben, immer Schutz, alle Räume offen")
	else:
		_zeige_meldung("Debugmodus aus")


## Zurück zum Startbildschirm: kurz abblenden, der Startbildschirm blendet
## auf der anderen Seite wieder auf.
func _zurueck() -> void:
	if _blockiert:
		return
	_blockiert = true
	_blende.zu(0.18).tween_callback(Spielfluss.zum_splash)


## Überall anbieten: am Rechner über den Dateidialog von Godot, im
## Browser über ein Hochladefeld der Seite.
func _dateiwahl_moeglich() -> bool:
	return true


func _datei_waehlen() -> void:
	if OS.has_feature("web"):
		_web_datei_waehlen()
		return
	if _dateiwahl == null:
		_dateiwahl = FileDialog.new()
		_dateiwahl.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_dateiwahl.access = FileDialog.ACCESS_FILESYSTEM
		_dateiwahl.use_native_dialog = true
		_dateiwahl.filters = PackedStringArray(["*.glb,*.gltf ; glTF-Figur"])
		_dateiwahl.title = "Eigene Figur wählen"
		# Das Menü-Theme (Konturschrift, Goldknöpfe) ist für gezeichnete
		# Menüs gemacht; ein Dateidialog ohne Systemdialog bleibt schlicht.
		_dateiwahl.theme = ThemeDB.get_default_theme()
		_dateiwahl.file_selected.connect(_auf_datei)
		add_child(_dateiwahl)
	_dateiwahl.popup_centered_ratio(0.7)


# ------------------------------------------------- Hochladen im Browser

## Baut im Browser ein verstecktes Dateifeld und öffnet es.
##
## Godot kann im Web nicht auf das Dateisystem zugreifen; die Datei kommt
## deshalb über ein `<input type="file">` der Seite herein und wird als
## Base64 zurückgereicht. Das bläht sie um ein Drittel auf, ist aber der
## einzige Weg, Binärdaten über die Rückrufe der Brücke zu schicken.
##
## Browser öffnen einen Dateidialog nur kurz nach einer Nutzeraktion.
## Godot verarbeitet Eingaben im Hauptlauf, also ein paar Millisekunden
## später – das liegt bequem innerhalb der Frist, die die Browser dafür
## einräumen. Öffnet sich trotzdem nichts, sagt die Meldung Bescheid.
const WEB_SKRIPT := """
window.banookaDateiWaehlen = function (rueckruf) {
	var feld = document.createElement('input');
	feld.type = 'file';
	feld.accept = '.glb,.gltf';
	feld.style.display = 'none';
	document.body.appendChild(feld);
	feld.addEventListener('change', function () {
		var datei = feld.files && feld.files[0];
		document.body.removeChild(feld);
		if (!datei) { rueckruf('', ''); return; }
		var leser = new FileReader();
		leser.onload = function () {
			var roh = new Uint8Array(leser.result);
			var text = '';
			var block = 0x8000;
			for (var i = 0; i < roh.length; i += block) {
				text += String.fromCharCode.apply(null, roh.subarray(i, i + block));
			}
			rueckruf(datei.name, btoa(text));
		};
		leser.onerror = function () { rueckruf(datei.name, ''); };
		leser.readAsArrayBuffer(datei);
	});
	feld.click();
	return true;
};
"""

var _web_rueckruf: JavaScriptObject


func _web_datei_waehlen() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		_zeige_meldung("In diesem Browser nicht möglich")
		return
	JavaScriptBridge.eval(WEB_SKRIPT, true)
	# Der Rückruf muss am Objekt hängen bleiben, sonst räumt Godot ihn ab,
	# bevor der Browser die Datei gelesen hat.
	_web_rueckruf = JavaScriptBridge.create_callback(_auf_web_datei)
	var fenster := JavaScriptBridge.get_interface("window")
	if fenster == null:
		_zeige_meldung("In diesem Browser nicht möglich")
		return
	fenster.banookaDateiWaehlen(_web_rueckruf)
	_zeige_meldung("Datei im Browserfenster auswählen …")


## Kommt aus dem Browser zurück: [Dateiname, Base64-Inhalt].
func _auf_web_datei(werte: Array) -> void:
	if werte.size() < 2:
		return
	var name := String(werte[0])
	var inhalt := String(werte[1])
	if name.is_empty():
		_zeige_meldung("Keine Datei gewählt")
		return
	if inhalt.is_empty():
		_zeige_meldung("%s ließ sich nicht lesen" % name)
		return
	var fehler := Einstellungen.uebernehmen_daten(name,
			Marshalls.base64_to_raw(inhalt))
	_zeige_meldung(fehler if not fehler.is_empty() else "%s übernommen" % name)


func _auf_datei(pfad: String) -> void:
	var fehler := Einstellungen.uebernehmen(pfad)
	_zeige_meldung(fehler if not fehler.is_empty()
			else "%s übernommen" % pfad.get_file())


func _auf_geaendert() -> void:
	if _vorschau_kennung() != _vorschau_stand:
		_vorschau_neu_bestuecken()
	_baue_menue()


func _zeige_meldung(text: String) -> void:
	_meldung = text
	_meldung_zeit = MELDUNG_DAUER
	if _fuss != null:
		_fuss.queue_redraw()


# ------------------------------------------------------------ Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if _blockiert:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		_waehle(_index + 1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_waehle(_index - 1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_ausloesen(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_ausloesen(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_ausloesen()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_zurueck()
	else:
		return
	get_viewport().set_input_as_handled()


func _waehle(nummer: int) -> void:
	if _eintraege.is_empty() or _blockiert:
		return
	var neu := posmod(nummer, _eintraege.size())
	if neu != _index:
		MenueEintrag.klang_wahl()
	_index = neu
	for i in _eintraege.size():
		_eintraege[i].setze_auswahl(i == _index)


## `richtung` gilt nur für Einträge, die einen Wert durchschalten; die
## übrigen ignorieren sie und tun beim Bestätigen immer dasselbe.
func _ausloesen(richtung: int = 1) -> void:
	if _blockiert or _aktionen.is_empty():
		return
	var eintrag := _eintraege[_index]
	var tat := _aktionen[_index]
	if tat.get_argument_count() > 0:
		# Wertzeile: Der Pfeil auf der Seite, in die geschaltet wurde,
		# schnellt heraus. Klang nur, wo nicht ohnehin einer kommt (die
		# Lautstärke spielt selbst eine Probe).
		if eintrag.art == MenueEintrag.Art.WAHL or eintrag.art == MenueEintrag.Art.STUFEN:
			eintrag.wert_geschoben(richtung)
		else:
			eintrag.druecken()
		if eintrag.art != MenueEintrag.Art.STUFEN:
			MenueEintrag.klang_wahl()
		tat.call(richtung)
	else:
		eintrag.druecken()
		MenueEintrag.klang_ok()
		tat.call()
