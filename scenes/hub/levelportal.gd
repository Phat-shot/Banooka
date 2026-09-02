extends Node3D
class_name Levelportal
## Ein Levelportal im Portalraum – ein Tor pro Level.
##
## Der Zustand kommt aus `Spielfluss`:
##   OFFEN         – leuchtender, pulsierender Ring; Betreten startet das Level
##   VERSCHLOSSEN  – gebaut, aber noch nicht freigeschaltet: dunkel, mit Gitter
##   IN_ARBEIT     – Level noch nicht gebaut: mit Bauplane abgedeckt
##
## Geschaffte Level leuchten: ein warmer Schein legt sich um das ganze
## Tor. Der goldene Haken von früher war eine Marke neben der Zahl – man
## musste hinsehen, um ihn zu bemerken. Der Schein wirkt schon aus dem
## Augenwinkel und über den halben Raum hinweg.
##
## Darüber schweben bis zu drei Steine:
##   blau  – alle Kisten zerbrochen
##   rot   – Level ohne einen einzigen Tod geschafft
##   Zeitrelikt – im Zeitmodus die Richtzeit unterboten; seine Farbe sagt
##   welche Stufe (Saphir, Gold, Platin). Darunter steht die Bestzeit.
##
## `nummer` muss VOR `add_child()` gesetzt werden – `_ready()` baut daraus
## die gesamte Optik auf.

enum Zustand { OFFEN, VERSCHLOSSEN, IN_ARBEIT }

const RADIUS := 1.05          ## Innenradius des Rings
const RING_DICKE := 0.17
const MITTE_Y := 1.25         ## Höhe der Ringmitte über dem Boden
const ZONE_RADIUS := 0.95
const ZONE_HOEHE := 2.4

## Levelnummer, 1-basiert.
var nummer := 1
## Ergibt sich in `_ready()` aus dem Spielfluss.
var zustand: Zustand = Zustand.IN_ARBEIT

var _scheibe: MeshInstance3D = null
var _scheibenmaterial: StandardMaterial3D = null
var _licht: OmniLight3D = null
var _edelsteine: Array[Node3D] = []
var _schein: OmniLight3D = null
var _scheinring: MeshInstance3D = null
var _scheinmaterial: StandardMaterial3D = null
var _phase := 0.0
var _ausgeloest := false


func _ready() -> void:
	add_to_group("levelportale")
	_phase = float(nummer) * 0.83
	zustand = _bestimme_zustand()

	_baue_pfeiler()
	_baue_ring()
	match zustand:
		Zustand.OFFEN:
			_baue_scheibe()
		Zustand.VERSCHLOSSEN:
			_baue_gitter()
		_:
			_baue_bauplane()
	_baue_zahl()
	_baue_erfolg()
	_baue_zone()

	set_process(zustand == Zustand.OFFEN or not _edelsteine.is_empty()
			or _schein != null)


func _bestimme_zustand() -> Zustand:
	if not Spielfluss.level_gebaut(nummer):
		return Zustand.IN_ARBEIT
	if Spielfluss.level_offen(nummer):
		return Zustand.OFFEN
	return Zustand.VERSCHLOSSEN


## Grundton des Tores.
func farbe() -> Color:
	match zustand:
		Zustand.OFFEN:
			return Farben.PORTAL_START
		Zustand.VERSCHLOSSEN:
			return Farben.KISTE_EISEN.darkened(0.35)
		_:
			return Farben.FELS_DUNKEL


# ------------------------------------------------------------------ Aufbau

## Zwei Steinpfeiler links und rechts – sie rahmen das Tor und geben ihm
## Halt im Raum. Kollision nur an den Pfeilern, der Durchgang bleibt frei.
func _baue_pfeiler() -> void:
	for wert in [-1.0, 1.0]:
		var seite := float(wert)
		var koerper := StaticBody3D.new()
		koerper.collision_layer = 1
		koerper.collision_mask = 0
		koerper.position = Vector3(seite * (RADIUS + 0.62), 0.85, 0.0)

		var wuerfel := BoxMesh.new()
		wuerfel.size = Vector3(0.52, 1.7, 0.52)
		var mi := MeshInstance3D.new()
		mi.mesh = wuerfel
		mi.material_override = Materialbibliothek.fels()
		koerper.add_child(mi)

		var form := BoxShape3D.new()
		form.size = wuerfel.size
		var kollision := CollisionShape3D.new()
		kollision.shape = form
		koerper.add_child(kollision)
		add_child(koerper)

		# Leuchtende Kappe – bei offenen Toren farbig, sonst matt
		var kappe := MeshInstance3D.new()
		var kappen_mesh := BoxMesh.new()
		kappen_mesh.size = Vector3(0.66, 0.16, 0.66)
		kappe.mesh = kappen_mesh
		kappe.position = Vector3(seite * (RADIUS + 0.62), 1.78, 0.0)
		kappe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if zustand == Zustand.OFFEN:
			kappe.material_override = Materialbibliothek.leuchtend(farbe(), 1.6)
		else:
			kappe.material_override = Materialbibliothek.einfarbig(farbe(), 0.8)
		add_child(kappe)


