extends RefCounted
class_name L05Ablage
## Level 05: fertig gebaute Knotenbäume aus Netzen (der Wald) als Daten für
## den `Bauspeicher` – und zurück (Paket P7, Mängel der Prüfung).
##
## WARUM. Wald und Rasen rechneten ihre Lage bei jedem Laden neu: Haine mit
## Sichtkegeln, Himmelsprobe, Baumtore, Rasen nach der Wegmaske, Laub und
## Farn. Gemessen (Bauzeitprobe, P7): 2,6 s je Laden (Runde 2) und 3,2 s
## kalt; mit Wald und Rasen lagen warm 4,8 s und Runde 2 2,9 s über den
## Zielen des Entwurfs (§9.4: warm ≤ 4 s, Runde 2 ≤ 0,3 s). Heraus kommen
## wenige hundert Knoten, die allein von Code, Daten des Levels, Kamera und
## Handyweg abhängen – genau das, wofür der Bauspeicher da ist
## (bauspeicher.gd). Wie `L05Saum` und `GelaendeBau` legt der Bau sie beim
## ersten Laden ab und hängt sie danach nur noch ein.
##
## NUR NETZE (MeshInstance3D), KEINE MULTIMESHES: Ohne Grafik (headless,
## Dummy-Renderer: alle Prüfwerkzeuge und die Bauzeitprobe) gibt der
## RenderingServer die Instanzen eines MultiMesh nicht zurück – `buffer`
## ist leer, `get_instance_transform` die Einheit (gemessen). Abgelegt wäre
## daraus ein Feld ohne Lagen geworden. Wer MultiMeshes baut, legt deshalb
## ihre Lagen selbst ab und baut sie beim Laden mit demselben Code neu
## (`L05Wald` den Waldboden, `L05Rasen` Rasen, Laub und Farn).
##
## WAS ABGELEGT WIRD (`sichern`). Je Knoten unter den Wurzeln, in der
## Reihenfolge des Baums: Name, Lage, Eltern, sichtbar; für Geometrie die
## Einstellungen von `GeometryInstance3D` (EIGENSCHAFTEN), das Netz und der
## Stoff.
## STOFFE gehen nie in die Ablage, nur ihr Schlüssel in der TAFEL des
## Aufrufers: Sie sind geteilt (`Kronenwolke.stoff`, `Riesenstamm.
## borkenstoff` …) und hängen an Texturen der Bibliothek – abgelegt kämen
## sie als Abschrift zurück, mit eigenen Texturen im Grafikspeicher.
## Dasselbe gilt für Netze, die ihren Stoff in den Flächen tragen: Auch sie
## stehen in der Tafel. Eigene Netze ohne Stoff (verschmolzene Zellen) gehen
## ganz hinein; ein Netz, das mehrere Knoten teilen, liegt einmal darin und
## ist nach dem Laden wieder geteilt. Der Aufrufer gibt beim Ablegen und
## beim Einhängen eine Tafel mit denselben Schlüsseln und baut die Stoffe
## darin beide Male gleich.
##
## Geht etwas nicht (ein Stoff ohne Schlüssel, ein Knoten anderer Art – auch
## ein MultiMesh –, ein Netz mit Stoff in den Flächen), liefert `sichern`
## {}: Dann wird nicht abgelegt, und das nächste Laden baut wieder – lieber
## langsam als falsch. `einhaengen` prüft vorher, ob die Tafel jeden
## Schlüssel kennt, und hängt sonst nichts ein (Rückgabe false).

## Was je Geometrieknoten mitgeht – alles, was der `Waldsetzer` und
## `L05Wald` setzen, und was sonst das Bild ändern könnte, wenn es jemand
## setzt.
const EIGENSCHAFTEN: Array[StringName] = [&"cast_shadow", &"gi_mode", &"layers",
		&"extra_cull_margin", &"custom_aabb", &"lod_bias", &"transparency",
		&"visibility_range_begin", &"visibility_range_begin_margin", &"visibility_range_end",
		&"visibility_range_end_margin", &"visibility_range_fade_mode", &"sorting_offset",
		&"sorting_use_aabb_center", &"ignore_occlusion_culling"]


## Die Knoten unter `wurzeln` (je samt der Wurzel selbst) als Daten. `tafel`:
## Schlüssel -> Stoff oder Netz, das nicht mit hinein soll. {} bei einem
## Knoten oder Stoff, den die Ablage nicht kennt.
static func sichern(wurzeln: Array[Node3D], tafel: Dictionary) -> Dictionary:
	var rueck := {}
	for k: String in tafel:
		if tafel[k] != null:
			rueck[tafel[k]] = k
	var knoten: Array[Dictionary] = []
	for w in wurzeln:
		if not _sammeln(w, -1, rueck, knoten):
			return {}
	return {"knoten": knoten}


