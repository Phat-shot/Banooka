shader_type canvas_item;
// Bildrahmen: dunkle Ränder und ein schwacher warmer Schein von oben.
//
// Liegt als bildschirmfüllendes Rechteck über der 3D-Welt (Knoten
// `Bildrahmen`, CanvasLayer unter dem HUD). Die Ränder rahmen den Weg
// in der Mitte und schieben den Blick dorthin, wo gespielt wird – der
// Lesbarkeitsvertrag verlangt eine dunkle Rahmenfläche.
//
// RENDERER: gl_compatibility. Deshalb KEIN SCREEN_TEXTURE: Der Shader
// liest das Bild nicht, er legt nur Farbe darüber. Mit vormultipliziertem
// Alpha rechnet die Grafikkarte
//     Bild = Farbe + Bild · (1 − Alpha)
// – ein einziger Durchgang dunkelt die Ränder ab UND legt den Schein auf.
render_mode unshaded, blend_premul_alpha;

uniform float rand_staerke : hint_range(0.0, 1.0) = 0.35;  // Abdunklung in den Ecken
uniform float rand_beginn = 0.5;    // ab hier (0 = Mitte, 1 = Ecke) wird es dunkler
uniform float rand_weich = 0.55;
uniform vec3 rand_farbe : source_color = vec3(0.02, 0.035, 0.02);
uniform vec3 licht_farbe : source_color = vec3(1.0, 0.84, 0.58);
uniform float licht_staerke = 0.04;
uniform vec2 licht_ort = vec2(0.5, -0.2);   // in UV, oberhalb des Bildes
uniform float licht_weite = 0.9;


void fragment() {
	// Seitenverhältnis, damit der Rahmen rund bleibt statt sich mit dem
	// Bild zu strecken. Die Ecken bekommen am meisten, die Seitenmitten
	// weniger, oben und unten in der Mitte fast nichts – dort liegt der Weg.
	vec2 seiten = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 q = (UV - 0.5) * seiten;
	float r = length(q) / length(seiten * 0.5);
	float dunkel = smoothstep(rand_beginn, rand_beginn + rand_weich, r) * rand_staerke;
	float licht = licht_staerke
			* (1.0 - smoothstep(0.0, licht_weite, distance(UV * seiten, licht_ort * seiten)));
	COLOR = vec4(rand_farbe * dunkel + licht_farbe * licht, dunkel);
}
