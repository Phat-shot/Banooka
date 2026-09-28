extends CanvasLayer
## HUD: Früchte, Leben, Kisten und die Uhr des Zeitmodus – dazu alles, was
## ein Level erzählt: Titelkarte beim Start, Meldungen, Bänder für die
## großen Momente, Blitz beim Tod und die Auswertung am Ziel.
##
## Alles wird gezeichnet (`UiStil`), nichts geladen – das Projekt kommt
## ohne fremde Assets aus (siehe assets/CREDITS.md).
##
## EBENE 10 (HUD.tscn): über der Rennanzeige und der Flugtafel (Ebene 2),
## damit die Statustafel sie beim Anhalten verdeckt – vorher lagen beide
## über der Pause. Unter dem Ladeschirm (128); der Bildblitz der Effekte
## (Ebene 0) liegt darunter.
##
## Aufbau unter `Anzeige`, von hinten nach vorn:
##   Blende       roter Blitz beim Tod (UiStil.Blende), UNTER den Zählern,
##                damit man im Blitz sieht, was ihn gekostet hat
##   Treffer      roter Rand, wenn ein Schutz einen Treffer abfängt
##   Tafel        die Chips: Früchte, Leben, Kisten
##   Zeittafel    Uhr des Zeitmodus, oben in der Mitte
##   Flugbahn     eingesammelte Früchte fliegen in den Zähler
##   Meldung      kleine Kapsel ("Checkpoint")
##   Band         großes schräges Band ("GAME OVER")
##   Titelkarte, Auswertung – nur solange sie gebraucht werden
##
## Der HUD zeichnet nur neu, wenn sich etwas bewegt; in Ruhe kostet er
## nichts. Die Titelkarte erscheint nur nach `Spielfluss.zum_level()`
## (Marke `titelkarte_faellig`), Werkzeugfotos bleiben also sauber.

## Höhe eines Chips; bei 46 px ist die Kapsel aus `UiStil` genau rund.
const CHIP_HOEHE := 46.0
const CHIP_ABSTAND := 10.0
## Schriftgröße der Zähler (&"zahl", Ziffern gleich breit).
const ZAHL_GROSS := 30
const ZAHL_MITTEL := 27
## So lange ohne Änderung, dann treten die Chips etwas zurück – die Welt
## soll im Vordergrund stehen, nicht die Buchhaltung.
const RUHE_NACH := 6.0
const RUHE_DECKUNG := 0.74
## Flug einer eingesammelten Frucht in den Zähler.
const FLUG_DAUER := 0.5
const FLUG_HOECHSTENS := 10

@onready var _anzeige: Control = $Anzeige
@onready var _tafel: Control = $Anzeige/Tafel
@onready var _zeittafel: Control = $Anzeige/Zeittafel
@onready var _touch: Control = $TouchControls

## Übersicht über Spielstand und Steuerung, Dreieck △ bzw. Tab.
var _status: Statustafel

var _blende: UiStil.Blende
var _treffer: Control
var _flugbahn: Control
var _meldung: Meldung
var _band: Band
var _auswertung: Auswertung = null

var _fruechte := 0
var _leben := GameState.START_LEBEN
var _kisten := 0
var _kisten_gesamt := 0
var _schutz := 0
## Angezeigte Früchte: läuft der echten Zahl nach, Frucht für Frucht, so
## wie die Flieger im Zähler landen.
var _fruechte_anzeige := 0.0

## Uhr des Zeitmodus. `_zeit_frost` > 0 heißt: Die Uhr steht gerade.
var _zeit := 0.0
var _zeit_frost := 0.0
var _frost_max := 0.0
var _zeit_rahmen: StyleBoxFlat
## Beste noch erreichbare Stufe; wechselt sie, ploppt die verlorene Raute.
var _stufe_vorher := -1
var _raute_pop := 0.0
var _raute_pop_stufe := 0

## Federnde Pops der Chips, 1 = gerade ausgelöst, 0 = ruhig.
var _pop_frucht := 0.0
var _pop_leben := 0.0
var _pop_verlust := 0.0
var _pop_kiste := 0.0
var _pop_edelstein := 0.0
var _uhr := 0.0
var _ruhe := 0.0
var _gedimmt := false
var _ruhe_tween: Tween = null
var _treffer_tween: Tween = null

## Mittelpunkte der Symbole in Tafel-Koordinaten (beim Zeichnen gemerkt):
## Ziel der Flieger und Startpunkt der Schwebetexte.
var _frucht_mitte := Vector2(23.0, 23.0)
var _herz_mitte := Vector2(120.0, 23.0)

## Früchte im Flug: {"t": float, "a": Vector2, "b": Vector2, "c": Vector2}
var _flieger: Array[Dictionary] = []
## Schwebende "+1"/"-1" und das fallende Herz:
## {"art": StringName, "text": String, "farbe": Color, "ort": Vector2,
##  "t": float, "dauer": float, "hub": float}
var _schweber: Array[Dictionary] = []
## Die ersten Signale nach dem Laden gleichen nur den Stand ab – dabei
## soll nichts aufploppen oder fliegen.
var _bereit := false

static var _rand_textur: GradientTexture2D = null


func _ready() -> void:
	# Ein CanvasLayer unterbricht die Theme-Vererbung: jede UI-Wurzel
	# bekommt das Theme selbst.
	_anzeige.theme = UiStil.thema()
	_touch.theme = UiStil.thema()

	GameState.fruechte_geaendert.connect(_auf_fruechte)
	GameState.leben_geaendert.connect(_auf_leben)
	GameState.kisten_geaendert.connect(_auf_kisten)
	GameState.nachricht.connect(_auf_nachricht)
	GameState.banner.connect(_auf_banner)
	GameState.schutz_geaendert.connect(_auf_schutz)
	GameState.level_zuruecksetzen.connect(_auf_tod)
	Zeitlauf.zeit_geaendert.connect(_auf_zeit)
	Zeitlauf.lauf_geaendert.connect(_auf_lauf)
	Spielfluss.level_abgeschlossen.connect(_auf_abschluss)
	Spielfluss.zeit_gewertet.connect(_auf_zeitwertung)

	_fruechte = GameState.fruechte
	_fruechte_anzeige = float(_fruechte)
	_leben = GameState.leben
	_kisten = GameState.kisten_zerbrochen
	_kisten_gesamt = GameState.kisten_gesamt
	_schutz = GameState.schutz

	_blende = UiStil.Blende.new(Farben.UI_TREFFER)
	_anzeige.add_child(_blende)
	_anzeige.move_child(_blende, 0)

	_treffer = _vollflaeche("Treffer")
	_treffer.visible = false
	_treffer.draw.connect(_zeichne_treffer)
	_anzeige.add_child(_treffer)
	_anzeige.move_child(_treffer, 1)

	_flugbahn = _vollflaeche("Flugbahn")
	_flugbahn.draw.connect(_zeichne_flieger)
	_anzeige.add_child(_flugbahn)

	_meldung = Meldung.new()
	_anzeige.add_child(_meldung)
	_band = Band.new()
	_anzeige.add_child(_band)

	_tafel.draw.connect(_zeichne_tafel)
	_zeittafel.draw.connect(_zeichne_zeit)
	_zeittafel.visible = Zeitlauf.laeuft
	_zeit = Zeitlauf.zeit
	_zeit_frost = Zeitlauf.frost
	_zeit_rahmen = UiStil.eigene(&"kachel")

	_status = Statustafel.new()
	_status.name = "Statustafel"
	add_child(_status)
	_status.umgeschaltet.connect(_auf_status)
	# Die Touch-Steuerung bleibt ganz oben: bei offener Statustafel steht
	# dort nur noch das Dreieck, mit dem man sie wieder zumacht.
	move_child(_touch, get_child_count() - 1)

	# Titelkarte: Der HUD ist ein Kind des Levels und läuft deshalb vor
	# dessen `_ready` – die Verbindung steht, bevor der Aufbau fertig ist.
	var level := _level()
	if level != null:
		level.connect("aufbau_fertig", _auf_aufbau_fertig)
	# Nach dem Abgleich der ersten Bilder (level_starten, Kistenzählung)
	# gilt jede Änderung als echtes Ereignis.
	get_tree().create_timer(0.6).timeout.connect(func() -> void: _bereit = true)


