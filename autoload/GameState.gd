extends Node
## Globaler Spielstand: Früchte, Leben, Kisten-Zähler, Checkpoint.
## Als Autoload unter dem Namen "GameState" registriert.

signal fruechte_geaendert(anzahl: int)
signal leben_geaendert(anzahl: int)
signal kisten_geaendert(zerbrochen: int, gesamt: int)
signal nachricht(text: String, dauer: float)
## Die großen Momente (Extraleben, alle Kisten, Game Over): im HUD als
## schräges Band quer über dem Bild statt als kleine Meldung. Ein eigenes
## Signal statt eines dritten Parameters an `nachricht` – wer dort schon
## mit zwei Parametern lauscht (der Spieltest), bleibt heil.
signal banner(text: String, farbe: Color, dauer: float)
signal schutz_geaendert(anzahl: int)
## Bittet das laufende Level, Kisten und Gegner auf den Stand des letzten
## Checkpoints zurückzusetzen. `von_vorn` heißt: ganz auf Levelanfang.
signal level_zuruecksetzen(von_vorn: bool)
## Ein Checkpoint wurde gesetzt – das Level sichert hier seinen Stand.
signal checkpoint_gesetzt

const START_LEBEN := 5
const FRUECHTE_PRO_EXTRALEBEN := 100
## So viele Schutzladungen lassen sich stapeln.
const SCHUTZ_MAX := 3

var fruechte := 0
## So lange steht das GAME-OVER-Banner, bevor es in den Portalraum geht.
const GAME_OVER_PAUSE := 2.5

var leben := START_LEBEN
var kisten_zerbrochen := 0
var kisten_gesamt := 0
## Läuft der aktuelle Versuch noch ohne einen einzigen Tod? Gibt am Ende
## den zweiten Edelstein.
var ohne_tod := true
## Schutzladungen: Jede fängt einen Treffer ab. Stürze fängt sie NICHT ab –
## die laufen an `schaden_nehmen()` vorbei und sollen es auch.
var schutz := 0

## Debugmodus (in den Einstellungen schaltbar): unendlich Leben, immer
## Schutz, alle Räume offen. Gedacht zum Durchspielen und Prüfen von
## Leveln, nicht als Spielweise.
var debug := false:
	set(an):
		debug = an
		leben_geaendert.emit(leben)
		schutz_geaendert.emit(schutz_anzeige())

## Respawn-Punkt (letzte Checkpoint-Kiste) und Levelanfang.
var checkpoint := Vector3.ZERO
var level_start := Vector3.ZERO


## Wird beim Laden eines Levels aufgerufen und setzt die Level-Zähler zurück.
func level_starten(start_position: Vector3, kisten_im_level: int = 0) -> void:
	level_start = start_position
	checkpoint = start_position
	kisten_zerbrochen = 0
	kisten_gesamt = kisten_im_level
	ohne_tod = true
	schutz_geaendert.emit(schutz)
	fruechte_geaendert.emit(fruechte)
	leben_geaendert.emit(leben)
	kisten_geaendert.emit(kisten_zerbrochen, kisten_gesamt)


## Setzt Leben und Früchte für einen frischen Levelversuch zurück.
## Wird vom Spielfluss beim Betreten eines Levels aufgerufen.
func neu_beginnen() -> void:
	leben = START_LEBEN
	ohne_tod = true
	fruechte = 0
	kisten_zerbrochen = 0
	kisten_gesamt = 0
	# Der Schutz gilt je Levelversuch; über einen Neustart nimmt man ihn
	# nicht mit, sonst sammelte man ihn im leichten Level für das schwere.
	schutz = 0
	schutz_geaendert.emit(schutz)
	fruechte_geaendert.emit(fruechte)
	leben_geaendert.emit(leben)
	kisten_geaendert.emit(0, 0)


## Angezeigter Schutz. Im Debugmodus immer voll.
func schutz_anzeige() -> int:
	return SCHUTZ_MAX if debug else schutz


