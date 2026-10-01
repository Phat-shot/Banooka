extends RefCounted
class_name Farnwerk
## Farne als reine Geometrie – ohne Alpha, weil Handys im Browser ohne
## Kantenglättung zeichnen und ausgeschnittene Blattkarten dort flimmern.
##
## Verallgemeinert aus `Schluchtsaum._farn`/`_wedel`: Ein Farn ist ein
## Trichter aus gefiederten Wedeln. Jeder Wedel hat eine gebogene
## Mittelrippe; an ihr sitzen paarweise Fiedern, am Grund kurz, im unteren
## Drittel am längsten, zur Spitze hin auslaufend und nach vorn gestrichen.
## Die Fiedern sind entlang ihrer Mittelrippe leicht geknickt (sie fangen
## Licht von zwei Seiten), bei den großen gezähnt.
##
## Drei Fassungen, alle als Netz für MultiMesh (Fuß im Ursprung, +Y hinauf):
## * `klein()`  – 0,4–0,8 m, ≈ 250 Dreiecke: Farne im Rasen, in Rissen.
## * `gross()`  – 2–3,5 m, ≈ 1,1k: am Wandfuß, an Ufern, unter Riesen.
## * `rahmen()` – Rahmenfarn in den unteren Bildecken (6–10 m vor der
##   Kamera): weit ausladende, dunkle, gelappte Wedel, ≈ 1,5k.
## `netz(optionen)` baut jede Zwischenform.
##
## Scheiteldaten: COLOR.rgb Tönung (Grund dunkel, Spitzen hell), COLOR.a
## Windgewicht; UV.x Abstand von der Fiedermitte (0 Rippe, 1 Rand), UV.y
## entlang der Fieder. Der Stoff (`stoff()`) ist beidseitig, wiegt die Wedel
## im Vertexshader (kein Knoten bewegt sich) und dunkelt die Rückseite ab.
## Schatten: keine (Plan, Abschnitt 13).

## Tönungen der Wedel, relativ zur Stofffarbe.
const TOENE: Array[Color] = [
	Color(0.78, 0.9, 0.78),
	Color(0.9, 1.0, 0.86),
	Color(1.0, 1.0, 0.9),
	Color(1.05, 1.08, 0.86),
]
## Ein welker Wedel hier und da (nur bei den großen).
const WELK := Color(1.35, 1.05, 0.55)


## Kleiner Farn, 0,4–0,8 m.
static func klein(saat: int = 1) -> ArrayMesh:
	var rng := PropWerkzeug.zufall(saat)
	return netz({"saat": saat, "laenge": rng.randf_range(0.45, 0.75), "wedel": 7,
			"fiedern": 9, "zacken": 0, "breite": 0.3, "steil": Vector2(0.8, 1.25),
			"schwere": 0.24, "rippe": false})


## Großer Farn, 2–3,5 m.
static func gross(saat: int = 1) -> ArrayMesh:
	var rng := PropWerkzeug.zufall(saat)
	return netz({"saat": saat, "laenge": rng.randf_range(2.0, 3.0), "wedel": 9,
			"fiedern": 13, "zacken": 1, "breite": 0.28, "steil": Vector2(0.95, 1.3),
			"schwere": 0.3, "welk": 0.12})


## Rahmenfarn: breite, weit überhängende Wedel mit gezähnten Fiedern, dunkler
## als der Rest – er soll die Bildecke rahmen, nicht leuchten.
static func rahmen(saat: int = 1) -> ArrayMesh:
	var rng := PropWerkzeug.zufall(saat)
	return netz({"saat": saat, "laenge": rng.randf_range(2.2, 3.2), "wedel": 7,
			"fiedern": 12, "zacken": 2, "steil": Vector2(0.75, 1.15), "schwere": 0.36,
			"breite": 0.32, "ton": 0.72, "welk": 0.0})


