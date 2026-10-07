// Bachband (Baukasten Raum 1, Paket G3): fließendes Wasser als Band über
// die Läufe eines Bettes – `Bachband` (scripts/gemeinsam/bachband.gd).
//
// WÖRTLICHE ABSCHRIFT von `L01Wasser.BACH_SHADER` mit eingesetztem
// `WELLEN_CODE` (scenes/levels/level01/wasser.gd:111-230). Level 01 behält
// seinen Shader als Zeichenkette und wird nicht angefasst; die Raum-1-Level
// laden diese Datei. Ab dem Ende dieses Kopfes ist der Text Zeichen für
// Zeichen derselbe – `werkzeuge/baukastenprobe.gd` vergleicht ihn. Wer hier
// etwas ändert, ändert es nur für die neuen Level und muss die Probe
// anpassen.
//
// Scheiteldaten: UV = (quer in m, längs in m), UV2.x = Fließtempo (m/s),
// COLOR = (Schnelle 0..1, Sichtbarkeit 0..1, Uferabstand 0 Mitte .. 1 Ufer).
// Uniforms: Farben (tief, hell, Schaum, gespiegelter Himmel), `stroemung`
// (grobes Rauschen, gestreckt gelesen), `rauschen` (fein, Wellen und
// Glitzern), `glitzer` (0 im Web), `wellen_hoehe`. Kein Bildschirm- und
// kein Tiefenpuffer (gl_compatibility).
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform vec3 farbe_tief : source_color = vec3(0.07, 0.13, 0.12);
uniform vec3 farbe_hell : source_color = vec3(0.16, 0.25, 0.22);
uniform vec3 farbe_schaum : source_color = vec3(0.84, 0.91, 0.92);
uniform vec3 himmel_farbe : source_color = vec3(0.70, 0.80, 0.84);
uniform sampler2D stroemung : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float grund_alpha = 0.74;
uniform float spiegelung = 0.55;
uniform float glitzer = 1.0;

uniform sampler2D rauschen : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float wellen_hoehe = 0.05;

float wellenfeld(vec2 p, float t) {
	float h = 0.0;
	h += sin(p.x * 0.90 + t * 1.30) * 0.42;
	h += sin(p.y * 1.25 - t * 1.05) * 0.30;
	h += sin((p.x + p.y) * 0.55 + t * 0.75) * 0.24;
	h += sin((p.x - p.y * 1.7) * 1.90 - t * 1.90) * 0.11;
	h += sin((p.x * 2.6 + p.y * 0.4) + t * 2.40) * 0.06;
	return h;
}

float welle(vec2 xz, float t) {
	float h = wellenfeld(xz * 1.4, t * 1.3);
	h += (texture(rauschen, xz * 0.05 + vec2(t * 0.020, t * 0.015)).r - 0.5) * 0.75;
	return h;
}

varying float wellen;
varying vec2 welt;
varying vec3 fluss;
varying vec3 art;

// Zerreißt den Schaumsaum am Ufer in Flocken statt einer weißen Linie.
float kraeusel_saum(vec2 p) {
	return texture(stroemung, p * 0.35 + vec2(TIME * 0.02, TIME * 0.015)).r * 0.6;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	welt = w.xz;
	float h = welle(w.xz, TIME);
	wellen = clamp(h, -1.0, 1.0);
	VERTEX.y += h * wellen_hoehe;
	float e = 0.3;
	float dx = welle(w.xz + vec2(e, 0.0), TIME) - welle(w.xz - vec2(e, 0.0), TIME);
	float dz = welle(w.xz + vec2(0.0, e), TIME) - welle(w.xz - vec2(0.0, e), TIME);
	NORMAL = normalize(vec3(-dx * wellen_hoehe, 2.0 * e, -dz * wellen_hoehe));
	fluss = vec3(UV.x, UV.y, UV2.x);
	art = COLOR.rgb;
}

