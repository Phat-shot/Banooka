extends Node3D
class_name Explosion
## Kurzlebiger Explosionseffekt für TNT- und Nitrokisten.
##
## Wird rein im Code erzeugt (keine Szenendatei nötig) und räumt sich
## nach dem Ablauf selbst wieder ab.
##
## Aufbau:
##   * Druckwelle – eine Kugel, die bis zum Wirkradius aufbläht. Ein
##     eigener Shader lässt nur ihren Rand leuchten (Fresnel): Man sieht
##     eine Blase, keine milchige Scheibe, und durch sie hindurch den Weg.
##   * Feuerball  – große additive Flecken, die weißgelb aufquellen und über
##     Orange und Rot abkühlen.
##   * Bodenring  – zeigt den Wirkradius genau an, wie beim Bauchplatscher.
##   * Glut, Rauch (steigt erst auf, wenn das Feuer verlischt) und ein
##     kurzes Blitzlicht über `Effekte` (gedeckelt: eine TNT-Kette erzeugte
##     vorher ein Punktlicht je Kiste).
##
## Die Splitter der Kiste und das Kamerawackeln kommen aus `Kiste`, weil
## nur sie weiß, aus welchem Holz sie ist.
##
## Farbe: Alles, was leuchtet, zieht die Kistenfarbe zur Hitze hin. Die
## Kistenfarbe selbst, nur aufgehellt, ergab beim roten TNT eine rosa
## Glasglocke über einer lachsfarbenen Scheibe – Licht, aber kein Feuer.

## Dauer der Druckwelle in Sekunden.
const DAUER := 0.6
## Weißgelbe Hitze: Richtung, in die Glut und Feuerball die Kistenfarbe
## ziehen.
const HITZE := Color(1.0, 0.82, 0.45)
## Höchste Deckkraft der Druckwelle. Sie ist nur der Rahmen, das Feuer
## steht in der Mitte.
const WELLE_DECKKRAFT := 0.55

