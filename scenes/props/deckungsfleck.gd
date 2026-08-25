extends Area3D
class_name Deckungsfleck
## Stelle am Boden, an der man geduckt sicher ist (Steckbrief 4-3).
##
## Vorbild sind die magentafarbenen Erdflecken im Dschungel: Der Schwarm
## kommt, man wirft sich in den Fleck und lässt ihn über sich hinweg.
## Das Level wird dadurch ein Wechsel aus Rennen und Ducken, statt aus
## Rennen und Kämpfen.
##
## DER FLECK BRAUCHT KEINE EIGENE TASTE. Er nutzt das Krabbeln, das die
## Figur ohnehin kann: Wer daraufsteht und die Slide-Taste hält, ist in
## Deckung (`Spieler.kriechen`, siehe `scenes/player/player.gd`); wer
## aufrecht daraufsteht, ist es nicht. Damit ist die Regel ohne ein Wort
## Erklärung zu lernen – man probiert es einmal aus und sieht es.
##
## Und man SIEHT es: In dem Moment, in dem die Figur geduckt drinsteht,
## wechselt der Fleck die Farbe und senkt sich ein Stück ab. Ohne diese
## Rückmeldung wüsste niemand, ob er gerade geschützt ist oder nicht –
## eine unsichtbare Regel ist in einem Plattformer dasselbe wie keine.
##
## Gegner fragen nur ab, sie müssen nichts wissen:
##     for fleck in get_tree().get_nodes_in_group("deckungsflecken"):
##         if fleck.ist_in_deckung(ziel):
##             return    # nicht angreifen
## Oder über das Signal `deckung_geaendert`, wenn ein Schwarm sein Ziel
## nur beim Wechsel neu wählen soll.

## Wechselt zwischen „jemand ist geduckt drin" und „niemand".
signal deckung_geaendert(in_deckung: bool)

## Halbmesser des Flecks in Metern.
@export var radius := 1.6:
	set(wert):
		radius = wert
		if is_inside_tree():
			_aufbauen()
			_form_anpassen()

## Grundfarbe. Signalfarbe – sie kommt sonst nirgends im Level vor, das
## ist Absicht: Der Spieler soll einen Fleck von weitem als Fleck
## erkennen und nicht mit einer Pfütze oder einem Schatten verwechseln.
@export var farbe := Color(0.75, 0.21, 0.48):
	set(wert):
		farbe = wert
		if is_inside_tree():
			_farben_setzen()

## Farbe, solange jemand geduckt drinsteht. Heller und wärmer – der
## Fleck soll beim Umschalten aufleuchten, nicht nur den Ton wechseln.
@export var farbe_aktiv := Color(1.0, 0.47, 0.80):
	set(wert):
		farbe_aktiv = wert
		if is_inside_tree():
			_farben_setzen()

## So weit sinkt das Bild ein, wenn der Fleck wirkt (Meter).
## Nur das Bild – der Boden unter den Füßen bleibt, wo er ist.
@export var tiefe := 0.12

## Höhe der Auslösezone. Reicht bis Kopfhöhe der stehenden Figur, damit
## der Fleck auch dann noch zählt, wenn man ihn im Sprung streift und
## unmittelbar danach in den Slide geht.
const ZONE_HOEHE := 1.4

## Dicke der sichtbaren Scheibe.
const SCHEIBE_DICKE := 0.10

## Wie schnell der Fleck seinen Zustand zeigt (Anteil je Sekunde).
## Schnell genug, dass es als Antwort auf den Tastendruck gelesen wird.
const WECHSELTEMPO := 9.0

## Ruhiges Pulsen im Leerlauf – der Fleck winkt, solange niemand drin ist.
const PULS_TEMPO := 1.3
const PULS_TIEFE := 0.22

var _kollision: CollisionShape3D = null
var _bild: Node3D = null
var _scheibe: MeshInstance3D = null
var _rand: MeshInstance3D = null

## Eigene Materialien statt solcher aus der `Materialbibliothek`: Die
## werden dort zwischengespeichert und von allen Objekten geteilt. Hier
## wird die Farbe Bild für Bild verändert – über ein geteiltes Material
## blinkten alle Flecken im Level gemeinsam, sobald einer wirkt.
var _mat_scheibe: StandardMaterial3D = null
var _mat_rand: StandardMaterial3D = null

var _drin: Array[Node3D] = []
var _aktiv := false
## 0 = offen, 1 = in Deckung. Läuft weich nach, damit es kein Blinken gibt.
var _mischung := 0.0
var _zeit := 0.0


func _ready() -> void:
	add_to_group("deckungsflecken")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	if not body_entered.is_connected(_auf_eintritt):
		body_entered.connect(_auf_eintritt)
	if not body_exited.is_connected(_auf_austritt):
		body_exited.connect(_auf_austritt)
	_aufbauen()
	_form_anpassen()
	_farben_setzen()


func _physics_process(delta: float) -> void:
	_zeit += delta

	var jetzt := _jemand_geduckt()
	if jetzt != _aktiv:
		_aktiv = jetzt
		deckung_geaendert.emit(_aktiv)

	var ziel := 1.0 if _aktiv else 0.0
	_mischung = move_toward(_mischung, ziel, WECHSELTEMPO * delta)
	_bild_stellen()


# ---------------------------------------------------------------- Abfrage

