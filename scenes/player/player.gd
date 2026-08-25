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
## Tempo beim Krabbeln. Kein Wert aus der Demo, sondern neu: Krabbeln ist
## langsamer als Gehen und soll sich zäh anfühlen, sonst wäre es die
## bessere Fortbewegung und niemand liefe mehr aufrecht.
const KRIECH_TEMPO := 3.0

## Tempo beim Hangeln, längs des Gitters. Bewusst zwischen Krabbeln (3,0)
## und Laufen (8,5): Hangeln soll zügig sein, aber nie die schnellere Wahl.
const HANGEL_TEMPO := 3.6
## Tempo quer dazu, entlang einer Sprosse. Langsamer, weil dabei die Griffe
## gewechselt werden statt nachgefasst.
const HANGEL_QUER := 2.0
## Sperre nach dem Loslassen. Ohne sie hinge die Figur im nächsten Bild
## wieder am selben Gitter – sie fällt ja mitten durch die Fangzone.
## In 0,3 s fällt sie 1,7 m und ist damit aus der 0,6 m hohen Zone heraus.
const HANGEL_SPERRE := 0.3

signal spin_gestartet
signal bauchplatscher_gelandet(pos: Vector3)
signal gestorben
signal abgeprallt

@onready var _kollision: CollisionShape3D = $Kollision
@onready var _kollision_slide: CollisionShape3D = $KollisionSlide
@onready var _kollision_hangeln: CollisionShape3D = $KollisionHangeln
@onready var _modell: SpielerModell = $Modell

## Kapsel für die Frage „ist oben Platz?". Eine Spur schmaler und kürzer als
## die echte, sonst meldete sie den Boden unter den eigenen Füßen und die
## Wand neben der Schulter als Decke und die Figur käme nie wieder hoch.
const STEHRAND := 0.03
var _stehform: CapsuleShape3D

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
## Krabbelt die Figur gerade? Kein Schalter: Gekrabbelt wird, solange die
## Slide-Taste gehalten wird (aus dem Stand heraus – mit Richtung ist
## dieselbe Taste der Slide), und darüber hinaus so lange, wie über der
## Figur kein Platz zum Aufrichten ist.
var kriechen := false
## Gitter, an dem die Figur gerade hängt. `null` = sie hängt nicht.
## Öffentlich, weil `haltung()` und Gegner es lesen sollen. Mehr Zustand
## braucht es nicht: Hanghöhe, Richtung und Grenzen liegen alle im Prop.
var hangelgitter: Hangelgitter = null
## Zieht die hängende Figur die Beine an? Das ist das Krabbeln des Gitters:
## Wer die Beine anzieht, wird oben schmal statt unten – die Kapsel wandert
## deshalb nach oben, nicht nach unten wie beim Krabbeln am Boden.
var hangeln_eingezogen := false

