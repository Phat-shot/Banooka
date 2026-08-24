extends StaticBody3D
class_name Stein
## Kantiger Findling. Mehrere verzerrte, gegeneinander verdrehte Blöcke
## werden zu einem Brocken verschmolzen; die Kollision ist die konvexe
## Hülle davon.
##
## Aufbau (3–4 Knoten – unverändert):
##   Stein (StaticBody3D, Ebene 1)
##     Kollision (CollisionShape3D)
##     Fels (MeshInstance3D)
##     Moos (MeshInstance3D)   – nur wenn `bemoost`
##
## Der Fels entsteht über `PropWerkzeug.klumpen(..., kantig = true)`:
## wenige Segmente, kräftig verschobene Ecken und FLÄCHENnormalen. Dadurch
## bricht das Licht an klaren Kanten – der Stein wirkt gebrochen statt
## kugelig. Die Farbe kommt vollständig aus `Materialbibliothek.fels()`;
## Scheitelfarben dunkeln lediglich den Fuß ab, damit der Brocken im Boden
## sitzt statt aufzuliegen.
##
## Der Ursprung liegt am Boden, der Stein wird zusätzlich ein Stück
## eingegraben.

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
## Wie stark die Ecken verschoben werden (0 = glatt, 0.45 = zerklüftet).
@export_range(0.0, 0.5, 0.01) var zerklueftung: float = 0.36
## Anteil der Höhe, um den der Stein im Boden versinkt.
@export_range(0.0, 0.4, 0.01) var eingegraben: float = 0.09

## Abdunklung am Fuß bzw. volle Materialfarbe oben (Scheitelfarben,
## multiplikativ – sie können nur abdunkeln).
const FUSS_DUNKEL := Color(0.78, 0.77, 0.74)
const KOPF_HELL := Color(1.0, 1.0, 1.0)

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
	if not _setze_fertiges_modell():
		_baue()


## Setzt einen mitgelieferten Felsen und meldet, ob es geklappt hat.
## Die Kollision bleibt eine grobe Kugel – ein Netz je Stein wäre für die
## Menge, die in einem Level steht, zu teuer.
func _setze_fertiges_modell() -> bool:
	if not NaturAssets.aktiv():
		return false
	var auswahl := ["rock_smallFlatA", "rock_smallFlatB"] if flach \
			else (["rock_largeA", "rock_largeB", "rock_largeC"] if groesse >= 1.2
			else ["rock_smallA", "rock_smallB", "rock_smallC"])
	var hoehe := groesse * (0.45 if flach else 0.9)
	var modell := NaturAssets.waehle(auswahl, _rng, hoehe)
	if modell == null:
		return false
	modell.name = "Modell"
	modell.rotation.y = _rng.randf() * TAU
	modell.position.y = -hoehe * eingegraben
	add_child(modell)
	if kollision:
		var form := SphereShape3D.new()
		form.radius = maxf(groesse * 0.45, 0.2)
		_kollision.shape = form
		_kollision.position = Vector3(0.0, form.radius * 0.7, 0.0)
	else:
		_kollision.queue_free()
	return true


func _baue() -> void:
	var flachheit := 0.45 if flach else 1.0
	var teile := _bloecke(flachheit)
	if teile.is_empty():
		return

	# Farbverlauf über den GESAMTEN Brocken, nicht je Block
	var von := INF
	var bis := -INF
	for t in teile:
		von = minf(von, t["pos"].y - t["radien"].y)
		bis = maxf(bis, t["pos"].y + t["radien"].y)

	var st := PropWerkzeug.bauer()
	for t in teile:
		PropWerkzeug.klumpen(st, _rng, t["pos"], t["radien"], t["dreh"],
				t["seiten"], t["ringe"], t["unruhe"], true,
				FUSS_DUNKEL, KOPF_HELL, von, bis - (bis - von) * 0.6)

	var netz := PropWerkzeug.fertig_mit_tangenten(st)
	if netz == null:
		return

	# Ursprung an den Boden legen und den Stein etwas eingraben
	var box := netz.get_aabb()
	var anheben := Vector3(0.0, -box.position.y - box.size.y * eingegraben, 0.0)

	var fels := PropWerkzeug.mesh_knoten("Fels", netz,
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.fels()))
	fels.position = anheben
	add_child(fels)

	if kollision:
		_kollision.shape = PropWerkzeug.huelle(netz)
		_kollision.position = anheben
	else:
		_kollision.disabled = true

	if bemoost:
		_baue_moos(netz, box, anheben)


