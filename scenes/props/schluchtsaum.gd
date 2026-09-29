extends RefCounted
class_name Schluchtsaum
## Bewuchs an der Schluchtwand: ein Blattsaum auf der Krone, Ranken, die
## über die Kante und die Simse hängen, Wurzeln, die sich die Wand
## hinabwinden, Farne auf den Simsen und große Blätter am Wandfuß.
##
## Die Schluchtwände füllen aus der Verfolgerkamera links und rechts je ein
## Drittel des Bildes. Nackt lesen sie sich als Stapel Kisten, so gut die
## Felstextur auch sein mag – in den Vorbildern ist eine Waldschlucht
## überwachsen: Die Kante franst in Grün aus, Ranken hängen herab, und
## Wurzeln der Bäume oben greifen über den Rand in den Fels.
##
## Alles wächst genau an der Wand, die dasteht. `LevelWerkzeuge.schluchtwand`
## legt mit der Option `kronen_merken` je Säule Lagen und Krone ab; daran
## richtet sich hier jeder Punkt aus. Eine Ranke hängt, wie Schwerkraft sie
## hängen lässt: Springt der Fels darunter vor, legt sie sich über den Sims,
## springt er zurück, hängt sie frei davor.
##
## Nichts ragt in den begehbaren Korridor. Über einem Überhang enden Ranken
## und Wurzeln, statt vor ihm auf Kopfhöhe herabzuhängen, und unter
## `MINDESTHOEHE` hängt keine Ranke mehr – dort geht die Figur.
##
## Kosten: je `ABSCHNITT` Meter und Seite ein Netz Laub (Saum, Ranken,
## Farne) und eines Wurzelholz, ohne Kollision und ohne Schatten. Der des
## Laubs fiele auf die Wandkrone, die die Kamera nie sieht; jede
## Schattenstufe kostete je Netz einen weiteren Zeichenaufruf.
##
## Aufruf:
##     var wand := LevelWerkzeuge.schluchtwand(..., {"kronen_merken": true})
##     Schluchtsaum.bauen(deko, verlauf, wand.get_meta("kronen"), {...})
## `optionen`: {"saat", "laubfarbe", "saum", "ranken", "wurzeln",
##              "vorhaenge", "simse", "fuss", "blueten", "helle_blueten"}
##   saum       Blattballen je Säule auf der Krone (Vorgabe 1.6)
##   ranken     Ranken je Säule von der Kante (Vorgabe 1.6)
##   wurzeln    Anteil der Säulen, an denen eine Wurzel herabwächst (0.22)
##   vorhaenge  Anteil der Säulen mit einem Vorhang aus Luftwurzeln (0.1)
##   simse      Anteil der Simse mit Farn oder kurzer Ranke (0.55)
##   fuss       Anteil der Säulen mit einer großen Pflanze am Wandfuß (0.6)
##   blueten    wie viel blüht, 0 = nichts (Vorgabe), 1 = Tupfer in den
##              Farnen; die Blüten sind ein drittes Netz je Stück
##   helle_blueten  auch weiße und gelbe Blüten (Vorgabe aus)
##
## Je Säule darf der Eintrag in `kronen` ein "weg_rand" tragen: den
## Querabstand, bis zu dem die Pflanzen am Wandfuß höchstens reichen. Ohne
## ihn bleiben sie einen Meter vor der Wand.

## Länge der Stücke, in die das Laub geschnitten wird. Kürzer wird es mehr
## Zeichenaufrufe, länger zeichnet die Karte mehr, als im Bild ist.
const ABSCHNITT := 30.0
## Darunter hängt keine Ranke: Dort geht die Figur, und ein Blattstrang
## vor ihr läse sich als Hindernis.
const MINDESTHOEHE := 1.3
## So weit dürfen Ranken und Wurzeln unterhalb von 5 m vor den Sollabstand
## der Wand treten. Mehr wäre schon der Streifen vor der Leitwand.
const VORTRITT := 0.25
## Bis in diese Höhe über dem Weg kommt die Verfolgerkamera: 6 m über der
## Figur, im Doppelsprung 2,4 m mehr, dazu Luft. Was über dem Weg hängt
## (Ranken am Baumstamm), endet samt Blättern darüber – sonst fährt die
## Linse bei einem gewöhnlichen Sprung hindurch.
const KAMERA_FREI := 8.8
## So weit hängen die Blätter einer Ranke unter ihren Stängel.
const BLATT_HANG := 0.45

## Tönungen relativ zur Grundfarbe des Laubs (dunkles Waldgrün bis
## frisches Hellgrün). Scheitelfarben können nur abdunkeln – die
## Grundfarbe ist deshalb die hellste.
const TOENE: Array[Color] = [
	Color(0.40, 0.52, 0.54),
	Color(0.55, 0.72, 0.68),
	Color(0.55, 0.72, 0.68),
	Color(0.80, 0.90, 0.80),
	Color(1.0, 1.0, 0.94),
]


