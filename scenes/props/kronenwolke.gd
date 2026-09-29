extends RefCounted
class_name Kronenwolke
## Baumkrone als weiche Wolke mit gebrochenem Umriss – das Gegenteil der
## glatten Blattballen, die sich aus der Kamera als grüne Kugeln lasen.
##
## Aufbau (gemessen 1,9–2,4k Dreiecke bei 3 m Radius, 0,6k bei 1,2 m, die
## Fernfassung 0,4k; Grenze 3k):
## * 5–9 **verrauschte Ikosphären**, verschmolzen zu einem Netz. Was eine
##   Kugel ganz in einer anderen verbirgt, fällt weg – das spart Dreiecke
##   und Überzeichnen.
## * **Normalen** zu 70 % zur Kronenmitte gebogen: Die Krone schattiert wie
##   eine Wolke im Ganzen, die Buckel bleiben nur als sanfte Stufen. So liest
##   sich eine Krone, nicht ein Haufen Kugeln. Dazu ein Zittern je Ecke (das
##   Licht bricht in Büschel) und ein Zug nach oben: Die Unterseite fängt
##   Himmelslicht, statt als schwarze Scheibe unter dem Baum zu hängen.
## * **Scheitelfarbe**: innen und unten dunkler und kühler, oben heller und
##   wärmer, jede Kugel leicht anders getönt.
## * **Blattkarten** (30–60) am Umriss: Vierecke, die sich im Vertexshader
##   zur Kamera drehen, mit einer prozeduralen Blattbüschel-Textur (256²,
##   Alpha-Scissor). Sie fransen die Silhouette aus, von jeder Seite.
## * **Wind**: ein Hauch im Vertexshader, kein Knoten wird bewegt.
##
## Varianten: 0 rund, 1 breit (Schirm), 2 hoch (schlank) – und `fern()`:
## flach, ohne Karten, ein paar hundert Dreiecke, zum Verschmelzen je Zelle.
##
## Koordinaten: Die Kronenmitte liegt bei `mitte` (Vorgabe Ursprung). Mit
## `zentren` (etwa den Astspitzen aus `Riesenstamm`) sitzen die Kugeln dort,
## wo die Äste enden – dann gelten die Koordinaten des Baums.
##
## Scheiteldaten (für den Stoff):
##   COLOR.rgb  Schattierung · Tönung, COLOR.a Windgewicht
##   UV2.x      1 = Blattkarte, 0 = Körper; UV2.y Kartengröße in m
##   UV         Ecke der Karte (0..1)
## Instanzfarben eines MultiMesh tönen die Krone. Eine skalierte Instanz
## skaliert auch die Karten mit.
##
## Schatten: Kronen werfen keine (Plan E15) – wer sie setzt, schaltet
## `cast_shadow` ab. Mit Schatten drehten sich die Karten zur Sonne.
##
## Aufruf:
##     var netz := Kronenwolke.netz({"radius": 4.0, "variante": 1, "saat": 3})
##     mi.mesh = netz
##     mi.material_override = Kronenwolke.stoff(Farben.LAUB)
##     mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Wie weit die Normalen zur Kronenmitte gebogen werden.
const BIEGUNG := 0.7


