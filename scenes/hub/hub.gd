extends Node3D
## Portalraum: eine große Halle, um die sich fünf Räume mit je fünf
## Levelportalen legen – ein Raum je Abschnitt (25 Level).
##
## Aufbau (alles prozedural in `_ready()`, die .tscn bleibt schlank):
##   * die Halle ist ein breites Bogenstück, der Spieler startet in ihrer Mitte
##   * darum liegen fünf Raumsektoren, jeder mit Torbogen, Namen und Portalen
##   * Mauern ringsum, damit niemand herausfallen kann
##
## Warum ein Bogen und kein Kreis:
## Die Verfolgerkamera hält einen festen Winkel und steht immer südlich
## (+Z) des Spielers. Läge ein Raum südlich der Halle, liefe der Spieler
## auf die Kamera zu und seine Portale lägen HINTER ihr. Deshalb liegen
## alle fünf Räume nördlich der Halle, aufgereiht auf einem weiten Bogen
## um den Punkt `BOGEN_MITTE`. Jeder Raum wird "ins Bild hinein" betreten,
## und alle Portale schauen dem Spieler entgegen.
##
## Die Außenmauern sind einseitige Flächen, die nur nach innen zeigen. Von
## außen sind sie unsichtbar – so schaut die Kamera auch dann in den Raum,
## wenn sie hinter einer Mauer steht.
##
## WICHTIG: Position immer VOR `add_child()` setzen.

const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const WURZELPROP := preload("res://scenes/props/Wurzel.tscn")

## Mittelpunkt des Bogens. Liegt weit südlich, außerhalb des Raums.
const BOGEN_MITTE := Vector3(0.0, 0.0, 36.0)
const RAUM_WINKEL := 21.0      ## Grad zwischen zwei Raummitten
const SEKTOR_HALB := 10.5      ## halbe Öffnung eines Raums in Grad
const SEITE := 52.5            ## äußerster Winkel (2,5 Räume je Seite)
const HALLE_R := 29.0          ## Südkante der Halle
const UEBERGANG_R := 41.0      ## Grenze Halle / Räume
const AUSSEN_R := 56.0         ## Nordmauer
const TOR_R := 41.6            ## Torbögen
const PORTAL_R := 51.0         ## Portalreihe
const PORTAL_ABSTAND := 3.6    ## seitlicher Abstand zweier Portale in Metern
const START_R := 33.5          ## Startplatz des Spielers

const WAND_HOEHE := 5.6
const KRANZ_HOEHE := 0.5
## Die Trennmauern zwischen den Räumen. Höher als der höchste erreichbare
## Sprung (Slide-Sprung 2,8 m plus Doppelsprung 1,4 m = 4,2 m) – sonst
## steht die Figur oben auf der Mauer statt davor.
const TEILER_HOEHE := 4.6
const TEILER_DICKE := 0.9
const SPERRE_HOEHE := 4.2      ## Gitter vor einem gesperrten Raum

## Ab diesem Abstand zur Kamera ist eine Torbeschriftung voll sichtbar;
## darunter blendet sie aus, damit sie beim Durchlaufen nicht das Bild
## zustellt.
const SCHRIFT_FERN := 19.0
const SCHRIFT_NAH := 11.0

## Rundgang nur für die Bildvorschau (`werkzeuge/foto.sh`): Das Werkzeug
## setzt den Spieler auf diese Kurve und fotografiert mit der Spielkamera.
## Für das Spiel selbst hat die Kurve keine Bedeutung.
var verlauf: Curve3D

var _geometrie: Node3D
var _objekte: Node3D
var _deko: Node3D
var _beschriftungen: Array[Label3D] = []


func _ready() -> void:
	_geometrie = _gruppe("Geometrie")
	_objekte = _gruppe("Objekte")
	_deko = _gruppe("Deko")

	_baue_boden()
	_baue_mauern()

	for i in Spielfluss.RAEUME:
		_baue_raum(i, raumwinkel(i))

	_baue_rundgang()
	_spieler_setzen()
	_wegweiser_setzen()
	# Der Portalraum ist der einzige Ort, an dem gespeichert wird.
	Spielfluss.speichern()
	# Der Portalraum wird über den Ladebildschirm betreten – er steht jetzt.
	Ladeschirm.verbergen()


## Pfeil über dem Spieler, der auf das nächste offene Portal zeigt.
func _wegweiser_setzen() -> void:
	var pfeil := Wegweiser.new()
	pfeil.name = "Wegweiser"
	_objekte.add_child(pfeil)


