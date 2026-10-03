extends Node
## Sprungprobe: Tragen die Pflichtsprünge eines Levels? (Plan P14)
##
## Aufruf (macht `pruefe.sh` in Stufe 4 für jedes Level, das mitmacht):
##   godot --headless --fixed-fps 60 --path . res://werkzeuge/Sprungprobe.tscn \
##       -- res://scenes/levels/Level01.tscn
## Mit `--fixed-fps 60` ist jedes Bild genau ein Physikschritt: Die Probe
## läuft so schnell, wie der Rechner rechnet, und misst bei jedem Lauf
## dasselbe. Ohne den Schalter liefe sie in Echtzeit (rund drei Minuten).
##
## OPT-IN wie die Proben in `level_check.gd`: Geprüft wird nur ein Level,
## das `sprungfaelle() -> Array[Dictionary]` anbietet. Alle anderen melden
## sich ohne Prüfung ab.
##
## Gemessen wird der Mensch, der einfach durchläuft: Die echte Figur rennt
## mit vollem Tempo auf die Lücke zu und springt an einer festen Stelle ab,
## Taste gehalten, Richtung gehalten, kein Doppelsprung. Eine Reihe von
## Absprungstellen im Abstand von 0,25 m ergibt das ABSPRUNGFENSTER: die
## zusammenhängenden Stellen um die Kante, von denen aus die Figur auf
## festem Boden landet (nicht tot, nicht tiefer als 1,5 m unter dem
## Absprung). Gegner gibt es dabei nicht – die Probe misst Sprünge, keine
## Kämpfe.
##
## FEHLER, wenn
##   * der Absprung an der KANTE nicht trägt: Wer bis an den Rand läuft
##     und dort springt wie an jeder anderen Lücke, darf nicht sterben. So
##     ertrank man an der Furt (Welle 6: Kantensprung hinter den ersten
##     Stein, vom Rand des ersten Steins in die Lücke vor dem Ufer);
##   * das Fenster kürzer ist als FENSTER_MIN (1,25 m, gut 0,15 s Lauf).
## Ausgabe je Stelle: "+<s>" gelandet bei s, "x" tot oder in die Lücke
## gefallen, "k" zu kurz (vor `landung`), "?" nie abgesprungen oder nie
## gelandet (etwa vor dem Mooslog hängen geblieben).
##
## Ein Fall (Dictionary aus `sprungfaelle()`):
##   name      Bezeichnung in der Ausgabe
##   start     Vector2(s, q): hier wird die Figur abgesetzt
##   kante     s der Absprungkante (Ende des Bodens, Rand des Steins)
##   von       erste Absprungstelle (s); die Reihe läuft von der Kante in
##             Schritten von 0,25 m bis hierher zurück, dazu eine Stelle
##             0,25 m hinter der Kante (die Figur steht dort noch mit dem
##             Rand ihrer Kapsel)
##   ziel      optional Vector2(s, q): geradewegs auf diesen Punkt zu (und
##             darüber hinaus) statt dem Weg entlang auf der Querlage von
##             `start` – für Diagonalen von Stein zu Stein
##   landung   optional: s, ab dem eine Landung zählt (die andere Seite der
##             Lücke). Wer davor aufkommt – auf einem Wulst in der Lücke,
##             am Fuß der Gegenwand –, ist nicht hinübergekommen, auch wenn
##             er nicht stirbt ("k" in der Ausgabe).
## Die Absprungstellen zählen als Strecke `s` auf dem Levelverlauf, auch
## auf der Diagonale.

const SCHRITT := 0.25
const FENSTER_MIN := 1.25
## Tiefer als das unter dem Absprung gelandet: in die Lücke gefallen.
const ZU_TIEF := 1.5
## Längster Versuch in Physikschritten (10 s).
const VERSUCH_MAX := 600
## Bodenstrahl beim Absetzen: fester Boden und Spielergrenze.
const BODEN_MASKE := 1 | LevelWerkzeuge.SPIELERGRENZE

