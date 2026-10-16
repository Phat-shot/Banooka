extends RefCounted
class_name L01Boden
## Level 01, Modul „Boden": Wegdecke und Lückenlippen (Plan Abschnitt 8.1).
##
## WEGDECKE. `stoff()` liefert je Eintrag in `Level01.ABSCHNITTE` den Stoff
## aus `shaders/wegboden.gdshader`: eine ausgetretene Erdspur, die pendelt
## und in Rasen übergeht (Wegmaske, `scripts/wegmaske.gd`), kein Bordstein.
## Zwei Fassungen nach "stoff": "waldweg" (A–D: Erde und Rasen) und
## "wurzelruecken" (E/F: helle, abgetretene Borke, Moos an den Flanken).
## Einträge mit demselben Stoff teilen sich ein Netz, also kostet die ganze
## Decke zwei Zeichenaufrufe. Die Kronenlicht-Stärke ("kronenlicht" je
## Eintrag) steht deshalb nicht je Stoff, sondern als Stützstellen über die
## Strecke im Shader (`kronen_stellen`), mit drei Metern Übergang an jeder
## Naht; `kronenlicht_bei()` rechnet dasselbe auf der CPU.
##
## LÜCKENLIPPEN. An jeder Lippe von Erdspalt, Kerbe, Fallkerbe, Furt, G1 und
## G2 liegen zwei, drei Gruppen heller, gewölbter Kalksteine in der Spur, je
## ein großer mit ein, zwei kleinen (auf der Wurzel: helles Bruchholz), an
## beiden Ecken außerhalb der Spur sitzen
## warme Leuchtpilzgruppen. Je Lücke EIN Netz mit EINEM Stoff, ohne Schatten,
## sichtbar bis 60 m – so zeichnet der Boden samt Marken an jeder Stelle
## höchstens sechs Aufrufe: zwei Decken und höchstens vier Lippen in
## Reichweite (gezählt über alle Kamerastellen, ohne Sichtkegel; der nimmt
## meist noch eine weg). Die Marken tragen nichts: Steine und Späne liegen
## höchstens vier Zentimeter über der Decke, die Pilze stehen außerhalb der
## Spur, alles ohne Kollision, und nichts ragt über die Lippe hinaus
## (Findling-Regel: nur Gras darf überhängen).

const WEGBODEN := preload("res://shaders/wegboden.gdshader")

## Sichtweite der Lippenmarken.
const LIPPEN_SICHTWEITE := 60.0
## Übergang der Kronenlicht-Stärke an einer Naht (je Seite).
const KRONEN_UEBERGANG := 1.5

## Art der Marke in UV2.x (wie `Riesenstamm`: EIGEN 1, LEUCHT 2).
const STEIN := 0.0
const EIGEN := 1.0
const LEUCHT := 2.0
const HOLZ := 3.0
## So weit bleiben die Marken vor der Lippe (m).
const VOR := 0.02

static var _stoffe: Dictionary = {}
static var _lippen_shader: Shader = null


# ================================================================ Wegdecke

