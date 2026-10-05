extends LevelBasis
class_name KorridorLevel
## Gemeinsame Grundlage der Korridor-Level (Level 02 aufwärts).
##
## `LevelBasis` kümmert sich um Kamera, Kistenzähler und Portalsignal.
## Diese Schicht darüber bündelt, was jedes Korridorlevel sonst noch
## gleich macht: Objekte relativ zum Verlauf setzen, dabei die Wegbreite
## an der Stelle beachten, Lücken markieren und unter dem Weg eine
## Absturzzone spannen.
##
## Ein abgeleitetes Level liefert dafür drei Angaben:
##   abschnitte()     – Bodenstreifen wie in `LevelWerkzeuge.korridor()`
##   ende()           – Länge der Strecke in Metern
##   absturz_hoehe()  – ab hier abwärts ist der Sturz tödlich
##
## Die Abschnittsliste ist die einzige Quelle für die Wegbreite: `breite_bei()`
## liest sie aus, damit Objekte nie neben dem Weg landen.
##
## Level 01 ist bewusst nicht umgestellt – es läuft und ist geprüft;
## ein Umbau wäre reines Risiko ohne Gewinn.
##
## WEGDATEN (Raum 1, Baukasten-Paket G1). Ein Level kann statt der bloßen
## Abschnittsliste `weg` setzen: die Daten des Weges im Schema von Level 01
## samt Terrassenhöhen, Begehbarem, Leitlinien und Todeszonen
## (`scripts/gemeinsam/wegdaten.gd`). Dann fragen `abschnitte()`,
## `breite_bei()`, `rand_bei()` und `weg_von_der_kante()` dort nach, und die
## Helfer `*_auf()` stellen Kisten, Früchte, Gegner und Portale auf die
## Wegdecke statt auf die Kurve. NULL-PFAD: Die Level 02–25 setzen `weg`
## nie – für sie läuft jede dieser Funktionen genau wie vorher.

const KISTE := preload("res://scenes/crates/Kiste.tscn")
const FRUCHT := preload("res://scenes/fruits/Frucht.tscn")
const WASSER := preload("res://scenes/hazards/Wasser.tscn")
const STACHELN := preload("res://scenes/hazards/Stacheln.tscn")
const WASSERPLATTFORM := preload("res://scenes/props/Wasserplattform.tscn")
const BRUCHPLATTE := preload("res://scenes/props/Bruchplatte.tscn")
const TAKTFLAECHE := preload("res://scenes/hazards/Taktflaeche.tscn")
const FEUERSPEIER := preload("res://scenes/hazards/Feuerspeier.tscn")
const LASERZAUN := preload("res://scenes/hazards/Laserzaun.tscn")
const ROLLHINDERNIS := preload("res://scenes/hazards/Rollhindernis.tscn")
const AUSLOESEPLATTE := preload("res://scenes/props/Ausloeseplatte.tscn")
const SCHLIESSTUER := preload("res://scenes/props/Schliesstuer.tscn")
const DECKUNGSFLECK := preload("res://scenes/props/Deckungsfleck.tscn")
const DREHPLATTFORM := preload("res://scenes/props/Drehplattform.tscn")
const FLIESSBAND := preload("res://scenes/props/Fliessband.tscn")
const SCHIEBEBLOCK := preload("res://scenes/props/Schiebeblock.tscn")
const HANGELGITTER := preload("res://scenes/props/Hangelgitter.tscn")
const HORIZONT := preload("res://scenes/props/Horizont.tscn")
const LICHTKREIS := preload("res://scenes/props/Lichtkreis.tscn")
const STIMMUNGSZONE := preload("res://scenes/props/Stimmungszone.tscn")
const TREIBMINE := preload("res://scenes/hazards/Treibmine.tscn")
const WERFER := preload("res://scenes/enemies/Werfer.tscn")
const SCHWARM := preload("res://scenes/enemies/Schwarm.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")

## Die Daten des Weges (siehe Kopf, WEGDATEN). Ein Level setzt sie, sobald
## der Verlauf steht und VOR allen Bauschritten, die etwas auf den Weg
## stellen. null = alter Weg über `abschnitte()`.
var weg: Wegdaten = null


# ------------------------------------------------------------- Haken

## Bodenstreifen des Weges: [{"von", "bis", "breite", "breite_ende"}].
## Mit `weg` die Abschnitte von dort.
func abschnitte() -> Array:
	if weg != null:
		return weg.abschnitte
	return []


## Gesamtlänge der Strecke in Metern.
func ende() -> float:
	return 0.0


## Höhe relativ zum Weg, ab der ein Sturz tödlich ist.
func absturz_hoehe() -> float:
	return -6.0


# ------------------------------------------------------------- Wegbreite

## Wegbreite an dieser Stelle, 0 in einer Lücke.
func breite_bei(strecke: float) -> float:
	if weg != null:
		return weg.breite_bei(strecke)
	for a in abschnitte():
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			var t := inverse_lerp(von, bis, strecke)
			return lerpf(a["breite"], a.get("breite_ende", a["breite"]), t)
	return 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func rand_bei(strecke: float, sicherheit: float = 1.3) -> float:
	if weg != null:
		return weg.rand_bei(strecke, sicherheit)
	return maxf(breite_bei(strecke) * 0.5 - sicherheit, 0.0)


## Schiebt eine Strecke vom Rand eines Abschnitts weg, damit Objekte nicht
## auf der Abbruchkante stehen. Mit `weg` zählt der Strang (gleich hoch
## anstoßende Abschnitte zusammen, nur Lücken und Stufen trennen), wie in
## Level 01 – sonst stünde ein Gegner an jeder bloßen Naht still.
func weg_von_der_kante(strecke: float, abstand: float) -> float:
	if weg != null:
		return weg.weg_von_der_kante(strecke, abstand)
	for a in abschnitte():
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			if bis - von <= abstand * 2.0:
				return (von + bis) * 0.5
			return clampf(strecke, von + abstand, bis - abstand)
	return strecke


# ------------------------------------------------------------- Bauteile

## Plattform relativ zum Verlauf, mit dem Weg mitgedreht.
func plattform(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, material: Material) -> StaticBody3D:
	var pos := LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	return LevelWerkzeuge.plattform(geometrie, pos, groesse, material,
			LevelWerkzeuge.drehung(verlauf, strecke))


# ------------------------------------------------------- Auf dem Wasser

## Treibfloß, das den Spieler von `von` nach `bis` trägt und zurückfährt.
##
## Es folgt dem Levelverlauf, dreht sich also mit dem Fluss mit. Die
## Rückfahrt ist Absicht und kein Zugeständnis: Wer den Absprung verpasst,
## wartet, statt neu anfangen zu müssen.
## `farbe` mit Alpha 0 heißt: Standardanstrich des Bauteils.
##
## Die Farbe MUSS durch diese Hilfe gehen, nicht nachträglich gesetzt
## werden: `Wasserplattform` baut ihre Optik in `_ready()`, und `_ready()`
## läuft beim `add_child()` hier drin. Was danach kommt, wirkt nicht mehr.
## Dasselbe gilt für jedes Prop, das sich selbst aufbaut.
func floss(von: float, bis: float, seitlich: float, hoehe: float,
		groesse: Vector2, fahrzeit: float, pause_a := 2.4,
		pause_b := 2.4, phase := 0.0,
		farbe := Color(0, 0, 0, 0)) -> Wasserplattform:
	var f := WASSERPLATTFORM.instantiate() as Wasserplattform
	f.farbe = farbe
	f.art = Wasserplattform.Art.FLOSS
	f.groesse = groesse
	f.verlauf = verlauf
	f.strecke_a = von
	f.strecke_b = bis
	f.seitlich_a = seitlich
	f.seitlich_b = seitlich
	f.hoehe = hoehe
	f.fahrzeit = fahrzeit
	f.pause_a = pause_a
	f.pause_b = pause_b
	f.phase = phase
	f.saat = int(von * 7.0) + 1
	objekte.add_child(f)
	return f


