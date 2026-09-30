// Gemeinsamer Fels der Kanten und des Geländes (Level 01, Plan 8.3/8.4).
//
// `fels_schichten` (Saum) und `gelaende` (Fels des Höhenfelds) binden diese
// Datei NACH `wald_gemeinsam` ein. Beide legen damit dieselben Schichtbänder
// in Weltkoordinaten über ihren Fels – die Felswand der Fallklamm, der
// Rücken der Rippe von C4, der Abbruch des Hallenwalds und die Lippen des
// Erdspalts lesen sich so als eine Geologie. Die Phase ist dieselbe Formel
// wie `GelaendeSaum.schicht()` (CPU, die Geometrie tritt mit denselben
// Bändern vor und zurück); wer sie ändert, ändert beide.
//
// RELIEF. Beide Stoffe rechnen ihre Reliefnormale aus Bildschirm-
// ableitungen einer Höhe. Die Ableitungen gelten je 2×2-Pixelblock: Eine
// Höhe mit feinem Korn (die Felstextur mit ihren längs gezogenen Streifen)
// gab je Block eine eigene Normale – aus mittlerer Entfernung eine Treppe
// aus Pixeln, ein Ziegelmuster. Deshalb kommt die Höhe aus einem zwei
// Mipstufen gröberen Abgriff (`fels_grob`, Ableitungen ×4), die Kanten der
// Bänke tragen einen Teil davon (`fels_bank_hoehe`), und das Relief
// verblasst mit der Entfernung (`fels_relief_nah`): Dort gäbe es nur noch
// Pixelrauschen.
//
// Belegte Namen: `fels_band_hash`, `fels_phase`, `fels_band_hell`,
// `fels_ist_kalk`, `fels_bank_hoehe`, `fels_relief_nah`, `fels_relief_normale`,
// `fels_achse`.

float fels_band_hash(float b) {
	return fract(sin(b * 12.9898 + 3.7) * 43758.5453);
}

// Lage in den Schichten: floor() = Band, fract() = Lage im Band (0 unten,
// 1 oben). `g` = G-Kanal des Weltrauschens (`wald_welt`).
float fels_phase(vec3 welt, float g, float dichte, vec2 neigung) {
	return welt.y * dichte + dot(welt.xz, neigung) + (g - 0.5) * 1.1
			+ 0.22 * sin(welt.y * 0.61 + 1.7);
}

// Helligkeit eines Bandes: je Band 0,8 … 1,12 (von Band zu Band kräftig
// verschieden, sonst liest sich die Wand als Torte aus gleichen Lagen), im
// Band nach unten etwas dunkler, an der Fuge dunkel.
float fels_band_hell(float phase) {
	float band = floor(phase);
	float innen = phase - band;
	float kenn2 = fels_band_hash(band + 31.0);
	float fuge = 1.0 - smoothstep(0.0, 0.05, innen);
	return (0.8 + 0.32 * kenn2) * mix(1.0, 0.93, 1.0 - innen) * (1.0 - 0.3 * fuge);
}

// Jede vierte Bank ist heller Kalk statt Sandstein; `b` = B-Kanal des
// Weltrauschens (Flecken), damit die Wahl nicht über die ganze Welt gleich
// liegt.
bool fels_ist_kalk(float phase, float b) {
	return fels_band_hash(floor(phase)) + (b - 0.5) * 0.3 > 0.74;
}

// Die Bankkante als Höhe: Oben auf einer Bank hoch, an der Fuge darunter
// tief – das Relief folgt so den Schichten, nicht dem Korn der Textur.
float fels_bank_hoehe(float phase) {
	float innen = fract(phase);
	return smoothstep(0.0, 0.08, innen) * (1.0 - 0.35 * smoothstep(0.55, 1.0, innen));
}

// Stärke des Reliefs nach Entfernung (m): voll bis `von`, 0 ab `bis`.
float fels_relief_nah(vec3 vertex, float von, float bis) {
	return 1.0 - smoothstep(von, bis, length(vertex));
}

// Welche Projektion der Dreifachprojektion vorherrscht: 0 = zy (x-Normale),
// 1 = xz (oben), 2 = xy (z-Normale).
int fels_achse(vec3 gewichte) {
	if (gewichte.x >= gewichte.y && gewichte.x >= gewichte.z) {
		return 0;
	}
	return gewichte.y >= gewichte.z ? 1 : 2;
}

// Reliefnormale aus der Höhe `h` (Bildschirmableitungen, kein
// Tangentenraum). Nur in gleichförmigem Kontrollfluss aufrufen.
vec3 fels_relief_normale(vec3 normale, vec3 vertex, float h, float staerke) {
	vec3 dpx = dFdx(vertex);
	vec3 dpy = dFdy(vertex);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpy, normale);
	vec3 r2 = cross(normale, dpx);
	float det = dot(dpx, r1);
	vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * normale - gefaelle * staerke);
}
