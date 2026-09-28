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
## aufsteigende Flusen, Vignette. Darauf Kicker ("LEVEL 01 · WURZELWALD"),
## Titel, was gerade gebaut wird, hüpfende Früchte, ein gerundeter
## Ladebalken und ein Tipp als Kapsel.
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
	[Color(0.07, 0.10, 0.10), Color(0.02, 0.035, 0.035), Color(1.0, 0.82, 0.50)],
	[Color(0.08, 0.14, 0.09), Color(0.02, 0.04, 0.03), Color(0.95, 0.85, 0.45)],
	[Color(0.07, 0.11, 0.11), Color(0.02, 0.04, 0.045), Color(0.55, 0.85, 0.80)],
	[Color(0.12, 0.10, 0.08), Color(0.035, 0.03, 0.025), Color(1.0, 0.78, 0.52)],
	[Color(0.13, 0.08, 0.05), Color(0.04, 0.025, 0.02), Color(1.0, 0.58, 0.32)],
	[Color(0.09, 0.06, 0.13), Color(0.03, 0.02, 0.045), Color(0.82, 0.55, 1.0)],
]

## Aufsteigende Flusen im Hintergrund.
const FLUSEN := 18

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
	_tween_stoppen()
	_flaeche.visible = true
	_flaeche.queue_redraw()
	if dauer <= 0.0 or _flaeche.modulate.a >= 0.999:
		_flaeche.modulate.a = 1.0
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
	_tween_stoppen()
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


func _tween_stoppen() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _blendet_ein:
		# Wer auf das Einblenden wartet, soll nicht ewig warten.
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
## Levelnamen – sofern der Spielfluss Namen kennt; sonst steht "Level 01"
## als Titel und darüber nur der Raum.
func _kopf_setzen(titel: String) -> void:
	_titel = titel
	_kicker = ""
	var nummer := Spielfluss.aktuelles_level
	if nummer < 1:
		_kicker = "%d VON %d LEVELN FREIGESCHALTET" % [
				mini(Spielfluss.freigeschaltet, Spielfluss.LEVEL_GESAMT),
				Spielfluss.LEVEL_GESAMT]
		return
	var raum := Spielfluss.raum_von_level(nummer)
	var namen: Array = Spielfluss.RAUM_NAMEN
	var raumname := String(namen[clampi(raum - 1, 0, namen.size() - 1)]).to_upper()
	var nur_nummer := "Level %02d" % nummer
	if titel == nur_nummer:
		var name := _levelname(nummer)
		if not name.is_empty():
			_titel = name
	if _titel == nur_nummer:
		_kicker = "RAUM %d · %s" % [raum, raumname]
	else:
		_kicker = "LEVEL %02d · %s" % [nummer, raumname]


## Name eines Levels, falls der Spielfluss welche führt (`level_name`).
## Über `has_method`, damit der Ladeschirm auch ohne sie auskommt.
func _levelname(nummer: int) -> String:
	if not Spielfluss.has_method(&"level_name"):
		return ""
	return String(Spielfluss.call(&"level_name", nummer))


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
	var hof := UiStil.radialverlauf(Color(schein, 0.16), Color(schein, 0.0))
	_flaeche.draw_texture_rect(hof, Rect2(mitte - Vector2(520, 330),
			Vector2(1040, 560)), false)
	_zeichne_flusen(groesse, schein)
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
			&"zahl", 3, HORIZONTAL_ALIGNMENT_CENTER)

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
		var deckung := 0.10 + 0.18 * _zufall(saat + 5.5)
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
	UiStil.zeichne(_flaeche, chip, &"chip")
	var marke := Rect2(chip.position + Vector2(11.0, 11.0), Vector2(marke_breite, 24.0))
	# Knapp unter voller Rundung – bei genau halber Höhe zeigt StyleBoxFlat
	# an den Enden einen hellen Nahtpunkt.
	var rund := func(s: StyleBoxFlat) -> void: s.set_corner_radius_all(11)
	UiStil.variante(&"pille", &"tippmarke", rund).draw(_flaeche.get_canvas_item(), marke)
	UiStil.text(_flaeche, Vector2(marke.get_center().x, marke.position.y + 17.0), "TIPP",
			12, Farben.UI_KONTUR, &"sperr", 0, HORIZONTAL_ALIGNMENT_CENTER)
	UiStil.text(_flaeche, Vector2(marke.end.x + 14.0, chip.position.y + 29.0), _tipp,
			text_groesse, Color(0.86, 0.90, 0.84), &"text", 3)
