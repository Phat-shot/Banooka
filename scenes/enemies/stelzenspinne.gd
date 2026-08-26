extends Gegner
class_name Stelzenspinne
## Große Spinne, die breitbeinig über dem Weg steht.
##
## NUR durch den Slide (oder den Bauchplatscher) zu besiegen: Man rutscht
## zwischen ihren Beinen hindurch und fegt sie ihr weg. Draufspringen geht
## NICHT – der Rücken trägt Stacheln, wer dort landet, nimmt Schaden.
##
## Die Silhouette ist die Spielanleitung: hoher Leib auf langen Beinen,
## darunter eine deutliche Lücke. Genau deshalb steht hier eine Spinne und
## kein gedrungenes Tier – wo keine Lücke zu sehen ist, kommt niemand auf
## die Idee, hindurchzurutschen.
##
## Bewegung: stakst langsam seitlich hin und her und stößt gelegentlich mit
## dem Vorderleib nach unten zu.

const STOSS_DAUER := 0.9         ## Wie lange ein Zustoßen dauert
const STOSS_ABSTAND_MIN := 2.5   ## Kürzeste Pause zwischen zwei Stößen
const STOSS_ABSTAND_MAX := 4.5   ## Längste Pause zwischen zwei Stößen
const HUEFT_HOEHE := 1.05        ## Höhe des Beinansatzes über dem Boden
const RUMPF_Y := 1.30            ## Hinterleib
const VORDERLEIB_Y := 1.24       ## Vorderleib mit Augen, stößt nach unten
const BEINE := 8

# ---------------------------------------------------------- Farben
#
# Die Spinne steht in mehr Leveln als in dem Wald, für den sie gebaut
# wurde. Damit ein Level sie in seine eigene Palette holen kann, ohne
# dass ein zweiter Gegner entstehen muss, sind ihre Flächen einzeln
# einstellbar. Vorgabe ist überall der bisherige Ton: Wer nichts setzt,
# sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Der Stachelkamm auf dem Rücken sagt
# "hier nicht landen", die Lücke zwischen den Beinen sagt "hier durch".
# Der Kamm muss deshalb HELL gegen den Leib stehen bleiben, und die Beine
# müssen sich vom Leib absetzen – sonst verschwindet die Lücke und mit
# ihr die Anleitung.

## Hinterleib und Vorderleib – die dunkle Grundfläche.
@export var farbe_leib: Color = Farben.FELS_DUNKEL.darkened(0.45):
	set(wert):
		farbe_leib = wert
		_neu_faerben()
## Beine und Kieferklauen. Heller als der Leib, damit die Lücke zu sehen ist.
@export var farbe_beine: Color = Farben.FELS_DUNKEL.darkened(0.2):
	set(wert):
		farbe_beine = wert
		_neu_faerben()
## Stachelkamm auf dem Rücken – die Warnung vor dem Draufspringen.
@export var farbe_stacheln: Color = Farben.WARNUNG:
	set(wert):
		farbe_stacheln = wert
		_neu_faerben()
## Haupt- und Nebenaugen.
@export var farbe_augen: Color = Color(0.95, 0.15, 0.12):
	set(wert):
		farbe_augen = wert
		_neu_faerben()
## Leibfarbe der mitgelieferten Spinnenfigur.
##
## Eigener Wert und nicht `farbe_leib`: Das fremde Modell bringt seinen
## eigenen, fast schwarzen Ton mit, und die Vorgabe ist genau dieser Ton –
## so sieht die Spinne aus wie bisher, solange niemand sie umfärbt. Wer
## sie in eine andere Palette holt, setzt beide.
@export var farbe_fremdmodell: Color = Color(0.225949, 0.225949, 0.225949):
	set(wert):
		farbe_fremdmodell = wert
		_neu_faerben()


var _stoss_zeit := 0.0
var _stoss_laeuft := 0.0

var _rumpf: MeshInstance3D
var _vorderleib: Node3D
var _beine: Array[Node3D] = []


func _init() -> void:
	# Nur der Slide fegt ihr die Beine weg.
	besiegbar_durch = Angriff.SLIDE | Angriff.SLAM
	patrouille_weite = 3.5
	tempo = 1.3


func _ready() -> void:
	super._ready()
	_stoss_zeit = randf_range(STOSS_ABSTAND_MIN, STOSS_ABSTAND_MAX)


## Mitgeliefertes Modell für diesen Gegner.
## Spinne von Quaternius. Eingepasst wird hier nach der HÖHE und nicht nach
## der größten Achse: Das Modell ist breit und flach, auf die Beinspanne
## eingepasst stünde es zu tief über dem Boden – und dann fehlt die Lücke,
## durch die man rutschen soll.
func fremdmodell() -> Dictionary:
	return {"datei": "spinne", "groesse": 1.30, "nach_hoehe": true,
			"drehung": PI, "farben": {"Material": farbe_fremdmodell}}


# ---------------------------------------------------------- Optik