func _baue_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS
	torus.outer_radius = RADIUS + RING_DICKE
	torus.rings = 16
	torus.ring_segments = 6

	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = torus
	ring.position = Vector3(0.0, MITTE_Y, 0.0)
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if zustand == Zustand.OFFEN:
		ring.material_override = Materialbibliothek.leuchtend(farbe(), 1.0)
	else:
		ring.material_override = Materialbibliothek.einfarbig(farbe(), 0.75, 0.25)
	add_child(ring)


## Flimmernde Scheibe im offenen Tor, dazu ein Schein.
func _baue_scheibe() -> void:
	var flaeche := CylinderMesh.new()
	flaeche.top_radius = RADIUS
	flaeche.bottom_radius = RADIUS
	flaeche.height = 0.04
	flaeche.radial_segments = 16
	flaeche.rings = 0

	_scheibe = MeshInstance3D.new()
	_scheibe.name = "Scheibe"
	_scheibe.mesh = flaeche
	_scheibe.position = Vector3(0.0, MITTE_Y, 0.0)
	_scheibe.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_scheibe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scheibenmaterial = Materialbibliothek.transparent(
			farbe().lightened(0.15), 1.0).duplicate()
	_scheibenmaterial.albedo_color.a = 0.5
	_scheibe.material_override = _scheibenmaterial
	add_child(_scheibe)

	_licht = OmniLight3D.new()
	_licht.name = "Schein"
	_licht.light_color = farbe()
	_licht.light_energy = 1.4
	_licht.omni_range = 7.0
	_licht.shadow_enabled = false
	_licht.position = Vector3(0.0, MITTE_Y, 0.35)
	add_child(_licht)


## Gitter vor einem verschlossenen Tor: drei Stäbe und ein Querriegel.
func _baue_gitter() -> void:
	var material := Materialbibliothek.metall()
	for i in 3:
		var stab := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.11, RADIUS * 1.95, 0.11)
		stab.mesh = mesh
		stab.material_override = material
		stab.position = Vector3((float(i) - 1.0) * 0.62, MITTE_Y, 0.0)
		add_child(stab)

	var riegel := MeshInstance3D.new()
	var riegel_mesh := BoxMesh.new()
	riegel_mesh.size = Vector3(RADIUS * 1.9, 0.16, 0.14)
	riegel.mesh = riegel_mesh
	riegel.material_override = material
	riegel.position = Vector3(0.0, MITTE_Y, 0.0)
	add_child(riegel)

	# Schloss in der Mitte
	var schloss := MeshInstance3D.new()
	var schloss_mesh := BoxMesh.new()
	schloss_mesh.size = Vector3(0.34, 0.4, 0.2)
	schloss.mesh = schloss_mesh
	schloss.material_override = Materialbibliothek.einfarbig(Farben.ROST_HELL, 0.6, 0.5)
	schloss.position = Vector3(0.0, MITTE_Y - 0.08, 0.1)
	add_child(schloss)


## Noch nicht gebautes Level: Bauplane mit gekreuzten Brettern.
func _baue_bauplane() -> void:
	var plane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(RADIUS * 2.35, RADIUS * 2.2, 0.12)
	plane.mesh = mesh
	plane.material_override = Materialbibliothek.einfarbig(
			Farben.WEG_HELL.lerp(Farben.GRAS_TROCKEN, 0.3), 0.95)
	plane.position = Vector3(0.0, MITTE_Y, 0.0)
	plane.rotation_degrees = Vector3(0.0, 0.0, 2.5)
	add_child(plane)

	for wert in [34.0, -34.0]:
		var winkel := float(wert)
		var brett := MeshInstance3D.new()
		var brett_mesh := BoxMesh.new()
		brett_mesh.size = Vector3(RADIUS * 2.7, 0.2, 0.1)
		brett.mesh = brett_mesh
		brett.material_override = Materialbibliothek.kistenholz()
		brett.position = Vector3(0.0, MITTE_Y, 0.12)
		brett.rotation_degrees = Vector3(0.0, 0.0, winkel)
		add_child(brett)

	var hinweis := Label3D.new()
	hinweis.text = "in Arbeit"
	hinweis.font_size = 44
	hinweis.outline_size = 10
	hinweis.pixel_size = 0.009
	hinweis.modulate = Farben.KISTE_FEDER
	hinweis.outline_modulate = Color(0.06, 0.05, 0.03, 0.9)
	hinweis.position = Vector3(0.0, 0.42, 0.2)
	add_child(hinweis)


