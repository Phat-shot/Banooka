extends Node3D
class_name Schutzmaske
## Der Schutz als EIN Schutzgeist, der um die Figur schwirrt.
##
## Früher kreiste je Ladung eine Maske um den Kopf – drei Masken bei
## voller Ladung, ein Karussell, das ständig vor der Figur vorbeizog.
## Jetzt ist es immer genau einer, und die Zahl der Ladungen zeigt sich an
## seinem Leuchten:
##
##   1  sanftes Glimmen, ein kleiner Hof
##   2  hell, der Hof wird größer und blüht im Glow auf
##   3  strahlend: Strahlenkranz und Funken, die um ihn blinken
##
## Der Hof ist eine eigene, immer zur Kamera gedrehte Fläche, die additiv
## gezeichnet wird. Er leuchtet also auch in Leveln ohne Glow; wo Glow an
## ist (Level 01), blüht zusätzlich das Leuchten der Maske selbst auf.
##
## Bewegung: Der Geist schwebt auf Schulterhöhe NEBEN und etwas HINTER der
## Figur – beides von der Kamera aus gesehen, damit er nie zwischen
## Kamera und Figur gerät. Er folgt über eine Feder mit Dämpfung, zieht
## also beim Loslaufen etwas nach und schießt beim Anhalten ein Stück
## vor; dazu wippt er sacht und macht ab und zu einen kleinen Ausflug zur
## Seite. Läuft die Figur quer durchs Bild, wechselt er auf die Seite
## hinter ihr – in einem Bogen über und hinter die Figur, nie durch sie
## hindurch. Kreisen tut er nicht mehr.
##
## Reine Anzeige: keine Kollision, kein Schatten. Ein Sichtstrahl im
## Physiktakt hält ihn vor Wänden zurück.
##
## Gezeichnet im Bildtakt (ARCHITEKTUR.md, „Bildtakt und Physiktakt"):
## Der Knoten ist `top_level`, ohne Interpolation, und liest die Figur
## über `Bildtakt.ort()`.

# --- Wo er schwebt (bezogen auf Figur und Kamera) ---
const SEITE := 0.72          ## Abstand quer zur Kamera
const HOEHE := 1.28          ## Schulterhöhe über den Füßen
const TIEFE := 0.3           ## hinter der Figur, von der Kamera weg
## Beim Seitenwechsel steigt er in einem Bogen über und hinter die Figur.
const BOGEN_HOEHE := 0.45
const BOGEN_TIEFE := 0.55
## Ab diesem Tempo quer durchs Bild (m/s) wechselt er auf die Seite
## hinter der Figur.
const WECHSEL_TEMPO := 2.5
## Dauer eines Seitenwechsels in Sekunden.
const WECHSEL_DAUER := 0.55

# --- Wie er folgt ---
## Anteil der Figurbewegung, den er sofort mitmacht; den Rest holt die
## Feder auf. Bei vollem Lauftempo (8,5 m/s) hängt er so rund einen
## halben Meter zurück.
const MITNAHME := 0.6
const FEDER := 110.0         ## Eigenfrequenz rund 10,5 rad/s
const BREMSE := 15.0         ## Dämpfungsmaß rund 0,7: einmal leicht nachschwingen
## Weiter als das bleibt er nie hinter seinem Platz zurück.
const LEINE := 1.0
## Um die Figur bleibt so viel frei (in Metern auf Höhe der Figur).
const FREI := 0.5
## Halbmesser des Geists samt Flügeln – so weit bleibt er von Wänden weg.
const RAND := 0.28

# --- Leuchten je Stufe: [Leuchten der Maske, Hof, Hofgröße, Strahlen] ---
const STUFEN := [
	[0.0, 0.0, 0.9, 0.0],
	[0.35, 0.32, 1.1, 0.0],
	[1.1, 0.7, 1.45, 0.0],
	[1.9, 1.0, 1.85, 0.85],
]

const FARBE := Farben.KISTE_SCHUTZ
const SCHALE := Color(0.86, 0.94, 1.0)
const AUGE := Color(0.92, 1.0, 1.0)
const MUND := Color(0.16, 0.36, 0.72)