## Stoff der Wegdecke für einen Eintrag aus `Level01.ABSCHNITTE`. Geteilt –
## nie verändern.
static func stoff(level: Level01, abschnitt: Dictionary) -> Material:
	var art := String(abschnitt.get("stoff", "waldweg"))
	if art != "wurzelruecken":
		art = "waldweg"
	if _stoffe.has(art):
		return _stoffe[art]
	var m := ShaderMaterial.new()
	m.shader = WEGBODEN
	Wegmaske.einrichten(m)
	if art == "wurzelruecken":
		m.set_shader_parameter("wurzelruecken", true)
		m.set_shader_parameter("boden_farbe", Materialbibliothek.rinde().albedo_texture)
		m.set_shader_parameter("boden_normal", Materialbibliothek.rinde().normal_texture)
		# Die Erde des Waldwegs, für den Anfang der Wurzel
		m.set_shader_parameter("flanke", Materialbibliothek.waldweg().albedo_texture)
		m.set_shader_parameter("borke_ton", Color(1.0, 0.95, 0.86))
		m.set_shader_parameter("moos_ton", Color(1.06, 1.04, 0.78))
		m.set_shader_parameter("erde_bis", _wurzel_anfang(level))
	else:
		var weg := Materialbibliothek.waldweg()
		m.set_shader_parameter("boden_farbe", weg.albedo_texture)
		m.set_shader_parameter("boden_normal", weg.normal_texture)
	# Lücken für die krümeligen Lippen (siehe Shader): erdig, außer auf der
	# Wurzel (G1, G2), dort nur ein dunkles Band.
	var luecken := PackedVector3Array()
	for l: Dictionary in Level01.LUECKEN:
		var holz := String(level.abschnitt_bei(float(l["von"]) - 0.01).get("stoff", "")) \
				== "wurzelruecken"
		luecken.append(Vector3(float(l["von"]), float(l["bis"]), 0.0 if holz else 1.0))
	var anzahl := mini(luecken.size(), 8)
	luecken.resize(8)
	m.set_shader_parameter("luecken", luecken)
	m.set_shader_parameter("luecken_anzahl", anzahl)
	var stellen := kronen_stellen(level)
	var feld := stellen.duplicate()
	feld.resize(24)
	m.set_shader_parameter("kronen_stellen", feld)
	m.set_shader_parameter("kronen_anzahl", mini(stellen.size(), 24))
	_stoffe[art] = m
	return m


## Wo der Weg aus der Erde auf die Wurzel steigt: Anfang des ersten
## Wurzelrücken-Eintrags, dessen Vorgänger bündig anschließt (keine Lücke).
static func _wurzel_anfang(level: Level01) -> float:
	var vorher: Dictionary = {}
	for a: Dictionary in level.ABSCHNITTE:
		if String(a.get("stoff", "")) == "wurzelruecken":
			if not vorher.is_empty() and String(vorher.get("stoff", "")) != "wurzelruecken" \
					and absf(float(vorher["bis"]) - float(a["von"])) < 0.01:
				return float(a["von"])
			return -1000000.0
		vorher = a
	return -1000000.0


## Stützstellen (s, Stärke) der Kronenlicht-Stärke, stückweise linear:
## je Lauf gleicher Stärke zwei Stellen, 1,5 m innerhalb seiner Enden.
static func kronen_stellen(level: Level01) -> PackedVector2Array:
	var laeufe: Array[Vector3] = []   # (von, bis, stärke)
	for a: Dictionary in level.ABSCHNITTE:
		var k: float = a.get("kronenlicht", 0.0)
		var von: float = a["von"]
		var bis: float = a["bis"]
		if not laeufe.is_empty() and is_equal_approx(laeufe[-1].z, k):
			laeufe[-1].y = bis
		else:
			laeufe.append(Vector3(von, bis, k))
	var stellen := PackedVector2Array()
	for l: Vector3 in laeufe:
		var rand := minf(KRONEN_UEBERGANG, (l.y - l.x) * 0.25)
		stellen.append(Vector2(l.x + rand, l.z))
		stellen.append(Vector2(l.y - rand, l.z))
	return stellen


## Kronenlicht-Stärke an der Strecke `s`, wie der Shader sie rechnet.
static func kronenlicht_bei(level: Level01, s: float) -> float:
	var stellen := kronen_stellen(level)
	if stellen.is_empty():
		return 0.0
	var w := stellen[0].y
	for i in range(1, stellen.size()):
		var a := stellen[i - 1]
		var b := stellen[i]
		if s >= a.x:
			w = lerpf(a.y, b.y, clampf((s - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))
	return w


# ================================================================ Lippen

## Bauschritte (Lückenlippen), je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [{"text": "Steine an die Abbruchkanten", "tun": func() -> void:
		lippen_bauen(level)}]


## Baut die Marken aller Lücken unter `level.geometrie` und gibt den
## Sammelknoten zurück.
static func lippen_bauen(level: Level01) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Lueckenlippen"
	level.geometrie.add_child(wurzel)
	for luecke: Dictionary in Level01.LUECKEN:
		var netz := _luecke(level, luecke)
		if netz != null:
			wurzel.add_child(netz)
	return wurzel


