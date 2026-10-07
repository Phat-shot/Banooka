extends RefCounted
class_name GelaendeFeld
## Ein Höhenfeld ohne Kollision: Tal, Hänge, Hügel (Plan Level 01, 8.4).
##
## Allgemein gehalten – das Level gibt nur Funktionen und Linien vor:
##   `hoehe`     (x, z) -> Welt-Y
##   `abstand`   (x, z) -> gewünschter Punktabstand dort in Metern
##   `kanten`    Linien, an denen die Fläche knicken soll (Lippen, Wasser-
##               linien, Hangfüße): Dort liegen Punktreihen, die ein Raster
##               allein nie träfe. Eine Lippe aus zwei Reihen 0,3 m
##               auseinander ist eine scharfe Kante, kein Buckel über 2,5 m.
##   `faerben`   (Punkt, Normale) -> Color: Gewichte der vier Böden
##   `zusatz`    (Punkt, Normale, Mulde) -> Vector2: UV2 (Verdeckung, …)
##   `zusatz2`   (Punkt, Normale) -> Vector2: UV1, wenn gesetzt (Tönung, …)
##
## BAU. Die Punkte entstehen EINMAL für das ganze Feld: an den Grenzen
## der Stücke in fester Laufrichtung, im Inneren über einen Quadtree nach
## `abstand` (je Blatt ein Punkt, fest verwürfelt), dazu die Kanten. Jedes
## Stück wird für sich trianguliert (`Geometry2D.triangulate_delaunay`).
## Weil zwei Nachbarn dieselben Punkte auf ihrer gemeinsamen Grenze haben,
## schließen die Stücke lückenlos. Die Normalen werden über alle Stücke
## gemittelt – an einer Stückgrenze gibt es keinen Lichtsprung.
##
## Ein Stück ist ein Netz mit einer Fläche, also ein Zeichenaufruf; die
## Sichtprüfung lässt Stücke außerhalb des Bildes weg. Schatten wirft das
## Feld keine (es empfängt sie). `beigaben` (Felsen, Brocken) werden in das
## Stück gemischt, in dem sie stehen – sie kosten keinen eigenen Aufruf.
##
## `hoehe_bei()` liefert danach die GEZEICHNETE Höhe (Dreieck unter dem
## Punkt, linear), damit Bäume und Steine genau auf der Fläche stehen und
## nicht auf der Funktion, die zwischen zwei Punkten davon abweicht.
##
## Scheiteldaten: COLOR = Stoffgewichte, UV2 = `zusatz`, UV1 = `zusatz2`,
## NORMAL. Keine Tangenten: Der Stoff projiziert in Weltkoordinaten.

## Kleinster Abstand, den `abstand` liefern darf, und größte Zelle des
## Quadtrees.
const MIN_ABSTAND := 0.6
const MAX_ZELLE := 16.0
## Näher als das an einer Stückgrenze setzt der Quadtree keinen Punkt (in
## Teilen des Zellmaßes): Die Grenze hat eigene Punkte.
const GRENZ_ABSTAND := 0.45
## Kantenpunkte: näher als das an einer Stückgrenze fallen sie weg.
const KANTE_ZUR_GRENZE := 0.3
## Raster der Kantenpunkte (m) für die Nähesuche.
const KANTEN_ZELLE := 2.0

## Welt-XZ-Rechteck (position = x_min, z_min).
var bereich := Rect2()
## Stücke in x und z.
var stuecke := Vector2i(2, 4)
var hoehe: Callable
var abstand: Callable
## [{"punkte": PackedVector2Array (Welt-XZ), "abstand": float,
##   "reihen": PackedFloat32Array (Querversatz, links negativ)}]
var kanten: Array = []
var faerben: Callable
var zusatz: Callable
## (Punkt, Normale) -> Vector2: UV1 (frei, z. B. Tönung); leer = keine UV1
var zusatz2: Callable
## [{"netz": ArrayMesh, "lage": Transform3D, "farbe": Color, "zusatz": Vector2}]
var beigaben: Array = []
var stoff: Material = null

