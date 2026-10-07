extends RefCounted
class_name Nebelstoff
## Eigener Nebel in einer Abschrift eines Stoffs – für Silhouetten, die im
## Dunst stehen sollen, aber nicht im VOLLEN Dunst (Baukasten Raum 1, Paket
## G3; Herkunft `L01Weltenbaum._nebelarm`, weltenbaum.gd:215-242, 278-292,
## 436-466).
##
## WARUM. Der Tiefennebel der Umgebung deckt eine ferne Silhouette ganz zu:
## In Level 01 lag der Weltenbaum vom Grat aus auf dem Wert des fernen
## Talwalds, die Krone las sich als ein paar blasse Schirmkiefern. Die
## Abschrift zeichnet ihren Nebel selbst (FOG im Stoff, gl_compatibility-
## tauglich) – mit Farbe, Strecke und Kurve der Umgebung, aber nur zu einem
## Anteil. So bleibt eine dunkle Form vor dem Dunst stehen.
##
## WIE. Der Shader des Stoffs bekommt fünf Uniforms und eine Zeile am Anfang
## von `fragment()`. Der Shader mit eigenem Nebel entsteht einmal je
## Quellshader (`_shader`, ein Übersetzungszwischenspeicher, kein Level-
## zustand – Baukasten §0 Nr. 3); der Stoff ist eine Abschrift je Aufruf,
## der geteilte Quellstoff bleibt unberührt. Ohne passende Stelle im Code
## (kein oder mehr als ein `void fragment() {`, oder der Shader setzt schon
## FOG) bleibt der Stoff, wie er ist.
##
## UNTERSCHIED ZU LEVEL 01. Level 01 sammelt die Abschriften statisch für
## seinen Stimmungsregler (`L01Weltenbaum.nebel_stoffe`) und liest die
## Umgebung aus dem Levelknoten. Hier gibt es keine Liste: Der Aufrufer hält
## die Abschriften selbst (z. B. für `Stimmungsregler`) und reicht die
## Umgebung herein. Rechenweg und Shadertext sind wörtlich dieselben –
## `werkzeuge/baukastenprobe.gd` vergleicht beides mit dem Original.

## Anteil am Nebel der Umgebung, wenn der Aufrufer keinen nennt.
const ANTEIL := 0.5

const NEBEL_UNIFORMS := """
uniform vec3 nebel_farbe = vec3(0.18, 0.31, 0.5);
uniform float nebel_von = 12.0;
uniform float nebel_bis = 140.0;
uniform float nebel_kurve = 1.1;
uniform float nebel_dichte = 0.0;
"""
const NEBEL_ZEILE := """
	FOG = vec4(nebel_farbe, pow(smoothstep(nebel_von, nebel_bis, length(VERTEX)), nebel_kurve)
			* nebel_dichte);
"""

## Shader mit eigenem Nebel je Quellshader (einmal übersetzt, nie verändert).
static var _shader := {}


## Eine Abschrift von `stoff` mit eigenem Nebel zum Anteil `anteil`,
## eingestellt auf `umgebung` (null: Vorgaben des Shaders, Dichte 0 – bis
## `nebel_setzen` sie nachträgt). Ein anderer Anteil als `ANTEIL` steht als
## Meta "nebel_anteil" am Stoff.
static func nebelarm(stoff: Material, umgebung: Environment, anteil: float = ANTEIL) -> Material:
	var alt := stoff as ShaderMaterial
	if alt == null or alt.shader == null:
		return stoff
	var shader: Shader = _shader.get(alt.shader)
	if shader == null:
		const MARKE := "void fragment() {"
		var code := alt.shader.code
		if code.count(MARKE) != 1 or code.contains("FOG"):
			push_warning("Nebelstoff: Stoff ohne eigenen Nebel (Shader unerwartet).")
			return stoff
		shader = Shader.new()
		shader.code = code.replace(MARKE, NEBEL_UNIFORMS + "\n" + MARKE + NEBEL_ZEILE)
		_shader[alt.shader] = shader
	var neu := alt.duplicate() as ShaderMaterial
	neu.shader = shader
	if not is_equal_approx(anteil, ANTEIL):
		neu.set_meta("nebel_anteil", anteil)
	if umgebung != null:
		nebel_setzen(neu, umgebung)
	return neu


## Schreibt Farbe, Strecke, Kurve und Dichte des Nebels von `umgebung` in
## eine Abschrift aus `nebelarm` (Dichte mal Anteil). Die Farbe geht linear
## in den Shader, wie der Renderer sein Nebellicht rechnet. Für Regler, die
## den Nebel je Zone ändern.
static func nebel_setzen(stoff: ShaderMaterial, umgebung: Environment) -> void:
	var anteil := float(stoff.get_meta("nebel_anteil", ANTEIL))
	var c := umgebung.fog_light_color.srgb_to_linear()
	var e := umgebung.fog_light_energy
	stoff.set_shader_parameter("nebel_farbe", Vector3(c.r, c.g, c.b) * e)
	stoff.set_shader_parameter("nebel_von", umgebung.fog_depth_begin)
	stoff.set_shader_parameter("nebel_bis", umgebung.fog_depth_end)
	stoff.set_shader_parameter("nebel_kurve", umgebung.fog_depth_curve)
	stoff.set_shader_parameter("nebel_dichte",
			umgebung.fog_density * anteil if umgebung.fog_enabled else 0.0)
