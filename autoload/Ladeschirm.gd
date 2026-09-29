extends CanvasLayer
## Ladebildschirm, der Szenenwechsel überdeckt.
##
## Als Autoload unter dem Namen "Ladeschirm" registriert und deshalb über
## Szenenwechsel hinweg vorhanden.
##
## Der Aufbau von Level 01 dauert rund fünf Sekunden, weil Gelände, Wald
## und Objekte im Code erzeugt werden. Damit das nicht als eingefrorenes
## Bild erscheint, meldet `LevelBasis` seinen Fortschritt hierher und gibt
## zwischen den Bauschritten ein Bild frei – so läuft die Anzeige weiter.
##
## Aussehen: Grund im Farbton des Raums, in den es geht (Wurzelwald grün,
## Nebelsümpfe blaugrau, Steinfeste warmer Stein, Rost und Ranken
## rostrot, Sand und Neon violett), ein Lichtschein hinter dem Titel,
## aufsteigende Flusen, Vignette. Im unteren Drittel stehen zwei Reihen
## Scherenschnitt, die den Raum zeigen: Tannen im Wurzelwald, Weiden, Schilf
## und Bohlensteg in den Sümpfen, Mauer und Türme der Steinfeste, Schlote
## im Rost, Dünen und Dächer bei Sand und Neon, im Portalraum Hügel mit den
## fünf Portalringen. Darauf Kicker ("LEVEL 01 · WURZELWALD"), Titel, was
## gerade gebaut wird, hüpfende Früchte, ein gerundeter Ladebalken und ein
## Tipp als Kapsel.
##
## Schnittstelle:
##   zeigen(titel, dauer := 0.0)   einblenden; dauer 0 = sofort deckend
##   eingeblendet                  Signal: der Schirm deckt jetzt ganz
##   fortschritt(anteil, text)     Baufortschritt 0..1 und was gerade läuft
##   verbergen()                   weich ausblenden
##   abblenden(dauer) / aufblenden(dauer) -> Tween
##                                 nur Dunkel, ohne Titel – für Wechsel,
##                                 die keinen Ladeschirm brauchen
##
## Scherenschnitt als Werkzeug (statisch, über `preload` dieses Skripts):
##   reihe(formen, breite, schritt, erzeuger, versatz, mitte_flach)
##   baum(tanne, hoehe) -> Form      zerlege(formen, ...) -> Dreiecke
## Die Einstellungen zeichnen damit ihren Waldrand.
##
## Wer einblendet und danach einen blockierenden Szenenwechsel startet,
## wartet auf `eingeblendet`:
##     Ladeschirm.zeigen(titel, 0.22)
##     await Ladeschirm.eingeblendet
## Ohne `dauer` deckt der Schirm sofort – so bleibt nie ein halb
## durchsichtiger Schirm über einer eingefrorenen Szene stehen, wenn der
## Aufrufer nicht wartet. Aus demselben Grund vollendet `fortschritt()`
## ein laufendes Einblenden: Wer Fortschritt meldet, blockiert gleich.

signal eingeblendet

const TIPPS := [
	"Slide und dann springen bringt dich höher als ein normaler Sprung.",
	"Die Spin-Attacke zerbricht Kisten auch im Vorbeidrehen.",
	"Der Bauchplatscher zerbricht alle Kisten im Umkreis von zwei Metern.",
	"Die Sumpfkröte spinnen, die Stelzenspinne unterrutschen, auf den Panzerkäfer springen.",
	"Nitrokisten explodieren bei Berührung – aus der Ferne sind sie ungefährlich.",
	"Federkisten geben zehn Früchte, wenn du zehnmal darauf springst.",
	"Hundert Früchte ergeben ein Extraleben.",
	"Gelbe Streifen auf dem Weg warnen vor einem Loch.",
]

## Farben je Raum: [oben, unten, Schein]. Eintrag 0 gilt für den
## Portalraum und alles ohne Level.
const RAUMTOENE := [
	[Color(0.07, 0.10, 0.12), Color(0.02, 0.03, 0.04), Color(1.0, 0.82, 0.50)],
	[Color(0.07, 0.17, 0.09), Color(0.02, 0.045, 0.03), Color(0.95, 0.86, 0.45)],
	[Color(0.05, 0.13, 0.14), Color(0.015, 0.04, 0.05), Color(0.55, 0.88, 0.82)],
	[Color(0.16, 0.12, 0.08), Color(0.04, 0.03, 0.02), Color(1.0, 0.78, 0.50)],
	[Color(0.18, 0.08, 0.04), Color(0.05, 0.02, 0.015), Color(1.0, 0.56, 0.28)],
	[Color(0.11, 0.05, 0.18), Color(0.03, 0.015, 0.05), Color(0.84, 0.52, 1.0)],
]

## Aufsteigende Flusen im Hintergrund.
const FLUSEN := 18