# Punkte des ganzen Feldes
var _px := PackedFloat32Array()
var _pz := PackedFloat32Array()
var _py := PackedFloat32Array()
var _hoehe_da := PackedByteArray()
var _normalen := PackedVector3Array()
# je Stück: globale Punktindizes und Dreiecke (globale Indizes, je drei)
var _stueck_punkte: Array[PackedInt32Array] = []
var _stueck_dreiecke: Array[PackedInt32Array] = []
var _fertig := false
# Suchgitter für `hoehe_bei`: je Zelle die Dreiecke (Index * 3 in _alle)
var _alle := PackedInt32Array()
var _gitter: Array[PackedInt32Array] = []
var _gitter_zelle := 4.0
var _gitter_n := Vector2i.ZERO


# ================================================================ Punkte

## Legt alle Punkte des Feldes an (ohne Höhen). Erster Bauschritt.
func punkte_setzen() -> void:
	_px.clear()
	_pz.clear()
	var n := stuecke.x * stuecke.y
	_stueck_punkte.clear()
	_stueck_dreiecke.clear()
	for i in n:
		_stueck_punkte.append(PackedInt32Array())
		_stueck_dreiecke.append(PackedInt32Array())
	var w := bereich.size.x / float(stuecke.x)
	var t := bereich.size.y / float(stuecke.y)
	# Ecken, je eine für alle Stücke daran
	var ecken := {}
	for i in stuecke.x + 1:
		for j in stuecke.y + 1:
			var p := Vector2(bereich.position.x + w * i, bereich.position.y + t * j)
			var k := _punkt(p)
			ecken[Vector2i(i, j)] = k
			_zu_stuecken(k, i - 1, i, j - 1, j)
	# Grenzlinien, je Abschnitt zwischen zwei Ecken
	for i in stuecke.x + 1:
		for j in stuecke.y:
			var a := Vector2(bereich.position.x + w * i, bereich.position.y + t * j)
			var b := Vector2(a.x, a.y + t)
			for k in _linie(a, b):
				_zu_stuecken(k, i - 1, i, j, j)
	for j in stuecke.y + 1:
		for i in stuecke.x:
			var a := Vector2(bereich.position.x + w * i, bereich.position.y + t * j)
			var b := Vector2(a.x + w, a.y)
			for k in _linie(a, b):
				_zu_stuecken(k, i, i, j - 1, j)
	# Kanten zuerst, damit der Quadtree ihnen ausweichen kann
	var kantenpunkte := {}
	for kante: Dictionary in kanten:
		_kante_setzen(kante, kantenpunkte, w, t)
	# Inneres
	for i in stuecke.x:
		for j in stuecke.y:
			var r := Rect2(bereich.position.x + w * i, bereich.position.y + t * j, w, t)
			_fuellen(r, i, j, kantenpunkte)
	_hoehe_da.resize(_px.size())
	_hoehe_da.fill(0)
	_py.resize(_px.size())


func _punkt(p: Vector2) -> int:
	_px.append(p.x)
	_pz.append(p.y)
	return _px.size() - 1


func _zu_stuecken(k: int, i0: int, i1: int, j0: int, j1: int) -> void:
	for i in [i0, i1]:
		for j in [j0, j1]:
			if i < 0 or j < 0 or i >= stuecke.x or j >= stuecke.y:
				continue
			var s := _stueck(i, j)
			if not _stueck_punkte[s].has(k):
				_stueck_punkte[s].append(k)


func _stueck(i: int, j: int) -> int:
	return j * stuecke.x + i


## Punkte auf einer Grenzlinie zwischen zwei Ecken, ohne die Ecken. Der
## Schritt folgt `abstand`; beide Nachbarn bekommen dieselben Punkte.
func _linie(a: Vector2, b: Vector2) -> PackedInt32Array:
	var ergebnis := PackedInt32Array()
	var laenge := a.distance_to(b)
	var richtung := (b - a) / laenge
	var t := 0.0
	var stellen := PackedFloat32Array()
	while true:
		var p := a + richtung * t
		var schritt := clampf(float(abstand.call(p.x, p.y)), MIN_ABSTAND, MAX_ZELLE)
		t += schritt
		if t >= laenge - schritt * 0.5:
			break
		stellen.append(t)
	# Gleichmäßig strecken, damit der letzte Abstand nicht winzig wird
	if not stellen.is_empty():
		var faktor := laenge / (stellen[stellen.size() - 1] + (laenge - stellen[stellen.size() - 1]))
		for s in stellen:
			ergebnis.append(_punkt(a + richtung * s * faktor))
	return ergebnis


