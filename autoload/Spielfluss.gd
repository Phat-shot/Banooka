extends Node
## Szenenfluss und Spielstand: Splash → Portalraum → Level → Portalraum.
##
## Als Autoload unter dem Namen "Spielfluss" registriert.
##
## Der Portalraum besteht aus fünf Räumen mit je fünf Leveln (25 Level).
## Gebaut ist bisher nur Level 01; alle übrigen Einträge sind leer und
## erscheinen im Portalraum als verschlossene Tore.

const SPLASH_SZENE := "res://scenes/ui/Splash.tscn"
const HUB_SZENE := "res://scenes/hub/Hub.tscn"

const RAEUME := 5
const LEVEL_JE_RAUM := 5
const LEVEL_GESAMT := RAEUME * LEVEL_JE_RAUM

const SPEICHERPFAD := "user://spielstand.cfg"

## Szenenpfade der Level, Index 0 = Level 01.
## Leerer Eintrag = noch nicht gebaut.
const LEVEL_SZENEN := [
	"res://scenes/levels/Level01.tscn",
	"", "", "", "",
	"", "", "", "", "",
	"", "", "", "", "",
	"", "", "", "", "",
	"", "", "", "", "",
]

## Namen der fünf Abschnitte (ein Raum je Abschnitt).
const RAUM_NAMEN := [
	"Wurzelwald",
	"Nebelsümpfe",
	"Felsenschlucht",
	"Frostkronen",
	"Glutkessel",
]

signal fortschritt_geaendert

## Höchstes freigeschaltetes Level (1-basiert).
var freigeschaltet := 1
## Abgeschlossene Level: Nummer -> {"kisten": bool, "fruechte": int}
var geschafft := {}
## Gerade gespieltes Level (0 = keins).
var aktuelles_level := 0


func _ready() -> void:
	laden()


# ----------------------------------------------------------- Abfragen

## Ist für dieses Level überhaupt eine Szene gebaut?
func level_gebaut(nummer: int) -> bool:
	if nummer < 1 or nummer > LEVEL_GESAMT:
		return false
	return not String(LEVEL_SZENEN[nummer - 1]).is_empty()


## Darf der Spieler dieses Level betreten?
func level_offen(nummer: int) -> bool:
	return level_gebaut(nummer) and nummer <= freigeschaltet


## Raum (1-basiert), in dem dieses Level liegt.
func raum_von_level(nummer: int) -> int:
	return (nummer - 1) / LEVEL_JE_RAUM + 1


## Die fünf Levelnummern eines Raums.
func level_im_raum(raum: int) -> Array[int]:
	var liste: Array[int] = []
	for i in LEVEL_JE_RAUM:
		liste.append((raum - 1) * LEVEL_JE_RAUM + i + 1)
	return liste


## Ist mindestens ein Level dieses Raums freigeschaltet?
func raum_offen(raum: int) -> bool:
	for nummer in level_im_raum(raum):
		if level_offen(nummer):
			return true
	return false


# ----------------------------------------------------------- Wechseln

func zum_splash() -> void:
	aktuelles_level = 0
	_wechseln(SPLASH_SZENE)


func zum_hub() -> void:
	aktuelles_level = 0
	_wechseln(HUB_SZENE, "Portalraum")


## Startet ein Level. Gibt false zurück, wenn es verschlossen oder
## noch nicht gebaut ist.
func zum_level(nummer: int) -> bool:
	if not level_offen(nummer):
		return false
	aktuelles_level = nummer
	GameState.neu_beginnen()
	_wechseln(LEVEL_SZENEN[nummer - 1], "Level %02d" % nummer)
	return true


## Wird vom Zielportal aufgerufen, wenn ein Level geschafft ist.
func level_abschliessen(alle_kisten: bool) -> void:
	if aktuelles_level < 1:
		return
	var eintrag: Dictionary = geschafft.get(aktuelles_level, {})
	eintrag["kisten"] = bool(eintrag.get("kisten", false)) or alle_kisten
	eintrag["fruechte"] = maxi(int(eintrag.get("fruechte", 0)), GameState.fruechte)
	geschafft[aktuelles_level] = eintrag
	freigeschaltet = maxi(freigeschaltet, mini(aktuelles_level + 1, LEVEL_GESAMT))
	speichern()
	fortschritt_geaendert.emit()


## Wechselt die Szene. Mit Titel wird vorher der Ladebildschirm
## eingeblendet – erst wenn er tatsächlich gezeichnet ist, beginnt der
## Wechsel, sonst sähe man während des Aufbaus die alte Szene einfrieren.
func _wechseln(pfad: String, ladetitel: String = "") -> void:
	if pfad.is_empty() or not ResourceLoader.exists(pfad):
		push_warning("Szene fehlt: %s" % pfad)
		return
	if ladetitel.is_empty():
		get_tree().change_scene_to_file.call_deferred(pfad)
		return
	_wechseln_mit_ladeschirm(pfad, ladetitel)


func _wechseln_mit_ladeschirm(pfad: String, titel: String) -> void:
	Ladeschirm.zeigen(titel)
	# Zwei Bilder abwarten, damit der Ladebildschirm wirklich sichtbar ist,
	# bevor der Hauptfaden mit dem Aufbau blockiert.
	await get_tree().process_frame
	await get_tree().process_frame
	Ladeschirm.fortschritt(0.05, "Szene wird geladen")
	get_tree().change_scene_to_file(pfad)


# ----------------------------------------------------------- Spielstand

func speichern() -> void:
	var datei := ConfigFile.new()
	datei.set_value("fortschritt", "freigeschaltet", freigeschaltet)
	datei.set_value("fortschritt", "geschafft", geschafft)
	datei.save(SPEICHERPFAD)


func laden() -> void:
	var datei := ConfigFile.new()
	if datei.load(SPEICHERPFAD) != OK:
		return
	freigeschaltet = int(datei.get_value("fortschritt", "freigeschaltet", 1))
	geschafft = datei.get_value("fortschritt", "geschafft", {})


## Setzt den gesamten Fortschritt zurück.
func zuruecksetzen() -> void:
	freigeschaltet = 1
	geschafft = {}
	speichern()
	fortschritt_geaendert.emit()
