extends Node3D
class_name Kart
## Kart für Level 05, prozedural aus Primitiven – keine fremden Dateien.
##
## Der Fahrer sitzt auf `SITZ_HOEHE`. Die Räder drehen sich mit dem Tempo,
## die Vorderräder schlagen beim Lenken ein und der Aufbau legt sich in die
## Kurve. Blickrichtung -Z.

const SITZ_HOEHE := 0.62
## Radumdrehungen je Meter Fahrstrecke.
const RAD_DREHUNG := 2.6

## Lackfarbe – jeder Fahrer bekommt eine eigene.
var farbe := Farben.FELL

var _aufbau: Node3D
var _raeder_vorn: Array[Node3D] = []
var _raeder_hinten: Array[Node3D] = []
var _spoiler: Node3D
var _flamme: MeshInstance3D
var _rollwinkel := 0.0


func _ready() -> void:
	_baue()


func _baue() -> void:
	var lack := Materialbibliothek.einfarbig(farbe, 0.35, 0.2)
	var dunkel := Materialbibliothek.einfarbig(farbe.darkened(0.55), 0.5)
	var gummi := Materialbibliothek.einfarbig(Color(0.11, 0.11, 0.12), 0.85)
	var felge := Materialbibliothek.einfarbig(Farben.KISTE_EISEN, 0.3, 0.7)

	_aufbau = Node3D.new()
	_aufbau.name = "Aufbau"
	_aufbau.position.y = 0.3
	add_child(_aufbau)

	# Wanne: flacher Kasten mit abgesetzter Nase
	var wanne := _netz(_aufbau, "Wanne", _kasten(Vector3(0.82, 0.26, 1.5)), lack,
			Vector3(0, 0.0, 0))
	_netz(_aufbau, "Nase", _kasten(Vector3(0.6, 0.18, 0.5)), lack,
			Vector3(0, -0.02, -0.9))
	_netz(_aufbau, "Sitz", _kasten(Vector3(0.5, 0.34, 0.42)), dunkel,
			Vector3(0, 0.28, 0.28))
	_netz(_aufbau, "Lenkrad", _scheibe(0.16, 0.05), dunkel,
			Vector3(0, 0.34, -0.28)).rotation.x = 1.15

	# Heckspoiler – macht von hinten sichtbar, wer da fährt
	_spoiler = Node3D.new()
	_spoiler.position = Vector3(0, 0.42, 0.72)
	_aufbau.add_child(_spoiler)
	_netz(_spoiler, "Blatt", _kasten(Vector3(0.9, 0.06, 0.24)), lack, Vector3.ZERO)
	for seite: float in [-1.0, 1.0]:
		_netz(_spoiler, "Strebe", _kasten(Vector3(0.06, 0.24, 0.08)), dunkel,
				Vector3(seite * 0.36, -0.14, 0.0))

	# Vier Räder an eigenen Drehpunkten
	for eintrag in [
		{"pos": Vector3(-0.52, 0.0, -0.58), "vorn": true},
		{"pos": Vector3(0.52, 0.0, -0.58), "vorn": true},
		{"pos": Vector3(-0.56, 0.02, 0.62), "vorn": false},
		{"pos": Vector3(0.56, 0.02, 0.62), "vorn": false},
	]:
		var nabe := Node3D.new()
		nabe.position = eintrag["pos"]
		add_child(nabe)
		var breit: float = 0.16 if eintrag["vorn"] else 0.22
		var r: float = 0.26 if eintrag["vorn"] else 0.30
		var reifen := _netz(nabe, "Reifen", _scheibe(r, breit), gummi, Vector3.ZERO)
		reifen.rotation.z = PI * 0.5
		var scheibe := _netz(nabe, "Felge", _scheibe(r * 0.55, breit + 0.02), felge,
				Vector3.ZERO)
		scheibe.rotation.z = PI * 0.5
		if eintrag["vorn"]:
			_raeder_vorn.append(nabe)
		else:
			_raeder_hinten.append(nabe)

	# Auspuffflamme, nur beim Boost sichtbar
	_flamme = _netz(self, "Flamme", _kegel(0.16, 0.02, 0.7),
			Materialbibliothek.leuchtend(Color(1.0, 0.62, 0.18), 2.4),
			Vector3(0, 0.32, 1.05))
	_flamme.rotation.x = -PI * 0.5
	_flamme.visible = false


## `tempo` in m/s, `lenkung` -1..1, `boost` = Flamme an.
func aktualisiere(delta: float, tempo: float, luft: bool, lenkung: float,
		boost: bool) -> void:
	var dreh := tempo * delta * RAD_DREHUNG
	for rad in _raeder_vorn + _raeder_hinten:
		if is_instance_valid(rad):
			rad.rotation.x += dreh
	for rad in _raeder_vorn:
		if is_instance_valid(rad):
			rad.rotation.y = lenkung * 0.45

	if is_instance_valid(_aufbau):
		# In die Kurve legen und beim Sprung die Nase heben
		_rollwinkel = lerpf(_rollwinkel, -lenkung * 0.18, minf(delta * 8.0, 1.0))
		_aufbau.rotation.z = _rollwinkel
		_aufbau.rotation.x = lerpf(_aufbau.rotation.x, -0.16 if luft else 0.0,
				minf(delta * 7.0, 1.0))

	if is_instance_valid(_flamme):
		_flamme.visible = boost
		if boost:
			_flamme.scale = Vector3(1.0, 0.8 + randf() * 0.5, 1.0)


# ---------------------------------------------------------------- Hilfen

func _netz(elternteil: Node3D, bezeichnung: String, netz: Mesh, material: Material,
		pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	mi.material_override = material
	mi.position = pos
	elternteil.add_child(mi)
	return mi


func _kasten(groesse: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = groesse
	return m


func _scheibe(radius: float, dicke: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = dicke
	m.radial_segments = 14
	return m


func _kegel(unten: float, oben: float, hoehe: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = unten
	m.top_radius = oben
	m.height = hoehe
	m.radial_segments = 8
	return m
