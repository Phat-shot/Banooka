extends Camera3D
## Korridor-Kamera: folgt dem Spieler von schräg hinten oben.
##
## Drei Betriebsarten:
##   ohne Pfad     – gerader Korridor Richtung -Z (Werte 1:1 aus der Demo)
##   mit Pfad      – die Kamera fährt auf einem Path3D hinter dem Spieler
##                   her und folgt damit auch Kurven im Levelverlauf.
##   Seitenansicht – die Kamera stellt sich quer neben den Weg; das Bild
##                   wird zum 2D-Scroller. Die Steuerung stimmt dabei von
##                   selbst, weil sie kamerarelativ ist: Was auf dem Schirm
##                   nach rechts geht, geht auch am Stick nach rechts.

## Ziel-Knoten. Bleibt das Feld leer, wird der erste Knoten
## aus der Gruppe "spieler" verwendet.
@export var ziel_pfad: NodePath
## Optionaler Path3D, dem der Korridor folgt. Ohne Pfad: gerader Korridor.
@export var kurve_pfad: NodePath
## Höhe über dem Spieler.
@export var hoehe := 4.2
## Abstand hinter dem Spieler.
@export var abstand := 8.0
## Seitliche Bewegungen werden nur zu diesem Anteil mitgefahren.
##
## 0.0 hieße: Die Kamera bleibt starr auf ihrer Schiene, die Figur wandert
## quer durchs Bild – die klassische, sehr ruhige Lösung, bei der man die
## Figur im engen Korridor aber leicht aus dem Blick verliert. 1.0 hieße:
## Die Figur klebt in der Bildmitte, das Bild wirkt festgeschraubt.
##
## 0.85 hält sie praktisch mittig, lässt einem Ausweichschritt aber noch
## sichtbares Spiel. Das Drehen in Kurven übernimmt ohnehin die Schiene:
## Dort dreht sich die Welt um die Figur, nicht die Kamera um sie herum.
@export var seiten_faktor := 0.85
## Blickpunkt vor dem Spieler.
@export var blick_vorlauf := 4.0
## Glättung: kleinerer Wert = härteres Nachziehen.
@export var glaettung := 0.001
## Wie schnell die Kamera Höhenunterschiede des Spielers nachfährt.
##
## Nicht sofort: Sonst hebt und senkt sich das ganze Bild bei jedem
## Sprung mit, und weil in einem Plattformer dauernd gesprungen wird,
## wackelt es ununterbrochen. Mit diesem Wert braucht die Kamera rund eine
## halbe Sekunde für einen Höhenwechsel – ein Sprung (0,64 s hin und
## zurück) läuft dadurch fast unbemerkt durch, ein echter Anstieg im
## Levelverlauf wird aber sauber mitgenommen.
@export var hoehe_folge := 2.6
## Seitenansicht: Abstand quer zum Weg (0 = normale Verfolgerkamera).
## Das Vorzeichen wählt die Seite.
@export var seitenblick := 0.0
## Höhe der Kamera über dem Spieler in der Seitenansicht.
@export var seitenblick_hoehe := 2.4
## Wie schnell zwischen Verfolger- und Seitenansicht überblendet wird.
## 1,6 heißt rund 0,6 s – länger als ein Sprung (0,64 s hin und zurück),
## damit der Wechsel nicht mitten im Sprung als Ruck erscheint, und kurz
## genug, dass niemand blind durch den halben Abschnitt läuft.
@export var seitenblick_folge := 1.6

var _ziel: Node3D
var _kurve_knoten: Path3D
## Beim ersten Bild darf die Kamera nicht erst hinfahren – sonst startet
## der Spieler außerhalb des Bildes.
var _muss_springen := true
## Nachgezogene Höhe des Spielers über der Wegkurve.
var _hoehe_versatz := 0.0
## Geführte Stelle auf der Kurve. Siehe `_strecke_gefuehrt()`.
var _strecke := -1.0
## Wie weit die Seitenansicht gerade eingeblendet ist (0 = Verfolger,
## 1 = ganz seitlich). Ohne diesen Zwischenwert war der Wechsel ein Sprung:
## Ort UND Blickziel kippten in einem einzigen Bild auf die andere Seite.
var _seiten_grad := 0.0


## Abstand, den die herangeholte Kamera vor der Wand hält.
const SICHT_PUFFER := 0.35
## Näher als das geht sie nie an die Figur – sonst steckt die Linse im Kopf.
const SICHT_MINDEST := 1.4


