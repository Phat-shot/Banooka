extends Node3D
class_name Baum
## Prozeduraler Waldbaum in drei Ausführungen: Laubbaum, Nadelbaum, Totholz.
##
## Aufbau (6 Knoten):
##   Baum (Node3D)
##     Stamm (StaticBody3D, Ebene 1)  – nur Kollision, kein Mesh
##       Kollision (CollisionShape3D) – Zylinder um den Stammfuß
##     Holz (MeshInstance3D)          – Stamm + Äste, zu einem Mesh verschmolzen
##     Krone (Node3D)                 – schwankt im Wind
##       Blattwerk (MeshInstance3D)   – alle Blattballen als ein Mesh
##
## Der Stamm besteht aus mehreren gestapelten, versetzten Kegelstümpfen und
## ist dadurch leicht gebogen und nach oben verjüngt. Die Krone ist NICHT
## kollidierbar – man kann durch die Blätter hindurchspringen.

enum Art {
	LAUBBAUM,   ## runde Blattballen
	NADELBAUM,  ## gestapelte Kegel
	TOTHOLZ,    ## kahler, abgebrochener Stamm
}

## Standard-Laubfarben (entsprechen Farben.LAUB / LAUB_DUNKEL / LAUB_HELL).
const LAUBTOENE: Array[Color] = [
	Color(0.20, 0.44, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.35, 0.60, 0.22),
]

@export var art: Art = Art.LAUBBAUM
## Gesamthöhe in Metern (4–12 m sind die üblichen Werte).
@export_range(3.0, 14.0, 0.1) var hoehe: float = 7.0
## Feste Saat: gleicher Wert ⇒ gleicher Baum. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Dicke des Stammes relativ zur Höhe.
@export_range(0.4, 2.5, 0.05) var staerke: float = 1.0
## Farbe des Blattwerks (bei Totholz ohne Wirkung).
@export var laubfarbe: Color = Color(0.20, 0.44, 0.16)
## Sanftes Schwanken der Krone.
@export var wind: bool = true
## Stamm blockiert den Spieler. Für reine Hintergrund-Deko abschaltbar.
@export var kollision: bool = true

var _rng: RandomNumberGenerator
var _phase := 0.0
var _zeit := 0.0
var _wind_x := 0.0
var _wind_z := 0.0

var _stamm: StaticBody3D
var _kollision: CollisionShape3D
var _krone: Node3D


func _ready() -> void:
	_hole_knoten()
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	_phase = _rng.randf() * TAU
	hoehe = clampf(hoehe, 3.0, 14.0)

	match art:
		Art.NADELBAUM:
			_baue_nadelbaum()
		Art.TOTHOLZ:
			_baue_totholz()
		_:
			_baue_laubbaum()

	# Windstärke je Baum leicht unterschiedlich – so schwanken nicht alle gleich.
	_wind_x = deg_to_rad(_rng.randf_range(1.0, 2.2))
	_wind_z = deg_to_rad(_rng.randf_range(0.8, 1.8))
	set_process(wind and _krone.get_child_count() > 0)


## Gerüst besorgen. Fehlt es (weil der Baum per `Baum.new()` entstanden ist),
## wird es hier angelegt.
func _hole_knoten() -> void:
	_stamm = PropWerkzeug.kind(self, "Stamm",
			func() -> Node: return StaticBody3D.new()) as StaticBody3D
	_stamm.collision_layer = 1
	_stamm.collision_mask = 0
	_kollision = PropWerkzeug.kind(_stamm, "Kollision",
			func() -> Node: return CollisionShape3D.new()) as CollisionShape3D
	_krone = PropWerkzeug.kind(self, "Krone",
			func() -> Node: return Node3D.new()) as Node3D


# ---------------------------------------------------------------- Bauarten

func _baue_laubbaum() -> void:
	var stamm_hoehe := hoehe * 0.55
	var r_unten := _stammradius()
	var r_oben := r_unten * 0.42

	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten)
	var punkte := _stamm_segmente(st, stamm_hoehe, r_unten, r_oben,
			maxi(int(hoehe * 0.8), 4), 0.14)
	_aeste(st, punkte, _rng.randi_range(3, 5), hoehe * 0.24, r_oben * 0.75)
	_setze_holz(st, Materialbibliothek.rinde())

	# Krone sitzt über dem letzten Stammpunkt und folgt damit der Biegung
	var spitze: Vector3 = punkte[punkte.size() - 1]
	var kronen_radius := hoehe * 0.25
	_baue_blattballen(spitze + Vector3(0.0, kronen_radius * 0.5, 0.0),
			kronen_radius, _rng.randi_range(5, 7))
	_setze_kollision(r_unten * 1.15, hoehe * 0.6)


