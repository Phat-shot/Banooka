extends Node
class_name Wegmaskenprobe
## Probe: Rechnen CPU (`scripts/wegmaske.gd`) und GPU
## (`shaders/wald_gemeinsam.gdshaderinc`) dieselbe Wegmaske?
##
## Saum, Gelände und Rasen setzen ihre Nähte und Halmfüße nach der CPU-
## Maske, der Weg malt nach der GPU-Maske – nur wenn beide gleich rechnen,
## wachsen die Halme aus dem Boden statt daneben. Plan P3: an 20 Punkten
## höchstens 0,02 Abweichung.
##
## Zwei Teile:
## * IMMER (auch ohne Bildschirm, `pruefe.sh`): Die Konstanten im Include
##   werden gelesen und mit denen in `Wegmaske` verglichen, und das Bild,
##   das die GPU bekommt, muss Byte für Byte das sein, das die CPU liest.
## * MIT BILDSCHIRM (`bash werkzeuge/wegmaskenprobe.sh`, `pruefe.sh` über
##   xvfb-run): Eine waagerechte Testebene (24 × 24 m) wird senkrecht von
##   oben mit einer Orthokamera in einen SubViewport (256²) gezeichnet,
##   unbeleuchtet: R = Maske, G = Makro, B = Kronenlicht zur Zeit T, in die
##   Mitte des Wertebereichs gelegt (0,2 + 0,6 · Wert). Ein Eichstreifen mit
##   bekannten Werten rechnet das Auslesen (sRGB/linear, Rundung) zurück.
##   Dann werden 20 Bildpunkte mit `Wegmaske.wert/makro/kronenlicht`
##   verglichen, bevorzugt dort, wo die Maske weder 0 noch 1 ist.
## Ausgabe endet mit "=== Wegmaske: … ===" und "ERGEBNIS: GUT" oder
## "ERGEBNIS: ABWEICHUNG".

const INCLUDE := "res://shaders/wald_gemeinsam.gdshaderinc"
const KANTE := 256
const FELD := 24.0
const MITTE := Vector2(37.3, -61.7)
const HALB := 4.6
const S_NULL := 83.0
const T := 7.3
const GRENZE := 0.02

