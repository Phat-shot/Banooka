extends RefCounted
class_name Bodenstreu
## Die Streu auf dem Waldboden (Plan Level 01, Abschnitt 8.2): Klee,
## Blütengruppen, Kiesel, Pilze – dazu Großblattstauden und der Stoff für
## Farne, die als MultiMesh stehen. (Moospolster wachsen im Stoff des
## Rasens: `Rasensaum.polster`.)
##
## ZWEI WEGE, ein Stoff (`stoff()`, beidseitig, Wind im Vertexshader):
## * **Haufen** (verschmolzen): Kleinzeug in großer Zahl und vielen Formen –
##   Klee, Blüten, Kiesel, Pilze – wird je Stück in EIN Netz
##   geschrieben (`Haufen.teil()`), ein Zeichenaufruf für alles. Jede Ecke
##   trägt den Fuß ihres Teils (UV = Fuß x/z, UV2.x = Fuß y) und seine Art
##   (UV2.y): So schrumpft jedes Teil im Vertexshader auf seinen eigenen
##   Fuß, obwohl alle in einem Netz liegen.
## * **Feld** (MultiMesh, `feld()`): wenige große Formen, die sich
##   wiederholen dürfen – Farne (`Farnwerk`), Großblätter, Rahmenfarne. Der
##   Fuß ist der Ursprung der Instanz. Instanzfarbe × Scheitelfarbe = Albedo.
##
## SCHEITELDATEN: COLOR.rgb die fertige Albedo (linear), COLOR.a das
## Windgewicht (0 am Fuß, 1 an der Spitze; wie `Farnwerk`). Die Farne aus
## `Farnwerk` passen so ohne Umbau hinein: ihre Tönung mal Instanzfarbe.
##
## ARTEN (UV2.y im Haufen) und ihre Schrumpfstrecke (Kameraabstand in m):
##   0 KLEIN   Klee, Kiesel, Pilze           `schrumpf_klein`  (22–30)
##   1 LEUCHT  Hut eines Leuchtpilzes        wie KLEIN, leuchtet warm
##   2 BLUETE  Blüten und ihre Stängel       `schrumpf_bluete` (28–38,
##             im Web 14–20: `Effekte.reduziert`)
##   3 GROSS   alles im Feld                 `schrumpf_gross`  (30–40)
##
## Blüten ohne Orange (das ist die Farbe der Früchte): weiß, gelb, violett,
## blau, ein gedecktes Rosa. Sie sind größer als in der Natur – aus sechs
## bis zwanzig Metern wären echte Gänseblümchen ein Bildpunkt.
##
## Keine Schatten, keine Kollision, kein `_process`.

const KLEIN := 0.0
const LEUCHT := 1.0
const BLUETE := 2.0
const GROSS := 3.0

## Blütenfarben (linear): weiß, gelb, violett, blau, rosa.
const BLUETEN_FARBEN: Array[Color] = [
	Color(0.80, 0.80, 0.72),
	Color(0.86, 0.58, 0.05),
	Color(0.36, 0.13, 0.62),
	Color(0.20, 0.34, 0.86),
	Color(0.74, 0.30, 0.46),
]
## Blütenmitte (linear).
const MITTE_GELB := Color(0.95, 0.62, 0.06)
## Kleegrün (linear), etwas blauer und heller als der Rasen.
const KLEE := Color(0.05, 0.105, 0.035)
## Kiesel: heller Kalk bis graubraun (linear).
const KIESEL_HELL := Color(0.36, 0.34, 0.29)
const KIESEL_DUNKEL := Color(0.2, 0.19, 0.16)
## Pilze (linear).
const PILZ_HUT := Color(0.30, 0.15, 0.06)
const PILZ_STIEL := Color(0.62, 0.56, 0.44)
const PILZ_GLUT := Color(1.0, 0.56, 0.2)

static var _shader: Shader = null
static var _stoffe := {}


# ================================================================ Teile

