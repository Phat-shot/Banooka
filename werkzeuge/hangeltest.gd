extends Node3D
## Prüft das Hangeln am Testaufbau: Boden, Lücke, Gitter darüber.
##
## Am Standbild ist keine der Fragen zu beantworten, auf die es ankommt:
## Greift die Figur beim Sprung zu? Trägt das Gitter sie wirklich, statt
## sie fallen zu lassen? Kommt sie mit beiden Tasten wieder herunter? Und
## vor allem die zwei Fallstricke aus der Spezifikation:
##
##   * `_fall_rest` wird beim Hangeln nie abgebaut, weil der
##     Schwerkraft-Block übersprungen ist. Bliebe es stehen, zerbräche die
##     Figur für immer jede Kiste im Vorbeihangeln.
##   * Ohne Sperre nach dem Loslassen greift sie im nächsten Bild sofort
##     wieder zu – sie fällt ja mitten durch die eigene Fangzone.
##
##   godot --headless --path <Kopie> res://werkzeuge/Hangeltest.tscn

## Leertaste. Der Sprung muss über ein echtes Tastenereignis laufen, nicht
## über `InputHub.touch_sprung()`: Dieses setzt bei jedem Aufruf das
## "neu gedrückt"-Merkmal, wiederholtes Aufrufen ist also wiederholtes
## DRÜCKEN und nicht Halten – die Figur hängt sich ein und springt im
## selben Moment wieder ab. Gehalten werden muss die Taste trotzdem, sonst
## kappt der Jump-Cut den Sprung auf 0,40 m.
const KEY_SPACE := 32
const KEY_SHIFT := 4194325

const GITTER_HOEHE := 3.2
const GITTER_LAENGE := 10.0

var _spieler: Spieler
var _gitter: Hangelgitter
var _fehler := 0


func _ready() -> void:
	_boden()
	_licht()
	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 4.0, 12.0)
	add_child(kamera)
	kamera.current = true

	_gitter = Hangelgitter.new()
	_gitter.laenge = GITTER_LAENGE
	_gitter.breite = 2.0
	_gitter.hoehe = GITTER_HOEHE
	add_child(_gitter)
	_gitter.global_position = Vector3(0.0, 0.0, 0.0)

	_spieler = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_spieler)
	_spieler.global_position = Vector3(0.0, 0.4, 4.5)
	for i in 40:
		await get_tree().physics_frame

	print("=== Hangeltest ===")
	print("  Gitter: Unterkante %.2f m, Hangelhöhe %.2f m"
			% [_gitter.unterkante(), _gitter.hangelhoehe()])

	await _darunter_durchlaufen()
	await _hinaufspringen()
	await _entlanghangeln()
	await _bild_machen()
	await _abspringen()
	await _wieder_einhaengen()
	await _loslassen()

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


## Wer darunter durchläuft, darf NICHT eingehängt werden.
func _darunter_durchlaufen() -> void:
	_spieler.global_position = Vector3(0.0, 0.4, 4.0)
	for i in 60:
		InputHub.touch_bewegung = Vector2(0.0, -1.0)
		await get_tree().physics_frame
	InputHub.touch_bewegung = Vector2.ZERO
	_melden("laeuft darunter durch", _spieler.hangelgitter == null,
			"haengt, obwohl niemand gesprungen ist")


## Ein Sprung von unten muss greifen.
func _hinaufspringen() -> void:
	_spieler.global_position = Vector3(0.0, 0.4, 0.0)
	_spieler.velocity = Vector3.ZERO
	for i in 12:
		await get_tree().physics_frame
	# Taste HALTEN, nicht antippen: Ein losgelassener Sprung wird durch den
	# Jump-Cut auf JUMP_V * 0.45 gekappt und trägt dann nur 0,40 m statt
	# 1,96 m. Das Gitter hängt außerhalb dieser Reichweite – so gehört es
	# sich auch, aber der Test muss davon wissen.
	var ergebnis: Dictionary = await _sprung_bis_gitter()
	print("      (Scheitel %.2f m, Fangzone beruehrt: %s)"
			% [float(ergebnis["scheitel"]), str(ergebnis["beruehrt"])])
	var haengt := _spieler.hangelgitter != null
	_melden("springt hinauf", haengt, "greift nicht zu")
	if not haengt:
		return
	var soll := _gitter.hangelhoehe()
	_melden("haengt auf der richtigen Hoehe",
			absf(_spieler.global_position.y - soll) < 0.05,
			"y=%.2f statt %.2f" % [_spieler.global_position.y, soll])
	# Fallstrick 1: Das Fall-Gedächtnis muss beim Einhängen weg sein.
	_melden("Fall-Gedaechtnis geloescht",
			(int(_spieler.angriffe()) & Angriff.FALLEN) == 0,
			"zaehlt weiter als Treffer von oben")


