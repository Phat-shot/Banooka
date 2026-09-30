// Wegdecke ohne Bordstein (Level 01, Plan Abschnitt 8.1).
//
// Die Decke ist EINE Fläche über die ganze begehbare Breite. Was Erde und
// was Rasen ist, entscheidet die Wegmaske aus `wald_gemeinsam`: In der
// Mitte eine ausgetretene Spur, die pendelt und ausfranst, zum Rand hin
// Rasen, der bündig an Saum und Gelände anschließt. Kein Kantenstein, keine
// Farbgrenze mit dem Lineal.
//
// Braucht UV2 = (quer / halbe Breite, Strecke) – `LevelWerkzeuge.korridor`
// mit "uv_quer". UV1 (Welt-XZ · 0,25) trägt die Tangenten, in deren Raum
// die Normalen der Erde liegen.
//
// Zwei Fassungen, gewählt über `wurzelruecken` (einheitlich je Stoff, die
// Verzweigung kostet also nichts):
//   Waldweg        Erde (Waldweg der Bibliothek) in der Spur, Rasen daneben
//   Wurzelrücken   helle, abgetretene Borke in der Spur, Moos an den Flanken,
//                  längs laufende Borkenrippen mit Moos in den Furchen; am
//                  Anfang steigt er ausgefranst aus der Erde des Waldwegs
//
// Texturzugriffe je Bildpunkt: Weltrauschen, treibendes Kronenlicht, Rasen,
// dazu Erde + Erdnormalen (Waldweg) bzw. Borke, auf den ersten Metern der
// Wurzel auch Erde (Wurzelrücken) – höchstens fünf. Kein SCREEN_TEXTURE,
// kein DEPTH_TEXTURE (gl_compatibility).
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/wald_gemeinsam.gdshaderinc"

// Waldweg: Erde samt Normalen. Wurzelrücken: Borke (Normalen dort aus den
// Bildschirmableitungen) und als `flanke` die Erde des Waldwegs – die
// braucht er nur am Anfang, wo er aus der Erde steigt.
uniform sampler2D boden_farbe : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D boden_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D flanke : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool wurzelruecken = false;
// Erde: Wiederholungen je Meter in Welt-XZ (wie der Waldweg der Bibliothek).
uniform float boden_kachel = 0.37;
// Borke: (quer, längs) je Meter entlang der Spur.
uniform vec2 borke_kachel = vec2(0.24, 0.065);
uniform vec4 erde_ton : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 borke_ton : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Moos auf dem Wurzelrücken: der Rasen des Waldwegs, gelber und ruhiger.
// So passen Flanke und Rasen an der Naht zusammen, und das Moos kostet
// keinen eigenen Texturzugriff.
uniform vec4 moos_ton : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Wurzelrücken: Ab dieser Strecke steigt der Weg aus der Erde auf die
// Wurzel. Auf den ersten drei Metern liegt Erde auf der Borke, mit
// ausgefranster Grenze; genau an der Naht zeichnet der Wurzelrücken
// dasselbe wie der Waldweg – sonst stünde dort eine Linie quer über den Weg.
uniform float erde_bis = -1000000.0;
// Kronenlicht-Stärke je Strecke als Stützstellen (s, Stärke), stückweise
// linear; `kronen_anzahl` 0 heißt überall `kronen_fest`.
uniform vec2 kronen_stellen[24];
uniform int kronen_anzahl = 0;
uniform float kronen_fest = 0.0;

varying vec3 v_welt;
varying float v_kronen;


float kronen_staerke(float s) {
	if (kronen_anzahl <= 0) {
		return kronen_fest;
	}
	float w = kronen_stellen[0].y;
	for (int i = 1; i < 24; i++) {
		if (i >= kronen_anzahl) {
			break;
		}
		vec2 a = kronen_stellen[i - 1];
		vec2 b = kronen_stellen[i];
		if (s >= a.x) {
			w = mix(a.y, b.y, clamp((s - a.x) / max(b.x - a.x, 0.001), 0.0, 1.0));
		}
	}
	return w;
}


void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_kronen = kronen_staerke(UV2.y);
}


// Erde der Spur: heller und weniger gesättigt als der Rasen, Spurmitte
// +8 %, eine leise Makrowelle gegen die Kachel.
vec3 erde_aufbereiten(vec3 erde, float spur, vec4 w) {
	float luma = dot(erde, vec3(0.3, 0.59, 0.11));
	erde = mix(erde, vec3(luma), 0.16) * erde_ton.rgb;
	erde *= 1.0 + 0.08 * (1.0 - smoothstep(0.0, 0.36, spur));
	return erde * mix(0.95, 1.04, w.g);
}


// Sichtbarer Übergang Erde → Rasen: Wo die Büschel dicht stehen, reicht der
// Rasen ein Stück weiter in die Spur, in den Lücken scheint Erde durch, und
// die Grenze ist schmaler als die Maske – aus der Nähe las sich der breite
// Verlauf als Unschärfe. Die Maske selbst (für Halme und Probe) bleibt `m`.
float maske_bild(float m, float dichte) {
	return smoothstep(0.22, 0.78, clamp(m + (dichte - 0.5) * 1.2 * m * (1.0 - m) * 4.0, 0.0, 1.0));
}


