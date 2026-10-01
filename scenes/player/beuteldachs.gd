extends Node3D
class_name SpielerModell
## Darstellung des Beuteldachses.
##
## Der Player-Controller kennt nur diese Schnittstelle und weiß nichts
## über den Aufbau des Modells:
##   aktualisiere()  – jeden Frame, überträgt den Bewegungszustand
##   setze_blick()   – Blickrichtung in Radiant um die Y-Achse
##   sichtbarkeit()  – Blinken während der Unverwundbarkeit
##   stoss()         – Stauchen/Strecken bei Absprung, Landung, Abprall
##   kneifen()       – Augen kurz zukneifen (Treffer, Aufschlag)
##
## Das Modell wird prozedural aus Godot-Primitiven aufgebaut, es werden
## keine fremden Asset-Dateien benötigt.
##
## Aufbau (alles hängt unter `_koerper`, damit eine Haltung des Rumpfes
## – Bauchrutschen, Krabbeln – die ganze Figur mitnimmt):
##   Teile
##     Koerper (Rumpf, Bauch, Halstuch)  – Ursprung auf Hüfthöhe, y = 0.7
##       Kopf (Schädel, Schnauze, Augen, Brauen, Schopf) mit Lidern, Ohren
##       Arme (mit Händen), Beine (mit Füßen), Schweif (mit Spitze),
##       Tuchzipfel
##     SpinRing                 – Geschwister, damit ihn der Rumpf nicht kippt
##
## Jedes starre Glied ist EIN Netz: Die Grundformen eines Glieds (Kugeln,
## Kapseln, Kegel) werden beim ersten Bau zu einem Netz mit Eckfarben
## verschmolzen und für alle weiteren Figuren aufgehoben. Die Zeichnung
## im Fell – heller Bauch, Brille ums Auge, Streifen auf dem Rücken und
## am Schweif – steckt in den Eckfarben. Alle Glieder teilen einen Stoff
## (`FELL_CODE`). Vorher waren es rund 50 Einzelteile mit je eigenem
## Draw-Call (und noch einmal so viele im Schatten), jetzt sind es 15.
##
## `Teile` selbst trägt das Stauchen und Strecken aus `stoss()`: Sein
## Ursprung liegt auf Fußhöhe, die Füße bleiben also am Boden, und es
## beißt sich weder mit der Haltung des Rumpfes noch mit dem Halter
## einer eigenen Figur noch mit dem Portal, das den Modellknoten schrumpft.
##
## Maße: Füße auf y = 0, Scheitel bei 1,36 m, Ohrenspitzen bei ca. 1,48 m,
## Breite ca. 0,75 m – passt damit in die Kollisionskapsel (Radius 0.38 /
## Höhe 1.3); nur die Ohren ragen wie bisher darüber hinaus.
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
const OHR_SPREIZUNG := 0.30  ## Grundneigung der Ohren nach außen
## Die Arme hängen leicht abgespreizt: Der Bauch ist rund, gerade nach
## unten steckten sie in ihm.
const ARM_RUHE := 0.30
const ARM_SPIN := 1.45       ## Arme waagerecht beim Spin
## Der Schweif schwingt etwas zur Seite: Von hinten – aus der Spielkamera –
## verdeckt er so nicht den ganzen Rücken samt Halstuchzipfel.
const SCHWEIF_SEITE := 0.35
const ARM_LUFT := 2.65       ## Arme schräg nach oben in der Luft

# --- Stauchen und Strecken (`stoss()`) ---
## Gedämpfte Feder: Eigenfrequenz rund 15 rad/s, Dämpfungsmaß rund 0,47.
## Das federt einmal sichtbar nach wie im Zeichentrick und ist nach gut
## 0,4 s abgeklungen – bevor der nächste Sprung ansetzt.
const STAUCH_FEDER := 220.0
const STAUCH_BREMSE := 14.0
## Weiter lässt sich die Figur nicht verformen. Mehr sieht nach Gummi aus.
const STAUCH_GRENZE := 0.45

## So schnell wechselt der Rumpf in eine liegende Haltung (Slide,
## Krabbeln) und zurück. Bei 25/s dauert der Übergang rund 0,1 s –
## schnell genug für einen Slide von 0,42 s.
const SLIDE_WECHSEL := 25.0

const BLINZ_DAUER := 0.14    ## ein Lidschlag in Sekunden

# --- Farben ---
## Warmes Orange mit cremefarbenen Flächen und dunkelbrauner Zeichnung,
## dazu ein türkises Halstuch als Gegenfarbe: Auf dem grünen Waldweg und
## vor braunen Stämmen soll die Figur auch klein im Bild sofort auffallen.
const FELL := Color(0.98, 0.62, 0.24)
const FELL_HELL := Color(1.0, 0.92, 0.74)
const FELL_DUNKEL := Color(0.50, 0.25, 0.10)
const PFOTE := Color(0.56, 0.31, 0.15)
const SOHLE := Color(0.86, 0.66, 0.48)
const INNENOHR := Color(0.98, 0.66, 0.58)
const NASE := Color(0.09, 0.06, 0.06)
const AUGWEISS := Color(0.99, 0.98, 0.95)
const IRIS := Color(0.30, 0.58, 0.22)
const TUCH := Color(0.16, 0.74, 0.78)

## Art einer Fläche, steckt im Alpha der Eckfarbe (siehe `FELL_CODE`).
const ART_FELL := 1.0
const ART_GLATT := 0.5       ## Augen, Nase, Tuch: glatt und glänzend
const ART_LICHT := 0.0       ## Glanzpunkt im Auge: leuchtet ein wenig

var _blick := 0.0
var _spin_alpha := 0.0
var _lauf_phase := 0.0
## Auslenkung der Stauchfeder: > 0 gestaucht, < 0 gestreckt.
var _stauch := 0.0
var _stauch_v := 0.0
## 0 = aufrecht, 1 = liegend (Slide, Krabbeln) – weich nachgeführt.
var _slide_grad := 0.0
## Weich nachgeführte Höhe des Rumpfes (Hocke im Sitzen, Strecken am Gitter).
var _rumpf_hoehe := RUMPF_Y
## Wie weit die Arme gestreckt sind (1 = normal, am Gitter länger).
var _streck := 1.0

var _koerper: Node3D
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
var _clip_hangeln_geduckt := ""
var _clip_hangeln_spin := ""
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
## Oberarm und Hand je Seite: Am Gitter wird der Oberarm gestreckt und die
## Hand rückt ans Ende, ohne selbst mitgezogen zu werden.
var _oberarme: Array[Node3D] = []
var _haende: Array[Node3D] = []
var _bein_links: Node3D
var _bein_rechts: Node3D
var _schweif: Node3D
var _schweif_spitze: Node3D
var _zipfel: Node3D

