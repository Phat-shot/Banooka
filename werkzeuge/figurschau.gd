extends Node3D
## Figurschau: der Beuteldachs und sein Schutz aus der Nähe.
##
## Level 01 zu bauen dauert unter llvmpipe über eine Minute, und dort steht
## die Figur nur in einer Haltung. Hier stehen sie nebeneinander, unter
## dem Licht von Level 01 (Umgebung und Sonnen werden aus der Szene
## gelöst, das Level selbst nie gebaut), auf einem grünen Boden wie dem
## Waldweg.
##
##   bash werkzeuge/figurschau.sh <Zielverzeichnis> [Teile]
##
## Teile (mit Komma, Vorgabe alle):
##   posen    zwei Bilder: Stand, Lauf, Sprung, Drehschlag – Slide,
##            Krabbeln, Hangeln, Sitzen
##   gesicht  Kopf groß, schräg von vorn
##   ruecken  wie aus der Spielkamera, nur näher: Rücken und Schweif
##   schutz   Schutz in Stufe 1, 2, 3 von hinten, Stufe 3 ohne Glow,
##            Verlust einer Stufe (Blitz) und der letzten (zerbricht)
##   lauf     Bildfolge auf einem Bogen: geradeaus, quer, auf die Kamera
##            zu. Zeigt, wie der Schutz nachzieht und die Seite wechselt.
##
## Läuft mit `--fixed-fps 30` (figurschau.sh setzt das): Jedes Bild dauert
## 1/30 s Spielzeit, die Bilder sind von Lauf zu Lauf gleich.

const LICHT_AUS := "res://scenes/levels/Level01.tscn"
const DT := 1.0 / 30.0

var _ziel := ""
var _kamera: Camera3D
var _umgebung: WorldEnvironment
## Jede Figur mit ihrer Haltung: [modell, tempo, luft, slide, spin, haltung]
var _posen: Array = []
## Träger des Schutzes im Teil „schutz" und „lauf".
var _traeger: Node3D


func _ready() -> void:
	_ziel = OS.get_environment("FIGURSCHAU_BILD")
	if _ziel.is_empty():
		_ziel = "/tmp/figurschau"
	DirAccess.make_dir_recursive_absolute(_ziel)
	var teile := OS.get_environment("FIGURSCHAU_TEILE")
	if teile.is_empty():
		teile = "posen,gesicht,ruecken,schutz,lauf"
	GameState.schutz = 0
	_licht_aus_level()
	_boden()
	_kamera = Camera3D.new()
	_kamera.fov = 40.0
	_kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_kamera)
	_kamera.current = true
	_bauzeit_messen()
	for teil: String in teile.split(","):
		match teil.strip_edges():
			"posen":
				await _bild_posen()
			"gesicht":
				await _bild_gesicht()
			"ruecken":
				await _bild_ruecken()
			"schutz":
				await _bild_schutz()
			"lauf":
				await _bild_lauf()
	print("FERTIG")
	get_tree().quit()


func _process(delta: float) -> void:
	for p: Array in _posen:
		var modell: SpielerModell = p[0]
		if is_instance_valid(modell):
			modell.aktualisiere(delta, p[1], p[2], p[3], p[4], p[5])


# ------------------------------------------------------------------ Aufbau

## Umgebung und Lichter von Level 01, ohne das Level zu bauen: Die Szene
## wird nur instanziiert (kein `_ready`), die Knoten herausgelöst.
func _licht_aus_level() -> void:
	var level := (load(LICHT_AUS) as PackedScene).instantiate()
	for name: String in ["WorldEnvironment", "Sonne", "Gegenlicht",
			"Himmelslicht", "Bodenlicht"]:
		var knoten := level.get_node_or_null(name)
		if knoten == null:
			continue
		level.remove_child(knoten)
		knoten.owner = null
		add_child(knoten)
		if knoten is WorldEnvironment:
			_umgebung = knoten
			# Eigene Kopie: Glow wird für ein Bild abgeschaltet.
			_umgebung.environment = _umgebung.environment.duplicate()
	level.free()


## Bauzeit des Beuteldachses: Das erste Modell verschmilzt seine Netze,
## jedes weitere nimmt sie aus dem Vorrat. Beides zählt beim Laden eines
## Levels (Spieler, auf der Wildkatze, im Kart, in der Vorschau).
func _bauzeit_messen() -> void:
	var zeiten: Array[float] = []
	for i in 2:
		var start := Time.get_ticks_usec()
		var modell := SpielerModell.new()
		add_child(modell)
		zeiten.append(float(Time.get_ticks_usec() - start) / 1000.0)
		modell.free()
	print("  Bauzeit Beuteldachs: erstes %.1f ms, weiteres %.1f ms" % [zeiten[0], zeiten[1]])


