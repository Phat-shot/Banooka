extends RefCounted
class_name L01Gelaende
## Level 01, Modul „Gelände": Tal, Oberland, Knoll, Wurzelgruben, Bach,
## Randhügel (Plan Abschnitt 8.4).
##
## WAS HIER ENTSTEHT. Ein Höhenfeld ohne Kollision über das ganze Level
## (`FELD`, weiter als die 220 × 270 m des Plans: Die Randhügel sollen von
## jeder Station 100–150 m weit stehen, und von der Wendel aus lagen die
## Nordhügel sonst nur 40 m entfernt):
## * **Oberland** im Westen: der Hallenwaldboden (26 m) um den Start, hinter
##   der Böschung von B und der Wand von C die Krone, dahinter der
##   **Westhang** bis y ≈ 42. Nach Norden läuft es im weichen **Nordfuß**
##   (`NORDFUSS`, kein Abbruch – der hätte das Schlussbild verstellt) zum
##   Bach aus; hinter der Wand von C4 sinkt es bis zu deren Ende auf 12 m.
##   Hinter dem Wasserfallpfeiler ein Hügel, aus dem der Oberlauf quillt;
##   über der Kerbe eine Rinne, die im Rinnsal der Kerbe endet.
## * **Talmulde** im Osten (y 4–7, zwei Oktaven Rauschen, einige Kuppen),
##   am Fuß der Felswand ein Schutthang.
## * Um den **Weltenbaum**: im Süden und Westen der Knoll (6–8 m), im
##   Norden und Osten die **Wurzelgruben** (Boden −2), im Südosten die
##   **Wurzelwiese** genau auf 7,0.
## * Der **Bach** als gegrabenes Bett (`bachlauf()`): Tümpel unter dem
##   unteren Fall, Kanal am Fuß von C4 (`KANAL` – er ersetzt die Punkte 1–2
##   von `Level01.BACH`, die 20 m weiter im Tal lagen), Furt, am Knoll
##   vorbei nach Norden durch eine Schlucht aus dem Tal. Die Ufer liegen
##   über dem Wasserspiegel, damit die Wasserflächen im Ufer enden – nur
##   im Kanal steht das Wasser an der Wand von C4.
## * **Randhügel** im Osten, Norden und Süden (y 30–45) mit Felsen auf dem
##   Kamm (`GelaendeFeld.felsbrocken`, in die Stücke gemischt).
##
## NÄHTE (`Level01.rand_profil`). Das Feld bleibt immer UNTER dem, was der
## Saum baut, und hält Abstand zu dem, wo eine Figur fällt:
##   FLACH (A, D)   genau auf der Wegkante (2 cm darunter), Rasen in der
##                  Farbe der Wegdecke, Verdeckung ab 0,78 wie deren Rand
##   FELS_AB        eine innere Wand 1,5 m hinter der Saumwand, oben 3 m
##                  senkrecht (wie deren Unterschnitt), unten ein Schutthang,
##                  der den Fuß der Saumwand begräbt; nichts über der
##                  Fallbahn (6,5 m unter der Lippe)
##   Ecke (A)       um die Ecke der Hochfläche (s 21–33) bricht der Hallen-
##                  waldboden 1,35 m hinter der Lippe des Saums steil ab
##                  (`L01Saum.lippe_q`), hinter dessen Wand; dessen Narbe
##                  reicht darüber 1,8 m nach innen
##   links (Saum)   Böschung, Felsnase, Wand und Becken nach den Querschnitten,
##                  die der Saum baut (`L01Saum.querschnitte_links`, s 27,7
##                  bis 158): unter dem Hang 1,5 m unter der Linie Fuß →
##                  Kronenkante und immer 0,35 m unter der Fläche, hinter der
##                  Wand tief (im Becken unter dessen Grund), unter der Krone
##                  0,35 m darunter, ab 2,5–4,5 m hinter der Kronenkante darf
##                  das Land darüber treten, am Ende der Krone deckt es sie
##                  0,35 m hoch zu; das Oberland beginnt dort auf dieser Höhe
##   BOESCHUNG      (ohne Saum) 1,5 m unter der Linie Wegkante → Krone, an
##                  der Krone mit 2 m Überlappung
##   FELS_AUF       (ohne Saum, C4 hinter 158) eine innere Wand 1,5–2,5 m
##                  hinter der Wegkante bis zur Krone, dahinter bündig
##   UFER (C4)      vom Wegrand hinab in den Kanal; in der Furt bis 1,8 m
##                  hinter den Deckenkanten unter dem Ufer, das der Saum baut
##   Lücken         Erdspalt als scharfer Riss, der 5 m in den Waldboden
##                  ausläuft; unter Kerbe und Fallkerbe tief und dunkel,
##                  unter jeder Todeszone
## Unter der Decke (außer FLACH) liegt das Feld 3 m tief.
##
## STOFF (`shaders/gelaende.gdshader`): Scheitelfarben R Wiese, G Waldboden,
## B Fels, A Schlamm; UV2.x die gebackene Verdeckung (Walddach, Kronen-
## schatten des Weltenbaums, Gruben, Mulden, Wegrand), UV2.y die Stärke
## des Kronenlichts, UV.x eine Tönung (−1 kühl in Senken und Nordhängen,
## +1 warm auf Kuppen). Rasen aus `wald_gemeinsam` – dieselbe Farbe wie die
## Wegdecke.
##
## FÜR ANDERE MODULE:
##   `hoehe(x, z)`   gezeichnete Höhe (nach dem Bau, sonst die Funktion)
##   `wald(x, z)`    Walddichte 0..1 – danach ist der Boden abgedunkelt;
##                   der Waldsetzer pflanzt am besten genau dort
##   `bachlauf()`    die Bachlinien, wie das Bett gegraben ist
##   `optik(...)`    für Wurzelwiese und Wiesenboden G1: ein leerer Knoten –
##                   den Boden dort zeichnet das Feld selbst
##
## KOSTEN: 6 Stücke und der Bachnebel = höchstens 7 Zeichenaufrufe, ohne
## Schatten.

const GELAENDE_SHADER := preload("res://shaders/gelaende.gdshader")

## Das Feld in Welt-XZ (x_min, z_min, Breite, Tiefe) und seine Stücke.
const FELD := Rect2(-80.0, -320.0, 290.0, 365.0)
const STUECKE := Vector2i(2, 3)

## Punktabstände: nah am Weg (bis 16 m), bis 40 m, bis 90 m, darüber. Der
## Quadtree von `GelaendeFeld` halbiert ab 16 m, daraus werden Zellen von
## 2, 4, 8 und 16 m.
const ABSTAND_NAH := 2.0
const ABSTAND_MITTE := 4.0
const ABSTAND_WEIT := 8.0
const ABSTAND_FERN := 13.0

## So weit liegt das Feld unter einer FLACH-Decke.
const UNTER_DECKE := 0.02
## Unter allen anderen Decken.
const UNTER_WEG := 3.0

## Talboden und Westhang (Höhe und Lage des Kamms).
const TAL_Y := 5.2
const HANG_Y := 42.0
const WESTKAMM_X := -50.0

## Weltenbaum.
const ACHSE := Vector2(72.0, -174.0)
const WIESE_Y := 7.0

## Der Oberlauf (eine Quelle in der Flanke des Pfeilerhügels bis zum oberen
## Fall bei q −8,6) und die Rinne über der Kerbe (bis zum Rinnsal bei
## q −9,5): Stellen am Weg (s, q, Welt-Y des Wasserspiegels).
const OBERLAUF := [Vector3(117.8, -30.0, 35.4), Vector3(117.3, -21.0, 33.8),
		Vector3(116.9, -14.5, 32.5), Vector3(116.6, -10.2, 31.8)]
const RINNE_KERBE := [Vector3(58.5, -30.0, 30.4), Vector3(57.8, -20.0, 29.4),
		Vector3(57.5, -13.0, 29.1), Vector3(57.5, -10.0, 28.8)]

## Der Kanal am Fuß von C3/C4 (Plan 5C: „Ab s 145 läuft der Bach am Fuß von
## C4"): Stellen (s, q). Die Punkte 2–3 von `Level01.BACH` liegen 20 m
## draußen im Tal; das Bett folgt hier dem Fuß, siehe `bachlauf()`.
const KANAL := [Vector2(126.0, 12.0), Vector2(133.0, 10.2), Vector2(140.0, 9.4),
		Vector2(147.0, 9.2), Vector2(153.0, 9.8), Vector2(158.0, 12.0), Vector2(163.0, 16.2)]

## Kuppen im Tal: (x, z, Radius, Höhe).
const KUPPEN := [
	Vector4(52.0, -52.0, 22.0, 4.5), Vector4(96.0, -38.0, 32.0, 9.0),
	Vector4(112.0, -96.0, 30.0, 8.0), Vector4(78.0, -78.0, 18.0, 3.0),
	Vector4(128.0, -152.0, 24.0, 7.0), Vector4(104.0, -222.0, 22.0, 6.5),
	Vector4(62.0, -16.0, 24.0, 5.0), Vector4(140.0, -60.0, 26.0, 8.0),
]

## Hügel hinter dem Wasserfallpfeiler (s, q, Radius, Höhe): Aus ihm kommt
## der Oberlauf, der oben über den Pfeiler stürzt (y 31,5).
const PFEILERHUEGEL := Vector4(117.0, -24.0, 15.0, 11.5)

## Der Fuß des Westhangs im Norden (x, z, Höhe am Fuß), von der Wand am
## Ende von C4 an: Der Grat von C fällt nach Nordwesten ins Bachtal, dahinter
## steigt der Westhang. Kein Abbruch – vom Kronentor aus (Schlussbild, Blick
## nach Südsüdwest) liegt hier das Tal offen bis zum Wasserfall und zum Grat.
const NORDFUSS := [Vector3(37.5, -152.5, 14.0), Vector3(34.0, -159.5, 9.0),
		Vector3(31.0, -168.0, 7.2), Vector3(29.0, -180.0, 6.8),
		Vector3(27.0, -195.0, 6.4), Vector3(24.5, -212.0, 6.0), Vector3(21.0, -232.0, 5.6),
		Vector3(16.0, -255.0, 5.2), Vector3(9.0, -278.0, 4.8), Vector3(-2.0, -300.0, 4.4),
		Vector3(-15.0, -335.0, 4.0)]
## Übergangsbreite (halb) zwischen Tal und Oberland: an Kanten steil, am
## Nordfuß weich.
const KANTE_STEIL := 1.5
const FUSS_WEICH := 9.0

## Die Talmulde für die Randhügel: Mitte und Halbachsen (Welt-XZ).
const TAL_MITTE := Vector2(72.0, -122.0)
const TAL_RADIEN := Vector2(108.0, 152.0)

## Querriegel im Tal (x0, z0, x1, z1) mit (Breite, Höhe): Sie teilen den
## Blick vom Grat in Bänder – naher Talboden, Riegel, ferner Boden, Hügel.
const RIEGEL := [Vector4(58.0, -72.0, 112.0, -84.0), Vector4(98.0, -130.0, 142.0, -114.0)]
const RIEGEL_MASS := [Vector2(16.0, 5.5), Vector2(18.0, 7.0)]

## Die Ostkante des Hallenwaldbodens (s, q) bis zur Lippe von B.
const HALLENKANTE := [Vector2(-60.0, 27.0), Vector2(0.0, 27.0), Vector2(18.0, 26.0),
		Vector2(23.0, 23.5), Vector2(25.5, 19.0), Vector2(27.5, 13.0), Vector2(29.5, 9.6),
		Vector2(31.3, 7.8), Vector2(32.6, 6.2), Vector2(33.3, 5.0)]
## So weit hinter der Hallenkante beginnt der Westhang zu steigen: Der
## Boden um A bleibt eben.
const HALLE_EBEN := 40.0

