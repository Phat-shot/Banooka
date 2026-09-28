extends Gegner
class_name Stelzenspinne
## Große Spinne, die breitbeinig über dem Weg steht.
##
## NUR durch den Slide (oder den Bauchplatscher) zu besiegen: Man rutscht
## zwischen ihren Beinen hindurch und fegt sie ihr weg. Draufspringen geht
## NICHT – der Rücken trägt Stacheln, wer dort landet, nimmt Schaden.
##
## Die Silhouette ist die Spielanleitung: hoher Leib auf langen Beinen,
## darunter eine deutliche Lücke. Genau deshalb steht hier eine Spinne und
## kein gedrungenes Tier – wo keine Lücke zu sehen ist, kommt niemand auf
## die Idee, hindurchzurutschen.
##
## Bewegung: stakst langsam seitlich hin und her und stößt gelegentlich mit
## dem Vorderleib nach unten zu.

const STOSS_DAUER := 0.9         ## Wie lange ein Zustoßen dauert
const STOSS_ABSTAND_MIN := 2.5   ## Kürzeste Pause zwischen zwei Stößen
const STOSS_ABSTAND_MAX := 4.5   ## Längste Pause zwischen zwei Stößen
const HUEFT_HOEHE := 1.05        ## Höhe des Beinansatzes über dem Boden
const RUMPF_Y := 1.30            ## Hinterleib
const VORDERLEIB_Y := 1.24       ## Vorderleib mit Augen, stößt nach unten
const BEINE := 8

# ---------------------------------------------------------- Farben
#
# Die Spinne steht in mehr Leveln als in dem Wald, für den sie gebaut
# wurde. Damit ein Level sie in seine eigene Palette holen kann, ohne
# dass ein zweiter Gegner entstehen muss, sind ihre Flächen einzeln
# einstellbar. Vorgabe ist überall der bisherige Ton: Wer nichts setzt,
# sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Der Stachelkamm auf dem Rücken sagt
# "hier nicht landen", die Lücke zwischen den Beinen sagt "hier durch".
# Der Kamm muss deshalb HELL gegen den Leib stehen bleiben, und die Beine
# müssen sich vom Leib absetzen – sonst verschwindet die Lücke und mit
# ihr die Anleitung.

## Hinterleib und Vorderleib – die dunkle Grundfläche.
@export var farbe_leib: Color = Farben.FELS_DUNKEL.darkened(0.45):
	set(wert):
		farbe_leib = wert
		_neu_faerben()
## Beine und Kieferklauen. Heller als der Leib, damit die Lücke zu sehen ist.
@export var farbe_beine: Color = Farben.FELS_DUNKEL.darkened(0.2):
	set(wert):
		farbe_beine = wert
		_neu_faerben()
## Stachelkamm auf dem Rücken – die Warnung vor dem Draufspringen.
@export var farbe_stacheln: Color = Farben.WARNUNG:
	set(wert):
		farbe_stacheln = wert
		_neu_faerben()
## Haupt- und Nebenaugen.
@export var farbe_augen: Color = Color(0.95, 0.15, 0.12):
	set(wert):
		farbe_augen = wert
		_neu_faerben()
## Leibfarbe der mitgelieferten Spinnenfigur.
##
## Eigener Wert und nicht `farbe_leib`: Das fremde Modell bringt seinen
## eigenen, fast schwarzen Ton mit, und die Vorgabe ist genau dieser Ton –
## so sieht die Spinne aus wie bisher, solange niemand sie umfärbt. Wer
## sie in eine andere Palette holt, setzt beide.
@export var farbe_fremdmodell: Color = Color(0.225949, 0.225949, 0.225949):
	set(wert):
		farbe_fremdmodell = wert
		_neu_faerben()


var _stoss_zeit := 0.0
var _stoss_laeuft := 0.0

var _rumpf: MeshInstance3D
var _vorderleib: Node3D
var _beine: Array[Node3D] = []

## Wie sie stirbt: vom Slide weggefegt oder vom Bauchplatscher platt.
var _platt := false
var _fegen := Vector3.ZERO

## Stachelkamm des Modells, einmal gebaut (Farbe steckt im Material).
static var _kamm: ArrayMesh = null


func _init() -> void:
	# Nur der Slide fegt ihr die Beine weg.
	besiegbar_durch = Angriff.SLIDE | Angriff.SLAM
	patrouille_weite = 3.5
	tempo = 1.3


