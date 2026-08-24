extends Reiter
class_name Fluechtling
## Der Spieler auf der Flucht (Level 05) – zu Fuß, mit einem Riesenkeiler
## im Nacken.
##
## Erbt die Schienenlogik vom Reiter: Strecke, seitlicher Versatz und Höhe
## sind der ganze Zustand, die Weltposition wird daraus berechnet. Neu ist
## der Verfolger.
##
## Der Keiler ist kein Gegner mit Trefferzone, sondern ein Abstand. Er
## läuft auf derselben Kurve, ein Stück hinter dem Spieler, und holt auf,
## wenn dieser langsamer wird. Ein Hindernis tötet deshalb nicht sofort –
## es bremst nur, und der Rest ergibt sich. Das ist der Unterschied zum
## Ritt in Level 04, wo jede Berührung sofort abwirft: Hier soll die
## Bedrohung sichtbar näher kommen, statt schlagartig zuzuschlagen.

## Tempo des Keilers in m/s. Ein eigener Wert und kein Anteil vom
## Höchsttempo des Spielers: Als Anteil (0,86 × 20 = 17,2 m/s) lag er über
## dem Anfangstempo des Spielers, der Rückstand schrumpfte also von der
## ersten Sekunde an und war nach 3,8 s aufgebraucht – 22 Tode im
## Ablauftest, ohne dass ein einziger Fehler nötig war. Er muss langsamer
## laufen als der Spieler anfängt, sonst gibt es keine Flucht, nur ein
## Ende mit Ansage.
@export var keiler_tempo := 12.5
## Abstand des Keilers zum Spieler beim Start.
@export var vorsprung := 16.0
## Kleinster Abstand, bevor er zupackt.
@export var todesabstand := 2.2
## Größter Abstand – weiter zurück fällt er nicht, sonst verschwindet er.
@export var hoechstabstand := 26.0
## Wie schnell sich der Rückstand des Keilers verändert, in Metern je
## Sekunde und Meter Tempounterschied.
@export var aufhol_faktor := 1.0
## Tempoverlust bei einem Treffer, als Anteil.
@export var treffer_bremse := 0.55
## Wie lange nach einem Treffer nicht gelenkt werden kann.
@export var taumel_dauer := 0.5

signal keiler_naehe(anteil: float)

var keiler: Keiler
var abstand_keiler := 16.0
var _taumel := 0.0


func _ready() -> void:
	super._ready()
	abstand_keiler = vorsprung
	lenk_richtung = -1.0   # Kamera steht vorn und blickt zurück


func _physics_process(delta: float) -> void:
	_taumel = maxf(_taumel - delta, 0.0)
	super._physics_process(delta)
	if verlauf == null or gesperrt or _fertig:
		return
	_keiler_nachziehen(delta)


## Der Keiler läuft mit festem Tempo; der Abstand wächst und schrumpft
## also mit dem Tempo des Spielers. Wer stehen bleibt, wird eingeholt.
func _keiler_nachziehen(delta: float) -> void:
	var unterschied := tempo - keiler_tempo
	abstand_keiler = clampf(abstand_keiler + unterschied * aufhol_faktor * delta,
			0.0, hoechstabstand)

	var naehe := 1.0 - clampf(abstand_keiler / hoechstabstand, 0.0, 1.0)
	keiler_naehe.emit(naehe)

	if is_instance_valid(keiler):
		var s := maxf(strecke - abstand_keiler, 0.0)
		keiler.global_position = LevelWerkzeuge.punkt(verlauf, s, _seitlich * 0.4, 0.0)
		keiler.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		keiler.aktualisiere(delta, tempo / maxf(tempo_max, 0.001), naehe)

	if abstand_keiler <= todesabstand:
		sterben()


## Ein Hindernis wirft hier nicht ab, es bremst – und der Keiler kommt
## näher. Während der Unverwundbarkeit wirkungslos.
func schaden_nehmen() -> void:
	if invuln > 0.0 or _fertig:
		return
	# Der Schutz fängt das Stolpern ab – man verliert also keinen Vorsprung.
	if GameState.schutz_verbrauchen():
		invuln = INVULN_ZEIT * 0.6
		return
	invuln = INVULN_ZEIT * 0.6
	_taumel = taumel_dauer
	tempo = maxf(tempo_start * 0.6, tempo * (1.0 - treffer_bremse))
	GameState.zeige_nachricht("Gestolpert!", 0.9)


## Nach dem Tod bekommt der Spieler seinen Vorsprung zurück – sonst
## stünde er beim Neustart sofort wieder unter den Hauern.
func respawn() -> void:
	super.respawn()
	abstand_keiler = vorsprung
	_taumel = 0.0


## Im Taumeln lässt sich nicht lenken.
func _lenken(delta: float) -> void:
	if _taumel > 0.0:
		return
	super._lenken(delta)
