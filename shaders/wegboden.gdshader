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
//                  das ungleich weit in die Decke frisst; längs laufende
//                  Borkenrippen an den Rändern mit Moos in den Furchen
//                  (früher eigene Leisten aus Geometrie, die auf der Decke
//                  flimmerten), Querrillen alle 1,5–4 m mit hellem Rand,
//                  dunkle Knoten; die Borke in Metern längs der Spur (in
//                  zwei Lagen, die zweite gedreht und größer); am Anfang
//                  steigt er ausgefranst aus der Erde des Waldwegs
//
// Texturzugriffe je Bildpunkt: Weltrauschen, Rasen, dazu Erde +
// Erdnormalen (Waldweg) bzw. zwei Lagen Borke, das treibende Kronenlicht
// nur, wo ein Kronendach ist – höchstens fünf; auf den ersten drei Metern
// der Wurzel kommt die Erde dazu (sechs). Kein SCREEN_TEXTURE, kein DEPTH_TEXTURE
// (gl_compatibility). Knoten und Risse sind reine Rechnung.
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
// Borke: (quer, längs) je Meter entlang der Spur, in Metern (Strecke und
// Querabstand) – also ohne UV-Streckung. Die Rinde der Bibliothek hat ihre
// Furchen schon 5:1 gestreckt (für Stämme); längs dichter gekachelt, bleibt
// davon auf dem Weg knapp 3:1: Furchen gut 10 cm breit und 30 cm lang wie
// grobe Eichenborke. Mit (0,22; 0,14) lief eine Kachel 4,5 m quer und 7 m
// längs, die Furchen 8:1 – Wellpappe oder Planken (Welle 6).
uniform vec2 borke_kachel = vec2(0.5, 0.9);
// Zweite Lage der Borke: um 35° gedreht und 2,7-mal so groß, nach einem
// groben Weltrauschen eingeblendet. Sie bricht die Wiederholung der
// Kachel und den Zug der Streifen – die Faser biegt sich um Knoten.
uniform float borke_dreh = 0.61;
uniform float borke_gross = 0.37;
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
// Lücken als (von, bis, erdig) entlang der Strecke. An ihren Lippen zieht
// sich die helle Spur mit krümeligem, unruhigem Rand zurück (erdig = 1:
// 4–40 cm, die Grasnarbe des Saums liegt dort 6 mm tiefer und zeigt den
// Abbruch), auf der Wurzel (erdig = 0) dunkelt nur ein ausgefranstes Band.
// Die Kollision bleibt die gerade Kante; nichts ragt über sie hinaus. Mit
// geradem Ende der Decke lag die Lippe wie mit dem Lineal gezogen, die
// Ecken rechtwinklig (Welle 6). `luecken_anzahl` 0: ohne.
uniform vec3 luecken[8];
uniform int luecken_anzahl = 0;

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


// Ein fester Zufallswert je Zelle (0..1).
float zelle_hash(vec2 c, vec2 k) {
	return fract(sin(dot(c, k)) * 43758.5453);
}


// Knoten in der Borke des Wurzelrückens: je Zelle von 2,6 × 3,4 m (quer ×
// längs) höchstens ein ovaler Knoten, Kern 0,35–0,6 m breit, längs
// gestreckt, mit Wulst bis rund 1,1 × 1,6 m.
// Rückgabe x = Kern (0..1), y = Wulst darum (0..1). `p` in Metern (quer,
// längs). Nur die Nachbarzellen längs werden gefragt – quer liegt jeder
// Knoten ganz in seiner Zelle.
vec2 knoten_aus(vec2 p) {
	vec2 zelle = vec2(2.6, 3.4);
	vec2 id = floor(p / zelle);
	vec2 ergebnis = vec2(0.0);
	for (int k = -1; k <= 1; k++) {
		vec2 c = id + vec2(0.0, float(k));
		float h1 = zelle_hash(c, vec2(127.1, 311.7));
		float h2 = zelle_hash(c, vec2(269.5, 183.3));
		float h3 = zelle_hash(c, vec2(419.2, 371.9));
		if (h3 < 0.42) {
			continue;
		}
		vec2 mitte = (c + vec2(0.3 + 0.4 * h1, 0.25 + 0.5 * h2)) * zelle;
		vec2 d = (p - mitte) / vec2(0.5 + 0.35 * h2, 0.75 + 0.5 * h1);
		float r = sqrt(dot(d, d));
		ergebnis.x = max(ergebnis.x, 1.0 - smoothstep(0.35, 0.7, r));
		ergebnis.y = max(ergebnis.y, smoothstep(0.5, 0.8, r) * (1.0 - smoothstep(0.85, 1.35, r)));
	}
	return ergebnis;
}


