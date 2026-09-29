extends Area3D
class_name Portal
## Leuchtendes Portal – als Startportal (Levelanfang) oder Zielportal.
##
## Optik: ein aufrecht stehender Ring mit einer wirbelnden Scheibe darin
## (`shaders/portal_wirbel.gdshader`), ein Funkenkranz, ein Lichtfleck am
## Boden und ein pulsierendes Licht. Das Zielportal trägt zusätzlich eine
## Lichtsäule, die man schon vom Anfang des Korridors über dem Weg sieht.
## Die Farbe kommt aus `Farben`.
##
## Startportal (`ist_ziel = false`): passiv. Beim Levelstart blendet es sich
## ein und der Spieler tritt daraus hervor. Sein Wirbel läuft nach außen.
## Zielportal (`ist_ziel = true`): saugt den Spieler ein und meldet
## `level_geschafft`. Sein Wirbel läuft nach innen.

## Wird ausgelöst, sobald der Spieler das Zielportal vollständig betreten hat.
signal level_geschafft

## True = Zielportal, False = Startportal.
@export var ist_ziel := false

## Radius des Rings in Metern.
@export_range(0.6, 3.0, 0.05) var radius := 1.15

## In diesem Umkreis gilt der Spieler beim Levelstart als "aus dem
## Startportal getreten" (nur beim Startportal).
@export_range(0.0, 12.0, 0.5) var auftritt_radius := 4.0

## Stärke des Funkenkranzes: Es kreisen doppelt so viele Funken.
@export_range(0, 24, 1) var funken_anzahl := 10

## Höhe der Lichtsäule über dem Zielportal in Metern, 0 = keine. Ein
## Level mit Decke oder Überhang über dem Ziel kann sie kürzen.
@export_range(0.0, 30.0, 0.5) var saeulen_hoehe := 14.0

const RING_DICKE := 0.16
const EINBLEND_ZEIT := 0.5
const AUFTRITT_SPERRE := 0.75
const EINSAUG_ZEIT := 0.6
const NACHRICHT_ZEIT := 4.0
const EDELSTEIN_VERZOEGERUNG := 1.6
## Deckkraft des Lichtflecks am Boden (additiv).
const FLECK_DECKKRAFT := 0.32

## Lichtsäule: additiver, offener Zylinder. Die Deckkraft läuft über die
## Höhe aus, Lichtbänder wandern aufwärts. Quer dazu ist sie in der Mitte
## am hellsten und läuft zum Umriss weich aus (d² ≈ 1 − x² über die
## Breite) – so liest sie sich als Lichtstrahl. Ein heller Umriss, wie im
## ersten Wurf, ergab aus der Nähe eine Glasröhre mit harten Kanten.
## Nur Vorderseiten (`cull_back`): Die Rückwand legte dasselbe Profil
## noch einmal darüber – doppelte Füllrate für ein Bild, das der hellere
## Kern auch allein trägt. Die Höhe kommt aus VERTEX.y, weil die UVs von
## Godots Zylinder nicht sauber 0..1 laufen.
const _SAEULEN_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(0.4, 0.85, 1.0, 1.0);
uniform float hoehe = 14.0;
uniform float staerke = 0.4;

varying float anteil;

void vertex() {
	anteil = clamp(VERTEX.y / hoehe + 0.5, 0.0, 1.0);
}