## Eine Krone. Optionen (alle freiwillig):
##   radius       waagerechter Radius in m (3)
##   hoehe        Gesamthöhe in m (je nach Variante)
##   mitte        Mittelpunkt (Vector3.ZERO)
##   variante     0 rund, 1 breit, 2 hoch
##   ballen       Anzahl der Kugeln (5–9, Vorgabe 7)
##   karten       Blattkarten (30–60 nach Größe; 0 = keine)
##   zentren      PackedVector3Array: Kugeln an diesen Stellen (Astspitzen,
##                der letzte Punkt ist der Leittrieb)
##   nebenzentren PackedVector3Array: kleinere Kugeln (Zweigspitzen)
##   flach        Fernfassung (siehe `fern()`)
##   wind         Windgewicht 0..1 (1)
##   saat         feste Saat (1)
static func netz(optionen: Dictionary = {}) -> ArrayMesh:
	var saat: int = optionen.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var variante: int = optionen.get("variante", 0)
	var flach: bool = optionen.get("flach", false)
	var radius: float = maxf(float(optionen.get("radius", 3.0)), 0.2)
	var hoehe_vorgabe := radius * (1.25 if variante == 0 else (0.75 if variante == 1 else 2.3))
	if flach:
		hoehe_vorgabe = radius * 0.9
	var hoehe: float = optionen.get("hoehe", hoehe_vorgabe)
	var mitte: Vector3 = optionen.get("mitte", Vector3.ZERO)
	var ballen: int = clampi(int(optionen.get("ballen", 5 if flach else 7)), 1, 12)
	var karten: int = optionen.get("karten", -1)
	if karten < 0:
		karten = 0 if flach else clampi(int(24.0 + radius * 12.0), 30, 60)
	var wind: float = optionen.get("wind", 1.0)
	var zentren: PackedVector3Array = optionen.get("zentren", PackedVector3Array())
	var nebenzentren: PackedVector3Array = optionen.get("nebenzentren", PackedVector3Array())

	var kugeln := _anordnen(rng, variante, flach, radius, hoehe, mitte, ballen, zentren,
			nebenzentren)

	# Hülle der ganzen Krone: Bezug für Biegung, Höhe und Verdeckung.
	var unten := INF
	var oben := -INF
	var box_min := Vector3(INF, INF, INF)
	var box_max := Vector3(-INF, -INF, -INF)
	for k in kugeln:
		var c: Vector3 = k["mitte"]
		var r: Vector3 = k["radien"]
		box_min = box_min.min(c - r)
		box_max = box_max.max(c + r)
	unten = box_min.y
	oben = box_max.y
	var huelle_mitte := (box_min + box_max) * 0.5
	var huelle_radien := ((box_max - box_min) * 0.5).max(Vector3(0.1, 0.1, 0.1))

	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 1.0
	rauschen.fractal_octaves = 2

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var randpunkte: Array[Dictionary] = []
	for index in kugeln.size():
		var k: Dictionary = kugeln[index]
		_kugel(st, rng, rauschen, k, index, kugeln, huelle_mitte, huelle_radien, unten, oben,
				wind, flach, randpunkte)

	# Blattkarten an Punkten nahe der Hülle, eher oben und außen.
	var max_karte := 0.0
	if karten > 0 and not randpunkte.is_empty():
		for n in karten:
			# Zweimal ziehen, den Punkt weiter außen nehmen: Die Karten
			# sammeln sich am Umriss, ohne die Fläche ganz zu meiden.
			var wahl: Dictionary = randpunkte[rng.randi_range(0, randpunkte.size() - 1)]
			var zweite: Dictionary = randpunkte[rng.randi_range(0, randpunkte.size() - 1)]
			if float(zweite["aussen"]) > float(wahl["aussen"]):
				wahl = zweite
			var p: Vector3 = wahl["ort"]
			var nrm: Vector3 = wahl["normale"]
			var farbe: Color = wahl["farbe"]
			var rk: float = wahl["kugel_radius"]
			var groesse := clampf(rk * rng.randf_range(0.55, 0.95), 0.35, 3.0)
			max_karte = maxf(max_karte, groesse)
			var ort := p + nrm * groesse * 0.12 + Vector3(rng.randf_range(-0.1, 0.1),
					rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)) * rk
			var f := Color(minf(farbe.r * 1.08, 1.0), minf(farbe.g * 1.08, 1.0),
					minf(farbe.b * 1.05, 1.0), minf(farbe.a + 0.2, 1.0))
			# Karten schauen stärker nach oben: Laub ist Licht zugewandt.
			_karte(st, ort, (nrm + Vector3.UP * 0.6).normalized(), groesse, f)

	var ergebnis: ArrayMesh = st.commit()
	# Die Karten wachsen erst im Shader um ihre Mitte: Hülle vorbeugend weiten,
	# sonst schneidet die Sichtprüfung sie am Bildrand ab.
	var box := ergebnis.get_aabb()
	ergebnis.custom_aabb = box.grow(max_karte * 0.75 + 0.1)
	return ergebnis