## Die Figur, an der der Geist hängt. Wird beim Eintreten gemerkt:
## `get_parent_node_3d()` liefert bei einem `top_level`-Knoten immer null,
## weil Godot dessen Elternverbindung im Transformbaum kappt.
var _traeger: Node3D

var _geist: Node3D           ## Maske und Flügel; dreht und skaliert sich
var _schein: MeshInstance3D  ## Hof, immer zur Kamera
var _stoff: ShaderMaterial
var _fluegel_stoff: ShaderMaterial
var _schein_stoff: ShaderMaterial

var _anzahl := -1            ## angezeigte Stufe
var _glanz := 0.0            ## weich nachgeführte Stufe (0..3)
var _puls := 0.0             ## Aufblitzen bei Gewinn und Verlust, klingt ab
var _zittern := 0.0          ## Restzeit des Flackerns nach einem Treffer
var _groesse := 1.0          ## Grundgröße (Aufploppen, Zerbrechen)
var _ablauf: Tween = null

var _hoehe := HOEHE          ## Schulterhöhe über dem Ursprung des Trägers
var _ort := Vector3.ZERO
var _tempo := Vector3.ZERO
var _neu := true             ## beim nächsten Bild direkt auf den Platz
var _traeger_vorher := Vector3.ZERO
var _lauf := Vector3.ZERO    ## geglättete Geschwindigkeit der Figur
var _seite := -1.0           ## +1 rechts der Figur (Kamerasicht), −1 links
var _seite_glatt := -1.0
var _ausflug := Vector3.ZERO
var _ausflug_pause := 1.0
var _zeit := 0.0
var _dreh := Quaternion.IDENTITY
var _blick := Vector3.FORWARD

## Unverkürzter Platz relativ zur Figur (für den Sichtstrahl) und der
## Anteil davon, der vor einer Wand noch frei ist.
var _versatz := Vector3.ZERO
var _wand := 1.0
var _wand_ziel := 1.0
var _strahl := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	# Erst den Träger merken, dann abkoppeln – nach `top_level = true`
	# ist die Elternverbindung im Transformbaum weg.
	_traeger = get_parent() as Node3D
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	_baue()
	_strahl.collision_mask = 1
	# Auf der Wildkatze, im Kart und im Flieger sitzt das Modell höher
	# oder kleiner im Träger: Schulterhöhe nach seinem Maßstab.
	var modell: Node3D = null
	if _traeger != null:
		modell = _traeger.get_node_or_null("Modell") as Node3D
	if modell != null:
		_hoehe = modell.position.y + HOEHE * modell.scale.y
	var koerper := _traeger as CollisionObject3D
	if koerper != null:
		_strahl.exclude = [koerper.get_rid()]
	GameState.schutz_geaendert.connect(_auf_schutz)
	_setze_anzahl(GameState.schutz_anzeige())


func _process(delta: float) -> void:
	if not is_instance_valid(_traeger):
		_traeger = get_parent() as Node3D
		return
	if delta <= 0.0:
		return
	delta = minf(delta, 0.05)
	if not _scherben.is_empty():
		_scherben_fuehren(delta)
	if _anzahl <= 0 and not _geist.visible:
		return
	_zeit += delta
	_folgen(delta)
	_ausrichten(delta)
	_leuchten(delta)


## Sichtstrahl von der Brust zum Platz: Steht eine Wand dazwischen, rückt
## der Geist näher an die Figur. Im Physiktakt, weil der Raum nur dort
## sicher abgefragt wird; das Ergebnis wird im Bildtakt weich übernommen.
func _physics_process(_delta: float) -> void:
	if _anzahl <= 0 or not is_instance_valid(_traeger) or _versatz == Vector3.ZERO:
		return
	var von := _traeger.global_position + Vector3.UP * 0.9
	var nach := _traeger.global_position + _versatz
	var laenge := von.distance_to(nach) + RAND
	if laenge < 0.01:
		return
	_strahl.from = von
	_strahl.to = von + (nach - von).normalized() * laenge
	var treffer := get_world_3d().direct_space_state.intersect_ray(_strahl)
	if treffer.is_empty():
		_wand_ziel = 1.0
	else:
		var frei := von.distance_to(treffer["position"]) - RAND
		_wand_ziel = clampf(frei / maxf(laenge - RAND, 0.01), 0.15, 1.0)


# --------------------------------------------------------------- Bewegung

