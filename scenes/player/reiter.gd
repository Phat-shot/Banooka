extends Spieler
class_name Reiter
## Der Spieler zu Pferde – genauer: auf einer Wildkatze (Level 04).
##
## Ein Ritt-Level läuft nach anderen Regeln als ein Korridor-Level: die
## Katze rennt von selbst und wird immer schneller, gelenkt wird nur quer
## zum Weg, gesprungen wie gewohnt. Anhalten oder umkehren geht nicht.
##
## Deshalb steht der Reiter NICHT auf `move_and_slide`, sondern klebt auf
## der Levelkurve: Strecke, seitlicher Versatz und Höhe sind der ganze
## Zustand, die Weltposition wird daraus jedes Bild neu berechnet. Ein
## Fahren gegen Wände gibt es damit gar nicht erst – Hindernisse sind
## Zonen, die Schaden machen, keine Körper zum Anrempeln.
##
## Er erbt von `Spieler` und ersetzt nur dessen Fortbewegung. Das ist
## nicht Bequemlichkeit: Kisten und Gegner prüfen `koerper is Spieler`, eine
## eigenständige Klasse liefe glatt durch sie hindurch, ohne dass etwas
## zerbricht. Geerbt bleiben damit auch Leben, Unverwundbarkeit und die
## ganze Schnittstelle, die HUD und Kamera erwarten.

## Anfangs- und Höchsttempo in m/s. Als Felder und nicht als Konstanten,
## damit eine Fluchtstrecke andere Werte fahren kann als ein Ritt.
@export var tempo_start := 11.0
@export var tempo_max := 19.0
## So viel schneller wird es je Sekunde.
@export var tempo_anstieg := 0.28
## Vorzeichen der Lenkung. Steht die Kamera vorn und blickt zurück, ist
## rechts auf dem Schirm links auf der Strecke – dann gehört hier -1 hin.
@export var lenk_richtung := 1.0
## Seitliches Lenktempo in m/s.
const LENK_TEMPO := 9.0
## So schnell folgt der seitliche Versatz der Lenkung (kleiner = träger).
const LENK_TRAEGHEIT := 9.0
signal ziel_erreicht

## Kurve, auf der geritten wird. Setzt das Level.
var verlauf: Curve3D
## Größter seitlicher Versatz an einer Stelle. Setzt das Level; ohne das
## bleibt es bei `halbe_breite`.
var seiten_grenze: Callable = Callable()
var halbe_breite := 4.0
## Liegt an dieser Stelle Boden? Setzt das Level. Weil der Reiter auf der
## Kurve klebt statt zu fallen, merkt er eine Lücke sonst überhaupt nicht –
## er liefe darüber hinweg wie über festen Grund.
var boden_pruefer: Callable = Callable()
## Strecke, ab der das Level geschafft ist.
var ziel_strecke := 0.0

## Zurückgelegte Strecke auf der Kurve.
var strecke := 0.0
## Aktuelles Tempo in m/s.
var tempo := 11.0

var _seitlich := 0.0
var _seitlich_ziel := 0.0
var _hoehe := 0.0
var _vy := 0.0
var _in_luft := false
var _kann_djump := false
## Strecke des letzten Checkpoints – dorthin geht es nach dem Tod zurück.
var _checkpoint := 0.0
var _fertig := false

## Reittier. Fehlt es (Fluchtstrecke zu Fuß), bleibt es schlicht leer.
@onready var _katze: Katze = get_node_or_null("Katze") as Katze


func _ready() -> void:
	super._ready()
	tempo = tempo_start
	# Der Reiter bewegt sich nicht über die Physik, sondern setzt seine
	# Position selbst. Ebene 2, damit Kisten- und Gegnerzonen ihn finden.
	collision_layer = 2
	collision_mask = 0


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln -= delta
	if verlauf == null or gesperrt or _fertig:
		_stellung_setzen()
		return

	tempo = minf(tempo + tempo_anstieg * delta, tempo_max)
	strecke += tempo * delta

	_lenken(delta)
	_springen(delta)
	_stellung_setzen()

	if ziel_strecke > 0.0 and strecke >= ziel_strecke:
		_fertig = true
		ziel_erreicht.emit()


## Quer zum Weg lenken. Der Versatz folgt der Eingabe träge nach – eine
## rennende Katze springt nicht seitlich, sie zieht in die Kurve.
func _lenken(delta: float) -> void:
	var eingabe := InputHub.bewegung().x * lenk_richtung
	_seitlich_ziel += eingabe * LENK_TEMPO * delta
	var grenze := _grenze_bei(strecke)
	_seitlich_ziel = clampf(_seitlich_ziel, -grenze, grenze)
	_seitlich = lerpf(_seitlich, _seitlich_ziel, minf(delta * LENK_TRAEGHEIT, 1.0))