static func bauen(eltern: Node3D, kurve: Curve3D, kronen: Array,
		optionen: Dictionary = {}) -> Node3D:
	var saat: int = optionen.get("saat", 7707)
	var laubfarbe: Color = optionen.get("laubfarbe", Farben.LAUB_HELL)
	var saum: float = optionen.get("saum", 1.6)
	var ranken: float = optionen.get("ranken", 1.6)
	var wurzeln: float = optionen.get("wurzeln", 0.22)
	var vorhaenge: float = optionen.get("vorhaenge", 0.1)
	var simse: float = optionen.get("simse", 0.55)
	var fussdichte: float = optionen.get("fuss", 0.6)
	var blueten: float = optionen.get("blueten", 0.0)
	var helle: bool = optionen.get("helle_blueten", false)
	var rng := PropWerkzeug.zufall(saat)

	var wurzel := Node3D.new()
	wurzel.name = "Schluchtsaum"
	eltern.add_child(wurzel)

	# Stück -> {"laub": SurfaceTool, "holz": SurfaceTool}
	var stuecke := {}
	for eintrag in kronen:
		var e: Dictionary = eintrag
		var s: float = e["s"]
		var seite: float = e["seite"]
		var schluessel := "%d_%d" % [int(seite), int(floor(s / ABSCHNITT))]
		if not stuecke.has(schluessel):
			stuecke[schluessel] = {"laub": PropWerkzeug.bauer(),
					"holz": PropWerkzeug.bauer(), "blueten": PropWerkzeug.bauer()}
		var stueck: Dictionary = stuecke[schluessel]
		var laub: SurfaceTool = stueck["laub"]
		var holz: SurfaceTool = stueck["holz"]
		var rahmen := _rahmen(kurve, s, seite)
		if blueten > 0.0:
			rahmen["blueten"] = stueck["blueten"]
			rahmen["bluetenanteil"] = blueten
			rahmen["bluetenfarben"] = BLUETEN_HELL.size() if helle else BLUETEN.size()

		var n_saum := _anzahl(saum, rng)
		for i in n_saum:
			_saumballen(laub, rng, rahmen, e)
		# Farne, die über die Kante hängen – die Wedel zeichnen von unten
		# eine gefiederte Kontur gegen den Himmel.
		if rng.randf() < 0.45:
			var innen: float = e["innen"]
			_farn(laub, rng, _punkt(rahmen, innen + rng.randf_range(0.0, 0.3),
					float(e["oben"]) - 0.1, rng.randf_range(-1.0, 1.0)),
					rng.randf_range(0.9, 1.5), rahmen, true)
		var n_ranken := _anzahl(ranken, rng)
		for i in n_ranken:
			var oben: float = e["oben"]
			# Meist kurz, gelegentlich bis weit hinab: So entsteht kein
			# Vorhang mit gerader Unterkante.
			var laenge := rng.randf_range(1.2, 3.5)
			if rng.randf() < 0.3:
				laenge = rng.randf_range(3.5, oben - MINDESTHOEHE)
			_ranke(laub, rng, rahmen, e, e["innen"], oben, laenge,
					rng.randf_range(-1.1, 1.1))
		_simse(laub, rng, rahmen, e, simse)
		if rng.randf() < fussdichte:
			_wandfuss(laub, rng, rahmen, e)
		if rng.randf() < wurzeln:
			_wurzel(holz, rng, rahmen, e)
		if rng.randf() < vorhaenge:
			_luftwurzeln(holz, rng, rahmen, e)

	var holzstoff := wurzelholz()
	for schluessel: String in stuecke:
		var stueck: Dictionary = stuecke[schluessel]
		var laub_knoten := PropWerkzeug.mesh_knoten("Laub_" + schluessel,
				_blattnetz(stueck["laub"]),
				PropWerkzeug.mit_scheitelfarben(Materialbibliothek.laub(laubfarbe)),
				false)
		if laub_knoten != null:
			wurzel.add_child(laub_knoten)
		# Auch die Wurzeln ohne Schatten: Sie liegen dicht auf dem Fels, ihr
		# Schatten wäre ein schmaler Saum – bezahlt mit bis zu vier
		# Zeichenaufrufen je Stück. Vom Stein löst sie das helle Holz.
		var holz_knoten := PropWerkzeug.mesh_knoten("Wurzeln_" + schluessel,
				PropWerkzeug.fertig(stueck["holz"]), holzstoff, false)
		if holz_knoten != null:
			wurzel.add_child(holz_knoten)
		var bluetenbauer: SurfaceTool = stueck["blueten"]
		bluetenbauer.index()
		var bluete_knoten := PropWerkzeug.mesh_knoten("Blueten_" + schluessel,
				PropWerkzeug.fertig(bluetenbauer), bluetenstoff(), false)
		if bluete_knoten != null:
			wurzel.add_child(bluete_knoten)
	return wurzel


static var _holz: StandardMaterial3D = null
static var _bluetenstoff: StandardMaterial3D = null

## Blütenfarben: Tupfer zwischen dem Grün, wie in den Vorbildern. Kein
## Orange – das ist die Farbe der Früchte, und eine Blüte, die man für eine
## Frucht hält, ist ein kleiner Betrug. Auch kein Weiß und Gelb in der
## Schlucht: Vor dunklem Fels lasen sich helle Tupfer als Funkeln oder als
## etwas zum Aufsammeln. Die gibt es nur, wo es ohnehin hell ist
## (`helle_blueten`); `BLUETEN` sind die ersten, gedeckten Einträge.
const BLUETEN: Array[Color] = [
	Color(0.90, 0.28, 0.62),
	Color(0.98, 0.62, 0.80),
	Color(0.72, 0.56, 0.98),
]
const BLUETEN_HELL: Array[Color] = [
	Color(0.90, 0.28, 0.62),
	Color(0.98, 0.62, 0.80),
	Color(0.72, 0.56, 0.98),
	Color(0.98, 0.92, 0.45),
	Color(0.96, 0.96, 0.92),
]

## Wurzelholz, heller als das der Bibliothek: Dunkles Holz auf dunklem Fels
## verschwand im Schatten der Schlucht, die Wurzeln lasen sich als Risse.
## Eine eigene Fassung – die der Bibliothek bleibt unverändert.
static func wurzelholz() -> StandardMaterial3D:
	if _holz == null:
		_holz = Materialbibliothek.wurzel().duplicate() as StandardMaterial3D
		_holz.albedo_color = Color(1.5, 1.38, 1.22)
	return _holz


## Stoff der Blüten: Farbe aus den Scheitelfarben, ein Hauch Eigenleuchten,
## damit die Tupfer auch im Schatten der Schlucht noch Farbe haben. Nur ein
## Hauch: Stärker glommen sie wie Lämpchen, und das Auge suchte die Wand ab
## statt den Weg.
static func bluetenstoff() -> StandardMaterial3D:
	if _bluetenstoff == null:
		_bluetenstoff = StandardMaterial3D.new()
		_bluetenstoff.vertex_color_use_as_albedo = true
		_bluetenstoff.cull_mode = BaseMaterial3D.CULL_DISABLED
		_bluetenstoff.roughness = 0.75
		_bluetenstoff.emission_enabled = true
		_bluetenstoff.emission = Color(0.42, 0.36, 0.38)
		_bluetenstoff.emission_energy_multiplier = 0.15
	return _bluetenstoff


## Eine Blüte: fünf Blütenblätter um eine gelbe Mitte, zur Kamera und ins
## Licht gedreht. Nur wenn der Rahmen einen Blütensammler trägt.
static func _bluete(rahmen: Dictionary, rng: RandomNumberGenerator, p: Vector3,
		r: float) -> void:
	if not rahmen.has("blueten"):
		return
	var st: SurfaceTool = rahmen["blueten"]
	var vor: Vector3 = rahmen["laengs"]
	var hinein: Vector3 = rahmen["hinein"]
	var n := (hinein * 0.5 - vor * 0.5 + Vector3.UP * 0.8
			+ Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))).normalized()
	var a := n.cross(Vector3.UP)
	if a.length_squared() < 0.01:
		a = vor
	a = a.normalized()
	var b := n.cross(a).normalized()
	var farben: int = rahmen.get("bluetenfarben", BLUETEN.size())
	var farbe := BLUETEN_HELL[rng.randi_range(0, farben - 1)]
	var dreh := rng.randf() * TAU
	for k in 5:
		var w := dreh + TAU * float(k) / 5.0
		var richtung := a * cos(w) + b * sin(w)
		var quer := n.cross(richtung)
		PropWerkzeug.blatt(st, p, p + richtung * r * 0.5 - quer * r * 0.34,
				p + richtung * r + n * r * 0.2, p + richtung * r * 0.5 + quer * r * 0.34,
				n, farbe * 0.75, farbe)
	var mitte := Color(1.0, 0.86, 0.3)
	var m := r * 0.24
	var q := p + n * r * 0.08
	PropWerkzeug.blatt(st, q - a * m, q - b * m, q + a * m, q + b * m, n, mitte, mitte)


