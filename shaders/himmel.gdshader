shader_type sky;
// Eigener Himmel für Banooka – Verlauf, Dunstband, Sonnenschein, Wolken.
//
// Ersetzt dort, wo er eingesetzt ist, den ProceduralSkyMaterial. Der
// hat zwei Schwächen, die im Korridor auffallen: Sein Horizont hat eine
// feste Farbe, die nicht zum Nebel passt – die vernebelten Silhouetten
// am Ende der Schlucht klebten dunkel auf hellem Himmel –, und er kennt
// weder Wolken noch einen warmen Schein in Richtung der Sonne.
//
// WAS MAN IM SPIEL SIEHT: Die Verfolgerkamera schaut rund 18° nach
// unten, sichtbar ist also nur das Band vom Horizont bis etwa 12°
// darüber. Deshalb steckt der Aufwand dort: Das unterste Stück
// (`dunst_hoehe`) trägt die Nebelfarbe, damit vernebelte Wände und
// Kronen nahtlos in den Himmel übergehen – das ersetzt die Luft-
// perspektive des Nebels, die der Compatibility-Renderer nicht rechnet.
//
// RENDERER: gl_compatibility. Deshalb gilt:
//  - KEIN TIME und kein POSITION. Ein Himmel, der eines davon liest, wird
//    jedes Bild neu in die Radiance-Cubemap gerendert und gefiltert.
//    Ohne sie rendert er genau einmal.
//  - Keine Uniforms pro Bild setzen – jede Änderung macht den Himmel
//    „schmutzig" und löst dasselbe aus. Treibende Wolken gehörten auf
//    eine eigene Kuppel, nicht hierher.
//  - LIGHT0 ist das erste Richtungslicht, das NICHT auf „nur Licht"
//    (sky_mode = 1) steht. Füll- und Hauptlichter, die den Himmel nicht
//    bemalen sollen, stehen deshalb auf sky_mode = 1.

// --- Verlauf ---
uniform vec3 zenit : source_color = vec3(0.24, 0.46, 0.74);
uniform vec3 horizont : source_color = vec3(0.70, 0.80, 0.80);
uniform vec3 dunst : source_color = vec3(0.34, 0.42, 0.38);     // = Nebelfarbe des Levels
uniform vec3 boden : source_color = vec3(0.12, 0.16, 0.13);     // unter dem Horizont
uniform float verlauf_kurve = 0.5;     // < 1: Blau setzt früh ein
uniform float dunst_hoehe = 0.07;      // Höhe des Dunstbands (Sinus des Winkels)

// --- Schein zur Sonne hin (warmes Leuchten am Horizont) ---
uniform vec3 schein_farbe : source_color = vec3(1.0, 0.80, 0.52);
uniform float schein_breite = 4.0;     // größer = schmaler um die Sonnenrichtung
uniform float schein_staerke = 0.7;
uniform float hof_staerke = 0.5;       // Lichthof direkt um die Sonne
uniform float scheibe_staerke = 0.0;   // 0 = keine harte Sonnenscheibe
uniform float scheibe_groesse = 0.9994; // Kosinus des Scheibenradius

// --- Ferne Hügel am Horizont ---
uniform float huegel_hoehe = 0.0;      // höchste Kuppe (Sinus des Winkels), 0 = keine

// --- Wolken ---
uniform sampler2D wolken : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float wolken_menge = 0.52;     // Schwelle: höher = weniger Wolken
uniform float wolken_weich = 0.2;
uniform float wolken_skala = 0.2;
uniform float wolken_deckung = 0.85;
uniform vec3 wolke_hell : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 wolke_schatten : source_color = vec3(0.62, 0.68, 0.76);


