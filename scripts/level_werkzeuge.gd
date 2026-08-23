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
	var il := mitte - r * innen
	var ir := mitte + r * innen
	var ar := mitte + r * halb

	# Die Kante läuft NUR über die beiden Randstreifen um die Ecke – nicht
	# quer über den Weg. Sonst stünde vor jeder Lücke eine Mauer, gegen die
	# der Spieler beim Anlauf rennt.
	_quad(kante, al + hoch, il + hoch, al + hoch + n * kb, il + hoch + n * kb, Vector3.UP)
	_quad(kante, ir + hoch, ar + hoch, ir + hoch + n * kb, ar + hoch + n * kb, Vector3.UP)
	_quad(kante, al, al + hoch, il, il + hoch, n)
	_quad(kante, ir, ir + hoch, ar, ar + hoch, n)

	# Stirnwand nach unten über die volle Breite: das Loch bekommt eine Kante
	_quad(klippe, al + hoch, al + runter, ar + hoch, ar + runter, n)


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


# ------------------------------------------------------------- Schlucht

## Zwei Wände links und rechts des Weges, die mit ihm mitlaufen.
##
## Aus Blöcken, nicht aus einer gesweepten Fläche. Der erste Entwurf zog
## ein Dreiecksband entlang der Kurve und terrassierte es; sobald der
## Rücksprung je Stufe schwankte, kippte die Normale einzelner Vierecke,
## deren Rückseiten wurden weggeschnitten und übrig blieben schwebende
## Splitter. Ein Quader hat seine Normalen dagegen von Haus aus richtig,
## es gibt keine Nähte und keine Ausrichtungsfrage.
##
## Alle Blöcke einer Wand hängen in einem MultiMesh – das sind je Level
## einige tausend, aber nur ein Zeichenaufruf.
##
## Die Wände tragen KEINE Kollision: Sie stehen außerhalb der begehbaren
## Fläche. Zum Begrenzen dient `leitwand()`, die glatt ist und an der man
## nicht hängen bleibt.
##
## `abschnitte`: [{"von", "bis", "abstand", "hoehe"}]
## `optionen`: {"schritt", "lagen", "block", "saat", "sockel"}
static func schluchtwand(elternteil: Node3D, kurve: Curve3D, abschnitte: Array,
		material: Material, optionen: Dictionary = {}) -> Node3D:
	var schritt: float = optionen.get("schritt", 3.0)
	var lagen: int = optionen.get("lagen", 4)        ## Blocklagen übereinander
	var block: float = optionen.get("block", 3.2)    ## Grundmaß eines Blocks
	var sockel: float = optionen.get("sockel", 6.0)  ## wie tief die unterste Lage reicht
	var saat: int = optionen.get("saat", 1234)

	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = saat

	var wurzel := Node3D.new()
	wurzel.name = "Schluchtwand"
	elternteil.add_child(wurzel)

	var stellen: Array[Transform3D] = []
	for eintrag in abschnitte:
		var von: float = eintrag.get("von", 0.0)
		var bis: float = eintrag.get("bis", 0.0)
		if bis <= von:
			continue
		var abstand: float = eintrag.get("abstand", 8.0)
		var hoehe: float = eintrag.get("hoehe", 12.0)
		var anzahl := maxi(int(ceil((bis - von) / schritt)), 1)
		for i in anzahl:
			var s := lerpf(von, bis, (float(i) + 0.5) / float(anzahl))
			for seite: float in [-1.0, 1.0]:
				_wandbloecke(stellen, kurve, s, abstand, hoehe, seite, lagen,
						block, sockel, wuerfel)

	var netz := BoxMesh.new()
	netz.size = Vector3.ONE
	var haufen := MultiMesh.new()
	haufen.transform_format = MultiMesh.TRANSFORM_3D
	haufen.mesh = netz
	haufen.instance_count = stellen.size()
	for i in stellen.size():
		haufen.set_instance_transform(i, stellen[i])

	var anzeige := MultiMeshInstance3D.new()
	anzeige.name = "Bloecke"
	anzeige.multimesh = haufen
	anzeige.material_override = material
	wurzel.add_child(anzeige)
	return wurzel


## Eine Säule aus Blöcken an einer Stelle der Wand.
##
## Die Lagen springen nach oben leicht zurück und werden kleiner – das
## ergibt die Terrassierung, ohne dass eine Fläche gebogen werden müsste.
static func _wandbloecke(hinein: Array[Transform3D], kurve: Curve3D, s: float,
		abstand: float, hoehe: float, seite: float, lagen: int, block: float,
		sockel: float, wuerfel: RandomNumberGenerator) -> void:
	var r := _rechts(kurve, s) * seite
	var dreh := drehung(kurve, s)

	# Unterste Lage reicht unter den Weg, damit unten keine Fuge klafft.
	var lagen_hoehe := (hoehe + sockel) / float(lagen)
	var y := -sockel
	for k in lagen:
		var t := float(k) / float(maxi(lagen - 1, 1))
		var tiefe := block * lerpf(1.0, 0.55, t) * wuerfel.randf_range(0.8, 1.25)
		var breite := block * wuerfel.randf_range(0.7, 1.15)
		var hoch := lagen_hoehe * wuerfel.randf_range(0.9, 1.3)
		# Nach oben etwas zurücktreten, aber nie über den Weg lehnen.
		var quer := abstand + block * 0.5 + t * block * 0.35 \
				+ wuerfel.randf_range(-0.25, 0.45)

		var mitte := punkt(kurve, s, seite * quer, y + hoch * 0.5)
		var form := Transform3D(Basis.IDENTITY, mitte)
		form.basis = Basis(Vector3.UP, dreh + wuerfel.randf_range(-0.12, 0.12))
		form.basis = form.basis.scaled(Vector3(tiefe, hoch, breite))
		hinein.append(form)
		y += hoch * wuerfel.randf_range(0.7, 0.92)   # Lagen überlappen sich


