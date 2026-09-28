extends CanvasLayer
class_name Bildrahmen
## Bildrahmen: abgedunkelte Ränder und ein warmer Schein von oben.
##
## Ein Overlay statt eines Nachbearbeitungseffekts, weil der
## Compatibility-Renderer (Web, Mobil) kein SCREEN_TEXTURE kennt. Der
## Shader (`shaders/bildrahmen.gdshader`) liest das Bild nicht, er legt
## mit vormultipliziertem Alpha Farbe darüber – ein bildschirmfüllendes
## Rechteck, ein Durchgang.
##
## Einsatz als Knoten in der Levelszene (Werte im Inspektor) oder aus
## Code: `Bildrahmen.einsetzen(self, 0.25, Color(0.03, 0.03, 0.05), 0.03)`.
##
## Liegt auf Ebene -1: unter dem HUD (1), dem Bildblitz der `Effekte` (0)
## und dem Ladeschirm (128). Der Rahmen gehört zur Welt, nicht zur Anzeige.
## Maus und Touch gehen durch (`MOUSE_FILTER_IGNORE`).

const SHADER := preload("res://shaders/bildrahmen.gdshader")

## Abdunklung in den Bildecken, 0 = aus. Über rund 0,4 verschluckt der
## Rahmen die HUD-Ecken und in den Ritt-Leveln die Spurränder.
@export_range(0.0, 0.6, 0.01) var staerke := 0.35:
	set(wert):
		staerke = wert
		_werte_setzen()

## Farbe, zu der die Ränder hin abdunkeln. Ein Hauch der Levelstimmung
## statt reinem Schwarz, sonst wirkt der Rand wie ein Loch.
@export var farbe := Color(0.02, 0.035, 0.02):
	set(wert):
		farbe = wert
		_werte_setzen()

## Warmer Schein von oben, als fiele Licht durch die Kronen. 0 = aus.
@export_range(0.0, 0.2, 0.005) var licht := 0.04:
	set(wert):
		licht = wert
		_werte_setzen()

@export var licht_farbe := Color(1.0, 0.84, 0.58):
	set(wert):
		licht_farbe = wert
		_werte_setzen()

var _stoff: ShaderMaterial = null


## Hängt einen fertigen Bildrahmen an `eltern` und gibt ihn zurück.
static func einsetzen(eltern: Node, rand: float = 0.3,
		rand_farbe: Color = Color(0.02, 0.035, 0.02),
		schein: float = 0.03) -> Bildrahmen:
	var rahmen := Bildrahmen.new()
	rahmen.name = "Bildrahmen"
	rahmen.staerke = rand
	rahmen.farbe = rand_farbe
	rahmen.licht = schein
	eltern.add_child(rahmen)
	return rahmen


func _init() -> void:
	layer = -1


func _ready() -> void:
	var flaeche := ColorRect.new()
	flaeche.name = "Flaeche"
	flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flaeche.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stoff = ShaderMaterial.new()
	_stoff.shader = SHADER
	flaeche.material = _stoff
	add_child(flaeche)
	_werte_setzen()


func _werte_setzen() -> void:
	if _stoff == null:
		return
	_stoff.set_shader_parameter("rand_staerke", staerke)
	_stoff.set_shader_parameter("rand_farbe", farbe)
	_stoff.set_shader_parameter("licht_staerke", licht)
	_stoff.set_shader_parameter("licht_farbe", licht_farbe)
	# Ganz aus heißt auch: nichts zeichnen. Das Rechteck füllt sonst den
	# ganzen Schirm mit einem Durchgang, der nichts verändert.
	visible = staerke > 0.0 or licht > 0.0
