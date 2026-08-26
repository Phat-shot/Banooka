extends Gegner
class_name Sumpfkroete
## Breite, flache Sumpfkröte.
##
## NUR durch den Drehschlag (Angriff.SPIN) oder den Bauchplatscher zu
## besiegen. Ihr Rücken ist so glitschig, dass ein Sprung darauf abrutscht,
## und flach genug, dass ein Slide unter ihr durchgeht – wer sie so
## berührt, nimmt Schaden.
##
## Bewegung: kurze Hüpfer hin und her, dazwischen plustert sie ihren
## Kehlsack auf. Der Drehschlag schleudert sie davon.

const HUPF_KRAFT := 6.4      ## Absprunggeschwindigkeit eines Hüpfers
const HUPF_G := -20.0        ## Gravitation für den Hüpfbogen
const PAUSE := 0.55          ## Wartezeit am Boden zwischen zwei Hüpfern
const ANSPANNUNG := 0.22     ## Kurz vor dem Absprung geht sie in die Hocke

# ---------------------------------------------------------- Farben
#
# Die Kröte hüpft längst nicht mehr nur im Sumpf. Damit ein Level sie in
# seine eigene Palette holen kann, ohne dass ein zweiter Gegner entstehen
# muss, sind ihre Flächen einzeln einstellbar. Vorgabe ist überall der
# bisherige Ton: Wer nichts setzt, sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Rücken und Flanke sind die Stelle,
# an der der Drehschlag wirkt, und die hellen Rückenflecken setzen sie
# ab. Flecken und Haut müssen deshalb weit auseinanderliegen – eine
# Kröte, deren Flecken im Ton der Haut liegen, ist eine Kröte ohne
# Anleitung.

## Warzige Grundhaut (dunkler Anteil der Rauschtextur).
@export var farbe_haut: Color = Farben.LAUB_DUNKEL.darkened(0.35):
	set(wert):
		farbe_haut = wert
		_neu_faerben()
## Hellerer Anteil derselben Haut – erst beide zusammen ergeben die Warzen.
@export var farbe_haut_hell: Color = Farben.MOOS:
	set(wert):
		farbe_haut_hell = wert
		_neu_faerben()
## Bauch, Lippe und Schwimmfüße.
@export var farbe_bauch: Color = Farben.KISTE_FEDER.lightened(0.18):
	set(wert):
		farbe_bauch = wert
		_neu_faerben()
## Rückenflecken – der helle Gegenpol zur Haut.
@export var farbe_flecken: Color = Farben.GRAS_HELL.lightened(0.32):
	set(wert):
		farbe_flecken = wert
		_neu_faerben()
## Warzen zwischen den Flecken.
@export var farbe_warzen: Color = Farben.LAUB_DUNKEL.darkened(0.55):
	set(wert):
		farbe_warzen = wert
		_neu_faerben()
## Kehlsack, der sich beim Quaken aufplustert.
@export var farbe_kehlsack: Color = Farben.LAUB_HELL.lightened(0.05):
	set(wert):
		farbe_kehlsack = wert
		_neu_faerben()
## Maulspalt und Pupillen – die dunkelste Fläche.
@export var farbe_maul: Color = Farben.NASE:
	set(wert):
		farbe_maul = wert
		_neu_faerben()
## Augapfel.
@export var farbe_auge: Color = Color(0.99, 0.97, 0.88):
	set(wert):
		farbe_auge = wert
		_neu_faerben()
## Hautfarbe der mitgelieferten Froschfigur.
##
## Eigener Wert und nicht `farbe_haut`: Das fremde Modell bringt seinen
## eigenen Grünton mit, und die Vorgabe ist genau dieser Ton – so sieht
## der Frosch aus wie bisher, solange niemand ihn umfärbt. Wer die Kröte
## in eine andere Palette holt, setzt beide.
@export var farbe_fremdmodell: Color = Color(0.502539, 0.663341, 0.377470):
	set(wert):
		farbe_fremdmodell = wert
		_neu_faerben()


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
	# Nur der Drehschlag erwischt sie.
	besiegbar_durch = Angriff.SPIN | Angriff.SLAM
	patrouille_weite = 4.0
	tempo = 2.4


func _ready() -> void:
	super._ready()
	_warten = PAUSE + randf() * 0.4


# ---------------------------------------------------------- Optik