func _level() -> Node:
	var knoten := get_parent()
	while knoten != null:
		if knoten.has_signal("aufbau_fertig"):
			return knoten
		knoten = knoten.get_parent()
	return null


func _vollflaeche(bezeichnung: String) -> Control:
	var c := Control.new()
	c.name = bezeichnung
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _process(delta: float) -> void:
	_uhr += delta
	var tafel_neu := false

	if _pop_frucht > 0.0 or _pop_leben > 0.0 or _pop_verlust > 0.0 \
			or _pop_kiste > 0.0 or _pop_edelstein > 0.0:
		_pop_frucht = maxf(_pop_frucht - delta * 2.6, 0.0)
		_pop_leben = maxf(_pop_leben - delta * 2.2, 0.0)
		_pop_verlust = maxf(_pop_verlust - delta * 2.0, 0.0)
		_pop_kiste = maxf(_pop_kiste - delta * 2.6, 0.0)
		_pop_edelstein = maxf(_pop_edelstein - delta * 1.6, 0.0)
		tafel_neu = true

	# Zähler läuft nach: Früchte im Flug zählen erst, wenn sie ankommen.
	var ziel := float(_fruechte - _flieger.size())
	if _fruechte_anzeige != ziel:
		var vorher := roundi(_fruechte_anzeige)
		_fruechte_anzeige = UiStil.annaehern(_fruechte_anzeige, ziel, delta, 8.0, 16.0)
		if roundi(_fruechte_anzeige) != vorher:
			_pop_frucht = maxf(_pop_frucht, 0.7)
		tafel_neu = true

	if not _flieger.is_empty():
		_flieger_bewegen(delta)
	if not _schweber.is_empty():
		for eintrag in _schweber:
			eintrag["t"] = float(eintrag["t"]) + delta
		_schweber = _schweber.filter(func(e: Dictionary) -> bool:
				return float(e["t"]) < float(e["dauer"]))
		tafel_neu = true

	if _raute_pop > 0.0:
		_raute_pop = maxf(_raute_pop - delta * 2.5, 0.0)
		_zeittafel.queue_redraw()

	_ruhe += delta
	if not _gedimmt and _ruhe > RUHE_NACH:
		_gedimmt = true
		_tafel_deckung(RUHE_DECKUNG, 0.8)

	if tafel_neu:
		_tafel.queue_redraw()


## Etwas hat sich geändert: Chips wieder voll zeigen.
func _wecken() -> void:
	_ruhe = 0.0
	if _gedimmt:
		_gedimmt = false
		_tafel_deckung(1.0, 0.15)


## Ein Tween für beides, Zurücktreten und Wecken – sonst liefe ein
## halbes Abdunkeln nach dem Wecken weiter und die Chips blieben blass.
func _tafel_deckung(ziel: float, dauer: float) -> void:
	if _ruhe_tween != null and _ruhe_tween.is_valid():
		_ruhe_tween.kill()
	_ruhe_tween = _tafel.create_tween()
	_ruhe_tween.tween_property(_tafel, "modulate:a", ziel, dauer)


# ------------------------------------------------------------- Chips

func _zeichne_tafel() -> void:
	var x := _chip_frucht(0.0)
	x = _chip_leben(x + CHIP_ABSTAND)
	# Im Portalraum gibt es keine Kisten – dann entfällt der Chip, statt
	# "0/0" anzuzeigen.
	if _kisten_gesamt > 0:
		_chip_kisten(x + CHIP_ABSTAND)
	_zeichne_schweber()


## Früchte: Beere im Fortschrittsring (bis zum Extraleben), daneben die
## Zahl. "/ 100" steht nicht mehr da – der Ring sagt es, ohne Text.
func _chip_frucht(x: float) -> float:
	var fach := UiStil.textbreite("00", ZAHL_GROSS, &"zahl")
	var feld := Rect2(x, 0.0, 50.0 + fach + 18.0, CHIP_HOEHE)
	_chip(feld)

	var mitte := Vector2(x + 23.0, CHIP_HOEHE * 0.5)
	_frucht_mitte = mitte
	var anteil := clampf(_fruechte_anzeige / float(GameState.FRUECHTE_PRO_EXTRALEBEN),
			0.0, 1.0)
	_tafel.draw_arc(mitte, 19.0, 0.0, TAU, 48, Color(0, 0, 0, 0.35), 3.5, true)
	if anteil > 0.0:
		_tafel.draw_arc(mitte, 19.0, -PI * 0.5, -PI * 0.5 + TAU * anteil, 48,
				Farben.FRUCHT.lightened(0.15), 3.5, true)

	var s := UiStil.federkurve(_pop_frucht, 0.3)
	_tafel.draw_set_transform(mitte + Vector2(0.0, 1.5), 0.0, Vector2.ONE * s)
	UiStil.frucht(_tafel, Vector2.ZERO, 12.5)
	_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)

	var farbe := Farben.FRUCHT.lightened(0.55).lerp(Color.WHITE, 0.55 * _pop_frucht)
	_zahl(Vector2(x + 50.0 + fach * 0.5, CHIP_HOEHE * 0.5), "%d" % roundi(_fruechte_anzeige),
			ZAHL_GROSS, farbe, s, HORIZONTAL_ALIGNMENT_CENTER)
	return feld.end.x


## Leben: EIN großes Herz und "×5" statt fünf winziger Herzen – bleibt auf
## dem Handy lesbar und reicht über fünf hinaus.
func _chip_leben(x: float) -> float:
	var zahl := "%d" % _leben
	var fach := maxf(UiStil.textbreite("0", ZAHL_MITTEL, &"zahl"),
			UiStil.textbreite(zahl, ZAHL_MITTEL, &"zahl"))
	var kreuz := UiStil.textbreite("×", 18, &"fett")
	var feld := Rect2(x, 0.0, 46.0 + kreuz + 3.0 + fach + 18.0, CHIP_HOEHE)
	_chip(feld)

	var mitte := Vector2(x + 23.0, CHIP_HOEHE * 0.5 + 1.0)
	_herz_mitte = mitte
	# Verlust: das Herz zittert; Gewinn: es federt.
	var wackeln := sin(_uhr * 46.0) * 4.0 * _pop_verlust
	var s := UiStil.federkurve(_pop_leben, 0.32)
	_tafel.draw_set_transform(mitte + Vector2(wackeln, 0.0), 0.0, Vector2.ONE * s)
	UiStil.herz(_tafel, Vector2.ZERO, 12.5, _leben > 0)
	_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)

	var links := x + 44.0
	UiStil.text(_tafel, Vector2(links, CHIP_HOEHE * 0.5 + 6.0), "×", 18,
			Color(1, 1, 1, 0.62), &"fett")
	var farbe := Farben.UI_HELL.lerp(Farben.WARNUNG.lightened(0.3), _pop_verlust)
	_zahl(Vector2(links + kreuz + 3.0 + fach * 0.5, CHIP_HOEHE * 0.5), zahl, ZAHL_MITTEL,
			farbe, s, HORIZONTAL_ALIGNMENT_CENTER)
	return feld.end.x


