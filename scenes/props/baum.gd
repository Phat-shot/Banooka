extends Node3D
class_name Baum
## Prozeduraler Waldbaum in drei Ausführungen: Laubbaum, Nadelbaum, Totholz.
##
## Aufbau (6 Knoten – unverändert):
##   Baum (Node3D)
##     Stamm (StaticBody3D, Ebene 1)  – nur Kollision, kein Mesh
##       Kollision (CollisionShape3D) – Zylinder um den Stammfuß
##     Holz (MeshInstance3D)          – Wurzelanlauf, Stamm und Äste als EIN Mesh
##     Krone (Node3D)                 – schwankt im Wind
##       Blattwerk (MeshInstance3D)   – alle Blattballen als EIN Mesh
##
## Alle Details entstehen im Mesh, nicht über zusätzliche Knoten:
##
## * Der Fuß bekommt einen **Wurzelanlauf** aus mehreren auslaufenden
##   Strebewurzeln – der Stamm steckt nicht mehr wie eine Stange im Boden.
## * Der Stamm ist aus gestapelten Kegelstümpfen gebogen und trägt 2–4
##   sichtbare **Äste, die in die Krone hineinführen** (die Astspitzen enden
##   bewusst in den Blattballen).
## * Die Krone besteht aus mehreren **unterschiedlich großen, versetzten,
##   leicht abgeflachten Ballen** mit unregelmäßiger Oberfläche
##   (`PropWerkzeug.klumpen`). Scheitelfarben dunkeln sie nach unten ab.
## * Über `kronenform` (bzw. die Saat) entstehen breite, hohe und
##   schirmförmige Bäume – kein Bestand sieht mehr gleich aus.
##
## Die Krone ist NICHT kollidierbar – man springt durch die Blätter hindurch.

enum Art {
	LAUBBAUM,   ## geschichtete Blattballen
	NADELBAUM,  ## gestaffelte Zweigkränze
	TOTHOLZ,    ## kahler Stamm mit Splitterbruch
}

## Grundriss der Laubkrone.
enum Kronenform {
	ZUFALL,  ## aus der Saat würfeln
	BREIT,   ## niedrig angesetzt, weit ausladend
	HOCH,    ## schlank und hoch, wie im dichten Bestand
	SCHIRM,  ## hoher Stamm, flach aufsitzende Schirmkrone
}

## Standard-Laubfarben (entsprechen Farben.LAUB / LAUB_DUNKEL / LAUB_HELL).
const LAUBTOENE: Array[Color] = [
	Color(0.20, 0.44, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.35, 0.60, 0.22),
]

## Wie stark die Krone an ihrer Unterseite abgedunkelt wird (Scheitelfarbe,
## wirkt multiplikativ auf das Material der Bibliothek).
const KRONE_UNTEN := Color(0.33, 0.37, 0.31)
const KRONE_OBEN := Color(1.0, 1.0, 0.97)

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
## Grundriss der Laubkrone (nur beim Laubbaum wirksam).
@export var kronenform: Kronenform = Kronenform.ZUFALL

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


# ---------------------------------------------------------------- Laubbaum

func _baue_laubbaum() -> void:
	var form := _gewaehlte_kronenform()
	var werte := _formwerte(form)

	var stamm_hoehe: float = hoehe * werte["stammanteil"] * _rng.randf_range(0.92, 1.08)
	var r_unten := _stammradius()
	var r_oben := r_unten * _rng.randf_range(0.34, 0.48)

	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten, _rng.randi_range(5, 7))
	var punkte := _stamm_segmente(st, stamm_hoehe, r_unten, r_oben,
			maxi(int(hoehe * 0.85), 5), _rng.randf_range(0.09, 0.2))
	var spitze: Vector3 = punkte[punkte.size() - 1]

	var radius: float = hoehe * float(werte["radius"]) * _rng.randf_range(0.88, 1.12)
	var spanne: float = radius * float(werte["spanne"])
	# Die Krone sitzt so tief, dass der obere Stamm in ihr steckt – dadurch
	# wächst sie aus dem Baum heraus, statt obenauf zu liegen.
	var kronen_ort: Vector3 = spitze + Vector3.UP * (spanne * 0.42)

	# Erst die Ballen festlegen – dann können die Äste gezielt hineinführen.
	var ballen := _kronen_ballen(werte, radius, spanne)
	_aeste_zur_krone(st, punkte, ballen, kronen_ort, r_oben)
	_setze_holz(st, Materialbibliothek.rinde())

	_baue_krone(ballen, kronen_ort)
	_setze_kollision(r_unten * 1.15, hoehe * 0.6)