## Freie Form. Optionen:
##   laenge   Wedellänge in m (0.6)
##   wedel    Anzahl der Wedel (7)
##   fiedern  Fiederpaare je Wedel (9)
##   zacken   0 glatte, 1 gezähnte, 2 tief gezähnte Fiedern
##   breite   Fiederlänge relativ zur Wedellänge (0.3)
##   steil    Vector2(min, max): Neigung der Wedel über der Waagerechten
##            in rad – die inneren steil, die äußeren flach
##   schwere  wie stark die Wedel zur Spitze hin überhängen (0.2)
##   ton      Helligkeit (1)
##   welk     Anteil welker Wedel (0)
##   rippe    Mittelrippe als eigener Streifen (true)
##   saat     feste Saat
static func netz(optionen: Dictionary = {}) -> ArrayMesh:
	return Bauspeicher.netz("farnwerk", [optionen],
			func() -> ArrayMesh: return _netz_bauen(optionen))


static func _netz_bauen(optionen: Dictionary = {}) -> ArrayMesh:
	var saat: int = optionen.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat + 7)
	var laenge: float = optionen.get("laenge", 0.6)
	var anzahl: int = optionen.get("wedel", 7)
	var fiedern: int = optionen.get("fiedern", 9)
	var zacken: int = optionen.get("zacken", 0)
	var breite: float = optionen.get("breite", 0.3)
	var steil: Vector2 = optionen.get("steil", Vector2(0.55, 1.05))
	var schwere: float = optionen.get("schwere", 0.2)
	var ton: float = optionen.get("ton", 1.0)
	var welk: float = optionen.get("welk", 0.0)
	var rippe: bool = optionen.get("rippe", true)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drehung := rng.randf() * TAU
	for i in anzahl:
		# Außen die alten, flachen Wedel, innen die jungen, steilen.
		var innen := float(i % 3 == 0)
		var winkel := drehung + TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(anzahl)
		var neigung := lerpf(steil.x, steil.y, innen * 0.7 + rng.randf() * 0.3)
		var flach := Vector3(cos(winkel), 0.0, -sin(winkel))
		var richtung := (flach * cos(neigung) + Vector3.UP * sin(neigung)).normalized()
		var l := laenge * rng.randf_range(0.78, 1.08) * lerpf(1.0, 0.82, innen)
		var farbe: Color = TOENE[rng.randi_range(0, TOENE.size() - 1)] * ton
		if innen > 0.5:
			farbe = farbe * Color(1.04, 1.06, 0.9)
		if rng.randf() < welk:
			farbe = WELK * ton
		_wedel(st, rng, Vector3.ZERO, richtung, l, fiedern, zacken, breite,
				schwere * rng.randf_range(0.8, 1.2) * lerpf(1.0, 0.6, innen), farbe, rippe)
	var ergebnis: ArrayMesh = st.commit()
	return ergebnis


