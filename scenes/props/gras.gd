extends MultiMeshInstance3D
class_name Grasfeld
## Grasbüschel-Feld auf Basis eines MultiMesh.
##
## EIN Knoten, EIN Draw-Call, mehrere hundert Büschel. Jedes Büschel besteht
## aus vielen kurzen, übergebogenen Halmen. Der Wind läuft
## komplett im Vertex-Shader – es wird also kein einziger Knoten pro Frame
## angefasst.
##
## Warum kurz und breit: einzelne hohe, spitze Halme lesen sich aus
## Spielerhöhe wie Schilf. Eine Wiese entsteht erst durch VIELE, KURZE,
## BREITE Halme, die sich überlagern. Deshalb sorgt `mindestdichte` dafür,
## dass ein Feld nie zu dünn besetzt ist, egal wie klein `anzahl` gesetzt
## wurde; `hoechstzahl` deckelt die Kosten nach oben.
##
## Keine Kollision: man läuft einfach durch das Gras hindurch.

## Größe des Feldes in Metern (X mal Z), zentriert um den Knoten.
@export var flaeche: Vector2 = Vector2(6.0, 6.0)
## Gewünschte Anzahl der Büschel (wird durch `mindestdichte` angehoben).
@export_range(1, 800) var anzahl: int = 180
## Untergrenze der Besetzung in Büscheln je Quadratmeter.
@export_range(0.0, 30.0, 0.5) var mindestdichte: float = 13.0
## Obergrenze je Feld – schützt die Bildrate bei großen Flächen.
@export_range(1, 800) var hoechstzahl: int = 320
## Höhe eines Halms in Metern.
@export_range(0.1, 2.0, 0.01) var halm_hoehe: float = 0.32
## Halme je Büschel (im Kreis angeordnet).
@export_range(2, 12) var halme_je_buschel: int = 7
## Feste Saat: gleicher Wert ⇒ gleiches Feld. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Farbe am Halmfuß.
@export var farbe_unten: Color = Color(0.14, 0.31, 0.10)
## Farbe an der Halmspitze.
@export var farbe_oben: Color = Color(0.51, 0.72, 0.27)
## Windschwanken an/aus.
@export var wind: bool = true
## Ausschlag des Windes in Metern an der Halmspitze.
@export_range(0.0, 0.5, 0.01) var wind_staerke: float = 0.07
## Windgeschwindigkeit.
@export_range(0.1, 4.0, 0.05) var wind_tempo: float = 1.3

## Halbe Breite eines Halms am Fuß. Breiter als ein Schilfhalm, aber schmal
## genug, dass die Halme nicht wie Maisblätter einzeln zu lesen sind – die
## geschlossene Wiese entsteht über die MENGE, nicht über die Breite.
const HALM_BREITE := 0.021

## Vertex-Shader für den Wind. Bewusst schlicht gehalten:
## `gl_compatibility` (Web-Export) kann keine Screen-/Depth-Texturen und
## keine Compute-Shader – hier wird nur der Vertex verschoben.
##
## Die Phase enthält neben der Büschelposition auch die lokale Halmposition:
## dadurch wippen die Halme EINES Büschels leicht gegeneinander, statt sich
## wie ein starrer Block zu neigen.
const WIND_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled, shadows_disabled;

uniform vec4 farbe_unten : source_color = vec4(0.14, 0.31, 0.10, 1.0);
uniform vec4 farbe_oben : source_color = vec4(0.51, 0.72, 0.27, 1.0);
uniform float wind_staerke = 0.07;
uniform float wind_tempo = 1.3;

varying float hoehe;

void vertex() {
	hoehe = clamp(UV.y, 0.0, 1.0);
	vec3 wpos = MODEL_MATRIX[3].xyz;
	float phase = wpos.x * 0.8 + wpos.z * 1.1
			+ VERTEX.x * 5.0 + VERTEX.z * 3.5;
	float schwung = sin(TIME * wind_tempo + phase)
			+ 0.35 * sin(TIME * wind_tempo * 2.4 + phase * 1.7);
	// quadratisch nach oben gewichtet ⇒ der Fuß bleibt stehen
	float gewicht = hoehe * hoehe * wind_staerke;
	VERTEX.x += schwung * gewicht;
	VERTEX.z += schwung * gewicht * 0.55;
}

