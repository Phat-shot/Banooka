extends Area3D
class_name Stimmungszone
## Ändert Licht und Nebel, solange der Spieler drinsteht.
##
## Gebaut, weil ein Level mit drei Untergründen trotzdem überall gleich
## aussah: Der Waldweg, die Bohlen über dem Moor und der Firn im Gebirge
## standen alle im selben grünen Dunst. Ein anderer Belag macht noch keinen
## anderen Ort – dafür müssen Nebelfarbe, Nebeldichte und Umgebungslicht
## mitgehen.
##
## Übergeblendet wird über `wechsel`, nicht geschaltet: Ein Nebel, der in
## einem Bild von Grün auf Weiß springt, liest sich als Fehler.
##
## Zwei Fallen, an denen das sonst scheitert:
##
## 1. Die `Environment` einer Levelszene ist eine Unterressource und gehört
##    ALLEN Instanzen. Wer sie anfasst, ändert das Level auch beim nächsten
##    Laden. Deshalb wird sie einmal kopiert.
## 2. Überlappen sich zwei Zonen oder liegen sie dicht beieinander, zögen
##    beide gleichzeitig an denselben Werten – eine zurück zur Grundstimmung,
##    die andere zu ihrer eigenen. Deshalb regelt immer nur die ZULETZT
##    betretene Zone; die anderen halten still.

## Nebelfarbe in dieser Zone. Alpha 0 = Grundwert des Levels behalten.
@export var nebelfarbe := Color(0, 0, 0, 0)
## Nebeldichte. Negativ = Grundwert behalten.
@export var nebeldichte := -1.0
## Stärke des Umgebungslichts. Negativ = Grundwert behalten.
@export var umgebungslicht := -1.0
## Farbe des Umgebungslichts. Alpha 0 = Grundwert behalten.
@export var umgebungsfarbe := Color(0, 0, 0, 0)
## Wie schnell übergeblendet wird (Anteil je Sekunde).
@export var wechsel := 0.8

## Die Zone, die gerade regelt. Ohne diesen gemeinsamen Zeiger zerrten
## mehrere Zonen gleichzeitig an denselben Werten.
static var _fuehrend: Stimmungszone = null
## Einmal angelegte Kopie der Levelumgebung samt Grundwerten.
static var _umgebung: Environment = null
static var _grund := {}

var _drin := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_auf_eintritt)
	body_exited.connect(_auf_austritt)
	_umgebung_sichern()


func _process(delta: float) -> void:
	if _fuehrend != self or _umgebung == null:
		return
	var anteil := clampf(delta * wechsel, 0.0, 1.0)
	var ziel_farbe: Color = nebelfarbe if _drin and nebelfarbe.a > 0.0 \
			else _grund["nebelfarbe"]
	var ziel_dichte: float = nebeldichte if _drin and nebeldichte >= 0.0 \
			else float(_grund["nebeldichte"])
	var ziel_licht: float = umgebungslicht if _drin and umgebungslicht >= 0.0 \
			else float(_grund["umgebungslicht"])
	var ziel_umgebung: Color = umgebungsfarbe if _drin and umgebungsfarbe.a > 0.0 \
			else _grund["umgebungsfarbe"]

	_umgebung.fog_light_color = _umgebung.fog_light_color.lerp(ziel_farbe, anteil)
	_umgebung.fog_density = lerpf(_umgebung.fog_density, ziel_dichte, anteil)
	_umgebung.ambient_light_energy = lerpf(
			_umgebung.ambient_light_energy, ziel_licht, anteil)
	_umgebung.ambient_light_color = _umgebung.ambient_light_color.lerp(
			ziel_umgebung, anteil)

	# Ist die Grundstimmung wieder erreicht, gibt die Zone die Führung ab.
	if not _drin and absf(_umgebung.fog_density - ziel_dichte) < 0.0005:
		_fuehrend = null


func _exit_tree() -> void:
	if _fuehrend == self:
		_fuehrend = null
	# Die letzte Zone räumt auf: Sonst behielte die nächste Levelinstanz
	# die Kopie und damit die Werte des vorigen Durchlaufs.
	if get_tree() != null and get_tree().get_nodes_in_group("stimmungszonen").size() <= 1:
		_umgebung = null
		_grund = {}


func _auf_eintritt(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	_drin = true
	_fuehrend = self


func _auf_austritt(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	_drin = false
	if _fuehrend == null:
		_fuehrend = self


## Legt einmalig eine Kopie der Levelumgebung an und merkt sich, wie sie
## aussah. Die Kopie ist Pflicht – siehe Kopfkommentar.
func _umgebung_sichern() -> void:
	add_to_group("stimmungszonen")
	if _umgebung != null:
		return
	var welt: WorldEnvironment = null
	for k in get_tree().get_root().find_children("*", "WorldEnvironment", true, false):
		welt = k as WorldEnvironment
		break
	if welt == null or welt.environment == null:
		return
	_umgebung = welt.environment.duplicate()
	welt.environment = _umgebung
	_grund = {
		"nebelfarbe": _umgebung.fog_light_color,
		"nebeldichte": _umgebung.fog_density,
		"umgebungslicht": _umgebung.ambient_light_energy,
		"umgebungsfarbe": _umgebung.ambient_light_color,
	}