## Schließt einen Sammler aus Blättern und Ballen ab: erst verschmelzen,
## dann Tangenten. Blatt und Ballen schreiben jede Ecke so oft, wie
## Dreiecke an ihr hängen – beim Ballen bis zu sechsmal. Verschmolzen
## trägt das Netz jede Ecke einmal, und das spart einen guten Teil des
## Grafikspeichers, den der Bewuchs belegt.
static func _blattnetz(st: SurfaceTool) -> ArrayMesh:
	st.index()
	return PropWerkzeug.fertig_mit_tangenten(st)


## Ganzzahl mit dem Mittelwert `wert`: 1.6 heißt mal 1, mal 2.
static func _anzahl(wert: float, rng: RandomNumberGenerator) -> int:
	var ganz := int(floor(wert))
	return ganz + (1 if rng.randf() < wert - float(ganz) else 0)


## Ortsrahmen einer Säule: Mitte auf der Kurve, "hinein" zeigt von der Wand
## zur Wegmitte, "laengs" die Kurve entlang. Einmal je Säule statt je Blatt
## gerechnet – auf den paar Zentimetern, um die eine Ranke schwingt, biegt
## sich der Weg nicht.
static func _rahmen(kurve: Curve3D, s: float, seite: float) -> Dictionary:
	var mitte := LevelWerkzeuge.punkt(kurve, s)
	var laengs := LevelWerkzeuge.richtung(kurve, s)
	var rechts := laengs.cross(Vector3.UP).normalized()
	return {"mitte": mitte, "laengs": laengs, "aussen": rechts * seite,
			"hinein": -rechts * seite}


## Weltpunkt aus Rahmen, Querabstand von der Wegmitte, Höhe und Versatz
## entlang des Weges.
static func _punkt(rahmen: Dictionary, quer: float, y: float,
		laengs: float = 0.0) -> Vector3:
	var mitte: Vector3 = rahmen["mitte"]
	var aussen: Vector3 = rahmen["aussen"]
	var vor: Vector3 = rahmen["laengs"]
	return mitte + aussen * quer + Vector3.UP * y + vor * laengs


## Innenkante der Wand in dieser Höhe: die am weitesten vorspringende Lage.
## Die Lagen greifen ineinander, deshalb kann es mehrere geben.
static func wand_bei(e: Dictionary, y: float) -> float:
	var beste := INF
	for lage in e["schichten"]:
		var l: Array = lage
		var unten: float = l[0]
		var oben: float = l[1]
		if y >= unten and y <= oben:
			beste = minf(beste, float(l[2]))
	if beste == INF:
		return e["innen"]
	return beste


# ------------------------------------------------------------ Blattsaum

## Ein Blattballen auf der Krone, oft ein Stück über die Kante hinaus. Von
## unten gesehen stehen diese Ballen als dunkle, weiche Kontur gegen den
## Himmel – statt der Linealkante des obersten Blocks.
static func _saumballen(st: SurfaceTool, rng: RandomNumberGenerator,
		rahmen: Dictionary, e: Dictionary) -> void:
	var innen: float = e["innen"]
	var oben: float = e["oben"]
	var groesse := rng.randf_range(0.75, 1.35)
	var radien := Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.5, 0.8),
			rng.randf_range(0.8, 1.3)) * groesse
	var quer := innen + rng.randf_range(-0.3, 1.0)
	var mitte := _punkt(rahmen, quer, oben + rng.randf_range(-0.15, 0.3),
			rng.randf_range(-1.3, 1.3))
	var ton := TOENE[rng.randi_range(0, TOENE.size() - 1)]
	# Zur Schlucht hin geneigt: Der Ballen hängt über die Kante.
	var hinein: Vector3 = rahmen["hinein"]
	var kipp := hinein.cross(Vector3.UP).normalized() * rng.randf_range(0.1, 0.4)
	PropWerkzeug.klumpen(st, rng, mitte, radien,
			Vector3(kipp.x, rng.randf() * TAU, kipp.z), 8, 4, 0.35, false,
			Color(ton.r * 0.32, ton.g * 0.36, ton.b * 0.32), ton,
			mitte.y - radien.y, mitte.y + radien.y)


# ------------------------------------------------------------ Ranken

## Eine Ranke von `start_quer`/`start_y` abwärts. Sie hängt, wie Schwerkraft
## es will: Tritt der Fels darunter weiter vor als sie hängt, legt sie sich
## über ihn; tritt er zurück, hängt sie frei davor.
static func _ranke(st: SurfaceTool, rng: RandomNumberGenerator, rahmen: Dictionary,
		e: Dictionary, start_quer: float, start_y: float, laenge: float,
		laengs: float) -> void:
	var abstand: float = e["abstand"]
	var weg := _haengeweg(e, start_quer - 0.08, start_y - 0.05, laenge,
			0.08, abstand)
	if weg.size() < 2:
		return
	var ton := TOENE[rng.randi_range(2, TOENE.size() - 1)]
	var schwung := rng.randf_range(0.05, 0.18)
	var takt := rng.randf_range(1.2, 2.4)
	var phase := rng.randf() * TAU
	var hinein: Vector3 = rahmen["hinein"]
	var vor: Vector3 = rahmen["laengs"]
	var groesse := rng.randf_range(0.8, 1.15)

	# Blätter in festem Abstand entlang des Weges, abwechselnd links und
	# rechts. Kein Stängel: Bei dem Abstand liest sich die Blattkette als
	# Ranke, und ein Stängel wäre eine Handvoll Dreiecke je Blatt mehr.
	var gesamt := 0.0
	for i in weg.size() - 1:
		gesamt += weg[i].distance_to(weg[i + 1])
	var abstand_blatt := 0.2 * groesse
	var t := 0.0
	var links := true
	while t < gesamt:
		var anteil := t / maxf(gesamt, 0.001)
		var q_y := _auf_weg(weg, t)
		var seit := laengs + sin(q_y.y * takt + phase) * schwung
		var p := _punkt(rahmen, q_y.x, q_y.y, seit)
		_blatt_an(st, rng, p, links, anteil, ton, groesse, vor, hinein)
		links = not links
		t += abstand_blatt * rng.randf_range(0.8, 1.2)


