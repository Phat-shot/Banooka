extends Node3D
class_name Kleinzeug
## Kleine Bodendeko: Farn, Pilz, Busch oder Blume – Art über `art`.
##
## Aufbau (3–4 Knoten – unverändert):
##   Kleinzeug (Node3D)
##     Teile (Node3D)             – schwankt im Wind (Drehpunkt am Boden)
##       <Mesh> (MeshInstance3D)  – ein bis zwei verschmolzene Meshes
##
## Alle Details stecken im Mesh:
##   * FARN  – gefiederte Wedel: Mittelrippe mit paarweisen, nach hinten
##             gepfeilten Fiederblättern, die sich nach außen überbiegen.
##   * PILZ  – Gruppen von 2 bis 5 Pilzen unterschiedlicher Größe, mit
##             leicht geneigten Stielen und unregelmäßigen Hüten.
##   * BUSCH – unregelmäßige, flache Blattpolster plus einzelne Blätter,
##             die über die Silhouette hinausstehen.
##   * BLUME – Horst aus mehreren Stielen mit Blütenkranz und Bodenblättern.
##
## Keine Kollision – man läuft einfach hindurch.

enum Art {
	FARN,   ## mehrere gebogene, gefiederte Wedel
	PILZ,   ## Gruppe aus Stiel und Hut, Hut leicht leuchtend
	BUSCH,  ## Blattpolster mit einzelnen abstehenden Blättern
	BLUME,  ## Stiele mit Blütenkranz
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

## Scheitelfarben: unten abgedunkelt, oben volle Materialfarbe.
const FUSS := Color(0.46, 0.50, 0.44)
const KOPF := Color(1.0, 1.0, 0.98)

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


## Setzt ein mitgeliefertes Modell und meldet, ob es geklappt hat.
## Kleinzeug steht nur herum, es hat weder Kollision noch bewegliche Teile –
## der Wind wiegt den ganzen Knoten.
func _setze_fertiges_modell() -> bool:
	if not NaturAssets.aktiv():
		return false
	var auswahl: Array = []
	match art:
		Art.PILZ:
			auswahl = ["mushroom_red", "mushroom_redGroup",
					"mushroom_tan", "mushroom_tanGroup"]
		Art.BUSCH:
			auswahl = ["plant_bush", "plant_bushSmall", "plant_bushDetailed"]
		Art.BLUME:
			auswahl = ["flower_redA", "flower_yellowA", "flower_purpleA"]
		_:
			# plant_flat* sind flache Blattkarten – als Farn am Boden
			# werden sie zu breiten Keilen. Deshalb nur Buschwerk.
			auswahl = ["grass_leafs", "grass_leafsLarge", "plant_bushSmall"]
	var modell := NaturAssets.waehle(auswahl, _rng, groesse)
	if modell == null:
		return false
	modell.name = "Modell"
	modell.rotation.y = _rng.randf() * TAU
	_teile.add_child(modell)
	return true


func _ready() -> void:
	# Gerüst besorgen – fehlt es (bei `Kleinzeug.new()`), wird es angelegt.
	_teile = PropWerkzeug.kind(self, "Teile",
			func() -> Node: return Node3D.new()) as Node3D
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_rng = PropWerkzeug.zufall(saat)
	_phase = _rng.randf() * TAU

