extends StaticBody3D
class_name Wurzel
## Begehbarer Wurzelbogen. Wächst aus dem Boden, spannt sich über eine
## Strecke und taucht wieder ein – im Level als kleines Hindernis, als
## Rampe oder als Brücke über eine Lücke einsetzbar.
##
## Aufbau (2 + `segmente` Knoten):
##   Wurzel (StaticBody3D, Ebene 1)
##     Holz (MeshInstance3D)        – Bogen + Nebenwurzeln als ein Mesh
##     Kollision0..n (CollisionShape3D) – flache Boxen entlang des Bogens
##
## Die Kollision besteht bewusst aus Boxen und nicht aus Zylindern: darauf
## läuft es sich sauber, ohne dass der Spieler seitlich abrutscht.

## Weite des Bogens in Metern (von Fuß zu Fuß).
@export_range(1.0, 14.0, 0.1) var spannweite: float = 4.0
## Höhe der begehbaren Oberfläche am Scheitel (nicht der Mittellinie) –
## damit kann man im Level direkt rechnen: `hoehe = 1.2` heißt, oben auf
## der Wurzel steht man auf 1,2 m.
@export_range(0.2, 5.0, 0.05) var hoehe: float = 1.2
## Durchmesser des Wurzelholzes.
@export_range(0.15, 1.2, 0.01) var dicke: float = 0.55
## Anzahl der Bogenabschnitte. Mehr = runder, aber mehr Kollisionsknoten.
@export_range(3, 16) var segmente: int = 8
## Feste Saat: gleicher Wert ⇒ gleiche Wurzel. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Kleine Nebenwurzeln am Boden.
@export var nebenwurzeln: bool = true
## Kollision abschaltbar (reine Deko im Hintergrund).
@export var kollision: bool = true

## Wie tief die Bogenenden im Boden verschwinden.
const EINTAUCHEN := 0.35

var _rng: RandomNumberGenerator


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	collision_layer = 1
	collision_mask = 0
	_baue()


func _baue() -> void:
	var punkte := _bogenpunkte()
	var st := PropWerkzeug.bauer()

	for i in punkte.size() - 1:
		var von: Vector3 = punkte[i]
		var bis: Vector3 = punkte[i + 1]
		var r0 := _radius(float(i) / float(segmente))
		var r1 := _radius(float(i + 1) / float(segmente))
		var laenge := von.distance_to(bis)
		if laenge < 0.005:
			continue

		# Optik: runde Wurzel, leicht breiter als hoch
		var form := PropWerkzeug.stumpf(r0, r1, laenge * 1.12, 7, false)
		PropWerkzeug.anfuegen(st, form, PropWerkzeug.ausrichten(von, bis))

		if kollision:
			_kollisionsbox(von, bis, maxf(r0, r1))

	if nebenwurzeln:
		_baue_nebenwurzeln(st, punkte)

	var knoten := PropWerkzeug.mesh_knoten("Holz", PropWerkzeug.fertig(st),
			Materialbibliothek.wurzel())
	if knoten != null:
		add_child(knoten)


## Punkte entlang eines Sinusbogens von -X nach +X, mit leichtem Z-Schlenker.
func _bogenpunkte() -> PackedVector3Array:
	var punkte := PackedVector3Array()
	var halb := spannweite * 0.5
	var schlenker := spannweite * _rng.randf_range(0.03, 0.1)
	var versatz := _rng.randf() * TAU
	# Die Mittellinie liegt um den Scheitelradius tiefer, damit die
	# OBERSEITE des Bogens genau auf `hoehe` endet.
	var scheitel := maxf(hoehe - _radius(0.5), 0.05)
	for i in segmente + 1:
		var t := float(i) / float(segmente)
		var bogen := sin(t * PI)
		punkte.append(Vector3(
			lerpf(-halb, halb, t),
			bogen * scheitel - EINTAUCHEN * (1.0 - bogen),
			sin(t * TAU + versatz) * schlenker))
	return punkte


## Wurzeln sind an den Füßen dicker als am Scheitel.
func _radius(t: float) -> float:
	return dicke * 0.5 * lerpf(1.3, 0.92, sin(t * PI))


## Flache Box entlang eines Abschnitts – das ist die begehbare Oberfläche.
func _kollisionsbox(von: Vector3, bis: Vector3, radius: float) -> void:
	var laenge := von.distance_to(bis)
	var form := BoxShape3D.new()
	form.size = Vector3(radius * 2.0, radius * 2.0, laenge * 1.02)
	var kf := CollisionShape3D.new()
	kf.name = "Kollision%d" % get_child_count()
	kf.shape = form
	kf.transform = PropWerkzeug.ausrichten_z(von, bis)
	add_child(kf)


## Kurze Seitenwurzeln, die vom Bogen in den Boden laufen.
func _baue_nebenwurzeln(st: SurfaceTool, punkte: PackedVector3Array) -> void:
	var anzahl := _rng.randi_range(2, 4)
	for i in anzahl:
		var idx := _rng.randi_range(1, punkte.size() - 2)
		var start: Vector3 = punkte[idx]
		var winkel := _rng.randf() * TAU
		var weite := dicke * _rng.randf_range(1.6, 3.4)
		var ende := start + Vector3(cos(winkel) * weite,
				-start.y - EINTAUCHEN * 0.6, sin(winkel) * weite)
		var r := _radius(float(idx) / float(segmente)) * 0.55
		var laenge := start.distance_to(ende)
		if laenge < 0.05:
			continue
		var form := PropWerkzeug.stumpf(r, r * 0.35, laenge * 1.05, 5, false)
		PropWerkzeug.anfuegen(st, form, PropWerkzeug.ausrichten(start, ende))
