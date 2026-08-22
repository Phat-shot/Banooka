extends Node
## Rendert Bilder eines Levels und legt sie als PNG ab.
##
## Aufruf über werkzeuge/foto.sh – dort stehen auch die Parameter.
## Godot kann im Headless-Modus nicht zeichnen; das Skript braucht daher
## einen echten Bildschirm (X11/Wayland). foto.sh legt das Fenster
## außerhalb des sichtbaren Bereichs ab.
##
## Umgebungsvariablen:
##   FOTO_ZIEL     Ausgabeverzeichnis (Pflicht)
##   FOTO_LEVEL    Szene, Vorgabe res://scenes/levels/Level01.tscn
##   FOTO_MODUS    "verfolger" (Spielkamera) oder "seite" (Blick quer auf den Weg)
##   FOTO_STELLEN  Strecken in Metern, mit Komma getrennt

const STANDARD_STELLEN := "4,24,50,60,86,112,136,162,192,216,233"

var _level: Node3D
var _spieler: Node3D
var _kamera: Camera3D


func _ready() -> void:
	var pfad := OS.get_environment("FOTO_LEVEL")
	if pfad.is_empty():
		pfad = "res://scenes/levels/Level01.tscn"
	_level = load(pfad).instantiate()
	add_child(_level)
	await get_tree().process_frame
	await get_tree().process_frame

	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	if _spieler != null and "gesperrt" in _spieler:
		_spieler.gesperrt = true

	var modus := OS.get_environment("FOTO_MODUS")
	if modus == "seite":
		_eigene_kamera()
	else:
		for kind in _level.get_children():
			if kind is Camera3D:
				_kamera = kind

	var stellen := OS.get_environment("FOTO_STELLEN")
	if stellen.is_empty():
		stellen = STANDARD_STELLEN
	await _fotografiere(stellen.split(","), modus)
	print("FERTIG")
	get_tree().quit()


func _eigene_kamera() -> void:
	for kind in _level.get_children():
		if kind is Camera3D:
			kind.queue_free()
	_kamera = Camera3D.new()
	_kamera.fov = 55.0
	_kamera.far = 400.0
	add_child(_kamera)
	_kamera.current = true


func _fotografiere(stellen: PackedStringArray, modus: String) -> void:
	var ziel := OS.get_environment("FOTO_ZIEL")
	var verlauf = _level.get("verlauf")
	for i in stellen.size():
		var s := float(stellen[i].strip_edges())
		var mitte: Vector3 = LevelWerkzeuge.punkt(verlauf, s, 0.0, 0.0)
		if _spieler != null:
			_spieler.global_position = mitte + Vector3.UP * 1.0
		if modus == "seite" and _kamera != null:
			var quer: Vector3 = LevelWerkzeuge.richtung(verlauf, s).cross(Vector3.UP)
			_kamera.global_position = mitte + quer * 34.0 + Vector3.UP * 8.0
			_kamera.look_at(mitte + Vector3.DOWN * 3.0, Vector3.UP)
		for f in 24:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name := "%s/%s_%02d_%03dm.png" % [ziel,
				"seite" if modus == "seite" else "weg", i, int(s)]
		var fehler := get_viewport().get_texture().get_image().save_png(name)
		print("  %s  %s" % ["ok " if fehler == OK else "FEHLER", name])
