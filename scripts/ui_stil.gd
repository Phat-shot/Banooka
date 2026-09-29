extends RefCounted
class_name UiStil
## Gemeinsamer Stil aller Menüs und Anzeigen: Schriften, Flächen, Theme,
## Zeichenhelfer, Bewegungen und eine Vollbild-Blende für Übergänge.
##
## Alles wird im Code gebaut, wie bei `Materialbibliothek`: keine .tres,
## keine Schriftdateien. Die Schriften sind Abwandlungen (FontVariation)
## der eingebauten Godot-Schrift, die Flächen sind StyleBoxFlat.
##
## Warum es das gibt: Vorher hatte jede UI-Datei ihre eigenen Helfer –
## vier Sätze `_runde_flaeche`/`_rahmen`, sechs `_text`-Funktionen –, und
## jeder Aufruf baute pro Bild eine neue StyleBoxFlat. Dasselbe Gold stand
## fünfmal im Code. Lesbar war Text nur über einen 1,5-px-Schatten, der
## über hellem Himmel und Gras verschwand; hier bekommt Schrift eine echte
## Kontur in warmem Dunkelbraun (`Farben.UI_KONTUR`).
##
## REGEL (wie Materialbibliothek): Alles, was hier herauskommt – Schriften,
## Flächen, Texturen, Theme –, ist zwischengespeichert und wird geteilt.
## NIE verändern. Abwandlungen:
##   getoent(art, grund)            andere Grundfarbe   – geteilt, einmal gebaut
##   gerahmt(art, rahmen)           andere Rahmenfarbe  – geteilt, einmal gebaut
##   variante(art, name, anpassen)  beliebig            – geteilt, einmal gebaut
##   eigene(art)                    Kopie für den Aufrufer, darf verändert
##                                  werden (für animierte Werte). Einmal holen
##                                  und in einer Variable halten, nicht pro Bild.
## Die geteilten Abwandlungen nur für eine kleine, feste Menge von Farben
## benutzen – für jede neue Farbe entsteht ein neuer Eintrag im Speicher.
##
## THEME UND CANVASLAYER: Ein CanvasLayer unterbricht die Vererbung des
## Themes (gesucht wird nur über Control- und Window-Eltern). Deshalb
## `theme = UiStil.thema()` an JEDER UI-Wurzel selbst setzen, nicht einmal
## an der Wurzel des Baums. Wer das Theme gesetzt hat, bekommt über
## `get_theme_default_font()` automatisch `schrift(&"text")`.
##
## ÜBERSICHT
##
##   Schriften   schrift(art) -> Font
##       &"text"     Fließtext; kaum fetter als die Grundschrift (Theme-Vorgabe)
##       &"fett"     Überschriften, Knöpfe, Zeilen, die sich abheben sollen
##       &"zahl"     Zähler und Uhren; alle Ziffern gleich breit
##       &"titel"    Seiten-, Level- und Tafeltitel ab etwa 34 px
##       &"logo"     nur der Schriftzug BANOOKA: weit gesperrt, wie bisher
##                   `_titelschrift` im Startbildschirm
##       &"sperr"    gesperrte Kicker-Zeilen ("LEVEL 01 · WURZELWALD"),
##                   wie bisher `_sperrschrift`
##       &"schwung"  schräg und fett, für Banner wie "GESCHAFFT!"
##
##   Flächen     flaeche(art) -> StyleBoxFlat,  zeichne(auf, feld, art)
##       &"tafel"           große Tafel: Statustafel, Auswertung, Overlays
##       &"kachel"          kleine Tafel mit mäßiger Rundung (Zeitanzeige)
##       &"chip"            HUD-Kapsel, lässt die Welt durchscheinen; Toasts
##       &"knopf"           Menüeintrag in Ruhe
##       &"knopf_gewaehlt"  Menüeintrag gewählt: Goldrand mit Schein
##       &"balken"          Rinne eines Fortschrittsbalkens
##       &"balken_voll"     Füllung (Frucht-Orange; `getoent` für andere)
##       &"pille"           voll gerundete Marke in Gold ("TIPP", Schubkapseln)
##       &"band"            schräges Band hinter Bannerschrift
##       &"schalter"        Rinne eines An/Aus-Schalters
##       &"mulde"           dunkle Vertiefung (Zahlenfeld, Tastenhinweis);
##                          runde Fassungen zeichnet `fassung()`
##     Kapselformen (chip, pille, schalter) nur BREITER ALS HOCH benutzen:
##     Ist ein Feld mit voller Rundung quadratisch oder hochkant, zeigt
##     Godots StyleBoxFlat (Kantenglättung + Rahmen) eine senkrechte Naht
##     durch die Mitte. Kreise immer mit `fassung()` oder draw_circle.
##     Auch breiter als hoch bleibt ein Rest: Ist der Eckradius GENAU die
##     halbe Höhe (volle Rundung), kann an den Kapselenden ein einzelnes
##     helles Nahtpixel stehen. Gesehen bei &"pille" und &"schalter" (Radius
##     64, also immer voll gerundet) und bei &"chip" unter 46 px Höhe –
##     &"chip" deshalb in der vorgesehenen Höhe von 46 px benutzen; wer eine
##     Kapsel ohne Naht braucht, nimmt einen Radius von halber Höhe − 1.
##
##   Text        text(), absatz(), textbreite(), passend(), kuerzen(),
##               konturstaerke()
##   Theme       thema()
##   Zeichnen    verlauf(), vignette(), radialverlauf(), balken(), fassung(),
##               raute(), edelstein(), frucht(), herz(), kiste()
##   Bewegung    pop(), einblenden(), ausblenden(), einschweben(),
##               ausschweben(), zaehle_hoch(), vollenden()   – Tweens
##               annaehern(), federkurve()                   – für _process
##   Blende      UiStil.Blende: Vollbild-Übergang (Abblenden, Blitz, Iris)
##
## Die Zeichenhelfer gehören wie jedes `draw_*` in einen draw-Aufruf
## (`_draw` oder das `draw`-Signal) des Knotens `auf`.
##
## Renderer: `gl_compatibility`. Die Iris-Blende ist ein einfacher
## canvas_item-Shader ohne Bildschirmtextur und läuft auch auf WebGL2.


# ------------------------------------------------------------ Maße

## Schriftgrößen-Leiter. Nicht Pflicht, aber wer sie benutzt, passt zum Rest.
const GROESSE_FUSS := 14     ## Fußzeilen, Tastenhinweise
const GROESSE_TEXT := 18     ## Fließtext (Vorgabe im Theme)
const GROESSE_KNOPF := 24    ## Menüeinträge
const GROESSE_KOPF := 34     ## Tafelüberschriften
const GROESSE_TITEL := 52    ## Level- und Seitentitel

## Deckung des weichen Schlagschattens unter der Textkontur. Die Kontur
## allein trennt Schrift vom Grund; der Schatten hebt sie davon ab.
const SCHATTEN := 0.30

