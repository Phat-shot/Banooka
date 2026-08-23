extends Node
## Einstellungen, die über Sitzungen hinweg erhalten bleiben.
## Als Autoload unter dem Namen "Einstellungen" registriert.
##
## Bisher nur das Spielermodell: Wer mag, legt eine eigene Figur als
## glTF-Datei ab und spielt damit statt mit dem Beuteldachs. Die Datei
## wird zur Laufzeit geladen (nicht beim Bauen importiert), deshalb kommen
## nur Formate infrage, die Godot ohne Importschritt lesen kann – das sind
## .glb und .gltf. Selbstenthaltendes .glb ist die sichere Wahl: bei .gltf
## liegen Textur- und Binärdateien daneben und müssen mitkopiert werden.

signal geaendert

## Ordner, in dem eigene Modelle liegen. Liegt unter `user://`, überlebt
## also Neuinstallationen der Anwendung nicht, ist dafür aber auf jeder
## Plattform beschreibbar.
const ORDNER := "user://modelle"
const ENDUNGEN := ["glb", "gltf"]
const SPEICHERPFAD := "user://einstellungen.cfg"

## Dateiname im Modellordner. Leer = mitgelieferter Beuteldachs.
var eigenes_modell := ""
## Feinjustierung der Figurengröße, 1.0 = auf Standardhöhe eingepasst.
var modell_groesse := 1.0
## Debugmodus: unendlich Leben, immer Schutz, alle Räume offen.
## Bleibt über Sitzungen erhalten, damit man beim Prüfen eines Levels
## nicht jedes Mal neu einschaltet.
var debug := false:
	set(an):
		debug = an
		GameState.debug = an
		geaendert.emit()


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)
	laden()
	GameState.debug = debug


## Absoluter Pfad des gewählten Modells, oder "" für den Beuteldachs.
func modell_pfad() -> String:
	if eigenes_modell.is_empty():
		return ""
	var pfad := ORDNER.path_join(eigenes_modell)
	return pfad if FileAccess.file_exists(pfad) else ""


## Alle Modelldateien im Ordner, alphabetisch.
func modelle() -> PackedStringArray:
	var gefunden := PackedStringArray()
	var ordner := DirAccess.open(ORDNER)
	if ordner == null:
		return gefunden
	for name in ordner.get_files():
		if ENDUNGEN.has(name.get_extension().to_lower()):
			gefunden.append(name)
	gefunden.sort()
	return gefunden


## Wählt ein Modell aus dem Ordner ("" = Beuteldachs) und speichert.
func waehle_modell(dateiname: String) -> void:
	eigenes_modell = dateiname
	speichern()
	geaendert.emit()


func setze_groesse(faktor: float) -> void:
	modell_groesse = clampf(faktor, 0.5, 2.0)
	speichern()
	geaendert.emit()


## Kopiert eine Datei von außerhalb in den Modellordner und wählt sie aus.
## Gibt eine leere Zeichenkette zurück, wenn es geklappt hat, sonst den
## Fehlertext für die Anzeige.
func uebernehmen(quelle: String) -> String:
	if not ENDUNGEN.has(quelle.get_extension().to_lower()):
		return "Nur .glb oder .gltf"
	var lesen := FileAccess.open(quelle, FileAccess.READ)
	if lesen == null:
		return "Datei nicht lesbar"
	var daten := lesen.get_buffer(lesen.get_length())
	lesen.close()

	DirAccess.make_dir_recursive_absolute(ORDNER)
	var ziel := ORDNER.path_join(quelle.get_file())
	var schreiben := FileAccess.open(ziel, FileAccess.WRITE)
	if schreiben == null:
		return "Ordner nicht beschreibbar"
	schreiben.store_buffer(daten)
	schreiben.close()

	waehle_modell(quelle.get_file())
	return ""


## Löscht ein Modell aus dem Ordner.
func entfernen(dateiname: String) -> void:
	var pfad := ORDNER.path_join(dateiname)
	if FileAccess.file_exists(pfad):
		DirAccess.remove_absolute(pfad)
	if eigenes_modell == dateiname:
		eigenes_modell = ""
	speichern()
	geaendert.emit()


# --------------------------------------------------------- Spielstand

func speichern() -> void:
	var datei := ConfigFile.new()
	datei.set_value("figur", "modell", eigenes_modell)
	datei.set_value("figur", "groesse", modell_groesse)
	datei.set_value("spiel", "debug", debug)
	datei.save(SPEICHERPFAD)


func laden() -> void:
	var datei := ConfigFile.new()
	if datei.load(SPEICHERPFAD) != OK:
		return
	eigenes_modell = String(datei.get_value("figur", "modell", ""))
	modell_groesse = clampf(float(datei.get_value("figur", "groesse", 1.0)), 0.5, 2.0)
	debug = bool(datei.get_value("spiel", "debug", false))
