extends KorridorLevel
## Level 02 – "Frostschlucht"
##
## Umgebaut von einem offenen Grat zu einer engen Schlucht. Der Grund:
## Ein Weg im Nebel ohne Wände ist ein heller Streifen im Nichts – man
## sieht weder, wohin es geht, noch wo man ist. Jetzt stehen links und
## rechts Eiswände, die mit dem Weg mitlaufen, sich an den engen Stellen
## zusammenschieben und am Gipfel aufreißen.
##
## Farbe ist dabei kein Schmuck, sondern Lesbarkeit: Ein Schneelevel
## läuft sonst zu einer weißen Fläche zusammen. Deshalb tiefblaues
## Gletschereis als Wand, leuchtende Kristalle als Wegmarken und
## Feuerschalen als warme Gegenfarbe – an ihnen erkennt man auf einen
## Blick, wo der Weg weitergeht.
##
## Der Weg ist kein Plateau mehr: Die Eiswände stehen unmittelbar an der
## Wegkante und tragen Kollision. Seitlich hinunterfallen geht damit gar
## nicht – gefallen wird nur noch durch die Gletscherspalten im Boden, und
## die spannen sich über die ganze Schluchtbreite, sind also echte Sprünge.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  60  Gletschertor  – Einführung, Torbögen, erste Kisten
##    60 –  96  Eisrinne      – blankes Eis, hier wird geschlittert
##    96 – 154  Spalte        – 2D-Abschnitt, Kamera steht seitlich
##   154 – 206  Kristallgrotte– leuchtende Kristalle, dichte Gegnerfolge
##   206 – 236  Gipfel        – die Schlucht reißt auf, Zielportal

