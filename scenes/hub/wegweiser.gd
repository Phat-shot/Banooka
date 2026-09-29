extends Node3D
class_name Wegweiser
## Schwebender Pfeil über dem Spieler, der auf das nächste offene
## Levelportal zeigt, dazu ein Kompassring am Boden.
##
## Im Portalraum ist von den 25 Toren zunächst nur ein Raum offen. Ohne
## Hinweis muss man alle fünf Räume ablaufen, um ihn zu finden.
## Der Pfeil blendet aus, sobald man nah genug dran ist.
##
## Ziel ist das nächste Tor, das offen UND noch nicht geschafft ist; erst
## wenn es keins mehr gibt, irgendein offenes. Sonst zeigte der Pfeil nach
## der Rückkehr aus Level 01 stur auf Level 01 – das nächstgelegene Tor.
## Im Raum dieses Tors gewinnt dann die kleinste Nummer: Beim neuen Spiel
## steht man mittig vor dem Wurzelwald, das nächste Tor wäre 03 – gemeint
## ist aber 01, das Tor mit dem Vorhof.
##
## Farbe: Der Winkel selbst ist warmweiß – in der Raumfarbe verschwand er
## auf dem Gras des Wurzelwalds und dem Stein der Feste. Die Farbe des
## Zielraums (`Levelportal.akzent`) tragen sein Rand und der Kompassring.

## Höhe über dem Spieler.
@export var hoehe := 2.5
## Ab diesem Abstand ist der Pfeil ganz ausgeblendet.
@export var ausblenden_ab := 6.0
## Ab diesem Abstand ist er voll sichtbar.
@export var voll_ab := 11.0
## Wie schnell er sich zum Ziel dreht (Anteil je Sekunde).
@export var drehtempo := 6.0

var _spieler: Node3D
var _ziel: Node3D
var _material: StandardMaterial3D
var _randmaterial: StandardMaterial3D
var _ringmaterial: StandardMaterial3D
var _ring: Node3D
var _farbe := Farben.PORTAL_START
var _phase := 0.0
var _sichtbarkeit := 0.0


## Größer als lebensgroß, damit der Pfeil aus der Verfolgerkamera auffällt.
## Skaliert werden die Teile, NICHT dieser Knoten: seine Basis muss
## normalisiert bleiben, sonst kann sie nicht mehr geslerpt werden.
const GROESSE := 1.45
## Höhe des Kompassrings über dem Boden. Der Portalraum ist eben (Pflaster
## und Räume auf 0 cm, Mittelstein und Schwellen gut 3 cm darüber); der
## Ring bleibt beim Springen unten wie ein Schatten.
const RING_Y := 0.05
## Kern des Winkels: warmweiß und über 1, damit er leicht glüht.
const KERN := Color(1.25, 1.2, 1.05)
## Maße eines Arms (Breite, Dicke, Länge) und wie weit der Rand übersteht.
const ARM := Vector3(0.17, 0.08, 0.55)
const RAND := 0.035

func _ready() -> void:
	_baue()
	_phase = randf() * TAU


