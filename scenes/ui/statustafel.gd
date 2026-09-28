extends Control
class_name Statustafel
## Statustafel: Übersicht über Spielstand und Steuerung.
##
## Wird mit Dreieck △ am Controller, mit Tab auf der Tastatur oder mit der
## Statustaste der Touch-Steuerung auf- und zugeklappt und hält das Spiel
## dabei an. Der HUD erzeugt sie; wie überall im Projekt ist alles
## gezeichnet statt geladen (`UiStil`).
##
## Sie ist zugleich der einzige Weg AUS einem Level heraus. Ohne den Knopf
## "Level verlassen" saß man bis zum Zielportal fest – am Rechner konnte
## man wenigstens das Fenster schließen, im Browser gab es gar nichts.
##
## Die Knöpfe unten: Weiterspielen (vorgewählt), Neu starten (nur im
## Level) und Verlassen. Bestätigen löst den GEWÄHLTEN Knopf aus. Früher
## verließ Enter bzw. ✕ sofort das Level – wer nach dem Öffnen mit △ noch
## einmal auf ✕ tippte, flog aus dem Level.

## Die Tafel ist offen oder zu. Kommt sofort beim Umschalten, nicht erst
## nach der Ausblendung – der HUD sperrt damit die Touch-Steuerung.
signal umgeschaltet(offen: bool)

## Aufbau der Steuerungslegende: [Aktion, Name, Erklärung, Tastatur].
## Leere Aktion = keine Symboltaste.
const LEGENDE := [
	["", "Laufen", "vorwärts heißt immer: ins Bild hinein", "WASD / Pfeile"],
	["jump", "Springen", "zweimal = Doppelsprung · am Gitter mit Richtung abspringen",
			"Leertaste"],
	["spin", "Drehschlag", "zerbricht Kisten, besiegt Gegner · auch im Hängen",
			"J / Strg"],
	["slide", "Slide", "gehalten krabbeln · in der Luft Bauchplatscher · am Gitter Beine anziehen",
			"Umschalt"],
	["status", "Status", "diese Tafel · hält das Spiel an", "Tab oder Esc"],
]

## Kurz nach dem Öffnen schließt kein Tippen. Ein Fingerdruck erzeugt auch
## ein nachgeahmtes Mausereignis; ohne diese Frist klappte die Tafel im
## selben Moment wieder zu, in dem die Statustaste sie geöffnet hat.
const SCHONFRIST := 0.35

## Maße der Tafel.
const BREITE_MAX := 840.0
const RAND := 34.0
## Legendenzeile: Name und darunter die Erklärung, die umbrechen darf.
const LEGENDE_KOPF := 36.0
const ERKLAERUNG_GROESSE := 12
const STAND_ZEILE := 31.0
const KNOPF_HOEHE := 54.0

var offen := false

var _auf_seit := 0.0
## Die Tafel selbst (mit den Knöpfen darauf); bewegt sich beim Öffnen,
## während die Abdunkelung dahinter nur einblendet.
var _karte: Control
var _knoepfe: Array[MenueEintrag] = []
var _aktionen: Array[Callable] = []
var _wahl := 0
var _tween: Tween = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStil.thema()
	# Muss auch bei angehaltenem Baum auf Eingaben hören, sonst käme man
	# nicht wieder heraus. Die Tweens dieses Knotens laufen damit ebenfalls.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	draw.connect(_zeichne_grund)

	_karte = Control.new()
	_karte.name = "Karte"
	_karte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_karte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_karte.draw.connect(_zeichne_karte)
	add_child(_karte)

	resized.connect(func() -> void:
		queue_redraw()
		_karte.queue_redraw()
		_knoepfe_ausrichten())
	InputHub.status_gewuenscht.connect(umschalten)
	InputHub.eingabeart_geaendert.connect(func(_art: int) -> void:
		_karte.queue_redraw())