## Fernfassung: flache, verschmolzene Kugeln ohne Karten, Unterteilung 1.
## Ein paar hundert Dreiecke – für Talwald in 60–200 m, gern je Zelle mit
## `SurfaceTool.append_from` zu einem Netz verschmolzen (die Scheiteldaten
## überleben das).
static func fern(optionen: Dictionary = {}) -> ArrayMesh:
	var o := optionen.duplicate()
	o["flach"] = true
	return netz(o)


# ---------------------------------------------------------------- Anordnung

static func _anordnen(rng: RandomNumberGenerator, variante: int, flach: bool, radius: float,
		hoehe: float, mitte: Vector3, ballen: int, zentren: PackedVector3Array,
		nebenzentren: PackedVector3Array) -> Array[Dictionary]:
	var kugeln: Array[Dictionary] = []
	var halb_h := hoehe * 0.5
	var ys := 0.62 if variante == 1 else (0.8 if variante == 0 or flach else 0.9)
	if not zentren.is_empty():
		# An den Astspitzen: je Spitze eine Kugel, dazu eine Füllkugel in der
		# Mitte, damit die Krone kein Kranz aus Einzelballen wird.
		var schwer := Vector3.ZERO
		for p in zentren:
			schwer += p
		schwer /= float(zentren.size())
		var n := mini(zentren.size(), 8)
		# Groß genug, dass sich die Ballen überlappen: Sonst hinge an jedem
		# Ast eine eigene Kugel wie ein Bommel.
		for i in n:
			var p := zentren[i]
			var rk := radius * rng.randf_range(0.52, 0.64)
			if i == zentren.size() - 1:
				rk = radius * 0.56
			kugeln.append({"mitte": p + Vector3(0.0, rk * 0.25, 0.0),
					"radien": Vector3(rk, rk * ys, rk), "stufe": 2})
		# Zweige: kleine, grobe Kugeln – sie brechen den Umriss.
		for i in mini(nebenzentren.size(), 6):
			var rk := radius * rng.randf_range(0.3, 0.4)
			kugeln.append({"mitte": nebenzentren[i] + Vector3(0.0, rk * 0.2, 0.0),
					"radien": Vector3(rk, rk * ys, rk), "stufe": 1})
		var fuell := radius * 0.66
		kugeln.append({"mitte": schwer + Vector3(0.0, fuell * 0.35, 0.0),
				"radien": Vector3(fuell, fuell * ys, fuell), "stufe": 2})
		return kugeln

	var dreh := rng.randf() * TAU
	match variante:
		1:
			# Schirm: eine breite Scheibe aus Ballen, oben eine flache Kuppe,
			# die Unterseite fast eben.
			var r0 := radius * 0.5
			kugeln.append({"mitte": mitte + Vector3(0.0, halb_h * 0.15, 0.0),
					"radien": Vector3(r0, r0 * ys, r0)})
			for i in ballen - 1:
				var a := dreh + TAU * (float(i) + rng.randf_range(-0.2, 0.2)) / float(ballen - 1)
				var weite := radius * rng.randf_range(0.45, 0.62)
				var rk := radius * rng.randf_range(0.34, 0.46)
				kugeln.append({"mitte": mitte + Vector3(cos(a) * weite,
						rng.randf_range(-0.15, 0.2) * halb_h, -sin(a) * weite),
						"radien": Vector3(rk, rk * ys, rk)})
		2:
			# Schlank: eine Säule aus Ballen, die abwechselnd zur Seite
			# treten – kein Schneemann aus gestapelten Kugeln.
			var n := maxi(ballen + 1, 3)
			for i in n:
				var t := float(i) / float(n - 1)
				var rk := radius * lerpf(0.58, 0.36, t) * rng.randf_range(0.88, 1.12)
				var a := dreh + float(i) * 2.39996
				var weite := radius * rng.randf_range(0.28, 0.46) * (1.0 - t * 0.4)
				if i == 0:
					weite *= 0.3
				kugeln.append({"mitte": mitte + Vector3(cos(a) * weite,
						lerpf(-halb_h + rk * ys, halb_h - rk * ys, t) + rng.randf_range(-0.1, 0.1) * rk,
						-sin(a) * weite), "radien": Vector3(rk, rk * ys, rk)})
		_:
			# Rund: ein großer Kern unten, die übrigen als Buckel darüber und
			# ringsum, oben kleiner – wie eine Haufenwolke.
			var r0 := radius * 0.6
			kugeln.append({"mitte": mitte + Vector3(0.0, -halb_h * 0.12, 0.0),
					"radien": Vector3(r0, r0 * ys, r0)})
			for i in ballen - 1:
				var t := float(i) / float(maxi(ballen - 2, 1))
				var y_dir := lerpf(0.72, -0.3, t)
				var a := dreh + float(i) * 2.39996
				var flach_r := sqrt(maxf(0.0, 1.0 - y_dir * y_dir))
				var rk := radius * rng.randf_range(0.36, 0.5) * (1.0 - 0.22 * maxf(y_dir, 0.0))
				var ort := Vector3(cos(a) * flach_r * radius * 0.55,
						y_dir * (halb_h - rk * ys) * 0.9, -sin(a) * flach_r * radius * 0.55)
				kugeln.append({"mitte": mitte + ort, "radien": Vector3(rk, rk * ys, rk)})
	return kugeln


