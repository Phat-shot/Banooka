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
## Das gilt auch für die mitgelieferten Modelle: Deren Zeichnung malt
## `_zeichen_am_fremdmodell()` nach (`_bemalung()`, `_an_knochen()`).
##
## MITGELIEFERTE MODELLE: Das Modell hängt unter `fremdhalter`; Stauchen
## und Wippen gehen auf den Halter, die Einpassung bleibt am Modell. Bringt
## es Clips mit, spielt `_clip()` sie ab. Über jedes Netz des Modells legt
## sich ein eigenes Overlay (`shaders/gegner_glanz.gdshader`): ein warmer
## Saum an der Silhouette und der weiße Trefferblitz.
##
## BESIEGT: Blitz, kurzes Erstarren, Funken und Kameraruck, dann die
## Todesanimation des Gegners, am Ende ein Rauchwölkchen, in dem er
## verschwindet (`_treffer_zeigen()`, `_verpuffen()`).

## Gravitation der Todesanimation.
const TODES_G := -32.0
## Nach dieser Zeit verschwindet ein besiegter Gegner.
const TODES_DAUER := 1.0
## Wie weit unter dem Gegnerursprung der Spieler höchstens stehen darf,
## damit ein Treffer noch als "von oben" zählt. Verhindert, dass jemand
## von einem tieferen Sims aus mit dem Kopf in die Trefferzone ragt und
## den Gegner damit besiegt.
const UNTERKANTE_TOLERANZ := 0.2

## Randlicht und Trefferblitz, je Gegner ein eigenes Material.
const GLANZ_SHADER: Shader = preload("res://shaders/gegner_glanz.gdshader")
## Stärke des Randlichts auf mitgelieferten Modellen. Der Saum soll die
## Silhouette vom Boden lösen, nicht den Gegner leuchten lassen – leuchten
## dürfen nur Früchte, Kisten und Wirkstellen. Der Wert wirkt größer, als
## er ist: Der Saum ist Licht (siehe Shader) und entsteht nur an Kanten,
## die ein Licht streift; bei 0,6 war er im Spielbild nicht zu finden.
const RAND_STAERKE := 1.4
## Ab dieser Entfernung zur Kamera stehen die Clips still. Jeder Knochen
## kostet je Bild Rechenzeit, und auf 40 m sieht niemand ein Bein zucken.
const ANIM_WEITE := 40.0
## Bis hierher (Meter zur Kamera) trägt ein mitgeliefertes Modell sein
## Overlay; der Shader blendet den Saum bis dahin aus. Dahinter kostete
## es nur noch einen Draw-Call je Fläche, für nichts.
const GLANZ_WEITE := 34.0
## Bis hierher werfen mitgelieferte Modelle einen Sonnenschatten. Jede
## Fläche kostet in jeder der vier Schattenstufen einen Draw-Call (der
## Frosch hat vier Flächen); der Schatten eines Käfers in 30 m Entfernung
## ist ein paar Pixel groß und liegt im Nebel. Das bezahlt Overlay und
## Zeichnung der nahen Gegner.
const SCHATTEN_WEITE := 28.0
## So lange steht ein getroffener Gegner starr und aufgebläht da, bevor
## er kippt oder fliegt – das Einzelbild, in dem der Treffer "sitzt".
const STARRE := 0.07
## Dauer des weißen Trefferblitzes.
const BLITZ_DAUER := 0.16
## So lange vor dem Verschwinden schrumpft er in ein Rauchwölkchen.
const PUFF_VORLAUF := 0.15
## Farbe dieses Wölkchens: hell und warm, wie aufgewirbelter Staub im
## Sonnenlicht. Nicht grau – Grau liest sich als Brand.
const PUFF_FARBE := Color(1.0, 0.95, 0.86, 0.9)

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
## Halter des mitgelieferten Modells (null ohne Modell). Seine Skalierung
## und Lage gehören der Animation des Gegners; `_neu_faerben()` baut ihn neu.
var fremdhalter: Node3D

var _start_position := Vector3.ZERO
var _zeit := 0.0
var _phase := 0.0
var _tot_zeit := 0.0
var _wegflug := Vector3.ZERO

