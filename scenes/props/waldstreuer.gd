extends Node3D
class_name Waldstreuer
## Verteilt Wald-Props zufällig über eine Fläche – ein Knoten im Level,
## fertiger Wald.
##
## Die Fläche liegt zentriert um den Knoten (X mal Z, lokale Achsen). In der
## Mitte bleibt ein Streifen der Breite `2 * mindestabstand_mitte` frei,
## damit der Korridor begehbar bleibt. Wer den Streuer als reine Randdeko
## nutzt, setzt `mindestabstand_mitte = 0` und stellt den Knoten neben den Weg.
##
## Alles hängt an der Saat: derselbe `saat`-Wert ergibt immer denselben Wald.

const BAUM_SZENE := preload("res://scenes/props/Baum.tscn")
const STEIN_SZENE := preload("res://scenes/props/Stein.tscn")
const WURZEL_SZENE := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG_SZENE := preload("res://scenes/props/Kleinzeug.tscn")
const GRAS_SZENE := preload("res://scenes/props/Gras.tscn")

## Laubfarben, aus denen die Bäume würfeln. Wenige Töne, damit die
## Material-Zwischenspeicher der Materialbibliothek klein bleiben.
const LAUBTOENE: Array[Color] = [
	Color(0.20, 0.44, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.35, 0.60, 0.22),
]

## Größe der Streufläche in Metern (X mal Z), zentriert um den Knoten.
@export var flaeche: Vector2 = Vector2(26.0, 40.0)
## Gesamtzahl der gestreuten Props (ohne Grasfelder).
@export_range(0, 400) var anzahl: int = 30
## Feste Saat: gleicher Wert ⇒ gleicher Wald. 0 = jedes Mal neu würfeln.
@export var saat: int = 0
## Freihaltezone um die Mittelachse (X = 0) in Metern – hier wächst nichts.
@export_range(0.0, 60.0, 0.5) var mindestabstand_mitte: float = 6.0

@export_group("Mischung")
## Anteil Bäume an `anzahl`.
@export_range(0.0, 1.0, 0.01) var anteil_baeume: float = 0.35
## Anteil Steine an `anzahl`.
@export_range(0.0, 1.0, 0.01) var anteil_steine: float = 0.15
## Anteil Wurzelbögen an `anzahl`.
@export_range(0.0, 1.0, 0.01) var anteil_wurzeln: float = 0.05
## Der Rest wird zu Kleinzeug (Farn, Pilz, Busch, Blume).

@export_group("Bäume")
@export_range(3.0, 14.0, 0.1) var baum_hoehe_min: float = 5.0
@export_range(3.0, 14.0, 0.1) var baum_hoehe_max: float = 10.5
## Anteil Nadelbäume.
@export_range(0.0, 1.0, 0.01) var anteil_nadelbaum: float = 0.3
## Anteil Totholz.
@export_range(0.0, 1.0, 0.01) var anteil_totholz: float = 0.08
## Mindestabstand zwischen zwei Bäumen in Metern.
@export_range(0.0, 12.0, 0.1) var baumabstand: float = 2.8

@export_group("Gras")
## Anzahl der Grasfelder (jedes ist ein einziger MultiMesh-Knoten).
@export_range(0, 40) var grasfelder: int = 4
## Büschel je Grasfeld.
@export_range(1, 800) var gras_dichte: int = 150
## Kantenlänge eines Grasfeldes in Metern.
@export_range(1.0, 30.0, 0.5) var gras_feldgroesse: float = 6.0

@export_group("Gelände")
## Höhe, auf der die Props abgesetzt werden (lokale Y-Koordinate).
@export var boden_hoehe: float = 0.0
## Zufälliger Höhenversatz nach unten – lässt Props in unebenem Boden versinken.
@export_range(0.0, 2.0, 0.05) var hoehen_streuung: float = 0.0
## Kollision der Bäume/Steine/Wurzeln. Für weit entfernte Kulisse abschaltbar.
@export var kollision: bool = true

var _rng: RandomNumberGenerator
## Bereits belegte Baumplätze (nur X/Z), für den Mindestabstand.
var _baumplaetze: Array[Vector2] = []


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	_streue()


func _streue() -> void:
	var n_baeume := int(round(anzahl * anteil_baeume))
	var n_steine := int(round(anzahl * anteil_steine))
	var n_wurzeln := int(round(anzahl * anteil_wurzeln))
	var n_klein := maxi(anzahl - n_baeume - n_steine - n_wurzeln, 0)

	# Reihenfolge: erst das Große (braucht Platz), dann das Kleine
	for i in n_baeume:
		_setze_baum()
	for i in n_steine:
		_setze_stein()
	for i in n_wurzeln:
		_setze_wurzel()
	for i in grasfelder:
		_setze_grasfeld()
	for i in n_klein:
		_setze_kleinzeug()


# ---------------------------------------------------------------- Props

