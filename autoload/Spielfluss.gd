extends Node
## Szenenfluss und Spielstand: Splash → Portalraum → Level → Portalraum.
##
## Als Autoload unter dem Namen "Spielfluss" registriert.
##
## Der Portalraum besteht aus fünf Räumen mit je fünf Leveln (25 Level).
## Noch nicht gebaute Level haben einen leeren Eintrag in `LEVEL_SZENEN`
## und erscheinen im Portalraum als verschlossene Tore.
##
## Gespeichert wird auf einen von vier Plätzen, und zwar immer beim
## Betreten des Portalraums – nicht mitten im Level.

const SPLASH_SZENE := "res://scenes/ui/Splash.tscn"
const HUB_SZENE := "res://scenes/hub/Hub.tscn"
const OPTIONEN_SZENE := "res://scenes/ui/Optionen.tscn"

const RAEUME := 5
const LEVEL_JE_RAUM := 5
const LEVEL_GESAMT := RAEUME * LEVEL_JE_RAUM

## Vier Speicherplätze. Gespeichert wird ausschließlich im Portalraum
## (siehe `hub.gd`), nie mitten im Level – so ist immer klar, worauf ein
## Spielstand zurückfällt.
const SLOTS := 4
const SLOT_MUSTER := "user://spielstand_%d.cfg"
## Alte Einzeldatei aus der Zeit vor den Speicherplätzen; wird beim ersten
## Start einmalig nach Platz 1 übernommen.
const ALTPFAD := "user://spielstand.cfg"

## Szenenpfade der Level, Index 0 = Level 01.
## Leerer Eintrag = noch nicht gebaut.
const LEVEL_SZENEN := [
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
	"res://scenes/levels/Level05.tscn",
	"res://scenes/levels/Level06.tscn",
	"res://scenes/levels/Level07.tscn",
	"res://scenes/levels/Level08.tscn",
	"res://scenes/levels/Level09.tscn",
	"res://scenes/levels/Level10.tscn",
	"res://scenes/levels/Level11.tscn",
	"res://scenes/levels/Level12.tscn",
	"res://scenes/levels/Level13.tscn",
	"res://scenes/levels/Level14.tscn",
	"res://scenes/levels/Level15.tscn",
	"res://scenes/levels/Level16.tscn",
	"res://scenes/levels/Level17.tscn",
	"res://scenes/levels/Level18.tscn",
	"res://scenes/levels/Level19.tscn",
	"res://scenes/levels/Level20.tscn",
	"res://scenes/levels/Level21.tscn",
	"res://scenes/levels/Level22.tscn",
	"res://scenes/levels/Level23.tscn",
	"res://scenes/levels/Level24.tscn",
	"res://scenes/levels/Level25.tscn",
]

## Namen der fünf Abschnitte (ein Raum je Abschnitt).
##
## Die Namen der Räume 3 bis 5 stammten aus der Zeit, als deren Inhalt
## noch offen war, und beschrieben ihn nicht mehr: In "Frostkronen" lagen
## am Ende ein Kanal, ein Dschungel und eine Maschinenhalle. Ein Raumname
## soll sagen, was hinter der Tür steht.
const RAUM_NAMEN := [
	"Wurzelwald",
	"Nebelsümpfe",
	"Steinfeste",
	"Rost und Ranken",
	"Sand und Neon",
]

signal fortschritt_geaendert

## Höchstes freigeschaltetes Level (1-basiert).
var freigeschaltet := 1
## Abgeschlossene Level: Nummer -> {"kisten": bool, "fruechte": int}
var geschafft := {}
## Bestzeiten des Zeitmodus: Nummer -> {"zeit": float, "stufe": int}
## Die Stufe ist die BESTE je erreichte, nicht die der letzten Zeit –
## beide wachsen nur, keine geht durch einen schlechteren Lauf verloren.
var zeiten := {}
## Gerade gespieltes Level (0 = keins).
var aktuelles_level := 0
## Gewählter Speicherplatz (1..SLOTS); 0 = noch keiner gewählt.
var aktueller_slot := 0
## Gesammelte Früchte über den ganzen Spielstand hinweg.
var fruechte_gesamt := 0


func _ready() -> void:
	_altstand_uebernehmen()


# ----------------------------------------------------------- Abfragen

## Ist für dieses Level überhaupt eine Szene gebaut?
func level_gebaut(nummer: int) -> bool:
	if nummer < 1 or nummer > LEVEL_GESAMT:
		return false
	return not String(LEVEL_SZENEN[nummer - 1]).is_empty()


## Darf der Spieler dieses Level betreten?
##
## Innerhalb eines Raums ist jedes gebaute Level offen – die Reihenfolge
## darin bleibt dem Spieler überlassen. Der nächste Raum öffnet erst,
## wenn der vorige abgeschlossen ist. Im Debugmodus ist alles offen.
func level_offen(nummer: int) -> bool:
	if not level_gebaut(nummer):
		return false
	return raum_offen(raum_von_level(nummer))


