extends Gegner
class_name Werfer
## Werfer – bleibt auf seinem Podest und wirft Geschosse im Bogen.
##
## Vorbild sind die Affen auf den Podesten der Festung und die Gorillas
## der Sturmruinen: Sie kommen nicht zu einem, sie halten einen auf
## Abstand. Deshalb patrouilliert er nicht (`patrouille_weite = 0`),
## sondern dreht sich nur zum Spieler und wirft im Takt.
##
## NUR durch den Drehschlag (oder den Bauchplatscher) zu besiegen – und
## das ist Absicht: Ein Gegner, dem man nur ausweichen kann, wird zur
## Wand. So gibt es eine Antwort, die den Weg wieder freimacht. Wer das
## Geschoss stattdessen im Flug zurückschlägt, erwischt ihn auch damit
## (siehe `geschoss.gd`).
##
## ZEICHENSPRACHE:
##   * Dornenkamm auf Kopf und Schultern  -> Draufspringen fällt aus.
##   * Er steht auf einem Podest          -> unten ist nichts zu holen,
##                                           der Slide läuft ins Leere.
##   * Heller Brustgurt auf Schlaghöhe    -> hier wirkt der Drehschlag.
##
## Das Ausholen ist Pflicht und nicht Zierde: Ein Wurf ohne Vorwarnung
## ist nicht auszuweichen, weil das Geschoss von weit her kommt und der
## Spieler den Werfer im Rücken der Kamera oft gar nicht sieht. Der Arm
## geht deshalb sichtbar über den Kopf zurück, der Körper lehnt mit.

const GESCHOSS_SZENE := preload("res://scenes/enemies/Geschoss.tscn")

## Sekunden zwischen zwei Würfen (gemessen ab dem Wurf, das Ausholen
## liegt darin).
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0,
## damit mehrere Taktgeber nebeneinander ein lernbares Muster ergeben.
@export var wurftakt := 2.0
## Weiter entfernte Spieler lässt er in Ruhe.
@export var wurfweite := 14.0
## Wie lange er sichtbar ausholt, bevor das Geschoss fliegt.
@export var vorholzeit := 0.5
## Womit er wirft.
@export var geschossart: Geschoss.Art = Geschoss.Art.STAMM

# ---------------------------------------------------------- Farben
#
# Der Werfer steht in Festung, Ruine und Halle. Die Farben waren schon
# einstellbar, wirkten aber nur, solange sie VOR dem Einhängen gesetzt
# wurden – die Optik entsteht in `_baue()`, also in `_ready()`. Jetzt
# baut jeder Setzer sie neu auf (siehe `_neu_faerben()`).
#
# ZEICHENSPRACHE (siehe gegner.gd): Der Brustgurt liegt auf Schlaghöhe
# und ist die einzige leuchtende Fläche am ganzen Gegner – dorthin zielt
# der Drehschlag. Er muss HELL gegen das Fell stehen bleiben. Die Dornen
# auf Kopf und Schultern hängen absichtlich am Fellton (`darkened`) und
# sind nicht einzeln einstellbar: So können sie nie im Fell verschwinden,
# egal welche Farbe ein Level wählt.

## Fellfarbe des Körpers. Dornen und Podestkante leiten sich daraus ab.
@export var farbe_fell := Farben.RINDE_DUNKEL:
	set(wert):
		farbe_fell = wert
		_neu_faerben()
## Farbe der freien Bauchseite und des Gesichts.
@export var farbe_bauch := Farben.ERDE_HELL:
	set(wert):
		farbe_bauch = wert
		_neu_faerben()
## Signalfarbe des Brustgurts – die Stelle, an der der Drehschlag wirkt.
@export var farbe_gurt := Farben.KISTE_FEDER:
	set(wert):
		farbe_gurt = wert
		_neu_faerben()
## Steinfarbe des Podests.
@export var farbe_podest := Farben.FELS:
	set(wert):
		farbe_podest = wert
		_neu_faerben()
## Augenpunkte.
@export var farbe_augen := Farben.WARNUNG:
	set(wert):
		farbe_augen = wert
		_neu_faerben()
