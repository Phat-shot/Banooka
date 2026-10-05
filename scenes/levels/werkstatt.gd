extends KorridorLevel
## Werkstatt – jedes Bauteil einmal, hintereinander weg.
##
## Kein Spiellevel. Ein Prüfstand: Nach jeder Änderung an einem Bauteil
## lässt sich hier in einem Durchgang ansehen, ob es noch steht, sich noch
## bewegt und noch aussieht wie gedacht. Ein Fehler in einem Prop fällt
## sonst erst auf, wenn ein Level ihn benutzt – und dann sucht man ihn im
## Level statt im Prop.
##
## Aufruf:
##   FOTO_LEVEL=res://scenes/levels/Werkstatt.tscn \
##       bash werkzeuge/foto.sh /tmp/werkstatt verfolger 8,20,32,...
##
## Die Stationen stehen bewusst weit auseinander und auf breitem Weg: Es
## geht ums Ansehen, nicht ums Bestehen. Wer hier stirbt, hat ein Bauteil
## gefunden, das zu früh trifft.
##
## Station 1–13 zeigen die Spielbauteile aus `korridor_level.gd`, 14–19
## die Schlucht, 20–29 die Bauteile aus Level 01 (Stämme, Kronen, Steine,
## Bewuchs, Zaun, Saum, Waldsetzer, Weltenbaum im Kleinen). 30–33 gehören
## dem Baukasten für Raum 1 (Plan `baukasten.md` §1.7), die neuen Level
## hängen ab 34 an.
##
## Station 30 „Unterbau": der Weg aus `Wegdaten` (scripts/gemeinsam/
## wegdaten.gd) – Terrassen ±1,2 m mit Stufenkollision, Decke ohne
## Bordstein, Leitlinie auf Ebene 16 mit Schulter links, rechts eine offene
## Kante über einer Todeszone „Boden − 6", eine Kiste auf der oberen
## Terrasse (`kiste_auf`), ein Käfer auf der unteren (`gegner_auf`), ein
## Duckdurchlass und eine Tafel, die jeden Aufruf aus der Gruppe
## `LevelBasis.NACH_TOD` anschreibt.
##
## ZWEI WEGDATEN. `weg` beschreibt den ganzen Prüfstand (die alte Strecke
## samt Station 30), damit `breite_bei`, `boden_bei` & Co. überall
## stimmen. Gebaut wird aus `weg` aber nur Station 30 (`_weg_30`): Der alte
## Boden bis 450 bleibt der Korridor mit Bordstein, auf dem die Stationen
## 1–29 stehen. Für die alten Stationen ändert `weg` nichts – ihre Stellen
## liegen weit von jeder Kante, Breite und Klemmung bleiben dieselben.

const M_ENDE := 530.0
const ABSTURZ := -8.0
const WEGBREITE := 12.0
## Bis hier reicht der alte Boden (Korridor mit Bordstein), danach Station 30.
const M_STATION_30 := 450.0

## Abstand zwischen zwei Stationen. Groß genug, dass nichts vom Nachbarn
## überdeckt wird.
const SCHRITT := 14.0

const STRECKE := [
	{"von": 0.0, "bis": 26.0, "breite": WEGBREITE},
	# Lücke 26–34: darüber liegen die Bruchplatten
	{"von": 34.0, "bis": M_STATION_30, "breite": WEGBREITE},
]

## Station 30: die Abschnitte im Schema von Level 01. Die Kurve liegt flach
## (y 0), die Terrassen entstehen über "hoehe". Ohne "hoehe" folgt die
## Decke der Kurve. A verjüngt den alten Weg (12 m) auf 8 m.
##   458  Stufe +1,2 hinauf (springen)
##   470  Stufe −1,2 hinab: zurück UNTER die obere Terrasse geht es nicht
##   480  Stufe −1,2 hinab auf die untere Terrasse (Fels)
##   492  Stufe +1,2 hinauf
##   505  Duckdurchlass, 1,6 m tief
const STATION_30 := [
	{"name": "30A", "von": M_STATION_30, "bis": 458.0, "breite": WEGBREITE,
			"breite_ende": 8.0},
	{"name": "30B", "von": 458.0, "bis": 470.0, "breite": 8.0, "hoehe": 1.2},
	{"name": "30C", "von": 470.0, "bis": 480.0, "breite": 8.0, "hoehe": 0.0},
	{"name": "30D", "von": 480.0, "bis": 492.0, "breite": 8.0, "hoehe": -1.2,
			"stoff": "fels"},
	{"name": "30E", "von": 492.0, "bis": M_ENDE, "breite": 8.0},
]

## Links eine Leitlinie (Ebene 16) 0,6 m außerhalb der Wegkante, dazwischen
## die Schulter; rechts bleibt die Kante offen.
const LEITLINIEN_30 := [
	{"name": "Links 30", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(M_STATION_30, M_ENDE), "punkte": [
				Vector2(M_STATION_30, -6.4), Vector2(458.0, -4.6), Vector2(M_ENDE, -4.6)]},
]

## Stirn und Tiefe des Duckdurchlasses, Dauer des Stolperns an seiner Stirn
## (wie `STOLPER_DAUER` in Level 05).
const DURCHLASS_30 := 505.0
const DURCHLASS_30_TIEFE := 1.6
const DURCHLASS_30_STOLPERN := 0.45

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")