void fragment() {
	vec2 xz = v_welt.xz;
	float q = UV2.x;
	float s = UV2.y;
	vec4 w = wald_welt(xz);
	float m = wegmaske_aus(q, s, w.r);
	float licht = kronenlicht_aus(w.a, xz, TIME);
	vec4 gras = rasen_textur(xz);
	vec3 rasen = rasen_farbe_aus(gras.rgb, w);
	float m_bild = maske_bild(m, gras.a);
	// Abstand zur Spurmitte (in halben Breiten) und zum Rand
	float spur = abs(q - wald_pendel(s));
	float rand = abs(q);
	// Die Trittkante: ein schmales Band festgetretener Erde, wo der Rasen
	// über die Spur hängt.
	float band = smoothstep(0.08, 0.42, m) * (1.0 - smoothstep(0.42, 0.78, m));
	vec2 euv = xz * boden_kachel;

	vec3 farbe;
	float rauh;
	if (!wurzelruecken) {
		vec3 erde = erde_aufbereiten(texture(boden_farbe, euv).rgb, spur, w);
		vec3 erde_n = texture(boden_normal, euv).rgb;
		farbe = mix(erde * mix(1.0, 0.7, band), rasen, m_bild);
		NORMAL_MAP = mix(erde_n, vec3(0.5, 0.5, 1.0), m_bild * 0.85);
		NORMAL_MAP_DEPTH = 1.0;
		rauh = mix(0.93, 0.86, m_bild);
	} else {
		// Borke längs der Spur: quer in Metern (halbe Breite 4 m), längs
		// die Strecke. So laufen die Rippen mit dem Weg, auch in der Wendel.
		vec2 buv = vec2(q * 4.0 * borke_kachel.x, s * borke_kachel.y);
		vec3 borke = texture(boden_farbe, buv).rgb;
		float h = dot(borke, vec3(0.333));
		// Abgetreten: Furchen flacher, Farbe heller und blasser, aber warm –
		// grau las sich die Borke als gebürstetes Blech.
		vec3 kern = mix(borke, vec3(h), 0.3);
		kern = mix(kern, vec3(0.3, 0.22, 0.14), 0.22) * 2.0 * borke_ton.rgb;
		kern *= 1.0 + 0.07 * (1.0 - smoothstep(0.0, 0.36, spur));
		kern *= mix(0.93, 1.05, w.g);
		// Moos kriecht von den Flanken in die Furchen der Rippen.
		float furche = 1.0 - smoothstep(0.18, 0.42, h);
		float moos_anteil = clamp(m + furche * smoothstep(0.1, 0.55, m) * 0.6
				+ (gras.a - 0.5) * 0.5 * m * (1.0 - m) * 4.0, 0.0, 1.0);
		moos_anteil = smoothstep(0.15, 0.85, moos_anteil);
		float rl = dot(rasen, vec3(0.3, 0.59, 0.11));
		vec3 moos = mix(rasen, vec3(rl), 0.25) * moos_ton.rgb;
		// Aus der Erde auf die Wurzel: Genau an der Naht ist alles Waldweg.
		float erdig = 1.0 - smoothstep(0.0, 1.0, (s - erde_bis) / 3.2 - (w.r - 0.5) * 1.2);
		if (erdig > 0.001) {
			// Nur am Anfang der Wurzel, deshalb mit festen Ableitungen: In
			// einer Verzweigung je Bildpunkt wären sie sonst undefiniert.
			vec3 erde = textureGrad(flanke, euv, dFdx(euv), dFdy(euv)).rgb;
			kern = mix(kern, erde_aufbereiten(erde, spur, w), erdig);
		}
		moos = mix(moos, rasen, erdig);
		float anteil = mix(moos_anteil, m_bild, erdig);
		farbe = mix(kern * mix(1.0, mix(0.72, 0.7, erdig), band), moos, anteil);
		// Relief aus den Bildschirmableitungen der Borkenhelligkeit (wie
		// `Riesenstamm.borkenstoff` in Weltfassung): kein Tangentenraum nötig.
		float relief_h = h * (1.0 - anteil * 0.8) * (1.0 - erdig);
		vec3 dpx = dFdx(VERTEX);
		vec3 dpy = dFdy(VERTEX);
		float dhx = dFdx(relief_h);
		float dhy = dFdy(relief_h);
		vec3 r1 = cross(dpy, NORMAL);
		vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
		NORMAL = normalize(abs(det) * NORMAL - gefaelle * 0.45);
		rauh = mix(0.72, 0.9, anteil);
	}

	// Verdeckung zum Rand: Mitte 1,0, Rand 0,78 (`Wegmaske.verdeckung`).
	float ao = mix(1.0, 0.78, smoothstep(0.3, 1.0, rand));
	ALBEDO = farbe * ao * kronen_faktor(licht, v_kronen, m);
	ROUGHNESS = rauh;
	SPECULAR = 0.3;
}
