extends RefCounted
class_name L01Wegbauten
## Level 01, Modul „Wegbauten": die Setpieces am Weg (Plan 5A–5D, 8.6, K7).
##
##   A  Wurzelnest hinter dem Start, Waldtor (s 3) zwischen zwei Stämmen,
##      Mooslog (s 8) mit Farn und Leuchtpilzen, Wurzeln im Erdspalt, der
##      Enthüllungsrahmen: ein toter Baum (s 28) und ein Findling (s 31)
##   B  Totholzgeländer (s 33–50) um die Kanzel mit geborstenem Endpfosten,
##      Kanzelplatte mit Drehkiefer, Wurzeln in der Kerbe, Spornfels,
##      Hangstamm, Nischenboden und Moosbank, die Torbaum-Pforte (links
##      ein Fels im Griff der Torbaumwurzeln, rechts ein Fels an der Kante),
##      der Torbaum auf der Felsnase links und das Pfortentor
##   D  Riesentor (s 162), Trittsteine der Furt, Findlingsturm, Wurzelknie
##
## FINDLING-REGEL (Plan E13, 8.6). Was man betreten kann, hat einen Körper
## aus `Level01.BEGEHBARES`, und die Optik passt genau darauf: Oberseite =
## Kollisionsoberkante, nichts ragt über den Kasten hinaus, was die Figur
## treffen könnte. Steine baut `Findling` (ein Block je Körper – in Blöcke
## zerlegt las sich die Moosbank als Reihe von Fässern), liegende Stämme
## `Riesenstamm.liegend` in derselben Lage wie die Kapsel. Wurzeln, die über
## einen Körper laufen, werden hinterher in seinen Kasten geklemmt
## (`_klemmen`): oben bündig mit der Oberkante (sie liegen im Moos, statt
## darauf), zur Wegseite bündig mit der Wand, und wo sie auf den Boden
## hinauslaufen, flacher als 0,3 m. Kisten stehen auf der ebenen Fläche
## (`Findling.plateau`): Die Steine unter Kisten haben deshalb eine knappe
## Kante (`_mit_kisten_auf`). Alles andere – Wurzeln, Äste, Farne,
## Deko-Felsen – steht so, dass man es nicht erreicht: hinter einer
## Leitlinie, über dem Abgrund, unter dem Weg oder niedriger als 0,35 m.
## Farne am Fuß und auf den Kanten der Steine sind weich; durch sie läuft
## man hindurch wie durch Gras.
##
## STEINE, DIE NICHT NACH KISTE AUSSEHEN. Ein Findling ist ein gerundeter
## Kasten mit ebener Oberseite; allein las er sich als Sockel mit Moos-
## deckel. Dagegen helfen hier: Schichten und tiefe Beulen, Moos, das von
## oben die Flanken hinabwächst (`_bemoost`, COLOR.a des Steins), kleine
## Farne auf den Oberkanten (`_randfarne`) und Wurzeln, die über den Stein
## greifen. Der Verdeckungsring folgt dem wirklichen Fuß des Netzes
## (`_fussring`): Nach dem Kasten gerechnet lag er an Steinen mit tiefen
## Beulen bis 0,4 m daneben, und der unverdeckte Streifen dazwischen las sich
## als helle Scheibe um den Stein.
##
## KAMERA (Plan K1, K2, Abschnitt 7). Nichts davon hat Kollision, der
## Kamerastrahl (1|8) trifft also nichts außer den Sichtsperren der Tore.
## Innerhalb |q| ≤ 6 steht über dem Weg nichts tiefer als 8,8 m. Die
## Rahmenbäume rechts halten sich aus dem ±6°-Kegel der Sichtlinie zur
## Krone des Weltenbaums (nachgerechnet von s 16 bis 96): Der tote Baum
## lehnt über den Abgrund und streckt die Äste nach außen, die Drehkiefer
## wächst als Kaskade in 3,5–5 m Höhe über die Kante (eine Sichtlinien-
## probe gegen die gezeichneten Netze fand sie von s 31 bis 84 in keiner
## Linie zu Stamm oder Krone). Der Torbaum steht links auf der Felsnase:
## Rechts am Rand (q 7) lag er vom ganzen Grat aus (s 24–80) auf der Linie
## zum STAMM des Weltenbaums (±5°) und deckte ihn mit Stamm und Krone zu –
## links liegt er 15–40° daneben, seine Krone neigt sich nach außen.
##
## KOSTEN (Plan 13: 25 Zeichenaufrufe, 10 für Schatten). `optik()` liefert
## für jeden Eintrag nur eine leere Marke; die Netze baut der Bauschritt je
## Stück verschmolzen, je Stoff eines. Stücke: Wurzelnest, Waldsaum (A),
## Hangweg vorn (33–66), Hangweg hinten (66–104, Sichtweite 75 m), Torbaum
## (mit Pfortentor, Wahrzeichen), Bachwiese (Sichtweite 110 m). Schatten
## werfen nur Stein und Borke. Harte Sichtweiten: Farn, Verdeckungsring,
## feine Wurzeln und Zweige bis `SICHT_NAH`, Böden bis 60 m, Stein, Borke
## und Kronen bis `SICHT_FERN` (je Stück enger), die Wurzeltore bis
## `SICHT_TOR`. Das Totholz des Geländers liegt im Borkennetz (grau nur über
## die Tönung). Das Wurzelnest sieht die Spielkamera nie – sie blickt immer
## nach vorn –, es wirft deshalb auch keinen Schatten. Gemessen (Verfolger,
## Tiefenvorlauf und Schatten eingerechnet): höchstens 28 Zeichenaufrufe
## (s 46), sonst 0–27; 45–78k Dreiecke auf dem Grat (s 4–101), 8–34k
## dahinter.

## Borkentönung der Kiefern: rötlich (Eigenfarbe ≤ 1).
const KIEFER_TON := Color(1.0, 0.78, 0.64)
## Der Torbaum: unten grau-braun, über 8 m die warme Spiegelrinde der Kiefer.
const TORBAUM_TON_UNTEN := Color(0.78, 0.72, 0.66)
const KIEFER_TON_OBEN := Color(1.0, 0.64, 0.44)
## Nadeln der Kiefern: dunkles, kühles Grün.
const NADEL := Color(0.17, 0.31, 0.18)
## So weit (m) bleibt Bewuchs von der Mitte einer Kiste weg.
const KISTEN_FREI := 1.3
## Sichtweiten (m): Kleinzeug, große Teile, Wurzeltore.
const SICHT_NAH := 45.0
const SICHT_FERN := 170.0
const SICHT_TOR := 130.0
## Schwelle gegen Flackern an der Sichtgrenze.
const SICHT_RAND := 5.0


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Wurzelnest, Mooslog und Waldtor", "tun": func() -> void: _waldsaum(level)},
		{"text": "Geländer und Kanzel am Hangweg", "tun": func() -> void: _hangweg_vorn(level)},
		{"text": "Moosbank und Torbaum-Pforte", "tun": func() -> void: _hangweg_hinten(level)},
		{"text": "Trittsteine und Riesentor", "tun": func() -> void: _bachwiese(level)},
	]


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "wegbauten".
## Nur eine leere Marke: Die Netze entstehen verschmolzen je Stück in den
## Bauschritten (siehe Kopf) – passgenau auf dieselbe Lage.
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
	## false: nichts in diesem Stück wirft Schatten (Wurzelnest).
	var schatten_erlaubt := true
	## Sichtweite der großen Teile (Stein, Borke, Kronen) in diesem Stück.
	var fern := SICHT_FERN
	var _werkzeuge := {}
	var _roh := {}
	var _stoffe := {}
	var _schatten := {}
	var _weiten := {}
	var _sicht := {}

	func _init(eltern: Node3D, name: String) -> void:
		wurzel = Node3D.new()
		wurzel.name = name
		eltern.add_child(wurzel)

	## Hängt `netz` (alle Flächen) mit `trafo` unter dem Stoff `schluessel` an.
	func dazu(schluessel: String, stoff: Material, schatten: bool, sicht: float, netz: Mesh,
			trafo: Transform3D = Transform3D.IDENTITY) -> void:
		if netz == null:
			return
		var st := werkzeug(schluessel, stoff, schatten, sicht)
		for f in netz.get_surface_count():
			st.append_from(netz, f, trafo)

	## Der Sammler eines Stoffs, in den fertige Netze angehängt werden.
	func werkzeug(schluessel: String, stoff: Material, schatten: bool,
			sicht: float) -> SurfaceTool:
		if not _werkzeuge.has(schluessel):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_werkzeuge[schluessel] = st
			_stoffe[schluessel] = stoff
			_schatten[schluessel] = schatten and schatten_erlaubt
			_sicht[schluessel] = fern if sicht == SICHT_FERN else sicht
		return _werkzeuge[schluessel]

	## Rohsammler im Borkenformat für direkt gebaute Teile eines Stoffs;
	## `fertig()` verschmilzt ihn (`Riesenstamm.fertig`) und hängt ihn an.
	func roh(schluessel: String, stoff: Material, schatten: bool, sicht: float) -> SurfaceTool:
		werkzeug(schluessel, stoff, schatten, sicht)
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
			var sicht: float = _sicht[schluessel]
			if sicht > 0.0:
				mi.visibility_range_end = sicht
				mi.visibility_range_end_margin = SICHT_RAND
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
	sa.dazu("Stein", Findling.stoff(), true, SICHT_FERN, netz, trafo)


static func _kranz(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Kranz", Findling.kranzstoff(), false, SICHT_NAH, netz, trafo)


static func _borke(sa: Sammler) -> SurfaceTool:
	return sa.roh("Borke", Riesenstamm.borkenstoff(), true, SICHT_FERN)


static func _holz(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Borke", Riesenstamm.borkenstoff(), true, SICHT_FERN, netz, trafo)


## Feine Wurzeln und Zweige: gleicher Stoff wie die Borke, aber ohne
## Schatten und nur in der Nähe – ein eigener Zeichenaufruf, der schon
## ab 45 m wegfällt.
static func _wurzeln(sa: Sammler) -> SurfaceTool:
	return sa.roh("Wurzeln", Riesenstamm.borkenstoff(), false, SICHT_NAH)


static func _krone(sa: Sammler, farbe: Color, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Krone", Kronenwolke.stoff(farbe), false, SICHT_FERN, netz, trafo)
	sa.weiten("Krone", 1.2)


static func _farn(sa: Sammler, netz: Mesh, trafo: Transform3D) -> void:
	sa.dazu("Farn", Farnwerk.stoff(), false, SICHT_NAH, netz, trafo)


# ================================================================ Lage

## Welttransform an (s, q, h): X quer nach rechts, Y hoch, −Z den Weg entlang.
static func _lage(level: Level01, s: float, q: float, h: float = 0.0,
		dreh: float = 0.0) -> Transform3D:
	var basis := Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s) + dreh)
	return Transform3D(basis, level.weg_punkt(s, q, h))


## Weltpunkt aus Wegkoordinaten (s, q, Höhe über der Decke).
static func _p(level: Level01, s: float, q: float, h: float = 0.0) -> Vector3:
	return level.weg_punkt(s, q, h)


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


## Orte aller Kisten, je Bauschritt einmal gelesen.
static var _kisten: Array[Vector3] = []


## Frei von Kisten? (Bewuchs hält `KISTEN_FREI` Abstand.)
static func _frei(p: Vector3, abstand: float = KISTEN_FREI) -> bool:
	for k in _kisten:
		if Vector2(k.x - p.x, k.z - p.z).length() < abstand:
			return false
	return true


static func _tor_daten(name: String) -> Dictionary:
	for t: Dictionary in Level01.TORE:
		if String(t["name"]) == name:
			return t
	return {}


static func _rahmenstelle(art: String) -> Dictionary:
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if String(stelle["art"]) == art:
			return stelle
	return {}


## Ein Wurzeltor aus `Level01.TORE` (Schluchtsaum.wurzeltor) mit Sichtweite.
static func _wurzeltor(sa: Sammler, level: Level01, name: String, saat: int) -> void:
	var tor := _tor_daten(name)
	if tor.is_empty():
		return
	var knoten := Schluchtsaum.wurzeltor(sa.wurzel, level.verlauf, float(tor["s"]),
			float(tor["abstand"]), saat, 3.2, float(tor["scheitel"]))
	knoten.name = name
	for mi in knoten.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visibility_range_end = SICHT_TOR
		(mi as MeshInstance3D).visibility_range_end_margin = SICHT_RAND


# ================================================================ Bausteine

## Ein Findling genau auf einen Kasten aus BEGEHBARES, mit Verdeckungsring
## um den Fuß auf der Bodenhöhe `boden_h` (über der Decke; NAN = ohne
## Ring). Optionen wie `Findling.netz`, dazu "bemoost": Vector2(Stärke, ab
## welchem Anteil der Höhe) für `_bemoost`. Unter Kisten wird die Kante so
## knapp, dass jede Kiste ganz auf der ebenen Fläche steht.
static func _findling_auf(sa: Sammler, level: Level01, name: String, optionen: Dictionary,
		boden_h: float = 0.0) -> void:
	var e := level.begehbar(name)
	if e.is_empty():
		return
	var groesse: Vector3 = e["groesse"]
	var lage: Transform3D = e["lage"]
	var boden_lokal := boden_h - (float(e.get("oben", 0.0)) - groesse.y * 0.5)
	var o := optionen.duplicate()
	o.erase("bemoost")
	o = _mit_kisten_auf(level, name, lage, groesse, o)
	var netz := Findling.netz(groesse, o)
	var moos: Vector2 = optionen.get("bemoost", Vector2.ZERO)
	if moos.x > 0.0:
		netz = _bemoost(netz, groesse * 0.5, boden_lokal, moos.x, moos.y,
				int(optionen.get("saat", 1)))
	_stein(sa, netz, lage)
	if not is_nan(boden_h):
		var breite := clampf(minf(groesse.x, groesse.z) * 0.3, 0.35, 0.8)
		_kranz(sa, _fussring(netz, boden_lokal, breite), lage)


## Kleine Farne auf der Oberkante eines Kastens, an seinen Rändern: Sie
## brechen die harte Kante, an der die ebene Oberseite in die Flanke
## übergeht (sonst liest sich der Stein wie ein Sockel mit Moosdeckel).
## Weg von den Kisten; weich, man läuft hindurch.
static func _randfarne(sa: Sammler, level: Level01, name: String, anzahl: int, saat: int) -> void:
	var e := level.begehbar(name)
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var rng := PropWerkzeug.zufall(saat)
	var gesetzt := 0
	for versuch in anzahl * 4:
		if gesetzt >= anzahl:
			break
		# Auf dem Umfang: Seite würfeln, dann die Stelle darauf.
		var seite := rng.randi_range(0, 3)
		var t := rng.randf_range(-0.85, 0.85)
		var ort := Vector3.ZERO
		match seite:
			0:
				ort = Vector3(h.x - 0.25, h.y, t * h.z)
			1:
				ort = Vector3(-h.x + 0.25, h.y, t * h.z)
			2:
				ort = Vector3(t * h.x, h.y, h.z - 0.25)
			_:
				ort = Vector3(t * h.x, h.y, -h.z + 0.25)
		var welt := lage * ort
		if not _frei(welt, 1.1):
			continue
		var trafo := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), welt)
		_farn_bei(sa, trafo, 0, saat + versuch, rng.randf_range(0.8, 1.3))
		gesetzt += 1


