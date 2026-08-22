extends Node3D
class_name SpielerModell
## Darstellung des Beuteldachses.
##
## Der Player-Controller kennt nur diese Schnittstelle und weiß nichts
## über den Aufbau des Modells:
##   aktualisiere()  – jeden Frame, überträgt den Bewegungszustand
##   setze_blick()   – Blickrichtung in Radiant um die Y-Achse
##   sichtbarkeit()  – Blinken während der Unverwundbarkeit
##
## Das Modell wird prozedural aufgebaut, es werden keine fremden
## Asset-Dateien benötigt.

const SPIN_DREHUNG := 30.0   ## Umdrehungsgeschwindigkeit beim Spin

var _blick := 0.0
var _spin_alpha := 0.0
var _lauf_phase := 0.0

var _koerper: MeshInstance3D
var _spin_ring: MeshInstance3D
var _teile: Node3D


func _ready() -> void:
	_baue()


## Baut das Modell auf. Wird vom Beuteldachs-Modell überschrieben/erweitert.
func _baue() -> void:
	_teile = Node3D.new()
	_teile.name = "Teile"
	add_child(_teile)

	var kapsel := CapsuleMesh.new()
	kapsel.radius = 0.38
	kapsel.height = 1.36
	_koerper = MeshInstance3D.new()
	_koerper.name = "Koerper"
	_koerper.mesh = kapsel
	_koerper.position.y = 0.7
	_koerper.material_override = Materialbibliothek.fell()
	_teile.add_child(_koerper)

	var ring := TorusMesh.new()
	ring.inner_radius = 0.77
	ring.outer_radius = 0.93
	_spin_ring = MeshInstance3D.new()
	_spin_ring.name = "SpinRing"
	_spin_ring.mesh = ring
	_spin_ring.position.y = 0.6
	_spin_ring.material_override = Materialbibliothek.transparent(Farben.SPIN_RING, 1.4).duplicate()
	_teile.add_child(_spin_ring)


## Überträgt den Bewegungszustand.
## tempo: 0..1, luft: in der Luft, slide/spin: Restzeiten in Sekunden.
func aktualisiere(delta: float, tempo: float, luft: bool, slide: float, spin: float) -> void:
	# Blickrichtung bzw. Spin-Drehung
	if spin > 0.0:
		rotation.y += delta * SPIN_DREHUNG
		_spin_alpha = 0.85
	else:
		rotation.y = _blick
		_spin_alpha = maxf(_spin_alpha - delta * 5.0, 0.0)

	if is_instance_valid(_spin_ring):
		var mat := _spin_ring.material_override
		if mat is StandardMaterial3D:
			mat.albedo_color.a = _spin_alpha

	# Slide: flach drücken
	if is_instance_valid(_koerper):
		var im_slide := slide > 0.0
		_koerper.scale.y = 0.45 if im_slide else 1.0
		_koerper.position.y = 0.4 if im_slide else 0.7

	# Laufzyklus (wird von abgeleiteten Modellen genutzt)
	_lauf_phase += delta * tempo * 12.0
	_animiere(delta, tempo, luft, slide > 0.0, spin > 0.0)


## Haken für Modelle mit beweglichen Teilen. Basisversion tut nichts.
func _animiere(_delta: float, _tempo: float, _luft: bool, _slide: bool, _spin: bool) -> void:
	pass


func setze_blick(winkel: float) -> void:
	_blick = winkel


func sichtbarkeit(sichtbar: bool) -> void:
	visible = sichtbar
