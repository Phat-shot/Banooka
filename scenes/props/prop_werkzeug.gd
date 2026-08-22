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


## Wie `fertig()`, erzeugt vorher aber Tangenten. Nötig für jeden Sammler,
## der über `klumpen()`, `flaeche()` oder `blatt()` befüllt wurde: die
## Materialien der Bibliothek tragen Normalmaps, und ohne Tangenten bliebe
## deren Struktur wirkungslos. (Primitive aus `anfuegen()` bringen ihre
## Tangenten schon mit – die beiden Wege deshalb nie mischen.)
static func fertig_mit_tangenten(st: SurfaceTool) -> ArrayMesh:
	if st == null:
		return null
	st.generate_tangents()
	return fertig(st)


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


# ---------------------------------------------------------------- Ausrichtung

## Godot zeichnet ein Dreieck (a, b, c) als Vorderseite, wenn
## `(b-a) x (c-a)` ENTGEGEN der Außenrichtung zeigt (empirisch an
## `SphereMesh` geprüft). Diese Hilfe nimmt einem das Nachdenken ab:
## `aussen` ist grob die Richtung, in die die Fläche schauen soll –
## die Reihenfolge wird bei Bedarf getauscht und die Flächennormale gesetzt.
static func flaeche(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		aussen: Vector3, farbe: Color = Color.WHITE) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-12:
		return
	var p_b := b
	var p_c := c
	if kreuz.dot(aussen) > 0.0:
		p_b = c
		p_c = b
		kreuz = -kreuz
	var n := -kreuz.normalized()
	_ecke_farbig(st, a, n, Vector2(0.0, 0.0), farbe)
	_ecke_farbig(st, p_b, n, Vector2(1.0, 0.0), farbe)
	_ecke_farbig(st, p_c, n, Vector2(0.0, 1.0), farbe)


## Eingefärbtes Viereck (a, b, c, d im Umlauf) – die Vorderseite schaut in
## Richtung `normale`. Für Blätter, Wedel und Blütenblätter.
static func blatt(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normale: Vector3, farbe_ab: Color = Color.WHITE,
		farbe_cd: Color = Color.WHITE) -> void:
	var n := normale
	if n.length_squared() < 0.000001:
		n = (b - a).cross(d - a)
	if n.length_squared() < 0.000001:
		return
	n = n.normalized()
	# Reihenfolge gedreht, damit die Vorderseite wirklich zu `n` zeigt
	_ecke_farbig(st, a, n, Vector2(0.0, 0.0), farbe_ab)
	_ecke_farbig(st, c, n, Vector2(1.0, 1.0), farbe_cd)
	_ecke_farbig(st, b, n, Vector2(1.0, 0.0), farbe_ab)
	_ecke_farbig(st, a, n, Vector2(0.0, 0.0), farbe_ab)
	_ecke_farbig(st, d, n, Vector2(0.0, 1.0), farbe_cd)
	_ecke_farbig(st, c, n, Vector2(1.0, 1.0), farbe_cd)


static func _ecke_farbig(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2,
		farbe: Color) -> void:
	st.set_color(farbe)
	st.set_normal(n)
	st.set_uv(uv)
	st.add_vertex(p)


# ---------------------------------------------------------------- Klumpen

