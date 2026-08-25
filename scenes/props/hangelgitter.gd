extends Node3D
class_name Hangelgitter
## Gitter unter der Decke, an dem sich die Figur entlangzieht.
##
## Es ist KEIN fester Körper: Man steht nicht darauf, man hängt darunter.
## Deshalb trägt das Gitter nur sichtbare Netze und eine einzige Area3D,
## die Fangzone – den Raum knapp unter der Unterkante, in dem die Hände
## an die Sprossen kommen. Alles Weitere entscheidet der Spieler-Code;
## dieses Prop beantwortet ihm nur drei Fragen: wie hoch gehangen wird
## (`hangelhoehe()`), wohin die Hände gehören (`naechster_punkt()`) und
## wann Schluss ist (`ist_am_ende()`).
##
## Achsen: Die LÄNGE läuft entlang der lokalen Z-Achse, die BREITE entlang
## der lokalen X-Achse. Das ist dieselbe Regel wie bei allen Korridorteilen –
## `LevelWerkzeuge.drehung(kurve, s)` liefert genau die Y-Drehung, mit der
## die Länge dem Weg folgt, und gehört unverändert in `drehung`.
##
## Der Ursprung des Knotens liegt auf BODENHÖHE, nicht am Gitter: `hoehe`
## ist der lichte Abstand vom Boden zur Unterkante. So platziert man ein
## Gitter dort, wo man auch die Gasse platziert, statt in der Luft zu rechnen.
##
## Wie hoch darf es hängen? Die Figur springt mit JUMP_V = 12,2 gegen
## G = −38, ihre Füße steigen also v²/(2·|G|) = 12,2² / 76 = 1,96 m. Mit
## gestreckten Armen greift sie GRIFF_HOEHE = 1,55 m über die Sohlen
## hinaus, im Scheitel demnach bis 3,51 m. Bequem – also mit Spielraum,
## sodass der Griff nicht auf den Zentimeter im Scheitel sitzen muss –
## sind 2,6 m bis 3,4 m; die Vorgabe 3,2 m liegt darin. Höher geht es nur
## mit dem Doppelsprung: DJUMP_V = 10,5 bringt vom Scheitel aus weitere
## 10,5² / 76 = 1,45 m, zusammen 3,41 m Fußhöhe und 4,96 m Griffhöhe.
## Das ist die harte Grenze, und ein Gitter dort oben ist eine eigene
## Aufgabe und keine Nebensache.

## Name der Gruppe, über die der Spieler-Code alle Gitter findet.
const GRUPPE := "hangelgitter"

## Abstand von den Fußsohlen zu den Händen bei gestreckten Armen. Die
## Kapsel ist 1,30 m hoch, die Ohrenspitzen des Beuteldachses liegen bei
## 1,42 m; der Griff reicht eine Handbreit darüber hinaus.
const GRIFF_HOEHE := 1.55

## Höhe der Fangzone unter der Unterkante. Sie ist so bemessen, dass der
## Scheitel der aufrechten Kapsel (Fußhöhe + 1,30 m) sie schon erreicht,
## wenn die Füße noch 0,35 m unter der späteren Hanghöhe stehen – wer
## knapp zu kurz springt, bekommt das Gitter trotzdem zu fassen.
const FANG_TIEFE := 0.6

## Tiefer darf ein Gitter nicht hängen, sonst schleift die hängende Figur
## über den Boden und `is_on_floor()` reißt das Hangeln sofort wieder ab.
const MINDESTHOEHE := 2.4

const SPROSSE_DICKE := 0.11    ## Kantenlänge der Quersprossen
const TRAEGER_BREITE := 0.12   ## Breite der Längsträger
const TRAEGER_HOEHE := 0.16    ## Höhe der Längsträger, liegen auf den Sprossen
const ENDE_DICKE := 0.18       ## Endbügel, kräftiger als eine Sprosse
const STUMMEL_HOEHE := 0.4     ## Aufhängung nach oben, markiert die Enden
## Ab dieser Breite bekommt das Gitter einen Mittelträger. Darunter wirkte
## er gedrängt und nähme dem Blick von unten die klaren Abstände.
const MITTELTRAEGER_AB := 1.8

