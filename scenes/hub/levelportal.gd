extends Node3D
class_name Levelportal
## Ein Levelportal im Portalraum – ein Tor pro Level.
##
## Der Zustand kommt aus `Spielfluss`:
##   OFFEN         – leuchtender Ring, wirbelnde Scheibe, Lichtfleck am
##                   Boden; Betreten startet das Level
##   VERSCHLOSSEN  – gebaut, aber noch nicht freigeschaltet: dunkler Ring
##                   und eine „schlafende" Scheibe, die sich kaum regt
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
## Kommt man einem offenen Tor nahe, erwacht es: Die Scheibe wird heller,
## die Zahl wächst ein wenig, und über dem Tor erscheint der Levelname. So
## steht der Name nur da, wo man ihn braucht – 25 Namen auf einmal wären
## eine Wand aus Schrift.
##
## LICHT OHNE PUNKTLICHT: Früher hatte jedes offene Tor ein OmniLight3D,
## jedes geschaffte ein zweites. Unter gl_compatibility zeichnet jedes
## Punktlicht alles in seiner Reichweite ein weiteres Mal, und ab acht
## Lichtern je Netz fallen welche weg – die Lichtflecken auf dem Raumboden
## sprangen beim Laufen an und aus. Jetzt liegt vor jedem offenen Tor ein
## additiver Lichtfleck, und den Schein um Ring und Scheibe legt das
## Glühen der Umgebung (Glow in Hub.tscn). Deshalb sind die leuchtenden
## Teile hier bewusst heller als 1: Nur was darüber liegt, glüht.
##
## `nummer`, `eigene_pfeiler`, `akzent` und `wirbel` müssen VOR
## `add_child()` gesetzt werden – `_ready()` baut daraus die gesamte Optik
## auf.

enum Zustand { OFFEN, VERSCHLOSSEN, IN_ARBEIT }

const RADIUS := 1.05          ## Innenradius des Rings
const RING_DICKE := 0.17
const MITTE_Y := 1.25         ## Höhe der Ringmitte über dem Boden
const ZONE_RADIUS := 0.95
const ZONE_HOEHE := 2.4
## Die beiden Pfeiler: Abstand zur Tormitte und Größe. Der Portalraum baut
## seine Säulenreihe genau um diese Kästen herum (siehe hub.gd).
const PFEILER_X := RADIUS + 0.62
const PFEILER_GROESSE := Vector3(0.52, 1.7, 0.52)

## Ab diesem Abstand (Meter) beginnt ein offenes Tor zu erwachen, ab dem
## zweiten ist es ganz wach. Den Namen zeigt nur das nächste Tor (siehe
## `_namenstor`) – bei 3,6 m Torabstand standen sonst zwei, drei Namen
## halb durchsichtig nebeneinander.
const NAH_BEGINN := 6.0
const NAH_VOLL := 4.0
## Dauer des Einsaugens beim Betreten.
const EINSAUG_ZEIT := 0.6
## Ruhewerte des Wirbelshaders (shaders/portal_wirbel.gdshader), zu denen
## ein abgebrochenes Betreten zurückkehrt.
const WIRBEL_DRALL := 4.0
const WIRBEL_SOG := 0.7
## Unter diesem Namen merkt sich der Baum das zuletzt betretene Level – der
## Portalraum setzt den Spieler bei der Rückkehr vor dessen Raum. Eine
## Metaangabe an der Wurzel überlebt den Szenenwechsel, gehört aber nicht
## zum Spielstand (nichts davon wird gespeichert). Je Speicherplatz: Wer
## nach Platz 1 ein neues Spiel beginnt, soll nicht vor dem Raum stehen,
## in dem er auf Platz 1 zuletzt war (siehe `letztes_level_schluessel`).
const LETZTES_LEVEL := "portalraum_letztes_level_%d"

