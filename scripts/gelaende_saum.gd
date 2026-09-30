extends RefCounted
class_name GelaendeSaum
## Kanten und Felswände als modellierte Profile (Plan Abschnitt 8.3).
##
## Die alten Schluchtwände waren Stapel aus Würfeln; aus der Spielkamera
## lasen sie sich als Kistenwand, und jede Lippe als grüner Bordstein. Hier
## entsteht eine Kante als QUERSCHNITT-SWEEP: Eine Linie (Lippe oder Fuß)
## läuft den Weg entlang, und an jeder Probe der Linie steht ein Profil aus
## 20–40 Punkten – Grasnarbe, Überhang, Schichtfels, Simse, Fuß. Die Punkte
## benachbarter Proben werden zu einem Gitter verbunden. Weil jede Kante
## EIN Gitter ist, gibt es keine Fugen, keine Blöcke und keine Nähte, und
## ein Stück zu 30 m kostet einen Zeichenaufruf.
##
## BAUSTEINE (alle statisch, ohne Zustand außer den Merkern unten):
##   `linie()`       tastet eine Linie in Wegkoordinaten (s, q) nach Bogen-
##                   länge in Welt-XZ ab, genau an festen Strecken (Stufen,
##                   Lückenränder). Vorsprünge und Buchten sind nur andere
##                   Linien – das Profil läuft um sie herum.
##   `glaetten()`    je Fensterbreite eine geglättete Fassung der Linie samt
##                   Normalen: Tiefere Profilpunkte folgen einer glatteren
##                   Linie. So wird ein Sporn nach unten zum Pfeiler, statt
##                   als Blech bis zum Fuß hinabzureichen.
##   `Profil`        die Punkte eines Querschnitts: Versatz nach außen (oder
##                   absolutes q), Welt-Y, Scheitelfarbe (siehe Stoff),
##                   Glättung, Rauschstärke und -richtung.
##   `querschnitte()` setzt die Profile an die Proben, verschiebt sie mit
##                   CPU-3D-Rauschen entlang der Normale (Richtung 1 frei,
##                   −1 nur nach innen – unter einer Lippe darf nie Fels
##                   hervortreten, in den eine fallende Figur hineinfiele)
##                   und mit den Schichtbändern, rechnet die Verdeckung.
##   `gitter_schreiben()` Gitter → Dreiecke mit glatten Normalen; in Stücke
##                   geschnitten, die sich die Randreihe teilen.
##   `deckel()`      schließt ein offenes Ende (Querschnitt als Vieleck).
##   `stein()`       ein verbeulter, halb versenkter Stein im selben Format.
##   `karte()`       Wurzel- und Halmkarten (Alpha-Scissor) unter der Lippe.
##
## STOFF: `shaders/fels_schichten.gdshader` (`stoff()`), Scheitelformat dort
## beschrieben: COLOR = (Verdeckung, Erde, Moos, Rasen), UV2 = (Kronenlicht,
## Tiefe unter der Wegkante). Keine Schatten: Die Kanten sind Gelände, und
## jede Schattenstufe kostete je Stück einen weiteren Zeichenaufruf.
##
## ABFRAGE: `flaeche_punkt(s, seite, hoehe)` liefert einen Punkt auf der
## zuletzt gebauten Fläche einer Seite (für Wasserfälle, die an der Wand
## hinablaufen). Die Querschnitte dazu merkt sich `merken()`.
##
## KOLLISION baut der Saum keine. Die Lippe IST die Kollisionskante (die
## Linie, die der Aufrufer übergibt); über sie hinaus darf nur Gras ragen.

## Wiederholungen der Schichtbänder je Meter Welt-Y (wie im Stoff).
const SCHICHT_DICHTE := 0.35
## Neigung der Bänder (tan je Achse, 3–6°), wie im Stoff.
const SCHICHT_NEIGUNG := Vector2(0.062, -0.041)
## Fensterbreiten der geglätteten Linien (m).
const FENSTER: Array[float] = [0.0, 0.8, 1.6, 3.0, 5.0]
## Ränder der Karten im Atlas: links Wurzeln, rechts Halme.
const ATLAS_WURZEL := Vector2(0.0, 0.5)
const ATLAS_HALM := Vector2(0.5, 1.0)

const STOFF_SHADER := preload("res://shaders/fels_schichten.gdshader")

static var _rauschen: FastNoiseLite = null
static var _zellen: FastNoiseLite = null
static var _stoff: ShaderMaterial = null
static var _kartenstoff: StandardMaterial3D = null
## Merker für `flaeche_punkt`: Seite (−1/1) → {"s", "boden", "reihen"}.
static var _flaechen := {}


# ================================================================ Profil