## So weit vor dem Rand ist Schluss – längs wie quer. Ohne diesen Einzug
## hinge die Figur mit den Händen über der letzten Sprosse in der Luft.
const RAND_LAENGS := 0.35
const RAND_QUER := 0.35
## Toleranz für `ist_am_ende()`: Wer so nah am Rand hängt, ist dort.
const ENDE_RAND := 0.06

## Länge des Gitters in Metern (entlang der lokalen Z-Achse).
@export var laenge := 8.0

## Breite des Gitters in Metern (entlang der lokalen X-Achse). Sie gibt
## den Spielraum quer – wer ausweichen können soll, braucht mindestens
## zwei Meter, sonst ist Hangeln eine Schiene ohne Entscheidung.
@export var breite := 2.0

## Lichte Höhe: Abstand vom Boden zur Unterkante des Gitters.
@export var hoehe := 3.2

## Abstand der Quersprossen. Sie sind das, was man von unten sieht und
## greift; unter 0,35 m wird daraus ein Netz, über 0,8 m eine Leiter mit
## Lücken.
@export var sprossenabstand := 0.5

## Drehung um die Hochachse, damit die Länge dem Wegverlauf folgt.
@export var drehung := 0.0

## Anstrich. Alpha 0 = Vorgabe (Rost). Die Sprossen werden daraus
## aufgehellt, die Träger abgedunkelt: Von unten liest sich das Gitter
## dadurch als Reihe heller Griffe in einem dunklen Rahmen, statt als
## gleichmäßiger Fleck.
@export var farbe := Color(0, 0, 0, 0)

var _fangzone: Area3D


func _ready() -> void:
	add_to_group(GRUPPE)
	rotation = Vector3(0.0, drehung, 0.0)
	if hoehe < MINDESTHOEHE:
		push_warning("Hangelgitter: hoehe %.2f liegt unter %.2f m und wird angehoben."
				% [hoehe, MINDESTHOEHE])
	_fangzone_bauen()
	_aufbauen()


# ---------------------------------------------------------- Auskunft

## Weltgleiche Y-Höhe der Unterkante – dort liegen die Sprossen.
func unterkante() -> float:
	return to_global(Vector3(0.0, _lichte_hoehe(), 0.0)).y


## Auf welcher Welthöhe der Ursprung der Figur (ihre Fußsohlen) hängt.
## Der Spieler-Code setzt seine `global_position.y` genau hierauf.
func hangelhoehe() -> float:
	return unterkante() - GRIFF_HOEHE


## Weltrichtung, in der das Gitter läuft: von Sprosse zu Sprosse, also
## die Richtung des eigentlichen Hangelns (lokale Z-Achse).
func laengsachse() -> Vector3:
	var v := global_transform.basis.z
	v.y = 0.0
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.BACK


## Weltrichtung quer dazu: entlang EINER Sprosse (lokale X-Achse).
func querachse() -> Vector3:
	var v := global_transform.basis.x
	v.y = 0.0
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.RIGHT


## Der Punkt am Gitter, an dem sich die Figur von `pos` aus einhängen
## würde: seitlich und längs auf den nutzbaren Bereich beschnitten, in
## der Höhe auf `hangelhoehe()` gesetzt.
##
## Der Spieler-Code darf das jedes Bild aufrufen – die Beschneidung ist
## zugleich die Grenze, an der das Hangeln aufhört. Bewegt er die Figur
## erst frei und schickt sie dann hier durch, kann sie nicht über das
## Gitter hinausrutschen.
func naechster_punkt(pos: Vector3) -> Vector3:
	var lokal := to_local(pos)
	lokal.x = clampf(lokal.x, -_halbe_breite(), _halbe_breite())
	lokal.z = clampf(lokal.z, -_halbe_laenge(), _halbe_laenge())
	lokal.y = _lichte_hoehe() - GRIFF_HOEHE
	return to_global(lokal)


