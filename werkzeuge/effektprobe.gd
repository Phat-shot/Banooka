extends Node3D
## Prüfstand für `Effekte` (scripts/effekte.gd): jeder Effekt einzeln,
## nebeneinander, in einer kleinen beleuchteten Szene.
##
## Vorbild ist die Werkstatt für Levelbauteile: Ein Effekt, den man nur im
## Level sieht, sieht man nie allein – immer zwischen Kisten, Laub und
## Nebel, und nie zweimal gleich. Hier steht jeder an seinem Platz, mit
## Schild, vor hellem Boden UND dunkler Wand (additive Funken verschwinden
## vor Hellem, Rauch vor Dunklem – beides muss man sehen).
##
## Zwei Betriebsarten:
## * MIT BILDSCHIRM und `EFFEKTPROBE_ZIEL`: Fotos in drei Momenten einer
##   Welle (kurz nach dem Zünden, Mitte, spät), dazu ein Bild mit Bildblitz.
## * HEADLESS (ohne Ziel): nur die Logik. Grenze je Bild, Aufräumen,
##   Lichtgrenze, Kameravertrag, `reduziert`, Trefferpause aus.
## In beiden Fällen: Rückgabe 0 = sauber, 1 = Fehler, und am Ende eine
## Zeile „=== Effektprobe: … ===".
##
## Aufruf mit Fotos (Software-GL unter Xvfb, auf einer Kopie des Projekts,
## damit der .godot-Cache anderer Läufe unberührt bleibt):
##   K=$(mktemp -d); cp -r . $K/; rm -rf $K/.godot $K/.git $K/export
##   godot --headless --path $K --import >/dev/null 2>&1
##   EFFEKTPROBE_ZIEL=/tmp/effektprobe xvfb-run -a -s "-screen 0 1280x720x24" \
##       godot --path $K res://werkzeuge/Effektprobe.tscn --display-driver x11 \
##       --rendering-driver opengl3 --audio-driver Dummy \
##       --resolution 1280x720 --fixed-fps 30
## `--fixed-fps 30` macht jedes Bild genau 1/30 s lang – dann treffen die
## Fotos auf jedem Rechner denselben Moment der Welle.
##
## Nur Logik:
##   godot --headless --path $K res://werkzeuge/Effektprobe.tscn

## Abstand der Stationen in Metern.
const ABSTAND := 3.1
## Vordere Reihe (Stöße) und hintere Reihe (Größeres, Dauerhaftes).
const VORNE_Z := 1.5
const HINTEN_Z := -3.0
## Mitte der Portalscheibe (hintere Reihe, Mitte).
const PORTAL_MITTE := Vector3(0.0, 1.7, HINTEN_Z)
const PORTAL_RADIUS := 1.3

## Kamera, die den KAMERAVERTRAG aus `Effekte` erfüllt: Sie merkt sich die
## Aufrufe (für die Prüfung) und wackelt nach dem beschriebenen Modell –
## Maximum statt Summe, Abklingen, Ausschlag mit staerke².
class Probekamera extends Camera3D:
	var wucht := 0.0
	var aufrufe := 0
	var letzte := 0.0
	var _t := 0.0

	func erschuettern(staerke: float) -> void:
		aufrufe += 1
		letzte = staerke
		wucht = clampf(maxf(wucht, staerke), 0.0, 1.0)

	func _process(delta: float) -> void:
		if wucht <= 0.0:
			h_offset = 0.0
			v_offset = 0.0
			return
		wucht = maxf(wucht - delta * 2.2, 0.0)
		_t += delta
		var w := wucht * wucht
		h_offset = (sin(_t * 41.0) + 0.5 * sin(_t * 97.0 + 1.3)) * 0.22 * w
		v_offset = (cos(_t * 37.0) + 0.5 * sin(_t * 83.0 + 2.1)) * 0.22 * w


var _kamera: Probekamera = null
var _laeufer: Node3D = null
var _laufstaub: CPUParticles3D = null
var _portalstoff: ShaderMaterial = null
var _ziel := ""
var _pruefungen := 0
var _fehler := 0
var _zeit := 0.0


