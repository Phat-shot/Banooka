shader_type spatial;
// Wirbelnde Portalscheibe – für `Portal` (Start/Ziel im Level) und die
// Levelportale im Hub. Gedacht für ein QuadMesh (2·r × 2·r): Die Scheibe
// ist der Kreis in den UVs 0..1, alles außerhalb wird verworfen.
//
// WARUM KEIN ZYLINDER: Die UVs der Zylinderkappen liegen in Godot nicht
// auf 0..1 (die Kappen teilen sich den Atlas mit der Mantelfläche). Ein
// Viereck hat saubere UVs, zwei Dreiecke statt 64 – und rund wird es hier.
//
// RENDERER: gl_compatibility (Web, Mobil). Deshalb KEIN SCREEN_TEXTURE,
// kein DEPTH_TEXTURE, keine Textur überhaupt: Das Muster ist rein
// rechnerisch (Winkel, Abstand, ein kleines Wertrauschen). `discard`,
// `atan` und `exp` gibt es in GLSL ES 3.0 überall.
//
// WARUM blend_mix UND NICHT blend_add: Additiv brennt die Scheibe vor
// hellem Himmel und hellem Hub-Boden zu Weiß aus und verschwindet vor
// Schwarz ganz im Kern. Gemischt bleibt sie in beiden Fällen dieselbe
// Farbe – ein Tor in eine andere Welt, kein Loch in dieser. Den Schein
// liefert der helle Saum, der über `helligkeit` auch über 1 gehen darf.
//
// Alle Farben kommen vom Skript (`Effekte.wirbelstoff()` leitet Kern und
// Saum aus einer Grundfarbe ab). `puls` ist der einzige Wert, den ein
// Skript pro Bild setzen sollte – der Wirbel selbst läuft über TIME.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

// --- Farben ---
uniform vec4 farbe : source_color = vec4(0.35, 0.85, 0.55, 1.0);      // Grundton außen
uniform vec4 kern : source_color = vec4(0.04, 0.16, 0.10, 1.0);       // Mitte: dunkel = Tiefe
uniform vec4 saum_farbe : source_color = vec4(0.80, 1.0, 0.88, 1.0);  // Leuchtsaum am Rand

// --- Regler ---
uniform float helligkeit = 1.25;          // Gesamthelligkeit (über 1 = Schein)
uniform float deckkraft : hint_range(0.0, 1.0) = 0.92;
uniform float tempo = 0.9;                // Drehung in Radiant je Sekunde
uniform float richtung = 1.0;             // +1 / -1: Drehsinn (Ziel saugt, Start stößt aus)
uniform float drall = 4.0;                // wie stark sich die Arme zur Mitte aufwickeln
uniform float arme = 3.0;                 // Anzahl der Spiralarme
uniform float saum_breite : hint_range(0.01, 0.4) = 0.07;  // Breite des Leuchtsaums (Anteil am Radius)
uniform float kante : hint_range(0.005, 0.3) = 0.035;      // weiche Alphakante ganz außen
uniform float sog : hint_range(0.0, 2.0) = 0.7;            // heller Punkt in der Mitte
uniform float puls : hint_range(0.0, 1.0) = 0.5;           // vom Skript, atmet mit dem Licht


// Wertrauschen ohne Textur. Die Eingaben bleiben klein (|p| < 10), damit
// der sin-Hash auch mit mittlerer Genauigkeit auf Mobilgeräten nicht
// in Streifen zerfällt.
float _zufall(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float _rauschen(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = _zufall(i);
	float b = _zufall(i + vec2(1.0, 0.0));
	float c = _zufall(i + vec2(0.0, 1.0));
	float d = _zufall(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Dreht p um w (Radiant).
vec2 _drehen(vec2 p, float w) {
	float s = sin(w);
	float c = cos(w);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}


void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}

	// Der Wirbel: Jeder Ring dreht sich um einen Winkel, der zur Mitte
	// hin wächst (`drall`). Dadurch biegen sich gerade Arme zu Spiralen,
	// und weil die Zeit dazukommt, laufen sie nach innen – das Auge liest
	// das als Sog, obwohl sich nur Winkel drehen.
	float t = TIME * tempo * richtung;
	vec2 q = _drehen(p, t + drall * (1.0 - r));
	float w = atan(q.y, q.x);
	float arm = 0.5 + 0.5 * sin(w * arme + r * 2.0);

	// Rauschen im mitgedrehten Raum: bricht die Arme in Schlieren auf.
	// Zwei Lagen mit verschiedenem Drehtempo, sonst wirkt es wie ein
	// starres Bild auf einem Plattenteller.
	float n1 = _rauschen(q * 3.2 + vec2(3.7, 1.3));
	float n2 = _rauschen(_drehen(p, -t * 0.6 + drall * 0.5 * (1.0 - r)) * 5.5 + vec2(9.1, 4.2));
	float muster = clamp(arm * 0.6 + n1 * 0.3 + n2 * 0.25, 0.0, 1.0);
	// Zur Mitte hin laufen alle Arme in einem Punkt zusammen und bilden
	// dort ein spitzes Windrad. Deshalb wird das Muster innen glatt.
	muster = mix(0.5, muster, smoothstep(0.0, 0.3, r));

	// Farbverlauf von außen (farbe) nach innen (kern).
	float innen = 1.0 - smoothstep(0.05, 0.85, r);
	vec3 grund = mix(farbe.rgb, kern.rgb, innen);
	grund *= 0.45 + 1.0 * muster;

	// Leuchtsaum knapp innerhalb der Kante (Gaußglocke um 1 - saum_breite).
	float abstand = (r - (1.0 - saum_breite)) / saum_breite;
	float saum = exp(-abstand * abstand * 2.2);
	// Heller Kern ganz in der Mitte – dort, wohin der Sog zieht.
	float mitte = exp(-r * r * 30.0) * sog;

	float atmen = 0.85 + 0.3 * puls;
	// Der Saum bleibt unter 1: Das Portal hat meist noch einen eigenen
	// leuchtenden Ring darum, zusammen brannten sie im ersten Probelauf zu
	// einem breiten weißen Band aus.
	vec3 licht = grund + saum_farbe.rgb * (saum * (0.35 + 0.25 * puls) + mitte);
	ALBEDO = licht * helligkeit * atmen;

	// Alpha: Die Arme sind dichter als die Zwischenräume, der Saum ist
	// ganz deckend, und die äußerste Kante läuft weich aus – sonst
	// flimmert der Kreisrand ohne Kantenglättung (das Projekt hat kein MSAA).
	float dicht = deckkraft * (0.75 + 0.25 * muster);
	float rand_weg = 1.0 - smoothstep(1.0 - kante, 1.0, r);
	ALPHA = clamp(dicht + saum * 0.8, 0.0, 1.0) * rand_weg;
}