## Selbstgebaute Ausweichoptik, wenn kein Modell da ist: dunkler Leib,
## acht helle Beine, roter Stachelkamm auf dem Rücken. Der Kamm sagt
## unmissverständlich "hier nicht landen".
func _baue() -> void:
	var panzer := Materialbibliothek.fell(farbe_leib)
	var gelenk := Materialbibliothek.einfarbig(farbe_beine, 0.6)
	var stachel_mat := Materialbibliothek.leuchtend(farbe_stacheln, 0.9)
	var augapfel := Materialbibliothek.leuchtend(farbe_augen, 1.2)

	# Acht Beine, gleichmäßig um den Leib verteilt
	for i in BEINE:
		var seite := -1.0 if i < BEINE / 2 else 1.0
		var reihe := float(i % (BEINE / 2)) - 1.5
		var bein := Node3D.new()
		bein.name = "Bein%d" % i
		bein.position = Vector3(seite * 0.22, HUEFT_HOEHE, reihe * 0.20)
		modell.add_child(bein)
		# Oberschenkel schräg nach außen, Unterschenkel senkrecht nach unten
		_teil(bein, _zylinder(0.055, 0.045, 0.62, 6), gelenk,
				Vector3(seite * 0.26, 0.06, reihe * 0.10),
				Vector3(0.0, 0.0, deg_to_rad(-38.0 * seite)), Vector3.ONE, "Schenkel")
		_teil(bein, _zylinder(0.045, 0.03, HUEFT_HOEHE, 6), gelenk,
				Vector3(seite * 0.5, -HUEFT_HOEHE * 0.5 + 0.1, reihe * 0.18),
				Vector3.ZERO, Vector3.ONE, "Unterschenkel")
		_beine.append(bein)

	# Hinterleib: der dicke, hohe Teil – aus der Spielkamera die Silhouette
	_rumpf = _teil(modell, _kugel(0.34, 12, 9), panzer,
			Vector3(0.0, RUMPF_Y, 0.30), Vector3.ZERO,
			Vector3(1.0, 0.86, 1.25), "Hinterleib")

	# Stachelkamm auf dem Rücken: "hier nicht landen"
	for i in 4:
		var laenge := 0.26 - absf(float(i) - 1.5) * 0.05
		_teil(_rumpf, _zylinder(0.05, 0.0, laenge, 6), stachel_mat,
				Vector3(0.0, 0.30, 0.22 - float(i) * 0.16), Vector3.ZERO,
				Vector3.ONE, "Stachel%d" % i)

	# Vorderleib mit den Augen – der Teil, der beim Zustoßen nach unten geht
	_vorderleib = Node3D.new()
	_vorderleib.name = "Vorderleib"
	_vorderleib.position = Vector3(0.0, VORDERLEIB_Y, -0.24)
	modell.add_child(_vorderleib)
	_teil(_vorderleib, _kugel(0.24, 10, 8), panzer, Vector3.ZERO,
			Vector3.ZERO, Vector3(1.0, 0.8, 1.1), "Kopf")
	for seite: float in [-1.0, 1.0]:
		_teil(_vorderleib, _kugel(0.055, 7, 5), augapfel,
				Vector3(0.09 * seite, 0.06, -0.20), Vector3.ZERO, Vector3.ONE, "Auge")
		_teil(_vorderleib, _kugel(0.035, 6, 5), augapfel,
				Vector3(0.16 * seite, 0.01, -0.16), Vector3.ZERO, Vector3.ONE, "Nebenauge")
		# Kieferklauen
		_teil(_vorderleib, _zylinder(0.045, 0.0, 0.2, 6), gelenk,
				Vector3(0.07 * seite, -0.14, -0.20),
				Vector3(deg_to_rad(38.0), 0.0, 0.0), Vector3.ONE, "Klaue")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_stoss_zeit -= delta
	if _stoss_zeit <= 0.0 and _stoss_laeuft <= 0.0:
		_stoss_laeuft = STOSS_DAUER
		_stoss_zeit = randf_range(STOSS_ABSTAND_MIN, STOSS_ABSTAND_MAX)

	if _stoss_laeuft > 0.0:
		# Beim Zustoßen bleibt sie stehen
		_stoss_laeuft = maxf(_stoss_laeuft - delta, 0.0)
	else:
		_phase += delta * tempo * 3.2
		_patrouille_schritt(tempo * delta)

	_blick_ausrichten(delta, 3.5)
	_animiere(delta)


## Staksende Schritte, wippender Hinterleib, Zustoßen mit dem Vorderleib.
func _animiere(_delta: float) -> void:
	var laeuft := _stoss_laeuft <= 0.0

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
		_rumpf.position.y = RUMPF_Y + (absf(sin(_phase)) * 0.05 if laeuft else 0.0)

	if is_instance_valid(_vorderleib):
		# Pickbogen: Kopf schnellt nach unten und wieder hoch
		var stoss := 0.0
		if _stoss_laeuft > 0.0:
			stoss = sin((1.0 - _stoss_laeuft / STOSS_DAUER) * PI)
		_vorderleib.rotation.x = stoss * 0.9
		_vorderleib.position.y = VORDERLEIB_Y - stoss * 0.42



# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Die Beine sind weg – sie fliegt nicht, sie kippt um.
	_wegflug = Vector3.ZERO


func _todesanimation(delta: float) -> void:
	if not is_instance_valid(modell):
		return
	# Beine knicken weg, die ganze Spinne kippt zur Seite
	modell.rotation.z = lerp_angle(modell.rotation.z, PI * 0.55, minf(delta * 7.0, 1.0))
	modell.scale = modell.scale.lerp(Vector3(0.9, 0.75, 0.9), minf(delta * 4.0, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = lerp_angle(bein.rotation.x, 1.4, minf(delta * 8.0, 1.0))


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Spinne erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Eine besiegte Spinne wird nicht angefasst: Ihre Todesanimation steckt
## in Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_beine.clear()
	_rumpf = null
	_vorderleib = null
	_baue()
	_fremdmodell_setzen()
