extends RefCounted
class_name Weltenbaum
## Der Weltenbaum: ein Riese mit rund 24 m Stammdurchmesser und einem
## Kronenschirm von fast 70 m – das Wahrzeichen am Ende von Level 01.
##
## Wie `Riesenstamm` nur statische Bauer, die in einen `SurfaceTool`
## schreiben oder ein `ArrayMesh` liefern: keine Knoten, keine Kollision,
## kein `_process`. WO etwas wächst (welche Wurzel wohin läuft, wo die Äste
## abgehen, wie die Wurzelwendel um den Stamm liegt), gibt der Aufrufer vor;
## hier steht, WIE es aussieht. Level 01 setzt alles in
## `scenes/levels/level01/weltenbaum.gd` zusammen.
##
## Bausteine:
## * `stamm_in()` – der Stamm mit Borkenrippen und Beulen wie bei
##   `Riesenstamm`, aber mit frei vorgegebenem Radiusverlauf (`profil`):
##   Der Riese ist nicht einfach ein großer Baum, er trägt eine Wurzelwendel,
##   deren Innenflanke genau an seiner Borke enden muss. Dazu Brettwurzeln,
##   Äste in die Krone, Konsolenpilze, Maserknollen, Efeu, Leuchtpilze und
##   senkrechte Moosstreifen. `stamm_schlicht_in()` baut dieselbe Säule mit
##   wenigen Ecken für die Ferne und den Schattenwurf.
## * `krone()` – der Kronenschirm aus `Kronenwolke`-Ballen, nah mit
##   Blattkarten, fern (und je Ballen "grob") flach.
## * Wurzelwerk als Gitter: `rohr()` (runder Strang entlang eines
##   Punktzugs), `zug()` (Querschnitte beliebiger Form), `gitter_faerben()`,
##   `orientieren()` und `gitter_schreiben()`. Die Normalen entstehen einmal
##   für das ganze Gitter; `gitter_schreiben()` schreibt auf Wunsch nur einen
##   Teil der Zeilen (so lässt sich ein Strang ohne Lichtkante auf mehrere
##   Netze verteilen) und lässt über einen Filter Vierecke aus, die nie zu
##   sehen sind.
## * `bruch_in()` (Bruchfläche mit Splittern und Jahresringen),
##   `knolle_in()` (Maserknolle), `leuchtpilz_in()` (Leuchtpilz mit
##   gedämpfter Glut für den Borkenstoff).
## * Stoffe: `stoff_stamm()`, `stoff_wurzel()`, `stoff_tor()`,
##   `stoff_krone()`.
##
## Koordinaten des Stamms: Ursprung in der Stammachse auf Welt-Y 0, +Y
## hinauf – wer ihn setzt, verschiebt nur waagerecht. Winkel wie bei
## `Riesenstamm`: 0 = +X, gegen den Uhrzeigersinn von oben, Richtung
## (cos w, 0, -sin w).
##
## Scheiteldaten wie `Riesenstamm` (COLOR.rgb Verdeckung, COLOR.a Moos, UV
## Borke, UV2.x Art, UV2.y Nordmoos) – alles zeichnet mit dem Borkenstoff.

## Laubfarbe der Krone: ein Hauch dunkler als der Wald ringsum. Der Riese
## soll sich als Masse lesen, nicht als heller Fleck.
const FARBE_KRONE := Color(0.19, 0.4, 0.15)
## Die Fernkrone: noch dunkler und kühler – vom Grat aus steht sie 150 m
## weit im Dunst und soll dort dunkler als der Dunst bleiben.
const FARBE_KRONE_FERN := Color(0.085, 0.18, 0.09)

## Farben der Bruchflächen: faseriges helles Holz, innen morsch.
const HOLZ := Color(0.5, 0.37, 0.23)
const MORSCH := Color(0.12, 0.08, 0.05)


# ================================================================ Stamm

## Radius des Stamms in der Höhe `y` (Welt), ohne Rippen und Beulen.
## `profil`: Stützstellen Vector2(y, r), aufsteigend; dazwischen Catmull-Rom,
## außerhalb der erste bzw. letzte Wert.
static func profil_radius(profil: PackedVector2Array, y: float) -> float:
	var n := profil.size()
	if n == 0:
		return 1.0
	if y <= profil[0].x:
		return profil[0].y
	if y >= profil[n - 1].x:
		return profil[n - 1].y
	var i := 0
	while i < n - 2 and y > profil[i + 1].x:
		i += 1
	var p1 := profil[i]
	var p2 := profil[i + 1]
	var p0 := profil[maxi(i - 1, 0)]
	var p3 := profil[mini(i + 2, n - 1)]
	var t := (y - p1.x) / maxf(p2.x - p1.x, 0.001)
	# Tangenten aus den Nachbarn, auf den Abstand der Stützstellen bezogen.
	var m1 := (p2.y - p0.y) / maxf(p2.x - p0.x, 0.001) * (p2.x - p1.x)
	var m2 := (p3.y - p1.y) / maxf(p3.x - p1.x, 0.001) * (p2.x - p1.x)
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * p1.y + (t3 - 2.0 * t2 + t) * m1 \
			+ (-2.0 * t3 + 3.0 * t2) * p2.y + (t3 - t2) * m2


## Punkt auf der Borke bei Winkel `w` und Höhe `y`, `abstand` Meter davor
## (Grundradius, ohne Rippen).
static func auf_borke(profil: PackedVector2Array, w: float, y: float,
		abstand: float = 0.0) -> Vector3:
	var r := profil_radius(profil, y) + abstand
	return Vector3(cos(w) * r, y, -sin(w) * r)


