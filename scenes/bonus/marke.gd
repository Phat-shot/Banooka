extends Area3D
class_name Marke
## Marke – das Sammelstück, das den Bonusraum aufschließt.
##
## Warum ein eigenes Sammelstück und keine besondere Kiste: Eine Kiste
## zählt in den Kistenstand und wird nach jedem Tod aus dem Bauplan neu
## aufgestellt (`LevelBasis._bauplan_erfassen()`). Eine Marke soll das
## Gegenteil sein – einmal gefunden, für immer gefunden. Deshalb hängt sie
## in keiner der beiden Gruppen "kisten" und "gegner", wird also von
## keinem Neuaufbau erfasst: Wer die drei Marken beisammen hat, verliert
## den Bonusraum auch durch einen Tod nicht wieder.
##
## Die Marke trägt die Farbe des Raums, den sie öffnet. Das ist kein
## Schmuck, sondern die Ansage: Wer das Türkis zum ersten Mal im Tor
## wiedersieht, weiß, wofür er gesammelt hat.
##
## Sie ist bewusst NICHT magentafarben. In Level 18 heißt Magenta
## "Deckung", und diese Bedeutung darf kein zweites Ding tragen.

## Türkis – im Kistenvertrag die globale Farbe für "Rettungspunkt oder
## Ausgang". Ein Bonustor ist genau das: ein Ausgang, nur nach oben.
##
## Kräftig gesättigt, und die Leuchtstärken unten sind klein gehalten:
## Level 18 belichtet mit 1,34 und hebt Kontrast und Sättigung noch an.
## Mit der ersten Fassung (Leuchtstärke 1,8 und 2,6) übersteuerte die
## Marke restlos und lag als WEISSES Papierstück am Wegrand. Ein Signal,
## das seine Farbe verliert, ist kein Signal mehr.
const TON := Color(0.12, 0.86, 0.78)
## Der Scheibenkern leuchtet gar nicht – nur so behält die Marke ihre
## Form. Ein durchleuchteter Sechseckkern wird zur Scheibe ohne Kanten.
const KERN := Color(0.04, 0.31, 0.29)

## Anziehungsradius wie bei der Frucht: Wer nah genug dran ist, hat sie.
const MAGNET_RADIUS := 2.2
const MAGNET_TEMPO := 8.0

## Der Raum, dem diese Marke gehört. Bleibt sie leer, wird über die
## Gruppe "bonusraeume" gesucht – so funktioniert eine von Hand in eine
## Szene gelegte Marke auch ohne Verdrahtung.
var raum: Node = null

var _phase := 0.0
var _genommen := false

@onready var _modell: Node3D = $Modell


func _ready() -> void:
	add_to_group("marken")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	body_entered.connect(_auf_koerper)
	_phase = randf() * TAU
	_baue_modell()


## Eine sechseckige Scheibe mit erhabenem Rand, hochkant gestellt.
##
## Hochkant und sechseckig, damit sie sich auf einen Blick von der runden,
## liegenden Frucht unterscheidet – Form trägt hier so viel wie Farbe.
func _baue_modell() -> void:
	var scheibe := CylinderMesh.new()
	scheibe.top_radius = 0.40
	scheibe.bottom_radius = 0.40
	scheibe.height = 0.09
	scheibe.radial_segments = 6
	scheibe.rings = 1
	var kern := MeshInstance3D.new()
	kern.name = "Scheibe"
	kern.mesh = scheibe
	kern.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	kern.material_override = Materialbibliothek.einfarbig(KERN, 0.3, 0.5)
	kern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modell.add_child(kern)

	var reif := TorusMesh.new()
	reif.inner_radius = 0.40
	reif.outer_radius = 0.58
	reif.rings = 6
	reif.ring_segments = 6
	var rand := MeshInstance3D.new()
	rand.name = "Rand"
	rand.mesh = reif
	rand.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	rand.material_override = Materialbibliothek.leuchtend(TON, 1.1)
	rand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modell.add_child(rand)

	var schein := OmniLight3D.new()
	schein.name = "Schein"
	schein.light_color = TON
	schein.light_energy = 1.2
	schein.omni_range = 4.5
	schein.shadow_enabled = false
	_modell.add_child(schein)


func _process(delta: float) -> void:
	if _genommen:
		return
	_phase += delta * 2.4
	if is_instance_valid(_modell):
		_modell.rotation.y += delta * 1.7
		_modell.position.y = sin(_phase) * 0.16

	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return
	var ziel := spieler.global_position + Vector3.UP * 0.7
	var abstand := global_position.distance_to(ziel)
	if abstand < MAGNET_RADIUS:
		global_position = global_position.move_toward(ziel, MAGNET_TEMPO * delta)
		if abstand < 0.6:
			_nehmen()


func _auf_koerper(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler"):
		_nehmen()


func _nehmen() -> void:
	if _genommen:
		return
	_genommen = true
	Klang.spiele("checkpoint", 1.35)
	var ziel := raum
	if ziel == null or not is_instance_valid(ziel):
		ziel = get_tree().get_first_node_in_group("bonusraeume")
	if ziel != null and ziel.has_method("marke_aufnehmen"):
		ziel.call("marke_aufnehmen")
	queue_free()