## Schriftarten: [Fettung, Sperrung in px, Schräge].
##
## Fettung verschmiert kleine Schrift (≤ 13 px) schnell – deshalb hat
## &"text" nur 0.15. &"logo" entspricht exakt der alten `_titelschrift`
## (0.55, 12 px), damit der Schriftzug beim Umstellen nicht springt. Die
## Sperrung ist in Pixeln, nicht relativ zur Größe: Was bei 104 px luftig
## wirkt, reißt ein halb so großes Wort auseinander. Deshalb hat &"titel"
## nur 3 px.
const _SCHRIFTARTEN := {
	&"text": [0.15, 0, 0.0],
	&"fett": [0.45, 0, 0.0],
	&"zahl": [0.55, 1, 0.0],
	&"titel": [0.6, 3, 0.0],
	&"logo": [0.55, 12, 0.0],
	&"sperr": [0.0, 3, 0.0],
	&"schwung": [0.55, 1, 0.2],
}

const _IRIS_CODE := """shader_type canvas_item;
// Kreisblende: deckt alles außerhalb von `radius` um `mitte` ab.
// Maße in Pixeln des Blendenrechtecks; `groesse` ist dessen Größe.
uniform vec2 groesse = vec2(1280.0, 720.0);
uniform vec2 mitte = vec2(640.0, 360.0);
uniform float radius = 2000.0;
uniform float weich = 2.5;

void fragment() {
	float d = length(UV * groesse - mitte);
	COLOR.a *= smoothstep(radius - weich, radius, d);
}
"""

static var _schriften: Dictionary[StringName, Font] = {}
static var _flaechen: Dictionary[StringName, StyleBoxFlat] = {}
static var _texturen: Dictionary[StringName, Texture2D] = {}
static var _thema: Theme = null
static var _iris_shader: Shader = null
static var _herzform := PackedVector2Array()
## Punkte der Herzkurve. Die Spitze unten liegt bei t = π, also beim
## mittleren Punkt (HERZ_PUNKTE / 2).
const HERZ_PUNKTE := 40
const HERZ_SPITZE := 20


# ------------------------------------------------------------ Schriften

## Schrift einer Art (siehe Übersicht oben). Unbekannte Arten geben
## &"text" zurück und warnen.
static func schrift(art: StringName = &"text") -> Font:
	if _schriften.has(art):
		return _schriften[art]
	if not _SCHRIFTARTEN.has(art):
		push_warning("UiStil: unbekannte Schriftart '%s'" % art)
		return schrift(&"text")
	var werte: Array = _SCHRIFTARTEN[art]
	var v := FontVariation.new()
	v.base_font = _grundschrift()
	v.variation_embolden = float(werte[0])
	v.spacing_glyph = int(werte[1])
	var schraege := float(werte[2])
	if schraege != 0.0:
		# Die Matrix wirkt auf die Glyphenumrisse, dort zeigt y nach OBEN:
		# x' = x + schraege * y neigt die Oberlängen nach rechts.
		v.variation_transform = Transform2D(Vector2(1.0, schraege),
				Vector2(0.0, 1.0), Vector2.ZERO)
	_schriften[art] = v
	return v


## Die eine Stelle, an der die Grundschrift gewählt wird. Soll später eine
## eigene Titelschrift dazukommen, wird sie hier je Art eingesetzt – alle
## Aufrufer bleiben unverändert.
static func _grundschrift() -> Font:
	return ThemeDB.fallback_font


# ------------------------------------------------------------ Flächen

## Geteilte Fläche einer Art (siehe Übersicht). NIE verändern.
static func flaeche(art: StringName) -> StyleBoxFlat:
	if _flaechen.has(art):
		return _flaechen[art]
	var neu := _baue_flaeche(art)
	_flaechen[art] = neu
	return neu


## Zeichnet eine geteilte Fläche. Für Abwandlungen direkt
## `UiStil.getoent(...).draw(auf.get_canvas_item(), feld)` aufrufen.
static func zeichne(auf: CanvasItem, feld: Rect2, art: StringName) -> void:
	flaeche(art).draw(auf.get_canvas_item(), feld)


## Geteilte Abwandlung mit anderer Grundfarbe. NIE verändern.
static func getoent(art: StringName, grund: Color) -> StyleBoxFlat:
	var schluessel := StringName("%s|g%s" % [art, grund.to_html()])
	if not _flaechen.has(schluessel):
		var kopie := eigene(art)
		kopie.bg_color = grund
		_flaechen[schluessel] = kopie
	return _flaechen[schluessel]


## Geteilte Abwandlung mit anderer Rahmenfarbe. NIE verändern.
## Hat die Art keinen Rahmen, bekommt sie einen von 2 px.
static func gerahmt(art: StringName, rahmen: Color) -> StyleBoxFlat:
	var schluessel := StringName("%s|r%s" % [art, rahmen.to_html()])
	if not _flaechen.has(schluessel):
		var kopie := eigene(art)
		kopie.border_color = rahmen
		if kopie.get_border_width_min() <= 0:
			kopie.set_border_width_all(2)
		_flaechen[schluessel] = kopie
	return _flaechen[schluessel]


## Geteilte Abwandlung unter eigenem Namen. `anpassen` bekommt beim ersten
## Aufruf eine Kopie (StyleBoxFlat) und ändert sie; danach kommt immer
## dieselbe Fläche zurück. NIE verändern.
##
##   var gruen := func(s: StyleBoxFlat) -> void:
##       s.border_color = Farben.KISTE_LEBEN
##       s.shadow_color = Color(Farben.KISTE_LEBEN, 0.25)
##   UiStil.variante(&"chip", &"kisten_voll", gruen).draw(...)
static func variante(art: StringName, bezeichnung: StringName,
		anpassen: Callable) -> StyleBoxFlat:
	var schluessel := StringName("%s|v%s" % [art, bezeichnung])
	if not _flaechen.has(schluessel):
		var kopie := eigene(art)
		anpassen.call(kopie)
		_flaechen[schluessel] = kopie
	return _flaechen[schluessel]


## Eigene Kopie einer Fläche – gehört dem Aufrufer und darf verändert
## werden, etwa um Farben pro Bild zu überblenden. Einmal holen und halten.
static func eigene(art: StringName) -> StyleBoxFlat:
	return flaeche(art).duplicate() as StyleBoxFlat