## Der Stamm samt Beiwerk. Optionen:
##   profil        PackedVector2Array (y, r) – Pflicht
##   y_von, y_bis  Fuß (versenkt) und oberes Ende (offen, in der Krone)
##   rippen        Borkenrippen (36), Ecken rundum das Doppelte
##   rippen_tiefe  Rippenhöhe relativ zum Radius (0.04)
##   drehung       Drehung der Rippen über die ganze Höhe in rad (0.35)
##   ring_min, ring_max  Ringabstand unten und oben (1.2 / 3.2)
##   boden         Callable(winkel) -> Welt-Y des Bodens rundum (Verdeckung
##                 und Moos am Fuß); ohne: y_von + 1
##   verdeckung    Callable(Vector3) -> Faktor 0..1 je Ecke (etwa, wo die
##                 Wurzelwendel am Stamm anliegt); freiwillig
##   streifen      senkrechte Moosstreifen 0..1 (0.6)
##   saat          feste Saat
##   brettwurzeln  [{winkel, reichweite, hoehe, dicke, fuss_y, schlange?,
##                 kruemmung?}]
##   aeste         [{winkel, y, laenge, steigung, radius, zweige?, seiten?,
##                 wandern?}] – Äste, die in die Krone führen
##   pilze         [{winkel, y, breite}] – Gruppen von Konsolenpilzen
##   knollen       [{winkel, y, radius}] – Maserknollen auf der Borke
##   efeu          [{winkel, von, bis}] – Efeuranken
##   leuchten      [{winkel, y}] – Leuchtpilzgruppen in den Furchen
## Rückgabe: {"ast_spitzen", "ast_richtungen", "zweig_spitzen"} (Achsraum) –
## wo die Krone ansetzen soll.
static func stamm_in(st: SurfaceTool, o: Dictionary) -> Dictionary:
	var profil: PackedVector2Array = o["profil"]
	var saat: int = o.get("saat", 21)
	var rng := PropWerkzeug.zufall(saat + 5)
	var rippen: int = o.get("rippen", 36)
	var seiten := rippen * 2
	var tiefe: float = o.get("rippen_tiefe", 0.04)
	var drehung: float = o.get("drehung", 0.35)
	var y_von: float = o.get("y_von", 0.0)
	var y_bis: float = o.get("y_bis", 50.0)
	var ring_min: float = o.get("ring_min", 1.2)
	var ring_max: float = o.get("ring_max", 3.2)
	var streifen: float = o.get("streifen", 0.6)
	var boden: Callable = o.get("boden", Callable())
	var verdeckung: Callable = o.get("verdeckung", Callable())
	var rauschen := Riesenstamm._rauschen(saat)
	var fein := FastNoiseLite.new()
	fein.seed = saat + 3
	fein.frequency = 1.0

	# Brettwurzeln vorab: Der Stamm schwillt zu ihnen hin an.
	var wurzeln: Array = o.get("brettwurzeln", [])

	var hoehen := PackedFloat32Array()
	var y := y_von
	hoehen.append(y)
	while y < y_bis - 0.01:
		var schritt := clampf(ring_min + (y - y_von) * 0.06, ring_min, ring_max)
		schritt *= rng.randf_range(0.85, 1.15)
		y = minf(y + schritt, y_bis)
		if y_bis - y < schritt * 0.35:
			y = y_bis
		hoehen.append(y)

	var amplituden := PackedFloat32Array()
	for k in rippen:
		amplituden.append(tiefe * rng.randf_range(0.45, 1.4))
	var versatz := PackedFloat32Array()
	for j in seiten:
		versatz.append(rng.randf_range(-0.2, 0.2) * TAU / float(seiten))
	var r_mittel := profil_radius(profil, (y_von + y_bis) * 0.5)
	var kachel := Riesenstamm.borkenmass(r_mittel)
	var n_u := maxi(1, roundi(TAU * r_mittel * Riesenstamm.KACHEL_U * kachel))

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	for i in hoehen.size():
		var yy := hoehen[i]
		var r0 := profil_radius(profil, yy)
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in seiten + 1:
			var jj := j % seiten
			var winkel := TAU * float(jj) / float(seiten) + versatz[jj] \
					+ drehung * (yy - y_von) / maxf(y_bis - y_von, 1.0)
			var k := (jj >> 1) % rippen
			var rel := 1.0
			var furche := jj % 2 == 1
			if not furche:
				rel += amplituden[k] * (0.75 + 0.5 * rauschen.get_noise_2d(float(k) * 7.3, yy * 0.2))
			else:
				var k2 := ((jj + 1) >> 1) % rippen
				rel -= (amplituden[k] + amplituden[k2]) * 0.4
			var beule := 1.0 + 0.045 * rauschen.get_noise_3d(cos(winkel) * 1.6, yy * 0.09, sin(winkel) * 1.6) \
					+ 0.02 * fein.get_noise_3d(cos(winkel) * 6.0, yy * 0.4, sin(winkel) * 6.0)
			var wulst := _wulst(winkel, yy, wurzeln)
			var r := r0 * rel * beule + wulst
			var p := Vector3(cos(winkel) * r, yy, -sin(winkel) * r)
			zeile.append(p)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u),
					yy * Riesenstamm.KACHEL_V * kachel))
			var y_boden: float = y_von + 1.0
			if boden.is_valid():
				y_boden = boden.call(winkel)
			var ao := lerpf(0.34, 1.0, smoothstep(y_boden - 0.5, y_boden + 4.0, yy)) \
					* lerpf(0.8, 1.0, smoothstep(y_boden + 4.0, y_boden + 12.0, yy))
			if furche:
				ao *= 0.78
			if verdeckung.is_valid():
				ao *= float(verdeckung.call(p))
			# Moos: unten dicht, in den Furchen, und in senkrechten Streifen,
			# die den Stamm hinablaufen (an einer Rippe entlang, nicht quer).
			var m := 0.9 * (1.0 - smoothstep(y_boden, y_boden + 7.0, yy)) \
					+ (0.12 if furche else 0.0)
			var lauf := rauschen.get_noise_3d(cos(winkel) * 4.2, yy * 0.012, sin(winkel) * 4.2)
			m += streifen * smoothstep(0.18, 0.42, lauf) * (0.55 + 0.45 * fein.get_noise_2d(winkel * 9.0, yy * 0.3))
			m += 0.25 * rauschen.get_noise_3d(p.x * 0.35, p.y * 0.25, p.z * 0.35)
			var nord := 1.0 - smoothstep(y_boden, y_boden + 24.0, yy)
			fa.append(Color(ao, ao, ao, clampf(m, 0.0, 1.0)))
			ar.append(Vector2(Riesenstamm.BORKE, nord))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)

	for w: Dictionary in wurzeln:
		var fuss: float = w["fuss_y"]
		Riesenstamm.brettwurzel_in(st, Vector3(0.0, fuss, 0.0), float(w["winkel"]),
				profil_radius(profil, fuss + 1.0), float(w["reichweite"]), float(w["hoehe"]),
				float(w["dicke"]), float(w.get("schlange", rng.randf_range(-0.3, 0.3))),
				float(w.get("kruemmung", rng.randf_range(1.6, 2.2))), 1.0, rauschen)

	var spitzen := PackedVector3Array()
	var richtungen := PackedVector3Array()
	var zweig_spitzen := PackedVector3Array()
	for a: Dictionary in o.get("aeste", []):
		var ergebnis := ast_in(st, a, profil, rng)
		spitzen.append_array(ergebnis[0] as PackedVector3Array)
		richtungen.append_array(ergebnis[1] as PackedVector3Array)
		zweig_spitzen.append_array(ergebnis[2] as PackedVector3Array)

	for p: Dictionary in o.get("pilze", []):
		var w: float = p["winkel"]
		var breite: float = p.get("breite", 1.4)
		var y0: float = p["y"]
		for k in rng.randi_range(2, 4):
			var yk := y0 + float(k) * breite * rng.randf_range(0.45, 0.7)
			var wk := w + rng.randf_range(-0.5, 0.5) * breite / profil_radius(profil, yk)
			var ort := auf_borke(profil, wk, yk, 0.25)
			Riesenstamm.konsolenpilz_in(st, ort, Vector3(cos(wk), 0.0, -sin(wk)),
					breite * rng.randf_range(0.7, 1.15), rng)

	for k: Dictionary in o.get("knollen", []):
		var w: float = k["winkel"]
		var yk: float = k["y"]
		var aussen := Vector3(cos(w), 0.0, -sin(w))
		knolle_in(st, auf_borke(profil, w, yk, -0.25), aussen, float(k["radius"]), rng, 0.6)

	for e: Dictionary in o.get("efeu", []):
		_efeu_in(st, e, profil, rng)

	for l: Dictionary in o.get("leuchten", []):
		var w: float = l["winkel"]
		var yl: float = l["y"]
		for n in rng.randi_range(4, 7):
			var wn := w + rng.randf_range(-0.035, 0.035)
			var ort := auf_borke(profil, wn, yl + rng.randf_range(-0.5, 0.5), 0.05)
			leuchtpilz_in(st, ort, rng.randf_range(0.12, 0.22), rng)
	return {"ast_spitzen": spitzen, "ast_richtungen": richtungen,
			"zweig_spitzen": zweig_spitzen}


