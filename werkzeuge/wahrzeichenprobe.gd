extends Node
## Wahrzeichenprobe: Steht das Wahrzeichen eines Levels im Bild – und ist es
## dort frei? (Level 05, die Hauereiche; Entwurf L05 §11 Nr. 7, §7.1 K3,
## §8.2, Paket P4)
##
## Aufruf:
##   godot --headless --path . res://werkzeuge/Wahrzeichenprobe.tscn \
##       -- res://scenes/levels/Level05.tscn
## Rückgabe 1, wenn der Anteil unter GRENZE liegt oder die Probe nichts
## messen konnte.
##
## WARUM: Die Eiche ist das Bild von Level 05 – man läuft von ihr weg, im
## Rückblick steht sie über dem ganzen Hang und wird immer kleiner. Der
## Entwurf hat gerechnet, dass ihre Kronen an 95 % der Stellen im Bild
## liegen, aber nur gegen das Wegprofil: ohne Gelände, Saum und Bäume.
## Ob ein Hang, eine Böschungskrone oder (ab Paket P7) ein Baum sie
## verdeckt, sieht man erst an der gezeichneten Geometrie. Die Freiraum-
## probe K3 im LevelCheck prüft Strahlen gegen das Höhenmodell; diese Probe
## prüft gegen die Dreiecke, die wirklich gezeichnet werden.
##
## OPT-IN: Gemessen wird nur ein Level mit `wahrzeichen() -> Array[Dictionary]`:
## je Eintrag "name" und "punkte" (PackedVector3Array, Weltkoordinaten).
## Einträge, deren Name mit "Krone" beginnt, sind die Kronen; ein Eintrag
## "Kerbe" ist der Himmelsspalt dazwischen und darf "kanten" tragen (die
## beiden innersten Ecken der Kronen). Die Stellen kommen aus
## `wahrzeichen_strecke() -> Vector2(von, bis)`, sonst `start_strecke` bis
## `ende()`; Schritt SCHRITT.
##
## JE STELLE s: die Figur in der Mitte des Weges (`weg_punkt(s, 0)`), die
## Kamera nach dem Modell aus `werkzeuge/level_check.gd` (`_kamera_modell`,
## `_freie_sicht`: eingeschwungen, auf den Ebenen der Kamera), mit dem
## Sichtfeld der Kamera im Seitenverhältnis 16:9 (1280 × 720) und ihrem
## `near`/`far`. Ein Punkt zählt, wenn er im Bildstumpf liegt und der Strahl
## von der Kamera zu ihm frei ist.
##   „frei im Bild"  jede Krone hat mindestens einen solchen Punkt – das
##                   Maß der Abnahme (Anteil ≥ GRENZE)
##   „Kerbe frei"    ein Punkt der Kerbe zählt
##   „im Bild"       wie „frei im Bild", aber ohne Verdeckung (Vergleich mit
##                   der Rechnung des Entwurfs)
##
## VERDECKUNG: alle sichtbaren Netze des Levels (MeshInstance3D und
## MultiMeshInstance3D samt allen Instanzen), außer dem Wahrzeichen selbst
## (Gruppe "wahrzeichen"), Kisten und Früchten (flüchtig, und im Bild unten),
## Figur, Gegnern und Verfolger (Gruppen "spieler", "gegner", der `Keiler`
## steht in keiner) und reinen Schattenkörpern. Sie werden für die Probe als Dreiecksflächen auf die
## Ebene VERDECKER gelegt (eigene Körper, ohne Wirkung auf das Spiel). Wer
## eine Sichtweite hat (`visibility_range_begin/end`, Abstand Kamera – Mitte
## der Hülle), verdeckt nur dort, wo er gezeichnet wird.
##
## AUSGABE: je ZEILE_JE Stellen eine Zeile, jede Spanne ohne freie Kronen,
## die Kerbe im Schlussbild (Stelle `bis`) in Bildpunkten bei 720 Zeilen –
## wie weit die "kanten" im Bild waagerecht auseinanderliegen; liegen sie
## verschieden hoch, ist der Spalt in jeder Bildzeile mindestens so breit –
## und zuletzt
##   === Wahrzeichenprobe <Level>: n von N Stellen (p %) frei im Bild … ===

