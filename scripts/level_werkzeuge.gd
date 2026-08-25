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
## Je Seite ein Knoten "WandLinks" bzw. "WandRechts" mit bis zu drei
## MultiMeshes darin – das sind je Level einige tausend Blöcke, aber nur
## wenige Zeichenaufrufe. Nach Seiten getrennt sind sie, damit die
## Seitenansicht des 2D-Abschnitts die nahe Wand ausblenden kann: Sonst
## stünde sie zwischen Kamera und Spieler und das halbe Bild wäre zu.
##
## Die drei Lagen tragen die Farbe der Schlucht:
##   Koerper  der Grundfels – in den Vorlagen ist er WARM, auch im Schnee.
##            Eine Schlucht ganz aus Eis wird monochrom und flach.
##   Adern    Bänder aus einem zweiten Material, die in Wellen über die
##            Länge laufen (bei uns das Gletschereis). Sie liegen als
##            zusammenhängende Bänder, nicht als Sprenkel – gesprenkelt
##            sähe die Wand aus wie Tarnstoff.
##   Deck     die oberste Blocklage, meist Schnee oder Bewuchs. In den
##            Vorlagen liegt der Schnee OBEN AUF dem Fels, er ist nicht
##            der Fels.
## `adermaterial` und `deckmaterial` sind freiwillig; ohne sie bleibt es
## bei der einen Wand von früher.
##
## Die Wände tragen KEINE Kollision: Sie stehen außerhalb der begehbaren
## Fläche. Zum Begrenzen dient `leitwand()`, die glatt ist und an der man
## nicht hängen bleibt.
##
## `abschnitte`: [{"von", "bis", "abstand", "hoehe"}]
## `optionen`: {"schritt", "lagen", "block", "saat", "sockel",
##              "adermaterial", "deckmaterial", "aderdichte"}
static func schluchtwand(elternteil: Node3D, kurve: Curve3D, abschnitte: Array,
		material: Material, optionen: Dictionary = {}) -> Node3D:
	var schritt: float = optionen.get("schritt", 3.0)
	var lagen: int = optionen.get("lagen", 4)        ## Blocklagen ÜBER dem Weg
	var block: float = optionen.get("block", 3.2)    ## Grundmaß eines Blocks
	var sockel: float = optionen.get("sockel", 6.0)  ## wie tief die unterste Lage reicht
	var saat: int = optionen.get("saat", 1234)
	var adermaterial: Material = optionen.get("adermaterial", null)
	var deckmaterial: Material = optionen.get("deckmaterial", null)
	## Schwelle der Bandwelle: kleiner = mehr Adern.
	var aderdichte: float = optionen.get("aderdichte", 0.35)

	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = saat

	var wurzel := Node3D.new()
	wurzel.name = "Schluchtwand"
	elternteil.add_child(wurzel)

	# Je Seite vier Töpfe: Grundfels, Adern, Deckschicht, Geröll.
	var je_seite := {}
	for seite: float in [-1.0, 1.0]:
		je_seite[seite] = {
			"koerper": [] as Array[Transform3D],
			"ader": [] as Array[Transform3D],
			"deck": [] as Array[Transform3D],
			"geroell": [] as Array[Transform3D],
			# Je Block eine eigene Farbe. Ohne die trägt jeder Würfel
			# dasselbe Muster in derselben Helligkeit, und eine Wand aus
			# hundert gleichen Würfeln liest sich als Tapete.
			"koerper_farbe": [] as Array[Color],
			"ader_farbe": [] as Array[Color],
			"deck_farbe": [] as Array[Color],
			"geroell_farbe": [] as Array[Color],
		}

	var phase := float(saat % 360) * 0.017
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
			# Zwei Wellen mit unterschiedlicher Länge: das Band wandert
			# unregelmäßig, wiederholt sich aber nicht sichtbar.
			var welle := sin(s * 0.20 + phase) * 0.6 + sin(s * 0.083 + phase * 1.7) * 0.4
			var ist_ader := adermaterial != null and welle > aderdichte
			for seite: float in [-1.0, 1.0]:
				_wandbloecke(je_seite[seite], kurve, s, seite, wuerfel, {
					"abstand": abstand, "hoehe": hoehe, "lagen": lagen,
					"block": block, "sockel": sockel, "schritt": schritt,
					"phase": phase, "ader": ist_ader,
					"deck": deckmaterial != null,
				})

	var netz := BoxMesh.new()
	netz.size = Vector3.ONE
	# Ein Material nur einmal nachbauen: Grundfels und Geröll teilen sich
	# denselben Stoff, zwei Fassungen kosteten nur zusätzliches Umschalten.
	var stoffe := {}
	for seite: float in [-1.0, 1.0]:
		var wand := Node3D.new()
		wand.name = "WandLinks" if seite < 0.0 else "WandRechts"
		wurzel.add_child(wand)
		var toepfe: Dictionary = je_seite[seite]
		for teil: Array in [
			["Koerper", toepfe["koerper"], material, toepfe["koerper_farbe"]],
			["Adern", toepfe["ader"], adermaterial, toepfe["ader_farbe"]],
			["Deck", toepfe["deck"], deckmaterial, toepfe["deck_farbe"]],
			["Geroell", toepfe["geroell"], material, toepfe["geroell_farbe"]],
		]:
			var stellen: Array[Transform3D] = teil[1]
			if stellen.is_empty() or teil[2] == null:
				continue
			var farben: Array[Color] = teil[3]
			var haufen := MultiMesh.new()
			haufen.transform_format = MultiMesh.TRANSFORM_3D
			haufen.use_colors = true
			haufen.mesh = netz
			haufen.instance_count = stellen.size()
			for i in stellen.size():
				haufen.set_instance_transform(i, stellen[i])
				haufen.set_instance_color(i,
						farben[i] if i < farben.size() else Color.WHITE)

			var anzeige := MultiMeshInstance3D.new()
			anzeige.name = teil[0]
			anzeige.multimesh = haufen
			anzeige.material_override = _farbstoff(teil[2], stoffe)
			wand.add_child(anzeige)
	return wurzel