func _gruppe(bezeichnung: String) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	add_child(knoten)
	return knoten


## Mittelwinkel eines Raums (0-basiert). Raum 3 liegt geradeaus.
static func raumwinkel(index: int) -> float:
	return (float(index) - 2.0) * RAUM_WINKEL


# ------------------------------------------------------------- Hilfsmittel

## Punkt in Bogenkoordinaten: `grad` um `BOGEN_MITTE`, 0° zeigt nach -Z
## (ins Bild hinein), positive Winkel nach rechts.
static func ort(grad: float, radius: float, hoehe := 0.0) -> Vector3:
	var t := deg_to_rad(grad)
	return BOGEN_MITTE + Vector3(sin(t) * radius, hoehe, -cos(t) * radius)


## Platz in einem Raum: `tiefe` = Abstand vom Bogenmittelpunkt,
## `seitlich` = Meter rechts der Raummitte.
static func stelle(grad_mitte: float, tiefe: float, seitlich: float,
		hoehe := 0.0) -> Vector3:
	return ort(grad_mitte + rad_to_deg(seitlich / tiefe), tiefe, hoehe)


## Drehung um Y, sodass die +Z-Achse eines Objekts nach außen zeigt.
static func nach_aussen(grad: float) -> float:
	return PI - deg_to_rad(grad)


func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3) -> void:
	var n := normale.normalized()
	# Godot zeichnet die Vorderseite bei Punkten im Uhrzeigersinn.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tausch := b
		b = c
		c = tausch
	for p in [a, b, c]:
		st.set_normal(n)
		if absf(n.y) > 0.7:
			st.set_uv(Vector2(p.x, p.z) * 0.25)
		else:
			st.set_uv(Vector2(p.x + p.z, -p.y) * 0.25)
		st.add_vertex(p)


func _viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normale: Vector3) -> void:
	_dreieck(st, a, b, c, normale)
	_dreieck(st, b, d, c, normale)


## Waagerechtes Bogenstück als Boden.
func _bogenflaeche(st: SurfaceTool, r_innen: float, r_aussen: float,
		von: float, bis: float, hoehe: float, schritte: int) -> void:
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		_viereck(st, ort(g0, r_innen, hoehe), ort(g0, r_aussen, hoehe),
				ort(g1, r_innen, hoehe), ort(g1, r_aussen, hoehe), Vector3.UP)


func _flaeche_anhaengen(elternteil: Node3D, st: SurfaceTool, material: Material,
		bezeichnung: String, schatten := true) -> MeshInstance3D:
	st.index()
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = mesh
	mi.material_override = material
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(mi)
	return mi


## Instanziiert ein Prop, setzt seine Werte und hängt es ein.
## Position wird vor `add_child()` gesetzt – sonst springen Props zurück.
func _prop(szene: PackedScene, pos: Vector3, werte: Dictionary = {},
		drehung := 0.0) -> Node3D:
	var knoten := szene.instantiate() as Node3D
	for schluessel in werte:
		knoten.set(schluessel, werte[schluessel])
	knoten.position = pos
	knoten.rotation.y = drehung
	_deko.add_child(knoten)
	return knoten


