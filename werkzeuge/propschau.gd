extends Node3D
## Baut EIN Bewegungs-Prop isoliert auf und fotografiert es mehrfach.
##
## Bewegung sieht man auf einem einzelnen Bild nicht. Deshalb entstehen hier
## mehrere Aufnahmen im Abstand von `PROPSCHAU_PAUSE` Sekunden: nebeneinander
## gelegt zeigen sie, ob sich überhaupt etwas rührt, wie weit es sich bewegt
## und ob beim Rücksprung einer Bahn etwas sichtbar umspringt.
##
## Aufruf (siehe werkzeuge/propschau.sh):
##   PROPSCHAU=staub godot --path . res://werkzeuge/Propschau.tscn
##
## PROPSCHAU        staub | laub | voegel
## PROPSCHAU_ZIEL   Zielverzeichnis (Vorgabe /tmp/propschau)
## PROPSCHAU_BILDER Anzahl der Aufnahmen (Vorgabe 3)
## PROPSCHAU_PAUSE  Sekunden zwischen den Aufnahmen (Vorgabe 1.2)

const GRAS := preload("res://scenes/props/Gras.tscn")


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


func _wand(mitte: Vector3, groesse: Vector3, farbe: Color) -> void:
	var mi := MeshInstance3D.new()
	var netz := BoxMesh.new()
	netz.size = groesse
	mi.mesh = netz
	mi.position = mitte
	mi.material_override = Materialbibliothek.einfarbig(farbe)
	add_child(mi)


func _kamera(ort: Vector3, ziel: Vector3, sichtfeld: float) -> void:
	var kamera := Camera3D.new()
	kamera.fov = sichtfeld
	kamera.position = ort
	kamera.far = 400.0
	add_child(kamera)
	# Erst einhängen, dann ausrichten: `look_at` braucht den Knoten im Baum.
	kamera.look_at(ziel, Vector3.UP)
	kamera.current = true


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