## Eigene Fassung eines Materials, die die Blockfarben durchlässt.
##
## Das gemeinsame Material aus der Materialbibliothek darf nicht verändert
## werden, es hängt an vielen anderen Stellen; deshalb eine Kopie. Das
## Zwischenlager sorgt dafür, dass zwei Töpfe mit demselben Stoff auch
## dieselbe Kopie bekommen.
static func _farbstoff(material: Material, zwischenlager: Dictionary) -> Material:
	if zwischenlager.has(material):
		return zwischenlager[material]
	var fertig: Material = material
	var stoff := material.duplicate() as BaseMaterial3D
	if stoff != null:
		stoff.vertex_color_use_as_albedo = true
		fertig = stoff
	zwischenlager[material] = fertig
	return fertig


## Farbe eines Wandblocks: dunkel am Schluchtgrund, hell an der Krone,
## dazu eine kleine Streuung je Block.
##
## Ohne das trägt jeder Würfel dasselbe Muster in derselben Helligkeit.
## Eine Wand aus hundert davon liest sich als Tapete, egal wie gut die
## Textur ist – der Blick findet keine Tiefe, weil unten und oben gleich
## hell sind. Der Verlauf macht aus der Fläche eine Schlucht.
##
## Unten geht die Farbe zusätzlich ins Kühle, oben ins Warme: Tiefer
## Schatten ist blaustichig, die Krone bekommt Sonne ab. Das ist derselbe
## Griff, mit dem Landschaftsmaler Tiefe erzeugen.
static func _wandfarbe(y: float, hoehe: float, sockel: float,
		wuerfel: RandomNumberGenerator) -> Color:
	var t := clampf((y + sockel) / maxf(hoehe + sockel, 0.001), 0.0, 1.0)
	# Unten deutlich abdunkeln, oben leicht aufhellen.
	var helligkeit := lerpf(0.63, 1.10, pow(t, 0.75))
	helligkeit *= wuerfel.randf_range(0.93, 1.07)
	var kalt := Color(0.82, 0.90, 1.06)     ## Schattenton am Grund
	var warm := Color(1.06, 1.00, 0.92)     ## Sonnenton an der Krone
	var ton := kalt.lerp(warm, t)
	return Color(ton.r * helligkeit, ton.g * helligkeit, ton.b * helligkeit)


