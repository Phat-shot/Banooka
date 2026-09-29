extends Node
## Glattprobe: Läuft das Bild glatt, oder springt etwas im Physiktakt?
##
## Aufruf (headless, nach Sekunden fertig, bei jedem Lauf dieselben Werte):
##   godot --headless --path . res://werkzeuge/Glattprobe.tscn --fixed-fps 144
##   GLATT_SZENEN=res://scenes/levels/Level06.tscn godot --headless … (Komma-Liste)
##
## `--fixed-fps 144` ist der Kern: Jedes Bild dauert genau 1/144 s Spielzeit,
## die Physik bleibt bei 60 Hz. Das ist der Fall, in dem man Ruckeln sieht –
## ein Bildschirm mit 120 oder 144 Hz –, und er lässt sich ohne Bildschirm
## nachstellen: Godot rechnet die Interpolation im Szenenbaum (SceneTreeFTI),
## `get_global_transform_interpolated()` ist also der Ort, an dem der Knoten
## gezeichnet wird. Unter Xvfb an Farbwürfeln gegengeprüft: gemessener
## Bildort und dieser Wert stimmten überein. Ohne `--fixed-fps` misst die
## Probe, was der Rechner gerade hergibt – das schwankt von Lauf zu Lauf.
##
## Je Szene läuft die Figur gut drei Sekunden (Touchrichtung nach vorn, im
## Portalraum die Halle entlang; Reiter und Karts fahren ohnehin), zwei
## davon werden gemessen:
##
##   1. Im Bild, beide als mittlere Änderung des Bildschritts von Bild zu
##      Bild (zweite Differenz, RMS, in Pixeln bei 720 Pixeln Bildhöhe):
##        Figur im Bild – der Bildpunkt der Figur;
##        Welt im Bild  – der Bildpunkt einer festen Stelle am Boden unter
##                        der Figur, gesehen durch die Kamera dreier Bilder
##                        hintereinander: das Ruckeln der Umgebung. Es fällt
##                        auch dort auf, wo die Kamera die Figur per
##                        `look_at` in der Bildmitte hält (Portalraum) – da
##                        steht die Figur still, und die Welt springt.
##      Weiche Bewegung ändert ihren Schritt kaum (Hundertstel bis Zehntel
##      Pixel); ein 60-Hz-Sprung zeigt sich als Knick von mehreren Pixeln.
##      Über `GRENZE_ZITTERN_PX` heißt es RUCKELT.
##      Zur Auskunft dazu Kamera und Figur in der Welt: Weg je Bild, seine
##      Streuung (Standardabweichung durch Mittelwert) und der Anteil der
##      Bilder ohne Bewegung. Glatt: Streuung nahe 0. Stufen im 60-Hz-Takt:
##      um 1,2, und 58 % der Bilder stehen still. Bewertet wird das nicht –
##      bleibt die Figur an einer Kiste hängen, streut es auch.
##   2. Knoten, die ZWISCHEN den Physikschritten bewegt werden (`_process`,
##      Tweens, Zeitgeber), aber interpoliert gezeichnet werden. Godot mischt
##      dann den Stand des letzten Physikschritts mit dem neuen Bildstand –
##      der Knoten zittert. Solche Knoten brauchen
##      `physics_interpolation_mode = OFF` (ARCHITEKTUR.md, „Bildtakt und
##      Physiktakt"). Meldung: ZITTERT.
##   3. Knoten, die IM Physikschritt bewegt werden, aber nicht interpoliert
##      sind – sie laufen in 60-Hz-Stufen. Meldung: STUFT.
##   4. Versetzen im Bildtakt: `respawn()` zwischen zwei Physikschritten,
##      wie nach dem Ertrinken (Zeitgeber) oder im Bonusraum. Die Kamera muss
##      im selben Bild mitspringen und darf danach nur ihren gewöhnlichen
##      Schritt machen. Flöge sie von der alten Stelle zurück, heißt es
##      FLIEGT NACH (siehe `Bildtakt`).
##
## Ein Knoten zählt erst ab `MINDEST_BILDER` auffälligen Bildern: Ein
## einzelnes Versetzen mit `reset_physics_interpolation()` ist erlaubt.
##
## Rückgabe: 0 = alles glatt, 1 = mindestens eine Abweichung.