# ---------------------------------------------------------------- Kugeln

## Eine verrauschte Ikosphäre, ohne die Dreiecke, die in einer anderen
## Kugel stecken. Punkte nahe der Hülle merkt sie sich für die Karten.
static func _kugel(st: SurfaceTool, rng: RandomNumberGenerator, rauschen: FastNoiseLite,
		k: Dictionary, index: int, kugeln: Array[Dictionary], huelle_mitte: Vector3,
		huelle_radien: Vector3, unten: float, oben: float, wind: float, flach: bool,
		randpunkte: Array[Dictionary]) -> void:
	var c: Vector3 = k["mitte"]
	var radien: Vector3 = k["radien"]
	var stufe: int = k.get("stufe", 1 if flach or radien.x < 0.9 else 2)
	if flach:
		stufe = 1
	var ico := _ikosphaere(stufe)
	var einheit: PackedVector3Array = ico["punkte"]
	var dreiecke: PackedInt32Array = ico["dreiecke"]
	var versatz := Vector3(rng.randf_range(-50.0, 50.0), rng.randf_range(-50.0, 50.0),
			rng.randf_range(-50.0, 50.0))
	var ton := rng.randf_range(0.9, 1.08)
	var waerme := rng.randf_range(-0.04, 0.04)

	# Punkte verschieben: grobe Buckel und feinere Büschel.
	var punkte := PackedVector3Array()
	punkte.resize(einheit.size())
	for i in einheit.size():
		var d := einheit[i]
		var f := 1.0 + 0.16 * rauschen.get_noise_3dv(d * 1.7 + versatz) \
				+ 0.08 * rauschen.get_noise_3dv(d * 4.3 - versatz) \
				+ 0.07 * rauschen.get_noise_3dv(d * 9.0 + versatz * 0.5)
		var p := Vector3(d.x * radien.x, d.y * radien.y, d.z * radien.z) * f
		if p.y < 0.0:
			p.y *= 0.82
		punkte[i] = c + p

	# Glatte Normalen aus den Flächen.
	var normalen := PackedVector3Array()
	normalen.resize(punkte.size())
	for t in dreiecke.size() / 3:
		var a := punkte[dreiecke[t * 3]]
		var b := punkte[dreiecke[t * 3 + 1]]
		var cc := punkte[dreiecke[t * 3 + 2]]
		var n := (b - a).cross(cc - a)
		# nach außen zeigen lassen
		if n.dot((a + b + cc) / 3.0 - c) < 0.0:
			n = -n
		for e in 3:
			var ie := dreiecke[t * 3 + e]
			normalen[ie] = normalen[ie] + n

	# Farbe und gebogene Normale je Punkt.
	var farben := PackedColorArray()
	farben.resize(punkte.size())
	var gebogen := PackedVector3Array()
	gebogen.resize(punkte.size())
	for i in punkte.size():
		var p := punkte[i]
		var ng := normalen[i].normalized()
		var rel := (p - huelle_mitte) / huelle_radien
		var nh := Vector3(rel.x / huelle_radien.x, rel.y / huelle_radien.y,
				rel.z / huelle_radien.z).normalized()
		var nb := ng.lerp(nh, BIEGUNG).normalized()
		# Etwas Unruhe in den Normalen: Das Licht bricht in Büschel, statt
		# glatt über die Kugel zu laufen.
		var zittern := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0))
		# Etwas nach oben geneigt: Die Unterseite fängt noch Himmelslicht,
		# statt als schwarze Scheibe unter der Krone zu hängen.
		nb = (nb + zittern * 0.28 + Vector3.UP * 0.35).normalized()
		gebogen[i] = nb
		var t := clampf(inverse_lerp(unten, oben, p.y), 0.0, 1.0)
		var e := rel.length()
		var ao := lerpf(0.68, 1.0, smoothstep(0.45, 1.0, e))
		var hell := lerpf(0.58, 1.0, smoothstep(0.0, 1.0, t)) * ao * ton \
				* rng.randf_range(0.88, 1.08)
		# unten kühl und bläulich, oben warm und gelblich
		var farbe := Color(hell * (0.8 + 0.22 * t + waerme), hell * (0.92 + 0.08 * t),
				hell * (1.0 - 0.3 * t - waerme), (0.25 + 0.75 * t) * wind)
		farben[i] = Color(clampf(farbe.r, 0.0, 1.0), clampf(farbe.g, 0.0, 1.0),
				clampf(farbe.b, 0.0, 1.0), clampf(farbe.a, 0.0, 1.0))
		if not flach and e > 0.55:
			# Unterseite seltener: dort sieht man selten hin, und Karten unten
			# lesen sich als herabhängendes Laub nur in Maßen.
			if t < 0.2 and rng.randf() < 0.6:
				continue
			randpunkte.append({"ort": p, "normale": nb, "farbe": farben[i],
					"kugel_radius": radien.x, "aussen": e})

	for t in dreiecke.size() / 3:
		var i0 := dreiecke[t * 3]
		var i1 := dreiecke[t * 3 + 1]
		var i2 := dreiecke[t * 3 + 2]
		var a := punkte[i0]
		var b := punkte[i1]
		var cc := punkte[i2]
		var schwer := (a + b + cc) / 3.0
		# Grobe Kugeln (Fernfassung, Zweige) behalten alles: Ihre Facetten
		# weichen zu weit von der Idealform ab, man sähe durch die Lücken.
		if stufe > 1 and _verdeckt(schwer, index, kugeln):
			continue
		# Vorderseite nach außen: cross(b-a, c-a) muss nach innen zeigen.
		if (b - a).cross(cc - a).dot(schwer - c) > 0.0:
			var tausch := i1
			i1 = i2
			i2 = tausch
		for ii: int in [i0, i1, i2]:
			st.set_color(farben[ii])
			st.set_uv(Vector2.ZERO)
			st.set_uv2(Vector2.ZERO)
			st.set_normal(gebogen[ii])
			st.add_vertex(punkte[ii])