func _ready() -> void:
	# Die Kamera wird selbst im Bildtakt gesetzt. Godot darf sie deshalb
	# nicht zusätzlich interpolieren, sonst hinkt sie einen Physikschritt
	# hinterher und alles fühlt sich schwammig an.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_ziel_suchen()
	sofort_ausrichten()


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollposition.
## Wird beim Levelstart und nach dem Respawn aufgerufen.
func sofort_ausrichten() -> void:
	_muss_springen = true
	_strecke = -1.0
	_ziel_suchen()
	if _ziel != null and is_instance_valid(_ziel):
		_folgen(1.0)


func _ziel_suchen() -> void:
	if not ziel_pfad.is_empty():
		_ziel = get_node_or_null(ziel_pfad) as Node3D
	if _ziel == null:
		_ziel = get_tree().get_first_node_in_group("spieler") as Node3D
	if _kurve_knoten == null and not kurve_pfad.is_empty():
		_kurve_knoten = get_node_or_null(kurve_pfad) as Path3D


func _process(delta: float) -> void:
	if _ziel == null or not is_instance_valid(_ziel):
		_ziel_suchen()
		return
	_folgen(delta)


## Führt die Stelle auf der Kurve, statt sie jedes Bild neu zu suchen.
##
## `get_closest_offset()` sucht den nächstgelegenen Punkt der Kurve zur
## Spielerposition. Das ist wackelig, sobald der Spieler nicht auf der
## Mittellinie steht: In einer Kurve liegt der nächste Punkt dann je nach
## seitlichem Versatz mal weiter vorn, mal weiter hinten, und im Sprung
## wandert er zusätzlich mit der Flugbahn. Der Wert kann dabei um mehrere
## Meter springen – die Kamera dreht sich dann ruckartig, am auffälligsten
## mitten im Sprung, wo der Spieler ohnehin nichts dagegen tun kann.
##
## Deshalb wird die Stelle geführt: Sie folgt der Messung, darf sich aber
## nur mit begrenztem Tempo ändern. Ein großer Sprung im Messwert ist kein
## echter Ortswechsel, sondern ein Umspringen der Suche – außer bei einem
## Rundkurs, wo der Wert am Rundenende tatsächlich auf null zurückfällt.

## Holt die Kamera heran, wenn etwas zwischen ihr und der Figur steht.
##
## Ohne das steckte sie regelmäßig in der Kulisse: im Torbogen von Level 11
## bei 330 m, in einem Block in Level 12 bei 269 m, im Kolben von Level 20
## bei 296 m – jedes Mal ein vollständig verdecktes Bild. Geprüft wird gegen
## Ebene 1, also die feste Levelgeometrie; Deko ohne Kollision stört nicht.
##
## Der Treffer wird um `SICHT_PUFFER` nach vorn gezogen, damit die Linse
## nicht in der Wand sitzt, die sie gerade noch getroffen hat.
func _freie_sicht(wunsch: Vector3, blickziel: Vector3) -> Vector3:
	var welt := get_world_3d()
	if welt == null:
		return wunsch
	# Ebene 1 ist die feste Levelgeometrie, Ebene 4 (Wert 8) die
	# Sichtsperre der Deko – siehe LevelWerkzeuge.SICHTSPERRE.
	var frage := PhysicsRayQueryParameters3D.create(blickziel, wunsch, 1 | 8)
	# Die Figur selbst steht auf Ebene 2 und ist hier ohnehin nicht dabei;
	# ausgeschlossen wird sie trotzdem, falls ein Level sie umhängt.
	if _ziel != null and _ziel is CollisionObject3D:
		frage.exclude = [(_ziel as CollisionObject3D).get_rid()]
	var treffer := welt.direct_space_state.intersect_ray(frage)
	if treffer.is_empty():
		return wunsch
	var punkt: Vector3 = treffer["position"]
	var weg := punkt - blickziel
	var laenge := weg.length()
	if laenge <= SICHT_MINDEST:
		return wunsch
	return blickziel + weg.normalized() * maxf(laenge - SICHT_PUFFER,
			SICHT_MINDEST)

func _strecke_gefuehrt(gemessen: float, laenge: float, delta: float) -> float:
	if _strecke < 0.0 or _muss_springen:
		_strecke = gemessen
		return _strecke
	var unterschied := gemessen - _strecke
	# Rundenwechsel: Der Messwert fällt um fast die ganze Länge zurück.
	if laenge > 1.0 and absf(unterschied) > laenge * 0.5:
		_strecke = gemessen
		return _strecke
	# Schneller als das Spiel selbst kann sich die Stelle nicht ändern:
	# Lauftempo 8,5 m/s, Slide 13,5, Karts bis 20 – mit Reserve 26 m/s.
	var hoechstens := 26.0 * delta
	_strecke += clampf(unterschied, -hoechstens, hoechstens)
	return _strecke


