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

const M_ENDE := 290.0
const ABSTURZ := -8.0
const WEGBREITE := 12.0

## Abstand zwischen zwei Stationen. Groß genug, dass nichts vom Nachbarn
## überdeckt wird.
const SCHRITT := 14.0

const STRECKE := [
	{"von": 0.0, "bis": 26.0, "breite": WEGBREITE},
	# Lücke 26–34: darüber liegen die Bruchplatten
	{"von": 34.0, "bis": 290.0, "breite": WEGBREITE},
]

## Die Schlucht am Ende (Station 14–18): eine Wand zu beiden Seiten, an der
## die Bauteile aus Level 01 wachsen. Gut einen Meter Luft neben dem Weg,
## damit der Bewuchs am Wandfuß nicht auf dem Weg steht.
const SCHLUCHT := [
	{"von": 212.0, "bis": 268.0, "abstand": WEGBREITE * 0.5 + 1.2, "hoehe": 8.0},
]


func abschnitte() -> Array:
	return STRECKE


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
		{"text": "Portale", "tun": _portale},
		{"text": "Schilder", "tun": _schilder_setzen},
	]


## Eine leichte Kurve, kein gerader Strich: Bauteile, die sich mit dem Weg
## mitdrehen, verraten ihren Fehler nur auf einer Kurve.
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
	])


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

	# 16 · Lichtschacht an der rechten Wand. Die Sonne dieser Szene steht
	# noch falsch herum (Licht von unten) – der Schacht nimmt dann seine
	# Vorgaberichtung.
	var schacht := Lichtschacht.new()
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
