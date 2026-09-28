extends MeshInstance3D
class_name Wasserfall
## Ein Wasserfall, der über die Kante einer Schluchtwand stürzt.
##
## Ein Band aus Vierecken, das der Wand folgt wie eine hängende Ranke:
## Springt der Fels vor, fällt das Wasser über ihn, springt er zurück,
## stürzt es frei davor (dieselbe Regel wie in `Schluchtsaum`). Das Fließen
## macht der Shader: zwei Streifenmuster aus Rauschen, verschieden schnell
## und verschieden fein, laufen nach unten und mischen tiefes Blaugrün mit
## Gischtweiß; zu den Rändern und Enden wird das Band durchsichtig.
##
## Unbeleuchtet, weil fallendes Wasser selbst hell ist – im Schatten der
## Schlucht wäre ein beleuchtetes Band ein graues Tuch. Kein Bildschirm-
## und kein Tiefenpuffer, also auch im Web und auf dem Handy dasselbe.
##
## Keine Kollision: Es steht an der Wand, nie im Weg.
##
## Aufbau: `Wasserfall.an_schluchtwand(...)` legt den Knoten an und baut das
## Netz in Weltkoordinaten aus den Kronendaten der Schluchtwand.

const FALL_SHADER := """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never,
		shadows_disabled;

uniform vec4 farbe_tief : source_color = vec4(0.24, 0.52, 0.58, 1.0);
uniform vec4 farbe_schaum : source_color = vec4(0.90, 0.97, 1.0, 1.0);
uniform float tempo = 5.5;
uniform float laenge = 20.0;

float zufall(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rauschen(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(zufall(i), zufall(i + vec2(1.0, 0.0)), u.x),
			mix(zufall(i + vec2(0.0, 1.0)), zufall(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	// UV.x quer über das Band (0..1), UV.y Meter ab der Kante.
	float quer = UV.x;
	float m = UV.y;
	float grob = rauschen(vec2(quer * 7.0, m * 0.45 - TIME * tempo * 0.45));
	float fein = rauschen(vec2(quer * 19.0 + 3.1, m * 1.3 - TIME * tempo * 1.1));
	float schaum = smoothstep(0.38, 0.85, grob * 0.62 + fein * 0.48);
	// Unten und an der Kante oben mehr Gischt.
	schaum = max(schaum, smoothstep(0.7, 1.0, m / laenge) * 0.8);
	schaum = max(schaum, (1.0 - smoothstep(0.0, 1.2, m)) * 0.7);
	float rand = smoothstep(0.0, 0.2, quer) * smoothstep(1.0, 0.8, quer);
	float enden = smoothstep(0.0, 0.4, m) * (1.0 - smoothstep(laenge * 0.8, laenge, m));
	ALBEDO = mix(farbe_tief.rgb, farbe_schaum.rgb, schaum);
	ALPHA = rand * enden * mix(0.5, 0.95, schaum);
}
"""

static var _shader: Shader = null


## Baut einen Wasserfall an einer Schluchtwand, die mit `kronen_merken`
## entstanden ist. `strecke` und `seite` wählen die Stelle; `breite` ist die
## Breite des Bandes entlang der Wand, `bis` die Höhe (relativ zum Weg), bis
## zu der es hinabreicht.
static func an_schluchtwand(eltern: Node3D, kurve: Curve3D, kronen: Array,
		strecke: float, seite: float, breite: float = 3.0,
		bis: float = -12.0) -> Wasserfall:
	# Die Säulen im Bereich des Bandes: Das Wasser muss vor JEDER davon
	# fallen, sonst stäche ein vorspringender Block durch den Vorhang.
	var saeulen: Array = []
	for eintrag in kronen:
		var e: Dictionary = eintrag
		if float(e["seite"]) == seite and absf(float(e["s"]) - strecke) < breite * 0.5 + 1.4:
			saeulen.append(e)
	if saeulen.is_empty():
		return null
	var oben := INF
	var start := INF
	for eintrag in saeulen:
		var e: Dictionary = eintrag
		oben = minf(oben, float(e["oben"]))
		start = minf(start, float(e["innen"]))

	# Weg des Wassers als (quer, y): über die Kante, dann hinab.
	var weg := PackedVector2Array()
	weg.append(Vector2(start + 0.9, oben + 0.05))
	var q := start - 0.15
	var y := oben - 0.1
	weg.append(Vector2(q, y))
	while y > bis:
		y = maxf(y - 0.5, bis)
		for eintrag in saeulen:
			q = minf(q, Schluchtsaum.wand_bei(eintrag as Dictionary, y) - 0.2)
		# Der Strahl löst sich mit der Höhe etwas von der Wand.
		weg.append(Vector2(q - (oben - y) * 0.015, y))

	var mitte := LevelWerkzeuge.punkt(kurve, strecke)
	var laengs := LevelWerkzeuge.richtung(kurve, strecke)
	var aussen := laengs.cross(Vector3.UP).normalized() * seite
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SPALTEN := 4
	var gelaufen := 0.0
	var vorher: Array[Vector3] = []
	var vorher_m := 0.0
	for i in weg.size():
		var p := weg[i]
		if i > 0:
			gelaufen += weg[i - 1].distance_to(p)
		var reihe: Array[Vector3] = []
		for k in SPALTEN + 1:
			var u := float(k) / float(SPALTEN)
			# Leicht nach außen gewölbt, und unten breiter als oben.
			var bauch := sin(u * PI) * 0.18
			var weite := breite * lerpf(0.85, 1.25, clampf((oben - p.y) / 20.0, 0.0, 1.0))
			reihe.append(mitte + aussen * (p.x - bauch) + Vector3.UP * p.y
					+ laengs * (u - 0.5) * weite)
		if not vorher.is_empty():
			for k in SPALTEN:
				var u0 := float(k) / float(SPALTEN)
				var u1 := float(k + 1) / float(SPALTEN)
				_ecke(st, vorher[k], Vector2(u0, vorher_m))
				_ecke(st, reihe[k], Vector2(u0, gelaufen))
				_ecke(st, reihe[k + 1], Vector2(u1, gelaufen))
				_ecke(st, vorher[k], Vector2(u0, vorher_m))
				_ecke(st, reihe[k + 1], Vector2(u1, gelaufen))
				_ecke(st, vorher[k + 1], Vector2(u1, vorher_m))
		vorher = reihe
		vorher_m = gelaufen

	var fall := Wasserfall.new()
	fall.name = "Wasserfall"
	fall.mesh = st.commit()
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FALL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("laenge", gelaufen)
	fall.material_override = mat
	eltern.add_child(fall)
	return fall


static func _ecke(st: SurfaceTool, p: Vector3, uv: Vector2) -> void:
	st.set_normal(Vector3.UP)
	st.set_uv(uv)
	st.add_vertex(p)
