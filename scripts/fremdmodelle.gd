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
## Zwei Wege, ein Modell ins Level zu bringen:
##   `nimm()` / `waehle()`  eine Instanz samt Knotenbaum (Einzelstücke, alle
##                          Level bis auf das neue Level 01).
##   `netz()`               ein verschmolzenes ArrayMesh mit höchstens drei
##                          Flächen für MultiMesh-Streuer (Level 01): Form aus
##                          der Datei, Stoff aus dem Level (`moosdecke()`).
## Gesucht wird zuerst in `natur/` (Kenney), dann in `natur2/`
## (Stilmodelle für Level 01, siehe `natur2/LIESMICH.md`). `ROLLEN` ordnet
## den Rollen M1–M18 aus dem Levelplan ihre Modelle zu.
##
## Quelle und Lizenz stehen in `assets/CREDITS.md`.

## Kenneys Palette auf unsere umgelegt, angesprochen über die
## Materialnamen aus den glTF-Dateien.
##
## Das Nature Kit ist in Minzgrün und Pfirsichbraun gehalten. Zwischen
## unserem warmen, dunklen Waldgrün lasen sich die Modelle deshalb wie
## aufgeklebt – besonders die Rahmenbäume, die aus der Schlucht
## emporwachsen und dabei groß im Bild stehen. Geometrie und Farbe sind
## bei glTF getrennt, also lässt sich genau das ändern, was stört.
##
## Blüten und Pilze behalten ihre Farben: Die sollen auffallen.
const PALETTE := {
	"leafsGreen": Farben.LAUB,
	"leafsDark": Farben.LAUB_DUNKEL,
	"grass": Farben.LAUB_HELL,
	"woodBark": Farben.RINDE,
	"woodBarkDark": Farben.RINDE_DUNKEL,
	"woodInner": Farben.RINDE_HELL,
	"dirt": Farben.FELS_HELL,
}

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
static func _beleuchtung_anpassen(knoten: Node, farben: Dictionary = {},
		stoff: Dictionary = {}) -> void:
	var netz := knoten as MeshInstance3D
	if netz != null and netz.mesh != null:
		for i in netz.mesh.get_surface_count():
			var roh := netz.mesh.surface_get_material(i)
			var fertig := _angepasst(roh, farben, stoff)
			if fertig != null:
				netz.set_surface_override_material(i, fertig)
	for kind in knoten.get_children():
		_beleuchtung_anpassen(kind, farben, stoff)


static func _angepasst(roh: Material, farben: Dictionary = {},
		stoff: Dictionary = {}) -> Material:
	if roh == null:
		return null
	var wunschfarbe: Variant = farben.get(roh.resource_name)
	if wunschfarbe == null:
		wunschfarbe = PALETTE.get(roh.resource_name)
	# Oberflächenwünsche für genau dieses Material (siehe `gegner()`).
	var wunsch: Dictionary = {}
	if stoff.has(roh.resource_name):
		wunsch = stoff[roh.resource_name] as Dictionary
	if wunsch.has("farbe"):
		wunschfarbe = wunsch["farbe"]
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
	if not wunsch.is_empty():
		# Dasselbe für Glanz und Leuchten: Ein glänzender Käferpanzer darf
		# nicht in ein anderes Modell durchsickern, das zufällig ein
		# gleichnamiges Material hat.
		schluessel = "%s#%s" % [str(schluessel), var_to_str(wunsch)]
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
	if wunsch.has("rauheit"):
		neu_stoff.roughness = float(wunsch["rauheit"])
	if wunsch.has("glanz"):
		neu_stoff.metallic_specular = float(wunsch["glanz"])
	if wunsch.has("leuchten"):
		# Leuchten in der eigenen Farbe – VOR `_struktur_geben`, das die
		# Farbe in die Textur verlegt und `albedo_color` auf Weiß stellt.
		neu_stoff.emission_enabled = true
		neu_stoff.emission = neu_stoff.albedo_color
		neu_stoff.emission_energy_multiplier = float(wunsch["leuchten"])
	_struktur_geben(neu_stoff)
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
##
## `stoff` stellt die Oberfläche einzelner Materialien ein, ebenfalls über
## den Namen: {"red": {"rauheit": 0.3, "glanz": 0.6}}. Schlüssel:
##   rauheit   roughness (Vorgabe hier matt: 0.92)
##   glanz     metallic_specular (Vorgabe 0.12)
##   leuchten  Eigenleuchten in der Materialfarbe, Stärke
##   farbe     Grundfarbe (wie `farben`)
## Nötig, weil die matte Vorgabe für Laub und Fels gedacht ist: Auf einem
## Käferpanzer sah sie aus wie Ton, und die roten Spinnenaugen blieben
## stumpf. Ohne Angabe ändert sich nichts – Bäume, Steine und Kleinzeug
## teilen diese Funktionen und bleiben matt.
static func gegner(bezeichnung: String, ziel_groesse: float,
		nach_hoehe: bool = false, drehung: float = 0.0,
		farben: Dictionary = {}, stoff: Dictionary = {}) -> Node3D:
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
	_beleuchtung_anpassen(knoten, farben, stoff)
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


## Gibt einem flachen Material Oberfläche.
##
## Die fremden Modelle bringen nur eine einzige Grundfarbe je Material mit
## und stehen deshalb als glatte Farbflächen zwischen unseren eigenen
## Props, die alle eine Rauschtextur samt Normalmap tragen. Hier bekommen
## sie dieselbe Behandlung: eine Textur aus zwei Tönen der eigenen Farbe,
## dreiachsig projiziert (die Modelle haben keine brauchbaren UVs für
## unsere Zwecke), dazu eine flache Normalmap für ein bisschen Relief.
##
## Die Saat kommt aus der Farbe. Dadurch bekommt jedes Material dieselbe
## Struktur bei jedem Start, und zwei gleichfarbige Materialien teilen sie.
static func _struktur_geben(stoff: StandardMaterial3D) -> void:
	var farbe := stoff.albedo_color
	# Sehr dunkle oder fast durchsichtige Flächen bleiben, wie sie sind –
	# dort fällt Struktur nicht auf, kostet aber Speicher.
	if farbe.a < 0.9 or farbe.get_luminance() < 0.04:
		return
	var saat := int(farbe.to_rgba32() & 0x7fffffff)
	stoff.albedo_texture = Materialbibliothek.rauschtextur(saat, 0.055,
			farbe.darkened(0.22), farbe.lightened(0.12))
	# Die Farbe steckt jetzt in der Textur; sonst würde sie doppelt wirken.
	stoff.albedo_color = Color.WHITE
	stoff.normal_enabled = true
	stoff.normal_texture = Materialbibliothek.normalmap(saat, 0.055, 1.4)
	stoff.normal_scale = 0.6
	stoff.uv1_triplanar = true
	stoff.uv1_scale = Vector3(0.55, 0.55, 0.55)


## Pfad eines Modells. Kenney (`natur/`) hat Vorrang, damit alle Level, die
## Kenney-Namen verlangen, genau dasselbe bekommen wie bisher; erst was es
## dort nicht gibt, wird in `natur2/` gesucht.
static func _pfad(bezeichnung: String) -> String:
	var kenney := "%s/%s.glb" % [ORDNER, bezeichnung]
	if ResourceLoader.exists(kenney):
		return kenney
	var zweit := _pfad_natur2(bezeichnung)
	return kenney if zweit.is_empty() else zweit


## Abmessungen des Modells in seinen eigenen Einheiten.
static func _abmessung(pfad: String, muster: Node3D) -> Vector3:
	if _hoehen.has(pfad):
		return _hoehen[pfad]
	var mass: Vector3 = ModellLader.huelle_von(muster).size
	_hoehen[pfad] = mass
	return mass


# ================================================================ natur2 und netz()
#
# Für MultiMesh-Streuer (Level 01): Jedes Modell wird zu EINEM ArrayMesh
# verschmolzen – alle Knoten mit eingebackener Lage, die Flächen nach Art
# gruppiert (hart, Laub, Akzent), höchstens drei. Der Stoff kommt aus dem
# Level: harte Flächen tragen `moosdecke()`, Laub `laubstoff()`. Beide sind
# beleuchtet, egal was die Datei mitbringt (Kenney und viele
# Quaternius-Dateien sind unbeleuchtet oder einfarbig).

## Zweiter Modellordner: Stilmodelle für Level 01, je Paket ein Unterordner.
const ORDNER_NATUR2 := "res://assets/modelle/natur2"
## Reihenfolge, in der gleichnamige Modelle aus verschiedenen Paketen
## gewählt werden, wenn nur der nackte Name verlangt ist.
const PAKETE_NATUR2 := ["megakit", "unp", "kenney"]

## Farben für `netz()`, angesprochen über die Materialnamen (Kenney).
## Anders als `PALETTE` (für `nimm()`; bleibt unverändert, damit die
## anderen Level pixelgleich bleiben) sind es die Farben des Waldbodens von
## Level 01: Fels grau statt hell, Gras satt, Blüten gedeckter.
const NETZ_FARBEN := {
	"leafsGreen": Farben.LAUB,
	"leafsDark": Farben.LAUB_DUNKEL,
	"grass": Farben.GRAS,
	"woodBark": Color(0.36, 0.28, 0.20),
	"woodBarkDark": Color(0.25, 0.19, 0.14),
	"woodInner": Farben.RINDE_HELL,
	"dirt": Color(0.58, 0.54, 0.46),
	"colorRed": Color(0.74, 0.22, 0.20),
	"colorYellow": Color(0.93, 0.70, 0.24),
	"colorPurple": Color(0.52, 0.40, 0.80),
	"colorTan": Color(0.80, 0.56, 0.34),
}

