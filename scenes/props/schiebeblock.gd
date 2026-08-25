extends AnimatableBody3D
class_name Schiebeblock
## Steinblock, der im Takt quer über den Weg fährt und den Spieler wegdrückt.
##
## Vorbild sind die Abendruinen (`doku/level-vorbilder.md`, 3-5). Dort ist der
## Block keine Falle, die trifft, sondern eine, die VERSETZT: Er schiebt den
## Spieler seitlich – auf einem breiten Weg ist das ein Ärgernis, an einer
## Kante der Sturz. Deshalb steht er nie in der Mitte eines Platzes, sondern
## immer dort, wo neben dem Weg nichts mehr kommt.
##
## Verwandt mit `Wasserplattform`: derselbe Takt aus Fahren und Warten, nur
## waagerecht quer statt senkrecht, und mit dem Zweck zu schieben statt zu
## tragen. Oben drauf trägt er trotzdem – wer im richtigen Moment aufspringt,
## fährt mit.
##
## WAS PASSIERT, WENN DER SPIELER ZWISCHEN BLOCK UND WAND GERÄT?
##
## Nachgemessen statt geraten (Block 1.6 x 1.1 x 1.6, Wand 0.2 m hinter der
## Endstellung, Figur dazwischen):
##
##   * Der Block schiebt die Figur vor sich her, bis sie an der Wand steht,
##     und drückt sie dann gut 0.3 m IN die Wand hinein. Godot verrechnet
##     Überschneidungen nicht als Druck, sondern schiebt Körper auf dem
##     kürzesten Weg auseinander; widersprechen sich zwei solche Wege,
##     gewinnt der des bewegten Körpers.
##   * Zerquetscht wird nichts – Godot kennt kein Zerquetschen. Kein Schaden,
##     kein Tod, und auch kein Zappeln zwischen den beiden Wänden.
##   * Fährt der Block zurück, schiebt die Wand die Figur wieder heraus, und
##     sie steht sauber davor. Sie bleibt also nicht hängen.
##   * Steht die Figur ganz IM Block (falsch gesetzt oder hineingesprungen),
##     hebt dieselbe Entpenetration sie von selbst auf dessen Oberseite: Bei
##     1.1 m Blockhöhe gegen 1.3 m Figurhöhe ist der kürzeste Weg nach
##     draußen der nach oben.
##
## Eine Fangvorrichtung gegen Festklemmen braucht es deshalb nicht; sie wäre
## toter Code. Was es braucht, ist Levelplanung: Der Block VERSETZT den
## Spieler, er tötet ihn nicht. Gefährlich wird er erst über einer Kante.
## Und er sollte niedrig bleiben – hoch genug zum Draufspringen, niedrig
## genug, dass der Ausweg aus der Enge nach oben zeigt.

## Kantenlängen des Blocks in Metern.
@export var groesse := Vector3(1.6, 1.1, 1.6)

## Fahrstrecke in Metern, gemessen von `ort` aus.
@export var weite := 3.0

## Fahrtrichtung in Levelkoordinaten, vor `drehung`. `Vector3.RIGHT` schiebt
## quer zum Weg, `Vector3.FORWARD` längs.
@export var achse := Vector3.RIGHT

## Dauer einer Fahrt von einem Ende zum anderen in Sekunden.
@export var fahrzeit := 1.4

## Wartezeit an jedem Ende. Ohne Pause ist der Block kein Takt, sondern nur
## Rauschen – die Pause ist das Zeitfenster, in dem man vorbeikommt.
@export var pause := 1.0

## Verschiebt den Takt, als Anteil einer ganzen Runde (0 bis 1). Damit laufen
## mehrere Blöcke versetzt und bilden eine Gasse, die sich öffnet und
## schließt.
@export var phase := 0.0

## Drehung um die Hochachse, damit `achse` zum Wegverlauf passt.
@export var drehung := 0.0

## Ausgangspunkt in Elternkoordinaten – die MITTE des Blocks (wie bei
## `Wasserplattform`), ein 1.1 m hoher Block steht also mit
## `ort.y = wegflaeche + 0.55`. Bleibt `ort` auf Null, gilt die Position,
## die der Knoten beim Start hat.
@export var ort := Vector3.ZERO

## Grundton des Gesteins. Der Ruinenstein der Vorlage ist kühl türkisgrau;
## die Bibliothek kennt keinen eingefärbten Stein, deshalb steht die Farbe
## hier – viel heller als der gemessene Wert `#34494A`: `albedo_color`
## MULTIPLIZIERT die Felstextur, der gemessene Ton ergab im Probebild einen
## fast schwarzen Klotz. Geblieben ist der Türkisstich, nicht die Tiefe.
@export var steinfarbe := Color(0.72, 0.86, 0.83)

## Farbe der Stoßkanten. Warmes Abendlicht gegen den kühlen Stein – die
## Signalfarbe sagt, an welchen zwei Seiten es weh tut, bevor der Block sich
## überhaupt bewegt hat.
@export var kantenfarbe := Color(0.57, 0.33, 0.11)

const BAND_DICKE := 0.14        ## Beschlagband um den Block
const KANTE := 0.05             ## so weit stehen die Stoßleisten vor

