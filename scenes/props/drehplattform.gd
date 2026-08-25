extends AnimatableBody3D
class_name Drehplattform
## Steinscheibe, die sich um die Hochachse dreht und den Spieler mitnimmt.
##
## Vorbild sind die rotierenden Säulen der Sturmruinen (`doku/level-vorbilder.md`,
## 4-4). Deren eigentlicher Trick ist nicht die Drehung, sondern was
## daraufsteht: ein Gegner. Der Spieler muss zwei bewegte Dinge zugleich
## lesen – die Scheibe unter sich und den Gegner darauf.
##
## SO SETZT EIN LEVEL EINEN GEGNER DARAUF:
##
##     var scheibe := drehplattform(...)      # Hilfe in korridor_level.gd
##     var g := GEGNER.instantiate()
##     g.patrouille_weite = 0.0               # WICHTIG, siehe unten
##     scheibe.aufsetzen(g)
##
## `aufsetzen()` hängt den Knoten als Kind ein; Kinder erben die
## Transformation der Scheibe und drehen und taumeln damit von selbst mit.
##
## Warum `patrouille_weite = 0.0`: `Gegner` merkt sich seinen Startpunkt in
## WELTkoordinaten und läuft von dort aus hin und her. Auf einer drehenden
## Scheibe wandert dieser Startpunkt mit der Drehung fort, seine Patrouille
## aber nicht – der Gegner liefe schräg über den Rand hinaus. Wer Bewegung
## auf der Scheibe will, nimmt die Drehung selbst dafür: Ein stehender
## Gegner auf einer drehenden Scheibe bewegt sich für den Spieler ohnehin.
##
## WARUM KERBEN, SPEICHEN UND EINE MARKE:
## Eine glatte Scheibe dreht sich für das Auge nicht. Es gibt nichts, woran
## sich die Drehung ablesen ließe, und der Spieler springt auf eine
## vermeintlich stehende Fläche und wird davon überrascht. Deshalb bekommt
## der Rand einen Zahnkranz, das Deck Speichen vom Mittelpunkt nach außen,
## und genau EIN Zahn eine Farbmarke. Am Zahnkranz sieht man, DASS sie sich
## dreht, an den Speichen WIE SCHNELL, und an der Marke, wann die Kante
## wieder da ist, wo man sie zum Abspringen braucht.
##
## `sync_to_physics` steht an, damit `CharacterBody3D` die Scheibe als
## bewegten Boden erkennt: Godot rechnet aus der Drehung eine
## Winkelgeschwindigkeit und trägt den Spieler um die Achse mit.
## Nachgemessen: Eine Scheibe mit `tempo = 45` dreht eine stehende Figur in
## zwei Sekunden um genau 90 Grad um die Mitte. Die Figur selbst dreht sich
## dabei NICHT mit – sie wird versetzt, nicht gedreht. Das ist die alte,
## richtige Auslegung: Wer sich mitdrehte, verlöre die Blickrichtung, und
## die Steuerung ist kamerarelativ.

## Kantenlängen des Decks in Metern. Bei `rund` zählt nur `groesse.x` – das
## ist dann der Durchmesser.
@export var groesse := Vector2(3.6, 3.6)

## Runde Scheibe (Vorbild) oder viereckige Platte.
@export var rund := true

## Drehtempo in Grad je Sekunde.
@export var tempo := 30.0

## Drehsinn: 1 = im Uhrzeigersinn von oben, -1 = dagegen.
@export var richtung := 1

## Grad-Raster, an dem die Scheibe kurz anhält (0 = sie dreht durch).
## Mit 90 und einer knappen Pause entsteht aus der Scheibe ein Taktgeber:
## Man springt nicht mehr im Vorbeilaufen auf, sondern auf ein Stichwort.
@export var pausiert_bei := 0.0

## Länge dieser Pause in Sekunden.
@export var pausenzeit := 0.0