var _slide_dir := Vector3.ZERO
## Restsperre nach dem Loslassen, in Sekunden.
var _hangel_sperre := 0.0
var _blick_y := 0.0
var _slide_hitbox_aktiv := false
## 0 = aufrecht, 1 = flach am Boden, 2 = eingezogen am Gitter
var _hitbox_art := 0
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
	_hangel_sperre = maxf(_hangel_sperre - delta, 0.0)

	if gesperrt:
		# Die Portalfahrt zieht die Figur vom Gitter. Ohne das fiele sie
		# zwar herunter, `hangelgitter` bliebe aber gesetzt – und sie
		# schnappte beim Entsperren wieder nach oben.
		hangelgitter = null
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y += G * delta
		move_and_slide()
		return

	var am_boden := is_on_floor()

	# --- Hangeln ---
	# Steht vor allem anderen, weil Hangeln kein Zustand NEBEN Laufen,
	# Slide und Sprung ist, sondern statt ihnen: Wer hängt, hat weder
	# Boden noch Schwerkraft. Der Block endet mit `return` und überspringt
	# damit bewusst Laufen, Slide, Krabbeln, Sprung, Jump-Cut, Spin,
	# Schwerkraft und Landung. Was er NICHT überspringen darf – Hitbox und
	# Absturzprüfung –, steht in `_hangeln()` noch einmal.
	if hangelgitter == null and not am_boden and not slamming \
			and sliding <= 0.0 and _hangel_sperre <= 0.0:
		_einhaengen(Hangelgitter.naechstes(self))
	if hangelgitter != null:
		_hangeln(delta)
		return

	# --- Horizontale Bewegung ---
	var eingabe := _kamerarelativ(InputHub.bewegung())
	var staerke := eingabe.length()
	var ctrl := 1.0 if am_boden else AIR_CTRL

	if sliding > 0.0:
		# Slide: Richtung beim Start eingefroren, festes Tempo
		velocity.x = _slide_dir.x * SLIDE_SPEED
		velocity.z = _slide_dir.z * SLIDE_SPEED
	else:
		var lauftempo := KRIECH_TEMPO if kriechen else RUN_SPEED
		var ziel_x := eingabe.x * lauftempo * ctrl
		var ziel_z := eingabe.y * lauftempo * ctrl
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
		if am_boden and staerke > 0.1 and sliding <= 0.0 and not kriechen:
			sliding = SLIDE_TIME
			_slide_dir = Vector3(eingabe.x, 0.0, eingabe.y).normalized()
			Klang.spiele("slide")
		elif not am_boden and not slamming:
			slamming = true
			velocity.y = SLAM_V
			# Bewusst still: Bei SLAM_V dauert der Sturz oft nur ein paar
			# Zehntelsekunden. Ein Zischen dazu würde noch dröhnen, wenn
			# der Aufschlag längst zu hören ist.

	# --- Krabbeln ---
	_kriechen_pruefen(am_boden, staerke)

	# --- Sprung ---
	if InputHub.sprung_gedrueckt() and _kann_aufstehen():
		# Wer springt, richtet sich auf – sonst hinge die Figur im
		# Krabbeln in der Luft und käme mit der flachen Hitbox wieder auf.
		# Unter einer zu tiefen Decke bleibt der Sprung aus.
		kriechen = false
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
		_modell.aktualisiere(delta, _tempo, not is_on_floor(), sliding, spinning,
				haltung())
		_modell.sichtbarkeit(invuln <= 0.0 or fmod(invuln, 0.2) > 0.1)


# ---------------------------------------------------------- Schnittstelle

## Haltung der Figur, die das Modell als Clip zeigt.
##
## Leer heißt: Das Modell entscheidet selbst aus Tempo, Luft, Slide und
## Spin. Die Schienenfiguren überschreiben das – wer auf einer Wildkatze
## sitzt, soll nicht so tun, als liefe er.
func haltung() -> String:
	if hangelgitter != null:
		if spinning > 0.0:
			return "hangeln_spin"
		return "hangeln_geduckt" if hangeln_eingezogen else "hangeln"
	return "krabbeln" if kriechen else ""


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


## Löst die Figur vom Gitter und sperrt das sofortige Wiedereinhängen.
##
## Öffentlich, weil nicht nur die Steuerung sie braucht: Auch ein Treffer,
## der Tod und die Portalfahrt müssen die Hände lösen können.
func hangeln_beenden() -> void:
	if hangelgitter == null:
		return
	hangelgitter = null
	hangeln_eingezogen = false
	_hangel_sperre = HANGEL_SPERRE


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
	# Ein Treffer reißt die Hände vom Gitter. Ohne das hinge die Figur im
	# Wirkbereich eines Deckengegners fest und verlöre dort in einer
	# Sekunde alle drei Schutzladungen.
	hangeln_beenden()
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
	kriechen = false
	hangelgitter = null
	hangeln_eingezogen = false
	# Bewusst auf 0 statt auf HANGEL_SPERRE: Wer an einem Checkpoint unter
	# einem Gitter erscheint, soll sofort wieder hinaufspringen dürfen.
	_hangel_sperre = 0.0
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