## Rand hell, Mitte durchsichtig. Additiv, damit die Welle auf dem dunklen
## Schluchtgrund glüht; Schatten und Tiefe schreibt sie nicht.
const _SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float deckkraft : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Hoher Exponent: nur ein schmaler Saum. Mit breitem Saum lag die
	// Blase im Probelauf wie eine Glasglocke über dem halben Bild.
	float rand = pow(1.0 - abs(dot(NORMAL, VIEW)), 6.0);
	ALBEDO = farbe.rgb * 1.6;
	ALPHA = clamp(rand, 0.0, 1.0) * deckkraft;
}
"""

var radius := 3.0
var farbe := Farben.WARNUNG
## Mittelpunkt in Weltkoordinaten. `erzeugen` setzt ihn VOR dem Einhängen:
## `_ready` läuft beim Einhängen und braucht ihn schon.
var mitte := Vector3.ZERO

# Einmal gebaut, von allen Explosionen geteilt (wie `Staubflug._shader`).
# Nie verändert: Farbe und Deckkraft stecken im Emitter bzw. im eigenen
# Material jeder Explosion.
static var _shader: Shader = null
static var _kugel: SphereMesh = null
static var _feuerlauf: Gradient = null
static var _feuerwuchs: Curve = null
static var _qualmlauf: Gradient = null
## Für welche Szene der Shader schon vorgewärmt ist (Instanzkennung).
static var _gewaermt_fuer := 0


## Erzeugt eine Explosion an `pos` unterhalb von `elternteil`.
static func erzeugen(elternteil: Node, pos: Vector3, wirkradius: float = 3.0,
		ton: Color = Farben.WARNUNG) -> void:
	if elternteil == null or not is_instance_valid(elternteil):
		return
	var ex := Explosion.new()
	ex.name = "Explosion"
	ex.radius = wirkradius
	ex.farbe = ton
	ex.mitte = pos
	# Die Druckwelle bläht per Tween im Bildtakt auf – ohne Interpolation.
	ex.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	elternteil.add_child(ex)
	ex.global_position = pos


## Zeichnet die Druckwelle einmal unsichtbar vor der Kamera, damit ihr
## Shader übersetzt ist, bevor die erste Kiste hochgeht. Unter
## gl_compatibility (und im Browser erst recht) wird ein Shader beim
## ersten Zeichnen übersetzt – ohne das stockte das Spiel genau im Knall.
## Einmal je Szene; `Kiste` ruft es für jede TNT- und Nitrokiste auf.
static func vorwaermen(bei: Node) -> void:
	if bei == null or not bei.is_inside_tree():
		return
	var szene := bei.get_tree().current_scene
	var kamera := bei.get_viewport().get_camera_3d()
	if szene == null or kamera == null \
			or szene.get_instance_id() == _gewaermt_fuer:
		return
	_gewaermt_fuer = szene.get_instance_id()
	var mi := MeshInstance3D.new()
	mi.name = "Vorwaermen"
	mi.mesh = _kugel_holen()
	mi.material_override = _stoff_neu(Color.WHITE, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Als Kind der Kamera bleibt sie im Bild, wohin die Kamera beim Aufbau
	# auch springt. Deckkraft 0: gezeichnet, aber nicht zu sehen.
	mi.position = Vector3(0.0, 0.0, -4.0)
	mi.scale = Vector3.ONE * 0.2
	kamera.add_child.call_deferred(mi)
	bei.get_tree().create_timer(0.5).timeout.connect(mi.queue_free)


func _ready() -> void:
	_baue_druckwelle()
	_stoesse()


static func _kugel_holen() -> SphereMesh:
	if _kugel == null:
		_kugel = SphereMesh.new()
		_kugel.radius = 0.5
		_kugel.height = 1.0
		# Fein genug, dass der Umriss auch bei drei Metern Radius rund bleibt.
		_kugel.radial_segments = 32
		_kugel.rings = 16
	return _kugel


## Eigenes Material je Explosion: Jede blendet ihre Deckkraft selbst aus.
static func _stoff_neu(ton: Color, deckkraft: float) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = _SHADER_CODE
	var stoff := ShaderMaterial.new()
	stoff.shader = _shader
	stoff.set_shader_parameter("farbe", ton)
	stoff.set_shader_parameter("deckkraft", deckkraft)
	return stoff


## Schnell aufblähende Druckwelle mit leuchtendem Rand.
func _baue_druckwelle() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Druckwelle"
	mi.mesh = _kugel_holen()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var stoff := _stoff_neu(farbe.lerp(HITZE, 0.45), WELLE_DECKKRAFT)
	mi.material_override = stoff
	mi.scale = Vector3.ONE * 0.3
	add_child(mi)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3.ONE * (radius * 2.0), DAUER) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Die Welle verlischt, bevor sie ganz draußen ist: Eine volle Blase um
	# die Kamera legte sonst einen Farbschleier über das halbe Bild.
	t.tween_method(func(wert: float) -> void:
			stoff.set_shader_parameter("deckkraft", wert), WELLE_DECKKRAFT, 0.0,
			DAUER * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(queue_free)


## Feuerball, Bodenring, Glut, Rauch und Blitzlicht. Die Reihenfolge ist
## der Rang, falls `Effekte` in einer Kettenreaktion Stöße verwerfen muss:
## zuerst das Feuer, dann der Ring, der den Wirkradius zeigt.
func _stoesse() -> void:
	# Der Feuerball: ein Knäuel großer, heißer Flecken, die aufquellen,
	# aufsteigen und dabei abkühlen – weißgelb, orange, dunkelrot, weg.
	# Additiv, also verlischt das Dunkelrot von selbst im Hintergrund. Die
	# Kistenfarbe tönt nur leicht: Nitro brennt grünlich, TNT bleibt Feuer.
	var ball := Effekte.funken(self, mitte + Vector3.UP * 0.3,
			Color.WHITE.lerp(farbe, 0.25), 10, 2.6, radius * 0.6)
	if ball != null:
		ball.emission_sphere_radius = radius * 0.15
		ball.gravity = Vector3(0.0, 3.0, 0.0)
		ball.damping_min = 3.0
		ball.damping_max = 5.0
		ball.lifetime = 0.45
		ball.lifetime_randomness = 0.25
		ball.scale_amount_curve = _feuerwuchs_holen()
		ball.color_ramp = _feuerlauf_holen()
	# Der Ring am Boden sagt genau, wie weit es reicht. Etwas gedämpft: Der
	# Saum der Ringtextur hat Körper, und voll lag eine glühende Scheibe
	# unter dem Feuer statt eines Rings.
	var boden := farbe.lerp(HITZE, 0.5)
	Effekte.ring(self, mitte + Vector3.DOWN * 0.44, Color(boden, 0.7), radius, 0.35)
	# Glut: fliegt weit, fällt schwer und glimmt länger als ein Funke. Nach
	# oben gestreut – was nach unten fliegt, steckt sofort im Boden. Der Ton
	# geht zum Feuer hin, auch beim grünen Nitro: Glut ist heiß.
	var glut := Effekte.funken(self, mitte, farbe.lerp(HITZE, 0.65), 24,
			radius * 2.2, 0.26, 110.0)
	if glut != null:
		glut.gravity = Vector3(0.0, -15.0, 0.0)
		glut.lifetime = 0.7
	# Dunkler Rauch, der aufsteigt, wenn das Feuer verlischt, und danach
	# noch eine Weile steht. Er quillt erst auf, wenn der Feuerball schon
	# abkühlt (eigener Verlauf): Gleichzeitig mit ihm zog er als brauner
	# Schleier über das Feuer, statt es zu rahmen. Breiter gestreut als
	# die Vorgabe, damit er seitlich um die Glut herumsteht. Nicht ganz
	# schwarz: Fast schwarzer Rauch stand im Probelauf wie ein Loch im Bild.
	var qualm := Effekte.rauch(self, mitte + Vector3.UP * 0.5, Color(0.26, 0.23, 0.2),
			radius * 0.65, 10)
	if qualm != null:
		qualm.lifetime = 1.5
		qualm.emission_sphere_radius = radius * 0.25
		qualm.color_ramp = _qualmlauf_holen()
	Effekte.blitzlicht(self, mitte, HITZE.lerp(farbe, 0.25), 6.0, radius * 2.5, 0.42)


## Feuer kühlt ab: weißgelb, orange, rot, dann nichts. Multipliziert mit der
## Emitterfarbe (fast weiß), deshalb stehen die Töne hier ausgeschrieben.
static func _feuerlauf_holen() -> Gradient:
	if _feuerlauf == null:
		_feuerlauf = Gradient.new()
		_feuerlauf.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
		_feuerlauf.colors = PackedColorArray([Color(1.0, 0.95, 0.75, 1.0),
				Color(1.0, 0.62, 0.18, 0.95), Color(0.75, 0.2, 0.06, 0.6),
				Color(0.25, 0.06, 0.02, 0.0)])
	return _feuerlauf


## Rauch nach dem Feuer: unsichtbar, solange der Feuerball brennt (er lebt
## knapp ein Drittel so lang), dann dicht, dann langsam weg.
static func _qualmlauf_holen() -> Gradient:
	if _qualmlauf == null:
		_qualmlauf = Gradient.new()
		_qualmlauf.offsets = PackedFloat32Array([0.0, 0.14, 0.32, 1.0])
		_qualmlauf.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0),
				Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	return _qualmlauf


## Feuer quillt auf und fällt am Ende nur wenig zusammen – ein Funke, der
## gleichmäßig schrumpft, sähe aus wie Glut, nicht wie eine Flamme.
static func _feuerwuchs_holen() -> Curve:
	if _feuerwuchs == null:
		_feuerwuchs = Curve.new()
		_feuerwuchs.add_point(Vector2(0.0, 0.45), 0.0, 2.5)
		_feuerwuchs.add_point(Vector2(0.4, 1.0))
		_feuerwuchs.add_point(Vector2(1.0, 0.8))
		_feuerwuchs.bake()
	return _feuerwuchs