## Eine Ranke, die frei von `start` herabhängt – unter einem Wurzeltor oder
## einem umgestürzten Stamm, wo keine Wand ist, an die sie sich legen kann.
static func _freie_ranke(st: SurfaceTool, rng: RandomNumberGenerator,
		start: Vector3, laenge: float, vor: Vector3, hinein: Vector3) -> void:
	var ton := TOENE[rng.randi_range(2, TOENE.size() - 1)]
	var schwung := rng.randf_range(0.05, 0.15)
	var takt := rng.randf_range(1.2, 2.4)
	var phase := rng.randf() * TAU
	var groesse := rng.randf_range(0.8, 1.1)
	var t := 0.0
	var links := true
	while t < laenge:
		var p := start + Vector3.DOWN * t + vor * sin(t * takt + phase) * schwung
		_blatt_an(st, rng, p, links, t / laenge, ton, groesse, vor, hinein)
		links = not links
		t += 0.2 * groesse * rng.randf_range(0.8, 1.2)


## Ein Blatt einer Ranke bei `p`, abwechselnd nach links und rechts
## abstehend, `anteil` = wie weit unten an der Ranke (kleiner nach unten).
static func _blatt_an(st: SurfaceTool, rng: RandomNumberGenerator, p: Vector3,
		links: bool, anteil: float, ton: Color, groesse: float, vor: Vector3,
		hinein: Vector3) -> void:
	var richtung := (vor * (1.0 if links else -1.0) * rng.randf_range(0.5, 0.9)
			+ Vector3.DOWN * rng.randf_range(0.5, 0.9)
			+ hinein * rng.randf_range(0.15, 0.45)).normalized()
	var lang := rng.randf_range(0.26, 0.4) * groesse * lerpf(1.0, 0.7, anteil)
	var breit := lang * rng.randf_range(0.3, 0.4)
	# Die Blattfläche schaut schräg zurück zur Kamera – die blickt den
	# Weg entlang und sähe flach an der Wand liegende Blätter nur von der
	# Kante – und dazu nach oben ins Licht: Senkrecht hängende Blätter
	# standen als schwarze Rauten auf dem Fels.
	var zur_kamera := (hinein * 0.45 - vor * 0.55 + Vector3.UP * 0.7).normalized()
	var normale := (zur_kamera - richtung * zur_kamera.dot(richtung)).normalized()
	var quer_achse := richtung.cross(normale).normalized()
	var hell := lerpf(1.0, 0.8, anteil) * rng.randf_range(0.85, 1.0)
	var fuss := Color(ton.r * 0.5, ton.g * 0.56, ton.b * 0.5) * hell
	var spitze := Color(ton.r, ton.g, ton.b) * hell
	# Spitzoval statt Raute: schmal am Stiel, am breitesten vor der Mitte,
	# dann zur Spitze auslaufend.
	var b1 := p + richtung * lang * 0.3
	var b2 := p + richtung * lang * 0.62
	var tip := p + richtung * lang
	PropWerkzeug.blatt(st, p, b1 - quer_achse * breit * 0.85,
			b2 - quer_achse * breit, tip, normale, fuss, spitze)
	PropWerkzeug.blatt(st, p, tip, b2 + quer_achse * breit,
			b1 + quer_achse * breit * 0.85, normale, fuss, spitze)


## Der Weg einer hängenden Ranke oder Wurzel als Folge von (quer, y).
## `luft` hält sie so weit vor der Felsfläche. Endet vorzeitig, wo ein
## Überhang sie tiefer als 5 m vor den Sollabstand drücken würde, und nie
## unter `MINDESTHOEHE`.
static func _haengeweg(e: Dictionary, quer: float, y: float, laenge: float,
		luft: float, abstand: float) -> PackedVector2Array:
	var weg := PackedVector2Array()
	var q := minf(quer, wand_bei(e, y) - luft)
	weg.append(Vector2(q, y))
	var ende := maxf(y - laenge, MINDESTHOEHE)
	var schritt := 0.35
	var h := y
	while h > ende:
		h = maxf(h - schritt, ende)
		q = minf(q, wand_bei(e, h) - luft)
		if h < 5.0 and q < abstand - VORTRITT:
			break
		weg.append(Vector2(q, h))
	return weg


## Punkt in `t` Metern Weglänge.
static func _auf_weg(weg: PackedVector2Array, t: float) -> Vector2:
	var rest := t
	for i in weg.size() - 1:
		var a := weg[i]
		var b := weg[i + 1]
		var l := a.distance_to(b)
		if rest <= l:
			return a.lerp(b, rest / maxf(l, 0.0001))
		rest -= l
	return weg[weg.size() - 1]


# ------------------------------------------------------------ Simse

## Auf den Simsen – wo eine Lage weiter zurückspringt als die darunter –
## sammelt sich Erde. Dort sitzt ein Busch, oder von der Simskante hängt
## eine kurze Ranke.
static func _simse(st: SurfaceTool, rng: RandomNumberGenerator, rahmen: Dictionary,
		e: Dictionary, anteil: float) -> void:
	var schichten: Array = e["schichten"]
	var krone: float = e["oben"]
	for k in schichten.size() - 1:
		var unter: Array = schichten[k]
		var ueber: Array = schichten[k + 1]
		var y: float = unter[1]
		var innen: float = unter[2]
		var breite: float = float(ueber[2]) - innen
		if breite < 0.35 or y < 0.8 or y > krone - 1.0 or bool(unter[3]):
			continue
		if rng.randf() > anteil:
			continue
		# Kein Busch aus Ballen: Auf dem schmalen Sims las sich der als
		# grünes Kissen. Ein Farn dagegen ist aus jeder Richtung ein Farn.
		if rng.randf() < 0.65:
			# Hoch oben sieht man die Farne nur von Weitem: Dort genügen
			# vier Stufen je Wedel statt sechs.
			_farn(st, rng, _punkt(rahmen, innen + breite * 0.45, y,
					rng.randf_range(-1.0, 1.0)), rng.randf_range(0.8, 1.4), rahmen,
					false, 4 if y > 4.0 else 6)
		else:
			_ranke(st, rng, rahmen, e, innen, y, rng.randf_range(0.8, 2.2),
					rng.randf_range(-1.0, 1.0))


# ------------------------------------------------------------ Wandfuß

