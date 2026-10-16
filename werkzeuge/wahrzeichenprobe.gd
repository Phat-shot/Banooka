extends Node
## Wahrzeichenprobe: Steht das Wahrzeichen eines Levels im Bild – und ist es
## dort frei? (Level 05, die Hauereiche; Entwurf L05 §11 Nr. 7, §7.1 K3,
## §8.2, Paket P4)
##
## Aufruf:
##   godot --headless --path . res://werkzeuge/Wahrzeichenprobe.tscn \
##       -- res://scenes/levels/Level05.tscn
## Rückgabe 1, wenn der Anteil unter GRENZE liegt, der SELBSTTEST einen
## Fehler findet oder die Probe nichts messen konnte.
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
## Einträge, deren Name mit "Krone" beginnt, sind die Kronen; ihre Punkte
## müssen IM Laub liegen (siehe SELBSTTEST), über die Krone verteilt. Ein
## Eintrag "Kerbe" ist der Himmelsspalt dazwischen und darf "kanten" tragen
## (die beiden innersten Ecken der Kronen). Die Stellen kommen aus
## `wahrzeichen_strecke() -> Vector2(von, bis)`, sonst `start_strecke` bis
## `ende()`; Schritt SCHRITT.
##
## JE STELLE s: die Figur in der Mitte des Weges (`weg_punkt(s, 0)`), die
## Kamera nach dem Modell aus `werkzeuge/level_check.gd` (`_kamera_modell`,
## `_freie_sicht`: eingeschwungen, auf den Ebenen der Kamera), mit dem
## Sichtfeld der Kamera im Seitenverhältnis 16:9 (1280 × 720) und ihrem
## `near`/`far`. Ein Punkt zählt, wenn er im Bildstumpf liegt und der Strahl
## von der Kamera zu ihm frei ist.
##   „frei im Bild"  bei jeder Krone zählt mindestens der Anteil
##                   KRONE_ANTEIL ihrer Punkte – das Maß der Abnahme (Anteil
##                   der Stellen ≥ GRENZE). Mit „ein Punkt genügt" zählte eine
##                   Krone, deren Laub bis auf einen Ballen zugedeckt ist.
##   „Kerbe frei"    ein Punkt der Kerbe zählt
##   „im Bild"       wie „frei im Bild", aber ohne Verdeckung (Vergleich mit
##                   der Rechnung des Entwurfs)
##
## SELBSTTEST: Ein Kronenpunkt, der in der Luft neben der Krone liegt, misst
## freien Himmel statt Laub (Prüfung P4: die alten Punkte auf 0,6 der halben
## Hülle lagen bei Kronen aus Ballen teils daneben). Die Netze des
## Wahrzeichens liegen dafür auf der Ebene EIGEN, mit ihrer Sichtweite.
##   innen   vorab, je Kronenpunkt und je Fassung des Wahrzeichens (je
##           Sichtweite eine, nah und fern): Jeder Strahl vom Punkt in die
##           sechs Achsrichtungen trifft ein Netz dieser Fassung – der
##           Punkt ist rundum von Laub umschlossen, auch oben und hinten.
##   Blick   an jeder Stelle: Der Strahl von der Kamera zu jedem
##           Kronenpunkt im Bildstumpf trifft das Wahrzeichen selbst, in der
##           Fassung, die bei diesem Abstand gezeichnet wird.
## Jeder Verstoß ist ein FEHLER.
##
## VERDECKUNG: alle sichtbaren Netze des Levels (MeshInstance3D und
## MultiMeshInstance3D samt allen Instanzen), außer dem Wahrzeichen selbst
## (Gruppe "wahrzeichen", es liegt auf EIGEN für den Selbsttest), Kisten und
## Früchten (flüchtig, und im Bild unten), Figur, Gegnern und Verfolger
## (Gruppen "spieler", "gegner", der `Keiler` steht in keiner) und reinen
## Schattenkörpern. Sie werden für die Probe als Dreiecksflächen auf die
## Ebene VERDECKER gelegt (eigene Körper, ohne Wirkung auf das Spiel). Wer
## eine Sichtweite hat (`visibility_range_begin/end`, Abstand Kamera – Mitte
## der Hülle, `custom_aabb` des Knotens vor der des Netzes), verdeckt nur
## dort, wo er gezeichnet wird.
##
## AUSGABE: je ZEILE_JE Stellen eine Zeile (mit dem Abstand der Kamera zur
## Mitte der Hülle des Wahrzeichens – danach wechselt es nah und fern), jede
## Spanne ohne freie Kronen, die Kerbe im Schlussbild (Stelle `bis`) in
## Bildpunkten bei 720 Zeilen –
## wie weit die "kanten" im Bild waagerecht auseinanderliegen; liegen sie
## verschieden hoch, ist der Spalt in jeder Bildzeile mindestens so breit –
## und zuletzt
##   === Wahrzeichenprobe <Level>: n von N Stellen (p %) frei im Bild …;
##       Selbsttest i von m Kronenpunkten innen, b Blicke, k nicht aufs Laub ===