static func _baue_flaeche(art: StringName) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.anti_aliasing = true
	s.corner_detail = 10
	match art:
		&"tafel":
			s.bg_color = Farben.UI_GRUND
			s.set_corner_radius_all(16)
			s.set_border_width_all(2)
			s.border_color = Color(Farben.UI_GOLD, 0.45)
			s.shadow_color = Color(0, 0, 0, 0.45)
			s.shadow_size = 18
			s.shadow_offset = Vector2(0, 6)
			_innenabstand(s, 28.0, 22.0)
		&"kachel":
			s.bg_color = Farben.UI_GRUND_LEICHT
			s.set_corner_radius_all(14)
			s.set_border_width_all(2)
			s.border_color = Color(1, 1, 1, 0.14)
			s.shadow_color = Color(0, 0, 0, 0.30)
			s.shadow_size = 8
			s.shadow_offset = Vector2(0, 3)
			_innenabstand(s, 14.0, 8.0)
		&"chip":
			# Kapselform bei der vorgesehenen Chiphöhe von 46 px; bei
			# niedrigeren Chips kürzt StyleBoxFlat die Rundung selbst.
			s.bg_color = Farben.UI_GRUND_LEICHT
			s.set_corner_radius_all(22)
			s.set_border_width_all(2)
			s.border_color = Color(1, 1, 1, 0.14)
			s.shadow_color = Color(0, 0, 0, 0.35)
			s.shadow_size = 8
			s.shadow_offset = Vector2(0, 3)
			_innenabstand(s, 16.0, 8.0)
		&"knopf":
			s.bg_color = Farben.UI_KNOPF
			s.set_corner_radius_all(10)
			s.set_border_width_all(1)
			s.border_color = Color(1, 1, 1, 0.10)
			_innenabstand(s, 20.0, 10.0)
		&"knopf_gewaehlt":
			# Der Schein ist der Schatten in Gold – ein Zeichenaufruf statt
			# einer zweiten, vergrößerten Fläche dahinter.
			s.bg_color = Farben.UI_KNOPF_GEWAEHLT
			s.set_corner_radius_all(10)
			s.set_border_width_all(2)
			s.border_color = Farben.UI_GOLD
			s.shadow_color = Color(Farben.UI_GOLD, 0.18)
			s.shadow_size = 10
			_innenabstand(s, 20.0, 10.0)
		&"balken":
			# Eine Rinne, in die die Füllung eingelassen ist.
			s.bg_color = Color(0, 0, 0, 0.32)
			s.set_corner_radius_all(7)
			s.set_border_width_all(1)
			s.border_color = Color(1, 1, 1, 0.16)
		&"balken_voll":
			# Oben ein weißer Rand, der ins Orange verläuft: ein Glanz, der
			# zu jeder Füllfarbe passt, auch nach `getoent`.
			s.bg_color = Farben.FRUCHT
			s.set_corner_radius_all(6)
			s.border_width_top = 3
			s.border_color = Color(1, 1, 1, 0.45)
			s.border_blend = true
		&"pille":
			s.bg_color = Farben.UI_GOLD
			s.set_corner_radius_all(64)
			_innenabstand(s, 10.0, 3.0)
		&"band":
			# Schräg wie ein Aufkleber; die Schräge macht aus einem Rechteck
			# ein Band, ohne dass ein Polygon von Hand gebaut werden muss.
			s.bg_color = Farben.UI_GOLD
			s.set_corner_radius_all(4)
			s.skew = Vector2(0.25, 0.0)
			s.shadow_color = Color(0, 0, 0, 0.35)
			s.shadow_size = 6
			s.shadow_offset = Vector2(0, 3)
		&"schalter":
			s.bg_color = Color(1, 1, 1, 0.14)
			s.set_corner_radius_all(64)
			s.set_border_width_all(1)
			s.border_color = Color(1, 1, 1, 0.22)
		&"mulde":
			# Bewusst keine volle Rundung, siehe "Kapselformen" oben.
			s.bg_color = Color(0, 0, 0, 0.35)
			s.set_corner_radius_all(10)
			s.set_border_width_all(1)
			s.border_color = Color(1, 1, 1, 0.12)
			_innenabstand(s, 10.0, 6.0)
		_:
			push_warning("UiStil: unbekannte Fläche '%s', nehme &\"tafel\"" % art)
			return flaeche(&"tafel").duplicate() as StyleBoxFlat
	return s


static func _innenabstand(s: StyleBox, waagerecht: float, senkrecht: float) -> void:
	s.content_margin_left = waagerecht
	s.content_margin_right = waagerecht
	s.content_margin_top = senkrecht
	s.content_margin_bottom = senkrecht


# ------------------------------------------------------------ Theme

## Theme für jede UI-Wurzel (siehe Kopfkommentar: CanvasLayer!).
##
## Schrift &"text" in 18 px; Label mit Kontur in UI_KONTUR, damit Text auch
## ohne eigenes Zeichnen auf hellem Grund lesbar bleibt. Button und
## Panel/PanelContainer nutzen die Flächen oben, falls einmal echte
## Controls dazukommen.
static func thema() -> Theme:
	if _thema != null:
		return _thema
	var t := Theme.new()
	t.default_font = schrift(&"text")
	t.default_font_size = GROESSE_TEXT

	t.set_color(&"font_color", &"Label", Farben.UI_HELL)
	t.set_color(&"font_outline_color", &"Label", Farben.UI_KONTUR)
	t.set_color(&"font_shadow_color", &"Label", Color(0, 0, 0, 0))
	t.set_constant(&"outline_size", &"Label", 8)

	t.set_stylebox(&"normal", &"Button", flaeche(&"knopf"))
	t.set_stylebox(&"hover", &"Button", flaeche(&"knopf_gewaehlt"))
	t.set_stylebox(&"pressed", &"Button", flaeche(&"knopf_gewaehlt"))
	t.set_stylebox(&"hover_pressed", &"Button", flaeche(&"knopf_gewaehlt"))
	t.set_stylebox(&"disabled", &"Button", flaeche(&"knopf"))
	var nur_rahmen := func(s: StyleBoxFlat) -> void:
		s.draw_center = false
		s.shadow_size = 0
	t.set_stylebox(&"focus", &"Button", variante(&"knopf_gewaehlt", &"fokus",
			nur_rahmen))
	t.set_color(&"font_color", &"Button", Farben.UI_TEXT_RUHE)
	t.set_color(&"font_hover_color", &"Button", Farben.UI_GOLD_HELL)
	t.set_color(&"font_pressed_color", &"Button", Farben.UI_GOLD_HELL)
	t.set_color(&"font_hover_pressed_color", &"Button", Farben.UI_GOLD_HELL)
	t.set_color(&"font_focus_color", &"Button", Farben.UI_GOLD_HELL)
	t.set_color(&"font_disabled_color", &"Button", Color(Farben.UI_TEXT_RUHE, 0.45))
	t.set_color(&"font_outline_color", &"Button", Farben.UI_KONTUR)
	t.set_constant(&"outline_size", &"Button", 6)

	t.set_stylebox(&"panel", &"Panel", flaeche(&"tafel"))
	t.set_stylebox(&"panel", &"PanelContainer", flaeche(&"tafel"))
	_thema = t
	return t


# ------------------------------------------------------------ Text

## Konturbreite, die zu einer Schriftgröße passt: 3 px bei kleiner
## Schrift, 17 px beim großen Schriftzug (wie bisher im Startbildschirm).
static func konturstaerke(groesse: int) -> int:
	return clampi(roundi(groesse / 6.0), 3, 20)


