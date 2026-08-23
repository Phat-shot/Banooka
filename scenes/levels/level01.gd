extends LevelBasis
## Level 01 – "Wurzelschlucht"
##
## Ein kurviger Waldpfad in fünf Abschnitten. Der Verlauf steckt in einer
## Kurve; alle Objekte werden über `LevelWerkzeuge.punkt(verlauf, strecke,
## seitlich, hoehe)` relativ dazu platziert. Wer den Verlauf ändert,
## verschiebt damit automatisch alles Übrige mit.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  42  Waldrand   – Anlaufstrecke, erste Kisten, Draufspring-Gegner
##    42 – 100  Schlucht   – Rechtskurve, Bach mit Lücken, Federkiste, Spin-Gegner
##   100 – 158  Stacheln   – Linkskurve, Stachelfelder, Slide-Gegner, TNT
##   158 – 208  Kronen     – Anstieg, schmaler Grat, Sprungkisten, Nitro
##   208 – 236  Lichtung   – Lebenskiste, Zielportal

const KISTE := preload("res://scenes/crates/Kiste.tscn")
const FRUCHT := preload("res://scenes/fruits/Frucht.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENVOGEL := preload("res://scenes/enemies/Stelzenvogel.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const WASSER := preload("res://scenes/hazards/Wasser.tscn")
const STACHELN := preload("res://scenes/hazards/Stacheln.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const WALDSTREUER := preload("res://scenes/props/Waldstreuer.tscn")

# Strecken-Marken der Abschnitte
const M_WALDRAND := 0.0
const M_SCHLUCHT := 42.0
const M_STACHELN := 100.0
const M_KRONEN := 158.0
const M_LICHTUNG := 208.0
const M_ENDE := 236.0

# Höhen relativ zum Weg
const WALDBODEN_HOEHE := -14.0  ## sichtbarer Waldboden tief unter dem Pfad
const ABSTURZ_HOEHE := -6.0     ## darunter ist der Sturz tödlich
const WASSER_HOEHE := -13.4     ## Bachlauf am Grund der Schlucht (nur Kulisse)


func _baue() -> void:
	for schritt in _bauschritte():
		var tun: Callable = schritt["tun"]
		tun.call()


## Aufbau in Einzelschritten, damit der Ladebildschirm mitläuft.
## Die Waldbestände sind der teuerste Teil und stehen deshalb einzeln
## in der Liste.
func _bauschritte() -> Array:
	var schritte: Array = [
		{"text": "Wegverlauf", "tun": _verlauf_anlegen},
		{"text": "Waldboden", "tun": _waldboden_bauen},
		{"text": "Weg wird angelegt", "tun": _boden_bauen},
		{"text": "Plattformen", "tun": _plattformen_bauen},
	]
	# Der Verlauf muss stehen, bevor die Bestände gesetzt werden – die
	# Anzahl hängt nur von der Streckenlänge ab, nicht von der Kurve.
	for nummer in _bestand_anzahl():
		schritte.append({
			"text": "Wald wächst (%d/%d)" % [nummer + 1, _bestand_anzahl()],
			"tun": _bestand_setzen.bind(nummer),
		})
	schritte.append_array([
		{"text": "Bäume am Wegesrand", "tun": _rahmenbaeume},
		{"text": "Farne und Pilze", "tun": _wegdeko},
		{"text": "Portale", "tun": _portale_setzen},
		{"text": "Bach und Stacheln", "tun": _gefahren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	])
	return schritte


## Der Weg durch den Wald: zwei große Kurven und ein Anstieg zum Ziel.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),        # Startportal
		Vector3(0, 0, -18),      # gerade Anlaufstrecke
		Vector3(3, 0, -36),      # Beginn der Rechtskurve
		Vector3(13, 0, -52),     # Schlucht
		Vector3(28, 1, -63),
		Vector3(45, 1, -70),     # Ende der Rechtskurve
		Vector3(62, 2, -80),     # Stachelpassage, Linkskurve beginnt
		Vector3(72, 3, -98),
		Vector3(74, 4, -120),
		Vector3(68, 6, -140),    # Anstieg in die Baumkronen
		Vector3(56, 8, -156),
		Vector3(40, 9, -168),
		Vector3(22, 10, -175),   # Lichtung
		Vector3(4, 10, -178),
	])


## Bodenstreifen mit Lücken. Die Lücken sind die Sprungpassagen –
## darunter liegt je nach Abschnitt Wasser oder Abgrund.
## Bodenstreifen mit Lücken. Die Lücken sind die Sprungpassagen –
## darunter liegt der Waldboden, abgefangen von der Absturzzone.
## Diese Liste ist die einzige Quelle für den Wegverlauf: `_breite_bei()`
## liest sie ebenfalls aus, damit Objekte nie neben dem Weg landen.
const ABSCHNITTE := [
	# --- Waldrand: breit und sicher, eine kleine Lücke zum Üben ---
	{"von": 0.0, "bis": 26.0, "breite": 11.0},
	{"von": 30.0, "bis": 42.0, "breite": 10.0},
	# --- Schlucht: schmaler, zwei Lücken über dem Bach ---
	{"von": 42.0, "bis": 56.0, "breite": 9.0, "breite_ende": 7.0},
	{"von": 62.0, "bis": 74.0, "breite": 7.0},
	{"von": 80.0, "bis": 100.0, "breite": 8.0, "breite_ende": 10.0},
	# --- Stachelpassage: breit genug zum Ausweichen ---
	{"von": 100.0, "bis": 128.0, "breite": 10.0},
	{"von": 132.0, "bis": 158.0, "breite": 9.0},
	# --- Baumkronen: schmaler Grat mit Lücken ---
	{"von": 158.0, "bis": 172.0, "breite": 7.0},
	{"von": 178.0, "bis": 190.0, "breite": 6.0},
	{"von": 196.0, "bis": 208.0, "breite": 7.0, "breite_ende": 9.0},
	# --- Lichtung: weite Fläche zum Abschluss ---
	{"von": 208.0, "bis": 236.0, "breite": 13.0},
]


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, ABSCHNITTE, {
		"oben": Materialbibliothek.waldweg(),   # Erde: hebt sich vom Grün ab
		"kante": Materialbibliothek.gras(),     # erhöhte Rasenkante als Begrenzung
		"klippe": Materialbibliothek.fels(),    # Felswand macht die Tiefe sichtbar
	}, {
		"tiefe": 15.5,
		"schritt": 1.0,
		"kante_hoehe": 0.45,
		"kante_breite": 0.8,
	})


