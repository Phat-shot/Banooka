extends Node3D
class_name Flugziel
## Ein Ziel im Luftraum des Flugmodus (5-2 „Wolkenjagd").
##
## Kein `Gegner`: Die Gegner-Basisklasse patrouilliert auf einer Achse am
## Boden, rechnet mit Draufspringen, Slide und Drehschlag und wirft beim
## Besiegen Früchte aus. Nichts davon passt 26 m über Grund. Ein Flugziel
## kennt genau zwei Ereignisse – es wird abgeschossen, oder es rammt den
## Flieger. Es meldet sich deshalb auch NICHT in der Gruppe "gegner" an,
## damit kein Levelzähler und keine Drehschlag-Reichweite es aufsammelt;
## es steht in der eigenen Gruppe "flugziele", die der `Flugschuss` abfragt.
##
## Die Bahn ist ein Kreis um einen gerechneten Mittelpunkt. Der wird so
## gelegt, dass das Ziel genau dort startet, wo es im Level steht – ein
## Level platziert also einen Punkt, keinen Kreismittelpunkt.

enum Art {
	JAEGER,   ## klein, schnell, kreist eng
	BOMBER,   ## groß, langsam, mehr Panzerung, feuert zurück
	BALLON,   ## steht fast still, gibt beim Abschuss eine Belohnung frei
}

## Art des Ziels. Sie bestimmt Optik, Größe und die Faktoren auf Tempo,
## Bahnradius und Panzerung (siehe `_art_werte`).
@export var art: Art = Art.JAEGER
## Panzerung, also wie viele Treffer es aushält. Der Wert wird beim Start
## auf den Mindestwert der Art angehoben – ein Level, das nur `art = BOMBER`
## setzt, bekommt so von selbst einen zähen Brocken; wer mehr einträgt,
## behält seinen Wert.
@export var panzerung := 1
## Bahngeschwindigkeit in m/s (vor dem Artfaktor).
@export var tempo := 8.0
## Radius der Kreisbahn in Metern (vor dem Artfaktor).
@export var bahn_radius := 14.0
## Höhenausschlag der Bahn in Metern. Das Ziel steigt und sinkt zweimal je
## Runde – eine flache Kreisbahn wäre nach einer halben Runde durchschaut.
@export var bahn_hoehe := 3.0
## Startpunkt auf der Bahn in Radiant. Mehrere Ziele auf ähnlichen Bahnen
## verteilen sich damit, statt im Pulk zu fliegen.
@export var phase := 0.0
## Schießt dieses Ziel zurück?
@export var feuert := false
## Abstand zwischen zwei Schüssen in Sekunden.
@export var feuertakt := 2.5
## Lackfarbe. Alpha 0 heißt „die Art entscheidet" – rote Feindmaschinen,
## gelbe Ballons (Vorbild 5-2).
@export var farbe := Color(0, 0, 0, 0)

## Ein Ziel ist erledigt. Der Zielzähler des Levels hängt hier dran.
## `art` kommt als int (Wert aus `Art`) – Enums als Signalparameter zu
## deklarieren bringt nichts, ein Empfänger bekommt ohnehin die Zahl.
signal abgeschossen(art: int)
## Ein Ballon ist geplatzt und gibt seine Belohnung frei (Ort mitgeliefert,
## damit das Level dort etwas fallen lassen kann).
signal belohnung_frei(ort: Vector3)

## Wie lange das Abtrudeln dauert, bevor das Wrack verschwindet. Kein
## schlagartiges Verschwinden: Man muss sehen, dass man getroffen hat.
const TRUDEL_DAUER := 2.2
## Fallbeschleunigung beim Abtrudeln. Deutlich schwächer als die Gravitation
## der Figur (-38), damit das Wrack lange genug im Bild bleibt.
const TRUDEL_G := -13.0
## So lange zuckt ein getroffenes, aber noch fliegendes Ziel sichtbar.
const ZUCK_DAUER := 0.14
## Weiter als so schießt ein Bomber nicht – sonst käme aus dem Dunst
## Beschuss von einem Ziel, das man noch gar nicht sieht.
const FEUER_REICHWEITE := 45.0
## Tempo der Rückschüsse. Langsamer als die eigenen (40 m/s), damit sie
## auf Distanz noch auszuweichen sind.
const FEUER_TEMPO := 24.0
## Streuung der Rückschüsse in Radiant. Ein Bomber, der auf 40 m Entfernung
## punktgenau trifft, ist kein Ziel, sondern eine Steuer auf Zeit.
const FEUER_STREUUNG := 0.06

## True, sobald abgeschossen – danach keine Treffer und keine Bahn mehr.
var erledigt := false

var _mitte := Vector3.ZERO
var _winkel := 0.0
var _tempo := 8.0
var _radius := 14.0
var _zuck := 0.0
var _feuer_rest := 0.0
var _tot_zeit := 0.0
var _wegflug := Vector3.ZERO
var _modell: Node3D
var _propeller: Array[Node3D] = []
var _trefferzone: Area3D


func _ready() -> void:
	add_to_group("flugziele")
	var werte := _art_werte()
	_tempo = tempo * float(werte["tempo"])
	_radius = maxf(bahn_radius * float(werte["radius"]), 0.5)
	panzerung = maxi(panzerung, int(werte["panzerung"]))
	_winkel = phase
	# Mittelpunkt so legen, dass die Bahn durch den gesetzten Ort läuft.
	_mitte = global_position - _bahnpunkt(_winkel)
	_feuer_rest = feuertakt * (0.4 + randf() * 0.6)

	_modell = Node3D.new()
	_modell.name = "Modell"
	add_child(_modell)
	_baue()

	_trefferzone = get_node_or_null("Trefferzone") as Area3D
	if _trefferzone != null:
		_trefferzone.collision_layer = 0    # das Ziel selbst kollidiert nicht
		_trefferzone.collision_mask = 2     # nur den Spieler beachten
		_trefferzone.monitoring = true
		var form := _trefferzone.get_node_or_null("Form") as CollisionShape3D
		if form != null:
			# Eigene Kugel je Instanz – eine geteilte Form würde beim
			# ersten Ziel eingestellt und für alle anderen mitgelten.
			var kugel := SphereShape3D.new()
			kugel.radius = trefferradius()
			form.shape = kugel
		if not _trefferzone.body_entered.is_connected(_auf_koerper):
			_trefferzone.body_entered.connect(_auf_koerper)

	_stellung_setzen(0.0)


func _physics_process(delta: float) -> void:
	if erledigt:
		_abtrudeln(delta)
		return

	_zuck = maxf(_zuck - delta, 0.0)
	_winkel = wrapf(_winkel + (_tempo / _radius) * delta, -PI, PI)
	_stellung_setzen(delta)
	_pruefe_ueberlappung()
	if feuert:
		_feuern(delta)


# ---------------------------------------------------------------- Bahn

## Punkt der Kreisbahn zum Winkel, relativ zum Mittelpunkt.
## Der doppelte Winkel in der Höhe ergibt zwei Wellen je Runde – die Bahn
## wirkt dadurch aus jedem Blickwinkel unterschiedlich.
func _bahnpunkt(w: float) -> Vector3:
	return Vector3(cos(w) * _radius, sin(w * 2.0) * bahn_hoehe, sin(w) * _radius)


func _stellung_setzen(delta: float) -> void:
	var alt := global_position
	global_position = _mitte + _bahnpunkt(_winkel)
	if not is_instance_valid(_modell):
		return

	var flug := global_position - alt
	if flug.length_squared() > 0.000001 and art != Art.BALLON:
		var richtung := flug.normalized()
		_modell.rotation.y = atan2(-richtung.x, -richtung.z)
		_modell.rotation.x = asin(clampf(richtung.y, -1.0, 1.0))
		# In die Kurve legen. Ein Flugzeug, das im Kreis fliegt, ohne sich
		# zu legen, sieht aus wie ein Karussellpferd – genau derselbe Grund
		# wie beim eigenen Doppeldecker.
		_modell.rotation.z = -0.7
	elif art == Art.BALLON:
		# Ein Ballon dreht sich langsam um sich selbst und dümpelt.
		_modell.rotation.y += delta * 0.4
		_modell.position.y = sin(_winkel * 6.0) * 0.15

	# Getroffen, aber noch in der Luft: kurzes Zusammenzucken als Quittung.
	var stauch := 1.0 + (_zuck / ZUCK_DAUER) * 0.25
	_modell.scale = Vector3(stauch, 2.0 - stauch, stauch)

	for prop in _propeller:
		if is_instance_valid(prop):
			prop.rotation.z += delta * 26.0


# ---------------------------------------------------------------- Treffer

## Trefferradius für den `Flugschuss`. Etwas großzügiger als die Optik –
## im Raum zu zielen ist schwer genug.
func trefferradius() -> float:
	match art:
		Art.BOMBER:
			return 2.0
		Art.BALLON:
			return 1.5
		_:
			return 1.1


