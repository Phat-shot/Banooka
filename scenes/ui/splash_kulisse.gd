extends Node3D
class_name SplashKulisse
## Waldkulisse hinter dem Startbildschirm.
##
## Ein Stück Waldboden mit sanften Hügeln, ringsherum Bäume, Findlinge,
## Wurzelbögen, Farn und Gras. Die Kamera steht in der Mitte der Lichtung,
## blickt nach außen und fährt endlos auf einem kleinen Kreis entlang –
## der Wald zieht dadurch langsam seitlich vorbei und läuft nach einer
## vollen Runde nahtlos weiter.
##
## Licht- und Nebelwerte sind von Level01 übernommen; nur die Sonne steht
## flacher (schönere Silhouetten) und der Nebel ist etwas dichter, damit
## der ferne Wald weich wegblendet.
##
## Stimmung, die nur hier gebraucht wird (der Startbildschirm ist das
## erste Bild des Spiels und darf dafür etwas mehr kosten als ein Level):
##   Himmel       eigener Himmelsshader mit Dunstband, warmem Schein auf
##                der Sonnenseite, Haufenwolken und Sonnenscheibe
##   Glühen       `glow` der Umgebung – Sonne und Lichtfahnen strahlen
##   Lichtfahnen  schräge Lichtbahnen durch die Stämme, in 3D, damit sie
##                bei der Kamerafahrt immer von der Sonne herkommen
##   Pollen       schwebende Flusen (`Staubflug`) zwischen Kamera und Wald
## Lichtfahnen und Pollen kosten zusammen zwei Draw-Calls, beide ohne
## Schatten.
##
## Alles ist Eigenbau: Props werden aus `scenes/props/` instanziiert,
## Materialien kommen aus der `Materialbibliothek`. Keine fremden Dateien.
##
## Renderer: `gl_compatibility` – Standardmaterialien und einfache Shader
## ohne Bildschirm- oder Tiefentextur.

const BAUM_SZENE := preload("res://scenes/props/Baum.tscn")
const STEIN_SZENE := preload("res://scenes/props/Stein.tscn")
const WURZEL_SZENE := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG_SZENE := preload("res://scenes/props/Kleinzeug.tscn")
const GRAS_SZENE := preload("res://scenes/props/Gras.tscn")

## Feste Saat: die Kulisse sieht bei jedem Start gleich aus.
const SAAT := 4711

## Kamerafahrt: Kreisbahn um die Lichtungsmitte, Blick nach außen.
const KAMERA_RADIUS := 2.6
const KAMERA_HOEHE := 2.30
const KAMERA_TEMPO := 0.035        ## Bogenmaß je Sekunde (volle Runde ≈ 3 min)
const KAMERA_NEIGUNG := -0.05      ## leicht nach unten geneigt

## Gelände
const BODEN_KANTE := 130.0
const BODEN_FELDER := 76
const HUEGEL_HOEHE := 4.6
## Der Wald liegt in einer Mulde: nach außen steigt das Gelände an und
## verdeckt den geraden Horizont.
const MULDE_HOEHE := 11.0

## Sonnenstand. Flacher als im Level: streift durch die Stämme, gibt
## Silhouetten und lange Lichtfahnen.
const SONNE_DREHUNG := Vector3(-24.0, 118.0, 0.0)

## Nebel- und Dunstfarbe. Der Himmel nimmt sie für sein Dunstband auf,
## damit die vernebelten Baumkronen nahtlos in den Horizont laufen.
const NEBELFARBE := Color(0.495, 0.594, 0.594)

## Lichtfahnen: Anzahl, Länge (m) und Mindestabstand ihrer Bahn von der
## Lichtungsmitte – näher liefen sie der Kamera durchs Bild.
const FAHNEN := 7
const FAHNEN_LAENGE := 22.0
const FAHNEN_FREIRAUM := 6.0

## Laubtöne der Bäume – wenige Töne, damit der Materialspeicher klein bleibt.
const LAUBTOENE: Array[Color] = [
	Color(0.22, 0.47, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.41, 0.66, 0.24),
	Color(0.30, 0.52, 0.17),
	Color(0.46, 0.60, 0.21),
]