## Seerosenblatt als Trittstein. Steht still und wippt nur.
func seerose(strecke: float, seitlich: float, hoehe: float,
		durchmesser := 2.4, farbe := Color(0, 0, 0, 0)) -> Wasserplattform:
	var b := WASSERPLATTFORM.instantiate() as Wasserplattform
	b.farbe = farbe
	b.art = Wasserplattform.Art.SEEROSE
	b.groesse = Vector2(durchmesser, durchmesser)
	b.punkt_a = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	b.punkt_b = b.punkt_a
	b.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	b.wippen = 0.04
	b.phase = fmod(strecke, TAU)
	objekte.add_child(b)
	return b


## Wehrbohle, die im Takt untertaucht. Oben steht sie lange, unten kurz –
## sonst wäre die Stelle kein Rhythmus, sondern eine Wartezeit.
func wehrbohle(strecke: float, seitlich: float, oben: float, unten: float,
		phase: float, groesse := Vector2(3.4, 2.6),
		oben_zeit := 2.3, unten_zeit := 0.9,
		farbe := Color(0, 0, 0, 0)) -> Wasserplattform:
	var b := WASSERPLATTFORM.instantiate() as Wasserplattform
	b.farbe = farbe
	b.art = Wasserplattform.Art.BOHLE
	b.groesse = groesse
	b.punkt_a = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, oben)
	b.punkt_b = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, unten)
	b.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	b.fahrzeit = 0.75
	b.pause_a = oben_zeit
	b.pause_b = unten_zeit
	b.phase = phase
	b.wippen = 0.0
	objekte.add_child(b)
	return b


## Treibmine: Hindernis auf dem Wasser, nicht zu besiegen.
func treibmine(strecke: float, seitlich: float, hoehe: float,
		pendel := 0.0, dauer := 4.0, phase := 0.0,
		kette := 0.0, galgen_tiefe := 2.6) -> Treibmine:
	var m := TREIBMINE.instantiate() as Treibmine
	m.kette_hoehe = kette
	m.pendel_weite = pendel
	m.pendel_dauer = dauer
	m.phase = phase
	m.saat = int(strecke * 11.0) + 3
	m.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	# Quer zum Fluss pendeln, nicht mit ihm – sonst führe die Mine dem
	# Spieler davon, statt ihm den Weg zu verlegen.
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)
	m.pendel_achse = Vector3(cos(dreh), 0.0, -sin(dreh))
	objekte.add_child(m)
	if kette > 0.0:
		_aufhaengung(strecke, seitlich, hoehe + kette, dreh,
				kette + galgen_tiefe)
	return m


## Galgen aus Totholz, an dem eine Kette hängt: ein Querholz über der
## Rinne und ein Pfahl, der es trägt.
##
## Ohne ihn endet die Kette in der Luft, und die Mine sieht aus, als
## schwebe sie an einem Stock. Das Querholz sitzt genau am Aufhängepunkt,
## den `Treibmine` beim Kippen der Kette festhält; der Pfahl steht daneben
## und reicht bis unter die Wasserlinie.
func _aufhaengung(strecke: float, seitlich: float, hoehe: float,
		dreh: float, tiefe: float) -> void:
	const QUER_LAENGE := 4.6
	const PFAHL_VERSATZ := 1.9

	var st := PropWerkzeug.bauer()
	var quer := PropWerkzeug.stumpf(0.13, 0.17, QUER_LAENGE, 6, true)
	# Liegend und eine Spur schief – gebaut sieht zu ordentlich aus.
	PropWerkzeug.anfuegen(st, quer, Transform3D(
			Basis(Vector3.FORWARD, PI * 0.5 + 0.06), Vector3.ZERO))
	var pfahl := PropWerkzeug.stumpf(0.19, 0.15, tiefe, 6, true)
	PropWerkzeug.anfuegen(st, pfahl, Transform3D(Basis(),
			Vector3(PFAHL_VERSATZ, -tiefe * 0.5, 0.0)))

	var knoten := PropWerkzeug.mesh_knoten("Aufhaengung",
			PropWerkzeug.fertig(st), Materialbibliothek.rinde())
	if knoten == null:
		return
	knoten.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	knoten.rotation.y = dreh
	deko.add_child(knoten)


## Stachelbalken, der über dem Weg hängt: aufrecht kommt man nicht
## darunter durch, krabbelnd schon.
##
## `unterkante` ist die Höhe, unter der wieder Luft ist – gemessen vom
## Boden, auf dem der Spieler steht. Die aufrechte Kapsel ist 1,30 m
## hoch, die flache 0,76 m; alles dazwischen trennt Gehen von Krabbeln.
func stachelbalken(strecke: float, seitlich: float, unterkante: float,
		flaeche := Vector2(4.0, 1.1), dicke := 0.55) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = false
	st.stachel_hoehe = dicke
	# Die Gefahrzone reicht von `unterkante` bis `unterkante + dicke + 0,12`.
	# Wo sie schmal sein muss – etwa zwischen baumelnden und angezogenen
	# Beinen am Hangelgitter –, wird `dicke` kleiner gesetzt.
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
			unterkante + st.stachel_hoehe + 0.12)
	st.rotation = Vector3(0.0, LevelWerkzeuge.drehung(verlauf, strecke), PI)
	objekte.add_child(st)
	return st


# ------------------------------------------------------------- Taktgeber

## Beim Durchsehen von fünfzehn Vorbildleveln (doku/level-vorbilder.md) fiel
## auf: Zehn davon bauen ihre Schwierigkeit aus TAKT. Unsere Hindernisse
## standen bis dahin still oder patrouillierten. Die folgenden Bauteile
## schließen genau diese Lücke.
##
## Alle bauen ihre Optik in `_ready()` – jeder Wert muss deshalb VOR
## `add_child()` gesetzt sein, sonst kommt er zu spät (wie bei `stacheln()`).

## Plattform, die nach kurzer Frist wegbricht und wiederkommt.
func bruchplatte(strecke: float, seitlich: float, hoehe: float,
		groesse := Vector2(2.6, 2.6), warnzeit := 0.6) -> Bruchplatte:
	var b := BRUCHPLATTE.instantiate() as Bruchplatte
	b.groesse = groesse
	b.warnzeit = warnzeit
	b.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	# Saat aus der Strecke: Dieselbe Stelle wackelt bei jedem Anlauf gleich,
	# sonst wäre die Vorwarnung nicht erlernbar.
	b.saat = int(strecke * 13.0) + 1
	b.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	objekte.add_child(b)
	return b


