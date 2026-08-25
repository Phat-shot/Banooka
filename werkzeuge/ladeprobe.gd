extends Node
## Lädt jede GDScript-Datei des Projekts wirklich – nicht nur den Import.
##
## Gebaut, weil ein Agent gemeldet hat, dass `godot --import` NICHT jedes
## Skript übersetzt: Ein "Inference on Variant" (in Godot 4.7 eine Meldung
## auf Fehlerstufe) rutschte durch und fiel erst beim Laden der Szene auf.
## Ein Prüfwerkzeug, das solche Fehler durchlässt, ist schlimmer als keines –
## es erzeugt Vertrauen, das es nicht deckt.
##
##   godot --headless --path <Kopie> res://werkzeuge/Ladeprobe.tscn

const ORTE := ["res://scenes", "res://scripts", "res://autoload", "res://werkzeuge"]

func _ready() -> void:
	var pfade: Array[String] = []
	for ort in ORTE:
		_sammle(ort, pfade)
	pfade.sort()
	var fehler := 0
	for p in pfade:
		var s := load(p)
		if s == null:
			print("  FEHLER  nicht ladbar: %s" % p)
			fehler += 1
	print("=== Ladeprobe: %d Skripte, %d nicht ladbar ===" % [pfade.size(), fehler])
	get_tree().quit(1 if fehler > 0 else 0)


func _sammle(verzeichnis: String, hinein: Array[String]) -> void:
	var d := DirAccess.open(verzeichnis)
	if d == null:
		return
	d.list_dir_begin()
	var eintrag := d.get_next()
	while eintrag != "":
		var voll := verzeichnis.path_join(eintrag)
		if d.current_is_dir():
			_sammle(voll, hinein)
		elif eintrag.ends_with(".gd"):
			hinein.append(voll)
		eintrag = d.get_next()
	d.list_dir_end()