## Himmel: Farbverlauf, Dunstband am Horizont, warmer Schein auf der
## Sonnenseite, Haufenwolken mit sonnigen Säumen und eine Sonnenscheibe,
## die hell genug ist, um zu glühen.
##
## Ohne TIME und POSITION: Im Compatibility-Renderer würde der Himmel
## sonst jedes Bild neu in die Umgebungskarte gerechnet. So entsteht er
## einmal. Die Wolken ziehen trotzdem durchs Bild – die Kamera dreht sich.
const HIMMEL_SHADER := """
shader_type sky;

uniform vec3 zenit : source_color = vec3(0.19, 0.39, 0.68);
uniform vec3 mitte : source_color = vec3(0.42, 0.62, 0.80);
uniform vec3 horizont : source_color = vec3(0.78, 0.84, 0.80);
uniform vec3 dunstband : source_color = vec3(0.50, 0.59, 0.59);
uniform vec3 boden : source_color = vec3(0.14, 0.18, 0.13);
uniform vec3 sonnenschein : source_color = vec3(1.0, 0.80, 0.52);
uniform float dunst_hoehe = 0.07;
uniform float schein_staerke = 0.85;
uniform sampler2D wolken : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float wolken_menge = 0.50;
uniform float wolken_weich = 0.24;
uniform float wolken_skala = 0.26;
uniform vec3 wolke_hell : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 wolke_schatten : source_color = vec3(0.60, 0.67, 0.78);

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 s = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0, 1.0, 0.0);
	float e = LIGHT0_ENABLED ? LIGHT0_ENERGY : 0.0;
	float zur_sonne = max(dot(d, s), 0.0);
	// Richtung der Sonne nur waagerecht: Der warme Schein liegt als breites
	// Band über dem Horizont, nicht als Kreis um die Sonne.
	float seite = max(dot(normalize(d.xz + 1e-4), normalize(s.xz + 1e-4)), 0.0);

	float hoch = clamp(h, 0.0, 1.0);
	vec3 himmel = mix(horizont, mitte, smoothstep(0.0, 0.28, hoch));
	himmel = mix(himmel, zenit, smoothstep(0.22, 0.85, hoch));
	himmel = mix(dunstband, himmel, smoothstep(0.0, dunst_hoehe, h));
	himmel += sonnenschein * pow(seite, 5.0) * (1.0 - smoothstep(0.0, 0.45, h))
			* schein_staerke * e * 0.6;
	himmel += sonnenschein * pow(zur_sonne, 12.0) * 0.55 * e;

	if (h > 0.0) {
		// Wolken auf einer gedachten Decke: Richtung durch Höhe geteilt,
		// zum Horizont hin rücken sie zusammen und werden flach.
		vec2 uv = d.xz / (h + 0.18) * wolken_skala;
		float n = texture(wolken, uv).r * 0.68 + texture(wolken, uv * 2.7 + 0.31).r * 0.32;
		float dichte = smoothstep(wolken_menge, wolken_menge + wolken_weich, n)
				* smoothstep(0.03, 0.22, h);
		vec3 wolke = mix(wolke_schatten, wolke_hell, smoothstep(0.42, 0.9, n));
		// Sonnenseitig angestrahlt: Säume leuchten warm.
		wolke += sonnenschein * pow(zur_sonne, 5.0) * 0.9 * e;
		himmel = mix(himmel, wolke, dichte * 0.88);
	}
	if (LIGHT0_ENABLED) {
		// Sonnenscheibe mit weichem Rand, deutlich über 1: Sie soll glühen.
		float scheibe = smoothstep(0.9993, 0.9997, dot(d, s));
		himmel += LIGHT0_COLOR * e * (scheibe * 5.0 + pow(zur_sonne, 220.0) * 1.2);
	}
	vec3 unten = mix(dunstband, boden, smoothstep(0.0, 0.25, -h));
	COLOR = h >= 0.0 ? himmel : unten;
	if (!AT_CUBEMAP_PASS) {
		// Eine Spur Rauschen gegen Stufen im flachen Verlauf
		COLOR += (fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453)
				- 0.5) / 255.0;
	}
}
"""