## Die Marken einer Lücke als ein Netz: Steine an beiden Lippen, je zwei
## Pilzgruppen an den Ecken.
static func _luecke(level: Level01, luecke: Dictionary) -> MeshInstance3D:
	var von: float = luecke["von"]
	var bis: float = luecke["bis"]
	var davor := level.abschnitt_bei(von - 0.01)
	var danach := level.abschnitt_bei(bis + 0.01)
	if davor.is_empty() and danach.is_empty():
		return null
	var mitte := level.weg_punkt((von + bis) * 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(luecke["name"])) & 0x7fffffff
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var holz := String(davor.get("stoff", danach.get("stoff", ""))) == "wurzelruecken"
	for lippe: Array in [[davor, von, -1.0], [danach, bis, 1.0]]:
		var eintrag: Dictionary = lippe[0]
		if eintrag.is_empty():
			continue
		_lippe(st, level, eintrag, float(lippe[1]), float(lippe[2]), mitte, holz, rng)
	var netz := st.commit()
	if netz.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "Lippe_" + String(luecke["name"])
	mi.mesh = netz
	mi.position = mitte
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = LIPPEN_SICHTWEITE
	mi.visibility_range_end_margin = 4.0
	mi.material_override = _lippen_stoff(kronenlicht_bei(level, (von + bis) * 0.5))
	return mi


## Eine Lippe: `innen` = -1, wenn der feste Boden vor der Kante liegt (die
## Lippe am Anfang der Lücke), +1 dahinter.
static func _lippe(st: SurfaceTool, level: Level01, eintrag: Dictionary, s_lippe: float,
		innen: float, mitte: Vector3, holz: bool, rng: RandomNumberGenerator) -> void:
	var von: float = eintrag["von"]
	var bis: float = eintrag["bis"]
	var t := inverse_lerp(von, bis, s_lippe) if bis > von else 0.0
	var breite: float = eintrag["breite"]
	var halb := lerpf(breite, float(eintrag.get("breite_ende", breite)), clampf(t, 0.0, 1.0)) * 0.5
	var y := LevelWerkzeuge.eintrag_hoehe(level.verlauf, eintrag, s_lippe)
	var rahmen := {"level": level, "s": s_lippe, "innen": innen, "y": y, "mitte": mitte}
	# Die Steine liegen in der Spur und ein Stück darüber hinaus: dort, wo
	# man abspringt und landet – in zwei, drei GRUPPEN, je ein großer Stein
	# mit ein, zwei kleinen daneben, ungleich weit von der Kante. Gleichmäßig
	# quer über die Spur verteilt (Welle 6: vier bis sechs Steine in
	# gleichen Abständen) lasen sie sich als Bordstein, auch mit Zufall in
	# Größe und Abstand.
	var spur := Wegmaske.pendel(s_lippe) * halb
	var spur_halb := 0.66 * halb
	var links := maxf(spur - spur_halb, -halb + 0.45)
	var rechts := minf(spur + spur_halb, halb - 0.45)
	var gruppen := rng.randi_range(2, 3)
	var belegt: Array[Vector3] = []   # (a, q, Radius) der gelegten Steine
	for g in gruppen:
		var q_g := lerpf(links, rechts, (float(g) + rng.randf_range(0.25, 0.75)) / float(gruppen))
		var a_g := 0.0 if rng.randf() < 0.65 else rng.randf_range(0.1, 0.45)
		var zahl := rng.randi_range(1, 3)
		for k in zahl:
			var gross := k == 0
			var breite_q := rng.randf_range(0.5, 0.85) if gross else rng.randf_range(0.22, 0.4)
			var tiefe := breite_q * rng.randf_range(0.75, 1.15)
			var q := q_g
			var zurueck := a_g
			if not gross:
				var seite := -1.0 if rng.randf() < 0.5 else 1.0
				q = q_g + seite * rng.randf_range(0.35, 0.6)
				zurueck = a_g + rng.randf_range(0.0, 0.5)
			q = clampf(q, -halb + 0.4, halb - 0.4)
			var r_hier := maxf(breite_q, tiefe) * 0.5
			var mitte_a := VOR + zurueck + tiefe * 0.5
			var frei := true
			for b_ in belegt:
				if Vector2(b_.x - mitte_a, b_.y - q).length() < b_.z + r_hier + 0.04:
					frei = false
					break
			if not frei:
				continue
			belegt.append(Vector3(mitte_a, q, r_hier))
			if holz:
				_splitter(st, rahmen, q, breite_q, tiefe, zurueck, rng)
			else:
				_stein(st, rahmen, q, breite_q, tiefe, zurueck, rng)
	# Leuchtpilze an beiden Ecken, außerhalb der Spur im Rasen.
	for seite: float in [-1.0, 1.0]:
		var q_ecke := seite * (halb - rng.randf_range(0.35, 0.8))
		var zahl := rng.randi_range(3, 6)
		for i in zahl:
			var a := rng.randf_range(0.2, 1.3)
			var q := q_ecke - seite * rng.randf_range(0.0, 0.7) + rng.randf_range(-0.2, 0.2)
			q = clampf(q, -halb + 0.12, halb - 0.12)
			var ort := _ort(rahmen, a, q, 0.0)
			var kipp := Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))
			_pilz(st, ort, rng.randf_range(0.05, 0.1), kipp, rng)


