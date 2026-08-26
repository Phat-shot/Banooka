extends Gegner
class_name Gletscherkrabbe
## Gletscherkrabbe – breit, flach, mit einem Panzer aus Klareis.
##
## NUR durch Draufspringen (oder den Bauchplatscher) zu besiegen.
##
## Das ist am Modell abzulesen: Rundherum auf Schlag- und Slidehöhe steht
## ein Kranz aus Eisklingen ab – da greift weder Drehschlag noch Slide.
## Frei bleibt allein die Oberseite, und dort leuchtet die Panzernaht als
## Einladung: Genau da hält der Panzer kein Gewicht.
##
## Sie ist die "draufspringen"-Rolle im Schneelevel. Bewegung: seitliches
## Krabbeln mit ruckartigen Richtungswechseln, dazu klappernde Scheren.

const SCHERE_TAKT := 3.2      ## Frequenz des Scherenklapperns
const BEIN_TAKT := 9.0

# ---------------------------------------------------------- Farben
#
# Die Krabbe krabbelt in mehr Leveln als in dem Schnee, für den sie
# gebaut wurde – bis in eine Grabkammer. Damit ein Level sie in seine
# eigene Palette holen kann, ohne dass ein zweiter Gegner entstehen muss,
# sind ihre Flächen einzeln einstellbar. Vorgabe ist überall der
# bisherige Ton: Wer nichts setzt, sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Die leuchtende Panzernaht ist die
# Stelle, an der das Draufspringen wirkt, der Klingenkranz ringsum die
# Absage an Schlag und Slide. Naht und Klingen müssen deshalb HELL gegen
# den Panzer stehen bleiben – eine Naht im Ton des Panzers ist keine
# Einladung mehr, sondern eine Fuge.

## Panzerdeckel – die dunkle Grundfläche.
@export var farbe_panzer: Color = Farben.FROSTTIER:
	set(wert):
		farbe_panzer = wert
		_neu_faerben()
## Panzernaht auf dem Rücken. Die Einladung – hell halten.
@export var farbe_naht: Color = Farben.EIS_HELL:
	set(wert):
		farbe_naht = wert
		_neu_faerben()
## Beine, Scheren und Augenstiele.
@export var farbe_chitin: Color = Farben.FROSTTIER.darkened(0.35):
	set(wert):
		farbe_chitin = wert
		_neu_faerben()
## Klingenkranz auf Schlag- und Slidehöhe. Die Absage – hell halten.
@export var farbe_klingen: Color = Farben.EIS_HELL:
	set(wert):
		farbe_klingen = wert
		_neu_faerben()
## Augen auf den Stielen.
@export var farbe_augen: Color = Farben.KRISTALL_VIOLETT:
	set(wert):
		farbe_augen = wert
		_neu_faerben()


var _panzer: MeshInstance3D
var _naht: MeshInstance3D
var _scheren: Array[Node3D] = []
var _beine: Array[Node3D] = []
var _bein_phase: Array[float] = []


func _init() -> void:
	# Nur Gewicht von oben bricht die Panzernaht.
	besiegbar_durch = Angriff.FALLEN | Angriff.SLAM
	patrouille_weite = 4.5
	tempo = 2.2
	abprall_hoehe = 14.0


# ---------------------------------------------------------- Optik