## Legt Lage, Halbachsen, Drehung und Auflösung der Teilblöcke fest.
## Wenige Segmente + kräftige Unruhe ⇒ eckige, plattige Formen.
func _bloecke(flachheit: float) -> Array:
	var teile: Array = []
	var versatz := _rng.randf() * TAU
	for i in brocken:
		# Der erste Block ist der Hauptkörper, die weiteren lehnen daran
		var haupt := i == 0
		var r := groesse * (0.46 if haupt else _rng.randf_range(0.2, 0.34))
		var pos := Vector3.ZERO
		if not haupt:
			var winkel := versatz + TAU * float(i) / float(brocken) \
					+ _rng.randf_range(-0.5, 0.5)
			var weite := groesse * _rng.randf_range(0.16, 0.4)
			pos = Vector3(cos(winkel) * weite,
					groesse * _rng.randf_range(-0.12, 0.26) * flachheit,
					sin(winkel) * weite)
		# stark ungleiche Halbachsen ⇒ Platten und Keile statt Kugeln
		var radien := Vector3(r * _rng.randf_range(0.8, 1.35),
				r * _rng.randf_range(0.85, 1.3) * flachheit,
				r * _rng.randf_range(0.8, 1.35))
		var dreh := Vector3(_rng.randf_range(-0.55, 0.55), _rng.randf() * TAU,
				_rng.randf_range(-0.55, 0.55))
		teile.append({
			"pos": pos, "radien": radien, "dreh": dreh,
			"seiten": _rng.randi_range(6, 8),
			"ringe": _rng.randi_range(3, 5),
			"unruhe": zerklueftung * _rng.randf_range(0.75, 1.25),
		})
	return teile


## Moos wächst nur dort, wo Regen hinkommt. Statt lose Polster auf den Stein
## zu setzen (die seitlich als Scheiben herausstachen), werden hier die
## OBEN LIEGENDEN Dreiecke des Felses selbst um eine Haaresbreite nach außen
## versetzt kopiert. Das Polster liegt dadurch exakt auf der Oberfläche und
## kann die Silhouette nicht durchstoßen.
##
## Sparsam bleibt es durch die Auswahl: nur ein bis zwei Flecken rund um
## zufällige Saatpunkte im oberen Drittel, und nur Flächen, die nach oben
## schauen.
func _baue_moos(netz: ArrayMesh, box: AABB, anheben: Vector3) -> void:
	var felder := netz.surface_get_arrays(0)
	var ecken: PackedVector3Array = felder[Mesh.ARRAY_VERTEX]
	var normalen: PackedVector3Array = felder[Mesh.ARRAY_NORMAL]
	if ecken.is_empty():
		return
	# Ohne Indexpuffer (nicht verschweißtes Mesh) laufen die Ecken der Reihe nach
	var kanten := PackedInt32Array()
	if felder[Mesh.ARRAY_INDEX] is PackedInt32Array:
		kanten = felder[Mesh.ARRAY_INDEX]
	if kanten.is_empty():
		kanten.resize(ecken.size())
		for i in ecken.size():
			kanten[i] = i

	# ein bis zwei Saatpunkte im oberen Bereich – dort wächst der Fleck
	var quer := maxf(box.size.x, box.size.z)
	var saaten: Array[Vector3] = []
	var reichweite := quer * _rng.randf_range(0.16, 0.26)
	for i in (2 if quer > 1.4 else 1):
		var w := _rng.randf() * TAU
		var d := quer * _rng.randf_range(0.0, 0.22)
		saaten.append(Vector3(box.get_center().x + cos(w) * d,
				box.position.y + box.size.y * 0.95,
				box.get_center().z + sin(w) * d))

	var dicke := maxf(box.size.y, 0.05) * 0.02
	var untergrenze := box.position.y + box.size.y * 0.6
	var st := PropWerkzeug.bauer()
	for i in range(0, kanten.size() - 2, 3):
		var a: Vector3 = ecken[kanten[i]]
		var b: Vector3 = ecken[kanten[i + 1]]
		var c: Vector3 = ecken[kanten[i + 2]]
		var n: Vector3 = normalen[kanten[i]]
		if n.y < 0.58:
			continue
		var mitte := (a + b + c) / 3.0
		if mitte.y < untergrenze:
			continue
		var nah := false
		for saat_punkt in saaten:
			if Vector2(mitte.x - saat_punkt.x, mitte.z - saat_punkt.z).length() < reichweite:
				nah = true
				break
		if not nah:
			continue
		var ab := n * dicke
		# Reihenfolge unverändert übernehmen – die Vorderseite stimmt dann auch
		PropWerkzeug.flaeche(st, a + ab, b + ab, c + ab, n)

	var knoten := PropWerkzeug.mesh_knoten("Moos",
			PropWerkzeug.fertig_mit_tangenten(st),
			Materialbibliothek.laub(Farben.MOOS), false)
	if knoten != null:
		knoten.position = anheben
		add_child(knoten)