## Lichtfahnen: Jede Fahne ist ein Band entlang der Sonnenrichtung, das
## sich um seine eigene Längsachse zur Kamera dreht (wie ein Billboard,
## nur mit fester Achse). Alle Fahnen stecken in EINEM Netz: ein Draw-Call.
##
## Jede Ecke steht im Netz auf der Achse; die Breite, der Takt und die
## Stärke kommen als Scheitelfarbe mit (r = Breite / 4 m, g = Takt,
## b = Stärke), die Seite (-1/1) und die Lage längs (0 oben, 1 unten) als
## UV. Additiv und ohne Nebel: Nebel würde eine additive Fläche nicht
## dämpfen, sondern aufhellen – die Ferne blendet der Shader selbst aus.
const FAHNEN_SHADER := """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never,
		shadows_disabled, fog_disabled, world_vertex_coords;

uniform vec3 achse = vec3(0.0, -1.0, 0.0);
uniform vec4 farbe : source_color = vec4(1.0, 0.86, 0.60, 1.0);
uniform float staerke = 1.8;

varying float quer;
varying float laengs;
varying float deckung;
varying float takt;

void vertex() {
	vec3 zur_kamera = CAMERA_POSITION_WORLD - VERTEX;
	float abstand = length(zur_kamera);
	vec3 seite = normalize(cross(achse, zur_kamera));
	VERTEX += seite * UV.x * COLOR.r * 2.0;
	// Blickt man längs der Fahne, schrumpft sie zum Strich, und alle
	// Fahnen dieser Seite lägen übereinander als heller Fleck: dann weg.
	float laengsblick = abs(dot(zur_kamera / abstand, achse));
	deckung = COLOR.b * (1.0 - smoothstep(0.78, 0.94, laengsblick));
	// Langsames Atmen, jede Fahne im eigenen Takt – wie Wolken vor der Sonne.
	deckung *= 0.62 + 0.38 * sin(TIME * (0.55 + COLOR.g * 0.5) + COLOR.g * 6.2832);
	// Nicht direkt vor der Linse, und in der Ferne sacht verlöschen.
	deckung *= smoothstep(2.5, 6.0, abstand) * exp(-abstand * 0.028);
	quer = UV.x;
	laengs = UV.y;
	takt = COLOR.g;
}

void fragment() {
	// Satter Kern mit weichem Saum, darin zwei, drei feine Streifen – so
	// liest sich die Fahne als Lichtbahn und nicht als Nebelfleck.
	float x = abs(quer);
	float kern = 1.0 - smoothstep(0.3, 1.0, x);
	float streifen = 0.72 + 0.28 * sin(quer * 8.5 + takt * 6.2832);
	float l = smoothstep(0.0, 0.22, laengs) * (1.0 - smoothstep(0.5, 1.0, laengs));
	ALBEDO = farbe.rgb * staerke;
	ALPHA = clamp(deckung * kern * streifen * l, 0.0, 1.0);
}
"""

var _kamera: Camera3D
var _rausch: FastNoiseLite
var _zeit := 0.0


func _ready() -> void:
	_rausch = FastNoiseLite.new()
	_rausch.seed = SAAT
	_rausch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_rausch.frequency = 0.017
	_rausch.fractal_octaves = 3

	_baue_umgebung()
	var sonne := _baue_licht()
	_baue_kamera()
	_baue_boden()
	_streue_wald()
	_baue_lichtfahnen(sonne)
	_baue_pollen()
	_stelle_kamera(0.0)


func _process(delta: float) -> void:
	_zeit += delta
	_stelle_kamera(_zeit)


# ------------------------------------------------------------- Umgebung