## Scherenschnitt: Grundlinie (Anteil der Bildhöhe) und größte Höhe der
## Formen (px) für die hintere und die vordere Reihe. In der Bildmitte
## bleiben die Formen niedriger (`_huelle`) – dort stehen Balken und Tipp.
const REIHE_HINTEN := Vector2(0.86, 150.0)
const REIHE_VORN := Vector2(0.955, 95.0)
## Abstand der Stützstellen des Umrisses (px). Spitzen und Kanten kommen
## zusätzlich als eigene Stellen hinein, damit sie scharf bleiben.
const UMRISS_SCHRITT := 4.0

var _flaeche: Control
var _blende: UiStil.Blende
var _titel := ""
var _kicker := ""
var _text := ""
var _anteil := 0.0
## Angezeigter Anteil: folgt `_anteil` weich, statt bei jedem Bauschritt
## zu springen.
var _anteil_anzeige := 0.0
var _tipp := ""
var _phase := 0.0
var _sichtbar := false
var _raum := 0
var _tween: Tween = null
var _blendet_ein := false
## Fertig zerlegte Scherenschnitte (Dreieckslisten) für Raum und Bildgröße
## in `_umriss_fuer`. Der Schirm zeichnet jedes Bild neu; ein Vieleck mit
## Hunderten Ecken jedes Mal neu zu zerlegen wäre Verschwendung.
var _umriss_fuer := ""
var _umriss_hinten := PackedVector2Array()
var _umriss_vorn := PackedVector2Array()
## Einzelteile, die nicht aus dem Boden wachsen (Steg, Portalringe):
## ["steg", Rect2] oder ["ring", Mitte, Radius, Farbe]
var _umriss_extra: Array = []
## Schon zerlegte Scherenschnitte je Raum und Bildgröße (Schlüssel wie
## `_umriss_fuer`, Wert [hinten, vorn, extra]). Mit nur einem Eintrag
## wurde bei jedem Wechsel Portalraum → Level neu zerlegt.
var _umrisse: Dictionary[String, Array] = {}
## Mehr Einträge verwirft der Zwischenspeicher (Fenster, das gezogen wird).
const UMRISSE_HOECHSTENS := 12


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_flaeche = Control.new()
	_flaeche.name = "Flaeche"
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_STOP
	_flaeche.theme = UiStil.thema()
	_flaeche.draw.connect(_zeichnen)
	add_child(_flaeche)

	_blende = UiStil.Blende.new()
	add_child(_blende)

	_flaeche.modulate.a = 0.0
	_flaeche.visible = false


func ist_sichtbar() -> bool:
	return _sichtbar


## Blendet den Ladebildschirm ein. Ohne `dauer` deckt er sofort (siehe
## Kopfkommentar), mit `dauer` blendet er weich auf. `eingeblendet` kommt,
## sobald er ganz deckt – bei `dauer` 0 im nächsten Augenblick.
func zeigen(titel: String, dauer: float = 0.0) -> void:
	_kopf_setzen(titel)
	_text = "Wird geladen"
	_anteil = 0.0
	_anteil_anzeige = 0.0
	_tipp = TIPPS[randi() % TIPPS.size()]
	_raum = _raum_jetzt()
	_sichtbar = true
	# Ein laufendes Einblenden wird hier ersetzt, nicht abgebrochen: Wer
	# darauf wartet, läuft erst weiter, wenn der Schirm wirklich deckt –
	# nicht schon bei einem halb durchsichtigen (siehe `_tween_stoppen`).
	_tween_stoppen(false)
	_flaeche.visible = true
	_flaeche.queue_redraw()
	if dauer <= 0.0 or _flaeche.modulate.a >= 0.999:
		_flaeche.modulate.a = 1.0
		_blendet_ein = false
		eingeblendet.emit.call_deferred()
		return
	_blendet_ein = true
	_tween = create_tween()
	_tween.tween_property(_flaeche, ^"modulate:a", 1.0,
			dauer * (1.0 - _flaeche.modulate.a)) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		_blendet_ein = false
		eingeblendet.emit())


## Meldet den Baufortschritt. `anteil` von 0.0 bis 1.0.
func fortschritt(anteil: float, text: String = "") -> void:
	_anteil = clampf(anteil, 0.0, 1.0)
	if not text.is_empty():
		_text = text
	if not _sichtbar:
		return
	# Wer Fortschritt meldet, blockiert gleich den Hauptfaden – ein halb
	# eingeblendeter Schirm bliebe dann so stehen.
	if _blendet_ein and _tween != null and _tween.is_valid():
		_tween.custom_step(10.0)
	_flaeche.queue_redraw()


## Blendet den Ladebildschirm weich aus. Bricht ein laufendes Einblenden
## ab – vorher konnte das Ende eines alten Ausblendens einen gerade neu
## gezeigten Schirm wieder verstecken.
func verbergen() -> void:
	if not _sichtbar:
		return
	_sichtbar = false
	_tween_stoppen(true)
	_tween = create_tween()
	_tween.tween_property(_flaeche, ^"modulate:a", 0.0, 0.45 * _flaeche.modulate.a) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func() -> void: _flaeche.visible = false)


