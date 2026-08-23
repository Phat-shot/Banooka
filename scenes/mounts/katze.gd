extends Node3D
class_name Katze
## Reittier für Level 04: eine große Wildkatze, prozedural aus Primitiven.
##
## Wie beim Beuteldachs werden keine fremden Asset-Dateien gebraucht.
## Der Reiter sitzt auf `sattel_hoehe` über dem Boden; alles Bewegliche
## hängt an eigenen Drehpunkten, damit der Galopp nur Winkel setzen muss.
##
## Maße: Widerrist bei 1.05 m, Länge 2.4 m, Blickrichtung -Z.

## Höhe, auf der der Reiter sitzt.
const SATTEL_HOEHE := 1.18
## Taktrate des Galopps bei vollem Tempo.
const GALOPP := 9.0
## Ausschlag der Beine im Galopp.
const BEIN_AUSSCHLAG := 0.85

var _rumpf: Node3D
var _kopf: Node3D
var _schweif: Node3D
var _schweif_spitze: Node3D
var _beine: Array[Node3D] = []
var _bein_phase: Array[float] = []
var _phase := 0.0
var _zeit := 0.0


func _ready() -> void:
	_baue()


# ---------------------------------------------------------------- Aufbau

func _baue() -> void:
	var fell := Materialbibliothek.fell(Farben.FELL_DUNKEL.lerp(Farben.RINDE, 0.35))
	var bauchfell := Materialbibliothek.fell(Farben.FELL_BAUCH.darkened(0.12))
	var streifen := Materialbibliothek.fell(Farben.FELL_DUNKEL.darkened(0.45))
	var nase := Materialbibliothek.einfarbig(Farben.NASE, 0.35)
	var augapfel := Materialbibliothek.einfarbig(Color(0.95, 0.92, 0.55), 0.25)

	_rumpf = Node3D.new()
	_rumpf.name = "Rumpf"
	_rumpf.position.y = 0.86
	add_child(_rumpf)

	# Langgestreckter Körper: eine liegende Kapsel, dazu Brust und Kruppe
	var leib := _netz(_rumpf, "Leib", _kapsel(0.36, 1.5), fell, Vector3.ZERO)
	leib.rotation.x = PI * 0.5
	_netz(_rumpf, "Brust", _kugel(0.38), fell, Vector3(0, 0.04, -0.52)) \
			.scale = Vector3(1.05, 0.92, 0.9)
	_netz(_rumpf, "Kruppe", _kugel(0.36), fell, Vector3(0, 0.06, 0.55)) \
			.scale = Vector3(1.0, 1.0, 0.9)
	_netz(_rumpf, "Bauch", _kugel(0.3), bauchfell, Vector3(0, -0.22, 0.0)) \
			.scale = Vector3(0.9, 0.7, 2.0)

	# Querstreifen auf dem Rücken – aus der Spielkamera von schräg oben
	# ist genau das zu sehen, was die Katze erkennbar macht.
	for i in 5:
		var fleck := _netz(_rumpf, "Streifen%d" % i, _kugel(0.14), streifen,
				Vector3(0.0, 0.28, -0.55 + i * 0.28))
		fleck.scale = Vector3(2.1, 0.28, 0.45)

	_baue_kopf(fell, bauchfell, streifen, nase, augapfel)
	_baue_beine(fell, streifen)
	_baue_schweif(fell, streifen)


func _baue_kopf(fell: Material, bauchfell: Material, streifen: Material,
		nase: Material, augapfel: Material) -> void:
	_kopf = _gelenk(_rumpf, "Kopf", Vector3(0, 0.24, -0.82))
	_netz(_kopf, "Schaedel", _kugel(0.27), fell, Vector3.ZERO) \
			.scale = Vector3(1.0, 0.92, 1.06)
	_netz(_kopf, "Schnauze", _kugel(0.17), bauchfell, Vector3(0, -0.07, -0.22)) \
			.scale = Vector3(1.0, 0.8, 1.15)
	_netz(_kopf, "Nase", _kugel(0.055), nase, Vector3(0, -0.04, -0.37))

	for seite: float in [-1.0, 1.0]:
		# Dreieckige Ohren als flach gedrückte Kegel
		var ohr := _netz(_kopf, "Ohr", _kegel(0.12, 0.005, 0.26), fell,
				Vector3(seite * 0.16, 0.24, 0.02))
		ohr.rotation = Vector3(-0.15, 0.0, seite * 0.3)
		ohr.scale = Vector3(1.0, 1.0, 0.55)
		_netz(_kopf, "Auge", _kugel(0.052), augapfel, Vector3(seite * 0.135, 0.04, -0.21))
		_netz(_kopf, "Pupille", _kugel(0.026), nase, Vector3(seite * 0.135, 0.04, -0.25))
		# Wangenbart als kurzer Streifenfleck
		_netz(_kopf, "Wange", _kugel(0.07), streifen,
				Vector3(seite * 0.19, -0.02, -0.1)).scale = Vector3(0.5, 0.7, 1.2)


