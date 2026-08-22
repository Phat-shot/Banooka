extends Node3D
class_name Kleinzeug
## Kleine Bodendeko: Farn, Pilz, Busch oder Blume – Art über `art`.
##
## Aufbau (3–4 Knoten):
##   Kleinzeug (Node3D)
##     Teile (Node3D)             – schwankt im Wind (Drehpunkt am Boden)
##       <Mesh> (MeshInstance3D)  – ein bis zwei verschmolzene Meshes
##
## Keine Kollision – man läuft einfach hindurch.

enum Art {
	FARN,   ## mehrere gebogene Wedel
	PILZ,   ## Stiel und Hut, Hut leicht leuchtend
	BUSCH,  ## Haufen aus Blattballen
	BLUME,  ## Stiel mit Blütenkranz
}

## Blattgrün in drei Abstufungen (Farben.LAUB / LAUB_DUNKEL / LAUB_HELL).
const GRUENTOENE: Array[Color] = [
	Color(0.20, 0.44, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.35, 0.60, 0.22),
]
## Hutfarben für Pilze.
const PILZTOENE: Array[Color] = [
	Color(0.78, 0.22, 0.18),
	Color(0.85, 0.62, 0.35),
	Color(0.55, 0.38, 0.72),
	Color(0.90, 0.86, 0.72),
]
## Blütenfarben.
const BLUETENTOENE: Array[Color] = [
	Color(0.95, 0.86, 0.35),
	Color(0.92, 0.55, 0.75),
	Color(0.62, 0.72, 0.95),
	Color(0.98, 0.98, 0.92),
]

@export var art: Art = Art.FARN
## Größe in Metern (grob die Höhe des Objekts).
@export_range(0.1, 3.0, 0.05) var groesse: float = 0.7
## Feste Saat: gleicher Wert ⇒ gleiches Objekt. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Farbe selbst bestimmen statt aus der Palette würfeln.
@export var eigene_farbe: bool = false
## Nur wirksam, wenn `eigene_farbe` gesetzt ist.
@export var farbe: Color = Color(0.20, 0.44, 0.16)
## Sanftes Schwanken (bei Pilzen ohne Wirkung).
@export var wind: bool = true

var _rng: RandomNumberGenerator
var _phase := 0.0
var _zeit := 0.0
var _wind_x := 0.0
var _wind_z := 0.0

var _teile: Node3D


func _ready() -> void:
	# Gerüst besorgen – fehlt es (bei `Kleinzeug.new()`), wird es angelegt.
	_teile = PropWerkzeug.kind(self, "Teile",
			func() -> Node: return Node3D.new()) as Node3D
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	_phase = _rng.randf() * TAU

	match art:
		Art.PILZ:
			_baue_pilz()
		Art.BUSCH:
			_baue_busch()
		Art.BLUME:
			_baue_blume()
		_:
			_baue_farn()

	_teile.rotation.y = _rng.randf() * TAU
	_wind_x = deg_to_rad(_rng.randf_range(2.0, 4.5))
	_wind_z = deg_to_rad(_rng.randf_range(1.5, 3.5))
	set_process(wind and art != Art.PILZ and _teile.get_child_count() > 0)


## Wählt die Grundfarbe: entweder die eigene oder eine aus der Palette.
func _grundfarbe(palette: Array[Color]) -> Color:
	if eigene_farbe:
		return farbe
	return palette[_rng.randi_range(0, palette.size() - 1)]


# ---------------------------------------------------------------- Farn

func _baue_farn() -> void:
	var st := PropWerkzeug.bauer()
	var wedel := _rng.randi_range(5, 8)
	for i in wedel:
		var winkel := TAU * float(i) / float(wedel) + _rng.randf_range(-0.3, 0.3)
		_wedel(st, winkel, groesse * _rng.randf_range(0.75, 1.1),
				_rng.randf_range(0.55, 1.0))
	_haenge_an("Wedel", st, Materialbibliothek.laub(_grundfarbe(GRUENTOENE)))


## Ein Wedel: flache "Feder" aus Mittelrippe und paarweisen Fiederblättern,
## die sich nach außen überbiegt. Alles aus Vierecken – ein Wedel kostet
## nur rund 30 Dreiecke.
func _wedel(st: SurfaceTool, winkel: float, laenge: float, neigung: float) -> void:
	var stufen := 6
	var schritt := laenge / float(stufen)
	var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
	var pos := Vector3.ZERO
	for j in stufen:
		var t0 := float(j) / float(stufen)
		var t1 := float(j + 1) / float(stufen)
		# Winkel zur Senkrechten wächst mit t ⇒ der Wedel kippt nach außen
		var ab := lerpf(0.2, 1.4, t0) * neigung
		var richtung := Vector3(cos(winkel) * sin(ab), cos(ab), sin(winkel) * sin(ab))
		var naechster := pos + richtung * schritt
		var normale := richtung.cross(quer).normalized()

		# Mittelrippe
		var r0 := groesse * 0.03 * (1.0 - t0 * 0.6)
		var r1 := groesse * 0.03 * (1.0 - t1 * 0.6)
		PropWerkzeug.viereck(st, pos - quer * r0, naechster - quer * r1,
				naechster + quer * r1, pos + quer * r0, normale)

		# Fiederblätter, nach hinten gepfeilt
		var f0 := groesse * 0.32 * (1.0 - t0 * 0.62)
		var f1 := groesse * 0.32 * (1.0 - t1 * 0.62)
		for seite in [-1.0, 1.0]:
			PropWerkzeug.viereck(st,
					pos + quer * (r0 * seite),
					naechster + quer * (r1 * seite),
					naechster + quer * ((r1 + f1 * 0.35) * seite),
					pos + quer * ((r0 + f0) * seite) - richtung * schritt * 0.15,
					normale)
		pos = naechster