# --- Zustand der Animation ---
var _zeit := 0.0             ## Laufende Zeit für Atmen und Zucken
var _atem := 0.0             ## 0 = bewegt, 1 = ruhig atmend
var _zuck := 0.0             ## Restzeit des Ohrenzuckens
var _zuck_pause := 3.0       ## Zeit bis zum nächsten Ohrenzucken
var _lider: Array[MeshInstance3D] = []
var _blinz := 0.0            ## Restzeit des laufenden Lidschlags
var _blinz_pause := 3.0      ## Zeit bis zum nächsten Lidschlag
var _kneifen := 0.0          ## Restzeit des Zukneifens
var _lid_zu := -1.0          ## zuletzt gesetzter Schluss der Lider


func _ready() -> void:
	# Die Figur wird im Bildtakt bewegt (`aktualisiere()` aus `_process`,
	# Tweens, Clips) und hängt an einem Körper, der sich im Physiktakt
	# bewegt. Interpoliert wird nur der Körper; das Modell folgt ihm weich
	# und zeigt seine eigene Bewegung genau so, wie sie gesetzt wurde. Mit
	# Interpolation zitterten Arme, Beine und Ohren (ARCHITEKTUR.md,
	# „Bildtakt und Physiktakt").
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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


## Baut den Beuteldachs aus seinen Gliedern auf.
##
## Silhouette: großer runder Kopf mit Wangenbüscheln und hohen Ohren,
## birnenförmiger Rumpf, kurze kräftige Beine mit großen Füßen und ein
## buschiger, geringelter Schweif. Von hinten – so sieht man die Figur
## fast immer – tragen Schweif, Rückenstreifen, Ohren und der Zipfel des
## Halstuchs die Form.
func _baue() -> void:
	_teile = Node3D.new()
	_teile.name = "Teile"
	add_child(_teile)

	_koerper = _glied(_teile, "Koerper", _netz("rumpf", _form_rumpf),
			Vector3(0.0, RUMPF_Y, 0.0))

	_zipfel = _glied(_koerper, "Tuchzipfel", _netz("zipfel", _form_zipfel),
			Vector3(0.0, 0.24, 0.19), false)

	_kopf = _glied(_koerper, "Kopf", _netz("kopf", _form_kopf), Vector3(0.0, 0.35, -0.02))
	for seite: float in [1.0, -1.0]:
		var auge := Node3D.new()
		auge.name = "Auge%s" % _kuerzel(seite)
		auge.transform = _augenlage(seite)
		_kopf.add_child(auge)
		var lid := _glied(auge, "Lid", _netz("lid", _form_lid), Vector3.ZERO, false)
		_lider.append(lid as MeshInstance3D)
	_lider_setzen(0.0)

	_ohr_rechts = _baue_ohr(1.0)
	_ohr_links = _baue_ohr(-1.0)
	_arm_rechts = _baue_arm(1.0)
	_arm_links = _baue_arm(-1.0)
	_bein_rechts = _glied(_koerper, "BeinR", _netz("bein", _form_bein),
			Vector3(0.14, -0.30, 0.0))
	_bein_links = _glied(_koerper, "BeinL", _netz("bein", _form_bein),
			Vector3(-0.14, -0.30, 0.0))
	_schweif = _glied(_koerper, "Schweif", _netz("schweif", _form_schweif),
			Vector3(0.0, -0.24, 0.22))
	_schweif_spitze = _glied(_schweif, "Spitze", _netz("spitze", _form_spitze),
			Vector3(0.0, 0.09, 0.29))

	_baue_spin_ring()


func _baue_ohr(seite: float) -> Node3D:
	var ohr := _glied(_kopf, "Ohr%s" % _kuerzel(seite), _netz("ohr", _form_ohr),
			Vector3(0.155 * seite, 0.20, 0.035))
	ohr.rotation = Vector3(OHR_RUHE, 0.0, -OHR_SPREIZUNG * seite)
	return ohr


func _baue_arm(seite: float) -> Node3D:
	var gelenk := Node3D.new()
	gelenk.name = "Arm%s" % _kuerzel(seite)
	gelenk.position = Vector3(0.255 * seite, 0.15, -0.01)
	gelenk.rotation.z = ARM_RUHE * seite
	_koerper.add_child(gelenk)
	_oberarme.append(_glied(gelenk, "Oberarm", _netz("arm", _form_arm)))
	var hand := "hand_r" if seite > 0.0 else "hand_l"
	_haende.append(_glied(gelenk, "Hand", _netz(hand,
			func(f: Form) -> void: _form_hand(f, seite)), Vector3(0.0, -0.29, 0.0)))
	return gelenk


static func _kuerzel(seite: float) -> String:
	return "R" if seite > 0.0 else "L"


## Spin-Ring: Geschwister des Rumpfes, damit ihn der Slide-Stauch nicht
## verzerrt. Auch eine eigene Figur bekommt ihn – sonst fehlte die einzige
## Rückmeldung, dass der Drehschlag gerade wirkt.
##
## Der Ring ist kein gleichmäßiger Reif, sondern zwei Schlieren mit heller
## Vorderkante (siehe `WIRBEL_CODE`). Weil er mit der Figur herumwirbelt
## (SPIN_DREHUNG, knapp fünf Umdrehungen je Sekunde), liest sich das als
## Bewegungsunschärfe eines Schlags – ein Donut läse sich als Schild.
func _baue_spin_ring() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.77
	ring.outer_radius = 0.93
	# Mehr Stücke im Umfang: Der Verlauf der Schliere läuft um den Ring
	# herum und bräuchte sonst sichtbare Kanten. Der Schlauch selbst ist
	# dünn und kommt mit wenigen aus.
	ring.rings = 48
	ring.ring_segments = 8
	_spin_ring = MeshInstance3D.new()
	_spin_ring.name = "SpinRing"
	_spin_ring.mesh = ring
	_spin_ring.position.y = 0.6
	_spin_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Eigenes Material je Modell (die Deckkraft ist Zustand dieser Figur),
	# der Shader darunter ist geteilt und wird nur einmal übersetzt.
	var stoff := ShaderMaterial.new()
	stoff.shader = _wirbel_shader()
	stoff.set_shader_parameter("farbe", Farben.SPIN_RING)
	stoff.set_shader_parameter("deckkraft", 0.0)
	_spin_ring.material_override = stoff
	# Unsichtbar starten: `aktualisiere()` blendet ihn beim Drehschlag ein.
	# Ausgeblendet ist er wirklich aus – mit Deckkraft 0 kostete er sonst
	# jedes Bild einen Draw-Call für nichts.
	_spin_ring.visible = false
	_teile.add_child(_spin_ring)