## Baut das Podest mit. Aus, wenn das Level ihn schon erhöht aufstellt.
@export var mit_podest := true

## Höhe des Podests – die Figur steht darauf.
const PODEST_HOEHE := 0.34
## Ruhewinkel des Wurfarms (leicht nach hinten hängend).
const ARM_RUHE := 0.25
## Wie weit der Arm beim Ausholen zurückgeht (über den Kopf).
const ARM_AUSHOLEN := -2.5
## Wie weit er beim Wurf durchschwingt.
const ARM_WURF := 1.5
## So schnell fällt der Arm nach dem Wurf in die Ruhelage zurück.
const ARM_RUECKKEHR := 4.5
## Höhe über den Füßen des Spielers, auf die gezielt wird (Brust).
const ZIEL_HOEHE := 0.6
## Anteil der Spielerbewegung, den er vorhält.
##
## Volles Vorhalten träfe jeden, der geradeaus weiterläuft – dagegen hülfe
## nur Stehenbleiben, und Stehenbleiben ist in einem Rennspiel keine
## Antwort. Ohne Vorhalten dagegen landete jedes Geschoss hinter einem
## laufenden Spieler, und der Werfer wäre Dekoration. Die Hälfte trifft
## den, der stur weiterrennt, und geht an dem vorbei, der springt,
## abbremst oder die Spur wechselt.
const VORHALT := 0.5

enum Lage {WARTEN, AUSHOLEN}

var _lage: int = Lage.WARTEN
var _rest := 0.0
var _schwung := 0.0        ## klingt nach dem Wurf ab (1 -> 0)

var _podest: Node3D
var _rumpf: Node3D
var _wurfarm: Node3D
var _haltearm: Node3D
var _hand: Node3D
var _kopf: Node3D


func _init() -> void:
	# Der Drehschlag kommt an die freie Flanke, der Bauchplatscher an alles.
	besiegbar_durch = Angriff.SPIN | Angriff.SLAM
	patrouille_weite = 0.0
	tempo = 0.0
	fruechte = 2


func _ready() -> void:
	super._ready()
	# Versetzter Takt, damit zwei Werfer nebeneinander nicht im Gleichschritt
	# werfen – zwei gleichzeitige Geschosse sind kein Rhythmus, sondern Zufall.
	_rest = wurftakt * randf()


# ---------------------------------------------------------- Optik

