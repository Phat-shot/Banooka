extends RefCounted
class_name ModellLader
## Lädt eigene Figuren zur Laufzeit und passt sie in die Spielerkapsel ein.
##
## Zwei Wege, je nachdem woher die Datei kommt:
##
## `res://…`  – mitgeliefert. Godot hat sie beim Bauen importiert; im
##              Export existiert die .glb als Datei gar nicht mehr,
##              sondern nur die importierte Ressource. Deshalb hier
##              `load()` statt `GLTFDocument` – sonst ist die Figur im
##              Editor da und in der APK weg.
## sonst      – vom Spieler hinzugelegt, also nie importiert. Die liest
##              `GLTFDocument` zur Laufzeit, weshalb nur .glb/.gltf gehen.
##
## Warum eine Datei abgelehnt wurde, steht danach in `letzter_fehler` und
## wird im Einstellungsbild angezeigt – eine stumm verschwundene Figur ist
## das Ärgerlichste, was hier passieren kann.
##
## Eingepasst wird über die zusammengefasste Hülle aller Netze: die Figur
## wird auf `ziel_hoehe` skaliert, waagerecht mittig gestellt und mit den
## Füßen auf y = 0 gesetzt. Damit passt jedes Modell in die
## Kollisionskapsel, egal in welcher Einheit es modelliert wurde.

## Höhe des Beuteldachses in Metern (Ohrenspitzen). Maßstab für alles andere.
const ZIEL_HOEHE := 1.42
## Modelle ohne brauchbare Hülle (leer oder entartet) werden abgelehnt.
const MIN_HOEHE := 0.001

## glTF-Erweiterungen, die Godot beim Lesen zur Laufzeit nicht beherrscht.
## Draco ist der häufigste Stolperstein: Viele Werkzeuge komprimieren beim
## Ausgeben damit, und die Datei sieht völlig gesund aus.
const UNGEEIGNETE_ERWEITERUNGEN := [
	"KHR_draco_mesh_compression",
	"EXT_meshopt_compression",
	"KHR_texture_basisu",
]

## Grund, warum das letzte `laden()` fehlgeschlagen ist. Leer = alles gut.
static var letzter_fehler := ""


## Lädt die Datei, passt sie ein und gibt den Knoten zurück – oder null,
## wenn sie fehlt, unlesbar ist oder nichts Sichtbares enthält. Der Grund
## steht dann als Warnung im Protokoll.
## Vorgabe für die Blickrichtung fremder Figuren, in Grad.
##
## Unsere eigene Figur schaut nach −Z, so wie Godot es vorsieht. Fremde
## glTF-Figuren schauen fast durchweg in die Gegenrichtung – nachgemessen
## mit `werkzeuge/modellschau.gd` und MODELLSCHAU_VORNE=1: Der Beuteldachs
## zeigt dort sein Gesicht, jedes eingesammelte Fremdmodell den Rücken.
## Deshalb ist eine halbe Drehung die Vorgabe; wer ein anders gebautes
## Modell hat, stellt sie in den Einstellungen um.
const STANDARDDREHUNG := 180.0


static func laden(pfad: String, groesse: float = 1.0,
		drehung_grad: float = STANDARDDREHUNG) -> Node3D:
	letzter_fehler = ""
	if pfad.is_empty():
		return null
	var knoten := _mitgeliefert(pfad) if pfad.begins_with("res://") \
			else _zur_laufzeit(pfad)
	if knoten == null:
		if not letzter_fehler.is_empty():
			push_warning("Eigenes Modell: %s (%s)" % [letzter_fehler, pfad])
		return null

	_kollisionen_entfernen(knoten)
	if not einpassen(knoten, ZIEL_HOEHE * groesse, deg_to_rad(drehung_grad)):
		knoten.queue_free()
		letzter_fehler = "Modell enthält keine sichtbaren Netze"
		push_warning("Eigenes Modell: %s (%s)" % [letzter_fehler, pfad])
		return null
	return knoten


## Mitgelieferte Datei: über den normalen Ressourcenweg, damit sie auch
## im Export gefunden wird.
static func _mitgeliefert(pfad: String) -> Node3D:
	if not ResourceLoader.exists(pfad):
		letzter_fehler = "Nicht im Spiel enthalten (nicht importiert)"
		return null
	var mittel := load(pfad)
	if mittel is PackedScene:
		return (mittel as PackedScene).instantiate() as Node3D
	if mittel is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mittel
		return mi
	letzter_fehler = "Datei ist weder Szene noch Netz"
	return null