## Ein Stück Geometrie im eigenen Raum (Fuß im Ursprung), das ein Haufen
## beliebig oft an beliebige Stellen schreiben kann.
class Teil:
	extends RefCounted
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var farben := PackedColorArray()
	var arten := PackedFloat32Array()

	## Ein Dreieck mit einer Normale; die Vorderseite zeigt zu `n` (Godot:
	## im Uhrzeigersinn von vorn).
	func dreieck(a: Vector3, b: Vector3, c: Vector3, n: Vector3, fa: Color, fb: Color,
			fc: Color, art: float) -> void:
		dreieck_n(a, b, c, n, n, n, fa, fb, fc, art)

	## Wie `dreieck`, mit einer Normale je Ecke; die Vorderseite zeigt zur
	## mittleren Normale.
	func dreieck_n(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			fa: Color, fb: Color, fc: Color, art: float) -> void:
		var kreuz := (b - a).cross(c - a)
		if kreuz.length_squared() < 1e-14:
			return
		if kreuz.dot(na + nb + nc) > 0.0:
			_ecke(a, na, fa, art)
			_ecke(c, nc, fc, art)
			_ecke(b, nb, fb, art)
		else:
			_ecke(a, na, fa, art)
			_ecke(b, nb, fb, art)
			_ecke(c, nc, fc, art)

	func viereck(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, fa: Color,
			fb: Color, fc: Color, fd: Color, art: float) -> void:
		dreieck(a, b, c, n, fa, fb, fc, art)
		dreieck(a, c, d, n, fa, fc, fd, art)

	func _ecke(p: Vector3, n: Vector3, f: Color, art: float) -> void:
		ecken.append(p)
		normalen.append(n.normalized())
		farben.append(f)
		arten.append(art)

	func dreiecke() -> int:
		return int(ecken.size() / 3.0)

	## Das Teil als eigenes Netz (für ein Feld).
	func netz() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = ecken
		arrays[Mesh.ARRAY_NORMAL] = normalen
		arrays[Mesh.ARRAY_COLOR] = farben
		var netz_ := ArrayMesh.new()
		if not ecken.is_empty():
			netz_.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return netz_


## Viele Teile, verschmolzen zu einem Netz um `ursprung` (Weltpunkt).
class Haufen:
	extends RefCounted
	var ursprung := Vector3.ZERO
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var farben := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()

	func _init(ursprung_: Vector3) -> void:
		ursprung = ursprung_

	## Schreibt `t` mit der Welttransformation `lage` (Fuß = `lage.origin`),
	## die Farben mal `ton`.
	func teil(t: Teil, lage: Transform3D, ton: Color = Color.WHITE) -> void:
		var lokal := Transform3D(lage.basis, lage.origin - ursprung)
		var fuss := lokal.origin
		var nb := lage.basis.inverse().transposed()
		var n := t.ecken.size()
		var start := ecken.size()
		ecken.resize(start + n)
		normalen.resize(start + n)
		farben.resize(start + n)
		uv.resize(start + n)
		uv2.resize(start + n)
		var fuss_uv := Vector2(fuss.x, fuss.z)
		for i in n:
			ecken[start + i] = lokal * t.ecken[i]
			normalen[start + i] = (nb * t.normalen[i]).normalized()
			var f := t.farben[i]
			farben[start + i] = Color(f.r * ton.r, f.g * ton.g, f.b * ton.b, f.a)
			uv[start + i] = fuss_uv
			uv2[start + i] = Vector2(fuss.y, t.arten[i])

	func leer() -> bool:
		return ecken.is_empty()

	func dreiecke() -> int:
		return int(ecken.size() / 3.0)

	func netz() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = ecken
		arrays[Mesh.ARRAY_NORMAL] = normalen
		arrays[Mesh.ARRAY_COLOR] = farben
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_TEX_UV2] = uv2
		var netz_ := ArrayMesh.new()
		if not ecken.is_empty():
			netz_.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return netz_

	## Hängt das Netz als Knoten an `eltern` (ohne Schatten), null wenn leer.
	func knoten(eltern: Node3D, name: String, sichtweite: float) -> MeshInstance3D:
		if leer():
			return null
		var mi := MeshInstance3D.new()
		mi.name = name
		mi.mesh = netz()
		mi.position = ursprung
		mi.material_override = Bodenstreu.stoff(false)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = sichtweite
		mi.visibility_range_end_margin = 2.0
		mi.extra_cull_margin = 0.3
		eltern.add_child(mi)
		return mi


# ================================================================ Formen

