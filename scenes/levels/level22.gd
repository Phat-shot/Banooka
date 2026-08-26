extends LevelBasis
## Level 22 – "Wolkenjagd" (Raum 5, Vorbild 5-2)
##
## Das erste Level ohne Korridor. Es gibt keinen Weg, keine Levelkurve,
## keine Strecke in Metern und kein Zielportal – nur einen Kasten Luft,
## in dem Ziele kreisen, und einen Zähler. Der Auftrag steht in einem
## Satz: fünf Doppeldecker herunterholen.
##
## WARUM DIREKT AUF `LevelBasis` UND NICHT AUF EINER EIGENEN `FlugBasis`.
## Eine Zwischenschicht hätte im Moment genau einen Erben. Was sie
## enthalten würde – Luftraummaße, Zielzähler, Anzeige, Kulisse – ist
## alles Inhalt DIESES Levels und nicht Gerüst für das nächste; erst wenn
## ein zweites Flugniveau danebensteht, ist zu sehen, was davon wirklich
## geteilt gehört. Eine Basisklasse, die man aus einem einzigen Fall
## herausrät, rät falsch. Was `LevelBasis` schon leistet, reicht:
## Ladeschirm mit Bauschritten, Kamera an den Spieler hängen, Kisten
## zählen (hier null), Zurücksetzen nach dem Tod, Levelabschluss.
##
## Überschrieben wird genau ein Haken: `_spieler_setzen()`. Das Original
## rechnet mit `verlauf` und tut ohne Kurve gar nichts – auch nicht das
## `GameState.level_starten()`, das die Zähler zurücksetzt.
##
## AUFBAU DES LUFTRAUMS. 120 × 44 × 120 m, Mitte auf 32 m Höhe: also von
## 10 m bis 54 m über dem Wolkenmeer. Bei Reisetempo 16 m/s dauert eine
## Durchquerung siebeneinhalb Sekunden, mit Schub (26 m/s) viereinhalb.
## Überblicken lässt er sich trotzdem nicht: Der Dunst nimmt auf 60 m
## schon die Hälfte des Kontrasts, und in der Mitte stehen Wolkenbänke,
## durch die man hindurchfliegt. Man weiß immer, wo man ist, aber nie,
## wo alle sind.
##
## DIE FARBE STECKT IN DEN ZIELEN. Himmel, Wolken und Berge sind
## durchgehend Grau in drei Helligkeiten (`#BCBDC9` gegen `#24252C` im
## Steckbrief). Rot sind nur die Feindmaschinen, gelb nur die Ballons.
## Wer im Dunst einen Farbfleck sieht, weiß sofort: Das ist ein Ziel.

const FLUGZIEL := preload("res://scenes/enemies/Flugziel.tscn")

# ---------------------------------------------------------------- Luftraum

## Größe und Mitte des Luftraums. Werden dem `Flieger` beim Start gesetzt.
const RAUM := Vector3(120.0, 44.0, 120.0)
const RAUM_MITTE := Vector3(0.0, 32.0, 0.0)
## Anfangskurs in Radiant (0 = Blick nach -Z, also in den Raum hinein).
const START_KURS := 0.0

## So viele Feindmaschinen müssen fallen. Ballons zählen nicht mit – sie
## sind die Belohnung zwischendurch, nicht der Auftrag.
const ZIEL_ABSCHUESSE := 5

# ---------------------------------------------------------------- Farben
#
# Alles Grau. `Farben` hat für einen Dunsthimmel nichts Passendes –
# SCHNEE und FELS sind beide zu farbig –, deshalb hier gemessene Werte
# aus dem Steckbrief 5-2.

const DUNST := Color(0.45, 0.50, 0.60)          ## #7B82 – der Grundton
const DUNST_HELL := Color(0.71, 0.74, 0.82)     ## #BCBDC9
const DUNST_DUNKEL := Color(0.14, 0.15, 0.17)   ## #24252C
const WOLKE := Color(0.90, 0.93, 0.98)
const WOLKE_SCHATTEN := Color(0.61, 0.67, 0.79)
const BERGFELS := Color(0.17, 0.20, 0.29)
const BERGSCHNEE := Color(0.84, 0.89, 0.97)
## Lack der eigenen Maschine: braun-oliv wie im Vorbild.
const EIGEN_RUMPF := Color(0.36, 0.27, 0.17)
const EIGEN_FLAECHE := Color(0.42, 0.44, 0.28)
## Die einzigen zwei Farben im Level.
const FEIND_ROT := Color(0.76, 0.18, 0.14)
const BALLON_GELB := Color(0.93, 0.78, 0.22)