## Anschwellen des Stamms zu den Brettwurzeln hin.
static func _wulst(winkel: float, y: float, wurzeln: Array) -> float:
	var summe := 0.0
	for w: Dictionary in wurzeln:
		var fuss: float = w["fuss_y"]
		var hh: float = float(w["hoehe"]) * 0.8
		var yy := y - fuss
		if yy >= hh or yy < -1.5:
			continue
		var d := angle_difference(winkel, float(w["winkel"]))
		var f := 1.0 - maxf(yy, 0.0) / hh
		summe += float(w["reichweite"]) * 0.13 * exp(-(d * d) / 0.012) * f * f
	return summe


## Dieselbe Säule schlicht: wenige Ecken, keine Rippen, keine Pilze – für
## die Ferne (ab 110 m) und als Schattenwerfer. Optionen wie `stamm_in`,
## dazu "seiten" (24), "ring_abstand" (5), "schrumpfen" (Faktor auf den
## Radius: Die Fernfassung liegt knapp INNERHALB der nahen, damit beim
## Wechsel keine Fläche in der anderen flackert). Äste mit 6 Ecken, ohne
## Zweige. Brettwurzeln nur mit "mit_wurzeln".
static func stamm_schlicht_in(st: SurfaceTool, o: Dictionary) -> void:
	var profil: PackedVector2Array = o["profil"]
	var saat: int = o.get("saat", 21)
	var rng := PropWerkzeug.zufall(saat + 5)
	var seiten: int = o.get("seiten", 24)
	var y_von: float = o.get("y_von", 0.0)
	var y_bis: float = o.get("y_bis", 50.0)
	var abstand: float = o.get("ring_abstand", 5.0)
	var schrumpfen: float = o.get("schrumpfen", 1.0)
	var boden: Callable = o.get("boden", Callable())
	var rauschen := Riesenstamm._rauschen(saat)
	var anzahl := maxi(2, ceili((y_bis - y_von) / abstand))
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	for i in anzahl + 1:
		var yy := lerpf(y_von, y_bis, float(i) / float(anzahl))
		var r0 := profil_radius(profil, yy) * schrumpfen
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in seiten + 1:
			var winkel := TAU * float(j % seiten) / float(seiten)
			var r := r0 * (1.0 + 0.04 * rauschen.get_noise_3d(cos(winkel) * 1.6, yy * 0.09, sin(winkel) * 1.6))
			zeile.append(Vector3(cos(winkel) * r, yy, -sin(winkel) * r))
			uv.append(Vector2(float(j) / float(seiten) * 12.0, yy * 0.05))
			var y_boden: float = y_von + 1.0
			if boden.is_valid():
				y_boden = boden.call(winkel)
			var ao := lerpf(0.4, 1.0, smoothstep(y_boden, y_boden + 5.0, yy))
			fa.append(Color(ao, ao, ao, 0.9 * (1.0 - smoothstep(y_boden, y_boden + 7.0, yy))))
			ar.append(Vector2(Riesenstamm.BORKE, 1.0 - smoothstep(y_boden, y_boden + 24.0, yy)))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)
	if o.get("mit_wurzeln", false):
		for w: Dictionary in o.get("brettwurzeln", []):
			var fuss: float = w["fuss_y"]
			Riesenstamm.brettwurzel_in(st, Vector3(0.0, fuss, 0.0), float(w["winkel"]),
					profil_radius(profil, fuss + 1.0) * schrumpfen,
					float(w["reichweite"]) * schrumpfen, float(w["hoehe"]) * schrumpfen,
					float(w["dicke"]) * schrumpfen, float(w.get("schlange", 0.0)),
					float(w.get("kruemmung", 1.9)), 1.0, rauschen)
	for a: Dictionary in o.get("aeste", []):
		var fern := a.duplicate()
		fern["zweige"] = 0
		fern["seiten"] = 6
		fern["stuecke"] = 4
		fern["radius"] = float(a.get("radius", 2.4)) * schrumpfen
		ast_in(st, fern, profil, rng)