## Verdeckungsring genau um den Fuß eines Netzes (lokale Koordinaten): Der
## Umriss wird dort abgelesen, wo das Netz die Bodenhöhe `y` schneidet –
## je Winkel der größte Abstand der Ecken in einem Band um `y`. Nach dem
## Kasten gerechnet lag der Ring an Steinen mit tiefen Beulen bis 0,4 m
## neben dem Fuß, und zwischen Stein und Ring blieb ein heller Streifen.
static func _fussring(netz: ArrayMesh, y: float, breite: float,
		staerke: float = 0.55) -> ArrayMesh:
	const N := 36
	var radien := PackedFloat32Array()
	radien.resize(N)
	for f in netz.get_surface_count():
		var punkte: PackedVector3Array = netz.surface_get_arrays(f)[Mesh.ARRAY_VERTEX]
		for p in punkte:
			if absf(p.y - y) > 0.3:
				continue
			var d := Vector2(p.x, p.z)
			var w := atan2(-d.y, d.x)
			var k := posmod(int(floor(w / TAU * float(N) + 0.5)), N)
			radien[k] = maxf(radien[k], d.length())
	# Leere Winkel aus den Nachbarn füllen.
	for runde in 3:
		for k in N:
			if radien[k] <= 0.0:
				radien[k] = maxf(radien[(k + 1) % N], radien[(k + N - 1) % N]) * 0.97
	return Findling.kranz(radien, y + 0.025, breite, staerke, 0.25)


## Optionen für einen Stein, auf dem Kisten stehen: Die ebene Fläche
## (`Findling.plateau`) muss jede Kiste ganz tragen. Rundung und Umriss
## werden so weit verkleinert, bis das passt.
## Gilt für einen Block `groesse` in der Lage `lage` und zählt nur die
## Kisten, deren Mitte über diesem Block steht.
static func _mit_kisten_auf(level: Level01, name: String, lage: Transform3D, groesse: Vector3,
		optionen: Dictionary) -> Dictionary:
	var noetig := Vector2.ZERO
	var h := groesse * 0.5
	for k: Dictionary in Level01.KISTEN:
		if String(k.get("auf", "")) != name:
			continue
		var lokal := lage.affine_inverse() * level.kisten_ort(k)
		if absf(lokal.x) > h.x or absf(lokal.z) > h.z:
			continue
		noetig.x = maxf(noetig.x, absf(lokal.x) + 0.5)
		noetig.y = maxf(noetig.y, absf(lokal.z) + 0.5)
	var o := optionen.duplicate()
	for versuch in 8:
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
		einsinken: float = 0.25, optionen: Dictionary = {}, ring: bool = true) -> void:
	var o := {"saat": saat}
	o.merge(optionen, true)
	var t := trafo.translated_local(Vector3(0.0, groesse.y * 0.5 - einsinken, 0.0))
	var netz := Findling.brocken(groesse, o)
	_stein(sa, netz, t)
	if ring:
		var breite := clampf(minf(groesse.x, groesse.z) * 0.35, 0.3, 0.8)
		_kranz(sa, _fussring(netz, -groesse.y * 0.5 + einsinken, breite), t)


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


## Eine Wurzel als Holzstück entlang `punkte` (Welt), dick am Anfang, in
## den Sammler `st`.
static func _wurzelstrang(st: SurfaceTool, punkte: PackedVector3Array, r0: float, r1: float,
		saat: int, optionen: Dictionary = {}) -> void:
	var radien := PackedFloat32Array()
	for i in punkte.size():
		radien.append(lerpf(r0, r1, float(i) / float(maxi(punkte.size() - 1, 1))))
	var o := {"saat": saat, "seiten": 7 if r0 > 0.12 else 5, "ende": "spitz", "moos": 0.35,
			"buckel": 0.1}
	o.merge(optionen, true)
	Totholzzaun.stueck(st, punkte, radien, o)


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


## Radien zu `_glatt(punkte, je)`: linear zwischen den Stützen.
static func _glatt_r(radien: PackedFloat32Array, je: int) -> PackedFloat32Array:
	var aus := PackedFloat32Array()
	for i in radien.size() - 1:
		for k in je:
			aus.append(lerpf(radien[i], radien[i + 1], float(k) / float(je)))
	aus.append(radien[radien.size() - 1])
	return aus


static func _kreis(r: float, n: int) -> PackedFloat32Array:
	var radien := PackedFloat32Array()
	for i in n:
		radien.append(r)
	return radien


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


## Legt Moos über einen Stein: COLOR.a (Moosanteil im Stoff von `Findling`)
## wächst von `ab` (Anteil der Höhe über dem Boden) nach oben auf `staerke`,
## in Flecken und Zungen aus Rauschen, auf allem, was nach oben schaut,
## mehr. Die Findlinge tragen Moos sonst nur in Zungen über der Kante –
## eine Moosbank muss aber grün sein.
static func _bemoost(netz: ArrayMesh, h: Vector3, boden: float, staerke: float, ab: float,
		saat: int) -> ArrayMesh:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 0.7
	rauschen.fractal_octaves = 2
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var punkte: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normalen: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in punkte.size():
			var v := punkte[i]
			var hoch := clampf((v.y - boden) / maxf(h.y - boden, 0.1), 0.0, 1.0)
			var fleck := 0.5 + 0.7 * rauschen.get_noise_3d(v.x * 1.3, v.y * 0.6, v.z * 1.3)
			var m := smoothstep(ab, ab + 0.35, hoch + (fleck - 0.5) * 0.5) * staerke
			m += maxf(normalen[i].y, 0.0) * 0.35 * staerke
			var c := farben[i]
			c.a = clampf(maxf(c.a, m * clampf(fleck + 0.35, 0.0, 1.0)), 0.0, 1.0)
			farben[i] = c
		arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return neu


## Klemmt ein Netz (Kastenkoordinaten, Halbmaße `h`, Wegdecke auf der
## lokalen Höhe `boden`) in seinen Kasten: Über dem Grundriss nie höher als
## die Oberkante; auf erreichbarem Boden neben dem Kasten nie höher als
## 0,3 m – was dort höher liegt, wird an die Kastenwand gezogen. `aussen`
## (+1/−1) nennt die Seite (±X), die man nicht erreicht (Abgrund, hinter
## der Leitlinie): Dort darf das Netz hinaus. `ueber`: so weit darf es über
## der Oberkante liegen – zwei Zentimeter für Wurzeln auf einem Stein, damit
## sie nicht mit seiner Oberseite flimmern (niemand sieht, dass die Figur
## darauf zwei Zentimeter einsinkt). Die Normalen bleiben – die geklemmten
## Stellen sind flache Stirnen im Moos oder an der Wand.
static func _klemmen(netz: ArrayMesh, h: Vector3, boden: float, aussen: float,
		ueber: float = 0.0) -> ArrayMesh:
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var punkte: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in punkte.size():
			var v := punkte[i]
			var jenseits := aussen != 0.0 and v.x * aussen > h.x
			if not jenseits and v.y > boden + 0.3:
				if aussen > 0.0:
					v.x = maxf(v.x, -h.x + 0.004)
				elif aussen < 0.0:
					v.x = minf(v.x, h.x - 0.004)
				else:
					v.x = clampf(v.x, -h.x + 0.004, h.x - 0.004)
				v.z = clampf(v.z, -h.z + 0.004, h.z - 0.004)
			if absf(v.x) <= h.x + 0.01 and absf(v.z) <= h.z + 0.01:
				v.y = minf(v.y, h.y + ueber - 0.004)
			punkte[i] = v
		arrays[Mesh.ARRAY_VERTEX] = punkte
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return neu


## Ein Kiefernwipfel: Äste ([Ansatz, Richtung, Länge, Polsterradius] in den
## Koordinaten des Baums), jeder mit einem flachen Nadelpolster am Ende und
## an jedem zweiten ein kleineres daneben. Die Äste gehen in den Rohsammler
## `st`, die Polster in die Krone. `lage` setzt alles in die Welt.
static func _kiefernwipfel(sa: Sammler, st: SurfaceTool, lage: Transform3D, aeste: Array,
		saat: int, nebenpolster: bool = true) -> void:
	var rng := PropWerkzeug.zufall(saat)
	for i in aeste.size():
		var ast: Array = aeste[i]
		var start: Vector3 = ast[0]
		var richtung: Vector3 = (ast[1] as Vector3).normalized()
		var laenge: float = ast[2]
		var polster: float = ast[3]
		# Kiefernäste steigen erst, dann biegen sie waagerecht aus.
		var knick := start + (richtung + Vector3.UP * 0.35).normalized() * laenge * 0.45
		var ende := start + richtung * laenge + Vector3.UP * laenge * 0.12
		var r0 := clampf(laenge * 0.045, 0.07, 0.2)
		Totholzzaun.stueck(st, _glatt(PackedVector3Array([start, knick, ende]), 2),
				_glatt_r(PackedFloat32Array([r0, r0 * 0.62, r0 * 0.3]), 2), {"saat": saat + i * 7,
				"seiten": 6, "ende": "spitz", "moos": 0.1, "ton": KIEFER_TON})
		_polster(sa, lage * (ende + Vector3.UP * polster * 0.18), polster, saat + 40 + i,
				rng.randf_range(0.9, 1.1))
		if nebenpolster and i % 2 == 0:
			# Ein Seitenzweig zum zweiten Polster.
			var quer := richtung.cross(Vector3.UP).normalized() * (1.0 if i % 4 == 0 else -1.0)
			var zweig_ende := knick + (quer * 0.8 + richtung * 0.5).normalized() * laenge * 0.42 \
					+ Vector3.UP * 0.15
			Totholzzaun.stueck(st, PackedVector3Array([knick, knick.lerp(zweig_ende, 0.5)
					+ Vector3.UP * 0.1, zweig_ende]), PackedFloat32Array([r0 * 0.5, r0 * 0.35,
					r0 * 0.2]), {"saat": saat + i * 7 + 3, "seiten": 5, "ende": "spitz",
					"moos": 0.0, "ton": KIEFER_TON})
			_polster(sa, lage * (zweig_ende + Vector3.UP * polster * 0.12), polster * 0.65,
					saat + 60 + i, rng.randf_range(0.88, 1.08))