## Clips des mitgelieferten Modells (null ohne Modell oder ohne Skelett).
var _fremd_anim: AnimationPlayer
## Wunschname des laufenden Clips ("idle", "jump" ...), leer = keiner.
var _clip_jetzt := ""
## Das Overlay dieses Gegners (Randlicht, Trefferblitz), null = keins.
var _glanz: ShaderMaterial
## Zähler für die Abstandsprüfung (nicht jedes Bild nötig).
var _anim_takt := 0.0
## Zuletzt gesetzte Abstandsstufe (Bits: Clips, Schatten, Overlay);
## -1 = noch nie gesetzt.
var _stufe := -1
## Die Netze des Modells, die Overlay und Schatten nach Abstand schalten.
var _fremdnetze: Array[MeshInstance3D] = []
## Eigenes Tempo der Dauerclips (±8 %), damit gleiche Gegner nie im
## Gleichschritt atmen oder staksen.
var _eigentempo := 1.0
## Restzeit des Erstarrens nach dem Treffer.
var _starre := 0.0
var _verpufft := false

## Körperknochen ("Body") des Modells, für `_koerper_halten()`.
var _skelett: Skeleton3D
var _koerper_knochen := -1
## Höhe des Körpers beim Start des Clips, der gerade gehalten wird.
var _koerper_null := 0.0
## Vom Skelett in den Halter (ohne den Halter selbst).
var _skelett_im_halter := Transform3D.IDENTITY

## Geteiltes Material aller Bemalungen (siehe `_stoff_der_bemalung()`).
static var _bemalungsstoff: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("gegner")
	_start_position = global_position
	_phase = randf() * TAU
	# Gestaffelt, damit nicht alle Gegner eines Levels im selben Bild messen.
	_anim_takt = randf() * 0.25
	_eigentempo = randf_range(0.92, 1.08)

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
		# Die Starre zählt in die Todesdauer hinein: Ein Gegner lebt nach
		# dem Treffer nicht länger als vorher.
		if _starre > 0.0:
			_starre -= delta
		else:
			_todesanimation(delta)
		if _tot_zeit <= PUFF_VORLAUF and not _verpufft:
			_verpuffen()
		if _tot_zeit <= 0.0:
			queue_free()
		return

	_bewegung(delta)
	_pruefe_ueberlappung()
	_anim_takt -= delta
	if _anim_takt <= 0.0:
		_anim_takt = 0.25
		_nach_abstand()


# ---------------------------------------------------------- Haken für Gegner

## Baut die Optik unter `modell` auf. Wird von jedem Gegner überschrieben.
func _baue() -> void:
	pass


## Datei und Zielgröße eines mitgelieferten Modells für diesen Gegner,
## z. B. {"datei": "kroete", "groesse": 1.1}. Leer = nur die eigene Optik.
## Mit {"nach_hoehe": true} zählt die Höhe statt der größten Achse,
## {"drehung": PI} dreht das Modell, {"farben": {...}} färbt Materialien um,
## {"stoff": {...}} stellt Glanz, Rauheit und Leuchten einzelner
## Materialien ein (siehe `Fremdmodelle.gegner`).
func fremdmodell() -> Dictionary:
	return {}


## Setzt Zeichnung und Zubehör auf das mitgelieferte Modell, nachdem es
## eingehängt ist (siehe ZEICHENSPRACHE). `figur` ist das eingepasste
## Modell unter `fremdhalter`. Die prozedurale Optik bringt ihre Zeichnung
## selbst mit; dieser Haken läuft nur mit Modell.
func _zeichen_am_fremdmodell(_figur: Node3D) -> void:
	pass


## Farbe der Funken beim Besiegen – die Wirkstelle des Gegners.
func _trefferfarbe() -> Color:
	return Farben.SPIN_RING


## Tonhöhe des Treffergeräuschs: große Gegner tiefer, kleine höher.
func _klanghoehe() -> float:
	return 1.0


## Hängt das mitgelieferte Modell ein und legt das Overlay an.
##
## Läuft beim Aufbau und bei jedem Umfärben (`_neu_faerben()` der Gegner
## ruft es nach `_baue()` auf). Alles, was am Modell hängt, entsteht
## deshalb hier neu – Clips, Zeichnung, Overlay.
func _fremdmodell_setzen() -> void:
	fremdhalter = null
	_fremd_anim = null
	_clip_jetzt = ""
	_glanz = null
	_stufe = -1
	_fremdnetze.clear()
	_skelett = null
	_koerper_knochen = -1
	_fremdmodell_einhaengen()
	if fremdhalter != null:
		_glanz_anlegen(fremdhalter, RAND_STAERKE)
		for knoten in fremdhalter.find_children("*", "MeshInstance3D", true, false):
			var netz := knoten as MeshInstance3D
			if netz != null and netz.material_overlay != null and netz.material_overlay == _glanz:
				_fremdnetze.append(netz)


