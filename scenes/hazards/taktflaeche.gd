extends Area3D
class_name Taktflaeche
## Fläche, die im Takt tödlich wird – Stromrinne, Heizplatte, Wandbarriere.
##
## Der Takt hat drei Teile: RUHE (harmlos), WARNUNG (leuchtet auf, noch
## harmlos) und GEFAHR (tödlich). Über `phase` laufen mehrere Flächen
## versetzt; daraus entsteht das eigentliche Rätsel: ein Weg, der nur in
## einem bestimmten Rhythmus begehbar ist.
##
## Die Warnphase ist Pflicht und nicht bloß Zierat. Eine Fläche, die ohne
## Vorlauf umschaltet, kann man nur auswendig lernen; mit Vorlauf kann man
## sie lesen. Wer beim Aufleuchten losläuft, kommt durch – das ist die
## Zusage, die dieses Bauteil dem Spieler macht.
##
## `senkrecht` stellt dieselbe Fläche auf die Kante. Damit ist sie statt
## eines gefährlichen Bodens eine Wand, die sich im Takt öffnet und
## schließt. Es ist bewusst dasselbe Bauteil: Ein Level, das beides
## einsetzt, lehrt seinen Rhythmus einmal und nutzt ihn zweimal.
##
## Der Schaden wird jeden Physikschritt geprüft und nicht nur bei
## `body_entered`. Wer schon auf der Platte steht, wenn sie anspringt,
## betritt sie ja nicht mehr – wie bei `Stacheln`.

enum Takt {
	RUHE,     ## harmlos, dunkel
	WARNUNG,  ## harmlos, leuchtet pulsierend auf
	GEFAHR,   ## tödlich
}

## Ausdehnung in Metern. Waagerecht: X mal Z. Senkrecht: X mal Höhe.
@export var flaeche := Vector2(4.0, 4.0):
	set(wert):
		flaeche = wert
		if is_inside_tree():
			_aufbauen()

## Länge eines vollen Durchlaufs in Sekunden – die Uhr dieses Bauteils.
##
## TAKTVERTRAG (doku/level-vorbilder.md): In einem Abschnitt schlägt alles
## auf derselben Uhr, und die Uhr läuft in ganzen Sekunden. Erlaubt sind
## nur 1,0 · 2,0 · 4,0; nur dann wiederholt sich das gemeinsame Muster
## mehrerer Taktgeber schnell genug, dass man es lernen kann. Vorher lief
## dieses Bauteil auf 3,8 s und der Feuerspeier auf 3,6 s – gemeinsames
## Muster erst nach 68,4 Sekunden, also nie.
@export var takt := 4.0

## Dauer der Vorwarnung. Unter 0,4 s bleibt keine Zeit zum Reagieren.
@export var warnzeit := 0.6

## Dauer der tödlichen Phase.
@export var gefahr_zeit := 1.2

## Verschiebt den Takt gegenüber anderen Flächen, 0…1 = Anteil eines
## vollen Durchlaufs. Damit werden aus gleichen Platten eine Welle.
@export var phase := 0.0

## Farbe der ruhenden Fläche.
@export var farbe_ruhe := Color(0.24, 0.26, 0.30)

## Farbe der tödlichen Fläche. Sie soll im Level sonst nirgends vorkommen –
## Gefahr muss an der Farbe zu erkennen sein, bevor man die Form erkennt.
@export var farbe_gefahr := Farben.WARNUNG

## Stellt die Fläche in die Senkrechte: aus dem Boden wird eine Barriere.
@export var senkrecht := false:
	set(wert):
		senkrecht = wert
		if is_inside_tree():
			_aufbauen()

const DICKE := 0.10             ## Stärke der sichtbaren Platte
const ZONE_HOEHE := 1.0         ## Höhe der Schadenszone über dem Boden
const ZONE_DICKE := 0.5         ## Tiefe der Schadenszone bei einer Wand
const WARN_PULS := 7.0          ## Pulsschläge je Sekunde in der Warnphase
const WARN_HUB := 0.05          ## Ausschlag des Pulsierens in Metern
const GEFAHR_LEUCHTEN := 1.6    ## Leuchtstärke in der Gefahrphase

var _platte: MeshInstance3D
var _kollision: CollisionShape3D
var _stoff: StandardMaterial3D  ## eigene Kopie, weil sie animiert wird
var _zeit := 0.0
var _lage := Takt.RUHE


func _ready() -> void:
	add_to_group("gefahren")
	collision_layer = 0
	collision_mask = 2          # nur den Spieler beachten
	monitoring = true
	_aufbauen()
	_takt_rechnen()
	body_entered.connect(_auf_koerper)


func _physics_process(delta: float) -> void:
	_zeit += delta
	_takt_rechnen()
	if not ist_gefaehrlich():
		return
	for koerper in get_overlapping_bodies():
		if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
			koerper.schaden_nehmen()


