extends Node3D
class_name Geschoss
## Ein geworfenes Ding, das im Bogen fliegt – Wurfstamm oder Tontopf.
##
## Bewusst kein `Gegner`, sondern ein eigenständiger Knoten: Der `Werfer`
## benutzt es, aber jeder andere Gegner kann es genauso abschießen. Es
## patrouilliert nicht, es lebt nur seinen Bogen zu Ende.
##
## ABWEHR MIT DEM DREHSCHLAG – das ist der Kern des Bauteils:
## Im Vorbild ist die Antwort auf ein geworfenes Ding nicht Weglaufen,
## sondern es im Flug wegzuschlagen. Dafür fragt das Geschoss selbst jeden
## Frame `spieler.angriffe() & Angriff.SPIN` ab (das ist genau das Bit,
## das `player.gd` setzt, solange `spinning > 0.0` läuft) und misst den
## Abstand gegen `abwehr_radius`. Über die eigene `Area3D` allein ginge
## das nicht: Die meldet Berührung erst, wenn das Geschoss schon am Körper
## klebt – der Drehschlag greift aber 1,7 m weit, und genau so weit soll
## auch die Abwehr reichen. Der Spieler prüft umgekehrt nur die Gruppen
## "kisten" und "gegner"; ein Geschoss gehört in keine von beiden, also
## muss es sich selbst zuständig fühlen.
##
## Ein abgewehrtes Geschoss ist harmlos und schlägt auf dem Rückweg sogar
## Gegner um, die per Drehschlag zu besiegen sind – der Schlag geht nicht
## ins Leere, er wird weitergereicht.

## Wurfarten – bestimmen nur die Optik und den Aufprallklang.
enum Art {STAMM, TOPF}

## Waagerechtes Reisetempo in m/s. Siehe `abschiessen()`: Die Höhe des
## Bogens ergibt sich daraus, nicht umgekehrt.
@export var tempo := 9.0
## Fallbeschleunigung des Geschosses (eigener Wert, nicht die Spieler-G:
## ein flacherer Bogen ist besser zu lesen als der Sprung der Figur).
@export var schwere := -18.0
## Halbmesser des Geschosses – Optik und Trefferzone hängen daran.
@export var radius := 0.28
## Nach so vielen Sekunden verschwindet es auch ohne Aufschlag.
@export var lebensdauer := 5.0
## Wurfstamm oder Tontopf.
@export var art: Art = Art.STAMM
## Eigendrehung im Flug (rad/s) – ein Geschoss ohne Drall wirkt geklebt.
@export var drehtempo := 6.0
## Reichweite der Drehschlag-Abwehr. Gleicher Wert wie `SPIN_REICHWEITE`
## im Spieler; hier als Export, damit größere Geschosse ihn anheben können.
@export var abwehr_radius := 1.7
## Grundfarbe des Körpers.
@export var farbe_koerper := Farben.RINDE
## Signalring, damit das Ding vor jedem Hintergrund als Gefahr zu lesen ist.
@export var farbe_zeichen := Farben.KISTE_FEDER

## Wie lange die Splitter nach dem Zerspringen noch fallen.
const SPLITTER_DAUER := 0.6
## So viele Splitter fliegen beim Aufschlag auseinander.
const SPLITTER_ZAHL := 5
## Aufschlaghöhe des Spielerkörpers (Kapselmitte über den Füßen).
const SPIELER_MITTE := 0.65

var _flug := Vector3.ZERO
var _bild: Node3D
var _zone: Area3D
var _rest := 0.0
var _abgewehrt := false
var _zerbrochen := false
var _splitter: Array[MeshInstance3D] = []
var _splitterflug: Array[Vector3] = []
var _koerper_material: Material
## Der helle Signalteil – erlischt beim Abwehren.
var _zeichen: MeshInstance3D


func _ready() -> void:
	add_to_group("geschosse")
	_rest = lebensdauer
	_aufbauen()


# ---------------------------------------------------------- Abschuss