## Vom Spieler hinzugelegte Datei: zur Laufzeit über GLTFDocument.
static func _zur_laufzeit(pfad: String) -> Node3D:
	if not FileAccess.file_exists(pfad):
		letzter_fehler = "Datei nicht gefunden"
		return null
	var hindernis := _unbrauchbare_erweiterung(pfad)
	if not hindernis.is_empty():
		letzter_fehler = "glTF-Erweiterung %s wird nicht unterstützt – " \
				% hindernis + "ohne Komprimierung neu ausgeben"
		return null
	var papier := GLTFDocument.new()
	var zustand := GLTFState.new()
	# Nur die Optik wird gebraucht; Kollisionsformen aus der Datei würden
	# mit der Spielerkapsel streiten.
	if papier.append_from_file(pfad, zustand) != OK:
		letzter_fehler = "Datei nicht lesbar oder beschädigt"
		return null
	var szene := papier.generate_scene(zustand)
	var knoten := szene as Node3D
	if knoten == null:
		if szene != null:
			szene.queue_free()
		letzter_fehler = "Datei enthält keine 3D-Szene"
		return null
	return knoten


## Sucht im JSON-Teil der Datei nach Erweiterungen, die Godot zur Laufzeit
## nicht lesen kann. Gibt den Namen der ersten gefundenen zurück.
static func _unbrauchbare_erweiterung(pfad: String) -> String:
	var datei := FileAccess.open(pfad, FileAccess.READ)
	if datei == null:
		return ""
	# Der JSON-Kopf steht am Anfang; ein Blick auf die ersten 64 KB reicht.
	var text := datei.get_buffer(mini(65536, datei.get_length())) \
			.get_string_from_utf8()
	datei.close()
	for name in UNGEEIGNETE_ERWEITERUNGEN:
		if text.find(name) >= 0:
			return name
	return ""


## Skaliert, dreht und verschiebt den Knoten so, dass er `ziel_hoehe` hoch
## ist, mittig steht und mit der Unterkante auf y = 0. Liefert false, wenn
## das Modell keine brauchbare Hülle hat.
##
## Die Drehung muss VOR der Mittigstellung eingerechnet werden: Der
## Ausgleich verschiebt den Knoten um die Mitte seiner Hülle, und die
## wandert mit, wenn man ihn dreht. Wer erst mittig stellt und danach
## dreht, bekommt eine Figur, die um den doppelten Versatz danebensteht.
static func einpassen(knoten: Node3D, ziel_hoehe: float,
		drehung: float = 0.0) -> bool:
	var huelle := huelle_von(knoten)
	if huelle.size.y < MIN_HOEHE:
		return false
	var faktor := ziel_hoehe / huelle.size.y
	knoten.scale = Vector3(faktor, faktor, faktor)
	knoten.rotation.y = drehung
	# Nach dem Skalieren zählt die skalierte Hülle, deshalb hier umrechnen.
	var mitte := Basis(Vector3.UP, drehung) * (huelle.get_center() * faktor)
	knoten.position = Vector3(-mitte.x, -huelle.position.y * faktor, -mitte.z)
	return true


## Zusammengefasste Hülle aller Netze im lokalen Raum von `wurzel`.
## Die eigene Verwandlung der Wurzel bleibt außen vor – sie wird gleich
## überschrieben. Gerechnet wird über die Kette der Kindverwandlungen und
## nicht über `global_transform`: der Knoten hängt noch nicht im Baum.
static func huelle_von(wurzel: Node3D) -> AABB:
	var gesammelt := _huelle(wurzel, Transform3D.IDENTITY, AABB(), [false])
	return gesammelt


static func _huelle(knoten: Node, bis_hier: Transform3D, bisher: AABB,
		gefunden: Array) -> AABB:
	var netz := knoten as MeshInstance3D
	if netz != null and netz.mesh != null:
		var kasten := bis_hier * netz.mesh.get_aabb()
		bisher = kasten if not gefunden[0] else bisher.merge(kasten)
		gefunden[0] = true
	for kind in knoten.get_children():
		var raum := kind as Node3D
		var weiter := bis_hier * raum.transform if raum != null else bis_hier
		bisher = _huelle(kind, weiter, bisher, gefunden)
	return bisher


## Kollisionsformen aus der Datei werfen wir weg – die Spielerkapsel in
## Player.tscn ist maßgeblich, zwei Formen würden sich gegenseitig stören.
## Beim Treffer wird der ganze Ast entfernt und nicht weiter abgestiegen,
## sonst würde ein Kind hinterher an einem schon gelösten Elternteil hängen.
static func _kollisionen_entfernen(knoten: Node) -> void:
	for kind in knoten.get_children():
		if kind is CollisionObject3D or kind is CollisionShape3D:
			knoten.remove_child(kind)
			kind.queue_free()
		else:
			_kollisionen_entfernen(kind)