## Nur Station 30, zum Bauen (siehe Kopf, ZWEI WEGDATEN).
var _weg_30: Wegdaten

## Die Schlucht am Ende (Station 14–18): eine Wand zu beiden Seiten, an der
## die Bauteile aus Level 01 wachsen. Gut einen Meter Luft neben dem Weg,
## damit der Bewuchs am Wandfuß nicht auf dem Weg steht.
const SCHLUCHT := [
	{"von": 212.0, "bis": 268.0, "abstand": WEGBREITE * 0.5 + 1.2, "hoehe": 8.0},
]


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Prüfstand wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Boden", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Taktgeber", "tun": _taktgeber_setzen},
		{"text": "Bewegte Böden", "tun": _boeden_setzen},
		{"text": "Auslöser und Schranken", "tun": _schranken_setzen},
		{"text": "Gegner", "tun": _gegner_setzen},
		{"text": "Hangeln und Deckung", "tun": _koerper_setzen},
		{"text": "Schlucht", "tun": _schlucht_setzen},
		{"text": "Blätterdach", "tun": _blaetterdach_setzen},
		{"text": "Stämme, Kronen, Steine", "tun": _waldbauteile_setzen},
		{"text": "Bewuchs", "tun": _bewuchs_setzen},
		{"text": "Zaun, Saum, Wald", "tun": _waldrand_setzen},
		{"text": "Weltenbaum im Kleinen", "tun": _weltenbaum_setzen},
		{"text": "Unterbau aus Wegdaten", "tun": _station_30_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Schilder", "tun": _schilder_setzen},
	]


## Eine leichte Kurve, kein gerader Strich: Bauteile, die sich mit dem Weg
## mitdrehen, verraten ihren Fehler nur auf einer Kurve. Die letzten drei
## Punkte tragen Station 30. Ein angehängter Punkt ändert nur das letzte
## Kurvenstück: Punkte und Drehung sind bis s 449,5 bitgleich mit der
## Kurve ohne sie (gemessen alle 0,5 m), die Stationen 1–29 stehen also,
## wo sie standen.
##
## Die Wegdaten entstehen hier, vor allen Bauschritten (siehe Kopf).
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),
		Vector3(0, 0, -30),
		Vector3(6, 0, -64),
		Vector3(20, 0, -94),
		Vector3(42, 0, -116),
		Vector3(70, 0, -128),
		Vector3(100, 0, -130),
		Vector3(130, 0, -124),
		Vector3(160, 0, -112),
		Vector3(188, 0, -97),
		Vector3(214, 0, -86),
		Vector3(240, 0, -79),
		Vector3(266, 0, -76),
		Vector3(292, 0, -78),
		Vector3(318, 0, -85),
		Vector3(342, 0, -96),
		Vector3(364, 0, -110),
		Vector3(384, 0, -126),
		Vector3(402, 0, -146),
		Vector3(416, 0, -170),
	])
	var alle: Array = STRECKE.duplicate()
	alle.append_array(STATION_30)
	weg = Wegdaten.new(verlauf, {"abschnitte": alle})
	_weg_30 = Wegdaten.new(verlauf, {"abschnitte": STATION_30, "leitlinien": LEITLINIEN_30})
	# Unter der ganzen Station eine Todeszone „Boden − 6": rechts über die
	# offene Kante, unter jeder Terrasse auf ihrer eigenen Höhe. Sie liegt
	# über den alten Absturzzonen (Kurve − 8), fängt also zuerst.
	_weg_30.todeszonen = Wegdaten.zonen_unter_boden(_weg_30, M_STATION_30, M_ENDE,
			-30.0, 30.0, 6.0)


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.moos(),
		"klippe": Materialbibliothek.fels(),
	}, {"tiefe": 4.0, "schritt": 1.2, "kante_hoehe": 0.24, "kante_breite": 0.7})
	luecken_markieren()


func _absturz_spannen() -> void:
	absturzzonen(18.0, 70.0)


func _horizont_bauen() -> void:
	horizont(200.0, 30.0, Color(0.38, 0.40, 0.34), Color(0.58, 0.62, 0.58),
			true, -7.0)


# =========================================================== Stationen

## Station 1–5: alles, was einen Takt hat.
func _taktgeber_setzen() -> void:
	# 1 · Bruchplatten über der Lücke bei 26–34 m
	bruchplatten_reihe(27.0, 33.0, 4, 0.0, -0.2)

	# 2 · Taktwelle: fünf Flächen mit versetzter Phase
	taktwelle(40.0, 54.0, 5, 0.0, Vector2(2.6, 2.6), 0.2)

	# 3 · Feuerspeier, einer fest und einer schwenkend
	feuerspeier(62.0, -4.2, 1.1, 0.0, 3.4, 0.0)
	feuerspeier(68.0, 4.2, 1.1, 180.0, 3.4, 0.35, true)

	# 4 · Laserzaun mit wandernder Lücke
	laserzaun(78.0, 6.0, true, 1.2)

	# 5 · Rollbrocken, Kugel und Fass nebeneinander
	rollbrocken(86.0, 100.0, -3.0, 0.0, 1.1, 7.0, 2.0, 0.0)
	rollbrocken(86.0, 100.0, 3.0, 0.0, 0.8, 6.0, 2.0, 0.5,
			Rollhindernis.Art.FASS)