## Abstand der Stellen (Entwurf P4: s 6 … 296 im Schritt 2 m).
const SCHRITT := 2.0
## Mindestanteil der Stellen, an denen beide Kronen frei im Bild stehen
## (Entwurf §11 Nr. 7).
const GRENZE := 0.7
## Bildgröße, für die gemessen wird (16:9, Kerbe in Bildpunkten).
const BILD := Vector2(1280.0, 720.0)
## Ebene der Verdeckungskörper: Ebene 30, die sonst niemand benutzt.
const VERDECKER := 1 << 29
## Eine Zeile je so viele Stellen.
const ZEILE_JE := 10

var _level: Node3D
var _kamera: KorridorKamera
var _pfad: Path3D
var _spieler: CollisionObject3D
var _raum: PhysicsDirectSpaceState3D
## Verdecker: je Netz {"rid", "von", "bis", "mitte"} (Sichtweite, Mitte der Hülle).
var _verdecker: Array[Dictionary] = []


func _ready() -> void:
	var pfad := "res://scenes/levels/Level05.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	# Immer dieselbe Fassung messen, egal was in `user://` steht.
	Zeitlauf.aktiv = false
	_level = (load(pfad) as PackedScene).instantiate() as Node3D
	var fertig := [false]
	if _level.has_signal("aufbau_fertig"):
		_level.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_level)
	var name_kurz := pfad.get_file().get_basename()
	if not _level.has_method("wahrzeichen"):
		print("=== Wahrzeichenprobe %s: kein Wahrzeichen (nicht angemeldet) ===" % name_kurz)
		get_tree().quit(0)
		return
	var gewartet := 0
	while not fertig[0] and gewartet < 3600:
		gewartet += 1
		await get_tree().physics_frame
	if _level.has_method("pruefruhe"):
		_level.call("pruefruhe")
	_kamera = _korridorkamera(_level)
	_pfad = _level.get("_pfad_knoten") as Path3D
	_spieler = get_tree().get_first_node_in_group("spieler") as CollisionObject3D
	var verlauf: Variant = _level.get("verlauf")
	var wz: Array = _level.call("wahrzeichen")
	if _kamera == null or not verlauf is Curve3D or wz.is_empty():
		print("  FEHLER  Wahrzeichenprobe: keine KorridorKamera, kein Verlauf oder kein Wahrzeichen")
		print("=== Wahrzeichenprobe %s: nichts gemessen ===" % name_kurz)
		get_tree().quit(1)
		return
	var netze := _verdecker_anlegen()
	for i in 2:
		await get_tree().physics_frame
	_raum = get_viewport().world_3d.direct_space_state
	var strecke := Vector2(float(_level.get("start_strecke")), float(_level.call("ende")))
	if _level.has_method("wahrzeichen_strecke"):
		strecke = _level.call("wahrzeichen_strecke")
	print("=== Wahrzeichenprobe %s: s %.0f … %.0f im Schritt %.0f m, %d Verdecker, %d Probepunkte ==="
			% [name_kurz, strecke.x, strecke.y, SCHRITT, netze, _punktzahl(wz)])
	_messen(name_kurz, wz, strecke)


# ------------------------------------------------------------- Messung

