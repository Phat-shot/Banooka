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
##                 "nah"       – dicht an der Figur, für Modelle und Effekte
##   FOTO_STELLEN  verfolger/seite: Strecken in Metern, mit Komma getrennt
##                 orbit: Winkel in Grad
##   FOTO_WARTEN   Bilder, die vor jeder Aufnahme abgewartet werden
##                 (Vorgabe 24) – für Einblend-Animationen hochsetzen
##   FOTO_RADIUS   nur orbit: Abstand zur Mitte (Vorgabe 26)
##   FOTO_HOEHE    nur orbit: Höhe über der Mitte (Vorgabe 14)
##   FOTO_ASSETS   0 = mitgelieferte Naturmodelle aus, prozedural bauen
##   FOTO_STATUS   1 = Statustafel aufgeklappt zeigen
##   FOTO_SEITLICH seitlicher Versatz der Figur vom Wegmittelpunkt in Metern
##                 (nur verfolger/seite/nah) – zeigt, wie stark die Kamera
##                 seitliche Bewegungen mitnimmt
##   FOTO_SEITENFAKTOR  überschreibt `seiten_faktor` der Korridorkamera

const STANDARD_STELLEN := "4,24,50,60,86,112,136,162,192,216,233"
const STANDARD_WINKEL := "0,72,144,216,288"

var _szene: Node
var _spieler: Node3D
var _kamera: Camera3D
var _verlauf: Variant = null


func _ready() -> void:
	# Zum Vergleichen: FOTO_ASSETS=0 zeigt die prozeduralen Props.
	if OS.get_environment("FOTO_ASSETS") == "0":
		Einstellungen.fremde_modelle = false
	var pfad := OS.get_environment("FOTO_LEVEL")
	if pfad.is_empty():
		pfad = "res://scenes/levels/Level01.tscn"
	# Dem Spielfluss sagen, welches Level läuft. Sonst hält sich das Spiel
	# für den Portalraum – die Statustafel zeigt dann den falschen Ort und
	# blendet "Level verlassen" aus.
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	if nummer.is_valid_int():
		Spielfluss.aktuelles_level = int(nummer)

	_szene = load(pfad).instantiate()
	add_child(_szene)
	await get_tree().process_frame
	await get_tree().process_frame
	# Auf den fertigen Levelaufbau warten. Er läuft über viele Bilder; wer
	# vorher fotografiert, erwischt eine halbe Szene – und vor allem hängt
	# die Verfolgerkamera dann noch nicht am Spieler, sodass JEDES Bild die
	# Startstelle zeigt, egal welche Strecke angefordert wurde.
	var fertig := [false]
	if _szene.has_signal("aufbau_fertig"):
		_szene.aufbau_fertig.connect(func() -> void: fertig[0] = true)
		var wartebilder := 0
		# Mit Zähler statt blankem `await`: Ist der Aufbau schon durch,
		# bevor wir lauschen, wartete das Signal ewig – der Lauf hing dann
		# bis zum Zeitablauf und lieferte kein einziges Bild.
		while not fertig[0] and wartebilder < 900:
			wartebilder += 1
			await get_tree().process_frame
		if not fertig[0]:
			print("HINWEIS: Aufbau meldete sich nicht, es wird trotzdem fotografiert")
	for f in 5:
		await get_tree().process_frame

	# Statustafel aufklappen, um sie im Bild zu prüfen. Sie hält den Baum
	# an – deshalb erst nach dem Aufbau und mit PROCESS_MODE_ALWAYS am
	# Fotoknoten, sonst käme dieses Skript nicht mehr weiter.
	if OS.get_environment("FOTO_STATUS") == "1":
		process_mode = Node.PROCESS_MODE_ALWAYS
		var tafel := _finde_statustafel(_szene)
		if tafel == null:
			print("HINWEIS: keine Statustafel gefunden")
		else:
			tafel.setzen(true)

	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	if _spieler != null:
		if "gesperrt" in _spieler:
			_spieler.gesperrt = true
		# Vollständig stilllegen. `gesperrt` allein reicht nicht: Die Figur
		# fällt weiter und löst Gefahren aus. Beim Fotografieren wird sie an
		# beliebige Stellen gesetzt – im Stachelfeld bei 106 m starb sie
		# sofort und landete wieder am Checkpoint, sodass JEDES Bild die
		# Startstelle zeigte, egal welche Strecke angefordert war.
		_spieler.set_physics_process(false)
		var koerper := _spieler as CollisionObject3D
		if koerper != null:
			koerper.collision_layer = 0
			koerper.collision_mask = 0
	# Zum Prüfen der Schutzmasken: FOTO_SCHUTZ=3 gibt drei Ladungen.
	if not OS.get_environment("FOTO_SCHUTZ").is_empty():
		GameState.schutz = int(OS.get_environment("FOTO_SCHUTZ"))
		GameState.schutz_geaendert.emit(GameState.schutz)
	if _szene.has_method("get") and _szene is Node3D:
		_verlauf = _szene.get("verlauf")

	var modus := OS.get_environment("FOTO_MODUS")
	if modus.is_empty():
		modus = "verfolger"
	# Ohne Korridorverlauf ergibt "verfolger" keinen Sinn – dann umkreisen.
	if _verlauf == null and modus != "orbit" and _szene is Node3D:
		modus = "orbit"

	if modus == "seite" or modus == "orbit" or modus == "nah":
		_eigene_kamera()
	else:
		_kamera = _finde_kamera(_szene)
		if _kamera != null and "seiten_faktor" in _kamera \
				and not OS.get_environment("FOTO_SEITENFAKTOR").is_empty():
			_kamera.set("seiten_faktor",
					float(OS.get_environment("FOTO_SEITENFAKTOR")))

	var stellen := OS.get_environment("FOTO_STELLEN")
	if stellen.is_empty():
		stellen = STANDARD_WINKEL if modus == "orbit" else STANDARD_STELLEN
	await _fotografiere(stellen.split(","), modus)
	print("FERTIG")
	get_tree().quit()


func _finde_statustafel(wurzel: Node) -> Statustafel:
	for kind in wurzel.get_children():
		if kind is Statustafel:
			return kind
		var treffer := _finde_statustafel(kind)
		if treffer != null:
			return treffer
	return null


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
			var quer_versatz := 0.0
			if not OS.get_environment("FOTO_SEITLICH").is_empty():
				quer_versatz = float(OS.get_environment("FOTO_SEITLICH"))
			var mitte: Vector3 = LevelWerkzeuge.punkt(_verlauf, wert, quer_versatz, 0.0)
			if _spieler != null:
				_spieler.global_position = mitte + Vector3.UP * 1.0
				# Die Verfolgerkamera zieht dem versetzten Spieler nicht von
				# allein nach: Ohne das zeigt JEDES Bild die Startstelle,
				# egal welche Strecke angefordert wurde.
				if modus == "verfolger" and _kamera != null \
						and _kamera.has_method("sofort_ausrichten"):
					_kamera.call("sofort_ausrichten")
			if modus == "nah" and _kamera != null:
				var vor: Vector3 = LevelWerkzeuge.richtung(_verlauf, wert)
				_kamera.global_position = mitte + vor.cross(Vector3.UP) * 3.2 \
						+ Vector3.UP * 2.0 + vor * 1.4
				_kamera.look_at(mitte + Vector3.UP * 1.15, Vector3.UP)
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
