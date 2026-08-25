extends AnimatableBody3D
class_name Wasserplattform
## Plattform auf dem Wasser, die zwischen zwei Punkten pendelt.
##
## Damit lassen sich drei Dinge bauen, die im Moor gebraucht werden:
##
##   FLOSS    – ein Treibfloß aus gebundenen Stämmen. Der Spieler steigt
##              auf und wird ein Stück mitgenommen. Das ist die Antwort
##              auf die Frage, wie ein Korridorlevel Tempo bekommt, ohne
##              dass die Figur die Steuerung wechselt.
##   BOHLE    – eine Wehrbohle, die im Takt untertaucht. Zwei Punkte
##              übereinander, lange Pause oben, kurze unten: Wer zu spät
##              springt, steht im Wasser.
##   SEEROSE  – ein Blatt als Trittstein. Steht meist still und wippt nur.
##
## Bewegt wird der KÖRPER, gewippt nur das SICHTBARE. Das ist Absicht:
## Ein Kollisionskörper, der im Zentimeterbereich zittert, lässt den
## Spieler abwechselnd fallen und landen; das Bild darf wippen, der Boden
## unter den Füßen nicht.
##
## `sync_to_physics` steht an, damit `CharacterBody3D` die Plattform als
## bewegten Boden erkennt und den Spieler von selbst mitträgt.

enum Art {
	FLOSS,    ## gebundene Stämme, trägt den Spieler über Wasser
	BOHLE,    ## Wehrbohle, taucht im Takt unter
	SEEROSE,  ## Blatt als Trittstein
}

## Aussehen der Plattform.
@export var art: Art = Art.FLOSS

## Kantenlängen des Decks in Metern (X mal Z). Die Höhe ergibt sich aus der Art.
@export var groesse := Vector2(3.2, 2.6)

## Endpunkte der Fahrt, beide in Elternkoordinaten. Sind sie gleich,
## steht die Plattform und wippt nur. Wird `verlauf` gesetzt, zählen
## stattdessen `strecke_a`/`strecke_b`.
@export var punkt_a := Vector3.ZERO
@export var punkt_b := Vector3.ZERO

## Fährt die Plattform einer Levelkurve nach? Ohne das führe eine lange
## Fahrt geradeaus aus dem Korridor heraus, sobald der Fluss eine Biegung
## macht. Mit Kurve dreht sich das Deck außerdem mit dem Lauf mit.
@export var verlauf: Curve3D = null
@export var strecke_a := 0.0
@export var strecke_b := 0.0
@export var seitlich_a := 0.0
@export var seitlich_b := 0.0
@export var hoehe := 0.0

## Dauer einer Fahrt von A nach B in Sekunden.
@export var fahrzeit := 3.0

## Wartezeit an jedem Ende. `pause_b` erlaubt ein ungleiches Verhältnis –
## eine Wehrbohle steht lange oben und nur kurz unten.
@export var pause_a := 1.2
@export var pause_b := 1.2

## Verschiebt den Takt. Damit laufen mehrere Plattformen versetzt.
@export var phase := 0.0

## Ausschlag des Wippens in Metern. Betrifft nur das Bild.
@export var wippen := 0.05

## Drehung um die Hochachse, damit das Deck zum Wegverlauf passt.
@export var drehung := 0.0

## Farbe des Blatts bzw. Anstrich. Alpha 0 = Vorgabe der Art.
@export var farbe := Color(0, 0, 0, 0)

## Feste Saat für die Streuung der Stämme.
@export var saat := 0

const STAMM_ZAHL := 6           ## Stämme eines Floßes
const DECK_STAERKE := 0.34      ## Höhe des Kollisionskastens
const WIPP_TEMPO := 0.9         ## Schwingungen je Sekunde
const ROLL_ANTEIL := 0.35       ## so viel vom Wippen geht in die Schräglage

var _bild: Node3D               ## alles Sichtbare, wippt
var _zeit := 0.0
var _fahrt := 0.0               ## 0 = an Punkt A, 1 = an Punkt B


func _ready() -> void:
	add_to_group("wasserplattformen")
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_aufbauen()
	# Gleich zum Takt passend setzen, sonst springt die Plattform im
	# ersten Bild von ihrer Ruhelage an ihren Platz.
	_takt()
	_stellen()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_zeit += delta
	if _faehrt():
		_takt()
		_stellen()
	if is_instance_valid(_bild) and wippen > 0.0:
		var welle := sin(_zeit * TAU * WIPP_TEMPO + phase)
		_bild.position.y = welle * wippen
		_bild.rotation.z = welle * wippen * ROLL_ANTEIL
		_bild.rotation.x = cos(_zeit * TAU * WIPP_TEMPO * 0.7 + phase) \
				* wippen * ROLL_ANTEIL


## Bewegt sich die Plattform überhaupt?
func _faehrt() -> bool:
	if verlauf != null:
		return not is_equal_approx(strecke_a, strecke_b) \
				or not is_equal_approx(seitlich_a, seitlich_b)
	return punkt_a != punkt_b


## Setzt Ort und Drehung passend zum Stand der Fahrt.
##
## Beides zusammen in EINEM Schreibzugriff auf `transform`. Getrennt geht
## es nicht: Bei einem Körper mit `sync_to_physics` steht der Knoten unter
## der Hoheit des Physikservers. Ein Schreiben auf `position` wirkt erst
## im nächsten Schritt, und ein anschließendes Schreiben auf `rotation`
## liest den noch alten Ursprung zurück und setzt ihn wieder ein – die
## Plattform blieb so im Nullpunkt stehen.
func _stellen() -> void:
	if verlauf == null:
		transform = Transform3D(Basis(Vector3.UP, drehung),
				punkt_a.lerp(punkt_b, _fahrt))
		return
	var s := lerpf(strecke_a, strecke_b, _fahrt)
	transform = Transform3D(
			Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, s) + drehung),
			LevelWerkzeuge.punkt(verlauf, s,
					lerpf(seitlich_a, seitlich_b, _fahrt), hoehe))