## Eigene Gegner für das Setting. Die Waldgegner aus Level 01 kommen hier
## nicht vor: Eine Sumpfkröte im Gletscher ist keine Gegnerwahl, sondern
## eine fehlende. Die drei decken dieselben drei Rollen ab –
## Drehschlag, Draufspringen, Slide –, sehen aber aus wie hier zu Hause.
const FROSTMOTTE := preload("res://scenes/enemies/Frostmotte.tscn")
const GLETSCHERKRABBE := preload("res://scenes/enemies/Gletscherkrabbe.tscn")
const SCHNEEWIESEL := preload("res://scenes/enemies/Schneewiesel.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const EISFLAECHE := preload("res://scenes/hazards/Eisflaeche.tscn")

const M_TOR := 0.0
const M_RINNE := 60.0
const M_SPALTE := 96.0
const M_GROTTE := 154.0
const M_GIPFEL := 206.0
const M_ENDE := 236.0

const SCHLUCHTGRUND := -22.0   ## Grund der Schlucht, tief unter dem Weg
const ABSTURZ := -6.0


## Der Schluchtboden. Die Breite entspricht dem Abstand der Wände – der
## Boden reicht also bis an sie heran, es gibt keinen Rand zum Herunterfallen.
## Die Lücken sind Gletscherspalten über die ganze Breite.
const STRECKE := [
	# --- Gletschertor: weiteste Stelle, eine Übungsspalte ---
	{"von": 0.0, "bis": 34.0, "breite": 13.0},
	{"von": 38.0, "bis": 60.0, "breite": 13.0},
	# --- Eisrinne: enger, auf Eis wird jede Spalte zur Aufgabe ---
	{"von": 60.0, "bis": 78.0, "breite": 11.0},
	{"von": 83.0, "bis": 96.0, "breite": 11.0},
	# --- Spalte: engste Stelle, im 2D-Bild gut zu treffen ---
	{"von": 100.0, "bis": 116.0, "breite": 9.0},
	{"von": 121.0, "bis": 136.0, "breite": 9.0},
	{"von": 141.0, "bis": 154.0, "breite": 9.0},
	# --- Kristallgrotte ---
	{"von": 154.0, "bis": 186.0, "breite": 12.0},
	{"von": 191.0, "bis": 206.0, "breite": 12.0},
	# --- Gipfel: die Schlucht reißt auf ---
	{"von": 206.0, "bis": 236.0, "breite": 16.0},
]

## Die Schluchtwände: Abstand von der Wegmitte und Höhe je Abschnitt.
## Die Enge ist das Gestaltungsmittel – im 2D-Teil stehen sie am
## dichtesten, am Gipfel weichen sie ganz zurück.
## Die Wände stehen jeweils eine halbe Bahnbreite von der Mitte entfernt,
## also unmittelbar an der Kante des Schluchtbodens. Die Höhen sind
## erprobt: 17 bis 24 m ergaben eine blaue Röhre ohne Himmel, 9 m
## verschwanden hinter dem Baumbestand. Diese Werte stehen über den
## Bäumen und lassen oben einen Streifen Himmel offen.
## Die Höhen sind dreimal danebengegangen: 17 bis 24 m ergaben eine blaue
## Röhre ohne Himmel, 9 m verschwanden hinter dem Baumbestand, und 13 bis
## 18 m mit starker Ausstellung schlossen sich über dem Spieler zu einem
## Flickenteppich aus Wandflächen. Diese Werte stehen fast senkrecht und
## bleiben unter der Kameralinie: Die Wand führt den Blick nach vorn,
## statt ihn zuzudecken.
const WAENDE := [
	{"von": -8.0, "bis": 60.0, "abstand": 6.5, "hoehe": 9.0},
	{"von": 60.0, "bis": 96.0, "abstand": 5.5, "hoehe": 10.0},
	{"von": 96.0, "bis": 154.0, "abstand": 4.5, "hoehe": 10.5},
	{"von": 154.0, "bis": 206.0, "abstand": 6.0, "hoehe": 8.5},
	{"von": 206.0, "bis": 244.0, "abstand": 8.0, "hoehe": 5.5},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Schlucht wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Eiswände türmen sich", "tun": _waende_bauen},
		{"text": "Schnee legt sich", "tun": _boden_bauen},
		{"text": "Schluchtgrund", "tun": _grund_bauen},
		{"text": "Blankes Eis", "tun": _eisflaechen_setzen},
		{"text": "Vorsprünge und Platten", "tun": _plattformen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Eiszapfen an den Wänden", "tun": _zapfen_bauen},
		{"text": "Kristalle leuchten auf", "tun": _kristalle_bauen},
		{"text": "Feuerschalen werden entzündet", "tun": _feuer_bauen},
		{"text": "Torbögen", "tun": _boegen_bauen},
		{"text": "Frostwald auf den Simsen", "tun": _wald_bauen},
		{"text": "Schneewehen", "tun": _wehen_bauen},
		{"text": "Kamera für die Spalte", "tun": _kamerazonen},
		{"text": "Portale", "tun": _portale},
		{"text": "Eiszapfenfelder", "tun": _gefahren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Weg durch die Schlucht: zwei Kurven und ein Anstieg von 14 m.
## Die Kurven sind bewusst da, wo die Wände eng stehen – dann sieht man
## erst im letzten Moment, was kommt.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),
		Vector3(0, 0, -20),
		Vector3(4, 1, -40),
		Vector3(16, 2, -56),
		Vector3(34, 3, -66),
		Vector3(53, 4, -70),
		Vector3(70, 5, -80),
		Vector3(80, 7, -98),
		Vector3(82, 9, -120),
		Vector3(74, 11, -140),
		Vector3(60, 13, -154),
		Vector3(42, 14, -162),
		Vector3(22, 14, -166),
	])


# =========================================================== Wände

## Die beiden Schluchtwände. Sie tragen keine Kollision: Sie stehen
## außerhalb des begehbaren Wegs, wer sie erreicht, fällt ohnehin.
func _waende_bauen() -> void:
	# Drei Schichten statt einer: warmer Fels als Grundton, Eisbänder in
	# Wellen darüber, Schnee auf der obersten Lage. Eine Wand ganz aus Eis
	# machte das Bild einfarbig blau – dann trägt nichts mehr Farbe und die
	# Kisten verlieren ihren Vorrang.
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			Materialbibliothek.frostgestein(), {
		"schritt": 2.4, "lagen": 4, "block": 3.0,
		"sockel": 12.0, "saat": 2802,
		"adermaterial": Materialbibliothek.eisfels(),
		"deckmaterial": Materialbibliothek.firn(),
		"aderdichte": 0.25,
	})
	# Die Sichtwand ist ein Dreiecksnetz und taugt nicht als Begrenzung –
	# an ihren Zacken bliebe man hängen. Dahinter läuft eine glatte
	# Leitwand aus Kästen, die den Spieler auf dem Schluchtboden hält.
	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), w["abstand"] - 0.4, 5.0)
	# Schneebank: steigt vom Boden zur Wand an und schließt die Fuge.
	var baenke: Array = []
	for w in WAENDE:
		baenke.append({
			"von": maxf(w["von"], -4.0), "bis": w["bis"],
			"innen": w["abstand"] - 2.2, "aussen": w["abstand"] + 0.6,
			"hoehe": -0.05,
		})
	LevelWerkzeuge.sims(geometrie, verlauf, baenke, Materialbibliothek.schnee())


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.schnee(),
		"kante": Materialbibliothek.firn(),
		"klippe": Materialbibliothek.frostfels(),
	}, {"tiefe": 16.0, "schritt": 1.2, "kante_hoehe": 0.28, "kante_breite": 0.6})
	luecken_markieren(Farben.EIS_DUNKEL)