func _kante_setzen(kante: Dictionary, kantenpunkte: Dictionary, w: float, t: float) -> void:
	var punkte: PackedVector2Array = kante["punkte"]
	var schritt: float = kante.get("abstand", 1.0)
	var reihen: PackedFloat32Array = kante.get("reihen", PackedFloat32Array([0.0]))
	if punkte.size() < 2:
		return
	var rest := 0.0
	for i in punkte.size() - 1:
		var a := punkte[i]
		var b := punkte[i + 1]
		var laenge := a.distance_to(b)
		if laenge < 0.0001:
			continue
		var d := (b - a) / laenge
		# links von der Laufrichtung (x rechts, z nach Süden): (d.y, -d.x)
		var links := Vector2(d.y, -d.x)
		var pos := rest
		while pos <= laenge:
			var m := a + d * pos
			for versatz in reihen:
				_kantenpunkt(m - links * versatz, kantenpunkte, w, t)
			pos += schritt
		rest = pos - laenge


func _kantenpunkt(p: Vector2, kantenpunkte: Dictionary, w: float, t: float) -> void:
	if not bereich.has_point(p):
		return
	var lx := (p.x - bereich.position.x) / w
	var lz := (p.y - bereich.position.y) / t
	var i := clampi(floori(lx), 0, stuecke.x - 1)
	var j := clampi(floori(lz), 0, stuecke.y - 1)
	# Nicht zu nah an eine Stückgrenze: Dort liegen deren eigene Punkte.
	var fx := (lx - float(i)) * w
	var fz := (lz - float(j)) * t
	if fx < KANTE_ZUR_GRENZE or fx > w - KANTE_ZUR_GRENZE \
			or fz < KANTE_ZUR_GRENZE or fz > t - KANTE_ZUR_GRENZE:
		return
	# Doppelte Kantenpunkte (zwei Linien kreuzen sich) auslassen
	if _nahe_kante(p, kantenpunkte, 0.18):
		return
	var zelle := Vector2i(floori(p.x / KANTEN_ZELLE), floori(p.y / KANTEN_ZELLE))
	var liste: PackedVector2Array = kantenpunkte.get(zelle, PackedVector2Array())
	liste.append(p)
	kantenpunkte[zelle] = liste
	var k := _punkt(p)
	_stueck_punkte[_stueck(i, j)].append(k)


## Quadtree über ein Stück: teilen, bis die Zelle zum Abstand passt; je
## Blatt ein Punkt in der Mitte, fest verwürfelt.
func _fuellen(r: Rect2, i: int, j: int, kantenpunkte: Dictionary) -> void:
	var s := _stueck(i, j)
	var anzahl_x := ceili(r.size.x / MAX_ZELLE)
	var anzahl_z := ceili(r.size.y / MAX_ZELLE)
	var zx := r.size.x / float(anzahl_x)
	var zz := r.size.y / float(anzahl_z)
	var stapel: Array[Rect2] = []
	for a in anzahl_x:
		for b in anzahl_z:
			stapel.append(Rect2(r.position.x + zx * a, r.position.y + zz * b, zx, zz))
	while not stapel.is_empty():
		var z: Rect2 = stapel.pop_back()
		var mitte := z.get_center()
		var ziel := clampf(float(abstand.call(mitte.x, mitte.y)), MIN_ABSTAND, MAX_ZELLE)
		var groesse := maxf(z.size.x, z.size.y)
		if groesse > ziel * 1.3 and groesse > MIN_ABSTAND * 2.0:
			var hx := z.size.x * 0.5
			var hz := z.size.y * 0.5
			stapel.append(Rect2(z.position.x, z.position.y, hx, hz))
			stapel.append(Rect2(z.position.x + hx, z.position.y, hx, hz))
			stapel.append(Rect2(z.position.x, z.position.y + hz, hx, hz))
			stapel.append(Rect2(z.position.x + hx, z.position.y + hz, hx, hz))
			continue
		var h1 := _zufall(mitte.x, mitte.y, 1.0)
		var h2 := _zufall(mitte.x, mitte.y, 2.0)
		var p := mitte + Vector2((h1 - 0.5) * z.size.x * 0.5, (h2 - 0.5) * z.size.y * 0.5)
		var rand := GRENZ_ABSTAND * groesse
		if p.x - r.position.x < rand or r.end.x - p.x < rand \
				or p.y - r.position.y < rand or r.end.y - p.y < rand:
			continue
		if _nahe_kante(p, kantenpunkte, groesse * 0.45):
			continue
		_stueck_punkte[s].append(_punkt(p))


