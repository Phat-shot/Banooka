extends RefCounted
class_name Waldsetzer
## Setzt Wald: viele Bäume, Büsche, Farne und Felsen, sortiert nach Art und
## Zelle, als wenige Zeichenaufrufe.
##
## Wer pflanzt, meldet zuerst die ARTEN an (`art()`: Stoff, Schatten,
## Sichtweite, Zellgröße, Verfahren) und setzt dann Stück für Stück
## (`setze(art, netz, lage, farbe)`). `fertig()` baut daraus die Knoten.
## Zwei Verfahren je Art:
##   MultiMesh      (Vorgabe) je Netz und Zelle ein `MultiMeshInstance3D`,
##                  getönt über Instanzfarben. Für viele gleiche Stücke –
##                  Farne, Büsche, Felsen – und für Stoffe, deren Vertex-
##                  shader den Ursprung des Stücks braucht (der Wind der
##                  Farne schwingt um den Fuß).
##   verschmelzen   je Zelle EIN Netz aus allen Stücken, gleich welcher
##                  Form: ein Zeichenaufruf für einen ganzen Hain aus zehn
##                  verschiedenen Stämmen. Lage und Tönung werden in die
##                  Scheitel eingebacken (die Farbe multipliziert COLOR, so
##                  wie es eine Instanzfarbe täte). Mit "karten" wachsen die
##                  Blattkarten einer `Kronenwolke` mit (UV2.y × Maßstab),
##                  denn deren Shader liest den Maßstab sonst aus der Lage
##                  des Knotens.
## Beide Wege teilen Stoffe (nie verändern) und bauen keine Kollision.
##
## ZELLEN. Die Welt wird in Quadrate der Kantenlänge `zelle` geteilt; je
## Zelle entsteht ein Knoten mit harter Sichtweite (`visibility_range_end`,
## gemessen bis zur Zellmitte – dort liegt der Ursprung des Knotens). Wer
## ein Stück sicher bis `d` Meter sehen will, gibt `d + 0,71 · zelle` an.
## Überblenden gibt es im Compatibility-Renderer nicht verlässlich; die
## Grenze liegt im Dunst.
##
## SCHATTEN. Je Art an oder aus: Borke wirft, Laub nicht. Jede Zelle mit
## Schatten kostet in jeder Schattenstufe, die sie erreicht, einen
## weiteren Zeichenaufruf – schattenwerfende Arten also grob zellen.
##
## HELFER für den Pflanzer (alle statisch):
##   `Raster`          Mindestabstand zwischen Stücken (Streuung ohne Haufen)
##   `kegel_frei()`    liegt eine Kugel außerhalb aller Sichtkegel?
##   `drehung_weg()`   dreht einen Stamm so, dass seine Brettwurzeln nicht
##                     in eine Richtung (zum Weg) ragen (`fuss_radien`)
##   `getoent()`       Kopie eines Netzes mit eingefärbten Scheiteln
## Dazu `fremd()`: die Flächen eines Netzes aus `Fremdmodelle.netz` als je
## eigene Art (Stoff und Schatten der Fläche).
##
## Aufruf:
##     var ws := Waldsetzer.new(level.geometrie, "Hallenwald", 40.0)
##     ws.art("stamm", {"stoff": Riesenstamm.borkenstoff(), "schatten": true,
##             "sicht": 120.0, "verschmelzen": true})
##     ws.art("farn", {"stoff": Farnwerk.stoff(), "sicht": 40.0, "zelle": 20.0})
##     ws.setze("stamm", baum["stamm"], lage, Color(0.9, 0.9, 0.9))
##     ws.setze("farn", farn, lage)
##     ws.fertig()

## Vorgabe der Übergangszone an den Sichtgrenzen (m), gegen Flackern.
const RAND := 5.0

## Alle Knoten hängen hier.
var wurzel: Node3D
## Kantenlänge der Zellen (m), wenn eine Art keine eigene angibt.
var zelle := 40.0

var _arten := {}
var _reihenfolge: Array[String] = []


func _init(eltern: Node3D, name: String, zellmass: float = 40.0) -> void:
	wurzel = Node3D.new()
	wurzel.name = name
	eltern.add_child(wurzel)
	zelle = zellmass