## Steht dieser Körper geduckt auf dem Fleck?
##
## Genau die Frage, die ein Gegner stellt, bevor er angreift. Aufrecht
## darüberstehen zählt nicht – der Fleck schützt nur den, der sich
## hineinlegt.
func ist_in_deckung(koerper: Node3D) -> bool:
	return koerper != null and _drin.has(koerper) and _geduckt(koerper)


## Wirkt der Fleck gerade für irgendjemanden?
func aktiv() -> bool:
	return _aktiv


func _jemand_geduckt() -> bool:
	for koerper in _drin:
		if is_instance_valid(koerper) and _geduckt(koerper):
			return true
	return false


## Krabbelt die Figur? `kriechen` ist kein Schalter, sondern der Zustand
## dieses Bildes – genau deshalb taugt er als Bedingung für Deckung.
func _geduckt(koerper: Node3D) -> bool:
	var spieler := koerper as Spieler
	return spieler != null and spieler.kriechen


func _auf_eintritt(koerper: Node3D) -> void:
	if not _drin.has(koerper):
		_drin.append(koerper)


func _auf_austritt(koerper: Node3D) -> void:
	_drin.erase(koerper)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	_bild = PropWerkzeug.kind(self, "Bild", func() -> Node3D: return Node3D.new())

	# Die Mulde: eine flache Scheibe, oben etwas enger als unten. Dadurch
	# hat der Fleck eine Schräge statt einer Kante und liest sich als
	# ausgehobene Erde, nicht als aufgeklebtes Blatt Papier.
	if _mat_scheibe == null:
		_mat_scheibe = StandardMaterial3D.new()
		_mat_scheibe.roughness = 0.85
		_mat_scheibe.emission_enabled = true
	var scheibe := PropWerkzeug.mesh_knoten("Scheibe",
			PropWerkzeug.stumpf(radius, radius * 0.88, SCHEIBE_DICKE, 18, true),
			_mat_scheibe, false)
	_ersetzen("Scheibe", scheibe)
	_scheibe = scheibe
	_scheibe.position.y = SCHEIBE_DICKE * 0.5

	# Aufgeworfener Wall ringsum – ohne ihn liegt der Fleck flach in der
	# Fläche und verschwindet, sobald die Kamera flach draufsieht.
	if _mat_rand == null:
		_mat_rand = StandardMaterial3D.new()
		_mat_rand.roughness = 0.95
		_mat_rand.emission_enabled = true
	var rand := PropWerkzeug.mesh_knoten("Rand",
			PropWerkzeug.stumpf(radius * 1.14, radius * 1.02,
					SCHEIBE_DICKE * 0.7, 18, false),
			_mat_rand, false)
	_ersetzen("Rand", rand)
	_rand = rand
	_rand.position.y = SCHEIBE_DICKE * 0.35


func _ersetzen(bezeichnung: String, neu: MeshInstance3D) -> void:
	var alt := _bild.get_node_or_null(NodePath(bezeichnung))
	if alt != null:
		# Erst aushängen, dann freigeben: `queue_free` wirkt erst am Ende
		# des Bildes, der neue Knoten bekäme sonst einen Namen mit Anhängsel.
		_bild.remove_child(alt)
		alt.queue_free()
	if neu != null:
		neu.name = bezeichnung
		_bild.add_child(neu)


## Spannt die Auslösezone auf.
##
## Die Form wird IMMER neu erzeugt und nie die aus der Szene weiterbenutzt:
## Unterressourcen einer `.tscn` teilen sich alle Instanzen. Zwei Flecken
## mit verschiedenem `radius` bekämen sonst beide den Wert dessen, der
## zuletzt geladen wurde. Und `PropWerkzeug.kind` hängt den Knoten selbst
## ein, falls der Fleck über `Deckungsfleck.new()` im Levelskript entsteht
## statt als Instanz der Szene.
func _form_anpassen() -> void:
	_kollision = PropWerkzeug.kind(self, "Kollision",
			func() -> CollisionShape3D: return CollisionShape3D.new())
	var form := CylinderShape3D.new()
	form.radius = maxf(radius, 0.1)
	form.height = ZONE_HOEHE
	_kollision.shape = form
	_kollision.position.y = ZONE_HOEHE * 0.5


func _farben_setzen() -> void:
	_bild_stellen()


## Setzt Farbe, Leuchten und Absenkung passend zum Zustand.
func _bild_stellen() -> void:
	if _bild == null or _mat_scheibe == null or _mat_rand == null:
		return

	# Im Leerlauf pulst der Fleck leicht, in Deckung steht er ruhig und
	# hell. Das Pulsen hört auf, sobald er wirkt – auch das ist Antwort.
	var puls := (sin(_zeit * TAU * PULS_TEMPO) * 0.5 + 0.5) * PULS_TIEFE
	puls *= 1.0 - _mischung

	var ton := farbe.lerp(farbe_aktiv, _mischung)
	_mat_scheibe.albedo_color = ton
	_mat_scheibe.emission = ton
	_mat_scheibe.emission_energy_multiplier = 0.25 + puls + _mischung * 1.35

	var randton := ton.darkened(0.35)
	_mat_rand.albedo_color = randton
	_mat_rand.emission = randton
	_mat_rand.emission_energy_multiplier = 0.15 + _mischung * 0.6

	_bild.position.y = -tiefe * _mischung
