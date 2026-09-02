extends Area3D
class_name Bonustor
## Das Tor in den Bonusraum – der sichtbare Zähler der Marken.
##
## Es steht NEBEN dem Weg, nie darauf. Ein verschlossenes Tor mitten im
## Korridor hielte den auf, der die Marken nicht gefunden hat, und
## bestrafte damit das Suchen statt es zu belohnen. Seitlich gestellt ist
## es ein Angebot: Wer daran vorbeiläuft, verliert nichts.
##
## Solange Marken fehlen, ist der Vorhang dunkel und trägt einen Riegel –
## man kann hineinlaufen und wird sanft abgewiesen, mit dem Stand als
## Meldung. Drei leere Fassungen über dem Sturz füllen sich Stück für
## Stück; der Zähler daneben sagt dasselbe noch einmal in Zahlen.
## Beides zusammen, weil man das eine im Vorbeilaufen sieht und das
## andere lesen kann.

## Der Spieler ist durch das offene Tor gegangen.
signal durchschritten

const TON := Marke.TON

## Lichte Weite und Höhe der Öffnung.
const WEITE := 3.2
const HOEHE := 3.4

var _offen := false
var _gefunden := 0
var _noetig := 3
var _phase := 0.0

var _modell: Node3D
var _vorhang: MeshInstance3D
var _vorhangstoff: StandardMaterial3D
var _riegel: StaticBody3D
var _fassungen: Array[MeshInstance3D] = []
var _zaehler: Label3D
var _schein: OmniLight3D


func _ready() -> void:
	add_to_group("bonustore")
	collision_layer = 0
	collision_mask = 2       # nur den Spieler beachten
	monitoring = true
	body_entered.connect(_auf_koerper)
	_baue()
	_stand_zeigen()