## Breite des Weges an dieser Stelle. 0.0 bedeutet: hier ist eine Lücke.
func _breite_bei(strecke: float) -> float:
	for a in ABSCHNITTE:
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			var t := inverse_lerp(von, bis, strecke)
			return lerpf(a["breite"], a.get("breite_ende", a["breite"]), t)
	return 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func _rand_bei(strecke: float, sicherheit: float = 1.3) -> float:
	return maxf(_breite_bei(strecke) * 0.5 - sicherheit, 0.0)


## Schiebt eine Strecke vom Rand eines Abschnitts weg, damit Objekte
## nicht auf der Abbruchkante stehen.
func _weg_von_der_kante(strecke: float, abstand: float) -> float:
	for a in ABSCHNITTE:
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			if bis - von <= abstand * 2.0:
				return (von + bis) * 0.5
			return clampf(strecke, von + abstand, bis - abstand)
	return strecke


## Einzelne Plattformen über den Lücken und als Kletterhilfen.
func _plattformen_bauen() -> void:
	var fels := Materialbibliothek.fels()
	var gras := Materialbibliothek.gras()

	# Trittstein in der ersten Lücke (Waldrand)
	_stein_plattform(28.0, 0.0, -0.4, Vector3(3.0, 0.8, 3.0), fels)

	# Schlucht: zwei versetzte Felsplateaus in den Lücken
	_stein_plattform(59.0, -1.5, 0.4, Vector3(3.2, 0.8, 3.2), fels)
	_stein_plattform(77.0, 1.8, 0.8, Vector3(3.0, 0.8, 3.0), fels)

	# Stachelpassage: erhöhter Umweg über zwei Grasplateaus
	_stein_plattform(112.0, -3.6, 1.8, Vector3(4.0, 0.7, 5.0), gras)
	_stein_plattform(120.0, -3.6, 3.0, Vector3(4.0, 0.7, 4.0), gras)
	_stein_plattform(130.0, 0.0, 0.6, Vector3(4.5, 0.8, 3.0), fels)

	# Baumkronen: Stufen im Anstieg und Trittsteine in den Lücken
	_stein_plattform(175.0, 0.0, 1.2, Vector3(3.0, 0.8, 3.0), fels)
	_stein_plattform(193.0, -1.2, 2.0, Vector3(2.8, 0.8, 2.8), fels)
	_stein_plattform(199.0, 1.4, 3.2, Vector3(2.8, 0.8, 2.8), fels)