## Der Grund der Schlucht, tief unten. Nicht erreichbar – wer fällt,
## stirbt vorher in der Absturzzone – aber er macht die Tiefe sichtbar.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(240.0, 300.0)
	var mi := MeshInstance3D.new()
	mi.name = "Schluchtgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.eis()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, SCHLUCHTGRUND)
	geometrie.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 60.0)


# =========================================================== Eis

## Drei Schlitterstrecken. Auf Eis nimmt die Figur Tempo nur träge auf und
## baut es genauso träge ab – wer zu spät bremst, rutscht über die Kante.
## Deshalb liegt vor jeder Lücke ein Stück blanker Boden zum Abfangen.
func _eisflaechen_setzen() -> void:
	# Fünf Strecken auf 236 m, zusammen rund 70 m – etwa ein Drittel. Das
	# ist Absicht: Wenn alles schlittert, ist Schlittern kein Ereignis mehr,
	# sondern nur noch eine schlechtere Steuerung.
	for eintrag in [
		{"von": 62.0, "bis": 76.0, "quer": 0.0, "breite": 10.0, "glaette": 0.85},
		{"von": 84.0, "bis": 94.0, "quer": 0.0, "breite": 10.0, "glaette": 0.85},
		{"von": 103.0, "bis": 115.0, "quer": 0.0, "breite": 8.0, "glaette": 0.75},
		{"von": 142.0, "bis": 152.0, "quer": 0.0, "breite": 8.0, "glaette": 0.75},
		{"von": 156.0, "bis": 172.0, "quer": 0.0, "breite": 11.0, "glaette": 0.7},
	]:
		var laenge: float = eintrag["bis"] - eintrag["von"]
		# In Stücken, damit die Platte den Kurven folgt.
		var stueck := 4.0
		var s: float = eintrag["von"]
		while s < eintrag["bis"]:
			var l := minf(stueck, eintrag["bis"] - s)
			var eis := EISFLAECHE.instantiate() as Eisflaeche
			eis.flaeche = Vector2(eintrag["breite"], l)
			eis.glaette = eintrag["glaette"]
			eis.position = LevelWerkzeuge.punkt(verlauf, s + l * 0.5,
					eintrag["quer"], 0.02)
			eis.rotation.y = LevelWerkzeuge.drehung(verlauf, s + l * 0.5)
			objekte.add_child(eis)
			s += l


# =========================================================== Plattformen