void fragment() {
	vec2 xz = v_welt.xz;
	float q = UV2.x;
	float s = UV2.y;
	vec4 w = wald_welt(xz);
	float m = wegmaske_aus(q, s, w.r);
	// Das treibende Kronenlicht nur, wo ein Kronendach ist (A, C4, D, E, F):
	// Ohne Dach bleibt `kronen_faktor` ohnehin 1. Die Verzweigung ist
	// räumlich zusammenhängend und kostet deshalb fast nichts; die
	// Ableitungen stehen davor.
	vec2 kuv = kronen_uv(xz, TIME);
	vec2 kuv_dx = dFdx(kuv);
	vec2 kuv_dy = dFdy(kuv);
	float licht = 0.5;
	if (v_kronen > 0.005) {
		licht = kronenlicht_grad(w.a, kuv, kuv_dx, kuv_dy);
	}
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
	// Ableitungen VOR jeder Verzweigung: In einem Zweig, den nicht alle
	// Bildpunkte eines Blocks nehmen, sind sie in GLSL ES 3.0 undefiniert.
	vec2 euv_dx = dFdx(euv);
	vec2 euv_dy = dFdy(euv);
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);

	// Abbruchkanten: Abstand (m entlang s) zur nächsten Lippe einer Lücke.
	float lippe_d = 10.0;
	float lippe_erdig = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= luecken_anzahl) {
			break;
		}
		vec3 l = luecken[i];
		float d = s < l.x ? l.x - s : (s > l.y ? s - l.y : 0.0);
		if (d < lippe_d) {
			lippe_d = d;
			lippe_erdig = l.z;
		}
	}
	float lippe_band = 0.0;
	if (lippe_d < 0.7) {
		// Ohne Ableitungen (Stufe 0): Der Zweig nimmt nicht jeder Block.
		float n1 = textureLod(wald_rauschen, xz * 0.55, 0.0).r;
		float n2 = textureLod(wald_rauschen, xz * 2.1 + vec2(0.37, 0.11), 0.0).g;
		float rueck = (0.04 + 0.3 * n1 + 0.06 * n2) * lippe_erdig;
		if (lippe_d < rueck) {
			discard;
		}
		lippe_band = 1.0 - smoothstep(rueck, rueck + 0.14 + 0.12 * n2 + 0.1 * (1.0 - lippe_erdig),
				lippe_d);
	}

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
		// Nähe zur Kamera: Das feine Halmmuster der Moosgrenze zählt nur bis
		// 8–20 m – weiter weg flimmerte es als Treppe.
		float nah = 1.0 - smoothstep(8.0, 20.0, length(VERTEX));
		float qm = q * 4.0;
		// Längs verzogen: Borke wächst nicht mit dem Lineal.
		float sl = s + (w.r - 0.5) * 3.0;
		// Borke längs der Spur: quer in Metern (halbe Breite 4 m), längs
		// die Strecke. So laufen die Rippen mit dem Weg, auch in der Wendel.
		vec2 buv = vec2(qm * borke_kachel.x, sl * borke_kachel.y);
		vec2 qs = vec2(qm, sl);
		vec2 gedreht = vec2(cos(borke_dreh) * qs.x - sin(borke_dreh) * qs.y,
				sin(borke_dreh) * qs.x + cos(borke_dreh) * qs.y);
		vec2 buv2 = gedreht * borke_kachel * borke_gross + vec2(0.31, 0.57);
		vec3 borke = mix(texture(boden_farbe, buv).rgb, texture(boden_farbe, buv2).rgb,
				0.15 + 0.45 * smoothstep(0.3, 0.7, w.g));
		float h = dot(borke, vec3(0.333));
		// Abgetreten: Furchen flacher, Farbe heller und blasser, aber warm –
		// grau las sich die Borke als gebürstetes Blech.
		vec3 kern = mix(borke, vec3(h), 0.3);
		kern = mix(kern, vec3(0.3, 0.22, 0.14), 0.22) * 2.0 * borke_ton.rgb;
		kern *= 1.0 + 0.07 * (1.0 - smoothstep(0.0, 0.36, spur));
		kern *= mix(0.88, 1.08, w.g) * mix(0.9, 1.06, w.b);

		// Rippen an den Rändern (längs, 0,47 m Abstand, wandernd): Wo die
		// Wurzel nicht abgetreten ist, steht die Borke in Leisten.
		float rippen_zone = smoothstep(0.5, 0.84, rand);
		float wandern = (w.b - 0.5) * 0.9 + (w.r - 0.5) * 0.4;
		float rippe = 0.5 + 0.5 * sin((abs(qm) + wandern) * 13.4);
		float rippen_fw = fwidth(abs(qm) * 13.4 / 6.2832);
		rippe = mix(rippe, 0.5, smoothstep(0.25, 0.6, rippen_fw)) * rippen_zone;
		float rippen_furche = rippen_zone * (1.0 - smoothstep(0.2, 0.45, rippe));

		// Querrisse alle 1,5–4 m: RILLEN, 8–15 cm breit, dunkelbraun mit
		// Moos im Grund und einem hellen, abgetretenen Rand von gut 5 cm –
		// nicht über die ganze Breite. Als schwarze Haarlinien lasen sie sich
		// wie Striche mit dem Stift (Welle 6). Gerechnet in Metern quer zur
		// Rille (eine Periode der Rissfolge sind 2,86 m).
		float riss_lauf = sl * 0.35 + w.b * 1.7;
		float riss_t = fract(riss_lauf);
		float riss_fw = fwidth(riss_lauf) * 2.86;
		float riss_id = floor(riss_lauf + 0.5);
		float riss_m = min(riss_t, 1.0 - riss_t) * 2.86;
		float riss_halb = (0.04 + 0.035 * fract(riss_id * 0.618))
				* (0.8 + 0.35 * sin(qm * 1.9 + riss_id));
		float riss_lauf_quer = smoothstep(-0.25, 0.35, sin(qm * 0.85 + riss_id * 2.37));
		float riss = (1.0 - smoothstep(riss_halb * 0.55, riss_halb + riss_fw, riss_m))
				* riss_lauf_quer * (1.0 - smoothstep(0.08, 0.2, riss_fw));
		float riss_rand = smoothstep(riss_halb * 0.6, riss_halb + 0.01, riss_m)
				* (1.0 - smoothstep(riss_halb + 0.03, riss_halb + 0.07 + riss_fw, riss_m))
				* riss_lauf_quer * (1.0 - smoothstep(0.08, 0.2, riss_fw));

		// Knoten: dunkle Kerne mit hellerem Wulst, auf der Spur halb
		// abgetreten.
		vec2 kn = knoten_aus(vec2(qm, sl));
		float knoten_kern = kn.x * mix(0.6, 1.0, smoothstep(0.1, 0.4, spur));
		kern *= 1.0 + 0.16 * kn.y;
		kern = mix(kern, vec3(0.1, 0.066, 0.04) * borke_ton.rgb, knoten_kern * 0.78);
		// In der Rille dunkle Borke mit Moos im Grund, am Rand hell
		// abgetreten.
		kern *= 1.0 + 0.16 * riss_rand;
		kern = mix(kern, kern * vec3(0.32, 0.3, 0.24) + vec3(0.012, 0.022, 0.006), riss * 0.85);
		kern *= 1.0 - 0.28 * rippen_furche;

		// Moos kriecht von den Flanken in die Furchen der Rippen, in die
		// Risse und um die Knoten – und frisst ungleich weit in die Decke
		// (±0,8 m in Zungen von 1–4 m), damit das Band nicht überall gleich
		// breit ist.
		float furche = 1.0 - smoothstep(0.18, 0.42, h);
		float fressen = ((w.b - 0.5) * 0.9 + (w.r - 0.5) * 0.7) * smoothstep(0.3, 0.75, rand);
		float moos_m = clamp(m + fressen, 0.0, 1.0);
		float moos_anteil = clamp(moos_m + furche * smoothstep(0.1, 0.55, moos_m) * 0.6
				+ (gras.a - 0.5) * 0.5 * moos_m * (1.0 - moos_m) * 4.0 * nah
				+ rippen_furche * 0.45 + riss * 0.55 * smoothstep(0.05, 0.5, moos_m + 0.2)
				+ kn.y * 0.25 * smoothstep(0.2, 0.6, rand), 0.0, 1.0);
		float moos_fw = fwidth(moos_anteil);
		moos_anteil = smoothstep(0.15 - moos_fw, 0.85 + moos_fw, moos_anteil);
		float rl = dot(rasen, vec3(0.3, 0.59, 0.11));
		// Moos auf Borke: dunkler und olivgrüner als der Rasen, in Polstern
		// (hell, wo die Halmdichte hoch ist) mit Borke in den Lücken.
		vec3 moos = mix(rasen, vec3(rl), 0.3) * moos_ton.rgb
				* mix(0.62, 0.95, smoothstep(0.2, 0.8, gras.a));
		moos = mix(moos, kern * 0.55, (1.0 - smoothstep(0.15, 0.45, gras.a)) * 0.5 * nah);
		// Aus der Erde auf die Wurzel: Genau an der Naht ist alles Waldweg.
		float erdig = 1.0 - smoothstep(0.0, 1.0, (s - erde_bis) / 3.2 - (w.r - 0.5) * 1.2);
		if (erdig > 0.001) {
			// Nur am Anfang der Wurzel; die Ableitungen stehen oben.
			vec3 erde = textureGrad(flanke, euv, euv_dx, euv_dy).rgb;
			kern = mix(kern, erde_aufbereiten(erde, spur, w), erdig);
		}
		moos = mix(moos, rasen, erdig);
		float anteil = mix(moos_anteil, m_bild, erdig);
		farbe = mix(kern * mix(1.0, mix(0.72, 0.7, erdig), band), moos, anteil);
		// Relief aus den Bildschirmableitungen der Borkenhelligkeit (wie
		// `Riesenstamm.borkenstoff` in Weltfassung): kein Tangentenraum nötig.
		// Dazu die Rippen, die Risse (tief) und die Knoten (erhaben).
		float relief_h = (h + rippe * 0.55 - riss * 0.7 + riss_rand * 0.2 + kn.x * 0.35 + kn.y * 0.25)
				* (1.0 - anteil * 0.7) * (1.0 - erdig);
		float dhx = dFdx(relief_h);
		float dhy = dFdy(relief_h);
		vec3 r1 = cross(dpy, NORMAL);
		vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
		NORMAL = normalize(abs(det) * NORMAL - gefaelle * 0.45);
		rauh = mix(0.72, 0.9, anteil);
	}

	// Verdeckung zum Rand: Mitte 1,0, Rand 0,78 (`Wegmaske.verdeckung`); an
	// der Lippe krümelig dunkler (festgetretene, abgebrochene Erde).
	float ao = mix(1.0, 0.78, smoothstep(0.3, 1.0, rand)) * (1.0 - 0.38 * lippe_band);
	ALBEDO = farbe * ao * kronen_faktor(licht, v_kronen, m);
	ROUGHNESS = rauh;
	SPECULAR = 0.3;
}