## Meldet eine Art an. Optionen (alle freiwillig):
##   stoff         Material für alle Stücke (null: die Materialien der Netze)
##   schatten      wirft Schatten: false, true oder "nur" (nur in die
##                 Schattenkarte – für schlichte Ersatznetze)
##   sicht         harte Sichtweite bis zur Zellmitte in m (0 = unbegrenzt)
##   sicht_von     erst ab dieser Entfernung sichtbar (0)
##   rand          Übergangszone der Sichtweiten (`RAND`)
##   zelle         eigene Zellgröße (sonst die des Setzers; 0 = eine Zelle)
##   verschmelzen  je Zelle ein Netz (false = MultiMesh je Netz)
##   karten        beim Verschmelzen die Blattkarten mitskalieren (false)
func art(name: String, optionen: Dictionary = {}) -> void:
	if _arten.has(name):
		return
	var a := {
		"stoff": optionen.get("stoff", null),
		"schatten": _schattenart(optionen.get("schatten", false)),
		"sicht": float(optionen.get("sicht", 0.0)),
		"sicht_von": float(optionen.get("sicht_von", 0.0)),
		"rand": float(optionen.get("rand", RAND)),
		"zelle": float(optionen.get("zelle", zelle)),
		"verschmelzen": bool(optionen.get("verschmelzen", false)),
		"karten": bool(optionen.get("karten", false)),
		# Zellschlüssel -> Array von [netz, lage, farbe]
		"zellen": {},
		"anzahl": 0,
	}
	_arten[name] = a
	_reihenfolge.append(name)


func hat_art(name: String) -> bool:
	return _arten.has(name)


## Setzt ein Stück: `netz` in `lage` (Welt), getönt mit `farbe` (multipliziert
## die Scheitelfarbe; Alpha bleibt am besten 1 – bei Kronen und Farnen ist
## COLOR.a das Windgewicht).
func setze(name: String, netz: Mesh, lage: Transform3D, farbe: Color = Color(1, 1, 1, 1)) -> void:
	if netz == null or not _arten.has(name):
		return
	var a: Dictionary = _arten[name]
	var z: float = a["zelle"]
	var schluessel := Vector2i.ZERO
	if z > 0.0:
		schluessel = Vector2i(floori(lage.origin.x / z), floori(lage.origin.z / z))
	var zellen: Dictionary = a["zellen"]
	if not zellen.has(schluessel):
		zellen[schluessel] = []
	(zellen[schluessel] as Array).append([netz, lage, farbe])
	a["anzahl"] = int(a["anzahl"]) + 1


## Stücke einer Art (oder aller Arten).
func anzahl(name: String = "") -> int:
	if not name.is_empty():
		return int((_arten.get(name, {"anzahl": 0}) as Dictionary)["anzahl"])
	var summe := 0
	for n: String in _reihenfolge:
		summe += int((_arten[n] as Dictionary)["anzahl"])
	return summe


## Baut die Knoten. Rückgabe: {"knoten": Zahl der Zeichenknoten,
## "dreiecke": Summe über alle Stücke}.
func fertig() -> Dictionary:
	var knoten := 0
	var dreiecke := 0
	for name: String in _reihenfolge:
		var a: Dictionary = _arten[name]
		var zellen: Dictionary = a["zellen"]
		for schluessel: Vector2i in zellen:
			var stuecke: Array = zellen[schluessel]
			if stuecke.is_empty():
				continue
			var mitte := _mitte(stuecke)
			if bool(a["verschmelzen"]):
				var netz := _verschmelzen(stuecke, mitte, bool(a["karten"]))
				if netz == null:
					continue
				var mi := MeshInstance3D.new()
				mi.name = "%s %d,%d" % [name, schluessel.x, schluessel.y]
				mi.mesh = netz
				mi.position = mitte
				_einrichten(mi, a)
				wurzel.add_child(mi)
				knoten += 1
				dreiecke += _dreiecke(netz)
			else:
				# je Netz ein MultiMesh
				var je_netz := {}
				var netze: Array[Mesh] = []
				for eintrag: Array in stuecke:
					var n: Mesh = eintrag[0]
					if not je_netz.has(n):
						je_netz[n] = []
						netze.append(n)
					(je_netz[n] as Array).append(eintrag)
				for i in netze.size():
					var n := netze[i]
					var liste: Array = je_netz[n]
					var mm := MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = true
					mm.mesh = n
					mm.instance_count = liste.size()
					for k in liste.size():
						var e: Array = liste[k]
						var lage: Transform3D = e[1]
						lage.origin -= mitte
						mm.set_instance_transform(k, lage)
						mm.set_instance_color(k, e[2] as Color)
					var mmi := MultiMeshInstance3D.new()
					mmi.name = "%s %d,%d #%d" % [name, schluessel.x, schluessel.y, i]
					mmi.multimesh = mm
					mmi.position = mitte
					_einrichten(mmi, a)
					wurzel.add_child(mmi)
					knoten += 1
					dreiecke += _dreiecke(n) * liste.size()
	return {"knoten": knoten, "dreiecke": dreiecke}


