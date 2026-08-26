extends Node3D
class_name Feuerspeier
## Feuerspeier: eine Düse, die im Takt einen gerichteten Feuerstoß ausstößt.
##
## Der Taktgeber, den unsere Vorbilder am häufigsten brauchen – Festungs-
## fackel, Götzenkopf, Grabfalle und Ofendüse sind dasselbe Bauteil mit
## anderer Verkleidung. Anders als ein Stachelfeld kostet er keinen Platz
## im Weg: Solange er ruht, ist der Korridor frei. Die Frage ist nicht
## „wo laufe ich?", sondern „wann laufe ich?".
##
## Der Takt hat drei Abschnitte und ist mit Absicht von weitem lesbar:
##
##   Ruhe        – nichts geschieht, der Weg ist frei (Rest des `takt`)
##   `warnzeit`   – Glut sammelt sich sichtbar in der Düsenmündung, harmlos
##   `speit_zeit` – die Flamme fährt aus, ist tödlich, zieht sich zurück
##
## `phase` verschiebt den Takt gegen andere Speier (0..1 = Anteil eines
## vollen Takts). Erst dadurch entsteht aus einer Reihe von Düsen ein
## Rhythmus, durch den man hindurchläuft, statt vier gleichzeitiger Wände.
##
## Die Flamme WÄCHST und schrumpft, statt zu erscheinen und zu verschwinden.
## Das ist keine Zierde: Wer sie kommen sieht, kann noch zurück. Und der
## Schadensbereich folgt der sichtbaren Länge Bild für Bild – ein Feuer,
## das weiter trifft, als es aussieht, ist der häufigste Fehler bei diesem
## Bauteil und macht es unspielbar.
##
## AUSRICHTUNG: Die Flamme zeigt in lokale −Z-Richtung. Ein Level dreht den
## Speier also über `rotation.y` in die gewünschte Richtung (0 = Flamme
## zeigt nach −Z). `schwenkt` legt eine langsame Pendelbewegung um genau
## diese Ruhelage, ohne `rotation.y` anzurühren – damit bleibt die
## Ausrichtung des Levels immer die Mitte des Schwenks.

## Reichweite der voll ausgefahrenen Flamme in Metern.
@export var laenge := 3.0

## Durchmesser der Flamme an der Düse in Metern.
@export var dicke := 0.8

## Länge eines vollen Durchlaufs in Sekunden – die Uhr dieses Bauteils.
##
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0.
## Vorher lief der Speier auf 3,6 s und die Taktfläche auf 3,8 s; nebenein-
## ander wiederholte sich ihr gemeinsames Muster erst nach 68,4 Sekunden.
@export var takt := 4.0

## Vorwarnung in Sekunden: Die Glut glimmt schon, das Feuer kommt aber erst.
@export var warnzeit := 0.7

## Dauer des Feuerstoßes in Sekunden – einschließlich Aus- und Einfahren.
@export var speit_zeit := 1.1

## Verschiebt den Takt gegen andere Speier (0..1 = Anteil eines Takts).
@export var phase := 0.0

## Schwenkt der Speier langsam hin und her? Macht aus einer festen Gefahr
## eine bewegliche: Der Spieler muss Takt UND Winkel zugleich lesen.
@export var schwenkt := false

## Voller Öffnungswinkel des Schwenks in Grad (halb nach jeder Seite).
@export var schwenk_winkel := 60.0

## Dauer einer vollen Hin- und Herbewegung des Schwenks in Sekunden.
@export var schwenk_dauer := 4.0

## Farbe der Flamme. Leuchtet und flackert.
@export var farbe_flamme := Color(1.0, 0.52, 0.11)

## Farbe der Düse. Sie ist Metall, nicht Gefahr – deshalb stumpf.
@export var farbe_duese := Farben.KISTE_EISEN

## Anteil der Speiphase, den das Aus- bzw. Einfahren dauert. Der Rest ist
## volle Länge. 0.28 heißt: gut ein Viertel Vorlauf, ein Viertel Nachlauf.
const AUSFAHR_ANTEIL := 0.28
## Ab dieser Flammenlänge (Anteil) tut das Feuer weh. Der erste Zentimeter
## Glut ist noch keine Flamme; darunter wäre der Treffer nicht zu sehen.
const SCHADEN_AB := 0.12
## Radius des Schadenszylinders im Verhältnis zur `dicke`. Etwas kleiner
## als der sichtbare Kegelfuß, weil der Kegel nach vorn dünner wird –
## lieber einmal zu wenig getroffen als einmal zu viel.
const SCHADEN_RADIUS := 0.40
## Länge der Düse nach hinten in Metern. Die Mündung sitzt im Ursprung,
## der Körper steckt dahinter (also in der Wand, an der sie hängt).
const DUESEN_LAENGE := 0.45
const SEITEN := 8