## Hangeln längs des Gitters: die Figur muss sich bewegen und oben bleiben.
func _entlanghangeln() -> void:
	if _spieler.hangelgitter == null:
		return
	var start := _spieler.global_position
	var tiefste := INF
	for i in 60:
		InputHub.touch_bewegung = Vector2(0.0, -1.0)
		await get_tree().physics_frame
		tiefste = minf(tiefste, _spieler.global_position.y)
	InputHub.touch_bewegung = Vector2.ZERO
	var weg := _spieler.global_position.distance_to(start)
	_melden("hangelt vorwaerts", weg > 1.5,
			"nur %.2f m in 1 s zurueckgelegt" % weg)
	_melden("bleibt dabei oben", tiefste > _gitter.hangelhoehe() - 0.1,
			"sackt auf %.2f m ab" % tiefste)
	print("      (%.2f m in 60 Bildern, Solltempo %.1f m/s)"
			% [weg, Spieler.HANGEL_TEMPO])


## Ein Bild von der hängenden Figur – aber nur, wenn eines verlangt wird.
##
## Godot zeichnet im Headless-Modus nicht; über `werkzeuge/lauf.sh` bleibt
## das hier still. Mit einem echten Fenster (siehe hangelbild.sh) entsteht
## der Beweis, dass es auch aussieht wie gedacht und nicht nur rechnet.
func _bild_machen() -> void:
	var ziel := OS.get_environment("HANGEL_BILD")
	if ziel.is_empty() or _spieler.hangelgitter == null:
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera != null:
		kamera.global_position = _spieler.global_position \
				+ Vector3(5.5, 1.2, 4.5)
		kamera.look_at(_spieler.global_position + Vector3.UP * 0.6, Vector3.UP)
	for f in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ziel.get_base_dir())
	get_viewport().get_texture().get_image().save_png(ziel)
	print("      (Bild: %s)" % ziel)


## Sprungtaste: Absprung nach oben und vorn.
func _abspringen() -> void:
	if _spieler.hangelgitter == null:
		return
	var start := _spieler.global_position.y
	_sprungtaste(true)
	# Zwei Bilder: Ein über `parse_input_event` eingespeister Tastendruck
	# wird erst im nächsten Eingabedurchlauf zu "gerade gedrückt".
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Sofort prüfen, nicht erst in zwanzig Bildern: Nach 0,3 s Sperre hängt
	# sich die Figur ganz regelgerecht wieder ein, und der späte Blick
	# meldete dann fälschlich "haengt noch".
	_melden("springt ab", _spieler.hangelgitter == null, "haengt noch")
	# Taste HALTEN – sonst kappt der Jump-Cut den Absprung auf 0,40 m.
	var hoechste := start
	for i in 20:
		await get_tree().physics_frame
		hoechste = maxf(hoechste, _spieler.global_position.y)
	_sprungtaste(false)
	_melden("Absprung traegt nach oben", hoechste > start + 1.2,
			"kommt nur %.2f m hoch" % (hoechste - start))
	print("      (von %.2f m auf %.2f m, Sollhoehe +1,96 m)"
			% [start, hoechste])


## Nach dem Absprung wieder einhängen, um das Loslassen zu prüfen.
func _wieder_einhaengen() -> void:
	_spieler.global_position = Vector3(0.0, 0.4, 0.0)
	_spieler.velocity = Vector3.ZERO
	for i in 30:
		await get_tree().physics_frame
	await _sprung_bis_gitter()
	_melden("haengt wieder", _spieler.hangelgitter != null, "greift nicht zu")