## Die Punkte eines Querschnitts, von innen (Weg) nach außen/unten bzw. oben.
## Alle Profile eines Zuges haben gleich viele Punkte – sonst ließen sie sich
## nicht zu einem Gitter verbinden.
class Profil:
	extends RefCounted
	## Versatz entlang der Normale der Linie (m, positiv = vom Weg weg) –
	## oder ein absolutes q (Wegkoordinate), wenn `absolut` gesetzt ist.
	var o := PackedFloat32Array()
	## Welt-Y.
	var y := PackedFloat32Array()
	## Verdeckung, Erde, Moos, Rasen (wie COLOR im Stoff).
	var farbe := PackedColorArray()
	## Fensterbreite der Linie, der dieser Punkt folgt (m).
	var glatt := PackedFloat32Array()
	## Stärke der Rauschverschiebung (m).
	var rauschen := PackedFloat32Array()
	## 1 = frei, −1 = nur nach innen (zum Weg), 2 = nur nach außen (vom Weg
	## weg), 0 = keine Verschiebung.
	var richtung := PackedFloat32Array()
	## Stärke der Schichtstufen (m).
	var schicht := PackedFloat32Array()
	var absolut := PackedByteArray()

	func punkt(o_: float, y_: float, farbe_: Color, glatt_: float = 0.0,
			rauschen_: float = 0.0, richtung_: float = 1.0, schicht_: float = 0.0,
			absolut_: bool = false) -> void:
		o.append(o_)
		y.append(y_)
		farbe.append(farbe_)
		glatt.append(glatt_)
		rauschen.append(rauschen_)
		richtung.append(richtung_)
		schicht.append(schicht_)
		absolut.append(1 if absolut_ else 0)

	func anzahl() -> int:
		return o.size()

	## Mischt zwei Profile gleicher Länge (t = 0: dieses, 1: `b`). Ein Punkt,
	## der hier absolut ist, bleibt es; `b` muss dort ebenso absolut sein.
	func gemischt(b: Profil, t: float) -> Profil:
		var p := Profil.new()
		if t <= 0.0:
			return self
		if t >= 1.0:
			return b
		for j in anzahl():
			p.punkt(lerpf(o[j], b.o[j], t), lerpf(y[j], b.y[j], t), farbe[j].lerp(b.farbe[j], t),
					lerpf(glatt[j], b.glatt[j], t), lerpf(rauschen[j], b.rauschen[j], t),
					richtung[j] if t < 0.5 else b.richtung[j],
					lerpf(schicht[j], b.schicht[j], t), absolut[j] == 1)
		return p


# ================================================================ Linie

## Tastet die Linie `punkte_sq` (Vector2(s, q), q mit Vorzeichen) ab: in
## gleichen Schritten von ungefähr `abstand` Metern Bogenlänge in Welt-XZ,
## und genau dort, wo die Linie eine Strecke aus `feste_s` kreuzt (Stufen,
## Lückenränder – dort muss ein Querschnitt stehen). Rückgabe je Probe
## {"s", "q", "p": Welt-XZ (y 0), "bogen": Bogenlänge ab Anfang}.
static func linie(kurve: Curve3D, punkte_sq: PackedVector2Array, abstand: float,
		feste_s: PackedFloat32Array = PackedFloat32Array()) -> Array[Dictionary]:
	var proben: Array[Dictionary] = []
	if punkte_sq.size() < 2:
		return proben
	# Dicht in (s, q) – dort ist die Linie gegeben – und in Welt-XZ messen.
	var dicht := PackedVector2Array()
	for i in punkte_sq.size() - 1:
		var a := punkte_sq[i]
		var b := punkte_sq[i + 1]
		var teile := maxi(ceili(a.distance_to(b) / 0.1), 1)
		for k in teile:
			dicht.append(a.lerp(b, float(k) / float(teile)))
	dicht.append(punkte_sq[punkte_sq.size() - 1])
	var welt := PackedVector3Array()
	var bogen := PackedFloat32Array()
	for i in dicht.size():
		var w := LevelWerkzeuge.punkt_frei(kurve, dicht[i].x, dicht[i].y)
		w.y = 0.0
		welt.append(w)
		bogen.append(0.0 if i == 0 else bogen[i - 1] + w.distance_to(welt[i - 1]))
	# Knickstellen: Anfang, jede Kreuzung einer festen Strecke, Ende.
	var knicke: Array[float] = [0.0]
	for f in feste_s:
		for i in dicht.size() - 1:
			var s0 := dicht[i].x
			var s1 := dicht[i + 1].x
			if (s0 - f) * (s1 - f) <= 0.0 and absf(s1 - s0) > 0.00001:
				var t := (f - s0) / (s1 - s0)
				var b := lerpf(bogen[i], bogen[i + 1], t)
				if b > 0.01 and b < bogen[bogen.size() - 1] - 0.01:
					knicke.append(b)
				break
	knicke.append(bogen[bogen.size() - 1])
	knicke.sort()
	var ziele: Array[float] = []
	for i in knicke.size() - 1:
		var laenge := knicke[i + 1] - knicke[i]
		if laenge < 0.005:
			continue
		var teile := maxi(roundi(laenge / abstand), 1)
		for k in teile:
			ziele.append(knicke[i] + laenge * float(k) / float(teile))
	ziele.append(knicke[knicke.size() - 1])
	# Abtasten.
	var j := 0
	for ziel in ziele:
		while j < bogen.size() - 2 and bogen[j + 1] < ziel:
			j += 1
		var spanne := maxf(bogen[j + 1] - bogen[j], 0.00001)
		var t := clampf((ziel - bogen[j]) / spanne, 0.0, 1.0)
		var sq := dicht[j].lerp(dicht[j + 1], t)
		proben.append({"s": sq.x, "q": sq.y, "p": welt[j].lerp(welt[j + 1], t), "bogen": ziel})
	return proben