## Rechnet die Stelle im Takt aus: warten, fahren, warten, zurückfahren.
func _takt() -> void:
	var runde := fahrzeit * 2.0 + pause_a + pause_b
	if runde <= 0.0:
		_fahrt = 0.0
		return
	var p := fposmod(_zeit + phase * runde, runde)
	if p < pause_a:
		_fahrt = 0.0
	elif p < pause_a + fahrzeit:
		_fahrt = (p - pause_a) / fahrzeit
	elif p < pause_a + fahrzeit + pause_b:
		_fahrt = 1.0
	else:
		_fahrt = 1.0 - (p - pause_a - fahrzeit - pause_b) / fahrzeit


## Setzt eine Kiste auf das Deck. Sie fährt mit, weil sie ein Kind ist.
##
## Nur für STEHENDE Plattformen gedacht: Auf einem fahrenden Floß wäre die
## Kiste ein bewegter StaticBody3D, und darauf steht es sich schlecht.
func kiste_aufsetzen(kiste: Node3D, seitlich := 0.0, laengs := 0.0) -> void:
	kiste.position = Vector3(seitlich, DECK_STAERKE * 0.5 + 0.5, laengs)
	_bild.add_child(kiste)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	_bild = Node3D.new()
	_bild.name = "Bild"
	add_child(_bild)

	match art:
		Art.FLOSS:
			_floss_bauen()
		Art.BOHLE:
			_bohle_bauen()
		Art.SEEROSE:
			_seerose_bauen()

	var form := BoxShape3D.new()
	form.size = Vector3(groesse.x, DECK_STAERKE, groesse.y)
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	add_child(kollision)


## Ein Floß aus quer liegenden Stämmen, mit zwei Bünden zusammengehalten.
func _floss_bauen() -> void:
	var rng := PropWerkzeug.zufall(saat if saat != 0 else 1)
	var st := PropWerkzeug.bauer()
	var breite := groesse.y / float(STAMM_ZAHL)
	for i in STAMM_ZAHL:
		var z := -groesse.y * 0.5 + breite * (i + 0.5)
		var dicke := breite * rng.randf_range(0.46, 0.54)
		var laenge := groesse.x * rng.randf_range(0.94, 1.0)
		var stamm := PropWerkzeug.stumpf(dicke, dicke * 0.94, laenge, 7, true)
		var ort := Transform3D(Basis(Vector3.FORWARD, PI * 0.5),
				Vector3(rng.randf_range(-0.05, 0.05), 0.0, z))
		PropWerkzeug.anfuegen(st, stamm, ort)
	# Zwei Bünde quer darüber – erst dadurch liest sich das als Floß und
	# nicht als lose Reihe Baumstämme.
	for seite in [-1.0, 1.0]:
		var bund := PropWerkzeug.kasten(
				Vector3(0.12, breite * 0.36, groesse.y * 0.98))
		PropWerkzeug.anfuegen(st, bund, Transform3D(Basis(),
				Vector3(seite * groesse.x * 0.32, breite * 0.34, 0.0)))
	_netz("Floss", st, Materialbibliothek.wurzel())


## Wehrbohle: eine Lage Bretter mit Beschlag an den Stirnseiten.
func _bohle_bauen() -> void:
	var st := PropWerkzeug.bauer()
	var bretter := maxi(int(groesse.y / 0.42), 2)
	var breite := groesse.y / float(bretter)
	for i in bretter:
		var z := -groesse.y * 0.5 + breite * (i + 0.5)
		var brett := PropWerkzeug.kasten(
				Vector3(groesse.x, DECK_STAERKE * 0.8, breite * 0.88))
		PropWerkzeug.anfuegen(st, brett, Transform3D(Basis(), Vector3(0, 0, z)))
	_netz("Bohle", st, Materialbibliothek.bohlen())

	var beschlag := PropWerkzeug.bauer()
	for seite in [-1.0, 1.0]:
		var band := PropWerkzeug.kasten(
				Vector3(0.14, DECK_STAERKE * 1.1, groesse.y))
		PropWerkzeug.anfuegen(beschlag, band, Transform3D(Basis(),
				Vector3(seite * (groesse.x * 0.5 - 0.1), 0.0, 0.0)))
	_netz("Beschlag", beschlag, Materialbibliothek.metall(Farben.ROST))


## Seerosenblatt: eine flache Scheibe mit Kerbe, darauf eine Knospe.
func _seerose_bauen() -> void:
	var st := PropWerkzeug.bauer()
	var blatt := PropWerkzeug.stumpf(groesse.x * 0.5, groesse.x * 0.47,
			DECK_STAERKE * 0.7, 11, true)
	PropWerkzeug.anfuegen(st, blatt, Transform3D())
	var grundfarbe := farbe if farbe.a > 0.0 else Farben.ALGE
	_netz("Blatt", st, Materialbibliothek.einfarbig(grundfarbe, 0.75))

	var knospe := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(knospe, PropWerkzeug.kugel(groesse.x * 0.09, 7, 4),
			Transform3D(Basis(), Vector3(groesse.x * 0.3,
			DECK_STAERKE * 0.5, groesse.y * 0.22)))
	_netz("Knospe", knospe,
			Materialbibliothek.einfarbig(Farben.BLUETE_MAGENTA, 0.6))


func _netz(bezeichnung: String, st: SurfaceTool, material: Material) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung,
			PropWerkzeug.fertig(st), material)
	if knoten != null:
		_bild.add_child(knoten)