## Große Pflanzen am Wandfuß, zwischen Wegkante und Fels: Farne und
## Großblätter, die sich über die Kante zum Weg neigen. Sie stehen links und
## rechts im unteren Bilddrittel – genau der Rahmen aus großen Blättern, den
## die Vorbilder um den Weg legen.
##
## Nur wo die Wand dicht am Weg steht (`abstand` unter 8 m): Weiter draußen
## stünden sie über dem Abgrund.
##
## Sie neigen sich zum Weg, aber nie über ihn: Ohne Kollision liefe die
## Figur am Rand sonst durch ein Blatt, und die Blätter verdeckten Füße
## und Wegkante. Wie weit sie reichen dürfen, sagt "weg_rand" der Säule;
## die Größe wird so gewählt, dass die Spitze davor endet.
static func _wandfuss(st: SurfaceTool, rng: RandomNumberGenerator,
		rahmen: Dictionary, e: Dictionary) -> void:
	var abstand: float = e["abstand"]
	if abstand > 8.0:
		return
	var quer := abstand + rng.randf_range(0.0, 0.25)
	var reichweite := quer - float(e.get("weg_rand", abstand - 1.0))
	var fuss := _punkt(rahmen, quer,
			rng.randf_range(0.2, 0.5), rng.randf_range(-1.1, 1.1))
	var farn := rng.randf() < 0.6
	var groesse := rng.randf_range(1.2, 1.9) if farn else rng.randf_range(0.7, 1.1)
	# Größe -> Reichweite: Ein Farnwedel reicht gut seine Länge weit, ein
	# Großblatt mit Stiel und hängender Spreite das Anderthalbfache.
	groesse = minf(groesse, reichweite / (1.1 if farn else 1.6))
	if groesse < 0.45:
		return
	if farn:
		_farn(st, rng, fuss, groesse, rahmen, false)
	else:
		_grossblatt(st, rng, fuss, groesse, rahmen)


## Eine Staude mit wenigen großen, herzförmigen Blättern an langen Stielen
## – das tropische Gegenstück zum Farn, und aus der Kamera die größte
## einzelne Blattform im Bild.
static func _grossblatt(st: SurfaceTool, rng: RandomNumberGenerator, fuss: Vector3,
		groesse: float, rahmen: Dictionary) -> void:
	var hinein: Vector3 = rahmen["hinein"]
	var vor: Vector3 = rahmen["laengs"]
	var ton := TOENE[rng.randi_range(2, TOENE.size() - 1)]
	# Nicht zu dunkel am Stiel, und wenige schmale Blätter statt vieler
	# breiter: Nah an der Kamera standen sie sonst als große schwarze
	# Dreiecke in den unteren Bildecken.
	var dunkel := Color(ton.r * 0.6, ton.g * 0.66, ton.b * 0.6)
	for i in rng.randi_range(2, 4):
		var winkel := rng.randf_range(-1.3, 1.3)
		var flach := (hinein * cos(winkel) + vor * sin(winkel)).normalized()
		# Stiel: schräg hinauf, dann hängt das Blatt über
		var stiel_ende := fuss + flach * groesse * rng.randf_range(0.35, 0.6) \
				+ Vector3.UP * groesse * rng.randf_range(0.55, 0.9)
		var quer := flach.cross(Vector3.UP).normalized()
		PropWerkzeug.blatt(st, fuss - quer * 0.025, stiel_ende - quer * 0.02,
				stiel_ende + quer * 0.02, fuss + quer * 0.025,
				(flach.cross(quer)).normalized(), dunkel, ton * 0.8)
		# Blattspreite: zwei Hälften, an der Mittelrippe leicht geknickt,
		# vorn zur Spitze hin hängend.
		var lang := groesse * rng.randf_range(0.7, 1.0)
		var breit := lang * rng.randf_range(0.26, 0.34)
		var mitte := stiel_ende + flach * lang * 0.5 + Vector3.DOWN * lang * 0.12
		var spitze := stiel_ende + flach * lang + Vector3.DOWN * lang * 0.45
		var hinten := stiel_ende - flach * lang * 0.12 + Vector3.UP * lang * 0.05
		for seite: float in [-1.0, 1.0]:
			var rand := mitte + quer * breit * seite + Vector3.UP * breit * 0.25
			var n := (rand - stiel_ende).cross(spitze - stiel_ende).normalized()
			if n.y < 0.0:
				n = -n
			PropWerkzeug.blatt(st, hinten, stiel_ende + quer * breit * 0.6 * seite,
					rand, mitte, n, dunkel, ton)
			PropWerkzeug.blatt(st, mitte, rand,
					spitze + quer * breit * 0.1 * seite, spitze, n, ton, ton * 0.85)


# ------------------------------------------------------------ Farne

## Ein Farnbusch aus gefiederten Wedeln. Auf einem Sims stehen die Wedel
## auf und biegen sich zur Schlucht hin über; an der Kante (`haengend`)
## wachsen sie hinaus und fallen nach unten.
##
## Gebaut wie der Farn im `Kleinzeug`, nur ohne eigenen Knoten und
## Windtakt: Hier stehen Hunderte, und alle landen im selben Netz.
static func _farn(st: SurfaceTool, rng: RandomNumberGenerator, fuss: Vector3,
		groesse: float, rahmen: Dictionary, haengend: bool, stufen: int = 6) -> void:
	var hinein: Vector3 = rahmen["hinein"]
	var vor: Vector3 = rahmen["laengs"]
	var ton := TOENE[rng.randi_range(1, TOENE.size() - 1)]
	var wedel := rng.randi_range(6, 9)
	for i in wedel:
		# Fächer zur Schlucht hin – in die Wand hinein wächst nichts.
		var winkel := lerpf(-1.7, 1.7, (float(i) + rng.randf()) / float(wedel))
		var flach := hinein * cos(winkel) + vor * sin(winkel)
		var richtung: Vector3
		if haengend:
			richtung = flach * rng.randf_range(0.8, 1.2) \
					+ Vector3.UP * rng.randf_range(-0.1, 0.4)
		else:
			richtung = flach * rng.randf_range(0.5, 0.9) \
					+ Vector3.UP * rng.randf_range(0.7, 1.3)
		_wedel(st, fuss, richtung.normalized(),
				groesse * rng.randf_range(0.7, 1.1), ton,
				0.34 if haengend else 0.22, stufen)
	# Zwischen den Wedeln blüht es manchmal.
	if not haengend and rahmen.has("blueten") \
			and rng.randf() < float(rahmen["bluetenanteil"]) * 0.45:
		for i in rng.randi_range(1, 3):
			var auf := fuss + (hinein * rng.randf_range(0.1, 0.4)
					+ vor * rng.randf_range(-0.35, 0.35)) * groesse \
					+ Vector3.UP * groesse * rng.randf_range(0.2, 0.45)
			_bluete(rahmen, rng, auf, rng.randf_range(0.09, 0.15))