## Plattform relativ zum Verlauf setzen, mit dem Weg mitgedreht.
func _stein_plattform(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, material: Material) -> StaticBody3D:
	var pos := LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	return LevelWerkzeuge.plattform(geometrie, pos, groesse, material,
			LevelWerkzeuge.drehung(verlauf, strecke))


# =========================================================== Portale

func _portale_setzen() -> void:
	var start := STARTPORTAL.instantiate()
	start.position = LevelWerkzeuge.punkt(verlauf, 1.0, 0.0, 0.1)
	start.rotation.y = LevelWerkzeuge.drehung(verlauf, 1.0)
	objekte.add_child(start)

	var ziel := ZIELPORTAL.instantiate()
	ziel.position = LevelWerkzeuge.punkt(verlauf, M_ENDE - 4.0, 0.0, 0.1)
	ziel.rotation.y = LevelWerkzeuge.drehung(verlauf, M_ENDE - 4.0)
	objekte.add_child(ziel)


# =========================================================== Gefahren

func _gefahren_setzen() -> void:
	# --- Bach am Grund der Schlucht. Reine Kulisse: der Spieler wird
	# schon von der Absturzzone weit darüber abgefangen. ---
	_wasser(50.0, Vector2(26.0, 40.0), WASSER_HOEHE).toedlich = false
	_wasser(86.0, Vector2(26.0, 40.0), WASSER_HOEHE).toedlich = false
	# --- Absturzzone: wer vom Pfad fällt, überlebt es nicht ---
	_absturzzonen()
	# --- Lücken sichtbar markieren ---
	_luecken_markieren()

	# --- Stachelfelder in der Stachelpassage ---
	_stacheln(106.0, 0.0, Vector2(4.0, 3.0), false)
	_stacheln(118.0, 1.0, Vector2(5.0, 3.0), true)
	_stacheln(142.0, -1.0, Vector2(4.5, 3.5), false)
	_stacheln(150.0, 2.0, Vector2(3.0, 3.0), true)

	# --- Stacheln auf dem schmalen Grat der Baumkronen ---
	_stacheln(184.0, -1.6, Vector2(2.5, 4.0), false)


func _wasser(strecke: float, flaeche: Vector2, hoehe: float,
		seitlich: float = 0.0) -> Wasser:
	var w := WASSER.instantiate() as Wasser
	w.flaeche = flaeche
	w.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	return w