func _ready() -> void:
	super._ready()
	_stoss_zeit = randf_range(STOSS_ABSTAND_MIN, STOSS_ABSTAND_MAX)


## Mitgeliefertes Modell für diesen Gegner.
## Spinne von Quaternius. Eingepasst wird hier nach der HÖHE und nicht nach
## der größten Achse: Das Modell ist breit und flach, auf die Beinspanne
## eingepasst stünde es zu tief über dem Boden – und dann fehlt die Lücke,
## durch die man rutschen soll.
##
## Die Augen ("Material.001") leuchten in `farbe_augen` wie bei der eigenen
## Optik; stumpf rot gingen sie im Waldschatten unter. Der Leib bekommt
## etwas Chitinglanz, damit der dunkle Körper Form zeigt.
func fremdmodell() -> Dictionary:
	return {"datei": "spinne", "groesse": 1.30, "nach_hoehe": true,
			"drehung": PI, "farben": {"Material": farbe_fremdmodell},
			"stoff": {
				"Material": {"rauheit": 0.6, "glanz": 0.25},
				"Material.001": {"farbe": farbe_augen, "leuchten": 1.6},
			}}


## Der rote Stachelkamm der eigenen Optik, auf den Hinterleib des Modells
## gesetzt: "hier nicht landen" (ZEICHENSPRACHE in gegner.gd). Er hängt
## am Knochen "Abdomen" und geht mit jedem Clip mit.
##
## Die vier Kegel stecken in EINEM Netz (ein Draw-Call statt vier). Gebaut
## im Netzraum der Spinne: x quer, y längs (positiv = hinten), z oben; der
## Rücken des Hinterleibs liegt bei y 0,012 bis 0,024 um z 0,016.
func _zeichen_am_fremdmodell(figur: Node3D) -> void:
	if _kamm == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var ein_meter := 1.0 / NETZ_JE_METER
		for stachel: Vector4 in KAMM:
			var kegel := CylinderMesh.new()
			kegel.top_radius = 0.0
			kegel.bottom_radius = 0.055
			kegel.height = stachel.w
			kegel.radial_segments = 6
			kegel.rings = 1
			# Kegelachse (Y) auf die Netz-Senkrechte (Z) kippen, nach hinten
			# geneigt wie die Rundung des Leibs; Fuß leicht eingesenkt.
			var neigung := deg_to_rad(90.0 - stachel.z)
			var lage := Basis(Vector3.RIGHT, neigung).scaled(Vector3.ONE * ein_meter)
			var achse := lage * Vector3.UP
			var fuss := Vector3(0.0, stachel.x, stachel.y)
			st.append_from(kegel, 0, Transform3D(lage,
					fuss + achse * (stachel.w * 0.35)))
		_kamm = st.commit()
	var kamm := MeshInstance3D.new()
	kamm.name = "Stachelkamm"
	kamm.mesh = _kamm
	kamm.material_override = Materialbibliothek.leuchtend(farbe_stacheln, 0.9)
	kamm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kamm.set_meta("ohne_glanz", true)
	_an_knochen(figur, "Abdomen", kamm, Transform3D.IDENTITY)


## Netzeinheiten je Meter im Spiel: Die Spinne ist 1,30 m hoch, ihr Netz
## 0,0195 Einheiten; dazu die Skalierung 100 des Armature-Knotens.
const NETZ_JE_METER := 1.30 / (0.019492 * 100.0) * 100.0
## Stacheln im Netzraum: y, z des Fußpunkts, Neigung nach hinten (Grad),
## Länge (Meter). Der mittlere ist der längste, wie bei der eigenen Optik.
const KAMM: Array[Vector4] = [
	Vector4(0.0115, 0.0158, 8.0, 0.22),
	Vector4(0.0152, 0.0166, 16.0, 0.27),
	Vector4(0.0190, 0.0166, 26.0, 0.25),
	Vector4(0.0222, 0.0154, 40.0, 0.20),
]


func _trefferfarbe() -> Color:
	return farbe_stacheln


# ---------------------------------------------------------- Optik