## Die Linie geglättet mit dem Fenster `fenster` (m Bogenlänge, dreieckig
## gewichtet), dazu die Normale je Probe: waagerecht, vom Weg weg (`seite`
## +1 rechts, −1 links). Zu den Enden hin schrumpft das Fenster, damit der
## erste und der letzte Querschnitt dort bleiben, wo sie hingehören.
## Rückgabe {"p": PackedVector3Array, "n": PackedVector3Array}.
static func glaetten(proben: Array[Dictionary], fenster: float, seite: float) -> Dictionary:
	var anzahl := proben.size()
	var p := PackedVector3Array()
	p.resize(anzahl)
	var bogen := PackedFloat32Array()
	bogen.resize(anzahl)
	for i in anzahl:
		bogen[i] = proben[i]["bogen"]
	var ende := bogen[anzahl - 1]
	for i in anzahl:
		var w := minf(fenster, minf(bogen[i], ende - bogen[i]))
		if w < 0.05:
			p[i] = proben[i]["p"]
			continue
		var summe := Vector3.ZERO
		var gewicht := 0.0
		var k := i
		while k >= 0 and bogen[i] - bogen[k] <= w:
			var g := 1.0 - (bogen[i] - bogen[k]) / w
			summe += (proben[k]["p"] as Vector3) * g
			gewicht += g
			k -= 1
		k = i + 1
		while k < anzahl and bogen[k] - bogen[i] <= w:
			var g := 1.0 - (bogen[k] - bogen[i]) / w
			summe += (proben[k]["p"] as Vector3) * g
			gewicht += g
			k += 1
		p[i] = summe / maxf(gewicht, 0.0001)
	var n := PackedVector3Array()
	n.resize(anzahl)
	for i in anzahl:
		var a := p[maxi(i - 1, 0)]
		var b := p[mini(i + 1, anzahl - 1)]
		var t := b - a
		t.y = 0.0
		if t.length_squared() < 0.000001:
			t = Vector3.FORWARD
		n[i] = t.normalized().cross(Vector3.UP).normalized() * seite
	return {"p": p, "n": n}


# ================================================================ Rauschen

## Das 3D-Rauschen der Felsen (fbm, feste Saat). Geteilt.
static func rauschen() -> FastNoiseLite:
	if _rauschen == null:
		_rauschen = FastNoiseLite.new()
		_rauschen.seed = 8311
		_rauschen.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_rauschen.frequency = 1.0
		_rauschen.fractal_type = FastNoiseLite.FRACTAL_FBM
		_rauschen.fractal_octaves = 2
	return _rauschen


## Zellrauschen für Schollen (je Zelle ein fester Wert, −1..1). Geteilt.
static func zellen() -> FastNoiseLite:
	if _zellen == null:
		_zellen = FastNoiseLite.new()
		_zellen.seed = 8317
		_zellen.noise_type = FastNoiseLite.TYPE_CELLULAR
		_zellen.frequency = 1.0
		_zellen.fractal_type = FastNoiseLite.FRACTAL_NONE
		_zellen.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
		_zellen.cellular_jitter = 0.9
	return _zellen


## Verschiebung an einem Weltpunkt, grob −1..1: Pfeiler und Rinnen um 6 m
## (senkrecht gestreckt), Schollen um 3 × 8 m (Zellrauschen: jede Scholle
## steht als Ganzes vor oder zurück – geklüfteter Fels statt Knetmasse),
## Buckel um 2 m, Körnung um 0,9 m.
static func verschiebung(p: Vector3) -> float:
	var r := rauschen()
	var grob := r.get_noise_3d(p.x * 0.15, p.y * 0.075, p.z * 0.15)
	var scholle := zellen().get_noise_3d(p.x * 0.3, p.y * 0.12, p.z * 0.3)
	var mittel := r.get_noise_3d(p.x * 0.46 + 31.0, p.y * 0.34, p.z * 0.46 - 17.0)
	var fein := r.get_noise_3d(p.x * 1.1 - 9.0, p.y * 1.1 + 4.0, p.z * 1.1 + 12.0)
	return clampf(grob * 0.8 + scholle * 0.42 + mittel * 0.42 + fein * 0.2, -1.0, 1.0)


## Die Schichtbänder an einem Weltpunkt: Vector2(Lage im Band 0..1, Band).
## Dieselbe Formel wie im Stoff (Weltrauschen G über `Wegmaske.welt`).
static func schicht(p: Vector3) -> Vector2:
	var w := Wegmaske.welt(Vector2(p.x, p.z))
	var phase := p.y * SCHICHT_DICHTE + p.x * SCHICHT_NEIGUNG.x + p.z * SCHICHT_NEIGUNG.y \
			+ (w.g - 0.5) * 1.1
	var band := floorf(phase)
	return Vector2(phase - band, band)