## Unsichtbare Leitwand am Rand der Schlucht.
##
## Ein Korridorlevel ist bisher ein Plateau: Wer seitlich hinunterläuft,
## fällt. In einer Schlucht ist das falsch – dort begrenzen Wände, und
## fallen kann man nur durch eine Spalte im Boden. Diese Wand übernimmt
## das Begrenzen.
##
## Sie besteht aus einzelnen Kästen statt aus einem Dreiecksnetz: Ein
## Trimesh über die zerklüftete Sichtwand wäre teuer und würde den Spieler
## an jeder Zacke hängen lassen. Die Kästen stehen glatt und dicht an der
## Wand, davon merkt man beim Anlaufen nichts.
static func leitwand(elternteil: Node3D, kurve: Curve3D, von: float, bis: float,
		abstand: float, hoehe: float = 4.0, schritt: float = 3.0) -> StaticBody3D:
	var koerper := StaticBody3D.new()
	koerper.name = "Leitwand"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	elternteil.add_child(koerper)

	var s := von
	while s < bis:
		var laenge := minf(schritt, bis - s)
		var mitte_s := s + laenge * 0.5
		for seite: float in [-1.0, 1.0]:
			var form := CollisionShape3D.new()
			var kasten := BoxShape3D.new()
			# Etwas länger als der Schritt, damit zwischen zwei Kästen in
			# einer Kurve keine Lücke aufgeht.
			kasten.size = Vector3(1.0, hoehe, laenge + 0.8)
			form.shape = kasten
			form.position = punkt(kurve, mitte_s, seite * (abstand + 0.5), hoehe * 0.5)
			form.rotation.y = drehung(kurve, mitte_s)
			koerper.add_child(form)
		s += laenge
	return koerper


## Waagerechtes Sims entlang beider Schluchtwände.
##
## Es schließt den klaffenden Zwischenraum zwischen Weg und Wand und gibt
## den Bäumen und Steinen eine Standfläche – ohne es hingen sie sichtbar
## in der Luft, was in der Seitenansicht des 2D-Abschnitts sofort auffiel.
## Rein optisch, ohne Kollision: Der Spieler soll den Weg nehmen.
##
## `abschnitte`: [{"von", "bis", "innen", "aussen", "hoehe"}]
static func sims(elternteil: Node3D, kurve: Curve3D, abschnitte: Array,
		material: Material, schritt: float = 3.0) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Simse"
	elternteil.add_child(wurzel)

	for eintrag in abschnitte:
		var von: float = eintrag.get("von", 0.0)
		var bis: float = eintrag.get("bis", 0.0)
		if bis <= von:
			continue
		for seite: float in [-1.0, 1.0]:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var anzahl := maxi(int(ceil((bis - von) / schritt)), 1)
			var innen: float = eintrag.get("innen", 6.0)
			var aussen: float = eintrag.get("aussen", 12.0)
			var hoehe: float = eintrag.get("hoehe", -2.0)
			var vorher := {}
			for i in anzahl + 1:
				var s := lerpf(von, bis, float(i) / float(anzahl))
				var q := {
					"i": punkt(kurve, s, seite * innen, hoehe),
					"a": punkt(kurve, s, seite * aussen, hoehe + 0.6),
				}
				if not vorher.is_empty():
					_quad(st, vorher["i"], vorher["a"], q["i"], q["a"], Vector3.UP)
				vorher = q
			_flaeche(wurzel, st, material, "Sims")
	return wurzel


## Ein Torbogen quer über den Weg, aus einzelnen Blöcken gesetzt.
##
## Der erste Versuch nahm für die Breite `breite * 0.62`, für die Höhe aber
## einen festen Radius und lief nur bis ±66°. Daraus wurde eine
## abgeschnittene Ellipse aus freischwebenden Blöcken. Hier ist es ein
## echter Halbkreis: gleicher Radius für beide Achsen, von Boden zu Boden.
static func torbogen(elternteil: Node3D, kurve: Curve3D, strecke: float,
		spannweite: float, material: Material, bloecke: int = 11,
		fusshoehe: float = 0.0) -> Node3D:
	var bogen := Node3D.new()
	bogen.name = "Torbogen"
	bogen.position = punkt(kurve, strecke, 0.0, fusshoehe)
	bogen.rotation.y = drehung(kurve, strecke)
	elternteil.add_child(bogen)

	var radius := spannweite * 0.5
	# Blockbreite so wählen, dass sich die Blöcke am Scheitel berühren.
	var bogenlaenge := PI * radius
	var block_laenge := bogenlaenge / float(bloecke) * 1.15
	for i in bloecke:
		var t := (float(i) + 0.5) / float(bloecke)
		var winkel := lerpf(-PI * 0.5, PI * 0.5, t)
		var block := MeshInstance3D.new()
		var kasten := BoxMesh.new()
		kasten.size = Vector3(radius * 0.26, block_laenge, radius * 0.34)
		block.mesh = kasten
		block.material_override = material
		block.position = Vector3(sin(winkel) * radius, cos(winkel) * radius, 0.0)
		# Der Block steht quer zum Radius, also um den Winkel gedreht.
		block.rotation.z = -winkel
		bogen.add_child(block)
	return bogen
