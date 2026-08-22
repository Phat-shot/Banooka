extends Area3D
class_name Portal
## Leuchtendes Portal – als Startportal (Levelanfang) oder Zielportal.
##
## Optik: ein aufrecht stehender Ring mit einer flimmernden, pulsierenden
## Scheibe darin und umlaufenden Funken. Die Farbe kommt aus `Farben`.
##
## Startportal (`ist_ziel = false`): passiv. Beim Levelstart blendet es sich
## ein und der Spieler tritt daraus hervor.
## Zielportal (`ist_ziel = true`): saugt den Spieler ein und meldet
## `level_geschafft`.

## Wird ausgelöst, sobald der Spieler das Zielportal vollständig betreten hat.
signal level_geschafft

## True = Zielportal, False = Startportal.
@export var ist_ziel := false

## Radius des Rings in Metern.
@export_range(0.6, 3.0, 0.05) var radius := 1.15

## In diesem Umkreis gilt der Spieler beim Levelstart als "aus dem
## Startportal getreten" (nur beim Startportal).
@export_range(0.0, 12.0, 0.5) var auftritt_radius := 4.0

## Anzahl der umlaufenden Funken.
@export_range(0, 24, 1) var funken_anzahl := 10

const RING_DICKE := 0.16
const EINBLEND_ZEIT := 0.5
const AUFTRITT_SPERRE := 0.75
const EINSAUG_ZEIT := 0.6
const NACHRICHT_ZEIT := 4.0
const EDELSTEIN_VERZOEGERUNG := 1.6

@onready var _kollision: CollisionShape3D = $Kollision

var _optik: Node3D = null
var _scheibe: MeshInstance3D = null
var _funken: Node3D = null
var _licht: OmniLight3D = null
var _scheibenmaterial: StandardMaterial3D = null
var _phase := 0.0
var _ausgeloest := false


func _ready() -> void:
	add_to_group("portale")
	add_to_group("zielportale" if ist_ziel else "startportale")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = ist_ziel
	_phase = randf() * TAU
	_form_anpassen()
	_baue_optik()

	if ist_ziel:
		if not body_entered.is_connected(_auf_koerper):
			body_entered.connect(_auf_koerper)
	else:
		_startauftritt()


## Farbe je nach Rolle.
func farbe() -> Color:
	return Farben.PORTAL_ZIEL if ist_ziel else Farben.PORTAL_START


# ---------------------------------------------------------------- Aufbau

func _form_anpassen() -> void:
	if _kollision == null:
		return
	var form := CylinderShape3D.new()
	form.radius = radius * 0.9
	form.height = radius * 2.0
	_kollision.shape = form
	_kollision.position = Vector3(0.0, radius, 0.0)


## Baut Ring, Scheibe, Funken und Licht auf.
func _baue_optik() -> void:
	_optik = Node3D.new()
	_optik.name = "Optik"
	_optik.position = Vector3(0.0, radius, 0.0)
	add_child(_optik)

	var ton := farbe()

	# --- Ring (aufrecht stehend, Öffnung zeigt in Z-Richtung) ---
	var torus := TorusMesh.new()
	torus.inner_radius = radius
	torus.outer_radius = radius + RING_DICKE
	torus.rings = 32
	torus.ring_segments = 12
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = torus
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.material_override = Materialbibliothek.leuchtend(ton, 2.2)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_optik.add_child(ring)

	# --- Flimmernde Scheibe in der Mitte ---
	var flaeche := CylinderMesh.new()
	flaeche.top_radius = radius
	flaeche.bottom_radius = radius
	flaeche.height = 0.04
	flaeche.radial_segments = 32
	flaeche.rings = 1
	_scheibe = MeshInstance3D.new()
	_scheibe.name = "Scheibe"
	_scheibe.mesh = flaeche
	_scheibe.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_scheibenmaterial = Materialbibliothek.transparent(ton.lightened(0.25), 1.4).duplicate()
	_scheibenmaterial.albedo_color.a = 0.55
	_scheibe.material_override = _scheibenmaterial
	_scheibe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_optik.add_child(_scheibe)

	# --- Umlaufende Funken ---
	_funken = Node3D.new()
	_funken.name = "Funken"
	_optik.add_child(_funken)
	var funke_mesh := SphereMesh.new()
	funke_mesh.radius = 0.075
	funke_mesh.height = 0.15
	funke_mesh.radial_segments = 6
	funke_mesh.rings = 4
	var funke_material := Materialbibliothek.leuchtend(ton.lightened(0.45), 2.6)
	for i in funken_anzahl:
		var mi := MeshInstance3D.new()
		mi.mesh = funke_mesh
		mi.material_override = funke_material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var winkel := TAU * float(i) / float(maxi(funken_anzahl, 1))
		var weite := radius + RING_DICKE + randf_range(0.10, 0.35)
		mi.position = Vector3(cos(winkel) * weite, sin(winkel) * weite,
				randf_range(-0.25, 0.25))
		mi.set_meta("winkel", winkel)
		mi.set_meta("weite", weite)
		_funken.add_child(mi)

	# --- Schein ---
	_licht = OmniLight3D.new()
	_licht.name = "Schein"
	_licht.light_color = ton
	_licht.light_energy = 1.6
	_licht.omni_range = radius * 6.0
	_licht.shadow_enabled = false
	_optik.add_child(_licht)


