extends RefCounted
class_name ModellLader
## Lädt eigene Figuren zur Laufzeit und passt sie in die Spielerkapsel ein.
##
## Zur Laufzeit steht der Godot-Importer nicht zur Verfügung – eine .tscn
## oder .obj von außen wäre also nutzlos. glTF dagegen liest die Engine
## über `GLTFDocument` auch im fertigen Export, deshalb nur .glb/.gltf.
##
## Eingepasst wird über die zusammengefasste Hülle aller Netze: die Figur
## wird auf `ziel_hoehe` skaliert, waagerecht mittig gestellt und mit den
## Füßen auf y = 0 gesetzt. Damit passt jedes Modell in die
## Kollisionskapsel, egal in welcher Einheit es modelliert wurde.

## Höhe des Beuteldachses in Metern (Ohrenspitzen). Maßstab für alles andere.
const ZIEL_HOEHE := 1.42
## Modelle ohne brauchbare Hülle (leer oder entartet) werden abgelehnt.
const MIN_HOEHE := 0.001


## Lädt die Datei, passt sie ein und gibt den Knoten zurück – oder null,
## wenn sie fehlt, unlesbar ist oder nichts Sichtbares enthält. Der Grund
## steht dann als Warnung im Protokoll.
static func laden(pfad: String, groesse: float = 1.0) -> Node3D:
	if pfad.is_empty() or not FileAccess.file_exists(pfad):
		return null
	var papier := GLTFDocument.new()
	var zustand := GLTFState.new()
	# Nur die Optik wird gebraucht; Kollisionsformen aus der Datei würden
	# mit der Spielerkapsel streiten.
	if papier.append_from_file(pfad, zustand) != OK:
		push_warning("Eigenes Modell nicht lesbar: %s" % pfad)
		return null
	var szene := papier.generate_scene(zustand)
	if szene == null:
		push_warning("Eigenes Modell ohne Szene: %s" % pfad)
		return null
	var knoten := szene as Node3D
	if knoten == null:
		szene.queue_free()
		push_warning("Eigenes Modell ist keine 3D-Szene: %s" % pfad)
		return null

	_kollisionen_entfernen(knoten)
	if not einpassen(knoten, ZIEL_HOEHE * groesse):
		knoten.queue_free()
		push_warning("Eigenes Modell hat keine sichtbare Ausdehnung: %s" % pfad)
		return null
	return knoten


## Skaliert und verschiebt den Knoten so, dass er `ziel_hoehe` hoch ist,
## mittig steht und mit der Unterkante auf y = 0. Liefert false, wenn das
## Modell keine brauchbare Hülle hat.
static func einpassen(knoten: Node3D, ziel_hoehe: float) -> bool:
	var huelle := huelle_von(knoten)
	if huelle.size.y < MIN_HOEHE:
		return false
	var faktor := ziel_hoehe / huelle.size.y
	knoten.scale = Vector3(faktor, faktor, faktor)
	# Nach dem Skalieren zählt die skalierte Hülle, deshalb hier umrechnen.
	var mitte := huelle.get_center() * faktor
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
