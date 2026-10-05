extends Node
## Baukastenprobe: Rechnen die Bausteine für Raum 1 (`scripts/gemeinsam/`)
## mit den Daten von Level 01 genau dasselbe wie die Originale in Level 01?
## (Plan `baukasten.md` §1.7.)
##
##   godot --headless --path <Kopie> res://werkzeuge/Baukastenprobe.tscn
##
## WARUM. Die Bausteine sind KOPIEN aus `level01.gd` und seinen Modulen,
## verallgemeinert (Stufe A der Technikkarte): Level 01 bleibt wörtlich, wie
## es ist. Ob die Kopie dabei etwas verändert hat, zeigt kein Bild – Level
## 01 benutzt sie ja nicht. Diese Probe füttert jeden Baustein mit den
## Konstanten von Level 01 und vergleicht mit dem Original. Erwartet wird
## Gleitkomma-GLEICHHEIT (`==`, keine Toleranz; NAN gleich NAN): Derselbe
## Rechenweg auf denselben Zahlen liefert dieselben Bits. Jede Abweichung
## ist eine echte Änderung am Rechenweg.
##
## Level 01 wird dafür nicht gebaut: Ein `Level01`, das nie in den Baum
## kommt, läuft kein `_ready`; `_verlauf_anlegen()` legt nur die Kurve an,
## und alle Abfragen rechnen allein auf Kurve und Konstanten. Die Bauteile
## (Decke, Leitlinien, Schultern, Todeszonen) baut die Probe in einen
## eigenen, freien Knoten und vergleicht Knoten für Knoten.
##
## TEILE (je Paket einer, Plan §2):
##   Wegdaten (G1)  Abfragen alle 0,5 m von −8 bis 300: abschnitt_bei,
##                  breite_bei, ist_luecke, boden_bei, strang_bei, rand_bei,
##                  weg_von_der_kante, Wegrand, Kanten vor/nach, weg_punkt,
##                  rand_profil links und rechts; Begehbares (Lage,
##                  Querschnitte, Oberkanten, Kollisionsformen); Lücken und
##                  Sprungfälle; Rohbau (Decke samt Netzen und Stufen,
##                  Leitlinien, Schultern, Todeszonen).
##
## Ausgabe: je Prüfung eine Zeile mit der Zahl der Vergleiche, die ersten
## Abweichungen im Wortlaut, am Ende
##   === Baukastenprobe: <n> Vergleiche, <m> Abweichungen ===
## Rückgabe 1, sobald eine Abweichung da ist.

## Abstand der Probestellen und ihr Bereich (Level 01 läuft von −7,5 bis 287,3).
const SCHRITT := 0.5
const VON := -8.0
const BIS := 300.0
## So viele Abweichungen werden je Prüfung im Wortlaut gezeigt.
const ZEIGEN := 8

var _vergleiche := 0
var _abweichungen := 0
## Zähler der laufenden Prüfung (für ihre Zeile).
var _teil_vergleiche := 0
var _teil_abweichungen := 0


func _ready() -> void:
	print("=== Baukastenprobe ===")
	_teil_wegdaten()
	print("=== Baukastenprobe: %d Vergleiche, %d Abweichungen ===" % [_vergleiche, _abweichungen])
	get_tree().quit(1 if _abweichungen > 0 else 0)


# ============================================================ Wegdaten (G1)