func _baue_zahl() -> void:
	var zahl := Label3D.new()
	zahl.name = "Nummer"
	zahl.text = "%02d" % nummer
	zahl.font_size = 120
	zahl.outline_size = 20
	zahl.pixel_size = 0.011
	match zustand:
		Zustand.OFFEN:
			zahl.modulate = Color(1.0, 0.97, 0.85)
		Zustand.VERSCHLOSSEN:
			zahl.modulate = Color(0.72, 0.75, 0.8)
		_:
			zahl.modulate = Color(0.6, 0.58, 0.54)
	zahl.outline_modulate = Color(0.05, 0.04, 0.03, 0.92)
	zahl.position = Vector3(0.0, MITTE_Y + RADIUS + 0.75, 0.0)
	add_child(zahl)


## Schein für geschaffte Level, Edelsteine für die beiden Kunststücke.
func _baue_erfolg() -> void:
	if not Spielfluss.geschafft.has(nummer):
		return
	var eintrag: Dictionary = Spielfluss.geschafft[nummer]

	_baue_schein()

	# --- Edelsteine über dem Tor ---
	var steine: Array = []
	if bool(eintrag.get("kisten", false)):
		steine.append(Farben.EDELSTEIN_KISTEN)
	if bool(eintrag.get("ohne_tod", false)):
		steine.append(Farben.EDELSTEIN_OHNE_TOD)
	var zeitstand := Spielfluss.zeit_von(nummer)
	var stufe := int(zeitstand["stufe"])
	if stufe > 0:
		steine.append(Zeitlauf.stufen_farbe(stufe))
	for i in steine.size():
		# Ein Stein steht mittig, mehrere rücken gleichmäßig auseinander.
		var x := (float(i) - float(steine.size() - 1) * 0.5) * 0.86
		_edelsteine.append(_baue_edelstein(steine[i], x))
	if float(zeitstand["zeit"]) > 0.0:
		_baue_bestzeit(float(zeitstand["zeit"]), stufe)


## Warmer Schein um das ganze Tor: ein Licht in der Toröffnung und ein
## breiter, halbdurchsichtiger Ring hinter dem Rahmen.
func _baue_schein() -> void:
	_scheinring = MeshInstance3D.new()
	_scheinring.name = "Schein"
	var scheibe := TorusMesh.new()
	scheibe.inner_radius = RADIUS + RING_DICKE * 0.2
	scheibe.outer_radius = RADIUS + RING_DICKE * 4.6
	scheibe.rings = 24
	scheibe.ring_segments = 10
	_scheinring.mesh = scheibe
	_scheinring.position = Vector3(0.0, MITTE_Y, -0.04)
	_scheinring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_scheinring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Additiv und ungeschattet: Nur so liest sich der Ring als Licht und
	# nicht als graue Scheibe. Ein gewöhnliches Leuchtmaterial wurde von
	# der Raumbeleuchtung überlagert und blieb stumpf.
	_scheinmaterial = StandardMaterial3D.new()
	_scheinmaterial.albedo_color = Color(Farben.ERFOLG_SCHEIN.r,
			Farben.ERFOLG_SCHEIN.g, Farben.ERFOLG_SCHEIN.b, 0.30)
	_scheinmaterial.emission_enabled = true
	_scheinmaterial.emission = Farben.ERFOLG_SCHEIN
	_scheinmaterial.emission_energy_multiplier = 1.3
	_scheinmaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_scheinmaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scheinmaterial.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_scheinmaterial.cull_mode = BaseMaterial3D.CULL_DISABLED
	_scheinring.material_override = _scheinmaterial
	add_child(_scheinring)

	_schein = OmniLight3D.new()
	_schein.name = "Scheinlicht"
	_schein.light_color = Farben.ERFOLG_SCHEIN
	_schein.light_energy = 1.6
	_schein.omni_range = 5.5
	_schein.shadow_enabled = false
	_schein.position = Vector3(0.0, MITTE_Y, 0.2)
	add_child(_schein)