func _ready() -> void:
	_ziel = OS.get_environment("EFFEKTPROBE_ZIEL")
	var fotos := not _ziel.is_empty() and DisplayServer.get_name() != "headless"
	if fotos:
		DirAccess.make_dir_recursive_absolute(_ziel)
	print("=== Effektprobe (%s) ===" % ("mit Fotos nach " + _ziel if fotos else "nur Logik"))

	_baue_szene()
	# Ein paar Bilder Vorlauf: Texturen (GradientTexture2D) entstehen erst
	# am Bildende, Shader beim ersten Zeichnen.
	await _bilder(6)
	Effekte.vorwaermen(self)
	await _bilder(12)

	_pruefe_grenze_je_bild()
	await _warte_auf_leere(3.0)
	_pruefe_reduziert()
	await _warte_auf_leere(3.0)

	# --- Die Welle, dreimal fotografiert ---
	await _welle()
	await _bilder(2)
	await _foto("welle_1_frueh")
	await _bilder(4)
	await _foto("welle_2_mitte")
	await _bilder(8)
	await _foto("welle_3_spaet")
	_pruefe_lichtgrenze()

	# --- Bildblitz: liegt über der Welt, unter dem HUD ---
	await _warte_auf_leere(3.0)
	Effekte.bildblitz(self, Color(1.0, 0.35, 0.2, 0.45), 0.5)
	await _bilder(2)
	await _foto("bildblitz")
	_pruefe_bildblitz()

	# --- Portalscheibe aus der Nähe (für den Wirbel-Shader) ---
	await _warte_auf_leere(1.0)
	var bisher := _kamera.global_transform
	_kamera.global_position = PORTAL_MITTE + Vector3(0.6, 0.3, 3.4)
	_kamera.look_at(PORTAL_MITTE, Vector3.UP)
	await _bilder(3)
	await _foto("portal_nah_1")
	await _bilder(12)
	await _foto("portal_nah_2")
	_kamera.global_transform = bisher

	_pruefe_kamera()
	await _pruefe_trefferpause()

	await _warte_auf_leere(4.0)
	_pruefe("alle Stöße aufgeräumt", Effekte.aktive() == 0,
			"%d leben noch" % Effekte.aktive())
	_pruefe("alle Blitzlichter aus", Effekte.lichter() == 0,
			"%d leuchten noch" % Effekte.lichter())

	print("=== Effektprobe: %d Prüfungen, %d Fehler ===" % [_pruefungen, _fehler])
	get_tree().quit(1 if _fehler > 0 else 0)


func _process(delta: float) -> void:
	_zeit += delta
	# Der Läufer pendelt vor der vorderen Reihe hin und her und zieht
	# eine Laufstaubspur hinter sich her.
	if is_instance_valid(_laeufer):
		_laeufer.position.x = sin(_zeit * 0.9) * 6.0
	if _portalstoff != null:
		_portalstoff.set_shader_parameter("puls", 0.5 + 0.5 * sin(_zeit * 3.1))


# ---------------------------------------------------------------- Welle

## Zündet alle Stöße an ihren Stationen – verteilt auf zwei Bilder, weil
## es zusammen mehr sind als `Effekte.MAX_JE_BILD`. Zuerst die langlebigen,
## dann die kurzen: So stehen auf dem ersten Foto alle zugleich.
func _welle() -> void:
	var vorne := _reihe(VORNE_Z)
	var hinten := _reihe(HINTEN_Z)
	var zahl := 0
	zahl += _gezaehlt(Effekte.rauch(self, vorne[4] + Vector3.UP * 0.4,
			Color(0.85, 0.82, 0.78), 0.9))
	zahl += _gezaehlt(Effekte.splitter(self, vorne[3] + Vector3.UP * 0.5,
			Materialbibliothek.kistenholz(Farben.HOLZ), 10))
	zahl += _gezaehlt(Effekte.lichtsaeule(self, hinten[1], Farben.KISTE_CHECKPOINT))
	zahl += _gezaehlt(Effekte.staubwolke(self, vorne[0], 1.0))
	var licht := Effekte.blitzlicht(self, hinten[3] + Vector3.UP * 1.4,
			Farben.GLUT, 8.0, 6.0, 0.8)
	_pruefe("Blitzlicht entsteht", licht != null, "null")
	Effekte.erschuettern(self, 0.5)
	await get_tree().process_frame
	zahl += _gezaehlt(Effekte.funken(self, vorne[1] + Vector3.UP * 0.6,
			Farben.FRUCHT, 16, 4.5))
	zahl += _gezaehlt(Effekte.aufblitzen(self, vorne[2] + Vector3.UP * 0.9,
			Color(1.0, 0.9, 0.7), 1.6, 0.3))
	zahl += _gezaehlt(Effekte.ring(self, hinten[0] + Vector3.UP * 0.06,
			Farben.SPIN_RING, 2.0, 0.6))
	zahl += _gezaehlt(Effekte.ring(self, PORTAL_MITTE + Vector3.BACK * 0.05,
			Farben.PORTAL_START.lightened(0.3), PORTAL_RADIUS + 0.45, 0.6,
			Vector3.BACK))
	_pruefe("Welle zündet alle Stöße", zahl == 8, "%d von 8" % zahl)


