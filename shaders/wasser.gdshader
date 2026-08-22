shader_type spatial;
// Wasseroberfläche für Banooka.
//
// WICHTIG: Das Projekt rendert mit "gl_compatibility" (Web-Export).
// Deshalb hier KEIN SCREEN_TEXTURE / DEPTH_TEXTURE und keine
// hint_screen_texture / hint_depth_texture – das gibt es dort nicht.
// Die gesamte Optik entsteht aus Vertex-Verschiebung, einer Rausch-
// textur und normaler Beleuchtung.
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// --- Farben (werden vom Skript aus `Farben` gesetzt) ---
uniform vec3 farbe_tief : source_color = vec3(0.13, 0.42, 0.52);
uniform vec3 farbe_hell : source_color = vec3(0.35, 0.72, 0.78);
uniform vec3 farbe_schaum : source_color = vec3(0.90, 0.97, 1.0);

// --- Rauschen für unregelmäßige Kräuselung (NoiseTexture2D) ---
uniform sampler2D rauschen : hint_default_white, filter_linear_mipmap, repeat_enable;

// --- Regler ---
uniform float wellen_hoehe = 0.16;    // Ausschlag der Wellen in Metern
uniform float wellen_tempo = 1.0;     // Zeitfaktor
uniform float wellen_dichte = 1.0;    // Wellenlänge (größer = feiner)
uniform float grund_alpha = 0.68;     // Grunddurchsichtigkeit
uniform float schaum_schwelle = 0.66; // ab welcher Wellenhöhe Schaum entsteht
uniform float spiegelung = 0.55;      // Stärke der Fresnel-Spiegelung

varying float wellenhoehe;  // -1 .. 1, Höhe an diesem Punkt
varying vec2 weltebene;     // Position in der XZ-Ebene


// Mehrere überlagerte Sinuswellen ergeben eine unruhige Oberfläche.
float wellenfeld(vec2 p, float t) {
	float h = 0.0;
	h += sin(p.x * 0.90 + t * 1.30) * 0.42;
	h += sin(p.y * 1.25 - t * 1.05) * 0.30;
	h += sin((p.x + p.y) * 0.55 + t * 0.75) * 0.24;
	h += sin((p.x - p.y * 1.7) * 1.90 - t * 1.90) * 0.11;
	h += sin((p.x * 2.6 + p.y * 0.4) + t * 2.40) * 0.06;
	return h;
}


void vertex() {
	// In Weltkoordinaten rechnen, damit die Wellen unabhängig von der
	// Größe und Position der Fläche gleich aussehen.
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * wellen_dichte;
	weltebene = p;
	float t = TIME * wellen_tempo;

	float h = wellenfeld(p, t);
	// Langsam driftendes Rauschen bricht das Sinusmuster auf.
	float n = texture(rauschen, p * 0.05 + vec2(t * 0.020, t * 0.015)).r - 0.5;
	h += n * 0.75;

	wellenhoehe = clamp(h, -1.0, 1.0);
	VERTEX.y += h * wellen_hoehe;

	// Normale aus finiten Differenzen der Wellenfunktion.
	float e = 0.35;
	float dx = wellenfeld(p + vec2(e, 0.0), t) - wellenfeld(p - vec2(e, 0.0), t);
	float dz = wellenfeld(p + vec2(0.0, e), t) - wellenfeld(p - vec2(0.0, e), t);
	NORMAL = normalize(vec3(-dx * wellen_hoehe, 2.0 * e, -dz * wellen_hoehe));
}


void fragment() {
	// Farbverlauf: Wellentäler dunkel, Wellenkämme hell.
	float k = clamp(wellenhoehe * 0.5 + 0.5, 0.0, 1.0);
	vec3 farbe = mix(farbe_tief, farbe_hell, k);

	// Schaumsaum auf den Kämmen, durch Rauschen aufgebrochen.
	float kraeusel = texture(rauschen,
			weltebene * 0.34 + vec2(TIME * 0.05, -TIME * 0.04)).r;
	float schaum = smoothstep(schaum_schwelle, schaum_schwelle + 0.22, k)
			* smoothstep(0.30, 0.72, kraeusel);
	farbe = mix(farbe, farbe_schaum, schaum);

	// Leichte Spiegelung: flacher Blickwinkel => heller Himmelsschimmer.
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	farbe += farbe_schaum * fresnel * spiegelung;

	ALBEDO = farbe;
	ALPHA = clamp(grund_alpha + fresnel * 0.30 + schaum * 0.25, 0.0, 1.0);
	ROUGHNESS = mix(0.42, 0.08, fresnel);
	METALLIC = 0.0;
	SPECULAR = 0.7;
	EMISSION = farbe * 0.10;
}
