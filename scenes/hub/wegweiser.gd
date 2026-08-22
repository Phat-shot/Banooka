extends Node3D
class_name Wegweiser
## Schwebender Pfeil über dem Spieler, der auf das nächste offene
## Levelportal zeigt.
##
## Im Portalraum ist von den 25 Toren zunächst nur eines offen. Ohne
## Hinweis muss man alle fünf Räume ablaufen, um es zu finden.
## Der Pfeil blendet aus, sobald man nah genug dran ist.

## Höhe über dem Spieler.
@export var hoehe := 2.5
## Ab diesem Abstand ist der Pfeil ganz ausgeblendet.
@export var ausblenden_ab := 6.0
## Ab diesem Abstand ist er voll sichtbar.
@export var voll_ab := 11.0
## Wie schnell er sich zum Ziel dreht (Anteil je Sekunde).
@export var drehtempo := 6.0

var _spieler: Node3D
var _ziel: Node3D
var _material: StandardMaterial3D
var _phase := 0.0
var _sichtbarkeit := 0.0


## Größer als lebensgroß, damit der Pfeil aus der Verfolgerkamera auffällt.
## Skaliert werden die Teile, NICHT dieser Knoten: seine Basis muss
## normalisiert bleiben, sonst kann sie nicht mehr geslerpt werden.
const GROESSE := 1.45

func _ready() -> void:
	_baue()
	_phase = randf() * TAU


func _baue() -> void:
	_material = Materialbibliothek.leuchtend(Farben.PORTAL_START, 1.8).duplicate()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Immer sichtbar, auch wenn eine Mauer dazwischen steht – der Pfeil
	# soll ja gerade den Weg durch den Raum weisen.
	_material.no_depth_test = true
	_material.render_priority = 4

	# Schaft
	var schaft := BoxMesh.new()
	schaft.size = Vector3(0.17, 0.17, 0.52)
	var schaft_knoten := MeshInstance3D.new()
	schaft_knoten.name = "Schaft"
	schaft_knoten.mesh = schaft
	schaft_knoten.position.z = 0.3 * GROESSE
	schaft_knoten.scale = Vector3.ONE * GROESSE
	schaft_knoten.material_override = _material
	add_child(schaft_knoten)

	# Spitze: Kegel, der nach -Z zeigt (Blickrichtung in Godot)
	var spitze := CylinderMesh.new()
	spitze.top_radius = 0.0
	spitze.bottom_radius = 0.28
	spitze.height = 0.46
	spitze.radial_segments = 8
	var spitze_knoten := MeshInstance3D.new()
	spitze_knoten.name = "Spitze"
	spitze_knoten.mesh = spitze
	spitze_knoten.rotation_degrees.x = -90.0
	spitze_knoten.position.z = -0.2 * GROESSE
	spitze_knoten.scale = Vector3.ONE * GROESSE
	spitze_knoten.material_override = _material
	add_child(spitze_knoten)


func _process(delta: float) -> void:
	_phase += delta * 2.4

	if _spieler == null or not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null:
			_setze_sichtbarkeit(0.0, delta)
			return

	_ziel = _naechstes_offenes_portal()
	if _ziel == null:
		_setze_sichtbarkeit(0.0, delta)
		return

	# Über dem Spieler schweben, mit leichtem Auf und Ab
	global_position = _spieler.global_position \
			+ Vector3.UP * (hoehe + sin(_phase) * 0.13)

	# Zum Ziel drehen, waagerecht
	var blick := _ziel.global_position
	blick.y = global_position.y
	if global_position.distance_squared_to(blick) > 0.01:
		var soll := Transform3D(basis, global_position).looking_at(blick, Vector3.UP)
		basis = basis.orthonormalized().slerp(soll.basis.orthonormalized(),
				clampf(drehtempo * delta, 0.0, 1.0))

	# Nahe am Ziel ausblenden
	var abstand := _spieler.global_position.distance_to(_ziel.global_position)
	var ziel_alpha := clampf(
			inverse_lerp(ausblenden_ab, voll_ab, abstand), 0.0, 1.0)
	_setze_sichtbarkeit(ziel_alpha, delta)


func _setze_sichtbarkeit(ziel_alpha: float, delta: float) -> void:
	_sichtbarkeit = move_toward(_sichtbarkeit, ziel_alpha, delta * 2.5)
	visible = _sichtbarkeit > 0.01
	if _material != null:
		# Leichtes Pulsieren, damit er auffällt
		var puls := 0.82 + 0.18 * sin(_phase * 1.6)
		_material.albedo_color.a = _sichtbarkeit * puls


## Nächstes Portal, das tatsächlich betreten werden kann.
func _naechstes_offenes_portal() -> Node3D:
	var bestes: Node3D = null
	var beste_entfernung := INF
	for knoten in get_tree().get_nodes_in_group("levelportale"):
		var portal := knoten as Node3D
		if portal == null or not ("nummer" in portal):
			continue
		if not Spielfluss.level_offen(int(portal.get("nummer"))):
			continue
		var entfernung := portal.global_position.distance_to(_spieler.global_position)
		if entfernung < beste_entfernung:
			beste_entfernung = entfernung
			bestes = portal
	return bestes
