extends Node3D
## Baut Props isoliert auf und fotografiert sie.
##
## Zwei Sorten:
## * **Bewegungs-Props** (staub, laub, voegel): Bewegung sieht man auf einem
##   einzelnen Bild nicht. Deshalb entstehen mehrere Aufnahmen im Abstand
##   von `PROPSCHAU_PAUSE` Sekunden: nebeneinander gelegt zeigen sie, ob sich
##   überhaupt etwas rührt, wie weit es sich bewegt und ob beim Rücksprung
##   einer Bahn etwas sichtbar umspringt.
## * **Holz und Stein** (stamm, krone, findling, farn, wald, tal, welt): die
##   prozeduralen Bauteile `Riesenstamm`, `Kronenwolke`, `Findling` und
##   `Farnwerk`, jedes in mehreren Größen und Fassungen, unter dem Licht von
##   Level 01 und aus festen Blickwinkeln (je Blickwinkel ein Bild). Dazu
##   stehen je Bauteil die Dreieckszahlen in der Ausgabe. `wald` stellt alles
##   zusammen in einen Hallenwald und blickt aus der Spielkamera hinein,
##   `tal` zeigt das Kronendach von oben (wie vom Grat), `welt` einen Stamm
##   in der Größe des Weltenbaums.
## * **messung** läuft auch headless: Dreieckszahlen gegen die Grenzen und
##   die Findlingsprobe (Oberkante gegen Kastenoberkante, ≤ 0,03 m, per
##   Strahl gemessen). Rückgabe 1 bei einer Abweichung.
##
## Aufruf (siehe werkzeuge/propschau.sh; ohne Bildschirm mit xvfb-run davor):
##   PROPSCHAU=staub godot --path . res://werkzeuge/Propschau.tscn
##   xvfb-run -a -s "-screen 0 1280x720x24" bash werkzeuge/propschau.sh /tmp/p "stamm krone findling farn wald tal welt"
##   PROPSCHAU=messung godot --headless --path . res://werkzeuge/Propschau.tscn
##
## PROPSCHAU        staub | laub | voegel | stamm | krone | findling | farn |
##                  wald | tal | welt | messung
## PROPSCHAU_ZIEL   Zielverzeichnis (Vorgabe /tmp/propschau)
## PROPSCHAU_BILDER Anzahl der Aufnahmen (Vorgabe 3, nur Bewegungs-Props)
## PROPSCHAU_PAUSE  Sekunden zwischen den Aufnahmen (Vorgabe 1.2, ebenso)
## PROPSCHAU_NUR    nur diese Blickwinkel (Namen mit Komma), zum Nachbessern

const GRAS := preload("res://scenes/props/Gras.tscn")
const HIMMEL := preload("res://shaders/himmel.gdshader")

## Grenzen aus dem Plan (Abschnitt 16, P4).
const GRENZE_STAMM := 6000
const GRENZE_SCHLICHT := 300
const GRENZE_KRONE := 3000
const GRENZE_FINDLING := 1500
const GRENZE_OBERKANTE := 0.03

## Blickwinkel der Holz- und Steinszenen: [Name, Ort, Ziel, Sichtfeld].
var _blicke: Array = []


func _ready() -> void:
	var art := OS.get_environment("PROPSCHAU")
	if art.is_empty():
		art = "staub"
	var ziel := OS.get_environment("PROPSCHAU_ZIEL")
	if ziel.is_empty():
		ziel = "/tmp/propschau"
	var bilder := maxi(int(OS.get_environment("PROPSCHAU_BILDER")), 1)
	var pause := float(OS.get_environment("PROPSCHAU_PAUSE"))
	if pause <= 0.0:
		pause = 1.2

	match art:
		"messung":
			var fehler := await _messung()
			get_tree().quit(1 if fehler > 0 else 0)
			return
		"stamm", "krone", "findling", "farn", "wald", "tal", "welt":
			_waldlicht()
			match art:
				"stamm":
					_szene_stamm()
				"krone":
					_szene_krone()
				"findling":
					_szene_findling()
				"farn":
					_szene_farn()
				"wald":
					_szene_wald()
				"tal":
					_szene_tal()
				_:
					_szene_welt()
			print("Propschau: %s, %d Blickwinkel" % [art, _blicke.size()])
			await _blicke_fotografieren(ziel, art)
			get_tree().quit()
			return
		"laub":
			_szene_laub()
		"voegel":
			_szene_voegel()
		_:
			_szene_staub()

	print("Propschau: %s, %d Bilder im Abstand von %.1f s" % [art, bilder, pause])
	await _fotografieren(ziel, art, bilder, pause)
	get_tree().quit()


# ---------------------------------------------------------------- Aufbauten

## Staub im Lichtschacht: dunkle Wand, Sonne von schräg hinten. Additive
## Teilchen sind nur vor dunklem Grund zu sehen – genau der Fall, für den
## das Prop gedacht ist.
func _szene_staub() -> void:
	_umgebung(Color(0.10, 0.12, 0.13), Color(0.25, 0.27, 0.28), 0.35)
	_sonne(Vector3(deg_to_rad(-25.0), deg_to_rad(160.0), 0.0), 2.2)
	_wand(Vector3(0.0, 4.0, -4.0), Vector3(16.0, 12.0, 0.5),
			Color(0.18, 0.17, 0.15))
	_boden(20.0, Color(0.16, 0.15, 0.13))

	var staub := Staubflug.new()
	staub.raum = Vector3(5.0, 7.0, 3.0)
	staub.anzahl = 140
	staub.saat = 4711
	add_child(staub)

	_kamera(Vector3(0.0, 3.2, 7.0), Vector3(0.0, 3.2, 0.0), 50.0)


