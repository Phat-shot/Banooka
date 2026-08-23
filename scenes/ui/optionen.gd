extends Control
## Einstellungen: eigene Spielfigur wählen und ihre Größe justieren.
##
## Aufbau wie der Startbildschirm – Tafeln aus MenueEintrag, alles
## gezeichnet statt geladen. Rechts steht eine Vorschau in einem eigenen
## kleinen 3D-Bild: ohne sie wäre nicht zu sehen, was die Einpassung mit
## einer fremden Datei anstellt.
##
## Bedienung: hoch/runter wählt, links/rechts ändert den Wert, Bestätigen
## löst aus, Abbrechen geht zurück.

const RAND := 96.0
const TITEL_OBEN := 92.0
const MENUE_OBEN := 210.0
const EINTRAG_BREITE := 470.0
const EINTRAG_HOEHE := 54.0
const EINTRAG_ABSTAND := 12.0

const GOLD := Color(1.0, 0.78, 0.32)
const HELL := Color(0.94, 0.93, 0.88)
const MATT := Color(1, 1, 1, 0.5)

## Schrittweite der Größenjustierung.
const SCHRITT := 0.05

var _eintraege: Array[MenueEintrag] = []
var _aktionen: Array[Callable] = []
var _index := 0
var _blockiert := false

var _meldung := ""
var _meldung_zeit := 0.0

var _vorschau: SubViewport
var _vorschau_figur: Node3D
var _vorschau_drehung := 0.0
var _dateiwahl: FileDialog


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grund := ColorRect.new()
	grund.name = "Grund"
	grund.color = Color(0.05, 0.08, 0.08)
	grund.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grund.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grund)

	_baue_vorschau()
	_baue_kopf()
	_baue_menue()
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
		queue_redraw()


# ------------------------------------------------------------ Aufbau

func _baue_kopf() -> void:
	var kopf := Control.new()
	kopf.set_anchors_preset(Control.PRESET_FULL_RECT)
	kopf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kopf.draw.connect(_zeichne_kopf.bind(kopf))
	add_child(kopf)


func _zeichne_kopf(auf: Control) -> void:
	var schrift := auf.get_theme_default_font()
	if schrift == null:
		return
	_text(auf, schrift, Vector2(RAND, TITEL_OBEN), "EINSTELLUNGEN", 46, GOLD)
	_text(auf, schrift, Vector2(RAND, TITEL_OBEN + 34.0),
			"Eigene Figur als .glb – sie wird auf Spielergröße eingepasst",
			17, MATT)

	# Ablageort nennen: ohne ihn weiß niemand, wohin mit der Datei.
	var unten := auf.size.y - 92.0
	_text(auf, schrift, Vector2(RAND, unten), "Ablage", 14, GOLD)
	_text(auf, schrift, Vector2(RAND, unten + 24.0),
			ProjectSettings.globalize_path(Einstellungen.ORDNER), 14, MATT)
	if not _meldung.is_empty():
		_text(auf, schrift, Vector2(RAND, unten + 50.0), _meldung, 17,
				Color(1.0, 0.62, 0.4))


func _baue_menue() -> void:
	for eintrag in _eintraege:
		eintrag.queue_free()
	_eintraege.clear()
	_aktionen.clear()

	_neuer_eintrag("Figur:  %s" % _figur_name(), _figur_weiter)
	_neuer_eintrag("Größe:  %.2f ×" % Einstellungen.modell_groesse, _groesse_weiter)
	if _dateiwahl_moeglich():
		_neuer_eintrag("Datei wählen …", _datei_waehlen)
	if not Einstellungen.eigenes_modell.is_empty():
		_neuer_eintrag("Diese Figur löschen", _figur_loeschen)
	_neuer_eintrag("Zurück", _zurueck)
	_waehle(mini(_index, _eintraege.size() - 1))


func _neuer_eintrag(text: String, tat: Callable) -> void:
	var nummer := _eintraege.size()
	var eintrag := MenueEintrag.new()
	eintrag.beschriftung = text
	eintrag.schriftgroesse = 24
	eintrag.position = Vector2(RAND, MENUE_OBEN
			+ nummer * (EINTRAG_HOEHE + EINTRAG_ABSTAND))
	eintrag.size = Vector2(EINTRAG_BREITE, EINTRAG_HOEHE)
	eintrag.ueberfahren.connect(func() -> void: _waehle(nummer))
	eintrag.angetippt.connect(func() -> void: _ausloesen())
	add_child(eintrag)
	_eintraege.append(eintrag)
	_aktionen.append(tat)


