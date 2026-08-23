extends Spieler
class_name Rennfahrer
## Ein Kart auf der Rennstrecke (Level 05) – für den Spieler und für die
## Gegner dieselbe Klasse, unterschieden nur durch `ist_spieler`.
##
## Wie der Reiter in Level 04 klebt auch das Kart auf der Kurve: Strecke,
## seitlicher Versatz und Höhe sind der ganze Zustand. Auf einem Rundkurs
## bringt das zwei Dinge geschenkt, die sonst mühsam wären – die Platzierung
## ist ein Zahlenvergleich, und die Gegner brauchen keine Wegfindung,
## sondern nur ein Wunschtempo und eine Wunschspur.
##
## Geerbt wird von `Spieler`, weil Kisten und Gegner `koerper is Spieler`
## prüfen. Die Gegner-Karts melden sich allerdings nicht in der Gruppe
## "spieler" an und rühren den Spielstand nicht an – sonst zählte das HUD
## fünf Spieler und jedes Kart setzte den Levelzähler zurück.

## Fährt hier ein Mensch? Sonst übernimmt die einfache Fahrhilfe unten.
@export var ist_spieler := false
## Lackfarbe des Karts.
@export var farbe: Color = Farben.FELL
## Name für die Platzierungsanzeige.
@export var fahrername := "Kart"
## Fahrkönnen der Gegner als Faktor auf ihr Wunschtempo (1.0 = wie der
## Spieler). Beim Spieler ohne Wirkung.
@export var koennen := 1.0
## Wie stark das Gummiband zieht: So viel Tempo legt ein Gegner höchstens
## zu, wenn er weit zurückliegt. Ohne das fährt ein Feld nach der ersten
## Runde auseinander und das Rennen ist entschieden.
@export var gummiband := 2.5

const TEMPO_START := 8.0
const HOECHST_TEMPO := 21.0
## Beschleunigung in m/s².
const ANTRIEB := 7.0
## Bremsverzögerung, wenn nichts gedrückt wird bzw. nach einem Dreher.
const ROLLWIDERSTAND := 3.5
## Faktor und Dauer eines Boosts.
const BOOST_FAKTOR := 1.55
const BOOST_DAUER := 1.6
## Seitliches Lenktempo und Trägheit.
const LENK_TEMPO := 8.0
const LENK_TRAEGHEIT := 7.0
## Ein Dreher kostet so lange die Kontrolle.
const DREHER_DAUER := 1.1
## So weit vor der Lochkante geht es nach einem Dreher weiter. Der Abstand
## ist kein Geschmackswert: Wer direkt an der Kante wieder anfährt, hat
## kein Tempo für den Sprung, fällt erneut hinein und hängt für immer
## fest – genau das taten die Gegner im ersten Testlauf. Mit 16 m Anlauf
## steht das Kart wieder bei rund 13 m/s, und ein Sprung trägt dann 8 m.
const DREHER_RUECKSETZ := 16.0

signal runde_gefahren(nummer: int)
signal rennen_beendet

## Kurve der Strecke, Länge einer Runde, zu fahrende Runden.
var verlauf: Curve3D
var rundenlaenge := 0.0
var runden_ziel := 3

## Auskünfte vom Level (wie beim Reiter).
var seiten_grenze: Callable = Callable()
var boden_pruefer: Callable = Callable()

var strecke := 0.0
var runde := 0
var tempo := TEMPO_START
var boost_rest := 0.0
var dreher_rest := 0.0
var fertig := false

var _seitlich := 0.0
var _seitlich_ziel := 0.0
var _hoehe := 0.0
var _vy := 0.0
var _in_luft := false
var _lenkung := 0.0
## Wunschspur der Fahrhilfe, wechselt gelegentlich.
var _ki_spur := 0.0
var _ki_wechsel := 0.0

@onready var _kart: Kart = $Kart