# ---------------------------------------------------------------- Anzeige

const ANZEIGE_HELL := Color(0.96, 0.95, 0.92)
const ANZEIGE_MATT := Color(1.0, 1.0, 1.0, 0.6)
const ANZEIGE_WARNUNG := Color(1.0, 0.42, 0.30)


## Zahl der abgeschossenen Feindmaschinen (Jäger und Bomber).
var _abschuesse := 0
## Zahl der geplatzten Ballons – nur für die Anzeige.
var _ballons := 0
## Wie viele Ballons überhaupt hängen.
var _ballons_gesamt := 0
## Steht auf true, sobald der Auftrag erfüllt ist. Verhindert, dass ein
## sechster Abschuss den Levelabschluss ein zweites Mal auslöst.
var _geschafft := false

var _flieger: Flieger
var _zeile_ziel: Label
var _zeile_panzer: Label


# =========================================================== Aufbau

func _bauschritte() -> Array:
	return [
		{"text": "Der Dunst zieht auf", "tun": _anzeige_bauen},
		{"text": "Wolkenmeer", "tun": _wolken_bauen},
		{"text": "Schneeberge", "tun": _berge_bauen},
		{"text": "Feindflug steigt auf", "tun": _ziele_setzen},
		{"text": "Fruchtringe", "tun": _ringe_setzen},
	]


# =========================================================== Spieler

## Der Flieger statt der Figur.
##
## Das Original in `LevelBasis` steigt ohne `verlauf` sofort aus und lässt
## damit auch `GameState.level_starten()` aus – die Zähler blieben dann
## auf dem Stand des vorigen Levels stehen. Hier wird dasselbe getan,
## nur ohne Kurve.
##
## WICHTIG UND UNSCHÖN: Der Startpunkt steht in `Level22.tscn`, nicht
## hier. `flieger.gd` merkt sich seinen Startort in `_ready()` – und das
## läuft, bevor das Level überhaupt aufgebaut ist. Wer die Maschine
## nachträglich versetzt, verschiebt zwar den Start, aber nicht den Punkt,
## an den `respawn()` sie zurückbringt; nach dem ersten Absturz stünde sie
## wieder am Ort aus der Szene. Deshalb: Startpunkt in der Szene, und hier
## nur noch Kurs, Luftraum und Zähler.
func _spieler_setzen() -> void:
	_flieger = _spieler as Flieger
	if _flieger == null:
		push_warning("Level 22: kein Flieger in der Szene – Flugmodus fehlt")
		return
	# Luftraum erst hier setzen: `Flieger` liest beide Werte in jedem
	# Physikschritt, und die Physik läuft während des Aufbaus noch nicht.
	# So stehen die Maße im Level, wo auch die Kulisse dazu steht.
	_flieger.raum = RAUM
	_flieger.raum_mitte = RAUM_MITTE
	_flieger.farbe_rumpf = EIGEN_RUMPF
	_flieger.farbe_flaeche = EIGEN_FLAECHE
	_flieger.setze_blickrichtung(START_KURS)
	_flieger.reset_physics_interpolation()
	if not _flieger.panzerung_geaendert.is_connected(_auf_panzerung):
		_flieger.panzerung_geaendert.connect(_auf_panzerung)
	_auf_panzerung(_flieger.panzer_rest, _flieger.panzerung)
	GameState.level_starten(_flieger.global_position)


# =========================================================== Ziele