## Ein Wedel. Die Mittelrippe biegt sich je Schritt um `schwere` nach unten
## und dreht leicht zur Seite; die Fiedern stehen nach vorn gestrichen ab.
static func _wedel(st: SurfaceTool, rng: RandomNumberGenerator, fuss: Vector3,
		richtung: Vector3, laenge: float, fiedern: int, zacken: int, breite: float,
		schwere: float, farbe: Color, rippe: bool) -> void:
	var schritte := fiedern + 2
	var schritt := laenge / float(schritte)
	var quer := richtung.cross(Vector3.UP)
	if quer.length_squared() < 0.001:
		quer = Vector3.RIGHT
	quer = quer.normalized()
	var drall := rng.randf_range(-0.06, 0.06)
	var pos := fuss
	var dir := richtung
	var punkte := PackedVector3Array([pos])
	var richtungen := PackedVector3Array([dir])
	for s in schritte:
		pos += dir * schritt
		dir = (dir + Vector3.DOWN * schwere * (6.0 / float(schritte)) + quer * drall).normalized()
		punkte.append(pos)
		richtungen.append(dir)

	# Mittelrippe als schmaler Streifen, oben dunkel-braungrün.
	if rippe:
		for s in schritte:
			var a := punkte[s]
			var b := punkte[s + 1]
			var t0 := float(s) / float(schritte)
			var t1 := float(s + 1) / float(schritte)
			var n := richtungen[s].cross(quer).normalized()
			if n.y < 0.0:
				n = -n
			var r0 := laenge * 0.012 * (1.0 - t0 * 0.7)
			var r1 := laenge * 0.012 * (1.0 - t1 * 0.7)
			var f0 := _farbe(farbe, t0, 0.55, 0.0)
			var f1 := _farbe(farbe, t1, 0.55, 0.0)
			_viereck(st, a - quer * r0, b - quer * r1, b + quer * r1, a + quer * r0, n,
					f0, f1, f1, f0, t0, t1)

	# Fiedern: paarweise ab dem zweiten Schritt.
	for s in range(1, schritte):
		var t := float(s) / float(schritte)
		var p := punkte[s]
		var d := richtungen[s]
		var q := d.cross(Vector3.UP)
		if q.length_squared() < 0.001:
			q = quer
		q = q.normalized()
		var ebene := q.cross(d).normalized()
		if ebene.y < 0.0:
			ebene = -ebene
		# Länge: am Grund kurz, im unteren Drittel am längsten, zur Spitze aus.
		var form := pow(sin(PI * clampf(0.1 + t * 1.02, 0.0, 1.0)), 0.7) * (1.0 - 0.25 * t)
		var fl := laenge * breite * form * rng.randf_range(0.9, 1.1)
		if fl < laenge * 0.03:
			continue
		for seite: float in [-1.0, 1.0]:
			var fr := (q * seite + d * 0.38 - ebene * 0.1).normalized()
			_fieder(st, p, fr, ebene, fl, zacken, farbe, t)


## Eine Fieder von `basis` in Richtung `richtung`: ein Fächer von der Basis
## über den Umriss bis zur Spitze, je Seite. Die Mittellinie (Basis–Spitze)
## liegt höher als die Ränder – die Fieder ist geknickt und fängt Licht von
## zwei Seiten. `zacken` 0: 2 Dreiecke, 1: 4, 2: 8.
static func _fieder(st: SurfaceTool, basis: Vector3, richtung: Vector3, ebene: Vector3,
		laenge: float, zacken: int, farbe: Color, t_wedel: float) -> void:
	var quer := ebene.cross(richtung).normalized()
	var b := laenge * 0.14
	var spitze := basis + richtung * laenge - ebene * laenge * 0.05
	# Umriss je Seite: (Anteil entlang, Breite) – Lappen und Kerben im Wechsel.
	var umriss: Array[Vector2] = []
	match zacken:
		0:
			umriss = [Vector2(0.4, 1.0)]
		1:
			umriss = [Vector2(0.3, 1.0), Vector2(0.62, 0.8)]
		_:
			umriss = [Vector2(0.2, 0.85), Vector2(0.33, 0.55), Vector2(0.5, 1.0),
					Vector2(0.66, 0.6)]
	var f_basis := _farbe(farbe, t_wedel, 0.62, 0.0)
	var f_spitze := _farbe(farbe, t_wedel, 1.0, 1.0)
	for seite: float in [-1.0, 1.0]:
		var vorher := Vector3.ZERO
		var vorher_f := f_basis
		var vorher_uv := Vector2.ZERO
		for k in umriss.size() + 1:
			var rand: Vector3
			var uv: Vector2
			if k == umriss.size():
				rand = spitze
				uv = Vector2(0.0, 1.0)
			else:
				var anteil := umriss[k].x
				var w := umriss[k].y
				rand = basis + richtung * laenge * anteil + quer * seite * b * w \
						- ebene * b * 0.4 * w
				uv = Vector2(w, anteil)
			var f_rand := f_basis.lerp(f_spitze, uv.y)
			if k > 0:
				var n := (vorher - basis).cross(rand - basis).normalized()
				if n.dot(ebene) < 0.0:
					n = -n
				n = (n + ebene * 1.5).normalized()
				_dreieck(st, basis, vorher, rand, n, f_basis, vorher_f, f_rand,
						Vector2.ZERO, vorher_uv, uv)
			vorher = rand
			vorher_f = f_rand
			vorher_uv = uv