## Die gebauten Teile bleiben absichtlich im Baum: Die Bewegungslogik jedes
## Gegners greift auf sie zu (Hüpf-Stauchung, Beintakt, Pickbewegung). Sie
## zu entfernen hieße, jede dieser Stellen abzusichern. Unsichtbar
## geschaltet kostet das nichts und kann nichts kaputtmachen.
func _fremdmodell_einhaengen() -> void:
	var angabe := fremdmodell()
	if angabe.is_empty() or not is_instance_valid(modell):
		return
	var figur := Fremdmodelle.gegner(String(angabe.get("datei", "")),
			float(angabe.get("groesse", 1.0)),
			bool(angabe.get("nach_hoehe", false)),
			float(angabe.get("drehung", 0.0)),
			angabe.get("farben", {}) as Dictionary,
			angabe.get("stoff", {}) as Dictionary)
	if figur == null:
		return
	for kind in modell.get_children():
		var sichtbar := kind as Node3D
		if sichtbar != null:
			sichtbar.visible = false
	figur.name = "Fremdmodell"
	# Eigener Halter wie "EigeneFigur" beim Beuteldachs: Die Einpassung
	# (Maßstab, halbe Drehung, Fußhöhe) bleibt am Modell, Stauchen und
	# Wippen gehen auf den Halter. Sein Ursprung liegt an den Füßen – eine
	# Stauchung drückt das Tier in den Boden, statt es um die Mitte zu
	# quetschen.
	fremdhalter = Node3D.new()
	fremdhalter.name = "Fremdhalter"
	modell.add_child(fremdhalter)
	fremdhalter.add_child(figur)
	_fremd_anim = ModellLader.spieler_von(figur)
	_koerper_messen(figur)
	_zeichen_am_fremdmodell(figur)


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
	Klang.spiele("gegner", _klanghoehe())

	if trefferzone != null:
		trefferzone.set_deferred("monitoring", false)
		for kind in trefferzone.get_children():
			if kind is CollisionShape3D:
				kind.set_deferred("disabled", true)

	_wegflug = _weg_richtung() * 5.0 + Vector3.UP * 6.0
	_todesstart(art)
	Frucht.streuen(get_parent(), global_position + Vector3.UP * 0.5, fruechte)
	_treffer_zeigen()


## Das Treffergefühl, für jeden Gegner gleich: weißer Blitz, ein Bild
## aufgebläht und starr, Funken in der Farbe der Wirkstelle, ein kurzer
## Ruck der Kamera und die Trefferpause. Rein optisch – `besiegt` ist
## schon gesetzt, die Trefferzone schon aus.
func _treffer_zeigen() -> void:
	_starre = STARRE
	if is_instance_valid(modell):
		modell.scale *= 1.18
	# Auch aus der Ferne getroffen (Bauchplatscher-Welle) soll der Tod zu
	# sehen sein – also die Clips wieder laufen lassen.
	if _fremd_anim != null:
		_fremd_anim.active = true
	# Die eigene Optik hat kein Overlay (es kostete je Teil einen Draw-Call);
	# für den Blitz bekommt sie jetzt eins, nur für die letzte Sekunde.
	if is_instance_valid(modell):
		_glanz_anlegen(modell, 0.0, true)
	if _glanz != null:
		var stoff := _glanz
		stoff.set_shader_parameter("blitz", 1.0)
		var setzen := func(w: float) -> void: stoff.set_shader_parameter("blitz", w)
		create_tween().tween_method(setzen, 1.0, 0.0, BLITZ_DAUER)

	# Zwischen Figur und Gegner, etwas über dem Boden: Dort "trifft" es.
	var ort := global_position + Vector3.UP * 0.6
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler != null and spieler.global_position.distance_to(ort) < 4.0:
		ort = ort.lerp(spieler.global_position + Vector3.UP * 0.6, 0.35)
	Effekte.aufblitzen(self, ort, Color(1.0, 0.96, 0.84), 1.9, 0.14)
	Effekte.funken(self, ort, _trefferfarbe(), 12, 6.0, 0.2)
	Effekte.erschuettern(self, 0.2, global_position)
	Effekte.trefferpause(self, 0.05)