## Ein Ast vom Stamm in die Krone: beginnt tief im Stamm, schwingt erst fast
## waagerecht hinaus und dann hinauf, verjüngt sich. Dazu Zweige, die zur
## Seite abgehen. Rückgabe [Spitzen, Richtungen, Zweigspitzen].
static func ast_in(st: SurfaceTool, a: Dictionary, profil: PackedVector2Array,
		rng: RandomNumberGenerator) -> Array:
	var w: float = a["winkel"]
	var y0: float = a["y"]
	var laenge: float = a["laenge"]
	var steigung: float = a.get("steigung", 0.45)
	var radius: float = a.get("radius", 2.4)
	var seiten: int = a.get("seiten", 12)
	var stuecke: int = a.get("stuecke", 8)
	var aussen := Vector3(cos(w), 0.0, -sin(w))
	var seitlich := aussen.cross(Vector3.UP)
	var wandern: float = a.get("wandern", rng.randf_range(-0.12, 0.12))
	var r0 := profil_radius(profil, y0) * 0.55
	var punkte := PackedVector3Array()
	var radien := PackedFloat32Array()
	for i in stuecke + 1:
		var t := float(i) / float(stuecke)
		var weite := r0 + laenge * t
		var hoch := laenge * (steigung * t * 0.45 + steigung * 0.9 * t * t)
		var p := aussen * weite + seitlich * (wandern * laenge * t * t) \
				+ Vector3.UP * (y0 + hoch - radius * 0.5 * (1.0 - t) * (1.0 - t))
		punkte.append(p)
		radien.append(lerpf(radius, radius * 0.28, pow(t, 0.8)))
	var g := rohr(punkte, radien, {"seiten": seiten, "beulen": 0.1, "saat": rng.randi(),
			"ende": "spitz", "uv_mass": 0.8})
	# Unterseite dunkler, obenauf Moos.
	var astfarbe := func(_p: Vector3, n: Vector3) -> Color:
		var ao := lerpf(0.5, 1.0, n.y * 0.5 + 0.5)
		return Color(ao, ao, ao, clampf(n.y * 0.95 - 0.1, 0.0, 0.85))
	gitter_faerben(g, astfarbe, 0.4)
	gitter_schreiben(st, g)
	var spitzen := PackedVector3Array([punkte[stuecke]])
	var richtungen := PackedVector3Array([(punkte[stuecke] - punkte[stuecke - 1]).normalized()])
	var zweig_spitzen := PackedVector3Array()
	var zweige: int = a.get("zweige", 2)
	for k in zweige:
		var ab := rng.randf_range(0.45, 0.8)
		var i := clampi(int(ab * float(stuecke)), 1, stuecke - 1)
		var start := punkte[i]
		var seite := 1.0 if k % 2 == 0 else -1.0
		var richtung := (aussen * 0.45 + seitlich * seite * 0.8 + Vector3.UP * 0.5).normalized()
		var zl := laenge * rng.randf_range(0.3, 0.45)
		var zweig := PackedVector3Array()
		var zr := PackedFloat32Array()
		for s in 4:
			var t := float(s) / 3.0
			zweig.append(start + richtung * zl * t + Vector3.UP * zl * 0.18 * t * t)
			zr.append(lerpf(radien[i] * 0.45, radien[i] * 0.12, t))
		var gz := rohr(zweig, zr, {"seiten": 7, "beulen": 0.1, "saat": rng.randi(),
				"ende": "spitz", "uv_mass": 0.8})
		gitter_faerben(gz, astfarbe, 0.3)
		gitter_schreiben(st, gz)
		zweig_spitzen.append(zweig[3])
	return [spitzen, richtungen, zweig_spitzen]


## Efeu, der sich die Borke hinaufwindet: ein Band aus Blättern, unten
## dicht, oben licht. Blätter liegen fast flach auf der Borke und schauen
## ein wenig nach oben ins Licht (wie `Riesenstamm`, nur im Maß des Riesen).
static func _efeu_in(st: SurfaceTool, e: Dictionary, profil: PackedVector2Array,
		rng: RandomNumberGenerator) -> void:
	var winkel: float = e["winkel"]
	var von: float = e["von"]
	var bis: float = e["bis"]
	var blatt: float = e.get("blatt", 0.42)
	var band: float = e.get("band", 1.6)
	var schritt := blatt * 0.6
	var phase := rng.randf() * TAU
	var y := von
	while y < bis:
		var anteil := (y - von) / maxf(bis - von, 0.1)
		var r := profil_radius(profil, y)
		var mitte_w := winkel + 0.6 * sin(y * 0.16 + phase) / r
		var anzahl := rng.randi_range(2, 4) if anteil < 0.6 else rng.randi_range(0, 2)
		for n in anzahl:
			var quer := rng.randf_range(-1.0, 1.0) * band * lerpf(1.0, 0.45, anteil)
			var w := mitte_w + quer / r
			var aussen := Vector3(cos(w), 0.0, -sin(w))
			var ort := auf_borke(profil, w, y + rng.randf_range(-schritt, schritt) * 0.5, 0.6)
			var seit := aussen.cross(Vector3.UP).normalized()
			var g := blatt * rng.randf_range(0.7, 1.3) * lerpf(1.0, 0.7, anteil)
			var dreh := rng.randf_range(-1.2, 1.2)
			var richtung := (Vector3.UP * cos(dreh) + seit * sin(dreh)).normalized()
			richtung = (richtung + aussen * 0.35).normalized()
			var normale := (aussen * 0.8 + Vector3.UP * 0.35 - richtung * 0.2).normalized()
			var quer_v := richtung.cross(normale).normalized() * g * 0.62
			var basis := ort + aussen * 0.02
			var spitze := basis + richtung * g
			var mitte_b := basis + richtung * g * 0.45 + normale * g * 0.08
			var l1 := basis + richtung * g * 0.38 + quer_v
			var l2 := basis + richtung * g * 0.38 - quer_v
			var s1 := basis + richtung * g * 0.8 + quer_v * 0.45
			var s2 := basis + richtung * g * 0.8 - quer_v * 0.45
			var gruen := Color(0.09, 0.17, 0.06).lerp(Color(0.16, 0.26, 0.09), rng.randf())
			gruen = gruen * lerpf(0.75, 1.0, rng.randf())
			var art := Vector2(Riesenstamm.EIGEN, 0.0)
			dreieck(st, basis, l1, mitte_b, normale, gruen * 0.7, gruen, gruen * 1.05, art)
			dreieck(st, mitte_b, l1, s1, normale, gruen * 1.05, gruen, gruen * 1.1, art)
			dreieck(st, mitte_b, s1, spitze, normale, gruen * 1.05, gruen * 1.1, gruen * 1.15, art)
			dreieck(st, basis, mitte_b, l2, normale, gruen * 0.7, gruen * 1.05, gruen, art)
			dreieck(st, mitte_b, s2, l2, normale, gruen * 1.05, gruen * 1.1, gruen, art)
			dreieck(st, mitte_b, spitze, s2, normale, gruen * 1.05, gruen * 1.15, gruen * 1.1, art)
		y += schritt * rng.randf_range(0.7, 1.3)


# ================================================================ Krone