## Der Feindflug.
##
## Sechzehn Ziele: acht Jäger, drei Bomber, fünf Ballons. Nötig für den
## Auftrag sind fünf Maschinen – es hängen elf, damit niemand nach dem
## vierten Abschuss durch einen leeren Himmel sucht, und damit ein Tod
## den Auftrag nicht unlösbar macht (abgeschossene Ziele kommen nicht
## wieder, siehe Kopf von `_auf_abgeschossen`).
##
## `bahn_radius`, `phase` und `tempo` streuen bewusst weit. Zwei Ziele
## mit gleichem Radius und gleicher Phase fliegen im Pulk, und ein Pulk
## ist ein einziges großes Ziel statt zweier kleiner.
##
## ACHTUNG bei den Orten: Der gesetzte Punkt liegt AUF der Bahn, nicht in
## ihrem Mittelpunkt (`Flugziel` legt den Mittelpunkt danach so, dass die
## Bahn durch den Punkt läuft). Ein Ziel bei x = 40 mit Radius 18 kann
## also bis x = 76 hinausschwingen – deshalb stehen die weiten Bahnen
## innen und die engen außen.
func _ziele_setzen() -> void:
	# --- Jäger: klein, schnell, eng. Das eigentliche Jagdziel. ---
	# Der erste steht dem Startkurs direkt gegenüber: Wer geradeaus
	# losfliegt, hat nach vier Sekunden sein erstes Ziel im Bild.
	_ziel(Flugziel.Art.JAEGER, Vector3(4, 30, -6), 8.5, 20.0, 3.0, 0.0)
	_ziel(Flugziel.Art.JAEGER, Vector3(-26, 24, -24), 9.5, 26.0, 4.0, 1.1)
	_ziel(Flugziel.Art.JAEGER, Vector3(30, 38, -18), 8.0, 22.0, 2.4, 2.3)
	_ziel(Flugziel.Art.JAEGER, Vector3(-34, 42, 14), 10.0, 18.0, 3.6, 3.0)
	_ziel(Flugziel.Art.JAEGER, Vector3(38, 22, 20), 9.0, 24.0, 4.4, 4.2)
	_ziel(Flugziel.Art.JAEGER, Vector3(-8, 46, 32), 8.5, 28.0, 2.8, 5.1)
	_ziel(Flugziel.Art.JAEGER, Vector3(18, 18, -40), 10.5, 20.0, 3.2, 5.8)
	_ziel(Flugziel.Art.JAEGER, Vector3(-42, 34, -6), 9.0, 22.0, 3.8, 1.7)

	# --- Bomber: groß, langsam, drei Treffer, weite Bahn. ---
	# Zwei von dreien schießen zurück. Alle drei nicht: Dann müsste man
	# ununterbrochen ausweichen, statt zwischendurch zielen zu können.
	_ziel(Flugziel.Art.BOMBER, Vector3(0, 40, -34), 7.0, 38.0, 5.0, 0.6, true)
	_ziel(Flugziel.Art.BOMBER, Vector3(-14, 20, 26), 6.5, 44.0, 4.0, 3.4, true)
	_ziel(Flugziel.Art.BOMBER, Vector3(26, 46, 4), 7.5, 34.0, 6.0, 2.0)

	# --- Ballons: stehen fast still und geben beim Platzen Früchte frei. ---
	# Sie sind die Pause im Level: ein Ziel, das nicht ausweicht und nicht
	# zurückschießt. Deshalb hängen sie am Rand und nicht dort, wo die
	# Jäger kreisen – wer sie holen will, verlässt kurz die Jagd.
	var ballonorte := [
		Vector3(-48, 16, -46), Vector3(46, 44, -44),
		Vector3(-46, 46, 44), Vector3(48, 20, 42),
		Vector3(0, 50, 0),
	]
	for i in ballonorte.size():
		var ort: Vector3 = ballonorte[i]
		_ziel(Flugziel.Art.BALLON, ort, 1.0, 4.0, 0.0, float(i) * 1.2)
		_ballons_gesamt += 1

	_anzeige_auffrischen()


## Setzt ein Ziel und hängt seine beiden Signale ein.
func _ziel(art: Flugziel.Art, ort: Vector3, tempo: float, radius: float,
		bahn_hoehe: float, phase: float, feuert := false) -> Flugziel:
	var z := FLUGZIEL.instantiate() as Flugziel
	z.art = art
	z.tempo = tempo
	z.bahn_radius = radius
	z.bahn_hoehe = bahn_hoehe
	z.phase = phase
	z.feuert = feuert
	z.farbe = BALLON_GELB if art == Flugziel.Art.BALLON else FEIND_ROT
	# Position VOR `add_child`: `Flugziel` rechnet in `_ready()` aus seinem
	# Ort den Mittelpunkt der Bahn.
	z.position = ort
	objekte.add_child(z)
	z.abgeschossen.connect(_auf_abgeschossen)
	z.belohnung_frei.connect(_auf_belohnung)
	return z


