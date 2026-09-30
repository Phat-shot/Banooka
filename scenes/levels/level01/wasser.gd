extends RefCounted
class_name L01Wasser
## Level 01, Modul „Wasser": Bach, Furt und der zweistufige Wurzelfall
## (Plan Abschnitt 8.5).
##
## WAS HIER ENTSTEHT.
## * Der **Bach** als EIN Band über alle Läufe, die das Gelände gegraben hat
##   (`L01Gelaende.bachlauf()`: "bach" vom Tümpel durch den Kanal am Fuß von
##   C4, über die Furt und am Knoll vorbei aus dem Tal, dazu "oberlauf" über
##   den Pfeilerhügel und "rinne" über der Kerbe). Das Band folgt den
##   geraden Stücken des Bettes mit dessen Spiegel; quer reicht es bis an
##   das GEZEICHNETE Ufer (`L01Gelaende.hoehe`, die Dreiecke des Feldes) und
##   ein Stück hinein – nie in die Senke dahinter, wo das Gelände wieder
##   unter den Spiegel fällt. Am Tümpel und an der Quelle schließt es rund,
##   am Rand des Feldes blendet es aus, in Fallbänder geht es über. Dazu der
##   Spiegel des Felsbeckens unter dem Pfeiler (bis an dessen Wand).
## * Das Wasser **fließt**: dunkel und grün wie ein Waldbach, Schaumflecken
##   treiben mit der Strömung (schnell, wo der Spiegel fällt, weiß in den
##   Schnellen). Am Ufer ein weicher, fleckiger Schaumsaum, und an der
##   Uferlinie selbst läuft das Wasser durchsichtig aus: Dort schneidet es
##   die Dreiecke des Geländes, die sonst als Sägezahn stünden. Es spiegelt
##   den Horizont und glitzert (`himmel_farbe`, `glitzer`; im Web ohne
##   Glitzern). Eigener Shader (`BACH_SHADER`), weil der der Wasserfläche
##   keine Fließrichtung kennt; die Wellen sind dieselben.
## * **Wurzelfall**, zweistufig (`Wasserfall.band`):
##     oben    der Oberlauf stürzt über die Krone des Pfeilers (y ≈ 31,5) in
##             das Felsbecken links (19,45): ein Strahl, der sich von der
##             Wand löst (Wurfbahn), gewölbt, damit er auch von der Seite –
##             vom Grat und vom Ziel aus – Tiefe hat
##     Rinne   aus dem Becken über die Stufe in die Fallkerbe und quer unter
##             dem Weg hindurch bis an die rechte Lippe: knapp einen Meter
##             über dem Grund (18), damit man sie im Schlitz sieht, nach der
##             Wegmitte fällt sie auf den Grund der Lippe
##     unten   über die Lippe die rechte Wand hinab (folgt der Fläche des
##             Saums, `GelaendeSaum.flaeche_punkt`) und über den Schutt in den
##             Tümpel
##     Rinnsal in der Kerbe: aus der Rinne die Böschung hinab, über den
##             dunklen Grund und die rechte Wand hinunter – zwei Stränge
##             nebeneinander
##   Der Tümpel, in den der untere Fall stürzt, ist der Anfang des Laufs
##   "bach" in `bachlauf()` (Plan 8.5, Nachtrag), nicht `Level01.BACH`.
## * **Gischt** (`Staubflug`) im Becken, in der Fallkerbe (fein und nur bis
##   an die Lippe – sie steht vor dem Sprung) und am Tümpel;
##   **Schaum** (ein unbeleuchtetes Netz) um die Trittsteine der Furt und
##   wo die Fälle aufschlagen.
##
## TÖDLICH nur, wo es so aussieht: in der Furt (s 173–183, Spiegel 6,0) und
## im Kanal am Fuß von C4 (die Stücke mit "toedlich" in `bachlauf()`). Dort
## liegt eine `Wasser`-Zone (Aufspritzer, dann ertrinken), deren eigene
## Fläche ausgeblendet ist – gezeichnet wird das Band. Überall sonst ist
## Wasser Kulisse; darunter fangen die Todeszonen des Rohbaus.
##
## KOLLISION baut das Modul keine (nur die Auslösezonen des Wassers, Ebene 0).
##
## KOSTEN (Plan 13: ≤ 10 Zeichenaufrufe, ≤ 5k Dreiecke): 1 Bachband,
## 5 Fallbänder (oben, Rinne, unten, zwei Rinnsale), 3 Gischtwolken,
## 1 Schaumnetz – alles ohne Schatten.

const WASSER_SZENE := preload("res://scenes/hazards/Wasser.tscn")

## Ohne gezeichnetes Ufer in Reichweite (außerhalb des Feldes) reicht das
## Band so weit über die halbe Bettbreite hinaus.
const UFER_ZUGABE := 0.6
## Abtastweite des Bachbands längs (m).
const SCHRITT := 1.2
## Auf so vielen Metern gehen Oberlauf und Rinne in ihr Fallband über.
const UEBERGANG := 1.6
## Sichtweiten: Rinne und Gischt der Fallkerbe (nur von Nahem zu sehen),
## Rinnsal der Kerbe (vom Grat aus bis zur Kanzel).
const SICHT_NAH := 60.0
const SICHT_RINNSAL := 110.0
## So weit vor dem Rand des Geländefelds endet der Bach (ausgeblendet über
## `AUSBLENDEN` m).
const FELDRAND := 6.0
const AUSBLENDEN := 10.0

## Das Felsbecken unter dem Pfeiler: Spiegel (Welt-Y) und Umriss (s, q).
const BECKEN_SPIEGEL := 19.45
## Wasserspiegel der Rinne in der Fallkerbe (Grund 18, Lippen 20,8 / 20,0).
const RINNE_SPIEGEL := 18.92
const BECKEN_S := Vector2(112.6, 118.0)
const BECKEN_Q := Vector2(-10.6, -5.2)

## Wasserspiegel der Furt (Plan 5D) und ihre Auslösezone (s, q).
const FURT_SPIEGEL := 6.0
const FURT_S := Vector2(173.0, 183.0)
const FURT_Q := 7.0

## Farben des Bachs: tief, hell, Schaum, gespiegelter Himmel. Dunkel und
## grün wie ein Waldbach – das helle Blaugrau las sich als Eismatsch.
const FARBE_TIEF := Color(0.07, 0.13, 0.12)
const FARBE_HELL := Color(0.16, 0.25, 0.22)
const FARBE_SCHAUM := Color(0.84, 0.91, 0.92)
const HIMMEL_FARBE := Color(0.70, 0.80, 0.84)
const GLITZER := 1.0

## Wellen: Hunderte Meter Bach sind kein See – flach und fein.
const WELLEN_HOEHE := 0.05

