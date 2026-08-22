extends Area3D
class_name Frucht
## Sammelbare Waldfrucht. 100 Stück ergeben ein Extraleben.
##
## Früchte können frei im Level stehen oder von zerbrochenen Kisten
## erzeugt werden (siehe `streuen`).

const FRUCHT_SZENE := preload("res://scenes/fruits/Frucht.tscn")

## Anziehungsradius: ab hier fliegt die Frucht zum Spieler.
const MAGNET_RADIUS := 2.6
const MAGNET_TEMPO := 9.0

## Anfangsgeschwindigkeit, wenn die Frucht aus einer Kiste geschleudert wird.
var wurf := Vector3.ZERO
## Solange > 0 fliegt die Frucht frei und wird nicht angezogen.
var _flugzeit := 0.0
var _phase := 0.0
var _eingesammelt := false

@onready var _modell: Node3D = $Modell


func _ready() -> void:
	_baue_modell()
	add_to_group("fruechte")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	body_entered.connect(_auf_koerper)
	_phase = randf() * TAU
	if wurf != Vector3.ZERO:
		_flugzeit = 0.6


## Baut die Frucht prozedural auf: Beere mit Glanz und kleinem Blatt.
func _baue_modell() -> void:
	var beere := SphereMesh.new()
	beere.radius = 0.24
	beere.height = 0.48
	beere.radial_segments = 12
	beere.rings = 8
	var mi := MeshInstance3D.new()
	mi.name = "Beere"
	mi.mesh = beere
	mi.material_override = Materialbibliothek.leuchtend(Farben.FRUCHT, 0.45)
	_modell.add_child(mi)

	var blatt := PrismMesh.new()
	blatt.size = Vector3(0.22, 0.16, 0.03)
	var bi := MeshInstance3D.new()
	bi.name = "Blatt"
	bi.mesh = blatt
	bi.material_override = Materialbibliothek.einfarbig(Farben.FRUCHT_BLATT)
	bi.position = Vector3(0.05, 0.28, 0.0)
	bi.rotation_degrees = Vector3(0.0, 0.0, -25.0)
	_modell.add_child(bi)


func _process(delta: float) -> void:
	if _eingesammelt:
		return

	_phase += delta * 3.0
	if is_instance_valid(_modell):
		_modell.rotation.y += delta * 2.6
		_modell.position.y = sin(_phase) * 0.12

	if _flugzeit > 0.0:
		# Frisch aus einer Kiste geschleudert: kurzer Wurfbogen
		_flugzeit -= delta
		wurf.y += -24.0 * delta
		global_position += wurf * delta
		return

	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return
	var ziel := spieler.global_position + Vector3.UP * 0.6
	var abstand := global_position.distance_to(ziel)
	if abstand < MAGNET_RADIUS:
		global_position = global_position.move_toward(ziel, MAGNET_TEMPO * delta)
		if abstand < 0.5:
			_einsammeln()


func _auf_koerper(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler"):
		_einsammeln()


func _einsammeln() -> void:
	if _eingesammelt:
		return
	_eingesammelt = true
	GameState.frucht_einsammeln(1)
	queue_free()


## Erzeugt `anzahl` Früchte an `pos` und schleudert sie auseinander.
static func streuen(elternteil: Node, pos: Vector3, anzahl: int = 1) -> void:
	if elternteil == null or not is_instance_valid(elternteil):
		return
	for i in anzahl:
		var f := FRUCHT_SZENE.instantiate() as Frucht
		var winkel := TAU * float(i) / maxf(float(anzahl), 1.0) + randf() * 0.6
		var streuung := 2.2 if anzahl > 1 else 0.0
		f.wurf = Vector3(cos(winkel) * streuung, 5.0 + randf() * 1.5, sin(winkel) * streuung)
		elternteil.add_child(f)
		f.global_position = pos + Vector3.UP * 0.3
