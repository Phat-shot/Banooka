extends Gegner
class_name Panzerkaefer
## Schwer gepanzerter Käfer.
##
## NUR durch die Spin-Attacke (oder den Bauchplatscher) zu besiegen:
## Sein Panzer ist zu hart zum Draufspringen und er ist zu flach, als
## dass ein Slide ihn erwischen würde.
##
## Bewegung: patrouilliert stur geradeaus und dreht an den Endpunkten
## umständlich um. Beim Besiegen wird er weggeschleudert.

const DREH_DAUER := 0.55     ## So lange braucht er zum Umdrehen
const SCHRITT_TEMPO := 5.0   ## Taktrate des Sechsbeinlaufs

var _dreht := 0.0

var _panzer: MeshInstance3D
var _kopf: Node3D
var _beine: Array[Node3D] = []
var _fuehler: Array[Node3D] = []


func _init() -> void:
	# Nur der Spin knackt den Panzer.
	besiegbar_durch = Angriff.SPIN | Angriff.SLAM
	patrouille_weite = 5.0
	tempo = 1.9


# ---------------------------------------------------------- Optik

## Tiefschwarzer Panzer mit gelben Warnstreifen, dicht über dem Boden.
## Die Streifen liegen quer über dem Rücken und sind daher genau das,
## was die Spielkamera von schräg oben zu sehen bekommt.
func _baue() -> void:
	var panzer_mat := Materialbibliothek.einfarbig(Farben.FELS.darkened(0.72), 0.35, 0.25)
	var chitin := Materialbibliothek.einfarbig(Farben.RINDE.darkened(0.55), 0.55)
	var streifen_mat := Materialbibliothek.einfarbig(Farben.KISTE_FEDER, 0.5)
	var naht_mat := Materialbibliothek.einfarbig(Farben.FELS_HELL.darkened(0.1), 0.4, 0.3)
	var glut := Materialbibliothek.leuchtend(Farben.WARNUNG, 1.3)

	# --- Sechs Laufbeine, jeweils an einem eigenen Drehpunkt ---
	for seite: float in [-1.0, 1.0]:
		for paar in 3:
			var huefte := Node3D.new()
			huefte.name = "Huefte"
			huefte.position = Vector3(0.34 * seite, 0.26, -0.36 + float(paar) * 0.36)
			modell.add_child(huefte)
			_beine.append(huefte)

			_teil(huefte, _zylinder(0.055, 0.045, 0.34, 6), chitin,
					Vector3(0.15 * seite, -0.05, 0.0),
					Vector3(0.0, 0.0, 66.0 * seite), Vector3.ONE, "Schenkel")
			_teil(huefte, _zylinder(0.045, 0.025, 0.30, 6), chitin,
					Vector3(0.28 * seite, -0.19, 0.0),
					Vector3(0.0, 0.0, 14.0 * seite), Vector3.ONE, "Schiene")

	# --- Sehr flacher, breiter Panzer ---
	_panzer = _teil(modell, _kugel(0.55, 16, 10), panzer_mat, Vector3(0.0, 0.30, 0.06),
			Vector3.ZERO, Vector3(1.02, 0.44, 1.30), "Panzer")

	# Drei gelbe Warnstreifen quer über den Rücken. Sie hängen am Panzer
	# und werden mit ihm gestaucht, liegen also immer sauber auf.
	var streifen: Array = [[-0.30, 0.500], [0.0, 0.565], [0.30, 0.500]]
	for i in streifen.size():
		var s = streifen[i]
		_teil(_panzer, _kugel(s[1], 14, 8), streifen_mat, Vector3(0.0, 0.0, s[0]),
				Vector3.ZERO, Vector3(1.0, 1.0, 0.085), "Warnstreifen%d" % i)

	# Mittelnaht als Beschlag
	_teil(_panzer, _quader(Vector3(0.07, 0.07, 0.52)), naht_mat,
			Vector3(0.0, 0.50, 0.0), Vector3.ZERO, Vector3(1.0, 2.2, 1.0), "Naht")

	# --- Kopf mit kräftigen Zangen und Fühlern ---
	_kopf = Node3D.new()
	_kopf.name = "Kopf"
	_kopf.position = Vector3(0.0, 0.26, -0.64)
	modell.add_child(_kopf)

	_teil(_kopf, _kugel(0.29, 12, 8), panzer_mat, Vector3.ZERO,
			Vector3.ZERO, Vector3(0.92, 0.66, 0.82), "Schaedel")
	_teil(_kopf, _kugel(0.24, 12, 8), streifen_mat, Vector3(0.0, 0.0, -0.02),
			Vector3.ZERO, Vector3(1.16, 0.86, 0.30), "Stirnband")

	for seite: float in [-1.0, 1.0]:
		# Kräftige Zangen nach vorn
		_teil(_kopf, _zylinder(0.075, 0.0, 0.44, 6), naht_mat,
				Vector3(0.13 * seite, -0.05, -0.24),
				Vector3(-80.0, 0.0, 20.0 * seite), Vector3.ONE, "Zange")
		# Glühende Augenpunkte
		_teil(_kopf, _kugel(0.07, 8, 6), glut, Vector3(0.155 * seite, 0.06, -0.14),
				Vector3.ZERO, Vector3.ONE, "Auge")
		# Fühler an eigenem Drehpunkt, damit sie wackeln können
		var wurzel := Node3D.new()
		wurzel.name = "Fuehlerwurzel"
		wurzel.position = Vector3(0.11 * seite, 0.12, -0.14)
		_kopf.add_child(wurzel)
		_fuehler.append(wurzel)
		_teil(wurzel, _zylinder(0.032, 0.015, 0.46, 6), chitin,
				Vector3(0.09 * seite, 0.19, -0.08),
				Vector3(-28.0, 0.0, 24.0 * seite), Vector3.ONE, "Fuehler")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	if _dreht > 0.0:
		# Umdrehen: kurz stehen bleiben und sich neu ausrichten
		_dreht -= delta
	else:
		_phase += delta * tempo * SCHRITT_TEMPO
		if _patrouille_schritt(tempo * delta):
			_dreht = DREH_DAUER

	_blick_ausrichten(delta, 6.0)
	_animiere()