## Wirft das Geschoss von `von` nach `nach`.
##
## Wurfbahn: `tempo` ist das WAAGERECHTE Reisetempo, die Senkrechte wird
## ausgerechnet. Der Grund ist Rechnerei, keine Bequemlichkeit: Mit fester
## Anfangsgeschwindigkeit v und Fallbeschleunigung g reicht der klassische
## ballistische Wurf höchstens v²/g weit – bei v = 9 und g = 18 sind das
## 4,5 m. Ein Werfer soll aber 14 m weit werfen; die Gleichung hätte dort
## schlicht keine Lösung, und ein Notnagel wäre geraten. Mit fester
## Waagerechten dagegen ist die Bahn immer eindeutig:
##
##     t  = waagerechte Strecke / tempo
##     vy = (Höhenunterschied - ½·g·t²) / t
##
## Ergebnis: Die Flugzeit wächst linear mit dem Abstand, der Bogen wird mit
## der Entfernung von selbst höher – nah ein flacher Schlenker, weit ein
## hoher Lob. Beides ist am Scheitelpunkt abzulesen, bevor man ausweicht.
func abschiessen(von: Vector3, nach: Vector3) -> void:
	global_position = von
	var d := nach - von
	var waagerecht := Vector3(d.x, 0.0, d.z)
	var strecke := waagerecht.length()
	var g := minf(schwere, -0.01)

	if strecke < 0.05:
		# Ziel steht senkrecht über oder unter uns: gerade hoch werfen,
		# der Rest erledigt die Schwerkraft.
		_flug = Vector3.UP * absf(g) * 0.35
		return

	var flugzeit := strecke / maxf(tempo, 0.1)
	var senkrecht := (d.y - 0.5 * g * flugzeit * flugzeit) / flugzeit
	# Schrittfehler ausgleichen: Der Flug wird in Physikschritten
	# integriert (erst Tempo, dann Ort), und dabei fällt das Geschoss um
	# ½·g·Δt·t tiefer als die stetige Formel es vorsieht – bei voller
	# Wurfweite gut 20 cm, also mehr als eine Kopfhöhe der Figur. Ohne
	# diesen Term zielte der Werfer systematisch zu tief.
	var schritt := 1.0 / float(maxi(Engine.physics_ticks_per_second, 1))
	senkrecht -= 0.5 * g * schritt
	_flug = waagerecht / flugzeit + Vector3.UP * senkrecht


# ---------------------------------------------------------- Flug

func _physics_process(delta: float) -> void:
	if _zerbrochen:
		_splitter_fallen(delta)
		_rest -= delta
		if _rest <= 0.0:
			queue_free()
		return

	_abwehr_pruefen()
	if _abgewehrt:
		_ruecklauf_treffer()
		if _zerbrochen:
			return

	_flug.y += schwere * delta
	var ziel := global_position + _flug * delta
	var einschlag := _boden_treffer(ziel)
	if not einschlag.is_empty():
		zerspringen(einschlag["position"] as Vector3)
		return
	global_position = ziel

	if is_instance_valid(_bild):
		_bild.rotation.x += drehtempo * delta
		_bild.rotation.z += drehtempo * 0.45 * delta

	_rest -= delta
	if _rest <= 0.0:
		zerspringen(global_position)


## Sucht auf dem Weg zum nächsten Bild eine Wand oder einen Boden
## (Ebene 1 = Weltgeometrie). Gibt das Ergebnis von `intersect_ray`
## zurück; leer heißt "freie Bahn".
##
## Ein Strahl statt einer Höhenschwelle, weil das Geschoss auch gegen
## Wände und über Abgründe hinweg fliegt: Eine feste Bodenhöhe wäre in
## einem Korridor mit Stufen und Lücken immer falsch.
func _boden_treffer(ziel: Vector3) -> Dictionary:
	var raum := get_world_3d().direct_space_state
	if raum == null:
		return {}
	var abfrage := PhysicsRayQueryParameters3D.create(global_position, ziel)
	abfrage.collision_mask = 1
	return raum.intersect_ray(abfrage)


# ---------------------------------------------------------- Abwehr

## Hält der Spieler gerade den Drehschlag in Reichweite? Dann wegschlagen.
func _abwehr_pruefen() -> void:
	if _abgewehrt:
		return
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null or not spieler.has_method("angriffe"):
		return
	if (int(spieler.call("angriffe")) & Angriff.SPIN) == 0:
		return
	var mitte := spieler.global_position + Vector3.UP * SPIELER_MITTE
	if global_position.distance_to(mitte) > abwehr_radius:
		return
	_abwehren(spieler)


