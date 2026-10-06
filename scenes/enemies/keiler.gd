extends Node3D
class_name Keiler
## Riesenkeiler – der Verfolger aus Level 05 (Entwurf L05 §8.4, §9.3).
##
## Kein `Gegner`: Er patrouilliert nicht und lässt sich nicht besiegen. Wo
## er steht und wann er fängt, rechnet `L05Jagd` als Abstand auf dem
## Verlauf; dieses Skript ist nur sein Körper – Haltung, Gang und die
## Effekte, die ihn begleiten. Blickrichtung −Z, Ursprung am Boden unter der
## Mitte des Leibs (dort setzt die Jagd ihn auf `boden_bei`).
##
## SIEBEN GLIEDER (Entwurf §9.3, §10: „33 → 7 Netze"). Vorher bestand er aus
## 33 Netzen (Kugeln, Kegel, Kapseln je Teil, ein Stoff je Farbe), jedes ein
## Zeichenaufruf und je Schattenstufe einer mehr. Jetzt sind es sieben:
##   Rumpf   Leib mit Buckel, Borstenmähne und Schwanz
##   Kopf    Keil mit Wurfscheibe, Ohren und Hauern
##   Augen   beide Augen, eigener Stoff (Glut nach `naehe`)
##   Beine   vier, je eines (sie schwingen einzeln um die Hüfte)
## Die Farben stehen als SCHEITELFARBEN im Netz (dunkles Fell, angegraute
## Mähne, helle Borstenspitzen, elfenbeinfarbene Hauer, Wurfscheibe, Hufe):
## Rumpf, Kopf und Beine teilen EINEN Stoff, eine Kopie des Fells der
## Bibliothek mit `vertex_color_use_as_albedo` (geteilte Stoffe werden nur
## als `duplicate()` geändert, Entwurf §1 Nr. 24). Schatten werfen nur
## Rumpf und Kopf – die Beine trügen je Schattenstufe vier Aufrufe bei, und
## die Sonne steht hinter der Kamera: Ihr Schatten fällt hangauf, hinter den
## Keiler, wo man ihn nicht sieht.
## Gemessen (Level 05, Messtore 8–296, mit gegen ohne Keiler, samt
## Staubfahne und Atemdampf): Rechner 8–16 Zeichenaufrufe (s 218: 14),
## Handy 8–14; vorher kostete er an denselben Stellen 66–90 (Paket P1a).
##
## HALTUNGEN (gerufen von `L05Jagd`, siehe dort „HALTUNGEN"):
##   schlafen()          liegt in der Suhle, die Schnauze zum Weg, atmet
##   erwachen()          springt in ERWACHEN Sekunden auf und dreht sich um –
##                       im Lauf, denn die Jagd rennt im selben Bild los
##   aufstehen()         sofort wach, ohne Aufspringen (Versetzen)
##   in_luft(an)         Hopser: Vorderbeine vor, Hinterbeine zurück
##   hangneigung(w)      kippt den Leib (Radiant, positiv bergab = Nase tief)
##   schnauben()         am Ufer: schlittert, steht, schnaubt, scharrt
##   durchbrechen(ort, wasser)  Kopfstoß, Splitter, am Fluderjoch Wasser
## Gehen ergibt sich aus `aktualisiere(delta, tempo, naehe)` (jedes
## Physikbild, solange er nicht schläft); `naehe` senkt den Schädel und
## lässt die Augen glühen.
##
## SCHLAFPLATZ. Die Jagd stellt ihn auf SCHLAF_S / SCHLAF_Q (s 16, q −4,5).
## Liegend dreht sich der Leib um und liegt um SCHLAF_VERSATZ hangauf: die
## Schnauze zur Eichelspur (Entwurf §5 A), das Hinterteil 0,8 m vor dem
## Wildgatter Ü (17,0). Stehend steckte er mit dem Kopf durch das Gatter
## (gesehen in P1a/P4). Beim Erwachen gleitet der Leib aus dieser Lage in
## die Laufhaltung, auch wenn die Jagd den Knoten im selben Bild auf die
## Fluchtlinie stellt (`_weck_lage`): Er dreht sich im Aufspringen um.
##
## TAKT. Alles bewegt sich in `_physics_process` (Physikinterpolation, die
## Glattprobe): Die Jagd ruft `aktualisiere` in ihrem Physikschritt, dieser
## Knoten rechnet danach (`process_physics_priority`) die Haltung. Ruft
## niemand `aktualisiere` in diesem Physikbild (Schlaf, Ruhe der Proben),
## steht er: Tempo 0, kein Gang, keine Staubfahne, am Ufer schnaubt er.
## Atem, Erwachen und Schnauben laufen weiter. WARUM: Sonst blieb das Tempo
## der letzten Haltung stehen (nach `aufstehen` 1) – in der Ruhe der Proben
## stand er mitten im Sprung, und die Staubfahne lief.
##
## EFFEKTE (Entwurf §8.4), alle über `Effekte` und dort gedeckelt:
##   Staubfahne   golden, hinter ihm, solange er läuft (`dauerstaub`)
##   Atemdampf    Wölkchen an der Wurfscheibe: im Schlaf je Atemzug, im
##                Lauf im Galopptakt, am Ufer als Schnauben
##   Staubpuff    beim Abspringen und Landen eines Hopsers, beim Aufspringen
##                und beim Schlittern am Ufer
##   Splitter     Bretter im Kistenholz (vorgewärmt, `Effekte.vorwaermen`)
##   Wasserschwall  Tropfen und Gischt aus dem Gerinne (D3/D4), beide im
##                Stoff ALPHA (`Effekte.rauch`): Funken (additiv) leuchteten
##                im Schatten wie Glut statt wie Wasser