## Nebel über dem Bach: alle so viele Meter eine Tafel, nicht näher als
## so am Wegrand, wenn das Wasser weniger als so tief unter der Decke
## liegt (Furt, Tümpel am Weg: Dort bleibt die Sicht auf die Figur frei).
const NEBEL_SCHRITT := 6.0
const NEBEL_WEGABSTAND := 8.0
const NEBEL_UNTER_DECKE := 5.0
## Deckkraft in der Mitte einer Tafel und wie nah an der Kamera sie
## ausgeblendet ist (von, bis in Metern).
const NEBEL_STAERKE := 0.26
const NEBEL_NAH := Vector2(7.0, 20.0)

## Tafeln, die sich um die Hochachse zur Kamera drehen; die vier Ecken
## einer Tafel liegen alle in ihrer Mitte, UV sagt, welche Ecke, UV2 die
## Größe, COLOR.r die Phase, COLOR.a die Kraft. Schlichtes Alpha, keine
## Tiefentextur: Die Tafel verblasst zu allen Rändern, damit ihr Schnitt
## mit dem Ufer nicht zu sehen ist.
const NEBEL_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, skip_vertex_transform, shadows_disabled;

uniform vec3 farbe : source_color = vec3(0.6, 0.7, 0.64);
uniform float staerke = 0.26;
uniform vec2 nah = vec2(7.0, 20.0);

varying float abstand;
varying float phase;
varying float kraft;