## Hängt die Figur an `pos` am Rand und will sie in `richtung` weiter?
##
## Gemeint ist die Weltrichtung der gewünschten Bewegung, nicht die
## Blickrichtung. Längs und quer werden beide geprüft: Am Ende des
## Gitters ist auch, wer seitlich hinauswill.
func ist_am_ende(pos: Vector3, richtung: Vector3) -> bool:
	var lokal := to_local(pos)
	var lokale_richtung := global_transform.basis.inverse() * richtung
	if _am_rand(lokal.z, lokale_richtung.z, _halbe_laenge()):
		return true
	return _am_rand(lokal.x, lokale_richtung.x, _halbe_breite())


## Steckt `koerper` gerade in der Fangzone?
##
## Bewusst eine Frage und keine Meldung: Würde das Gitter dem Spieler von
## sich aus Bescheid geben, hinge das Ergebnis daran, welcher Knoten sein
## `_physics_process` zuerst bekommt. So fragt der Spieler, wenn es ihm
## passt, und die Reihenfolge im Baum spielt keine Rolle.
func in_reichweite(koerper: PhysicsBody3D) -> bool:
	if koerper == null or _fangzone == null:
		return false
	return _fangzone.overlaps_body(koerper)


## Das nächstgelegene Gitter, an dem sich `koerper` gerade einhängen kann,
## oder `null`. Bei überlappenden Gittern gewinnt das, dessen Griffpunkt
## am dichtesten liegt.
static func naechstes(koerper: PhysicsBody3D) -> Hangelgitter:
	if koerper == null or not koerper.is_inside_tree():
		return null
	var bestes: Hangelgitter = null
	var beste_weite := INF
	for knoten in koerper.get_tree().get_nodes_in_group(GRUPPE):
		var gitter := knoten as Hangelgitter
		if gitter == null or not gitter.in_reichweite(koerper):
			continue
		var weite := gitter.naechster_punkt(koerper.global_position) \
				.distance_squared_to(koerper.global_position)
		if weite < beste_weite:
			beste_weite = weite
			bestes = gitter
	return bestes


# ---------------------------------------------------------- Intern

func _lichte_hoehe() -> float:
	return maxf(hoehe, MINDESTHOEHE)


func _halbe_laenge() -> float:
	return maxf(laenge * 0.5 - RAND_LAENGS, 0.0)


func _halbe_breite() -> float:
	return maxf(breite * 0.5 - RAND_QUER, 0.0)


static func _am_rand(wert: float, richtung: float, grenze: float) -> bool:
	# Unter dieser Schwelle ist die Richtung nur noch Rauschen aus dem
	# Stick und würde am Rand ständig zwischen "Ende" und "nicht Ende"
	# umschlagen.
	if absf(richtung) < 0.05:
		return false
	return absf(wert) >= grenze - ENDE_RAND and signf(wert) == signf(richtung)


func _farbe() -> Color:
	return farbe if farbe.a > 0.0 else Farben.ROST


# ---------------------------------------------------------------- Aufbau

## Flache Zone unmittelbar unter der Unterkante. Nur der Spieler (Ebene 2)
## wird beachtet; das Gitter selbst liegt auf keiner Ebene und stellt
## damit für niemanden ein Hindernis dar.
func _fangzone_bauen() -> void:
	_fangzone = PropWerkzeug.kind(self, "Fangzone",
			func() -> Area3D: return Area3D.new()) as Area3D
	_fangzone.collision_layer = 0
	_fangzone.collision_mask = 2
	_fangzone.monitoring = true
	_fangzone.monitorable = false
	var kollision := PropWerkzeug.kind(_fangzone, "Kollision",
			func() -> CollisionShape3D: return CollisionShape3D.new()) \
			as CollisionShape3D
	var form := BoxShape3D.new()
	form.size = Vector3(maxf(breite, 0.2), FANG_TIEFE, maxf(laenge, 0.2))
	kollision.shape = form
	kollision.position = Vector3(0.0,
			_lichte_hoehe() - FANG_TIEFE * 0.5, 0.0)