## Schlieren des Spin-Rings. Ohne Bild- und Tiefentextur, also auch unter
## gl_compatibility und im Browser. Der Winkel wird je Pixel gerechnet und
## nicht je Ecke: Am Sprung von 1 auf 0 verschmierte ein Ecken-Varying
## sonst quer über ein ganzes Dreieck.
const WIRBEL_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.88, 0.4, 1.0);
uniform float deckkraft = 0.0;

varying vec2 eben;

void vertex() {
	eben = VERTEX.xz;
}

void fragment() {
	// 0..1 je halbem Umlauf in Drehrichtung: zwei Schlieren, deren helles
	// Ende vorausläuft und deren Schweif ausblasst.
	float a = fract(atan(-eben.y, eben.x) / 3.14159265);
	float schliere = a * a * a;
	ALBEDO = mix(farbe.rgb, vec3(1.0, 0.98, 0.9), schliere * 0.6);
	ALPHA = deckkraft * (0.08 + 0.92 * schliere);
}
"""

static var _wirbel: Shader = null


static func _wirbel_shader() -> Shader:
	if _wirbel == null:
		_wirbel = Shader.new()
		_wirbel.code = WIRBEL_CODE
	return _wirbel


## Der Stoff aller Glieder. Farbe und Art kommen aus der Eckfarbe:
## rgb ist die Farbe (sRGB), Alpha die Art der Fläche – 1 Fell, 0,5 glatt
## (Augen, Nase, Tuch), 0 Glanzpunkt.
##
## Fell: zwei Lagen Rauschen aus der Lage im Glied (keine Textur, keine
## UV), längs gestreckt wie Strähnen; Unterseiten etwas dunkler, an der
## Silhouette ein weicher Saum, wie ihn Fell im Gegenlicht zeigt. Alles
## ohne Bild- und Tiefentextur, läuft also unter gl_compatibility.
const FELL_CODE := """
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

varying vec3 lage;

