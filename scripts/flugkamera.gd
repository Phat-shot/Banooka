extends Camera3D
class_name Flugkamera
## Verfolgerkamera für den Flugmodus (Level 22 „Wolkenjagd").
##
## Warum nicht `CorridorCamera`: Die hängt an einem `Path3D` und rechnet
## in Weltkoordinaten – Höhe über dem Weg, Abstand entlang der Kurve,
## seitlicher Versatz. Im Flugmodus gibt es keinen Weg, keine Strecke und
## kein „oben" der Welt, das für die Kamera gälte. Und ihr `look_at(...,
## Vector3.UP)` würde die Rolle der Maschine gerade wieder herausrechnen,
## also genau das wegnehmen, was den Flug ausmacht.
##
## Diese Kamera sitzt deshalb IM FLUGZEUGSYSTEM: Ihr Versatz ist ein
## fester Punkt hinter und über dem Cockpit, und ihre Hochachse ist die
## Hochachse der Maschine. Wer in die Kurve legt, legt das ganze Bild mit –
## und der eigene Flügel wandert unten durchs Bild. Genau das ist das
## Erkennungsmerkmal des Vorbilds 5-2.
##
## Nachgezogen wird beides getrennt: der Ort über eine Strecke, die Lage
## über eine Kugelinterpolation. Beides träge, aber nicht gleich träge –
## die Lage darf schneller folgen als der Ort, sonst hinkt das Bild in
## einer engen Kurve sichtbar hinter der Maschine her.

## Ziel. Bleibt das Feld leer, wird der erste Knoten der Gruppe
## "spieler" verwendet.
@export var ziel_pfad: NodePath

## Versatz im Flugzeugsystem: x nach rechts, y nach oben, z nach hinten.
##
## 2,5 m über und 7 m hinter dem Cockpit. Der Doppeldecker misst über
## die Tragflächen 4,7 m – aus 7 m Abstand füllt er rund ein Drittel der
## Bildbreite, und die obere Fläche steht knapp unter der Bildmitte.
@export var versatz := Vector3(0.0, 2.5, 7.0)

## Wie weit vor der Maschine der Blickpunkt liegt.
##
## Weit, mit Absicht: Ein Blickpunkt dicht an der Nase lässt die Kamera
## bei jedem Nicken mitkippen. Auf 14 m dreht sich das Bild ruhig, und die
## Maschine sitzt tief genug im Bild, dass man sieht, wohin man fliegt.
@export var blick_vorlauf := 14.0

## Glättung des Ortes: kleinerer Wert = härteres Nachziehen.
@export var glaettung := 0.0015
## Glättung der Lage. Kleiner als `glaettung`, die Kamera dreht also
## schneller, als sie fährt.
@export var dreh_glaettung := 0.00008

## Wie weit die Kamera die Rolle mitmacht.
##
## 1,0 hieße: starr am Flugzeug, der Horizont steht senkrecht, sobald man
## voll in der Kurve liegt. Das ist im Standbild richtig und in Bewegung
## schwer zu lesen – man verliert das Gefühl dafür, wo unten ist. 0,85
## lässt den Horizont bei voller Rolle noch rund 8° stehen: genug, dass
## das Auge einen Anhalt behält, und wenig genug, dass die Kurve als
## Schräglage ankommt und nicht als Schwenk.
@export_range(0.0, 1.0, 0.01) var roll_anteil := 0.85

var _ziel: Node3D
## Beim ersten Bild darf die Kamera nicht erst hinfahren – sonst startet
## der Spieler außerhalb des Bildes.
var _muss_springen := true


func _ready() -> void:
	# Die Kamera wird selbst im Bildtakt gesetzt. Godot darf sie deshalb
	# nicht zusätzlich interpolieren, sonst hinkt sie einen Physikschritt
	# hinterher und alles fühlt sich schwammig an.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_ziel_suchen()
	sofort_ausrichten()


func _ziel_suchen() -> void:
	if not ziel_pfad.is_empty():
		_ziel = get_node_or_null(ziel_pfad) as Node3D
	if _ziel == null:
		_ziel = get_tree().get_first_node_in_group("spieler") as Node3D


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollstellung.
##
## PFLICHT für den Flugmodus: `Flieger.respawn()` ruft sie auf, und ohne
## sie zöge die Kamera nach einem Absturz quer durch den halben Luftraum
## zum Startpunkt zurück.
func sofort_ausrichten() -> void:
	_muss_springen = true
	_ziel_suchen()
	if _ziel != null and is_instance_valid(_ziel):
		_folgen(1.0)


func _process(delta: float) -> void:
	if _ziel == null or not is_instance_valid(_ziel):
		_ziel_suchen()
		return
	_folgen(delta)


func _folgen(delta: float) -> void:
	# Interpoliert lesen: `global_transform` liefert die Stellung des
	# letzten Physikschritts, also eine Treppe mit 60 Stufen je Sekunde.
	var lage := _ziel.get_global_transform_interpolated()
	var basis := lage.basis.orthonormalized()

	var wunsch := lage.origin + basis * versatz
	var blickziel := lage.origin - basis.z * blick_vorlauf
	var richtung := blickziel - wunsch
	if richtung.length_squared() < 0.000001:
		return

	# Die Hochachse zwischen Welt und Flugzeug mischen – das ist der
	# ganze `roll_anteil`.
	var oben := Vector3.UP.lerp(basis.y, roll_anteil)
	if oben.length_squared() < 0.0001 or absf(oben.normalized().dot(richtung.normalized())) > 0.999:
		# Blick und Hochachse fast parallel: Dann taugt `looking_at` nicht.
		# Kommt bei NICK_MAX = 0,62 rad eigentlich nie vor; die Zeile steht
		# hier, damit ein Ausreißer die Kamera nicht verdreht.
		oben = basis.y
	var soll := Transform3D(Basis.looking_at(richtung, oben.normalized()), wunsch)

	if _muss_springen:
		global_transform = soll
		_muss_springen = false
		return

	var ort := global_position.lerp(soll.origin, 1.0 - pow(glaettung, delta))
	var dreh := Quaternion(global_transform.basis.orthonormalized()).slerp(
			Quaternion(soll.basis), 1.0 - pow(dreh_glaettung, delta))
	global_transform = Transform3D(Basis(dreh), ort)