## Die Rollen aus dem Levelplan (Level 01, Abschnitt 9) und welche Modelle
## sie tragen dürfen, in drei Stufen: `primaer` (Stylized Nature MegaKit),
## `ersatz` (Ultimate Nature Pack bzw. das volle Kenney-Paket) und `kenney`
## (liegt schon im Spiel). Die erste Stufe, von der etwas vorhanden ist,
## gewinnt – so mischen sich innerhalb einer Rolle nicht zwei Stile. Ist
## keine vorhanden, liefert `rolle()` nichts, und der Aufrufer baut den
## prozeduralen Rückfall. `hoehe` ist die typische Höhe in Metern (bzw.
## `groesse` die größte Achse, für Liegendes), `optionen` sind die
## Vorgaben für `netz()`. Die Namen stammen aus dem Plan
## und sind nach dem Herunterladen zu prüfen (natur2/LIESMICH.md).
const ROLLEN := {
	"M1": {"name": "Hallen- und Hangbäume", "hoehe": 15.0,
		"primaer": ["megakit/CommonTree_1", "megakit/CommonTree_2", "megakit/CommonTree_3",
			"megakit/CommonTree_4", "megakit/CommonTree_5", "megakit/Pine_1",
			"megakit/Pine_2", "megakit/Pine_3"],
		"ersatz": ["unp/CommonTree_1", "unp/CommonTree_2", "unp/CommonTree_3",
			"unp/PineTree_1", "unp/PineTree_2", "unp/PineTree_3"],
		"kenney": [],
		"optionen": {"wind": 0.08}},
	"M2": {"name": "Rahmenbäume", "hoehe": 12.0,
		"primaer": ["megakit/TwistedTree_1", "megakit/TwistedTree_3"],
		"ersatz": [], "kenney": [],
		"optionen": {"wind": 0.06}},
	"M3": {"name": "Talwald nah", "hoehe": 9.0,
		"primaer": ["megakit/CommonTree_1", "megakit/CommonTree_2", "megakit/CommonTree_3",
			"megakit/CommonTree_4", "megakit/CommonTree_5"],
		"ersatz": ["unp/CommonTree_1", "unp/CommonTree_2", "unp/BirchTree_1",
			"unp/BirchTree_2"],
		"kenney": [],
		"optionen": {}},
	"M7": {"name": "Konsolenpilze", "hoehe": 0.4,
		"primaer": ["megakit/Mushroom_Laetiporus"], "ersatz": [], "kenney": [],
		"optionen": {}},
	"M8": {"name": "Felsen, Findlinge (Deko)", "groesse": 2.4,
		"primaer": ["megakit/Rock_Medium_1", "megakit/Rock_Medium_2", "megakit/Rock_Medium_3"],
		"ersatz": [],
		"kenney": ["rock_largeA", "rock_largeB", "rock_largeC"],
		"optionen": {"moos": 0.42, "formen": 2, "max_dreiecke": 700}},
	"M9": {"name": "Kiesel", "groesse": 0.32,
		"primaer": ["megakit/Pebble_Round_1", "megakit/Pebble_Round_2",
			"megakit/Pebble_Square_1", "megakit/Pebble_Square_2"],
		"ersatz": [],
		"kenney": ["rock_smallA", "rock_smallB", "rock_smallC", "rock_smallFlatA",
			"rock_smallFlatB"],
		"optionen": {"moos": 0.25, "formen": 1, "zerklueftung": 0.1}},
	"M10": {"name": "Trittsteine, Schwellen (Optik)", "groesse": 1.0,
		"primaer": ["megakit/RockPath_Round_Wide"], "ersatz": [], "kenney": [],
		"optionen": {"moos": 0.3, "formen": 1, "woelbung": 0.05}},
	"M11": {"name": "Büsche, Hecken", "hoehe": 1.3,
		"primaer": ["megakit/Bush_Common", "megakit/Bush_Common_Flowers"],
		"ersatz": [],
		"kenney": ["plant_bush", "plant_bushDetailed", "plant_bushSmall"],
		"optionen": {"wind": 0.03}},
	"M12": {"name": "Farne", "hoehe": 1.1,
		"primaer": ["megakit/Fern_1"], "ersatz": [], "kenney": [],
		"optionen": {"wind": 0.03}},
	"M13": {"name": "Großblattpflanzen", "hoehe": 1.3,
		"primaer": ["megakit/Plant_1", "megakit/Plant_7"], "ersatz": [], "kenney": [],
		"optionen": {"wind": 0.03}},
	"M14": {"name": "Blumen, Klee", "hoehe": 0.35,
		"primaer": ["megakit/Flower_3_Group", "megakit/Flower_4_Group",
			"megakit/Clover_1", "megakit/Clover_2"],
		"ersatz": [],
		"kenney": ["flower_redA", "flower_yellowA", "flower_purpleA"],
		"optionen": {"wind": 0.02, "umriss": 0.0}},
	"M15": {"name": "Gras-Akzente", "hoehe": 0.5,
		"primaer": ["megakit/Grass_Wispy_Tall", "megakit/Grass_Wispy_Short"],
		"ersatz": [], "kenney": [],
		"optionen": {"wind": 0.04, "umriss": 0.0}},
	"M16": {"name": "Moosstämme, Stümpfe", "groesse": 2.4,
		"primaer": ["unp/WoodLog_Moss", "unp/TreeStump_Moss"],
		"ersatz": ["stump_old", "stump_round"],
		"kenney": ["log_large"],
		"optionen": {"moos": 0.5, "formen": 2, "zerklueftung": 0.025, "woelbung": 0.0,
			"runden": 1.0, "max_dreiecke": 600}},
	"M17": {"name": "Totholz", "hoehe": 8.0,
		"primaer": ["megakit/DeadTree_1", "megakit/DeadTree_2"], "ersatz": [], "kenney": [],
		"optionen": {"moos": 0.3}},
	"M18": {"name": "Pilze", "hoehe": 0.3,
		"primaer": ["megakit/Mushroom_Common"], "ersatz": [],
		"kenney": ["mushroom_red", "mushroom_redGroup", "mushroom_tan", "mushroom_tanGroup"],
		"optionen": {}},
}

## Welche Materialklasse zu welcher Fläche gehört. Harte Flächen werfen
## Schatten, Laub und Akzente nicht (Plan, Abschnitt 13).
const _ART := {
	"fels": "hart", "borke": "hart", "holz": "hart", "moos": "hart",
	"laub": "laub", "bluete": "akzent", "pilz": "akzent",
}
## Stichwörter in Materialnamen, in dieser Reihenfolge geprüft („woodInner"
## ist Schnittholz, nicht Borke).
const _WOERTER := [
	["holz", ["inner", "cut", "schnitt"]],
	["borke", ["bark", "wood", "trunk", "log", "stump", "branch", "twig", "rinde",
		"stamm", "holz"]],
	["fels", ["rock", "stone", "dirt", "pebble", "path", "cliff", "boulder", "gravel",
		"fels", "stein"]],
	["pilz", ["mushroom", "fungus", "laetiporus", "pilz"]],
	["bluete", ["flower", "petal", "blossom", "color", "bluete", "blume"]],
	["laub", ["leaf", "leaves", "grass", "bush", "fern", "clover", "plant", "needle",
		"moss", "ivy", "foliage", "canopy", "hedge", "laub", "gras", "farn", "klee",
		"nadel", "moos"]],
]

static var _natur2_index := {}
static var _natur2_liste := PackedStringArray()
static var _natur2_gelesen := false
static var _netze := {}
static var _shader := {}
static var _netz_stoffe := {}
static var _moos_bild: ImageTexture = null
static var _lod_gewarnt := false


## Die vorhandenen Modelle einer Rolle (siehe `ROLLEN`), nur aus der
## besten Stufe, von der etwas da ist. Leer: prozeduraler Rückfall.
static func rolle(kennung: String) -> PackedStringArray:
	var liste := PackedStringArray()
	if not aktiv() or not ROLLEN.has(kennung):
		return liste
	var eintrag: Dictionary = ROLLEN[kennung]
	for stufe: String in ["primaer", "ersatz", "kenney"]:
		var namen: Array = eintrag.get(stufe, [])
		for n: Variant in namen:
			if hat(String(n)):
				liste.append(String(n))
		if not liste.is_empty():
			return liste
	return liste


## Die Vorgaben einer Rolle für `netz()`: typische Höhe und Stoffwünsche.
## `dazu` überschreibt einzelne Werte.
static func rolle_optionen(kennung: String, dazu: Dictionary = {}) -> Dictionary:
	var optionen := {}
	if ROLLEN.has(kennung):
		var eintrag: Dictionary = ROLLEN[kennung]
		# Liegendes und Breites (Felsen, Kiesel, Stämme) nach der größten
		# Achse, Stehendes nach der Höhe: Ein flacher Kenney-Felsen auf
		# 1,6 m Höhe gebracht wäre sechs Meter breit.
		if eintrag.has("groesse"):
			optionen["groesse"] = float(eintrag["groesse"])
		else:
			optionen["hoehe"] = float(eintrag.get("hoehe", 0.0))
		var vorgaben: Dictionary = eintrag.get("optionen", {})
		optionen.merge(vorgaben, true)
	optionen.merge(dazu, true)
	return optionen


## Alle Netze einer Rolle mit ihren Vorgaben – leer, wenn die Rolle auf
## den Rückfall angewiesen ist.
static func rolle_netze(kennung: String, dazu: Dictionary = {}) -> Array[Dictionary]:
	var netze: Array[Dictionary] = []
	var optionen := rolle_optionen(kennung, dazu)
	for n in rolle(kennung):
		var fertig := netz(n, optionen)
		if not fertig.is_empty():
			netze.append(fertig)
	return netze


