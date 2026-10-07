extends MeshInstance3D
class_name Wasserfall
## Ein Wasserfall, der über die Kante einer Schluchtwand stürzt.
##
## Ein Band aus Vierecken, das der Wand folgt wie eine hängende Ranke:
## Springt der Fels vor, fällt das Wasser über ihn, springt er zurück,
## stürzt es frei davor (dieselbe Regel wie in `Schluchtsaum`). Das Fließen
## macht der Shader: zwei Streifenmuster aus Rauschen, verschieden schnell
## und verschieden fein, laufen nach unten und mischen tiefes Blaugrün mit
## Gischtweiß; zu den Rändern und Enden wird das Band durchsichtig.
##
## Unbeleuchtet, weil fallendes Wasser selbst hell ist – im Schatten der
## Schlucht wäre ein beleuchtetes Band ein graues Tuch. Kein Bildschirm-
## und kein Tiefenpuffer, also auch im Web und auf dem Handy dasselbe.
##
## Gedeckt und nie ganz deckend: Unbeleuchtet leuchtet das Band gegen die
## schattige Wand – in reinem Gischtweiß und Türkis war es das Grellste in
## der ganzen Schlucht und zog den Blick von Weg und Kisten ab. Die Ränder
## franst das Rauschen aus; ein Wasserfall hat keine Linealkanten.
##
## Keine Kollision: Es steht an der Wand, nie im Weg.
##
## Aufbau: `Wasserfall.an_schluchtwand(...)` legt den Knoten an und baut das
## Netz in Weltkoordinaten aus den Kronendaten der Schluchtwand.
## `Wasserfall.band(...)` baut dasselbe Band entlang einer freien Polylinie
## (Weltpunkte, in Fließrichtung): für Fälle, deren Bahn der Aufrufer selbst
## rechnet, für Schussrinnen und Rinnsale. Gleicher Shader, eigener Stoff je
## Band (die Länge steht im Stoff).

const FALL_SHADER := """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never,
		shadows_disabled;

uniform vec4 farbe_tief : source_color = vec4(0.18, 0.38, 0.42, 1.0);
uniform vec4 farbe_schaum : source_color = vec4(0.74, 0.84, 0.87, 1.0);
uniform float tempo = 5.5;
uniform float laenge = 20.0;
// Nur für `band()`: Aus der Ferne heller und dichter, damit ein Fall durch
// den Dunst trägt (0 = aus, dann rechnet der Shader genau wie zuvor).
uniform float ferne = 0.0;

float zufall(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rauschen(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(zufall(i), zufall(i + vec2(1.0, 0.0)), u.x),
			mix(zufall(i + vec2(0.0, 1.0)), zufall(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	// UV.x quer über das Band (0..1), UV.y Meter ab der Kante.
	float quer = UV.x;
	float m = UV.y;
	float grob = rauschen(vec2(quer * 7.0, m * 0.45 - TIME * tempo * 0.45));
	float fein = rauschen(vec2(quer * 19.0 + 3.1, m * 1.3 - TIME * tempo * 1.1));
	float schaum = smoothstep(0.38, 0.85, grob * 0.62 + fein * 0.48);
	// Unten und an der Kante oben mehr Gischt.
	schaum = max(schaum, smoothstep(0.7, 1.0, m / laenge) * 0.8);
	schaum = max(schaum, (1.0 - smoothstep(0.0, 1.2, m)) * 0.7);
	// Ausgefranste Ränder: Das grobe Rauschen verschiebt die Kante hin und
	// her, das feine löst sie in Strähnen auf – beides fließt mit.
	float rand = smoothstep(0.0, 0.25, quer + (grob - 0.5) * 0.3)
			* smoothstep(1.0, 0.75, quer - (fein - 0.5) * 0.3);
	float enden = smoothstep(0.0, 0.4, m) * (1.0 - smoothstep(laenge * 0.8, laenge, m));
	ALBEDO = mix(farbe_tief.rgb, farbe_schaum.rgb, schaum);
	ALPHA = rand * enden * mix(0.45, 0.85, schaum);
	if (ferne > 0.0) {
		float weit = smoothstep(20.0, 90.0, length(VERTEX));
		ALBEDO *= 1.0 + ferne * weit;
		ALPHA = min(ALPHA * (1.0 + 0.6 * ferne * weit), 1.0);
	}
}
"""

static var _shader: Shader = null