## Liegt ein Kantenpunkt näher als `radius` an p? (Raster von
## `KANTEN_ZELLE` mit Listen.)
func _nahe_kante(p: Vector2, kantenpunkte: Dictionary, radius: float) -> bool:
	if kantenpunkte.is_empty():
		return false
	var x0 := floori((p.x - radius) / KANTEN_ZELLE)
	var x1 := floori((p.x + radius) / KANTEN_ZELLE)
	var z0 := floori((p.y - radius) / KANTEN_ZELLE)
	var z1 := floori((p.y + radius) / KANTEN_ZELLE)
	var r2 := radius * radius
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var zelle := Vector2i(gx, gz)
			if not kantenpunkte.has(zelle):
				continue
			var liste: PackedVector2Array = kantenpunkte[zelle]
			for q in liste:
				if q.distance_squared_to(p) < r2:
					return true
	return false


## Fester Zufall 0..1 je Ort.
static func _zufall(x: float, z: float, saat: float) -> float:
	var v := sin(x * 12.9898 + z * 78.233 + saat * 37.719) * 43758.5453
	return v - floorf(v)


# ================================================================ Stücke

## Anzahl der Stücke.
func anzahl() -> int:
	return stuecke.x * stuecke.y


## Höhen und Dreiecke eines Stücks. Ein Bauschritt je Stück.
func stueck_triangulieren(s: int) -> void:
	var indizes := _stueck_punkte[s]
	var flach := PackedVector2Array()
	flach.resize(indizes.size())
	for i in indizes.size():
		var k := indizes[i]
		flach[i] = Vector2(_px[k], _pz[k])
		if _hoehe_da[k] == 0:
			_py[k] = float(hoehe.call(_px[k], _pz[k]))
			_hoehe_da[k] = 1
	var dreiecke := Geometry2D.triangulate_delaunay(flach)
	var aus := PackedInt32Array()
	for i in range(0, dreiecke.size(), 3):
		var a := flach[dreiecke[i]]
		var b := flach[dreiecke[i + 1]]
		var c := flach[dreiecke[i + 2]]
		var flaeche := (b - a).cross(c - a)
		if absf(flaeche) < 0.0002:
			continue
		aus.append(indizes[dreiecke[i]])
		aus.append(indizes[dreiecke[i + 1]])
		aus.append(indizes[dreiecke[i + 2]])
	_stueck_dreiecke[s] = aus


## Normalen über alle Stücke (flächengewichtet), danach das Suchgitter.
func normalen_rechnen() -> void:
	var n := _px.size()
	_normalen.resize(n)
	_normalen.fill(Vector3.ZERO)
	_alle.clear()
	for s in _stueck_dreiecke.size():
		var d := _stueck_dreiecke[s]
		for i in range(0, d.size(), 3):
			var a := d[i]
			var b := d[i + 1]
			var c := d[i + 2]
			var pa := Vector3(_px[a], _py[a], _pz[a])
			var pb := Vector3(_px[b], _py[b], _pz[b])
			var pc := Vector3(_px[c], _py[c], _pz[c])
			var f := (pb - pa).cross(pc - pa)
			if f.y < 0.0:
				f = -f
			_normalen[a] += f
			_normalen[b] += f
			_normalen[c] += f
		_alle.append_array(d)
	for i in n:
		var v := _normalen[i]
		_normalen[i] = v.normalized() if v.length_squared() > 0.0 else Vector3.UP
	_gitter_bauen()
	_fertig = true


## Muldentiefe je Punkt (Mittel der Nachbarn minus eigene Höhe, >0 = Mulde),
## für die gebackene Verdeckung.
func _mulden() -> PackedFloat32Array:
	var summe := PackedFloat32Array()
	var zahl := PackedFloat32Array()
	summe.resize(_px.size())
	zahl.resize(_px.size())
	summe.fill(0.0)
	zahl.fill(0.0)
	for i in range(0, _alle.size(), 3):
		for k in 3:
			var a := _alle[i + k]
			for m in 3:
				if m == k:
					continue
				var b := _alle[i + m]
				summe[a] += _py[b]
				zahl[a] += 1.0
	var mulde := PackedFloat32Array()
	mulde.resize(_px.size())
	for i in _px.size():
		mulde[i] = summe[i] / zahl[i] - _py[i] if zahl[i] > 0.0 else 0.0
	return mulde