## Wie weit ein Band an dieser Lage vortritt (0..1): Die obere Hälfte eines
## Bandes ist harte Bank und steht vor, die untere weich und zurück; wie
## hart, entscheidet das Band selbst.
static func schicht_vortritt(p: Vector3) -> float:
	var sb := schicht(p)
	var haerte := 0.35 + 0.65 * fposmod(sin(sb.y * 17.23 + 1.3) * 4375.85, 1.0)
	return smoothstep(0.3, 0.52, sb.x) * (1.0 - smoothstep(0.9, 1.0, sb.x) * 0.6) * haerte


# ================================================================ Querschnitte

## Setzt die Profile an die Proben einer Linie.
##   kurve     der Verlauf (für absolute Punkte: q → Welt)
##   proben    aus `linie()`
##   seite     +1 rechts, −1 links (Normale vom Weg weg)
##   profil_bei  Callable(i: int, probe: Dictionary) -> Profil
##   tiefe_bei   Callable(i: int, probe: Dictionary) -> float: Welt-Y der
##               Wegkante an dieser Probe (für UV2.y, die Tiefe)
##   kronen_bei  Callable(i, probe) -> float: Kronenlicht 0..1
## Rückgabe: {"reihen": Array[PackedVector3Array], "farben": Array[
## PackedColorArray], "uv2": Array[PackedVector2Array], "s": PackedFloat32Array,
## "boden": PackedFloat32Array (Welt-Y der Wegkante), "vorzeichen"}.
static func querschnitte(kurve: Curve3D, proben: Array[Dictionary], seite: float,
		profil_bei: Callable, tiefe_bei: Callable, kronen_bei: Callable) -> Dictionary:
	var linien: Array[Dictionary] = []
	for f in FENSTER:
		linien.append(glaetten(proben, f, seite))
	var reihen: Array[PackedVector3Array] = []
	var farben: Array[PackedColorArray] = []
	var uv2: Array[PackedVector2Array] = []
	var strecken := PackedFloat32Array()
	var boden := PackedFloat32Array()
	for i in proben.size():
		var probe := proben[i]
		var profil: Profil = profil_bei.call(i, probe)
		var kante_y: float = tiefe_bei.call(i, probe)
		var kronen: float = kronen_bei.call(i, probe)
		var reihe := PackedVector3Array()
		var reihe_f := PackedColorArray()
		var reihe_uv := PackedVector2Array()
		for j in profil.anzahl():
			var basis := _auf_linie(linien, i, profil.glatt[j])
			var ort: Vector3 = basis[0]
			var normale: Vector3 = basis[1]
			var y := profil.y[j]
			var p: Vector3
			if profil.absolut[j] == 1:
				p = LevelWerkzeuge.punkt_frei(kurve, float(probe["s"]), profil.o[j])
			else:
				p = ort + normale * profil.o[j]
			p.y = y
			var farbe := profil.farbe[j]
			var staerke := profil.rauschen[j]
			if staerke > 0.0 and profil.richtung[j] != 0.0:
				var v := verschiebung(p)
				var d := v * staerke
				if profil.richtung[j] < 0.0:
					# Nur nach innen: −staerke … 0
					d = -staerke * (0.5 + 0.5 * v)
				elif profil.richtung[j] > 1.5:
					# Nur nach außen: 0 … staerke
					d = staerke * (0.5 + 0.5 * v)
				p += normale * d
				# Hohlform: Was zurückliegt, liegt im Schatten.
				farbe.r *= lerpf(1.0, lerpf(0.72, 1.06, 0.5 + 0.5 * v), minf(staerke / 0.5, 1.0))
			if profil.schicht[j] > 0.0:
				var vor := schicht_vortritt(p)
				p -= normale * profil.schicht[j] * (1.0 - vor)
				farbe.r *= lerpf(0.8, 1.0, vor)
			reihe.append(p)
			reihe_f.append(farbe)
			reihe_uv.append(Vector2(kronen, maxf(kante_y - p.y, 0.0)))
		reihen.append(reihe)
		farben.append(reihe_f)
		uv2.append(reihe_uv)
		strecken.append(float(probe["s"]))
		boden.append(kante_y)
	return {"reihen": reihen, "farben": farben, "uv2": uv2, "s": strecken, "boden": boden,
			"vorzeichen": vorzeichen(reihen)}


## Punkt und Normale der Linie mit Fensterbreite `fenster` (zwischen den
## vorbereiteten Fassungen gemischt).
static func _auf_linie(linien: Array[Dictionary], i: int, fenster: float) -> Array:
	var k := 0
	while k < FENSTER.size() - 2 and FENSTER[k + 1] < fenster:
		k += 1
	var t := clampf(inverse_lerp(FENSTER[k], FENSTER[k + 1], fenster), 0.0, 1.0)
	var a: Dictionary = linien[k]
	var b: Dictionary = linien[k + 1]
	var pa: Vector3 = (a["p"] as PackedVector3Array)[i]
	var pb: Vector3 = (b["p"] as PackedVector3Array)[i]
	var na: Vector3 = (a["n"] as PackedVector3Array)[i]
	var nb: Vector3 = (b["n"] as PackedVector3Array)[i]
	return [pa.lerp(pb, t), na.lerp(nb, t).normalized()]


