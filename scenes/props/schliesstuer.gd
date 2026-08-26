extends Node3D
class_name Schliesstuer
## Tor, das sich im Takt öffnet und schließt – ein Zeitfenster im Weg.
##
## Zwei Torhälften, die aufeinander zufahren. Kein Fallgatter, und zwar
## aus zwei Gründen: Erstens sieht man von der Korridorkamera aus, wie der
## Spalt in der Bildmitte schmaler wird – ein Gatter, das von oben kommt,
## verdeckt beim Fallen genau die Stelle, die man einschätzen müsste.
## Zweitens presst ein Gatter jeden, der darunter steht, nach unten in den
## Boden; zwei waagerechte Hälften schieben ihn dagegen zur Seite, und das
## bekommt die Figur ohne Schaden ab.
##
## Das Tor BLOCKIERT, es TÖTET NICHT. Bei diesem Takt wäre ein tödliches
## Tor zu hart: Das Zeitfenster ist kurz, es entscheiden Zehntelsekunden,
## und der Spieler soll seinen Fehler an der eigenen Ungeduld ablesen –
## nicht an einem Bildschirmtod, dessen Ursache er nicht mehr sieht.
## Wer zu spät kommt, steht davor und wartet eine Runde.
##
## Schließt das Tor, während der Spieler mittendrin steht, wird er von den
## Hälften zusammengeschoben. Die Flügel sind deshalb mit Absicht DÜNN
## (`TIEFE` = 0,34 m, die Spielerkapsel misst 0,76 m im Durchmesser): Die
## beiden seitlichen Schübe heben sich in der Mitte gegenseitig auf, und
## der kürzeste Weg aus dem Tor heraus zeigt nach vorn oder nach hinten.
## Die Figur wird also aus der Torebene herausgedrückt statt zerquetscht –
## sie verliert das Zeitfenster, nicht das Leben, und steckt nie fest.
##
## Mit `ausloesen()` bleibt das Tor offen stehen (etwa an einer
## `Ausloeseplatte`), `zuruecksetzen()` gibt es dem Takt zurück.

## Lichte Weite und Höhe des Durchgangs in Metern.
@export var breite := 3.6
@export var hoehe := 2.8

## Takt: offen stehen, zufahren, zu bleiben, auffahren – in Sekunden.
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0,
## damit mehrere Taktgeber nebeneinander ein lernbares Muster ergeben.
## Voller Zyklus ist `offen_zeit + zu_zeit + schliess_zeit * 2`.
## Vorgabe 2,0 + 1,0 + 2·0,5 = 4,0 s.
@export var offen_zeit := 2.0
@export var schliess_zeit := 0.5
@export var zu_zeit := 1.0

## Verschiebt den Takt gegen andere Türen. 0 bis 1 = eine volle Runde.
@export var phase := 0.0

## Farbe der Flügel. Die Kante am Spalt leuchtet in derselben Farbe –
## erst dadurch ist von weitem zu sehen, wie breit der Spalt noch ist.
@export var farbe := Color(0.66, 0.55, 0.34)

const TIEFE := 0.34           ## Dicke der Flügel (siehe Kopfkommentar)
const PFOSTEN := 0.36         ## Stärke von Pfosten und Sturz
const KANTE := 0.12           ## Breite des leuchtenden Streifens am Spalt

var _fluegel: Array[AnimatableBody3D] = []
var _zeit := 0.0
var _grad := 0.0              ## 0 = ganz offen, 1 = ganz zu
var _gehalten := false        ## von außen offen gehalten


func _ready() -> void:
	add_to_group("schliesstueren")
	_aufbauen()
	# Gleich zum Takt passend setzen, sonst stünde das Tor im ersten Bild
	# offen und schnappte danach sichtbar in seine Taktlage.
	_grad = _takt_grad(_takt_stelle())
	_stellen()
	for f in _fluegel:
		f.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_zeit += delta
	var ziel := 0.0 if _gehalten else _takt_grad(_takt_stelle())
	# Nicht springen lassen: Die Fahrgeschwindigkeit ist immer dieselbe,
	# egal ob der Takt sie vorgibt oder ein Auslöser dazwischenfunkt.
	_grad = move_toward(_grad, ziel, delta / maxf(schliess_zeit, 0.01))
	_stellen()


## Hält das Tor offen.
func ausloesen() -> void:
	_gehalten = true


## Gibt das Tor dem Takt zurück.
func zuruecksetzen() -> void:
	_gehalten = false


## 0 = ganz offen, 1 = ganz zu. Für Level, die etwas daran hängen wollen.
func schliessgrad() -> float:
	return _grad


# ---------------------------------------------------------------- Takt