## Sprünge je Sekunde im vollen Galopp. 7,4 m/s bei gut 3,3 m je Sprung.
const TAKT := 2.2
## So lange dauert das Aufspringen (Entwurf §9.3: 0,5 s im Lauf).
const ERWACHEN := 0.5
## Lage des liegenden Leibs relativ zum Knoten: Versatz (x quer, y, z
## zurück = hangauf) und Drehung um die Hochachse (PI = mit der Schnauze
## zum Start, 0,5 zur Wegmitte hin).
const SCHLAF_VERSATZ := Vector3(0.25, -0.82, 2.0)
const SCHLAF_DREHUNG := PI + 0.5
const SCHLAF_ROLLEN := 0.1
## Atemzüge im Schlaf (rad/s) und Abstand der Wölkchen im Lauf (s).
const ATEM_SCHLAF := 1.6
const ATEM_LAUF := 0.85
## Schnauben am Ufer: alle so viele Sekunden ein Stoß.
const SCHNAUB_TAKT := 1.6
## Abstand der Atemwölkchen nach vorn, ab der Wurfscheibe (m).
const ATEM_VOR := 0.12
## Augen: Glut ohne und mit voller Nähe (Emissionsstärke).
const GLUT := Vector2(0.5, 1.5)

## Farben (linear, Faktoren auf die Felltextur).
const FELL := Color(0.11, 0.085, 0.068)
const BAUCH := Color(0.065, 0.05, 0.042)
const RUECKEN := Color(0.2, 0.158, 0.118)
const BORSTE := Color(0.33, 0.26, 0.19)
const SCHEIBE := Color(0.24, 0.15, 0.13)
const HAUER := Color(0.86, 0.8, 0.65)
const HAUER_WURZEL := Color(0.5, 0.44, 0.34)
const HUF := Color(0.042, 0.037, 0.033)
const AUGE := Color(1.0, 0.36, 0.1)
## Staub der Fahne und der Puffs: golden im Abendlicht (Entwurf §8.4).
const GOLDSTAUB := Color(0.96, 0.76, 0.46, 0.85)
const DAMPF := Color(0.9, 0.93, 1.0, 0.42)
## Gischt und Tropfen im Schatten des Tobels: gedämpft, nicht leuchtend.
const GISCHT := Color(0.88, 0.94, 1.0, 0.7)
const TROPFEN := Color(0.58, 0.68, 0.76, 0.95)

## Leib: Stationen [z, Oberkante, Unterkante, halbe Breite, Mähne] (m, Raum
## des Körpers, Boden auf 0). Buckel über den Vorderbeinen, abfallender
## Rücken, schmale Kruppe – die Silhouette eines Keilers, auch von vorn.
const RUMPF := [
	[-1.95, 1.95, 1.15, 0.42, 0.05], [-1.6, 2.32, 0.92, 0.62, 0.2],
	[-1.15, 2.52, 0.78, 0.78, 0.3], [-0.6, 2.47, 0.74, 0.84, 0.26],
	[0.0, 2.32, 0.78, 0.84, 0.16], [0.6, 2.16, 0.86, 0.79, 0.06],
	[1.1, 2.04, 0.94, 0.72, 0.0], [1.5, 1.94, 1.04, 0.62, 0.0],
	[1.8, 1.78, 1.16, 0.46, 0.0], [2.0, 1.56, 1.28, 0.24, 0.0],
	[2.07, 1.42, 1.38, 0.05, 0.0],
]
## Der Rumpf hängt an diesem Punkt (atmet um ihn).
const RUMPF_MITTE := Vector3(0.0, 1.6, 0.0)
## Kopf: Gelenk am Hals und Stationen [Mitte x, y, z, halbe Breite, oben,
## unten] im Raum des Gelenks – vom Nacken bis zur Wurfscheibe.
const KOPF_GELENK := Vector3(0.0, 1.72, -1.62)
## Hohe Stirn und breite Backen hinter den Augen, davor ein schmaler Keil
## (gerade gezogen las er sich als Rohr), vorn die Scheibe leicht gewulstet.
const KOPF := [
	[0.0, 0.02, 0.15, 0.5, 0.42, 0.5], [0.0, 0.04, -0.25, 0.56, 0.46, 0.52],
	[0.0, -0.06, -0.6, 0.46, 0.4, 0.42], [0.0, -0.25, -0.92, 0.3, 0.27, 0.3],
	[0.0, -0.42, -1.22, 0.22, 0.2, 0.21], [0.0, -0.5, -1.42, 0.2, 0.185, 0.185],
	[0.0, -0.51, -1.47, 0.215, 0.19, 0.18],
]
## Wurfscheibe (Nase) und Augen im Raum des Gelenks. Die Augen sitzen knapp
## vor der Haut (dort ist der Kopf 0,395 m breit): weiter innen lagen sie im
## Kopf und glühten unsichtbar.
const NASE := Vector3(0.0, -0.51, -1.49)
const AUGE_ORT := Vector3(0.37, 0.18, -0.62)
## Hüften (Raum des Körpers) und Beinstationen [y, z, Radius] darunter.
const HUEFTEN: Array[Vector3] = [Vector3(-0.46, 1.32, -1.1), Vector3(0.46, 1.32, -1.1),
		Vector3(-0.44, 1.38, 1.2), Vector3(0.44, 1.38, 1.2)]
