extends Node3D
class_name Flugschuss
## Geschoss des Flugmodus – für den Doppeldecker des Spielers wie für die
## Bomber, die zurückschießen.
##
## Bewusst KEIN Physikkörper und keine `Area3D`: Bei 40 m/s legt ein Schuss
## je Bild rund 0,67 m zurück. Eine Area meldet Überlappungen erst im
## nächsten Physikschritt und prüft nur die Endlage – ein Jäger von 1,2 m
## Durchmesser fiele damit regelmäßig durchs Raster, und der Spieler hätte
## den Eindruck, mitten hindurchgeschossen zu haben. Stattdessen wird die
## STRECKE zwischen alter und neuer Lage gegen die Ziele geprüft; damit
## kann kein Treffer zwischen zwei Bildern verlorengehen.
##
## Erzeugt wird ein Schuss immer über `Flugschuss.abfeuern()`, nicht über
## die Szene: Ein `preload` der eigenen .tscn im eigenen Skript wäre ein
## Ringverweis. Die Szene gibt es nur, damit sich das Geschoss im Editor
## ansehen und einstellen lässt.

## Fluggeschwindigkeit in m/s.
@export var tempo := 40.0
## Nach dieser Zeit verschwindet der Schuss. 2 s mal 40 m/s sind 80 m –
## mehr als die Diagonale des Luftraums, ein Schuss stirbt also nie vor
## der Wand, aber auch nie später.
@export var lebensdauer := 2.0
## Trefferradius des Geschosses selbst.
@export var radius := 0.16
## Leuchtfarbe.
@export var farbe: Color = Farben.SPIN_RING

## Flugrichtung (normiert).
var richtung := Vector3.FORWARD
## Wer geschossen hat – den trifft der eigene Schuss nie.
var quelle: Node3D

## Länge des Leuchtstrichs, als Bruchteil der Strecke einer Sekunde.
## Ein Punkt wäre bei diesem Tempo unsichtbar; 0,05 s ergeben bei 40 m/s
## einen 2 m langen Strich – lang genug, um die Schussbahn zu lesen.
const STRICH_ZEIT := 0.05

var _rest := 0.0


## Erzeugt einen Schuss und hängt ihn ins Level (NICHT an den Schützen –
## sonst führe er mit ihm mit).
static func abfeuern(elternteil: Node, ort: Vector3, dir: Vector3,
		von: Node3D, ton: Color, schuss_tempo: float = 40.0) -> Flugschuss:
	if elternteil == null or dir.length_squared() < 0.000001:
		return null
	var schuss := Flugschuss.new()
	schuss.richtung = dir.normalized()
	schuss.quelle = von
	schuss.farbe = ton
	schuss.tempo = schuss_tempo
	elternteil.add_child(schuss)
	# Erst nach dem Einhängen ausrichten: vorher gibt es keine globale Lage.
	# `looking_at` bricht ab, wenn Blick und Hilfsachse parallel sind – bei
	# einem Rückschuss senkrecht nach oben wäre das genau der Fall.
	var oben := Vector3.UP
	if absf(schuss.richtung.dot(oben)) > 0.99:
		oben = Vector3.FORWARD
	schuss.global_transform = Transform3D(
			Basis.looking_at(schuss.richtung, oben), ort)
	return schuss


func _ready() -> void:
	_rest = lebensdauer
	add_to_group("flugschuesse")
	var laenge := maxf(tempo * STRICH_ZEIT, radius * 3.0)
	# Der Zylinder steht auf Y; um 90° gekippt liegt er auf der Blickachse.
	var strich := PropWerkzeug.mesh_knoten("Strich",
			PropWerkzeug.stumpf(radius, radius, laenge, 6),
			Materialbibliothek.leuchtend(farbe, 3.0), false)
	if strich != null:
		strich.rotation.x = PI * 0.5
		add_child(strich)


func _physics_process(delta: float) -> void:
	_rest -= delta
	if _rest <= 0.0:
		queue_free()
		return
	var von := global_position
	var bis := von + richtung * tempo * delta
	if _pruefe_treffer(von, bis):
		return
	global_position = bis


## Prüft die geflogene Strecke gegen alle Ziele. Gibt true zurück, wenn der
## Schuss verbraucht ist.
func _pruefe_treffer(von: Vector3, bis: Vector3) -> bool:
	for ziel in get_tree().get_nodes_in_group("flugziele"):
		var knoten := ziel as Node3D
		if knoten == null or knoten == quelle or not knoten.has_method("treffer_nehmen"):
			continue
		var weite: float = radius + float(knoten.call("trefferradius"))
		if _abstand_zu_strecke(knoten.global_position, von, bis) <= weite:
			knoten.call("treffer_nehmen", 1, richtung)
			queue_free()
			return true

	# Rückschüsse der Bomber treffen den Flieger.
	var spieler := get_tree().get_first_node_in_group("spieler") as Spieler
	if spieler != null and spieler != quelle:
		if _abstand_zu_strecke(spieler.global_position, von, bis) <= radius + 1.0:
			spieler.schaden_nehmen()
			queue_free()
			return true
	return false


## Kürzester Abstand eines Punktes zu einer Strecke.
static func _abstand_zu_strecke(punkt: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var laenge2 := ab.length_squared()
	if laenge2 < 0.000001:
		return punkt.distance_to(a)
	var t := clampf((punkt - a).dot(ab) / laenge2, 0.0, 1.0)
	return punkt.distance_to(a + ab * t)