void vertex() {
	vec3 mitte = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	phase = COLOR.r * 6.2832;
	kraft = COLOR.a;
	mitte.y += sin(TIME * 0.21 + phase) * 0.12;
	vec3 zur_kamera = CAMERA_POSITION_WORLD - mitte;
	zur_kamera.y = 0.0;
	vec3 rechts = normalize(vec3(zur_kamera.z, 0.0, -zur_kamera.x) + vec3(1e-4, 0.0, 0.0));
	vec3 welt = mitte + rechts * (UV.x - 0.5) * UV2.x + vec3(0.0, (0.5 - UV.y) * UV2.y, 0.0);
	abstand = distance(welt, CAMERA_POSITION_WORLD);
	VERTEX = (VIEW_MATRIX * vec4(welt, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float u = abs(UV.x * 2.0 - 1.0);
	float v = 1.0 - UV.y;
	float a = (1.0 - smoothstep(0.1, 1.0, u)) * smoothstep(0.0, 0.32, v) * (1.0 - smoothstep(0.3, 1.0, v));
	float wogen = 0.78 + 0.22 * sin(UV.x * 4.0 + phase + TIME * 0.23) * sin(v * 3.0 - TIME * 0.17 + phase * 1.7);
	ALBEDO = farbe;
	ALPHA = clamp(a * wogen * staerke * kraft * smoothstep(nah.x, nah.y, abstand), 0.0, 1.0);
}
"""

static var _modell: Modell = null
static var _feld: GelaendeFeld = null
static var _stoff_cache: ShaderMaterial = null
static var _nebel_shader: Shader = null


# ================================================================ Haken

## Bauschritte, je {"text": String, "tun": Callable}. Das Modell entsteht
## sofort: `hoehe()` und `wald()` gelten damit schon beim Zusammenstellen
## der Schritte der anderen Module.
static func bauschritte(level: Level01) -> Array:
	einrichten(level)
	var feld := _feld_anlegen()
	var schritte: Array = [{"text": "Das Tal wird vermessen", "tun": func() -> void:
		_modell.sammeln = true
		feld.kanten = _modell.kanten()
		feld.beigaben = _modell.felsen()
		feld.punkte_setzen()}]
	for s in feld.anzahl():
		var nummer := s
		schritte.append({"text": "Hänge werden geformt (%d/%d)" % [s + 1, feld.anzahl()],
				"tun": func() -> void: feld.stueck_triangulieren(nummer)})
	schritte.append({"text": "Das Tal bekommt Farbe", "tun": func() -> void:
		_netze_bauen(level, feld)})
	schritte.append({"text": "Nebel steigt vom Bach", "tun": func() -> void:
		_nebel_bauen(level)})
	return schritte


## Legt das Höhenmodell an (ohne Netze): Wegstellen, Bach, Oberkante.
static func einrichten(level: Level01) -> void:
	_modell = Modell.new(level)
	_feld = null


## Geländehöhe (Welt-Y) an einer Stelle: nach dem Bau die gezeichnete
## Fläche, vorher die Höhenfunktion, ohne Level der Talboden.
static func hoehe(x: float, z: float) -> float:
	if _feld != null and _feld.fertig():
		var h := _feld.hoehe_bei(x, z)
		if not is_nan(h):
			return h
	if _modell != null:
		return _modell.hoehe(x, z)
	return 4.0


## Walddichte (0 Lichtung/Wiese .. 1 dichter Wald). Unter Wald ist der
## Boden abgedunkelt; wer Bäume setzt, setzt sie am besten dorthin.
static func wald(x: float, z: float) -> float:
	if _modell == null:
		return 0.0
	return _modell.wald(x, z)


## Die Bachlinien, wie das Bett gegraben ist: je Lauf {"name",
## "punkte": PackedVector3Array (x, Wasserspiegel, z), "bett":
## PackedFloat32Array, "breite": PackedFloat32Array (Wasserbreite),
## "toedlich": PackedByteArray}. Das Ufer liegt bis zur halben Breite unter
## dem Spiegel und darüber 0,3 m über ihm – eine Wasserfläche dieser Breite
## endet im Ufer. Läufe: "bach" (Tümpel → Kanal → Furt → Norden),
## "oberlauf" (vom Pfeilerhügel zum oberen Fall), "rinne" (über der Kerbe).
static func bachlauf() -> Array:
	if _modell == null:
		return []
	return _modell.laeufe_ausgeben()


## Optik für Wurzelwiese und Wiesenboden G1: Das Höhenfeld zeichnet beide
## selbst (flach auf 7,0), hier steht nur ein leerer Knoten.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	var leer := Node3D.new()
	leer.name = "ImGelaende"
	return leer


# ================================================================ Bau

static func _feld_anlegen() -> GelaendeFeld:
	var m := _modell
	var feld := GelaendeFeld.new()
	feld.bereich = FELD
	feld.stuecke = STUECKE
	feld.hoehe = m.hoehe
	feld.abstand = m.punktabstand
	feld.faerben = m.farbe
	feld.zusatz = m.zusatz
	feld.zusatz2 = m.toenung
	_feld = feld
	return feld


static func _netze_bauen(level: Level01, feld: GelaendeFeld) -> void:
	feld.stoff = _stoff()
	feld.normalen_rechnen()
	var mulden := feld.mulden_rechnen()
	var netze: Array[ArrayMesh] = []
	for s in feld.anzahl():
		netze.append(feld.stueck_netz(s, mulden))
	feld.knoten_bauen(level.geometrie, netze, "Gelaende")
	_modell.ablage_leeren()
	if level.debug:
		var z := feld.zaehlen()
		print("Gelände: %d Punkte, %d Dreiecke" % [z.x, z.y])


## Nebeltafeln über dem Hauptbach, ein Netz, ein Zeichenaufruf. Die Farbe
## ist das Nebellicht der Umgebung, etwas heller: Der Dunst über dem
## Wasser steht vor dem Talnebel, nicht in einer anderen Farbe.
static func _nebel_bauen(level: Level01) -> void:
	var tafeln := _modell.nebel_tafeln()
	if tafeln.is_empty():
		return
	var ecken := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var farben := PackedColorArray()
	var indizes := PackedInt32Array()
	var huelle := AABB()
	var rand := 0.0
	for k in tafeln.size():
		var t: Dictionary = tafeln[k]
		var mitte: Vector3 = t["mitte"]
		var mass: Vector2 = t["mass"]
		var c := Color(float(t["phase"]), 0.0, 0.0, float(t["kraft"]))
		var basis := ecken.size()
		for ecke: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			ecken.append(mitte)
			uv.append(ecke)
			uv2.append(mass)
			farben.append(c)
		indizes.append_array(PackedInt32Array([basis, basis + 1, basis + 2,
				basis, basis + 2, basis + 3]))
		huelle = AABB(mitte, Vector3.ZERO) if k == 0 else huelle.expand(mitte)
		rand = maxf(rand, maxf(mass.x, mass.y) * 0.5 + 0.2)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = ecken
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_COLOR] = farben
	arrays[Mesh.ARRAY_INDEX] = indizes
	var netz := ArrayMesh.new()
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Die Ecken liegen in den Mitten: Die Hülle muss die Tafeln fassen.
	netz.custom_aabb = huelle.grow(rand)
	if _nebel_shader == null:
		_nebel_shader = Shader.new()
		_nebel_shader.code = NEBEL_SHADER_CODE
	var stoff := ShaderMaterial.new()
	stoff.shader = _nebel_shader
	stoff.render_priority = 1
	var licht := Color(0.42, 0.52, 0.46)
	var umgebung := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if umgebung != null and umgebung.environment != null:
		licht = umgebung.environment.fog_light_color
	stoff.set_shader_parameter("farbe", licht.lightened(0.22))
	stoff.set_shader_parameter("staerke", NEBEL_STAERKE)
	stoff.set_shader_parameter("nah", NEBEL_NAH)
	var knoten := MeshInstance3D.new()
	knoten.name = "Bachnebel"
	knoten.mesh = netz
	knoten.material_override = stoff
	knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	knoten.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	level.geometrie.add_child(knoten)
	if level.debug:
		print("Bachnebel: %d Tafeln" % tafeln.size())


## Der Stoff des Feldes. Geteilt – nie verändern.
static func _stoff() -> ShaderMaterial:
	if _stoff_cache != null:
		return _stoff_cache
	var m := ShaderMaterial.new()
	m.shader = GELAENDE_SHADER
	Wegmaske.einrichten(m)
	m.set_shader_parameter("waldboden", Materialbibliothek.waldboden().albedo_texture)
	m.set_shader_parameter("fels", Materialbibliothek.fels().albedo_texture)
	m.set_shader_parameter("erde", Materialbibliothek.waldweg().albedo_texture)
	_stoff_cache = m
	return m


# ================================================================ Modell

## Alles, was die Höhenfunktion braucht, vorab aus dem Level gelesen: Der
## Level-Knoten selbst wird nicht gehalten.
class Modell:
	extends RefCounted

	const S_MIN := -60.0
	const S_MAX := 320.0
	const S_SCHRITT := 0.5
	# Saum links: Profilpunkt der Kronenkante; bis hierhin (s) gilt sein
	# Profil; so weit (m) bleibt das Gelände unter seinen Flächen und so
	# weit deckt es das Ende der Krone zu.
	const SAUM_KRONE := 20
	const SAUM_LINKS_BIS := 158.0
	const SAUM_UNTER := 0.35
	const SAUM_DECKT := 0.35
	# Die Ecke der Hochfläche (s von, bis), wie weit die Oberkante des
	# Geländes hinter der Lippe liegt und wie steil sie abbricht
	const ECKE := Vector2(21.0, 33.2)
	const ECKE_ABSTAND := 1.35
	const ECKE_WEICH := 0.35
	# So weit hinter der Lippe des Erdspalts (Saum) steht die Wand des
	# Feldes, und so weit dahinter erreicht es den Waldboden
	const SPALT_WAND := 0.85
	const SPALT_LIPPE := 1.05
	# Randtypen
	const FLACH := 0
	const BOESCHUNG := 1
	const FELS_AUF := 2
	const FELS_AB := 3
	const UFER := 4
	const WURZEL := 5
	const KEIN := 6
	# Zellen des Rasters für die Suche an der Oberkante
	const OBER_ZELLE := 8.0
	# Raster der Bachsuche und wie weit ein Bach (über die halbe Breite
	# hinaus) wirkt
	const BACH_ZELLE := 6.0
	const BACH_REICHWEITE := 8.0

	var anzahl := 0
	var px := PackedFloat32Array()
	var pz := PackedFloat32Array()
	var rx := PackedFloat32Array()
	var rz := PackedFloat32Array()
	var deck := PackedFloat32Array()
	var wegrand := PackedFloat32Array()
	var breite := PackedFloat32Array()
	var kronenlicht := PackedFloat32Array()
	# je Seite (0 links, 1 rechts)
	var typ: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array()]
	var abstand: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array()]
	var fuss: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array()]
	var krone: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array()]
	var krone_q: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array()]
	# Die linke Seite, wie der Saum sie baut (`L01Saum.querschnitte_links`),
	# je Stelle: das Profil als Vector2(|q|, Y) und daraus Fuß, Wand (größtes
	# |q| unter der Krone), Kronenkante und Kronenende. `saum_da` 0: kein
	# Saum links (dort gilt das Randprofil aus `rand_profil`).
	var saum_da := PackedByteArray()
	var saum_reihen: Array[PackedVector2Array] = []
	var saum_fuss_y := PackedFloat32Array()
	var saum_wand_q := PackedFloat32Array()
	var saum_kante_q := PackedFloat32Array()
	var saum_ende_q := PackedFloat32Array()
	var saum_ende_y := PackedFloat32Array()
	# Die Ecke der Hochfläche vor s 33 (Oberkante des Geländes, Wegkoordinaten)
	# und die halbe Übergangsbreite je Punkt
	var hallenkante := PackedVector2Array()
	var hallenkante_weich := PackedFloat32Array()
	# Die Furt (s von–bis), deren Ufer der Saum zeichnet
	var furt := Vector2(173.0, 183.0)
	var flach_kurve := Curve3D.new()
	var laengen := PackedFloat32Array()
	var ende_s := 287.0
	# Bachläufe: je {"name", "p": PackedVector2Array, "bett", "wasser",
	# "breite", "toedlich"}
	var laeufe: Array[Dictionary] = []
	# Oberkante des Oberlands: Punkte, Grundhöhe, Anfang des Anstiegs
	var ober_p := PackedVector2Array()
	var ober_oben := PackedFloat32Array()
	var ober_anfang := PackedFloat32Array()
	var ober_weich := PackedFloat32Array()
	var ober_raster: Dictionary = {}
	var ober_vieleck := PackedVector2Array()
	var pfeilerhuegel := Vector2.ZERO
	var rausch_grob := FastNoiseLite.new()
	var rausch_fein := FastNoiseLite.new()
	var rausch_wald := FastNoiseLite.new()
	var rausch_kamm := FastNoiseLite.new()
	var luecken: Array[Vector2] = []
	var erdspalt := Vector2(25.0, 27.5)
	# Zwischenablage für farbe()/zusatz() desselben Punkts
	var _letzter := Vector3(INF, INF, INF)
	var _letzt_sq := Vector2.ZERO
	var _letzt_wald := 0.0
	var _ablage: Dictionary = {}
	## Während des Baus: Projektion und Oberkante je Punkt aufheben.
	var sammeln := false

	func _init(level: Level01) -> void:
		ende_s = Level01.M_ENDE
		_rauschen_anlegen()
		_weg_lesen(level)
		_saum_lesen(level)
		_hallenkante_anlegen(level)
		_luecken_lesen(level)
		_laeufe_anlegen(level)
		_oberkante_anlegen()
		pfeilerhuegel = _weg_welt(PFEILERHUEGEL.x, PFEILERHUEGEL.y)

	func _rauschen_anlegen() -> void:
		rausch_grob.seed = 4101
		rausch_grob.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		rausch_grob.frequency = 1.0 / 55.0
		rausch_grob.fractal_octaves = 2
		rausch_fein.seed = 4102
		rausch_fein.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		rausch_fein.frequency = 1.0 / 16.0
		rausch_fein.fractal_octaves = 2
		rausch_wald.seed = 4103
		rausch_wald.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		rausch_wald.frequency = 1.0 / 38.0
		rausch_wald.fractal_octaves = 3
		rausch_kamm.seed = 4104
		rausch_kamm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		rausch_kamm.frequency = 1.0 / 70.0
		rausch_kamm.fractal_octaves = 2

	# ------------------------------------------------------------ Weg

	func _weg_lesen(level: Level01) -> void:
		var v: Curve3D = level.verlauf
		var laenge := v.get_baked_length()
		anzahl = int(round((S_MAX - S_MIN) / S_SCHRITT)) + 1
		px.resize(anzahl)
		pz.resize(anzahl)
		rx.resize(anzahl)
		rz.resize(anzahl)
		deck.resize(anzahl)
		wegrand.resize(anzahl)
		breite.resize(anzahl)
		kronenlicht.resize(anzahl)
		laengen.resize(anzahl)
		for seite in 2:
			typ[seite].resize(anzahl)
			abstand[seite].resize(anzahl)
			fuss[seite].resize(anzahl)
			krone[seite].resize(anzahl)
			krone_q[seite].resize(anzahl)
		flach_kurve.bake_interval = 0.5
		# wie `L01Boden.kronenlicht_bei`, die Stützstellen nur einmal geholt
		var kronen := L01Boden.kronen_stellen(level)
		var summe := 0.0
		var vorher := Vector2.ZERO
		for i in anzahl:
			var s := S_MIN + S_SCHRITT * float(i)
			var p := LevelWerkzeuge.punkt_frei(v, s)
			var r := LevelWerkzeuge.richtung(v, clampf(s, 0.0, laenge)).cross(Vector3.UP).normalized()
			px[i] = p.x
			pz[i] = p.z
			rx[i] = r.x
			rz[i] = r.z
			deck[i] = level.boden_bei(clampf(s, -30.0, ende_s + 30.0))
			breite[i] = level.breite_bei(s) if s >= 0.0 and s <= ende_s else 0.0
			kronenlicht[i] = _kronen_bei(kronen, s)
			var jetzt := Vector2(p.x, p.z)
			if i > 0:
				summe += jetzt.distance_to(vorher)
			laengen[i] = summe
			vorher = jetzt
			# Nur bis zum Ende: Die gerade Verlängerung dahinter (Kurs −150°)
			# liefe hinter die Wand von C4 und finge dort die Punkte ein, die
			# zu deren Krone gehören. Hinter dem Ende rechnet `projektion`.
			if s <= ende_s + 0.001:
				flach_kurve.add_point(Vector3(p.x, 0.0, p.z))
			for seite in 2:
				var rp := level.rand_profil(s, -1.0 if seite == 0 else 1.0)
				wegrand[i] = float(rp["wegrand"])
				var t := _typ(String(rp["typ"]))
				if s < -12.0 or s > ende_s + 0.3:
					t = KEIN
				typ[seite][i] = t
				abstand[seite][i] = float(rp["abstand"])
				fuss[seite][i] = float(rp["fuss_y"])
				krone[seite][i] = float(rp["krone_y"])
				var eintrag: Dictionary = rp["eintrag"]
				var kq: float = eintrag.get("krone_q", NAN)
				# Die Nische der Moosbank: der Böschungsfuß weicht zurück.
				if eintrag.has("nische"):
					var nq := level._polylinie_q(eintrag["nische"], s)
					if not is_nan(nq):
						abstand[seite][i] = maxf(abstand[seite][i], absf(nq))
						kq = maxf(kq, absf(nq) + 5.0)
				krone_q[seite][i] = kq

	## Die linke Seite, wie der Saum sie baut: je Stelle das Profil und seine
	## Kennwerte (siehe `saum_reihen`). Bis `SAUM_LINKS_BIS` – dahinter biegt
	## der Fuß quer zum Weg ab, dort gilt wieder das Randprofil.
	func _saum_lesen(level: Level01) -> void:
		saum_da.resize(anzahl)
		saum_da.fill(0)
		saum_reihen.resize(anzahl)
		saum_fuss_y.resize(anzahl)
		saum_wand_q.resize(anzahl)
		saum_kante_q.resize(anzahl)
		saum_ende_q.resize(anzahl)
		saum_ende_y.resize(anzahl)
		var daten := L01Saum.querschnitte_links(level)
		var strecken: PackedFloat32Array = daten["s"]
		var punkte: Array[PackedVector2Array] = daten["punkte"]
		var n := strecken.size()
		if n < 2:
			return
		var k := 0
		for i in anzahl:
			var s := S_MIN + S_SCHRITT * float(i)
			saum_reihen[i] = PackedVector2Array()
			if s < strecken[0] or s > minf(strecken[n - 1], SAUM_LINKS_BIS):
				continue
			while k < n - 2 and strecken[k + 1] < s:
				k += 1
			var t := clampf((s - strecken[k]) / maxf(strecken[k + 1] - strecken[k], 0.0001),
					0.0, 1.0)
			var a := punkte[k]
			var b := punkte[k + 1]
			var reihe := PackedVector2Array()
			reihe.resize(a.size())
			var wand := 0.0
			for j in a.size():
				reihe[j] = a[j].lerp(b[j], t)
				if j >= 2 and j < SAUM_KRONE:
					wand = maxf(wand, reihe[j].x)
			saum_reihen[i] = reihe
			saum_da[i] = 1
			saum_fuss_y[i] = reihe[2].y - 0.04
			saum_wand_q[i] = wand
			saum_kante_q[i] = reihe[SAUM_KRONE].x
			saum_ende_q[i] = reihe[reihe.size() - 1].x
			saum_ende_y[i] = reihe[reihe.size() - 1].y
		# Die Furt, deren Ufer der Saum zeichnet
		for r: Dictionary in Level01.RAENDER:
			if String(r["typ"]) == "UFER" and not r.has("kanal"):
				furt = Vector2(float(r["von"]), float(r["bis"]))

	## Höhe der Saumfläche links bei |q| = u an der Stelle i, zwischen den
	## Profilpunkten `von` und dem letzten (die Punkte steigen dort in |q|);
	## davor der erste, dahinter der letzte Wert.
	func _saum_hoehe(i: int, u: float, von: int) -> float:
		var reihe := saum_reihen[i]
		var n := reihe.size()
		if u <= reihe[von].x:
			return reihe[von].y
		for j in range(von, n - 1):
			var a := reihe[j]
			var b := reihe[j + 1]
			if u <= b.x:
				return lerpf(a.y, b.y, clampf((u - a.x) / maxf(b.x - a.x, 0.0001), 0.0, 1.0))
		return reihe[n - 1].y

	## Die Oberkante des Hallenwaldbodens: bis vor die Ecke aus `HALLENKANTE`,
	## um die Ecke der Hochfläche 1,35 m hinter der Lippe, die der Saum dort
	## baut (`L01Saum.lippe_q`, s 21–33,2), und steil (±0,35 m): Der Abbruch
	## liegt ganz hinter dessen Wand (0,5–0,85 m hinter der Lippe), über ihm
	## reicht dessen Narbe 1,8 m nach innen, unter den Waldboden.
	func _hallenkante_anlegen(level: Level01) -> void:
		hallenkante = PackedVector2Array()
		hallenkante_weich = PackedFloat32Array()
		for sq: Vector2 in HALLENKANTE:
			if sq.x < ECKE.x - 3.0:
				hallenkante.append(sq)
				hallenkante_weich.append(KANTE_STEIL)
		var lippe := PackedVector2Array()
		var s := ECKE.x
		while s < ECKE.y:
			lippe.append(Vector2(s, L01Saum.lippe_q(level, s, 1.0)))
			s += 0.25
		lippe.append(Vector2(ECKE.y, L01Saum.lippe_q(level, ECKE.y, 1.0)))
		for j in lippe.size():
			var t := lippe[mini(j + 1, lippe.size() - 1)] - lippe[maxi(j - 1, 0)]
			t = t.normalized()
			# nach innen: zum Weg und zurück in den Hallenwald
			hallenkante.append(lippe[j] + Vector2(t.y, -t.x) * ECKE_ABSTAND)
			hallenkante_weich.append(ECKE_WEICH)

	## Stärke des Kronenlichts an `s` aus den Stützstellen der Wegdecke
	## (stückweise linear wie `L01Boden.kronenlicht_bei`).
	static func _kronen_bei(stellen: PackedVector2Array, s: float) -> float:
		if stellen.is_empty():
			return 0.0
		var w := stellen[0].y
		for i in range(1, stellen.size()):
			var a := stellen[i - 1]
			var b := stellen[i]
			if s >= a.x:
				w = lerpf(a.y, b.y, clampf((s - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))
		return w

	static func _typ(name: String) -> int:
		match name:
			"FLACH":
				return FLACH
			"BOESCHUNG":
				return BOESCHUNG
			"FELS_AUF":
				return FELS_AUF
			"FELS_AB":
				return FELS_AB
			"UFER":
				return UFER
			"WURZEL":
				return WURZEL
		return KEIN

	func _luecken_lesen(level: Level01) -> void:
		for l: Dictionary in level.LUECKEN:
			luecken.append(Vector2(float(l["von"]), float(l["bis"])))
			if String(l["name"]) == "Erdspalt":
				erdspalt = Vector2(float(l["von"]), float(l["bis"]))

	## Weltpunkt (x, z) einer Stelle (s, q) auf dem Weg.
	func _weg_welt(s: float, q: float) -> Vector2:
		var f := clampf((s - S_MIN) / S_SCHRITT, 0.0, float(anzahl - 1))
		var i := mini(floori(f), anzahl - 2)
		var t := f - float(i)
		var x := lerpf(px[i], px[i + 1], t) + lerpf(rx[i], rx[i + 1], t) * q
		var z := lerpf(pz[i], pz[i + 1], t) + lerpf(rz[i], rz[i + 1], t) * q
		return Vector2(x, z)

	## (s, q) eines Weltpunkts: nächste Stelle des Weges in der Ebene.
	func projektion(x: float, z: float) -> Vector2:
		var off := flach_kurve.get_closest_offset(Vector3(x, 0.0, z))
		var lo := 0
		var hi := anzahl - 1
		while hi - lo > 1:
			var mitte := (lo + hi) >> 1
			if laengen[mitte] <= off:
				lo = mitte
			else:
				hi = mitte
		var seg := laengen[hi] - laengen[lo]
		var t := clampf((off - laengen[lo]) / seg, 0.0, 1.0) if seg > 0.0 else 0.0
		var s := S_MIN + S_SCHRITT * (float(lo) + t)
		var cx := lerpf(px[lo], px[hi], t)
		var cz := lerpf(pz[lo], pz[hi], t)
		var r := Vector2(lerpf(rx[lo], rx[hi], t), lerpf(rz[lo], rz[hi], t)).normalized()
		var q := (x - cx) * r.x + (z - cz) * r.y
		# Hinter dem Ende geradeaus weiter, wie auf der Verlängerung
		if s >= ende_s - 0.01:
			var vor := (x - cx) * r.y - (z - cz) * r.x
			s += maxf(vor, 0.0)
		return Vector2(s, q)

	func _index(s: float) -> int:
		return clampi(int(round((s - S_MIN) / S_SCHRITT)), 0, anzahl - 1)

	func in_luecke(s: float) -> bool:
		for l in luecken:
			if s > l.x and s < l.y:
				return true
		return false

	# ------------------------------------------------------------ Bach

	func _laeufe_anlegen(level: Level01) -> void:
		# Hauptbach: Tümpel, Kanal am Fuß von C3/C4, dann BACH ab dem Knick
		# vor der Furt, zuletzt aus dem Tal hinaus
		var bach: Array = level.BACH
		var lauf := _neuer_lauf("bach")
		var tuempel: Dictionary = bach[0]
		var tp: Vector3 = tuempel["punkt"]
		_lauf_punkt(lauf, Vector2(tp.x, tp.z), float(tuempel["bett_y"]),
				float(tuempel["wasser_y"]), 9.0, false)
		for k in KANAL.size():
			var sq: Vector2 = KANAL[k]
			var t := float(k) / float(KANAL.size() - 1)
			_lauf_punkt(lauf, _weg_welt(sq.x, sq.y), lerpf(4.6, 4.8, t), lerpf(6.3, 6.2, t),
					7.0, true)
		# BACH[1] und BACH[2] ersetzt der Kanal; (76, −124) ist dessen Ende.
		for k in range(3, bach.size()):
			var e: Dictionary = bach[k]
			var w: Vector3 = e["punkt"]
			_lauf_punkt(lauf, Vector2(w.x, w.z), float(e["bett_y"]), float(e["wasser_y"]),
					float(e["breite"]), bool(e["toedlich"]))
		# Aus dem Tal hinaus: nach Norden, dann hinter dem Nordwestsporn nach
		# Westen – die Schlucht schaut nicht auf den Feldrand.
		_lauf_punkt(lauf, Vector2(36.0, -256.0), 2.8, 3.6, 7.0, false)
		_lauf_punkt(lauf, Vector2(31.0, -278.0), 2.3, 3.2, 6.5, false)
		_lauf_punkt(lauf, Vector2(20.0, -295.0), 1.9, 2.8, 6.0, false)
		_lauf_punkt(lauf, Vector2(2.0, -308.0), 1.5, 2.4, 6.0, false)
		_lauf_punkt(lauf, Vector2(-16.0, -322.0), 1.1, 2.0, 6.0, false)
		laeufe.append(lauf)
		for art: String in ["oberlauf", "rinne"]:
			var quelle: Array = OBERLAUF if art == "oberlauf" else RINNE_KERBE
			var neu := _neuer_lauf(art)
			for sqh: Vector3 in quelle:
				_lauf_punkt(neu, _weg_welt(sqh.x, sqh.y), sqh.z - 0.7, sqh.z,
						2.4 if art == "oberlauf" else 1.4, false)
			laeufe.append(neu)
		for l in laeufe:
			_bach_raster(l)

	## Je Zelle die Segmente, die näher als `BACH_REICHWEITE` kommen.
	func _bach_raster(lauf: Dictionary) -> void:
		var raster := {}
		var p: PackedVector2Array = lauf["p"]
		var br: PackedFloat32Array = lauf["breite"]
		for i in p.size() - 1:
			var weit := maxf(br[i], br[i + 1]) * 0.5 + BACH_REICHWEITE
			var a := p[i]
			var b := p[i + 1]
			var x0 := floori((minf(a.x, b.x) - weit) / BACH_ZELLE)
			var x1 := floori((maxf(a.x, b.x) + weit) / BACH_ZELLE)
			var z0 := floori((minf(a.y, b.y) - weit) / BACH_ZELLE)
			var z1 := floori((maxf(a.y, b.y) + weit) / BACH_ZELLE)
			for gx in range(x0, x1 + 1):
				for gz in range(z0, z1 + 1):
					var zelle := Vector2i(gx, gz)
					var liste: PackedInt32Array = raster.get(zelle, PackedInt32Array())
					liste.append(i)
					raster[zelle] = liste
		lauf["raster"] = raster

	func _neuer_lauf(name: String) -> Dictionary:
		return {"name": name, "p": PackedVector2Array(), "bett": PackedFloat32Array(),
				"wasser": PackedFloat32Array(), "breite": PackedFloat32Array(),
				"toedlich": PackedByteArray()}

	func _lauf_punkt(lauf: Dictionary, ort: Vector2, b: float, w: float, breit: float,
			toedlich: bool) -> void:
		var p: PackedVector2Array = lauf["p"]
		p.append(ort)
		lauf["p"] = p
		var bett: PackedFloat32Array = lauf["bett"]
		bett.append(b)
		lauf["bett"] = bett
		var wasser: PackedFloat32Array = lauf["wasser"]
		wasser.append(w)
		lauf["wasser"] = wasser
		var br: PackedFloat32Array = lauf["breite"]
		br.append(breit)
		lauf["breite"] = br
		var tod: PackedByteArray = lauf["toedlich"]
		tod.append(1 if toedlich else 0)
		lauf["toedlich"] = tod

	func laeufe_ausgeben() -> Array:
		var aus: Array = []
		for l: Dictionary in laeufe:
			var p: PackedVector2Array = l["p"]
			var wasser: PackedFloat32Array = l["wasser"]
			var punkte := PackedVector3Array()
			for i in p.size():
				punkte.append(Vector3(p[i].x, wasser[i], p[i].y))
			aus.append({"name": l["name"], "punkte": punkte,
					"bett": (l["bett"] as PackedFloat32Array).duplicate(),
					"breite": (l["breite"] as PackedFloat32Array).duplicate(),
					"toedlich": (l["toedlich"] as PackedByteArray).duplicate()})
		return aus

	## Nebeltafeln über dem Hauptbach: je {"mitte": Vector3, "mass":
	## Vector2 (Breite, Höhe), "phase", "kraft"}. Frei bleibt es, wo der
	## Bach nah am Weg und kaum unter der Decke liegt, und außerhalb des
	## Feldes.
	func nebel_tafeln() -> Array[Dictionary]:
		var aus: Array[Dictionary] = []
		var lauf: Dictionary = laeufe[0]
		var p: PackedVector2Array = lauf["p"]
		var wasser: PackedFloat32Array = lauf["wasser"]
		var br: PackedFloat32Array = lauf["breite"]
		var zufall := RandomNumberGenerator.new()
		zufall.seed = 5101
		var feld := FELD.grow(-6.0)
		var rest := NEBEL_SCHRITT * 0.5
		for i in p.size() - 1:
			var a := p[i]
			var b := p[i + 1]
			var laenge := a.distance_to(b)
			var d := (b - a) / maxf(laenge, 0.001)
			var quer := Vector2(-d.y, d.x)
			var weg := rest
			while weg < laenge:
				var t := weg / laenge
				weg += NEBEL_SCHRITT * zufall.randf_range(0.8, 1.2)
				var ort := a.lerp(b, t)
				var w := lerpf(wasser[i], wasser[i + 1], t)
				var breit := lerpf(br[i], br[i + 1], t)
				if not feld.has_point(ort):
					continue
				if _nah_am_weg(ort, w, breit * 0.5):
					continue
				var mitte := ort + quer * zufall.randf_range(-0.25, 0.25) * breit
				var hoch := zufall.randf_range(2.2, 3.0)
				aus.append({"mitte": Vector3(mitte.x, w - 0.25 + hoch * 0.5, mitte.y),
						"mass": Vector2(breit + zufall.randf_range(1.0, 3.0), hoch),
						"phase": zufall.randf(), "kraft": zufall.randf_range(0.65, 1.0)})
			rest = weg - laenge
		return aus

	## Liegt der Weg irgendwo nah und kaum über dem Wasser? Alle Stellen,
	## nicht nur die nächste: Die Wendel steht mehrfach über demselben Ort.
	func _nah_am_weg(ort: Vector2, w: float, halb: float) -> bool:
		var von := _index(0.0)
		var bis := _index(ende_s)
		for i in range(von, bis + 1, 2):
			if deck[i] - w >= NEBEL_UNTER_DECKE:
				continue
			var weit := NEBEL_WEGABSTAND + wegrand[i] + halb
			if ort.distance_squared_to(Vector2(px[i], pz[i])) < weit * weit:
				return true
		return false

	## Nächster Punkt eines Laufs: Vector4(Abstand, Bett, Wasser, Breite).
	## Weiter als `BACH_REICHWEITE` von jedem Segment: Abstand INF (über ein
	## Raster der Segmente, damit die vielen fernen Punkte nichts kosten).
	func _bach_naechst(lauf: Dictionary, x: float, z: float) -> Vector4:
		var p: PackedVector2Array = lauf["p"]
		var bett: PackedFloat32Array = lauf["bett"]
		var wasser: PackedFloat32Array = lauf["wasser"]
		var br: PackedFloat32Array = lauf["breite"]
		var q := Vector2(x, z)
		var bester := Vector4(INF, 0.0, 0.0, 0.0)
		var raster: Dictionary = lauf["raster"]
		var zelle := Vector2i(floori(x / BACH_ZELLE), floori(z / BACH_ZELLE))
		if not raster.has(zelle):
			return bester
		var liste: PackedInt32Array = raster[zelle]
		for i in liste:
			var a := p[i]
			var b := p[i + 1]
			var ab := b - a
			var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var d := q.distance_to(a + ab * t)
			if d < bester.x:
				bester = Vector4(d, lerpf(bett[i], bett[i + 1], t),
						lerpf(wasser[i], wasser[i + 1], t), lerpf(br[i], br[i + 1], t))
		return bester

	# ------------------------------------------------------------ Oberland

	func _oberkante_anlegen() -> void:
		# Ostkante des Hallenwaldbodens: eben bis `HALLE_EBEN` dahinter
		for k in hallenkante.size():
			var sq := hallenkante[k]
			_ober_punkt(_weg_welt(sq.x, sq.y), 26.0, HALLE_EBEN, hallenkante_weich[k])
		# Lippe von B und C: dahinter liegt die Krone der Böschung bzw. Wand –
		# das Land beginnt auf der Höhe, auf der der Saum sie enden lässt.
		var s := 34.0
		while s <= 143.0:
			var i := _index(s)
			var a_r := abstand[1][i]
			var anfang := a_r + abstand[0][i] + 4.5
			var oben := krone[0][i]
			if typ[0][i] == BOESCHUNG:
				anfang = a_r + krone_q[0][i] + 2.5
			if saum_da[i] == 1:
				anfang = a_r + saum_ende_q[i] + 1.0
				oben = saum_ende_y[i] + SAUM_DECKT
			_ober_punkt(_weg_welt(s, a_r), oben, anfang)
			s += 2.0
		# C4: über den Weg auf die linke Wand, dann der Nordfuß
		# Über den Weg auf die linke Wand von C4: Die Wand ist eine
		# Felsrippe, deren Rücken nach Nordwesten ins Bachtal fällt (die
		# Krone unmittelbar hinter der Wand hält das Profil in `_profil`).
		# Die Grundhöhe sinkt zum Ende der Wand – hinter 160 steht kein
		# Block Oberland, vom Kronentor aus liegt das Tal offen.
		for s4: float in [146.0, 150.0, 154.0, 158.0, 160.0]:
			var i := _index(s4)
			var t4 := smoothstep(146.0, 160.0, s4)
			var q4 := abstand[0][i] + 3.0
			var oben4 := krone[0][i]
			# Mit Saum: hinter dem Ende seiner Krone, auf deren Höhe
			if saum_da[i] == 1:
				q4 = saum_ende_q[i] + 0.5
				oben4 = saum_ende_y[i] + SAUM_DECKT
			_ober_punkt(_weg_welt(s4, -q4), lerpf(oben4, 12.0, t4),
					1.5, lerpf(KANTE_STEIL, FUSS_WEICH, t4))
		for f: Vector3 in NORDFUSS:
			_ober_punkt(Vector2(f.x, f.y), f.z, 0.0, FUSS_WEICH)
		# Geschlossen über den Westen: innen = Oberland
		ober_vieleck = ober_p.duplicate()
		var erster := ober_p[0]
		var letzter := ober_p[ober_p.size() - 1]
		ober_vieleck.append(Vector2(letzter.x, -1000.0))
		ober_vieleck.append(Vector2(-1000.0, -1000.0))
		ober_vieleck.append(Vector2(-1000.0, 1000.0))
		ober_vieleck.append(Vector2(erster.x, 1000.0))

	func _ober_punkt(p: Vector2, oben: float, anfang: float,
			weich: float = KANTE_STEIL) -> void:
		ober_p.append(p)
		ober_oben.append(oben)
		ober_anfang.append(anfang)
		ober_weich.append(weich)

	## Vorzeichenbehafteter Abstand zur Oberkante (positiv = im Oberland)
	## samt Grundhöhe, Anfang des Anstiegs und halber Übergangsbreite dort:
	## Vector4(Abstand, Grundhöhe, Anfang, Übergang). Je Zelle des Rasters werden die
	## Segmente, die für einen Punkt darin die nächsten sein können, beim
	## ersten Zugriff einmal gesucht (Abstand zur Zellmitte höchstens der
	## kleinste plus eine Zelldiagonale) – genau und stetig über das ganze
	## Feld.
	func _ober(x: float, z: float) -> Vector4:
		var q := Vector2(x, z)
		var zelle := Vector2i(floori(x / OBER_ZELLE), floori(z / OBER_ZELLE))
		var kandidaten: PackedInt32Array
		if ober_raster.has(zelle):
			kandidaten = ober_raster[zelle]
		else:
			kandidaten = _ober_kandidaten(zelle)
			ober_raster[zelle] = kandidaten
		# Leere Liste: die ganze Zelle liegt weit im Tal (siehe unten)
		if kandidaten.is_empty():
			return Vector4(-50.0, 0.0, 0.0, KANTE_STEIL)
		# Abstand = der kleinste; Grundhöhe und Anfang weich über alle nahen
		# Segmente gemittelt (sonst sprängen sie, wo der nächste Punkt von
		# einem Teil der Kante auf einen fernen anderen wechselt).
		var abstaende := PackedFloat32Array()
		var werte: Array[Vector3] = []
		var bester := INF
		for k in kandidaten:
			var a := ober_p[k]
			var ab := ober_p[k + 1] - a
			var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var d := q.distance_to(a + ab * t)
			abstaende.append(d)
			werte.append(Vector3(lerpf(ober_oben[k], ober_oben[k + 1], t),
					lerpf(ober_anfang[k], ober_anfang[k + 1], t),
					lerpf(ober_weich[k], ober_weich[k + 1], t)))
			bester = minf(bester, d)
		var summe := 0.0
		var mittel := Vector3.ZERO
		# Je weiter weg, desto weicher (fern ist ohnehin alles Westhang)
		var weich := 3.0 + 0.12 * bester
		for k in abstaende.size():
			var g := exp(-(abstaende[k] - bester) / weich)
			summe += g
			mittel += werte[k] * g
		mittel /= summe
		var ergebnis := Vector4(bester, mittel.x, mittel.y, mittel.z)
		# Die Seite über das geschlossene Vieleck (an Ecken der Kante wäre
		# die Seite des nächsten Segments falsch).
		if not Geometry2D.is_point_in_polygon(q, ober_vieleck):
			ergebnis.x = -ergebnis.x
		return ergebnis

	func _ober_kandidaten(zelle: Vector2i) -> PackedInt32Array:
		var mitte := (Vector2(zelle) + Vector2(0.5, 0.5)) * OBER_ZELLE
		var abstaende := PackedFloat32Array()
		var kleinster := INF
		for k in ober_p.size() - 1:
			var a := ober_p[k]
			var ab := ober_p[k + 1] - a
			var l2 := ab.length_squared()
			var d := INF
			if l2 > 1e-6:
				var t := clampf((mitte - a).dot(ab) / l2, 0.0, 1.0)
				d = mitte.distance_to(a + ab * t)
			abstaende.append(d)
			kleinster = minf(kleinster, d)
		# Alle Segmente, die für einen Punkt der Zelle unter den nahen der
		# weichen Mittelung sein können (drei Weichen weit, siehe `_ober`)
		var grenze := kleinster * 1.4 + 9.0 + OBER_ZELLE * 1.42 * 1.4
		var liste := PackedInt32Array()
		# Weit im Tal zählt nur die Seite: `_landschaft` nimmt dort das Tal.
		if kleinster > 20.0 and not Geometry2D.is_point_in_polygon(mitte, ober_vieleck):
			return liste
		for k in abstaende.size():
			if abstaende[k] <= grenze:
				liste.append(k)
		return liste

	# ------------------------------------------------------------ Höhe

	## Die Höhenfunktion: Landschaft, Weltenbaum, Bach, Nähte zum Weg,
	## Rinnen, Riss und Wiese.
	func hoehe(x: float, z: float) -> float:
		var sq := projektion(x, z)
		var o := _ober(x, z)
		if sammeln:
			_ablage[Vector2(x, z)] = [sq, o]
		var h := _landschaft(x, z, o)
		h = _baumzone(x, z, h)
		h = _baeche(x, z, h, true)
		h = _weg(x, z, sq, h, o)
		h = _baeche(x, z, h, false)
		h = _sonderzonen(sq, h)
		return h

	## Tal, Randhügel und Oberland in Weltkoordinaten.
	func _landschaft(x: float, z: float, o: Vector4) -> float:
		var tal := tal_hoehe(x, z)
		if o.x <= -o.w:
			return tal
		var ober := _oberland_hoehe(x, z, o)
		# Übergang: steil an der Hallenwaldkante (an B/C liegt ohnehin der
		# Weg davor), weich am Nordfuß.
		return lerpf(tal, ober, smoothstep(-o.w, o.w, o.x))

	func tal_hoehe(x: float, z: float) -> float:
		var h := TAL_Y + 1.4 * rausch_grob.get_noise_2d(x, z) \
				+ 0.45 * rausch_fein.get_noise_2d(x, z)
		# Süden etwas höher
		h += 1.2 * smoothstep(-60.0, 10.0, z)
		for k: Vector4 in KUPPEN:
			var d := Vector2(x - k.x, z - k.y).length() / k.z
			if d < 1.0:
				var f := 1.0 - d * d
				h += k.w * f * f * (1.0 + 0.2 * rausch_fein.get_noise_2d(x * 1.7, z * 1.7))
		for k in RIEGEL.size():
			var r: Vector4 = RIEGEL[k]
			var m: Vector2 = RIEGEL_MASS[k]
			var a := Vector2(r.x, r.y)
			var ab := Vector2(r.z, r.w) - a
			var tt := clampf((Vector2(x, z) - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var d := Vector2(x, z).distance_to(a + ab * tt) / m.x
			if d < 1.0:
				var f := 1.0 - d * d
				h += m.y * f * f * (0.8 + 0.4 * sin(tt * PI)) \
						* (1.0 + 0.25 * rausch_fein.get_noise_2d(x * 1.4, z * 1.4))
		# Randhügel rund um die Talmulde (abgerundetes Rechteck, 100–150 m
		# von den Stationen), im Norden die Kerbe des Bachs bei x ≈ 30
		var ex := (x - TAL_MITTE.x) / TAL_RADIEN.x
		var ez := (z - TAL_MITTE.y) / TAL_RADIEN.y
		var rund := pow(pow(absf(ex), 3.0) + pow(absf(ez), 3.0), 1.0 / 3.0)
		rund += 0.06 * rausch_kamm.get_noise_2d(x * 1.3, z * 1.3)
		# Ein Kamm, kein Tafelberg: Anstieg bis 1,0–1,06, dahinter fällt es
		# wieder (der Feldrand liegt so immer hinter dem Kamm).
		var t := smoothstep(0.66, 1.03, rund)
		t -= 0.35 * smoothstep(1.08, 1.4, rund)
		if z < -200.0:
			t *= smoothstep(24.0, 52.0, x + 0.25 * (z + 260.0))
		# Im Nordosten (nah an Bachwiese und Wendel) etwas niedriger
		var kamm := 37.0 + 8.0 * rausch_kamm.get_noise_2d(x, z) \
				+ 3.0 * rausch_grob.get_noise_2d(z * 1.5, x * 1.5) \
				- 6.0 * smoothstep(-150.0, -220.0, z) * smoothstep(90.0, 150.0, x)
		return lerpf(h, maxf(h, kamm), t)

	func _oberland_hoehe(x: float, z: float, o: Vector4) -> float:
		var anfang := o.z
		var anstieg := smoothstep(anfang + 4.0, anfang + 75.0, o.x)
		var h := o.y + (HANG_Y - o.y) * pow(anstieg, 0.85)
		# Rauschen erst hinter dem Anfang (die Krone bleibt bündig)
		var rausch := smoothstep(anfang + 1.0, anfang + 10.0, o.x)
		h += rausch * (1.6 * rausch_grob.get_noise_2d(x + 300.0, z)
				+ 0.5 * rausch_fein.get_noise_2d(x, z + 200.0))
		# Der Hügel hinter dem Wasserfallpfeiler
		var dh := Vector2(x, z).distance_to(pfeilerhuegel) / PFEILERHUEGEL.z
		h += PFEILERHUEGEL.w * exp(-dh * dh)
		# Der Kamm des Westhangs: ein Grat mit Buckeln, dahinter fällt es zum
		# Feldrand ab – von Osten ist er die Kimm, nicht die Schnittkante.
		var kamm_x := WESTKAMM_X + 9.0 * rausch_kamm.get_noise_2d(z * 0.8, 51.0)
		var dk := (x - kamm_x) / 11.0
		h += (4.0 + 4.0 * rausch_kamm.get_noise_2d(z * 1.7, 7.0)) * exp(-dk * dk)
		h -= 0.4 * maxf(kamm_x - x, 0.0)
		return h

	# ------------------------------------------------------------ Weltenbaum

	## Knoll (Süd, West), Wurzelgruben (Nord, Ost), dazwischen weich.
	func _baumzone(x: float, z: float, h: float) -> float:
		var d := Vector2(x, z) - ACHSE
		var r := d.length()
		if r > 70.0:
			return h
		var winkel := rad_to_deg(atan2(-d.y, d.x))   # 0 Ost, 90 Nord
		# Gruben: von Osten (knapp nördlich der Wiese) bis Nordwesten, wie
		# `L01Weltenbaum.boden_unter_wendel` unter der Wendel
		var g := smoothstep(-6.0, 16.0, winkel) * (1.0 - smoothstep(112.0, 148.0, winkel))
		# Knoll: am Stamm 8,4, nach außen fallend, ab r 28 ins Tal; wo das
		# Land dahinter höher ist (Abbruch im Westen), gewinnt das Land.
		var knoll := 8.4 - 0.13 * maxf(r - 12.0, 0.0) + 0.4 * rausch_fein.get_noise_2d(x, z)
		var k_ziel := lerpf(knoll, h, smoothstep(28.0, 50.0, r))
		k_ziel = maxf(k_ziel, lerpf(knoll, h, smoothstep(22.0, 36.0, r)))
		# Grube: am Stamm ein Wurzelwulst (die Innenwand der Wendel steckt
		# darin), Boden −2 bis r 42, dann die Außenwand hinauf ins Tal.
		var boden := -2.0 + 0.6 * rausch_fein.get_noise_2d(x * 1.3, z * 1.3)
		var wulst := 4.6 * (1.0 - smoothstep(15.2, 18.6, r)) + maxf(15.2 - r, 0.0) * 0.9
		var grube := lerpf(boden + wulst, h, smoothstep(42.0, 60.0, r))
		return lerpf(k_ziel, grube, g)

	# ------------------------------------------------------------ Weg

	## Nähte zum Weg nach dem Randtyp (siehe Kopf). Mischt die Profile der
	## beiden Nachbarstellen, damit Typwechsel nicht als Stufe stehen – nur
	## an den Enden einer Decke bleibt die Kante scharf.
	func _weg(x: float, z: float, sq: Vector2, h: float, o: Vector4) -> float:
		var s := sq.x
		if s < S_MIN + 1.0 or s > S_MAX - 1.0:
			return h
		var seite := 0 if sq.y < 0.0 else 1
		var u := absf(sq.y)
		var f := clampf((s - S_MIN) / S_SCHRITT, 0.0, float(anzahl - 1))
		var i := mini(floori(f), anzahl - 2)
		var t := f - float(i)
		# Neben einer FLACH-Decke weicht die Naht dem Bach (Furt): Sonst
		# füllte sie sein Ufer bis auf Deckenhöhe auf.
		var nb := _bach_naechst(laeufe[0], x, z)
		var bach := 1.0 - smoothstep(nb.w * 0.5, nb.w * 0.5 + 3.0, nb.x)
		var a := _profil(i, seite, u, s, h, bach)
		var b := _profil(i + 1, seite, u, s, h, bach)
		if (breite[i] <= 0.0) != (breite[i + 1] <= 0.0):
			# Genau an der Deckenkante wechseln, nicht auf halbem Weg zur
			# nächsten Stelle: Sonst stünde das Feld bis zu 0,25 m in Deckenhöhe
			# in der Lücke, vor den Stirnflächen und Ufern des Saums.
			var ab := a if (breite[i] <= 0.0) == in_luecke(s) else b
			return lerpf(h, ab.x, ab.y)
		var gewicht := lerpf(a.y, b.y, t)
		# Um die Ecke der Hochfläche hält die Naht den Rasen nur bis zur
		# Oberkante: Dahinter bricht das Land hinter der Wand des Saums ab.
		if seite == 1 and s < ECKE.y + 0.3 and u > wegrand[i] + 0.1:
			gewicht *= smoothstep(-o.w, o.w, o.x)
		if gewicht <= 0.0:
			return h
		var ziel := (a.x * a.y * (1.0 - t) + b.x * b.y * t) / maxf(a.y * (1.0 - t) + b.y * t, 1e-5)
		return lerpf(h, ziel, gewicht)

	## Profil an der Stelle i: Vector2(Zielhöhe, Gewicht).
	func _profil(i: int, seite: int, u: float, s: float, h: float, bach: float) -> Vector2:
		var ty := typ[seite][i]
		var kante := deck[i]
		var rand := wegrand[i]
		var auf_decke := breite[i] > 0.0
		if ty == KEIN or ty == WURZEL:
			return Vector2(h, 0.0)
		if seite == 0 and saum_da[i] == 1:
			return _profil_saum_links(i, ty, u, s, h, kante, rand, auf_decke)
		# Unter der Decke. UFER dort nur auf der Grenzstelle einer Furt-Decke
		# (183,0 gehört zu beidem): Sie endet sichtbar, also bündig wie FLACH.
		if auf_decke and u < rand - 0.05:
			if ty == FLACH or ty == UFER:
				return Vector2(kante - UNTER_DECKE, 1.0)
			return Vector2(kante - UNTER_WEG, 1.0)
		if not auf_decke:
			# In einer Lücke: Erdspalt (FLACH) und Furt (UFER) regeln Riss und
			# Bach, sonst tief und dunkel unter der Todeszone.
			if ty == UFER:
				# Die Ufer der Furt zeichnet der Saum (|q| ≤ 8, unter der
				# Wasserlinie taucht er unter das Bett): Bis dorthin bleibt
				# das Feld unter seiner Böschung.
				if s > furt.x and s < furt.y and u < 9.2:
					var d := minf(s - furt.x, furt.y - s)
					var k_ufer := deck[_index(furt.x - 0.25)] if s - furt.x < furt.y - s \
							else deck[_index(furt.y + 0.25)]
					var ufer := _furt_ufer(d, k_ufer)
					var w := (1.0 - smoothstep(8.0, 9.2, u)) * (1.0 - smoothstep(1.3, 1.8, d))
					return Vector2(minf(h, ufer), w)
				return Vector2(h, 0.0)
			if u < rand + 0.5 and ty != FLACH:
				return Vector2(minf(h, _lueckenboden(s)), 1.0)
		match ty:
			FLACH:
				var w := 1.0 - smoothstep(rand + 1.5, rand + 7.0, u)
				w *= 1.0 - bach * smoothstep(rand - 0.05, rand + 0.4, u)
				return Vector2(kante - UNTER_DECKE, w)
			BOESCHUNG:
				var a := abstand[seite][i]
				var k := krone_q[seite][i]
				if is_nan(k):
					k = a + 6.0
				var kr := krone[seite][i]
				var y := 0.0
				if u <= k:
					y = lerpf(kante - 1.5, kr - 0.6, clampf((u - a) / maxf(k - a, 0.1), 0.0, 1.0))
				else:
					y = lerpf(kr - 0.6, kr, clampf((u - k) / 2.5, 0.0, 1.0))
				return Vector2(y, 1.0 - smoothstep(k + 2.5, k + 9.0, u))
			FELS_AUF:
				var a := abstand[seite][i]
				var kr := krone[seite][i]
				# Am Wasserfallpfeiler (s 112–122) steht das Land dahinter so
				# hoch wie der Pfeiler: Von dort kommt der Oberlauf.
				var pfeiler := smoothstep(108.0, 112.5, s) * (1.0 - smoothstep(121.5, 126.0, s))
				kr = lerpf(kr, maxf(kr, kante + 10.8), pfeiler)
				var y := 0.0
				if u < a + 1.5:
					y = kante - 2.0
				elif u < a + 2.5:
					y = lerpf(kante - 2.0, kr - 0.5, smoothstep(a + 1.5, a + 2.5, u))
				else:
					y = lerpf(kr - 0.5, kr, clampf((u - a - 2.5) / 2.0, 0.0, 1.0))
				# Wo die Wand endet (C4 bei 160), übergibt die Krone früh an
				# den Grat dahinter, der weich nach Norden fällt – sonst stünde
				# dort ein Block mit ebener Stirn.
				var weit := lerpf(10.0, 3.5, smoothstep(150.0, 159.5, s))
				return Vector2(y, 1.0 - smoothstep(a + minf(4.5, weit - 1.0), a + weit, u))
			FELS_AB:
				var a := abstand[seite][i]
				var d := u - a
				var fu := fuss[seite][i]
				var fuss_n := maxf((kante - 3.0 - fu) / 4.7, 0.0)
				var wand := kante - 3.0 if d < -1.5 else kante - 3.0 - 4.7 * (d + 1.5)
				var schutt := fu + 1.2 - 0.3 * maxf(d - fuss_n, 0.0)
				var y := maxf(wand, schutt)
				# Hinter dem Fuß das Tal, wo es höher ist als der Schutt (Tümpel-
				# und Kanalufer liegen dort über dem Wasser)
				y = maxf(y, lerpf(y, h, smoothstep(fuss_n - 1.0, fuss_n + 1.0, d)))
				return Vector2(y, 1.0 - smoothstep(fuss_n + 4.0, fuss_n + 16.0, d))
			UFER:
				var a := abstand[seite][i]
				var fu := fuss[seite][i]
				var y := lerpf(kante - 2.0, fu - 0.8, smoothstep(a, a + 2.5, u))
				return Vector2(y, 1.0 - smoothstep(a + 2.5, a + 6.0, u))
		return Vector2(h, 0.0)

	## Links, wo der Saum baut (Böschung, Felsnase, Felswand, Becken): Das
	## Feld bleibt `SAUM_UNTER` unter seinen Flächen – unter der Böschung
	## und der Krone, hinter der Wand tief, im Becken unter dessen Grund –,
	## darf hinter der Kronenkante (ab 2,5–4,5 m) als Land heraustreten und
	## deckt das Ende der Krone um `SAUM_DECKT` zu. Dahinter das Land.
	func _profil_saum_links(i: int, ty: int, u: float, s: float, h: float, kante: float,
			rand: float, auf_decke: bool) -> Vector2:
		if auf_decke and u < rand - 0.05:
			return Vector2(kante - (UNTER_DECKE if ty == FLACH else UNTER_WEG), 1.0)
		if not auf_decke and u < rand + 0.5:
			return Vector2(minf(h, _lueckenboden(s)), 1.0)
		var reihe := saum_reihen[i]
		var k := saum_kante_q[i]
		var e := saum_ende_q[i]
		var wand := saum_wand_q[i]
		var y := 0.0
		if ty == FELS_AUF:
			# Hinter der Wand tief (im Becken unter dessen Grund), erst hinter
			# ihrer äußersten Stelle hinauf unter die Krone
			var tief := minf(kante - 2.0, saum_fuss_y[i] - 0.6)
			if u < wand + 0.4:
				return Vector2(tief, 1.0)
			y = _saum_krone(i, u, h, maxf(k, wand), e)
			y = lerpf(tief, y, smoothstep(wand + 0.4, wand + 0.9, u))
			return Vector2(y, 1.0 - smoothstep(e + 1.0, e + 8.0, u))
		# Böschung (auch ihr Anfang aus dem Waldboden vor s 33): unter dem
		# Hang 1,5 m unter der Linie Fuß → Kronenkante (wie vorher) und nie
		# weniger als `SAUM_UNTER` unter der Fläche (Rinne der Kerbe)
		var a := reihe[2].x
		if u <= k:
			if ty == FLACH and u < rand + 1.5:
				y = kante - UNTER_DECKE
			else:
				y = lerpf(kante - 1.5, reihe[SAUM_KRONE].y - 0.6,
						clampf((u - a) / maxf(k - a, 0.1), 0.0, 1.0))
			y = minf(y, _saum_hoehe(i, u, 0) - SAUM_UNTER)
			return Vector2(y, 1.0)
		y = _saum_krone(i, u, h, k, e)
		return Vector2(y, 1.0 - smoothstep(e + 1.0, e + 8.0, u))

	## Unter dem Ufer der Furt, das der Saum baut (`L01Saum._profil_furt`),
	## `d` Meter von der Deckenkante, `k` deren Höhe: 0,25 m darunter.
	static func _furt_ufer(d: float, k: float) -> float:
		var stellen := [Vector2(0.0, k - 0.6), Vector2(0.4, k - 0.97), Vector2(0.8, 6.05),
				Vector2(1.2, 5.77), Vector2(1.6, 5.25), Vector2(2.2, 4.5)]
		for j in stellen.size() - 1:
			var a: Vector2 = stellen[j]
			var b: Vector2 = stellen[j + 1]
			if d <= b.x:
				return lerpf(a.y, b.y, clampf((d - a.x) / (b.x - a.x), 0.0, 1.0))
		return 4.5

	## Das Feld an der Krone links (ab `von`): `SAUM_UNTER` unter ihr, ab
	## 2,5–4,5 m hinter `von` darf das Land darüber treten, und am Ende der
	## Krone liegt es `SAUM_DECKT` über ihr.
	func _saum_krone(i: int, u: float, h: float, von: float, ende: float) -> float:
		var unter := _saum_hoehe(i, u, SAUM_KRONE) - SAUM_UNTER
		var frei := smoothstep(von + 2.5, von + 4.5, u)
		var y := lerpf(unter, maxf(h, unter), frei)
		return maxf(y, unter + (SAUM_UNTER + SAUM_DECKT) * smoothstep(ende - 1.5, ende, u))

	## Boden unter einer Lücke (nicht Erdspalt/Furt): unter der Todeszone.
	func _lueckenboden(s: float) -> float:
		if s < 80.0:
			return 15.0    # Kerbe, K-Kerbe 18,5
		return 12.5        # Fallkerbe, K-Fallkerbe 14

	# ------------------------------------------------------------ Bach

	## Gräbt die Bäche: `haupt` = der Hauptbach (vor den Nähten), sonst
	## Oberlauf und Rinne (danach, sie schneiden in Krone und Böschung).
	func _baeche(x: float, z: float, h: float, haupt: bool) -> float:
		for lauf in laeufe:
			if (String(lauf["name"]) == "bach") != haupt:
				continue
			var n := _bach_naechst(lauf, x, z)
			var d := n.x
			var b := n.w
			if d > b * 0.5 + 6.0:
				continue
			var bett := n.y + 0.25 * rausch_fein.get_noise_2d(x * 2.0, z * 2.0)
			var wasser := n.z
			var rinne := bett + (wasser + 0.3 - bett) * smoothstep(b * 0.26, b * 0.5, d)
			var t := smoothstep(b * 0.5, b * 0.5 + (5.0 if haupt else 2.5), d)
			if haupt:
				h = lerpf(minf(rinne, maxf(h, wasser + 0.3)), h, t)
			else:
				# Oberlauf und Rinne: nur hinab schneiden, kein Damm
				h = minf(h, lerpf(rinne, h, t))
		return h

	# ------------------------------------------------------------ Sonderzonen

	## Erdspalt, Wurzelwiese und Wiesenboden unter G1.
	func _sonderzonen(sq: Vector2, h: float) -> float:
		var s := sq.x
		var q := sq.y
		var u := absf(q)
		# Erdspalt: voll zwischen den Decken, dann 5,5 m keilförmig in den
		# Waldboden (Plan 5A), dunkel und tief (Boden 16, K-Spalt 20), hinter
		# den Wänden, die der Saum dort baut.
		var hinter := _spalt_hinter(s, q)
		if hinter < SPALT_LIPPE and u < 10.5:
			# Boden 0,6 m unter dem Grund, den der Saum dort zeichnet
			var eng := pow(smoothstep(5.2, 10.6, u), 0.8)
			var kante := deck[_index(erdspalt.x - 0.25)]
			var tiefe := lerpf(16.0, kante - 3.1, smoothstep(0.55, 1.0, eng))
			tiefe = lerpf(tiefe, kante - 0.6, smoothstep(9.9, 10.4, u))
			var boden := lerpf(tiefe, h, smoothstep(SPALT_WAND, SPALT_LIPPE, hinter))
			h = minf(h, boden)
		# Wurzelwiese (s 196–214, q 3,9–12,4) und Wiesenboden unter G1
		# (s 210–214, q −4,2…4): flach auf 7,0, wie die Kollision.
		if s > 193.0 and s < 217.0:
			var in_s := smoothstep(193.0, 196.0, s) * (1.0 - smoothstep(214.0, 216.5, s))
			var lo := -4.6 if s > 209.5 else 3.0
			var in_q := smoothstep(lo - 1.2, lo, q) * (1.0 - smoothstep(12.9, 14.6, q))
			var w := in_s * in_q
			if w > 0.0:
				h = lerpf(h, WIESE_Y, w)
		return h

	## Wie weit (s, q) hinter der nächsten Lippe des Erdspalts liegt, die der
	## Saum baut (`L01Saum.erdspalt_linie`, samt Zacken; negativ = zwischen
	## den Lippen, über dem Riss). Die Wände des Feldes stehen `SPALT_WAND`
	## dahinter, hinter den Wänden des Saums (0,4–0,5 m, Rauschen bis 0,3 m
	## weiter), der Waldboden beginnt `SPALT_LIPPE` dahinter, unter dessen
	## Narbe (1,15 m). Vor dem Ende der Wände (10,6 m) läuft der Riss flach
	## zu, in ihrer Höhlung: Dahinter ist kein Saum mehr, der ihn deckte.
	func _spalt_hinter(s: float, q: float) -> float:
		var u := absf(q)
		var zu := 1.6 * smoothstep(9.9, 10.4, u)
		return maxf(L01Saum.erdspalt_linie(q, 0) - s, s - L01Saum.erdspalt_linie(q, 1)) + zu

	# ------------------------------------------------------------ Dichte

	func punktabstand(x: float, z: float) -> float:
		var sq := projektion(x, z)
		var s := sq.x
		var u := absf(sq.y)
		var i := _index(s)
		var d := u
		if s < -8.0:
			d = u + (-8.0 - s)
		elif s > ende_s:
			d = u + (s - ende_s)
		var r := Vector2(x, z).distance_to(ACHSE)
		d = minf(d, maxf(r - 30.0, 0.0))
		# unter einer Decke genügt es grob
		if breite[i] > 0.0 and u < wegrand[i] - 1.0:
			return 3.0
		if d < 16.0:
			return ABSTAND_NAH
		if d < 40.0:
			return ABSTAND_MITTE
		if d < 90.0:
			return ABSTAND_WEIT
		return ABSTAND_FERN

	# ------------------------------------------------------------ Kanten

	## Linien, an denen das Feld knicken soll.
	func kanten() -> Array:
		var liste: Array = []
		# FLACH-Kanten in A und D: eine Reihe knapp außerhalb des Wegrands
		for bereich_s: Vector2 in [Vector2(-10.0, erdspalt.x - 0.4),
				Vector2(erdspalt.y + 0.4, 33.0), Vector2(160.3, 172.8), Vector2(183.2, 196.0)]:
			for seite: float in [-1.0, 1.0]:
				var p := PackedVector2Array()
				var s := bereich_s.x
				while s <= bereich_s.y + 0.001:
					p.append(_weg_welt(s, seite * (wegrand[_index(s)] + 0.12)))
					s += 1.0
				liste.append({"punkte": p, "abstand": 1.2, "reihen": PackedFloat32Array([0.0])})
		# Deckenenden an Erdspalt und Furt: eine Reihe auf der Decke, eine
		# in der Lücke
		for ende: Vector2 in [Vector2(erdspalt.x, -1.0), Vector2(erdspalt.y, 1.0),
				Vector2(173.0, -1.0), Vector2(183.0, 1.0)]:
			var r := wegrand[_index(ende.x)] + 0.6
			for versatz: float in [-0.08, 0.3]:
				var s := ende.x + ende.y * versatz
				liste.append({"punkte": PackedVector2Array([_weg_welt(s, -r), _weg_welt(s, r)]),
						"abstand": 0.7, "reihen": PackedFloat32Array([0.0])})
		# Keile des Erdspalts im Waldboden: Lippe und Riss
		for seite: float in [-1.0, 1.0]:
			for ende in 2:
				var richtung := -1.0 if ende == 0 else 1.0
				var lippe := PackedVector2Array()
				var riss := PackedVector2Array()
				var boden := PackedVector2Array()
				for k in 29:
					var q := seite * (4.8 + 5.6 * float(k) / 28.0)
					var zu := 1.6 * smoothstep(9.9, 10.4, absf(q))
					var s := L01Saum.erdspalt_linie(q, ende)
					lippe.append(_weg_welt(s + richtung * (SPALT_LIPPE - zu), q))
					riss.append(_weg_welt(s + richtung * (SPALT_WAND - zu), q))
					boden.append(_weg_welt(s + richtung * (SPALT_LIPPE + 0.25 - zu), q))
				liste.append({"punkte": boden, "abstand": 0.45, "reihen": PackedFloat32Array([0.0])})
				liste.append({"punkte": lippe, "abstand": 0.45, "reihen": PackedFloat32Array([0.0])})
				liste.append({"punkte": riss, "abstand": 0.45, "reihen": PackedFloat32Array([0.0])})
		# Ostkante des Hallenwaldbodens: Oberkante und Fuß; um die Ecke der
		# Hochfläche steil (hinter der Wand des Saums), davor weich
		var halle := PackedVector2Array()
		var ecke := PackedVector2Array()
		for k in hallenkante.size():
			var sq := hallenkante[k]
			if sq.x >= ECKE.x - 1.5:
				ecke.append(_weg_welt(sq.x, sq.y))
			elif sq.x > -10.0:
				halle.append(_weg_welt(sq.x, sq.y))
		if not ecke.is_empty():
			halle.append(ecke[0])
		liste.append({"punkte": halle, "abstand": 1.0,
				"reihen": PackedFloat32Array([-1.7, -1.2, 1.6])})
		liste.append({"punkte": ecke, "abstand": 0.7,
				"reihen": PackedFloat32Array([-0.6, -0.38, 0.38, 0.6])})
		# Links das Ende der Krone, die der Saum baut: Dort steigt das Feld
		# knapp über sie (ein schmaler Wulst, zu schmal für das Raster)
		var kronenende := PackedVector2Array()
		var sk := S_MIN
		while sk <= SAUM_LINKS_BIS:
			var i := _index(sk)
			if saum_da[i] == 1:
				kronenende.append(_weg_welt(sk, -saum_ende_q[i]))
			sk += 1.0
		if kronenende.size() > 1:
			liste.append({"punkte": kronenende, "abstand": 1.0,
					"reihen": PackedFloat32Array([-0.8, 0.0, 1.0])})
		# Die Rinne der Kerbe, die der Saum links die Böschung hinaufführt: ein
		# schmales V, das das Raster sonst überdeckte
		for s: float in [56.2, 56.8, 57.5, 58.2, 58.8]:
			liste.append({"punkte": PackedVector2Array([_weg_welt(s, -4.8), _weg_welt(s, -14.0)]),
					"abstand": 0.6, "reihen": PackedFloat32Array([0.0])})
		# Die Ufer der Furt, die der Saum baut: Reihen quer, damit das Feld
		# dort unter ihm bleibt
		for ende: Vector2 in [Vector2(furt.x, 1.0), Vector2(furt.y, -1.0)]:
			for d: float in [0.12, 0.45, 0.85, 1.25, 1.65]:
				var s := ende.x + ende.y * d
				liste.append({"punkte": PackedVector2Array([_weg_welt(s, -9.5), _weg_welt(s, 9.5)]),
						"abstand": 0.8, "reihen": PackedFloat32Array([0.0])})
		# Wasserlinien der Bäche, je Abschnitt (die Breite ändert sich)
		for lauf in laeufe:
			var p: PackedVector2Array = lauf["p"]
			var br: PackedFloat32Array = lauf["breite"]
			for k in p.size() - 1:
				var b := (br[k] + br[k + 1]) * 0.5
				liste.append({"punkte": PackedVector2Array([p[k], p[k + 1]]),
						"abstand": 2.0 if b > 3.0 else 1.1,
						"reihen": PackedFloat32Array([-b * 0.5, -b * 0.36, b * 0.36, b * 0.5])})
		return liste

	# ------------------------------------------------------------ Felsen

	## Felsen auf den Kämmen der Randhügel und des Westhangs, ohne
	## Kollision: an den höchsten Stellen des Kamms, zu zweit oder dritt.
	func felsen() -> Array:
		var liste: Array = []
		var rng := RandomNumberGenerator.new()
		rng.seed = 4199
		var formen: Array[ArrayMesh] = []
		for k in 6:
			formen.append(GelaendeFeld.felsbrocken(Vector3.ONE, 4200 + k))
		var orte: Array[Vector2] = []
		# Randhügel: entlang des Kamms (rund ≈ 1,04), wo er hoch ist
		var n := 90
		for k in n:
			var w := TAU * float(k) / float(n)
			var c := cos(w)
			var sn := sin(w)
			var norm := pow(pow(absf(c), 3.0) + pow(absf(sn), 3.0), 1.0 / 3.0)
			var p := TAL_MITTE + Vector2(c * TAL_RADIEN.x, sn * TAL_RADIEN.y) * (1.04 / norm)
			if not FELD.grow(-6.0).has_point(p) or p.x < 30.0:
				continue
			if rausch_kamm.get_noise_2d(p.x, p.y) < 0.1:
				continue
			orte.append(p)
		# Westhang: auf dem Grat
		var zz := 30.0
		while zz > -310.0:
			var kx := WESTKAMM_X + 9.0 * rausch_kamm.get_noise_2d(zz * 0.8, 51.0)
			if rausch_kamm.get_noise_2d(zz * 1.7, 7.0) > 0.05:
				orte.append(Vector2(kx, zz))
			zz -= 14.0
		for ort in orte:
			var anzahl := 1 + rng.randi() % 3
			for k in anzahl:
				var p := ort + Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-7.0, 7.0))
				var breit := rng.randf_range(4.0, 9.0)
				var g := Vector3(breit, rng.randf_range(4.0, 10.0), breit * rng.randf_range(0.6, 1.0))
				var y := hoehe(p.x, p.y)
				var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled_local(g)
				liste.append({"netz": formen[rng.randi() % formen.size()],
						"lage": Transform3D(basis, Vector3(p.x, y, p.y)),
						"farbe": Color(0.0, 0.0, 1.0, 0.0), "zusatz": Vector2(1.0, 0.0)})
		return liste

	# ------------------------------------------------------------ Wald

	func wald(x: float, z: float) -> float:
		return _wald(x, z, projektion(x, z), _ober(x, z), L01Gelaende.hoehe(x, z))

	func _wald(x: float, z: float, sq: Vector2, o: Vector4, y: float) -> float:
		var s := sq.x
		var u := absf(sq.y)
		var n := rausch_wald.get_noise_2d(x, z)
		# Oberland: Wald mit wenigen Lichtungen
		var w_ober := smoothstep(-0.55, -0.3, n) * 0.95
		# Tal: Flecken, nahe dem Grat dichter, auf Kuppen, Riegeln und den
		# Randhängen mehr Wald, in den Senken Wiese
		var hoch := smoothstep(TAL_Y + 0.5, TAL_Y + 5.0, y) - 0.5
		var w_tal := smoothstep(-0.12, 0.18, n + 0.3 * hoch
				+ 0.18 * (1.0 - smoothstep(20.0, 60.0, absf(o.x))))
		# Die Randhänge bewaldet, die Kämme selbst licht (Fels und Gras)
		w_tal = maxf(w_tal, smoothstep(9.0, 18.0, y) * (0.55 + 0.45 * smoothstep(-0.3, 0.2, n)))
		w_tal *= 1.0 - 0.6 * smoothstep(31.0, 41.0, y)
		var w := lerpf(w_tal, w_ober, smoothstep(-2.0, 4.0, o.x))
		var i := _index(s)
		if s > -12.0 and s < ende_s:
			var seite := 0 if sq.y < 0.0 else 1
			var rand := wegrand[i]
			# Nahe am Weg in A und D: Rasen bis 1–5 m hinter der Kante
			if typ[seite][i] == FLACH:
				w *= smoothstep(rand + 1.0, rand + 5.0, u)
			# Hallenwald um A: dicht
			if s < 26.0 + (8.0 if seite == 0 else 0.0):
				w = maxf(w, smoothstep(rand + 1.5, rand + 4.5, u) * (1.0 - smoothstep(30.0, 40.0, u)))
			# Bachwiese D und Wurzelwiese: offen
			if s > 158.0 and s < 216.0 and u < 16.0:
				w *= smoothstep(10.0, 16.0, u) * 0.6
		# Um den Weltenbaum keine Bäume (Knoll, Gruben)
		w *= smoothstep(40.0, 56.0, Vector2(x, z).distance_to(ACHSE))
		# Am Bach offen
		for lauf in laeufe:
			var nb := _bach_naechst(lauf, x, z)
			w *= smoothstep(nb.w * 0.5 + 1.0, nb.w * 0.5 + 6.0, nb.x)
		return clampf(w, 0.0, 1.0)

	## Projektion und Walddichte eines Punkts für farbe()/zusatz(): aus der
	## Ablage von `hoehe()`, sonst neu gerechnet.
	func _merken(p: Vector3) -> void:
		if p == _letzter:
			return
		_letzter = p
		var schluessel := Vector2(p.x, p.z)
		var o := Vector4.ZERO
		if _ablage.has(schluessel):
			var a: Array = _ablage[schluessel]
			_letzt_sq = a[0]
			o = a[1]
		else:
			_letzt_sq = projektion(p.x, p.z)
			o = _ober(p.x, p.z)
		_letzt_wald = _wald(p.x, p.z, _letzt_sq, o, p.y)

	## Die Ablage wird nach dem Bau nicht mehr gebraucht.
	func ablage_leeren() -> void:
		_ablage.clear()
		sammeln = false

	# ------------------------------------------------------------ Farbe

	## Stoffgewichte: R Wiese, G Waldboden, B Fels, A Schlamm.
	func farbe(p: Vector3, n: Vector3) -> Color:
		_merken(p)
		var w := _letzt_wald
		var fels := smoothstep(0.8, 0.62, n.y)
		# Die Lippe des Erdspalts liegt oben auf dem Waldboden: Ihre Normale
		# neigt sich zur Wand darunter (unter der Narbe des Saums), ihre Farbe
		# bliebe sonst als Felsband neben der Narbe stehen.
		if p.y > 25.7 and absf(_letzt_sq.x - 26.25) < 3.5 and absf(_letzt_sq.y) < 11.5:
			fels = 0.0
		# Gruben: Wurzelerde, dunkel und nass, am Rand Waldboden statt Rasen
		var schlamm := 0.0
		var grube := _grubenanteil(p)
		if grube > 0.0:
			schlamm = smoothstep(3.0, -0.5, p.y) * 0.8 * grube
			w = maxf(w, grube * 0.85)
		for lauf in laeufe:
			var nb := _bach_naechst(lauf, p.x, p.z)
			if nb.x < nb.w * 0.5 + 2.0:
				schlamm = maxf(schlamm, 1.0 - smoothstep(nb.w * 0.5 - 0.2, nb.w * 0.5 + 0.9, nb.x))
		var rest := 1.0 - fels
		var sch := rest * schlamm
		rest -= sch
		return Color(rest * (1.0 - w), rest * w, fels, sch)

	## UV1: (Tönung −1 kühl-feucht … +1 warm-trocken, frei). Flecken über
	## 60 m, Südhänge wärmer, Senken und Bachufer kühler – von weitem liest
	## sich die Wiese so nicht als eine Farbe. Am Rand der FLACH-Decken 0:
	## Dort muss der Rasen genau dem der Wegdecke gleichen.
	func toenung(p: Vector3, n: Vector3) -> Vector2:
		_merken(p)
		var ton := 0.55 * rausch_grob.get_noise_2d(p.x * 0.8 + 500.0, p.z * 0.8)
		# Südhang (Normale nach +z) trockener, Nordhang frischer
		ton += 0.9 * n.z * (1.0 - n.y) * 2.0
		ton -= 0.5 * smoothstep(TAL_Y + 1.0, TAL_Y - 1.5, p.y)
		for lauf in laeufe:
			var nb := _bach_naechst(lauf, p.x, p.z)
			ton -= 0.6 * (1.0 - smoothstep(nb.w * 0.5, nb.w * 0.5 + 8.0, nb.x))
		var s := _letzt_sq.x
		var u := absf(_letzt_sq.y)
		if s > -12.0 and s < ende_s:
			var i := _index(s)
			var seite := 0 if _letzt_sq.y < 0.0 else 1
			if typ[seite][i] == FLACH:
				ton *= smoothstep(wegrand[i] + 2.0, wegrand[i] + 9.0, u)
		return Vector2(clampf(ton, -1.0, 1.0), 0.0)

	## Wie sehr ein Punkt zu den Wurzelgruben gehört (0..1): Winkel wie in
	## `_baumzone`, bis zum oberen Rand der Außenwand.
	func _grubenanteil(p: Vector3) -> float:
		var d := Vector2(p.x, p.z) - ACHSE
		var r := d.length()
		if r > 62.0:
			return 0.0
		var winkel := rad_to_deg(atan2(-d.y, d.x))
		var g := smoothstep(-6.0, 16.0, winkel) * (1.0 - smoothstep(112.0, 148.0, winkel))
		return g * (1.0 - smoothstep(46.0, 60.0, r))

	## UV2: (Verdeckung, Stärke des Kronenlichts).
	func zusatz(p: Vector3, _n: Vector3, mulde: float) -> Vector2:
		_merken(p)
		var s := _letzt_sq.x
		var u := absf(_letzt_sq.y)
		var w := _letzt_wald
		# Walddach dunkel, Lichtungen fern vom Weg etwas heller: Von oben muss
		# sich das Tal in Flächen lesen, auch durch den Dunst.
		var ao := lerpf(1.0, 0.5, w)
		ao *= 1.0 + 0.12 * (1.0 - w) * smoothstep(12.0, 30.0, u)
		var licht := w * 0.8
		# Kronenschatten des Weltenbaums (die Krone wirft keinen echten):
		# Mitte 16 m nördlich der Achse, wie die Sonne ihn legte.
		var schatten := Vector2(p.x, p.z).distance_to(ACHSE + Vector2(-4.0, -15.5))
		ao *= lerpf(0.55, 1.0, smoothstep(26.0, 44.0, schatten))
		# Gruben: dunkel, je tiefer, desto mehr (der Blick von der Wendel
		# hinab soll in Dunkel fallen, nicht auf eine Wiese)
		var grube := _grubenanteil(p)
		if grube > 0.0:
			ao *= lerpf(1.0, 0.62, grube)
			ao *= lerpf(1.0, 0.55, smoothstep(5.0, -1.5, p.y) * grube)
		# Mulden, Risse
		ao *= 1.0 - 0.45 * smoothstep(0.1, 1.6, mulde)
		# Erdspalt fast schwarz
		if s > 20.0 and s < 32.0 and u < 11.5:
			ao *= lerpf(1.0, 0.18, smoothstep(25.9, 23.5, p.y))
		# Am Wegrand in A und D: wie der Rand der Decke ab 0,78
		var i := _index(s)
		if s > -12.0 and s < ende_s:
			var seite := 0 if _letzt_sq.y < 0.0 else 1
			if typ[seite][i] == FLACH and breite[i] > 0.0:
				var rand := wegrand[i]
				ao = minf(ao, lerpf(1.0, Wegmaske.RAND_VERDECKUNG, 1.0 - smoothstep(rand, rand + 2.5, u)))
				licht = lerpf(licht, kronenlicht[i], 1.0 - smoothstep(rand + 0.5, rand + 3.0, u))
		return Vector2(clampf(ao, 0.0, 1.0), clampf(licht, 0.0, 1.0))