func _plattformen_bauen() -> void:
	var eis := Materialbibliothek.eis()
	var fels := Materialbibliothek.frostfels()

	plattform(36.0, 0.0, -0.4, Vector3(3.4, 0.7, 3.4), fels)
	plattform(80.5, -1.4, 0.4, Vector3(3.0, 0.6, 3.6), eis)
	# Spalte: Trittsimse in den Lücken, im 2D-Bild als Stufen lesbar
	plattform(118.5, 0.0, 0.8, Vector3(2.6, 0.6, 3.2), fels)
	plattform(138.5, 0.0, 1.6, Vector3(2.6, 0.6, 3.2), fels)
	# Grotte: erhöhter Umweg über zwei Felsstufen
	plattform(176.0, -3.2, 1.6, Vector3(3.6, 0.7, 4.4), fels)
	plattform(183.0, -3.2, 2.8, Vector3(3.6, 0.7, 3.8), fels)
	plattform(188.5, 0.0, 1.2, Vector3(3.2, 0.6, 3.4), eis)


# =========================================================== Kulisse

## Eiszapfen hängen von den Wandkanten herab. Sie sind reine Optik, geben
## der Schlucht aber erst ihre Decke – ohne sie enden die Wände oben im
## Nichts.
func _zapfen_bauen() -> void:
	var eis := Materialbibliothek.eis()
	var wuerfel := randi()
	seed(20811)
	for i in 150:
		var s := randf_range(-4.0, M_ENDE + 4.0)
		var wand := _wand_bei(s)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var laenge := randf_range(0.8, 2.6)
		var zapfen := MeshInstance3D.new()
		var kegel := CylinderMesh.new()
		kegel.top_radius = randf_range(0.10, 0.24)
		kegel.bottom_radius = 0.02
		kegel.height = laenge
		kegel.radial_segments = 6
		zapfen.mesh = kegel
		zapfen.material_override = eis
		zapfen.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (wand["abstand"] - randf_range(0.2, 2.2)),
				randf_range(wand["hoehe"] * 0.45, wand["hoehe"] * 0.9))
		deko.add_child(zapfen)
	seed(wuerfel)


## Leuchtende Kristalle: die Wegmarken des Levels. Sie stehen dort, wo es
## weitergeht, und geben dem Weiß der Schneedecke einen Gegenpol.
func _kristalle_bauen() -> void:
	var wuerfel := randi()
	seed(20812)
	for i in 70:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 0.4)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var blau := i % 3 != 0
		var farbe := Farben.KRISTALL_BLAU if blau else Farben.KRISTALL_VIOLETT
		var stoff := Materialbibliothek.kristall(farbe)

		var horst := Node3D.new()
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand + randf_range(0.0, 1.6)), -0.1)
		horst.rotation.y = randf() * TAU
		deko.add_child(horst)
		for k in randi_range(2, 4):
			var zacken := MeshInstance3D.new()
			var kegel := CylinderMesh.new()
			kegel.top_radius = 0.02
			kegel.bottom_radius = randf_range(0.12, 0.26)
			kegel.height = randf_range(0.7, 2.1)
			kegel.radial_segments = 6
			zacken.mesh = kegel
			zacken.material_override = stoff
			zacken.position = Vector3(randf_range(-0.4, 0.4), kegel.height * 0.45,
					randf_range(-0.4, 0.4))
			zacken.rotation = Vector3(randf_range(-0.25, 0.25), randf() * TAU,
					randf_range(-0.25, 0.25))
			horst.add_child(zacken)

		# Nur jeder dritte Horst bekommt Licht – sonst wird es teuer und
		# das Bild flau.
		if i % 3 == 0:
			var licht := OmniLight3D.new()
			licht.light_color = farbe
			licht.light_energy = 1.6
			licht.omni_range = 7.0
			licht.position.y = 1.2
			licht.shadow_enabled = false
			horst.add_child(licht)
	seed(wuerfel)