## Abstand der Stellen (Entwurf P4: s 6 … 296 im Schritt 2 m).
const SCHRITT := 2.0
## Mindestanteil der Stellen, an denen beide Kronen frei im Bild stehen
## (Entwurf §11 Nr. 7).
const GRENZE := 0.7
## Je Krone muss mindestens dieser Anteil ihrer Punkte frei im Bild sein
## (aufgerundet: von 5 Punkten 3).
const KRONE_ANTEIL := 0.5
## Bildgröße, für die gemessen wird (16:9, Kerbe in Bildpunkten).
const BILD := Vector2(1280.0, 720.0)
## Ebene der Verdeckungskörper: Ebene 30, die sonst niemand benutzt.
const VERDECKER := 1 << 29
## Ebene der Körper des Wahrzeichens selbst (Selbsttest): Ebene 29, die
## sonst ebenfalls niemand benutzt.
const EIGEN := 1 << 28
## So viele Selbsttest-Fehler werden einzeln gemeldet, der Rest gezählt.
const MELDUNGEN := 10
## Länge der Strahlen des Innen-Tests (m), weit über jede Krone hinaus.
const INNEN_WEIT := 60.0
const ACHSEN: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
		Vector3.FORWARD, Vector3.BACK]
## Eine Zeile je so viele Stellen.
const ZEILE_JE := 10

var _level: Node3D
var _kamera: KorridorKamera
var _pfad: Path3D
var _spieler: CollisionObject3D
var _raum: PhysicsDirectSpaceState3D
## Verdecker: je Netz {"rid", "von", "bis", "mitte"} (Sichtweite, Mitte der Hülle).
var _verdecker: Array[Dictionary] = []
## Dasselbe für die Netze des Wahrzeichens (Ebene EIGEN).
var _eigene: Array[Dictionary] = []
## Innen-Test (SELBSTTEST): geprüfte Kronenpunkte, davon innen.
var _innen_zahl := 0
var _innen_gut := 0


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
	print("=== Wahrzeichenprobe %s: s %.0f … %.0f im Schritt %.0f m, %d Verdecker, %d Netze des Wahrzeichens, %d Probepunkte ==="
			% [name_kurz, strecke.x, strecke.y, SCHRITT, netze, _eigene.size(), _punktzahl(wz)])
	if _eigene.is_empty():
		print("  FEHLER  Wahrzeichenprobe: keine Netze in der Gruppe \"wahrzeichen\" – kein Selbsttest möglich")
	else:
		_innen_pruefen(wz)
	_messen(name_kurz, wz, strecke)


# ------------------------------------------------------------- Messung