## Vorzeichen der Flächennormale (Profilrichtung × Linienrichtung), so dass
## sie aus dem Fels heraus zeigt. Geprüft am Anfang des Profils: Dort liegt
## bei jedem Profil dieses Moduls die Oberseite (Narbe bzw. Schulter).
static func vorzeichen(reihen: Array[PackedVector3Array]) -> float:
	if reihen.size() < 2:
		return 1.0
	var mitte := reihen.size() / 2
	var a := reihen[mitte]
	var b := reihen[mitte + 1]
	var n := (a[1] - a[0]).cross(b[0] - a[0])
	return 1.0 if n.y >= 0.0 else -1.0


# ================================================================ Netze

## Glatte Normalen eines Gitters (flächengewichtet), einmal für alle Stücke:
## An den Schnitten zwischen zwei Stücken stimmen sie dann überein.
static func normalen(g: Dictionary) -> Array[PackedVector3Array]:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var vz: float = g["vorzeichen"]
	var ergebnis: Array[PackedVector3Array] = []
	for reihe in reihen:
		var leer := PackedVector3Array()
		leer.resize(reihe.size())
		ergebnis.append(leer)
	for i in reihen.size() - 1:
		var a := reihen[i]
		var b := reihen[i + 1]
		var na := ergebnis[i]
		var nb := ergebnis[i + 1]
		for j in a.size() - 1:
			var f1 := (a[j + 1] - a[j]).cross(b[j] - a[j]) * vz
			var f2 := (b[j + 1] - a[j + 1]).cross(b[j] - a[j + 1]) * vz
			na[j] += f1
			na[j + 1] += f1 + f2
			nb[j] += f1 + f2
			nb[j + 1] += f2
		ergebnis[i] = na
		ergebnis[i + 1] = nb
	for i in ergebnis.size():
		var reihe := ergebnis[i]
		for j in reihe.size():
			var n := reihe[j]
			reihe[j] = n.normalized() if n.length_squared() > 0.0000001 else Vector3.UP
		ergebnis[i] = reihe
	return ergebnis


## Schreibt die Reihen `von`..`bis` eines Gitters als Dreiecke in `st`.
static func gitter_schreiben(st: SurfaceTool, g: Dictionary, norm: Array[PackedVector3Array],
		von: int, bis: int) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var farben: Array[PackedColorArray] = g["farben"]
	var uv2: Array[PackedVector2Array] = g["uv2"]
	var vz: float = g["vorzeichen"]
	for i in range(von, bis):
		var a := reihen[i]
		var b := reihen[i + 1]
		for j in a.size() - 1:
			var ecken := [[i, j], [i, j + 1], [i + 1, j], [i + 1, j + 1]]
			var p00 := a[j]
			var p01 := a[j + 1]
			var p10 := b[j]
			var p11 := b[j + 1]
			var flaeche := (p01 - p00).cross(p10 - p00) * vz
			if flaeche.length_squared() > 0.0000001:
				_dreieck_gitter(st, [ecken[0], ecken[1], ecken[2]], reihen, farben, uv2, norm, flaeche)
			var flaeche2 := (p11 - p01).cross(p10 - p01) * vz
			if flaeche2.length_squared() > 0.0000001:
				_dreieck_gitter(st, [ecken[1], ecken[3], ecken[2]], reihen, farben, uv2, norm, flaeche2)


static func _dreieck_gitter(st: SurfaceTool, ecken: Array, reihen: Array[PackedVector3Array],
		farben: Array[PackedColorArray], uv2: Array[PackedVector2Array],
		norm: Array[PackedVector3Array], aussen: Vector3) -> void:
	var p: Array[Vector3] = []
	for e: Array in ecken:
		p.append(reihen[int(e[0])][int(e[1])])
	var reihe: Array[int] = [0, 1, 2]
	# Godot zeichnet im Uhrzeigersinn als Vorderseite (siehe LevelWerkzeuge).
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(aussen) > 0.0:
		reihe = [0, 2, 1]
	for k in reihe:
		var e: Array = ecken[k]
		var i: int = e[0]
		var j: int = e[1]
		st.set_normal(norm[i][j])
		st.set_color(farben[i][j])
		st.set_uv2(uv2[i][j])
		st.add_vertex(p[k])


