extends Control
class_name MenueEintrag
## Ein Eintrag im Startmenü – vollständig gezeichnet, ohne Bilddateien.
##
## Bedienbar mit Tastatur/Gamepad (der Startbildschirm setzt die Auswahl)
## und mit Maus/Finger (Antippen löst aus, Überfahren wählt aus).
##
## Aussehen aus `UiStil`: Knopffläche, Schrift mit Kontur, Gold für die
## Auswahl. Gewählt und abgewählt wird weich (`_anteil` läuft von 0 nach 1
## und zurück), damit der Blick der Auswahl folgen kann, statt dass zwei
## Einträge gleichzeitig hart umspringen.
##
## Wertzeilen (Einstellungen): Mit `art` zeigt der Eintrag rechts seinen
## Wert – als Wahl mit Pfeilen (‹ Wert ›), als Schalter oder als Stufenbalken.
## Die Beschriftung bleibt dabei nur der Name ("Lautstärke"), der Wert
## steht getrennt; so springt beim Umschalten nicht die ganze Zeile.
##
## Klänge spielt der Eintrag nicht selbst – das Menü, dem er gehört, weiß,
## ob eine Taste etwas bewirkt hat. Dafür gibt es `klang_wahl()` und
## `klang_ok()`, damit alle Menüs gleich klingen.
##
## Verborgen ruht der Eintrag ganz (kein `_process`), auch wenn er gewählt
## ist – die Statustafel lässt ihren Eintrag gewählt stehen, während sie
## zu ist. Sichtbar geworden läuft er weiter, wo er war.

signal angetippt
signal ueberfahren

## Wie der Wert rechts gezeigt wird.
##   SCHLICHT  kein Wert; gewählt zeigt ein Pfeil nach rechts
##   WAHL      `wert` als Text, gewählt mit ‹ › (links/rechts schaltet)
##   SCHALTER  An/Aus-Schalter nach `eingeschaltet`
##   STUFEN    `stufe` von `stufen` Balken, dazu `wert` als Text
enum Art { SCHLICHT, WAHL, SCHALTER, STUFEN }

## So schnell folgt die Auswahl (Anteile je Sekunde): 0,14 s für den Wechsel.
const TEMPO_AUSWAHL := 7.0
## Rand rechts, an dem Pfeil und Wert enden.
const RAND_RECHTS := 22.0
## Höchstens so viel der Breite nimmt ein Wert (‹ Wert ›) ein. Figurennamen
## kommen ungekürzt aus dem Dateinamen; ohne Grenze liefen lange über die
## Beschriftung.
const WERT_ANTEIL := 0.58

var beschriftung := "":
	set(neu):
		beschriftung = neu
		queue_redraw()
## Zweite, kleinere Zeile – bleibt leer, wenn nichts dransteht.
var unterzeile := "":
	set(neu):
		unterzeile = neu
		queue_redraw()
var schriftgroesse := 27:
	set(neu):
		schriftgroesse = neu
		queue_redraw()
## Gedämpft gezeichnet: Eintrag ist sichtbar, aber ohne Inhalt (leerer Slot).
var gedaempft := false:
	set(neu):
		gedaempft = neu
		queue_redraw()
var gewaehlt := false

var art := Art.SCHLICHT:
	set(neu):
		art = neu
		queue_redraw()
## Text des Werts (WAHL, STUFEN).
var wert := "":
	set(neu):
		wert = neu
		queue_redraw()
## Stellung des Schalters (SCHALTER). Der Knopf gleitet hinüber.
var eingeschaltet := false:
	set(neu):
		if eingeschaltet == neu:
			return
		eingeschaltet = neu
		_wecken()
## Gefüllte Balken (STUFEN), von `stufen`.
var stufe := 0:
	set(neu):
		stufe = neu
		queue_redraw()
var stufen := 10

var _anteil := 0.0        ## 0 = Ruhe, 1 = gewählt; folgt `gewaehlt`
var _puls := 0.0          ## läuft nach dem Auswählen kurz aus (Schein)
var _druck := 0.0         ## kurzes Eindrücken beim Auslösen
var _schub := 0.0         ## Wertwechsel: Vorzeichen = Richtung, klingt ab
var _schalter := 0.0      ## Knopfstellung, folgt `eingeschaltet`
var _zeit := 0.0
## Eigene Kopie der Knopffläche: Farbe und Schein werden pro Bild
## überblendet, die geteilte Fläche aus UiStil darf das nicht.
var _flaeche: StyleBoxFlat
var _schalterflaeche: StyleBoxFlat