const BEIN_VORN := [[0.15, 0.0, 0.3], [-0.35, 0.03, 0.24], [-0.7, 0.02, 0.14],
		[-1.0, 0.0, 0.1], [-1.18, -0.03, 0.09], [-1.24, -0.06, 0.11], [-1.32, -0.08, 0.1]]
const BEIN_HINTEN := [[0.15, 0.0, 0.33], [-0.35, 0.08, 0.26], [-0.7, 0.18, 0.13],
		[-1.0, 0.08, 0.1], [-1.24, -0.02, 0.09], [-1.3, -0.05, 0.11], [-1.38, -0.06, 0.1]]
## Galopp: Phase je Bein (vorn links, vorn rechts, hinten links, hinten
## rechts) und Ausschlag vorn/hinten (rad).
const BEIN_PHASE: Array[float] = [0.0, 0.5, 3.4, 3.9]
const SCHWUNG := Vector2(0.62, 0.66)

## Die Netze sind unveränderlich und für jeden Keiler gleich.
static var _netze: Dictionary = {}
static var _fellstoff: StandardMaterial3D = null

var _koerper: Node3D
var _rumpf: MeshInstance3D
var _kopf_gelenk: Node3D
var _augen: MeshInstance3D
var _augenstoff: StandardMaterial3D
var _beine: Array[Node3D] = []
var _staub: CPUParticles3D

## Gangzeit (läuft nur in `aktualisiere`) und Uhr (läuft immer).
var _zeit := 0.0
var _uhr := 0.0
var _tempo := 1.0
var _naehe := 0.0
## 1 = liegt, 0 = steht.
var _schlaf := 0.0
## Sekunden seit `erwachen()`; negativ, wenn er nicht gerade aufspringt.
var _erwachen := -1.0
## Weltlage des liegenden Leibs im Augenblick des Weckens.
var _weck_lage := Transform3D.IDENTITY
var _luft := 0.0
var _luft_ziel := 0.0
var _neigung := 0.0
var _neigung_ziel := 0.0
var _ufer := false
var _ufer_zeit := 0.0
var _ramm := 0.0
var _atem := 0.0
var _staub_an := false
## Physikbild des letzten `aktualisiere` (siehe Kopf, TAKT).
var _angetrieben := -1


func _ready() -> void:
	# Nach der Jagd rechnen: Sie stellt den Knoten und ruft `aktualisiere`.
	process_physics_priority = 10
	_baue()
	_haltung_setzen()


func _baue() -> void:
	var stoff := _fell()
	_koerper = Node3D.new()
	_koerper.name = "Koerper"
	add_child(_koerper)

	_rumpf = _glied(_koerper, "Rumpf", _netz("rumpf"), stoff, true)
	_rumpf.position = RUMPF_MITTE

	_kopf_gelenk = Node3D.new()
	_kopf_gelenk.name = "Hals"
	_kopf_gelenk.position = KOPF_GELENK
	_koerper.add_child(_kopf_gelenk)
	_glied(_kopf_gelenk, "Kopf", _netz("kopf"), stoff, true)
	_augenstoff = Materialbibliothek.leuchtend(AUGE, GLUT.x).duplicate() as StandardMaterial3D
	_augen = _glied(_kopf_gelenk, "Augen", _netz("augen"), _augenstoff, false)

	for i in HUEFTEN.size():
		var huefte := Node3D.new()
		huefte.name = "Huefte%d" % i
		huefte.position = HUEFTEN[i]
		_koerper.add_child(huefte)
		_glied(huefte, "Bein%d" % i, _netz("bein_vorn" if i < 2 else "bein_hinten"), stoff, false)
		_beine.append(huefte)

	_staub = Effekte.dauerstaub(self, false, GOLDSTAUB)
	_staub.name = "Staubfahne"
	_staub.position = Vector3(0.0, 0.15, 1.3)
	_staub.amount = 11 if Effekte.reduziert else 22
	_staub.lifetime = 1.1
	_staub.emission_sphere_radius = 0.7
	_staub.spread = 60.0
	_staub.initial_velocity_min = 0.3
	_staub.initial_velocity_max = 1.1
	_staub.gravity = Vector3(0.0, 0.35, 0.0)
	_staub.scale_amount_min = 0.9
	_staub.scale_amount_max = 1.6
	_staub.color = Color(GOLDSTAUB.r, GOLDSTAUB.g, GOLDSTAUB.b, 0.45)


