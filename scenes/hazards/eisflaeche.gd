extends Node3D
class_name Eisflaeche
## Blankes Eis zum Schlittern.
##
## Zwei Teile: eine sichtbare Platte und eine Zone darüber. Wer in der Zone
## steht, bekommt `glaette` gesetzt – der Spieler nimmt dann Tempo nur noch
## träge auf und baut es genauso träge ab. Die Physikwerte selbst bleiben
## unberührt; Eis ändert nicht das Lauftempo, nur wie schnell es erreicht
## wird (siehe `Spieler.EIS_GRIFF`).
##
## Mehrere Flächen dürfen sich überlappen: Der Spieler führt sie als Liste
## und nimmt die glatteste. Sonst schaltete das Verlassen der einen die
## andere mit ab.

## Ausdehnung der Fläche in Metern (x = quer, y = längs).
@export var flaeche := Vector2(6.0, 8.0):
	set(wert):
		flaeche = wert
		if is_inside_tree():
			_aufbauen()

## 0 = normaler Grip, 1 = blankes Eis.
@export_range(0.0, 1.0, 0.05) var glaette := 0.85

## Höhe der Zone über der Platte – hoch genug, dass ein Sprung darüber
## nicht sofort als "vom Eis herunter" zählt.
const ZONE_HOEHE := 1.6
## Dicke der sichtbaren Platte.
const DICKE := 0.06

var _zone: Area3D
var _platte: MeshInstance3D


func _ready() -> void:
	add_to_group("eisflaechen")
	_aufbauen()


func _aufbauen() -> void:
	if _platte == null:
		_platte = MeshInstance3D.new()
		_platte.name = "Platte"
		add_child(_platte)
	var kasten := BoxMesh.new()
	kasten.size = Vector3(flaeche.x, DICKE, flaeche.y)
	_platte.mesh = kasten
	_platte.material_override = Materialbibliothek.eis()
	_platte.position.y = DICKE * 0.5

	if _zone == null:
		_zone = Area3D.new()
		_zone.name = "Zone"
		_zone.collision_layer = 0
		_zone.collision_mask = 2
		_zone.body_entered.connect(_auf_eintritt)
		_zone.body_exited.connect(_auf_austritt)
		add_child(_zone)
		var form := CollisionShape3D.new()
		form.name = "Form"
		_zone.add_child(form)
	var form_knoten := _zone.get_node("Form") as CollisionShape3D
	var kasten_form := BoxShape3D.new()
	kasten_form.size = Vector3(flaeche.x, ZONE_HOEHE, flaeche.y)
	form_knoten.shape = kasten_form
	form_knoten.position.y = ZONE_HOEHE * 0.5


func _auf_eintritt(koerper: Node3D) -> void:
	if koerper.has_method("betritt_eis"):
		koerper.call("betritt_eis", get_instance_id(), glaette)


func _auf_austritt(koerper: Node3D) -> void:
	if koerper.has_method("verlaesst_eis"):
		koerper.call("verlaesst_eis", get_instance_id())
