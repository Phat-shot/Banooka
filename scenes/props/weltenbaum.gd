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
## * `bruch_in()` (Bruchfläche, die heraussteht: Faserkamm, Borkensaum,
##   Jahresringe um ein verschobenes Mark), `brettwurzel_in()` (Brettwurzel
##   als dünne Finne), `konsolen_in()` (Konsolenpilze in Stufen),
##   `knolle_in()` (Maserknolle), `leuchtpilz_in()` (Leuchtpilz mit
##   gedämpfter Glut für den Borkenstoff).
## * Eigenfarben (UV2.x ≥ 0,5) sind LINEAR: Der Borkenstoff nimmt sie als
##   ALBEDO = COLOR.rgb. Als sRGB-Werte gewählt, erschienen sie viel zu hell
##   (Bruchflächen wie Pappe).
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
## weit im Dunst und soll dort dunkler als der Dunst UND als die Hügel
## davor bleiben. Mit 0,085/0,18/0,09 und dem vollen Durchlicht der
## Kronenwolke stand sie dort als blasser Scherenschnitt, heller als die
## Hügel; jetzt ×0,7 und mit dunklem Unterband (`stoff_krone`).
const FARBE_KRONE_FERN := Color(0.06, 0.126, 0.063)
## Borke der Fernfassung (Stamm, Kehle): kühl und dunkel.
const FARBE_STAMM_FERN := Color(0.14, 0.15, 0.17)

## Farben der Bruchflächen: faseriges Holz, innen morsch. LINEAR – der
## Borkenstoff zeichnet Eigenfarbe als ALBEDO = COLOR.rgb. Als sRGB-Werte
## gewählt (0,5/0,37/0,23) erschienen sie als helles Pappbraun (sRGB
## ≈ 0,73/0,64/0,52); so sind es rund 0,56/0,44/0,29.
const HOLZ := Color(0.27, 0.16, 0.07)
const MORSCH := Color(0.03, 0.02, 0.012)
## Dunkle Borke am Rand eines Bruchs (linear).
const BRUCH_BORKE := Color(0.035, 0.022, 0.013)


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
			# Unten zwischen den Finnen tief dunkel: Die Spalten sollen sich als
			# Spalten lesen.
			var ao := lerpf(0.2, 1.0, smoothstep(y_boden - 0.5, y_boden + 6.0, yy)) \
					* lerpf(0.72, 1.0, smoothstep(y_boden + 6.0, y_boden + 14.0, yy))
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
		brettwurzel_in(st, Vector3(0.0, fuss, 0.0), float(w["winkel"]),
				profil_radius(profil, fuss + 1.0), float(w["reichweite"]), float(w["hoehe"]),
				float(w["dicke"]), float(w.get("schlange", rng.randf_range(-0.35, 0.35))),
				rauschen)

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
		# Eine Stufe aus 3–7 Konsolen, 0,6–1,2 m breit (`konsolen_in`).
		var ort := auf_borke(profil, w, y0, 0.05)
		konsolen_in(st, ort, Vector3(cos(w), 0.0, -sin(w)), clampf(breite * 0.62, 0.6, 1.2),
				rng.randi_range(3, 7), rng)

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