func _springen(delta: float) -> void:
	if InputHub.sprung_gedrueckt():
		if not _in_luft:
			_vy = JUMP_V
			_in_luft = true
			_kann_djump = true
			_kein_jump_cut = false
		elif _kann_djump:
			_vy = DJUMP_V
			_kann_djump = false
			_kein_jump_cut = false

	# Taste loslassen kappt den Sprung – gleiche Regel wie zu Fuß.
	if _in_luft and not _kein_jump_cut and not InputHub.sprung_gehalten() \
			and _vy > JUMP_V * JUMP_CUT:
		_vy = JUMP_V * JUMP_CUT
		_kein_jump_cut = true

	_vy += G * delta
	_hoehe += _vy * delta
	if _hoehe <= 0.0:
		if not _boden_da(strecke):
			# Über einer Lücke aufgesetzt: der Sprung kam zu kurz.
			sterben()
			return
		_hoehe = 0.0
		_vy = 0.0
		_in_luft = false
		_kann_djump = false
		_kein_jump_cut = false


## Setzt Position und Blickrichtung aus Strecke, Versatz und Höhe.
func _stellung_setzen() -> void:
	if verlauf == null:
		return
	global_position = LevelWerkzeuge.punkt(verlauf, strecke, _seitlich, _hoehe + 0.04)
	rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)

	if is_instance_valid(_katze):
		_katze.aktualisiere(get_physics_process_delta_time(),
				tempo / maxf(tempo_max, 0.001), _in_luft)
		# In die Kurve legen: je stärker gelenkt wird, desto schräger.
		var neigung := clampf((_seitlich_ziel - _seitlich) * 0.25, -0.3, 0.3)
		_katze.rotation.z = lerpf(_katze.rotation.z, neigung, 0.2)


func _boden_da(s: float) -> bool:
	return not boden_pruefer.is_valid() or bool(boden_pruefer.call(s))


## Der Reiter sitzt und läuft nicht – der Basis-Zustand des Modells
## (`is_on_floor()`, Slide, Spin) passt hier nicht.
func _process(delta: float) -> void:
	var figur := get_node_or_null("Modell") as SpielerModell
	if figur == null:
		return
	figur.setze_blick(0.0)
	figur.aktualisiere(delta, 0.25, _in_luft, 0.0, 0.0)
	figur.sichtbarkeit(invuln <= 0.0 or fmod(invuln, 0.2) > 0.1)


func _grenze_bei(s: float) -> float:
	if seiten_grenze.is_valid():
		return maxf(float(seiten_grenze.call(s)), 0.2)
	return halbe_breite


# ---------------------------------------------------------- Schnittstelle

## Beim Ritt trampelt die Katze alles nieder, was im Weg steht: Kisten
## zerbrechen und Gegner fallen durch bloße Berührung. Im Sprung kommt
## das Draufspringen dazu, damit ein Käfer auch von oben zählt.
func angriffe() -> int:
	var maske := Angriff.SPIN | Angriff.SLIDE
	if _vy < Angriff.FALL_SCHWELLE:
		maske |= Angriff.FALLEN
	return maske


## Beim Ritt gibt die Kurve die Blickrichtung vor, nicht der Levelstart.
func setze_blickrichtung(_winkel: float) -> void:
	pass


## Federkisten und besiegte Gegner werfen den Reiter samt Katze hoch.
func abprallen(hoehe: float = ABPRALL_V) -> void:
	_vy = hoehe
	_in_luft = true
	_kann_djump = true
	_kein_jump_cut = true


## Ein Treffer wirft vom Rücken – wie im Vorbild endet jede Berührung
## eines Hindernisses den Ritt und setzt zum letzten Checkpoint zurück.
## Während der Unverwundbarkeit wirkungslos.
func schaden_nehmen() -> void:
	if invuln > 0.0 or _fertig:
		return
	if GameState.schutz_verbrauchen():
		invuln = INVULN_ZEIT
		return
	sterben()


func sterben() -> void:
	if _fertig:
		return
	gestorben.emit()
	GameState.leben_verlieren()
	respawn()


## Der Basis-Respawn setzt auf `GameState.checkpoint`; hier zählt die
## Strecke auf der Kurve.


## Zurück zum letzten Checkpoint auf der Strecke.
func respawn() -> void:
	strecke = _checkpoint
	_seitlich = 0.0
	_seitlich_ziel = 0.0
	_hoehe = 0.0
	_vy = 0.0
	_in_luft = false
	tempo = tempo_start
	invuln = INVULN_ZEIT
	_stellung_setzen()
	# Kamera mitnehmen, sonst steht der Reiter kurz außerhalb des Bildes
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")


## Setzt den Rückkehrpunkt. Die Checkpoint-Kiste meldet über GameState eine
## Position; das Level rechnet sie in eine Strecke um und ruft dies auf.
func setze_checkpoint(s: float) -> void:
	_checkpoint = maxf(_checkpoint, s)