## Versatz des Startwinkels in Grad. Damit stehen mehrere Scheiben versetzt,
## statt im Gleichschritt zu laufen.
@export var phase := 0.0

## Lässt die Scheibe zusätzlich taumeln wie eine auslaufende Münze. Das
## Stehen wird dadurch unruhig, ohne unfair zu werden: Die Neigung bleibt
## weit unter dem Winkel, ab dem der Spieler abrutscht.
@export var kippt := false

## Ausschlag des Taumelns in Grad.
@export var kipp_winkel := 12.0

## Höhe der Säule unter dem Deck (0 = keine). Reine Kulisse, sie hat keine
## Kollision – ohne sie schwebt die Scheibe aber sichtbar im Nichts.
@export var saeule := 1.6

## Mittelpunkt des Decks in Elternkoordinaten. Bleibt er auf Null, gilt die
## Position, die der Knoten beim Start hat.
@export var ort := Vector3.ZERO

## Grundton des Gesteins. Der Sturmstein der Vorlage ist blaugrau, nicht
## erdbraun wie unser `Materialbibliothek.fels()`; die Bibliothek kennt
## keinen eingefärbten Stein, deshalb steht die Farbe hier.
##
## Viel heller als der gemessene Wert `#41364F`. Der stammt aus einem
## PS1-Bildschirmfoto, und `albedo_color` MULTIPLIZIERT die Felstextur –
## der gemessene Ton halbierte sie und ergab im Probebild einen schwarzen
## Klumpen. Auf etwas, das aussieht wie ein Loch, springt niemand
## freiwillig. Der Ton hier hat deshalb die Helligkeit unserer übrigen
## Steine und trägt die Farbe der Vorlage nur noch als Stich.
@export var steinfarbe := Color(0.76, 0.71, 0.88)

## Farbe der einen markierten Kerbe. Bewusst eine Signalfarbe, die sonst
## nirgends im Level vorkommt – sie ist eine Ableseskala, kein Schmuck.
@export var markenfarbe := Color(0.43, 0.27, 0.72)

## Höhe des Kollisionskörpers. Der Ursprung liegt in seiner MITTE (wie bei
## `Wasserplattform`), die Trittfläche also `DECK_STAERKE * 0.5` darüber.
const DECK_STAERKE := 0.36
const ZAEHNE := 12              ## Kerben am Rand
const SPEICHEN := 6             ## eingelegte Bänder auf dem Deck
const EINLAGE := 0.03           ## so weit stehen die Einlagen über dem Deck
const TAUMEL_TEMPO := 0.23      ## Umläufe der Taumelachse je Sekunde

var _zeit := 0.0
var _winkel := 0.0


func _ready() -> void:
	add_to_group("drehplattformen")
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	if ort == Vector3.ZERO:
		ort = position
	_aufbauen()
	# Gleich zum Takt passend setzen, sonst springt die Scheibe im ersten
	# Bild von ihrer Ruhelage an ihren Platz.
	_takt()
	_stellen()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_zeit += delta
	_takt()
	_stellen()


## Setzt Ort, Drehung und Neigung in EINEM Schreibzugriff auf `transform`.
##
## Getrennt geht es nicht: Bei einem Körper mit `sync_to_physics` steht der
## Knoten unter der Hoheit des Physikservers. Ein Schreiben auf `position`
## wirkt erst im nächsten Schritt, und ein anschließendes Schreiben auf
## `rotation` liest den noch alten Ursprung zurück und setzt ihn wieder ein –
## die Plattform bliebe im Nullpunkt stehen.
func _stellen() -> void:
	var basis := Basis(Vector3.UP, _winkel)
	if kippt and kipp_winkel > 0.0:
		# Die Neigung bleibt gleich groß, ihre Achse wandert langsam im
		# Kreis. Das liest sich als Taumeln; eine feste Schräge dagegen
		# sähe nach schiefem Einbau aus und wäre nach zwei Sekunden
		# auswendig gelernt.
		var a := _zeit * TAU * TAUMEL_TEMPO + deg_to_rad(phase)
		basis = Basis(Vector3(cos(a), 0.0, sin(a)), deg_to_rad(kipp_winkel)) * basis
	transform = Transform3D(basis, ort)