	if not _setze_fertiges_modell():
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


## Scheitelfarbe nach Höhe: unten dunkel, oben hell.
func _ton(y: float, spanne: float) -> Color:
	return FUSS.lerp(KOPF, clampf(y / maxf(spanne, 0.0001), 0.0, 1.0))


# ---------------------------------------------------------------- Farn

func _baue_farn() -> void:
	var st := PropWerkzeug.bauer()
	var wedel := _rng.randi_range(7, 10)
	var versatz := _rng.randf() * TAU
	for i in wedel:
		var winkel := versatz + TAU * float(i) / float(wedel) + _rng.randf_range(-0.3, 0.3)
		_wedel(st, winkel, groesse * _rng.randf_range(0.7, 1.15),
				_rng.randf_range(0.6, 1.05))
	_haenge_an("Wedel", st, Materialbibliothek.laub(_grundfarbe(GRUENTOENE)))


## Ein Wedel: flache "Feder" aus Mittelrippe und paarweisen Fiederblättern,
## die sich nach außen überbiegt. Alles aus Vierecken – ein Wedel kostet
## nur rund 36 Dreiecke.
func _wedel(st: SurfaceTool, winkel: float, laenge: float, neigung: float) -> void:
	var stufen := 6
	var schritt := laenge / float(stufen)
	var quer := Vector3(-sin(winkel), 0.0, cos(winkel))
	var pos := Vector3.ZERO
	for j in stufen:
		var t0 := float(j) / float(stufen)
		var t1 := float(j + 1) / float(stufen)
		# Winkel zur Senkrechten wächst mit t ⇒ der Wedel kippt nach außen
		# und legt sich am Ende fast waagerecht
		var ab := lerpf(0.12, 2.0, t0 * t0 * 0.55 + t0 * 0.45) * neigung
		var richtung := Vector3(cos(winkel) * sin(ab), cos(ab), sin(winkel) * sin(ab))
		var naechster := pos + richtung * schritt
		var normale := richtung.cross(quer).normalized()
		var f0 := _ton(pos.y, laenge * 0.8)
		var f1 := _ton(naechster.y, laenge * 0.8)

		# Mittelrippe
		var r0 := groesse * 0.022 * (1.0 - t0 * 0.6)
		var r1 := groesse * 0.022 * (1.0 - t1 * 0.6)
		PropWerkzeug.blatt(st, pos - quer * r0, naechster - quer * r1,
				naechster + quer * r1, pos + quer * r0, normale, f0, f1)

		# Fiederblätter, nach hinten gepfeilt; die Fieder wird zur Spitze
		# hin kürzer, dadurch bekommt der Wedel seine Federform
		var kurve := sin(PI * clampf(t0 * 1.15, 0.0, 1.0))
		var fie0 := groesse * 0.46 * kurve
		var fie1 := groesse * 0.46 * sin(PI * clampf(t1 * 1.15, 0.0, 1.0))
		for seite in [-1.0, 1.0]:
			# leichter Knick nach unten: die Fieder hängen ein wenig
			var senke := Vector3.DOWN * fie0 * 0.3
			PropWerkzeug.blatt(st,
					pos + quer * (r0 * seite),
					naechster + quer * (r1 * seite),
					naechster + quer * ((r1 + fie1 * 0.4) * seite) + senke,
					pos + quer * ((r0 + fie0) * seite) - richtung * schritt * 0.12 + senke,
					normale, f0, f1)
		pos = naechster


# ---------------------------------------------------------------- Pilz

func _baue_pilz() -> void:
	var hutfarbe := _grundfarbe(PILZTOENE)
	var stiele := PropWerkzeug.bauer()
	var huete := PropWerkzeug.bauer()
	# Pilze stehen fast nie allein – kleine Gruppen wirken deutlich besser
	var anzahl := _rng.randi_range(2, 5)

	for i in anzahl:
		var s := groesse * (1.0 if i == 0 else _rng.randf_range(0.32, 0.78))
		var versatz := Vector3.ZERO
		if i > 0:
			var w := _rng.randf() * TAU
			var d := groesse * _rng.randf_range(0.14, 0.42)
			versatz = Vector3(cos(w) * d, 0.0, sin(w) * d)

		var stiel_hoehe := s * _rng.randf_range(0.42, 0.6)
		# Der Stiel steht leicht schief – kein Pilz wächst lotrecht
		var kopf := versatz + Vector3(_rng.randf_range(-0.12, 0.12) * stiel_hoehe,
				stiel_hoehe, _rng.randf_range(-0.12, 0.12) * stiel_hoehe)
		PropWerkzeug.anfuegen(stiele,
				PropWerkzeug.stumpf(s * 0.075, s * 0.055, stiel_hoehe * 1.05, 7, true),
				PropWerkzeug.ausrichten(versatz, kopf))