## true/false oder "nur" (zeichnet nur in die Schattenkarte: ein schlichter
## Ersatz wirft den Schatten eines teuren Netzes).
static func _schattenart(wert: Variant) -> GeometryInstance3D.ShadowCastingSetting:
	if wert is String and String(wert) == "nur":
		return GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if wert is bool and bool(wert):
		return GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _einrichten(g: GeometryInstance3D, a: Dictionary) -> void:
	var stoff: Material = a["stoff"]
	if stoff != null:
		g.material_override = stoff
	var schatten: GeometryInstance3D.ShadowCastingSetting = a["schatten"]
	g.cast_shadow = schatten
	var bis: float = a["sicht"]
	var von: float = a["sicht_von"]
	var rand: float = a["rand"]
	if bis > 0.0:
		g.visibility_range_end = bis
		g.visibility_range_end_margin = rand
	if von > 0.0:
		g.visibility_range_begin = von
		g.visibility_range_begin_margin = rand


## Mitte einer Zelle aus ihren Stücken (Mittel der Ursprünge): Dort liegt
## der Ursprung des Knotens, von dort misst die Sichtweite.
func _mitte(stuecke: Array) -> Vector3:
	var summe := Vector3.ZERO
	for e: Array in stuecke:
		var lage: Transform3D = e[1]
		summe += lage.origin
	return summe / float(stuecke.size())


# ================================================================ Verschmelzen

## Ein Netz aus allen Stücken einer Zelle, relativ zu `mitte`. Alle Flächen
## aller Netze gehen in EINE Fläche – sie müssen also denselben Stoff
## vertragen. Indizes werden fortgezählt (Netze ohne Indizes bekommen
## welche), fehlende Farben sind weiß, fehlende UVs null.
static func _verschmelzen(stuecke: Array, mitte: Vector3, karten: bool) -> ArrayMesh:
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var tangenten := PackedFloat32Array()
	var farben := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var indizes := PackedInt32Array()
	var mit_tangenten := true
	# Die Scheiteldaten je Netz nur einmal lesen: `surface_get_arrays` holt
	# sie jedes Mal neu vom Server.
	var vorrat := {}
	for e: Array in stuecke:
		var netz: Mesh = e[0]
		if vorrat.has(netz):
			continue
		var flaechen: Array = []
		for f in netz.get_surface_count():
			var arrays := netz.surface_get_arrays(f)
			var t: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null \
					else PackedFloat32Array()
			if t.is_empty():
				mit_tangenten = false
			flaechen.append(arrays)
		vorrat[netz] = flaechen
	for e: Array in stuecke:
		var netz: Mesh = e[0]
		var lage: Transform3D = e[1]
		lage.origin -= mitte
		var ton: Color = e[2]
		var nbasis := lage.basis.inverse().transposed()
		var gleich := _gleichmaessig(lage.basis)
		var skala := lage.basis.get_scale().length() / sqrt(3.0)
		var spiegel := lage.basis.determinant() < 0.0
		for arrays: Array in vorrat[netz]:
			var p: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n := p.size()
			if n == 0:
				continue
			var basis_index := ecken.size()
			ecken.append_array(lage * p)
			# Normalen: bei gleichmäßigem Maßstab genügt die Drehung.
			var nn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null \
					else PackedVector3Array()
			if nn.size() == n:
				if gleich:
					normalen.append_array(Transform3D(lage.basis.orthonormalized(), Vector3.ZERO) * nn)
				else:
					var gedreht := Transform3D(nbasis, Vector3.ZERO) * nn
					for i in gedreht.size():
						gedreht[i] = gedreht[i].normalized()
					normalen.append_array(gedreht)
			else:
				var leer := PackedVector3Array()
				leer.resize(n)
				leer.fill(Vector3.UP)
				normalen.append_array(leer)
			if mit_tangenten:
				var tt: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				var ob := lage.basis.orthonormalized()
				for i in n:
					var v := (ob * Vector3(tt[i * 4], tt[i * 4 + 1], tt[i * 4 + 2])).normalized()
					tangenten.append(v.x)
					tangenten.append(v.y)
					tangenten.append(v.z)
					tangenten.append(-tt[i * 4 + 3] if spiegel else tt[i * 4 + 3])
			var cc: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null \
					else PackedColorArray()
			if cc.size() == n:
				# Kopie: Die Daten im Vorrat gehören allen Stücken dieses Netzes.
				cc = cc.duplicate()
				for i in n:
					cc[i] = cc[i] * ton
				farben.append_array(cc)
			else:
				var voll := PackedColorArray()
				voll.resize(n)
				voll.fill(ton)
				farben.append_array(voll)
			var u1: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null \
					else PackedVector2Array()
			if u1.size() != n:
				u1 = PackedVector2Array()
				u1.resize(n)
			uv.append_array(u1)
			var u2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null \
					else PackedVector2Array()
			if u2.size() != n:
				u2 = PackedVector2Array()
				u2.resize(n)
			elif karten and absf(skala - 1.0) > 0.001:
				u2 = u2.duplicate()
				for i in n:
					if u2[i].x >= 0.5:
						u2[i] = Vector2(u2[i].x, u2[i].y * skala)
			uv2.append_array(u2)
			var ind: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null \
					else PackedInt32Array()
			if ind.is_empty():
				ind.resize(n)
				for i in n:
					ind[i] = i
			else:
				ind = ind.duplicate()
			for i in ind.size():
				ind[i] += basis_index
			if spiegel:
				for i in range(0, ind.size() - 2, 3):
					var tausch := ind[i + 1]
					ind[i + 1] = ind[i + 2]
					ind[i + 2] = tausch
			indizes.append_array(ind)
	if ecken.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = ecken
	arrays[Mesh.ARRAY_NORMAL] = normalen
	if mit_tangenten:
		arrays[Mesh.ARRAY_TANGENT] = tangenten
	arrays[Mesh.ARRAY_COLOR] = farben
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = indizes
	var netz := ArrayMesh.new()
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Blattkarten wachsen erst im Shader um ihre Mitte: Hülle weiten, sonst
	# schneidet die Sichtprüfung sie am Rand ab (wie `Kronenwolke.netz`).
	if karten:
		netz.custom_aabb = netz.get_aabb().grow(1.2)
	return netz