func _baue_nadelbaum() -> void:
	var r_unten := _stammradius() * 0.85
	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten)
	_stamm_segmente(st, hoehe * 0.8, r_unten, r_unten * 0.2,
			maxi(int(hoehe * 0.6), 4), 0.05)
	_setze_holz(st, Materialbibliothek.rinde())

	# Kegelkranz von unten nach oben, jeder Kegel etwas kleiner
	var start := hoehe * 0.22
	var oben := hoehe * 0.8
	var mitte := (start + oben) * 0.5
	var stufen := clampi(int(hoehe * 0.55), 4, 7)
	var kst := PropWerkzeug.bauer()
	for i in stufen:
		var t := float(i) / float(stufen - 1)
		var y := lerpf(start, oben, t)
		var radius := lerpf(hoehe * 0.22, hoehe * 0.045, t) * _rng.randf_range(0.9, 1.1)
		var kegel_hoehe := (oben - start) / float(stufen) * _rng.randf_range(2.4, 2.9)
		var kegel := PropWerkzeug.stumpf(radius, radius * 0.12, kegel_hoehe, 9, false)
		var neigung := Vector3(_rng.randf_range(-0.05, 0.05), _rng.randf() * TAU,
				_rng.randf_range(-0.05, 0.05))
		PropWerkzeug.anfuegen(kst, kegel,
				PropWerkzeug.ort(Vector3(0.0, y - mitte + kegel_hoehe * 0.3, 0.0), neigung))
	_setze_krone(kst, Vector3(0.0, mitte, 0.0))
	_setze_kollision(r_unten * 1.2, hoehe * 0.8)


func _baue_totholz() -> void:
	var stamm_hoehe := hoehe * 0.7
	var r_unten := _stammradius() * 1.4
	var r_oben := r_unten * 0.62

	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten)
	var punkte := _stamm_segmente(st, stamm_hoehe, r_unten, r_oben,
			maxi(int(hoehe * 0.7), 4), 0.2)
	_aeste(st, punkte, _rng.randi_range(3, 5), hoehe * 0.22, r_oben * 0.75)

	# Abgebrochene, splittrige Spitze
	var spitze: Vector3 = punkte[punkte.size() - 1]
	var splitter := PropWerkzeug.stumpf(r_oben, 0.0, r_oben * 3.0, 6, false)
	PropWerkzeug.anfuegen(st, splitter, PropWerkzeug.ort(
			spitze + Vector3(0.0, r_oben * 1.4, 0.0),
			Vector3(_rng.randf_range(-0.25, 0.25), 0.0, _rng.randf_range(-0.25, 0.25))))
	_setze_holz(st, Materialbibliothek.wurzel())
	_setze_kollision(r_unten * 1.1, stamm_hoehe)


# ---------------------------------------------------------------- Bausteine

func _stammradius() -> float:
	return 0.135 * staerke * (hoehe / 7.0) + 0.05


## Gestapelte Kegelstümpfe. Gibt die Segmentgrenzen zurück (für Äste/Krone).
func _stamm_segmente(st: SurfaceTool, stamm_hoehe: float, r_unten: float,
		r_oben: float, segmente: int, biegung: float) -> PackedVector3Array:
	var punkte := PackedVector3Array()
	var richtung := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
	if richtung.length() < 0.01:
		richtung = Vector2.RIGHT
	richtung = richtung.normalized() * biegung

	var pos := Vector3.ZERO
	punkte.append(pos)
	for i in segmente:
		var t0 := float(i) / float(segmente)
		var t1 := float(i + 1) / float(segmente)
		# quadratischer Verlauf ⇒ unten gerade, oben stärker geneigt
		var naechster := Vector3(
			richtung.x * t1 * t1 * stamm_hoehe + _rng.randf_range(-0.03, 0.03) * stamm_hoehe,
			stamm_hoehe * t1,
			richtung.y * t1 * t1 * stamm_hoehe + _rng.randf_range(-0.03, 0.03) * stamm_hoehe)
		_ast_segment(st, pos, naechster,
				lerpf(r_unten, r_oben, t0), lerpf(r_unten, r_oben, t1), 8)
		pos = naechster
		punkte.append(pos)
	return punkte


