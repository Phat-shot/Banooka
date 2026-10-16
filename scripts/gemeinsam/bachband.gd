extends RefCounted
class_name Bachband
## Fließendes Wasser als EIN Band über die Läufe eines Bettes – dunkel,
## mit treibendem Schaum, Schaumsaum am Ufer, spiegelt den Horizont
## (Baukasten Raum 1, Paket G3; Herkunft scenes/levels/level01/wasser.gd,
## `L01Wasser`: Band :308-523, Stoff :568-584, Shader :111-230).
##
## WIE. Jeder Lauf ist eine Linie aus Spiegelpunkten (x, Wasserspiegel, z)
## mit einer Breite je Punkt. Das Band folgt den geraden Stücken mit fünf
## Punkten quer (Ränder, Viertel, Mitte); jede Seite reicht bis an das
## GEZEICHNETE Ufer (`optionen["hoehe"]`, meist `GelaendeFeld.hoehe_bei`)
## und ein Stück hinein – nie in die Senke dahinter. Ohne Ufer in Reichweite
## reicht es `UFER_ZUGABE` über die halbe Breite hinaus. Wo ein Lauf
## beginnt, schließt er rund (Halbkreis bis ans Ufer), am Ende ebenso oder
## er blendet aus (`auslauf`, für den Übergang in einen Fall).
## Schaum und Tempo kommen aus dem Gefälle des Spiegels.
##
## Rechenweg wörtlich wie Level 01 – mit derselben Höhenfunktion liefern
## `_lauf_abtasten`, `_band_schreiben` und `_kappe` bis aufs Bit dieselben
## Netzdaten (`werkzeuge/baukastenprobe.gd`). Was Level 01 nach dem Namen
## des Laufs entschied ("bach" schließt am Ende rund, alle anderen blenden
## aus), steht hier als Eintrag am Lauf.
##
## TÖDLICH ist das Band nicht und es hat keine Kollision: Wer es tödlich
## braucht, legt eine `todeszone()` auf feste Höhe darunter (Entwurf L05
## Nr. 23).
##
## KOSTEN: ein Netz, ein Zeichenaufruf, ohne Schatten; der Shader liest kein
## Bildschirm- und kein Tiefenbild (gl_compatibility).

const BACH_SHADER := preload("res://shaders/bach.gdshader")

## Ohne gezeichnetes Ufer in Reichweite reicht das Band so weit über die
## halbe Bettbreite hinaus.
const UFER_ZUGABE := 0.6
## Abtastweite des Bandes längs (m).
const SCHRITT := 1.2
## Auf so vielen Metern blendet ein Lauf am Feldrand aus.
const AUSBLENDEN := 10.0

## Farben (wie wasser.gd:91-95): tief, hell, Schaum, gespiegelter Himmel –
## dunkel und grün wie ein Waldbach.
const FARBE_TIEF := Color(0.07, 0.13, 0.12)
const FARBE_HELL := Color(0.16, 0.25, 0.22)
const FARBE_SCHAUM := Color(0.84, 0.91, 0.92)
const HIMMEL_FARBE := Color(0.70, 0.80, 0.84)
const GLITZER := 1.0
## Wellen: flach und fein.
const WELLEN_HOEHE := 0.05