static func _gleichmaessig(b: Basis) -> bool:
	var s := b.get_scale()
	return absf(s.x - s.y) < 0.001 and absf(s.y - s.z) < 0.001


static func _dreiecke(netz: Mesh) -> int:
	var summe := 0
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var ind: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null \
				else PackedInt32Array()
		if not ind.is_empty():
			summe += ind.size() / 3
		else:
			summe += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return summe


# ================================================================ Fremdmodelle

## Die Flächen eines Netzes aus `Fremdmodelle.netz` (oder `rolle_netze`)
## als je eigene Art "<name>/<index>" – Stoff und Schatten der Fläche, die
## übrigen Optionen wie `art()`. Rückgabe: die Namen der Arten; mit
## `setze_fremd` setzt man ein Stück in alle zugleich.
func fremd(name: String, modell: Dictionary, optionen: Dictionary = {}) -> Array[String]:
	var namen: Array[String] = []
	var flaechen: Array = modell.get("flaechen", [])
	for i in flaechen.size():
		var f: Dictionary = flaechen[i]
		var o := optionen.duplicate()
		o["stoff"] = f.get("material", null)
		o["schatten"] = bool(optionen.get("schatten", true)) and bool(f.get("schatten", false))
		o["verschmelzen"] = false
		var art_name := "%s/%d" % [name, i]
		art(art_name, o)
		namen.append(art_name)
	return namen


## Setzt ein Fremdmodell (Arten aus `fremd()`) mit allen Flächen.
func setze_fremd(namen: Array[String], modell: Dictionary, lage: Transform3D,
		farbe: Color = Color(1, 1, 1, 1)) -> void:
	var flaechen: Array = modell.get("flaechen", [])
	for i in mini(namen.size(), flaechen.size()):
		var f: Dictionary = flaechen[i]
		setze(namen[i], f.get("mesh", null) as Mesh, lage, farbe)


# ================================================================ Helfer