## Feuerschalen auf Pfosten – die einzige warme Farbe im Level und damit
## das, woran das Auge den Weg entlangläuft.
func _feuer_bauen() -> void:
	var holz := Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	var schale := Materialbibliothek.einfarbig(Farben.FELS_DUNKEL, 0.6, 0.3)
	var glut := Materialbibliothek.leuchtend(Farben.GLUT, 2.6)
	for s: float in [8.0, 30.0, 52.0, 90.0, 128.0, 150.0, 168.0, 200.0, 226.0]:
		var rand := rand_bei(s, 0.7)
		if rand < 1.0:
			continue
		for seite: float in [-1.0, 1.0]:
			var gruppe := Node3D.new()
			gruppe.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
			deko.add_child(gruppe)

			var pfosten := MeshInstance3D.new()
			var saeule := CylinderMesh.new()
			saeule.top_radius = 0.13
			saeule.bottom_radius = 0.2
			saeule.height = 1.5
			saeule.radial_segments = 8
			pfosten.mesh = saeule
			pfosten.material_override = holz
			pfosten.position.y = 0.75
			gruppe.add_child(pfosten)

			var korb := MeshInstance3D.new()
			var kelch := CylinderMesh.new()
			kelch.top_radius = 0.42
			kelch.bottom_radius = 0.24
			kelch.height = 0.34
			kelch.radial_segments = 10
			korb.mesh = kelch
			korb.material_override = schale
			korb.position.y = 1.6
			gruppe.add_child(korb)

			var flamme := MeshInstance3D.new()
			var zunge := SphereMesh.new()
			zunge.radius = 0.3
			zunge.height = 0.9
			zunge.radial_segments = 8
			zunge.rings = 5
			flamme.mesh = zunge
			flamme.material_override = glut
			flamme.position.y = 2.0
			gruppe.add_child(flamme)

			# Klein halten: mit 3,2 auf 12 m überzog jede Schale den halben
			# Weg mit einem lachsfarbenen Schleier – aus weißem Schnee
			# wurde rosa Schnee. Als Wegmarke reicht ein enger Schein.
			var licht := OmniLight3D.new()
			licht.light_color = Farben.GLUT
			licht.light_energy = 2.0
			licht.omni_range = 7.5
			licht.shadow_enabled = false
			licht.position.y = 2.0
			gruppe.add_child(licht)


## Eisbögen spannen sich über den Weg. Sie geben der Schlucht einen Takt
## und verdecken beim Durchlaufen kurz die Sicht – dadurch wirkt die
## Strecke länger, als sie ist. Der erste Entwurf setzte für Breite und
## Höhe verschiedene Radien und lief nur bis ±66°; daraus wurden
## freischwebende Blöcke statt eines Bogens. Jetzt baut sie
## `LevelWerkzeuge.torbogen()` als echten Halbkreis von Boden zu Boden.
func _boegen_bauen() -> void:
	var eis := Materialbibliothek.eisfels()
	for s: float in [22.0, 66.0, 104.0, 132.0, 162.0, 196.0]:
		LevelWerkzeuge.torbogen(deko, verlauf, s, maxf(breite_bei(s), 6.0) * 1.05,
				eis, 13, 0.0)


## Verschneite Nadelbäume dicht an den Wänden.
##
## Sie standen zuerst auf "Simsen", die es nicht gab. Danach hingen sie am
## Wandabstand – aber `WAENDE` hält den Abstand je Abschnitt fest, während
## die Wegbreite innerhalb eines Abschnitts wandert. Wo der Weg schmaler
## war als die Wand, standen die Bäume wieder in der Luft. Jetzt richtet
## sich der Platz nach dem Weg selbst (`rand_bei`), und wo es keinen Weg
## gibt, wächst auch kein Baum.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(20802)
	for i in 96:
		var s := randf_range(0.5, M_ENDE - 0.5)
		var rand := rand_bei(s, 0.4)
		if rand < 2.2:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var quer := seite * randf_range(rand - 1.5, rand - 0.2)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM
		baum.hoehe = randf_range(3.5, 7.5)
		baum.staerke = randf_range(0.6, 1.05)
		baum.saat = 3000 + i
		baum.laubfarbe = Farben.NADEL_FROST.lerp(Farben.SCHNEE, randf_range(0.1, 0.5))
		baum.kollision = false
		baum.wind = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, 0.0)
		deko.add_child(baum)
	seed(wuerfel)