## Slide-Taste: loslassen und senkrecht fallen – und NICHT sofort wieder
## zugreifen. Das ist Fallstrick 2.
func _loslassen() -> void:
	if _spieler.hangelgitter == null:
		return
	var hoehe_vorher := _spieler.global_position.y
	_taste(KEY_SHIFT, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_taste(KEY_SHIFT, false)
	var wieder_gehaengt := false
	for i in 40:
		await get_tree().physics_frame
		if _spieler.hangelgitter != null:
			wieder_gehaengt = true
			break
	_melden("laesst los", not wieder_gehaengt,
			"greift sofort wieder zu – Sperre fehlt")
	_melden("faellt dabei", _spieler.global_position.y < hoehe_vorher - 0.5,
			"bleibt auf %.2f m" % _spieler.global_position.y)


## Drückt oder löst eine Taste als echtes Tastenereignis.
##
## `InputHub.touch_*()` taugt dafür NICHT: Dessen "neu gedrückt"-Merkmale
## werden in `InputHub._physics_process()` gelöscht, und als Autoload läuft
## das VOR dem Spieler. Ein von außen gesetzter Tastendruck kommt also nie
## an. Nur die gehaltenen Merkmale überleben – deshalb funktioniert der
## Kriechtest mit `touch_slide()`, ein Absprung aber nicht.
func _taste(code: int, gedrueckt: bool) -> void:
	var ereignis := InputEventKey.new()
	ereignis.physical_keycode = code
	ereignis.pressed = gedrueckt
	# Die Slide-Taste ist in der Eingabekarte auf die LINKE Umschalttaste
	# gelegt (location 1). Ohne Seitenangabe passt das Ereignis nicht.
	ereignis.location = KEY_LOCATION_LEFT
	Input.parse_input_event(ereignis)


func _sprungtaste(gedrueckt: bool) -> void:
	_taste(KEY_SPACE, gedrueckt)


## Springt mit gehaltener Taste und wartet auf das Einhängen.
func _sprung_bis_gitter() -> Dictionary:
	var scheitel := 0.0
	var beruehrt := false
	_sprungtaste(true)
	for i in 60:
		await get_tree().physics_frame
		scheitel = maxf(scheitel, _spieler.global_position.y)
		beruehrt = beruehrt or _gitter.in_reichweite(_spieler)
		# Nach dem Steigen loslassen, damit der Griff ans Gitter nicht
		# sofort wieder als Absprung gelesen wird.
		if i == 16:
			_sprungtaste(false)
		if _spieler.hangelgitter != null:
			break
	_sprungtaste(false)
	return {"scheitel": scheitel, "beruehrt": beruehrt}


func _melden(was: String, gut: bool, warum: String) -> void:
	if not gut:
		_fehler += 1
	print("  %-28s %s%s" % [was, "ja" if gut else "NEIN",
			"" if gut else "   <-- " + warum])


## Sonne und Umgebung. Ohne beides ist das Bild eine schwarze Silhouette –
## als Formnachweis brauchbar, zum Beurteilen der Haltung nicht.
func _licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(35.0), 0.0)
	sonne.light_energy = 1.2
	add_child(sonne)
	var umgebung := WorldEnvironment.new()
	var welt := Environment.new()
	welt.background_mode = Environment.BG_COLOR
	welt.background_color = Color(0.52, 0.62, 0.72)
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.62, 0.68, 0.74)
	welt.ambient_light_energy = 0.9
	umgebung.environment = welt
	add_child(umgebung)


func _boden() -> void:
	# Durchgehender Boden, KEINE Lücke unter dem Gitter. Das war der erste
	# Entwurf und war falsch: In der Lücke fiel die Figur, statt springen
	# zu können. Nötig ist die Lücke auch nicht – hängend schweben die
	# Sohlen auf 1,65 m, `is_on_floor()` bleibt also falsch. Genau dafür
	# erzwingt das Prop seine MINDESTHOEHE von 2,40 m.
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(14.0, 1.0, 30.0)
	form.shape = kasten
	form.position = Vector3(0.0, -0.5, 0.0)
	koerper.add_child(form)
	add_child(koerper)
