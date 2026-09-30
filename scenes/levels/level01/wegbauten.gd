extends RefCounted
class_name L01Wegbauten
## Level 01, Modul „Wegbauten": die Setpieces am Weg (Plan 5A–5D, 8.6, K7).
##
##   A  Wurzelnest hinter dem Start, Waldtor (s 3) zwischen zwei Stämmen,
##      Mooslog (s 8) mit Farn an den Enden, Wurzeln im Erdspalt, der
##      Enthüllungsrahmen: ein toter Baum (s 28) und ein Findling (s 31)
##   B  Totholzgeländer (s 33–50) um die Kanzel mit geborstenem Endpfosten,
##      Kanzelplatte mit Drehkiefer, Wurzeln in der Kerbe, Spornfels,
##      Hangstamm, Nischenboden und Moosbank, die Torbaum-Pforte (links
##      Fels, rechts eine Wurzel des Torbaums) samt Pfortentor
##   D  Riesentor (s 162), Trittsteine der Furt, Findlingsturm, Wurzelknie
##
## FINDLING-REGEL (Plan E13, 8.6). Was man betreten kann, hat einen Körper
## aus `Level01.BEGEHBARES`, und die Optik passt genau darauf: Oberseite =
## Kollisionsoberkante, nichts ragt über den Kasten hinaus, was die Figur
## treffen könnte. Steine baut `Findling`, liegende Stämme `Riesenstamm.
## liegend` in derselben Lage wie die Kapsel, Wurzelkörper `_wurzelkoerper`
## (Querschnitt mit flacher, bemooster Oberseite, auf den Kasten geklemmt).
## Kisten stehen auf der ebenen Fläche (`Findling.plateau`): Die Steine
## unter Kisten haben deshalb eine knappe Kante (`_mit_kisten`).
## Alles andere – Wurzeln, Äste, Farne, Deko-Felsen – steht so, dass man
## es nicht erreicht: hinter einer Leitlinie, über dem Abgrund, unter dem
## Weg oder niedriger als 0,35 m.
##
## KAMERA (Plan K1, K2). Nichts davon hat Kollision, der Kamerastrahl (1|8)
## trifft also nichts außer den Sichtsperren der Tore. Innerhalb |q| ≤ 6
## steht über dem Weg nichts tiefer als 8,8 m; Kronen am Weg lehnen nach
## außen. Die Rahmenbäume rechts (toter Baum, Drehkiefer, Torbaum) sind so
## gestellt, dass sie den Weltenbaum aus den Enthüllungsbildern (s 22–46)
## nicht verdecken: der tote Baum lehnt über den Abgrund, die Drehkiefer
## trägt ihre Krone tief und weit draußen.
##
## KOSTEN. `optik()` liefert für jeden Eintrag nur eine leere Marke; die
## Netze baut der Bauschritt je Abschnittsstück verschmolzen, je Stoff
## eines (Plan: „je Abschnitt verschmolzen"). Schatten werfen nur Stein und
## Holz, nie Laub, Farn oder Kranz. Stücke: A, B vorn (33–66), B hinten
## (66–104), D – an jeder Station sind höchstens zwei in Sicht.

## Borkentönung der Kiefern: rötlich, heller oben (Eigenfarbe ≤ 1).
const KIEFER_TON := Color(1.0, 0.8, 0.66)
## Nadeln der Kiefern: dunkles, kühles Grün.
const NADEL := Color(0.17, 0.31, 0.18)
## Laub der Hallenbäume am Waldtor.
const HALLENLAUB := Color(0.2, 0.4, 0.16)
## So weit (m) bleibt Bewuchs von der Mitte einer Kiste weg.
const KISTEN_FREI := 1.3


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Wurzelnest, Mooslog und Waldtor", "tun": func() -> void: _waldsaum(level)},
		{"text": "Geländer und Kanzel am Hangweg", "tun": func() -> void: _hangweg_vorn(level)},
		{"text": "Moosbank und Torbaum-Pforte", "tun": func() -> void: _hangweg_hinten(level)},
		{"text": "Trittsteine und Riesentor", "tun": func() -> void: _bachwiese(level)},
	]


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "wegbauten".
## Nur eine leere Marke: Die Netze entstehen verschmolzen je Abschnitt in
## den Bauschritten (siehe Kopf) – passgenau auf dieselbe Lage.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	var marke := Node3D.new()
	marke.name = "Optik (Wegbauten)"
	return marke


# ================================================================ Sammler

## Sammelt Netze je Stoff und legt sie am Ende als je EINE MeshInstance an.
## Alle Netze eines Schlüssels müssen dasselbe Scheitelformat haben und
## entweder alle indiziert sein oder keines (`SurfaceTool.append_from`
## führt die Indizes nur für indizierte Netze fort). Was direkt gebaut
## wird (Äste, Wurzeln, Zaun), geht deshalb in einen eigenen Rohsammler
## (`roh()`), der zum Schluss fertig gemacht und angehängt wird.
class Sammler:
	extends RefCounted
	var wurzel: Node3D
	var _werkzeuge := {}
	var _roh := {}
	var _stoffe := {}
	var _schatten := {}
	var _weiten := {}

	func _init(eltern: Node3D, name: String) -> void:
		wurzel = Node3D.new()
		wurzel.name = name
		eltern.add_child(wurzel)

	## Hängt `netz` (alle Flächen) mit `trafo` unter dem Stoff `schluessel` an.
	func dazu(schluessel: String, stoff: Material, schatten: bool, netz: Mesh,
			trafo: Transform3D = Transform3D.IDENTITY) -> void:
		if netz == null:
			return
		var st := werkzeug(schluessel, stoff, schatten)
		for f in netz.get_surface_count():
			st.append_from(netz, f, trafo)

	## Der Sammler eines Stoffs, in den fertige Netze angehängt werden.
	func werkzeug(schluessel: String, stoff: Material, schatten: bool) -> SurfaceTool:
		if not _werkzeuge.has(schluessel):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_werkzeuge[schluessel] = st
			_stoffe[schluessel] = stoff
			_schatten[schluessel] = schatten
		return _werkzeuge[schluessel]

	## Rohsammler im Borkenformat für direkt gebaute Teile eines Stoffs;
	## `fertig()` verschmilzt ihn (`Riesenstamm.fertig`) und hängt ihn an.
	func roh(schluessel: String, stoff: Material, schatten: bool) -> SurfaceTool:
		werkzeug(schluessel, stoff, schatten)
		if not _roh.has(schluessel):
			_roh[schluessel] = Riesenstamm.bauer()
		return _roh[schluessel]

	## Hülle eines Stoffs weiten (Blattkarten wachsen erst im Shader).
	func weiten(schluessel: String, um: float) -> void:
		_weiten[schluessel] = um

	func fertig() -> void:
		for schluessel: String in _roh:
			var roh_netz := Riesenstamm.fertig(_roh[schluessel] as SurfaceTool)
			var ziel: SurfaceTool = _werkzeuge[schluessel]
			for f in roh_netz.get_surface_count():
				ziel.append_from(roh_netz, f, Transform3D.IDENTITY)
		_roh.clear()
		for schluessel: String in _werkzeuge:
			var st: SurfaceTool = _werkzeuge[schluessel]
			var netz := st.commit()
			if netz.get_surface_count() == 0:
				continue
			if _weiten.has(schluessel):
				netz.custom_aabb = netz.get_aabb().grow(float(_weiten[schluessel]))
			var mi := MeshInstance3D.new()
			mi.name = schluessel
			mi.mesh = netz
			mi.material_override = _stoffe[schluessel]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if _schatten[schluessel] \
					else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			wurzel.add_child(mi)
		_werkzeuge.clear()


static func _wurzel(level: Level01) -> Node3D:
	var knoten := level.geometrie.get_node_or_null("Wegbauten") as Node3D
	if knoten == null:
		knoten = Node3D.new()
		knoten.name = "Wegbauten"
		level.geometrie.add_child(knoten)
	return knoten


# ---------------------------------------------------------------- Stoffe

