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
	_baue()


# ---------------------------------------------------------------- Aufbau

## Baut den kompletten Beuteldachs aus Primitiven auf.
func _baue() -> void:
	_teile = Node3D.new()
	_teile.name = "Teile"
	add_child(_teile)

	var fell := Materialbibliothek.fell()
	var bauchfell := Materialbibliothek.fell(Farben.FELL_BAUCH)
	var dunkelfell := Materialbibliothek.fell(Farben.FELL_DUNKEL)
	var nasenfarbe := Materialbibliothek.einfarbig(Farben.NASE, 0.35)
	var augapfel := Materialbibliothek.einfarbig(Color(0.97, 0.97, 0.93), 0.25)

	# --- Rumpf: trägt als Wurzel alle übrigen Teile ---
	_koerper = MeshInstance3D.new()
	_koerper.name = "Koerper"
	_koerper.mesh = _kapsel(0.30, 0.88)
	_koerper.material_override = fell
	_koerper.position.y = RUMPF_Y
	_teile.add_child(_koerper)

	# Hellerer Bauch, leicht abgeflacht und nach vorn (-Z) versetzt
	var bauch := _netz(_koerper, "Bauch", _kugel(0.24), bauchfell,
			Vector3(0.0, -0.06, -0.16))
	bauch.scale = Vector3(1.0, 1.15, 0.78)

	_baue_kopf(fell, bauchfell, dunkelfell, nasenfarbe, augapfel)
	_baue_arme(fell, bauchfell)
	_baue_beine(fell, bauchfell)
	_baue_schweif(fell, dunkelfell)

	# --- Spin-Ring (Geschwister des Rumpfes, wird nicht mitgestaucht) ---
	var ring := TorusMesh.new()
	ring.inner_radius = 0.77
	ring.outer_radius = 0.93
	_spin_ring = MeshInstance3D.new()
	_spin_ring.name = "SpinRing"
	_spin_ring.mesh = ring
	_spin_ring.position.y = 0.6
	_spin_ring.material_override = Materialbibliothek.transparent(Farben.SPIN_RING, 1.4).duplicate()
	_teile.add_child(_spin_ring)


## Kopf mit spitzer Schnauze, Nase, Augen und aufgestellten Ohren.
func _baue_kopf(fell: Material, bauchfell: Material, dunkelfell: Material,
		nasenfarbe: Material, augapfel: Material) -> void:
	_kopf = _gelenk(_koerper, "Kopf", Vector3(0.0, 0.42, -0.02))

	var schaedel := _netz(_kopf, "Schaedel", _kugel(0.24), fell)
	schaedel.scale = Vector3(1.06, 1.0, 1.10)

	# Spitze Schnauze: Kegel, der nach -Z zeigt
	var schnauze := _netz(_kopf, "Schnauze", _kegel(0.16, 0.035, 0.32), fell,
			Vector3(0.0, -0.05, -0.20))
	schnauze.rotation.x = -PI * 0.5

	# Helle Unterseite der Schnauze
	var kinn := _netz(_kopf, "Kinn", _kugel(0.11), bauchfell,
			Vector3(0.0, -0.10, -0.17))
	kinn.scale = Vector3(0.85, 0.55, 1.25)

	_netz(_kopf, "Nase", _kugel(0.058), nasenfarbe, Vector3(0.0, -0.045, -0.365))

	# Augen mit Pupillen
	for seite in [-1.0, 1.0]:
		var name_teil := "Auge%s" % ("R" if seite > 0.0 else "L")
		var auge := _netz(_kopf, name_teil, _kugel(0.072), augapfel,
				Vector3(0.115 * seite, 0.075, -0.175))
		_netz(auge, "Pupille", _kugel(0.036), nasenfarbe, Vector3(0.0, 0.0, -0.052))

	# Aufgestellte Ohren – Dreiecksprismen auf eigenen Gelenken
	_ohr_rechts = _baue_ohr(1.0, fell, dunkelfell)
	_ohr_links = _baue_ohr(-1.0, fell, dunkelfell)