## Ein Dreieck mit eigener Normale im Format des Stoffs.
static func dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color, uva: Vector2, uvb: Vector2, uvc: Vector2,
		na := Vector3.ZERO, nb := Vector3.ZERO, nc := Vector3.ZERO) -> void:
	var n := aussen.normalized()
	var punkte: Array[Vector3] = [a, b, c]
	var f: Array[Color] = [fa, fb, fc]
	var uv: Array[Vector2] = [uva, uvb, uvc]
	var nn: Array[Vector3] = [na, nb, nc]
	var reihe: Array[int] = [0, 1, 2]
	if (b - a).cross(c - a).dot(n) > 0.0:
		reihe = [0, 2, 1]
	for k in reihe:
		st.set_normal(nn[k] if nn[k] != Vector3.ZERO else n)
		st.set_color(f[k])
		st.set_uv2(uv[k])
		st.add_vertex(punkte[k])


## Schließt ein offenes Ende: das Vieleck aus der Reihe `reihe` (Welt-
## punkte, alle ungefähr in einer senkrechten Ebene), nach `aussen` zeigend.
## Das Vieleck wird unten durch einen Punkt unter dem Anfang geschlossen.
## Scheitert die Zerlegung (sich schneidender Umriss), bleibt es offen.
static func deckel(st: SurfaceTool, reihe: PackedVector3Array, farben: PackedColorArray,
		aussen: Vector3, kante_y: float) -> void:
	if reihe.size() < 3:
		return
	var ebene_x := aussen.cross(Vector3.UP).normalized()
	if ebene_x.length_squared() < 0.5:
		return
	var tiefst := INF
	for p in reihe:
		tiefst = minf(tiefst, p.y)
	var umriss := PackedVector3Array(reihe)
	var anfang := reihe[0]
	umriss.append(Vector3(reihe[reihe.size() - 1].x, tiefst - 0.5, reihe[reihe.size() - 1].z))
	umriss.append(Vector3(anfang.x, tiefst - 0.5, anfang.z))
	var flach := PackedVector2Array()
	for p in umriss:
		flach.append(Vector2(p.dot(ebene_x), p.y))
	var dreiecke := Geometry2D.triangulate_polygon(flach)
	if dreiecke.is_empty():
		return
	var dunkel := Color(0.45, 0.2, 0.0, 0.0)
	for k in range(0, dreiecke.size(), 3):
		var a := umriss[dreiecke[k]]
		var b := umriss[dreiecke[k + 1]]
		var c := umriss[dreiecke[k + 2]]
		var fa := farben[dreiecke[k]] if dreiecke[k] < farben.size() else dunkel
		var fb := farben[dreiecke[k + 1]] if dreiecke[k + 1] < farben.size() else dunkel
		var fc := farben[dreiecke[k + 2]] if dreiecke[k + 2] < farben.size() else dunkel
		dreieck(st, a, b, c, aussen, fa, fb, fc, Vector2(0.0, maxf(kante_y - a.y, 0.0)),
				Vector2(0.0, maxf(kante_y - b.y, 0.0)), Vector2(0.0, maxf(kante_y - c.y, 0.0)))


## Ein verbeulter Stein (verrauschte Ikosphäre), `mitte`, Halbachsen
## `radien` in der Lage `basis`. Die untere Hälfte steckt meist im Boden;
## sie wird trotzdem gebaut, falls der Boden dort zurückweicht. `farbe` wie
## im Stoff (Moos, Erde), die Verdeckung nach unten dunkler.
static func stein(st: SurfaceTool, mitte: Vector3, radien: Vector3, basis: Basis,
		saat: int, farbe: Color, kante_y: float, kronen: float = 0.0) -> void:
	var kugel := _ikosphaere()
	var punkte: PackedVector3Array = kugel["punkte"]
	var flaechen: PackedInt32Array = kugel["flaechen"]
	var r := rauschen()
	var welt := PackedVector3Array()
	var fs := PackedColorArray()
	for p in punkte:
		var beule := r.get_noise_3d(p.x * 1.7 + float(saat), p.y * 1.7, p.z * 1.7 - float(saat))
		var eben := p * (1.0 + beule * 0.28)
		# Unten etwas abgeflacht, oben eine Kante: Stein, nicht Kartoffel.
		eben.y = maxf(eben.y, -0.75) * (0.85 if eben.y < 0.0 else 1.0)
		var w := mitte + basis * Vector3(eben.x * radien.x, eben.y * radien.y, eben.z * radien.z)
		welt.append(w)
		var f := farbe
		f.r *= lerpf(0.45, 1.0, clampf(p.y * 0.5 + 0.6, 0.0, 1.0))
		fs.append(f)
	# Glatte Normalen über die Kugel.
	var n := PackedVector3Array()
	n.resize(welt.size())
	for k in range(0, flaechen.size(), 3):
		var a := welt[flaechen[k]]
		var b := welt[flaechen[k + 1]]
		var c := welt[flaechen[k + 2]]
		var fn := (b - a).cross(c - a)
		if fn.dot(a - mitte) < 0.0:
			fn = -fn
		n[flaechen[k]] += fn
		n[flaechen[k + 1]] += fn
		n[flaechen[k + 2]] += fn
	for k in range(0, flaechen.size(), 3):
		var ia := flaechen[k]
		var ib := flaechen[k + 1]
		var ic := flaechen[k + 2]
		var a := welt[ia]
		var aussen := (a + welt[ib] + welt[ic]) / 3.0 - mitte
		dreieck(st, a, welt[ib], welt[ic], aussen, fs[ia], fs[ib], fs[ic],
				Vector2(kronen, maxf(kante_y - a.y, 0.0)),
				Vector2(kronen, maxf(kante_y - welt[ib].y, 0.0)),
				Vector2(kronen, maxf(kante_y - welt[ic].y, 0.0)),
				n[ia].normalized(), n[ib].normalized(), n[ic].normalized())


