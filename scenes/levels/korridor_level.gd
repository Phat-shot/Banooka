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
const HANGELGITTER := preload("res://scenes/props/Hangelgitter.tscn")
const HORIZONT := preload("res://scenes/props/Horizont.tscn")
const LICHTKREIS := preload("res://scenes/props/Lichtkreis.tscn")
const TREIBMINE := preload("res://scenes/hazards/Treibmine.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")


# ------------------------------------------------------------- Haken

## Bodenstreifen des Weges: [{"von", "bis", "breite", "breite_ende"}].
func abschnitte() -> Array:
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
	for a in abschnitte():
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			var t := inverse_lerp(von, bis, strecke)
			return lerpf(a["breite"], a.get("breite_ende", a["breite"]), t)
	return 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func rand_bei(strecke: float, sicherheit: float = 1.3) -> float:
	return maxf(breite_bei(strecke) * 0.5 - sicherheit, 0.0)


## Schiebt eine Strecke vom Rand eines Abschnitts weg, damit Objekte nicht
## auf der Abbruchkante stehen.
func weg_von_der_kante(strecke: float, abstand: float) -> float:
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
func floss(von: float, bis: float, seitlich: float, hoehe: float,
		groesse: Vector2, fahrzeit: float, pause_a := 2.4,
		pause_b := 2.4, phase := 0.0) -> Wasserplattform:
	var f := WASSERPLATTFORM.instantiate() as Wasserplattform
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
		durchmesser := 2.4) -> Wasserplattform:
	var b := WASSERPLATTFORM.instantiate() as Wasserplattform
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
		oben_zeit := 2.3, unten_zeit := 0.9) -> Wasserplattform:
	var b := WASSERPLATTFORM.instantiate() as Wasserplattform
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
		flaeche := Vector2(4.0, 1.1)) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = false
	st.stachel_hoehe = 0.55
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
		takt := 1.2, phase := 0.0) -> Laserzaun:
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
func rollbrocken(von: float, bis: float, seitlich := 0.0, hoehe := 0.0,
		radius := 1.1, tempo := 9.0, pause := 2.0, phase := 0.0,
		art := Rollhindernis.Art.KUGEL) -> Rollhindernis:
	var r := ROLLHINDERNIS.instantiate() as Rollhindernis
	r.art = art
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
		hoehe := 2.8, offen := 2.2, zu := 1.6,
		phase := 0.0) -> Schliesstuer:
	var t := SCHLIESSTUER.instantiate() as Schliesstuer
	t.breite = breite
	t.hoehe = hoehe
	t.offen_zeit = offen
	t.zu_zeit = zu
	t.phase = phase
	t.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	t.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(t)
	return t


# ------------------------------------------------------- Deckung und Licht

## Stelle, an der man geduckt sicher ist. Nutzt unser Krabbeln.
func deckungsfleck(strecke: float, seitlich: float,
		radius := 1.6) -> Deckungsfleck:
	strecke = weg_von_der_kante(strecke, 2.0)
	var grenze := rand_bei(strecke, radius)
	var d := DECKUNGSFLECK.instantiate() as Deckungsfleck
	d.radius = radius
	d.position = LevelWerkzeuge.punkt(verlauf, strecke,
			clampf(seitlich, -grenze, grenze), 0.02)
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
	var markiert := Leuchtmarker.markieren(self, ["kisten", "fruechte"], 1.4)
	print("Dunkellevel: %d Marker leuchten selbst" % markiert)
	return l


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


func kiste(art: Kiste.Art, strecke: float, seitlich: float,
		hoehe: float = 0.5) -> Kiste:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	k.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	k.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(k)
	return k


## Setzt einen Gegner so, dass er beim Patrouillieren nicht vom Weg läuft:
## seitlicher Versatz und Weite werden auf die Wegbreite an dieser Stelle
## begrenzt, die Strecke von der Abbruchkante weggeschoben.
func gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool) -> Gegner:
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
		for a in abschnitte():
			if strecke >= a["von"] and strecke <= a["bis"]:
				frei = minf(strecke - a["von"], a["bis"] - strecke) - 1.0
		weite = minf(weite, maxf(frei, 0.5))
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized() if quer else richtung
	# Position VOR add_child setzen: die Gegner merken sich in _ready()
	# ihre Startposition für die Patrouille.
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.05)
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
func stacheln(strecke: float, seitlich: float, flaeche: Vector2,
		einfahrbar: bool, farbe: Color = Color(0, 0, 0, 0)) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = einfahrbar
	st.versatz = fmod(strecke, 2.0)
	if farbe.a > 0.0:
		st.rostig = false
		st.eigenfarbe = farbe
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	st.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(st)
	return st


# ------------------------------------------------------------- Absturz

## Spannt unter dem ganzen Weg eine Zone, die den Spieler sterben lässt.
## In Stücken, weil ein einzelner Kasten einem kurvigen Verlauf nicht folgt.
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