## Ein Modell als verschmolzenes Netz für MultiMesh-Streuer.
##
## Rückgabe (leer, wenn das Modell fehlt oder `aktiv()` aus ist):
##   mesh         ArrayMesh, alle Flächen samt Material, höchstens drei
##   huelle       AABB in Netzeinheiten (mit `hoehe`/`groesse` in Metern)
##   krone_unten  Unterkante des Laubs (Y relativ zum Fuß); ohne Laub die
##                Oberkante der Hülle. Für die Kamera-Freiheit (K1).
##   flaechen     je Fläche {art "hart"|"laub"|"akzent", material, mesh (nur
##                diese Fläche – für ein eigenes MultiMesh), schatten,
##                dreiecke, index}
##   dreiecke     Summe
##   massstab     angewandter Faktor auf die Datei
##
## Optionen (alle freiwillig):
##   hoehe        auf diese Höhe skalieren (Meter). Empfohlen: die typische
##                Höhe der Rolle, dann je Instanz 0,7–1,4 skalieren – so
##                stimmen Musterkachel und Moos auf allen Instanzen.
##   groesse      statt `hoehe`: die größte Achse auf diesen Wert
##   boden        Fuß auf y = 0 (Vorgabe an)
##   mitte        waagerecht auf den Ursprung mitteln (Vorgabe aus)
##   toenung      Color, auf alle Scheitelfarben multipliziert
##   laub_toenung / hart_toenung   nur auf Laub bzw. harte Flächen
##   farben       {Materialname: Color} statt der Palette
##   moos         0–1 Moosmenge auf harten Flächen (Vorgabe je Stoff)
##   glaetten     0–1 Normalen der harten Flächen glätten (Vorgabe je Stoff)
##   formen       0–3 harte Flächen so oft vierteln und nachformen: Rauschen
##                und gewölbte Oberseite, aus Tischplatten werden Findlinge
##                (Vorgabe 0 = Form der Datei). Mal 4 Dreiecke je Stufe –
##                mit `max_dreiecke` wieder ausdünnen. Bei
##                `Effekte.reduziert` eine Stufe weniger.
##   zerklueftung Rauschausschlag beim Formen, Anteil der größten Achse (0,07)
##   woelbung     Wölbung der Oberseite beim Formen, Anteil der Höhe (0,12)
##   runden       0–1 beim Formen um die längste Achse runden (Stämme)
##   laub_biegen  0–1 Laubnormalen zur Kronenaußenseite (Vorgabe 0,55)
##   laub_tiefe   0–1 Verdeckung im Kroneninneren (Vorgabe 1)
##   umriss       0–1 Laubumriss in Blätter brechen (Vorgabe 0,55; aus bei
##                `Effekte.reduziert`, weil Verwerfen auf Handys teuer ist)
##   wind         Ausschlag des Laubs an der Spitze in Metern (Vorgabe 0)
##   max_dreiecke höchstens so viele Dreiecke (über Godots LOD-Vereinfachung)
##
## Die Rückgabe wird zwischengespeichert und geteilt: nie verändern.
static func netz(bezeichnung: String, optionen: Dictionary = {}) -> Dictionary:
	if not aktiv():
		return {}
	var pfad := _pfad(bezeichnung)
	if not ResourceLoader.exists(pfad):
		return {}
	var schluessel := "%s|%s|%s" % [pfad, var_to_str(optionen), str(Effekte.reduziert)]
	if _netze.has(schluessel):
		return _netze[schluessel]
	var knoten := _instanz(pfad)
	var fertig := {}
	if knoten != null:
		fertig = netz_aus(knoten, optionen, bezeichnung)
		knoten.free()
	_netze[schluessel] = fertig
	return fertig


## Wie `netz()`, aber aus einem schon vorhandenen Knotenbaum (etwa einer
## zur Laufzeit gelesenen Datei oder einem Prüfmodell). Der Baum bleibt
## unverändert, das Ergebnis wird nicht zwischengespeichert.
static func netz_aus(wurzel: Node, optionen: Dictionary = {},
		bezeichnung: String = "") -> Dictionary:
	var teile: Array[Dictionary] = []
	_teile_sammeln(wurzel, Transform3D.IDENTITY, teile)
	if teile.is_empty():
		return {}
	var modell := bezeichnung.to_lower()
	var ist_pilz := modell.contains("mushroom") or modell.contains("pilz")
	var hat_fels := false
	for teil in teile:
		var info := _stoff_lesen(teil["stoff"] as Material, optionen)
		if ist_pilz and String(info["klasse"]) != "laub":
			info["klasse"] = "pilz"
		teil["info"] = info
		hat_fels = hat_fels or String(info["klasse"]) == "fels"
	var eigene: Dictionary = optionen.get("farben", {})
	for teil in teile:
		var info: Dictionary = teil["info"]
		var klasse := String(info["klasse"])
		var roh: Texture2D = info["textur"]
		# Kenney legt Felsen einen Grasdeckel auf. Im Wald wird daraus Moos –
		# derselbe Stoff wie auf allen anderen Steinen und Stämmen.
		if hat_fels and klasse == "laub" and roh == null:
			info["klasse"] = "moos"
			info["farbe"] = NETZ_FARBEN["dirt"]
		elif klasse == "unbestimmt":
			# Kenneys `_defaultMat` ist weiß und gehört zu dem, was es umgibt.
			if ist_pilz:
				info["klasse"] = "pilz"
				info["farbe"] = Color(0.86, 0.80, 0.68)
			elif hat_fels:
				info["klasse"] = "fels"
				info["farbe"] = Farben.FELS
			else:
				info["klasse"] = "borke"
				info["farbe"] = Farben.RINDE
		if not eigene.has(String(info["name"])):
			var ton: Color = optionen.get("toenung", Color.WHITE)
			var art := String(_ART[String(info["klasse"])])
			if art == "laub":
				ton *= optionen.get("laub_toenung", Color.WHITE) as Color
			elif art == "hart":
				ton *= optionen.get("hart_toenung", Color.WHITE) as Color
			info["farbe"] = (info["farbe"] as Color) * ton

	# Gruppieren: harte Flächen, Laub, Akzente – je Textur eine eigene
	# Fläche. Akzente ohne Textur (Blütenblätter, Pilzhüte) reisen im Laub
	# mit und behalten dort ihre Farbe; so bleibt eine Blume EIN Netz.
	var gruppen := {}
	var reihenfolge: Array[String] = []
	for teil in teile:
		var info: Dictionary = teil["info"]
		var art := String(_ART[String(info["klasse"])])
		var textur: Texture2D = info["textur"]
		if art == "akzent" and textur == null:
			art = "laub"
		var schluessel := art if textur == null \
				else "%s#%d" % [art, textur.get_instance_id()]
		if not gruppen.has(schluessel):
			gruppen[schluessel] = _neue_gruppe(art, textur, float(info["schnitt"]))
			reihenfolge.append(schluessel)
		_teil_anhaengen(gruppen[schluessel], teil)
	reihenfolge.sort_custom(func(a: String, b: String) -> bool:
		return _rang(a) < _rang(b))
	if reihenfolge.size() > 3:
		push_warning("Fremdmodelle.netz: %s hat %d Flächen (mehr als drei)"
				% [bezeichnung, reihenfolge.size()])

	# Form, Normalen und Verdeckung, noch in den Einheiten der Datei.
	for s in reihenfolge:
		var g: Dictionary = gruppen[s]
		if String(g["art"]) == "hart":
			var vorgabe := 0.2
			match _vorherrschend(g):
				"fels":
					vorgabe = 0.35
				"borke", "moos":
					vorgabe = 0.5
			var stufen := int(optionen.get("formen", 0))
			# Browser und Handy: eine Stufe weniger. Dort fehlt womöglich auch
			# das Ausdünnen (meshoptimizer), dann bleibt es bei einem Viertel.
			if Effekte.reduziert and stufen > 1:
				stufen -= 1
			if stufen > 0:
				_formen(g, mini(stufen, 3), float(optionen.get("zerklueftung", 0.07)),
						float(optionen.get("woelbung", 0.12)), float(optionen.get("runden", 0.0)),
						bezeichnung.hash())
				vorgabe = maxf(vorgabe, 0.7)
			_glaetten(g, float(optionen.get("glaetten", vorgabe)))
			if stufen > 0:
				_verschweissen(g)
		else:
			_laub_formen(g, float(optionen.get("laub_biegen", 0.55)),
					float(optionen.get("laub_tiefe", 1.0)))

	# Maßstab und Fuß.
	var huelle := _gruppen_huelle(gruppen, reihenfolge)
	var faktor := 1.0
	var ziel_hoehe := float(optionen.get("hoehe", 0.0))
	var ziel_groesse := float(optionen.get("groesse", 0.0))
	var groesste := maxf(huelle.size.x, maxf(huelle.size.y, huelle.size.z))
	if ziel_hoehe > 0.0 and huelle.size.y > 0.0001:
		faktor = ziel_hoehe / huelle.size.y
	elif ziel_groesse > 0.0 and groesste > 0.0001:
		faktor = ziel_groesse / groesste
	var versatz := Vector3.ZERO
	if bool(optionen.get("boden", true)):
		versatz.y = -huelle.position.y * faktor
	if bool(optionen.get("mitte", false)):
		versatz.x = -huelle.get_center().x * faktor
		versatz.z = -huelle.get_center().z * faktor
	for s in reihenfolge:
		var g: Dictionary = gruppen[s]
		var v: PackedVector3Array = g["v"]
		for k in v.size():
			v[k] = v[k] * faktor + versatz
		g["v"] = v

	var grenze := int(optionen.get("max_dreiecke", 0))
	if grenze > 0:
		_vereinfachen(gruppen, reihenfolge, grenze)

	huelle = _gruppen_huelle(gruppen, reihenfolge)
	var gesamt := ArrayMesh.new()
	var flaechen: Array[Dictionary] = []
	var dreiecke := 0
	var krone_unten := INF
	for s in reihenfolge:
		var g: Dictionary = gruppen[s]
		var arrays := _gruppe_arrays(g)
		var stoff := _gruppe_stoff(g, optionen, huelle)
		var art := String(g["art"])
		var klassen: Dictionary = g["klassen"]
		if art == "laub" and not klassen.has("laub"):
			art = "akzent"
		gesamt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var index := gesamt.get_surface_count() - 1
		gesamt.surface_set_material(index, stoff)
		gesamt.surface_set_name(index, art)
		var einzeln := ArrayMesh.new()
		einzeln.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		einzeln.surface_set_material(0, stoff)
		einzeln.surface_set_name(0, art)
		var i: PackedInt32Array = g["i"]
		dreiecke += i.size() / 3
		flaechen.append({"art": art, "material": stoff, "mesh": einzeln,
			"schatten": art == "hart", "dreiecke": i.size() / 3, "index": index})
		if art == "laub":
			krone_unten = minf(krone_unten, _laub_unterkante(g))
	if krone_unten == INF:
		krone_unten = huelle.end.y
	return {
		"name": bezeichnung,
		"mesh": gesamt,
		"huelle": huelle,
		"krone_unten": krone_unten,
		"flaechen": flaechen,
		"dreiecke": dreiecke,
		"massstab": faktor,
	}