## Die Levelnamen (aus CLAUDE.md). Sie stehen über dem Tor, sobald man
## davorsteht, und groß über der Blende beim Betreten.
const LEVEL_NAMEN := [
	"Wurzelschlucht", "Frostgrat", "Treibgut", "Katzensprung", "Hauerjagd",
	"Wettrennen", "Moorbrücken", "Torfstich", "Sumpfgeysir", "Hebewerk",
	"Steinschlag", "Kesselwerk", "Pfahlfeste", "Wolkensteg", "Abendruinen",
	"Kanalgrund", "Frostritt", "Schwarmpfad", "Sturmruinen", "Kolbengang",
	"Sandgrab", "Wolkenjagd", "Funkenlicht", "Neonhöhe", "Dächergasse",
]

## Levelnummer, 1-basiert.
var nummer := 1
## Ergibt sich in `_ready()` aus dem Spielfluss.
var zustand: Zustand = Zustand.IN_ARBEIT
## Sichtbare Steinpfeiler bauen. Der Portalraum schaltet das ab und
## zeichnet eine gemeinsame Bogenreihe für alle fünf Tore eines Raums –
## die Pfeiler zweier Nachbartore standen vorher ineinander. Die
## Kollision der Pfeiler bleibt in jedem Fall dieselbe.
var eigene_pfeiler := true
## Akzentfarbe des Raums. Färbt die schlafende Scheibe eines verschlossenen
## Tors; Alpha 0 heißt „keine" (dann Eisengrau).
var akzent := Color(0.0, 0.0, 0.0, 0.0)
## Farben des Wirbels in einem offenen Tor: [Grundton, Kern, Saum]. Leer
## heißt Portalgrün. Der Ring bleibt immer grün – er sagt „offen" –, der
## Wirbel darin sagt, wohin: Sonst hätten der Wurzelwald und „Sand und
## Neon" genau dasselbe Tor, und gerade das Tor ist, wohin das Auge zuerst
## geht.
var wirbel := PackedColorArray()

var _ring: MeshInstance3D = null
var _scheibe: MeshInstance3D = null
var _scheibenmaterial: ShaderMaterial = null
var _fleckmaterial: StandardMaterial3D = null
var _zahl: Label3D = null
var _name: Label3D = null
var _edelsteine: Array[Node3D] = []
var _scheinring: MeshInstance3D = null
var _scheinmaterial: StandardMaterial3D = null
var _spieler: Node3D = null
var _phase := 0.0
var _naehe := 0.0
var _namenssicht := 0.0
var _helligkeit := -1.0
var _ausgeloest := false

## Weicher Lichtfleck (einmal gebaut, von allen Toren geteilt).
static var _fleckbild: GradientTexture2D = null
## Das Tor, dessen Name gerade stehen darf, und sein Abstand zum Spieler.
## Jedes offene Tor vergleicht sich in `_erwachen` damit.
static var _namenstor: Levelportal = null
static var _namensabstand := INF


func _ready() -> void:
	add_to_group("levelportale")
	_phase = float(nummer) * 0.83
	zustand = _bestimme_zustand()

	_baue_pfeiler()
	_baue_ring()
	match zustand:
		Zustand.OFFEN:
			_baue_scheibe()
			_baue_lichtfleck()
		Zustand.VERSCHLOSSEN:
			_baue_schlafende_scheibe()
		_:
			_baue_bauplane()
	_baue_zahl()
	if zustand == Zustand.OFFEN:
		_baue_name()
	_baue_erfolg()
	if _name != null:
		var ueber_steinen := not _edelsteine.is_empty()
		_name.position = Vector3(0.0, _zahl_hoehe() + (1.55 if ueber_steinen else 0.78), 0.0)
	_baue_zone()

	set_process(zustand == Zustand.OFFEN or not _edelsteine.is_empty()
			or _scheinmaterial != null)


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