## Laub über einer Wiese: das Grasfeld steht daneben, damit man das
## gleichmäßige Wiegen des Grases direkt neben den Böen des Laubs sieht.
func _szene_laub() -> void:
	_umgebung(Color(0.55, 0.66, 0.74), Color(0.62, 0.66, 0.62), 0.6)
	_sonne(Vector3(deg_to_rad(-38.0), deg_to_rad(40.0), 0.0), 1.5)
	_boden(30.0, Color(0.30, 0.26, 0.18))

	var gras := GRAS.instantiate() as Grasfeld
	gras.flaeche = Vector2(12.0, 8.0)
	gras.saat = 99
	add_child(gras)

	var laub := Laubtreiben.new()
	laub.flaeche = Vector2(10.0, 6.0)
	laub.hoehe = 1.4
	laub.anzahl = 60
	laub.saat = 4711
	add_child(laub)

	_kamera(Vector3(0.0, 1.6, 7.5), Vector3(0.0, 0.9, 0.0), 55.0)


## Vögel: Blick von unten in den Himmel, wie ihn der Spieler hätte.
func _szene_voegel() -> void:
	_umgebung(Color(0.58, 0.72, 0.85), Color(0.7, 0.75, 0.8), 0.8)
	_sonne(Vector3(deg_to_rad(-50.0), deg_to_rad(30.0), 0.0), 1.4)

	var schwarm := Vogelschwarm.new()
	schwarm.anzahl = 9
	schwarm.radius = 26.0
	schwarm.hoehe = 30.0
	schwarm.spannweite = 1.8
	# fürs Bild deutlich schneller als im Level, sonst sieht man nichts
	schwarm.umdrehungen_je_minute = 6.0
	schwarm.schlag_tempo = 1.4
	schwarm.saat = 4711
	add_child(schwarm)

	_kamera(Vector3(0.0, 1.5, 16.0), Vector3(0.0, 30.0, 0.0), 60.0)


# ---------------------------------------------------------------- Holz und Stein

## Stämme: ein Talriese mit allem Beiwerk, drei Bäume aus `baum()` (hoch,
## rund, breit und gedreht), eine schlichte Reihe, ein liegender Stamm und
## ein Stumpf.
func _szene_stamm() -> void:
	_waldboden(90.0)
	var riese := Riesenstamm.netz({"hoehe": 30.0, "radius": 1.6, "brettwurzeln": 7,
			"pilze": 3, "efeu": 2, "leuchtpilze": 2, "saat": 11})
	_setze(riese, Riesenstamm.borkenstoff(), Transform3D(Basis(), Vector3.ZERO), true, "Talriese")
	_kranz_um(riese, Vector3.ZERO)

	_baum({"hoehe": 16.0, "radius": 0.38, "variante": 2, "saat": 5}, Vector3(-10.0, 0.0, 3.0),
			"Hallenbaum")
	_baum({"hoehe": 13.0, "radius": 0.42, "variante": 0, "saat": 3}, Vector3(-19.0, 0.0, -8.0),
			"Laubbaum")
	_baum({"hoehe": 11.0, "radius": 0.5, "variante": 1, "drehung": 1.8, "rippen_tiefe": 0.1,
			"neigung": Vector2(2.2, 0.4), "krumm": 0.9, "saat": 9}, Vector3(10.0, 0.0, 4.0),
			"Rahmenbaum")
	for k in 5:
		var b := Riesenstamm.baum({"hoehe": 15.0, "radius": 0.34, "aeste": 3, "schlicht": true,
				"krone_radius": 3.2, "saat": 40 + k})
		var ort := Transform3D(Basis(), Vector3(16.0 + k * 4.5, 0.0, -12.0 - k * 2.5))
		_setze(b["stamm"], Riesenstamm.borkenstoff(), ort, true, "Schlicht")
		_setze(b["krone"], Kronenwolke.stoff(Farben.LAUB), ort, false, "Schlicht_Krone")
	var log_netz := Riesenstamm.liegend(0.42, 5.0, {"saat": 3, "aeste": 2})
	var liegen := Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)).rotated(Vector3.UP, 0.4),
			Vector3(3.0, 0.36, 8.5))
	_setze(log_netz, Riesenstamm.borkenstoff(), liegen, true, "Liegend")
	var stumpf := Riesenstamm.stumpf(0.7, 1.3, {"saat": 8})
	_setze(stumpf, Riesenstamm.borkenstoff(), Transform3D(Basis(), Vector3(-4.0, 0.0, 9.0)),
			true, "Stumpf")
	_kranz_um(stumpf, Vector3(-4.0, 0.0, 9.0))
	_figur(Vector3(1.5, 0.0, 6.0))

	_blick("stamm_ueberblick", Vector3(2.0, 8.0, 34.0), Vector3(0.0, 8.0, 0.0), 62.0)
	_blick("stamm_fuss", Vector3(6.0, 2.6, 8.5), Vector3(0.0, 1.4, 0.0), 58.0)
	_blick("stamm_spiel", Vector3(0.0, 6.5, 19.0), Vector3(0.0, 1.0, 5.0), 60.0)
	_blick("stamm_liegend", Vector3(1.0, 2.3, 14.5), Vector3(0.0, 0.6, 8.5), 50.0)
	_blick("stamm_rahmen", Vector3(4.0, 3.0, 20.0), Vector3(10.0, 6.0, 4.0), 55.0)


