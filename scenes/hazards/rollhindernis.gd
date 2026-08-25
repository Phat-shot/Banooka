extends Node3D
class_name Rollhindernis
## Steinkugel oder Fass, das den Weg entlangrollt und bei Berührung tötet.
##
## Der Ablauf ist eine Schleife und läuft immer in dieselbe Richtung:
## warten am Anfang → rollen bis zum Ende → weg sein → wieder am Anfang
## auftauchen. Kein Zurückrollen: Eine Kugel, die rückwärts den Berg
## hochrollt, verrät sofort, dass da nur ein Wert zwischen zwei Punkten
## hin- und herläuft. Lieber ist sie kurz weg – dann glaubt man ihr, dass
## oben immer neue nachkommen.
##
## Mit `auf_abruf` wartet sie stattdessen, bis jemand `ausloesen()` ruft.
## Das ist die Falle: Eine `Ausloeseplatte` im Weg, und der Brocken kommt
## genau dann, wenn man am wenigsten Platz hat.
##
## Sie folgt dem Levelverlauf wie die `Wasserplattform`. Ohne Kurve wäre
## eine lange Bahn in einem Korridorlevel wertlos – schon nach der ersten
## Biegung rollte der Brocken neben dem Weg her.
##
## Sie ist mit Absicht NICHT zu besiegen. Der Drehschlag hilft nicht, nur
## Ausweichen: zur Seite, in eine Nische, oder gar nicht.

enum Art {
	KUGEL,  ## grob facettierte Steinkugel
	FASS,   ## Metallfass mit Reifen
}

## Aussehen des Brockens.
@export var art: Art = Art.KUGEL

## Levelkurve, der die Bahn folgt. Ohne Kurve rollt der Brocken
## geradeaus in die lokale Vorwärtsrichtung (-Z).
@export var verlauf: Curve3D = null

## Anfang und Ende der Bahn als Strecke auf der Kurve, in Metern.
@export var strecke_von := 0.0
@export var strecke_bis := 40.0

## Querversatz zur Wegmitte (positiv = rechts) und Höhe des BODENS,
## auf dem der Brocken rollt. Er selbst sitzt `radius` darüber.
@export var seitlich := 0.0
@export var hoehe := 0.0

## Halbmesser des Brockens in Metern. Beim Fass zugleich der Radius der
## Reifen; seine Länge ergibt sich daraus.
@export var radius := 1.1

## Rolltempo in Metern je Sekunde.
@export var tempo := 9.0

## Wartezeit am Startpunkt vor dem nächsten Lauf, in Sekunden.
@export var pause := 2.0

## Verschiebt den Takt gegen andere Brocken. 0 bis 1 = eine volle Runde.
@export var phase := 0.0

## Wartet der Brocken auf `ausloesen()`, statt von selbst zu laufen?
@export var auf_abruf := false

## Höhe, aus der er am Startpunkt hereinfällt. 0 = er ist einfach da.
@export var abwurf := 2.6

## Farbe. Alpha 0 = Vorgabe der Art (Fels bzw. Rost).
@export var farbe := Color(0, 0, 0, 0)

## Feste Saat für die Form der Kugel.
@export var saat := 0

const ABWURF_ZEIT := 0.45     ## so lange dauert der Fall an den Startpunkt
const WEG_ZEIT := 0.5         ## so lange ist er nach dem Lauf verschwunden
const FASS_LAENGE := 1.9      ## Fasslänge in Vielfachen des Radius

var _bild: Node3D             ## trägt die Rolldrehung
var _zone: Area3D
var _ruhe := Vector3.ZERO     ## Ausgangsort, falls keine Kurve gesetzt ist
var _zeit := 0.0
var _winkel := 0.0            ## aufgelaufene Rolldrehung in Bogenmaß
var _laeuft := false          ## rollt gerade (nur für `auf_abruf`)
var _scharf := false          ## darf gerade Schaden machen


func _ready() -> void:
	add_to_group("gefahren")
	_ruhe = position
	_aufbauen()
	# Gleich zum Takt passend setzen, sonst steht der Brocken im ersten
	# Bild im Nullpunkt und springt danach an seinen Platz.
	_takten(0.0)


func _physics_process(delta: float) -> void:
	_zeit += delta
	_takten(delta)
	if not _scharf:
		return
	for koerper in _zone.get_overlapping_bodies():
		if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
			koerper.schaden_nehmen()


