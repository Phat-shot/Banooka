extends RefCounted
class_name L01Rasen
## Level 01, Modul „Rasen": Rasensaum, Bodenstreu, Rahmenfarne (Plan
## Abschnitt 8.2, Regel K8).
##
## WO ES WÄCHST. Der Rasen folgt der Wegmaske (`Wegmaske`, dieselbe, nach
## der Wegdecke und Gelände malen): Auf der ausgetretenen Spur wächst nichts,
## daneben stehen Rasenflecken (`Rasensaum.fleck`, je 26 Halme) mit einer
## Dichte ∝ m² (m = Rasenanteil), an der Trittkante eine innere Reihe, die
## sich 25–40° über die Erde legt. Jenseits der Wegkante je nach Rand
## (`Level01.rand_profil`, `L01Saum.lippe_q`):
##   A      der Boden des Geländes bis 4,5 m hinter der Kante, lichter, wo
##          der Wald dichter wird (`L01Gelaende.wald`); dort Farne, Moos
##          und Leuchtpilze
##   B/C    rechts bis an die Lippe (auch auf den Vorsprüngen), davor hohes
##          Gras, darüber Wispelgras, das 0,5–0,8 m über die Kante hängt;
##          links der Streifen bis zum Fuß der Böschung bzw. Wand (in der
##          Nische der ganze Boden), dann die Böschung hinauf (auf der
##          gebauten Fläche, `GelaendeSaum.flaeche_punkt`); am Wandfuß der
##          Fallklamm hohes Gras, Farne, Großblätter
##   D      die Bachwiese: auf dem Weg 4 Flecken/m², daneben 6,5, bis 12,5 m
##          hinaus, viele Blüten; an den Ufern der Furt hohes Gras
##   E/F    kein Gras auf der Borke: Moospolster, Farne und Leuchtpilze in
##          den Querrissen des Wurzelrückens (dieselbe Rechnung wie der
##          Shader, `_riss`), auf dem Moos der Flanken Polster, Farne,
##          Blüten und am Saum zur Borke kurzes Moosgras; die Wurzelwiese
##          darunter voll Gras und Blüten
## Wispelgras und hohes Gras auch an den Lippen der Lücken und Stufen
## (außerhalb der Spur) und an den Ufern der Furt. Hohes Gras (0,45–0,6 m)
## an Steinen, Stämmen und Toren. Nichts wächst in Körpern aus
## `BEGEHBARES`, in Stämmen, an den Füßen der Tore und an den Portalen; um
## jede Kiste bleibt 1 m frei, hohes Gras und große Streu halten 1,5 m.
##
## STREU (`Bodenstreu`): Kleeflecken, Blütengruppen (je Gruppe eine Art und
## Farbe; auf der Wiese viele, im Hallenwald nur weiße), Kiesel an der
## Lippe und an der Trittkante, Pilze (im Hallenwald und in den Rissen
## leuchtend), kleine Farne (`Farnwerk.klein`, mit natur2 das Stilmodell
## M12), Großblätter (mit natur2 M13) am Wandfuß und an der Furt,
## Moospolster (`Rasensaum.polster`). RAHMENFARNE (`Farnwerk.rahmen`,
## 2–3 m) alle 7–11 m: links in A (Gelände, |q| 6,5–8), B (Fuß der
## Böschung) und C (Fuß der Wand), in D beidseitig (|q| 7–9). Die Kamera
## steht 9,5 m hinter der Figur, also rahmen sie die unteren Bildecken,
## wenn die Figur 3,5 m vor ihnen bis 0,5 m hinter ihnen läuft. Nie in den
## mittleren 40 % des Bildes (Figur in der Mitte): Ihre Wedel reichen gut
## 2,4 m je Maß nach innen und enden bei |q| ≥ 2,5 – wo die Wand näher
## am Weg steht, wird der Farn kleiner. Nie zwischen Figur und Kamera: Sie
## bleiben unter der Sichtlinie.
##
## KOSTEN (Plan 13: ≤ 40 Zeichenaufrufe, ≤ 120k Dreiecke je Station): je
## Stück von `STUECK` m höchstens neun Netze – Gras (zweimal: die halbe
## Dichte bis `SICHT_GRAS`, die andere Hälfte nur bis `SICHT_DICHT`),
## Büschel, Wispelgras, Moospolster, Streu (verschmolzen), Farne,
## Großblätter, Rahmenfarne –, alle ohne Schatten, mit harter Sichtweite
## und Schrumpfen im Vertexshader. Gemessen (Verfolger, gegen den Stand
## ohne Rasen): 2–19 Zeichenaufrufe und 2–107k Dreiecke je Station, am
## meisten auf der Bachwiese und am Wurzelaufgang (s 176, 212). Web
## (`Effekte.reduziert`): halbe Dichte (Gras, Streu, Wispelgras), Blüten
## nur bis 20 m.
##
## AUFBAU in sechs Schritten (je Abschnitt einer, zuletzt die Netze), am
## Desktop ohne Kopf gemessen je 70–260 ms. Die Zwischenstände liegen in
## `_bau` und werden danach vergessen (auch, wenn das Level vorher geht).

## Länge der Stücke entlang s (m).
const STUECK := 16.0
## Kandidatenraster: zehn Stellen je m², jede wird gewürfelt.
const RASTER := 0.316
const DICHTE_MAX := 10.0
## Rasenflecken je m² (je 26 Halme, Rasensaum.fleck): Schultern, Bachwiese
## auf dem Weg und daneben, Böschung. Dazu gekippte Flecken an der
## Trittkante (`DICHTE_KANTE`) und Büschel (9 Halme) als hohes Gras
## (`DICHTE_HOCH`).
const DICHTE_SCHULTER := 6.0
const DICHTE_WIESE_WEG := 4.0
const DICHTE_WIESE_RAND := 6.5
const DICHTE_HANG := 4.2
const DICHTE_KANTE := 5.5
## Moos auf den Flanken des Wurzelrückens (E/F), Moosflecken je m²: auf
## der ganzen Fläche und dazu im Saum zur Borke, wo es über sie kriecht.
const DICHTE_MOOS := 2.2
const DICHTE_MOOS_SAUM := 6.5
const DICHTE_HOCH := 2.5
## Freiraum um Kisten (m, von der Mitte): nichts / nichts Hohes.
const KISTE_FREI := 1.0
const KISTE_HOCH := 1.5
## Sichtweiten der Netze (m, zur Mitte des Stücks).
const SICHT_GRAS := 42.0
## Die Hälfte der Rasenflecken nur bis hier: Jenseits von gut 20 m sind die
## Halme zwei, drei Bildpunkte breit, dort reicht die halbe Dichte.
const SICHT_DICHT := 22.0
const SICHT_WISPEL := 38.0
const SICHT_STREU := 40.0
const SICHT_FARN := 44.0
## Bereiche (für die Streu).
enum Bereich { WALD, SCHULTER, HANG, WIESE, WIESE_WEG, WURZEL, WANDFUSS }

static var _bau: Bau = null


# ================================================================ Haken

## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Gras wächst am Waldsaum", "tun": func() -> void:
			_anfangen(level)
			_waldsaum(_bau)},
		{"text": "Gras am Hangweg", "tun": func() -> void: _hangweg(_bau)},
		{"text": "Farne in der Fallklamm", "tun": func() -> void: _fallklamm(_bau)},
		{"text": "Die Bachwiese blüht", "tun": func() -> void: _bachwiese(_bau)},
		{"text": "Moos in den Wurzelrissen", "tun": func() -> void: _wurzel(_bau)},
		{"text": "Rasen wird ausgerollt", "tun": func() -> void:
			_netze(_bau)
			_bau = null},
	]