## Das Netz eines Stücks samt Beigaben. `mulden` aus `mulden_rechnen()`.
func stueck_netz(s: int, mulden: PackedFloat32Array) -> ArrayMesh:
	var indizes := _stueck_punkte[s]
	var lokal := {}
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var farben := PackedColorArray()
	var uv2 := PackedVector2Array()
	var uv1 := PackedVector2Array()
	var mit_uv1 := zusatz2.is_valid()
	for k in indizes:
		lokal[k] = ecken.size()
		var p := Vector3(_px[k], _py[k], _pz[k])
		var n := _normalen[k]
		ecken.append(p)
		normalen.append(n)
		farben.append(faerben.call(p, n) as Color)
		uv2.append(zusatz.call(p, n, mulden[k]) as Vector2)
		if mit_uv1:
			uv1.append(zusatz2.call(p, n) as Vector2)
	var liste := PackedInt32Array()
	var d := _stueck_dreiecke[s]
	for i in range(0, d.size(), 3):
		var a: int = lokal[d[i]]
		var b: int = lokal[d[i + 1]]
		var c: int = lokal[d[i + 2]]
		var pa := ecken[a]
		var pb := ecken[b]
		var pc := ecken[c]
		# Vorderseite im Uhrzeigersinn (wie `LevelWerkzeuge._dreieck`)
		if (pb - pa).cross(pc - pa).y > 0.0:
			liste.append_array(PackedInt32Array([a, c, b]))
		else:
			liste.append_array(PackedInt32Array([a, b, c]))
	var w := bereich.size.x / float(stuecke.x)
	var t := bereich.size.y / float(stuecke.y)
	var i_s := s % stuecke.x
	var j_s := s / stuecke.x
	var rahmen := Rect2(bereich.position.x + w * i_s, bereich.position.y + t * j_s, w, t)
	for beigabe: Dictionary in beigaben:
		var lage: Transform3D = beigabe["lage"]
		if not rahmen.has_point(Vector2(lage.origin.x, lage.origin.z)):
			continue
		_beigabe_anhaengen(beigabe, ecken, normalen, farben, uv2, liste)
		if mit_uv1:
			while uv1.size() < ecken.size():
				uv1.append(Vector2.ZERO)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = ecken
	arrays[Mesh.ARRAY_NORMAL] = normalen
	arrays[Mesh.ARRAY_COLOR] = farben
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	if mit_uv1:
		arrays[Mesh.ARRAY_TEX_UV] = uv1
	arrays[Mesh.ARRAY_INDEX] = liste
	var netz := ArrayMesh.new()
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return netz


func _beigabe_anhaengen(beigabe: Dictionary, ecken: PackedVector3Array,
		normalen: PackedVector3Array, farben: PackedColorArray, uv2: PackedVector2Array,
		liste: PackedInt32Array) -> void:
	var netz: ArrayMesh = beigabe["netz"]
	var lage: Transform3D = beigabe["lage"]
	var farbe: Color = beigabe.get("farbe", Color(0, 0, 1, 0))
	var extra: Vector2 = beigabe.get("zusatz", Vector2(1, 0))
	var basis_n := lage.basis.inverse().transposed()
	for f in netz.get_surface_count():
		var a := netz.surface_get_arrays(f)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null \
				else PackedInt32Array()
		var c: PackedColorArray = a[Mesh.ARRAY_COLOR] if a[Mesh.ARRAY_COLOR] != null \
				else PackedColorArray()
		var start := ecken.size()
		for i in v.size():
			ecken.append(lage * v[i])
			normalen.append((basis_n * n[i]).normalized())
			farben.append(farbe)
			# Verdeckung des Netzes (COLOR.r) mit der Vorgabe verrechnet
			var ao := c[i].r if not c.is_empty() else 1.0
			uv2.append(Vector2(extra.x * ao, extra.y))
		if idx.is_empty():
			for i in range(0, v.size(), 3):
				liste.append_array(PackedInt32Array([start + i, start + i + 1, start + i + 2]))
		else:
			for i in idx:
				liste.append(start + i)


## Muldentiefen aller Punkte (einmal vor den Netzen).
func mulden_rechnen() -> PackedFloat32Array:
	return _mulden()


