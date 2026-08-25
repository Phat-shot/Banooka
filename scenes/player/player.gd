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
const SPIN_TIME := 0.55      ## Dauer der Spin-Attacke

# --- Weitere Kennwerte ---
const DJUMP_SPIN_TIME := 0.2 ## Kurzer Spin-Effekt beim Doppelsprung
const SLAM_RADIUS := 2.0     ## Schockwelle des Bauchplatschers
const TODESHOEHE := -12.0    ## Unterhalb dieser Höhe stirbt der Spieler
const INVULN_ZEIT := 1.2     ## Unverwundbarkeit nach dem Respawn
const SPIN_REICHWEITE := 1.7 ## Wirkradius der Spin-Attacke
const FALL_GEDAECHTNIS := 0.25
## Wie lange ein Fall noch als Treffer zählt. move_and_slide setzt vel.y
## beim Aufsetzen sofort auf 0 – ohne dieses Gedächtnis verpufft der
## Treffer von oben, weil die Trefferzone erst danach prüft.
const ABPRALL_V := 16.0      ## Standard-Absprunghöhe von Federkisten und Gegnern
## Wie träge die Figur auf blankem Eis Tempo aufnimmt und abbaut.
## Kleiner Wert = rutschiger. Die Physikwerte oben bleiben unangetastet:
## Eis ändert nicht das Lauftempo, nur wie schnell es erreicht wird.
const EIS_GRIFF := 2.4

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
var _fall_rest := 0.0
var _spin_geprueft := false
## Solange gesetzt, wird die Sprunghöhe nicht gekappt. Wird von
## `abprallen()` gesetzt, damit Feder- und Sprungkisten ihre volle
## Höhe behalten – die Sprungtaste ist dabei ja nicht gedrückt.
var _kein_jump_cut := false
## Betretene Eisflächen (Instanz-ID -> Glätte). Mehrere überlappende
## Flächen dürfen sich nicht gegenseitig ausschalten, deshalb eine Liste
## und nicht ein einzelner Wert.
var _eisflaechen := {}