## Ort im Netz: `a` Meter von der Lippe in den festen Boden, `q` quer,
## `h` über der Decke.
static func _ort(rahmen: Dictionary, a: float, q: float, h: float) -> Vector3:
	var level: Level01 = rahmen["level"]
	var s: float = float(rahmen["s"]) + float(rahmen["innen"]) * a
	var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
	p.y = float(rahmen["y"]) + h
	return p - (rahmen["mitte"] as Vector3)


## Ein Kalkstein in der Spur: eine Kuppe 8–14 cm über der Decke
## (`_kuppe`), gerade Stirn genau an der Lippe, Flanken 22 cm tief.
static func _stein(st: SurfaceTool, rahmen: Dictionary, q: float, breite_q: float,
		tiefe: float, zurueck: float, rng: RandomNumberGenerator) -> void:
	# Heller Kalk, aber kein Weiß: In der Sonne überstrahlte er sonst.
	# LINEAR (der Lippenstoff nimmt ALBEDO = COLOR.rgb): Als sRGB-Wert
	# gewählt (0,72/0,68/0,58) lagen die Steine als weiße Münzen in der Spur.
	# Welle 6: 0,40/0,37/0,30 las sich im Schatten der Kante dunkelgrau.
	var grund := Color(0.46, 0.43, 0.35).lerp(Color(0.40, 0.39, 0.32), rng.randf())
	grund *= rng.randf_range(0.9, 1.05)
	const N := 10
	var ra := tiefe * 0.5
	var rb := breite_q * 0.5
	var mitte2 := Vector2(VOR + zurueck + ra * rng.randf_range(0.85, 1.0), q)
	var umriss: Array[Vector2] = []
	for k in N:
		var w := TAU * float(k) / float(N) + rng.randf_range(-0.12, 0.12)
		var c := cos(w)
		var s_ := sin(w)
		# Superellipse (Exponent 2,4): ein Kiesel, der gelegt wurde, kein Ei
		var ca := signf(c) * pow(absf(c), 2.0 / 2.4)
		var sb := signf(s_) * pow(absf(s_), 2.0 / 2.4)
		var j := rng.randf_range(0.86, 1.06)
		umriss.append(Vector2(maxf(mitte2.x + ra * ca * j, VOR), q + rb * sb * j))
	# Gewölbt nach Größe: kleine Steine 8, große bis 14 cm.
	var hoehe := clampf(0.06 + 0.12 * minf(ra, rb), 0.08, 0.14) * rng.randf_range(0.9, 1.05)
	_kuppe(st, rahmen, umriss, mitte2, hoehe, grund, rng)