## Nadelpolster einer Kiefer: flache, breite Wolke an `mitte` (Welt).
## Die Helligkeit `hell` steckt in der Scheitelfarbe (COLOR.rgb tönt, A ist
## das Windgewicht): Alle Polster teilen EINEN Stoff, sonst legte
## `Kronenwolke.stoff` je Ton einen neuen an, und das verschmolzene Netz
## trüge ohnehin nur den ersten.
##
## Große Polster (r > 1,7) werden zu drei kleineren Büscheln: Kiefernlaub
## steht in Büscheln, und Ballen unter 0,9 m baut `Kronenwolke` mit einem
## Viertel der Dreiecke.
static func _polster(sa: Sammler, mitte: Vector3, r: float, saat: int, hell: float = 1.0) -> void:
	if r > 1.7:
		var rng := PropWerkzeug.zufall(saat)
		var dreh := rng.randf() * TAU
		for k in 3:
			var a := dreh + TAU * float(k) / 3.0 + rng.randf_range(-0.3, 0.3)
			var ort := mitte + Vector3(cos(a) * r * 0.42, rng.randf_range(-0.12, 0.18) * r,
					-sin(a) * r * 0.42)
			_polster(sa, ort, minf(r * 0.6, 1.7), saat * 3 + k, hell * rng.randf_range(0.94, 1.06))
		return
	var netz := Kronenwolke.netz({"radius": r, "hoehe": r * 0.5, "variante": 1, "saat": saat,
			"ballen": 3 if r < 1.4 else 4, "karten": clampi(int(r * r * 6.0), 10, 40)})
	if absf(hell - 1.0) > 0.001:
		netz = _getoent(netz, Color(hell, hell, hell))
	_krone(sa, NADEL, netz, Transform3D(Basis.IDENTITY, mitte))


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
	var st := sa.werkzeug(name, stoff, false, 60.0)
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
	# Hinter dem Start: eigenes Stück ohne Schatten – die Spielkamera blickt
	# immer nach vorn und sieht es nie.
	var nest := Sammler.new(_wurzel(level), "Wurzelnest")
	nest.schatten_erlaubt = false
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


## Hinter dem Start: ein gestürzter Stamm quer über dem Weg, Wurzelbögen,
## die sich aus dem Boden wölben, Farn dazwischen. Die Querleitlinie steht
## bei s −7; alles hier liegt dahinter oder seitlich hinter ±5,6.
static func _wurzelnest(sa: Sammler, level: Level01) -> void:
	var lage := _lage(level, -9.2, 0.6, 0.45, 0.12)
	var liegend := Riesenstamm.liegend(1.05, 17.0, {"saat": 311, "rippen": 11, "aeste": 2})
	_holz(sa, liegend, lage * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO))
	var rng := PropWerkzeug.zufall(4401)
	var st := _borke(sa)
	for i in 6:
		var q0 := rng.randf_range(-7.5, 7.5)
		var s0 := rng.randf_range(-12.5, -7.8)
		var hoch := rng.randf_range(1.2, 3.0)
		var weite := rng.randf_range(2.5, 5.0)
		var richtung := rng.randf_range(-0.9, 0.9)
		var stuetzen := PackedVector3Array()
		for k in 5:
			var t := float(k) / 4.0
			var s := s0 - cos(richtung) * weite * t * 0.4
			var q := q0 + sin(richtung) * weite * t
			stuetzen.append(_p(level, s, q, sin(t * PI) * hoch - 0.4))
		_wurzelstrang(st, _glatt(stuetzen, 3), rng.randf_range(0.18, 0.34),
				rng.randf_range(0.08, 0.14), 4410 + i, {"ende": "offen", "anfang": "offen",
				"seiten": 6})
	for k in 4:
		var q := rng.randf_range(-6.5, 6.5)
		_farn_bei(sa, _lage(level, rng.randf_range(-10.5, -8.3), q, 0.2, rng.randf() * TAU), 0,
				4440 + k, rng.randf_range(1.6, 2.2))


## Das Waldtor bei s 3 zwischen zwei Stämmen der ersten Reihe. Die Kronen
## gehören zum Blätterdach des Hallenwalds (ab 9,5 m über dem Weg). Die
## Spielkamera steht hier auf s 0 und sieht die Stämme nie – sie stehen
## neben ihr –, nur ihre Schatten: deshalb die schlichte Fassung.
static func _waldtor(sa: Sammler, level: Level01) -> void:
	var tor := _tor_daten("Waldtor")
	var s: float = tor["s"]
	for seite: float in [-1.0, 1.0]:
		var q := seite * (float(tor["abstand"]) + 1.5)
		var netz := Riesenstamm.schlicht({"hoehe": 19.0, "radius": 0.85, "radius_oben": 0.55,
				"saat": 71 + int(seite)})
		var lage := _lage(level, s + 0.4 * seite, q, 0.0, seite)
		_holz(sa, netz, lage)
		var fuss: PackedFloat32Array = netz.get_meta("fuss_radien", PackedFloat32Array())
		if fuss.size() >= 3:
			_kranz(sa, Findling.kranz(fuss, 0.02, 1.2, 0.55, 0.3), lage)
		_farn_bei(sa, lage.translated_local(Vector3(-seite * 1.6, 0.0, 1.0)), 0, 75 + int(seite),
				1.5)
	_wurzeltor(sa, level, "Waldtor", 303)