## Die Bestzeit unter der Levelnummer. Sie steht klein und matt da: Wer
## sie sucht, findet sie; wer nur zum nächsten Tor läuft, wird von ihr
## nicht aufgehalten.
func _baue_bestzeit(sekunden: float, stufe: int) -> void:
	var schild := Label3D.new()
	schild.name = "Bestzeit"
	schild.text = Zeitlauf.als_text(sekunden)
	schild.font_size = 44
	schild.pixel_size = 0.0032
	schild.modulate = Zeitlauf.stufen_farbe(stufe) if stufe > 0 \
			else Color(0.82, 0.80, 0.74)
	schild.outline_size = 12
	schild.outline_modulate = Color(0.05, 0.04, 0.03, 0.92)
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Zwischen Torbogen und Levelnummer. Unter den Ring gehört sie nicht:
	# Dort ist der Boden, und die Schrift steckte darin.
	schild.position = Vector3(0.0, MITTE_Y + RADIUS + 0.32, 0.0)
	add_child(schild)


func _baue_edelstein(ton: Color, seitlich: float) -> Node3D:
	var stein := Node3D.new()
	stein.name = "Edelstein"
	stein.position = Vector3(seitlich, MITTE_Y + RADIUS + 1.62, 0.0)
	add_child(stein)

	var kristall := MeshInstance3D.new()
	var form := SphereMesh.new()
	form.radius = 0.3
	form.height = 0.86
	form.radial_segments = 6
	form.rings = 2
	kristall.mesh = form
	kristall.material_override = Materialbibliothek.leuchtend(ton, 1.4)
	kristall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stein.add_child(kristall)
	return stein


func _baue_zone() -> void:
	var zone := Area3D.new()
	zone.name = "Zone"
	zone.collision_layer = 0
	zone.collision_mask = 2       # nur den Spieler beachten
	zone.position = Vector3(0.0, ZONE_HOEHE * 0.5, 0.0)
	var form := CollisionShape3D.new()
	var zylinder := CylinderShape3D.new()
	zylinder.radius = ZONE_RADIUS
	zylinder.height = ZONE_HOEHE
	form.shape = zylinder
	zone.add_child(form)
	add_child(zone)
	zone.body_entered.connect(_auf_koerper)


# --------------------------------------------------------------- Animation

func _process(delta: float) -> void:
	_phase += delta
	if zustand == Zustand.OFFEN:
		var puls := 0.5 + 0.5 * sin(_phase * 2.9)
		if is_instance_valid(_scheibe):
			var s := 0.9 + puls * 0.1
			_scheibe.scale = Vector3(s, 1.0, s)
		if _scheibenmaterial != null:
			_scheibenmaterial.emission_energy_multiplier = 0.9 + puls * 1.2
			_scheibenmaterial.albedo_color.a = 0.4 + puls * 0.22
		if is_instance_valid(_licht):
			_licht.light_energy = 1.1 + puls * 0.9
	for i in _edelsteine.size():
		var stein := _edelsteine[i]
		if not is_instance_valid(stein):
			continue
		stein.rotation.y += delta * 1.4
		# Gegenläufig versetzt schweben, damit zwei Steine nicht im
		# Gleichschritt wippen.
		stein.position.y = MITTE_Y + RADIUS + 1.62 \
				+ sin(_phase * 1.7 + float(i) * 2.1) * 0.09
	if _scheinmaterial != null:
		var schwelle := 0.5 + 0.5 * sin(_phase * 1.6)
		_scheinmaterial.emission_energy_multiplier = 1.1 + schwelle * 0.7
		_scheinmaterial.albedo_color.a = 0.22 + schwelle * 0.14
	if is_instance_valid(_schein):
		_schein.light_energy = 1.2 + 0.6 * (0.5 + 0.5 * sin(_phase * 1.6))


# ------------------------------------------------------------------ Betreten

func _auf_koerper(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	match zustand:
		Zustand.OFFEN:
			if _ausgeloest:
				return
			_ausgeloest = true
			_eintreten(koerper)
		Zustand.VERSCHLOSSEN:
			GameState.zeige_nachricht("Noch verschlossen", 1.5)
		_:
			GameState.zeige_nachricht("Noch in Arbeit", 1.5)


## Kurze Aufblende, dann startet das Level.
func _eintreten(spieler: Node3D) -> void:
	if "gesperrt" in spieler:
		spieler.gesperrt = true
	GameState.zeige_nachricht("Level %02d" % nummer, 1.2)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.3, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_instance_valid(self):
		return
	if Spielfluss.zum_level(nummer):
		return
	# Sollte nicht vorkommen – Tor wieder freigeben.
	scale = Vector3.ONE
	_ausgeloest = false
	if is_instance_valid(spieler) and "gesperrt" in spieler:
		spieler.gesperrt = false