## Kurz vor dem Ende: Der Gegner schrumpft in ein helles Wölkchen, statt
## einfach zu verschwinden.
##
## Geschrumpft wird der Gegner selbst, nicht `modell`: Dessen Skalierung
## gehört der Todesanimation, die sie jedes Bild nachführt – ein Tween
## darauf flackerte gegen sie an. Nicht ganz auf null: Eine Nullskala
## macht die Basis singulär, und Godot meldet das bei jeder Abfrage.
func _verpuffen() -> void:
	_verpufft = true
	var mitte := global_position + Vector3.UP * 0.4
	if is_instance_valid(modell):
		mitte = modell.global_position + Vector3.UP * 0.4
	Effekte.rauch(self, mitte, PUFF_FARBE, 1.0, 9)
	create_tween().tween_property(self, "scale", Vector3.ONE * 0.02, PUFF_VORLAUF) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


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


## Gierwinkel für `modell`, damit es in die WELTrichtung `d` blickt.
##
## `d` ist eine Weltrichtung (Patrouillenachse, Weg zum Spieler), `modell`
## hängt aber unter dem Gegner – und den drehen die Level auf den
## Korridor (`g.rotation.y = LevelWerkzeuge.drehung(...)`). Wer den
## Weltwinkel direkt ins Modell schrieb, drehte ihn ein zweites Mal um
## diese Korridordrehung: In den Kurven von Level 01 lief so jeder zweite
## Gegner 30 bis 70 Grad schräg, wie ein Krebs. Die eigene Drehung wird
## deshalb abgezogen.
func _blickwinkel(d: Vector3) -> float:
	return atan2(-d.x, -d.z) - global_rotation.y


## Dreht das Modell weich in die Laufrichtung (alle Modelle schauen nach -Z).
func _blick_ausrichten(delta: float, geschwindigkeit := 8.0) -> void:
	if not is_instance_valid(modell):
		return
	var ziel := _blickwinkel(achse() * richtung)
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


# ---------------------------------------------------------- Clips

## Spielt einen Clip des mitgelieferten Modells, gesucht nach Wortstamm
## ("idle", "jump", "walk" ...; siehe `ModellLader.clip_fuer`). Läuft er
## schon, ändert sich nur das Tempo. Gibt false zurück, wenn es kein
## Modell, keinen AnimationPlayer oder keinen passenden Clip gibt – die Aufrufer
## brauchen dann nichts weiter zu tun, die eigene Optik animiert sich selbst.
##
## `schleife` stellt den Clip auf Dauerschleife. Das gilt für die
## importierte Animation, also für jeden Gegner mit diesem Modell; die
## Einstellung ist dieselbe für alle und ändert sich nie zurück. Der
## Beuteldachs macht es genauso (`_schleife_setzen`). Eine Schleife beginnt
## an zufälliger Stelle und läuft im Eigentempo des Gegners – fünf Kröten
## atmen sonst im Gleichtakt.
func _clip(wunsch: String, blende: float = 0.12, tempo_faktor: float = 1.0,
		schleife: bool = false) -> bool:
	if _fremd_anim == null:
		return false
	_fremd_anim.speed_scale = tempo_faktor * (_eigentempo if schleife else 1.0)
	if _clip_jetzt == wunsch:
		return true
	var clip := ModellLader.clip_fuer(_fremd_anim, wunsch)
	if clip.is_empty():
		return false
	var anim := _fremd_anim.get_animation(clip)
	if anim == null:
		return false
	if schleife:
		anim.loop_mode = Animation.LOOP_LINEAR
	_fremd_anim.play(clip, blende)
	if schleife:
		_fremd_anim.seek(randf() * anim.length)
	_clip_jetzt = wunsch
	return true


## Merkt sich den Körperknochen des Modells für `_koerper_halten()`.
func _koerper_messen(figur: Node3D) -> void:
	var netz := _hauptnetz(figur)
	if netz == null or netz.skin == null:
		return
	_skelett = netz.get_node_or_null(netz.skeleton) as Skeleton3D
	_koerper_knochen = _skelett.find_bone("Body") if _skelett != null else -1
	if _koerper_knochen < 0:
		_skelett = null
		return
	# Vom Skelett bis in den Halter, OHNE den Halter selbst: Dessen Lage
	# setzt `_koerper_halten()`, sie darf nicht in die Messung zurückwirken.
	var kette := Transform3D.IDENTITY
	var knoten: Node = _skelett
	while knoten != null and knoten != fremdhalter:
		var raum := knoten as Node3D
		if raum != null:
			kette = raum.transform * kette
		knoten = knoten.get_parent()
	_skelett_im_halter = kette