func _messen(name_kurz: String, wz: Array, strecke: Vector2) -> void:
	var stellen := 0
	var frei := 0
	var im_bild := 0
	var kerbe := 0
	var luecken: Array[Vector2] = []
	var luecke := Vector2(NAN, NAN)
	var selbst_geprueft := 0
	var selbst_fehler := 0
	var s := strecke.x
	while s <= strecke.y + 0.001:
		var k := _kamera_bei(s)
		var kronen_frei := true
		var kronen_bild := true
		var kerbe_frei := false
		var zeile := PackedStringArray()
		for e: Dictionary in wz:
			var name_e := String(e["name"])
			var krone := name_e.begins_with("Krone")
			var n_bild := 0
			var n_frei := 0
			var punkte: PackedVector3Array = e["punkte"]
			for j in punkte.size():
				var p := punkte[j]
				if _im_stumpf(k, p):
					n_bild += 1
					if _frei(k, p):
						n_frei += 1
					if krone:
						selbst_geprueft += 1
						if not _im_laub(k, p):
							selbst_fehler += 1
							if selbst_fehler <= MELDUNGEN:
								print("  FEHLER  Selbsttest bei s %.0f: %s, Punkt %d %s – der Blick der Kamera trifft das Wahrzeichen nicht"
										% [s, name_e, j, str(p.snappedf(0.1))])
			if krone:
				var noetig := ceili(KRONE_ANTEIL * float(punkte.size()))
				kronen_frei = kronen_frei and n_frei >= noetig
				kronen_bild = kronen_bild and n_bild >= noetig
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
			print("  s %5.1f  %s  (frei/im Bild; Kamera %s, %.0f m vor dem Wahrzeichen)"
					% [s, ", ".join(zeile), str(k["ort"].snappedf(0.1)), _abstand(k)])
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
	if selbst_fehler > MELDUNGEN:
		print("  FEHLER  Selbsttest: %d weitere Blicke nicht aufs Laub" % (selbst_fehler - MELDUNGEN))
	if selbst_geprueft == 0:
		print("  FEHLER  Selbsttest: kein Kronenpunkt im Bild geprüft")
	print("=== Wahrzeichenprobe %s: %d von %d Stellen (%.1f %%) frei im Bild (Grenze %.0f %%, je Krone %.0f %% der Punkte); Kerbe frei %.1f %%; ohne Verdeckung im Bild %.1f %%; Selbsttest %d von %d Kronenpunkten innen, %d Blicke, %d nicht aufs Laub ==="
			% [name_kurz, frei, stellen, 100.0 * anteil, 100.0 * GRENZE, 100.0 * KRONE_ANTEIL,
			100.0 * float(kerbe) / float(maxi(stellen, 1)),
			100.0 * float(im_bild) / float(maxi(stellen, 1)), _innen_gut, _innen_zahl,
			selbst_geprueft, selbst_fehler])
	var gut := stellen > 0 and anteil >= GRENZE and selbst_fehler == 0 and selbst_geprueft > 0 \
			and not _eigene.is_empty() and _innen_gut == _innen_zahl and _innen_zahl > 0
	get_tree().quit(0 if gut else 1)


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
	return not _trifft(k, p, VERDECKER, _verdecker)


## Selbsttest „innen" (siehe Kopf) für alle Kronenpunkte; je Verstoß eine
## Zeile FEHLER.
func _innen_pruefen(wz: Array) -> void:
	for e: Dictionary in wz:
		var name_e := String(e["name"])
		if not name_e.begins_with("Krone"):
			continue
		var punkte: PackedVector3Array = e["punkte"]
		for j in punkte.size():
			_innen_zahl += 1
			var fehlt := _innen_fehlt(punkte[j])
			if fehlt.is_empty():
				_innen_gut += 1
			else:
				print("  FEHLER  Selbsttest: %s, Punkt %d %s liegt nicht im Laub (%s)"
						% [name_e, j, str(punkte[j].snappedf(0.1)), fehlt])


