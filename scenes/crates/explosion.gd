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
##   * Bodenring  – zeigt den Wirkradius genau an, wie beim Bauchplatscher.
##   * Glut, Rauch und ein kurzes Blitzlicht über `Effekte` (gedeckelt:
##     eine TNT-Kette erzeugte vorher ein Punktlicht je Kiste).
##
## Die Splitter der Kiste und das Kamerawackeln kommen aus `Kiste`, weil
## nur sie weiß, aus welchem Holz sie ist.

## Dauer der Druckwelle in Sekunden.
const DAUER := 0.6
## Weißgelbe Hitze: Richtung, in die Glut und Feuerball die Kistenfarbe
## ziehen.
const HITZE := Color(1.0, 0.82, 0.45)

## Rand hell, Mitte durchsichtig. Additiv, damit die Welle auf dem dunklen
## Schluchtgrund glüht; Schatten und Tiefe schreibt sie nicht.
const _SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float deckkraft : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Hoher Exponent: nur ein schmaler Saum. Mit breitem Saum lag die
	// Blase im Probelauf wie eine rosa Glocke über dem halben Bild.
	float rand = pow(1.0 - abs(dot(NORMAL, VIEW)), 4.0);
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
static var _shader: Shader = null
static var _kugel: SphereMesh = null
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
	var stoff := _stoff_neu(farbe.lightened(0.35), 0.8)
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
			stoff.set_shader_parameter("deckkraft", wert), 0.8, 0.0, DAUER * 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(queue_free)


## Glut, Feuerball, Bodenring, Rauch und Blitzlicht. Die Reihenfolge ist der Rang,
## falls `Effekte` in einer Kettenreaktion Stöße verwerfen muss.
func _stoesse() -> void:
	# Glut: fliegt weit, fällt schwer und glimmt länger als ein Funke. Nach
	# oben gestreut – was nach unten fliegt, steckt sofort im Boden. Der Ton
	# geht zum Feuer hin, auch beim grünen Nitro: Glut ist heiß.
	var glut := Effekte.funken(self, mitte, farbe.lerp(HITZE, 0.55), 24,
			radius * 2.2, 0.26, 110.0)
	if glut != null:
		glut.gravity = Vector3(0.0, -15.0, 0.0)
		glut.lifetime = 0.7
	# Der Feuerball: ein Knäuel großer, heißer Flecken, die auseinander-
	# quellen, aufsteigen und dabei schrumpfen. Ein einzelner Blitzfleck
	# las sich im Probelauf als Lichtschein, nicht als Feuer.
	var ball := Effekte.funken(self, mitte + Vector3.UP * 0.3, farbe.lerp(HITZE, 0.7),
			7, 2.5, radius * 0.45)
	if ball != null:
		ball.gravity = Vector3(0.0, 2.0, 0.0)
		ball.lifetime = 0.35
	# Der Ring am Boden sagt genau, wie weit es reicht.
	Effekte.ring(self, mitte + Vector3.DOWN * 0.44, farbe.lightened(0.2), radius, 0.35)
	# Dunkler Rauch, der langsam aufsteigt und stehen bleibt, wenn der
	# Blitz längst vorbei ist.
	# Nicht zu dunkel: Fast schwarzer Rauch stand im Probelauf wie ein Loch
	# mitten im Bild.
	Effekte.rauch(self, mitte + Vector3.UP * 0.4, Color(0.4, 0.37, 0.34, 0.8),
			radius * 0.55, 8)
	Effekte.blitzlicht(self, mitte, farbe.lightened(0.4), 6.0, radius * 2.5, 0.42)
