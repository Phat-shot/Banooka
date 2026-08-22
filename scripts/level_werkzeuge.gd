extends RefCounted
class_name LevelWerkzeuge
## Bauhilfen für Level: gebogene Bodenstreifen entlang einer Kurve,
## Plattformen und Platzierungshilfen relativ zum Korridorverlauf.
##
## Die Levelgeometrie wird komplett im Code erzeugt. Der Verlauf des
## Korridors steckt in einem `Curve3D`; alles andere (Kisten, Gegner,
## Bäume) wird über `punkt()` relativ dazu platziert. Dadurch lässt sich
## der Levelverlauf ändern, ohne jedes Objekt einzeln zu verschieben.

## Godot zeichnet Dreiecke als Vorderseite, wenn ihre Punkte aus Blickrichtung
## IM Uhrzeigersinn liegen. Die Wicklung unten ist entsprechend gewählt;
## zusätzlich werden die Normalen explizit gesetzt.


# ------------------------------------------------------------- Platzierung

## Punkt relativ zum Korridor: `strecke` entlang der Kurve,
## `seitlich` quer dazu (positiv = rechts), `hoehe` nach oben.
static func punkt(kurve: Curve3D, strecke: float, seitlich: float = 0.0,
		hoehe: float = 0.0) -> Vector3:
	var laenge := kurve.get_baked_length()
	var s := clampf(strecke, 0.0, laenge)
	var mitte := kurve.sample_baked(s)
	var rechts := _rechts(kurve, s)
	return mitte + rechts * seitlich + Vector3.UP * hoehe


## Tangente (Blickrichtung des Korridors) an der Stelle `strecke`.
static func richtung(kurve: Curve3D, strecke: float) -> Vector3:
	var laenge := kurve.get_baked_length()
	var s := clampf(strecke, 0.0, laenge)
	var a := kurve.sample_baked(maxf(s - 0.5, 0.0))
	var b := kurve.sample_baked(minf(s + 0.5, laenge))
	var d := b - a
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 else Vector3.FORWARD


## Drehung um die Y-Achse, sodass ein Objekt dem Korridor folgt.
static func drehung(kurve: Curve3D, strecke: float) -> float:
	var d := richtung(kurve, strecke)
	return atan2(-d.x, -d.z)


static func _rechts(kurve: Curve3D, strecke: float) -> Vector3:
	var vorwaerts := richtung(kurve, strecke)
	return vorwaerts.cross(Vector3.UP).normalized()


# ------------------------------------------------------------- Korridor

## Baut den Boden des Korridors entlang der Kurve.
##
## `abschnitte` ist eine Liste von Wörterbüchern:
##   {"von": float, "bis": float, "breite": float, "breite_ende": float}
## "breite_ende" ist optional (Standard = "breite") und erlaubt sich
## verjüngende oder verbreiternde Passagen. Lücken zwischen den
## Abschnitten bleiben offen – das sind die Sprungpassagen.
static func korridor(elternteil: Node3D, kurve: Curve3D, abschnitte: Array,
		material: Material, tiefe: float = 6.0, schritt: float = 1.0,
		mit_kollision: bool = true) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for eintrag in abschnitte:
		var von: float = eintrag.get("von", 0.0)
		var bis: float = eintrag.get("bis", 0.0)
		if bis <= von:
			continue
		var breite_a: float = eintrag.get("breite", 8.0)
		var breite_b: float = eintrag.get("breite_ende", breite_a)
		_streifen(st, kurve, von, bis, breite_a, breite_b, tiefe, schritt)

	st.index()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Korridorboden"
	mi.mesh = mesh
	# Sicherheitsnetz: beidseitig sichtbar, damit der Boden auf keinen Fall
	# durch eine falsch herum gewickelte Fläche verschwindet.
	var mat := material.duplicate() as BaseMaterial3D
	if mat != null:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
	else:
		mi.material_override = material
	elternteil.add_child(mi)
	if mit_kollision:
		mi.create_trimesh_collision()
	return mi