## Das Mooslog bei s 8: ein umgestürzter Baum, der Stamm genau in der
## Kapsel (von Leitlinie zu Leitlinie). Links reißt der Wurzelteller aus dem
## Boden (Erde, Steine, abgerissene Wurzeln), rechts ist der Stamm
## abgebrochen: lange Faserspäne. Beides liegt hinter der Leitlinie (|q| ≥
## 5,6), an beiden Enden Farn und Pilze. Ein paar Leuchtpilze am Fuß der
## Flanke zur Kamera. Als Rohr mit zwei flachen Deckeln las es sich als
## Balken (Welle 6).
static func _mooslog(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Mooslog")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var r: float = e["radius"]
	var l: float = e["laenge"]
	var liegt := lage * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
	var netz := Riesenstamm.liegend(r, l, {"saat": 808, "rippen": 10, "aeste": 0, "moos": 1.0})
	# Eigener Borkenstoff mit wenig Moos von oben (ein Zeichenaufruf mehr):
	# Mit dem gewöhnlichen lag ein gleichmäßig grüner Deckel auf dem Stamm.
	# Das Moos setzt hier die Scheitelfarbe – in Flecken und Zungen.
	sa.dazu("Mooslog", Riesenstamm.borkenstoff({"moos_oben": 0.12, "moos_nord": 0.2}), true,
			SICHT_FERN, _log_nachbessern(netz, r, l), liegt)
	var s: float = e["s"]
	var halb := l * 0.5
	# Aststummel an den äußeren Dritteln, waagerecht nach vorn und hinten
	# und nicht höher als die Kapsel: Man springt darüber hinweg, ohne an
	# etwas hängen zu bleiben, das keine Kollision hat.
	var stummel := Riesenstamm.bauer()
	var stummel_rng := PropWerkzeug.zufall(815)
	for k in 3:
		var q: float = [-3.2, -2.1, 2.9][k]
		var richtung := -1.0 if k != 1 else 1.0
		var start := _p(level, s, q, r * 1.05)
		var vor := LevelWerkzeuge.richtung(level.verlauf, s)
		var raus := (vor * richtung + Vector3.DOWN * 0.12).normalized()
		var laenge := stummel_rng.randf_range(0.26, 0.38)
		Totholzzaun.stueck(stummel, PackedVector3Array([start, start + raus * (r * 0.8),
				start + raus * (r * 0.8 + laenge)]), PackedFloat32Array([0.11, 0.09, 0.07]),
				{"saat": 816 + k, "seiten": 6, "ende": "bruch", "moos": 0.5})
	_holz(sa, Riesenstamm.fertig(stummel), Transform3D.IDENTITY)
	_wurzelteller(sa, level, s, -halb, r)
	_stammbruch(sa, level, s, halb, r)
	# Farn und Pilze an beiden Enden, außen hinter der Leitlinie (K7: über
	# 0,9 m erst ab |q| 5,05); innen reichen die Wedel über das Stammende.
	for seite: float in [-1.0, 1.0]:
		_farn_bei(sa, _lage(level, s + 0.9, seite * 5.9, 0.0, seite * 0.6), 0, 810 + int(seite), 2.0)
		_farn_bei(sa, _lage(level, s - 1.1, seite * 6.3, 0.0, 1.3), 1, 812 + int(seite), 0.9)
		_farn_bei(sa, _lage(level, s + 1.2, seite * 4.9, 0.0, 2.1), 0, 814 + int(seite), 1.1)
	var rng := PropWerkzeug.zufall(820)
	var pilze := Riesenstamm.bauer()
	# Leuchtpilze am Fuß der Flanke zur Kamera, unter 0,35 m.
	for i in 3:
		var q := rng.randf_range(-3.5, 3.5)
		var ort := _p(level, s - r * 0.95, q, 0.05)
		for k in rng.randi_range(2, 4):
			Riesenstamm.leuchtpilz_in(pilze, ort + Vector3(rng.randf_range(-0.2, 0.2), 0.0,
					rng.randf_range(-0.05, 0.05)), rng.randf_range(0.035, 0.06), rng)
	# Pilzgruppen an den Enden: am Boden und auf dem Stamm.
	for seite: float in [-1.0, 1.0]:
		for k in 2:
			var ort := _p(level, s + rng.randf_range(-0.9, 0.9),
					seite * rng.randf_range(5.0, 5.5), 0.02)
			if k == 1:
				ort = _p(level, s + rng.randf_range(-0.1, 0.1), seite * (halb - 0.9), r * 1.85)
			for n in rng.randi_range(3, 5):
				Riesenstamm.leuchtpilz_in(pilze, ort + Vector3(rng.randf_range(-0.22, 0.22), 0.0,
						rng.randf_range(-0.22, 0.22)), rng.randf_range(0.04, 0.075), rng)
	_holz(sa, Riesenstamm.fertig(pilze), Transform3D.IDENTITY)


## Der Wurzelteller am linken Ende des Mooslogs (`q_ende`, Mitte des Stamms
## auf Höhe `r`): eine aufgestellte, unruhige Scheibe aus Erde und Wurzeln
## (Ø gut 2,6 m), unten im Boden, hinter der Leitlinie. Die Wurzeln reißen
## strahlig aus ihr heraus, ein paar Steine hängen in der Erde.
static func _wurzelteller(sa: Sammler, level: Level01, s: float, q_ende: float, r: float) -> void:
	var seite := signf(q_ende)
	var vor := LevelWerkzeuge.richtung(level.verlauf, s)
	var quer := vor.cross(Vector3.UP).normalized() * seite
	var mitte := _p(level, s, q_ende + seite * 0.75, r * 1.6)
	var rng := PropWerkzeug.zufall(823)
	var holz := _borke(sa)
	# Der Teller: eine flache Knolle zum Weg hin (bis an die Leitlinie), eine
	# kleinere nach außen – Borke, Erde und Moos im Borkenstoff, unten im
	# Boden. Als heller Stein las er sich wie ein Grabstein.
	Weltenbaum.knolle_in(holz, mitte, -quer, 1.25, rng, 0.45)
	Weltenbaum.knolle_in(holz, mitte + quer * 0.1, quer, 0.95, rng, 0.3)
	var st := _wurzeln(sa)
	for i in 14:
		var w := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / 14.0
		var richtung := (vor * cos(w) + Vector3.UP * sin(w)).normalized()
		if richtung.y < -0.6:
			continue
		var start := mitte + richtung * rng.randf_range(0.7, 1.05) - quer * 0.1
		var lang := rng.randf_range(0.5, 1.3)
		var zug := PackedVector3Array([start,
				start + richtung * lang * 0.5 + quer * rng.randf_range(0.05, 0.3),
				start + richtung * lang + quer * rng.randf_range(0.15, 0.6)
						+ Vector3.DOWN * rng.randf_range(0.0, 0.35)])
		var dick := rng.randf_range(0.05, 0.13)
		Totholzzaun.stueck(holz if dick > 0.09 else st, zug,
				PackedFloat32Array([dick, dick * 0.6, dick * 0.25]),
				{"saat": 824 + i, "seiten": 6, "ende": "spitz", "moos": 0.2})
	# Steine in der Erde des Tellers, zum Weg hin
	for k in 3:
		var w := rng.randf_range(0.4, 2.7)
		var ort := mitte + (vor * cos(w) + Vector3.UP * sin(w) * 0.8) * rng.randf_range(0.35, 0.8) \
				- quer * 0.55
		_brocken(sa, Vector3.ONE * rng.randf_range(0.2, 0.32), Transform3D(Basis(), ort), 830 + k,
				0.1, {}, false)


## Das rechte Ende des Mooslogs: abgebrochen, ein Kranz langer Faserspäne
## (0,3–0,8 m) aus dem Rand, hell im Bruch, nach außen hinter die Leitlinie.
static func _stammbruch(sa: Sammler, level: Level01, s: float, q_ende: float, r: float) -> void:
	var seite := signf(q_ende)
	var vor := LevelWerkzeuge.richtung(level.verlauf, s)
	var quer := vor.cross(Vector3.UP).normalized() * seite
	var achse := _p(level, s, q_ende - seite * 0.2, r)
	var rng := PropWerkzeug.zufall(840)
	var holz := _borke(sa)
	for i in 9:
		var w := TAU * float(i) / 9.0 + rng.randf_range(-0.2, 0.2)
		var rund := (vor * cos(w) + Vector3.UP * sin(w))
		var start := achse + rund * r * rng.randf_range(0.55, 0.85)
		var lang := rng.randf_range(0.3, 0.8)
		var spitze := start + quer * lang + rund * rng.randf_range(0.0, 0.15) \
				+ Vector3.DOWN * rng.randf_range(0.0, 0.1)
		Totholzzaun.stueck(holz, PackedVector3Array([start, start.lerp(spitze, 0.5), spitze]),
				PackedFloat32Array([0.07, 0.045, 0.012]),
				{"saat": 841 + i, "seiten": 5, "ende": "spitz", "moos": 0.0,
				"ton": Color(1.0, 0.92, 0.8)})


## Das Mooslog nachgebessert, damit es sich nicht als Balken mit grünem
## Deckel liest (Netz im Raum der Kapsel: Achse +Y, lokal X zeigt nach
## oben, lokal Z nach hinten zur Kamera):
## * runde Schattierung: die Unterseite auf 0,4 abgedunkelt;
## * Moos, das an der Flanke zur Kamera in Zungen herabtropft;
## * ein Borkenriss längs über zwei Drittel der Länge;
## * dunkle, morsche Stirnflächen (die Eigenfarbe von `Riesenstamm.liegend`
##   ist für diesen Stoff zu hell);
## * ein leichter Bogen, höchstens 6 cm aus der Kapsel.
static func _log_nachbessern(netz: ArrayMesh, r: float, l: float) -> ArrayMesh:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 831
	rauschen.frequency = 1.6
	var neu := ArrayMesh.new()
	var halb := maxf(l * 0.5, 0.1)
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var punkte: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normalen: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var arten: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		for i in punkte.size():
			var p := punkte[i]
			var n := normalen[i]
			var c := farben[i]
			var t := clampf(p.y / halb, -1.0, 1.0)
			p.z += 0.06 * (1.0 - t * t)
			if arten[i].x > 0.5:
				# Stirnfläche: morsch und dunkel.
				c = Color(c.r * 0.32, c.g * 0.28, c.b * 0.24, c.a)
			else:
				var ao := lerpf(0.4, 1.0, smoothstep(-0.75, 0.55, n.x))
				var winkel := atan2(p.z, p.x)
				var riss := absf(angle_difference(winkel, 0.55)) < 0.07 and t > -0.7 and t < 0.35
				if riss:
					ao *= 0.3
				# Obenauf nur Flecken; an der Flanke zur Kamera schmale Zungen,
				# die unterschiedlich weit herabtropfen.
				var moos := c.a * 0.7
				if n.z > 0.1 and not riss:
					var zunge := rauschen.get_noise_1d(p.y * 3.1)
					if zunge > 0.15:
						var linie := r * (0.7 - 2.2 * (zunge - 0.15))
						moos = maxf(moos, smoothstep(linie, linie + 0.06, p.x) * 0.95)
				c = Color(c.r * ao, c.g * ao, c.b * ao, clampf(moos, 0.0, 1.0))
			punkte[i] = p
			farben[i] = c
		arrays[Mesh.ARRAY_VERTEX] = punkte
		arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu


## Wurzeln hängen in den Erdspalt, an beiden Lippen, aus der Stirnwand
## knapp unter der Kante – nichts liegt auf der Decke oder überspannt ihn.
static func _erdspalt(sa: Sammler, level: Level01) -> void:
	_lippenwurzeln(sa, level, 25.0, 27.5, 6.8, 2501)


## Wurzeln an den Lippen einer Lücke `von`–`bis`, quer bis `weit`.
static func _lippenwurzeln(sa: Sammler, level: Level01, von: float, bis: float, weit: float,
		saat: int, q_von: float = NAN, q_bis: float = NAN) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var st := _wurzeln(sa)
	var links := -weit if is_nan(q_von) else q_von
	var rechts := weit if is_nan(q_bis) else q_bis
	for lippe in 2:
		var s_kante := von if lippe == 0 else bis
		var hinein := 1.0 if lippe == 0 else -1.0
		var y_kante := level.boden_bei(s_kante - hinein * 0.05)
		var anzahl := int((rechts - links) / 2.3)
		for i in anzahl:
			var q := lerpf(links, rechts, (float(i) + rng.randf_range(0.1, 0.9)) / float(anzahl))
			# In der Spur (|q| < 2,2) sitzen die Lippensteine: dort nur
			# dünne Wurzeln, tiefer angesetzt.
			var spur := absf(q) < 2.2
			var dick := rng.randf_range(0.05, 0.09) if spur else rng.randf_range(0.07, 0.17)
			var tief := rng.randf_range(0.2, 0.6) + (0.25 if spur else 0.0)
			# Höchstens 2,5 m: Länger hingen sie ohne Stirnwand dahinter wie
			# Spinnenbeine ins Leere (die Stirnflächen baut der Saum).
			var lang := rng.randf_range(1.2, 2.5)
			var schwung := rng.randf_range(0.25, 0.6)
			var stuetzen := PackedVector3Array()
			for k in 5:
				var t := float(k) / 4.0
				var s := s_kante + hinein * (0.02 + schwung * sin(t * PI * 0.7) * 0.7 + t * 0.15)
				var p := LevelWerkzeuge.punkt_frei(level.verlauf, s,
						q + sin(t * 3.0 + float(i)) * 0.25)
				p.y = y_kante - tief - lang * t * t * 0.9 - t * lang * 0.1
				stuetzen.append(p)
			# Der Ansatz steckt in der Wand.
			var ansatz := LevelWerkzeuge.punkt_frei(level.verlauf, s_kante - hinein * 0.5, q)
			ansatz.y = y_kante - tief + 0.05
			stuetzen.insert(0, ansatz)
			_wurzelstrang(st, _glatt(stuetzen, 3), dick, dick * 0.3, saat + i * 7 + lippe,
					{"ao": Vector2(0.6, 0.35), "moos": 0.15, "anfang": "offen",
					"seiten": 5})


## Der Rahmen der Enthüllung: ein toter Baum (s 28), der über den Hang
## lehnt, und ein bemooster Findling (s 31) am rechten Rand.
static func _enthuellung(sa: Sammler, level: Level01) -> void:
	var tot := _rahmenstelle("totholz")
	if not tot.is_empty():
		_toter_baum(sa, level, tot)
	var stelle := _rahmenstelle("findling")
	if stelle.is_empty():
		return
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var h: float = stelle["hoehe"]
	var lage := _lage(level, s, q + 0.4, float(stelle["fuss"]), 0.5)
	_brocken(sa, Vector3(2.8, h, 2.4), lage, 3101, 0.3, {"moos": 1.0, "rundung": 0.6})
	_brocken(sa, Vector3(1.2, 0.75, 1.0), lage.translated_local(Vector3(1.7, 0.0, -1.1)),
			3102, 0.15)
	_brocken(sa, Vector3(0.7, 0.4, 0.6), lage.translated_local(Vector3(-1.5, 0.0, -0.9)),
			3105, 0.12, {}, false)
	_farn_bei(sa, lage.translated_local(Vector3(-1.2, 0.0, 1.0)), 1, 3103, 0.75)
	_farn_bei(sa, lage.translated_local(Vector3(0.6, 0.0, -1.6)), 0, 3104, 1.6)
	_farn_bei(sa, lage.translated_local(Vector3(1.6, 0.0, 1.2)), 0, 3106, 1.3)


## Ein toter Baum: kahl, oben gebrochen, lehnt nach außen über den Hang.
## Die Äste zeigen nach außen und nach oben und verzweigen sich zweimal –
## gegen den hellen Dunst des Tals liest er sich als Scherenschnitt. Über
## dem Weg (|q| ≤ 6) hängt unter 8,8 m nichts, und aus den
## Enthüllungsbildern steht er rechts neben dem Weltenbaum statt davor.
static func _toter_baum(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var hoehe: float = stelle["hoehe"]
	var lage := _lage(level, s, q, float(stelle["fuss"]))
	var h := hoehe * 0.82
	var neigung := Vector2(2.4, -0.7)
	var netz := Riesenstamm.netz({"hoehe": h, "radius": 0.52, "radius_oben": 0.28,
			"oben": "bruch", "saat": 2801, "brettwurzeln": 5, "wurzel_reichweite": 1.7,
			"wurzel_hoehe": 1.7, "neigung": neigung, "krumm": 0.0, "pilze": 3,
			"moos": 0.45, "aeste": 0, "rippen": 13})
	_holz(sa, _getoent(netz, Totholzzaun.RINDE_TON), lage)
	var fuss: PackedFloat32Array = netz.get_meta("fuss_radien", PackedFloat32Array())
	_kranz(sa, Findling.kranz(fuss, 0.02, 1.2, 0.55, 0.3), lage)
	var achse := func(y: float) -> Vector3:
		var t := clampf(y / h, 0.0, 1.0)
		return Vector3(neigung.x * pow(t, 1.5), y, neigung.y * pow(t, 1.5))
	# [Anteil der Höhe, Richtung (lokal: +X nach außen), Länge, Radius]
	var aeste := [
		[0.5, Vector3(1.0, 0.45, 0.25), 3.6, 0.14],
		[0.62, Vector3(0.55, 0.9, -0.6), 3.0, 0.12],
		[0.72, Vector3(1.0, 0.3, 0.6), 2.8, 0.11],
		[0.8, Vector3(0.3, 1.0, 0.5), 2.2, 0.09],
		[0.38, Vector3(0.8, 0.2, -0.8), 1.5, 0.1],
		[0.88, Vector3(0.9, 0.7, -0.2), 1.8, 0.08],
	]
	var st := _borke(sa)
	var feine := _wurzeln(sa)
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
					+ Vector3.UP * laenge * 0.1 * t * t
					+ Vector3(0.0, 0.0, sin(t * 3.0 + float(i)) * 0.18)))
		var radien := PackedFloat32Array([r, r * 0.8, r * 0.6, r * 0.42, r * 0.3])
		Totholzzaun.stueck(st, punkte, radien, {"saat": 2810 + i, "seiten": 6,
				"ende": "splitter" if i % 2 == 0 else "spitz", "moos": 0.2,
				"ton": Totholzzaun.RINDE_TON})
		# Zwei Zweige, die sich noch einmal gabeln.
		for z in 2:
			var gabel := punkte[2 + z]
			var seite := 1.0 if (i + z) % 2 == 0 else -1.0
			var quer := richtung.cross(Vector3.UP).normalized() * seite
			var zr := (richtung * 0.6 + Vector3.UP * 0.7 + quer * 0.5).normalized()
			var zl := laenge * (0.38 - 0.1 * float(z))
			var a := gabel
			var b := gabel + lage.basis * zr * zl * 0.5
			var c := gabel + lage.basis * (zr * zl + quer * 0.15)
			Totholzzaun.stueck(feine, PackedVector3Array([a, b, c]), PackedFloat32Array(
					[r * 0.42, r * 0.3, r * 0.16]), {"saat": 2820 + i * 3 + z, "seiten": 5,
					"ende": "spitz", "moos": 0.05, "ton": Totholzzaun.RINDE_TON})
			var d := c + lage.basis * (zr + Vector3.UP * 0.4 - quer * 0.6).normalized() * zl * 0.35
			Totholzzaun.stueck(feine, PackedVector3Array([b, b.lerp(d, 0.5) + Vector3.UP * 0.05, d]),
					PackedFloat32Array([r * 0.22, r * 0.16, r * 0.09]), {"saat": 2840 + i * 3 + z,
					"seiten": 4, "ende": "spitz", "moos": 0.0, "ton": Totholzzaun.RINDE_TON})
	# Am Fuß: Farn und zwei Steine
	_farn_bei(sa, lage.translated_local(Vector3(-0.9, 0.0, 1.2)), 0, 2830, 2.0)
	_farn_bei(sa, lage.translated_local(Vector3(1.2, 0.0, -1.0)), 0, 2832, 1.5)
	_brocken(sa, Vector3(0.9, 0.55, 0.8), lage.translated_local(Vector3(0.9, 0.0, 1.4)), 2831, 0.15)


# ================================================================ B Hangweg

static func _hangweg_vorn(level: Level01) -> void:
	_kisten = level.kisten_orte()
	var sa := Sammler.new(_wurzel(level), "Hangweg vorn")
	_gelaender(sa, level)
	_kanzel(sa, level)
	_kerbe(sa, level)
	_findling_auf(sa, level, "Spornfels", {"saat": 632, "eckig": 2.6, "rundung": 0.3,
			"beulen": 0.14, "moos": 0.9, "ausgetreten": 0.2, "schichten": false}, 0.0)
	_farn_bei(sa, _lage(level, 62.1, 5.3, 0.0, 0.7), 0, 633, 1.4)
	_farn_bei(sa, _lage(level, 64.4, 6.2, 0.0, 2.2), 0, 634, 1.1)
	sa.fertig()