## Nur Dunkel, ohne Titel und Balken – für Szenenwechsel, die schnell
## gehen (Menü zu Menü). `await Ladeschirm.abblenden().finished`, dann
## wechseln, dann `aufblenden()`.
func abblenden(dauer: float = 0.18) -> Tween:
	return _blende.zu(dauer)


func aufblenden(dauer: float = 0.3) -> Tween:
	return _blende.auf(dauer)


## Hält den laufenden Tween an. `melden`: Bricht `verbergen()` ein
## Einblenden ab, bekommt, wer darauf wartet, sein Signal trotzdem – sonst
## wartete er ewig. Ersetzt `zeigen()` es durch ein neues, meldet erst
## dessen Ende.
func _tween_stoppen(melden: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if melden and _blendet_ein:
		_blendet_ein = false
		eingeblendet.emit.call_deferred()


func _process(delta: float) -> void:
	if not _flaeche.visible:
		return
	_phase += delta
	_anteil_anzeige = UiStil.annaehern(_anteil_anzeige, _anteil, delta, 6.0, 0.4)
	_flaeche.queue_redraw()


# ------------------------------------------------------------ Inhalt

## Kicker und Titel. Im Level: "LEVEL 01 · WURZELWALD" über dem
## Levelnamen. `Spielfluss.zum_level()` übergibt "Level 01"; Name und
## Kopfzeile kommen aus dem Spielfluss – dieselben wie über der Blende des
## Portals und auf der Titelkarte des HUD. Ohne Namen (unbekannte Nummer)
## bleibt "Level 01" der Titel, darüber steht nur der Raum.
func _kopf_setzen(titel: String) -> void:
	_titel = titel
	_kicker = ""
	var nummer := Spielfluss.aktuelles_level
	if nummer < 1:
		_kicker = "%d VON %d LEVELN FREIGESCHALTET" % [
				mini(Spielfluss.freigeschaltet, Spielfluss.LEVEL_GESAMT),
				Spielfluss.LEVEL_GESAMT]
		return
	var nur_nummer := "Level %02d" % nummer
	if titel == nur_nummer:
		var name := Spielfluss.level_name(nummer)
		if not name.is_empty():
			_titel = name
	if _titel == nur_nummer:
		var raum := Spielfluss.raum_von_level(nummer)
		var namen: Array = Spielfluss.RAUM_NAMEN
		_kicker = "RAUM %d · %s" % [raum,
				String(namen[clampi(raum - 1, 0, namen.size() - 1)]).to_upper()]
	else:
		_kicker = Spielfluss.level_kopfzeile(nummer)


func _raum_jetzt() -> int:
	var nummer := Spielfluss.aktuelles_level
	if nummer < 1:
		return 0
	return clampi(Spielfluss.raum_von_level(nummer), 0, RAUMTOENE.size() - 1)


# ------------------------------------------------------------- Zeichnen

func _zeichnen() -> void:
	var groesse := _flaeche.size
	var feld := Rect2(Vector2.ZERO, groesse)
	var mitte := groesse * 0.5
	var toene: Array = RAUMTOENE[_raum]
	var oben: Color = toene[0]
	var unten: Color = toene[1]
	var schein: Color = toene[2]

	# Grund im Ton des Raums, Lichtschein hinter dem Titel
	UiStil.verlauf(_flaeche, feld, oben, unten)
	var hof := UiStil.radialverlauf(Color(schein, 0.28), Color(schein, 0.0))
	_flaeche.draw_texture_rect(hof, Rect2(mitte - Vector2(520, 330),
			Vector2(1040, 560)), false)
	_zeichne_flusen(groesse, schein)
	_zeichne_scherenschnitt(groesse, schein)
	UiStil.vignette(_flaeche, feld, 0.55)

	# Kicker mit Zierstrichen, Titel, was gerade geschieht
	if not _kicker.is_empty():
		var kicker_y := mitte.y - 108.0
		var breite := UiStil.text(_flaeche, Vector2(mitte.x, kicker_y), _kicker, 15,
				Farben.UI_GOLD, &"sperr", 3, HORIZONTAL_ALIGNMENT_CENTER)
		var strich_y := kicker_y - 5.0
		var abstand := breite * 0.5 + 16.0
		for seite in [-1.0, 1.0]:
			var s := float(seite)
			_flaeche.draw_line(Vector2(mitte.x + s * abstand, strich_y),
					Vector2(mitte.x + s * (abstand + 44.0), strich_y),
					Color(Farben.UI_GOLD, 0.5), 1.5, true)
			UiStil.raute(_flaeche, Vector2(mitte.x + s * (abstand + 50.0), strich_y),
					3.0, Color(Farben.UI_GOLD, 0.8))
	var titelgroesse := UiStil.passend(UiStil.schrift(&"titel"), _titel, 56,
			groesse.x - 80.0, 28)
	UiStil.text(_flaeche, Vector2(mitte.x, mitte.y - 46.0), _titel, titelgroesse,
			Farben.UI_HELL, &"titel", 6, HORIZONTAL_ALIGNMENT_CENTER)
	UiStil.text(_flaeche, Vector2(mitte.x, mitte.y - 8.0), _text, 17,
			Color(0.80, 0.86, 0.80), &"text", 3, HORIZONTAL_ALIGNMENT_CENTER)

	_zeichne_fruechte(mitte)

	# Ladebalken: Rinne, Füllung mit Glanzlicht, das über die Füllung
	# wandert, und die Zahl darunter.
	var breite_balken := minf(groesse.x * 0.46, 460.0)
	var balken := Rect2(mitte.x - breite_balken * 0.5, mitte.y + 92.0, breite_balken, 14.0)
	UiStil.balken(_flaeche, balken, _anteil_anzeige)
	var voll := (balken.size.x - 4.0) * _anteil_anzeige
	if voll > 24.0:
		# Ein schräger Streifen; jede Ecke wird einzeln auf die Füllung
		# beschnitten, so bleibt er auch am Rand ein sauberes Viereck.
		var anfang := balken.position.x + 2.0
		var x := anfang + fmod(_phase * 220.0, voll + 60.0) - 30.0
		var y0 := balken.position.y + 2.0
		var y1 := balken.end.y - 2.0
		var ecken := PackedVector2Array()
		for ecke in [Vector2(x + 6.0, y0), Vector2(x + 30.0, y0),
				Vector2(x + 24.0, y1), Vector2(x, y1)]:
			var punkt: Vector2 = ecke
			punkt.x = clampf(punkt.x, anfang, anfang + voll)
			# Zusammenfallende Ecken weglassen – ein Vieleck mit doppeltem
			# Punkt lässt sich nicht zerlegen.
			if ecken.is_empty() or not ecken[ecken.size() - 1].is_equal_approx(punkt):
				ecken.append(punkt)
		if ecken.size() >= 3 and not ecken[0].is_equal_approx(ecken[ecken.size() - 1]):
			_flaeche.draw_colored_polygon(ecken, Color(1, 1, 1, 0.20))
	UiStil.text(_flaeche, Vector2(mitte.x, balken.end.y + 24.0),
			"%d %%" % roundi(_anteil_anzeige * 100.0), 15, Color(0.74, 0.80, 0.74),
			&"fett", 3, HORIZONTAL_ALIGNMENT_CENTER)

	_zeichne_tipp(groesse)


## Drei Früchte hüpfen nacheinander – mit Blatt, Kontur und einem kurzen
## Stauchen beim Aufkommen, wie ein Ball.
func _zeichne_fruechte(mitte: Vector2) -> void:
	for i in 3:
		var versatz := _phase * 2.2 - float(i) * 0.42
		var sprung := absf(sin(versatz * PI))
		var hoch := sprung * 22.0
		var x := mitte.x - 46.0 + float(i) * 46.0
		var boden := mitte.y + 50.0
		# Schatten am Boden: kleiner und blasser, je höher die Frucht ist
		var schatten := 1.0 - sprung * 0.5
		_flaeche.draw_set_transform(Vector2(x, boden + 12.0), 0.0, Vector2(1.0, 0.35))
		_flaeche.draw_circle(Vector2.ZERO, 12.0 * schatten, Color(0, 0, 0, 0.30 * schatten),
				true, -1.0, true)
		# Stauchen nahe am Boden: breiter und flacher, oben wieder rund
		var stauch := clampf(1.0 - hoch / 5.0, 0.0, 1.0) * 0.18
		_flaeche.draw_set_transform(Vector2(x, boden - hoch), 0.0,
				Vector2(1.0 + stauch, 1.0 - stauch))
		UiStil.frucht(_flaeche, Vector2.ZERO, 12.0)
	_flaeche.draw_set_transform_matrix(Transform2D.IDENTITY)


## Schwebende Flusen, die langsam aufsteigen – nur Kreise, bestimmt aus
## der Zeit, ohne eigenen Zustand.
func _zeichne_flusen(groesse: Vector2, farbe: Color) -> void:
	for i in FLUSEN:
		var saat := float(i) * 12.9898
		var zufall := _zufall(saat)
		var tempo := 18.0 + 22.0 * _zufall(saat + 3.1)
		var x := groesse.x * _zufall(saat + 7.7) + sin(_phase * 0.4 + saat) * 24.0
		var y := groesse.y + 20.0 - fposmod(_phase * tempo + zufall * groesse.y,
				groesse.y + 40.0)
		var r := 1.5 + 2.5 * _zufall(saat + 1.3)
		var deckung := 0.16 + 0.24 * _zufall(saat + 5.5)
		# Oben und unten weich ein- und ausblenden
		deckung *= clampf(y / 120.0, 0.0, 1.0) * clampf((groesse.y - y) / 120.0, 0.0, 1.0)
		_flaeche.draw_circle(Vector2(x, y), r, Color(farbe, deckung), true, -1.0, true)


## Pseudozufall 0..1 aus einer Zahl – gleiche Zahl, gleicher Wert.
static func _zufall(wert: float) -> float:
	var s := sin(wert) * 43758.5453
	return s - floorf(s)


## Tipp als Kapsel am unteren Rand: goldene Marke "TIPP", daneben der Satz.
func _zeichne_tipp(groesse: Vector2) -> void:
	if _tipp.is_empty():
		return
	var zs := UiStil.schrift()
	var text_groesse := UiStil.passend(zs, _tipp, 16, groesse.x - 260.0, 12)
	var text_breite := zs.get_string_size(_tipp, HORIZONTAL_ALIGNMENT_LEFT, -1,
			text_groesse).x
	var marke_breite := UiStil.textbreite("TIPP", 12, &"sperr") + 20.0
	var breite := marke_breite + text_breite + 44.0
	var chip := Rect2(groesse.x * 0.5 - breite * 0.5, groesse.y - 88.0, breite, 46.0)
	# Kapsel und Marke knapp unter voller Rundung – bei genau halber Höhe
	# zeigt StyleBoxFlat an den Enden einen hellen Nahtpunkt.
	var kapsel := func(s: StyleBoxFlat) -> void: s.set_corner_radius_all(21)
	UiStil.variante(&"chip", &"tippkapsel", kapsel).draw(_flaeche.get_canvas_item(), chip)
	var marke := Rect2(chip.position + Vector2(11.0, 11.0), Vector2(marke_breite, 24.0))
	var rund := func(s: StyleBoxFlat) -> void: s.set_corner_radius_all(11)
	UiStil.variante(&"pille", &"tippmarke", rund).draw(_flaeche.get_canvas_item(), marke)
	UiStil.text(_flaeche, Vector2(marke.get_center().x, marke.position.y + 17.0), "TIPP",
			12, Farben.UI_KONTUR, &"sperr", 0, HORIZONTAL_ALIGNMENT_CENTER)
	UiStil.text(_flaeche, Vector2(marke.end.x + 14.0, chip.position.y + 29.0), _tipp,
			text_groesse, Color(0.86, 0.90, 0.84), &"text", 3)


# ------------------------------------------------------ Scherenschnitt

## Zwei Reihen Umriss im unteren Drittel: hinten im Schein des Raums, als
## läge Licht im Dunst, vorn fast schwarz. Darüber ein Hauch Licht am
## Horizont, damit die hintere Reihe sich abhebt.
func _zeichne_scherenschnitt(groesse: Vector2, schein: Color) -> void:
	var kennung := "%d|%d|%d" % [_raum, roundi(groesse.x), roundi(groesse.y)]
	if kennung != _umriss_fuer:
		_umriss_fuer = kennung
		if _umrisse.has(kennung):
			var fertig: Array = _umrisse[kennung]
			_umriss_hinten = fertig[0]
			_umriss_vorn = fertig[1]
			_umriss_extra = fertig[2]
		else:
			_baue_umriss(groesse)
			if _umrisse.size() >= UMRISSE_HOECHSTENS:
				_umrisse.clear()
			_umrisse[kennung] = [_umriss_hinten, _umriss_vorn, _umriss_extra]
	# Bis zum unteren Rand, sonst endete der Schein an der Grundlinie mit
	# einer harten Kante.
	var horizont := groesse.y * REIHE_HINTEN.x
	UiStil.verlauf(_flaeche, Rect2(0.0, horizont - 220.0, groesse.x,
			groesse.y - horizont + 220.0), Color(schein, 0.0), Color(schein, 0.08))
	var ci := _flaeche.get_canvas_item()
	if not _umriss_hinten.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(),
				_umriss_hinten, PackedColorArray([Color(schein, 0.10)]))
	var nacht := Color(0.008, 0.012, 0.012, 0.92)
	# Nach Art gebündelt gezeichnet – erst alle Rechtecke, dann alle
	# Scheiben, dann alle Ränder: Wechselnde Befehlsarten brächen sonst das
	# Bündeln der 2D-Zeichenaufrufe (Portalraum: 144 statt gut 100).
	# Portalring auf einem Sockel: dunkler Rand, darin der Schein des Raums,
	# in den er führt.
	for teil in _umriss_extra:
		var stueck: Array = teil
		if String(stueck[0]) == "steg":
			_flaeche.draw_rect(stueck[1] as Rect2, nacht)
		else:
			var mitte: Vector2 = stueck[1]
			var r: float = stueck[2]
			_flaeche.draw_rect(Rect2(mitte.x - r * 0.75, mitte.y + r * 0.8, r * 1.5,
					r * 0.9), nacht)
	for teil in _umriss_extra:
		var stueck: Array = teil
		if String(stueck[0]) == "ring":
			var farbe: Color = stueck[3]
			_flaeche.draw_circle(stueck[1] as Vector2, float(stueck[2]) * 0.9,
					Color(farbe, 0.38), true, -1.0, true)
	for teil in _umriss_extra:
		var stueck: Array = teil
		if String(stueck[0]) == "ring":
			var r: float = stueck[2]
			_flaeche.draw_arc(stueck[1] as Vector2, r, 0.0, TAU, 32, nacht, r * 0.24, true)
	if not _umriss_vorn.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(),
				_umriss_vorn, PackedColorArray([nacht]))


