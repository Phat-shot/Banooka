extends Gegner
class_name Sumpfkroete
## Breite, flache Sumpfkröte.
##
## NUR durch Draufspringen (Angriff.FALLEN von oben) oder den
## Bauchplatscher zu besiegen. Spin und Slide prallen an ihrem
## glitschigen Rücken ab – wer sie so berührt, nimmt Schaden.
##
## Bewegung: kurze Hüpfer hin und her, dazwischen plustert sie ihren
## Kehlsack auf. Beim Besiegen platzt sie platt und der Spieler prallt ab.

const HUPF_KRAFT := 6.4      ## Absprunggeschwindigkeit eines Hüpfers
const HUPF_G := -20.0        ## Gravitation für den Hüpfbogen
const PAUSE := 0.55          ## Wartezeit am Boden zwischen zwei Hüpfern
const ANSPANNUNG := 0.22     ## Kurz vor dem Absprung geht sie in die Hocke

var _hoehe := 0.0
var _vy := 0.0
var _in_luft := false
var _warten := 0.0
var _stauchung := 0.0

var _koerper: MeshInstance3D
var _kehlsack: MeshInstance3D
var _beine: Array[MeshInstance3D] = []
var _bein_ruhe: Array[float] = []
var _augen: Array[MeshInstance3D] = []


func _init() -> void:
	# Nur von oben plattzumachen.
	besiegbar_durch = Angriff.FALLEN | Angriff.SLAM
	patrouille_weite = 4.0
	tempo = 2.4
	abprall_hoehe = 14.0


func _ready() -> void:
	super._ready()
	_warten = PAUSE + randf() * 0.4


# ---------------------------------------------------------- Optik

func _baue() -> void:
	# Warzige, feuchte Sumpfhaut aus Rauschen
	var haut := StandardMaterial3D.new()
	haut.albedo_texture = Materialbibliothek.rauschtextur(4711, 0.55,
			Farben.LAUB.darkened(0.35), Farben.MOOS.lightened(0.12))
	haut.uv1_triplanar = true
	haut.uv1_scale = Vector3(1.6, 1.6, 1.6)
	haut.roughness = 0.65

	var bauch_mat := Materialbibliothek.einfarbig(Farben.GRAS_HELL.lightened(0.3), 0.7)
	var sack_mat := Materialbibliothek.einfarbig(Farben.LAUB_HELL.darkened(0.05), 0.55)
	var dunkel := Materialbibliothek.einfarbig(Farben.NASE, 0.6)
	var augapfel := Materialbibliothek.einfarbig(Farben.FELL_BAUCH, 0.3)

	# Breiter, flacher Körper
	_koerper = _teil(modell, _kugel(0.5, 14, 9), haut, Vector3(0.0, 0.44, 0.0),
			Vector3.ZERO, Vector3(1.32, 0.62, 1.02), "Koerper")

	# Heller Bauch, etwas tiefer gesetzt
	_teil(modell, _kugel(0.44, 12, 7), bauch_mat, Vector3(0.0, 0.26, 0.02),
			Vector3.ZERO, Vector3(1.14, 0.38, 0.86), "Bauch")

	# Breites Maul als dunkler Spalt
	_teil(modell, _quader(Vector3(0.86, 0.09, 0.12)), dunkel,
			Vector3(0.0, 0.33, -0.5), Vector3(6.0, 0.0, 0.0), Vector3.ONE, "Maul")

	# Kehlsack, der sich beim Quaken aufplustert
	_kehlsack = _teil(modell, _kugel(0.28, 12, 7), sack_mat,
			Vector3(0.0, 0.2, -0.4), Vector3.ZERO, Vector3(1.0, 0.85, 0.9), "Kehlsack")

	# Zwei Glupschaugen oben auf dem Kopf
	for seite: float in [-1.0, 1.0]:
		var auge := _teil(modell, _kugel(0.16, 10, 7), augapfel,
				Vector3(0.27 * seite, 0.72, -0.2), Vector3.ZERO, Vector3.ONE, "Auge")
		_augen.append(auge)
		_teil(auge, _kugel(0.09, 8, 6), dunkel, Vector3(0.0, 0.03, -0.1),
				Vector3.ZERO, Vector3(1.0, 1.0, 0.7), "Pupille")

	# Vier abgespreizte Beine
	var bein_gitter := CapsuleMesh.new()
	bein_gitter.radius = 0.1
	bein_gitter.height = 0.52
	bein_gitter.radial_segments = 8
	bein_gitter.rings = 2
	for seite: float in [-1.0, 1.0]:
		for vorn: float in [-1.0, 1.0]:
			var ruhe := 62.0 * seite
			var bein := _teil(modell, bein_gitter, haut,
					Vector3(0.46 * seite, 0.2, 0.3 * vorn),
					Vector3(0.0, 0.0, ruhe), Vector3.ONE, "Bein")
			_beine.append(bein)
			_bein_ruhe.append(ruhe)
			# Schwimmhautfuß
			_teil(bein, _quader(Vector3(0.2, 0.06, 0.26)), bauch_mat,
					Vector3(0.0, -0.28, 0.0), Vector3(0.0, 0.0, -ruhe),
					Vector3.ONE, "Fuss")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_phase += delta * 3.0

	if _in_luft:
		_vy += HUPF_G * delta
		_hoehe += _vy * delta
		_patrouille_schritt(tempo * delta)
		if _hoehe <= 0.0:
			# Landung: kurz platt drücken und verschnaufen
			_hoehe = 0.0
			_vy = 0.0
			_in_luft = false
			_warten = PAUSE
			_stauchung = 1.0
	else:
		_stauchung = maxf(_stauchung - delta * 4.0, 0.0)
		_warten -= delta
		if _warten <= ANSPANNUNG:
			# In die Hocke gehen, bevor es losgeht
			_stauchung = maxf(_stauchung, 1.0 - maxf(_warten, 0.0) / ANSPANNUNG)
		if _warten <= 0.0:
			_in_luft = true
			_vy = HUPF_KRAFT
			_stauchung = 0.0

	_setze_hoehe(_hoehe)
	_blick_ausrichten(delta, 6.0)
	_animiere()