static func _hangweg_hinten(level: Level01) -> void:
	_kisten = level.kisten_orte()
	# Moosbank, Pforte und Hangstamm sieht man vom Grat aus erst ab gut
	# 60 m; der Torbaum mit dem Pfortentor ist Wahrzeichen und eigenes Stück.
	var sa := Sammler.new(_wurzel(level), "Hangweg hinten")
	sa.fern = 75.0
	_hangstamm(sa, level)
	_nische(sa, level)
	_pforte(sa, level)
	_boden_fertig(sa, "Boden")
	sa.fertig()
	var baum := Sammler.new(_wurzel(level), "Torbaum")
	var stelle := _rahmenstelle("torbaum")
	if not stelle.is_empty():
		_torbaum(baum, level, stelle)
	_pfortentor(baum, level)
	baum.fertig()


## Das Pfortentor (TORE "Pfortentor", s 101,5): kein Bündel aus gleich
## dicken Rohren wie `Schluchtsaum.wurzeltor` – das las sich hier, im
## Wahrzeichenbild, als Gartenschläuche. Zwei Wurzeln verschiedener Stärke,
## die sich umeinander winden und zum Scheitel dünn werden, Moos nur
## obenauf und in großen Flecken, außen an den Füßen ein paar hängende
## Würzelchen (nie über dem Weg), Farne im Scheitel und im Zwickel. Dieselbe
## Bogenlinie und dieselben Sichtkörper wie `Schluchtsaum.wurzeltor`.
static func _pfortentor(sa: Sammler, level: Level01) -> void:
	var tor := _tor_daten("Pfortentor")
	if tor.is_empty():
		return
	var s: float = tor["s"]
	var weite := float(tor["abstand"]) + 0.8
	var fuss := 3.2
	var scheitel: float = tor["scheitel"]
	var mitte := LevelWerkzeuge.punkt(level.verlauf, s)
	var vor := LevelWerkzeuge.richtung(level.verlauf, s)
	var rechts := vor.cross(Vector3.UP).normalized()
	var linie := func(t: float) -> Vector3:
		return mitte + rechts * sin(t) * weite + Vector3.UP * (fuss + (scheitel - fuss) * cos(t))
	var st := _borke(sa)
	var rng := PropWerkzeug.zufall(1017)
	# Zwei Stränge: der dicke (0,62 → 0,24) und der schlanke (0,36 → 0,13),
	# um 180° versetzt, anderthalb Windungen je Hälfte. Die Unterkante liegt
	# auf dem Scheitel aus TORE.
	for strang in 2:
		var r_fuss: float = [0.62, 0.36][strang]
		var r_oben: float = [0.24, 0.13][strang]
		var aus: float = [0.3, 0.42][strang]
		var phase := PI * float(strang) + 0.4
		var punkte := PackedVector3Array()
		var radien := PackedFloat32Array()
		const N := 30
		for i in N + 1:
			var t := lerpf(-PI * 0.5 - 0.12, PI * 0.5 + 0.12, float(i) / float(N))
			var p: Vector3 = linie.call(t)
			var tangente := (rechts * cos(t) * weite - Vector3.UP * (scheitel - fuss) * sin(t)).normalized()
			var normale := tangente.cross(vor).normalized()
			var w := phase + t * 3.0
			var r := lerpf(r_oben, r_fuss, pow(absf(sin(t)), 1.6))
			# Die Unterkante bleibt auf dem Scheitel: im Scheitel liegen die
			# Stränge über der Linie.
			var hoch := (r + aus) * (1.0 - absf(sin(t)))
			punkte.append(p + (normale * cos(w) + vor * sin(w)) * aus * absf(sin(t))
					+ Vector3.UP * hoch)
			radien.append(r * (0.92 + 0.08 * sin(float(i) * 1.3 + float(strang))))
		var g := Weltenbaum.rohr(punkte, radien, {"seiten": 9, "beulen": 0.12,
				"saat": 1080 + strang, "uv_mass": 0.35})
		var farbe := func(_p: Vector3, n: Vector3) -> Color:
			var ao := lerpf(0.55, 1.0, clampf(n.y * 0.5 + 0.5, 0.0, 1.0))
			return Color(ao, ao, ao, clampf(n.y * 1.1 - 0.25, 0.0, 1.0))
		Weltenbaum.gitter_faerben(g, farbe, 0.3)
		Weltenbaum.gitter_schreiben(st, g)
	# Hängende Würzelchen außen an den Füßen – nach außen gebogen, nie über
	# den Weg (dort fährt die Kamera durch).
	for seite: float in [-1.0, 1.0]:
		for k in 3:
			var t := seite * rng.randf_range(0.95, 1.35)
			var ansatz: Vector3 = linie.call(t) + rechts * seite * 0.45
			var laenge := rng.randf_range(0.7, 1.6)
			var ende := ansatz + rechts * seite * rng.randf_range(0.2, 0.5) + Vector3.DOWN * laenge
			Totholzzaun.stueck(st, PackedVector3Array([ansatz, ansatz.lerp(ende, 0.5)
					+ rechts * seite * 0.12, ende]), PackedFloat32Array([0.06, 0.04, 0.02]),
					{"saat": 1090 + k + int(seite + 1.0) * 5, "seiten": 5, "ende": "spitz",
					"moos": 0.2})
	# Farne: zwei im Scheitel, einer im Zwickel am linken Fuß (bei den
	# Wurzeln des Torbaums).
	for t: float in [-0.35, 0.28]:
		var ort: Vector3 = linie.call(t) + Vector3.UP * 0.55
		_farn_bei(sa, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), ort), 0, 1095, 1.3)
	_farn_bei(sa, Transform3D(Basis(Vector3.UP, 0.7), linie.call(-1.45) - rechts * 0.3), 0,
			1096, 1.4)
	# Sichtkörper wie `Schluchtsaum.wurzeltor`: oben dick, an den Füßen schmal.
	var knoten := Node3D.new()
	knoten.name = "Pfortentor"
	sa.wurzel.add_child(knoten)
	var sperre := StaticBody3D.new()
	sperre.name = "Sichtsperre"
	sperre.collision_layer = LevelWerkzeuge.SICHTSPERRE
	sperre.collision_mask = 0
	knoten.add_child(sperre)
	const STUECKE := 12
	for i in STUECKE:
		var a: Vector3 = linie.call(lerpf(-PI * 0.5, PI * 0.5, float(i) / float(STUECKE)))
		var b: Vector3 = linie.call(lerpf(-PI * 0.5, PI * 0.5, float(i + 1) / float(STUECKE)))
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		var dick := 2.7 if minf(a.y, b.y) - mitte.y > 6.0 else 1.1
		kasten.size = Vector3(dick, dick, a.distance_to(b) + 0.2)
		form.shape = kasten
		form.transform = PropWerkzeug.ausrichten_z(a, b)
		sperre.add_child(form)


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
	# Die Linie ab der Enthüllung, 0,2 m hinter der Innenseite der Wand.
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
			linie.append(_p(level, p.x, p.y + 0.2))
	var ende := stellen[stellen.size() - 1]
	linie.append(_p(level, ende.x, ende.y + 0.2))
	var laengen := PackedFloat32Array([0.0])
	for i in range(1, linie.size()):
		laengen.append(laengen[i - 1] + linie[i].distance_to(linie[i - 1]))
	# Findlinge statt Zaunfeldern: [s, q der Innenkante (hinter der
	# Leitlinie), Größe]
	var luecken: Array[Vector2] = []
	var findlinge := [[36.3, 5.25, 1.35], [40.4, 9.85, 1.15], [47.6, 9.85, 1.25]]
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
	var zaun := Totholzzaun.bauen(linie, {"saat": 3301, "abstand": 2.3, "hoehe": 1.15,
			"aussen": 1.0, "luecken": luecken, "ende_geborsten": true, "verfall": 0.45})
	_holz(sa, zaun, Transform3D.IDENTITY)
	for i in findlinge.size():
		var f: Array = findlinge[i]
		var s: float = f[0]
		var g: float = f[2]
		var q: float = f[1] + g * 0.5
		_brocken(sa, Vector3(g, g * 0.8, g * 0.9), _lage(level, s, q, 0.0, float(i) * 1.3),
				3310 + i, 0.2, {"moos": 1.0})
		_farn_bei(sa, _lage(level, s + 0.8, q + 0.3, 0.0, float(i)), 0, 3315 + i, 1.2)
	# Der Felsrand unter dem Zaun: bündige Platten bis an die Schulter, tief
	# genug, dass sie in der Felswand des Saums stecken.
	for rand: Array in [[33.2, 39.9], [48.2, 50.8]]:
		var von: float = rand[0]
		var bis: float = rand[1]
		var laenge := bis - von
		var groesse := Vector3(1.0, 3.0, laenge)
		_stein(sa, Findling.netz(groesse, {"saat": 3320 + int(von), "eckig": 4.0,
				"rundung": 0.12, "umriss": 0.02, "moos": 0.9, "ausgetreten": 0.0,
				"schichten": false}), _kasten_lage(level, (von + bis) * 0.5, 5.2, groesse, 0.0))
	# Am geborstenen Pfosten: ein heruntergefallener Riegel und Farn.
	var ende_p := _lage(level, 50.4, 5.3, 0.0)
	Totholzzaun.stueck(_borke(sa),
			PackedVector3Array([ende_p * Vector3(-0.3, 0.07, 0.4), ende_p * Vector3(0.1, 0.05, 1.3),
			ende_p * Vector3(0.35, 0.08, 2.2)]),
			PackedFloat32Array([0.085, 0.085, 0.08]), {"saat": 3330, "form": "gespalten",
			"spalt": Vector3.UP, "ende": "splitter", "anfang": "splitter", "moos": 0.6,
			"ton": Totholzzaun.RINDE_TON})
	_farn_bei(sa, _lage(level, 49.4, 5.6, 0.0, 0.4), 0, 3331, 1.4)