## Schlägt das Geschoss vom Spieler weg und entschärft es.
func _abwehren(spieler: Node3D) -> void:
	_abgewehrt = true
	var weg := global_position - spieler.global_position
	weg.y = 0.0
	if weg.length() < 0.15:
		# Steht der Spieler genau darunter, geht es dorthin zurück,
		# woher es kam – sonst bliebe die Richtung dem Zufall überlassen.
		weg = Vector3(-_flug.x, 0.0, -_flug.z)
	if weg.length() < 0.05:
		weg = Vector3.FORWARD
	_flug = weg.normalized() * maxf(tempo, 1.0) * 0.9 + Vector3.UP * 6.0
	drehtempo *= 2.2
	# Das Signal erlischt: Was abgewehrt ist, ist keine Gefahr mehr, und
	# die Warnfarbe soll nur an Dingen leuchten, die noch treffen können.
	# (Nur der Knoten wird versteckt – die Materialien der
	# Materialbibliothek sind zwischengespeichert und gehören allen.)
	if is_instance_valid(_zeichen):
		_zeichen.visible = false
	Klang.spiele("abprall")


## Ein zurückgeschlagenes Geschoss trifft Gegner, die der Drehschlag
## ohnehin fällen würde. So geht der Schlag nicht ins Leere – wer den
## Werfer mit seinem eigenen Stamm erwischt, hat es verdient.
func _ruecklauf_treffer() -> void:
	for knoten in get_tree().get_nodes_in_group("gegner"):
		var gegner := knoten as Node3D
		if gegner == null or not gegner.has_method("besiegen"):
			continue
		if bool(gegner.get("besiegt")):
			continue
		if (int(gegner.get("besiegbar_durch")) & Angriff.SPIN) == 0:
			continue
		if global_position.distance_to(gegner.global_position + Vector3.UP * 0.8) > radius + 0.9:
			continue
		gegner.call("besiegen", Angriff.SPIN)
		zerspringen(global_position)
		return


# ---------------------------------------------------------- Treffer & Ende

func _auf_koerper(koerper: Node3D) -> void:
	if _zerbrochen or koerper == null:
		return
	if not koerper.is_in_group("spieler"):
		return
	if not _abgewehrt and koerper.has_method("schaden_nehmen"):
		koerper.call("schaden_nehmen")
	# Auch abgewehrt zerspringt es am Körper – sonst hinge es im Spieler.
	zerspringen(global_position)


## Zerbricht am angegebenen Ort: Körper weg, Splitter fallen lassen.
func zerspringen(ort: Vector3) -> void:
	if _zerbrochen:
		return
	_zerbrochen = true
	_rest = SPLITTER_DAUER
	global_position = ort
	if _zone != null:
		_zone.set_deferred("monitoring", false)
	if is_instance_valid(_bild):
		_bild.visible = false
	Klang.spiele("kiste" if art == Art.TOPF else "aufschlag")
	_splitter_streuen()


## Ein paar einfache Bruchstücke, die auseinanderfliegen und einsinken.
## Bewusst schlichte Meshes: `gl_compatibility` kann keine GPU-Partikel.
func _splitter_streuen() -> void:
	var rng := PropWerkzeug.zufall(int(_zeitsaat()))
	for i in SPLITTER_ZAHL:
		var stueck := PropWerkzeug.mesh_knoten("Splitter%d" % i,
				PropWerkzeug.kasten(Vector3(radius * 0.42, radius * 0.34,
						radius * 0.38)), _koerper_material, false)
		if stueck == null:
			continue
		add_child(stueck)
		stueck.position = Vector3(rng.randf_range(-0.1, 0.1), 0.05,
				rng.randf_range(-0.1, 0.1))
		stueck.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)
		_splitter.append(stueck)
		var winkel := TAU * float(i) / float(SPLITTER_ZAHL) + rng.randf_range(-0.4, 0.4)
		_splitterflug.append(Vector3(cos(winkel) * rng.randf_range(1.2, 2.6),
				rng.randf_range(2.0, 3.6), sin(winkel) * rng.randf_range(1.2, 2.6)))