func _messen(name_kurz: String, wz: Array, strecke: Vector2) -> void:
	var stellen := 0
	var frei := 0
	var im_bild := 0
	var kerbe := 0
	var luecken: Array[Vector2] = []
	var luecke := Vector2(NAN, NAN)
	var s := strecke.x
	while s <= strecke.y + 0.001:
		var k := _kamera_bei(s)
		var kronen_frei := true
		var kronen_bild := true
		var kerbe_frei := false
		var zeile := PackedStringArray()
		for e: Dictionary in wz:
			var name_e := String(e["name"])
			var n_bild := 0
			var n_frei := 0
			for p: Vector3 in e["punkte"]:
				if _im_stumpf(k, p):
					n_bild += 1
					if _frei(k, p):
						n_frei += 1
			if name_e.begins_with("Krone"):
				kronen_frei = kronen_frei and n_frei > 0
				kronen_bild = kronen_bild and n_bild > 0
			elif name_e == "Kerbe":
				kerbe_frei = n_frei > 0
			zeile.append("%s %d/%d" % [name_e, n_frei, n_bild])
		stellen += 1
		if kronen_frei:
			frei += 1
		if kronen_bild:
			im_bild += 1
		if kerbe_frei:
			kerbe += 1
		# Spannen ohne freie Kronen sammeln.
		if not kronen_frei:
			if is_nan(luecke.x):
				luecke = Vector2(s, s)
			else:
				luecke.y = s
		elif not is_nan(luecke.x):
			luecken.append(luecke)
			luecke = Vector2(NAN, NAN)
		if (stellen - 1) % ZEILE_JE == 0:
			print("  s %5.1f  %s  (frei/im Bild; Kamera %s)" % [s, ", ".join(zeile),
					str(k["ort"].snappedf(0.1))])
		s += SCHRITT
	if not is_nan(luecke.x):
		luecken.append(luecke)
	for l in luecken:
		print("  ohne freie Kronen: s %.0f … %.0f" % [l.x, l.y])
	_kerbe_melden(wz, strecke.y)
	var anteil := float(frei) / float(maxi(stellen, 1))
	if anteil < GRENZE:
		print("  FEHLER  Wahrzeichenprobe: frei im Bild an %.1f %% der Stellen, Grenze %.0f %%"
				% [100.0 * anteil, 100.0 * GRENZE])
	print("=== Wahrzeichenprobe %s: %d von %d Stellen (%.1f %%) frei im Bild (Grenze %.0f %%); Kerbe frei %.1f %%; ohne Verdeckung im Bild %.1f %% ==="
			% [name_kurz, frei, stellen, 100.0 * anteil, 100.0 * GRENZE,
			100.0 * float(kerbe) / float(maxi(stellen, 1)),
			100.0 * float(im_bild) / float(maxi(stellen, 1))])
	get_tree().quit(0 if stellen > 0 and anteil >= GRENZE else 1)


## Die Kerbe im Schlussbild: wie weit die "kanten" im Bild auseinanderliegen,
## dazu das Kronenband – die Bildzeilen, in denen beide Kronen mit ihren
## Probepunkten liegen – dort misst man die Kerbe im Foto nach (Zeile für
## Zeile die Himmelsstrecke zwischen den Kronen).
func _kerbe_melden(wz: Array, s: float) -> void:
	var band := Vector2(-INF, INF)
	for e: Dictionary in wz:
		if not String(e["name"]).begins_with("Krone"):
			continue
		var k := _kamera_bei(s)
		var oben := INF
		var unten := -INF
		for p: Vector3 in e["punkte"]:
			var b := _bildpunkt(k, p)
			oben = minf(oben, b.y)
			unten = maxf(unten, b.y)
		band = Vector2(maxf(band.x, oben), minf(band.y, unten))
	for e: Dictionary in wz:
		if String(e["name"]) != "Kerbe" or not e.has("kanten"):
			continue
		var kanten: PackedVector3Array = e["kanten"]
		if kanten.size() != 2:
			continue
		var k := _kamera_bei(s)
		var a := _bildpunkt(k, kanten[0])
		var b := _bildpunkt(k, kanten[1])
		var mitte := (kanten[0] + kanten[1]) * 0.5
		print("  Kerbe bei s %.0f: %.1f px waagerecht bei %d Zeilen (Kanten %.2f m auseinander, %.0f m entfernt, im Bild bei x %.0f y %.0f; Kronenband y %.0f … %.0f)"
				% [s, absf(a.x - b.x), int(BILD.y), kanten[0].distance_to(kanten[1]),
				(k["ort"] as Vector3).distance_to(mitte), (a.x + b.x) * 0.5, (a.y + b.y) * 0.5,
				band.x, band.y])