## Station 6–8: Böden, die sich bewegen.
func _boeden_setzen() -> void:
	# 6 · Drehscheibe
	drehscheibe(108.0, 0.0, 0.2, 4.2, 34.0)

	# 7 · Fließband
	laufband(118.0, 128.0, 0.0, 0.1, 3.4, 2.5, 1)

	# 8 · Schiebeblock, mit reichlich Luft zur Kante
	schiebeblock(136.0, -2.0, 0.0, Vector3(1.8, 1.2, 1.8), 3.4, true, 1.4, 1.0)


## Station 9–10: Auslöser und Schranken.
func _schranken_setzen() -> void:
	# 9 · Platte, die das Tor offen hält – ein Hindernis, zwei Rollen
	var tor := schliesstuer(150.0, 0.0, 3.6, 2.8, 2.0, 1.6)
	ausloeseplatte(145.0, 0.0, Vector2(2.6, 2.6), 1.2, false, [tor])

	# 10 · Wasserplattform als Aufzug, damit auch das Alte im Bild ist
	wehrbohle(158.0, -3.6, 1.6, -0.4, 0.0)


## Station 11–12: die neuen Gegner.
func _gegner_setzen() -> void:
	werfer(166.0, -3.4)
	schwarm(176.0, 0.0, 10.0)


## Station 13–14: Hangeln und Deckung.
func _koerper_setzen() -> void:
	hangelgitter(188.0, 0.0, 3.2, 9.0)
	deckungsfleck(176.0, 3.0)
	# Zwei Kisten als Größenvergleich – ohne etwas Bekanntes im Bild
	# lässt sich kein Maß beurteilen.
	kiste(Kiste.Art.EISEN, 200.0, -1.6)
	kiste(Kiste.Art.NORMAL, 200.0, 1.6)


## Station 14–18: die Schlucht aus Level 01 im Kleinen – Wand mit
## gemerkten Kronen, Bewuchs daran, Wasserfall, Lichtschacht, Wurzeltor
## und ein umgestürzter Stamm.
func _schlucht_setzen() -> void:
	var wand := LevelWerkzeuge.schluchtwand(geometrie, verlauf, SCHLUCHT,
			Materialbibliothek.wurzelfels(), {
		"schritt": 2.4, "lagen": 3, "block": 3.0, "sockel": 10.0, "saat": 1407,
		"adermaterial": Materialbibliothek.waldboden(),
		"deckmaterial": Materialbibliothek.moos(),
		"welt_projektion": true,
		"welt_kachel": Vector3(0.19, 0.3, 0.19),
		"kronen_merken": true,
	})
	var kronen: Array = wand.get_meta("kronen", [])
	# Ein Erdsims schließt den Spalt zwischen Weg und Wandfuß, wie in
	# Level 01 – sonst steht dort ein heller Streifen Himmel.
	var zone: Dictionary = SCHLUCHT[0]
	LevelWerkzeuge.sims(geometrie, verlauf, [{"von": zone["von"], "bis": zone["bis"],
			"innen": WEGBREITE * 0.5 - 0.3, "aussen": float(zone["abstand"]) + 0.5,
			"hoehe": -0.3}], Materialbibliothek.waldboden(), 2.0)

	# 14 · Bewuchs, mit Blüten, damit auch das dritte Netz im Bild ist
	Schluchtsaum.bauen(deko, verlauf, kronen, {"saat": 1408, "blueten": 1.0})

	# 15 · Wasserfall an der linken Wand
	Wasserfall.an_schluchtwand(deko, verlauf, kronen, 224.0, -1.0, 3.2, -6.0)

	# 16 · Lichtschacht an der rechten Wand, in der Richtung der Sonne
	var schacht := Lichtschacht.new()
	var sonne := get_node_or_null("Sonne") as DirectionalLight3D
	if sonne != null:
		schacht.richtung = -sonne.global_transform.basis.z
	schacht.saat = 1416
	schacht.laenge = 16.0
	schacht.position = LevelWerkzeuge.punkt(verlauf, 234.0, 4.0, -0.5)
	schacht.decke = LevelWerkzeuge.punkt(verlauf, 234.0).y \
			+ float(SCHLUCHT[0]["hoehe"])
	deko.add_child(schacht)

	# 17 · Wurzeltor von Wand zu Wand
	Schluchtsaum.wurzeltor(deko, verlauf, 244.0,
			float(SCHLUCHT[0]["abstand"]), 1417)

	# 18 · Umgestürzter Stamm hoch über dem Weg, von Krone zu Krone
	var a := _kronenpunkt(kronen, 251.0, -1.0)
	var b := _kronenpunkt(kronen, 257.0, 1.0)
	Schluchtsaum.baumstamm(deko, a, b, 0.7,
			LevelWerkzeuge.punkt(verlauf, 254.0).y + 6.0, 1418)


## Station 19: ein Blätterdach neben dem Weg, tief unten – Wald, auf den
## man von oben schaut.
func _blaetterdach_setzen() -> void:
	var rng := PropWerkzeug.zufall(1419)
	var baeume: Array = []
	for i in 14:
		var strecke := rng.randf_range(270.0, 284.0)
		var quer := rng.randf_range(9.0, 18.0)
		baeume.append({
			"fuss": LevelWerkzeuge.punkt(verlauf, strecke, quer, -12.0),
			"hoehe": rng.randf_range(8.0, 10.0),
			"breite": rng.randf_range(2.6, 3.6),
		})
	Schluchtsaum.blaetterdach(deko, baeume, 1420)