void fragment() {
	float oben_weg = pow(1.0 - anteil, 1.6);
	// Unten erst ab Ringhöhe voll: Das Portal selbst soll vor der Säule
	// stehen, nicht in einer Lichtwand.
	float fuss = smoothstep(0.0, 0.16, anteil);
	float baender = 0.7 + 0.3 * sin(anteil * 20.0 - TIME * 3.0);
	float d = abs(dot(NORMAL, VIEW));
	// Weicher Strahl mit hellerem Kern.
	float strahl = d * d + 0.4 * pow(d, 8.0);
	// Aus der Ferne ist sie der Wegweiser, aus der Nähe nur noch ein Hauch:
	// Dicht davor füllte sie sonst das halbe Bild und bleichte den Himmel.
	float fern = mix(0.2, 1.0, smoothstep(10.0, 35.0,
			distance(CAMERA_POSITION_WORLD, NODE_POSITION_WORLD)));
	ALBEDO = farbe.rgb * 1.5;
	ALPHA = clamp(oben_weg * fuss * baender * strahl * fern * staerke, 0.0, 1.0);
}
"""

@onready var _kollision: CollisionShape3D = $Kollision

var _optik: Node3D = null
var _scheibe: MeshInstance3D = null
var _scheibenstoff: ShaderMaterial = null
var _funken: CPUParticles3D = null
var _fleckstoff: StandardMaterial3D = null
var _licht: OmniLight3D = null
var _phase := 0.0
var _ausgeloest := false

# Einmal gebaut und von allen Portalen geteilt.
static var _saeulen_shader: Shader = null
static var _funkenlauf: Gradient = null


func _ready() -> void:
	# Das Portal steht still; bewegt wird darin nur im Bildtakt: die
	# atmende Scheibe, Ein- und Ausblenden, der Sog (`_process`, Tweens).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group("portale")
	add_to_group("zielportale" if ist_ziel else "startportale")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = ist_ziel
	_phase = randf() * TAU
	_form_anpassen()
	_baue_optik()

	if ist_ziel:
		if not body_entered.is_connected(_auf_koerper):
			body_entered.connect(_auf_koerper)
	else:
		_startauftritt()


## Farbe je nach Rolle.
func farbe() -> Color:
	return Farben.PORTAL_ZIEL if ist_ziel else Farben.PORTAL_START


# ---------------------------------------------------------------- Aufbau

func _form_anpassen() -> void:
	if _kollision == null:
		return
	var form := CylinderShape3D.new()
	form.radius = radius * 0.9
	form.height = radius * 2.0
	_kollision.shape = form
	_kollision.position = Vector3(0.0, radius, 0.0)


## Baut Ring, Scheibe, Funkenkranz, Licht und die Teile am Boden auf.
func _baue_optik() -> void:
	_optik = Node3D.new()
	_optik.name = "Optik"
	_optik.position = Vector3(0.0, radius, 0.0)
	add_child(_optik)

	var ton := farbe()

	# --- Ring (aufrecht stehend, Öffnung zeigt in Z-Richtung) ---
	var torus := TorusMesh.new()
	torus.inner_radius = radius
	torus.outer_radius = radius + RING_DICKE
	torus.rings = 40
	torus.ring_segments = 12
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = torus
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# Leuchtet in der eigenen Farbe, nicht weiß: Mit 2,2 brannte der Ring
	# zusammen mit dem Saum der Scheibe zu einem breiten weißen Reif aus.
	ring.material_override = Materialbibliothek.leuchtend(ton, 0.9)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_optik.add_child(ring)

	# --- Wirbelnde Scheibe ---
	# Ein Viereck von 2r × 2r, rund macht es der Shader. Es liegt schon in
	# der XY-Ebene, also quer zum Weg wie der Ring. Etwas größer als der
	# Innenradius, damit zwischen Scheibe und Ring kein Spalt klafft.
	var flaeche := QuadMesh.new()
	flaeche.size = Vector2.ONE * (radius + RING_DICKE * 0.4) * 2.0
	_scheibe = MeshInstance3D.new()
	_scheibe.name = "Scheibe"
	_scheibe.mesh = flaeche
	# Saum nur wenig heller als der Grundton: Mit dem Vorgabesaum (um 0,25
	# aufgehellt) las sich der Rand direkt am leuchtenden Ring aus
	# Spielentfernung fast weiß – das Tor soll seine Farbe behalten.
	_scheibenstoff = Effekte.wirbelstoff(ton, Effekte.KEINE_FARBE, ton.lightened(0.1))
	# Das Ziel saugt (Arme laufen nach innen), der Start stößt aus.
	_scheibenstoff.set_shader_parameter("richtung", -1.0 if ist_ziel else 1.0)
	_scheibe.material_override = _scheibenstoff
	_scheibe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_optik.add_child(_scheibe)

	_baue_funkenkranz(ton)

	# --- Schein ---
	_licht = OmniLight3D.new()
	_licht.name = "Schein"
	_licht.light_color = ton
	_licht.light_energy = 1.6
	_licht.omni_range = radius * 6.0
	_licht.shadow_enabled = false
	_optik.add_child(_licht)

	_baue_lichtfleck(ton)
	if ist_ziel and saeulen_hoehe > 0.0:
		_baue_saeule(ton)


## Funken, die um den Ring kreisen – EIN Teilchenemitter statt zehn
## einzelner Kugeln, die das Skript jedes Bild von Hand verschob. Ein
## Zeichenaufruf, und die Bahn rechnet die Engine.
##
## DREHACHSE = SCHWERKRAFT: `CPUParticles3D` rechnet die Richtung von
## `tangential_accel` als Kreuzprodukt aus Abstand zur Mitte und
## `gravity`. Ohne Schwerkraft ist sie null – der Kranz kreiste dann
## nicht, die Funken trieben nur geradeaus zur Mitte (so im ersten Wurf,
## per Sonde unter 4.7.2 nachgemessen). Ein Hauch Schwerkraft entlang der
## lokalen Y-Achse gibt die Achse vor und verschiebt die Funken in ihrer
## Lebenszeit um einen Millimeter. Der Emitter liegt um 90° gekippt, damit
## diese Achse durch die Öffnung des Rings zeigt. Lokale Koordinaten,
## damit der Kranz mit dem Portal ein- und ausblendet.
##
## Drehsinn wie die Scheibe: Mit +Y als Achse kreist ein positives
## `tangential_accel`, von vorn (+Z) gesehen, im Uhrzeigersinn – so wie
## der Wirbel mit `richtung = -1` (Ziel). Das Startportal dreht umgekehrt.
func _baue_funkenkranz(ton: Color) -> void:
	if funken_anzahl <= 0:
		return
	var p := CPUParticles3D.new()
	p.name = "Funken"
	p.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	p.local_coords = true
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Wie jeder Emitter aus `Effekte`: auf Handys halbiert.
	p.amount = maxi(1, roundi(funken_anzahl * 2 * (0.5 if Effekte.reduziert else 1.0)))
	p.lifetime = 1.4
	p.lifetime_randomness = 0.3
	# Schon beim ersten Bild ein voller Kranz, nicht erst nach 1,4 s.
	p.preprocess = 1.5
	p.mesh = Effekte.teilchen_netz()
	p.material_override = Effekte.stoff(Effekte.Stoff.ADDITIV)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_height = 0.3
	p.gravity = Vector3(0.0, 0.001, 0.0)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.25
	if ist_ziel:
		# Von außen zum Ring gezogen und dabei im Kreis gerissen: ein Sog.
		# Zug und Drall halten sich die Waage – die Funken enden auf dem
		# Ring nach 60 bis 90° Umlauf, statt quer über die Scheibe zu ziehen.
		p.emission_ring_radius = radius + RING_DICKE + 0.55
		p.emission_ring_inner_radius = radius + RING_DICKE + 0.15
		p.radial_accel_min = -1.5
		p.radial_accel_max = -1.0
		p.tangential_accel_min = 1.6
		p.tangential_accel_max = 2.4
	else:
		# Vom Ring nach außen gestoßen, andersherum kreisend.
		p.emission_ring_radius = radius + RING_DICKE + 0.2
		p.emission_ring_inner_radius = radius + RING_DICKE
		p.radial_accel_min = 0.4
		p.radial_accel_max = 0.9
		p.tangential_accel_min = -2.0
		p.tangential_accel_max = -1.2
	p.damping_min = 0.3
	p.damping_max = 0.6
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.2
	p.color = ton.lightened(0.45)
	p.color_ramp = _funkenlauf_holen()
	_optik.add_child(p)
	_funken = p


## Weich ein, lang sichtbar, weich aus – ein Funke, der aus dem Nichts
## in voller Größe erscheint, flackert.
static func _funkenlauf_holen() -> Gradient:
	if _funkenlauf == null:
		_funkenlauf = Gradient.new()
		_funkenlauf.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
		_funkenlauf.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1),
				Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	return _funkenlauf


## Heller Fleck am Boden vor und unter dem Portal: Das Portal steht damit
## IN der Szene statt davor, auch dort, wo sein Punktlicht nicht hinreicht.
## Nicht breiter als das Portal selbst: Der weiche Fleck hat bis weit nach
## außen Körper, und auf schmalen Stegen glühte ein größerer in der Luft
## neben dem Weg.
func _baue_lichtfleck(ton: Color) -> void:
	var netz := PlaneMesh.new()
	netz.size = Vector2(radius * 2.4, radius * 2.4)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_receive_shadows = true
	m.albedo_texture = Effekte.weiche_textur()
	m.albedo_color = Color(ton.r, ton.g, ton.b, FLECK_DECKKRAFT)
	_fleckstoff = m
	var fleck := MeshInstance3D.new()
	fleck.name = "Lichtfleck"
	fleck.mesh = netz
	fleck.material_override = m
	fleck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Das Portal steht 10 cm über dem Weg; 5 cm Abstand zum Boden, damit
	# der Fleck aus der Ferne nicht mit ihm flimmert.
	fleck.position = Vector3(0.0, -0.05, 0.0)
	add_child(fleck)


## Die Lichtsäule über dem Zielportal – das Ziel sieht man schon vom
## Levelanfang, lange bevor das Portal selbst ins Bild kommt.
func _baue_saeule(ton: Color) -> void:
	if _saeulen_shader == null:
		_saeulen_shader = Shader.new()
		_saeulen_shader.code = _SAEULEN_CODE
	var netz := CylinderMesh.new()
	# Schmaler als der Ring: ein Strahl, der aus dem Tor steigt, keine Röhre,
	# in der es steht.
	netz.top_radius = radius * 0.6
	netz.bottom_radius = radius * 0.6
	netz.height = saeulen_hoehe
	netz.radial_segments = 20
	netz.rings = 1
	netz.cap_top = false
	netz.cap_bottom = false
	var m := ShaderMaterial.new()
	m.shader = _saeulen_shader
	m.set_shader_parameter("farbe", ton)
	m.set_shader_parameter("hoehe", saeulen_hoehe)
	var saeule := MeshInstance3D.new()
	saeule.name = "Lichtsaeule"
	saeule.mesh = netz
	saeule.material_override = m
	saeule.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	saeule.position = Vector3(0.0, saeulen_hoehe * 0.5, 0.0)
	add_child(saeule)
	_vorwaermen(netz, m)


## Die Säule einmal vor der Kamera zeichnen lassen: Ihr Shader wird sonst
## erst übersetzt, wenn sie zum ersten Mal ins Bild kommt – mitten im
## Level, und im Browser stockt es dann spürbar. Deckkraft 0 über eine
## eigene Kopie; als Kind der Kamera bleibt sie im Bild, auch wenn die
## Kamera beim Aufbau noch springt.
func _vorwaermen(netz: Mesh, stoff: ShaderMaterial) -> void:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var unsichtbar := stoff.duplicate() as ShaderMaterial
	unsichtbar.set_shader_parameter("staerke", 0.0)
	var mi := MeshInstance3D.new()
	mi.name = "Vorwaermen"
	mi.mesh = netz
	mi.material_override = unsichtbar
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0.0, 0.0, -4.0)
	mi.scale = Vector3.ONE * 0.05
	kamera.add_child.call_deferred(mi)
	get_tree().create_timer(0.5).timeout.connect(mi.queue_free)


# ---------------------------------------------------------------- Animation

func _process(delta: float) -> void:
	_phase += delta
	if not is_instance_valid(_optik):
		return

	# Die Scheibe atmet: Der Shader wirbelt selbst (über TIME), das Skript
	# setzt nur noch den Puls – ein Wert je Bild statt Emission, Alpha
	# und zehn Funkenpositionen.
	var puls := 0.5 + 0.5 * sin(_phase * 3.1)
	if is_instance_valid(_scheibe):
		var s := 0.97 + puls * 0.03
		_scheibe.scale = Vector3(s, s, 1.0)
	if _scheibenstoff != null:
		_scheibenstoff.set_shader_parameter("puls", puls)
	if is_instance_valid(_licht):
		_licht.light_energy = 1.2 + puls * 1.0


## Blendet die Scheibe zwischen Ruhe (0) und Sog (1) über: Die Arme
## wickeln sich enger, die Mitte strahlt, alles wird heller.
func _scheibe_hochfahren(tween: Tween, ziel: float, dauer: float) -> void:
	var stoff := _scheibenstoff
	var von := 1.0 - ziel
	tween.tween_method(func(w: float) -> void:
			stoff.set_shader_parameter("drall", lerpf(4.0, 10.0, w))
			stoff.set_shader_parameter("sog", lerpf(0.7, 2.2, w))
			stoff.set_shader_parameter("helligkeit", lerpf(1.25, 1.9, w)),
			von, ziel, dauer).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


# ---------------------------------------------------------------- Startportal

## Blendet das Portal ein; ein Spieler in Reichweite tritt daraus hervor.
func _startauftritt() -> void:
	if _optik != null:
		_optik.scale = Vector3(0.05, 0.05, 0.05)
	# Der Fleck am Boden hängt nicht an `_optik` (er soll beim Aufblähen
	# nicht mitwandern) und blendet deshalb eigens mit auf – sonst
	# leuchtete er schon, bevor es das Tor gibt.
	if _fleckstoff != null:
		_fleckstoff.albedo_color.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(self):
		return

	var spieler := _spieler_in_reichweite()
	if spieler != null and "gesperrt" in spieler:
		spieler.gesperrt = true

	if is_instance_valid(_optik):
		var tween := create_tween()
		tween.tween_property(_optik, "scale", Vector3.ONE, EINBLEND_ZEIT) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _fleckstoff != null:
			tween.parallel().tween_property(_fleckstoff, "albedo_color:a",
					FLECK_DECKKRAFT, EINBLEND_ZEIT)
		# Das Tor geht mit einem Lichtschlag auf.
		Effekte.aufblitzen(self, _optik.global_position, farbe().lightened(0.3),
				radius * 2.6, 0.22)

	await get_tree().create_timer(AUFTRITT_SPERRE).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(spieler):
		if "gesperrt" in spieler:
			spieler.gesperrt = false
		_heraustreten(spieler)


## Die Figur ist da: ein Ring zu ihren Füßen, ein paar Funken und – wenn
## das Modell es kann – ein kurzes Nachfedern.
func _heraustreten(spieler: Node3D) -> void:
	var fuss := spieler.global_position
	Effekte.ring(self, fuss + Vector3.UP * 0.06, farbe(), 1.3, 0.4)
	Effekte.funken(self, fuss + Vector3.UP * 0.6, farbe().lightened(0.4), 14, 3.0)
	var modell := spieler.get_node_or_null("Modell")
	if modell != null and modell.has_method("stoss"):
		modell.call("stoss", -0.3)


func _spieler_in_reichweite() -> Node3D:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return null
	if auftritt_radius <= 0.0:
		return spieler
	if spieler.global_position.distance_to(global_position) > auftritt_radius:
		return null
	return spieler


# ---------------------------------------------------------------- Zielportal

func _auf_koerper(koerper: Node3D) -> void:
	if _ausgeloest or not ist_ziel:
		return
	if not koerper.is_in_group("spieler"):
		return
	_ausgeloest = true
	_einsaugen(koerper)


## Der Spieler wird eingesogen, danach folgt die Erfolgsmeldung.
func _einsaugen(spieler: Node3D) -> void:
	if "gesperrt" in spieler:
		spieler.gesperrt = true
	if spieler is CharacterBody3D:
		(spieler as CharacterBody3D).velocity = Vector3.ZERO
	# Physik anhalten, damit die Schwerkraft nicht gegen die Animation arbeitet.
	spieler.set_physics_process(false)
	# Ab jetzt trägt ein Tween die Figur, und Tweens laufen im Bildtakt –
	# ohne Interpolation, sonst zittert sie auf dem Weg in den Wirbel.
	# Zurück kommt sie nicht mehr: Danach folgt der Levelwechsel.
	spieler.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var mitte := global_position + Vector3.UP * radius
	var modell := spieler.get_node_or_null("Modell") as Node3D

	var tween := create_tween().set_parallel(true)
	tween.tween_property(spieler, "global_position", mitte, EINSAUG_ZEIT) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(spieler, "rotation:y", spieler.rotation.y + TAU * 2.0,
			EINSAUG_ZEIT)
	if modell != null:
		tween.tween_property(modell, "scale", Vector3.ONE * 0.05, EINSAUG_ZEIT) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_optik):
		tween.tween_property(_optik, "scale", Vector3.ONE * 1.35, EINSAUG_ZEIT * 0.5) \
				.set_trans(Tween.TRANS_SINE)
	if _scheibenstoff != null:
		# Der Wirbel zieht sich zu und wird heller, während er die Figur
		# schluckt. NICHT `tempo`: Der Shader rechnet TIME · tempo, und TIME
		# läuft seit Spielstart – ein anderes Tempo springt dort um Hunderte
		# Umdrehungen, das Bild flackert. Drall und Sog ändern nur die Form.
		_scheibe_hochfahren(tween, 1.0, EINSAUG_ZEIT)
	await tween.finished
	if not is_instance_valid(self):
		return

	# Geschluckt: ein Lichtschlag im Portal und über dem ganzen Bild.
	Effekte.aufblitzen(self, mitte, farbe().lightened(0.3), radius * 2.6, 0.25)
	Effekte.funken(self, mitte, farbe().lightened(0.4), 30, 6.0)
	Effekte.ring(self, mitte, farbe().lightened(0.3), radius + 0.8, 0.45, global_basis.z)
	Effekte.bildblitz(self, Color(1.0, 1.0, 1.0, 0.35), 0.35)

	if is_instance_valid(_optik):
		var zurueck := create_tween().set_parallel(true)
		zurueck.tween_property(_optik, "scale", Vector3.ONE, 0.25)
		if _scheibenstoff != null:
			_scheibe_hochfahren(zurueck, 0.0, 0.8)

	GameState.zeige_nachricht("Level geschafft!", NACHRICHT_ZEIT)
	level_geschafft.emit()

	if GameState.kisten_gesamt > 0 \
			and GameState.kisten_zerbrochen >= GameState.kisten_gesamt:
		await get_tree().create_timer(EDELSTEIN_VERZOEGERUNG).timeout
		if not is_instance_valid(self):
			return
		GameState.zeige_nachricht("Alle Kisten! Edelstein erhalten", 3.0)