func _stacheln(strecke: float, seitlich: float, flaeche: Vector2,
		einfahrbar: bool) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = einfahrbar
	st.versatz = fmod(strecke, 2.0)
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	st.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(st)
	return st


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Waldrand: die Grundlagen ----------
	_kiste(Kiste.Art.NORMAL, 10.0, -1.2)
	_kiste(Kiste.Art.NORMAL, 10.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 10.0, 1.2)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 14.0, 0.0)
	# Stapel: obere Kiste nur durch Draufspringen oder Spin erreichbar
	_kiste(Kiste.Art.NORMAL, 22.0, -1.0)
	_kiste(Kiste.Art.NORMAL, 22.0, -1.0, 1.5)
	_kiste(Kiste.Art.NORMAL, 22.0, 1.0)
	_kiste(Kiste.Art.SCHUTZ, 22.0, -2.2)
	_kiste(Kiste.Art.CHECKPOINT, 34.0, 0.0)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 38.5, -1.8)

	# ---------- Schlucht: Federkiste und Eisenplattformen ----------
	_kiste(Kiste.Art.FEDER, 50.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 53.5, 1.6)
	# Eisenkisten als Trittstufen über die zweite Lücke
	_kiste(Kiste.Art.EISEN, 64.5, -1.0)
	_kiste(Kiste.Art.EISEN, 66.5, -1.0, 1.5)
	_kiste(Kiste.Art.NORMAL, 66.5, -1.0, 2.5)
	_kiste(Kiste.Art.NORMAL, 70.0, 1.4)
	# TNT-Kette: die TNT reißt die Nachbarn mit
	_kiste(Kiste.Art.NORMAL, 84.0, -1.1)
	_kiste(Kiste.Art.TNT, 84.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 84.0, 1.1)
	_kiste(Kiste.Art.NORMAL, 85.2, 0.0)
	_kiste(Kiste.Art.CHECKPOINT, 96.0, 0.0)

	# ---------- Stachelpassage: Nitro als Fallstrick ----------
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 112.0, -3.6, 1.8 + 0.85)
	_kiste(Kiste.Art.NORMAL, 120.0, -3.6, 3.0 + 0.85)
	_kiste(Kiste.Art.NITRO, 134.0, -1.4)
	_kiste(Kiste.Art.NORMAL, 134.0, 0.2)
	_kiste(Kiste.Art.NORMAL, 135.4, 0.2)
	_kiste(Kiste.Art.NORMAL, 136.8, 0.2)
	_kiste(Kiste.Art.FEDER, 148.0, 1.8)
	_kiste(Kiste.Art.SCHUTZ, 150.0, 2.2)
	_kiste(Kiste.Art.CHECKPOINT, 154.0, 0.0)

	# ---------- Baumkronen: Sprungfedern und Nitro auf dem Grat ----------
	_kiste(Kiste.Art.SPRUNG, 162.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 162.0, 0.0, 4.0)
	_kiste(Kiste.Art.NORMAL, 163.4, 0.0, 4.0)
	_kiste(Kiste.Art.NITRO, 186.0, 1.4)
	_kiste(Kiste.Art.NITRO, 187.4, 1.4)
	_kiste(Kiste.Art.NORMAL, 186.7, -1.2)
	_kiste(Kiste.Art.FEDER, 194.0, -1.2, 2.0 + 0.5)
	_kiste(Kiste.Art.TNT, 204.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 204.0, -1.2)
	_kiste(Kiste.Art.NORMAL, 204.0, 1.2)

	# ---------- Lichtung: Belohnung ----------
	_kiste(Kiste.Art.LEBEN, 214.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 219.0, -2.0)
	_kiste(Kiste.Art.NORMAL, 219.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 219.0, 2.0)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 224.0, 0.0)