## Langsame Welle über die Länge der Schlucht.
##
## Sie steuert, wie weit der Fels an einer Stelle vorspringt. Reiner Zufall
## je Block ergibt eine gleichmäßig raue, aber eben doch gerade Wand; erst
## eine Welle über zwanzig, dreißig Meter macht daraus Buchten und
## Strebepfeiler. Die beiden Seiten laufen versetzt, sonst zöge sich die
## Schlucht im Gleichtakt zusammen und wieder auseinander.
static func _wandwelle(s: float, seite: float, phase: float) -> float:
	var v := phase + (2.4 if seite > 0.0 else 0.0)
	return sin(s * 0.11 + v) * 0.55 + sin(s * 0.29 + v * 1.7) * 0.30


## Die Höhen, an denen die Blocklagen aneinanderstoßen – vom Fuß des
## Sockels bis zur Krone.
##
## Über dem Weg liegen `lagen` Lagen, darunter `unter` gröbere: Der Sockel
## ist meist doppelt so tief wie die Wand hoch, und mit derselben feinen
## Teilung steckte die Hälfte aller Blöcke unsichtbar unter dem Weg.
## Die Fugen werden gegeneinander versetzt, damit nicht alle Säulen auf
## derselben Linie brechen.
static func _lagengrenzen(krone: float, sockel: float, lagen: int, unter: int,
		wuerfel: RandomNumberGenerator) -> Array[float]:
	var grenzen: Array[float] = []
	for k in unter:
		grenzen.append(lerpf(-sockel, 0.0, float(k) / float(unter)))
	for k in lagen + 1:
		grenzen.append(lerpf(0.0, krone, float(k) / float(lagen)))
	for k in range(1, grenzen.size() - 1):
		var spanne := minf(grenzen[k] - grenzen[k - 1], grenzen[k + 1] - grenzen[k])
		grenzen[k] += wuerfel.randf_range(-0.3, 0.3) * spanne
	return grenzen


## Ein einzelner, frei gedrehter Brocken.
##
## Gesetzt wird er über seine INNENKANTE, nicht über seine Mitte: Wie weit
## ein gedrehter Kasten quer ausgreift, hängt von der Drehung ab. Wer
## stattdessen die Mitte würfelt, hat den Brocken entweder im Weg stehen
## oder unsichtbar im Fels versenkt. Also erst drehen, dann ausmessen,
## dann setzen.
static func _brocken(toepfe: Dictionary, topf: String, kurve: Curve3D, s: float,
		seite: float, innen: float, y: float, groesse: Vector3, dreh: float,
		streuung: float, wuerfel: RandomNumberGenerator, farbe: Color) -> void:
	var basis := Basis.from_euler(Vector3(
			wuerfel.randf_range(-streuung, streuung),
			dreh + wuerfel.randf_range(-0.9, 0.9),
			wuerfel.randf_range(-streuung, streuung))).scaled(groesse)
	var quer := innen + _halbe_quer(basis, kurve, s, seite)
	toepfe[topf].append(Transform3D(basis, punkt(kurve, s, seite * quer, y)))
	toepfe[topf + "_farbe"].append(farbe)


## Wie weit ein gedrehter Kasten von seiner Mitte aus quer zum Weg reicht:
## die Projektion seiner drei skalierten Achsen auf die Querrichtung.
static func _halbe_quer(basis: Basis, kurve: Curve3D, s: float,
		seite: float) -> float:
	var quer := _rechts(kurve, s) * seite
	return 0.5 * (absf(basis.x.dot(quer)) + absf(basis.y.dot(quer))
			+ absf(basis.z.dot(quer)))


