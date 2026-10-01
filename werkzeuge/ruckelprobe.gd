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
##   RUCKEL_REDUZIERT  1 = Handyweg wie die App auf Android/iOS:
##                     `Effekte.reduziert`, kein MSAA, Schattenkarte 2048, 3D in
##                     der Auflösung von `rendering/scaling_3d/scale.mobile`
##   RUCKEL_DURCHGAENGE  Vorgabe 2
##   RUCKEL_VORWAERMEN 0 = ohne den Rundgang (`Rundgang`), zum Vergleich
##   RUCKEL_BESUCHE    so oft wird die Szene nacheinander gebaut, gemessen
##                     und wieder freigegeben (Vorgabe 1). Ab dem zweiten
##                     Besuch zeigt sich, was der erste übersetzt
##                     zurücklässt – der Portalraum wird nach jedem Level
##                     neu betreten.
##   RUCKEL_MASS       wonach Ruckler gezählt werden: "zeit" (Vorgabe, echte
##                     Dauer je Bild), "cpu" (Rechenzeit des Hauptfadens) oder
##                     "cpu_alle" (Rechenzeit aller Fäden des Prozesses, unter
##                     llvmpipe samt Rastern). Die Rechenzeit stammt aus
##                     /proc (Linux) und zählt nur, was der Prozess selbst
##                     rechnet: Läuft nebenher ein zweiter Godot, wachsen die
##                     echten Bildzeiten mit, die Rechenzeit nicht. Gedruckt
##                     werden immer alle drei Kennzahlen.
##   RUCKEL_STAND      Spielstand vor dem Laden: "neu" (nichts geschafft)
##                     oder "mitte" (Raum 1 und 2 geschafft, in Raum 3 die
##                     Level 11 und 12, teils mit Edelsteinen und Bestzeiten;
##                     Raum 4 und 5 versiegelt). Vorgabe im Portalraum
##                     "mitte" – so steht jede Art Tor einmal da –, sonst
##                     "neu".
##
## PORTALRAUM (RUCKEL_LEVEL=res://scenes/hub/Hub.tscn): Statt der
## Zickzackfahrt dreht sich die Figur erst auf der Stelle (acht
## Richtungen), dann läuft sie den Hallenbogen ab, an allen Räumen vorbei:
## in jeden offenen Raum durchs Tor und an allen fünf Toren entlang, vor
## einem versiegelten bis an das Siegel. Gelenkt wird auf Wegpunkte
## (`_hub_wegpunkte`); ein Punkt, der nach `WEGPUNKT_ZEIT` nicht erreicht
## ist, wird übersprungen und gemeldet.
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
## die Physikschritte, `ort` die Stelle der Figur (x, z).

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
## Höchstens so lange (Spielzeit, s) wird auf einen Wegpunkt zugelaufen.
const WEGPUNKT_ZEIT := 8.0

var _szene: Node
var _spieler: Node3D
var _kamera: Camera3D
var _letzt := 0
var _letzt_cpu := 0
var _letzt_alle := 0
var _zeiten: PackedFloat64Array = []
var _zeilen: Array[String] = []
var _messen := false
var _hub := false
var _verfehlt := 0


func _ready() -> void:
	process_priority = -1000
	if OS.get_environment("RUCKEL_VORWAERMEN") == "0":
		Rundgang.an = false
	var reduziert := OS.get_environment("RUCKEL_REDUZIERT") == "1"
	if reduziert:
		Effekte.reduziert = true
		get_tree().root.msaa_3d = Viewport.MSAA_DISABLED
		RenderingServer.directional_shadow_atlas_set_size(int(ProjectSettings.get_setting(
				"rendering/lights_and_shadows/directional_shadow/size.mobile", 2048)), true)
		get_tree().root.scaling_3d_scale = float(ProjectSettings.get_setting(
				"rendering/scaling_3d/scale.mobile", 1.0))
	var pfad := OS.get_environment("RUCKEL_LEVEL")
	if pfad.is_empty():
		pfad = "res://scenes/levels/Level01.tscn"
	_hub = pfad.contains("/hub/")
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	if nummer.is_valid_int():
		Spielfluss.aktuelles_level = int(nummer)
	var stand := OS.get_environment("RUCKEL_STAND")
	if stand.is_empty():
		stand = "mitte" if _hub else "neu"
	if stand == "mitte":
		_stand_mitte()
	print("Ruckelprobe: %s reduziert=%s Auflösung %s Stand %s" % [pfad,
			str(Effekte.reduziert), str(get_viewport().get_visible_rect().size), stand])
	var besuche := 1
	if OS.get_environment("RUCKEL_BESUCHE").is_valid_int():
		besuche = maxi(1, int(OS.get_environment("RUCKEL_BESUCHE")))
	for besuch in besuche:
		if besuche > 1:
			print("=== Besuch %d ===" % (besuch + 1))
		await _besuch(pfad)
	InputHub.touch_bewegung = Vector2.ZERO
	print("FERTIG")
	get_tree().quit(0)