func _gezaehlt(p: CPUParticles3D) -> int:
	return 1 if p != null else 0


# ---------------------------------------------------------------- Prüfungen

## Mehr Stöße in einem Bild als erlaubt: Genau `MAX_JE_BILD` dürfen durch.
## Unter dem Boden gezündet, damit sie keines der Fotos stören.
func _pruefe_grenze_je_bild() -> void:
	var durch := 0
	for i in Effekte.MAX_JE_BILD + 4:
		durch += _gezaehlt(Effekte.funken(self, Vector3(0.0, -6.0, 0.0),
				Color.WHITE, 4))
	_pruefe("Grenze je Bild", durch == Effekte.MAX_JE_BILD,
			"%d statt %d durchgelassen" % [durch, Effekte.MAX_JE_BILD])


func _pruefe_reduziert() -> void:
	var vorher := Effekte.reduziert
	Effekte.reduziert = true
	var aufrufe := _kamera.aufrufe
	Effekte.erschuettern(self, 0.8)
	var p := Effekte.funken(self, Vector3(0.0, -6.0, 0.0), Color.WHITE, 10)
	var licht := Effekte.blitzlicht(self, Vector3(0.0, -6.0, 0.0), Color.WHITE)
	Effekte.reduziert = vorher
	_pruefe("reduziert: kein Wackeln", _kamera.aufrufe == aufrufe, "Kamera gerufen")
	_pruefe("reduziert: halbe Menge", p != null and p.amount == 5,
			"Menge %d" % (p.amount if p != null else -1))
	_pruefe("reduziert: kein Blitzlicht", licht == null, "Licht entstand")


## Drei Lichter auf einmal: Nur so viele dürfen entstehen, wie bis zur
## Grenze noch Platz ist (das Licht der Welle kann noch leuchten).
func _pruefe_lichtgrenze() -> void:
	var frei := Effekte.MAX_LICHTER - Effekte.lichter()
	var neu := 0
	for i in 3:
		if Effekte.blitzlicht(self, Vector3(0.0, -6.0, 0.0), Color.WHITE, 0.1) != null:
			neu += 1
	_pruefe("Lichtgrenze", neu == frei and Effekte.lichter() == Effekte.MAX_LICHTER,
			"%d neu bei %d frei, %d Lichter" % [neu, frei, Effekte.lichter()])


func _pruefe_bildblitz() -> void:
	var schicht := get_node_or_null("Bildblitz") as CanvasLayer
	_pruefe("Bildblitz hat eine Schicht", schicht != null, "keine Schicht")
	if schicht != null:
		_pruefe("Bildblitz liegt unter dem HUD", schicht.layer < 1,
				"Ebene %d" % schicht.layer)
	# Zweiter Blitz im selben Bild: dieselbe Schicht, keine zweite.
	Effekte.bildblitz(self, Color(1, 1, 1, 0.2), 0.2)
	var zahl := 0
	for k in get_children():
		if k is CanvasLayer:
			zahl += 1
	_pruefe("Bildblitz baut nur eine Schicht", zahl == 1, "%d Schichten" % zahl)


## Kameravertrag: Effekte ruft `erschuettern` per Duck-Typing, rechnet den
## Abstand ein und ruft ab `ABFALL_WEITE` gar nicht mehr.
func _pruefe_kamera() -> void:
	_pruefe("Welle hat die Kamera gerufen", _kamera.aufrufe >= 1,
			"%d Aufrufe" % _kamera.aufrufe)
	var vorher := _kamera.aufrufe
	Effekte.erschuettern(self, 0.9, _kamera.global_position + Vector3.RIGHT * 100.0)
	_pruefe("zu weit weg: kein Wackeln", _kamera.aufrufe == vorher, "gerufen")
	Effekte.erschuettern(self, 0.8, _kamera.global_position + Vector3.RIGHT * 7.0)
	_pruefe("halber Abstand: halbe Wucht",
			_kamera.aufrufe == vorher + 1 and is_equal_approx(_kamera.letzte, 0.4),
			"Wert %.3f" % _kamera.letzte)