func _exit_tree() -> void:
	# Beim Szenenwechsel darf kein angehaltener Baum zurückbleiben – auch
	# nicht, wenn das aufgeschobene `_weiter` mit der Tafel verfällt. Nur
	# die Statustafel hält das Spiel an.
	if get_tree() != null:
		get_tree().paused = false


func _weiter() -> void:
	# Wer im selben Bild wieder aufgemacht hat, bleibt angehalten.
	if not offen:
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
	# Auswahl wandern lassen: Knöpfe stehen nebeneinander, aber auch
	# hoch/runter wählt – der Daumen liegt ohnehin auf dem Steuerkreuz.
	var schritt := 0
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right") \
			or event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		schritt = 1
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left") \
			or event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		schritt = -1
	if schritt != 0:
		_waehle(_wahl + schritt)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_ausloesen(_wahl)
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


## Öffnet oder schließt die Tafel. Öffnen hält das Spiel an; das Bild ist
## nach gut 0,2 s ruhig (foto.gd wartet 24 Bilder).
func setzen(an: bool) -> void:
	if offen == an:
		return
	offen = an
	_auf_seit = Time.get_ticks_msec() * 0.001
	if an:
		get_tree().paused = true
	else:
		# Erst am Ende des Bildes weiterlaufen lassen: Wer mit ✕ oder
		# Leertaste "Weiterspielen" wählt, dessen Druck gälte sonst im
		# selben Bild noch als Sprung.
		_weiter.call_deferred()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if an:
		_knoepfe_bauen()
		visible = true
		queue_redraw()
		_karte.queue_redraw()
		_karte.pivot_offset = _tafelfeld().get_center()
		modulate.a = 0.0
		_karte.position = Vector2(0.0, 18.0)
		_karte.scale = Vector2.ONE * 0.96
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.set_parallel(true)
		_tween.tween_property(self, ^"modulate:a", 1.0, 0.14)
		_tween.tween_property(_karte, ^"position", Vector2.ZERO, 0.24) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(_karte, ^"scale", Vector2.ONE, 0.24) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		# Das Spiel läuft sofort weiter; nur das Bild blendet kurz nach.
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.tween_property(self, ^"modulate:a", 0.0, 0.12)
		_tween.tween_callback(hide)
	umgeschaltet.emit(an)


func _im_level() -> bool:
	return Spielfluss.aktuelles_level > 0


# ------------------------------------------------------------- Knöpfe

func _knoepfe_bauen() -> void:
	for k in _knoepfe:
		k.queue_free()
	_knoepfe.clear()
	_aktionen.clear()
	_knopf("Weiterspielen", "", func() -> void: setzen(false))
	if _im_level():
		_knopf("Neu starten", "", _neu_starten)
		# Im Level führt der Knopf in den Portalraum, dort ins Hauptmenü.
		# Ohne die zweite Fassung kam man aus dem Portalraum nur über das
		# Schließen des Fensters heraus – im Browser also gar nicht.
		_knopf("Level verlassen", "", _zurueck)
	else:
		_knopf("Zum Hauptmenü", "", _zurueck)
	_wahl = 0
	_waehle(0)
	_knoepfe_ausrichten()


func _knopf(beschriftung: String, unterzeile: String, aktion: Callable) -> void:
	var k := MenueEintrag.new()
	k.name = "Knopf%d" % _knoepfe.size()
	k.beschriftung = beschriftung
	k.unterzeile = unterzeile
	k.schriftgroesse = 20
	k.process_mode = Node.PROCESS_MODE_ALWAYS
	var index := _knoepfe.size()
	k.angetippt.connect(func() -> void: _ausloesen(index))
	k.ueberfahren.connect(func() -> void: _waehle(index))
	_karte.add_child(k)
	_knoepfe.append(k)
	_aktionen.append(aktion)


func _waehle(index: int) -> void:
	if _knoepfe.is_empty():
		return
	_wahl = wrapi(index, 0, _knoepfe.size())
	for i in _knoepfe.size():
		_knoepfe[i].setze_auswahl(i == _wahl)


