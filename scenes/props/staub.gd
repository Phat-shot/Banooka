extends MultiMeshInstance3D
class_name Staubflug
## Schwebender Staub und Pollen – ein Lichtschacht voller Flusen.
##
## Gedacht für die Stellen, an denen Sonne durch die Kronen in die Schlucht
## fällt: winzige Teilchen steigen langsam auf, driften seitlich weg und
## blitzen dabei unregelmäßig auf. Das Bild bewegt sich, ohne dass sich
## irgendetwas am Spiel ändert.
##
## WARUM MultiMesh statt GPUParticles3D: Der Renderer ist `gl_compatibility`.
## Dort laufen GPU-Partikel über Transform-Feedback, das je nach Treiber
## (besonders auf Android und in WebGL) fehlt oder still danebenliegt –
## `scenes/hazards/wasser.gd` verzichtet aus demselben Grund darauf.
## Ein MultiMesh mit Bewegung im Vertex-Shader ist dagegen überall dasselbe:
## EIN Draw-Call, kein einziger Knoten pro Bild, keine CPU-Last, und weil die
## Bahn eine reine Funktion von TIME ist, sieht sie auf jedem Gerät gleich aus.
##
## Der Knoten sitzt am FUSS der Säule; der Raum reicht von dort nach oben.
## Nach dem Aufbau sollte er nicht mehr bewegt werden – die Hülle
## (`custom_aabb`) ist fest, weil die Teilchen erst im Shader entstehen.
##
## Keine Kollision, kein Schatten: reine Kulisse.

## Raum, in dem die Teilchen schweben (X mal Y mal Z, in Metern).
## X/Z sind um den Knoten zentriert, Y reicht vom Knoten nach oben.
@export var raum: Vector3 = Vector3(6.0, 9.0, 6.0)
## Anzahl der Teilchen. Sie kosten nur Füllrate, keine CPU.
@export_range(1, 600) var anzahl: int = 90
## Kantenlänge eines Teilchens in Metern.
@export_range(0.01, 0.5, 0.005) var groesse: float = 0.05
## Streuung der Größe (0 = alle gleich, 1 = doppelt bis nichts).
@export_range(0.0, 1.0, 0.05) var groessen_streuung: float = 0.5
## Grundfarbe. Warm und hell, damit sie im Gegenlicht wirkt.
@export var farbe: Color = Color(1.0, 0.94, 0.76)
## Deckkraft. Der Staub wird additiv gezeichnet, leuchtet also auf dunklem
## Grund und verschwindet vor hellem Himmel – genau wie echte Flusen.
@export_range(0.0, 1.5, 0.05) var deckkraft: float = 0.75
## Steiggeschwindigkeit in Metern je Sekunde. Negativ = rieselt herunter.
@export_range(-1.0, 2.0, 0.01) var steiggeschwindigkeit: float = 0.22
## Seitlicher Ausschlag der Trudelbewegung in Metern.
@export_range(0.0, 1.5, 0.01) var wirbel: float = 0.35
## Tempo der Trudelbewegung.
@export_range(0.05, 3.0, 0.05) var wirbel_tempo: float = 0.35
## Wie stark die Teilchen aufblitzen (0 = ruhig, 1 = volles Flackern).
@export_range(0.0, 1.0, 0.05) var funkeln: float = 0.6
## Tempo des Aufblitzens.
@export_range(0.1, 8.0, 0.1) var funkel_tempo: float = 2.1
## Feste Saat: gleicher Wert ⇒ gleiche Verteilung. 0 = jedes Mal neu würfeln.
@export var saat: int = 0