## Ein Treffer. `von` ist die Flugrichtung des Geschosses; sie gibt dem
## Wrack seinen Drall.
func treffer_nehmen(schaden: int = 1, von: Vector3 = Vector3.ZERO) -> void:
	if erledigt:
		return
	panzerung -= maxi(schaden, 1)
	if panzerung <= 0:
		_abschuss(von)
		return
	_zuck = ZUCK_DAUER
	Klang.spiele("gegner", 1.4, 0.5)


func _abschuss(von: Vector3) -> void:
	erledigt = true
	_tot_zeit = TRUDEL_DAUER
	if _trefferzone != null:
		_trefferzone.set_deferred("monitoring", false)
	Klang.spiele("explosion", 1.0 if art == Art.BOMBER else 1.25)
	# Drall aus der Schussrichtung, dazu ein Rest der eigenen Bahn.
	var schub := von.normalized() * 4.0 if von.length_squared() > 0.0001 else Vector3.ZERO
	_wegflug = schub + Vector3(randf_range(-2.0, 2.0), 2.0, randf_range(-2.0, 2.0))
	abgeschossen.emit(art)
	if art == Art.BALLON:
		belohnung_frei.emit(global_position)


## Abtrudeln: fallen, überschlagen, kleiner werden – und erst dann weg.
func _abtrudeln(delta: float) -> void:
	_tot_zeit -= delta
	_wegflug.y += TRUDEL_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(_modell):
		_modell.rotation.z += delta * 7.0
		_modell.rotation.x += delta * 3.0
		_modell.scale = _modell.scale.lerp(Vector3(0.3, 0.3, 0.3),
				minf(delta * 1.6, 1.0))
	if _tot_zeit <= 0.0:
		queue_free()


func _auf_koerper(koerper: Node3D) -> void:
	if erledigt or koerper == null or not koerper.is_in_group("spieler"):
		return
	var spieler := koerper as Spieler
	if spieler == null:
		return
	# Die Berührung kostet den Flieger Panzerung, das Ziel aber nichts:
	# Sonst wäre Rammen der bequemste Abschuss und niemand müsste zielen.
	spieler.schaden_nehmen()


## `body_entered` feuert nur beim Eintreten. Ein Flieger, der in der Zone
## hängt, weil sein Kurs sie streift, muss aber weiter Schaden nehmen.
func _pruefe_ueberlappung() -> void:
	if _trefferzone == null or not _trefferzone.monitoring:
		return
	for koerper in _trefferzone.get_overlapping_bodies():
		_auf_koerper(koerper)


func _feuern(delta: float) -> void:
	_feuer_rest -= delta
	if _feuer_rest > 0.0:
		return
	_feuer_rest = feuertakt
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return
	var zum_ziel := spieler.global_position - global_position
	if zum_ziel.length() > FEUER_REICHWEITE or zum_ziel.length() < 0.5:
		return
	var richtung := zum_ziel.normalized().rotated(Vector3.UP,
			randf_range(-FEUER_STREUUNG, FEUER_STREUUNG))
	Flugschuss.abfeuern(get_parent(), global_position + richtung * 1.5,
			richtung, self, Farben.WARNUNG, FEUER_TEMPO)


# ---------------------------------------------------------------- Optik

## Faktoren und Mindestwerte je Art.
func _art_werte() -> Dictionary:
	match art:
		Art.BOMBER:
			# Groß und langsam, aber auf weitem Kreis – er zieht seine Bahn
			# durch den halben Luftraum und ist immer irgendwo zu sehen.
			return {"tempo": 0.55, "radius": 1.0, "panzerung": 3}
		Art.BALLON:
			# Bewegt sich kaum: ein stehendes Ziel, das man sich für
			# zwischendurch aufhebt.
			return {"tempo": 0.06, "radius": 0.12, "panzerung": 1}
		_:
			# Jäger: schnell und eng – das eigentliche Jagdziel.
			return {"tempo": 1.6, "radius": 0.6, "panzerung": 1}


## Farbe der Art, falls im Level keine eingetragen wurde.
func _grundfarbe() -> Color:
	if farbe.a > 0.0:
		return farbe
	return Farben.KISTE_FEDER if art == Art.BALLON else Farben.WARNUNG


func _baue() -> void:
	match art:
		Art.BOMBER:
			_baue_bomber()
		Art.BALLON:
			_baue_ballon()
		_:
			_baue_jaeger()