func _quader(elternteil: Node3D, pos: Vector3, groesse: Vector3,
		material: Material, drehung := 0.0, schatten := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = groesse
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation.y = drehung
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(mi)
	return mi


# --------------------------------------------------------------- Grundriss

## Böden: ein Bogenstück für die Halle, je eines für die fünf Räume.
## Die Kollision übernimmt ein einziger flacher Kasten unter allem – das
## ist deutlich billiger als eine Trimesh-Kollision je Fläche.
func _baue_boden() -> void:
	var koerper := StaticBody3D.new()
	koerper.name = "Boden"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	koerper.position = Vector3(0.0, -0.75, BOGEN_MITTE.z - AUSSEN_R * 0.5)
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(AUSSEN_R * 2.0, 1.5, AUSSEN_R + 4.0)
	form.shape = box
	koerper.add_child(form)
	_geometrie.add_child(koerper)

	# Sockel: ragt unter den Mauern hervor. Die Kamera steht beim Laufen
	# oft außerhalb der Mauern – ohne diesen Rand sähe sie dort ins Leere.
	var sockel := SurfaceTool.new()
	sockel.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bogenflaeche(sockel, HALLE_R - 7.0, AUSSEN_R + 3.5, -SEITE - 6.0,
			SEITE + 6.0, -0.09, 22)
	_flaeche_anhaengen(_geometrie, sockel,
			Materialbibliothek.fels(), "Sockel", false)

	var halle := SurfaceTool.new()
	halle.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bogenflaeche(halle, HALLE_R, UEBERGANG_R + 0.6, -SEITE, SEITE, 0.03, 30)
	_flaeche_anhaengen(_geometrie, halle, Materialbibliothek.waldweg(), "Hallenboden")

	# Leuchtender Ring markiert den Startplatz. Eine gefüllte Scheibe wäre
	# eine große, tote Fläche mitten im Bild – der Ring reicht.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.6
	torus.outer_radius = 3.82
	torus.rings = 24
	torus.ring_segments = 5
	ring.mesh = torus
	ring.material_override = Materialbibliothek.leuchtend(Farben.PORTAL_START, 1.4)
	ring.position = ort(0.0, START_R, 0.09)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_geometrie.add_child(ring)


## Alle Mauern in einem Netz: Nordbogen, Südbogen und die beiden
## Seitenmauern. Die Flächen zeigen nur nach innen.
func _baue_mauern() -> void:
	var wand := SurfaceTool.new()
	wand.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kranz := SurfaceTool.new()
	kranz.begin(Mesh.PRIMITIVE_TRIANGLES)
	var koerper := StaticBody3D.new()
	koerper.name = "Mauerkollision"
	koerper.collision_layer = 1
	koerper.collision_mask = 0

	# Nordmauer (Bogen, Blick nach innen = zur Bogenmitte)
	_bogenmauer(wand, kranz, koerper, AUSSEN_R, -SEITE, SEITE, 26, true)
	# Südmauer hinter dem Startplatz
	_bogenmauer(wand, kranz, koerper, HALLE_R, -SEITE, SEITE, 16, false)
	# Seitenmauern
	for vorzeichen in [-1.0, 1.0]:
		var g: float = SEITE * float(vorzeichen)
		var t := deg_to_rad(g)
		var innen := Vector3(cos(t), 0.0, sin(t)) * -float(vorzeichen)
		_gerade_mauer(wand, kranz, koerper, ort(g, HALLE_R), ort(g, AUSSEN_R), innen)

	_flaeche_anhaengen(_geometrie, wand, Materialbibliothek.fels(),
			"Aussenmauer", false)
	_flaeche_anhaengen(_geometrie, kranz,
			Materialbibliothek.einfarbig(Farben.FELS_WARM, 0.85), "Mauerkranz", false)
	_geometrie.add_child(koerper)


func _bogenmauer(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		radius: float, von: float, bis: float, schritte: int,
		zur_mitte: bool) -> void:
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		var p0 := ort(g0, radius)
		var p1 := ort(g1, radius)
		var radial := (p0 + p1) * 0.5 - BOGEN_MITTE
		radial.y = 0.0
		var innen := -radial.normalized() if zur_mitte else radial.normalized()
		_mauerstueck(wand, kranz, koerper, p0, p1, innen)


func _gerade_mauer(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		von: Vector3, bis: Vector3, innen: Vector3) -> void:
	var schritte := maxi(int(von.distance_to(bis) / 6.0), 1)
	for i in schritte:
		var p0 := von.lerp(bis, float(i) / float(schritte))
		var p1 := von.lerp(bis, float(i + 1) / float(schritte))
		_mauerstueck(wand, kranz, koerper, p0, p1, innen)


## Ein Mauerabschnitt: Fläche nach innen, heller Kranz obenauf, Kollision.
func _mauerstueck(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		p0: Vector3, p1: Vector3, innen: Vector3) -> void:
	var unten := WAND_HOEHE - KRANZ_HOEHE
	_viereck(wand, p0, p0 + Vector3.UP * unten, p1, p1 + Vector3.UP * unten, innen)
	_viereck(kranz, p0 + Vector3.UP * unten, p0 + Vector3.UP * WAND_HOEHE,
			p1 + Vector3.UP * unten, p1 + Vector3.UP * WAND_HOEHE, innen)

	var mitte := (p0 + p1) * 0.5
	var laenge := p0.distance_to(p1)
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(laenge + 0.4, WAND_HOEHE + 2.0, 1.2)
	form.shape = box
	form.position = mitte - innen * 0.6 + Vector3.UP * WAND_HOEHE * 0.5
	form.rotation.y = atan2(-innen.x, -innen.z)
	koerper.add_child(form)


# ------------------------------------------------------------------- Räume

func _baue_raum(index: int, grad: float) -> void:
	var raum := Node3D.new()
	raum.name = "Raum%d" % (index + 1)
	_objekte.add_child(raum)

	var boden := SurfaceTool.new()
	boden.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bogenflaeche(boden, UEBERGANG_R, AUSSEN_R,
			grad - SEKTOR_HALB, grad + SEKTOR_HALB, 0.0, 8)
	_flaeche_anhaengen(_geometrie, boden, _bodenmaterial(index),
			"Raumboden%d" % (index + 1))

	# Trennmauer zum rechten Nachbarn (die linke gehört zum Nachbarn)
	if index < Spielfluss.RAEUME - 1:
		_baue_trennmauer(grad + SEKTOR_HALB)

	_baue_torbogen(index, grad)
	if not Spielfluss.raum_offen(index + 1):
		_baue_sperre(index, grad)

	var nummern := Spielfluss.level_im_raum(index + 1)
	for i in nummern.size():
		var seitlich := (float(i) - 2.0) * PORTAL_ABSTAND
		var winkel := grad + rad_to_deg(seitlich / PORTAL_R)
		var portal := Levelportal.new()
		portal.nummer = nummern[i]
		portal.name = "Portal%02d" % nummern[i]
		portal.position = ort(winkel, PORTAL_R)
		portal.rotation.y = -deg_to_rad(winkel)
		raum.add_child(portal)

	match index:
		0:
			_deko_wurzelwald(grad)
		1:
			_deko_nebelsuempfe(grad)
		2:
			_deko_felsenschlucht(grad)
		3:
			_deko_frostkronen(grad)
		_:
			_deko_glutkessel(grad)


## Gitter vor einem noch gesperrten Raum.
##
## Die Portale dahinter sind ohnehin dunkel, aber ein Raum, den man
## betreten kann und in dem dann nichts geht, liest sich wie ein Fehler.
## Das Gitter sagt vorher, woran es liegt: Erst den Raum davor abschließen.
##
## Im Debugmodus wird es gar nicht erst gebaut – dort ist alles offen.
func _baue_sperre(index: int, grad: float) -> void:
	var sperre := Node3D.new()
	sperre.name = "Sperre%d" % (index + 1)
	_objekte.add_child(sperre)

	var eisen := Materialbibliothek.metall(Farben.KISTE_EISEN.darkened(0.45))
	var warnton := Materialbibliothek.leuchtend(Farben.WARNUNG, 1.1)
	var koerper := StaticBody3D.new()
	koerper.name = "Riegel"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	sperre.add_child(koerper)

	# Senkrechte Stäbe über die ganze Raumbreite
	var staebe := 13
	for i in staebe:
		var t := float(i) / float(staebe - 1)
		var winkel := lerpf(grad - SEKTOR_HALB + 0.4, grad + SEKTOR_HALB - 0.4, t)
		_quader(sperre, ort(winkel, TOR_R, SPERRE_HOEHE * 0.5),
				Vector3(0.16, SPERRE_HOEHE, 0.16), eisen, nach_aussen(winkel), false)
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		# Die Kästen greifen ineinander, sonst schlüpft man zwischen zwei
		# Stäben hindurch – der Spieler ist schmaler als der Stababstand.
		kasten.size = Vector3(1.4, SPERRE_HOEHE, 0.7)
		form.shape = kasten
		form.position = ort(winkel, TOR_R, SPERRE_HOEHE * 0.5)
		form.rotation.y = nach_aussen(winkel)
		koerper.add_child(form)

	# Zwei Querriegel und ein Warnband oben
	for hoehe: float in [SPERRE_HOEHE * 0.32, SPERRE_HOEHE * 0.78]:
		_bogenriegel(sperre, grad, hoehe, 0.18, eisen)
	_bogenriegel(sperre, grad, SPERRE_HOEHE - 0.12, 0.1, warnton)

	# Schild mit dem Grund
	# Der Schriftzug muss in den Sektor passen. Bei 96 pt und 0,012 m je
	# Pixel war er rund 15 m breit – so breit wie der ganze Raum – und
	# ragte beidseitig über die Trennmauern in die Nachbarräume.
	# Jetzt: kleiner, mit fester Breite und Wortumbruch.
	var schild := Label3D.new()
	schild.text = "Erst %s abschließen" % Spielfluss.RAUM_NAMEN[maxi(index - 1, 0)]
	schild.font_size = 64
	schild.pixel_size = 0.010
	# Nutzbare Sehnenbreite des Sektors, abzüglich Rand
	schild.width = (2.0 * TOR_R * sin(deg_to_rad(SEKTOR_HALB)) - 2.0) / schild.pixel_size
	schild.autowrap_mode = TextServer.AUTOWRAP_WORD
	schild.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	schild.modulate = Farben.WARNUNG.lightened(0.35)
	schild.outline_size = 18
	schild.outline_modulate = Color(0.05, 0.03, 0.02, 0.9)
	schild.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	schild.double_sided = false
	schild.no_depth_test = false
	schild.position = ort(grad, TOR_R - 0.35, SPERRE_HOEHE * 0.56)
	sperre.add_child(schild)
	schild.rotation.y = nach_aussen(grad) + PI


## Ein waagerechter Riegel, der dem Bogen des Raums folgt.
func _bogenriegel(elternteil: Node3D, grad: float, hoehe: float,
		dicke: float, stoff: Material) -> void:
	var stuecke := 10
	for i in stuecke:
		var a := lerpf(grad - SEKTOR_HALB, grad + SEKTOR_HALB,
				(float(i) + 0.5) / float(stuecke))
		var breite := deg_to_rad(SEKTOR_HALB * 2.0) * TOR_R / float(stuecke) + 0.06
		_quader(elternteil, ort(a, TOR_R, hoehe),
				Vector3(breite, dicke, dicke), stoff, nach_aussen(a), false)


func _baue_trennmauer(grad: float) -> void:
	var von := UEBERGANG_R - 1.0
	var bis := AUSSEN_R
	var mitte := (von + bis) * 0.5
	LevelWerkzeuge.plattform(_geometrie, ort(grad, mitte, TEILER_HOEHE * 0.5),
			Vector3(TEILER_DICKE, TEILER_HOEHE, bis - von),
			Materialbibliothek.fels(), nach_aussen(grad))
	_quader(_geometrie, ort(grad, mitte, TEILER_HOEHE + 0.09),
			Vector3(TEILER_DICKE + 0.2, 0.18, bis - von),
			Materialbibliothek.einfarbig(Farben.FELS_WARM, 0.85),
			nach_aussen(grad), false)


func _bodenmaterial(index: int) -> Material:
	match index:
		0:
			return Materialbibliothek.gras()
		1:
			return Materialbibliothek.waldboden()
		2:
			return Materialbibliothek.fels()
		3:
			return Materialbibliothek.einfarbig(
					Farben.KIES_HELL.lerp(Farben.WASSER_HELL, 0.3), 0.4)
		_:
			return Materialbibliothek.einfarbig(
					Farben.FELS_DUNKEL.lerp(Farben.ROST, 0.25), 0.9)


## Akzentfarbe eines Raums – Torbogen, Kappen und Deko greifen sie auf.
func _akzent(index: int) -> Color:
	match index:
		0:
			return Farben.LAUB_HELL
		1:
			return Farben.WASSER_HELL
		2:
			return Farben.FELS_WARM
		3:
			return Color(0.72, 0.90, 1.0)
		_:
			return Farben.FRUCHT


## Torbogen am Eingang eines Raums, darüber Name und Fortschritt.
func _baue_torbogen(index: int, grad: float) -> void:
	var stein := Materialbibliothek.fels()
	var hoehe := 6.2
	var breite := 2.0 * (TOR_R * deg_to_rad(SEKTOR_HALB) - 1.0)
	var drehung := nach_aussen(grad)

	# Kein durchgehender Sturz: Die Kamera steht beim Durchlaufen genau
	# hinter dem Tor, ein Querbalken läge dann quer über der Bildmitte.
	# Stattdessen zwei Pfeiler mit kurzen Kragsteinen, die Mitte bleibt frei.
	for vorzeichen in [-1.0, 1.0]:
		var seite: float = float(vorzeichen) * breite * 0.5
		var pfeiler := LevelWerkzeuge.plattform(_geometrie,
				stelle(grad, TOR_R, seite, hoehe * 0.5),
				Vector3(1.0, hoehe, 1.0), stein, drehung)
		pfeiler.name = "Torpfeiler"
		_quader(_geometrie, stelle(grad, TOR_R, seite - vorzeichen * 0.9,
				hoehe + 0.28), Vector3(2.8, 0.56, 1.0), stein, drehung)
		_quader(_geometrie, stelle(grad, TOR_R, seite, hoehe + 0.66),
				Vector3(1.12, 0.2, 1.12),
				Materialbibliothek.leuchtend(
						_akzent(index).lerp(Farben.FELS_HELL, 0.55), 0.25),
				drehung, false)

	for vorzeichen in [-1.0, 1.0]:
		var fuss: float = float(vorzeichen) * (breite * 0.5 - 1.2)
		_prop(STEIN, stelle(grad, TOR_R - 1.4, fuss), {
			"groesse": 0.85, "brocken": 2, "bemoost": index == 0,
			"saat": 101 + index * 2 + int(vorzeichen)})

	# Höhe und Größe sind knapp bemessen: Die Verfolgerkamera steht 6,4 m
	# über dem Spieler und schaut 31 Grad nach unten, ihr oberer Bildrand
	# liegt damit fast waagerecht. Mit den früheren 96 pt auf 6,2 m Höhe
	# ragte der Schriftzug oben aus dem Bild und war halb abgeschnitten.
	var beschriftung := Label3D.new()
	beschriftung.text = Spielfluss.RAUM_NAMEN[index]
	beschriftung.font_size = 76
	beschriftung.outline_size = 18
	beschriftung.pixel_size = 0.0095
	beschriftung.double_sided = false
	beschriftung.modulate = _akzent(index).lightened(0.35)
	beschriftung.outline_modulate = Color(0.05, 0.04, 0.03, 0.92)
	beschriftung.position = ort(grad, TOR_R, 5.95)
	beschriftung.rotation.y = -deg_to_rad(grad)
	_geometrie.add_child(beschriftung)
	_beschriftungen.append(beschriftung)

	var geschafft := 0
	for nummer in Spielfluss.level_im_raum(index + 1):
		if Spielfluss.geschafft.has(nummer):
			geschafft += 1
	var stand := Label3D.new()
	stand.text = "%d / %d geschafft" % [geschafft, Spielfluss.LEVEL_JE_RAUM]
	stand.font_size = 48
	stand.outline_size = 12
	stand.pixel_size = 0.011
	stand.double_sided = false
	stand.modulate = Color(0.95, 0.93, 0.86)
	stand.outline_modulate = Color(0.05, 0.04, 0.03, 0.92)
	stand.position = ort(grad, TOR_R, 5.15)
	stand.rotation.y = -deg_to_rad(grad)
	_geometrie.add_child(stand)
	_beschriftungen.append(stand)


## Die Torbeschriftungen blenden aus, wenn die Kamera dicht davor steht –
## sonst legt sich der Schriftzug beim Durchlaufen über das halbe Bild.
func _process(_delta: float) -> void:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var kamera_ort := kamera.global_position
	for schild in _beschriftungen:
		if not is_instance_valid(schild):
			continue
		var abstand := schild.global_position.distance_to(kamera_ort)
		var sicht := clampf(
				(abstand - SCHRIFT_NAH) / (SCHRIFT_FERN - SCHRIFT_NAH), 0.0, 1.0)
		schild.modulate.a = sicht
		# Der Umriss hat seine eigene Deckkraft – sonst bliebe ein schwarzer
		# Schattenriss stehen, während die Schrift schon weg ist.
		schild.outline_modulate.a = sicht * 0.92


# -------------------------------------------------------------- Ausstattung

func _deko_wurzelwald(grad: float) -> void:
	_prop(BAUM, stelle(grad, 54.0, -8.2), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 7.6, "saat": 11,
		"laubfarbe": Farben.LAUB, "staerke": 1.1})
	_prop(BAUM, stelle(grad, 54.5, 8.4), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 6.9, "saat": 12,
		"laubfarbe": Farben.LAUB_HELL})
	# Vorne links steht bewusst kein Baum: Der Wurzelwald liegt ganz außen,
	# die Kamera schaut schräg hinein – eine Krone an dieser Stelle würde
	# genau das offene Tor 01 verdecken.
	_prop(KLEINZEUG, stelle(grad, 44.8, -7.4),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 1.1, "saat": 13})
	_prop(BAUM, stelle(grad, 45.2, 8.0), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 7.1, "saat": 14})

	_prop(WURZELPROP, stelle(grad, 45.5, -2.4),
			{"spannweite": 4.2, "hoehe": 1.0, "saat": 21}, deg_to_rad(grad + 70.0))
	_prop(WURZELPROP, stelle(grad, 46.5, 2.8),
			{"spannweite": 3.6, "hoehe": 0.9, "saat": 22}, deg_to_rad(grad - 50.0))

	for i in 2:
		_prop(GRASFELD, stelle(grad, 47.5 + float(i) * 1.5, -3.5 + float(i) * 7.0), {
			"flaeche": Vector2(6.5, 6.5), "anzahl": 55, "mindestdichte": 1.0,
			"hoechstzahl": 60, "saat": 30 + i})
	_prop(KLEINZEUG, stelle(grad, 43.5, 3.6),
			{"art": Kleinzeug.Art.FARN, "groesse": 0.9, "saat": 41})
	_prop(KLEINZEUG, stelle(grad, 44.0, -4.2),
			{"art": Kleinzeug.Art.FARN, "groesse": 0.8, "saat": 42})
	_prop(KLEINZEUG, stelle(grad, 48.5, 5.5),
			{"art": Kleinzeug.Art.PILZ, "groesse": 0.7, "saat": 43})


