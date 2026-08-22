extends CharacterBody3D
class_name Spieler
## Spieler-Controller (CharacterBody3D).
##
## Das komplette Move-Set ist 1:1 aus plattformer-demo.html übernommen:
## Laufen, Sprung mit variabler Höhe, Doppelsprung, Slide, Slide-Jump,
## Bauchplatscher und Spin-Attacke.
##
## ACHTUNG: Die Physikwerte sind laut CLAUDE.md verbindlich und dürfen
## NICHT ohne Rückfrage geändert werden.

# --- Physikwerte (VERBINDLICH) ---
const G := -38.0             ## Gravitation in m/s²
const JUMP_V := 12.2         ## Sprungkraft
const JUMP_CUT := 0.45       ## Taste loslassen => vel.y auf JUMP_V * JUMP_CUT kappen
const DJUMP_V := 10.5        ## Doppelsprung (schwächer als der erste Sprung)
const RUN_SPEED := 8.5       ## Laufgeschwindigkeit
const AIR_CTRL := 0.82       ## Faktor Luftkontrolle
const SLIDE_SPEED := 13.5    ## Slide-Tempo
const SLIDE_TIME := 0.42     ## Slide-Dauer
const SLIDEJUMP_V := 14.5    ## Sprung aus dem Slide heraus
const SLAM_V := -30.0        ## Bauchplatscher
const SPIN_TIME := 0.38      ## Dauer der Spin-Attacke

# --- Weitere Kennwerte ---
const DJUMP_SPIN_TIME := 0.2 ## Kurzer Spin-Effekt beim Doppelsprung
const SLAM_RADIUS := 2.0     ## Schockwelle des Bauchplatschers
const TODESHOEHE := -12.0    ## Unterhalb dieser Höhe stirbt der Spieler
const INVULN_ZEIT := 1.2     ## Unverwundbarkeit nach dem Respawn
const ABPRALL_V := 16.0      ## Standard-Absprunghöhe von Federkisten und Gegnern

signal spin_gestartet
signal bauchplatscher_gelandet(pos: Vector3)
signal gestorben
signal abgeprallt

@onready var _kollision: CollisionShape3D = $Kollision
@onready var _kollision_slide: CollisionShape3D = $KollisionSlide
@onready var _modell: SpielerModell = $Modell

## Restlaufzeit des Slides in Sekunden (> 0 = Slide aktiv).
var sliding := 0.0
## Restlaufzeit der Spin-Attacke in Sekunden (> 0 = Spin aktiv).
var spinning := 0.0
## True, solange der Bauchplatscher läuft.
var slamming := false
## True, wenn der Doppelsprung in dieser Luftphase noch verfügbar ist.
var can_djump := false
## Restlaufzeit der Unverwundbarkeit.
var invuln := 0.0
## Steuerung gesperrt (z. B. während einer Portal-Animation).
var gesperrt := false

var _slide_dir := Vector3.ZERO
var _blick_y := 0.0
var _slide_hitbox_aktiv := false
var _tempo := 0.0


func _ready() -> void:
	add_to_group("spieler")
	GameState.level_starten(global_position)


