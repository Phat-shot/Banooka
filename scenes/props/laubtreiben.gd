extends MultiMeshInstance3D
class_name Laubtreiben
## Trockenes Laub, das in Böen über den Weg getrieben wird.
##
## WARUM ZUSÄTZLICH ZU `gras.gd`: Das Gras (und ebenso Baumkrone und
## Kleinzeug) wiegt sich GLEICHMÄSSIG – ein ruhiges Sinus-Schwanken, das nach
## ein paar Sekunden zum Standbild wird, weil nichts passiert. Was fehlt, ist
## das Unregelmäßige: eine Böe, die durchs Bild wandert, kurz alles mitreißt
## und wieder abflaut. Genau das macht dieser Knoten sichtbar – ohne das
## Gras anzufassen, denn ein wandernder Stoß braucht etwas, das sich
## FORTBEWEGT, und ein Grashalm bleibt nun mal stehen.
##
## Die Böe ist eine Welle, die entlang der Windrichtung durch das Feld läuft.
## Hoch potenziert ⇒ kurze, kräftige Stöße mit langen Ruhephasen dazwischen.
## Steht der Knoten neben einem Grasfeld, liest man beides als denselben Wind.
##
## Technik wie bei `staub.gd`: ein MultiMesh, dessen Bewegung komplett im
## Vertex-Shader steckt (GPU-Partikel sind in `gl_compatibility` unzuverlässig).
## EIN Draw-Call, keine CPU-Last, keine Kollision, kein Schatten.
##
## Der Knoten sitzt auf dem Boden; das Laub fliegt von dort nach oben.

## Fläche, über die das Laub verteilt wird (X mal Z, zentriert um den Knoten).
@export var flaeche: Vector2 = Vector2(10.0, 10.0)
## Höhe des Bandes über dem Knoten, in dem Blätter schweben.
@export_range(0.1, 8.0, 0.1) var hoehe: float = 1.6
## Anzahl der Blätter.
@export_range(1, 400) var anzahl: int = 40
## Länge eines Blattes in Metern.
@export_range(0.02, 0.6, 0.005) var groesse: float = 0.16
## Erste Laubfarbe.
@export var farbe_a: Color = Farben.LAUBSTREU
## Zweite Laubfarbe – jedes Blatt würfelt zwischen beiden.
@export var farbe_b: Color = Farben.LAUB_GELB

@export_group("Wind")
## Windrichtung in LOKALEN Koordinaten. Den Knoten drehen (oder diesen Wert
## setzen), damit das Laub den Weg entlangfliegt statt quer darüber.
@export var windrichtung: Vector3 = Vector3(0.0, 0.0, 1.0)
## Länge der Bahn in Metern, nach der ein Blatt wieder von vorn anfängt.
@export_range(2.0, 80.0, 0.5) var bahn: float = 24.0
## Grundtempo des Laubs in Metern je Sekunde (zwischen den Böen).
@export_range(0.0, 8.0, 0.05) var tempo: float = 1.1
## Abstand zwischen zwei Böen in Metern – so weit ist es von Stoß zu Stoß.
@export_range(2.0, 120.0, 1.0) var boe_abstand: float = 34.0
## Wie schnell die Böe durchs Feld wandert (Böen je Sekunde).
@export_range(0.02, 3.0, 0.02) var boe_tempo: float = 0.45
## Wie weit eine Böe das Laub zusätzlich nach vorn reißt, in Metern.
@export_range(0.0, 12.0, 0.1) var boe_schub: float = 3.0
## Wie hoch eine Böe das Laub hebt, in Metern.
@export_range(0.0, 8.0, 0.1) var boe_hub: float = 1.0
## Ständiges Flattern zwischen den Böen, in Metern.
@export_range(0.0, 1.0, 0.01) var flattern: float = 0.18
## Tempo, mit dem sich ein Blatt um sich selbst dreht.
@export_range(0.0, 6.0, 0.05) var dreh_tempo: float = 1.2
## Feste Saat: gleicher Wert ⇒ gleiches Laub. 0 = jedes Mal neu würfeln.
@export var saat: int = 0