## Grundton des Wirbels und von allem, was von ihm ausgeht (Lichtfleck,
## Funken beim Betreten). Bei einem Tor ohne eigenen Wirbel der Grundton.
func wirbelfarbe() -> Color:
	if zustand == Zustand.OFFEN and wirbel.size() > 0:
		return wirbel[0]
	return farbe()


## Metaschlüssel für das zuletzt betretene Level des laufenden Speicherplatzes.
static func letztes_level_schluessel() -> String:
	return LETZTES_LEVEL % Spielfluss.aktueller_slot


## Name eines Levels (1-basiert), leer für unbekannte Nummern.
static func levelname(nr: int) -> String:
	if nr < 1 or nr > LEVEL_NAMEN.size():
		return ""
	return String(LEVEL_NAMEN[nr - 1])


## Höhe der Levelnummer. Mit der Bogenreihe des Portalraums sitzt über dem
## Ring ein Schlussstein – die Zahl rückt darüber.
func _zahl_hoehe() -> float:
	return MITTE_Y + RADIUS + (0.75 if eigene_pfeiler else 1.25)


# ------------------------------------------------------------------ Aufbau

## Zwei Pfeiler links und rechts – sie rahmen das Tor und geben ihm Halt im
## Raum. Kollision nur an den Pfeilern, der Durchgang bleibt frei.
func _baue_pfeiler() -> void:
	for wert in [-1.0, 1.0]:
		var seite := float(wert)
		var koerper := StaticBody3D.new()
		koerper.collision_layer = 1
		koerper.collision_mask = 0
		koerper.position = Vector3(seite * PFEILER_X, PFEILER_GROESSE.y * 0.5, 0.0)

		var form := BoxShape3D.new()
		form.size = PFEILER_GROESSE
		var kollision := CollisionShape3D.new()
		kollision.shape = form
		koerper.add_child(kollision)
		add_child(koerper)

		if not eigene_pfeiler:
			continue
		var wuerfel := BoxMesh.new()
		wuerfel.size = PFEILER_GROESSE
		var mi := MeshInstance3D.new()
		mi.mesh = wuerfel
		mi.material_override = Materialbibliothek.fels()
		koerper.add_child(mi)

		# Leuchtende Kappe – bei offenen Toren farbig, sonst matt
		var kappe := MeshInstance3D.new()
		var kappen_mesh := BoxMesh.new()
		kappen_mesh.size = Vector3(0.66, 0.16, 0.66)
		kappe.mesh = kappen_mesh
		kappe.position = Vector3(seite * PFEILER_X, 1.78, 0.0)
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
	# 48 × 12 statt 16 × 6: Der Ring ist die hellste Kante im Bild, und mit
	# Glühen zeichnet sich jede Facette als Zacke im Schein ab.
	torus.rings = 48
	torus.ring_segments = 12

	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = torus
	_ring.position = Vector3(0.0, MITTE_Y, 0.0)
	_ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if zustand == Zustand.OFFEN:
		# Über 1, damit er glüht (siehe Kopfkommentar).
		_ring.material_override = Materialbibliothek.leuchtend(farbe(), 2.2)
	else:
		_ring.material_override = Materialbibliothek.einfarbig(farbe(), 0.75, 0.25)
	add_child(_ring)


## Wirbelnde Scheibe im offenen Tor. Ein Viereck mit dem Wirbel-Shader
## statt eines Zylinders: Der Kreis entsteht im Shader, und der Wirbel läuft
## über TIME – pro Bild setzt das Skript nur noch `puls`.
func _baue_scheibe() -> void:
	_scheibe = _scheibenviereck()
	if wirbel.size() >= 3:
		_scheibenmaterial = Effekte.wirbelstoff(wirbel[0], wirbel[1], wirbel[2])
	else:
		_scheibenmaterial = Effekte.wirbelstoff(farbe())
	_scheibe.material_override = _scheibenmaterial
	add_child(_scheibe)


