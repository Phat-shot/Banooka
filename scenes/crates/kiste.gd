extends StaticBody3D
class_name Kiste
## Kiste in neun Ausführungen – ein Skript für alle Arten.
##
## Die Art wird im Inspektor über `art` eingestellt, die Optik baut das
## Skript in `_ready()` prozedural auf (Holzkorpus, Kantenstreben, Symbol).
##
## Treffer werden über die Area3D "Trefferzone" erkannt: Sie fragt jeden
## Physikschritt `spieler.angriffe()` ab (siehe scripts/angriff.gd).
## Zusätzlich ruft die Schockwelle des Bauchplatschers bei allen Kisten
## im Umkreis `zerbrechen(Angriff.SLAM)` auf.

## Die neun Kistenarten.
enum Art {
	NORMAL,           ## Holzkiste, gibt 1 Frucht
	FRUCHT_MEHRFACH,  ## Holzkiste, gibt 5 Früchte
	LEBEN,            ## gibt ein Extraleben
	FEDER,            ## Sprungkiste: 10 Absprünge, je 1 Frucht
	SPRUNG,           ## reine Sprungfeder, unzerstörbar
	TNT,              ## Countdown 3 s, dann Explosion
	NITRO,            ## explodiert bei jeder Berührung
	EISEN,            ## unzerbrechlich, reine Plattform
	CHECKPOINT,       ## setzt den Respawn-Punkt
}

# --- Kennwerte ---
const FEDER_SPRUENGE := 10        ## Absprünge der Federkiste
const FEDER_ABPRALL := 15.0       ## Absprunghöhe der Federkiste
const SPRUNG_ABPRALL := 20.0      ## Absprunghöhe der Sprungfeder
const ABPRALL_SPERRE := 0.25      ## Pause zwischen zwei Absprüngen (s)
const TNT_ZEIT := 3.0             ## Countdown der TNT-Kiste
const TNT_RADIUS := 3.0           ## Wirkradius der TNT-Explosion
const NITRO_RADIUS := 2.5         ## Wirkradius der Nitro-Explosion
const FRUECHTE_MEHRFACH := 5      ## Früchte der Mehrfachkiste

## Angriffsarten, die eine Holzkiste direkt zerbrechen.
const ZERBRECHENDE_ANGRIFFE := Angriff.SPIN | Angriff.SLIDE | Angriff.SLAM

@export var art: Art = Art.NORMAL

@onready var _modell: Node3D = $Modell
@onready var _trefferzone: Area3D = $Trefferzone

## Restliche Absprünge der Federkiste.
var _spruenge_uebrig := FEDER_SPRUENGE
## Restzeit des TNT-Countdowns (< 0 = nicht gestartet).
var _countdown := -1.0
## Sperre gegen doppelte Absprünge im selben Moment.
var _abprall_sperre := 0.0
## Verhindert doppeltes Zerbrechen/Explodieren.
var _zerstoert := false
## Beschriftungen auf den vier Seiten (für Zahlen, die sich ändern).
var _beschriftungen: Array[Label3D] = []
## Material des Korpus (bei Nitro eine eigene Kopie zum Pulsieren).
var _korpus_material: StandardMaterial3D = null
var _zeit := 0.0


func _ready() -> void:
	add_to_group("kisten")
	collision_layer = 1
	collision_mask = 0
	_trefferzone.collision_layer = 0
	_trefferzone.collision_mask = 2      # nur den Spieler beachten
	_trefferzone.monitoring = true
	_baue_optik()
	# Eisenkisten reagieren auf gar nichts – Abfrage kann entfallen.
	if art == Art.EISEN:
		set_physics_process(false)
	# Nur diese drei Arten bewegen sich pro Bild.
	set_process(art == Art.NITRO or art == Art.TNT or art == Art.FEDER)


# ---------------------------------------------------------------- Optik

## Baut Korpus, Kantenstreben und Symbole auf.
func _baue_optik() -> void:
	_korpus_material = _material_fuer_art()

	var korpus := MeshInstance3D.new()
	korpus.name = "Korpus"
	var wuerfel := BoxMesh.new()
	wuerfel.size = Vector3(0.96, 0.96, 0.96)
	korpus.mesh = wuerfel
	korpus.material_override = _korpus_material
	_modell.add_child(korpus)

	_baue_streben()
	_baue_symbole()


