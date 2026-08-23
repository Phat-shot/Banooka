extends KorridorLevel
## Level 03 – "Moorbrücken"
##
## Ein Bohlenweg durch ein Moor. Anders als in Level 01 und 02 liegt unter
## dem Weg kein Abgrund, sondern Wasser: Wer danebentritt, ertrinkt. Das
## macht denselben Fehler sichtbarer – der Sturz endet nicht im Nichts,
## sondern mit einem Platsch.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  44  Ufer        – fester Torfboden, breite Anlaufstrecke
##    44 –  98  Bohlenweg   – schmale Stege über offenem Wasser, Lücken
##    98 – 146  Wurzelinseln– einzelne Inseln, dazwischen wird gesprungen
##   146 – 184  Schilfgürtel– Schilf und Nebel, Stelzenvögel
##   184 – 212  Anhöhe      – trockener Grund, Extraleben, Zielportal
##
## Die Wasserfläche liegt knapp unter dem Weg (`WASSER_HOEHE`), die
## Absturzzone noch darunter: Zuerst greift die tödliche Wasserfläche,
## die Zone ist nur der Notnagel, falls jemand daran vorbeifällt.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENVOGEL := preload("res://scenes/enemies/Stelzenvogel.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# Strecken-Marken der Abschnitte
const M_UFER := 0.0
const M_BOHLEN := 44.0
const M_INSELN := 98.0
const M_SCHILF := 146.0
const M_ANHOEHE := 184.0
const M_ENDE := 212.0

# Höhen relativ zum Weg
const WASSER_HOEHE := -1.1     ## Wasserspiegel knapp unter dem Steg
const MOORGRUND := -3.2        ## sichtbarer Grund unter dem Wasser
const ABSTURZ := -4.0          ## Notnagel unterhalb des Wassers


const STRECKE := [
	# --- Ufer: fester Boden, eine erste Lücke ---
	{"von": 0.0, "bis": 28.0, "breite": 11.0},
	{"von": 32.0, "bis": 44.0, "breite": 10.0, "breite_ende": 8.0},
	# --- Bohlenweg: schmal, drei Lücken über offenem Wasser ---
	{"von": 44.0, "bis": 60.0, "breite": 6.0},
	{"von": 65.0, "bis": 78.0, "breite": 5.5},
	{"von": 83.0, "bis": 98.0, "breite": 6.0, "breite_ende": 8.0},
	# --- Wurzelinseln: kurze Stücke mit weiten Sprüngen dazwischen ---
	{"von": 98.0, "bis": 112.0, "breite": 9.0},
	{"von": 118.0, "bis": 130.0, "breite": 8.0},
	{"von": 136.0, "bis": 146.0, "breite": 9.0},
	# --- Schilfgürtel: breiter, dafür voller Gegner ---
	{"von": 146.0, "bis": 184.0, "breite": 10.0},
	# --- Anhöhe: trockener Abschluss ---
	{"von": 184.0, "bis": 212.0, "breite": 12.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Moor wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Torfgrund", "tun": _grund_bauen},
		{"text": "Stege werden gelegt", "tun": _boden_bauen},
		{"text": "Wasser steigt", "tun": _wasser_fluten},
		{"text": "Wurzelinseln", "tun": _plattformen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Sumpfwald", "tun": _wald_bauen},
		{"text": "Schilf und Farne", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Weg schlängelt sich flach durchs Moor – kaum Höhenunterschied,
## dafür zwei enge Kurven. Erst die Anhöhe am Ende steigt an.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),         # Startportal
		Vector3(0, 0, -18),
		Vector3(-5, 0, -36),      # Linkskurve ins Moor
		Vector3(-16, 0, -50),
		Vector3(-32, 0, -58),     # Bohlenweg
		Vector3(-50, 0, -60),
		Vector3(-66, 0, -70),     # Rechtskurve zu den Inseln
		Vector3(-76, 0, -86),
		Vector3(-78, 1, -106),
		Vector3(-70, 1, -124),    # Schilfgürtel
		Vector3(-56, 2, -136),
		Vector3(-38, 4, -144),    # Anstieg zur Anhöhe
		Vector3(-18, 5, -148),
	])


# =========================================================== Boden

func _boden_bauen() -> void:
	# Ufer und Anhöhe sind Torf, der Mittelteil ist Bohlensteg. Der
	# Korridor kennt nur ein Material je Fläche, deshalb liegt hier Holz
	# als Wegdecke und der Torf bleibt der Kulisse unten überlassen.
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.bohlen(),      # Bohlen als Wegdecke
		"kante": Materialbibliothek.algen(),      # bewachsene Kante
		"klippe": Materialbibliothek.moorboden(), # Torf unter dem Steg
	}, {"tiefe": 3.0, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.6})
	luecken_markieren(Farben.BOHLE.darkened(0.3))