# =================================================== Bauteile aus Level 01
#
# Station 20–29. Alles ohne Kollision bis auf den Kasten unter dem
# Findling (Station 22) – die Bauteile stehen am Wegrand, die Mitte bleibt
# frei. Jedes Teil so, wie sein Kopfkommentar es aufruft.

## Station 20–22: Stämme, Kronen, Steine.
func _waldbauteile_setzen() -> void:
	var borke := Riesenstamm.borkenstoff()

	# 20 · Riesenstamm: Talriese mit Brettwurzeln und Beiwerk, oben
	# gebrochen; daneben ein liegender Stamm und ein Stumpf
	var riese := Riesenstamm.netz({"hoehe": 15.0, "radius": 0.9, "brettwurzeln": 6,
			"pilze": 2, "efeu": 1, "leuchtpilze": 1, "oben": "bruch", "saat": 2001})
	_netz_setzen(riese, borke, _lage(298.0, 4.2), true, "Talriese")
	var liegend := Riesenstamm.liegend(0.45, 5.0, {"saat": 2002, "aeste": 2})
	# Die Achse liegt entlang +Y: um X gekippt zeigt sie den Weg entlang.
	var quer := _lage(296.0, -4.0, 0.36)
	quer.basis = quer.basis * Basis(Vector3.RIGHT, -PI * 0.5)
	_netz_setzen(liegend, borke, quer, true, "Liegend")
	_netz_setzen(Riesenstamm.stumpf(0.6, 1.2, {"saat": 2003}), borke,
			_lage(303.0, -4.4), true, "Stumpf")

	# 21 · Kronenwolke: ein Baum mit Ästen in die Krone, dazu die drei
	# Varianten (rund, breit, hoch) und die Fernfassung, bodennah
	var baum := Riesenstamm.baum({"hoehe": 11.0, "radius": 0.3, "aeste": 4, "saat": 2101})
	_netz_setzen(baum["stamm"], borke, _lage(312.0, 4.4), true, "Baum")
	_netz_setzen(baum["krone"], Kronenwolke.stoff(Farben.LAUB), _lage(312.0, 4.4), false,
			"Baumkrone")
	for variante in 3:
		var krone := Kronenwolke.netz({"radius": 1.3, "variante": variante,
				"saat": 2102 + variante})
		_netz_setzen(krone, Kronenwolke.stoff(Farben.LAUB),
				_auf_boden(krone, 307.0 + 3.6 * float(variante), -4.2), false,
				"Krone %d" % variante)
	var fern := Kronenwolke.fern({"radius": 1.6, "saat": 2105})
	_netz_setzen(fern, Kronenwolke.stoff(Farben.LAUB, false), _auf_boden(fern, 318.5, -4.2),
			false, "Krone fern")

	# 22 · Findling genau auf seinem Kasten – der Kasten trägt, man kann
	# hinaufspringen. Daneben ein Deko-Brocken und ein Trittstein.
	var groesse := Vector3(2.4, 1.0, 1.8)
	var kasten := _lage(326.0, 3.4, groesse.y * 0.5)
	var koerper := StaticBody3D.new()
	koerper.name = "Findlingskasten"
	koerper.transform = kasten
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = groesse
	form.shape = box
	koerper.add_child(form)
	geometrie.add_child(koerper)
	Findling.bauen(deko, groesse, kasten, {"saat": 2201})
	_netz_setzen(Findling.brocken(Vector3(1.4, 0.9, 1.2), {"saat": 2202}), Findling.stoff(),
			_lage(324.0, -4.3, 0.3, 0.6), true, "Brocken")
	_netz_setzen(Findling.scheibe(0.8, 0.6, {"saat": 2203, "wasser_y": 0.1}), Findling.stoff(),
			_lage(329.0, -3.6, 0.1), true, "Trittstein")