static var _kugel: Dictionary = {}

## Ikosphäre mit einer Teilung (42 Punkte, 80 Flächen), Einheitsradius.
static func _ikosphaere() -> Dictionary:
	if not _kugel.is_empty():
		return _kugel
	var t := (1.0 + sqrt(5.0)) / 2.0
	# Ein Array (Verweis), kein PackedVector3Array: `_mittelpunkt` hängt an.
	var punkte: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in punkte.size():
		punkte[i] = punkte[i].normalized()
	var flaechen := PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
			1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
			3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
			4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	var mitten := {}
	var neu := PackedInt32Array()
	for k in range(0, flaechen.size(), 3):
		var a := flaechen[k]
		var b := flaechen[k + 1]
		var c := flaechen[k + 2]
		var ab := _mittelpunkt(a, b, punkte, mitten)
		var bc := _mittelpunkt(b, c, punkte, mitten)
		var ca := _mittelpunkt(c, a, punkte, mitten)
		neu.append_array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca])
	_kugel = {"punkte": PackedVector3Array(punkte), "flaechen": neu}
	return _kugel


static func _mittelpunkt(a: int, b: int, punkte: Array[Vector3], mitten: Dictionary) -> int:
	var schluessel := "%d_%d" % [mini(a, b), maxi(a, b)]
	if mitten.has(schluessel):
		return mitten[schluessel]
	punkte.append(((punkte[a] + punkte[b]) * 0.5).normalized())
	mitten[schluessel] = punkte.size() - 1
	return punkte.size() - 1


# ================================================================ Karten

## Eine Karte (Viereck) mit Alpha-Scissor: oben an `oben`, hängt entlang
## `runter` um `laenge`, `breite` quer entlang `quer`. `atlas` ist der
## u-Bereich im Kartenatlas (`ATLAS_WURZEL`, `ATLAS_HALM`), `v0`/`v1` der
## Ausschnitt in v. `farbe` tönt (Scheitelfarbe).
static func karte(st: SurfaceTool, oben: Vector3, runter: Vector3, quer: Vector3,
		laenge: float, breite: float, atlas: Vector2, farbe: Color,
		v0: float = 0.0, v1: float = 1.0) -> void:
	var r := runter.normalized()
	var q := quer.normalized()
	var n := q.cross(r).normalized()
	var a := oben - q * breite * 0.5
	var b := oben + q * breite * 0.5
	var c := b + r * laenge
	var d := a + r * laenge
	var ecken: Array[Vector3] = [a, b, c, a, c, d]
	var uvs: Array[Vector2] = [Vector2(atlas.x, v0), Vector2(atlas.y, v0), Vector2(atlas.y, v1),
			Vector2(atlas.x, v0), Vector2(atlas.y, v1), Vector2(atlas.x, v1)]
	var unten := farbe.darkened(0.35)
	var farben: Array[Color] = [farbe, farbe, unten, farbe, unten, unten]
	for k in 6:
		st.set_normal(n)
		st.set_color(farben[k])
		st.set_uv(uvs[k])
		st.add_vertex(ecken[k])


# ================================================================ Stoffe

## Der Stoff aller Kanten (`shaders/fels_schichten.gdshader`). Geteilt – nie
## verändern.
static func stoff() -> ShaderMaterial:
	if _stoff != null:
		return _stoff
	_stoff = ShaderMaterial.new()
	_stoff.shader = STOFF_SHADER
	Wegmaske.einrichten(_stoff)
	_stoff.set_shader_parameter("fels", Materialbibliothek.wurzelfels().albedo_texture)
	_stoff.set_shader_parameter("erde", Materialbibliothek.waldboden().albedo_texture)
	_stoff.set_shader_parameter("moos", Riesenstamm.moostextur())
	return _stoff


## Stoff der Wurzel- und Halmkarten: Atlas mit Alpha-Scissor, beidseitig,
## Farbe × Scheitelfarbe. Geteilt – nie verändern.
static func kartenstoff() -> StandardMaterial3D:
	if _kartenstoff != null:
		return _kartenstoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = _kartenatlas()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_kartenstoff = m
	return m


