extends Node3D
class_name Horizont
## Ferne Hügelkette als Abschluss der Welt.
##
## Gebaut, weil zwei Level ohne Schluchtwände auskommen (das Katzenrennen
## und das Kartrennen) und dort auffiel, dass die Welt einfach aufhört:
## Die untere Hälfte des Himmel-Shaders liegt als einfarbige Fläche bis an
## einen kerzengeraden Horizont auf Augenhöhe. Kein Nebel der Welt kaschiert
## eine gerade Linie – dagegen hilft nur Silhouette.
##
## Der Ring besteht aus zwei Lagen: eine nahe, dunklere und eine ferne,
## hellere. Erst dadurch entsteht Tiefe; eine einzelne Lage sieht aus wie
## eine bemalte Wand. Beide Lagen sind unbeleuchtet und werfen keinen
## Schatten – sie sollen von der Beleuchtung des Levels unabhängig bleiben
## und mit dem Nebel verschmelzen, nicht mit ihm kämpfen.
##
## Keine Kollision, kein Physikkörper. Reine Kulisse.

## Abstand der nahen Hügelkette vom Mittelpunkt.
@export var radius := 150.0:
	set(wert):
		radius = wert
		if is_inside_tree():
			_aufbauen()

## Höhe der höchsten Erhebung der nahen Kette.
@export var hoehe := 22.0

## Wie viele Zacken die nahe Kette hat. Wenige wirken wie Berge, viele wie
## ein Sägeblatt – zwischen 30 und 60 sieht es nach Landschaft aus.
@export_range(8, 120, 1) var zacken := 44

## Farben der beiden Lagen. Sie sollten dicht an der Nebelfarbe des Levels
## liegen: Ein Horizont, der sich vom Dunst abhebt, zieht den Blick auf
## sich, obwohl er nur Abschluss sein soll.
@export var farbe_nah := Color(0.34, 0.38, 0.34)
@export var farbe_fern := Color(0.52, 0.57, 0.55)

## Zusätzlich eine große Bodenscheibe unter dem Ring. Nötig überall dort,
## wo das Level selbst keinen Untergrund mitbringt.
@export var boden := true
@export var boden_farbe := Color(0.30, 0.36, 0.24)

## Wie tief die Ketten unter der Nulllinie beginnen. Etwas unter dem Boden
## anzusetzen verhindert einen Spalt, wenn der Weg leicht ansteigt.
@export var fuss := -6.0

## Feste Saat, damit die Kette bei jedem Start gleich aussieht.
@export var saat := 4711

## Bewaldete Kuppen statt kahler Zacken: Jede Zacke bekommt eine runde
## Oberkante, jede siebte eine Spitze wie ein Nadelbaum, und die Höhen
## schwanken weniger. Aus der Ferne liest sich das als Waldsaum über
## Hügeln. Aus lässt die Kette, wie sie war.
@export var kronen := false

## Nur die nahe Kette. Die ferne steht beim 1,45-fachen Radius und damit
## schnell hinter der Sichtweite der Kamera – dort kostet sie nur Dreiecke.
@export var nur_nah := false

## Die ferne Kette steht so viel weiter draußen und ist so viel höher.
const FERN_FAKTOR := 1.45
const FERN_HOEHE := 0.72
## Die Bodenscheibe reicht über die ferne Kette hinaus, damit sie deren
## Fuß verdeckt.
const BODEN_FAKTOR := 1.85


func _ready() -> void:
	_aufbauen()


func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	if boden:
		_scheibe()
	# Erst fern, dann nah: Die nahe Kette soll die ferne überdecken.
	if not nur_nah:
		_kette(radius * FERN_FAKTOR, hoehe * FERN_HOEHE, farbe_fern,
				zacken, saat + 17)
	_kette(radius, hoehe, farbe_nah, zacken, saat)


