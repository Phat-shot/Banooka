extends Gegner
class_name Schwarm
## Schwarm – eine Wolke kleiner Flieger, die als EINS kommt und als EINS fällt.
##
## Vorbild sind die Bienenschwärme des Dschungels. Der Reiz daran ist
## nicht "mehr Trefferpunkte", sondern eine andere FORM von Gegner: Was
## einen verfolgt, ist keine Silhouette mit einem Fuß auf dem Boden,
## sondern eine Fläche, die um einen Mittelpunkt schwirrt. Man weicht ihr
## nicht aus wie einem Käfer, man läuft ihr davon – oder man dreht sich
## einmal richtig, und alles fällt auf einmal.
##
## Deshalb: Kollision und Treffer laufen ausschließlich über den
## Mittelpunkt (die Trefferzone der Szene). Die Einzeltiere sind reine
## Optik und haben keine eigene Zone. Ein Schwarm mit sieben Trefferzonen
## wäre siebenmal so teuer und dabei schlechter zu lesen.
##
## NUR durch den Drehschlag (Angriff.SPIN) zu besiegen:
##   * Er fliegt in Brusthöhe  -> unten geht der Slide ins Leere.
##   * Er ist eine Wolke       -> es gibt nichts, worauf man landen kann;
##                                jedes Tier trägt seinen Stachel sichtbar.
##   * Die Wolke ist breiter als ein Einzelgegner – der Spin greift 1,7 m,
##     das reicht bequem hinein. Genau dafür ist sie so gebaut.
##
## TEMPO – bewusst langsam:
## Der Spieler läuft `RUN_SPEED` = 8,5 m/s. Ein Schwarm mit 3,4 m/s ist
## damit auf 40 % gedrosselt und in gerader Linie IMMER abzuschütteln.
## Das ist Absicht: Ein Verfolger, der schneller ist als der Verfolgte,
## lässt nur noch die Wahl zwischen Kämpfen und Sterben – und nimmt dem
## Level damit sein eigentliches Thema, den Wechsel aus Rennen und
## Stehenbleiben. Gefährlich wird der Schwarm dort, wo man anhalten muss:
## vor einem Sprung, an einer Kiste, in einer Sackgasse. Er holt einen
## nicht ein, er wartet darauf, dass man zögert.

## So viele Einzeltiere schwirren sichtbar umher.
@export var anzahl := 7
## Halbmesser der Wolke, in dem sie ihre Bahnen ziehen.
@export var wolkenradius := 0.9
## Bis zu diesem Abstand verfolgt er den Spieler.
@export var reichweite := 9.0
## Verfolgungstempo in m/s (siehe Kopfkommentar).
@export var folgetempo := 3.4
## Tempo der Einzelbahnen innerhalb der Wolke.
@export var schwirrtempo := 3.0
## Farbe der Tierkörper.
@export var farbe_koerper := Farben.KISTE_FRAGE
## Farbe der Flügel (wird durchscheinend verwendet).
@export var farbe_fluegel := Farben.EIS_HELL
## Flughöhe des Wolkenmittelpunkts über dem Boden.
@export var schwebehoehe := 1.45

## Rückweg zum Ausgangsort ist gemütlicher als die Jagd.
const HEIMTEMPO_FAKTOR := 0.7
## So schnell folgt die Wolke einem Höhenunterschied (Stufen, Plattformen).
const STEIG_FAKTOR := 0.6
## Schlagfrequenz der Flügel.
const FLUEGEL_TAKT := 26.0
## Wie weit die Tiere beim Sterben auseinanderstieben.
const STIEB_TEMPO := 4.5

var _tiere: Array[Node3D] = []
var _fluegel: Array[Node3D] = []
var _phasen: Array[float] = []
var _weiten: Array[float] = []
var _neigungen: Array[float] = []
var _letzte: Array[Vector3] = []
var _todflug: Array[Vector3] = []
var _jagt := false


func _init() -> void:
	# Nur der Drehschlag räumt die Wolke ab – ein einziger, gut gesetzter.
	besiegbar_durch = Angriff.SPIN
	# Er patrouilliert nicht, er verfolgt. Die Achse bleibt trotzdem
	# gesetzt, weil `_weg_richtung()` der Basisklasse darauf zurückfällt.
	patrouille_weite = 0.0
	tempo = 0.0
	# Ein ganzer Schwarm ist einen ganzen Batzen Früchte wert – im Vorbild
	# ist der saubere Schlag in die Wolke die Extraleben-Belohnung.
	fruechte = 5


func _ready() -> void:
	super._ready()
	_trefferzone_anpassen()


## Zieht die Trefferzone auf Wolkengröße und -höhe.
##
## Die Szene bringt eine Kugel mit, aber Höhe und Radius hängen an
## `schwebehoehe` und `wolkenradius`, und die darf das Level setzen. Ohne
## das säße die Zone bei geändertem Export woanders als die Wolke.
func _trefferzone_anpassen() -> void:
	if trefferzone == null:
		return
	for kind in trefferzone.get_children():
		var form := kind as CollisionShape3D
		if form == null:
			continue
		form.position.y = schwebehoehe
		var kugel := form.shape as SphereShape3D
		if kugel != null:
			kugel.radius = maxf(wolkenradius, 0.2)


