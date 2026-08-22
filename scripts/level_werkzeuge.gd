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

## Baut den Weg entlang der Kurve als drei getrennte Flächen:
##   Wegdecke  – begehbare Oberfläche (eigenes Material)
##   Kante     – erhöhte Rasen-/Steinkante am Rand, macht den Weg lesbar
##   Klippe    – senkrechte Wand nach unten, macht die Tiefe sichtbar
##
## `abschnitte`: Liste von {"von", "bis", "breite", "breite_ende"}.
## Lücken zwischen den Abschnitten sind die Sprungpassagen; ihre
## Stirnseiten werden geschlossen und mit der Kante umrandet, damit
## Löcher von weitem erkennbar sind.
##
## `optionen`: {"tiefe", "schritt", "kollision", "kante_hoehe",
##              "kante_breite", "hoehe_versatz"}
static func korridor(elternteil: Node3D, kurve: Curve3D, abschnitte: Array,
		materialien: Dictionary, optionen: Dictionary = {}) -> Node3D:
	var tiefe: float = optionen.get("tiefe", 8.0)
	var schritt: float = optionen.get("schritt", 1.2)
	var kollision: bool = optionen.get("kollision", true)
	var kante_hoehe: float = optionen.get("kante_hoehe", 0.34)
	var kante_breite: float = optionen.get("kante_breite", 0.7)
	var versatz: float = optionen.get("hoehe_versatz", 0.0)

	var oben := SurfaceTool.new()
	var kante := SurfaceTool.new()
	var klippe := SurfaceTool.new()
	for st in [oben, kante, klippe]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for eintrag in abschnitte:
		var von: float = eintrag.get("von", 0.0)
		var bis: float = eintrag.get("bis", 0.0)
		if bis <= von:
			continue
		_abschnitt(oben, kante, klippe, kurve, von, bis,
				eintrag.get("breite", 8.0),
				eintrag.get("breite_ende", eintrag.get("breite", 8.0)),
				tiefe, schritt, kante_hoehe, kante_breite, versatz)

	var wurzel := Node3D.new()
	wurzel.name = "Korridor"
	elternteil.add_child(wurzel)

	var decke := _flaeche(wurzel, oben, materialien.get("oben"), "Wegdecke")
	var rand := _flaeche(wurzel, kante, materialien.get("kante"), "Kante")
	_flaeche(wurzel, klippe, materialien.get("klippe"), "Klippe")

	if kollision:
		if decke != null:
			decke.create_trimesh_collision()
		if rand != null:
			rand.create_trimesh_collision()
	return wurzel


static func _flaeche(elternteil: Node3D, st: SurfaceTool, material: Variant,
		bezeichnung: String) -> MeshInstance3D:
	st.index()
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = mesh
	if material != null:
		mi.material_override = material
	elternteil.add_child(mi)
	return mi


static func _abschnitt(oben: SurfaceTool, kante: SurfaceTool, klippe: SurfaceTool,
		kurve: Curve3D, von: float, bis: float, breite_a: float, breite_b: float,
		tiefe: float, schritt: float, kh: float, kb: float, versatz: float) -> void:
	var anzahl := maxi(int(ceil((bis - von) / schritt)), 1)
	var laenge := kurve.get_baked_length()

	# Querschnitt an einer Stelle: außen links, innen links, innen rechts, außen rechts
	var vorher := {}
	for i in anzahl + 1:
		var t := float(i) / float(anzahl)
		var s := lerpf(von, bis, t)
		var breite := lerpf(breite_a, breite_b, t)
		var mitte := kurve.sample_baked(clampf(s, 0.0, laenge)) + Vector3.UP * versatz
		var r := _rechts(kurve, s)
		var halb := breite * 0.5
		var innen := maxf(halb - kb, halb * 0.35)

		var q := {
			"al": mitte - r * halb, "il": mitte - r * innen,
			"ir": mitte + r * innen, "ar": mitte + r * halb,
			"r": r, "s": s,
		}
		if not vorher.is_empty():
			_querstueck(oben, kante, klippe, vorher, q, kh, tiefe)
		vorher = q

	_stirn(oben, kante, klippe, kurve, von, breite_a, kh, kb, tiefe, versatz, true)
	_stirn(oben, kante, klippe, kurve, bis, breite_b, kh, kb, tiefe, versatz, false)