func _aufbauen() -> void:
	var unten := _lichte_hoehe()
	var sprossen_mitte := unten + SPROSSE_DICKE * 0.5
	var traeger_mitte := unten + SPROSSE_DICKE + TRAEGER_HOEHE * 0.5
	var oben := unten + SPROSSE_DICKE + TRAEGER_HOEHE

	_netz("Sprossen", _sprossen_bauen(sprossen_mitte),
			Materialbibliothek.metall(_farbe().lightened(0.18)))
	_netz("Traeger", _traeger_bauen(traeger_mitte),
			Materialbibliothek.metall(_farbe().darkened(0.35)))
	_netz("Halterung", _halterung_bauen(unten, oben),
			Materialbibliothek.metall(_farbe().darkened(0.5)))


## Die Quersprossen: kräftige Riegel in klaren Abständen, ganz unten am
## Gitter. Sie sind das, was von unten zu sehen ist, und das, was gegriffen
## wird – deshalb liegen sie unter den Trägern und nicht darüber.
##
## Die beiden äußersten Plätze bleiben frei, dort sitzen die Endbügel.
func _sprossen_bauen(mitte_y: float) -> ArrayMesh:
	var st := PropWerkzeug.bauer()
	var felder := maxi(int(round(laenge / maxf(sprossenabstand, 0.15))), 2)
	var schritt := laenge / float(felder)
	for i in range(1, felder):
		var z := -laenge * 0.5 + schritt * float(i)
		var sprosse := PropWerkzeug.kasten(
				Vector3(breite, SPROSSE_DICKE, SPROSSE_DICKE))
		PropWerkzeug.anfuegen(st, sprosse,
				Transform3D(Basis(), Vector3(0.0, mitte_y, z)))
	return PropWerkzeug.fertig(st)


## Die Längsträger, auf denen die Sprossen aufliegen. Zwei außen, bei
## breiten Gittern einer in der Mitte – mehr braucht es nicht, ein feineres
## Raster verschluckt von unten die Abstände.
func _traeger_bauen(mitte_y: float) -> ArrayMesh:
	var st := PropWerkzeug.bauer()
	var rand := breite * 0.5 - TRAEGER_BREITE * 0.5
	var spuren := [-rand, rand]
	if breite >= MITTELTRAEGER_AB:
		spuren.append(0.0)
	for x: float in spuren:
		var traeger := PropWerkzeug.kasten(
				Vector3(TRAEGER_BREITE, TRAEGER_HOEHE, laenge))
		PropWerkzeug.anfuegen(st, traeger,
				Transform3D(Basis(), Vector3(x, mitte_y, 0.0)))
	return PropWerkzeug.fertig(st)


## Endbügel und Aufhängung.
##
## Beides ist nicht Zierrat: Der Bügel schließt das Gitter sichtbar ab,
## damit man das Ende erkennt, BEVOR man dort hängt – sonst hangelt man
## blind gegen eine unsichtbare Grenze. Die Stummel nach oben erklären,
## woran das Gitter überhaupt hängt.
func _halterung_bauen(unten: float, oben: float) -> ArrayMesh:
	var st := PropWerkzeug.bauer()
	var dicke := oben - unten
	for seite: float in [-1.0, 1.0]:
		var buegel := PropWerkzeug.kasten(
				Vector3(breite + 0.06, dicke, ENDE_DICKE))
		PropWerkzeug.anfuegen(st, buegel, Transform3D(Basis(),
				Vector3(0.0, unten + dicke * 0.5,
				seite * (laenge * 0.5 - ENDE_DICKE * 0.5))))
		for quer: float in [-1.0, 1.0]:
			var stummel := PropWerkzeug.kasten(
					Vector3(TRAEGER_BREITE, STUMMEL_HOEHE, TRAEGER_BREITE))
			PropWerkzeug.anfuegen(st, stummel, Transform3D(Basis(), Vector3(
					quer * (breite * 0.5 - TRAEGER_BREITE * 0.5),
					oben + STUMMEL_HOEHE * 0.5,
					seite * (laenge * 0.5 - ENDE_DICKE * 0.5))))
	return PropWerkzeug.fertig(st)


func _netz(bezeichnung: String, netz: ArrayMesh, material: Material) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung, netz, material)
	if knoten != null:
		add_child(knoten)
