extends Node3D
class_name Bodenschatten
## Weicher runder Fleck am Boden unter einer Figur – die klassische
## Landehilfe der Korridor-Plattformer: Wo der Fleck liegt, landet man.
##
## Der echte Sonnenschatten reicht dafür nicht. Die Sonne steht in den
## Leveln bewusst steil, aber nie senkrecht – ihr Schatten fällt schräg
## vor oder neben die Figur, und in der Luft verrät er nicht, über welcher
## Kante man gerade steht. Der Fleck liegt dagegen immer GENAU darunter.
## Am Boden bleibt er als schwacher Kontaktschatten stehen: Er setzt die
## Figur auf den Weg, statt sie darüber schweben zu lassen.
##
## Aufbau nach dem Muster von `Schutzmaske`: Der Knoten hängt am Träger,
## merkt ihn sich beim Eintreten und führt den Fleck selbst. Der Fleck ist
## `top_level` (siehe `Effekte.blobschatten`) und wird jedes Bild auf den
## Bodenpunkt gesetzt, den ein Strahl nach unten findet.
##
## Reine Anzeige: keine Kollision, kein Schatten, keine Wirkung aufs Spiel.
## Der Strahl trifft nur Ebene 1 (feste Levelgeometrie, Kisten) und keine
## Areas – sonst läge der Fleck auf Wasserflächen und Todeszonen.

## Radius des Flecks am Boden in Metern. Etwas größer als die Kapsel
## (0,38 m): Am Boden verdeckt die Figur die Mitte, sichtbar bleibt der
## Saum um die Füße – ein Kontaktschatten, der sie auf den Weg stellt.
const RADIUS := 0.5
## So weit sucht der Strahl nach unten. Darunter ist ohnehin Abgrund.
const REICHWEITE := 40.0
## Ab dieser Höhe über dem Boden ist der Fleck am kleinsten und blassesten.
const HOEHE_VOLL := 8.0
## Deckkraft direkt am Boden bzw. in voller Höhe. Kräftig, weil der
## Waldweg selbst schon dunkel ist – bei 0,34 war der Fleck im Probelauf
## auf der Erde und auf den Wurzeln schlicht nicht zu finden.
const DECKKRAFT_BODEN := 0.6
const DECKKRAFT_HOCH := 0.3
## Anteil der Grundgröße in voller Höhe – je höher, desto kleiner, wie
## ein Schatten unter einer Lampe. Das liest sich ohne Zahl als Höhe.
const SKALA_HOCH := 0.5

## Zusätzlicher Faktor der Deckkraft (0..1), vom Träger gesetzt: etwa,
## solange die Figur im Portal schrumpft oder nach dem Tod wieder
## auftaucht. 0 blendet den Fleck ganz aus.
var staerke := 1.0

var _traeger: Node3D
var _fleck: MeshInstance3D
var _frage: PhysicsRayQueryParameters3D


func _ready() -> void:
	# Erst den Träger merken: Der Fleck selbst ist `top_level`, und bei
	# einem solchen Knoten liefert `get_parent_node_3d()` null.
	_traeger = get_parent() as Node3D
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_fleck = Effekte.blobschatten(self, RADIUS)
	# Das Material gehört diesem Fleck allein (siehe `Effekte.blobschatten`),
	# das Bild darf also getauscht werden. Der weiche Verlauf der Vorgabe
	# fällt schon ab halbem Radius ab; am Boden verdeckt die Figur genau
	# diese Mitte, und vom Fleck blieb nur ein Hauch. Hier ist er bis weit
	# nach außen satt und hat einen kurzen, weichen Saum.
	var stoff := _fleck.material_override as StandardMaterial3D
	if stoff != null:
		stoff.albedo_texture = _scheibenbild()
	_frage = PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.DOWN, 1)
	var koerper := _traeger as CollisionObject3D
	if koerper != null:
		_frage.exclude = [koerper.get_rid()]


func _process(_delta: float) -> void:
	if not is_instance_valid(_traeger) or not is_instance_valid(_fleck):
		return
	var welt := get_world_3d()
	if welt == null or staerke <= 0.0:
		_fleck.visible = false
		return
	# Interpoliert lesen wie Kamera und Masken: Die Figur wird weich
	# gezeichnet, ein Fleck im Physiktakt hüpfte daneben her.
	var p := Bildtakt.ort(_traeger)
	_frage.from = p + Vector3.UP * 0.3
	_frage.to = p + Vector3.DOWN * REICHWEITE
	var treffer := welt.direct_space_state.intersect_ray(_frage)
	if treffer.is_empty():
		_fleck.visible = false
		return
	var punkt: Vector3 = treffer["position"]
	var normale: Vector3 = treffer["normal"]
	var anteil := clampf((p.y - punkt.y) / HOEHE_VOLL, 0.0, 1.0)
	Effekte.blobschatten_setzen(_fleck, punkt, normale,
			lerpf(DECKKRAFT_BODEN, DECKKRAFT_HOCH, anteil) * clampf(staerke, 0.0, 1.0),
			lerpf(1.0, SKALA_HOCH, anteil))


static var _scheibe: GradientTexture2D = null


## Runde Scheibe, satt bis gut zur Hälfte, dann ein weicher Saum. Einmal
## gebaut und von allen Flecken geteilt; sie wird nie verändert.
static func _scheibenbild() -> GradientTexture2D:
	if _scheibe == null:
		var verlauf := Gradient.new()
		verlauf.offsets = PackedFloat32Array([0.0, 0.55, 0.8, 1.0])
		verlauf.colors = PackedColorArray([Color(1, 1, 1, 1.0),
				Color(1, 1, 1, 0.92), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		var bild := GradientTexture2D.new()
		bild.gradient = verlauf
		bild.width = 64
		bild.height = 64
		bild.fill = GradientTexture2D.FILL_RADIAL
		bild.fill_from = Vector2(0.5, 0.5)
		bild.fill_to = Vector2(1.0, 0.5)
		_scheibe = bild
	return _scheibe