## Ein verschlossenes Tor schläft: Dieselbe Scheibe, aber dunkel, fast
## still und im kühlen Siegelton des Raums – derselbe Ton wie der Schleier
## vor dem Raum (hub.gd). Vorher saßen hier drei Gitterstäbe, ein Riegel
## und ein Schloss: fünf Netze je Tor, und zwanzig vergitterte Tore lasen
## sich beim ersten Betreten wie ein Gefängnis.
func _baue_schlafende_scheibe() -> void:
	var ton := akzent if akzent.a > 0.0 else Farben.KISTE_EISEN
	var schlaf := ton.lerp(Farben.KISTE_ZEIT, 0.5).darkened(0.35)
	_scheibe = _scheibenviereck()
	var stoff := Effekte.wirbelstoff(schlaf)
	stoff.set_shader_parameter("helligkeit", 0.6)
	stoff.set_shader_parameter("tempo", 0.12)
	stoff.set_shader_parameter("deckkraft", 0.85)
	stoff.set_shader_parameter("sog", 0.15)
	stoff.set_shader_parameter("puls", 0.0)
	_scheibe.material_override = stoff
	add_child(_scheibe)


func _scheibenviereck() -> MeshInstance3D:
	var flaeche := QuadMesh.new()
	flaeche.size = Vector2(RADIUS * 2.0, RADIUS * 2.0)
	var mi := MeshInstance3D.new()
	mi.name = "Scheibe"
	mi.mesh = flaeche
	mi.position = Vector3(0.0, MITTE_Y, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Lichtfleck am Boden vor dem Tor – ersetzt das Punktlicht. Additiv und
## ungeschattet, deshalb wirkt er auch im Schatten der Rückwand.
func _baue_lichtfleck() -> void:
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(3.1, 2.3)
	var fleck := MeshInstance3D.new()
	fleck.name = "Lichtfleck"
	fleck.mesh = ebene
	fleck.position = Vector3(0.0, 0.035, 0.7)
	fleck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fleckmaterial = StandardMaterial3D.new()
	_fleckmaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fleckmaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fleckmaterial.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_fleckmaterial.disable_receive_shadows = true
	_fleckmaterial.albedo_texture = _fleck_textur()
	_fleckmaterial.albedo_color = _fleckfarbe(0.5)
	fleck.material_override = _fleckmaterial
	add_child(fleck)


## Farbe des Lichtflecks bei Puls `p` (0..1). Geschaffte Tore mischen Gold
## hinein, damit auch der Boden sagt, dass man hier schon war.
func _fleckfarbe(p: float) -> Color:
	var ton := wirbelfarbe()
	if Spielfluss.geschafft.has(nummer):
		ton = ton.lerp(Farben.ERFOLG_SCHEIN, 0.55)
	var k := (0.42 + 0.16 * p) * (1.0 + 0.6 * _naehe)
	return Color(ton.r * k, ton.g * k, ton.b * k, 1.0)


static func _fleck_textur() -> GradientTexture2D:
	if _fleckbild == null:
		var verlauf := Gradient.new()
		verlauf.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
		verlauf.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6),
				Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
		_fleckbild = GradientTexture2D.new()
		_fleckbild.gradient = verlauf
		_fleckbild.fill = GradientTexture2D.FILL_RADIAL
		_fleckbild.fill_from = Vector2(0.5, 0.5)
		_fleckbild.fill_to = Vector2(1.0, 0.5)
		_fleckbild.width = 64
		_fleckbild.height = 64
	return _fleckbild


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
	_zahl = Label3D.new()
	_zahl.name = "Nummer"
	_zahl.text = "%02d" % nummer
	# Die Zählschrift: gleich breite, kräftige Ziffern – „11" und „18"
	# stehen damit genauso ruhig über dem Tor wie „08".
	_zahl.font = UiStil.schrift(&"zahl")
	_zahl.font_size = 96
	_zahl.outline_size = 20
	_zahl.pixel_size = 0.0096
	match zustand:
		Zustand.OFFEN:
			_zahl.modulate = Farben.UI_HELL
		Zustand.VERSCHLOSSEN:
			_zahl.modulate = Color(0.66, 0.66, 0.72)
		_:
			_zahl.modulate = Color(0.6, 0.58, 0.54)
	_zahl.outline_modulate = Farben.UI_KONTUR
	_zahl.position = Vector3(0.0, _zahl_hoehe(), 0.0)
	add_child(_zahl)


