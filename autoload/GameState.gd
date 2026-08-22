extends Node
## Globaler Spielstand: Früchte, Leben, Kisten-Zähler, Checkpoint.
## Als Autoload unter dem Namen "GameState" registriert.

signal fruechte_geaendert(anzahl: int)
signal leben_geaendert(anzahl: int)
signal kisten_geaendert(zerbrochen: int, gesamt: int)
signal nachricht(text: String, dauer: float)

const START_LEBEN := 3
const FRUECHTE_PRO_EXTRALEBEN := 100

var fruechte := 0
var leben := START_LEBEN
var kisten_zerbrochen := 0
var kisten_gesamt := 0

## Respawn-Punkt (letzte Checkpoint-Kiste) und Levelanfang.
var checkpoint := Vector3.ZERO
var level_start := Vector3.ZERO


## Wird beim Laden eines Levels aufgerufen und setzt die Level-Zähler zurück.
func level_starten(start_position: Vector3, kisten_im_level: int = 0) -> void:
	level_start = start_position
	checkpoint = start_position
	kisten_zerbrochen = 0
	kisten_gesamt = kisten_im_level
	fruechte_geaendert.emit(fruechte)
	leben_geaendert.emit(leben)
	kisten_geaendert.emit(kisten_zerbrochen, kisten_gesamt)


func frucht_einsammeln(anzahl: int = 1) -> void:
	fruechte += anzahl
	while fruechte >= FRUECHTE_PRO_EXTRALEBEN:
		fruechte -= FRUECHTE_PRO_EXTRALEBEN
		leben += 1
		leben_geaendert.emit(leben)
		zeige_nachricht("Extraleben!", 1.5)
	fruechte_geaendert.emit(fruechte)


func kiste_zerbrochen() -> void:
	kisten_zerbrochen += 1
	kisten_geaendert.emit(kisten_zerbrochen, kisten_gesamt)
	if kisten_gesamt > 0 and kisten_zerbrochen >= kisten_gesamt:
		zeige_nachricht("Alle Kisten!", 2.0)


func setze_checkpoint(pos: Vector3) -> void:
	checkpoint = pos
	zeige_nachricht("Checkpoint", 1.2)


## Ein Leben abziehen. Bei 0 Leben geht es am Levelanfang weiter.
func leben_verlieren() -> void:
	leben -= 1
	if leben < 0:
		leben = START_LEBEN
		fruechte = 0
		checkpoint = level_start
		fruechte_geaendert.emit(fruechte)
		zeige_nachricht("GAME OVER", 2.5)
	else:
		zeige_nachricht("Autsch!", 1.2)
	leben_geaendert.emit(leben)


func zeige_nachricht(text: String, dauer: float = 1.8) -> void:
	nachricht.emit(text, dauer)