## Stelle im Takt in Sekunden seit Rundenbeginn.
func _takt_stelle() -> float:
	var runde := offen_zeit + zu_zeit + schliess_zeit * 2.0
	if runde <= 0.0:
		return 0.0
	return fposmod(_zeit + phase * runde, runde)


## Verlauf über eine Runde: offen stehen, zufahren, zu bleiben, auffahren.
func _takt_grad(p: float) -> float:
	if p < offen_zeit:
		return 0.0
	if p < offen_zeit + schliess_zeit:
		return (p - offen_zeit) / maxf(schliess_zeit, 0.0001)
	if p < offen_zeit + schliess_zeit + zu_zeit:
		return 1.0
	return 1.0 - (p - offen_zeit - schliess_zeit - zu_zeit) \
			/ maxf(schliess_zeit, 0.0001)


## Setzt beide Flügel. Ort und Drehung in EINEM Schreibzugriff auf
## `transform`: Bei `sync_to_physics` steht der Knoten unter der Hoheit
## des Physikservers, getrennte Zugriffe auf `position` und `rotation`
## heben einander auf. Siehe `Wasserplattform._stellen()`.
func _stellen() -> void:
	var halb := breite * 0.5
	for i in _fluegel.size():
		var seite := -1.0 if i == 0 else 1.0
		# offen: Flügel steht neben dem Durchgang; zu: er füllt seine Hälfte
		var x := seite * lerpf(halb * 1.5, halb * 0.5, _grad)
		_fluegel[i].transform = Transform3D(Basis(),
				Vector3(x, hoehe * 0.5, 0.0))


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()
	_fluegel.clear()

	_rahmen_bauen()
	for i in 2:
		_fluegel.append(_fluegel_bauen(-1.0 if i == 0 else 1.0))


## Pfosten und Sturz. Nur Bild, kein Körper: Die Wände des Korridors
## stehen schon, ein zweiter Satz Kollisionen daneben würde die Figur nur
## an unsichtbaren Kanten hängen lassen.
func _rahmen_bauen() -> void:
	var st := PropWerkzeug.bauer()
	var aussen := breite * 2.0 + PFOSTEN * 2.0
	for seite in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(
				Vector3(PFOSTEN, hoehe + PFOSTEN, TIEFE * 1.6)),
				Transform3D(Basis(), Vector3(
				seite * (breite + PFOSTEN * 0.5), (hoehe + PFOSTEN) * 0.5, 0.0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(
			Vector3(aussen, PFOSTEN, TIEFE * 1.6)),
			Transform3D(Basis(), Vector3(0.0, hoehe + PFOSTEN * 0.5, 0.0)))
	var knoten := PropWerkzeug.mesh_knoten("Rahmen", PropWerkzeug.fertig(st),
			Materialbibliothek.fels())
	if knoten != null:
		add_child(knoten)


## Ein Flügel: fester Körper mit Bild. `sync_to_physics` steht an, damit
## der Spieler mitgeschoben wird, statt in den Flügel einzusinken.
func _fluegel_bauen(seite: float) -> AnimatableBody3D:
	var koerper := AnimatableBody3D.new()
	koerper.name = "FluegelLinks" if seite < 0.0 else "FluegelRechts"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	koerper.sync_to_physics = true
	add_child(koerper)

	var form := BoxShape3D.new()
	form.size = Vector3(breite * 0.5, hoehe, TIEFE)
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	koerper.add_child(kollision)

	# Platte mit waagerechten Bändern – die Bänder zeigen im Fahren, wie
	# schnell der Flügel läuft; eine glatte Fläche wirkt beim Zufahren
	# fast unbewegt.
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(
			Vector3(breite * 0.5, hoehe, TIEFE)), Transform3D())
	var baender := maxi(int(hoehe / 0.7), 2)
	for i in baender:
		var y := -hoehe * 0.5 + hoehe * (float(i) + 0.5) / float(baender)
		PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(
				Vector3(breite * 0.46, 0.1, TIEFE * 1.12)),
				Transform3D(Basis(), Vector3(0.0, y, 0.0)))
	var bild := PropWerkzeug.mesh_knoten("Bild", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(farbe))
	if bild != null:
		koerper.add_child(bild)

	# Leuchtstreifen an der Kante, die auf die andere zufährt.
	var kst := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(kst, PropWerkzeug.kasten(
			Vector3(KANTE, hoehe * 0.94, TIEFE * 1.2)),
			Transform3D(Basis(), Vector3(
			-seite * (breite * 0.25 - KANTE * 0.5), 0.0, 0.0)))
	var kante := PropWerkzeug.mesh_knoten("Spaltkante",
			PropWerkzeug.fertig(kst),
			Materialbibliothek.leuchtend(farbe, 1.3), false)
	if kante != null:
		koerper.add_child(kante)

	return koerper