## Liegt der Punkt deutlich in einer anderen Kugel?
static func _verdeckt(p: Vector3, eigene: int, kugeln: Array[Dictionary]) -> bool:
	for i in kugeln.size():
		if i == eigene:
			continue
		var c: Vector3 = kugeln[i]["mitte"]
		var r: Vector3 = kugeln[i]["radien"]
		var d := (p - c) / r
		# Unten ist jede Kugel gestaucht (siehe `_kugel`).
		if d.y < 0.0:
			d.y /= 0.82
		# Vorsichtig: Das Rauschen drückt die andere Kugel stellenweise um
		# fast 30 % ein, die groben Facetten der Fernfassung noch mehr – dort
		# darf nichts fehlen, sonst sieht man durch die Krone hindurch.
		if d.length_squared() < 0.36:
			return true
	return false


## Eine Blattkarte: vier Ecken an derselben Stelle, der Shader zieht sie
## zur Kamera hin auf. Reihenfolge so, dass die Vorderseite zur Kamera zeigt.
static func _karte(st: SurfaceTool, ort: Vector3, normale: Vector3, groesse: float,
		farbe: Color) -> void:
	var ecken := [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0),
			Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
	for e: Vector2 in ecken:
		st.set_color(farbe)
		st.set_uv(e)
		st.set_uv2(Vector2(1.0, groesse))
		st.set_normal(normale)
		st.add_vertex(ort)