## Eine Brettwurzel als FINNE: dünn und hoch, im Querschnitt ein Dreieck –
## oben 0,5–0,9 m, am Fuß 2–3 m –, die Oberkante fällt in einem langen,
## hohlen Bogen von `hoehe` am Stamm bis unter den Boden bei `reichweite`
## und schlängelt sich dabei. Die `Riesenstamm`-Brettwurzel (Querschnitt
## gewölbt, am Fuß 1,6-mal so dick) las sich im Maß des Riesen als dicke
## Kissen, die am Stamm lehnen. Der Fuß taucht 1 m in den Boden, die
## Flanken werden nach unten sehr dunkel (die Spalten zwischen den Finnen),
## auf dem Grat wächst Moos. `schlicht`: wenige Ecken (Ferne, Schatten).
static func brettwurzel_in(st: SurfaceTool, mitte: Vector3, winkel: float, r_stamm: float,
		reichweite: float, hoehe: float, dicke: float, schlange: float,
		rauschen: FastNoiseLite, schlicht: bool = false) -> void:
	var stationen := 7 if schlicht else 14
	var v_werte := PackedFloat32Array([-0.12, 0.3, 0.62, 0.86, 1.0]) if schlicht \
			else PackedFloat32Array([-0.12, 0.12, 0.34, 0.55, 0.74, 0.88, 0.97, 1.0])
	var fuss_breite := dicke * 1.25
	var grat_breite := clampf(dicke * 0.34, 0.5, 0.9)
	var r0 := r_stamm * 0.82
	var r1 := r_stamm + reichweite
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var massstab := Riesenstamm.borkenmass(r_stamm)
	for i in stationen:
		var s := float(i) / float(stationen - 1)
		var rho := lerpf(r0, r1, s)
		var w := winkel + (schlange * sin(s * PI * 1.4) + 0.12 * sin(s * 9.0 + winkel * 3.0)) \
				* reichweite / maxf(rho, 0.1) * 0.35
		var er := Vector3(cos(w), 0.0, -sin(w))
		var et := Vector3(-sin(w), 0.0, -cos(w))
		# Oberkante: hohler Bogen, die Spitze taucht 0,6 m ein.
		var grat := hoehe * pow(1.0 - s, 1.35) * (1.0 + 0.05 * sin(s * 11.0 + winkel)) - 0.6 * s * s
		var unten := -1.0
		var fb := fuss_breite * (1.0 - 0.55 * s)
		var gb := grat_breite * (1.0 - 0.45 * s)
		var basis := mitte + er * rho
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		var bogen := 0.0
		var vorher := Vector3.ZERO
		# Von der Flanke auf +et über den Grat zur anderen: die Werte `v`
		# vorwärts, dann rückwärts (ohne den Grat doppelt). Die Reihenfolge
		# legt die Vorderseite nach außen (wie `Riesenstamm.brettwurzel_in`).
		var folge: Array[Vector2] = []
		for k in v_werte.size():
			folge.append(Vector2(v_werte[k], 1.0))
		for k in range(v_werte.size() - 2, -1, -1):
			folge.append(Vector2(v_werte[k], -1.0))
		for f in folge:
			var v := f.x
			var seite := f.y
			var yy := lerpf(unten, grat, clampf(v, 0.0, 1.0)) + minf(v, 0.0) * 2.0
			# Dreieckig mit leicht hohlen Flanken; oben rund.
			var halb := 0.5 * (gb + (fb - gb) * pow(1.0 - clampf(v, 0.0, 1.0), 1.5))
			if v >= 0.999:
				halb = gb * 0.18
			var beule := 1.0 + 0.18 * rauschen.get_noise_3d(basis.x * 0.6, yy * 0.5, basis.z * 0.6 + seite)
			var p := basis + Vector3.UP * yy + et * seite * halb * beule
			if v >= 0.999:
				p += Vector3.UP * gb * 0.12
			if bogen == 0.0 and zeile.is_empty():
				vorher = p
			bogen += p.distance_to(vorher)
			vorher = p
			zeile.append(p)
			uv.append(Vector2(bogen * Riesenstamm.KACHEL_U, rho * Riesenstamm.KACHEL_V * 2.5) * massstab)
			# Tief unten in der Spalte fast schwarz, am Grat voll.
			var ao := lerpf(0.22, 1.0, smoothstep(-0.2, 0.85, v)) * lerpf(0.75, 1.0, smoothstep(0.0, 0.4, s))
			var moos := 0.15 + 0.75 * smoothstep(0.8, 1.0, v) + 0.35 * (1.0 - smoothstep(0.0, 0.25, v))
			moos += 0.25 * rauschen.get_noise_3d(p.x * 1.3, p.y * 1.3, p.z * 1.3)
			fa.append(Color(ao, ao, ao, clampf(moos, 0.0, 1.0)))
			ar.append(Vector2(Riesenstamm.BORKE, 0.8))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, false)


## Konsolenpilze in Stufen: `anzahl` Konsolen (3–7) übereinander, leicht
## versetzt, je 0,6–1,2 m breit und 0,15–0,3 m dick – im Maß des Riesen,
## dicker als die Blätter aus `Riesenstamm`, die sich als Papier lasen.
## Oben gezont (dunkel am Stamm, ocker, cremefarbener Rand), die Unterseite
## dunkler, damit die Konsole von unten Masse hat. `aussen` zeigt vom Stamm
## weg. Farben linear.
static func konsolen_in(st: SurfaceTool, ort: Vector3, aussen: Vector3, breite: float,
		anzahl: int, rng: RandomNumberGenerator) -> void:
	var er := Vector3(aussen.x, 0.0, aussen.z).normalized()
	var et := Vector3.UP.cross(er).normalized()
	var y := 0.0
	var seit := 0.0
	for n in anzahl:
		var b := clampf(breite * rng.randf_range(0.7, 1.1) * lerpf(1.0, 0.7, float(n) / 6.0), 0.5, 1.2)
		var p := ort + Vector3.UP * y + et * seit
		_konsole_in(st, p, er, et, b, rng)
		y += rng.randf_range(0.28, 0.48)
		seit += rng.randf_range(-0.25, 0.25) * b


