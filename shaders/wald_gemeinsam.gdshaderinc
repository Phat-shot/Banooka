// Gemeinsame Bodenfunktionen des Waldes (Level 01, Plan Abschnitt 8.1).
//
// Weg, Saum, Gelände und Rasenhalme binden diese Datei ein und rechnen
// damit an jeder Stelle dieselbe Rasenfarbe, dieselbe Makrovariation und
// dasselbe Kronenlicht – nur so bleiben die Nähte zwischen den Flächen
// unsichtbar. Die Uniforms setzt `Wegmaske.einrichten(stoff)`; ohne den
// Aufruf fehlen die Texturen.
//
// Das Weltrauschen ist EIN Bild (`Wegmaske.bild()`), 256² über 80 m in
// Welt-XZ, kachelbar:
//   R  Wegmaske   – wo die Spur ausfranst (fbm, Formen um 11 m bis 1,5 m)
//   G  Makro      – Helligkeit des Rasens über 20 m
//   B  Flecken    – Helligkeit über 4 m, wo hoch: strohige Stellen
//   A  Kronenlicht – Lichtflecken um 3 m (ruhende Lage)
// Die CPU (`Wegmaske.wert`, `Wegmaske.makro` …) liest dasselbe Bild mit
// derselben bilinearen Abtastung. Wer hier eine Formel ändert, ändert sie
// in `scripts/wegmaske.gd` mit – die Probe vergleicht beide
// (`werkzeuge/wegmaskenprobe.gd`: die Konstanten in `level_check` über
// `pruefprofil()` "wegmaske", die gezeichnete Maske an 20 Punkten in
// `pruefe.sh` über `werkzeuge/wegmaskenprobe.sh`, Grenze 0,02).
//
// Kosten: `wald_welt()` ist ein Texturzugriff, `kronenlicht_aus()` ein
// zweiter (die treibende Lage), `rasen_textur()` ein dritter. Wer mehrere
// Werte braucht, holt `wald_welt()` einmal und rechnet mit den `…_aus`-
// Fassungen weiter.
//
// Belegte Namen (nicht noch einmal vergeben): Uniforms `wald_rauschen`,
// `wald_rasen`, `wald_kachel`, `wald_rasen_kachel`; Konstanten `WALD_…`;
// Funktionen `wald_welt`, `wald_pendel`, `wegmaske`, `wegmaske_aus`,
// `makro`, `makro_aus`, `trocken_aus`, `rasen_textur`, `rasen_farbe`,
// `rasen_farbe_aus`, `kronenlicht`, `kronenlicht_aus`, `kronenlicht_grad`,
// `kronen_uv`, `kronen_faktor`.
//
// Anschluss an die Wegkante: Die Decke dunkelt zum Rand auf 0,78 ab
// (`Wegmaske.RAND_VERDECKUNG`); wer dort ansetzt, beginnt mit demselben
// Wert. Das Kronenlicht braucht eine Stärke je Ort (Wegdecke:
// `L01Boden.kronenlicht_bei(level, s)`); wer keine hat, nimmt 0.

uniform sampler2D wald_rauschen : filter_linear_mipmap, repeat_enable;
uniform sampler2D wald_rasen : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
// Wiederholungen je Meter: Weltrauschen (1/80 m) und Rasentextur (1/2,4 m).
uniform float wald_kachel = 0.0125;
uniform float wald_rasen_kachel = 0.41667;

// Wegmaske (Plan 8.1): smoothstep(0,42; 0,62; |q − Pendel| + (n − 0,5)·0,45
// − 0,12·sin(s·0,09)), zum Wegrand hin sicher Rasen.
const float WALD_MASKE_VON = 0.42;
const float WALD_MASKE_BIS = 0.62;
const float WALD_MASKE_RAUSCHEN = 0.45;
const float WALD_MASKE_WELLE = 0.12;
// Das Pendel der Spur, in halben Wegbreiten.
const float WALD_PENDEL_A = 0.17;
const float WALD_PENDEL_B = 0.07;
// Ab hier wird der Rand sicher Rasen: Die Spur läuft nie bis an die Kante,
// dort schließt das Gelände mit derselben Rasenfarbe an.
const float WALD_RAND_VON = 0.80;
const float WALD_RAND_BIS = 0.97;

// Rasenfarbe: Makro ×0,82–1,12, trockene Stellen gelblich.
const float WALD_MAKRO_TIEF = 0.82;
const float WALD_MAKRO_HOCH = 1.12;
const vec3 WALD_TROCKEN_TON = vec3(1.28, 1.08, 0.62);

// Kronenlicht: treibende Lage 1,7-mal feiner als die ruhende, Drift je
// Sekunde in Texturkoordinaten (0,004 · 47 m ≈ 0,19 m/s).
const float WALD_KRONEN_FEIN = 1.7;
const vec2 WALD_KRONEN_DRIFT = vec2(0.0040, 0.0017);


// Ein Abgriff des Weltrauschens an einer Stelle (R Maske, G Makro,
// B trocken, A Kronenlicht ruhend).
vec4 wald_welt(vec2 welt_xz) {
	return texture(wald_rauschen, welt_xz * wald_kachel);
}