## Baut einen Wasserfall an einer Schluchtwand, die mit `kronen_merken`
## entstanden ist. `strecke` und `seite` wählen die Stelle; `breite` ist die
## Breite des Bandes entlang der Wand, `bis` die Höhe (relativ zum Weg), bis
## zu der es hinabreicht.
static func an_schluchtwand(eltern: Node3D, kurve: Curve3D, kronen: Array,
		strecke: float, seite: float, breite: float = 3.0,
		bis: float = -12.0) -> Wasserfall:
	# Die Säulen im Bereich des Bandes: Das Wasser muss vor JEDER davon
	# fallen, sonst stäche ein vorspringender Block durch den Vorhang.
	var saeulen: Array = []
	for eintrag in kronen:
		var e: Dictionary = eintrag
		if float(e["seite"]) == seite and absf(float(e["s"]) - strecke) < breite * 0.5 + 1.4:
			saeulen.append(e)
	if saeulen.is_empty():
		return null
	var oben := INF
	var start := INF
	for eintrag in saeulen:
		var e: Dictionary = eintrag
		oben = minf(oben, float(e["oben"]))
		start = minf(start, float(e["innen"]))

	# Weg des Wassers als (quer, y): über die Kante, dann hinab.
	var weg := PackedVector2Array()
	weg.append(Vector2(start + 0.9, oben + 0.05))
	var q := start - 0.15
	var y := oben - 0.1
	weg.append(Vector2(q, y))
	while y > bis:
		y = maxf(y - 0.5, bis)
		for eintrag in saeulen:
			q = minf(q, Schluchtsaum.wand_bei(eintrag as Dictionary, y) - 0.2)
		# Der Strahl löst sich mit der Höhe etwas von der Wand.
		weg.append(Vector2(q - (oben - y) * 0.015, y))

	var mitte := LevelWerkzeuge.punkt(kurve, strecke)
	var laengs := LevelWerkzeuge.richtung(kurve, strecke)
	var aussen := laengs.cross(Vector3.UP).normalized() * seite
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SPALTEN := 4
	var gelaufen := 0.0
	var vorher: Array[Vector3] = []
	var vorher_m := 0.0
	for i in weg.size():
		var p := weg[i]
		if i > 0:
			gelaufen += weg[i - 1].distance_to(p)
		var reihe: Array[Vector3] = []
		for k in SPALTEN + 1:
			var u := float(k) / float(SPALTEN)
			# Leicht nach außen gewölbt, und unten breiter als oben.
			var bauch := sin(u * PI) * 0.18
			var weite := breite * lerpf(0.85, 1.25, clampf((oben - p.y) / 20.0, 0.0, 1.0))
			reihe.append(mitte + aussen * (p.x - bauch) + Vector3.UP * p.y
					+ laengs * (u - 0.5) * weite)
		if not vorher.is_empty():
			for k in SPALTEN:
				var u0 := float(k) / float(SPALTEN)
				var u1 := float(k + 1) / float(SPALTEN)
				_ecke(st, vorher[k], Vector2(u0, vorher_m))
				_ecke(st, reihe[k], Vector2(u0, gelaufen))
				_ecke(st, reihe[k + 1], Vector2(u1, gelaufen))
				_ecke(st, vorher[k], Vector2(u0, vorher_m))
				_ecke(st, reihe[k + 1], Vector2(u1, gelaufen))
				_ecke(st, vorher[k + 1], Vector2(u1, vorher_m))
		vorher = reihe
		vorher_m = gelaufen

	var fall := Wasserfall.new()
	fall.name = "Wasserfall"
	st.index()
	fall.mesh = st.commit()
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FALL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("laenge", gelaufen)
	fall.material_override = mat
	eltern.add_child(fall)
	return fall