## Levelname über dem Tor – unsichtbar, bis man davorsteht. Er sitzt
## dicht über der Nummer; nur wenn Edelsteine darüber schweben, rückt er
## über sie. Kräftige Kontur, weil hinter ihm Baumkronen und Rückwand
## liegen – mit dünner Kontur las er sich wie ein Aufdruck auf der Mauer.
func _baue_name() -> void:
	_name = Label3D.new()
	_name.name = "Levelname"
	_name.text = levelname(nummer)
	_name.font = UiStil.schrift(&"titel")
	_name.font_size = 48
	_name.outline_size = 18
	_name.pixel_size = 0.0068
	_name.render_priority = 2
	_name.outline_render_priority = 1
	_name.modulate = Color(Farben.UI_GOLD_HELL, 0.0)
	_name.outline_modulate = Color(Farben.UI_KONTUR, 0.0)
	_name.visible = false
	add_child(_name)


## Schein für geschaffte Level, Edelsteine für die beiden Kunststücke.
func _baue_erfolg() -> void:
	if not Spielfluss.geschafft.has(nummer):
		return
	var eintrag: Dictionary = Spielfluss.geschafft[nummer]

	_baue_schein()

	# --- Edelsteine über dem Tor ---
	var steine: Array[Color] = []
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


## Warmer Schein um das ganze Tor: ein breiter, halbdurchsichtiger Ring
## hinter dem Rahmen. Das zweite Punktlicht von früher ist weg (siehe
## Kopfkommentar); den Boden färbt der goldene Lichtfleck.
func _baue_schein() -> void:
	_scheinring = MeshInstance3D.new()
	_scheinring.name = "Schein"
	var scheibe := TorusMesh.new()
	scheibe.inner_radius = RADIUS + RING_DICKE * 0.2
	scheibe.outer_radius = RADIUS + RING_DICKE * 4.6
	scheibe.rings = 32
	scheibe.ring_segments = 10
	_scheinring.mesh = scheibe
	_scheinring.position = Vector3(0.0, MITTE_Y, -0.04)
	_scheinring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# Flach gedrückt: Ein runder Wulst stach vorn durch die Bogensteine
	# des Portalraums und überzog sie cremeweiß.
	_scheinring.scale = Vector3(1.0, 0.3, 1.0)
	_scheinring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Additiv und ungeschattet: Nur so liest sich der Ring als Licht und
	# nicht als graue Scheibe. ACHTUNG: Ungeschattete Materialien geben unter
	# gl_compatibility nur ihre Grundfarbe aus, die Eigenleuchtkraft fällt
	# weg – das Atmen läuft deshalb über `albedo_color` (siehe _process).
	_scheinmaterial = StandardMaterial3D.new()
	_scheinmaterial.albedo_color = _scheinfarbe(0.5)
	_scheinmaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_scheinmaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scheinmaterial.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_scheinmaterial.cull_mode = BaseMaterial3D.CULL_DISABLED
	_scheinmaterial.disable_receive_shadows = true
	_scheinring.material_override = _scheinmaterial
	add_child(_scheinring)


func _scheinfarbe(schwelle: float) -> Color:
	var k := 0.9 + schwelle * 0.5
	var s := Farben.ERFOLG_SCHEIN
	return Color(s.r * k, s.g * k, s.b * k, 0.22 + schwelle * 0.12)