static func _glied(eltern: Node3D, bezeichnung: String, netz: Mesh, stoff: Material,
		schatten: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eltern.add_child(mi)
	return mi


# =========================================================== Haltungen

## Gang und Stimmung (`tempo` 0..1 Anteil des Höchsttempos, `naehe` 0..1 wie
## dicht er an der Figur ist). Jedes Physikbild, solange er wach ist.
func aktualisiere(delta: float, tempo: float, naehe: float) -> void:
	_angetrieben = Engine.get_physics_frames()
	_tempo = clampf(tempo, 0.0, 1.0)
	_naehe = clampf(naehe, 0.0, 1.0)
	_zeit += delta * _tempo
	if _tempo > 0.5 and _ufer:
		_ufer = false


func schlafen() -> void:
	_schlaf = 1.0
	_erwachen = -1.0
	_ufer = false
	_luft = 0.0
	_luft_ziel = 0.0
	_ramm = 0.0
	_tempo = 0.0
	_atem = 1.5
	_staub_setzen(false)
	_haltung_setzen()
	reset_physics_interpolation()


## Sofort wach, ohne Aufspringen und ohne Effekte: wenn die Jagd ihn an
## einen anderen Ort stellt (nach einem Tod, Ruhe der Proben), statt ihn zu
## wecken.
func aufstehen() -> void:
	_schlaf = 0.0
	_erwachen = -1.0
	_tempo = 1.0
	_haltung_setzen()
	reset_physics_interpolation()


func erwachen() -> void:
	if _schlaf <= 0.0:
		return
	_weck_lage = _koerper.global_transform
	_erwachen = 0.0
	_tempo = 1.0
	if is_inside_tree():
		Effekte.staubwolke(self, global_position + global_basis * Vector3(0.0, 0.0, 1.6), 1.4,
				GOLDSTAUB)
		_schnauben_stoss(1.3)


func in_luft(an: bool) -> void:
	var war := _luft_ziel > 0.5
	_luft_ziel = 1.0 if an else 0.0
	if war == an or _schlaf > 0.5 or not is_inside_tree():
		return
	Effekte.staubwolke(self, global_position, 1.3 if not an else 0.8, GOLDSTAUB)


func hangneigung(winkel: float) -> void:
	_neigung_ziel = winkel


func schnauben() -> void:
	_ufer = true
	_ufer_zeit = 0.0
	_atem = 0.35
	if is_inside_tree() and _schlaf < 0.5:
		Effekte.staubwolke(self, global_position + global_basis * Vector3(0.0, 0.0, -1.4), 1.8,
				GOLDSTAUB)


## Bricht durch einen Durchlass (Entwurf §8.4): `ort` Mitte des Bruchs (Welt),
## `wasser` Ort des Gerinnes, aus dem es schwappt (Welt; nicht endlich =
## kein Wasser).
func durchbrechen(ort: Vector3, wasser: Vector3 = Vector3.INF) -> void:
	_ramm = 0.3
	if not is_inside_tree():
		return
	Effekte.splitter(self, ort, Materialbibliothek.kistenholz(Farben.HOLZ), 16)
	Effekte.staubwolke(self, Vector3(ort.x, global_position.y, ort.z), 1.2, GOLDSTAUB)
	if wasser.is_finite():
		_wasserschwall(wasser)


# =========================================================== Takt

func _physics_process(delta: float) -> void:
	_uhr += delta
	if _angetrieben != Engine.get_physics_frames():
		_tempo = 0.0
	if _erwachen >= 0.0:
		_erwachen += delta
		_schlaf = 1.0 - smoothstep(0.0, ERWACHEN, _erwachen)
		if _erwachen >= ERWACHEN:
			_erwachen = -1.0
			_schlaf = 0.0
	if _ufer:
		_ufer_zeit += delta
	_ramm = maxf(_ramm - delta, 0.0)
	var weich := 1.0 - exp(-12.0 * delta)
	_luft = lerpf(_luft, _luft_ziel, weich)
	_neigung = lerpf(_neigung, _neigung_ziel, weich)
	_haltung_setzen()
	_staub_setzen(_schlaf < 0.5 and _tempo > 0.5 and _luft_ziel < 0.5 and not _ufer)
	_atmen(delta)


## Die ganze Haltung aus dem Zustand: Laufhaltung, darüber Hopser, Ufer und
## Kopfstoß, gemischt mit der Schlafhaltung nach `_schlaf`.
func _haltung_setzen() -> void:
	if _koerper == null:
		return
	var phase := _zeit * TAKT * TAU
	var gang := _tempo * (1.0 - _luft)
	var ufer := 1.0 if _ufer and _tempo < 0.5 else 0.0
	# Schlittern am Ufer: die ersten 0,5 s zurückgelehnt, die Vorderbeine
	# gegen den Boden gestemmt.
	var schlittern := ufer * (1.0 - smoothstep(0.25, 0.6, _ufer_zeit))
	var nicken := 0.06 * gang * sin(phase + 0.3) + 0.16 * schlittern
	var heben := 0.07 * gang * (1.0 + sin(phase - 0.5)) + 0.12 * _luft
	var stand := Transform3D(Basis.from_euler(Vector3(nicken - _neigung, 0.0,
			0.03 * gang * sin(phase * 0.5))), Vector3(0.0, heben, 0.0))
	var liegt := Transform3D(Basis.from_euler(Vector3(0.0, SCHLAF_DREHUNG, SCHLAF_ROLLEN)),
			SCHLAF_VERSATZ)
	if _erwachen >= 0.0:
		# Aus der Lage, in der er geschlafen hat (siehe Kopf, SCHLAFPLATZ).
		liegt = global_transform.affine_inverse() * _weck_lage
	_koerper.transform = stand.interpolate_with(liegt, _schlaf)

	# Atmen: im Schlaf hebt und senkt sich der Leib um seine Mitte.
	var atem := sin(_uhr * ATEM_SCHLAF) * _schlaf
	_rumpf.scale = Vector3(1.0 + 0.012 * atem, 1.0 + 0.024 * atem, 1.0)

	# Beine: Galopp, im Hopser gestreckt, am Ufer gestemmt bzw. scharrend,
	# im Schlaf unter den Leib gefaltet.
	var scharren := ufer * (1.0 - schlittern) * maxf(sin(_uhr * 4.2), 0.0) \
			* smoothstep(0.3, 0.7, sin(_uhr * 0.9))
	for i in _beine.size():
		var vorn := i < 2
		var w := sin(phase + BEIN_PHASE[i]) * (SCHWUNG.x if vorn else SCHWUNG.y) * gang
		w += _luft * (0.75 if vorn else -0.7)
		w += schlittern * (0.45 if vorn else 0.3)
		if i == 0:
			w += 0.5 * scharren
		var gefaltet := -1.4 if vorn else 1.25
		_beine[i].rotation = Vector3(lerpf(w, gefaltet, _schlaf), 0.0, 0.0)

	# Kopf: tiefer, je näher er ist; beim Durchbrechen ein Stoß; am Ufer
	# schüttelt er ihn bei jedem Schnauben; im Schlaf liegt das Kinn auf.
	var schuetteln := ufer * (1.0 - schlittern) * _schnaub_huelle() * sin(_uhr * 11.0) * 0.28
	var kopf_x := lerpf(0.0, -0.2, _naehe) + 0.07 * gang * sin(phase + 0.9) \
			- 0.4 * (_ramm / 0.3) + 0.12 * _luft
	_kopf_gelenk.rotation = Vector3(lerpf(kopf_x, -0.22, _schlaf),
			schuetteln * (1.0 - _schlaf), 0.0)

	# Augen: zu im Schlaf, sonst Glut nach Nähe (am Ufer voll).
	_augen.visible = _schlaf < 0.6
	var glut := maxf(_naehe, ufer)
	_augenstoff.emission_energy_multiplier = lerpf(GLUT.x, GLUT.y, glut)


## Hülle des Schnaubens: 1 kurz nach jedem Stoß, dazwischen 0.
func _schnaub_huelle() -> float:
	var t := fposmod(_ufer_zeit, SCHNAUB_TAKT)
	return 1.0 - smoothstep(0.1, 0.55, t)


func _staub_setzen(an: bool) -> void:
	if _staub == null or an == _staub_an:
		return
	_staub_an = an
	_staub.emitting = an


## Atemdampf (siehe Kopf, EFFEKTE).
func _atmen(delta: float) -> void:
	if not is_inside_tree():
		return
	_atem -= delta
	if _atem > 0.0:
		return
	if _schlaf > 0.5:
		# Ausatmen, wenn sich der Leib senkt.
		_atem = TAU / ATEM_SCHLAF
		_schnauben_stoss(0.55)
	elif _ufer and _tempo < 0.5:
		_atem = SCHNAUB_TAKT
		_schnauben_stoss(1.0)
	elif _tempo > 0.5:
		_atem = ATEM_LAUF
		_schnauben_stoss(0.7)
	else:
		_atem = 1.0


## Zwei Wölkchen aus der Wurfscheibe, nach vorn und schräg nach unten.
func _schnauben_stoss(staerke: float) -> void:
	var gelenk := _kopf_gelenk.global_transform
	var vor := (gelenk.basis * Vector3(0.0, -0.35, -1.0)).normalized()
	for seite: float in [-1.0, 1.0]:
		var ort := gelenk * (NASE + Vector3(0.07 * seite, 0.0, -ATEM_VOR))
		var p := Effekte.rauch(self, ort, DAMPF, 0.32 * staerke, 3)
		if p == null:
			return
		p.direction = (vor + gelenk.basis.x.normalized() * 0.25 * seite).normalized()
		p.spread = 18.0
		p.initial_velocity_min = 1.0 * staerke
		p.initial_velocity_max = 1.9 * staerke
		p.damping_min = 2.5
		p.damping_max = 3.5
		p.gravity = Vector3(0.0, 0.35, 0.0)


## Wasser schwappt aus dem Gerinne: Tropfen fallen, unten stäubt Gischt.
func _wasserschwall(ort: Vector3) -> void:
	var tropfen := Effekte.rauch(self, ort, TROPFEN, 0.2, 26)
	if tropfen != null:
		tropfen.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		tropfen.emission_box_extents = Vector3(1.2, 0.1, 0.4)
		tropfen.direction = Vector3.DOWN
		tropfen.spread = 30.0
		tropfen.initial_velocity_min = 0.4
		tropfen.initial_velocity_max = 2.2
		tropfen.damping_min = 0.0
		tropfen.damping_max = 0.2
		tropfen.gravity = Vector3(0.0, -14.0, 0.0)
		tropfen.lifetime = 0.9
		tropfen.scale_amount_min = 0.08
		tropfen.scale_amount_max = 0.15
		tropfen.scale_amount_curve = null
	var gischt := Effekte.rauch(self, Vector3(ort.x, global_position.y + 0.3, ort.z),
			GISCHT, 1.1, 6)
	if gischt != null:
		gischt.gravity = Vector3(0.0, 0.2, 0.0)


# =========================================================== Netze

static func _fell() -> StandardMaterial3D:
	if _fellstoff == null:
		_fellstoff = Materialbibliothek.fell(Color(0.8, 0.78, 0.76)).duplicate() \
				as StandardMaterial3D
		_fellstoff.vertex_color_use_as_albedo = true
		_fellstoff.albedo_color = Color.WHITE
	return _fellstoff


static func _netz(art: String) -> ArrayMesh:
	if not _netze.has(art):
		match art:
			"rumpf":
				_netze[art] = _rumpf_bauen()
			"kopf":
				_netze[art] = _kopf_bauen()
			"augen":
				_netze[art] = _augen_bauen()
			"bein_vorn":
				_netze[art] = _bein_bauen(BEIN_VORN)
			_:
				_netze[art] = _bein_bauen(BEIN_HINTEN)
	return _netze[art]


## Wert einer Station zwischen den Stützpunkten (Catmull-Rom über `spalte`).
static func _glatt(tabelle: Array, spalte: int, z: float) -> float:
	var n := tabelle.size()
	var i := 0
	while i < n - 2 and z > float(tabelle[i + 1][0]):
		i += 1
	var a: Array = tabelle[maxi(i - 1, 0)]
	var b: Array = tabelle[i]
	var c: Array = tabelle[i + 1]
	var d: Array = tabelle[mini(i + 2, n - 1)]
	var t := clampf((z - float(b[0])) / maxf(float(c[0]) - float(b[0]), 0.001), 0.0, 1.0)
	var p0 := float(a[spalte])
	var p1 := float(b[spalte])
	var p2 := float(c[spalte])
	var p3 := float(d[spalte])
	return 0.5 * (2.0 * p1 + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
			+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## Der Leib: Ringe alle 0,1 m, Querschnitt oben schmaler (Rückgrat), unten
## voll (Bauch); auf dem Rücken die Mähne als Sägezahn – jeder zweite Ring
## höher, so steht sie gegen den Himmel als Borstenkamm. Dazu der Schwanz.
static func _rumpf_bauen() -> ArrayMesh:
	var st := Riesenstamm.bauer()
	const SEITEN := 22
	var z0 := float(RUMPF[0][0])
	var z1 := float(RUMPF[RUMPF.size() - 1][0])
	var anzahl := ceili((z1 - z0) / 0.1)
	var zeilen: Array[PackedVector3Array] = []
	var farben: Array[PackedColorArray] = []
	for k in anzahl + 1:
		var z := lerpf(z0, z1, float(k) / float(anzahl))
		var oben := _glatt(RUMPF, 1, z)
		var unten := _glatt(RUMPF, 2, z)
		var breite := maxf(_glatt(RUMPF, 3, z), 0.02)
		var maehne := maxf(_glatt(RUMPF, 4, z), 0.0)
		var mitte := (oben + unten) * 0.5
		var zacke := 0.55 + 0.45 * float(k % 2) + 0.25 * (Riesenstamm.randf_hash(k, 3) - 0.5)
		var zeile := PackedVector3Array()
		var fa := PackedColorArray()
		for j in SEITEN + 1:
			var w := TAU * float(j % SEITEN) / float(SEITEN)
			var c := cos(w)
			var s := sin(w)
			var x := breite * signf(c) * pow(absf(c), 0.8) * (1.0 - 0.22 * pow(maxf(s, 0.0), 2.0))
			var h := (oben - mitte) if s >= 0.0 else (mitte - unten)
			var y := mitte + h * signf(s) * pow(absf(s), 0.8)
			var kamm := 0.0
			if s > 0.72:
				kamm = maehne * zacke * pow((s - 0.72) / 0.28, 2.0)
				y += kamm
			zeile.append(Vector3(x, y, z) - RUMPF_MITTE)
			fa.append(_fellfarbe(s, kamm, k * 31 + j))
		zeilen.append(zeile)
		farben.append(fa)
	_gitter(st, zeilen, farben, true, true)
	# Schwanz mit Quaste
	var schwanz := PackedVector3Array([Vector3(0.0, 1.5, 1.98), Vector3(0.0, 1.32, 2.14),
			Vector3(0.03, 1.08, 2.2), Vector3(0.04, 0.9, 2.18)])
	for i in schwanz.size():
		schwanz[i] -= RUMPF_MITTE
	_strang(st, schwanz, PackedFloat32Array([0.07, 0.05, 0.04, 0.075]),
			PackedColorArray([FELL, FELL, BAUCH, BAUCH]), 6, 1.0, Vector3.BACK)
	return Riesenstamm.fertig(st)


## Fellfarbe nach Lage am Leib: Bauch dunkel, Rücken angegraut, die Spitzen
## der Mähne hell; dazu ein Hauch Rauschen.
static func _fellfarbe(s: float, kamm: float, saat: int) -> Color:
	var f := BAUCH.lerp(FELL, smoothstep(-0.8, -0.2, s))
	f = f.lerp(RUECKEN, smoothstep(-0.05, 0.85, s) * 0.85)
	if kamm > 0.0:
		f = f.lerp(BORSTE, clampf(kamm / 0.22, 0.0, 1.0))
	var r := 0.9 + 0.2 * Riesenstamm.randf_hash(saat, 11)
	return Color(f.r * r, f.g * r, f.b * r, 1.0)


## Der Kopf: Keil vom Nacken zur Wurfscheibe (oben gerade Stirnlinie, unten
## steigt der Kiefer an), die Scheibe als Deckel, Ohren und Hauer.
static func _kopf_bauen() -> ArrayMesh:
	var st := Riesenstamm.bauer()
	const SEITEN := 18
	var zeilen: Array[PackedVector3Array] = []
	var farben: Array[PackedColorArray] = []
	for k in KOPF.size():
		var e: Array = KOPF[k]
		var mitte := Vector3(e[0], e[1], e[2])
		var breite: float = e[3]
		var oben: float = e[4]
		var unten: float = e[5]
		var vorn := float(k) / float(KOPF.size() - 1)
		var zeile := PackedVector3Array()
		var fa := PackedColorArray()
		for j in SEITEN + 1:
			var w := TAU * float(j % SEITEN) / float(SEITEN)
			var c := cos(w)
			var s := sin(w)
			# Ringe laufen nach vorn (−Z): x gespiegelt, damit die
			# Vorderseite außen liegt (siehe `_gitter`).
			var x := -breite * signf(c) * pow(absf(c), 0.85)
			var y := (oben if s >= 0.0 else unten) * signf(s) * pow(absf(s), 0.85)
			zeile.append(mitte + Vector3(x, y, 0.0))
			var f := _fellfarbe(s * 0.8, 0.0, k * 17 + j)
			if k == KOPF.size() - 1:
				f = SCHEIBE
			elif vorn > 0.6:
				f = f.lerp(SCHEIBE * 0.6, smoothstep(0.6, 0.95, vorn) * 0.6)
			fa.append(f)
		zeilen.append(zeile)
		farben.append(fa)
	_gitter(st, zeilen, farben, true, false)
	# Wurfscheibe: ein Deckel, zur Mitte dunkler (die Nasenlöcher).
	var ring := zeilen[zeilen.size() - 1]
	var scheibe_mitte := NASE
	for j in ring.size() - 1:
		_dreieck(st, scheibe_mitte, ring[j], ring[j + 1], Vector3.FORWARD,
				SCHEIBE * 0.5, SCHEIBE, SCHEIBE)
	# Ohren: spitze, flache Tüten, nach oben, außen und hinten.
	for seite: float in [-1.0, 1.0]:
		var fuss := Vector3(0.3 * seite, 0.34, -0.12)
		var spitze := fuss + Vector3(0.3 * seite, 0.4, 0.3)
		_strang(st, PackedVector3Array([fuss, fuss.lerp(spitze, 0.5), spitze]),
				PackedFloat32Array([0.13, 0.1, 0.0]), PackedColorArray([FELL, FELL, RUECKEN]),
				6, 0.45, Vector3.BACK)
		# Hauer: aus dem Unterkiefer nach außen und oben gebogen.
		var hauer := PackedVector3Array([Vector3(0.16 * seite, -0.6, -1.12),
				Vector3(0.28 * seite, -0.56, -1.22), Vector3(0.38 * seite, -0.4, -1.24),
				Vector3(0.41 * seite, -0.22, -1.16), Vector3(0.38 * seite, -0.08, -1.04)])
		_strang(st, hauer, PackedFloat32Array([0.07, 0.062, 0.05, 0.034, 0.0]),
				PackedColorArray([HAUER_WURZEL, HAUER, HAUER, HAUER, HAUER]), 7, 1.0,
				Vector3.FORWARD)
	return Riesenstamm.fertig(st)


static func _augen_bauen() -> ArrayMesh:
	var st := Riesenstamm.bauer()
	for seite: float in [-1.0, 1.0]:
		var mitte := Vector3(AUGE_ORT.x * seite, AUGE_ORT.y, AUGE_ORT.z)
		var punkte := PackedVector3Array([mitte + Vector3(0.0, 0.0, 0.06), mitte,
				mitte + Vector3(0.0, 0.0, -0.06)])
		_strang(st, punkte, PackedFloat32Array([0.0, 0.072, 0.0]),
				PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE]), 8, 0.75, Vector3.UP)
	return Riesenstamm.fertig(st)