func _deko_nebelsuempfe(grad: float) -> void:
	_prop(BAUM, stelle(grad, 54.0, -7.8), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 6.4, "saat": 51, "staerke": 1.2})
	_prop(BAUM, stelle(grad, 54.5, 7.6), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 5.8, "saat": 52, "staerke": 1.1})
	_prop(BAUM, stelle(grad, 44.8, 7.9), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 5.2, "saat": 53})
	_prop(BAUM, stelle(grad, 45.2, -8.0), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 6.0, "saat": 54, "staerke": 1.3})

	# Stille, dunkle Tümpel
	var wasser := Materialbibliothek.einfarbig(
			Farben.WASSER.lerp(Farben.FELS_DUNKEL, 0.62), 0.22)
	var schlamm := Materialbibliothek.einfarbig(
			Farben.ERDE_DUNKEL.lerp(Farben.MOOS, 0.3), 0.95)
	for eintrag in [[45.0, -2.2, 2.6], [48.0, 4.4, 2.0], [54.5, -1.5, 2.4]]:
		var e: Array = eintrag
		for rand in [true, false]:
			var scheibe := CylinderMesh.new()
			scheibe.top_radius = float(e[2]) + (0.55 if rand else 0.0)
			scheibe.bottom_radius = scheibe.top_radius
			scheibe.height = 0.08
			scheibe.radial_segments = 16
			scheibe.rings = 0
			var tuempel := MeshInstance3D.new()
			tuempel.mesh = scheibe
			tuempel.material_override = schlamm if rand else wasser
			tuempel.position = stelle(grad, float(e[0]), float(e[1]),
					0.015 if rand else 0.03)
			tuempel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_deko.add_child(tuempel)

	for i in 4:
		_prop(KLEINZEUG, stelle(grad, 43.5 + float(i) * 2.2, -6.0 + float(i) * 3.6),
				{"art": Kleinzeug.Art.PILZ, "groesse": 0.75, "saat": 61 + i})
	_prop(KLEINZEUG, stelle(grad, 49.0, 7.0),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 1.0, "saat": 66})


