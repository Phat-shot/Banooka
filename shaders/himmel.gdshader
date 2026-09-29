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
// UNTER dem Horizont sieht man ihn überall, wo die Schlucht aufgeht,
// und am Ende hinter dem Zielportal: Dort stehen gestaffelte Waldrücken
// (`wald_kante`), dunkel, damit die hellste Fläche der Weg bleibt.
//
// Die Textur `wolken` trägt Wolken, Hügel und Waldrücken zugleich. Eine
// NoiseTexture2D wird beim Laden auf der CPU erzeugt (die erste Erzeugung
// synchron, im Browser ohne Faden): 256² reicht, 512² sah gleich aus und
// kostete viermal so lange.
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
uniform float boden_uebergang = 0.3;   // ohne Waldkanten: so tief unter dem Horizont ist der Dunst ganz `boden`

// --- Schein zur Sonne hin (warmes Leuchten am Horizont) ---
uniform vec3 schein_farbe : source_color = vec3(1.0, 0.80, 0.52);
uniform float schein_breite = 4.0;     // größer = schmaler um die Sonnenrichtung
uniform float schein_staerke = 0.7;
uniform float hof_staerke = 0.5;       // Lichthof direkt um die Sonne
uniform float scheibe_staerke = 0.0;   // 0 = keine harte Sonnenscheibe
uniform float scheibe_groesse = 0.9994; // Kosinus des Scheibenradius

// --- Ferne Hügel am Horizont ---
uniform float huegel_hoehe = 0.0;      // höchste Kuppe (Sinus des Winkels), 0 = keine

// --- Wald unter dem Horizont ---
uniform float wald_kante = 0.0;        // Tiefe der fernsten Waldkante (Sinus), 0 = glatter Verlauf

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

	// Unter dem Horizont: der Blick hinab auf fernen Wald – am Ende der
	// Schlucht und überall, wo sie aufgeht. Nah am Horizont ist der Wald
	// weit weg und steckt im Dunst, steiler nach unten ist er näher und
	// dunkelgrün. Hell darf dort nichts sein, sonst leuchtet hinter dem
	// Wegende eine Fläche, die heller ist als der Weg selbst – der
	// Lesbarkeitsvertrag verlangt: Wo der Weg aufhört, hört die Helligkeit auf.
	// az läuft einmal um den Horizont, -0,5 bis 0,5 mit Sprung im Süden.
	// textureLod statt texture: Am Sprung des atan gäbe die Mip-Wahl sonst
	// eine senkrechte Naht. Ganzzahlige Wiederholungen schließen die Naht.
	float az = atan(d.x, d.z) * (1.0 / 6.2831853);
	float tiefe = max(-h, 0.0);
	vec3 tal = mix(dunst, boden, smoothstep(0.0, boden_uebergang, tiefe));
	if (wald_kante > 0.0 && h < 0.0) {
		// Bewaldete Rücken hintereinander wie Kulissen, in den Tälern
		// dazwischen liegt Nebel: Jeder Rücken ist oben an den Kronen am
		// dunkelsten und verschwimmt nach unten im Dunst, bis der nächste,
		// nähere Rücken ihn verdeckt. Nähere Rücken sind dunkler und tragen
		// größere Kronen. Ohne diese Staffelung las sich die dunkle Fläche
		// als See – mit hellem oberen Rand sogar als Spiegelung.
		float anteil = 0.0;   // 0 = Dunst, 1 = Boden
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			float mass = 1.0 + fi * (1.1 + fi * 0.55);                 // 1; 2,65; 5,4; 9,25
			float lage = wald_kante * mass;
			// Flach gewellter Rücken aus der Wolkentextur (textureLod, siehe oben).
			float grob = textureLod(wolken, vec2(az * (3.0 + 2.0 * fi), 0.11 + 0.23 * fi), 0.0).r;
			float ruecken = -lage * (0.85 + 0.3 * grob);
			// Kronen: zwei gegeneinander versetzte Reihen von Kuppeln, jede
			// per Zufall anders hoch – die höhere gewinnt. Eine gerade Anzahl
			// je Umlauf, damit am Sprung des atan eine Kronengrenze liegt und
			// keine Krone zerschnitten wird.
			float anzahl = 2.0 * floor(150.0 / sqrt(mass));
			float kronen = 0.0;
			for (int reihe = 0; reihe < 2; reihe++) {
				float t = az * anzahl + float(reihe) * 0.5;
				float zelle = mod(floor(t), anzahl);
				float x = fract(t) * 2.0 - 1.0;
				float zufall = fract(sin(zelle * 12.9898 + fi * 78.233 + float(reihe) * 3.7) * 43758.5453);
				kronen = max(kronen, sqrt(max(1.0 - x * x, 0.0)) * (0.55 + 0.45 * zufall));
			}
			float kante = ruecken + kronen * 2.5 / anzahl;
			float drin = 1.0 - smoothstep(kante - 0.0012, kante + 0.0012, h);
			// Nebel im Tal unter dem Rücken, gemessen am glatten Rücken statt
			// an den Kronen – sonst zöge jede Krone einen senkrechten Streifen
			// nach unten. Der vorderste Rücken bleibt ohne: Er füllt den Blick
			// nach unten, und dort soll es dunkel sein.
			float nebel = i < 3 ? 0.55 * smoothstep(0.0, lage * 0.9, ruecken - h) : 0.0;
			float dunkel = 0.35 + 0.65 * (fi + 1.0) / 4.0;
			anteil = mix(anteil, dunkel * (1.0 - nebel), drin);
		}
		tal = mix(dunst, boden, anteil);
	}
	vec3 farbe = h >= 0.0 ? himmel : tal;

	// Ferne Hügelketten als Silhouette – keine Geometrie, nur zwei
	// Lesungen der Wolkentextur entlang des Horizonts. Ohne sie endet der
	// Blick über die Lichtung in leerem Dunst. Die hintere Kette steht
	// heller (mehr Luft davor), die vordere trägt genau die Nebelfarbe:
	// Dort geht vernebelte Geometrie nahtlos in den Himmel über.
	// Die Hügel stehen AUF dem Horizont: Darunter liegt der Wald. Ohne
	// diese Grenze deckten sie die ganze untere Hälfte mit hellem Dunst zu.
	if (huegel_hoehe > 0.0 && h >= 0.0) {
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
	// Unter dem Horizont nur im schmalen Dunst, nicht auf dem dunklen Tal.
	float band = h >= 0.0 ? 1.0 - smoothstep(0.0, 0.45, h) : 1.0 - smoothstep(0.0, 0.1, -h);
	farbe += schein_farbe * licht * pow(azimut, schein_breite) * band * schein_staerke;
	COLOR = farbe;

	// Feines Rauschen gegen Farbstufen im flachen Verlauf. Nur im Bild,
	// nicht in der Cubemap – dort wäre es ohnehin weggefiltert. COLOR ist
	// linear, die Stufen entstehen erst nach der sRGB-Umrechnung: Eine
	// Stufe ist im Hellen linear mehrfach so breit wie im Dunkeln. Die
	// Potenz folgt ungefähr der Steigung der sRGB-Kurve, sodass das
	// Rauschen überall rund eine Stufe breit ist – gerade im hellen
	// Dunstband, wo man Stufen sonst sähe.
	if (!AT_CUBEMAP_PASS) {
		float r = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
		COLOR += (r - 0.5) * (3.0 / 255.0) * pow(max(COLOR, vec3(1e-4)), vec3(0.58));
	}
}