void fragment() {
	float k = clamp(wellen * 0.5 + 0.5, 0.0, 1.0);
	float ufer = art.b;
	float wild = art.r;
	// Mitte tief, zum Ufer hin flach und heller
	vec3 farbe = mix(farbe_tief, farbe_hell, k * 0.6 + smoothstep(0.45, 1.0, ufer) * 0.4);
	// Schaumflecken mit der Strömung: wenig gestreckt, zwei Lagen, nur wo
	// beide hoch stehen – lange, dünne Striche lasen sich wie Regen.
	float lauf = fluss.y - TIME * fluss.z;
	float s1 = texture(stroemung, vec2(fluss.x * 0.35, lauf * 0.12)).r;
	float s2 = texture(stroemung, vec2(fluss.x * 0.55 + 0.31,
			(fluss.y - TIME * fluss.z * 1.35) * 0.11)).r;
	float streifen = smoothstep(0.72, 0.9, s1 * 0.55 + s2 * 0.55);
	float schaum = streifen * (0.2 + 0.8 * wild);
	// In der Schnelle zerrissener Schaum: grob mit fein gemischt, keine
	// Zebrastreifen
	float fetzen = texture(stroemung, vec2(fluss.x * 0.5 + 0.7,
			(fluss.y - TIME * fluss.z * 1.1) * 0.3)).r;
	schaum = max(schaum, wild * smoothstep(0.42, 0.78, s2 * 0.6 + fetzen * 0.5) * 0.9);
	// Schaumsaum am Ufer: ein durchgehender, weicher, fleckiger Streifen
	// vor der Linie, an der das Wasser die Böschung schneidet (die Dreiecke
	// des Geländes zeichnen sie als Treppe) – dort wird das Wasser selbst
	// durchsichtig (siehe ALPHA).
	float flocken = kraeusel_saum(welt);
	float saum = smoothstep(0.6, 0.84, ufer + (flocken - 0.3) * 0.5)
			* (1.0 - smoothstep(0.9, 1.05, ufer));
	schaum = max(schaum, saum * (0.2 + 0.4 * flocken));
	float kraeusel = texture(rauschen, welt * 0.34 + vec2(TIME * 0.05, -TIME * 0.04)).r;
	schaum = max(schaum, smoothstep(0.82, 0.98, k) * smoothstep(0.35, 0.7, kraeusel) * 0.12);
	farbe = mix(farbe, farbe_schaum, schaum);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	farbe += himmel_farbe * fresnel * spiegelung * (1.0 - schaum);
	// Glitzern wie auf der Wasserfläche: zwei gegenläufig treibende
	// Rauschmuster, nur wo beide hoch stehen, blitzt ein Punkt auf.
	// Seltener als auf der Wasserfläche und vor allem im flachen Blick, wo
	// die Wellen die Sonne am ehesten zurückwerfen – sonst lag ein
	// Sternenhimmel auf dem Bach.
	float funkeln = 0.0;
	if (glitzer > 0.0) {
		float g1 = textureLod(rauschen, welt * 0.23 + vec2(TIME * 0.021, -TIME * 0.013), 0.0).r;
		float g2 = textureLod(rauschen, welt * 0.31 - vec2(TIME * 0.010, TIME * 0.018), 0.0).r;
		funkeln = smoothstep(0.52, 0.66, g1 * g2) * glitzer * (0.35 + 0.65 * fresnel)
				* (1.0 - schaum);
	}
	ALBEDO = farbe;
	// Am flachen Ufer durchsichtiger: dort scheint das Bett durch, und an
	// der Uferlinie selbst läuft das Wasser ganz aus.
	float deck = mix(grund_alpha, grund_alpha - 0.2, smoothstep(0.5, 0.95, ufer));
	float auslauf = 1.0 - smoothstep(0.8, 1.0, ufer + (flocken - 0.3) * 0.12);
	ALPHA = clamp(deck + fresnel * 0.3 + schaum * 0.3 + funkeln * 0.3, 0.0, 1.0) * art.g
			* auslauf;
	// Wenig Glanz aus der Umgebung: Der blaue Himmel im Spiegel machte den
	// Bach zum Kinderbild. Den Horizont spiegelt `himmel_farbe`.
	ROUGHNESS = mix(0.4, 0.2, fresnel) + schaum * 0.4;
	METALLIC = 0.0;
	SPECULAR = 0.1;
	EMISSION = farbe * 0.1 + himmel_farbe * funkeln * 2.5 + farbe_schaum * schaum * 0.15;
}
