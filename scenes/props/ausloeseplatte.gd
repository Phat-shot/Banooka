extends Area3D
class_name Ausloeseplatte
## Bodenplatte, die etwas auslöst, wenn der Spieler sie betritt.
##
## Sie tut selbst nichts. Was passiert, entscheidet das Level: entweder
## über die Signale `ausgeloest` / `zurueckgesetzt`, oder über
## `zielpfade` – dann ruft die Platte bei jedem eingetragenen Knoten
## `ausloesen()` bzw. `zuruecksetzen()`, sofern es die Methode gibt.
## `Rollhindernis` und `Schliesstuer` haben beide genau diese zwei
## Methoden; damit lässt sich eine Falle ohne eine Zeile Verdrahtung bauen.
##
## Sie SCHALTET SICHTBAR: Sie sinkt beim Betreten ein Stück ein und
## leuchtet. Eine Platte, die etwas auslöst, ohne dass man es ihr ansieht,
## ist eine Gemeinheit – der Spieler soll den Zusammenhang zwischen seinem
## Schritt und dem, was gleich passiert, selbst herstellen können.
##
## `nachlauf` hält sie nach dem Verlassen noch eine Weile gedrückt. Ohne
## das flackert alles, was an ihr hängt, sobald man im Laufen darüberspringt.

## Die Platte wurde betreten.
signal ausgeloest
## Die Platte ist wieder frei (bei `einmalig` nie).
signal zurueckgesetzt

## Kantenlängen der Trittfläche in Metern (X mal Z).
@export var flaeche := Vector2(2.4, 2.4)

## Bleibt sie nach dem ersten Tritt für immer gedrückt?
@export var einmalig := false

## Wie lange sie nach dem Verlassen noch als ausgelöst gilt, in Sekunden.
@export var nachlauf := 0.0

## Farbe im Ruhezustand und im ausgelösten Zustand. Die ausgelöste Farbe
## leuchtet – sie ist von weitem der einzige Hinweis, dass hier etwas
## scharf ist.
@export var farbe_aus := Color(0.42, 0.40, 0.36)
@export var farbe_an := Color(0.98, 0.72, 0.22)

## Knoten, deren `ausloesen()` bzw. `zuruecksetzen()` gerufen wird.
@export var zielpfade: Array[NodePath] = []

const RAHMEN := 0.22          ## Breite der festen Fassung ringsum
const PLATTE_DICKE := 0.14
const EINSINK := 0.075        ## so tief geht die Platte beim Tritt
const SINK_TEMPO := 0.9       ## Meter je Sekunde, mit denen sie sinkt/steigt
const ZONE_HOEHE := 1.4       ## Fühlhöhe – muss die Spielerkapsel treffen

var _platte: MeshInstance3D
var _mat_aus: Material
var _mat_an: Material
var _seit_frei := 999.0       ## Sekunden seit dem Verlassen
var _an := false
var _tiefe := 0.0             ## aktuelle Einsinktiefe in Metern


func _ready() -> void:
	add_to_group("ausloeseplatten")
	collision_layer = 0
	collision_mask = 2        # nur den Spieler beachten
	monitoring = true
	_aufbauen()


func _physics_process(delta: float) -> void:
	var drauf := _jemand_drauf()
	if drauf:
		_seit_frei = 0.0
	else:
		_seit_frei += delta

	var soll := drauf or _seit_frei < nachlauf or (einmalig and _an)
	if soll != _an:
		_an = soll
		_leuchten_setzen()
		if _an:
			ausgeloest.emit()
			_ziele_rufen("ausloesen")
		else:
			zurueckgesetzt.emit()
			_ziele_rufen("zuruecksetzen")

	# Weich statt sofort: Eine Platte, die im selben Bild unten ist, liest
	# sich wie ein Fehler in der Anzeige, nicht wie ein Mechanismus.
	var ziel := EINSINK if _an else 0.0
	if is_instance_valid(_platte) and not is_equal_approx(_tiefe, ziel):
		_tiefe = move_toward(_tiefe, ziel, delta * SINK_TEMPO)
		_platte.position.y = PLATTE_DICKE * 0.5 - _tiefe


func _leuchten_setzen() -> void:
	if is_instance_valid(_platte):
		_platte.material_override = _mat_an if _an else _mat_aus


## Ist die Platte gerade gedrückt?
func ist_an() -> bool:
	return _an


## Löst die Verriegelung einer `einmalig`-Platte wieder. Für Level, die
## eine Falle nach dem Tod des Spielers neu scharf machen wollen.
func entriegeln() -> void:
	_seit_frei = 999.0
	if _an and not _jemand_drauf():
		_an = false
		zurueckgesetzt.emit()
		_ziele_rufen("zuruecksetzen")


func _jemand_drauf() -> bool:
	for koerper in get_overlapping_bodies():
		if koerper.is_in_group("spieler"):
			return true
	return false


func _ziele_rufen(methode: String) -> void:
	for pfad in zielpfade:
		var ziel := get_node_or_null(pfad)
		if ziel != null and ziel.has_method(methode):
			ziel.call(methode)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	# Feste Fassung ringsum. Sie sinkt nicht mit und gibt dem Auge den
	# Bezugspunkt, an dem die Bewegung der Platte überhaupt auffällt.
	var st := PropWerkzeug.bauer()
	var aussen := flaeche + Vector2.ONE * RAHMEN * 2.0
	for seite in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var laengs := absf(seite.x) > 0.0
		var balken := PropWerkzeug.kasten(Vector3(
				RAHMEN if laengs else aussen.x,
				PLATTE_DICKE * 1.15,
				aussen.y if laengs else RAHMEN))
		PropWerkzeug.anfuegen(st, balken, Transform3D(Basis(), Vector3(
				seite.x * (flaeche.x + RAHMEN) * 0.5,
				PLATTE_DICKE * 0.5,
				seite.y * (flaeche.y + RAHMEN) * 0.5)))
	var rahmen := PropWerkzeug.mesh_knoten("Rahmen", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(farbe_aus.darkened(0.4)))
	if rahmen != null:
		add_child(rahmen)

	# Trittfläche mit aufgesetzter Raute. Die Raute ist kein Schmuck: Sie
	# unterscheidet die Platte auf einen Blick von einer bloßen Fliese.
	var pst := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(pst, PropWerkzeug.kasten(
			Vector3(flaeche.x, PLATTE_DICKE, flaeche.y)), Transform3D())
	PropWerkzeug.anfuegen(pst, PropWerkzeug.kasten(Vector3(
			flaeche.x * 0.5, PLATTE_DICKE * 1.3, flaeche.y * 0.5)),
			Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO))
	_mat_aus = Materialbibliothek.einfarbig(farbe_aus, 0.75, 0.2)
	_mat_an = Materialbibliothek.leuchtend(farbe_an, 1.1)
	_platte = PropWerkzeug.mesh_knoten("Platte", PropWerkzeug.fertig(pst),
			_mat_aus)
	if _platte != null:
		_platte.position.y = PLATTE_DICKE * 0.5
		add_child(_platte)
	_leuchten_setzen()

	var form := BoxShape3D.new()
	form.size = Vector3(flaeche.x, ZONE_HOEHE, flaeche.y)
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	kollision.position = Vector3(0.0, ZONE_HOEHE * 0.5, 0.0)
	add_child(kollision)