## Mit Bildschirm muss das Tempo sinken und von selbst zurückkommen; im
## Headless-Betrieb darf es sich gar nicht rühren.
func _pruefe_trefferpause() -> void:
	Effekte.trefferpause(self, 0.1)
	if DisplayServer.get_name() == "headless":
		_pruefe("Trefferpause headless aus", is_equal_approx(Engine.time_scale, 1.0),
				"Tempo %.2f" % Engine.time_scale)
		return
	_pruefe("Trefferpause bremst", is_equal_approx(Engine.time_scale, Effekte.PAUSE_TEMPO),
			"Tempo %.2f" % Engine.time_scale)
	# Eine zweite Pause im selben Moment darf nichts verlängern.
	Effekte.trefferpause(self, 0.2)
	await get_tree().create_timer(0.4, true, false, true).timeout
	_pruefe("Trefferpause endet", is_equal_approx(Engine.time_scale, 1.0),
			"Tempo %.2f" % Engine.time_scale)
	Engine.time_scale = 1.0


func _pruefe(was: String, gut: bool, sonst: String) -> void:
	_pruefungen += 1
	if gut:
		print("  ok      %s" % was)
	else:
		_fehler += 1
		print("  FEHLER  %s: %s" % [was, sonst])


# ---------------------------------------------------------------- Warten, Fotos

func _bilder(anzahl: int) -> void:
	for i in anzahl:
		await get_tree().process_frame


## Wartet, bis alle Stöße aufgeräumt sind – höchstens `hoechstens` Sekunden.
func _warte_auf_leere(hoechstens: float) -> void:
	var bis := _zeit + hoechstens
	while (Effekte.aktive() > 0 or Effekte.lichter() > 0) and _zeit < bis:
		await get_tree().process_frame


func _foto(name: String) -> void:
	if _ziel.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var pfad := "%s/%s.png" % [_ziel, name]
	var fehler := get_viewport().get_texture().get_image().save_png(pfad)
	print("  %s  %s" % ["foto  " if fehler == OK else "FEHLER", pfad])


# ---------------------------------------------------------------- Aufbau

func _reihe(z: float) -> Array[Vector3]:
	var r: Array[Vector3] = []
	for i in 5:
		r.append(Vector3((float(i) - 2.0) * ABSTAND, 0.0, z))
	return r