float zufall(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float rauschen(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(zufall(i), zufall(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(zufall(i + vec3(0.0, 1.0, 0.0)), zufall(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(zufall(i + vec3(0.0, 0.0, 1.0)), zufall(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(zufall(i + vec3(0.0, 1.0, 1.0)), zufall(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

void vertex() {
	lage = VERTEX;
}

void fragment() {
	vec3 farbe = pow(COLOR.rgb, vec3(2.2));
	float fell = smoothstep(0.7, 0.9, COLOR.a);
	float licht = 1.0 - smoothstep(0.1, 0.3, COLOR.a);
	float glatt = (1.0 - fell) * (1.0 - licht);
	float n = rauschen(lage * vec3(34.0, 12.0, 34.0)) * 0.65 + rauschen(lage * 90.0) * 0.35;
	farbe *= mix(1.0, 0.84 + 0.28 * n, fell);
	vec3 welt_n = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	farbe *= mix(1.0, mix(0.74, 1.04, smoothstep(-0.8, 0.7, welt_n.y)), fell);
	ALBEDO = farbe;
	ROUGHNESS = mix(0.2, 0.8, fell);
	SPECULAR = mix(0.7, 0.3, fell);
	float saum = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = farbe * (saum * 0.35 * fell + glatt * 0.08 + licht * 1.5);
}
"""

static var _fell_stoff: ShaderMaterial = null
## Verschmolzene Netze je Glied, für alle Figuren geteilt und nie verändert.
static var _netze: Dictionary = {}


static func _stoff() -> ShaderMaterial:
	if _fell_stoff == null:
		var shader := Shader.new()
		shader.code = FELL_CODE
		_fell_stoff = ShaderMaterial.new()
		_fell_stoff.shader = shader
	return _fell_stoff


## Das Netz eines Glieds; beim ersten Mal von `bau` aus Grundformen
## zusammengesetzt, danach aus dem Vorrat.
func _netz(name: String, bau: Callable) -> ArrayMesh:
	if not _netze.has(name):
		var form := Form.new()
		bau.call(form)
		_netze[name] = form.netz()
	return _netze[name]


## Hängt ein Glied (Netz im Fellstoff) unter den Elternteil.
func _glied(elternteil: Node3D, bezeichnung: String, netz: Mesh,
		pos := Vector3.ZERO, schatten := true) -> MeshInstance3D:
	var teil := MeshInstance3D.new()
	teil.name = bezeichnung
	teil.mesh = netz
	teil.material_override = _stoff()
	teil.position = pos
	if not schatten:
		teil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(teil)
	return teil


## Sammelt Grundformen zu EINEM Netz mit Eckfarben. Ein Maler (optional)
## bekommt Ort, Normale (beides im Glied) und Grundfarbe jeder Ecke und
## gibt ihre Farbe zurück – so entsteht die Zeichnung im Fell.
class Form:
	var ecken := PackedVector3Array()
	var normalen := PackedVector3Array()
	var farben := PackedColorArray()
	var indizes := PackedInt32Array()

	func teil(netz: PrimitiveMesh, lage: Transform3D, farbe: Color,
			art: float = ART_FELL, maler: Callable = Callable()) -> void:
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


## Verwandlung einer Grundform: erst skaliert, dann gedreht, dann versetzt.
static func _lage(pos: Vector3, skala := Vector3.ONE, drehung := Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(drehung) * Basis.from_scale(skala), pos)


static func _kugel(radius: float, segmente := 24, ringe := 12) -> SphereMesh:
	var netz := SphereMesh.new()
	netz.radius = radius
	netz.height = radius * 2.0
	netz.radial_segments = segmente
	netz.rings = ringe
	return netz


static func _kapsel(radius: float, hoehe: float, segmente := 18) -> CapsuleMesh:
	var netz := CapsuleMesh.new()
	netz.radius = radius
	netz.height = maxf(hoehe, radius * 2.0)
	netz.radial_segments = segmente
	netz.rings = 6
	return netz


## Kegelstumpf entlang +Y (unten breit, oben spitz).
static func _kegel(unten: float, oben: float, hoehe: float, segmente := 14) -> CylinderMesh:
	var netz := CylinderMesh.new()
	netz.bottom_radius = unten
	netz.top_radius = oben
	netz.height = hoehe
	netz.radial_segments = segmente
	netz.rings = 3
	return netz


# ------------------------------------------------------------- Die Glieder

## Rumpf: birnenförmig aus Bauch und Brust, ein Hals, der in den Kopf
## übergeht, und das Halstuch mit Knoten. Bemalt mit hellem Bauch und drei
## Streifen quer über den Rücken.
func _form_rumpf(f: Form) -> void:
	f.teil(_kugel(0.29, 48, 36), _lage(Vector3(0.0, -0.10, 0.01), Vector3(0.94, 0.98, 0.9)),
			FELL, ART_FELL, _male_rumpf.bind(true))
	f.teil(_kugel(0.235, 40, 24), _lage(Vector3(0.0, 0.13, -0.01), Vector3(1.08, 0.95, 0.92)),
			FELL, ART_FELL, _male_rumpf.bind(false))
	f.teil(_kugel(0.15, 20, 10), _lage(Vector3(0.0, 0.29, -0.02)), FELL)
	# Halstuch: Wulst um den Hals, vorn ein Knoten
	var tuch := TorusMesh.new()
	tuch.inner_radius = 0.175
	tuch.outer_radius = 0.255
	tuch.rings = 32
	tuch.ring_segments = 10
	f.teil(tuch, _lage(Vector3(0.0, 0.245, -0.01), Vector3(1.0, 1.0, 0.94),
			Vector3(0.12, 0.0, 0.0)), TUCH)
	f.teil(_kugel(0.042, 14, 8), _lage(Vector3(0.0, 0.215, -0.245), Vector3(1.3, 0.9, 0.8)),
			TUCH)


func _male_rumpf(p: Vector3, n: Vector3, grund: Color, hinten_tiefer: bool) -> Color:
	var c := grund
	# Heller Bauch: ein Oval vorn mit weichem Rand
	var oval := pow(p.x / 0.175, 2.0) + pow((p.y + 0.10) / 0.26, 2.0)
	var bauch := (1.0 - smoothstep(0.7, 1.05, oval)) * smoothstep(0.05, 0.4, -n.z)
	c = c.lerp(FELL_HELL, bauch)
	# Rücken etwas dunkler, zur Mitte hin am meisten: ein weicher Sattel,
	# der den Rumpf von hinten rund macht. (Streifen quer über den Rücken
	# zerfransten in den Eckfarben und lasen sich als Kritzelei; die Ringe
	# trägt jetzt allein der Schweif.)
	var sattel := smoothstep(0.2, 0.8, n.z) * (1.0 - smoothstep(0.05, 0.2, absf(p.x)))
	return c.lerp(c.darkened(0.25), sattel * (0.6 if hinten_tiefer else 1.0))


## Kopf: Schädel mit heller Brille um die Augen, Wangen mit Büscheln,
## lange Schnauze mit glänzender Nase und einem Lächeln, große Augen
## (Weiß, Iris, Pupille, zwei Glanzpunkte), kräftige Brauen und ein Schopf.
## Die Lider sind eigene Glieder (`_form_lid`), sie blinzeln.
func _form_kopf(f: Form) -> void:
	f.teil(_kugel(0.25, 48, 32), _lage(Vector3(0.0, 0.07, 0.0), Vector3(1.08, 0.97, 1.0)),
			FELL, ART_FELL, _male_schaedel)

	for seite: float in [1.0, -1.0]:
		# Wangen und Wangenbüschel: geben dem Kopf Breite und Witz
		f.teil(_kugel(0.1, 20, 10), _lage(Vector3(0.165 * seite, -0.04, -0.07),
				Vector3(0.95, 0.8, 1.0)), FELL_HELL)
		f.teil(_kegel(0.06, 0.0, 0.13, 10), _lage(Vector3(0.25 * seite, -0.05, -0.03),
				Vector3.ONE, Vector3(0.0, 0.0, -1.95 * seite)), FELL_HELL)
		f.teil(_kegel(0.045, 0.0, 0.10, 10), _lage(Vector3(0.235 * seite, 0.0, 0.02),
				Vector3.ONE, Vector3(0.0, 0.0, -1.55 * seite)), FELL)

	# Schnauze: hell, mit orangem Nasenrücken
	f.teil(_kugel(0.13, 32, 20), _lage(Vector3(0.0, -0.045, -0.235), Vector3(0.92, 0.72, 1.45)),
			FELL_HELL, ART_FELL, _male_schnauze)
	f.teil(_kugel(0.052, 20, 12), _lage(Vector3(0.0, -0.005, -0.415), Vector3(1.3, 0.85, 0.9)),
			NASE, ART_GLATT)
	# Lächeln: eine Kette kleiner Punkte auf der Schnauze, die Winkel oben
	for i in 15:
		var s := float(i) / 7.0 - 1.0
		var x := 0.07 * s
		var y := -0.098 + 0.024 * s * s
		var tiefe := 1.0 - pow(x / 0.12, 2.0) - pow((y + 0.045) / 0.094, 2.0)
		var z := -0.235 - 0.1885 * sqrt(maxf(tiefe, 0.0)) + 0.006
		f.teil(_kugel(0.011, 8, 4), _lage(Vector3(x, y, z), Vector3(1.4, 1.0, 0.8)), NASE, ART_GLATT)

	for seite: float in [1.0, -1.0]:
		var auge := _augenlage(seite)
		f.teil(_kugel(0.07, 24, 16), auge, AUGWEISS, ART_GLATT)
		var innen := -0.012 * seite
		f.teil(_kugel(0.046, 20, 10), auge * _lage(Vector3(innen, 0.0, -0.058),
				Vector3(1.0, 1.0, 0.4)), IRIS, ART_GLATT, _male_iris)
		f.teil(_kugel(0.026, 16, 8), auge * _lage(Vector3(innen, -0.002, -0.0705),
				Vector3(1.0, 1.1, 0.35)), NASE, ART_GLATT)
		f.teil(_kugel(0.012, 10, 6), auge * _lage(Vector3(innen + 0.017, 0.02, -0.078)),
				Color.WHITE, ART_LICHT)
		f.teil(_kugel(0.006, 8, 4), auge * _lage(Vector3(innen - 0.012, -0.022, -0.078)),
				Color.WHITE, ART_LICHT)
		# Braue: kräftig, innen tiefer – ein entschlossener, frecher Blick
		f.teil(_kugel(0.05, 16, 8), _lage(Vector3(0.112 * seite, 0.245, -0.175),
				Vector3(1.7, 0.55, 0.62), Vector3(-0.35, 0.0, 0.26 * seite)), FELL_DUNKEL)

	# Schopf: drei Strähnen, nach hinten gekämmt, mit dunklen Spitzen
	for i in 3:
		var seitlich := float(i) - 1.0
		f.teil(_kegel(0.065, 0.0, 0.17, 10), _lage(Vector3(seitlich * 0.065, 0.28, -0.04),
				Vector3.ONE, Vector3(1.05 + absf(seitlich) * 0.15, 0.0, -seitlich * 0.5)),
				FELL, ART_FELL, _male_spitze.bind(0.36))


## Lage eines Auges im Kopf: Mitte, nach außen gedreht und gekippt, hoch-
## oval. Lid und Augapfel teilen sie, damit das Lid genau passt.
static func _augenlage(seite: float) -> Transform3D:
	return _lage(Vector3(0.105 * seite, 0.095, -0.2), Vector3(0.92, 1.18, 0.8),
			Vector3(0.0, -0.22 * seite, -0.10 * seite))


func _male_schaedel(p: Vector3, n: Vector3, grund: Color) -> Color:
	# Helle Brille um beide Augen und die untere Gesichtshälfte; die Stirn
	# bleibt orange und läuft als Spitze zwischen die Augen.
	var um_auge := Vector2(absf(p.x) - 0.105, (p.y - 0.095) * 0.85).length()
	var brille := 1.0 - smoothstep(0.1, 0.13, um_auge)
	var unten := 1.0 - smoothstep(-0.03, 0.02, p.y)
	var vorn := smoothstep(0.1, 0.4, -n.z)
	return grund.lerp(FELL_HELL, maxf(brille, unten) * vorn)


func _male_schnauze(p: Vector3, n: Vector3, grund: Color) -> Color:
	var steg := smoothstep(0.45, 0.8, n.y) * (1.0 - smoothstep(0.035, 0.07, absf(p.x)))
	return grund.lerp(FELL, steg)


func _male_iris(p: Vector3, _n: Vector3, grund: Color) -> Color:
	# Oben dunkler: Das Lid wirft dort seinen Schatten.
	return grund.lerp(grund.darkened(0.55), smoothstep(0.08, 0.16, p.y))


## Dunkle Spitze ab der Höhe `ab` (im Glied).
func _male_spitze(p: Vector3, _n: Vector3, grund: Color, ab: float) -> Color:
	return grund.lerp(FELL_DUNKEL, smoothstep(ab - 0.03, ab + 0.02, p.y))


## Lid: eine Fellschale etwas größer als der Augapfel, hell wie die Brille
## ums Auge, unten mit dunklem Wimpernrand. Offen ist sie flach nach oben geschoben, geschlossen
## umschließt sie das ganze Auge (`_lider_setzen`).
func _form_lid(f: Form) -> void:
	f.teil(_kugel(0.075, 24, 14), Transform3D.IDENTITY, FELL_HELL, ART_FELL,
			func(p: Vector3, _n: Vector3, grund: Color) -> Color:
				return grund.lerp(FELL_DUNKEL, 1.0 - smoothstep(-0.07, -0.05, p.y)))


## Ohr: rundes Blatt, außen orange mit dunkler Spitze, innen rosa.
func _form_ohr(f: Form) -> void:
	f.teil(_kugel(0.095, 20, 14), _lage(Vector3(0.0, 0.11, 0.0), Vector3(0.88, 1.4, 0.36)),
			FELL, ART_FELL, _male_spitze.bind(0.20))
	f.teil(_kugel(0.095, 16, 10), _lage(Vector3(0.0, 0.10, -0.02), Vector3(0.55, 1.0, 0.18)),
			INNENOHR)


func _form_arm(f: Form) -> void:
	f.teil(_kugel(0.08, 16, 10), Transform3D.IDENTITY, FELL)
	f.teil(_kapsel(0.058, 0.27), _lage(Vector3(0.0, -0.13, 0.0)), FELL)


## Hand: Fäustling mit Daumen, dunkel wie die Füße.
func _form_hand(f: Form, seite: float) -> void:
	f.teil(_kugel(0.072, 18, 10), _lage(Vector3(0.0, -0.03, 0.0), Vector3(0.85, 1.0, 1.05)), PFOTE)
	f.teil(_kugel(0.032, 10, 6), _lage(Vector3(-0.05 * seite, -0.005, -0.035)), PFOTE)


## Bein: kräftiger Schenkel, kurzer Unterschenkel und ein großer Fuß mit
## heller Sohle und drei Zehen.
func _form_bein(f: Form) -> void:
	f.teil(_kugel(0.11, 20, 12), _lage(Vector3(0.0, -0.06, 0.0), Vector3(0.92, 1.15, 0.98)), FELL)
	f.teil(_kapsel(0.065, 0.22), _lage(Vector3(0.0, -0.20, 0.0)), FELL)
	f.teil(_kugel(0.1, 24, 12), _lage(Vector3(0.0, -0.335, -0.07), Vector3(0.95, 0.62, 1.55)),
			PFOTE, ART_FELL,
			func(_p: Vector3, n: Vector3, grund: Color) -> Color:
				return grund.lerp(SOHLE, smoothstep(0.5, 0.8, -n.y)))
	for i in 3:
		var x := (float(i) - 1.0) * 0.045
		f.teil(_kugel(0.033, 10, 6), _lage(Vector3(x, -0.345, -0.205), Vector3(1.0, 0.8, 1.0)),
				PFOTE.lightened(0.12))


## Schweif: vom Hinterteil schräg nach hinten, geringelt.
func _form_schweif(f: Form) -> void:
	var ringe := _male_ringe.bind(Vector3(0.0, 0.3, 0.95).normalized(), 0.15)
	f.teil(_kugel(0.075, 18, 10), _lage(Vector3(0.0, 0.0, 0.03)), FELL, ART_FELL, ringe)
	f.teil(_kugel(0.1, 24, 16), _lage(Vector3(0.0, 0.04, 0.15), Vector3(1.0, 1.0, 1.55),
			Vector3(-0.3, 0.0, 0.0)), FELL, ART_FELL, ringe)


## Schweifspitze: ein dicker Busch, der nach oben schwingt, dunkles Ende.
func _form_spitze(f: Form) -> void:
	var ringe := _male_ringe.bind(Vector3(0.0, 0.95, 0.3).normalized(), 0.55)
	f.teil(_kugel(0.13, 28, 18), _lage(Vector3(0.0, 0.13, 0.03), Vector3(1.0, 1.45, 1.0),
			Vector3(0.3, 0.0, 0.0)), FELL, ART_FELL, ringe)
	f.teil(_kugel(0.085, 18, 10), _lage(Vector3(0.0, 0.31, 0.0), Vector3(1.0, 1.2, 1.0)),
			FELL_DUNKEL)


## Ringe quer zur Achse `achse` im Abstand von 0,15 m.
func _male_ringe(p: Vector3, _n: Vector3, grund: Color, achse: Vector3, versatz: float) -> Color:
	var s := fposmod(p.dot(achse) / 0.15 + versatz, 1.0)
	var ring := smoothstep(0.0, 0.08, s) * (1.0 - smoothstep(0.32, 0.4, s))
	return grund.lerp(FELL_DUNKEL, ring)


## Zipfel des Halstuchs: zwei Dreiecke, die im Nacken herabhängen und beim
## Laufen nach hinten flattern.
func _form_zipfel(f: Form) -> void:
	for seite: float in [1.0, -1.0]:
		var dreieck := PrismMesh.new()
		dreieck.size = Vector3(0.13, 0.22, 0.025)
		f.teil(dreieck, _lage(Vector3(0.04 * seite, -0.1, 0.0), Vector3.ONE,
				Vector3(0.0, 0.0, PI + 0.3 * seite)), TUCH)


# ---------------------------------------------------------- Schnittstelle

## Überträgt den Bewegungszustand.
## tempo: 0..1, luft: in der Luft, slide/spin: Restzeiten in Sekunden.
## haltung: siehe `Spieler.haltung()` – leer, krabbeln, hangeln…, sitzen,
## reiten.
func aktualisiere(delta: float, tempo: float, luft: bool, slide: float,
		spin: float, haltung: String = "") -> void:
	_federn(delta)

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
		_spin_ring_zeigen(spin > 0.0, delta)

	# Laufzyklus (wird von abgeleiteten Modellen genutzt)
	_lauf_phase += delta * tempo * 12.0

	if is_instance_valid(_eigenes):
		_animiere_eigenes(delta, tempo, luft, slide > 0.0, spin > 0.0, haltung)
		return
	_animiere(delta, tempo, luft, slide > 0.0, spin > 0.0, haltung)


func setze_blick(winkel: float) -> void:
	_blick = winkel


func sichtbarkeit(sichtbar: bool) -> void:
	visible = sichtbar


## Stößt die Stauchfeder an: `wert` > 0 staucht (Landung, Aufschlag),
## `wert` < 0 streckt (Absprung, Abprall). Gesetzt, nicht addiert – zwei
## Stöße im selben Bild sollen sich nicht zu Gummi aufschaukeln.
## Reine Anzeige: Hitbox und Kollision bleiben, wie sie sind.
func stoss(wert: float) -> void:
	_stauch = clampf(wert, -STAUCH_GRENZE, STAUCH_GRENZE)
	_stauch_v = 0.0


## Kneift die Augen `dauer` Sekunden zu (Treffer, harter Aufschlag).
## Nur der Beuteldachs hat Lider; bei einer eigenen Figur geschieht nichts.
func kneifen(dauer: float = 0.3) -> void:
	_kneifen = maxf(_kneifen, dauer)


## Führt die Stauchfeder ein Bild weiter und überträgt sie auf `_teile`.
## Das Volumen bleibt ungefähr erhalten: Wer flacher wird, wird breiter.
func _federn(delta: float) -> void:
	if not is_instance_valid(_teile):
		return
	if absf(_stauch) < 0.0005 and absf(_stauch_v) < 0.005:
		# Ausgeschwungen: einmal genau auf 1 setzen, danach nichts mehr tun.
		if _stauch != 0.0 or _stauch_v != 0.0:
			_stauch = 0.0
			_stauch_v = 0.0
			_teile.scale = Vector3.ONE
		return
	# Halbimplizit und mit gedeckeltem Schritt – bei wenigen Bildern je
	# Sekunde schwänge die Feder sonst auf, statt abzuklingen.
	var d := minf(delta, 1.0 / 30.0)
	_stauch_v += (-_stauch * STAUCH_FEDER - _stauch_v * STAUCH_BREMSE) * d
	_stauch += _stauch_v * d
	var hoch := 1.0 - _stauch
	var breit := 1.0 / sqrt(maxf(hoch, 0.3))
	_teile.scale = Vector3(breit, hoch, breit)


## Blendet den Spin-Ring ein und aus. Beim Einsetzen schnappt er aus der
## Enge auf seine Größe, beim Ausklingen weitet er sich, während er
## verblasst – ein Schlag, der verpufft, statt eines Reifs, der erlischt.
func _spin_ring_zeigen(dreht: bool, delta: float) -> void:
	var war_aus := not _spin_ring.visible
	_spin_ring.visible = _spin_alpha > 0.01
	if not _spin_ring.visible:
		return
	if war_aus and dreht:
		_spin_ring.scale = Vector3.ONE * 0.7
	var ziel := 1.0 if dreht else 1.18
	_spin_ring.scale = _spin_ring.scale.lerp(Vector3.ONE * ziel,
			minf(delta * 16.0, 1.0))
	var stoff := _spin_ring.material_override as ShaderMaterial
	if stoff != null:
		stoff.set_shader_parameter("deckkraft", _spin_alpha)


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
	_clip_hangeln_geduckt = _erster_clip(
			["hangduck", "hangeln_geduckt", "haengen_geduckt"])
	_clip_hangeln_spin = _erster_clip(["hangspin", "hangeln_dreh"])

	# Die Zyklen laufen endlos, sonst bleibt die Figur nach einem
	# Durchlauf im letzten Bild stehen. Ruhepose und Sprung dagegen NICHT:
	# Die Pose ist ein einzelnes Bild, und ein Sprung, der sich wiederholt,
	# sähe aus wie ein Hüpfen an Ort und Stelle.
	# Haltungen laufen endlos: Wer sitzt, sitzt weiter, und wer krabbelt,
	# braucht einen Zyklus wie beim Gehen.
	for clip: String in [_clip_ruhe, _clip_schlendern, _clip_gehen, _clip_rennen,
			_clip_spin, _clip_sitzen, _clip_reiten, _clip_krabbeln,
			_clip_hangeln, _clip_hangeln_geduckt, _clip_hangeln_spin]:
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
		"hangeln_geduckt":
			# Fehlt der eigene Clip, ist das gewöhnliche Hangeln immer noch
			# besser als gar nichts – die Figur hängt dann eben gestreckt.
			return _clip_hangeln_geduckt if not _clip_hangeln_geduckt.is_empty() \
					else _clip_hangeln
		"hangeln_spin":
			return _clip_hangeln_spin if not _clip_hangeln_spin.is_empty() \
					else _clip_hangeln
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
##
## Drehrichtungen (alle Gelenke hängen am Rumpf): Bein und Arm mit
## positivem X nach vorn, Arm mit Z nach außen (rechts +, links −), Rumpf
## mit negativem X nach vorn gebeugt, Kopf mit positivem X nach oben,
## Schweif und Zipfel mit negativem X nach hinten oben.
func _animiere(delta: float, tempo: float, luft: bool, slide: bool, spin: bool,
		haltung: String) -> void:
	if not is_instance_valid(_koerper):
		return

	_zeit += delta
	var t := clampf(tempo, 0.0, 1.0)
	var schwung := sin(_lauf_phase)              # Laufschwingung
	var nachlauf := sin(_lauf_phase - 1.1)       # verzögerte Schwingung
	var am_gitter := haltung.begins_with("hangeln")
	var ruhig := not luft and not slide and t <= 0.05 and haltung.is_empty()

	# --- Zielwerte, Ruhepose als Ausgangspunkt ---
	var z_bein_r := Vector3(0.0, 0.0, 0.05)
	var z_bein_l := Vector3(0.0, 0.0, -0.05)
	var z_arm_r := Vector3(0.0, 0.0, ARM_RUHE)
	var z_arm_l := Vector3(0.0, 0.0, -ARM_RUHE)
	var z_kopf := Vector3.ZERO
	var z_rumpf := Vector3.ZERO
	var z_schweif := Vector3(-0.2, SCHWEIF_SEITE, 0.0)
	var z_spitze := Vector3(-0.15, 0.0, 0.0)
	var z_zipfel := Vector3(-0.12, 0.0, 0.0)
	var rumpf_y := RUMPF_Y
	var streck := 1.0
	var ohr_neigung := OHR_RUHE
	var wippen := 0.0
	var wechsel := 14.0           # wie schnell der Rumpf seine Haltung annimmt

	if slide:
		# Bauchrutscher: flach nach vorn, Kopf hoch, Arme voraus, Beine
		# gestreckt hinterher. Der Rumpf kippt, statt gestaucht zu werden –
		# so bleibt der Kopf rund.
		z_rumpf = Vector3(-1.3, 0.0, 0.0)
		rumpf_y = 0.30
		z_kopf = Vector3(1.15, 0.0, 0.0)
		z_bein_r = Vector3(-0.15, 0.0, 0.16)
		z_bein_l = Vector3(-0.15, 0.0, -0.16)
		z_arm_r = Vector3(2.7, 0.0, 0.35)
		z_arm_l = Vector3(2.7, 0.0, -0.35)
		z_schweif = Vector3(1.0, 0.0, 0.0)
		z_spitze = Vector3(0.3, 0.0, 0.0)
		z_zipfel = Vector3(-1.3, 0.0, 0.0)
		ohr_neigung = 1.0
		wechsel = 24.0
	elif haltung == "krabbeln":
		# Auf allen vieren: Rumpf weit vorgebeugt, Hände am Boden, Beine
		# schräg nach hinten. Bleibt unter 0,76 m – so hoch ist die Kapsel.
		var k := clampf(t * 2.5, 0.0, 1.0)
		z_rumpf = Vector3(-1.25, 0.0, sin(_lauf_phase * 0.5) * 0.08 * k)
		rumpf_y = 0.33
		z_kopf = Vector3(1.0, 0.0, 0.0)
		z_bein_r = Vector3(0.1 + schwung * 0.3 * k, 0.0, 0.12)
		z_bein_l = Vector3(0.1 - schwung * 0.3 * k, 0.0, -0.12)
		z_arm_r = Vector3(1.45 - schwung * 0.35 * k, 0.0, 0.18)
		z_arm_l = Vector3(1.45 + schwung * 0.35 * k, 0.0, -0.18)
		z_schweif = Vector3(0.8, nachlauf * 0.3 * k, 0.0)
		z_spitze = Vector3(0.2, 0.0, 0.0)
		z_zipfel = Vector3(-0.9, 0.0, 0.0)
		ohr_neigung = 0.9
		wechsel = 20.0
	elif am_gitter:
		# Am Gitter: Arme senkrecht und gestreckt, die Hände reichen an
		# die Unterkante (GRIFF_HOEHE 1,55 m); die Arme greifen beim
		# Hangeln abwechselnd vor. Der Rumpf hängt etwas höher.
		rumpf_y = RUMPF_Y + 0.12
		streck = 1.6
		z_arm_r = Vector3(schwung * 0.35 * t, 0.0, PI - 0.16)
		z_arm_l = Vector3(-schwung * 0.35 * t, 0.0, -PI + 0.16)
		z_kopf = Vector3(0.12, 0.0, 0.0)
		z_rumpf = Vector3(-0.08 * t + sin(_zeit * 1.7) * 0.04, 0.0, nachlauf * 0.05 * t)
		var pendel := sin(_zeit * 2.1) * 0.08 - nachlauf * 0.3 * t
		z_bein_r = Vector3(pendel, 0.0, 0.06)
		z_bein_l = Vector3(-pendel * 0.6, 0.0, -0.06)
		z_schweif = Vector3(0.5, sin(_zeit * 1.9) * 0.2, 0.0)
		z_spitze = Vector3(0.25, 0.0, 0.0)
		ohr_neigung = 0.65
		if haltung == "hangeln_geduckt":
			# Beine angezogen: Die Figur wird UNTEN kurz (Kapsel ab 0,54 m).
			z_bein_r = Vector3(1.7, 0.0, 0.3)
			z_bein_l = Vector3(1.7, 0.0, -0.3)
			z_rumpf = Vector3(0.2, 0.0, 0.0)
			z_schweif = Vector3(-0.3, 0.0, 0.0)
		elif haltung == "hangeln_spin":
			# Drehschlag am Gitter: Die Beine werden herumgerissen.
			z_bein_r = Vector3(0.3, 0.0, 1.1)
			z_bein_l = Vector3(0.3, 0.0, -1.1)
	elif haltung == "sitzen":
		# Im Kart und im Flieger: Beine nach vorn, Hände am Lenker.
		rumpf_y = 0.55
		z_rumpf = Vector3(-0.05, 0.0, 0.0)
		z_bein_r = Vector3(1.35, 0.0, 0.12)
		z_bein_l = Vector3(1.35, 0.0, -0.12)
		z_arm_r = Vector3(1.05, 0.0, 0.18)
		z_arm_l = Vector3(1.05, 0.0, -0.18)
		z_kopf = Vector3(0.05, 0.0, 0.0)
		z_schweif = Vector3(0.3, 0.0, 0.0)
		z_zipfel = Vector3(-0.6 - 0.4 * t + sin(_zeit * 17.0) * 0.12 * t, 0.0, 0.0)
		ohr_neigung = OHR_RUHE + 0.3 * t
	elif haltung == "reiten":
		# Auf der Wildkatze: breitbeinig, vorgebeugt, die Hände im Fell.
		rumpf_y = 0.42
		z_rumpf = Vector3(-0.3, 0.0, 0.0)
		z_bein_r = Vector3(0.35, 0.0, 0.7)
		z_bein_l = Vector3(0.35, 0.0, -0.7)
		z_arm_r = Vector3(0.95, 0.0, 0.35)
		z_arm_l = Vector3(0.95, 0.0, -0.35)
		z_kopf = Vector3(0.25, 0.0, 0.0)
		z_schweif = Vector3(0.2, sin(_zeit * 3.0) * 0.2, 0.0)
		z_zipfel = Vector3(-1.0 + sin(_zeit * 15.0) * 0.15, 0.0, 0.0)
		ohr_neigung = 0.5
		wippen = absf(schwung) * 0.04
	elif luft:
		# Beine angezogen, Arme hoch, Ohren und Tuch fliegen nach hinten
		z_bein_r = Vector3(0.9, 0.0, 0.15)
		z_bein_l = Vector3(0.9, 0.0, -0.15)
		z_arm_r = Vector3(0.2, 0.0, ARM_LUFT)
		z_arm_l = Vector3(0.2, 0.0, -ARM_LUFT)
		z_kopf = Vector3(0.15, 0.0, 0.0)
		z_schweif = Vector3(-0.55, SCHWEIF_SEITE, 0.0)
		z_spitze = Vector3(-0.3, 0.0, 0.0)
		z_zipfel = Vector3(-1.2 + sin(_zeit * 16.0) * 0.12, 0.0, 0.0)
		ohr_neigung = 0.45
	elif t > 0.05:
		# Laufen: Beine und Arme gegengleich, Rumpf wippt und schaukelt
		z_bein_r = Vector3(schwung * 0.85 * t, 0.0, 0.05)
		z_bein_l = Vector3(-schwung * 0.85 * t, 0.0, -0.05)
		z_arm_r = Vector3(-schwung * 0.75 * t, 0.0, ARM_RUHE + 0.05)
		z_arm_l = Vector3(schwung * 0.75 * t, 0.0, -ARM_RUHE - 0.05)
		z_kopf = Vector3(0.06 * t + nachlauf * 0.05 * t, 0.0, 0.0)
		z_rumpf = Vector3(-0.16 * t, 0.0, sin(_lauf_phase * 0.5) * 0.07 * t)
		# Schweif hoch, wedelt und läuft dabei hinterher
		z_schweif = Vector3(-0.35 * t - 0.15, SCHWEIF_SEITE + nachlauf * 0.35 * t, 0.0)
		z_spitze = Vector3(-0.15 * t - 0.10, sin(_lauf_phase - 2.0) * 0.4 * t, 0.0)
		z_zipfel = Vector3(-0.5 - 0.7 * t + sin(_zeit * 19.0) * 0.12 * t, 0.0,
				nachlauf * 0.15 * t)
		ohr_neigung = OHR_RUHE + 0.1 * t + nachlauf * 0.22 * t
		wippen = absf(schwung) * 0.06 * t
	else:
		# Ruhig stehen: Kopfnicken, Schweif und Arme pendeln sacht
		z_kopf = Vector3(sin(_zeit * 1.6) * 0.05, sin(_zeit * 0.7) * 0.12, 0.0)
		z_schweif = Vector3(-0.2 + sin(_zeit * 1.3) * 0.06,
				SCHWEIF_SEITE + sin(_zeit * 0.9) * 0.15, 0.0)
		z_spitze = Vector3(-0.15, sin(_zeit * 0.9 - 0.7) * 0.2, 0.0)
		z_arm_r.x = sin(_zeit * 1.1) * 0.05
		z_arm_l.x = sin(_zeit * 1.1 + 0.6) * 0.05
		z_zipfel = Vector3(-0.12 + sin(_zeit * 1.4) * 0.05, 0.0, sin(_zeit * 0.9) * 0.06)

	# Spin sticht durch: Arme waagerecht ausgestreckt. Am Gitter bleiben
	# die Hände oben – dort reißt der Drehschlag die Beine herum.
	if spin and not am_gitter:
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
	_folge(_zipfel, z_zipfel, 9.0, delta)
	_folge(_koerper, z_rumpf, wechsel, delta)

	_rumpf_hoehe = lerpf(_rumpf_hoehe, rumpf_y, clampf(delta * SLIDE_WECHSEL, 0.0, 1.0))
	_streck_setzen(lerpf(_streck, streck, clampf(delta * 12.0, 0.0, 1.0)))

	_bewege_ohren(ohr_neigung, delta, ruhig)
	_blinzeln(delta)

	# --- Rumpf: Wippen beim Laufen, Atmen im Stand ---
	_koerper.position.y = _rumpf_hoehe + wippen
	_atem = lerpf(_atem, 1.0 if ruhig else 0.0, clampf(delta * 4.0, 0.0, 1.0))
	var atem := sin(_zeit * 2.2) * 0.025 * _atem
	_koerper.scale = Vector3(1.0 - atem * 0.5, 1.0 + atem, 1.0 - atem * 0.5)


## Streckt die Oberarme (am Gitter) und rückt die Hände ans Ende.
func _streck_setzen(wert: float) -> void:
	if is_equal_approx(wert, _streck):
		return
	_streck = wert
	for arm in _oberarme:
		arm.scale.y = wert
	for hand in _haende:
		hand.position.y = -0.29 * wert


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


## Lider (Lage im Auge, siehe `_augenlage`): offen eine flache Kappe über
## dem oberen Achtel des Auges, geschlossen eine Schale, die Augapfel,
## Iris und Glanzpunkte ganz umschließt.
const LID_OFFEN := Vector3(0.97, 0.3, 0.88)
const LID_ZU := Vector3(1.05, 1.02, 1.12)
const LID_OFFEN_Y := 0.074


func _lider_setzen(zu: float) -> void:
	if is_equal_approx(zu, _lid_zu):
		return
	_lid_zu = zu
	for lid in _lider:
		if is_instance_valid(lid):
			lid.scale = LID_OFFEN.lerp(LID_ZU, zu)
			lid.position.y = lerpf(LID_OFFEN_Y, 0.0, zu)


## Blinzeln in unregelmäßigem Takt – eine Figur, die nie blinzelt, wirkt
## aus der Nähe ausgestopft. Ab und zu folgt ein zweiter Lidschlag gleich
## hinterher; das liest sich lebendiger als ein Metronom.
func _blinzeln(delta: float) -> void:
	if _lider.is_empty():
		return
	_blinz_pause -= delta
	if _blinz_pause <= 0.0:
		_blinz = BLINZ_DAUER
		_blinz_pause = 0.28 if randf() < 0.2 else randf_range(2.2, 5.0)
	_blinz = maxf(_blinz - delta, 0.0)
	_kneifen = maxf(_kneifen - delta, 0.0)
	var zu := sin(clampf(_blinz / BLINZ_DAUER, 0.0, 1.0) * PI)
	if _kneifen > 0.0:
		zu = 1.0
	_lider_setzen(zu)


## Fährt die Drehung eines Gelenks weich auf den Zielwinkel zu.
func _folge(knoten: Node3D, ziel: Vector3, geschwindigkeit: float, delta: float) -> void:
	if not is_instance_valid(knoten):
		return
	knoten.rotation = knoten.rotation.lerp(ziel, clampf(geschwindigkeit * delta, 0.0, 1.0))