func _setze_baum() -> void:
	var pos := _freier_baumplatz()
	var b := BAUM_SZENE.instantiate() as Baum
	var wurf := _rng.randf()
	if wurf < anteil_totholz:
		b.art = Baum.Art.TOTHOLZ
	elif wurf < anteil_totholz + anteil_nadelbaum:
		b.art = Baum.Art.NADELBAUM
	else:
		b.art = Baum.Art.LAUBBAUM
	b.hoehe = _rng.randf_range(minf(baum_hoehe_min, baum_hoehe_max),
			maxf(baum_hoehe_min, baum_hoehe_max))
	b.staerke = _rng.randf_range(0.8, 1.25)
	b.laubfarbe = LAUBTOENE[_rng.randi_range(0, LAUBTOENE.size() - 1)]
	b.saat = PropWerkzeug.kindsaat(_rng)
	b.kollision = kollision
	b.position = pos
	b.rotation.y = _rng.randf() * TAU
	add_child(b)


func _setze_stein() -> void:
	var s := STEIN_SZENE.instantiate() as Stein
	s.groesse = _rng.randf_range(0.5, 2.2)
	s.brocken = _rng.randi_range(2, 4)
	s.flach = _rng.randf() < 0.3
	s.bemoost = _rng.randf() < 0.7
	s.saat = PropWerkzeug.kindsaat(_rng)
	s.kollision = kollision
	s.position = _zufallsplatz(0.6)
	s.rotation.y = _rng.randf() * TAU
	add_child(s)


func _setze_wurzel() -> void:
	var w := WURZEL_SZENE.instantiate() as Wurzel
	w.spannweite = _rng.randf_range(2.5, 5.5)
	w.hoehe = _rng.randf_range(0.5, 1.4)
	w.dicke = _rng.randf_range(0.3, 0.55)
	w.segmente = 7
	w.saat = PropWerkzeug.kindsaat(_rng)
	w.kollision = kollision
	w.position = _zufallsplatz(w.spannweite * 0.5)
	w.rotation.y = _rng.randf() * TAU
	add_child(w)


func _setze_kleinzeug() -> void:
	var k := KLEINZEUG_SZENE.instantiate() as Kleinzeug
	var wurf := _rng.randf()
	if wurf < 0.4:
		k.art = Kleinzeug.Art.FARN
		k.groesse = _rng.randf_range(0.5, 0.95)
	elif wurf < 0.65:
		k.art = Kleinzeug.Art.BUSCH
		k.groesse = _rng.randf_range(0.6, 1.3)
	elif wurf < 0.85:
		k.art = Kleinzeug.Art.PILZ
		k.groesse = _rng.randf_range(0.25, 0.6)
	else:
		k.art = Kleinzeug.Art.BLUME
		k.groesse = _rng.randf_range(0.3, 0.6)
	k.saat = PropWerkzeug.kindsaat(_rng)
	k.position = _zufallsplatz(0.3)
	add_child(k)


func _setze_grasfeld() -> void:
	var g := GRAS_SZENE.instantiate() as Grasfeld
	var kante := gras_feldgroesse * _rng.randf_range(0.7, 1.25)
	g.flaeche = Vector2(kante, kante)
	g.anzahl = maxi(int(gras_dichte * _rng.randf_range(0.7, 1.2)), 1)
	g.halm_hoehe = _rng.randf_range(0.35, 0.7)
	g.saat = PropWerkzeug.kindsaat(_rng)
	# Grasfelder werden nicht gedreht: die Fläche ist ohnehin quadratisch,
	# und ohne Drehung passt die Freihaltezone exakt.
	g.position = _zufallsplatz(kante * 0.5)
	add_child(g)


# ---------------------------------------------------------------- Platzwahl

## Zufälliger Platz in der Fläche, der die Freihaltezone in der Mitte
## respektiert. `rand` ist der Platzbedarf des Props (halbe Breite).
func _zufallsplatz(rand: float) -> Vector3:
	var halb_x := flaeche.x * 0.5
	var halb_z := flaeche.y * 0.5
	var von := mindestabstand_mitte + rand
	var bis := maxf(halb_x - rand, von + 0.01)
	var seite := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := seite * _rng.randf_range(von, bis)
	var z := _rng.randf_range(-halb_z, halb_z)
	var y := boden_hoehe - _rng.randf() * hoehen_streuung
	return Vector3(x, y, z)


## Wie `_zufallsplatz`, hält aber zusätzlich Abstand zu schon gesetzten Bäumen.
func _freier_baumplatz() -> Vector3:
	var pos := _zufallsplatz(0.8)
	if baumabstand <= 0.0:
		return pos
	var quadrat := baumabstand * baumabstand
	for versuch in 8:
		var frei := true
		for platz in _baumplaetze:
			if platz.distance_squared_to(Vector2(pos.x, pos.z)) < quadrat:
				frei = false
				break
		if frei:
			break
		pos = _zufallsplatz(0.8)
	_baumplaetze.append(Vector2(pos.x, pos.z))
	return pos