## Wartet ein Wahlklang auf das Ende des Bildes? Ein Tipp wählt und
## bestätigt im selben Augenblick – dann soll nur die Bestätigung klingen,
## nicht beide übereinander. `klang_ok()` verwirft den wartenden Wahlklang.
static var _wahl_wartet := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: ueberfahren.emit())
	draw.connect(_zeichne)
	_flaeche = UiStil.eigene(&"knopf")
	_schalterflaeche = UiStil.eigene(&"schalter")
	# Knapp unter voller Rundung (Spur 24 px hoch): Bei genau halber Höhe
	# zeigt StyleBoxFlat an den Enden einen hellen Nahtpunkt.
	_schalterflaeche.set_corner_radius_all(11)
	_schalter = 1.0 if eingeschaltet else 0.0
	visibility_changed.connect(_auf_sichtbarkeit)
	set_process(_unruhig() and is_visible_in_tree())


## Wählt den Eintrag an oder ab. `sofort` springt ohne Überblenden in den
## neuen Zustand – für Einträge, die gerade erst entstehen.
func setze_auswahl(an: bool, sofort: bool = false) -> void:
	if sofort:
		_anteil = 1.0 if an else 0.0
	if gewaehlt == an:
		queue_redraw()
		return
	gewaehlt = an
	if an and not sofort:
		_puls = 1.0
	_wecken()


## Kurzes Eindrücken beim Auslösen. Verzögert nichts – die Tat läuft
## sofort, das Eindrücken ist nur Rückmeldung.
func druecken() -> void:
	_druck = 1.0
	_wecken()


## Der Wert hat sich in `richtung` geändert (-1 links, +1 rechts): Der
## Pfeil auf dieser Seite schnellt kurz heraus.
func wert_geschoben(richtung: int) -> void:
	_schub = signf(float(richtung))
	_wecken()


## Klang beim Wechseln der Auswahl. Eigene Menüklänge, sobald `Klang`
## sie kennt; bis dahin ein hoch gestimmter, leiser Sprungton.
##
## Gespielt wird erst am Ende des Bildes, und mehrere Wahlen im selben Bild
## klingen einmal (siehe `_wahl_wartet`).
static func klang_wahl() -> void:
	if _wahl_wartet:
		return
	_wahl_wartet = true
	Callable(MenueEintrag, &"_wahl_nachholen").call_deferred()


static func _wahl_nachholen() -> void:
	if not _wahl_wartet:
		return
	_wahl_wartet = false
	if Klang.namen().has("menue_wahl"):
		Klang.spiele("menue_wahl")
	else:
		Klang.spiele("sprung", 1.7, 0.22)


## Klang beim Bestätigen: die zwei Glöckchen der Frucht, etwas gedämpft.
static func klang_ok() -> void:
	_wahl_wartet = false
	if Klang.namen().has("menue_ok"):
		Klang.spiele("menue_ok")
	else:
		Klang.spiele("frucht", 1.0, 0.5)


func _wecken() -> void:
	set_process(true)
	queue_redraw()


func _auf_sichtbarkeit() -> void:
	if is_visible_in_tree() and _unruhig():
		_wecken()