func _ready() -> void:
	add_to_group("spieler")
	# Die Schutzladungen kreisen als Masken um die Figur.
	add_child(Schutzmaske.new())
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
	var eingabe := _kamerarelativ(InputHub.bewegung())
	var staerke := eingabe.length()
	var ctrl := 1.0 if am_boden else AIR_CTRL

	if sliding > 0.0:
		# Slide: Richtung beim Start eingefroren, festes Tempo
		velocity.x = _slide_dir.x * SLIDE_SPEED
		velocity.z = _slide_dir.z * SLIDE_SPEED
	else:
		var ziel_x := eingabe.x * RUN_SPEED * ctrl
		var ziel_z := eingabe.y * RUN_SPEED * ctrl
		var glatt := glaette()
		if am_boden and glatt > 0.0:
			# Auf Eis greift nichts sofort: Die Figur nimmt Tempo träge auf
			# und baut es genauso träge ab. Wer die Richtung wechselt,
			# rutscht erst einmal weiter geradeaus.
			var griff := lerpf(1.0, EIS_GRIFF * delta, glatt)
			velocity.x = lerpf(velocity.x, ziel_x, clampf(griff, 0.0, 1.0))
			velocity.z = lerpf(velocity.z, ziel_z, clampf(griff, 0.0, 1.0))
		else:
			velocity.x = ziel_x
			velocity.z = ziel_z

	# --- Blickrichtung merken (Modell schaut in -Z) ---
	if staerke > 0.1 and sliding <= 0.0:
		_blick_y = atan2(-eingabe.x, -eingabe.y)
	_tempo = staerke

	# --- Slide bzw. Bauchplatscher ---
	if InputHub.slide_gedrueckt():
		if am_boden and staerke > 0.1 and sliding <= 0.0:
			sliding = SLIDE_TIME
			_slide_dir = Vector3(eingabe.x, 0.0, eingabe.y).normalized()
			Klang.spiele("slide")
		elif not am_boden and not slamming:
			slamming = true
			velocity.y = SLAM_V
			# Bewusst still: Bei SLAM_V dauert der Sturz oft nur ein paar
			# Zehntelsekunden. Ein Zischen dazu würde noch dröhnen, wenn
			# der Aufschlag längst zu hören ist.

	# --- Sprung ---
	if InputHub.sprung_gedrueckt():
		if am_boden:
			# Sprung aus dem Slide heraus geht höher
			var aus_slide := sliding > 0.0
			velocity.y = SLIDEJUMP_V if aus_slide else JUMP_V
			sliding = 0.0
			can_djump = true
			_kein_jump_cut = false
			_fall_rest = 0.0
			# Der Slide-Jump klingt eine Spur heller, weil er höher trägt.
			Klang.spiele("sprung", 1.12 if aus_slide else 1.0)
		elif can_djump and not slamming:
			velocity.y = DJUMP_V
			can_djump = false
			spinning = maxf(spinning, DJUMP_SPIN_TIME)
			_kein_jump_cut = false
			Klang.spiele("doppelsprung")

	# --- Variable Sprunghöhe: Taste losgelassen => kappen ---
	# Abprallen von Feder-/Sprungkisten und Gegnern wird nicht gekappt.
	if not _kein_jump_cut and not InputHub.sprung_gehalten() \
			and velocity.y > JUMP_V * JUMP_CUT and not slamming:
		velocity.y = JUMP_V * JUMP_CUT

	# --- Spin-Attacke ---
	if InputHub.spin_gedrueckt() and spinning <= 0.0:
		spinning = SPIN_TIME
		_spin_geprueft = false
		spin_gestartet.emit()
		Klang.spiele("drehschlag")
	if spinning > 0.0:
		_spin_treffer()

	_hitbox_aktualisieren()

	# --- Gravitation und Bewegung ---
	velocity.y += G * delta

	# Fall merken, bevor move_and_slide vel.y beim Aufsetzen auf 0 zieht
	if velocity.y < Angriff.FALL_SCHWELLE:
		_fall_rest = FALL_GEDAECHTNIS
	else:
		_fall_rest = maxf(_fall_rest - delta, 0.0)

	move_and_slide()

	# --- Landung ---
	if is_on_floor():
		# `am_boden` stammt vom Anfang des Bildes, vor move_and_slide –
		# der Vergleich trifft also genau den Moment des Aufsetzens und
		# nicht jedes Bild, in dem die Figur schon steht.
		if not am_boden:
			Klang.spiele("aufschlag" if slamming else "landung")
		can_djump = false
		_kein_jump_cut = false
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
	if _fall_rest > 0.0:
		maske |= Angriff.FALLEN
	return maske


## Glätte des Bodens: 0 = normaler Grip, 1 = blankes Eis. Betretene
## Eisflächen melden sich hier an; es gilt die glatteste.
func glaette() -> float:
	var hoechste := 0.0
	for wert in _eisflaechen.values():
		hoechste = maxf(hoechste, float(wert))
	return hoechste


func betritt_eis(kennung: int, wert: float) -> void:
	_eisflaechen[kennung] = wert


func verlaesst_eis(kennung: int) -> void:
	_eisflaechen.erase(kennung)


## Setzt die Blickrichtung, ohne den Spieler zu bewegen. Wird beim
## Levelstart genutzt, damit die Figur in Richtung des Korridors schaut
## und nicht stur nach Welt-Norden.
func setze_blickrichtung(winkel: float) -> void:
	_blick_y = winkel
	if is_instance_valid(_modell):
		_modell.setze_blick(winkel)
		_modell.rotation.y = winkel


## Schleudert den Spieler nach oben (Federkiste, Sprung auf einen Gegner).
func abprallen(hoehe: float = ABPRALL_V) -> void:
	velocity.y = hoehe
	_fall_rest = 0.0
	slamming = false
	can_djump = true
	_kein_jump_cut = true
	abgeprallt.emit()
	Klang.spiele("abprall")


