extends Node3D
class_name Explosion
## Kurzlebiger Explosionseffekt für TNT- und Nitrokisten.
##
## Wird rein im Code erzeugt (keine Szenendatei nötig) und räumt sich
## nach dem Ablauf selbst wieder ab.

## Dauer des gesamten Effekts in Sekunden.
const DAUER := 0.6
## Anzahl der wegfliegenden Glutsplitter.
const SPLITTER := 10

var radius := 3.0
var farbe := Farben.WARNUNG


## Erzeugt eine Explosion an `pos` unterhalb von `elternteil`.
static func erzeugen(elternteil: Node, pos: Vector3, wirkradius: float = 3.0,
		ton: Color = Farben.WARNUNG) -> void:
	if elternteil == null or not is_instance_valid(elternteil):
		return
	var ex := Explosion.new()
	ex.name = "Explosion"
	ex.radius = wirkradius
	ex.farbe = ton
	elternteil.add_child(ex)
	ex.global_position = pos


func _ready() -> void:
	_baue_kugel()
	_baue_splitter()
	_baue_blitz()


## Schnell aufblähende, durchscheinende Druckwelle.
func _baue_kugel() -> void:
	var kugel := SphereMesh.new()
	kugel.radius = 0.5
	kugel.height = 1.0
	kugel.radial_segments = 16
	kugel.rings = 10

	var mi := MeshInstance3D.new()
	mi.name = "Druckwelle"
	mi.mesh = kugel
	var mat := Materialbibliothek.transparent(farbe, 2.2).duplicate() as StandardMaterial3D
	mi.material_override = mat
	mi.scale = Vector3.ONE * 0.3
	add_child(mi)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3.ONE * (radius * 2.0), DAUER).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, DAUER)
	t.chain().tween_callback(queue_free)


## Glutsplitter, die in alle Richtungen davonfliegen.
func _baue_splitter() -> void:
	for i in SPLITTER:
		var wuerfel := BoxMesh.new()
		wuerfel.size = Vector3.ONE * randf_range(0.12, 0.24)
		var mi := MeshInstance3D.new()
		mi.mesh = wuerfel
		mi.material_override = Materialbibliothek.leuchtend(farbe.lightened(randf() * 0.4), 1.6)
		add_child(mi)

		var richtung := Vector3(randf() * 2.0 - 1.0, randf() * 1.2, randf() * 2.0 - 1.0).normalized()
		var ziel := richtung * radius * randf_range(0.5, 1.0)
		var t := mi.create_tween()
		t.set_parallel(true)
		t.tween_property(mi, "position", ziel, DAUER).set_ease(Tween.EASE_OUT)
		t.tween_property(mi, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), DAUER)
		t.tween_property(mi, "scale", Vector3.ZERO, DAUER * 0.6).set_delay(DAUER * 0.4)


## Kurzer Lichtblitz.
func _baue_blitz() -> void:
	var licht := OmniLight3D.new()
	licht.name = "Blitz"
	licht.light_color = farbe.lightened(0.4)
	licht.light_energy = 6.0
	licht.omni_range = radius * 2.5
	add_child(licht)
	var t := licht.create_tween()
	t.tween_property(licht, "light_energy", 0.0, DAUER * 0.7)
