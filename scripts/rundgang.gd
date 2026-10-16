extends RefCounted
class_name Rundgang
## Vorwärmen unter dem Ladeschirm: Eine eigene Kamera in einem eigenen,
## kleinen Viewport derselben Welt zeigt der Reihe nach eine Liste von
## Blicken, je Blick ein Bild. Genutzt von `LevelBasis` (Blicke entlang
## des Verlaufs, `blicke_entlang`) und vom Portalraum (Blicke der
## Folgekamera über Halle und Räume).
##
## WARUM. Der Compatibility-Renderer (OpenGL ES 3, WebGL 2) übersetzt die
## Fassung eines Shaders erst, wenn das erste Objekt damit gezeichnet wird
## – mit Nebel, Schattenstufen, Instanzen, Lichtern, je nachdem, wo es
## steht. Auf dem Handy kostet jede Fassung Dutzende Millisekunden, und
## sie fielen genau dann an, wenn beim Laufen oder Wenden etwas Neues ins
## Bild kam: „es lädt bei jeder Bewegung nach". Gemessen mit der
## Ruckelprobe (Level 01, Handyweg, llvmpipe): ohne Rundgang 16 Ruckler
## im ersten Durchgang (bis 2,9 s), im zweiten nur noch einer – es war
## Arbeit beim ersten Gebrauch, keine in jedem Bild.
##
## Gezeichnet werden die echten Objekte an ihren echten Orten, also auch
## mit den Lichtern und Schatten, die sie im Spiel haben. Die Sichtweiten
## (`visibility_range`) gelten von jeder Kamera aus; wer die Blicke
## wählt, bringt jedes Objekt einmal nah genug heran.
##
## In einem EIGENEN, kleinen Viewport in derselben Welt: Übersetzte Shader
## gelten für alle Viewports, aber die Sichtweiten merken sich je Viewport,
## was zuletzt zu sehen war (der Rand `visibility_range_end_margin` wirkt
## als Hysterese). Fuhr die Spielkamera selbst die Runde, standen bei 70 m
## danach Kronen im Bild, die dort sonst fehlen (gerendert). Der Viewport
## übernimmt alles, was die Shaderfassung bestimmt (MSAA, 3D-Skalierung,
## HDR, Schattenatlas für Punktlichter), nur nicht die Größe. Das Hauptbild
## zeichnet solange kein 3D (`disable_3d`): Es liegt hinter dem
## Ladeschirm, zeichnete aber jedes Bild die volle Szene mit – auf dem
## Handy die Hälfte der Rundgangszeit.
##
## Headless (Prüfwerkzeuge) wird nichts gezeichnet – dort entfällt er.

## Breite des Rundgang-Viewports in Bildpunkten (Höhe nach dem Seiten-
## verhältnis des Fensters). Die Shaderfassung hängt nicht an der Größe,
## die Füllrate schon.
const BREITE := 320
## Text auf dem Ladeschirm, solange der Rundgang läuft.
const TEXT := "Licht und Schatten werden vorbereitet"
## Aus nur zum Vergleichen (`werkzeuge/ruckelprobe.gd`, RUCKEL_VORWAERMEN=0).
static var an := true


## Fällt der Rundgang hier weg (abgeschaltet oder headless)?
static func entfaellt() -> bool:
	return not an or DisplayServer.get_name() == "headless"


