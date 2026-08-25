extends Node3D
class_name SpielerModell
## Darstellung des Beuteldachses.
##
## Der Player-Controller kennt nur diese Schnittstelle und weiß nichts
## über den Aufbau des Modells:
##   aktualisiere()  – jeden Frame, überträgt den Bewegungszustand
##   setze_blick()   – Blickrichtung in Radiant um die Y-Achse
##   sichtbarkeit()  – Blinken während der Unverwundbarkeit
##
## Das Modell wird prozedural aus Godot-Primitiven aufgebaut, es werden
## keine fremden Asset-Dateien benötigt.
##
## Aufbau (alles hängt unter `_koerper`, damit der Slide-Stauch der
## Basislogik die ganze Figur flach drückt):
##   Teile
##     Koerper (Rumpf)          – Ursprung auf Hüfthöhe, y = 0.7
##       Bauch, Kopf (Schnauze, Nase, Augen, Ohren),
##       Arme (mit Händen), Beine (mit Füßen), Schweif
##     SpinRing                 – Geschwister, damit ihn der Slide nicht verzerrt
##
## Maße: Füße auf y = 0, Ohrenspitzen bei ca. 1.42 m, Breite ca. 0.75 m –
## passt damit in die Kollisionskapsel (Radius 0.38 / Höhe 1.3).
## Das Modell blickt in -Z.
##
## Wer in den Einstellungen eine eigene glTF-Figur hinterlegt, bekommt
## diese statt des Beuteldachses: sie wird auf dieselbe Höhe eingepasst
## und übernimmt die Schnittstelle unverändert.
##
## Bringt die Datei ein Skelett mit Clips mit (Idle/Walk/Run), führen wir
## sie damit. Fehlt das, bewegt `_animiere_eigenes()` sie nur als Ganzes –
## Laufwippen, Slide-Stauchen, Spin-Drehung. Beides greift ineinander:
## Für Sprung und Slide hat kaum eine fremde Figur einen Clip, dort
## übernimmt wieder die Stauchung.

const SPIN_DREHUNG := 30.0   ## Umdrehungsgeschwindigkeit beim Spin

# --- Ruhewerte und Ausschläge der Animation ---
const RUMPF_Y := 0.7         ## Höhe des Rumpf-Ursprungs über dem Boden
const OHR_RUHE := 0.10       ## Grundneigung der Ohren nach hinten
const OHR_SPREIZUNG := 0.22  ## Grundneigung der Ohren nach außen
const ARM_SPIN := 1.45       ## Arme waagerecht beim Spin
const ARM_LUFT := 2.90       ## Arme steil nach oben in der Luft

var _blick := 0.0
var _spin_alpha := 0.0
var _lauf_phase := 0.0

var _koerper: MeshInstance3D
var _spin_ring: MeshInstance3D
var _teile: Node3D

## Gesetzt, wenn statt des Beuteldachses eine eigene Datei angezeigt wird.
var _eigenes: Node3D = null
## AnimationPlayer der eigenen Figur, falls sie ein Skelett mitbringt.
var _eigener_spieler: AnimationPlayer = null
## Zugeordnete Clips: leerer Name = die Figur hat dafür keinen.
var _clip_pose := ""
var _clip_ruhe := ""
var _clip_schlendern := ""
var _clip_gehen := ""
var _clip_rennen := ""
var _clip_sprung := ""
var _clip_slide := ""
var _clip_spin := ""
var _clip_sitzen := ""
var _clip_reiten := ""
var _clip_krabbeln := ""
var _clip_hangeln := ""
var _clip_laeuft := ""
## War die Figur im letzten Bild im Slide? Der Slideclip wird beim Ansetzen
## einmal angestoßen, nicht jedes Bild neu.
var _war_im_slide := false
## War die Figur im letzten Bild in der Luft? Der Sprungclip wird beim
## Abheben EINMAL angestoßen, nicht jedes Bild neu.
var _war_in_luft := false

# --- Bewegliche Teile ---
var _kopf: Node3D
var _ohr_links: Node3D
var _ohr_rechts: Node3D
var _arm_links: Node3D
var _arm_rechts: Node3D
var _bein_links: Node3D
var _bein_rechts: Node3D
var _schweif: Node3D
var _schweif_spitze: Node3D

# --- Zustand der Animation ---
var _zeit := 0.0             ## Laufende Zeit für Atmen und Zucken
var _atem := 0.0             ## 0 = bewegt, 1 = ruhig atmend
var _zuck := 0.0             ## Restzeit des Ohrenzuckens
var _zuck_pause := 3.0       ## Zeit bis zum nächsten Ohrenzucken


func _ready() -> void:
	if not _baue_eigenes():
		_baue()


# ---------------------------------------------------------------- Aufbau

