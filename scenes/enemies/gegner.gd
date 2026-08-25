extends Node3D
class_name Gegner
## Basisklasse für alle Gegner.
##
## Ein Gegner ist KEIN fester Körper – der Spieler läuft physisch durch ihn
## hindurch. Alles entscheidet die `Area3D` "Trefferzone" (Ebene 0, Maske 2):
##
##   * passende Bewegung des Spielers  ->  `besiegen()`
##   * sonst                           ->  `spieler.schaden_nehmen()`
##
## Welche Bewegung passt, legt `besiegbar_durch` als Bitmaske fest
## (siehe scripts/angriff.gd). `Angriff.FALLEN` (Draufspringen) zählt nur,
## wenn der Spieler auch wirklich oberhalb des Gegners ist.
##
## Die Optik bauen die abgeleiteten Gegner in `_baue()` prozedural auf,
## die Fortbewegung läuft über `_bewegung()`. Beide sind hier leere Haken.
##
## ZEICHENSPRACHE – verbindlich für jeden neuen Gegner:
## Wer nur eine Angriffsart zulässt, muss die anderen SICHTBAR abwehren.
## Der Spieler soll nie ausprobieren müssen, was wirkt.
##
##   Drehschlag wirkt nicht  ->  Stacheln, Klingen oder Draht auf
##                               Schlaghöhe (rund 0,4 bis 1,0 m)
##   Draufspringen wirkt nicht -> Panzer, Zapfen oder Dornen OBEN;
##                               oder der Gegner schwebt außer Reichweite
##   Slide wirkt nicht       ->  nichts Angreifbares unten: flach am Boden
##                               anliegend oder hoch über dem Boden
##
## Umgekehrt gilt: Die Stelle, an der es wirkt, bleibt frei und ist hell
## abgesetzt – bei der Gletscherkrabbe etwa die leuchtende Panzernaht.

## Gravitation der Todesanimation.
const TODES_G := -32.0
## Nach dieser Zeit verschwindet ein besiegter Gegner.
const TODES_DAUER := 1.0
## Wie weit unter dem Gegnerursprung der Spieler höchstens stehen darf,
## damit ein Treffer noch als "von oben" zählt. Verhindert, dass jemand
## von einem tieferen Sims aus mit dem Kopf in die Trefferzone ragt und
## den Gegner damit besiegt.
const UNTERKANTE_TOLERANZ := 0.2

## Bitmaske der Angriffsarten, die diesen Gegner besiegen (siehe Angriff).
@export var besiegbar_durch: int = Angriff.SLAM
## Gesamtbreite der Patrouille (jeweils die Hälfte nach beiden Seiten).
@export var patrouille_weite := 3.0
## Fortbewegungstempo in m/s.
@export var tempo := 2.0
## Achse, auf der patrouilliert wird (Korridor läuft Richtung -Z).
@export var patrouille_achse := Vector3.RIGHT
## Absprunghöhe, wenn der Spieler den Gegner von oben plättet.
@export var abprall_hoehe := 14.0
## So viele Früchte lässt der Gegner fallen.
@export var fruechte := 1

## True, sobald der Gegner besiegt wurde (danach keine Treffer mehr).
var besiegt := false
## Laufrichtung auf der Patrouillenachse (+1 oder -1).
var richtung := 1.0

## Wurzelknoten der prozeduralen Optik – hier hängt alles Sichtbare drunter.
var modell: Node3D
## Die Trefferzone aus der Szene.
var trefferzone: Area3D

var _start_position := Vector3.ZERO
var _zeit := 0.0
var _phase := 0.0
var _tot_zeit := 0.0
var _wegflug := Vector3.ZERO


func _ready() -> void:
	add_to_group("gegner")
	_start_position = global_position
	_phase = randf() * TAU

	modell = Node3D.new()
	modell.name = "Modell"
	add_child(modell)

	trefferzone = get_node_or_null("Trefferzone") as Area3D
	if trefferzone != null:
		trefferzone.collision_layer = 0     # der Gegner selbst kollidiert nicht
		trefferzone.collision_mask = 2      # nur den Spieler beachten
		trefferzone.monitoring = true
		if not trefferzone.body_entered.is_connected(_auf_koerper):
			trefferzone.body_entered.connect(_auf_koerper)

	_baue()
	_fremdmodell_setzen()


func _physics_process(delta: float) -> void:
	_zeit += delta
	if besiegt:
		_tot_zeit -= delta
		_todesanimation(delta)
		if _tot_zeit <= 0.0:
			queue_free()
		return

	_bewegung(delta)
	_pruefe_ueberlappung()