## Kronen: drei Varianten in drei Größen, dazu die Fernfassung, von der
## Seite und schräg von oben (wie vom Grat ins Tal).
func _szene_krone() -> void:
	_waldboden(120.0)
	var x := -14.0
	for variante in 3:
		var r := 3.0
		var netz := Kronenwolke.netz({"radius": r, "variante": variante, "saat": 1 + variante})
		_setze(netz, Kronenwolke.stoff(Farben.LAUB), Transform3D(Basis(),
				Vector3(x, r * 1.4 + 1.0, 0.0)), false, "Krone_%d" % variante)
		var klein := Kronenwolke.netz({"radius": 1.2, "variante": variante, "saat": 11 + variante})
		_setze(klein, Kronenwolke.stoff(Farben.LAUB), Transform3D(Basis(),
				Vector3(x, 1.2, 7.0)), false, "Busch_%d" % variante)
		x += 9.0
	var gross := Kronenwolke.netz({"radius": 5.5, "variante": 0, "saat": 31})
	_setze(gross, Kronenwolke.stoff(Farben.LAUB_DUNKEL), Transform3D(Basis(),
			Vector3(14.0, 8.0, -6.0)), false, "Gross")
	for k in 6:
		var fern := Kronenwolke.fern({"radius": rng_wert(k, 2.5, 4.0), "saat": 50 + k})
		_setze(fern, Kronenwolke.stoff(Farben.LAUB), Transform3D(Basis(),
				Vector3(-16.0 + k * 6.5, 2.5, -18.0)), false, "Fern_%d" % k)
	_figur(Vector3(-5.0, 0.0, 9.0))

	_blick("krone_seite", Vector3(-2.0, 5.0, 24.0), Vector3(-2.0, 4.0, 0.0), 62.0)
	_blick("krone_oben", Vector3(-2.0, 26.0, 26.0), Vector3(-2.0, 0.0, -4.0), 60.0)
	_blick("krone_nah", Vector3(-12.0, 4.5, 8.0), Vector3(-14.0, 5.0, 0.0), 55.0)


## Findlinge mit ihrem Kollisionskasten als Drahtgitter: Passt die Optik?
func _szene_findling() -> void:
	_waldboden(80.0)
	var kaesten: Array = [
		[Vector3(1.4, 0.9, 1.2), Vector3(-6.5, 0.45, 0.0), 1],
		[Vector3(3.5, 2.6, 2.4), Vector3(-1.5, 1.3, 0.0), 2],
		[Vector3(1.6, 3.0, 2.5), Vector3(3.5, 1.5, 0.0), 3],
		[Vector3(4.75, 1.2, 8.0), Vector3(10.0, 0.6, 1.0), 4],
	]
	for eintrag: Array in kaesten:
		var groesse: Vector3 = eintrag[0]
		var ort: Vector3 = eintrag[1]
		var saat: int = eintrag[2]
		var trafo := Transform3D(Basis(Vector3.UP, 0.15 * float(saat)), ort)
		Findling.bauen(self, groesse, trafo, {"saat": saat})
		_drahtkasten(groesse, trafo)
	# Trittstein im Wasser
	var wasser := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(9.0, 6.0)
	wasser.mesh = ebene
	wasser.position = Vector3(-4.0, 0.02, 7.0)
	var wstoff := StandardMaterial3D.new()
	wstoff.albedo_color = Color(0.2, 0.36, 0.4, 0.8)
	wstoff.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wstoff.roughness = 0.1
	wasser.material_override = wstoff
	add_child(wasser)
	for k in 2:
		var mitte := Vector3(-5.8 + k * 3.8, -0.35, 7.0 + k * 0.6)
		var netz := Findling.scheibe(1.3, 1.2, {"saat": 60 + k, "wasser_y": 0.37})
		_setze(netz, Findling.stoff(), Transform3D(Basis(), mitte), true, "Trittstein")
		_drahtzylinder(1.3, 1.2, mitte)
	# Deko-Brocken (gewölbt, nicht begehbar)
	for k in 3:
		var g := Vector3(2.2, 1.6, 1.8) * (0.7 + 0.35 * float(k))
		var netz := Findling.brocken(g, {"saat": 80 + k})
		_setze(netz, Findling.stoff(), Transform3D(Basis(Vector3.UP, float(k)),
				Vector3(-8.0 + k * 6.0, g.y * 0.5 - 0.2, -8.0)), true, "Brocken")
	_figur(Vector3(-3.4, 0.0, 3.0))
	_figur(Vector3(-2.6, 2.6, 0.3))

	_blick("findling_ueberblick", Vector3(1.0, 7.0, 17.0), Vector3(1.0, 1.0, 0.0), 62.0)
	_blick("findling_kante", Vector3(-4.0, 4.2, 5.0), Vector3(-2.0, 2.3, 0.0), 50.0)
	_blick("findling_platte", Vector3(4.0, 5.0, 12.0), Vector3(10.0, 0.8, 1.0), 55.0)
	_blick("findling_tritt", Vector3(-3.0, 3.2, 13.0), Vector3(-4.0, 0.2, 7.0), 50.0)


## Farne: klein, groß und Rahmenfarn auf Waldboden.
func _szene_farn() -> void:
	_waldboden(60.0)
	for k in 9:
		var netz := Farnwerk.klein(k + 1)
		_setze(netz, Farnwerk.stoff(Farben.LAUB), Transform3D(Basis(Vector3.UP, float(k)),
				Vector3(-3.0 + float(k % 3) * 1.1, 0.0, 1.5 + float(k / 3) * 0.9)), false, "Klein")
	for k in 3:
		var netz := Farnwerk.gross(k + 1)
		_setze(netz, Farnwerk.stoff(Farben.LAUB), Transform3D(Basis(Vector3.UP, float(k) * 2.0),
				Vector3(1.5 + float(k) * 3.2, 0.0, -1.0 - float(k) * 0.8)), false, "Gross")
	for k in 2:
		var netz := Farnwerk.rahmen(k + 1)
		_setze(netz, Farnwerk.stoff(Farben.LAUB), Transform3D(Basis(Vector3.UP, float(k) * 2.5),
				Vector3(-6.0 + float(k) * 13.0, 0.0, -4.0)), false, "Rahmen")
	_figur(Vector3(0.0, 0.0, 3.0))

	_blick("farn_spiel", Vector3(0.0, 5.0, 11.0), Vector3(0.5, 0.6, 0.0), 60.0)
	_blick("farn_nah", Vector3(-1.5, 1.3, 5.0), Vector3(-2.0, 0.4, 2.0), 55.0)
	_blick("farn_gross", Vector3(3.0, 2.2, 6.5), Vector3(4.0, 1.0, -2.0), 58.0)


