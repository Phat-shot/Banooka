extends Gegner
class_name Stelzenvogel
## Hoher, dünner Vogel auf langen Stelzenbeinen.
##
## NUR durch den Slide (oder den Bauchplatscher) zu besiegen: Der Slide
## fegt ihm die Beine weg. Draufspringen geht NICHT – auf dem Kopf sitzt
## ein spitzer Stachel, wer dort landet, nimmt Schaden.
##
## Bewegung: stakst langsam seitlich hin und her und pickt gelegentlich
## nach Würmern.

const PICK_DAUER := 0.9          ## Wie lange ein Pickvorgang dauert
const PICK_ABSTAND_MIN := 2.5    ## Kürzeste Pause zwischen zwei Pickern
const PICK_ABSTAND_MAX := 4.5    ## Längste Pause zwischen zwei Pickern
const HUEFT_HOEHE := 1.05        ## Höhe der Hüfte über dem Boden

var _pick_zeit := 0.0
var _pick_laeuft := 0.0

var _rumpf: MeshInstance3D
var _hals: Node3D
var _beine: Array[Node3D] = []
var _fluegel: Array[MeshInstance3D] = []


func _init() -> void:
	# Nur der Slide fegt ihm die Beine weg.
	besiegbar_durch = Angriff.SLIDE | Angriff.SLAM
	patrouille_weite = 3.5
	tempo = 1.3


func _ready() -> void:
	super._ready()
	_pick_zeit = randf_range(PICK_ABSTAND_MIN, PICK_ABSTAND_MAX)


# ---------------------------------------------------------- Optik

func _baue() -> void:
	var gefieder := Materialbibliothek.fell(Farben.WASSER_HELL.darkened(0.28))
	var bauch_mat := Materialbibliothek.einfarbig(Farben.FELL_BAUCH.darkened(0.08), 0.85)
	var stelzen := Materialbibliothek.einfarbig(Farben.KISTE_FEDER.darkened(0.2), 0.8)
	var schnabel_mat := Materialbibliothek.einfarbig(Farben.FRUCHT, 0.5)
	var stachel_mat := Materialbibliothek.einfarbig(Farben.WARNUNG, 0.4)
	var dunkel := Materialbibliothek.einfarbig(Farben.NASE, 0.5)
	var augapfel := Materialbibliothek.einfarbig(Farben.FELL_BAUCH, 0.3)

	# --- Zwei lange Stelzenbeine, jeweils an einem Drehpunkt in der Hüfte ---
	for seite: float in [-1.0, 1.0]:
		var huefte := Node3D.new()
		huefte.name = "Huefte"
		huefte.position = Vector3(0.17 * seite, HUEFT_HOEHE, 0.0)
		modell.add_child(huefte)
		_beine.append(huefte)

		_teil(huefte, _zylinder(0.045, 0.06, HUEFT_HOEHE, 8), stelzen,
				Vector3(0.0, -HUEFT_HOEHE * 0.5, 0.0), Vector3.ZERO, Vector3.ONE, "Stelze")
		# Rückwärts geknickter Fuß
		_teil(huefte, _quader(Vector3(0.16, 0.05, 0.34)), stelzen,
				Vector3(0.0, -HUEFT_HOEHE + 0.02, -0.06), Vector3.ZERO, Vector3.ONE, "Fuss")

	# --- Schmaler, hoch sitzender Rumpf ---
	_rumpf = _teil(modell, _kugel(0.4, 12, 9), gefieder, Vector3(0.0, 1.42, 0.02),
			Vector3.ZERO, Vector3(0.62, 0.78, 1.1), "Rumpf")
	_teil(_rumpf, _kugel(0.36, 10, 7), bauch_mat, Vector3(0.0, -0.14, -0.1),
			Vector3.ZERO, Vector3(0.85, 0.7, 0.85), "Bauch")
	# Spitzer Schwanz nach hinten
	_teil(modell, _zylinder(0.14, 0.0, 0.5, 8), gefieder, Vector3(0.0, 1.5, 0.42),
			Vector3(-70.0, 0.0, 0.0), Vector3.ONE, "Schwanz")

	# --- Flügel, eng angelegt ---
	for seite: float in [-1.0, 1.0]:
		var fluegel := _teil(modell, _quader(Vector3(0.07, 0.42, 0.6)), gefieder,
				Vector3(0.26 * seite, 1.44, 0.04),
				Vector3(0.0, 0.0, -8.0 * seite), Vector3.ONE, "Fluegel")
		_fluegel.append(fluegel)

	# --- Hals mit Kopf: hängt an einem Drehpunkt, damit er picken kann ---
	_hals = Node3D.new()
	_hals.name = "Hals"
	_hals.position = Vector3(0.0, 1.72, -0.05)
	modell.add_child(_hals)

	_teil(_hals, _zylinder(0.09, 0.07, 0.52, 8), gefieder, Vector3(0.0, 0.26, -0.04),
			Vector3(6.0, 0.0, 0.0), Vector3.ONE, "Halsrohr")
	var kopf := _teil(_hals, _kugel(0.18, 10, 8), gefieder, Vector3(0.0, 0.56, -0.09),
			Vector3.ZERO, Vector3(0.9, 0.95, 1.05), "Kopf")

	# Langer, spitzer Schnabel nach vorn
	_teil(kopf, _zylinder(0.08, 0.0, 0.46, 8), schnabel_mat, Vector3(0.0, -0.02, -0.26),
			Vector3(-95.0, 0.0, 0.0), Vector3.ONE, "Schnabel")

	# Stachelkamm nach OBEN – darauf kann niemand landen
	for i in 3:
		var hoehe := 0.3 - float(i) * 0.06
		_teil(kopf, _zylinder(0.05, 0.0, hoehe, 6), stachel_mat,
				Vector3(0.0, 0.14 + hoehe * 0.5, 0.02 + float(i) * 0.11),
				Vector3(float(i) * 9.0, 0.0, 0.0), Vector3.ONE, "Stachel")

	# Augen
	for seite: float in [-1.0, 1.0]:
		var auge := _teil(kopf, _kugel(0.07, 8, 6), augapfel,
				Vector3(0.12 * seite, 0.04, -0.1), Vector3.ZERO, Vector3.ONE, "Auge")
		_teil(auge, _kugel(0.04, 6, 5), dunkel, Vector3(0.0, 0.0, -0.05),
				Vector3.ZERO, Vector3.ONE, "Pupille")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_pick_zeit -= delta
	if _pick_zeit <= 0.0 and _pick_laeuft <= 0.0:
		_pick_laeuft = PICK_DAUER
		_pick_zeit = randf_range(PICK_ABSTAND_MIN, PICK_ABSTAND_MAX)

	if _pick_laeuft > 0.0:
		# Beim Picken bleibt er stehen
		_pick_laeuft = maxf(_pick_laeuft - delta, 0.0)
	else:
		_phase += delta * tempo * 3.2
		_patrouille_schritt(tempo * delta)

	_blick_ausrichten(delta, 3.5)
	_animiere(delta)