const STANDARD_SZENEN := "res://scenes/levels/Level01.tscn,res://scenes/hub/Hub.tscn,res://scenes/levels/Level04.tscn"
## Alle so viele Bilder ein Drehschlag: Er räumt Kisten aus dem Weg, ohne
## das Tempo zu ändern – und bringt Früchte, Splitter und Funken ins Bild,
## die der Wächter dann mit prüft.
const SCHLAG_TAKT := 80
## Bilder vor dem Loslaufen: Startportal und Auftritt der Figur abwarten.
const VORLAUF := 150
## Bilder, in denen die Figur schon läuft, bevor gemessen wird. Am
## Kurvenanfang steht die Korridorkamera still, bis die Figur `abstand`
## Meter weit ist – das soll nicht in die Messung.
const ANLAUF := 144
## Gemessene Bilder (2 s bei 144 Bildern je Sekunde).
const MESSBILDER := 288
const GRENZE_ZITTERN_PX := 1.0
## Größter Kameraschritt je Bild nach einem Versetzen. Beim Folgen sind es
## Zentimeter; eine Kamera, die 20 m zurückfliegt, macht fast einen Meter.
const GRENZE_NACHFLUG := 0.5
const MINDEST_BILDER := 3

var _fehler := 0

# --- Aufzeichnung, im eigenen `_process` ganz am Ende jedes Bildes ---
var _spieler: Node3D
var _kamera: Camera3D
var _kamera_lagen: Array[Transform3D] = []
var _kamera_fov: Array[float] = []
var _figur_orte: Array[Vector3] = []
var _bildzeiten: Array[float] = []
var _zeichnen := false
var _schlagen := false
var _bild := 0
## Mitte des Hallenbogens im Portalraum, sonst INF
var _bogen_mitte := Vector3.INF
var _bogen_radius := 0.0

# --- Wächter über alle Node3D der Szene ---
var _knoten: Array[Node3D] = []
## Instanz-ID -> zuletzt gesehene lokale Transformation
var _stand := {}
## Instanz-ID -> Zahl der Bilder mit Bewegung im Bildtakt bzw. Physiktakt
var _im_bild := {}
var _in_physik := {}
## "bild" nach `process_frame`, "physik" nach `physics_frame`
var _phase := ""
var _wache := false


func _ready() -> void:
	# Ganz hinten: Kamera und Figur haben ihr `_process` für dieses Bild
	# schon hinter sich, wenn hier gelesen wird.
	process_priority = 1 << 30
	get_tree().process_frame.connect(_auf_bild)
	get_tree().physics_frame.connect(_auf_physik)
	var liste := OS.get_environment("GLATT_SZENEN")
	if liste.is_empty():
		liste = STANDARD_SZENEN
	print("=== Glattprobe (Physik %d Hz, Interpolation %s) ===" % [
			Engine.physics_ticks_per_second,
			"an" if get_tree().physics_interpolation else "AUS"])
	for pfad in liste.split(","):
		await _szene_pruefen(pfad.strip_edges())
	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


func _process(_delta: float) -> void:
	_bild += 1
	if _schlagen and _bild % SCHLAG_TAKT == 0:
		InputHub.touch_spin(true)
	if _schlagen and _bogen_mitte.is_finite():
		_bogen_lenken()
	if not _zeichnen:
		return
	# Die Kamera ohne Interpolation: gezeichnet wird genau `global_transform`.
	# NICHT `get_global_transform_interpolated()` – für einen Knoten, der im
	# Bildtakt bewegt wird, liefert das den Merkwert vom Ende des VORIGEN
	# Bildes (SceneTreeFTI rechnet ihn dann), also ein Bild zu spät.
	_kamera_lagen.append(_kamera.global_transform)
	_kamera_fov.append(_kamera.fov)
	_figur_orte.append(_spieler.get_global_transform_interpolated().origin)
	_bildzeiten.append(_delta)


## Hält die Figur auf dem Hallenbogen: tangential laufen, leicht zurück
## auf den Anfangsradius ziehen. Geradeaus stünde sie nach zwei Sekunden
## vor dem Siegel eines gesperrten Raums. Die Hallenkamera blickt starr
## nach -Z, Touch (x, y) ist darum gleich Welt (x, z).
func _bogen_lenken() -> void:
	var r := _spieler.global_position - _bogen_mitte
	var flach := Vector2(r.x, r.z)
	var weg := Vector2(-flach.y, flach.x).normalized()
	weg -= flach.normalized() * clampf((flach.length() - _bogen_radius) * 0.5, -0.5, 0.5)
	InputHub.touch_bewegung = weg.normalized()