## Stellt die Formen des Raums zusammen und zerlegt sie in Dreiecke.
##
## Eine Form ist [Art, Mitte x, halbe Breite, Höhe]; `_formhoehe` kennt ihr
## Profil. Der Umriss einer Reihe ist an jeder Stelle die höchste Form
## darüber – so überlappen sich Bäume, ohne dass Flächen doppelt gedeckt
## und damit fleckig heller würden.
func _baue_umriss(groesse: Vector2) -> void:
	var hinten: Array = []
	var vorn: Array = []
	_umriss_extra = []
	var b := groesse.x
	var grund_hinten := groesse.y * REIHE_HINTEN.x
	var grund_vorn := groesse.y * REIHE_VORN.x
	var hh := REIHE_HINTEN.y
	var hv := REIHE_VORN.y
	match _raum:
		1:  # Wurzelwald: hinten Tannen und runde Laubbäume, vorn Tannen
			reihe(hinten, b, 44.0, func(i: int, z: float) -> Array:
				return baum(z < 0.75, hh * (0.5 + 0.5 * _zufall(i * 1.7))))
			reihe(vorn, b, 58.0, func(i: int, _z: float) -> Array:
				return baum(true, hv * (0.6 + 0.4 * _zufall(i * 2.3))))
		2:  # Nebelsümpfe: Weiden und Schilf, vorn ein Bohlensteg
			reihe(hinten, b, 90.0, func(_i: int, z: float) -> Array:
				var h := hh * (0.35 + 0.25 * z)
				return ["laub", 0.0, h * 0.6, h])
			reihe(hinten, b, 11.0, func(i: int, _z: float) -> Array:
				return ["schilf", 0.0, 4.0, hh * (0.14 + 0.16 * _zufall(i * 3.1))])
			var steg_y := grund_vorn - hv * 0.34
			_umriss_extra.append(["steg", Rect2(-10.0, steg_y, b + 20.0, 8.0)])
			var pfahl := 40.0
			while pfahl < b:
				_umriss_extra.append(["steg", Rect2(pfahl, steg_y, 7.0,
						groesse.y - steg_y)])
				pfahl += 150.0
			reihe(vorn, b, 7.0, func(i: int, z: float) -> Array:
				var bueschel := 0.5 + 0.5 * sin(float(i) * 0.33)
				return ["schilf", 0.0, 3.5, hv * (0.15 + 0.85 * bueschel * z)])
		3:  # Steinfeste: Mauer mit Zinnen und Türmen, vorn Fels
			hinten.append(["mauer", b * 0.5, b * 0.5 + 20.0, hh * 0.30])
			for x: float in PackedFloat32Array([b * 0.10, b * 0.28, b * 0.80]):
				hinten.append(["turm", x, 30.0, hh * 0.72])
			hinten.append(["dach", b * 0.28, 40.0, hh])
			reihe(vorn, b, 120.0, func(i: int, z: float) -> Array:
				return ["fels", 0.0, 60.0 + 50.0 * z, hv * (0.35 + 0.45 * _zufall(i * 1.9))])
		4:  # Rost und Ranken: Schlote und Sägedächer, vorn dichtes Laub
			hinten.append(["saege", b * 0.5, b * 0.5 + 20.0, hh * 0.34])
			for x: float in PackedFloat32Array([b * 0.13, b * 0.19, b * 0.74, b * 0.88]):
				hinten.append(["schlot", x, 10.0, hh * (0.7 + 0.3 * _zufall(x))])
			reihe(vorn, b, 70.0, func(i: int, z: float) -> Array:
				return ["laub", 0.0, 44.0 + 30.0 * z, hv * (0.45 + 0.4 * _zufall(i * 2.9))])
		5:  # Sand und Neon: Dünen, davor die Dächer der Stadt
			reihe(hinten, b, 260.0, func(_i: int, z: float) -> Array:
				return ["huegel", 0.0, 220.0 + 80.0 * z, hh * (0.24 + 0.2 * z)])
			reihe(vorn, b, 46.0, func(i: int, z: float) -> Array:
				return ["block", 0.0, 20.0 + 12.0 * z, hv * (0.3 + 0.7 * _zufall(i * 4.1))])
		_:  # Portalraum: Hügel mit Bäumen, darauf die fünf Portalringe
			reihe(hinten, b, 300.0, func(_i: int, z: float) -> Array:
				return ["huegel", 0.0, 260.0 + 60.0 * z, hh * (0.20 + 0.10 * z)])
			# Die Ringe stehen auf den Hügeln – erst die Hügel messen, dann
			# kommen die Bäume dazu.
			for n in 5:
				var x := b * (0.2 + 0.15 * float(n))
				var boden := 0.0
				for form in hinten:
					boden = maxf(boden, _formhoehe(form as Array, x))
				var toene: Array = RAUMTOENE[n + 1]
				_umriss_extra.append(["ring", Vector2(x, grund_hinten - boden - 30.0),
						22.0, toene[2]])
			var baeume := func(_i: int, z: float) -> Array:
				return baum(z < 0.4, hh * (0.40 + 0.2 * z))
			reihe(hinten, b, 150.0, baeume, 75.0)
			reihe(vorn, b, 140.0, func(_i: int, z: float) -> Array:
				return ["huegel", 0.0, 120.0 + 60.0 * z, hv * (0.25 + 0.2 * z)])
	_umriss_hinten = zerlege(hinten, b, grund_hinten, groesse.y)
	_umriss_vorn = zerlege(vorn, b, grund_vorn, groesse.y)