func _baue_umgebung() -> void:
	var shader := Shader.new()
	shader.code = HIMMEL_SHADER
	var himmelsstoff := ShaderMaterial.new()
	himmelsstoff.shader = shader
	himmelsstoff.set_shader_parameter("dunstband", NEBELFARBE)
	himmelsstoff.set_shader_parameter("wolken", _wolkentextur())

	var himmel := Sky.new()
	himmel.sky_material = himmelsstoff
	# Die Umgebungskarte speist nur Glanzlichter (das Umgebungslicht ist
	# eine feste Farbe) – 64 px reichen und sind schnell gerechnet.
	himmel.radiance_size = Sky.RADIANCE_SIZE_64

	var umgebung := Environment.new()
	umgebung.background_mode = Environment.BG_SKY
	umgebung.sky = himmel
	umgebung.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	umgebung.ambient_light_color = Color(0.55, 0.62, 0.70)
	umgebung.ambient_light_energy = 0.75
	umgebung.tonemap_mode = Environment.TONE_MAPPER_ACES
	umgebung.tonemap_exposure = 1.05
	umgebung.tonemap_white = 6.0
	umgebung.fog_enabled = true
	umgebung.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	umgebung.fog_light_color = NEBELFARBE
	umgebung.fog_light_energy = 0.70
	umgebung.fog_density = 0.045
	# Blick gegen die Sonne färbt den Dunst warm – der Wald steht dann im
	# Gegenlicht statt in grauem Nebel.
	umgebung.fog_sun_scatter = 0.16
	umgebung.fog_sky_affect = 0.14
	umgebung.fog_height = 2.0
	umgebung.fog_height_density = 0.14
	umgebung.adjustment_enabled = true
	umgebung.adjustment_brightness = 0.94
	umgebung.adjustment_contrast = 1.08
	umgebung.adjustment_saturation = 1.14
	# Glühen: Sonne, Wolkensäume und Lichtfahnen strahlen über. Unter
	# Compatibility zählen nur Stärke, Schwelle und Skala (Mischart und
	# Stufen sind fest); die Schwelle liegt über dem besonnten Laub. Der
	# Nachbearbeitungsschritt läuft wegen `adjustment` ohnehin, das Glühen
	# kostet nur seine paar Weichzeichnungsschritte in halber Auflösung.
	umgebung.glow_enabled = true
	umgebung.glow_intensity = 0.6
	umgebung.glow_bloom = 0.0
	umgebung.glow_hdr_threshold = 1.0
	umgebung.glow_hdr_scale = 1.2

	var knoten := WorldEnvironment.new()
	knoten.name = "Umgebung"
	knoten.environment = umgebung
	add_child(knoten)


## Wolkenbild für den Himmel: kachelbares, weiches Rauschen, einmal beim
## Start gerechnet. Bewusst kein NoiseTexture2D – das rechnet im
## Hintergrund, und der Himmel stünde die ersten Bilder ohne Wolken da.
func _wolkentextur() -> ImageTexture:
	var r := FastNoiseLite.new()
	r.seed = SAAT
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.frequency = 0.011
	r.fractal_octaves = 5
	r.fractal_gain = 0.5
	r.domain_warp_enabled = true
	r.domain_warp_amplitude = 22.0
	r.domain_warp_frequency = 0.006
	var bild := r.get_seamless_image(256, 256, false, false, 0.1)
	bild.convert(Image.FORMAT_L8)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


func _baue_licht() -> DirectionalLight3D:
	var sonne := DirectionalLight3D.new()
	sonne.name = "Sonne"
	sonne.rotation_degrees = SONNE_DREHUNG
	sonne.position = Vector3(0.0, 30.0, 0.0)
	sonne.light_color = Color(1.0, 0.90, 0.75)
	sonne.light_energy = 1.25
	sonne.light_specular = 0.4
	sonne.shadow_enabled = true
	sonne.shadow_bias = 0.04
	sonne.shadow_normal_bias = 1.5
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sonne.directional_shadow_max_distance = 30.0
	sonne.directional_shadow_split_1 = 0.09
	sonne.directional_shadow_split_2 = 0.24
	add_child(sonne)
	return sonne


func _baue_kamera() -> void:
	_kamera = Camera3D.new()
	_kamera.name = "Kamera"
	_kamera.fov = 58.0
	_kamera.near = 0.1
	_kamera.far = 400.0
	add_child(_kamera)
	_kamera.current = true


## Setzt die Kamera auf ihre Kreisbahn. Blickrichtung: nach außen,
## dadurch wandert der Wald seitlich durchs Bild.
func _stelle_kamera(zeit: float) -> void:
	if _kamera == null:
		return
	var winkel := zeit * KAMERA_TEMPO
	var aussen := Vector3(sin(winkel), 0.0, cos(winkel))
	var ort := aussen * KAMERA_RADIUS
	ort.y = KAMERA_HOEHE + sin(zeit * 0.21) * 0.12
	_kamera.position = ort
	_kamera.look_at(ort + aussen * 12.0 + Vector3.UP * (KAMERA_NEIGUNG * 12.0), Vector3.UP)