static func _konsole_in(st: SurfaceTool, ort: Vector3, er: Vector3, et: Vector3, breite: float,
		rng: RandomNumberGenerator) -> void:
	var tiefe := breite * rng.randf_range(0.55, 0.75)
	var dick := rng.randf_range(0.15, 0.3)
	const K := 7
	var rand_oben := PackedVector3Array()
	var rand_unten := PackedVector3Array()
	var ring := PackedVector3Array()
	var welle := rng.randf() * TAU
	for k in K + 1:
		var a := lerpf(-PI * 0.5, PI * 0.5, float(k) / float(K))
		var w := 1.0 + 0.09 * sin(a * 5.0 + welle)
		var rp := ort + et * sin(a) * breite * 0.5 * w + er * (cos(a) * tiefe * w)
		rand_oben.append(rp + Vector3.UP * dick * 0.1)
		rand_unten.append(rp - Vector3.UP * dick * 0.35)
		ring.append(ort + (rp - ort) * 0.6 + Vector3.UP * dick * 0.75)
	var kopf := ort + Vector3.UP * dick * 0.95 - er * 0.05
	var bauch := ort - Vector3.UP * dick * 0.5 + er * tiefe * 0.25
	var dunkel := Color(0.05, 0.028, 0.012)
	var ocker := Color(0.3, 0.12, 0.03) * rng.randf_range(0.8, 1.1)
	var creme := Color(0.5, 0.34, 0.13)
	var unten_farbe := Color(0.1, 0.075, 0.045)
	var art := Vector2(Riesenstamm.EIGEN, 0.0)
	for k in K:
		dreieck(st, kopf, ring[k], ring[k + 1], Vector3.UP + er * 0.3, dunkel, ocker, ocker, art)
		dreieck(st, ring[k], rand_oben[k], rand_oben[k + 1], Vector3.UP + er * 0.5, ocker, creme,
				creme, art)
		dreieck(st, ring[k], rand_oben[k + 1], ring[k + 1], Vector3.UP + er * 0.5, ocker, creme,
				ocker, art)
		var raus := (rand_oben[k] + rand_oben[k + 1]) * 0.5 - ort
		dreieck(st, rand_oben[k], rand_unten[k], rand_unten[k + 1], raus, creme * 0.8,
				unten_farbe, unten_farbe, art)
		dreieck(st, rand_oben[k], rand_unten[k + 1], rand_oben[k + 1], raus, creme * 0.8,
				unten_farbe, creme * 0.8, art)
		dreieck(st, bauch, rand_unten[k + 1], rand_unten[k], Vector3.DOWN, unten_farbe * 0.6,
				unten_farbe, unten_farbe, art)


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
		# Schmal und schwach: Die Finne soll aus dem Stamm wachsen, nicht
		# in einem Polster, das die Spalten zwischen den Finnen füllt.
		summe += float(w["reichweite"]) * 0.07 * exp(-(d * d) / 0.005) * f * f
	return summe


## Dieselbe Säule schlicht: wenige Ecken, keine Rippen, keine Pilze – für
## die Ferne (ab 110 m) und als Schattenwerfer. Optionen wie `stamm_in`,
## dazu "seiten" (24), "ring_abstand" (5), "schrumpfen" (Faktor auf den
## Radius: Die Fernfassung liegt knapp INNERHALB der nahen, damit beim
## Wechsel keine Fläche in der anderen flackert). Äste mit 6 Ecken, ohne
## Zweige. Brettwurzeln nur mit "mit_wurzeln". Ein Ast mit "weglassen"
## wird gerechnet, aber nicht gezeichnet (die übrigen bleiben gleich
## gewürfelt) – für einen Schattenkörper, der einen Ast auslässt.
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
			brettwurzel_in(st, Vector3(0.0, fuss, 0.0), float(w["winkel"]),
					profil_radius(profil, fuss + 1.0) * schrumpfen,
					float(w["reichweite"]) * schrumpfen, float(w["hoehe"]) * schrumpfen,
					float(w["dicke"]) * schrumpfen, float(w.get("schlange", 0.0)), rauschen, true)
	for a: Dictionary in o.get("aeste", []):
		var fern := a.duplicate()
		fern["zweige"] = 0
		fern["seiten"] = 6
		fern["stuecke"] = 4
		fern["radius"] = float(a.get("radius", 2.4)) * schrumpfen
		var ziel := st
		if bool(a.get("weglassen", false)):
			ziel = SurfaceTool.new()
			ziel.begin(Mesh.PRIMITIVE_TRIANGLES)
		ast_in(ziel, fern, profil, rng)


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

