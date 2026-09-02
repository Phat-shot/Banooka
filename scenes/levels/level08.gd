extends KorridorLevel
## Level 08 – "Torfstich"
##
## Ein aufgelassener Torfstich im Nebel: Wo das Moor abgebaut wurde,
## stehen die Stichgruben voll Wasser, und über ihnen liegt das
## Bandhaus, das den Torf einmal abtransportiert hat. Die Maschinen
## laufen noch – nur weiß niemand mehr, wofür.
##
## Level 07 nebenan ist das reine Moor: schmale Stege über Wasser, sonst
## nichts. Dieses hier setzt den TAKT dagegen. Dieselbe Landschaft, aber
## alles darin bewegt sich: Bänder schieben, Pressen fahren quer, morsche
## Bohlen brechen weg. Wer in 07 gelernt hat, wohin er springt, lernt
## hier, WANN.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  36  Stichkante   – fester Torf, breit; Kisten und ein Käfer
##    36 –  92  Stichgruben  – schmale Bohlen, drei Gruben, Bruchplatten
##    92 – 150  Bandhaus     – Förderbänder, Torfpressen, ein Stachelbalken
##   150 – 189  Förderbrücke – zwei Lücken, überhangelt statt übersprungen
##   189 – 222  Halde        – trockener Abschluss, Extraleben, Zielportal
##
## Die Wasserfläche liegt knapp unter dem Weg, die Absturzzone darunter:
## Zuerst greift das Wasser, die Zone ist nur der Notnagel.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# Strecken-Marken der Abschnitte
const M_KANTE := 0.0
const M_GRUBEN := 36.0
const M_BANDHAUS := 92.0
const M_BRUECKE := 150.0
const M_HALDE := 189.0
const M_ENDE := 222.0

# Höhen relativ zum Weg
const WASSER_HOEHE := -1.2     ## Spiegel der vollgelaufenen Stichgruben
const GRUBENGRUND := -3.4      ## sichtbarer Grund unter dem Wasser
const ABSTURZ := -4.2          ## Notnagel unterhalb des Wassers
const GITTER_HOEHE := 3.2      ## Unterkante der Förderbrücke


const STRECKE := [
	# --- Stichkante: breiter Anlauf auf festem Torf ---
	{"von": 0.0, "bis": 22.0, "breite": 12.0},
	{"von": 26.0, "bis": 36.0, "breite": 11.0, "breite_ende": 8.0},
	# --- Stichgruben: schmale Bohlen zwischen den Gruben ---
	{"von": 36.0, "bis": 52.0, "breite": 6.5},
	{"von": 58.0, "bis": 72.0, "breite": 6.0},
	{"von": 78.0, "bis": 92.0, "breite": 7.0, "breite_ende": 9.0},
	# --- Bandhaus: durchgehender Boden, dafür voller Maschinen ---
	{"von": 92.0, "bis": 150.0, "breite": 9.0},
	# --- Förderbrücke: zwei Lücken, die das Gitter überspannt ---
	{"von": 150.0, "bis": 164.0, "breite": 7.0},
	{"von": 171.0, "bis": 182.0, "breite": 7.0},
	# --- Halde: trocken und breit ---
	{"von": 189.0, "bis": 222.0, "breite": 11.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Stich wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Grubengrund", "tun": _grund_bauen},
		{"text": "Bohlen werden gelegt", "tun": _boden_bauen},
		{"text": "Gruben laufen voll", "tun": _wasser_fluten},
		{"text": "Torfhaufen", "tun": _plattformen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Bänder und Pressen", "tun": _maschinen_bauen},
		{"text": "Morsche Bohlen", "tun": _bruchstellen_bauen},
		{"text": "Förderbrücke", "tun": _bruecke_bauen},
		{"text": "Nebel über dem Stich", "tun": _stimmung_setzen},
		{"text": "Birken und Wollgras", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Weg beschreibt einen weiten Bogen um das Stichfeld herum und
## steigt zum Schluss auf die Halde – den aufgeschütteten Torfberg, von
## dem aus man über das ganze Moor sieht.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),          # Startportal
		Vector3(0, 0, -16),
		Vector3(4, 0, -34),        # Rechtskurve an die Stichkante
		Vector3(14, 0, -50),
		Vector3(28, 0, -62),       # Stichgruben
		Vector3(46, 0, -70),
		Vector3(66, 0, -72),       # Bandhaus, schnurgerade
		Vector3(86, 0, -68),
		Vector3(104, 1, -58),      # Förderbrücke
		Vector3(118, 1, -44),
		Vector3(128, 2, -28),      # Anstieg zur Halde
		Vector3(134, 3, -10),
		Vector3(136, 4, 4),
	])


# =========================================================== Boden

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.bohlen(),       # gelegte Bohlen
		"kante": Materialbibliothek.moorboden(),   # nasse Torfkante
		"klippe": Materialbibliothek.moorboden(),  # Stichwand aus Torf
	}, {"tiefe": 3.2, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.6})
	luecken_markieren(Farben.BOHLE.darkened(0.35))


