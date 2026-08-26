extends Gegner
class_name Schneewiesel
## Schneewiesel – schlank, aufgerichtet, mit einem Kranz aus Eiszapfen
## auf dem Kopf.
##
## NUR durch den Slide (oder den Bauchplatscher) zu besiegen.
##
## Das ist am Modell abzulesen: Oben der Zapfenkranz auf dem Kopf – da
## springt niemand drauf. Auf Schlaghöhe ein Kragen aus gefrorenen
## Borsten – da fasst kein Drehschlag hinein. Frei bleiben allein die
## dünnen Läufe unten, und die holt der Slide.
##
## Es ist die "Slide"-Rolle im Schneelevel. Bewegung: schnelle Sprints mit
## kurzen Pausen, in denen es sich witternd aufrichtet.

const SPRINT := 4.6           ## Tempo während eines Sprints
const SPRINT_DAUER := 0.9
const PAUSE_DAUER := 0.7
const WITTERN := 0.35         ## wie hoch es sich in der Pause aufrichtet

# ---------------------------------------------------------- Farben
#
# Das Wiesel läuft in mehr Leveln als in dem Schnee, für den es gebaut
# wurde – bis in die Raumstation. Damit ein Level es in seine eigene
# Palette holen kann, ohne dass ein zweiter Gegner entstehen muss, sind
# seine Flächen einzeln einstellbar. Vorgabe ist überall der bisherige
# Ton: Wer nichts setzt, sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Zapfenkranz oben und Borstenkragen
# auf Schlaghöhe sind die Absagen, die dünnen Läufe unten die Einladung
# für den Slide. Zapfen und Borsten müssen deshalb HELL gegen das Fell
# stehen bleiben, und die Läufe dürfen nicht in der Silhouette
# verschwinden – sonst sieht niemand mehr, wo etwas zu holen ist.

## Rücken- und Halsfell.
@export var farbe_fell: Color = Farben.FROSTTIER_HELL:
	set(wert):
		farbe_fell = wert
		_neu_faerben()
## Kruppe und Läufe – dunkler, damit die Beine als Beine lesbar sind.
@export var farbe_fell_dunkel: Color = Farben.FROSTTIER.darkened(0.25):
	set(wert):
		farbe_fell_dunkel = wert
		_neu_faerben()
## Bauchseite.
@export var farbe_bauch: Color = Farben.FROSTTIER_BAUCH:
	set(wert):
		farbe_bauch = wert
		_neu_faerben()
## Zapfenkranz und Borstenkragen – die beiden Absagen. Hell halten.
@export var farbe_zapfen: Color = Farben.EIS_HELL:
	set(wert):
		farbe_zapfen = wert
		_neu_faerben()
## Nasenspiegel.
@export var farbe_nase: Color = Farben.NASE:
	set(wert):
		farbe_nase = wert
		_neu_faerben()
## Augen.
@export var farbe_augen: Color = Farben.KRISTALL_BLAU:
	set(wert):
		farbe_augen = wert
		_neu_faerben()


var _rumpf: Node3D
var _hals: Node3D
var _zapfen: Array[MeshInstance3D] = []
var _laeufe: Array[Node3D] = []
var _sprint_rest := 0.0
var _pause_rest := 0.0
var _aufrichtung := 0.0


func _init() -> void:
	# Der Zapfenkranz verhindert das Draufspringen.
	besiegbar_durch = Angriff.SLIDE | Angriff.SLAM
	patrouille_weite = 6.0
	tempo = SPRINT
	fruechte = 2


func _ready() -> void:
	super._ready()
	_pause_rest = PAUSE_DAUER + randf() * 0.5


# ---------------------------------------------------------- Optik

