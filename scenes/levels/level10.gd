extends KorridorLevel
## Level 10 – "Hebewerk"
##
## Ein Schiffshebewerk am Hafenbecken. Das Level geht nach OBEN, nicht in
## die Breite: Es beginnt unten am Kai und endet 23 m höher auf dem
## Oberdeck.
##
##     0 –  56  Unterhafen     3D vorwärts · ruhig, weit, zum Ankommen
##    56 –  76  Kistenstiege   3D · über Eisenkisten hinauf
##    76 – 152  Galerie        2D-SEITENANSICHT · eine Richtung, immer höher
##   152 – 172  Schacht        2D · über Hebebühnen die letzten Meter
##   172 – 250  Oberdeck       3D vorwärts · oben angekommen
##
## Die Vorfassung war 430 m lang, hatte elf Abschnitte und jedes Bauteil
## des Projekts darin. Sie war überladen und kaum spielbar – eine
## Ausstellung, kein Level. Die Bauteile zeigen jetzt die Level 11 bis 25
## einzeln; hier geht es allein um den senkrechten Aufbau.
##
## Daraus die Sparsamkeit: je Abschnitt höchstens zwei Arten von Gefahr,
## nie zwei gleichzeitig an derselben Stelle, und zwischen zwei Aufgaben
## immer ein Stück Weg zum Durchatmen.
##
## REGEL FÜR DIE 2D-ABSCHNITTE: Alles liegt bei `seitlich = 0`. In der
## Seitenansicht ist Tiefe nicht zu beurteilen – eine Kiste, die einen
## Meter weiter hinten steht, sieht aus wie eine, die im Weg liegt. Wer
## dort seitlich etwas platziert, baut eine Falle, die niemand sehen kann.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# Strecken-Marken
const M_HAFEN := 0.0
const M_STIEGE := 56.0
const M_GALERIE := 76.0
const M_SCHACHT := 152.0
const M_OBERDECK := 172.0
const M_ENDE := 250.0

# Höhen
## Weltebene des Hafenbeckens. Absolut, nicht relativ zum Verlauf: Der
## steigt um 23 m, das Wasser bleibt unten liegen.
const WASSER_WELT := -1.0
## Tief genug, dass fast überall das Wasser zuerst tötet und die Zone nur
## der Notnagel bleibt. Bei -4 starb man von der Galerie aus schon vier
## Meter unter der Kante – mitten in der Luft, zwölf Meter über dem
## Wasser, das man dabei ansieht.
const ABSTURZ := -20.0