## Station 23–25: Bewuchs am Boden.
func _bewuchs_setzen() -> void:
	var rng := PropWerkzeug.zufall(2300)

	# 23 · Farnwerk: kleine Farne links, große rechts, ein Rahmenfarn
	var farnstoff := Farnwerk.stoff(Farben.LAUB)
	for k in 5:
		_netz_setzen(Farnwerk.klein(k + 1), farnstoff,
				_lage(334.0 + 2.0 * float(k), rng.randf_range(-5.4, -3.6), 0.0, float(k) * 1.3),
				false, "Farn klein %d" % k)
	for k in 2:
		_netz_setzen(Farnwerk.gross(k + 1), farnstoff,
				_lage(335.0 + 5.0 * float(k), 4.6, 0.0, float(k) * 2.0), false, "Farn gross %d" % k)
	_netz_setzen(Farnwerk.rahmen(1), farnstoff, _lage(342.0, -4.8, 0.0, 0.8), false,
			"Rahmenfarn")

	# 24 · Rasensaum: Flecken und Büschel rechts, Wispelgras über der
	# Kante, Moospolster und Moosflecken links
	var flecken: Array[Transform3D] = []
	var buesche: Array[Transform3D] = []
	var wispel: Array[Transform3D] = []
	var polster: Array[Transform3D] = []
	var moos: Array[Transform3D] = []
	var farben_f := PackedColorArray()
	var farben_b := PackedColorArray()
	var farben_w := PackedColorArray()
	var farben_p := PackedColorArray()
	var farben_m := PackedColorArray()
	for i in 140:
		flecken.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(2.4, 5.8), 0.0,
				rng.randf() * TAU))
		farben_f.append(Rasensaum.farbe(0.9, 1.0, rng.randf_range(0.35, 0.65), 0.0))
	for i in 18:
		buesche.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(5.0, 5.8), 0.0,
				rng.randf() * TAU))
		farben_b.append(Rasensaum.farbe(0.85, 1.0, rng.randf_range(0.4, 0.6), 0.0))
	for i in 8:
		# Wispelgras hängt nach +X über eine Kante: mit der Wegdrehung ist das
		# die rechte Wegkante.
		wispel.append(_lage(346.0 + 1.2 * float(i), 5.85, 0.0, rng.randf_range(-0.3, 0.3)))
		farben_w.append(Rasensaum.farbe(Wegmaske.RAND_VERDECKUNG, 1.0, 0.5, 0.0))
	for i in 6:
		polster.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(-5.4, -3.0), 0.0,
				rng.randf() * TAU))
		farben_p.append(Rasensaum.farbe(0.9, 1.0, 0.5, 0.0))
		moos.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(-5.4, -3.0), 0.0,
				rng.randf() * TAU))
		farben_m.append(Rasensaum.farbe(0.9, 1.0, 0.5, 0.0))
	Rasensaum.feld(deko, "Rasen Flecken", Rasensaum.fleck(2401), flecken, farben_f)
	Rasensaum.feld(deko, "Rasen Bueschel", Rasensaum.bueschel(2402), buesche, farben_b)
	Rasensaum.feld(deko, "Rasen Wispel", Rasensaum.wispel(2403), wispel, farben_w)
	Rasensaum.feld(deko, "Rasen Polster", Rasensaum.polster(2404), polster, farben_p)
	Rasensaum.feld(deko, "Rasen Moos", Rasensaum.moosfleck(2405), moos, farben_m,
			Rasensaum.SICHTWEITE, true)

	# 25 · Bodenstreu: Klee, Blüten, Kiesel und Pilze in EINEM Netz, dazu
	# Großblattstauden als Feld
	var haufen := Bodenstreu.Haufen.new(LevelWerkzeuge.punkt(verlauf, 362.0))
	for i in 4:
		haufen.teil(Bodenstreu.klee(rng, 0.35, i % 2 == 0),
				_lage(358.0 + 2.5 * float(i), rng.randf_range(-5.2, -2.8)))
	for i in 5:
		haufen.teil(Bodenstreu.blueten(rng, i % 3, Bodenstreu.BLUETEN_FARBEN[i]),
				_lage(357.0 + 2.2 * float(i), rng.randf_range(2.8, 5.2)))
	for i in 4:
		haufen.teil(Bodenstreu.kiesel(rng, 0.16, 3),
				_lage(rng.randf_range(357.0, 367.0), rng.randf_range(-5.4, -2.6)))
	for i in 3:
		haufen.teil(Bodenstreu.pilze(rng, 0.06, 3, i == 2),
				_lage(359.0 + 3.0 * float(i), rng.randf_range(2.6, 4.4)))
	haufen.knoten(deko, "Streu", 60.0)
	var stauden: Array[Transform3D] = []
	var farben_s := PackedColorArray()
	for i in 3:
		stauden.append(_lage(358.0 + 4.0 * float(i), 5.0, 0.0, rng.randf() * TAU))
		farben_s.append(Color.WHITE)
	Bodenstreu.feld(deko, "Grossblatt", Bodenstreu.grossblatt(rng, 1.0).netz(), stauden,
			farben_s, 60.0)


## Station 26–28: Zaun, Saum und ein kleiner Wald.
func _waldrand_setzen() -> void:
	# 26 · Totholzzaun am rechten Rand, mit geborstenem Endpfosten
	var linie := PackedVector3Array()
	var s := 368.0
	while s <= 381.0:
		linie.append(LevelWerkzeuge.punkt(verlauf, s, 5.3))
		s += 1.0
	_netz_setzen(Totholzzaun.bauen(linie, {"saat": 2601, "aussen": 1.0,
			"ende_geborsten": true, "verfall": 0.5}), Totholzzaun.stoff(), Transform3D.IDENTITY,
			true, "Totholzzaun")

	# 27 · GelaendeSaum: eine Felsbank am linken Rand
	_saum_setzen(383.0, 394.0)

	# 28 · Waldsetzer: ein Hain aus vier Bäumen und Farnen in drei Arten,
	# Stämme und Kronen je Zelle verschmolzen, Farne als MultiMesh
	var ws := Waldsetzer.new(deko, "Waldprobe", 20.0)
	ws.art("stamm", {"stoff": Riesenstamm.borkenstoff(), "schatten": true, "sicht": 120.0,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(Farben.LAUB_DUNKEL), "sicht": 120.0,
			"verschmelzen": true, "karten": true})
	ws.art("farn", {"stoff": Farnwerk.stoff(Farben.LAUB), "sicht": 60.0})
	var rng := PropWerkzeug.zufall(2800)
	for k in 4:
		var b := Riesenstamm.baum({"hoehe": rng.randf_range(9.0, 11.0),
				"radius": rng.randf_range(0.24, 0.3), "aeste": 3, "saat": 2801 + k})
		var lage := _lage(397.0 + 3.6 * float(k), 4.8 if k % 2 == 0 else -4.8, 0.0,
				rng.randf() * TAU)
		var ton := Color(1.0, 1.0, 1.0).darkened(rng.randf_range(0.0, 0.15))
		ws.setze("stamm", b["stamm"], lage, ton)
		ws.setze("krone", b["krone"], lage, ton)
	var farn := Farnwerk.klein(7)
	for k in 8:
		ws.setze("farn", farn, _lage(rng.randf_range(397.0, 408.0),
				rng.randf_range(3.2, 5.6) * (1.0 if k % 2 == 0 else -1.0), 0.0,
				rng.randf() * TAU))
	ws.fertig()