func _teil_wegdaten() -> void:
	print("--- Wegdaten gegen Level01 ---")
	var l01 := Level01.new()
	l01.call("_verlauf_anlegen")
	var weg := Wegdaten.new(l01.verlauf, {
		"abschnitte": Level01.ABSCHNITTE, "begehbares": Level01.BEGEHBARES,
		"leitlinien": Level01.LEITLINIEN, "todeszonen": Level01.TODESZONEN,
		"raender": Level01.RAENDER,
	})

	# --- Abfragen alle 0,5 m ---
	_anfang()
	var stellen := 0
	var s := VON
	while s <= BIS + 0.001:
		stellen += 1
		var wo := "s %.1f" % s
		_pruefe("abschnitt_bei " + wo, l01.abschnitt_bei(s), weg.abschnitt_bei(s))
		_pruefe("breite_bei " + wo, l01.breite_bei(s), weg.breite_bei(s))
		_pruefe("ist_luecke " + wo, l01.ist_luecke(s), weg.ist_luecke(s))
		_pruefe("boden_bei " + wo, l01.boden_bei(s), weg.boden_bei(s))
		_pruefe("strang_bei " + wo, l01.strang_bei(s), weg.strang_bei(s))
		_pruefe("rand_bei " + wo, l01.rand_bei(s), weg.rand_bei(s))
		_pruefe("rand_bei 2,0 " + wo, l01.rand_bei(s, 2.0), weg.rand_bei(s, 2.0))
		_pruefe("weg_von_der_kante " + wo, l01.weg_von_der_kante(s, 2.5),
				weg.weg_von_der_kante(s, 2.5))
		_pruefe("Wegrand " + wo, l01.call("_wegrand", s), weg.wegrand(s))
		_pruefe("Kante vor " + wo, l01.call("_kante_vor", s), weg.kante_vor(s))
		_pruefe("Kante nach " + wo, l01.call("_kante_nach", s), weg.kante_nach(s))
		for q: float in [-3.0, 0.0, 2.5]:
			_pruefe("weg_punkt q %.1f %s" % [q, wo], l01.weg_punkt(s, q, 0.9),
					weg.weg_punkt(s, q, 0.9))
		for seite: float in [-1.0, 1.0]:
			_pruefe("rand_profil %+.0f %s" % [seite, wo], l01.rand_profil(s, seite),
					weg.rand_profil(s, seite))
		s += SCHRITT
	_zeile("Abfragen an %d Stellen je %.1f m (%.1f … %.1f)" % [stellen, SCHRITT, VON, BIS])

	# --- Begehbares: Lage, Querschnitte, Oberkanten ---
	_anfang()
	var proben := 0
	for roh: Dictionary in Level01.BEGEHBARES:
		var name := String(roh["name"])
		_pruefe("begehbar " + name, l01.begehbar(name), weg.begehbar(name))
		for p: Vector2 in _oberkanten_stellen(roh):
			proben += 1
			_pruefe("oberkante %s s %.2f q %.2f" % [name, p.x, p.y],
					l01.oberkante(name, p.x, p.y), weg.oberkante(name, p.x, p.y))
	_pruefe("begehbar unbekannt", l01.begehbar("gibt es nicht"), weg.begehbar("gibt es nicht"))
	_zeile("Begehbares: %d Einträge, %d Oberkanten" % [Level01.BEGEHBARES.size(), proben])

	# --- Lücken und Sprungfälle ---
	_anfang()
	var luecken := weg.luecken()
	_pruefe("Zahl der Lücken", Level01.LUECKEN.size(), luecken.size())
	for i in mini(luecken.size(), Level01.LUECKEN.size()):
		var l: Dictionary = Level01.LUECKEN[i]
		_pruefe("Lücke " + String(l["name"]), Vector2(float(l["von"]), float(l["bis"])),
				luecken[i])
	var bahnen: Array[float] = [0.0, 2.4]
	var eigene := weg.sprungfaelle_aus_luecken(Level01.LANDUNG_SPIEL, bahnen)
	var gefunden := 0
	for fall: Dictionary in l01.sprungfaelle():
		var name := String(fall["name"])
		if name == "Mooslog" or name.begins_with("Furt"):
			continue
		var start: Vector2 = fall["start"]
		var passend: Dictionary = {}
		for e: Dictionary in eigene:
			if float(e["kante"]) == float(fall["kante"]) \
					and (e["start"] as Vector2).y == start.y:
				passend = e
		if passend.is_empty():
			_abweichung("Sprungfall %s fehlt in sprungfaelle_aus_luecken" % name)
			continue
		gefunden += 1
		for schluessel: String in ["start", "kante", "von", "landung"]:
			_pruefe("Sprungfall %s %s" % [name, schluessel], fall[schluessel],
					passend[schluessel])
	_zeile("Lücken %d, Sprungfälle über Lücken %d" % [luecken.size(), gefunden])

	# --- Rohbau ---
	var alt := Node3D.new()
	l01.add_child(alt)
	l01.geometrie = alt
	var neu := Node3D.new()

	_anfang()
	l01.call("_weg_bauen")
	var decke := weg.decke_bauen(neu, func(a: Dictionary) -> Material:
		return L01Boden.stoff(l01, a))
	_baum_pruefe("Decke", alt.get_children(), decke.get_children())
	_zeile("Decke: %d Knoten (Netze je Stoff, Kollision, Stufen)" % _zaehle(decke))

	for teil: Array in [["Leitlinien", "_leitlinien_bauen", weg.leitlinien_bauen],
			["Schultern", "_schultern_bauen", weg.schultern_bauen],
			["Todeszonen", "_gefahren_setzen", weg.todeszonen_bauen]]:
		_anfang()
		var vorher := alt.get_child_count()
		l01.call(String(teil[1]))
		var original: Array[Node] = []
		for i in range(vorher, alt.get_child_count()):
			original.append(alt.get_child(i))
		var gebaut: Node3D = (teil[2] as Callable).call(neu)
		var kopie: Array[Node] = [gebaut]
		_baum_pruefe(String(teil[0]), original, kopie)
		_zeile("%s: %d Knoten" % [String(teil[0]), _zaehle(gebaut)])

	# Begehbares: Die Optik von Level 01 baut sich aus seinen Modulen (mit
	# Zwischenspeichern und Modellen) – verglichen werden deshalb Lage und
	# Kollisionsformen, die Optik ist bei Wegdaten ein Platzhalter.
	_anfang()
	var koerper_neu := weg.begehbares_bauen(neu, Callable())
	var i_koerper := 0
	for roh: Dictionary in Level01.BEGEHBARES:
		var name := String(roh["name"])
		var e := l01.begehbar(name)
		var formen_alt: Array[CollisionShape3D] = l01.call("_formen", e)
		var k := koerper_neu.get_child(i_koerper) as StaticBody3D
		i_koerper += 1
		if k == null:
			_abweichung("Begehbares %s: kein Körper" % name)
			continue
		_pruefe("Begehbares %s Name" % name, name, String(k.name))
		_pruefe("Begehbares %s Lage" % name, e["lage"], k.transform)
		_pruefe("Begehbares %s Ebene" % name, int(e["ebene"]), k.collision_layer)
		var formen_neu: Array[Node] = []
		for kind in k.get_children():
			if kind is CollisionShape3D:
				formen_neu.append(kind)
		var alt_knoten: Array[Node] = []
		alt_knoten.assign(formen_alt)
		_baum_pruefe("Begehbares " + name, alt_knoten, formen_neu)
		for f in formen_alt:
			f.free()
	_zeile("Begehbares: %d Körper (Lage, Ebene, Formen)" % i_koerper)

	neu.free()
	l01.free()