## Kisten: "12/39". Sind alle zerbrochen, wird der Chip grün und der
## Edelstein ploppt dazu – dieselbe Farbe wie im Portalraum.
func _chip_kisten(x: float) -> float:
	# Der letzte Chip der Reihe darf mitwachsen – rechts von ihm steht
	# nichts, das dabei verrutschen könnte.
	var zahl := "%d" % _kisten
	var fach := UiStil.textbreite(zahl, ZAHL_MITTEL, &"zahl")
	var rest := "/%d" % _kisten_gesamt
	var rest_breite := UiStil.textbreite(rest, 18, &"zahl")
	var voll := _kisten >= _kisten_gesamt
	var breite := 46.0 + fach + 2.0 + rest_breite + 18.0
	if voll:
		breite += 26.0
	var feld := Rect2(x, 0.0, breite, CHIP_HOEHE)
	_chip(feld, voll)

	var mitte := Vector2(x + 23.0, CHIP_HOEHE * 0.5)
	var s := UiStil.federkurve(_pop_kiste, 0.3)
	_tafel.draw_set_transform(mitte, 0.0, Vector2.ONE * s)
	UiStil.kiste(_tafel, Vector2.ZERO, 10.0)
	_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)

	var links := x + 44.0
	var farbe := Farben.KISTE_LEBEN.lightened(0.45) if voll else Color(0.97, 0.88, 0.70)
	farbe = farbe.lerp(Color.WHITE, 0.5 * _pop_kiste)
	_zahl(Vector2(links + fach * 0.5, CHIP_HOEHE * 0.5), zahl, ZAHL_MITTEL, farbe, s,
			HORIZONTAL_ALIGNMENT_CENTER)
	UiStil.text(_tafel, Vector2(links + fach + 2.0, CHIP_HOEHE * 0.5 + 7.0), rest, 18,
			Color(1, 1, 1, 0.6), &"zahl")
	if voll:
		var stein := Vector2(feld.end.x - 24.0, CHIP_HOEHE * 0.5 + 1.0)
		var e := 1.0 - _pop_edelstein
		var groesse := clampf(e * 3.0, 0.0, 1.0) * UiStil.federkurve(_pop_edelstein, 0.4)
		if groesse > 0.01:
			_tafel.draw_set_transform(stein, 0.0, Vector2.ONE * groesse)
			UiStil.edelstein(_tafel, Vector2.ZERO, 9.0, Farben.EDELSTEIN_KISTEN)
			_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)
	return feld.end.x


## Kapsel mit feinem Glanz an der Oberkante – wie Glas über der Welt,
## nicht wie ein Loch in ihr.
func _chip(feld: Rect2, gruen: bool = false) -> void:
	if gruen:
		UiStil.variante(&"chip", &"kisten_voll", _chip_gruen).draw(
				_tafel.get_canvas_item(), feld)
	else:
		UiStil.zeichne(_tafel, feld, &"chip")
	_tafel.draw_line(feld.position + Vector2(20.0, 3.5),
			Vector2(feld.end.x - 20.0, feld.position.y + 3.5), Color(1, 1, 1, 0.08), 2.0, true)


func _chip_gruen(s: StyleBoxFlat) -> void:
	s.border_color = Color(Farben.KISTE_LEBEN, 0.85)
	s.bg_color = Color(0.03, 0.12, 0.06, 0.66)
	s.shadow_color = Color(Farben.KISTE_LEBEN, 0.22)


## Zahl, senkrecht mittig auf `mitte.y`, mit Pop um ihre eigene Mitte.
func _zahl(anker: Vector2, inhalt: String, groesse: int, farbe: Color, skala: float,
		ausrichtung: HorizontalAlignment) -> void:
	_tafel.draw_set_transform(anker, 0.0, Vector2.ONE * skala)
	UiStil.text(_tafel, Vector2(0.0, groesse * 0.36), inhalt, groesse, farbe, &"zahl",
			-1, ausrichtung)
	_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)


func _zeichne_schweber() -> void:
	for eintrag in _schweber:
		var t: float = eintrag["t"]
		var dauer: float = eintrag["dauer"]
		var k := clampf(t / dauer, 0.0, 1.0)
		var ort: Vector2 = eintrag["ort"]
		var hub: float = eintrag["hub"]
		var deckung := 1.0 - k * k
		var pos := ort + Vector2(0.0, hub * (1.0 - (1.0 - k) * (1.0 - k)))
		if StringName(eintrag["art"]) == &"herz":
			# Das verlorene Herz fällt grau aus dem Chip und kippt dabei.
			_tafel.draw_set_transform(pos, 0.5 * k, Vector2.ONE)
			UiStil.herz(_tafel, Vector2.ZERO, 12.5, false, deckung)
			_tafel.draw_set_transform_matrix(Transform2D.IDENTITY)
		else:
			var farbe: Color = eintrag["farbe"]
			UiStil.text(_tafel, pos, String(eintrag["text"]), 22,
					Color(farbe, deckung), &"fett", -1, HORIZONTAL_ALIGNMENT_CENTER)


func _schweben(art: StringName, text: String, farbe: Color, ort: Vector2, hub: float,
		dauer: float) -> void:
	_schweber.append({"art": art, "text": text, "farbe": farbe, "ort": ort,
			"t": 0.0, "dauer": dauer, "hub": hub})


# ------------------------------------------------------------- Flieger

## Schickt `anzahl` Früchte von der Figur in den Zähler. Ohne Kamera oder
## hinter ihr zählen sie sofort.
func _flieger_starten(anzahl: int) -> void:
	var kamera := get_viewport().get_camera_3d()
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if kamera == null or spieler == null:
		return
	var punkt := spieler.global_position + Vector3.UP * 0.9
	if kamera.is_position_behind(punkt):
		return
	var start := kamera.unproject_position(punkt)
	var ziel := _tafel.position + _frucht_mitte
	for i in anzahl:
		var a := start + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 10.0))
		_flieger.append({
			"t": -0.05 * i,
			"a": a,
			"b": ziel,
			"c": (a + ziel) * 0.5 + Vector2(randf_range(-90.0, 90.0), -150.0),
		})


func _flieger_bewegen(delta: float) -> void:
	var gelandet := 0
	for f in _flieger:
		f["t"] = float(f["t"]) + delta
		if float(f["t"]) >= FLUG_DAUER:
			gelandet += 1
	if gelandet > 0:
		_flieger = _flieger.filter(func(f: Dictionary) -> bool:
				return float(f["t"]) < FLUG_DAUER)
		_pop_frucht = 1.0
		_wecken()
	_flugbahn.queue_redraw()


