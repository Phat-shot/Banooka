extends KorridorLevel
## Level 02 – "Frostgrat"
##
## Ein verschneiter Grat, der zum Gipfel ansteigt. Aufbau wie Level 01:
## Der Verlauf steckt in einer Kurve, alles Übrige wird über
## `LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)` relativ dazu
## gesetzt. Die gemeinsamen Helfer stehen in `KorridorLevel`.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  48  Anstieg      – breite Anlaufstrecke, erste Kisten, Käfer
##    48 – 104  Eisfeld      – Rechtskurve, Eisplatten über dem See, Kröten
##   104 – 152  Spalten      – schmaler Grat, tiefe Lücken, Federkiste
##   152 – 182  Zapfen       – Eiszapfenfelder, Stelzenvögel, TNT-Kette
##   182 – 212  Gipfel       – Extraleben und Zielportal
##
## Die Gegner kommen in der Reihenfolge ihrer Schwierigkeit: erst der
## Käfer (draufspringen), dann die Kröte (Drehschlag), zuletzt der
## Stelzenvogel (Slide).

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENVOGEL := preload("res://scenes/enemies/Stelzenvogel.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")

# Strecken-Marken der Abschnitte
const M_ANSTIEG := 0.0
const M_EISFELD := 48.0
const M_SPALTEN := 104.0
const M_ZAPFEN := 152.0
const M_GIPFEL := 182.0
const M_ENDE := 212.0

# Höhen relativ zum Weg
const SEE_HOEHE := -12.0      ## gefrorener See tief unter dem Grat
const ABSTURZ := -6.0         ## darunter ist der Sturz tödlich


## Bodenstreifen mit Lücken. Diese Liste ist die einzige Quelle für die
## Wegbreite – `breite_bei()` liest sie aus, damit nichts neben dem Weg landet.
const STRECKE := [
	# --- Anstieg: breit und sicher, eine Übungslücke ---
	{"von": 0.0, "bis": 30.0, "breite": 11.0},
	{"von": 34.0, "bis": 48.0, "breite": 10.0},
	# --- Eisfeld: schmaler, zwei Lücken über dem See ---
	{"von": 48.0, "bis": 66.0, "breite": 9.0, "breite_ende": 7.5},
	{"von": 72.0, "bis": 84.0, "breite": 7.0},
	{"von": 90.0, "bis": 104.0, "breite": 8.0},
	# --- Gletscherspalten: schmaler Grat mit weiten Lücken ---
	{"von": 104.0, "bis": 124.0, "breite": 7.0},
	{"von": 130.0, "bis": 146.0, "breite": 6.0, "breite_ende": 8.0},
	# --- Zapfenpassage: breit genug zum Ausweichen ---
	{"von": 152.0, "bis": 182.0, "breite": 10.0},
	# --- Gipfel: weite Fläche zum Abschluss ---
	{"von": 182.0, "bis": 212.0, "breite": 13.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Grat wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Gefrorener See", "tun": _see_bauen},
		{"text": "Schnee legt sich", "tun": _boden_bauen},
		{"text": "Eisplatten", "tun": _plattformen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Nadelwald im Frost", "tun": _wald_bauen},
		{"text": "Schneewehen und Findlinge", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Eiszapfen", "tun": _gefahren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Grat: eine weite Rechtskurve über das Eisfeld, dann links hinauf
## zum Gipfel. Die Höhe steigt über die ganze Strecke um 14 m.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),         # Startportal
		Vector3(0, 0, -20),       # gerade Anlaufstrecke
		Vector3(4, 1, -40),       # Beginn der Rechtskurve
		Vector3(16, 2, -56),      # Eisfeld
		Vector3(34, 3, -66),
		Vector3(53, 4, -70),      # Ende der Rechtskurve
		Vector3(70, 5, -80),      # Gletscherspalten, Linkskurve
		Vector3(80, 7, -98),
		Vector3(82, 9, -120),
		Vector3(74, 11, -140),    # Anstieg zur Zapfenpassage
		Vector3(60, 13, -154),
		Vector3(42, 14, -162),    # Gipfel
		Vector3(22, 14, -166),
	])


# =========================================================== Boden

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.schnee(),   # Pulverschnee als Wegdecke
		"kante": Materialbibliothek.firn(),    # festgetretener Firn als Rand
		"klippe": Materialbibliothek.fels(),   # blanker Fels unter der Schneedecke
	}, {"tiefe": 9.0, "schritt": 1.2, "kante_hoehe": 0.32, "kante_breite": 0.75})
	luecken_markieren(Farben.EIS_DUNKEL)