## Eine Zackenkette als geschlossener Ring.
##
## Gebaut aus je einem Viereck vom Fuß bis zur Kammlinie – die Kammhöhe
## schwankt, die Vierecke stoßen aneinander. Das ergibt eine durchgehende
## Silhouette ohne Lücken, und zwar mit zwei Dreiecken je Zacke statt mit
## einem ganzen Berggitter.
func _kette(r: float, h: float, farbe: Color, anzahl: int, eigene_saat: int) -> void:
	var rng := PropWerkzeug.zufall(eigene_saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Kammhöhen vorab ziehen, damit die letzte Zacke wieder zur ersten passt
	# und der Ring keine sichtbare Naht bekommt.
	var hoehen: Array[float] = []
	for i in anzahl:
		hoehen.append(h * (rng.randf_range(0.62, 1.0) if kronen
				else rng.randf_range(0.28, 1.0)))
	hoehen[anzahl - 1] = hoehen[0]

	for i in anzahl:
		var w0 := TAU * float(i) / float(anzahl)
		var w1 := TAU * float(i + 1) / float(anzahl)
		var h0: float = hoehen[i]
		var h1: float = hoehen[(i + 1) % anzahl]
		if kronen:
			_kuppe(st, r, w0, w1, h0, h1, i % 7 == 3)
			continue
		var a := Vector3(cos(w0) * r, fuss, sin(w0) * r)
		var b := Vector3(cos(w1) * r, fuss, sin(w1) * r)
		var c := Vector3(cos(w1) * r, h1, sin(w1) * r)
		var d := Vector3(cos(w0) * r, h0, sin(w0) * r)
		# Normale nach innen, zur Mitte hin – dorthin schaut die Kamera.
		var n := -Vector3(cos((w0 + w1) * 0.5), 0.0, sin((w0 + w1) * 0.5))
		PropWerkzeug.viereck(st, a, b, c, d, n)

	var netz := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Kette_%d" % int(r)
	mi.mesh = netz
	mi.material_override = _kulissenstoff(farbe)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Eine Zacke als Baumkrone: fünf Streifen, deren Oberkante einer Kuppe
## folgt (oder spitz zuläuft). Zwischen zwei Kuppen bleibt eine Kerbe –
## erst die Kerben machen aus der Linie einzelne Bäume.
func _kuppe(st: SurfaceTool, r: float, w0: float, w1: float, h0: float,
		h1: float, spitz: bool) -> void:
	const STREIFEN := 5
	for k in STREIFEN:
		var t0 := float(k) / float(STREIFEN)
		var t1 := float(k + 1) / float(STREIFEN)
		var wa := lerpf(w0, w1, t0)
		var wb := lerpf(w0, w1, t1)
		var ha := lerpf(h0, h1, t0) * _kronenprofil(t0, spitz)
		var hb := lerpf(h0, h1, t1) * _kronenprofil(t1, spitz)
		var a := Vector3(cos(wa) * r, fuss, sin(wa) * r)
		var b := Vector3(cos(wb) * r, fuss, sin(wb) * r)
		var c := Vector3(cos(wb) * r, hb, sin(wb) * r)
		var d := Vector3(cos(wa) * r, ha, sin(wa) * r)
		var n := -Vector3(cos((wa + wb) * 0.5), 0.0, sin((wa + wb) * 0.5))
		PropWerkzeug.viereck(st, a, b, c, d, n)


## Höhenanteil über eine Zacke: runde Kuppe, oder Spitze mit steilen Flanken.
func _kronenprofil(t: float, spitz: bool) -> float:
	if spitz:
		return lerpf(0.8, 1.22, 1.0 - absf(t * 2.0 - 1.0))
	return 0.84 + 0.16 * sin(PI * t)


## Bodenscheibe, die unter der Kette bis über den Ring hinausreicht.
func _scheibe() -> void:
	var kreis := CylinderMesh.new()
	kreis.top_radius = radius * BODEN_FAKTOR
	kreis.bottom_radius = radius * BODEN_FAKTOR
	kreis.height = 0.4
	kreis.radial_segments = 32
	kreis.rings = 0
	var mi := MeshInstance3D.new()
	mi.name = "Fernboden"
	mi.mesh = kreis
	mi.material_override = _kulissenstoff(boden_farbe)
	mi.position.y = fuss - 0.2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Unbeleuchtetes Material. Kulisse in dieser Entfernung soll nicht auf
## Sonnenstand reagieren – sie soll im Dunst stehen.
func _kulissenstoff(farbe: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Keulung aus: Ob ein Ring von innen vorder- oder rückseitig ist, hängt
	# an der Umlaufrichtung der Vierecke, nicht an der gesetzten Normale –
	# und mit Keulung war die Kette schlicht unsichtbar, obwohl sie stand.
	# Bei einer geschlossenen Silhouette kostet das nichts.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m