## Stauchen, Strecken und Kehlsack-Pumpen.
func _animiere() -> void:
	var streckung := 0.0
	if _in_luft:
		streckung = clampf(_vy * 0.05, -0.22, 0.22)
	var s := _stauchung * 0.32 - streckung

	if is_instance_valid(_koerper):
		_koerper.scale = Vector3(1.32 * (1.0 + s), 0.62 * (1.0 - s), 1.02 * (1.0 + s))

	if is_instance_valid(_kehlsack):
		var pumpen := 1.0 + sin(_phase * 2.2) * 0.2 + _stauchung * 0.35
		_kehlsack.scale = Vector3(pumpen, pumpen * 0.88, pumpen * 0.94)

	# Augen ducken sich beim Stauchen mit
	for auge in _augen:
		if is_instance_valid(auge):
			auge.position.y = 0.72 - _stauchung * 0.12

	# In der Luft zieht die Kröte die Beine an
	for i in _beine.size():
		var bein := _beine[i]
		if is_instance_valid(bein):
			var faktor := 0.55 if _in_luft else 1.0
			bein.rotation_degrees.z = _bein_ruhe[i] * faktor
			bein.position.y = 0.2 + (0.1 if _in_luft else 0.0)


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Die Kröte fliegt nicht weg, sie platzt an Ort und Stelle.
	_wegflug = Vector3.ZERO


func _todesanimation(delta: float) -> void:
	# Platzt zu einem flachen Fladen und sackt zu Boden.
	if is_instance_valid(modell):
		modell.scale = modell.scale.lerp(Vector3(1.75, 0.05, 1.5), minf(delta * 12.0, 1.0))
	_hoehe = maxf(_hoehe - delta * 9.0, 0.0)
	_setze_hoehe(_hoehe)