## Der gefrorene See weit unter dem Grat: sichtbar, aber nicht erreichbar –
## wer hinunterfällt, stirbt vorher in der Absturzzone. Er macht die Tiefe
## lesbar, ohne dass dafür Kollision nötig wäre.
func _see_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(260.0, 260.0)
	flaeche.subdivide_width = 8
	flaeche.subdivide_depth = 8
	var mi := MeshInstance3D.new()
	mi.name = "GefrorenerSee"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.eis()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, SEE_HOEHE)
	geometrie.add_child(mi)

	# Ein paar aufgestellte Schollen brechen die spiegelglatte Fläche auf.
	var eis := Materialbibliothek.eis()
	var wuerfel := randi()
	seed(4711)
	for i in 14:
		var s := randf_range(10.0, M_ENDE - 10.0)
		var scholle := MeshInstance3D.new()
		var kasten := BoxMesh.new()
		kasten.size = Vector3(randf_range(3.0, 7.0), randf_range(0.6, 1.4),
				randf_range(3.0, 7.0))
		scholle.mesh = kasten
		scholle.material_override = eis
		scholle.position = LevelWerkzeuge.punkt(verlauf, s,
				randf_range(-26.0, 26.0), SEE_HOEHE + 0.4)
		scholle.rotation = Vector3(randf_range(-0.35, 0.35),
				randf_range(0.0, TAU), randf_range(-0.35, 0.35))
		geometrie.add_child(scholle)
	seed(wuerfel)


func _absturz_spannen() -> void:
	absturzzonen()


# =========================================================== Plattformen

## Eisplatten in den Lücken. Sie sind schmaler als die Trittsteine in
## Level 01 – der Grat soll sich enger anfühlen als der Waldweg.
func _plattformen_bauen() -> void:
	var eis := Materialbibliothek.eis()
	var firn := Materialbibliothek.firn()

	# Anstieg: eine breite Platte zum Üben
	plattform(32.0, 0.0, -0.4, Vector3(3.4, 0.7, 3.4), firn)

	# Eisfeld: zwei versetzte Platten, dazwischen muss gesprungen werden
	plattform(69.0, -1.6, 0.5, Vector3(3.0, 0.6, 3.0), eis)
	plattform(87.0, 1.8, 0.9, Vector3(2.8, 0.6, 2.8), eis)

	# Gletscherspalte: zwei Stufen, die zweite höher – Slide-Jump lohnt
	plattform(127.0, -1.0, 1.0, Vector3(2.6, 0.6, 2.6), eis)
	plattform(148.5, 1.2, 1.8, Vector3(2.8, 0.6, 2.8), eis)

	# Zapfenpassage: erhöhter Umweg über zwei Firnstufen
	plattform(162.0, -3.4, 1.7, Vector3(3.8, 0.7, 4.6), firn)
	plattform(170.0, -3.4, 2.9, Vector3(3.8, 0.7, 4.0), firn)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Gefahren