## Versucht, die in den Einstellungen gewählte eigene Figur zu laden.
## Schlägt das fehl (keine gewählt, Datei weg, unlesbar), wird ganz normal
## der Beuteldachs gebaut – ein kaputter Pfad darf nie zu einer unsichtbaren
## Spielfigur führen.
func _baue_eigenes() -> bool:
	var pfad := Einstellungen.modell_pfad()
	if pfad.is_empty():
		return false
	var figur := ModellLader.laden(pfad, Einstellungen.modell_groesse,
			Einstellungen.modell_drehung)
	if figur == null:
		return false

	_teile = Node3D.new()
	_teile.name = "Teile"
	add_child(_teile)

	# Die eingepasste Figur bekommt einen eigenen Halter: die Einpassung
	# steckt in ihrer Verwandlung, der Halter bleibt bei Maßstab 1 und
	# Ursprung auf Fußhöhe. Nur so drückt ein Stauchen die Figur zu Boden,
	# statt sie in der Luft schrumpfen zu lassen.
	var halter := Node3D.new()
	halter.name = "EigeneFigur"
	halter.add_child(figur)
	_teile.add_child(halter)
	_eigenes = halter

	# Bringt die Figur ein Skelett samt Clips mit, führen wir sie damit –
	# das schlägt jede Ganzkörper-Stauchung. Fehlt der Spieler oder ein
	# Clip, greift für diesen Zustand wieder die einfache Bewegung.
	_eigener_spieler = ModellLader.spieler_von(figur)
	if _eigener_spieler != null:
		_clips_zuordnen()

	_baue_spin_ring()
	return true


## Baut den kompletten Beuteldachs aus Primitiven auf.
##
## Silhouette: breite Schultern, schmale Hüfte, lange Schnauze, hohe
## Ohren, buschiger Schweif. Die Zeichnung im Fell (heller Bauch, dunkles
## Rückenband, geringelter Schweif) gibt der Figur auch aus der Ferne
## eine erkennbare Kontur.
func _baue() -> void:
	_teile = Node3D.new()
	_teile.name = "Teile"
	add_child(_teile)

	var fell := Materialbibliothek.fell()
	var bauchfell := Materialbibliothek.fell(Farben.FELL_BAUCH.lerp(Farben.FRUCHT, 0.22))
	var dunkelfell := Materialbibliothek.fell(Farben.FELL_DUNKEL)
	var nasenfarbe := Materialbibliothek.einfarbig(Farben.NASE, 0.35)
	var augapfel := Materialbibliothek.einfarbig(Color(0.97, 0.97, 0.93), 0.25)

	# --- Rumpf: trägt als Wurzel alle übrigen Teile ---
	_koerper = MeshInstance3D.new()
	_koerper.name = "Koerper"
	_koerper.mesh = _kapsel(0.29, 0.86)
	_koerper.material_override = fell
	_koerper.position.y = RUMPF_Y
	_teile.add_child(_koerper)

	# Breiter Brustkorb – macht die Schultern kräftig, die Hüfte bleibt schmal
	var brust := _netz(_koerper, "Brust", _kugel(0.27), fell, Vector3(0.0, 0.20, -0.02))
	brust.scale = Vector3(1.28, 0.76, 1.04)

	# Dunkle Halskrause – setzt den Kopf von den Schultern ab
	var kragen := _netz(_koerper, "Kragen", _kugel(0.215), dunkelfell,
			Vector3(0.0, 0.34, -0.03))
	kragen.scale = Vector3(1.12, 0.42, 1.10)

	# Heller Bauch, deutlich nach vorn (-Z) gewölbt
	var bauch := _netz(_koerper, "Bauch", _kugel(0.215), bauchfell,
			Vector3(0.0, -0.09, -0.165))
	bauch.scale = Vector3(0.98, 1.18, 0.74)

	# Dunkles Rückenband: drei flach aufliegende Flecken, nach unten schmaler
	var zeichnung := Materialbibliothek.fell(Farben.FELL_DUNKEL.darkened(0.32))
	var band: Array = [[0.25, 0.250, 0.125, 1.45], [0.02, 0.272, 0.140, 1.45],
			[-0.21, 0.262, 0.110, 1.30]]
	for i in band.size():
		var fleck := _netz(_koerper, "Rueckenband%d" % i, _kugel(band[i][2]),
				zeichnung, Vector3(0.0, band[i][0], band[i][1]))
		fleck.scale = Vector3(band[i][3], 1.0, 0.20)

	_baue_kopf(fell, bauchfell, dunkelfell, nasenfarbe, augapfel)
	_baue_arme(fell, dunkelfell)
	_baue_beine(fell, dunkelfell)
	_baue_schweif(fell, dunkelfell)

	_baue_spin_ring()


## Spin-Ring: Geschwister des Rumpfes, damit ihn der Slide-Stauch nicht
## verzerrt. Auch eine eigene Figur bekommt ihn – sonst fehlte die einzige
## Rückmeldung, dass der Drehschlag gerade wirkt.
func _baue_spin_ring() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.77
	ring.outer_radius = 0.93
	_spin_ring = MeshInstance3D.new()
	_spin_ring.name = "SpinRing"
	_spin_ring.mesh = ring
	_spin_ring.position.y = 0.6
	var ringstoff := Materialbibliothek.transparent(Farben.SPIN_RING, 1.4).duplicate()
	# Unsichtbar starten: `aktualisiere()` blendet ihn beim Drehschlag ein.
	# Ohne das stünde der Ring bis zum ersten Bild voll sichtbar um die Figur.
	if ringstoff is StandardMaterial3D:
		(ringstoff as StandardMaterial3D).albedo_color.a = 0.0
	_spin_ring.material_override = ringstoff
	_teile.add_child(_spin_ring)