func _kiste(art: Kiste.Art, strecke: float, seitlich: float,
		hoehe: float = 0.5) -> Kiste:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	k.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	k.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(k)
	return k


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Waldrand: Drehschlag lernen ----------
	_gegner(SUMPFKROETE, 18.0, 0.0, 3.5, true)
	_gegner(SUMPFKROETE, 39.0, 1.5, 3.0, true)

	# ---------- Schlucht: Draufspringen lernen ----------
	_gegner(PANZERKAEFER, 52.0, 0.0, 2.5, true)
	_gegner(PANZERKAEFER, 70.5, -1.0, 3.0, true)
	_gegner(SUMPFKROETE, 88.0, 0.0, 3.0, true)

	# ---------- Stachelpassage: Slide lernen ----------
	_gegner(STELZENVOGEL, 110.0, -1.0, 3.0, true)
	_gegner(STELZENVOGEL, 123.0, 0.5, 3.5, true)
	_gegner(PANZERKAEFER, 138.0, -2.0, 2.5, true)
	_gegner(STELZENVOGEL, 146.0, 0.0, 3.0, true)

	# ---------- Baumkronen: alles gemischt ----------
	_gegner(SUMPFKROETE, 166.0, 0.0, 2.5, true)
	_gegner(PANZERKAEFER, 182.0, 1.2, 2.0, false)
	_gegner(STELZENVOGEL, 200.0, 0.0, 2.5, true)

	# ---------- Lichtung: letzte Wache ----------
	_gegner(PANZERKAEFER, 216.0, 3.5, 3.0, true)
	_gegner(SUMPFKROETE, 222.0, -3.5, 3.0, true)


## Setzt einen Gegner auf den Weg. `quer` bestimmt, ob er quer zum
## Korridor patrouilliert (true) oder ihm entlang (false).
func _gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool) -> Gegner:
	var g := szene.instantiate() as Gegner
	# Nicht direkt an die Abbruchkante stellen
	strecke = _weg_von_der_kante(strecke, 2.5)
	# Der Gegner darf beim Patrouillieren nicht vom Weg laufen: seitlicher
	# Versatz und Weite werden auf die Wegbreite an dieser Stelle begrenzt.
	var rand := _rand_bei(strecke)
	if quer:
		seitlich = clampf(seitlich, -rand * 0.5, rand * 0.5)
		weite = minf(weite, maxf(rand - absf(seitlich), 0.5))
	else:
		seitlich = clampf(seitlich, -rand, rand)
		# Entlang des Weges: Weite so kürzen, dass beide Enden auf dem Weg liegen
		var frei := 99.0
		for a in ABSCHNITTE:
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


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	# Führungslinien aus Früchten weisen den Weg und markieren Sprünge
	_fruechte_reihe(6.0, 9.0, 4, 0.0, 0.9)
	_fruechte_reihe(16.0, 20.0, 5, -1.4, 0.9)
	_fruechte_reihe(26.5, 29.5, 4, 0.0, 2.2)      # Bogen über die erste Lücke
	_fruechte_reihe(30.5, 33.5, 4, 0.0, 2.2)
	_fruechte_reihe(44.0, 48.0, 5, 1.2, 0.9)
	_fruechte_reihe(56.5, 61.5, 5, -1.5, 2.6)     # über den Bach
	_fruechte_reihe(74.5, 79.5, 5, 1.8, 2.6)
	_fruechte_reihe(90.0, 95.0, 5, 0.0, 0.9)
	_fruechte_reihe(102.0, 105.0, 4, -2.5, 0.9)
	_fruechte_reihe(113.0, 119.0, 6, -3.6, 3.0)   # auf dem Umweg über die Plateaus
	_fruechte_reihe(126.0, 130.0, 5, 2.2, 0.9)
	_fruechte_reihe(144.0, 148.0, 5, -1.8, 0.9)
	_fruechte_reihe(160.0, 164.0, 4, -1.8, 0.9)
	_fruechte_reihe(172.5, 177.5, 5, 0.0, 2.8)    # über die Grat-Lücke
	_fruechte_reihe(190.5, 195.5, 5, 0.0, 3.4)
	_fruechte_reihe(209.0, 213.0, 5, 0.0, 0.9)
	_fruechte_reihe(226.0, 230.0, 6, 0.0, 0.9)


func _fruechte_reihe(von: float, bis: float, anzahl: int,
		seitlich: float, hoehe: float) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		var s := lerpf(von, bis, t)
		var f := FRUCHT.instantiate()
		f.position = LevelWerkzeuge.punkt(verlauf, s, seitlich, hoehe)
		objekte.add_child(f)


# =========================================================== Waldboden