## Ein Wedel: Mittelrippe mit paarweisen Fiederblättern, die zur Spitze hin
## kürzer werden. `schwere` biegt ihn je Stufe nach unten (gemessen an
## sechs Stufen – mit weniger biegt jede Stufe entsprechend mehr, die Form
## bleibt dieselbe).
static func _wedel(st: SurfaceTool, fuss: Vector3, richtung: Vector3,
		laenge: float, ton: Color, schwere: float, stufen: int = 6) -> void:
	var schritt := laenge / float(stufen)
	schwere *= 6.0 / float(stufen)
	var quer := richtung.cross(Vector3.UP)
	if quer.length_squared() < 0.01:
		quer = Vector3.RIGHT
	quer = quer.normalized()
	var pos := fuss
	var dir := richtung
	for j in stufen:
		var t0 := float(j) / float(stufen)
		var t1 := float(j + 1) / float(stufen)
		var naechster := pos + dir * schritt
		var normale := dir.cross(quer).normalized()
		if normale.y < 0.0:
			normale = -normale
		var f0 := Color(ton.r * lerpf(0.45, 0.95, t0), ton.g * lerpf(0.5, 1.0, t0),
				ton.b * lerpf(0.45, 0.95, t0))
		var f1 := Color(ton.r * lerpf(0.45, 0.95, t1), ton.g * lerpf(0.5, 1.0, t1),
				ton.b * lerpf(0.45, 0.95, t1))
		var r0 := laenge * 0.02 * (1.0 - t0 * 0.6)
		var r1 := laenge * 0.02 * (1.0 - t1 * 0.6)
		PropWerkzeug.blatt(st, pos - quer * r0, naechster - quer * r1,
				naechster + quer * r1, pos + quer * r0, normale, f0, f1)
		var fie0 := laenge * 0.4 * sin(PI * clampf(t0 * 1.15, 0.0, 1.0))
		var fie1 := laenge * 0.4 * sin(PI * clampf(t1 * 1.15, 0.0, 1.0))
		var senke := Vector3.DOWN * fie0 * 0.28
		for seite: float in [-1.0, 1.0]:
			PropWerkzeug.blatt(st,
					pos + quer * (r0 * seite),
					naechster + quer * (r1 * seite),
					naechster + quer * ((r1 + fie1 * 0.4) * seite) + senke,
					pos + quer * ((r0 + fie0) * seite) - dir * schritt * 0.12 + senke,
					normale, f0, f1)
		pos = naechster
		dir = (dir + Vector3.DOWN * schwere).normalized()


# ------------------------------------------------------------ Wurzeln

## Ein Vorhang aus dünnen Luftwurzeln, die von der Krone fast gerade
## herabfallen – wie unter einer Würgefeige. Gegen den Fels lesen sie sich
## als feine senkrechte Striche und geben der Schlucht ihren Namen.
static func _luftwurzeln(st: SurfaceTool, rng: RandomNumberGenerator,
		rahmen: Dictionary, e: Dictionary) -> void:
	var innen: float = e["innen"]
	var oben: float = e["oben"]
	var abstand: float = e["abstand"]
	var anzahl := rng.randi_range(4, 8)
	var breite := rng.randf_range(1.0, 2.2)
	for i in anzahl:
		var laengs := lerpf(-breite * 0.5, breite * 0.5, float(i) / float(anzahl - 1)) \
				+ rng.randf_range(-0.1, 0.1)
		var r := rng.randf_range(0.035, 0.08)
		var weg := _haengeweg(e, innen - r, oben - 0.1,
				rng.randf_range(2.5, oben - 1.0), r * 1.2, abstand)
		if weg.size() < 2:
			continue
		weg.insert(0, Vector2(innen + 0.5, oben + 0.05))
		var takt := rng.randf_range(0.8, 1.6)
		var phase := rng.randf() * TAU
		var punkte := PackedVector3Array()
		for p in weg:
			punkte.append(_punkt(rahmen, p.x, p.y,
					laengs + sin(p.y * takt + phase) * 0.06))
		_strang(st, punkte, r, r * 0.5, 5)



## Eine Wurzel, die von der Krone über die Kante greift und sich die Wand
## hinabwindet, oft bis in das Geröll am Fuß. Unterwegs zweigen ein, zwei
## dünnere Wurzeln ab.
static func _wurzel(st: SurfaceTool, rng: RandomNumberGenerator, rahmen: Dictionary,
		e: Dictionary) -> void:
	var innen: float = e["innen"]
	var oben: float = e["oben"]
	var abstand: float = e["abstand"]
	var dick := rng.randf_range(0.26, 0.45)
	var ziel := rng.randf_range(0.2, oben * 0.45)
	var weg := _haengeweg(e, innen - dick * 0.4, oben - 0.2, oben - ziel,
			dick * 0.35, abstand)
	if weg.size() < 3:
		return
	# Anlauf oben auf der Krone: Die Wurzel kommt von einem Baum dahinter.
	weg.insert(0, Vector2(innen + 1.4, oben + 0.1))
	var schwung := rng.randf_range(0.3, 0.6)
	var takt := rng.randf_range(1.0, 1.7)
	var phase := rng.randf() * TAU
	var laengs := rng.randf_range(-0.8, 0.8)
	var punkte := PackedVector3Array()
	for i in weg.size():
		var p := weg[i]
		punkte.append(_punkt(rahmen, p.x, p.y, laengs + sin(p.y * takt + phase) * schwung))
	_strang(st, punkte, dick, dick * 0.35)

	# Abzweige: dünner, schräg zur Seite, kurz
	for i in rng.randi_range(1, 2):
		var ab := rng.randi_range(2, maxi(punkte.size() - 3, 2))
		if ab >= punkte.size():
			continue
		var start := punkte[ab]
		var seitwaerts: Vector3 = rahmen["laengs"]
		seitwaerts *= 1.0 if rng.randf() < 0.5 else -1.0
		var ast := PackedVector3Array()
		var anzahl := rng.randi_range(3, 5)
		var hinein: Vector3 = rahmen["hinein"]
		for j in anzahl:
			var t := float(j) / float(anzahl - 1)
			ast.append(start + seitwaerts * t * rng.randf_range(1.0, 1.6)
					+ Vector3.DOWN * t * rng.randf_range(0.6, 1.2)
					+ hinein * 0.05 * sin(t * PI))
		var r := lerpf(dick, dick * 0.35, float(ab) / float(punkte.size())) * 0.55
		_strang(st, ast, r, r * 0.3)