## Farbe und Material je nach Art.
func _material_fuer_art() -> StandardMaterial3D:
	match art:
		Art.LEBEN:
			return Materialbibliothek.kistenholz(Farben.KISTE_LEBEN)
		Art.FEDER:
			return Materialbibliothek.kistenholz(Farben.KISTE_FEDER)
		Art.CHECKPOINT:
			return Materialbibliothek.kistenholz(Farben.KISTE_CHECKPOINT)
		Art.TNT:
			return Materialbibliothek.kistenholz(Farben.KISTE_TNT)
		Art.NITRO:
			# eigene Kopie, damit das Pulsieren keine anderen Kisten stört
			return Materialbibliothek.leuchtend(Farben.KISTE_NITRO, 0.6).duplicate() as StandardMaterial3D
		Art.SPRUNG:
			return Materialbibliothek.metall(Farben.KISTE_SPRUNG)
		Art.EISEN:
			return Materialbibliothek.metall(Farben.KISTE_EISEN)
		_:
			return Materialbibliothek.kistenholz(Farben.HOLZ)


## Farbe der Kantenstreben und Beschläge.
func _strebenfarbe() -> Color:
	match art:
		Art.EISEN, Art.SPRUNG:
			return Farben.FELS_HELL
		Art.NITRO:
			return Farben.KISTE_NITRO.darkened(0.5)
		_:
			return Farben.HOLZ_DUNKEL


## Zwölf dünne Boxen entlang der Würfelkanten.
func _baue_streben() -> void:
	var mat: StandardMaterial3D
	if art == Art.EISEN or art == Art.SPRUNG:
		mat = Materialbibliothek.metall(_strebenfarbe())
	else:
		mat = Materialbibliothek.einfarbig(_strebenfarbe(), 0.9)

	var dicke := 0.12
	var laenge := 1.0
	# Für jede Achse vier Kanten: Achse = Richtung der Strebe.
	var achsen: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]
	for achse in achsen:
		var groesse := Vector3(dicke, dicke, dicke)
		groesse += achse.abs() * (laenge - dicke)
		var quer_a := Vector3.UP if achse == Vector3.RIGHT else Vector3.RIGHT
		var quer_b := achse.cross(quer_a).normalized()
		for i in 4:
			var vz_a := 1.0 if i < 2 else -1.0
			var vz_b := 1.0 if i % 2 == 0 else -1.0
			var strebe := MeshInstance3D.new()
			var m := BoxMesh.new()
			m.size = groesse
			strebe.mesh = m
			strebe.material_override = mat
			strebe.position = quer_a * (0.46 * vz_a) + quer_b * (0.46 * vz_b)
			_modell.add_child(strebe)


## Beschriftet alle vier Seitenflächen mit dem Symbol der Art.
func _baue_symbole() -> void:
	var text := _symboltext()
	if text == "":
		return
	var stellen: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.505),
		Vector3(0.0, 0.0, -0.505),
		Vector3(0.505, 0.0, 0.0),
		Vector3(-0.505, 0.0, 0.0),
	]
	var drehungen: Array[float] = [0.0, 180.0, 90.0, -90.0]
	for i in stellen.size():
		var schild := Label3D.new()
		schild.text = text
		schild.font_size = 110
		schild.pixel_size = 0.0042
		schild.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		schild.double_sided = false
		schild.modulate = _symbolfarbe()
		schild.outline_size = 16
		schild.outline_modulate = Color(0.06, 0.05, 0.04, 0.9)
		schild.position = stellen[i]
		schild.rotation_degrees = Vector3(0.0, drehungen[i], 0.0)
		_modell.add_child(schild)
		_beschriftungen.append(schild)


## Symbol je Art. Leerer Text = keine Beschriftung.
func _symboltext() -> String:
	match art:
		Art.FRUCHT_MEHRFACH:
			return "x5"
		Art.LEBEN:
			return "1UP"
		Art.FEDER:
			return str(_spruenge_uebrig)
		Art.SPRUNG:
			return "^"
		Art.TNT:
			return "TNT"
		Art.NITRO:
			return "N"
		Art.CHECKPOINT:
			return "C"
		_:
			return ""


func _symbolfarbe() -> Color:
	match art:
		Art.TNT:
			return Color(1.0, 0.94, 0.85)
		Art.NITRO:
			return Color(0.85, 1.0, 0.88)
		Art.SPRUNG:
			return Color(0.90, 0.96, 1.0)
		_:
			return Color(0.99, 0.95, 0.86)


## Setzt den Text aller vier Beschriftungen.
func _setze_beschriftung(text: String) -> void:
	for schild in _beschriftungen:
		if is_instance_valid(schild):
			schild.text = text