# ---------------------------------------------------------- Haken für Gegner

## Baut die Optik unter `modell` auf. Wird von jedem Gegner überschrieben.
func _baue() -> void:
	pass


## Datei und Zielgröße eines mitgelieferten Modells für diesen Gegner,
## z. B. {"datei": "kroete", "groesse": 1.1}. Leer = nur die eigene Optik.
## Mit {"nach_hoehe": true} zählt die Höhe statt der größten Achse,
## {"drehung": PI} dreht das Modell, {"farben": {...}} färbt Materialien um.
func fremdmodell() -> Dictionary:
	return {}


## Hängt das mitgelieferte Modell ein und blendet die selbst gebaute Optik aus.
##
## Die gebauten Teile bleiben absichtlich im Baum: Die Bewegungslogik jedes
## Gegners greift auf sie zu (Hüpf-Stauchung, Beintakt, Pickbewegung). Sie
## zu entfernen hieße, jede dieser Stellen abzusichern. Unsichtbar
## geschaltet kostet das nichts und kann nichts kaputtmachen.
func _fremdmodell_setzen() -> void:
	var angabe := fremdmodell()
	if angabe.is_empty() or not is_instance_valid(modell):
		return
	var figur := Fremdmodelle.gegner(String(angabe.get("datei", "")),
			float(angabe.get("groesse", 1.0)),
			bool(angabe.get("nach_hoehe", false)),
			float(angabe.get("drehung", 0.0)),
			angabe.get("farben", {}) as Dictionary)
	if figur == null:
		return
	for kind in modell.get_children():
		var sichtbar := kind as Node3D
		if sichtbar != null:
			sichtbar.visible = false
	figur.name = "Fremdmodell"
	modell.add_child(figur)


## Fortbewegung und Animation. Wird von jedem Gegner überschrieben.
func _bewegung(_delta: float) -> void:
	pass


## Startschuss der Todesanimation (z. B. Wegflugrichtung festlegen).
func _todesstart(_art: int) -> void:
	pass


## Todesanimation pro Frame: wegschleudern und überschlagen.
func _todesanimation(delta: float) -> void:
	_wegflug.y += TODES_G * delta
	global_position += _wegflug * delta
	if is_instance_valid(modell):
		modell.rotation.x += delta * 9.0
		modell.rotation.z += delta * 5.0
		modell.scale = modell.scale.lerp(Vector3(0.55, 0.55, 0.55), minf(delta * 3.0, 1.0))


# ---------------------------------------------------------- Trefferlogik

func _auf_koerper(koerper: Node3D) -> void:
	if besiegt or koerper == null:
		return
	if not koerper.is_in_group("spieler"):
		return
	_treffer(koerper as Spieler)


## Prüft laufend, ob der Spieler in der Trefferzone steht. Nötig, weil
## `body_entered` nur beim Eintreten feuert – der Spieler kann aber auch
## erst im Gegner stehen und dann angreifen.
func _pruefe_ueberlappung() -> void:
	if trefferzone == null or not trefferzone.monitoring:
		return
	for koerper in trefferzone.get_overlapping_bodies():
		_auf_koerper(koerper)


## Entscheidet, ob der Spieler den Gegner besiegt oder Schaden nimmt.
func _treffer(spieler: Spieler) -> void:
	if besiegt or spieler == null:
		return

	var maske: int = spieler.angriffe()
	var wirksam: int = maske & besiegbar_durch

	# Draufspringen zählt nur, wenn der Spieler wirklich oberhalb ist.
	if (wirksam & Angriff.FALLEN) != 0 and not _spieler_ist_oben(spieler):
		wirksam &= ~Angriff.FALLEN

	if wirksam != 0:
		if (wirksam & Angriff.FALLEN) != 0:
			spieler.abprallen(abprall_hoehe)
		besiegen(wirksam)
	else:
		spieler.schaden_nehmen()


