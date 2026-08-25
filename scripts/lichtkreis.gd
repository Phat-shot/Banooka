extends Node3D
class_name Lichtkreis
## Macht aus einem Level ein Dunkellevel (Steckbrief 5-3 „Funkenlicht").
##
## Vorbild ist das Grab bei Nacht, in dem ein Glühwürmchen die einzige
## Lichtquelle ist: Das Umgebungslicht geht fast aus, der Himmel wird
## abgedunkelt, und übrig bleibt ein warmer Kreis, der mit der Figur
## mitwandert. Gefahren erscheinen erst, wenn man in sie hineinläuft.
##
## REGEL FÜR DAS LEVEL, DAMIT DAS FAIR BLEIBT:
## **Kein Sprung darf weiter gehen, als das Licht reicht.** Wer eine
## Plattform anspringt, die er beim Absprung nicht sehen kann, springt
## ins Ungewisse – und das ist kein Können, sondern Raten. Praktisch
## heißt das: Die Lücke von Absprungkante zu Landekante bleibt kleiner
## als `reichweite`; bei der Vorgabe 7 m also deutlich unter der
## Sprungweite, die die Figur eigentlich schafft. Aus demselben Grund
## verzweigt so ein Level nicht: Orientierung im Dunkeln wäre unfair.
##
## Das Licht klebt nicht an der Figur, sondern folgt ihr mit kleiner
## Verzögerung (`nachlauf`) und flackert leicht (`flackern`). Beides ist
## Absicht: Ein starr mitgeführtes, ruhiges Licht sieht nach Taschenlampe
## aus, ein nachziehendes und unruhiges nach lebendem Leuchttier.
##
## Renderer ist `gl_compatibility` – deshalb ein einzelnes `OmniLight3D`
## ohne Schatten. Punktlichter sind dort in der Anzahl begrenzt, und
## Schatten eines beweglichen Punktlichts kosten dort am meisten. Wer im
## Level noch Fackeln setzt, bleibt bei wenigen.
##
## Einsatz im Level:
##     var kreis := Lichtkreis.new()
##     add_child(kreis)
##     Leuchtmarker.markieren(self, ["kisten", "fruechte"], 1.4)

## Wie weit der Lichtkreis reicht (Meter). Zugleich die Obergrenze für
## jede Sprungweite im Level – siehe Kopfkommentar.
@export var reichweite := 7.0

## Helligkeit des mitgeführten Lichts.
@export var staerke := 2.2

## Farbe des Lichts. Warmes Ocker wie im Vorbild (`#A05524` ist dort der
## Lichtkreis) – warmes Licht in kaltem Schwarz liest sich als Feuer,
## weißes Licht als Scheinwerfer.
@export var farbe := Color(1.0, 0.86, 0.55)

## Ausschlag des Flackerns als Anteil der Stärke. 0 = völlig ruhig.
@export_range(0.0, 0.5, 0.01) var flackern := 0.12

## Wie schnell das Licht der Figur nachzieht (je größer, desto strammer).
## Klein genug, dass man das Nachziehen sieht, groß genug, dass das Licht
## bei vollem Lauftempo nicht zurückbleibt.
@export var nachlauf := 6.0

## Anteil des Umgebungslichts, der übrig bleibt (0 = stockfinster).
## Ganz auf null gedreht verschwinden auch die Silhouetten der Wände,
## und der Gang wird zur schwarzen Fläche ohne Raumgefühl.
@export_range(0.0, 1.0, 0.01) var restlicht := 0.06

## Höhe des Lichts über dem Ursprung der Figur (Brusthöhe).
@export var hoehe := 1.2

## Anteil, auf den gerichtete Lichter (die Levelsonne) gedimmt werden.
## Ohne das bliebe das Level trotz ausgeschaltetem Umgebungslicht taghell –
## die Sonne allein beleuchtet den ganzen Gang.
@export_range(0.0, 1.0, 0.01) var sonnenrest := 0.04

## Mindestdichte des Nebels. Der Nebel ist hier kein Wettereffekt, sondern
## die Wand aus Schwarz, hinter der die Strecke aufhört – ohne ihn sieht
## man unbeleuchtete Geometrie noch als Umriss vor dem Horizont.
@export var nebeldichte := 0.05

## Frequenzen des Flackerns. Zwei Wellen, die kein ganzzahliges Verhältnis
## haben – sonst wiederholt sich das Muster hörbar regelmäßig und wirkt
## wieder wie Technik statt wie Leben.
const FLACKER_SCHNELL := 11.3
const FLACKER_LANGSAM := 4.7

var _licht: OmniLight3D = null
var _spieler: Node3D = null
var _zeit := 0.0

## Umgebung und ihre Vorgänger-Fassung. Gedimmt wird nie das Original,
## sondern eine Kopie – die `Environment` einer Levelszene ist eine
## Unterressource und wird von allen Instanzen derselben Szene geteilt.
## Wer sie anfasst, dimmt das Level auch beim nächsten Laden noch.
var _welt: WorldEnvironment = null
var _umgebung_vorher: Environment = null