func _deko_felsenschlucht(grad: float) -> void:
	var brocken := [
		[54.5, -8.0, 2.8], [54.0, 8.2, 2.4], [44.5, -6.6, 2.0],
		[45.0, 6.8, 2.2], [48.0, -3.2, 1.2], [47.0, 3.4, 1.4],
	]
	for i in brocken.size():
		var b: Array = brocken[i]
		_prop(STEIN, stelle(grad, float(b[0]), float(b[1])), {
			"groesse": float(b[2]), "brocken": 3, "bemoost": false,
			"saat": 71 + i, "zerklueftung": 0.4})

	# Zwei schlanke Felsnadeln rahmen die Portalreihe
	for vorzeichen in [-1.0, 1.0]:
		var seite: float = float(vorzeichen) * 8.6
		var nadel := MeshInstance3D.new()
		var kegel := CylinderMesh.new()
		kegel.top_radius = 0.25
		kegel.bottom_radius = 1.1
		kegel.height = 5.4
		kegel.radial_segments = 7
		kegel.rings = 1
		nadel.mesh = kegel
		nadel.material_override = Materialbibliothek.fels()
		nadel.position = stelle(grad, 54.8, seite, 2.7)
		_deko.add_child(nadel)
	_prop(KLEINZEUG, stelle(grad, 43.5, 1.5),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 0.8, "saat": 78})