## Mindestabstand zwischen Stücken in der Ebene: ein Raster aus Eimern.
## `frei(p, r)` fragt, ob im Umkreis r (plus dem Radius der gesetzten
## Stücke) nichts steht; `dazu(p, r)` trägt ein Stück ein.
class Raster:
	extends RefCounted
	var _mass := 8.0
	var _eimer := {}
	var _groesster := 0.0

	func _init(mass: float = 8.0) -> void:
		_mass = maxf(mass, 0.5)

	func frei(p: Vector2, r: float) -> bool:
		var weite := r + _groesster
		var a := Vector2i(floori((p.x - weite) / _mass), floori((p.y - weite) / _mass))
		var b := Vector2i(floori((p.x + weite) / _mass), floori((p.y + weite) / _mass))
		for i in range(a.x, b.x + 1):
			for j in range(a.y, b.y + 1):
				var k := Vector2i(i, j)
				if not _eimer.has(k):
					continue
				for e: Vector3 in _eimer[k]:
					var d := Vector2(e.x, e.y).distance_to(p)
					if d < r + e.z:
						return false
		return true

	func dazu(p: Vector2, r: float) -> void:
		var k := Vector2i(floori(p.x / _mass), floori(p.y / _mass))
		if not _eimer.has(k):
			_eimer[k] = []
		(_eimer[k] as Array).append(Vector3(p.x, p.y, r))
		_groesster = maxf(_groesster, r)


## Liegt die Kugel (`mitte`, `radius`) außerhalb aller Sichtkegel? Ein
## Kegel: {"auge": Vector3, "ziel": Vector3, "winkel": halber Öffnungswinkel
## in rad, "ziel_frei": so viele Meter vor dem Ziel endet er (0)}. Nur was
## zwischen Auge und Ziel liegt, kann stören.
static func kegel_frei(mitte: Vector3, radius: float, kegel: Array) -> bool:
	for k: Dictionary in kegel:
		var auge: Vector3 = k["auge"]
		var ziel: Vector3 = k["ziel"]
		var winkel: float = k["winkel"]
		var achse := ziel - auge
		var laenge := achse.length()
		if laenge < 0.01:
			continue
		achse /= laenge
		var zu := mitte - auge
		var entlang := zu.dot(achse)
		if entlang <= 0.0 or entlang > laenge - float(k.get("ziel_frei", 0.0)):
			continue
		var d := zu.length()
		if d <= radius:
			return false
		# Winkel zwischen Achse und Kugelmitte minus der halben scheinbaren
		# Größe der Kugel
		var zwischen := acos(clampf(entlang / d, -1.0, 1.0))
		if zwischen - asin(clampf(radius / d, 0.0, 1.0)) < winkel:
			return false
	return true


## Drehung um Y (rad), mit der ein Stamm seine Wurzeln möglichst wenig in
## Richtung `weg` (waagerecht) streckt. `fuss_radien`: der Umriss am Boden
## in gleichen Winkelschritten (0 = +X, weiter über -Z; `Riesenstamm`
## meldet ihn als Metadatum). Rückgabe: {"drehung", "weite"} – "weite" ist
## die größte Ausdehnung in Richtung `weg` nach der Drehung.
static func drehung_weg(fuss_radien: PackedFloat32Array, weg: Vector3) -> Dictionary:
	var n := fuss_radien.size()
	if n < 3:
		return {"drehung": 0.0, "weite": 0.0}
	var richtung := Vector2(weg.x, weg.z).normalized()
	var beste := 0.0
	var kleinste := INF
	for k in 36:
		var dreh := TAU * float(k) / 36.0
		var weite := 0.0
		for j in n:
			var w := TAU * float(j) / float(n)
			# lokal (cos w, -sin w) in XZ, um Y gedreht
			var lokal := Vector3(cos(w), 0.0, -sin(w))
			var welt := Basis(Vector3.UP, dreh) * lokal
			weite = maxf(weite, fuss_radien[j] * Vector2(welt.x, welt.z).dot(richtung))
		if weite < kleinste:
			kleinste = weite
			beste = dreh
	return {"drehung": beste, "weite": kleinste}


## Kopie eines Netzes, dessen Scheitelfarben mit `ton` multipliziert sind
## (für feste Tönungen, wo keine Instanzfarbe hilft). Das Original bleibt
## unberührt; Metadaten wandern mit.
static func getoent(netz: ArrayMesh, ton: Color) -> ArrayMesh:
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null \
				else PackedColorArray()
		if not farben.is_empty():
			for i in farben.size():
				farben[i] = farben[i] * ton
			arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		neu.surface_set_material(f, netz.surface_get_material(f))
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu
