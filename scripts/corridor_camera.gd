extends Camera3D
class_name KorridorKamera
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
##
## Dazu drei Dinge fürs Gefühl, alle im Ruhezustand neutral (ein Standbild
## sieht genauso aus wie ohne sie):
##   Wackeln   – `erschuettern(staerke)` nach dem Kameravertrag in
##               scripts/effekte.gd. Nur Drehung, kein Versatz: Glättung
##               und Wandstrahl (`_freie_sicht`) sehen davon nichts.
##   Tempo     – das Sichtfeld weitet sich bei hohem Tempo und im Slide um
##               wenige Grad; Kart und Wildkatze bekommen das mit, weil
##               das Tempo am Ort gemessen wird, nicht an der Figur.
##   Handys    – auf sehr breiten Bildschirmen (20:9) wird das senkrechte
##               Sichtfeld so weit gesenkt, dass das waagerechte nicht
##               über `WAAGRECHT_HOECHSTENS` wächst – sonst Fischauge.
##
## Die statischen Helfer `wackelbasis()` und `sichtfeld_begrenzt()` teilen
## sich Folge- und Flugkamera, damit ein Stoß überall gleich aussieht.

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
## Ebenen, die der Sichtstrahl in `_freie_sicht` prüft. Vorgabe 1|8 – feste
## Levelgeometrie und Sichtsperre der Deko (`LevelWerkzeuge.SICHTSPERRE`),
## genau der Wert, der dort bis dahin fest stand. Ein Level, in dessen
## Kamerabahn nichts Festes stehen darf, nimmt 8: Dann holt keine Kiste und
## keine Terrasse die Kamera heran, nur ausdrücklich gesetzte Sichtsperren
## (Level 05, Rückblick; Baukasten §4 Nr. 5). Wer das wählt, belegt es mit
## einer Freiraumprobe.
@export var sicht_maske := 1 | 8

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

# --- Wackeln (Kameravertrag: scripts/effekte.gd) ---
## Größter Ausschlag bei Wucht 1, in Radiant: Nicken rund 3,4°, Rollen
## rund 2°. Der Ausschlag wächst mit Wucht², ein Bauchplatscher (0,45)
## nickt also nur um gut 0,7° – spürbar, ohne dass das Bild verschwimmt.
##
## Bewusst KEIN Gieren: Die Steuerung ist kamerarelativ und liest die
## waagerechte Blickrichtung der Kamera. Ein Gieren ließe den Stick für
## einen Moment schief greifen. Nicken ändert diese Richtung gar nicht,
## Rollen bei rund 20° Neigung nur um Bruchteile eines Grades.
const WUCHT_NICKEN := 0.06
const WUCHT_ROLLEN := 0.035
## Abklingen je Sekunde. Ein Bauchplatscher ist nach gut 0,2 s ruhig.
const WUCHT_ABKLINGEN := 2.0

# --- Sichtfeld ---
## Zusätzliches Sichtfeld in Grad bei hohem Tempo. Ab `TEMPO_AB` m/s –
## knapp über dem Lauftempo 8,5, damit bloßes Laufen das Bild nie atmen
## lässt – voll ab `TEMPO_VOLL` (Slide 13,5, Wildkatze und Kart bis 21).
const SCHUB_TEMPO := 3.0
const TEMPO_AB := 9.0
const TEMPO_VOLL := 15.0
## Im Slide kommt das dazu: Der Ruck nach vorn soll im Bild ankommen.
## Zusammen bleibt es unter 5° – mehr macht auf Dauer übel.
const SCHUB_SLIDE := 2.0
## Größtes waagerechtes Sichtfeld in Grad. Bei 16:9 und 60° senkrecht
## sind es 91°, erst ab etwa 19:9 greift der Deckel.
const WAAGRECHT_HOECHSTENS := 100.0

## Am Anfang der Kurve kann die Kamera nicht `abstand` Meter hinter der
## Figur stehen – dahinter ist kein Weg, oft nur das Startportal. Sie
## steht dann dicht hinter ihr und hoch darüber, blickte aber weiter
## `blick_vorlauf` voraus: Am Levelstart (Strecke 2) und nach jedem Tod
## vor dem ersten Checkpoint lag die Figur ganz unter dem Bildrand. Der
## Blickpunkt rückt deshalb heran, quadratisch mit dem fehlenden Abstand:
## an der Startstelle kräftig, bis die Figur im unteren Bilddrittel steht,
## ein paar Meter weiter kaum noch – sonst sähe man dort nur noch Boden
## statt der Schlucht. Ab Strecke `abstand` ist alles wie immer.
## 0,75 heißt an der Startstelle (2 m, 7,5 m fehlen): Blick 1,6 m statt
## 6 m voraus, die Füße stehen gut 10° über dem unteren Bildrand.
const START_HERANHOLEN := 0.75