# ---------------------------------------------------------- Stimmung

## Schräge Lichtbahnen, die von der Sonne her durch den Wald fallen.
##
## Jede Fahne endet am Waldboden zwischen den Bäumen und reicht
## `FAHNEN_LAENGE` Meter zur Sonne hinauf – bei 24° Sonnenhöhe beginnt sie
## damit oben im Kronendach. Bahnen, die über die Lichtung führen würden,
## werden verworfen: Dort fährt die Kamera, und eine Fahne quer vor der
## Linse wäre nur ein heller Schleier.
func _baue_lichtfahnen(sonne: DirectionalLight3D) -> void:
	# Die Lichtrichtung aus dem Sonnenstand, ohne auf den Baum zu warten:
	# Das Licht scheint entlang seiner -Z-Achse.
	var achse := -Basis.from_euler(SONNE_DREHUNG * (PI / 180.0)).z.normalized()
	if sonne.is_inside_tree():
		achse = -sonne.global_basis.z.normalized()
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = SAAT + 77

	var punkte := PackedVector3Array()
	var uvs := PackedVector2Array()
	var farben := PackedColorArray()
	var indizes := PackedInt32Array()
	for nummer in FAHNEN:
		# Gleichmäßig rundum verteilt – die Kamera schaut ja nacheinander in
		# jede Richtung. Die erste Fahne liegt in der Startblickrichtung
		# (+Z), damit schon das erste Bild eine zeigt.
		var anfang := Vector3.ZERO
		var ende := Vector3.ZERO
		var frei := false
		for _versuch in 24:
			var winkel := TAU * float(nummer) / float(FAHNEN) \
					+ wuerfel.randf_range(-0.25, 0.25)
			var radius := wuerfel.randf_range(8.0, 15.0)
			# Die Mitte der Fahne – ihr hellster Teil – schwebt ein paar
			# Meter über dem Boden in dieser Richtung.
			var mitte := Vector3(sin(winkel) * radius, 0.0, cos(winkel) * radius)
			mitte.y = _boden_hoehe(mitte.x, mitte.z) + wuerfel.randf_range(2.5, 4.5)
			anfang = mitte - achse * FAHNEN_LAENGE * 0.55
			ende = mitte + achse * FAHNEN_LAENGE * 0.45
			if _abstand_zur_mitte(anfang, ende) >= FAHNEN_FREIRAUM:
				frei = true
				break
		if not frei:
			continue
		var breite := wuerfel.randf_range(1.1, 2.6)
		var kennung := Color(breite / 4.0, wuerfel.randf(), wuerfel.randf_range(0.55, 1.0))
		var erste := punkte.size()
		punkte.append_array(PackedVector3Array([anfang, anfang, ende, ende]))
		uvs.append_array(PackedVector2Array([Vector2(-1, 0), Vector2(1, 0),
				Vector2(-1, 1), Vector2(1, 1)]))
		farben.append_array(PackedColorArray([kennung, kennung, kennung, kennung]))
		indizes.append_array(PackedInt32Array([erste, erste + 1, erste + 2,
				erste + 1, erste + 3, erste + 2]))
	if punkte.is_empty():
		return

	var felder := []
	felder.resize(Mesh.ARRAY_MAX)
	felder[Mesh.ARRAY_VERTEX] = punkte
	felder[Mesh.ARRAY_TEX_UV] = uvs
	felder[Mesh.ARRAY_COLOR] = farben
	felder[Mesh.ARRAY_INDEX] = indizes
	var netz := ArrayMesh.new()
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, felder)

	var shader := Shader.new()
	shader.code = FAHNEN_SHADER
	var stoff := ShaderMaterial.new()
	stoff.shader = shader
	stoff.set_shader_parameter("achse", achse)

	var fahnen := MeshInstance3D.new()
	fahnen.name = "Lichtfahnen"
	fahnen.mesh = netz
	fahnen.material_override = stoff
	fahnen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Das Netz kennt nur die Achsen; die Breite entsteht erst im Shader.
	fahnen.extra_cull_margin = 3.0
	add_child(fahnen)