# ================================================================ Bauzustand

## Was ein Stück (STUECK m entlang s) sammelt.
class Sammlung:
	extends RefCounted
	var gras: Array[Transform3D] = []
	var gras_farben := PackedColorArray()
	var bueschel: Array[Transform3D] = []
	var bueschel_farben := PackedColorArray()
	var wispel: Array[Transform3D] = []
	var wispel_farben := PackedColorArray()
	var polster: Array[Transform3D] = []
	var polster_farben := PackedColorArray()
	## Moos auf dem Wurzelrücken (Stoff `Rasensaum.stoff(true)`).
	var moos: Array[Transform3D] = []
	var moos_farben := PackedColorArray()
	var moospolster: Array[Transform3D] = []
	var moospolster_farben := PackedColorArray()
	var farn: Array[Transform3D] = []
	var farn_farben := PackedColorArray()
	var gross: Array[Transform3D] = []
	var gross_farben := PackedColorArray()
	var rahmen: Array[Transform3D] = []
	var rahmen_farben := PackedColorArray()
	var haufen: Bodenstreu.Haufen = null


## Der Zustand eines Baus: Level, Zufall, Sperren, gesammelte Stücke.
class Bau:
	extends RefCounted
	var level: Level01
	var rng := RandomNumberGenerator.new()
	var sammlungen := {}
	## Kisten je Meter (floor(s)) als Vector2(s, q).
	var kisten := {}
	## Sperren je Meter: Vector4(s, q, halbe Länge in s, halbe Breite in q)
	## (Rechteck) oder mit w < 0: Kreis, Radius = -w.
	var sperren := {}
	var teile := {}
	var reduziert := false
	var dichte_faktor := 1.0
	## Gelände je Zelle (0,5 m Höhe, 1 m Wald): Beide Abfragen sind teuer,
	## und benachbarte Reihen fragen fast dieselben Stellen.
	var _hoehen := {}
	var _walder := {}

	func _init(level_: Level01) -> void:
		level = level_
		rng.seed = 91017
		reduziert = Effekte.reduziert
		dichte_faktor = 0.5 if reduziert else 1.0

	func sammlung(s: float) -> Sammlung:
		var i := floori(s / STUECK)
		if not sammlungen.has(i):
			sammlungen[i] = Sammlung.new()
		return sammlungen[i]

	## Haufen des Stücks um `s` (Ursprung: Wegmitte in der Stückmitte).
	func haufen(s: float) -> Bodenstreu.Haufen:
		var sa := sammlung(s)
		if sa.haufen == null:
			var mitte := (floorf(s / STUECK) + 0.5) * STUECK
			sa.haufen = Bodenstreu.Haufen.new(level.weg_punkt(mitte))
		return sa.haufen

	## Geländehöhe in einer Zelle von 0,5 m (für Abbruchproben).
	func hoehe_zelle(p: Vector3) -> float:
		var k := Vector2i(floori(p.x * 2.0), floori(p.z * 2.0))
		if not _hoehen.has(k):
			_hoehen[k] = L01Gelaende.hoehe((float(k.x) + 0.5) * 0.5, (float(k.y) + 0.5) * 0.5)
		return _hoehen[k]

	## Walddichte des Geländes in einer Zelle von 1 m.
	func wald(p: Vector3) -> float:
		var k := Vector2i(floori(p.x), floori(p.z))
		if not _walder.has(k):
			_walder[k] = L01Gelaende.wald(float(k.x) + 0.5, float(k.y) + 0.5)
		return _walder[k]

	func sperre(s: float, q: float, laenge: float, breite: float) -> void:
		var v := Vector4(s, q, laenge, breite)
		for k in range(floori(s - laenge) - 2, floori(s + laenge) + 3):
			if not sperren.has(k):
				sperren[k] = []
			(sperren[k] as Array).append(v)

	func kreis(s: float, q: float, radius: float) -> void:
		var v := Vector4(s, q, radius, -radius)
		for k in range(floori(s - radius) - 2, floori(s + radius) + 3):
			if not sperren.has(k):
				sperren[k] = []
			(sperren[k] as Array).append(v)

	## Abstand zur nächsten Kiste in (s, q) (INF, wenn keine nah ist).
	func kiste_abstand(s: float, q: float) -> float:
		var beste := INF
		for k in range(floori(s) - 2, floori(s) + 3):
			if not kisten.has(k):
				continue
			for v: Vector2 in kisten[k]:
				beste = minf(beste, Vector2(s, q).distance_to(v))
		return beste

	## Abstand zur nächsten Sperre (negativ: darin); INF, wenn keine nah ist.
	func sperr_abstand(s: float, q: float) -> float:
		var k := floori(s)
		if not sperren.has(k):
			return INF
		var beste := INF
		for v: Vector4 in sperren[k]:
			var d: float
			if v.w < 0.0:
				d = Vector2(s, q).distance_to(Vector2(v.x, v.y)) + v.w
			else:
				var ds := absf(s - v.x) - v.z
				var dq := absf(q - v.y) - v.w
				d = Vector2(maxf(ds, 0.0), maxf(dq, 0.0)).length() + minf(maxf(ds, dq), 0.0)
			beste = minf(beste, d)
		return beste


static func _anfangen(level: Level01) -> void:
	_bau = Bau.new(level)
	var b := _bau
	# Bricht der Aufbau ab (das Level wird vorher verlassen), hält der
	# Zwischenstand sonst das Level fest.
	var id := level.get_instance_id()
	level.tree_exiting.connect(func() -> void: L01Rasen._vergessen(id), CONNECT_ONE_SHOT)
	for e: Dictionary in Level01.KISTEN:
		var s: float = e["s"]
		var q: float = e["q"]
		var k := floori(s)
		if not b.kisten.has(k):
			b.kisten[k] = []
		(b.kisten[k] as Array).append(Vector2(s, q))
	# Körper aus BEGEHBARES (Steine, Stämme, Pfortenfelsen): nichts darin.
	for e: Dictionary in Level01.BEGEHBARES:
		match String(e["form"]):
			"kasten":
				var g: Vector3 = e["groesse"]
				b.sperre(float(e["s"]), float(e["q"]), g.z * 0.5, g.x * 0.5)
			"zylinder":
				b.kreis(float(e["s"]), float(e["q"]), float(e["radius"]))
			"kapsel":
				b.sperre(float(e["s"]), float(e["q"]), float(e["radius"]) * 0.8,
						float(e["laenge"]) * 0.5)
	# Stämme, Findlinge, Füße der Tore, Portale.
	for e: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if float(e["fuss"]) < -0.5:
			continue
		var r := 1.2 if String(e["art"]) == "findling" else 0.7
		if String(e["art"]) == "torbaum":
			r = 1.4
		b.kreis(float(e["s"]), float(e["q"]), r)
	for e: Dictionary in Level01.TORRIESEN + Level01.TALRIESEN:
		b.kreis(float(e["s"]), float(e["q"]), float(e["radius"]) * 1.7)
	for e: Dictionary in Level01.TORE:
		if e.has("art") or float(e["s"]) > Level01.M_KRONENTOR:
			continue
		for seite: float in [-1.0, 1.0]:
			b.kreis(float(e["s"]), seite * float(e["abstand"]), 1.1)
	b.kreis(1.0, 0.0, 2.2)
	b.kreis(Level01.M_ZIEL, 0.0, 2.6)