## Startet einen Lauf. Wirkt nur bei `auf_abruf` und nur, wenn der Brocken
## gerade oben wartet – ein zweiter Ruf mitten im Lauf tut nichts, sonst
## spränge der Stein vor den Augen des Spielers zurück an den Anfang.
func ausloesen() -> void:
	if auf_abruf and not _laeuft:
		_laeuft = true
		_zeit = 0.0


## Holt den Brocken zurück an den Startpunkt.
func zuruecksetzen() -> void:
	_laeuft = false
	_zeit = 0.0


# ---------------------------------------------------------------- Takt

## Setzt Ort, Drehung und Schärfe für diesen Augenblick.
func _takten(delta: float) -> void:
	var bahn := absf(strecke_bis - strecke_von)
	var fahrzeit := bahn / maxf(tempo, 0.01)
	var anteil := 0.0        ## 0 = am Anfang, 1 = am Ende
	var da := true           ## sichtbar und gefährlich?
	var rollt := false
	var fall := 0.0          ## Resthöhe über dem Boden beim Hereinfallen

	if auf_abruf:
		if _laeuft and _zeit >= fahrzeit:
			# Nach dem Lauf wieder oben warten – den Takt gibt hier der
			# Auslöser vor, nicht die Uhr. Der neue Brocken fällt wieder
			# herein, damit das Zurücksetzen nicht wie ein Sprung wirkt.
			_laeuft = false
			_zeit = 0.0
		if _laeuft:
			anteil = _zeit / maxf(fahrzeit, 0.0001)
			rollt = true
		else:
			fall = _abwurf_rest(_zeit)
	else:
		var runde := pause + fahrzeit + WEG_ZEIT
		var p := fposmod(_zeit + phase * runde, runde)
		if p < pause:
			fall = _abwurf_rest(p)
		elif p < pause + fahrzeit:
			anteil = (p - pause) / maxf(fahrzeit, 0.0001)
			rollt = true
		else:
			da = false

	if visible != da:
		visible = da
		_zone.monitoring = da
	# Beim Hereinfallen noch harmlos: Was über einem auftaucht, darf einen
	# nicht töten, bevor man es überhaupt gesehen hat.
	_scharf = da and fall <= 0.0

	if not rollt:
		# Zurücksetzen, solange es niemand sieht – sonst liefe der Winkel
		# über eine lange Sitzung ins Unfeine.
		_winkel = 0.0
	if not da:
		return

	var s := lerpf(strecke_von, strecke_bis, anteil)
	var vorwaerts := _richtung(s)
	position = _ort(s) + Vector3.UP * fall

	# Rollen statt rutschen: Ein Rad vom Halbmesser r legt bei einer
	# vollen Umdrehung seinen Umfang U = 2·PI·r zurück. Für die Strecke d
	# sind das d/U Umdrehungen, also einen Drehwinkel von
	# 2·PI·d/(2·PI·r) = d/r im Bogenmaß. Der Winkel läuft mit, damit die
	# Drehung auch in Kurven stimmt, wo sich die Achse mitdreht.
	if rollt:
		_winkel += delta * tempo / maxf(radius, 0.01)
	# Rollachse: waagerecht, quer zur Fahrt. Mit UP × vorwärts dreht sich
	# der Scheitel nach VORNE – mit der umgekehrten Reihenfolge liefe der
	# Brocken rückwärts, was man sofort sieht und keinem erklären kann.
	var achse := Vector3.UP.cross(vorwaerts).normalized()
	var ausrichtung := Basis(achse, Vector3.UP, vorwaerts)
	_bild.basis = Basis(achse, _winkel) * ausrichtung
	# Die Schadenszone dreht sich mit der Fahrt, aber nicht mit dem Rollen:
	# ein mitrollender Kasten würde am Fass abwechselnd vorstehen.
	_zone.basis = ausrichtung


## Resthöhe des Brockens über dem Boden, während er an den Startpunkt fällt.
func _abwurf_rest(gewartet: float) -> float:
	if abwurf <= 0.0 or gewartet >= ABWURF_ZEIT:
		return 0.0
	var t := 1.0 - gewartet / ABWURF_ZEIT
	return abwurf * t * t      # quadratisch: sieht nach Fallen aus, nicht nach Schweben


## Ort der Mitte des Brockens bei Strecke `s`.
func _ort(s: float) -> Vector3:
	var mitte := hoehe + radius
	if verlauf == null:
		return _ruhe + Vector3.RIGHT * seitlich \
				+ Vector3.FORWARD * (s - strecke_von) + Vector3.UP * mitte
	return LevelWerkzeuge.punkt(verlauf, s, seitlich, mitte)