## Ein Ziel ist gefallen.
##
## Abgeschossene Ziele kommen NICHT wieder – auch nicht nach einem Tod.
## `LevelBasis` baut beim Zurücksetzen alles wieder auf, was in den
## Gruppen "kisten" oder "gegner" steht; `Flugziel` steht mit Absicht in
## keiner von beiden (siehe Kopf von `flugziel.gd`). Das ist hier richtig
## so: Der Zähler ist der Fortschritt des Levels, und ein Absturz soll
## Panzerung kosten, nicht die Arbeit der letzten Minute.
func _auf_abgeschossen(art: int) -> void:
	if art == Flugziel.Art.BALLON:
		_ballons += 1
		_anzeige_auffrischen()
		return

	_abschuesse += 1
	_anzeige_auffrischen()
	if _geschafft:
		return
	if _abschuesse >= ZIEL_ABSCHUESSE:
		_geschafft = true
		GameState.zeige_nachricht("Fünf abgeschossen – Rückflug!", 3.0)
		# Es gibt kein Zielportal: Der Zähler löst den Abschluss aus.
		# `_auf_level_geschafft()` meldet das Level dem Spielfluss und
		# schickt nach ein paar Sekunden zurück in den Portalraum.
		_auf_level_geschafft()
		return
	GameState.zeige_nachricht("Doppeldecker %d von %d"
			% [_abschuesse, ZIEL_ABSCHUESSE], 1.4)


## Ein Ballon ist geplatzt: Früchte fallen aus dem Korb.
##
## `Frucht.streuen()` gibt jeder Frucht einen kurzen Wurfbogen und lässt
## sie danach an Ort und Stelle schweben. In der Luft ist genau das
## richtig: Eine Frucht, die weiterfiele, wäre nach zwei Sekunden 40 m
## tiefer und für einen Doppeldecker nicht mehr erreichbar.
func _auf_belohnung(ort: Vector3) -> void:
	Frucht.streuen(objekte, ort, 5)


## Vier Fruchtringe, durch die man hindurchfliegt.
##
## Sie sind keine Aufgabe, sondern eine Einladung: Ein Ring im Dunst sagt
## „hier ist noch Luftraum" und führt den Blick in eine Ecke, in die man
## sonst nicht flöge. Und sie sind das Einzige, was diesem Level einen
## Sammelwert gibt – Kisten gibt es hier keine.
func _ringe_setzen() -> void:
	var ringe := [
		[Vector3(0, 28, -46), Vector3(0, 0, 1), 5.0],
		[Vector3(-40, 36, 8), Vector3(1, 0, 0), 6.0],
		[Vector3(34, 24, 30), Vector3(0.7, 0.2, 0.7), 5.5],
		[Vector3(10, 46, 40), Vector3(0.3, -0.3, 1.0), 6.5],
	]
	for eintrag in ringe:
		var mitte: Vector3 = eintrag[0]
		var achse: Vector3 = (eintrag[1] as Vector3).normalized()
		var radius: float = eintrag[2]
		# Zwei Achsen quer zur Ringachse aufspannen.
		var hilfs := Vector3.UP if absf(achse.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var a := achse.cross(hilfs).normalized()
		var b := achse.cross(a).normalized()
		for i in 10:
			var w := TAU * float(i) / 10.0
			var f := Frucht.FRUCHT_SZENE.instantiate() as Frucht
			objekte.add_child(f)
			f.global_position = mitte + (a * cos(w) + b * sin(w)) * radius


# =========================================================== Kulisse

## Das Wolkenmeer.
##
## Drei Lagen mit verschiedener Aufgabe:
##   DECKE  bei 2 bis 8 m – ein geschlossenes Feld unter dem Luftraum.
##          Es sagt „du bist hoch oben", ohne dass man den Boden sähe.
##   BÄNKE  im Luftraum selbst. Sie haben keine Kollision; man fliegt
##          hindurch, und für eine Sekunde ist alles weiß. Das ist die
##          eigentliche Antwort auf „durchquert, aber nicht überblickt".
##   FETZEN hoch oben, dünn verteilt, damit die Decke nach oben nicht
##          plötzlich aufhört.
##
## Alles in EINEM Netz. Ein Ballen aus fünf Kugeln, hundert Ballen –
## einzeln gesetzt wären das hundert Zeichenaufrufe für Deko, die nie
## im Vordergrund steht.
func _wolken_bauen() -> void:
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 2201
	var st := PropWerkzeug.bauer()

	# --- Wolkendecke unter dem Luftraum ---
	for i in 56:
		var winkel := wuerfel.randf() * TAU
		var weite := sqrt(wuerfel.randf()) * 240.0
		_wolkenballen(st, wuerfel, Vector3(cos(winkel) * weite,
				wuerfel.randf_range(0.0, 9.0), sin(winkel) * weite),
				wuerfel.randf_range(9.0, 22.0))

	# --- Bänke im Luftraum: die Sichtbrecher ---
	for i in 20:
		var ort := Vector3(
				wuerfel.randf_range(-52.0, 52.0),
				wuerfel.randf_range(14.0, 50.0),
				wuerfel.randf_range(-52.0, 52.0))
		_wolkenballen(st, wuerfel, ort, wuerfel.randf_range(5.0, 11.0))

	# --- Fetzen darüber ---
	for i in 14:
		var winkel := wuerfel.randf() * TAU
		var weite := 30.0 + wuerfel.randf() * 130.0
		_wolkenballen(st, wuerfel, Vector3(cos(winkel) * weite,
				wuerfel.randf_range(56.0, 84.0), sin(winkel) * weite),
				wuerfel.randf_range(7.0, 16.0))

	var stoff := Materialbibliothek.einfarbig(WOLKE, 1.0)
	# Wolken werfen keinen Schatten: Zweiundhundert Kugeln in den
	# Schattenkarten kosten mehr, als ein Fleck auf einer Wolke einbringt –
	# und unter ihnen liegt ohnehin nur wieder Wolke.
	var knoten := PropWerkzeug.mesh_knoten("Wolken", PropWerkzeug.fertig(st),
			stoff, false)
	if knoten != null:
		deko.add_child(knoten)


## Ein Wolkenballen: vier bis sechs abgeflachte Kugeln ineinander.
func _wolkenballen(st: SurfaceTool, wuerfel: RandomNumberGenerator,
		mitte: Vector3, breite: float) -> void:
	var teile := wuerfel.randi_range(4, 6)
	for i in teile:
		var r := breite * wuerfel.randf_range(0.28, 0.5)
		var versatz := Vector3(
				wuerfel.randf_range(-breite, breite) * 0.5,
				wuerfel.randf_range(-0.18, 0.22) * breite,
				wuerfel.randf_range(-breite, breite) * 0.5)
		# Flach gedrückt – eine Kugelwolke sieht aus wie ein Wattebausch,
		# eine gestauchte wie ein Haufenwölkchen.
		PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(r, 7, 4),
				Transform3D(Basis.IDENTITY.scaled(Vector3(1.25, 0.6, 1.25)),
						mitte + versatz))