## Alles zusammen: ein Stück Hallenwald mit Pfad, aus der Spielkamera
## (6 m hoch, 9,5 m hinter der Figur, Blick 6 m voraus) und von der Seite.
func _szene_wald() -> void:
	_waldboden(160.0)
	var pfad := MeshInstance3D.new()
	var streifen := PlaneMesh.new()
	streifen.size = Vector2(9.0, 140.0)
	pfad.mesh = streifen
	pfad.position = Vector3(0.0, 0.015, -50.0)
	pfad.material_override = Materialbibliothek.waldweg()
	add_child(pfad)

	var baeume: Array[Dictionary] = []
	for k in 6:
		baeume.append(Riesenstamm.baum({"hoehe": 15.0 + float(k % 3) * 1.5, "radius": 0.36 + 0.05 * float(k % 2),
				"variante": 2 if k % 2 == 0 else 0, "krone_radius": 3.6, "saat": 70 + k,
				"ast_start": 0.66}))
	var stoff_stamm := Riesenstamm.borkenstoff()
	var stoff_krone := Kronenwolke.stoff(Farben.LAUB_DUNKEL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for seite: float in [-1.0, 1.0]:
		for reihe in 3:
			var z := 6.0 - rng.randf_range(0.0, 4.0)
			while z > -110.0:
				var q := seite * (7.5 + float(reihe) * 5.5 + rng.randf_range(-1.0, 1.5))
				var b: Dictionary = baeume[rng.randi_range(0, baeume.size() - 1)]
				var trafo := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(q, 0.0, z))
				_setze(b["stamm"], stoff_stamm, trafo, true, "Stamm")
				_setze(b["krone"], stoff_krone, trafo, false, "Krone")
				z -= rng.randf_range(6.0, 9.5)
	var riese := Riesenstamm.netz({"hoehe": 34.0, "radius": 1.8, "brettwurzeln": 8,
			"pilze": 3, "efeu": 2, "saat": 12})
	_setze(riese, stoff_stamm, Transform3D(Basis(), Vector3(-10.5, 0.0, -32.0)), true, "Riese")
	_kranz_um(riese, Vector3(-10.5, 0.0, -32.0))
	var farne: Array[ArrayMesh] = [Farnwerk.klein(1), Farnwerk.klein(2), Farnwerk.gross(1),
			Farnwerk.rahmen(1)]
	var farnstoff := Farnwerk.stoff(Farben.LAUB)
	for k in 40:
		var seite := -1.0 if k % 2 == 0 else 1.0
		var z := 4.0 - float(k) * 2.4 + rng.randf_range(-1.0, 1.0)
		var q := seite * rng.randf_range(4.6, 7.0)
		var art := rng.randi_range(0, 2)
		_setze(farne[art], farnstoff, Transform3D(Basis(Vector3.UP, rng.randf() * TAU),
				Vector3(q, 0.0, z)), false, "Farn")
	_setze(farne[3], farnstoff, Transform3D(Basis(Vector3.UP, 1.0), Vector3(-5.8, 0.0, 1.5)),
			false, "Rahmenfarn")
	Findling.bauen(self, Vector3(1.6, 1.0, 1.4), Transform3D(Basis(Vector3.UP, 0.4),
			Vector3(5.2, 0.5, -8.0)), {"saat": 5})
	Findling.bauen(self, Vector3(2.4, 1.6, 2.0), Transform3D(Basis(Vector3.UP, -0.3),
			Vector3(-5.6, 0.8, -20.0)), {"saat": 6})
	var log_netz := Riesenstamm.liegend(0.4, 8.8, {"saat": 4})
	_setze(log_netz, stoff_stamm, Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)),
			Vector3(0.0, 0.4, -4.0)), true, "Mooslog")
	_figur(Vector3(0.0, 0.0, 4.0))

	_blick("wald_spiel", Vector3(0.0, 6.0, 13.5), Vector3(0.0, 1.0, -2.0), 60.0)
	_blick("wald_tief", Vector3(0.0, 6.0, -10.5), Vector3(0.0, 1.0, -26.0), 60.0)
	_blick("wald_seite", Vector3(14.0, 4.0, -26.0), Vector3(-6.0, 5.0, -32.0), 60.0)