## Zeichnet eine Textzeile mit Kontur und weichem Schatten.
##
## `pos` ist wie bei `draw_string` die Grundlinie. Ohne `breite` ist
## `pos.x` der Ankerpunkt: links, Mitte oder rechtes Ende, je nach
## `ausrichtung` – so braucht niemand mehr eigene `_mittig`/`_rechts`.
## Mit `breite` gilt Godots Verhalten: ausgerichtet im Feld ab `pos.x`.
##
## `kontur` = -1 wählt `konturstaerke(groesse)`, 0 schaltet Kontur und
## Schatten ab. Die Kontur folgt der Deckung von `farbe` abgeschwächt
## (Wurzel): Linear mitgenommen verschwand gedämpfter Text (UI_MATT) auf
## hellem Himmel ganz, voll deckend bekam er einen schweren dunklen Hof.
## Blendet `farbe.a` auf 0, verschwindet die Kontur mit.
##
## Rückgabe: die Breite des Textes in px (für Unterstreichungen usw.).
static func text(auf: CanvasItem, pos: Vector2, inhalt: String, groesse: int,
		farbe: Color, art: StringName = &"text", kontur: int = -1,
		ausrichtung: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		breite: float = -1.0) -> float:
	if inhalt.is_empty() or groesse <= 0:
		return 0.0
	var zs := schrift(art)
	var weite := zs.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	var ort := pos
	var ausr := ausrichtung
	if breite < 0.0:
		if ausrichtung == HORIZONTAL_ALIGNMENT_CENTER:
			ort.x -= weite * 0.5
		elif ausrichtung == HORIZONTAL_ALIGNMENT_RIGHT:
			ort.x -= weite
		ausr = HORIZONTAL_ALIGNMENT_LEFT
	var staerke := kontur if kontur >= 0 else konturstaerke(groesse)
	if staerke > 0:
		auf.draw_string_outline(zs, ort + Vector2(0.0, maxf(1.0, staerke * 0.45)),
				inhalt, ausr, breite, groesse, staerke,
				Color(0, 0, 0, SCHATTEN * farbe.a))
		auf.draw_string_outline(zs, ort, inhalt, ausr, breite, groesse, staerke,
				_kontur(sqrt(farbe.a)))
	auf.draw_string(zs, ort, inhalt, ausr, breite, groesse, farbe)
	return weite


## Mehrzeiliger Text mit Kontur, umbrochen auf `breite`. `pos` ist die
## Grundlinie der ersten Zeile. Rückgabe: die Höhe des Absatzes in px.
static func absatz(auf: CanvasItem, pos: Vector2, inhalt: String, groesse: int,
		farbe: Color, breite: float, art: StringName = &"text",
		max_zeilen: int = -1, kontur: int = -1,
		ausrichtung: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> float:
	if inhalt.is_empty() or groesse <= 0:
		return 0.0
	var zs := schrift(art)
	var staerke := kontur if kontur >= 0 else konturstaerke(groesse)
	if staerke > 0:
		auf.draw_multiline_string_outline(zs,
				pos + Vector2(0.0, maxf(1.0, staerke * 0.45)), inhalt,
				ausrichtung, breite, groesse, max_zeilen, staerke,
				Color(0, 0, 0, SCHATTEN * farbe.a))
		auf.draw_multiline_string_outline(zs, pos, inhalt, ausrichtung, breite,
				groesse, max_zeilen, staerke, _kontur(sqrt(farbe.a)))
	auf.draw_multiline_string(zs, pos, inhalt, ausrichtung, breite, groesse,
			max_zeilen, farbe)
	return zs.get_multiline_string_size(inhalt, ausrichtung, breite, groesse,
			max_zeilen).y


## Breite einer Textzeile in px.
static func textbreite(inhalt: String, groesse: int, art: StringName = &"text") -> float:
	return schrift(art).get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse).x


## Größte Schriftgröße ≤ `groesse`, bei der `inhalt` in `max_breite` passt –
## gegen Zeilen, die über den Tafelrand laufen. Nie kleiner als `kleinste`.
static func passend(zeichensatz: Font, inhalt: String, groesse: int,
		max_breite: float, kleinste: int = 10) -> int:
	if zeichensatz == null or max_breite <= 0.0 or inhalt.is_empty():
		return groesse
	var weite := zeichensatz.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT,
			-1, groesse).x
	if weite <= max_breite:
		return groesse
	# Erst schätzen, dann nachzählen: Die Breite wächst wegen Hinting und
	# Sperrung nicht ganz linear mit der Größe.
	var g := clampi(floori(groesse * max_breite / weite), kleinste, groesse)
	while g > kleinste and zeichensatz.get_string_size(inhalt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, g).x > max_breite:
		g -= 1
	return g


## Kürzt `inhalt` mit "…", bis er in `max_breite` passt. `vorne` = true
## behält das Ende (für Dateipfade: der Dateiname ist das Wichtige).
static func kuerzen(zeichensatz: Font, inhalt: String, groesse: int,
		max_breite: float, vorne: bool = false) -> String:
	if zeichensatz == null or _weite(zeichensatz, inhalt, groesse) <= max_breite:
		return inhalt
	var unten := 0
	var oben := inhalt.length()
	while unten < oben:
		var probe := (unten + oben + 1) >> 1
		if _weite(zeichensatz, _gekuerzt(inhalt, probe, vorne), groesse) <= max_breite:
			unten = probe
		else:
			oben = probe - 1
	return _gekuerzt(inhalt, unten, vorne)


static func _gekuerzt(inhalt: String, anzahl: int, vorne: bool) -> String:
	if vorne:
		return "…" + inhalt.right(anzahl).strip_edges(true, false)
	return inhalt.left(anzahl).strip_edges(false, true) + "…"


static func _weite(zeichensatz: Font, inhalt: String, groesse: int) -> float:
	return zeichensatz.get_string_size(inhalt, HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse).x


static func _kontur(deckung: float) -> Color:
	return Color(Farben.UI_KONTUR, Farben.UI_KONTUR.a * clampf(deckung, 0.0, 1.0))


static func _mit_alpha(farbe: Color, deckung: float) -> Color:
	return Color(farbe, farbe.a * clampf(deckung, 0.0, 1.0))


# ------------------------------------------------------------ Zeichnen

## Rechteck mit linearem Farbverlauf, waagerecht (links → rechts) oder
## senkrecht (oben → unten).
static func verlauf(auf: CanvasItem, feld: Rect2, von: Color, bis: Color,
		waagerecht: bool = false) -> void:
	var ecken := PackedVector2Array([
		feld.position,
		feld.position + Vector2(feld.size.x, 0.0),
		feld.end,
		feld.position + Vector2(0.0, feld.size.y),
	])
	var farben: PackedColorArray
	if waagerecht:
		farben = PackedColorArray([von, bis, bis, von])
	else:
		farben = PackedColorArray([von, von, bis, bis])
	auf.draw_polygon(ecken, farben)


## Dunkelt die Ränder von `feld` weich ab. `staerke` ist die Deckung in
## den Ecken (ungefähr; die Mitte bleibt frei). Auf ein Rechteck gezogen
## wird die Vignette elliptisch.
static func vignette(auf: CanvasItem, feld: Rect2, staerke: float = 0.45) -> void:
	auf.draw_texture_rect(_vignettentextur(), feld, false,
			Color(1, 1, 1, clampf(staerke / 0.66, 0.0, 1.0)))