## Die Kanzel: eine Felsplatte bündig mit dem Weg, auf der die erste
## Checkpoint-Kiste steht. Sichtbar reicht sie bis an die Schulter hinter
## der Leitlinie (so weit trägt die Kollision). Darauf die Drehkiefer.
static func _kanzel(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Kanzel")
	if e.is_empty():
		return
	var s: float = e["s"]
	var groesse: Vector3 = e["groesse"]
	# Innen 0,45 m unter die Wegdecke geschoben und 2 cm tiefer als sie: Die
	# gerundete Innenkante der Platte lag sonst als graue Rinne neben dem
	# Rasen der Decke.
	var innen: float = float(e["q"]) - groesse.x * 0.5 - 0.45
	var aussen := 10.2
	var platte := Vector3(aussen - innen, groesse.y, groesse.z + 1.4)
	_stein(sa, Findling.netz(platte, {"saat": 4401, "eckig": 4.4, "rundung": 0.22,
			"umriss": 0.03, "moos": 0.85, "moos_oben": 0.7, "ausgetreten": 0.9,
			"schichten": false}),
			_kasten_lage(level, s, (innen + aussen) * 0.5, platte, -0.02))
	# Farn in den Fugen am Fuß des Geländers, weg von den Kisten.
	var rng := PropWerkzeug.zufall(4410)
	for i in 5:
		var p := _lage(level, rng.randf_range(40.5, 47.5), rng.randf_range(9.0, 9.7), 0.0,
				rng.randf() * TAU)
		if _frei(p.origin):
			_farn_bei(sa, p, 0, 4411 + i, rng.randf_range(0.9, 1.3))
	var stelle := _rahmenstelle("drehkiefer")
	if not stelle.is_empty():
		_drehkiefer(sa, level, stelle)


## Die Drehkiefer auf der Kanzel: eine Kaskadenkiefer, wie sie an Felskanten
## wächst. Bis 2,6 m senkrecht im Zylinder der Kollision (Radius 0,45; die
## Figur kommt mit einem Sprung bis gut 3 m), dann knickt der Stamm über den
## Abgrund und läuft fast waagerecht hinaus; die Nadelpolster liegen in
## 3,5–5 m Höhe weit draußen (q 11–16). Höher und näher am Weg stünde die
## Krone von s 24 bis 40 in der Sichtlinie zur Krone des Weltenbaums
## (Plan 7, ±6°) – so rahmt sie das Tal darunter.
static func _drehkiefer(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var lage := _lage(level, s, q, float(stelle["fuss"]))
	var st := Riesenstamm.bauer()
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 4161
	# Stamm (lokal: X nach außen, Y hoch, −Z voraus)
	var achse := PackedVector3Array([Vector3(0.0, -0.8, 0.0), Vector3(0.02, 1.0, 0.0),
			Vector3(-0.02, 2.0, -0.05), Vector3(0.2, 2.75, -0.12), Vector3(1.0, 3.35, -0.22),
			Vector3(2.3, 3.6, -0.3), Vector3(3.7, 3.7, -0.22), Vector3(5.0, 3.9, -0.05),
			Vector3(6.1, 4.25, 0.12), Vector3(6.9, 4.7, 0.2)])
	var radien := PackedFloat32Array([0.46, 0.43, 0.41, 0.38, 0.33, 0.28, 0.23, 0.18, 0.13,
			0.08])
	Totholzzaun.stueck(st, _glatt(achse, 3), _glatt_r(radien, 3), {"saat": 4162, "seiten": 12,
			"ende": "spitz", "moos": 0.45, "drehung": 0.7, "buckel": 0.12,
			"ton": KIEFER_TON, "ao": Vector2(0.55, 1.0)})
	# Wurzeln krallen sich in den Fels, zwei laufen über den Rand hinab.
	# Flach: Die Kanzel ist begehbar, und nur der Stamm hat Kollision.
	for i in 5:
		var w := TAU * float(i) / 5.0 + 0.4
		Riesenstamm.brettwurzel_in(st, Vector3.ZERO, w, 0.45, 0.7 + 0.25 * float(i % 2),
				0.5, 0.2, 0.2, 1.8, 0.8, rauschen)
	for k in 2:
		var z := -0.5 + float(k) * 1.1
		var wurzel := PackedVector3Array([Vector3(0.3, 0.1, z * 0.4), Vector3(0.9, 0.06, z),
				Vector3(1.35, -0.1, z * 1.2), Vector3(1.55, -0.8, z * 1.3),
				Vector3(1.6, -1.8, z * 1.2)])
		Totholzzaun.stueck(st, _glatt(wurzel, 2), _glatt_r(PackedFloat32Array(
				[0.2, 0.16, 0.14, 0.11, 0.07]), 2), {"saat": 4170 + k, "seiten": 6,
				"ende": "spitz", "moos": 0.5, "ton": KIEFER_TON})
	# Ein trockener Ast über der Kanzel, oben am Knick.
	Totholzzaun.stueck(st, PackedVector3Array([Vector3(0.4, 3.0, -0.15), Vector3(0.2, 3.8, 0.4),
			Vector3(0.1, 4.3, 0.9)]), PackedFloat32Array([0.07, 0.05, 0.03]), {"saat": 4175,
			"seiten": 5, "ende": "splitter", "moos": 0.2, "ton": Totholzzaun.RINDE_TON})
	# [Ansatz, Richtung, Länge, Polsterradius]
	var aeste := [
		[Vector3(2.3, 3.6, -0.3), Vector3(0.3, 0.15, -1.0), 1.7, 1.3],
		[Vector3(3.3, 3.68, -0.25), Vector3(0.35, 0.2, 1.0), 1.9, 1.5],
		[Vector3(4.6, 3.85, -0.1), Vector3(0.5, 0.25, -1.0), 1.8, 1.5],
		[Vector3(6.3, 4.35, 0.14), Vector3(1.0, 0.3, 0.25), 1.3, 1.7],
		[Vector3(5.4, 4.0, 0.0), Vector3(0.2, 1.0, 0.15), 0.9, 1.2],
		[Vector3(5.8, 4.15, 0.08), Vector3(0.3, 0.1, 1.0), 1.5, 1.3],
	]
	_kiefernwipfel(sa, st, lage, aeste, 4180)
	_holz(sa, Riesenstamm.fertig(st), lage)
	_kranz(sa, Findling.kranz(_kreis(0.9, 24), 0.02, 0.9, 0.5, 0.25), lage)


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
	_farn_bei(sa, _lage(level, s - 0.6, 5.0, 0.0, 0.3), 0, 7502, 1.3)
	_farn_bei(sa, _lage(level, s + 0.7, 5.6, 0.0, 2.0), 0, 7503, 1.1)


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
	# Ein Block mit Schichten und tiefen Beulen: In Blöcke zerlegt las sich
	# die Bank als Reihe von Fässern.
	_findling_auf(sa, level, "Moosbank", {"saat": 8702, "eckig": 3.2,
			"rundung": 0.32, "beulen": 0.45, "unruhe": 0.18, "umriss": 0.1, "moos": 1.0,
			"moos_oben": 1.0, "ausgetreten": 0.1, "schichten": true, "anlauf": 0.12,
			"bemoost": Vector2(0.85, 0.55)}, 0.0)
	_randfarne(sa, level, "Moosbank", 7, 8790)
	var bank := level.begehbar("Moosbank")
	var bank_lage: Transform3D = bank["lage"]
	var bank_g: Vector3 = bank["groesse"]
	var bank_boden := -(float(bank["oben"]) - bank_g.y * 0.5)
	var rng := PropWerkzeug.zufall(8710)
	# Wurzeln der Böschung kriechen über den Rücken der Bank und hängen an
	# der Stirn herab – oben bündig im Moos, zur Wegseite an der Wand.
	var wst := Riesenstamm.bauer()
	# Zwei Wurzeln in den Fugen (z 3,0 und −2,8), wo keine Kiste steht; sie
	# schlängeln sich über die Kante und den Fels hinab.
	for i in 2:
		var z := 3.0 if i == 0 else -2.8
		var w := 1.0 if i == 0 else -1.0
		var r := 0.2 - 0.03 * float(i)
		var oben_y := bank_g.y * 0.5
		var zug := PackedVector3Array([
				Vector3(-3.4, bank_boden + 2.9, z + 0.5 * w), Vector3(-2.3, oben_y + 0.25, z + 0.3 * w),
				Vector3(-1.2, oben_y - r * 0.3, z), Vector3(0.1, oben_y - r * 0.4, z - 0.25 * w),
				Vector3(1.3, oben_y - r * 0.5, z + 0.2 * w), Vector3(1.72, oben_y - 0.7, z + 0.45 * w),
				Vector3(1.7, oben_y - 1.7, z + 0.1 * w), Vector3(1.74, bank_boden + 0.6, z - 0.35 * w),
				Vector3(2.1, bank_boden + 0.12, z - 0.6 * w), Vector3(2.8, bank_boden - 0.1,
				z - 0.9 * w)])
		var radien := PackedFloat32Array()
		for k in zug.size():
			radien.append(r * lerpf(1.35, 0.35, float(k) / float(zug.size() - 1)))
		Totholzzaun.stueck(wst, _glatt(zug, 2), _glatt_r(radien, 2), {"saat": 8750 + i,
				"seiten": 7, "ende": "spitz", "moos": 0.6, "buckel": 0.14,
				"ao": Vector2(0.7, 0.8)})
	var bank_wurzeln := _klemmen(Riesenstamm.fertig(wst), bank_g * 0.5, bank_boden, -1.0, 0.02)
	_holz(sa, bank_wurzeln, bank_lage)
	# Am Wandfuß und an den Enden der Bank
	var farne := [[83.0, -9.8, 1, 0.8], [91.4, -9.6, 0, 2.0], [93.6, -9.3, 0, 1.6],
			[95.6, -7.4, 0, 1.4], [85.5, -10.5, 0, 1.3], [88.7, -10.6, 0, 1.5],
			[79.6, -6.2, 0, 1.2], [96.8, -6.0, 0, 1.5], [90.0, -10.5, 0, 1.2]]
	for i in farne.size():
		var f: Array = farne[i]
		var p := _lage(level, float(f[0]), float(f[1]), 0.0, rng.randf() * TAU)
		if _frei(p.origin):
			_farn_bei(sa, p, int(f[2]), 8720 + i, float(f[3]) * rng.randf_range(0.85, 1.05))
	for i in 4:
		var s := rng.randf_range(92.5, 96.0) if i < 2 else rng.randf_range(79.5, 82.0)
		var q := float(q_bei.call(s)) + rng.randf_range(0.4, 0.8)
		var g := rng.randf_range(0.5, 0.8)
		var p := _lage(level, s, q, 0.0, rng.randf() * TAU)
		if _frei(p.origin):
			_brocken(sa, Vector3(g * 1.3, g * 0.6, g), p, 8730 + i, 0.2)
	# Ein Ast auf dem Nischenboden (flach, unter 0,35 m)
	var ast := PackedVector3Array([_p(level, 92.6, -6.4, 0.06), _p(level, 93.6, -7.1, 0.08),
			_p(level, 94.8, -7.4, 0.07), _p(level, 95.5, -8.1, 0.06)])
	Totholzzaun.stueck(_borke(sa), ast,
			PackedFloat32Array([0.08, 0.07, 0.06, 0.04]), {"saat": 8740, "ende": "spitz",
			"anfang": "splitter", "moos": 0.7, "ton": Totholzzaun.RINDE_TON})
	# Leuchtpilze am Fuß der Bank
	var pilze := Riesenstamm.bauer()
	for i in 3:
		var ort := bank_lage * Vector3(bank_g.x * 0.5 - 0.1 + rng.randf_range(0.0, 0.15),
				bank_boden + 0.02, rng.randf_range(-3.3, 3.3))
		for k in rng.randi_range(3, 5):
			Riesenstamm.leuchtpilz_in(pilze, ort + Vector3(rng.randf_range(-0.25, 0.25), 0.0,
					rng.randf_range(-0.25, 0.25)), rng.randf_range(0.04, 0.07), rng)
	_holz(sa, Riesenstamm.fertig(pilze), Transform3D.IDENTITY)


## Die Torbaum-Pforte (s 99,5–103,5): links ein Fels, der aus der Felsnase
## vorspringt, im Griff der Wurzeln des Torbaums, der oben auf der Felsnase
## steht; rechts ein freier Fels an der Kante. Darüber das Pfortentor, dessen
## linker Fuß in den Torbaum wächst.
static func _pforte(sa: Sammler, level: Level01) -> void:
	# Hinter der Leitlinie (q < −3,8): Felsmasse bis an die Felsnase.
	_brocken(sa, Vector3(2.6, 4.2, 5.4), _lage(level, 101.4, -5.4, 0.0, 0.1), 1012, 0.6,
			{"moos": 0.9, "kuppe": 0.5})
	_brocken(sa, Vector3(1.8, 2.3, 2.2), _lage(level, 98.3, -5.0, 0.0, 0.8), 1013, 0.35,
			{"moos": 1.0})
	_brocken(sa, Vector3(1.7, 1.6, 1.9), _lage(level, 104.7, -5.0, 0.0, 2.1), 1014, 0.3,
			{"moos": 1.0})
	# Die Farne der Pforte stehen hinter dem Felsen (q ≤ −5): Bei q −4,1 und
	# 1,8-facher Größe reichten ihre Wedel quer über die Öffnung und lagen
	# auf dem Handy (ohne MSAA) als grün gepunktete Striche über Figur und
	# Spinne – im wichtigsten Lehrbild, dem Slide (Welle 6).
	_farn_bei(sa, _lage(level, 98.6, -5.3, 0.0, 1.0), 0, 1015, 1.3)
	_farn_bei(sa, _lage(level, 104.1, -5.1, 0.0, 2.0), 0, 1016, 1.2)
	var links := level.begehbar("Pforte links")
	if not links.is_empty():
		_wurzelstock(sa, level, links)
	_findling_auf(sa, level, "Pforte rechts", {"saat": 1022, "eckig": 2.8,
			"rundung": 0.36, "beulen": 0.34, "unruhe": 0.15, "umriss": 0.12, "moos": 1.0,
			"moos_oben": 0.9, "ausgetreten": 0.0, "schichten": true, "anlauf": 0.1,
			"bemoost": Vector2(0.8, 0.55)}, 0.0)
	# Keine Randfarne auf dem rechten Felsen: Von seiner Innenkante hingen
	# die Wedel in die Öffnung. Nur ein Farn an der Außenkante (unten).
	var rechts := level.begehbar("Pforte rechts")
	if not rechts.is_empty():
		# Farn obenauf an der Außenkante, wo man nicht hinkommt, ohne
		# hinaufzuspringen.
		var lage_r: Transform3D = rechts["lage"]
		var g_r: Vector3 = rechts["groesse"]
		_farn_bei(sa, lage_r.translated_local(Vector3(g_r.x * 0.3, g_r.y * 0.5, 0.9)), 0,
				1018, 1.1)


## Fuß des Torbaums (Welt): oben auf der Felsnase, knapp in den Boden
## gesenkt. Die Höhe kommt aus dem gezeichneten Gelände bzw. der Krone der
## Felswand des Saums, je nachdem, was dort höher liegt.
static func _torbaum_fuss(level: Level01, stelle: Dictionary) -> Vector3:
	var s: float = stelle["s"]
	var q: float = stelle["q"]
	var p := _p(level, s, q, float(stelle["fuss"]))
	var boden := L01Gelaende.hoehe(p.x, p.z)
	var krone := float(level.rand_profil(s, signf(q)).get("krone_y", NAN))
	if not is_nan(krone):
		boden = maxf(boden, krone)
	if not is_nan(boden) and absf(boden - p.y) < 3.0:
		p.y = boden
	p.y -= 0.4
	return p


## Die linke Pfortenwand: ein Fels genau im Kasten, den drei Wurzeln des
## Torbaums umklammern. Sie kommen vom Stammfuß oben auf der Felsnase, laufen
## über die Felsmasse hinter der Leitlinie herab, liegen oben bündig im
## Moos, hängen an der Wegseite herab und kriechen als flache
## Oberflächenwurzeln auf den Weg.
static func _wurzelstock(sa: Sammler, level: Level01, e: Dictionary) -> void:
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	_findling_auf(sa, level, "Pforte links", {"saat": 1011, "eckig": 2.9,
			"rundung": 0.36, "beulen": 0.3, "unruhe": 0.14, "umriss": 0.1, "moos": 1.0,
			"moos_oben": 0.8, "ausgetreten": 0.0, "schichten": true, "anlauf": 0.1,
			"bemoost": Vector2(0.7, 0.6)}, 0.0)
	_randfarne(sa, level, "Pforte links", 2, 1019)
	# Der Torbaum in Kastenkoordinaten (lokal +X zeigt zum Weg).
	var stelle := _rahmenstelle("torbaum")
	var baum := Vector3(-4.8, boden + 4.2, 0.0)
	if not stelle.is_empty():
		baum = lage.affine_inverse() * _torbaum_fuss(level, stelle)
	var st := Riesenstamm.bauer()
	# [Versatz längs (z), Radius, Weg über Felsmasse und Stein]
	var zuege := [
		[0.1, 0.3, [Vector3(-3.3, 2.95, 0.3), Vector3(-2.1, 2.5, 0.25), Vector3(-1.2, 1.95, 0.15),
				Vector3(-0.55, 1.73, 0.1), Vector3(0.2, 1.74, -0.05), Vector3(0.66, 1.4, -0.2),
				Vector3(0.74, 0.5, -0.3), Vector3(0.8, boden + 0.2, -0.45),
				Vector3(1.4, boden + 0.02, -0.7), Vector3(2.2, boden - 0.25, -0.9)]],
		[1.25, 0.24, [Vector3(-3.2, 2.8, 1.5), Vector3(-2.0, 2.3, 1.7), Vector3(-1.1, 1.8, 1.8),
				Vector3(-0.3, 1.62, 1.92), Vector3(0.5, 1.2, 1.94), Vector3(0.75, 0.2, 1.9),
				Vector3(0.95, boden + 0.12, 2.1), Vector3(1.4, boden - 0.2, 2.5)]],
		[-1.3, 0.26, [Vector3(-3.2, 2.85, -1.4), Vector3(-2.0, 2.35, -1.6),
				Vector3(-1.0, 1.9, -1.7), Vector3(-0.1, 1.7, -1.75), Vector3(0.6, 1.1, -1.9),
				Vector3(0.72, -0.1, -1.8), Vector3(1.0, boden + 0.12, -1.9),
				Vector3(1.6, boden - 0.2, -2.1)]],
	]
	for i in zuege.size():
		var zug: Array = zuege[i]
		var r: float = zug[1]
		var punkte := PackedVector3Array([baum + Vector3(0.45, 0.5, float(zug[0]) * 0.35),
				baum + Vector3(1.0, 0.1, float(zug[0]) * 0.7)])
		for p: Vector3 in zug[2]:
			punkte.append(p)
		var radien := PackedFloat32Array()
		for k in punkte.size():
			var t := float(k) / float(punkte.size() - 1)
			radien.append(r * lerpf(1.7, 0.35, t) * (1.0 + 0.12 * sin(float(k) * 2.3 + float(i))))
		Totholzzaun.stueck(st, _glatt(punkte, 3), _glatt_r(radien, 3), {"saat": 1030 + i,
				"seiten": 8, "ende": "spitz", "moos": 0.5, "buckel": 0.14, "ton": KIEFER_TON,
				"ao": Vector2(0.75, 0.6)})
	# Feine Oberflächenwurzeln auf dem Weg (unter 0,3 m).
	var rng := PropWerkzeug.zufall(1036)
	for i in 3:
		var z := rng.randf_range(-1.6, 1.6)
		var zug := PackedVector3Array([Vector3(0.7, boden + 0.08, z),
				Vector3(1.1, boden + 0.1, z + rng.randf_range(-0.4, 0.4)),
				Vector3(1.6, boden + 0.04, z + rng.randf_range(-0.6, 0.6)),
				Vector3(2.0, boden - 0.08, z + rng.randf_range(-0.8, 0.8))])
		Totholzzaun.stueck(st, _glatt(zug, 2), _glatt_r(PackedFloat32Array(
				[0.13, 0.1, 0.07, 0.04]), 2), {"saat": 1037 + i, "seiten": 6, "ende": "spitz",
				"moos": 0.4, "ton": KIEFER_TON, "ao": Vector2(0.7, 0.8)})
	_holz(sa, _klemmen(Riesenstamm.fertig(st), h, boden, -1.0, 0.02), lage)
	_farn_bei(sa, lage.translated_local(Vector3(-0.45, h.y, -1.2)), 0, 1039, 1.0)


## Der Torbaum: eine große Kiefer auf der Felsnase am linken Pfortenpfosten
## (q −7,8, hinter der Leitlinie). Bis gut 10 m steigt der Stamm senkrecht,
## dann neigt sich sein Leittrieb in einem Bogen nach außen über den
## Hangwald; die Krone liegt als flacher Schirm 17–21 m über dem Weg. Am
## rechten Rand (q +7) stand er vom Grat aus (s 24–80) genau in der
## Sichtlinie zum Stamm des Weltenbaums (±5°, nachgerechnet) und verdeckte
## ihn mit Stamm und Krone; links liegt er 15–40° daneben, seine Krone nach
## außen noch weiter – und das Bild folgt der Regel „links zu, rechts
## offen". Aus der Spielkamera an der Pforte steht der Stamm links, die
## Krone über dem Bildrand. Drei Wurzeln greifen über den linken
## Pfortenstein (`_wurzelstock`), zwei Stränge führen vom linken Fuß des
## Pfortentors in den Stamm.
static func _torbaum(sa: Sammler, level: Level01, stelle: Dictionary) -> void:
	var s: float = stelle["s"]
	var fuss := _torbaum_fuss(level, stelle)
	# Lokal: X = quer (+q, zum Weg), Y hoch, −Z voraus. Außen ist −X.
	var lage := Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s)), fuss)
	# Felsfuß: ein Block, auf dessen Kuppe der Stamm steht, halb in der
	# Felsnase.
	_brocken(sa, Vector3(3.2, 2.6, 3.6), lage.translated_local(Vector3(0.5, -1.9, 0.0)),
			1031, 0.0, {"moos": 0.95, "kuppe": 0.35}, false)
	var h := 11.0
	# Unten 1,0 m stark, grau-braun; über 7 m die warme, rötliche Borke der
	# Kiefer (`_nach_hoehe_getoent`). Schlanker las sich der Baum vom Grat
	# aus als Akazie.
	var netz := Riesenstamm.netz({"hoehe": h, "radius": 1.0, "radius_oben": 0.6,
			"saat": 1032, "brettwurzeln": 6, "wurzel_reichweite": 1.7, "wurzel_hoehe": 2.0,
			"neigung": Vector2(-0.5, 0.15), "krumm": 0.12, "drehung": 0.35, "pilze": 1,
			"efeu": 1, "aeste": 0, "oben": "offen", "rippen": 12})
	_holz(sa, _nach_hoehe_getoent(netz, TORBAUM_TON_UNTEN, KIEFER_TON_OBEN, 6.0, 8.0), lage)
	var st := Riesenstamm.bauer()
	# Der Bogen nach außen, mit zwei Knicken wie ein Leittrieb, der nach
	# einem Bruch neu ausgetrieben ist – ein glatter Bogen las sich als
	# gebogenes Rohr.
	var bogen := PackedVector3Array([Vector3(-0.5, h - 1.2, 0.15), Vector3(-0.9, h + 1.0, 0.3),
			Vector3(-1.3, h + 2.3, 0.35), Vector3(-2.4, h + 3.3, 0.1), Vector3(-3.5, h + 4.4, -0.05),
			Vector3(-4.9, h + 5.3, -0.2), Vector3(-5.9, h + 5.9, -0.25), Vector3(-6.7, h + 6.1, -0.3)])
	var bogen_r := PackedFloat32Array([0.6, 0.54, 0.49, 0.43, 0.37, 0.3, 0.22, 0.14])
	Totholzzaun.stueck(st, _glatt(bogen, 3), _glatt_r(bogen_r, 3), {"saat": 1033,
			"seiten": 12, "ende": "spitz", "moos": 0.3, "drehung": 0.3, "buckel": 0.08,
			"ton": KIEFER_TON_OBEN, "ao": Vector2(1.0, 1.0)})
	# Die unteren Etagen: kurze Äste mit Nadelpolstern nach außen und quer,
	# gut 6–8 m über dem Fuß – die Krone reicht so über ein Drittel der Höhe
	# und stuft sich bis zum Schirm.
	var etagen := [
		[Vector3(-0.6, 6.2, 0.35), Vector3(-1.0, 0.16, 0.6), 2.6, 2.2],
		[Vector3(-0.7, 6.7, -0.3), Vector3(-1.0, 0.18, -0.65), 2.8, 2.3],
		[Vector3(-0.55, 7.3, 0.5), Vector3(-0.5, 0.22, 1.0), 2.2, 2.0],
		[Vector3(-0.55, 7.7, -0.45), Vector3(-0.55, 0.22, -1.0), 2.2, 2.0],
		[Vector3(-0.5, 8.3, 0.1), Vector3(-0.9, 0.3, 0.1), 2.0, 1.9],
	]
	_kiefernwipfel(sa, st, lage, etagen, 1060, false)
	# Der Schirm: Äste vom äußeren Bogen, weit nach vorn und hinten
	# ausladend – eine breite, flache Krone über dem Hangwald.
	var aeste := [
		[Vector3(-3.9, h + 4.6, -0.05), Vector3(0.1, 0.25, 1.0), 3.4, 2.6],
		[Vector3(-4.2, h + 4.8, -0.1), Vector3(-0.05, 0.22, -1.0), 3.6, 2.7],
		[Vector3(-4.8, h + 5.2, -0.15), Vector3(-0.35, 0.3, 1.0), 3.0, 2.5],
		[Vector3(-5.2, h + 5.4, -0.2), Vector3(-0.3, 0.2, -1.0), 2.9, 2.5],
		[Vector3(-5.9, h + 5.8, -0.25), Vector3(-1.0, 0.25, 0.55), 2.4, 2.4],
		[Vector3(-6.3, h + 5.95, -0.28), Vector3(-1.0, 0.25, -0.5), 2.3, 2.4],
		[Vector3(-6.7, h + 6.1, -0.3), Vector3(-1.0, 0.35, 0.0), 1.7, 2.3],
		[Vector3(-5.5, h + 5.6, -0.22), Vector3(-0.2, 1.0, 0.1), 1.2, 2.1],
		[Vector3(-4.6, h + 5.0, -0.12), Vector3(0.1, 1.0, -0.3), 1.1, 1.9],
	]
	# Ohne Nebenpolster: Die Krone sieht man nur von Weitem (vom Grat), und
	# jedes Polster kostet gut 400 Dreiecke, im Tiefenvorlauf doppelt.
	_kiefernwipfel(sa, st, lage, aeste, 1040, false)
	# Ein toter Nebentrieb am Knick und trockene Stummel am unteren Stamm.
	Totholzzaun.stueck(st, PackedVector3Array([Vector3(-0.3, h - 0.5, 0.1), Vector3(0.3, h + 1.0,
			-0.1), Vector3(0.7, h + 2.3, -0.3)]), PackedFloat32Array([0.16, 0.11, 0.05]),
			{"saat": 1069, "seiten": 6, "ende": "splitter", "moos": 0.3,
			"ton": Totholzzaun.RINDE_TON})
	for i in 4:
		var y := h * (0.35 + 0.12 * float(i))
		var w := float(i) * 2.1 + 0.4
		# Nur nach außen und quer: Zum Weg hin hängt nichts.
		var raus := Vector3(-absf(cos(w)), 0.15, -sin(w)).normalized()
		var start := Vector3(-0.5 * pow(y / h, 1.5), y, 0.0)
		Totholzzaun.stueck(st, PackedVector3Array([start, start + raus * 0.7,
				start + raus * 1.3 + Vector3.DOWN * 0.1]), PackedFloat32Array([0.09, 0.06, 0.035]),
				{"saat": 1070 + i, "seiten": 5, "ende": "splitter", "moos": 0.3,
				"ton": Totholzzaun.RINDE_TON})
	# Zwei Stränge vom linken Torfuß (q −5,2, gut 3 m über dem Weg) in den
	# Fuß des Stamms.
	var tor := _tor_daten("Pfortentor")
	var weite := float(tor.get("abstand", 4.4)) + 0.8
	for k in 2:
		var dz := -0.35 + 0.7 * float(k)
		var von := lage.affine_inverse() * _p(level, s + dz, -(weite - 0.2), 3.1 + 0.3 * float(k))
		var ziel := Vector3(0.6, 0.9 + 0.7 * float(k), dz * 0.5)
		var zug := PackedVector3Array([von, von.lerp(ziel, 0.5) + Vector3.UP * 0.25, ziel])
		Totholzzaun.stueck(st, _glatt(zug, 3), _glatt_r(PackedFloat32Array([0.3, 0.24, 0.2]), 3),
				{"saat": 1050 + k, "seiten": 7, "moos": 0.45, "ton": TORBAUM_TON_UNTEN})
	_holz(sa, Riesenstamm.fertig(st), lage)