## Kopf mit langer Schnauze, Wangen, Augen samt Lidern, Brauen,
## Stachelfrisur und hohen Ohren.
func _baue_kopf(fell: Material, bauchfell: Material, dunkelfell: Material,
		nasenfarbe: Material, augapfel: Material) -> void:
	_kopf = _gelenk(_koerper, "Kopf", Vector3(0.0, 0.40, -0.03))

	var schaedel := _netz(_kopf, "Schaedel", _kugel(0.235), fell)
	schaedel.scale = Vector3(1.08, 0.99, 1.00)

	# Wangen: geben dem Kopf Breite und trennen ihn von der Schnauze
	for seite in [-1.0, 1.0]:
		var wange := _netz(_kopf, "Wange%s" % ("R" if seite > 0.0 else "L"),
				_kugel(0.105), fell, Vector3(0.135 * seite, -0.09, -0.12))
		wange.scale = Vector3(0.9, 0.82, 1.15)

	# Lange, flache Schnauze: breiter als hoch, ragt deutlich nach -Z heraus
	var schnauze := _netz(_kopf, "Schnauze", _kegel(0.135, 0.048, 0.46), fell,
			Vector3(0.0, -0.06, -0.27))
	schnauze.rotation.x = -PI * 0.5
	schnauze.scale = Vector3(1.12, 1.0, 0.72)

	# Helle Unterseite der Schnauze
	var kinn := _netz(_kopf, "Kinn", _kugel(0.115), bauchfell,
			Vector3(0.0, -0.115, -0.26))
	kinn.scale = Vector3(0.90, 0.50, 1.55)

	# Dunkler Mundstrich unter der Nase
	var mund := _netz(_kopf, "Mund", _kugel(0.05), nasenfarbe,
			Vector3(0.0, -0.105, -0.395))
	mund.scale = Vector3(1.45, 0.26, 0.7)

	var nase := _netz(_kopf, "Nase", _kugel(0.062), nasenfarbe,
			Vector3(0.0, -0.028, -0.455))
	nase.scale = Vector3(1.3, 0.88, 0.85)

	# Helle Blesse über Nasenrücken und Stirn – die Dachszeichnung
	var blesse := _netz(_kopf, "Blesse", _kugel(0.10), bauchfell,
			Vector3(0.0, 0.005, -0.275))
	blesse.scale = Vector3(0.44, 0.55, 2.5)

	# Augen: dunkle Maske, Augapfel, große Pupille, Glanzpunkt, Lid und Braue
	for seite in [-1.0, 1.0]:
		var kuerzel := "R" if seite > 0.0 else "L"
		# Dunkle Augenmaske: zieht sich vom Nasenrücken bis zum Ohr
		var maske := _netz(_kopf, "Maske%s" % kuerzel, _kugel(0.125), dunkelfell,
				Vector3(0.128 * seite, 0.085, -0.155))
		maske.scale = Vector3(1.10, 0.92, 0.72)
		maske.rotation.z = -0.22 * seite

		var auge := _netz(_kopf, "Auge%s" % kuerzel, _kugel(0.080), augapfel,
				Vector3(0.118 * seite, 0.085, -0.185))
		auge.scale = Vector3(1.0, 1.12, 1.0)
		_netz(auge, "Pupille", _kugel(0.043), nasenfarbe, Vector3(0.0, -0.004, -0.050))
		var glanz := _netz(auge, "Glanz", _kugel(0.018), augapfel,
				Vector3(-0.020 * seite, 0.028, -0.066))
		glanz.scale = Vector3(1.0, 1.0, 0.6)

		# Oberlid: zieht die Augen zu und gibt der Figur einen wachen Blick
		var lid := _netz(auge, "Lid", _kugel(0.086), fell, Vector3(0.0, 0.050, 0.006))
		lid.scale = Vector3(1.0, 0.66, 1.0)

		# Braue: leicht nach außen angehoben
		var braue := _netz(_kopf, "Braue%s" % kuerzel, _kugel(0.055), dunkelfell,
				Vector3(0.122 * seite, 0.175, -0.165))
		braue.scale = Vector3(1.55, 0.42, 0.55)
		braue.rotation.z = -0.28 * seite

	# Stachelfrisur zwischen den Ohren
	for i in 3:
		var strubbel := _netz(_kopf, "Stachel%d" % i, _kegel(0.048, 0.0, 0.17),
				dunkelfell, Vector3((float(i) - 1.0) * 0.085, 0.205, 0.055))
		strubbel.rotation.x = 0.85 + absf(float(i) - 1.0) * 0.12

	# Aufgestellte Ohren – Dreiecksprismen auf eigenen Gelenken
	_ohr_rechts = _baue_ohr(1.0, fell, dunkelfell)
	_ohr_links = _baue_ohr(-1.0, fell, dunkelfell)