## Ein Kalkstein als Kuppe: `hoehe` über der Decke gewölbt, weiche Normalen
## (vier Ringe), der Fuß dunkel – dort steckt er im Boden, der Rand liest
## sich als Kontaktschatten. Flach (3 cm) und kantig schattiert lasen sich
## die Steine aus der Nähe als graue, aufgeklebte Vielecke. Die Flanke geht
## wie bei `_platte` 22 cm unter die Decke und nie über die Lippe.
static func _kuppe(st: SurfaceTool, rahmen: Dictionary, umriss: Array[Vector2],
		mitte2: Vector2, hoehe: float, grund: Color, rng: RandomNumberGenerator) -> void:
	var n_ := umriss.size()
	var r_mittel := 0.0
	for p in umriss:
		r_mittel += (p - mitte2).length()
	r_mittel = maxf(r_mittel / float(n_), 0.05)
	# Anteil des Radius und Höhe je Ring (Kopf, drei Ringe, Rand am Boden).
	var ringe := PackedFloat32Array([0.0, 0.4, 0.7, 0.9, 1.0])
	var hoehen := PackedFloat32Array([1.0, 0.9, 0.66, 0.34, 0.0])
	var toene := [grund * 1.12, grund * 1.05, grund * 0.95, grund * 0.72,
			(grund * 0.4).lerp(Color(0.05, 0.05, 0.025), 0.35)]
	var reihen: Array = []
	var normalen: Array = []
	var kopf := _ort(rahmen, mitte2.x, mitte2.y, hoehe + 0.008)
	for i in ringe.size():
		var reihe: Array[Vector3] = []
		var nreihe: Array[Vector3] = []
		for k in n_:
			var p := Vector2(maxf(umriss[k].x, VOR), umriss[k].y)
			var z := mitte2.lerp(p, ringe[i])
			var h := hoehe * hoehen[i] + 0.008 + (rng.randf_range(0.0, 0.006) if i == 4 else 0.0)
			var ort := _ort(rahmen, z.x, z.y, h) if i > 0 else kopf
			reihe.append(ort)
			var raus := ort - kopf
			raus.y = 0.0
			var steil := 0.0
			if i > 0:
				# Steigung der Kuppe am Ring (Ableitung der Höhen nach dem Radius)
				var dh := (hoehen[i - 1] - hoehen[mini(i + 1, 4)]) * hoehe
				var dr := (ringe[mini(i + 1, 4)] - ringe[i - 1]) * r_mittel
				steil = dh / maxf(dr, 0.01)
			var nn := Vector3.UP
			if raus.length_squared() > 1e-8:
				nn = (Vector3.UP + raus.normalized() * steil).normalized()
			nreihe.append(nn)
		reihen.append(reihe)
		normalen.append(nreihe)
	var fuss_ring: Array[Vector3] = []
	for k in n_:
		var p := Vector2(maxf(umriss[k].x, VOR), umriss[k].y)
		var fuss := mitte2.lerp(p, 0.92)
		fuss_ring.append(_ort(rahmen, maxf(fuss.x, VOR), fuss.y, -0.22))
	for i in range(ringe.size() - 1):
		var a: Array[Vector3] = reihen[i]
		var b: Array[Vector3] = reihen[i + 1]
		var na: Array[Vector3] = normalen[i]
		var nb: Array[Vector3] = normalen[i + 1]
		var fa: Color = toene[i]
		var fb: Color = toene[i + 1]
		for k in n_:
			var m := (k + 1) % n_
			_dreieck_n(st, a[k], b[k], b[m], na[k], nb[k], nb[m], fa, fb, fb, STEIN)
			_dreieck_n(st, a[k], b[m], a[m], na[k], nb[m], na[m], fa, fb, fa, STEIN)
	var rand: Array[Vector3] = reihen[ringe.size() - 1]
	var dunkel: Color = toene[ringe.size() - 1]
	for k in n_:
		var m := (k + 1) % n_
		var raus := (rand[k] + rand[m]) * 0.5 - kopf
		raus.y = 0.0
		if raus.length_squared() < 1e-8:
			continue
		var nr := raus.normalized()
		_dreieck(st, rand[k], fuss_ring[k], fuss_ring[m], raus, dunkel, dunkel * 0.8,
				dunkel * 0.8, STEIN, nr)
		_dreieck(st, rand[k], fuss_ring[m], rand[m], raus, dunkel, dunkel * 0.8, dunkel, STEIN,
				nr)