## Beim Wert ZUFALL entscheidet die Saat – so bleibt derselbe Baum gleich.
func _gewaehlte_kronenform() -> Kronenform:
	if kronenform != Kronenform.ZUFALL:
		return kronenform
	var wurf := _rng.randf()
	if wurf < 0.42:
		return Kronenform.BREIT
	if wurf < 0.78:
		return Kronenform.HOCH
	return Kronenform.SCHIRM


## Kennzahlen je Kronenform. `radius` und `spanne` sind Anteile der Baumhöhe.
func _formwerte(form: Kronenform) -> Dictionary:
	match form:
		Kronenform.HOCH:
			return {"stammanteil": 0.50, "radius": 0.20, "spanne": 2.1,
					"spreiz_unten": 0.60, "spreiz_oben": 0.24,
					"ball_unten": 0.62, "ball_oben": 0.46, "ballen": 8}
		Kronenform.SCHIRM:
			return {"stammanteil": 0.66, "radius": 0.32, "spanne": 0.85,
					"spreiz_unten": 0.48, "spreiz_oben": 0.80,
					"ball_unten": 0.44, "ball_oben": 0.54, "ballen": 7}
		_:
			return {"stammanteil": 0.52, "radius": 0.30, "spanne": 1.25,
					"spreiz_unten": 0.72, "spreiz_oben": 0.22,
					"ball_unten": 0.58, "ball_oben": 0.46, "ballen": 7}


## Legt Ort, Halbachsen und Drehung der Blattballen fest (Koordinaten relativ
## zum Kronenknoten). Die Ballen sind bewusst leicht abgeflacht und
## unterschiedlich groß – das ergibt die geschichtete Silhouette.
func _kronen_ballen(werte: Dictionary, radius: float, spanne: float) -> Array:
	var anzahl: int = int(werte["ballen"]) + _rng.randi_range(-1, 1)
	anzahl = maxi(anzahl, 4)

	var ballen: Array = []
	var drall := _rng.randf() * TAU
	for i in anzahl:
		# t = 0 unten, 1 oben; leicht gestört, damit keine Etagen entstehen
		var t := clampf(float(i) / float(anzahl - 1) + _rng.randf_range(-0.1, 0.1),
				0.0, 1.0)
		var weite := radius * lerpf(float(werte["spreiz_unten"]),
				float(werte["spreiz_oben"]), t) * _rng.randf_range(0.7, 1.15)
		# der oberste Ballen sitzt mittig auf der Achse und schließt die Krone
		if i == anzahl - 1:
			weite *= 0.25
		# jeder dritte Ballen hängt tiefer: das bricht die harte Unterkante
		var haenger := 1.0 if i % 3 == 1 else 0.0
		var winkel := drall + TAU * 0.618 * float(i) + _rng.randf_range(-0.35, 0.35)
		var r := radius * lerpf(float(werte["ball_unten"]),
				float(werte["ball_oben"]), t) * _rng.randf_range(0.82, 1.18)
		var pos := Vector3(cos(winkel) * weite,
				lerpf(-spanne * 0.5, spanne * 0.5, t)
						+ _rng.randf_range(-0.06, 0.06) * spanne
						- haenger * spanne * _rng.randf_range(0.1, 0.25),
				sin(winkel) * weite)
		# leicht abgeflacht: Blattballen sind breiter als hoch, aber keine
		# Scheiben – sonst wirkt die Krone wie ein Teller
		var radien := Vector3(r * _rng.randf_range(0.95, 1.3),
				r * _rng.randf_range(0.72, 0.98),
				r * _rng.randf_range(0.95, 1.3))
		var dreh := Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf() * TAU,
				_rng.randf_range(-0.25, 0.25))
		ballen.append({"pos": pos, "radien": radien, "dreh": dreh,
				"ton": _rng.randf_range(0.86, 1.0)})
	return ballen


func _baue_krone(ballen: Array, kronen_ort: Vector3) -> void:
	var st := PropWerkzeug.bauer()
	var von := INF
	var bis := -INF
	for b in ballen:
		von = minf(von, b["pos"].y - b["radien"].y)
		bis = maxf(bis, b["pos"].y + b["radien"].y)
	# Der Verlauf greift etwas tiefer an, damit die Unterseite satt dunkel wird
	von -= (bis - von) * 0.15

	for b in ballen:
		var ton: float = b["ton"]
		var unten := Color(KRONE_UNTEN.r * ton, KRONE_UNTEN.g * ton, KRONE_UNTEN.b * ton)
		var oben := Color(KRONE_OBEN.r * ton, KRONE_OBEN.g * ton, KRONE_OBEN.b * ton)
		PropWerkzeug.klumpen(st, _rng, b["pos"], b["radien"], b["dreh"], 9, 5,
				0.3, false, unten, oben, von, bis)
	_setze_krone(st, kronen_ort)