## Eine Schutzladung aufnehmen. Über `SCHUTZ_MAX` hinaus verfällt sie.
func schutz_aufnehmen() -> void:
	if debug:
		return
	if schutz >= SCHUTZ_MAX:
		zeige_nachricht("Schutz bereits voll", 1.2)
		return
	schutz += 1
	schutz_geaendert.emit(schutz)
	zeige_nachricht("Schutz %d/%d" % [schutz, SCHUTZ_MAX], 1.4)


## Verbraucht eine Ladung. Gibt true zurück, wenn eine da war – dann ist
## der Treffer abgefangen.
func schutz_verbrauchen() -> bool:
	if debug:
		zeige_nachricht("Schutz hält! (Debug)", 1.0)
		return true
	if schutz <= 0:
		return false
	schutz -= 1
	schutz_geaendert.emit(schutz)
	zeige_nachricht("Schutz hält!", 1.0)
	return true


func frucht_einsammeln(anzahl: int = 1) -> void:
	fruechte += anzahl
	while fruechte >= FRUECHTE_PRO_EXTRALEBEN:
		fruechte -= FRUECHTE_PRO_EXTRALEBEN
		leben += 1
		leben_geaendert.emit(leben)
		zeige_banner("Extraleben!", Farben.UI_HERZ, 1.5)
	fruechte_geaendert.emit(fruechte)


func kiste_zerbrochen() -> void:
	kisten_zerbrochen += 1
	kisten_geaendert.emit(kisten_zerbrochen, kisten_gesamt)
	if kisten_gesamt > 0 and kisten_zerbrochen >= kisten_gesamt:
		zeige_banner("Alle Kisten!", Farben.EDELSTEIN_KISTEN, 2.0)


func setze_checkpoint(pos: Vector3) -> void:
	checkpoint = pos
	# Ab hier gilt der aktuelle Stand: Was jetzt zerbrochen oder besiegt
	# ist, bleibt es auch nach dem nächsten Tod.
	checkpoint_gesetzt.emit()
	zeige_nachricht("Checkpoint", 1.2)


## Ein Leben abziehen. Bei 0 Leben: Game Over, zurück in den Portalraum.
##
## Ein Tod stellt das Level wieder her und setzt am Checkpoint ein: Ohne
## das stand man nach dem Respawn vor einer leergeräumten Strecke und
## konnte die Kisten nicht mehr holen. Game Over stellt das Level auch
## wieder her (Uhr, HUD und Zeitmodus hängen an `level_zuruecksetzen`) und
## wechselt nach dem Banner in den Portalraum (`GAME_OVER_PAUSE`).
func leben_verlieren() -> void:
	ohne_tod = false
	if debug:
		zeige_nachricht("Autsch! (Debug: kein Leben ab)", 1.2)
		level_zuruecksetzen.emit(false)
		return
	leben -= 1
	var von_vorn := leben < 0
	if von_vorn:
		leben = START_LEBEN
		fruechte = 0
		checkpoint = level_start
		fruechte_geaendert.emit(fruechte)
		zeige_banner("GAME OVER", Farben.WARNUNG, 2.5)
	else:
		zeige_nachricht("Autsch!", 1.2)
	leben_geaendert.emit(leben)
	level_zuruecksetzen.emit(von_vorn)
	if von_vorn:
		_zum_portalraum_nach_game_over()


## Nach dem Banner in den Portalraum – nur aus einem Level heraus, und nur,
## wenn der Spieler inzwischen nicht selbst woandershin gewechselt ist.
func _zum_portalraum_nach_game_over() -> void:
	var nummer: int = Spielfluss.aktuelles_level
	if nummer <= 0 or not is_inside_tree():
		return
	await get_tree().create_timer(GAME_OVER_PAUSE).timeout
	if Spielfluss.aktuelles_level == nummer:
		Spielfluss.zum_hub()


func zeige_nachricht(text: String, dauer: float = 1.8) -> void:
	nachricht.emit(text, dauer)


## Großes Band statt Meldung – nur für seltene Momente, sonst nutzt es
## sich ab. `farbe` färbt das Band.
func zeige_banner(text: String, farbe: Color = Farben.UI_GOLD,
		dauer: float = 2.0) -> void:
	banner.emit(text, farbe, dauer)