func _baue_jaeger() -> void:
	var lack := Materialbibliothek.metall(_grundfarbe())
	var dunkel := Materialbibliothek.einfarbig(_grundfarbe().darkened(0.65), 0.6)
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.22, 0.11, 1.7, 8),
			PropWerkzeug.ort(Vector3(0, 0, 0.1), Vector3(PI * 0.5, 0, 0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(2.5, 0.07, 0.62)),
			PropWerkzeug.ort(Vector3(0, 0.0, -0.1)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(0.9, 0.06, 0.34)),
			PropWerkzeug.ort(Vector3(0, 0.05, 0.8)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(0.07, 0.42, 0.4)),
			PropWerkzeug.ort(Vector3(0, 0.25, 0.78)))
	_anhaengen("Zelle", PropWerkzeug.fertig(st), lack, true)
	_baue_propeller(Vector3(0, 0, -0.9), 0.55, dunkel)


func _baue_bomber() -> void:
	var lack := Materialbibliothek.metall(_grundfarbe())
	var dunkel := Materialbibliothek.einfarbig(_grundfarbe().darkened(0.65), 0.6)
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.42, 0.22, 3.6, 8),
			PropWerkzeug.ort(Vector3(0, 0, 0.2), Vector3(PI * 0.5, 0, 0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.3, 0.4, 0.6, 8, true),
			PropWerkzeug.ort(Vector3(0, 0, -1.9), Vector3(-PI * 0.5, 0, 0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(6.2, 0.14, 1.25)),
			PropWerkzeug.ort(Vector3(0, 0.1, -0.15)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(2.6, 0.1, 0.7)),
			PropWerkzeug.ort(Vector3(0, 0.18, 1.7)))
	# Doppelleitwerk – der schnellste Weg, „großes Flugzeug" zu sagen
	for seite: float in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(0.1, 0.7, 0.6)),
				PropWerkzeug.ort(Vector3(seite * 1.2, 0.5, 1.7)))
		PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.24, 0.2, 1.1, 8),
				PropWerkzeug.ort(Vector3(seite * 1.7, 0.06, -0.3),
						Vector3(PI * 0.5, 0, 0)))
	_anhaengen("Zelle", PropWerkzeug.fertig(st), lack, true)
	for seite: float in [-1.0, 1.0]:
		_baue_propeller(Vector3(seite * 1.7, 0.06, -0.9), 0.62, dunkel)


func _baue_ballon() -> void:
	var haut := Materialbibliothek.einfarbig(_grundfarbe(), 0.55, 0.05)
	var streifen := Materialbibliothek.einfarbig(Farben.SCHNEE_HELL, 0.55)
	var korb := Materialbibliothek.einfarbig(Farben.HOLZ_DUNKEL, 0.85)

	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.kugel(1.15, 10, 7),
			PropWerkzeug.ort(Vector3(0, 0.4, 0), Vector3.ZERO,
					Vector3(1.0, 1.25, 1.0)))
	_anhaengen("Huelle", PropWerkzeug.fertig(st), haut, true)

	# Zwei helle Bänder – ohne sie ist der Ballon vor dem Dunsthimmel
	# nur ein Fleck, und man sieht seine Drehung nicht.
	var stb := PropWerkzeug.bauer()
	for hoehe: float in [0.05, 0.85]:
		PropWerkzeug.anfuegen(stb, PropWerkzeug.stumpf(1.14, 1.14, 0.18, 10),
				PropWerkzeug.ort(Vector3(0, hoehe, 0)))
	_anhaengen("Baender", PropWerkzeug.fertig(stb), streifen, false)

	var stk := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(stk, PropWerkzeug.kasten(Vector3(0.62, 0.5, 0.62)),
			PropWerkzeug.ort(Vector3(0, -1.35, 0)))
	for x: float in [-0.26, 0.26]:
		for z: float in [-0.26, 0.26]:
			PropWerkzeug.anfuegen(stk, PropWerkzeug.stumpf(0.03, 0.03, 0.75, 4),
					PropWerkzeug.ort(Vector3(x, -0.78, z)))
	_anhaengen("Korb", PropWerkzeug.fertig(stk), korb, true)


func _baue_propeller(ort: Vector3, laenge: float, stoff: Material) -> void:
	var nabe := Node3D.new()
	nabe.name = "Propeller"
	nabe.position = ort
	_modell.add_child(nabe)
	var st := PropWerkzeug.bauer()
	for winkel: float in [0.0, PI * 0.5]:
		PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(0.08, laenge * 2.0, 0.03)),
				PropWerkzeug.ort(Vector3.ZERO, Vector3(0, 0, winkel)))
	var blaetter := PropWerkzeug.mesh_knoten("Blaetter", PropWerkzeug.fertig(st),
			stoff, false)
	if blaetter != null:
		nabe.add_child(blaetter)
	_propeller.append(nabe)


func _anhaengen(bezeichnung: String, netz: Mesh, stoff: Material,
		schatten: bool) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung, netz, stoff, schatten)
	if knoten != null:
		_modell.add_child(knoten)