## Kopie eines Netzes, nach Höhe getönt: bis `von` (lokal Y) mit `unten`,
## ab `bis` mit `oben`, dazwischen gemischt (RGB · Ton, A bleibt).
static func _nach_hoehe_getoent(netz: ArrayMesh, unten: Color, oben: Color, von: float,
		bis: float) -> ArrayMesh:
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var punkte: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in farben.size():
			var ton := unten.lerp(oben, smoothstep(von, bis, punkte[i].y))
			var c := farben[i]
			farben[i] = Color(c.r * ton.r, c.g * ton.g, c.b * ton.b, c.a)
		arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu


# ================================================================ D Bachwiese

static func _bachwiese(level: Level01) -> void:
	_kisten = level.kisten_orte()
	# Vom Grat aus 130 m und mehr entfernt: Dort zeichnete die Bachwiese
	# nur Punkte im Dunst.
	var sa := Sammler.new(_wurzel(level), "Bachwiese")
	sa.fern = 110.0
	_wurzeltor(sa, level, "Riesentor", 1621)
	# Trittsteine der Furt: Oberseite genau auf der Walze, nass unter der
	# Wasserlinie (Wasser y 6,0). Der Umriss springt nur NACH AUSSEN (bis
	# 13 %): Die ebene Oberseite reicht damit überall bis gut 1,1 m an den
	# Rand (Rundung 0,22, Anlauf 0,12), und der Rand der Kollision liegt auf
	# sichtbarem Fels – mit dem Umriss nach innen (Welle 6) stand die Figur
	# am Rand neben dem Stein über dem Wasser. Die Flanke läuft von unter der
	# Kante bis zum Grund 0,8 m aus (an der Wasserlinie gut 0,4 m):
	# gewachsener Fels mit Anlauf statt einer Trommel. Daneben je zwei kleine,
	# halb versunkene Brocken (Oberkante unter 6,6, außen neben der Spur) –
	# sie gehören zum Bach, nicht zum Weg.
	for i in 2:
		var name := "Furtstein %d" % (i + 1)
		var e := level.begehbar(name)
		if e.is_empty():
			continue
		var lage: Transform3D = e["lage"]
		var r := float(e["radius"])
		var wasser := 6.0 - lage.origin.y
		_stein(sa, Findling.scheibe(r, float(e["hoehe"]),
				{"saat": 1750 + name.length() + 7 * i, "wasser_y": wasser, "rundung": 0.22,
				"umriss": 0.0, "umriss_aussen": 0.13, "beulen": 0.1, "anlauf": 0.1,
				"fuss_aus": 0.8}), lage)
		_trabanten(sa, level, e, 1760 + 10 * i)
	# Farnbüsche am fernen Ufer, außerhalb der Spur (|q| 6,6–8,2): Sie
	# brechen die Linie der Böschung, aus dem Kanal wird ein Bach im Wald.
	# Am nahen Ufer keine – dort lagen die Wedel in der Spielkamera vor den
	# Trittsteinen (K8); die Rahmenfarne der Wiese rahmen diese Ecken.
	var ufer_rng := PropWerkzeug.zufall(1771)
	for stelle: Vector4 in [Vector4(183.6, -6.6, 0.85, 1.0), Vector4(183.4, 8.2, 0.7, 1.0)]:
		_farn_bei(sa, _lage(level, stelle.x, stelle.y, 0.0, ufer_rng.randf() * TAU),
				int(stelle.w), 1772 + int(stelle.y), stelle.z)
		if stelle.w > 0.5:
			_farn_bei(sa, _lage(level, stelle.x + ufer_rng.randf_range(0.3, 0.9),
					stelle.y + signf(stelle.y) * 0.9, 0.0, ufer_rng.randf() * TAU), 0,
					1776 + int(stelle.y), 1.3)
	_findlingsturm(sa, level)
	_wurzelknie(sa, level)
	sa.fertig()