## Reiht Formen über die ganze Breite: im Abstand `schritt` (±35 %).
## `erzeuger(i, zufall)` liefert die Form, die Reihe setzt ihre Mitte. Mit
## `mitte_flach` drückt sie sie zur Bildmitte hin flacher (`_huelle`).
##
## Öffentlich und statisch wie `zerlege()`: Die Einstellungen stellen mit
## denselben Formen ihren Waldrand auf (über `preload` dieses Skripts).
static func reihe(formen: Array, breite: float, schritt: float, erzeuger: Callable,
		versatz: float = 0.0, mitte_flach: bool = true) -> void:
	var x := -schritt * 0.5 + versatz
	var i := 0
	while x < breite + schritt:
		var z := _zufall(float(i) * 7.13 + schritt)
		var form: Array = erzeuger.call(i, z)
		form[1] = x
		if mitte_flach:
			form[3] = float(form[3]) * _huelle(x / maxf(breite, 1.0))
		formen.append(form)
		x += schritt * (0.65 + 0.7 * _zufall(float(i) * 3.7 + schritt * 0.1))
		i += 1


## Ein Baum für `reihe()`: schlanke Tanne oder Laubbaum mit runder Krone,
## die Breite passend zur Höhe – zu schmale Kronen sähen aus wie Grabsteine.
static func baum(tanne: bool, hoehe: float) -> Array:
	return ["tanne" if tanne else "laub", 0.0, hoehe * (0.30 if tanne else 0.46), hoehe]


