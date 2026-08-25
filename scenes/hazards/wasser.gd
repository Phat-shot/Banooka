extends Node3D
class_name Wasser
## Rechteckige Wasserfläche mit animierten Wellen.
##
## Die Oberfläche ist ein feines PlaneMesh, das der Shader
## `res://shaders/wasser.gdshader` im Vertex-Shader verformt.
## Darunter liegt eine Area3D: Fällt der Spieler hinein, spritzt es
## und er ertrinkt (`schaden_nehmen`). Mit `toedlich = false` ist die
## Fläche reine Deko, etwa ein flacher Bach.

const SHADER_PFAD := "res://shaders/wasser.gdshader"

## Kantenlängen der Wasserfläche in Metern (X mal Z).
@export var flaeche := Vector2(10.0, 10.0):
	set(wert):
		flaeche = wert
		if is_inside_tree():
			_aufbauen()

## Tiefe des Wasserkörpers – so hoch ist die Auslösezone unter der Oberfläche.
@export var tiefe := 3.0:
	set(wert):
		tiefe = wert
		if is_inside_tree():
			_zone_anpassen()

## Ertrinkt der Spieler hier? False = reine Deko (flacher Bach).
@export var toedlich := true

## Ausschlag der Wellen in Metern.
@export_range(0.0, 0.6, 0.01) var wellen_hoehe := 0.16

## Tempo der Wellenanimation.
@export_range(0.1, 3.0, 0.05) var wellen_tempo := 1.0

## Farbe des Wassers. Alpha 0 = Vorgabe aus der Palette (klares Blau).
## Ein Moortümpel braucht andere Töne als ein Gebirgsbach, und ohne diese
## beiden Regler sah bisher jedes Gewässer im Spiel gleich aus.
@export var farbe_tief := Color(0, 0, 0, 0)
@export var farbe_hell := Color(0, 0, 0, 0)

## Stärke des hellen Schimmers an flachen Blickwinkeln. Bei trübem Wasser
## gehört er heruntergedreht: Sonst legt sich ein weißer Schleier über die
## ganze Fläche und der Sumpf leuchtet heller als der Himmel.
@export_range(0.0, 1.0, 0.05) var spiegelung := 0.55

## Unterteilung des Gitters – je feiner, desto runder die Wellen.
@export_range(8, 64, 1) var unterteilung := 32

## So weit reicht die Auslösezone über die Oberfläche hinaus – schon eine
## Berührung der Wasseroberfläche zählt damit als "hineingefallen".
const ZONE_OBERKANTE := 0.05
## Wartezeit zwischen Aufspritzen und Ertrinken.
const ERTRINK_VERZOEGERUNG := 0.35
## Anzahl der Tropfen pro Aufspritzer.
const TROPFEN_ANZAHL := 12
const TROPFEN_LEBEN := 0.9
const TROPFEN_G := -22.0

@onready var _zone: Area3D = $Zone
@onready var _zonenform: CollisionShape3D = $Zone/Kollision

var _oberflaeche: MeshInstance3D = null
var _tropfen: Array = []


func _ready() -> void:
	add_to_group("wasser")
	_zone.collision_layer = 0
	_zone.collision_mask = 2       # nur den Spieler beachten
	_zone.monitoring = true
	if not _zone.body_entered.is_connected(_auf_koerper):
		_zone.body_entered.connect(_auf_koerper)
	_aufbauen()
	_zone_anpassen()


# ---------------------------------------------------------------- Aufbau

## Erzeugt die Wasseroberfläche mit dem Wellen-Shader.
func _aufbauen() -> void:
	if _oberflaeche == null:
		_oberflaeche = MeshInstance3D.new()
		_oberflaeche.name = "Oberflaeche"
		add_child(_oberflaeche)

	var gitter := PlaneMesh.new()
	gitter.size = flaeche
	gitter.subdivide_width = unterteilung
	gitter.subdivide_depth = unterteilung
	_oberflaeche.mesh = gitter
	_oberflaeche.material_override = _wassermaterial()
	# Die Wellen schieben Punkte über die AABB hinaus – sonst poppt die Fläche weg.
	_oberflaeche.extra_cull_margin = 2.0
	_oberflaeche.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Baut das ShaderMaterial und füllt die Uniforms aus der Farbpalette.