void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;

	// Richtung zur Sonne. Ohne LIGHT0 ein Punkt im Zenit – dann gibt es
	// keinen Schein am Horizont, der Himmel bleibt trotzdem stimmig.
	vec3 s = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0, 1.0, 0.0);
	vec3 licht = LIGHT0_ENABLED ? LIGHT0_COLOR : vec3(0.0);
	float zur_sonne = max(dot(d, s), 0.0);
	// Nur der Azimut: Der Schein liegt als breiter Fächer am Horizont,
	// nicht als Kreis um die Sonne.
	vec2 dxz = d.xz + vec2(1e-4);
	vec2 sxz = s.xz + vec2(1e-4);
	float azimut = max(dot(normalize(dxz), normalize(sxz)), 0.0);

	vec3 himmel = mix(horizont, zenit, pow(clamp(h, 0.0, 1.0), verlauf_kurve));
	himmel += schein_farbe * licht * pow(zur_sonne, 24.0) * hof_staerke;

	if (h > 0.0) {
		// Ebene Wolkendecke, zum Horizont hin gestaucht.
		vec2 uv = d.xz / (h + 0.12) * wolken_skala;
		float n = texture(wolken, uv).r * 0.65 + texture(wolken, uv * 2.7 + vec2(0.31, 0.17)).r * 0.35;
		float dichte = smoothstep(wolken_menge, wolken_menge + wolken_weich, n)
				* smoothstep(0.015, 0.16, h);
		vec3 wolke = mix(wolke_schatten, wolke_hell, smoothstep(wolken_menge, wolken_menge + 0.35, n));
		// Sonnenseitige Ränder leuchten warm – dünne Stellen stärker.
		wolke += schein_farbe * licht * pow(zur_sonne, 5.0) * (1.0 - dichte * 0.6) * 0.7;
		himmel = mix(himmel, wolke, dichte * wolken_deckung);
	}

	if (scheibe_staerke > 0.0) {
		himmel += licht * smoothstep(scheibe_groesse, scheibe_groesse + 0.0003, zur_sonne) * scheibe_staerke;
	}

	// Dunstband: Es liegt VOR den Wolken, genau wie der Nebel vor den
	// fernen Wänden.
	himmel = mix(dunst, himmel, smoothstep(0.0, dunst_hoehe, h));
	vec3 farbe = h >= 0.0 ? himmel : mix(dunst, boden, smoothstep(0.0, 0.3, -h));

	// Ferne Hügelketten als Silhouette – keine Geometrie, nur zwei
	// Lesungen der Wolkentextur entlang des Horizonts. Ohne sie endet der
	// Blick über die Lichtung in leerem Dunst. Die hintere Kette steht
	// heller (mehr Luft davor), die vordere trägt genau die Nebelfarbe:
	// Dort geht vernebelte Geometrie nahtlos in den Himmel über.
	// textureLod statt texture: Am Sprung des atan (Süden) gäbe die
	// Mip-Wahl sonst eine senkrechte Naht.
	if (huegel_hoehe > 0.0) {
		float az = atan(d.x, d.z) * (1.0 / 6.2831853);
		float p_fern = textureLod(wolken, vec2(az * 3.0, 0.23), 0.0).r;
		float p_nah = textureLod(wolken, vec2(az * 5.0 + 0.5, 0.71), 0.0).r;
		float kamm_fern = huegel_hoehe * (0.25 + 0.9 * p_fern);
		float kamm_nah = huegel_hoehe * (0.05 + 0.6 * p_nah);
		farbe = mix(farbe, mix(dunst, horizont, 0.45),
				1.0 - smoothstep(kamm_fern - 0.0015, kamm_fern + 0.0015, h));
		farbe = mix(farbe, dunst, 1.0 - smoothstep(kamm_nah - 0.0015, kamm_nah + 0.0015, h));
	}

	// Warmer Schein in Richtung der Sonne, über Himmel, Dunst und Hügeln
	// zugleich – wie die Streuung des Nebels auf der fernen Geometrie.
	farbe += schein_farbe * licht * pow(azimut, schein_breite)
			* (1.0 - smoothstep(0.0, 0.45, abs(h))) * schein_staerke;
	COLOR = farbe;

	// Feines Rauschen gegen Farbstufen im flachen Verlauf. Nur im Bild,
	// nicht in der Cubemap – dort wäre es ohnehin weggefiltert.
	if (!AT_CUBEMAP_PASS) {
		float r = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
		COLOR += (r - 0.5) / 255.0;
	}
}