var _schwenker: Node3D          ## trägt alles, pendelt bei `schwenkt`
var _achse: Node3D              ## dreht lokales +Y auf −Z (Blickrichtung)
var _flamme: MeshInstance3D     ## Netz von y=0 bis y=1, in Y gestreckt
var _glut: MeshInstance3D       ## Vorwarnung in der Mündung
var _flammen_material: StandardMaterial3D
var _glut_material: StandardMaterial3D
var _zone: Area3D
var _kollision: CollisionShape3D
var _form: CylinderShape3D
var _zeit := 0.0


func _ready() -> void:
	add_to_group("gefahren")
	_aufbauen()
	_bild_setzen(0.0, 0.0)


func _physics_process(delta: float) -> void:
	_zeit += delta

	if schwenkt:
		var welle := sin(_zeit * TAU / maxf(schwenk_dauer, 0.1) + phase * TAU)
		_schwenker.rotation.y = welle * deg_to_rad(schwenk_winkel) * 0.5

	var takt := _taktlaenge()
	var p := fposmod(_zeit + phase * takt, takt)
	var grad := _flammengrad(p)
	_bild_setzen(grad, _glutgrad(p))

	if grad <= SCHADEN_AB:
		return
	for koerper in _zone.get_overlapping_bodies():
		if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
			koerper.schaden_nehmen()


## Dauer eines vollen Takts. Untergrenze, damit ein versehentlich auf 0
## gesetzter Speier nicht durch fposmod() ins Nichts rechnet.
func _taktlaenge() -> float:
	return maxf(takt, 0.1)


## Ruhe ist der Rest des Takts. So bleibt `takt` die Uhr, während Warn- und
## Speizeit absolute Reaktionszeiten bleiben, die nicht mitskalieren.
func _ruhe() -> float:
	return maxf(_taktlaenge() - warnzeit - speit_zeit, 0.2)


## Ausfahrgrad der Flamme (0 = eingezogen, 1 = volle `laenge`).
func _flammengrad(p: float) -> float:
	var beginn := _ruhe() + warnzeit
	if p < beginn or speit_zeit <= 0.0:
		return 0.0
	var t := (p - beginn) / speit_zeit
	if t < AUSFAHR_ANTEIL:
		return t / AUSFAHR_ANTEIL
	if t > 1.0 - AUSFAHR_ANTEIL:
		return maxf(1.0 - t, 0.0) / AUSFAHR_ANTEIL
	return 1.0


## Glut in der Mündung: schwillt in der Warnzeit an, brennt während des
## Stoßes weiter und verglüht danach. Sie ist das einzige Signal, das der
## Spieler VOR dem Feuer bekommt – deshalb steigt sie im Quadrat an, wird
## also gegen Ende der Warnzeit deutlich schneller heller.
func _glutgrad(p: float) -> float:
	var ruhe := _ruhe()
	if p < ruhe:
		# Nachglühen: der Rest des vorigen Stoßes verklingt.
		var rest := 1.0 - p / maxf(ruhe * 0.35, 0.05)
		return maxf(rest, 0.0)
	if p < ruhe + warnzeit:
		var t := (p - ruhe) / maxf(warnzeit, 0.01)
		return t * t
	return 1.0