## Hängt die Knoten aus `daten` (von `sichern`) unter `eltern` ein. false,
## wenn die Tafel einen Schlüssel nicht kennt – dann ist nichts eingehängt.
static func einhaengen(eltern: Node3D, daten: Dictionary, tafel: Dictionary) -> bool:
	var knoten: Array = daten.get("knoten", [])
	if knoten.is_empty():
		return false
	for e: Dictionary in knoten:
		for feld: String in ["stoff", "netz_schluessel"]:
			if e.has(feld) and tafel.get(String(e[feld])) == null:
				push_warning("L05Ablage: Schlüssel '%s' fehlt in der Tafel" % e[feld])
				return false
	var gebaut: Array[Node3D] = []
	for e: Dictionary in knoten:
		var n: Node3D
		match String(e.get("art", "")):
			"netz":
				var mi := MeshInstance3D.new()
				mi.mesh = _netz(e, tafel)
				n = mi
			_:
				n = Node3D.new()
		n.name = String(e["name"])
		n.transform = e["lage"] as Transform3D
		n.visible = bool(e["sichtbar"])
		if n is GeometryInstance3D:
			var g := n as GeometryInstance3D
			if e.has("stoff"):
				g.material_override = tafel[String(e["stoff"])] as Material
			var werte: Array = e["werte"]
			for i in EIGENSCHAFTEN.size():
				g.set(EIGENSCHAFTEN[i], werte[i])
		var i_eltern := int(e["eltern"])
		(eltern if i_eltern < 0 else gebaut[i_eltern]).add_child(n)
		gebaut.append(n)
	return true


# ================================================================ Helfer

static func _sammeln(n: Node, eltern: int, rueck: Dictionary, aus: Array[Dictionary]) -> bool:
	var n3 := n as Node3D
	if n3 == null or n.get_script() != null:
		push_error("L05Ablage: Knoten '%s' (%s) lässt sich nicht ablegen" % [n.name, n.get_class()])
		return false
	var e := {"name": String(n.name), "eltern": eltern, "lage": n3.transform,
			"sichtbar": n3.visible}
	var g := n as GeometryInstance3D
	if g != null:
		if g.material_overlay != null:
			push_error("L05Ablage: '%s' hat einen material_overlay" % n.name)
			return false
		if g.material_override != null:
			if not rueck.has(g.material_override):
				push_error("L05Ablage: Stoff von '%s' fehlt in der Tafel" % n.name)
				return false
			e["stoff"] = rueck[g.material_override]
		var werte := []
		for p in EIGENSCHAFTEN:
			werte.append(g.get(p))
		e["werte"] = werte
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			for i in mi.get_surface_override_material_count():
				if mi.get_surface_override_material(i) != null:
					push_error("L05Ablage: '%s' hat einen Flächenstoff" % n.name)
					return false
			e["art"] = "netz"
			if not _netz_eintragen(mi.mesh, rueck, e):
				return false
		else:
			push_error("L05Ablage: '%s' (%s) lässt sich nicht ablegen" % [n.name, n.get_class()])
			return false
	elif n.get_class() != "Node3D":
		push_error("L05Ablage: '%s' (%s) lässt sich nicht ablegen" % [n.name, n.get_class()])
		return false
	aus.append(e)
	var ich := aus.size() - 1
	for c in n.get_children():
		if not _sammeln(c, ich, rueck, aus):
			return false
	return true


## Ein Netz: aus der Tafel (Schlüssel) oder ganz, wenn es keinen Stoff in
## den Flächen trägt.
static func _netz_eintragen(netz: Mesh, rueck: Dictionary, e: Dictionary) -> bool:
	if netz == null:
		return true
	if rueck.has(netz):
		e["netz_schluessel"] = rueck[netz]
		return true
	var am := netz as ArrayMesh
	if am == null:
		push_error("L05Ablage: Netz '%s' ist kein ArrayMesh" % e["name"])
		return false
	for i in am.get_surface_count():
		if am.surface_get_material(i) != null:
			push_error("L05Ablage: Netz von '%s' trägt einen Stoff und fehlt in der Tafel" % e["name"])
			return false
	e["netz"] = am
	return true


static func _netz(e: Dictionary, tafel: Dictionary) -> Mesh:
	if e.has("netz_schluessel"):
		return tafel[String(e["netz_schluessel"])] as Mesh
	return e.get("netz", null) as Mesh


## Schlüssel-Anhang für die Kamera: Abstand, Höhe, Blickvorlauf, far und fov
## formen Sichtkegel, Himmelsprobe, K8 und Sichtweiten. Sie stehen in
## Level05.tscn, das der Fingerabdruck des Bauspeichers nicht sieht (er
## liest nur Skripte). Ein Kameraplan (Paket G6) gehört dann mit hinein.
static func kamera_schluessel(kamera: KorridorKamera) -> String:
	if kamera == null:
		return "ohne"
	var werte := [kamera.abstand, kamera.hoehe, kamera.blick_vorlauf, kamera.far, kamera.fov,
			kamera.get("plan") != null]
	return var_to_str(werte).md5_text().substr(0, 10)