## Die Schneeberge unter dem Wolkenmeer.
##
## `horizont()` gibt es hier nicht – das Bauteil gehört zu `KorridorLevel`
## und braucht einen Verlauf, um sich zu setzen. Und es wäre auch das
## falsche Werkzeug: Es baut EINEN Zackenring in zwei Lagen, also eine
## Kulisse für den Blick nach vorn. Hier schaut man in alle Richtungen und
## vor allem nach unten.
##
## Deshalb einzelne Kegel, in zwei Ringen und mit stark streuender Höhe.
## Zwei Netze: Fels und Schneekappe. Der Schnee sitzt OBEN AUF dem Fels,
## er ist nicht der Fels – dieselbe Regel wie an den Schluchtwänden.
func _berge_bauen() -> void:
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 2202
	var fels := PropWerkzeug.bauer()
	var schnee := PropWerkzeug.bauer()

	for i in 46:
		# Zwei Ringe: die nahen Gipfel ragen ins Bild, die fernen füllen
		# den Horizont.
		var nah := i % 3 != 0
		var weite := wuerfel.randf_range(175.0, 265.0) if nah \
				else wuerfel.randf_range(300.0, 470.0)
		var winkel := TAU * float(i) / 46.0 + wuerfel.randf_range(-0.06, 0.06)
		var fuss := -84.0
		var hoehe := wuerfel.randf_range(60.0, 116.0) * (1.0 if nah else 1.6)
		var breite := hoehe * wuerfel.randf_range(0.6, 1.0)
		var ort := Vector3(cos(winkel) * weite, fuss + hoehe * 0.5,
				sin(winkel) * weite)
		PropWerkzeug.anfuegen(fels,
				PropWerkzeug.stumpf(breite, breite * 0.12, hoehe, 5),
				Transform3D(Basis(Vector3.UP, wuerfel.randf() * TAU), ort))
		# Die Kappe: das oberste Drittel, eine Spur breiter als der Fels
		# darunter, damit keine Fuge klafft.
		var kappe := hoehe * wuerfel.randf_range(0.16, 0.28)
		PropWerkzeug.anfuegen(schnee,
				PropWerkzeug.stumpf(breite * (kappe / hoehe) * 1.06, 0.0,
						kappe, 5),
				Transform3D(Basis(Vector3.UP, wuerfel.randf() * TAU),
						ort + Vector3.UP * (hoehe * 0.5 - kappe * 0.5)))

	var fels_knoten := PropWerkzeug.mesh_knoten("Berge",
			PropWerkzeug.fertig(fels),
			Materialbibliothek.einfarbig(BERGFELS, 0.95), false)
	if fels_knoten != null:
		deko.add_child(fels_knoten)
	var schnee_knoten := PropWerkzeug.mesh_knoten("Gipfelschnee",
			PropWerkzeug.fertig(schnee),
			Materialbibliothek.einfarbig(BERGSCHNEE, 0.9), false)
	if schnee_knoten != null:
		deko.add_child(schnee_knoten)

	# Ein Firnfeld ganz unten schließt den Blick nach unten ab. Ohne es
	# sieht man zwischen den Bergen in den leeren Hintergrund.
	var feld := PlaneMesh.new()
	feld.size = Vector2(1200.0, 1200.0)
	var boden := MeshInstance3D.new()
	boden.name = "Firnfeld"
	boden.mesh = feld
	boden.material_override = Materialbibliothek.einfarbig(
			BERGSCHNEE.darkened(0.28), 0.95)
	boden.position = Vector3(0.0, -88.0, 0.0)
	boden.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deko.add_child(boden)


