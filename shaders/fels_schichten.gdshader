// Schichtfels, Erde und Grasnarbe der Kanten (Level 01, Plan Abschnitt 8.3).
//
// EIN Stoff für alles, was `GelaendeSaum` baut: Felswände, Böschungen, Ufer,
// Stirnflächen der Lücken, die Grasnarbe auf der Lippe und die Steine in
// der Böschung. Was an einer Stelle liegt, sagen die Scheitelfarben – so
// kostet ein Stück Kante einen einzigen Zeichenaufruf:
//   COLOR.r  Verdeckung (1 offen … 0,2 tief im Überhang), auf der CPU aus
//            Hohlform, Überhang und Tiefe gerechnet
//   COLOR.g  Erde (0 Fels … 1 Erde): Böschung, Grasnarbe von unten, Ufer
//   COLOR.b  Moos: wie viel Moos hier wachsen darf (Simse, Krone, Fugen);
//            gewachsen wird nur, wo die Fläche nach oben schaut
//   COLOR.a  Rasen: die Rasenfarbe des Weges (Include `wald_gemeinsam`) –
//            an der Wegkante schließt sie ohne Naht an die Decke an
//   UV2.x    Stärke des Kronenlichts (0 = kein Kronendach)
//   UV2.y    Tiefe unter der Wegkante (m): zum Fuß hin kühler und dunkler
//
// Der Fels liegt in Weltkoordinaten (Dreifachprojektion), die großen
// SCHICHTEN auch: Band = floor(Welt-Y · 0,35 + Neigung + Makrorauschen +
// Welle über die Höhe), 3–6° geneigt und ungleich dick, jedes Band mit
// eigener Gesteinsart (meist warmer Sandstein, einzelne helle Kalkbänke)
// und eigener Helligkeit, dazwischen eine dunkle Fuge. Die Geometrie tritt mit denselben
// Bändern vor und zurück (`GelaendeSaum.schicht()`), deshalb liegen Farbe und
// Form übereinander. Dazu Wasserspuren, die senkrecht die Wand hinablaufen.
//
// Texturzugriffe: Weltrauschen 1, Fels 3 (Dreifachprojektion, je Band
// Sandstein ODER Kalk), Moos 2
// (Polster, Wasserspuren); Erde (3) nur, wo Erde ist, Rasen (1) nur, wo
// Rasen ist, das treibende Kronenlicht (1) nur unter einem Kronendach – die
// Verzweigungen hängen an Scheitelwerten und sind räumlich zusammenhängend;
// in ihnen wird mit vorab geholten Ableitungen gelesen. Kein SCREEN_TEXTURE,
// kein DEPTH_TEXTURE (gl_compatibility). Das Relief kommt aus den
// Bildschirmableitungen der Helligkeit, eine Normalmap braucht es nicht.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/wald_gemeinsam.gdshaderinc"

uniform sampler2D fels : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
// Zweite Gesteinsart für die Kalkbänke (grauer, mit Flechten).
uniform sampler2D kalk : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D erde : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moos : source_color, filter_linear_mipmap, repeat_enable;
// Wiederholungen je Meter.
uniform float fels_kachel = 0.17;
uniform float erde_kachel = 0.4;
uniform float moos_kachel = 0.6;
// Die beiden Gesteinsarten der Bänder.
uniform vec4 fels_warm : source_color = vec4(1.0, 0.96, 0.9, 1.0);
uniform vec4 fels_grau : source_color = vec4(1.06, 0.99, 0.86, 1.0);
uniform vec4 erde_ton : source_color = vec4(0.82, 0.74, 0.66, 1.0);
uniform vec4 moos_ton : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Zum Fuß hin: kühler und dunkler (Luftperspektive nach unten).
uniform vec4 fuss_ton : source_color = vec4(0.56, 0.64, 0.74, 1.0);
uniform float fuss_tiefe = 17.0;
// Schichtbänder: Dichte je Meter und Neigung (tan des Winkels je Achse).
uniform float schicht_dichte = 0.35;
uniform vec2 schicht_neigung = vec2(0.062, -0.041);
uniform float relief = 0.55;

varying vec3 v_welt;
varying vec3 v_wn;


void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


float band_hash(float b) {
	return fract(sin(b * 12.9898 + 3.7) * 43758.5453);
}


