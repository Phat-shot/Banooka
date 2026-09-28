extends Area3D
class_name Frucht
## Sammelbare Waldfrucht. 100 Stück ergeben ein Extraleben.
##
## Früchte können frei im Level stehen oder von zerbrochenen Kisten
## erzeugt werden (siehe `streuen`).
##
## Optik: EIN Netz mit EINER Fläche für alle Früchte des Spiels – Beere,
## Stiel und zwei Blätter, gefärbt über Scheitelfarben. Level 01 hat rund
## 90 Früchte; vorher waren es je zwei Flächen (Beere, Blatt) mit Schatten
## in vier Stufen, also bis zu zehn Zeichenaufrufe je Frucht, jetzt einer.
## Schatten wirft sie keinen: Sie schwebt und wippt, ein Fleck darunter
## zuckte nur mit, und die Vorbilder zeigen ihre Früchte ebenso.

const FRUCHT_SZENE := preload("res://scenes/fruits/Frucht.tscn")

## Anziehungsradius: ab hier fliegt die Frucht zum Spieler.
const MAGNET_RADIUS := 2.6
const MAGNET_TEMPO := 9.0

## Anfangsgeschwindigkeit, wenn die Frucht aus einer Kiste geschleudert wird.
var wurf := Vector3.ZERO
## Solange > 0 fliegt die Frucht frei und wird nicht angezogen.
var _flugzeit := 0.0
## Höhe beim Abwurf (gemerkt im ersten Flugbild: `streuen` setzt die
## Position erst nach dem Einhängen, `_ready` kennt sie noch nicht).
var _abwurf_y := INF
var _phase := 0.0
var _eingesammelt := false
## Gemerkter Spieler: Eine Gruppensuche je Frucht und Bild kostete bei
## neunzig Früchten neunzig Suchen je Bild.
var _spieler: Node3D = null

@onready var _modell: Node3D = $Modell

# Einmal gebaut, von allen Früchten geteilt. Beide NIE verändern – der
# `Leuchtmarker` (Level 23) kopiert das Material, bevor er es ändert.
static var _netz: ArrayMesh = null
static var _stoff: StandardMaterial3D = null