func _ausloesen(index: int) -> void:
	if index < 0 or index >= _aktionen.size() or not offen:
		return
	_waehle(index)
	_aktionen[index].call()


func _knoepfe_ausrichten() -> void:
	if _knoepfe.is_empty():
		return
	var feld := _tafelfeld()
	var anzahl := _knoepfe.size()
	var luecke := 14.0
	var breite := (feld.size.x - RAND * 2.0 - luecke * (anzahl - 1)) / anzahl
	var oben := feld.end.y - 44.0 - KNOPF_HOEHE
	for i in anzahl:
		_knoepfe[i].size = Vector2(breite, KNOPF_HOEHE)
		_knoepfe[i].position = Vector2(feld.position.x + RAND + i * (breite + luecke), oben)


func _neu_starten() -> void:
	var nummer := Spielfluss.aktuelles_level
	setzen(false)
	if not Spielfluss.zum_level(nummer):
		_zurueck()


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


## Fläche der Tafel. Wird von Zeichnung UND Knöpfen benutzt, damit beide
## nicht auseinanderlaufen.
func _tafelfeld() -> Rect2:
	var breite := minf(size.x * 0.92, BREITE_MAX)
	var legende := 0.0
	for h in _legendenhoehen(_spalte_rechts(breite)):
		legende += h
	var hoehe := 136.0 + legende + 12.0 + KNOPF_HOEHE + 44.0
	hoehe = minf(size.y * 0.94, hoehe)
	return Rect2((size - Vector2(breite, hoehe)) * 0.5, Vector2(breite, hoehe))


## Breite der linken Spalte (Spielstand) bei dieser Tafelbreite.
func _spalte_links(tafelbreite: float) -> float:
	return (tafelbreite - RAND * 2.0) * 0.40


## Breite der rechten Spalte (Steuerung).
func _spalte_rechts(tafelbreite: float) -> float:
	return tafelbreite - RAND * 2.0 - _spalte_links(tafelbreite) - 40.0


## Höhe jeder Legendenzeile: Kopfzeile plus so viele Zeilen, wie die
## Erklärung in der Spalte braucht (höchstens zwei). Gemessen statt fest,
## sonst läuft eine umbrochene Erklärung in die nächste Zeile.
func _legendenhoehen(spaltenbreite: float) -> Array[float]:
	var zs := UiStil.schrift(&"text")
	var textbreite := spaltenbreite - 40.0
	var hoehen: Array[float] = []
	for zeile: Array in LEGENDE:
		var h := zs.get_multiline_string_size(String(zeile[2]), HORIZONTAL_ALIGNMENT_LEFT,
				textbreite, ERKLAERUNG_GROESSE, 2).y
		hoehen.append(LEGENDE_KOPF + h)
	return hoehen


# ------------------------------------------------------------- Zeichnen

func _zeichne_grund() -> void:
	# Alles dahinter abdunkeln, zu den Rändern hin stärker
	draw_rect(Rect2(Vector2.ZERO, size), Farben.UI_ABDUNKELN)
	UiStil.vignette(self, Rect2(Vector2.ZERO, size), 0.5)