## Talwald, wie man ihn vom Grat aus sieht: 8–12 m unter dem Weg ein Dach
## aus Kronen (drei Varianten, nah mit Karten), dahinter die Fernfassung
## bis 200 m, je Zelle zu einem Netz verschmolzen.
func _szene_tal() -> void:
	_waldboden(420.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var varianten: Array[Dictionary] = []
	for k in 6:
		varianten.append(Riesenstamm.baum({"hoehe": rng.randf_range(12.0, 16.0),
				"radius": rng.randf_range(0.32, 0.45), "variante": k % 3,
				"krone_radius": rng.randf_range(3.2, 4.4), "saat": 300 + k}))
	var stoff_stamm := Riesenstamm.borkenstoff()
	var toene: Array[Color] = [Farben.LAUB, Farben.LAUB_DUNKEL, Color(0.26, 0.5, 0.17),
			Color(0.2, 0.4, 0.2)]
	# Nah: 0–75 m vor der Kamera, einzelne Bäume
	for i in 110:
		var ort := Vector3(rng.randf_range(-40.0, 40.0), 0.0, rng.randf_range(-75.0, 0.0))
		var b: Dictionary = varianten[rng.randi_range(0, varianten.size() - 1)]
		var skala := rng.randf_range(0.85, 1.2)
		var trafo := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * skala), ort)
		_setze(b["stamm"], stoff_stamm, trafo, true, "Talstamm")
		_setze(b["krone"], Kronenwolke.stoff(toene[rng.randi_range(0, toene.size() - 1)]),
				trafo, false, "Talkrone")
	# Fern: je 25-m-Zelle ein verschmolzenes Netz aus flachen Kronen
	var fern: Array[ArrayMesh] = []
	for k in 4:
		fern.append(Kronenwolke.fern({"radius": 4.0, "saat": 500 + k}))
	for zx in range(-6, 6):
		for zz in range(3, 9):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var mitte := Vector3(float(zx) * 25.0 + 12.5, 0.0, -float(zz) * 25.0 - 12.5)
			for i in 12:
				var ort := mitte + Vector3(rng.randf_range(-12.5, 12.5), 0.0,
						rng.randf_range(-12.5, 12.5))
				var hoehe := rng.randf_range(10.0, 14.0)
				var skala := rng.randf_range(0.8, 1.3)
				st.append_from(fern[rng.randi_range(0, 3)], 0, Transform3D(
						Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * skala),
						ort - mitte + Vector3(0.0, hoehe, 0.0)))
			_setze(st.commit(), Kronenwolke.stoff(Farben.LAUB_DUNKEL), Transform3D(Basis(), mitte),
					false, "Fernzelle")
	_blick("tal_grat", Vector3(0.0, 26.0, 16.0), Vector3(0.0, 8.0, -30.0), 60.0)
	_blick("tal_weit", Vector3(-20.0, 30.0, 30.0), Vector3(10.0, 6.0, -90.0), 60.0)


## Größenprobe: Stamm in der Größenordnung des Weltenbaums (r 12 m), in
## beiden Projektionen des Borkenstoffs.
func _szene_welt() -> void:
	_waldboden(300.0)
	var o := {"hoehe": 40.0, "radius": 12.0, "radius_oben": 8.0, "rippen": 36,
			"rippen_tiefe": 0.05, "drehung": 0.3, "brettwurzeln": 8, "wurzel_reichweite": 14.0,
			"wurzel_hoehe": 16.0, "wurzel_dicke": 3.5, "pilze": 6, "efeu": 3,
			"leuchtpilze": 4, "ring_abstand": 4.0, "oben": "offen", "saat": 21}
	var netz := Riesenstamm.netz(o)
	_setze(netz, Riesenstamm.borkenstoff({"welt": true}), Transform3D(Basis(), Vector3.ZERO),
			true, "Weltenbaum")
	_kranz_um(netz, Vector3.ZERO)
	_figur(Vector3(8.0, 0.0, 26.0))
	_blick("welt_fern", Vector3(20.0, 14.0, 80.0), Vector3(0.0, 14.0, 0.0), 60.0)
	_blick("welt_fuss", Vector3(14.0, 5.0, 34.0), Vector3(0.0, 4.0, 10.0), 60.0)


# ---------------------------------------------------------------- Messung

## Dreieckszahlen gegen die Grenzen und die Findlingsprobe. Läuft headless.
func _messung() -> int:
	var fehler := 0
	print("=== Propschau-Messung: Holz und Stein ===")
	var staemme: Array = [
		["Hallenbaum-Stamm", Riesenstamm.netz({"hoehe": 16.0, "radius": 0.38, "aeste": 4, "saat": 5})],
		["Talriese (alles Beiwerk)", Riesenstamm.netz({"hoehe": 34.0, "radius": 1.8,
				"brettwurzeln": 8, "pilze": 3, "efeu": 2, "leuchtpilze": 2, "aeste": 5, "saat": 12})],
		["Rahmenbaum-Stamm", Riesenstamm.netz({"hoehe": 11.0, "radius": 0.5, "drehung": 1.8,
				"aeste": 5, "saat": 9})],
		["Stumpf", Riesenstamm.stumpf(0.7, 1.3)],
		["Liegend", Riesenstamm.liegend(0.4, 8.8)],
	]
	for eintrag: Array in staemme:
		fehler += _zaehle(eintrag[0], eintrag[1], GRENZE_STAMM)
	for saat in 3:
		fehler += _zaehle("Schlicht (3 Äste)", Riesenstamm.schlicht({"hoehe": 15.0 + saat * 4.0,
				"radius": 0.35, "aeste": 3, "saat": saat + 1}), GRENZE_SCHLICHT)
	var fernbaum := Riesenstamm.baum({"hoehe": 15.0, "radius": 0.35, "aeste": 3,
			"schlicht": true, "saat": 4})
	fehler += _zaehle("Schlicht: Stamm", fernbaum["stamm"], GRENZE_SCHLICHT)
	_zaehle("Schlicht: Krone (grob)", fernbaum["krone"], 0)
	for variante in 3:
		for r: float in [1.2, 3.0, 6.0]:
			fehler += _zaehle("Krone v%d r%.1f" % [variante, r], Kronenwolke.netz({"radius": r,
					"variante": variante, "saat": 7}), GRENZE_KRONE)
	fehler += _zaehle("Krone fern", Kronenwolke.fern({"radius": 4.0}), GRENZE_KRONE)
	var b := Riesenstamm.baum({"hoehe": 16.0, "radius": 0.4, "saat": 3})
	fehler += _zaehle("Baum: Krone an Ästen", b["krone"], GRENZE_KRONE)
	_zaehle("Farn klein", Farnwerk.klein(1), 0)
	_zaehle("Farn groß", Farnwerk.gross(1), 0)
	_zaehle("Rahmenfarn", Farnwerk.rahmen(1), 0)

	# Findlinge: Dreiecke und Oberkante
	var proben: Array = [Vector3(1.4, 0.9, 1.2), Vector3(3.5, 2.6, 2.4), Vector3(1.6, 3.0, 2.5),
			Vector3(4.75, 1.2, 8.0), Vector3(0.8, 0.5, 0.8), Vector3(9.0, 2.0, 5.0)]
	for i in proben.size():
		var g: Vector3 = proben[i]
		for saat in 3:
			var netz := Findling.netz(g, {"saat": saat + 1})
			if saat == 0:
				fehler += _zaehle("Findling %s" % str(g), netz, GRENZE_FINDLING)
			fehler += await _oberkante(netz, g, "Findling %s Saat %d" % [str(g), saat + 1])
	for saat in 2:
		var tritt := Findling.scheibe(1.3, 1.2, {"saat": saat + 1, "wasser_y": 0.37})
		if saat == 0:
			fehler += _zaehle("Trittstein", tritt, GRENZE_FINDLING)
		fehler += await _oberkante(tritt, Vector3(2.6, 1.2, 2.6), "Trittstein Saat %d" % (saat + 1),
				true)
	print("=== Propschau-Messung: %d Abweichungen ===" % fehler)
	return fehler


