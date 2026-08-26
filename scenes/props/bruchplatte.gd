extends AnimatableBody3D
class_name Bruchplatte
## Bretterplattform, die trägt – aber nur kurz.
##
## Wer sie betritt, löst eine Frist aus: Die Platte wackelt, kippt weg und
## fällt in die Tiefe. Nach einer Weile steht sie wieder da.
##
## Das Wackeln ist der eigentliche Kern des Bauteils, nicht das Fallen.
## Eine Platte, die ohne Vorwarnung verschwindet, ist keine Aufgabe,
## sondern eine Falle: Beim ersten Mal stirbt man garantiert, beim zweiten
## Mal weiß man es auswendig. Erst die sichtbare Vorwarnung macht daraus
## eine Frage, die man beim ersten Anlauf beantworten kann – und zwar
## dieselbe Frage wie beim Sprung über eine Lücke: "reicht die Zeit?"
##
## Gewackelt wird nur das SICHTBARE, nie der Kollisionskörper. Ein Boden,
## der im Zentimeterbereich zittert, lässt den Spieler abwechselnd fallen
## und landen; dieselbe Trennung wie bei `Wasserplattform`.
##
## `sync_to_physics` steht an, damit `CharacterBody3D` die Platte beim
## Absacken als bewegten Boden erkennt.

enum Zustand {
	RUHT,      ## steht fest, wartet auf einen Fuß
	WACKELT,   ## Vorwarnung läuft, trägt aber noch
	FAELLT,    ## durchlässig, sackt beschleunigt weg
	WEG,       ## unsichtbar, wartet auf die Rückkehr
}

## Kantenlängen des Decks in Metern (X mal Z).
@export var groesse := Vector2(2.6, 2.6)

## Dauer der Vorwarnung, ab dem Betreten. Kürzer als 0,4 s ist unfair –
## so lange braucht ein Spieler, um das Zittern überhaupt zu bemerken.
@export var warnzeit := 0.6

## Dauer des Fallens, bis die Platte ganz verschwindet.
@export var fallzeit := 1.2

## Wartezeit im Verborgenen, bevor die Platte zurückkehrt.
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0,
## damit mehrere Taktgeber nebeneinander ein lernbares Muster ergeben.
## Warnzeit + Fallzeit + Wartezeit ergeben 0,6 + 1,2 + 2,2 = 4,0 s.
@export var wartezeit := 2.2

## Kommt die Platte zurück? Ohne Rückkehr ist eine verpasste Stelle
## endgültig – nur für Wege sinnvoll, die es zweimal gibt.
@export var kehrt_zurueck := true

## Drehung um die Hochachse, damit das Deck zum Wegverlauf passt.
@export var drehung := 0.0

## Anstrich der Bretter. Alpha 0 = Vorgabe (verwittertes Holz).
@export var farbe := Color(0, 0, 0, 0)

## Feste Saat für die Streuung der Bretter und des Wackelns.
@export var saat := 0

const DECK_STAERKE := 0.28       ## Höhe des Kollisionskastens
const MELDE_HOEHE := 0.45        ## Höhe der Fühlzone über dem Deck
const WACKEL_WEITE := 0.045      ## größter Ausschlag am Ende der Warnzeit
const WACKEL_TEMPO := 26.0       ## Zittern je Sekunde
const KIPP_WINKEL := 0.09        ## Schräglage, in die die Platte wegkippt
const SINK_BESCHLEUNIGUNG := 22.0  ## m/s², spürbar schneller als der Spieler

var _bild: Node3D                ## alles Sichtbare, wackelt und kippt
var _melder: Area3D              ## flache Zone knapp über dem Deck
var _rng: RandomNumberGenerator
var _ruhe := Vector3.ZERO        ## Ausgangsort in Elternkoordinaten
var _zustand := Zustand.RUHT
var _uhr := 0.0                  ## Laufzeit im aktuellen Zustand


func _ready() -> void:
	add_to_group("bruchplatten")
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_rng = PropWerkzeug.zufall(saat if saat != 0 else 1)
	_ruhe = position
	_aufbauen()
	_stellen(0.0)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_uhr += delta
	match _zustand:
		Zustand.RUHT:
			if _jemand_drauf():
				_wechseln(Zustand.WACKELT)
		Zustand.WACKELT:
			_wackeln()
			if _uhr >= warnzeit:
				_wechseln(Zustand.FAELLT)
		Zustand.FAELLT:
			# Freier Fall aus dem Stand: Weg = ½·a·t².
			_stellen(SINK_BESCHLEUNIGUNG * _uhr * _uhr * 0.5)
			if _uhr >= fallzeit:
				_wechseln(Zustand.WEG)
		Zustand.WEG:
			if kehrt_zurueck and _uhr >= wartezeit:
				_wechseln(Zustand.RUHT)


## Trägt die Platte gerade noch?
func ist_tragfaehig() -> bool:
	return _zustand == Zustand.RUHT or _zustand == Zustand.WACKELT


## Stellt die Platte sofort wieder her – für den Neustart am Checkpoint.
## Ohne das fände ein zurückgesetzter Spieler eine Lücke vor, die er
## selbst gerissen hat, und stünde vor einer Wartezeit statt vor der Stelle.
func zuruecksetzen() -> void:
	_wechseln(Zustand.RUHT)


# ---------------------------------------------------------------- Zustand