func _folgen(delta: float) -> void:
	var figur := Bildtakt.ort(_traeger)
	var schritt := figur - _traeger_vorher
	_traeger_vorher = figur

	var rechts := Vector3.RIGHT
	var weg := Vector3.FORWARD        # von der Kamera weg, waagerecht
	var kamera := get_viewport().get_camera_3d()
	if kamera != null:
		var r := kamera.global_basis.x
		var w := -kamera.global_basis.z
		r.y = 0.0
		w.y = 0.0
		if r.length_squared() > 0.01 and w.length_squared() > 0.01:
			rechts = r.normalized()
			weg = w.normalized()

	var lauf := Vector3(schritt.x, 0.0, schritt.z) / delta
	if _neu or schritt.length() > Bildtakt.VERSETZT:
		lauf = Vector3.ZERO
	_lauf = _lauf.lerp(lauf, 1.0 - exp(-6.0 * delta))

	# Seite: hinter der Laufrichtung, wie das Bild sie zeigt. Wer stehen
	# bleibt oder auf die Kamera zu läuft, behält seinen Geist, wo er ist.
	var quer := _lauf.dot(rechts)
	if quer > WECHSEL_TEMPO:
		_seite = -1.0
	elif quer < -WECHSEL_TEMPO:
		_seite = 1.0
	_seite_glatt = move_toward(_seite_glatt, _seite, delta * 2.0 / WECHSEL_DAUER)
	var s := _seite_glatt
	var bogen := 1.0 - s * s

	_ausflug_pause -= delta
	if _ausflug_pause <= 0.0:
		_ausflug_pause = randf_range(0.7, 1.8)
		_ausflug = Vector3(randf_range(-0.22, 0.22), randf_range(-0.08, 0.18),
				randf_range(-0.12, 0.22))
	var schweben := Vector3(sin(_zeit * 1.3) * 0.05,
			sin(_zeit * 2.4) * 0.07 + sin(_zeit * 3.7) * 0.025, cos(_zeit * 1.7) * 0.05)

	_versatz = rechts * (s * SEITE + _ausflug.x + schweben.x) \
			+ Vector3.UP * (_hoehe + BOGEN_HOEHE * bogen + _ausflug.y + schweben.y) \
			+ weg * (TIEFE + BOGEN_TIEFE * bogen + _ausflug.z + schweben.z)
	_wand = lerpf(_wand, _wand_ziel, 1.0 - exp(-10.0 * delta))
	var brust := Vector3.UP * 0.9
	var ziel := figur + brust + (_versatz - brust) * _wand

	if _neu or schritt.length() > Bildtakt.VERSETZT:
		# Erstes Bild oder die Figur wurde versetzt (Respawn): nicht quer
		# durchs Level hinterherfliegen.
		_neu = false
		_ort = ziel
		_tempo = Vector3.ZERO
	else:
		_ort += schritt * MITNAHME
		_tempo += ((ziel - _ort) * FEDER - _tempo * BREMSE) * delta
		_ort += _tempo * delta
		var abstand := _ort - ziel
		if abstand.length() > LEINE:
			_ort = ziel + abstand.normalized() * LEINE

	if kamera != null:
		_ort = _aus_der_sicht(_ort, kamera.global_position, figur + brust, rechts * signf(s))
	global_position = _ort


## Schiebt `ort` aus der Sichtlinie von der Kamera zur Figur. Je näher er
## der Kamera ist, desto mehr verdeckt er – desto weiter muss er weg.
static func _aus_der_sicht(ort: Vector3, kamera: Vector3, figur: Vector3,
		ausweichen: Vector3) -> Vector3:
	var linie := figur - kamera
	var laenge := linie.length()
	if laenge < 0.5:
		return ort
	var richtung := linie / laenge
	var entlang := (ort - kamera).dot(richtung)
	if entlang <= 0.0 or entlang >= laenge:
		return ort
	var naechster := kamera + richtung * entlang
	var quer := ort - naechster
	var frei := FREI * entlang / laenge + RAND
	var abstand := quer.length()
	if abstand >= frei:
		return ort
	var weg_von := quer / abstand if abstand > 0.01 else ausweichen
	return naechster + weg_von * frei


