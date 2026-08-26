extends Area3D
class_name Stacheln
## Stachelfeld: spitze Metallkegel auf einer rechteckigen Grundplatte.
##
## Berührt der Spieler die Stacheln, ruft das Feld `schaden_nehmen()`.
## Mit `einfahrbar = true` fahren die Stacheln im Takt ein und aus und
## sind nur im ausgefahrenen Zustand tödlich.

## Kantenlängen der Grundfläche in Metern (X mal Z).
@export var flaeche := Vector2(3.0, 3.0):
	set(wert):
		flaeche = wert
		if is_inside_tree():
			_aufbauen()
			_form_anpassen()

## Höhe der einzelnen Kegel.
@export_range(0.2, 2.0, 0.05) var stachel_hoehe := 0.7:
	set(wert):
		stachel_hoehe = wert
		if is_inside_tree():
			_aufbauen()
			_form_anpassen()

## Abstand der Kegel zueinander.
@export_range(0.3, 2.0, 0.05) var abstand := 0.6:
	set(wert):
		abstand = wert
		if is_inside_tree():
			_aufbauen()

## Rostige Stacheln statt blankem Metall.
@export var rostig := true
## Farbe der Zacken. Leer = Vorgabe nach `rostig`. In einem Schneelevel
## sehen rostbraune Stacheln aus wie Lava; dort wird hier Eis gesetzt.
@export var eigenfarbe: Color = Color(0, 0, 0, 0)

## Fahren die Stacheln im Takt ein und aus?
@export var einfahrbar := false

## Dauer eines vollen Zyklus (aus, warten, ein, warten) in Sekunden.
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0,
## damit mehrere Taktgeber nebeneinander ein lernbares Muster ergeben.
@export_range(0.5, 10.0, 0.1) var takt := 2.0

## Zeitversatz, damit mehrere Felder versetzt takten.
@export_range(0.0, 10.0, 0.05) var versatz := 0.0


## Zackenfarbe: eigene Farbe, sonst Rost bzw. blankes Eisen.
func _farbe() -> Color:
	if eigenfarbe.a > 0.0:
		return eigenfarbe
	return ROST if rostig else Farben.KISTE_EISEN

const ROST := Color(0.46, 0.28, 0.17)
## Anteil des Takts, den das Ein- bzw. Ausfahren dauert.
const FAHRZEIT := 0.2

@onready var _kollision: CollisionShape3D = $Kollision

var _platte: MeshInstance3D = null
var _feld: MultiMeshInstance3D = null
var _zeit := 0.0
## 0 = ganz eingefahren, 1 = ganz ausgefahren.
var _ausfahrgrad := 1.0


func _ready() -> void:
	add_to_group("gefahren")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	_zeit = versatz
	_aufbauen()
	_form_anpassen()
	if einfahrbar:
		_ausfahrgrad = 0.0
		_feld_versetzen()


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	_baue_platte()
	_baue_kegel()


## Dünne Grundplatte, auf der die Kegel sitzen.
func _baue_platte() -> void:
	if _platte == null:
		_platte = MeshInstance3D.new()
		_platte.name = "Platte"
		add_child(_platte)
	var quader := BoxMesh.new()
	quader.size = Vector3(flaeche.x, 0.12, flaeche.y)
	_platte.mesh = quader
	_platte.position = Vector3(0.0, 0.06, 0.0)
	_platte.material_override = Materialbibliothek.metall(
			_farbe().darkened(0.35))


## Kegelfeld als MultiMesh – ein Zeichenaufruf für alle Stacheln.
func _baue_kegel() -> void:
	if _feld == null:
		_feld = MultiMeshInstance3D.new()
		_feld.name = "Kegel"
		add_child(_feld)

	var kegel := CylinderMesh.new()
	kegel.top_radius = 0.0
	kegel.bottom_radius = maxf(abstand * 0.36, 0.06)
	kegel.height = stachel_hoehe
	kegel.radial_segments = 6
	kegel.rings = 1

	var spalten := maxi(int(flaeche.x / abstand), 1)
	var reihen := maxi(int(flaeche.y / abstand), 1)
	var schritt_x := flaeche.x / float(spalten)
	var schritt_z := flaeche.y / float(reihen)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = kegel
	mm.instance_count = spalten * reihen

	var i := 0
	for sx in spalten:
		for sz in reihen:
			var x := -flaeche.x * 0.5 + schritt_x * (float(sx) + 0.5)
			var z := -flaeche.y * 0.5 + schritt_z * (float(sz) + 0.5)
			# Etwas Streuung, damit das Feld nicht wie ein Raster wirkt.
			x += randf_range(-schritt_x, schritt_x) * 0.12
			z += randf_range(-schritt_z, schritt_z) * 0.12
			var hoehe := stachel_hoehe * randf_range(0.85, 1.0)
			var t := Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, hoehe / stachel_hoehe, 1.0)),
					Vector3(x, 0.12 + hoehe * 0.5, z))
			mm.set_instance_transform(i, t)
			i += 1

	_feld.multimesh = mm
	_feld.material_override = Materialbibliothek.metall(_farbe())
	_feld.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Kollisionsform umschließt Platte und Kegel.
func _form_anpassen() -> void:
	if _kollision == null:
		return
	var form := BoxShape3D.new()
	form.size = Vector3(flaeche.x, stachel_hoehe + 0.12, flaeche.y)
	_kollision.shape = form
	_kollision.position = Vector3(0.0, (stachel_hoehe + 0.12) * 0.5, 0.0)


# ---------------------------------------------------------------- Takt

func _physics_process(delta: float) -> void:
	if einfahrbar:
		_zeit += delta
		_ausfahrgrad = _takt_wert(fmod(_zeit, takt) / takt)
		_feld_versetzen()

	if not toedlich_jetzt():
		return
	for koerper in get_overlapping_bodies():
		if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
			koerper.schaden_nehmen()


## Verlauf über einen Takt: ausfahren, oben bleiben, einfahren, unten bleiben.
func _takt_wert(p: float) -> float:
	if p < FAHRZEIT:
		return p / FAHRZEIT
	if p < 0.5:
		return 1.0
	if p < 0.5 + FAHRZEIT:
		return 1.0 - (p - 0.5) / FAHRZEIT
	return 0.0


## Schiebt das Kegelfeld je nach Ausfahrgrad in die Platte hinein.
func _feld_versetzen() -> void:
	if _feld == null:
		return
	_feld.position.y = -(1.0 - _ausfahrgrad) * (stachel_hoehe + 0.14)


## True, wenn die Stacheln gerade Schaden machen.
func toedlich_jetzt() -> bool:
	return not einfahrbar or _ausfahrgrad > 0.55