## In der Bildmitte stehen Ladebalken und Tipp – dort bleibt der Umriss
## niedriger, zu den Rändern wächst er. Wie ein Tal, in das man hineinsieht.
static func _huelle(anteil: float) -> float:
	return lerpf(0.6, 1.0, smoothstep(0.12, 0.38, absf(anteil - 0.5)))


## Höhe einer Form an der Stelle x über ihrer Grundlinie (negativ: nichts).
static func _formhoehe(form: Array, x: float) -> float:
	var art := String(form[0])
	var dx := x - float(form[1])
	var w := float(form[2])
	var h := float(form[3])
	var ax := absf(dx)
	match art:
		"tanne":
			# Drei Stufen übereinander, jede ein Dreieck; die obere setzt
			# über der unteren an – das gibt die Kerben im Umriss.
			var y := h * 0.14 if ax < w * 0.09 else -1.0
			for k in 3:
				var wk := w * (1.0 - 0.25 * float(k))
				if ax < wk:
					y = maxf(y, h * (0.10 + 0.25 * float(k)) + h * 0.40 * (1.0 - ax / wk))
			return y
		"laub":
			# Stamm und eine Krone aus Kanten statt eines Kreises – kantig
			# wie die Bäume im Spiel.
			var y := h * 0.45 if ax < w * 0.1 else -1.0
			if ax < w:
				var winkel := acos(clampf(ax / w, 0.0, 1.0))
				var stufe := PI / 6.0
				var a0 := floorf(winkel / stufe) * stufe
				var a1 := minf(a0 + stufe, PI * 0.5)
				var t := clampf((ax / w - cos(a0)) / minf(cos(a1) - cos(a0), -0.0001),
						0.0, 1.0)
				y = maxf(y, h * 0.62 + h * 0.38 * lerpf(sin(a0), sin(a1), t))
			return y
		"schilf":
			return h * (1.0 - ax / w) if ax < w else -1.0
		"fels":
			# Kantiger Brocken mit schiefer Kuppe
			if ax >= w:
				return -1.0
			return h * minf(1.0, (1.0 - ax / w) * 2.2) * (1.0 - 0.18 * dx / w)
		"huegel":
			return h * (0.5 + 0.5 * cos(PI * dx / w)) if ax < w else -1.0
		"mauer":
			# Zinnen im Takt von 26 px
			if ax >= w:
				return -1.0
			return h + (12.0 if fposmod(x, 26.0) < 13.0 else 0.0)
		"turm":
			if ax >= w:
				return -1.0
			return h + (10.0 if fposmod(dx + w, 17.0) < 8.5 else 0.0)
		"dach":
			return h * 0.72 + h * 0.28 * (1.0 - ax / w) if ax < w else -1.0
		"saege":
			if ax >= w:
				return -1.0
			return h + 24.0 * fposmod(x, 64.0) / 64.0
		"schlot":
			return h if ax < w else -1.0
		"block":
			if ax >= w:
				return -1.0
			# Manche Dächer tragen eine Antenne.
			if _zufall(float(form[1])) > 0.7 and absf(dx - w * 0.3) < 1.5:
				return h + 16.0
			return h
	return -1.0