## Eine Felsbank aus `GelaendeSaum`: Fuß im Rasen am Wegrand, Schichtfels,
## ein kleiner Überhang, Grasnarbe obenauf und hinten wieder hinab. Die
## Enden schließt `deckel()`.
func _saum_setzen(von: float, bis: float) -> void:
	const SEITE := -1.0
	var q := -WEGBREITE * 0.5 + 0.6
	var proben := GelaendeSaum.linie(verlauf, PackedVector2Array([Vector2(von, q),
			Vector2(bis, q)]), 0.8)
	var g := GelaendeSaum.querschnitte(verlauf, proben, SEITE, _saum_profil,
			func(_i: int, _probe: Dictionary) -> float: return 0.0,
			func(_i: int, _probe: Dictionary) -> float: return 0.0)
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var farben: Array[PackedColorArray] = g["farben"]
	var n := reihen.size()
	if n < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	GelaendeSaum.gitter_schreiben(st, g, GelaendeSaum.normalen(g), 0, n - 1)
	for ende in 2:
		var i := 0 if ende == 0 else n - 1
		var aussen := reihen[i][0] - reihen[1 if ende == 0 else n - 2][0]
		aussen.y = 0.0
		if aussen.length_squared() > 0.000001:
			GelaendeSaum.deckel(st, reihen[i], farben[i], aussen.normalized(), 0.0)
	st.index()
	_netz_setzen(st.commit(), GelaendeSaum.stoff(), Transform3D.IDENTITY, false, "Saum")


## Querschnitt der Felsbank: Versatz nach außen und Welt-Y, Farbe als
## (Verdeckung, Erde, Moos, Rasen). Zur Mitte der Bank hin höher.
func _saum_profil(i: int, _probe: Dictionary) -> GelaendeSaum.Profil:
	var h := 2.6 + 0.8 * sin(float(i) * 0.45)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.5, -0.02, Color(0.78, 0.0, 0.1, 1.0))
	p.punkt(0.0, 0.0, Color(0.5, 0.7, 0.3, 0.3))
	p.punkt(0.15, 0.35, Color(0.35, 0.8, 0.1, 0.0), 0.8, 0.12, 2.0)
	p.punkt(0.3, h * 0.35, Color(0.6, 0.15, 0.05, 0.0), 1.6, 0.25, 2.0, 0.12)
	p.punkt(0.45, h * 0.65, Color(0.65, 0.1, 0.05, 0.0), 1.6, 0.25, 2.0, 0.12)
	p.punkt(0.4, h * 0.9, Color(0.55, 0.1, 0.2, 0.0), 0.8, 0.15, 1.0)
	p.punkt(0.65, h, Color(0.7, 0.2, 0.5, 0.3))
	p.punkt(1.2, h + 0.08, Color(0.8, 0.0, 0.2, 1.0))
	p.punkt(2.4, h + 0.1, Color(0.8, 0.0, 0.1, 1.0))
	p.punkt(3.0, h * 0.6, Color(0.5, 0.4, 0.2, 0.3), 1.6, 0.2, 2.0)
	p.punkt(3.3, -1.5, Color(0.3, 0.6, 0.1, 0.0), 1.6, 0.2, 2.0)
	return p