## Stoff für harte Flächen fremder und eigener Modelle: Fels, Borke,
## Stümpfe und Stämme. Das Muster liegt im Objektraum (es klebt am Netz,
## auch in einem MultiMesh), das Moos in Weltlage: Es wächst, wo die Fläche
## nach oben zeigt, und ein Rauschen in Weltkoordinaten macht jeden Stein
## anders, obwohl alle dasselbe Netz teilen. So lesen sich Kenney und
## Quaternius als eine Familie. Dazu ein dunkler Fuß (der Stein sitzt im
## Boden, statt aufzuliegen) und Relief aus dem Muster, ohne Tangenten.
##
## Die Grundfarbe kommt aus den Scheitelfarben (Palette und Tönung, je
## MultiMesh-Instanz zusätzlich deren Farbe). Optionen:
##   stoff        "fels" | "borke" – Muster aus der Materialbibliothek
##   grund        Texture2D statt des Musters
##   grund_ist_farbe  `grund` ist die echte Albedo über UV (texturierte Pakete)
##   kachel       Meter je Musterkachel (Vorgabe fels 2,0 / borke 1,0)
##   moos         0–1 Moosmenge (Vorgabe 0,45)
##   moos_ton     Color auf die Moosfarbe
##   toenung      Color auf alles
##   fuss         Höhe des dunklen Fußes in Netzeinheiten (Vorgabe 0,3)
##   fuss_dunkel  0–1 (Vorgabe 0,3)
##   relief       Stärke des Reliefs (Vorgabe 0,8)
##   lage         Basis, die das Muster dreht (liegende Stämme: Furchen längs)
##   ueberlage    true: nur das Moos, als `next_pass` über ein bestehendes
##                Material zu legen (eine Zeichnung mehr, durchsichtig)
## Das Ergebnis wird zwischengespeichert und geteilt: nie verändern.
static func moosdecke(optionen: Dictionary = {}) -> ShaderMaterial:
	var grund_roh: Variant = optionen.get("grund")
	var schluessel := "moos|" + _stoff_schluessel(optionen)
	if _netz_stoffe.has(schluessel):
		return (_netz_stoffe[schluessel] as Dictionary)["fertig"]
	var ueberlage := bool(optionen.get("ueberlage", false))
	var stoff := ShaderMaterial.new()
	stoff.shader = _hol_shader("ueberlage" if ueberlage else "hart")
	stoff.set_shader_parameter("moos_textur", _moos_textur())
	stoff.set_shader_parameter("moos_menge", float(optionen.get("moos", 0.45)))
	stoff.set_shader_parameter("moos_ton", optionen.get("moos_ton", Color.WHITE) as Color)
	if not ueberlage:
		var art := String(optionen.get("stoff", "fels"))
		var grund: Texture2D = null
		if grund_roh is Texture2D:
			grund = grund_roh
		elif art == "borke":
			grund = Materialbibliothek.rinde().albedo_texture
		else:
			grund = Materialbibliothek.fels().albedo_texture
		stoff.set_shader_parameter("grund", grund)
		stoff.set_shader_parameter("grund_ist_farbe",
				bool(optionen.get("grund_ist_farbe", false)))
		stoff.set_shader_parameter("kachel",
				float(optionen.get("kachel", 1.0 if art == "borke" else 2.0)))
		stoff.set_shader_parameter("toenung", optionen.get("toenung", Color.WHITE) as Color)
		stoff.set_shader_parameter("fuss", float(optionen.get("fuss", 0.3)))
		stoff.set_shader_parameter("fuss_dunkel", float(optionen.get("fuss_dunkel", 0.3)))
		stoff.set_shader_parameter("relief", float(optionen.get("relief", 0.8)))
		stoff.set_shader_parameter("lage", optionen.get("lage", Basis.IDENTITY) as Basis)
	# Die Ausgangstextur mit festhalten (siehe `_angepasst`): Der Schlüssel
	# trägt ihre Kennung, und die darf nicht an eine andere vergeben werden.
	_netz_stoffe[schluessel] = {"quelle": grund_roh, "fertig": stoff}
	return stoff


## Der Laubstoff von `netz()`: beidseitig, weiches Licht mit Durchschein,
## Muster aus der Materialbibliothek (oder die Textur der Datei), am Umriss
## in Blätter gebrochen, freiwillig mit Wind im Scheitelshader (bewegt
## keine Knoten, braucht also keine Ausnahme von der Physikinterpolation).
## Optionen: grund, grund_ist_farbe, schnitt (Alphaschwelle der Textur),
## kachel, toenung, umriss, wind, hoehe (Netzhöhe für den Wind), durchlicht.
## Das Ergebnis wird zwischengespeichert und geteilt: nie verändern.
static func laubstoff(optionen: Dictionary = {}) -> ShaderMaterial:
	var grund_roh: Variant = optionen.get("grund")
	var schluessel := "laub|" + _stoff_schluessel(optionen)
	if _netz_stoffe.has(schluessel):
		return (_netz_stoffe[schluessel] as Dictionary)["fertig"]
	var schnitt := float(optionen.get("schnitt", 0.0))
	var umriss := float(optionen.get("umriss", 0.0))
	var grund: Texture2D = null
	var ist_farbe := false
	if grund_roh is Texture2D:
		grund = grund_roh
		ist_farbe = bool(optionen.get("grund_ist_farbe", true))
	else:
		grund = Materialbibliothek.laub().albedo_texture
	var stoff := ShaderMaterial.new()
	# Verwerfen nur, wo es etwas zu verwerfen gibt: Ohne Alpha und ohne
	# Umrissbruch bleibt der Stoff undurchsichtig und billig.
	var mit_schnitt := (ist_farbe and schnitt > 0.0) or (not ist_farbe and umriss > 0.0)
	stoff.shader = _hol_shader("laub_schnitt" if mit_schnitt else "laub")
	stoff.set_shader_parameter("grund", grund)
	stoff.set_shader_parameter("grund_ist_farbe", ist_farbe)
	stoff.set_shader_parameter("kachel", float(optionen.get("kachel", 0.7)))
	stoff.set_shader_parameter("toenung", optionen.get("toenung", Color.WHITE) as Color)
	stoff.set_shader_parameter("umriss", 0.0 if ist_farbe else umriss)
	stoff.set_shader_parameter("schnitt", schnitt if ist_farbe else 0.5)
	stoff.set_shader_parameter("wind", float(optionen.get("wind", 0.0)))
	stoff.set_shader_parameter("hoehe", maxf(float(optionen.get("hoehe", 1.0)), 0.01))
	stoff.set_shader_parameter("durchlicht", float(optionen.get("durchlicht", 0.3)))
	_netz_stoffe[schluessel] = {"quelle": grund_roh, "fertig": stoff}
	return stoff


# ---------------------------------------------------------------- Innereien

## Schlüssel für den Stoffvorrat. Die Textur geht nur mit ihrer Kennung ein:
## `var_to_str` schriebe sie samt Bilddaten aus.
static func _stoff_schluessel(optionen: Dictionary) -> String:
	var ohne := optionen.duplicate()
	var grund: Variant = ohne.get("grund")
	ohne.erase("grund")
	var schluessel := var_to_str(ohne)
	if grund is Texture2D:
		schluessel += "#%d" % (grund as Texture2D).get_instance_id()
	return schluessel

## Alle Modelle in natur2, als „paket/Name" (liegen sie direkt im Ordner:
## nur „Name"). Für die Modellschau und für Prüfungen.
static func natur2_modelle() -> PackedStringArray:
	if not _natur2_gelesen:
		_natur2_lesen()
	return _natur2_liste.duplicate()


static func _pfad_natur2(bezeichnung: String) -> String:
	if not _natur2_gelesen:
		_natur2_lesen()
	return String(_natur2_index.get(bezeichnung, ""))