## Stellen, an denen der Umriss einen Knick oder eine Kante hat – dort
## wird zusätzlich gemessen, sonst würden Spitzen gekappt und Kanten schräg.
static func _formkanten(form: Array) -> PackedFloat32Array:
	var art := String(form[0])
	var mx := float(form[1])
	var w := float(form[2])
	var stellen := PackedFloat32Array([mx - w, mx, mx + w])
	match art:
		"tanne":
			for k in 3:
				var wk := w * (1.0 - 0.25 * float(k))
				stellen.append_array(PackedFloat32Array([mx - wk, mx + wk]))
		"laub":
			for k in 7:
				stellen.append(mx + w * cos(PI * float(k) / 6.0))
		"mauer", "saege", "turm":
			var takt := 13.0
			var x := floorf((mx - w) / takt) * takt
			if art == "saege":
				takt = 64.0
				x = floorf((mx - w) / takt) * takt
			elif art == "turm":
				takt = 8.5
				x = mx - w
			while x <= mx + w + 0.01:
				stellen.append_array(PackedFloat32Array([x - 0.01, x + 0.01]))
				x += takt
		"schlot", "block":
			stellen.append_array(PackedFloat32Array([mx - w - 0.01, mx - w + 0.01,
					mx + w - 0.01, mx + w + 0.01]))
			if art == "block":
				var antenne := mx + w * 0.3
				stellen.append_array(PackedFloat32Array([antenne - 1.51, antenne - 1.49,
						antenne + 1.49, antenne + 1.51]))
	return stellen


