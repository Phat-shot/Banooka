extends Node
## Misst jedes Bauteil eines Levels: wo es steht und wie groß es wirklich ist.
##
## Gebaut, weil ein Bildschirmfoto genau drei Antworten offenlässt: Ist das
## Ding gar nicht da, ist es da und unsichtbar, oder ist es da und sitzt an
## der falschen Stelle? Die Netzhülle in Weltmaßen beantwortet alle drei.
##
##   bash werkzeuge/lauf.sh res://werkzeuge/Bauteilprobe.tscn res://scenes/levels/Werkstatt.tscn

func _ready() -> void:
	var pfad := "res://scenes/levels/Werkstatt.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	var level: Node3D = load(pfad).instantiate()
	add_child(level)
	if level.has_signal("aufbau_fertig"):
		await level.aufbau_fertig
	for i in 8:
		await get_tree().physics_frame

	var verlauf: Curve3D = level.get("verlauf")
	print("=== Bauteile in %s ===" % pfad.get_file().get_basename())
	var zeilen: Array[String] = []
	for k in _alle(level):
		var art := _art_von(k)
		if art.is_empty():
			continue
		var knoten := k as Node3D
		var huelle := _huelle(knoten)
		var strecke := 0.0
		if verlauf != null:
			strecke = verlauf.get_closest_offset(knoten.global_position)
		zeilen.append("%7.1f m  %-16s Ort %-22s Hülle y %+6.2f..%+6.2f  %.1f×%.1f m  Netze %d"
				% [strecke, art, str(knoten.global_position.snappedf(0.1)),
				huelle["unten"], huelle["oben"], huelle["breite"], huelle["tiefe"],
				huelle["netze"]])
	zeilen.sort()
	for z in zeilen:
		print("  " + z)
	print("%d Bauteile" % zeilen.size())
	get_tree().quit(0)


## Klassenname, wenn es eines unserer Bauteile ist.
func _art_von(k: Node) -> String:
	for paar in [["Bruchplatte", k is Bruchplatte], ["Taktflaeche", k is Taktflaeche],
			["Feuerspeier", k is Feuerspeier], ["Laserzaun", k is Laserzaun],
			["Rollhindernis", k is Rollhindernis], ["Drehplattform", k is Drehplattform],
			["Fliessband", k is Fliessband], ["Schiebeblock", k is Schiebeblock],
			["Ausloeseplatte", k is Ausloeseplatte], ["Schliesstuer", k is Schliesstuer],
			["Deckungsfleck", k is Deckungsfleck], ["Hangelgitter", k is Hangelgitter],
			["Werfer", k is Werfer], ["Schwarm", k is Schwarm],
			["Wasserplattform", k is Wasserplattform], ["Horizont", k is Horizont]]:
		if bool(paar[1]):
			return String(paar[0])
	return ""


## Hülle aller sichtbaren Netze darunter, in Weltmaßen.
func _huelle(wurzel: Node3D) -> Dictionary:
	var gesamt := AABB()
	var erster := true
	var netze := 0
	for k in _alle(wurzel):
		var mi := k as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		netze += 1
		var kasten: AABB = mi.global_transform * mi.get_aabb()
		gesamt = kasten if erster else gesamt.merge(kasten)
		erster = false
	if erster:
		return {"unten": 0.0, "oben": 0.0, "breite": 0.0, "tiefe": 0.0, "netze": 0}
	return {"unten": gesamt.position.y, "oben": gesamt.position.y + gesamt.size.y,
			"breite": gesamt.size.x, "tiefe": gesamt.size.z, "netze": netze}


func _alle(w: Node) -> Array[Node]:
	var l: Array[Node] = [w]
	for k in w.get_children():
		l.append_array(_alle(k))
	return l
