extends RefCounted
class_name PropWerkzeug
## Werkzeugkasten für die prozeduralen Wald-Props.
##
## Alle Props bauen ihre Optik aus Godot-Primitiven zusammen und
## verschmelzen sie mit `SurfaceTool` zu EINEM `ArrayMesh`. Das hält die
## Knotenzahl klein (wichtig für den Web-Export) und spart Draw-Calls.
##
## Es werden keine fremden Asset-Dateien benutzt – alles entsteht zur Laufzeit.


# ---------------------------------------------------------------- Zufall

## Liefert einen Zufallsgenerator mit fester Saat.
## Bei `saat == 0` wird eine zufällige Saat gezogen – dann sieht das Prop
## bei jedem Start anders aus. Wer Wiederholbarkeit will, setzt `saat`.
static func zufall(saat: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if saat == 0:
		rng.randomize()
	else:
		rng.seed = saat
	return rng


## Zieht eine gültige Saat für ein Kind-Prop (nie 0, damit sie fest bleibt).
static func kindsaat(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 2_000_000_000)


# ---------------------------------------------------------------- Mesh-Bau

## Startet einen Mesh-Sammler.
static func bauer() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Hängt ein Primitiv-Mesh transformiert an den Sammler an.
static func anfuegen(st: SurfaceTool, form: Mesh, ort_: Transform3D) -> void:
	if st == null or form == null:
		return
	st.append_from(form, 0, ort_)


## Schließt den Sammler ab. Gibt `null` zurück, wenn nichts gesammelt wurde.
static func fertig(st: SurfaceTool) -> ArrayMesh:
	if st == null:
		return null
	var netz: ArrayMesh = st.commit()
	if netz == null or netz.get_surface_count() == 0:
		return null
	return netz


## Erzeugt einen fertigen MeshInstance3D. Gibt `null` zurück, wenn kein Mesh da ist.
static func mesh_knoten(bezeichnung: String, netz: Mesh, material: Material,
		schatten: bool = true) -> MeshInstance3D:
	if netz == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	if material != null:
		mi.material_override = material
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ---------------------------------------------------------------- Knoten

## Holt einen benannten Kindknoten – und legt ihn an, falls er fehlt.
##
## Damit funktioniert jedes Prop auf beide Arten: als Instanz der .tscn
## (dann sind die Knoten schon da) UND über `Klasse.new()` direkt im
## Level-Skript (dann baut sich das Prop sein Gerüst selbst).
static func kind(elternteil: Node, bezeichnung: String, erzeuger: Callable) -> Node:
	var vorhanden := elternteil.get_node_or_null(NodePath(bezeichnung))
	if vorhanden != null:
		return vorhanden
	var neu: Node = erzeuger.call()
	neu.name = bezeichnung
	elternteil.add_child(neu)
	return neu


# ---------------------------------------------------------------- Primitive

## Kegelstumpf entlang der Y-Achse. Ohne Deckel spart das Dreiecke –
## die offenen Enden stecken bei uns immer in anderer Geometrie.
static func stumpf(radius_unten: float, radius_oben: float, hoehe: float,
		seiten: int = 8, deckel: bool = false) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = maxf(radius_unten, 0.001)
	m.top_radius = maxf(radius_oben, 0.0)
	m.height = maxf(hoehe, 0.001)
	m.radial_segments = maxi(seiten, 3)
	m.rings = 0
	m.cap_top = deckel and radius_oben > 0.0
	m.cap_bottom = deckel
	return m


## Kugel mit wenig Segmenten – bewusst kantig, das passt zum PS1-Look.
static func kugel(radius: float, seiten: int = 8, ringe: int = 5) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = maxf(radius, 0.001)
	m.height = m.radius * 2.0
	m.radial_segments = maxi(seiten, 4)
	m.rings = maxi(ringe, 2)
	return m


static func kasten(groesse: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	var g := groesse.abs()
	m.size = Vector3(maxf(g.x, 0.001), maxf(g.y, 0.001), maxf(g.z, 0.001))
	return m


## Fügt ein Viereck als zwei Dreiecke direkt ein – die billigste Art, ein
## Blatt zu bauen (2 Dreiecke statt 12 wie bei einer Box).
##
## ACHTUNG: In EINEM Sammler nicht mit `anfuegen()` mischen – die Primitive
## bringen Tangenten mit, diese Vierecke nicht. Für Blattwerk daher immer
## einen eigenen Sammler benutzen.
static func viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normale: Vector3 = Vector3.ZERO) -> void:
	var n := normale
	if n.length_squared() < 0.000001:
		n = (b - a).cross(d - a)
	if n.length_squared() < 0.000001:
		n = Vector3.UP
	n = n.normalized()
	_ecke(st, a, n, Vector2(0.0, 0.0))
	_ecke(st, b, n, Vector2(1.0, 0.0))
	_ecke(st, c, n, Vector2(1.0, 1.0))
	_ecke(st, a, n, Vector2(0.0, 0.0))
	_ecke(st, c, n, Vector2(1.0, 1.0))
	_ecke(st, d, n, Vector2(0.0, 1.0))


static func _ecke(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.add_vertex(p)


# ---------------------------------------------------------------- Transforme

## Baut eine Transformation aus Position, Euler-Drehung und Skalierung.
## Reihenfolge: erst skalieren, dann drehen, dann verschieben.
static func ort(pos: Vector3, dreh: Vector3 = Vector3.ZERO,
		skal: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(dreh) * Basis.from_scale(skal), pos)


## Transformation, deren Y-Achse von `von` nach `bis` zeigt; Ursprung in der Mitte.
## Passend für Zylinder/Kegel (die stehen in Godot auf der Y-Achse).
static func ausrichten(von: Vector3, bis: Vector3) -> Transform3D:
	var richtung := bis - von
	var laenge := richtung.length()
	if laenge < 0.0001:
		return Transform3D(Basis.IDENTITY, von)
	var y := richtung / laenge
	var hilfe := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := hilfe.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), (von + bis) * 0.5)


## Transformation, deren Z-Achse von `von` nach `bis` zeigt; Ursprung in der Mitte.
## Passend für Boxen (Länge auf der Z-Achse) – z. B. Kollisionsformen und Blätter.
static func ausrichten_z(von: Vector3, bis: Vector3, auf: Vector3 = Vector3.UP) -> Transform3D:
	var richtung := bis - von
	var laenge := richtung.length()
	if laenge < 0.0001:
		return Transform3D(Basis.IDENTITY, von)
	var z := richtung / laenge
	var x := auf.cross(z)
	if x.length_squared() < 0.000001:
		x = Vector3.RIGHT.cross(z)
	x = x.normalized()
	var y := z.cross(x).normalized()
	return Transform3D(Basis(x, y, z), (von + bis) * 0.5)


# ---------------------------------------------------------------- Kollision

## Konvexe Hülle aus einem Mesh. Fällt auf eine Box zurück, falls das nicht klappt.
static func huelle(netz: Mesh) -> Shape3D:
	if netz == null:
		return BoxShape3D.new()
	var form := netz.create_convex_shape(true, true)
	if form != null and form.points.size() >= 4:
		return form
	var kasten_form := BoxShape3D.new()
	var g := netz.get_aabb().size
	kasten_form.size = Vector3(maxf(g.x, 0.05), maxf(g.y, 0.05), maxf(g.z, 0.05))
	return kasten_form