## Die Bestzeit unter der Levelnummer. Sie steht klein und matt da: Wer
## sie sucht, findet sie; wer nur zum nächsten Tor läuft, wird von ihr
## nicht aufgehalten.
func _baue_bestzeit(sekunden: float, stufe: int) -> void:
	var schild := Label3D.new()
	schild.name = "Bestzeit"
	schild.text = Zeitlauf.als_text(sekunden)
	schild.font = UiStil.schrift(&"zahl")
	schild.font_size = 44
	schild.pixel_size = 0.0032
	schild.modulate = Zeitlauf.stufen_farbe(stufe) if stufe > 0 \
			else Color(0.82, 0.80, 0.74)
	schild.outline_size = 12
	schild.outline_modulate = Farben.UI_KONTUR
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Zwischen Torbogen und Levelnummer. Unter den Ring gehört sie nicht:
	# Dort ist der Boden, und die Schrift steckte darin. Mit der Bogenreihe
	# des Portalraums steht sie vor dem Schlussstein wie auf einer Tafel.
	if eigene_pfeiler:
		schild.position = Vector3(0.0, MITTE_Y + RADIUS + 0.32, 0.0)
	else:
		schild.position = Vector3(0.0, MITTE_Y + RADIUS + 0.62, 0.42)
	add_child(schild)


func _baue_edelstein(ton: Color, seitlich: float) -> Node3D:
	var stein := Node3D.new()
	stein.name = "Edelstein"
	stein.position = Vector3(seitlich, _edelstein_hoehe(), 0.0)
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


func _edelstein_hoehe() -> float:
	return _zahl_hoehe() + 0.82


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
	if zustand == Zustand.OFFEN and not _ausgeloest:
		_erwachen(delta)
	for i in _edelsteine.size():
		var stein := _edelsteine[i]
		if not is_instance_valid(stein):
			continue
		stein.rotation.y += delta * 1.4
		# Gegenläufig versetzt schweben, damit zwei Steine nicht im
		# Gleichschritt wippen.
		stein.position.y = _edelstein_hoehe() \
				+ sin(_phase * 1.7 + float(i) * 2.1) * 0.09
	if _scheinmaterial != null:
		_scheinmaterial.albedo_color = _scheinfarbe(0.5 + 0.5 * sin(_phase * 1.6))


## Atmen und Nähe eines offenen Tors.
func _erwachen(delta: float) -> void:
	var puls := 0.5 + 0.5 * sin(_phase * 2.9)
	if _spieler == null or not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	var ziel := 0.0
	var abstand := INF
	if _spieler != null:
		abstand = global_position.distance_to(_spieler.global_position)
		ziel = clampf(inverse_lerp(NAH_BEGINN, NAH_VOLL, abstand), 0.0, 1.0)
	_naehe = move_toward(_naehe, ziel, delta * 2.5)

	if is_instance_valid(_scheibe):
		var s := 0.94 + puls * 0.06
		_scheibe.scale = Vector3(s, s, 1.0)
	if _scheibenmaterial != null:
		_scheibenmaterial.set_shader_parameter("puls", puls)
		# Die Helligkeit ändert sich nur beim Näherkommen – dann erst setzen.
		var hell := snappedf(1.25 + 0.7 * _naehe, 0.01)
		if hell != _helligkeit:
			_helligkeit = hell
			_scheibenmaterial.set_shader_parameter("helligkeit", hell)
	if _fleckmaterial != null:
		_fleckmaterial.albedo_color = _fleckfarbe(puls)
	if _zahl != null:
		_zahl.scale = Vector3.ONE * (1.0 + 0.12 * _naehe)
	if _name != null:
		var ziel_sicht := _naehe if _name_frei(abstand) else 0.0
		_namenssicht = move_toward(_namenssicht, ziel_sicht, delta * 3.0)
		_name.visible = _namenssicht > 0.01
		_name.modulate.a = _namenssicht
		_name.outline_modulate.a = _namenssicht * Farben.UI_KONTUR.a