		# Hut: unregelmäßige, flach gedrückte Kuppel
		var hut_r := s * 0.3 * _rng.randf_range(0.85, 1.25)
		var hut_mitte := kopf + Vector3(0.0, hut_r * 0.1, 0.0)
		var hut_h := hut_r * _rng.randf_range(0.5, 0.8)
		PropWerkzeug.klumpen(huete, _rng, hut_mitte,
				Vector3(hut_r, hut_h, hut_r),
				Vector3(0.0, _rng.randf() * TAU, 0.0), 9, 4, 0.12,
				false, Color(0.6, 0.58, 0.56), Color(1.0, 1.0, 1.0),
				kopf.y, kopf.y + hut_r)
		# Tupfen laufen in den Stiel-Sammler: gleiches helles Material,
		# dadurch bleibt es bei zwei Mesh-Knoten je Pilzgruppe.
		_tupfen(stiele, hut_mitte, hut_r, hut_h)

	_haenge_an("Stiel", stiele, Materialbibliothek.einfarbig(Color(0.92, 0.89, 0.80)))
	# Leicht leuchtend – Pilze sind kleine Wegmarken im dunklen Wald
	_haenge_an("Hut", huete, Materialbibliothek.leuchtend(hutfarbe, 0.22))


## Helle Tupfen auf dem Hut – ein paar flach aufliegende Scheibchen.
func _tupfen(st: SurfaceTool, mitte: Vector3, r: float, h: float) -> void:
	var anzahl := _rng.randi_range(2, 4)
	for i in anzahl:
		var w := _rng.randf() * TAU
		var d := r * _rng.randf_range(0.15, 0.72)
		var y := h * sqrt(maxf(1.0 - pow(d / maxf(r, 0.0001), 2.0), 0.0))
		var punkt := mitte + Vector3(cos(w) * d, y * 0.96, sin(w) * d)
		PropWerkzeug.anfuegen(st,
				PropWerkzeug.kugel(r * _rng.randf_range(0.1, 0.17), 4, 2),
				PropWerkzeug.ort(punkt, Vector3.ZERO, Vector3(1.0, 0.45, 1.0)))


# ---------------------------------------------------------------- Busch

func _baue_busch() -> void:
	var st := PropWerkzeug.bauer()
	var polster := _rng.randi_range(4, 6)
	var hoch := groesse
	var versatz := _rng.randf() * TAU
	for i in polster:
		var winkel := versatz + TAU * 0.618 * float(i) + _rng.randf_range(-0.4, 0.4)
		var weite := groesse * (0.0 if i == 0 else _rng.randf_range(0.16, 0.4))
		var r := groesse * _rng.randf_range(0.2, 0.34)
		var pos := Vector3(cos(winkel) * weite,
				groesse * _rng.randf_range(0.25, 0.72), sin(winkel) * weite)
		PropWerkzeug.klumpen(st, _rng, pos,
				Vector3(r * _rng.randf_range(1.0, 1.4),
						r * _rng.randf_range(0.6, 0.95),
						r * _rng.randf_range(1.0, 1.4)),
				Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf() * TAU,
						_rng.randf_range(-0.3, 0.3)),
				8, 4, 0.24, false, FUSS, KOPF, 0.0, hoch)

	# Einzelne Blätter, die über die Silhouette hinausstehen – erst dadurch
	# liest sich der Busch als Laub und nicht als Knäuel.
	var blaetter := _rng.randi_range(18, 26)
	for i in blaetter:
		var w := _rng.randf() * TAU
		var hoehe := groesse * _rng.randf_range(0.2, 0.95)
		var weite := groesse * _rng.randf_range(0.2, 0.42)
		var wurzel := Vector3(cos(w) * weite * 0.6, hoehe, sin(w) * weite * 0.6)
		var aussen := Vector3(cos(w), _rng.randf_range(-0.25, 0.75), sin(w)).normalized()
		var quer := Vector3(-sin(w), 0.0, cos(w))
		var l := groesse * _rng.randf_range(0.24, 0.42)
		var b := l * _rng.randf_range(0.32, 0.52)
		var spitze := wurzel + aussen * l
		var mitte := wurzel + aussen * l * 0.45
		var n := aussen.cross(quer).normalized()
		var f0 := _ton(wurzel.y, hoch)
		var f1 := _ton(spitze.y, hoch)
		PropWerkzeug.blatt(st, wurzel, mitte - quer * b, spitze, mitte + quer * b,
				n, f0, f1)

	_haenge_an("Laub", st, Materialbibliothek.laub(_grundfarbe(GRUENTOENE)))


# ---------------------------------------------------------------- Blume