## Vergisst den Zwischenstand, wenn er zu diesem Level gehört.
static func _vergessen(level_id: int) -> void:
	if _bau != null and is_instance_valid(_bau.level) \
			and _bau.level.get_instance_id() == level_id:
		_bau = null


# ================================================================ Rahmen je Strecke

## Querlage an der Strecke `s`: Wegmitte (Welt, y = Decke), rechts, vor,
## halbe Breite (in Lücken 0), Kronenlicht.
class Lage:
	extends RefCounted
	var s := 0.0
	var mitte := Vector3.ZERO
	var rechts := Vector3.RIGHT
	var vor := Vector3.FORWARD
	var halb := 0.0
	var kronen := 0.0

	func punkt(q: float) -> Vector3:
		return mitte + rechts * q


static func _lage(b: Bau, s: float) -> Lage:
	var l := Lage.new()
	var kurve := b.level.verlauf
	l.s = s
	var a := LevelWerkzeuge.punkt_frei(kurve, s, 0.0)
	var r := LevelWerkzeuge.punkt_frei(kurve, s, 1.0) - a
	r.y = 0.0
	l.rechts = r.normalized()
	l.vor = Vector3.UP.cross(l.rechts).normalized()
	a.y = b.level.boden_bei(s)
	l.mitte = a
	l.halb = b.level.breite_bei(s) * 0.5
	l.kronen = L01Boden.kronenlicht_bei(b.level, s)
	return l


# ================================================================ Setzen

## Gras (und vielleicht Streu) an der Stelle `p`. `m` Rasenanteil am Fuß,
## `ao` Verdeckung, `dichte` Rasenflecken je m², `kante` Büschel je m² der
## inneren Reihe (gekippt nach `kipp`: Richtung × Winkel in rad), `hoch`
## 0..1 Anteil hohes Gras. Gewürfelt wird gegen `DICHTE_MAX` je Stelle.
static func _stelle(b: Bau, s: float, q: float, p: Vector3, m: float, ao: float,
		kronen: float, dichte: float, hoch: float, bereich: int,
		kipp: Vector3 = Vector3.ZERO, kante: float = 0.0) -> void:
	var rng := b.rng
	var kiste := b.kiste_abstand(s, q)
	if kiste < KISTE_FREI:
		return
	var sperre := b.sperr_abstand(s, q)
	if sperre < 0.05:
		return
	# Am Rand eines Körpers (Stein, Stamm) hohes Gras.
	if sperre < 0.55:
		hoch = maxf(hoch, 1.0 - sperre / 0.55)
	if kiste < KISTE_HOCH:
		hoch = 0.0
	var wurf := rng.randf() * DICHTE_MAX
	var fleck := dichte * b.dichte_faktor
	var bueschel := (kante + DICHTE_HOCH * hoch) * b.dichte_faktor
	if wurf < fleck + bueschel:
		var w := Wegmaske.welt(Vector2(p.x, p.z))
		# Höhe: Flecken über 4–20 m, an der Trittkante niedergetreten.
		var feld := smoothstep(0.25, 0.8, w.g * 0.55 + w.b * 0.45)
		var h := lerpf(0.15, 0.34, feld) * rng.randf_range(0.8, 1.2)
		h *= lerpf(0.6, 1.0, smoothstep(0.3, 0.9, m))
		if bereich == Bereich.WIESE:
			h *= 1.15
		elif bereich == Bereich.WURZEL:
			h *= 0.55
		var sa := b.sammlung(s)
		var farbe := Rasensaum.farbe(ao, m, rng.randf_range(0.25, 0.75), kronen)
		if wurf < fleck + kante * b.dichte_faktor:
			# Rasenflecken; an der Trittkante gekippt über die Erde (die innere
			# Reihe), sonst mit einem Hauch Schiefe.
			var k := kipp if wurf >= fleck else Vector3.ZERO
			sa.gras.append(_bueschel_lage(rng, p - Vector3(0.0, 0.012, 0.0), h, k))
			sa.gras_farben.append(farbe)
		else:
			if hoch > 0.0 and rng.randf() < hoch:
				h = rng.randf_range(0.45, 0.6)
			sa.bueschel.append(_bueschel_lage(rng, p - Vector3(0.0, 0.012, 0.0), h, kipp))
			sa.bueschel_farben.append(farbe)
	_streu(b, s, q, p, m, bereich, kiste, sperre, kronen)


## Lage eines Büschels der Höhe `h`: gedreht, das Maß gestreut, an der
## Trittkante gekippt.
static func _bueschel_lage(rng: RandomNumberGenerator, fuss: Vector3, h: float,
		kipp: Vector3) -> Transform3D:
	var mass := h / Rasensaum.BEZUG
	var quer := lerpf(1.0, mass, 0.5) * rng.randf_range(0.85, 1.2)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(quer, mass, quer))
	var winkel := kipp.length()
	if winkel > 0.001:
		var achse := Vector3.UP.cross(kipp / winkel).normalized()
		basis = Basis(achse, winkel) * basis
	else:
		# Ein Hauch Schiefe, sonst stehen alle wie gezogen.
		basis = Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(),
				rng.randf_range(0.0, 0.12)) * basis
	return Transform3D(basis, fuss)


## Streu an einer Kandidatenstelle (0,1 m²): je Art gewürfelt nach der Rate
## des Bereichs (je m²).
static func _streu(b: Bau, s: float, q: float, p: Vector3, m: float, bereich: int,
		kiste: float, sperre: float, kronen: float) -> void:
	var rng := b.rng
	var f := 0.1 * b.dichte_faktor
	var r_klee := 0.0
	var r_bluete := 0.0
	var r_kiesel := 0.0
	var r_pilz := 0.0
	var r_moos := 0.0
	var r_farn := 0.0
	var r_gross := 0.0
	var leucht := 0.0
	match bereich:
		Bereich.WALD:
			r_klee = 0.02
			r_bluete = 0.01
			r_pilz = 0.02
			r_moos = 0.035
			r_farn = 0.1
			leucht = 0.6
		Bereich.SCHULTER:
			r_klee = 0.035
			r_bluete = 0.05
			r_kiesel = 0.012 + 0.08 * (1.0 - smoothstep(0.35, 0.7, m)) * smoothstep(0.1, 0.3, m)
			r_pilz = 0.003
		Bereich.HANG:
			r_klee = 0.01
			r_bluete = 0.025
			r_moos = 0.02
			r_farn = 0.06
			r_pilz = 0.004
		Bereich.WIESE:
			r_klee = 0.06
			r_bluete = 0.22
			r_farn = 0.004
		Bereich.WIESE_WEG:
			r_klee = 0.05
			r_bluete = 0.06
			r_kiesel = 0.05 * (1.0 - smoothstep(0.35, 0.7, m)) * smoothstep(0.1, 0.3, m)
		Bereich.WURZEL:
			r_moos = 0.12
			r_farn = 0.05
			r_pilz = 0.015
			r_bluete = 0.025
			leucht = 0.85
		Bereich.WANDFUSS:
			r_moos = 0.05
			r_farn = 0.05
			r_gross = 0.03
			r_pilz = 0.01
			r_bluete = 0.01
	var gross_frei := kiste >= KISTE_HOCH and sperre > 0.3
	if m > 0.75 and rng.randf() < r_klee * f:
		_teil(b, s, p, "klee", rng.randf_range(0.8, 1.25))
	if m > 0.8 and gross_frei and rng.randf() < r_bluete * f:
		_bluetengruppe(b, s, p, bereich)
	if rng.randf() < r_kiesel * f:
		_teil(b, s, p, "kiesel", rng.randf_range(0.7, 1.3))
	if gross_frei and rng.randf() < r_pilz * f:
		_teil(b, s, p, "pilz_leucht" if rng.randf() < leucht else "pilz", rng.randf_range(0.8, 1.3))
	if rng.randf() < r_moos * f:
		_polster(b, s, p, rng.randf_range(0.7, 1.4), bereich == Bereich.WURZEL, kronen)
	if gross_frei and rng.randf() < r_farn * f:
		_farn(b, s, p, rng.randf_range(0.7, 1.3))
	if gross_frei and rng.randf() < r_gross * f:
		_grossblatt(b, s, p, rng.randf_range(0.8, 1.2))