## Ein Kleefleck: 14–30 Kleeblätter (je drei herzförmige Blättchen) in
## einer Scheibe von `radius` m, 1–7 cm über dem Boden, dazu manchmal ein
## paar weiße Köpfchen. Rund 6 Dreiecke je Blatt.
static func klee(rng: RandomNumberGenerator, radius: float = 0.35, bluehen: bool = false) -> Teil:
	var t := Teil.new()
	var anzahl := int(clampf(radius * radius * 160.0, 10.0, 34.0))
	for i in anzahl:
		var w := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var mitte := Vector3(cos(w) * r, rng.randf_range(0.012, 0.07), sin(w) * r)
		# Innen dichter, höher und heller; am Rand flach.
		var rand := r / radius
		mitte.y *= lerpf(1.0, 0.45, rand)
		var groesse := rng.randf_range(0.022, 0.036) * lerpf(1.05, 0.8, rand)
		var ton := rng.randf_range(0.82, 1.18)
		var gruen := Color(KLEE.r * ton, KLEE.g * ton, KLEE.b * ton * rng.randf_range(0.9, 1.2), 0.3)
		var kippen := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
		var dreh := rng.randf() * TAU
		for k in 3:
			var wk := dreh + TAU * float(k) / 3.0
			var d := Vector3(cos(wk), 0.0, sin(wk))
			var q := Vector3(-sin(wk), 0.0, cos(wk))
			d = (d - kippen * d.dot(kippen)).normalized()
			q = (q - kippen * q.dot(kippen)).normalized()
			var fuss := mitte + d * 0.003
			var links := mitte + d * groesse * 0.55 + q * groesse * 0.5 + kippen * groesse * 0.1
			var kerbe := mitte + d * groesse * 0.92 + kippen * groesse * 0.05
			var rechts := mitte + d * groesse * 0.55 - q * groesse * 0.5 + kippen * groesse * 0.1
			var hell := gruen * 1.35
			hell.a = gruen.a
			t.dreieck(fuss, links, kerbe, kippen, hell, gruen, gruen, KLEIN)
			t.dreieck(fuss, kerbe, rechts, kippen, hell, gruen, gruen, KLEIN)
	if bluehen:
		for i in rng.randi_range(1, 3):
			var w := rng.randf() * TAU
			var r := sqrt(rng.randf()) * radius * 0.8
			var kopf := Vector3(cos(w) * r, rng.randf_range(0.09, 0.14), sin(w) * r)
			_stiel(t, Vector3(kopf.x, 0.0, kopf.z), kopf, 0.004)
			_kugelkopf(t, kopf, rng.randf_range(0.014, 0.02), Color(0.78, 0.76, 0.66), rng)
	return t


## Eine Blütengruppe von `farbe`-Blüten: `art` 0 Margerite (Strahlen um
## eine gelbe Mitte), 1 Butterblume (fünf runde, gewölbte Blätter), 2
## Glockenblume (nickende Glocken am gebogenen Stängel). 3–9 Köpfe in
## einer Scheibe von `radius` m, dazu ein paar Grundblätter.
static func blueten(rng: RandomNumberGenerator, art: int, farbe: Color,
		radius: float = 0.25) -> Teil:
	var t := Teil.new()
	var anzahl := rng.randi_range(4, 10)
	var gruen := Color(0.05, 0.1, 0.03, 0.0)
	for i in anzahl:
		var w := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var fuss := Vector3(cos(w) * r, 0.0, sin(w) * r)
		var hoehe := rng.randf_range(0.1, 0.24)
		var neig := Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
		var kopf := fuss + Vector3.UP * hoehe + neig * hoehe
		var ton := rng.randf_range(0.88, 1.1)
		var f := Color(farbe.r * ton, farbe.g * ton, farbe.b * ton, 1.0)
		match art:
			0:
				_stiel(t, fuss, kopf, 0.0045)
				var n := (Vector3.UP + neig * 1.5 + Vector3(rng.randf_range(-0.2, 0.2), 0.0,
						rng.randf_range(-0.2, 0.2))).normalized()
				_strahlenkopf(t, kopf, n, rng.randf_range(0.05, 0.07), f, rng)
			1:
				_stiel(t, fuss, kopf, 0.004)
				var n := (Vector3.UP + neig).normalized()
				_schalenkopf(t, kopf, n, rng.randf_range(0.042, 0.056), f, rng)
			_:
				# Glockenblume: der Stängel biegt sich, die Glocken nicken.
				var bogen := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
				var spitze := kopf + bogen * hoehe * 0.25 - Vector3.UP * hoehe * 0.05
				_stiel(t, fuss, kopf, 0.004)
				_stiel(t, kopf, spitze, 0.003)
				for k in rng.randi_range(1, 3):
					var an := kopf.lerp(spitze, rng.randf_range(0.2, 1.0))
					var haengen := (Vector3.DOWN * 0.8 + bogen * 0.5 + Vector3(
							rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))).normalized()
					_glocke(t, an, haengen, rng.randf_range(0.045, 0.062), f)
	# Grundblätter: schmale Bänder, die sich vom Fuß über den Boden legen.
	for i in rng.randi_range(2, 5):
		var w := rng.randf() * TAU
		var d := Vector3(cos(w), 0.0, sin(w))
		var q := Vector3(-sin(w), 0.0, cos(w))
		var fuss := Vector3(rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.5, 0.5)) * radius
		var lang := rng.randf_range(0.1, 0.18)
		var mitte := fuss + d * lang * 0.5 + Vector3.UP * lang * 0.28
		var spitze := fuss + d * lang + Vector3.UP * lang * 0.12
		var b := lang * 0.16
		var ton := rng.randf_range(0.8, 1.15)
		var g := Color(gruen.r * ton * 1.1, gruen.g * ton, gruen.b * ton, 0.2)
		var n := (Vector3.UP * 0.9 - d * 0.3).normalized()
		t.dreieck(fuss, mitte + q * b, spitze, n, g * 0.7, g, g, BLUETE)
		t.dreieck(fuss, spitze, mitte - q * b, n, g * 0.7, g, g, BLUETE)
	return t