## Eine Säule aus Blöcken an einer Stelle der Wand.
##
## `bau`: {"abstand", "hoehe", "lagen", "block", "sockel", "schritt",
##         "phase", "ader", "deck"}
##
## Die Lagen springen nach oben zurück und werden kleiner – das ergibt die
## Terrassierung, ohne dass eine Fläche gebogen werden müsste. Am Fuß
## bleibt die Wand dagegen dicht am Weg – dort ist nur eine Handbreit für
## das Geröll ausgespart. Springt sie unten weiter zurück, klafft zwischen
## Wegkante und Fels ein Graben.
##
## Nichts darf in den begehbaren Korridor ragen – die Wand hat keine
## Kollision, ein Block über dem Weg stünde also mitten in der Figur.
## Deshalb rechnet jeder Block seine Innenkante aus und wird von dort nach
## außen gesetzt, statt seine Mitte zu würfeln. Einzige Ausnahme sind die
## Überhänge, und die hängen so hoch, dass niemand an sie heranreicht.
static func _wandbloecke(toepfe: Dictionary, kurve: Curve3D, s: float,
		seite: float, wuerfel: RandomNumberGenerator, bau: Dictionary) -> void:
	var abstand: float = bau.get("abstand", 8.0)
	var hoehe: float = bau.get("hoehe", 12.0)
	var lagen: int = maxi(int(bau.get("lagen", 4)), 1)
	var block: float = bau.get("block", 3.2)
	var sockel: float = bau.get("sockel", 6.0)
	var schritt: float = bau.get("schritt", 3.0)
	var phase: float = bau.get("phase", 0.0)
	var topf: String = "ader" if bau.get("ader", false) else "koerper"
	var dreh := drehung(kurve, s)

	# Die Krone wellt sich: eine langsame Welle über die Länge, dazu ein
	# kleiner Ausschlag je Säule. Ohne Welle schneidet die Wand oben ab wie
	# mit dem Lineal, mit reinem Zufall franst sie zur Hecke aus.
	var krone := maxf(hoehe * (1.0 + _wandwelle(s * 1.6, seite, phase) * 0.08
			+ wuerfel.randf_range(-0.05, 0.04)), 1.0)
	var lagen_hoehe := krone / float(lagen)
	var unter := maxi(int(ceil(sockel / maxf(lagen_hoehe * 1.7, 0.5))), 1)
	var grenzen := _lagengrenzen(krone, sockel, lagen, unter, wuerfel)
	var gesamt := grenzen.size() - 1

	# Ein Block je Säule darf über den Weg kragen. Nur weit über Kopfhöhe:
	# Die Figur kommt im Doppelsprung knapp fünf Meter hoch, die Kamera
	# schwebt in gut vier – tiefer hinge der Fels in einem von beiden.
	var ueberhang := -1
	if wuerfel.randf() < 0.22:
		var moeglich: Array[int] = []
		for k in gesamt:
			if grenzen[k] >= 5.5:
				moeglich.append(k)
		if not moeglich.is_empty():
			ueberhang = moeglich[wuerfel.randi_range(0, moeglich.size() - 1)]

	var letzter_quer := abstand + block * 0.5
	var letzte_tiefe := block
	var letztes_oben := krone
	for k in gesamt:
		var unten := grenzen[k]
		var oben := grenzen[k + 1]
		var spanne := maxf(oben - unten, 0.2)
		var mitte_y := (unten + oben) * 0.5
		# Höher als die Lage tief ist: so greifen die Lagen ineinander und
		# es klafft keine waagerechte Fuge durch die ganze Wand.
		var hoch := spanne * wuerfel.randf_range(1.12, 1.45)
		# Anteil an der sichtbaren Wandhöhe; unter dem Weg ist er 0.
		var oberhalb := clampf(mitte_y / krone, 0.0, 1.0)
		var tiefe := block * lerpf(1.25, 0.70, oberhalb) * wuerfel.randf_range(0.85, 1.30)
		# Mindestens einen Schritt breit, sonst klafft zwischen zwei
		# Säulen ein Schlitz und man sieht durch die Wand in den Himmel.
		var breite := maxf(schritt + 0.8, block * wuerfel.randf_range(0.8, 1.35))
		var kipp := wuerfel.randf_range(-0.06, 0.06)

		# Vorsprung der Innenkante gegenüber dem Sollabstand. Am Fuß nur
		# ein Hauch, nach oben immer mehr – daher der Faktor.
		var vor := (_wandwelle(s, seite, phase) * 0.9
				+ wuerfel.randf_range(-0.2, 0.7)) * lerpf(0.3, 1.0, oberhalb) \
				+ oberhalb * block * 0.35
		# So weit darf die Innenkante höchstens einwärts. Am Fuß bleibt
		# ein Streifen frei, in den das Geröll gelegt wird: Läge der Fels
		# dort so weit vorn wie erlaubt, steckten die Brocken in ihm und
		# man sähe nur ihre Ecken.
		var innerste := lerpf(0.30, -0.1, clampf(mitte_y / 3.0, 0.0, 1.0))
		if k == ueberhang:
			vor = -wuerfel.randf_range(0.45, 1.15)
			innerste = vor
			tiefe *= wuerfel.randf_range(1.35, 1.8)
			# Der Kragen neigt sich, sonst sieht er aus wie ein Regalbrett.
			kipp = wuerfel.randf_range(0.07, 0.17) * (1.0 if wuerfel.randf() < 0.5 else -1.0)
		vor = maxf(vor, innerste)

		# Beim Kippen wandert eine Ecke einwärts – das kommt auf den
		# Abstand drauf, sonst stünde der Block doch im Weg.
		var quer := abstand + vor + tiefe * 0.5 + absf(kipp) * hoch * 0.5
		var mitte := punkt(kurve, s + wuerfel.randf_range(-0.35, 0.35),
				seite * quer, mitte_y + wuerfel.randf_range(-0.12, 0.12))
		var form := Transform3D(Basis.IDENTITY, mitte)
		form.basis = Basis.from_euler(Vector3(wuerfel.randf_range(-0.06, 0.06),
				dreh + wuerfel.randf_range(-0.22, 0.22), kipp))
		form.basis = form.basis.scaled(Vector3(tiefe, hoch, breite))
		toepfe[topf].append(form)
		toepfe[topf + "_farbe"].append(_wandfarbe(mitte.y, hoehe, sockel, wuerfel))

		# Gebrochene Kante: ein Splitter auf der Oberkante der Lage. Unter
		# dem Weg lohnt er nicht, dort sieht ihn niemand.
		if oben > -1.0 and wuerfel.randf() < 0.5:
			_splitter(toepfe, topf, kurve, s, seite, dreh, oben,
					quer - tiefe * 0.5, tiefe, breite, hoehe, sockel, wuerfel)

		letzter_quer = quer
		letzte_tiefe = tiefe
		letztes_oben = mitte_y + hoch * 0.5

	_geroell(toepfe, kurve, s, seite, dreh, abstand, hoehe, sockel, block,
			schritt, wuerfel)

	if not bau.get("deck", false):
		return
	# Die Deckschicht ist ein Saum auf der Krone, kein eigenes Stockwerk.
	#
	# Zuerst war sie die oberste Blocklage. Weil die Lagen sich zufällig
	# aufaddierten, endeten die Säulen auf sehr verschiedenen Höhen – der
	# Saum verteilte sich über die halbe Wand und die Wand sah aus wie
	# Tarnstoff. Jetzt sitzt er auf dem obersten Block, und weil die Krone
	# einer Welle folgt statt dem Zufall, liest er sich als Kante.
	var kappe := lagen_hoehe * wuerfel.randf_range(0.28, 0.5)
	var kappen_tiefe := letzte_tiefe * wuerfel.randf_range(0.7, 1.0)
	var kappen_quer := letzter_quer - letzte_tiefe * 0.5 + kappen_tiefe * 0.5 \
			+ wuerfel.randf_range(0.1, 0.4)
	var kappen_mitte := punkt(kurve, s + wuerfel.randf_range(-0.3, 0.3),
			seite * kappen_quer,
			letztes_oben - kappe * wuerfel.randf_range(0.2, 0.55))
	var kappen_form := Transform3D(Basis.IDENTITY, kappen_mitte)
	kappen_form.basis = Basis.from_euler(Vector3(wuerfel.randf_range(-0.07, 0.07),
			dreh + wuerfel.randf_range(-0.2, 0.2), wuerfel.randf_range(-0.07, 0.07)))
	kappen_form.basis = kappen_form.basis.scaled(Vector3(kappen_tiefe, kappe,
			maxf(schritt + 0.8, block * wuerfel.randf_range(0.85, 1.3))))
	toepfe["deck"].append(kappen_form)
	toepfe["deck_farbe"].append(_wandfarbe(hoehe, hoehe, sockel, wuerfel))