## Stellen (s, q), an denen die Oberkante eines Begehbaren verglichen wird:
## bei Körpern um die Mitte, bei Streifen und Sweeps über ihre ganze Länge
## und quer über den Weg hinaus.
func _oberkanten_stellen(e: Dictionary) -> Array[Vector2]:
	var liste: Array[Vector2] = []
	match String(e["form"]):
		"kasten", "zylinder", "kapsel":
			var s: float = e["s"]
			var q: float = e["q"]
			for ds: float in [-1.0, 0.0, 1.0]:
				for dq: float in [-0.5, 0.0, 0.5]:
					liste.append(Vector2(s + ds, q + dq))
		_:
			var s: float = e["von"]
			while s <= float(e["bis"]) + 0.001:
				for q: float in [-12.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 12.0]:
					liste.append(Vector2(s, q))
				s += SCHRITT
	return liste


# ============================================================ Vergleich

func _anfang() -> void:
	_teil_vergleiche = 0
	_teil_abweichungen = 0


func _zeile(was: String) -> void:
	print("  %-60s %6d Vergleiche, %d Abweichungen" % [was, _teil_vergleiche,
			_teil_abweichungen])


func _pruefe(was: String, original: Variant, kopie: Variant) -> void:
	_vergleiche += 1
	_teil_vergleiche += 1
	if _gleich(original, kopie):
		return
	_abweichung("%s: Level01 %s, Kopie %s" % [was, _kurz(original), _kurz(kopie)])


func _abweichung(text: String) -> void:
	_abweichungen += 1
	_teil_abweichungen += 1
	if _teil_abweichungen <= ZEIGEN:
		print("  ABWEICHUNG  " + text)


func _kurz(wert: Variant) -> String:
	var text := str(wert)
	return text if text.length() <= 160 else text.substr(0, 160) + " …"


