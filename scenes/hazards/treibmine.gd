extends Node3D
class_name Treibmine
## Treibmine: eine stachelige Kugel, die auf dem Wasser dümpelt.
##
## Wer sie berührt, nimmt Schaden. Sie ist mit Absicht NICHT zu besiegen –
## anders als ein Gegner ist sie kein Ziel, sondern ein Hindernis, an dem
## man vorbeimuss. Der Drehschlag hilft hier nicht, nur Ausweichen.
##
## `pendel_weite` lässt sie quer treiben. Erst dadurch wird aus einem
## festen Hindernis eine Frage des Zeitpunkts: Die Lücke zwischen zwei
## gegenläufigen Minen ist mal offen und mal zu.
##
## Damit sie auch von weitem als Gefahr zu lesen ist, trägt sie
## Warnfarbe und einen leuchtenden Ring – im Nebel des Moors ist eine
## dunkle Kugel auf dunklem Wasser sonst schlicht nicht zu sehen.
##
## Mit `kette_hoehe` hängt sie stattdessen an einer Kette von oben herein.
## Das ist kein Schmuck, sondern nötig: Über der Fahrrinne kann keine Mine
## im Wasser liegen, dort fährt das Floß. Eine hängende Mine schwingt über
## das Deck hinweg – ausweichen heißt dann zur Seite gehen oder krabbeln.

## Radius des Minenkörpers in Metern.
@export var radius := 0.62

## Ausschlag der Querbewegung in Metern (0 = steht).
@export var pendel_weite := 0.0

## Dauer einer vollen Hin- und Herbewegung in Sekunden.
@export var pendel_dauer := 4.0

## Richtung des Pendelns in Elternkoordinaten.
@export var pendel_achse := Vector3.RIGHT

## Verschiebt den Takt gegenüber anderen Minen.
@export var phase := 0.0

## Ausschlag des Dümpelns in Metern.
@export var wippen := 0.09

## Länge der Kette nach oben in Metern. 0 = schwimmt im Wasser.
@export var kette_hoehe := 0.0

## Feste Saat für die Stachelstellung.
@export var saat := 0

const STACHEL_ZAHL := 9
const WIPP_TEMPO := 0.75        ## Schwingungen je Sekunde
const RING_HOEHE := -0.12       ## Schwimmring etwas unter der Mitte

var _bild: Node3D
var _kette: Node3D
var _zone: Area3D
var _ruhe := Vector3.ZERO
var _zeit := 0.0


func _ready() -> void:
	add_to_group("treibminen")
	_ruhe = position
	_aufbauen()


func _physics_process(delta: float) -> void:
	_zeit += delta
	var welle := sin(_zeit * TAU / maxf(pendel_dauer, 0.1) + phase * TAU)
	var versatz := pendel_achse.normalized() * (welle * pendel_weite)
	position = _ruhe + versatz
	if is_instance_valid(_bild):
		# Was schwimmt, dümpelt auf und ab; was hängt, bleibt auf Höhe.
		if kette_hoehe <= 0.0:
			_bild.position.y = sin(_zeit * TAU * WIPP_TEMPO + phase * TAU) * wippen
		_bild.rotation.y += delta * 0.6
	if is_instance_valid(_kette):
		_kette_kippen(versatz)


## Kippt die Kette so, dass ihr oberes Ende am festen Aufhängepunkt bleibt,
## während die Mine darunter pendelt. Ohne das wanderte der Haken mit und
## die Kette hinge frei in der Luft.
func _kette_kippen(versatz: Vector3) -> void:
	var soll := (Vector3.UP * kette_hoehe - versatz).normalized()
	var achse := Vector3.UP.cross(soll)
	if achse.length_squared() < 0.000001:
		_kette.basis = Basis()
		return
	_kette.basis = Basis(achse.normalized(), Vector3.UP.angle_to(soll))


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	_bild = Node3D.new()
	_bild.name = "Bild"
	add_child(_bild)

	var rng := PropWerkzeug.zufall(saat if saat != 0 else 1)

	# Körper und Stacheln in einem Netz – das spart Knoten und Draw-Calls.
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(radius, 9, 6), Transform3D())
	for i in STACHEL_ZAHL:
		# Nur die obere Halbkugel bestacheln: Was unter Wasser sitzt,
		# sieht ohnehin niemand, und die Dreiecke fehlen im Web-Export.
		var hoch := rng.randf_range(0.05, 0.95)
		var winkel := TAU * float(i) / float(STACHEL_ZAHL) \
				+ rng.randf_range(-0.2, 0.2)
		var richtung := Vector3(cos(winkel) * sqrt(1.0 - hoch * hoch), hoch,
				sin(winkel) * sqrt(1.0 - hoch * hoch)).normalized()
		var laenge := radius * rng.randf_range(0.42, 0.6)
		var stachel := PropWerkzeug.stumpf(radius * 0.17, 0.0, laenge, 5, true)
		var basis := Basis()
		var achse := Vector3.UP.cross(richtung)
		if achse.length_squared() > 0.000001:
			basis = Basis(achse.normalized(), Vector3.UP.angle_to(richtung))
		PropWerkzeug.anfuegen(st, stachel, Transform3D(basis,
				richtung * (radius + laenge * 0.42)))
	var koerper := PropWerkzeug.mesh_knoten("Mine", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(Farben.MOOR_DUNKEL))
	if koerper != null:
		_bild.add_child(koerper)

	# Warnring: der einzige helle Punkt an der Mine.
	var ring := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(ring, PropWerkzeug.stumpf(radius * 1.16,
			radius * 1.16, radius * 0.22, 12, false),
			Transform3D(Basis(), Vector3(0.0, RING_HOEHE, 0.0)))
	var ringknoten := PropWerkzeug.mesh_knoten("Warnring",
			PropWerkzeug.fertig(ring),
			Materialbibliothek.leuchtend(Farben.WARNUNG, 0.9))
	if ringknoten != null:
		_bild.add_child(ringknoten)

	if kette_hoehe > 0.0:
		_kette_bauen()

	_zone = Area3D.new()
	_zone.name = "Zone"
	_zone.collision_layer = 0
	_zone.collision_mask = 2      # nur den Spieler beachten
	var form := SphereShape3D.new()
	form.radius = radius * 1.15
	var kollision := CollisionShape3D.new()
	kollision.shape = form
	_zone.add_child(kollision)
	add_child(_zone)
	_zone.body_entered.connect(_auf_koerper)


## Kette zum Aufhängepunkt, aufgebaut von der Mine aus nach oben. Sie hängt
## nicht im `_bild`, damit sie das Dümpeln und Drehen der Kugel nicht
## mitmacht – gekippt wird sie in `_kette_kippen()`.
func _kette_bauen() -> void:
	var glieder := maxi(int(kette_hoehe / 0.34), 2)
	var st := PropWerkzeug.bauer()
	for i in glieder:
		var y := radius * 0.6 + kette_hoehe * (float(i) + 0.5) / float(glieder)
		var glied := PropWerkzeug.stumpf(0.07, 0.07,
				kette_hoehe / float(glieder) * 0.78, 5, true)
		var quer := Basis(Vector3.UP, PI * 0.5 * float(i % 2))
		PropWerkzeug.anfuegen(st, glied, Transform3D(quer, Vector3(0.0, y, 0.0)))
	_kette = Node3D.new()
	_kette.name = "Kette"
	add_child(_kette)
	var knoten := PropWerkzeug.mesh_knoten("Glieder", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(Farben.ROST))
	if knoten != null:
		_kette.add_child(knoten)


func _auf_koerper(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
		koerper.schaden_nehmen()