func _unruhig() -> bool:
	return gewaehlt or _anteil > 0.0 or _puls > 0.0 or _druck > 0.0 \
			or _schub != 0.0 or _schalter != (1.0 if eingeschaltet else 0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		# Verborgen gibt es nichts zu zeigen; `_auf_sichtbarkeit` weckt wieder.
		set_process(false)
		return
	_anteil = move_toward(_anteil, 1.0 if gewaehlt else 0.0, delta * TEMPO_AUSWAHL)
	_puls = maxf(_puls - delta * 3.0, 0.0)
	_druck = maxf(_druck - delta * 6.0, 0.0)
	_schub = move_toward(_schub, 0.0, delta * 5.0)
	_schalter = move_toward(_schalter, 1.0 if eingeschaltet else 0.0, delta * 8.0)
	_zeit += delta
	queue_redraw()
	# Gewählt läuft er weiter (der Pfeil wippt); ruhig und abgewählt nicht.
	if not _unruhig():
		set_process(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var maus := event as InputEventMouseButton
		if maus.pressed and maus.button_index == MOUSE_BUTTON_LEFT:
			ueberfahren.emit()
			druecken()
			angetippt.emit()
			accept_event()


# ------------------------------------------------------------- Zeichnen

func _zeichne() -> void:
	if _flaeche == null:
		return
	var feld := Rect2(Vector2.ZERO, size)
	# Weich hinein und hinaus: Die Mitte des Wechsels geht schnell, die
	# Enden setzen sanft auf.
	var a := ease(_anteil, -1.8)

	if _druck > 0.0:
		var s := 1.0 - 0.035 * _druck
		draw_set_transform(size * 0.5 * (1.0 - s), 0.0, Vector2(s, s))

	var grund := Farben.UI_KNOPF.lerp(Farben.UI_KNOPF_GEWAEHLT, a)
	_flaeche.bg_color = grund.lerp(Color(1, 1, 1, grund.a), 0.12 * _druck)
	_flaeche.border_color = Color(1, 1, 1, 0.10).lerp(Farben.UI_GOLD, a)
	_flaeche.set_border_width_all(1 if a < 0.5 else 2)
	# Der Schein ist der Schatten in Gold; beim Anwählen blüht er kurz auf.
	_flaeche.shadow_color = Color(Farben.UI_GOLD, 0.18 * a + 0.14 * _puls * _puls)
	_flaeche.shadow_size = roundi(10.0 * a + 8.0 * _puls * _puls)
	_flaeche.draw(get_canvas_item(), feld)

	# Goldbalken links: wächst aus der Mitte, statt aufzuploppen.
	if a > 0.01:
		var hoehe := (feld.size.y - 16.0) * a
		draw_rect(Rect2(Vector2(0.0, (feld.size.y - hoehe) * 0.5),
				Vector2(4.0, hoehe)), Farben.UI_GOLD)

	var farbe := Farben.UI_TEXT_RUHE.lerp(Farben.UI_GOLD_HELL, a)
	if gedaempft:
		farbe = Color(farbe, 0.45)
	var einzug := 20.0 + 8.0 * a
	var rechts := _zeichne_wert(feld, a)
	var platz := maxf(rechts - einzug - 12.0, 40.0)

	# Mit Unterzeile rückt die Hauptzeile nach oben, sonst steht sie mittig.
	var grundlinie := feld.size.y * 0.5 + schriftgroesse * 0.36
	if not unterzeile.is_empty():
		grundlinie = feld.size.y * 0.5 - 2.0
	var zs := UiStil.schrift(&"fett")
	var groesse := UiStil.passend(zs, beschriftung, schriftgroesse, platz)
	UiStil.text(self, Vector2(einzug, grundlinie), beschriftung, groesse, farbe,
			&"fett", 3)
	if not unterzeile.is_empty():
		var klein := maxi(schriftgroesse - 9, 12)
		# Lange Zeilen (Raumname, Früchte, Relikte) werden kleiner statt
		# über den Rand zu laufen.
		klein = UiStil.passend(UiStil.schrift(), unterzeile, klein, platz, 11)
		UiStil.text(self, Vector2(einzug, grundlinie + klein + 6.0), unterzeile,
				klein, Color(farbe, farbe.a * 0.72), &"text", 3)

	if _druck > 0.0:
		draw_set_transform_matrix(Transform2D.IDENTITY)


## Zeichnet den Wert rechts. Rückgabe: linke Kante des Wertbereichs, bis
## zu der die Beschriftung reichen darf.
func _zeichne_wert(feld: Rect2, a: float) -> float:
	var mitte_y := feld.size.y * 0.5
	var rechts := feld.size.x - RAND_RECHTS
	match art:
		Art.SCHLICHT:
			if a > 0.01:
				var x := feld.size.x - 26.0 - 6.0 * (1.0 - a) + sin(_zeit * 5.0) * 2.0 * a
				_pfeil(Vector2(x, mitte_y), 8.0, 1.0, Color(Farben.UI_GOLD, a))
			return feld.size.x - 34.0
		Art.WAHL:
			return _zeichne_wahl(rechts, mitte_y, a)
		Art.SCHALTER:
			return _zeichne_schalter(rechts, mitte_y, a)
		Art.STUFEN:
			return _zeichne_stufen(rechts, mitte_y, a)
	return rechts


## ‹ Wert ›: Die Pfeile erscheinen nur, wenn der Eintrag gewählt ist –
## dann schalten links/rechts den Wert.
func _zeichne_wahl(rechts: float, mitte_y: float, a: float) -> float:
	var zs := UiStil.schrift(&"fett")
	# Lange Werte erst etwas kleiner, dann hinten gekürzt – nie über die
	# Beschriftung. Der Platz ist ohne die Pfeile gerechnet, damit der Text
	# beim Anwählen nicht umbricht oder springt.
	var platz := size.x * WERT_ANTEIL
	var voll := maxi(schriftgroesse - 3, 14)
	var groesse := UiStil.passend(zs, wert, voll, platz, mini(16, voll))
	var anzeige := UiStil.kuerzen(zs, wert, groesse, platz)
	var breite := zs.get_string_size(anzeige, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	var pfeilraum := 16.0 * a
	var ende := rechts - pfeilraum
	var farbe := Farben.UI_TEXT_RUHE.lerp(Farben.UI_GOLD_HELL, a)
	UiStil.text(self, Vector2(ende, mitte_y + groesse * 0.36), anzeige, groesse,
			farbe, &"fett", 3, HORIZONTAL_ALIGNMENT_RIGHT)
	if a > 0.01:
		var gold := Color(Farben.UI_GOLD, a)
		var links_x := ende - breite - 12.0 - maxf(-_schub, 0.0) * 5.0
		var rechts_x := ende + 10.0 + maxf(_schub, 0.0) * 5.0
		_pfeil(Vector2(rechts_x, mitte_y), 6.5, 1.0, gold)
		_pfeil(Vector2(links_x, mitte_y), 6.5, -1.0, gold)
	return ende - breite - 22.0


## Schalter als Kapsel: Gold, wenn an; der Knopf gleitet.
func _zeichne_schalter(rechts: float, mitte_y: float, _a: float) -> float:
	var s := ease(_schalter, -2.0)
	var spur := Rect2(rechts - 46.0, mitte_y - 12.0, 46.0, 24.0)
	_schalterflaeche.bg_color = Color(1, 1, 1, 0.14).lerp(Color(Farben.UI_GOLD, 0.92), s)
	_schalterflaeche.border_color = Color(1, 1, 1, 0.22).lerp(
			Color(Farben.UI_GOLD_HELL, 0.9), s)
	_schalterflaeche.draw(get_canvas_item(), spur)
	var knopf := Vector2(lerpf(spur.position.x + 12.0, spur.end.x - 12.0, s), mitte_y)
	draw_circle(knopf + Vector2(0.0, 1.5), 9.5, Color(0, 0, 0, 0.30), true, -1.0, true)
	draw_circle(knopf, 9.0, Farben.UI_HELL, true, -1.0, true)
	draw_arc(knopf, 9.0, 0.0, TAU, 32, Color(Farben.UI_KONTUR, 0.55), 1.2, true)
	return spur.position.x - 14.0


## Stufenbalken wie eine Lautstärkeanzeige: nach rechts höher werdend.
func _zeichne_stufen(rechts: float, mitte_y: float, a: float) -> float:
	var breite := 6.0
	var luecke := 3.0
	var gesamt := stufen * breite + (stufen - 1) * luecke
	var links := rechts - gesamt
	for i in stufen:
		var h := lerpf(8.0, 20.0, float(i) / maxf(float(stufen - 1), 1.0))
		var feld := Rect2(links + i * (breite + luecke), mitte_y + 10.0 - h, breite, h)
		var voll := i < stufe
		var farbe := Farben.UI_GOLD if voll else Color(1, 1, 1, 0.16)
		if voll:
			farbe = farbe.lerp(Farben.UI_GOLD_HELL, 0.35 * a)
		draw_rect(feld, farbe)
	var groesse := maxi(schriftgroesse - 7, 13)
	var farbe_text := Farben.UI_TEXT_RUHE.lerp(Farben.UI_GOLD_HELL, a)
	UiStil.text(self, Vector2(links - 12.0, mitte_y + groesse * 0.36), wert, groesse,
			farbe_text, &"zahl", 3, HORIZONTAL_ALIGNMENT_RIGHT)
	return links - 12.0 - UiStil.textbreite(wert, groesse, &"zahl") - 14.0


## Kleines Dreieck als Zeiger; `seite` 1 zeigt nach rechts, -1 nach links.
func _pfeil(mitte: Vector2, r: float, seite: float, farbe: Color) -> void:
	if farbe.a <= 0.0:
		return
	draw_colored_polygon(PackedVector2Array([
		mitte + Vector2(-r * 0.5 * seite, -r),
		mitte + Vector2(r * 0.7 * seite, 0.0),
		mitte + Vector2(-r * 0.5 * seite, r),
	]), farbe)