## Ein Teil aus dem Vorrat (je Art sechs Formen) in den Haufen des Stücks.
static func _teil(b: Bau, s: float, p: Vector3, art: String, mass: float,
		ton: Color = Color.WHITE) -> void:
	var formen := _formen(b, art)
	var t: Bodenstreu.Teil = formen[b.rng.randi() % formen.size()]
	var basis := Basis(Vector3.UP, b.rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	b.haufen(s).teil(t, Transform3D(basis, p), ton)


static func _formen(b: Bau, art: String) -> Array:
	if b.teile.has(art):
		return b.teile[art]
	var formen := []
	var rng := PropWerkzeug.zufall((hash(art) & 0xffff) + 17)
	for i in 6:
		match art:
			"klee":
				formen.append(Bodenstreu.klee(rng, rng.randf_range(0.22, 0.42), i < 2))
			"kiesel":
				formen.append(Bodenstreu.kiesel(rng, rng.randf_range(0.1, 0.2), rng.randi_range(1, 4)))
			"pilz":
				formen.append(Bodenstreu.pilze(rng, rng.randf_range(0.035, 0.06), rng.randi_range(1, 4)))
			"pilz_leucht":
				formen.append(Bodenstreu.pilze(rng, rng.randf_range(0.025, 0.045),
						rng.randi_range(2, 5), true))
	b.teile[art] = formen
	return formen


## Eine Blütengruppe: Art und Farbe nach Bereich, je Gruppe eine.
static func _bluetengruppe(b: Bau, s: float, p: Vector3, bereich: int) -> void:
	var rng := b.rng
	# (Art, Farbindex) – 0 Margerite, 1 Butterblume, 2 Glocke; Farben aus
	# Bodenstreu.BLUETEN_FARBEN (weiß, gelb, violett, blau, rosa).
	var moeglich: Array[Vector2i] = []
	match bereich:
		Bereich.WALD:
			moeglich = [Vector2i(0, 0)]
		Bereich.WURZEL:
			moeglich = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
		Bereich.HANG, Bereich.WANDFUSS:
			moeglich = [Vector2i(2, 2), Vector2i(2, 2), Vector2i(0, 0), Vector2i(2, 3)]
		Bereich.WIESE, Bereich.WIESE_WEG:
			moeglich = [Vector2i(1, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(0, 0),
					Vector2i(2, 2), Vector2i(0, 4), Vector2i(2, 3)]
		_:
			moeglich = [Vector2i(1, 1), Vector2i(0, 0), Vector2i(2, 2), Vector2i(1, 1)]
	var wahl := moeglich[rng.randi() % moeglich.size()]
	var schluessel := "bluete_%d_%d" % [wahl.x, wahl.y]
	if not b.teile.has(schluessel):
		var formen := []
		var frng := PropWerkzeug.zufall(wahl.x * 31 + wahl.y * 7 + 5)
		for i in 4:
			formen.append(Bodenstreu.blueten(frng, wahl.x, Bodenstreu.BLUETEN_FARBEN[wahl.y],
					frng.randf_range(0.18, 0.32)))
		b.teile[schluessel] = formen
	_teil(b, s, p, schluessel, rng.randf_range(0.85, 1.2))


## Ein Moospolster (Rasensaum.polster) im Stoff des Rasens: `wurzel` auf
## dem Moos des Wurzelrückens (dort ist der Boden dunkler).
static func _polster(b: Bau, s: float, p: Vector3, mass: float, wurzel: bool,
		kronen: float) -> void:
	var rng := b.rng
	var sa := b.sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) \
			* Basis.from_scale(Vector3(mass, mass * rng.randf_range(0.6, 1.1), mass))
	var lage := Transform3D(basis, p - Vector3(0.0, 0.015, 0.0))
	var farbe := Rasensaum.farbe(0.8 if wurzel else 0.85, 1.0, rng.randf_range(0.2, 0.7), kronen)
	if wurzel:
		sa.moospolster.append(lage)
		sa.moospolster_farben.append(farbe)
	else:
		sa.polster.append(lage)
		sa.polster_farben.append(farbe)


## Ein kleiner Farn (Farnwerk.klein) ins Feld des Stücks.
static func _farn(b: Bau, s: float, p: Vector3, mass: float) -> void:
	var rng := b.rng
	var sa := b.sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	sa.farn.append(Transform3D(basis, p - Vector3(0.0, 0.03, 0.0)))
	sa.farn_farben.append(_laub(rng, 1.0))


static func _grossblatt(b: Bau, s: float, p: Vector3, mass: float) -> void:
	var rng := b.rng
	var sa := b.sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	sa.gross.append(Transform3D(basis, p - Vector3(0.0, 0.03, 0.0)))
	sa.gross_farben.append(_laub(rng, 1.1) * Color(0.95, 1.0, 0.85))


## Laubgrün (linear) mit ±12 % Streuung, `hell` als Faktor.
static func _laub(rng: RandomNumberGenerator, hell: float) -> Color:
	var g := Farben.LAUB.srgb_to_linear()
	var t := rng.randf_range(0.85, 1.15) * hell
	return Color(g.r * t * rng.randf_range(0.9, 1.15), g.g * t, g.b * t * rng.randf_range(0.85, 1.1))


## Ein Rahmenfarn (2–3 m) an `p`.
static func _rahmenfarn(b: Bau, s: float, p: Vector3, mass: float) -> void:
	var rng := b.rng
	var sa := b.sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	sa.rahmen.append(Transform3D(basis, p - Vector3(0.0, 0.05, 0.0)))
	sa.rahmen_farben.append(_laub(rng, 1.3))


## Wispelgras an einer Kante: `aussen` zeigt über die Kante hinaus.
static func _wispel(b: Bau, s: float, p: Vector3, aussen: Vector3, ao: float) -> void:
	var rng := b.rng
	if rng.randf() >= b.dichte_faktor:
		return
	var x := Vector3(aussen.x, 0.0, aussen.z).normalized()
	var z := x.cross(Vector3.UP).normalized()
	var mass := rng.randf_range(0.8, 1.25)
	var basis := Basis(x, Vector3.UP, z) * Basis(Vector3.UP, rng.randf_range(-0.35, 0.35)) \
			* Basis.from_scale(Vector3(mass, mass * rng.randf_range(0.85, 1.15), mass))
	var sa := b.sammlung(s)
	sa.wispel.append(Transform3D(basis, p))
	sa.wispel_farben.append(Rasensaum.farbe(ao, 1.0, rng.randf_range(0.3, 0.8), 0.0))


# ================================================================ Weg und Ränder

## Die Wegdecke einer Seite an der Lage `l`: Büschel nach der Maske, die
## innere Reihe an der Trittkante gekippt.
static func _decke(b: Bau, l: Lage, seite: float, dichte: float, bereich: int,
		lippe: float = INF) -> void:
	if l.halb <= 0.0:
		return
	var rng := b.rng
	var pendel := Wegmaske.pendel(l.s)
	var k := 0
	while true:
		var q := seite * (float(k) + rng.randf()) * RASTER
		k += 1
		if absf(q) > l.halb:
			break
		var s := l.s + rng.randf_range(-0.14, 0.14)
		var p := l.punkt(q)
		var w := Wegmaske.welt(Vector2(p.x, p.z))
		var qn := q / l.halb
		var m := Wegmaske.wert_aus(qn, s, w.r)
		if m < 0.2:
			continue
		# Die innere Reihe: an der Trittkante (m 0,3–0,7) dichter, und die
		# Büschel legen sich über die Erde zur Spur hin.
		var kante := smoothstep(0.25, 0.45, m) * (1.0 - smoothstep(0.55, 0.75, m))
		var zur_spur := -signf(qn - pendel)
		var kipp := l.rechts * zur_spur * deg_to_rad(rng.randf_range(25.0, 40.0))
		# Vor der Lippe hohes Gras: Die Kante franst aus, statt als Linie zu enden.
		var hoch := 1.0 - smoothstep(0.1, 0.8, lippe - absf(q))
		_stelle(b, s, q, p, m, Wegmaske.verdeckung(qn), l.kronen, dichte * m * m, hoch, bereich,
				kipp, DICHTE_KANTE * kante)


## Boden bündig mit der Decke von |q| `von` bis `bis` (Vorsprünge, Nische,
## Streifen am Wandfuß): voller Rasen; `hoch_ab`: ab hier hohes Gras.
static func _boden(b: Bau, l: Lage, seite: float, von: float, bis: float, dichte: float,
		bereich: int, hoch_ab: float = INF) -> void:
	var rng := b.rng
	var q_lauf := von
	while q_lauf < bis:
		var q := seite * minf(q_lauf + rng.randf() * RASTER, bis - 0.02)
		q_lauf += RASTER
		var s := l.s + rng.randf_range(-0.14, 0.14)
		var p := l.punkt(q)
		p.y -= 0.015
		var hoch := smoothstep(hoch_ab - 0.2, hoch_ab + 0.2, absf(q))
		_stelle(b, s, q, p, 1.0, lerpf(0.78, 0.88, smoothstep(0.0, 1.5, absf(q) - l.halb)),
				l.kronen, dichte, hoch, bereich)


## Gelände bündig am Weg (A, D): von |q| `von` bis `bis`, solange es auf
## Deckenhöhe liegt (kein Abbruch, kein Spalt), lichter, wo Wald steht.
static func _gelaende(b: Bau, l: Lage, seite: float, von: float, bis: float, dichte: float,
		bereich: int, wald_bereich: int) -> void:
	var rng := b.rng
	var q_lauf := von
	while q_lauf < bis:
		var q := seite * (q_lauf + rng.randf() * RASTER)
		q_lauf += RASTER
		var s := l.s + rng.randf_range(-0.14, 0.14)
		var p := l.punkt(q)
		var y := L01Gelaende.hoehe(p.x, p.z)
		if is_nan(y) or absf(y - l.mitte.y) > 0.6:
			continue
		if absf(b.hoehe_zelle(l.punkt(q + seite * 0.5)) - y) > 0.3:
			continue
		p.y = y
		var wald := b.wald(p)
		var aussen := absf(q) - l.halb
		var ao := lerpf(Wegmaske.RAND_VERDECKUNG, 1.0, smoothstep(0.0, 2.5, aussen)) \
				* lerpf(1.0, 0.38, wald)
		var g := 1.0 - smoothstep(0.15, 0.6, wald)
		_stelle(b, s, q, p, 1.0, ao, l.kronen, dichte * g, 0.0,
				bereich if wald < 0.35 else wald_bereich)


## Die Böschung links hinauf (auf der gebauten Fläche des Saums), bis
## `hoehe_max` über der Kante: Büschel je nach Neigung, Farne und Moos.
static func _hang(b: Bau, l: Lage, hoehe_max: float, dichte: float) -> void:
	var rng := b.rng
	var punkte := PackedVector3Array()
	var h := 0.06
	while h <= hoehe_max + 0.01:
		var p := GelaendeSaum.flaeche_punkt(l.s, -1.0, h)
		if is_nan(p.x):
			break
		punkte.append(p)
		h += 0.22
	for i in punkte.size() - 1:
		var a := punkte[i]
		var c := punkte[i + 1]
		var laenge := a.distance_to(c)
		var flach := Vector2(c.x - a.x, c.z - a.z).length()
		var steil := 1.0 - flach / maxf(laenge, 0.001)
		# Über 60° wächst kaum etwas; ab 45° wird es licht.
		var d := dichte * (1.0 - smoothstep(0.3, 0.55, steil))
		var zellen := maxi(roundi(laenge / RASTER), 1)
		for k in zellen:
			var t := (float(k) + rng.randf()) / float(zellen)
			var s := l.s + rng.randf_range(-0.14, 0.14)
			var p := a.lerp(c, t)
			var q := (p - l.mitte).dot(l.rechts)
			_stelle(b, s, q, p - Vector3(0.0, 0.02, 0.0), 1.0, 0.8, 0.0, d, 0.0, Bereich.HANG)


## Wispelgras und hohes Gras an einer Lippe rechts (B/C), von der Lage `l`.
static func _lippe_rechts(b: Bau, l: Lage) -> void:
	var rng := b.rng
	var q_lippe := L01Saum.lippe_q(b.level, l.s, 1.0)
	var a := b.level.weg_punkt(l.s - 0.3, L01Saum.lippe_q(b.level, l.s - 0.3, 1.0))
	var c := b.level.weg_punkt(l.s + 0.3, L01Saum.lippe_q(b.level, l.s + 0.3, 1.0))
	var laengs := c - a
	laengs.y = 0.0
	var aussen := laengs.normalized().cross(Vector3.UP)
	if aussen.dot(l.rechts) < 0.0:
		aussen = -aussen
	if rng.randf() < 0.75:
		var p := l.punkt(q_lippe + rng.randf_range(0.0, 0.06))
		p.y -= 0.02
		_wispel(b, l.s, p, aussen, 0.8)
	if rng.randf() < 0.2:
		var p := l.punkt(q_lippe - rng.randf_range(0.2, 0.7))
		_teil(b, l.s, p, "kiesel", rng.randf_range(0.6, 1.1))


## Wispelgras an einer Querlippe (Lücke, Stufe): längs der Kante bei `s`,
## `richtung` +1: die Lücke liegt in +s. Nur außerhalb der Spur.
static func _lippe_quer(b: Bau, s: float, richtung: float, von_q: float, bis_q: float) -> void:
	var rng := b.rng
	var l := _lage(b, s)
	var pendel := Wegmaske.pendel(s) * maxf(l.halb, 0.1)
	var q := von_q
	while q < bis_q:
		q += rng.randf_range(0.3, 0.55)
		if absf(q - pendel) < l.halb * 0.62:
			continue
		var p := l.punkt(q) + l.vor * richtung * rng.randf_range(-0.04, 0.02)
		p.y = b.level.boden_bei(s - richtung * 0.05) - 0.02
		# Neben der Decke (Ufer der Furt) nur, wo das Gelände auf ihrer Höhe
		# liegt – sonst hinge das Gras in der Luft.
		if absf(q) > l.halb + 0.1:
			var zurueck_p := l.punkt(q) - l.vor * richtung * 0.3
			if absf(L01Gelaende.hoehe(zurueck_p.x, zurueck_p.z) - p.y) > 0.15:
				continue
		_wispel(b, s, p, l.vor * richtung, 0.8)
		# Dahinter hohes Gras (nicht in der Spur, nicht an Kisten)
		var zurueck := rng.randf_range(0.12, 0.5)
		var sq := s - richtung * zurueck
		if rng.randf() < 0.8 * b.dichte_faktor and b.kiste_abstand(sq, q) > KISTE_HOCH \
				and b.sperr_abstand(sq, q) > 0.05:
			var h := b.level.weg_punkt(sq, q)
			h.y -= 0.012
			var sa := b.sammlung(sq)
			sa.bueschel.append(_bueschel_lage(rng, h, rng.randf_range(0.42, 0.58),
					l.vor * richtung * deg_to_rad(rng.randf_range(10.0, 30.0))))
			sa.bueschel_farben.append(Rasensaum.farbe(0.82, 1.0, rng.randf_range(0.3, 0.8),
					l.kronen))


# ================================================================ Abschnitte

## A (bis 33): Hallenwald. Auf dem Weg Rasen nach der Maske, daneben der
## Waldboden mit Farnen, Moos und Leuchtpilzen. Rahmenfarne links.
static func _waldsaum(b: Bau) -> void:
	var s := -3.0
	while s < 33.0:
		var l := _lage(b, s)
		if l.halb > 0.0:
			for seite: float in [-1.0, 1.0]:
				_decke(b, l, seite, DICHTE_SCHULTER, Bereich.SCHULTER)
				_gelaende(b, l, seite, l.halb, l.halb + 4.5, DICHTE_SCHULTER,
						Bereich.SCHULTER, Bereich.WALD)
		s += RASTER
	for g: float in [25.0, 27.5]:
		_lippe_quer(b, g, 1.0 if g < 26.0 else -1.0, -5.0, 5.0)
	_rahmenfarne(b, -1.0, 4.0, 32.0, 6.5, 8.0)


## B (33–104): Hangweg. Rechts bis an die Lippe, links bis zum Fuß der
## Böschung und hinauf.
static func _hangweg(b: Bau) -> void:
	var s := 33.0
	while s < 104.0:
		var l := _lage(b, s)
		var luecke := l.halb <= 0.0
		var platte := s > 33.2 and s < 50.8
		if not luecke:
			_decke(b, l, -1.0, DICHTE_SCHULTER, Bereich.SCHULTER)
			_decke(b, l, 1.0, DICHTE_SCHULTER, Bereich.SCHULTER,
					INF if platte else L01Saum.lippe_q(b.level, s, 1.0))
		var halb := float(b.level.rand_profil(s, 1.0)["wegrand"])
		# rechts: Vorsprünge bis zur Lippe (nicht auf den Platten 33–51)
		if not luecke and not platte:
			var lippe := L01Saum.lippe_q(b.level, s, 1.0)
			if lippe > halb + 0.1:
				_boden(b, l, 1.0, halb, lippe - 0.05, DICHTE_SCHULTER, Bereich.SCHULTER, lippe - 0.6)
			_lippe_rechts(b, l)
		# links: Streifen bis zum Fuß, dann die Böschung
		var fuss := L01Saum.lippe_q(b.level, s, -1.0)
		if not luecke:
			_boden(b, l, -1.0, halb, fuss - 0.2, DICHTE_SCHULTER,
					Bereich.SCHULTER if fuss - halb < 1.0 else Bereich.HANG, fuss - 0.5)
		if s < 91.0 and (s < 55.0 or s > 60.0):
			_hang(b, l, 2.2 if s > 36.0 else 1.2, DICHTE_HANG)
		elif s >= 91.0:
			_hang(b, l, 0.35, DICHTE_HANG)
		s += RASTER
	for g: Vector2 in [Vector2(56.0, 1.0), Vector2(59.0, -1.0), Vector2(66.0, 1.0)]:
		_lippe_quer(b, g.x, g.y, -5.0, 5.0)
	_rahmenfarne(b, -1.0, 36.0, 102.0, 5.7, 7.0)


## C (104–160): Fallklamm. Rechts bis an die Lippe (C4: das Ufer), links der
## Streifen am Wandfuß mit hohem Gras, Farnen und Großblättern.
static func _fallklamm(b: Bau) -> void:
	var s := 104.0
	while s < 160.0:
		var l := _lage(b, s)
		var luecke := l.halb <= 0.0
		if not luecke:
			_decke(b, l, -1.0, DICHTE_SCHULTER, Bereich.SCHULTER)
			_decke(b, l, 1.0, DICHTE_SCHULTER, Bereich.SCHULTER, L01Saum.lippe_q(b.level, s, 1.0))
			_lippe_rechts(b, l)
			var fuss := L01Saum.lippe_q(b.level, s, -1.0)
			# Am Felsbecken (112–122) weicht die Wand zurück: nur der Streifen.
			var bis := minf(fuss - 0.15, l.halb + 1.2) if s > 111.0 and s < 123.0 else fuss - 0.15
			_boden(b, l, -1.0, l.halb, bis, DICHTE_SCHULTER, Bereich.WANDFUSS, fuss - 0.5)
		s += RASTER
	for g: Vector2 in [Vector2(118.0, 1.0), Vector2(121.0, -1.0), Vector2(133.0, 1.0),
			Vector2(145.0, 1.0)]:
		_lippe_quer(b, g.x, g.y, -4.5, 4.5)
	_rahmenfarne(b, -1.0, 106.0, 158.0, 5.2, 8.0)


## D (160–198): Bachwiese. Die Wiese reicht zu beiden Seiten weit hinaus;
## an der Furt hohes Gras an den Ufern.
static func _bachwiese(b: Bau) -> void:
	var s := 159.0
	while s < 198.0:
		var l := _lage(b, s)
		if l.halb > 0.0:
			for seite: float in [-1.0, 1.0]:
				_decke(b, l, seite, DICHTE_WIESE_WEG, Bereich.WIESE_WEG)
				# Ufer der Furt: die letzten Meter vor dem Wasser hoch
				var ufer := 1.0 - smoothstep(0.6, 2.0, minf(absf(s - 173.0), absf(s - 183.0)))
				_gelaende(b, l, seite, l.halb, 12.5, DICHTE_WIESE_RAND * lerpf(1.0, 0.8, ufer),
						Bereich.WIESE, Bereich.WALD)
		s += RASTER
	# Die Furt: hohes Gras an den Ufern, Großblätter.
	for g: Vector2 in [Vector2(173.0, 1.0), Vector2(183.0, -1.0)]:
		_lippe_quer(b, g.x, g.y, -12.0, 12.0)
		var rng := b.rng
		for i in 7:
			var q := rng.randf_range(-11.0, 11.0)
			if absf(q) < 5.0:
				continue
			var l := _lage(b, g.x - g.y * rng.randf_range(0.3, 1.0))
			var p := l.punkt(q)
			p.y = L01Gelaende.hoehe(p.x, p.z)
			if absf(p.y - l.mitte.y) < 0.5 and b.sperr_abstand(l.s, q) > 0.5:
				_grossblatt(b, l.s, p, rng.randf_range(0.9, 1.3))
	_rahmenfarne(b, -1.0, 164.0, 196.0, 7.0, 7.0)
	_rahmenfarne(b, 1.0, 166.0, 196.0, 7.2, 9.0)
	# Die Wurzelwiese unter dem Aufgang (y 7,0) und der Wiesenboden unter G1.
	s = 196.0
	while s < 214.0:
		var l := _lage(b, s)
		var von := 4.3 if s < 210.0 else -4.0
		_wiese_unten(b, l, von, 12.0)
		s += RASTER


## Die Wurzelwiese (unter dem Weg, auf 7,0) von q `von` bis `bis`.
static func _wiese_unten(b: Bau, l: Lage, von: float, bis: float) -> void:
	var rng := b.rng
	var q := von
	while q < bis:
		var qq := q + rng.randf() * RASTER
		q += RASTER
		var p := l.punkt(qq)
		var y := L01Gelaende.hoehe(p.x, p.z)
		if is_nan(y) or absf(y - L01Gelaende.WIESE_Y) > 0.3:
			continue
		p.y = y
		var wald := b.wald(p)
		_stelle(b, l.s + rng.randf_range(-0.14, 0.14), qq, p, 1.0, lerpf(0.95, 0.5, wald), 0.3,
				DICHTE_WIESE_RAND * (1.0 - smoothstep(0.2, 0.6, wald)), 0.0, Bereich.WIESE)


## E/F: Wurzelrücken. Kein Gras auf der Borke: Auf dem Moos der Flanken
## stehen Moosflecken (`Rasensaum.moosfleck`, 6–14 cm, in der Moosfarbe des
## Wegbodens) – licht auf der ganzen Fläche, dicht im Saum zur Borke, wo
## sie sich über die Borke legen –, dazu Moospolster, kleine Farne und ein
## paar Blüten. In den Querrissen (dieselbe Rechnung wie der Shader,
## `_riss`) wächst Moos, dazwischen Farne und Leuchtpilze. Die Borke in der
## Spur bleibt frei. Die ersten Meter der Wurzel sind noch Erde (Wegboden:
## `erdig`); dort steht kein Moos.
static func _wurzel(b: Bau) -> void:
	var rng := b.rng
	var s := Level01.M_WENDEL + 3.0
	while s < Level01.M_ENDE - 0.5:
		var l := _lage(b, s)
		if l.halb > 0.0:
			for seite: float in [-1.0, 1.0]:
				var k := 0
				while true:
					var qa := l.halb * 0.3 + (float(k) + rng.randf()) * RASTER
					k += 1
					if qa > l.halb - 0.1:
						break
					var q := seite * qa
					var ss := l.s + rng.randf_range(-0.14, 0.14)
					var kiste := b.kiste_abstand(ss, q)
					var sperre := b.sperr_abstand(ss, q)
					if kiste < KISTE_FREI or sperre < 0.1:
						continue
					var p := l.punkt(q)
					var w := Wegmaske.welt(Vector2(p.x, p.z))
					var qn := q / l.halb
					var m := Wegmaske.wert_aus(qn, ss, w.r)
					# Moos frisst ungleich weit in die Decke (wie im Shader).
					var fressen := ((w.b - 0.5) * 0.9 + (w.r - 0.5) * 0.7) \
							* smoothstep(0.3, 0.75, absf(qn))
					var moos := clampf(m + fressen, 0.0, 1.0)
					var riss := _riss(qn, ss, w)
					if riss > 0.5:
						var r := rng.randf()
						if r < 0.55 * b.dichte_faktor:
							_moos(b, ss, p, rng.randf_range(0.05, 0.1), Vector3.ZERO,
									rng.randf_range(0.5, 0.8), l.kronen)
						elif r < 0.66 and moos > 0.3 and kiste > KISTE_HOCH:
							_farn(b, ss, p, rng.randf_range(0.45, 0.75))
						elif r < 0.76:
							_teil(b, ss, p, "pilz_leucht", rng.randf_range(0.7, 1.1))
						continue
					if moos < 0.45:
						# Vor dem Saum kleine Moosinseln auf der Borke: Die Grenze
						# franst aus, statt als Linie längs der Wurzel zu laufen.
						var insel := smoothstep(0.22, 0.45, moos) * 1.6 * b.dichte_faktor
						if rng.randf() * DICHTE_MAX < insel:
							_moos(b, ss, p, rng.randf_range(0.04, 0.07), Vector3.ZERO,
									rng.randf_range(0.45, 0.75), l.kronen)
						continue
					# Im Saum zur Borke dicht und über sie gelegt (zur Spur hin),
					# auf der Fläche licht und aufrecht.
					var saum := smoothstep(0.45, 0.58, moos) * (1.0 - smoothstep(0.7, 0.9, moos))
					var dichte := (DICHTE_MOOS + DICHTE_MOOS_SAUM * saum) * b.dichte_faktor
					if rng.randf() * DICHTE_MAX < dichte:
						var kipp := Vector3.ZERO
						if saum > 0.4:
							kipp = l.rechts * -seite * deg_to_rad(rng.randf_range(15.0, 35.0))
						_moos(b, ss, p, rng.randf_range(0.06, 0.1) * lerpf(1.0, 1.45, saum), kipp,
								rng.randf_range(0.9, 1.4), l.kronen)
					_streu(b, ss, q, p, 1.0, Bereich.WURZEL, kiste, sperre, l.kronen)
		s += RASTER


## Ein Moosfleck (Rasensaum.moosfleck) der Höhe `h`, waagerecht `breit`
## mal so groß, auf Wunsch nach `kipp` gelegt (Richtung × Winkel in rad).
static func _moos(b: Bau, s: float, p: Vector3, h: float, kipp: Vector3, breit: float,
		kronen: float) -> void:
	var rng := b.rng
	var mass := h / Rasensaum.BEZUG
	var quer := breit * rng.randf_range(0.85, 1.15)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(quer, mass, quer))
	var winkel := kipp.length()
	if winkel > 0.001:
		basis = Basis(Vector3.UP.cross(kipp / winkel).normalized(), winkel) * basis
	var sa := b.sammlung(s)
	sa.moos.append(Transform3D(basis, p - Vector3(0.0, 0.01, 0.0)))
	sa.moos_farben.append(Rasensaum.farbe(0.8, 1.0, rng.randf_range(0.2, 0.8), kronen))