## Baut das Band aller Läufe unter `eltern` (Knoten "Bach") und gibt es
## zurück. `laeufe`: [{
##   "name": String,
##   "punkte": PackedVector3Array (x, Wasserspiegel, z),
##   "breite": PackedFloat32Array (Wasserbreite je Punkt),
##   "anfang_rund": bool (true) – Halbkreis am Anfang,
##   "ende_rund": bool (true) – Halbkreis am Ende (nur, wenn der Lauf ganz
##                im Feld liegt),
##   "auslauf": float (0) – auf so vielen Metern vor dem Ende ausblenden
##                (Level 01: 1,6 m, wo ein Lauf in ein Fallband übergeht)
## }]. `stoff` aus `stoff()`. `optionen`:
##   "hoehe"  Callable(x: float, z: float) -> float: gezeichnetes Ufer
##            (NAN = keines). Leer: überall die Sollbreite plus Zugabe
##   "feld"   Rect2 in Welt-XZ: Ein Lauf endet am ersten Punkt außerhalb und
##            blendet auf `AUSBLENDEN` m zum Rand hin aus. Leer: kein Rand
static func bauen(eltern: Node3D, laeufe: Array, stoff_: ShaderMaterial,
		optionen: Dictionary = {}) -> MeshInstance3D:
	var hoehe: Callable = optionen.get("hoehe", Callable())
	var feld: Rect2 = optionen.get("feld", Rect2())
	var mit_feld := optionen.has("feld")
	var netz := Netz.new()
	for lauf: Dictionary in laeufe:
		var punkte: PackedVector3Array = lauf["punkte"]
		var breiten: PackedFloat32Array = lauf["breite"]
		var bis := punkte.size()
		if mit_feld:
			for i in punkte.size():
				if not feld.has_point(Vector2(punkte[i].x, punkte[i].z)):
					bis = i
					break
		if bis < 2:
			continue
		var zeile := _lauf_abtasten(punkte, breiten, bis, feld)
		var auslauf := float(lauf.get("auslauf", 0.0))
		if auslauf > 0.0:
			var ende: float = zeile[zeile.size() - 1]["laengs"]
			for st in zeile:
				st["sicht"] = minf(float(st["sicht"]),
						clampf((ende - float(st["laengs"])) / auslauf, 0.0, 1.0))
		if bool(lauf.get("anfang_rund", true)):
			_kappe(netz, zeile, true, hoehe)
		_band_schreiben(netz, zeile, hoehe)
		if bool(lauf.get("ende_rund", true)) and bis == punkte.size():
			_kappe(netz, zeile, false, hoehe)
	var knoten := MeshInstance3D.new()
	knoten.name = "Bach"
	knoten.mesh = netz.fertig()
	knoten.material_override = stoff_
	knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	knoten.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Die Wellen heben die Fläche um bis zu 0,05 m
	knoten.extra_cull_margin = 0.5
	eltern.add_child(knoten)
	return knoten