## Kegelstümpfe entlang eines Punktzugs, dick am Anfang, dünn am Ende.
static func _strang(st: SurfaceTool, punkte: PackedVector3Array, r0: float,
		r1: float, seiten: int = 7) -> void:
	var n := punkte.size()
	for i in n - 1:
		var a := punkte[i]
		var b := punkte[i + 1]
		var l := a.distance_to(b)
		if l < 0.01:
			continue
		var ra := lerpf(r0, r1, float(i) / float(n - 1))
		var rb := lerpf(r0, r1, float(i + 1) / float(n - 1))
		# Etwas länger als der Abstand, damit an den Knicken keine Lücke klafft
		PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(ra, rb, l * 1.12, seiten, false),
				PropWerkzeug.ausrichten(a, b))


# ------------------------------------------------------------ Überbauten

## Ein Tor aus ineinander gewundenen Wurzeln quer über der Schlucht, von
## Wand zu Wand. An den Abschnittswechseln gesetzt, gibt es dem Weg einen
## Takt – wie die Eisbögen im Frostgrat.
##
## Die Füße stecken auf `fuss` Metern in den Wänden, der Scheitel liegt auf
## `scheitel`: hoch über Doppelsprung und Kamera. Wie `LevelWerkzeuge.
## torbogen` trägt es Sichtkörper auf der Ebene SICHTSPERRE, damit die
## Verfolgerkamera nie in die Wurzeln fährt; der Spieler bemerkt sie nicht.
## Sie umfassen die ganzen Stränge, nicht nur die Bogenlinie: Die winden
## sich bis 1,25 m um sie herum, und die Kamera (6 m über dem Weg, im
## Doppelsprung 8,4 m) steckte sonst mitten darin.
static func wurzeltor(eltern: Node3D, kurve: Curve3D, strecke: float,
		abstand: float, saat: int, fuss: float = 3.2,
		scheitel: float = 9.2) -> Node3D:
	var rng := PropWerkzeug.zufall(saat)
	var tor := Node3D.new()
	tor.name = "Wurzeltor"
	eltern.add_child(tor)
	var mitte := LevelWerkzeuge.punkt(kurve, strecke)
	var vor := LevelWerkzeuge.richtung(kurve, strecke)
	var rechts := vor.cross(Vector3.UP).normalized()
	var holz := PropWerkzeug.bauer()
	var laub := PropWerkzeug.bauer()
	var weite := abstand + 0.8

	# Drei Stränge winden sich um die Bogenlinie, jeder in zwei Hälften
	# von den Füßen zum Scheitel: dick in der Wand, dünn im Scheitel.
	for strang in 3:
		var phase := TAU * float(strang) / 3.0 + rng.randf_range(-0.3, 0.3)
		var windung := rng.randf_range(2.2, 3.2)
		# Unterschiedlich dick und weiter auseinander: Eng und gleich stark
		# verschmolzen die drei zu einem glatten Rohr, und das Tor las sich
		# von Weitem als Steinbogen.
		var r := rng.randf_range(0.2, 0.42)
		var aus := rng.randf_range(0.45, 0.6)
		for haelfte: float in [-1.0, 1.0]:
			var punkte := PackedVector3Array()
			for i in 13:
				var t := haelfte * lerpf(PI * 0.5 + 0.1, 0.0, float(i) / 12.0)
				var bogen := mitte + rechts * sin(t) * weite \
						+ Vector3.UP * (fuss + (scheitel - fuss) * cos(t))
				var tangente := (rechts * cos(t) * weite
						- Vector3.UP * (scheitel - fuss) * sin(t)).normalized()
				var normale := tangente.cross(vor).normalized()
				var w := phase + t * windung
				punkte.append(bogen + (normale * cos(w) + vor * sin(w)) * aus)
			_strang(holz, punkte, r * 1.5, r * 0.75, 7)

	# Bewuchs obenauf. Freie Ranken hängen hier keine: Unter dem Scheitel
	# fährt die Kamera durch, und jede Ranke, die tiefer als die Stränge
	# reicht, hing ihr schon bei einem gewöhnlichen Sprung ins Bild.
	for i in 7:
		var t := rng.randf_range(-0.9, 0.9)
		var auf := mitte + rechts * sin(t) * weite \
				+ Vector3.UP * (fuss + (scheitel - fuss) * cos(t) + 0.35)
		var g := rng.randf_range(0.5, 0.95)
		var ton := TOENE[rng.randi_range(0, TOENE.size() - 1)]
		PropWerkzeug.klumpen(laub, rng, auf + vor * rng.randf_range(-0.4, 0.4),
				Vector3(g * 1.2, g * 0.6, g), Vector3(0.0, rng.randf() * TAU, 0.0),
				8, 4, 0.35, false, Color(ton.r * 0.32, ton.g * 0.36, ton.b * 0.32),
				ton, auf.y - g * 0.6, auf.y + g * 0.6)

	_knoten(tor, "Holz", PropWerkzeug.fertig(holz), wurzelholz(), true)
	_knoten(tor, "Laub", _blattnetz(laub),
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.laub(Farben.LAUB_HELL)),
			false)

	# Sichtkörper entlang der Bogenlinie.
	var sperre := StaticBody3D.new()
	sperre.name = "Sichtsperre"
	sperre.collision_layer = LevelWerkzeuge.SICHTSPERRE
	sperre.collision_mask = 0
	tor.add_child(sperre)
	const STUECKE := 12
	for i in STUECKE:
		var t0 := lerpf(-PI * 0.5, PI * 0.5, float(i) / float(STUECKE))
		var t1 := lerpf(-PI * 0.5, PI * 0.5, float(i + 1) / float(STUECKE))
		var a := mitte + rechts * sin(t0) * weite + Vector3.UP * (fuss + (scheitel - fuss) * cos(t0))
		var b := mitte + rechts * sin(t1) * weite + Vector3.UP * (fuss + (scheitel - fuss) * cos(t1))
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		# Strang: bis 0,6 m neben der Linie, Radius bis 0,63 m – 2,7 m Kasten.
		# Nur oben, wo die Kamera hinkommt; an den Füßen stünde der dicke
		# Kasten dem Kamerastrahl einer Figur an der Wand im Weg.
		var dick := 2.7 if minf(a.y, b.y) - mitte.y > 6.0 else 1.1
		kasten.size = Vector3(dick, dick, a.distance_to(b) + 0.2)
		form.shape = kasten
		form.transform = PropWerkzeug.ausrichten_z(a, b)
		sperre.add_child(form)
	return tor


