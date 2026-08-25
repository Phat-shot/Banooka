extends Node
## Einstellungen, die über Sitzungen hinweg erhalten bleiben.
## Als Autoload unter dem Namen "Einstellungen" registriert.
##
## Bisher nur das Spielermodell. Es gibt dafür zwei Wege, und der
## Unterschied ist wichtig:
##
## 1. MITGELIEFERT (`res://assets/modelle`) – die Datei liegt im Projekt,
##    wird beim Bauen importiert und steckt damit in jedem Export, auch in
##    der APK und im Browser. Das ist der Weg für unsere eigenen Figuren.
## 2. SELBST HINZUGELEGT (`user://modelle`) – der Spieler wählt zur
##    Laufzeit eine Datei. Die wird ohne Importschritt gelesen, deshalb
##    kommen nur .glb/.gltf infrage. Auf Android hängt dieser Weg an einer
##    Speicher-Berechtigung und am Dateidialog des Geräts; wenn dort
##    nichts ankommt, liegt es fast immer daran – nicht am Modell.
##
## Selbstenthaltendes .glb ist in beiden Fällen die sichere Wahl: bei
## .gltf liegen Textur- und Binärdateien daneben und müssen mit.

signal geaendert

## Ordner, in dem eigene Modelle liegen. Liegt unter `user://`, überlebt
## also Neuinstallationen der Anwendung nicht, ist dafür aber auf jeder
## Plattform beschreibbar.
const ORDNER := "user://modelle"
## Ordner der mitgelieferten Figuren. Die landen über den normalen
## Godot-Import im Export – für die APK der einzig verlässliche Weg.
const MITGELIEFERT := "res://assets/modelle"
const ENDUNGEN := ["glb", "gltf"]
const SPEICHERPFAD := "user://einstellungen.cfg"

## Kennung der gewählten Figur. Leer = Beuteldachs aus dem Code.
## Mitgelieferte Figuren stehen mit vollem `res://`-Pfad drin, selbst
## hinzugelegte mit blankem Dateinamen.
var eigenes_modell := ""
## Feinjustierung der Figurengröße, 1.0 = auf Standardhöhe eingepasst.
var modell_groesse := 1.0
## Mitgelieferte Naturmodelle (Kenney, CC0) statt der prozeduralen Props.
## Umschaltbar, damit sich beide Fassungen vergleichen lassen; der
## prozedurale Aufbau bleibt in jedem Fall der Rückfall.
var fremde_modelle := true:
	set(an):
		fremde_modelle = an
		geaendert.emit()
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


## Pfad des gewählten Modells, oder "" für den Beuteldachs.
##
## Für mitgelieferte Dateien wird `ResourceLoader.exists()` gefragt und
## NICHT `FileAccess.file_exists()`: Im fertigen Export gibt es die .glb
## als Datei nicht mehr, Godot hat sie beim Bauen zu einer importierten
## Ressource umgeschrieben. Genau daran scheitert die Prüfung sonst – im
## Editor läuft alles, in der APK ist die Figur plötzlich weg.
func modell_pfad() -> String:
	if eigenes_modell.is_empty():
		return ""
	if eigenes_modell.begins_with("res://"):
		return eigenes_modell if ResourceLoader.exists(eigenes_modell) else ""
	var pfad := ORDNER.path_join(eigenes_modell)
	return pfad if FileAccess.file_exists(pfad) else ""


## Alle wählbaren Figuren: erst die mitgelieferten (voller res://-Pfad),
## dann die selbst hinzugelegten (blanker Dateiname).
func modelle() -> PackedStringArray:
	var gefunden := PackedStringArray()
	for name in _dateien_in(MITGELIEFERT):
		gefunden.append(MITGELIEFERT.path_join(name))
	gefunden.append_array(_dateien_in(ORDNER))
	return gefunden


## Anzeigename einer Kennung – ohne Ordner, damit die Zeile kurz bleibt.
func anzeigename(kennung: String) -> String:
	if kennung.is_empty():
		return "Beuteldachs (Standard)"
	if kennung.begins_with("res://"):
		return "%s (mitgeliefert)" % kennung.get_file()
	return kennung


## Lässt sich diese Figur löschen? Mitgelieferte gehören zum Spiel.
func loeschbar(kennung: String) -> bool:
	return not kennung.is_empty() and not kennung.begins_with("res://")


func _dateien_in(ordner_pfad: String) -> PackedStringArray:
	var gefunden := PackedStringArray()
	var ordner := DirAccess.open(ordner_pfad)
	if ordner == null:
		return gefunden
	for name in ordner.get_files():
		# Im Export heißen importierte Dateien ".glb.import"; der blanke
		# Name steckt davor.
		var sauber := name.trim_suffix(".import").trim_suffix(".remap")
		if ENDUNGEN.has(sauber.get_extension().to_lower()) \
				and not gefunden.has(sauber):
			gefunden.append(sauber)
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


## Nimmt eine Datei als Rohdaten auf. Im Browser gibt es keinen Pfad, den
## man lesen könnte – dort kommen die Bytes aus dem Hochladefeld.
## Gibt "" zurück, wenn es geklappt hat, sonst den Fehlertext.
func uebernehmen_daten(dateiname: String, daten: PackedByteArray) -> String:
	var sauber := dateiname.get_file()
	if not ENDUNGEN.has(sauber.get_extension().to_lower()):
		return "Nur .glb oder .gltf"
	if daten.is_empty():
		return "Datei war leer"
	DirAccess.make_dir_recursive_absolute(ORDNER)
	var schreiben := FileAccess.open(ORDNER.path_join(sauber), FileAccess.WRITE)
	if schreiben == null:
		return "Ordner nicht beschreibbar"
	schreiben.store_buffer(daten)
	schreiben.close()
	# Im Browser liegt `user://` in der IndexedDB. Ohne diesen Anstoß wäre
	# die Datei nach dem nächsten Laden der Seite wieder weg.
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		JavaScriptBridge.force_fs_sync()
	waehle_modell(sauber)
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
	datei.set_value("spiel", "fremde_modelle", fremde_modelle)
	datei.save(SPEICHERPFAD)


func laden() -> void:
	var datei := ConfigFile.new()
	if datei.load(SPEICHERPFAD) != OK:
		return
	eigenes_modell = String(datei.get_value("figur", "modell", ""))
	modell_groesse = clampf(float(datei.get_value("figur", "groesse", 1.0)), 0.5, 2.0)
	debug = bool(datei.get_value("spiel", "debug", false))
	fremde_modelle = bool(datei.get_value("spiel", "fremde_modelle", true))
