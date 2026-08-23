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
@export var seiten_faktor := 0.5
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

var _ziel: Node3D
var _kurve_knoten: Path3D
## Beim ersten Bild darf die Kamera nicht erst hinfahren – sonst startet
## der Spieler außerhalb des Bildes.
var _muss_springen := true
## Nachgezogene Höhe des Spielers über der Wegkurve.
var _hoehe_versatz := 0.0


func _ready() -> void:
	_ziel_suchen()
	sofort_ausrichten()


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollposition.
## Wird beim Levelstart und nach dem Respawn aufgerufen.
func sofort_ausrichten() -> void:
	_muss_springen = true
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


func _folgen(delta: float) -> void:
	var p := _ziel.global_position
	var wunsch: Vector3
	var blickziel: Vector3

	if _kurve_knoten != null and _kurve_knoten.curve != null \
			and _kurve_knoten.curve.point_count >= 2:
		# --- Kurvenbetrieb: Kamera fährt auf dem Pfad hinter dem Spieler ---
		var kurve := _kurve_knoten.curve
		var laenge := kurve.get_baked_length()
		var lokal := _kurve_knoten.to_local(p)
		var strecke := kurve.get_closest_offset(lokal)

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

		if absf(seitenblick) > 0.01:
			# Seitenansicht: quer neben den Weg stellen und den Spieler
			# anschauen. Die Kamera fährt mit, bleibt aber auf Höhe seiner
			# Stelle auf der Kurve – dadurch scrollt das Bild flach mit.
			var vor := _kurve_knoten.to_global(
					kurve.sample_baked(clampf(strecke + 0.5, 0.0, laenge)))
			var zurueck := _kurve_knoten.to_global(
					kurve.sample_baked(clampf(strecke - 0.5, 0.0, laenge)))
			var richtung := (vor - zurueck)
			richtung.y = 0.0
			richtung = richtung.normalized() if richtung.length() > 0.001 \
					else Vector3.FORWARD
			var rechts := richtung.cross(Vector3.UP).normalized()
			wunsch = mitte + rechts * seitenblick \
					+ Vector3.UP * (_hoehe_versatz + seitenblick_hoehe)
			blickziel = Vector3(p.x, p.y + 0.9, p.z)
		else:
			var kam_punkt := _kurve_knoten.to_global(
					kurve.sample_baked(clampf(strecke - abstand, 0.0, laenge)))
			wunsch = kam_punkt + Vector3.UP * (_hoehe_versatz + hoehe) \
					+ versatz * seiten_faktor

			blickziel = _kurve_knoten.to_global(
					kurve.sample_baked(clampf(strecke + blick_vorlauf, 0.0, laenge)))
			# Auch der Blickpunkt folgt der geglätteten Höhe, sonst kippte
			# die Kamera bei jedem Sprung nach oben statt sich zu heben.
			blickziel.y = mitte.y + _hoehe_versatz + 1.0
			blickziel += versatz * seiten_faktor
	else:
		# --- Gerader Korridor Richtung -Z (Verhalten der HTML-Demo) ---
		wunsch = Vector3(p.x * seiten_faktor, p.y + hoehe, p.z + abstand)
		blickziel = Vector3(p.x * seiten_faktor, p.y + 1.0, p.z - blick_vorlauf)

	if _muss_springen:
		global_position = wunsch
		_muss_springen = false
	else:
		global_position = global_position.lerp(wunsch, 1.0 - pow(glaettung, delta))
	if global_position.distance_squared_to(blickziel) > 0.001:
		look_at(blickziel, Vector3.UP)
