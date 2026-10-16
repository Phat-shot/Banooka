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
##   gespeichert(schluessel) -> Variant / ablegen(schluessel, inhalt)
##       Lesen und Schreiben getrennt, für Bauten über mehrere Bauschritte
##       (Gelände in Level 01); null heißt: noch nichts da.
##   vorladen(schluessel) -> bool
##       Liest einen abgelegten Wert im Hintergrund (ResourceLoader in einem
##       Arbeitsfaden), während das Level andere Schritte baut; ein späteres
##       `gespeichert()` holt ihn ab und wartet nur, wenn er noch nicht fertig
##       ist. false: nichts abgelegt (dann gar nicht erst anfragen). Level 05
##       lädt so Wald und Rasen (zusammen rund 60 ms von der Platte, Runde 2
##       der Bauzeitprobe). Ohne `vorladen` liest `gespeichert()` wie immer.
##   vorrechnen(schluessel, erzeuger) -> bool / vorrechnen_wert(...)
##       Rechnet, was noch nicht abgelegt ist, in einem Arbeitsfaden
##       (WorkerThreadPool) vor, während der Hauptfaden anderes baut; ein
##       späteres `holen`/`wert` mit demselben Schlüssel nimmt das Ergebnis
##       und wartet nur, wenn es noch nicht fertig ist. Siehe dort, was ein
##       solcher Erzeuger darf. Ohne `vorrechnen` rechnet `holen` wie immer.
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
## So viele Skripte findet der Fingerabdruck mindestens (heute rund 180).
## Findet er weniger, kann er Änderungen nicht sehen – etwa wenn eine
## Plattform res:// nicht auflisten kann. Dann bleibt der Speicher aus:
## sonst überlebten alte Bilder jedes Update, ohne dass es jemand merkt.
const MINDESTENS_SKRIPTE := 50
## Zwischendateien, die älter sind (Sekunden), stammen von einem Spiel,
## das mitten im Schreiben beendet wurde, und werden weggeräumt.
const ZWISCHEN_ALTER := 600

static var an := true

static var _bereit := false
static var _nutzbar := false
## Pfade, die `vorladen` im Hintergrund angefragt hat.
static var _vorgeladen := {}
## false = `vorrechnen` stößt nichts an (zum Vergleichen: Das Ergebnis muss
## dasselbe sein, nur die Ladezeit nicht).
static var vorrechnen_an := true
## Pfade, die `vorrechnen` angestoßen hat: Pfad -> {"aufgabe": Kennung im
## WorkerThreadPool, "ergebnis": Array, in das der Faden die Ressource legt}.
static var _im_bau := {}


static func holen(schluessel: String, erzeuger: Callable) -> Resource:
	if not _vorbereiten():
		return erzeuger.call()
	var pfad := _pfad(schluessel)
	if FileAccess.file_exists(pfad):
		var geladen := ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_IGNORE)
		if geladen != null:
			return geladen
	var neu: Resource = _abholen(pfad) if _im_bau.has(pfad) else null
	if neu == null:
		neu = erzeuger.call()
	if neu != null:
		# Je Prozess eine eigene Zwischendatei: Zwei Spiele (oder Prüfwerk-
		# zeuge) mit demselben user:// schreiben sich so nicht hinein.
		var zwischen := "%s.%d.neu.res" % [pfad.get_basename(), OS.get_process_id()]
		if ResourceSaver.save(neu, zwischen, ResourceSaver.FLAG_COMPRESS) == OK:
			DirAccess.rename_absolute(zwischen, pfad)
	return neu


