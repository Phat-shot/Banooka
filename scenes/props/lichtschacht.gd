extends MultiMeshInstance3D
class_name Lichtschacht
## Sonnenstrahlen, die schräg in die Schlucht fallen – ein Bündel heller
## Bahnen im Dunst.
##
## Echte Lichtstrahlen (volumetrischer Nebel) kennt der Renderer
## `gl_compatibility` nicht, und alles, was die Tiefe des Bildes liest, fällt
## im Web ebenfalls weg. Die Strahlen hier sind deshalb gemalt: ein paar
## lange Bänder, die sich um ihre eigene Achse der Kamera zudrehen, additiv
## gezeichnet und zu allen Rändern hin weich ausgeblendet. Additiv heißt:
## Vor dunklem Fels leuchten sie auf, vor hellem Himmel verschwinden sie –
## so wie Lichtstrahlen im Wald eben auch nur im Schatten zu sehen sind.
##
## Gebaut wie `Staubflug`: EIN MultiMesh, EIN Zeichenaufruf, alle Bewegung
## im Shader, feste Hülle. Der Knoten sitzt am FUSS des Bündels; die Bahnen
## laufen von dort gegen die Lichtrichtung nach oben. Nach dem Aufbau nicht
## mehr bewegen – die Hülle ist fest.
##
## Keine Kollision, kein Schatten. Nahe an der Kamera blendet der Shader
## die Bahnen aus, damit die Verfolgerkamera nie durch eine harte Fläche
## fährt.

## Richtung, in die das Licht fällt (Welt). Am besten die der Sonne
## (`-sonne.global_transform.basis.z`), dann passen die Strahlen zu den
## Schatten.
@export var richtung: Vector3 = Vector3(-0.36, -0.89, -0.27)
## Länge der Bahnen in Metern, vom Fuß gegen die Lichtrichtung gemessen.
@export_range(2.0, 60.0, 0.5) var laenge: float = 18.0
## Breite einer Bahn in Metern.
@export_range(0.2, 8.0, 0.1) var breite: float = 2.2
## Anzahl der Bahnen im Bündel. Mehr als vier kostet im Web vor allem
## Füllrate, ohne viel heller zu wirken.
@export_range(1, 8) var anzahl: int = 4
## Wie weit die Bahnen um den Fuß gestreut sind (Meter, waagerecht).
@export_range(0.0, 8.0, 0.1) var streuung: float = 2.4
## Lichtfarbe – warmes Nachmittagslicht.
@export var farbe: Color = Color(1.0, 0.88, 0.62)
## Helligkeit. Über 0,2 lesen sich die Bahnen als Laser.
@export_range(0.0, 0.4, 0.005) var staerke: float = 0.1
## Feste Saat: gleicher Wert ⇒ gleiches Bündel. 0 = jedes Mal neu würfeln.
@export var saat: int = 0

## Die Bahn dreht sich im Vertex-Teil um ihre Achse zur Kamera. Die Achse
## steckt in der zweiten Spalte der Instanzmatrix (Länge inklusive), die
## Breite in der ersten. Die Instanzfarbe trägt in Alpha die Phase fürs
## Atmen, damit nicht alle Bahnen im Gleichtakt pulsieren.
const SCHACHT_SHADER := """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never,
		shadows_disabled, fog_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float staerke = 0.1;
uniform float nah = 7.0;
uniform float fern = 110.0;

varying float quer;
varying float laengs;
varying float phase;

void vertex() {
	phase = COLOR.a;
	quer = VERTEX.x * 2.0;
	laengs = VERTEX.y + 0.5;
	// Unten etwas breiter: Das Licht fächert zum Boden hin auf.
	float weite = mix(1.3, 0.75, laengs);
	vec3 achse = MODEL_MATRIX[1].xyz;
	vec3 mitte = MODEL_MATRIX[3].xyz + achse * 0.5;
	vec3 zur_kamera = INV_VIEW_MATRIX[3].xyz - mitte;
	vec3 seite = normalize(cross(normalize(achse), zur_kamera));
	vec3 n = normalize(cross(seite, achse));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(seite * length(MODEL_MATRIX[0].xyz) * weite, 0.0),
			vec4(achse, 0.0), vec4(n, 0.0), vec4(mitte, 1.0));
}

void fragment() {
	float kante = 1.0 - smoothstep(0.2, 1.0, abs(quer));
	float enden = smoothstep(0.0, 0.25, laengs) * (1.0 - smoothstep(0.6, 1.0, laengs));
	float d = length(VERTEX);
	float sicht = smoothstep(nah * 0.5, nah, d) * (1.0 - smoothstep(fern * 0.6, fern, d));
	float atmen = 0.72 + 0.28 * sin(TIME * 0.55 + phase * 40.0 + quer * 1.3);
	ALBEDO = farbe.rgb;
	ALPHA = staerke * kante * kante * enden * sicht * atmen;
}
"""

## Einmal für alle Bündel gebaut – eine Kompilierung reicht.
static var _shader: Shader = null


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_baue(PropWerkzeug.zufall(saat))


func _baue(rng: RandomNumberGenerator) -> void:
	var fall := richtung.normalized()
	if fall.length_squared() < 0.5 or fall.y > -0.1:
		fall = Vector3(-0.36, -0.89, -0.27).normalized()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = anzahl

	# Lokale Richtung: Der Knoten kann gedreht im Level hängen.
	var hoch := -(global_basis.inverse() * fall).normalized() if is_inside_tree() \
			else -fall
	var groesste := 0.0
	for i in anzahl:
		var b := breite * rng.randf_range(0.55, 1.2)
		var l := laenge * rng.randf_range(0.8, 1.1)
		var fuss := Vector3(rng.randf_range(-streuung, streuung), 0.0,
				rng.randf_range(-streuung, streuung))
		mm.set_instance_transform(i, Transform3D(
				Basis(Vector3.RIGHT * b, hoch * l, Vector3.BACK), fuss))
		mm.set_instance_color(i, Color(1.0, 1.0, 1.0, rng.randf()))
		groesste = maxf(groesste, l)

	multimesh = mm
	material_override = _material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Feste Hülle um alle Bahnen samt ihrer Breite, in welche Richtung
	# auch immer sie sich zur Kamera drehen.
	var spitze := hoch * groesste
	var rand := breite * 1.3 + streuung
	var von := Vector3(minf(0.0, spitze.x), minf(0.0, spitze.y), minf(0.0, spitze.z)) \
			- Vector3.ONE * rand
	var bis := Vector3(maxf(0.0, spitze.x), maxf(0.0, spitze.y), maxf(0.0, spitze.z)) \
			+ Vector3.ONE * rand
	custom_aabb = AABB(von, bis - von)


func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SCHACHT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("farbe", farbe)
	mat.set_shader_parameter("staerke", staerke)
	return mat
