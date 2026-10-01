extends RefCounted
class_name Bauspeicher
## Zwischenspeicher auf der Platte (`user://bauspeicher`) für das, was beim
## Laden im Code entsteht und teuer ist: Texturen der Materialbibliothek,
## Rauschbilder der Wegmaske, Blatt- und Moosbilder.
##
## WARUM. Diese Bilder rechnet GDScript Bildpunkt für Bildpunkt aus. Für
## Level 01 waren das gut 2,5 s der Ladezeit (gemessen mit
## `werkzeuge/bauzeitprobe.gd`, Rechner; auf dem Handy mehr), allein der
## Waldweg 0,6 s. Von der Platte geladen kostet derselbe Waldweg 8 ms. Das
## erste Laden nach der Installation (und nach jeder Änderung am Code)
## rechnet und legt ab, jedes weitere liest nur noch.
##
## Schnittstelle:
##   holen(schluessel, erzeuger: Callable) -> Resource
##       Liefert die Ressource vom Speicher oder ruft `erzeuger` (gibt eine
##       Resource zurück: Image, ImageTexture, Material …) und legt das
##       Ergebnis ab. Unterressourcen (Texturen eines Materials) wandern
##       mit hinein. Rückgaben sind geteilt – nie verändern.
##   wert(schluessel, erzeuger: Callable) -> Variant
##       Dasselbe für Werte, die keine Ressource sind (Dictionary, Arrays,
##       Farben – auch mit Ressourcen darin), verpackt als Metadaten.
##   netz(art, argumente: Array, erzeuger: Callable) -> ArrayMesh
##       Für Netze, die allein aus ihren Argumenten entstehen (Stämme,
##       Kronen, Farne, Felsen): Schlüssel aus `art` und dem md5 der
##       Argumente. Jeder Aufruf liefert ein eigenes Netz wie vorher auch –
##       wer es verändert, verändert nichts im Speicher.
##   an: bool    false = nie lesen, nie schreiben (zum Vergleichen)
##
## Der SCHLÜSSEL muss alles nennen, wovon das Ergebnis abhängt und was sich
## zur Laufzeit ändern kann (Farben, Größen, `Effekte.reduziert`). Was nur
## im Code steht, deckt die FASSUNG ab: ein md5 über alle Skripte unter
## res://scripts, res://scenes und res://autoload, so wie sie im Paket
## liegen (im Export die übersetzten .gdc), dazu die Engine-Version. Ändert
## sich daran irgendetwas, ist der ganze Speicher veraltet und wird beim
## ersten Zugriff geleert – lieber einmal neu rechnen als ein altes Bild
## zeigen. Das Prüfen kostet einmal je Sitzung rund 25 ms.
##
## Geschrieben wird erst in eine Zwischendatei, dann umbenannt: Wird das
## Spiel mitten im Schreiben beendet, bleibt keine halbe Datei liegen.
## Was sich nicht lesen lässt, wird neu gerechnet.

const ORDNER := "user://bauspeicher"
const FASSUNGSDATEI := "user://bauspeicher/fassung.txt"
## Wo die Skripte liegen, aus denen der Fingerabdruck entsteht.
const QUELLEN: Array[String] = ["res://scripts", "res://scenes", "res://autoload"]

static var an := true

static var _bereit := false
static var _nutzbar := false


static func holen(schluessel: String, erzeuger: Callable) -> Resource:
	if not _vorbereiten():
		return erzeuger.call()
	var pfad := _pfad(schluessel)
	if FileAccess.file_exists(pfad):
		var geladen := ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_IGNORE)
		if geladen != null:
			return geladen
	var neu: Resource = erzeuger.call()
	if neu != null:
		var zwischen := pfad.get_basename() + ".neu.res"
		if ResourceSaver.save(neu, zwischen, ResourceSaver.FLAG_COMPRESS) == OK:
			DirAccess.rename_absolute(zwischen, pfad)
	return neu


static func wert(schluessel: String, erzeuger: Callable) -> Variant:
	var huelle := holen(schluessel, func() -> Resource:
		var r := Resource.new()
		r.set_meta("wert", erzeuger.call())
		return r)
	if huelle == null or not huelle.has_meta("wert"):
		return erzeuger.call()
	return huelle.get_meta("wert")


static func netz(art: String, argumente: Array, erzeuger: Callable) -> ArrayMesh:
	var text := var_to_str(argumente)
	# Ein Objekt hat keinen festen Text (Kennung) – dann jedes Mal rechnen.
	if text.contains("Object("):
		return erzeuger.call()
	return holen(art + "_" + text.md5_text(), erzeuger) as ArrayMesh


static func _pfad(schluessel: String) -> String:
	return ORDNER.path_join(schluessel.validate_filename() + ".res")


## Einmal je Sitzung: Ordner anlegen, Fassung prüfen, Veraltetes löschen.
static func _vorbereiten() -> bool:
	if not an:
		return false
	if _bereit:
		return _nutzbar
	_bereit = true
	if DirAccess.make_dir_recursive_absolute(ORDNER) != OK:
		return false
	var fassung := fingerabdruck()
	var alt := ""
	if FileAccess.file_exists(FASSUNGSDATEI):
		alt = FileAccess.get_file_as_string(FASSUNGSDATEI).strip_edges()
	if alt != fassung:
		var ordner := DirAccess.open(ORDNER)
		if ordner == null:
			return false
		for datei in ordner.get_files():
			ordner.remove(datei)
		var f := FileAccess.open(FASSUNGSDATEI, FileAccess.WRITE)
		if f == null:
			return false
		f.store_line(fassung)
		f.close()
	_nutzbar = true
	return true


## md5 über alle Skripte (.gd/.gdc) unter `QUELLEN` und die Engine-Version.
static func fingerabdruck() -> String:
	var teile := PackedStringArray()
	var info := Engine.get_version_info()
	teile.append(str(info.get("string", "")) + str(info.get("hash", "")))
	for quelle in QUELLEN:
		_sammle(quelle, teile)
	return "".join(teile).md5_text()


static func _sammle(ordner_pfad: String, teile: PackedStringArray) -> void:
	var ordner := DirAccess.open(ordner_pfad)
	if ordner == null:
		return
	var dateien := ordner.get_files()
	dateien.sort()
	for datei in dateien:
		if datei.ends_with(".gd") or datei.ends_with(".gdc"):
			var voll := ordner_pfad.path_join(datei)
			teile.append(voll + FileAccess.get_md5(voll))
	var unter := ordner.get_directories()
	unter.sort()
	for unterordner in unter:
		_sammle(ordner_pfad.path_join(unterordner), teile)