## Leer, wenn p in jeder Fassung des Wahrzeichens rundum von dessen Netzen
## umschlossen ist; sonst, in welcher Fassung und Richtung nicht. Eine
## Fassung je Sichtweite (von, bis); Netze ohne Sichtweite gehören zu allen.
func _innen_fehlt(p: Vector3) -> String:
	var fassungen: Array[Vector2] = []
	for v in _eigene:
		var r := Vector2(float(v["von"]), float(v["bis"]))
		if r != Vector2.ZERO and not fassungen.has(r):
			fassungen.append(r)
	if fassungen.is_empty():
		fassungen.append(Vector2.ZERO)
	for f in fassungen:
		var aus: Array[RID] = []
		for v in _eigene:
			var r := Vector2(float(v["von"]), float(v["bis"]))
			if r != Vector2.ZERO and r != f:
				aus.append(v["rid"] as RID)
		for richtung in ACHSEN:
			var frage := PhysicsRayQueryParameters3D.create(p, p + richtung * INNEN_WEIT, EIGEN, aus)
			frage.hit_back_faces = true
			if _raum.intersect_ray(frage).is_empty():
				return "Fassung %.0f … %.0f m: Richtung %s frei" % [f.x, f.y, str(richtung)]
	return ""


## Selbsttest: Trifft der Strahl von der Kamera zu p das Wahrzeichen selbst
## (in der Fassung, die bei diesem Abstand gezeichnet wird)? Ein Punkt im
## Laub liegt hinter dessen Außenhaut, von jeder Kamera aus.
func _im_laub(k: Dictionary, p: Vector3) -> bool:
	return _trifft(k, p, EIGEN, _eigene)


## Trifft der Strahl von der Kamera zu p einen der `koerper` auf `ebene`,
## die bei diesem Abstand gezeichnet werden?
func _trifft(k: Dictionary, p: Vector3, ebene: int, koerper: Array[Dictionary]) -> bool:
	var ort: Vector3 = k["ort"]
	var aus: Array[RID] = []
	for v in koerper:
		var d := ort.distance_to(v["mitte"] as Vector3)
		var von: float = v["von"]
		var bis: float = v["bis"]
		if d < von or (bis > 0.0 and d > bis):
			aus.append(v["rid"] as RID)
	var frage := PhysicsRayQueryParameters3D.create(ort, p, ebene, aus)
	frage.hit_back_faces = true
	return not _raum.intersect_ray(frage).is_empty()


## Abstand der Kamera k zur Mitte der Hülle des Wahrzeichens (der kleinste
## über seine Netze).
func _abstand(k: Dictionary) -> float:
	var d := INF
	for v in _eigene:
		d = minf(d, (k["ort"] as Vector3).distance_to(v["mitte"] as Vector3))
	return d


# ------------------------------------------------------------- Verdecker

## Legt die Verdecker an (siehe Kopf) und gibt ihre Zahl zurück; die Netze
## des Wahrzeichens kommen auf die Ebene EIGEN (`_eigene`).
func _verdecker_anlegen() -> int:
	for knoten in _level.find_children("*", "GeometryInstance3D", true, false):
		var g := knoten as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var eigen := _im_wahrzeichen(g)
		if not eigen and _ausgenommen(g):
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
		koerper.collision_layer = EIGEN if eigen else VERDECKER
		koerper.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = form
		koerper.add_child(cs)
		add_child(koerper)
		# Sichtweite wie Godot: Abstand zur Mitte der Hülle, die Hülle des
		# Knotens (custom_aabb) vor der des Netzes.
		var huelle := g.custom_aabb if g.custom_aabb.has_volume() else g.get_aabb()
		var eintrag := {"rid": koerper.get_rid(), "von": g.visibility_range_begin,
				"bis": g.visibility_range_end, "mitte": (g.global_transform * huelle).get_center()}
		if eigen:
			_eigene.append(eintrag)
		else:
			_verdecker.append(eintrag)
	return _verdecker.size()


## Gehört g zum Wahrzeichen (Gruppe "wahrzeichen")?
func _im_wahrzeichen(g: Node) -> bool:
	var n := g
	while n != null and n != _level:
		if n.is_in_group("wahrzeichen"):
			return true
		n = n.get_parent()
	return false


## Kisten, Früchte, Figur, Gegner, Keiler (siehe Kopf).
func _ausgenommen(g: Node) -> bool:
	var n := g
	while n != null and n != _level:
		if n.is_in_group("spieler") or n.is_in_group("gegner") \
				or n is Kiste or n is Frucht or n is Keiler:
			return true
		n = n.get_parent()
	return false