static var _ikos: Dictionary = {}

## Einheits-Ikosphäre (Punkte, Dreiecke) der Unterteilungsstufe, einmal
## gebaut und geteilt. Stufe 1: 80, Stufe 2: 320 Dreiecke.
static func _ikosphaere(stufe: int) -> Dictionary:
	if _ikos.has(stufe):
		return _ikos[stufe]
	var t := (1.0 + sqrt(5.0)) * 0.5
	var punkte := PackedVector3Array([
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	])
	for i in punkte.size():
		punkte[i] = punkte[i].normalized()
	var dreiecke := PackedInt32Array([
		0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
	])
	for s in stufe:
		var mitten := {}
		var neu := PackedInt32Array()
		for f in dreiecke.size() / 3:
			var a := dreiecke[f * 3]
			var b := dreiecke[f * 3 + 1]
			var c := dreiecke[f * 3 + 2]
			var ab := _mitte_von(a, b, punkte, mitten)
			var bc := _mitte_von(b, c, punkte, mitten)
			var ca := _mitte_von(c, a, punkte, mitten)
			neu.append_array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca])
		dreiecke = neu
	var ergebnis := {"punkte": punkte, "dreiecke": dreiecke}
	_ikos[stufe] = ergebnis
	return ergebnis


static func _mitte_von(a: int, b: int, punkte: PackedVector3Array, mitten: Dictionary) -> int:
	var schluessel := Vector2i(mini(a, b), maxi(a, b))
	if mitten.has(schluessel):
		return mitten[schluessel]
	punkte.append(((punkte[a] + punkte[b]) * 0.5).normalized())
	var i := punkte.size() - 1
	mitten[schluessel] = i
	return i


# ---------------------------------------------------------------- Stoff

static var _stoffe: Dictionary = {}
static var _shader: Shader = null
static var _blatt: ImageTexture = null

## Stoff der Kronen, je Laubfarbe einmal gebaut und geteilt – nie verändern.
static func stoff(farbe: Color = Farben.LAUB) -> ShaderMaterial:
	var schluessel := farbe.to_html()
	if _stoffe.has(schluessel):
		return _stoffe[schluessel]
	if _shader == null:
		_shader = Shader.new()
		_shader.code = KRONEN_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("blatt", blatttextur())
	_stoffe[schluessel] = m
	return m