func _zeichne_karte() -> void:
	var feld := _tafelfeld()
	UiStil.zeichne(_karte, feld, &"tafel")

	var links := feld.position.x + RAND
	var rechts := feld.end.x - RAND
	var y := feld.position.y + 56.0

	UiStil.text(_karte, Vector2(links, y), "STATUS", 34, Farben.UI_GOLD, &"titel")
	var nummer := Spielfluss.aktuelles_level
	if nummer >= 1:
		UiStil.text(_karte, Vector2(rechts, y - 30.0), Spielfluss.level_kopfzeile(nummer),
				12, Farben.UI_GOLD, &"sperr", -1, HORIZONTAL_ALIGNMENT_RIGHT)
		UiStil.text(_karte, Vector2(rechts, y), Spielfluss.level_name(nummer), 24,
				Farben.UI_TITEL_FUELLUNG, &"titel", -1, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		UiStil.text(_karte, Vector2(rechts, y), "Portalraum", 24,
				Farben.UI_TITEL_FUELLUNG, &"titel", -1, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 20.0
	_karte.draw_line(Vector2(links, y), Vector2(rechts, y), Color(1, 1, 1, 0.14), 1.5)

	var spalte_links := _spalte_links(feld.size.x)
	var spalte_rechts_x := links + spalte_links + 40.0
	_zustand(Vector2(links, y + 40.0), spalte_links)
	_steuerung(Vector2(spalte_rechts_x, y + 40.0), _spalte_rechts(feld.size.x))

	# Trennlinie zwischen den Spalten
	var trenn_x := links + spalte_links + 20.0
	_karte.draw_line(Vector2(trenn_x, y + 26.0),
			Vector2(trenn_x, feld.end.y - 44.0 - KNOPF_HOEHE - 18.0),
			Color(1, 1, 1, 0.08), 1.0)

	UiStil.text(_karte, Vector2(feld.get_center().x, feld.end.y - 16.0), _fusszeile(),
			13, Farben.UI_MATT, &"text", 0, HORIZONTAL_ALIGNMENT_CENTER)


func _fusszeile() -> String:
	if InputHub.eingabeart == InputHub.Art.PAD:
		return "Kreuz wählt  ·  Dreieck schließt"
	if InputHub.eingabeart == InputHub.Art.TOUCH:
		return "Antippen wählt  ·  Tippen daneben schließt"
	return "Enter wählt  ·  Tab oder Esc schließt"


## Abschnittskopf: gesperrte Goldschrift mit feiner Linie bis zur
## Spaltenkante.
func _kopf(ort: Vector2, breite: float, inhalt: String) -> void:
	var tb := UiStil.text(_karte, ort, inhalt, 13, Farben.UI_GOLD, &"sperr", 3)
	_karte.draw_line(Vector2(ort.x + tb + 12.0, ort.y - 4.0),
			Vector2(ort.x + breite, ort.y - 4.0), Color(Farben.UI_GOLD, 0.25), 1.0)


func _zustand(oben: Vector2, breite: float) -> void:
	# [Symbol, Bezeichnung, Wert]
	var zeilen: Array = [
		[&"frucht", "Früchte", "%d / %d" % [GameState.fruechte,
				GameState.FRUECHTE_PRO_EXTRALEBEN]],
		[&"herz", "Leben", "%d" % GameState.leben],
	]
	if GameState.kisten_gesamt > 0:
		zeilen.append([&"kiste", "Kisten", "%d / %d"
				% [GameState.kisten_zerbrochen, GameState.kisten_gesamt]])
	# Im Zeitlauf ist die Richtzeit die Zahl, die man wissen will – die
	# Uhr im HUD sagt nur, wo man steht, nicht, wo man hin muss.
	if Zeitlauf.laeuft:
		zeilen.append([&"uhr", "Zeit", Zeitlauf.als_text(Zeitlauf.zeit)])
		zeilen.append([&"uhr", "Richtzeit", Zeitlauf.als_text(Zeitlauf.richtzeit)])
	zeilen.append([&"raute", "Freigeschaltet", "%d / %d Level"
			% [Spielfluss.freigeschaltet, Spielfluss.LEVEL_GESAMT]])
	if not _im_level():
		# Im Portalraum zählt der ganze Spielstand, nicht der Versuch.
		zeilen.append([&"raute", "Geschafft", "%d / %d Level"
				% [Spielfluss.geschafft.size(), Spielfluss.LEVEL_GESAMT]])
		zeilen.append([&"edelstein", "Edelsteine", "%d" % _edelsteine_gesamt()])
		zeilen.append([&"frucht", "Früchte gesamt", "%d" % Spielfluss.fruechte_gesamt])

	_kopf(oben, breite, "SPIELSTAND")
	var y := oben.y + 36.0
	for zeile: Array in zeilen:
		var symbol := StringName(zeile[0])
		var bezeichnung := String(zeile[1])
		var wert := String(zeile[2])
		_symbol(symbol, Vector2(oben.x + 10.0, y - 6.0))
		var lb := UiStil.text(_karte, Vector2(oben.x + 30.0, y), bezeichnung, 16,
				Farben.UI_TEXT_RUHE, &"text")
		var wb := UiStil.textbreite(wert, 19, &"zahl")
		UiStil.text(_karte, Vector2(oben.x + breite, y), wert, 19, Farben.UI_HELL,
				&"zahl", -1, HORIZONTAL_ALIGNMENT_RIGHT)
		# Punktierte Führungslinie zwischen Bezeichnung und Wert
		var von := oben.x + 30.0 + lb + 10.0
		var bis := oben.x + breite - wb - 10.0
		if bis > von:
			_karte.draw_dashed_line(Vector2(von, y - 4.0), Vector2(bis, y - 4.0),
					Color(1, 1, 1, 0.14), 1.5, 3.0)
		y += STAND_ZEILE

	if Spielfluss.aktuelles_level >= 1:
		_edelsteine(Vector2(oben.x, y + 18.0), breite)


## Alle Edelsteine des Spielstands: Kisten, ohne Tod und Zeitstufen.
func _edelsteine_gesamt() -> int:
	var anzahl := 0
	for nummer: Variant in Spielfluss.geschafft:
		var eintrag: Dictionary = Spielfluss.geschafft[nummer]
		if bool(eintrag.get("kisten", false)):
			anzahl += 1
		if bool(eintrag.get("ohne_tod", false)):
			anzahl += 1
	for nummer: Variant in Spielfluss.zeiten:
		if int((Spielfluss.zeiten[nummer] as Dictionary).get("stufe", 0)) > 0:
			anzahl += 1
	return anzahl


## Die Edelsteine dieses Levels im Spielstand: alle Kisten, ohne Tod und –
## wenn es eine gibt – die beste Zeitstufe.
func _edelsteine(oben: Vector2, breite: float) -> void:
	var nummer := Spielfluss.aktuelles_level
	var eintrag: Dictionary = Spielfluss.geschafft.get(nummer, {})
	var zeit: Dictionary = Spielfluss.zeit_von(nummer)
	var stufe := int(zeit.get("stufe", 0))
	var steine: Array = []
	# Ohne Kisten im Level gibt es auch keinen Kistenstein zu holen.
	if GameState.kisten_gesamt > 0:
		steine.append([Farben.EDELSTEIN_KISTEN, bool(eintrag.get("kisten", false)), "Kisten"])
	steine.append([Farben.EDELSTEIN_OHNE_TOD, bool(eintrag.get("ohne_tod", false)),
			"Ohne Tod"])
	if stufe > 0:
		steine.append([Zeitlauf.stufen_farbe(stufe), true, Zeitlauf.stufen_name(stufe)])
	_kopf(oben, breite, "EDELSTEINE")
	var abstand := minf(breite / 3.0, 96.0)
	var y := oben.y + 36.0
	for i in steine.size():
		var stein: Array = steine[i]
		var mitte := Vector2(oben.x + 22.0 + abstand * i, y)
		var farbe: Color = stein[0]
		var erhalten: bool = stein[1]
		UiStil.fassung(_karte, mitte, 17.0)
		UiStil.edelstein(_karte, mitte + Vector2(0.0, -1.0), 11.0, farbe, erhalten)
		UiStil.text(_karte, mitte + Vector2(24.0, 5.0), String(stein[2]), 13,
				Farben.UI_HELL if erhalten else Farben.UI_MATT, &"text")


func _symbol(art: StringName, mitte: Vector2) -> void:
	match art:
		&"frucht":
			UiStil.frucht(_karte, mitte + Vector2(0.0, 1.0), 7.5)
		&"herz":
			UiStil.herz(_karte, mitte, 8.0)
		&"kiste":
			UiStil.kiste(_karte, mitte, 6.5)
		&"edelstein":
			UiStil.edelstein(_karte, mitte + Vector2(0.0, -1.0), 8.0, Farben.EDELSTEIN_KISTEN)
		&"uhr":
			_karte.draw_circle(mitte, 8.0, Farben.UI_KONTUR, true, -1.0, true)
			_karte.draw_circle(mitte, 6.5, Farben.KISTE_ZEIT.lightened(0.25), true, -1.0, true)
			_karte.draw_line(mitte, mitte + Vector2(0, -4.5), Farben.UI_KONTUR, 1.5, true)
			_karte.draw_line(mitte, mitte + Vector2(3.5, 1.5), Farben.UI_KONTUR, 1.5, true)
		_:
			UiStil.raute(_karte, mitte, 6.5, Farben.UI_GOLD)


func _steuerung(oben: Vector2, breite: float) -> void:
	_kopf(oben, breite, "STEUERUNG")
	var y := oben.y + 38.0
	var r := 14.0
	var art := InputHub.eingabeart
	var hoehen := _legendenhoehen(breite)
	for i in LEGENDE.size():
		var zeile: Array = LEGENDE[i]
		var aktion := String(zeile[0])
		var mitte := Vector2(oben.x + r, y - 6.0)
		if aktion.is_empty():
			# Laufen: ein Steuerkreuz statt einer Symboltaste
			_karte.draw_circle(mitte, r, Color(0, 0, 0, 0.3), true, -1.0, true)
			for w in 4:
				var d := Vector2.from_angle(TAU * w / 4.0)
				UiStil.raute(_karte, mitte + d * 6.5, 3.0, Farben.UI_TEXT_RUHE)
		else:
			var farbe := PadSymbole.farbe(aktion)
			_karte.draw_circle(mitte, r, Color(0, 0, 0, 0.3), true, -1.0, true)
			_karte.draw_arc(mitte, r, 0.0, TAU, 32, Color(farbe, 0.6), 1.5, true)
			PadSymbole.zeichne(_karte, aktion, mitte, r * 0.6, farbe, 2.0)
		var textlinks := oben.x + r * 2.0 + 12.0
		UiStil.text(_karte, Vector2(textlinks, y), String(zeile[1]), 17, Farben.UI_HELL,
				&"fett")
		var taste := _tastenname(aktion, String(zeile[3]), art)
		var passend := UiStil.passend(UiStil.schrift(&"text"), taste, 13,
				breite * 0.45, 10)
		UiStil.text(_karte, Vector2(oben.x + breite, y), taste, passend, Farben.UI_MATT,
				&"text", 0, HORIZONTAL_ALIGNMENT_RIGHT)
		# Die Erklärung darf umbrechen – vorher lief die Slide-Zeile über
		# den Tastenhinweis hinweg bis aus der Tafel heraus.
		UiStil.absatz(_karte, Vector2(textlinks, y + 17.0), String(zeile[2]),
				ERKLAERUNG_GROESSE, Farben.UI_MATT, oben.x + breite - textlinks, &"text", 2, 0)
		y += hoehen[i]


## Was rechts neben einer Aktion steht – passend zu dem, was der Spieler
## gerade in der Hand hat.
func _tastenname(aktion: String, tastatur: String, art: int) -> String:
	if art == InputHub.Art.PAD:
		if aktion.is_empty():
			return "Stick / Steuerkreuz"
		return String(PadSymbole.TASTEN.get(aktion, tastatur))
	if art == InputHub.Art.TOUCH:
		if aktion.is_empty():
			return "Joystick links"
		return "Taste " + String(PadSymbole.TASTEN.get(aktion, tastatur))
	return tastatur