## Der Kronenschirm aus Ballen. `ballen`: [{mitte: Vector3, radius,
## variante (0 rund, 1 Schirm), saat, ballen?, karten?, hoehe?, grob?}].
## Nah (`fern` false): Ballen wie angegeben; fern und "grob": flach mit
## höchstens vier Kugeln und ohne Karten – rund 300 Dreiecke je Ballen. Ein
## Netz, ein Zeichenaufruf. Stoff: `stoff_krone(fern)`, ohne Schatten.
static func krone(ballen: Array, fern: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var huelle := AABB()
	var erste := true
	for b: Dictionary in ballen:
		var grob := fern or bool(b.get("grob", false))
		var o := {
			"radius": b["radius"], "variante": b.get("variante", 1), "mitte": b["mitte"],
			"saat": b.get("saat", 1), "flach": grob,
		}
		if grob:
			o["ballen"] = mini(int(b.get("ballen", 5)), 4)
		else:
			o["ballen"] = b.get("ballen", 6)
			o["karten"] = b.get("karten", 120)
		if b.has("hoehe"):
			o["hoehe"] = b["hoehe"]
		var netz := Kronenwolke.netz(o)
		st.append_from(netz, 0, Transform3D.IDENTITY)
		var box := netz.get_aabb()
		if erste:
			huelle = box
			erste = false
		else:
			huelle = huelle.merge(box)
	var ergebnis := st.commit()
	# Die Karten wachsen erst im Shader: Hülle vorbeugend weiten (wie
	# `Kronenwolke.netz`), sonst schnitte die Sichtprüfung sie ab.
	ergebnis.custom_aabb = huelle.grow(2.0)
	return ergebnis


# ================================================================ Gitter

## Ein Rohr entlang eines Punktzugs: `radien` je Punkt. Die Rahmen werden
## parallel verschoben (kein Verdrillen). Optionen:
##   seiten   Ecken rundum (10)
##   beulen   Unruhe des Radius (0,08) – NUR nach innen, damit ein Strang,
##            der an eine Kollisionsfläche gelegt wird, nie über sie ragt
##   saat     für das Rauschen
##   ende     "offen" (Vorgabe), "spitz" (läuft zu), "stumpf" (Deckel)
##   uv_mass  Borkenmaß (Vorgabe aus dem mittleren Radius)
##   anfang_normale  Vector3: Richtung der ersten Ecke (die Naht der
##            Textur liegt dort); Vorgabe möglichst nach oben
## Die Vorderseite zeigt nach außen (wie `Riesenstamm._rohr`).
## Rückgabe: Gitter für `gitter_faerben()`/`gitter_schreiben()`; "mitten"
## hält die Achspunkte je Zeile.
static func rohr(punkte: PackedVector3Array, radien: PackedFloat32Array,
		optionen: Dictionary = {}) -> Dictionary:
	var g := {"p": [], "uv": [], "ringsum": true, "mitten": PackedVector3Array()}
	var n := punkte.size()
	if n < 2:
		return g
	var seiten: int = optionen.get("seiten", 10)
	var beulen: float = optionen.get("beulen", 0.08)
	var ende: String = optionen.get("ende", "offen")
	var rauschen := FastNoiseLite.new()
	rauschen.seed = int(optionen.get("saat", 1))
	rauschen.frequency = 0.6
	var mittel := 0.0
	for r in radien:
		mittel += r
	mittel /= float(radien.size())
	var mass: float = optionen.get("uv_mass", Riesenstamm.borkenmass(mittel))
	var n_u := maxi(1, roundi(TAU * mittel * Riesenstamm.KACHEL_U * mass))
	var t0 := (punkte[1] - punkte[0]).normalized()
	var hilfe: Vector3 = optionen.get("anfang_normale", Vector3.UP)
	if absf(t0.dot(hilfe.normalized())) > 0.95:
		hilfe = Vector3.RIGHT if absf(t0.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var normale := (hilfe - t0 * hilfe.dot(t0)).normalized()
	var bogen := 0.0
	var zeilen_zahl := n + (1 if ende == "spitz" else 0)
	for i in zeilen_zahl:
		var ii := mini(i, n - 1)
		var t: Vector3
		if ii == 0:
			t = t0
		elif ii == n - 1:
			t = (punkte[n - 1] - punkte[n - 2]).normalized()
		else:
			t = (punkte[ii + 1] - punkte[ii - 1]).normalized()
		normale = (normale - t * normale.dot(t)).normalized()
		var bi := t.cross(normale)
		var mitte := punkte[ii]
		var rad := radien[ii]
		if i >= n:
			mitte += t * rad * 1.1
			rad *= 0.12
		if ii > 0 and i < n:
			bogen += punkte[ii].distance_to(punkte[ii - 1])
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		for j in seiten + 1:
			var a := TAU * float(j % seiten) / float(seiten)
			var richtung := normale * cos(a) + bi * sin(a)
			var p0 := mitte + richtung * rad
			var r := rad * (1.0 - beulen * (0.5 + 0.5 * rauschen.get_noise_3dv(p0)))
			zeile.append(mitte + richtung * r)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u),
					bogen * Riesenstamm.KACHEL_V * 1.6 * mass))
		(g["p"] as Array).append(zeile)
		(g["uv"] as Array).append(uv)
		(g["mitten"] as PackedVector3Array).append(mitte)
	if ende == "stumpf":
		g["deckel"] = true
	return g


## Gitter aus Querschnitten: je Stelle eine Punktreihe (Weltpunkte, alle
## gleich lang). `ringsum`: geschlossene Querschnitte (der erste Punkt wird
## hinten wiederholt). `laengs`: Bogenlänge je Stelle (für die UV). Die
## Vorderseite richtet `orientieren()` aus.
static func zug(schnitte: Array[PackedVector3Array], laengs: PackedFloat32Array,
		ringsum: bool, optionen: Dictionary = {}) -> Dictionary:
	var g := {"p": [], "uv": [], "ringsum": ringsum}
	if schnitte.size() < 2:
		return g
	var mass: float = optionen.get("uv_mass", 0.7)
	var umfang := 0.0
	for schnitt in schnitte:
		umfang += _umfang(schnitt, ringsum)
	umfang /= float(schnitte.size())
	var n_u := maxi(1, roundi(umfang * Riesenstamm.KACHEL_U * mass))
	for i in schnitte.size():
		var schnitt := schnitte[i]
		var eigen := maxf(_umfang(schnitt, ringsum), 0.001)
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var lauf := 0.0
		var anzahl := schnitt.size() + (1 if ringsum else 0)
		for j in anzahl:
			var p := schnitt[j % schnitt.size()]
			if j > 0:
				lauf += p.distance_to(schnitt[(j - 1) % schnitt.size()])
			zeile.append(p)
			var u := lauf / eigen * float(n_u) if ringsum else lauf * Riesenstamm.KACHEL_U * mass
			uv.append(Vector2(u, laengs[i] * Riesenstamm.KACHEL_V * 1.6 * mass))
		(g["p"] as Array).append(zeile)
		(g["uv"] as Array).append(uv)
	return g


static func _umfang(schnitt: PackedVector3Array, ringsum: bool) -> float:
	var summe := 0.0
	var n := schnitt.size()
	for j in range(1, n + (1 if ringsum else 0)):
		summe += schnitt[j % n].distance_to(schnitt[j - 1])
	return summe