## Liest natur2 einmal ein: „paket/Name" und, nach `PAKETE_NATUR2`, der
## nackte Name. Im Export liegen dort nur noch die `.import`-Einträge;
## deren Pfad ohne Endung lädt Godot trotzdem.
static func _natur2_lesen() -> void:
	_natur2_gelesen = true
	var ordner := DirAccess.open(ORDNER_NATUR2)
	if ordner == null:
		return
	var pakete: Array[String] = [""]
	for p: String in PAKETE_NATUR2:
		pakete.append(p)
	for unter in ordner.get_directories():
		if not pakete.has(unter):
			pakete.append(unter)
	for paket in pakete:
		var pfad := ORDNER_NATUR2 if paket.is_empty() else ORDNER_NATUR2.path_join(paket)
		var liste := DirAccess.open(pfad)
		if liste == null:
			continue
		for datei in liste.get_files():
			var sauber := datei.trim_suffix(".import").trim_suffix(".remap")
			if not (sauber.get_extension().to_lower() in ["glb", "gltf"]):
				continue
			var name := sauber.get_basename()
			var voll := pfad.path_join(sauber)
			if not paket.is_empty():
				_natur2_index["%s/%s" % [paket, name]] = voll
			if not _natur2_index.has(name):
				_natur2_index[name] = voll
			var eintrag := name if paket.is_empty() else "%s/%s" % [paket, name]
			if not _natur2_liste.has(eintrag):
				_natur2_liste.append(eintrag)


## Sammelt alle sichtbaren Dreiecksflächen samt Lage relativ zur Wurzel.
static func _teile_sammeln(knoten: Node, bis_hier: Transform3D,
		teile: Array[Dictionary]) -> void:
	var mi := knoten as MeshInstance3D
	if mi != null and mi.mesh != null and mi.visible:
		var am := mi.mesh as ArrayMesh
		for i in mi.mesh.get_surface_count():
			if am != null and am.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var stoff: Material = mi.material_override
			if stoff == null:
				stoff = mi.get_surface_override_material(i)
			if stoff == null:
				stoff = mi.mesh.surface_get_material(i)
			teile.append({"arrays": mi.mesh.surface_get_arrays(i), "form": bis_hier,
				"stoff": stoff})
	for kind in knoten.get_children():
		var raum := kind as Node3D
		if raum != null and not raum.visible:
			continue
		var weiter := bis_hier * raum.transform if raum != null else bis_hier
		_teile_sammeln(kind, weiter, teile)


## Liest aus einem Material, was `netz()` braucht. Unbeleuchtet oder nicht:
## Übernommen werden nur Farbe, Textur und Alphaschnitt – der Stoff wird
## ohnehin neu gebaut, beleuchtet.
static func _stoff_lesen(stoff: Material, optionen: Dictionary) -> Dictionary:
	var name := ""
	if stoff != null:
		name = stoff.resource_name
	var farbe := Color(0.62, 0.62, 0.62)
	var textur: Texture2D = null
	var schnitt := 0.0
	var scheitelfarbe := false
	var basis := stoff as BaseMaterial3D
	if basis != null:
		farbe = basis.albedo_color
		textur = basis.albedo_texture
		scheitelfarbe = basis.vertex_color_use_as_albedo
		if basis.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			schnitt = basis.alpha_scissor_threshold
		elif basis.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and textur != null:
			schnitt = 0.5
	elif stoff is ShaderMaterial:
		# Einen fremden Shader kann niemand lesen; die üblichen Namen der
		# Hauptfarbe schon. Sonst bleibt es beim neutralen Grau – nie rosa.
		var sm := stoff as ShaderMaterial
		var f: Variant = sm.get_shader_parameter("albedo")
		if f is Color:
			farbe = f
		var t: Variant = sm.get_shader_parameter("texture_albedo")
		if t is Texture2D:
			textur = t
	var klasse := _klasse(name.to_lower(), farbe)
	var eigene: Dictionary = optionen.get("farben", {})
	if eigene.has(name):
		farbe = eigene[name]
	elif textur == null and NETZ_FARBEN.has(name):
		farbe = NETZ_FARBEN[name]
	farbe.a = 1.0
	return {"name": name, "klasse": klasse, "farbe": farbe, "textur": textur,
		"schnitt": schnitt, "scheitelfarbe": scheitelfarbe}


static func _klasse(name: String, farbe: Color) -> String:
	if name.begins_with("_defaultmat"):
		return "unbestimmt"
	for eintrag: Array in _WOERTER:
		var woerter: Array = eintrag[1]
		for wort: Variant in woerter:
			if name.contains(String(wort)):
				return String(eintrag[0])
	# Kein Stichwort: nach der Farbe. Grün ist Laub, Graues Fels, der Rest Holz.
	if farbe.g > farbe.r * 1.08 and farbe.g > farbe.b:
		return "laub"
	if farbe.s < 0.22:
		return "fels"
	return "borke"


static func _neue_gruppe(art: String, textur: Texture2D, schnitt: float) -> Dictionary:
	return {"art": art, "textur": textur, "schnitt": schnitt,
		"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(),
		"uv": PackedVector2Array(), "uv2": PackedVector2Array(), "i": PackedInt32Array(),
		"klassen": {}}


## Harte Flächen zuerst, dann Laub, dann Akzente.
static func _rang(schluessel: String) -> int:
	if schluessel.begins_with("hart"):
		return 0
	if schluessel.begins_with("laub"):
		return 1
	return 2


## Hängt eine Fläche an eine Gruppe an, mit eingebackener Lage.
## UV2 trägt je Scheitel zwei Merkmale für die Stoffe: x = schlicht (1:
## Farbe ohne Muster – Schnittholz, Blütenblätter, Pilze), y = Moos
## erzwungen (Kenneys Grasdeckel auf Felsen).
static func _teil_anhaengen(g: Dictionary, teil: Dictionary) -> void:
	var arrays: Array = teil["arrays"]
	var form: Transform3D = teil["form"]
	var info: Dictionary = teil["info"]
	var roh_v: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not (roh_v is PackedVector3Array):
		return
	var quelle_v: PackedVector3Array = roh_v
	var quelle_n := PackedVector3Array()
	var roh_n: Variant = arrays[Mesh.ARRAY_NORMAL]
	if roh_n is PackedVector3Array:
		quelle_n = roh_n
	var quelle_uv := PackedVector2Array()
	var roh_uv: Variant = arrays[Mesh.ARRAY_TEX_UV]
	if roh_uv is PackedVector2Array:
		quelle_uv = roh_uv
	var quelle_c := PackedColorArray()
	var roh_c: Variant = arrays[Mesh.ARRAY_COLOR]
	if roh_c is PackedColorArray and bool(info["scheitelfarbe"]):
		quelle_c = roh_c
	var quelle_i := PackedInt32Array()
	var roh_i: Variant = arrays[Mesh.ARRAY_INDEX]
	if roh_i is PackedInt32Array and not (roh_i as PackedInt32Array).is_empty():
		quelle_i = roh_i
	else:
		quelle_i.resize(quelle_v.size())
		for k in quelle_v.size():
			quelle_i[k] = k

	var v: PackedVector3Array = g["v"]
	var n: PackedVector3Array = g["n"]
	var c: PackedColorArray = g["c"]
	var uv: PackedVector2Array = g["uv"]
	var uv2: PackedVector2Array = g["uv2"]
	var ind: PackedInt32Array = g["i"]
	var start := v.size()
	var basis_n := form.basis.inverse().transposed()
	var spiegel := form.basis.determinant() < 0.0
	var farbe: Color = info["farbe"]
	var klasse := String(info["klasse"])
	var merkmal := Vector2(1.0 if klasse in ["holz", "bluete", "pilz"] else 0.0,
			1.0 if klasse == "moos" else 0.0)
	for k in quelle_v.size():
		v.append(form * quelle_v[k])
		n.append((basis_n * quelle_n[k]).normalized() if k < quelle_n.size() else Vector3.ZERO)
		c.append(farbe * quelle_c[k] if k < quelle_c.size() else farbe)
		uv.append(quelle_uv[k] if k < quelle_uv.size() else Vector2.ZERO)
		uv2.append(merkmal)
	for t in range(0, quelle_i.size() - 2, 3):
		var a := quelle_i[t] + start
		var b := quelle_i[t + 1] + start
		var d := quelle_i[t + 2] + start
		ind.append(a)
		ind.append(d if spiegel else b)
		ind.append(b if spiegel else d)
	# Fehlen Normalen, werden sie aus den Dreiecken gewonnen (Godot:
	# Vorderseite im Uhrzeigersinn).
	if quelle_n.is_empty():
		for t in range(0, quelle_i.size() - 2, 3):
			var a := quelle_i[t] + start
			var b := quelle_i[t + 1] + start
			var d := quelle_i[t + 2] + start
			var flaeche := (v[d] - v[a]).cross(v[b] - v[a])
			n[a] += flaeche
			n[b] += flaeche
			n[d] += flaeche
		for k in range(start, n.size()):
			n[k] = n[k].normalized() if n[k].length_squared() > 0.0 else Vector3.UP
	var klassen: Dictionary = g["klassen"]
	klassen[klasse] = int(klassen.get(klasse, 0)) + quelle_i.size() / 3
	g["v"] = v
	g["n"] = n
	g["c"] = c
	g["uv"] = uv
	g["uv2"] = uv2
	g["i"] = ind


## Die Klasse mit den meisten Dreiecken in einer Gruppe.
static func _vorherrschend(g: Dictionary) -> String:
	var klassen: Dictionary = g["klassen"]
	var beste := ""
	var anzahl := -1
	for k: Variant in klassen:
		if int(klassen[k]) > anzahl:
			anzahl = int(klassen[k])
			beste = String(k)
	return beste