## Kreisrunder Verlauf, `innen` in der Mitte, `aussen` ab dem Rand des
## Inkreises (die Ecken bleiben `aussen`). Für Lichtscheiben und Glühen:
##   auf.draw_texture_rect(UiStil.radialverlauf(warm, klar), feld, false)
## Geteilt und zwischengespeichert – nur für eine feste Menge von Farben.
static func radialverlauf(innen: Color, aussen: Color) -> GradientTexture2D:
	var schluessel := StringName("radial|%s|%s" % [innen.to_html(), aussen.to_html()])
	if _texturen.has(schluessel):
		return _texturen[schluessel] as GradientTexture2D
	var g := Gradient.new()
	g.set_color(0, innen)
	g.set_color(1, aussen)
	var t := _radialtextur(g, Vector2(1.0, 0.5))
	_texturen[schluessel] = t
	return t


static func _vignettentextur() -> GradientTexture2D:
	if _texturen.has(&"vignette"):
		return _texturen[&"vignette"] as GradientTexture2D
	# Innen klar, ab halbem Weg zunehmend dunkel. Der Endpunkt liegt
	# jenseits der Ecken, damit dort kein harter Übergang entsteht.
	var g := Gradient.new()
	g.set_color(0, Color(Farben.UI_NACHT, 0.0))
	g.set_color(1, Color(Farben.UI_NACHT, 1.0))
	g.add_point(0.5, Color(Farben.UI_NACHT, 0.0))
	g.add_point(0.78, Color(Farben.UI_NACHT, 0.4))
	var t := _radialtextur(g, Vector2(1.1, 1.1))
	_texturen[&"vignette"] = t
	return t


static func _radialtextur(g: Gradient, bis: Vector2) -> GradientTexture2D:
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = bis
	return t


## Fortschrittsbalken: Rinne (&"balken") und eingelassene Füllung
## (&"balken_voll", in `farbe` getönt). `anteil` von 0 bis 1.
static func balken(auf: CanvasItem, feld: Rect2, anteil: float,
		farbe: Color = Farben.FRUCHT) -> void:
	zeichne(auf, feld, &"balken")
	var innen := feld.grow(-2.0)
	var voll := innen.size.x * clampf(anteil, 0.0, 1.0)
	if voll < 1.0:
		return
	var stil := flaeche(&"balken_voll") if farbe == Farben.FRUCHT \
			else getoent(&"balken_voll", farbe)
	stil.draw(auf.get_canvas_item(), Rect2(innen.position, Vector2(voll, innen.size.y)))


## Runde, eingelassene Fassung – etwa für die beiden Edelsteine eines
## Levels. Oben ein dunkler Innenschatten, damit sie vertieft wirkt.
static func fassung(auf: CanvasItem, mitte: Vector2, r: float,
		deckung: float = 1.0) -> void:
	auf.draw_circle(mitte, r, Color(0, 0, 0, 0.35 * deckung), true, -1.0, true)
	auf.draw_arc(mitte, r - 1.5, PI * 1.08, PI * 1.92, 24,
			Color(0, 0, 0, 0.35 * deckung), 2.5, true)
	auf.draw_arc(mitte, r, 0.0, TAU, 48, Color(1, 1, 1, 0.13 * deckung), 1.0, true)


## Raute (Fortschrittsmarke, Stufenanzeige). Gefüllt oder als Umriss.
static func raute(auf: CanvasItem, mitte: Vector2, r: float, farbe: Color,
		gefuellt: bool = true, strich: float = 1.6) -> void:
	var ecken := PackedVector2Array([
		mitte + Vector2(0, -r), mitte + Vector2(r, 0),
		mitte + Vector2(0, r), mitte + Vector2(-r, 0),
	])
	if gefuellt:
		auf.draw_colored_polygon(ecken, farbe)
	else:
		auf.draw_polyline(_geschlossen(ecken), farbe, strich, true)


## Geschliffener Edelstein mit Kontur. `erhalten` = false zeichnet nur den
## leeren Umriss, dunkel mit hellem Strich – man sieht, was noch fehlt.
## `r` ist die halbe Breite; die Spitze reicht `r` unter die Mitte.
## Farben: Farben.EDELSTEIN_KISTEN, EDELSTEIN_OHNE_TOD, Zeitlauf-Stufen.
static func edelstein(auf: CanvasItem, mitte: Vector2, r: float, farbe: Color,
		erhalten: bool = true, deckung: float = 1.0) -> void:
	var links := mitte + Vector2(-1.0, -0.22) * r
	var rechts := mitte + Vector2(1.0, -0.22) * r
	var krone_l := mitte + Vector2(-0.55, -0.74) * r
	var krone_r := mitte + Vector2(0.55, -0.74) * r
	var spitze := mitte + Vector2(0.0, 1.0) * r
	var umriss := PackedVector2Array([links, krone_l, krone_r, rechts, spitze])
	var rand := maxf(1.2, r * 0.16)
	if not erhalten:
		auf.draw_colored_polygon(umriss, Color(0, 0, 0, 0.30 * deckung))
		auf.draw_polyline(_geschlossen(umriss), Color(1, 1, 1, 0.30 * deckung),
				maxf(1.2, r * 0.1), true)
		return
	auf.draw_polyline(_geschlossen(umriss), _kontur(deckung), rand * 2.0, true)
	var f := _mit_alpha(farbe, deckung)
	# Unterteil in drei Facetten: links Grundton, Mitte heller, rechts Schatten
	var gurt_l := mitte + Vector2(-0.42, -0.22) * r
	var gurt_r := mitte + Vector2(0.42, -0.22) * r
	auf.draw_colored_polygon(PackedVector2Array([links, gurt_l, spitze]), f)
	auf.draw_colored_polygon(PackedVector2Array([gurt_l, gurt_r, spitze]),
			f.lightened(0.18))
	auf.draw_colored_polygon(PackedVector2Array([gurt_r, rechts, spitze]),
			f.darkened(0.28))
	# Krone und Tafel (die flache Oberseite)
	auf.draw_colored_polygon(PackedVector2Array([links, krone_l, krone_r, rechts]),
			f.lightened(0.32))
	auf.draw_colored_polygon(PackedVector2Array([
			mitte + Vector2(-0.3, -0.74) * r, mitte + Vector2(0.3, -0.74) * r,
			gurt_r, gurt_l]), f.lightened(0.55))
	# Funkeln oben rechts
	var funke := mitte + Vector2(0.5, -0.62) * r
	var s := r * 0.32
	var weiss := Color(1, 1, 1, 0.9 * deckung)
	auf.draw_line(funke - Vector2(s, 0), funke + Vector2(s, 0), weiss, maxf(1.0, r * 0.08), true)
	auf.draw_line(funke - Vector2(0, s), funke + Vector2(0, s), weiss, maxf(1.0, r * 0.08), true)


