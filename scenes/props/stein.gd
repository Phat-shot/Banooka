extends StaticBody3D
class_name Stein
## Unregelmäßiger Findling. Mehrere verzerrte Kugeln werden zu einem
## Brocken verschmolzen; die Kollision ist die konvexe Hülle davon.
##
## Aufbau (3–4 Knoten):
##   Stein (StaticBody3D, Ebene 1)
##     Kollision (CollisionShape3D)
##     Fels (MeshInstance3D)
##     Moos (MeshInstance3D)   – nur wenn `bemoost`
##
## Der Ursprung liegt am Boden: der Stein steht immer sauber auf y = 0.

## Ungefährer Durchmesser in Metern.
@export_range(0.2, 8.0, 0.05) var groesse: float = 1.0
## Wie viele Teilbrocken verschmolzen werden.
@export_range(1, 6) var brocken: int = 3
## Flacher Findling – gut als Trittstein oder niedriges Hindernis.
@export var flach: bool = false
## Moosbelag auf der Oberseite.
@export var bemoost: bool = true
## Feste Saat: gleicher Wert ⇒ gleicher Stein. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Kollision abschaltbar (reine Deko im Hintergrund).
@export var kollision: bool = true

var _rng: RandomNumberGenerator

var _kollision: CollisionShape3D


func _ready() -> void:
	# Gerüst besorgen – fehlt es (bei `Stein.new()`), wird es angelegt.
	_kollision = PropWerkzeug.kind(self, "Kollision",
			func() -> Node: return CollisionShape3D.new()) as CollisionShape3D
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	collision_layer = 1
	collision_mask = 0
	_baue()


func _baue() -> void:
	var flachheit := 0.45 if flach else 1.0
	var st := PropWerkzeug.bauer()

	for i in brocken:
		# Der erste Brocken ist der Hauptkörper, die weiteren hängen daran
		var haupt := i == 0
		var r := groesse * (0.42 if haupt else _rng.randf_range(0.2, 0.34))
		var versatz := Vector3.ZERO
		if not haupt:
			var winkel := TAU * float(i) / float(brocken) + _rng.randf_range(-0.5, 0.5)
			var weite := groesse * _rng.randf_range(0.15, 0.38)
			versatz = Vector3(cos(winkel) * weite,
					groesse * _rng.randf_range(-0.1, 0.28) * flachheit,
					sin(winkel) * weite)
		# Kantige Kugel mit wenig Segmenten, zusätzlich verzerrt ⇒ Felsoptik
		var skal := Vector3(_rng.randf_range(0.8, 1.4),
				_rng.randf_range(0.6, 1.05) * flachheit, _rng.randf_range(0.8, 1.4))
		var dreh := Vector3(_rng.randf_range(-0.5, 0.5), _rng.randf() * TAU,
				_rng.randf_range(-0.5, 0.5))
		PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(r, 7, 4),
				PropWerkzeug.ort(versatz, dreh, skal))

	var netz := PropWerkzeug.fertig(st)
	if netz == null:
		return

	# Ursprung an den Boden legen: alles so weit anheben, dass die
	# Unterkante genau auf y = 0 liegt.
	var box := netz.get_aabb()
	var anheben := Vector3(0.0, -box.position.y, 0.0)

	var fels := PropWerkzeug.mesh_knoten("Fels", netz, Materialbibliothek.fels())
	fels.position = anheben
	add_child(fels)

	if kollision:
		_kollision.shape = PropWerkzeug.huelle(netz)
		_kollision.position = anheben
	else:
		_kollision.disabled = true

	if bemoost:
		_baue_moos(box, anheben)


## Flacher Moosfleck auf der Oberseite.
func _baue_moos(box: AABB, anheben: Vector3) -> void:
	var st := PropWerkzeug.bauer()
	var flecken := _rng.randi_range(1, 3)
	for i in flecken:
		var r := groesse * _rng.randf_range(0.13, 0.22)
		var winkel := _rng.randf() * TAU
		var weite := box.size.x * _rng.randf_range(0.0, 0.14)
		var pos := Vector3(box.get_center().x + cos(winkel) * weite,
				box.position.y + box.size.y * _rng.randf_range(0.62, 0.8),
				box.get_center().z + sin(winkel) * weite)
		PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(r, 7, 4),
				PropWerkzeug.ort(pos, Vector3(0.0, _rng.randf() * TAU, 0.0),
						Vector3(1.25, 0.32, 1.25)))
	var knoten := PropWerkzeug.mesh_knoten("Moos", PropWerkzeug.fertig(st),
			Materialbibliothek.einfarbig(Farben.MOOS), false)
	if knoten != null:
		knoten.position = anheben
		add_child(knoten)
