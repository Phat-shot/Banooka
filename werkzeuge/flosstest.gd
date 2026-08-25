extends Node3D
## Prüft, ob eine Wasserplattform den Spieler wirklich mitnimmt.
##
## Das ist die eine Frage, an der Level 03 hängt: Ein Boden, der sich
## bewegt, trägt den Spieler nur dann mit, wenn Godot ihn als bewegte
## Plattform erkennt. Behaupten lässt sich das nicht – gemessen wird der
## Abstand zwischen Spieler und Deckmitte über die ganze Fahrt.
##
##   godot --headless --path . res://werkzeuge/Flosstest.tscn

const FAHRWEG := 24.0      ## Länge der Testfahrt in Metern
const FAHRZEIT := 6.0
const ABWEICHUNG := 0.6    ## so weit darf der Spieler auf dem Deck rutschen

var _spieler: Spieler
var _floss: Wasserplattform
var _bohle: Wasserplattform
var _fehler := 0


func _ready() -> void:
	_boden()
	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 6.0, 14.0)
	add_child(kamera)
	kamera.current = true

	_floss = Wasserplattform.new()
	_floss.art = Wasserplattform.Art.FLOSS
	_floss.groesse = Vector2(4.6, 3.4)
	_floss.punkt_a = Vector3(0.0, 0.6, 0.0)
	_floss.punkt_b = Vector3(FAHRWEG, 0.6, 0.0)
	_floss.fahrzeit = FAHRZEIT
	_floss.pause_a = 1.0
	_floss.pause_b = 1.0
	add_child(_floss)

	_bohle = Wasserplattform.new()
	_bohle.art = Wasserplattform.Art.BOHLE
	_bohle.groesse = Vector2(3.4, 2.6)
	_bohle.punkt_a = Vector3(-8.0, 1.4, 0.0)
	_bohle.punkt_b = Vector3(-8.0, 0.2, 0.0)
	_bohle.fahrzeit = 0.75
	_bohle.pause_a = 1.5
	_bohle.pause_b = 1.0
	_bohle.wippen = 0.0
	add_child(_bohle)

	_spieler = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_spieler)
	print("=== Floßtest ===")

	await _auf_plattform(_floss, "Floss")
	await _mitfahren()
	await _auf_plattform(_bohle, "Wehrbohle")
	await _mitsinken()

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


## Setzt den Spieler auf eine Plattform und lässt ihn landen.
func _auf_plattform(platte: Wasserplattform, was: String) -> void:
	_spieler.velocity = Vector3.ZERO
	_spieler.global_position = platte.global_position \
			+ Vector3(0.0, Wasserplattform.DECK_STAERKE * 0.5 + 0.3, 0.0)
	for i in 40:
		InputHub.touch_bewegung = Vector2.ZERO
		await get_tree().physics_frame
	var hoch := _spieler.global_position.y - platte.global_position.y
	var steht := _spieler.is_on_floor()
	if not steht:
		_fehler += 1
	print("  auf %-10s abgesetzt: steht %-5s, Fusshoehe ueber Deckmitte %+.3f m%s"
			% [was, str(steht), hoch, "" if steht else "  <-- steht nicht"])


## Fährt die ganze Strecke mit und misst dabei den Versatz.
func _mitfahren() -> void:
	var groesster := 0.0
	var weg_anfang := _floss.global_position.x
	for i in int(FAHRZEIT * 60.0) + 90:
		await get_tree().physics_frame
		var versatz := absf(_spieler.global_position.x - _floss.global_position.x)
		groesster = maxf(groesster, versatz)
		if _spieler.global_position.y < _floss.global_position.y - 0.5:
			break
	var mitgefahren := _floss.global_position.x - weg_anfang
	var gehalten := groesster <= ABWEICHUNG \
			and absf(_spieler.global_position.x - _floss.global_position.x) <= ABWEICHUNG
	if not gehalten:
		_fehler += 1
	print("  Fahrt: Floss legte %+.1f m zurueck, groesster Versatz %.3f m%s"
			% [mitgefahren, groesster,
			"" if gehalten else "  <-- Spieler blieb zurueck"])


## Prüft, ob der Spieler mit der Bohle nach unten geht statt zu schweben.
func _mitsinken() -> void:
	var tiefste := INF
	var hoechste := -INF
	for i in 260:
		await get_tree().physics_frame
		var abstand := _spieler.global_position.y - _bohle.global_position.y
		tiefste = minf(tiefste, abstand)
		hoechste = maxf(hoechste, abstand)
	var haftet := (hoechste - tiefste) < 0.35
	if not haftet:
		_fehler += 1
	print("  Sinken: Abstand zur Bohle schwankte zwischen %+.3f und %+.3f m%s"
			% [tiefste, hoechste, "" if haftet else "  <-- Spieler haengt in der Luft"])


func _boden() -> void:
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(80.0, 1.0, 20.0)
	form.shape = kasten
	form.position = Vector3(10.0, -3.5, 0.0)
	koerper.add_child(form)
	add_child(koerper)