## Rechnet den Drehwinkel zur Spielzeit aus.
##
## Der Winkel wird jedes Mal neu aus `_zeit` bestimmt statt aufaddiert:
## Aufaddieren driftet, und zwei Scheiben, die im Gleichtakt laufen sollen,
## laufen nach ein paar Minuten sichtbar auseinander.
func _takt() -> void:
	var vz := 1.0 if richtung >= 0 else -1.0
	var t := _zeit
	if pausiert_bei > 0.0 and pausenzeit > 0.0 and tempo > 0.0:
		var fahrzeit := pausiert_bei / tempo
		var runde := fahrzeit + pausenzeit
		var stufe := floorf(t / runde)
		var rest := t - stufe * runde
		var anteil := clampf(rest / fahrzeit, 0.0, 1.0)
		_winkel = deg_to_rad(pausiert_bei * (stufe + anteil) + phase) * vz
		return
	_winkel = deg_to_rad(tempo * t + phase) * vz


## Stellt einen Knoten auf das Deck, wo er mitgedreht wird.
##
## `seitlich` und `laengs` messen vom Mittelpunkt aus. Am Rand ist die
## Mitnahme am deutlichsten zu spüren – dort legt die Fläche unter den Füßen
## den längsten Weg zurück.
func aufsetzen(knoten: Node3D, seitlich := 0.0, laengs := 0.0) -> void:
	# Erst stellen, dann einhängen: Ein `Gegner` merkt sich in `_ready()`
	# seine Weltposition. Andersherum merkte er sich den Mittelpunkt der
	# Scheibe und zöge sich beim ersten Schritt dorthin.
	knoten.position = Vector3(seitlich, DECK_STAERKE * 0.5, laengs)
	add_child(knoten)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	var r := groesse.x * 0.5
	var stein := _gestein(steinfarbe)
	var dunkel := _gestein(steinfarbe.darkened(0.4))

	_deck_bauen(r, stein)
	_zaehne_bauen(r, stein)
	_einlagen_bauen(r, dunkel)
	if saeule > 0.0:
		_saeule_bauen(r, dunkel)

	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	if rund:
		# Konvexe Hülle statt `CylinderShape3D`: ein Zylinder ist in Godot
		# die heikelste aller Formen, die Hülle des Scheibennetzes ist ein
		# schlichtes 16-Eck-Prisma und verhält sich berechenbar.
		kollision.shape = PropWerkzeug.huelle(
				PropWerkzeug.stumpf(r, r, DECK_STAERKE, 16, true))
	else:
		var form := BoxShape3D.new()
		form.size = Vector3(groesse.x, DECK_STAERKE, groesse.y)
		kollision.shape = form
	add_child(kollision)


func _deck_bauen(r: float, material: Material) -> void:
	var st := PropWerkzeug.bauer()
	if rund:
		# Unten eine Spur schmaler: Die angeschrägte Unterkante lässt die
		# Scheibe von unten wie eine gedrechselte Säulentrommel aussehen
		# statt wie eine ausgestanzte Platte.
		PropWerkzeug.anfuegen(st,
				PropWerkzeug.stumpf(r * 0.94, r, DECK_STAERKE, 16, true),
				Transform3D())
	else:
		PropWerkzeug.anfuegen(st,
				PropWerkzeug.kasten(Vector3(groesse.x, DECK_STAERKE, groesse.y)),
				Transform3D())
	_netz("Deck", st, material, true)