# ---------------------------------------------------------------- Nadelbaum

func _baue_nadelbaum() -> void:
	var r_unten := _stammradius() * 0.86
	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten, _rng.randi_range(4, 6))
	# Der Stamm endet unter dem obersten Kranz – sonst ragt eine kahle
	# Stange aus der Spitze heraus.
	var punkte := _stamm_segmente(st, hoehe * 0.72, r_unten, r_unten * 0.18,
			maxi(int(hoehe * 0.55), 5), _rng.randf_range(0.02, 0.06))
	# ein paar kahle Stummel unten am Stamm, wo keine Kränze mehr sitzen
	_aststummel(st, punkte, _rng.randi_range(2, 3), r_unten * 0.28, 0.0, 0.3)
	_setze_holz(st, Materialbibliothek.rinde())

	var start := hoehe * _rng.randf_range(0.13, 0.22)
	var oben := hoehe * _rng.randf_range(0.80, 0.90)
	var stufen := clampi(int(hoehe * 0.8), 6, 10)
	var r_max := hoehe * _rng.randf_range(0.19, 0.26)
	var mitte := (start + oben) * 0.5
	var spitzen_h := hoehe * _rng.randf_range(0.1, 0.17)
	# Farbverlauf über den GANZEN Baum – kein Wechsel von Kranz zu Kranz
	var von := start - mitte - r_max * 0.3
	var bis := oben - mitte + spitzen_h

	var kst := PropWerkzeug.bauer()
	for i in stufen:
		var t := float(i) / float(stufen - 1)
		# nach oben deutlich schlanker, unten breit ausladend
		var radius := lerpf(r_max, hoehe * 0.04, pow(t, 0.75)) * _rng.randf_range(0.9, 1.1)
		var kranz_h := (oben - start) / float(stufen) * _rng.randf_range(2.0, 2.7)
		_zweigkranz(kst, lerpf(start, oben, t) - mitte, radius, kranz_h,
				_rng.randi_range(10, 14), von, bis)
	# schlanke Spitze
	_zweigkranz(kst, oben - mitte, hoehe * 0.038, spitzen_h, 8, von, bis)

	_setze_krone(kst, Vector3(0.0, mitte, 0.0))
	_setze_kollision(r_unten * 1.25, hoehe * 0.8)


## Ein Zweigkranz: flacher Kegel, dessen Randpunkte abwechselnd weit und kurz
## auslaufen und dabei unterschiedlich tief hängen. Aus der Ferne ergibt das
## eine gezackte Kontur mit einzelnen Zweigspitzen statt einer glatten
## Kegelmantelfläche. Kosten: 2 Dreiecke je Zacke.
func _zweigkranz(st: SurfaceTool, y: float, radius: float, kranz_hoehe: float,
		zacken: int, von: float, bis: float) -> void:
	var n := maxi(zacken, 6)
	var spitze := Vector3(0.0, y + kranz_hoehe, 0.0)
	var nabe := Vector3(0.0, y + kranz_hoehe * 0.1, 0.0)
	var versatz := _rng.randf() * TAU
	var ring := PackedVector3Array()
	for j in n:
		var lang := j % 2 == 0
		var th := TAU * float(j) / float(n) + versatz + _rng.randf_range(-0.1, 0.1)
		var rr := radius * (1.0 if lang else _rng.randf_range(0.6, 0.78)) \
				* _rng.randf_range(0.9, 1.1)
		# lange Zweige hängen tiefer als die kurzen dazwischen
		var senke := radius * (_rng.randf_range(0.12, 0.3) if lang
				else _rng.randf_range(0.0, 0.1))
		ring.append(Vector3(cos(th) * rr, y - senke, sin(th) * rr))
	for j in n:
		var p0: Vector3 = ring[j]
		var p1: Vector3 = ring[(j + 1) % n]
		var aussen := ((p0 + p1) * 0.5 - Vector3(0.0, y, 0.0)).normalized() \
				+ Vector3.UP * 0.4
		PropWerkzeug.flaeche(st, spitze, p0, p1, aussen,
				_nadelton((spitze.y + p0.y + p1.y) / 3.0, von, bis, false))
		PropWerkzeug.flaeche(st, nabe, p0, p1, Vector3.DOWN,
				_nadelton((nabe.y + p0.y + p1.y) / 3.0, von, bis, true))