## Blickt in Laufrichtung, im Stand halb zur Kamera; neigt sich ins Tempo
## und in die Kurve, wackelt ein wenig.
func _ausrichten(delta: float) -> void:
	var lauf := _lauf.length()
	if lauf > 1.0:
		_blick = _lauf / lauf
	var kamera := get_viewport().get_camera_3d()
	var zur_kamera := _blick
	if kamera != null:
		zur_kamera = kamera.global_position - _ort
		zur_kamera.y = 0.0
		zur_kamera = zur_kamera.normalized() if zur_kamera.length_squared() > 0.01 else _blick
	var eile := clampf(lauf / 6.0, 0.0, 1.0)
	var richtung := zur_kamera.lerp(_blick, 0.45 + 0.5 * eile)
	if richtung.length_squared() < 0.01:
		richtung = _blick
	var ziel := Basis.looking_at(richtung.normalized(), Vector3.UP)
	var seitlich := _tempo.dot(ziel.x)
	ziel = ziel * Basis.from_euler(Vector3(-0.35 * eile + sin(_zeit * 2.1) * 0.08,
			sin(_zeit * 1.6) * 0.12, clampf(-seitlich * 0.08, -0.5, 0.5) + sin(_zeit * 2.9) * 0.06))
	if _zittern > 0.0:
		ziel = ziel * Basis.from_euler(Vector3(randf_range(-0.3, 0.3),
				randf_range(-0.4, 0.4), randf_range(-0.3, 0.3)) * (_zittern / 0.4))
	_dreh = _dreh.slerp(ziel.get_rotation_quaternion(), 1.0 - exp(-9.0 * delta))
	var puls := 1.0 + _puls * 0.25
	_geist.basis = Basis(_dreh).scaled(Vector3.ONE * maxf(_groesse * puls, 0.001))


# ---------------------------------------------------------------- Leuchten

func _leuchten(delta: float) -> void:
	_puls = maxf(_puls - delta * 3.0, 0.0)
	_zittern = maxf(_zittern - delta, 0.0)
	_glanz = move_toward(_glanz, float(maxi(_anzahl, 0)), delta * 3.0)
	var unten := mini(int(_glanz), STUFEN.size() - 2)
	var anteil := clampf(_glanz - float(unten), 0.0, 1.0)
	var a: Array = STUFEN[unten]
	var b: Array = STUFEN[unten + 1]
	var leuchten := lerpf(a[0], b[0], anteil)
	var hof := lerpf(a[1], b[1], anteil)
	var hof_groesse := lerpf(a[2], b[2], anteil)
	var strahlen := lerpf(a[3], b[3], anteil)
	# Nach einem Treffer flackert er, bevor er eine Stufe dunkler steht.
	if _zittern > 0.0:
		var flackern := 0.5 + 0.5 * sin(_zeit * 55.0)
		leuchten *= 0.4 + 0.9 * flackern
		hof *= 0.5 + 0.8 * flackern
	leuchten += _puls * 2.5
	hof += _puls * 0.9
	_stoff.set_shader_parameter("leuchten", leuchten)
	_fluegel_stoff.set_shader_parameter("leuchten", 0.5 + leuchten)
	_schein_stoff.set_shader_parameter("staerke", hof * _groesse)
	_schein_stoff.set_shader_parameter("strahlen", strahlen)
	_schein_stoff.set_shader_parameter("groesse", hof_groesse * (1.0 + _puls * 0.4))


# ------------------------------------------------------- Gewinn und Verlust

func _auf_schutz(anzahl: int) -> void:
	_setze_anzahl(anzahl)


## Gleicht den Geist an die Zahl der Ladungen an. Beim ersten Mal (Level-
## start) ohne Blitz und Funken – sonst sähe der Start aus wie ein Treffer.
func _setze_anzahl(anzahl: int) -> void:
	anzahl = clampi(anzahl, 0, GameState.SCHUTZ_MAX)
	if anzahl == _anzahl:
		return
	var vorher := _anzahl
	_anzahl = anzahl
	if vorher < 0:
		_glanz = float(anzahl)
		_geist.visible = anzahl > 0
		_schein.visible = anzahl > 0
		_neu = true
		return
	if anzahl > vorher:
		_gewonnen(vorher)
	elif anzahl > 0:
		_getroffen()
	else:
		_zerbrochen()