## Kräftige Silhouette: breite Schultern, lange Arme, kurze Beine. Die
## Arme sind absichtlich übertrieben lang – die Wurfbewegung muss über
## die halbe Korridorbreite hinweg zu lesen sein.
func _baue() -> void:
	var fell := Materialbibliothek.fell(farbe_fell)
	var bauch := Materialbibliothek.einfarbig(farbe_bauch, 0.7)
	var gurt := Materialbibliothek.leuchtend(farbe_gurt, 0.9)
	var dunkel := Materialbibliothek.einfarbig(farbe_fell.darkened(0.45), 0.6)
	var stein := Materialbibliothek.einfarbig(farbe_podest, 0.9)
	var auge := Materialbibliothek.leuchtend(farbe_augen, 1.2)

	var fuss := PODEST_HOEHE if mit_podest else 0.0

	if mit_podest:
		# Eigener Knoten außerhalb des Rumpfs: Beim Sterben fliegt die
		# Figur weg, das Podest soll das nicht mitmachen (siehe _todesstart).
		_podest = Node3D.new()
		_podest.name = "Podest"
		modell.add_child(_podest)
		_teil(_podest, _quader(Vector3(1.5, PODEST_HOEHE, 1.5)), stein,
				Vector3(0.0, PODEST_HOEHE * 0.5, 0.0), Vector3.ZERO,
				Vector3.ONE, "Block")
		_teil(_podest, _quader(Vector3(1.66, 0.1, 1.66)), dunkel,
				Vector3(0.0, PODEST_HOEHE, 0.0), Vector3.ZERO,
				Vector3.ONE, "Deckplatte")

	# --- Beine: kurz und breit, damit er wie festgewachsen wirkt ---
	for seite: float in [-1.0, 1.0]:
		_teil(modell, _zylinder(0.19, 0.16, 0.46, 7), fell,
				Vector3(0.26 * seite, fuss + 0.23, 0.0), Vector3.ZERO,
				Vector3.ONE, "Bein")
		_teil(modell, _quader(Vector3(0.3, 0.12, 0.44)), dunkel,
				Vector3(0.28 * seite, fuss + 0.06, -0.06), Vector3.ZERO,
				Vector3.ONE, "Fuss")

	# --- Rumpf: eigener Knoten, damit er beim Ausholen zurücklehnen kann ---
	_rumpf = Node3D.new()
	_rumpf.name = "Rumpf"
	_rumpf.position = Vector3(0.0, fuss + 0.46, 0.0)
	modell.add_child(_rumpf)

	_teil(_rumpf, _kugel(0.46, 12, 8), fell, Vector3(0.0, 0.34, 0.0),
			Vector3.ZERO, Vector3(1.12, 1.05, 0.88), "Brustkorb")
	_teil(_rumpf, _kugel(0.36, 10, 7), bauch, Vector3(0.0, 0.22, -0.14),
			Vector3.ZERO, Vector3(0.94, 1.0, 0.6), "Bauchseite")

	# Brustgurt: der einzige leuchtende Streifen am ganzen Gegner. Er liegt
	# auf Schlaghöhe (rund 0,8 m über dem Boden) – dorthin zielt der Spin.
	_teil(_rumpf, _kugel(0.48, 12, 4), gurt, Vector3(0.0, 0.30, 0.0),
			Vector3(0.0, 0.0, 18.0), Vector3(1.16, 0.2, 0.94), "Brustgurt")

	# --- Kopf mit Dornenkamm: hier springt niemand drauf ---
	_kopf = Node3D.new()
	_kopf.name = "Kopf"
	_kopf.position = Vector3(0.0, 0.86, -0.06)
	_rumpf.add_child(_kopf)
	_teil(_kopf, _kugel(0.28, 12, 8), fell, Vector3.ZERO, Vector3.ZERO,
			Vector3(1.0, 0.95, 1.05), "Schaedel")
	_teil(_kopf, _kugel(0.2, 10, 7), bauch, Vector3(0.0, -0.04, -0.18),
			Vector3.ZERO, Vector3(0.9, 0.8, 0.7), "Gesicht")
	for seite: float in [-1.0, 1.0]:
		_teil(_kopf, _kugel(0.05, 8, 6), auge, Vector3(0.1 * seite, 0.04, -0.27),
				Vector3.ZERO, Vector3.ONE, "Auge")
	for i in 5:
		var laenge := 0.18 + sin(float(i) / 4.0 * PI) * 0.1
		_teil(_kopf, _zylinder(0.05, 0.0, laenge, 5), dunkel,
				Vector3(0.0, 0.24, -0.16 + float(i) * 0.09),
				Vector3(-18.0 + float(i) * 9.0, 0.0, 0.0), Vector3.ONE, "Dorn")

	# --- Schultern mit Dornen und die beiden Arme ---
	for seite: float in [-1.0, 1.0]:
		var schulter := Node3D.new()
		schulter.name = "Schulter" if seite > 0.0 else "SchulterLinks"
		schulter.position = Vector3(0.5 * seite, 0.6, 0.0)
		_rumpf.add_child(schulter)
		_teil(schulter, _kugel(0.24, 10, 7), fell, Vector3.ZERO, Vector3.ZERO,
				Vector3(1.0, 0.9, 1.0), "Schulterballen")
		for j in 3:
			_teil(schulter, _zylinder(0.045, 0.0, 0.16, 5), dunkel,
					Vector3(0.02 * seite, 0.2, -0.12 + float(j) * 0.12),
					Vector3(-10.0 + float(j) * 10.0, 0.0, 12.0 * seite),
					Vector3.ONE, "Schulterdorn")

		# Arm an einem eigenen Gelenk: Oberarm nach unten, Unterarm daran,
		# Hand am Ende. Gedreht wird nur das Gelenk.
		var arm := Node3D.new()
		arm.name = "Arm" if seite > 0.0 else "ArmLinks"
		arm.position = schulter.position
		_rumpf.add_child(arm)
		_teil(arm, _zylinder(0.14, 0.12, 0.48, 7), fell,
				Vector3(0.03 * seite, -0.24, 0.0), Vector3.ZERO,
				Vector3.ONE, "Oberarm")
		_teil(arm, _zylinder(0.12, 0.1, 0.44, 7), fell,
				Vector3(0.05 * seite, -0.66, 0.0), Vector3.ZERO,
				Vector3.ONE, "Unterarm")
		var hand := _teil(arm, _kugel(0.16, 9, 6), bauch,
				Vector3(0.06 * seite, -0.92, 0.0), Vector3.ZERO,
				Vector3(1.0, 0.85, 1.0), "Hand")
		if seite > 0.0:
			_wurfarm = arm
			_hand = hand
		else:
			_haltearm = arm

	if is_instance_valid(_wurfarm):
		_wurfarm.rotation.x = ARM_RUHE
	if is_instance_valid(_haltearm):
		_haltearm.rotation.x = -0.15


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	_zum_spieler_drehen(delta, spieler)

	match _lage:
		Lage.AUSHOLEN:
			_rest -= delta
			if _rest <= 0.0:
				_werfen(spieler)
				_lage = Lage.WARTEN
				_rest = wurftakt
				_schwung = 1.0
		_:
			_rest -= delta
			if _rest <= 0.0 and _in_reichweite(spieler):
				_lage = Lage.AUSHOLEN
				_rest = vorholzeit
				# Hörbare Vorwarnung für alles, was gerade nicht im Bild ist.
				Klang.spiele("slide", 0.7, 0.7)

	_schwung = maxf(_schwung - delta * ARM_RUECKKEHR, 0.0)
	_animiere(delta)