func _boden() -> void:
	var boden := MeshInstance3D.new()
	var netz := PlaneMesh.new()
	netz.size = Vector2(60.0, 60.0)
	boden.mesh = netz
	boden.material_override = Materialbibliothek.einfarbig(Color(0.27, 0.42, 0.16), 0.95)
	add_child(boden)
	# Ein paar Stämme im Hintergrund, damit der Schutz vor Dunklem UND Hellem steht.
	for i in 6:
		var stamm := MeshInstance3D.new()
		var zylinder := CylinderMesh.new()
		zylinder.top_radius = 0.35
		zylinder.bottom_radius = 0.45
		zylinder.height = 8.0
		stamm.mesh = zylinder
		stamm.material_override = Materialbibliothek.einfarbig(Color(0.28, 0.2, 0.14), 0.95)
		stamm.position = Vector3(-7.5 + i * 3.1, 4.0, -9.0 - float(i % 2) * 3.0)
		add_child(stamm)


func _figur(ort: Vector3, blick: float, tempo: float, luft: bool, slide: float,
		spin: float, haltung: String) -> SpielerModell:
	var modell := SpielerModell.new()
	add_child(modell)
	modell.position = ort
	modell.setze_blick(blick)
	_posen.append([modell, tempo, luft, slide, spin, haltung])
	return modell


func _aufraeumen() -> void:
	for p: Array in _posen:
		if is_instance_valid(p[0]):
			(p[0] as Node).queue_free()
	_posen.clear()
	if is_instance_valid(_traeger):
		_traeger.queue_free()
	_traeger = null
	await _warte(2)


func _warte(bilder: int) -> void:
	for i in bilder:
		await get_tree().process_frame