## Setzt Flammenlänge, Flackern, Glut und Schadenszylinder auf einen Stand.
func _bild_setzen(grad: float, glut: float) -> void:
	if _flamme == null or _glut == null:
		return
	var l := laenge * grad

	# Zwei unstimmige Schwingungen ergeben ein Flackern ohne erkennbaren
	# Rhythmus; eine einzelne Sinuskurve sähe nach Blinklicht aus.
	var flacker := sin(_zeit * 37.0) * 0.6 + sin(_zeit * 23.0) * 0.4

	_flamme.visible = grad > 0.001
	_flamme.scale = Vector3(1.0 + flacker * 0.05, maxf(l, 0.001),
			1.0 + flacker * 0.05)
	_flammen_material.emission_energy_multiplier = 2.1 + flacker * 0.55

	_glut.visible = glut > 0.02
	var g := maxf(glut, 0.02)
	_glut.scale = Vector3(g, g, g)
	_glut_material.emission_energy_multiplier = 0.6 + glut * 2.2

	# Der Schadenszylinder deckt genau die sichtbare Länge ab: Fuß in der
	# Mündung, Spitze am Flammenende.
	_form.height = maxf(l, 0.02)
	_kollision.position.y = _form.height * 0.5


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	_schwenker = Node3D.new()
	_schwenker.name = "Schwenker"
	add_child(_schwenker)

	# Alles Gerichtete hängt unter dieser Achse: Sie kippt das lokale +Y
	# auf −Z. Dadurch dürfen Flamme, Düse und Zylinderform in ihrer
	# natürlichen Y-Ausrichtung gebaut werden und zeigen trotzdem nach vorn.
	_achse = Node3D.new()
	_achse.name = "Achse"
	_achse.rotation_degrees.x = -90.0
	_schwenker.add_child(_achse)

	_duese_bauen()
	_flamme_bauen()
	_zone_bauen()


## Kegelstumpf als Düse: hinten breit, an der Mündung eng, dazu ein
## Mündungsring. Die Mündung liegt im Ursprung, der Körper dahinter.
func _duese_bauen() -> void:
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(dicke * 0.62, dicke * 0.36,
			DUESEN_LAENGE, SEITEN, true),
			Transform3D(Basis(), Vector3(0.0, -DUESEN_LAENGE * 0.5, 0.0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(dicke * 0.44, dicke * 0.40,
			0.1, SEITEN, false),
			Transform3D(Basis(), Vector3(0.0, -0.04, 0.0)))
	var knoten := PropWerkzeug.mesh_knoten("Duese", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(farbe_duese))
	if knoten != null:
		_achse.add_child(knoten)

	# Glut sitzt in der Mündung und wird über die Knotenskalierung
	# aufgeblasen – deshalb ein eigenes, kleines Netz mit Radius 1 · Anteil.
	_glut_material = Materialbibliothek.leuchtend(
			farbe_flamme.lightened(0.25), 1.0).duplicate()
	_glut = PropWerkzeug.mesh_knoten("Glut",
			PropWerkzeug.kugel(dicke * 0.30, 7, 4), _glut_material, false)
	if _glut != null:
		_glut.position.y = 0.02
		_achse.add_child(_glut)


## Flamme als gestreckter Kegel, gebaut von y=0 bis y=1. Die Länge kommt
## später allein über `scale.y` – so bleibt der Fuß immer in der Mündung
## und der Kegel wird nicht in der Breite mitgezogen.
func _flamme_bauen() -> void:
	var r := dicke * 0.5
	var st := PropWerkzeug.bauer()
	# Kurzer Ansatz, der zur Mündung hin schmaler wird …
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(r * 0.62, r, 0.3, SEITEN, false),
			Transform3D(Basis(), Vector3(0.0, 0.15, 0.0)))
	# … und die lange Spitze.
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(r, 0.0, 0.7, SEITEN, false),
			Transform3D(Basis(), Vector3(0.0, 0.65, 0.0)))

	# Eigene Kopie des Materials: `Materialbibliothek.leuchtend()` gibt ein
	# gemeinsam genutztes Material zurück – flackerte der Speier darauf,
	# flackerte jedes Portal im Level mit.
	_flammen_material = Materialbibliothek.leuchtend(farbe_flamme, 2.1).duplicate()
	_flamme = PropWerkzeug.mesh_knoten("Flamme", PropWerkzeug.fertig(st),
			_flammen_material, false)
	if _flamme != null:
		_achse.add_child(_flamme)


func _zone_bauen() -> void:
	_zone = Area3D.new()
	_zone.name = "Zone"
	_zone.collision_layer = 0
	_zone.collision_mask = 2      # nur den Spieler beachten
	_zone.monitoring = true
	_form = CylinderShape3D.new()
	_form.radius = maxf(dicke * SCHADEN_RADIUS, 0.05)
	_form.height = 0.02
	_kollision = CollisionShape3D.new()
	_kollision.name = "Form"
	_kollision.shape = _form
	_zone.add_child(_kollision)
	_achse.add_child(_zone)
