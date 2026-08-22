extends CanvasLayer
## HUD: Früchte, Leben, Kisten-Zähler und Einblend-Nachrichten.

@onready var _fruechte: Label = $Anzeige/Werte/Fruechte
@onready var _leben: Label = $Anzeige/Werte/Leben
@onready var _kisten: Label = $Anzeige/Werte/Kisten
@onready var _nachricht: Label = $Anzeige/Nachricht

var _nachricht_timer := 0.0


func _ready() -> void:
	GameState.fruechte_geaendert.connect(_auf_fruechte)
	GameState.leben_geaendert.connect(_auf_leben)
	GameState.kisten_geaendert.connect(_auf_kisten)
	GameState.nachricht.connect(_auf_nachricht)

	_auf_fruechte(GameState.fruechte)
	_auf_leben(GameState.leben)
	_auf_kisten(GameState.kisten_zerbrochen, GameState.kisten_gesamt)
	_nachricht.modulate.a = 0.0


func _process(delta: float) -> void:
	if _nachricht_timer > 0.0:
		_nachricht_timer -= delta
		if _nachricht_timer <= 0.0:
			_nachricht.modulate.a = 0.0


func _auf_fruechte(anzahl: int) -> void:
	_fruechte.text = "Früchte: %d" % anzahl


func _auf_leben(anzahl: int) -> void:
	_leben.text = "Leben: %d" % anzahl


func _auf_kisten(zerbrochen: int, gesamt: int) -> void:
	_kisten.text = "Kisten: %d/%d" % [zerbrochen, gesamt]


func _auf_nachricht(text: String, dauer: float) -> void:
	_nachricht.text = text
	_nachricht.modulate.a = 1.0
	_nachricht_timer = dauer