func _foto(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var bild := get_viewport().get_texture().get_image()
	var pfad := _ziel.path_join(name + ".png")
	bild.save_png(pfad)
	print("  ok   ", pfad, "  draw ",
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	return bild


# ------------------------------------------------------------------- Bilder

func _bild_posen() -> void:
	var reihen := [
		[["stand", 0.0, false, 0.0, 0.0, ""], ["lauf", 1.0, false, 0.0, 0.0, ""],
			["sprung", 0.6, true, 0.0, 0.0, ""], ["dreh", 0.0, false, 0.0, 0.4, ""]],
		[["slide", 0.9, false, 0.3, 0.0, ""], ["krabbeln", 0.4, false, 0.0, 0.0, "krabbeln"],
			["hangeln", 0.3, true, 0.0, 0.0, "hangeln"], ["sitzen", 0.0, false, 0.0, 0.0, "sitzen"]],
	]
	for r in reihen.size():
		var reihe: Array = reihen[r]
		for i in reihe.size():
			var p: Array = reihe[i]
			var ort := Vector3(-2.1 + i * 1.4, 0.0, 0.0)
			if String(p[5]).begins_with("hangeln"):
				ort.y = 0.6
			_figur(ort, -0.55, p[1], p[2], p[3], p[4], p[5])
		_kamera.position = Vector3(1.6, 1.7, -5.6)
		_kamera.look_at(Vector3(0.0, 0.75, 0.0))
		await _warte(36)
		await _foto("posen_%d" % (r + 1))
		await _aufraeumen()


func _bild_gesicht() -> void:
	_figur(Vector3.ZERO, -0.35, 0.0, false, 0.0, 0.0, "")
	_kamera.position = Vector3(0.55, 1.35, -1.75)
	_kamera.look_at(Vector3(0.0, 1.05, 0.0))
	await _warte(20)
	await _foto("gesicht")
	await _aufraeumen()


func _bild_ruecken() -> void:
	_figur(Vector3(-0.8, 0.0, 0.0), 0.0, 1.0, false, 0.0, 0.0, "")
	_figur(Vector3(0.8, 0.0, 0.0), 0.3, 0.0, false, 0.0, 0.0, "")
	_kamera.position = Vector3(0.0, 2.3, 3.6)
	_kamera.look_at(Vector3(0.0, 0.8, 0.0))
	await _warte(30)
	await _foto("ruecken")
	await _aufraeumen()


## Ein Träger mit Figur und Schutz, wie der Spieler: Der Schutz hängt am
## Träger und liest ihn über `Bildtakt`.
func _traeger_bauen(ort: Vector3) -> SpielerModell:
	_traeger = Node3D.new()
	_traeger.name = "Traeger"
	_traeger.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_traeger)
	_traeger.position = ort
	var modell := SpielerModell.new()
	_traeger.add_child(modell)
	_posen.append([modell, 0.0, false, 0.0, 0.0, ""])
	_traeger.add_child(Schutzmaske.new())
	return modell


func _schutz_setzen(stufe: int) -> void:
	GameState.schutz = stufe
	GameState.schutz_geaendert.emit(stufe)


func _bild_schutz() -> void:
	_traeger_bauen(Vector3.ZERO)
	_kamera.fov = 45.0
	_kamera.position = Vector3(0.0, 2.2, 4.4)
	_kamera.look_at(Vector3(0.0, 1.0, -1.0))
	for stufe in [1, 2, 3]:
		_schutz_setzen(stufe)
		await _warte(45)
		await _foto("schutz_%d" % stufe)
	_umgebung.environment.glow_enabled = false
	await _warte(4)
	await _foto("schutz_3_ohne_glow")
	_umgebung.environment.glow_enabled = true
	# Verlust einer Stufe: Blitz, das Leuchten tritt eine Stufe zurück.
	_schutz_setzen(2)
	await _warte(2)
	await _foto("verlust_3_2_a")
	await _warte(6)
	await _foto("verlust_3_2_b")
	# Verlust der letzten: Die Maske zerbricht.
	_schutz_setzen(1)
	await _warte(30)
	_schutz_setzen(0)
	await _warte(3)
	await _foto("verlust_1_0_a")
	await _warte(12)
	await _foto("verlust_1_0_b")
	# Gewinn aus dem Nichts: Sie ploppt auf.
	_schutz_setzen(1)
	await _warte(4)
	await _foto("gewinn_0_1")
	await _aufraeumen()


## Der Träger läuft einen Weg ab, die Kamera folgt wie die Korridorkamera
## (fester Blick nach -Z, 4,2 m hoch, 8 m zurück). Alle 9 Bilder ein
## Foto, zusammen als Kontaktbogen.
func _bild_lauf() -> void:
	var modell := _traeger_bauen(Vector3.ZERO)
	_schutz_setzen(2)
	# Blickwinkel der Korridorkamera, aber enger: Die Figur soll groß
	# genug sein, um den Schutz neben ihr zu beurteilen.
	_kamera.fov = 32.0
	await _warte(20)
	# Abschnitte: [Dauer s, Richtung (Winkel um Y), Tempo m/s]
	var weg := [[1.2, 0.0, 8.5], [0.5, 0.0, 0.0], [1.2, -PI * 0.5, 8.5],
			[1.2, PI, 8.5], [0.6, PI, 0.0], [0.9, PI * 0.5, 8.5], [0.8, 0.0, 0.0]]
	var bilder: Array[Image] = []
	var zaehler := 0
	for abschnitt: Array in weg:
		var dauer: float = abschnitt[0]
		var winkel: float = abschnitt[1]
		var tempo: float = abschnitt[2]
		var t := 0.0
		while t < dauer:
			var richtung := Vector3(-sin(winkel), 0.0, -cos(winkel))
			_traeger.position += richtung * tempo * DT
			modell.setze_blick(winkel)
			_posen[0][1] = tempo / 8.5
			var ziel := _traeger.position
			_kamera.position = ziel + Vector3(0.0, 4.2, 8.0)
			_kamera.look_at(ziel + Vector3(0.0, 0.8, -2.0))
			await get_tree().process_frame
			zaehler += 1
			if zaehler % 9 == 0:
				await RenderingServer.frame_post_draw
				bilder.append(get_viewport().get_texture().get_image())
			t += DT
	_kontaktbogen(bilder, "lauf")
	await _aufraeumen()


func _kontaktbogen(bilder: Array[Image], name: String) -> void:
	if bilder.is_empty():
		return
	var spalten := 4
	var b := bilder[0].get_width() / 2
	var h := bilder[0].get_height() / 2
	var zeilen := (bilder.size() + spalten - 1) / spalten
	var bogen := Image.create(b * spalten, h * zeilen, false, Image.FORMAT_RGB8)
	for i in bilder.size():
		var klein := bilder[i]
		klein.convert(Image.FORMAT_RGB8)
		klein.resize(b, h, Image.INTERPOLATE_BILINEAR)
		bogen.blit_rect(klein, Rect2i(0, 0, b, h), Vector2i((i % spalten) * b, (i / spalten) * h))
	var pfad := _ziel.path_join(name + ".png")
	bogen.save_png(pfad)
	print("  ok   ", pfad, "  (", bilder.size(), " Bilder)")