## Der Pfad verläuft auf einem Grat. Weit darunter liegt der Waldboden –
## sichtbar, aber nicht begehbar; wer hinunterfällt, stirbt vorher in der
## Absturzzone. Darauf stehen die Bäume, deren Kronen bis auf Weghöhe reichen.
func _waldboden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, [
		{"von": 0.0, "bis": M_ENDE, "breite": 110.0},
	], {
		"oben": Materialbibliothek.waldboden(),
		"kante": Materialbibliothek.waldboden(),
		"klippe": Materialbibliothek.fels(),
	}, {
		"tiefe": 22.0,
		"schritt": 4.0,
		"kollision": false,
		"kante_hoehe": 0.0,
		"kante_breite": 0.0,
		"hoehe_versatz": WALDBODEN_HOEHE,   # tief unter dem Weg
	})


## Reihe unsichtbarer Bereiche unter dem Pfad, die den Sturz beenden.
func _absturzzonen() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ENDE:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(70.0, 5.0, schritt + 4.0)
		form.shape = box
		zone.add_child(form)
		zone.position = LevelWerkzeuge.punkt(verlauf, s + schritt * 0.5,
				0.0, ABSTURZ_HOEHE - 2.5)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s + schritt * 0.5)
		zone.body_entered.connect(_auf_absturz)
		geometrie.add_child(zone)
		s += schritt


func _auf_absturz(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("sterben"):
		koerper.call("sterben")


# =========================================================== Wald

## Verteilt den Wald in einem Rutsch. Wird nur noch von außen genutzt;
## der Levelaufbau ruft die Teile einzeln über `_bauschritte()` auf.
func _wald_bauen() -> void:
	_bestaende_unten()
	_wegrand_bepflanzen()


## Waldbestände auf dem Waldboden. Die Kronen ragen bis auf Weghöhe herauf
## und rahmen den Pfad ein.
func _bestaende_unten() -> void:
	for nummer in _bestand_anzahl():
		_bestand_setzen(nummer)


## Anzahl der Waldbestände entlang des Weges.
func _bestand_anzahl() -> int:
	return int(ceil((M_ENDE - 6.0) / 26.0))


## Ein Waldbestand auf dem Waldboden. Einzeln aufrufbar, damit der
## Ladebildschirm zwischen den Beständen ein Bild zeichnen kann –
## sie sind der teuerste Teil des Aufbaus.
func _bestand_setzen(nummer: int) -> void:
		var s := 6.0 + float(nummer) * 26.0
		var streuer := WALDSTREUER.instantiate() as Waldstreuer
		streuer.flaeche = Vector2(34.0, 30.0)
		streuer.anzahl = 22
		streuer.saat = 1000 + nummer * 37
		streuer.mindestabstand_mitte = 9.0
		streuer.anteil_baeume = 0.62
		streuer.anteil_steine = 0.16
		streuer.anteil_wurzeln = 0.06
		streuer.baum_hoehe_min = 7.0
		streuer.baum_hoehe_max = 12.5
		streuer.anteil_nadelbaum = 0.35
		streuer.anteil_totholz = 0.1
		streuer.grasfelder = 2
		streuer.gras_dichte = 90
		streuer.gras_feldgroesse = 8.0
		streuer.hoehen_streuung = 0.6
		streuer.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, WALDBODEN_HOEHE)
		streuer.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		deko.add_child(streuer)


## Deko am Weg. Wichtig: Auf dem Weg selbst stehen nur niedrige Dinge.
## Bäume wachsen aus der Schlucht neben dem Grat empor und rahmen den Weg
## ein – stünden sie auf dem Weg, geriete die Verfolgerkamera in ihre Krone.
func _wegrand_bepflanzen() -> void:
	_rahmenbaeume()
	_wegdeko()