## Sechsbeinlauf im Dreifußgang, wippender Panzer, tastende Fühler.
func _animiere() -> void:
	var laeuft := _dreht <= 0.0

	for i in _beine.size():
		var bein := _beine[i]
		if not is_instance_valid(bein):
			continue
		# Dreifußgang: benachbarte Beine laufen gegenphasig
		var versatz := PI * float((i % 3) + int(i / 3))
		var schwung := sin(_phase + versatz) if laeuft else 0.0
		bein.rotation.x = schwung * 0.4
		bein.position.y = 0.26 + maxf(schwung, 0.0) * 0.04

	if is_instance_valid(_panzer):
		_panzer.position.y = 0.30 + (sin(_phase * 2.0) * 0.02 if laeuft else 0.0)
		_panzer.rotation.z = sin(_phase) * 0.05 if laeuft else 0.0

	for i in _fuehler.size():
		var wurzel := _fuehler[i]
		if is_instance_valid(wurzel):
			var seite := -1.0 if i == 0 else 1.0
			wurzel.rotation.x = sin(_zeit * 3.4 + float(i)) * 0.25
			wurzel.rotation.y = cos(_zeit * 2.6 + float(i)) * 0.2 * seite

	if is_instance_valid(_kopf):
		_kopf.rotation.y = sin(_zeit * 1.6) * 0.12


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Der Spin schleudert ihn kräftig davon.
	_wegflug = _weg_richtung() * 7.5 + Vector3.UP * 7.5


func _todesanimation(delta: float) -> void:
	# Überschlägt sich und landet auf dem Rücken.
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.x += delta * 11.0
		modell.rotation.z += delta * 7.0
		modell.scale = modell.scale.lerp(Vector3(0.7, 0.7, 0.7), minf(delta * 2.5, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = sin(_zeit * 26.0) * 0.8