## Normalen, Farben und Arten eines Gitters. `farbe(p, n) -> Color` liefert
## je Ecke Verdeckung (rgb) und Moos (a), `nord` ist das Gewicht des
## Nordmooses (UV2.y). Die Normalen kommen aus den Nachbarn im Gitter – über
## die Naht eines Rings hinweg, so bleibt keine Lichtkante. Sie zeigen nach
## cross(d_spalte, d_zeile); wer die andere Seite braucht, ruft danach
## `orientieren()`.
static func gitter_faerben(g: Dictionary, farbe: Callable, nord: float = 0.5) -> void:
	var zeilen: Array = g["p"]
	var r := zeilen.size()
	if r < 2:
		return
	var ringsum: bool = g["ringsum"]
	var c := (zeilen[0] as PackedVector3Array).size()
	var normalen: Array = []
	for i in r:
		var zeile: PackedVector3Array = zeilen[i]
		var vorher: PackedVector3Array = zeilen[maxi(i - 1, 0)]
		var nachher: PackedVector3Array = zeilen[mini(i + 1, r - 1)]
		var reihe := PackedVector3Array()
		reihe.resize(c)
		for j in c:
			var jl := j - 1
			var jr := j + 1
			if ringsum:
				if jl < 0:
					jl = c - 2
				if jr > c - 1:
					jr = 1
			else:
				jl = maxi(jl, 0)
				jr = mini(jr, c - 1)
			var nn := (zeile[jr] - zeile[jl]).cross(nachher[j] - vorher[j])
			reihe[j] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.ZERO
		normalen.append(reihe)
	# Entartete Normalen (Spitzen) von der Nachbarzeile übernehmen.
	for i in r:
		var reihe: PackedVector3Array = normalen[i]
		for j in c:
			if reihe[j] == Vector3.ZERO:
				var ersatz := Vector3.UP
				if i > 0 and (normalen[i - 1] as PackedVector3Array)[j] != Vector3.ZERO:
					ersatz = (normalen[i - 1] as PackedVector3Array)[j]
				elif i < r - 1 and (normalen[i + 1] as PackedVector3Array)[j] != Vector3.ZERO:
					ersatz = (normalen[i + 1] as PackedVector3Array)[j]
				reihe[j] = ersatz
		normalen[i] = reihe
	g["n"] = normalen
	g["wenden"] = false
	neu_faerben(g, farbe, nord)


## Farben neu rechnen (nach `orientieren()`, falls die Farbe von der
## Normale abhängt).
static func neu_faerben(g: Dictionary, farbe: Callable, nord: float = 0.5) -> void:
	var zeilen: Array = g["p"]
	var normalen: Array = g["n"]
	var farben: Array = []
	var arten: Array = []
	for i in zeilen.size():
		var zeile: PackedVector3Array = zeilen[i]
		var reihe: PackedVector3Array = normalen[i]
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in zeile.size():
			var f: Color = farbe.call(zeile[j], reihe[j])
			fa.append(Color(clampf(f.r, 0.0, 1.0), clampf(f.g, 0.0, 1.0),
					clampf(f.b, 0.0, 1.0), clampf(f.a, 0.0, 1.0)))
			ar.append(Vector2(Riesenstamm.BORKE, nord))
		farben.append(fa)
		arten.append(ar)
	g["f"] = farben
	g["a"] = arten


## Dreht die Vorderseite eines gefärbten Gitters, wenn ihre Normalen im
## Mittel NICHT von `innen` wegzeigen. `innen`: Callable(zeile) -> Vector3,
## ein Punkt im Inneren der Zeile (Achse eines Strangs, Kern eines
## Querschnitts). Liefert true, wenn gedreht wurde.
static func orientieren(g: Dictionary, innen: Callable) -> bool:
	var zeilen: Array = g["p"]
	var normalen: Array = g["n"]
	var summe := 0.0
	for i in zeilen.size():
		var zeile: PackedVector3Array = zeilen[i]
		var reihe: PackedVector3Array = normalen[i]
		var kern: Vector3 = innen.call(i)
		for j in zeile.size():
			summe += reihe[j].dot(zeile[j] - kern)
	if summe >= 0.0:
		return false
	for i in normalen.size():
		var reihe: PackedVector3Array = normalen[i]
		for j in reihe.size():
			reihe[j] = -reihe[j]
		normalen[i] = reihe
	g["wenden"] = not bool(g.get("wenden", false))
	return true


## Schreibt die Zeilen `von` bis `bis` (einschließlich; -1 = bis zum Ende)
## eines gefärbten Gitters als Dreiecke. `filter(i, j) -> bool` darf Vierecke
## auslassen (etwa die Rückseite eines Strangs, die im Wurzelfleisch steckt
## und nie zu sehen ist).
static func gitter_schreiben(st: SurfaceTool, g: Dictionary, von: int = 0, bis: int = -1,
		filter: Callable = Callable()) -> void:
	var zeilen: Array = g["p"]
	if zeilen.size() < 2 or not g.has("n"):
		return
	var wenden: bool = g.get("wenden", false)
	var letzte := zeilen.size() - 1 if bis < 0 else mini(bis, zeilen.size() - 1)
	var erste := clampi(von, 0, letzte)
	var c := (zeilen[0] as PackedVector3Array).size()
	var mit_filter := filter.is_valid()
	for i in range(erste, letzte):
		for j in c - 1:
			if mit_filter and not bool(filter.call(i, j)):
				continue
			if wenden:
				_ecke(st, g, i, j)
				_ecke(st, g, i, j + 1)
				_ecke(st, g, i + 1, j)
				_ecke(st, g, i, j + 1)
				_ecke(st, g, i + 1, j + 1)
				_ecke(st, g, i + 1, j)
			else:
				_ecke(st, g, i, j)
				_ecke(st, g, i + 1, j)
				_ecke(st, g, i, j + 1)
				_ecke(st, g, i, j + 1)
				_ecke(st, g, i + 1, j)
				_ecke(st, g, i + 1, j + 1)


static func _ecke(st: SurfaceTool, g: Dictionary, i: int, j: int) -> void:
	st.set_color((g["f"][i] as PackedColorArray)[j])
	st.set_uv((g["uv"][i] as PackedVector2Array)[j])
	st.set_uv2((g["a"][i] as PackedVector2Array)[j])
	st.set_normal((g["n"][i] as PackedVector3Array)[j])
	st.add_vertex((g["p"][i] as PackedVector3Array)[j])


## Letzte (`ende` true) bzw. erste Zeile eines Gitters ohne die doppelte
## Nahtecke – für Bruchflächen und Deckel.
static func gitter_rand(g: Dictionary, ende: bool) -> PackedVector3Array:
	var zeilen: Array = g["p"]
	if zeilen.is_empty():
		return PackedVector3Array()
	var zeile: PackedVector3Array = zeilen[zeilen.size() - 1] if ende else zeilen[0]
	if bool(g["ringsum"]):
		return zeile.slice(0, zeile.size() - 1)
	return zeile


# ================================================================ Beiwerk

