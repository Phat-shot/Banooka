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

## Die Figur, an der die Masken hängen. Wird beim Eintreten gemerkt:
## `get_parent_node_3d()` liefert bei einem `top_level`-Knoten immer null,
## weil Godot dessen Elternverbindung im Transformbaum kappt. Genau daran
## scheiterte das Mitziehen – die Masken blieben am Startpunkt stehen.
var _traeger: Node3D

var _masken: Array[Node3D] = []
var _phase := 0.0
var _anzahl := -1


func _ready() -> void:
	# Erst den Träger merken, dann abkoppeln – nach `top_level = true`
	# ist die Elternverbindung im Transformbaum weg.
	_traeger = get_parent() as Node3D
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true          ## Position folgt, Drehung nicht
	set_process(true)
	GameState.schutz_geaendert.connect(_auf_schutz)
	_setze_anzahl(GameState.schutz_anzeige())


func _process(delta: float) -> void:
	if is_instance_valid(_traeger):
		# Interpoliert lesen, sonst hüpfen die Masken im Physiktakt neben
		# einer Figur her, die weich gezeichnet wird.
		global_position = _traeger.get_global_transform_interpolated().origin
	else:
		_traeger = get_parent() as Node3D
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


## Gleicht die Masken an die Zahl der Ladungen an. Nur die Differenz
## wird gebaut oder abgeräumt: Beim Verlust einer Ladung ploppen die
## übrigen nicht neu auf – sonst sähe ein Treffer aus wie ein Geschenk.
func _setze_anzahl(anzahl: int) -> void:
	anzahl = clampi(anzahl, 0, GameState.SCHUTZ_MAX)
	if anzahl == _anzahl:
		return
	var erstes_mal := _anzahl < 0
	_anzahl = anzahl
	while _masken.size() > anzahl:
		var weg: Node3D = _masken.pop_back()
		if not erstes_mal and weg.is_inside_tree():
			_zerspringen(weg.global_position)
		weg.queue_free()
	while _masken.size() < anzahl:
		var maske := _baue_maske()
		add_child(maske)
		_masken.append(maske)
		# Neu dazugekommene Maske kurz aufploppen lassen.
		maske.scale = Vector3.ZERO
		var ablauf := create_tween()
		ablauf.tween_property(maske, "scale", Vector3.ONE, 0.28) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Eine verlorene Maske zerspringt: Bretter in ihrem Holz, Funken in der
## Schutzfarbe, ein kurzer Blitz. Vorher verschwand sie einfach – den
## Verlust sah nur, wer die Masken gezählt hatte.
func _zerspringen(pos: Vector3) -> void:
	Effekte.aufblitzen(self, pos, Farben.KISTE_SCHUTZ.lightened(0.5), 1.0, 0.12)
	Effekte.funken(self, pos, Farben.KISTE_SCHUTZ, 12, 4.0)
	Effekte.splitter(self, pos, Materialbibliothek.leuchtend(Farben.KISTE_SCHUTZ, 0.5), 5)


## Eine Maske: gewölbte Platte mit Brauen, zwei Augen und einem Mund.
## Bewusst kantig und in wenigen Teilen – sie ist zwei Handbreit groß und
## wird meist in Bewegung gesehen.
##
## Alle Masken teilen EIN Netz mit drei Flächen, eine je Material. Vorher
## waren es sechs Knoten mit je eigenem Würfel: sechs Draw-Calls je Maske,
## jetzt drei.
func _baue_maske() -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Maske"
	var teil := MeshInstance3D.new()
	teil.mesh = _maskennetz()
	teil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wurzel.add_child(teil)
	return wurzel


static var _netz: ArrayMesh = null


static func _maskennetz() -> ArrayMesh:
	if _netz != null:
		return _netz
	var holz := Materialbibliothek.leuchtend(Farben.KISTE_SCHUTZ, 0.5)
	var dunkel := Materialbibliothek.einfarbig(
			Farben.KISTE_SCHUTZ.darkened(0.75), 0.4, 0.2)
	var zier := Materialbibliothek.leuchtend(Farben.SPIN_RING, 1.1)

	var h := MASKENHOEHE
	var netz := ArrayMesh.new()
	_flaeche(netz, holz, [
		# Platte
		[Vector3(h * 0.74, h, h * 0.16), Vector3.ZERO],
		# Kinn: schmaler, damit die Maske nicht wie ein Brett aussieht
		[Vector3(h * 0.46, h * 0.24, h * 0.16), Vector3(0.0, -h * 0.56, 0.0)],
	])
	# Stirnband
	_flaeche(netz, zier, [
		[Vector3(h * 0.80, h * 0.14, h * 0.20), Vector3(0.0, h * 0.34, 0.01)],
	])
	# Augen und Mund
	_flaeche(netz, dunkel, [
		[Vector3(h * 0.20, h * 0.16, h * 0.06), Vector3(-h * 0.18, h * 0.08, h * 0.10)],
		[Vector3(h * 0.20, h * 0.16, h * 0.06), Vector3(h * 0.18, h * 0.08, h * 0.10)],
		[Vector3(h * 0.34, h * 0.10, h * 0.06), Vector3(0.0, -h * 0.26, h * 0.10)],
	])
	_netz = netz
	return netz


## Hängt eine Fläche aus Quadern (je [Größe, Mitte]) mit einem Material an.
static func _flaeche(netz: ArrayMesh, stoff: Material, kaesten: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for kasten: Array in kaesten:
		var groesse: Vector3 = kasten[0]
		var mitte: Vector3 = kasten[1]
		var quader := BoxMesh.new()
		quader.size = groesse
		st.append_from(quader, 0, Transform3D(Basis.IDENTITY, mitte))
	st.set_material(stoff)
	st.commit(netz)