## Die Bahn läuft über `fract(...)`: der Rücksprung ist dadurch exakt und
## braucht keinen Sonderfall. Damit er nicht auffällt, SCHRUMPFT das Blatt an
## beiden Enden auf null – ausblenden über Alpha geht hier nicht, weil das
## Blatt per Alpha-Test gezeichnet wird (und damit sauber in den
## Tiefenpuffer schreibt, statt sich mit anderer Deko zu sortieren).
##
## Das Taumeln entsteht ohne echte 3D-Drehung: Das Blatt ist ein Billboard,
## das sich in der Bildebene dreht und dabei quer gestaucht wird. Von weitem
## ist das von einem echten Überschlag nicht zu unterscheiden und kostet
## weder Normalen noch eine zweite Matrix.
const LAUB_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 richtung = vec3(0.0, 0.0, 1.0);
uniform float bahn = 24.0;
uniform float grund_tempo = 0.045;
uniform float boe_dichte = 0.18;
uniform float boe_tempo = 0.45;
uniform float boe_schub = 3.0;
uniform float boe_hub = 1.0;
uniform float flattern = 0.18;
uniform float dreh_tempo = 1.2;

varying vec3 tonung;
varying float schatten;

void vertex() {
	// Instanzfarbe: RGB ist die Blattfarbe, Alpha die Phase des Blattes.
	float phase = COLOR.a;
	tonung = COLOR.rgb;
	float streu = fract(phase * 7.31);

	vec3 wpos = MODEL_MATRIX[3].xyz;

	// Wandernde Böe: Ort entlang der Windachse minus Zeit ⇒ die Welle läuft
	// mit dem Wind mit. Die vierte Potenz macht aus dem Sinus einen Stoß.
	float welle = dot(wpos, richtung) * boe_dichte - TIME * boe_tempo * 6.2831;
	float boe = pow(0.5 + 0.5 * sin(welle), 4.0);

	float anteil = fract(phase + TIME * grund_tempo * (0.6 + 0.8 * streu));
	wpos += richtung * ((anteil - 0.5) * bahn + boe * boe_schub);
	// quer zum Wind pendeln – ohne das fliegt alles auf exakt parallelen Bahnen
	vec3 quer = normalize(cross(richtung, vec3(0.0, 1.0, 0.0)));
	wpos += quer * sin(TIME * 0.7 + phase * 9.0) * flattern * 2.0;
	// Der Hub der Böe wirkt auf jedes Blatt anders stark: sonst hebt und
	// senkt sich das ganze Feld wie eine einzige Platte.
	wpos.y += boe * boe_hub * (0.35 + 0.65 * streu)
			+ sin(TIME * (0.9 + streu) + phase * 12.0) * flattern;

	// Die Böe gibt dem Blatt einen Dreh-Schub obendrauf. Additiv, NICHT als
	// Faktor auf TIME – sonst spränge der Winkel bei jeder Böe wild um.
	float dreh = TIME * dreh_tempo * (0.5 + streu) + phase * 6.2831 + boe * 2.5;
	float kipp = abs(sin(dreh * 0.5));
	// kantig gestellt bekommt das Blatt weniger Licht ab
	schatten = 0.58 + 0.42 * kipp;

	float saum = smoothstep(0.0, 0.08, anteil) * smoothstep(1.0, 0.92, anteil);

	vec3 v = VERTEX;
	v.x *= 0.2 + 0.8 * kipp;
	float c = cos(dreh);
	float s = sin(dreh);
	v = vec3(v.x * c - v.y * s, v.x * s + v.y * c, v.z);

	// Billboard: Ausrichtung von der Kamera, Ort und Drehung von uns.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], vec4(wpos, 1.0));
	VERTEX = v * length(MODEL_MATRIX[0].xyz) * saum;
}