const PROBE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://shaders/wald_gemeinsam.gdshaderinc"
uniform vec2 mitte;
uniform float halb;
uniform float s_null;
uniform float zeit;
uniform int eich = 0;
varying vec3 v_welt;
void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	if (eich == 1) {
		ALBEDO = vec3(UV.x, 1.0 - UV.x, 0.5);
	} else {
		float q = (v_welt.x - mitte.x) / halb;
		float s = s_null + (mitte.y - v_welt.z);
		float m = wegmaske(q, s, v_welt.xz);
		float mk = (makro(v_welt.xz) - 0.82) / 0.3;
		float kl = kronenlicht(v_welt.xz, zeit);
		ALBEDO = 0.2 + 0.6 * vec3(m, mk, kl);
	}
}
"""

var _fehler := 0
var _vp: SubViewport
var _eich := PackedFloat32Array()


func _ready() -> void:
	print("=== Wegmaskenprobe ===")
	for zeile in ohne_bild():
		print("  " + zeile)
		if zeile.begins_with("ABWEICHUNG"):
			_fehler += 1
	if DisplayServer.get_name() == "headless":
		print("  GPU-Abgleich: entfällt ohne Bildschirm (bash werkzeuge/wegmaskenprobe.sh)")
		print("=== Wegmaske: %d Abweichungen ===" % _fehler)
		print("ERGEBNIS: %s" % ("GUT" if _fehler == 0 else "ABWEICHUNG"))
		get_tree().quit(1 if _fehler > 0 else 0)
		return
	await _gpu_abgleich()
	print("ERGEBNIS: %s" % ("GUT" if _fehler == 0 else "ABWEICHUNG"))
	get_tree().quit(1 if _fehler > 0 else 0)


## Der Teil ohne Bildschirm: Konstanten und Weltrauschen. Zeilen, die mit
## "ABWEICHUNG" beginnen, sind Fehler. Auch `level_check` ruft das auf, wenn
## ein Level `"wegmaske": true` im `pruefprofil()` meldet.
static func ohne_bild() -> Array[String]:
	var zeilen: Array[String] = []
	_konstanten_pruefen(zeilen)
	_bild_pruefen(zeilen)
	return zeilen


## Die Konstanten des Includes gegen die der CPU-Maske.
static func _konstanten_pruefen(zeilen: Array[String]) -> void:
	var text := FileAccess.get_file_as_string(INCLUDE)
	if text.is_empty():
		zeilen.append("ABWEICHUNG  %s nicht lesbar" % INCLUDE)
		return
	var paare := {
		"WALD_MASKE_VON": Wegmaske.MASKE_VON, "WALD_MASKE_BIS": Wegmaske.MASKE_BIS,
		"WALD_MASKE_RAUSCHEN": Wegmaske.MASKE_RAUSCHEN, "WALD_MASKE_WELLE": Wegmaske.MASKE_WELLE,
		"WALD_PENDEL_A": Wegmaske.PENDEL_A, "WALD_PENDEL_B": Wegmaske.PENDEL_B,
		"WALD_RAND_VON": Wegmaske.RAND_VON, "WALD_RAND_BIS": Wegmaske.RAND_BIS,
		"WALD_MAKRO_TIEF": Wegmaske.MAKRO_TIEF, "WALD_MAKRO_HOCH": Wegmaske.MAKRO_HOCH,
		"WALD_KRONEN_FEIN": Wegmaske.KRONEN_FEIN,
	}
	var geprueft := 0
	for name: String in paare:
		var werte := _werte_aus(text, name)
		if werte.size() != 1:
			zeilen.append("ABWEICHUNG  Konstante %s im Include nicht gefunden" % name)
			continue
		geprueft += 1
		if not is_equal_approx(werte[0], float(paare[name])):
			zeilen.append("ABWEICHUNG  %s: Include %s, CPU %s" % [name, werte[0], paare[name]])
	for eintrag: Array in [["WALD_TROCKEN_TON", [Wegmaske.TROCKEN_TON.x, Wegmaske.TROCKEN_TON.y,
			Wegmaske.TROCKEN_TON.z]], ["WALD_KRONEN_DRIFT", [Wegmaske.KRONEN_DRIFT.x,
			Wegmaske.KRONEN_DRIFT.y]]]:
		var name: String = eintrag[0]
		var soll: Array = eintrag[1]
		var werte := _werte_aus(text, name)
		geprueft += 1
		if werte.size() != soll.size():
			zeilen.append("ABWEICHUNG  Konstante %s im Include nicht gefunden" % name)
			continue
		for k in soll.size():
			if not is_equal_approx(werte[k], float(soll[k])):
				zeilen.append("ABWEICHUNG  %s[%d]: Include %s, CPU %s" % [name, k, werte[k], soll[k]])
	# Die Kacheln: Vorgaben der Uniforms gegen die CPU (die GPU bekommt sie
	# von `Wegmaske.einrichten`, aber ein Stoff ohne den Aufruf nähme diese).
	for eintrag: Array in [["wald_kachel", Wegmaske.KACHEL], ["wald_rasen_kachel",
			Wegmaske.RASEN_KACHEL]]:
		var werte := _werte_aus(text, String(eintrag[0]))
		geprueft += 1
		if werte.size() != 1 or absf(werte[0] - float(eintrag[1])) > 0.0001:
			zeilen.append("ABWEICHUNG  Vorgabe %s: Include %s, CPU %s" % [eintrag[0], werte, eintrag[1]])
	zeilen.append("Konstanten: %d geprüft" % geprueft)


## Zahlen hinter `name =` bis zum Semikolon (Skalar oder vecN(…)).
static func _werte_aus(text: String, name: String) -> PackedFloat32Array:
	var werte := PackedFloat32Array()
	var ausdruck := RegEx.create_from_string("\\b" + name + "\\s*=\\s*([^;]+);")
	var treffer := ausdruck.search(text)
	if treffer == null:
		return werte
	var zahlen := RegEx.create_from_string("-?[0-9]+(\\.[0-9]+)?")
	for z in zahlen.search_all(treffer.get_string(1).replace("vec2", "").replace("vec3", "")):
		werte.append(float(z.get_string()))
	return werte


## Bekommt die GPU genau das Bild, das die CPU liest?
static func _bild_pruefen(zeilen: Array[String]) -> void:
	var cpu := Wegmaske.bild()
	var gpu := Wegmaske.textur().get_image()
	if cpu == null:
		zeilen.append("ABWEICHUNG  Weltrauschen fehlt")
		return
	if gpu == null:
		# Der Kopflos-Betrieb hält keine Texturdaten vor.
		zeilen.append("Weltrauschen: GPU-Bild hier nicht auslesbar")
		return
	var roh := gpu.duplicate() as Image
	roh.clear_mipmaps()
	if roh.get_format() != cpu.get_format():
		roh.convert(cpu.get_format())
	if roh.get_data() != cpu.get_data():
		zeilen.append("ABWEICHUNG  Das Weltrauschen der GPU weicht vom Bild der CPU ab")
	else:
		zeilen.append("Weltrauschen: GPU-Bild gleich dem CPU-Bild (%d Bytes)" % cpu.get_data().size())


func _gpu_abgleich() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(KANTE, KANTE + 32)
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	_vp.use_debanding = false
	add_child(_vp)
	var welt := Node3D.new()
	_vp.add_child(welt)
	var umgebung := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.glow_enabled = false
	env.fog_enabled = false
	umgebung.environment = env
	welt.add_child(umgebung)

	var shader := Shader.new()
	shader.code = PROBE_SHADER
	var stoff := ShaderMaterial.new()
	stoff.shader = shader
	Wegmaske.einrichten(stoff)
	stoff.set_shader_parameter("mitte", MITTE)
	stoff.set_shader_parameter("halb", HALB)
	stoff.set_shader_parameter("s_null", S_NULL)
	stoff.set_shader_parameter("zeit", T)
	var ebene := MeshInstance3D.new()
	var netz := PlaneMesh.new()
	netz.size = Vector2(FELD, FELD)
	ebene.mesh = netz
	ebene.material_override = stoff
	ebene.position = Vector3(MITTE.x, 0.0, MITTE.y)
	welt.add_child(ebene)
	# Eichstreifen unterhalb (Bildzeilen 256..287)
	var eich := stoff.duplicate() as ShaderMaterial
	eich.set_shader_parameter("eich", 1)
	var streifen := MeshInstance3D.new()
	var sn := PlaneMesh.new()
	sn.size = Vector2(FELD, FELD * 32.0 / float(KANTE))
	streifen.mesh = sn
	streifen.material_override = eich
	streifen.position = Vector3(MITTE.x, 0.0, MITTE.y + FELD * 0.5 + sn.size.y * 0.5)
	welt.add_child(streifen)

	var kamera := Camera3D.new()
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.size = FELD * float(KANTE + 32) / float(KANTE)
	kamera.near = 0.1
	kamera.far = 100.0
	# Senkrecht nach unten; Bild oben = −Z (Norden)
	kamera.position = Vector3(MITTE.x, 20.0, MITTE.y + FELD * 16.0 / float(KANTE))
	kamera.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	welt.add_child(kamera)
	kamera.current = true
	for i in 8:
		await get_tree().process_frame
	var bild := _vp.get_texture().get_image()
	bild.convert(Image.FORMAT_RGBA8)
	_eich.clear()
	for x in KANTE:
		_eich.append(bild.get_pixel(x, KANTE + 16).r)
	# Wie weit das rohe Auslesen danebenliegt (nur zur Auskunft – der
	# Abgleich rechnet über den Streifen zurück).
	var eich_fehler := 0.0
	for k in 9:
		var x := 16 + k * 28
		var soll := (float(x) + 0.5) / float(KANTE)
		eich_fehler = maxf(eich_fehler, absf(bild.get_pixel(x, KANTE + 16).r - soll))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var max_m := 0.0
	var max_mk := 0.0
	var max_kl := 0.0
	var punkte := 0
	var versuche := 0
	while punkte < 20 and versuche < 5000:
		versuche += 1
		var px := rng.randi_range(4, KANTE - 5)
		var py := rng.randi_range(4, KANTE - 5)
		var wxz := Vector2(MITTE.x - FELD * 0.5 + (float(px) + 0.5) * FELD / float(KANTE),
				MITTE.y - FELD * 0.5 + (float(py) + 0.5) * FELD / float(KANTE))
		var q := (wxz.x - MITTE.x) / HALB
		var s := S_NULL + (MITTE.y - wxz.y)
		var cpu := Wegmaske.wert(q, s, wxz)
		if punkte < 14 and (cpu < 0.05 or cpu > 0.95):
			continue
		var c := bild.get_pixel(px, py)
		max_m = maxf(max_m, absf(cpu - _lin(c.r)))
		max_mk = maxf(max_mk, absf((Wegmaske.makro(wxz) - 0.82) / 0.3 - _lin(c.g)))
		max_kl = maxf(max_kl, absf(Wegmaske.kronenlicht(wxz, T) - _lin(c.b)))
		punkte += 1
	print("  GPU-Abgleich: %d Punkte, größte Abweichung Maske %.4f (Grenze %.2f), Makro %.4f, Kronenlicht %.4f; Eichung %.4f"
			% [punkte, max_m, GRENZE, max_mk, max_kl, eich_fehler])
	if punkte < 20 or max_m > GRENZE or max_mk > GRENZE * 2.0 or max_kl > GRENZE * 2.0:
		print("  ABWEICHUNG  CPU- und GPU-Maske rechnen verschieden")
		_fehler += 1
	print("=== Wegmaske: %d Abweichungen ===" % _fehler)


## Ausgelesener Wert → Wert im Shader: über den Eichstreifen zurückgerechnet
## (roh → wahr), dann aus der Mitte des Wertebereichs zurückgeholt.
func _lin(v: float) -> float:
	var wahr := v
	for i in range(1, _eich.size()):
		if _eich[i] >= v:
			var a := _eich[i - 1]
			var b := _eich[i]
			var t := 0.0 if b <= a else (v - a) / (b - a)
			wahr = (float(i - 1) + 0.5 + t) / float(KANTE)
			break
	return (wahr - 0.2) / 0.6