## Frucht: Beere mit Schattenseite, Glanzpunkt und Blatt, dunkel umrandet.
## Das HUD-Symbol als Vorbild, dazu Kontur und Schattenseite – eine Stelle,
## damit Zähler, Ladeschirm und Auswertung dieselbe Frucht zeigen.
static func frucht(auf: CanvasItem, mitte: Vector2, r: float,
		deckung: float = 1.0) -> void:
	var rand := maxf(1.5, r * 0.15)
	var blatt := PackedVector2Array([
		mitte + Vector2(r * 0.05, -r * 0.9),
		mitte + Vector2(r * 0.95, -r * 1.5),
		mitte + Vector2(r * 0.22, -r * 1.38),
	])
	var kontur := _kontur(deckung)
	auf.draw_polyline(_geschlossen(blatt), kontur, rand * 2.0, true)
	auf.draw_circle(mitte, r + rand, kontur, true, -1.0, true)
	var koerper := _mit_alpha(Farben.FRUCHT, deckung)
	auf.draw_circle(mitte, r, koerper.darkened(0.25), true, -1.0, true)
	auf.draw_circle(mitte - Vector2(r, r) * 0.12, r * 0.82, koerper, true, -1.0, true)
	auf.draw_circle(mitte - Vector2(r * 0.32, r * 0.36), r * 0.27,
			Color(1, 0.88, 0.64, 0.85 * deckung), true, -1.0, true)
	auf.draw_colored_polygon(blatt, _mit_alpha(Farben.FRUCHT_BLATT.lightened(0.15), deckung))


## Herz (Leben). `voll` = false zeichnet ein leeres, blasses Herz.
## `r` ist die halbe Breite.
static func herz(auf: CanvasItem, mitte: Vector2, r: float, voll: bool = true,
		deckung: float = 1.0) -> void:
	var form := PackedVector2Array()
	var umriss := PackedVector2Array()
	var punkte := _herzpunkte()
	for i in punkte.size():
		form.append(mitte + punkte[i] * r)
		# Die Spitze unten fehlt im Umriss: Dort treffen sich die beiden
		# Flanken fast parallel, und die Linie setzt an so einem Knick eine
		# Gehrung an – ein Dorn, gut dreimal so lang wie die Kontur breit.
		# Ohne den Punkt endet die Kontur dort stumpf statt in einem Dorn.
		# Die Füllung behält ihre Spitze; die liegt nur Bruchteile eines
		# Pixels unter der Sehne und bleibt innerhalb der Konturbreite.
		if i != HERZ_SPITZE:
			umriss.append(form[i])
	var rand := maxf(1.5, r * 0.16)
	auf.draw_polyline(_geschlossen(umriss), _kontur(deckung), rand * 2.0, true)
	if not voll:
		auf.draw_colored_polygon(form, Color(1, 1, 1, 0.16 * deckung))
		return
	var f := _mit_alpha(Farben.UI_HERZ, deckung)
	auf.draw_colored_polygon(form, f.darkened(0.25))
	# Innen ein kleineres, helleres Herz: ergibt eine dunklere Kante unten
	# rechts, ohne Verlaufsfarben pro Punkt.
	var innen := PackedVector2Array()
	var versatz := mitte - Vector2(r * 0.06, r * 0.1)
	for punkt in _herzpunkte():
		innen.append(versatz + punkt * r * 0.8)
	auf.draw_colored_polygon(innen, f)
	auf.draw_circle(mitte + Vector2(-r * 0.45, -r * 0.42), r * 0.2,
			Color(1, 1, 1, 0.55 * deckung), true, -1.0, true)


## Kiste mit Rahmen und Kreuzstreben. `r` ist die halbe Kantenlänge.
static func kiste(auf: CanvasItem, mitte: Vector2, r: float,
		deckung: float = 1.0) -> void:
	var feld := Rect2(mitte - Vector2(r, r), Vector2(r, r) * 2.0)
	var rand := maxf(1.5, r * 0.15)
	var holz := _mit_alpha(Farben.HOLZ.darkened(0.2), deckung)
	var fuge := _mit_alpha(Farben.HOLZ_DUNKEL.darkened(0.3), deckung)
	var strich := maxf(1.5, r * 0.18)
	auf.draw_rect(feld.grow(rand), _kontur(deckung))
	auf.draw_rect(feld, holz)
	# Oberkante heller: Licht von oben, wie bei den Kisten im Level
	auf.draw_rect(Rect2(feld.position, Vector2(feld.size.x, r * 0.3)),
			holz.lightened(0.2))
	auf.draw_line(feld.position, feld.end, fuge, strich, true)
	auf.draw_line(feld.position + Vector2(feld.size.x, 0),
			feld.position + Vector2(0, feld.size.y), fuge, strich, true)
	auf.draw_rect(feld, fuge, false, strich)


## Herzform als Einheitspunkte (halbe Breite 1, Mitte ≈ Formmitte),
## einmal berechnet. Klassische Herzkurve statt zweier Kreise und eines
## Dreiecks – nur so lässt sie sich als Ganzes umranden.
static func _herzpunkte() -> PackedVector2Array:
	if _herzform.is_empty():
		for i in HERZ_PUNKTE:
			var t := TAU * float(i) / float(HERZ_PUNKTE)
			var s := sin(t)
			var x := 16.0 * s * s * s
			var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t)
					- cos(4.0 * t))
			_herzform.append(Vector2(x, y - 2.5) / 16.0)
	return _herzform


static func _geschlossen(punkte: PackedVector2Array) -> PackedVector2Array:
	var zug := punkte.duplicate()
	if not punkte.is_empty():
		zug.append(punkte[0])
	return zug


# ------------------------------------------------------------ Bewegung
#
# Alle Tween-Helfer merken sich ihren Tween je Knoten und Kanal (als
# Metadatum "_uistil_<kanal>") und brechen einen laufenden desselben
# Kanals ab, bevor sie einen neuen starten. Das behebt die Wettläufe, bei
# denen ein altes Ausblenden einen gerade neu gezeigten Knoten wieder
# versteckte. Kanäle: "pop", "alpha" (modulate.a), "schweben" (position),
# "zaehlen" (oder frei wählbar bei zaehle_hoch).
#
# Die Tweens hängen am Knoten und folgen seinem process_mode: Unter einer
# Statustafel (PROCESS_MODE_ALWAYS) laufen sie auch bei angehaltenem Spiel.
# Engine.time_scale ignorieren sie – eine Zeitlupe im Spiel soll kein
# Menü verlangsamen. Der zurückgegebene Tween darf im selben Bild noch
# verlängert werden (etwa `.tween_callback(knoten.queue_free)`).