## Waagerechter Abstand einer Strecke zur Lichtungsmitte.
func _abstand_zur_mitte(a: Vector3, b: Vector3) -> float:
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	var weg := b2 - a2
	var t := clampf(-a2.dot(weg) / maxf(weg.length_squared(), 0.001), 0.0, 1.0)
	return (a2 + weg * t).length()


## Pollen und Staub, die langsam um die Kamera schweben. Ein Staubflug ist
## ein einziges MultiMesh mit Bewegung im Shader – ein Draw-Call.
func _baue_pollen() -> void:
	var pollen := Staubflug.new()
	pollen.name = "Pollen"
	pollen.raum = Vector3(18.0, 4.5, 18.0)
	pollen.anzahl = 90
	pollen.groesse = 0.04
	pollen.groessen_streuung = 0.55
	pollen.farbe = Color(1.0, 0.93, 0.72)
	pollen.deckkraft = 0.8
	pollen.steiggeschwindigkeit = 0.12
	pollen.wirbel = 0.45
	pollen.wirbel_tempo = 0.28
	pollen.saat = SAAT
	pollen.position = Vector3(0.0, 0.4, 0.0)
	add_child(pollen)


# --------------------------------------------------------------- Boden

## Höhe des Geländes an einer Stelle. Die Lichtung in der Mitte bleibt
## flach, nach außen hin wird es hügelig.
func _boden_hoehe(x: float, z: float) -> float:
	var abstand := sqrt(x * x + z * z)
	var anteil := smoothstep(3.0, 13.0, abstand)
	var mulde := smoothstep(16.0, 58.0, abstand)
	var grob := _rausch.get_noise_2d(x, z) * HUEGEL_HOEHE
	var fein := _rausch.get_noise_2d(x * 3.4, z * 3.4) * 1.15
	return (grob + fein) * anteil + mulde * mulde * MULDE_HOEHE


func _baue_boden() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var schritt := BODEN_KANTE / float(BODEN_FELDER)
	var halb := BODEN_KANTE * 0.5

	for ix in BODEN_FELDER:
		for iz in BODEN_FELDER:
			var x0 := -halb + ix * schritt
			var z0 := -halb + iz * schritt
			var x1 := x0 + schritt
			var z1 := z0 + schritt
			var a := Vector3(x0, _boden_hoehe(x0, z0), z0)
			var b := Vector3(x1, _boden_hoehe(x1, z0), z0)
			var c := Vector3(x1, _boden_hoehe(x1, z1), z1)
			var d := Vector3(x0, _boden_hoehe(x0, z1), z1)
			# Von oben gesehen im Uhrzeigersinn = Vorderseite (siehe ARCHITEKTUR.md)
			_dreieck(st, a, b, c)
			_dreieck(st, a, c, d)

	st.generate_normals()
	st.generate_tangents()
	var netz := MeshInstance3D.new()
	netz.name = "Boden"
	netz.mesh = st.commit()
	netz.material_override = _bodenmaterial()
	netz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(netz)


## Grasmaterial, für die Kulisse abgedunkelt und feiner gekachelt –
## eine helle, glatte Wiese sähe nach Rasen aus, nicht nach Wald.
## Kopie ziehen, damit die geteilte Fassung unverändert bleibt.
func _bodenmaterial() -> StandardMaterial3D:
	var m: StandardMaterial3D = Materialbibliothek.gras().duplicate()
	m.albedo_color = Color(0.54, 0.60, 0.49)
	m.uv1_scale = Vector3(1.6, 1.6, 1.6)
	return m


func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p in [a, b, c]:
		st.set_uv(Vector2(p.x, p.z) * 0.125)
		st.add_vertex(p)


# ---------------------------------------------------------------- Wald

