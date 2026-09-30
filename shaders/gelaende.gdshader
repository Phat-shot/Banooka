// Gelände (Level 01, Plan Abschnitt 8.4): Tal, Oberland, Knoll, Gruben,
// Hügel – das Höhenfeld aus `GelaendeFeld` / `L01Gelaende`.
//
// Vier Böden, gemischt nach den Scheitelfarben:
//   R  Wiese      der Rasen aus `wald_gemeinsam` – dieselbe Farbe, dieselbe
//                 Makrovariation und dasselbe Kronenlicht wie der Rasenrand
//                 der Wegdecke, damit die Naht an A und D verschwindet
//   G  Waldboden  Erde, Laub und Moos (Bibliothek), dunkler und grüner
//   B  Fels       Bibliotheksfels in Dreifachprojektion (Welt), Moos auf
//                 allem, was nach oben schaut; Relief aus den Ableitungen
//   A  Schlamm    nasse Erde an Bach und Gruben
// UV2.x = gebackene Verdeckung (Walddach, Kronenschatten des Weltenbaums,
// Gruben, Mulden, Wegrand ab 0,78 wie die Decke), UV2.y = Stärke des
// Kronenlichts (0 = kein Dach), UV.x = Tönung (−1 kühl-feucht … +1
// warm-trocken; am Rand der Wegdecke 0).
//
// Texturzugriffe: Weltrauschen und Rasen immer, die übrigen nur wo ihr
// Gewicht > 0 ist (Fels drei, sonst einer); das treibende Kronenlicht nur
// unter einem Dach. Die Zweige sind räumlich zusammenhängend und holen mit
// vorab gerechneten Ableitungen (in einem Zweig, den nicht alle Bildpunkte
// eines Blocks nehmen, sind implizite Ableitungen in GLSL ES 3.0
// undefiniert). Kein SCREEN_TEXTURE, kein DEPTH_TEXTURE (gl_compatibility).
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/wald_gemeinsam.gdshaderinc"

uniform sampler2D waldboden : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fels : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D erde : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
// Wiederholungen je Meter in Weltkoordinaten
uniform float waldboden_kachel = 0.28;
uniform float fels_kachel = 0.085;
uniform float erde_kachel = 0.3;
// Waldboden dunkler und grüner als die Textur: Unter dem Dach liegt Moos
// auf dem Laub, und von oben muss sich der Wald als dunkle Fläche lesen.
uniform vec4 waldboden_ton : source_color = vec4(0.56, 0.66, 0.46, 1.0);
uniform vec4 fels_ton : source_color = vec4(1.02, 0.98, 0.9, 1.0);
uniform vec4 schlamm_ton : source_color = vec4(0.5, 0.48, 0.42, 1.0);
// Moos auf Fels (Anteil des Rasens, abgedunkelt)
uniform vec4 moos_ton : source_color = vec4(0.62, 0.7, 0.5, 1.0);
// Tönung der Böden: warm-trocken und kühl-feucht (Faktoren je Kanal)
uniform vec3 ton_warm = vec3(1.1, 1.03, 0.8);
uniform vec3 ton_kuehl = vec3(0.86, 0.97, 1.0);

varying vec3 v_welt;
varying vec3 v_n;


void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


void fragment() {
	vec2 xz = v_welt.xz;
	vec4 g = max(COLOR, vec4(0.0));
	g /= max(g.r + g.g + g.b + g.a, 0.001);
	vec4 w = wald_welt(xz);

	// Ableitungen vor jedem Zweig
	vec2 kuv = kronen_uv(xz, TIME);
	vec2 kuv_dx = dFdx(kuv);
	vec2 kuv_dy = dFdy(kuv);
	vec2 wuv = xz * waldboden_kachel;
	vec2 wuv_dx = dFdx(wuv);
	vec2 wuv_dy = dFdy(wuv);
	vec2 euv = xz * erde_kachel;
	vec2 euv_dx = dFdx(euv);
	vec2 euv_dy = dFdy(euv);
	vec3 fp = v_welt * fels_kachel;
	vec3 fp_dx = dFdx(fp);
	vec3 fp_dy = dFdy(fp);
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);

	// Wiese: genau wie der Rasenrand der Wegdecke
	vec4 gras = rasen_textur(xz);
	vec3 rasen = rasen_farbe_aus(gras.rgb, w);
	vec3 farbe = rasen * g.r;
	float rauh = 0.86 * g.r;
	float relief = 0.0;

	if (g.g > 0.004) {
		vec3 wb = textureGrad(waldboden, wuv, wuv_dx, wuv_dy).rgb * waldboden_ton.rgb;
		wb *= mix(0.84, 1.1, w.g);
		// Moospolster, fleckig über 4 m
		wb = mix(wb, rasen * moos_ton.rgb, smoothstep(0.52, 0.78, w.b) * 0.55);
		farbe += wb * g.g;
		rauh += 0.95 * g.g;
	}
	if (g.b > 0.004) {
		vec3 n = normalize(v_n);
		vec3 tw = pow(abs(n), vec3(4.0));
		tw /= (tw.x + tw.y + tw.z);
		vec3 fx = textureGrad(fels, fp.zy, fp_dx.zy, fp_dy.zy).rgb;
		vec3 fy = textureGrad(fels, fp.xz, fp_dx.xz, fp_dy.xz).rgb;
		vec3 fz = textureGrad(fels, fp.xy, fp_dx.xy, fp_dy.xy).rgb;
		vec3 f = fx * tw.x + fy * tw.y + fz * tw.z;
		float fl = dot(f, vec3(0.3, 0.55, 0.15));
		f = mix(f, vec3(fl), 0.22) * fels_ton.rgb * mix(0.9, 1.06, w.g);
		// Moos, wo der Fels nach oben schaut, in Zungen
		float moos = smoothstep(0.55, 0.85, n.y + (w.b - 0.5) * 0.5);
		f = mix(f, rasen * moos_ton.rgb, moos * 0.7);
		farbe += f * g.b;
		rauh += 0.9 * g.b;
		relief += fl * g.b * (1.0 - moos);
	}
	if (g.a > 0.004) {
		vec3 e = textureGrad(erde, euv, euv_dx, euv_dy).rgb;
		e = mix(e, vec3(dot(e, vec3(0.33))), 0.5) * schlamm_ton.rgb;
		farbe += e * g.a;
		rauh += 0.62 * g.a;
	}

	// Relief des Felses aus den Bildschirmableitungen der Helligkeit (wie
	// der Wurzelrücken der Wegdecke): kein Tangentenraum nötig. Außerhalb
	// jedes Zweigs – ohne Fels ist `relief` 0 und die Normale bleibt. In
	// der Ferne verblasst es: Dort würfe es nur Pixelrauschen.
	relief *= 1.0 - smoothstep(22.0, 70.0, length(VERTEX));
	float dhx = dFdx(relief);
	float dhy = dFdy(relief);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
	NORMAL = normalize(abs(det) * NORMAL - gefaelle * 0.6);

	float licht = 0.5;
	if (UV2.y > 0.005) {
		licht = kronenlicht_grad(w.a, kuv, kuv_dx, kuv_dy);
	}
	vec3 ton = UV.x > 0.0 ? mix(vec3(1.0), ton_warm, UV.x) : mix(vec3(1.0), ton_kuehl, -UV.x);
	ALBEDO = farbe * ton * UV2.x * kronen_faktor(licht, UV2.y, g.r);
	ROUGHNESS = rauh;
	SPECULAR = 0.3;
}