## Der Grund unter dem Wasser. Reine Kulisse: Wer hier landet, ist schon
## ertrunken – aber ein schwarzes Loch unter dem Steg sähe aus wie ein
## Fehler, nicht wie eine Grube.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(260.0, 260.0)
	var mi := MeshInstance3D.new()
	mi.name = "Grubengrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.moorboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, GRUBENGRUND)
	geometrie.add_child(mi)


## Wasser in Stücken längs des Weges – eine einzige Platte stünde in den
## beiden Kurven weit über den Rand hinaus.
func _wasser_fluten() -> void:
	var schritt := 20.0
	var s := 0.0
	while s < M_ENDE:
		# Auf der Halde steht kein Wasser mehr.
		if s < M_HALDE - 8.0:
			var w := wasser(s + schritt * 0.5, Vector2(44.0, schritt + 2.0),
					WASSER_HOEHE)
			w.tiefe = 2.2
			w.toedlich = true
			w.wellen_hoehe = 0.07
			w.wellen_tempo = 0.45
			# Torfwasser ist braun, nicht grün: Es steht über abgestochenem
			# Torf, nicht über Algen.
			w.farbe_tief = Farben.MOOR_DUNKEL
			w.farbe_hell = Farben.MOOR_HELL
			w.spiegelung = 0.22
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 58.0)


# =========================================================== Plattformen

## Torfhaufen und Trittstümpfe: In den Gruben liegen aufgestapelte
## Torfsoden, auf denen man steht.
func _plattformen_bauen() -> void:
	var torf := Materialbibliothek.moorboden()
	var holz := Materialbibliothek.bohlen()

	# Stichkante: eine Sode in der ersten Lücke, zum Üben
	plattform(24.0, 0.0, -0.3, Vector3(3.6, 0.7, 3.4), torf)

	# Stichgruben: je Grube ein Stapel, versetzt zur Wegmitte
	plattform(55.0, -1.3, -0.15, Vector3(2.4, 0.8, 2.4), torf)
	plattform(75.0, 1.3, -0.15, Vector3(2.4, 0.8, 2.4), torf)

	# Bandhaus: zwei Podeste neben den Bändern, als Ausweichplatz
	plattform(112.0, -3.0, 1.2, Vector3(3.0, 0.7, 4.0), holz)
	plattform(136.0, 3.0, 1.2, Vector3(3.0, 0.7, 4.0), holz)


# =========================================================== Maschinen

## Bandhaus: drei Förderbänder und zwei Torfpressen.
##
## Die Bänder wechseln die Richtung – das erste trägt mit, das zweite
## gegen den Weg. Ein Band, das immer schiebt, wäre ein Geschenk; erst
## das Gegenband macht daraus eine Aufgabe.
func _maschinen_bauen() -> void:
	# Erstes Band: trägt mit. Es soll sich gut anfühlen, bevor es weh tut.
	laufband(98.0, 108.0, 0.0, 0.06, 4.0, 2.6, 1)
	# Zweites Band: gegen die Laufrichtung, dazwischen eine Presse.
	laufband(118.0, 128.0, 0.0, 0.06, 4.0, 2.4, -1)
	# Drittes Band: wieder mit, als Belohnung fürs Durchkommen.
	laufband(138.0, 146.0, 0.0, 0.06, 4.0, 2.8, 1)

	# Torfpressen: fahren quer über den Weg und schieben, sie töten nicht.
	schiebeblock(113.0, 0.0, 0.0, Vector3(1.8, 1.3, 1.8), 3.4, true, 1.5, 0.9)
	schiebeblock(132.0, 0.0, 0.0, Vector3(1.8, 1.3, 1.8), 3.2, true, 1.5, 0.9, 0.5)

	# Ein Stachelbalken über dem zweiten Band: Wer hier durch will, muss
	# krabbeln – und krabbelt gegen das Band an.
	stachelbalken(123.0, 0.0, 1.0, Vector2(4.4, 1.1), 0.5)


## Morsche Bohlen über den Stichgruben. Sie liegen NEBEN der sicheren
## Linie, nicht darauf: Wer sie nimmt, spart Weg und holt Früchte; wer
## sie meidet, kommt trotzdem durch.
func _bruchstellen_bauen() -> void:
	bruchplatten_reihe(53.0, 57.0, 3, 1.4, -0.1, Vector2(2.4, 2.4))
	bruchplatten_reihe(73.0, 77.0, 3, -1.4, -0.1, Vector2(2.4, 2.4))