## Ein Querriss des Wurzelrückens an (q/halbe Breite, s) wie im Shader
## (`wegboden.gdshader`, Fassung Wurzelrücken): 0..1.
static func _riss(qn: float, s: float, w: Color) -> float:
	var qm := qn * 4.0
	var sl := s + (w.r - 0.5) * 3.0
	var lauf := sl * 0.35 + w.b * 1.7
	var t := lauf - floorf(lauf)
	var id := floorf(lauf + 0.5)
	var breite := (0.08 + 0.1 * (id * 0.618 - floorf(id * 0.618))) * (0.7 + 0.5 * sin(qm * 1.9 + id))
	var abstand := minf(t, 1.0 - t) * 2.0
	var riss := 1.0 - smoothstep(breite * 0.35, breite, abstand)
	return riss * smoothstep(-0.25, 0.35, sin(qm * 0.85 + id * 2.37))


## Rahmenfarne auf einer Seite von `von` bis `bis`: je 7–11 m einer, bei
## |q| `q_von`..`q_bis`, auf dem Gelände bzw. an der gebauten Fläche.
static func _rahmenfarne(b: Bau, seite: float, von: float, bis: float, q_von: float,
		q_bis: float) -> void:
	var rng := b.rng
	var s := von + rng.randf_range(0.0, 4.0)
	while s < bis:
		var q := seite * rng.randf_range(q_von, q_bis)
		var l := _lage(b, s)
		var p := l.punkt(q)
		var y := NAN
		# An der Böschung/Wand: auf der gebauten Fläche knapp über dem Fuß.
		var saum := GelaendeSaum.flaeche_punkt(s, seite, rng.randf_range(0.15, 0.5)) \
				if seite < 0.0 and s > 33.0 and s < 160.0 else Vector3(NAN, NAN, NAN)
		if not is_nan(saum.x):
			p = saum + l.rechts * seite * 0.15
			y = saum.y - 0.05
		else:
			y = L01Gelaende.hoehe(p.x, p.z)
			if absf(y - l.mitte.y) > 1.0:
				y = NAN
		# K8: Die Wedel reichen gut 2,4 m je Maß nach innen; ihre Spitzen
		# bleiben 6 m vor der Kamera außerhalb der mittleren 40 % des Bildes
		# (|q| ≥ 0,4 · 6 m · tan 45,75° ≈ 2,5 m). Wo die Wand nahe am Weg
		# steht (Fallklamm), wird der Farn kleiner oder fällt weg.
		var q_ist := absf((p - l.mitte).dot(l.rechts))
		var mass := minf(rng.randf_range(0.85, 1.2), (q_ist - 2.5) / 2.4)
		if not is_nan(y) and mass >= 0.6 and b.kiste_abstand(s, seite * q_ist) > 2.0 \
				and b.sperr_abstand(s, seite * q_ist) > 0.6:
			p.y = y
			_rahmenfarn(b, s, p, mass)
		s += rng.randf_range(7.0, 11.0)