## Station 29: der Weltenbaum im Maßstab 1:8 – rund 3 statt 24 m Stamm-
## durchmesser. Der echte (Level 01) passt auf keinen Prüfstand, und ein
## Platz für ein größeres Muster zöge Nähte quer über den Weg; die
## Bausteine sind dieselben: Stamm aus `profil` mit Brettwurzeln, Ästen,
## Konsolen, Knollen, Efeu und Leuchtpilzen, darauf der Kronenschirm aus
## Ballen. Die Borke in Weltprojektion mit der Kachel für diesen Radius –
## die des Riesen (`Weltenbaum.stoff_stamm`) wäre hier achtmal zu grob.
func _weltenbaum_setzen() -> void:
	var fuss := _lage(432.0, 3.6)
	var st := Riesenstamm.bauer()
	var info := Weltenbaum.stamm_in(st, {
		"profil": PackedVector2Array([Vector2(-1.0, 2.0), Vector2(0.5, 1.6),
				Vector2(3.0, 1.3), Vector2(8.0, 1.1), Vector2(12.0, 1.0)]),
		"y_von": -1.0, "y_bis": 12.0, "rippen": 24, "ring_min": 0.5, "ring_max": 1.2,
		"saat": 2901,
		"brettwurzeln": [
			{"winkel": 0.4, "reichweite": 2.2, "hoehe": 1.4, "dicke": 0.22, "fuss_y": -0.5},
			{"winkel": 2.2, "reichweite": 1.9, "hoehe": 1.2, "dicke": 0.2, "fuss_y": -0.5},
			{"winkel": 3.6, "reichweite": 2.4, "hoehe": 1.6, "dicke": 0.22, "fuss_y": -0.5},
			{"winkel": 5.1, "reichweite": 1.8, "hoehe": 1.1, "dicke": 0.2, "fuss_y": -0.5},
		],
		"aeste": [
			{"winkel": 0.8, "y": 9.2, "laenge": 2.6, "steigung": 0.5, "radius": 0.32},
			{"winkel": 2.9, "y": 9.8, "laenge": 2.3, "steigung": 0.55, "radius": 0.28},
			{"winkel": 4.8, "y": 10.4, "laenge": 2.4, "steigung": 0.5, "radius": 0.28},
		],
		"pilze": [{"winkel": 1.6, "y": 2.6, "breite": 0.9}],
		"knollen": [{"winkel": 4.2, "y": 3.4, "radius": 0.3}],
		"efeu": [{"winkel": 2.6, "von": 0.0, "bis": 5.5}],
		"leuchten": [{"winkel": 5.6, "y": 0.6}],
	})
	_netz_setzen(Riesenstamm.fertig(st), Riesenstamm.borkenstoff({"welt": true, "radius": 1.5}),
			fuss, true, "Weltenbaum")
	var spitzen: PackedVector3Array = info["ast_spitzen"]
	var ballen: Array = []
	for k in spitzen.size():
		ballen.append({"mitte": spitzen[k], "radius": 1.8, "variante": 1, "saat": 2910 + k})
	ballen.append({"mitte": Vector3(0.0, 12.6, 0.0), "radius": 2.2, "variante": 1, "saat": 2920})
	_netz_setzen(Weltenbaum.krone(ballen, false), Weltenbaum.stoff_krone(), fuss, false,
			"Weltenbaum Krone")


# =================================================== Baukasten Raum 1

## Station 30: der Unterbau aus `Wegdaten` und die Helfer `*_auf` aus
## `KorridorLevel` (Paket G1). Abnahme (Plan G1): Der Rückweg unter die
## obere Terrasse ist gesperrt (Stufenkollision und zwei Meter dicke
## Schulter); der Duckdurchlass sperrt die aufrechte Kapsel und lässt Slide
## und Krabbeln durch, ein Doppelsprung kommt nicht darüber; ein Tod
## schreibt `nach_tod(false)` an die Tafel.
func _station_30_setzen() -> void:
	# Die untere Terrasse in Fels, der Rest fällt auf den Waldweg zurück
	# (null): zwei Stoffe, also zwei Netze und eine Kollision.
	_weg_30.decke_bauen(geometrie, func(a: Dictionary) -> Material:
		if String(a.get("stoff", "")) == "fels":
			return Materialbibliothek.fels()
		return null)
	_weg_30.leitlinien_bauen(geometrie)
	_weg_30.schultern_bauen(geometrie)
	_weg_30.todeszonen_bauen(geometrie)

	# Auf der oberen Terrasse (+1,2): zwei Kisten über die Decke gesetzt.
	kiste_auf(Kiste.Art.NORMAL, 464.0, -2.0)
	kiste_auf(Kiste.Art.FRUCHT_MEHRFACH, 464.0, 2.0)
	# Auf der unteren Terrasse (−1,2) ein Käfer, der längs patrouilliert: Die
	# Weite klemmt am Strang 480–492, nicht an der Kurve.
	gegner_auf(PANZERKAEFER, 486.0, 0.0, 3.0, false)
	# Bogen über die Stufe hinauf, gemessen an der Decke.
	fruechte_bogen_auf(489.5, 494.5, 5, 0.0, 2.2)
	for i in 3:
		frucht_auf(500.0 + 1.2 * float(i), 0.0, 0.45)

	duckdurchlass(DURCHLASS_30, DURCHLASS_30_TIEFE, {
		"stolperzone": DURCHLASS_30_STOLPERN,
		"optik": _durchlass_optik,
	})

	var tafel := Nachtodtafel.new()
	tafel.name = "Nachtodtafel"
	tafel.text = "30 nach_tod\nnoch kein Aufruf"
	tafel.font_size = 72
	tafel.pixel_size = 0.012
	tafel.modulate = Color(0.85, 0.95, 1.0)
	tafel.outline_size = 18
	tafel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Hinter dem Durchlass und links über der Leitlinie: Näher und weiter
	# innen stünde sie der Verfolgerkamera vor 494–500 mitten im Bild.
	tafel.position = weg_punkt(512.0, -5.6, 3.0)
	deko.add_child(tafel)
	nach_tod_melden(tafel)