## Die Förderbrücke: Über den beiden letzten Lücken hängt das alte
## Transportgitter. Sie sind mit 7 m zu weit für einen Sprung – hier wird
## gehangelt, und genau dafür steht das Bauteil.
func _bruecke_bauen() -> void:
	hangelgitter(167.5, 0.0, GITTER_HOEHE, 10.0, 2.2)
	hangelgitter(185.5, 0.0, GITTER_HOEHE, 10.0, 2.2)

	# Die Träger, an denen das Gitter hängt: vier Pfeiler am Grubenrand.
	var eisen := Materialbibliothek.metall(Farben.ROST)
	for s: float in [163.5, 171.5, 181.5, 189.5]:
		for seite: float in [-1.0, 1.0]:
			plattform(s, seite * 3.6, GITTER_HOEHE * 0.5 + 0.4,
					Vector3(0.5, GITTER_HOEHE + 0.8, 0.5), eisen)


# =========================================================== Stimmung

## Über den Gruben steht der Nebel dicht, im Bandhaus lichtet er sich –
## dort ist ein Dach über dem Weg, und wo ein Dach ist, ist kein Nebel.
func _stimmung_setzen() -> void:
	stimmung(M_GRUBEN, M_BANDHAUS, Farben.MOOR_HELL, 0.030, 0.55,
			Color(0.52, 0.56, 0.48))
	stimmung(M_BANDHAUS, M_BRUECKE, Farben.ROST, 0.012, 0.75,
			Color(0.58, 0.52, 0.44))
	stimmung(M_BRUECKE, M_ENDE, Farben.MOOR_HELL, 0.020, 0.85,
			Color(0.60, 0.62, 0.56))

	# Die beiden Ketten liegen dicht an der Nebelfarbe (siehe `horizont.gd`):
	# Ein dunkler Ring vor hellem Dunst liest sich nicht als Ferne, sondern
	# als schwarzer Balken quer durchs Bild.
	horizont(190.0, 16.0, Color(0.52, 0.50, 0.42), Color(0.63, 0.60, 0.52),
			false, -5.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Stichkante: ruhige Einführung ----------
	kiste(Kiste.Art.NORMAL, 6.0, -1.8)
	kiste(Kiste.Art.NORMAL, 6.0, 0.0)
	kiste(Kiste.Art.NORMAL, 6.0, 1.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 12.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 15.0, 2.4)
	kiste(Kiste.Art.CHECKPOINT, 19.0, -2.4)
	kiste(Kiste.Art.EISEN, 30.0, 1.4)
	kiste(Kiste.Art.NORMAL, 30.0, 1.4, 1.6)
	kiste(Kiste.Art.NORMAL, 33.0, -1.4)

	# ---------- Stichgruben: jede Kiste kostet Standfläche ----------
	kiste(Kiste.Art.NORMAL, 40.0, 0.0)
	kiste(Kiste.Art.NORMAL, 44.0, -1.2)
	kiste(Kiste.Art.FEDER, 48.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 60.0, -1.6)
	kiste(Kiste.Art.NORMAL, 63.0, 0.0)
	kiste(Kiste.Art.NORMAL, 67.0, 1.2)
	kiste(Kiste.Art.NITRO, 70.0, -1.4)
	kiste(Kiste.Art.NORMAL, 81.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 85.0, -1.4)
	kiste(Kiste.Art.NORMAL, 89.0, 1.4)

	# ---------- Bandhaus: zwischen den Maschinen ----------
	kiste(Kiste.Art.CHECKPOINT, 95.0, -2.6)
	kiste(Kiste.Art.NORMAL, 96.0, 2.4)
	kiste(Kiste.Art.NORMAL, 110.0, -2.6)
	kiste(Kiste.Art.NORMAL, 110.0, 2.6)
	kiste(Kiste.Art.SCHUTZ, 116.0, 2.8)
	kiste(Kiste.Art.TNT, 130.0, -2.8)
	kiste(Kiste.Art.NORMAL, 134.0, 2.6)
	kiste(Kiste.Art.NORMAL, 136.0, -2.6)
	kiste(Kiste.Art.CHECKPOINT, 148.0, -2.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 148.0, 2.8)

	# ---------- Förderbrücke: nur an den Enden, das Gitter bleibt frei ---
	kiste(Kiste.Art.NORMAL, 154.0, 0.0)
	kiste(Kiste.Art.NORMAL, 158.0, -1.6)
	kiste(Kiste.Art.NORMAL, 161.0, 1.6)
	kiste(Kiste.Art.NORMAL, 174.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 178.0, -1.6)
	kiste(Kiste.Art.NORMAL, 180.0, 1.6)

	# ---------- Halde ----------
	kiste(Kiste.Art.NORMAL, 194.0, -2.0)
	kiste(Kiste.Art.NORMAL, 194.0, 0.0)
	kiste(Kiste.Art.NORMAL, 194.0, 2.0)
	kiste(Kiste.Art.LEBEN, 200.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 206.0, -1.8)
	kiste(Kiste.Art.NORMAL, 210.0, 1.8)


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Stichkante: Draufspringen auf festem Boden ----------
	gegner(PANZERKAEFER, 14.0, 0.0, 3.5, true)
	gegner(SUMPFKROETE, 32.0, -1.0, 2.5, true)

	# ---------- Stichgruben: Drehschlag auf schmalen Bohlen ----------
	gegner(SUMPFKROETE, 46.0, 0.0, 2.0, true)
	gegner(PANZERKAEFER, 65.0, 0.0, 2.0, true)
	gegner(SUMPFKROETE, 86.0, 0.0, 2.5, true)

	# ---------- Bandhaus: auf dem Band steht keiner, nur daneben ----------
	gegner(STELZENSPINNE, 103.0, 2.4, 3.0, true)
	gegner(STELZENSPINNE, 122.0, -2.6, 3.0, true)
	gegner(PANZERKAEFER, 143.0, 1.8, 3.0, true)

	# ---------- Förderbrücke: an beiden Ufern einer ----------
	gegner(STELZENSPINNE, 157.0, 0.0, 2.5, true)
	gegner(SUMPFKROETE, 177.0, 0.0, 2.5, true)

	# ---------- Halde ----------
	gegner(PANZERKAEFER, 198.0, 2.0, 3.0, true)
	gegner(STELZENSPINNE, 212.0, -2.0, 3.0, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 18.0, 7, 0.0)
	fruechte_bogen(22.5, 25.5, 5, 0.0)
	fruechte_reihe(38.0, 50.0, 6, 0.0)
	# Über den morschen Bohlen: Wer sie nimmt, wird bezahlt.
	fruechte_reihe(53.0, 57.0, 4, 1.4)
	fruechte_reihe(60.0, 70.0, 5, 0.0)
	fruechte_reihe(73.0, 77.0, 4, -1.4)
	fruechte_reihe(80.0, 90.0, 5, 0.0)
	fruechte_reihe(98.0, 108.0, 6, 0.0)
	fruechte_reihe(118.0, 128.0, 6, 0.0)
	fruechte_reihe(138.0, 146.0, 5, 0.0)
	# Unter dem Gitter hängend einzusammeln – die Reihe liegt auf Hanghöhe.
	fruechte_reihe(164.5, 170.5, 5, 0.0, GITTER_HOEHE - 1.35)
	fruechte_reihe(182.5, 188.5, 5, 0.0, GITTER_HOEHE - 1.35)
	fruechte_reihe(192.0, 216.0, 9, 0.0)


# =========================================================== Kulisse

## Birken und Totholz am Rand des Stichs. Sie stehen im Wasser oder auf
## dem Torf daneben, nie auf dem Weg – der bleibt frei.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(80801)

	for i in 62:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * randf_range(8.0, 28.0)
		var totholz := i % 3 == 0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if totholz else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(4.5, 9.5)
		baum.staerke = randf_range(0.5, 0.95)
		baum.saat = 4200 + i
		# Birkengrün, ausgeblichen – hier wächst nichts Sattes mehr.
		baum.laubfarbe = Farben.LAUB_GELB.lerp(Farben.MOOR_HELL, randf())
		baum.kollision = false
		var fuss := WASSER_HOEHE - 0.4 if s < M_HALDE else -0.2
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, fuss)
		deko.add_child(baum)

	# Wollgras auf den Torfbänken: helle Büschel am Wasserrand
	for i in 48:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.6, 3.4)),
				WASSER_HOEHE + 0.1 if s < M_HALDE else 0.0)
		horst.flaeche = Vector2(2.8, 2.8)
		horst.halm_hoehe = randf_range(0.5, 0.9)
		horst.farbe_unten = Farben.MOOR.darkened(0.2)
		horst.farbe_oben = Farben.GRAS_TROCKEN
		horst.saat = 5200 + i
		deko.add_child(horst)

	# Abgestochene Torfsoden als Steinhaufen am Wegrand
	for i in 22:
		var s := randf_range(M_GRUBEN, M_ENDE - 6.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var brocken := STEIN.instantiate() as Stein
		brocken.groesse = randf_range(0.5, 1.2)
		brocken.flach = i % 3 == 0
		brocken.bemoost = true
		brocken.kollision = false
		brocken.saat = 6200 + i
		brocken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.4, 2.0)), 0.0)
		deko.add_child(brocken)

	# Pilze und Farne auf dem trockenen Anfang und Ende
	for i in 20:
		var s: float = randf_range(2.0, 34.0) if i % 2 == 0 \
				else randf_range(M_HALDE, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.FARN
		kleinzeug.saat = 7200 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	seed(wuerfel)