func _physics_process(delta: float) -> void:
	# --- Timer ---
	spinning = maxf(spinning - delta, 0.0)
	sliding = maxf(sliding - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)

	if gesperrt:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y += G * delta
		move_and_slide()
		return

	var am_boden := is_on_floor()

	# --- Horizontale Bewegung ---
	var eingabe := InputHub.bewegung()
	var staerke := eingabe.length()
	var ctrl := 1.0 if am_boden else AIR_CTRL

	if sliding > 0.0:
		# Slide: Richtung beim Start eingefroren, festes Tempo
		velocity.x = _slide_dir.x * SLIDE_SPEED
		velocity.z = _slide_dir.z * SLIDE_SPEED
	else:
		velocity.x = eingabe.x * RUN_SPEED * ctrl
		velocity.z = eingabe.y * RUN_SPEED * ctrl

	# --- Blickrichtung merken (Modell schaut in -Z) ---
	if staerke > 0.1 and sliding <= 0.0:
		_blick_y = atan2(-eingabe.x, -eingabe.y)
	_tempo = staerke

	# --- Slide bzw. Bauchplatscher ---
	if InputHub.slide_gedrueckt():
		if am_boden and staerke > 0.1 and sliding <= 0.0:
			sliding = SLIDE_TIME
			_slide_dir = Vector3(eingabe.x, 0.0, eingabe.y).normalized()
		elif not am_boden and not slamming:
			slamming = true
			velocity.y = SLAM_V

	# --- Sprung ---
	if InputHub.sprung_gedrueckt():
		if am_boden:
			# Sprung aus dem Slide heraus geht höher
			velocity.y = SLIDEJUMP_V if sliding > 0.0 else JUMP_V
			sliding = 0.0
			can_djump = true
		elif can_djump and not slamming:
			velocity.y = DJUMP_V
			can_djump = false
			spinning = maxf(spinning, DJUMP_SPIN_TIME)

	# --- Variable Sprunghöhe: Taste losgelassen => kappen ---
	if not InputHub.sprung_gehalten() and velocity.y > JUMP_V * JUMP_CUT and not slamming:
		velocity.y = JUMP_V * JUMP_CUT

	# --- Spin-Attacke ---
	if InputHub.spin_gedrueckt() and spinning <= 0.0:
		spinning = SPIN_TIME
		spin_gestartet.emit()

	_hitbox_aktualisieren()

	# --- Gravitation und Bewegung ---
	velocity.y += G * delta
	move_and_slide()

	# --- Landung ---
	if is_on_floor():
		can_djump = false
		if slamming:
			slamming = false
			_schockwelle()

	# --- Absturz ---
	if global_position.y < TODESHOEHE:
		sterben()


func _process(delta: float) -> void:
	if is_instance_valid(_modell):
		_modell.setze_blick(_blick_y)
		_modell.aktualisiere(delta, _tempo, not is_on_floor(), sliding, spinning)
		_modell.sichtbarkeit(invuln <= 0.0 or fmod(invuln, 0.2) > 0.1)


# ---------------------------------------------------------- Schnittstelle

## Aktuell laufende Angriffsarten als Bitmaske (siehe scripts/angriff.gd).
## Gegner und Kisten fragen das ab, um zu entscheiden, ob sie getroffen sind.
func angriffe() -> int:
	var maske := Angriff.KEINER
	if spinning > 0.0:
		maske |= Angriff.SPIN
	if sliding > 0.0:
		maske |= Angriff.SLIDE
	if slamming:
		maske |= Angriff.SLAM
	if velocity.y < Angriff.FALL_SCHWELLE:
		maske |= Angriff.FALLEN
	return maske


## Schleudert den Spieler nach oben (Federkiste, Sprung auf einen Gegner).
func abprallen(hoehe: float = ABPRALL_V) -> void:
	velocity.y = hoehe
	slamming = false
	can_djump = true
	abgeprallt.emit()


## Schaden nehmen. Während der Unverwundbarkeit wirkungslos.
func schaden_nehmen() -> void:
	if invuln > 0.0:
		return
	sterben()


func sterben() -> void:
	gestorben.emit()
	GameState.leben_verlieren()
	respawn()


func respawn() -> void:
	velocity = Vector3.ZERO
	sliding = 0.0
	spinning = 0.0
	slamming = false
	can_djump = false
	gesperrt = false
	invuln = INVULN_ZEIT
	_slide_hitbox_aktiv = false
	_kollision.set_deferred("disabled", false)
	_kollision_slide.set_deferred("disabled", true)
	global_position = GameState.checkpoint


# ---------------------------------------------------------- Intern

## Schaltet zwischen normaler und halbierter Hitbox um.
func _hitbox_aktualisieren() -> void:
	var im_slide := sliding > 0.0
	if im_slide == _slide_hitbox_aktiv:
		return
	_slide_hitbox_aktiv = im_slide
	_kollision.set_deferred("disabled", im_slide)
	_kollision_slide.set_deferred("disabled", not im_slide)


## Schockwelle beim Aufschlag des Bauchplatschers: zerbricht Kisten im Umkreis.
func _schockwelle() -> void:
	bauchplatscher_gelandet.emit(global_position)
	for kiste in get_tree().get_nodes_in_group("kisten"):
		if kiste is Node3D and kiste.has_method("zerbrechen"):
			if kiste.global_position.distance_to(global_position) < SLAM_RADIUS:
				kiste.zerbrechen(Angriff.SLAM)