## Optik des Duckdurchlasses an Station 30, nach dem Entwurf von Level 05
## (§1 Nr. 2): ein massiver Riegel 0,95–1,40 m, darüber Latten mit viel
## Luft dazwischen, eine Kappe bis 4,4 m und zwei Pfosten außen. Alles ohne
## Kollision – die trägt der Körper.
func _durchlass_optik(s: float, tiefe: float) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Durchlassoptik"
	var mitte := s + tiefe * 0.5
	var lage := Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, mitte)),
			weg_punkt(mitte))
	var holz := Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	var breite := breite_bei(mitte) + 2.0
	_kasten(wurzel, holz, lage, Vector3(breite, 0.45, tiefe), Vector3(0.0, 1.175, 0.0))
	_kasten(wurzel, holz, lage, Vector3(breite, 0.2, tiefe), Vector3(0.0, 4.3, 0.0))
	for k in 6:
		var q := lerpf(-breite * 0.5 + 0.6, breite * 0.5 - 0.6, float(k) / 5.0)
		_kasten(wurzel, holz, lage, Vector3(0.14, 2.8, 0.14), Vector3(q, 2.8, 0.0))
	for seite: float in [-1.0, 1.0]:
		_kasten(wurzel, holz, lage, Vector3(0.3, 5.9, 0.3),
				Vector3(seite * breite * 0.5, 4.4 - 2.95, 0.0))
	return wurzel


func _kasten(eltern: Node3D, stoff: Material, lage: Transform3D, groesse: Vector3,
		versatz: Vector3) -> void:
	var netz := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = groesse
	netz.mesh = form
	netz.material_override = stoff
	netz.transform = lage * Transform3D(Basis(), versatz)
	eltern.add_child(netz)


## Station 30: zählt die Aufrufe aus der Gruppe `LevelBasis.NACH_TOD` und
## schreibt den letzten an – ein Tod muss hier „nach_tod(false)" zeigen,
## ein Game Over „nach_tod(true)".
class Nachtodtafel extends Label3D:
	var anzahl := 0
	var zuletzt := ""

	func nach_tod(von_vorn: bool) -> void:
		anzahl += 1
		zuletzt = "nach_tod(%s)" % str(von_vorn)
		text = "30 nach_tod\n%d× – zuletzt %s" % [anzahl, zuletzt]


## Lage am Weg: Strecke, Querabstand (rechts positiv), Höhe und eine
## Drehung um die Hochachse, ausgerichtet nach der Wegrichtung (+X zeigt
## nach rechts, -Z den Weg entlang).
func _lage(strecke: float, quer: float, hoehe: float = 0.0, dreh: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, strecke) + dreh),
			LevelWerkzeuge.punkt(verlauf, strecke, quer, hoehe))


## Lage für ein Netz, das um seine Mitte gebaut ist: die Unterkante knapp
## über den Weg.
func _auf_boden(netz: Mesh, strecke: float, quer: float) -> Transform3D:
	return _lage(strecke, quer, 0.2 - netz.get_aabb().position.y)


func _netz_setzen(netz: Mesh, stoff: Material, lage: Transform3D, schatten: bool,
		name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = lage
	deko.add_child(mi)
	return mi


## Auflagepunkt auf der Wandkrone (wie in Level 01): ein Stück hinter der
## Kante, auf ihrer Oberseite.
func _kronenpunkt(kronen: Array, strecke: float, seite: float) -> Vector3:
	var beste: Dictionary = {}
	var abstand := INF
	for eintrag in kronen:
		var e: Dictionary = eintrag
		if float(e["seite"]) != seite:
			continue
		var d := absf(float(e["s"]) - strecke)
		if d < abstand:
			abstand = d
			beste = e
	if beste.is_empty():
		return LevelWerkzeuge.punkt(verlauf, strecke, seite * 8.0, 8.0)
	return LevelWerkzeuge.punkt(verlauf, strecke,
			seite * (float(beste["innen"]) + 1.0), float(beste["oben"]) + 0.6)


func _portale() -> void:
	portale_setzen(1.0, 4.0)


## Nummernschilder an jeder Station.
##
## Ohne sie ist auf einem Bild nicht zu sagen, welches Bauteil man gerade
## sieht – und genau das ist der Zweck dieses Levels.
func _schilder_setzen() -> void:
	var stationen := {
		30.0: "1 Bruchplatte", 47.0: "2 Taktwelle", 65.0: "3 Feuerspeier",
		78.0: "4 Laserzaun", 93.0: "5 Rollbrocken", 108.0: "6 Drehscheibe",
		123.0: "7 Fliessband", 136.0: "8 Schiebeblock",
		148.0: "9 Platte + Tor", 158.0: "10 Wehrbohle",
		166.0: "11 Werfer", 176.0: "12 Schwarm + Deckung",
		188.0: "13 Hangelgitter",
		216.0: "14 Schluchtsaum", 224.0: "15 Wasserfall",
		234.0: "16 Lichtschacht", 244.0: "17 Wurzeltor",
		254.0: "18 Baumstamm", 276.0: "19 Blaetterdach",
		298.0: "20 Riesenstamm", 312.0: "21 Kronenwolke", 326.0: "22 Findling",
		338.0: "23 Farnwerk", 350.0: "24 Rasensaum", 362.0: "25 Bodenstreu",
		374.0: "26 Totholzzaun", 388.0: "27 GelaendeSaum",
		402.0: "28 Waldsetzer", 432.0: "29 Weltenbaum (1:8)",
		452.0: "30 Unterbau (Wegdaten)",
	}
	for strecke: float in stationen:
		var schild := Label3D.new()
		schild.text = String(stationen[strecke])
		schild.font_size = 96
		schild.pixel_size = 0.012
		schild.modulate = Color(1.0, 0.94, 0.7)
		schild.outline_size = 24
		schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		schild.no_depth_test = true
		schild.position = LevelWerkzeuge.punkt(verlauf, strecke,
				-WEGBREITE * 0.5 + 0.8, 3.4)
		deko.add_child(schild)