## Setzt die Stücke als Knoten unter `eltern` (je Stück ein MeshInstance3D,
## ohne Schatten). Rückgabe: der Sammelknoten.
func knoten_bauen(eltern: Node3D, netze: Array[ArrayMesh], name_: String) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = name_
	eltern.add_child(wurzel)
	for s in netze.size():
		var mi := MeshInstance3D.new()
		mi.name = "Stueck%d" % s
		mi.mesh = netze[s]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if stoff != null:
			mi.material_override = stoff
		wurzel.add_child(mi)
	return wurzel


# ================================================================ Speicher

## Zustand nach dem Bau: alles, was `hoehe_bei()` und die Abfragen
## brauchen – für den Bauspeicher. Die Netze legt der Aufrufer dazu.
func zustand() -> Dictionary:
	return {"px": _px, "pz": _pz, "py": _py, "normalen": _normalen,
			"alle": _alle, "gitter": _gitter, "gitter_zelle": _gitter_zelle,
			"gitter_n": _gitter_n, "stueck_punkte": _stueck_punkte,
			"stueck_dreiecke": _stueck_dreiecke}


## Übernimmt einen mit `zustand()` gesicherten Bau; danach ist das Feld
## fertig, ohne gerechnet zu haben.
func zustand_setzen(d: Dictionary) -> void:
	_px = d["px"]
	_pz = d["pz"]
	_py = d["py"]
	_normalen = d["normalen"]
	_alle = d["alle"]
	_gitter.assign(d["gitter"])
	_gitter_zelle = float(d["gitter_zelle"])
	_gitter_n = d["gitter_n"]
	_stueck_punkte.assign(d["stueck_punkte"])
	_stueck_dreiecke.assign(d["stueck_dreiecke"])
	_hoehe_da.resize(_px.size())
	_hoehe_da.fill(1)
	_fertig = true


# ================================================================ Abfragen

## Ist das Feld gebaut (Dreiecke da)?
func fertig() -> bool:
	return _fertig


## Punkte und Dreiecke insgesamt (zum Messen).
func zaehlen() -> Vector2i:
	return Vector2i(_px.size(), _alle.size() / 3)


## Anzahl der Punkte und ein Punkt samt Höhe (für Proben der Nähte).
func punkt_anzahl() -> int:
	return _px.size()


func punkt(k: int) -> Vector3:
	return Vector3(_px[k], _py[k], _pz[k])


func _gitter_bauen() -> void:
	_gitter_n = Vector2i(ceili(bereich.size.x / _gitter_zelle), ceili(bereich.size.y / _gitter_zelle))
	_gitter.clear()
	_gitter.resize(_gitter_n.x * _gitter_n.y)
	for i in _gitter.size():
		_gitter[i] = PackedInt32Array()
	for i in range(0, _alle.size(), 3):
		var a := _alle[i]
		var b := _alle[i + 1]
		var c := _alle[i + 2]
		var x0 := minf(_px[a], minf(_px[b], _px[c]))
		var x1 := maxf(_px[a], maxf(_px[b], _px[c]))
		var z0 := minf(_pz[a], minf(_pz[b], _pz[c]))
		var z1 := maxf(_pz[a], maxf(_pz[b], _pz[c]))
		var gx0 := clampi(floori((x0 - bereich.position.x) / _gitter_zelle), 0, _gitter_n.x - 1)
		var gx1 := clampi(floori((x1 - bereich.position.x) / _gitter_zelle), 0, _gitter_n.x - 1)
		var gz0 := clampi(floori((z0 - bereich.position.y) / _gitter_zelle), 0, _gitter_n.y - 1)
		var gz1 := clampi(floori((z1 - bereich.position.y) / _gitter_zelle), 0, _gitter_n.y - 1)
		for gx in range(gx0, gx1 + 1):
			for gz in range(gz0, gz1 + 1):
				_gitter[gz * _gitter_n.x + gx].append(i)