## Höhe des Körperknochens im Halter, in Metern.
func _koerperhoehe() -> float:
	if _skelett == null:
		return 0.0
	return (_skelett_im_halter * _skelett.get_bone_global_pose(_koerper_knochen).origin).y


## Nimmt den Anstieg des Körpers aus einem Clip wieder heraus.
##
## Manche Clips (Hüpfen, Sterben) heben den Körper selbst an, als wäre das
## Tier allein auf der Welt. Wo das Skript die Höhe schon führt – und die
## Trefferzone mit ihr –, stünde das Modell dann über seiner Trefferzone.
## Solange `clip` läuft, drückt der Halter jeden Anstieg über
## `_koerper_null` (Höhe beim Clipstart) zurück; Absenken bleibt, so
## bleiben Hocke und Zusammensacken erhalten. Die Knochenlage stammt aus
## dem letzten gezeichneten Bild – ein Bild Verzug sieht niemand.
func _koerper_halten(clip: String) -> void:
	if _skelett == null or fremdhalter == null:
		return
	if _clip_jetzt != clip:
		fremdhalter.position.y = 0.0
		return
	fremdhalter.position.y = -maxf(_koerperhoehe() - _koerper_null, 0.0) \
			* fremdhalter.scale.y


## Schaltet ab, was aus der Ferne niemand sieht: Clips (`ANIM_WEITE`),
## Sonnenschatten (`SCHATTEN_WEITE`) und Overlay (`GLANZ_WEITE`). Nur bei
## einem Wechsel wird etwas gesetzt.
func _nach_abstand() -> void:
	if fremdhalter == null:
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var abstand := kamera.global_position.distance_to(global_position)
	var stufe := (1 if abstand < ANIM_WEITE else 0) \
			| (2 if abstand < SCHATTEN_WEITE else 0) \
			| (4 if abstand < GLANZ_WEITE else 0)
	if stufe == _stufe:
		return
	_stufe = stufe
	if _fremd_anim != null:
		_fremd_anim.active = (stufe & 1) != 0
	for netz in _fremdnetze:
		if not is_instance_valid(netz):
			continue
		netz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (stufe & 2) != 0 \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		netz.material_overlay = _glanz if (stufe & 4) != 0 else null


# ---------------------------------------------------------- Overlay

## Legt das Overlay über jedes sichtbare Netz unter `wurzel`.
##
## Ein Material je Gegner, weil jeder seinen eigenen Blitz hat. Der Shader
## darunter ist für alle derselbe und wird nur einmal übersetzt.
## `material_overlay` ist eine Eigenschaft der Instanz – die (geteilten)
## Materialien darunter bleiben unberührt. Netze mit der Markierung
## "ohne_glanz" (Bemalung, Stachelkamm, Glanzpunkte) bleiben im Leben
## aus: Sie liegen auf dem Körper, dessen Saum reicht, und jedes Overlay
## kostet einen Draw-Call. Beim Treffer (`alle`) bekommen auch sie es –
## sonst stünde die Zeichnung farbig im weißen Blitz. "kein_blitz" trägt,
## was zwar im Modell hängt, aber nicht zum Gegner gehört (das Podest des
## Werfers bleibt als Teil des Levels stehen).
## Gibt es schon ein Overlay, wird es weiterverwendet.
func _glanz_anlegen(wurzel: Node, rand: float, alle: bool = false) -> void:
	var stoff := _glanz
	if stoff == null:
		stoff = ShaderMaterial.new()
		stoff.shader = GLANZ_SHADER
		stoff.set_shader_parameter("rand_staerke", rand)
		stoff.set_shader_parameter("fern", GLANZ_WEITE)
	var belegt := 0
	for knoten in wurzel.find_children("*", "MeshInstance3D", true, false):
		var netz := knoten as MeshInstance3D
		if netz == null or not _sichtbar_im_gegner(netz) or netz.has_meta("kein_blitz"):
			continue
		if netz.material_overlay == stoff:
			belegt += 1
			continue
		if netz.material_overlay != null or (netz.has_meta("ohne_glanz") and not alle):
			continue
		netz.material_overlay = stoff
		belegt += 1
	_glanz = stoff if belegt > 0 else null