## Liest einen mit `ablegen()` abgelegten Wert, ohne etwas zu erzeugen;
## null, wenn keiner da ist. Für Bauten, die über mehrere Bauschritte
## laufen und deshalb nicht in einen Erzeuger passen (Gelände in Level 01).
static func gespeichert(schluessel: String) -> Variant:
	if not _vorbereiten():
		return null
	var pfad := _pfad(schluessel)
	if not FileAccess.file_exists(pfad):
		return null
	var huelle: Resource
	if _vorgeladen.has(pfad):
		_vorgeladen.erase(pfad)
		huelle = ResourceLoader.load_threaded_get(pfad)
	else:
		huelle = ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_IGNORE)
	if huelle == null or not huelle.has_meta("wert"):
		return null
	return huelle.get_meta("wert")


## Fragt einen abgelegten Wert im Hintergrund an (siehe Kopf). false, wenn
## nichts abgelegt ist oder der Speicher aus ist.
static func vorladen(schluessel: String) -> bool:
	if not _vorbereiten():
		return false
	var pfad := _pfad(schluessel)
	if not FileAccess.file_exists(pfad):
		return false
	if _vorgeladen.has(pfad):
		return true
	if ResourceLoader.load_threaded_request(pfad, "", false,
			ResourceLoader.CACHE_MODE_IGNORE) != OK:
		return false
	_vorgeladen[pfad] = true
	return true


## Legt einen Wert ab (Gegenstück zu `gespeichert()`).
static func ablegen(schluessel: String, inhalt: Variant) -> void:
	if not _vorbereiten():
		return
	var huelle := Resource.new()
	huelle.set_meta("wert", inhalt)
	var pfad := _pfad(schluessel)
	var zwischen := "%s.%d.neu.res" % [pfad.get_basename(), OS.get_process_id()]
	if ResourceSaver.save(huelle, zwischen, ResourceSaver.FLAG_COMPRESS) == OK:
		DirAccess.rename_absolute(zwischen, pfad)


static func wert(schluessel: String, erzeuger: Callable) -> Variant:
	var huelle := holen(schluessel, _huelle(erzeuger))
	if huelle == null or not huelle.has_meta("wert"):
		return erzeuger.call()
	return huelle.get_meta("wert")


## Der Erzeuger der Hülle, in der `wert` einen Wert ablegt.
static func _huelle(erzeuger: Callable) -> Callable:
	return func() -> Resource:
		var r := Resource.new()
		r.set_meta("wert", erzeuger.call())
		return r


## Rechnet `erzeuger` in einem Arbeitsfaden vor, wenn unter `schluessel`
## nichts abgelegt ist (siehe Kopf). true: angestoßen. false: nichts zu tun
## oder nicht möglich (schon abgelegt oder unterwegs, Speicher aus, keine
## Fäden) – dann rechnet `holen` wie bisher selbst.
##
## WARUM. Kalt rechnet ein Level seine Texturen Bildpunkt für Bildpunkt im
## Hauptfaden, Schritt für Schritt; die übrigen Kerne stehen still. Was nur
## aus festen Zahlen entsteht, kann dort schon laufen, bevor der Aufbau es
## braucht. Level 05 stößt so seine Texturen an, bevor die Figur gebaut
## wird (`Level05._enter_tree`).
##
## Der Erzeuger darf NUR rechnen: Rauschen, Bilder, Arrays, neue
## Ressourcen. Nichts im Baum, keine statischen Zwischenspeicher, und nichts,
## was den Grafikserver synchron fragt (`Texture2D.get_image`,
## `Mesh.surface_get_arrays`): Wartet der Hauptfaden gerade auf diese
## Aufgabe, kann er die Frage nicht beantworten. Neue Texturen und Stoffe
## anzulegen ist erlaubt – der Server reiht das nur ein. Das Ergebnis muss
## dasselbe sein wie im Hauptfaden: derselbe Erzeuger, derselbe Schlüssel.
static func vorrechnen(schluessel: String, erzeuger: Callable) -> bool:
	if not vorrechnen_an or not faeden() or not _vorbereiten():
		return false
	var pfad := _pfad(schluessel)
	if _im_bau.has(pfad) or FileAccess.file_exists(pfad):
		return false
	var ergebnis := []
	var aufgabe := WorkerThreadPool.add_task(func() -> void:
		ergebnis.append(erzeuger.call()), true, "Bauspeicher " + schluessel)
	_im_bau[pfad] = {"aufgabe": aufgabe, "ergebnis": ergebnis}
	return true