func _zeichne_flieger() -> void:
	for f in _flieger:
		var t: float = f["t"]
		if t < 0.0:
			continue
		var k := clampf(t / FLUG_DAUER, 0.0, 1.0)
		var e := k * k
		var a: Vector2 = f["a"]
		var b: Vector2 = f["b"]
		var c: Vector2 = f["c"]
		var u := 1.0 - e
		var pos := a * u * u + c * 2.0 * u * e + b * e * e
		# Ein blasser Schweif hinter der Frucht
		var e2 := maxf(k - 0.12, 0.0) * maxf(k - 0.12, 0.0)
		var u2 := 1.0 - e2
		var hinten := a * u2 * u2 + c * 2.0 * u2 * e2 + b * e2 * e2
		_flugbahn.draw_line(hinten, pos, Color(1.0, 0.78, 0.4, 0.35), 5.0, true)
		UiStil.frucht(_flugbahn, pos, lerpf(12.0, 9.0, e))


# ------------------------------------------------------------- Zeittafel

## Die Uhr des Zeitmodus: oben in der Mitte, groß genug, um sie im
## Vorbeilaufen zu lesen.
##
## Sie steht bewusst NICHT bei Früchten und Leben in der Ecke. Im Zeitlauf
## ist sie die einzige Zahl, auf die es ankommt, und der Blick liegt beim
## Laufen in der Bildmitte. Darunter drei Rauten – Platin, Gold, Saphir –:
## leuchtend, solange die Stufe noch zu schaffen ist, und daneben, bis
## wann die beste noch offene reicht.
func _zeichne_zeit() -> void:
	var breite := _zeittafel.size.x
	var feld := Rect2(0.0, 0.0, breite, 70.0)
	var steht := _zeit_frost > 0.0
	if steht:
		# Pulsierender Rahmen in der Farbe der Zeitkiste
		_zeit_rahmen.border_color = Color(Farben.KISTE_ZEIT.lightened(0.2),
				0.6 + 0.4 * sin(_uhr * 8.0))
		_zeit_rahmen.draw(_zeittafel.get_canvas_item(), feld)
	else:
		UiStil.zeichne(_zeittafel, feld, &"kachel")

	var stufe := _offene_stufe()
	var farbe := Farben.UI_HELL
	if steht:
		farbe = Farben.KISTE_ZEIT.lightened(0.5)
	elif stufe != Zeitlauf.Stufe.KEINE:
		farbe = Farben.UI_HELL.lerp(Zeitlauf.stufen_farbe(stufe), 0.35)
	else:
		farbe = Color(1.0, 0.80, 0.74)
	UiStil.text(_zeittafel, Vector2(breite * 0.5, 38.0), Zeitlauf.als_text(_zeit), 34,
			farbe, &"zahl", -1, HORIZONTAL_ALIGNMENT_CENTER)

	if steht:
		# Ring, der die Standzeit herunterzählt
		var ring := Vector2(breite - 26.0, 26.0)
		var anteil := clampf(_zeit_frost / maxf(_frost_max, 0.01), 0.0, 1.0)
		_zeittafel.draw_arc(ring, 10.0, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 3.0, true)
		_zeittafel.draw_arc(ring, 10.0, -PI * 0.5, -PI * 0.5 + TAU * anteil, 32,
				Farben.KISTE_ZEIT.lightened(0.3), 3.0, true)
		UiStil.text(_zeittafel, Vector2(breite * 0.5, 60.0),
				("Uhr steht  %.1f s" % _zeit_frost).replace(".", ","), 13,
				Farben.KISTE_ZEIT.lightened(0.55), &"fett", -1, HORIZONTAL_ALIGNMENT_CENTER)
		return

	# Rauten und die Schwelle der besten noch offenen Stufe
	var zeile := "Richtzeit vorbei"
	var zeilen_farbe := Farben.UI_MATT
	if stufe != Zeitlauf.Stufe.KEINE:
		zeile = "%s bis %s" % [Zeitlauf.stufen_name(stufe),
				Zeitlauf.als_text(_schwelle(stufe))]
		zeilen_farbe = Zeitlauf.stufen_farbe(stufe).lightened(0.25)
	var text_breite := UiStil.textbreite(zeile, 14, &"fett")
	var rauten_breite := 3.0 * 14.0 + 2.0 * 4.0
	var links := (breite - rauten_breite - 10.0 - text_breite) * 0.5
	var y := 55.0
	var reihe := [Zeitlauf.Stufe.PLATIN, Zeitlauf.Stufe.GOLD, Zeitlauf.Stufe.SAPHIR]
	for i in reihe.size():
		var st: int = reihe[i]
		var mitte := Vector2(links + 7.0 + i * 18.0, y)
		var offen := _zeit <= _schwelle(st)
		var r := 6.5
		if st == _raute_pop_stufe and _raute_pop > 0.0:
			r *= 1.0 + 0.8 * _raute_pop
		if offen:
			UiStil.raute(_zeittafel, mitte, r + 1.5, Farben.UI_KONTUR)
			UiStil.raute(_zeittafel, mitte, r, Zeitlauf.stufen_farbe(st))
		else:
			UiStil.raute(_zeittafel, mitte, r, Color(1, 1, 1, 0.28 + 0.5 * _raute_pop), false,
					1.4)
	UiStil.text(_zeittafel, Vector2(links + rauten_breite + 10.0, y + 5.0), zeile, 14,
			zeilen_farbe, &"fett")


func _schwelle(stufe: int) -> float:
	if stufe == Zeitlauf.Stufe.PLATIN:
		return Zeitlauf.richtzeit * Zeitlauf.PLATIN_ANTEIL
	if stufe == Zeitlauf.Stufe.GOLD:
		return Zeitlauf.richtzeit * Zeitlauf.GOLD_ANTEIL
	if stufe == Zeitlauf.Stufe.SAPHIR:
		return Zeitlauf.richtzeit
	return 0.0


## Beste Stufe, die mit der jetzigen Zeit noch zu schaffen ist – dieselbe
## Rechnung wie die Wertung am Ziel (`Zeitlauf.stufe_fuer`).
func _offene_stufe() -> int:
	return Zeitlauf.stufe_fuer(maxf(_zeit, 0.001), Zeitlauf.richtzeit)


# ------------------------------------------------------------- Treffer

func _zeichne_treffer() -> void:
	_treffer.draw_texture_rect(_randtextur(), Rect2(Vector2.ZERO, _treffer.size), false)


