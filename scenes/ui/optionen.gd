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
	_neuer_eintrag(_lautstaerke_text(), _lautstaerke_weiter)
	if not Einstellungen.eigenes_modell.is_empty():
		_neuer_eintrag("Blickrichtung:  %d°" % roundi(Einstellungen.modell_drehung),
				_drehung_weiter)
	if _dateiwahl_moeglich():
		_neuer_eintrag("Datei wählen …", _datei_waehlen)
	if not Einstellungen.eigenes_modell.is_empty():
		_neuer_eintrag("Diese Figur löschen", _figur_loeschen)
	_neuer_eintrag("Debugmodus:  %s" % ("an" if Einstellungen.debug else "aus"),
			_debug_umschalten)
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
func _lautstaerke_text() -> String:
	if Klang.stumm or Klang.lautstaerke <= 0.001:
		return "Lautstärke:  stumm"
	return "Lautstärke:  %d %%" % roundi(Klang.lautstaerke * 100.0)


func _lautstaerke_weiter(richtung: int = 1) -> void:
	var stufe := roundi(Klang.lautstaerke * 10.0)
	if Klang.stumm:
		stufe = 0
	stufe = posmod(stufe + richtung, 11)
	Klang.stumm_schalten(stufe <= 0)
	Klang.setze_lautstaerke(float(stufe) * 0.1)
	# Gleich hörbar machen, sonst stellt man blind ein.
	if stufe > 0:
		Klang.spiele("frucht")
	_baue_menue()
	queue_redraw()


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


## Debugmodus: unendlich Leben, immer Schutz, alle Räume offen.
func _debug_umschalten(_richtung: int = 1) -> void:
	Einstellungen.debug = not Einstellungen.debug
	Einstellungen.speichern()
	_baue_menue()
	if Einstellungen.debug:
		_zeige_meldung("Debugmodus an – unendlich Leben, immer Schutz, alle Räume offen")
	else:
		_zeige_meldung("Debugmodus aus")


func _zurueck() -> void:
	_blockiert = true
	Spielfluss.zum_splash()


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