func _gewonnen(vorher: int) -> void:
	_halt_ablauf()
	_puls = 1.0
	if vorher <= 0:
		# Aus dem Nichts: Er ploppt an der Schulter der Figur auf.
		_neu = true
		_geist.visible = true
		_schein.visible = true
		_groesse = 0.0
		_ablauf = create_tween()
		_ablauf.tween_property(self, "_groesse", 1.0, 0.35) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_inside_tree():
		Effekte.funken(self, _ort, FARBE.lightened(0.3), 8, 2.5, 0.14)


## Eine Stufe weniger: Blitz, ein paar Splitter, er flackert und steht
## danach eine Stufe dunkler.
func _getroffen() -> void:
	_zittern = 0.4
	_puls = 0.6
	if is_inside_tree():
		Effekte.aufblitzen(self, _ort, FARBE.lightened(0.5), 1.0, 0.12)
		Effekte.funken(self, _ort, FARBE, 10, 4.0)
	_scherben_werfen(2, 2.5)


## Die letzte Stufe: Er zerspringt und verschwindet.
func _zerbrochen() -> void:
	_halt_ablauf()
	_zittern = 0.0
	if is_inside_tree():
		Effekte.aufblitzen(self, _ort, FARBE.lightened(0.6), 1.5, 0.16)
		Effekte.funken(self, _ort, FARBE, 16, 5.0)
		# Ein Ring, der sich zur Kamera hin aufweitet: Der Schutz ist weg.
		var kamera := get_viewport().get_camera_3d()
		var achse := kamera.global_basis.z if kamera != null else Vector3.BACK
		Effekte.ring(self, _ort, FARBE.lightened(0.3), 0.9, 0.3, achse)
	_scherben_werfen(7, 3.5)
	_ablauf = create_tween()
	_ablauf.tween_property(self, "_groesse", 0.0, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_ablauf.tween_callback(func() -> void:
		_geist.visible = false
		_schein.visible = false)


## Scherben der Maske: kleine helle Dreiecke im Stoff der Maske, die
## auseinanderfliegen, trudeln und schrumpfen. (Die Bretter aus
## `Effekte.splitter` lasen sich als zerbrochene Kiste.) Eigene Knoten,
## `top_level`, damit sie nicht mit dem Geist weiterfliegen; im Bildtakt
## bewegt, ohne Interpolation wie alles hier.
class Scherbe:
	var knoten: MeshInstance3D
	var tempo: Vector3
	var drall: Vector3
	var alter := 0.0

const SCHERBEN_DAUER := 0.6

var _scherben: Array[Scherbe] = []
static var _scherbennetz: PrismMesh = null


func _scherben_werfen(anzahl: int, wucht: float) -> void:
	if not is_inside_tree():
		return
	if _scherbennetz == null:
		_scherbennetz = PrismMesh.new()
		_scherbennetz.size = Vector3(0.09, 0.11, 0.025)
	for i in anzahl:
		var s := Scherbe.new()
		s.knoten = MeshInstance3D.new()
		s.knoten.mesh = _scherbennetz
		s.knoten.material_override = _stoff
		s.knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.knoten.top_level = true
		add_child(s.knoten)
		var richtung := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.0),
				randf_range(-1.0, 1.0)).normalized()
		s.knoten.global_position = _ort + richtung * 0.08
		s.knoten.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		s.tempo = richtung * wucht * randf_range(0.6, 1.0)
		s.drall = Vector3(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
		_scherben.append(s)


func _scherben_fuehren(delta: float) -> void:
	for i in range(_scherben.size() - 1, -1, -1):
		var s := _scherben[i]
		s.alter += delta
		if s.alter >= SCHERBEN_DAUER or not is_instance_valid(s.knoten):
			if is_instance_valid(s.knoten):
				s.knoten.queue_free()
			_scherben.remove_at(i)
			continue
		s.tempo.y -= 12.0 * delta
		s.knoten.global_position += s.tempo * delta
		s.knoten.rotation += s.drall * delta
		s.knoten.scale = Vector3.ONE * (1.0 - smoothstep(0.5, 1.0, s.alter / SCHERBEN_DAUER))


func _halt_ablauf() -> void:
	if _ablauf != null and _ablauf.is_valid():
		_ablauf.kill()
	_ablauf = null
	_groesse = 1.0


# ------------------------------------------------------------------ Aufbau

## Maske (eine Schale mit leuchtendem Rand, Stirnstein, Augen, Wangen-
## strichen, Lächeln und einem Blatt obenauf), zwei durchscheinende
## Flügel und der Hof. Drei Draw-Calls, gleich bei welcher Stufe.
func _baue() -> void:
	_geist = Node3D.new()
	_geist.name = "Geist"
	add_child(_geist)

	_stoff = ShaderMaterial.new()
	_stoff.shader = _shader("maske", MASKE_CODE)
	_stoff.set_shader_parameter("farbe", FARBE)
	var maske := MeshInstance3D.new()
	maske.name = "Maske"
	maske.mesh = _maskennetz()
	maske.material_override = _stoff
	maske.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_geist.add_child(maske)

	_fluegel_stoff = ShaderMaterial.new()
	_fluegel_stoff.shader = _shader("fluegel", FLUEGEL_CODE)
	_fluegel_stoff.set_shader_parameter("farbe", FARBE.lightened(0.35))
	var fluegel := MeshInstance3D.new()
	fluegel.name = "Fluegel"
	fluegel.mesh = _fluegelnetz()
	fluegel.material_override = _fluegel_stoff
	fluegel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_geist.add_child(fluegel)

	_schein_stoff = ShaderMaterial.new()
	_schein_stoff.shader = _shader("schein", SCHEIN_CODE)
	_schein_stoff.set_shader_parameter("farbe", FARBE)
	_schein = MeshInstance3D.new()
	_schein.name = "Hof"
	_schein.mesh = _scheinnetz()
	_schein.material_override = _schein_stoff
	_schein.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Die Fläche wird im Shader zur Kamera gedreht und vergrößert; ohne
	# erweiterte Hülle fiele sie am Bildrand zu früh aus dem Bild.
	_schein.extra_cull_margin = 1.5
	add_child(_schein)


## Schale: Farbe aus der Eckfarbe (sRGB), Art im Alpha – 1 Schale,
## 0,5 Zier (leuchtet mit der Stufe), 0 Augen und Stirnstein (leuchten
## am stärksten). Ein Saum in der Schutzfarbe umgibt die Silhouette.
const MASKE_CODE := """
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 farbe : source_color = vec4(0.3, 0.68, 0.95, 1.0);
uniform float leuchten = 1.0;

void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	float zier = 1.0 - smoothstep(0.6, 0.9, COLOR.a);
	float auge = 1.0 - smoothstep(0.1, 0.3, COLOR.a);
	ALBEDO = c;
	ROUGHNESS = 0.28;
	SPECULAR = 0.6;
	float saum = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	EMISSION = c * zier * (0.15 + leuchten * 0.9) + c * auge * (0.4 + leuchten * 1.1)
			+ farbe.rgb * saum * (0.15 + leuchten * 0.45);
}
"""

## Flügel: durchscheinend, additiv, am Rand heller. Sie schlagen im
## Vertex-Shader um ihre Wurzel – kein Knoten muss dafür bewegt werden.
const FLUEGEL_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float leuchten = 1.0;

void vertex() {
	float seite = sign(VERTEX.x);
	vec3 wurzel = vec3(0.08 * seite, 0.04, 0.05);
	vec3 p = VERTEX - wurzel;
	float w = (0.25 + 0.6 * sin(TIME * 42.0)) * seite;
	float c = cos(w);
	float s = sin(w);
	VERTEX = wurzel + vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

void fragment() {
	float rand = 1.0 - abs(dot(NORMAL, VIEW));
	ALBEDO = farbe.rgb * (0.12 + 0.55 * rand * rand) * (0.6 + 0.4 * leuchten);
}
"""

## Hof: eine Fläche, im Shader zur Kamera gedreht und ein Stück hinter den
## Geist geschoben (die Maske bleibt davor sichtbar). Kern und Hof weich,
## ab Stufe 3 ein langsam drehender Strahlenkranz und sechs Funken, die
## auf einem Kreis nacheinander aufblinken. Additiv, also auch ohne Glow
## ein Leuchten.
const SCHEIN_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(0.3, 0.68, 0.95, 1.0);
uniform float staerke = 0.5;
uniform float strahlen = 0.0;
uniform float groesse = 1.0;

varying vec2 q;

void vertex() {
	q = VERTEX.xy * 2.0;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[3].z -= 0.25;
	VERTEX.xy *= groesse;
}

void fragment() {
	float r = length(q);
	float kern = exp(-r * r * 10.0);
	float hof = exp(-r * r * 3.5) * 0.4;
	float winkel = atan(q.y, q.x);
	float strahl = pow(abs(cos(winkel * 3.0 + TIME * 0.6)), 24.0)
			+ 0.6 * pow(abs(cos(winkel * 2.0 - TIME * 0.9)), 40.0);
	strahl *= (1.0 - smoothstep(0.1, 0.95, r)) * strahlen;
	float funken = 0.0;
	for (int i = 0; i < 6; i++) {
		float w = float(i) * 1.0472 + TIME * 0.8;
		vec2 m = vec2(cos(w), sin(w)) * (0.5 + 0.08 * sin(TIME * 2.0 + float(i)));
		vec2 d = q - m;
		float blinken = max(sin(TIME * 5.0 + float(i) * 2.3), 0.0);
		funken += exp(-dot(d, d) * 700.0) * blinken;
	}
	float rand = 1.0 - smoothstep(0.8, 1.0, r);
	ALBEDO = (farbe.rgb * (kern + hof) * staerke + (farbe.rgb + vec3(0.35)) * strahl * 0.5
			+ vec3(0.9, 1.0, 1.0) * funken * strahlen * 1.4) * rand;
}
"""

static var _shader_vorrat: Dictionary = {}
static var _maske: ArrayMesh = null
static var _fluegel: ArrayMesh = null
static var _hofnetz: QuadMesh = null


static func _shader(name: String, code: String) -> Shader:
	if not _shader_vorrat.has(name):
		var s := Shader.new()
		s.code = code
		_shader_vorrat[name] = s
	return _shader_vorrat[name]


static func _maskennetz() -> ArrayMesh:
	if _maske != null:
		return _maske
	var f := Netzbau.new()
	# Schale: hinten tiefer blau, vorn porzellanhell
	f.teil(_kugel(0.16, 32, 20), _lage(Vector3.ZERO, Vector3(1.0, 1.2, 0.48)), SCHALE, 1.0,
			func(_p: Vector3, n: Vector3, grund: Color) -> Color:
				return grund.lerp(FARBE.lightened(0.35), smoothstep(-0.2, 0.6, n.z)))
	# Rückenzeichen: Von hinten – so sieht man ihn beim Laufen meist – ein
	# leuchtender Kringel mit Punkt, damit er dort kein leeres Ei ist.
	var kringel := TorusMesh.new()
	kringel.inner_radius = 0.055
	kringel.outer_radius = 0.072
	kringel.rings = 24
	kringel.ring_segments = 6
	f.teil(kringel, _lage(Vector3(0.0, 0.01, 0.07), Vector3(1.0, 1.0, 1.15),
			Vector3(PI * 0.5, 0.0, 0.0)), FARBE, 0.5)
	f.teil(_kugel(0.025, 12, 6), _lage(Vector3(0.0, 0.01, 0.075)), AUGE, 0.0)
	# Leuchtender Rand um das Gesicht
	var rand := TorusMesh.new()
	rand.inner_radius = 0.15
	rand.outer_radius = 0.174
	rand.rings = 40
	rand.ring_segments = 8
	f.teil(rand, _lage(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.2), Vector3(PI * 0.5, 0.0, 0.0)),
			FARBE, 0.5)
	# Stirnstein
	f.teil(_kugel(0.032, 14, 8), _lage(Vector3(0.0, 0.125, -0.06)), AUGE, 0.0)
	for seite: float in [1.0, -1.0]:
		# Augen: mandelförmig, leuchtend, außen leicht nach unten
		f.teil(_kugel(0.038, 16, 8), _lage(Vector3(0.058 * seite, 0.02, -0.068),
				Vector3(1.35, 0.8, 0.45), Vector3(0.0, 0.0, 0.25 * seite)), AUGE, 0.0)
		# Wangenstriche
		f.teil(_kugel(0.018, 10, 6), _lage(Vector3(0.1 * seite, -0.045, -0.058),
				Vector3(1.8, 0.55, 0.5), Vector3(0.0, 0.0, -0.3 * seite)), FARBE, 0.5)
	# Lächeln
	for i in 7:
		var s := float(i) / 3.0 - 1.0
		var x := 0.04 * s
		var y := -0.085 + 0.018 * s * s
		var tiefe := 1.0 - pow(x / 0.16, 2.0) - pow(y / 0.192, 2.0)
		f.teil(_kugel(0.009, 8, 4), _lage(Vector3(x, y, -0.077 * sqrt(maxf(tiefe, 0.0)) + 0.003)),
				MUND, 0.6)
	# Blatt obenauf: ein Stiel und ein Blatt, leicht zur Seite gebogen
	f.teil(_kegel(0.016, 0.006, 0.07), _lage(Vector3(0.0, 0.215, 0.0), Vector3.ONE,
			Vector3(0.0, 0.0, -0.3)), FARBE, 0.5)
	f.teil(_kugel(0.05, 14, 8), _lage(Vector3(0.04, 0.25, 0.0), Vector3(1.4, 0.45, 0.28),
			Vector3(0.0, 0.0, 0.55)), FARBE.lightened(0.25), 0.5)
	_maske = f.netz()
	return _maske


static func _fluegelnetz() -> ArrayMesh:
	if _fluegel != null:
		return _fluegel
	var f := Netzbau.new()
	for seite: float in [1.0, -1.0]:
		f.teil(_kugel(0.12, 20, 10), _lage(Vector3(0.2 * seite, 0.06, 0.05),
				Vector3(1.35, 0.6, 0.06), Vector3(0.0, -0.35 * seite, 0.3 * seite)), Color.WHITE, 1.0)
	_fluegel = f.netz()
	return _fluegel


static func _scheinnetz() -> QuadMesh:
	if _hofnetz == null:
		_hofnetz = QuadMesh.new()
		_hofnetz.size = Vector2(1.0, 1.0)
	return _hofnetz


static func _lage(pos: Vector3, skala := Vector3.ONE, drehung := Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(drehung) * Basis.from_scale(skala), pos)


static func _kugel(radius: float, segmente: int, ringe: int) -> SphereMesh:
	var netz := SphereMesh.new()
	netz.radius = radius
	netz.height = radius * 2.0
	netz.radial_segments = segmente
	netz.rings = ringe
	return netz


static func _kegel(unten: float, oben: float, hoehe: float) -> CylinderMesh:
	var netz := CylinderMesh.new()
	netz.bottom_radius = unten
	netz.top_radius = oben
	netz.height = hoehe
	netz.radial_segments = 8
	netz.rings = 1
	return netz


## Verschmilzt Grundformen zu einem Netz mit Eckfarben (wie die Glieder
## des Beuteldachses, siehe `SpielerModell.Form`).
class Netzbau:
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var farben := PackedColorArray()
	var indizes := PackedInt32Array()

	func teil(netz: PrimitiveMesh, lage: Transform3D, farbe: Color, art: float,
			maler: Callable = Callable()) -> void:
		var daten := netz.get_mesh_arrays()
		var e: PackedVector3Array = daten[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = daten[Mesh.ARRAY_NORMAL]
		var ii: PackedInt32Array = daten[Mesh.ARRAY_INDEX]
		var nbasis := lage.basis.inverse().transposed()
		var start := ecken.size()
		for k in e.size():
			var p := lage * e[k]
			var n := (nbasis * nn[k]).normalized()
			var c := farbe
			if maler.is_valid():
				c = maler.call(p, n, farbe)
			ecken.append(p)
			normalen.append(n)
			farben.append(Color(c.r, c.g, c.b, art))
		for k in ii.size():
			indizes.append(start + ii[k])

	func netz() -> ArrayMesh:
		var daten := []
		daten.resize(Mesh.ARRAY_MAX)
		daten[Mesh.ARRAY_VERTEX] = ecken
		daten[Mesh.ARRAY_NORMAL] = normalen
		daten[Mesh.ARRAY_COLOR] = farben
		daten[Mesh.ARRAY_INDEX] = indizes
		var ergebnis := ArrayMesh.new()
		ergebnis.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, daten)
		return ergebnis