## Der Stoff des Bandes. Thema (alles freiwillig, Vorgabe Level 01):
## "farbe_tief", "farbe_hell", "farbe_schaum", "himmel_farbe" (Color),
## "glitzer" (im Handyweg immer 0), "wellen_hoehe", "rauschen" und
## "stroemung" (Texturen: fein für Wellen und Glitzern, grob für den
## Schaum), "uniforms" {Name: Wert}. Je Aufruf ein neuer Stoff.
static func stoff(thema: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = BACH_SHADER
	m.set_shader_parameter("farbe_tief", thema.get("farbe_tief", FARBE_TIEF))
	m.set_shader_parameter("farbe_hell", thema.get("farbe_hell", FARBE_HELL))
	m.set_shader_parameter("farbe_schaum", thema.get("farbe_schaum", FARBE_SCHAUM))
	m.set_shader_parameter("himmel_farbe", thema.get("himmel_farbe", HIMMEL_FARBE))
	# Im Web ohne Glitzern: zwei Texturzugriffe weniger je Bildpunkt auf
	# einer großen durchsichtigen Fläche.
	m.set_shader_parameter("glitzer", 0.0 if Effekte.reduziert
			else float(thema.get("glitzer", GLITZER)))
	m.set_shader_parameter("wellen_hoehe", float(thema.get("wellen_hoehe", WELLEN_HOEHE)))
	var fein: Texture2D = thema["rauschen"] if thema.has("rauschen") \
			else Materialbibliothek.rauschtextur(1313, 0.9, Color.BLACK, Color.WHITE, 128)
	var grob: Texture2D = thema["stroemung"] if thema.has("stroemung") \
			else Materialbibliothek.rauschtextur(4711, 0.045, Color.BLACK, Color.WHITE, 256)
	m.set_shader_parameter("rauschen", fein)
	m.set_shader_parameter("stroemung", grob)
	var uniforms: Dictionary = thema.get("uniforms", {})
	for name: String in uniforms:
		m.set_shader_parameter(name, uniforms[name])
	return m


# ================================================================ Band

## Tastet einen Lauf ab: je Stelle {"p": Welt (Spiegel), "halb": halbe
## Breite, "laengs": Laufmeter, "tempo", "wild", "sicht"}. Die Stellen
## liegen auf den geraden Stücken des Bettes, höchstens `SCHRITT`
## auseinander, die Ecken inbegriffen. Endet der Lauf vor seinem letzten
## Punkt (`bis` < Punktzahl: am Feldrand), blendet er zu `feld` hin aus.
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


## Das Band: fünf Punkte quer, damit der Uferabstand in COLOR.b linear
## bleibt. Jede Seite reicht bis an das wirkliche Ufer (`_ufer`), über die
## Nachbarn geglättet, nie mehr als 0,3 m über das eigene hinaus.
static func _band_schreiben(netz: Netz, zeile: Array[Dictionary], hoehe: Callable) -> void:
	const QUER: Array[float] = [-1.0, -0.5, 0.0, 0.5, 1.0]
	var roh: Array[PackedVector2Array] = []
	for i in zeile.size():
		var st: Dictionary = zeile[i]
		var p: Vector3 = st["p"]
		var halb: float = st["halb"]
		var rechts := _richtung(zeile, i).cross(Vector3.UP).normalized()
		roh.append(PackedVector2Array([_ufer(p, -rechts, halb, hoehe),
				_ufer(p, rechts, halb, hoehe)]))
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
## gezeichnete Gelände über den Spiegel tritt, dann noch ein Stück in die
## Böschung, solange sie über dem Spiegel bleibt. Rückgabe: (Kante des
## Bandes, Uferlinie). Ohne Gelände dort: die Sollbreite samt Zugabe.
static func _ufer(p: Vector3, richtung: Vector3, halb: float, hoehe: Callable) -> Vector2:
	var d := halb * 0.4
	var bis := halb + UFER_ZUGABE + 2.0
	while d <= bis:
		if _ueber_wasser(p + richtung * d, p.y, hoehe):
			var kante := d
			for k in 3:
				var weiter := d + 0.15 * float(k + 1)
				if not _ueber_wasser(p + richtung * weiter, p.y, hoehe):
					break
				kante = weiter
			return Vector2(kante, maxf(d, 0.5))
		d += 0.25
	return Vector2(halb + UFER_ZUGABE, halb)


static func _ueber_wasser(ort: Vector3, spiegel: float, hoehe: Callable) -> bool:
	if not hoehe.is_valid():
		return false
	var h: float = hoehe.call(ort.x, ort.z)
	return not is_nan(h) and h > spiegel + 0.04


## Runder Abschluss am Anfang (`anfang`) oder Ende eines Laufs: ein Halb-
## kreis um den ersten bzw. letzten Punkt, jeder Strahl bis ans Ufer.
static func _kappe(netz: Netz, zeile: Array[Dictionary], anfang: bool, hoehe: Callable) -> void:
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
		var ufer := _ufer(p, r, halb, hoehe)
		for stufe: float in [0.5, 1.0]:
			var d := r * ufer.x * stufe
			netz.punkt(p + d, Vector2(d.dot(rechts), laengs + d.dot(vor)), float(st["tempo"]),
					Color(float(st["wild"]), float(st["sicht"]), ufer.x * stufe / ufer.y))
	for k in TEILE:
		var a := mitte + 1 + k * 2
		var b := mitte + 1 + (k + 1) * 2
		netz.dreieck(mitte, a, b)
		netz.viereck(a, a + 1, b + 1, b)


## Die Netzdaten des Bandes (wie wasser.gd:959-1003): UV = (quer, längs) in
## Metern, UV2.x = Tempo, COLOR = (Schnelle, Sichtbarkeit, Uferabstand).
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