## Formt harte Flächen nach, damit aus Kenneys Tischplatten Findlinge
## werden: `stufen`-mal jedes Dreieck in vier teilen, dann jeden Ort entlang
## seiner geglätteten Normale verschieben – 3D-Rauschen (`zerklueftung`,
## Anteil der größten Achse) und eine Wölbung der Oberseite (`woelbung`,
## Anteil der Höhe), denn Deko-Felsen dürfen nie flach und damit begehbar
## aussehen (Plan, Findling-Regel). Die Verschiebung hängt nur vom Ort ab:
## Scheitel an derselben Stelle wandern gleich, es entstehen keine Risse,
## auch nicht zwischen flach schattierten Facetten. Danach tragen die
## Scheitel Flächennormalen; `_glaetten` mischt sie.
static func _formen(g: Dictionary, stufen: int, zerklueftung: float, woelbung: float,
		runden: float, saat: int) -> void:
	var v: PackedVector3Array = g["v"]
	var n: PackedVector3Array = g["n"]
	var c: PackedColorArray = g["c"]
	var uv: PackedVector2Array = g["uv"]
	var uv2: PackedVector2Array = g["uv2"]
	var ind: PackedInt32Array = g["i"]
	for stufe in stufen:
		var nv := PackedVector3Array()
		var nc := PackedColorArray()
		var nuv := PackedVector2Array()
		var nuv2 := PackedVector2Array()
		for t in range(0, ind.size() - 2, 3):
			var ecken: Array[int] = [ind[t], ind[t + 1], ind[t + 2]]
			var p: Array[Vector3] = []
			var f: Array[Color] = []
			var u: Array[Vector2] = []
			var m: Array[Vector2] = []
			for e in ecken:
				p.append(v[e])
				f.append(c[e])
				u.append(uv[e])
				m.append(uv2[e])
			# Kantenmitten 3 (a–b), 4 (b–c), 5 (c–a); (a + b) · 0,5 ist
			# vertauschbar, also treffen sich Nachbardreiecke genau.
			for paar: Array in [[0, 1], [1, 2], [2, 0]]:
				var a := int(paar[0])
				var b := int(paar[1])
				p.append((p[a] + p[b]) * 0.5)
				f.append(f[a].lerp(f[b], 0.5))
				u.append((u[a] + u[b]) * 0.5)
				m.append((m[a] + m[b]) * 0.5)
			for dreieck: Array in [[0, 3, 5], [3, 1, 4], [5, 4, 2], [3, 4, 5]]:
				for k: Variant in dreieck:
					nv.append(p[int(k)])
					nc.append(f[int(k)])
					nuv.append(u[int(k)])
					nuv2.append(m[int(k)])
		v = nv
		c = nc
		uv = nuv
		uv2 = nuv2
		ind = PackedInt32Array()
		ind.resize(v.size())
		for k in v.size():
			ind[k] = k

	var huelle := AABB(v[0], Vector3.ZERO)
	for p in v:
		huelle = huelle.expand(p)
	var mitte := huelle.get_center()
	if runden > 0.0:
		v = _rund_machen(v, huelle, runden)

	# Glatte Richtung je Ort: Flächennormalen aller Dreiecke dort, dazu ein
	# Drittel radial – so wölbt sich auch eine scharfe Kante nach außen.
	var groesste := maxf(huelle.size.x, maxf(huelle.size.y, huelle.size.z))
	var richtung := {}
	for t in range(0, ind.size() - 2, 3):
		var flaeche := (v[ind[t + 2]] - v[ind[t]]).cross(v[ind[t + 1]] - v[ind[t]])
		for k in 3:
			var ort := _ort(v[ind[t + k]])
			richtung[ort] = (richtung.get(ort, Vector3.ZERO) as Vector3) + flaeche
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	rauschen.frequency = 2.2 / maxf(groesste, 0.001)
	rauschen.fractal_octaves = 3
	var versatz := {}
	for k in v.size():
		var ort := _ort(v[k])
		if versatz.has(ort):
			continue
		var p := v[k]
		var glatt := (richtung[ort] as Vector3).normalized()
		var radial := (p - mitte).normalized()
		var weg := glatt.lerp(radial, 0.33).normalized()
		var hoch := clampf((p.y - huelle.position.y) / maxf(huelle.size.y, 0.001), 0.0, 1.0)
		var d := weg * rauschen.get_noise_3dv(p) * zerklueftung * groesste
		var q := Vector2((p.x - mitte.x) / maxf(huelle.size.x * 0.5, 0.001),
				(p.z - mitte.z) / maxf(huelle.size.z * 0.5, 0.001))
		d.y += maxf(0.0, 1.0 - q.length_squared()) * smoothstep(0.45, 1.0, hoch) \
				* woelbung * huelle.size.y
		# Der Fuß bleibt, wo er ist: Er steckt im Boden.
		d.y *= smoothstep(0.0, 0.12, hoch)
		versatz[ort] = d
	for k in v.size():
		v[k] += versatz[_ort(v[k])] as Vector3
	n.resize(v.size())
	for t in range(0, ind.size() - 2, 3):
		var flaeche := (v[ind[t + 2]] - v[ind[t]]).cross(v[ind[t + 1]] - v[ind[t]])
		var normale := flaeche.normalized() if flaeche.length_squared() > 0.0 else Vector3.UP
		for k in 3:
			n[ind[t + k]] = normale
	g["v"] = v
	g["n"] = n
	g["c"] = c
	g["uv"] = uv
	g["uv2"] = uv2
	g["i"] = ind


## Rundet einen Stamm (Kenneys Achteck-Prisma) um seine längste Achse: Jeder
## Ort am Mantel rückt auf den Kreis durch die Ecken, das Innere der
## Stirnflächen bleibt. Auch das hängt nur vom Ort ab – keine Risse.
static func _rund_machen(v: PackedVector3Array, huelle: AABB,
		anteil: float) -> PackedVector3Array:
	var achse := Vector3.RIGHT
	var s := huelle.size
	if s.y >= s.x and s.y >= s.z:
		achse = Vector3.UP
	elif s.z >= s.x and s.z >= s.y:
		achse = Vector3.BACK
	var mitte := huelle.get_center()
	var aussen := 0.0
	for p in v:
		var quer := (p - mitte) - achse * (p - mitte).dot(achse)
		aussen = maxf(aussen, quer.length())
	var kreis := aussen * 0.97
	for k in v.size():
		var quer := (v[k] - mitte) - achse * (v[k] - mitte).dot(achse)
		var r := quer.length()
		if r < 0.0001:
			continue
		var t := smoothstep(kreis * 0.5, kreis * 0.85, r) * anteil
		v[k] += quer / r * (lerpf(r, kreis, t) - r)
	return v


## Ein Ort als Schlüssel (0,5 mm Raster): gleiche Stelle, gleicher Schlüssel.
static func _ort(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 2000.0), roundi(p.y * 2000.0), roundi(p.z * 2000.0))


## Legt gleiche Scheitel zusammen (nach `_formen` liegt jeder dreifach vor).
static func _verschweissen(g: Dictionary) -> void:
	var v: PackedVector3Array = g["v"]
	var n: PackedVector3Array = g["n"]
	var c: PackedColorArray = g["c"]
	var uv: PackedVector2Array = g["uv"]
	var uv2: PackedVector2Array = g["uv2"]
	var ind: PackedInt32Array = g["i"]
	var nv := PackedVector3Array()
	var nn := PackedVector3Array()
	var nc := PackedColorArray()
	var nuv := PackedVector2Array()
	var nuv2 := PackedVector2Array()
	var neu := PackedInt32Array()
	var schon := {}
	for k in ind:
		var schluessel := [_ort(v[k]), Vector3i((n[k] * 1000.0).round()), c[k].to_rgba32(),
				Vector2i((uv[k] * 4096.0).round()), Vector2i((uv2[k] * 100.0).round())]
		var index := int(schon.get(schluessel, -1))
		if index < 0:
			index = nv.size()
			schon[schluessel] = index
			nv.append(v[k])
			nn.append(n[k])
			nc.append(c[k])
			nuv.append(uv[k])
			nuv2.append(uv2[k])
		neu.append(index)
	g["v"] = nv
	g["n"] = nn
	g["c"] = nc
	g["uv"] = nuv
	g["uv2"] = nuv2
	g["i"] = neu


## Mischt die Normalen gleicher Orte. Kenneys Felsen sind flach schattiert;
## halb geglättet brechen sie das Licht noch an Kanten, wirken aber nicht
## mehr wie gefaltetes Papier.
static func _glaetten(g: Dictionary, anteil: float) -> void:
	if anteil <= 0.0:
		return
	var v: PackedVector3Array = g["v"]
	var n: PackedVector3Array = g["n"]
	var summe := {}
	var orte: Array[Vector3i] = []
	for k in v.size():
		var ort := Vector3i(roundi(v[k].x * 2000.0), roundi(v[k].y * 2000.0),
				roundi(v[k].z * 2000.0))
		orte.append(ort)
		summe[ort] = (summe.get(ort, Vector3.ZERO) as Vector3) + n[k]
	for k in v.size():
		var mittel: Vector3 = summe[orte[k]]
		if mittel.length_squared() > 0.000001:
			n[k] = n[k].lerp(mittel.normalized(), anteil).normalized()
	g["n"] = n