func _ready() -> void:
	_baue_modell()
	add_to_group("fruechte")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	body_entered.connect(_auf_koerper)
	_phase = randf() * TAU
	if wurf != Vector3.ZERO:
		_flugzeit = 0.6
		# Aus der Kiste geschleudert: klein heraus und aufploppen. Sonst
		# stünde die Frucht im ersten Bild in voller Größe in der Kiste.
		_modell.scale = Vector3.ONE * 0.3
		create_tween().tween_property(_modell, "scale", Vector3.ONE, 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _baue_modell() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Beere"
	mi.mesh = _netz_holen()
	mi.material_override = _stoff_holen()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modell.add_child(mi)


func _process(delta: float) -> void:
	_phase += delta * 3.0
	if _eingesammelt:
		# Während des Aufploppens der Figur folgen – eine Frucht, die an
		# der Sammelstelle stehen bleibt, sähe aus wie liegen gelassen.
		if is_instance_valid(_spieler):
			var hin := _spieler.global_position + Vector3.UP * 0.6
			global_position = global_position.move_toward(hin, MAGNET_TEMPO * 1.5 * delta)
		return

	if is_instance_valid(_modell):
		_modell.rotation.y += delta * 2.6
		_modell.position.y = sin(_phase) * 0.12

	if _flugzeit > 0.0:
		# Frisch aus einer Kiste geschleudert: kurzer Wurfbogen
		if _abwurf_y == INF:
			_abwurf_y = global_position.y
		_flugzeit -= delta
		wurf.y += -24.0 * delta
		global_position += wurf * delta
		# Der Bogen endet auf Abwurfhöhe. Die volle Flugzeit trug die Frucht
		# fast einen Meter tiefer – halb in den Boden neben der Kiste, und
		# über einer Lücke hinab ins Leere.
		if wurf.y < 0.0 and global_position.y <= _abwurf_y:
			global_position.y = _abwurf_y
			_flugzeit = 0.0
		return

	if not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null:
			return
	var ziel := _spieler.global_position + Vector3.UP * 0.6
	var abstand := global_position.distance_to(ziel)
	if abstand < MAGNET_RADIUS:
		global_position = global_position.move_toward(ziel, MAGNET_TEMPO * delta)
		if abstand < 0.5:
			_einsammeln()


func _auf_koerper(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler"):
		_einsammeln()


func _einsammeln() -> void:
	if _eingesammelt:
		return
	_eingesammelt = true
	# Sofort aus Zählung und Treffern nehmen: Die Frucht lebt noch einen
	# Wimpernschlag fürs Aufploppen, zählt aber schon nicht mehr.
	remove_from_group("fruechte")
	set_deferred("monitoring", false)
	# Wer eine Reihe Früchte abräumt, hört eine Tonleiter statt zehnmal
	# denselben Ton.
	Klang.spiele_folge("frucht")
	GameState.frucht_einsammeln(1)

	# Funkeln und Plopp: kurz aufblähen, dann in nichts. Die Funken hängen
	# an der Szene, nicht an der Frucht (siehe `Effekte`) – sie überleben
	# deren `queue_free`.
	var ort := _modell.global_position if is_instance_valid(_modell) else global_position
	Effekte.aufblitzen(self, ort, Color(1.0, 0.85, 0.5), 0.75, 0.1)
	Effekte.funken(self, ort, Farben.FRUCHT.lightened(0.2), 7, 3.0, 0.16)
	if not is_instance_valid(_modell):
		queue_free()
		return
	var t := create_tween()
	t.tween_property(_modell, "scale", Vector3.ONE * 1.5, 0.05) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_modell, "scale", Vector3.ZERO, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


## Erzeugt `anzahl` Früchte an `pos` und schleudert sie auseinander.
static func streuen(elternteil: Node, pos: Vector3, anzahl: int = 1) -> void:
	if elternteil == null or not is_instance_valid(elternteil):
		return
	for i in anzahl:
		var f := FRUCHT_SZENE.instantiate() as Frucht
		var winkel := TAU * float(i) / maxf(float(anzahl), 1.0) + randf() * 0.6
		var streuung := 2.2 if anzahl > 1 else 0.0
		f.wurf = Vector3(cos(winkel) * streuung, 5.0 + randf() * 1.5, sin(winkel) * streuung)
		elternteil.add_child(f)
		f.global_position = pos + Vector3.UP * 0.3


# ---------------------------------------------------------------- Netz

## Maße der Beere (halbe Breite und halbe Höhe) – etwas breiter als hoch,
## wie eine reife Aprikose.
const BEERE_R := 0.24
const BEERE_H := 0.215

## Das Material: Farbe aus den Scheiteln, Eigenleuchten nur für die Beere.
##
## `StandardMaterial3D` kennt kein Leuchten je Scheitel. Deshalb eine
## Leuchtmaske: ein Bild aus zwei Pixeln (weiß | schwarz), und die UV
## jedes Scheitels zeigt auf eines davon. Mit multipliziertem Leuchten
## glüht die Beere und das Blatt nicht – so bleibt es bei einer Fläche.
## Ein eigener Shader ginge auch, aber dann ließe der `Leuchtmarker` die
## Frucht im Dunkellevel aus (er fasst nur `StandardMaterial3D` an).
static func _stoff_holen() -> StandardMaterial3D:
	if _stoff != null:
		return _stoff
	var bild := Image.create(2, 1, false, Image.FORMAT_RGB8)
	bild.set_pixel(0, 0, Color.WHITE)
	bild.set_pixel(1, 0, Color.BLACK)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	# Scheitelfarben werden wie `albedo_color` als sRGB gelesen – so hat die
	# Beere genau den Ton von `Farben.FRUCHT`, wie das Symbol im HUD.
	m.vertex_color_is_srgb = true
	m.roughness = 0.42
	m.emission_enabled = true
	m.emission = Farben.FRUCHT
	m.emission_energy_multiplier = 0.45
	m.emission_texture = ImageTexture.create_from_image(bild)
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# Ein warmer Saum gegen das Licht: Die Frucht löst sich damit auch vor
	# dem dunklen Schluchtgrund, ohne heller zu werden.
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	_stoff = m
	return m


static func _netz_holen() -> ArrayMesh:
	if _netz != null:
		return _netz
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_beere(st)
	_stiel(st)
	_blatt(st, 0.35, 0.21, 0.085, 0.9)
	_blatt(st, 0.35 + PI * 0.92, 0.15, 0.06, 0.7)
	st.generate_normals()
	st.index()
	_netz = st.commit()
	return _netz


## Die Beere: eine leicht gedrückte Kugel mit Mulde am Stielansatz und
## einer flachen Naht an einer Seite. Farbe: oben goldener, unten und auf
## der Nahtseite röter – so wirkt sie rund, auch wo das Licht flach ist.
static func _beere(st: SurfaceTool) -> void:
	var ringe := 10
	var segmente := 16
	var gold := Farben.FRUCHT.lerp(Color(1.0, 0.8, 0.3), 0.4)
	var rot := Farben.FRUCHT.lerp(Color(0.92, 0.26, 0.1), 0.45)
	# Glatt schattiert: Scheitel an derselben Stelle teilen sich die Normale.
	st.set_smooth_group(0)
	st.set_uv(Vector2(0.25, 0.5))            # Leuchtmaske: weiß
	var punkt := func(ring: int, seg: int) -> Vector3:
		var th := PI * float(ring) / float(ringe)
		var ph := TAU * float(seg % segmente) / float(segmente)
		var s := sin(th)
		var c := cos(th)
		# Naht: eine flache Rinne entlang eines Längengrads.
		var naht := 1.0 - 0.07 * exp(-pow(wrapf(ph, -PI, PI) / 0.3, 2.0)) * s
		# Mulde oben, wo der Stiel sitzt.
		var mulde := 1.0 - 0.28 * exp(-pow(th / 0.42, 2.0))
		return Vector3(cos(ph) * s * BEERE_R * naht, c * BEERE_H * mulde,
				sin(ph) * s * BEERE_R * naht)
	var farbe := func(p: Vector3) -> Color:
		var hoch := clampf(p.y / BEERE_H * 0.5 + 0.5, 0.0, 1.0)
		var seite := clampf(p.x / BEERE_R, 0.0, 1.0)
		var c := Farben.FRUCHT.lerp(gold, smoothstep(0.55, 1.0, hoch))
		c = c.lerp(rot, maxf(smoothstep(0.45, 0.0, hoch), seite * 0.5))
		return c
	for r in ringe:
		for i in segmente:
			var a: Vector3 = punkt.call(r, i)
			var b: Vector3 = punkt.call(r, i + 1)
			var c: Vector3 = punkt.call(r + 1, i + 1)
			var d: Vector3 = punkt.call(r + 1, i)
			# An den Polen fällt je ein Dreieck des Vierecks in einen Punkt.
			var ecken: Array[Vector3] = []
			if r > 0:
				ecken.append_array([a, c, b])
			if r < ringe - 1:
				ecken.append_array([a, d, c])
			for p in ecken:
				st.set_color(farbe.call(p))
				st.add_vertex(p)


## Kurzer, leicht schräger Stiel aus der Mulde.
static func _stiel(st: SurfaceTool) -> void:
	st.set_smooth_group(-1)                  # kantig, er ist winzig
	st.set_uv(Vector2(0.75, 0.5))            # Leuchtmaske: schwarz
	var braun := Color(0.36, 0.22, 0.1)
	var unten := Vector3(0.0, BEERE_H * 0.72, 0.0)
	var oben := Vector3(0.035, BEERE_H + 0.1, 0.0)
	var n := 5
	for i in n:
		var w0 := TAU * float(i) / float(n)
		var w1 := TAU * float(i + 1) / float(n)
		var a := unten + Vector3(cos(w0), 0.0, sin(w0)) * 0.024
		var b := unten + Vector3(cos(w1), 0.0, sin(w1)) * 0.024
		var c := oben + Vector3(cos(w1), 0.0, sin(w1)) * 0.016
		var d := oben + Vector3(cos(w0), 0.0, sin(w0)) * 0.016
		for p: Vector3 in [a, b, c, a, c, d]:
			st.set_color(braun)
			st.add_vertex(p)
		for p: Vector3 in [oben, d, c]:
			st.set_color(braun)
			st.add_vertex(p)


## Ein Blatt am Stiel: spitz, in der Mitte gefaltet, zur Spitze hin
## hängend. Beidseitig gebaut (Ober- und Unterseite), damit es von unten
## nicht verschwindet – das Material schneidet Rückseiten weg.
## `winkel` Richtung um die Hochachse, `laenge`/`breite` in Metern,
## `hebung` wie steil es vom Stiel absteht (1 = wie das erste Blatt).
static func _blatt(st: SurfaceTool, winkel: float, laenge: float, breite: float,
		hebung: float) -> void:
	st.set_smooth_group(-1)
	st.set_uv(Vector2(0.75, 0.5))
	var hell := Farben.FRUCHT_BLATT.lightened(0.18)
	var dunkel := Farben.FRUCHT_BLATT.darkened(0.15)
	var dreh := Basis(Vector3.UP, winkel)
	var fuss := Vector3(0.02, BEERE_H + 0.07, 0.0)
	# Punkte in Blattrichtung +X: Fuß, zwei Flanken, Spitze.
	var spitze := Vector3(laenge, 0.03 * hebung - 0.05, 0.0)
	var links := Vector3(laenge * 0.45, 0.07 * hebung - 0.012, -breite)
	var rechts := Vector3(laenge * 0.45, 0.07 * hebung - 0.012, breite)
	var rippe := Vector3(laenge * 0.45, 0.07 * hebung + 0.012, 0.0)
	var pkt := func(v: Vector3) -> Vector3:
		return fuss + dreh * v
	var dicke := Vector3(0.0, -0.006, 0.0)
	var oben: Array = [
		[Vector3.ZERO, links, rippe], [rippe, links, spitze],
		[Vector3.ZERO, rippe, rechts], [rippe, spitze, rechts],
	]
	for dreieck: Array in oben:
		# Oberseite
		for p: Vector3 in [dreieck[0], dreieck[1], dreieck[2]]:
			st.set_color(hell if p == rippe else Farben.FRUCHT_BLATT)
			st.add_vertex(pkt.call(p))
		# Unterseite: umgekehrt gewickelt, ein Hauch tiefer, dunkler.
		for p: Vector3 in [dreieck[0], dreieck[2], dreieck[1]]:
			st.set_color(dunkel)
			st.add_vertex(pkt.call(p + dicke))