# ---------------------------------------------------------------- Animation

func _process(delta: float) -> void:
	_phase += delta
	if not is_instance_valid(_optik):
		return

	# Scheibe pulsiert und flimmert.
	var puls := 0.5 + 0.5 * sin(_phase * 3.1)
	var flimmern := 0.5 + 0.5 * sin(_phase * 11.7 + 1.3)
	if is_instance_valid(_scheibe):
		var s := 0.90 + puls * 0.10
		_scheibe.scale = Vector3(s, 1.0, s)
	if _scheibenmaterial != null:
		_scheibenmaterial.emission_energy_multiplier = 0.9 + puls * 1.1
		_scheibenmaterial.albedo_color.a = 0.42 + flimmern * 0.22
	if is_instance_valid(_licht):
		_licht.light_energy = 1.2 + puls * 1.0

	# Funken kreisen um den Ring und atmen leicht.
	if is_instance_valid(_funken):
		_funken.rotation.z += delta * 1.3
		for kind in _funken.get_children():
			var mi := kind as MeshInstance3D
			if mi == null:
				continue
			var w: float = mi.get_meta("winkel", 0.0)
			var weite: float = mi.get_meta("weite", radius)
			var atem := weite + sin(_phase * 2.4 + w * 3.0) * 0.12
			mi.position = Vector3(cos(w) * atem, sin(w) * atem,
					sin(_phase * 3.3 + w * 2.0) * 0.22)


# ---------------------------------------------------------------- Startportal

## Blendet das Portal ein; ein Spieler in Reichweite tritt daraus hervor.
func _startauftritt() -> void:
	if _optik != null:
		_optik.scale = Vector3(0.05, 0.05, 0.05)
	await get_tree().process_frame
	if not is_instance_valid(self):
		return

	var spieler := _spieler_in_reichweite()
	if spieler != null and "gesperrt" in spieler:
		spieler.gesperrt = true

	if is_instance_valid(_optik):
		var tween := create_tween()
		tween.tween_property(_optik, "scale", Vector3.ONE, EINBLEND_ZEIT) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(AUFTRITT_SPERRE).timeout
	if is_instance_valid(spieler) and "gesperrt" in spieler:
		spieler.gesperrt = false


func _spieler_in_reichweite() -> Node3D:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return null
	if auftritt_radius <= 0.0:
		return spieler
	if spieler.global_position.distance_to(global_position) > auftritt_radius:
		return null
	return spieler


# ---------------------------------------------------------------- Zielportal

func _auf_koerper(koerper: Node3D) -> void:
	if _ausgeloest or not ist_ziel:
		return
	if not koerper.is_in_group("spieler"):
		return
	_ausgeloest = true
	_einsaugen(koerper)


## Der Spieler wird eingesogen, danach folgt die Erfolgsmeldung.
func _einsaugen(spieler: Node3D) -> void:
	if "gesperrt" in spieler:
		spieler.gesperrt = true
	if spieler is CharacterBody3D:
		(spieler as CharacterBody3D).velocity = Vector3.ZERO
	# Physik anhalten, damit die Schwerkraft nicht gegen die Animation arbeitet.
	spieler.set_physics_process(false)

	var mitte := global_position + Vector3.UP * radius
	var modell := spieler.get_node_or_null("Modell") as Node3D

	var tween := create_tween().set_parallel(true)
	tween.tween_property(spieler, "global_position", mitte, EINSAUG_ZEIT) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(spieler, "rotation:y", spieler.rotation.y + TAU * 2.0,
			EINSAUG_ZEIT)
	if modell != null:
		tween.tween_property(modell, "scale", Vector3.ONE * 0.05, EINSAUG_ZEIT) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_optik):
		tween.tween_property(_optik, "scale", Vector3.ONE * 1.35, EINSAUG_ZEIT * 0.5) \
				.set_trans(Tween.TRANS_SINE)
	await tween.finished
	if not is_instance_valid(self):
		return

	if is_instance_valid(_optik):
		var zurueck := create_tween()
		zurueck.tween_property(_optik, "scale", Vector3.ONE, 0.25)

	GameState.zeige_nachricht("Level geschafft!", NACHRICHT_ZEIT)
	level_geschafft.emit()

	if GameState.kisten_gesamt > 0 \
			and GameState.kisten_zerbrochen >= GameState.kisten_gesamt:
		await get_tree().create_timer(EDELSTEIN_VERZOEGERUNG).timeout
		if not is_instance_valid(self):
			return
		GameState.zeige_nachricht("Alle Kisten! Edelstein erhalten", 3.0)