## Ein umgestürzter Baumstamm, der hoch oben von Krone zu Krone über der
## Schlucht liegt. `a` und `b` sind die Auflagepunkte (Welt) der Achse.
## Moos und Farne obenauf, Ranken hängen herab – samt Blättern nie tiefer
## als `tiefste` (Weltkoordinate), damit sie über Figur und Kamera bleiben
## (dafür `KAMERA_FREI` über dem Weg).
static func baumstamm(eltern: Node3D, a: Vector3, b: Vector3, dicke: float,
		tiefste: float, saat: int) -> Node3D:
	var rng := PropWerkzeug.zufall(saat)
	var stamm := Node3D.new()
	stamm.name = "Baumstamm"
	eltern.add_child(stamm)
	var holz := PropWerkzeug.bauer()
	var laub := PropWerkzeug.bauer()
	var achse := (b - a).normalized()
	var quer := achse.cross(Vector3.UP).normalized()

	# Leicht durchhängend, am Wurzelende dicker.
	var punkte := PackedVector3Array()
	for i in 9:
		var t := float(i) / 8.0
		punkte.append(a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * 0.35
				+ quer * sin(t * PI * 2.0) * 0.15)
	_strang(holz, punkte, dicke * 1.15, dicke * 0.8, 10)
	# Abgebrochene Äste
	for i in rng.randi_range(3, 5):
		var t := rng.randf_range(0.15, 0.85)
		var auf := a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * 0.35
		var raus := (quer * (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.4, 1.0)
				+ Vector3.UP * rng.randf_range(0.2, 0.9) + achse * rng.randf_range(-0.4, 0.4)).normalized()
		var ende := auf + raus * (dicke + rng.randf_range(0.6, 1.4))
		PropWerkzeug.anfuegen(holz, PropWerkzeug.stumpf(dicke * 0.3, dicke * 0.16,
				auf.distance_to(ende), 6, true), PropWerkzeug.ausrichten(auf, ende))
	# Moosbuckel und Farne auf dem Rücken
	for i in 9:
		var t := rng.randf_range(0.05, 0.95)
		var auf := a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * 0.35 + Vector3.UP * dicke * 0.85
		var ton := TOENE[rng.randi_range(0, TOENE.size() - 1)]
		var g := rng.randf_range(0.4, 0.8)
		PropWerkzeug.klumpen(laub, rng, auf, Vector3(g * 1.3, g * 0.45, g),
				Vector3(0.0, rng.randf() * TAU, 0.0), 8, 3, 0.3, false,
				Color(ton.r * 0.35, ton.g * 0.4, ton.b * 0.35), ton,
				auf.y - g * 0.45, auf.y + g * 0.45)
	# Ranken von der Unterseite
	for i in 10:
		var t := rng.randf_range(0.1, 0.9)
		var unter := a.lerp(b, t) + Vector3.DOWN * (sin(t * PI) * 0.35 + dicke * 0.8)
		var laenge := minf(rng.randf_range(1.0, 3.4), unter.y - tiefste - BLATT_HANG)
		if laenge < 0.5:
			continue
		_freie_ranke(laub, rng, unter + quer * rng.randf_range(-0.3, 0.3), laenge,
				achse, quer)

	_knoten(stamm, "Holz", PropWerkzeug.fertig(holz), Materialbibliothek.rinde(), true)
	_knoten(stamm, "Laub", _blattnetz(laub),
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.laub(Farben.LAUB_HELL)),
			false)
	return stamm


## Ein Blätterdach aus vielen Bäumen in zwei Netzen: Kronen und Stämme.
##
## Für Wald, auf den man von oben schaut – unter dem Grat der Baumkronen
## und im Tal am Ende. Dort sieht man Wipfel, keine einzelnen Bäume, und
## ein `Baum` je Wipfel kostete zwei Zeichenaufrufe und einen eigenen
## Windtakt. Hier ist das ganze Dach einer.
##
## `baeume`: [{"fuss": Vector3 (Welt), "hoehe": float, "breite": float}]
## Der Wipfel liegt auf `fuss.y + hoehe`, die Krone reicht `breite` Meter
## zur Seite.
static func blaetterdach(eltern: Node3D, baeume: Array, saat: int,
		laubfarbe: Color = Farben.LAUB_HELL) -> Node3D:
	var rng := PropWerkzeug.zufall(saat)
	var dach := Node3D.new()
	dach.name = "Blaetterdach"
	eltern.add_child(dach)
	var holz := PropWerkzeug.bauer()
	var laub := PropWerkzeug.bauer()
	for eintrag in baeume:
		var b: Dictionary = eintrag
		var fuss: Vector3 = b["fuss"]
		var hoehe: float = b["hoehe"]
		var breite: float = b["breite"]
		var wipfel := fuss + Vector3.UP * hoehe
		var mitte := wipfel + Vector3.DOWN * breite * 0.55
		# Der Stamm reicht bis in die Krone hinein.
		var r := 0.14 + hoehe * 0.022
		PropWerkzeug.anfuegen(holz, PropWerkzeug.stumpf(r * 1.5, r * 0.6,
				mitte.y - fuss.y, 7, false),
				PropWerkzeug.ort(fuss + Vector3.UP * (mitte.y - fuss.y) * 0.5))
		# Ballen in einer flachen Halbkugel, die obersten hell, die unteren
		# im Schatten der Krone dunkel – derselbe Verlauf wie beim `Baum`.
		var ton := TOENE[rng.randi_range(0, TOENE.size() - 1)]
		var unten := Color(ton.r * 0.3, ton.g * 0.34, ton.b * 0.3)
		var anzahl := rng.randi_range(6, 9)
		var drall := rng.randf() * TAU
		for i in anzahl:
			var t := float(i) / float(anzahl - 1)
			var winkel := drall + TAU * 0.618 * float(i)
			var weite := breite * lerpf(0.62, 0.1, t) * rng.randf_range(0.7, 1.1)
			var ball := breite * lerpf(0.5, 0.42, t) * rng.randf_range(0.85, 1.15)
			var ort := mitte + Vector3(cos(winkel) * weite,
					lerpf(-breite * 0.2, breite * 0.4, t), sin(winkel) * weite)
			PropWerkzeug.klumpen(laub, rng, ort,
					Vector3(ball * rng.randf_range(1.0, 1.25), ball * rng.randf_range(0.7, 0.9),
							ball * rng.randf_range(1.0, 1.25)),
					Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, 0.0),
					9, 5, 0.3, false, unten, ton, mitte.y - breite * 0.75, wipfel.y)
	_knoten(dach, "Kronen", _blattnetz(laub),
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.laub(laubfarbe)), false)
	_knoten(dach, "Staemme", PropWerkzeug.fertig(holz), Materialbibliothek.rinde(), false)
	return dach


static func _knoten(eltern: Node3D, bezeichnung: String, netz: Mesh,
		material: Material, schatten: bool) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung, netz, material, schatten)
	if knoten != null:
		eltern.add_child(knoten)