func _deko_frostkronen(grad: float) -> void:
	var frost := Color(0.62, 0.82, 0.86)
	_prop(BAUM, stelle(grad, 54.5, -8.2), {
		"art": Baum.Art.NADELBAUM, "hoehe": 8.0, "saat": 81, "laubfarbe": frost})
	_prop(BAUM, stelle(grad, 54.0, 8.0), {
		"art": Baum.Art.NADELBAUM, "hoehe": 7.2, "saat": 82, "laubfarbe": frost})
	_prop(BAUM, stelle(grad, 44.8, -7.9), {
		"art": Baum.Art.NADELBAUM, "hoehe": 6.6, "saat": 83, "laubfarbe": frost})
	_prop(BAUM, stelle(grad, 45.2, 8.0), {
		"art": Baum.Art.NADELBAUM, "hoehe": 7.0, "saat": 84, "laubfarbe": frost})

	var eis := Materialbibliothek.einfarbig(Color(0.78, 0.92, 1.0), 0.2)
	var stellen := [[47.0, -3.0, 1.6], [48.5, 3.2, 2.1], [53.0, 5.6, 1.4],
			[52.5, -5.4, 1.8], [43.8, 1.2, 1.2]]
	for i in stellen.size():
		var e: Array = stellen[i]
		var kristall := MeshInstance3D.new()
		var kegel := CylinderMesh.new()
		kegel.top_radius = 0.0
		kegel.bottom_radius = 0.42
		kegel.height = float(e[2])
		kegel.radial_segments = 6
		kegel.rings = 1
		kristall.mesh = kegel
		kristall.material_override = eis
		kristall.position = stelle(grad, float(e[0]), float(e[1]), float(e[2]) * 0.5)
		kristall.rotation = Vector3(deg_to_rad(6.0), float(i) * 1.1, deg_to_rad(4.0))
		_deko.add_child(kristall)


