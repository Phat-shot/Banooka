extends RefCounted
class_name Fremdmodelle
## Mitgelieferte Modelle aus fremden CC0-Sammlungen: Wald-Props aus dem
## Kenney Nature Kit, Gegner von Quaternius und Exceptional_3D.
##
## Der prozedurale Aufbau bleibt vollständig erhalten und ist der Rückfall:
## Fehlt eine Datei oder ist die Umschaltung aus, baut jedes Prop sich wie
## bisher selbst. So lässt sich der Look vergleichen, ohne etwas zu
## verlieren, und das Spiel läuft auch ohne die Dateien.
##
## Die Modelle werden über `load()` geholt und nicht über `GLTFDocument`:
## Sie liegen unter res://, sind also beim Bauen importiert – im Export
## gibt es die .glb-Datei gar nicht mehr, nur die importierte Ressource.
##
## Quelle und Lizenz stehen in `assets/CREDITS.md`.

const ORDNER := "res://assets/modelle/natur"
const ORDNER_GEGNER := "res://assets/modelle/gegner"

## Einmal geladene Szenen. Ein Wald setzt dasselbe Modell hundertfach ein;
## ohne Zwischenspeicher würde jede Instanz neu von der Platte gelesen.
static var _vorrat := {}
## Gemessene Abmessungen der Modelle, damit nicht jedes Mal die Hülle über
## den ganzen Baum gerechnet wird.
static var _hoehen := {}
## Auf Beleuchtung umgestellte Materialien, je Ausgangsmaterial einmal.
static var _materialien := {}


## Sollen die mitgelieferten Modelle benutzt werden?
static func aktiv() -> bool:
	return Einstellungen.fremde_modelle


## Liegt dieses Modell im Spiel?
static func hat(bezeichnung: String) -> bool:
	return ResourceLoader.exists(_pfad(bezeichnung))


## Eine Instanz des Modells, oder null. `ziel_hoehe` > 0 skaliert es auf
## diese Höhe – die Level rechnen in Metern, die Modelle in eigenen Einheiten.
static func nimm(bezeichnung: String, ziel_hoehe: float = 0.0) -> Node3D:
	if not aktiv():
		return null
	var pfad := _pfad(bezeichnung)
	var knoten := _instanz(pfad)
	if knoten == null:
		return null
	if ziel_hoehe > 0.0:
		var mass := _abmessung(pfad, knoten)
		if mass.y > 0.001:
			var faktor := ziel_hoehe / mass.y
			# Nur nach der Höhe zu skalieren geht bei flachen Modellen
			# schief: Ein liegendes Blatt ist kaum hoch, aber lang – es
			# würde zum meterbreiten Keil aufgeblasen. Deshalb die Breite
			# mitbegrenzen.
			var breite := maxf(mass.x, mass.z)
			if breite > 0.001 and breite * faktor > ziel_hoehe * 1.8:
				faktor = ziel_hoehe * 1.8 / breite
			knoten.scale = Vector3(faktor, faktor, faktor)
			# Unterkante auf den Boden setzen. Ohne das hingen Bäume in der
			# Luft oder steckten im Boden – je nachdem, wo der Ursprung der
			# Datei liegt. Der ist bei fremden Modellen nicht verlässlich.
			knoten.position.y = -_unterkante(pfad, knoten) * faktor
	_beleuchtung_anpassen(knoten)
	return knoten


## Die Kenney-Modelle bringen `KHR_materials_unlit` mit: Godot zeichnet sie
## dann unbeleuchtet. Zwischen beschatteten Bäumen und Felsen leuchten sie
## dadurch flach heraus und ignorieren Sonne wie Nebel. Hier wird jedes
## Material einmal auf normale Beleuchtung umgestellt und danach
## wiederverwendet – ein Wald hat hunderte Instanzen, aber nur eine Handvoll
## verschiedener Materialien.
static func _beleuchtung_anpassen(knoten: Node, farben: Dictionary = {}) -> void:
	var netz := knoten as MeshInstance3D
	if netz != null and netz.mesh != null:
		for i in netz.mesh.get_surface_count():
			var roh := netz.mesh.surface_get_material(i)
			var fertig := _angepasst(roh, farben)
			if fertig != null:
				netz.set_surface_override_material(i, fertig)
	for kind in knoten.get_children():
		_beleuchtung_anpassen(kind, farben)