## Schaden nehmen. Während der Unverwundbarkeit wirkungslos.
##
## Eine Schutzladung fängt den Treffer ab und schenkt dieselbe kurze
## Unverwundbarkeit wie ein Respawn – sonst zöge ein einziger Gegner in
## einem Bild gleich alle drei Ladungen ab. Stürze laufen nicht hierher,
## sondern direkt in `sterben()`; dort greift der Schutz bewusst nicht.
func schaden_nehmen() -> void:
	if invuln > 0.0:
		return
	if GameState.schutz_verbrauchen():
		invuln = INVULN_ZEIT
		Klang.spiele("schaden")
		return
	sterben()


func sterben() -> void:
	gestorben.emit()
	Klang.spiele("tod")
	GameState.leben_verlieren()
	respawn()


func respawn() -> void:
	velocity = Vector3.ZERO
	sliding = 0.0
	spinning = 0.0
	slamming = false
	can_djump = false
	gesperrt = false
	_kein_jump_cut = false
	invuln = INVULN_ZEIT
	_slide_hitbox_aktiv = false
	_fall_rest = 0.0
	_kollision.set_deferred("disabled", false)
	_kollision_slide.set_deferred("disabled", true)
	global_position = GameState.checkpoint
	# Nach einem Versetzen die Interpolation zurücksetzen, sonst zieht
	# Godot eine Spur vom alten zum neuen Ort – bei einem Respawn quer
	# durchs halbe Level.
	reset_physics_interpolation()
	# Kamera mitnehmen, sonst steht der Spieler kurz außerhalb des Bildes
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")


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


## Rechnet die Eingabe in die Blickrichtung der Kamera um.
##
## Ohne das zeigt "vorwärts" immer nach Welt-Norden. Sobald der Korridor
## eine Kurve macht und die Kamera mitschwenkt, passt die Steuerung dann
## nicht mehr zum Bild.
func _kamerarelativ(eingabe: Vector2) -> Vector2:
	if eingabe.length_squared() < 0.0001:
		return eingabe
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return eingabe

	var basis := kamera.global_transform.basis
	var vor := -basis.z
	vor.y = 0.0
	var rechts := basis.x
	rechts.y = 0.0
	if vor.length_squared() < 0.0001 or rechts.length_squared() < 0.0001:
		return eingabe
	vor = vor.normalized()
	rechts = rechts.normalized()

	# eingabe.y ist -1 für "vorwärts" (siehe Input-Map)
	var welt := rechts * eingabe.x - vor * eingabe.y
	return Vector2(welt.x, welt.z)


## Aktive Reichweite der Spin-Attacke.
##
## Kisten und Gegner prüfen sonst nur, ob der Spielerkörper ihre
## Trefferzone berührt – das ist beim Vorbeidrehen frustrierend knapp.
## Der Spin greift deshalb selbst nach Zielen im Umkreis.
func _spin_treffer() -> void:
	for kiste in get_tree().get_nodes_in_group("kisten"):
		if not (kiste is Node3D) or not kiste.has_method("zerbrechen"):
			continue
		if kiste.global_position.distance_to(global_position + Vector3.UP * 0.5) < SPIN_REICHWEITE:
			kiste.zerbrechen(Angriff.SPIN)

	for gegner in get_tree().get_nodes_in_group("gegner"):
		if not (gegner is Node3D) or not gegner.has_method("besiegen"):
			continue
		# Nur Gegner erwischen, die überhaupt per Spin zu besiegen sind –
		# sonst würde der Spin Gegner umwerfen, die anders gehen.
		var besiegbar: int = gegner.get("besiegbar_durch")
		if not (besiegbar & Angriff.SPIN):
			continue
		if gegner.global_position.distance_to(global_position + Vector3.UP * 0.5) < SPIN_REICHWEITE:
			gegner.besiegen(Angriff.SPIN)