## Ein Ohr; seite = +1 rechts (+X), -1 links (-X).
func _baue_ohr(seite: float, fell: Material, dunkelfell: Material) -> Node3D:
	var gelenk := _gelenk(_kopf, "Ohr%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.135 * seite, 0.11, 0.03))
	gelenk.rotation = Vector3(OHR_RUHE, 0.0, -OHR_SPREIZUNG * seite)

	var muschel := PrismMesh.new()
	muschel.size = Vector3(0.15, 0.18, 0.07)
	_netz(gelenk, "Muschel", muschel, fell, Vector3(0.0, 0.10, 0.0))

	var innen := PrismMesh.new()
	innen.size = Vector3(0.085, 0.11, 0.02)
	_netz(gelenk, "Innenohr", innen, dunkelfell, Vector3(0.0, 0.085, -0.042))
	return gelenk


## Beide Arme mit Händen.
func _baue_arme(fell: Material, bauchfell: Material) -> void:
	_arm_rechts = _baue_arm(1.0, fell, bauchfell)
	_arm_links = _baue_arm(-1.0, fell, bauchfell)


func _baue_arm(seite: float, fell: Material, bauchfell: Material) -> Node3D:
	var gelenk := _gelenk(_koerper, "Arm%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.28 * seite, 0.22, 0.0))
	_netz(gelenk, "Schulter", _kugel(0.095), fell)
	_netz(gelenk, "Oberarm", _kapsel(0.075, 0.30), fell, Vector3(0.0, -0.17, 0.0))
	var hand := _netz(gelenk, "Hand", _kugel(0.09), bauchfell, Vector3(0.0, -0.35, 0.0))
	hand.scale = Vector3(0.9, 1.0, 1.15)
	return gelenk


## Beide Beine mit Füßen.
func _baue_beine(fell: Material, bauchfell: Material) -> void:
	_bein_rechts = _baue_bein(1.0, fell, bauchfell)
	_bein_links = _baue_bein(-1.0, fell, bauchfell)


func _baue_bein(seite: float, fell: Material, bauchfell: Material) -> Node3D:
	var gelenk := _gelenk(_koerper, "Bein%s" % ("R" if seite > 0.0 else "L"),
			Vector3(0.15 * seite, -0.30, 0.0))
	_netz(gelenk, "Schenkel", _kapsel(0.10, 0.32), fell, Vector3(0.0, -0.14, 0.0))

	var fuss := BoxMesh.new()
	fuss.size = Vector3(0.18, 0.10, 0.30)
	_netz(gelenk, "Fuss", fuss, bauchfell, Vector3(0.0, -0.345, -0.07))
	return gelenk


## Buschiger Schweif aus mehreren Kugeln auf zwei Gelenken.
func _baue_schweif(fell: Material, dunkelfell: Material) -> void:
	_schweif = _gelenk(_koerper, "Schweif", Vector3(0.0, -0.16, 0.22))
	var wurzel := _netz(_schweif, "Wurzel", _kugel(0.135), fell, Vector3(0.0, 0.03, 0.05))
	wurzel.scale = Vector3(0.95, 1.0, 1.1)

	_schweif_spitze = _gelenk(_schweif, "Spitze", Vector3(0.0, 0.13, 0.13))
	_netz(_schweif_spitze, "Busch", _kugel(0.11), fell, Vector3(0.0, 0.02, 0.03))
	_netz(_schweif_spitze, "Zipfel", _kugel(0.08), dunkelfell, Vector3(0.0, 0.09, 0.10))


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
func aktualisiere(delta: float, tempo: float, luft: bool, slide: float, spin: float) -> void:
	# Blickrichtung bzw. Spin-Drehung
	if spin > 0.0:
		rotation.y += delta * SPIN_DREHUNG
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
	_animiere(delta, tempo, luft, slide > 0.0, spin > 0.0)


func setze_blick(winkel: float) -> void:
	_blick = winkel


func sichtbarkeit(sichtbar: bool) -> void:
	visible = sichtbar


# ---------------------------------------------------------------- Animation

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