## Baut ein Band entlang der Polylinie `punkte` (Welt, in Fließrichtung).
## `breite` ist die Breite am Anfang. Die Bahn wird geglättet (Catmull-Rom
## durch alle Punkte) und alle `schritt` Meter abgetastet.
##
## Die Breite liegt waagerecht und quer zur waagerechten Fließrichtung –
## an einer Wand also längs der Wand, auf dem Boden quer zum Lauf. Wo das
## Wasser senkrecht fällt, gilt die letzte waagerechte Richtung davor. Der
## Querschnitt wölbt sich um `bauch` × Breite nach vorn (bei einem Fall vom
## Fels weg, bei einer Rinne nach oben): Ein flaches Band ist von der Seite
## gesehen nur ein Strich, ein gewölbtes behält Tiefe.
##
## optionen:
##   "breite_ende"  Breite am Ende (Vorgabe `breite`), linear über die Länge
##   "bauch"        Wölbung als Anteil der Breite (Vorgabe 0)
##   "bauch_ab"     so viele Meter ab dem Anfang wächst die Wölbung auf
##                  (Vorgabe 0: überall voll) – oben an der Kante liegt das
##                  Wasser noch flach
##   "name"         Knotenname (Vorgabe "Wasserband")
##   "richtung"     waagerechte Fließrichtung, wo die Bahn selbst keine hat
##   "spalten"      Unterteilung quer (Vorgabe 4, mit Bauch 8)
##   "schritt"      Abtastweite längs in Metern (Vorgabe 0,5)
##   "tempo", "farbe_tief", "farbe_schaum"  Stoffwerte (Vorgaben wie der Fall
##                  an der Schluchtwand)
##   "ferne"        so viel heller (und dichter) wird das Band zwischen 20 und
##                  90 m Abstand: Ein Wahrzeichen trägt so durch den Dunst,
##                  ohne von Nahem zu blenden (Vorgabe 0)
## Rückgabe: der Knoten (schon an `eltern` gehängt), oder null ohne Bahn.
static func band(eltern: Node3D, punkte: PackedVector3Array, breite: float,
		optionen: Dictionary = {}) -> Wasserfall:
	if punkte.size() < 2:
		return null
	var schritt := maxf(float(optionen.get("schritt", 0.5)), 0.05)
	var bahn := _glatte_bahn(punkte, schritt)
	if bahn.size() < 2:
		return null
	var breite_ende := float(optionen.get("breite_ende", breite))
	var bauch := float(optionen.get("bauch", 0.0))
	var bauch_ab := float(optionen.get("bauch_ab", 0.0))
	var spalten := int(optionen.get("spalten", 8 if bauch > 0.0 else 4))
	spalten = maxi(spalten, 1)

	# Laufmeter je Punkt
	var meter := PackedFloat32Array([0.0])
	for i in range(1, bahn.size()):
		meter.append(meter[i - 1] + bahn[i - 1].distance_to(bahn[i]))
	var gesamt := maxf(meter[meter.size() - 1], 0.001)

	# Waagerechte Fließrichtung je Punkt; wo die Bahn senkrecht fällt, gilt
	# die letzte davor (am Anfang die erste danach oder "richtung").
	var waag: Array[Vector3] = []
	var zuletzt: Vector3 = optionen.get("richtung", Vector3.ZERO)
	zuletzt.y = 0.0
	for i in bahn.size():
		var vor := bahn[mini(i + 1, bahn.size() - 1)] - bahn[maxi(i - 1, 0)]
		var lang := vor.length()
		vor.y = 0.0
		if lang > 0.0001 and vor.length() > 0.2 * lang:
			zuletzt = vor.normalized()
		waag.append(zuletzt)
	var erste := Vector3.FORWARD
	for w in waag:
		if w.length() > 0.5:
			erste = w
			break
	for i in waag.size():
		if waag[i].length() < 0.5:
			waag[i] = erste
		else:
			break

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vorher: Array[Vector3] = []
	for i in bahn.size():
		var p := bahn[i]
		var tangente := (bahn[mini(i + 1, bahn.size() - 1)] - bahn[maxi(i - 1, 0)]).normalized()
		var quer := waag[i].cross(Vector3.UP).normalized()
		# Nach vorn: bei einem Fall vom Fels weg, bei einer Rinne nach oben
		var vorn := quer.cross(tangente).normalized()
		var weite := lerpf(breite, breite_ende, meter[i] / gesamt)
		var wolbung := bauch * weite
		if bauch_ab > 0.0:
			wolbung *= smoothstep(0.0, bauch_ab, meter[i])
		var reihe: Array[Vector3] = []
		for k in spalten + 1:
			var u := float(k) / float(spalten)
			reihe.append(p + quer * (u - 0.5) * weite + vorn * sin(u * PI) * wolbung)
		if not vorher.is_empty():
			for k in spalten:
				var u0 := float(k) / float(spalten)
				var u1 := float(k + 1) / float(spalten)
				_ecke(st, vorher[k], Vector2(u0, meter[i - 1]))
				_ecke(st, reihe[k], Vector2(u0, meter[i]))
				_ecke(st, reihe[k + 1], Vector2(u1, meter[i]))
				_ecke(st, vorher[k], Vector2(u0, meter[i - 1]))
				_ecke(st, reihe[k + 1], Vector2(u1, meter[i]))
				_ecke(st, vorher[k + 1], Vector2(u1, meter[i - 1]))
		vorher = reihe

	var fall := Wasserfall.new()
	fall.name = String(optionen.get("name", "Wasserband"))
	st.index()
	fall.mesh = st.commit()
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FALL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("laenge", gesamt)
	for wert: String in ["tempo", "farbe_tief", "farbe_schaum", "ferne"]:
		if optionen.has(wert):
			mat.set_shader_parameter(wert, optionen[wert])
	fall.material_override = mat
	eltern.add_child(fall)
	return fall


## Catmull-Rom durch alle Punkte, abgetastet alle `schritt` Meter (je
## Abschnitt mindestens einmal). Die Enden werden gespiegelt verlängert.
static func _glatte_bahn(punkte: PackedVector3Array, schritt: float) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var n := punkte.size()
	for i in n - 1:
		var p1 := punkte[i]
		var p2 := punkte[i + 1]
		var p0 := punkte[i - 1] if i > 0 else p1 * 2.0 - p2
		var p3 := punkte[i + 2] if i + 2 < n else p2 * 2.0 - p1
		var teile := maxi(ceili(p1.distance_to(p2) / schritt), 1)
		for k in teile:
			var t := float(k) / float(teile)
			aus.append(p1.cubic_interpolate(p2, p0, p3, t))
	aus.append(punkte[n - 1])
	return aus


static func _ecke(st: SurfaceTool, p: Vector3, uv: Vector2) -> void:
	st.set_normal(Vector3.UP)
	st.set_uv(uv)
	st.add_vertex(p)