## Bruchfläche über einem geschlossenen Randring: gebrochenes Holz, das
## HERAUSSTEHT, statt einzusinken. Die alte Fassung (vier Ringstufen bis
## 0,7 m tief, die Mitte 0,8 m) las sich aus der Spielkamera als Inneres
## einer Pappschachtel. Jetzt, von außen nach innen:
## * ein Kamm aus Faserspänen, 0,2 bis `splitter` Meter hinaus in die
##   Bruchrichtung, lang und kurz im Wechsel – nur unterhalb der oberen
##   0,3 m (`flach_ueber`): Die Sprunglippe bleibt glatt, ein langer Span
##   dort täuschte eine kürzere Lücke vor;
## * ein dunkler Borkensaum, 0,2 m breit, der ein wenig vorsteht;
## * die Fläche mit neun unruhigen Jahresringen um ein Mark, das NICHT in
##   der Mitte liegt, höchstens 0,15 m eingesunken;
## * ein nasser, dunkler Kern um das Mark;
## * Moospolster an den untersten Randstellen.
## `aussen` zeigt aus dem Holz heraus (die Bruchrichtung). Optionen:
##   splitter     größte Spanlänge in m (0,8)
##   flach_ueber  Welt-Y: Randpunkte darüber bekommen höchstens 0,05 m Span
##   moos         Moospolster am Fuß (true)
## Farben linear (Eigenfarbe, siehe HOLZ).
static func bruch_in(st: SurfaceTool, rand_roh: PackedVector3Array, aussen: Vector3,
		rng: RandomNumberGenerator, optionen: Dictionary = {}) -> void:
	var n0 := rand_roh.size()
	if n0 < 3:
		return
	var max_splitter: float = optionen.get("splitter", 0.8)
	var flach_ueber: float = optionen.get("flach_ueber", INF)
	var mit_moos: bool = optionen.get("moos", true)
	aussen = aussen.normalized()
	# Der Rand fein genug für einen Kamm: höchstens 0,3 m je Zahn.
	var rand := PackedVector3Array()
	for j in n0:
		var a := rand_roh[j]
		var b := rand_roh[(j + 1) % n0]
		var teile := maxi(1, ceili(a.distance_to(b) / 0.3))
		for k in teile:
			rand.append(a.lerp(b, float(k) / float(teile)))
	var n := rand.size()
	var mitte := Vector3.ZERO
	var unten := INF
	var oben := -INF
	for p in rand:
		mitte += p
		unten = minf(unten, p.y)
		oben = maxf(oben, p.y)
	mitte /= float(n)
	var groesse := 0.0
	for p in rand:
		groesse = maxf(groesse, p.distance_to(mitte))
	# Das Mark: aus der Mitte zum Rand hin verschoben, wie bei gewachsenem
	# Holz (die Jahresringe sind auf einer Seite enger).
	var mark := mitte.lerp(rand[rng.randi() % n], rng.randf_range(0.22, 0.4))
	var art := Vector2(Riesenstamm.EIGEN, 0.0)
	var borke := BRUCH_BORKE
	var kamm_grenze := minf(flach_ueber, oben - 0.3)

	# Borkensaum: 0,2 m breit (höchstens ein Viertel des Weges zum Mark),
	# 3 cm vorstehend.
	var saum := PackedVector3Array()
	for j in n:
		var zum_mark := mark - rand[j]
		var d := zum_mark.length()
		var f := minf(0.2 / maxf(d, 0.01), 0.25)
		saum.append(rand[j] + zum_mark * f + aussen * 0.03)
	for j in n:
		var j2 := (j + 1) % n
		dreieck(st, rand[j], saum[j], saum[j2], aussen, borke * 0.8, borke, borke, art)
		dreieck(st, rand[j], saum[j2], rand[j2], aussen, borke * 0.8, borke, borke * 0.8, art)

	# Jahresringe: neun unruhige Ringe vom Saum zum Mark, hell und dunkel im
	# Wechsel, zur Mitte hin enger und dunkler (nass), leicht eingesunken.
	var rauschen := FastNoiseLite.new()
	rauschen.seed = rng.randi()
	rauschen.frequency = 0.9
	var anteile := PackedFloat32Array([0.93, 0.84, 0.74, 0.64, 0.53, 0.42, 0.31, 0.21, 0.11])
	var aussen_ring := saum
	var ton_vorher := 1.0
	for k in anteile.size():
		var f := anteile[k]
		var ring := PackedVector3Array()
		var tiefe := 0.15 * (1.0 - f) * (1.0 - f) * 1.6
		for j in n:
			var p := saum[j]
			var wackeln := 1.0 + 0.07 * rauschen.get_noise_2d(float(j) * 0.9, float(k) * 3.1)
			ring.append(mark + (p - mark) * clampf(f * wackeln, 0.02, 0.98) - aussen * minf(tiefe, 0.15))
		var hell := k % 2 == 0
		var ton := (1.08 if hell else 0.74) * lerpf(0.55, 1.0, smoothstep(0.1, 0.5, f))
		for j in n:
			var j2 := (j + 1) % n
			var fa := HOLZ * ton_vorher * _holzkorn(rng)
			var fb := HOLZ * ton * _holzkorn(rng)
			dreieck(st, aussen_ring[j], ring[j], ring[j2], aussen, fa, fb, fb, art)
			dreieck(st, aussen_ring[j], ring[j2], aussen_ring[j2], aussen, fa, fb, fa, art)
		aussen_ring = ring
		ton_vorher = ton
	# Der nasse Kern um das Mark.
	var kern := mark - aussen * 0.15
	for j in n:
		var j2 := (j + 1) % n
		dreieck(st, kern, aussen_ring[j2], aussen_ring[j], aussen, MORSCH,
				HOLZ * ton_vorher * 0.6, HOLZ * ton_vorher * 0.6, art)

	# Der Kamm aus Faserspänen: je Randstelle ein Keil mit zwei Seiten, lang
	# und kurz im Wechsel, spitz zulaufend.
	for j in n:
		var j2 := (j + 1) % n
		var a := rand[j]
		var b := rand[j2]
		if maxf(a.y, b.y) > kamm_grenze:
			continue
		var lang := j % 2 == 0
		var weit := rng.randf_range(0.45, 1.0) * max_splitter if lang \
				else rng.randf_range(0.2, 0.45) * max_splitter * 0.7
		weit = maxf(weit, 0.12)
		var basis := (a + b) * 0.5
		var zur_mitte := (mark - basis).normalized()
		var spitze := basis + aussen * weit + zur_mitte * weit * rng.randf_range(0.05, 0.25) \
				+ Vector3.DOWN * weit * rng.randf_range(0.0, 0.2)
		var innen_a := a + zur_mitte * 0.07
		var innen_b := b + zur_mitte * 0.07
		var raus := (basis - mark).normalized()
		var hell := HOLZ * rng.randf_range(0.95, 1.2)
		dreieck(st, a, b, spitze, raus + aussen * 0.3, borke, borke, hell, art)
		dreieck(st, innen_a, innen_b, spitze, -raus + aussen * 0.3, HOLZ * 0.5, HOLZ * 0.5,
				hell, art)

	# Moospolster an den untersten Randstellen: kleine grüne Fächer, die über
	# den Rand hängen.
	if mit_moos:
		var hoehe := maxf(oben - unten, 0.1)
		for j in n:
			var p := rand[j]
			if (p.y - unten) / hoehe > 0.22 or rng.randf() < 0.35:
				continue
			var raus := (p - mark).normalized()
			var gruen := Color(0.045, 0.085, 0.02).lerp(Color(0.085, 0.13, 0.03), rng.randf())
			for f in rng.randi_range(3, 5):
				var richtung := (raus * rng.randf_range(0.3, 1.0) + aussen * rng.randf_range(0.2, 0.8)
						+ Vector3.DOWN * rng.randf_range(0.2, 0.9)).normalized()
				var laenge := rng.randf_range(0.18, 0.42)
				var quer := richtung.cross(aussen).normalized() * laenge * 0.28
				dreieck(st, p - quer, p + quer, p + richtung * laenge, aussen, gruen * 0.6,
						gruen * 0.6, gruen, art)