static func _angepasst(roh: Material, farben: Dictionary = {}) -> Material:
	if roh == null:
		return null
	var wunschfarbe: Variant = farben.get(roh.resource_name)
	# ACHTUNG: Als Schlüssel diente hier einmal `get_instance_id()`. Das war
	# falsch – Godot vergibt die IDs freigegebener Objekte neu. Ein später
	# geladenes Modell bekam dadurch die Materialien eines früheren, und
	# Figuren erschienen in fremden Farben. Der Schlüssel ist jetzt der
	# Ressourcenpfad, und das Ausgangsmaterial wird mit festgehalten, damit
	# es gar nicht erst freigegeben werden kann.
	var schluessel: Variant = roh.resource_path
	if String(schluessel).is_empty():
		schluessel = roh
	if wunschfarbe != null:
		# Umgefärbte Fassungen brauchen einen eigenen Platz, sonst bekäme
		# jedes andere Modell mit demselben Material die neue Farbe.
		schluessel = "%s#%s" % [str(schluessel), Color(wunschfarbe).to_html()]
	if _materialien.has(schluessel):
		return _materialien[schluessel]["fertig"]
	var standard := roh as StandardMaterial3D
	if standard == null:
		_materialien[schluessel] = {"quelle": roh, "fertig": null}
		return null
	var neu_stoff := standard.duplicate() as StandardMaterial3D
	neu_stoff.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	# Mattes Laub und matter Fels – Glanzlichter passen nicht zum Comicstil.
	neu_stoff.roughness = 0.92
	neu_stoff.metallic = 0.0
	neu_stoff.metallic_specular = 0.12
	if wunschfarbe != null:
		neu_stoff.albedo_color = wunschfarbe
	_materialien[schluessel] = {"quelle": roh, "fertig": neu_stoff}
	return neu_stoff


## Wählt eines aus einer Liste, gesteuert vom Zufall des Props – damit ein
## Bestand abwechslungsreich wird und bei gleicher Saat gleich bleibt.
static func waehle(namen: Array, rng: RandomNumberGenerator,
		ziel_hoehe: float = 0.0) -> Node3D:
	if namen.is_empty():
		return null
	var vorhanden: Array = []
	for n in namen:
		if hat(String(n)):
			vorhanden.append(String(n))
	if vorhanden.is_empty():
		return null
	return nimm(vorhanden[rng.randi() % vorhanden.size()], ziel_hoehe)


## Ein Gegnermodell. Anders als bei Bäumen zählt hier die GRÖSSTE Achse:
## Ein Marienkäfer oder ein Frosch ist flach und lang – auf die Höhe
## eingepasst würde er meterweit über den Weg ragen.
## `nach_hoehe` bestimmt, worauf sich `ziel_groesse` bezieht. Vorgabe ist
## die größte Achse; für Gegner, unter denen man durchrutschen können muss,
## zählt dagegen die HÖHE – sonst duckt sich ein breites Tier zu flach.
## `drehung` dreht das Modell um die Y-Achse. Das Spiel erwartet Figuren,
## die nach −Z blicken; fremde Modelle schauen fast immer nach +Z und
## laufen dann rückwärts durch die Gegend.
##
## `farben` färbt einzelne Materialien um, angesprochen über ihren Namen
## aus der glTF-Datei (z. B. {"red": Color(...)}). CC0 erlaubt Änderungen –
## so wird aus einem Marienkäfer ein Panzerkäfer, ohne die gute Form zu
## verlieren.
static func gegner(bezeichnung: String, ziel_groesse: float,
		nach_hoehe: bool = false, drehung: float = 0.0,
		farben: Dictionary = {}) -> Node3D:
	if not aktiv():
		return null
	var pfad := "%s/%s.glb" % [ORDNER_GEGNER, bezeichnung]
	var knoten := _instanz(pfad)
	if knoten == null:
		return null
	var mass := _abmessung(pfad, knoten)
	var groesste := mass.y if nach_hoehe else maxf(mass.x, maxf(mass.y, mass.z))
	if groesste > 0.001 and ziel_groesse > 0.0:
		var faktor := ziel_groesse / groesste
		knoten.scale = Vector3(faktor, faktor, faktor)
		# Füße auf den Boden: die Hülle liegt selten schon auf y = 0.
		knoten.position.y = -_unterkante(pfad, knoten) * faktor
	knoten.rotation.y = drehung
	_beleuchtung_anpassen(knoten, farben)
	return knoten


static func _unterkante(pfad: String, muster: Node3D) -> float:
	var schluessel := pfad + "#unten"
	if _hoehen.has(schluessel):
		return _hoehen[schluessel]
	var u: float = ModellLader.huelle_von(muster).position.y
	_hoehen[schluessel] = u
	return u


static func _instanz(pfad: String) -> Node3D:
	if not _vorrat.has(pfad):
		_vorrat[pfad] = load(pfad) if ResourceLoader.exists(pfad) else null
	var szene: PackedScene = _vorrat[pfad]
	if szene == null:
		return null
	return szene.instantiate() as Node3D


static func _pfad(bezeichnung: String) -> String:
	return "%s/%s.glb" % [ORDNER, bezeichnung]


## Abmessungen des Modells in seinen eigenen Einheiten.
static func _abmessung(pfad: String, muster: Node3D) -> Vector3:
	if _hoehen.has(pfad):
		return _hoehen[pfad]
	var mass: Vector3 = ModellLader.huelle_von(muster).size
	_hoehen[pfad] = mass
	return mass
