// Nebeltafeln (Baukasten Raum 1, Paket G3): Dunst über Wasser als Tafeln,
// die sich um die Hochachse zur Kamera drehen – `GelaendeBau.nebeltafeln`
// (scripts/gemeinsam/gelaende_bau.gd).
//
// WÖRTLICHE ABSCHRIFT von `L01Gelaende.NEBEL_SHADER_CODE`
// (scenes/levels/level01/gelaende.gd:215-249). Level 01 behält seinen
// Shader als Zeichenkette und wird nicht angefasst. Ab dem Ende dieses
// Kopfes ist der Text Zeichen für Zeichen derselbe – `werkzeuge/
// baukastenprobe.gd` vergleicht ihn.
//
// Die vier Ecken einer Tafel liegen alle in ihrer Mitte; UV sagt, welche
// Ecke, UV2 die Größe (m), COLOR.r die Phase, COLOR.a die Kraft. Schlichtes
// Alpha, keine Tiefentextur: Die Tafel verblasst zu allen Rändern, damit
// ihr Schnitt mit dem Ufer nicht zu sehen ist. Uniforms: `farbe` (Nebel-
// licht), `staerke` (Deckkraft in der Mitte), `nah` (von–bis in m: so nah
// an der Kamera ausgeblendet).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, skip_vertex_transform, shadows_disabled;

uniform vec3 farbe : source_color = vec3(0.6, 0.7, 0.64);
uniform float staerke = 0.26;
uniform vec2 nah = vec2(7.0, 20.0);

varying float abstand;
varying float phase;
varying float kraft;

void vertex() {
	vec3 mitte = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	phase = COLOR.r * 6.2832;
	kraft = COLOR.a;
	mitte.y += sin(TIME * 0.21 + phase) * 0.12;
	vec3 zur_kamera = CAMERA_POSITION_WORLD - mitte;
	zur_kamera.y = 0.0;
	vec3 rechts = normalize(vec3(zur_kamera.z, 0.0, -zur_kamera.x) + vec3(1e-4, 0.0, 0.0));
	vec3 welt = mitte + rechts * (UV.x - 0.5) * UV2.x + vec3(0.0, (0.5 - UV.y) * UV2.y, 0.0);
	abstand = distance(welt, CAMERA_POSITION_WORLD);
	VERTEX = (VIEW_MATRIX * vec4(welt, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float u = abs(UV.x * 2.0 - 1.0);
	float v = 1.0 - UV.y;
	float a = (1.0 - smoothstep(0.1, 1.0, u)) * smoothstep(0.0, 0.32, v) * (1.0 - smoothstep(0.3, 1.0, v));
	float wogen = 0.78 + 0.22 * sin(UV.x * 4.0 + phase + TIME * 0.23) * sin(v * 3.0 - TIME * 0.17 + phase * 1.7);
	ALBEDO = farbe;
	ALPHA = clamp(a * wogen * staerke * kraft * smoothstep(nah.x, nah.y, abstand), 0.0, 1.0);
}