## Unregelmäßiger, geschlossener Ballen – direkt in den Sammler geschrieben.
##
## Gegenüber `anfuegen(kugel(...))` lässt sich hier jeder Scheitelpunkt
## verschieben und einfärben; erst dadurch bekommen Kronen und Felsen eine
## erkennbare Silhouette. Die Unruhe läuft über Sinusterme mit ganzzahligen
## Faktoren in `theta`, damit die Form rundherum nahtlos schließt, und wird
## an den Polen ausgeblendet, damit dort nichts einschnürt.
##
## `kantig = true` setzt Flächennormalen ⇒ facettierte Felsoptik.
## `y_unten`/`y_oben` spannen den Farbverlauf über MEHRERE Ballen hinweg auf
## (Koordinaten wie `mitte`); bei `y_oben <= y_unten` gilt der eigene Ballen.
static func klumpen(st: SurfaceTool, rng: RandomNumberGenerator, mitte: Vector3,
		radien: Vector3, dreh: Vector3, seiten: int, ringe: int, unruhe: float,
		kantig: bool = false, farbe_unten: Color = Color.WHITE,
		farbe_oben: Color = Color.WHITE, y_unten: float = 0.0,
		y_oben: float = 0.0) -> void:
	var n_seiten := maxi(seiten, 4)
	var n_ringe := maxi(ringe, 2)
	var basis := Basis.from_euler(dreh)

	# Drei Wellen; die theta-Faktoren sind ganzzahlig ⇒ rundherum nahtlos
	var wa := rng.randi_range(2, 4)
	var wb := rng.randi_range(2, 5)
	var pa := rng.randf() * TAU
	var pb := rng.randf() * TAU
	var pc := rng.randf() * TAU

	var von := y_unten
	var bis := y_oben
	if bis <= von:
		von = mitte.y - radien.y
		bis = mitte.y + radien.y

	var punkte: Array[PackedVector3Array] = []
	var normalen: Array[PackedVector3Array] = []
	var farben: Array = []
	for i in n_ringe + 1:
		var ph := PI * float(i) / float(n_ringe)
		var reihe := PackedVector3Array()
		var nreihe := PackedVector3Array()
		var freihe: Array[Color] = []
		for j in n_seiten + 1:
			var th := TAU * float(j % n_seiten) / float(n_seiten)
			var s := sin(ph)
			# Die Terme sind auf Summe 1 normiert und zusätzlich begrenzt:
			# ohne das können sich die Wellen aufschaukeln und einzelne
			# Zacken schießen als dünne Klingen aus der Form heraus.
			var welle := 0.46 * sin(wa * th + pa) * cos(ph * 2.0 + pb) \
					+ 0.32 * sin(wb * th + pc)
			var f := 1.0 + unruhe * clampf(s * welle + 0.22 * sin(ph * 3.0 + pb),
					-1.0, 1.0)
			var einheit := Vector3(s * cos(th), cos(ph), s * sin(th))
			var lokal := Vector3(einheit.x * radien.x, einheit.y * radien.y,
					einheit.z * radien.z) * f
			var nl := Vector3(einheit.x / maxf(radien.x, 0.0001),
					einheit.y / maxf(radien.y, 0.0001),
					einheit.z / maxf(radien.z, 0.0001)).normalized()
			var p := mitte + basis * lokal
			reihe.append(p)
			nreihe.append((basis * nl).normalized())
			freihe.append(farbe_unten.lerp(farbe_oben,
					clampf(inverse_lerp(von, bis, p.y), 0.0, 1.0)))
		punkte.append(reihe)
		normalen.append(nreihe)
		farben.append(freihe)

	for i in n_ringe:
		for j in n_seiten:
			var a: Vector3 = punkte[i][j]
			var b: Vector3 = punkte[i][j + 1]
			var c: Vector3 = punkte[i + 1][j + 1]
			var d: Vector3 = punkte[i + 1][j]
			# Reihenfolge (a, c, b) bzw. (a, d, c) ⇒ Vorderseite nach außen
			if i > 0:
				_klumpen_tri(st, a, c, b, normalen[i][j], normalen[i + 1][j + 1],
						normalen[i][j + 1], farben[i][j], farben[i + 1][j + 1],
						farben[i][j + 1], _uv(i, j, n_ringe, n_seiten),
						_uv(i + 1, j + 1, n_ringe, n_seiten),
						_uv(i, j + 1, n_ringe, n_seiten), kantig)
			if i < n_ringe - 1:
				_klumpen_tri(st, a, d, c, normalen[i][j], normalen[i + 1][j],
						normalen[i + 1][j + 1], farben[i][j], farben[i + 1][j],
						farben[i + 1][j + 1], _uv(i, j, n_ringe, n_seiten),
						_uv(i + 1, j, n_ringe, n_seiten),
						_uv(i + 1, j + 1, n_ringe, n_seiten), kantig)


static func _uv(i: int, j: int, ringe: int, seiten: int) -> Vector2:
	return Vector2(float(j) / float(seiten), float(i) / float(ringe))


static func _klumpen_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3, fa: Color, fb: Color, fc: Color,
		ua: Vector2, ub: Vector2, uc: Vector2, kantig: bool) -> void:
	var n_a := na
	var n_b := nb
	var n_c := nc
	if kantig:
		var kreuz := (b - a).cross(c - a)
		if kreuz.length_squared() < 1e-12:
			return
		n_a = -kreuz.normalized()
		n_b = n_a
		n_c = n_a
	_ecke_farbig(st, a, n_a, ua, fa)
	_ecke_farbig(st, b, n_b, ub, fb)
	_ecke_farbig(st, c, n_c, uc, fc)


# ---------------------------------------------------------------- Material

static var _mit_farben: Dictionary = {}

## Variante eines Bibliotheksmaterials, die Scheitelfarben als Albedo-Faktor
## nutzt. Die Bibliothek selbst bleibt unangetastet; das Ergebnis wird je
## Ausgangsmaterial einmal erzeugt und dann geteilt.
##
## Scheitelfarben multiplizieren – sie können also nur abdunkeln. Genau das
## ist gewollt: Kronen unten dunkel, Felsen unten dunkel.
static func mit_scheitelfarben(basis: Material) -> Material:
	if basis == null:
		return null
	var schluessel := basis.get_instance_id()
	var vorhanden: Variant = _mit_farben.get(schluessel)
	if vorhanden != null and is_instance_valid(vorhanden):
		return vorhanden
	var m: Material = basis.duplicate()
	if m is StandardMaterial3D:
		(m as StandardMaterial3D).vertex_color_use_as_albedo = true
	_mit_farben[schluessel] = m
	return m