func _folgen(delta: float) -> void:
	# Interpoliert lesen: `global_position` liefert die Stellung des
	# letzten Physikschritts, also eine Treppe mit 60 Stufen je Sekunde.
	# Die Kamera läuft im Bildtakt und würde diese Treppe sonst getreu
	# nachfahren – genau das nimmt man als Ruckeln der Umgebung wahr.
	var p := _ziel.get_global_transform_interpolated().origin
	var wunsch: Vector3
	var blickziel: Vector3

	if _kurve_knoten != null and _kurve_knoten.curve != null \
			and _kurve_knoten.curve.point_count >= 2:
		# --- Kurvenbetrieb: Kamera fährt auf dem Pfad hinter dem Spieler ---
		var kurve := _kurve_knoten.curve
		var laenge := kurve.get_baked_length()
		var lokal := _kurve_knoten.to_local(p)
		var strecke := _strecke_gefuehrt(kurve.get_closest_offset(lokal),
				laenge, delta)

		var mitte := _kurve_knoten.to_global(kurve.sample_baked(strecke))
		var versatz := p - mitte
		versatz.y = 0.0

		# Höhe getrennt und träge nachziehen – siehe `hoehe_folge`.
		var ziel_hoehe := p.y - mitte.y
		if _muss_springen:
			_hoehe_versatz = ziel_hoehe
		else:
			_hoehe_versatz = lerpf(_hoehe_versatz, ziel_hoehe,
					clampf(delta * hoehe_folge, 0.0, 1.0))

		# Beide Ansichten werden IMMER gerechnet und dann überblendet.
		# Ein `if` an dieser Stelle war der Fehler: Beim Betreten einer
		# Kamerazone kippten Ort und Blickziel in einem einzigen Bild auf
		# die andere Seite – mitten im Sprung sah das aus wie ein Ruck.
		var ziel_grad := 1.0 if absf(seitenblick) > 0.01 else 0.0
		if _muss_springen:
			_seiten_grad = ziel_grad
		else:
			_seiten_grad = move_toward(_seiten_grad, ziel_grad,
					delta * seitenblick_folge)
		# Weiche Kurve statt gerader Fahrt: Der Wechsel setzt sanft an und
		# läuft sanft aus, sonst liest er sich trotz Dauer als Schub.
		var mischung: float = smoothstep(0.0, 1.0, _seiten_grad)

		var vor := _kurve_knoten.to_global(
				kurve.sample_baked(clampf(strecke + 0.5, 0.0, laenge)))
		var zurueck := _kurve_knoten.to_global(
				kurve.sample_baked(clampf(strecke - 0.5, 0.0, laenge)))
		var richtung := (vor - zurueck)
		richtung.y = 0.0
		richtung = richtung.normalized() if richtung.length() > 0.001 \
				else Vector3.FORWARD
		var rechts := richtung.cross(Vector3.UP).normalized()
		# Seitenansicht: quer neben den Weg, auf Höhe der Stelle auf der
		# Kurve – dadurch scrollt das Bild flach mit.
		var wunsch_seite := mitte + rechts * seitenblick \
				+ Vector3.UP * (_hoehe_versatz + seitenblick_hoehe)
		var blick_seite := Vector3(p.x, p.y + 0.9, p.z)

		var kam_punkt := _kurve_knoten.to_global(
				kurve.sample_baked(clampf(strecke - abstand, 0.0, laenge)))
		var wunsch_hinten := kam_punkt + Vector3.UP * (_hoehe_versatz + hoehe) \
				+ versatz * seiten_faktor
		var blick_hinten := _kurve_knoten.to_global(
				kurve.sample_baked(clampf(strecke + blick_vorlauf, 0.0, laenge)))
		# Auch der Blickpunkt folgt der geglätteten Höhe, sonst kippte
		# die Kamera bei jedem Sprung nach oben statt sich zu heben.
		blick_hinten.y = mitte.y + _hoehe_versatz + 1.0
		blick_hinten += versatz * seiten_faktor

		wunsch = wunsch_hinten.lerp(wunsch_seite, mischung)
		blickziel = blick_hinten.lerp(blick_seite, mischung)
	else:
		# --- Gerader Korridor Richtung -Z (Verhalten der HTML-Demo) ---
		wunsch = Vector3(p.x * seiten_faktor, p.y + hoehe, p.z + abstand)
		blickziel = Vector3(p.x * seiten_faktor, p.y + 1.0, p.z - blick_vorlauf)

	wunsch = _freie_sicht(wunsch, blickziel)

	if _muss_springen:
		global_position = wunsch
		_muss_springen = false
	else:
		global_position = global_position.lerp(wunsch, 1.0 - pow(glaettung, delta))
	if global_position.distance_squared_to(blickziel) > 0.001:
		look_at(blickziel, Vector3.UP)