## Kurzes Aufploppen: Größe auf (1 + staerke) und federnd zurück. Bei
## einem Control wird der Drehpunkt auf die Mitte gelegt
## (pivot_offset_ratio 0.5, pivot_offset 0); `mitte` = false lässt ihn
## stehen. Wiederholtes Auslösen stapelt sich nicht auf, die Größe kehrt
## immer zur Ausgangsgröße zurück. Nur für Control und Node2D.
static func pop(knoten: CanvasItem, staerke: float = 0.18, dauer: float = 0.3,
		mitte: bool = true) -> Tween:
	if not (knoten is Control or knoten is Node2D):
		push_warning("UiStil.pop: %s hat keine Größe (scale)" % knoten)
		return null
	var grund: Vector2 = knoten.get(&"scale")
	if _laeuft(knoten, &"pop") and knoten.has_meta(&"_uistil_wert_pop"):
		grund = knoten.get_meta(&"_uistil_wert_pop")
	knoten.set_meta(&"_uistil_wert_pop", grund)
	if mitte and knoten is Control:
		# Anteilig statt in Pixeln: bleibt mittig, auch wenn der Knoten
		# später seine Größe ändert (etwa ein Label mit neuem Text).
		var steuer := knoten as Control
		steuer.pivot_offset = Vector2.ZERO
		steuer.pivot_offset_ratio = Vector2(0.5, 0.5)
	var t := _tween_fuer(knoten, &"pop")
	t.tween_property(knoten, ^"scale", grund * (1.0 + staerke), dauer * 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(knoten, ^"scale", grund, dauer * 0.72) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t


## Blendet ein (modulate.a → 1) und macht sichtbar. Beginnt bei 0 – außer
## ein Ein- oder Ausblenden läuft gerade, dann geht es von dort weiter.
static func einblenden(knoten: CanvasItem, dauer: float = 0.25,
		verzoegerung: float = 0.0) -> Tween:
	var weiter := _laeuft(knoten, &"alpha")
	var t := _tween_fuer(knoten, &"alpha")
	if not weiter:
		knoten.modulate.a = 0.0
	knoten.visible = true
	t.tween_property(knoten, ^"modulate:a", 1.0,
			maxf(dauer * (1.0 - knoten.modulate.a), 0.01)) \
			.set_delay(verzoegerung) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return t


## Blendet aus (modulate.a → 0) und versteckt am Ende (`verstecken`).
## Die Dauer gilt für volle Deckung; halb Sichtbares ist halb so schnell weg.
static func ausblenden(knoten: CanvasItem, dauer: float = 0.25,
		verstecken: bool = true) -> Tween:
	var t := _tween_fuer(knoten, &"alpha")
	t.tween_property(knoten, ^"modulate:a", 0.0,
			maxf(dauer * knoten.modulate.a, 0.01)) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if verstecken:
		t.tween_callback(knoten.hide)
	return t


## Schwebt aus `position + versatz` an die jetzige Stelle und blendet dabei
## ein. Die Ruhelage wird gemerkt, damit ein Abbruch mitten im Schweben
## (oder ein `ausschweben`) nicht an einer verschobenen Stelle endet.
## `federnd` schießt leicht über das Ziel hinaus (TRANS_BACK).
## Nur für frei platzierte Knoten – in Containern setzt das Layout die
## Position zurück.
static func einschweben(knoten: CanvasItem, versatz: Vector2,
		dauer: float = 0.35, verzoegerung: float = 0.0,
		federnd: bool = false) -> Tween:
	var weiter := _laeuft(knoten, &"schweben")
	var ziel := _ruhelage(knoten, weiter)
	var t := _tween_fuer(knoten, &"schweben")
	if not weiter:
		knoten.set(&"position", ziel + versatz)
	t.tween_property(knoten, ^"position", ziel, dauer).set_delay(verzoegerung) \
			.set_trans(Tween.TRANS_BACK if federnd else Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
	einblenden(knoten, dauer * 0.8, verzoegerung)
	return t


## Schwebt um `versatz` davon und blendet aus. Mit `verstecken` wird der
## Knoten am Ende versteckt und still an die Ruhelage zurückgesetzt, damit
## das nächste `einschweben` wieder stimmt.
static func ausschweben(knoten: CanvasItem, versatz: Vector2,
		dauer: float = 0.3, verstecken: bool = true) -> Tween:
	var ruhe := _ruhelage(knoten, _laeuft(knoten, &"schweben"))
	var t := _tween_fuer(knoten, &"schweben")
	t.tween_property(knoten, ^"position", ruhe + versatz, dauer) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	ausblenden(knoten, dauer, verstecken)
	if verstecken:
		t.tween_callback(func() -> void: knoten.set(&"position", ruhe))
	return t


## Zählt von `von` nach `bis` hoch und ruft `bei_wert(wert: int)` bei jeder
## neuen ganzen Zahl – einmal sofort mit `von`. Schnell am Anfang, langsam
## zum Schluss. Für mehrere Zähler an einem Knoten verschiedene `kanal`.
static func zaehle_hoch(knoten: Node, von: int, bis: int, dauer: float,
		bei_wert: Callable, kanal: StringName = &"zaehlen") -> Tween:
	var t := _tween_fuer(knoten, kanal)
	var stand: Array[int] = [von]
	bei_wert.call(von)
	var schritt := func(wert: float) -> void:
		var ganz := roundi(wert)
		if ganz != stand[0]:
			stand[0] = ganz
			bei_wert.call(ganz)
	t.tween_method(schritt, float(von), float(bis), maxf(dauer, 0.01)) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return t


## Springt mit allen laufenden UiStil-Tweens eines Knotens sofort ans
## Ende, samt ihrer Rückrufe – für "Einblendung überspringen".
static func vollenden(knoten: Node) -> void:
	for schluessel in knoten.get_meta_list():
		if not String(schluessel).begins_with("_uistil_"):
			continue
		var wert: Variant = knoten.get_meta(schluessel)
		if wert is Tween and (wert as Tween).is_valid():
			(wert as Tween).custom_step(3600.0)


## Weiches Nachziehen eines angezeigten Werts an sein Ziel, pro Bild in
## `_process`: große Abstände schnell, kleine mindestens mit `mindest`
## Einheiten pro Sekunde. Für hochlaufende Zähler und Ladebalken.
static func annaehern(ist: float, ziel: float, delta: float, tempo: float = 7.0,
		mindest: float = 14.0) -> float:
	return move_toward(ist, ziel, maxf(mindest, absf(ziel - ist) * tempo) * delta)


## Federnde Größe für selbst gezeichnete Pops. `rest` läuft von 1 (gerade
## ausgelöst) nach 0 (ruhig), etwa `rest = maxf(rest - delta * 3.0, 0.0)`.
## Ergibt 1 + staerke am Anfang, schwingt einmal leicht unter 1 und kommt
## genau bei 1 an:
##   auf.draw_set_transform(mitte, 0.0, Vector2.ONE * UiStil.federkurve(rest))
static func federkurve(rest: float, staerke: float = 0.25) -> float:
	var r := clampf(rest, 0.0, 1.0)
	return 1.0 + staerke * r * r * cos((1.0 - r) * PI * 3.0)


static func _kanal(kanal: StringName) -> StringName:
	return StringName("_uistil_" + String(kanal))


static func _laeuft(knoten: Node, kanal: StringName) -> bool:
	var schluessel := _kanal(kanal)
	if not knoten.has_meta(schluessel):
		return false
	var t := knoten.get_meta(schluessel) as Tween
	return t != null and t.is_valid() and t.is_running()


static func _tween_fuer(knoten: Node, kanal: StringName) -> Tween:
	var schluessel := _kanal(kanal)
	if knoten.has_meta(schluessel):
		var alt := knoten.get_meta(schluessel) as Tween
		if alt != null and alt.is_valid():
			alt.kill()
	var neu := knoten.create_tween()
	neu.set_ignore_time_scale(true)
	knoten.set_meta(schluessel, neu)
	return neu


static func _ruhelage(knoten: CanvasItem, weiter: bool) -> Vector2:
	var ruhe: Vector2 = knoten.get(&"position")
	if weiter and knoten.has_meta(&"_uistil_wert_ruhe"):
		ruhe = knoten.get_meta(&"_uistil_wert_ruhe")
	knoten.set_meta(&"_uistil_wert_ruhe", ruhe)
	return ruhe


# ------------------------------------------------------------ Blende

## Der geteilte Shader der Iris-Blende (Kreis, der sich schließt/öffnet).
static func iris_shader() -> Shader:
	if _iris_shader == null:
		_iris_shader = Shader.new()
		_iris_shader.code = _IRIS_CODE
	return _iris_shader


## Vollbild-Blende für Übergänge: Abblenden, Aufblenden, Farbblitz, Iris.
##
## Ein ColorRect über der ganzen Fläche seines Elternknotens. Jede
## Oberfläche legt sich ihre eigene an, sie stören einander nicht:
##
##   var blende := UiStil.Blende.new()          # dunkel, anfangs unsichtbar
##   add_child(blende)                          # unter CanvasLayer oder Control
##   await blende.zu(0.2).finished              # abblenden
##   blende.auf(0.35)                           # aufblenden
##   blende.blitz(Color(Farben.UI_TREFFER, 0.92), 0.45)       # Tod/Treffer
##   blende.blitz(Color(Farben.UI_TREFFER, 0.92), 0.6, 0.6)   # halten, dann weg
##   await blende.iris_zu(spieler_im_bild, 0.45).finished     # Kreis schließt
##   blende.iris_auf(bildmitte, 0.45)                         # Kreis öffnet
##
## Jeder Aufruf bricht den vorigen ab und macht dort weiter, wo die Blende
## gerade steht – kein altes Ausblenden versteckt ein neues Abblenden.
## Unsichtbar, solange sie nichts deckt (kostet dann keine Füllrate).
## Läuft mit PROCESS_MODE_ALWAYS: Ein Übergang bleibt nicht halb stehen,
## wenn das Spiel pausiert. Maus und Finger gehen durch (MOUSE_FILTER_IGNORE);
## wer während des Wechsels Eingaben sperren will, setzt mouse_filter selbst.
## Nicht in einen Container hängen – dort gelten die Anker nicht.
class Blende extends ColorRect:
	## Farbe bei voller Deckung; `blitz()` färbt nur vorübergehend um.
	var grundfarbe: Color
	var _tween: Tween = null
	var _iris: ShaderMaterial = null

	func _init(farbe: Color = Farben.UI_NACHT) -> void:
		name = "Blende"
		grundfarbe = Color(farbe, 1.0)
		color = Color(farbe, 0.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		process_mode = Node.PROCESS_MODE_ALWAYS
		visible = false

	## Deckt die Blende gerade vollständig?
	func ist_zu() -> bool:
		if not visible or color.a < 0.999:
			return false
		return material == null or _iris_radius() <= 0.0

	## Setzt die Deckung sofort, ohne Übergang.
	func setzen(anteil: float) -> void:
		_anhalten()
		material = null
		color = Color(grundfarbe, clampf(anteil, 0.0, 1.0))
		visible = color.a > 0.0

	## Abblenden bis zur vollen Deckung.
	func zu(dauer: float = 0.25) -> Tween:
		_anhalten()
		material = null
		color = Color(grundfarbe, color.a)
		visible = true
		_tween = _neuer_tween()
		_tween.tween_property(self, ^"color:a", 1.0,
				maxf(dauer * (1.0 - color.a), 0.01)) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return _tween

	## Aufblenden, am Ende unsichtbar. Steht gerade eine Iris, öffnet sie
	## sich stattdessen – sonst sprünge das Bild erst auf Schwarz.
	func auf(dauer: float = 0.35) -> Tween:
		if material != null and _iris != null:
			var mitte: Vector2 = _iris.get_shader_parameter("mitte")
			return iris_auf(mitte, dauer)
		_anhalten()
		_tween = _neuer_tween()
		_tween.tween_property(self, ^"color:a", 0.0, maxf(dauer * color.a, 0.01)) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_callback(_ruhe)
		return _tween

	## Farbblitz: sofort `farbe` (mit deren Deckung), `halten` Sekunden
	## stehen lassen, dann in `dauer` ausblenden. Für Tod und Treffer.
	func blitz(farbe: Color, dauer: float = 0.45, halten: float = 0.0) -> Tween:
		_anhalten()
		material = null
		color = farbe
		visible = true
		_tween = _neuer_tween()
		if halten > 0.0:
			_tween.tween_interval(halten)
		_tween.tween_property(self, ^"color:a", 0.0, maxf(dauer, 0.01)) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_callback(_ruhe)
		return _tween

	## Kreisblende schließt sich auf `mitte` (Pixel in dieser Blende, etwa
	## `kamera.unproject_position(ort)`). Am Ende deckt sie ganz.
	func iris_zu(mitte: Vector2, dauer: float = 0.45) -> Tween:
		var start := _iris_radius() if material != null else _iris_voll(mitte)
		if material == null and visible and color.a >= 0.999:
			start = 0.0   # deckt schon – nicht erst aufreißen
		_iris_vorbereiten(mitte, start)
		_tween = _neuer_tween()
		_tween.tween_property(_iris, ^"shader_parameter/radius", 0.0, maxf(dauer, 0.01)) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		return _tween

	## Kreisblende öffnet sich von `mitte` aus. Deckt die Blende gerade
	## gar nicht, passiert nichts Sichtbares.
	func iris_auf(mitte: Vector2, dauer: float = 0.45) -> Tween:
		var start := _iris_radius() if material != null else 0.0
		if not visible or color.a <= 0.0:
			start = _iris_voll(mitte)
		_iris_vorbereiten(mitte, start)
		_tween = _neuer_tween()
		_tween.tween_property(_iris, ^"shader_parameter/radius", _iris_voll(mitte),
				maxf(dauer, 0.01)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_callback(_ruhe)
		return _tween

	func _iris_vorbereiten(mitte: Vector2, radius: float) -> void:
		_anhalten()
		if _iris == null:
			_iris = ShaderMaterial.new()
			_iris.shader = UiStil.iris_shader()
		_iris.set_shader_parameter("groesse", _flaeche())
		_iris.set_shader_parameter("mitte", mitte)
		_iris.set_shader_parameter("radius", radius)
		material = _iris
		color = Color(grundfarbe, 1.0)
		visible = true

	func _iris_radius() -> float:
		return float(_iris.get_shader_parameter("radius")) if _iris != null else 0.0

	## Radius, bei dem der Kreis auch die fernste Ecke freigibt.
	func _iris_voll(mitte: Vector2) -> float:
		var f := _flaeche()
		var weiteste := 0.0
		for ecke: Vector2 in [Vector2.ZERO, Vector2(f.x, 0.0), f, Vector2(0.0, f.y)]:
			weiteste = maxf(weiteste, mitte.distance_to(ecke))
		return weiteste + 4.0

	func _flaeche() -> Vector2:
		if size.x > 0.0 and size.y > 0.0:
			return size
		return get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)

	func _ruhe() -> void:
		material = null
		color = Color(grundfarbe, 0.0)
		visible = false

	func _anhalten() -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = null

	func _neuer_tween() -> Tween:
		var t := create_tween()
		t.set_ignore_time_scale(true)
		return t