## Splitter auf der Oberkante einer Blocklage.
##
## Ein Stapel Quader hat lauter waagerechte Kanten in gleicher Höhe; die
## Splitter zerbrechen diese Linie. Sie bleiben hinter der Innenkante des
## Blocks, unter dem sie sitzen – der steht schon so weit einwärts, wie es
## der Weg erlaubt.
static func _splitter(toepfe: Dictionary, topf: String, kurve: Curve3D, s: float,
		seite: float, dreh: float, kante_y: float, innenkante: float,
		tiefe: float, breite: float, hoehe: float, sockel: float,
		wuerfel: RandomNumberGenerator) -> void:
	var mass := tiefe * wuerfel.randf_range(0.20, 0.46)
	var groesse := Vector3(mass * wuerfel.randf_range(0.7, 1.4),
			mass * wuerfel.randf_range(0.6, 1.3),
			mass * wuerfel.randf_range(0.7, 1.5))
	var laengs := s + wuerfel.randf_range(-breite * 0.45, breite * 0.45)
	var y := kante_y + wuerfel.randf_range(-0.45, 0.25) * groesse.y
	_brocken(toepfe, topf, kurve, laengs, seite,
			innenkante + wuerfel.randf_range(0.0, tiefe * 0.5), y, groesse,
			dreh, 0.55, wuerfel,
			_wandfarbe(punkt(kurve, laengs, 0.0, y).y, hoehe, sockel, wuerfel))