# =========================================================== Anzeige

## Zielzähler und Trefferanzeige.
##
## Das übliche HUD taugt hier nicht: Es zeigt Früchte, Leben und Kisten,
## und von den dreien sagt keines, wie weit der Auftrag gediehen ist.
## Kisten gibt es in diesem Level überhaupt nicht, die Anzeige stünde
## also dauerhaft auf 0/0.
##
## Die Tafel liegt oben RECHTS: Links sitzt schon das HUD.
##
## Gebaut wird sie hier im Level und nicht als eigene Szene – sie zeigt
## zwei Zeilen und hat keinen anderen Nutzer. Sobald ein zweites
## Flugniveau danebensteht, gehört sie nach `scenes/ui/`.
func _anzeige_bauen() -> void:
	var tafel := CanvasLayer.new()
	tafel.name = "Flugtafel"
	tafel.layer = 2
	add_child(tafel)

	var flaeche := Control.new()
	flaeche.name = "Anzeige"
	flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tafel.add_child(flaeche)

	_zeile_ziel = _zeile(flaeche, 14.0, 34)
	_zeile_panzer = _zeile(flaeche, 58.0, 26)
	_anzeige_auffrischen()


func _zeile(elternteil: Control, oben: float, groesse: int) -> Label:
	var l := Label.new()
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -340.0
	l.offset_right = -22.0
	l.offset_top = oben
	l.offset_bottom = oben + float(groesse) + 10.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", groesse)
	# Umriss statt Kasten: Vor hellem Dunst wie vor dunklem Berg lesbar,
	# ohne dass ein Balken ein Viertel des Himmels wegnimmt.
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 0.85))
	l.add_theme_color_override("font_color", ANZEIGE_HELL)
	elternteil.add_child(l)
	return l


func _anzeige_auffrischen() -> void:
	if _zeile_ziel != null:
		_zeile_ziel.text = "Abgeschossen  %d / %d" % [_abschuesse, ZIEL_ABSCHUESSE]
		_zeile_ziel.add_theme_color_override("font_color",
				BALLON_GELB if _geschafft else ANZEIGE_HELL)
	if _zeile_panzer == null:
		return
	var rest := _flieger.panzer_rest if _flieger != null else 0
	var gesamt := _flieger.panzerung if _flieger != null else 0
	# Punkte statt Zahlen: Wie viel noch übrig ist, liest man im Flug
	# schneller an einer Reihe ab als an einer Ziffer.
	var balken := ""
	for i in gesamt:
		balken += "•" if i < rest else "·"
	var ballon_text := ""
	if _ballons_gesamt > 0:
		ballon_text = "     Ballons %d / %d" % [_ballons, _ballons_gesamt]
	_zeile_panzer.text = "%s%s" % [balken, ballon_text]
	_zeile_panzer.add_theme_color_override("font_color",
			ANZEIGE_WARNUNG if rest <= 1 else ANZEIGE_MATT)


func _auf_panzerung(_rest: int, _gesamt: int) -> void:
	_anzeige_auffrischen()