## Gerichtete Lichter des Levels mit ihrer ursprünglichen Stärke.
var _sonnen := {}


func _ready() -> void:
	_licht = OmniLight3D.new()
	_licht.name = "Funke"
	_licht.light_color = farbe
	_licht.light_energy = staerke
	_licht.omni_range = reichweite
	# Weicher Abfall zum Rand: Mit dem harten Vorgabewert endet der Kreis
	# an einer sichtbaren Kante, und die liest sich als Loch im Boden.
	_licht.omni_attenuation = 1.6
	_licht.shadow_enabled = false
	add_child(_licht)

	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	if _spieler != null:
		_licht.global_position = _spieler.global_position + Vector3.UP * hoehe

	_dunkel_machen()


func _exit_tree() -> void:
	_helligkeit_zurueck()


func _process(delta: float) -> void:
	if _spieler == null or not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null:
			return
	_zeit += delta

	# Nachziehen bildratenunabhängig: `lerp` mit festem Faktor würde bei
	# 30 Bildern je Sekunde doppelt so träge folgen wie bei 60.
	var ziel := _spieler.global_position + Vector3.UP * hoehe
	_licht.global_position = _licht.global_position.lerp(ziel,
			1.0 - exp(-nachlauf * delta))

	if flackern <= 0.0:
		return
	var welle := sin(_zeit * FLACKER_SCHNELL) * 0.6 \
			+ sin(_zeit * FLACKER_LANGSAM) * 0.4
	_licht.light_energy = staerke * (1.0 + flackern * welle)
	# Die Reichweite atmet nur halb so stark mit: Ein Kreis, der genauso
	# sprunghaft wächst wie er heller wird, wirkt wie ein Wackelkontakt.
	_licht.omni_range = reichweite * (1.0 + flackern * welle * 0.5)


# ---------------------------------------------------------------- Umgebung

## Dimmt Umgebungslicht, Himmel, Nebel und die Levelsonne.
func _dunkel_machen() -> void:
	var wurzel := _levelwurzel()
	if wurzel == null:
		return

	_welt = _suche_umgebung(wurzel)
	if _welt != null and _welt.environment != null:
		_umgebung_vorher = _welt.environment
		var dunkel := _umgebung_vorher.duplicate() as Environment
		dunkel.ambient_light_energy = _umgebung_vorher.ambient_light_energy * restlicht
		# Der Himmel ist im Vorbild nicht dunkelblau, sondern weg. Bleibt er
		# hell, hat der schwarze Gang plötzlich einen leuchtenden Horizont.
		dunkel.background_energy_multiplier = \
				_umgebung_vorher.background_energy_multiplier * restlicht
		dunkel.fog_enabled = true
		dunkel.fog_light_color = dunkel.fog_light_color.darkened(
				clampf(1.0 - restlicht, 0.0, 1.0))
		dunkel.fog_density = maxf(dunkel.fog_density, nebeldichte)
		dunkel.fog_sky_affect = 1.0
		dunkel.fog_aerial_perspective = 0.0
		_welt.environment = dunkel

	_sonnen.clear()
	for licht in _gerichtete_lichter(wurzel):
		_sonnen[licht] = licht.light_energy
		licht.light_energy *= sonnenrest


## Stellt her, wie es vorher war. Ohne das bliebe der Portalraum dunkel,
## sobald man das Level verlässt – die Umgebung gehört der Szene, nicht uns.
func _helligkeit_zurueck() -> void:
	if _welt != null and is_instance_valid(_welt) and _umgebung_vorher != null:
		_welt.environment = _umgebung_vorher
	_welt = null
	_umgebung_vorher = null
	for licht in _sonnen:
		if is_instance_valid(licht):
			licht.light_energy = _sonnen[licht]
	_sonnen.clear()


## Die Levelwurzel ist der nächste Vorfahr, der eine `WorldEnvironment`
## unter sich hat. Über sie hinaus wird nicht gesucht: Sonst griffe ein
## Lichtkreis im Level nach der Umgebung des Hubs.
func _levelwurzel() -> Node:
	var knoten: Node = owner if owner != null else get_parent()
	while knoten != null:
		if _suche_umgebung(knoten) != null:
			return knoten
		knoten = knoten.get_parent()
	return owner if owner != null else get_parent()


static func _suche_umgebung(wurzel: Node) -> WorldEnvironment:
	if wurzel is WorldEnvironment:
		return wurzel as WorldEnvironment
	for kind in wurzel.get_children():
		var treffer := _suche_umgebung(kind)
		if treffer != null:
			return treffer
	return null


static func _gerichtete_lichter(wurzel: Node) -> Array:
	var gefunden := []
	var stapel: Array[Node] = [wurzel]
	while not stapel.is_empty():
		var knoten: Node = stapel.pop_back()
		for kind in knoten.get_children():
			stapel.push_back(kind)
		if knoten is DirectionalLight3D:
			gefunden.append(knoten)
	return gefunden