## Wie `_dreieck` mit einer Normale je Ecke (weiche Wölbung); Vorderseite
## nach oben.
static func _dreieck_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3,
		nb: Vector3, nc: Vector3, fa: Color, fb: Color, fc: Color, art: float) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var ecken: Array[Vector3] = [a, b, c]
	var farben: Array[Color] = [fa, fb, fc]
	var nn: Array[Vector3] = [na, nb, nc]
	if kreuz.dot(Vector3.UP) > 0.0:
		ecken = [a, c, b]
		farben = [fa, fc, fb]
		nn = [na, nc, nb]
	for i in 3:
		var p := ecken[i]
		var f := farben[i]
		st.set_color(Color(f.r, f.g, f.b, 0.0))
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 3.0)
		st.set_uv2(Vector2(art, 0.0))
		st.set_normal(nn[i])
		st.add_vertex(p)


## Helles Bruchholz an einer Wurzellippe: zwei, drei schmale Späne längs der
## Strecke – die Fasern einer Wurzel laufen mit ihr –, spitz zur Bruchkante.
static func _splitter(st: SurfaceTool, rahmen: Dictionary, q: float, breite_q: float,
		tiefe: float, zurueck: float, rng: RandomNumberGenerator) -> void:
	var zahl := rng.randi_range(2, 3)
	var teil := breite_q / float(zahl)
	for i in zahl:
		# Warm und satt (linear): blasses Holz wurde im Schatten blaugrau.
		var grund := Color(0.46, 0.30, 0.14).lerp(Color(0.40, 0.27, 0.15), rng.randf())
		grund *= rng.randf_range(0.88, 1.04)
		var b := teil * rng.randf_range(0.34, 0.46)
		var qm := q - breite_q * 0.5 + teil * (float(i) + 0.5) + rng.randf_range(-0.05, 0.05) * teil
		var lang := tiefe * rng.randf_range(0.9, 1.5)
		var a0 := VOR + zurueck * 0.5 + rng.randf_range(0.0, 0.1)
		var spitze := qm + rng.randf_range(-0.4, 0.4) * b
		# Spitze an der Kante, breiteste Stelle bei einem Viertel, hinten
		# stumpf und leicht schief abgebrochen
		var umriss: Array[Vector2] = [
			Vector2(a0, spitze),
			Vector2(a0 + lang * 0.25, qm + b),
			Vector2(a0 + lang * 0.7, qm + b * 0.8),
			Vector2(a0 + lang * rng.randf_range(0.95, 1.05), qm + b * 0.35),
			Vector2(a0 + lang * rng.randf_range(0.9, 1.0), qm - b * 0.45),
			Vector2(a0 + lang * 0.6, qm - b * 0.85),
			Vector2(a0 + lang * 0.2, qm - b),
		]
		var mitte2 := Vector2(a0 + lang * 0.5, qm)
		_platte(st, rahmen, umriss, mitte2, 0.022, grund, HOLZ, rng)