## Blattbüschel, 256²: rund 90 spitzovale Blätter, strahlig um die Mitte,
## innen dunkler (Verdeckung), Mittelrippe und Rand leicht abgesetzt.
## Graustufen – die Farbe kommt aus Stoff und Scheitelfarbe. Durchsichtige
## Stellen tragen ein mittleres Grau, damit die Mipmaps nicht dunkel
## ausfransen; in den kleineren Stufen wird Alpha so angehoben, dass die
## Deckung erhalten bleibt (sonst zerfallen die Karten in der Ferne).
static func blatttextur() -> ImageTexture:
	if _blatt != null:
		return _blatt
	const K := 256
	var grund := Image.create_empty(K, K, false, Image.FORMAT_RGBA8)
	grund.fill(Color8(150, 150, 150, 0))
	var daten := grund.get_data()
	var rng := PropWerkzeug.zufall(8801)
	var mitte := Vector2(K * 0.5, K * 0.5)
	var weit := K * 0.36
	var blaetter: Array[Dictionary] = []
	for n in 95:
		var r := sqrt(rng.randf()) * weit
		var a := rng.randf() * TAU
		var laenge := rng.randf_range(24.0, 40.0) * lerpf(0.85, 1.1, r / weit)
		blaetter.append({
			"ort": mitte + Vector2(cos(a), sin(a)) * r,
			"winkel": a + rng.randf_range(-0.7, 0.7),
			"laenge": laenge,
			"breite": laenge * rng.randf_range(0.34, 0.46),
			"hell": rng.randf_range(0.6, 1.0) * lerpf(0.66, 1.0, r / weit),
			"r": r,
		})
	blaetter.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return float(x["r"]) < float(y["r"]))
	for b in blaetter:
		var ort: Vector2 = b["ort"]
		var winkel: float = b["winkel"]
		var laenge: float = b["laenge"]
		var breite: float = b["breite"]
		var hell: float = b["hell"]
		var achse := Vector2(cos(winkel), sin(winkel))
		var quer := Vector2(-achse.y, achse.x)
		# Enger Rahmen um das gedrehte Blatt – nur dort wird gerechnet.
		var spitze := ort + achse * laenge
		var q := quer * breite * 0.5
		var lo := ort.min(spitze) - q.abs() - Vector2(1.0, 1.0)
		var hi := ort.max(spitze) + q.abs() + Vector2(1.0, 1.0)
		var x0 := clampi(int(lo.x), 0, K - 1)
		var x1 := clampi(int(hi.x), 0, K - 1)
		var y0 := clampi(int(lo.y), 0, K - 1)
		var y1 := clampi(int(hi.y), 0, K - 1)
		for py in range(y0, y1 + 1):
			for px in range(x0, x1 + 1):
				var d := Vector2(float(px) + 0.5, float(py) + 0.5) - ort
				var u := d.dot(achse)
				if u < 0.0 or u > laenge:
					continue
				var v := absf(d.dot(quer))
				var f := u / laenge
				var halb := breite * 0.5 * pow(sin(PI * pow(f, 0.8)), 0.8)
				if v > halb:
					continue
				var s := hell * (0.72 + 0.28 * f)
				s *= 1.0 - 0.2 * (1.0 - smoothstep(0.0, 1.2, v))
				s *= 1.0 - 0.14 * pow(v / maxf(halb, 0.01), 4.0)
				var w := int(clampf(s, 0.0, 1.0) * 255.0)
				var i := (py * K + px) * 4
				daten[i] = w
				daten[i + 1] = w
				daten[i + 2] = w
				daten[i + 3] = 255
	var bild := Image.create_from_data(K, K, false, Image.FORMAT_RGBA8, daten)
	bild.generate_mipmaps()
	_deckung_halten(bild)
	_blatt = ImageTexture.create_from_image(bild)
	return _blatt


## Hebt Alpha in den Mipmaps so weit an, dass bei der Schwelle 0,5 so viel
## deckt wie in der vollen Auflösung.
static func _deckung_halten(bild: Image) -> void:
	var daten := bild.get_data()
	var k := bild.get_width()
	var soll := _deckung(daten, 0, k * k, 1.0)
	for stufe in range(1, bild.get_mipmap_count() + 1):
		var start := bild.get_mipmap_offset(stufe)
		var kante := maxi(k >> stufe, 1)
		var anzahl := kante * kante
		if anzahl < 4:
			break
		var lo := 1.0
		var hi := 4.0
		for versuch in 7:
			var mittel := (lo + hi) * 0.5
			if _deckung(daten, start, anzahl, mittel) < soll:
				lo = mittel
			else:
				hi = mittel
		var faktor := (lo + hi) * 0.5
		for i in anzahl:
			var j := (start / 4 + i) * 4 + 3
			daten[j] = mini(255, int(float(daten[j]) * faktor))
	var neu := Image.create_from_data(k, k, true, Image.FORMAT_RGBA8, daten)
	bild.copy_from(neu)