## Langer, schmaler Körper auf hohen Läufen, dazu der Zapfenkranz. Die
## Zapfen zeigen nach oben und sind hell – sie sind die Warnung, dass
## Draufspringen hier nicht geht.
func _baue() -> void:
	# Weiß auf Schnee war unsichtbar – dunkler Rücken, heller Bauch.
	var fell := Materialbibliothek.fell(farbe_fell)
	var dunkelfell := Materialbibliothek.fell(farbe_fell_dunkel)
	var eis := Materialbibliothek.kristall(farbe_zapfen)
	var nase := Materialbibliothek.einfarbig(farbe_nase, 0.35)
	var auge := Materialbibliothek.leuchtend(farbe_augen, 1.1)

	_rumpf = Node3D.new()
	_rumpf.name = "Rumpf"
	_rumpf.position.y = 0.52
	modell.add_child(_rumpf)

	var leib := _teil(_rumpf, _zylinder(0.17, 0.15, 0.72, 10), fell,
			Vector3.ZERO, Vector3(90.0, 0.0, 0.0), Vector3.ONE, "Leib")
	_teil(_rumpf, _kugel(0.15), dunkelfell, Vector3(0.0, -0.05, 0.3),
			Vector3.ZERO, Vector3(1.0, 0.85, 1.2), "Kruppe")
	_teil(_rumpf, _kugel(0.13), Materialbibliothek.fell(farbe_bauch),
			Vector3(0.0, -0.13, 0.0), Vector3.ZERO, Vector3(0.9, 0.6, 2.2), "Bauch")

	_hals = Node3D.new()
	_hals.name = "Hals"
	_hals.position = Vector3(0.0, 0.1, -0.3)
	_rumpf.add_child(_hals)
	_teil(_hals, _zylinder(0.11, 0.09, 0.3, 8), fell, Vector3(0.0, 0.14, 0.0),
			Vector3.ZERO, Vector3.ONE, "Halsstueck")
	var kopf := _teil(_hals, _kugel(0.14), fell, Vector3(0.0, 0.34, -0.05),
			Vector3.ZERO, Vector3(0.9, 0.85, 1.25), "Kopf")
	_teil(kopf, _kugel(0.045), nase, Vector3(0.0, -0.02, -0.17),
			Vector3.ZERO, Vector3.ONE, "Nase")
	for seite: float in [-1.0, 1.0]:
		_teil(kopf, _kugel(0.042), auge, Vector3(seite * 0.075, 0.05, -0.09),
				Vector3.ZERO, Vector3.ONE, "Auge")

	# Zapfenkranz: fünf Spitzen nach oben
	for i in 5:
		var winkel := (float(i) / 5.0) * TAU
		var zapfen := _teil(kopf, _zylinder(0.035, 0.004, 0.3, 5), eis,
				Vector3(cos(winkel) * 0.09, 0.16, sin(winkel) * 0.09),
				Vector3(cos(winkel) * 16.0, 0.0, -sin(winkel) * 16.0),
				Vector3.ONE, "Zapfen")
		_zapfen.append(zapfen)

	# Borstenkragen auf Schlaghöhe: die Warnung vor dem Drehschlag.
	# Wie beim Klingenkranz der Krabbe: Drehpunkt schwenken, Borste darin
	# nur noch nach außen kippen.
	var borste := Materialbibliothek.kristall(farbe_zapfen)
	for i in 12:
		var dreh := Node3D.new()
		dreh.name = "Borstenpunkt"
		dreh.position.z = -0.16
		dreh.rotation.y = (float(i) / 12.0) * TAU
		_rumpf.add_child(dreh)
		var lang := 0.28 + (0.09 if i % 2 == 0 else 0.0)
		_teil(dreh, _zylinder(0.034, 0.004, lang, 5), borste,
				Vector3(0.0, 0.05, 0.17), Vector3(-76.0, 0.0, 0.0),
				Vector3.ONE, "Borste")

	# Vier hohe Läufe
	for seite: float in [-1.0, 1.0]:
		for vorn in [true, false]:
			var huefte := Node3D.new()
			huefte.name = "Lauf"
			huefte.position = Vector3(seite * 0.12, -0.02,
					-0.22 if vorn else 0.24)
			_rumpf.add_child(huefte)
			_teil(huefte, _zylinder(0.045, 0.035, 0.46, 6), dunkelfell,
					Vector3(0.0, -0.24, 0.0), Vector3.ZERO, Vector3.ONE, "Bein")
			_laeufe.append(huefte)


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	if _sprint_rest > 0.0:
		_sprint_rest -= delta
		_patrouille_schritt(SPRINT * delta)
		_aufrichtung = maxf(_aufrichtung - delta * 4.0, 0.0)
		if _sprint_rest <= 0.0:
			_pause_rest = PAUSE_DAUER
	else:
		_pause_rest -= delta
		# In der Pause richtet es sich auf und wittert
		_aufrichtung = minf(_aufrichtung + delta * 3.0, 1.0)
		if _pause_rest <= 0.0:
			_sprint_rest = SPRINT_DAUER

	_blick_ausrichten(delta, 9.0)

	if is_instance_valid(_rumpf):
		_rumpf.rotation.x = -_aufrichtung * 0.8
		_rumpf.position.y = 0.52 + _aufrichtung * WITTERN
	if is_instance_valid(_hals):
		_hals.rotation.x = -_aufrichtung * 0.4 + sin(_zeit * 2.0) * 0.06

	var takt := 14.0 if _sprint_rest > 0.0 else 0.0
	for i in _laeufe.size():
		var lauf := _laeufe[i]
		if is_instance_valid(lauf):
			lauf.rotation.x = sin(_zeit * takt + i * 1.6) * (0.6 if takt > 0.0 else 0.0)


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Der Slide holt ihm die Läufe weg – es überschlägt sich nach vorn.
	_wegflug = achse() * richtung * 5.0 + Vector3.UP * 4.5


func _todesanimation(delta: float) -> void:
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.x += delta * 10.0
		modell.scale = modell.scale.lerp(Vector3(0.6, 0.6, 0.6), minf(delta * 3.0, 1.0))


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das das Wiesel erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Ein besiegtes Wiesel wird nicht angefasst: Seine Todesanimation steckt
## in Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_zapfen.clear()
	_laeufe.clear()
	_rumpf = null
	_hals = null
	_baue()
	_fremdmodell_setzen()