## Fälle: Farbe des Schaums etwas über Weiß (unbeleuchtet, gegen die
## schattige Wand gedämpft vom Tonemapping), tiefes Blaugrün.
const FALL_SCHAUM := Color(0.86, 0.93, 0.95)
const FALL_TIEF := Color(0.2, 0.38, 0.42)

## Gemeinsamer Teil beider Shader: die Wellen der Wasserfläche. Der Schaum
## reitet auf denselben Wellen wie das Band.
const WELLEN_CODE := """
uniform sampler2D rauschen : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float wellen_hoehe = 0.05;

float wellenfeld(vec2 p, float t) {
	float h = 0.0;
	h += sin(p.x * 0.90 + t * 1.30) * 0.42;
	h += sin(p.y * 1.25 - t * 1.05) * 0.30;
	h += sin((p.x + p.y) * 0.55 + t * 0.75) * 0.24;
	h += sin((p.x - p.y * 1.7) * 1.90 - t * 1.90) * 0.11;
	h += sin((p.x * 2.6 + p.y * 0.4) + t * 2.40) * 0.06;
	return h;
}

float welle(vec2 xz, float t) {
	float h = wellenfeld(xz * 1.4, t * 1.3);
	h += (texture(rauschen, xz * 0.05 + vec2(t * 0.020, t * 0.015)).r - 0.5) * 0.75;
	return h;
}
"""

## Das Bachband. UV = (quer in m, längs in m), UV2.x = Fließtempo (m/s),
## COLOR = (Schnelle 0..1, Sichtbarkeit 0..1, Uferabstand 0 Mitte .. 1 Ufer).
## Kein Bildschirm- und kein Tiefenpuffer (gl_compatibility).
const BACH_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform vec3 farbe_tief : source_color = vec3(0.07, 0.13, 0.12);
uniform vec3 farbe_hell : source_color = vec3(0.16, 0.25, 0.22);
uniform vec3 farbe_schaum : source_color = vec3(0.84, 0.91, 0.92);
uniform vec3 himmel_farbe : source_color = vec3(0.70, 0.80, 0.84);
uniform sampler2D stroemung : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float grund_alpha = 0.74;
uniform float spiegelung = 0.55;
uniform float glitzer = 1.0;
%s
varying float wellen;
varying vec2 welt;
varying vec3 fluss;
varying vec3 art;

// Zerreißt den Schaumsaum am Ufer in Flocken statt einer weißen Linie.
float kraeusel_saum(vec2 p) {
	return texture(stroemung, p * 0.35 + vec2(TIME * 0.02, TIME * 0.015)).r * 0.6;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	welt = w.xz;
	float h = welle(w.xz, TIME);
	wellen = clamp(h, -1.0, 1.0);
	VERTEX.y += h * wellen_hoehe;
	float e = 0.3;
	float dx = welle(w.xz + vec2(e, 0.0), TIME) - welle(w.xz - vec2(e, 0.0), TIME);
	float dz = welle(w.xz + vec2(0.0, e), TIME) - welle(w.xz - vec2(0.0, e), TIME);
	NORMAL = normalize(vec3(-dx * wellen_hoehe, 2.0 * e, -dz * wellen_hoehe));
	fluss = vec3(UV.x, UV.y, UV2.x);
	art = COLOR.rgb;
}

void fragment() {
	float k = clamp(wellen * 0.5 + 0.5, 0.0, 1.0);
	float ufer = art.b;
	float wild = art.r;
	// Mitte tief, zum Ufer hin flach und heller
	vec3 farbe = mix(farbe_tief, farbe_hell, k * 0.6 + smoothstep(0.45, 1.0, ufer) * 0.4);
	// Schaumflecken mit der Strömung: wenig gestreckt, zwei Lagen, nur wo
	// beide hoch stehen – lange, dünne Striche lasen sich wie Regen.
	float lauf = fluss.y - TIME * fluss.z;
	float s1 = texture(stroemung, vec2(fluss.x * 0.35, lauf * 0.12)).r;
	float s2 = texture(stroemung, vec2(fluss.x * 0.55 + 0.31,
			(fluss.y - TIME * fluss.z * 1.35) * 0.11)).r;
	float streifen = smoothstep(0.72, 0.9, s1 * 0.55 + s2 * 0.55);
	float schaum = streifen * (0.2 + 0.8 * wild);
	// In der Schnelle zerrissener Schaum: grob mit fein gemischt, keine
	// Zebrastreifen
	float fetzen = texture(stroemung, vec2(fluss.x * 0.5 + 0.7,
			(fluss.y - TIME * fluss.z * 1.1) * 0.3)).r;
	schaum = max(schaum, wild * smoothstep(0.42, 0.78, s2 * 0.6 + fetzen * 0.5) * 0.9);
	// Schaumsaum am Ufer: ein durchgehender, weicher, fleckiger Streifen
	// vor der Linie, an der das Wasser die Böschung schneidet (die Dreiecke
	// des Geländes zeichnen sie als Treppe) – dort wird das Wasser selbst
	// durchsichtig (siehe ALPHA).
	float flocken = kraeusel_saum(welt);
	float saum = smoothstep(0.6, 0.84, ufer + (flocken - 0.3) * 0.5)
			* (1.0 - smoothstep(0.9, 1.05, ufer));
	schaum = max(schaum, saum * (0.2 + 0.4 * flocken));
	float kraeusel = texture(rauschen, welt * 0.34 + vec2(TIME * 0.05, -TIME * 0.04)).r;
	schaum = max(schaum, smoothstep(0.82, 0.98, k) * smoothstep(0.35, 0.7, kraeusel) * 0.12);
	farbe = mix(farbe, farbe_schaum, schaum);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	farbe += himmel_farbe * fresnel * spiegelung * (1.0 - schaum);
	// Glitzern wie auf der Wasserfläche: zwei gegenläufig treibende
	// Rauschmuster, nur wo beide hoch stehen, blitzt ein Punkt auf.
	// Seltener als auf der Wasserfläche und vor allem im flachen Blick, wo
	// die Wellen die Sonne am ehesten zurückwerfen – sonst lag ein
	// Sternenhimmel auf dem Bach.
	float funkeln = 0.0;
	if (glitzer > 0.0) {
		float g1 = textureLod(rauschen, welt * 0.23 + vec2(TIME * 0.021, -TIME * 0.013), 0.0).r;
		float g2 = textureLod(rauschen, welt * 0.31 - vec2(TIME * 0.010, TIME * 0.018), 0.0).r;
		funkeln = smoothstep(0.52, 0.66, g1 * g2) * glitzer * (0.35 + 0.65 * fresnel)
				* (1.0 - schaum);
	}
	ALBEDO = farbe;
	// Am flachen Ufer durchsichtiger: dort scheint das Bett durch, und an
	// der Uferlinie selbst läuft das Wasser ganz aus.
	float deck = mix(grund_alpha, grund_alpha - 0.2, smoothstep(0.5, 0.95, ufer));
	float auslauf = 1.0 - smoothstep(0.8, 1.0, ufer + (flocken - 0.3) * 0.12);
	ALPHA = clamp(deck + fresnel * 0.3 + schaum * 0.3 + funkeln * 0.3, 0.0, 1.0) * art.g
			* auslauf;
	// Wenig Glanz aus der Umgebung: Der blaue Himmel im Spiegel machte den
	// Bach zum Kinderbild. Den Horizont spiegelt `himmel_farbe`.
	ROUGHNESS = mix(0.4, 0.2, fresnel) + schaum * 0.4;
	METALLIC = 0.0;
	SPECULAR = 0.1;
	EMISSION = farbe * 0.1 + himmel_farbe * funkeln * 2.5 + farbe_schaum * schaum * 0.15;
}
"""

## Schaum um Steine und wo die Fälle aufschlagen: unbeleuchtet, reitet auf
## den Wellen. UV.x = 0 innen .. 1 außen, UV.y = Umfang in m, COLOR.a =
## Deckkraft, COLOR.r = Tempo nach außen.
const SCHAUM_SHADER := """
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 farbe : source_color = vec3(0.86, 0.92, 0.93);
uniform sampler2D stroemung : hint_default_white, filter_linear_mipmap, repeat_enable;
%s
varying vec2 lage;
varying vec2 kraft;
varying vec2 welt;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += welle(w.xz, TIME) * wellen_hoehe;
	welt = w.xz;
	lage = UV;
	kraft = vec2(COLOR.a, COLOR.r);
}