## Flache Platte nach einem Umriss (Punkte als Vector2(a, q), `a` von der
## Lippe in den festen Boden, im Uhrzeigersinn oder dagegen): Mitte,
## innerer und äußerer Ring oben, dazu die Flanken bis 22 cm unter die
## Decke. Kein Punkt liegt näher als `VOR` an der Kante – die Marken ragen
## nie über die Kollision hinaus.
static func _platte(st: SurfaceTool, rahmen: Dictionary, umriss: Array[Vector2],
		mitte2: Vector2, woelbung: float, grund: Color, art: float,
		rng: RandomNumberGenerator) -> void:
	var n_ := umriss.size()
	var hell := grund * 1.06
	# Der Rand dunkel und erdig-moosig: Der Stein liegt IM Boden. Ein Ring
	# daneben las sich auf der hellen Spur als schwarzer Umriss.
	var rand_farbe := (grund * 0.8).lerp(Color(0.07, 0.075, 0.035), 0.3 if art == STEIN else 0.0)
	var flanke := grund * 0.58
	var kopf := _ort(rahmen, mitte2.x, mitte2.y, woelbung + 0.008)
	var innen_ring: Array[Vector3] = []
	var aussen_ring: Array[Vector3] = []
	var fuss_ring: Array[Vector3] = []
	for k in n_:
		var p := Vector2(maxf(umriss[k].x, VOR), umriss[k].y)
		var zwischen := mitte2.lerp(p, 0.62)
		innen_ring.append(_ort(rahmen, zwischen.x, zwischen.y, woelbung * 0.75 + 0.008))
		aussen_ring.append(_ort(rahmen, p.x, p.y, 0.008 + rng.randf_range(0.0, 0.006)))
		# Die Flanke zieht leicht nach innen, damit sie nie über die Lippe ragt.
		var fuss := mitte2.lerp(p, 0.92)
		fuss_ring.append(_ort(rahmen, maxf(fuss.x, VOR), fuss.y, -0.22))
	var oben := Vector3.UP
	for k in n_:
		var n := (k + 1) % n_
		var raus := (aussen_ring[k] + aussen_ring[n]) * 0.5 - kopf
		raus.y = 0.0
		if raus.length_squared() < 1e-8:
			continue
		var neigung := (oben + raus.normalized() * 0.18).normalized()
		_dreieck(st, kopf, innen_ring[k], innen_ring[n], oben, hell, grund, grund, art, oben)
		_dreieck(st, innen_ring[k], aussen_ring[k], aussen_ring[n], oben, grund, rand_farbe,
				rand_farbe, art, neigung)
		_dreieck(st, innen_ring[k], aussen_ring[n], innen_ring[n], oben, grund, rand_farbe,
				grund, art, neigung)
		_dreieck(st, aussen_ring[k], fuss_ring[k], fuss_ring[n], raus, rand_farbe, flanke,
				flanke, art, raus.normalized())
		_dreieck(st, aussen_ring[k], fuss_ring[n], aussen_ring[n], raus, rand_farbe, flanke,
				rand_farbe, art, raus.normalized())


## Ein gedrungener Leuchtpilz: kurzer, blasser Stiel, flacher Hut, der oben
## warm leuchtet (UV2.x = LEUCHT), die Lamellen darunter glimmen schwächer.
## `neigung` kippt ihn aus der Gruppe heraus. Gedrungener als
## `Riesenstamm.leuchtpilz_in` – dessen Stiele lasen sich aus der Nähe der
## Kamera als Streichhölzer.
static func _pilz(st: SurfaceTool, ort: Vector3, hut: float, neigung: Vector3,
		rng: RandomNumberGenerator) -> void:
	const N := 7
	var achse := (Vector3.UP + neigung).normalized()
	var a := achse.cross(Vector3.RIGHT)
	if a.length_squared() < 0.01:
		a = achse.cross(Vector3.FORWARD)
	a = a.normalized()
	var b := achse.cross(a).normalized()
	var stiel_h := hut * rng.randf_range(0.8, 1.3)
	var fuss := ort - achse * 0.05
	var kopf := ort + achse * stiel_h
	var stiel := Color(0.6, 0.54, 0.37)
	var glut := Color(1.0, 0.56, 0.2).lerp(Color(1.0, 0.72, 0.3), rng.randf())
	var drehung := rng.randf() * TAU
	for k in N:
		var w0 := drehung + TAU * float(k) / float(N)
		var w1 := drehung + TAU * float(k + 1) / float(N)
		var d0 := a * cos(w0) + b * sin(w0)
		var d1 := a * cos(w1) + b * sin(w1)
		var raus := d0 + d1
		# Stiel
		var s0 := fuss + d0 * hut * 0.3
		var s1 := fuss + d1 * hut * 0.3
		var t0 := kopf + d0 * hut * 0.24
		var t1 := kopf + d1 * hut * 0.24
		_dreieck(st, s0, t0, t1, raus, stiel * 0.6, stiel, stiel, EIGEN, raus.normalized())
		_dreieck(st, s0, t1, s1, raus, stiel * 0.6, stiel, stiel * 0.6, EIGEN, raus.normalized())
		# Hut: flache Kuppe mit Rand und Unterseite
		var r0 := kopf + d0 * hut - achse * hut * 0.12
		var r1 := kopf + d1 * hut - achse * hut * 0.12
		var m0 := kopf + d0 * hut * 0.6 + achse * hut * 0.32
		var m1 := kopf + d1 * hut * 0.6 + achse * hut * 0.32
		var kuppe := kopf + achse * hut * 0.48
		_dreieck(st, kuppe, m0, m1, achse, glut, glut, glut, LEUCHT, achse)
		_dreieck(st, m0, r0, r1, achse + raus, glut, glut * 0.85, glut * 0.85, LEUCHT,
				(achse + raus.normalized()).normalized())
		_dreieck(st, m0, r1, m1, achse + raus, glut, glut * 0.85, glut, LEUCHT,
				(achse + raus.normalized()).normalized())
		_dreieck(st, kopf, r1, r0, -achse, glut * 0.4, glut * 0.55, glut * 0.55, LEUCHT, -achse)