## Gezeichnete Höhe an (x, z); außerhalb des Feldes oder vor dem Bau NAN.
func hoehe_bei(x: float, z: float) -> float:
	if not _fertig or not bereich.has_point(Vector2(x, z)):
		return NAN
	var gx := clampi(floori((x - bereich.position.x) / _gitter_zelle), 0, _gitter_n.x - 1)
	var gz := clampi(floori((z - bereich.position.y) / _gitter_zelle), 0, _gitter_n.y - 1)
	var p := Vector2(x, z)
	for i in _gitter[gz * _gitter_n.x + gx]:
		var a := _alle[i]
		var b := _alle[i + 1]
		var c := _alle[i + 2]
		var pa := Vector2(_px[a], _pz[a])
		var pb := Vector2(_px[b], _pz[b])
		var pc := Vector2(_px[c], _pz[c])
		var nenner := (pb - pa).cross(pc - pa)
		if absf(nenner) < 1e-9:
			continue
		var u := (p - pa).cross(pc - pa) / nenner
		var v := (pb - pa).cross(p - pa) / nenner
		if u >= -1e-4 and v >= -1e-4 and u + v <= 1.0001:
			return _py[a] + (_py[b] - _py[a]) * u + (_py[c] - _py[a]) * v
	return NAN


# ================================================================ Felsbrocken

## Ein kantiger Fels für Hügelkämme und Ferne (≈ 200 Dreiecke): der
## Schnitt von zwölf Halbräumen – steile Seitenflächen, ein paar schräge
## oben –, flach schattiert. So liest er sich auf 100 m als Klippe, nicht
## als Kiesel. `groesse` = volle Maße; Ursprung am Fuß, ein Viertel der
## Höhe steckt unter y 0. COLOR.r trägt die Verdeckung (unten dunkler).
static func felsbrocken(groesse: Vector3, saat: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = saat
	# Halbräume: Normale und Abstand (in Einheiten der halben Größe)
	var ebenen: Array[Vector4] = []
	for k in 8:
		var w := TAU * (float(k) + rng.randf_range(-0.3, 0.3)) / 8.0
		var n := Vector3(cos(w), rng.randf_range(-0.15, 0.35), sin(w)).normalized()
		ebenen.append(Vector4(n.x, n.y, n.z, rng.randf_range(0.8, 1.0)))
	for k in 4:
		var w := TAU * float(k) / 4.0 + rng.randf_range(0.0, 1.5)
		var n := Vector3(cos(w) * 0.8, 1.0, sin(w) * 0.8).normalized()
		ebenen.append(Vector4(n.x, n.y, n.z, rng.randf_range(0.75, 0.95)))
	ebenen.append(Vector4(0.0, 1.0, 0.0, rng.randf_range(0.85, 1.0)))
	var ringe := 8
	var seiten := 12
	var ecken: Array[Vector3] = []
	var halb := groesse * 0.5
	for r in ringe + 1:
		var breite := PI * (float(r) / float(ringe) - 0.5)
		for k in seiten:
			var w := TAU * float(k) / float(seiten)
			var dir := Vector3(cos(breite) * cos(w), sin(breite), cos(breite) * sin(w))
			var weite := 1.35
			for e in ebenen:
				var dn := dir.dot(Vector3(e.x, e.y, e.z))
				if dn > 0.05:
					weite = minf(weite, e.w / dn)
			var p := dir * weite
			if p.y < -0.5:
				p.y = -0.5
			ecken.append(Vector3(p.x * halb.x, (p.y + 0.5) * groesse.y * 0.75 - groesse.y * 0.25,
					p.z * halb.z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in ringe:
		for k in seiten:
			var a := ecken[r * seiten + k]
			var b := ecken[r * seiten + (k + 1) % seiten]
			var c := ecken[(r + 1) * seiten + k]
			var d := ecken[(r + 1) * seiten + (k + 1) % seiten]
			_fels_dreieck(st, a, c, b, groesse.y)
			_fels_dreieck(st, b, c, d, groesse.y)
	return st.commit()


## Ein flach schattiertes Dreieck des Felses, Vorderseite außen.
static func _fels_dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		hoehe_: float) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-10:
		return
	var mitte := (a + b + c) / 3.0
	var aussen := mitte - Vector3(0.0, hoehe_ * 0.25, 0.0)
	var reihe: Array[Vector3] = [a, b, c]
	# Vorderseite im Uhrzeigersinn von außen: Kreuzprodukt zeigt nach innen
	if n.dot(aussen) > 0.0:
		reihe = [a, c, b]
		n = -n
	n = -n.normalized()
	for p in reihe:
		var ao := clampf(0.5 + 0.5 * (p.y + hoehe_ * 0.25) / hoehe_, 0.4, 1.0)
		st.set_normal(n)
		st.set_color(Color(ao, ao, ao, 1.0))
		st.add_vertex(p)