## Fahrtrichtung bei Strecke `s`, waagerecht.
func _richtung(s: float) -> Vector3:
	if verlauf == null:
		return Vector3.FORWARD if strecke_bis >= strecke_von else Vector3.BACK
	var d := LevelWerkzeuge.richtung(verlauf, s)
	return d if strecke_bis >= strecke_von else -d


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	_bild = Node3D.new()
	_bild.name = "Bild"
	add_child(_bild)

	match art:
		Art.KUGEL:
			_kugel_bauen()
		Art.FASS:
			_fass_bauen()

	_zone = Area3D.new()
	_zone.name = "Zone"
	_zone.collision_layer = 0
	_zone.collision_mask = 2      # nur den Spieler beachten
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	if art == Art.FASS:
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(radius * FASS_LAENGE, radius * 2.0, radius * 2.0)
		kollision.shape = kasten
	else:
		var ball := SphereShape3D.new()
		ball.radius = radius * 1.02
		kollision.shape = ball
	_zone.add_child(kollision)
	add_child(_zone)


## Grob facettierte Steinkugel. `kantig` setzt Flächennormalen – erst
## dadurch fängt jede Facette das Licht einzeln, und man sieht die Kugel
## sich drehen. Eine glatte Kugel rollt optisch überhaupt nicht.
func _kugel_bauen() -> void:
	var rng := PropWerkzeug.zufall(saat if saat != 0 else 7)
	var st := PropWerkzeug.bauer()
	var ton := farbe if farbe.a > 0.0 else Farben.FELS
	PropWerkzeug.klumpen(st, rng, Vector3.ZERO, Vector3.ONE * radius,
			Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU),
			9, 6, 0.11, true, ton.darkened(0.35), ton)
	# `klumpen()` bringt keine Tangenten mit, die Felsmaterialien tragen
	# aber Normalmaps – ohne die Tangenten bliebe die Struktur wirkungslos.
	var netz := PropWerkzeug.fertig_mit_tangenten(st)
	var knoten := PropWerkzeug.mesh_knoten("Kugel", netz,
			PropWerkzeug.mit_scheitelfarben(Materialbibliothek.fels()))
	if knoten != null:
		_bild.add_child(knoten)


## Fass: liegender Zylinder mit zwei Reifen, Achse quer zur Fahrt (X).
## Das `_bild` wird später so gedreht, dass X auf der Rollachse liegt.
func _fass_bauen() -> void:
	var laenge := radius * FASS_LAENGE
	var quer := Basis(Vector3.BACK, PI * 0.5)      # Zylinderachse Y -> X
	var ton := farbe if farbe.a > 0.0 else Farben.ROST

	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(radius * 0.94, radius * 0.94,
			laenge, 10, true), Transform3D(quer, Vector3.ZERO))
	var rumpf := PropWerkzeug.mesh_knoten("Fass", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(ton))
	if rumpf != null:
		_bild.add_child(rumpf)

	# Reifen etwas dicker als der Rumpf: Sie tragen das Fass, und ihre
	# Kanten machen die Drehung sichtbar.
	var reifen := PropWerkzeug.bauer()
	for seite in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(reifen, PropWerkzeug.stumpf(radius, radius,
				laenge * 0.13, 10, false),
				Transform3D(quer, Vector3(seite * laenge * 0.3, 0.0, 0.0)))
	var band := PropWerkzeug.mesh_knoten("Reifen", PropWerkzeug.fertig(reifen),
			Materialbibliothek.metall(Farben.KISTE_EISEN))
	if band != null:
		_bild.add_child(band)

	# Ein leuchtender Streifen auf der Stirnseite. Ohne ihn ist ein
	# rostiges Fass vor einer rostigen Wand erst zu sehen, wenn es zu
	# spät ist – Gefahr muss man an der Farbe erkennen, nicht an der Form.
	var marke := PropWerkzeug.bauer()
	for seite in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(marke, PropWerkzeug.stumpf(radius * 0.44,
				radius * 0.44, laenge * 0.06, 8, true),
				Transform3D(quer, Vector3(seite * laenge * 0.5, 0.0, 0.0)))
	var warn := PropWerkzeug.mesh_knoten("Warnmarke", PropWerkzeug.fertig(marke),
			Materialbibliothek.leuchtend(Farben.WARNUNG, 0.8), false)
	if warn != null:
		_bild.add_child(warn)
