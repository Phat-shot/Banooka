extends Node3D
class_name Vogelschwarm
## Ein paar Vögel, die weit über dem Level kreisen.
##
## Reine Silhouetten am Himmel: klein, dunkel, ohne Kollision und ohne
## Schatten. Sie geben dem Bild einen ruhigen Zeiger dafür, dass die Welt
## lebt, und dürfen dem Spiel nie in die Quere kommen – deshalb beginnt
## `hoehe` erst bei 8 m über dem Knoten und es gibt keinerlei Körper.
##
## AUFBAU – warum ein MultiMesh an einem Drehknoten:
##   Vogelschwarm (Node3D)
##     └ Kreisel (MultiMeshInstance3D)   – dreht sich um die eigene Y-Achse
##
## Der ganze Schwarm hängt in EINEM MultiMesh; gekreist wird, indem der
## Kreisel gedreht wird. Das ist EINE Zahl je Bild für beliebig viele Vögel –
## billiger geht es nicht. Die Vögel behalten dabei ihre Formation, was bei
## Vögeln in einem Aufwind ohnehin so aussieht; das Leben kommt vom
## Flügelschlag, der im Vertex-Shader läuft und für jeden Vogel eine andere
## Phase hat.
##
## Die Vögel schauen nach -Z (Spielkonvention); ihre Instanz ist so gedreht,
## dass diese Richtung auf der Kreisbahn nach vorn zeigt, mit leichter
## Schräglage in die Kurve.

## Anzahl der Vögel.
@export_range(1, 60) var anzahl: int = 7
## Radius der Kreisbahn in Metern.
@export_range(2.0, 200.0, 0.5) var radius: float = 34.0
## Streuung des Radius (0 = alle auf einem Ring, 1 = von der Mitte bis außen).
@export_range(0.0, 1.0, 0.05) var radius_streuung: float = 0.35
## Flughöhe über dem Knoten in Metern. Nie tief genug, um zu stören.
@export_range(8.0, 200.0, 0.5) var hoehe: float = 42.0
## Streuung der Flughöhe in Metern.
@export_range(0.0, 40.0, 0.5) var hoehen_streuung: float = 7.0
## Spannweite eines Vogels in Metern. Aus der Ferne wirkt alles kleiner,
## als es ist – unter 1 m sieht man gar nichts mehr.
@export_range(0.2, 6.0, 0.05) var spannweite: float = 1.7
## Größenstreuung der Vögel.
@export_range(0.0, 1.0, 0.05) var groessen_streuung: float = 0.3
## Farbe der Silhouette.
@export var farbe: Color = Color(0.13, 0.14, 0.18)
## Kreisen an/aus. Aus = die Vögel stehen (schlagen aber weiter).
@export var kreisen: bool = true
## Winkelgeschwindigkeit der Kreisbahn in Umdrehungen je Minute.
@export_range(0.05, 10.0, 0.05) var umdrehungen_je_minute: float = 1.1
## Linksherum statt rechtsherum kreisen.
@export var linksherum: bool = false
## Schräglage in die Kurve, in Grad.
@export_range(0.0, 45.0, 0.5) var schraeglage: float = 12.0
## Flügelschläge je Sekunde.
@export_range(0.0, 8.0, 0.05) var schlag_tempo: float = 1.9
## Wie weit die Flügelspitzen ausschlagen, als Anteil der halben Spannweite.
@export_range(0.0, 1.5, 0.05) var schlag_hub: float = 0.55
## Feste Saat: gleicher Wert ⇒ gleicher Schwarm. 0 = jedes Mal neu würfeln.
@export var saat: int = 0

## Nur der Flügelschlag – das Kreisen macht der Drehknoten.
##
## `unshaded`: Ein Vogel am Himmel ist praktisch immer im Gegenlicht und
## damit eine dunkle Fläche. Eine echte Beleuchtung würde ihn je nach
## Sonnenstand aufhellen und die Silhouette zerstören; außerdem spart das
## Normalen und Lichtberechnung.
const VOGEL_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 farbe : source_color = vec4(0.13, 0.14, 0.18, 1.0);
uniform float schlag_tempo = 1.9;
uniform float schlag_hub = 0.55;
uniform float halbe_spannweite = 0.85;

void vertex() {
	// Instanzfarbe: Alpha ist die Phase, RGB die Aufhellung dieses Vogels.
	float phase = COLOR.a;
	float t = TIME * schlag_tempo * 6.2831 * (0.85 + 0.3 * fract(phase * 7.31))
			+ phase * 6.2831;
	// quadratisch nach außen gewichtet ⇒ der Rumpf bleibt ruhig,
	// die Spitzen holen weit aus
	float aussen = clamp(abs(VERTEX.x) / halbe_spannweite, 0.0, 1.0);
	VERTEX.y += sin(t) * aussen * aussen * schlag_hub * halbe_spannweite;
}