# ---------------------------------------------------------------- Pilz

func _baue_pilz() -> void:
	var hutfarbe := _grundfarbe(PILZTOENE)
	var stiele := PropWerkzeug.bauer()
	var huete := PropWerkzeug.bauer()
	var anzahl := _rng.randi_range(1, 3)

	for i in anzahl:
		var s := groesse * (1.0 if i == 0 else _rng.randf_range(0.45, 0.8))
		var versatz := Vector3.ZERO
		if i > 0:
			var w := _rng.randf() * TAU
			var d := groesse * _rng.randf_range(0.15, 0.35)
			versatz = Vector3(cos(w) * d, 0.0, sin(w) * d)

		var stiel_hoehe := s * 0.5
		PropWerkzeug.anfuegen(stiele,
				PropWerkzeug.stumpf(s * 0.08, s * 0.1, stiel_hoehe, 7, true),
				PropWerkzeug.ort(versatz + Vector3(0.0, stiel_hoehe * 0.5, 0.0)))

		# Hut: halbe Kugel, flach gedrückt
		var hut_r := s * 0.3 * _rng.randf_range(0.85, 1.2)
		PropWerkzeug.anfuegen(huete, PropWerkzeug.kugel(hut_r, 9, 5),
				PropWerkzeug.ort(versatz + Vector3(0.0, stiel_hoehe * 0.95, 0.0),
						Vector3(0.0, _rng.randf() * TAU, 0.0),
						Vector3(1.0, _rng.randf_range(0.5, 0.75), 1.0)))

	_haenge_an("Stiel", stiele, Materialbibliothek.einfarbig(Color(0.90, 0.87, 0.78)))
	# Leicht leuchtend – Pilze sind kleine Wegmarken im dunklen Wald
	_haenge_an("Hut", huete, Materialbibliothek.leuchtend(hutfarbe, 0.3))


# ---------------------------------------------------------------- Busch

func _baue_busch() -> void:
	var st := PropWerkzeug.bauer()
	var ballen := _rng.randi_range(4, 6)
	for i in ballen:
		var winkel := TAU * float(i) / float(ballen) + _rng.randf_range(-0.4, 0.4)
		var weite := groesse * (0.0 if i == 0 else _rng.randf_range(0.18, 0.4))
		var r := groesse * _rng.randf_range(0.28, 0.45)
		var versatz := Vector3(cos(winkel) * weite,
				groesse * _rng.randf_range(0.25, 0.55), sin(winkel) * weite)
		var skal := Vector3(_rng.randf_range(0.9, 1.35),
				_rng.randf_range(0.7, 1.05), _rng.randf_range(0.9, 1.35))
		PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(r, 8, 5),
				PropWerkzeug.ort(versatz,
						Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf() * TAU,
								_rng.randf_range(-0.4, 0.4)), skal))
	_haenge_an("Laub", st, Materialbibliothek.laub(_grundfarbe(GRUENTOENE)))


# ---------------------------------------------------------------- Blume

func _baue_blume() -> void:
	var bluetenfarbe := _grundfarbe(BLUETENTOENE)
	var stiele := PropWerkzeug.bauer()
	var blueten := PropWerkzeug.bauer()
	var anzahl := _rng.randi_range(2, 4)

	for i in anzahl:
		var h := groesse * _rng.randf_range(0.65, 1.0)
		var versatz := Vector3.ZERO
		if i > 0:
			var w := _rng.randf() * TAU
			var d := groesse * _rng.randf_range(0.1, 0.3)
			versatz = Vector3(cos(w) * d, 0.0, sin(w) * d)
		var kopf := versatz + Vector3(_rng.randf_range(-0.05, 0.05) * groesse, h,
				_rng.randf_range(-0.05, 0.05) * groesse)

		PropWerkzeug.anfuegen(stiele,
				PropWerkzeug.stumpf(groesse * 0.02, groesse * 0.015, h * 1.02, 5, false),
				PropWerkzeug.ausrichten(versatz, kopf))

		# Blütenkranz: Mitte plus flache Blätter ringsum
		var r := groesse * 0.115
		PropWerkzeug.anfuegen(blueten, PropWerkzeug.kugel(r * 0.7, 5, 3),
				PropWerkzeug.ort(kopf))
		var blaetter := 5
		for b in blaetter:
			var w2 := TAU * float(b) / float(blaetter) + _rng.randf_range(-0.1, 0.1)
			PropWerkzeug.anfuegen(blueten, PropWerkzeug.kugel(r, 5, 2),
					PropWerkzeug.ort(kopf + Vector3(cos(w2) * r * 1.1, 0.0, sin(w2) * r * 1.1),
							Vector3(0.0, -w2, 0.0), Vector3(1.5, 0.3, 0.8)))

	_haenge_an("Stiel", stiele, Materialbibliothek.einfarbig(Color(0.26, 0.46, 0.20)))
	_haenge_an("Bluete", blueten, Materialbibliothek.leuchtend(bluetenfarbe, 0.2))


# ---------------------------------------------------------------- Helfer

func _haenge_an(bezeichnung: String, st: SurfaceTool, material: Material) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung, PropWerkzeug.fertig(st),
			material, false)
	if knoten != null:
		_teile.add_child(knoten)


## Der Drehpunkt liegt am Boden – dadurch wippt die Pflanze aus dem Fuß heraus.
func _process(delta: float) -> void:
	_zeit += delta
	_teile.rotation.x = _wind_x * sin(_zeit * 1.4 + _phase)
	_teile.rotation.z = _wind_z * sin(_zeit * 2.1 + _phase * 1.6)