var _zeit := 0.0
var _fahrt := 0.0               ## 0 = an `ort`, 1 = am anderen Ende
var _richtung := Vector3.RIGHT  ## gedrehte, normierte Fahrachse


func _ready() -> void:
	add_to_group("schiebebloecke")
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	if ort == Vector3.ZERO:
		ort = position
	var a := achse
	if a.length_squared() < 0.000001:
		a = Vector3.RIGHT
	_richtung = (Basis(Vector3.UP, drehung) * a).normalized()
	_aufbauen()
	# Gleich zum Takt passend setzen, sonst springt der Block im ersten Bild
	# von seiner Ruhelage an seinen Platz.
	_takt()
	_stellen()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_zeit += delta
	_takt()
	_stellen()


## Setzt Ort und Drehung in EINEM Schreibzugriff auf `transform`.
##
## Getrennt geht es nicht: Bei einem Körper mit `sync_to_physics` steht der
## Knoten unter der Hoheit des Physikservers. Ein Schreiben auf `position`
## wirkt erst im nächsten Schritt, und ein anschließendes Schreiben auf
## `rotation` liest den noch alten Ursprung zurück und setzt ihn wieder ein –
## der Block bliebe im Nullpunkt stehen.
func _stellen() -> void:
	transform = Transform3D(Basis(Vector3.UP, drehung),
			ort + _richtung * (weite * _fahrt))


## Rechnet die Stelle im Takt aus: warten, fahren, warten, zurückfahren.
func _takt() -> void:
	var runde := fahrzeit * 2.0 + pause * 2.0
	if runde <= 0.0:
		_fahrt = 0.0
		return
	var p := fposmod(_zeit + phase * runde, runde)
	if p < pause:
		_fahrt = 0.0
	elif p < pause + fahrzeit:
		_fahrt = (p - pause) / fahrzeit
	elif p < pause * 2.0 + fahrzeit:
		_fahrt = 1.0
	else:
		_fahrt = 1.0 - (p - pause * 2.0 - fahrzeit) / fahrzeit


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	_stein_bauen()
	_beschlag_bauen()
	_stossleisten_bauen()

	var form := BoxShape3D.new()
	form.size = groesse
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	add_child(kollision)


func _stein_bauen() -> void:
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(groesse), Transform3D())
	_netz("Block", st, _gestein(steinfarbe), true)


## Beschlagband um die Blockmitte. Es steht nur wenige Zentimeter vor – so
## viel Abweichung von der Kollisionsform fällt nicht auf, gibt dem Block
## aber überhaupt erst eine Silhouette. Ein nackter Quader liest sich aus
## der Spielkamera als Loch in der Wand.
func _beschlag_bauen() -> void:
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(
			groesse.x + KANTE, BAND_DICKE, groesse.z + KANTE)),
			Transform3D(Basis(), Vector3(0.0, -groesse.y * 0.16, 0.0)))
	_netz("Beschlag", st, Materialbibliothek.metall(Farben.ROST), true)


## Warnleisten auf den beiden Stoßseiten – quer zur Fahrachse.
##
## Sie sitzen dort, wo der Block trifft, und nur dort. Damit ist die
## Fahrachse schon im Stillstand ablesbar, und der Spieler weiß, an welcher
## Seite er nichts verloren hat, bevor sich etwas bewegt.
func _stossleisten_bauen() -> void:
	var st := PropWerkzeug.bauer()
	# `achse` zeigt vor der Drehung in Blockkoordinaten – die Leisten müssen
	# also an die Seite, in die die ungedrehte Achse zeigt.
	var lokal := achse
	if lokal.length_squared() < 0.000001:
		lokal = Vector3.RIGHT
	lokal = lokal.normalized()
	var quer := Vector3.UP.cross(lokal)
	if quer.length_squared() < 0.000001:
		quer = Vector3.RIGHT
	quer = quer.normalized()
	var halbe := groesse * 0.5
	var tiefe := absf(lokal.x) * halbe.x + absf(lokal.z) * halbe.z
	var breite := (absf(quer.x) * groesse.x + absf(quer.z) * groesse.z) * 0.82
	for seite: float in [-1.0, 1.0]:
		for i in 3:
			var y := (float(i) - 1.0) * groesse.y * 0.26
			var mitte := lokal * (seite * (tiefe + KANTE * 0.5)) + Vector3(0.0, y, 0.0)
			var leiste := PropWerkzeug.kasten(Vector3(
					absf(quer.x) * breite + absf(lokal.x) * KANTE + 0.02,
					groesse.y * 0.13,
					absf(quer.z) * breite + absf(lokal.z) * KANTE + 0.02))
			PropWerkzeug.anfuegen(st, leiste, Transform3D(Basis(), mitte))
	_netz("Stossleisten", st, Materialbibliothek.einfarbig(kantenfarbe, 0.6), true)


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
## Je Farbe entsteht das Material einmal und wird von allen Blöcken geteilt;
## die Bibliothek selbst bleibt unangetastet.
static func _gestein(farbe: Color) -> Material:
	var schluessel := farbe.to_rgba32()
	var vorhanden: Variant = _steine.get(schluessel)
	if vorhanden != null:
		return vorhanden
	var m := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	_steine[schluessel] = m
	return m
