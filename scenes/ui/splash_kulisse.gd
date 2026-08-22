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
## Licht-, Himmels- und Nebelwerte sind von Level01 übernommen; nur die
## Sonne steht flacher (schönere Silhouetten) und der Nebel ist etwas
## dichter, damit der ferne Wald weich wegblendet.
##
## Alles ist Eigenbau: Props werden aus `scenes/props/` instanziiert,
## Materialien kommen aus der `Materialbibliothek`. Keine fremden Dateien.
##
## Renderer: `gl_compatibility` – nur einfache Standardmaterialien.

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

## Laubtöne der Bäume – wenige Töne, damit der Materialspeicher klein bleibt.
const LAUBTOENE: Array[Color] = [
	Color(0.22, 0.47, 0.16),
	Color(0.13, 0.30, 0.12),
	Color(0.41, 0.66, 0.24),
	Color(0.30, 0.52, 0.17),
	Color(0.46, 0.60, 0.21),
]

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
	_baue_licht()
	_baue_kamera()
	_baue_boden()
	_streue_wald()
	_stelle_kamera(0.0)


func _process(delta: float) -> void:
	_zeit += delta
	_stelle_kamera(_zeit)


# ------------------------------------------------------------- Umgebung

func _baue_umgebung() -> void:
	var himmelsstoff := ProceduralSkyMaterial.new()
	himmelsstoff.sky_top_color = Color(0.25, 0.45, 0.68)
	himmelsstoff.sky_horizon_color = Color(0.66, 0.76, 0.76)
	himmelsstoff.sky_curve = 0.12
	himmelsstoff.ground_bottom_color = Color(0.16, 0.20, 0.16)
	himmelsstoff.ground_horizon_color = Color(0.66, 0.76, 0.76)
	himmelsstoff.sun_angle_max = 25.0
	himmelsstoff.sun_curve = 0.2

	var himmel := Sky.new()
	himmel.sky_material = himmelsstoff

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
	umgebung.fog_light_color = Farben.NEBEL.darkened(0.10)
	umgebung.fog_light_energy = 0.70
	umgebung.fog_density = 0.045
	umgebung.fog_aerial_perspective = 0.35
	umgebung.fog_sky_affect = 0.14
	umgebung.fog_height = 2.0
	umgebung.fog_height_density = 0.14
	umgebung.adjustment_enabled = true
	umgebung.adjustment_brightness = 0.94
	umgebung.adjustment_contrast = 1.08
	umgebung.adjustment_saturation = 1.14

	var knoten := WorldEnvironment.new()
	knoten.name = "Umgebung"
	knoten.environment = umgebung
	add_child(knoten)


func _baue_licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.name = "Sonne"
	# Flacher als im Level: streift durch die Stämme und gibt Silhouetten.
	sonne.rotation_degrees = Vector3(-24.0, 118.0, 0.0)
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