## Hohe Bäume, die vom Waldboden bis über Weghöhe reichen.
func _rahmenbaeume() -> void:
	var stellen := [
		[8.0, -1.0, 17.0], [15.0, 1.0, 19.0], [24.0, -1.0, 16.0], [36.0, 1.0, 20.0],
		[46.0, -1.0, 17.5], [54.0, 1.0, 16.0], [66.0, 1.0, 18.0], [78.0, -1.0, 17.0],
		[86.0, -1.0, 19.0], [98.0, 1.0, 21.0], [108.0, -1.0, 18.5], [118.0, 1.0, 17.0],
		[124.0, 1.0, 16.5], [140.0, -1.0, 20.0], [150.0, 1.0, 18.0], [156.0, -1.0, 17.0],
		[164.0, -1.0, 19.5], [172.0, 1.0, 18.0], [186.0, 1.0, 17.5], [196.0, -1.0, 20.0],
		[206.0, -1.0, 18.0], [214.0, 1.0, 21.0], [222.0, -1.0, 19.0], [230.0, 1.0, 17.5],
	]
	for i in stellen.size():
		var e: Array = stellen[i]
		var strecke: float = e[0]
		var seite: float = e[1]
		# Deutlich außerhalb der Wegkante, damit die Kamera frei bleibt
		var abstand := _rand_bei(strecke, 0.0) + 4.5 + float(i % 3) * 1.6
		var b := BAUM.instantiate() as Baum
		b.hoehe = e[2]
		b.saat = 400 + i * 13
		b.art = Baum.Art.NADELBAUM if i % 4 == 3 else Baum.Art.LAUBBAUM
		b.laubfarbe = Farben.LAUB.lerp(Farben.LAUB_HELL, float(i % 3) * 0.4)
		b.position = LevelWerkzeuge.punkt(verlauf, strecke, seite * abstand, WALDBODEN_HOEHE)
		b.rotation.y = float(i) * 1.37
		deko.add_child(b)

	# Totholz als Blickfang in der Schlucht
	for stelle in [[54.0, -1.0], [132.0, 1.0], [196.0, -1.0]]:
		var strecke: float = stelle[0]
		var t := BAUM.instantiate() as Baum
		t.art = Baum.Art.TOTHOLZ
		t.hoehe = 13.0
		t.saat = int(strecke)
		t.position = LevelWerkzeuge.punkt(verlauf, strecke,
				stelle[1] * (_rand_bei(strecke, 0.0) + 5.0), WALDBODEN_HOEHE)
		deko.add_child(t)


## Niedrige Deko auf dem Weg selbst: Wurzeln, Findlinge, Gras, Kleinzeug.
## Alles bleibt unter Kniehöhe, damit die Sicht frei bleibt.
func _wegdeko() -> void:
	# Wurzelbögen quer über den Weg – Hindernisse zum Drüberspringen
	for stelle in [[20.0, 0.0, 4.5], [72.0, 0.0, 4.0], [144.0, -0.5, 4.5],
			[180.0, 0.0, 3.5], [212.0, 0.5, 5.0]]:
		var strecke: float = stelle[0]
		var w := WURZEL.instantiate() as Wurzel
		w.spannweite = stelle[2]
		w.hoehe = 1.0
		w.saat = int(strecke) * 3
		w.position = LevelWerkzeuge.punkt(verlauf, strecke, stelle[1], 0.0)
		w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke) + PI * 0.5
		deko.add_child(w)

	# Findlinge am Wegesrand, innerhalb der Kante
	for i in 16:
		var s := 12.0 + float(i) * 14.0
		if s > M_ENDE - 6.0:
			break
		var seite := 1.0 if i % 2 == 0 else -1.0
		var st := STEIN.instantiate() as Stein
		st.groesse = 0.55 + float(i % 3) * 0.3
		st.saat = 700 + i * 11
		st.bemoost = i % 3 == 0
		st.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.1), 0.5), -0.15)
		deko.add_child(st)

	# Grasnarben entlang des Weges, direkt an der Kante
	for i in 22:
		var s := 5.0 + float(i) * 10.5
		if s > M_ENDE - 4.0:
			break
		var seite := -1.0 if i % 2 == 0 else 1.0
		var g := GRASFELD.instantiate() as Grasfeld
		g.flaeche = Vector2(3.2, 5.0)
		g.anzahl = 150
		g.saat = 200 + i * 7
		g.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.6), 0.4), 0.0)
		g.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		deko.add_child(g)

	# Farne, Pilze, Büsche und Blumen
	var arten := [Kleinzeug.Art.FARN, Kleinzeug.Art.PILZ, Kleinzeug.Art.BUSCH,
			Kleinzeug.Art.BLUME]
	for i in 44:
		var s := 4.0 + float(i) * 5.2
		if s > M_ENDE - 3.0:
			break
		var seite := -1.0 if i % 2 == 0 else 1.0
		var k := KLEINZEUG.instantiate() as Kleinzeug
		k.art = arten[i % arten.size()]
		k.groesse = 0.45 + float(i % 4) * 0.18
		k.saat = 900 + i * 5
		k.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.4) - float(i % 3) * 0.5, 0.3), 0.0)
		k.rotation.y = float(i) * 0.9
		deko.add_child(k)