## Selbstgebaute Ausweichoptik, wenn kein Modell da ist: dunkler Leib,
## acht helle Beine, roter Stachelkamm auf dem Rücken. Der Kamm sagt
## unmissverständlich "hier nicht landen".
func _baue() -> void:
	var panzer := Materialbibliothek.fell(farbe_leib)
	var gelenk := Materialbibliothek.einfarbig(farbe_beine, 0.6)
	var stachel_mat := Materialbibliothek.leuchtend(farbe_stacheln, 0.9)
	var augapfel := Materialbibliothek.leuchtend(farbe_augen, 1.2)

	# Acht Beine, gleichmäßig um den Leib verteilt
	for i in BEINE:
		var seite := -1.0 if i < BEINE / 2 else 1.0
		var reihe := float(i % (BEINE / 2)) - 1.5
		var bein := Node3D.new()
		bein.name = "Bein%d" % i
		bein.position = Vector3(seite * 0.22, HUEFT_HOEHE, reihe * 0.20)
		modell.add_child(bein)
		# Oberschenkel schräg nach außen, Unterschenkel senkrecht nach unten
		_teil(bein, _zylinder(0.055, 0.045, 0.62, 6), gelenk,
				Vector3(seite * 0.26, 0.06, reihe * 0.10),
				Vector3(0.0, 0.0, deg_to_rad(-38.0 * seite)), Vector3.ONE, "Schenkel")
		_teil(bein, _zylinder(0.045, 0.03, HUEFT_HOEHE, 6), gelenk,
				Vector3(seite * 0.5, -HUEFT_HOEHE * 0.5 + 0.1, reihe * 0.18),
				Vector3.ZERO, Vector3.ONE, "Unterschenkel")
		_beine.append(bein)

	# Hinterleib: der dicke, hohe Teil – aus der Spielkamera die Silhouette
	_rumpf = _teil(modell, _kugel(0.34, 12, 9), panzer,
			Vector3(0.0, RUMPF_Y, 0.30), Vector3.ZERO,
			Vector3(1.0, 0.86, 1.25), "Hinterleib")

	# Stachelkamm auf dem Rücken: "hier nicht landen"
	for i in 4:
		var laenge := 0.26 - absf(float(i) - 1.5) * 0.05
		_teil(_rumpf, _zylinder(0.05, 0.0, laenge, 6), stachel_mat,
				Vector3(0.0, 0.30, 0.22 - float(i) * 0.16), Vector3.ZERO,
				Vector3.ONE, "Stachel%d" % i)

	# Vorderleib mit den Augen – der Teil, der beim Zustoßen nach unten geht
	_vorderleib = Node3D.new()
	_vorderleib.name = "Vorderleib"
	_vorderleib.position = Vector3(0.0, VORDERLEIB_Y, -0.24)
	modell.add_child(_vorderleib)
	_teil(_vorderleib, _kugel(0.24, 10, 8), panzer, Vector3.ZERO,
			Vector3.ZERO, Vector3(1.0, 0.8, 1.1), "Kopf")
	for seite: float in [-1.0, 1.0]:
		_teil(_vorderleib, _kugel(0.055, 7, 5), augapfel,
				Vector3(0.09 * seite, 0.06, -0.20), Vector3.ZERO, Vector3.ONE, "Auge")
		_teil(_vorderleib, _kugel(0.035, 6, 5), augapfel,
				Vector3(0.16 * seite, 0.01, -0.16), Vector3.ZERO, Vector3.ONE, "Nebenauge")
		# Kieferklauen
		_teil(_vorderleib, _zylinder(0.045, 0.0, 0.2, 6), gelenk,
				Vector3(0.07 * seite, -0.14, -0.20),
				Vector3(deg_to_rad(38.0), 0.0, 0.0), Vector3.ONE, "Klaue")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_stoss_zeit -= delta
	if _stoss_zeit <= 0.0 and _stoss_laeuft <= 0.0:
		_stoss_laeuft = STOSS_DAUER
		_stoss_zeit = randf_range(STOSS_ABSTAND_MIN, STOSS_ABSTAND_MAX)

	if _stoss_laeuft > 0.0:
		# Beim Zustoßen bleibt sie stehen
		_stoss_laeuft = maxf(_stoss_laeuft - delta, 0.0)
		_clip("attack", 0.08, CLIP_STOSS / STOSS_DAUER)
	else:
		_phase += delta * tempo * 3.2
		_patrouille_schritt(tempo * delta)
		# Schritttakt an das Tempo gebunden, damit die Füße nicht rutschen.
		_clip("walk", 0.15, tempo / CLIP_LAUFTEMPO, true)

	_blick_ausrichten(delta, 3.5)
	_animiere(delta)


