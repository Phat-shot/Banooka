extends Node
## Sucht Ruckler beim Laufen: Bildzeiten auf einer festen Zickzackfahrt.
##
## Gebaut für die Klage vom Handy: „Es scheint bei Bewegung immer
## vor-/nachzuladen; wenn eine Richtung eingeschlagen ist, passt es." Die
## Figur läuft dieselbe Eingabefolge (vor, schräg links, schräg rechts,
## zurück, quer, wieder vor) ZWEIMAL vom Start aus. Ein Ruckler, der nur im
## ersten Durchgang auftritt, ist Arbeit beim ersten Gebrauch (Shader
## übersetzen, Textur hochladen); einer, der in beiden kommt, ist Arbeit
## in jedem Bild (Skripte, Neuaufbau, Schatten).
##
## Braucht einen echten Renderer (Xvfb + llvmpipe reicht):
##   bash werkzeuge/ruckelprobe.sh            (startet Xvfb selbst)
##
## Umgebungsvariablen:
##   RUCKEL_LEVEL      Szene (Vorgabe Level 01)
##   RUCKEL_REDUZIERT  1 = Handyweg wie auf Android/iOS: `Effekte.reduziert`,
##                     kein MSAA, Schattenkarte 2048
##   RUCKEL_DURCHGAENGE  Vorgabe 2
##   RUCKEL_VORWAERMEN 0 = ohne den Rundgang des Levels (`LevelBasis._rundgang`),
##                     zum Vergleich
##
## Mit `--fixed-fps 30` starten: Dann ist jede Fahrt Bild für Bild gleich,
## gleichgültig, wie langsam gezeichnet wird. Gemessen wird trotzdem die
## echte Zeit je Bild.
##
## Ausgabe je Durchgang: Median, 95 %, Höchstwert, Zahl der Ruckler
## (> RUCKEL_SCHWELLE × Median, Vorgabe 1,8, und mindestens 25 ms über dem
## Median) und je Ruckler eine Zeile mit Stelle, Zeichenaufrufen und
## Objekten im Bild. `bild` ist Godots „Process Time" des Bildes davor:
## Skripte UND Zeichnen (in Godot 4 misst sie bis nach `draw()`), `physik`
## die Physikschritte.

const FAHRT := [
	[2.0, Vector2(0.0, -1.0)],
	[1.0, Vector2(-0.8, -0.6)],
	[1.0, Vector2(0.8, -0.6)],
	[1.0, Vector2(0.0, 1.0)],
	[0.7, Vector2(-1.0, 0.0)],
	[0.7, Vector2(1.0, 0.0)],
	[2.6, Vector2(0.0, -1.0)],
	[1.0, Vector2(0.0, 1.0)],
	[0.6, Vector2(-0.7, -0.7)],
	[0.6, Vector2(0.7, -0.7)],
	[2.0, Vector2(0.0, -1.0)],
]

var _szene: Node
var _spieler: Node3D
var _kamera: Camera3D
var _letzt := 0
var _zeiten: PackedFloat64Array = []
var _zeilen: Array[String] = []
var _messen := false


func _ready() -> void:
	process_priority = -1000
	if OS.get_environment("RUCKEL_VORWAERMEN") == "0":
		LevelBasis.rundgang_an = false
	var reduziert := OS.get_environment("RUCKEL_REDUZIERT") == "1"
	if reduziert:
		Effekte.reduziert = true
		get_tree().root.msaa_3d = Viewport.MSAA_DISABLED
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
	var pfad := OS.get_environment("RUCKEL_LEVEL")
	if pfad.is_empty():
		pfad = "res://scenes/levels/Level01.tscn"
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	if nummer.is_valid_int():
		Spielfluss.aktuelles_level = int(nummer)
	print("Ruckelprobe: %s reduziert=%s Auflösung %s" % [pfad, str(Effekte.reduziert),
			str(get_viewport().get_visible_rect().size)])
	var t0 := Time.get_ticks_msec()
	_szene = (load(pfad) as PackedScene).instantiate()
	var fertig := [false]
	if _szene.has_signal("aufbau_fertig"):
		_szene.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_szene)
	var bilder := 0
	while not fertig[0] and bilder < 3000:
		bilder += 1
		await get_tree().process_frame
	print("Aufbau fertig nach %d ms, %d Bilder" % [Time.get_ticks_msec() - t0, bilder])
	# Die Bilder nach dem Aufbau zählen mit: Was der Ladeschirm nicht
	# verdeckt, sieht der Spieler.
	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	_kamera = get_viewport().get_camera_3d()
	_messen = true
	_letzt = Time.get_ticks_usec()
	var nach_aufbau: Array = await _warte_bilder(45)
	_auswerten("Nach dem Aufbau (1,5 s Stand)", nach_aufbau)

	var durchgaenge := 2
	if OS.get_environment("RUCKEL_DURCHGAENGE").is_valid_int():
		durchgaenge = int(OS.get_environment("RUCKEL_DURCHGAENGE"))
	var start := _spieler.global_position if _spieler != null else Vector3.ZERO
	for d in durchgaenge:
		if d > 0 and _spieler != null:
			InputHub.touch_bewegung = Vector2.ZERO
			_spieler.global_position = start
			if _spieler is CharacterBody3D:
				(_spieler as CharacterBody3D).velocity = Vector3.ZERO
			_spieler.reset_physics_interpolation()
			if _kamera != null and _kamera.has_method("sofort_ausrichten"):
				_kamera.call("sofort_ausrichten")
			await _warte_bilder(15)
		var werte: Array = await _fahrt()
		_auswerten("Durchgang %d" % (d + 1), werte)
	InputHub.touch_bewegung = Vector2.ZERO
	print("FERTIG")
	get_tree().quit(0)


