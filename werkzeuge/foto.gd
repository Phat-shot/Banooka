extends Node
## Rendert Bilder einer Szene und legt sie als PNG ab.
##
## Aufruf über werkzeuge/foto.sh (einzelne Szene) oder
## werkzeuge/schaufenster.sh (fester Bildersatz für Vorher/Nachher).
## Godot kann im Headless-Modus nicht zeichnen; das Skript braucht daher
## einen echten Bildschirm (X11/Wayland). foto.sh legt das Fenster
## außerhalb des sichtbaren Bereichs ab und startet ohne DISPLAY selbst
## einen unsichtbaren X-Server (xvfb-run).
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
##   FOTO_ZEITMODUS 1 = Zeitmodus an (Zeitkisten im Level, Uhr im HUD)
##   FOTO_STATUS   1 = Statustafel aufgeklappt zeigen
##   FOTO_SEITLICH seitlicher Versatz der Figur vom Wegmittelpunkt in Metern
##                 (nur verfolger/seite/nah) – zeigt, wie stark die Kamera
##                 seitliche Bewegungen mitnimmt
##   FOTO_SEITENFAKTOR  überschreibt `seiten_faktor` der Korridorkamera
##   FOTO_WERTE    Datei (absoluter Pfad), an die je Aufnahme eine
##                 Tab-getrennte Zeile mit den Kosten angehängt wird;
##                 Kopfzeile beim Anlegen:
##                 bild  draw  objekte  primitive  vram_mb  knoten
##   FOTO_BUDGET_DRAW  Draw-Calls je Bild; darüber gibt es eine WARNUNG
##
## Ausgabe je Aufnahme, eine Zeile – Bild und Kosten stehen zusammen, damit
## jede Verschönerung zugleich nach Aussehen UND Preis beurteilt wird:
##   ok   <pfad>  draw 2026  obj 2044  prim 859k  vram 94.4 MB  knoten 3555
## draw      Draw-Calls des ganzen Bildes, die Schattenkarten der Sonne
##           eingerechnet. Getrennt ausweisen kann der Compatibility-
##           Renderer sie nicht (seine Schatten-Zählung bleibt immer 0),
##           deshalb fehlt eine eigene Spalte. Gemessen an Level 01: ohne
##           Sonnenschatten 1286 statt 2026 Draw-Calls bei 4 m, 480 statt
##           1027 bei 170 m – die Schatten kosten dort also gut ein Drittel
##           bis die Hälfte. Die Sonne läuft mit vier Schattenstufen; ein
##           Objekt mit `cast_shadow` aus spart bis zu vier Draw-Calls.
## obj/prim  gezeichnete Objekte und Primitive (Dreiecke), ebenfalls gesamt
## vram      belegter Grafikspeicher, knoten = Knoten im Baum
## Das sind Zählwerte, keine Zeiten: Sie stimmen unter llvmpipe (Xvfb)
## und auf einer echten Grafikkarte überein, sind also zwischen Rechnern
## vergleichbar. Headless (Dummy-Renderer) stehen dort nur Nullen.

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
	# FOTO_ZEITMODUS=1 zeigt das Level so, wie es im Zeitlauf aussieht:
	# mit Zeitkisten und laufender Uhr. Muss VOR dem Aufbau stehen – der
	# Umbau der Kisten passiert einmalig beim Laden des Levels.
	if OS.get_environment("FOTO_ZEITMODUS") == "1":
		Zeitlauf.aktiv = true
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
	# Wird zwischen den Aufnahmen versetzt, nie bewegt: ohne Interpolation,
	# sonst stünde sie im ersten Bild danach noch halb am alten Ort.
	_kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
				# Versetzt, nicht gelaufen: Ohne Rücksetzen zeichnete Godot
				# die Figur bis zum nächsten Physikschritt auf halbem Weg
				# von der vorigen Stelle – bei festen 30 Bildern je Sekunde
				# ist das nur das erste Bild, verschmiert wäre es trotzdem.
				_spieler.reset_physics_interpolation()
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
		_melde_aufnahme(name, fehler == OK)


## Druckt die Aufnahmezeile mit den Kosten des Bildes und hängt sie auf
## Wunsch an FOTO_WERTE an.
##
## Muss direkt nach `frame_post_draw` laufen: Die Zähler gelten für das
## zuletzt gezeichnete Bild und fangen beim nächsten wieder bei null an.
## Ein einziges `await` dazwischen, und die Werte gehörten schon zu einem
## anderen Bild als dem gespeicherten.
func _melde_aufnahme(pfad: String, gespeichert: bool) -> void:
	var draw := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objekte := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var primitive := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var vram_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var knoten := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	print("  %s  %s  draw %d  obj %d  prim %dk  vram %.1f MB  knoten %d" % [
			"ok " if gespeichert else "FEHLER", pfad, draw, objekte,
			roundi(primitive / 1000.0), vram_mb, knoten])

	var budget := OS.get_environment("FOTO_BUDGET_DRAW")
	if budget.is_valid_int() and draw > int(budget):
		print("  WARNUNG: %d Draw-Calls, Budget %s" % [draw, budget])

	var werte := OS.get_environment("FOTO_WERTE")
	if werte.is_empty():
		return
	# READ_WRITE statt WRITE: WRITE leert die Datei, und mehrere Läufe
	# (ein Aufruf je Szene) sammeln in dieselbe Tabelle.
	var neu := not FileAccess.file_exists(werte)
	var datei := FileAccess.open(werte, FileAccess.WRITE if neu else FileAccess.READ_WRITE)
	if datei == null:
		print("HINWEIS: FOTO_WERTE nicht schreibbar: %s" % werte)
		return
	if neu:
		datei.store_line("bild\tdraw\tobjekte\tprimitive\tvram_mb\tknoten")
	datei.seek_end()
	datei.store_line("%s\t%d\t%d\t%d\t%.1f\t%d" % [
			pfad.get_file(), draw, objekte, primitive, vram_mb, knoten])