## Zeigt jeden Blick ein Bild lang. `bei` hängt in der Welt, die gezeichnet
## wird (Level, Portalraum), und trägt den Viewport. `vorbild` ist die
## Spielkamera: Sichtfeld, Nah- und Fernebene, Ebenenmaske und Umgebung
## kommen von ihr; ohne sie gelten die Vorgaben von `Camera3D`. Der
## Ladebalken läuft dabei von `von` bis `bis`.
##
## Rückgabe: false, wenn `bei` unterwegs den Baum verlassen hat (dann
## nichts mehr anfassen).
static func fahren(bei: Node, blicke: Array[Transform3D], vorbild: Camera3D,
		von := 0.95, bis := 1.0) -> bool:
	if entfaellt() or blicke.is_empty() or not bei.is_inside_tree():
		return true
	var haupt := bei.get_viewport()
	var buehne := SubViewport.new()
	buehne.name = "Rundgang"
	var flaeche := haupt.get_visible_rect().size
	var seitenverhaeltnis := flaeche.x / maxf(flaeche.y, 1.0)
	buehne.size = Vector2i(BREITE, maxi(16, roundi(BREITE / seitenverhaeltnis)))
	buehne.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	buehne.msaa_3d = haupt.msaa_3d
	buehne.scaling_3d_mode = haupt.scaling_3d_mode
	buehne.scaling_3d_scale = haupt.scaling_3d_scale
	buehne.use_hdr_2d = haupt.use_hdr_2d
	buehne.use_debanding = haupt.use_debanding
	buehne.positional_shadow_atlas_size = haupt.positional_shadow_atlas_size
	buehne.positional_shadow_atlas_16_bits = haupt.positional_shadow_atlas_16_bits
	for quadrant in 4:
		buehne.set_positional_shadow_atlas_quadrant_subdiv(quadrant,
				haupt.get_positional_shadow_atlas_quadrant_subdiv(quadrant))
	var kamera := Camera3D.new()
	# Im Bildtakt versetzt, nie bewegt.
	kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if vorbild != null:
		kamera.fov = vorbild.fov
		kamera.near = vorbild.near
		kamera.far = vorbild.far
		kamera.cull_mask = vorbild.cull_mask
		kamera.environment = vorbild.environment
		kamera.attributes = vorbild.attributes
	buehne.add_child(kamera)
	bei.add_child(buehne)
	kamera.current = true
	var hauptbild_aus := haupt.disable_3d
	haupt.disable_3d = true
	var baum := bei.get_tree()
	for i in blicke.size():
		kamera.global_transform = blicke[i]
		# `process_frame`, nicht `frame_post_draw`: Das nächste
		# `process_frame` kommt nach dem Zeichnen dieses Bildes, und anders
		# als `frame_post_draw` kommt es auch, wenn nicht gezeichnet wird
		# (Fenster verkleinert) – der Aufbau hinge sonst.
		await baum.process_frame
		if not is_instance_valid(bei) or not bei.is_inside_tree():
			haupt.disable_3d = hauptbild_aus
			return false
		Ladeschirm.fortschritt(lerpf(von, bis, float(i + 1) / float(blicke.size())), TEXT)
	haupt.disable_3d = hauptbild_aus
	buehne.queue_free()
	return true


## Nach dem Rundgang, noch unter dem Ladeschirm: zwei Bilder, in denen
## das Hauptbild wieder zeichnet (das erste ist so lang wie dieses erste
## Zeichnen), dann die Teilchen und die verborgenen Netze
## (`Effekte.vorwaermen`, die Kamera steht dafür wieder an ihrem Platz),
## dann noch zwei Bilder, in denen sie gezeichnet werden. Erst danach darf
## der Ladeschirm ausblenden.
##
## Gemessen (Ruckelprobe, Level 01, Handyweg, llvmpipe): Rief das Level
## `Effekte.vorwaermen` und blendete gleich aus, kosteten die beiden ersten
## Bilder nach dem Ladeschirm 1,6 und 1,1 s Rechenzeit – mitten im
## Ausblenden; mit den vier Bildern höchstens 81 ms. Läuft auch headless.
##
## Rückgabe: false, wenn `bei` unterwegs den Baum verlassen hat.
static func ausklingen(bei: Node) -> bool:
	var baum := bei.get_tree()
	for i in 2:
		await baum.process_frame
		if not is_instance_valid(bei) or not bei.is_inside_tree():
			return false
	Effekte.vorwaermen(bei)
	for i in 2:
		await baum.process_frame
		if not is_instance_valid(bei) or not bei.is_inside_tree():
			return false
	return true


## Blicke einer Korridorkamera entlang einer Kurve: alle `abstand_halte` m
## ein Halt, die Kamera `abstand` m dahinter und `hoehe` m darüber, mit
## Blick auf den Punkt `vorlauf` m voraus; je Halt ein Blick je Eintrag in
## `gieren` (Grad gegen den Weg). Zwei Blicke zu je rund 97° Breite (16:9)
## decken mit ±40° zusammen 177° ab – mehr, als die Korridorkamera je zur
## Seite schaut (gemessen bis 38°).
static func blicke_entlang(kurve: Curve3D, abstand: float, hoehe: float,
		vorlauf: float, abstand_halte := 12.0,
		gieren: Array[float] = [40.0, -40.0]) -> Array[Transform3D]:
	var blicke: Array[Transform3D] = []
	if kurve == null:
		return blicke
	var laenge := kurve.get_baked_length()
	if laenge <= 0.0:
		return blicke
	var halte := maxi(1, ceili(laenge / abstand_halte) + 1)
	for i in halte:
		var s := minf(float(i) * abstand_halte, laenge)
		var auge := LevelWerkzeuge.punkt_frei(kurve, s - abstand, 0.0, hoehe)
		var ziel := LevelWerkzeuge.punkt(kurve, s + vorlauf, 0.0, 1.0)
		if auge.distance_to(ziel) < 0.5:
			continue
		var blick := Basis.looking_at(ziel - auge, Vector3.UP)
		for grad in gieren:
			blicke.append(Transform3D(Basis(Vector3.UP, deg_to_rad(grad)) * blick, auge))
	return blicke