## Länge des Clips "Spider_Attack" in Sekunden.
const CLIP_STOSS := 0.75
## Bei diesem Tempo (m/s) setzen die Füße des Laufclips ohne Rutschen auf.
## Gemessen an "Spider_Walk": Ein Fuß wandert in 0,42 s Standphase
## 0,014 Einheiten nach hinten, bei 66,7 m je Einheit also 2,2 m/s.
const CLIP_LAUFTEMPO := 2.2


## Staksende Schritte, wippender Hinterleib, Zustoßen mit dem Vorderleib.
func _animiere(_delta: float) -> void:
	var laeuft := _stoss_laeuft <= 0.0

	for i in _beine.size():
		var bein := _beine[i]
		if not is_instance_valid(bein):
			continue
		var versatz := PI * float(i)
		var schwung := sin(_phase + versatz) if laeuft else 0.0
		bein.rotation.x = schwung * 0.45
		# Beim Vorschwingen wird das Bein leicht angehoben
		bein.position.y = HUEFT_HOEHE + maxf(schwung, 0.0) * 0.06

	if is_instance_valid(_rumpf):
		_rumpf.position.y = RUMPF_Y + (absf(sin(_phase)) * 0.05 if laeuft else 0.0)

	if is_instance_valid(_vorderleib):
		# Pickbogen: Kopf schnellt nach unten und wieder hoch
		var stoss := 0.0
		if _stoss_laeuft > 0.0:
			stoss = sin((1.0 - _stoss_laeuft / STOSS_DAUER) * PI)
		_vorderleib.rotation.x = stoss * 0.9
		_vorderleib.position.y = VORDERLEIB_Y - stoss * 0.42



# ---------------------------------------------------------- Tod

func _todesstart(art: int) -> void:
	# Die Beine sind weg – sie fliegt nicht, sie kippt um.
	_wegflug = Vector3.ZERO
	_platt = (art & Angriff.SLIDE) == 0 and (art & Angriff.SLAM) != 0
	# Der Slide fegt sie in SEINE Richtung davon, nicht vom Spieler weg:
	# Wer unter ihr durchrutscht, steht beim Treffer fast unter dem Leib,
	# und die Richtung "vom Spieler weg" zeigte dann irgendwohin.
	_fegen = Vector3.ZERO
	var spieler := get_tree().get_first_node_in_group("spieler") as CharacterBody3D
	if not _platt and spieler != null:
		var flach := Vector3(spieler.velocity.x, 0.0, spieler.velocity.z)
		if flach.length() > 0.5:
			_fegen = flach.normalized() * FEGEN_TEMPO
	if _fegen != Vector3.ZERO:
		Effekte.staubwolke(self, global_position, 0.8)
	# Spider_Death dauert 1,04 s – etwas schneller, damit sie liegt, bevor
	# sie verpufft.
	if _clip("death", 0.05, 1.2):
		_koerper_null = _koerperhoehe()


## Tempo, mit dem die Spinne weggefegt wird (m/s, klingt schnell ab).
const FEGEN_TEMPO := 3.0


func _todesanimation(delta: float) -> void:
	if not is_instance_valid(modell):
		return
	# Der Todesclip wirft die Spinne erst gut einen Meter hoch, bevor sie
	# auf den Rücken fällt. Weggefegte Beine tragen aber nichts mehr: Der
	# Anstieg wird herausgerechnet, sie sackt gleich zusammen.
	_koerper_halten("death")
	if _fegen != Vector3.ZERO:
		global_position += _fegen * delta
		_fegen = _fegen.lerp(Vector3.ZERO, minf(delta * 5.0, 1.0))
	if _platt:
		modell.scale = modell.scale.lerp(Vector3(1.3, 0.25, 1.3), minf(delta * 10.0, 1.0))
		return
	# Beine knicken weg, die ganze Spinne kippt zur Seite. Mit Modell nur
	# ein wenig: Dessen Todesclip rollt die Beine selbst ein, und ganz auf
	# die Seite gelegt sähe man davon nichts.
	var kippen := PI * (0.2 if fremdhalter != null else 0.55)
	modell.rotation.z = lerp_angle(modell.rotation.z, kippen, minf(delta * 7.0, 1.0))
	modell.scale = modell.scale.lerp(Vector3(0.9, 0.75, 0.9), minf(delta * 4.0, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = lerp_angle(bein.rotation.x, 1.4, minf(delta * 8.0, 1.0))


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Spinne erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Eine besiegte Spinne wird nicht angefasst: Ihre Todesanimation steckt
## in Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_beine.clear()
	_rumpf = null
	_vorderleib = null
	_baue()
	_fremdmodell_setzen()