## Zahnkranz am Rand. Ein Zahn trägt die Farbmarke und sitzt deshalb in
## einem eigenen Netz.
func _zaehne_bauen(r: float, material: Material) -> void:
	var breite := TAU * r / float(ZAEHNE) * 0.42
	var tiefe := maxf(r * 0.16, 0.14)
	var kerbe := PropWerkzeug.kasten(Vector3(breite, DECK_STAERKE * 0.86, tiefe))
	var st := PropWerkzeug.bauer()
	var marke := PropWerkzeug.bauer()
	for i in ZAEHNE:
		var a := TAU * float(i) / float(ZAEHNE)
		var lage := PropWerkzeug.ort(
				Vector3(sin(a), 0.0, cos(a)) * (r + tiefe * 0.3),
				Vector3(0.0, a, 0.0))
		PropWerkzeug.anfuegen(marke if i == 0 else st, kerbe, lage)
	_netz("Zahnkranz", st, material, true)
	_netz("Marke", marke, Materialbibliothek.einfarbig(markenfarbe, 0.55), true)


## Speichen und Nabe auf der Trittfläche.
##
## Sie stehen nur drei Zentimeter über dem Deck. Bündig ginge nicht – zwei
## deckungsgleiche Flächen flimmern gegeneinander –, und höher wäre eine
## Stolperkante, die es in der Kollision gar nicht gibt.
func _einlagen_bauen(r: float, material: Material) -> void:
	var oben := DECK_STAERKE * 0.5 + EINLAGE * 0.5
	var st := PropWerkzeug.bauer()
	for i in SPEICHEN:
		var a := PI * float(i) / float(SPEICHEN)
		var band := PropWerkzeug.kasten(
				Vector3(maxf(r * 0.09, 0.08), EINLAGE, r * 1.82))
		PropWerkzeug.anfuegen(st, band,
				PropWerkzeug.ort(Vector3(0.0, oben, 0.0), Vector3(0.0, a, 0.0)))
	# Quadratische Nabe: Ein Kreis in der Mitte sähe stillstehend aus, eine
	# Ecke dreht sich sichtbar mit.
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.kasten(Vector3(r * 0.42, EINLAGE * 1.6, r * 0.42)),
			Transform3D(Basis(), Vector3(0.0, oben, 0.0)))
	_netz("Einlagen", st, material, false)


func _saeule_bauen(r: float, material: Material) -> void:
	var st := PropWerkzeug.bauer()
	var unten := -DECK_STAERKE * 0.5
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.stumpf(r * 0.46, r * 0.62, saeule, 8, false),
			Transform3D(Basis(), Vector3(0.0, unten - saeule * 0.5, 0.0)))
	# Ein Wulst dicht unter dem Deck: Er fängt den Blick, wenn die Scheibe
	# von unten gesehen wird, und trennt Deck von Schaft.
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.stumpf(r * 0.7, r * 0.7, 0.12, 8, true),
			Transform3D(Basis(), Vector3(0.0, unten - 0.08, 0.0)))
	_netz("Saeule", st, material, true)


func _netz(bezeichnung: String, st: SurfaceTool, material: Material,
		schatten: bool) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung,
			PropWerkzeug.fertig(st), material, schatten)
	if knoten != null:
		add_child(knoten)


# ---------------------------------------------------------------- Material

static var _steine: Dictionary = {}

## Fels der Bibliothek, in den Ton der Ruine getaucht.
##
## `albedo_color` multipliziert die vorhandene Struktur – Schichtung,
## Bruchkanten und Normalmap bleiben also erhalten, nur der Ton wandert.
## Je Farbe entsteht das Material einmal und wird von allen Scheiben
## geteilt; die Bibliothek selbst bleibt unangetastet.
static func _gestein(farbe: Color) -> Material:
	var schluessel := farbe.to_rgba32()
	var vorhanden: Variant = _steine.get(schluessel)
	if vorhanden != null:
		return vorhanden
	var m := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	_steine[schluessel] = m
	return m