## Ist dieser Raum betretbar? Raum 1 immer, jeder weitere erst, wenn der
## vorige abgeschlossen ist.
func raum_offen(raum: int) -> bool:
	if raum <= 1 or GameState.debug:
		return true
	return raum_abgeschlossen(raum - 1)


## Sind alle gebauten Level dieses Raums geschafft?
## Ein Raum ohne gebaute Level gilt als abgeschlossen – sonst hinge der
## Fortschritt an Leveln, die es noch gar nicht gibt.
func raum_abgeschlossen(raum: int) -> bool:
	for nummer in level_im_raum(raum):
		if level_gebaut(nummer) and not geschafft.has(nummer):
			return false
	return true


## Raum (1-basiert), in dem dieses Level liegt.
func raum_von_level(nummer: int) -> int:
	return (nummer - 1) / LEVEL_JE_RAUM + 1


## Die fünf Levelnummern eines Raums.
func level_im_raum(raum: int) -> Array[int]:
	var liste: Array[int] = []
	for i in LEVEL_JE_RAUM:
		liste.append((raum - 1) * LEVEL_JE_RAUM + i + 1)
	return liste


# ----------------------------------------------------------- Wechseln

func zum_splash() -> void:
	aktuelles_level = 0
	_wechseln(SPLASH_SZENE)


func zu_optionen() -> void:
	aktuelles_level = 0
	_wechseln(OPTIONEN_SZENE)


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
##
## Beide Edelsteine sind dauerhaft: Wer sie einmal geholt hat, behält sie
## auch nach einem schlechteren Durchlauf.
func level_abschliessen(alle_kisten: bool, ohne_tod: bool = false) -> void:
	if aktuelles_level < 1:
		return
	var eintrag: Dictionary = geschafft.get(aktuelles_level, {})
	eintrag["kisten"] = bool(eintrag.get("kisten", false)) or alle_kisten
	eintrag["ohne_tod"] = bool(eintrag.get("ohne_tod", false)) or ohne_tod
	eintrag["fruechte"] = maxi(int(eintrag.get("fruechte", 0)), GameState.fruechte)
	geschafft[aktuelles_level] = eintrag
	freigeschaltet = maxi(freigeschaltet, mini(aktuelles_level + 1, LEVEL_GESAMT))
	fruechte_gesamt += GameState.fruechte
	# Geschrieben wird nicht hier, sondern beim Betreten des Portalraums.
	fortschritt_geaendert.emit()


## Trägt das Ergebnis eines Zeitlaufs ein.
## Rückgabe: true, wenn es eine neue Bestzeit ist.
func zeit_eintragen(nummer: int, gelaufen: float, stufe: int) -> bool:
	if nummer < 1 or gelaufen <= 0.0:
		return false
	var eintrag: Dictionary = zeiten.get(nummer, {})
	var alt := float(eintrag.get("zeit", 0.0))
	var besser := alt <= 0.0 or gelaufen < alt
	if besser:
		eintrag["zeit"] = gelaufen
	eintrag["stufe"] = maxi(int(eintrag.get("stufe", 0)), stufe)
	zeiten[nummer] = eintrag
	# Geschrieben wird wie der übrige Fortschritt erst im Portalraum.
	fortschritt_geaendert.emit()
	return besser


## Bestzeit und beste Stufe eines Levels.
## Rückgabe: {"zeit": float, "stufe": int}; Zeit 0 heißt "noch keine".
func zeit_von(nummer: int) -> Dictionary:
	var eintrag: Dictionary = zeiten.get(nummer, {})
	return {
		"zeit": float(eintrag.get("zeit", 0.0)),
		"stufe": int(eintrag.get("stufe", 0)),
	}


## Wechselt die Szene. Mit Titel wird vorher der Ladebildschirm
## eingeblendet – erst wenn er tatsächlich gezeichnet ist, beginnt der
## Wechsel, sonst sähe man während des Aufbaus die alte Szene einfrieren.
func _wechseln(pfad: String, ladetitel: String = "") -> void:
	if pfad.is_empty() or not ResourceLoader.exists(pfad):
		push_warning("Szene fehlt: %s" % pfad)
		return
	# Touch-Zustand aufräumen, sonst nimmt die neue Szene den Daumen vom
	# Portal-Eingang als dauerhaften Steuerbefehl mit.
	InputHub.zuruecksetzen()
	# Ein Zeitlauf endet mit der Szene, in der er lief. Ohne das liefe die
	# Uhr im Portalraum weiter – und zählte die Zeit mit, die jemand dort
	# beim Aussuchen des nächsten Levels verbringt.
	Zeitlauf.abbrechen()
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

func slot_pfad(slot: int) -> String:
	return SLOT_MUSTER % slot