func _punktzahl(wz: Array) -> int:
	var n := 0
	for e: Dictionary in wz:
		n += (e["punkte"] as PackedVector3Array).size()
	return n


# ------------------------------------------------------------- Kamera

## Kamera an der Stelle s, Figur in der Mitte: {"ort", "basis", "tan_h",
## "tan_v", "near", "far"}.
func _kamera_bei(s: float) -> Dictionary:
	var fuss: Vector3 = _level.call("weg_punkt", s, 0.0, 0.0)
	var m := _kamera_modell(fuss)
	var ort := _freie_sicht(m["blick"] as Vector3, m["wunsch"] as Vector3)
	var blick: Vector3 = m["blick"]
	var basis := Basis.looking_at(blick - ort, Vector3.UP)
	var tan_v := tan(deg_to_rad(_kamera.fov) * 0.5)
	return {"ort": ort, "basis": basis, "tan_v": tan_v, "tan_h": tan_v * BILD.x / BILD.y,
			"near": _kamera.near, "far": _kamera.far}


## Wie `level_check.gd` `_kamera_modell` (dort beschrieben): eingeschwungene
## Kamera für eine stehende Figur am Fußpunkt `fuss`.
func _kamera_modell(fuss: Vector3) -> Dictionary:
	var kurve: Curve3D = _level.get("verlauf")
	var zu_welt := _pfad.global_transform if _pfad != null else Transform3D.IDENTITY
	var laenge := kurve.get_baked_length()
	var strecke := kurve.get_closest_offset(zu_welt.affine_inverse() * fuss)
	var mitte := zu_welt * kurve.sample_baked(strecke)
	var versatz := fuss - mitte
	versatz.y = 0.0
	var hoehe_versatz := fuss.y - mitte.y
	var abstand := _kamera.abstand
	var hinten := zu_welt * kurve.sample_baked(clampf(strecke - abstand, 0.0, laenge))
	var wunsch := hinten + Vector3.UP * (hoehe_versatz + _kamera.hoehe) \
			+ versatz * _kamera.seiten_faktor
	var fehlt := 0.0
	var ende := kurve.point_count - 1
	if kurve.get_point_position(0).distance_to(kurve.get_point_position(ende)) >= 12.0:
		fehlt = maxf(abstand - strecke, 0.0)
	var vorlauf := maxf(_kamera.blick_vorlauf
			- KorridorKamera.START_HERANHOLEN * fehlt * fehlt / maxf(abstand, 0.1),
			minf(_kamera.blick_vorlauf, 1.5))
	var blick := zu_welt * kurve.sample_baked(clampf(strecke + vorlauf, 0.0, laenge))
	blick.y = mitte.y + hoehe_versatz + 1.0
	blick += versatz * _kamera.seiten_faktor
	return {"blick": blick, "wunsch": wunsch}


## Wie `level_check.gd` `_freie_sicht`: Strahl vom Blickpunkt zur
## Wunschlage auf den Ebenen der Kamera, die Figur ausgenommen.
func _freie_sicht(blick: Vector3, wunsch: Vector3) -> Vector3:
	var frage := PhysicsRayQueryParameters3D.create(blick, wunsch, _kamera.sicht_maske)
	if _spieler != null:
		frage.exclude = [_spieler.get_rid()]
	var treffer := _raum.intersect_ray(frage)
	if treffer.is_empty():
		return wunsch
	var weg: Vector3 = (treffer["position"] as Vector3) - blick
	var laenge := weg.length()
	if laenge <= KorridorKamera.SICHT_MINDEST:
		return wunsch
	return blick + weg.normalized() * maxf(laenge - KorridorKamera.SICHT_PUFFER,
			KorridorKamera.SICHT_MINDEST)