## Reihe von Bruchplatten über eine Lücke.
##
## Der Regelfall – einzeln gesetzt driften die Abstände, und genau die sind
## hier die Aufgabe: Wer zu lange überlegt, steht auf der Platte, die schon
## fällt.
func bruchplatten_reihe(von: float, bis: float, anzahl: int,
		seitlich: float, hoehe: float,
		groesse := Vector2(2.6, 2.6)) -> Array[Bruchplatte]:
	var reihe: Array[Bruchplatte] = []
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		reihe.append(bruchplatte(lerpf(von, bis, t), seitlich, hoehe, groesse))
	return reihe


## Fläche, die im Takt tödlich wird. `senkrecht` macht daraus eine Wand.
func taktflaeche(strecke: float, seitlich: float, flaeche: Vector2,
		phase := 0.0, senkrecht := false, hoehe := 0.02) -> Taktflaeche:
	var t := TAKTFLAECHE.instantiate() as Taktflaeche
	t.flaeche = flaeche
	t.phase = phase
	t.senkrecht = senkrecht
	t.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	t.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(t)
	return t


## Folge von Taktflächen mit gleichmäßig versetzter Phase.
##
## Daraus entsteht die Welle, die vor dem Spieler herläuft – der eigentliche
## Zweck des Bauteils. Eine Reihe gleichphasiger Flächen wäre nur eine
## größere Fläche.
func taktwelle(von: float, bis: float, anzahl: int, seitlich: float,
		flaeche := Vector2(3.0, 3.0),
		versatz_je_platte := 0.25) -> Array[Taktflaeche]:
	var welle: Array[Taktflaeche] = []
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		welle.append(taktflaeche(lerpf(von, bis, t), seitlich, flaeche,
				fposmod(float(i) * versatz_je_platte, 1.0)))
	return welle


## Feuerstoß im Takt. `richtung` in Grad zusätzlich zur Wegrichtung;
## 0 heißt: Flamme quer über den Weg.
func feuerspeier(strecke: float, seitlich: float, hoehe: float,
		richtung := 0.0, laenge := 3.0, phase := 0.0,
		schwenkt := false) -> Feuerspeier:
	var f := FEUERSPEIER.instantiate() as Feuerspeier
	f.laenge = laenge
	f.phase = phase
	f.schwenkt = schwenkt
	f.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	f.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke) + deg_to_rad(richtung)
	objekte.add_child(f)
	return f


## Laserzaun quer über den Weg.
##
## `wandernd` ist die interessantere Betriebsart: Es fehlt immer nur EIN
## Strahl, und die Lücke wandert – mal muss man krabbeln, mal springen.
func laserzaun(strecke: float, breite := 4.0, wandernd := true,
		takt := 2.0, phase := 0.0) -> Laserzaun:
	var l := LASERZAUN.instantiate() as Laserzaun
	l.breite = breite
	l.art = Laserzaun.Art.WANDERND if wandernd else Laserzaun.Art.GLEICHZEITIG
	l.takt = takt
	l.phase = phase
	l.position = LevelWerkzeuge.punkt(verlauf, strecke, 0.0, 0.0)
	l.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(l)
	return l


## Rollender Brocken, der dem Weg folgt.
## Rollender Brocken, der dem Weg folgt.
##
## `auf_abruf` und `farbe` müssen VOR dem Einhängen gesetzt sein: Das Prop
## baut seine Optik in `_ready()`, und der Helfer hängt es sofort ein.
## Beide Werte nachträglich zu setzen wirkt nicht mehr auf das Aussehen –
## ein Agent musste sich deshalb mit einem eigenen Fass behelfen.
func rollbrocken(von: float, bis: float, seitlich := 0.0, hoehe := 0.0,
		radius := 1.1, tempo := 9.0, pause := 2.0, phase := 0.0,
		art := Rollhindernis.Art.KUGEL, auf_abruf := false,
		farbe := Color(0, 0, 0, 0)) -> Rollhindernis:
	var r := ROLLHINDERNIS.instantiate() as Rollhindernis
	r.art = art
	r.auf_abruf = auf_abruf
	if farbe.a > 0.0:
		r.farbe = farbe
	r.verlauf = verlauf
	r.strecke_von = von
	r.strecke_bis = bis
	r.seitlich = seitlich
	r.hoehe = hoehe
	r.radius = radius
	r.tempo = tempo
	r.pause = pause
	r.phase = phase
	r.saat = int(von * 7.0) + 5
	objekte.add_child(r)
	return r


## Bodenplatte, die beim Betreten etwas auslöst.
##
## `ziele` wird erst NACH `add_child` in Pfade übersetzt: `get_path_to()`
## braucht beide Knoten im selben Baum.
func ausloeseplatte(strecke: float, seitlich := 0.0,
		flaeche := Vector2(2.4, 2.4), nachlauf := 0.6, einmalig := false,
		ziele: Array[Node] = []) -> Ausloeseplatte:
	var a := AUSLOESEPLATTE.instantiate() as Ausloeseplatte
	a.flaeche = flaeche
	a.nachlauf = nachlauf
	a.einmalig = einmalig
	a.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	a.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(a)
	var pfade: Array[NodePath] = []
	for z in ziele:
		if z != null and z.is_inside_tree():
			pfade.append(a.get_path_to(z))
	a.zielpfade = pfade
	return a


## Tor, das sich im Takt schließt. Es blockiert, es tötet nicht.
func schliesstuer(strecke: float, seitlich := 0.0, breite := 3.6,
		hoehe := 2.8, offen := 2.0, zu := 1.0,
		phase := 0.0, farbe := Color(0, 0, 0, 0)) -> Schliesstuer:
	var t := SCHLIESSTUER.instantiate() as Schliesstuer
	if farbe.a > 0.0:
		t.farbe = farbe
	t.breite = breite
	t.hoehe = hoehe
	t.offen_zeit = offen
	t.zu_zeit = zu
	t.phase = phase
	t.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	t.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(t)
	return t


# ------------------------------------------------------- Bewegte Böden

## Drehscheibe. `hoehe` ist die Trittfläche, nicht die Mitte des Körpers.
##
## Der Reiz des Vorbilds liegt darin, dass darauf oft ein Gegner steht:
## `aufsetzen()` hängt ihn ein. Wichtig dabei – `Gegner` patrouilliert in
## Weltkoordinaten, ein aufgesetzter braucht also `patrouille_weite = 0.0`.
func drehscheibe(strecke: float, seitlich: float, hoehe: float,
		durchmesser := 3.6, tempo := 30.0, richtung := 1,
		pausiert_bei := 0.0, pausenzeit := 0.0,
		kippt := false, phase := 0.0, saeule := 1.6,
		kipp_winkel := 12.0, steinfarbe := Color(0, 0, 0, 0),
		markenfarbe := Color(0, 0, 0, 0)) -> Drehplattform:
	var d := DREHPLATTFORM.instantiate() as Drehplattform
	d.groesse = Vector2(durchmesser, durchmesser)
	d.tempo = tempo
	d.richtung = richtung
	d.pausiert_bei = pausiert_bei
	d.pausenzeit = pausenzeit
	d.kippt = kippt
	d.phase = phase
	d.saeule = saeule
	d.kipp_winkel = kipp_winkel
	if steinfarbe.a > 0.0:
		d.steinfarbe = steinfarbe
	if markenfarbe.a > 0.0:
		d.markenfarbe = markenfarbe
	# `position`, NICHT `ort`: Die Scheibe ist ein `AnimatableBody3D` mit
	# `sync_to_physics`. Ihr Platz muss beim Erzeugen im Physikserver
	# stehen – wird sie am Nullpunkt eingehängt und erst danach gestellt,
	# zieht der Server sie im ersten Bild dorthin zurück, und ein mit
	# `aufsetzen()` aufgesetzter Gegner merkt sich genau diesen Nullpunkt
	# als Patrouillenmitte. `_ready()` übernimmt `ort` aus `position`.
	# Derselbe Fehler wie seinerzeit bei den Flößen.
	d.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
			hoehe - Drehplattform.DECK_STAERKE * 0.5)
	objekte.add_child(d)
	return d