## Faserkorn: ein leises Zittern der Holzfarbe je Ecke.
static func _holzkorn(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(0.9, 1.08)


## Ein Leuchtpilz wie `Riesenstamm.leuchtpilz_in`, aber mit gedämpfter Glut:
## Im Borkenstoff leuchtet die Scheitelfarbe mit dem Faktor 1,8. Mit voller
## Farbe brannte der Hut im Schatten der Kehle weiß aus; so bleibt er ein
## warmes Orange, das aus dem Dunkel eines Risses scheint.
static func leuchtpilz_in(st: SurfaceTool, ort: Vector3, groesse: float,
		rng: RandomNumberGenerator, glut_staerke: float = 0.5) -> void:
	var stiel_h := groesse * rng.randf_range(1.2, 2.2)
	var neig := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
	var hut := ort + neig * stiel_h
	# Linear (Eigenfarbe): sRGB ≈ 0,62/0,56/0,44, ein blasser Stiel.
	var stiel := Color(0.34, 0.27, 0.16)
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
				"farbe": FARBE_STAMM_FERN, "moos_farbe": Color(0.22, 0.27, 0.29)})
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
			"uniform float relief = 0.6;\nuniform vec4 saum_farbe : source_color = vec4(1.0, 0.68, 0.36, 1.0);\nuniform float saum_staerke = 0.25;")
	code = code.replace(ALT, ALT + """
	// Randlicht: warm am Umriss, nur auf Borke, nur auf der Oberseite und
	// nur aus der Nähe. Ohne diese Grenzen waren dünne Stränge aus 100 m
	// ganz Umriss und hingen als blasse Geistervorhänge im Dunst, und aus
	// der Nähe hatten schwarze Stöcke rundum einen orangen Rand.
	float saum = pow(1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0), 4.0);
	saum *= (1.0 - smoothstep(25.0, 60.0, length(VERTEX))) * smoothstep(-0.1, 0.7, wn.y);
	EMISSION += saum_farbe.rgb * saum_staerke * saum * borke;""")
	_torshader = Shader.new()
	_torshader.code = code
	_torstoff = ShaderMaterial.new()
	_torstoff.shader = _torshader
	var rinde := Materialbibliothek.rinde()
	_torstoff.set_shader_parameter("rinde", rinde.albedo_texture)
	_torstoff.set_shader_parameter("rinde_normal", rinde.normal_texture)
	_torstoff.set_shader_parameter("moos", Riesenstamm.moostextur())
	# Heller als zuvor (0,62/0,56/0,5): Im Gegenlicht soll die Rinde noch
	# als Rinde lesen, jetzt, da der Saum sie nicht mehr überstrahlt.
	_torstoff.set_shader_parameter("borke_farbe", Color(0.8, 0.72, 0.64))
	_torstoff.set_shader_parameter("moos_farbe", Color(0.78, 0.84, 0.78))
	_torstoff.set_shader_parameter("moos_oben", 0.7)
	_torstoff.set_shader_parameter("moos_nord", 0.3)
	_torstoff.set_shader_parameter("flechten", 0.4)
	return _torstoff


static var _krone_fern: ShaderMaterial = null

## Stoff des Kronenschirms: nah beidseitig mit Lücken im Laub, fern nur
## Vorderseiten (siehe `Kronenwolke.stoff`). Die Fernfassung ist eine
## eigene Abschrift des Kronenstoffs (der geteilte bleibt unberührt) mit
## wenig Durchlicht und dunkler, kühler Unterseite: Vom Grat aus soll der
## Schirm eine dunkle Masse mit dunklem Unterband sein, kein blasser Fleck.
static func stoff_krone(fern: bool = false) -> ShaderMaterial:
	if fern:
		if _krone_fern == null:
			_krone_fern = Kronenwolke.stoff(FARBE_KRONE_FERN, false).duplicate() as ShaderMaterial
			_krone_fern.set_shader_parameter("durchlicht", 0.1)
			_krone_fern.set_shader_parameter("ton_unten", Vector3(0.24, 0.25, 0.42))
		return _krone_fern
	return Kronenwolke.stoff(FARBE_KRONE)