## Hängt die Figur ein. `null` wird stillschweigend geschluckt, damit die
## Fundstelle in `_physics_process` ohne zweite Abfrage auskommt.
func _einhaengen(gitter: Hangelgitter) -> void:
	if gitter == null:
		return
	hangelgitter = gitter
	hangeln_eingezogen = false
	velocity = Vector3.ZERO
	sliding = 0.0
	slamming = false
	# Auch aus dem Krabbeln heraus kommt man ans Gitter – über eine
	# Federkiste zum Beispiel.
	kriechen = false
	can_djump = true
	_kein_jump_cut = false
	# Das Fall-Gedächtnis MUSS hier weg. Abgebaut wird es sonst nur im
	# Schwerkraft-Block, und der läuft beim Hangeln nie: Die Figur zählte
	# den Sprung, mit dem sie ans Gitter kam, für immer als Treffer von
	# oben und zerbräche im Vorbeihangeln jede Kiste.
	_fall_rest = 0.0
	global_position = gitter.naechster_punkt(global_position)
	reset_physics_interpolation()
	Klang.spiele("landung", 1.3, 0.7)


## Hangeln: ein vollständiger Ersatz für Laufen und Fallen.
##
## Zwei Wege führen heraus, und beide sind Entscheidungen, kein Unfall:
## Springen (trägt weiter) und Loslassen (fällt senkrecht). Am Ende des
## Gitters passiert dagegen NICHTS – die Figur bleibt hängen. Automatisch
## loszulassen wäre ein Verrat: Ein Gitter hängt über einer Gasse, und wer
## zu weit hangelt, stürbe, ohne etwas falsch gemacht zu haben.
func _hangeln(delta: float) -> void:
	var gitter := hangelgitter
	if not is_instance_valid(gitter):
		hangeln_beenden()
		return

	var eingabe := _kamerarelativ(InputHub.bewegung())

	# ✕ löst vom Gitter, und die RICHTUNG entscheidet wie: mit Richtung
	# ein Absprung, der weiterträgt; ohne Richtung ein senkrechtes
	# Loslassen, um genau darunter zu landen. Dieselbe Regel wie am Boden,
	# wo die Richtung über Slide und Krabbeln entscheidet.
	if InputHub.sprung_gedrueckt():
		hangeln_beenden()
		if eingabe.length() > 0.15:
			velocity = Vector3(eingabe.x * RUN_SPEED * AIR_CTRL, JUMP_V,
					eingabe.y * RUN_SPEED * AIR_CTRL)
			can_djump = true
			Klang.spiele("sprung")
		else:
			velocity = Vector3.ZERO
		return

	# ○ zieht die Beine an. Damit ist die Slide-Taste am Gitter dasselbe
	# wie am Boden: gehalten macht sie klein. Nur die Richtung, in die es
	# eng wird, ist eine andere – wer hängt, wird oben schmal.
	hangeln_eingezogen = InputHub.slide_gehalten()

	# Drehschlag im Hängen: Die Beine werden herumgerissen. Die
	# Spezifikation hatte ihn ausgeschlossen ("kaum Handlungs-
	# möglichkeiten"), aber genau die wollten wir hier haben.
	if InputHub.spin_gedrueckt() and spinning <= 0.0:
		spinning = SPIN_TIME
		_spin_geprueft = false
		spin_gestartet.emit()
		Klang.spiele("drehschlag")
	if spinning > 0.0:
		_spin_treffer()

	# Die Eingabe wird auf die beiden Gitterachsen zerlegt. So bleibt die
	# Steuerung kamerarelativ, auch wenn das Gitter schräg zur Kamera
	# hängt – und Rückwärtshangeln braucht keinen Sonderfall, weil die
	# Zerlegung Vorzeichen kennt.
	var wunsch := Vector3(eingabe.x, 0.0, eingabe.y)
	var laengs := gitter.laengsachse()
	var quer := gitter.querachse()
	var zug := laengs * laengs.dot(wunsch) * HANGEL_TEMPO \
			+ quer * quer.dot(wunsch) * HANGEL_QUER

	velocity = Vector3(zug.x, 0.0, zug.z)
	move_and_slide()
	# Erst bewegen, dann zurück auf das Gitter setzen – in dieser
	# Reihenfolge: `move_and_slide()` lässt Wände weiter blocken,
	# `naechster_punkt()` hält danach nur Höhe und Grenzen. Umgekehrt wäre
	# die Höhe um ein Bild verzögert und die Figur würde sichtbar sägen.
	global_position = gitter.naechster_punkt(global_position)

	if eingabe.length() > 0.1:
		_blick_y = atan2(-eingabe.x, -eingabe.y)
	_tempo = clampf(zug.length() / HANGEL_TEMPO, 0.0, 1.0)
	# Beides läuft im übersprungenen Teil von `_physics_process` und muss
	# deshalb hier stehen: Sonst bliebe die flache Slide-Kapsel stehen,
	# wenn jemand aus einem Slide-Jump heraus ins Gitter greift, und ein
	# Gitter über einem Abgrund fienge den Tod nicht ab.
	_hitbox_aktualisieren()
	if global_position.y < TODESHOEHE:
		sterben()