## Flacher Eispanzer mit heller Naht auf dem Rücken. Die Naht ist der
## Hinweis, wo man treffen muss – sie ist von schräg oben genau das, was
## die Spielkamera zeigt.
func _baue() -> void:
	# Undurchsichtig und dunkel: Ein durchscheinender Panzer aus Klareis war
	# auf Schnee schlicht nicht zu sehen.
	var panzer := Materialbibliothek.einfarbig(farbe_panzer, 0.45, 0.15)
	var naht := Materialbibliothek.leuchtend(farbe_naht, 1.4)
	var chitin := Materialbibliothek.einfarbig(farbe_chitin, 0.55)
	var auge := Materialbibliothek.leuchtend(farbe_augen, 1.2)

	_panzer = _teil(modell, _kugel(0.46), panzer, Vector3(0.0, 0.34, 0.0),
			Vector3.ZERO, Vector3(1.35, 0.62, 1.0), "Panzer")
	_naht = _teil(modell, _quader(Vector3(0.10, 0.05, 0.78)), naht,
			Vector3(0.0, 0.62, 0.0), Vector3.ZERO, Vector3.ONE, "Naht")

	# Augen auf kurzen Stielen, nach vorn gerichtet
	for seite: float in [-1.0, 1.0]:
		var stiel := _teil(modell, _zylinder(0.035, 0.03, 0.22, 6), chitin,
				Vector3(seite * 0.18, 0.62, -0.26), Vector3(-18.0, 0.0, 0.0),
				Vector3.ONE, "Augenstiel")
		_teil(stiel, _kugel(0.06), auge, Vector3(0.0, 0.13, 0.0),
				Vector3.ZERO, Vector3.ONE, "Auge")

	# Zwei Scheren vorn
	for seite: float in [-1.0, 1.0]:
		var gelenk := Node3D.new()
		gelenk.name = "Scherenarm"
		gelenk.position = Vector3(seite * 0.5, 0.26, -0.3)
		modell.add_child(gelenk)
		_teil(gelenk, _quader(Vector3(0.16, 0.1, 0.3)), chitin,
				Vector3(seite * 0.1, 0.0, -0.12), Vector3.ZERO, Vector3.ONE, "Arm")
		var oben := _teil(gelenk, _quader(Vector3(0.2, 0.09, 0.26)), chitin,
				Vector3(seite * 0.2, 0.06, -0.3), Vector3.ZERO, Vector3.ONE, "Backe")
		oben.name = "BackeOben"
		_teil(gelenk, _quader(Vector3(0.2, 0.09, 0.26)), chitin,
				Vector3(seite * 0.2, -0.05, -0.3), Vector3.ZERO, Vector3.ONE,
				"BackeUnten")
		_scheren.append(oben)

	# Klingenkranz auf Schlag- und Slidehöhe: die Warnung, dass hier weder
	# Drehschlag noch Slide etwas ausrichtet.
	# Über einen Drehpunkt je Klinge statt über Eulerwinkel: Ein Zylinder
	# liegt auf +Y, und ihn per rotation.x/y gleichzeitig auszurichten und
	# im Kreis zu stellen ergab keine Krone, sondern verstreute Splitter.
	# Der Drehpunkt schwenkt, die Klinge kippt darin nur noch nach außen.
	var klinge := Materialbibliothek.kristall(farbe_klingen)
	for i in 10:
		var dreh := Node3D.new()
		dreh.name = "Klingenpunkt"
		dreh.rotation.y = (float(i) / 10.0) * TAU
		modell.add_child(dreh)
		_teil(dreh, _zylinder(0.075, 0.006, 0.44, 5), klinge,
				Vector3(0.0, 0.30, 0.46), Vector3(-74.0, 0.0, 0.0),
				Vector3.ONE, "Klinge")

	# Sechs Beine
	for seite: float in [-1.0, 1.0]:
		for paar in 3:
			var huefte := Node3D.new()
			huefte.name = "Huefte"
			huefte.position = Vector3(seite * 0.42, 0.24, -0.2 + paar * 0.22)
			modell.add_child(huefte)
			_teil(huefte, _zylinder(0.045, 0.03, 0.34, 5), chitin,
					Vector3(seite * 0.14, -0.14, 0.0),
					Vector3(0.0, 0.0, seite * 52.0), Vector3.ONE, "Bein")
			_beine.append(huefte)
			_bein_phase.append(float(paar) * 1.1 + (0.0 if seite < 0.0 else PI))


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	# Krabben laufen seitwärts – der Körper bleibt quer zur Laufrichtung.
	_patrouille_schritt(tempo * delta)
	if is_instance_valid(modell):
		var d := achse() * richtung
		var ziel := atan2(-d.x, -d.z) + PI * 0.5
		modell.rotation.y = lerp_angle(modell.rotation.y, ziel, minf(delta * 6.0, 1.0))

	for i in _beine.size():
		var bein := _beine[i]
		if is_instance_valid(bein):
			bein.rotation.x = sin(_zeit * BEIN_TAKT + _bein_phase[i]) * 0.42

	var klappern: float = maxf(sin(_zeit * SCHERE_TAKT), 0.0) * 0.5
	for backe in _scheren:
		if is_instance_valid(backe):
			backe.position.y = 0.06 + klappern * 0.09


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Sie wird an Ort und Stelle plattgetreten, der Panzer springt auf.
	_wegflug = Vector3.ZERO


func _todesanimation(delta: float) -> void:
	if is_instance_valid(modell):
		modell.scale = modell.scale.lerp(Vector3(1.4, 0.07, 1.3), minf(delta * 12.0, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = sin(_zeit * 24.0) * 0.9


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Krabbe erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Eine besiegte Krabbe wird nicht angefasst: Ihre Todesanimation steckt
## in der Skalierung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_scheren.clear()
	_beine.clear()
	_bein_phase.clear()
	_panzer = null
	_naht = null
	_baue()
	_fremdmodell_setzen()