## Laub: Normalen zur Außenseite einer gedachten Kronenhülle biegen (weiche
## Wolkenschattierung statt Facetten, Blattkarten lesen sich als Krone) und
## das Innere und die Unterseite abdunkeln. Akzente (UV2.x = 1) bleiben.
static func _laub_formen(g: Dictionary, biegen: float, tiefe: float) -> void:
	var v: PackedVector3Array = g["v"]
	var n: PackedVector3Array = g["n"]
	var c: PackedColorArray = g["c"]
	var uv2: PackedVector2Array = g["uv2"]
	var huelle := AABB()
	var erst := true
	for k in v.size():
		if uv2[k].x > 0.5:
			continue
		if erst:
			huelle = AABB(v[k], Vector3.ZERO)
			erst = false
		else:
			huelle = huelle.expand(v[k])
	if erst:
		return
	var mitte := huelle.get_center()
	# Die Kronenmitte liegt etwas unter der Hüllenmitte: Unten hängt Laub
	# tiefer als oben.
	mitte.y = huelle.position.y + huelle.size.y * 0.45
	var halb := (huelle.size * 0.5).max(Vector3(0.05, 0.05, 0.05))
	for k in v.size():
		if uv2[k].x > 0.5:
			continue
		var rel := (v[k] - mitte) / halb
		var aussen := Vector3(rel.x / halb.x, rel.y / halb.y, rel.z / halb.z)
		if aussen.length_squared() > 0.000001:
			n[k] = n[k].lerp(aussen.normalized(), biegen).normalized()
		var h := clampf((v[k].y - huelle.position.y) / maxf(huelle.size.y, 0.001), 0.0, 1.0)
		var r := clampf(rel.length(), 0.0, 1.0)
		var licht := lerpf(0.7, 1.12, pow(h, 0.8)) * lerpf(0.78, 1.0, r)
		licht = lerpf(1.0, licht, tiefe)
		var alt := c[k]
		c[k] = Color(alt.r * licht, alt.g * licht, alt.b * licht, alt.a)
	g["n"] = n
	g["c"] = c


static func _laub_unterkante(g: Dictionary) -> float:
	var v: PackedVector3Array = g["v"]
	var uv2: PackedVector2Array = g["uv2"]
	var tiefste := INF
	for k in v.size():
		if uv2[k].x < 0.5:
			tiefste = minf(tiefste, v[k].y)
	return tiefste


static func _gruppen_huelle(gruppen: Dictionary, reihenfolge: Array[String]) -> AABB:
	var huelle := AABB()
	var erst := true
	for s in reihenfolge:
		var v: PackedVector3Array = (gruppen[s] as Dictionary)["v"]
		for p in v:
			if erst:
				huelle = AABB(p, Vector3.ZERO)
				erst = false
			else:
				huelle = huelle.expand(p)
	return huelle


static func _gruppe_arrays(g: Dictionary) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = g["v"]
	arrays[Mesh.ARRAY_NORMAL] = g["n"]
	arrays[Mesh.ARRAY_COLOR] = g["c"]
	if g["textur"] != null:
		arrays[Mesh.ARRAY_TEX_UV] = g["uv"]
	arrays[Mesh.ARRAY_TEX_UV2] = g["uv2"]
	arrays[Mesh.ARRAY_INDEX] = g["i"]
	return arrays


## Der Stoff einer Gruppe, abgeleitet aus ihrem Inhalt und den Optionen.
static func _gruppe_stoff(g: Dictionary, optionen: Dictionary, huelle: AABB) -> ShaderMaterial:
	var textur: Texture2D = g["textur"]
	var hoehe := maxf(huelle.size.y, 0.01)
	if String(g["art"]) == "hart":
		var art := _vorherrschend(g)
		var holzig := art in ["borke", "holz"]
		var wunsch := {
			"stoff": "borke" if holzig else "fels",
			"moos": float(optionen.get("moos", 0.4 if holzig else 0.45)),
			# Der dunkle Fuß: 12 % der Höhe, höchstens 35 cm.
			"fuss": snappedf(clampf(hoehe * 0.12, 0.04, 0.35), 0.01),
			"relief": 0.6 if holzig else 0.45,
		}
		if textur != null:
			wunsch["grund"] = textur
			wunsch["grund_ist_farbe"] = true
			wunsch["relief"] = 0.5
		elif holzig:
			wunsch["lage"] = _borkenlage(g)
		return moosdecke(wunsch)
	var laub := {
		"wind": float(optionen.get("wind", 0.0)),
		"hoehe": snappedf(hoehe, 0.01),
		"umriss": 0.0 if Effekte.reduziert else float(optionen.get("umriss", 0.55)),
	}
	if textur != null:
		laub["grund"] = textur
		laub["grund_ist_farbe"] = true
		laub["schnitt"] = float(g["schnitt"])
	return laubstoff(laub)


## Borke hat Furchen längs des Stamms. Liegt ein Stamm, wird das Muster so
## gedreht, dass die Furchen seiner längsten Achse folgen.
static func _borkenlage(g: Dictionary) -> Basis:
	var v: PackedVector3Array = g["v"]
	if v.is_empty():
		return Basis.IDENTITY
	var huelle := AABB(v[0], Vector3.ZERO)
	for p in v:
		huelle = huelle.expand(p)
	var s := huelle.size
	if s.x > s.y * 1.3 and s.x >= s.z:
		return Basis(Vector3(0, 0, 1), PI * 0.5)    # X wird zur Musterhöhe
	if s.z > s.y * 1.3 and s.z > s.x:
		return Basis(Vector3(1, 0, 0), PI * 0.5)    # Z wird zur Musterhöhe
	return Basis.IDENTITY


## Dünnt Gruppen aus, bis das Modell höchstens `grenze` Dreiecke hat – über
## die LOD-Stufen, die Godots Importnetz selbst errechnet (meshoptimizer).
## Ohne diese Fähigkeit bleibt das Netz, wie es ist, mit einer Warnung.
static func _vereinfachen(gruppen: Dictionary, reihenfolge: Array[String],
		grenze: int) -> void:
	var summe := 0
	for s in reihenfolge:
		summe += ((gruppen[s] as Dictionary)["i"] as PackedInt32Array).size() / 3
	if summe <= grenze:
		return
	var anteil := float(grenze) / float(summe)
	for s in reihenfolge:
		var g: Dictionary = gruppen[s]
		var i: PackedInt32Array = g["i"]
		var ziel := int(float(i.size() / 3) * anteil)
		var roh := ImporterMesh.new()
		var arrays := _gruppe_arrays(g)
		arrays[Mesh.ARRAY_TEX_UV] = g["uv"]
		roh.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		roh.generate_lods(60.0, 25.0, [])
		var stufen := roh.get_surface_lod_count(0)
		if stufen == 0:
			if not _lod_gewarnt:
				_lod_gewarnt = true
				push_warning("Fremdmodelle: Vereinfachen hier nicht möglich, Netz bleibt voll")
			return
		var neu := roh.get_surface_arrays(0)
		var beste := PackedInt32Array()
		for stufe in stufen:
			beste = roh.get_surface_lod_indices(0, stufe)
			if beste.size() / 3 <= ziel:
				break
		g["v"] = neu[Mesh.ARRAY_VERTEX]
		g["n"] = neu[Mesh.ARRAY_NORMAL]
		g["c"] = neu[Mesh.ARRAY_COLOR]
		var neu_uv: Variant = neu[Mesh.ARRAY_TEX_UV]
		if neu_uv is PackedVector2Array:
			g["uv"] = neu_uv
		g["uv2"] = neu[Mesh.ARRAY_TEX_UV2]
		g["i"] = beste


## Moosmuster für eine Kachel von 2,2 m: RGB Moos – Polster von gut
## 25 cm mit dunklen Fugen und hellen Kuppen, darin kleinere Büschel und
## feine Fasern, dazwischen olivgelbe Flecken –, A ein großes Fleckrauschen
## für die Moosgrenze. 256², kachelbar, 0,3 MB mit Mipmaps.
static func _moos_textur() -> ImageTexture:
	if _moos_bild == null:
		_moos_bild = ImageTexture.create_from_image(moos_bild())
	return _moos_bild


## Das Bild hinter `_moos_textur()` (mit Mipmaps), auch für Prüfbilder.
static func moos_bild() -> Image:
	var k := 256
	var polster := _rauschbild(9101, 0.045, k, FastNoiseLite.RETURN_DISTANCE, 2.0)
	var wert := _rauschbild(9101, 0.045, k, FastNoiseLite.RETURN_CELL_VALUE, 2.0)
	var bueschel := _rauschbild(9104, 0.14, k, FastNoiseLite.RETURN_DISTANCE, 0.0)
	var fein := _rauschbild(9102, 0.45, k, -1, 0.0)
	var flecken := _rauschbild(9105, 0.012, k, -1, 0.0)
	var gross := _rauschbild(9103, 0.008, k, -1, 0.0)
	var fuge := Color(0.05, 0.075, 0.03)
	var dunkel := Color(0.12, 0.19, 0.06)
	var hell := Color(0.34, 0.44, 0.13)
	var oliv := Color(0.47, 0.47, 0.17)
	var daten := PackedByteArray()
	daten.resize(k * k * 4)
	for i in k * k:
		# Jedes Polster ist eine Kuppe (hell oben, dunkel am Rand) mit eigenem
		# Grundton; darin kleinere Büschel und Fasern.
		var kuppe := 1.0 - polster[i] / 255.0
		var ton := wert[i] / 255.0
		var klein := 1.0 - bueschel[i] / 255.0
		var faser := fein[i] / 255.0
		var t := clampf(0.5 * kuppe + 0.2 * ton + 0.15 * klein + 0.15 * faser, 0.0, 1.0)
		var farbe := dunkel.lerp(hell, smoothstep(0.2, 0.85, t))
		# Fugen zwischen den Polstern bleiben dunkel – daraus liest sich
		# das Polster auch aus zehn Metern.
		farbe = farbe.lerp(fuge, clampf((0.32 - kuppe) * 4.0, 0.0, 1.0))
		var gelb := clampf((flecken[i] / 255.0 - 0.5) * 2.4, 0.0, 1.0) * smoothstep(0.3, 0.8, t)
		farbe = farbe.lerp(oliv, gelb * 0.7)
		daten[i * 4] = int(clampf(farbe.r, 0.0, 1.0) * 255.0)
		daten[i * 4 + 1] = int(clampf(farbe.g, 0.0, 1.0) * 255.0)
		daten[i * 4 + 2] = int(clampf(farbe.b, 0.0, 1.0) * 255.0)
		daten[i * 4 + 3] = gross[i]
	var bild := Image.create_from_data(k, k, false, Image.FORMAT_RGBA8, daten)
	bild.generate_mipmaps()
	return bild