## Vier Beine an eigenen Hüftgelenken. Die Phasen sind so gewählt, dass
## sich ein Galopp ergibt: Vorderbeine fast gleichzeitig, Hinterbeine
## eine halbe Periode versetzt.
func _baue_beine(fell: Material, streifen: Material) -> void:
	var stellen := [
		{"pos": Vector3(-0.26, -0.1, -0.5), "phase": 0.0},
		{"pos": Vector3(0.26, -0.1, -0.5), "phase": 0.35},
		{"pos": Vector3(-0.28, -0.08, 0.52), "phase": PI},
		{"pos": Vector3(0.28, -0.08, 0.52), "phase": PI + 0.35},
	]
	for eintrag in stellen:
		var huefte := _gelenk(_rumpf, "Huefte", eintrag["pos"])
		_netz(huefte, "Oberschenkel", _kapsel(0.105, 0.42), fell, Vector3(0, -0.24, 0))
		_netz(huefte, "Unterschenkel", _kapsel(0.075, 0.34), fell, Vector3(0, -0.6, 0.03))
		_netz(huefte, "Pfote", _kugel(0.11), streifen, Vector3(0, -0.8, -0.04)) \
				.scale = Vector3(1.0, 0.62, 1.3)
		_beine.append(huefte)
		_bein_phase.append(eintrag["phase"])


func _baue_schweif(fell: Material, streifen: Material) -> void:
	_schweif = _gelenk(_rumpf, "Schweif", Vector3(0, 0.16, 0.78))
	_netz(_schweif, "Wurzel", _kapsel(0.075, 0.42), fell, Vector3(0, 0.0, 0.2)) \
			.rotation.x = PI * 0.5
	_schweif_spitze = _gelenk(_schweif, "Spitze", Vector3(0, 0.0, 0.44))
	_netz(_schweif_spitze, "Ende", _kapsel(0.062, 0.4), streifen, Vector3(0, 0.0, 0.2)) \
			.rotation.x = PI * 0.5


# ---------------------------------------------------------------- Bewegung

## `tempo` 0..1 als Anteil der Höchstgeschwindigkeit, `luft` = im Sprung.
func aktualisiere(delta: float, tempo: float, luft: bool) -> void:
	_zeit += delta
	_phase += delta * GALOPP * maxf(tempo, 0.15)

	for i in _beine.size():
		var bein := _beine[i]
		if not is_instance_valid(bein):
			continue
		if luft:
			# Im Sprung werden die Beine angezogen, vorn stärker als hinten
			var vorn := i < 2
			bein.rotation.x = lerpf(bein.rotation.x, -0.9 if vorn else 0.7,
					minf(delta * 10.0, 1.0))
		else:
			bein.rotation.x = sin(_phase + _bein_phase[i]) * BEIN_AUSSCHLAG * \
					maxf(tempo, 0.2)

	if is_instance_valid(_rumpf):
		# Der Rumpf federt im Galopp und streckt sich im Sprung
		var federn := sin(_phase * 2.0) * 0.045 * tempo
		_rumpf.position.y = 0.86 + (0.1 if luft else federn)
		_rumpf.rotation.x = lerpf(_rumpf.rotation.x, -0.18 if luft else federn * 0.6,
				minf(delta * 8.0, 1.0))

	if is_instance_valid(_kopf):
		# Kopf tief und nach vorn gestreckt, wenn es schnell geht
		_kopf.rotation.x = lerpf(_kopf.rotation.x, 0.22 * tempo - (0.3 if luft else 0.0),
				minf(delta * 6.0, 1.0))

	if is_instance_valid(_schweif):
		_schweif.rotation.x = -0.5 - sin(_phase * 0.5) * 0.2 - (0.5 if luft else 0.0)
		_schweif.rotation.y = sin(_zeit * 2.2) * 0.25
	if is_instance_valid(_schweif_spitze):
		_schweif_spitze.rotation.x = sin(_phase * 0.5 + 1.0) * 0.35
		_schweif_spitze.rotation.y = sin(_zeit * 2.6 + 0.8) * 0.3


# ---------------------------------------------------------------- Hilfen

func _gelenk(elternteil: Node3D, bezeichnung: String, pos: Vector3) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	knoten.position = pos
	elternteil.add_child(knoten)
	return knoten


func _netz(elternteil: Node3D, bezeichnung: String, netz: Mesh, material: Material,
		pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	mi.material_override = material
	mi.position = pos
	elternteil.add_child(mi)
	return mi


func _kugel(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 7
	return m


func _kapsel(radius: float, hoehe: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(hoehe, radius * 2.0 + 0.01)
	m.radial_segments = 10
	m.rings = 4
	return m


func _kegel(unten: float, oben: float, hoehe: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = unten
	m.top_radius = oben
	m.height = hoehe
	m.radial_segments = 8
	return m