var _wucht := 0.0
var _wucht_zeit := 0.0
## Hat `_folgen()` in diesem Bild die Blickrichtung neu gesetzt? Nur dann
## darf gewackelt werden – sonst addierte sich der Ausschlag Bild für Bild.
var _blick_gesetzt := false
## Sichtfeld laut Szene, danach mit Handy-Deckel, zuletzt selbst gesetzt.
var _szenen_fov := 60.0
var _grund_fov := 60.0
var _fov_gesetzt := -1.0
## Aktueller Tempo-Zuschlag in Grad und das geglättete Tempo.
var _schub := 0.0
var _tempo_glatt := 0.0
var _letzter_ort := Vector3.INF


func _ready() -> void:
	# Die Kamera wird selbst im Bildtakt gesetzt. Godot darf sie deshalb
	# nicht zusätzlich interpolieren, sonst hinkt sie einen Physikschritt
	# hinterher und alles fühlt sich schwammig an.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_szenen_fov = fov
	get_viewport().size_changed.connect(_grund_fov_rechnen)
	_grund_fov_rechnen()
	_ziel_suchen()
	sofort_ausrichten()


## Setzt die Kamera ohne Nachziehen direkt an ihre Sollposition.
## Wird beim Levelstart und nach dem Respawn aufgerufen.
func sofort_ausrichten() -> void:
	_muss_springen = true
	_strecke = -1.0
	_wucht = 0.0
	_schub = 0.0
	_tempo_glatt = 0.0
	_letzter_ort = Vector3.INF
	_fov_setzen(_grund_fov)
	_ziel_suchen()
	if _ziel != null and is_instance_valid(_ziel):
		_folgen(1.0)


## Kamerawackeln nach dem Kameravertrag (scripts/effekte.gd): Das
## Maximum zählt, nicht die Summe – sonst schaukelte eine Kistenkette die
## Kamera zum Erdbeben auf. Abstand und `Effekte.reduziert` hat der
## Aufrufer schon verrechnet.
func erschuettern(staerke: float) -> void:
	_wucht = clampf(maxf(_wucht, staerke), 0.0, 1.0)


## Drehung eines Wackelns der Wucht `wucht` (0..1) zur Zeit `zeit`, als
## Basis zum Anhängen im Kamerasystem (`basis * wackelbasis(...)`).
## Zwei Nick-Frequenzen gegeneinander verstimmt, damit es nicht wie ein
## Pendel tickt; ein Rollen darüber gibt dem Stoß Gewicht.
static func wackelbasis(wucht: float, zeit: float) -> Basis:
	var k := wucht * wucht
	var nicken := WUCHT_NICKEN * k \
			* (sin(zeit * 37.0) + 0.5 * sin(zeit * 71.0 + 1.3)) / 1.5
	var rollen := WUCHT_ROLLEN * k * sin(zeit * 29.0 + 2.1)
	return Basis(Vector3.RIGHT, nicken) * Basis(Vector3.FORWARD, rollen)


## Senkrechtes Sichtfeld `fov_szene`, gedeckelt für breite Bildschirme:
## Das waagerechte Sichtfeld wächst bei KEEP_HEIGHT mit dem Seitenverhältnis
## – auf einem 20:9-Handy wären aus 60° senkrecht 104° waagerecht geworden,
## ein Fischauge, in dem die Figur winzig wird. Gedeckelt sind es dort
## rund 56° senkrecht. Bei 16:9 ändert sich nichts.
static func sichtfeld_begrenzt(kamera: Camera3D, fov_szene: float) -> float:
	if not kamera.is_inside_tree():
		return fov_szene
	var groesse := kamera.get_viewport().get_visible_rect().size
	if groesse.x < 1.0 or groesse.y < 1.0:
		return fov_szene
	if kamera.keep_aspect == Camera3D.KEEP_WIDTH:
		return minf(fov_szene, WAAGRECHT_HOECHSTENS)
	var seiten := groesse.x / groesse.y
	var hoechstens := rad_to_deg(2.0 * atan(
			tan(deg_to_rad(WAAGRECHT_HOECHSTENS) * 0.5) / seiten))
	return minf(fov_szene, hoechstens)


## Wie viele Meter der Kamera am Kurvenanfang zum vollen Abstand fehlen.
## Auf einem Rundkurs (Level 06: der letzte Punkt liegt knapp 6 m neben
## dem ersten) fehlt nichts – dort geht es hinter dem Start weiter, und
## die Kamera soll nicht in jeder Runde nicken. Ein Korridorlevel endet
## Hunderte Meter von seinem Anfang entfernt.
func _fehlstrecke(kurve: Curve3D, strecke: float) -> float:
	var ende := kurve.point_count - 1
	if kurve.get_point_position(0).distance_to(kurve.get_point_position(ende)) < 12.0:
		return 0.0
	return maxf(abstand - strecke, 0.0)


func _grund_fov_rechnen() -> void:
	_grund_fov = sichtfeld_begrenzt(self, _szenen_fov)
	_fov_setzen(_grund_fov + _schub)