## Die gesamte Bewegung steckt hier drin. Gerechnet wird in Weltkoordinaten,
## weil `MODEL_MATRIX[3]` bei einem MultiMesh den Platz der Einzelinstanz
## liefert – so braucht keine Instanz eigene Daten.
##
## Die Höhe kommt NICHT aus der Instanz, sondern aus `fract(phase + TIME…)`.
## Dadurch ist der Rücksprung von oben nach unten exakt und ohne Sonderfall;
## dass er nicht auffällt, besorgt der Saum im Fragment-Teil.
const STAUB_SHADER := """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never,
		shadows_disabled, fog_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.94, 0.76, 1.0);
uniform float raum_hoehe = 9.0;
uniform float steig_tempo = 0.024;
uniform float wirbel = 0.35;
uniform float wirbel_tempo = 0.35;
uniform float funkeln = 0.6;
uniform float funkel_tempo = 2.1;
uniform float deckkraft = 0.75;

varying float phase;
varying float bahn;
varying vec3 tonung;

void vertex() {
	// Instanzfarbe: RGB ist der Farbstich, Alpha die Phase des Teilchens.
	phase = COLOR.a;
	tonung = COLOR.rgb;
	// Zweiter Pseudozufall aus derselben Zahl – ohne ihn stiege der ganze
	// Schwarm im Gleichschritt, und das liest sich sofort als Muster.
	float streu = fract(phase * 7.31);
	bahn = fract(phase + TIME * steig_tempo * (0.55 + 0.9 * streu));

	vec3 wpos = MODEL_MATRIX[3].xyz;
	wpos.y += bahn * raum_hoehe;
	float w = TIME * wirbel_tempo + phase * 6.2831;
	wpos.x += sin(w) * wirbel;
	wpos.z += cos(w * 0.83 + 1.7) * wirbel;

	// Billboard: Ausrichtung von der Kamera übernehmen, Ort selbst setzen.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], vec4(wpos, 1.0));
	// Die eigene Matrix wirft die Instanzskalierung weg – hier zurückholen.
	VERTEX *= length(MODEL_MATRIX[0].xyz);
}

void fragment() {
	// Runde Flocke statt Viereck: billiger als jede Textur.
	float d = length(UV - vec2(0.5)) * 2.0;
	float rund = smoothstep(1.0, 0.2, d);
	// Oben und unten ausblenden, sonst sieht man den Rücksprung.
	float saum = smoothstep(0.0, 0.14, bahn) * smoothstep(1.0, 0.86, bahn);
	float blitz = mix(1.0, 0.45 + 0.55 * sin(TIME * funkel_tempo + phase * 41.0),
			funkeln);
	ALBEDO = farbe.rgb * tonung;
	ALPHA = deckkraft * rund * saum * blitz;
}
"""

## Einmal für alle Staubsäulen gebaut – eine Kompilierung reicht.
static var _shader: Shader = null


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_baue(PropWerkzeug.zufall(saat))


func _baue(rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _flocke()
	mm.instance_count = anzahl

	var halb_x := absf(raum.x) * 0.5
	var halb_z := absf(raum.z) * 0.5
	for i in anzahl:
		# Y bleibt 0: die Höhe verteilt der Shader über die Phase.
		var pos := Vector3(rng.randf_range(-halb_x, halb_x), 0.0,
				rng.randf_range(-halb_z, halb_z))
		var skal := groesse * (1.0 + rng.randf_range(-groessen_streuung,
				groessen_streuung))
		mm.set_instance_transform(i, Transform3D(
				Basis.from_scale(Vector3(skal, skal, skal)), pos))
		# Alpha = Phase (Höhe, Trudeln, Blitzen); RGB = leichter Farbstich
		mm.set_instance_color(i, Color(rng.randf_range(0.85, 1.0),
				rng.randf_range(0.85, 1.0), rng.randf_range(0.7, 1.0), rng.randf()))

	multimesh = mm
	material_override = _material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Feste Hülle: die Teilchen entstehen erst im Shader, aus Sicht des
	# Cullings stünden sie sonst alle flach auf Höhe des Knotens.
	var rand := wirbel + groesse * 2.0
	custom_aabb = AABB(
			Vector3(-halb_x - rand, -groesse, -halb_z - rand),
			Vector3(halb_x * 2.0 + rand * 2.0, absf(raum.y) + groesse * 2.0,
					halb_z * 2.0 + rand * 2.0))


## Ein Viereck, zwei Dreiecke – mehr braucht eine Flocke nicht.
func _flocke() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	return q


func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = STAUB_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("farbe", farbe)
	mat.set_shader_parameter("raum_hoehe", maxf(absf(raum.y), 0.1))
	# Umläufe je Sekunde statt Meter je Sekunde – der Shader rechnet in 0..1.
	mat.set_shader_parameter("steig_tempo",
			steiggeschwindigkeit / maxf(absf(raum.y), 0.1))
	mat.set_shader_parameter("wirbel", wirbel)
	mat.set_shader_parameter("wirbel_tempo", wirbel_tempo)
	mat.set_shader_parameter("funkeln", funkeln)
	mat.set_shader_parameter("funkel_tempo", funkel_tempo)
	mat.set_shader_parameter("deckkraft", deckkraft)
	return mat