## Ist die Fläche gerade tödlich? Level und Prüfwerkzeuge fragen darüber
## ab, ob eine Stelle im Moment passierbar ist.
func ist_gefaehrlich() -> bool:
	return _lage == Takt.GEFAHR


# ---------------------------------------------------------------- Takt

## Bestimmt die Stelle im Takt und färbt die Platte entsprechend.
func _takt_rechnen() -> void:
	var runde := maxf(takt, 0.1)
	# Die Ruhe ist der Rest, nicht ein eigener Wert: So bleibt `takt` die
	# Uhr, und Warn- und Gefahrzeit bleiben absolute Reaktionszeiten, die
	# nicht mitskalieren dürfen.
	var ruhe_zeit := maxf(runde - warnzeit - gefahr_zeit, 0.2)
	var p := fposmod(_zeit + phase * runde, runde)
	if p < ruhe_zeit:
		_lage = Takt.RUHE
		_bild_stellen(0.0)
	elif p < ruhe_zeit + warnzeit:
		_lage = Takt.WARNUNG
		# Die Farbe wandert über die ganze Warnzeit hinüber, statt zu
		# springen: So ist nicht nur ZU SEHEN, dass es gleich losgeht,
		# sondern auch WIE BALD.
		_bild_stellen((p - ruhe_zeit) / maxf(warnzeit, 0.01))
	else:
		_lage = Takt.GEFAHR
		_bild_stellen(1.0)


## Färbt und bewegt die Platte. `anteil` 0 = ruhig, 1 = voll gefährlich.
func _bild_stellen(anteil: float) -> void:
	if _stoff == null or not is_instance_valid(_platte):
		return
	var puls := 0.0
	if _lage == Takt.WARNUNG:
		puls = 0.5 + 0.5 * sin(_zeit * TAU * WARN_PULS)
	var leuchten := 0.0
	match _lage:
		Takt.WARNUNG:
			leuchten = puls * GEFAHR_LEUCHTEN * 0.7
		Takt.GEFAHR:
			leuchten = GEFAHR_LEUCHTEN
	_stoff.albedo_color = farbe_ruhe.lerp(farbe_gefahr, anteil)
	_stoff.emission = farbe_gefahr
	_stoff.emission_energy_multiplier = leuchten
	# Zusätzlich zum Leuchten ein Zucken quer zur Platte. Farbe allein geht
	# in einem bunten Level unter, Bewegung fängt den Blick auch am Rand.
	_platte.position = _ruhelage() + _dickeachse() * (puls * WARN_HUB)


## Richtung, in der die Platte dünn ist – die Achse, auf der sie pulsiert.
func _dickeachse() -> Vector3:
	return Vector3.BACK if senkrecht else Vector3.UP


## Mittelpunkt der sichtbaren Platte in Eigenkoordinaten. Beide Lagen
## sitzen mit ihrer Unterkante auf y = 0, damit `strecke`/`hoehe` im Level
## dasselbe bedeuten wie beim Boden.
func _ruhelage() -> Vector3:
	if senkrecht:
		return Vector3(0.0, flaeche.y * 0.5, 0.0)
	return Vector3(0.0, DICKE * 0.5, 0.0)


# ---------------------------------------------------------------- Aufbau

func _aufbauen() -> void:
	if _platte == null:
		_platte = MeshInstance3D.new()
		_platte.name = "Platte"
		_platte.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_platte)
	if _stoff == null:
		# Kopie: Die Bibliothek gibt geteilte Materialien zurück, und dieses
		# hier ändert seine Farbe im Takt.
		_stoff = Materialbibliothek.leuchtend(farbe_gefahr).duplicate() as StandardMaterial3D
		_stoff.roughness = 0.7
		_platte.material_override = _stoff

	var kasten := BoxMesh.new()
	kasten.size = _plattenmass()
	_platte.mesh = kasten
	_platte.position = _ruhelage()

	if _kollision == null:
		_kollision = CollisionShape3D.new()
		_kollision.name = "Kollision"
		add_child(_kollision)
	var form := BoxShape3D.new()
	form.size = _zonenmass()
	_kollision.shape = form
	_kollision.position = Vector3(0.0, form.size.y * 0.5, 0.0)


## Maße der sichtbaren Platte.
func _plattenmass() -> Vector3:
	if senkrecht:
		return Vector3(flaeche.x, flaeche.y, DICKE)
	return Vector3(flaeche.x, DICKE, flaeche.y)


## Maße der Schadenszone. Waagerecht reicht sie über die Platte hinauf,
## sonst liefe der Spieler auf ihr, ohne sie je zu berühren – seine Kapsel
## beginnt erst an der Fußsohle.
func _zonenmass() -> Vector3:
	if senkrecht:
		return Vector3(flaeche.x, flaeche.y, ZONE_DICKE)
	return Vector3(flaeche.x, ZONE_HOEHE, flaeche.y)


func _auf_koerper(koerper: Node3D) -> void:
	if not ist_gefaehrlich():
		return
	if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
		koerper.schaden_nehmen()
