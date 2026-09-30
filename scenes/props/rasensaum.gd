extends RefCounted
class_name Rasensaum
## Rasen, der aus dem Boden wächst (Plan Level 01, Abschnitt 8.2).
##
## Der Boden trägt schon eine Rasentextur (`wald_gemeinsam`); allein las sie
## sich aus der Spielkamera als Teppich auf Pappe. Hier stehen darauf
## BÜSCHEL aus gebogenen Halmen, je Stück und Art EIN MultiMesh – tausende
## Büschel in einer Handvoll Zeichenaufrufen, ohne Schatten, ohne Kollision.
##
## Drei Dinge lassen sie aus dem Boden wachsen, statt aufgeklebt zu wirken:
## * **Fuß = Boden.** Der Vertexshader holt an der Stelle des Büschels
##   dieselbe Rasenfarbe wie der Boden darunter (Rasentextur in einer
##   groben Mipstufe, Makro, trockene Stellen, Kronenlicht – dieselben
##   Funktionen aus `wald_gemeinsam`) und mischt sie nach der Wegmaske mit
##   der dunklen Erde der Trittkante. Der Fuß jedes Halms hat genau diese
##   Farbe, die Normale zeigt wie die des Bodens nach oben – so gibt es
##   keine Kante zwischen Halm und Boden.
## * **Spitzen heller und wärmer**, auf trockenen Stellen strohig, je Halm
##   und je Büschel leicht anders (±8 %).
## * **Wind** im Vertexshader, in Weltrichtung (kein Knoten bewegt sich).
##
## INSTANZFARBE (`MultiMesh.use_colors`, der Shader liest sie als Daten, die
## Scheitelfarbe der Netze ist weiß):
##   r  Verdeckung am Fuß (die des Bodens dort, 0,78 am Wegrand)
##   g  Rasenanteil am Fuß (Wegmaske m: 0 Erde der Trittkante, 1 Rasen)
##   b  Tönung, 0,5 neutral (±8 % Helligkeit, leicht in Richtung Gelb)
##   a  Stärke des Kronenlichts dort (0 = kein Blätterdach)
##
## AUSBLENDEN (Plan 8.2): Fade-Modi sind in gl_compatibility nicht
## verlässlich. Die Halme schrumpfen deshalb im Vertexshader zwischen
## `SCHRUMPF.x` und `SCHRUMPF.y` Metern Kameraabstand auf ihren Fuß, dazu
## hart `visibility_range_end` je Stück.
##
## NETZE (Fuß im Ursprung, +Y hinauf, Bezugshöhe `BEZUG`):
##   `bueschel()`  8 Halme, je drei Dreiecke (24 Dreiecke); die Instanz
##                 skaliert auf 0,14–0,6 m und kippt ihn an der Trittkante.
##   `wispel()`    6 lange Halme, die nach +X über eine Kante hängen
##                 (0,5–0,8 m, 42 Dreiecke): Wispelgras an Lippen.
## Scheiteldaten: UV = (quer −1..1, t entlang des Halms 0..1), UV2.x =
## Tönung des Halms, NORMAL fast senkrecht (wie der Boden).
##
## Aufruf:
##     var mm := Rasensaum.feld(eltern, "Gras 3", Rasensaum.bueschel(7),
##             lagen, farben, 42.0)
## `lagen` sind Welttransformationen (Fuß, Kippung, Maß), `farben` die
## Instanzfarben (siehe oben). `stoff()` ist geteilt; wer ihn braucht, ruft
## ihn – die Uniforms des Includes setzt `Wegmaske.einrichten`.

## Bezugshöhe der Netze (m): Eine Instanz mit Maß 1 ist so hoch.
const BEZUG := 0.3
## Kameraabstand (m), ab dem die Halme schrumpfen, und wo sie weg sind.
const SCHRUMPF := Vector2(28.0, 40.0)
## Harte Sichtweite je Stück (m, zur Mitte des Stücks).
const SICHTWEITE := 42.0