# ---------------------------------------------------------------- Ablauf

func _process(delta: float) -> void:
	_zeit += delta
	if _zerstoert or not is_instance_valid(_modell):
		return
	match art:
		Art.NITRO:
			# Warnendes Pulsieren
			var puls := 0.5 + 0.5 * sin(_zeit * 6.0)
			if _korpus_material != null:
				_korpus_material.emission_energy_multiplier = 0.35 + puls * 1.5
			_modell.scale = Vector3.ONE * (1.0 + puls * 0.04)
		Art.TNT:
			if _countdown >= 0.0:
				# Wackeln, je knapper die Zeit, desto heftiger
				var heftig := 0.03 + (1.0 - _countdown / TNT_ZEIT) * 0.05
				_modell.position = Vector3(
						sin(_zeit * 47.0) * heftig, 0.0, cos(_zeit * 39.0) * heftig)
		Art.FEDER:
			_modell.position.y = sin(_zeit * 3.0) * 0.02


func _physics_process(delta: float) -> void:
	if _zerstoert:
		return
	_abprall_sperre = maxf(_abprall_sperre - delta, 0.0)

	if art == Art.TNT and _countdown >= 0.0:
		_countdown -= delta
		_setze_beschriftung(str(maxi(int(ceil(_countdown)), 0)))
		if _countdown <= 0.0:
			_explodieren(TNT_RADIUS, Farben.KISTE_TNT, true)
			return

	var spieler := _spieler_in_zone()
	if spieler == null:
		return
	_auf_spieler(spieler)


## Sucht den Spieler in der Trefferzone.
func _spieler_in_zone() -> Spieler:
	for koerper in _trefferzone.get_overlapping_bodies():
		if koerper is Spieler:
			return koerper as Spieler
	return null


## Echte Berührung: Der Spieler steht an oder auf der Kiste.
## Die Trefferzone reicht bewusst höher (damit ein schneller Fall erkannt
## wird, bevor die Landung `velocity.y` auf 0 setzt) – für die Nitrokiste
## ist das zu großzügig, deshalb hier die enge Prüfung.
func _beruehrt(spieler: Spieler) -> bool:
	var ab: Vector3 = spieler.global_position - global_position
	return absf(ab.x) < 0.88 and absf(ab.z) < 0.88 and ab.y > -1.35 and ab.y < 0.6


## Wertet die Angriffe des Spielers aus.
func _auf_spieler(spieler: Spieler) -> void:
	var maske: int = spieler.angriffe()
	# "Draufspringen": fällt schnell genug UND ist über der Kistenmitte.
	var von_oben: bool = (maske & Angriff.FALLEN) != 0 \
			and spieler.global_position.y > global_position.y + 0.4

	match art:
		Art.EISEN:
			pass
		Art.SPRUNG:
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				spieler.abprallen(SPRUNG_ABPRALL)
		Art.FEDER:
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				_feder_absprung(spieler)
		Art.NITRO:
			# Nur echte Berührung ist tödlich – Drüberspringen bleibt erlaubt.
			if _beruehrt(spieler):
				_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
				spieler.schaden_nehmen()
		Art.TNT:
			if _countdown < 0.0 and ((maske & ZERBRECHENDE_ANGRIFFE) != 0 or von_oben):
				_countdown = TNT_ZEIT
				_setze_beschriftung(str(int(TNT_ZEIT)))
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				spieler.abprallen()
		_:
			if (maske & ZERBRECHENDE_ANGRIFFE) != 0 or von_oben:
				zerbrechen(maske)


## Ein Absprung von der Federkiste: 1 Frucht, danach ein Sprung weniger.
func _feder_absprung(spieler: Spieler) -> void:
	spieler.abprallen(FEDER_ABPRALL)
	_spruenge_uebrig -= 1
	Frucht.streuen(get_parent(), global_position, 1)
	if _spruenge_uebrig <= 0:
		_zerbrechen_ausfuehren(0)
	else:
		_setze_beschriftung(str(_spruenge_uebrig))


# ---------------------------------------------------------------- Schnittstelle

## Von außen aufgerufen (z. B. Schockwelle des Bauchplatschers oder eine
## Explosion). `art_treffer` ist eine Angriff-Konstante, 0 = Umgebung.
## Jede Kistenart entscheidet selbst, ob sie darauf reagiert.
## True, wenn diese Kiste im Kistenzähler des Levels mitzählt.
## Checkpoint-, Sprung- und Eisenkisten zählen nicht.
func zaehlt_mit() -> bool:
	return art != Art.CHECKPOINT and art != Art.SPRUNG and art != Art.EISEN