## Kommt der Spieler von oben?
##
## Entscheidend ist die Fallrichtung, nicht die Höhe. Zwei Anläufe über
## eine Höhenschwelle sind daran gescheitert, dass `Area3D` Überlappungen
## erst im nächsten Physikschritt meldet: Bei 18 m/s ist der Spieler dann
## schon 0,30 m weiter, und ein flacher Gegner kann gar kein Fenster
## bieten, das einen verlorenen Frame samt Messschritt überdeckt. Gemessen
## wurde ein Fehlschlag bei spieler_y = 0,299 gegen eine Schwelle von
## 0,300 – einen Millimeter daneben, nachdem das Bild davor mitten im
## Fenster gelegen hatte.
##
## Dass der Spieler überhaupt fällt, steckt bereits in `Angriff.FALLEN`:
## Das Bit setzt der Spieler nur, wenn er schneller als die Fallschwelle
## sinkt, und behält es 0,25 s lang (`FALL_GEDAECHTNIS`) – eigens dafür,
## dass `move_and_slide` beim Aufsetzen die Fallgeschwindigkeit sofort auf
## null zieht. Hier bleibt damit nur noch zu prüfen, dass der Spieler
## nicht von unten kommt.
##
## Preis dieser Regel: Wer im Fallen seitlich gegen einen Gegner stößt,
## besiegt ihn. Das ist in Plattformern das übliche Verhalten und allemal
## besser als ein Sprung, der in einem Viertel der Fälle Leben kostet.
func _spieler_ist_oben(spieler: Node3D) -> bool:
	return spieler.global_position.y > global_position.y - UNTERKANTE_TOLERANZ


## Der Gegner geht kaputt: Kollision aus, Früchte streuen, Todesanimation.
func besiegen(art: int = 0) -> void:
	if besiegt:
		return
	besiegt = true
	_tot_zeit = TODES_DAUER

	if trefferzone != null:
		trefferzone.set_deferred("monitoring", false)
		for kind in trefferzone.get_children():
			if kind is CollisionShape3D:
				kind.set_deferred("disabled", true)

	_wegflug = _weg_richtung() * 5.0 + Vector3.UP * 6.0
	_todesstart(art)
	Frucht.streuen(get_parent(), global_position + Vector3.UP * 0.5, fruechte)


# ---------------------------------------------------------- Hilfen

## Normierte Patrouillenachse (mit Notnagel, falls jemand Null einträgt).
func achse() -> Vector3:
	if patrouille_achse.length() < 0.01:
		return Vector3.RIGHT
	return patrouille_achse.normalized()


## Richtung vom Spieler weg – für das Wegschleudern beim Besiegen.
func _weg_richtung() -> Vector3:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler != null:
		var d := global_position - spieler.global_position
		d.y = 0.0
		if d.length() > 0.05:
			return d.normalized()
	return achse() * richtung


## Ein Patrouillenschritt entlang der Achse. Gibt true zurück, wenn der
## Gegner an einem Endpunkt umgedreht hat.
func _patrouille_schritt(strecke: float) -> bool:
	var a := achse()
	global_position += a * richtung * strecke
	var abstand := (global_position - _start_position).dot(a)
	var grenze := patrouille_weite * 0.5
	if abstand > grenze and richtung > 0.0:
		richtung = -1.0
		return true
	if abstand < -grenze and richtung < 0.0:
		richtung = 1.0
		return true
	return false


## Dreht das Modell weich in die Laufrichtung (alle Modelle schauen nach -Z).
func _blick_ausrichten(delta: float, geschwindigkeit := 8.0) -> void:
	if not is_instance_valid(modell):
		return
	var d := achse() * richtung
	var ziel := atan2(-d.x, -d.z)
	modell.rotation.y = lerp_angle(modell.rotation.y, ziel, minf(delta * geschwindigkeit, 1.0))


## Setzt die Höhe über der Startebene (für hüpfende Gegner).
func _setze_hoehe(hoehe: float) -> void:
	var p := global_position
	p.y = _start_position.y + hoehe
	global_position = p


## Hängt ein Mesh mit Material unter `elternteil` und gibt es zurück.
func _teil(elternteil: Node3D, gitter: Mesh, material: Material, pos: Vector3,
		drehung := Vector3.ZERO, skalierung := Vector3.ONE,
		benennung := "Teil") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = benennung
	mi.mesh = gitter
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = drehung
	mi.scale = skalierung
	elternteil.add_child(mi)
	return mi


## Erzeugt eine Kugel (Standardform für Körper, Köpfe und Augen).
func _kugel(radius: float, segmente := 12, ringe := 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = segmente
	m.rings = ringe
	return m


## Erzeugt einen Zylinder bzw. Kegel (oben_radius = 0 ergibt eine Spitze).
func _zylinder(unten_radius: float, oben_radius: float, hoehe: float,
		segmente := 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = unten_radius
	m.top_radius = oben_radius
	m.height = hoehe
	m.radial_segments = segmente
	m.rings = 1
	return m


## Erzeugt einen Quader.
func _quader(groesse: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = groesse
	return m