## Baut die Szene, misst Stand und Fahrten und gibt sie wieder frei.
func _besuch(pfad: String) -> void:
	_messen = false
	var t0 := Time.get_ticks_msec()
	_szene = (load(pfad) as PackedScene).instantiate()
	var fertig := [false]
	var mit_signal := _szene.has_signal("aufbau_fertig")
	if mit_signal:
		_szene.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_szene)
	var t1 := Time.get_ticks_msec()
	var bilder := 0
	while not fertig[0] and bilder < 3000:
		bilder += 1
		await get_tree().process_frame
	if not mit_signal:
		# Ein Portalraum ohne Signal (Stand vor dem Rundgang) blendete nach
		# vier Bildern aus.
		for i in 4:
			bilder += 1
			await get_tree().process_frame
	print("Aufbau fertig nach %d ms (davon _ready %d ms), %d Bilder, Grafikspeicher %.1f MB" % [
			Time.get_ticks_msec() - t0, t1 - t0, bilder,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	var zeiten: Variant = _szene.get("bauzeiten")
	if zeiten is Array:
		for e: Variant in zeiten as Array:
			var eintrag := e as Dictionary
			if eintrag != null and String(eintrag["text"]).begins_with("Vorwärmen"):
				print("  %s: %.0f ms" % [String(eintrag["text"]), float(eintrag["ms"])])
	# Die Bilder nach dem Aufbau zählen mit: Was der Ladeschirm nicht
	# verdeckt, sieht der Spieler.
	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	_kamera = get_viewport().get_camera_3d()
	_messen = true
	_letzt = Time.get_ticks_usec()
	_letzt_cpu = _cpu_ns()
	_letzt_alle = _cpu_alle_ns()
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
		_verfehlt = 0
		var werte: Array = []
		if _hub:
			werte = await _hub_fahrt()
		else:
			werte = await _fahrt()
		_auswerten("Durchgang %d" % (d + 1), werte)
		print("  Grafikspeicher danach %.1f MB" % (
				Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0))
		if _verfehlt > 0:
			print("  %d Wegpunkte nicht erreicht" % _verfehlt)
	InputHub.touch_bewegung = Vector2.ZERO
	_messen = false
	_szene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Spielstand "mitte" (siehe Kopf). Edelsteine und Zeitstufen wechseln,
## damit jede Art Schmuck an einem Tor steht. Gespeichert wird nichts:
## Es ist kein Speicherplatz gewählt.
func _stand_mitte() -> void:
	GameState.debug = false
	Spielfluss.aktueller_slot = 0
	Spielfluss.geschafft = {}
	Spielfluss.zeiten = {}
	for nr in range(1, 13):
		Spielfluss.geschafft[nr] = {"kisten": nr % 2 == 1, "ohne_tod": nr % 3 == 0,
				"fruechte": 40}
		if nr <= 9:
			Spielfluss.zeiten[nr] = {"zeit": 60.0 + float(nr) * 7.3, "stufe": nr % 4}
	Spielfluss.freigeschaltet = 13


func _warte_bilder(n: int) -> Array:
	var werte: Array = []
	for i in n:
		await get_tree().process_frame
		werte.append(_bildwert())
	return werte


func _fahrt() -> Array:
	var werte: Array = []
	for schritt: Array in FAHRT:
		werte.append_array(await _halten(schritt[1], schritt[0]))
	return werte


## Hält eine Eingabe für `dauer` Sekunden. Spielzeit, nicht Bilder: Mit
## `--fixed-fps` ist jedes Bild gleich lang, ohne zählt das wirkliche Delta.
func _halten(eingabe: Vector2, dauer: float) -> Array:
	var werte: Array = []
	InputHub.touch_bewegung = eingabe
	var vergangen := 0.0
	while vergangen < dauer - 0.0001:
		await get_tree().process_frame
		vergangen += get_process_delta_time()
		werte.append(_bildwert())
	return werte


## Portalraum: erst auf der Stelle drehen, dann an allen Räumen vorbei.
func _hub_fahrt() -> Array:
	var werte: Array = []
	for i in 8:
		var w := TAU * float(i) / 8.0
		werte.append_array(await _halten(Vector2(sin(w), -cos(w)) * 0.35, 0.25))
	for ziel in _hub_wegpunkte():
		werte.append_array(await _hin(ziel))
	InputHub.touch_bewegung = Vector2.ZERO
	return werte


## Läuft auf einen Punkt zu, waagerecht und kamerarelativ gelenkt.
func _hin(ziel: Vector3) -> Array:
	var werte: Array = []
	var vergangen := 0.0
	while vergangen < WEGPUNKT_ZEIT:
		if _spieler == null or not is_instance_valid(_spieler):
			break
		var weg := ziel - _spieler.global_position
		weg.y = 0.0
		if weg.length() < 1.2:
			return werte
		var eingabe := Vector2(weg.x, weg.z).normalized()
		if _kamera != null:
			var rechts := _kamera.global_basis.x
			var vorn := -_kamera.global_basis.z
			rechts.y = 0.0
			vorn.y = 0.0
			eingabe = Vector2(weg.dot(rechts.normalized()),
					-weg.dot(vorn.normalized())).normalized()
		InputHub.touch_bewegung = eingabe
		await get_tree().process_frame
		vergangen += get_process_delta_time()
		werte.append(_bildwert())
	_verfehlt += 1
	return werte


## Wegpunkte im Portalraum, aus dessen eigenen Maßen (hub.gd): vom Start
## den Hallenbogen hinab zum linken Raum, dann Raum für Raum nach rechts.
func _hub_wegpunkte() -> Array[Vector3]:
	var skript := _szene.get_script() as Script
	var k := skript.get_script_constant_map()
	var start_r := float(k["START_R"])
	var tor_r := float(k["TOR_R"])
	var portal_r := float(k["PORTAL_R"])
	var mitte: Vector3 = k["BOGEN_MITTE"]
	var breite := float(k["PORTAL_ABSTAND"]) * 2.0
	var punkte: Array[Vector3] = []
	var winkel := 0.0
	if _spieler != null:
		var p := _spieler.global_position
		winkel = rad_to_deg(atan2(p.x - mitte.x, mitte.z - p.z))
	for i in Spielfluss.RAEUME:
		var g := (float(i) - 2.0) * float(k["RAUM_WINKEL"])
		var schritte := maxi(int(absf(g - winkel) / 7.0), 1)
		for n in range(1, schritte + 1):
			punkte.append(_bogenort(mitte, lerpf(winkel, g, float(n) / float(schritte)),
					start_r))
		winkel = g
		if Spielfluss.raum_offen(i + 1):
			var tief := portal_r - 3.2
			punkte.append(_bogenort(mitte, g, tor_r + 2.5))
			punkte.append(_bogenort(mitte, g + rad_to_deg(-breite / tief), tief))
			punkte.append(_bogenort(mitte, g + rad_to_deg(breite / tief), tief))
			punkte.append(_bogenort(mitte, g, tor_r + 2.5))
		else:
			punkte.append(_bogenort(mitte, g, tor_r - 3.0))
		punkte.append(_bogenort(mitte, g, start_r))
	return punkte


static func _bogenort(mitte: Vector3, grad: float, radius: float) -> Vector3:
	var t := deg_to_rad(grad)
	return mitte + Vector3(sin(t) * radius, 0.0, -cos(t) * radius)


## Rechenzeit des Hauptfadens in Nanosekunden (erstes Feld von
## /proc/thread-self/schedstat), 0 ohne /proc.
static func _cpu_ns() -> int:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return 0
	return int(f.get_line().get_slice(" ", 0))


## Rechenzeit aller Fäden des Prozesses in Nanosekunden, 0 ohne /proc.
static func _cpu_alle_ns() -> int:
	var summe := 0
	for faden in DirAccess.get_directories_at("/proc/self/task"):
		var f := FileAccess.open("/proc/self/task/%s/schedstat" % faden, FileAccess.READ)
		if f != null:
			summe += int(f.get_line().get_slice(" ", 0))
	return summe


## Eine Zeile je Bild: echte Dauer seit dem letzten Bild, Rechenzeit und
## Zählwerte.
func _bildwert() -> Dictionary:
	var jetzt := Time.get_ticks_usec()
	var ms := float(jetzt - _letzt) / 1000.0
	_letzt = jetzt
	var cpu := _cpu_ns()
	var alle := _cpu_alle_ns()
	var cpu_ms := float(cpu - _letzt_cpu) / 1.0e6
	var alle_ms := float(alle - _letzt_alle) / 1.0e6
	_letzt_cpu = cpu
	_letzt_alle = alle
	var s := -1.0
	var verlauf: Variant = _szene.get("verlauf") if _szene != null else null
	var da := _spieler != null and is_instance_valid(_spieler)
	if verlauf is Curve3D and da:
		s = (verlauf as Curve3D).get_closest_offset(
				(_szene as Node3D).to_local(_spieler.global_position))
	var gieren := 0.0
	if _kamera != null:
		var z := -_kamera.global_basis.z
		gieren = rad_to_deg(atan2(z.x, -z.z))
	return {
		"ms": ms,
		"cpu": cpu_ms,
		"cpu_alle": alle_ms,
		"bild": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physik": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"obj": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"knoten": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"s": s,
		"gieren": gieren,
		"ort": _spieler.global_position if da else Vector3.ZERO,
	}


func _auswerten(titel: String, werte: Array) -> void:
	if werte.is_empty():
		return
	var mass := OS.get_environment("RUCKEL_MASS")
	if mass != "cpu" and mass != "cpu_alle":
		mass = "ms"
	var schwelle := 1.8
	if not OS.get_environment("RUCKEL_SCHWELLE").is_empty():
		schwelle = float(OS.get_environment("RUCKEL_SCHWELLE"))
	var draw := 0
	for w: Dictionary in werte:
		draw = maxi(draw, int(w["draw"]))
	var kennzahlen := {}
	for schluessel: String in ["ms", "cpu", "cpu_alle"]:
		kennzahlen[schluessel] = _kennzahlen(werte, schluessel, schwelle)
	var k: Dictionary = kennzahlen[mass]
	print("RUCKEL %s: %d Bilder  Median %.1f ms  95%% %.1f ms  max %.1f ms  Ruckler %d (über %.0f ms, zusammen %.0f ms zu viel)  draw max %d  [Maß %s]" % [
			titel, werte.size(), float(k["median"]), float(k["p95"]), float(k["max"]),
			int(k["anzahl"]), float(k["grenze"]), float(k["ueber"]), draw,
			"zeit" if mass == "ms" else mass])
	for schluessel: String in ["ms", "cpu", "cpu_alle"]:
		var z: Dictionary = kennzahlen[schluessel]
		print("  %-8s Median %7.1f  max %7.1f  Ruckler %3d  zusammen %6.0f ms zu viel" % [
				"zeit" if schluessel == "ms" else schluessel, float(z["median"]),
				float(z["max"]), int(z["anzahl"]), float(z["ueber"])])
	var grenze := float(k["grenze"])
	for i in werte.size():
		var w: Dictionary = werte[i]
		if float(w[mass]) <= grenze:
			continue
		var ort: Vector3 = w["ort"]
		print("    Bild %3d  %7.1f ms  cpu %6.1f  alle %6.1f  bild %6.1f  physik %5.1f  draw %4d  obj %4d  knoten %5d  s %6.1f  gieren %6.1f  ort %5.1f %5.1f" % [
				i, float(w["ms"]), float(w["cpu"]), float(w["cpu_alle"]), float(w["bild"]),
				float(w["physik"]), int(w["draw"]), int(w["obj"]), int(w["knoten"]),
				float(w["s"]), float(w["gieren"]), ort.x, ort.z])


## Median, 95 %, Höchstwert und Ruckler einer Kennzahl (`schluessel`).
## Ruckler: über `schwelle` × Median und mindestens 25 ms darüber.
static func _kennzahlen(werte: Array, schluessel: String, schwelle: float) -> Dictionary:
	var zeiten: Array[float] = []
	for w: Dictionary in werte:
		zeiten.append(float(w[schluessel]))
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[sortiert.size() / 2]
	var grenze := maxf(median * schwelle, median + 25.0)
	var anzahl := 0
	var ueber := 0.0
	for z in zeiten:
		if z > grenze:
			anzahl += 1
			ueber += z - median
	return {
		"median": median,
		"p95": sortiert[mini(sortiert.size() - 1, int(sortiert.size() * 0.95))],
		"max": sortiert[sortiert.size() - 1],
		"grenze": grenze,
		"anzahl": anzahl,
		"ueber": ueber,
	}