## Scheitelfarbe eines Kranzstücks: unten im Baum dunkel, oben hell,
## Unterseiten grundsätzlich dunkler. Das ersetzt die früher zufällige
## Helligkeit je Kranz, die wie aufgeklebtes Papier aussah.
func _nadelton(y: float, von: float, bis: float, unterseite: bool) -> Color:
	var t := clampf(inverse_lerp(von, bis, y), 0.0, 1.0)
	var h := lerpf(0.62, 1.0, t) * (0.7 if unterseite else 1.0)
	h *= _rng.randf_range(0.95, 1.05)
	return Color(h * 0.97, h, h * 0.93)


# ---------------------------------------------------------------- Totholz

func _baue_totholz() -> void:
	var stamm_hoehe := hoehe * _rng.randf_range(0.55, 0.75)
	var r_unten := _stammradius() * 1.45
	var r_oben := r_unten * _rng.randf_range(0.55, 0.72)

	var st := PropWerkzeug.bauer()
	_wurzelanlauf(st, r_unten, _rng.randi_range(4, 6))
	var punkte := _stamm_segmente(st, stamm_hoehe, r_unten, r_oben,
			maxi(int(hoehe * 0.7), 4), _rng.randf_range(0.12, 0.24))
	# kahle Aststummel: kurz, stumpf abgebrochen
	_aststummel(st, punkte, _rng.randi_range(3, 5), r_oben * 0.75, 0.35, 1.0)
	_splitterbruch(st, punkte[punkte.size() - 1], r_oben)
	# Rinde statt Wurzelholz: Wurzelholz trägt Moosgrün, das an einem
	# abgestorbenen Stamm wie Tarnfarbe aussieht.
	_setze_holz(st, Materialbibliothek.rinde())
	_setze_kollision(r_unten * 1.05, stamm_hoehe)


## Abgebrochene Krone: mehrere unterschiedlich hohe Splitter stehen schräg
## vom Bruchrand ab, dazwischen bleibt die Bruchfläche stehen.
func _splitterbruch(st: SurfaceTool, spitze: Vector3, r_oben: float) -> void:
	var anzahl := _rng.randi_range(4, 7)
	var versatz := _rng.randf() * TAU
	for i in anzahl:
		var th := TAU * float(i) / float(anzahl) + versatz + _rng.randf_range(-0.2, 0.2)
		var weite := r_oben * _rng.randf_range(0.35, 0.85)
		var fuss := spitze + Vector3(cos(th) * weite, -r_oben * 0.4, sin(th) * weite)
		var laenge := r_oben * _rng.randf_range(0.7, 2.8)
		var kippe := _rng.randf_range(0.08, 0.35)
		var kopf := fuss + Vector3(cos(th) * laenge * kippe, laenge,
				sin(th) * laenge * kippe)
		# derbe Späne: unten breit, oben spitz zulaufend
		var r := r_oben * _rng.randf_range(0.28, 0.5)
		PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(r, 0.0, laenge, 4, false),
				PropWerkzeug.ausrichten(fuss, kopf))
	# stehen gebliebene Bruchfläche in der Mitte
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.stumpf(r_oben * 0.95, r_oben * 0.6, r_oben * 0.7, 7, true),
			PropWerkzeug.ort(spitze))


# ---------------------------------------------------------------- Bausteine

func _stammradius() -> float:
	return 0.21 * staerke * (hoehe / 7.0) + 0.06


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


## Wurzelanlauf: verbreiterter Fuß plus mehrere Strebewurzeln, die aus dem
## Stamm heraus schräg in den Boden laufen. Erst dadurch sieht der Baum
## gewachsen aus statt eingesteckt.
func _wurzelanlauf(st: SurfaceTool, r_unten: float, anzahl: int) -> void:
	var fuss_h := r_unten * 2.6
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.stumpf(r_unten * 1.55, r_unten * 1.02, fuss_h, 8, false),
			PropWerkzeug.ort(Vector3(0.0, fuss_h * 0.42, 0.0)))

	var versatz := _rng.randf() * TAU
	for i in anzahl:
		var th := TAU * float(i) / float(anzahl) + versatz + _rng.randf_range(-0.25, 0.25)
		var laenge := r_unten * _rng.randf_range(1.5, 2.6)
		var start := Vector3(0.0, r_unten * _rng.randf_range(1.1, 1.9), 0.0)
		var ende := Vector3(cos(th) * laenge, -r_unten * 0.45, sin(th) * laenge)
		var mitte := start.lerp(ende, 0.5) + Vector3.UP * r_unten * 0.2
		# kräftig und kurz: die Streben verschmelzen zu einem Anlauf,
		# statt wie Spinnenbeine unter dem Stamm zu stehen
		var r := r_unten * _rng.randf_range(0.6, 0.85)
		_ast_segment(st, start, mitte, r, r * 0.72, 6)
		_ast_segment(st, mitte, ende, r * 0.72, r * 0.22, 5)