static func _streifen(st: SurfaceTool, kurve: Curve3D, von: float, bis: float,
		breite_a: float, breite_b: float, tiefe: float, schritt: float) -> void:
	var anzahl := maxi(int(ceil((bis - von) / schritt)), 1)
	var links_alt := Vector3.ZERO
	var rechts_alt := Vector3.ZERO
	var hat_alt := false

	for i in anzahl + 1:
		var t := float(i) / float(anzahl)
		var s := lerpf(von, bis, t)
		var breite := lerpf(breite_a, breite_b, t)
		var mitte := kurve.sample_baked(clampf(s, 0.0, kurve.get_baked_length()))
		var rechts_vektor := _rechts(kurve, s)
		var links := mitte - rechts_vektor * breite * 0.5
		var rechts := mitte + rechts_vektor * breite * 0.5

		if hat_alt:
			# --- Oberseite (Blick von oben, im Uhrzeigersinn) ---
			_dreieck(st, rechts_alt, links_alt, rechts, Vector3.UP, s)
			_dreieck(st, links_alt, links, rechts, Vector3.UP, s)

			# --- Seitenwände nach unten (Klippen) ---
			var runter := Vector3.DOWN * tiefe
			var n_rechts := rechts_vektor
			_dreieck(st, rechts_alt, rechts, rechts_alt + runter, n_rechts, s)
			_dreieck(st, rechts_alt + runter, rechts, rechts + runter, n_rechts, s)

			var n_links := -rechts_vektor
			_dreieck(st, links_alt, links_alt + runter, links, n_links, s)
			_dreieck(st, links_alt + runter, links + runter, links, n_links, s)

		links_alt = links
		rechts_alt = rechts
		hat_alt = true

	# --- Stirnseiten an den Abschnittsenden, damit keine Löcher entstehen ---
	_stirnseite(st, kurve, von, breite_a, tiefe, true)
	_stirnseite(st, kurve, bis, breite_b, tiefe, false)


static func _stirnseite(st: SurfaceTool, kurve: Curve3D, s: float, breite: float,
		tiefe: float, am_anfang: bool) -> void:
	var mitte := kurve.sample_baked(clampf(s, 0.0, kurve.get_baked_length()))
	var rechts_vektor := _rechts(kurve, s)
	var vorwaerts := richtung(kurve, s)
	var links := mitte - rechts_vektor * breite * 0.5
	var rechts := mitte + rechts_vektor * breite * 0.5
	var runter := Vector3.DOWN * tiefe
	var n := -vorwaerts if am_anfang else vorwaerts
	if am_anfang:
		_dreieck(st, links, rechts, links + runter, n, s)
		_dreieck(st, links + runter, rechts, rechts + runter, n, s)
	else:
		_dreieck(st, rechts, links, rechts + runter, n, s)
		_dreieck(st, rechts + runter, links, links + runter, n, s)


static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3, uv_versatz: float) -> void:
	for p in [a, b, c]:
		st.set_normal(normale)
		st.set_uv(Vector2(p.x * 0.25, (p.z + uv_versatz) * 0.25))
		st.add_vertex(p)


# ------------------------------------------------------------- Bauteile

## Einfache rechteckige Plattform mit Kollision.
static func plattform(elternteil: Node3D, pos: Vector3, groesse: Vector3,
		material: Material, drehung_y: float = 0.0) -> StaticBody3D:
	var koerper := StaticBody3D.new()
	koerper.position = pos
	koerper.rotation.y = drehung_y
	koerper.collision_layer = 1
	koerper.collision_mask = 0

	var wuerfel := BoxMesh.new()
	wuerfel.size = groesse
	var mi := MeshInstance3D.new()
	mi.mesh = wuerfel
	mi.material_override = material
	koerper.add_child(mi)

	var form := BoxShape3D.new()
	form.size = groesse
	var kollision := CollisionShape3D.new()
	kollision.shape = form
	koerper.add_child(kollision)

	elternteil.add_child(koerper)
	return koerper


## Erzeugt eine Kurve aus einer Liste von Punkten mit weichen Übergängen.
static func kurve_aus_punkten(punkte: Array, glaettung: float = 0.45) -> Curve3D:
	var kurve := Curve3D.new()
	for i in punkte.size():
		var p: Vector3 = punkte[i]
		var vorher: Vector3 = punkte[maxi(i - 1, 0)]
		var nachher: Vector3 = punkte[mini(i + 1, punkte.size() - 1)]
		var tangente := (nachher - vorher) * glaettung * 0.5
		kurve.add_point(p, -tangente, tangente)
	return kurve
