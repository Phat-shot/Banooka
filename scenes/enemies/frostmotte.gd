extends Gegner
class_name Frostmotte
## Frostmotte – schwebt über dem Weg und kreuzt ihn langsam.
##
## NUR durch den Drehschlag (oder den Bauchplatscher) zu besiegen.
##
## Das ist am Modell abzulesen: Auf dem Rücken sitzt ein Kamm aus
## Eiszapfen – da springt niemand drauf. Und sie schwebt über Slide-Höhe,
## unten ist nichts zu erwischen. Frei und weich bleibt allein die Flanke,
## und genau dorthin reicht der Drehschlag.
##
## Sie ist die "schlagen"-Rolle im Schneelevel – dieselbe Aufgabe wie die
## Sumpfkröte im Wald, aber mit einer Silhouette, die ins Setting passt.

const SCHWEBE_HOEHE := 1.35   ## Ruhehöhe über dem Boden
const SCHWEBE_HUB := 0.32     ## wie weit sie dabei auf und ab geht
const FLUEGEL_TAKT := 13.0    ## Schlagfrequenz der Flügel

# ---------------------------------------------------------- Farben
#
# Die Motte schwebt in mehr Leveln als in dem Schnee, für den sie gebaut
# wurde. Damit ein Level sie in seine eigene Palette holen kann, ohne
# dass ein zweiter Gegner entstehen muss, sind ihre Flächen einzeln
# einstellbar. Vorgabe ist überall der bisherige Ton: Wer nichts setzt,
# sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Der Zapfenkamm auf dem Rücken ist
# die Absage an das Draufspringen, die weiche Flanke die Stelle, an der
# der Drehschlag wirkt. Die Zapfen müssen deshalb HELL gegen den Pelz
# stehen bleiben; verschwinden sie im Pelz, sucht der Spieler wieder.

## Pelziger Leib und Kopf.
@export var farbe_pelz: Color = Farben.FROSTTIER:
	set(wert):
		farbe_pelz = wert
		_neu_faerben()
## Die durchscheinenden Flügel.
@export var farbe_fluegel: Color = Farben.EIS_HELL:
	set(wert):
		farbe_fluegel = wert
		_neu_faerben()
## Zapfenkamm auf dem Rücken – die Absage. Hell halten.
@export var farbe_zapfen: Color = Farben.EIS_HELL:
	set(wert):
		farbe_zapfen = wert
		_neu_faerben()
## Fühler.
@export var farbe_fuehler: Color = Farben.FROSTTIER.darkened(0.4):
	set(wert):
		farbe_fuehler = wert
		_neu_faerben()
## Augen.
@export var farbe_augen: Color = Farben.KRISTALL_BLAU:
	set(wert):
		farbe_augen = wert
		_neu_faerben()


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
	var pelz := Materialbibliothek.fell(farbe_pelz)
	var fluegelstoff := Materialbibliothek.transparent(farbe_fluegel, 0.55)
	var dunkel := Materialbibliothek.einfarbig(farbe_fuehler, 0.5)
	var auge := Materialbibliothek.leuchtend(farbe_augen, 1.4)

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

	# Zapfenkamm auf dem Rücken: die Warnung, dass Draufspringen ausfällt.
	var eis := Materialbibliothek.kristall(farbe_zapfen)
	for i in 5:
		var laenge := 0.16 + sin(float(i) / 4.0 * PI) * 0.12
		_teil(_koerper, _zylinder(0.038, 0.004, laenge, 5), eis,
				Vector3(0.0, 0.16, -0.16 + i * 0.09),
				Vector3(-14.0 + i * 7.0, 0.0, 0.0), Vector3.ONE, "Zapfen")


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


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Motte erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Eine besiegte Motte wird nicht angefasst: Ihre Todesanimation steckt in
## Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_fluegel.clear()
	_fuehler.clear()
	_koerper = null
	_baue()
	_fremdmodell_setzen()