## Bruchfläche über einem geschlossenen Randring: faseriges helles Holz mit
## Splittern am Rand, zur Mitte hin eingesunken und morsch. `aussen` zeigt
## aus dem Holz heraus (die Bruchrichtung). Optionen:
##   splitter     größte Splitterlänge in m (1,35)
##   flach_ueber  Welt-Y: Randpunkte darüber bekommen höchstens 0,1 m –
##                an einer Sprunglippe täuschte ein langer Span sonst eine
##                kürzere Lücke vor
static func bruch_in(st: SurfaceTool, rand: PackedVector3Array, aussen: Vector3,
		rng: RandomNumberGenerator, optionen: Dictionary = {}) -> void:
	var n := rand.size()
	if n < 3:
		return
	var max_splitter: float = optionen.get("splitter", 1.35)
	var flach_ueber: float = optionen.get("flach_ueber", INF)
	var mitte := Vector3.ZERO
	for p in rand:
		mitte += p
	mitte /= float(n)
	var groesse := 0.0
	for p in rand:
		groesse = maxf(groesse, p.distance_to(mitte))
	var splitter := PackedVector3Array()
	var toene := PackedFloat32Array()
	for j in n:
		var p := rand[j]
		# Splitter: an wenigen Stellen ragt ein langer, dünner Span hinaus.
		var zacke := rng.randf()
		zacke = zacke * zacke * zacke
		var weit := minf(groesse * (0.02 + 0.12 * zacke), 0.25 + 1.1 * zacke)
		weit = minf(weit, max_splitter)
		if p.y > flach_ueber:
			weit = minf(weit, 0.1)
		splitter.append(p + aussen * weit + (mitte - p) * 0.06 * zacke)
		toene.append(rng.randf_range(0.82, 1.12))
	# Jahresringe: helle und dunkle Bänder, die zur Mitte hin einsinken –
	# ohne sie läse sich der Bruch als glattes Brett.
	var stufen := PackedFloat32Array([0.86, 0.7, 0.52, 0.34])
	var ringtoene := PackedFloat32Array([1.12, 0.68, 1.02, 0.6])
	var tiefe := minf(groesse * 0.09, 0.7)
	var ringe: Array[PackedVector3Array] = []
	for k in stufen.size():
		var ring := PackedVector3Array()
		for j in n:
			var f := stufen[k] * rng.randf_range(0.95, 1.05)
			ring.append(mitte + (rand[j] - mitte) * f
					- aussen * tiefe * ((0.3 + 0.25 * float(k)) * rng.randf_range(0.5, 1.0)
					+ rng.randf_range(-0.2, 0.2)))
		ringe.append(ring)
	var tief := mitte - aussen * minf(groesse * 0.12, 0.8)
	var art := Vector2(Riesenstamm.EIGEN, 0.0)
	var borke := Color(0.2, 0.14, 0.09)
	for j in n:
		var j2 := (j + 1) % n
		var a := HOLZ * toene[j]
		var b := HOLZ * toene[j2]
		# Rand (Borke) zum Splitter, Splitter zum ersten Ring.
		dreieck(st, rand[j], splitter[j], splitter[j2], aussen, borke, a * 0.8, b * 0.8, art)
		dreieck(st, rand[j], splitter[j2], rand[j2], aussen, borke, b * 0.8, borke, art)
		var aussen_ring := splitter
		var ton_vorher := 0.9
		for k in ringe.size():
			var innen_ring: PackedVector3Array = ringe[k]
			var ton := ringtoene[k]
			dreieck(st, aussen_ring[j], innen_ring[j], innen_ring[j2], aussen, a * ton_vorher,
					a * ton, b * ton, art)
			dreieck(st, aussen_ring[j], innen_ring[j2], aussen_ring[j2], aussen, a * ton_vorher,
					b * ton, b * ton_vorher, art)
			aussen_ring = innen_ring
			ton_vorher = ton
		dreieck(st, tief, aussen_ring[j2], aussen_ring[j], aussen, MORSCH, b * 0.45, a * 0.45, art)


## Ein Leuchtpilz wie `Riesenstamm.leuchtpilz_in`, aber mit gedämpfter Glut:
## Im Borkenstoff leuchtet die Scheitelfarbe mit dem Faktor 1,8. Mit voller
## Farbe brannte der Hut im Schatten der Kehle weiß aus; so bleibt er ein
## warmes Orange, das aus dem Dunkel eines Risses scheint.
static func leuchtpilz_in(st: SurfaceTool, ort: Vector3, groesse: float,
		rng: RandomNumberGenerator, glut_staerke: float = 0.5) -> void:
	var stiel_h := groesse * rng.randf_range(1.2, 2.2)
	var neig := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
	var hut := ort + neig * stiel_h
	var stiel := Color(0.62, 0.56, 0.44)
	var glut := Color(1.0, 0.55, 0.2).lerp(Color(1.0, 0.72, 0.32), rng.randf()) * glut_staerke
	const N := 6
	var a := neig.cross(Vector3.RIGHT).normalized()
	if a.length_squared() < 0.01:
		a = Vector3.FORWARD
	var b := neig.cross(a).normalized()
	var eigen := Vector2(Riesenstamm.EIGEN, 0.0)
	var leucht := Vector2(Riesenstamm.LEUCHT, 0.0)
	for k in N:
		var w0 := TAU * float(k) / float(N)
		var w1 := TAU * float(k + 1) / float(N)
		var d0 := a * cos(w0) + b * sin(w0)
		var d1 := a * cos(w1) + b * sin(w1)
		var s0 := ort + d0 * groesse * 0.22 - neig * 0.2
		var s1 := ort + d1 * groesse * 0.22 - neig * 0.2
		var t0 := hut + d0 * groesse * 0.16
		var t1 := hut + d1 * groesse * 0.16
		dreieck(st, s0, t0, t1, d0 + d1, stiel * 0.6, stiel, stiel, eigen)
		dreieck(st, s0, t1, s1, d0 + d1, stiel * 0.6, stiel, stiel * 0.6, eigen)
		var r0 := hut + d0 * groesse - neig * groesse * 0.25
		var r1 := hut + d1 * groesse - neig * groesse * 0.25
		var kuppe := hut + neig * groesse * 0.55
		dreieck(st, kuppe, r0, r1, neig + (d0 + d1) * 0.5, glut, glut * 0.75, glut * 0.75, leucht)
		dreieck(st, hut, r1, r0, -neig, glut * 0.6, glut * 0.7, glut * 0.7, leucht)