func _baue() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Immer sichtbar, auch wenn eine Mauer dazwischen steht – der Pfeil
	# soll ja gerade den Weg durch den Raum weisen.
	_material.no_depth_test = true
	_material.render_priority = 4
	_randmaterial = _material.duplicate() as StandardMaterial3D
	_randmaterial.render_priority = 3
	_setze_farbe(_farbe)

	# Winkel statt Schaft und Kegel: zwei flache Balken, die sich vorn
	# treffen. Er liest sich von oben wie von hinten als Richtung, und
	# anders als der Kegel verdeckt er die Figur kaum. Beide Arme sind EIN
	# Netz, der Rand in Raumfarbe ein zweites, etwas größeres dahinter.
	_winkel("Winkel", ARM, _material)
	_winkel("Winkelrand", ARM + Vector3(RAND, RAND, RAND) * 2.0, _randmaterial)

	# Kompassring am Boden. Er hängt NICHT unter diesem Knoten – der dreht
	# und schwebt; der Ring liegt still und nur seine Kerbe zeigt zum Ziel.
	_ringmaterial = StandardMaterial3D.new()
	_ringmaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ringmaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ringmaterial.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ringmaterial.disable_receive_shadows = true
	_ring = Node3D.new()
	_ring.name = "Kompass"
	_ring.top_level = true
	add_child(_ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 0.9
	torus.rings = 40
	torus.ring_segments = 4
	var reif := MeshInstance3D.new()
	reif.mesh = torus
	reif.scale = Vector3(1.0, 0.15, 1.0)
	reif.material_override = _ringmaterial
	reif.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.add_child(reif)
	# Kerbe: ein kleines Dreieck außen am Ring, Spitze zum Ziel.
	var kerbe := MeshInstance3D.new()
	var prisma := PrismMesh.new()
	prisma.size = Vector3(0.34, 0.3, 0.02)
	kerbe.mesh = prisma
	kerbe.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	kerbe.position = Vector3(0.0, 0.0, -1.06)
	kerbe.material_override = _ringmaterial
	kerbe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.add_child(kerbe)


## Beide Arme des Winkels als ein Netz. Spitze bei -Z (Blickrichtung), die
## Arme laufen nach hinten auseinander.
func _winkel(bezeichnung: String, groesse: Vector3, stoff: Material) -> void:
	var balken := BoxMesh.new()
	balken.size = groesse
	var st := SurfaceTool.new()
	for seite: float in [-1.0, 1.0]:
		var dreh := deg_to_rad(42.0) * seite
		var halb := ARM.z * 0.5
		var mitte := Vector3(sin(dreh) * halb, 0.0, cos(dreh) * halb - 0.22) * GROESSE
		st.append_from(balken, 0, Transform3D(
				Basis(Vector3.UP, dreh).scaled(Vector3.ONE * GROESSE), mitte))
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = st.commit()
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _setze_farbe(ton: Color) -> void:
	_farbe = ton
	var hell := ton.lightened(0.25)
	if _material != null:
		_material.albedo_color = Color(KERN, _material.albedo_color.a)
	if _randmaterial != null:
		_randmaterial.albedo_color = Color(ton, _randmaterial.albedo_color.a)
	if _ringmaterial != null:
		_ringmaterial.albedo_color = Color(hell, _ringmaterial.albedo_color.a)


func _process(delta: float) -> void:
	_phase += delta * 2.4

	if _spieler == null or not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null:
			_setze_sichtbarkeit(0.0, delta)
			return

	_ziel = _naechstes_offenes_portal()
	if _ziel == null:
		_setze_sichtbarkeit(0.0, delta)
		return
	var ton: Variant = _ziel.get("akzent")
	if ton is Color and (ton as Color).a > 0.0 and (ton as Color) != _farbe:
		_setze_farbe(ton as Color)

	# Über dem Spieler schweben, mit leichtem Auf und Ab
	global_position = _spieler.global_position \
			+ Vector3.UP * (hoehe + sin(_phase) * 0.13)

	# Zum Ziel drehen, waagerecht
	var blick := _ziel.global_position
	blick.y = global_position.y
	if global_position.distance_squared_to(blick) > 0.01:
		var soll := Transform3D(basis, global_position).looking_at(blick, Vector3.UP)
		basis = basis.orthonormalized().slerp(soll.basis.orthonormalized(),
				clampf(drehtempo * delta, 0.0, 1.0))

	# Kompass am Boden: folgt dem Spieler, Kerbe in dieselbe Richtung.
	var fuss := _spieler.global_position
	_ring.global_position = Vector3(fuss.x, RING_Y, fuss.z)
	_ring.global_rotation = Vector3(0.0, global_rotation.y, 0.0)

	# Nahe am Ziel ausblenden
	var abstand := _spieler.global_position.distance_to(_ziel.global_position)
	var ziel_alpha := clampf(
			inverse_lerp(ausblenden_ab, voll_ab, abstand), 0.0, 1.0)
	_setze_sichtbarkeit(ziel_alpha, delta)


func _setze_sichtbarkeit(ziel_alpha: float, delta: float) -> void:
	_sichtbarkeit = move_toward(_sichtbarkeit, ziel_alpha, delta * 2.5)
	visible = _sichtbarkeit > 0.01
	# Leichtes Pulsieren, damit er auffällt
	var puls := 0.82 + 0.18 * sin(_phase * 1.6)
	if _material != null:
		_material.albedo_color.a = _sichtbarkeit * puls
	if _randmaterial != null:
		_randmaterial.albedo_color.a = _sichtbarkeit * puls
	if _ringmaterial != null:
		_ringmaterial.albedo_color.a = _sichtbarkeit * (0.35 + 0.25 * puls)


## Nächstes Portal, das tatsächlich betreten werden kann – bevorzugt eines,
## das noch nicht geschafft ist, und in dessen Raum das mit der kleinsten
## Nummer.
func _naechstes_offenes_portal() -> Node3D:
	var bestes: Node3D = null
	var beste_entfernung := INF
	var neues_gefunden := false
	var offene: Array[Node3D] = []
	for knoten in get_tree().get_nodes_in_group("levelportale"):
		var portal := knoten as Node3D
		if portal == null or not ("nummer" in portal):
			continue
		var nummer := int(portal.get("nummer"))
		if not Spielfluss.level_offen(nummer):
			continue
		var neu := not Spielfluss.geschafft.has(nummer)
		if neu:
			offene.append(portal)
		# Ein ungeschafftes Tor schlägt jedes geschaffte, egal wie nah.
		if neues_gefunden and not neu:
			continue
		var entfernung := portal.global_position.distance_to(_spieler.global_position)
		if (neu and not neues_gefunden) or entfernung < beste_entfernung:
			beste_entfernung = entfernung
			bestes = portal
			neues_gefunden = neues_gefunden or neu
	if not neues_gefunden:
		return bestes
	var kleinste := int(bestes.get("nummer"))
	var raum := Spielfluss.raum_von_level(kleinste)
	for portal in offene:
		var nummer := int(portal.get("nummer"))
		if nummer < kleinste and Spielfluss.raum_von_level(nummer) == raum:
			kleinste = nummer
			bestes = portal
	return bestes