## Ein Stängel als schmales Band (zwei Dreiecke), quer zum Blick nicht zu
## sehen – er soll den Kopf tragen, nicht auffallen.
static func _stiel(t: Teil, a: Vector3, b: Vector3, breite: float) -> void:
	var d := (b - a).normalized()
	var q := d.cross(Vector3.FORWARD)
	if q.length_squared() < 0.01:
		q = d.cross(Vector3.RIGHT)
	q = q.normalized() * breite
	var n := d.cross(q).normalized()
	var unten := Color(0.06, 0.11, 0.03, 0.0)
	var oben := Color(0.1, 0.19, 0.05, 1.0)
	t.viereck(a - q, b - q * 0.6, b + q * 0.6, a + q, n, unten, oben, oben, unten, BLUETE)


## Margerite: 9–12 Strahlen um eine gelbe, leicht erhabene Mitte.
static func _strahlenkopf(t: Teil, kopf: Vector3, n: Vector3, r: float, f: Color,
		rng: RandomNumberGenerator) -> void:
	var a := n.cross(Vector3.RIGHT)
	if a.length_squared() < 0.01:
		a = n.cross(Vector3.FORWARD)
	a = a.normalized()
	var b := n.cross(a).normalized()
	var strahlen := rng.randi_range(9, 12)
	var dreh := rng.randf() * TAU
	var innen := f * 0.82
	innen.a = 1.0
	for k in strahlen:
		var w := dreh + TAU * float(k) / float(strahlen)
		var d := a * cos(w) + b * sin(w)
		var q := a * cos(w + PI * 0.5) + b * sin(w + PI * 0.5)
		var breite := r * rng.randf_range(0.15, 0.22)
		var lang := r * rng.randf_range(0.85, 1.05)
		var fuss := kopf + d * r * 0.22
		var spitze := kopf + d * lang + n * r * rng.randf_range(-0.1, 0.12)
		var mitte := kopf + d * lang * 0.62 + n * r * 0.06
		t.dreieck(fuss, mitte + q * breite, spitze, n, innen, f, f, BLUETE)
		t.dreieck(fuss, spitze, mitte - q * breite, n, innen, f, f, BLUETE)
	_scheibe(t, kopf + n * r * 0.08, n, a, b, r * 0.3, MITTE_GELB, 6)