func _streue_wald() -> void:
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = SAAT

	# Dichter Ring aus Bäumen: nah als Rahmen, dahinter als Wand, in der
	# Ferne als Skyline, die im Nebel verschwindet.
	for i in 12:
		_setze_baum(wuerfel, wuerfel.randf_range(8.0, 14.0),
				wuerfel.randf_range(5.5, 8.5), i)
	for i in 34:
		_setze_baum(wuerfel, wuerfel.randf_range(12.0, 27.0),
				wuerfel.randf_range(7.0, 11.5), 100 + i)
	# Ferne Bäume nur als Silhouette im Nebel – wenige reichen und der
	# Startbildschirm bleibt schnell aufgebaut.
	for i in 18:
		_setze_baum(wuerfel, wuerfel.randf_range(27.0, 54.0),
				wuerfel.randf_range(9.5, 13.5), 200 + i)

	# Findlinge
	for i in 18:
		var stein := STEIN_SZENE.instantiate()
		stein.groesse = wuerfel.randf_range(0.6, 2.6)
		stein.brocken = wuerfel.randi_range(2, 5)
		stein.flach = wuerfel.randf() < 0.3
		stein.bemoost = true
		stein.kollision = false
		stein.saat = 300 + i * 13
		_setze(stein, wuerfel, wuerfel.randf_range(4.0, 24.0))

	# Wurzelbögen
	for i in 5:
		var wurzel := WURZEL_SZENE.instantiate()
		wurzel.spannweite = wuerfel.randf_range(2.6, 5.0)
		wurzel.hoehe = wuerfel.randf_range(0.7, 1.4)
		wurzel.dicke = wuerfel.randf_range(0.3, 0.55)
		wurzel.kollision = false
		wurzel.saat = 500 + i * 17
		_setze(wurzel, wuerfel, wuerfel.randf_range(4.5, 14.0))

	# Farn, Pilze, Büsche, Blumen im Vordergrund
	var arten := [Kleinzeug.Art.FARN, Kleinzeug.Art.PILZ,
			Kleinzeug.Art.BUSCH, Kleinzeug.Art.BLUME]
	for i in 58:
		var klein := KLEINZEUG_SZENE.instantiate()
		klein.art = arten[wuerfel.randi() % arten.size()]
		klein.groesse = wuerfel.randf_range(0.40, 0.85)
		klein.saat = 700 + i * 7
		_setze(klein, wuerfel, wuerfel.randf_range(3.4, 18.0))

	# Grasbüschel – je Feld ein einziger Zeichenaufruf. Sie decken den
	# offenen Boden zu, damit die Lichtung nach Wald aussieht und nicht
	# nach Sandfläche.
	# Weniger Felder als früher: 26 Felder à 260 Büscheln waren rund
	# 135 000 Dreiecke allein für Gras und drückten den Startbildschirm
	# auf 22 Bilder je Sekunde.
	for i in 12:
		var gras := GRAS_SZENE.instantiate()
		gras.flaeche = Vector2(9.0, 9.0)
		gras.anzahl = 150
		gras.hoechstzahl = 190
		gras.halm_hoehe = 0.38
		gras.farbe_unten = Farben.GRAS_DUNKEL
		gras.farbe_oben = Farben.GRAS_HELL
		gras.saat = 900 + i * 11
		_setze(gras, wuerfel, wuerfel.randf_range(3.2, 22.0))


func _setze_baum(wuerfel: RandomNumberGenerator, radius: float,
		hoehe: float, nummer: int) -> void:
	var baum := BAUM_SZENE.instantiate()
	var los := wuerfel.randf()
	if los < 0.08:
		baum.art = Baum.Art.TOTHOLZ
	elif los < 0.38:
		baum.art = Baum.Art.NADELBAUM
	else:
		baum.art = Baum.Art.LAUBBAUM
	baum.hoehe = hoehe
	baum.staerke = wuerfel.randf_range(0.85, 1.25)
	baum.laubfarbe = LAUBTOENE[wuerfel.randi() % LAUBTOENE.size()]
	baum.kollision = false
	baum.saat = 1000 + nummer * 23
	_setze(baum, wuerfel, radius)


## Stellt ein Prop auf einen zufälligen Punkt des Kreisrings mit diesem
## Radius – Position immer vor `add_child` setzen (siehe ARCHITEKTUR.md).
func _setze(knoten: Node3D, wuerfel: RandomNumberGenerator, radius: float) -> void:
	var winkel := wuerfel.randf() * TAU
	var x := sin(winkel) * radius
	var z := cos(winkel) * radius
	knoten.position = Vector3(x, _boden_hoehe(x, z), z)
	knoten.rotation.y = wuerfel.randf() * TAU
	add_child(knoten)
