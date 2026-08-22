extends RefCounted
class_name Kistengeometrie
## Prozedurale Bauteile für Kisten – alles wird in `SurfaceTool` gesammelt
## und am Ende zu EINEM Mesh mit mehreren Flächen zusammengeführt.
##
## Warum: Eine Kiste aus 40 einzelnen `MeshInstance3D` kostet 40 Knoten und
## 40 Zeichenaufrufe. Level 01 hat 43 Kisten – das läppert sich. Hier
## entstehen stattdessen drei Materialgruppen (Holz, Metall, Akzent) in
## einem einzigen Mesh: 1 Knoten, 3 Zeichenaufrufe.
##
## Alle Bauteile nehmen einen `Transform3D` entgegen, damit dasselbe
## Symbol auf allen vier Seitenflächen sitzen kann.
##
## Wicklung: Godot zeichnet die Vorderseite, wenn die Punkte aus
## Blickrichtung im Uhrzeigersinn liegen (siehe ARCHITEKTUR.md) – die
## Hilfen hier drehen die Dreiecke von selbst passend zur Normalen.


# ------------------------------------------------------------- Grundkörper

## Quader mit angefasten Kanten (Fase = 0 ergibt einen scharfen Quader).
## `halb` sind die halben Kantenlängen, `mitte` der Mittelpunkt.
static func quader(st: SurfaceTool, mitte: Vector3, halb: Vector3,
		fase := 0.0, uv_skala := 1.0, tf := Transform3D.IDENTITY) -> void:
	var h := halb.abs()
	var f: float = minf(fase, minf(h.x, minf(h.y, h.z)) * 0.85)
	if f < 0.0005:
		f = 0.0

	# --- sechs Seitenflächen ---
	for achse in 3:
		var u := (achse + 1) % 3
		var w := (achse + 2) % 3
		for vz: float in [-1.0, 1.0]:
			var n := _achsvektor(achse, vz)
			var a := _punkt(achse, vz * h[achse], -(h[u] - f), -(h[w] - f))
			var b := _punkt(achse, vz * h[achse], h[u] - f, -(h[w] - f))
			var c := _punkt(achse, vz * h[achse], h[u] - f, h[w] - f)
			var d := _punkt(achse, vz * h[achse], -(h[u] - f), h[w] - f)
			viereck(st, mitte + a, mitte + b, mitte + c, mitte + d, n, uv_skala, tf)

	if f == 0.0:
		return

	# --- zwölf Fasen entlang der Kanten ---
	for achse in 3:
		var u := (achse + 1) % 3
		var w := (achse + 2) % 3
		for va: float in [-1.0, 1.0]:
			for vu: float in [-1.0, 1.0]:
				var n := (_achsvektor(achse, va) + _achsvektor(u, vu)).normalized()
				var a := _punkt(achse, va * h[achse], vu * (h[u] - f), -(h[w] - f))
				var b := _punkt(achse, va * h[achse], vu * (h[u] - f), h[w] - f)
				var c := _punkt(achse, va * (h[achse] - f), vu * h[u], h[w] - f)
				var d := _punkt(achse, va * (h[achse] - f), vu * h[u], -(h[w] - f))
				viereck(st, mitte + a, mitte + b, mitte + c, mitte + d, n, uv_skala, tf)

	# --- acht Ecken ---
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var n := Vector3(sx, sy, sz).normalized()
				var a := Vector3(sx * h.x, sy * (h.y - f), sz * (h.z - f))
				var b := Vector3(sx * (h.x - f), sy * h.y, sz * (h.z - f))
				var c := Vector3(sx * (h.x - f), sy * (h.y - f), sz * h.z)
				dreieck(st, mitte + a, mitte + b, mitte + c, n, uv_skala, tf)


## Zylinder entlang der Y-Achse (oben_radius 0 ergibt einen Kegel).
static func zylinder(st: SurfaceTool, mitte: Vector3, unten: float, oben: float,
		hoehe: float, segmente := 8, uv_skala := 1.0,
		tf := Transform3D.IDENTITY, deckel := true) -> void:
	var hy := hoehe * 0.5
	for i in segmente:
		var w0 := TAU * float(i) / float(segmente)
		var w1 := TAU * float(i + 1) / float(segmente)
		var r0 := Vector3(cos(w0), 0.0, sin(w0))
		var r1 := Vector3(cos(w1), 0.0, sin(w1))
		var a := mitte + r0 * unten + Vector3.DOWN * hy
		var b := mitte + r1 * unten + Vector3.DOWN * hy
		var c := mitte + r1 * oben + Vector3.UP * hy
		var d := mitte + r0 * oben + Vector3.UP * hy
		var n := ((r0 + r1) * 0.5).normalized()
		if oben < unten:
			n = (n + Vector3.UP * ((unten - oben) / maxf(hoehe, 0.001))).normalized()
		if oben <= 0.0005:
			dreieck(st, a, b, c, n, uv_skala, tf)
		else:
			viereck(st, a, b, c, d, n, uv_skala, tf)
		if not deckel:
			continue
		if oben > 0.0005:
			dreieck(st, mitte + Vector3.UP * hy, mitte + r0 * oben + Vector3.UP * hy,
					mitte + r1 * oben + Vector3.UP * hy, Vector3.UP, uv_skala, tf)
		if unten > 0.0005:
			dreieck(st, mitte + Vector3.DOWN * hy, mitte + r0 * unten + Vector3.DOWN * hy,
					mitte + r1 * unten + Vector3.DOWN * hy, Vector3.DOWN, uv_skala, tf)