## Fließband über die Strecke `von`..`bis`. `hoehe` ist die Trittfläche.
##
## Es trägt den Spieler nicht dadurch, dass sich der Körper bewegt – das
## war der erste Versuch und ging schief: Godot wertet die Bodengeschwindig-
## keit in beide Richtungen aus, und der Rücksprung riss die Figur genau um
## den gewonnenen Weg zurück. Das Band steht still und schiebt aktiv.
func laufband(von: float, bis: float, seitlich: float, hoehe: float,
		breite := 3.0, tempo := 2.5, richtung := 1) -> Fliessband:
	var mitte := (von + bis) * 0.5
	var f := FLIESSBAND.instantiate() as Fliessband
	f.groesse = Vector2(breite, absf(bis - von))
	f.tempo = tempo
	f.richtung = richtung
	f.drehung = LevelWerkzeuge.drehung(verlauf, mitte)
	f.ort = LevelWerkzeuge.punkt(verlauf, mitte, seitlich, hoehe)
	objekte.add_child(f)
	return f


## Block, der quer über den Weg fährt und schiebt.
##
## Zwischen Endstellung und nächster Wand gehört mindestens ein Meter Luft,
## sonst ist der Block eine Sackgasse statt eines Hindernisses.
func schiebeblock(strecke: float, seitlich: float, hoehe: float,
		groesse := Vector3(1.6, 1.1, 1.6), weite := 3.0, quer := true,
		fahrzeit := 1.4, pause := 1.0, phase := 0.0) -> Schiebeblock:
	var b := SCHIEBEBLOCK.instantiate() as Schiebeblock
	b.groesse = groesse
	b.weite = weite
	b.achse = Vector3.RIGHT if quer else Vector3.FORWARD
	b.fahrzeit = fahrzeit
	b.pause = pause
	b.phase = phase
	b.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	b.ort = LevelWerkzeuge.punkt(verlauf, strecke, seitlich,
			hoehe + groesse.y * 0.5)
	objekte.add_child(b)
	return b


# ------------------------------------------------------- Gegner mit Eigenart

## Werfer: steht fest und wirft im Bogen. Keine Patrouille.
func werfer(strecke: float, seitlich: float,
		art := Geschoss.Art.STAMM) -> Werfer:
	strecke = weg_von_der_kante(strecke, 2.5)
	var grenze := rand_bei(strecke)
	var w := WERFER.instantiate() as Werfer
	w.geschossart = art
	w.patrouille_weite = 0.0
	w.position = LevelWerkzeuge.punkt(verlauf, strecke,
			clampf(seitlich, -grenze, grenze), 0.0)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	return w


## Schwarm: verfolgt als Gruppe und fällt als Gruppe.
##
## Bewusst in die Wegmitte, nicht an den Rand: Beim Heimkehren hinge er
## sonst über der Abbruchkante.
func schwarm(strecke: float, seitlich := 0.0,
		reichweite := 9.0) -> Schwarm:
	strecke = weg_von_der_kante(strecke, 2.5)
	var grenze := rand_bei(strecke, 2.0)
	var s := SCHWARM.instantiate() as Schwarm
	s.reichweite = reichweite
	s.patrouille_weite = 0.0
	s.position = LevelWerkzeuge.punkt(verlauf, strecke,
			clampf(seitlich, -grenze, grenze), 0.0)
	objekte.add_child(s)
	return s


# ------------------------------------------------------- Deckung und Licht

## Stelle, an der man geduckt sicher ist. Nutzt unser Krabbeln.
## `hoehe` ist der Abstand über dem Weg, `am_weg = false` hebt die
## Begrenzung auf die Wegbreite auf.
##
## Ohne das ließe sich kein Fleck auf eine Insel neben dem Weg legen –
## die Klemmung zöge ihn zurück auf den Weg, und der schönste Einfall des
## Dschungellevels (Deckung suchen heißt: erst einmal hinüberspringen)
## wäre nicht baubar. Gemeldet aus Level 18, das sich dafür eine eigene
## Hilfe schrieb.
func deckungsfleck(strecke: float, seitlich: float,
		radius := 1.6, hoehe := 0.02,
		am_weg := true) -> Deckungsfleck:
	var d := DECKUNGSFLECK.instantiate() as Deckungsfleck
	d.radius = radius
	if am_weg:
		strecke = weg_von_der_kante(strecke, 2.0)
		var grenze := rand_bei(strecke, radius)
		seitlich = clampf(seitlich, -grenze, grenze)
	d.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	objekte.add_child(d)
	return d


## Macht aus dem Level ein Dunkellevel.
##
## MUSS nach allen `kiste()`- und `frucht()`-Aufrufen kommen: Der
## Leuchtmarker geht den fertigen Baum durch und kann nur markieren, was
## schon dasteht. Und es gilt die Regel aus dem Kopf von `Lichtkreis`:
## keine Lücke breiter, als das Licht reicht, und keine Verzweigung.
func dunkelheit(reichweite := 7.0, restlicht := 0.06) -> Lichtkreis:
	var l := LICHTKREIS.instantiate() as Lichtkreis
	l.reichweite = reichweite
	l.restlicht = restlicht
	add_child(l)
	_leuchtmarker_setzen()
	# Nach einem Tod baut `LevelBasis` Kisten und Früchte aus dem Bauplan
	# NEU auf. Die frischen Knoten wissen nichts von der Markierung –
	# ohne dieses Nachziehen stünde ab dem ersten Tod ein stockdunkler
	# Gang voller unsichtbarer Kisten. Gefunden beim Bau von Level 23.
	if not GameState.level_zuruecksetzen.is_connected(_leuchtmarker_nachziehen):
		GameState.level_zuruecksetzen.connect(_leuchtmarker_nachziehen)
	return l


## Markiert Kisten und Früchte. Mehrfaches Aufrufen kostet nichts:
## `Leuchtmarker` setzt ein Merkzeichen und überspringt Markiertes.
func _leuchtmarker_setzen() -> void:
	var markiert := Leuchtmarker.markieren(self, ["kisten", "fruechte"], 1.4)
	print("Dunkellevel: %d Marker leuchten selbst" % markiert)


## Wartet ein Bild ab, BEVOR neu markiert wird.
##
## `dunkelheit()` läuft als Bauschritt, also noch in `_aufbauen()` –
## `LevelBasis` hängt sich erst danach an dasselbe Signal. Diese
## Verbindung steht damit VOR dem Neuaufbau in der Reihe: Ohne das
## abgewartete Bild markierte sie die alten Knoten ein zweites Mal und
## die neuen gar nicht.
func _leuchtmarker_nachziehen(_von_vorn: bool) -> void:
	await get_tree().process_frame
	if is_instance_valid(self) and is_inside_tree():
		_leuchtmarker_setzen()