## Misst den Umriss einer Reihe und gibt ihn als Dreiecksliste zurück:
## je zwei Nachbarstellen ein Streifen von der Kante bis `unten_y`.
## Zeichnen mit `RenderingServer.canvas_item_add_triangle_array` – fertig
## zerlegt, ohne dass Godot das Vieleck jedes Bild neu zerlegt.
static func zerlege(formen: Array, breite: float, grund_y: float,
		unten_y: float) -> PackedVector2Array:
	if formen.is_empty():
		return PackedVector2Array()
	var stellen := PackedFloat32Array()
	var x := -UMRISS_SCHRITT
	while x <= breite + UMRISS_SCHRITT:
		stellen.append(x)
		x += UMRISS_SCHRITT
	for form in formen:
		for k in _formkanten(form as Array):
			if k > -UMRISS_SCHRITT and k < breite + UMRISS_SCHRITT:
				stellen.append(k)
	stellen.sort()
	# Jede Form zählt nur über ihrer eigenen Breite (mitte ± w, außerhalb
	# liefert `_formhoehe` -1). Alle Formen an allen Stellen zu fragen
	# kostete im Schilf der Nebelsümpfe über 200 000 Aufrufe und eine
	# Viertelsekunde vor dem ersten Bild des Ladeschirms.
	var hoehen := PackedFloat64Array()
	hoehen.resize(stellen.size())
	hoehen.fill(0.0)
	for form in formen:
		var f := form as Array
		var bis := float(f[1]) + float(f[2])
		var i := stellen.bsearch(float(f[1]) - float(f[2]))
		while i < stellen.size() and stellen[i] <= bis:
			hoehen[i] = maxf(hoehen[i], _formhoehe(f, stellen[i]))
			i += 1
	var kante := PackedVector2Array()
	for i in stellen.size():
		kante.append(Vector2(stellen[i], grund_y - hoehen[i]))
	var dreiecke := PackedVector2Array()
	for i in kante.size() - 1:
		var a := kante[i]
		var c := kante[i + 1]
		if c.x - a.x < 0.001:
			# Senkrechte Kante: zwei Stellen am selben Ort, kein Streifen.
			continue
		var a0 := Vector2(a.x, unten_y)
		var c0 := Vector2(c.x, unten_y)
		dreiecke.append_array(PackedVector2Array([a, c, c0, a, c0, a0]))
	return dreiecke