func _zaehle(bezeichnung: String, netz: Mesh, grenze: int) -> int:
	var n := _dreiecke(netz)
	if grenze > 0 and n > grenze:
		print("  FEHLER %-34s %6d Dreiecke (Grenze %d)" % [bezeichnung, n, grenze])
		return 1
	print("  ok     %-34s %6d Dreiecke%s" % [bezeichnung, n,
			"" if grenze <= 0 else " (Grenze %d)" % grenze])
	return 0


static func _dreiecke(netz: Mesh) -> int:
	if netz == null:
		return 0
	var summe := 0
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var indizes: Variant = arrays[Mesh.ARRAY_INDEX]
		if indizes is PackedInt32Array and (indizes as PackedInt32Array).size() > 0:
			summe += (indizes as PackedInt32Array).size() / 3
		else:
			summe += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return summe


## Misst per Strahl, wo die sichtbare Oberseite liegt, und vergleicht mit
## der Kastenoberkante (`groesse.y / 2`). Gemessen wird auf dem Plateau,
## das `Findling.plateau()` verspricht. Außerdem darf der Stein oberhalb
## des Bodens nirgends über den Kasten hinausragen.
func _oberkante(netz: ArrayMesh, groesse: Vector3, bezeichnung: String,
		rund: bool = false) -> int:
	var h := groesse * 0.5
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var flaechen := ConcavePolygonShape3D.new()
	flaechen.set_faces(netz.get_faces())
	form.shape = flaechen
	koerper.add_child(form)
	koerper.position = Vector3(0.0, 0.0, 400.0)
	add_child(koerper)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var raum := get_world_3d().direct_space_state
	var eben := Findling.plateau(groesse, {}, rund)
	var groesste := 0.0
	var treffer := 0
	var proben := 0
	const RASTER := 9
	for ix in RASTER:
		for iz in RASTER:
			var fx := lerpf(-1.0, 1.0, float(ix) / float(RASTER - 1))
			var fz := lerpf(-1.0, 1.0, float(iz) / float(RASTER - 1))
			var x := fx * eben.x
			var z := fz * eben.y
			# Nur auf dem Plateau: im selben Grundriss (Exponent 3,6 bzw. Kreis),
			# um die Kante nach innen versetzt.
			var exponent := 2.0 if rund else 3.6
			if pow(absf(fx), exponent) + pow(absf(fz), exponent) > 1.0:
				continue
			proben += 1
			var von := koerper.position + Vector3(x, h.y + 2.0, z)
			var bis := koerper.position + Vector3(x, -h.y, z)
			var frage := PhysicsRayQueryParameters3D.create(von, bis)
			var ergebnis := raum.intersect_ray(frage)
			if ergebnis.is_empty():
				groesste = maxf(groesste, 9.9)
				continue
			treffer += 1
			var y: float = (ergebnis["position"] as Vector3).y - koerper.position.y
			groesste = maxf(groesste, absf(y - h.y))
	koerper.queue_free()
	# Nichts ragt über den Kasten: über dem Boden bleibt alles innen, und
	# nichts liegt über der Oberkante.
	var ueber := 0.0
	var ecken := netz.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for p in ecken:
		ueber = maxf(ueber, p.y - h.y)
		if p.y > -h.y + 0.01:
			if rund:
				ueber = maxf(ueber, Vector2(p.x, p.z).length() - h.x)
			else:
				ueber = maxf(ueber, maxf(absf(p.x) - h.x, absf(p.z) - h.z))
	var gut := groesste <= GRENZE_OBERKANTE and ueber <= 0.005 and treffer == proben
	print("  %s %-38s Oberkante ±%.3f m (%d/%d Strahlen), Überstand %.3f m" % [
			"ok    " if gut else "FEHLER", bezeichnung, groesste, treffer, proben, ueber])
	return 0 if gut else 1


# ---------------------------------------------------------------- Bausteine

func _umgebung(hintergrund: Color, umgebungslicht: Color, staerke: float) -> void:
	var we := WorldEnvironment.new()
	var welt := Environment.new()
	welt.background_mode = Environment.BG_COLOR
	welt.background_color = hintergrund
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = umgebungslicht
	welt.ambient_light_energy = staerke
	we.environment = welt
	add_child(we)