static func _stein(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Stein", Findling.stoff(), true, netz, trafo)


static func _kranz(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Kranz", Findling.kranzstoff(), false, netz, trafo)


static func _borke(sa: Sammler) -> SurfaceTool:
	return sa.roh("Borke", Riesenstamm.borkenstoff(), true)


static func _holz(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Borke", Riesenstamm.borkenstoff(), true, netz, trafo)


static func _krone(sa: Sammler, farbe: Color, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Krone", Kronenwolke.stoff(farbe), false, netz, trafo)
	sa.weiten("Krone", 1.2)


static func _farn(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Farn", Farnwerk.stoff(), false, netz, trafo)


# ================================================================ Lage

## Welttransform an (s, q, h): X quer nach rechts, Y hoch, −Z den Weg entlang.
static func _lage(level: Level01, s: float, q: float, h: float = 0.0,
		dreh: float = 0.0) -> Transform3D:
	var basis := Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s) + dreh)
	return Transform3D(basis, level.weg_punkt(s, q, h))


## Weltpunkt aus Wegkoordinaten (s, q, Höhe über der Decke).
static func _p(level: Level01, s: float, q: float, h: float = 0.0) -> Vector3:
	return level.weg_punkt(s, q, h)


## Orte aller Kisten, je Bauschritt einmal gelesen.
static var _kisten: Array[Vector3] = []


## Frei von Kisten? (Bewuchs hält `KISTEN_FREI` Abstand.)
static func _frei(p: Vector3, abstand: float = KISTEN_FREI) -> bool:
	for k in _kisten:
		if Vector2(k.x - p.x, k.z - p.z).length() < abstand:
			return false
	return true


# ================================================================ Bausteine

## Ein Findling genau auf einen Kasten aus BEGEHBARES, mit Verdeckungsring
## auf der Bodenhöhe `boden_h` (über der Decke; NAN = ohne Ring).
static func _findling_auf(sa: Sammler, level: Level01, name: String, optionen: Dictionary,
		boden_h: float = 0.0) -> void:
	var e := level.begehbar(name)
	if e.is_empty():
		return
	var groesse: Vector3 = e["groesse"]
	var lage: Transform3D = e["lage"]
	_stein(sa, Findling.netz(groesse, optionen), lage)
	if not is_nan(boden_h):
		var oben: float = e.get("oben", 0.0)
		var boden_lokal := boden_h - (oben - groesse.y * 0.5)
		_kranz(sa, _kranz_im_kasten(groesse, boden_lokal, optionen), lage)


## Verdeckungsring um einen Kasten auf der lokalen Höhe `y` (der Boden
## schneidet den Stein dort, nicht an seiner Unterkante).
static func _kranz_im_kasten(groesse: Vector3, y: float, optionen: Dictionary = {}) -> ArrayMesh:
	var h := groesse.abs() * 0.5
	var eckig: float = optionen.get("eckig", 3.6)
	var radien := PackedFloat32Array()
	for j in 40:
		var w := TAU * float(j) / 40.0
		var c := cos(w)
		var s := sin(w)
		var e := 2.0 / eckig
		var p := Vector2(h.x * signf(c) * pow(absf(c), e), h.z * signf(s) * pow(absf(s), e))
		radien.append(p.length())
	var breite := clampf(minf(h.x, h.z) * 0.6, 0.35, 1.0)
	return Findling.kranz(radien, y + 0.025, breite, 0.6, 0.2)


## Optionen für einen Stein, auf dem Kisten stehen: Die ebene Fläche
## (`Findling.plateau`) muss jede Kiste ganz tragen. Rundung und Umriss
## werden so weit verkleinert, bis das passt.
static func _mit_kisten(level: Level01, name: String, optionen: Dictionary) -> Dictionary:
	var e := level.begehbar(name)
	var groesse: Vector3 = e["groesse"]
	var lage: Transform3D = e["lage"]
	var noetig := Vector2.ZERO
	for k: Dictionary in Level01.KISTEN:
		if String(k.get("auf", "")) != name:
			continue
		var lokal := lage.affine_inverse() * level.kisten_ort(k)
		noetig.x = maxf(noetig.x, absf(lokal.x) + 0.5)
		noetig.y = maxf(noetig.y, absf(lokal.z) + 0.5)
	var o := optionen.duplicate()
	for versuch in 6:
		var platte := Findling.plateau(groesse, o)
		if platte.x >= noetig.x and platte.y >= noetig.y:
			break
		o["rundung"] = float(o.get("rundung", 0.3)) * 0.6
		o["umriss"] = float(o.get("umriss", 0.035)) * 0.5
		o["anlauf"] = float(o.get("anlauf", 0.06)) * 0.5
		o["unruhe"] = float(o.get("unruhe", 0.1)) * 0.6
	return o


## Ein Deko-Felsen (gewölbt, nicht zum Draufstehen) mit Ring, der Fuß auf
## der Bodenhöhe `trafo.origin`, `einsinken` Meter tiefer.
static func _brocken(sa: Sammler, groesse: Vector3, trafo: Transform3D, saat: int,
		einsinken: float = 0.25, optionen: Dictionary = {}) -> void:
	var o := {"saat": saat}
	o.merge(optionen, true)
	var t := trafo.translated_local(Vector3(0.0, groesse.y * 0.5 - einsinken, 0.0))
	_stein(sa, Findling.brocken(groesse, o), t)
	_kranz(sa, _kranz_im_kasten(groesse * 0.92, -groesse.y * 0.5 + einsinken, {"eckig": 2.6}), t)


## Farn an einer Stelle (Fuß auf `trafo`), `art` 0 klein, 1 groß, 2 Rahmen.
static func _farn_bei(sa: Sammler, trafo: Transform3D, art: int, saat: int,
		groesse: float = 1.0) -> void:
	var netz: ArrayMesh
	match art:
		0:
			netz = Farnwerk.klein(saat)
		1:
			netz = Farnwerk.gross(saat)
		_:
			netz = Farnwerk.rahmen(saat)
	_farn(sa, netz, trafo.scaled_local(Vector3.ONE * groesse))


## Eine Wurzel als Holzstück entlang `punkte` (Welt), dick am Anfang.
static func _wurzelstrang(sa: Sammler, punkte: PackedVector3Array, r0: float, r1: float,
		saat: int, optionen: Dictionary = {}) -> void:
	var radien := PackedFloat32Array()
	for i in punkte.size():
		radien.append(lerpf(r0, r1, float(i) / float(maxi(punkte.size() - 1, 1))))
	var o := {"saat": saat, "seiten": 7 if r0 > 0.12 else 5, "ende": "spitz", "moos": 0.35,
			"buckel": 0.1}
	o.merge(optionen, true)
	Totholzzaun.stueck(_borke(sa), punkte, radien, o)


## Glatte Kurve durch Stützpunkte (Catmull-Rom), `je` Punkte je Abschnitt.
static func _glatt(stuetzen: PackedVector3Array, je: int = 4) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var n := stuetzen.size()
	if n < 3:
		return stuetzen
	for i in n - 1:
		var p0 := stuetzen[maxi(i - 1, 0)]
		var p1 := stuetzen[i]
		var p2 := stuetzen[i + 1]
		var p3 := stuetzen[mini(i + 2, n - 1)]
		for k in je:
			var t := float(k) / float(je)
			var t2 := t * t
			var t3 := t2 * t
			aus.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	aus.append(stuetzen[n - 1])
	return aus


## Ein stehender Baum aus `Riesenstamm.netz` (Optionen dort) samt Ring, Fuß
## bei `trafo`. `ton` tönt die Borke über die Scheitelfarbe.
static func _stamm(sa: Sammler, trafo: Transform3D, optionen: Dictionary,
		ton: Color = Color(1.0, 1.0, 1.0)) -> ArrayMesh:
	var netz := Riesenstamm.netz(optionen)
	if ton != Color(1.0, 1.0, 1.0):
		netz = _getoent(netz, ton)
	_holz(sa, netz, trafo)
	var fuss: PackedFloat32Array = netz.get_meta("fuss_radien", PackedFloat32Array())
	if fuss.size() >= 3:
		_kranz(sa, Findling.kranz(fuss, 0.02, 1.2, 0.65, 0.3), trafo)
	return netz


## Kopie eines Netzes mit getönten Scheitelfarben (RGB · ton, A bleibt).
static func _getoent(netz: ArrayMesh, ton: Color) -> ArrayMesh:
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in farben.size():
			var c := farben[i]
			farben[i] = Color(c.r * ton.r, c.g * ton.g, c.b * ton.b, c.a)
		arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu


## Kronenpolster einer Kiefer: flache Wolke an `mitte` (Welt), Radius `r`.
static func _polster(sa: Sammler, mitte: Vector3, r: float, saat: int,
		farbe: Color = NADEL) -> void:
	var netz := Kronenwolke.netz({"radius": r, "hoehe": r * 0.62, "variante": 1, "saat": saat,
			"ballen": 6, "karten": clampi(int(r * r * 9.0), 30, 110)})
	_krone(sa, farbe, netz, Transform3D(Basis.IDENTITY, mitte))


## Ein Boden in Wegkoordinaten mit dem Stoff der Wegdecke: UV wie
## `LevelWerkzeuge.korridor` mit "uv_quer" (UV = Welt-XZ · 0,25, UV2 =
## (q / halbe Wegbreite, s)). Jenseits der Wegkante ist |UV2.x| > 1 – dort
## zeichnet der Wegboden Rasen, und die Naht zur Decke verschwindet.
## `umriss(s) -> Vector2(q_von, q_bis)`, `halb(s)` = halbe Wegbreite.
static func _boden(sa: Sammler, level: Level01, abschnitt: Dictionary, von: float, bis: float,
		umriss: Callable, halb: Callable, name: String) -> void:
	var stoff: Material = L01Boden.stoff(level, abschnitt)
	if stoff == null:
		stoff = Materialbibliothek.waldweg()
	var st := sa.werkzeug(name, stoff, false)
	var schritte := maxi(ceili((bis - von) / 0.5), 1)
	const QUER := 10
	var reihen: Array[PackedVector3Array] = []
	var uv2s: Array[PackedVector2Array] = []
	for i in schritte + 1:
		var s := lerpf(von, bis, float(i) / float(schritte))
		var q_bereich: Vector2 = umriss.call(s)
		var hb: float = halb.call(s)
		var reihe := PackedVector3Array()
		var uv2 := PackedVector2Array()
		for k in QUER + 1:
			var q := lerpf(q_bereich.x, q_bereich.y, float(k) / float(QUER))
			reihe.append(level.weg_punkt(s, q))
			uv2.append(Vector2(q / maxf(hb, 0.5), s))
		reihen.append(reihe)
		uv2s.append(uv2)
	for i in schritte:
		for k in QUER:
			var a := reihen[i][k]
			var b := reihen[i][k + 1]
			var c := reihen[i + 1][k]
			var d := reihen[i + 1][k + 1]
			_boden_dreieck(st, [a, b, c], [uv2s[i][k], uv2s[i][k + 1], uv2s[i + 1][k]])
			_boden_dreieck(st, [b, d, c], [uv2s[i][k + 1], uv2s[i + 1][k + 1], uv2s[i + 1][k]])


static func _boden_dreieck(st: SurfaceTool, ecken: Array[Vector3], uv2: Array[Vector2]) -> void:
	var reihe: Array[int] = [0, 1, 2]
	# Vorderseite nach oben (Wicklung wie `LevelWerkzeuge._dreieck_decke`).
	if (ecken[1] - ecken[0]).cross(ecken[2] - ecken[0]).y > 0.0:
		reihe = [0, 2, 1]
	for i in reihe:
		var p := ecken[i]
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(p.x, p.z) * 0.25)
		st.set_uv2(uv2[i])
		st.add_vertex(p)


## Schließt die Böden ab: Tangenten für die Normalen der Erde.
static func _boden_fertig(sa: Sammler, name: String) -> void:
	if not sa._werkzeuge.has(name):
		return
	var st: SurfaceTool = sa._werkzeuge[name]
	st.index()
	st.generate_tangents()


# ================================================================ A Waldsaum

static func _waldsaum(level: Level01) -> void:
	_kisten = level.kisten_orte()
	# Hinter dem Start: eigenes Stück, damit es aus der Spielkamera (die
	# immer nach vorn blickt) ganz wegfällt.
	var nest := Sammler.new(_wurzel(level), "Wurzelnest")
	_startboden(nest, level)
	_wurzelnest(nest, level)
	_boden_fertig(nest, "Boden")
	nest.fertig()
	var sa := Sammler.new(_wurzel(level), "Waldsaum")
	_waldtor(sa, level)
	_mooslog(sa, level)
	_erdspalt(sa, level)
	_enthuellung(sa, level)
	sa.fertig()


## Der Boden hinter dem Startportal (BEGEHBARES "Startboden"): bündig, im
## Stoff der Decke, bis unter die Wurzeln des Nests.
static func _startboden(sa: Sammler, level: Level01) -> void:
	var a: Dictionary = Level01.ABSCHNITTE[0]
	var halb := float(a["breite"]) * 0.5
	_boden(sa, level, a, -9.5, 0.0, func(_s: float) -> Vector2: return Vector2(-7.5, 7.5),
			func(_s: float) -> float: return halb, "Boden")


## Hinter dem Start: ein gestürzter Riese quer über dem Weg, Wurzelbögen,
## die sich aus dem Boden wölben, Farn dazwischen. Die Querleitlinie steht
## bei s −7; alles hier liegt dahinter oder seitlich hinter ±5,6.
static func _wurzelnest(sa: Sammler, level: Level01) -> void:
	# Der gestürzte Stamm liegt quer, leicht schräg, halb im Boden.
	var lage := _lage(level, -9.2, 0.6, 0.45, 0.12)
	var liegend := Riesenstamm.liegend(1.05, 17.0, {"saat": 311, "rippen": 13, "aeste": 3})
	_holz(sa, liegend, lage * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	# Wurzelbögen: aus dem Boden, über Kopfhöhe hinter der Wand, zurück.
	var rng := PropWerkzeug.zufall(4401)
	for i in 7:
		var q0 := rng.randf_range(-7.5, 7.5)
		var s0 := rng.randf_range(-12.5, -7.6)
		var hoch := rng.randf_range(1.2, 3.2)
		var weite := rng.randf_range(2.5, 5.0)
		var richtung := rng.randf_range(-0.9, 0.9)
		var stuetzen := PackedVector3Array()
		for k in 5:
			var t := float(k) / 4.0
			var s := s0 - cos(richtung) * weite * t * 0.4
			var q := q0 + sin(richtung) * weite * t
			stuetzen.append(_p(level, s, q, sin(t * PI) * hoch - 0.4))
		_wurzelstrang(sa, _glatt(stuetzen, 3), rng.randf_range(0.18, 0.34),
				rng.randf_range(0.08, 0.14), 4410 + i, {"ende": "offen", "anfang": "offen"})
	# Seitlich: Wurzelteller am Rand, Farn in den Winkeln.
	for seite: float in [-1.0, 1.0]:
		for k in 2:
			var s := rng.randf_range(-9.0, -1.0)
			var q := seite * rng.randf_range(6.0, 7.6)
			_farn_bei(sa, _lage(level, s, q, 0.0, rng.randf() * TAU), 1, 4420 + k + int(seite * 10.0),
					rng.randf_range(0.7, 1.0))
	for k in 3:
		var q := rng.randf_range(-6.5, 6.5)
		_farn_bei(sa, _lage(level, rng.randf_range(-10.5, -8.3), q, 0.2, rng.randf() * TAU), 1,
				4440 + k, rng.randf_range(0.8, 1.15))


## Das Waldtor bei s 3 zwischen zwei Stämmen der ersten Reihe.
static func _waldtor(sa: Sammler, level: Level01) -> void:
	var tor := _tor_daten("Waldtor")
	var s: float = tor["s"]
	for seite: float in [-1.0, 1.0]:
		var q := seite * (float(tor["abstand"]) + 1.5)
		# Die Kronen gehören zum Blätterdach des Hallenwalds (ab 9,5 m über
		# dem Weg); aus der Spielkamera sieht man hier nur die Stämme.
		_stamm(sa, _lage(level, s + 0.4 * seite, q, 0.0, seite), {
			"hoehe": 19.0, "radius": 0.85, "radius_oben": 0.5, "saat": 71 + int(seite),
			"brettwurzeln": 6, "wurzel_reichweite": 2.4, "wurzel_hoehe": 2.8, "pilze": 2,
			"efeu": 1 if seite > 0.0 else 0, "aeste": 2, "ast_start": 0.8,
			"ast_laenge": 3.0})
	Schluchtsaum.wurzeltor(sa.wurzel, level.verlauf, s, float(tor["abstand"]), 303,
			3.2, float(tor["scheitel"]))


static func _tor_daten(name: String) -> Dictionary:
	for t: Dictionary in Level01.TORE:
		if String(t["name"]) == name:
			return t
	return {}


## Das Mooslog bei s 8: der Stamm genau in der Kapsel, die Enden im Farn.
static func _mooslog(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Mooslog")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var r: float = e["radius"]
	var l: float = e["laenge"]
	var netz := Riesenstamm.liegend(r, l, {"saat": 808, "rippen": 10, "aeste": 1, "moos": 1.0})
	_holz(sa, netz, lage * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	var s: float = e["s"]
	# Außen an der Wegkante (K7: über 0,9 m erst ab |q| 5,05): Die Wedel
	# reichen über die Enden des Stamms.
	for seite: float in [-1.0, 1.0]:
		var q := seite * 5.25
		_farn_bei(sa, _lage(level, s + 0.3, q, 0.0, seite * 0.6), 1, 810 + int(seite), 0.72)
		_farn_bei(sa, _lage(level, s - 0.9, q + seite * 0.6, 0.0, 1.3), 1, 812 + int(seite), 0.55)
		_farn_bei(sa, _lage(level, s + 1.2, seite * 4.9, 0.0, 2.1), 0, 814 + int(seite), 1.1)


## Wurzeln hängen in den Erdspalt, an beiden Lippen, aus der Stirnwand
## knapp unter der Kante – nichts liegt auf der Decke oder überspannt ihn.
static func _erdspalt(sa: Sammler, level: Level01) -> void:
	_lippenwurzeln(sa, level, 25.0, 27.5, 6.8, 2501)


## Wurzeln an den Lippen einer Lücke `von`–`bis`, quer bis `weit`.
static func _lippenwurzeln(sa: Sammler, level: Level01, von: float, bis: float, weit: float,
		saat: int, q_von: float = NAN, q_bis: float = NAN) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var links := -weit if is_nan(q_von) else q_von
	var rechts := weit if is_nan(q_bis) else q_bis
	for lippe in 2:
		var s_kante := von if lippe == 0 else bis
		var hinein := 1.0 if lippe == 0 else -1.0
		var y_kante := level.boden_bei(s_kante - hinein * 0.05)
		var anzahl := int((rechts - links) / 1.3)
		for i in anzahl:
			var q := lerpf(links, rechts, (float(i) + rng.randf_range(0.1, 0.9)) / float(anzahl))
			# In der Spur (|q| < 2,2) sitzen die Lippensteine: dort nur
			# dünne Wurzeln, tiefer angesetzt.
			var spur := absf(q) < 2.2
			var dick := rng.randf_range(0.05, 0.1) if spur else rng.randf_range(0.07, 0.19)
			var tief := rng.randf_range(0.2, 0.6) + (0.25 if spur else 0.0)
			var lang := rng.randf_range(1.6, 5.5)
			var schwung := rng.randf_range(0.25, 0.6)
			var stuetzen := PackedVector3Array()
			for k in 6:
				var t := float(k) / 5.0
				var s := s_kante + hinein * (0.02 + schwung * sin(t * PI * 0.7) * 0.7 + t * 0.15)
				var p := LevelWerkzeuge.punkt_frei(level.verlauf, s,
						q + sin(t * 3.0 + float(i)) * 0.25)
				p.y = y_kante - tief - lang * t * t * 0.9 - t * lang * 0.1
				stuetzen.append(p)
			# Der Ansatz steckt in der Wand.
			var ansatz := LevelWerkzeuge.punkt_frei(level.verlauf, s_kante - hinein * 0.5, q)
			ansatz.y = y_kante - tief + 0.05
			stuetzen.insert(0, ansatz)
			_wurzelstrang(sa, _glatt(stuetzen, 3), dick, dick * 0.3, saat + i * 7 + lippe,
					{"ao": Vector2(0.6, 0.35), "moos": 0.15, "anfang": "offen"})


## Der Rahmen der Enthüllung: ein toter Baum (s 28), der über den Hang
## lehnt, und ein bemooster Findling (s 31) am rechten Rand.
static func _enthuellung(sa: Sammler, level: Level01) -> void:
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		match String(stelle["art"]):
			"totholz":
				_toter_baum(sa, level, stelle)
			"findling":
				var s: float = stelle["s"]
				var q: float = stelle["q"]
				var h: float = stelle["hoehe"]
				var lage := _lage(level, s, q + 0.4, float(stelle["fuss"]), 0.5)
				_brocken(sa, Vector3(2.7, h, 2.3), lage, 3101, 0.3,
						{"moos": 1.0, "rundung": 0.6})
				_brocken(sa, Vector3(1.1, 0.7, 0.9), lage.translated_local(Vector3(1.6, 0.0, -1.1)),
						3102, 0.15)
				_farn_bei(sa, lage.translated_local(Vector3(-1.1, 0.0, 1.0)), 1, 3103, 0.8)
				_farn_bei(sa, lage.translated_local(Vector3(0.6, 0.0, -1.5)), 0, 3104, 1.4)


## Ein toter Baum: kahl, oben gebrochen, lehnt nach außen über den Hang.
## Die Äste zeigen nur nach außen und nach oben – über dem Weg (|q| ≤ 6)
## hängt unter 8,8 m nichts, und aus den Enthüllungsbildern steht er rechts
## neben dem Weltenbaum statt davor.
static func _toter_baum(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var hoehe: float = stelle["hoehe"]
	var lage := _lage(level, s, q, float(stelle["fuss"]))
	var h := hoehe * 0.8
	var netz := Riesenstamm.netz({"hoehe": h, "radius": 0.5, "radius_oben": 0.3,
			"oben": "bruch", "saat": 2801, "brettwurzeln": 5, "wurzel_reichweite": 1.6,
			"wurzel_hoehe": 1.6, "neigung": Vector2(2.6, -0.8), "krumm": 0.0, "pilze": 3,
			"moos": 0.45, "aeste": 0})
	_holz(sa, _getoent(netz, Totholzzaun.RINDE_TON), lage)
	var fuss: PackedFloat32Array = netz.get_meta("fuss_radien", PackedFloat32Array())
	_kranz(sa, Findling.kranz(fuss, 0.02, 1.2, 0.65, 0.3), lage)
	# Kahle Äste, von Hand gesetzt: nach außen (+X), nach oben, einer
	# nach vorn – keiner nach innen über den Weg.
	var achse := func(y: float) -> Vector3:
		var t := clampf(y / h, 0.0, 1.0)
		return Vector3(2.6 * pow(t, 1.5), y, -0.8 * pow(t, 1.5))
	var aeste := [
		[0.55, Vector3(1.0, 0.55, 0.15), 3.2, 0.13],
		[0.68, Vector3(0.6, 0.9, -0.5), 2.6, 0.1],
		[0.78, Vector3(1.0, 0.35, 0.5), 2.3, 0.09],
		[0.42, Vector3(0.7, 0.3, -0.7), 1.2, 0.1],
	]
	var st := _borke(sa)
	for i in aeste.size():
		var ast: Array = aeste[i]
		var start: Vector3 = achse.call(float(ast[0]) * h)
		var richtung: Vector3 = (ast[1] as Vector3).normalized()
		var laenge: float = ast[2]
		var r: float = ast[3]
		var punkte := PackedVector3Array()
		for k in 5:
			var t := float(k) / 4.0
			punkte.append(lage * (start + richtung * laenge * t
					+ Vector3.UP * laenge * 0.12 * t * t
					+ Vector3(0.0, 0.0, sin(t * 3.0 + float(i)) * 0.15)))
		var radien := PackedFloat32Array([r, r * 0.8, r * 0.6, r * 0.42, r * 0.3])
		Totholzzaun.stueck(st, punkte, radien, {"saat": 2810 + i, "seiten": 6,
				"ende": "splitter" if i % 2 == 0 else "spitz", "moos": 0.2,
				"ton": Totholzzaun.RINDE_TON})
		# Ein Zweig in der zweiten Hälfte
		var gabel := punkte[2]
		var zweig_r := (richtung + Vector3.UP * 0.8).normalized()
		var zweig := PackedVector3Array([gabel, gabel + lage.basis * zweig_r * laenge * 0.25,
				gabel + lage.basis * (zweig_r * laenge * 0.45 + Vector3.RIGHT * 0.2)])
		Totholzzaun.stueck(st, zweig, PackedFloat32Array([r * 0.45, r * 0.32, r * 0.2]),
				{"saat": 2820 + i, "seiten": 5, "ende": "spitz", "moos": 0.1,
				"ton": Totholzzaun.RINDE_TON})
	# Am Fuß: Farn und ein Stein
	_farn_bei(sa, lage.translated_local(Vector3(-0.9, 0.0, 1.2)), 1, 2830, 0.85)
	_brocken(sa, Vector3(0.9, 0.55, 0.8), lage.translated_local(Vector3(0.9, 0.0, 1.4)), 2831, 0.15)


# ================================================================ B Hangweg

static func _hangweg_vorn(level: Level01) -> void:
	_kisten = level.kisten_orte()
	var sa := Sammler.new(_wurzel(level), "Hangweg vorn")
	_gelaender(sa, level)
	_kanzel(sa, level)
	_kerbe(sa, level)
	_findling_auf(sa, level, "Spornfels", {"saat": 632, "eckig": 2.8, "rundung": 0.28,
			"beulen": 0.12, "moos": 0.9, "ausgetreten": 0.2}, 0.0)
	_farn_bei(sa, _lage(level, 62.2, 5.4, 0.0, 0.7), 0, 633, 1.2)
	_farn_bei(sa, _lage(level, 64.3, 6.3, 0.0, 2.2), 0, 634, 0.9)
	sa.fertig()


static func _hangweg_hinten(level: Level01) -> void:
	_kisten = level.kisten_orte()
	var sa := Sammler.new(_wurzel(level), "Hangweg hinten")
	_hangstamm(sa, level)
	_nische(sa, level)
	_pforte(sa, level)
	_boden_fertig(sa, "Boden")
	sa.fertig()


## Welttransform eines Kastens wie `Level01._kasten_lage` (folgt der Neigung
## des Weges zwischen seinen Enden), für Optik ohne eigenen Eintrag.
static func _kasten_lage(level: Level01, s: float, q: float, groesse: Vector3,
		oben: float) -> Transform3D:
	var a := level.weg_punkt(s - groesse.z * 0.5, q, oben)
	var b := level.weg_punkt(s + groesse.z * 0.5, q, oben)
	var vor := (b - a).normalized()
	var rechts := vor.cross(Vector3.UP).normalized()
	var hoch := rechts.cross(vor).normalized()
	return Transform3D(Basis(rechts, hoch, -vor), (a + b) * 0.5 - hoch * groesse.y * 0.5)


## Das Totholzgeländer (s 33–50): ein Spaltzaun gleich hinter der
## Leitlinie „Rechts A/B“ – die Figur stößt an die Leitlinie, bevor sie ihn
## berührt. Er steht auf einem Felsrand, der bündig mit dem Weg bis an die
## Schulter reicht (so weit trägt die Kollision), mit Findlingen in den
## Lücken und einem geborstenen Endpfosten bei s 50, wo die Kante offen
## wird.
static func _gelaender(sa: Sammler, level: Level01) -> void:
	var leitlinie: Array = []
	for e: Dictionary in Level01.LEITLINIEN:
		if String(e["name"]) == "Rechts A/B":
			leitlinie = e["punkte"]
	if leitlinie.is_empty():
		return
	# Die Linie ab der Enthüllung, 0,15 m hinter der Innenseite der Wand.
	var linie := PackedVector3Array()
	var stellen: Array[Vector2] = []
	for p: Vector2 in leitlinie:
		if p.x >= 33.4:
			stellen.append(p)
	for i in stellen.size() - 1:
		var a := stellen[i]
		var b := stellen[i + 1]
		var teile := maxi(ceili(a.distance_to(b) / 0.5), 1)
		for k in teile:
			var p := a.lerp(b, float(k) / float(teile))
			linie.append(_p(level, p.x, p.y + 0.15))
	var ende := stellen[stellen.size() - 1]
	linie.append(_p(level, ende.x, ende.y + 0.15))
	# Findlinge statt Zaunfeldern: an der Kanzelecke vorn, mitten im ersten
	# Stück, an der hinteren Ecke. Bogenlängen auf der Linie.
	var laengen := PackedFloat32Array([0.0])
	for i in range(1, linie.size()):
		laengen.append(laengen[i - 1] + linie[i].distance_to(linie[i - 1]))
	# [s, q der Innenkante (hinter der Leitlinie), Größe]
	var luecken: Array[Vector2] = []
	var findlinge := [[36.3, 5.22, 1.3], [40.5, 9.82, 1.1], [47.6, 9.82, 1.2]]
	for f: Array in findlinge:
		var mitte := _p(level, float(f[0]), float(f[1]))
		var naechst := 0.0
		var best := INF
		for i in linie.size():
			var d := linie[i].distance_to(mitte)
			if d < best:
				best = d
				naechst = laengen[i]
		var halb := float(f[2]) * 0.5
		luecken.append(Vector2(naechst - halb, naechst + halb))
	var zaun := Totholzzaun.bauen(linie, {"saat": 3301, "abstand": 2.4, "hoehe": 1.15,
			"aussen": 1.0, "luecken": luecken, "ende_geborsten": true, "verfall": 0.45})
	sa.dazu("Totholz", Totholzzaun.stoff(), true, zaun)
	for i in findlinge.size():
		var f: Array = findlinge[i]
		var s: float = f[0]
		var g: float = f[2]
		var q: float = f[1] + g * 0.5
		_brocken(sa, Vector3(g, g * 0.75, g * 0.85), _lage(level, s, q, 0.0), 3310 + i, 0.2,
				{"moos": 1.0})
	# Der Felsrand unter dem Zaun: bündige Platten bis an die Schulter.
	for rand: Array in [[33.2, 39.9], [48.2, 50.8]]:
		var von: float = rand[0]
		var bis: float = rand[1]
		var laenge := bis - von
		var groesse := Vector3(0.95, 1.4, laenge)
		_stein(sa, Findling.netz(groesse, {"saat": 3320 + int(von), "eckig": 4.0, "rundung": 0.12,
				"umriss": 0.02, "moos": 0.7, "ausgetreten": 0.0}),
				_kasten_lage(level, (von + bis) * 0.5, 5.2, groesse, 0.0))
	# Am geborstenen Pfosten: ein heruntergefallener Riegel und Farn.
	var ende_p := _lage(level, 50.4, 5.3, 0.0)
	Totholzzaun.stueck(sa.roh("Totholz", Totholzzaun.stoff(), true),
			PackedVector3Array([ende_p * Vector3(-0.3, 0.07, 0.4), ende_p * Vector3(0.1, 0.05, 1.3),
			ende_p * Vector3(0.35, 0.08, 2.2)]),
			PackedFloat32Array([0.07, 0.07, 0.065]), {"saat": 3330, "form": "gespalten",
			"spalt": Vector3.UP, "ende": "splitter", "anfang": "splitter", "moos": 0.6,
			"ton": Totholzzaun.RINDE_TON})
	_farn_bei(sa, _lage(level, 49.4, 5.6, 0.0, 0.4), 0, 3331, 1.2)


## Die Kanzel: eine Felsplatte bündig mit dem Weg, auf der ersten
## Checkpoint-Kiste steht. Sichtbar reicht sie bis an die Schulter hinter
## der Leitlinie (so weit trägt die Kollision). Darauf die Drehkiefer.
static func _kanzel(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Kanzel")
	if e.is_empty():
		return
	var s: float = e["s"]
	var groesse: Vector3 = e["groesse"]
	var innen: float = float(e["q"]) - groesse.x * 0.5
	var aussen := 10.2
	var platte := Vector3(aussen - innen, groesse.y, groesse.z + 1.4)
	_stein(sa, Findling.netz(platte, {"saat": 4401, "eckig": 4.4, "rundung": 0.22,
			"umriss": 0.03, "moos": 0.85, "moos_oben": 0.7, "ausgetreten": 0.9}),
			_kasten_lage(level, s, (innen + aussen) * 0.5, platte, 0.0))
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if String(stelle["art"]) == "drehkiefer":
			_drehkiefer(sa, level, stelle)


## Die Drehkiefer auf der Kanzel: bis über Kopfhöhe senkrecht (dort steht
## die Kollision, ein Zylinder bis +6 m), dann weit über den Abgrund
## hinausgebogen, die Nadelpolster tief (4,5–6 m) und außen (q ≥ 10). So
## rahmt sie das Tal, ohne den Weltenbaum zu verdecken.
static func _drehkiefer(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var lage := _lage(level, s, q, float(stelle["fuss"]))
	var st := Riesenstamm.bauer()
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 4161
	# Stamm (lokal: X nach außen, Y hoch, −Z voraus)
	var achse := PackedVector3Array([Vector3(0.0, -0.8, 0.0), Vector3(0.02, 1.0, 0.0),
			Vector3(0.0, 2.4, -0.04), Vector3(0.18, 3.5, -0.12), Vector3(0.8, 4.3, -0.25),
			Vector3(1.8, 4.85, -0.35), Vector3(2.9, 5.15, -0.3), Vector3(3.8, 5.25, -0.15)])
	var radien := PackedFloat32Array([0.52, 0.46, 0.43, 0.4, 0.34, 0.27, 0.2, 0.14])
	Totholzzaun.stueck(st, _glatt(achse, 3), _glatt_r(radien, 3), {"saat": 4162, "seiten": 14,
			"ende": "spitz", "moos": 0.35, "drehung": 0.55, "buckel": 0.08,
			"ton": KIEFER_TON, "ao": Vector2(0.55, 1.0)})
	# Wurzeln krallen sich in den Fels, zwei laufen über den Rand hinab.
	# Flach: Die Kanzel ist begehbar, und nur der Stamm hat Kollision.
	for i in 5:
		var w := TAU * float(i) / 5.0 + 0.4
		Riesenstamm.brettwurzel_in(st, Vector3.ZERO, w, 0.5, 0.7 + 0.25 * float(i % 2),
				0.5, 0.2, 0.2, 1.8, 0.8, rauschen)
	for k in 2:
		var z := -0.5 + float(k) * 1.1
		var wurzel := PackedVector3Array([Vector3(0.3, 0.1, z * 0.4), Vector3(0.9, 0.06, z),
				Vector3(1.35, -0.1, z * 1.2), Vector3(1.55, -0.8, z * 1.3),
				Vector3(1.6, -1.8, z * 1.2)])
		Totholzzaun.stueck(st, _glatt(wurzel, 3), _glatt_r(PackedFloat32Array(
				[0.2, 0.16, 0.14, 0.11, 0.07]), 3), {"saat": 4170 + k, "seiten": 6,
				"ende": "spitz", "moos": 0.5, "ton": KIEFER_TON})
	# Äste zu den Polstern
	var polster := [
		[Vector3(3.8, 5.6, -0.2), 1.9], [Vector3(2.6, 6.0, 0.9), 1.45],
		[Vector3(4.4, 4.8, -1.3), 1.4], [Vector3(1.9, 5.4, -1.5), 1.2],
	]
	for i in polster.size():
		var ziel: Vector3 = polster[i][0]
		var start := achse[4 + (i % 3)]
		var mitte := start.lerp(ziel, 0.5) + Vector3.UP * 0.25
		Totholzzaun.stueck(st, _glatt(PackedVector3Array([start, mitte, ziel]), 3),
				_glatt_r(PackedFloat32Array([0.14, 0.09, 0.05]), 3), {"saat": 4180 + i,
				"seiten": 6, "ende": "spitz", "moos": 0.15, "ton": KIEFER_TON})
	_holz(sa, Riesenstamm.fertig(st), lage)
	_kranz(sa, Findling.kranz(_kreis(0.95, 24), 0.02, 0.9, 0.55, 0.25), lage)
	for i in polster.size():
		var ziel: Vector3 = polster[i][0]
		_polster(sa, lage * ziel, float(polster[i][1]), 4190 + i)


static func _kreis(r: float, n: int) -> PackedFloat32Array:
	var radien := PackedFloat32Array()
	for i in n:
		radien.append(r)
	return radien


## Radien zu `_glatt(punkte, je)`: linear zwischen den Stützen.
static func _glatt_r(radien: PackedFloat32Array, je: int) -> PackedFloat32Array:
	var aus := PackedFloat32Array()
	for i in radien.size() - 1:
		for k in je:
			aus.append(lerpf(radien[i], radien[i + 1], float(k) / float(je)))
	aus.append(radien[radien.size() - 1])
	return aus


## Die Kerbe (56–59): Wurzeln hängen von beiden Lippen hinein, am meisten
## an der Böschung links; das Rinnsal macht das Modul Wasser.
static func _kerbe(sa: Sammler, level: Level01) -> void:
	_lippenwurzeln(sa, level, 56.0, 59.0, 0.0, 5601, -7.0, 4.2)


## Der Hangstamm (s 75): liegt genau in seiner Kapsel quer auf dem
## Stammsporn, das äußere Drittel über dem Abgrund.
static func _hangstamm(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Hangstamm")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var netz := Riesenstamm.liegend(float(e["radius"]), float(e["laenge"]),
			{"saat": 7501, "rippen": 9, "aeste": 2, "moos": 0.9})
	_holz(sa, netz, lage * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	var s: float = e["s"]
	_farn_bei(sa, _lage(level, s - 0.6, 5.0, 0.0, 0.3), 0, 7502, 1.1)
	_farn_bei(sa, _lage(level, s + 0.7, 5.6, 0.0, 2.0), 0, 7503, 0.9)


## Die Moosbank-Nische (78–98): Nischenboden im Stoff der Decke (Rasen),
## die Moosbank als Findling-Sims, am Wandfuß Farn, Steine, Leuchtpilze
## und ein Ast. Frei bleiben der Anlauf von der Feder (80,5) und die Kisten.
static func _nische(sa: Sammler, level: Level01) -> void:
	var nb := level.begehbar("Nischenboden")
	if nb.is_empty():
		return
	var umriss: Array = nb["aussen"]
	var von: float = nb["von"]
	var bis: float = nb["bis"]
	var q_bei := func(s: float) -> float:
		for i in umriss.size() - 1:
			var a: Vector2 = umriss[i]
			var b: Vector2 = umriss[i + 1]
			if s >= a.x and s <= b.x:
				return lerpf(a.y, b.y, (s - a.x) / maxf(b.x - a.x, 0.001))
		return (umriss[umriss.size() - 1] as Vector2).y
	var halb := func(s: float) -> float: return maxf(level.breite_bei(s) * 0.5, 3.75)
	_boden(sa, level, level.abschnitt_bei(88.0), von, bis,
			func(s: float) -> Vector2:
				return Vector2(float(q_bei.call(s)) - 0.6, -float(halb.call(s))),
			halb, "Boden")
	_findling_auf(sa, level, "Moosbank", _mit_kisten(level, "Moosbank", {"saat": 8701,
			"eckig": 4.2, "rundung": 0.2, "moos": 1.2, "moos_oben": 1.0, "ausgetreten": 0.15,
			"beulen": 0.14}), 0.0)
	# Am Wandfuß und an den Enden der Bank
	var rng := PropWerkzeug.zufall(8710)
	var farne := [[83.2, -9.8, 1], [91.4, -9.6, 1], [93.5, -9.4, 1], [95.6, -7.4, 0],
			[85.5, -10.5, 0], [88.7, -10.6, 0], [79.6, -6.2, 0], [96.8, -6.0, 1]]
	for i in farne.size():
		var f: Array = farne[i]
		var p := _lage(level, float(f[0]), float(f[1]), 0.0, rng.randf() * TAU)
		if _frei(p.origin):
			_farn_bei(sa, p, int(f[2]), 8720 + i, rng.randf_range(0.7, 1.0))
	for i in 4:
		var s := rng.randf_range(92.0, 96.0) if i < 2 else rng.randf_range(79.5, 82.0)
		var q := float(q_bei.call(s)) + rng.randf_range(0.3, 0.8)
		var g := rng.randf_range(0.5, 0.9)
		var p := _lage(level, s, q, 0.0, rng.randf() * TAU)
		if _frei(p.origin):
			_brocken(sa, Vector3(g * 1.3, g * 0.8, g), p, 8730 + i, 0.15)
	# Ein Ast auf dem Nischenboden (flach, unter 0,35 m)
	var ast := PackedVector3Array([_p(level, 92.6, -6.4, 0.06), _p(level, 93.6, -7.1, 0.08),
			_p(level, 94.8, -7.4, 0.07), _p(level, 95.5, -8.1, 0.06)])
	Totholzzaun.stueck(sa.roh("Totholz", Totholzzaun.stoff(), true), ast,
			PackedFloat32Array([0.07, 0.06, 0.05, 0.035]), {"saat": 8740, "ende": "spitz",
			"anfang": "splitter", "moos": 0.7, "ton": Totholzzaun.RINDE_TON})
	# Leuchtpilze am Fuß der Bank
	var pilze := Riesenstamm.bauer()
	var bank := level.begehbar("Moosbank")
	var bank_lage: Transform3D = bank["lage"]
	for i in 3:
		var ort := bank_lage * Vector3(-1.9 + rng.randf_range(0.0, 0.2), -0.78,
				rng.randf_range(-3.5, 3.5))
		for k in rng.randi_range(3, 5):
			Riesenstamm.leuchtpilz_in(pilze, ort + Vector3(rng.randf_range(-0.25, 0.25), 0.0,
					rng.randf_range(-0.25, 0.25)), rng.randf_range(0.04, 0.07), rng)
	_holz(sa, Riesenstamm.fertig(pilze), Transform3D.IDENTITY)


## Die Torbaum-Pforte (s 99,5–103,5): links ein Felskörper, der in die
## Felsnase übergeht, rechts eine Wurzel des Torbaums, der außen am Rand
## steht. Darüber das Pfortentor, dessen rechter Fuß in den Torbaum wächst.
static func _pforte(sa: Sammler, level: Level01) -> void:
	_findling_auf(sa, level, "Pforte links", {"saat": 1011, "eckig": 3.0, "rundung": 0.3,
			"beulen": 0.2, "moos": 0.9, "ausgetreten": 0.1}, 0.0)
	# Hinter der Leitlinie (q < −3,8): Felsmasse bis an die Felsnase.
	_brocken(sa, Vector3(2.6, 3.6, 5.2), _lage(level, 101.4, -5.3, 0.0, 0.1), 1012, 0.6,
			{"moos": 0.8, "kuppe": 0.4})
	_brocken(sa, Vector3(1.8, 1.9, 2.0), _lage(level, 98.2, -4.9, 0.0, 0.8), 1013, 0.35,
			{"moos": 1.0})
	_brocken(sa, Vector3(1.6, 1.4, 1.8), _lage(level, 104.6, -5.0, 0.0, 2.1), 1014, 0.3,
			{"moos": 1.0})
	_farn_bei(sa, _lage(level, 98.6, -4.2, 0.0, 1.0), 1, 1015, 0.6)
	# Rechts: Wurzel des Torbaums, genau im Kasten
	var e := level.begehbar("Pforte rechts")
	if not e.is_empty():
		_pfortenwurzel(sa, level, e)
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if String(stelle["art"]) == "torbaum":
			_torbaum(sa, level, stelle)
	var tor := _tor_daten("Pfortentor")
	Schluchtsaum.wurzeltor(sa.wurzel, level.verlauf, float(tor["s"]), float(tor["abstand"]),
			1017, 3.2, float(tor["scheitel"]))


## Die rechte Pfortenwurzel: ein Strang mit flacher, bemooster Oberseite
## genau auf der Kastenoberkante (+2,6), der vorn aus dem Boden steigt und
## hinten über die Kante nach außen zum Torbaum abbiegt.
static func _pfortenwurzel(sa: Sammler, level: Level01, e: Dictionary) -> void:
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	# Punkte in Kastenkoordinaten (x quer, y hoch, z = −Strecke): Mitte des
	# Querschnitts, halbe Breite, halbe Höhe.
	var pfad := [
		[Vector3(-0.1, boden - 1.6, h.z + 0.9), 0.45, 0.6],
		[Vector3(0.0, boden + 0.1, h.z + 0.05), 0.6, 0.85],
		[Vector3(0.0, h.y - 1.05, h.z - 0.45), 0.72, 1.2],
		[Vector3(0.02, h.y - 1.1, 0.5), 0.74, 1.25],
		[Vector3(0.08, h.y - 1.1, -0.6), 0.74, 1.25],
		[Vector3(0.3, h.y - 1.2, -1.3), 0.7, 1.2],
		[Vector3(1.2, h.y - 1.8, -1.72), 0.58, 1.0],
		[Vector3(2.3, boden - 0.3, -1.55), 0.5, 0.8],
		[Vector3(3.2, boden - 0.9, -0.9), 0.46, 0.7],
		[Vector3(3.9, boden - 1.2, -0.2), 0.44, 0.6],
	]
	var st := Riesenstamm.bauer()
	_wurzelkoerper(st, pfad, h, boden, 1021, KIEFER_TON)
	# Oberflächenwurzeln am Fuß, flach (unter 0,3 m), zur Wegseite
	var rng := PropWerkzeug.zufall(1022)
	for i in 3:
		var z := rng.randf_range(-1.4, 1.6)
		var zug := PackedVector3Array([Vector3(-0.55, boden + 0.05, z),
				Vector3(-1.0, boden + 0.08, z + rng.randf_range(-0.4, 0.4)),
				Vector3(-1.5, boden + 0.02, z + rng.randf_range(-0.6, 0.6)),
				Vector3(-1.8, boden - 0.1, z + rng.randf_range(-0.8, 0.8))])
		Totholzzaun.stueck(st, _glatt(zug, 2), _glatt_r(PackedFloat32Array(
				[0.16, 0.12, 0.08, 0.05]), 2), {"saat": 1023 + i, "seiten": 6, "ende": "spitz",
				"moos": 0.4, "ton": KIEFER_TON, "ao": Vector2(0.7, 0.8)})
	_holz(sa, Riesenstamm.fertig(st), lage)


## Ein Wurzelkörper aus Querschnitten entlang `pfad` ([Mitte, halbe Breite,
## halbe Höhe] in Kastenkoordinaten). Der Querschnitt ist ein gerundetes
## Rechteck; oben wird er auf die Kastenoberkante `h.y` geklemmt (flache,
## bemooste Oberseite), zur Wegseite auf die Innenwand (−h.x), und solange
## er dort liegt, auf die Enden des Kastens (±h.z). Nach außen (x > h.x)
## darf er hinaus: Dort ist der Abgrund.
static func _wurzelkoerper(st: SurfaceTool, pfad: Array, h: Vector3, boden: float,
		saat: int, ton: Color = Color(1.0, 1.0, 1.0)) -> void:
	var punkte := PackedVector3Array()
	var breiten := PackedFloat32Array()
	var hoehen := PackedFloat32Array()
	for eintrag: Array in pfad:
		punkte.append(eintrag[0])
		breiten.append(float(eintrag[1]))
		hoehen.append(float(eintrag[2]))
	var je := 3
	punkte = _glatt(punkte, je)
	breiten = _glatt_r(breiten, je)
	hoehen = _glatt_r(hoehen, je)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 0.9
	const SEITEN := 18
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var n := punkte.size()
	var bogen := 0.0
	var kachel := Riesenstamm.borkenmass(0.7)
	var n_u := maxi(1, roundi(4.0 * Riesenstamm.KACHEL_U * kachel))
	for i in n:
		var t: Vector3
		if i == 0:
			t = punkte[1] - punkte[0]
		elif i == n - 1:
			t = punkte[n - 1] - punkte[n - 2]
		else:
			t = punkte[i + 1] - punkte[i - 1]
		t = t.normalized()
		var n1 := t.cross(Vector3.UP)
		n1 = n1.normalized() if n1.length() > 0.05 else Vector3.RIGHT
		var n2 := t.cross(n1).normalized()
		if i > 0:
			bogen += punkte[i].distance_to(punkte[i - 1])
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in SEITEN + 1:
			var jj := j % SEITEN
			var a := TAU * float(jj) / float(SEITEN)
			var c := cos(a)
			var s := sin(a)
			# Gerundetes Rechteck (Superellipse, Exponent 3)
			var e := 2.0 / 3.0
			var rel := 1.0 + 0.07 * rauschen.get_noise_3d(c * 2.0 + bogen, s * 2.0, bogen * 0.7)
			if jj % 2 == 1:
				rel -= 0.035
			var p := punkte[i] + n1 * (breiten[i] * rel * signf(c) * pow(absf(c), e)) \
					+ n2 * (hoehen[i] * rel * signf(s) * pow(absf(s), e))
			# Klemmen: Oberseite, Wegseite, Kastenenden auf der Wegseite
			p.y = minf(p.y, h.y - 0.005)
			p.x = maxf(p.x, -h.x + 0.01)
			if p.x < h.x:
				p.z = clampf(p.z, -h.z + 0.01, h.z - 0.01) if p.y > boden + 0.3 else p.z
			zeile.append(p)
			uv.append(Vector2(float(j) / float(SEITEN) * float(n_u),
					bogen * Riesenstamm.KACHEL_V * kachel * 2.0))
			var ao := lerpf(0.42, 1.0, smoothstep(boden - 0.2, boden + 1.2, p.y))
			var m := 0.25 + 0.35 * rauschen.get_noise_3d(p.x * 3.0, p.y * 3.0, p.z * 3.0)
			if p.y > h.y - 0.02:
				m += 0.45
			fa.append(Color(ao * ton.r, ao * ton.g, ao * ton.b, clampf(m, 0.0, 1.0)))
			ar.append(Vector2(Riesenstamm.BORKE, 0.4))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)


## Der Torbaum: eine große Kiefer außen am Rand (q +7, Fuß 1 m unter dem
## Weg) auf einem Felsfuß. Die Krone hängt nach außen über das Tal. Zwei
## Wurzelstränge führen vom rechten Fuß des Pfortentors in den Stamm.
static func _torbaum(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var fuss: float = stelle["fuss"]
	var hoehe: float = stelle["hoehe"]
	var lage := _lage(level, s, q, fuss, 0.0)
	# Felsfuß: gewölbt, damit er nicht nach Boden aussieht; der Stamm steht
	# auf seiner Kuppe.
	_brocken(sa, Vector3(3.6, 3.4, 4.0), lage.translated_local(Vector3(0.3, -3.5, 0.0)),
			1031, 0.0, {"moos": 0.9, "kuppe": 0.6})
	var h := hoehe - 2.0
	var netz := Riesenstamm.netz({"hoehe": h, "radius": 0.8, "radius_oben": 0.38,
			"saat": 1032, "brettwurzeln": 6, "wurzel_reichweite": 2.2, "wurzel_hoehe": 2.2,
			"neigung": Vector2(1.8, -0.4), "krumm": 0.0, "drehung": 0.35, "pilze": 1,
			"efeu": 1, "aeste": 0, "oben": "offen"})
	_holz(sa, _getoent(netz, KIEFER_TON), lage)
	# Äste und Polster im oberen Drittel, alle nach außen oder quer.
	var achse := func(y: float) -> Vector3:
		var t := clampf(y / h, 0.0, 1.0)
		return Vector3(1.8 * pow(t, 1.5), y, -0.4 * pow(t, 1.5))
	var st := Riesenstamm.bauer()
	var aeste := [
		[0.66, Vector3(1.0, 0.25, 0.6), 3.4, 2.0], [0.74, Vector3(1.0, 0.3, -0.7), 3.0, 1.9],
		[0.82, Vector3(0.2, 0.35, 1.0), 2.4, 1.6], [0.88, Vector3(1.0, 0.5, 0.0), 2.2, 1.8],
		[0.95, Vector3(-0.3, 0.8, -0.4), 1.2, 1.5], [0.72, Vector3(-0.5, 0.3, -1.0), 2.0, 1.4],
	]
	var polster: Array[Array] = []
	for i in aeste.size():
		var ast: Array = aeste[i]
		var start: Vector3 = achse.call(float(ast[0]) * h)
		var richtung: Vector3 = (ast[1] as Vector3).normalized()
		var laenge: float = ast[2]
		var ende := start + richtung * laenge + Vector3.UP * laenge * 0.15
		var mitte := start.lerp(ende, 0.5) + Vector3.UP * laenge * 0.12
		Totholzzaun.stueck(st, _glatt(PackedVector3Array([start, mitte, ende]), 3),
				_glatt_r(PackedFloat32Array([0.2, 0.13, 0.07]), 3), {"saat": 1040 + i,
				"seiten": 6, "ende": "spitz", "moos": 0.1, "ton": KIEFER_TON})
		polster.append([ende + Vector3.UP * 0.3, float(ast[3])])
	polster.append([achse.call(h) + Vector3.UP * 0.6, 1.7])
	# Zwei Stränge vom rechten Torfuß (q 5,2, 3,2 m über dem Weg) in den Stamm.
	var tor := _tor_daten("Pfortentor")
	var weite := float(tor["abstand"]) + 0.8
	for k in 2:
		var dz := -0.35 + 0.7 * float(k)
		var von_welt := _p(level, s + dz, weite - 0.2, 3.1 + 0.3 * float(k))
		var von := lage.affine_inverse() * von_welt
		var ziel: Vector3 = achse.call(4.2 + 0.8 * float(k)) + Vector3(-0.55, 0.0, dz * 0.5)
		var zug := PackedVector3Array([von, von.lerp(ziel, 0.5) + Vector3.DOWN * 0.35, ziel])
		Totholzzaun.stueck(st, _glatt(zug, 3), _glatt_r(PackedFloat32Array([0.3, 0.24, 0.2]), 3),
				{"saat": 1050 + k, "seiten": 7, "moos": 0.45, "ton": KIEFER_TON})
	_holz(sa, Riesenstamm.fertig(st), lage)
	for i in polster.size():
		var p: Array = polster[i]
		_polster(sa, lage * (p[0] as Vector3), float(p[1]), 1060 + i)


# ================================================================ D Bachwiese

static func _bachwiese(level: Level01) -> void:
	_kisten = level.kisten_orte()
	var sa := Sammler.new(_wurzel(level), "Bachwiese")
	var tor := _tor_daten("Riesentor")
	if not tor.is_empty():
		Schluchtsaum.wurzeltor(sa.wurzel, level.verlauf, float(tor["s"]), float(tor["abstand"]),
				1621, 3.2, float(tor["scheitel"]))
	# Trittsteine der Furt: Oberseite genau auf der Walze, nass unter der
	# Wasserlinie.
	for name: String in ["Furtstein 1", "Furtstein 2"]:
		var e := level.begehbar(name)
		if e.is_empty():
			continue
		var lage: Transform3D = e["lage"]
		var wasser := 6.0 - lage.origin.y
		_stein(sa, Findling.scheibe(float(e["radius"]), float(e["hoehe"]),
				{"saat": 1750 + name.length(), "wasser_y": wasser}), lage)
	_findlingsturm(sa, level)
	_wurzelknie(sa, level)
	sa.fertig()


## Der Findlingsturm (S2): ein hoher Stein bündig außen an der Kante, dahinter
## (jenseits der Leitlinie) eine Gruppe kleinerer Findlinge mit Farn.
static func _findlingsturm(sa: Sammler, level: Level01) -> void:
	var name := "Findlingsturm"
	var e := level.begehbar(name)
	if e.is_empty():
		return
	_findling_auf(sa, level, name, _mit_kisten(level, name, {"saat": 1891, "eckig": 3.4,
			"rundung": 0.2, "beulen": 0.12, "moos": 0.8, "moos_oben": 0.6,
			"ausgetreten": 0.3}), 0.0)
	var s: float = e["s"]
	_brocken(sa, Vector3(2.2, 2.6, 2.4), _lage(level, s + 0.6, 9.1, 0.0, 0.6), 1892, 0.3,
			{"moos": 1.0})
	_brocken(sa, Vector3(1.6, 1.5, 1.7), _lage(level, s - 1.9, 8.6, 0.0, 2.0), 1893, 0.25,
			{"moos": 1.0})
	_farn_bei(sa, _lage(level, s + 2.0, 8.3, 0.0, 0.2), 1, 1894, 0.8)
	_farn_bei(sa, _lage(level, s - 1.0, 8.0, 0.0, 1.9), 0, 1895, 1.3)


## Das Wurzelknie (S3): ein Wurzelbogen des Weltenbaums, der sich aus dem
## Boden wölbt, oben flach und bemoost genau auf +2,4, dahinter ein
## zweiter Strang aus Richtung des Stamms.
static func _wurzelknie(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Wurzelknie")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	var pfad := [
		[Vector3(-0.3, boden - 1.5, h.z + 0.8), 0.5, 0.6],
		[Vector3(0.0, boden + 0.1, h.z - 0.05), 0.66, 0.9],
		[Vector3(0.0, h.y - 1.1, h.z - 0.55), 0.76, 1.2],
		[Vector3(0.0, h.y - 1.1, 0.0), 0.76, 1.2],
		[Vector3(0.0, h.y - 1.1, -h.z + 0.55), 0.76, 1.2],
		[Vector3(0.0, boden + 0.1, -h.z + 0.05), 0.66, 0.9],
		[Vector3(-0.4, boden - 1.5, -h.z - 0.8), 0.5, 0.6],
	]
	var st := Riesenstamm.bauer()
	_wurzelkoerper(st, pfad, h, boden, 1911)
	# Der zweite Strang von hinten (Richtung Stamm, hinter der Leitlinie)
	var zug := PackedVector3Array([Vector3(-3.4, boden - 0.6, 1.2), Vector3(-2.3, boden + 0.4, 0.8),
			Vector3(-1.2, boden + 1.0, 0.3), Vector3(-0.5, boden + 1.1, 0.1)])
	Totholzzaun.stueck(st, _glatt(zug, 3), _glatt_r(PackedFloat32Array([0.5, 0.45, 0.4, 0.36]), 3),
			{"saat": 1912, "seiten": 10, "moos": 0.6, "ao": Vector2(0.6, 0.9)})
	_holz(sa, Riesenstamm.fertig(st), lage)
	_farn_bei(sa, lage.translated_local(Vector3(-1.4, boden, -1.9)), 1, 1913, 0.7)
	_farn_bei(sa, lage.translated_local(Vector3(-1.2, boden, 2.0)), 0, 1914, 1.3)