## Verdickter Fuß, damit der Stamm nicht wie ein Rohr im Boden steckt.
func _wurzelanlauf(st: SurfaceTool, r_unten: float) -> void:
	var fuss := PropWerkzeug.stumpf(r_unten * 1.85, r_unten * 1.02, r_unten * 2.4, 8, false)
	PropWerkzeug.anfuegen(st, fuss, PropWerkzeug.ort(Vector3(0.0, r_unten * 0.9, 0.0)))


## Ein Stamm-/Astabschnitt als Kegelstumpf zwischen zwei Punkten.
func _ast_segment(st: SurfaceTool, von: Vector3, bis: Vector3,
		r0: float, r1: float, seiten: int) -> void:
	var laenge := von.distance_to(bis)
	if laenge < 0.005:
		return
	# 6 % Überlappung, damit an den Knicken keine Lücken aufreißen
	var form := PropWerkzeug.stumpf(r0, r1, laenge * 1.06, seiten, false)
	PropWerkzeug.anfuegen(st, form, PropWerkzeug.ausrichten(von, bis))


## Setzt Äste an die obere Stammhälfte.
func _aeste(st: SurfaceTool, punkte: PackedVector3Array, anzahl: int,
		laenge: float, radius: float) -> void:
	if punkte.size() < 3:
		return
	for i in anzahl:
		var idx := _rng.randi_range(maxi(int(punkte.size() * 0.45), 1), punkte.size() - 1)
		var start: Vector3 = punkte[idx]
		var winkel := TAU * float(i) / float(anzahl) + _rng.randf_range(-0.5, 0.5)
		var steigung := _rng.randf_range(0.4, 1.0)
		var richtung := Vector3(cos(winkel), steigung, sin(winkel)).normalized()
		var l := laenge * _rng.randf_range(0.7, 1.3)
		var mitte := start + richtung * l * 0.55
		# leichter Knick nach oben – Äste sind selten kerzengerade
		var ende := mitte + (richtung + Vector3.UP * 0.35).normalized() * l * 0.45
		_ast_segment(st, start, mitte, radius, radius * 0.65, 6)
		_ast_segment(st, mitte, ende, radius * 0.65, radius * 0.25, 5)


## Überlappende, unregelmäßig verzerrte Kugeln als Laubkrone.
func _baue_blattballen(mitte: Vector3, radius: float, ballen: int) -> void:
	var st := PropWerkzeug.bauer()
	for i in ballen:
		var winkel := TAU * float(i) / float(ballen) + _rng.randf_range(-0.4, 0.4)
		var weite := radius * _rng.randf_range(0.25, 0.7) if i > 0 else 0.0
		var versatz := Vector3(cos(winkel) * weite,
				radius * _rng.randf_range(-0.55, 0.6), sin(winkel) * weite)
		var r := radius * _rng.randf_range(0.5, 0.85)
		var skal := Vector3(_rng.randf_range(0.85, 1.25),
				_rng.randf_range(0.8, 1.25), _rng.randf_range(0.85, 1.25))
		var dreh := Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf() * TAU,
				_rng.randf_range(-0.4, 0.4))
		PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(r, 8, 5),
				PropWerkzeug.ort(versatz, dreh, skal))
	_setze_krone(st, mitte)


func _setze_holz(st: SurfaceTool, material: Material) -> void:
	var knoten := PropWerkzeug.mesh_knoten("Holz", PropWerkzeug.fertig(st), material)
	if knoten != null:
		add_child(knoten)


func _setze_krone(st: SurfaceTool, mitte: Vector3) -> void:
	var knoten := PropWerkzeug.mesh_knoten("Blattwerk", PropWerkzeug.fertig(st),
			Materialbibliothek.laub(laubfarbe))
	if knoten == null:
		return
	_krone.position = mitte
	_krone.add_child(knoten)


func _setze_kollision(radius: float, kollisionshoehe: float) -> void:
	if not kollision:
		# Ohne Kollision fliegt der ganze Koerper raus – spart zwei Knoten.
		_stamm.queue_free()
		return
	var form := CylinderShape3D.new()
	form.radius = maxf(radius, 0.22)
	form.height = maxf(kollisionshoehe, 0.5)
	_kollision.shape = form
	_kollision.position = Vector3(0.0, form.height * 0.5, 0.0)


# ---------------------------------------------------------------- Wind

## Nur EIN Knoten je Baum wird bewegt – die Krone. Das bleibt auch bei
## einem ganzen Wald bezahlbar.
func _process(delta: float) -> void:
	_zeit += delta
	_krone.rotation.x = _wind_x * sin(_zeit * 0.9 + _phase)
	_krone.rotation.z = _wind_z * sin(_zeit * 1.43 + _phase * 1.7)