## Sichtbar innerhalb des Gegners? Gefragt wird nur bis zum Gegner selbst:
## `is_visible_in_tree()` fragte auch dessen Eltern, und ein Gegner, der in
## einem (noch) verborgenen Knoten entsteht, bekäme so nie ein Overlay.
## Die ausgeblendete eigene Optik unter einem Modell bleibt dagegen außen vor.
func _sichtbar_im_gegner(knoten: Node) -> bool:
	var n := knoten
	while n != null and n != self:
		var raum := n as Node3D
		if raum != null and not raum.visible:
			return false
		n = n.get_parent()
	return true


# ---------------------------------------------------------- Zeichnung

## Hauptnetz eines mitgelieferten Modells: das mit den meisten Ecken.
static func _hauptnetz(figur: Node) -> MeshInstance3D:
	var bestes: MeshInstance3D = null
	var ecken := -1
	for knoten in figur.find_children("*", "MeshInstance3D", true, false):
		var netz := knoten as MeshInstance3D
		if netz == null or netz.mesh == null:
			continue
		var n := 0
		for i in netz.mesh.get_surface_count():
			n += netz.mesh.surface_get_array_len(i)
		if n > ecken:
			ecken = n
			bestes = netz
	return bestes


## Nummer der Fläche, deren Ausgangsmaterial so heißt (-1 = keine).
static func _flaeche_nach_name(netz: Mesh, name: String) -> int:
	for i in netz.get_surface_count():
		var stoff := netz.surface_get_material(i)
		if stoff != null and stoff.resource_name == name:
			return i
	return -1


## Malt eine Zeichnung auf ein mitgeliefertes Modell.
##
## Aus einer Fläche des Netzes werden die Dreiecke herausgelöst, denen
## `auswahl.call(mitte, normale) -> Color` eine Farbe gibt (Alpha 0 = nicht
## dabei; beide Werte im Netzraum). Sie rücken `abstand` Netzeinheiten
## entlang ihrer Normalen nach außen und tragen die Farbe als
## Scheitelfarbe. Das Ergebnis liegt passgenau auf der gewölbten
## Oberfläche – ein aufgesetzter Kasten stünde an den Rändern ab oder
## tauchte in die Wölbung ein. Knochen und Gewichte bleiben erhalten:
## Auf einem gehäuteten Modell geht die Zeichnung in jeden Clip mit.
##
## Teuer (einmal über alle Dreiecke); die Gegner halten das Ergebnis
## deshalb je Farbsatz in einem statischen Zwischenspeicher.
## Gibt null zurück, wenn nichts ausgewählt wurde.
static func _bemalung(netz: Mesh, flaeche: int, auswahl: Callable,
		abstand: float) -> ArrayMesh:
	if netz == null or flaeche < 0 or flaeche >= netz.get_surface_count():
		return null
	var roh := netz.surface_get_arrays(flaeche)
	var ecken: PackedVector3Array = roh[Mesh.ARRAY_VERTEX]
	var normalen: PackedVector3Array = roh[Mesh.ARRAY_NORMAL]
	if ecken.is_empty() or normalen.size() != ecken.size():
		return null
	var folge := PackedInt32Array()
	if roh[Mesh.ARRAY_INDEX] != null:
		folge = roh[Mesh.ARRAY_INDEX]
	if folge.is_empty():
		folge.resize(ecken.size())
		for i in ecken.size():
			folge[i] = i
	var knochen := PackedInt32Array()
	var gewichte := PackedFloat32Array()
	if roh[Mesh.ARRAY_BONES] != null and roh[Mesh.ARRAY_WEIGHTS] != null:
		knochen = roh[Mesh.ARRAY_BONES]
		gewichte = roh[Mesh.ARRAY_WEIGHTS]
	var je := 8 if (netz.surface_get_format(flaeche) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) != 0 else 4
	var gehaeutet := not knochen.is_empty() and knochen.size() >= ecken.size() * je

	var neu_ecken := PackedVector3Array()
	var neu_normalen := PackedVector3Array()
	var neu_farben := PackedColorArray()
	var neu_knochen := PackedInt32Array()
	var neu_gewichte := PackedFloat32Array()
	for d in range(0, folge.size() - 2, 3):
		var a := folge[d]
		var b := folge[d + 1]
		var c := folge[d + 2]
		var mitte := (ecken[a] + ecken[b] + ecken[c]) / 3.0
		var normale := (normalen[a] + normalen[b] + normalen[c]).normalized()
		var farbe: Color = auswahl.call(mitte, normale)
		if farbe.a <= 0.0:
			continue
		for i: int in [a, b, c]:
			neu_ecken.append(ecken[i] + normalen[i] * abstand)
			neu_normalen.append(normalen[i])
			neu_farben.append(Color(farbe.r, farbe.g, farbe.b, 1.0))
			if gehaeutet:
				for j in je:
					neu_knochen.append(knochen[i * je + j])
					neu_gewichte.append(gewichte[i * je + j])
	if neu_ecken.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = neu_ecken
	arrays[Mesh.ARRAY_NORMAL] = neu_normalen
	arrays[Mesh.ARRAY_COLOR] = neu_farben
	var format := 0
	if gehaeutet:
		arrays[Mesh.ARRAY_BONES] = neu_knochen
		arrays[Mesh.ARRAY_WEIGHTS] = neu_gewichte
		if je == 8:
			format = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	var ergebnis := ArrayMesh.new()
	ergebnis.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, format)
	return ergebnis