## Staksende Schritte, wippender Rumpf, Picken und leichtes Flügelzucken.
func _animiere(_delta: float) -> void:
	var laeuft := _pick_laeuft <= 0.0

	for i in _beine.size():
		var bein := _beine[i]
		if not is_instance_valid(bein):
			continue
		var versatz := PI * float(i)
		var schwung := sin(_phase + versatz) if laeuft else 0.0
		bein.rotation.x = schwung * 0.45
		# Beim Vorschwingen wird das Bein leicht angehoben
		bein.position.y = HUEFT_HOEHE + maxf(schwung, 0.0) * 0.06

	if is_instance_valid(_rumpf):
		_rumpf.position.y = 1.42 + (absf(sin(_phase)) * 0.05 if laeuft else 0.0)

	if is_instance_valid(_hals):
		# Pickbogen: Kopf schnellt nach unten und wieder hoch
		var pick := 0.0
		if _pick_laeuft > 0.0:
			pick = sin((1.0 - _pick_laeuft / PICK_DAUER) * PI)
		_hals.rotation.x = pick * 1.35
		_hals.position.y = 1.72 - pick * 0.18

	for i in _fluegel.size():
		var fluegel := _fluegel[i]
		if is_instance_valid(fluegel):
			var seite := -1.0 if i == 0 else 1.0
			var zucken := sin(_zeit * 2.4 + float(i)) * 6.0
			fluegel.rotation_degrees.z = -8.0 * seite + zucken * seite


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Die Beine sind weg – er fliegt nicht, er kippt um.
	_wegflug = Vector3.ZERO


func _todesanimation(delta: float) -> void:
	if not is_instance_valid(modell):
		return
	# Beine knicken weg, der ganze Vogel kippt zur Seite
	modell.rotation.z = lerp_angle(modell.rotation.z, PI * 0.55, minf(delta * 7.0, 1.0))
	modell.scale = modell.scale.lerp(Vector3(0.9, 0.75, 0.9), minf(delta * 4.0, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = lerp_angle(bein.rotation.x, 1.4, minf(delta * 8.0, 1.0))
	for fluegel in _fluegel:
		if is_instance_valid(fluegel):
			fluegel.rotation_degrees.z = lerpf(fluegel.rotation_degrees.z, 70.0,
					minf(delta * 6.0, 1.0))