## Gitter unter der Decke, an dem sich die Figur entlanghangelt.
func hangelgitter(strecke: float, seitlich := 0.0, hoehe := 3.2,
		laenge := 8.0, breite := 2.0) -> Hangelgitter:
	var g := HANGELGITTER.instantiate() as Hangelgitter
	g.laenge = laenge
	g.breite = breite
	g.hoehe = hoehe
	g.drehung = LevelWerkzeuge.drehung(verlauf, strecke)
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	objekte.add_child(g)
	return g


## Ändert Licht und Nebel über einen Abschnitt hinweg.
##
## In Stücken wie `kamerazone()`, weil ein einzelner Kasten einem kurvigen
## Weg nicht folgt. Alpha 0 bzw. ein negativer Wert heißt: Grundstimmung
## des Levels behalten.
func stimmung(von: float, bis: float, nebelfarbe := Color(0, 0, 0, 0),
		nebeldichte := -1.0, umgebungslicht := -1.0,
		umgebungsfarbe := Color(0, 0, 0, 0), breite := 40.0) -> void:
	var schritt := 14.0
	var s := von
	while s < bis:
		var laenge := minf(schritt, bis - s)
		var z := STIMMUNGSZONE.instantiate() as Stimmungszone
		z.nebelfarbe = nebelfarbe
		z.nebeldichte = nebeldichte
		z.umgebungslicht = umgebungslicht
		z.umgebungsfarbe = umgebungsfarbe
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(breite, 24.0, laenge)
		form.shape = box
		z.add_child(form)
		z.position = LevelWerkzeuge.punkt(verlauf, s + laenge * 0.5, 0.0, 6.0)
		z.rotation.y = LevelWerkzeuge.drehung(verlauf, s + laenge * 0.5)
		geometrie.add_child(z)
		s += laenge


## Ferne Hügelkette rings um das Level.
##
## Für jedes Level ohne Schluchtwände Pflicht: Sonst endet die Welt an einer
## kerzengeraden Linie. Der Radius muss größer sein als der halbe
## Levelverlauf, sonst steht die Kette dem Spieler am Ende vor der Nase.
func horizont(radius: float, hoehe: float, farbe_nah: Color,
		farbe_fern: Color, mit_boden := false,
		fuss := -6.0) -> Horizont:
	var h := HORIZONT.instantiate() as Horizont
	h.radius = maxf(radius, ende() * 0.6)
	h.hoehe = hoehe
	h.zacken = clampi(int(radius / 4.5), 24, 96)
	h.farbe_nah = farbe_nah
	h.farbe_fern = farbe_fern
	h.boden = mit_boden
	h.fuss = fuss
	h.position = LevelWerkzeuge.punkt(verlauf, ende() * 0.5, 0.0, 0.0)
	deko.add_child(h)
	return h


## Start- und Zielportal an den beiden Enden der Strecke.
func portale_setzen(start: float = 1.0, ziel_vor_ende: float = 4.0) -> void:
	var a := STARTPORTAL.instantiate()
	a.position = LevelWerkzeuge.punkt(verlauf, start, 0.0, 0.1)
	a.rotation.y = LevelWerkzeuge.drehung(verlauf, start)
	objekte.add_child(a)

	var s := ende() - ziel_vor_ende
	var z := ZIELPORTAL.instantiate()
	z.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, 0.1)
	z.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
	objekte.add_child(z)


## Kiste auf den Weg setzen.
##
## `schwebt = true` sagt: Diese Kiste steht ABSICHTLICH in der Luft – sie
## ist selbst der Boden, etwa als Stufe einer Kistentreppe über einer
## Lücke. Das Prüfwerkzeug meldet eine Kiste ohne Boden darunter sonst als
## Fehler, und es hat recht damit: In neun von zehn Fällen ist das ein
## Versehen. Absicht muss deshalb dastehen, statt geraten zu werden.
func kiste(art: Kiste.Art, strecke: float, seitlich: float,
		hoehe: float = 0.5, schwebt := false) -> Kiste:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	if schwebt:
		k.add_to_group("schwebende_kisten")
	k.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	k.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(k)
	return k


## Setzt einen Gegner so, dass er beim Patrouillieren nicht vom Weg läuft:
## seitlicher Versatz und Weite werden auf die Wegbreite an dieser Stelle
## begrenzt, die Strecke von der Abbruchkante weggeschoben.
## `hoehe` ist der Abstand über dem Weg – für einen Gegner, der auf einer
## Plattform steht. Er MUSS hier durch: `Gegner` friert in `_ready()`
## seine Startposition ein und hält die Patrouille auf deren Höhe fest,
## nachträgliches Verschieben zieht ihn beim ersten Schritt wieder
## herunter. Gemeldet aus Level 21, das sich dafür eine eigene Hilfe baute.
## Ortsfarben für alle Gegner dieses Levels, als {Eigenschaftsname: Color}.
##
## Unser Bestiarium besteht aus acht Tieren aus Wald, Sumpf und Eis, die
## fünfzehn Level bespielen – in der Raumstation lief ein Schneewiesel, im
## ägyptischen Grab eine Gletscherkrabbe. Neue Gegner zu bauen ist teuer;
## sie an den Ort anzupassen kostet eine Zeile. Namen, die ein Gegner nicht
## kennt, werden übergangen, ein Satz gilt also für ein ganzes Level.
##
## Die Zeichensprache aus `gegner.gd` bleibt bindend: Die Stelle, an der ein
## Angriff wirkt, muss hell abgesetzt bleiben. Wer umfärbt, prüft das im Bild.
var gegner_faerbung := {}


func gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool, hoehe := 0.05) -> Gegner:
	var g := szene.instantiate() as Gegner
	strecke = weg_von_der_kante(strecke, 2.5)
	var rand := rand_bei(strecke)
	if quer:
		seitlich = clampf(seitlich, -rand * 0.5, rand * 0.5)
		weite = minf(weite, maxf(rand - absf(seitlich), 0.5))
	else:
		seitlich = clampf(seitlich, -rand, rand)
		# Entlang des Weges: Weite so kürzen, dass beide Enden auf dem Weg liegen
		var frei := 99.0
		if weg != null:
			# Mit Wegdaten der Strang wie in `weg_von_der_kante` (level01.gd:1200).
			var strang := weg.strang_bei(strecke)
			frei = minf(strecke - strang.x, strang.y - strecke) - 1.0
		else:
			for a in abschnitte():
				if strecke >= a["von"] and strecke <= a["bis"]:
					frei = minf(strecke - a["von"], a["bis"] - strecke) - 1.0
		weite = minf(weite, maxf(frei, 0.5))
	# Ortsfarben VOR dem Einhängen: Die Gegner bauen ihre Optik in `_ready()`,
	# und ein Umfärben danach wirft sie neu auf. Siehe `gegner_faerbung`.
	for name in gegner_faerbung:
		if name in g:
			g.set(name, gegner_faerbung[name])
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized() if quer else richtung
	# Position VOR add_child setzen: die Gegner merken sich in _ready()
	# ihre Startposition für die Patrouille.
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


func frucht(strecke: float, seitlich: float, hoehe: float = 0.9) -> Node3D:
	var f := FRUCHT.instantiate()
	f.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	objekte.add_child(f)
	return f


func fruechte_reihe(von: float, bis: float, anzahl: int,
		seitlich: float, hoehe: float = 0.9) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		frucht(lerpf(von, bis, t), seitlich, hoehe)