# ---------------------------------------------------------- Optik

## Ein Tier je Platz in der Wolke: gestreifter Körper, zwei schlagende
## Flügel, ein dunkler Stachel. Klein, aber kräftig gezeichnet – aus der
## Spielkamera ist ein Schwarm sonst nur ein Fleck.
func _baue() -> void:
	var koerper_mat := Materialbibliothek.einfarbig(farbe_koerper, 0.6)
	var streifen_mat := Materialbibliothek.einfarbig(farbe_koerper.darkened(0.72), 0.6)
	var fluegel_mat := Materialbibliothek.transparent(farbe_fluegel, 0.5)

	var rng := PropWerkzeug.zufall(4242)
	for i in maxi(anzahl, 1):
		var tier := Node3D.new()
		tier.name = "Tier%d" % i
		modell.add_child(tier)
		_tiere.append(tier)

		# Bahnen leicht verschieden: gleiche Formel, andere Phase, andere
		# Weite, andere Neigung. Erst dadurch lebt die Wolke, statt zu
		# rotieren wie ein Karussell.
		_phasen.append(rng.randf() * TAU)
		_weiten.append(rng.randf_range(0.45, 1.0))
		_neigungen.append(rng.randf() * TAU)
		_letzte.append(Vector3.ZERO)
		_todflug.append(Vector3.ZERO)

		var groesse := rng.randf_range(0.85, 1.15)
		_teil(tier, _kugel(0.13, 8, 6), koerper_mat, Vector3.ZERO, Vector3.ZERO,
				Vector3(0.85, 0.85, 1.35) * groesse, "Leib")
		_teil(tier, _kugel(0.1, 7, 5), streifen_mat, Vector3(0.0, 0.0, 0.05),
				Vector3.ZERO, Vector3(0.95, 0.95, 0.45) * groesse, "Streifen")
		_teil(tier, _kugel(0.09, 7, 5), streifen_mat, Vector3(0.0, 0.0, -0.13),
				Vector3.ZERO, Vector3(0.9, 0.9, 0.7) * groesse, "Kopf")
		# Stachel nach hinten unten: die Warnung, dass hier nichts zu
		# holen ist – weder von oben noch von unten.
		_teil(tier, _zylinder(0.03, 0.0, 0.16, 5), streifen_mat,
				Vector3(0.0, -0.03, 0.17), Vector3(-70.0, 0.0, 0.0),
				Vector3.ONE * groesse, "Stachel")

		for seite: float in [-1.0, 1.0]:
			var gelenk := Node3D.new()
			gelenk.name = "Fluegelgelenk"
			gelenk.position = Vector3(0.03 * seite, 0.07, 0.0)
			tier.add_child(gelenk)
			_fluegel.append(gelenk)
			_teil(gelenk, _kugel(0.16, 7, 4), fluegel_mat,
					Vector3(0.16 * seite, 0.0, 0.0), Vector3.ZERO,
					Vector3(1.0, 0.07, 0.5) * groesse, "Fluegel")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_wolke_bewegen(delta)
	_tiere_schwirren(delta)


## Die Wolke als Ganzes: hinter dem Spieler her oder zurück nach Hause.
##
## `_setze_hoehe()` der Basisklasse wird hier bewusst NICHT benutzt: Das
## klebt die Höhe an `_start_position.y` fest, und genau das darf ein
## Verfolger nicht – er muss dem Spieler auch eine Stufe hinauf folgen.
## Der Knoten selbst bleibt dabei auf Bodenhöhe (wie bei der Frostmotte),
## die Flughöhe steckt im Modell und in der Trefferzone. So passt er
## weiter zu `korridor_level.gegner()`, das Gegner auf den Weg setzt.
func _wolke_bewegen(delta: float) -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	var ziel := _start_position
	_jagt = false
	if spieler != null and not _in_deckung(spieler):
		var d := spieler.global_position - global_position
		d.y = 0.0
		if d.length() <= reichweite:
			_jagt = true
			ziel = spieler.global_position

	var schritt := folgetempo * delta
	if not _jagt:
		schritt *= HEIMTEMPO_FAKTOR

	var jetzt := global_position
	var flach := Vector3(ziel.x - jetzt.x, 0.0, ziel.z - jetzt.z)
	if flach.length() > 0.02:
		global_position = jetzt + flach.normalized() * minf(schritt, flach.length())

	# Höhe getrennt und langsamer: Ein Schwarm, der jeden Sprung des
	# Spielers senkrecht mitmacht, wirkt wie an ihn geklebt.
	var y_ziel := ziel.y
	var y_neu := move_toward(global_position.y, y_ziel, schritt * STEIG_FAKTOR)
	global_position = Vector3(global_position.x, y_neu, global_position.z)