func zerbrechen(art_treffer: int = 0) -> void:
	if _zerstoert:
		return
	match art:
		Art.EISEN, Art.SPRUNG:
			return                       # unzerstörbar
		Art.NITRO:
			# Aus der Ferne gezündet: gefahrlos für den Spieler.
			_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
		Art.TNT:
			if art_treffer == 0:
				_explodieren(TNT_RADIUS, Farben.KISTE_TNT, true)   # Kettenreaktion
			elif _countdown < 0.0:
				_countdown = TNT_ZEIT
				_setze_beschriftung(str(int(TNT_ZEIT)))
		_:
			_zerbrechen_ausfuehren(art_treffer)


# ---------------------------------------------------------------- Intern

## Belohnung ausschütten, Trümmer erzeugen und verschwinden.
func _zerbrechen_ausfuehren(_art_treffer: int) -> void:
	if _zerstoert:
		return
	_zerstoert = true

	match art:
		Art.CHECKPOINT:
			# Zählt nicht im Kistenzähler, setzt dafür den Respawn-Punkt.
			GameState.setze_checkpoint(global_position + Vector3.UP * 0.6)
		Art.LEBEN:
			GameState.kiste_zerbrochen()
			GameState.leben += 1
			GameState.leben_geaendert.emit(GameState.leben)
			GameState.zeige_nachricht("Extraleben!", 1.5)
		Art.FRUCHT_MEHRFACH:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, FRUECHTE_MEHRFACH)
		Art.FEDER:
			GameState.kiste_zerbrochen()
			# Noch nicht abgeholte Früchte gibt es beim Zerbrechen dazu.
			if _spruenge_uebrig > 0:
				Frucht.streuen(get_parent(), global_position, _spruenge_uebrig)
		_:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, 1)

	_truemmer()
	queue_free()


## Explosion: zerstört Kisten im Umkreis und ggf. den Spieler.
func _explodieren(wirkradius: float, ton: Color, trifft_spieler: bool) -> void:
	if _zerstoert:
		return
	_zerstoert = true

	var elternteil := get_parent()
	var pos := global_position
	GameState.kiste_zerbrochen()
	Explosion.erzeugen(elternteil, pos, wirkradius, ton)

	# Nachbarkisten mitreißen
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var nachbar := knoten as Kiste
		if nachbar == null or nachbar == self or not is_instance_valid(nachbar):
			continue
		if nachbar.global_position.distance_to(pos) <= wirkradius:
			nachbar.zerbrechen(0)

	if trifft_spieler:
		var spieler := get_tree().get_first_node_in_group("spieler") as Spieler
		if spieler != null and spieler.global_position.distance_to(pos) < wirkradius:
			spieler.schaden_nehmen()

	queue_free()


## Ein paar Bruchstücke, die wegfliegen und nach etwa einer Sekunde vergehen.
func _truemmer() -> void:
	var elternteil := get_parent()
	if elternteil == null or not is_instance_valid(elternteil):
		return

	var wurzel := Node3D.new()
	wurzel.name = "Truemmer"
	elternteil.add_child(wurzel)
	wurzel.global_position = global_position

	var mat := _korpus_material if _korpus_material != null \
			else Materialbibliothek.kistenholz(Farben.HOLZ)
	var ziele: Array[Vector3] = []
	for i in 8:
		var stueck := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3.ONE * randf_range(0.18, 0.3)
		stueck.mesh = m
		stueck.material_override = mat
		var richtung := Vector3(randf() * 2.0 - 1.0, randf() * 0.9 + 0.3,
				randf() * 2.0 - 1.0).normalized()
		stueck.position = richtung * 0.25
		wurzel.add_child(stueck)
		ziele.append(richtung * randf_range(1.0, 1.8) + Vector3.DOWN * 0.7)

	var t := wurzel.create_tween()
	t.set_parallel(true)
	var i2 := 0
	for stueck in wurzel.get_children():
		var knoten := stueck as Node3D
		t.tween_property(knoten, "position", ziele[i2], 0.9).set_ease(Tween.EASE_OUT)
		t.tween_property(knoten, "rotation",
				Vector3(randf() * TAU, randf() * TAU, randf() * TAU), 0.9)
		t.tween_property(knoten, "scale", Vector3.ZERO, 0.35).set_delay(0.55)
		i2 += 1
	t.chain().tween_callback(wurzel.queue_free)