## Streu aus Brocken am Wandfuß.
##
## Ohne sie stößt die Wand in einer geraden Linie auf den Weg, und die Fuge
## liest sich als Schnitt. Die Brocken liegen halb im Fels und halb davor,
## unterschiedlich groß und frei gedreht; damit franst die Linie aus. Sie
## kommen in einen eigenen Topf und kosten für die ganze Wand deshalb nur
## einen einzigen zusätzlichen Zeichenaufruf.
##
## Weiter einwärts als der Wandfuß dürfen sie nicht: Die Wand hat keine
## Kollision, ein Brocken auf dem Weg stünde in der Figur.
static func _geroell(toepfe: Dictionary, kurve: Curve3D, s: float, seite: float,
		dreh: float, abstand: float, hoehe: float, sockel: float, block: float,
		schritt: float, wuerfel: RandomNumberGenerator) -> void:
	for i in wuerfel.randi_range(3, 5):
		var mass := block * wuerfel.randf_range(0.14, 0.34)
		if wuerfel.randf() < 0.16:
			mass *= wuerfel.randf_range(1.5, 2.2)   # gelegentlich ein Findling
		var groesse := Vector3(mass * wuerfel.randf_range(0.8, 1.5),
				mass * wuerfel.randf_range(0.55, 1.1),
				mass * wuerfel.randf_range(0.8, 1.5))
		var laengs := s + wuerfel.randf_range(-schritt * 0.5, schritt * 0.5)
		# Dicht an der Sollkante bleiben: Der Wandfuß schwankt um sie
		# herum, und was weiter nach außen rutscht, steckt im Fels und
		# ist von der Strecke aus nie zu sehen.
		var innen := abstand - 0.05 + wuerfel.randf_range(0.0, 0.15)
		# Der Schutt türmt sich an der Wand auf, statt nur auf dem Grund
		# zu liegen: Am Weg steht eine erhöhte Kante, und alles, was
		# tiefer liegt als sie, verschwindet aus der Spielkamera hinter
		# ihr. Erst was über die Kante ragt, bricht die Fuge auf.
		var y := wuerfel.randf_range(-0.3, 1.2) + groesse.y * 0.3
		# Um die Wandfarbe herum gestreut, nach beiden Seiten: Wären alle
		# Brocken dunkler, verschwänden sie im ohnehin dunklen Wandfuß.
		var ton := _wandfarbe(punkt(kurve, laengs, 0.0, y).y, hoehe, sockel, wuerfel)
		var dunkel := wuerfel.randf_range(0.84, 1.08)
		_brocken(toepfe, "geroell", kurve, laengs, seite, innen, y, groesse,
				dreh, 1.2, wuerfel,
				Color(ton.r * dunkel, ton.g * dunkel, ton.b * dunkel))


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