func _wechseln(neu: int) -> void:
	_zustand = neu
	_uhr = 0.0
	match neu:
		Zustand.RUHT:
			# Erst der Ort, dann sichtbar und fest: In umgekehrter Reihenfolge
			# blitzte die Platte einen Bildschritt lang am Fallort auf.
			_stellen(0.0)
			if is_instance_valid(_bild):
				_bild.position = Vector3.ZERO
				_bild.rotation = Vector3.ZERO
			visible = true
			collision_layer = 1
			# Sonst zöge die Bildinterpolation eine Schliere vom Fallort
			# herauf – die Platte ist gesprungen, nicht geflogen.
			if is_inside_tree():
				reset_physics_interpolation()
		Zustand.FAELLT:
			# Durchlässig ab dem ersten Bild des Falls – die Platte soll dem
			# Spieler unter den Füßen wegbrechen, nicht ihn mitnehmen.
			collision_layer = 0
			if is_instance_valid(_bild):
				_bild.rotation.z = _rng.randf_range(-KIPP_WINKEL, KIPP_WINKEL)
				_bild.rotation.x = _rng.randf_range(-KIPP_WINKEL, KIPP_WINKEL)
		Zustand.WEG:
			visible = false


## Fühlt, ob jemand auf dem Deck steht.
##
## Über eine Area3D und nicht über `get_colliding_bodies()`: Die Platte ist
## ein `AnimatableBody3D` und meldet Berührungen von sich aus nicht.
func _jemand_drauf() -> bool:
	if _melder == null:
		return false
	for koerper in _melder.get_overlapping_bodies():
		if koerper.is_in_group("spieler"):
			return true
	return false


## Zittern als Vorwarnung. Der Ausschlag wächst über die Warnzeit an,
## damit sich das Ablaufen der Frist ablesen lässt und nicht nur ihr Beginn.
func _wackeln() -> void:
	if not is_instance_valid(_bild):
		return
	var staerke := WACKEL_WEITE * (_uhr / maxf(warnzeit, 0.01))
	_bild.position = Vector3(
			sin(_uhr * WACKEL_TEMPO) * staerke,
			sin(_uhr * WACKEL_TEMPO * 1.7) * staerke * 0.6,
			cos(_uhr * WACKEL_TEMPO * 1.3) * staerke)


## Setzt Ort und Drehung in EINEM Schreibzugriff auf `transform`.
##
## Getrennt geht es nicht: Bei `sync_to_physics` steht der Knoten unter der
## Hoheit des Physikservers; ein Schreiben auf `position` wirkt erst im
## nächsten Schritt, und ein anschließendes Schreiben auf `rotation` liest
## den alten Ursprung zurück und setzt ihn wieder ein.
func _stellen(sinktiefe: float) -> void:
	transform = Transform3D(Basis(Vector3.UP, drehung),
			_ruhe - Vector3.UP * sinktiefe)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	for kind in get_children():
		kind.queue_free()

	_bild = Node3D.new()
	_bild.name = "Bild"
	add_child(_bild)
	_bretter_bauen()

	var form := BoxShape3D.new()
	form.size = Vector3(groesse.x, DECK_STAERKE, groesse.y)
	var kollision := CollisionShape3D.new()
	kollision.name = "Kollision"
	kollision.shape = form
	add_child(kollision)

	_melder_bauen()


## Eine Lage Bretter quer zum Weg, dazu zwei Beschläge an den Stirnseiten.
## Die Fugen sind Absicht: Erst an ihnen ist von oben zu erkennen, dass hier
## Holz liegt und kein Stein – und Holz traut man das Nachgeben zu.
func _bretter_bauen() -> void:
	var st := PropWerkzeug.bauer()
	var bretter := maxi(int(groesse.y / 0.42), 2)
	var breite := groesse.y / float(bretter)
	for i in bretter:
		var z := -groesse.y * 0.5 + breite * (i + 0.5)
		var brett := PropWerkzeug.kasten(Vector3(
				groesse.x * _rng.randf_range(0.97, 1.0),
				DECK_STAERKE * 0.82,
				breite * 0.86))
		PropWerkzeug.anfuegen(st, brett, Transform3D(Basis(), Vector3(0, 0, z)))
	var knoten := PropWerkzeug.mesh_knoten("Bretter",
			PropWerkzeug.fertig(st), _stoff(), true)
	if knoten != null:
		_bild.add_child(knoten)

	var beschlag := PropWerkzeug.bauer()
	for seite in [-1.0, 1.0]:
		var band := PropWerkzeug.kasten(
				Vector3(0.12, DECK_STAERKE * 1.05, groesse.y))
		PropWerkzeug.anfuegen(beschlag, band, Transform3D(Basis(),
				Vector3(seite * (groesse.x * 0.5 - 0.09), 0.0, 0.0)))
	var beschlagknoten := PropWerkzeug.mesh_knoten("Beschlag",
			PropWerkzeug.fertig(beschlag),
			Materialbibliothek.metall(Farben.ROST), false)
	if beschlagknoten != null:
		_bild.add_child(beschlagknoten)


## Flache Zone knapp über dem Deck, die nur den Spieler beachtet.
func _melder_bauen() -> void:
	_melder = Area3D.new()
	_melder.name = "Melder"
	_melder.collision_layer = 0
	_melder.collision_mask = 2     # nur den Spieler beachten
	var form := BoxShape3D.new()
	form.size = Vector3(groesse.x, MELDE_HOEHE, groesse.y)
	var kollision := CollisionShape3D.new()
	kollision.name = "Form"
	kollision.shape = form
	kollision.position.y = DECK_STAERKE * 0.5 + MELDE_HOEHE * 0.5
	_melder.add_child(kollision)
	add_child(_melder)


## Anstrich: eigene Farbe, sonst verwittertes Stegholz.
## Bei eigener Farbe eine Kopie – Rückgaben der Bibliothek sind geteilt.
func _stoff() -> Material:
	if farbe.a <= 0.0:
		return Materialbibliothek.bohlen()
	var m := Materialbibliothek.bohlen().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	return m