## Flache Halbkugel (Niete, Fruchtrelief, Beule). Achse ist +Y.
static func kuppel(st: SurfaceTool, mitte: Vector3, radius: float, hoehe: float,
		segmente := 10, ringe := 3, uv_skala := 1.0,
		tf := Transform3D.IDENTITY) -> void:
	for r in ringe:
		var t0 := float(r) / float(ringe)
		var t1 := float(r + 1) / float(ringe)
		var w0 := t0 * PI * 0.5
		var w1 := t1 * PI * 0.5
		for i in segmente:
			var a0 := TAU * float(i) / float(segmente)
			var a1 := TAU * float(i + 1) / float(segmente)
			var p := func(w: float, a: float) -> Vector3:
				return mitte + Vector3(cos(w) * cos(a) * radius, sin(w) * hoehe,
						cos(w) * sin(a) * radius)
			var n := func(w: float, a: float) -> Vector3:
				return Vector3(cos(w) * cos(a) * hoehe, sin(w) * radius,
						cos(w) * sin(a) * hoehe).normalized()
			if r == ringe - 1:
				dreieck(st, p.call(w0, a0), p.call(w0, a1), mitte + Vector3.UP * hoehe,
						n.call((w0 + w1) * 0.5, (a0 + a1) * 0.5), uv_skala, tf)
			else:
				viereck(st, p.call(w0, a0), p.call(w0, a1), p.call(w1, a1),
						p.call(w1, a0), n.call((w0 + w1) * 0.5, (a0 + a1) * 0.5),
						uv_skala, tf)


## Quader, der in der XY-Ebene um `winkel` (Radiant) gedreht ist – für
## Pfeile, Kreuze und Schrägstreben auf einer Seitenfläche.
static func schraeg_quader(st: SurfaceTool, mitte: Vector3, halb: Vector3,
		winkel: float, fase := 0.0, uv_skala := 1.0,
		tf := Transform3D.IDENTITY) -> void:
	var dreh := Transform3D(Basis(Vector3.BACK, winkel), mitte)
	quader(st, Vector3.ZERO, halb, fase, uv_skala, tf * dreh)


# ------------------------------------------------------------- Mesh-Hilfen

## Viereck aus zwei Dreiecken; a–b–c–d laufen um die Fläche herum.
static func viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, normale: Vector3, uv_skala := 1.0,
		tf := Transform3D.IDENTITY) -> void:
	dreieck(st, a, b, c, normale, uv_skala, tf)
	dreieck(st, a, c, d, normale, uv_skala, tf)


## Einzelnes Dreieck mit fester Normalen und Weltprojektion als UV.
static func dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3, uv_skala := 1.0, tf := Transform3D.IDENTITY) -> void:
	var n := (tf.basis * normale).normalized()
	var pa := tf * a
	var pb := tf * b
	var pc := tf * c
	if (pb - pa).cross(pc - pa).dot(n) > 0.0:
		var tausch := pb
		pb = pc
		pc = tausch
	for p in [pa, pb, pc]:
		st.set_normal(n)
		st.set_uv(_uv(p, n, uv_skala))
		st.add_vertex(p)


## Planare Projektion auf die zur Normalen passende Ebene.
static func _uv(p: Vector3, n: Vector3, skala: float) -> Vector2:
	var ax := absf(n.x)
	var ay := absf(n.y)
	var az := absf(n.z)
	if ay >= ax and ay >= az:
		return Vector2(p.x, p.z) * skala
	if ax >= az:
		return Vector2(p.z, -p.y) * skala
	return Vector2(p.x, -p.y) * skala


static func _achsvektor(achse: int, vz: float) -> Vector3:
	var v := Vector3.ZERO
	v[achse] = vz
	return v


## Baut einen Vektor, dessen Komponente `achse` = a ist, die folgende = b
## und die übernächste = c.
static func _punkt(achse: int, a: float, b: float, c: float) -> Vector3:
	var v := Vector3.ZERO
	v[achse] = a
	v[(achse + 1) % 3] = b
	v[(achse + 2) % 3] = c
	return v