## Ein Bein im Raum seiner Hüfte: Stationen [y, z, Radius], quer etwas
## schmaler; unten der Huf, dunkel.
static func _bein_bauen(stationen: Array) -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var punkte := PackedVector3Array()
	var radien := PackedFloat32Array()
	var farben := PackedColorArray()
	for i in stationen.size():
		var e: Array = stationen[i]
		punkte.append(Vector3(0.0, e[0], e[1]))
		radien.append(e[2])
		var f := FELL.lerp(BAUCH, float(i) / float(stationen.size() - 1))
		if i >= stationen.size() - 2:
			f = HUF
		farben.append(f)
	_strang(st, punkte, radien, farben, 9, 0.85, Vector3.FORWARD)
	return Riesenstamm.fertig(st)


## Ein Strang durch `punkte` mit Radius und Farbe je Punkt; Querschnitt
## elliptisch (`platt` in Richtung `bezug`, quer zur Achse). Der Anfang
## bekommt einen Deckel; das Ende läuft spitz zu, wenn sein Radius 0 ist,
## sonst ebenfalls ein Deckel (`ende_zu`).
static func _strang(st: SurfaceTool, punkte: PackedVector3Array, radien: PackedFloat32Array,
		farben: PackedColorArray, seiten: int, platt: float, bezug: Vector3,
		ende_zu: bool = true) -> void:
	var n := punkte.size()
	var zeilen: Array[PackedVector3Array] = []
	var fa: Array[PackedColorArray] = []
	for i in n:
		var t := (punkte[mini(i + 1, n - 1)] - punkte[maxi(i - 1, 0)]).normalized()
		var hoch := bezug - t * bezug.dot(t)
		if hoch.length() < 0.05:
			hoch = Vector3.RIGHT - t * Vector3.RIGHT.dot(t)
		hoch = hoch.normalized()
		var quer := hoch.cross(t).normalized()
		var zeile := PackedVector3Array()
		var reihe := PackedColorArray()
		for j in seiten + 1:
			var w := TAU * float(j % seiten) / float(seiten)
			zeile.append(punkte[i] + (quer * cos(w) + hoch * sin(w) * platt) * radien[i])
			reihe.append(farben[i])
		zeilen.append(zeile)
		fa.append(reihe)
	_gitter(st, zeilen, fa, true, ende_zu and radien[n - 1] > 0.0)