## Darf dieses Tor seinen Namen zeigen? Nur das dem Spieler nächste offene
## Tor. Ein anderes übernimmt erst, wenn es ein Stück näher ist – sonst
## flackerte der Name genau zwischen zwei Toren hin und her.
func _name_frei(abstand: float) -> bool:
	var halter_da := _namenstor != null and is_instance_valid(_namenstor) \
			and not _namenstor._ausgeloest
	if halter_da and _namenstor == self:
		if abstand > NAH_BEGINN:
			_namenstor = null
			return false
		_namensabstand = abstand
		return true
	if abstand < NAH_BEGINN and (not halter_da or abstand < _namensabstand - 0.4):
		_namenstor = self
		_namensabstand = abstand
		return true
	return false


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


## Das Tor saugt den Spieler ein, eine Kreisblende schließt sich auf der
## Scheibe, dann startet das Level. Vorher wuchs das ganze Tor samt
## Steinpfeilern auf 1,3 und die Szene brach hart zum Ladebildschirm ab.
func _eintreten(spieler: Node3D) -> void:
	if "gesperrt" in spieler:
		spieler.gesperrt = true
	var figur := spieler as CharacterBody3D
	if figur != null:
		figur.velocity = Vector3.ZERO
	# Physik anhalten, damit die Schwerkraft nicht gegen das Einsaugen zieht.
	spieler.set_physics_process(false)
	var schluessel := letztes_level_schluessel()
	get_tree().root.set_meta(schluessel, nummer)

	var mitte := to_global(Vector3(0.0, MITTE_Y, 0.0))
	var ton := wirbelfarbe()
	Effekte.aufblitzen(self, mitte, ton.lightened(0.35), 2.6, 0.3)
	Effekte.funken(self, mitte, ton, 22, 4.0, 0.2)
	Effekte.ring(self, to_global(Vector3(0.0, 0.08, 0.4)), ton, 2.4, 0.45)
	Klang.spiele("checkpoint", 0.8)

	var modell := spieler.get_node_or_null("Modell") as Node3D
	var modell_skala := modell.scale if modell != null else Vector3.ONE
	var start_drehung := spieler.rotation.y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spieler, "global_position", mitte, EINSAUG_ZEIT) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(spieler, "rotation:y", start_drehung + TAU * 2.0,
			EINSAUG_ZEIT)
	if modell != null:
		tween.tween_property(modell, "scale", modell_skala * 0.05, EINSAUG_ZEIT) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Nur Scheibe und Ring wachsen – die Steine bleiben, wo sie sind.
	for teil: Node3D in [_scheibe, _ring]:
		if is_instance_valid(teil):
			tween.tween_property(teil, "scale", teil.scale * 1.2, EINSAUG_ZEIT) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _scheibenmaterial != null and is_instance_valid(_scheibe):
		var hell_start := _helligkeit if _helligkeit > 0.0 else 1.25
		tween.tween_method(_scheibe_aufdrehen.bind(hell_start), 0.0, 1.0, EINSAUG_ZEIT)
		# Schneller drehen über den Knoten, nicht über `tempo` (siehe unten).
		# Positiv um Z ist der Drehsinn des Wirbels, von vorn gesehen.
		tween.tween_property(_scheibe, "rotation:z", TAU * 1.5, EINSAUG_ZEIT) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var name_text := levelname(nummer)
	var blende := _blende_anlegen(name_text)
	var kamera := get_viewport().get_camera_3d()
	if blende != null and kamera != null and not kamera.is_position_behind(mitte):
		blende.iris_zu(kamera.unproject_position(mitte), EINSAUG_ZEIT + 0.12)
	if blende == null:
		# Ohne Blende steht der Name als Meldung im HUD.
		GameState.zeige_nachricht("Level %02d · %s" % [nummer, name_text] \
				if not name_text.is_empty() else "Level %02d" % nummer, 1.4)

	await tween.finished
	if not is_instance_valid(self):
		return
	if Spielfluss.zum_level(nummer):
		return

	# Sollte nicht vorkommen – Tor und Figur wieder freigeben.
	get_tree().root.remove_meta(schluessel)
	if blende != null:
		blende.auf(0.2)
		var schicht := blende.get_parent()
		if schicht != null:
			get_tree().create_timer(0.3).timeout.connect(schicht.queue_free)
	for teil: Node3D in [_scheibe, _ring]:
		if is_instance_valid(teil):
			teil.scale = Vector3.ONE
	if is_instance_valid(_scheibe):
		_scheibe.rotation.z = 0.0
	if _scheibenmaterial != null:
		_scheibenmaterial.set_shader_parameter("drall", WIRBEL_DRALL)
		_scheibenmaterial.set_shader_parameter("sog", WIRBEL_SOG)
		# Den Merkwert verwerfen, sonst hielte `_erwachen` die hochgedrehte
		# Helligkeit für schon gesetzt.
		_helligkeit = -1.0
	_ausgeloest = false
	if is_instance_valid(spieler):
		spieler.set_physics_process(true)
		if modell != null and is_instance_valid(modell):
			modell.scale = modell_skala
		if "gesperrt" in spieler:
			spieler.gesperrt = false