## Ein Dreieck mit Farbe je Ecke; Vorderseite nach `aussen` (Godot zeichnet
## im Uhrzeigersinn als Vorderseite, siehe `Riesenstamm._tri`), gemeinsame
## Normale `normale`. Farbe, UV, UV2 (Art) und Normale an jeder Ecke.
static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color, art: float, normale: Vector3) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var ecken: Array[Vector3] = [a, b, c]
	var farben: Array[Color] = [fa, fb, fc]
	if kreuz.dot(aussen) > 0.0:
		ecken = [a, c, b]
		farben = [fa, fc, fb]
	for i in 3:
		var p := ecken[i]
		var f := farben[i]
		st.set_color(Color(f.r, f.g, f.b, 0.0))
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 3.0)
		st.set_uv2(Vector2(art, 0.0))
		st.set_normal(normale)
		st.add_vertex(p)


## Stoff der Lippenmarken: Scheitelfarbe mit Korn aus der Erdtextur,
## Kronenlicht wie die Decke, Leuchtpilze (UV2.x = 2) leuchten warm.
static func _lippen_stoff(kronen: float) -> ShaderMaterial:
	if _lippen_shader == null:
		_lippen_shader = Shader.new()
		_lippen_shader.code = LIPPEN_SHADER
	var m := ShaderMaterial.new()
	m.shader = _lippen_shader
	Wegmaske.einrichten(m)
	m.set_shader_parameter("korn", Materialbibliothek.waldweg().albedo_texture)
	m.set_shader_parameter("kronen_staerke", kronen)
	return m


const LIPPEN_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

#include "res://shaders/wald_gemeinsam.gdshaderinc"

uniform sampler2D korn : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float kronen_staerke = 0.0;

varying vec3 v_welt;

void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float art = UV2.x;
	float leucht = step(1.5, art) * (1.0 - step(2.5, art));
	float eigen = step(0.5, art) * (1.0 - step(1.5, art));
	float holz = step(2.5, art);
	// Korn: Kalk grob gesprenkelt, Holz längs gefasert.
	vec2 kuv = v_welt.xz * mix(1.3, 0.6, holz) + vec2(v_welt.y * 0.8);
	kuv.x *= mix(1.0, 5.0, holz);
	float k = dot(texture(korn, kuv).rgb, vec3(0.3, 0.59, 0.11));
	float grob = mix(0.6 + 0.8 * k, 1.0, eigen + leucht);
	vec3 c = COLOR.rgb * grob;
	float licht = kronenlicht(v_welt.xz, TIME);
	// Leuchtende Hüte: wenig Albedo, das Licht kommt aus der Emission. Mit
	// voller Albedo in der Sonne plus Emission kippte ACES sie ins Weiße.
	ALBEDO = c * kronen_faktor(licht, kronen_staerke, 0.4) * mix(1.0, 0.45, leucht);
	EMISSION = COLOR.rgb * vec3(1.0, 0.8, 0.6) * 1.1 * leucht;
	ROUGHNESS = mix(0.82, 0.6, eigen + leucht);
	SPECULAR = 0.3;
}
"""