var _level: Node
var _spieler: CharacterBody3D
var _verlauf: Curve3D
var _tot := false
var _fehler := 0


func _ready() -> void:
	var pfad := "res://scenes/levels/Level01.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	# Die Probe misst immer dieselbe Fassung, egal was in `user://` steht.
	Zeitlauf.aktiv = false
	_level = (load(pfad) as PackedScene).instantiate()
	var fertig := [false]
	if _level.has_signal("aufbau_fertig"):
		_level.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_level)
	var name_kurz := pfad.get_file().get_basename()
	if not _level.has_method("sprungfaelle"):
		print("=== Sprungprobe %s: keine Sprungfälle (nicht angemeldet) ===" % name_kurz)
		get_tree().quit(0)
		return
	var gewartet := 0
	while not fertig[0] and gewartet < 3600:
		gewartet += 1
		await get_tree().physics_frame
	_spieler = get_tree().get_first_node_in_group("spieler") as CharacterBody3D
	var verlauf: Variant = _level.get("verlauf")
	if _spieler == null or not verlauf is Curve3D:
		print("  FEHLER  Sprungprobe: keine Figur oder kein Levelverlauf")
		get_tree().quit(1)
		return
	_verlauf = verlauf as Curve3D
	_spieler.connect("gestorben", func() -> void: _tot = true)
	for g in get_tree().get_nodes_in_group("gegner"):
		g.queue_free()
	for f in 3:
		await get_tree().physics_frame

	print("=== Sprungprobe %s ===" % name_kurz)
	var faelle: Array = _level.call("sprungfaelle")
	if faelle.is_empty():
		# Angemeldet, aber nichts geliefert: Das ist ein Fehler im Level
		# (oder ein Skriptfehler in `sprungfaelle`), kein Freispruch.
		_fehler += 1
		print("  FEHLER  sprungfaelle() lieferte keinen einzigen Fall")
	for fall: Dictionary in faelle:
		await _fall_pruefen(fall)
	print("=== Sprungprobe: %d Fälle, %d Fehler ===" % [faelle.size(), _fehler])
	get_tree().quit(1 if _fehler > 0 else 0)


func _fall_pruefen(fall: Dictionary) -> void:
	var name: String = fall["name"]
	var start: Vector2 = fall["start"]
	var kante: float = fall["kante"]
	var von: float = fall["von"]
	var ziel: Vector2 = fall.get("ziel", Vector2(NAN, NAN))
	var landung: float = fall.get("landung", -INF)
	# Stellen: hinter der Kante, die Kante, dann zurück bis `von`.
	var stellen: Array[float] = [kante + SCHRITT, kante]
	var s := kante - SCHRITT
	while s >= von - 0.001:
		stellen.append(s)
		s -= SCHRITT
	stellen.reverse()
	var zeile := "SPRUNG %-24s" % name
	var gut: Array[bool] = []
	for stelle in stellen:
		var ergebnis := await _versuch(start, ziel, stelle, landung)
		zeile += " %.2f%s" % [stelle, ergebnis]
		gut.append(ergebnis.begins_with("+"))
	print(zeile)
	# Fenster: die zusammenhängenden tragenden Stellen um die Kante.
	var i_kante := stellen.find(kante)
	if not gut[i_kante]:
		_fehler += 1
		print("  FEHLER  %s: Der Absprung an der Kante (s %.2f) trägt nicht" % [name, kante])
		return
	var a := i_kante
	while a > 0 and gut[a - 1]:
		a -= 1
	var b := i_kante
	while b < stellen.size() - 1 and gut[b + 1]:
		b += 1
	var weite := stellen[b] - stellen[a]
	var bis_rand := " (ganze Reihe)" if a == 0 else ""
	if weite < FENSTER_MIN - 0.001:
		_fehler += 1
		print("  FEHLER  %s: Absprungfenster %.2f – %.2f nur %.2f m (mindestens %.2f)"
				% [name, stellen[a], stellen[b], weite, FENSTER_MIN])
	else:
		print("SPRUNG %-24s Fenster %.2f – %.2f (%.2f m%s), Kante %.2f trägt" % [name,
				stellen[a], stellen[b], weite, bis_rand, kante])