# ================================================================ Netze

## Legt je Stück die Netze an (unter `Deko/Rasen`).
static func _netze(b: Bau) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Rasen"
	b.level.deko.add_child(wurzel)
	var schluessel := b.sammlungen.keys()
	schluessel.sort()
	var farn_netze: Array[ArrayMesh] = [Farnwerk.klein(3), Farnwerk.klein(8), Farnwerk.klein(13)]
	var rahmen_netze: Array[ArrayMesh] = [Farnwerk.rahmen(5), Farnwerk.rahmen(9)]
	var gross_rng := PropWerkzeug.zufall(4411)
	var gross_netze: Array[ArrayMesh] = [Bodenstreu.grossblatt(gross_rng, 1.0).netz(),
			Bodenstreu.grossblatt(gross_rng, 1.0).netz()]
	# Stilmodelle für Farne und Großblätter, wenn natur2 sie hat (M12, M13).
	var farn_fremd := _fremd("M12")
	var gross_fremd := _fremd("M13")
	var gesamt := 0
	for i: int in schluessel:
		var sa: Sammlung = b.sammlungen[i]
		var n := posmod(i, 3)
		# Jeder zweite Fleck nur in der Nähe (siehe SICHT_DICHT).
		var weit: Array[Transform3D] = []
		var weit_farben := PackedColorArray()
		var nah: Array[Transform3D] = []
		var nah_farben := PackedColorArray()
		for k in sa.gras.size():
			# Im Web ist die Dichte ohnehin halb: alles in einer Lage.
			if k % 2 == 0 or b.reduziert:
				weit.append(sa.gras[k])
				weit_farben.append(sa.gras_farben[k])
			else:
				nah.append(sa.gras[k])
				nah_farben.append(sa.gras_farben[k])
		Rasensaum.feld(wurzel, "Gras %d" % i, Rasensaum.fleck(11 + n), weit, weit_farben,
				SICHT_GRAS)
		Rasensaum.feld(wurzel, "Gras nah %d" % i, Rasensaum.fleck(14 + n), nah, nah_farben,
				SICHT_DICHT)
		Rasensaum.feld(wurzel, "Bueschel %d" % i, Rasensaum.bueschel(31 + n), sa.bueschel,
				sa.bueschel_farben, SICHT_GRAS)
		Rasensaum.feld(wurzel, "Wispel %d" % i, Rasensaum.wispel(21 + n), sa.wispel,
				sa.wispel_farben, SICHT_WISPEL)
		Rasensaum.feld(wurzel, "Moos %d" % i, Rasensaum.polster(41 + n), sa.polster,
				sa.polster_farben, SICHT_STREU)
		# Wurzelrücken: Moos in der Moosfarbe des Wegbodens (eigener Stoff).
		Rasensaum.feld(wurzel, "Borkenmoos %d" % i, Rasensaum.moosfleck(51 + n), sa.moos,
				sa.moos_farben, SICHT_GRAS, true)
		Rasensaum.feld(wurzel, "Borkenpolster %d" % i, Rasensaum.polster(44 + n),
				sa.moospolster, sa.moospolster_farben, SICHT_STREU, true)
		if sa.haufen != null:
			sa.haufen.knoten(wurzel, "Streu %d" % i, SICHT_STREU)
			gesamt += sa.haufen.dreiecke()
		if farn_fremd.is_empty():
			Bodenstreu.feld(wurzel, "Farne %d" % i, farn_netze[n], sa.farn, sa.farn_farben,
					SICHT_FARN)
		else:
			_fremd_felder(wurzel, "Farne %d" % i, farn_fremd, sa.farn)
		if gross_fremd.is_empty():
			Bodenstreu.feld(wurzel, "Grossblatt %d" % i, gross_netze[posmod(i, 2)], sa.gross,
					sa.gross_farben, SICHT_FARN)
		else:
			_fremd_felder(wurzel, "Grossblatt %d" % i, gross_fremd, sa.gross)
		Bodenstreu.feld(wurzel, "Rahmenfarne %d" % i, rahmen_netze[posmod(i, 2)], sa.rahmen,
				sa.rahmen_farben, SICHT_FARN)
		gesamt += sa.gras.size() * 30 + sa.bueschel.size() * 27 + sa.wispel.size() * 42 \
				+ sa.moos.size() * 40 + (sa.polster.size() + sa.moospolster.size()) * 45
	if b.level.debug:
		print("Rasen: %d Stücke, %d Dreiecke" % [schluessel.size(), gesamt])