void fragment() {
	// Wolkiger Schaum in Weltkoordinaten, der vom Stein bzw. vom Aufschlag
	// wegtreibt (UV.x 0 innen .. 1 außen): keine Speichen, keine Ringe.
	float r = lage.x;
	float t = TIME * kraft.y;
	float n1 = texture(stroemung, welt * 0.21 + vec2(t * 0.031, -t * 0.024)).r;
	float n2 = texture(stroemung, welt * 0.55 + vec2(-t * 0.05, t * 0.043) + 0.37).r;
	float n3 = texture(stroemung, vec2(lage.y * 0.3, r * 0.9 - t * 0.2)).r;
	float dicht = n1 * 0.45 + n2 * 0.4 + n3 * 0.3 - r * 0.62 + 0.1;
	float a = smoothstep(0.3, 0.58, dicht) * (1.0 - smoothstep(0.45, 1.0, r));
	ALBEDO = farbe * mix(0.85, 1.0, n2);
	ALPHA = a * kraft.x;
}
"""

static var _bach_shader: Shader = null
static var _schaum_shader: Shader = null


## Bauschritte, je {"text": String, "tun": Callable}. Läuft nach Saum und
## Gelände: Das Bett (`bachlauf`, `hoehe`) und die Flächen der Wände
## (`flaeche_punkt`) stehen dann.
static func bauschritte(level: Level01) -> Array:
	var stand := {}
	return [
		{"text": "Der Bach füllt sein Bett", "tun": func() -> void:
			stand["wurzel"] = _wurzel(level)
			stand["texturen"] = _texturen()
			_bach_bauen(level, stand)},
		{"text": "Wasser stürzt über die Felsen", "tun": func() -> void:
			_faelle_bauen(level, stand)},
		{"text": "Gischt und Schaum", "tun": func() -> void:
			_gischt_bauen(level, stand)},
	]


static func _wurzel(level: Level01) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = "Wasser"
	level.geometrie.add_child(knoten)
	return knoten


## Rauschen für Wellen und Glitzern (fein, wie `Wasser`) und für die
## Strömung (grob, gestreckt gelesen). Je Bau neu, nie verändert.
static func _texturen() -> Dictionary:
	return {
		"fein": Materialbibliothek.rauschtextur(1313, 0.9, Color.BLACK, Color.WHITE, 128),
		"grob": Materialbibliothek.rauschtextur(4711, 0.045, Color.BLACK, Color.WHITE, 256),
	}


# ================================================================ Bach

static func _bach_bauen(level: Level01, stand: Dictionary) -> void:
	var laeufe := L01Gelaende.bachlauf()
	var netz := Netz.new()
	var feld := L01Gelaende.FELD.grow(-FELDRAND)
	for lauf: Dictionary in laeufe:
		var name := String(lauf["name"])
		var punkte: PackedVector3Array = lauf["punkte"]
		var breiten: PackedFloat32Array = lauf["breite"]
		# Der Bach beginnt im Tümpel unter dem unteren Fall (Plan 8.5,
		# Nachtrag: nach dem gegrabenen Bett, nicht nach `Level01.BACH`).
		if name == "bach" and not punkte.is_empty():
			stand["tuempel"] = punkte[0]
			stand["tuempel_breite"] = breiten[0]
		# Nur innerhalb des Feldes: draußen gibt es kein Bett
		var bis := punkte.size()
		for i in punkte.size():
			if not feld.has_point(Vector2(punkte[i].x, punkte[i].z)):
				bis = i
				break
		if bis < 2:
			continue
		var zeile := _lauf_abtasten(punkte, breiten, bis, feld)
		# Rund schließen, wo ein Lauf beginnt (Tümpel, Quelle). Die Rinne
		# endet an der Kante der Kerbe, der Oberlauf an der Krone des
		# Pfeilers – dort stürzen sie weiter (Fallbänder): Das Band blendet
		# auf den letzten `UEBERGANG` Metern aus, das Fallband beginnt dort.
		if name != "bach":
			var ende: float = zeile[zeile.size() - 1]["laengs"]
			for st in zeile:
				st["sicht"] = minf(float(st["sicht"]),
						clampf((ende - float(st["laengs"])) / UEBERGANG, 0.0, 1.0))
		_kappe(netz, zeile, true)
		_band_schreiben(netz, zeile)
		if name == "bach" and bis == punkte.size():
			_kappe(netz, zeile, false)
		stand["lauf_" + name] = zeile
	_becken_schreiben(level, netz)
	var knoten := MeshInstance3D.new()
	knoten.name = "Bach"
	knoten.mesh = netz.fertig()
	knoten.material_override = _bach_stoff(stand["texturen"] as Dictionary)
	knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	knoten.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Die Wellen heben die Fläche um bis zu 0,05 m
	knoten.extra_cull_margin = 0.5
	(stand["wurzel"] as Node3D).add_child(knoten)
	_zonen_bauen(level, laeufe, stand["wurzel"] as Node3D)
	if level.debug:
		print("Bach: %d Punkte, %d Dreiecke" % [netz.punkte.size(), netz.indizes.size() / 3])


## Tastet einen Lauf ab: je Stelle {"p": Welt (Spiegel), "halb": halbe
## Breite, "laengs": Laufmeter, "tempo", "wild", "sicht"}. Die Stellen
## liegen auf den geraden Stücken des Bettes (so gräbt es das Gelände),
## höchstens `SCHRITT` auseinander, die Ecken inbegriffen.
static func _lauf_abtasten(punkte: PackedVector3Array, breiten: PackedFloat32Array,
		bis: int, feld: Rect2) -> Array[Dictionary]:
	var aus: Array[Dictionary] = []
	var laengs := 0.0
	for i in bis - 1:
		var a := punkte[i]
		var b := punkte[i + 1]
		var lang := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
		# Gefälle des Spiegels: Tempo und Schnelle
		var gefaelle := (a.y - b.y) / maxf(lang, 0.01)
		var teile := maxi(ceili(lang / SCHRITT), 1)
		for k in teile:
			var t := float(k) / float(teile)
			aus.append(_stelle(a.lerp(b, t), lerpf(breiten[i], breiten[i + 1], t),
					laengs + lang * t, gefaelle))
		laengs += lang
	var letzte := punkte[bis - 1]
	var g_ende := (punkte[bis - 2].y - letzte.y) / maxf(
			Vector2(punkte[bis - 2].x, punkte[bis - 2].z).distance_to(Vector2(letzte.x, letzte.z)), 0.01)
	aus.append(_stelle(letzte, breiten[bis - 1], laengs, g_ende))
	# Am Feldrand ausblenden
	if bis < punkte.size():
		for st in aus:
			var p: Vector3 = st["p"]
			var rand := minf(minf(p.x - feld.position.x, feld.end.x - p.x),
					minf(p.z - feld.position.y, feld.end.y - p.z))
			st["sicht"] = clampf(rand / AUSBLENDEN, 0.0, 1.0)
	# Tempo und Schnelle geglättet (sonst springt der Schaum an den Ecken)
	var tempo := PackedFloat32Array()
	var wild := PackedFloat32Array()
	for i in aus.size():
		var summe := Vector2.ZERO
		var n := 0
		for j in range(maxi(i - 3, 0), mini(i + 4, aus.size())):
			summe += Vector2(float(aus[j]["tempo"]), float(aus[j]["wild"]))
			n += 1
		tempo.append(summe.x / float(n))
		wild.append(summe.y / float(n))
	for i in aus.size():
		aus[i]["tempo"] = tempo[i]
		aus[i]["wild"] = wild[i]
	return aus


static func _stelle(p: Vector3, breite: float, laengs: float, gefaelle: float) -> Dictionary:
	return {"p": p, "halb": breite * 0.5, "laengs": laengs,
			"tempo": clampf(0.7 + gefaelle * 30.0, 0.6, 4.5),
			"wild": clampf((gefaelle - 0.025) * 7.0, 0.0, 1.0), "sicht": 1.0}


## Richtung (waagerecht) an Stelle `i`: Mittel der Nachbarn – an den Ecken
## die Winkelhalbierende, so bleibt der Rand auf dem runden Ufer.
static func _richtung(zeile: Array[Dictionary], i: int) -> Vector3:
	var a: Vector3 = zeile[maxi(i - 1, 0)]["p"]
	var b: Vector3 = zeile[mini(i + 1, zeile.size() - 1)]["p"]
	var d := b - a
	d.y = 0.0
	return d.normalized() if d.length() > 0.0001 else Vector3.FORWARD


## Das Band: fünf Punkte quer (Ränder, Viertel, Mitte), damit der
## Uferabstand in COLOR.b linear bleibt. Jede Seite reicht bis an das
## wirkliche Ufer (`_ufer`), nicht an die Sollbreite.
static func _band_schreiben(netz: Netz, zeile: Array[Dictionary]) -> void:
	const QUER: Array[float] = [-1.0, -0.5, 0.0, 0.5, 1.0]
	# Ufer je Stelle, dann über die Nachbarn geglättet (das gezeichnete Ufer
	# springt von Dreieck zu Dreieck). Nie mehr als 0,3 m über das eigene
	# hinaus – dort liegt die Böschung sicher noch über dem Spiegel.
	var roh: Array[PackedVector2Array] = []
	for i in zeile.size():
		var st: Dictionary = zeile[i]
		var p: Vector3 = st["p"]
		var halb: float = st["halb"]
		var rechts := _richtung(zeile, i).cross(Vector3.UP).normalized()
		roh.append(PackedVector2Array([_ufer(p, -rechts, halb), _ufer(p, rechts, halb)]))
	var vorher := -1
	for i in zeile.size():
		var st: Dictionary = zeile[i]
		var p: Vector3 = st["p"]
		var rechts := _richtung(zeile, i).cross(Vector3.UP).normalized()
		var glatt := PackedVector2Array()
		for seite in 2:
			var summe := Vector2.ZERO
			var n := 0.0
			for j in range(maxi(i - 1, 0), mini(i + 2, zeile.size())):
				var g := 1.0 if j == i else 0.5
				summe += roh[j][seite] * g
				n += g
			var eigen := roh[i][seite]
			var mittel := summe / n
			glatt.append(Vector2(minf(mittel.x, eigen.x + 0.3), mittel.y))
		var links_ufer := glatt[0]
		var rechts_ufer := glatt[1]
		var erste := netz.punkte.size()
		for u in QUER:
			var seite := links_ufer if u < 0.0 else rechts_ufer
			var q := u * seite.x
			netz.punkt(p + rechts * q, Vector2(q, float(st["laengs"])), float(st["tempo"]),
					Color(float(st["wild"]), float(st["sicht"]), absf(q) / seite.y))
		if vorher >= 0:
			for k in QUER.size() - 1:
				netz.viereck(vorher + k, vorher + k + 1, erste + k + 1, erste + k)
		vorher = erste


## Wie weit reicht das Wasser von `p` aus in `richtung`? Bis dorthin, wo das
## GEZEICHNETE Gelände über den Spiegel tritt – das Feld ist in Dreiecken
## von 2–13 m gezeichnet, und zwischen zwei Punkten liegt sein Ufer oft
## anders als das gewollte Bett; weiter draußen sinkt es wieder unter den
## Spiegel. Dann noch ein Stück in die Böschung, solange sie über dem
## Spiegel bleibt. Rückgabe: (Kante des Bandes, Uferlinie). Ohne Gelände
## dort: die Sollbreite samt `UFER_ZUGABE`.
static func _ufer(p: Vector3, richtung: Vector3, halb: float) -> Vector2:
	var d := halb * 0.4
	var bis := halb + UFER_ZUGABE + 2.0
	while d <= bis:
		if _ueber_wasser(p + richtung * d, p.y):
			var kante := d
			for k in 3:
				var weiter := d + 0.15 * float(k + 1)
				if not _ueber_wasser(p + richtung * weiter, p.y):
					break
				kante = weiter
			return Vector2(kante, maxf(d, 0.5))
		d += 0.25
	return Vector2(halb + UFER_ZUGABE, halb)


static func _ueber_wasser(ort: Vector3, spiegel: float) -> bool:
	var h := L01Gelaende.hoehe(ort.x, ort.z)
	return not is_nan(h) and h > spiegel + 0.04


## Runder Abschluss am Anfang (`anfang`) oder Ende eines Laufs: ein Halb-
## kreis um den ersten bzw. letzten Punkt, jeder Strahl bis ans Ufer.
static func _kappe(netz: Netz, zeile: Array[Dictionary], anfang: bool) -> void:
	var i := 0 if anfang else zeile.size() - 1
	var st: Dictionary = zeile[i]
	var p: Vector3 = st["p"]
	var halb: float = st["halb"]
	var vor := _richtung(zeile, i)
	var rechts := vor.cross(Vector3.UP).normalized()
	var zurueck := -vor if anfang else vor
	var mitte := netz.punkte.size()
	var laengs: float = st["laengs"]
	netz.punkt(p, Vector2(0.0, laengs), float(st["tempo"]),
			Color(float(st["wild"]), float(st["sicht"]), 0.0))
	const TEILE := 14
	for k in TEILE + 1:
		var w := PI * float(k) / float(TEILE)
		var r := rechts * cos(w) + zurueck * sin(w)
		var ufer := _ufer(p, r, halb)
		for stufe: float in [0.5, 1.0]:
			var d := r * ufer.x * stufe
			netz.punkt(p + d, Vector2(d.dot(rechts), laengs + d.dot(vor)), float(st["tempo"]),
					Color(float(st["wild"]), float(st["sicht"]), ufer.x * stufe / ufer.y))
	for k in TEILE:
		var a := mitte + 1 + k * 2
		var b := mitte + 1 + (k + 1) * 2
		netz.dreieck(mitte, a, b)
		netz.viereck(a, a + 1, b + 1, b)


## Der Spiegel des Felsbeckens unter dem Pfeiler, als Band längs des Weges:
## außen bis an die Wand (wo die Fläche des Saums den Spiegel kreuzt), innen
## bis unter den Sims. Wo der Grund des Beckens über dem Spiegel liegt,
## findet `flaeche_punkt` dort keine Kreuzung – da ist kein Wasser. An der
## Fallkerbe (118) bricht der Grund ab; dort stürzt die Rinne weiter.
static func _becken_schreiben(level: Level01, netz: Netz) -> void:
	var reihen: Array[Dictionary] = []
	var s := BECKEN_S.x
	while s <= BECKEN_S.y + 0.001:
		var kante := level.boden_bei(s)
		var wand := GelaendeSaum.flaeche_punkt(s, -1.0, BECKEN_SPIEGEL - kante)
		if not is_nan(wand.x):
			var mitte := LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
			var rechts := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP).normalized()
			var q_wand := (wand - mitte).dot(rechts)
			if q_wand < BECKEN_Q.y - 0.8:
				reihen.append({"s": s, "q": q_wand})
		s += 0.35
	if reihen.size() < 2:
		return
	var erste := netz.punkte.size()
	const SPALTEN := 4
	var s0: float = reihen[0]["s"]
	var s1: float = reihen[reihen.size() - 1]["s"]
	for r in reihen:
		var rs: float = r["s"]
		var aussen: float = r["q"] - 0.3
		# An den Enden ausblenden: dort steigt der Grund bzw. bricht ab
		var sicht := smoothstep(s0, s0 + 0.8, rs) * (1.0 - smoothstep(s1 - 0.5, s1, rs))
		for k in SPALTEN + 1:
			var u := float(k) / float(SPALTEN)
			var q := lerpf(aussen, BECKEN_Q.y, u)
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, rs, q)
			p.y = BECKEN_SPIEGEL
			netz.punkt(p, Vector2(q, rs), 0.4, Color(0.0, sicht, 1.0 - u))
	for i in reihen.size() - 1:
		for k in SPALTEN:
			var a := erste + i * (SPALTEN + 1) + k
			var b := a + SPALTEN + 1
			netz.viereck(a, a + 1, b + 1, b)


static func _bach_stoff(texturen: Dictionary) -> ShaderMaterial:
	if _bach_shader == null:
		_bach_shader = Shader.new()
		_bach_shader.code = BACH_SHADER % WELLEN_CODE
	var m := ShaderMaterial.new()
	m.shader = _bach_shader
	m.set_shader_parameter("farbe_tief", FARBE_TIEF)
	m.set_shader_parameter("farbe_hell", FARBE_HELL)
	m.set_shader_parameter("farbe_schaum", FARBE_SCHAUM)
	m.set_shader_parameter("himmel_farbe", HIMMEL_FARBE)
	# Im Web ohne Glitzern: zwei Texturzugriffe weniger je Bildpunkt auf
	# einer großen durchsichtigen Fläche.
	m.set_shader_parameter("glitzer", 0.0 if Effekte.reduziert else GLITZER)
	m.set_shader_parameter("wellen_hoehe", WELLEN_HOEHE)
	m.set_shader_parameter("rauschen", texturen["fein"])
	m.set_shader_parameter("stroemung", texturen["grob"])
	return m


# ================================================================ Zonen

## Tödliches Wasser: Furt und Kanal. Eine `Wasser`-Zone je Stück; ihre
## eigene Fläche ist ausgeblendet (gezeichnet wird das Bachband), Auf-
## spritzen und Ertrinken bleiben wie überall im Spiel.
static func _zonen_bauen(level: Level01, laeufe: Array, wurzel: Node3D) -> void:
	# Furt: im Wegrahmen, genau über der Lücke
	var mitte_s := (FURT_S.x + FURT_S.y) * 0.5
	var furt := LevelWerkzeuge.punkt(level.verlauf, mitte_s)
	furt.y = FURT_SPIEGEL
	_zone(wurzel, "Furt", furt, LevelWerkzeuge.drehung(level.verlauf, mitte_s),
			Vector2(FURT_Q * 2.0, FURT_S.y - FURT_S.x))
	# Kanal: jedes Stück, dessen beide Enden tödlich sind
	for lauf: Dictionary in laeufe:
		if String(lauf["name"]) != "bach":
			continue
		var punkte: PackedVector3Array = lauf["punkte"]
		var breiten: PackedFloat32Array = lauf["breite"]
		var tod: PackedByteArray = lauf["toedlich"]
		for i in punkte.size() - 1:
			if tod[i] == 0 or tod[i + 1] == 0:
				continue
			# (Die Furt ist ein einzelner tödlicher Punkt ohne tödliche
			# Nachbarn: Sie hat oben ihre eigene Zone im Wegrahmen.)
			var a := punkte[i]
			var b := punkte[i + 1]
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var m := (a + b) * 0.5
			_zone(wurzel, "Kanal %d" % i, m, atan2(-ab.x, -ab.y),
					Vector2(maxf(breiten[i], breiten[i + 1]) + 1.0, ab.length() + 1.0))


static func _zone(wurzel: Node3D, name: String, ort: Vector3, drehung: float,
		flaeche: Vector2) -> void:
	var w := WASSER_SZENE.instantiate() as Wasser
	w.name = name
	w.flaeche = flaeche
	w.tiefe = 3.0
	w.position = ort
	w.rotation.y = drehung
	wurzel.add_child(w)
	var oberflaeche := w.get_node_or_null("Oberflaeche") as GeometryInstance3D
	if oberflaeche != null:
		oberflaeche.visible = false


# ================================================================ Fälle

static func _faelle_bauen(level: Level01, stand: Dictionary) -> void:
	var wurzel: Node3D = stand["wurzel"]
	var baender := 0
	# --- oben: vom Pfeiler in das Becken ---
	var ober: Array = stand.get("lauf_oberlauf", [])
	if ober.size() >= 2:
		var ende: Vector3 = (ober[ober.size() - 1] as Dictionary)["p"]
		var davor: Vector3 = (ober[maxi(ober.size() - 4, 0)] as Dictionary)["p"]
		var richtung := ende - davor
		richtung.y = 0.0
		richtung = richtung.normalized()
		var bahn := PackedVector3Array([_vor_dem_ende(ober, UEBERGANG), ende])
		# Die Wand zählt nur über dem Weg: darunter kreuzt die Fläche zuerst
		# den Boden vor dem Becken, nicht die Wand dahinter.
		var s_fall := level.verlauf.get_closest_offset(ende)
		bahn.append_array(_wurfbahn(level, ende, richtung, 2.4, BECKEN_SPIEGEL + 0.02, -1.0,
				0.45, level.boden_bei(s_fall) + 0.3))
		stand["fuss_oben"] = bahn[bahn.size() - 1]
		if Wasserfall.band(wurzel, bahn, 3.0, {"name": "Fall oben", "breite_ende": 4.8,
				"bauch": 0.22, "bauch_ab": 2.5, "tempo": 6.5, "ferne": 1.3, "spalten": 6,
				"schritt": 0.6, "farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF,
				"richtung": richtung}) != null:
			baender += 1
	# --- Rinne: aus dem Becken durch die Fallkerbe an die rechte Lippe ---
	var lippe := _lippe(level, 119.5, 1.0, L01Saum.FALLKERBE_GRUND + 0.05)
	var rinne := PackedVector3Array()
	# Über die Kante des Beckens (118) hinab in die Kerbe, dann in weitem
	# Bogen quer unter dem Weg hindurch. Sie füllt die Kerbe knapp einen
	# Meter hoch (`RINNE_SPIEGEL`) und fällt erst nach der Wegmitte auf den
	# Grund der rechten Lippe: Auf dem Grund lag sie hinter der Kante, die
	# Kerbe las sich aus der Spielkamera als schwarzer Schlitz. So steht im
	# Schlitz ein helles, schnelles Band.
	var grund := L01Saum.FALLKERBE_GRUND
	for sqh: Vector3 in [Vector3(117.1, -8.1, BECKEN_SPIEGEL + 0.02),
			Vector3(117.85, -7.9, BECKEN_SPIEGEL + 0.01), Vector3(118.1, -7.8, 19.3),
			Vector3(118.35, -7.4, RINNE_SPIEGEL + 0.14), Vector3(118.7, -6.8, RINNE_SPIEGEL + 0.05),
			Vector3(119.15, -5.8, RINNE_SPIEGEL + 0.02), Vector3(119.45, -4.1, RINNE_SPIEGEL),
			Vector3(119.5, -1.5, RINNE_SPIEGEL - 0.03), Vector3(119.5, 1.2, RINNE_SPIEGEL - 0.12),
			Vector3(119.5, 2.7, lerpf(RINNE_SPIEGEL, grund + 0.06, 0.6))]:
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, sqh.x, sqh.y)
		p.y = sqh.z
		rinne.append(p)
	if not is_nan(lippe.x):
		lippe.y = L01Saum.FALLKERBE_GRUND + 0.06
		rinne.append(lippe)
	# Nur von Nahem zu sehen: Den Grund der Kerbe verdeckt ihre Kante.
	if _sichtweite(Wasserfall.band(wurzel, rinne, 2.8, {"name": "Rinne Fallkerbe",
			"breite_ende": 1.9, "tempo": 4.5, "spalten": 3, "schritt": 0.6,
			"farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF}), SICHT_NAH):
		baender += 1
	# --- unten: über die Lippe die rechte Wand hinab in den Tümpel ---
	if not is_nan(lippe.x):
		var aussen := LevelWerkzeuge.richtung(level.verlauf, 119.5).cross(Vector3.UP).normalized()
		var tuempel: Vector3 = stand.get("tuempel", (Level01.BACH[0] as Dictionary)["punkt"])
		var bahn := PackedVector3Array([lippe - aussen * 0.6, lippe])
		var fall := _wurfbahn(level, lippe, aussen, 2.4, tuempel.y + 0.6, 1.0, 0.35)
		bahn.append_array(fall)
		# Über den Schutt in den Tümpel
		var fuss := bahn[bahn.size() - 1]
		var zum := Vector3(tuempel.x - fuss.x, 0.0, tuempel.z - fuss.z)
		var weit := zum.length()
		var halb := float(stand.get("tuempel_breite",
				(Level01.BACH[0] as Dictionary)["breite"])) * 0.5
		var schritte := maxi(ceili((weit - halb * 0.5) / 0.8), 1)
		for k in range(1, schritte + 1):
			var t := float(k) / float(schritte) * (weit - halb * 0.5) / weit
			var p := fuss + zum * t
			p.y = maxf(L01Gelaende.hoehe(p.x, p.z) + 0.1, tuempel.y + 0.03)
			p.y = minf(p.y, bahn[bahn.size() - 1].y)
			bahn.append(p)
		stand["fuss_unten"] = fuss
		stand["einlauf_unten"] = bahn[bahn.size() - 1]
		if Wasserfall.band(wurzel, bahn, 2.0, {"name": "Fall unten", "breite_ende": 3.2,
				"bauch": 0.12, "bauch_ab": 2.0, "tempo": 6.0, "ferne": 1.0, "spalten": 5,
				"schritt": 0.7, "farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF,
				"richtung": aussen}) != null:
			baender += 1
	# --- Rinnsal in der Kerbe: zwei Stränge, die nebeneinander laufen
	# (eine glatte Scheibe von einem Meter las sich wie Glas auf dem Fels) ---
	var rinne_kerbe: Array = stand.get("lauf_rinne", [])
	if rinne_kerbe.size() >= 2:
		var bahn := _rinnsal(level, (rinne_kerbe[rinne_kerbe.size() - 1] as Dictionary)["p"])
		bahn.insert(0, _vor_dem_ende(rinne_kerbe, UEBERGANG))
		# Schmal: Handbreit breite Bänder lasen sich aus der Nähe als zwei
		# weiße Papierstreifen an der Wand.
		if _sichtweite(Wasserfall.band(wurzel, bahn, 0.26, {"name": "Rinnsal Kerbe",
				"breite_ende": 0.36, "tempo": 3.5, "spalten": 2, "schritt": 0.8,
				"farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF}), SICHT_RINNSAL):
			baender += 1
		# Der zweite Strang ein Stück längs versetzt, schmaler und langsamer;
		# er zweigt erst an der Kante ab.
		var laengs := LevelWerkzeuge.richtung(level.verlauf, 57.5)
		laengs.y = 0.0
		var zweit := PackedVector3Array()
		for i in range(1, bahn.size()):
			zweit.append(bahn[i] + laengs.normalized() * 0.5 * minf(float(i) / 3.0, 1.0))
		if zweit.size() >= 2 and _sichtweite(Wasserfall.band(wurzel, zweit, 0.17,
				{"name": "Rinnsal Kerbe 2", "breite_ende": 0.26, "tempo": 2.6, "spalten": 2,
				"schritt": 0.8, "farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF}),
				SICHT_RINNSAL):
			baender += 1
	if level.debug:
		print("Wasserfälle: %d Bänder" % baender)


## Der Punkt eines abgetasteten Laufs, der `meter` vor seinem Ende liegt
## (knapp über dem Spiegel: Dort beginnt das Fallband auf dem Band).
static func _vor_dem_ende(zeile: Array, meter: float) -> Vector3:
	var ende: float = (zeile[zeile.size() - 1] as Dictionary)["laengs"]
	for i in range(zeile.size() - 1, -1, -1):
		var st: Dictionary = zeile[i]
		if ende - float(st["laengs"]) >= meter or i == 0:
			return (st["p"] as Vector3) + Vector3.UP * 0.03
	return (zeile[0] as Dictionary)["p"]


## Harte Sichtweite (Plan 13): Was aus der Ferne nur ein Strich wäre, kostet
## dort keinen Zeichenaufruf. Rückgabe: ob es den Knoten gibt.
static func _sichtweite(knoten: GeometryInstance3D, weite: float) -> bool:
	if knoten == null:
		return false
	knoten.visibility_range_end = weite
	knoten.visibility_range_end_margin = 5.0
	return true


## Wurfbahn eines Strahls, der bei `start` mit `tempo` m/s in `richtung`
## (waagerecht) über eine Kante schießt, bis `ende_y`. Er hält `abstand`
## zur Fläche des Saums auf der Seite `seite` (erst unter `wand_ab_y`
## nicht mehr): Tritt die Wand vor, läuft er über sie (Kaskade), weicht sie
## zurück, fällt er frei. Ohne den Punkt `start` selbst.
static func _wurfbahn(level: Level01, start: Vector3, richtung: Vector3, tempo: float,
		ende_y: float, seite: float, abstand: float, wand_ab_y: float = -INF) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var vor := 0.0
	var t := 0.0
	var y := start.y
	while y > ende_y + 0.001:
		t += 0.05
		y = maxf(start.y - 0.5 * 9.81 * t * t, ende_y)
		vor = maxf(vor, tempo * t)
		var p := start + richtung * vor
		p.y = y
		var s := level.verlauf.get_closest_offset(p)
		var wand := GelaendeSaum.flaeche_punkt(s, seite, y - level.boden_bei(s))
		if not is_nan(wand.x) and y >= wand_ab_y:
			vor = maxf(vor, (wand - start).dot(richtung) + abstand)
			p = start + richtung * vor
			p.y = y
		if aus.is_empty() or aus[aus.size() - 1].distance_to(p) > 0.35 or y <= ende_y + 0.001:
			aus.append(p)
	return aus


## Die Lippe einer Seite an der Strecke `s` auf der Höhe `y` (Welt): die
## erste Stelle von innen, an der die Fläche des Saums dort kreuzt.
static func _lippe(level: Level01, s: float, seite: float, y: float) -> Vector3:
	return GelaendeSaum.flaeche_punkt(s, seite, y - level.boden_bei(s))


## Das Rinnsal der Kerbe: vom Ende der Rinne die linke Wand der Kerbe hinab
## auf ihren Grund, quer hinüber und die rechte Wand hinunter.
static func _rinnsal(level: Level01, start: Vector3) -> PackedVector3Array:
	var s := clampf(level.verlauf.get_closest_offset(start), 56.6, 58.4)
	var boden := level.boden_bei(s)
	var grund := L01Saum.KERBE_GRUND + 0.06
	var bahn := PackedVector3Array([start])
	var zum_weg := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP).normalized()
	# links hinab, auf der Fläche (etwas davor)
	var y := start.y - 0.3
	while y > grund + 0.4:
		var w := GelaendeSaum.flaeche_punkt(s, -1.0, y - boden)
		if not is_nan(w.x):
			bahn.append(w + zum_weg * 0.12 + Vector3.UP * 0.04)
		y -= 0.6
	# über den Grund zur rechten Lippe
	var rechts := GelaendeSaum.flaeche_punkt(s, 1.0, grund - 0.1 - boden)
	if is_nan(rechts.x):
		return bahn
	var links_fuss := bahn[bahn.size() - 1]
	links_fuss.y = grund
	bahn.append(links_fuss + zum_weg * 0.6)
	var ueber := rechts
	ueber.y = grund
	bahn.append(ueber.lerp(links_fuss, 0.5))
	bahn.append(ueber - zum_weg * 0.3)
	# die rechte Wand hinab, bis auf den Schutt
	var fall := _wurfbahn(level, ueber, zum_weg, 1.2, grund - 11.0, 1.0, 0.15)
	for p in fall:
		if L01Gelaende.hoehe(p.x, p.z) > p.y - 0.1:
			bahn.append(p)
			break
		bahn.append(p)
	return bahn


# ================================================================ Gischt

static func _gischt_bauen(level: Level01, stand: Dictionary) -> void:
	var wurzel: Node3D = stand["wurzel"]
	var texturen: Dictionary = stand["texturen"]
	# Wolken: im Becken, in der Fallkerbe, am Tümpel
	if stand.has("fuss_oben"):
		var fuss: Vector3 = stand["fuss_oben"]
		# Große, weiche Flocken, die bis über die Krone steigen: Vom Ziel aus
		# verdeckt die Wand der Fallklamm den Fall bis auf seine Kante, die
		# Wolke darüber zeigt, wo er stürzt.
		_wolke(wurzel, "Gischt Becken", fuss + Vector3.DOWN * 0.4, Vector3(5.5, 14.0, 5.5), 44,
				1.3, 0.1, 1.6, 7101)
	var kerbe := LevelWerkzeuge.punkt(level.verlauf, 119.5, 0.0)
	kerbe.y = RINNE_SPIEGEL - 0.4
	# Sie steigt über die Lippe: Den Grund der Kerbe sieht die Kamera nicht,
	# die Gischt darüber sagt, dass unten Wasser rauscht.
	# Fein und niedrig: Sie steigt nur bis an die Lippe (Grund 18, Weg gut
	# 20,7). Große Flocken in Augenhöhe der Figur lasen sich wie Schnee und
	# standen genau vor dem Sprung.
	# Dichter als zuvor (70 statt 40, Deckkraft 0,26), aber fein wie zuvor:
	# ein weißer Hauch über dem Band, der die Kerbe als Wasser ansagt.
	var wolke := _wolke(wurzel, "Gischt Fallkerbe", kerbe, Vector3(8.5, 2.6, 2.4), 70, 0.16,
			0.26, 0.6, 7102)
	wolke.rotation.y = LevelWerkzeuge.drehung(level.verlauf, 119.5)
	_sichtweite(wolke, SICHT_NAH)
	if stand.has("fuss_unten"):
		var fuss: Vector3 = stand["fuss_unten"]
		_wolke(wurzel, "Gischt Tümpel", fuss + Vector3.DOWN * 0.3, Vector3(5.0, 8.0, 5.0), 40,
				0.9, 0.13, 1.0, 7103)
	# Schaum: um die Trittsteine und wo die Fälle aufschlagen
	var netz := Netz.new()
	for name: String in ["Furtstein 1", "Furtstein 2"]:
		var e := level.begehbar(name)
		if e.is_empty():
			continue
		var mitte := (e["lage"] as Transform3D).origin
		mitte.y = FURT_SPIEGEL + 0.015
		var r := float(e["radius"])
		_ring(netz, mitte, r * 0.8, r + 1.1, 0.75, 0.6, name.hash())
	if stand.has("fuss_oben"):
		var fuss: Vector3 = stand["fuss_oben"]
		fuss.y = BECKEN_SPIEGEL + 0.02
		_ring(netz, fuss, 0.0, 2.2, 1.0, 1.4, 11)
	if stand.has("einlauf_unten"):
		var fuss: Vector3 = stand["einlauf_unten"]
		var tuempel: Vector3 = stand.get("tuempel", (Level01.BACH[0] as Dictionary)["punkt"])
		fuss.y = tuempel.y + 0.02
		_ring(netz, fuss, 0.0, 2.6, 1.0, 1.2, 13)
	var knoten := MeshInstance3D.new()
	knoten.name = "Schaum"
	knoten.mesh = netz.fertig()
	knoten.material_override = _schaum_stoff(texturen)
	knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	knoten.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	knoten.extra_cull_margin = 0.5
	wurzel.add_child(knoten)


static func _wolke(wurzel: Node3D, name: String, ort: Vector3, raum: Vector3, anzahl: int,
		groesse: float, deckkraft: float, steigen: float, saat: int) -> Staubflug:
	var g := Staubflug.new()
	g.name = name
	g.raum = raum
	g.anzahl = anzahl
	g.groesse = groesse
	g.groessen_streuung = 0.6
	g.farbe = Color(0.8, 0.9, 0.93)
	g.deckkraft = deckkraft
	g.steiggeschwindigkeit = steigen
	g.wirbel = 0.55
	g.wirbel_tempo = 0.5
	g.funkeln = 0.3
	g.saat = saat
	g.position = ort
	wurzel.add_child(g)
	return g


## Ein Schaumring (innen `innen`, außen `aussen`, bei `innen` 0 eine
## Scheibe) mit ausgefranstem Außenrand.
static func _ring(netz: Netz, mitte: Vector3, innen: float, aussen: float, deckkraft: float,
		tempo: float, saat: int) -> void:
	var zufall := RandomNumberGenerator.new()
	zufall.seed = saat
	const TEILE := 28
	const STUFEN := 4
	var erste := netz.punkte.size()
	var umfang := TAU * aussen
	var zacken := PackedFloat32Array()
	for k in TEILE:
		zacken.append(zufall.randf_range(0.8, 1.15))
	for k in TEILE + 1:
		var w := TAU * float(k) / float(TEILE)
		var richtung := Vector3(cos(w), 0.0, sin(w))
		var zacke := zacken[k % TEILE]
		for j in STUFEN + 1:
			var u := float(j) / float(STUFEN)
			var r := lerpf(innen, aussen * lerpf(1.0, zacke, u), u)
			netz.punkt(mitte + richtung * r, Vector2(u, umfang * float(k) / float(TEILE)), 0.0,
					Color(tempo, 0.0, 0.0, deckkraft))
	for k in TEILE:
		for j in STUFEN:
			var a := erste + k * (STUFEN + 1) + j
			var b := a + STUFEN + 1
			netz.viereck(a, a + 1, b + 1, b)


static func _schaum_stoff(texturen: Dictionary) -> ShaderMaterial:
	if _schaum_shader == null:
		_schaum_shader = Shader.new()
		_schaum_shader.code = SCHAUM_SHADER % WELLEN_CODE
	var m := ShaderMaterial.new()
	m.shader = _schaum_shader
	m.set_shader_parameter("farbe", FARBE_SCHAUM)
	m.set_shader_parameter("wellen_hoehe", WELLEN_HOEHE)
	m.set_shader_parameter("rauschen", texturen["fein"])
	m.set_shader_parameter("stroemung", texturen["grob"])
	# Über dem Bach, der selbst durchsichtig ist
	m.render_priority = 1
	return m


# ================================================================ Netz

## Sammelt Punkte und Dreiecke für ein ArrayMesh: Punkt, UV, UV2.x, Farbe.
class Netz:
	extends RefCounted
	var punkte := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var farben := PackedColorArray()
	var indizes := PackedInt32Array()

	func punkt(p: Vector3, u: Vector2, tempo: float, farbe: Color) -> void:
		punkte.append(p)
		uv.append(u)
		uv2.append(Vector2(tempo, 0.0))
		farben.append(farbe)

	## Immer mit der Oberseite nach vorn (Godot: im Uhrzeigersinn von oben
	## gesehen). Sonst dreht der Shader bei beidseitigen Flächen die Normale
	## nach unten, und die Sonne erreicht das Wasser nicht.
	func dreieck(a: int, b: int, c: int) -> void:
		var n := (punkte[b] - punkte[a]).cross(punkte[c] - punkte[a])
		if n.y > 0.0:
			indizes.append_array(PackedInt32Array([a, c, b]))
		else:
			indizes.append_array(PackedInt32Array([a, b, c]))

	func viereck(a: int, b: int, c: int, d: int) -> void:
		dreieck(a, b, c)
		dreieck(a, c, d)

	func fertig() -> ArrayMesh:
		var netz := ArrayMesh.new()
		if indizes.is_empty():
			return netz
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = punkte
		var normalen := PackedVector3Array()
		normalen.resize(punkte.size())
		normalen.fill(Vector3.UP)
		arrays[Mesh.ARRAY_NORMAL] = normalen
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_TEX_UV2] = uv2
		arrays[Mesh.ARRAY_COLOR] = farben
		arrays[Mesh.ARRAY_INDEX] = indizes
		netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return netz
