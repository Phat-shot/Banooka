extends AnimatableBody3D
class_name Fliessband
## Boden mit Eigengeschwindigkeit: Wer darauf steht, wird getragen.
##
## Vorbild ist die Burgmaschinerie (`doku/level-vorbilder.md`, 3-2). Der
## Gedanke dort: Der Boden ist zum ersten Mal kein Verlass. Ein Band, das
## gegen die Laufrichtung läuft, macht aus einem geraden Gang eine Strecke,
## und ein Band über einem Abgrund macht aus dem Stehenbleiben einen Fehler.
##
## WIE DER SPIELER GETRAGEN WIRD – und warum nicht anders.
##
## Godot trägt einen `CharacterBody3D` auf einem `AnimatableBody3D` nur mit,
## wenn sich der Körper wirklich bewegt: `move_and_slide` fragt die
## Geschwindigkeit des Bodens ab, auf dem die Figur steht, und schiebt sie um
## `bodentempo * delta` nach. Ein Band, das nur so AUSSIEHT, als liefe es,
## trägt nicht.
##
## Der naheliegende Ausweg wäre, den Körper eine kurze Strecke `hub`
## vorfahren zu lassen und ihn dann an den Anfang zurückspringen zu lassen.
## Der trägt aber nicht: Godot wertet die Bodengeschwindigkeit in BEIDE
## Richtungen aus. Der Rücksprung ist für ein Bild eine Geschwindigkeit von
## `-hub / delta`, und die Figur wird um genau den Weg zurückgerissen, den
## sie über den ganzen Hub gewonnen hatte.
##
## Nachgemessen mit genau diesem Aufbau (Hub 1.2 m, Tempo 3 m/s): In drei
## Sekunden, in denen 9 m Bandfläche unter der Figur durchgelaufen sind, ist
## sie nicht 9 m weit gekommen, sondern 0.6 m RÜCKWÄRTS gedriftet. Aus dem
## Fließband würde ein Laufband, und der Rucker wäre obendrein zu sehen,
## weil die Figur bei jedem Rücksprung mitspringt.
##
## Deshalb hier andersherum: Der KÖRPER STEHT STILL, getragen wird über eine
## Zone dicht über dem Band. Wer darin steht und Boden unter den Füßen hat,
## wird in jedem Physikbild um `tempo * delta` weitergeschoben – mit
## `move_and_collide`, also mit Kollisionsprüfung: Vor einer Wand staut sich
## die Figur, statt hindurchgeschoben zu werden.
##
## Das ist dem Hub in drei Punkten überlegen:
##   1. Es trägt überhaupt. Der Hub trägt netto null.
##   2. Es gibt keinen Rücksprung, also auch keinen Bildsprung.
##   3. Das Tempo ist genau `tempo` und hängt nicht daran, wie viel vom Hub
##      gerade noch übrig ist.
##
## Die Optik läuft davon unabhängig und braucht den Trick nicht: Jede Rille
## wandert einzeln über das Band und setzt am Ende hinter der Umlenkrolle
## wieder vorn an – genau das tut eine echte Rille auch, sie läuft unten
## zurück. Weil der Rillenabstand die Bandlänge glatt teilt, ist das Muster
## dabei lückenlos; sichtbar ist nur, dass etwas läuft.

## Kantenlängen des Bandes in Metern (x = quer, y = längs).
@export var groesse := Vector2(3.0, 6.0)

## Tempo der Bandoberfläche in Metern je Sekunde. Zum Vergleich: Der Spieler
## läuft mit 8.5. Ein Band mit 2.5 ist also spürbar, aber nicht übermächtig;
## erst ab etwa 5 wird das Gegenanlaufen aussichtslos.
@export var tempo := 2.5

## Laufrichtung: 1 = in lokale −Z (die Richtung, in die das Band zeigt),
## −1 = zurück.
@export var richtung := 1

## Wunschabstand der Rillen in Metern.
##
## Der tatsächliche Abstand wird auf ein glattes Vielfaches der Bandlänge
## gerundet – sonst klaffte an einem Ende eine Lücke im Muster, und genau
## dort steht die Umlenkrolle, wo es am meisten auffiele.
@export var hub := 1.2

## Drehung um die Hochachse, damit das Band zum Wegverlauf passt.
@export var drehung := 0.0

## Mittelpunkt des Bandes in Elternkoordinaten. Bleibt er auf Null, gilt die
## Position, die der Knoten beim Start hat.
@export var ort := Vector3.ZERO