static func _deckung(daten: PackedByteArray, start: int, anzahl: int, faktor: float) -> float:
	var zaehler := 0
	for i in anzahl:
		if float(daten[start + i * 4 + 3]) * faktor >= 127.5:
			zaehler += 1
	return float(zaehler) / float(anzahl)


## Körper und Karten in einem Stoff (ein Zeichenaufruf je Netz). Die Karten
## werden in der Ansicht aufgezogen (`skip_vertex_transform`), jede um einen
## festen Zufallswinkel gedreht. Der Körper nimmt die Blatttextur als
## Helligkeitsmuster, damit er aus der Nähe nach Laub aussieht und nicht
## nach Kunststoff.
const KRONEN_SHADER := """
shader_type spatial;
render_mode skip_vertex_transform, cull_back, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 farbe : source_color = vec4(0.22, 0.47, 0.16, 1.0);
uniform sampler2D blatt : source_color, filter_linear_mipmap, repeat_enable;
uniform float wind = 1.0;
uniform float wind_weite = 0.05;
// Licht, das durch das Laub scheint: hebt die Unterseite, sonst stünden
// Kronen von unten als schwarze Scheiben im Bild.
uniform float durchlicht = 0.28;

varying float v_karte;
varying vec3 v_lokal;
varying vec3 v_n;

void vertex() {
	v_karte = step(0.5, UV2.x);
	v_lokal = VERTEX;
	v_n = NORMAL;
	vec3 welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float skala = length(MODEL_MATRIX[0].xyz);
	float phase = dot(MODEL_MATRIX[3].xyz, vec3(0.13, 0.0, 0.17)) + dot(VERTEX, vec3(0.9, 0.5, 0.7));
	float w = wind * wind_weite * COLOR.a * skala;
	vec3 schwung = vec3(sin(TIME * 1.1 + phase), 0.0, cos(TIME * 0.9 + phase * 1.3)) * w;
	vec3 ansicht = (VIEW_MATRIX * vec4(welt + schwung, 1.0)).xyz;
	if (v_karte > 0.5) {
		float groesse = UV2.y * skala;
		float zufall = fract(sin(dot(welt, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		float dreh = zufall * 6.2832 + sin(TIME * 1.7 + phase) * 0.06 * wind;
		vec2 ecke = (UV - vec2(0.5)) * vec2(1.0, -1.0) * groesse;
		float c = cos(dreh);
		float s = sin(dreh);
		ansicht.xy += vec2(c * ecke.x - s * ecke.y, s * ecke.x + c * ecke.y);
	}
	VERTEX = ansicht;
	NORMAL = normalize((VIEW_MATRIX * vec4((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz, 0.0)).xyz);
}

void fragment() {
	float muster;
	float alpha = 1.0;
	if (v_karte > 0.5) {
		vec4 t = texture(blatt, UV);
		muster = t.r;
		alpha = t.a;
	} else {
		// Körper: Blattmuster mit dunklen Lücken, dreifach projiziert nach
		// der (gebogenen) Normale – ohne Schlieren an steilen Stellen.
		vec3 p = v_lokal * 0.85;
		vec3 w = pow(abs(normalize(v_n)), vec3(3.0));
		w /= (w.x + w.y + w.z);
		vec4 a = texture(blatt, p.zy + vec2(0.13, 0.71));
		vec4 b = texture(blatt, p.xz);
		vec4 c = texture(blatt, p.xy + vec2(0.57, 0.29));
		float ma = mix(0.22, a.r * 1.05, a.a);
		float mb = mix(0.22, b.r * 1.05, b.a);
		float mc = mix(0.22, c.r * 1.05, c.a);
		muster = ma * w.x + mb * w.y + mc * w.z;
	}
	ALBEDO = farbe.rgb * COLOR.rgb * (0.42 + 0.72 * muster);
	// Durchlicht nach der Stofffarbe, nicht nach der Verdeckung: Auch die
	// Unterseite behält ihr Blattmuster.
	EMISSION = farbe.rgb * (0.45 + 0.55 * muster) * durchlicht;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""