func _fov_setzen(wert: float) -> void:
	fov = wert
	# Zurücklesen statt `wert` merken: Der Setter klemmt auf 1..179.
	_fov_gesetzt = fov


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
	_sichtfeld_fuehren(delta)
	_wackeln(delta)


## Weitet das Sichtfeld mit dem Tempo. Gemessen wird am Weg, den das Ziel
## im Bild zurücklegt – so gilt es für jede Figur, auch für die, die ihre
## `velocity` nie setzen (Reiter, Rennfahrer).
func _sichtfeld_fuehren(delta: float) -> void:
	# Hat jemand anderes das Sichtfeld gesetzt (ein Werkzeug, ein Level),
	# gilt das als neue Grundlage, statt jedes Bild überschrieben zu werden.
	if _fov_gesetzt >= 0.0 and not is_equal_approx(fov, _fov_gesetzt):
		_szenen_fov = fov
		_grund_fov = sichtfeld_begrenzt(self, _szenen_fov)
	if delta <= 0.0:
		return
	var p := Bildtakt.ort(_ziel)
	var tempo := _tempo_glatt
	if _letzter_ort.is_finite():
		var weg := p - _letzter_ort
		weg.y = 0.0
		# Schneller als 60 m/s ist nichts im Spiel – das ist ein Versetzen
		# (Checkpoint, Portal), kein Tempo.
		var gemessen := weg.length() / delta
		if gemessen < 60.0:
			tempo = gemessen
	_letzter_ort = p
	_tempo_glatt = lerpf(_tempo_glatt, tempo, 1.0 - exp(-10.0 * delta))

	var ziel := SCHUB_TEMPO * clampf(
			(_tempo_glatt - TEMPO_AB) / (TEMPO_VOLL - TEMPO_AB), 0.0, 1.0)
	if _ziel is Spieler and (_ziel as Spieler).sliding > 0.0:
		ziel += SCHUB_SLIDE
	# Schnell auf, langsam zurück: Der Schub soll als Ruck ankommen und
	# nicht als Pumpen, wenn Slides kurz hintereinander folgen.
	var rate := 8.0 if ziel > _schub else 3.0
	_schub = lerpf(_schub, ziel, 1.0 - exp(-rate * delta))
	if absf(_schub) < 0.01 and ziel <= 0.0:
		_schub = 0.0
	_fov_setzen(_grund_fov + _schub)


## Legt das Wackeln über die frisch gesetzte Blickrichtung. Die Drehung
## geht bei jedem `look_at` wieder verloren; es sammelt sich nichts an.
func _wackeln(delta: float) -> void:
	if _wucht <= 0.0:
		return
	_wucht_zeit += delta
	if _blick_gesetzt:
		basis = basis * wackelbasis(_wucht, _wucht_zeit)
	_wucht = maxf(_wucht - delta * WUCHT_ABKLINGEN, 0.0)


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
	# Sichtsperre der Deko – siehe LevelWerkzeuge.SICHTSPERRE und
	# `sicht_maske` (Vorgabe 1 | 8).
	var frage := PhysicsRayQueryParameters3D.create(blickziel, wunsch, sicht_maske)
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
	# Den gezeichneten Ort lesen (Bildtakt.ort): `global_position` liefert
	# die Stellung des letzten Physikschritts, also eine Treppe mit 60
	# Stufen je Sekunde. Die Kamera läuft im Bildtakt und würde diese
	# Treppe sonst getreu nachfahren – genau das nimmt man als Ruckeln der
	# Umgebung wahr.
	var p := Bildtakt.ort(_ziel)
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
		# Exponentiell statt `delta * hoehe_folge`: Das lief bei 30 und 144
		# Bildern je Sekunde verschieden schnell nach. Bei 60 ist es gleich.
		var ziel_hoehe := p.y - mitte.y
		if _muss_springen:
			_hoehe_versatz = ziel_hoehe
		else:
			_hoehe_versatz = lerpf(_hoehe_versatz, ziel_hoehe,
					1.0 - exp(-hoehe_folge * delta))

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
		# Am Kurvenanfang rückt der Blickpunkt heran (START_HERANHOLEN), aber
		# nie näher als anderthalb Meter vor die Figur – sonst blickte die
		# Kamera bei Strecke 0 senkrecht nach unten.
		var fehlt := _fehlstrecke(kurve, strecke)
		var vorlauf := maxf(blick_vorlauf - START_HERANHOLEN * fehlt * fehlt
				/ maxf(abstand, 0.1), minf(blick_vorlauf, 1.5))
		var blick_hinten := _kurve_knoten.to_global(
				kurve.sample_baked(clampf(strecke + vorlauf, 0.0, laenge)))
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
	_blick_gesetzt = global_position.distance_squared_to(blickziel) > 0.001
	if _blick_gesetzt:
		look_at(blickziel, Vector3.UP)