## Der Wirbel dreht beim Betreten auf: Die Arme wickeln sich enger
## (`drall`), die Mitte zieht heller (`sog`), alles wird heller.
##
## NIE über `tempo` oder `richtung`: Der Shader rechnet `TIME * tempo`, und
## TIME zählt seit Spielstart. Jede Änderung von `tempo` ließe den Winkel
## um TIME·Δtempo springen – nach fünf Minuten Spielzeit um mehrere
## Umdrehungen je Bild. Die Scheibe flackerte dann wild, statt schneller zu
## werden. Das Schnellerwerden übernimmt die Drehung des Knotens.
func _scheibe_aufdrehen(anteil: float, hell_start: float) -> void:
	if _scheibenmaterial == null:
		return
	_scheibenmaterial.set_shader_parameter("helligkeit", lerpf(hell_start, 3.4, anteil))
	_scheibenmaterial.set_shader_parameter("drall", lerpf(WIRBEL_DRALL, 10.0, anteil))
	_scheibenmaterial.set_shader_parameter("sog", lerpf(WIRBEL_SOG, 2.0, anteil))


## Eigene Blende über dem HUD, unter dem Ladebildschirm. Sie hängt an der
## laufenden Szene und verschwindet mit ihr. Der Levelname steht auf
## derselben Schicht ÜBER der Blende: Als Meldung im HUD lag er unter ihr,
## und die Iris schluckte ihn, kaum dass er erschienen war.
func _blende_anlegen(name_text: String) -> UiStil.Blende:
	var szene := get_tree().current_scene
	if szene == null:
		return null
	var schicht := CanvasLayer.new()
	schicht.name = "Portalblende"
	schicht.layer = 50
	var blende := UiStil.Blende.new(Farben.UI_NACHT)
	schicht.add_child(blende)

	var titel := Control.new()
	titel.name = "Levelname"
	titel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var kopf := "LEVEL %02d" % nummer
	titel.draw.connect(func() -> void:
		var feld := titel.size
		var x := feld.x * 0.5
		var y := feld.y * 0.7
		UiStil.text(titel, Vector2(x, y), kopf, UiStil.GROESSE_KNOPF,
				Farben.UI_GOLD_HELL, &"sperr", -1, HORIZONTAL_ALIGNMENT_CENTER)
		if not name_text.is_empty():
			UiStil.text(titel, Vector2(x, y + 62.0), name_text, UiStil.GROESSE_TITEL,
					Farben.UI_HELL, &"titel", -1, HORIZONTAL_ALIGNMENT_CENTER))
	schicht.add_child(titel)
	szene.add_child(schicht)
	UiStil.einschweben(titel, Vector2(0.0, 22.0), 0.4, 0.08)
	return blende
