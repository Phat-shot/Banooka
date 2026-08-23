extends Gegner
class_name Frostmotte
## Frostmotte – schwebt über dem Weg und kreuzt ihn langsam.
##
## NUR durch den Drehschlag (oder den Bauchplatscher) zu besiegen: Sie
## schwebt zu hoch zum Draufspringen und ein Slide geht unter ihr durch.
## Der Drehschlag reicht dagegen weit genug hinauf.
##
## Sie ist die "schlagen"-Rolle im Schneelevel – dieselbe Aufgabe wie die
## Sumpfkröte im Wald, aber mit einer Silhouette, die ins Setting passt.

const SCHWEBE_HOEHE := 1.35   ## Ruhehöhe über dem Boden
const SCHWEBE_HUB := 0.32     ## wie weit sie dabei auf und ab geht
const FLUEGEL_TAKT := 13.0    ## Schlagfrequenz der Flügel

var _koerper: MeshInstance3D
var _fluegel: Array[Node3D] = []
var _fuehler: Array[Node3D] = []


func _init() -> void:
	# Zu hoch für den Sprung, zu hoch für den Slide.
	besiegbar_durch = Angriff.SPIN | Angriff.SLAM
	patrouille_weite = 5.0
	tempo = 1.7
	fruechte = 2


# ---------------------------------------------------------- Optik

## Pelziger Körper mit großen, hellen Flügeln. Die Flügel sind bewusst
## breit und blass: Aus der Spielkamera von schräg oben ist von einem
## fliegenden Gegner sonst kaum etwas zu sehen.
func _baue() -> void:
	var pelz := Materialbibliothek.fell(Farben.SCHNEE_SCHATTEN.darkened(0.15))
	var fluegelstoff := Materialbibliothek.transparent(Farben.EIS_HELL, 0.35)
	var dunkel := Materialbibliothek.einfarbig(Farben.EIS_DUNKEL, 0.5)
	var auge := Materialbibliothek.leuchtend(Farben.KRISTALL_BLAU, 1.4)

	_koerper = _teil(modell, _kugel(0.24), pelz, Vector3(0.0, SCHWEBE_HOEHE, 0.0),
			Vector3.ZERO, Vector3(0.85, 0.9, 1.5), "Koerper")
	_teil(_koerper, _kugel(0.15), pelz, Vector3(0.0, 0.06, -0.26),
			Vector3.ZERO, Vector3(1.0, 0.9, 0.9), "Kopf")

	# Vier Flügel, je zwei an einem Gelenk – dann schlagen sie gemeinsam.
	for seite: float in [-1.0, 1.0]:
		var gelenk := Node3D.new()
		gelenk.name = "Fluegelgelenk"
		gelenk.position = Vector3(seite * 0.12, SCHWEBE_HOEHE + 0.08, 0.0)
		modell.add_child(gelenk)
		_fluegel.append(gelenk)

		var vorn := _teil(gelenk, _kugel(0.34), fluegelstoff,
				Vector3(seite * 0.32, 0.0, -0.12), Vector3.ZERO,
				Vector3(1.0, 0.08, 0.78), "FluegelVorn")
		vorn.rotation.z = seite * -0.25
		var hinten := _teil(gelenk, _kugel(0.26), fluegelstoff,
				Vector3(seite * 0.26, -0.04, 0.22), Vector3.ZERO,
				Vector3(1.0, 0.08, 0.66), "FluegelHinten")
		hinten.rotation.z = seite * -0.18

		# Fühler
		var f := Node3D.new()
		f.position = Vector3(seite * 0.06, SCHWEBE_HOEHE + 0.14, -0.3)
		modell.add_child(f)
		_teil(f, _zylinder(0.018, 0.008, 0.28, 5), dunkel, Vector3(0.0, 0.14, 0.0),
				Vector3(-24.0, 0.0, seite * 22.0), Vector3.ONE, "Fuehler")
		_fuehler.append(f)

		_teil(_koerper, _kugel(0.05), auge, Vector3(seite * 0.075, 0.09, -0.36),
				Vector3.ZERO, Vector3.ONE, "Auge")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_patrouille_schritt(tempo * delta)
	# Schweben: langsame Welle, damit sie nicht wie angenagelt in der Luft steht
	_setze_hoehe(sin(_zeit * 1.6 + _phase) * SCHWEBE_HUB)
	_blick_ausrichten(delta, 4.0)

	var schlag := sin(_zeit * FLUEGEL_TAKT)
	for i in _fluegel.size():
		var gelenk := _fluegel[i]
		if is_instance_valid(gelenk):
			var seite := -1.0 if i == 0 else 1.0
			gelenk.rotation.z = seite * schlag * 0.7
	for f in _fuehler:
		if is_instance_valid(f):
			f.rotation.x = sin(_zeit * 2.4) * 0.2


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Der Drehschlag schlägt sie aus der Luft.
	_wegflug = _weg_richtung() * 7.0 + Vector3.UP * 3.0


func _todesanimation(delta: float) -> void:
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.z += delta * 14.0
		modell.scale = modell.scale.lerp(Vector3(0.5, 0.5, 0.5), minf(delta * 3.0, 1.0))