const STRECKE := [
	# --- Unterhafen: weit und ruhig ---
	{"von": 0.0, "bis": 56.0, "breite": 13.0, "breite_ende": 9.0},
	# --- 56 bis 76: Kistenstiege, KEIN Boden – nur die Kisten tragen ---
	# --- Galerie: schmal, die Seitenansicht braucht keine Breite ---
	{"von": 76.0, "bis": 104.0, "breite": 5.5},
	{"von": 112.0, "bis": 132.0, "breite": 5.5},
	{"von": 140.0, "bis": 152.0, "breite": 5.5},
	# --- 152 bis 172: Schacht, nur Hebebühnen ---
	# --- Oberdeck ---
	{"von": 172.0, "bis": 250.0, "breite": 12.0, "breite_ende": 9.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Hebewerk wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Hafenbecken", "tun": _becken_bauen},
		{"text": "Kai und Galerie", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Kistenstiege", "tun": _stiege_bauen},
		{"text": "Galerie", "tun": _galerie_bauen},
		{"text": "Schacht", "tun": _schacht_bauen},
		{"text": "Oberdeck", "tun": _oberdeck_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Kulisse", "tun": _kulisse_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Verlauf steigt in zwei Stufen und bleibt dazwischen flach.
##
## Die Galerie (76–152) läuft absichtlich schnurgerade: In der
## Seitenansicht dreht die Kamera mit dem Weg, und eine Kurve würde das
## Bild schwenken lassen, während der Spieler geradeaus zu laufen glaubt.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 8),
		Vector3(0, 0, -10),
		Vector3(-3, 0, -28),
		Vector3(-8, 0, -45),        # Ende Unterhafen
		Vector3(-13, 3.4, -60),     # Kistenstiege steigt
		Vector3(-18, 7.0, -73),
		# --- ab hier schnurgerade nach -X, nur die Höhe ändert sich ---
		Vector3(-36, 8.6, -76),
		Vector3(-58, 10.4, -76),
		Vector3(-80, 12.2, -76),
		Vector3(-102, 14.0, -76),
		Vector3(-118, 15.0, -76),   # Ende Galerie
		Vector3(-132, 19.0, -76),   # Schacht steigt steil
		Vector3(-140, 23.0, -76),
		# --- Oberdeck, wieder 3D ---
		Vector3(-152, 23.0, -66),
		Vector3(-162, 23.0, -48),
		Vector3(-166, 23.0, -28),
		Vector3(-162, 23.2, -8),
		Vector3(-152, 23.4, 8),
	])


# =========================================================== Grund

## Unten Kai aus Stein, oben das Werk aus Bohlen und Metall. Der Wechsel
## des Belags sagt dem Spieler, dass er eine Ebene weiter ist.
func _boden_bauen() -> void:
	var form := {"tiefe": 3.2, "schritt": 1.0,
			"kante_hoehe": 0.26, "kante_breite": 0.7}
	LevelWerkzeuge.korridor(geometrie, verlauf, [STRECKE[0]], {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.moos(),
		"klippe": Materialbibliothek.fels(),
	}, form)
	LevelWerkzeuge.korridor(geometrie, verlauf,
			[STRECKE[1], STRECKE[2], STRECKE[3], STRECKE[4]], {
		"oben": Materialbibliothek.bohlen(),
		"kante": Materialbibliothek.metall(Farben.ROST),
		"klippe": Materialbibliothek.frostgestein(),
	}, form)
	luecken_markieren(Farben.HOLZ_DUNKEL)


## Das Hafenbecken unter der ganzen Anlage.
##
## Es reicht unter die ganze Anlage, auch unter das Oberdeck, und zwar aus
## einem Grund, der
## nichts mit Wasser zu tun hat: Von der Galerie aus sah man nach unten in
## eine leere, flache Fläche. Ein Turm wird erst hoch, wenn unter ihm etwas
## liegt, das klein aussieht.
##
## `wasser()` setzt die Fläche relativ zum Verlauf – und der steigt hier um
## 23 m. Die Höhe wird deshalb je Stück ausgerechnet, damit das Becken
## waagerecht liegen bleibt statt mit der Galerie mitzuklettern.
func _becken_bauen() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ENDE:
		var mitte := s + schritt * 0.5
		var weltoben := LevelWerkzeuge.punkt(verlauf, mitte, 0.0, 0.0).y
		var w := wasser(mitte, Vector2(56.0, schritt + 2.0),
				WASSER_WELT - weltoben)
		w.tiefe = 2.0
		w.toedlich = true
		w.wellen_hoehe = 0.07
		w.wellen_tempo = 0.5
		w.farbe_tief = Farben.TUEMPEL
		w.farbe_hell = Farben.TUEMPEL_HELL
		w.spiegelung = 0.22
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 70.0)


func _horizont_bauen() -> void:
	horizont(220.0, 30.0, Color(0.34, 0.38, 0.33), Color(0.55, 0.60, 0.56),
			false, -8.0)


# =========================================================== Aufstieg

## 56–76 · Die Kistenstiege. Der erste Höhenwechsel und die Stelle, an der
## das Level seine Idee erklärt.
##
## Eisenkisten, weil sie unzerbrechlich sind: Eine Holzkiste als Treppe
## wäre nach dem ersten Sprung weg, und der Spieler stünde vor einer Lücke,
## die er selbst gerissen hat. Der seitliche Versatz wechselt von Stufe zu
## Stufe, damit die Stiege nicht senkrecht steht – man soll zwischen den
## Stufen kurz zielen müssen.
func _stiege_bauen() -> void:
	var stellen := [58.0, 61.0, 64.0, 67.0, 70.0, 73.0]
	for i in stellen.size():
		var seitlich: float = -1.6 if i % 2 == 0 else 1.6
		# Höhe relativ zum Verlauf: Der steigt hier selbst schon, die Kisten
		# gleichen nur die Differenz zur Sprunghöhe aus.
		kiste(Kiste.Art.EISEN, stellen[i], seitlich, 0.5 + float(i) * 0.12, true)
		frucht(stellen[i], seitlich, 1.6 + float(i) * 0.12)
	# Ein Auffangdeck unter der ganzen Stiege, knapp über dem Wasser.
	#
	# Ohne das kostet jeder verfehlte Sprung ein Leben, und bei sechs
	# Stufen hintereinander ist das der sichere Weg in die Frustration.
	# So kostet ein Fehltritt den Aufstieg, nicht den Anlauf – und genau
	# das war die Klage an der Vorfassung: zu hart, zu voll, zu unfair.
	plattform(66.0, 0.0, -5.4, Vector3(10.0, 0.8, 24.0),
			Materialbibliothek.frostgestein())
	# Die Sprungfeder steht AUF dem Auffangdeck: Wer herunterfällt, landet
	# darauf und kommt ohne Umweg wieder hinauf.
	kiste(Kiste.Art.SPRUNG, 62.0, 0.0, -4.5, true)


## 76–152 · Die Galerie. Seitenansicht, eine Richtung, stetig höher.
##
## Wenig, und das Wenige weit auseinander: zwei Bruchplatten-Lücken, ein
## Feuerspeier, eine Taktwelle. Zwischen zwei Aufgaben liegen gut zehn
## Meter freier Weg – in der Seitenansicht wirkt alles dichter, als es ist,
## weil das Bild flach wird.
func _galerie_bauen() -> void:
	bruchplatten_reihe(105.0, 111.0, 3, 0.0, -0.1)
	bruchplatten_reihe(133.0, 139.0, 3, 0.0, -0.1)

	# Ein einzelner Feuerspeier auf der Geraden dazwischen. Quer zum Weg,
	# damit er in der Seitenansicht in voller Länge zu sehen ist.
	feuerspeier(120.0, -3.0, 1.0, 0.0, 3.2, 0.0)

	# Eine kurze Taktwelle kurz vor dem Schacht.
	taktwelle(143.0, 150.0, 3, 0.0, Vector2(2.4, 2.4), 0.3)


## 152–172 · Der Schacht. Zwei Hebebühnen tragen die letzten Meter.
##
## Sie fahren versetzt: Wer auf der ersten oben ankommt, muss kurz auf die
## zweite warten. Das ist die einzige Stelle im Level, an der Warten
## verlangt wird, und sie ist deshalb kurz.
func _schacht_bauen() -> void:
	wehrbohle(157.0, 0.0, 2.6, -0.4, 0.0, Vector2(3.6, 3.2), 2.4, 2.4)
	# Ein fester Absatz dazwischen zum Durchatmen.
	plattform(163.0, 0.0, 2.2, Vector3(4.0, 0.6, 3.4),
			Materialbibliothek.frostgestein())
	wehrbohle(168.0, 0.0, 2.4, -0.6, 0.5, Vector2(3.6, 3.2), 2.4, 2.4)


## 172–250 · Das Oberdeck. Wieder 3D, wieder Platz.
##
## Oben angekommen soll man erst einmal sehen dürfen, wie hoch man ist –
## deshalb passiert auf den ersten dreißig Metern nichts. Danach ein
## Hangelgitter als Höhepunkt, mit zwei schmalen Stegen daneben für alle,
## die lieber laufen.
func _oberdeck_bauen() -> void:
	hangelgitter(214.0, 0.0, 3.2, 12.0, 2.2)
	plattform(214.0, -4.6, 0.1, Vector3(2.0, 0.5, 12.0),
			Materialbibliothek.bohlen())
	plattform(214.0, 4.6, 0.1, Vector3(2.0, 0.5, 12.0),
			Materialbibliothek.bohlen())


## Galerie und Schacht am Stück in der Seitenansicht – der Wechsel soll
## nicht mitten im Aufstieg passieren.
func _kamerazonen_setzen() -> void:
	kamerazone(78.0, 172.0, -17.0, 3.4)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Unterhafen: wenig, breit gestreut ----------
	kiste(Kiste.Art.NORMAL, 8.0, -2.0)
	kiste(Kiste.Art.NORMAL, 8.0, 2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 16.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 24.0, -2.6)
	kiste(Kiste.Art.NORMAL, 34.0, 2.4)
	kiste(Kiste.Art.SCHUTZ, 44.0, -2.0)
	kiste(Kiste.Art.NORMAL, 50.0, 0.0)

	# ---------- Galerie: alles bei seitlich 0, siehe Kopfkommentar ------
	kiste(Kiste.Art.CHECKPOINT, 80.0, 0.0)
	kiste(Kiste.Art.NORMAL, 88.0, 0.0)
	kiste(Kiste.Art.NORMAL, 96.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 102.0, 0.0)
	kiste(Kiste.Art.NORMAL, 116.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 124.0, 0.0)
	kiste(Kiste.Art.NORMAL, 130.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 141.0, 0.0)

	# ---------- Oberdeck ----------
	kiste(Kiste.Art.CHECKPOINT, 176.0, -2.4)
	kiste(Kiste.Art.NORMAL, 186.0, -2.0)
	kiste(Kiste.Art.NORMAL, 186.0, 0.0)
	kiste(Kiste.Art.NORMAL, 186.0, 2.0)
	kiste(Kiste.Art.EISEN, 196.0, -2.6)
	kiste(Kiste.Art.NORMAL, 196.0, -2.6, 1.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 204.0, 2.2)
	kiste(Kiste.Art.NORMAL, 226.0, -2.2)
	kiste(Kiste.Art.NORMAL, 226.0, 2.2)
	kiste(Kiste.Art.LEBEN, 236.0, 0.0)
	kiste(Kiste.Art.NORMAL, 243.0, -1.8)


# =========================================================== Gegner

## Sieben Gegner im ganzen Level, und keiner steht dort, wo gerade
## gesprungen werden muss.
##
## Die Vorfassung hatte vierundzwanzig. Auf einem schmalen Steg ist ein
## Gegner keine Aufgabe mehr, sondern eine Wand – erst recht, wenn
## gleichzeitig eine Platte wegbricht.
func _gegner_setzen() -> void:
	# ---------- Unterhafen: hier ist Platz zum Üben ----------
	gegner(PANZERKAEFER, 14.0, -1.5, 4.0, true)
	gegner(SUMPFKROETE, 30.0, 1.5, 3.0, true)
	gegner(PANZERKAEFER, 46.0, 0.0, 3.5, true)

	# ---------- Galerie: nur auf festen Stücken, nie an einer Lücke -----
	gegner(SUMPFKROETE, 92.0, 0.0, 2.4, true)
	gegner(PANZERKAEFER, 128.0, 0.0, 2.4, true)

	# ---------- Oberdeck ----------
	gegner(STELZENSPINNE, 190.0, 2.0, 3.0, true)
	gegner(SUMPFKROETE, 232.0, -2.0, 3.0, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 52.0, 14, 0.0)
	fruechte_bogen(56.0, 75.0, 8, 0.0, 1.6)
	fruechte_reihe(78.0, 104.0, 9, 0.0)
	fruechte_bogen(104.0, 112.0, 5, 0.0, 2.0)
	fruechte_reihe(113.0, 132.0, 7, 0.0)
	fruechte_bogen(132.0, 140.0, 5, 0.0, 2.0)
	fruechte_reihe(141.0, 151.0, 4, 0.0)
	fruechte_bogen(153.0, 171.0, 7, 0.0, 2.2)
	fruechte_reihe(174.0, 246.0, 20, 0.0)


# =========================================================== Kulisse

## Unten Hafenbewuchs, oben nichts als Himmel.
##
## Auf dem Oberdeck steht mit Absicht kein einziger Baum: 23 m über dem
## Becken soll nichts die Sicht nach unten verstellen. Die Höhe IST die
## Kulisse.
func _kulisse_bauen() -> void:
	var wuerfel := randi()
	seed(31010)
	for i in 54:
		var s := randf_range(-8.0, M_ENDE)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 4 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(5.0, 12.0)
		baum.staerke = randf_range(0.6, 1.1)
		baum.saat = 8100 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.ALGE, randf())
		baum.kollision = false
		# Auch die Bäume stehen im Becken, nicht auf Weghöhe – sonst
		# schwebten sie neben der Galerie in der Luft.
		var weltoben := LevelWerkzeuge.punkt(verlauf, s, 0.0, 0.0).y
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(9.0, 26.0),
				WASSER_WELT - 0.4 - weltoben)
		deko.add_child(baum)

	for i in 22:
		var s := randf_range(2.0, 52.0)
		var rand := rand_bei(s, 1.4)
		if rand < 1.8:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate()
		if "saat" in stein:
			stein.set("saat", 8300 + i)
		if "hoehe" in stein:
			stein.set("hoehe", randf_range(0.6, 1.8))
		stein.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)

	for i in 26:
		var s := randf_range(2.0, 54.0)
		var rand := rand_bei(s, 0.5)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand, rand + 3.0), 0.0)
		horst.flaeche = Vector2(2.6, 2.6)
		horst.halm_hoehe = randf_range(0.5, 1.0)
		horst.farbe_unten = Farben.GRAS_DUNKEL
		horst.farbe_oben = Farben.GRAS
		horst.saat = 8500 + i
		deko.add_child(horst)

	for i in 16:
		var s := randf_range(4.0, 50.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.FARN
		kleinzeug.saat = 8700 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)