## Grundton der Bandplatten. Dunkel genug, dass die hellen Rillen darauf
## lesbar bleiben, hell genug, dass der Rost im Metall noch nach Rost
## aussieht und nicht nach Glut.
@export var bandfarbe := Color(0.31, 0.32, 0.36)

## Farbe der Querrillen. Der Abstand zum Band ist hier der ganze Zweck: Wer
## die Rillen nicht sieht, sieht die Laufrichtung nicht.
@export var rillenfarbe := Color(0.67, 0.65, 0.53)

## Dicke des Bandkörpers. Der Ursprung liegt in seiner MITTE (wie bei
## `Wasserplattform`), die Trittfläche also `DICKE * 0.5` darüber.
const DICKE := 0.26
## Höhe der Trage-Zone. Reicht bis über Kopf, damit ein Schritt auf der
## Stelle oder eine Landung nicht durch das Zonenraster fällt.
const ZONE_HOEHE := 1.4
const RILLE_HOCH := 0.07        ## so weit stehen die Rillen über dem Band
const RILLE_TIEF := 0.16        ## Länge der Rille in Laufrichtung
const RAND := 0.12              ## Breite der Seitenwangen

var _zeit := 0.0
var _zone: Area3D
var _rillen: Array[MeshInstance3D] = []
var _rollen: Array[MeshInstance3D] = []
var _abstand := 1.0             ## gerundeter Rillenabstand
var _rollenradius := 0.2


func _ready() -> void:
	add_to_group("fliessbaender")
	# Der Boden steht still, das Tragen macht die Zone. Ein kinematischer
	# Körper meldete hier nur eine Geschwindigkeit, die es gar nicht gibt.
	sync_to_physics = false
	collision_layer = 1
	collision_mask = 0
	if ort == Vector3.ZERO:
		ort = position
	_aufbauen()
	# Ort und Drehung zusammen in EINEM Schreibzugriff auf `transform`:
	# Bei einem Körper unter der Hoheit des Physikservers liest ein zweiter,
	# getrennter Zugriff den noch alten Ursprung zurück und setzt ihn wieder
	# ein – das Band bliebe im Nullpunkt stehen.
	transform = Transform3D(Basis(Vector3.UP, drehung), ort)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_zeit += delta
	_optik(delta)
	_tragen(delta)


## Schiebt jeden, der auf dem Band steht, um ein Bild weiter.
func _tragen(delta: float) -> void:
	if _zone == null or is_zero_approx(tempo):
		return
	var schub := _laufrichtung() * tempo * delta
	for koerper in _zone.get_overlapping_bodies():
		if not (koerper is Spieler):
			continue
		var s := koerper as Spieler
		# Nur wer Boden unter den Füßen hat. Ohne diese Frage risse das Band
		# auch den mit, der gerade darüber hinwegspringt – und ein Sprung,
		# der in der Luft die Richtung wechselt, ist nicht mehr lesbar.
		if s.is_on_floor():
			s.move_and_collide(schub)


## Rillen wandern, Rollen drehen sich.
func _optik(delta: float) -> void:
	var laenge := groesse.y
	var versatz := fposmod(_zeit * tempo, laenge)
	var vz := _vorzeichen()
	for i in _rillen.size():
		var r := _rillen[i]
		if not is_instance_valid(r):
			continue
		# Die Rille läuft in Laufrichtung und beginnt am anderen Ende neu.
		# Weil der Abstand die Länge glatt teilt, rückt im selben Moment die
		# nächste Rille genau einen Abstand nach – das Muster bleibt dicht.
		var s := fposmod(float(i) * _abstand + versatz * vz, laenge)
		r.position.z = -laenge * 0.5 + s
	for rolle in _rollen:
		if is_instance_valid(rolle):
			rolle.rotation.x += tempo / _rollenradius * delta * vz


## Einheitsvektor der Laufrichtung in Weltkoordinaten.
func _laufrichtung() -> Vector3:
	return (global_transform.basis * Vector3(0.0, 0.0, -1.0)).normalized() \
			* _vorzeichen()