## Steht der Spieler nah genug und ist er überhaupt da?
func _in_reichweite(spieler: Node3D) -> bool:
	if spieler == null:
		return false
	var d := spieler.global_position - global_position
	d.y = 0.0
	return d.length() <= wurfweite


## Dreht die Figur zum Spieler. `_blick_ausrichten()` der Basisklasse
## taugt hier nicht: Das richtet sich nach der Patrouillenachse, und die
## ist bei einem Gegner, der steht, ohne Bedeutung.
func _zum_spieler_drehen(delta: float, spieler: Node3D) -> void:
	if not is_instance_valid(modell) or spieler == null:
		return
	var d := spieler.global_position - global_position
	d.y = 0.0
	if d.length() < 0.2:
		return
	var ziel := atan2(-d.x, -d.z)
	modell.rotation.y = lerp_angle(modell.rotation.y, ziel, minf(delta * 4.0, 1.0))


## Wurfarm, Rumpflehne und ruhiges Atmen.
func _animiere(delta: float) -> void:
	var atmen := sin(_zeit * 1.8 + _phase) * 0.03

	var arm_ziel := ARM_RUHE
	var lehne := 0.0
	if _lage == Lage.AUSHOLEN:
		# Fortschritt des Ausholens: 0 am Anfang, 1 kurz vor dem Wurf.
		var t := 1.0 - clampf(_rest / maxf(vorholzeit, 0.01), 0.0, 1.0)
		arm_ziel = lerpf(ARM_RUHE, ARM_AUSHOLEN, t * t)
		lehne = -0.22 * t
	elif _schwung > 0.0:
		arm_ziel = lerpf(ARM_RUHE, ARM_WURF, _schwung)
		lehne = 0.18 * _schwung

	if is_instance_valid(_wurfarm):
		_wurfarm.rotation.x = lerp_angle(_wurfarm.rotation.x, arm_ziel,
				minf(delta * 14.0, 1.0))
	if is_instance_valid(_haltearm):
		_haltearm.rotation.x = -0.15 + atmen
	if is_instance_valid(_rumpf):
		_rumpf.rotation.x = lerp_angle(_rumpf.rotation.x, lehne,
				minf(delta * 10.0, 1.0))
		_rumpf.scale = Vector3(1.0 + atmen, 1.0 - atmen, 1.0 + atmen)
	if is_instance_valid(_kopf):
		_kopf.rotation.z = sin(_zeit * 1.3) * 0.06