func _szene_pruefen(pfad: String) -> void:
	var nummer := pfad.get_file().get_basename().to_lower().trim_prefix("level")
	Spielfluss.aktuelles_level = int(nummer) if nummer.is_valid_int() else 0
	var szene: Node = load(pfad).instantiate()
	add_child(szene)
	if szene.has_signal("aufbau_fertig"):
		var fertig := [false]
		szene.aufbau_fertig.connect(func() -> void: fertig[0] = true)
		var warten := 0
		while not fertig[0] and warten < 900:
			warten += 1
			await get_tree().process_frame
	for i in VORLAUF:
		await get_tree().process_frame

	print("--- %s ---" % pfad)
	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	_kamera = get_viewport().get_camera_3d()
	if _spieler == null or _kamera == null:
		# Menü, Vorspann: nichts zu verfolgen, aber bewegt wird trotzdem.
		print("  keine Figur oder keine Kamera – nur der Wächter")
		_wache_starten(szene)
		for i in MESSBILDER + 1:
			await get_tree().process_frame
		_wache = false
		_auffaellige(szene)
	else:
		# Unverwundbar: Ein Tod mitten in der Messung versetzte die Figur an
		# den Checkpoint, und gemessen wäre der Sprung, nicht das Laufen.
		# (Stürze töten trotzdem; auf den Standardstrecken kommt keiner vor.)
		if "invuln" in _spieler:
			_spieler.set("invuln", 3600.0)
		InputHub.touch_bewegung = Vector2(0.0, -1.0)
		_bogen_mitte = Vector3.INF
		var skript := szene.get_script() as Script
		var konstanten := skript.get_script_constant_map() if skript != null else {}
		if konstanten.has("BOGEN_MITTE"):
			_bogen_mitte = konstanten["BOGEN_MITTE"]
			var r := _spieler.global_position - _bogen_mitte
			_bogen_radius = Vector2(r.x, r.z).length()
		_schlagen = true
		for i in ANLAUF:
			await get_tree().process_frame
		_kamera_lagen.clear()
		_kamera_fov.clear()
		_figur_orte.clear()
		_bildzeiten.clear()
		_wache_starten(szene)
		_zeichnen = true
		for i in MESSBILDER:
			await get_tree().process_frame
		# Das letzte `_process` gehört noch zur Messung.
		await get_tree().process_frame
		_zeichnen = false
		_schlagen = false
		_wache = false
		InputHub.touch_bewegung = Vector2.ZERO
		_bildtakt_melden()
		_bild_bewertung()
		var kamera_orte: Array[Vector3] = []
		for lage in _kamera_lagen:
			kamera_orte.append(lage.origin)
		_auskunft("Kamera", kamera_orte)
		_auskunft("Figur ", _figur_orte)
		_auffaellige(szene)
		await _versetzen_pruefen()
	szene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Respawn im Bildtakt: Diese Zeile läuft nach `process_frame`, also nach
## dem Bildanfang, an dem Godot den interpolierten Ort ausrechnet, und vor
## allen `_process`. Genau dort ist `get_global_transform_interpolated()`
## veraltet.
func _versetzen_pruefen() -> void:
	# Karts sterben nicht, sie drehen sich (`Rennfahrer.sterben()` ist ein
	# Dreher); das geerbte `respawn()` ruft im Spiel niemand auf.
	if not _spieler.has_method("respawn") or _spieler is Rennfahrer:
		return
	var vorher := _kamera.global_position
	_kamera_lagen.clear()
	_kamera_fov.clear()
	_figur_orte.clear()
	_bildzeiten.clear()
	_spieler.call("respawn")
	_zeichnen = true
	for i in 30:
		await get_tree().process_frame
	_zeichnen = false
	var sprung := vorher.distance_to(_kamera_lagen[0].origin)
	var danach := 0.0
	for i in range(1, _kamera_lagen.size()):
		danach = maxf(danach, _kamera_lagen[i].origin.distance_to(_kamera_lagen[i - 1].origin))
	var urteil := "springt mit"
	if danach > GRENZE_NACHFLUG:
		urteil = "FLIEGT NACH"
		_fehler += 1
	print("  Versetzen      Kamera %.1f m im selben Bild, danach höchstens %.2f m je Bild  -> %s"
			% [sprung, danach, urteil])