func _vorzeichen() -> float:
	return 1.0 if richtung >= 0 else -1.0


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()
	_rillen.clear()
	_rollen.clear()

	var laenge := groesse.y
	var zahl := maxi(int(round(laenge / maxf(hub, 0.2))), 2)
	_abstand = laenge / float(zahl)
	_rollenradius = DICKE * 0.62

	_band_bauen()
	_rollen_bauen()
	_rillen_bauen(zahl)

	var form := BoxShape3D.new()
	form.size = Vector3(groesse.x, DICKE, groesse.y)
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	add_child(kollision)

	_zone = Area3D.new()
	_zone.name = "Zone"
	_zone.collision_layer = 0
	_zone.collision_mask = 2       # nur den Spieler beachten
	add_child(_zone)
	var zonenform := BoxShape3D.new()
	# Eine Spur schmaler als das Band: Wer nur mit der Schulter über die
	# Kante ragt, steht schon nicht mehr darauf.
	zonenform.size = Vector3(groesse.x * 0.96, ZONE_HOEHE, groesse.y * 0.96)
	var zonenknoten := CollisionShape3D.new()
	zonenknoten.name = "Form"
	zonenknoten.shape = zonenform
	zonenknoten.position.y = DICKE * 0.5 + ZONE_HOEHE * 0.5 - 0.12
	_zone.add_child(zonenknoten)


## Bandkörper und Seitenwangen.
func _band_bauen() -> void:
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.kasten(Vector3(groesse.x - RAND * 2.0, DICKE, groesse.y)),
			Transform3D())
	_netz("Band", st, Materialbibliothek.metall(bandfarbe), true)

	# Die Wangen schließen bündig mit der Trittfläche ab. Stünden sie höher,
	# hätte das Band eine sichtbare Kante, die es in der Kollision nicht
	# gibt – der Spieler liefe hindurch, und das sähe kaputt aus.
	var rahmen := PropWerkzeug.bauer()
	for seite: float in [-1.0, 1.0]:
		PropWerkzeug.anfuegen(rahmen,
				PropWerkzeug.kasten(Vector3(RAND, DICKE * 1.5, groesse.y)),
				Transform3D(Basis(), Vector3(
						seite * (groesse.x - RAND) * 0.5,
						DICKE * 0.5 - DICKE * 0.75, 0.0)))
	_netz("Wangen", rahmen, Materialbibliothek.metall(Farben.ROST), true)


## Umlenkrollen an beiden Enden. Sie sind der zweite Richtungshinweis –
## und der einzige, der auch von der Seite noch zu sehen ist.
func _rollen_bauen() -> void:
	var material := Materialbibliothek.metall(Farben.ROST_HELL)
	var breite := groesse.x - RAND * 2.0
	for seite: float in [-1.0, 1.0]:
		var st := PropWerkzeug.bauer()
		# Walze quer zum Band: Der Zylinder steht in Godot auf Y, also um
		# 90° um Z gekippt.
		PropWerkzeug.anfuegen(st,
				PropWerkzeug.stumpf(_rollenradius, _rollenradius, breite, 10, true),
				Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3.ZERO))
		# Zwei Nuten längs der Walze. Ohne sie drehte sich eine glatte Walze
		# für das Auge überhaupt nicht.
		for i in 3:
			var a := PI * float(i) / 3.0
			PropWerkzeug.anfuegen(st,
					PropWerkzeug.kasten(Vector3(breite * 0.98, _rollenradius * 0.26,
							_rollenradius * 2.1)),
					PropWerkzeug.ort(Vector3.ZERO, Vector3(a, 0.0, 0.0)))
		var knoten := PropWerkzeug.mesh_knoten("Rolle", PropWerkzeug.fertig(st),
				material, true)
		if knoten == null:
			continue
		knoten.position = Vector3(0.0, 0.0, seite * groesse.y * 0.5)
		add_child(knoten)
		_rollen.append(knoten)


## Querrillen. Alle teilen sich EIN Netz und sind nur als Knoten getrennt –
## anders ließen sie sich nicht einzeln wandern lassen.
func _rillen_bauen(zahl: int) -> void:
	var netz := PropWerkzeug.kasten(Vector3(groesse.x - RAND * 2.2,
			RILLE_HOCH, RILLE_TIEF))
	var material := Materialbibliothek.einfarbig(rillenfarbe, 0.7)
	for i in zahl:
		var knoten := PropWerkzeug.mesh_knoten("Rille%d" % i, netz, material, false)
		if knoten == null:
			continue
		# Knapp über der Trittfläche: bündig flimmerten die beiden Flächen
		# gegeneinander, höher wäre es eine Stolperkante ohne Kollision.
		knoten.position = Vector3(0.0, DICKE * 0.5 + RILLE_HOCH * 0.4,
				-groesse.y * 0.5 + float(i) * _abstand)
		add_child(knoten)
		_rillen.append(knoten)


func _netz(bezeichnung: String, st: SurfaceTool, material: Material,
		schatten: bool) -> void:
	var knoten := PropWerkzeug.mesh_knoten(bezeichnung,
			PropWerkzeug.fertig(st), material, schatten)
	if knoten != null:
		add_child(knoten)