## Entscheidet Bild für Bild, ob die Figur krabbelt.
##
## Krabbeln ist kein Schalter, sondern ein Halten: Solange die Slide-Taste
## gedrückt bleibt, bleibt die Figur unten; beim Loslassen richtet sie sich
## wieder auf und läuft normal weiter. Der Einstieg verlangt Stillstand,
## denn mit Richtung ist dieselbe Taste der Slide. Weiterkrabbeln mit
## Richtung geht dagegen sehr wohl – die Taste ist dann schon gehalten,
## und der Slide löst nur beim Drücken aus.
##
## Dazu kommt der Zwang: Wo über der Figur kein Platz zum Aufrichten ist,
## krabbelt sie weiter, auch ohne Taste. Sonst stünde sie nach einem Slide
## unter einem tiefen Vorsprung im Fels.
func _kriechen_pruefen(am_boden: bool, staerke: float) -> void:
	if not am_boden or sliding > 0.0 or slamming:
		kriechen = false
		return
	var taste := InputHub.slide_gehalten()
	if kriechen or _slide_hitbox_aktiv:
		kriechen = taste or not _kann_aufstehen()
	else:
		kriechen = (taste and staerke <= 0.1) or not _kann_aufstehen()


## Ist über der Figur Platz für die aufrechte Hitbox?
##
## Gefragt wird mit genau der Kapsel, die im Stehen gilt, an genau der
## Stelle, an der sie dann säße. Nur so stimmt die Antwort auch an
## schrägen Decken, wo ein einzelner Strahl nach oben daneben griffe.
func _kann_aufstehen() -> bool:
	var raum := get_world_3d().direct_space_state
	if raum == null:
		return true
	if _stehform == null:
		var echt := _kollision.shape as CapsuleShape3D
		if echt == null:
			return true
		_stehform = CapsuleShape3D.new()
		_stehform.radius = maxf(echt.radius - STEHRAND, 0.05)
		_stehform.height = maxf(echt.height - STEHRAND * 2.0, _stehform.radius * 2.0)
	var frage := PhysicsShapeQueryParameters3D.new()
	frage.shape = _stehform
	frage.transform = Transform3D(Basis(), global_position + _kollision.position)
	frage.collision_mask = collision_mask
	frage.exclude = [get_rid()]
	return raum.intersect_shape(frage, 1).is_empty()


## Schaltet zwischen den drei Kollisionsformen um.
##
## aufrecht  – der Normalfall, Kapsel von 0,00 bis 1,30 m
## flach     – Slide und Krabbeln am Boden, 0,00 bis 0,76 m
## eingezogen– angezogene Beine am Gitter, 0,54 bis 1,30 m
##
## Die dritte Form ist der Grund für den Umbau: Am Gitter hängt die Figur
## an der Oberkante. Wer dort die Beine anzieht, wird UNTEN kürzer – die
## flache Bodenkapsel säße genau falsch herum.
func _hitbox_aktualisieren() -> void:
	var art := 0
	if hangelgitter != null and hangeln_eingezogen:
		art = 2
	elif sliding > 0.0 or kriechen:
		art = 1
	if art == _hitbox_art:
		return
	_hitbox_art = art
	_slide_hitbox_aktiv = art == 1
	_kollision.set_deferred("disabled", art != 0)
	_kollision_slide.set_deferred("disabled", art != 1)
	_kollision_hangeln.set_deferred("disabled", art != 2)


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