## Wie lang die gemessenen Bilder waren. Mit `--fixed-fps 144` genau
## 1/144 s; alles andere heißt, die Probe lief ohne festen Takt.
func _bildtakt_melden() -> void:
	var kurz := INF
	var lang := 0.0
	for d in _bildzeiten:
		kurz = minf(kurz, d)
		lang = maxf(lang, d)
	print("  Bildtakt       %.2f bis %.2f ms je Bild" % [kurz * 1000.0, lang * 1000.0])


## Bildpunkt von `punkt` durch die Kamera von Bild `i`, in Pixeln bei
## 720 Pixeln Bildhöhe (senkrechtes Sichtfeld, wie Godot es vorgibt).
func _bildpunkt(i: int, punkt: Vector3) -> Vector2:
	var v := _kamera_lagen[i].affine_inverse() * punkt
	var tiefe := maxf(-v.z, 0.01)
	var pixel := 360.0 / tan(deg_to_rad(_kamera_fov[i]) * 0.5)
	return Vector2(v.x, -v.y) / tiefe * pixel


func _bild_bewertung() -> void:
	var figur := 0.0
	var welt := 0.0
	var anzahl := 0
	for i in range(2, _figur_orte.size()):
		var f0 := _bildpunkt(i - 2, _figur_orte[i - 2] + Vector3.UP * 0.7)
		var f1 := _bildpunkt(i - 1, _figur_orte[i - 1] + Vector3.UP * 0.7)
		var f2 := _bildpunkt(i, _figur_orte[i] + Vector3.UP * 0.7)
		figur += ((f2 - f1) - (f1 - f0)).length_squared()
		# Eine feste Stelle am Boden, drei Kameras nacheinander.
		var fest := _figur_orte[i]
		var w0 := _bildpunkt(i - 2, fest)
		var w1 := _bildpunkt(i - 1, fest)
		var w2 := _bildpunkt(i, fest)
		welt += ((w2 - w1) - (w1 - w0)).length_squared()
		anzahl += 1
	var n := maxf(float(anzahl), 1.0)
	for paar: Array in [["Figur im Bild", sqrt(figur / n)], ["Welt im Bild ", sqrt(welt / n)]]:
		var wert: float = paar[1]
		var urteil := "glatt"
		if wert > GRENZE_ZITTERN_PX:
			urteil = "RUCKELT"
			_fehler += 1
		print("  %s  Zittern %.2f px  -> %s" % [paar[0], wert, urteil])


## Weg je Bild in der Welt, zur Auskunft (siehe Kopf: nicht bewertet).
func _auskunft(name: String, orte: Array[Vector3]) -> void:
	var schritte: Array[float] = []
	for i in range(1, orte.size()):
		schritte.append(orte[i].distance_to(orte[i - 1]))
	var anzahl := maxf(float(schritte.size()), 1.0)
	var summe := 0.0
	for s in schritte:
		summe += s
	var mittel := summe / anzahl
	var quadrate := 0.0
	var still := 0
	for s in schritte:
		quadrate += (s - mittel) * (s - mittel)
		if s < mittel * 0.1:
			still += 1
	var streuung := sqrt(quadrate / anzahl) / maxf(mittel, 0.000001)
	print("  %s         Weg je Bild %.4f m, Streuung %.3f, Stillstand %d %%" % [
			name, mittel, streuung, roundi(100.0 * still / anzahl)])


# ---------------------------------------------------------------- Wächter

func _wache_starten(szene: Node) -> void:
	_knoten.clear()
	_stand.clear()
	_im_bild.clear()
	_in_physik.clear()
	for k in szene.find_children("*", "Node3D", true, false):
		var n := k as Node3D
		_knoten.append(n)
		_stand[n.get_instance_id()] = n.transform
	_phase = "bild"
	_wache = true