void fragment() {
	// Blattform aus dem UV: die halbe Breite folgt einem Sinusbogen,
	// also läuft das Blatt an beiden Enden spitz zu. Billiger als jede Textur.
	float halb = 0.26 * pow(max(sin(UV.y * 3.14159), 0.0), 0.6);
	float d = abs(UV.x - 0.5);
	float rippe = (d < 0.012) ? 0.7 : 1.0;
	ALBEDO = tonung * schatten * rippe;
	ALPHA = (d < halb) ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""

## Einmal für alles Laub gebaut – eine Kompilierung reicht.
static var _shader: Shader = null


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_baue(PropWerkzeug.zufall(saat))


func _baue(rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _blatt()
	mm.instance_count = anzahl

	var halb_x := absf(flaeche.x) * 0.5
	var halb_z := absf(flaeche.y) * 0.5
	for i in anzahl:
		# quadratisch nach unten gewichtet: das meiste Laub liegt tief und
		# wird erst von einer Böe hochgerissen
		var hoch := rng.randf()
		var pos := Vector3(rng.randf_range(-halb_x, halb_x),
				0.03 + hoch * hoch * maxf(hoehe, 0.1),
				rng.randf_range(-halb_z, halb_z))
		var skal := groesse * rng.randf_range(0.7, 1.3)
		mm.set_instance_transform(i, Transform3D(
				Basis.from_scale(Vector3(skal, skal, skal)), pos))
		var ton := farbe_a.lerp(farbe_b, rng.randf()).darkened(rng.randf_range(0.0, 0.25))
		# Alpha = Phase (Bahnstelle, Drehung, Flattern)
		mm.set_instance_color(i, Color(ton.r, ton.g, ton.b, rng.randf()))

	multimesh = mm
	material_override = _material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Feste Hülle: die Blätter werden im Shader über die ganze Bahn verteilt.
	# Der Rand gilt in alle Richtungen, weil die Windrichtung frei wählbar ist.
	var rand := bahn * 0.5 + boe_schub + flattern * 2.0 + groesse
	custom_aabb = AABB(
			Vector3(-halb_x - rand, -groesse, -halb_z - rand),
			Vector3(halb_x * 2.0 + rand * 2.0,
					hoehe + boe_hub + flattern + groesse * 2.0,
					halb_z * 2.0 + rand * 2.0))


## Ein Viereck, zwei Dreiecke – die Blattform schneidet der Shader heraus.
func _blatt() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	return q


func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = LAUB_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("richtung", _weltrichtung())
	mat.set_shader_parameter("bahn", maxf(bahn, 0.1))
	# Meter je Sekunde in Umläufe je Sekunde umrechnen
	mat.set_shader_parameter("grund_tempo", tempo / maxf(bahn, 0.1))
	mat.set_shader_parameter("boe_dichte", TAU / maxf(boe_abstand, 0.1))
	mat.set_shader_parameter("boe_tempo", boe_tempo)
	mat.set_shader_parameter("boe_schub", boe_schub)
	mat.set_shader_parameter("boe_hub", boe_hub)
	mat.set_shader_parameter("flattern", flattern)
	mat.set_shader_parameter("dreh_tempo", dreh_tempo)
	return mat


## Windrichtung in Weltkoordinaten. Der Shader rechnet in Weltkoordinaten,
## weil `MODEL_MATRIX[3]` bei einem MultiMesh dort liegt.
##
## Der Wert wird EINMAL beim Aufbau gelesen: erst den Knoten drehen und
## einhängen, dann läuft der Wind in die gewünschte Richtung.
func _weltrichtung() -> Vector3:
	var r: Vector3 = global_transform.basis * windrichtung
	# waagerecht halten – schräg nach oben treibendes Laub sieht falsch aus
	r.y = 0.0
	if r.length_squared() < 0.000001:
		return Vector3.FORWARD
	return r.normalized()