## Ein Ohr; seite = +1 rechts (+X), -1 links (-X).
func _baue_ohr(seite: float, fell: Material, dunkelfell: Material) -> Node3D:
	var gelenk := _gelenk(_kopf, "Ohr%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.145 * seite, 0.125, 0.02))
	gelenk.rotation = Vector3(OHR_RUHE, 0.0, -OHR_SPREIZUNG * seite)

	var muschel := PrismMesh.new()
	muschel.size = Vector3(0.17, 0.20, 0.075)
	_netz(gelenk, "Muschel", muschel, fell, Vector3(0.0, 0.105, 0.0))

	var innen := PrismMesh.new()
	innen.size = Vector3(0.10, 0.125, 0.02)
	_netz(gelenk, "Innenohr", innen, dunkelfell, Vector3(0.0, 0.09, -0.045))
	return gelenk


## Beide Arme mit dunklen Pfoten.
func _baue_arme(fell: Material, dunkelfell: Material) -> void:
	_arm_rechts = _baue_arm(1.0, fell, dunkelfell)
	_arm_links = _baue_arm(-1.0, fell, dunkelfell)


func _baue_arm(seite: float, fell: Material, dunkelfell: Material) -> Node3D:
	var gelenk := _gelenk(_koerper, "Arm%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.29 * seite, 0.22, 0.0))
	var schulter := _netz(gelenk, "Schulter", _kugel(0.105), fell)
	schulter.scale = Vector3(1.0, 0.95, 1.0)
	_netz(gelenk, "Oberarm", _kapsel(0.072, 0.30), fell, Vector3(0.0, -0.17, 0.0))
	var hand := _netz(gelenk, "Hand", _kugel(0.095), dunkelfell, Vector3(0.0, -0.35, 0.0))
	hand.scale = Vector3(0.9, 1.0, 1.2)
	return gelenk


## Beide Beine mit dunklen Füßen.
func _baue_beine(fell: Material, dunkelfell: Material) -> void:
	_bein_rechts = _baue_bein(1.0, fell, dunkelfell)
	_bein_links = _baue_bein(-1.0, fell, dunkelfell)


func _baue_bein(seite: float, fell: Material, dunkelfell: Material) -> Node3D:
	var gelenk := _gelenk(_koerper, "Bein%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.155 * seite, -0.30, 0.0))
	_netz(gelenk, "Schenkel", _kapsel(0.105, 0.32), fell, Vector3(0.0, -0.14, 0.0))

	var fuss := BoxMesh.new()
	fuss.size = Vector3(0.19, 0.105, 0.31)
	_netz(gelenk, "Fuss", fuss, dunkelfell, Vector3(0.0, -0.345, -0.075))
	# Helle Zehenkappe – trennt den Fuß optisch vom Boden
	var kappe := _netz(gelenk, "Zehen", _kugel(0.075), fell,
			Vector3(0.0, -0.345, -0.215))
	kappe.scale = Vector3(1.2, 0.65, 0.7)
	return gelenk


## Buschiger Schweif aus mehreren Kugeln auf zwei Gelenken, mit Ringen.
func _baue_schweif(fell: Material, dunkelfell: Material) -> void:
	_schweif = _gelenk(_koerper, "Schweif", Vector3(0.0, -0.16, 0.22))
	var wurzel := _netz(_schweif, "Wurzel", _kugel(0.115), fell, Vector3(0.0, 0.03, 0.05))
	wurzel.scale = Vector3(0.95, 1.0, 1.15)

	# Erster Ring
	var ring_a := _netz(_schweif, "RingA", _kugel(0.112), dunkelfell,
			Vector3(0.0, 0.085, 0.09))
	ring_a.scale = Vector3(1.02, 0.30, 1.02)

	_schweif_spitze = _gelenk(_schweif, "Spitze", Vector3(0.0, 0.12, 0.12))
	_netz(_schweif_spitze, "Busch", _kugel(0.098), fell, Vector3(0.0, 0.02, 0.03))
	var ring_b := _netz(_schweif_spitze, "RingB", _kugel(0.095), dunkelfell,
			Vector3(0.0, 0.055, 0.055))
	ring_b.scale = Vector3(1.02, 0.30, 1.02)
	_netz(_schweif_spitze, "Zipfel", _kugel(0.072), dunkelfell, Vector3(0.0, 0.10, 0.10))


# ------------------------------------------------------- Bau-Hilfsfunktionen

## Legt ein Drehgelenk (reiner Node3D) unter dem Elternteil an.
func _gelenk(elternteil: Node3D, bezeichnung: String, pos: Vector3) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	knoten.position = pos
	elternteil.add_child(knoten)
	return knoten


## Hängt ein Mesh mit Material unter den Elternteil.
func _netz(elternteil: Node3D, bezeichnung: String, netz: Mesh, material: Material,
		pos := Vector3.ZERO) -> MeshInstance3D:
	var teil := MeshInstance3D.new()
	teil.name = bezeichnung
	teil.mesh = netz
	teil.material_override = material
	teil.position = pos
	elternteil.add_child(teil)
	return teil


func _kugel(radius: float) -> SphereMesh:
	var netz := SphereMesh.new()
	netz.radius = radius
	netz.height = radius * 2.0
	netz.radial_segments = 16
	netz.rings = 8
	return netz


func _kapsel(radius: float, hoehe: float) -> CapsuleMesh:
	var netz := CapsuleMesh.new()
	netz.radius = radius
	netz.height = maxf(hoehe, radius * 2.0)
	netz.radial_segments = 16
	netz.rings = 6
	return netz


## Kegelstumpf entlang +Y (unten breit, oben spitz).
func _kegel(unten: float, oben: float, hoehe: float) -> CylinderMesh:
	var netz := CylinderMesh.new()
	netz.bottom_radius = unten
	netz.top_radius = oben
	netz.height = hoehe
	netz.radial_segments = 14
	return netz


# ---------------------------------------------------------- Schnittstelle

## Überträgt den Bewegungszustand.
## tempo: 0..1, luft: in der Luft, slide/spin: Restzeiten in Sekunden.
func aktualisiere(delta: float, tempo: float, luft: bool, slide: float,
		spin: float, haltung: String = "") -> void:
	# Blickrichtung bzw. Spin-Drehung.
	#
	# Bringt die Figur einen eigenen Spinclip mit, dreht der bereits um
	# volle 360°. Dann darf der Knoten NICHT zusätzlich gedreht werden,
	# sonst wirbelt die Figur doppelt so schnell und die Blickrichtung
	# stimmt hinterher nicht mehr.
	var eigener_spin := spin > 0.0 and not _clip_spin.is_empty()
	if spin > 0.0:
		if not eigener_spin:
			rotation.y += delta * SPIN_DREHUNG
		else:
			rotation.y = _blick
		_spin_alpha = 0.85
	else:
		rotation.y = _blick
		_spin_alpha = maxf(_spin_alpha - delta * 5.0, 0.0)

	if is_instance_valid(_spin_ring):
		var mat := _spin_ring.material_override
		if mat is StandardMaterial3D:
			mat.albedo_color.a = _spin_alpha

	# Slide: flach drücken
	if is_instance_valid(_koerper):
		var im_slide := slide > 0.0
		_koerper.scale.y = 0.45 if im_slide else 1.0
		_koerper.position.y = 0.4 if im_slide else 0.7

	# Laufzyklus (wird von abgeleiteten Modellen genutzt)
	_lauf_phase += delta * tempo * 12.0

	if is_instance_valid(_eigenes):
		_animiere_eigenes(delta, tempo, luft, slide > 0.0, spin > 0.0, haltung)
		return
	_animiere(delta, tempo, luft, slide > 0.0, spin > 0.0)


func setze_blick(winkel: float) -> void:
	_blick = winkel


func sichtbarkeit(sichtbar: bool) -> void:
	visible = sichtbar


# ---------------------------------------------------------------- Animation

## Bewegung einer fremden Figur. Ihre Gliedmaßen sind unbekannt, also wird
## nur der ganze Körper bewegt: Laufwippen, gestreckt in der Luft, flach im
## Slide, ruhiges Atmen im Stand. Der Halter sitzt auf Fußhöhe, ein
## Stauchen drückt die Figur damit zu Boden statt in der Luft zu schrumpfen.
func _animiere_eigenes(delta: float, tempo: float, luft: bool, slide: bool,
		spin: bool, haltung: String) -> void:
	_zeit += delta
	_fuehre_clips(tempo, luft, slide, spin, haltung)
	var ziel := Vector3.ONE
	var wippen := 0.0
	if slide:
		ziel = Vector3(1.16, 0.5, 1.08)
	elif luft:
		ziel = Vector3(0.94, 1.09, 0.94)
	elif tempo > 0.05:
		wippen = absf(sin(_lauf_phase)) * 0.07 * tempo
		var stoss := 1.0 - wippen * 0.4
		ziel = Vector3(1.0 / stoss, stoss, 1.0 / stoss)
	else:
		var atem := sin(_zeit * 1.9) * 0.014
		ziel = Vector3(1.0 - atem, 1.0 + atem, 1.0 - atem)

	# Trägt die Figur eigene Clips, übernehmen die den Lauf. Die Stauchung
	# bleibt dann aus, sonst kämen zwei Bewegungen übereinander.
	if _eigener_spieler != null and not _clip_laeuft.is_empty():
		ziel = Vector3.ONE
		wippen = 0.0
	_eigenes.scale = _eigenes.scale.lerp(ziel, minf(delta * 16.0, 1.0))
	_eigenes.position.y = lerpf(_eigenes.position.y, wippen, minf(delta * 16.0, 1.0))


## Ordnet die Clips der Figur den Bewegungszuständen zu.
##
## Erwartet werden die elf Namen, die unsere eigenen Figuren mitbringen
## (siehe assets/modelle/LIESMICH.md): IdlePose, Idle, WalkSlow, Walk, Run,
## Jump, Slide, Spin, Crawl, Ride, Sit. Deutsche Namen werden ebenso
## erkannt, und fehlt einer, greift für diesen Zustand der nächstbeste –
## eine Figur mit nur "Walk" läuft eben auch im Schlendern damit.
##
## Reihenfolge beachten: "walkslow" wird VOR "walk" gesucht. `clip_fuer()`
## prüft erst auf Gleichheit und dann auf Wortstamm; ohne diese Reihenfolge
## bekäme ein Modell ohne eigenen "Walk" den langsamen Clip auch fürs
## normale Gehen zugeteilt, ohne dass es auffiele.
func _clips_zuordnen() -> void:
	_clip_pose = _erster_clip(["idlepose", "ruhepose", "pose"])
	_clip_ruhe = _erster_clip(["idle", "ruhe", "atmen"])
	_clip_schlendern = _erster_clip(["walkslow", "schlendern", "gehen_langsam"])
	_clip_gehen = _erster_clip(["walk", "gehen"])
	_clip_rennen = _erster_clip(["run", "rennen", "sprint"])
	_clip_sprung = _erster_clip(["jump", "sprung"])
	_clip_slide = _erster_clip(["slide", "rutsch", "graetsche"])
	_clip_spin = _erster_clip(["spin", "drehschlag", "dreh"])
	_clip_sitzen = _erster_clip(["sit", "sitzen"])
	_clip_reiten = _erster_clip(["ride", "reiten"])
	_clip_krabbeln = _erster_clip(["crawl", "krabbeln", "kriechen"])
	# "hang" kollidiert mit keinem der elf bisherigen Namen.
	_clip_hangeln = _erster_clip(["hang", "hangeln", "haengen"])

	# Die Zyklen laufen endlos, sonst bleibt die Figur nach einem
	# Durchlauf im letzten Bild stehen. Ruhepose und Sprung dagegen NICHT:
	# Die Pose ist ein einzelnes Bild, und ein Sprung, der sich wiederholt,
	# sähe aus wie ein Hüpfen an Ort und Stelle.
	# Haltungen laufen endlos: Wer sitzt, sitzt weiter, und wer krabbelt,
	# braucht einen Zyklus wie beim Gehen.
	for clip: String in [_clip_ruhe, _clip_schlendern, _clip_gehen, _clip_rennen,
			_clip_spin, _clip_sitzen, _clip_reiten, _clip_krabbeln,
			_clip_hangeln]:
		_schleife_setzen(clip, Animation.LOOP_LINEAR)
	for clip: String in [_clip_pose, _clip_sprung, _clip_slide]:
		_schleife_setzen(clip, Animation.LOOP_NONE)


## Hält den Sprungclip am Scheitel an, solange die Figur noch fliegt.
##
## Der Clip ist mit 1,15 s deutlich länger als ein Sprung dauert (0,64 s
## bei JUMP_V 12,2 und G -38). Wer tiefer fällt – in ein Loch oder nach
## einem Bauchplatscher – wäre sonst noch in der Luft, während der Clip
## schon die Landung samt Aufrichten abgespielt hat und im letzten Bild
## stehen bleibt: Die Figur schwebt dann in Landepose durchs Bild.
##
## Die Marken sind Anteile der Clip-Länge, nicht feste Sekunden – so
## passen sie auch zu einer Figur mit anders langem Sprung.
const SCHEITEL_ANTEIL := 0.48   ## ~0,55 s von 1,15 s: höchster Punkt
const LANDUNG_ANTEIL := 0.78    ## ~0,90 s von 1,15 s: Aufsetzen


func _am_scheitel_halten() -> void:
	if _clip_sprung.is_empty() or _clip_laeuft != _clip_sprung:
		return
	var anim := _eigener_spieler.get_animation(_clip_sprung)
	if anim == null:
		return
	var scheitel := anim.length * SCHEITEL_ANTEIL
	if _eigener_spieler.current_animation_position > scheitel:
		_eigener_spieler.seek(scheitel, true)


## Beim Aufsetzen in den Landeteil des Clips springen.
##
## Ohne das bliebe die Figur beim Landen in der Scheitelpose stehen, bis
## der nächste Bodenclip übergeblendet ist – sie käme mit angezogenen
## Beinen auf. Der Landeteil ist kurz; die Überblendung zum Geh- oder
## Ruheclip läuft ohnehin gleich darüber.
func _landeteil_anspielen() -> void:
	if _clip_sprung.is_empty() or _clip_laeuft != _clip_sprung:
		return
	var anim := _eigener_spieler.get_animation(_clip_sprung)
	if anim == null:
		return
	_eigener_spieler.seek(anim.length * LANDUNG_ANTEIL, true)


## Ordnet eine Haltung ihrem Clip zu. Leer, wenn keine gesetzt ist oder
## die Figur den passenden Clip nicht mitbringt – dann entscheidet wie
## bisher der Bewegungszustand.
func _clip_zu_haltung(haltung: String) -> String:
	match haltung:
		"sitzen":
			return _clip_sitzen
		"reiten":
			return _clip_reiten
		"krabbeln":
			return _clip_krabbeln
		"hangeln":
			return _clip_hangeln
		_:
			return ""


## Hält den Slideclip in der Grätsche, solange gerutscht wird.
##
## Der Clip dauert 0,9 s, ein Slide aber nur SLIDE_TIME = 0,42 s. Die
## Haltephase liegt zwischen 0,2 und 0,55 s; dort wird angehalten, damit
## ein Slide nie mitten im Aufstehen endet. Umgekehrt gilt: Wäre ein Slide
## einmal länger, streckt sich die Grätsche statt durchzulaufen.
const GRAETSCHE_ANTEIL := 0.61   ## ~0,55 s von 0,9 s: Ende der Haltephase
const AUFSTEHEN_ANTEIL := 0.64   ## kurz danach beginnt das Aufrichten


func _in_graetsche_halten() -> void:
	if _clip_slide.is_empty() or _clip_laeuft != _clip_slide:
		return
	var anim := _eigener_spieler.get_animation(_clip_slide)
	if anim == null:
		return
	var halten := anim.length * GRAETSCHE_ANTEIL
	if _eigener_spieler.current_animation_position > halten:
		_eigener_spieler.seek(halten, true)


func _aufstehteil_anspielen() -> void:
	if _clip_slide.is_empty() or _clip_laeuft != _clip_slide:
		return
	var anim := _eigener_spieler.get_animation(_clip_slide)
	if anim == null:
		return
	_eigener_spieler.seek(anim.length * AUFSTEHEN_ANTEIL, true)


func _erster_clip(wuensche: Array) -> String:
	for wunsch: String in wuensche:
		var treffer := ModellLader.clip_fuer(_eigener_spieler, wunsch)
		if not treffer.is_empty():
			return treffer
	return ""


func _schleife_setzen(clip: String, art: Animation.LoopMode) -> void:
	if clip.is_empty():
		return
	var anim := _eigener_spieler.get_animation(clip)
	if anim != null:
		anim.loop_mode = art


## Wählt den passenden Clip und blendet weich hinüber.
##
## Für Sprung, Slide und Drehschlag bringt so eine Figur meist nichts mit;
## dort bleibt der Laufclip stehen und die Stauchung aus `_animiere_eigenes`
## übernimmt – lieber ein ruhiger Körper als ein Gehzyklus in der Luft.
func _fuehre_clips(tempo: float, luft: bool, slide: bool, spin: bool,
		haltung: String) -> void:
	if _eigener_spieler == null:
		return

	# Eine gesetzte Haltung schlägt alles andere: Wer auf der Wildkatze
	# sitzt oder im Kart hockt, soll nicht zwischendurch einen Gehzyklus
	# zeigen, nur weil sich die Figur über die Strecke bewegt. Beim
	# Krabbeln gilt dasselbe – die Beine machen dort etwas anderes.
	var haltungsclip := _clip_zu_haltung(haltung)
	if not haltungsclip.is_empty():
		_war_in_luft = luft
		_war_im_slide = false
		if _clip_laeuft != haltungsclip:
			_clip_laeuft = haltungsclip
			_eigener_spieler.play(haltungsclip, 0.15)
		return

	# Der Drehschlag steht vorn: Er kann am Boden UND in der Luft laufen –
	# der Doppelsprung setzt ihn kurz mit –, und er ist die auffälligere
	# Bewegung. Der Clip läuft in Schleife, solange gedreht wird.
	if spin and not _clip_spin.is_empty():
		_war_in_luft = luft
		_war_im_slide = false
		if _clip_laeuft != _clip_spin:
			_clip_laeuft = _clip_spin
			_eigener_spieler.play(_clip_spin, 0.06)
		return

	# Slide: einmal anstoßen, in der Grätsche halten, beim Aufstehen weiter.
	if slide and not _clip_slide.is_empty():
		if not _war_im_slide:
			_war_im_slide = true
			_clip_laeuft = _clip_slide
			_eigener_spieler.play(_clip_slide, 0.06)
		else:
			_in_graetsche_halten()
		return
	if _war_im_slide:
		_war_im_slide = false
		_aufstehteil_anspielen()

	if luft:
		# Abheben stößt den Sprungclip genau einmal an.
		if not _war_in_luft and not _clip_sprung.is_empty():
			_war_in_luft = true
			_clip_laeuft = _clip_sprung
			_eigener_spieler.play(_clip_sprung, 0.08)
			return
		_war_in_luft = true
		# Ohne eigenen Sprungclip bleibt der letzte Bodenclip stehen; die
		# Stauchung aus `_animiere_eigenes()` zeigt den Sprung dann.
		_am_scheitel_halten()
		return

	if _war_in_luft:
		_landeteil_anspielen()
	_war_in_luft = false

	var wunsch := _clip_ruhe if not _clip_ruhe.is_empty() else _clip_pose
	if not slide:
		if tempo > 0.75 and not _clip_rennen.is_empty():
			wunsch = _clip_rennen
		elif tempo > 0.35 and not _clip_gehen.is_empty():
			wunsch = _clip_gehen
		elif tempo > 0.05:
			# Beim Schlendern zur Not den normalen Gehclip nehmen.
			wunsch = _clip_schlendern if not _clip_schlendern.is_empty() \
					else _clip_gehen
	if wunsch.is_empty() or wunsch == _clip_laeuft:
		return
	_clip_laeuft = wunsch
	# Kurze Überblendung, damit der Wechsel zwischen den Gangarten nicht
	# springt. Aus dem Sprung heraus etwas länger, das federt die Landung.
	_eigener_spieler.play(wunsch, 0.18)


## Bewegt alle Gliedmaßen passend zum Bewegungszustand.
## Die Zielwinkel werden pro Zustand gesetzt und anschließend weich
## angefahren – dadurch federn Ohren und Schweif von selbst nach.
func _animiere(delta: float, tempo: float, luft: bool, slide: bool, spin: bool) -> void:
	if not is_instance_valid(_koerper):
		return

	_zeit += delta
	var t := clampf(tempo, 0.0, 1.0)
	var schwung := sin(_lauf_phase)              # Laufschwingung
	var nachlauf := sin(_lauf_phase - 1.1)       # verzögerte Schwingung
	var ruhig := not luft and not slide and t <= 0.05

	# --- Zielwerte, Ruhepose als Ausgangspunkt ---
	var z_bein_r := Vector3.ZERO
	var z_bein_l := Vector3.ZERO
	var z_arm_r := Vector3(0.0, 0.0, 0.08)
	var z_arm_l := Vector3(0.0, 0.0, -0.08)
	var z_kopf := Vector3.ZERO
	var z_rumpf := Vector3.ZERO
	var z_schweif := Vector3(-0.15, 0.0, 0.0)
	var z_spitze := Vector3(-0.10, 0.0, 0.0)
	var ohr_neigung := OHR_RUHE
	var wippen := 0.0

	if slide:
		# Bauch am Boden: Beine nach hinten gestreckt, Arme nach vorn
		z_bein_r = Vector3(-1.20, 0.0, 0.10)
		z_bein_l = Vector3(-1.20, 0.0, -0.10)
		z_arm_r = Vector3(1.35, 0.0, 0.18)
		z_arm_l = Vector3(1.35, 0.0, -0.18)
		z_kopf = Vector3(0.45, 0.0, 0.0)
		z_rumpf = Vector3(-0.12, 0.0, 0.0)
		z_schweif = Vector3(-0.50, 0.0, 0.0)
		z_spitze = Vector3(-0.30, 0.0, 0.0)
		ohr_neigung = 0.60
	elif luft:
		# Beine angezogen, Arme nach oben
		z_bein_r = Vector3(0.85, 0.0, 0.12)
		z_bein_l = Vector3(0.85, 0.0, -0.12)
		z_arm_r = Vector3(0.0, 0.0, ARM_LUFT)
		z_arm_l = Vector3(0.0, 0.0, -ARM_LUFT)
		z_kopf = Vector3(0.18, 0.0, 0.0)
		z_schweif = Vector3(-0.40, 0.0, 0.0)
		z_spitze = Vector3(-0.25, 0.0, 0.0)
		ohr_neigung = 0.40
	elif t > 0.05:
		# Laufen: Beine und Arme gegengleich, Rumpf wippt
		z_bein_r = Vector3(schwung * 0.80 * t, 0.0, 0.05)
		z_bein_l = Vector3(-schwung * 0.80 * t, 0.0, -0.05)
		z_arm_r = Vector3(-schwung * 0.65 * t, 0.0, 0.12)
		z_arm_l = Vector3(schwung * 0.65 * t, 0.0, -0.12)
		z_kopf = Vector3(-0.08 * t + nachlauf * 0.06 * t, 0.0, 0.0)
		z_rumpf = Vector3(-0.14 * t, 0.0, sin(_lauf_phase * 0.5) * 0.07 * t)
		# Schweif wedelt und läuft dabei hinterher
		z_schweif = Vector3(-0.30 * t - 0.15, nachlauf * 0.30 * t, 0.0)
		z_spitze = Vector3(-0.15 * t - 0.10, sin(_lauf_phase - 2.0) * 0.35 * t, 0.0)
		ohr_neigung = OHR_RUHE + nachlauf * 0.26 * t
		wippen = absf(schwung) * 0.05 * t
	else:
		# Ruhig stehen: nur leichtes Kopfnicken
		z_kopf = Vector3(sin(_zeit * 1.6) * 0.05, sin(_zeit * 0.7) * 0.10, 0.0)
		z_schweif = Vector3(-0.15 + sin(_zeit * 1.3) * 0.06, sin(_zeit * 0.9) * 0.12, 0.0)
		z_spitze = Vector3(-0.10, sin(_zeit * 0.9 - 0.7) * 0.16, 0.0)

	# Spin sticht durch: Arme waagerecht ausgestreckt
	if spin:
		z_arm_r = Vector3(0.0, 0.0, ARM_SPIN)
		z_arm_l = Vector3(0.0, 0.0, -ARM_SPIN)
		ohr_neigung = maxf(ohr_neigung, 0.35)

	# --- Weich anfahren; Ohren und Schweif langsamer => sie federn nach ---
	_folge(_bein_rechts, z_bein_r, 16.0, delta)
	_folge(_bein_links, z_bein_l, 16.0, delta)
	_folge(_arm_rechts, z_arm_r, 15.0, delta)
	_folge(_arm_links, z_arm_l, 15.0, delta)
	_folge(_kopf, z_kopf, 10.0, delta)
	_folge(_schweif, z_schweif, 7.0, delta)
	_folge(_schweif_spitze, z_spitze, 5.5, delta)
	_folge(_koerper, z_rumpf, 12.0, delta)

	_bewege_ohren(ohr_neigung, delta, ruhig)

	# --- Rumpf: Wippen beim Laufen, Atmen im Stand ---
	_koerper.position.y += wippen
	_atem = lerpf(_atem, 1.0 if ruhig else 0.0, clampf(delta * 4.0, 0.0, 1.0))
	var atem := sin(_zeit * 2.2) * 0.03 * _atem
	_koerper.scale.y *= 1.0 + atem
	_koerper.scale.x = 1.0 - atem * 0.5
	_koerper.scale.z = 1.0 - atem * 0.5


## Ohren: gemeinsame Neigung plus gelegentliches Zucken im Stand.
func _bewege_ohren(neigung: float, delta: float, ruhig: bool) -> void:
	if not is_instance_valid(_ohr_rechts) or not is_instance_valid(_ohr_links):
		return

	if ruhig:
		_zuck_pause -= delta
		if _zuck_pause <= 0.0:
			_zuck_pause = randf_range(2.5, 5.5)
			_zuck = 0.35
	_zuck = maxf(_zuck - delta, 0.0)
	var zucken := sin(_zuck * 46.0) * 0.30 * (_zuck / 0.35)

	var faktor := clampf(delta * 9.0, 0.0, 1.0)
	_ohr_rechts.rotation.x = lerpf(_ohr_rechts.rotation.x, neigung, faktor)
	_ohr_links.rotation.x = lerpf(_ohr_links.rotation.x, neigung, faktor)
	_ohr_rechts.rotation.z = -OHR_SPREIZUNG - zucken
	_ohr_links.rotation.z = OHR_SPREIZUNG + zucken


## Fährt die Drehung eines Gelenks weich auf den Zielwinkel zu.
func _folge(knoten: Node3D, ziel: Vector3, geschwindigkeit: float, delta: float) -> void:
	if not is_instance_valid(knoten):
		return
	knoten.rotation = knoten.rotation.lerp(ziel, clampf(geschwindigkeit * delta, 0.0, 1.0))