## Erster Physikschritt nach einem Bild: Alles, was sich seit dem letzten
## `process_frame` bewegt hat, geschah im Bildtakt – in `_process`, in
## Tweens, Zeitgebern oder Aufschüben. Bis auf eines: Körper, die der
## Physikserver führt, übernehmen ihren Stand am Anfang des Schritts,
## noch vor diesem Signal (siehe `_vom_server`).
func _auf_physik() -> void:
	if not _wache:
		return
	if _phase == "bild":
		_vergleichen(true)
	_phase = "physik"


## Beginn eines Bildes: Was sich seitdem bewegt hat, geschah in den
## Physikschritten dazwischen – oder, gab es keinen, im letzten Bild.
func _auf_bild() -> void:
	if not _wache:
		return
	_vergleichen(_phase == "bild")
	_phase = "bild"


func _vergleichen(im_bildtakt: bool) -> void:
	for n in _knoten:
		if not is_instance_valid(n) or not n.is_inside_tree():
			continue
		var id := n.get_instance_id()
		var jetzt := n.transform
		var vorher: Transform3D = _stand.get(id, jetzt)
		if jetzt.is_equal_approx(vorher):
			continue
		_stand[id] = jetzt
		if not n.is_visible_in_tree():
			continue
		var zaehler := _im_bild if im_bildtakt and not _vom_server(n) else _in_physik
		zaehler[id] = int(zaehler.get(id, 0)) + 1


## Führt der Physikserver diesen Körper? Eine `AnimatableBody3D` mit
## `sync_to_physics` bekommt ihre Lage in `PhysicsServer3D.sync()` zurück –
## nach dem Vorbereiten der Interpolation, aber vor `physics_frame`. Das
## ist Physiktakt, auch wenn es vor dem Signal geschieht.
func _vom_server(n: Node3D) -> bool:
	if n is AnimatableBody3D:
		return (n as AnimatableBody3D).sync_to_physics
	return n is RigidBody3D


## Meldet auffällige Knoten, gruppiert nach dem Skript, das sie baut: 60
## Baumkronen sind EIN Befund, nicht sechzig.
func _auffaellige(szene: Node) -> void:
	var gruppen := {}   # Schlüssel -> [Art, Zahl, meiste Bilder]
	var zittern := 0
	var stufen := 0
	for n in _knoten:
		if not is_instance_valid(n):
			continue
		var id := n.get_instance_id()
		var bild := int(_im_bild.get(id, 0))
		var physik := int(_in_physik.get(id, 0))
		var art := ""
		var bilder := 0
		if bild >= MINDEST_BILDER and n.is_physics_interpolated_and_enabled():
			art = "ZITTERT"
			bilder = bild
			zittern += 1
		elif physik >= MINDEST_BILDER and get_tree().physics_interpolation \
				and not n.is_physics_interpolated():
			art = "STUFT"
			bilder = physik
			stufen += 1
		if art.is_empty():
			continue
		var schluessel := "%s %s" % [art, _benennen(szene, n)]
		var eintrag: Array = gruppen.get(schluessel, [art, 0, 0])
		eintrag[1] = int(eintrag[1]) + 1
		eintrag[2] = maxi(int(eintrag[2]), bilder)
		gruppen[schluessel] = eintrag
	for schluessel: String in gruppen:
		var eintrag: Array = gruppen[schluessel]
		_fehler += 1
		var was := "Bildern im Bildtakt bewegt, aber interpoliert" \
				if eintrag[0] == "ZITTERT" else "Physikschritten bewegt, aber nicht interpoliert"
		print("  %s – %d Knoten, bis %d %s" % [schluessel, eintrag[1], eintrag[2], was])
	print("  Knoten: %d beobachtet, %d zittern, %d stufen" % [
			_knoten.size(), zittern, stufen])


## "baum.gd: Krone" – das nächste Skript über dem Knoten und der Weg von
## dort. Namen, die Godot selbst vergibt (@Node3D@123), werden zur Klasse.
func _benennen(szene: Node, n: Node) -> String:
	var teile: PackedStringArray = []
	var k: Node = n
	while k != null and k != szene:
		var name := String(k.name)
		teile.insert(0, k.get_class() if name.begins_with("@") else name)
		if k.get_script() != null:
			return "%s: %s" % [(k.get_script() as Script).resource_path.get_file(),
					"/".join(teile)]
		k = k.get_parent()
	return "/".join(teile)