## Bogen aus Früchten über eine Lücke – belohnt den Sprung mit Höhe.
func fruechte_bogen(von: float, bis: float, anzahl: int, seitlich: float,
		scheitel: float = 2.6) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		frucht(lerpf(von, bis, t), seitlich, 0.9 + sin(t * PI) * scheitel)


func wasser(strecke: float, flaeche: Vector2, hoehe: float,
		seitlich: float = 0.0) -> Wasser:
	var w := WASSER.instantiate() as Wasser
	w.flaeche = flaeche
	w.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	return w


## `farbe` mit Alpha 0 = Vorgabe des Stachelfelds (rostiges Eisen).
## Die Farbe muss VOR `add_child` stehen: Das Feld baut seine Zacken in
## `_ready()`, ein späteres Setzen käme zu spät und bliebe wirkungslos.
## `takt` ist die Dauer eines vollen Aus- und Einfahrens; `versatz`
## kleiner 0 heißt: aus der Strecke ableiten. Der abgeleitete Versatz ist
## bequem, solange die Felder weit auseinanderstehen – für eine Welle aus
## dicht gesetzten Feldern muss er von Hand kommen.
##
## Die Ableitung bleibt bei `fmod(strecke, 2.0)`, obwohl `fmod(strecke,
## takt)` sauberer aussähe: Bestehende Level haben ihre Wellen auf diesen
## Wert gelegt, ein anderer Teiler verschöbe sie stumm.
func stacheln(strecke: float, seitlich: float, flaeche: Vector2,
		einfahrbar: bool, farbe: Color = Color(0, 0, 0, 0),
		takt := 2.0, versatz := -1.0) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = einfahrbar
	st.takt = takt
	st.versatz = fmod(strecke, 2.0) if versatz < 0.0 else versatz
	if farbe.a > 0.0:
		st.rostig = false
		st.eigenfarbe = farbe
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	st.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(st)
	return st


# ------------------------------------------------- Auf der Wegdecke (Wegdaten)
#
# Die alten Helfer oben messen jede Höhe über der KURVE. Auf Terrassen
# (Abschnitte mit "hoehe") liegt die Decke bis über einen Meter darüber
# oder darunter; die Helfer hier messen über der DECKE (`boden_bei`). Ohne
# `weg` fallen sie auf die Kurve zurück und tun dasselbe wie die alten.

## Duckdurchlass: Maße aus dem Entwurf von Level 05 (§1 Nr. 2 und 3).
## Unterkante 0,95 m – die aufrechte Kapsel (1,30 m, Player.tscn) stößt an,
## Slide und Krabbeln (0,76 m) gehen darunter durch. Oberkante 4,4 m – ein
## Doppelsprung (Scheitel 3,22) und ein Slide-Sprung mit Doppelsprung
## (4,01) kommen nicht darüber; der Slide ist Pflicht.
const DUCK_UNTEN := 0.95
const DUCK_OBEN := 4.4
## Die Stolperzone liegt nur an der Stirn, von 0,15 m davor bis 0,25 m
## dahinter, ab 0,85 m Höhe: Eine Zone über die ganze Tiefe ließ Figuren
## beim Aufrichten am Ausgang stolpern (Entwurf L05 §1 Nr. 3, gemessen).
const STOLPER_VOR := 0.15
const STOLPER_NACH := 0.25
const STOLPER_UNTEN := 0.85
## Querschnitte des Durchlasses höchstens so weit auseinander: Der Körper
## folgt so auch einer Kurve und einer geneigten Decke.
const DUCK_SCHRITT := 0.5

## Sichtweiten der Spielobjekte wie in Level 01 (level01.gd:836-857).
const SICHTWEITEN_VORGABE := {
	"kiste": 80.0, "frucht": 58.0, "gegner": 90.0,
	"kiste_web": 55.0, "frucht_web": 45.0, "gegner_web": 60.0,
	"rand": 5.0,
}

## Sichtweiten nach `sichtweiten_einrichten`; leer = nicht eingerichtet.
var _sichtweiten := {}


## Welt-Y der Wegdecke. Ohne `weg` die Höhe der Kurve.
func boden_bei(s: float) -> float:
	if weg != null:
		return weg.boden_bei(s)
	return LevelWerkzeuge.punkt(verlauf, s).y


func ist_luecke(s: float) -> bool:
	if weg != null:
		return weg.ist_luecke(s)
	return breite_bei(s) <= 0.0


## Punkt auf dem Weg: `q` quer, `h` über der Wegdecke.
func weg_punkt(s: float, q := 0.0, h := 0.0) -> Vector3:
	if weg != null:
		return weg.weg_punkt(s, q, h)
	return LevelWerkzeuge.punkt_frei(verlauf, s, q, h)


## Höhe der Decke über der Kurve – das, was die alten Helfer als Höhe
## zusätzlich brauchen, damit sie auf der Decke landen.
func _ueber_kurve(s: float) -> float:
	return weg.ueber_kurve(s) if weg != null else 0.0


## Kiste auf die Wegdecke (Mitte `ueber` über dem Boden). Sonst wie `kiste()`.
func kiste_auf(art: Kiste.Art, s: float, q: float, ueber := 0.5,
		schwebt := false) -> Kiste:
	return kiste(art, s, q, _ueber_kurve(s) + ueber, schwebt)


## Frucht `ueber` Meter über der Wegdecke.
func frucht_auf(s: float, q: float, ueber := 0.9) -> Node3D:
	return frucht(s, q, _ueber_kurve(s) + ueber)


## Bogen aus Früchten über eine Lücke, gemessen an der Decke (in der Lücke
## linear zwischen den Kanten, `boden_bei`). ANDERS als `fruechte_bogen`:
## `scheitel` ist hier wie in Level 01 die Höhe der mittleren Frucht über
## dem Weg, nicht der Zuschlag auf 0,9 – „Scheitel 3,2" heißt also: so hoch
## wie ein Doppelsprung.
func fruechte_bogen_auf(von: float, bis: float, anzahl: int, q: float,
		scheitel := 2.6) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		frucht_auf(lerpf(von, bis, t), q, 0.9 + sin(t * PI) * (scheitel - 0.9))


## Gegner auf der Wegdecke. Die Strecke wird ERST von der Kante geschoben
## (wie in `gegner()`), dann die Höhe dort gemessen – sonst stünde ein
## Gegner, den die Klemmung von einer Stufe wegschiebt, auf der Höhe der
## Stelle, von der er kam.
func gegner_auf(szene: PackedScene, s: float, q: float, weite: float,
		quer: bool) -> Gegner:
	var stelle := weg_von_der_kante(s, 2.5)
	return gegner(szene, stelle, q, weite, quer, _ueber_kurve(stelle) + 0.05)


## Start- und Zielportal auf der Wegdecke, an den Strecken `start` und `ziel`.
func portale_auf(start: float, ziel: float) -> void:
	var a := STARTPORTAL.instantiate() as Node3D
	a.position = weg_punkt(start, 0.0, 0.1)
	a.rotation.y = LevelWerkzeuge.drehung(verlauf, start)
	objekte.add_child(a)
	var z := ZIELPORTAL.instantiate() as Node3D
	z.position = weg_punkt(ziel, 0.0, 0.1)
	z.rotation.y = LevelWerkzeuge.drehung(verlauf, ziel)
	objekte.add_child(z)