## Butterblume: fünf runde, zur Schale gewölbte Blätter, kleine Mitte.
static func _schalenkopf(t: Teil, kopf: Vector3, n: Vector3, r: float, f: Color,
		rng: RandomNumberGenerator) -> void:
	var a := n.cross(Vector3.RIGHT)
	if a.length_squared() < 0.01:
		a = n.cross(Vector3.FORWARD)
	a = a.normalized()
	var b := n.cross(a).normalized()
	var dreh := rng.randf() * TAU
	var innen := f * 0.7
	innen.a = 1.0
	for k in 5:
		var w := dreh + TAU * float(k) / 5.0
		var d := a * cos(w) + b * sin(w)
		var q := a * cos(w + PI * 0.5) + b * sin(w + PI * 0.5)
		var fuss := kopf + d * r * 0.12
		var mitte := kopf + d * r * 0.6 + n * r * 0.25
		var rand := kopf + d * r + n * r * 0.45
		var bl := r * 0.42
		t.dreieck(fuss, mitte + q * bl, rand, n, innen, f, f, BLUETE)
		t.dreieck(fuss, rand, mitte - q * bl, n, innen, f, f, BLUETE)
		t.dreieck(mitte + q * bl, rand + q * bl * 0.3, rand, n, f, f, f, BLUETE)
		t.dreieck(mitte - q * bl, rand, rand - q * bl * 0.3, n, f, f, f, BLUETE)
	_scheibe(t, kopf + n * r * 0.15, n, a, b, r * 0.22, Color(0.75, 0.62, 0.1), 5)


## Glocke: fünf Flanken von der Aufhängung bis zum offenen Rand.
static func _glocke(t: Teil, an: Vector3, achse: Vector3, lang: float, f: Color) -> void:
	var a := achse.cross(Vector3.UP)
	if a.length_squared() < 0.01:
		a = achse.cross(Vector3.RIGHT)
	a = a.normalized()
	var b := achse.cross(a).normalized()
	var dunkel := f * 0.55
	dunkel.a = 1.0
	const N := 5
	for k in N:
		var w0 := TAU * float(k) / float(N)
		var w1 := TAU * float(k + 1) / float(N)
		var d0 := a * cos(w0) + b * sin(w0)
		var d1 := a * cos(w1) + b * sin(w1)
		var o0 := an + achse * lang * 0.45 + d0 * lang * 0.28
		var o1 := an + achse * lang * 0.45 + d1 * lang * 0.28
		var r0 := an + achse * lang + d0 * lang * 0.48
		var r1 := an + achse * lang + d1 * lang * 0.48
		var nn := (d0 + d1).normalized()
		t.dreieck(an, o0, o1, nn, dunkel, f, f, BLUETE)
		t.viereck(o0, r0, r1, o1, nn, f, f * 1.1, f * 1.1, f, BLUETE)


## Ein rundes Köpfchen (Kleeblüte) aus acht Dreiecken.
static func _kugelkopf(t: Teil, mitte: Vector3, r: float, f: Color,
		rng: RandomNumberGenerator) -> void:
	var pole: Array[Vector3] = [mitte + Vector3.UP * r, mitte - Vector3.UP * r * 0.6]
	var dreh := rng.randf() * TAU
	for k in 4:
		var w0 := dreh + TAU * float(k) / 4.0
		var w1 := dreh + TAU * float(k + 1) / 4.0
		var p0 := mitte + Vector3(cos(w0), 0.0, sin(w0)) * r
		var p1 := mitte + Vector3(cos(w1), 0.0, sin(w1)) * r
		var nn := (p0 + p1) * 0.5 - mitte
		t.dreieck(pole[0], p0, p1, nn + Vector3.UP * r, f, f * 0.85, f * 0.85, BLUETE)
		t.dreieck(pole[1], p1, p0, nn - Vector3.UP * r, f * 0.6, f * 0.8, f * 0.8, BLUETE)


## Eine flache Scheibe (Blütenmitte) aus `n` Dreiecken.
static func _scheibe(t: Teil, mitte: Vector3, n: Vector3, a: Vector3, b: Vector3, r: float,
		f: Color, seiten: int) -> void:
	var ff := Color(f.r, f.g, f.b, 1.0)
	for k in seiten:
		var w0 := TAU * float(k) / float(seiten)
		var w1 := TAU * float(k + 1) / float(seiten)
		t.dreieck(mitte + n * r * 0.3, mitte + (a * cos(w0) + b * sin(w0)) * r,
				mitte + (a * cos(w1) + b * sin(w1)) * r, n, ff * 1.1, ff * 0.85, ff * 0.85, BLUETE)