## `vorrechnen` für einen Wert, den später `wert()` abholt.
static func vorrechnen_wert(schluessel: String, erzeuger: Callable) -> bool:
	return vorrechnen(schluessel, _huelle(erzeuger))


## Laufen Arbeitsfäden wirklich nebenher? Ohne Fäden (Web-Export ohne
## Fadenunterstützung) rechnet der WorkerThreadPool im aufrufenden Faden –
## Vorrechnen verlegte die Arbeit dann nur an eine Stelle ohne Ladebalken.
static func faeden() -> bool:
	return OS.has_feature("threads") and OS.get_processor_count() > 1


## Wartet auf eine angestoßene Rechnung und gibt ihr Ergebnis heraus (null,
## wenn der Faden nichts geliefert hat – dann rechnet `holen` selbst).
static func _abholen(pfad: String) -> Resource:
	var eintrag: Dictionary = _im_bau[pfad]
	_im_bau.erase(pfad)
	WorkerThreadPool.wait_for_task_completion(int(eintrag["aufgabe"]))
	var ergebnis: Array = eintrag["ergebnis"]
	return ergebnis[0] as Resource if not ergebnis.is_empty() else null


## Wartet alle angestoßenen, nicht abgeholten Rechnungen ab und verwirft
## sie – beim Verlassen eines Levels. Ein Faden, der beim Beenden des Spiels
## noch Skript rechnet, darf nicht übrig bleiben, und ein nie abgeholtes
## Ergebnis bliebe sonst bis zum Ende im Speicher.
static func vorrechnungen_verwerfen() -> void:
	for pfad: String in _im_bau.keys():
		WorkerThreadPool.wait_for_task_completion(int((_im_bau[pfad] as Dictionary)["aufgabe"]))
	_im_bau.clear()


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
	var skripte := PackedStringArray()
	var fassung := fingerabdruck(skripte)
	if skripte.size() < MINDESTENS_SKRIPTE:
		push_warning("Bauspeicher aus: nur %d Skripte für den Fingerabdruck gefunden"
				% skripte.size())
		return false
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
	else:
		_zwischen_aufraeumen()
	_nutzbar = true
	return true


## Liegengebliebene Zwischendateien (`*.neu.res`) löschen. Nur alte: Eine
## junge kann gerade ein zweites Spiel mit demselben user:// schreiben.
static func _zwischen_aufraeumen() -> void:
	var ordner := DirAccess.open(ORDNER)
	if ordner == null:
		return
	var jetzt := int(Time.get_unix_time_from_system())
	for datei in ordner.get_files():
		if not datei.ends_with(".neu.res"):
			continue
		var alter := jetzt - int(FileAccess.get_modified_time(ORDNER.path_join(datei)))
		if alter > ZWISCHEN_ALTER:
			ordner.remove(datei)


## md5 über alle Skripte (.gd/.gdc) unter `QUELLEN`, die Engine-Version
## und die Spielversion aus den Projekteinstellungen (zweite Sicherung,
## falls ein Export die Skripte anders ablegt). `teile` bekommt je Skript
## einen Eintrag – daran sieht der Aufrufer, ob überhaupt etwas gefunden
## wurde.
static func fingerabdruck(teile := PackedStringArray()) -> String:
	for quelle in QUELLEN:
		_sammle(quelle, teile)
	var info := Engine.get_version_info()
	var kopf := str(info.get("string", "")) + str(info.get("hash", "")) \
			+ str(ProjectSettings.get_setting("application/config/version", ""))
	return (kopf + "".join(teile)).md5_text()


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
