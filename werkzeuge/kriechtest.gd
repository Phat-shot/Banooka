extends Node3D
## Prüft das Krabbeln an einem kleinen Testaufbau: Boden, ein tiefer
## Vorsprung, ein Spieler.
##
## Drei Fragen lassen sich nur in Bewegung beantworten:
##   1. Krabbelt die Figur, solange die Taste gehalten wird – und richtet
##      sie sich beim Loslassen wieder auf?
##   2. Bleibt sie unter dem tiefen Vorsprung unten, auch ohne Taste?
##   3. Sinkt sie dabei in den Boden?
##
##   godot --headless --path . res://werkzeuge/Kriechtest.tscn

const DECKE_VON := 4.0     ## Der Vorsprung beginnt bei dieser x-Stelle
const DECKE_BIS := 11.0
const DECKE_HOEHE := 0.95  ## Unterkante – zu tief zum Stehen, hoch genug zum Krabbeln
const RAMPE_VON := 16.0    ## Danach geht es eine Schräge hinauf
const RAMPE_NEIGUNG := 28.0

var _spieler: Spieler
var _skelett: Skeleton3D
var _fehler := 0


func _ready() -> void:
	_boden()
	_vorsprung()
	_rampe()
	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 3.0, 8.0)
	add_child(kamera)
	kamera.current = true

	_spieler = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_spieler)
	_spieler.global_position = Vector3(0.0, 0.4, 0.0)
	for i in 30:
		await get_tree().physics_frame
	_skelett = _skelett_suchen(_spieler)

	print("=== Krabbeltest ===")
	await _schritt("steht, keine Taste", 30, false, Vector2.ZERO, false)
	await _schritt("Taste gehalten", 20, true, Vector2.ZERO, true)
	await _schritt("krabbelt vorwaerts", 25, true, Vector2(1.0, 0.0), true)
	await _schritt("Taste losgelassen", 20, false, Vector2.ZERO, false)
	# Aufrecht bis kurz vor den Vorsprung. Mit gehaltener Taste wäre das
	# ein Slide – deshalb erst hinlaufen, dann anhalten, dann krabbeln.
	await _bis_x("laeuft zum Vorsprung", DECKE_VON - 0.9, false, false)
	await _schritt("haelt an und drueckt", 20, true, Vector2.ZERO, true)
	await _bis_x("krabbelt darunter", DECKE_VON + 2.0, true, true)
	await _bis_x("Taste los, Decke tief", DECKE_BIS - 1.0, false, true)
	await _bis_x("wieder im Freien", DECKE_BIS + 2.5, false, false)
	await _schritt("richtet sich auf", 20, false, Vector2.ZERO, false)

	# Am Hang darf die Stehprobe den ansteigenden Boden nicht für eine
	# Decke halten – sonst bliebe die Figur an jeder Schräge unten kleben.
	await _bis_x("laeuft die Rampe hoch", RAMPE_VON + 5.0, false, false)
	await _schritt("steht am Hang", 20, false, Vector2.ZERO, false)

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


## Ein Abschnitt: Taste und Richtung setzen, laufen lassen, dann melden.
func _schritt(was: String, bilder: int, taste: bool, richtung: Vector2,
		erwartet: bool) -> void:
	var tiefster := INF
	for i in bilder:
		InputHub.touch_slide(taste)
		InputHub.touch_bewegung = richtung
		await get_tree().physics_frame
		tiefster = minf(tiefster, _fusshoehe())
	InputHub.touch_slide(false)
	InputHub.touch_bewegung = Vector2.ZERO
	_melden(was, erwartet, tiefster)


## Eine Zeile Protokoll und die Buchführung über Abweichungen.
func _melden(was: String, erwartet: bool, tiefster: float) -> void:
	var passt := _spieler.kriechen == erwartet
	if not passt:
		_fehler += 1
	if tiefster < -0.02:
		_fehler += 1
	print("  %-24s x %5.1f m | krabbelt %-5s (erwartet %-5s)%s | Fuss tiefstens %+.3f m%s"
			% [was, _spieler.global_position.x,
			str(_spieler.kriechen), str(erwartet),
			"" if passt else "  <-- FALSCH",
			tiefster, "  <-- IM BODEN" if tiefster < -0.02 else ""])


## Wie _schritt, aber bis zu einer x-Stelle statt über eine Bilderzahl.
func _bis_x(was: String, ziel_x: float, taste: bool, erwartet: bool) -> void:
	var tiefster := INF
	var bilder := 0
	while _spieler.global_position.x < ziel_x and bilder < 600:
		InputHub.touch_slide(taste)
		InputHub.touch_bewegung = Vector2(1.0, 0.0)
		await get_tree().physics_frame
		tiefster = minf(tiefster, _fusshoehe())
		bilder += 1
	InputHub.touch_slide(false)
	InputHub.touch_bewegung = Vector2.ZERO
	_melden(was, erwartet, tiefster)


## Tiefster Knochen der Figur in Weltmaßen. Die Netzhülle taugt dafür
## nicht: Godot meldet bei Häuten immer die Hülle der Ruhepose.
func _fusshoehe() -> float:
	if _skelett == null:
		return 0.0
	var tief := INF
	for i in _skelett.get_bone_count():
		var pos := (_skelett.global_transform
				* _skelett.get_bone_global_pose(i)).origin
		tief = minf(tief, pos.y)
	return tief


func _skelett_suchen(knoten: Node) -> Skeleton3D:
	if knoten is Skeleton3D:
		return knoten
	for kind in knoten.get_children():
		var gefunden := _skelett_suchen(kind)
		if gefunden != null:
			return gefunden
	return null


func _boden() -> void:
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(80.0, 1.0, 20.0)
	form.shape = kasten
	form.position = Vector3(20.0, -0.5, 0.0)
	koerper.add_child(form)
	add_child(koerper)


## Eine schiefe Ebene hinter dem Vorsprung.
func _rampe() -> void:
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(30.0, 1.0, 10.0)
	form.shape = kasten
	form.rotation = Vector3(0.0, 0.0, deg_to_rad(RAMPE_NEIGUNG))
	form.position = Vector3(RAMPE_VON + 13.0,
			tan(deg_to_rad(RAMPE_NEIGUNG)) * 13.0 - 0.5, 0.0)
	koerper.add_child(form)
	add_child(koerper)


func _vorsprung() -> void:
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	var tiefe := DECKE_BIS - DECKE_VON
	kasten.size = Vector3(tiefe, 2.0, 8.0)
	form.shape = kasten
	form.position = Vector3(DECKE_VON + tiefe * 0.5, DECKE_HOEHE + 1.0, 0.0)
	koerper.add_child(form)
	add_child(koerper)