func _korridorkamera(wurzel: Node) -> KorridorKamera:
	for k in wurzel.find_children("*", "Camera3D", true, false):
		if k is KorridorKamera:
			return k as KorridorKamera
	return null


## Liegt p im Bildstumpf der Kamera k?
func _im_stumpf(k: Dictionary, p: Vector3) -> bool:
	var basis: Basis = k["basis"]
	var v := basis.inverse() * (p - (k["ort"] as Vector3))
	var tiefe := -v.z
	if tiefe <= float(k["near"]) or tiefe >= float(k["far"]):
		return false
	return absf(v.x / tiefe) <= float(k["tan_h"]) and absf(v.y / tiefe) <= float(k["tan_v"])


## Bildpunkt (x nach rechts, y nach unten) von p bei BILD.
func _bildpunkt(k: Dictionary, p: Vector3) -> Vector2:
	var basis: Basis = k["basis"]
	var v := basis.inverse() * (p - (k["ort"] as Vector3))
	var tiefe := maxf(-v.z, 0.001)
	return Vector2(BILD.x * 0.5 + v.x / tiefe / float(k["tan_h"]) * BILD.x * 0.5,
			BILD.y * 0.5 - v.y / tiefe / float(k["tan_v"]) * BILD.y * 0.5)


## Ist der Strahl von der Kamera zu p frei von gezeichneter Geometrie?
func _frei(k: Dictionary, p: Vector3) -> bool:
	var ort: Vector3 = k["ort"]
	var aus: Array[RID] = []
	for v in _verdecker:
		var d := ort.distance_to(v["mitte"] as Vector3)
		var von: float = v["von"]
		var bis: float = v["bis"]
		if d < von or (bis > 0.0 and d > bis):
			aus.append(v["rid"] as RID)
	var frage := PhysicsRayQueryParameters3D.create(ort, p, VERDECKER, aus)
	frage.hit_back_faces = true
	return _raum.intersect_ray(frage).is_empty()


# ------------------------------------------------------------- Verdecker

## Legt die Verdecker an (siehe Kopf) und gibt ihre Zahl zurück.
func _verdecker_anlegen() -> int:
	for knoten in _level.find_children("*", "GeometryInstance3D", true, false):
		var g := knoten as GeometryInstance3D
		if not g.is_visible_in_tree() or _ausgenommen(g):
			continue
		if g.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		var flaechen := PackedVector3Array()
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var lage := g.global_transform
			for p in (g as MeshInstance3D).mesh.get_faces():
				flaechen.append(lage * p)
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			if mm.mesh == null:
				continue
			var roh := mm.mesh.get_faces()
			for i in mm.instance_count:
				var lage := g.global_transform * mm.get_instance_transform(i)
				for p in roh:
					flaechen.append(lage * p)
		if flaechen.size() < 3:
			continue
		var form := ConcavePolygonShape3D.new()
		form.backface_collision = true
		form.set_faces(flaechen)
		var koerper := StaticBody3D.new()
		koerper.collision_layer = VERDECKER
		koerper.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = form
		koerper.add_child(cs)
		add_child(koerper)
		_verdecker.append({"rid": koerper.get_rid(), "von": g.visibility_range_begin,
				"bis": g.visibility_range_end,
				"mitte": (g.global_transform * g.get_aabb()).get_center()})
	return _verdecker.size()


## Wahrzeichen selbst, Kisten, Früchte, Figur, Gegner, Keiler (siehe Kopf).
func _ausgenommen(g: Node) -> bool:
	var n := g
	while n != null and n != _level:
		if n.is_in_group("wahrzeichen") or n.is_in_group("spieler") or n.is_in_group("gegner") \
				or n is Kiste or n is Frucht or n is Keiler:
			return true
		n = n.get_parent()
	return false
