extends KorridorLevel
## Level 09 – "Sumpfgeysir"
##
## Eine Schlickebene, unter der Gas steht. Aus Spalten im Boden fahren
## Fontänen hoch, Schlammlöcher blubbern im Takt, und wo der feste Grund
## aufhört, tragen Seerosen und Wehrbohlen weiter.
##
## Das Level ist der TAKTGEBER des zweiten Raums. In 07 lernt man, wohin
## man springt; in 08, wann. Hier kommt beides zusammen und wird schnell:
## Fast jede Stelle hat einen Rhythmus, und fast jeder Rhythmus lässt
## genau eine Lücke.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  34  Schlickufer   – fester Grund, erste Fontäne zum Ansehen
##    34 –  86  Blasenfeld    – Schlammlöcher als wandernde Welle
##    86 – 140  Fontänenpfad  – schmaler Weg zwischen den Geysiren
##   140 – 186  Trittsteine   – Seerosen und Wehrbohlen über dem Schlick
##   186 – 216  Gasrücken     – trockener Anstieg, Extraleben, Zielportal
##
## Die Fontänen sind `Feuerspeier` mit anderem Namen: Sumpfgas brennt,
## und ein Bauteil, das im Takt eine tödliche Säule ausfährt, ist genau
## das, was hier gebraucht wird.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")

# Strecken-Marken der Abschnitte
const M_UFER := 0.0
const M_BLASEN := 34.0
const M_FONTAENEN := 86.0
const M_STEINE := 140.0
const M_RUECKEN := 186.0
const M_ENDE := 216.0

# Höhen relativ zum Weg
const SCHLICK_HOEHE := -0.8     ## Spiegel des Schlicks, dicht unter dem Weg
const SCHLICKGRUND := -3.0      ## sichtbarer Grund darunter
const ABSTURZ := -3.8           ## Notnagel unterhalb des Schlicks
const ROSE_HOEHE := -0.5        ## Trittfläche eines Seerosenblatts
const BOHLE_OBEN := -0.35
const BOHLE_UNTEN := -1.7


const STRECKE := [
	# --- Schlickufer: fester Grund zum Ankommen ---
	{"von": 0.0, "bis": 34.0, "breite": 12.0, "breite_ende": 9.0},
	# --- Blasenfeld: durchgehend, dafür voller Schlammlöcher ---
	{"von": 34.0, "bis": 86.0, "breite": 9.0},
	# --- Fontänenpfad: schmal, damit die Säulen zählen ---
	{"von": 86.0, "bis": 112.0, "breite": 6.5},
	{"von": 116.0, "bis": 140.0, "breite": 6.5, "breite_ende": 8.0},
	# --- Trittsteine: zwei Lücken über offenem Schlick ---
	{"von": 140.0, "bis": 150.0, "breite": 8.0},
	{"von": 158.0, "bis": 166.0, "breite": 7.0},
	{"von": 174.0, "bis": 186.0, "breite": 8.0},
	# --- Gasrücken: breiter Abschluss ---
	{"von": 186.0, "bis": 216.0, "breite": 11.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Ebene wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Schlickgrund", "tun": _grund_bauen},
		{"text": "Fester Grund", "tun": _boden_bauen},
		{"text": "Schlick steigt", "tun": _schlick_fluten},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Schlammlöcher blubbern", "tun": _blasen_bauen},
		{"text": "Gas findet den Weg", "tun": _fontaenen_bauen},
		{"text": "Seerosen und Bohlen", "tun": _trittsteine_bauen},
		{"text": "Dunst über dem Schlick", "tun": _stimmung_setzen},
		{"text": "Weiden und Binsen", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Ein liegendes S: erst nach links um die große Blase herum, dann zurück
## nach rechts über die Trittsteine, zuletzt hinauf auf den Gasrücken.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),          # Startportal
		Vector3(0, 0, -16),
		Vector3(-6, 0, -34),       # Linkskurve ins Blasenfeld
		Vector3(-20, 0, -48),
		Vector3(-38, 0, -56),
		Vector3(-58, 0, -58),      # Fontänenpfad, fast gerade
		Vector3(-78, 0, -54),
		Vector3(-94, 0, -44),      # Rechtskurve zu den Trittsteinen
		Vector3(-106, 0, -30),
		Vector3(-112, 1, -12),
		Vector3(-112, 2, 6),       # Anstieg auf den Gasrücken
		Vector3(-106, 4, 22),
		Vector3(-96, 5, 34),
	])


# =========================================================== Boden

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.moorboden(),    # getrockneter Schlick
		"kante": Materialbibliothek.algen(),       # bewachsene Kante
		"klippe": Materialbibliothek.moorboden(),
	}, {"tiefe": 2.8, "schritt": 1.0, "kante_hoehe": 0.24, "kante_breite": 0.6})
	luecken_markieren(Farben.MOOR_DUNKEL)