## Liegt der Spieler geduckt in einem Deckungsfleck?
##
## Der Fleck weiß selbst, wer auf ihm steht und ob derjenige geduckt ist
## (`Deckungsfleck.ist_in_deckung`); hier wird nur gefragt. Die Gruppe ist
## in Leveln ohne Flecken leer, die Schleife kostet dort nichts.
func _in_deckung(spieler: Node3D) -> bool:
	for fleck in get_tree().get_nodes_in_group("deckungsflecken"):
		var f := fleck as Deckungsfleck
		if f != null and f.ist_in_deckung(spieler):
			return true
	return false


## In Deckung zieht die Wolke wirkungslos hinweg.
##
## Ohne diese Ausnahme wäre der Fleck eine Lüge: Er leuchtet, der Schwarm
## verliert das Ziel und schwebt heim – aber wer dabei unter ihm liegt,
## bekäme trotzdem Schaden, sobald sich Trefferzone und Figur berühren.
## Gefragt wird nicht "greift der Spieler an", sondern "greift er WIRKSAM
## an": Wer eben in den Fleck gesprungen ist, trägt noch 0,25 s
## Fall-Gedächtnis mit sich – gegen einen Schwarm nutzlos, aber genug, um
## eine Abfrage auf `angriffe() == 0` zu überlisten und ihn ausgerechnet
## beim Hineinwerfen sterben zu lassen. Der Drehschlag wirkt weiter.
func _treffer(spieler: Spieler) -> void:
	if not besiegt and spieler != null \
			and (spieler.angriffe() & besiegbar_durch) == 0 \
			and _in_deckung(spieler):
		return
	super(spieler)


## Die Einzeltiere auf ihren Achterbahnen um den Mittelpunkt.
func _tiere_schwirren(delta: float) -> void:
	var schlag := sin(_zeit * FLUEGEL_TAKT)
	for i in _tiere.size():
		var tier := _tiere[i]
		if not is_instance_valid(tier):
			continue
		var t := _zeit * schwirrtempo + _phasen[i]
		var r := wolkenradius * _weiten[i]
		# Liegende Acht: x = sin(t), z = sin(2t)/2, um die Hochachse gekippt.
		var x := sin(t) * r
		var z := sin(t * 2.0) * r * 0.5
		var w := _neigungen[i]
		var ort := Vector3(x * cos(w) - z * sin(w),
				schwebehoehe + sin(t * 1.7 + _phasen[i]) * r * 0.35,
				x * sin(w) + z * cos(w))
		# Blick in die eigene Flugrichtung – aus der Änderung abgelesen,
		# weil die Ableitung der gekippten Acht mehr Rechnerei wäre als
		# die Differenz zum letzten Bild.
		var d := ort - _letzte[i]
		if d.length() > 0.0005:
			tier.rotation.y = atan2(d.x, d.z)
		_letzte[i] = ort
		tier.position = ort

	for i in _fluegel.size():
		var gelenk := _fluegel[i]
		if is_instance_valid(gelenk):
			var seite := 1.0 if i % 2 == 0 else -1.0
			gelenk.rotation.z = seite * schlag * 0.9


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Der Mittelpunkt bleibt stehen, wo er getroffen wurde – was
	# auseinanderfliegt, sind die Tiere.
	_wegflug = Vector3.ZERO
	for i in _tiere.size():
		var tier := _tiere[i]
		if not is_instance_valid(tier):
			continue
		var raus := tier.position - Vector3(0.0, schwebehoehe, 0.0)
		if raus.length() < 0.05:
			raus = Vector3(cos(float(i)), 0.4, sin(float(i)))
		_todflug[i] = raus.normalized() * STIEB_TEMPO \
				+ Vector3.UP * (1.5 + float(i % 3) * 0.6)


## Die Wolke stiebt auseinander: Jedes Tier trudelt für sich davon und
## wird dabei kleiner. Kein Wegflug des Mittelpunkts – sonst zöge er die
## Tiere alle in dieselbe Richtung, und der Schwarm fiele als Klumpen.
func _todesanimation(delta: float) -> void:
	for i in _tiere.size():
		var tier := _tiere[i]
		if not is_instance_valid(tier):
			continue
		_todflug[i] += Vector3.UP * TODES_G * delta * 0.35
		tier.position += _todflug[i] * delta
		tier.rotation.x += delta * 16.0
		tier.rotation.z += delta * 11.0
		tier.scale = tier.scale.lerp(Vector3(0.2, 0.2, 0.2), minf(delta * 2.6, 1.0))
	# Die Flügel schlagen wild weiter – das liest sich als Auflösen,
	# nicht als Abschalten.
	for i in _fluegel.size():
		var gelenk := _fluegel[i]
		if is_instance_valid(gelenk):
			gelenk.rotation.z = sin(_zeit * 40.0 + float(i)) * 1.2