func _splitter_fallen(delta: float) -> void:
	for i in _splitter.size():
		var stueck := _splitter[i]
		if not is_instance_valid(stueck):
			continue
		_splitterflug[i] += Vector3.UP * schwere * delta
		stueck.position += _splitterflug[i] * delta
		stueck.rotation.x += delta * 7.0
		stueck.rotation.z += delta * 5.0
		stueck.scale = stueck.scale.lerp(Vector3(0.2, 0.2, 0.2), minf(delta * 2.5, 1.0))


## Saat für die Splitterstreuung: der Ort reicht, damit zwei Geschosse am
## selben Bild nicht identisch zerbrechen.
func _zeitsaat() -> int:
	return absi(int(global_position.x * 131.0 + global_position.z * 977.0)) + 1


# ---------------------------------------------------------- Optik

func _aufbauen() -> void:
	_bild = Node3D.new()
	_bild.name = "Bild"
	add_child(_bild)

	if art == Art.TOPF:
		_koerper_material = Materialbibliothek.einfarbig(farbe_koerper, 0.75)
		_baue_topf()
	else:
		_koerper_material = Materialbibliothek.einfarbig(farbe_koerper, 0.85)
		_baue_stamm()

	_zone = Area3D.new()
	_zone.name = "Trefferzone"
	_zone.collision_layer = 0
	_zone.collision_mask = 2        # nur den Spieler beachten
	var form := SphereShape3D.new()
	form.radius = radius * 1.15
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	_zone.add_child(kollision)
	add_child(_zone)
	_zone.body_entered.connect(_auf_koerper)


## Wurfstamm: kurzes Holzstück quer zur Flugrichtung, mit zwei hellen
## Schnittflächen an den Enden. Quer liegend ist die Silhouette breit –
## das ist im Flug deutlich besser zu sehen als ein Speer von vorn.
func _baue_stamm() -> void:
	var laengs := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(radius * 0.62, radius * 0.58,
			radius * 3.1, 7, true), laengs)
	# Zwei Aststummel, damit der Drall im Flug sichtbar wird
	for seite: float in [-1.0, 1.0]:
		var stummel := Transform3D(Basis(Vector3.FORWARD, 0.5 * seite),
				Vector3(radius * 0.5 * seite, radius * 0.4, radius * 0.6 * seite))
		PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(radius * 0.2, radius * 0.1,
				radius * 0.7, 5, false), stummel)
	var koerper := PropWerkzeug.mesh_knoten("Stamm", PropWerkzeug.fertig(st),
			_koerper_material)
	if koerper != null:
		_bild.add_child(koerper)

	var ring := PropWerkzeug.bauer()
	for seite: float in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(ring, PropWerkzeug.stumpf(radius * 0.64,
				radius * 0.64, radius * 0.22, 7, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
						Vector3(0.0, 0.0, radius * 1.45 * seite)))
	_zeichen = PropWerkzeug.mesh_knoten("Schnittflaeche",
			PropWerkzeug.fertig(ring),
			Materialbibliothek.einfarbig(farbe_zeichen, 0.6), false)
	if _zeichen != null:
		_bild.add_child(_zeichen)


## Tontopf: bauchig, mit Hals und einem hellen Zierband auf dem Bauch.
func _baue_topf() -> void:
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(radius, 9, 6),
			Transform3D(Basis().scaled(Vector3(1.0, 0.92, 1.0)), Vector3.ZERO))
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(radius * 0.46, radius * 0.58,
			radius * 0.55, 8, false),
			Transform3D(Basis(), Vector3(0.0, radius * 0.9, 0.0)))
	var koerper := PropWerkzeug.mesh_knoten("Topf", PropWerkzeug.fertig(st),
			_koerper_material)
	if koerper != null:
		_bild.add_child(koerper)

	var band := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(band, PropWerkzeug.stumpf(radius * 1.02, radius * 1.02,
			radius * 0.3, 9, false), Transform3D())
	_zeichen = PropWerkzeug.mesh_knoten("Zierband", PropWerkzeug.fertig(band),
			Materialbibliothek.einfarbig(farbe_zeichen, 0.55), false)
	if _zeichen != null:
		_bild.add_child(_zeichen)