## Die Stilmodelle einer Rolle aus natur2 (`Fremdmodelle.rolle`), als
## Netze. Die Kenney-Stufe bleibt hier außen vor: Der Rasen steht ganz nah
## an der Kamera, und aus der Nähe lesen sich deren Pflanzen als Klötzchen
## (siehe `Fremdmodelle.ROLLEN`, "kenney_ab"). Leer: prozeduraler Rückfall.
static func _fremd(kennung: String) -> Array[Dictionary]:
	var netze: Array[Dictionary] = []
	var optionen := Fremdmodelle.rolle_optionen(kennung)
	for name in Fremdmodelle.rolle(kennung):
		if not name.contains("/"):
			continue
		var netz := Fremdmodelle.netz(name, optionen)
		if not netz.is_empty():
			netze.append(netz)
	return netze


## Je Modell ein MultiMesh (alle Flächen samt ihren Stoffen), die Lagen
## reihum verteilt; ohne Schatten (Plan 13: Laub wirft keinen).
static func _fremd_felder(eltern: Node3D, name: String, modelle: Array[Dictionary],
		lagen: Array[Transform3D]) -> void:
	for j in modelle.size():
		var eigene: Array[Transform3D] = []
		for i in range(j, lagen.size(), modelle.size()):
			eigene.append(lagen[i])
		if eigene.is_empty():
			continue
		var mitte := Vector3.ZERO
		for l in eigene:
			mitte += l.origin
		mitte /= float(eigene.size())
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = modelle[j]["mesh"] as Mesh
		mm.instance_count = eigene.size()
		for i in eigene.size():
			mm.set_instance_transform(i, Transform3D(eigene[i].basis, eigene[i].origin - mitte))
		var mi := MultiMeshInstance3D.new()
		mi.name = "%s %d" % [name, j]
		mi.multimesh = mm
		mi.position = mitte
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = SICHT_FARN
		mi.visibility_range_end_margin = 2.0
		eltern.add_child(mi)