## Zwei kleine Brocken neben einem Trittstein, außen (weg von der Wegmitte)
## und quer zur Laufrichtung: halb versunken, Oberkante 0,1–0,5 m über dem
## Wasser (6,0) – klar tiefer als der Stein (7,2), also kein Tritt. Sie
## liegen außerhalb der Bahnen, auf denen man springt (|q| ≥ 2,1).
static func _trabanten(sa: Sammler, level: Level01, e: Dictionary, saat: int) -> void:
	var s: float = e["s"]
	var q: float = e["q"]
	var r: float = e["radius"]
	var aussen := signf(q) if q != 0.0 else 1.0
	var rng := PropWerkzeug.zufall(saat)
	var stellen := [Vector2(s - r * 0.35, q + aussen * (r + 0.55)),
			Vector2(s + r * 0.55, q + aussen * (r + 0.95))]
	for k in stellen.size():
		var st: Vector2 = stellen[k]
		var groesse := Vector3(rng.randf_range(0.7, 1.1), rng.randf_range(0.8, 1.1),
				rng.randf_range(0.8, 1.3))
		var fuss := level.weg_punkt(st.x, st.y)
		# Oberkante 6,1–6,5: Der Brocken steht im Bachbett, der größte Teil
		# unter Wasser.
		var oben := rng.randf_range(6.1, 6.5)
		fuss.y = oben - groesse.y
		var dreh := Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis(Vector3.RIGHT, rng.randf_range(-0.25, 0.25))
		_brocken(sa, groesse, Transform3D(dreh, fuss), saat + k, 0.0,
				{"wasser_y": 6.0 - (fuss.y + groesse.y * 0.5), "moos": 0.8}, false)


## Der Findlingsturm (S2): ein hoher Stein bündig außen an der Kante, dahinter
## (jenseits der Leitlinie) eine Gruppe kleinerer Findlinge mit Farn.
static func _findlingsturm(sa: Sammler, level: Level01) -> void:
	var name := "Findlingsturm"
	var e := level.begehbar(name)
	if e.is_empty():
		return
	_findling_auf(sa, level, name, {"saat": 1891, "eckig": 2.6, "rundung": 0.24,
			"beulen": 0.3, "unruhe": 0.14, "umriss": 0.06, "moos": 1.0, "moos_oben": 0.6,
			"ausgetreten": 0.3, "schichten": true, "anlauf": 0.08,
			"bemoost": Vector2(0.7, 0.6)}, 0.0)
	var s: float = e["s"]
	_brocken(sa, Vector3(2.3, 3.0, 2.5), _lage(level, s + 0.5, 9.1, 0.0, 0.6), 1892, 0.3,
			{"moos": 1.0})
	_brocken(sa, Vector3(1.6, 1.6, 1.8), _lage(level, s - 2.0, 8.7, 0.0, 2.0), 1893, 0.25,
			{"moos": 1.0})
	_farn_bei(sa, _lage(level, s + 2.1, 8.2, 0.0, 0.2), 0, 1894, 2.0)
	_farn_bei(sa, _lage(level, s - 1.0, 8.0, 0.0, 1.9), 0, 1895, 1.5)
	_farn_bei(sa, _lage(level, s + 1.6, 6.3, 0.0, 0.9), 0, 1896, 1.1)


## Das Wurzelknie (S3): eine Wurzel des Weltenbaums wölbt sich aus dem
## Boden, oben flach und bemoost genau auf +2,4, und taucht wieder ein –
## unter dem Bogen ein Spalt, durch den Licht fällt. Dahinter ein zweiter
## Strang aus Richtung des Stamms, beide in den Kasten geklemmt.
static func _wurzelknie(sa: Sammler, level: Level01) -> void:
	var e := level.begehbar("Wurzelknie")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	# Der Bogen ist ein Bündel aus drei Strängen, die sich umeinander winden –
	# mit dunklen Spalten dazwischen liest er sich als Wurzel, nicht als Rohr.
	# Zusammen reicht es von der Oberkante bis 0,4 m über den Boden: Unter
	# dem Bogen bleibt ein Spalt, aber keiner, durch den man kriechen zu
	# können glaubt (die Figur kriecht 0,76 m hoch).
	var buendel_r := (h.y - boden - 0.4) * 0.5
	var mitte_y := h.y - buendel_r
	var bogen := PackedVector3Array([Vector3(-0.55, boden - 1.2, h.z + 0.7),
			Vector3(-0.32, boden + 0.35, h.z - 0.05), Vector3(-0.26, mitte_y, h.z - 0.75),
			Vector3(-0.22, mitte_y + 0.02, 0.0), Vector3(-0.26, mitte_y, -h.z + 0.75),
			Vector3(-0.32, boden + 0.35, -h.z + 0.05), Vector3(-0.6, boden - 1.2, -h.z - 0.7)])
	var linie := _glatt(bogen, 5)
	var sb := Riesenstamm.bauer()
	for strang in 3:
		var punkte := PackedVector3Array()
		var radien := PackedFloat32Array()
		for k in linie.size():
			var t := float(k) / float(linie.size() - 1)
			var vor := (linie[mini(k + 1, linie.size() - 1)] - linie[maxi(k - 1, 0)]).normalized()
			var normale := vor.cross(Vector3.RIGHT).normalized()
			var a := TAU * float(strang) / 3.0 + t * TAU * 1.1
			var weite := buendel_r * 0.46 * (0.75 + 0.25 * sin(t * PI))
			punkte.append(linie[k] + (Vector3.RIGHT * cos(a) + normale * sin(a)) * weite)
			radien.append(buendel_r * lerpf(0.5, 0.58, sin(t * PI)) * (0.92 + 0.08 * float(strang)))
		Totholzzaun.stueck(sb, punkte, radien, {"saat": 1911 + strang, "seiten": 10,
				"moos": 0.9, "buckel": 0.14, "ao": Vector2(0.55, 0.55),
				"ton": Color(1.0, 0.94, 0.86), "drehung": 0.2})
	var buendel := _klemmen(Riesenstamm.fertig(sb), h, boden, -1.0)
	_holz(sa, buendel, lage)
	_kranz(sa, _fussring(buendel, boden, 0.55), lage)
	var st := Riesenstamm.bauer()
	# Der zweite Strang von hinten (Richtung Stamm, hinter der Leitlinie)
	var zug := PackedVector3Array([Vector3(-3.6, boden - 0.8, 1.3), Vector3(-2.4, boden + 0.45, 0.9),
			Vector3(-1.3, boden + 1.25, 0.4), Vector3(-0.3, boden + 1.5, 0.1)])
	Totholzzaun.stueck(st, _glatt(zug, 3), _glatt_r(PackedFloat32Array([0.55, 0.5, 0.45, 0.4]), 3),
			{"saat": 1912, "seiten": 10, "moos": 0.7, "ao": Vector2(0.6, 0.9),
			"ton": Color(1.0, 0.94, 0.86)})
	# Oberflächenwurzeln an den Füßen (unter 0,3 m)
	var rng := PropWerkzeug.zufall(1915)
	for i in 4:
		var ende := 1.0 if i < 2 else -1.0
		var z0 := ende * (h.z - 0.2)
		var zug2 := PackedVector3Array([Vector3(0.2, boden + 0.1, z0),
				Vector3(0.8 + rng.randf_range(0.0, 0.4), boden + 0.08, z0 + ende * rng.randf_range(0.2, 0.6)),
				Vector3(1.4 + rng.randf_range(0.0, 0.5), boden - 0.05, z0 + ende * rng.randf_range(0.5, 1.1))])
		Totholzzaun.stueck(st, _glatt(zug2, 2), _glatt_r(PackedFloat32Array([0.14, 0.09, 0.04]), 2),
				{"saat": 1916 + i, "seiten": 6, "ende": "spitz", "moos": 0.5})
	_holz(sa, _klemmen(Riesenstamm.fertig(st), h, boden, -1.0), lage)
	_farn_bei(sa, lage.translated_local(Vector3(-1.3, boden, -1.9)), 1, 1913, 0.62)
	_farn_bei(sa, lage.translated_local(Vector3(-1.1, boden, 2.0)), 0, 1914, 1.5)
	# Leuchtpilze im Spalt unter dem Bogen
	var pilze := Riesenstamm.bauer()
	for k in 5:
		Riesenstamm.leuchtpilz_in(pilze, lage * Vector3(rng.randf_range(-0.5, 0.4), boden + 0.02,
				rng.randf_range(-0.6, 0.6)), rng.randf_range(0.04, 0.065), rng)
	_holz(sa, Riesenstamm.fertig(pilze), Transform3D.IDENTITY)