func _baue_blume() -> void:
	var bluetenfarbe := _grundfarbe(BLUETENTOENE)
	var stiele := PropWerkzeug.bauer()
	var blueten := PropWerkzeug.bauer()
	var anzahl := _rng.randi_range(3, 4)

	for i in anzahl:
		var h := groesse * _rng.randf_range(0.55, 1.0)
		var versatz := Vector3.ZERO
		if i > 0:
			var w := _rng.randf() * TAU
			var d := groesse * _rng.randf_range(0.08, 0.32)
			versatz = Vector3(cos(w) * d, 0.0, sin(w) * d)
		var kopf := versatz + Vector3(_rng.randf_range(-0.12, 0.12) * h, h,
				_rng.randf_range(-0.12, 0.12) * h)

		PropWerkzeug.anfuegen(stiele,
				PropWerkzeug.stumpf(groesse * 0.03, groesse * 0.022, h * 1.02, 5, false),
				PropWerkzeug.ausrichten(versatz, kopf))

		# Blütenkranz: Mitte plus flache Blätter ringsum
		var r := groesse * _rng.randf_range(0.11, 0.16)
		PropWerkzeug.anfuegen(blueten, PropWerkzeug.kugel(r * 0.66, 5, 2),
				PropWerkzeug.ort(kopf))
		var blaetter := 5
		var dreh := _rng.randf() * TAU
		for b in blaetter:
			var w2 := dreh + TAU * float(b) / float(blaetter) + _rng.randf_range(-0.12, 0.12)
			# Blütenblätter stehen schräg nach oben ab ⇒ Schale statt Pfannkuchen
			var kippe := _rng.randf_range(0.2, 0.45)
			PropWerkzeug.anfuegen(blueten, PropWerkzeug.kugel(r, 5, 2),
					PropWerkzeug.ort(kopf + Vector3(cos(w2) * r * 0.9,
							r * 0.45 * kippe, sin(w2) * r * 0.9),
							Vector3(sin(w2) * kippe, -w2, -cos(w2) * kippe),
							Vector3(1.15, 0.32, 0.72)))

	# Bodenblätter: ohne sie schweben die Stiele über dem Nichts. Sie
	# entstehen als flach gedrückte Primitive im Stiel-Sammler – gleiches
	# Material, also kein zusätzlicher Knoten.
	var boden := _rng.randi_range(3, 5)
	for i in boden:
		var w := _rng.randf() * TAU
		var l := groesse * _rng.randf_range(0.22, 0.38)
		var aussen := Vector3(cos(w), 0.55, sin(w)).normalized()
		var fuss := Vector3(0.0, groesse * 0.03, 0.0)
		PropWerkzeug.anfuegen(stiele, PropWerkzeug.kugel(l * 0.5, 4, 2),
				PropWerkzeug.ort(fuss + aussen * l * 0.55,
						Vector3(0.0, -w, 0.0), Vector3(0.34, 0.16, 1.0)))

	_haenge_an("Stiel", stiele, Materialbibliothek.einfarbig(Color(0.26, 0.46, 0.20)))
	_haenge_an("Bluete", blueten, Materialbibliothek.leuchtend(bluetenfarbe, 0.2))


# ---------------------------------------------------------------- Helfer

## Sammler, die über `klumpen()`/`blatt()` befüllt wurden, brauchen erzeugte
## Tangenten; die reinen Primitivsammler bringen sie schon mit.
func _haenge_an(bezeichnung: String, st: SurfaceTool, material: Material) -> void:
	var eigene := bezeichnung in ["Wedel", "Laub", "Hut"]
	var netz := PropWerkzeug.fertig_mit_tangenten(st) if eigene \
			else PropWerkzeug.fertig(st)
	var mat := PropWerkzeug.mit_scheitelfarben(material) if eigene else material
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung, netz, mat, false)
	if knoten != null:
		_teile.add_child(knoten)


## Der Drehpunkt liegt am Boden – dadurch wippt die Pflanze aus dem Fuß heraus.
func _process(delta: float) -> void:
	_zeit += delta
	_teile.rotation.x = _wind_x * sin(_zeit * 1.4 + _phase)
	_teile.rotation.z = _wind_z * sin(_zeit * 2.1 + _phase * 1.6)