void fragment() {
	vec3 n = normalize(v_wn);
	vec2 xz = v_welt.xz;
	vec4 w = wald_welt(xz);
	float ao = COLOR.r;
	float erdig = COLOR.g;
	float moos_erlaubt = COLOR.b;
	float rasen_anteil = COLOR.a;

	// --- Schichten (wie `GelaendeSaum.schicht`)
	// Die Bänder sind ungleich dick: Eine langsame Welle über die Höhe
	// staucht und dehnt sie um gut ein Drittel.
	float phase = v_welt.y * schicht_dichte + dot(xz, schicht_neigung) + (w.g - 0.5) * 1.1
			+ 0.22 * sin(v_welt.y * 0.61 + 1.7);
	float band = floor(phase);
	float innen = phase - band;
	float kenn = band_hash(band);
	float kenn2 = band_hash(band + 31.0);

	// --- Fels, dreifach projiziert; je Band eine Gesteinsart: meist warmer
	// Sandstein (`fels`), jede dritte Bank grauer Kalk mit Flechten
	// (`kalk`). Gewechselt wird an der Fuge, die den Sprung verdeckt; die
	// Ableitungen kommen von der unverschobenen Koordinate, der Versatz ist
	// innerhalb eines Bandes fest.
	vec3 gew = pow(abs(n), vec3(4.0));
	gew /= (gew.x + gew.y + gew.z);
	vec3 p = v_welt * fels_kachel;
	vec2 dzy_x = dFdx(p.zy);
	vec2 dzy_y = dFdy(p.zy);
	vec2 dxz_x = dFdx(p.xz);
	vec2 dxz_y = dFdy(p.xz);
	vec2 dxy_x = dFdx(p.xy);
	vec2 dxy_y = dFdy(p.xy);
	// Jedes Band leicht verschoben: Die Textur wiederholt sich nicht von
	// Band zu Band an derselben Stelle.
	vec2 versatz = vec2(kenn * 7.3, kenn2 * 3.1);
	bool ist_kalk = kenn + (w.b - 0.5) * 0.3 > 0.74;
	vec3 fels_c;
	if (ist_kalk) {
		fels_c = textureGrad(kalk, p.zy + versatz, dzy_x, dzy_y).rgb * gew.x
				+ textureGrad(kalk, p.xz + versatz, dxz_x, dxz_y).rgb * gew.y
				+ textureGrad(kalk, p.xy + versatz, dxy_x, dxy_y).rgb * gew.z;
		// Heller, warmer Kalk – kein Beton zwischen dem Sandstein.
		float kl = dot(fels_c, vec3(0.3, 0.59, 0.11));
		fels_c = mix(fels_c, vec3(kl), 0.35) * 1.3 * fels_grau.rgb;
	} else {
		fels_c = textureGrad(fels, p.zy + versatz, dzy_x, dzy_y).rgb * gew.x
				+ textureGrad(fels, p.xz + versatz, dxz_x, dxz_y).rgb * gew.y
				+ textureGrad(fels, p.xy + versatz, dxy_x, dxy_y).rgb * gew.z;
		fels_c *= 1.32 * fels_warm.rgb;
	}
	float fl = dot(fels_c, vec3(0.3, 0.59, 0.11));
	fels_c *= (0.93 + 0.13 * kenn2) * mix(0.86, 1.1, w.g);
	// Im Band nach unten etwas dunkler, an der Fuge dunkel.
	fels_c *= mix(1.0, 0.93, 1.0 - innen);
	float fuge = 1.0 - smoothstep(0.0, 0.05, innen);
	fels_c *= 1.0 - 0.3 * fuge;
	// Wasserspuren: lange, schmale Streifen die Wand hinab. Die seitliche
	// Koordinate läuft schräg über X und Z – ein Wechsel der Projektion je
	// nach Normale flackerte auf verbeulten Flächen als Kamm aus Streifen.
	float wx = n.x * n.x / max(n.x * n.x + n.z * n.z, 0.0001);
	float spur = texture(moos, vec2((v_welt.x + v_welt.z) * 0.15, v_welt.y * 0.018)
			+ vec2(0.13, 0.57)).a;
	fels_c *= 1.0 - 0.28 * smoothstep(0.58, 0.78, spur) * (1.0 - gew.y);

	// Ableitungen VOR den Verzweigungen: In einem Zweig, den nicht alle
	// Bildpunkte eines Blocks nehmen, sind sie in GLSL ES 3.0 undefiniert.
	vec3 pe = v_welt * erde_kachel;
	vec2 pe_xy_dx = dFdx(pe.xy);
	vec2 pe_xy_dy = dFdy(pe.xy);
	vec2 pe_zy_dx = dFdx(pe.zy);
	vec2 pe_zy_dy = dFdy(pe.zy);
	vec2 pe_xz_dx = dFdx(pe.xz);
	vec2 pe_xz_dy = dFdy(pe.xz);
	vec2 ruv = xz * wald_rasen_kachel;
	vec2 ruv_dx = dFdx(ruv);
	vec2 ruv_dy = dFdy(ruv);

	// --- Erde (Böschung, Unterseite der Narbe, Ufer)
	vec3 flaeche = fels_c;
	float relief_h = fl;
	if (erdig > 0.01) {
		vec3 es = mix(textureGrad(erde, pe.xy, pe_xy_dx, pe_xy_dy).rgb,
				textureGrad(erde, pe.zy, pe_zy_dx, pe_zy_dy).rgb, wx);
		vec3 eo = textureGrad(erde, pe.xz, pe_xz_dx, pe_xz_dy).rgb;
		vec3 erde_c = mix(es, eo, smoothstep(0.45, 0.8, abs(n.y))) * erde_ton.rgb;
		flaeche = mix(flaeche, erde_c, erdig);
		relief_h = mix(relief_h, dot(erde_c, vec3(0.33)), erdig);
	}

	// --- Moos: wo es darf und wo die Fläche nach oben schaut; in Zungen
	vec4 mt = texture(moos, (xz + v_welt.y * vec2(0.31, -0.27)) * moos_kachel);
	float oben = smoothstep(0.42, 0.8, n.y);
	float moos_m = moos_erlaubt * (0.2 + 0.8 * oben) + (w.b - 0.5) * 0.45;
	float moos_a = smoothstep(0.45, 0.66, moos_m + (mt.a - 0.5) * 0.9);
	flaeche = mix(flaeche, mt.rgb * moos_ton.rgb * 1.1, moos_a);
	relief_h = mix(relief_h, dot(mt.rgb, vec3(0.33)) * 0.6, moos_a);

	// --- Rasen: dieselbe Farbe wie der Rasen der Wegdecke
	vec4 gras = vec4(0.5);
	if (rasen_anteil > 0.01) {
		gras = textureGrad(wald_rasen, ruv, ruv_dx, ruv_dy);
		vec3 rasen = rasen_farbe_aus(gras.rgb, w);
		float r_anteil = smoothstep(0.1, 0.9, rasen_anteil + (gras.a - 0.5) * 0.5 * (1.0 - rasen_anteil) * rasen_anteil * 4.0);
		// Rasen wächst nicht an steilen Flächen (die Textur liegt von oben
		// projiziert und zöge sich dort in Streifen).
		r_anteil *= smoothstep(0.38, 0.62, n.y);
		flaeche = mix(flaeche, rasen, r_anteil);
		relief_h = mix(relief_h, 0.4, r_anteil);
	}

	// --- Kronenlicht (nur unter einem Kronendach)
	vec2 kuv = kronen_uv(xz, TIME);
	vec2 kuv_dx = dFdx(kuv);
	vec2 kuv_dy = dFdy(kuv);
	float licht = 0.5;
	if (UV2.x > 0.005) {
		licht = kronenlicht_grad(w.a, kuv, kuv_dx, kuv_dy);
	}

	// --- Tiefe: zum Fuß hin kühl und dunkler
	float tief = smoothstep(3.0, fuss_tiefe, UV2.y);
	flaeche = mix(flaeche, flaeche * fuss_ton.rgb, tief);

	// --- Relief aus den Bildschirmableitungen (wie `Riesenstamm.borkenstoff`)
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	float dhx = dFdx(relief_h);
	float dhy = dFdy(relief_h);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
	float rel = relief * (1.0 - 0.7 * rasen_anteil) * (1.0 - 0.5 * moos_a);
	NORMAL = normalize(abs(det) * NORMAL - gefaelle * rel);

	ALBEDO = flaeche * ao * kronen_faktor(licht, UV2.x, rasen_anteil);
	ROUGHNESS = mix(mix(0.86, 0.95, erdig), 0.92, max(moos_a, rasen_anteil));
	SPECULAR = 0.25;
}