static var _shader: Shader = null
static var _stoff: ShaderMaterial = null
static var _netze := {}


# ================================================================ Netze

## Ein Rasenfleck: `halme` kurze Halme (Vorgabe 20), über eine Scheibe
## von `radius` m verteilt, nicht aus einem Punkt – so schließt sich der
## Rasen, statt als Reihe einzelner Sterne zu stehen. Drei von vier Halmen
## sind ein einziges Dreieck (kurzes Gras biegt sich aus sechs Metern Höhe
## nicht sichtbar), jeder vierte hat zwei Abschnitte. Gut die Hälfte legt
## sich in eine gemeinsame Richtung (der Fleck ist gekämmt), der Rest
## kreuz und quer. Bezugshöhe `BEZUG`; rund 30 Dreiecke. Geteilt je Saat.
static func fleck(saat: int = 1, halme: int = 20, radius: float = 0.2) -> ArrayMesh:
	var schluessel := "f%d_%d_%.2f" % [saat, halme, radius]
	if _netze.has(schluessel):
		return _netze[schluessel]
	var rng := PropWerkzeug.zufall(saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kamm := rng.randf() * TAU
	for i in halme:
		var r := sqrt(rng.randf()) * radius
		var wf := rng.randf() * TAU
		var fuss := Vector3(cos(wf) * r, 0.0, sin(wf) * r)
		var winkel := kamm + rng.randf_range(-0.7, 0.7) if rng.randf() < 0.55 else rng.randf() * TAU
		var aussen := Vector3(cos(winkel), 0.0, sin(winkel))
		var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
		# Zur Mitte des Flecks etwas höher: Er wölbt sich wie ein Horst.
		var h := BEZUG * rng.randf_range(0.4, 1.0) * lerpf(1.1, 0.8, r / radius)
		var neigung := h * rng.randf_range(0.12, 0.6)
		var schwung := h * rng.randf_range(-0.2, 0.2)
		var breite := rng.randf_range(0.012, 0.02)
		var ton := rng.randf_range(0.8, 1.16)
		_halm(st, fuss, aussen, quer, h, neigung, schwung, breite, ton, 2 if i % 4 == 0 else 1)
	var netz := st.commit()
	_netze[schluessel] = netz
	return netz


## Ein Büschel aus `halme` Halmen (Vorgabe 9), die aus einem Horst von gut
## 8 cm wachsen: für hohes Gras an Kanten und Steinen und für die innere
## Reihe an der Trittkante. Innen stehen die Halme steiler und höher,
## außen legen sie sich über, alle leicht in eine Richtung gekämmt (ein
## gleichmäßiger Stern las sich als Stachelkugel). Geteilt je Saat.
static func bueschel(saat: int = 1, halme: int = 9) -> ArrayMesh:
	var schluessel := "b%d_%d" % [saat, halme]
	if _netze.has(schluessel):
		return _netze[schluessel]
	var rng := PropWerkzeug.zufall(saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kamm := rng.randf() * TAU
	for i in halme:
		var innen := i * 3 < halme
		var winkel := kamm + rng.randf_range(-1.6, 1.6) if rng.randf() < 0.6 else rng.randf() * TAU
		var aussen := Vector3(cos(winkel), 0.0, sin(winkel))
		var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
		var h := BEZUG * (rng.randf_range(0.85, 1.2) if innen else rng.randf_range(0.5, 1.0))
		# Überhang: Innen steht der Halm, außen legt er sich – ein Halm, der
		# senkrecht steht, liest sich als Stachel.
		var neigung := h * (rng.randf_range(0.15, 0.4) if innen else rng.randf_range(0.4, 0.85))
		var schwung := h * rng.randf_range(-0.3, 0.3)
		var fuss := Vector3(rng.randf_range(-0.04, 0.04), 0.0, rng.randf_range(-0.04, 0.04))
		var breite := rng.randf_range(0.011, 0.018)
		var ton := rng.randf_range(0.82, 1.14)
		_halm(st, fuss, aussen, quer, h, neigung, schwung, breite, ton, 2)
	var netz := st.commit()
	_netze[schluessel] = netz
	return netz


## Wispelgras: `halme` lange, dünne Halme (Vorgabe 8), die kurz steigen und
## dann nach +X über eine Kante hängen. Länge etwa 0,55–0,8 m, am Ende gut
## 0,35 m unter dem Fuß. Geteilt je Saat – nie verändern.
static func wispel(saat: int = 1, halme: int = 8) -> ArrayMesh:
	var schluessel := "w%d_%d" % [saat, halme]
	if _netze.has(schluessel):
		return _netze[schluessel]
	var rng := PropWerkzeug.zufall(saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in halme:
		var winkel := lerpf(-0.8, 0.8, (float(i) + rng.randf()) / float(halme))
		var aussen := Vector3(cos(winkel), 0.0, sin(winkel))
		var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
		var laenge := rng.randf_range(0.55, 0.8)
		var steigen := rng.randf_range(0.18, 0.32)
		var haengen := rng.randf_range(0.55, 0.95)
		var fuss := aussen * rng.randf_range(-0.05, 0.03) + quer * rng.randf_range(-0.04, 0.04)
		var breite := rng.randf_range(0.013, 0.02)
		var ton := rng.randf_range(0.85, 1.2)
		var punkte := PackedVector3Array()
		const STUFEN := 4
		for k in STUFEN + 1:
			var t := float(k) / float(STUFEN)
			# steigt, biegt über und hängt: eine Parabel über die Kante
			punkte.append(fuss + aussen * laenge * t * 0.92
					+ Vector3.UP * laenge * (steigen * t - haengen * t * t)
					+ quer * laenge * 0.12 * t * t * signf(winkel))
		_band(st, punkte, quer, breite, ton, aussen)
	var netz := st.commit()
	_netze[schluessel] = netz
	return netz


## Ein Halm aus `stufen` Abschnitten (der letzte läuft spitz aus).
static func _halm(st: SurfaceTool, fuss: Vector3, aussen: Vector3, quer: Vector3, h: float,
		neigung: float, schwung: float, breite: float, ton: float, stufen: int) -> void:
	var punkte := PackedVector3Array()
	for k in stufen + 1:
		var t := float(k) / float(stufen)
		# Wer sich neigt, wird niedriger: Die Länge des Halms bleibt ungefähr.
		var hoch := h * t * (1.0 - 0.35 * (neigung / h) * t)
		punkte.append(fuss + Vector3.UP * hoch + aussen * neigung * t * t
				+ quer * schwung * t * t)
	_band(st, punkte, quer, breite, ton, aussen)


## Ein Band entlang `punkte`, zur Spitze hin schmal; der letzte Abschnitt
## ist ein Dreieck. Normale fast senkrecht, leicht nach `aussen` – so
## beleuchtet wie der Boden, aus dem der Halm wächst.
static func _band(st: SurfaceTool, punkte: PackedVector3Array, quer: Vector3, breite: float,
		ton: float, aussen: Vector3) -> void:
	var n := punkte.size() - 1
	var normale := (Vector3.UP * 0.92 + aussen * 0.3).normalized()
	for k in n:
		var t0 := float(k) / float(n)
		var t1 := float(k + 1) / float(n)
		var w0 := breite * (1.0 - 0.55 * t0 * t0)
		var w1 := breite * (1.0 - 0.55 * t1 * t1)
		var a := punkte[k]
		var b := punkte[k + 1]
		if k == n - 1:
			_ecke(st, a - quer * w0, normale, Vector2(-1.0, t0), ton)
			_ecke(st, b, normale, Vector2(0.0, t1), ton)
			_ecke(st, a + quer * w0, normale, Vector2(1.0, t0), ton)
			continue
		_ecke(st, a - quer * w0, normale, Vector2(-1.0, t0), ton)
		_ecke(st, b - quer * w1, normale, Vector2(-1.0, t1), ton)
		_ecke(st, b + quer * w1, normale, Vector2(1.0, t1), ton)
		_ecke(st, a - quer * w0, normale, Vector2(-1.0, t0), ton)
		_ecke(st, b + quer * w1, normale, Vector2(1.0, t1), ton)
		_ecke(st, a + quer * w0, normale, Vector2(1.0, t0), ton)


static func _ecke(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2, ton: float) -> void:
	st.set_color(Color.WHITE)
	st.set_normal(n)
	st.set_uv(uv)
	st.set_uv2(Vector2(ton, 0.0))
	st.add_vertex(p)


# ================================================================ Feld

## Ein MultiMesh aus `netz` mit einer Instanz je Eintrag in `lagen`
## (Welttransformationen) und `farben` (Instanzfarben, siehe Kopf). Der
## Knoten steht in der Mitte der Füße (für die Sichtweite), ohne Schatten.
## Leer: null.
static func feld(eltern: Node3D, name: String, netz: Mesh, lagen: Array[Transform3D],
		farben: PackedColorArray, sichtweite: float = SICHTWEITE) -> MultiMeshInstance3D:
	var n := lagen.size()
	if n == 0 or netz == null:
		return null
	var mitte := Vector3.ZERO
	for l in lagen:
		mitte += l.origin
	mitte /= float(n)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = netz
	mm.instance_count = n
	for i in n:
		var l := lagen[i]
		mm.set_instance_transform(i, Transform3D(l.basis, l.origin - mitte))
		mm.set_instance_color(i, farben[i] if i < farben.size() else Color(1.0, 1.0, 0.5, 0.0))
	var mi := MultiMeshInstance3D.new()
	mi.name = name
	mi.multimesh = mm
	mi.position = mitte
	mi.material_override = stoff()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = sichtweite
	mi.visibility_range_end_margin = 2.0
	# Der Wind verschiebt Spitzen um wenige Zentimeter; ohne Rand schnitte
	# die Sichtprüfung am Rand der Hülle zu früh ab.
	mi.extra_cull_margin = 0.3
	eltern.add_child(mi)
	return mi


## Instanzfarbe aus den Daten (siehe Kopf).
static func farbe(verdeckung: float, rasenanteil: float, toenung: float,
		kronenlicht: float) -> Color:
	return Color(clampf(verdeckung, 0.0, 1.0), clampf(rasenanteil, 0.0, 1.0),
			clampf(toenung, 0.0, 1.0), clampf(kronenlicht, 0.0, 1.0))


# ================================================================ Stoff

## Der Halmstoff, geteilt – nie verändern. Braucht die Uniforms des Includes
## (`Wegmaske.einrichten`, hier schon erledigt).
static func stoff() -> ShaderMaterial:
	if _stoff != null:
		return _stoff
	if _shader == null:
		_shader = Shader.new()
		_shader.code = HALM_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	Wegmaske.einrichten(m)
	var erde := Wegmaske.ERDE_MITTEL
	m.set_shader_parameter("erde_farbe", Vector3(erde.r, erde.g, erde.b))
	m.set_shader_parameter("schrumpf", SCHRUMPF)
	_stoff = m
	return m


const HALM_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, world_vertex_coords;

#include "res://shaders/wald_gemeinsam.gdshaderinc"

// Erde der Spur (linear, `Wegmaske.ERDE_MITTEL`); an der Trittkante ×0,7.
uniform vec3 erde_farbe = vec3(0.306, 0.192, 0.097);
// Spitzen: heller und wärmer als der Boden, auf trockenen Stellen Stroh.
uniform vec3 spitze_ton = vec3(1.42, 1.38, 1.0);
uniform vec3 spitze_licht = vec3(0.01, 0.014, 0.001);
uniform vec3 stroh = vec3(0.26, 0.22, 0.085);
// Kameraabstand: Schrumpfen von x bis y (m).
uniform vec2 schrumpf = vec2(28.0, 40.0);
uniform float wind_staerke = 0.07;
uniform float wind_tempo = 1.25;
// Mipstufe der Rasentextur für die Fußfarbe: gut 7 cm gemittelt, so viel,
// wie ein Büschel bedeckt.
uniform float rasen_lod = 3.0;

varying vec3 v_fuss;
varying vec3 v_spitze;
varying vec3 v_n;
varying float v_t;

void vertex() {
	vec3 fuss = MODEL_MATRIX[3].xyz;
	float t = clamp(UV.y, 0.0, 1.0);
	float f = 1.0 - smoothstep(schrumpf.x, schrumpf.y, distance(fuss, CAMERA_POSITION_WORLD));
	vec3 rel = VERTEX - fuss;
	// Wind in Weltrichtung, nach oben quadratisch; die Halme eines Büschels
	// wippen leicht gegeneinander (Phase aus ihrer Lage).
	float phase = fuss.x * 0.63 + fuss.z * 0.91;
	float schwung = sin(TIME * wind_tempo + phase + rel.x * 3.0)
			+ 0.4 * sin(TIME * wind_tempo * 2.3 + phase * 1.7 + rel.z * 4.0);
	float laenge = length(rel);
	vec3 wind = vec3(0.85, -0.12, 0.5) * schwung * wind_staerke * t * t * (0.3 + laenge);
	v_n = normalize((VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Der Boden unter dieser Ecke, wie Wegdecke und Gelände ihn malen:
	// Rasentextur (gemittelt), Makro, trockene Stellen, Kronenlicht. Am Fuß
	// eines Halms ist das genau der Boden, aus dem er wächst.
	vec2 ort = VERTEX.xz;
	vec4 w = textureLod(wald_rauschen, ort * wald_kachel, 0.0);
	vec3 gras = textureLod(wald_rasen, ort * wald_rasen_kachel, rasen_lod).rgb;
	vec3 rasen = rasen_farbe_aus(gras, w);
	float ao = COLOR.r;
	float m = COLOR.g;
	float ton = 1.0 + (COLOR.b - 0.5) * 0.32;
	float kronen = COLOR.a;
	float licht = 0.5;
	if (kronen > 0.005) {
		float treibend = textureLod(wald_rauschen, kronen_uv(ort, TIME), 0.0).a;
		licht = smoothstep(0.55, 0.63, w.a * 0.5 + treibend * 0.5);
	}
	vec3 kf = kronen_faktor(licht, kronen, 1.0);
	vec3 boden = mix(erde_farbe * 0.7, rasen, smoothstep(0.2, 0.7, m));
	// Am Fuß eine Spur dunkler: Zwischen den Halmen liegt Schatten.
	v_fuss = boden * ao * kf * 0.9;
	vec3 spitze = rasen * spitze_ton + spitze_licht;
	spitze = mix(spitze, stroh, trocken_aus(w) * 0.6);
	spitze *= mix(ton, ton * UV2.x, 0.8);
	spitze *= vec3(1.0, 1.0, mix(1.0, 0.8, max(ton - 1.0, 0.0) * 4.0));
	v_spitze = spitze * mix(1.0, ao, 0.45) * kf;
	v_t = t;
	VERTEX = fuss + (rel + wind) * f;
}

void fragment() {
	// Fuß in Bodenfarbe, die untere Hälfte schnell heller, die Spitze warm.
	float t = smoothstep(0.0, 0.9, v_t);
	ALBEDO = mix(v_fuss, v_spitze, t);
	// Die Normale bleibt auf beiden Seiten die des Bodens (nicht gespiegelt).
	NORMAL = normalize(v_n);
	ROUGHNESS = 0.85;
	SPECULAR = 0.22;
}
"""