## Gleichheit bis aufs Bit, NAN gleich NAN, Wörterbücher und Listen
## rekursiv. Objekte (Stoffe) müssen dasselbe Objekt sein.
func _gleich(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			var x: float = a
			var y: float = b
			return x == y or (is_nan(x) and is_nan(y))
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			if da.size() != db.size():
				return false
			for k: Variant in da:
				if not db.has(k) or not _gleich(da[k], db[k]):
					return false
			return true
		TYPE_ARRAY:
			var la: Array = a
			var lb: Array = b
			if la.size() != lb.size():
				return false
			for i in la.size():
				if not _gleich(la[i], lb[i]):
					return false
			return true
	return a == b


## Vergleicht zwei Knotenlisten Knoten für Knoten samt allen Kindern: Klasse,
## Lage, Ebenen, Gruppen, Formen (Maße, Punkte, Flächen) und Netze (alle
## Flächenfelder, Stoff, Schatten). Namen nur, wo sie lesbar gesetzt sind.
func _baum_pruefe(was: String, alt: Array[Node], neu: Array[Node]) -> void:
	_pruefe(was + " Zahl der Knoten", alt.size(), neu.size())
	for i in mini(alt.size(), neu.size()):
		_knoten_pruefe("%s/%d" % [was, i], alt[i], neu[i])


func _knoten_pruefe(pfad: String, a: Node, b: Node) -> void:
	_pruefe(pfad + " Klasse", a.get_class(), b.get_class())
	if a is Node3D and b is Node3D:
		_pruefe(pfad + " Lage", (a as Node3D).transform, (b as Node3D).transform)
		_pruefe(pfad + " sichtbar", (a as Node3D).visible, (b as Node3D).visible)
	if a is CollisionObject3D and b is CollisionObject3D:
		_pruefe(pfad + " Ebene", (a as CollisionObject3D).collision_layer,
				(b as CollisionObject3D).collision_layer)
		_pruefe(pfad + " Maske", (a as CollisionObject3D).collision_mask,
				(b as CollisionObject3D).collision_mask)
		_pruefe(pfad + " Gruppe todeszonen", a.is_in_group("todeszonen"),
				b.is_in_group("todeszonen"))
	if a is CollisionShape3D and b is CollisionShape3D:
		_form_pruefe(pfad, (a as CollisionShape3D).shape, (b as CollisionShape3D).shape)
	if a is MeshInstance3D and b is MeshInstance3D:
		var ma := a as MeshInstance3D
		var mb := b as MeshInstance3D
		_pruefe(pfad + " Stoff", ma.material_override, mb.material_override)
		_pruefe(pfad + " Schatten", ma.cast_shadow, mb.cast_shadow)
		_pruefe(pfad + " Flächen", ma.mesh.get_surface_count(), mb.mesh.get_surface_count())
		for f in mini(ma.mesh.get_surface_count(), mb.mesh.get_surface_count()):
			_pruefe("%s Fläche %d" % [pfad, f], ma.mesh.surface_get_arrays(f),
					mb.mesh.surface_get_arrays(f))
	var lesbar_a := not String(a.name).begins_with("@")
	var lesbar_b := not String(b.name).begins_with("@")
	if lesbar_a and lesbar_b:
		_pruefe(pfad + " Name", String(a.name), String(b.name))
	_pruefe(pfad + " Kinder", a.get_child_count(), b.get_child_count())
	for i in mini(a.get_child_count(), b.get_child_count()):
		_knoten_pruefe("%s/%d" % [pfad, i], a.get_child(i), b.get_child(i))


func _form_pruefe(pfad: String, a: Shape3D, b: Shape3D) -> void:
	if a == null or b == null:
		_pruefe(pfad + " Form vorhanden", a != null, b != null)
		return
	_pruefe(pfad + " Formklasse", a.get_class(), b.get_class())
	if a is BoxShape3D and b is BoxShape3D:
		_pruefe(pfad + " Kasten", (a as BoxShape3D).size, (b as BoxShape3D).size)
	elif a is ConvexPolygonShape3D and b is ConvexPolygonShape3D:
		_pruefe(pfad + " Punkte", (a as ConvexPolygonShape3D).points,
				(b as ConvexPolygonShape3D).points)
	elif a is ConcavePolygonShape3D and b is ConcavePolygonShape3D:
		_pruefe(pfad + " Dreiecke", (a as ConcavePolygonShape3D).get_faces(),
				(b as ConcavePolygonShape3D).get_faces())
	elif a is CylinderShape3D and b is CylinderShape3D:
		_pruefe(pfad + " Walze", Vector2((a as CylinderShape3D).radius,
				(a as CylinderShape3D).height), Vector2((b as CylinderShape3D).radius,
				(b as CylinderShape3D).height))
	elif a is CapsuleShape3D and b is CapsuleShape3D:
		_pruefe(pfad + " Kapsel", Vector2((a as CapsuleShape3D).radius,
				(a as CapsuleShape3D).height), Vector2((b as CapsuleShape3D).radius,
				(b as CapsuleShape3D).height))


func _zaehle(wurzel: Node) -> int:
	var n := 1
	for kind in wurzel.get_children():
		n += _zaehle(kind)
	return n