## Stoff für jede Bemalung: Die Farbe steckt in den Scheitelfarben, also
## genügt ein einziges Material für alle Gegner und alle Farbsätze.
static func _stoff_der_bemalung() -> StandardMaterial3D:
	if _bemalungsstoff == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		# Scheitelfarben als sRGB: Sie werden so umgerechnet wie
		# `albedo_color`, ein Fleck in `farbe_flecken` hat dann denselben
		# Ton wie auf der eigenen Optik.
		m.vertex_color_is_srgb = true
		m.roughness = 0.55
		m.metallic_specular = 0.35
		_bemalungsstoff = m
	return _bemalungsstoff


## Zeigt eine Bemalung auf dem Modell: als Geschwister des Hauptnetzes,
## mit dessen Lage, Haut und Skelett.
func _bemalung_zeigen(figur: Node3D, zeichnung: ArrayMesh) -> MeshInstance3D:
	var netz := _hauptnetz(figur)
	if netz == null or zeichnung == null or netz.get_parent() == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "Zeichnung"
	mi.mesh = zeichnung
	mi.material_override = _stoff_der_bemalung()
	# Liegt flach auf dem Körper – dessen Schatten reicht.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = netz.transform
	if netz.skin != null:
		mi.skin = netz.skin
		mi.skeleton = netz.skeleton
	netz.get_parent().add_child(mi)
	return mi


## Hängt `teil` an einen Knochen des mitgelieferten Modells, sodass es
## jedem Clip folgt. `lage` ist die Lage im NETZRAUM (wie `Mesh.get_aabb()`)
## in der Bindepose – dort, wo die Oberfläche beim Modellieren lag.
##
## Über die Bindematrix der Haut und nicht über die Ruhelage des Skeletts:
## Bei der Spinne weichen beide voneinander ab (der Hinterleib ist in der
## Ruhelage auf 0,88 geschrumpft), und nur die Bindematrix sagt, wo die
## Oberfläche zu einem Knochen liegt. Gibt false zurück (und `teil` wird
## freigegeben), wenn Skelett oder Knochen fehlen.
func _an_knochen(figur: Node3D, knochen: String, teil: Node3D,
		lage: Transform3D) -> bool:
	var netz := _hauptnetz(figur)
	var skelett: Skeleton3D = null
	if netz != null and netz.skin != null:
		skelett = netz.get_node_or_null(netz.skeleton) as Skeleton3D
	var bindung := -1
	if skelett != null and skelett.find_bone(knochen) >= 0:
		for i in netz.skin.get_bind_count():
			if String(netz.skin.get_bind_name(i)) == knochen:
				bindung = i
				break
	if bindung < 0:
		teil.queue_free()
		return false
	var halter := BoneAttachment3D.new()
	halter.name = "Halter_" + knochen
	halter.bone_name = knochen
	skelett.add_child(halter)
	halter.add_child(teil)
	teil.transform = netz.skin.get_bind_pose(bindung) * lage
	return true