## Maserknolle: ein verbeulter, halb in die Unterlage gedrückter Buckel bei
## `mitte`, `aussen` zeigt von der Unterlage weg.
static func knolle_in(st: SurfaceTool, mitte: Vector3, aussen: Vector3, radius: float,
		rng: RandomNumberGenerator, moos: float = 0.5) -> void:
	var achse := aussen.normalized()
	var hilfe := Vector3.UP if absf(achse.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u := achse.cross(hilfe).normalized()
	var v := achse.cross(u)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = rng.randi()
	rauschen.frequency = 1.6 / maxf(radius, 0.1)
	const SEITEN := 12
	var breiten := PackedFloat32Array([1.12, 1.0, 0.86, 0.62, 0.3, 0.0])
	var g := {"p": [], "uv": [], "ringsum": true}
	var kerne := PackedVector3Array()
	for i in breiten.size():
		var b := breiten[i]
		var hoch := sqrt(maxf(0.0, 1.0 - minf(b, 1.0) * minf(b, 1.0))) * radius * 0.62
		if b > 1.0:
			hoch = -radius * 0.25
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		for j in SEITEN + 1:
			var a := TAU * float(j % SEITEN) / float(SEITEN)
			var richtung := u * cos(a) + v * sin(a)
			var p := mitte + richtung * b * radius + achse * hoch
			p += (p - mitte).normalized() * radius * 0.16 * rauschen.get_noise_3dv(p)
			zeile.append(p)
			uv.append(Vector2(float(j) / float(SEITEN) * 3.0, float(i) * 0.4))
		(g["p"] as Array).append(zeile)
		(g["uv"] as Array).append(uv)
		kerne.append(mitte - achse * radius * 0.3)
	var knollenfarbe := func(p: Vector3, n: Vector3) -> Color:
		var ao := lerpf(0.55, 1.0, clampf((p - mitte).dot(achse) / (radius * 0.5), 0.0, 1.0))
		return Color(ao, ao, ao, moos * clampf(n.y + 0.2, 0.0, 1.0))
	gitter_faerben(g, knollenfarbe, 0.5)
	orientieren(g, func(i: int) -> Vector3: return kerne[i])
	neu_faerben(g, knollenfarbe, 0.5)
	gitter_schreiben(st, g)


## Ein Dreieck mit eigener Farbe je Ecke und Vorderseite nach `aussen`
## (Flächennormale, UV planar aus der Lage – damit die Tangenten nie
## entarten). Farbe ohne Moos.
static func dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color, art: Vector2) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var pb := b
	var pc := c
	var fbb := fb
	var fcc := fc
	# Vorderseite: cross(b-a, c-a) zeigt ENTGEGEN der Außenrichtung.
	if kreuz.dot(aussen) > 0.0:
		pb = c
		pc = b
		fbb = fc
		fcc = fb
		kreuz = -kreuz
	var n := -kreuz.normalized()
	for e in 3:
		var p := a if e == 0 else (pb if e == 1 else pc)
		var f := fa if e == 0 else (fbb if e == 1 else fcc)
		st.set_color(Color(clampf(f.r, 0.0, 1.0), clampf(f.g, 0.0, 1.0),
				clampf(f.b, 0.0, 1.0), 0.0))
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 0.5)
		st.set_uv2(art)
		st.set_normal(n)
		st.add_vertex(p)


# ================================================================ Stoffe

static var _torstoff: ShaderMaterial = null
static var _torshader: Shader = null

## Borke des Stamms in Weltprojektion (senkrechte Furchen, keine Nähte
## zwischen Stamm, Brettwurzeln und Ästen). `fern`: dunkler und kühler, mit
## Moosstreifen – eine Silhouette, die sich vom Dunst abhebt. Die Vorgabe
## der Fernborke (×0,6) stand vom Grat aus (150 m, 70 % Dunst) noch so hell
## wie der Dunst selbst; hier ist sie rund ein Drittel so hell.
static func stoff_stamm(fern: bool = false) -> ShaderMaterial:
	if fern:
		return Riesenstamm.borkenstoff({"welt": true, "radius": 12.0, "fern": true,
				"farbe": Color(0.2, 0.21, 0.24), "moos_farbe": Color(0.3, 0.36, 0.38)})
	return Riesenstamm.borkenstoff({"welt": true, "radius": 12.0})


## Borke der Wurzeln über UV: Die Furchen laufen den Strängen entlang, nicht
## senkrecht wie in der Weltprojektion. Moos nur mäßig nach oben – mit voller
## Stärke lag auf jedem Strang ein grüner Teppich, und die Kehle las sich als
## Stapel bemooster Schläuche. Das Moos setzt die Scheitelfarbe (Risse,
## Flecken).
static func stoff_wurzel() -> ShaderMaterial:
	return Riesenstamm.borkenstoff({"moos_oben": 0.3, "moos_nord": 0.25, "flechten": 0.5})


## Borke des Kronentors: dunkel im Gegenlicht, mit warmem Saum am Umriss.
## Das Tor steht vor dem hellen Taldunst und soll sich dort als Rahmen
## lesen, nicht als Loch. Ein eigener Shader aus `Riesenstamm.BORKE_SHADER`
## (UV-Fassung) mit Randlicht. Geteilt – nie verändern.
static func stoff_tor() -> ShaderMaterial:
	if _torstoff != null:
		return _torstoff
	const ALT := "EMISSION = COLOR.rgb * 1.8 * step(1.5, art);"
	var code := Riesenstamm.BORKE_SHADER
	if not code.contains(ALT):
		push_warning("Weltenbaum.stoff_tor: Borkenshader verändert, das Tor bleibt ohne Randlicht.")
	code = code.replace("uniform float relief = 0.6;",
			"uniform float relief = 0.6;\nuniform vec4 saum_farbe : source_color = vec4(1.0, 0.68, 0.36, 1.0);\nuniform float saum_staerke = 0.55;")
	code = code.replace(ALT, ALT + """
	// Randlicht: warm am Umriss, nur auf Borke. Nach oben stärker – dort
	// fängt das Tor den Taldunst im Gegenlicht.
	float saum = pow(1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0), 4.0);
	EMISSION += saum_farbe.rgb * saum_staerke * saum * borke * (0.6 + 0.4 * clamp(wn.y + 0.5, 0.0, 1.0));""")
	_torshader = Shader.new()
	_torshader.code = code
	_torstoff = ShaderMaterial.new()
	_torstoff.shader = _torshader
	var rinde := Materialbibliothek.rinde()
	_torstoff.set_shader_parameter("rinde", rinde.albedo_texture)
	_torstoff.set_shader_parameter("rinde_normal", rinde.normal_texture)
	_torstoff.set_shader_parameter("moos", Riesenstamm.moostextur())
	_torstoff.set_shader_parameter("borke_farbe", Color(0.62, 0.56, 0.5))
	_torstoff.set_shader_parameter("moos_farbe", Color(0.78, 0.84, 0.78))
	_torstoff.set_shader_parameter("moos_oben", 0.7)
	_torstoff.set_shader_parameter("moos_nord", 0.3)
	_torstoff.set_shader_parameter("flechten", 0.4)
	return _torstoff


## Stoff des Kronenschirms: nah beidseitig mit Lücken im Laub, fern nur
## Vorderseiten (siehe `Kronenwolke.stoff`).
static func stoff_krone(fern: bool = false) -> ShaderMaterial:
	if fern:
		return Kronenwolke.stoff(FARBE_KRONE_FERN, false)
	return Kronenwolke.stoff(FARBE_KRONE)