static func _querstueck(oben: SurfaceTool, kante: SurfaceTool, klippe: SurfaceTool,
		a: Dictionary, b: Dictionary, kh: float, tiefe: float) -> void:
	var hoch := Vector3.UP * kh
	var runter := Vector3.DOWN * tiefe

	# --- begehbare Wegdecke ---
	_quad(oben, a["il"], a["ir"], b["il"], b["ir"], Vector3.UP)

	# --- linke Kante: Oberseite und Innenflanke ---
	_quad(kante, a["al"] + hoch, a["il"] + hoch, b["al"] + hoch, b["il"] + hoch, Vector3.UP)
	_quad(kante, a["il"], a["il"] + hoch, b["il"], b["il"] + hoch, a["r"])
	# --- rechte Kante ---
	_quad(kante, a["ir"] + hoch, a["ar"] + hoch, b["ir"] + hoch, b["ar"] + hoch, Vector3.UP)
	_quad(kante, a["ir"], a["ir"] + hoch, b["ir"], b["ir"] + hoch, -a["r"])

	# --- Klippen nach unten ---
	_quad(klippe, a["al"] + hoch, a["al"] + runter, b["al"] + hoch, b["al"] + runter, -a["r"])
	_quad(klippe, a["ar"] + hoch, a["ar"] + runter, b["ar"] + hoch, b["ar"] + runter, a["r"])


## Stirnseite an einer Abbruchkante: verschließt das Loch und umrandet es.
static func _stirn(oben: SurfaceTool, kante: SurfaceTool, klippe: SurfaceTool,
		kurve: Curve3D, s: float, breite: float, kh: float, kb: float,
		tiefe: float, versatz: float, am_anfang: bool) -> void:
	var laenge := kurve.get_baked_length()
	var mitte := kurve.sample_baked(clampf(s, 0.0, laenge)) + Vector3.UP * versatz
	var r := _rechts(kurve, s)
	var v := richtung(kurve, s)
	var halb := breite * 0.5
	var innen := maxf(halb - kb, halb * 0.35)
	var n := -v if am_anfang else v
	var hoch := Vector3.UP * kh
	var runter := Vector3.DOWN * tiefe

	var al := mitte - r * halb
	var ar := mitte + r * halb
	# Kante quer über das Wegende: macht das Loch von weitem sichtbar
	_quad(kante, al + hoch, ar + hoch, al + hoch + n * kb, ar + hoch + n * kb, Vector3.UP)
	_quad(kante, al, al + hoch, ar, ar + hoch, n)
	# Wand nach unten
	_quad(klippe, al + hoch, al + runter, ar + hoch, ar + runter, n)
	# innere Kanten-Ecken schließen
	_quad(kante, mitte - r * innen, mitte - r * innen + hoch, al, al + hoch, -v if am_anfang else v)
	_quad(kante, mitte + r * innen, mitte + r * innen + hoch, ar, ar + hoch, -v if am_anfang else v)


# ------------------------------------------------------------- Mesh-Hilfen

## Viereck aus zwei Dreiecken. a/b liegen auf der einen Kante, c/d auf der
## gegenüberliegenden. Die Wicklung wird automatisch so gewählt, dass die
## Fläche in Richtung `normale` sichtbar ist – Godot zeichnet die
## Vorderseite bei Punkten im Uhrzeigersinn.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normale: Vector3) -> void:
	_dreieck(st, a, b, c, normale)
	_dreieck(st, b, d, c, normale)


static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3) -> void:
	var n := normale.normalized()
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tausch := b
		b = c
		c = tausch
	for p in [a, b, c]:
		st.set_normal(n)
		# Dreiachsige Projektion in den Materialien macht echte UVs entbehrlich;
		# für Materialien ohne Triplanar reicht diese Weltprojektion.
		if absf(n.y) > 0.7:
			st.set_uv(Vector2(p.x, p.z) * 0.25)
		else:
			st.set_uv(Vector2(p.x + p.z, -p.y) * 0.25)
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