## Ein bis vier Kiesel, halb im Boden: verbeulte, flache Zwanzigflächner,
## oben manchmal ein Hauch Moos. `groesse` = größter Durchmesser (m).
static func kiesel(rng: RandomNumberGenerator, groesse: float = 0.14, anzahl: int = 3) -> Teil:
	var t := Teil.new()
	var ikosa := _ikosaeder()
	var punkte: PackedVector3Array = ikosa[0]
	var flaechen: PackedInt32Array = ikosa[1]
	for i in anzahl:
		var d := groesse * (1.0 if i == 0 else rng.randf_range(0.35, 0.75))
		var mass := Vector3(d * 0.5 * rng.randf_range(0.85, 1.15), d * 0.5 * rng.randf_range(0.4, 0.62),
				d * 0.5 * rng.randf_range(0.6, 0.95))
		var ort := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-1.0, 1.0), 0.0,
				rng.randf_range(-1.0, 1.0)).normalized() * groesse * rng.randf_range(0.6, 1.1)
		ort.y = -mass.y * 0.35
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.15, 0.15))
		var grund := KIESEL_HELL.lerp(KIESEL_DUNKEL, rng.randf() * rng.randf())
		grund *= rng.randf_range(0.9, 1.08)
		var moos := rng.randf() < 0.45
		var ecken := PackedVector3Array()
		var normalen := PackedVector3Array()
		var farben := PackedColorArray()
		for p in punkte:
			var beule := rng.randf_range(0.82, 1.12)
			var q := Vector3(p.x * mass.x, p.y * mass.y, p.z * mass.z) * beule
			ecken.append(ort + basis * q)
			var nn := basis * Vector3(p.x / mass.x, p.y / mass.y, p.z / mass.z)
			normalen.append(nn.normalized())
			var c := grund * lerpf(0.62, 1.05, clampf(p.y * 0.5 + 0.55, 0.0, 1.0))
			if moos and p.y > 0.3:
				c = c.lerp(Color(0.06, 0.1, 0.03), clampf((p.y - 0.3) * 1.6, 0.0, 0.75))
			c.a = 0.0
			farben.append(c)
		for k in range(0, flaechen.size(), 3):
			var ia := flaechen[k]
			var ib := flaechen[k + 1]
			var ic := flaechen[k + 2]
			t.dreieck_n(ecken[ia], ecken[ib], ecken[ic], normalen[ia], normalen[ib], normalen[ic],
					farben[ia], farben[ib], farben[ic], KLEIN)
	return t


## Ein bis fünf Pilze, `hut` = Hutradius des größten (m). `leuchtend`:
## die Hüte glühen warm wie die Pilze an den Lückenlippen.
static func pilze(rng: RandomNumberGenerator, hut: float = 0.05, anzahl: int = 3,
		leuchtend: bool = false) -> Teil:
	var t := Teil.new()
	for i in anzahl:
		var r := hut * (1.0 if i == 0 else rng.randf_range(0.45, 0.85))
		var ort := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-1.0, 1.0), 0.0,
				rng.randf_range(-1.0, 1.0)).normalized() * hut * rng.randf_range(1.2, 2.6)
		var hoehe := r * rng.randf_range(1.1, 2.0)
		var achse := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
		var kopf := ort + achse * hoehe
		var ton := rng.randf_range(0.8, 1.2)
		var hutfarbe := (PILZ_GLUT if leuchtend else PILZ_HUT) * ton
		var stiel := PILZ_STIEL * rng.randf_range(0.85, 1.05)
		hutfarbe.a = 0.0
		stiel.a = 0.0
		var art_hut := LEUCHT if leuchtend else KLEIN
		var a := achse.cross(Vector3.RIGHT).normalized()
		var b := achse.cross(a).normalized()
		const N := 6
		var dreh := rng.randf() * TAU
		for k in N:
			var w0 := dreh + TAU * float(k) / float(N)
			var w1 := dreh + TAU * float(k + 1) / float(N)
			var d0 := a * cos(w0) + b * sin(w0)
			var d1 := a * cos(w1) + b * sin(w1)
			var nn := (d0 + d1).normalized()
			# Stiel (unten dunkler, im Boden)
			var s0 := ort + d0 * r * 0.24 - achse * 0.03
			var s1 := ort + d1 * r * 0.24 - achse * 0.03
			var o0 := kopf + d0 * r * 0.18
			var o1 := kopf + d1 * r * 0.18
			t.viereck(s0, o0, o1, s1, nn, stiel * 0.55, stiel, stiel, stiel * 0.55, KLEIN)
			# Hut: gewölbt, Rand leicht nach unten
			var rand0 := kopf + d0 * r - achse * r * 0.18
			var rand1 := kopf + d1 * r - achse * r * 0.18
			var schulter0 := kopf + d0 * r * 0.62 + achse * r * 0.3
			var schulter1 := kopf + d1 * r * 0.62 + achse * r * 0.3
			var kuppe := kopf + achse * r * 0.52
			var hell := hutfarbe * 1.15
			hell.a = 0.0
			t.dreieck(kuppe, schulter0, schulter1, achse + nn * 0.3, hell, hutfarbe, hutfarbe, art_hut)
			t.viereck(schulter0, rand0, rand1, schulter1, nn + achse * 0.4, hutfarbe,
					hutfarbe * 0.8, hutfarbe * 0.8, hutfarbe, art_hut)
			# Unterseite: Lamellen, blass (glühend: schwächer)
			var unten := (hutfarbe * 0.45) if leuchtend else Color(0.5, 0.42, 0.3, 0.0)
			t.dreieck(kopf - achse * r * 0.05, rand1, rand0, -achse, unten * 0.7, unten, unten, art_hut)
	return t