## Kartenatlas 128 × 128: links Wurzelgeflecht (dunkle, sich teilende
## Stränge, die nach unten dünner werden), rechts Halme, die über die Kante
## hängen. Weiß getönt; die Farbe kommt aus den Scheitelfarben.
static func _kartenatlas() -> ImageTexture:
	const K := 128
	var bild := Image.create(K, K, false, Image.FORMAT_RGBA8)
	bild.fill(Color(0, 0, 0, 0))
	var rng := PropWerkzeug.zufall(8341)
	# Wurzeln: 9 Stränge von oben, jeder verzweigt sich einmal.
	for strang in 9:
		var x := rng.randf_range(4.0, 60.0)
		var dicke := rng.randf_range(1.6, 3.2)
		var lang := rng.randf_range(0.55, 1.0) * float(K)
		var drift := rng.randf_range(-0.25, 0.25)
		_strang(bild, x, 0.0, drift, dicke, lang, rng, 0, 64, true)
	# Halme: 26 Halme, oben dicht, nach unten hängend und spitz.
	for halm in 26:
		var x := rng.randf_range(66.0, 126.0)
		var lang := rng.randf_range(0.35, 1.0) * float(K)
		var drift := rng.randf_range(-0.35, 0.35)
		_strang(bild, x, 0.0, drift, rng.randf_range(1.1, 1.9), lang, rng, 64, 128, false)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


## Malt einen Strang von (x, y) nach unten in das Bild, zwischen den
## Spalten `x_min`..`x_max`.
static func _strang(bild: Image, x: float, y: float, drift: float, dicke: float,
		laenge: float, rng: RandomNumberGenerator, x_min: int, x_max: int,
		wurzel: bool) -> void:
	var schritte := int(laenge)
	var verzweigt := false
	for k in schritte:
		var t := float(k) / float(schritte)
		var d := dicke * lerpf(1.0, 0.25, t)
		var cx := x + sin(float(k) * 0.09 + x) * 1.6
		var cy := y + float(k)
		var hell := lerpf(0.55, 0.95, t) if wurzel else lerpf(0.75, 1.0, t)
		var farbe := Color(hell, hell, hell, 1.0)
		var r := ceili(d)
		for dx in range(-r, r + 1):
			var px := int(cx) + dx
			var py := int(cy)
			if px < x_min or px >= x_max or py < 0 or py >= bild.get_height():
				continue
			if absf(float(dx)) <= d * 0.5 + 0.2:
				bild.set_pixel(px, py, farbe)
		x += drift
		if wurzel and not verzweigt and t > 0.3 and rng.randf() < 0.02:
			verzweigt = true
			_strang(bild, x, cy, -drift + rng.randf_range(-0.3, 0.3), d * 0.7,
					(1.0 - t) * laenge * 0.8, rng, x_min, x_max, true)


# ================================================================ Fläche

## Merkt sich die Querschnitte einer Seite für `flaeche_punkt`.
static func merken(seite: float, g: Dictionary) -> void:
	_flaechen[signi(int(signf(seite)))] = {"s": g["s"], "boden": g["boden"],
			"reihen": g["reihen"]}


## Vergisst alle Flächen (beim Neuaufbau eines Levels).
static func vergessen() -> void:
	_flaechen.clear()


## Ein Punkt auf der zuletzt gebauten Fläche einer Seite (`seite` −1 links,
## +1 rechts) an der Strecke `s`, `hoehe` Meter über der Wegkante dort
## (negativ = darunter). Gesucht wird im Querschnitt von innen nach außen
## die erste Stelle, an der die Fläche diese Höhe kreuzt – rechts also die
## Felswand unter der Lippe, links die Wand über dem Fuß. Ohne gebaute Fläche
## oder außerhalb: Vector3(NAN, NAN, NAN).
static func flaeche_punkt(s: float, seite: float, hoehe: float) -> Vector3:
	var f: Dictionary = _flaechen.get(signi(int(signf(seite))), {})
	var leer := Vector3(NAN, NAN, NAN)
	if f.is_empty():
		return leer
	var strecken: PackedFloat32Array = f["s"]
	var boden: PackedFloat32Array = f["boden"]
	var reihen: Array[PackedVector3Array] = f["reihen"]
	var i := -1
	for k in strecken.size() - 1:
		var a := minf(strecken[k], strecken[k + 1])
		var b := maxf(strecken[k], strecken[k + 1])
		if s >= a and s <= b:
			i = k
			break
	if i < 0:
		return leer
	var spanne := strecken[i + 1] - strecken[i]
	var t := (s - strecken[i]) / spanne if absf(spanne) > 0.0001 else 0.0
	var y := lerpf(boden[i], boden[i + 1], t) + hoehe
	var pa := _kreuzung(reihen[i], y)
	var pb := _kreuzung(reihen[i + 1], y)
	if is_nan(pa.x) or is_nan(pb.x):
		return leer
	return pa.lerp(pb, t)


## Erste Stelle eines Querschnitts, an der er die Höhe `y` kreuzt.
static func _kreuzung(reihe: PackedVector3Array, y: float) -> Vector3:
	for j in reihe.size() - 1:
		var a := reihe[j]
		var b := reihe[j + 1]
		if (a.y - y) * (b.y - y) <= 0.0 and absf(b.y - a.y) > 0.0001:
			return a.lerp(b, (y - a.y) / (b.y - a.y))
	return Vector3(NAN, NAN, NAN)
