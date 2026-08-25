extends Node3D
## Prüft, ob ein Deckungsfleck den Schwarm wirklich abhält (Level 18).
##
## Der Fleck leuchtete bisher nur: `Deckungsfleck.ist_in_deckung()` gab
## richtige Auskunft, aber niemand fragte danach. Dieser Prüfstand stellt
## die drei Fragen, die darüber entscheiden, ob die Regel des Levels
## überhaupt existiert:
##
##   1. Verfolgt der Schwarm eine AUFRECHT im Fleck stehende Figur?
##      (er muss – sonst wäre der Fleck ein Freibrief zum Danebenstehen)
##   2. Lässt er von ihr ab, sobald sie sich duckt?
##   3. Nimmt sie Schaden, während er über ihr steht und sie geduckt ist?
##      (sie darf nicht – sonst leuchtet der Fleck und schützt trotzdem
##      nicht, und das ist schlimmer als gar kein Fleck)
##
##   godot --headless --path . res://werkzeuge/Deckungstest.tscn

const FLECK_RADIUS := 1.6
## So weit steht der Schwarm anfangs weg: innerhalb seiner Reichweite (9 m),
## aber weit genug, dass "verfolgt" und "verfolgt nicht" messbar auseinander
## liegen.
const SCHWARM_ABSTAND := 6.0

var _spieler: Spieler
var _fleck: Deckungsfleck
var _schwarm: Schwarm
var _leben_verloren := 0
var _fehler := 0


func _ready() -> void:
	_boden()
	var kamera := Camera3D.new()
	kamera.position = Vector3(0.0, 4.0, 9.0)
	add_child(kamera)
	kamera.current = true

	_fleck = preload("res://scenes/props/Deckungsfleck.tscn").instantiate()
	_fleck.radius = FLECK_RADIUS
	add_child(_fleck)
	_fleck.global_position = Vector3.ZERO

	_schwarm = preload("res://scenes/enemies/Schwarm.tscn").instantiate()
	# VOR dem Einhängen stellen: `Gegner` merkt sich in `_ready()` seinen
	# Platz als Heimat. Andersherum wäre die Heimat der Nullpunkt – also
	# genau der Fleck –, und der heimfliegende Schwarm sähe im Protokoll
	# aus wie ein verfolgender. Beim ersten Anlauf ist der Test genau
	# darauf hereingefallen.
	_schwarm.position = Vector3(SCHWARM_ABSTAND, 0.0, 0.0)
	add_child(_schwarm)

	_spieler = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_spieler)
	_spieler.global_position = Vector3(0.0, 0.4, 0.0)

	# Leben mitzählen statt am Ende die Zahl vergleichen: Ein Treffer, der
	# durch eine Schutzladung abgefangen wird, änderte die Lebenszahl nicht.
	GameState.leben_geaendert.connect(func(_n): _leben_verloren += 1)

	for i in 40:
		await get_tree().physics_frame

	print("=== Deckungstest ===")
	await _phase("aufrecht im Fleck", 60, false, true)
	await _phase("geduckt im Fleck", 60, true, false)
	await _ueberflug()

	print("=== %d Abweichungen ===" % _fehler)
	get_tree().quit(1 if _fehler > 0 else 0)


## Lässt den Schwarm `bilder` lang laufen und misst, ob er nähergekommen
## ist. Nicht `_jagt` abfragen: Das wäre die Innensicht des Gegners, und
## der Prüfstand soll das messen, was der Spieler sieht – Abstand.
func _phase(was: String, bilder: int, geduckt: bool, jagt_erwartet: bool) -> void:
	_schwarm.global_position = Vector3(SCHWARM_ABSTAND, 0.0, 0.0)
	var vorher := _abstand()
	for i in bilder:
		InputHub.touch_slide(geduckt)
		await get_tree().physics_frame
	InputHub.touch_slide(false)
	var nachher := _abstand()
	var kam_naeher := nachher < vorher - 0.5
	var passt := kam_naeher == jagt_erwartet and _spieler.kriechen == geduckt
	if not passt:
		_fehler += 1
	print("  %-22s krabbelt %-5s | Abstand %5.2f -> %5.2f m | naehert sich %-5s (erwartet %-5s)%s"
			% [was, str(_spieler.kriechen), vorher, nachher,
			str(kam_naeher), str(jagt_erwartet),
			"" if passt else "  <-- FALSCH"])


## Die eigentliche Frage: Der Schwarm steht MITTEN auf der geduckten
## Figur. Von selbst käme er dort nie hin – deshalb wird er hingesetzt.
## Ohne diesen Zwang prüfte der Test nur die Zielwahl, nicht den Schaden.
func _ueberflug() -> void:
	var vorher := _leben_verloren
	for i in 60:
		InputHub.touch_slide(true)
		_schwarm.global_position = _spieler.global_position
		await get_tree().physics_frame
	InputHub.touch_slide(false)
	var neu := _leben_verloren - vorher
	if neu > 0:
		_fehler += 1
	print("  %-22s krabbelt %-5s | Schwarm auf der Figur | Treffer %d (erwartet 0)%s"
			% ["Schwarm direkt drueber", str(_spieler.kriechen), neu,
			"" if neu == 0 else "  <-- FALSCH"])


func _abstand() -> float:
	var d := _schwarm.global_position - _spieler.global_position
	d.y = 0.0
	return d.length()


func _boden() -> void:
	var koerper := StaticBody3D.new()
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(40.0, 1.0, 40.0)
	form.shape = kasten
	form.position = Vector3(0.0, -0.5, 0.0)
	koerper.add_child(form)
	add_child(koerper)