# =========================================================== Lücken

## Setzt an jede Abbruchkante Warnpfosten mit Querbalken und einen
## Warnstreifen auf dem Weg, damit Löcher von weitem als Löcher erkennbar sind.
func _luecken_markieren() -> void:
	for i in ABSCHNITTE.size():
		var a: Dictionary = ABSCHNITTE[i]
		if i + 1 < ABSCHNITTE.size():
			var naechster: Dictionary = ABSCHNITTE[i + 1]
			if naechster["von"] - a["bis"] > 0.5:
				_warnbalken(a["bis"] - 0.5, a.get("breite_ende", a["breite"]))
				_warnbalken(naechster["von"] + 0.5, naechster["breite"])


## Zwei Holzpfosten mit Querbalken quer zum Weg, knapp vor der Kante.
func _warnbalken(strecke: float, breite: float) -> void:
	var holz := Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	var streifen := Materialbibliothek.leuchtend(Color(1.0, 0.85, 0.25), 0.5)
	var halb := breite * 0.5 - 0.55
	var drehung := LevelWerkzeuge.drehung(verlauf, strecke)

	for seite: float in [-1.0, 1.0]:
		var gruppe := Node3D.new()
		gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seite * halb, 0.45)
		gruppe.rotation.y = drehung
		deko.add_child(gruppe)

		var pfosten := MeshInstance3D.new()
		var zylinder := CylinderMesh.new()
		zylinder.top_radius = 0.09
		zylinder.bottom_radius = 0.11
		zylinder.height = 1.1
		zylinder.radial_segments = 8
		pfosten.mesh = zylinder
		pfosten.position.y = 0.55
		pfosten.material_override = holz
		gruppe.add_child(pfosten)

		var kappe := MeshInstance3D.new()
		var band := CylinderMesh.new()
		band.top_radius = 0.13
		band.bottom_radius = 0.13
		band.height = 0.18
		band.radial_segments = 8
		kappe.mesh = band
		kappe.position.y = 1.0
		kappe.material_override = streifen
		gruppe.add_child(kappe)

	# Querbalken auf Kniehöhe – warnt, ohne die Sicht auf die Lücke zu nehmen
	var balken := MeshInstance3D.new()
	var quader := BoxMesh.new()
	quader.size = Vector3(halb * 2.0, 0.1, 0.08)
	balken.mesh = quader
	balken.material_override = holz
	balken.position = LevelWerkzeuge.punkt(verlauf, strecke, 0.0, 0.62)
	balken.rotation.y = drehung
	deko.add_child(balken)

	# Warnstreifen auf dem Weg: aus der Verfolgerkamera gut sichtbar
	var streifen_mesh := BoxMesh.new()
	streifen_mesh.size = Vector3(halb * 2.0 + 0.6, 0.04, 0.45)
	var markierung := MeshInstance3D.new()
	markierung.mesh = streifen_mesh
	markierung.material_override = streifen
	markierung.position = LevelWerkzeuge.punkt(verlauf, strecke, 0.0, 0.03)
	markierung.rotation.y = drehung
	deko.add_child(markierung)
