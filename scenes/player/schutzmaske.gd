extends Node3D
class_name Schutzmaske
## Die Schutzladungen als schwebende Masken um den Spieler.
##
## Vorher stand der Schutz als Zahlenreihe im HUD. Im Spiel schaut man
## aber auf die Figur, nicht in die Ecke – wer im Sprung getroffen wird,
## soll am Bild sehen, dass noch etwas abfängt. Deshalb kreisen die
## Ladungen jetzt als Masken um den Kopf: eine Maske je Ladung, gleich
## verteilt, langsam kreisend.
##
## Die Masken sind reine Anzeige: keine Kollision, kein Schatten. Sie
## hängen am Spieler und drehen sich mit ihm nicht mit – der Ring bleibt
## in der Welt ausgerichtet, sonst wirkte er angeklebt.

## Kreis, auf dem die Masken laufen.
const RADIUS := 0.92
const HOEHE := 1.15
const TEMPO := 1.5          ## Umdrehungen pro Sekunde × 2π
const NICK := 0.22          ## Auf-und-ab-Schwingen
const MASKENHOEHE := 0.42

var _masken: Array[Node3D] = []
var _phase := 0.0
var _anzahl := -1


func _ready() -> void:
	top_level = true          ## Position folgt, Drehung nicht
	set_process(true)
	GameState.schutz_geaendert.connect(_auf_schutz)
	_setze_anzahl(GameState.schutz_anzeige())


func _process(delta: float) -> void:
	var eltern := get_parent_node_3d()
	if eltern != null:
		global_position = eltern.global_position
	if _masken.is_empty():
		return
	_phase += delta * TEMPO
	for i in _masken.size():
		var winkel := _phase + TAU * float(i) / float(_masken.size())
		var maske := _masken[i]
		maske.position = Vector3(sin(winkel) * RADIUS,
				HOEHE + sin(winkel * 2.0) * NICK, cos(winkel) * RADIUS)
		# Die Maske schaut nach AUSSEN, vom Spieler weg. Mit `winkel`
		# allein zeigte ihre Vorderseite zur Kreismitte – man sah immer
		# nur Rückseiten.
		maske.rotation = Vector3(0.0, winkel + PI, 0.0)


func _auf_schutz(anzahl: int) -> void:
	_setze_anzahl(anzahl)


func _setze_anzahl(anzahl: int) -> void:
	anzahl = clampi(anzahl, 0, GameState.SCHUTZ_MAX)
	if anzahl == _anzahl:
		return
	_anzahl = anzahl
	for maske in _masken:
		maske.queue_free()
	_masken.clear()
	for i in anzahl:
		var maske := _baue_maske()
		add_child(maske)
		_masken.append(maske)
		# Neu dazugekommene Maske kurz aufploppen lassen.
		maske.scale = Vector3.ZERO
		var ablauf := create_tween()
		ablauf.tween_property(maske, "scale", Vector3.ONE, 0.28) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Eine Maske: gewölbte Platte mit Brauen, zwei Augen und einem Mund.
## Bewusst kantig und in wenigen Teilen – sie ist zwei Handbreit groß und
## wird meist in Bewegung gesehen.
func _baue_maske() -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Maske"

	var holz := Materialbibliothek.leuchtend(Farben.KISTE_SCHUTZ, 0.5)
	var dunkel := Materialbibliothek.einfarbig(
			Farben.KISTE_SCHUTZ.darkened(0.75), 0.4, 0.2)
	var zier := Materialbibliothek.leuchtend(Farben.SPIN_RING, 1.1)

	var h := MASKENHOEHE
	_teil(wurzel, Vector3(h * 0.74, h, h * 0.16), Vector3.ZERO, holz)
	# Kinn: schmaler, damit die Maske nicht wie ein Brett aussieht
	_teil(wurzel, Vector3(h * 0.46, h * 0.24, h * 0.16),
			Vector3(0.0, -h * 0.56, 0.0), holz)
	# Stirnband
	_teil(wurzel, Vector3(h * 0.80, h * 0.14, h * 0.20),
			Vector3(0.0, h * 0.34, 0.01), zier)
	# Augen
	for seite in [-1.0, 1.0]:
		_teil(wurzel, Vector3(h * 0.20, h * 0.16, h * 0.06),
				Vector3(seite * h * 0.18, h * 0.08, h * 0.10), dunkel)
	# Mund
	_teil(wurzel, Vector3(h * 0.34, h * 0.10, h * 0.06),
			Vector3(0.0, -h * 0.26, h * 0.10), dunkel)
	return wurzel


func _teil(elternteil: Node3D, groesse: Vector3, ort: Vector3,
		stoff: Material) -> void:
	var teil := MeshInstance3D.new()
	var kasten := BoxMesh.new()
	kasten.size = groesse
	teil.mesh = kasten
	teil.position = ort
	teil.material_override = stoff
	teil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(teil)
