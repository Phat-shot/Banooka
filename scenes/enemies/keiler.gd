extends Node3D
class_name Keiler
## Riesenkeiler – der Verfolger aus Level 05.
##
## Kein `Gegner`: Er patrouilliert nicht und lässt sich nicht besiegen. Er
## läuft auf derselben Kurve wie der Spieler, immer ein Stück hinter ihm,
## und holt auf, wenn der Spieler langsamer wird. Wer sich einholen lässt,
## ist tot – das ist der ganze Gegner.
##
## Prozedural wie alles andere: massiger Rumpf, gesenkter Schädel, Hauer,
## stampfender Vierbeinlauf. Blickrichtung -Z.

## Wie hoch der Schädel über dem Boden sitzt.
const SCHULTER := 2.6
const BEIN_TAKT := 7.0

var _rumpf: Node3D
var _kopf: Node3D
var _beine: Array[Node3D] = []
var _bein_phase: Array[float] = []
var _borsten: Array[Node3D] = []
var _zeit := 0.0


func _ready() -> void:
	_baue()


func _baue() -> void:
	var fell := Materialbibliothek.fell(Farben.RINDE_DUNKEL.lerp(Farben.FELS, 0.25))
	var dunkel := Materialbibliothek.fell(Farben.RINDE_DUNKEL.darkened(0.4))
	var hauer := Materialbibliothek.einfarbig(Color(0.93, 0.9, 0.78), 0.35)
	var auge := Materialbibliothek.leuchtend(Farben.WARNUNG, 2.0)
	var huf := Materialbibliothek.einfarbig(Farben.NASE, 0.5)

	_rumpf = Node3D.new()
	_rumpf.name = "Rumpf"
	_rumpf.position.y = SCHULTER * 0.72
	add_child(_rumpf)

	# Massiger Leib, vorn höher als hinten – das macht die Silhouette
	var leib := _netz(_rumpf, "Leib", _kapsel(1.05, 3.4), fell, Vector3.ZERO)
	leib.rotation.x = PI * 0.5
	_netz(_rumpf, "Buckel", _kugel(1.15), fell, Vector3(0.0, 0.42, -0.7)) \
			.scale = Vector3(1.0, 0.86, 1.25)
	_netz(_rumpf, "Kruppe", _kugel(0.92), dunkel, Vector3(0.0, -0.1, 1.5)) \
			.scale = Vector3(1.0, 0.95, 0.9)

	# Borstenkamm auf dem Rücken
	for i in 9:
		var borste := Node3D.new()
		borste.position = Vector3(0.0, 1.0, -1.4 + i * 0.36)
		_rumpf.add_child(borste)
		_netz(borste, "Borste", _kegel(0.09, 0.01, 0.7), dunkel,
				Vector3(0.0, 0.3, 0.0))
		_borsten.append(borste)

	# Gesenkter Schädel mit Rüssel und Hauern
	_kopf = Node3D.new()
	_kopf.name = "Kopf"
	_kopf.position = Vector3(0.0, -0.1, -1.9)
	_rumpf.add_child(_kopf)
	_netz(_kopf, "Schaedel", _kugel(0.8), fell, Vector3.ZERO) \
			.scale = Vector3(0.92, 0.9, 1.15)
	_netz(_kopf, "Ruessel", _kegel(0.42, 0.5, 0.9), dunkel,
			Vector3(0.0, -0.22, -0.9)).rotation.x = PI * 0.5
	_netz(_kopf, "Nase", _kugel(0.2), huf, Vector3(0.0, -0.22, -1.32)) \
			.scale = Vector3(1.2, 0.7, 0.5)

	for seite: float in [-1.0, 1.0]:
		# Hauer: nach vorn und oben gebogen, hell – sie sind das Zeichen
		var h := _netz(_kopf, "Hauer", _kegel(0.13, 0.01, 1.15), hauer,
				Vector3(seite * 0.38, -0.16, -1.05))
		h.rotation = Vector3(-1.15, 0.0, seite * 0.42)
		_netz(_kopf, "Auge", _kugel(0.13), auge, Vector3(seite * 0.42, 0.3, -0.55))
		# Ohren
		var ohr := _netz(_kopf, "Ohr", _kegel(0.24, 0.02, 0.5), dunkel,
				Vector3(seite * 0.5, 0.6, 0.15))
		ohr.rotation = Vector3(-0.3, 0.0, seite * 0.5)

	# Vier stämmige Beine
	for eintrag in [
		{"pos": Vector3(-0.62, -0.55, -1.15), "phase": 0.0},
		{"pos": Vector3(0.62, -0.55, -1.15), "phase": PI},
		{"pos": Vector3(-0.66, -0.55, 1.15), "phase": PI},
		{"pos": Vector3(0.66, -0.55, 1.15), "phase": 0.0},
	]:
		var huefte := Node3D.new()
		huefte.name = "Huefte"
		huefte.position = eintrag["pos"]
		_rumpf.add_child(huefte)
		_netz(huefte, "Oberschenkel", _kapsel(0.26, 0.9), fell, Vector3(0, -0.45, 0))
		_netz(huefte, "Unterschenkel", _kapsel(0.18, 0.7), dunkel,
				Vector3(0, -1.1, 0.05))
		_netz(huefte, "Huf", _kegel(0.22, 0.16, 0.24), huf, Vector3(0, -1.5, 0))
		_beine.append(huefte)
		_bein_phase.append(eintrag["phase"])


## `tempo` 0..1 als Anteil des Höchsttempos, `naehe` 0..1 wie dicht er dran
## ist – je näher, desto wütender stampft er.
func aktualisiere(delta: float, tempo: float, naehe: float) -> void:
	_zeit += delta
	var takt := BEIN_TAKT * maxf(tempo, 0.3)
	for i in _beine.size():
		var bein := _beine[i]
		if is_instance_valid(bein):
			bein.rotation.x = sin(_zeit * takt + _bein_phase[i]) * 0.7 * maxf(tempo, 0.3)

	if is_instance_valid(_rumpf):
		# Stampfen: Der ganze Leib hebt und senkt sich im Takt
		_rumpf.position.y = SCHULTER * 0.72 + absf(sin(_zeit * takt)) * 0.16
		_rumpf.rotation.z = sin(_zeit * takt * 0.5) * 0.05
	if is_instance_valid(_kopf):
		# Je näher er ist, desto tiefer geht der Schädel
		_kopf.rotation.x = lerpf(0.05, 0.3, naehe) + sin(_zeit * takt) * 0.08
	for i in _borsten.size():
		var borste := _borsten[i]
		if is_instance_valid(borste):
			# Bei Nähe stellen sich die Borsten auf
			borste.rotation.x = lerpf(0.5, 0.0, naehe) + sin(_zeit * 6.0 + i) * 0.08


# ---------------------------------------------------------------- Hilfen

func _netz(elternteil: Node3D, bezeichnung: String, gitter: Mesh,
		material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = gitter
	mi.material_override = material
	mi.position = pos
	elternteil.add_child(mi)
	return mi


func _kugel(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 14
	m.rings = 8
	return m


func _kapsel(radius: float, hoehe: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(hoehe, radius * 2.0 + 0.01)
	m.radial_segments = 12
	m.rings = 5
	return m


func _kegel(unten: float, oben: float, hoehe: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = unten
	m.top_radius = oben
	m.height = hoehe
	m.radial_segments = 8
	return m