## Der Grund unter dem Schlick – Kulisse, wie in Level 07 und 08.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(250.0, 250.0)
	var mi := MeshInstance3D.new()
	mi.name = "Schlickgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.moorboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, SCHLICKGRUND)
	geometrie.add_child(mi)


func _schlick_fluten() -> void:
	var schritt := 20.0
	var s := 0.0
	while s < M_ENDE:
		if s < M_RUECKEN - 8.0:
			var w := wasser(s + schritt * 0.5, Vector2(42.0, schritt + 2.0),
					SCHLICK_HOEHE)
			w.tiefe = 1.8
			w.toedlich = true
			# Schlick ist zäh: kaum Wellen, kaum Spiegelung.
			w.wellen_hoehe = 0.04
			w.wellen_tempo = 0.3
			w.farbe_tief = Farben.MOOR_DUNKEL
			w.farbe_hell = Farben.TUEMPEL_HELL.darkened(0.25)
			w.spiegelung = 0.10
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 56.0)


# =========================================================== Taktgeber

## Das Blasenfeld: Schlammlöcher, die im Takt tödlich werden.
##
## Als WELLE gesetzt, nicht als Feld gleichphasiger Löcher – erst der
## Versatz macht daraus etwas, durch das man hindurchlaufen kann. Wer im
## Rhythmus bleibt, geht mit der Lücke mit; wer stehen bleibt, wartet.
func _blasen_bauen() -> void:
	taktwelle(40.0, 54.0, 5, 0.0, Vector2(2.6, 2.6), 0.22)
	# Zweite Welle, breiter gestellt: Hier muss man zusätzlich ausweichen.
	taktwelle(60.0, 72.0, 4, -2.0, Vector2(2.4, 2.4), 0.3)
	taktwelle(62.0, 74.0, 4, 2.0, Vector2(2.4, 2.4), 0.55)
	# Ein einzelnes großes Loch als Abschluss des Abschnitts.
	taktflaeche(80.0, 0.0, Vector2(4.4, 3.2), 0.0)