## Licht und Umgebung wie in Level01.tscn (Stand der Neubauplanung): Himmel,
## Sonne 68° aus Süd-Südost mit zwei Schattenstufen bis 70 m, Gegen-,
## Himmels- und Bodenlicht, Tiefennebel ab 12 m, ACES.
func _waldlicht() -> void:
	var himmel := ShaderMaterial.new()
	himmel.shader = HIMMEL
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 101
	rauschen.frequency = 0.016
	rauschen.fractal_octaves = 5
	rauschen.fractal_gain = 0.55
	var wolken := NoiseTexture2D.new()
	wolken.width = 256
	wolken.height = 256
	wolken.seamless = true
	wolken.noise = rauschen
	var werte := {
		"zenit": Color(0.24, 0.46, 0.74), "horizont": Color(0.7, 0.8, 0.84),
		"dunst": Color(0.42, 0.52, 0.46), "boden": Color(0.17, 0.24, 0.19),
		"verlauf_kurve": 0.42, "dunst_hoehe": 0.07, "schein_farbe": Color(1.0, 0.74, 0.45),
		"schein_breite": 4.0, "schein_staerke": 0.5, "hof_staerke": 0.3,
		"scheibe_staerke": 0.0, "huegel_hoehe": 0.085, "wald_kante": 0.02,
		"wolken": wolken, "wolken_menge": 0.52, "wolken_weich": 0.2, "wolken_skala": 0.2,
		"wolken_deckung": 0.85,
	}
	for schluessel: String in werte:
		himmel.set_shader_parameter(schluessel, werte[schluessel])
	var sky := Sky.new()
	sky.sky_material = himmel
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	var welt := Environment.new()
	welt.background_mode = Environment.BG_SKY
	welt.sky = sky
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.4, 0.5, 0.7)
	welt.ambient_light_energy = 0.4
	welt.tonemap_mode = Environment.TONE_MAPPER_ACES
	welt.tonemap_exposure = 0.95
	welt.tonemap_white = 6.0
	welt.glow_enabled = true
	welt.glow_intensity = 0.6
	welt.glow_bloom = 0.0
	welt.glow_hdr_threshold = 1.0
	welt.glow_hdr_scale = 1.2
	welt.fog_enabled = true
	welt.fog_mode = Environment.FOG_MODE_DEPTH
	welt.fog_light_color = Color(0.42, 0.52, 0.46)
	welt.fog_light_energy = 1.0
	welt.fog_sun_scatter = 1.6
	welt.fog_density = 0.9
	welt.fog_sky_affect = 0.0
	welt.fog_depth_curve = 1.1
	welt.fog_depth_begin = 12.0
	welt.fog_depth_end = 140.0
	var we := WorldEnvironment.new()
	we.environment = welt
	add_child(we)

	var sonne := DirectionalLight3D.new()
	sonne.transform = Transform3D(Basis(Vector3(0.965926, 0.0, -0.258819),
			Vector3(-0.239973, 0.374607, -0.895591), Vector3(0.096955, 0.927184, 0.361842)),
			Vector3(0.0, 30.0, 0.0))
	sonne.light_color = Color(1.0, 0.93, 0.8)
	sonne.light_energy = 0.6
	sonne.light_specular = 0.2
	sonne.shadow_enabled = true
	sonne.shadow_bias = 0.04
	sonne.shadow_normal_bias = 1.5
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sonne.directional_shadow_max_distance = 70.0
	sonne.directional_shadow_split_1 = 0.25
	sonne.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(sonne)
	_licht(Basis(Vector3(-0.9848, -0.042, 0.1684), Vector3(0.0, 0.9703, 0.2419),
			Vector3(-0.1736, 0.2382, -0.9556)), Color(1.0, 0.82, 0.6), 0.14, 0.3, false)
	_licht(Basis(Vector3(-0.86603, -0.44147, 0.23474), Vector3(0.0, 0.46947, 0.88295),
			Vector3(-0.5, 0.76466, -0.40657)), Color(0.55, 0.68, 1.0), 0.42, 0.0, true)
	_licht(Basis(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.819152, 0.573576),
			Vector3(0.0, -0.573576, 0.819152)), Color(0.86, 0.66, 0.42), 0.12, 0.0, true)


func _licht(basis: Basis, farbe: Color, energie: float, glanz: float, nur_licht: bool) -> void:
	var licht := DirectionalLight3D.new()
	licht.transform = Transform3D(basis, Vector3(0.0, 30.0, 0.0))
	licht.light_color = farbe
	licht.light_energy = energie
	licht.light_specular = glanz
	if nur_licht:
		licht.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(licht)


func _sonne(drehung: Vector3, energie: float) -> void:
	var licht := DirectionalLight3D.new()
	licht.rotation = drehung
	licht.light_energy = energie
	add_child(licht)


func _boden(breite: float, farbe: Color) -> void:
	var mi := MeshInstance3D.new()
	var netz := PlaneMesh.new()
	netz.size = Vector2(breite, breite)
	mi.mesh = netz
	mi.material_override = Materialbibliothek.einfarbig(farbe)
	add_child(mi)


func _waldboden(breite: float) -> void:
	var mi := MeshInstance3D.new()
	var netz := PlaneMesh.new()
	netz.size = Vector2(breite, breite)
	mi.mesh = netz
	mi.material_override = Materialbibliothek.waldboden()
	add_child(mi)


func _wand(mitte: Vector3, groesse: Vector3, farbe: Color) -> void:
	var mi := MeshInstance3D.new()
	var netz := BoxMesh.new()
	netz.size = groesse
	mi.mesh = netz
	mi.position = mitte
	mi.material_override = Materialbibliothek.einfarbig(farbe)
	add_child(mi)