## Schneewehen am Wegrand und Findlinge auf den Simsen.
func _wehen_bauen() -> void:
	var schnee := Materialbibliothek.schnee()
	var wuerfel := randi()
	seed(20803)
	for i in 110:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 0.5)
		if rand < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var wehe := MeshInstance3D.new()
		var kugel := SphereMesh.new()
		kugel.radius = randf_range(0.4, 1.2)
		kugel.height = kugel.radius * 2.0
		kugel.radial_segments = 10
		kugel.rings = 6
		wehe.mesh = kugel
		wehe.material_override = schnee
		wehe.scale = Vector3(randf_range(1.2, 2.4), randf_range(0.25, 0.5),
				randf_range(1.0, 1.9))
		wehe.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (rand - randf_range(0.0, 0.5)), -kugel.radius * 0.3)
		wehe.rotation.y = randf() * TAU
		deko.add_child(wehe)

	for i in 40:
		var s := randf_range(0.0, M_ENDE)
		var wand := _wand_bei(s)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate() as Stein
		stein.groesse = randf_range(1.0, 3.0)
		stein.bemoost = false
		stein.kollision = false
		stein.saat = 7000 + i
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(wand["abstand"] - 2.4, wand["abstand"] - 1.1),
				0.0)
		deko.add_child(stein)
	seed(wuerfel)


## Wandwerte an einer Stelle – Zapfen, Bäume und Steine richten sich danach.
func _wand_bei(strecke: float) -> Dictionary:
	for w in WAENDE:
		if strecke >= w["von"] and strecke <= w["bis"]:
			return w
	return WAENDE[0]


# =========================================================== Kamera

## Die Spalte wird zum 2D-Abschnitt: Die Kamera stellt sich quer daneben.
## Dass die Steuerung dann noch stimmt, kommt von selbst – sie ist
## kamerarelativ, was auf dem Schirm nach rechts geht, geht auch am Stick
## nach rechts.
func _kamerazonen() -> void:
	kamerazone(M_SPALTE + 2.0, M_GROTTE - 2.0, -15.0, 3.2)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Gefahren