## Kachelbares Rauschen als Bytes: Zellrauschen mit der Rückgabeart
## `zellen` (FastNoiseLite.CellularReturnType) oder, bei −1, Fraktalrauschen.
static func _rauschbild(saat: int, frequenz: float, k: int, zellen: int,
		verwirbeln: float) -> PackedByteArray:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.frequency = frequenz
	if zellen >= 0:
		r.noise_type = FastNoiseLite.TYPE_CELLULAR
		r.fractal_type = FastNoiseLite.FRACTAL_NONE
		r.cellular_return_type = zellen as FastNoiseLite.CellularReturnType
	else:
		r.fractal_octaves = 3
	if verwirbeln > 0.0:
		r.domain_warp_enabled = true
		r.domain_warp_amplitude = verwirbeln
		r.domain_warp_frequency = frequenz * 0.7
	return r.get_seamless_image(k, k, false, false, 0.1).get_data()


static func _hol_shader(art: String) -> Shader:
	if _shader.has(art):
		return _shader[art]
	var code := ""
	match art:
		"hart":
			code = _SHADER_HART
		"ueberlage":
			code = _SHADER_UEBERLAGE
		"laub":
			code = _SHADER_LAUB.replace("//SCHNITT", "")
		_:
			code = _SHADER_LAUB.replace("//SCHNITT",
					"ALPHA = a;\n\tALPHA_SCISSOR_THRESHOLD = schnitt;")
	var shader := Shader.new()
	shader.code = code
	_shader[art] = shader
	return shader


## Harte Flächen (gl_compatibility: fünf Texturzugriffe im Bildpunkt, kein
## Bildschirm- oder Tiefenpuffer). Das Mittel des Musters kommt aus seiner
## kleinsten Mipmap-Stufe im Scheitelshader – so wird das Muster zum reinen
## Detail um 1,0, und die Farbe bleibt die der Scheitel.
const _SHADER_HART := """shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D grund : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moos_textur : source_color, filter_linear_mipmap, repeat_enable;
uniform bool grund_ist_farbe = false;
uniform float kachel = 2.0;
uniform float relief = 0.8;
uniform vec4 toenung : source_color = vec4(1.0);
uniform float moos_menge : hint_range(0.0, 1.0) = 0.45;
uniform vec4 moos_ton : source_color = vec4(1.0);
uniform float moos_kachel = 2.2;
uniform float fuss = 0.3;
uniform float fuss_dunkel : hint_range(0.0, 1.0) = 0.4;
uniform mat3 lage = mat3(1.0);

varying vec3 o_pos;
varying vec3 o_nrm;
varying vec3 w_pos;
varying vec3 w_nrm;
varying vec3 mittel;

void vertex() {
	o_pos = lage * VERTEX;
	o_nrm = lage * NORMAL;
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	mittel = max(textureLod(grund, vec2(0.5), 12.0).rgb, vec3(0.02));
}

void fragment() {
	vec3 farbe;
	float hoehe;
	if (grund_ist_farbe) {
		vec3 t = texture(grund, UV).rgb;
		farbe = t * COLOR.rgb;
		hoehe = dot(t / mittel, vec3(0.333));
	} else {
		vec3 b = abs(normalize(o_nrm));
		b = b * b * b * b;
		b /= max(b.x + b.y + b.z, 0.0001);
		vec3 d = texture(grund, o_pos.zy / kachel).rgb * b.x
				+ texture(grund, o_pos.xz / kachel).rgb * b.y
				+ texture(grund, o_pos.xy / kachel).rgb * b.z;
		d /= mittel;
		hoehe = dot(d, vec3(0.333)) * (1.0 - UV2.x);
		farbe = COLOR.rgb * mix(mix(vec3(1.0), d, 0.7), vec3(1.0), UV2.x * 0.7);
	}
	// Moos wächst oben; das Rauschen liegt in der Welt, nicht am Netz.
	vec3 wn = normalize(w_nrm);
	vec4 mf = texture(moos_textur, w_pos.xz / moos_kachel);
	float flecken = texture(moos_textur, w_pos.xz / (moos_kachel * 5.7) + vec2(0.37, 0.71)).a;
	// Oben, wo Regen und Laub liegen bleiben – je mehr Moos, desto steiler
	// darf es sein –, und dort in Inseln aus dem Weltrauschen, deren Ränder
	// den Polstern folgen. UV2.y: Hier lag in der Datei schon Bewuchs
	// (Kenneys Grasdeckel), dort ist Moos wahrscheinlicher, nie lückenlos.
	float schwelle = 0.9 - moos_menge * 1.1;
	float oben = smoothstep(schwelle, schwelle + 0.3, wn.y + UV2.y * 0.25);
	float insel = smoothstep(0.62 - moos_menge * 0.45, 0.7 - moos_menge * 0.45,
			flecken + (mf.a - 0.5) * 0.3 + (dot(mf.rgb, vec3(0.6)) - 0.3) * 0.4 + UV2.y * 0.15);
	float m = oben * insel;
	vec3 moos = mf.rgb * moos_ton.rgb;
	float boden = mix(1.0 - fuss_dunkel, 1.0, smoothstep(0.0, fuss, o_pos.y));
	ALBEDO = mix(farbe, moos, m) * toenung.rgb * boden;
	ROUGHNESS = mix(0.84, 1.0, m);
	SPECULAR = mix(0.28, 0.05, m);
	// Relief über Bildschirmableitungen: kein Tangentenraum, keine Textur mehr.
	float h = mix(hoehe, dot(mf.rgb, vec3(1.2)), m);
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 gefaelle = sign(det) * (dhx * r1 + dhy * r2);
	NORMAL = normalize(abs(det) * NORMAL - gefaelle * relief * 0.05);
}
"""

## Moos als Überlage (`next_pass`) auf einem bestehenden Material.
const _SHADER_UEBERLAGE := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_disabled;

uniform sampler2D moos_textur : source_color, filter_linear_mipmap, repeat_enable;
uniform float moos_menge : hint_range(0.0, 1.0) = 0.45;
uniform vec4 moos_ton : source_color = vec4(1.0);
uniform float moos_kachel = 2.2;

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	// Ein Hauch nach außen, damit die Überlage nicht mit ihrem Träger flimmert.
	VERTEX += NORMAL * 0.004;
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 wn = normalize(w_nrm);
	vec4 mf = texture(moos_textur, w_pos.xz / moos_kachel);
	float flecken = texture(moos_textur, w_pos.xz / (moos_kachel * 5.7) + vec2(0.37, 0.71)).a;
	float schwelle = 0.9 - moos_menge * 1.1;
	float oben = smoothstep(schwelle, schwelle + 0.3, wn.y);
	float insel = smoothstep(0.62 - moos_menge * 0.45, 0.7 - moos_menge * 0.45,
			flecken + (mf.a - 0.5) * 0.3 + (dot(mf.rgb, vec3(0.6)) - 0.3) * 0.4);
	ALBEDO = mf.rgb * moos_ton.rgb;
	ALPHA = oben * insel;
	ROUGHNESS = 1.0;
}
"""

## Laub (beidseitig). `//SCHNITT` wird für die Fassung mit Verwerfen ersetzt.
const _SHADER_LAUB := """shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D grund : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool grund_ist_farbe = false;
uniform float kachel = 0.7;
uniform vec4 toenung : source_color = vec4(1.0);
uniform float umriss : hint_range(0.0, 1.0) = 0.55;
uniform float schnitt : hint_range(0.0, 1.0) = 0.5;
uniform float wind = 0.0;
uniform float hoehe = 1.0;
uniform float durchlicht = 0.3;

varying vec3 o_pos;
varying vec3 o_nrm;
varying vec3 mittel;

void vertex() {
	o_pos = VERTEX;
	o_nrm = NORMAL;
	mittel = max(textureLod(grund, vec2(0.5), 12.0).rgb, vec3(0.02));
	if (wind > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float h = clamp(VERTEX.y / hoehe, 0.0, 1.0);
		float s = sin(TIME * 1.6 + w.x * 0.43 + w.z * 0.29) + 0.45 * sin(TIME * 2.9 + w.z * 1.1);
		VERTEX.x += s * wind * h * h;
		VERTEX.z += s * wind * h * h * 0.6;
	}
}

void fragment() {
	vec3 farbe;
	float a = 1.0;
	if (grund_ist_farbe) {
		vec4 t = texture(grund, UV);
		farbe = t.rgb * COLOR.rgb;
		a = t.a;
	} else {
		vec3 b = abs(normalize(o_nrm));
		b = b * b * b;
		b /= max(b.x + b.y + b.z, 0.0001);
		vec3 d = (texture(grund, o_pos.zy / kachel).rgb * b.x
				+ texture(grund, o_pos.xz / kachel).rgb * b.y
				+ texture(grund, o_pos.xy / kachel).rgb * b.z) / mittel;
		farbe = COLOR.rgb * mix(d, vec3(1.0), UV2.x);
		// Am Umriss zerfällt die Krone in Blätter: Wo das Muster dunkel ist
		// (Lücken zwischen den Blättern), wird verworfen.
		float kante = 1.0 - abs(dot(normalize(NORMAL), VIEW));
		float zerfall = smoothstep(0.35, 0.85, kante) * umriss * (1.0 - UV2.x);
		float blatt = smoothstep(0.78, 1.08, dot(d, vec3(0.333)));
		a = mix(1.0, blatt, zerfall);
	}
	ALBEDO = farbe * toenung.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
	BACKLIGHT = ALBEDO * durchlicht;
	//SCHNITT
}
"""
