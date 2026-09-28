shader_type spatial;
// Randlicht und Trefferblitz der Gegner – als `material_overlay` über die
// eigentlichen Materialien gelegt. Die bleiben dabei unberührt: Sie sind
// geteilt (Fremdmodelle-Zwischenspeicher, Materialbibliothek), und ein
// Blitz auf einem geteilten Material ließe jeden Frosch des Levels
// aufleuchten. Das Overlay dagegen gehört einem einzigen Gegner.
//
// RANDLICHT: Der dunkle Käfer und die dunkle Spinne standen auf dunklem
// Waldboden und verschwammen mit ihm. Ein heller Saum an der Silhouette
// (Fresnel) trennt sie davon, ohne ihre Farbe zu ändern.
// Der Saum ist LICHT, das über die Kante streift: Er entsteht nur, wo ein
// Licht die Kante trifft (eigenes `light()`), und fällt im Schatten weg.
// Ohne Umgebungslicht (`ambient_light_disabled`): Im ersten Versuch färbte
// das blaue Himmelslicht von Level 01 den ganzen Saum bläulich, und ein
// unbeleuchteter Saum leuchtete in dunklen Ecken wie ein Warnschild.
//
// TREFFERBLITZ: `blitz` 1 → 0 färbt den ganzen Gegner einen Augenblick
// weiß – über EMISSION, also unabhängig vom Licht.
//
// RENDERER: gl_compatibility. Keine Bildschirm- oder Tiefentextur.
// `fog_disabled`, weil Nebel ein ADDITIVES Material nicht ausblendet,
// sondern die Nebelfarbe draufaddiert: Ferne Gegner bekämen einen
// hellgrünen Schleier. Stattdessen blendet `fern` den Saum mit dem
// Abstand selbst aus.
render_mode blend_add, depth_draw_never, cull_back, fog_disabled,
		ambient_light_disabled, specular_disabled;

// Farbe und Stärke des Saums. Stärke 0 = nur Blitz (eigene Optik der
// prozeduralen Gegner, die den Saum nicht brauchen).
uniform vec4 rand_farbe : source_color = vec4(1.0, 0.92, 0.78, 1.0);
uniform float rand_staerke : hint_range(0.0, 2.0) = 1.4;
// Je höher, desto schmaler der Saum.
uniform float rand_schaerfe : hint_range(1.0, 8.0) = 3.0;
// Wie weit das Licht um die Kante herumgreift (0 = streng nur die
// beleuchtete Seite, 0,5 = weit herum).
uniform float umgriff : hint_range(0.0, 1.0) = 0.5;
// Ab hier (Meter) ist der Saum ganz weg; ab 60 % davon blendet er aus.
uniform float fern = 34.0;
// Trefferblitz, 0..1.
uniform float blitz : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float kante = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float saum = pow(kante, rand_schaerfe);
	float nah = 1.0 - smoothstep(fern * 0.6, fern, -VERTEX.z);
	ALBEDO = rand_farbe.rgb * rand_staerke * saum * nah;
	EMISSION = vec3(blitz);
}

void light() {
	// Umwickelte Lambert-Beleuchtung: Die Kante leuchtet auch dort noch,
	// wo das Licht sie gerade eben streift. LIGHT_COLOR enthält Energie·π.
	float nl = clamp((dot(NORMAL, LIGHT) + umgriff) / (1.0 + umgriff), 0.0, 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * nl / PI;
}