## Der Moorgrund unter dem Wasser. Nur Kulisse – begehbar ist er nicht,
## das Wasser darüber ist tödlich.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(240.0, 240.0)
	var mi := MeshInstance3D.new()
	mi.name = "Moorgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.moorboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, MOORGRUND)
	geometrie.add_child(mi)


## Wasserflächen längs des Weges. Sie in Stücken zu setzen statt als eine
## große Platte ist nötig, weil der Weg zwei enge Kurven macht – eine
## einzige Fläche würde an den Außenseiten weit über den Rand stehen.
func _wasser_fluten() -> void:
	var schritt := 20.0
	var s := 0.0
	while s < M_ENDE:
		# Auf der Anhöhe steht kein Wasser mehr.
		if s < M_ANHOEHE - 6.0:
			var w := wasser(s + schritt * 0.5, Vector2(46.0, schritt + 2.0),
					WASSER_HOEHE)
			w.tiefe = 2.0
			w.toedlich = true
			w.wellen_hoehe = 0.09
			w.wellen_tempo = 0.55
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 60.0)


# =========================================================== Plattformen

## Wurzelinseln und Trittstümpfe in den Lücken.
func _plattformen_bauen() -> void:
	var holz := Materialbibliothek.wurzel()
	var algen := Materialbibliothek.algen()

	# Ufer: eine breite Insel zum Üben
	plattform(30.0, 0.0, -0.35, Vector3(3.4, 0.7, 3.2), algen)

	# Bohlenweg: schmale Stümpfe, jeweils leicht versetzt
	plattform(62.5, -1.2, -0.1, Vector3(2.2, 0.8, 2.2), holz)
	plattform(80.5, 1.2, -0.1, Vector3(2.2, 0.8, 2.2), holz)

	# Wurzelinseln: zwei Stufen je Lücke, die zweite höher
	plattform(114.0, -1.4, 0.3, Vector3(2.6, 0.8, 2.6), holz)
	plattform(116.0, 1.4, 0.9, Vector3(2.4, 0.8, 2.4), holz)
	plattform(132.0, 1.2, 0.4, Vector3(2.6, 0.8, 2.6), holz)
	plattform(134.0, -1.2, 1.0, Vector3(2.4, 0.8, 2.4), holz)

	# Schilfgürtel: erhöhter Umweg über zwei Wurzelteller
	plattform(158.0, -3.4, 1.4, Vector3(3.6, 0.7, 4.2), algen)
	plattform(166.0, -3.4, 2.4, Vector3(3.6, 0.7, 3.8), algen)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Ufer ----------
	kiste(Kiste.Art.NORMAL, 7.0, -1.6)
	kiste(Kiste.Art.NORMAL, 7.0, 0.0)
	kiste(Kiste.Art.NORMAL, 7.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 13.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 20.0, -2.4)
	kiste(Kiste.Art.EISEN, 25.0, 1.6)
	kiste(Kiste.Art.NORMAL, 25.0, 1.6, 1.6)
	kiste(Kiste.Art.NORMAL, 38.0, 0.0)

	# ---------- Bohlenweg: eng, jede Kiste kostet Standfläche ----------
	kiste(Kiste.Art.NORMAL, 48.0, 0.0)
	kiste(Kiste.Art.NORMAL, 52.0, -1.2)
	kiste(Kiste.Art.FEDER, 57.0, 0.0)
	kiste(Kiste.Art.NORMAL, 68.0, 0.0)
	kiste(Kiste.Art.NORMAL, 72.0, 1.0)
	kiste(Kiste.Art.CHECKPOINT, 86.0, -1.4)
	kiste(Kiste.Art.NORMAL, 90.0, 0.0)
	kiste(Kiste.Art.NITRO, 94.0, 1.6)

	# ---------- Wurzelinseln ----------
	kiste(Kiste.Art.NORMAL, 102.0, -1.8)
	kiste(Kiste.Art.NORMAL, 102.0, 1.8)
	kiste(Kiste.Art.SPRUNG, 108.0, 0.0)
	kiste(Kiste.Art.NORMAL, 122.0, 0.0)
	kiste(Kiste.Art.NORMAL, 126.0, -1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 140.0, 0.0)
	kiste(Kiste.Art.NORMAL, 143.0, 1.8)

	# ---------- Schilfgürtel: TNT hinter dem Schilf ----------
	kiste(Kiste.Art.CHECKPOINT, 149.0, -3.0)
	kiste(Kiste.Art.TNT, 156.0, -1.0)
	kiste(Kiste.Art.NORMAL, 156.0, 0.8)
	kiste(Kiste.Art.NORMAL, 163.0, -0.6)
	kiste(Kiste.Art.TNT, 172.0, 0.6)
	kiste(Kiste.Art.NORMAL, 178.0, -2.2)
	kiste(Kiste.Art.NORMAL, 180.0, 2.2)

	# ---------- Anhöhe ----------
	kiste(Kiste.Art.NORMAL, 190.0, -2.0)
	kiste(Kiste.Art.NORMAL, 190.0, 0.0)
	kiste(Kiste.Art.NORMAL, 190.0, 2.0)
	kiste(Kiste.Art.LEBEN, 196.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 201.0, -1.8)


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Ufer: Draufspringen auf festem Boden ----------
	gegner(PANZERKAEFER, 16.0, 0.0, 3.5, true)
	gegner(PANZERKAEFER, 40.0, -1.2, 2.5, true)

	# ---------- Bohlenweg: Drehschlag auf schmalem Steg ----------
	gegner(SUMPFKROETE, 50.0, 0.0, 2.0, true)
	gegner(SUMPFKROETE, 74.0, 0.0, 2.0, true)
	gegner(PANZERKAEFER, 92.0, 0.0, 2.5, true)

	# ---------- Wurzelinseln ----------
	gegner(SUMPFKROETE, 105.0, 0.0, 3.0, true)
	gegner(SUMPFKROETE, 124.0, 0.0, 2.5, true)
	gegner(PANZERKAEFER, 140.0, 0.0, 3.0, true)

	# ---------- Schilfgürtel: Slide zwischen dem Schilf ----------
	gegner(STELZENVOGEL, 152.0, -1.6, 3.0, true)
	gegner(STELZENVOGEL, 160.0, 0.8, 3.5, true)
	gegner(STELZENVOGEL, 170.0, -0.6, 3.0, true)
	gegner(STELZENVOGEL, 179.0, 1.4, 3.0, true)

	# ---------- Anhöhe ----------
	gegner(SUMPFKROETE, 194.0, 2.0, 3.0, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 18.0, 7, 0.0)
	fruechte_bogen(27.0, 33.0, 5, 0.0)
	fruechte_reihe(46.0, 58.0, 6, 0.0)
	fruechte_bogen(60.5, 64.5, 5, -1.0)
	fruechte_reihe(67.0, 76.0, 5, 0.0)
	fruechte_bogen(78.5, 82.5, 5, 1.0)
	fruechte_reihe(85.0, 96.0, 5, -1.2)
	fruechte_reihe(100.0, 110.0, 5, 0.0)
	fruechte_bogen(112.5, 117.5, 5, 0.0, 3.0)
	fruechte_reihe(120.0, 128.0, 5, 1.4)
	fruechte_bogen(130.5, 135.5, 5, 0.0, 3.0)
	fruechte_reihe(138.0, 144.0, 4, -1.4)
	fruechte_reihe(148.0, 182.0, 12, -3.2)
	fruechte_reihe(186.0, 206.0, 8, 0.0)