func _baue_szene() -> void:
	var we := WorldEnvironment.new()
	var welt := Environment.new()
	welt.background_mode = Environment.BG_COLOR
	welt.background_color = Farben.HIMMEL_UNTEN
	welt.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	welt.ambient_light_color = Color(0.62, 0.68, 0.74)
	welt.ambient_light_energy = 0.45
	welt.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = welt
	add_child(we)

	var sonne := DirectionalLight3D.new()
	sonne.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(28.0), 0.0)
	sonne.light_energy = 1.0
	sonne.shadow_enabled = true
	add_child(sonne)

	# Boden erdig wie der Waldweg, Wand dunkel – siehe Kopfkommentar.
	_quader(Vector3(0.0, -0.05, -1.0), Vector3(26.0, 0.1, 16.0), Farben.ERDE)
	_quader(Vector3(0.0, 3.0, -5.6), Vector3(26.0, 6.0, 0.6), Farben.FELS_DUNKEL)

	var namen_vorne := ["staubwolke", "funken", "aufblitzen", "splitter", "rauch"]
	var namen_hinten := ["ring", "lichtsaeule", "wirbelstoff", "blitzlicht\ndauerfunken",
			"blobschatten"]
	var vorne := _reihe(VORNE_Z)
	var hinten := _reihe(HINTEN_Z)
	# Die Schilder der vorderen Reihe liegen vorn am Boden – oben
	# stünden sie vor der hinteren Reihe.
	for i in 5:
		_schild(vorne[i] + Vector3(0.0, 0.15, 1.3), String(namen_vorne[i]))
		_schild(hinten[i] + Vector3(0.0, 3.7, 0.0), String(namen_hinten[i]))

	# Eine Kiste an der Splitterstation, damit man die Bretter mit dem
	# Original vergleichen kann.
	var kiste := _quader(vorne[3] + Vector3(1.0, 0.25, 0.4), Vector3(0.5, 0.5, 0.5),
			Farben.HOLZ)
	kiste.material_override = Materialbibliothek.kistenholz(Farben.HOLZ)

	# Portal: Wirbelscheibe im leuchtenden Ring, wie später portal.gd.
	var scheibe := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * PORTAL_RADIUS * 2.0
	scheibe.mesh = quad
	_portalstoff = Effekte.wirbelstoff(Farben.PORTAL_START)
	scheibe.material_override = _portalstoff
	scheibe.position = PORTAL_MITTE
	scheibe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(scheibe)
	var torus := TorusMesh.new()
	torus.inner_radius = PORTAL_RADIUS
	torus.outer_radius = PORTAL_RADIUS + 0.16
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.position = PORTAL_MITTE
	# Schwächer als in portal.gd (2.2): Hier soll die Scheibe beurteilt
	# werden, nicht der Rahmen.
	ring.material_override = Materialbibliothek.leuchtend(Farben.PORTAL_START, 1.1)
	add_child(ring)

	# Blitzlicht-Station: eine helle Kugel, an der man das Licht sieht, und
	# eine „TNT-Kiste" mit glimmender Zündschnur (dauerfunken).
	_kugel(hinten[3] + Vector3(-0.7, 0.6, 0.3), 0.6, Farben.FELS_HELL)
	var tnt := _quader(hinten[3] + Vector3(0.8, 0.35, 0.3), Vector3(0.7, 0.7, 0.7),
			Farben.KISTE_TNT)
	Effekte.dauerfunken(tnt, Vector3(0.0, 0.4, 0.0))

	# Blobschatten unter einer schwebenden Kugel – ohne Physik: Der Boden
	# ist hier flach, der „Strahl" trifft bei y = 0.
	var schwebend := _kugel(hinten[4] + Vector3(0.0, 1.8, 0.0), 0.35, Farben.FELL)
	var fleck := Effekte.blobschatten(schwebend, 0.5)
	Effekte.blobschatten_setzen(fleck, hinten[4], Vector3.UP, 0.5)

	# Läufer mit Laufstaub vor der vorderen Reihe.
	_laeufer = Node3D.new()
	_laeufer.name = "Laeufer"
	_laeufer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_laeufer.position = Vector3(0.0, 0.0, 3.4)
	add_child(_laeufer)
	_kugel(Vector3(0.0, 0.3, 0.0), 0.3, Farben.FELL, _laeufer)
	_laufstaub = Effekte.dauerstaub(_laeufer, true)
	_laufstaub.emitting = true

	_kamera = Probekamera.new()
	_kamera.name = "Kamera"
	# Etwa so weit weg wie die Spielkamera von der Figur (7 bis 11 m):
	# Größen, die hier stimmen, stimmen auch im Level.
	_kamera.fov = 60.0
	_kamera.position = Vector3(0.0, 3.8, 9.4)
	add_child(_kamera)
	_kamera.look_at(Vector3(0.0, 1.2, -1.0), Vector3.UP)
	_kamera.current = true


func _quader(mitte: Vector3, groesse: Vector3, farbe: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var netz := BoxMesh.new()
	netz.size = groesse
	mi.mesh = netz
	mi.position = mitte
	mi.material_override = Materialbibliothek.einfarbig(farbe)
	add_child(mi)
	return mi


func _kugel(mitte: Vector3, radius: float, farbe: Color,
		eltern: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var netz := SphereMesh.new()
	netz.radius = radius
	netz.height = radius * 2.0
	mi.mesh = netz
	mi.position = mitte
	mi.material_override = Materialbibliothek.einfarbig(farbe, 0.6)
	if eltern != null:
		eltern.add_child(mi)
	else:
		add_child(mi)
	return mi


func _schild(ort: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = ort
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 56
	l.pixel_size = 0.005
	l.outline_size = 14
	l.modulate = Color(1.0, 0.97, 0.9)
	l.outline_modulate = Color(0.08, 0.06, 0.05)
	add_child(l)