## Eiszapfen aus dem Boden – dieselbe Mechanik wie die Stacheln in
## Level 01, hier als aus dem Firn gewachsene Zacken gelesen.
func _gefahren_setzen() -> void:
	# Eisfeld: zwei feste Felder an den Rändern, Mitte bleibt frei
	stacheln(58.0, -2.6, Vector2(2.4, 5.0), false)
	stacheln(97.0, 2.4, Vector2(2.4, 5.0), false)

	# Zapfenpassage: einfahrbare Zapfen im Takt, zum Durchtimen
	stacheln(156.0, 1.8, Vector2(3.0, 4.0), true)
	stacheln(164.0, 2.2, Vector2(3.0, 4.5), true)
	stacheln(172.0, 1.6, Vector2(3.0, 4.0), true)
	stacheln(178.0, -1.4, Vector2(2.6, 3.6), true)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Anstieg: ruhige Einführung ----------
	kiste(Kiste.Art.NORMAL, 8.0, -1.6)
	kiste(Kiste.Art.NORMAL, 8.0, 0.0)
	kiste(Kiste.Art.NORMAL, 8.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 14.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 22.0, -2.4)
	# Stapel: die obere ist nur mit einem Sprung von der unteren zu holen
	kiste(Kiste.Art.EISEN, 26.0, 1.8)
	kiste(Kiste.Art.NORMAL, 26.0, 1.8, 1.6)
	kiste(Kiste.Art.NORMAL, 40.0, -1.4)
	kiste(Kiste.Art.NORMAL, 44.0, 1.4)

	# ---------- Eisfeld: Kisten am Rand der Lücken ----------
	kiste(Kiste.Art.NORMAL, 52.0, 0.0)
	kiste(Kiste.Art.NORMAL, 55.0, -2.0)
	kiste(Kiste.Art.FEDER, 63.0, 0.0)          # federt über die Lücke
	kiste(Kiste.Art.NORMAL, 76.0, 0.0)
	kiste(Kiste.Art.NORMAL, 80.0, 1.6)
	kiste(Kiste.Art.CHECKPOINT, 92.0, -2.2)
	kiste(Kiste.Art.NORMAL, 96.0, 0.0)
	kiste(Kiste.Art.NORMAL, 100.0, -1.8)

	# ---------- Spalten: Sprungfedern über die weiten Lücken ----------
	kiste(Kiste.Art.NORMAL, 108.0, 0.0)
	kiste(Kiste.Art.NORMAL, 112.0, -1.6)
	kiste(Kiste.Art.SPRUNG, 120.0, 0.0)        # unzerstörbare Sprungfeder
	kiste(Kiste.Art.NORMAL, 134.0, 1.4)
	kiste(Kiste.Art.NORMAL, 138.0, -1.4)
	kiste(Kiste.Art.NITRO, 142.0, 2.0)         # Berührung genügt zum Auslösen

	# ---------- Zapfen: TNT-Kette hinter den Zapfenfeldern ----------
	kiste(Kiste.Art.CHECKPOINT, 154.0, -3.0)
	kiste(Kiste.Art.TNT, 160.0, -1.0)
	kiste(Kiste.Art.NORMAL, 160.0, 0.6)
	kiste(Kiste.Art.NORMAL, 166.0, -0.8)
	kiste(Kiste.Art.TNT, 174.0, 0.4)
	kiste(Kiste.Art.NORMAL, 178.0, -2.2)

	# ---------- Gipfel: Belohnung ----------
	kiste(Kiste.Art.NORMAL, 188.0, -2.0)
	kiste(Kiste.Art.NORMAL, 188.0, 0.0)
	kiste(Kiste.Art.NORMAL, 188.0, 2.0)
	kiste(Kiste.Art.LEBEN, 194.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 199.0, -1.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 199.0, 1.8)


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Anstieg: Draufspringen ----------
	gegner(PANZERKAEFER, 18.0, 0.0, 3.5, true)
	gegner(PANZERKAEFER, 42.0, 1.5, 3.0, true)

	# ---------- Eisfeld: Drehschlag ----------
	gegner(SUMPFKROETE, 54.0, 0.0, 3.0, true)
	gegner(SUMPFKROETE, 78.0, -1.0, 2.5, true)
	gegner(PANZERKAEFER, 94.0, 0.0, 3.0, true)

	# ---------- Spalten: gemischt, auf schmalem Grat ----------
	gegner(SUMPFKROETE, 110.0, 0.0, 2.5, true)
	gegner(PANZERKAEFER, 136.0, 0.0, 2.5, true)

	# ---------- Zapfen: Slide zwischen den Zapfenfeldern ----------
	gegner(STELZENVOGEL, 158.0, -1.6, 3.0, true)
	gegner(STELZENVOGEL, 168.0, 0.5, 3.5, true)
	gegner(STELZENVOGEL, 176.0, -0.5, 3.0, true)

	# ---------- Gipfel: letzter Wächter ----------
	gegner(SUMPFKROETE, 192.0, 2.0, 3.5, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 20.0, 8, 0.0)
	fruechte_reihe(24.0, 30.0, 4, -2.2)
	# Über die Lücken jeweils ein Bogen – er zeigt die Sprungbahn an
	fruechte_bogen(29.0, 35.0, 5, 0.0)
	fruechte_reihe(50.0, 62.0, 6, 1.8)
	fruechte_bogen(66.5, 71.5, 5, -1.4)
	fruechte_reihe(74.0, 82.0, 5, 0.0)
	fruechte_bogen(84.5, 89.5, 5, 1.6)
	fruechte_reihe(92.0, 102.0, 5, -1.6)
	fruechte_reihe(106.0, 122.0, 7, 0.0)
	fruechte_bogen(124.5, 129.5, 5, -1.0, 3.2)
	fruechte_reihe(132.0, 144.0, 6, 0.0)
	fruechte_bogen(146.5, 151.5, 5, 1.0, 3.2)
	fruechte_reihe(154.0, 180.0, 10, -3.2)
	fruechte_reihe(184.0, 206.0, 9, 0.0)