## Ein Versuch: bei `start` absetzen, anlaufen, bei `absprung` springen.
## Rückgabe wie im Kopf beschrieben ("+<s>", "x", "k", "?").
func _versuch(start: Vector2, ziel: Vector2, absprung: float, landung: float) -> String:
	InputHub.zuruecksetzen()
	GameState.leben = 50
	_spieler.set("can_djump", false)
	_spieler.velocity = Vector3.ZERO
	_spieler.global_position = _abstellen(start)
	_spieler.reset_physics_interpolation()
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")
	for f in 10:
		await get_tree().physics_frame
	# Diagonale: Richtung auf einen Punkt weit hinter dem Ziel, damit sie
	# sich nicht umkehrt, wenn die Figur das Ziel überfliegt.
	var fern := Vector3.INF
	if not is_nan(ziel.x):
		var a := LevelWerkzeuge.punkt_frei(_verlauf, start.x, start.y)
		var b := LevelWerkzeuge.punkt_frei(_verlauf, ziel.x, ziel.y)
		var richtung := b - a
		richtung.y = 0.0
		fern = a + richtung.normalized() * 60.0
	_tot = false
	var gesprungen := false
	var in_luft := false
	var y_start := _spieler.global_position.y
	for f in VERSUCH_MAX:
		var s := _verlauf.get_closest_offset(_spieler.global_position)
		var hin := fern
		if fern == Vector3.INF:
			hin = LevelWerkzeuge.punkt_frei(_verlauf, s + 3.0, start.y)
		var d := hin - _spieler.global_position
		d.y = 0.0
		InputHub.touch_bewegung = _eingabe_fuer(d.normalized())
		if not gesprungen and s >= absprung and _spieler.is_on_floor():
			InputHub.touch_sprung(true)
			gesprungen = true
			y_start = _spieler.global_position.y
		await get_tree().physics_frame
		if _tot:
			InputHub.zuruecksetzen()
			return "x"
		if gesprungen and not _spieler.is_on_floor():
			in_luft = true
		if in_luft and _spieler.is_on_floor():
			InputHub.zuruecksetzen()
			if _spieler.global_position.y < y_start - ZU_TIEF:
				return "x"
			var s_land := _verlauf.get_closest_offset(_spieler.global_position)
			if s_land < landung:
				return "k"
			return "+%.1f" % s_land
		if _spieler.global_position.y < y_start - 4.0:
			InputHub.zuruecksetzen()
			return "x"
	InputHub.zuruecksetzen()
	return "?"


## Fußpunkt auf dem Boden unter (s, q): Bodenstrahl von 4 m darüber.
func _abstellen(sq: Vector2) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(_verlauf, sq.x, sq.y)
	var anfrage := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 4.0,
			p + Vector3.DOWN * 4.0, BODEN_MASKE, [_spieler.get_rid()])
	var treffer := get_viewport().world_3d.direct_space_state.intersect_ray(anfrage)
	if treffer.is_empty():
		return p + Vector3.UP * 0.3
	return (treffer["position"] as Vector3) + Vector3.UP * 0.05


## Welt-Richtung -> Stick, kamerarelativ wie die echte Steuerung.
func _eingabe_fuer(d: Vector3) -> Vector2:
	var kamera := get_viewport().get_camera_3d()
	var vor := -kamera.global_transform.basis.z
	vor.y = 0.0
	vor = vor.normalized()
	var rechts := kamera.global_transform.basis.x
	rechts.y = 0.0
	rechts = rechts.normalized()
	return Vector2(d.dot(rechts), -d.dot(vor))