## Grundmaße des flachen Körpers – die Animation staucht sie nur noch.
const KOERPER_Y := 0.34
const KOERPER_SKALA := Vector3(1.42, 0.50, 1.12)
const AUGE_Y := 0.58


## Breit, flach und satt gezeichnet: Von der Spielkamera aus sieht man vor
## allem den Rücken – deshalb sitzen dort die hellen Flecken und die
## Glupschaugen, die die Kröte als "bespringbar" ausweisen.
## Mitgeliefertes Modell für diesen Gegner.
## Laubfrosch von Quaternius – flach und breit wie die eigene Kröte.
func fremdmodell() -> Dictionary:
	# Das Modell blickt nach +Z, das Spiel erwartet −Z – ohne die halbe
	# Drehung hüpft die Kröte rückwärts.
	return {"datei": "kroete", "groesse": 1.15, "drehung": PI,
			"farben": {"Green": farbe_fremdmodell}}


func _baue() -> void:
	# Dunkle, warzige Sumpfhaut
	var haut := StandardMaterial3D.new()
	haut.albedo_texture = Materialbibliothek.rauschtextur(4711, 0.9,
			farbe_haut, farbe_haut_hell)
	haut.uv1_triplanar = true
	haut.uv1_scale = Vector3(2.2, 2.2, 2.2)
	haut.roughness = 0.5

	var bauch_mat := Materialbibliothek.einfarbig(farbe_bauch, 0.7)
	var fleck_mat := Materialbibliothek.einfarbig(farbe_flecken, 0.65)
	var warze_mat := Materialbibliothek.einfarbig(farbe_warzen, 0.75)
	var sack_mat := Materialbibliothek.einfarbig(farbe_kehlsack, 0.5)
	var dunkel := Materialbibliothek.einfarbig(farbe_maul, 0.6)
	var augapfel := Materialbibliothek.einfarbig(farbe_auge, 0.25)

	# Sehr breiter, sehr flacher Körper
	_koerper = _teil(modell, _kugel(0.5, 16, 10), haut, Vector3(0.0, KOERPER_Y, 0.0),
			Vector3.ZERO, KOERPER_SKALA, "Koerper")

	# Kräftig heller Bauch – zeichnet die flache Silhouette nach
	_teil(modell, _kugel(0.46, 14, 8), bauch_mat, Vector3(0.0, 0.19, 0.02),
			Vector3.ZERO, Vector3(1.24, 0.34, 0.96), "Bauch")

	# Helle Rückenflecken: die Aufsprungfläche
	var flecken: Array = [[0.0, 0.10, 0.15], [-0.34, 0.14, 0.115],
			[0.34, 0.14, 0.115], [0.0, -0.24, 0.10]]
	for i in flecken.size():
		var f = flecken[i]
		var y: float = KOERPER_Y + 0.245 - absf(f[0]) * 0.11 - absf(f[1]) * 0.10
		var fleck := _teil(modell, _kugel(f[2], 10, 6), fleck_mat,
				Vector3(f[0], y, f[1]), Vector3.ZERO,
				Vector3(1.25, 0.30, 1.05), "Fleck%d" % i)
		fleck.name = "Fleck%d" % i

	# Dunkle Warzen dazwischen
	var warzen: Array = [[-0.20, -0.10], [0.20, -0.10], [-0.46, -0.02], [0.46, -0.02]]
	for i in warzen.size():
		var w = warzen[i]
		var y: float = KOERPER_Y + 0.235 - absf(w[0]) * 0.16
		_teil(modell, _kugel(0.075, 8, 5), warze_mat, Vector3(w[0], y, w[1]),
				Vector3.ZERO, Vector3(1.0, 0.7, 1.0), "Warze%d" % i)

	# Breites Maul als dunkler Spalt, darunter eine helle Lippe
	_teil(modell, _quader(Vector3(0.60, 0.09, 0.14)), dunkel,
			Vector3(0.0, 0.28, -0.45), Vector3(8.0, 0.0, 0.0), Vector3.ONE, "Maul")
	_teil(modell, _quader(Vector3(0.54, 0.07, 0.12)), bauch_mat,
			Vector3(0.0, 0.205, -0.44), Vector3(8.0, 0.0, 0.0), Vector3.ONE, "Lippe")

	# Kehlsack, der sich beim Quaken aufplustert
	_kehlsack = _teil(modell, _kugel(0.24, 12, 7), sack_mat,
			Vector3(0.0, 0.14, -0.38), Vector3.ZERO, Vector3(1.15, 0.75, 0.85), "Kehlsack")

	# Zwei große Glupschaugen oben auf dem Kopf, mit dunklem Wulst darüber
	for seite: float in [-1.0, 1.0]:
		_teil(modell, _kugel(0.19, 10, 6), haut,
				Vector3(0.29 * seite, AUGE_Y - 0.02, -0.08), Vector3.ZERO,
				Vector3(1.05, 0.60, 1.05), "Augenwulst")
		var auge := _teil(modell, _kugel(0.145, 12, 8), augapfel,
				Vector3(0.30 * seite, AUGE_Y, -0.26), Vector3.ZERO, Vector3.ONE, "Auge")
		_augen.append(auge)
		_teil(auge, _kugel(0.088, 8, 6), dunkel, Vector3(0.0, 0.01, -0.085),
				Vector3.ZERO, Vector3(1.0, 1.0, 0.65), "Pupille")
		# Grünes Oberlid: sonst wirkt der Augapfel von der Seite wie ein Ball
		_teil(auge, _kugel(0.152, 10, 6), haut, Vector3(0.0, 0.055, 0.02),
				Vector3.ZERO, Vector3(1.0, 0.62, 1.0), "Lid")

	# Vier weit abgespreizte Beine mit hellen Schwimmfüßen
	var bein_gitter := CapsuleMesh.new()
	bein_gitter.radius = 0.11
	bein_gitter.height = 0.56
	bein_gitter.radial_segments = 8
	bein_gitter.rings = 2
	for seite: float in [-1.0, 1.0]:
		for vorn: float in [-1.0, 1.0]:
			var ruhe := 68.0 * seite
			var bein := _teil(modell, bein_gitter, haut,
					Vector3(0.50 * seite, 0.20, 0.32 * vorn),
					Vector3(0.0, 0.0, ruhe), Vector3.ONE, "Bein")
			_beine.append(bein)
			_bein_ruhe.append(ruhe)
			# Schwimmhautfuß
			_teil(bein, _quader(Vector3(0.24, 0.07, 0.30)), bauch_mat,
					Vector3(0.0, -0.30, 0.0), Vector3(0.0, 0.0, -ruhe),
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
		_koerper.scale = Vector3(KOERPER_SKALA.x * (1.0 + s),
				KOERPER_SKALA.y * (1.0 - s), KOERPER_SKALA.z * (1.0 + s))

	if is_instance_valid(_kehlsack):
		var pumpen := 1.0 + sin(_phase * 2.2) * 0.2 + _stauchung * 0.35
		_kehlsack.scale = Vector3(pumpen, pumpen * 0.88, pumpen * 0.94)

	# Augen ducken sich beim Stauchen mit
	for auge in _augen:
		if is_instance_valid(auge):
			auge.position.y = AUGE_Y - _stauchung * 0.11

	# In der Luft zieht die Kröte die Beine an
	for i in _beine.size():
		var bein := _beine[i]
		if is_instance_valid(bein):
			var faktor := 0.55 if _in_luft else 1.0
			bein.rotation_degrees.z = _bein_ruhe[i] * faktor
			bein.position.y = 0.20 + (0.1 if _in_luft else 0.0)


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Der Drehschlag schleudert sie seitlich weg.
	_wegflug = _weg_richtung() * 8.0 + Vector3.UP * 6.5
	# Die Hüpfhöhe steckt im Modell, nicht in der Position; sie muss beim
	# Wegflug auf null, sonst schwebte die Kröte um ihren Hüpfbogen zu hoch.
	_hoehe = 0.0
	_setze_hoehe(0.0)


func _todesanimation(delta: float) -> void:
	# Überschlägt sich im Flug und wird dabei kleiner.
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.x += delta * 8.0
		modell.rotation.z += delta * 12.0
		modell.scale = modell.scale.lerp(Vector3(0.6, 0.6, 0.6), minf(delta * 3.0, 1.0))


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Kröte erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Eine besiegte Kröte wird nicht angefasst: Ihre Todesanimation steckt in
## Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_beine.clear()
	_bein_ruhe.clear()
	_augen.clear()
	_koerper = null
	_kehlsack = null
	_baue()
	_fremdmodell_setzen()