func _ready() -> void:
	if ist_spieler:
		super._ready()
	else:
		# Gegner sind keine Spieler: keine Gruppe, kein Spielstand, keine
		# Kollisionsebene – sie sollen weder das HUD noch Kisten auslösen.
		collision_layer = 0
		collision_mask = 0
	if is_instance_valid(_kart):
		_kart.farbe = farbe


## Gesamtstrecke seit dem Start – daraus wird die Platzierung bestimmt.
func gesamtstrecke() -> float:
	return runde * rundenlaenge + strecke


func _physics_process(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	if verlauf == null or gesperrt or fertig:
		_stellung_setzen(delta)
		return

	boost_rest = maxf(boost_rest - delta, 0.0)
	dreher_rest = maxf(dreher_rest - delta, 0.0)

	if ist_spieler:
		_spieler_steuern(delta)
	else:
		_fahrhilfe(delta)

	_fahren(delta)
	_springen(delta)
	_stellung_setzen(delta)


# ------------------------------------------------------------ Steuerung

func _spieler_steuern(delta: float) -> void:
	_lenkung = InputHub.bewegung().x
	# Der Drehschlag-Knopf zündet den gesammelten Boost.
	if InputHub.spin_gedrueckt() and boost_rest <= 0.0 and _boost_vorrat > 0:
		_boost_vorrat -= 1
		boost_rest = BOOST_DAUER
		GameState.zeige_nachricht("Schub!", 0.8)
	_lenken(delta)


## Fahrhilfe der Gegner: Wunschtempo mit leichtem Gummiband zum Spieler,
## dazu eine Spur, die alle paar Sekunden wechselt. Kein Wegfinden nötig –
## die Strecke ist die Kurve.
func _fahrhilfe(delta: float) -> void:
	_ki_wechsel -= delta
	if _ki_wechsel <= 0.0:
		_ki_wechsel = randf_range(1.8, 4.5)
		_ki_spur = randf_range(-0.7, 0.7)
	var grenze := _grenze_bei(strecke)
	_seitlich_ziel = _ki_spur * grenze
	_lenkung = clampf((_seitlich_ziel - _seitlich) * 0.5, -1.0, 1.0)
	_seitlich = lerpf(_seitlich, _seitlich_ziel, minf(delta * LENK_TRAEGHEIT, 1.0))

	# An der Lochkante abspringen, nicht früher: Ein Sprung trägt bei 21 m/s
	# gut 13 m, ein zu früher Absprung landet mitten im Loch.
	if not _in_luft and not _boden_da(strecke + 1.5):
		_absprung()


func _lenken(delta: float) -> void:
	_seitlich_ziel += _lenkung * LENK_TEMPO * delta
	var grenze := _grenze_bei(strecke)
	_seitlich_ziel = clampf(_seitlich_ziel, -grenze, grenze)
	_seitlich = lerpf(_seitlich, _seitlich_ziel, minf(delta * LENK_TRAEGHEIT, 1.0))


func _fahren(delta: float) -> void:
	var ziel := HOECHST_TEMPO * (BOOST_FAKTOR if boost_rest > 0.0 else 1.0)
	if not ist_spieler:
		ziel *= koennen + _gummiband_zuschlag()
	if dreher_rest > 0.0:
		# Während des Drehers rollt das Kart nur aus – aber nicht bis zum
		# Stillstand, sonst wäre der Anlauf zum nächsten Loch verloren.
		tempo = maxf(tempo, TEMPO_START * 0.5)
	elif tempo < ziel:
		tempo = minf(tempo + ANTRIEB * delta, ziel)
	else:
		tempo = maxf(tempo - ROLLWIDERSTAND * delta, ziel)

	strecke += tempo * delta
	if rundenlaenge > 0.0 and strecke >= rundenlaenge:
		strecke -= rundenlaenge
		runde += 1
		runde_gefahren.emit(runde)
		if runde >= runden_ziel:
			fertig = true
			rennen_beendet.emit()


## Zuschlag aufs Wunschtempo, wenn dieser Gegner hinter dem Spieler liegt.
## Nach vorn wirkt es nicht: ein Führender soll nicht künstlich gebremst
## werden, sonst wäre der eigene Vorsprung wertlos.
func _gummiband_zuschlag() -> float:
	var spieler := get_tree().get_first_node_in_group("spieler") as Rennfahrer
	if spieler == null or spieler == self:
		return 0.0
	var rueckstand := spieler.gesamtstrecke() - gesamtstrecke()
	if rueckstand <= 0.0:
		return 0.0
	return minf(rueckstand / 60.0, 1.0) * gummiband / HOECHST_TEMPO


func _springen(delta: float) -> void:
	if ist_spieler and InputHub.sprung_gedrueckt() and not _in_luft:
		_absprung()

	_vy += G * delta
	_hoehe += _vy * delta
	if _hoehe <= 0.0:
		if not _boden_da(strecke):
			# In ein Loch gefallen: Dreher statt Tod – ein Rennen endet
			# nicht am Streckenrand, es kostet Zeit.
			_dreher()
			return
		_hoehe = 0.0
		_vy = 0.0
		_in_luft = false


func _absprung() -> void:
	_vy = JUMP_V
	_in_luft = true


func _dreher() -> void:
	_hoehe = 0.0
	_vy = 0.0
	_in_luft = false
	dreher_rest = DREHER_DAUER
	tempo = TEMPO_START * 0.5
	# Zurück auf festen Grund – und dann noch ein gutes Stück weiter, damit
	# Anlauf für den nächsten Anlauf bleibt.
	var zurueck := strecke
	var versuche := 0
	while not _boden_da(zurueck) and versuche < 400:
		zurueck -= 0.5
		versuche += 1
	strecke = fposmod(zurueck - DREHER_RUECKSETZ, rundenlaenge) \
			if rundenlaenge > 0.0 else maxf(zurueck - DREHER_RUECKSETZ, 0.0)
	_seitlich_ziel = 0.0
	if ist_spieler:
		GameState.zeige_nachricht("Dreher!", 1.0)


func _stellung_setzen(delta: float) -> void:
	if verlauf == null:
		return
	global_position = LevelWerkzeuge.punkt(verlauf, strecke, _seitlich, _hoehe + 0.02)
	rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	if is_instance_valid(_kart):
		var dreh := _lenkung
		if dreher_rest > 0.0:
			# Sichtbar quer stehen, solange der Dreher läuft
			_kart.rotation.y += delta * 14.0
			dreh = 1.0
		else:
			_kart.rotation.y = 0.0
		_kart.aktualisiere(delta, tempo, _in_luft, dreh, boost_rest > 0.0)


# ------------------------------------------------------------ Boost

var _boost_vorrat := 0

## Ein Schubfeld auf der Strecke: sofort Schub, kein Vorrat nötig.
func schubfeld() -> void:
	boost_rest = BOOST_DAUER


## Eine aufgesammelte Schubladung, die auf Knopfdruck wartet.
func schub_sammeln() -> void:
	_boost_vorrat = mini(_boost_vorrat + 1, 3)


func boost_vorrat() -> int:
	return _boost_vorrat


# ------------------------------------------------------------ Hilfen

func _boden_da(s: float) -> bool:
	var wert := s
	if rundenlaenge > 0.0:
		wert = fposmod(s, rundenlaenge)
	return not boden_pruefer.is_valid() or bool(boden_pruefer.call(wert))


func _grenze_bei(s: float) -> float:
	if seiten_grenze.is_valid():
		return maxf(float(seiten_grenze.call(s)), 0.5)
	return 4.0


# ------------------------------------------------------- Schnittstelle

## Auf der Rennstrecke wird nichts niedergetrampelt – Kisten und Gegner
## kommen hier nicht vor, und ein Kart soll auch nichts zerschlagen.
func angriffe() -> int:
	return Angriff.KEINER


func setze_blickrichtung(_winkel: float) -> void:
	pass


## Ein Rennen kennt keinen Tod, nur Zeitverlust.
func schaden_nehmen() -> void:
	if invuln > 0.0:
		return
	invuln = 0.6
	_dreher()


func sterben() -> void:
	schaden_nehmen()