## Ein Stamm-/Astabschnitt als Kegelstumpf zwischen zwei Punkten.
func _ast_segment(st: SurfaceTool, von: Vector3, bis: Vector3,
		r0: float, r1: float, seiten: int) -> void:
	var laenge := von.distance_to(bis)
	if laenge < 0.005:
		return
	# 6 % Überlappung, damit an den Knicken keine Lücken aufreißen
	var form := PropWerkzeug.stumpf(r0, r1, laenge * 1.06, seiten, false)
	PropWerkzeug.anfuegen(st, form, PropWerkzeug.ausrichten(von, bis))


## Sichtbare Äste, die vom oberen Stamm in die Blattballen hineinführen.
## Die Astspitze endet im Ballen – so hängt die Krone erkennbar am Holz.
func _aeste_zur_krone(st: SurfaceTool, punkte: PackedVector3Array, ballen: Array,
		kronen_ort: Vector3, radius: float) -> void:
	if punkte.size() < 3 or ballen.is_empty():
		return
	# die am weitesten außen liegenden Ballen zuerst – die brauchen Halt
	var reihenfolge: Array = range(ballen.size())
	reihenfolge.sort_custom(func(a: int, b: int) -> bool:
		return Vector2(ballen[a]["pos"].x, ballen[a]["pos"].z).length() \
				> Vector2(ballen[b]["pos"].x, ballen[b]["pos"].z).length())

	var anzahl := mini(_rng.randi_range(3, 5), reihenfolge.size())
	for i in anzahl:
		var ziel: Dictionary = ballen[reihenfolge[i]]
		# bewusst weit unten ansetzen: nur so tritt der Ast unterhalb der
		# Krone aus dem Stamm und ist von außen überhaupt zu sehen
		var idx := _rng.randi_range(maxi(int(punkte.size() * 0.35), 1), punkte.size() - 1)
		var start: Vector3 = punkte[idx]
		var ende: Vector3 = kronen_ort + ziel["pos"] * _rng.randf_range(0.6, 0.95)
		# Knick auf halber Strecke, leicht durchhängend – Äste sind nie gerade
		var mitte := start.lerp(ende, 0.55) + Vector3.DOWN * start.distance_to(ende) * 0.1
		var r := radius * _rng.randf_range(0.75, 1.0)
		_ast_segment(st, start, mitte, r, r * 0.62, 6)
		_ast_segment(st, mitte, ende, r * 0.62, r * 0.22, 5)


## Kurze, stumpf abgebrochene Aststummel. `von`/`bis` grenzen ein, in welchem
## Bereich des Stammes (0 = Fuß, 1 = Spitze) sie sitzen dürfen.
func _aststummel(st: SurfaceTool, punkte: PackedVector3Array, anzahl: int,
		radius: float, von: float, bis: float) -> void:
	if punkte.size() < 3:
		return
	var u := clampi(int(punkte.size() * von), 0, punkte.size() - 2)
	var o := clampi(int(punkte.size() * bis), u + 1, punkte.size() - 1)
	var versatz := _rng.randf() * TAU
	for i in anzahl:
		var idx := _rng.randi_range(u, o)
		var start: Vector3 = punkte[idx]
		var th := TAU * float(i) / float(anzahl) + versatz + _rng.randf_range(-0.4, 0.4)
		var steigung := _rng.randf_range(0.15, 0.75)
		var richtung := Vector3(cos(th), steigung, sin(th)).normalized()
		var l := radius * _rng.randf_range(3.0, 8.0)
		var ende := start + richtung * l
		# stumpfes Ende: der Ast bricht ab, statt spitz auszulaufen
		_ast_segment(st, start, ende, radius, radius * _rng.randf_range(0.4, 0.6), 5)


func _setze_holz(st: SurfaceTool, material: Material) -> void:
	var knoten := PropWerkzeug.mesh_knoten("Holz", PropWerkzeug.fertig(st), material)
	if knoten != null:
		add_child(knoten)


func _setze_krone(st: SurfaceTool, mitte: Vector3) -> void:
	var knoten := PropWerkzeug.mesh_knoten("Blattwerk",
			PropWerkzeug.fertig_mit_tangenten(st),
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.laub(laubfarbe)))
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