## Orte aller Kisten, die schon unter `objekte` stehen (Level-Koordinaten),
## für Freiräume im Bewuchs. Wald und Rasen brauchen sie beim Bau – die
## Kisten müssen deshalb VOR ihnen gesetzt sein. Kisten, die an etwas
## anderem hängen (Floß, Plattform), zählen nicht.
func kisten_orte() -> Array[Vector3]:
	var orte: Array[Vector3] = []
	for kind in objekte.get_children():
		if kind is Kiste:
			orte.append(objekte.transform * (kind as Kiste).position)
	return orte


## Harte Sichtweiten für Kisten, Früchte und Gegner wie in Level 01
## (level01.gd:836-857, 1132-1173): Jedes Objekt, das danach unter `objekte`
## eintritt – auch was `LevelBasis` nach einem Tod neu aufstellt oder gegen
## eine Zeitkiste tauscht –, bekommt seine Weite, sobald es fertig gebaut
## ist. Darum VOR den Kisten aufrufen. `weiten` überschreibt einzelne
## Schlüssel aus `SICHTWEITEN_VORGABE` (die Werte von Level 01).
func sichtweiten_einrichten(weiten := {}) -> void:
	_sichtweiten = SICHTWEITEN_VORGABE.duplicate()
	_sichtweiten.merge(weiten, true)
	if not objekte.child_entered_tree.is_connected(_sichtweite_eingetreten):
		objekte.child_entered_tree.connect(_sichtweite_eingetreten)


func _sichtweite_eingetreten(knoten: Node) -> void:
	var weite := _sichtweite_fuer(knoten)
	if weite <= 0.0:
		return
	if knoten.is_node_ready():
		_sichtweite_setzen(knoten, weite)
	else:
		knoten.ready.connect(_sichtweite_setzen.bind(knoten, weite), CONNECT_ONE_SHOT)


func _sichtweite_fuer(knoten: Node) -> float:
	var web := Effekte.reduziert
	var art := ""
	if knoten is Kiste:
		art = "kiste"
	elif knoten is Frucht:
		art = "frucht"
	elif knoten is Gegner:
		art = "gegner"
	if art.is_empty():
		return 0.0
	return float(_sichtweiten.get(art + "_web" if web else art, 0.0))


## Setzt die Sichtweite an allem, was darunter gezeichnet wird. Wer schon
## eine eigene hat, behält sie.
func _sichtweite_setzen(knoten: Node, weite: float) -> void:
	if not is_instance_valid(knoten):
		return
	var teil := knoten as GeometryInstance3D
	if teil != null and teil.visibility_range_end <= 0.0:
		teil.visibility_range_end = weite
		teil.visibility_range_end_margin = float(_sichtweiten.get("rand", 5.0))
	for kind in knoten.get_children():
		_sichtweite_setzen(kind, weite)


## Duckdurchlass: ein Riegel quer über den Weg, unter dem man nur im Slide
## oder krabbelnd hindurchkommt. `s` ist die Stirn (Eingang), `tiefe` die
## Länge in Laufrichtung.
##
## Der Körper liegt auf Ebene 16 (Spielergrenze): Die Figur stößt an, der
## Kamerastrahl (1|8) geht hindurch – sonst holte jeder Durchlass die
## Kamera vor die Figur. Er reicht von `unten` bis `oben` über der Decke
## (`boden_bei` je Querschnitt) und quer über die ganze Wegbreite.
##
## `optionen`:
##   q_von, q_bis   Querausdehnung; Vorgabe die halbe Wegbreite + 1 m nach
##                  beiden Seiten (über die Schulter bis an die Leitlinie)
##   unten, oben    Vorgabe DUCK_UNTEN 0,95 und DUCK_OBEN 4,4
##   stolperzone    Stolperdauer in Sekunden (`Spieler.stolpern`); > 0 legt
##                  eine Zone an die Stirn (STOLPER_VOR/NACH/UNTEN). Vorgabe 0
##   optik          Callable(s, tiefe) -> Node3D in Weltkoordinaten; wird
##                  Kind des Körpers. Ohne: grauer Platzhalter in der Form
##                  des Körpers
## Rückgabe: der Körper (unter `geometrie`); die Stolperzone ist sein Kind
## "Stolperzone". Metadaten "strecke", "tiefe", "unten", "oben" für Proben.
func duckdurchlass(s: float, tiefe: float, optionen := {}) -> StaticBody3D:
	var halb := maxf(breite_bei(s), breite_bei(s + tiefe)) * 0.5
	var q_von: float = optionen.get("q_von", -(halb + 1.0))
	var q_bis: float = optionen.get("q_bis", halb + 1.0)
	var unten: float = optionen.get("unten", DUCK_UNTEN)
	var oben: float = optionen.get("oben", DUCK_OBEN)
	var koerper := StaticBody3D.new()
	koerper.name = "Duckdurchlass"
	koerper.collision_layer = LevelWerkzeuge.SPIELERGRENZE
	koerper.collision_mask = 0
	koerper.set_meta("strecke", s)
	koerper.set_meta("tiefe", tiefe)
	koerper.set_meta("unten", unten)
	koerper.set_meta("oben", oben)
	var anzahl := maxi(ceili(tiefe / DUCK_SCHRITT), 1)
	var schnitte: Array[PackedVector3Array] = []
	for i in anzahl + 1:
		schnitte.append(_durchlass_schnitt(lerpf(s, s + tiefe, float(i) / float(anzahl)),
				q_von, q_bis, unten, oben))
	for i in anzahl:
		koerper.add_child(Wegdaten.prisma(schnitte[i], schnitte[i + 1]))

	var dauer: float = optionen.get("stolperzone", 0.0)
	if dauer > 0.0:
		var zone := Area3D.new()
		zone.name = "Stolperzone"
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.monitorable = false
		zone.add_child(Wegdaten.prisma(
				_durchlass_schnitt(s - STOLPER_VOR, q_von, q_bis, STOLPER_UNTEN, oben),
				_durchlass_schnitt(s + STOLPER_NACH, q_von, q_bis, STOLPER_UNTEN, oben)))
		zone.body_entered.connect(_durchlass_stolpern.bind(dauer))
		koerper.add_child(zone)

	var optik: Callable = optionen.get("optik", Callable())
	var sicht: Node3D = null
	if optik.is_valid():
		sicht = optik.call(s, tiefe) as Node3D
	if sicht == null:
		var netz := MeshInstance3D.new()
		netz.name = "Platzhalter"
		netz.mesh = Wegdaten.schnittnetz(schnitte)
		netz.material_override = Materialbibliothek.einfarbig(Color(0.52, 0.52, 0.5))
		sicht = netz
	koerper.add_child(sicht)
	geometrie.add_child(koerper)
	return koerper


## Querschnitt des Durchlasses an der Stelle `si`: vier Weltpunkte von
## (q_von, unten) im Uhrzeigersinn, Höhen über `boden_bei(si)`.
func _durchlass_schnitt(si: float, q_von: float, q_bis: float, unten: float,
		oben: float) -> PackedVector3Array:
	var schnitt := PackedVector3Array()
	var boden := boden_bei(si)
	for p: Vector2 in [Vector2(q_von, unten), Vector2(q_bis, unten),
			Vector2(q_bis, oben), Vector2(q_von, oben)]:
		var w := LevelWerkzeuge.punkt_frei(verlauf, si, p.x)
		schnitt.append(Vector3(w.x, boden + p.y, w.z))
	return schnitt