## Roter Rand, innen klar – einmal gebaut, von allen HUDs geteilt.
static func _randtextur() -> GradientTexture2D:
	if _rand_textur != null:
		return _rand_textur
	var g := Gradient.new()
	g.set_color(0, Color(Farben.WARNUNG, 0.0))
	g.set_color(1, Color(Farben.WARNUNG, 0.5))
	g.add_point(0.55, Color(Farben.WARNUNG, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.95, 0.95)
	_rand_textur = t
	return t


# ------------------------------------------------------------- Signale

## Solange die Statustafel offen ist, nimmt die Touch-Steuerung nur noch
## die Statustaste an – sonst spränge die Figur durch die Tafel hindurch.
func _auf_status(offen: bool) -> void:
	_touch.set("gesperrt", offen)
	_anzeige.visible = not offen
	if not offen:
		_wecken()


func _auf_fruechte(anzahl: int) -> void:
	var alt := _fruechte
	_fruechte = anzahl
	_wecken()
	if anzahl < alt or not _bereit:
		# Zurückgesetzt (Game Over) oder übergelaufen (Extraleben): sofort
		# stimmen, nichts fliegt rückwärts.
		_flieger.clear()
		_fruechte_anzeige = float(anzahl)
		_flugbahn.queue_redraw()
		_tafel.queue_redraw()
		return
	_flieger_starten(mini(anzahl - alt, FLUG_HOECHSTENS))
	_tafel.queue_redraw()


func _auf_leben(anzahl: int) -> void:
	var alt := _leben
	_leben = anzahl
	if _bereit and anzahl != alt:
		_wecken()
		if anzahl == alt + 1:
			_pop_leben = 1.0
			_schweben(&"text", "+1", Farben.KISTE_LEBEN.lightened(0.3),
					_herz_mitte + Vector2(0.0, -14.0), -30.0, 0.9)
		elif anzahl > alt:
			# Sprung um mehrere: Game Over füllt die Leben wieder auf – das
			# ist kein Geschenk, also kein "+5".
			_pop_leben = 0.6
		else:
			_pop_verlust = 1.0
			_schweben(&"herz", "", Color.WHITE, _herz_mitte, 26.0, 0.7)
	_tafel.queue_redraw()


func _auf_kisten(zerbrochen: int, gesamt: int) -> void:
	var war_voll := _kisten_gesamt > 0 and _kisten >= _kisten_gesamt
	var mehr := zerbrochen > _kisten and gesamt == _kisten_gesamt
	_kisten = zerbrochen
	_kisten_gesamt = gesamt
	if _bereit and mehr:
		_wecken()
		_pop_kiste = 1.0
		if not war_voll and gesamt > 0 and zerbrochen >= gesamt:
			_pop_edelstein = 1.0
	_tafel.queue_redraw()


func _auf_schutz(anzahl: int) -> void:
	# Eine Ladung weniger heißt: Ein Treffer wurde abgefangen. Rot am Rand
	# statt Blitz über alles – man lebt ja noch.
	if _bereit and anzahl == _schutz - 1 and _auswertung == null:
		if _treffer_tween != null and _treffer_tween.is_valid():
			_treffer_tween.kill()
		_treffer.modulate.a = 1.0
		_treffer.visible = true
		_treffer_tween = _treffer.create_tween()
		_treffer_tween.set_ignore_time_scale(true)
		_treffer_tween.tween_property(_treffer, "modulate:a", 0.0, 0.45) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_treffer_tween.tween_callback(_treffer.hide)
	_schutz = anzahl


## Tod: Die Figur steht in diesem Moment schon am Checkpoint (player.gd
## setzt sie zurück, bevor das Signal kommt). Der Blitz deckt den Sprung
## der Kamera und macht aus dem Versetzen einen gewollten Schnitt. Kurz,
## weil das Spiel darunter weiterläuft; bei Game Over hält er einen Moment.
func _auf_tod(von_vorn: bool) -> void:
	if von_vorn:
		_blende.blitz(Color(Farben.UI_TREFFER, 0.94), 0.6, 0.55)
	else:
		_blende.blitz(Color(Farben.UI_TREFFER, 0.9), 0.4, 0.08)


func _auf_zeit(sekunden: float, frost: float) -> void:
	if frost > _zeit_frost + 0.001:
		_frost_max = frost
	_zeit = sekunden
	_zeit_frost = frost
	var stufe := _offene_stufe()
	if _stufe_vorher >= 0 and stufe < _stufe_vorher:
		# Eine Stufe ist eben verloren gegangen: ihre Raute ploppt und
		# erlischt – man soll merken, WANN es passiert ist.
		_raute_pop = 1.0
		_raute_pop_stufe = _stufe_vorher
	_stufe_vorher = stufe
	_zeittafel.queue_redraw()


func _auf_lauf(laeuft: bool) -> void:
	_zeittafel.visible = laeuft
	if laeuft:
		_stufe_vorher = -1
		UiStil.einschweben(_zeittafel, Vector2(0.0, -16.0), 0.35)
	_zeittafel.queue_redraw()


func _auf_nachricht(text: String, dauer: float) -> void:
	# Während der Auswertung spricht nur sie: "Level geschafft!", "Alle
	# Kisten! Edelstein erhalten" und die Zeit stehen alle auf der Karte.
	if _auswertung != null:
		return
	_meldung.zeigen(text, dauer)


func _auf_banner(text: String, farbe: Color, dauer: float) -> void:
	if _auswertung != null:
		return
	_meldung.verbergen()
	_band.zeigen(text, farbe, dauer)


func _auf_aufbau_fertig() -> void:
	if not Spielfluss.titelkarte_faellig:
		return
	Spielfluss.titelkarte_faellig = false
	var nummer := Spielfluss.aktuelles_level
	var karte := Titelkarte.new(Spielfluss.level_kopfzeile(nummer),
			Spielfluss.level_name(nummer))
	_anzeige.add_child(karte)
	# Unter Meldung und Band, damit "Zeitlauf!" nicht verdeckt wird
	_anzeige.move_child(karte, _meldung.get_index())


func _auf_abschluss(daten: Dictionary) -> void:
	if _auswertung != null:
		return
	_meldung.verbergen()
	_band.verbergen()
	_auswertung = Auswertung.new(daten)
	# Im Rennen steht die Platzierung mit auf der Karte.
	var renn := get_tree().get_first_node_in_group("rennanzeige")
	if renn != null and not String(renn.get("schlusstext")).is_empty():
		_auswertung.platz = int(renn.call("platz"))
		_auswertung.platz_von = (renn.get("fahrer") as Array).size()
	_anzeige.add_child(_auswertung)


func _auf_zeitwertung(daten: Dictionary) -> void:
	if _auswertung != null:
		_auswertung.zeit_setzen(daten)


# =============================================================== Meldung

## Kleine Meldung ("Checkpoint", "Schutz hält!") als Kapsel oben in der
## Mitte: gleitet herab, steht, blendet aus. Eine neue ersetzt die alte
## sofort – der Tween wird gehalten und abgebrochen, sonst blendete das
## Ende der alten die neue gleich wieder aus.
class Meldung extends Control:
	const GROESSE := 24
	var text := ""
	var ein := 0.0:
		set(wert):
			ein = wert
			modulate.a = clampf(wert, 0.0, 1.0)
			queue_redraw()
	var _tween: Tween = null

	func _init() -> void:
		name = "Meldung"
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func zeigen(inhalt: String, dauer: float) -> void:
		text = inhalt
		_abbrechen()
		visible = true
		if ein <= 0.0:
			ein = 0.0
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.tween_property(self, ^"ein", 1.0, maxf(0.22 * (1.0 - ein), 0.01)) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_interval(maxf(dauer, 0.2))
		_tween.tween_property(self, ^"ein", 0.0, 0.3) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.tween_callback(hide)
		queue_redraw()

	func verbergen() -> void:
		if not visible:
			return
		_abbrechen()
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.tween_property(self, ^"ein", 0.0, maxf(0.15 * ein, 0.01))
		_tween.tween_callback(hide)

	func _abbrechen() -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = null

	func _draw() -> void:
		if text.is_empty():
			return
		var breite := UiStil.textbreite(text, GROESSE, &"fett") + 52.0
		var hoehe := 46.0
		var mitte_x := size.x * 0.5
		var oben := size.y * 0.17 - 14.0 * (1.0 - ein)
		UiStil.zeichne(self, Rect2(mitte_x - breite * 0.5, oben, breite, hoehe), &"chip")
		UiStil.text(self, Vector2(mitte_x, oben + hoehe * 0.5 + GROESSE * 0.36), text,
				GROESSE, Farben.UI_HELL, &"fett", -1, HORIZONTAL_ALIGNMENT_CENTER)


# =============================================================== Band

## Das große Band für seltene Momente: schräg, farbig, mit Wucht herein
## (groß → normal, federnd), nach oben hinaus.
class Band extends Control:
	const GROESSE := 52
	var text := ""
	var farbe := Farben.UI_GOLD
	var skala := 1.0:
		set(wert):
			skala = wert
			queue_redraw()
	var breite_anteil := 0.0:
		set(wert):
			breite_anteil = wert
			queue_redraw()
	var aus := 0.0:
		set(wert):
			aus = wert
			queue_redraw()
	var _tween: Tween = null

	func _init() -> void:
		name = "Band"
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func zeigen(inhalt: String, ton: Color, dauer: float) -> void:
		text = inhalt
		farbe = ton
		if _tween != null and _tween.is_valid():
			_tween.kill()
		visible = true
		skala = 1.5
		breite_anteil = 0.0
		aus = 0.0
		modulate.a = 0.0
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.set_parallel(true)
		_tween.tween_property(self, ^"modulate:a", 1.0, 0.12)
		_tween.tween_property(self, ^"skala", 1.0, 0.34) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, ^"breite_anteil", 1.0, 0.26).set_delay(0.04) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.chain().tween_interval(maxf(dauer, 0.4))
		_tween.chain().tween_property(self, ^"aus", 1.0, 0.35) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_tween.tween_property(self, ^"modulate:a", 0.0, 0.35)
		_tween.chain().tween_callback(hide)

	func verbergen() -> void:
		if not visible:
			return
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		_tween.tween_property(self, ^"modulate:a", 0.0, 0.15)
		_tween.tween_callback(hide)

	func _draw() -> void:
		if text.is_empty():
			return
		var mitte := Vector2(size.x * 0.5, size.y * 0.3 - 22.0 * aus)
		draw_set_transform(mitte, 0.0, Vector2.ONE * skala)
		var tb := UiStil.textbreite(text, GROESSE, &"schwung")
		var bw := (tb + 84.0) * breite_anteil
		if bw > 2.0:
			var h := 64.0
			UiStil.getoent(&"band", farbe).draw(get_canvas_item(),
					Rect2(-bw * 0.5, -h * 0.5, bw, h))
			# Heller Streif oben: macht aus der Fläche ein Band
			draw_rect(Rect2(-bw * 0.5 + 10.0, -h * 0.5 + 5.0, bw - 20.0, 3.0),
					Color(1, 1, 1, 0.28))
		UiStil.text(self, Vector2(0.0, GROESSE * 0.36), text, GROESSE, Farben.UI_HELL,
				&"schwung", 10, HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform_matrix(Transform2D.IDENTITY)


# =============================================================== Titelkarte

## "LEVEL 01 · WURZELWALD / Wurzelschlucht" im linken unteren Drittel, wie
## ein Filmtitel: gleitet herein, steht gut zwei Sekunden, geht. Links
## unten, weil dort weder Figur (Mitte) noch Zähler (oben) stehen.
class Titelkarte extends Control:
	const GROESSE := 60
	## Abstand vom linken Rand.
	const RAND := 64.0
	var kopf := ""
	var titel := ""
	var ein := 0.0:
		set(wert):
			ein = wert
			queue_redraw()
	var strich := 0.0:
		set(wert):
			strich = wert
			queue_redraw()

	func _init(kopfzeile: String, levelname: String) -> void:
		name = "Titelkarte"
		kopf = kopfzeile
		titel = levelname
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		var t := create_tween()
		t.set_ignore_time_scale(true)
		# Erst den Ladeschirm ausblenden lassen (0,35 s), dann hereingleiten
		t.tween_interval(0.4)
		t.tween_property(self, ^"ein", 1.0, 0.55) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(self, ^"strich", 1.0, 0.45).set_delay(0.25) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_interval(2.2)
		t.tween_property(self, ^"ein", 0.0, 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(queue_free)

	func _draw() -> void:
		if ein <= 0.0 or titel.is_empty():
			return
		var e := ein
		var x := RAND - 44.0 * (1.0 - e)
		var y := size.y * 0.64
		var tb := UiStil.textbreite(titel, GROESSE, &"titel")
		# Weicher dunkler Hof hinter der Schrift – lesbar über hellem Laub,
		# ohne Kasten.
		draw_texture_rect(UiStil.radialverlauf(Color(Farben.UI_NACHT, 0.62),
				Color(Farben.UI_NACHT, 0.0)),
				Rect2(x - 180.0, y - 150.0, tb + 380.0, 230.0), false, Color(1, 1, 1, e))
		UiStil.text(self, Vector2(x + 3.0, y - 62.0), kopf, 15,
				Color(Farben.UI_GOLD, e), &"sperr", 4)
		UiStil.text(self, Vector2(x, y), titel, GROESSE,
				Color(Farben.UI_TITEL_FUELLUNG, e), &"titel", 10)
		var lang := (tb - 8.0) * strich
		if lang > 1.0:
			var linie := Rect2(x + 4.0, y + 16.0, lang, 4.0)
			draw_rect(linie.grow(1.5), Color(Farben.UI_KONTUR, 0.8 * e))
			draw_rect(linie, Color(Farben.UI_GOLD, e))
			UiStil.raute(self, Vector2(linie.end.x + 9.0, linie.get_center().y), 6.0 * strich,
					Color(Farben.UI_GOLD, e))


# =============================================================== Auswertung

## Die Karte am Ziel: Früchte zählen hoch, der Kistenbalken füllt sich, die
## Edelsteine springen in ihre Fassungen, Konfetti fliegt. Ersetzt die
## losen Meldungen "Level geschafft!" und "Alle Kisten! Edelstein
## erhalten". Alles in gut zwei Sekunden – `LevelBasis` wechselt nach 4,5 s
## (im Zeitlauf nach 5,6 s) in den Portalraum, der Ladeschirm deckt sie dann.
class Auswertung extends Control:
	const BREITE := 560.0
	const ZEILE := 50.0

	var daten: Dictionary
	## Platzierung im Rennen (0 = kein Rennen).
	var platz := 0
	var platz_von := 0
	var zeit_daten: Dictionary = {}

	var ein := 0.0
	var band_ein := 0.0
	var fruechte_zahl := 0
	var kisten_anteil := 0.0
	var stein_pop: Array[float] = [0.0, 0.0, 0.0]
	var _konfetti: CPUParticles2D

	static var _schnipsel: ImageTexture = null

	func _init(werte: Dictionary) -> void:
		name = "Auswertung"
		daten = werte
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_to_group(&"auswertung")

	func _ready() -> void:
		_konfetti = _baue_konfetti()
		add_child(_konfetti)
		var t := create_tween()
		t.set_ignore_time_scale(true)
		t.tween_property(self, ^"ein", 1.0, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(self, ^"band_ein", 1.0, 0.32).set_delay(0.12) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_callback(_konfetti_los).set_delay(0.18)
		# Früchte zählen hoch
		var ziel := int(daten.get("fruechte", 0))
		t.tween_method(_fruechte_zaehlen, 0.0, float(ziel), clampf(0.25 + ziel * 0.02, 0.3, 0.8)) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# Kistenbalken füllt sich
		var gesamt := int(daten.get("kisten_gesamt", 0))
		if gesamt > 0:
			var anteil := clampf(float(int(daten.get("kisten", 0))) / float(gesamt), 0.0, 1.0)
			t.tween_property(self, ^"kisten_anteil", anteil, 0.55) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# Edelsteine nacheinander
		for i in 3:
			t.tween_callback(_stein_klang.bind(i))
			t.tween_method(_stein_setzen.bind(i), 0.0, 1.0, 0.42) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	## Kommt im selben Bild wie die Karte (aus `LevelBasis._zeitlauf_werten`).
	func zeit_setzen(werte: Dictionary) -> void:
		zeit_daten = werte

	func _process(_delta: float) -> void:
		queue_redraw()

	func _fruechte_zaehlen(wert: float) -> void:
		var ganz := roundi(wert)
		if ganz != fruechte_zahl:
			if ganz % 3 == 0:
				Klang.spiele("frucht", 1.0 + minf(ganz, 60) * 0.012, 0.5)
			fruechte_zahl = ganz

	func _stein_setzen(wert: float, i: int) -> void:
		stein_pop[i] = wert

	func _stein_klang(i: int) -> void:
		if _stein_erreicht(i):
			Klang.spiele("checkpoint", 1.15 + 0.12 * i, 0.55)

	## Ein Level ohne Kisten (Rennen, Flug) bekommt weder Zeile noch
	## Kistenstein – "0/0" und ein unerreichbarer Stein sagen nichts.
	func _mit_kisten() -> bool:
		return int(daten.get("kisten_gesamt", 0)) > 0

	## In diesem Lauf verdient: Kisten, ohne Tod, Zeitstufe.
	func _stein_erreicht(i: int) -> bool:
		match i:
			0:
				return bool(daten.get("alle_kisten", false))
			1:
				return bool(daten.get("ohne_tod", false))
			2:
				return int(zeit_daten.get("stufe", 0)) > 0
		return false

	func _stein_vorher(i: int) -> bool:
		match i:
			0:
				return bool(daten.get("hatte_kisten", false))
			1:
				return bool(daten.get("hatte_ohne_tod", false))
		return false

	func _konfetti_los() -> void:
		if is_instance_valid(_konfetti):
			_konfetti.position = Vector2(size.x * 0.5, _kartenfeld().position.y)
			_konfetti.restart()

	func _baue_konfetti() -> CPUParticles2D:
		var k := CPUParticles2D.new()
		k.name = "Konfetti"
		k.emitting = false
		k.one_shot = true
		k.amount = 56
		k.lifetime = 2.4
		k.explosiveness = 0.92
		k.texture = _schnipsel_textur()
		k.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		k.emission_rect_extents = Vector2(150.0, 8.0)
		k.direction = Vector2(0.0, -1.0)
		k.spread = 62.0
		k.initial_velocity_min = 380.0
		k.initial_velocity_max = 640.0
		k.gravity = Vector2(0.0, 820.0)
		k.damping_min = 40.0
		k.damping_max = 90.0
		k.angle_min = -180.0
		k.angle_max = 180.0
		k.angular_velocity_min = -420.0
		k.angular_velocity_max = 420.0
		k.scale_amount_min = 0.7
		k.scale_amount_max = 1.2
		var bunt := Gradient.new()
		bunt.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		bunt.set_color(0, Farben.FRUCHT)
		bunt.set_color(1, Farben.EDELSTEIN_OHNE_TOD)
		bunt.add_point(0.25, Farben.UI_GOLD)
		bunt.add_point(0.5, Farben.EDELSTEIN_KISTEN)
		bunt.add_point(0.75, Farben.KISTE_LEBEN)
		k.color_initial_ramp = bunt
		var aus := Gradient.new()
		aus.set_color(0, Color.WHITE)
		aus.set_color(1, Color(1, 1, 1, 0))
		aus.add_point(0.75, Color.WHITE)
		k.color_ramp = aus
		return k

	static func _schnipsel_textur() -> ImageTexture:
		if _schnipsel == null:
			var bild := Image.create(6, 11, false, Image.FORMAT_RGBA8)
			bild.fill(Color.WHITE)
			_schnipsel = ImageTexture.create_from_image(bild)
		return _schnipsel

	func _kartenfeld() -> Rect2:
		var hoehe := 150.0 + ZEILE * 2.0 + 92.0 + 18.0
		if not _mit_kisten():
			hoehe -= ZEILE
		if not zeit_daten.is_empty():
			hoehe += ZEILE
		if platz > 0:
			hoehe += 40.0
		var breite := minf(BREITE, size.x - 32.0)
		return Rect2((size.x - breite) * 0.5, size.y * 0.53 - hoehe * 0.5, breite, hoehe)

	func _draw() -> void:
		if ein <= 0.0:
			return
		var feld := _kartenfeld()
		var mitte := feld.get_center()
		var s := lerpf(0.88, 1.0, ein)
		# Abdunkeln hinter der Karte, die Welt bleibt zu sehen
		draw_rect(Rect2(Vector2.ZERO, size), Color(Farben.UI_NACHT, 0.38 * minf(ein, 1.0)))
		draw_set_transform(mitte * (1.0 - s), 0.0, Vector2.ONE * s)
		UiStil.zeichne(self, feld, &"tafel")

		var links := feld.position.x + 34.0
		var rechts := feld.end.x - 34.0
		var y := feld.position.y + 72.0
		var nummer := int(daten.get("nummer", 0))
		UiStil.text(self, Vector2(mitte.x, y), Spielfluss.level_kopfzeile(nummer), 14,
				Farben.UI_GOLD, &"sperr", -1, HORIZONTAL_ALIGNMENT_CENTER)
		y += 36.0
		UiStil.text(self, Vector2(mitte.x, y), String(daten.get("name", "")), 32,
				Farben.UI_TITEL_FUELLUNG, &"titel", -1, HORIZONTAL_ALIGNMENT_CENTER)
		if platz > 0:
			y += 40.0
			var ton := Farben.UI_HELL
			match platz:
				1:
					ton = Farben.UI_GOLD
				2:
					ton = Farben.UI_SILBER
				3:
					ton = Farben.UI_BRONZE
			UiStil.text(self, Vector2(mitte.x, y), "Platz %d von %d" % [platz, platz_von],
					24, ton, &"fett", -1, HORIZONTAL_ALIGNMENT_CENTER)
		y += 20.0
		draw_line(Vector2(links, y), Vector2(rechts, y), Color(1, 1, 1, 0.12), 1.5)

		# --- Früchte ---
		y += ZEILE * 0.5 + 6.0
		UiStil.frucht(self, Vector2(links + 14.0, y + 1.0), 12.0)
		UiStil.text(self, Vector2(links + 40.0, y + 6.5), "Früchte", 18, Farben.UI_TEXT_RUHE,
				&"fett")
		UiStil.text(self, Vector2(rechts, y + 10.0), "%d" % fruechte_zahl, 28,
				Farben.FRUCHT.lightened(0.55), &"zahl", -1, HORIZONTAL_ALIGNMENT_RIGHT)

		# --- Kisten ---
		var gesamt := int(daten.get("kisten_gesamt", 0))
		var zerbrochen := int(daten.get("kisten", 0))
		if gesamt > 0:
			y += ZEILE
			UiStil.kiste(self, Vector2(links + 14.0, y), 10.0)
			UiStil.text(self, Vector2(links + 40.0, y + 6.5), "Kisten", 18,
					Farben.UI_TEXT_RUHE, &"fett")
			var alle := zerbrochen >= gesamt
			var balken := Rect2(links + 130.0, y - 7.0, rechts - links - 130.0 - 92.0, 14.0)
			var voll := kisten_anteil >= float(zerbrochen) / float(gesamt) - 0.001
			UiStil.balken(self, balken, kisten_anteil,
					Farben.KISTE_LEBEN if alle and voll else Farben.FRUCHT)
			UiStil.text(self, Vector2(rechts, y + 8.0), "%d/%d" % [
					roundi(kisten_anteil * gesamt), gesamt], 22,
					Farben.KISTE_LEBEN.lightened(0.4) if alle and voll else Farben.UI_HELL,
					&"zahl", -1, HORIZONTAL_ALIGNMENT_RIGHT)

		# --- Zeit ---
		if not zeit_daten.is_empty():
			y += ZEILE
			var stufe := int(zeit_daten.get("stufe", 0))
			UiStil.text(self, Vector2(links + 40.0, y + 6.5), "Zeit", 18, Farben.UI_TEXT_RUHE,
					&"fett")
			var zt := Zeitlauf.als_text(float(zeit_daten.get("zeit", 0.0)))
			var zb := UiStil.text(self, Vector2(links + 130.0, y + 9.0), zt, 24,
					Farben.UI_HELL, &"zahl")
			if stufe > 0:
				UiStil.text(self, Vector2(links + 146.0 + zb, y + 7.0),
						Zeitlauf.stufen_name(stufe), 18,
						Zeitlauf.stufen_farbe(stufe).lightened(0.2), &"fett")
			if bool(zeit_daten.get("bestzeit", false)):
				_pille(Vector2(rechts, y), "BESTZEIT", Farben.UI_GOLD)
			# Uhrsymbol statt Frucht und Kiste
			var uhr := Vector2(links + 14.0, y)
			draw_circle(uhr, 12.5, Farben.UI_KONTUR, true, -1.0, true)
			draw_circle(uhr, 10.5, Farben.KISTE_ZEIT.lightened(0.25), true, -1.0, true)
			draw_line(uhr, uhr + Vector2(0, -7), Farben.UI_KONTUR, 2.0, true)
			draw_line(uhr, uhr + Vector2(5, 2), Farben.UI_KONTUR, 2.0, true)

		# --- Edelsteine ---
		y += ZEILE * 0.5 + 44.0
		var steine: Array[int] = [1]
		if _mit_kisten():
			steine.push_front(0)
		if int(zeit_daten.get("stufe", 0)) > 0:
			steine.append(2)
		var abstand := 150.0
		var start := mitte.x - abstand * (steine.size() - 1) * 0.5
		for j in steine.size():
			var i := steine[j]
			_zeichne_stein(Vector2(start + abstand * j, y), i)

		draw_set_transform_matrix(Transform2D.IDENTITY)

		# --- Band "GESCHAFFT!" über der Oberkante ---
		if band_ein > 0.0:
			var bs := lerpf(1.6, 1.0, band_ein)
			var oben := Vector2(mitte.x, feld.position.y)
			draw_set_transform(oben, -0.03, Vector2.ONE * bs)
			var tb := UiStil.textbreite("GESCHAFFT!", 50, &"schwung")
			var bw := tb + 90.0
			UiStil.flaeche(&"band").draw(get_canvas_item(), Rect2(-bw * 0.5, -34.0, bw, 66.0))
			draw_rect(Rect2(-bw * 0.5 + 10.0, -29.0, bw - 20.0, 3.0), Color(1, 1, 1, 0.3))
			UiStil.text(self, Vector2(0.0, 18.0), "GESCHAFFT!", 50, Farben.UI_HELL,
					&"schwung", 10, HORIZONTAL_ALIGNMENT_CENTER)
			draw_set_transform_matrix(Transform2D.IDENTITY)

	func _zeichne_stein(ort: Vector2, i: int) -> void:
		var farben: Array[Color] = [Farben.EDELSTEIN_KISTEN, Farben.EDELSTEIN_OHNE_TOD,
				Zeitlauf.stufen_farbe(int(zeit_daten.get("stufe", 0)))]
		var namen: Array[String] = ["Alle Kisten", "Ohne Tod",
				Zeitlauf.stufen_name(int(zeit_daten.get("stufe", 0)))]
		UiStil.fassung(self, ort, 28.0)
		var jetzt := _stein_erreicht(i)
		var p := stein_pop[i]
		if jetzt and p > 0.0:
			# Kranz aus kurzen Strahlen, der aufgeht und verlischt
			var k := clampf((p - 0.1) / 0.9, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				for n in 8:
					var w := TAU * n / 8.0 + 0.2
					var r0 := 22.0 + 26.0 * k
					var d := Vector2(cos(w), sin(w))
					draw_line(ort + d * r0, ort + d * (r0 + 10.0 * (1.0 - k)),
							Color(farben[i].lightened(0.4), 1.0 - k), 3.0, true)
			draw_set_transform(ort, 0.0, Vector2.ONE * maxf(p, 0.0))
			UiStil.edelstein(self, Vector2(0.0, -1.0), 19.0, farben[i])
			draw_set_transform_matrix(Transform2D.IDENTITY)
			var neu := not _stein_vorher(i) and i < 2
			if neu and p > 0.6:
				_pille(ort + Vector2(28.0, -24.0), "NEU", farben[i].lightened(0.3), true)
		elif _stein_vorher(i):
			# Schon früher verdient, diesmal nicht: blass in der Fassung
			UiStil.edelstein(self, Vector2(ort.x, ort.y - 1.0), 19.0, farben[i], true, 0.35)
		else:
			UiStil.edelstein(self, Vector2(ort.x, ort.y - 1.0), 19.0, farben[i], false)
		var hell := jetzt and p > 0.5
		UiStil.text(self, ort + Vector2(0.0, 50.0), namen[i], 14,
				Farben.UI_HELL if hell else Farben.UI_MATT, &"fett", -1,
				HORIZONTAL_ALIGNMENT_CENTER)

	## Kleine Marke ("NEU", "BESTZEIT"). `mittig` = Mitte statt rechtes Ende.
	func _pille(ort: Vector2, inhalt: String, ton: Color, mittig: bool = false) -> void:
		var tb := UiStil.textbreite(inhalt, 12, &"fett")
		var w := tb + 20.0
		var feld := Rect2(ort.x - (w * 0.5 if mittig else w), ort.y - 11.0, w, 22.0)
		UiStil.getoent(&"pille", ton).draw(get_canvas_item(), feld)
		UiStil.text(self, Vector2(feld.get_center().x, ort.y + 4.5), inhalt, 12,
				Farben.UI_KONTUR, &"fett", 0, HORIZONTAL_ALIGNMENT_CENTER)