## Eine Großblattstaude: 2–4 große, herzförmige Blätter an langen Stielen,
## die sich nach außen legen (etwa `groesse` m hoch). Fuß im Ursprung, für
## ein Feld. Scheitelfarbe = Tönung (mal Instanzfarbe).
static func grossblatt(rng: RandomNumberGenerator, groesse: float = 1.0) -> Teil:
	var t := Teil.new()
	var dreh := rng.randf() * TAU
	var blaetter := rng.randi_range(3, 5)
	for i in blaetter:
		var w := dreh + TAU * (float(i) + rng.randf_range(-0.25, 0.25)) / float(blaetter)
		var flach := Vector3(cos(w), 0.0, sin(w))
		var quer := Vector3(-sin(w), 0.0, cos(w))
		var stiel_ende := flach * groesse * rng.randf_range(0.2, 0.4) \
				+ Vector3.UP * groesse * rng.randf_range(0.45, 0.8)
		var ton := rng.randf_range(0.85, 1.12)
		var stielfarbe := Color(0.55 * ton, 0.62 * ton, 0.42 * ton, 0.5)
		var nst := flach.cross(quer).normalized()
		t.viereck(-quer * 0.015, stiel_ende - quer * 0.012, stiel_ende + quer * 0.012,
				quer * 0.015, nst, stielfarbe * 0.7, stielfarbe, stielfarbe, stielfarbe * 0.7, GROSS)
		var lang := groesse * rng.randf_range(0.6, 0.85)
		var breit := lang * rng.randf_range(0.28, 0.36)
		var mitte := stiel_ende + flach * lang * 0.5 + Vector3.DOWN * lang * 0.1
		var spitze := stiel_ende + flach * lang + Vector3.DOWN * lang * 0.38
		var hinten := stiel_ende - flach * lang * 0.1 + Vector3.UP * lang * 0.05
		var dunkel := Color(0.62 * ton, 0.7 * ton, 0.55 * ton, 0.6)
		var blatt := Color(ton, ton * 1.02, ton * 0.9, 1.0)
		for seite: float in [-1.0, 1.0]:
			var rand := mitte + quer * breit * seite + Vector3.UP * breit * 0.25
			var n := (rand - stiel_ende).cross(spitze - stiel_ende).normalized()
			if n.y < 0.0:
				n = -n
			t.viereck(hinten, stiel_ende + quer * breit * 0.6 * seite, rand, mitte, n,
					dunkel, blatt, blatt, dunkel, GROSS)
			t.viereck(mitte, rand, spitze + quer * breit * 0.1 * seite, spitze, n,
					dunkel, blatt, blatt * 0.9, blatt * 0.85, GROSS)
	return t


## Zwanzigflächner: [Punkte (Einheitskugel), Flächen (Indizes)].
static func _ikosaeder() -> Array:
	var g := (1.0 + sqrt(5.0)) * 0.5
	var roh: Array[Vector3] = [Vector3(-1, g, 0), Vector3(1, g, 0), Vector3(-1, -g, 0),
		Vector3(1, -g, 0), Vector3(0, -1, g), Vector3(0, 1, g), Vector3(0, -1, -g),
		Vector3(0, 1, -g), Vector3(g, 0, -1), Vector3(g, 0, 1), Vector3(-g, 0, -1),
		Vector3(-g, 0, 1)]
	var punkte := PackedVector3Array()
	for p in roh:
		punkte.append(p.normalized())
	var flaechen := PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	return [punkte, flaechen]