# ---------------------------------------------------------- Wurf

func _werfen(spieler: Node3D) -> void:
	if spieler == null or not _in_reichweite(spieler):
		return

	var geschoss := GESCHOSS_SZENE.instantiate() as Geschoss
	if geschoss == null:
		return
	geschoss.art = geschossart
	# In den Levelknoten hängen, nicht unter den Werfer: Sein Tod nimmt
	# sonst das Geschoss mit, das schon in der Luft ist.
	var elternteil := get_parent()
	if elternteil == null:
		elternteil = self
	elternteil.add_child(geschoss)

	var von := global_position + Vector3.UP * 1.6
	if is_instance_valid(_hand):
		von = _hand.global_position
	geschoss.abschiessen(von, _zielpunkt(spieler, von, geschoss.tempo))


## Wohin gezielt wird: Brusthöhe des Spielers, um `VORHALT` in seine
## Laufrichtung verschoben. Die Flugzeit wird aus dem Abstand geschätzt –
## dieselbe Rechnung wie in `Geschoss.abschiessen()`, hier nur einmal
## vorweggenommen, um die Vorhaltestrecke zu bekommen.
func _zielpunkt(spieler: Node3D, von: Vector3, geschoss_tempo: float) -> Vector3:
	var ziel := spieler.global_position + Vector3.UP * ZIEL_HOEHE
	var koerper := spieler as CharacterBody3D
	if koerper == null:
		return ziel
	var lauf := koerper.velocity
	lauf.y = 0.0
	if lauf.length() < 0.2:
		return ziel
	var d := ziel - von
	var strecke := Vector3(d.x, 0.0, d.z).length()
	var flugzeit := strecke / maxf(geschoss_tempo, 0.1)
	return ziel + lauf * flugzeit * VORHALT


# ---------------------------------------------------------- Tod

func _todesstart(_art: int) -> void:
	# Er kippt vom Podest – das Podest bleibt stehen. Es ist Stein und
	# gehört zum Level, nicht zum Gegner, also hängt es sich aus der
	# sterbenden Figur aus, statt mit ihr davonzufliegen. Aufgeschoben,
	# weil mitten im Physikschritt nicht am Szenenbaum geschraubt wird.
	if is_instance_valid(_podest):
		var eltern := get_parent()
		if eltern != null:
			call_deferred("_podest_abhaengen", eltern, _podest.global_transform)
	_wegflug = _weg_richtung() * 6.0 + Vector3.UP * 7.0


## Hängt das Podest in den Levelknoten um und setzt es an seinen Platz
## zurück – `reparent` allein übernähme die schon verrutschte Sturzlage.
func _podest_abhaengen(eltern: Node, ort: Transform3D) -> void:
	if not is_instance_valid(_podest) or not is_instance_valid(eltern):
		return
	_podest.reparent(eltern, false)
	_podest.global_transform = ort


func _todesanimation(delta: float) -> void:
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.x += delta * 7.0
		modell.rotation.z += delta * 4.0
		modell.scale = modell.scale.lerp(Vector3(0.55, 0.55, 0.55),
				minf(delta * 3.0, 1.0))
	# Die Arme rudern noch – das liest sich als "getroffen", nicht als
	# "ausgeschaltet".
	if is_instance_valid(_wurfarm):
		_wurfarm.rotation.x = sin(_zeit * 22.0) * 1.1
	if is_instance_valid(_haltearm):
		_haltearm.rotation.x = -sin(_zeit * 22.0) * 1.1


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Die Materialien der `Materialbibliothek` sind geteilt und dürfen nicht
## nachträglich verändert werden; also wird die Optik neu gebaut, wie es
## auch die Props halten (`baum.gd`, `deckungsfleck.gd`).
##
## Ein besiegter Werfer wird nicht angefasst: Sein Podest hängt dann
## schon im Levelknoten und die Sturzlage steckt im Modell – ein Neubau
## holte beides zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_podest = null
	_rumpf = null
	_wurfarm = null
	_haltearm = null
	_hand = null
	_kopf = null
	_baue()
	_fremdmodell_setzen()