func _setze(netz: Mesh, stoff: Material, trafo: Transform3D, schatten: bool,
		bezeichnung: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	mi.material_override = stoff
	mi.transform = trafo
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _baum(optionen: Dictionary, ort: Vector3, bezeichnung: String) -> void:
	var b := Riesenstamm.baum(optionen)
	_setze(b["stamm"], Riesenstamm.borkenstoff(), Transform3D(Basis(), ort), true, bezeichnung)
	_setze(b["krone"], Kronenwolke.stoff(Farben.LAUB), Transform3D(Basis(), ort), false,
			bezeichnung + "_Krone")
	_kranz_um(b["stamm"], ort)
	print("  %-12s Stamm %5d  Krone %5d Dreiecke, Laub ab %.1f m" % [bezeichnung,
			_dreiecke(b["stamm"]), _dreiecke(b["krone"]), float(b["krone_unten"])])


func _kranz_um(netz: Mesh, ort: Vector3) -> void:
	var radien: PackedFloat32Array = netz.get_meta("fuss_radien", PackedFloat32Array())
	if radien.is_empty():
		return
	var breite := clampf(radien[0] * 0.8, 0.5, 6.0)
	_setze(Findling.kranz(radien, 0.02, breite, 0.65, clampf(radien[0] * 0.15, 0.1, 1.5)),
			Findling.kranzstoff(),
			Transform3D(Basis(), ort), false, "Kranz")


## Figur in Spielergröße (Kapsel 0,38 × 1,3 m + Füße) als Maßstab.
func _figur(fuss: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var kapsel := CapsuleMesh.new()
	kapsel.radius = 0.38
	kapsel.height = 1.42
	mi.mesh = kapsel
	mi.position = fuss + Vector3(0.0, 0.71, 0.0)
	mi.material_override = Materialbibliothek.einfarbig(Color(0.95, 0.5, 0.15))
	add_child(mi)


## Drahtgitter eines Kastens (Kollision) in Signalfarbe.
func _drahtkasten(groesse: Vector3, trafo: Transform3D) -> void:
	var h := groesse * 0.5
	var ecken: Array[Vector3] = []
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				ecken.append(trafo * Vector3(h.x * x, h.y * y, h.z * z))
	var kanten := [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7],
			[0, 4], [1, 5], [2, 6], [3, 7]]
	for k: Array in kanten:
		_draht(ecken[k[0]], ecken[k[1]])


func _drahtzylinder(radius: float, hoehe: float, mitte: Vector3) -> void:
	const N := 24
	for y: float in [-0.5, 0.5]:
		for k in N:
			var a := TAU * float(k) / float(N)
			var b := TAU * float(k + 1) / float(N)
			_draht(mitte + Vector3(cos(a) * radius, y * hoehe, sin(a) * radius),
					mitte + Vector3(cos(b) * radius, y * hoehe, sin(b) * radius))


func _draht(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var kasten := BoxMesh.new()
	kasten.size = Vector3(0.025, 0.025, a.distance_to(b))
	mi.mesh = kasten
	mi.transform = PropWerkzeug.ausrichten_z(a, b)
	var stoff := StandardMaterial3D.new()
	stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stoff.albedo_color = Color(1.0, 0.2, 0.6)
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _blick(bezeichnung: String, ort: Vector3, ziel: Vector3, sichtfeld: float) -> void:
	_blicke.append([bezeichnung, ort, ziel, sichtfeld])


static func rng_wert(k: int, von: float, bis: float) -> float:
	return lerpf(von, bis, fmod(float(k) * 0.618034, 1.0))


func _kamera(ort: Vector3, ziel: Vector3, sichtfeld: float) -> Camera3D:
	var kamera := Camera3D.new()
	# Die Blickwinkel versetzen die Kamera im Bildtakt (Bildtakt-Regel).
	kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kamera.fov = sichtfeld
	kamera.position = ort
	kamera.far = 400.0
	add_child(kamera)
	# Erst einhängen, dann ausrichten: `look_at` braucht den Knoten im Baum.
	kamera.look_at(ziel, Vector3.UP)
	kamera.current = true
	return kamera


# ---------------------------------------------------------------- Aufnahme

func _fotografieren(ziel: String, art: String, bilder: int, pause: float) -> void:
	DirAccess.make_dir_recursive_absolute(ziel)
	# Ein paar Bilder Vorlauf: Shader werden erst beim ersten Zeichnen gebaut.
	for f in 20:
		await get_tree().process_frame
	for nummer in bilder:
		await RenderingServer.frame_post_draw
		var pfad := "%s/%s_%d.png" % [ziel, art, nummer]
		get_viewport().get_texture().get_image().save_png(pfad)
		print("Bild: %s" % pfad)
		if nummer < bilder - 1:
			await get_tree().create_timer(pause).timeout


## Ein Bild je Blickwinkel, mit Zeichenaufrufen und Primitiven.
func _blicke_fotografieren(ziel: String, art: String) -> void:
	DirAccess.make_dir_recursive_absolute(ziel)
	var nur := OS.get_environment("PROPSCHAU_NUR").split(",", false)
	var kamera := _kamera(Vector3(0.0, 5.0, 20.0), Vector3.ZERO, 60.0)
	var erstes := true
	for blick: Array in _blicke:
		var name_: String = blick[0]
		if not nur.is_empty() and not nur.has(name_):
			continue
		kamera.fov = blick[3]
		kamera.position = blick[1]
		kamera.look_at(blick[2], Vector3.UP)
		# Vorlauf: Shader werden erst beim ersten Zeichnen gebaut.
		for f in (24 if erstes else 6):
			await get_tree().process_frame
		erstes = false
		await RenderingServer.frame_post_draw
		var pfad := "%s/%s.png" % [ziel, name_]
		get_viewport().get_texture().get_image().save_png(pfad)
		var draw := RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prim := RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		print("Bild: %s  draw %d  prim %dk" % [pfad, draw, prim / 1000])