void fragment() {
	// COLOR = Scheitelfarbe (Halm) mal Instanzfarbe (Büschel)
	ALBEDO = mix(farbe_unten.rgb, farbe_oben.rgb, hoehe) * COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
"""

## Der Shader wird einmal für alle Grasfelder gebaut (nur eine Kompilierung).
static var _shader: Shader = null


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	var rng := PropWerkzeug.zufall(saat)
	_baue(rng)


func _baue(rng: RandomNumberGenerator) -> void:
	var buschel := _buschel_mesh(rng)
	if buschel == null:
		return

	var soll := maxi(anzahl, int(absf(flaeche.x * flaeche.y) * mindestdichte))
	soll = clampi(soll, 1, hoechstzahl)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = buschel
	mm.instance_count = soll

	var halb := flaeche * 0.5
	for i in soll:
		var pos := Vector3(rng.randf_range(-halb.x, halb.x), 0.0,
				rng.randf_range(-halb.y, halb.y))
		var skal := rng.randf_range(0.75, 1.3)
		var trafo := Transform3D(
			Basis.from_euler(Vector3(rng.randf_range(-0.1, 0.1),
					rng.randf() * TAU, rng.randf_range(-0.1, 0.1)))
					* Basis.from_scale(Vector3(skal, skal * rng.randf_range(0.72, 1.15), skal)),
			pos)
		mm.set_instance_transform(i, trafo)
		# Farbstreuung je Büschel: manche Horste gelblich, manche satt dunkel
		var ton := rng.randf_range(0.74, 1.12)
		mm.set_instance_color(i, Color(ton * rng.randf_range(0.96, 1.12),
				ton * rng.randf_range(0.94, 1.06), ton * rng.randf_range(0.82, 1.0)))

	multimesh = mm
	material_override = _material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Feste Hülle: der Wind verschiebt Vertices, sonst würde am Rand
	# fälschlich weggeschnitten.
	var rand := halb.abs() + Vector2(0.6, 0.6)
	custom_aabb = AABB(Vector3(-rand.x, -0.2, -rand.y),
			Vector3(rand.x * 2.0, halm_hoehe * 1.8 + 0.4, rand.y * 2.0))


func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = WIND_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("farbe_unten", farbe_unten)
	mat.set_shader_parameter("farbe_oben", farbe_oben)
	mat.set_shader_parameter("wind_staerke", wind_staerke if wind else 0.0)
	mat.set_shader_parameter("wind_tempo", wind_tempo)
	return mat


## Ein Büschel: mehrere Halme im Kreis, jeder aus einem Viereck und einer
## Spitze. 3 Dreiecke je Halm – ein Büschel kostet rund 21 Dreiecke.
func _buschel_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in halme_je_buschel:
		var winkel := TAU * float(i) / float(halme_je_buschel) + rng.randf_range(-0.45, 0.45)
		_halm(st, winkel, rng)
	var netz: ArrayMesh = st.commit()
	if netz == null or netz.get_surface_count() == 0:
		return null
	return netz


## Ein einzelner Halm: schmales Band am Fuß, das sich nach außen überbiegt,
## seitlich leicht ausschert und in einer Spitze ausläuft. 3 Dreiecke.
func _halm(st: SurfaceTool, winkel: float, rng: RandomNumberGenerator) -> void:
	var aussen := Vector3(cos(winkel), 0.0, sin(winkel))
	var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
	var h := halm_hoehe * rng.randf_range(0.5, 1.3)
	# kräftiger Überhang: der Halm legt sich, statt senkrecht zu stehen
	var neigung := h * rng.randf_range(0.5, 1.05)
	# seitliches Ausscheren – ohne das stehen alle Halme wie gezogen
	var schwung := quer * h * rng.randf_range(-0.35, 0.35)
	var fuss := aussen * rng.randf_range(0.0, 0.12) * h
	var breite := HALM_BREITE * rng.randf_range(0.75, 1.5)
	# Normale zwischen "nach außen" und "nach oben" – wirkt weicher beleuchtet
	var normale := (aussen * 0.4 + Vector3.UP * 0.9).normalized()
	# Halm-eigener Ton: ein Büschel ist nie einfarbig
	var ton := rng.randf_range(0.78, 1.16)
	var farbe := Color(ton, ton * rng.randf_range(0.95, 1.06), ton * rng.randf_range(0.85, 1.0))

	var stufen := 2
	for s in stufen:
		var t0 := float(s) / float(stufen)
		var t1 := float(s + 1) / float(stufen)
		var a := _halmpunkt(fuss, aussen, schwung, h, neigung, t0)
		var b := _halmpunkt(fuss, aussen, schwung, h, neigung, t1)
		var wa := breite * _breite(t0)
		var wb := breite * _breite(t1)
		if s == stufen - 1:
			# oberste Stufe läuft in einer Spitze aus: nur EIN Dreieck
			_dreieck(st, a - quer * wa, b, a + quer * wa, normale, farbe,
					Vector2(0.0, t0), Vector2(0.5, t1), Vector2(1.0, t0))
			continue
		_dreieck(st, a - quer * wa, b - quer * wb, b + quer * wb, normale, farbe,
				Vector2(0.0, t0), Vector2(0.0, t1), Vector2(1.0, t1))
		_dreieck(st, a - quer * wa, b + quer * wb, a + quer * wa, normale, farbe,
				Vector2(0.0, t0), Vector2(1.0, t1), Vector2(1.0, t0))


## Breitenverlauf: unten voll, oben schmal – aber nicht nadelfein.
func _breite(t: float) -> float:
	return 1.0 - 0.5 * t * t


func _halmpunkt(fuss: Vector3, aussen: Vector3, schwung: Vector3, h: float,
		neigung: float, t: float) -> Vector3:
	return fuss + Vector3.UP * (h * t) + aussen * (neigung * t * t) + schwung * t * t


func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normale: Vector3,
		farbe: Color, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	st.set_color(farbe)
	st.set_normal(normale)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_color(farbe)
	st.set_normal(normale)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_color(farbe)
	st.set_normal(normale)
	st.set_uv(uc)
	st.add_vertex(c)