func _wassermaterial() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_PFAD) as Shader
	var tief := farbe_tief if farbe_tief.a > 0.0 else Farben.WASSER
	var hell := farbe_hell if farbe_hell.a > 0.0 else Farben.WASSER_HELL
	m.set_shader_parameter("farbe_tief", tief)
	m.set_shader_parameter("farbe_hell", hell)
	m.set_shader_parameter("farbe_schaum", hell.lightened(0.6))
	m.set_shader_parameter("spiegelung", spiegelung)
	m.set_shader_parameter("wellen_hoehe", wellen_hoehe)
	m.set_shader_parameter("wellen_tempo", wellen_tempo)
	# Graustufen-Rauschen aus der Materialbibliothek als Kräuselmuster.
	m.set_shader_parameter("rauschen",
			Materialbibliothek.rauschtextur(1313, 0.9, Color.BLACK, Color.WHITE, 128))
	return m


## Passt die Auslösezone an Fläche und Tiefe an.
func _zone_anpassen() -> void:
	if _zonenform == null:
		return
	var form := _zonenform.shape as BoxShape3D
	if form == null:
		form = BoxShape3D.new()
		_zonenform.shape = form
	else:
		form = form.duplicate() as BoxShape3D
		_zonenform.shape = form
	form.size = Vector3(flaeche.x, tiefe, flaeche.y)
	_zonenform.position = Vector3(0.0, ZONE_OBERKANTE - tiefe * 0.5, 0.0)


# ---------------------------------------------------------------- Reaktion

func _auf_koerper(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	var stelle := to_local(koerper.global_position)
	aufspritzen(Vector3(stelle.x, 0.0, stelle.z))
	if toedlich:
		_ertrinken_ausloesen(koerper)


## Kleiner Aufspritzer aus einfachen Tropfen-Meshes.
## (Bewusst keine GPUParticles3D – die sind in gl_compatibility zickig.)
func aufspritzen(lokale_stelle: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	mesh.radial_segments = 6
	mesh.rings = 4
	var material := Materialbibliothek.transparent(Farben.WASSER_HELL, 0.6)
	for i in TROPFEN_ANZAHL:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.position = lokale_stelle + Vector3(randf_range(-0.2, 0.2), 0.05,
				randf_range(-0.2, 0.2))
		var winkel := TAU * float(i) / float(TROPFEN_ANZAHL) + randf() * 0.5
		var weite := randf_range(1.4, 3.0)
		_tropfen.append({
			"knoten": mi,
			"geschw": Vector3(cos(winkel) * weite, randf_range(4.5, 7.5),
					sin(winkel) * weite),
			"zeit": TROPFEN_LEBEN,
		})


## Kurz warten, damit der Aufspritzer sichtbar ist, dann ertrinken.
func _ertrinken_ausloesen(spieler: Node3D) -> void:
	await get_tree().create_timer(ERTRINK_VERZOEGERUNG).timeout
	if not is_instance_valid(spieler) or not is_instance_valid(self):
		return
	if spieler.has_method("schaden_nehmen"):
		spieler.schaden_nehmen()


func _process(delta: float) -> void:
	if _tropfen.is_empty():
		return
	var uebrig: Array = []
	for t in _tropfen:
		var mi: MeshInstance3D = t["knoten"]
		if not is_instance_valid(mi):
			continue
		t["zeit"] -= delta
		if t["zeit"] <= 0.0:
			mi.queue_free()
			continue
		var v: Vector3 = t["geschw"]
		v.y += TROPFEN_G * delta
		t["geschw"] = v
		mi.position += v * delta
		var rest: float = t["zeit"] / TROPFEN_LEBEN
		mi.scale = Vector3.ONE * maxf(rest, 0.05)
		uebrig.append(t)
	_tropfen = uebrig