## Baut Pfosten, Sturz, Vorhang, Fassungen und Zähler.
func _baue() -> void:
	_modell = Node3D.new()
	_modell.name = "Modell"
	add_child(_modell)

	# Kühler Stein statt Rinde. Das Tor gehört nicht zum Dschungel, es
	# gehört zu dem, was dahinter liegt – wer es sieht, soll die Farben
	# des Bonusraums schon erkennen, bevor er drin war. Im warmen Grün
	# des Levels hebt sich der kalte Stein zudem überhaupt erst ab; in
	# Rinde war das Tor aus zehn Metern ein Baumstumpf.
	var stein := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	stein.albedo_color = Color(0.30, 0.36, 0.44)
	var halb := WEITE * 0.5 + 0.3
	for seite: float in [-1.0, 1.0]:
		var pfosten := MeshInstance3D.new()
		var quader := BoxMesh.new()
		quader.size = Vector3(0.7, HOEHE + 0.5, 0.8)
		pfosten.mesh = quader
		pfosten.material_override = stein
		pfosten.position = Vector3(seite * halb, (HOEHE + 0.5) * 0.5, 0.0)
		_modell.add_child(pfosten)
		# Türkise Einlage an der Innenkante: die Umrandung der Öffnung.
		var einlage := MeshInstance3D.new()
		var leiste := BoxMesh.new()
		leiste.size = Vector3(0.12, HOEHE, 0.86)
		einlage.mesh = leiste
		einlage.material_override = Materialbibliothek.leuchtend(TON, 1.1)
		einlage.position = Vector3(seite * (WEITE * 0.5 - 0.02), HOEHE * 0.5, 0.0)
		einlage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_modell.add_child(einlage)

	var sturz := MeshInstance3D.new()
	var balken := BoxMesh.new()
	balken.size = Vector3(WEITE + 2.0, 0.8, 1.0)
	sturz.mesh = balken
	sturz.material_override = stein
	sturz.position = Vector3(0.0, HOEHE + 0.6, 0.0)
	_modell.add_child(sturz)

	var oben := MeshInstance3D.new()
	var querleiste := BoxMesh.new()
	querleiste.size = Vector3(WEITE, 0.12, 1.04)
	oben.mesh = querleiste
	oben.material_override = Materialbibliothek.leuchtend(TON, 1.1)
	oben.position = Vector3(0.0, HOEHE + 0.06, 0.0)
	oben.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modell.add_child(oben)

	# --- Der Vorhang: das eigentliche Signal ---
	var flaeche := QuadMesh.new()
	flaeche.size = Vector2(WEITE, HOEHE)
	_vorhang = MeshInstance3D.new()
	_vorhang.name = "Vorhang"
	_vorhang.mesh = flaeche
	_vorhangstoff = Materialbibliothek.transparent(TON, 1.4).duplicate()
	_vorhang.material_override = _vorhangstoff
	_vorhang.position = Vector3(0.0, HOEHE * 0.5, 0.0)
	_vorhang.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modell.add_child(_vorhang)

	# Der Riegel ist eine echte Wand, kein Bild. Sonst liefe man durch
	# ein Tor, das aussieht wie zu.
	_riegel = StaticBody3D.new()
	_riegel.name = "Riegel"
	_riegel.collision_layer = 1
	_riegel.collision_mask = 0
	var form := BoxShape3D.new()
	form.size = Vector3(WEITE, HOEHE, 0.4)
	var kollision := CollisionShape3D.new()
	kollision.shape = form
	_riegel.add_child(kollision)
	_riegel.position = Vector3(0.0, HOEHE * 0.5, 0.0)
	add_child(_riegel)

	# --- Drei Fassungen über dem Sturz ---
	for i in 3:
		var reif := TorusMesh.new()
		reif.inner_radius = 0.20
		reif.outer_radius = 0.30
		reif.rings = 6
		reif.ring_segments = 6
		var mi := MeshInstance3D.new()
		mi.mesh = reif
		mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		mi.position = Vector3((float(i) - 1.0) * 0.85, HOEHE + 1.35, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_modell.add_child(mi)
		_fassungen.append(mi)

	_zaehler = Label3D.new()
	_zaehler.name = "Zaehler"
	_zaehler.font_size = 96
	_zaehler.outline_size = 24
	_zaehler.outline_modulate = Color(0.03, 0.06, 0.06, 1.0)
	_zaehler.pixel_size = 0.006
	_zaehler.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_zaehler.no_depth_test = false
	_zaehler.position = Vector3(0.0, HOEHE + 2.3, 0.0)
	_modell.add_child(_zaehler)

	_schein = OmniLight3D.new()
	_schein.name = "Schein"
	_schein.light_color = TON
	_schein.light_energy = 0.4
	_schein.omni_range = 8.0
	_schein.shadow_enabled = false
	_schein.position = Vector3(0.0, HOEHE * 0.5, 0.0)
	_modell.add_child(_schein)


## Meldet dem Tor den Stand der Suche.
func stand_setzen(gefunden: int, noetig: int) -> void:
	_gefunden = gefunden
	_noetig = maxi(noetig, 1)
	_stand_zeigen()


func _stand_zeigen() -> void:
	if _zaehler == null:
		return
	_zaehler.text = "%d/%d" % [_gefunden, _noetig]
	_zaehler.modulate = TON if _offen else Color(0.62, 0.66, 0.66)
	for i in _fassungen.size():
		var voll := i < _gefunden
		_fassungen[i].material_override = Materialbibliothek.leuchtend(TON, 1.3) \
				if voll else Materialbibliothek.einfarbig(Color(0.16, 0.19, 0.19))
	if not _offen:
		# Geschlossen: fast blickdicht und farblos – ein Loch, kein Weg.
		_vorhangstoff.albedo_color = Color(0.07, 0.10, 0.11, 0.88)
		_vorhangstoff.emission = Color(0.05, 0.09, 0.10)
		_vorhangstoff.emission_energy_multiplier = 0.25


## Öffnet das Tor endgültig. Es bleibt offen – auch über einen Tod hinweg,
## denn die Kisten dahinter werden beim Neuaufbau wieder aufgestellt und
## müssen dann auch wieder erreichbar sein.
func oeffnen() -> void:
	if _offen:
		return
	_offen = true
	_gefunden = _noetig
	_stand_zeigen()
	_vorhangstoff.albedo_color = Color(TON.r, TON.g, TON.b, 0.42)
	_vorhangstoff.emission = TON
	_vorhangstoff.emission_energy_multiplier = 1.8
	if is_instance_valid(_riegel):
		_riegel.queue_free()
		_riegel = null
	if is_instance_valid(_schein):
		_schein.light_energy = 2.4
	Klang.spiele("checkpoint", 0.7)


func ist_offen() -> bool:
	return _offen


func _process(delta: float) -> void:
	_phase += delta
	if _vorhangstoff == null:
		return
	if not _offen:
		return
	var puls := 0.5 + 0.5 * sin(_phase * 2.7)
	_vorhangstoff.emission_energy_multiplier = 1.2 + puls * 1.4
	_vorhangstoff.albedo_color.a = 0.32 + puls * 0.16
	if is_instance_valid(_schein):
		_schein.light_energy = 1.8 + puls * 1.2


func _auf_koerper(koerper: Node3D) -> void:
	if not koerper.is_in_group("spieler"):
		return
	if _offen:
		durchschritten.emit()
	else:
		GameState.zeige_nachricht("Verschlossen – Marken %d/%d"
				% [_gefunden, _noetig], 1.6)