func _deko_glutkessel(grad: float) -> void:
	var brocken := [[54.5, -8.0, 2.4], [54.0, 8.0, 2.1], [44.5, -6.4, 1.8],
			[45.0, 6.6, 2.0], [49.5, -8.4, 1.5], [50.5, 8.6, 1.3]]
	for i in brocken.size():
		var b: Array = brocken[i]
		_prop(STEIN, stelle(grad, float(b[0]), float(b[1])), {
			"groesse": float(b[2]), "brocken": 3, "bemoost": false,
			"saat": 91 + i, "zerklueftung": 0.44})

	# Glühende Risse im Basalt
	var glut := Materialbibliothek.leuchtend(
			Farben.FRUCHT.lerp(Farben.WARNUNG, 0.45), 1.1)
	var risse := [[45.0, -4.5, 5.0, 30.0], [47.5, -1.0, 6.5, -20.0],
			[46.0, 3.5, 4.5, 55.0], [50.0, 6.5, 5.5, 10.0],
			[54.0, 0.0, 7.0, 80.0], [52.5, -6.0, 4.0, -60.0]]
	# Jeder Riss besteht aus drei versetzten Stücken – ein einzelner langer
	# Balken sähe aus wie ein Brett, erst der Knick macht daraus einen Riss.
	for i in risse.size():
		var r: Array = risse[i]
		var laenge := float(r[2]) / 3.0
		var richtung := deg_to_rad(grad + float(r[3]))
		var quer := Vector3(cos(richtung), 0.0, sin(richtung))
		var laengs := Vector3(sin(richtung), 0.0, -cos(richtung))
		var start := stelle(grad, float(r[0]), float(r[1]), 0.03)
		for k in 3:
			var knick := (float((k + i) % 3) - 1.0) * 0.28
			_quader(_deko, start + laengs * (float(k) - 1.0) * laenge
					+ quer * knick,
					Vector3(0.16 + 0.06 * float(k % 2), 0.03, laenge * 0.94),
					glut, richtung + knick * 0.5, false)

	for vorzeichen in [-1.0, 1.0]:
		var licht := OmniLight3D.new()
		licht.light_color = Farben.FRUCHT
		licht.light_energy = 2.0
		licht.omni_range = 16.0
		licht.shadow_enabled = false
		licht.position = stelle(grad, 48.0, float(vorzeichen) * 5.0, 1.8)
		_deko.add_child(licht)


# ------------------------------------------------------------------ Spieler

## Weg für die Bildvorschau: von der Halle in jeden Raum und zurück.
func _baue_rundgang() -> void:
	var punkte: Array[Vector3] = [ort(0.0, START_R, 0.9)]
	for i in Spielfluss.RAEUME:
		var grad := raumwinkel(i)
		punkte.append(ort(grad, START_R, 0.9))
		punkte.append(ort(grad, PORTAL_R - 2.5, 0.9))
		punkte.append(ort(grad, START_R, 0.9))
	verlauf = LevelWerkzeuge.kurve_aus_punkten(punkte, 0.0)


func _spieler_setzen() -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return
	spieler.global_position = ort(0.0, START_R, 0.9)
	if spieler.has_method("setze_blickrichtung"):
		spieler.call("setze_blickrichtung", 0.0)
	GameState.level_starten(spieler.global_position)
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")