## Keine Stachelfelder. Dornen aus dem Boden sind ein Wald- und
## Kerkermotiv; im Gletscher wirkten sie wie hineinkopiert – rostbraun
## sahen sie sogar aus wie Lava. Die Aufgabe dieses Levels ist das Eis,
## und die steckt in den Schlitterstrecken.
##
## Was hier bleibt, sind die Gletscherspalten im Boden: Sie spannen sich
## über die ganze Schluchtbreite und sind der einzige Weg nach unten.
func _gefahren_setzen() -> void:
	pass


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Gletschertor ----------
	kiste(Kiste.Art.NORMAL, 8.0, -1.6)
	kiste(Kiste.Art.NORMAL, 8.0, 0.0)
	kiste(Kiste.Art.NORMAL, 8.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 14.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 20.0, 2.2)
	kiste(Kiste.Art.CHECKPOINT, 24.0, -2.4)
	kiste(Kiste.Art.EISEN, 28.0, 1.8)
	kiste(Kiste.Art.NORMAL, 28.0, 1.8, 1.6)
	kiste(Kiste.Art.NORMAL, 44.0, -1.4)
	kiste(Kiste.Art.NORMAL, 50.0, 1.4)

	# ---------- Eisrinne: wenige Kisten, das Eis ist die Aufgabe ----------
	kiste(Kiste.Art.NORMAL, 64.0, -1.6)
	kiste(Kiste.Art.NORMAL, 70.0, 1.6)
	kiste(Kiste.Art.FEDER, 74.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 88.0, -2.0)
	kiste(Kiste.Art.NORMAL, 92.0, 0.0)

	# ---------- Spalte: alles auf einer Linie, 2D-tauglich ----------
	kiste(Kiste.Art.NORMAL, 104.0, 0.0)
	kiste(Kiste.Art.NORMAL, 108.0, 0.0)
	kiste(Kiste.Art.SPRUNG, 113.0, 0.0)
	kiste(Kiste.Art.NORMAL, 124.0, 0.0)
	kiste(Kiste.Art.NITRO, 128.0, 1.4)
	kiste(Kiste.Art.NORMAL, 133.0, 0.0)
	kiste(Kiste.Art.NORMAL, 144.0, 0.0)
	kiste(Kiste.Art.NORMAL, 148.0, -1.2)

	# ---------- Kristallgrotte ----------
	kiste(Kiste.Art.SCHUTZ, 152.0, 2.0)
	kiste(Kiste.Art.CHECKPOINT, 156.0, -3.0)
	kiste(Kiste.Art.TNT, 164.0, -1.0)
	kiste(Kiste.Art.NORMAL, 164.0, 0.8)
	kiste(Kiste.Art.NORMAL, 170.0, -0.8)
	kiste(Kiste.Art.TNT, 178.0, 0.4)
	kiste(Kiste.Art.NORMAL, 184.0, -2.2)
	kiste(Kiste.Art.NORMAL, 196.0, 1.8)
	kiste(Kiste.Art.NORMAL, 200.0, -1.8)

	# ---------- Gipfel ----------
	kiste(Kiste.Art.NORMAL, 212.0, -2.0)
	kiste(Kiste.Art.NORMAL, 212.0, 0.0)
	kiste(Kiste.Art.NORMAL, 212.0, 2.0)
	kiste(Kiste.Art.LEBEN, 218.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 224.0, -1.8)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 224.0, 1.8)


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Gletschertor: Draufspringen lernen ----------
	gegner(GLETSCHERKRABBE, 18.0, 0.0, 3.5, true)
	gegner(GLETSCHERKRABBE, 48.0, 1.5, 3.0, true)

	# ---------- Eisrinne: auf blankem Eis ist jeder Gegner schwerer ----------
	gegner(FROSTMOTTE, 68.0, 0.0, 3.0, true)
	gegner(GLETSCHERKRABBE, 90.0, 0.0, 2.5, true)

	# ---------- Spalte: im 2D-Bild kommt alles frontal ----------
	gegner(FROSTMOTTE, 110.0, 0.0, 2.5, true)
	gegner(GLETSCHERKRABBE, 130.0, 0.0, 2.0, true)
	gegner(FROSTMOTTE, 146.0, 0.0, 2.5, true)

	# ---------- Kristallgrotte: hier lernt man den Slide ----------
	gegner(SCHNEEWIESEL, 166.0, -1.6, 4.0, true)
	gegner(SCHNEEWIESEL, 176.0, 0.5, 4.5, true)
	gegner(FROSTMOTTE, 186.0, 0.0, 3.0, true)
	gegner(SCHNEEWIESEL, 196.0, -0.5, 4.0, true)

	# ---------- Gipfel ----------
	gegner(GLETSCHERKRABBE, 216.0, 2.0, 3.5, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 22.0, 9, 0.0)
	fruechte_reihe(26.0, 32.0, 4, -2.2)
	fruechte_bogen(33.0, 39.0, 5, 0.0)
	fruechte_reihe(42.0, 58.0, 8, 1.6)
	fruechte_reihe(62.0, 76.0, 7, 0.0)
	fruechte_bogen(78.5, 82.5, 5, -1.2)
	fruechte_reihe(85.0, 94.0, 5, 0.0)
	fruechte_reihe(102.0, 114.0, 6, 0.0)
	fruechte_bogen(116.5, 120.5, 5, 0.0, 3.0)
	fruechte_reihe(123.0, 134.0, 6, 0.0)
	fruechte_bogen(136.5, 140.5, 5, 0.0, 3.0)
	fruechte_reihe(143.0, 152.0, 5, 0.0)
	fruechte_reihe(158.0, 184.0, 11, -3.0)
	fruechte_bogen(186.5, 190.5, 5, 0.0)
	fruechte_reihe(193.0, 204.0, 6, 1.6)
	fruechte_reihe(208.0, 232.0, 10, 0.0)