## Farbe entlang Wedel (t) und Fieder (f), Alpha = Windgewicht.
static func _farbe(farbe: Color, t: float, f: float, spitze: float) -> Color:
	var hell := lerpf(0.42, 1.0, pow(t, 0.7)) * lerpf(0.78, 1.0, f)
	return Color(clampf(farbe.r * hell, 0.0, 1.0), clampf(farbe.g * hell, 0.0, 1.0),
			clampf(farbe.b * hell, 0.0, 1.0), clampf(t * 0.9 + spitze * 0.1, 0.0, 1.0))


static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3,
		fa: Color, fb: Color, fc: Color, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	# Vorderseite zu n: cross(b-a, c-a) muss entgegen n zeigen.
	if (b - a).cross(c - a).dot(n) > 0.0:
		_ecke(st, a, n, fa, ua)
		_ecke(st, c, n, fc, uc)
		_ecke(st, b, n, fb, ub)
	else:
		_ecke(st, a, n, fa, ua)
		_ecke(st, b, n, fb, ub)
		_ecke(st, c, n, fc, uc)


static func _viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3, fa: Color, fb: Color, fc: Color, fd: Color, t0: float, t1: float) -> void:
	_dreieck(st, a, b, c, n, fa, fb, fc, Vector2(0.0, t0), Vector2(0.0, t1), Vector2(0.0, t1))
	_dreieck(st, a, c, d, n, fa, fc, fd, Vector2(0.0, t0), Vector2(0.0, t1), Vector2(0.0, t0))


static func _ecke(st: SurfaceTool, p: Vector3, n: Vector3, f: Color, uv: Vector2) -> void:
	st.set_color(f)
	st.set_uv(uv)
	st.set_normal(n)
	st.add_vertex(p)


# ---------------------------------------------------------------- Stoff

static var _stoffe: Dictionary = {}
static var _shader: Shader = null

## Beidseitiger Farnstoff je Grundfarbe, geteilt – nie verändern.
static func stoff(farbe: Color = Farben.LAUB) -> ShaderMaterial:
	var schluessel := farbe.to_html()
	if _stoffe.has(schluessel):
		return _stoffe[schluessel]
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FARN_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("farbe", farbe)
	_stoffe[schluessel] = m
	return m


const FARN_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 farbe : source_color = vec4(0.22, 0.47, 0.16, 1.0);
uniform float wind = 1.0;
uniform float wind_weite = 0.045;

void vertex() {
	float phase = dot(MODEL_MATRIX[3].xyz, vec3(0.31, 0.0, 0.27));
	float w = wind * wind_weite * COLOR.a * COLOR.a;
	float laenge = length(VERTEX);
	VERTEX.x += sin(TIME * 1.35 + phase + laenge * 1.3) * w * (0.5 + laenge);
	VERTEX.z += cos(TIME * 1.05 + phase * 1.3 + laenge * 1.1) * w * 0.7 * (0.5 + laenge);
	VERTEX.y -= abs(sin(TIME * 0.8 + phase)) * w * 0.5 * laenge;
}

void fragment() {
	float rippe = 1.0 - 0.22 * (1.0 - smoothstep(0.0, 0.14, UV.x));
	float rueck = FRONT_FACING ? 1.0 : 0.78;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = farbe.rgb * COLOR.rgb * rippe * rueck;
	ROUGHNESS = 0.72;
	SPECULAR = 0.25;
}
"""