# =========================================================== Kulisse

## Verschneiter Nadelwald auf beiden Seiten, unterhalb des Grats.
## Die Bäume stehen auf Seehöhe und reichen mit den Spitzen bis über den
## Weg – dadurch wirkt der Grat schmal, ohne dass er es sein muss.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(20802)
	var anzahl := 74
	for i in anzahl:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * randf_range(9.0, 30.0)
		var hoehe := randf_range(6.0, 12.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM
		baum.hoehe = hoehe
		baum.staerke = randf_range(0.7, 1.15)
		baum.saat = 3000 + i
		baum.laubfarbe = Farben.NADEL_FROST.lerp(Farben.SCHNEE, randf_range(0.1, 0.45))
		baum.kollision = false
		baum.wind = false          # im Frost steht der Wald still
		# Bäume wachsen vom See herauf, nicht vom Weg – sonst schwebten sie.
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer,
				SEE_HOEHE + randf_range(0.0, 3.0))
		deko.add_child(baum)
	seed(wuerfel)


## Schneewehen am Wegrand und vereinzelte Findlinge. Beides ohne
## Kollision: es soll den Grat rahmen, nicht den Weg verengen.
func _deko_bauen() -> void:
	var schnee := Materialbibliothek.schnee()
	var wuerfel := randi()
	seed(20803)
	for i in 60:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 0.6)
		if rand < 1.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var wehe := MeshInstance3D.new()
		var kugel := SphereMesh.new()
		kugel.radius = randf_range(0.5, 1.3)
		kugel.height = kugel.radius * 2.0
		kugel.radial_segments = 10
		kugel.rings = 6
		wehe.mesh = kugel
		wehe.material_override = schnee
		wehe.scale = Vector3(randf_range(1.2, 2.2), randf_range(0.28, 0.5),
				randf_range(1.0, 1.8))
		wehe.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand,
				-kugel.radius * 0.25)
		wehe.rotation.y = randf() * TAU
		deko.add_child(wehe)

	# Findlinge unterhalb des Grats, als Maßstab für die Tiefe
	for i in 16:
		var s := randf_range(0.0, M_ENDE)
		var stein := STEIN.instantiate() as Stein
		stein.groesse = randf_range(1.4, 3.4)
		stein.bemoost = false
		stein.kollision = false
		stein.saat = 7000 + i
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				randf_range(-24.0, 24.0), SEE_HOEHE + 0.3)
		deko.add_child(stein)
	seed(wuerfel)