func _durchlass_stolpern(koerper: Node3D, dauer: float) -> void:
	if koerper is Spieler:
		(koerper as Spieler).stolpern(dauer)


## Meldet einen Knoten für die Zeit nach einem Tod an: `LevelBasis` ruft
## nach jedem Zurücksetzen `nach_tod(von_vorn: bool)` an ihm auf (Gruppe
## `LevelBasis.NACH_TOD`). Für alles, was ein Tod heilen oder neu stellen
## muss und das der Bauplan aus Kisten und Gegnern nicht kennt.
func nach_tod_melden(knoten: Node) -> void:
	knoten.add_to_group(NACH_TOD)


# ------------------------------------------------------------- Absturz

## Spannt unter dem ganzen Weg eine Zone, die den Spieler sterben lässt.
## In Stücken, weil ein einzelner Kasten einem kurvigen Verlauf nicht folgt.
##
## ACHTUNG BEI GESTAPELTEN EBENEN. `absturz_hoehe()` ist EIN Wert für das
## ganze Level, und die Zonen hängen relativ am Verlauf. Führt der Weg über
## sich selbst hinweg – eine Wendel, ein Obergeschoss, ein Turm –, dann
## schwebt die Zone des oberen Stücks irgendwo über dem unteren Boden. Zwei
## Regeln folgen daraus:
##
##   * Der Abstand zwischen zwei Ebenen muss größer sein als
##     |absturz_hoehe()| plus Sprunghöhe (1,96 m), sonst tötet die obere
##     Zone den Spieler, der unten nur springt.
##   * Umgekehrt darf `absturz_hoehe()` nicht beliebig tief gesetzt werden,
##     nur damit ein langer Sturz dramatisch wird – je tiefer, desto
##     größer muss der Ebenenabstand sein.
##
## Wer beides nicht zusammenbekommt, nimmt statt der Zone eine tödliche
## Fläche (`wasser()` mit `toedlich`) auf fester Welthöhe; die klettert
## nicht mit.
func absturzzonen(schritt: float = 18.0, breite: float = 70.0) -> void:
	var s := 0.0
	while s < ende():
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(breite, 5.0, schritt + 4.0)
		form.shape = box
		zone.add_child(form)
		zone.position = LevelWerkzeuge.punkt(verlauf, s + schritt * 0.5,
				0.0, absturz_hoehe() - 2.5)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s + schritt * 0.5)
		zone.body_entered.connect(_auf_absturz)
		geometrie.add_child(zone)
		s += schritt


func _auf_absturz(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler") or not koerper.has_method("sterben"):
		return
	# Die Zonen überlappen einander mit Absicht, damit unter einem kurvigen
	# Weg keine Lücke bleibt. Ohne diese Sperre zählt ein einziger Sturz
	# aber so oft, wie er Zonen berührt – bei einer engen Schleife waren
	# das drei Leben auf einmal. Nach dem ersten Tod ist der Spieler kurz
	# unverwundbar; genau daran wird der zweite Auslöser erkannt.
	if float(koerper.get("invuln")) > 0.0:
		return
	koerper.call("sterben")


# ------------------------------------------------------------- Lücken

## Markiert beide Seiten jeder Lücke, damit Löcher von weitem auffallen.
func luecken_markieren(pfosten_farbe: Color = Farben.HOLZ_DUNKEL) -> void:
	var liste := abschnitte()
	for i in liste.size() - 1:
		var a: Dictionary = liste[i]
		var naechster: Dictionary = liste[i + 1]
		if naechster["von"] - a["bis"] > 0.5:
			warnbalken(a["bis"] - 0.5, a.get("breite_ende", a["breite"]), pfosten_farbe)
			warnbalken(naechster["von"] + 0.5, naechster["breite"], pfosten_farbe)


## Zwei Pfosten mit Warnstreifen links und rechts, knapp vor der Kante.
func warnbalken(strecke: float, breite: float,
		pfosten_farbe: Color = Farben.HOLZ_DUNKEL) -> void:
	var holz := Materialbibliothek.kistenholz(pfosten_farbe)
	var streifen := Materialbibliothek.leuchtend(Color(1.0, 0.85, 0.25), 0.5)
	var halb := breite * 0.5 - 0.55
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)

	for seite: float in [-1.0, 1.0]:
		var gruppe := Node3D.new()
		gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seite * halb, 0.45)
		gruppe.rotation.y = dreh
		deko.add_child(gruppe)

		var zylinder := CylinderMesh.new()
		zylinder.top_radius = 0.09
		zylinder.bottom_radius = 0.11
		zylinder.height = 1.1
		zylinder.radial_segments = 8
		var pfosten := MeshInstance3D.new()
		pfosten.mesh = zylinder
		pfosten.position.y = 0.55
		pfosten.material_override = holz
		gruppe.add_child(pfosten)

		var band := BoxMesh.new()
		band.size = Vector3(0.26, 0.2, 0.26)
		var schild := MeshInstance3D.new()
		schild.mesh = band
		schild.position.y = 1.0
		schild.material_override = streifen
		gruppe.add_child(schild)


# ------------------------------------------------------------- Kamera

## Schaltet die Kamera auf Seitenansicht, solange der Spieler zwischen
## `von` und `bis` steht – das Bild wird für diesen Abschnitt zum
## 2D-Scroller. Die Steuerung stimmt dabei von selbst, weil sie
## kamerarelativ ist: Was auf dem Schirm nach rechts geht, geht auch am
## Stick nach rechts.
##
## Die Wand auf der Kameraseite wird dabei ausgeblendet – sonst stünde sie
## zwischen Kamera und Spieler und nähme das halbe Bild.
##
## In Stücken, weil ein einzelner Kasten einem kurvigen Weg nicht folgt.
func kamerazone(von: float, bis: float, seitlich: float,
		hoehe: float = 2.6) -> void:
	var schritt := 12.0
	var s := von
	while s < bis:
		var laenge := minf(schritt, bis - s)
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(30.0, 14.0, laenge)
		form.shape = box
		zone.add_child(form)
		zone.position = LevelWerkzeuge.punkt(verlauf, s + laenge * 0.5, 0.0, 4.0)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s + laenge * 0.5)
		zone.body_entered.connect(_kamera_seitlich.bind(seitlich, hoehe))
		zone.body_exited.connect(_kamera_normal)
		geometrie.add_child(zone)
		s += laenge


func _kamera_seitlich(koerper: Node3D, seitlich: float, hoehe: float) -> void:
	if not koerper.is_in_group("spieler"):
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera == null or not ("seitenblick" in kamera):
		return
	kamera.set("seitenblick", seitlich)
	kamera.set("seitenblick_hoehe", hoehe)
	_nahe_wand_zeigen(seitlich > 0.0, false)


func _kamera_normal(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera == null or not ("seitenblick" in kamera):
		return
	kamera.set("seitenblick", 0.0)
	_nahe_wand_zeigen(true, true)
	_nahe_wand_zeigen(false, true)


## Blendet eine der beiden Schluchtwände ein oder aus.
func _nahe_wand_zeigen(rechts: bool, sichtbar: bool) -> void:
	var wand := geometrie.get_node_or_null("Schluchtwand")
	if wand == null:
		return
	var teil := wand.get_node_or_null("WandRechts" if rechts else "WandLinks")
	if teil != null:
		teil.visible = sichtbar