# =========================================================== Kulisse

## Sumpfwald: kahle Stämme im Wasser, dazwischen einzelne Laubkronen.
## Die Bäume stehen im Wasser, nicht auf dem Steg – der Weg soll frei
## bleiben, der Blick daneben dicht.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(30301)
	for i in 68:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * randf_range(7.0, 26.0)
		var totholz := i % 3 == 0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if totholz else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(5.0, 11.0)
		baum.staerke = randf_range(0.6, 1.1)
		baum.saat = 4000 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.ALGE, randf())
		baum.kollision = false
		# Auf der Anhöhe stehen sie auf trockenem Grund, sonst im Wasser.
		var fuss := WASSER_HOEHE - 0.4 if s < M_ANHOEHE else -0.2
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, fuss)
		deko.add_child(baum)
	seed(wuerfel)


## Schilf am Wegrand, Farne auf dem Ufer, Wurzeln über den Inseln.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(30302)

	# Schilfhorste: Grasfelder in Schilffarbe, dicht am Wasser
	for i in 46:
		var s := randf_range(2.0, M_ANHOEHE)
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.6, 3.0)), WASSER_HOEHE + 0.1)
		horst.flaeche = Vector2(3.0, 3.0)
		horst.halm_hoehe = randf_range(0.7, 1.25)   # Schilf steht hoch
		horst.farbe_unten = Farben.ALGE.darkened(0.35)
		horst.farbe_oben = Farben.SCHILF
		horst.saat = 5000 + i
		deko.add_child(horst)

	# Farne und Pilze auf dem festen Grund am Anfang und Ende
	for i in 26:
		var s: float = randf_range(2.0, 42.0) if i % 2 == 0 \
				else randf_range(M_ANHOEHE, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.FARN
		kleinzeug.saat = 6000 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	# Wurzeln, die aus dem Wasser greifen
	for i in 20:
		var s := randf_range(M_BOHLEN, M_SCHILF)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate()
		if "saat" in w:
			w.set("saat", 8000 + i)
		w.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(4.0, 12.0), WASSER_HOEHE - 0.2)
		w.rotation.y = randf() * TAU
		deko.add_child(w)
	seed(wuerfel)