## Die Geysire. Sie stehen am Rand und speien quer über den Weg – eine
## Fontäne mitten im Weg wäre eine Wand, keine Aufgabe.
##
## `richtung` 0 heißt: quer nach rechts, 180 quer nach links. Die Phasen
## sind gegeneinander versetzt, damit nie beide Seiten zugleich sperren.
func _fontaenen_bauen() -> void:
	feuerspeier(92.0, -3.0, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(99.0, 3.0, 1.0, 180.0, 3.2, 0.5)
	feuerspeier(106.0, -3.0, 1.1, 0.0, 3.4, 0.25)
	feuerspeier(120.0, 3.0, 1.1, 180.0, 3.4, 0.0, true)
	feuerspeier(128.0, -3.0, 1.2, 0.0, 3.6, 0.4, true)
	feuerspeier(135.0, 3.0, 1.0, 180.0, 3.2, 0.15)

	# Eine Fontäne, die den Weg der LÄNGE nach bestreicht (`richtung` 90°
	# statt quer). Vor ihr hilft kein schnelleres Laufen, nur ein Schritt
	# zur Seite – der einzige Geysir im Level, dem man nicht durch Timing
	# allein entkommt.
	feuerspeier(108.0, -2.6, 1.0, 90.0, 4.0, 0.0)


## Über den drei Lücken tragen Seerosen und Wehrbohlen.
##
## Erst zwei stehende Blätter (man lernt den Abstand), dann eine Bohle
## dazwischen (man lernt den Takt), zuletzt beides gemischt.
func _trittsteine_bauen() -> void:
	# Erste Lücke, 150 bis 158: zwei ruhige Blätter
	seerose(152.5, -0.8, ROSE_HOEHE, 2.6)
	seerose(155.5, 0.8, ROSE_HOEHE, 2.6)

	# Zweite Lücke, 166 bis 174: Blatt, Bohle, Blatt
	seerose(168.0, -1.0, ROSE_HOEHE, 2.4)
	wehrbohle(170.5, 0.0, BOHLE_OBEN, BOHLE_UNTEN, 0.0,
			Vector2(3.0, 2.6), 2.4, 1.0)
	seerose(173.0, 1.0, ROSE_HOEHE, 2.4)

	# Ein Floß, das neben dem Weg über das offene Feld fährt. Es führt
	# nirgends hin – es ist der Umweg selbst, und auf ihm liegt eine
	# Fruchtreihe, die vom Weg aus nicht zu holen ist.
	floss(150.0, 158.0, -5.0, ROSE_HOEHE, Vector2(3.4, 2.8), 6.0, 2.2, 2.2)


# =========================================================== Stimmung

func _stimmung_setzen() -> void:
	stimmung(M_BLASEN, M_FONTAENEN, Farben.TUEMPEL_HELL, 0.022, 0.7,
			Color(0.48, 0.56, 0.46))
	# Am Fontänenpfad steht das Gas in der Luft: wärmer und dichter.
	stimmung(M_FONTAENEN, M_STEINE, Color(0.72, 0.66, 0.42), 0.030, 0.8,
			Color(0.62, 0.56, 0.40))
	stimmung(M_STEINE, M_ENDE, Farben.TUEMPEL_HELL, 0.016, 0.9,
			Color(0.55, 0.60, 0.52))

	# Nah am Dunst gehalten, sonst steht der Ring als dunkler Balken im
	# Bild statt als Ferne (Begründung im Kopf von `horizont.gd`).
	horizont(185.0, 14.0, Color(0.42, 0.48, 0.40), Color(0.52, 0.58, 0.48),
			false, -4.5)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Schlickufer ----------
	kiste(Kiste.Art.NORMAL, 6.0, -1.8)
	kiste(Kiste.Art.NORMAL, 6.0, 0.0)
	kiste(Kiste.Art.NORMAL, 6.0, 1.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 12.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 16.0, 2.4)
	kiste(Kiste.Art.CHECKPOINT, 20.0, -2.4)
	kiste(Kiste.Art.EISEN, 27.0, 1.6)
	kiste(Kiste.Art.NORMAL, 27.0, 1.6, 1.6)
	kiste(Kiste.Art.NORMAL, 31.0, -1.6)

	# ---------- Blasenfeld: zwischen den Löchern, nie darauf ----------
	kiste(Kiste.Art.NORMAL, 37.0, -2.6)
	kiste(Kiste.Art.NORMAL, 37.0, 2.6)
	kiste(Kiste.Art.FEDER, 57.0, 0.0)
	kiste(Kiste.Art.NORMAL, 58.0, -2.8)
	kiste(Kiste.Art.NORMAL, 58.0, 2.8)
	kiste(Kiste.Art.CHECKPOINT, 76.0, -2.6)
	kiste(Kiste.Art.NORMAL, 76.0, 2.6)
	kiste(Kiste.Art.TNT, 84.0, 2.4)
	kiste(Kiste.Art.NORMAL, 84.0, -2.4)

	# ---------- Fontänenpfad: eng, jede Kiste hält auf ----------
	kiste(Kiste.Art.NORMAL, 89.0, 0.0)
	kiste(Kiste.Art.NORMAL, 96.0, -1.4)
	kiste(Kiste.Art.NORMAL, 103.0, 1.4)
	kiste(Kiste.Art.SCHUTZ, 110.0, -1.6)
	kiste(Kiste.Art.CHECKPOINT, 118.0, -1.8)
	kiste(Kiste.Art.NORMAL, 124.0, 1.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 131.0, -1.4)
	kiste(Kiste.Art.NORMAL, 138.0, 1.6)

	# ---------- Trittsteine: nur auf den festen Stücken ----------
	kiste(Kiste.Art.NORMAL, 143.0, 0.0)
	kiste(Kiste.Art.NORMAL, 147.0, -1.6)
	kiste(Kiste.Art.CHECKPOINT, 161.0, 0.0)
	kiste(Kiste.Art.NORMAL, 164.0, 1.4)
	kiste(Kiste.Art.NORMAL, 177.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 182.0, -1.6)

	# ---------- Gasrücken ----------
	kiste(Kiste.Art.NORMAL, 190.0, -2.0)
	kiste(Kiste.Art.NORMAL, 190.0, 0.0)
	kiste(Kiste.Art.NORMAL, 190.0, 2.0)
	kiste(Kiste.Art.LEBEN, 196.0, 0.0)
	kiste(Kiste.Art.NORMAL, 202.0, -2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 206.0, 2.2)


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Schlickufer ----------
	gegner(PANZERKAEFER, 14.0, 0.0, 3.5, true)
	gegner(SUMPFKROETE, 30.0, -1.0, 2.5, true)

	# ---------- Blasenfeld ----------
	gegner(SUMPFKROETE, 45.0, 0.0, 3.0, true)
	gegner(STELZENSPINNE, 64.0, 1.6, 3.0, true)
	gegner(PANZERKAEFER, 78.0, -1.6, 3.0, true)

	# ---------- Fontänenpfad: einer je Abschnittshälfte, mehr wäre zu viel
	gegner(SUMPFKROETE, 101.0, 0.0, 2.0, true)
	gegner(STELZENSPINNE, 126.0, 0.0, 2.0, true)

	# ---------- Trittsteine: nur auf festem Grund ----------
	gegner(PANZERKAEFER, 146.0, 0.0, 2.5, true)
	gegner(SUMPFKROETE, 180.0, 0.0, 2.5, true)

	# ---------- Gasrücken ----------
	gegner(STELZENSPINNE, 199.0, 2.0, 3.0, true)
	gegner(SUMPFKROETE, 209.0, -2.0, 3.0, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 18.0, 7, 0.0)
	fruechte_reihe(36.0, 54.0, 8, 0.0)
	fruechte_reihe(60.0, 74.0, 6, 0.0)
	fruechte_reihe(78.0, 84.0, 4, 0.0)
	fruechte_reihe(88.0, 110.0, 9, 0.0)
	# Über der Lücke zwischen den beiden Hälften des Fontänenpfads.
	fruechte_bogen(112.5, 115.5, 5, 0.0, 2.8)
	fruechte_reihe(118.0, 138.0, 8, 0.0)
	fruechte_bogen(150.5, 157.5, 6, 0.0, 2.4)
	fruechte_bogen(166.5, 173.5, 6, 0.0, 2.4)
	# Auf der Bahn des Floßes – vom Weg aus nicht zu erreichen.
	fruechte_reihe(151.0, 157.0, 5, -5.0, 0.6)
	fruechte_reihe(176.0, 184.0, 5, 0.0)
	fruechte_reihe(188.0, 212.0, 9, 0.0)


# =========================================================== Kulisse

## Weiden, Binsen und Wurzeln. Am Fontänenpfad steht nichts – dort soll
## der Blick frei auf die Säulen fallen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(90901)

	for i in 56:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * randf_range(9.0, 26.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 4 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(4.0, 8.5)
		baum.staerke = randf_range(0.5, 0.9)
		baum.saat = 4600 + i
		baum.laubfarbe = Farben.ALGE.lerp(Farben.LAUB_DUNKEL, randf())
		baum.kollision = false
		var fuss := SCHLICK_HOEHE - 0.3 if s < M_RUECKEN else -0.2
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, fuss)
		deko.add_child(baum)

	# Binsen dicht am Schlickrand
	for i in 52:
		var s := randf_range(2.0, M_ENDE - 4.0)
		if s > M_FONTAENEN and s < M_STEINE:
			continue                    # Fontänenpfad bleibt frei
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.5, 3.0)),
				SCHLICK_HOEHE + 0.1 if s < M_RUECKEN else 0.0)
		horst.flaeche = Vector2(2.6, 2.6)
		horst.halm_hoehe = randf_range(0.8, 1.3)
		horst.farbe_unten = Farben.ALGE.darkened(0.4)
		horst.farbe_oben = Farben.SCHILF
		horst.saat = 5600 + i
		deko.add_child(horst)

	# Wurzeln, die aus dem Schlick greifen
	for i in 18:
		var s := randf_range(M_BLASEN, M_RUECKEN)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate()
		if "saat" in w:
			w.set("saat", 8600 + i)
		w.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(5.0, 13.0), SCHLICK_HOEHE - 0.15)
		w.rotation.y = randf() * TAU
		deko.add_child(w)

	# Pilze auf dem trockenen Anfang und Ende
	for i in 18:
		var s: float = randf_range(2.0, 32.0) if i % 2 == 0 \
				else randf_range(M_RUECKEN, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 2 == 0 else Kleinzeug.Art.BUSCH
		kleinzeug.saat = 7600 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	seed(wuerfel)