## Kopfdaten eines Speicherplatzes, ohne ihn zu laden.
## Rückgabe: {"belegt": bool, "freigeschaltet": int, "geschafft": int,
##            "fruechte": int, "raum": String}
func slot_daten(slot: int) -> Dictionary:
	var leer := {"belegt": false, "freigeschaltet": 1, "geschafft": 0,
			"fruechte": 0, "relikte": 0, "raum": RAUM_NAMEN[0]}
	if slot < 1 or slot > SLOTS:
		return leer
	var datei := ConfigFile.new()
	if datei.load(slot_pfad(slot)) != OK:
		return leer
	var frei := int(datei.get_value("fortschritt", "freigeschaltet", 1))
	var fertig: Dictionary = datei.get_value("fortschritt", "geschafft", {})
	var laeufe: Dictionary = datei.get_value("fortschritt", "zeiten", {})
	var relikte := 0
	for nummer in laeufe:
		if int((laeufe[nummer] as Dictionary).get("stufe", 0)) > 0:
			relikte += 1
	var raum := raum_von_level(clampi(frei, 1, LEVEL_GESAMT))
	return {
		"belegt": true,
		"freigeschaltet": frei,
		"geschafft": fertig.size(),
		"fruechte": int(datei.get_value("fortschritt", "fruechte", 0)),
		"relikte": relikte,
		"raum": RAUM_NAMEN[clampi(raum - 1, 0, RAUM_NAMEN.size() - 1)],
	}


## Weitesten Stand über alle Plätze hinweg – für die Fortschrittszeile
## im Startbildschirm, wo noch kein Platz gewählt ist.
## Rückgabe: {"freigeschaltet": int, "geschafft": Dictionary}
func bester_stand() -> Dictionary:
	var frei := 1
	var fertig := {}
	for slot in range(1, SLOTS + 1):
		var datei := ConfigFile.new()
		if datei.load(slot_pfad(slot)) != OK:
			continue
		frei = maxi(frei, int(datei.get_value("fortschritt", "freigeschaltet", 1)))
		var liste: Dictionary = datei.get_value("fortschritt", "geschafft", {})
		for nummer in liste:
			fertig[nummer] = true
	return {"freigeschaltet": frei, "geschafft": fertig}


## Beginnt auf diesem Platz ein frisches Spiel und geht in den Portalraum.
func neues_spiel(slot: int) -> void:
	aktueller_slot = clampi(slot, 1, SLOTS)
	freigeschaltet = 1
	geschafft = {}
	zeiten = {}
	fruechte_gesamt = 0
	GameState.neu_beginnen()
	speichern()
	fortschritt_geaendert.emit()
	zum_hub()


## Lädt diesen Platz und geht in den Portalraum. Falsch, wenn er leer ist.
func spiel_laden(slot: int) -> bool:
	if slot < 1 or slot > SLOTS:
		return false
	var datei := ConfigFile.new()
	if datei.load(slot_pfad(slot)) != OK:
		return false
	aktueller_slot = slot
	freigeschaltet = int(datei.get_value("fortschritt", "freigeschaltet", 1))
	geschafft = datei.get_value("fortschritt", "geschafft", {})
	zeiten = datei.get_value("fortschritt", "zeiten", {})
	fruechte_gesamt = int(datei.get_value("fortschritt", "fruechte", 0))
	GameState.neu_beginnen()
	fortschritt_geaendert.emit()
	zum_hub()
	return true


## Schreibt den laufenden Fortschritt auf den gewählten Platz.
## Wird vom Portalraum bei jedem Betreten aufgerufen.
func speichern() -> void:
	if aktueller_slot < 1:
		return
	var datei := ConfigFile.new()
	datei.set_value("fortschritt", "freigeschaltet", freigeschaltet)
	datei.set_value("fortschritt", "geschafft", geschafft)
	datei.set_value("fortschritt", "zeiten", zeiten)
	datei.set_value("fortschritt", "fruechte", fruechte_gesamt)
	datei.save(slot_pfad(aktueller_slot))


## Löscht einen Speicherplatz.
func slot_loeschen(slot: int) -> void:
	if slot < 1 or slot > SLOTS:
		return
	DirAccess.remove_absolute(slot_pfad(slot))
	if aktueller_slot == slot:
		aktueller_slot = 0
		freigeschaltet = 1
		geschafft = {}
		zeiten = {}
		fruechte_gesamt = 0
	fortschritt_geaendert.emit()


## Übernimmt einen Spielstand aus der Zeit vor den Speicherplätzen.
func _altstand_uebernehmen() -> void:
	if not FileAccess.file_exists(ALTPFAD):
		return
	if FileAccess.file_exists(slot_pfad(1)):
		DirAccess.remove_absolute(ALTPFAD)
		return
	var datei := ConfigFile.new()
	if datei.load(ALTPFAD) != OK:
		return
	datei.set_value("fortschritt", "fruechte", 0)
	datei.save(slot_pfad(1))
	DirAccess.remove_absolute(ALTPFAD)