## Kleines eigenes 3D-Bild rechts, in dem die Figur sich dreht.
func _baue_vorschau() -> void:
	var rahmen := SubViewportContainer.new()
	rahmen.name = "Vorschau"
	rahmen.stretch = true
	rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rahmen.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	rahmen.offset_left = -430.0
	rahmen.offset_top = -190.0
	rahmen.offset_right = -70.0
	rahmen.offset_bottom = 190.0
	add_child(rahmen)

	_vorschau = SubViewport.new()
	_vorschau.size = Vector2i(360, 380)
	_vorschau.transparent_bg = true
	_vorschau.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	rahmen.add_child(_vorschau)

	var licht := DirectionalLight3D.new()
	licht.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	licht.light_energy = 1.15
	_vorschau.add_child(licht)

	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 0.95, 3.1)
	kamera.rotation_degrees.x = -8.0
	kamera.fov = 42.0
	_vorschau.add_child(kamera)

	# Bodenscheibe als Größenbezug – ohne sie schwebt die Figur im Nichts.
	var scheibe := MeshInstance3D.new()
	var zylinder := CylinderMesh.new()
	zylinder.top_radius = 0.95
	zylinder.bottom_radius = 0.95
	zylinder.height = 0.06
	scheibe.mesh = zylinder
	scheibe.position.y = -0.03
	scheibe.material_override = Materialbibliothek.einfarbig(Farben.FELS_HELL, 0.8)
	_vorschau.add_child(scheibe)

	_vorschau_neu_bestuecken()


## Baut die Figur in der Vorschau neu auf – gewählte Datei oder Beuteldachs.
func _vorschau_neu_bestuecken() -> void:
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
		geladen = ModellLader.laden(pfad, Einstellungen.modell_groesse)
	if geladen == null:
		# Beuteldachs: baut sich selbst auf und ist damit der Maßstab.
		geladen = SpielerModell.new()
		if not pfad.is_empty():
			_zeige_meldung("Datei nicht lesbar – zeige den Beuteldachs")
	halter.add_child(geladen)
	_vorschau.add_child(halter)
	_vorschau_figur = halter


# ------------------------------------------------------------ Aktionen

func _figur_name() -> String:
	if Einstellungen.eigenes_modell.is_empty():
		return "Beuteldachs (Standard)"
	return Einstellungen.eigenes_modell


## Schaltet durch Standard und alle gefundenen Dateien.
func _figur_weiter(richtung: int = 1) -> void:
	var liste := PackedStringArray([""])
	liste.append_array(Einstellungen.modelle())
	if liste.size() <= 1:
		_zeige_meldung("Keine eigene Datei im Ablageordner gefunden")
		return
	var jetzt := liste.find(Einstellungen.eigenes_modell)
	if jetzt < 0:
		jetzt = 0
	Einstellungen.waehle_modell(liste[posmod(jetzt + richtung, liste.size())])


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
	Einstellungen.entfernen(name)
	_zeige_meldung("%s gelöscht" % name)


func _zurueck() -> void:
	_blockiert = true
	Spielfluss.zum_splash()


## Nur dort anbieten, wo es einen Dateidialog gibt – im Browser nicht.
func _dateiwahl_moeglich() -> bool:
	return not OS.has_feature("web")


func _datei_waehlen() -> void:
	if _dateiwahl == null:
		_dateiwahl = FileDialog.new()
		_dateiwahl.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_dateiwahl.access = FileDialog.ACCESS_FILESYSTEM
		_dateiwahl.use_native_dialog = true
		_dateiwahl.filters = PackedStringArray(["*.glb,*.gltf ; glTF-Figur"])
		_dateiwahl.title = "Eigene Figur wählen"
		_dateiwahl.file_selected.connect(_auf_datei)
		add_child(_dateiwahl)
	_dateiwahl.popup_centered_ratio(0.7)


func _auf_datei(pfad: String) -> void:
	var fehler := Einstellungen.uebernehmen(pfad)
	_zeige_meldung(fehler if not fehler.is_empty()
			else "%s übernommen" % pfad.get_file())


func _auf_geaendert() -> void:
	_vorschau_neu_bestuecken()
	_baue_menue()
	queue_redraw()


func _zeige_meldung(text: String) -> void:
	_meldung = text
	_meldung_zeit = 4.0
	queue_redraw()


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
	if _eintraege.is_empty():
		return
	_index = posmod(nummer, _eintraege.size())
	for i in _eintraege.size():
		_eintraege[i].setze_auswahl(i == _index)


## `richtung` gilt nur für Einträge, die einen Wert durchschalten; die
## übrigen ignorieren sie und tun beim Bestätigen immer dasselbe.
func _ausloesen(richtung: int = 1) -> void:
	if _blockiert or _aktionen.is_empty():
		return
	var tat := _aktionen[_index]
	if tat.get_argument_count() > 0:
		tat.call(richtung)
	else:
		tat.call()


# ------------------------------------------------------------ Zeichnen

func _text(auf: Control, schrift: Font, pos: Vector2, inhalt: String,
		groesse: int, farbe: Color) -> void:
	auf.draw_string(schrift, pos + Vector2(1.0, 1.5), inhalt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, Color(0, 0, 0, 0.55))
	auf.draw_string(schrift, pos, inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)