// Seitlicher Versatz der Spurmitte in halben Wegbreiten (±0,24).
float wald_pendel(float s) {
	return WALD_PENDEL_A * sin(s * 0.067 + 0.8) + WALD_PENDEL_B * sin(s * 0.181 + 2.3);
}


// Die Wegmaske aus einem schon geholten Rauschwert `n` (R-Kanal):
// 0 = ausgetretene Erde, 1 = Rasen. `q_norm` = quer / halbe Wegbreite
// (UV2.x der Wegdecke), `s` = Strecke (UV2.y).
float wegmaske_aus(float q_norm, float s, float n) {
	float d = abs(q_norm - wald_pendel(s)) + (n - 0.5) * WALD_MASKE_RAUSCHEN
			- WALD_MASKE_WELLE * sin(s * 0.09);
	float m = smoothstep(WALD_MASKE_VON, WALD_MASKE_BIS, d);
	return max(m, smoothstep(WALD_RAND_VON, WALD_RAND_BIS, abs(q_norm)));
}


float wegmaske(float q_norm, float s, vec2 welt_xz) {
	return wegmaske_aus(q_norm, s, wald_welt(welt_xz).r);
}


// Helligkeitsfaktor der Makrovariation (0,82–1,12): die 20-m-Flecken (G)
// zu zwei Dritteln, die 4-m-Flecken (B) zu einem Drittel.
float makro_aus(vec4 w) {
	float t = 0.65 * smoothstep(0.18, 0.82, w.g) + 0.35 * smoothstep(0.2, 0.8, w.b);
	return mix(WALD_MAKRO_TIEF, WALD_MAKRO_HOCH, t);
}


float makro(vec2 welt_xz) {
	return makro_aus(wald_welt(welt_xz));
}


// Anteil der trockenen, strohigen Stellen (0..1), wo die 4-m-Flecken (B)
// am höchsten sind.
float trocken_aus(vec4 w) {
	return smoothstep(0.68, 0.86, w.b);
}


// Die Rasentextur selbst: RGB Farbe, A Halmdichte (0 = Lücke, 1 = Büschel).
vec4 rasen_textur(vec2 welt_xz) {
	return texture(wald_rasen, welt_xz * wald_rasen_kachel);
}


// Rasenfarbe aus Textur und Weltrauschen: Makro und trockene Stellen.
vec3 rasen_farbe_aus(vec3 textur, vec4 w) {
	vec3 c = textur * makro_aus(w);
	return mix(c, c * WALD_TROCKEN_TON, trocken_aus(w) * 0.7);
}


// Rasenfarbe an einer Stelle (zwei Texturzugriffe).
vec3 rasen_farbe(vec2 welt_xz) {
	return rasen_farbe_aus(rasen_textur(welt_xz).rgb, wald_welt(welt_xz));
}


// Texturkoordinate der treibenden Kronenlicht-Lage zur Zeit `t`.
vec2 kronen_uv(vec2 welt_xz, float t) {
	return welt_xz * wald_kachel * WALD_KRONEN_FEIN + WALD_KRONEN_DRIFT * t;
}


// Lichtflecken unter dem Kronendach, 0 (Schatten) .. 1 (Fleck). `ruhend`
// ist der A-Kanal aus `wald_welt()`; die treibende Lage kostet einen
// zweiten Zugriff. Zwei Lagen, die gegeneinander wandern, flirren wie
// Laub im Wind, statt als Muster über den Boden zu ziehen.
float kronenlicht_aus(float ruhend, vec2 welt_xz, float t) {
	float treibend = texture(wald_rauschen, kronen_uv(welt_xz, t)).a;
	return smoothstep(0.55, 0.63, ruhend * 0.5 + treibend * 0.5);
}


// Dasselbe mit vorab geholten Ableitungen der Texturkoordinate: für
// Stoffe, die das Kronenlicht nur in einem Zweig holen (in einer
// Verzweigung je Bildpunkt wären implizite Ableitungen undefiniert).
float kronenlicht_grad(float ruhend, vec2 uv, vec2 uv_dx, vec2 uv_dy) {
	float treibend = textureGrad(wald_rauschen, uv, uv_dx, uv_dy).a;
	return smoothstep(0.55, 0.63, ruhend * 0.5 + treibend * 0.5);
}


float kronenlicht(vec2 welt_xz, float t) {
	return kronenlicht_aus(wald_welt(welt_xz).a, welt_xz, t);
}


// Faktor für die Albedo: Rasen ×0,78–1,08, Pfad ×0,9–1,05, gemischt nach
// `rasen` (Wegmaske), abgeschwächt nach `staerke` (0 = kein Kronendach).
// Schatten etwas kühler, Flecken etwas wärmer.
vec3 kronen_faktor(float licht, float staerke, float rasen) {
	float pfad_f = mix(0.90, 1.05, licht);
	float rasen_f = mix(0.78, 1.08, licht);
	float f = mix(pfad_f, rasen_f, rasen);
	vec3 ton = mix(vec3(0.97, 1.0, 1.03), vec3(1.04, 1.01, 0.95), licht);
	return mix(vec3(1.0), ton * f, clamp(staerke, 0.0, 1.0));
}