void fragment() {
	ALBEDO = farbe.rgb * COLOR.rgb;
}
"""

## Einmal für alle Schwärme gebaut – eine Kompilierung reicht.
static var _shader: Shader = null

var _kreisel: MultiMeshInstance3D = null
var _winkel := 0.0


func _ready() -> void:
	if saat == 0:
		saat = randi_range(1, 2_000_000_000)
	_kreisel = PropWerkzeug.kind(self, "Kreisel",
			func() -> MultiMeshInstance3D: return MultiMeshInstance3D.new())
	_baue(PropWerkzeug.zufall(saat))
	set_process(kreisen)


func _process(delta: float) -> void:
	# Eine einzige Zahl je Bild für den ganzen Schwarm.
	# `wrapf` hält den Winkel klein – nach Stunden Spielzeit verliert ein
	# unbegrenzt wachsender Float sonst seine Genauigkeit.
	var tempo := umdrehungen_je_minute * TAU / 60.0
	_winkel = wrapf(_winkel + tempo * delta * (-1.0 if linksherum else 1.0),
			0.0, TAU)
	_kreisel.rotation.y = _winkel


func _baue(rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _vogel_mesh()
	mm.instance_count = anzahl

	var neigung := deg_to_rad(schraeglage) * (1.0 if linksherum else -1.0)
	for i in anzahl:
		# gleichmäßig verteilt plus Rauschen: ein Kreis aus exakt gleichen
		# Abständen liest sich als Zahnrad, ein rein zufälliger als Klumpen
		var winkel := TAU * float(i) / float(anzahl) + rng.randf_range(-0.5, 0.5)
		var r := radius * (1.0 - rng.randf() * radius_streuung)
		var y := hoehe + rng.randf_range(-hoehen_streuung, hoehen_streuung) * 0.5
		var pos := Vector3(cos(winkel) * r, y, sin(winkel) * r)
		# Blickrichtung -Z auf die Tangente der Bahn drehen, dann in die
		# Kurve legen (Rollen um die eigene Längsachse). Der Kreisel dreht
		# sich um +Y, der Vogel läuft also auf wachsendem Winkel voran –
		# beim Linksherum-Flug entsprechend andersherum.
		var kurs := -winkel + (0.0 if linksherum else PI)
		var basis := Basis.from_euler(Vector3(0.0, kurs, 0.0)) \
				* Basis(Vector3.FORWARD, neigung)
		var skal := 1.0 + rng.randf_range(-groessen_streuung, groessen_streuung)
		mm.set_instance_transform(i, Transform3D(basis * Basis.from_scale(
				Vector3(skal, skal, skal)), pos))
		# leichte Helligkeitsstreuung, damit die Silhouetten Tiefe bekommen
		var ton := rng.randf_range(0.8, 1.25)
		mm.set_instance_color(i, Color(ton, ton, ton, rng.randf()))

	_kreisel.multimesh = mm
	_kreisel.material_override = _material()
	_kreisel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Feste Hülle: der Flügelschlag verschiebt Scheitelpunkte, und die
	# Instanzen stehen weit auseinander.
	var weite := radius + spannweite * 2.0
	var band := hoehen_streuung + spannweite * 2.0
	_kreisel.custom_aabb = AABB(Vector3(-weite, hoehe - band, -weite),
			Vector3(weite * 2.0, band * 2.0, weite * 2.0))


## Ein Vogel: schlanker Rumpf und zwei nach hinten gepfeilte Flügel.
##
## Entscheidend für die Lesbarkeit ist die HINTERKANTE: Läuft sie gerade vom
## Rumpf zur Spitze, entsteht ein Drachen, kein Vogel. Deshalb ist sie nach
## vorn eingezogen (`d` liegt vor der Linie Rumpfende–Spitze) – erst dadurch
## bekommt die Silhouette den Möwenschwung. Acht Dreiecke insgesamt;
## `cull_disabled` macht sie von oben wie von unten sichtbar.
func _vogel_mesh() -> Mesh:
	var st := PropWerkzeug.bauer()
	var h := spannweite * 0.5
	# nach -Z schauend: Kopf vorn, Schwanz hinten
	var kopf := Vector3(0.0, 0.0, -h * 0.46)
	var schwanz := Vector3(0.0, 0.0, h * 0.50)
	var seiten: Array[float] = [-1.0, 1.0]
	for seite in seiten:
		var rumpf_vorn := Vector3(seite * h * 0.05, 0.0, -h * 0.30)
		var rumpf_hinten := Vector3(seite * h * 0.05, 0.0, h * 0.26)
		var a := Vector3(seite * h * 0.45, h * 0.06, -h * 0.20)   # Vorderkante
		var d := Vector3(seite * h * 0.50, h * 0.07, h * 0.05)    # Hinterkante
		var spitze := Vector3(seite * h, h * 0.20, h * 0.10)
		_dreieck(st, rumpf_vorn, a, spitze)
		_dreieck(st, rumpf_vorn, spitze, d)
		_dreieck(st, rumpf_vorn, d, rumpf_hinten)
		# Rumpfhälfte: schmale Spindel zwischen Kopf und Schwanz
		_dreieck(st, kopf, rumpf_vorn, rumpf_hinten)
		_dreieck(st, kopf, rumpf_hinten, schwanz)
	var netz := PropWerkzeug.fertig(st)
	if netz == null:
		# Notnagel: lieber ein Viereck als gar kein Vogel
		var q := QuadMesh.new()
		q.size = Vector2(spannweite, spannweite * 0.3)
		return q
	return netz


## Die UV trägt hier keine Textur, sie muss nur gesetzt sein.
func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var punkte: Array[Vector3] = [a, b, c]
	for p in punkte:
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(p)


func _material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = VOGEL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("farbe", farbe)
	mat.set_shader_parameter("schlag_tempo", schlag_tempo)
	mat.set_shader_parameter("schlag_hub", schlag_hub)
	mat.set_shader_parameter("halbe_spannweite", maxf(spannweite * 0.5, 0.01))
	return mat
