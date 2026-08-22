extends Node
## Rendert Bilder einer Szene und legt sie als PNG ab.
##
## Aufruf über werkzeuge/foto.sh – dort stehen auch die Parameter.
## Godot kann im Headless-Modus nicht zeichnen; das Skript braucht daher
## einen echten Bildschirm (X11/Wayland). foto.sh legt das Fenster
## außerhalb des sichtbaren Bereichs ab.
##
## Umgebungsvariablen:
##   FOTO_ZIEL     Ausgabeverzeichnis (Pflicht)
##   FOTO_LEVEL    Szene, Vorgabe res://scenes/levels/Level01.tscn
##   FOTO_MODUS    "verfolger" – Spielkamera, Spieler wird am Verlauf entlanggesetzt
##                 "seite"     – Blick quer auf den Weg
##                 "orbit"     – Kamera umkreist die Szene (für Räume und Menüs)
##   FOTO_STELLEN  verfolger/seite: Strecken in Metern, mit Komma getrennt
##                 orbit: Winkel in Grad
##   FOTO_WARTEN   Bilder, die vor jeder Aufnahme abgewartet werden
##                 (Vorgabe 24) – für Einblend-Animationen hochsetzen
##   FOTO_RADIUS   nur orbit: Abstand zur Mitte (Vorgabe 26)
##   FOTO_HOEHE    nur orbit: Höhe über der Mitte (Vorgabe 14)

const STANDARD_STELLEN := "4,24,50,60,86,112,136,162,192,216,233"
const STANDARD_WINKEL := "0,72,144,216,288"

var _szene: Node
var _spieler: Node3D
var _kamera: Camera3D
var _verlauf: Variant = null


func _ready() -> void:
	var pfad := OS.get_environment("FOTO_LEVEL")
	if pfad.is_empty():
		pfad = "res://scenes/levels/Level01.tscn"
	_szene = load(pfad).instantiate()
	add_child(_szene)
	await get_tree().process_frame
	await get_tree().process_frame

	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	if _spieler != null and "gesperrt" in _spieler:
		_spieler.gesperrt = true
	if _szene.has_method("get") and _szene is Node3D:
		_verlauf = _szene.get("verlauf")

	var modus := OS.get_environment("FOTO_MODUS")
	if modus.is_empty():
		modus = "verfolger"
	# Ohne Korridorverlauf ergibt "verfolger" keinen Sinn – dann umkreisen.
	if _verlauf == null and modus != "orbit" and _szene is Node3D:
		modus = "orbit"

	if modus == "seite" or modus == "orbit":
		_eigene_kamera()
	else:
		_kamera = _finde_kamera(_szene)

	var stellen := OS.get_environment("FOTO_STELLEN")
	if stellen.is_empty():
		stellen = STANDARD_WINKEL if modus == "orbit" else STANDARD_STELLEN
	await _fotografiere(stellen.split(","), modus)
	print("FERTIG")
	get_tree().quit()


func _finde_kamera(wurzel: Node) -> Camera3D:
	for kind in wurzel.get_children():
		if kind is Camera3D:
			return kind
	return null


func _eigene_kamera() -> void:
	var vorhanden := _finde_kamera(_szene)
	if vorhanden != null:
		vorhanden.queue_free()
	_kamera = Camera3D.new()
	_kamera.fov = 55.0
	_kamera.far = 400.0
	add_child(_kamera)
	_kamera.current = true


func _fotografiere(stellen: PackedStringArray, modus: String) -> void:
	var ziel := OS.get_environment("FOTO_ZIEL")
	var radius := float(OS.get_environment("FOTO_RADIUS")) if not OS.get_environment("FOTO_RADIUS").is_empty() else 26.0
	var hoehe := float(OS.get_environment("FOTO_HOEHE")) if not OS.get_environment("FOTO_HOEHE").is_empty() else 14.0

	for i in stellen.size():
		var wert := float(stellen[i].strip_edges())

		if modus == "orbit":
			var winkel := deg_to_rad(wert)
			var mitte := Vector3.ZERO
			if _spieler != null:
				mitte = Vector3(0.0, _spieler.global_position.y, 0.0)
			_kamera.global_position = mitte + Vector3(
					sin(winkel) * radius, hoehe, cos(winkel) * radius)
			_kamera.look_at(mitte + Vector3.UP * 1.5, Vector3.UP)
		elif _verlauf != null:
			var mitte: Vector3 = LevelWerkzeuge.punkt(_verlauf, wert, 0.0, 0.0)
			if _spieler != null:
				_spieler.global_position = mitte + Vector3.UP * 1.0
			if modus == "seite" and _kamera != null:
				var quer: Vector3 = LevelWerkzeuge.richtung(_verlauf, wert).cross(Vector3.UP)
				_kamera.global_position = mitte + quer * 34.0 + Vector3.UP * 8.0
				_kamera.look_at(mitte + Vector3.DOWN * 3.0, Vector3.UP)

		var warten := 24
		if not OS.get_environment("FOTO_WARTEN").is_empty():
			warten = int(OS.get_environment("FOTO_WARTEN"))
		for f in warten:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name := "%s/%s_%02d_%03d.png" % [ziel, modus, i, int(wert)]
		var fehler := get_viewport().get_texture().get_image().save_png(name)
		print("  %s  %s" % ["ok " if fehler == OK else "FEHLER", name])