# ================================================================ Feld

## Ein MultiMesh aus `netz` (Fuß im Ursprung) je Eintrag in `lagen`
## (Welttransformationen) mit Instanzfarben `farben` (mal Scheitelfarbe =
## Albedo). Ohne Schatten. Leer: null.
static func feld(eltern: Node3D, name: String, netz: Mesh, lagen: Array[Transform3D],
		farben: PackedColorArray, sichtweite: float, stoff_: Material = null) -> MultiMeshInstance3D:
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
		mm.set_instance_color(i, farben[i] if i < farben.size() else Color.WHITE)
	var mi := MultiMeshInstance3D.new()
	mi.name = name
	mi.multimesh = mm
	mi.position = mitte
	mi.material_override = stoff_ if stoff_ != null else stoff(true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = sichtweite
	mi.visibility_range_end_margin = 2.0
	mi.extra_cull_margin = 0.4
	eltern.add_child(mi)
	return mi


# ================================================================ Stoff

## Der Streustoff: `instanziert` für Felder (Fuß = Ursprung der Instanz),
## sonst für Haufen (Fuß aus UV/UV2). Geteilt – nie verändern.
static func stoff(instanziert: bool) -> ShaderMaterial:
	var schluessel := ("feld" if instanziert else "haufen") + ("_web" if Effekte.reduziert else "")
	if _stoffe.has(schluessel):
		return _stoffe[schluessel]
	if _shader == null:
		_shader = Shader.new()
		_shader.code = STREU_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("instanziert", instanziert)
	if Effekte.reduziert:
		m.set_shader_parameter("schrumpf_bluete", Vector2(14.0, 20.0))
	_stoffe[schluessel] = m
	return m


const STREU_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform bool instanziert = false;
// Kameraabstand (m): von x an schrumpft ein Teil auf seinen Fuß, bei y ist
// es weg – je Art (siehe `Bodenstreu`).
uniform vec2 schrumpf_klein = vec2(22.0, 30.0);
uniform vec2 schrumpf_bluete = vec2(28.0, 38.0);
uniform vec2 schrumpf_gross = vec2(30.0, 40.0);
uniform float wind_weite = 0.04;
uniform float leuchten = 1.1;

varying vec3 v_n;
varying float v_art;

void vertex() {
	vec3 fuss = vec3(0.0);
	float art = 3.0;
	if (!instanziert) {
		fuss = vec3(UV.x, UV2.x, UV.y);
		art = UV2.y;
	}
	vec3 fuss_welt = (MODEL_MATRIX * vec4(fuss, 1.0)).xyz;
	float d = distance(fuss_welt, CAMERA_POSITION_WORLD);
	vec2 sr = art > 2.5 ? schrumpf_gross : (art > 1.5 ? schrumpf_bluete : schrumpf_klein);
	float f = 1.0 - smoothstep(sr.x, sr.y, d);
	vec3 rel = VERTEX - fuss;
	float phase = dot(fuss_welt, vec3(0.31, 0.0, 0.27));
	float w = wind_weite * COLOR.a * COLOR.a;
	float l = length(rel);
	rel.x += sin(TIME * 1.35 + phase + l * 1.3) * w * (0.5 + l);
	rel.z += cos(TIME * 1.05 + phase * 1.3 + l * 1.1) * w * 0.7 * (0.5 + l);
	VERTEX = fuss + rel * f;
	v_n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_art = art;
}

void fragment() {
	NORMAL = normalize(v_n) * (FRONT_FACING ? 1.0 : -1.0);
	float leucht = step(0.5, v_art) * (1.0 - step(1.5, v_art));
	vec3 c = COLOR.rgb * (FRONT_FACING ? 1.0 : 0.8);
	// Leuchtende Hüte: wenig Albedo, das Licht kommt aus der Emission (wie
	// die Pilze an den Lückenlippen, `L01Boden`).
	ALBEDO = c * mix(1.0, 0.45, leucht);
	EMISSION = COLOR.rgb * vec3(1.0, 0.8, 0.6) * leuchten * leucht;
	ROUGHNESS = 0.78;
	SPECULAR = 0.25;
}
"""