## Netz aus Ringen (je Ring dieselbe Zahl Punkte, der letzte gleich dem
## ersten) im Scheitelformat von `Riesenstamm` (die Farbe in COLOR, UV
## rundum und längs für die Felltextur). Die Ringe müssen so umlaufen, dass
## (quer, hoch, Laufrichtung) rechtshändig ist – dann zeigen die Normalen
## nach außen. Deckel an Anfang und Ende, wenn verlangt.
static func _gitter(st: SurfaceTool, zeilen: Array[PackedVector3Array],
		farben: Array[PackedColorArray], deckel_anfang: bool, deckel_ende: bool) -> void:
	var uvs: Array[PackedVector2Array] = []
	var arten: Array[PackedVector2Array] = []
	var laenge := 0.0
	for i in zeilen.size():
		if i > 0:
			laenge += _mitte(zeilen[i]).distance_to(_mitte(zeilen[i - 1]))
		var uv := PackedVector2Array()
		var art := PackedVector2Array()
		var c := zeilen[i].size()
		for j in c:
			uv.append(Vector2(float(j) / float(c - 1) * 2.0, laenge * 0.8))
			art.append(Vector2.ZERO)
		uvs.append(uv)
		arten.append(art)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)
	if deckel_anfang:
		_deckel(st, zeilen[0], zeilen[1], farben[0][0])
	if deckel_ende:
		_deckel(st, zeilen[zeilen.size() - 1], zeilen[zeilen.size() - 2],
				farben[farben.size() - 1][0])


static func _mitte(zeile: PackedVector3Array) -> Vector3:
	var summe := Vector3.ZERO
	for k in zeile.size() - 1:
		summe += zeile[k]
	return summe / float(maxi(zeile.size() - 1, 1))


static func _deckel(st: SurfaceTool, rand: PackedVector3Array, nachbar: PackedVector3Array,
		farbe: Color) -> void:
	var mitte := _mitte(rand)
	var aussen := mitte - _mitte(nachbar)
	for k in rand.size() - 1:
		_dreieck(st, mitte, rand[k], rand[k + 1], aussen, farbe, farbe, farbe)


## Ein Dreieck im Scheitelformat, Vorderseite nach `aussen`.
static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var ecken: Array[Vector3] = [a, b, c]
	var farben: Array[Color] = [fa, fb, fc]
	if kreuz.dot(aussen) > 0.0:
		ecken = [a, c, b]
		farben = [fa, fc, fb]
		kreuz = -kreuz
	var n := -kreuz.normalized()
	for e in 3:
		var p := ecken[e]
		st.set_color(farben[e])
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 2.0)
		st.set_uv2(Vector2.ZERO)
		st.set_normal(n)
		st.add_vertex(p)
