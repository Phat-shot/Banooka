extends Node3D
## Testkorridor zum Prüfen des Player-Controllers.
## Die Geometrie entspricht dem Korridor aus plattformer-demo.html.
## Das ist bewusst KEIN fertiges Level – Level 01 bis 25 entstehen später
## einzeln als eigene Szenen.

const BODEN_FARBE := Color(0.239, 0.42, 0.208)
const WEG_FARBE := Color(0.541, 0.435, 0.278)
const ZIEL_FARBE := Color(0.831, 0.69, 0.29)


func _ready() -> void:
	# Korridor Richtung -Z
	_box(Vector3(0, -0.5, -10), Vector3(8, 1, 40), BODEN_FARBE)     # Startabschnitt
	_box(Vector3(0, -0.5, -38), Vector3(6, 1, 12), BODEN_FARBE)     # nach Lücke 1
	_box(Vector3(-1.5, 0.5, -36), Vector3(1.2, 1, 1.2), WEG_FARBE)  # Stufe
	_box(Vector3(0, -0.5, -58), Vector3(8, 1, 20), BODEN_FARBE)     # nach Lücke 2
	_box(Vector3(2, 0.75, -52), Vector3(2, 2.5, 2), WEG_FARBE)      # Block für Slide-Jump
	_box(Vector3(0, -0.5, -80), Vector3(6, 1, 16), BODEN_FARBE)     # Endabschnitt
	_box(Vector3(0, 0.25, -86), Vector3(4, 0.5, 3), ZIEL_FARBE)     # Ziel-Podest

	GameState.zeige_nachricht("Testkorridor – Steuerung prüfen", 2.5)


## Erzeugt eine statische Box mit Mesh und Kollision.
func _box(pos: Vector3, groesse: Vector3, farbe: Color) -> void:
	var koerper := StaticBody3D.new()
	koerper.name = "Box_%d_%d" % [int(pos.z), int(pos.x)]
	koerper.position = pos

	var box_mesh := BoxMesh.new()
	box_mesh.size = groesse
	var material := StandardMaterial3D.new()
	material.albedo_color = farbe
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	koerper.add_child(mesh_instance)

	var box_form := BoxShape3D.new()
	box_form.size = groesse
	var kollision := CollisionShape3D.new()
	kollision.shape = box_form
	koerper.add_child(kollision)

	add_child(koerper)