func _warte_bilder(n: int) -> Array:
	var werte: Array = []
	for i in n:
		await get_tree().process_frame
		werte.append(_bildwert())
	return werte


func _fahrt() -> Array:
	var werte: Array = []
	for schritt: Array in FAHRT:
		var dauer: float = schritt[0]
		InputHub.touch_bewegung = schritt[1]
		# Spielzeit, nicht Bilder: Mit `--fixed-fps` ist jedes Bild gleich
		# lang, ohne zählt das wirkliche Delta.
		var vergangen := 0.0
		while vergangen < dauer - 0.0001:
			await get_tree().process_frame
			vergangen += get_process_delta_time()
			werte.append(_bildwert())
	return werte


## Eine Zeile je Bild: echte Dauer seit dem letzten Bild und Zählwerte.
func _bildwert() -> Dictionary:
	var jetzt := Time.get_ticks_usec()
	var ms := float(jetzt - _letzt) / 1000.0
	_letzt = jetzt
	var s := -1.0
	var verlauf: Variant = _szene.get("verlauf") if _szene != null else null
	if verlauf is Curve3D and _spieler != null:
		s = (verlauf as Curve3D).get_closest_offset(
				(_szene as Node3D).to_local(_spieler.global_position))
	var gieren := 0.0
	if _kamera != null:
		var z := -_kamera.global_basis.z
		gieren = rad_to_deg(atan2(z.x, -z.z))
	return {
		"ms": ms,
		"bild": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physik": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"obj": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"knoten": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"s": s,
		"gieren": gieren,
	}


func _auswerten(titel: String, werte: Array) -> void:
	if werte.is_empty():
		return
	var zeiten: Array[float] = []
	var draw := 0
	for w: Dictionary in werte:
		zeiten.append(float(w["ms"]))
		draw = maxi(draw, int(w["draw"]))
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[sortiert.size() / 2]
	var p95: float = sortiert[mini(sortiert.size() - 1, int(sortiert.size() * 0.95))]
	var hoechst: float = sortiert[sortiert.size() - 1]
	var schwelle := 1.8
	if not OS.get_environment("RUCKEL_SCHWELLE").is_empty():
		schwelle = float(OS.get_environment("RUCKEL_SCHWELLE"))
	var grenze := maxf(median * schwelle, median + 25.0)
	var ruckler: Array[String] = []
	var summe_ueber := 0.0
	for i in werte.size():
		var w: Dictionary = werte[i]
		if float(w["ms"]) > grenze:
			summe_ueber += float(w["ms"]) - median
			ruckler.append("    Bild %3d  %7.1f ms  bild %6.1f  physik %5.1f  draw %4d  obj %4d  knoten %5d  s %6.1f  gieren %6.1f" % [
					i, float(w["ms"]), float(w["bild"]), float(w["physik"]), int(w["draw"]),
					int(w["obj"]), int(w["knoten"]), float(w["s"]), float(w["gieren"])])
	print("RUCKEL %s: %d Bilder  Median %.1f ms  95%% %.1f ms  max %.1f ms  Ruckler %d (über %.0f ms, zusammen %.0f ms zu viel)  draw max %d" % [
			titel, werte.size(), median, p95, hoechst, ruckler.size(), grenze, summe_ueber, draw])
	for z in ruckler:
		print(z)
