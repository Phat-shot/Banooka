extends RefCounted
class_name GelaendeBau
## Rahmen für ein Gelände aus `GelaendeFeld`: Bauschritte mit Bauspeicher,
## Stoff je Thema und Nebeltafeln über Wasser (Baukasten Raum 1, Paket G3;
## Herkunft scenes/levels/level01/gelaende.gd:215-253, 263-295, 405-506).
##
## WARUM. Ein Höhenfeld zu triangulieren kostet in Level 01 acht Schritte
## und gut eine Sekunde; aus dem `Bauspeicher` geladen ist es ein Schritt.
## Dieser Rahmen trennt das Muster von Level 01 (vermessen, je Stück
## triangulieren, Farbe und Netze, ablegen – oder alles laden) von dem, was
## jedes Level selbst hat: seinem Höhenmodell. Das Level gibt nur das
## konfigurierte `GelaendeFeld` (Höhe, Abstand, Färbung als Callables)
## herein, der Rahmen macht daraus die Schritte. Level 01 bleibt bei seinem
## eigenen Modul.
##
## SCHLÜSSEL im Bauspeicher: "<lNN>_gelaende_<voll|handy>" (`schluessel()`),
## damit ein Feld, das vom Handyweg abhängt, nie das andere lädt. Den Code
## deckt der Fingerabdruck des Speichers ab (bauspeicher.gd:35-49).
##
## STOFF. `stoff(thema)` ist der Geländestoff (`shaders/gelaende.gdshader`)
## mit den Texturen eines Themas; mit leerem Thema dieselben Uniforms wie
## `L01Gelaende._stoff()` (geprüft in `werkzeuge/baukastenprobe.gd`), aber
## ein eigenes Objekt je Aufruf: Der Zustand gehört dem Level.
##
## NEBELTAFELN. `nebeltafeln()` baut Dunst über einem Wasser als EIN Netz
## (ein Zeichenaufruf) mit dem Shader `shaders/nebeltafel.gdshader`, einer
## wörtlichen Abschrift von `L01Gelaende.NEBEL_SHADER_CODE`. Der Stoff ist
## eigen je Aufruf; der `Stimmungsregler` (Option "nebeltafeln") setzt
## darin "farbe" nach dem Nebellicht.

const GELAENDE_SHADER := preload("res://shaders/gelaende.gdshader")
const NEBEL_SHADER := preload("res://shaders/nebeltafel.gdshader")

## Deckkraft in der Mitte einer Nebeltafel und wie nah an der Kamera sie
## ausgeblendet ist (von, bis in Metern) – wie gelaende.gd:205-206.
const NEBEL_STAERKE := 0.26
const NEBEL_NAH := Vector2(7.0, 20.0)


## Schlüssel eines Geländes im Bauspeicher: `praefix` (Level, z. B. "l05")
## + "_gelaende_" + Fassung (voll oder Handyweg).
static func schluessel(praefix: String) -> String:
	return praefix + "_gelaende_" + ("handy" if Effekte.reduziert else "voll")


## Die Bauschritte eines Geländes, je {"text", "tun"}.
##   eltern      Knoten, unter dem der Sammelknoten (Name = `text`) entsteht
##   schluessel  im Bauspeicher ("" = nicht speichern), siehe `schluessel()`
##   feld_bauen  Callable() -> GelaendeFeld: legt das Feld an und setzt
##               `bereich`, `stuecke`, `hoehe`, `abstand`, `faerben`,
##               `zusatz` (`zusatz2`). Wird SOFORT gerufen – also nur Felder
##               setzen; wer das Feld später abfragt (`hoehe_bei`), merkt es
##               sich hier
##   stoff       Stoff der Stücke (`stoff(thema)`)
##   text        Text der Schritte und Name des Sammelknotens
##   vorbereiten Callable(feld) -> void, im ersten Schritt vor `punkte_
##               setzen()`: die teure Vorarbeit (`kanten`, `beigaben`)
## Ist der Bau schon im Speicher, wird daraus EIN Schritt ("… wird geladen"),
## der Höhenraster und Netze übernimmt; `vorbereiten` läuft dann nicht.
static func schritte(eltern: Node3D, schluessel_: String, feld_bauen: Callable,
		stoff_: Material, text: String = "Gelände",
		vorbereiten: Callable = Callable()) -> Array:
	var feld: GelaendeFeld = feld_bauen.call()
	if not schluessel_.is_empty():
		var gesichert: Variant = Bauspeicher.gespeichert(schluessel_)
		if gesichert is Dictionary:
			var d: Dictionary = gesichert
			return [{"text": text + " wird geladen", "tun": func() -> void:
					_aus_speicher(eltern, feld, stoff_, text, d)}]
	var schritte_: Array = [{"text": text + " wird vermessen", "tun": func() -> void:
		if vorbereiten.is_valid():
			vorbereiten.call(feld)
		feld.punkte_setzen()}]
	for s in feld.anzahl():
		var nummer := s
		schritte_.append({"text": "%s: Hänge (%d/%d)" % [text, s + 1, feld.anzahl()],
				"tun": func() -> void: feld.stueck_triangulieren(nummer)})
	schritte_.append({"text": text + " bekommt Farbe", "tun": func() -> void:
		_netze_bauen(eltern, feld, stoff_, text, schluessel_)})
	return schritte_


## Gelände aus dem Bauspeicher: Höhenraster übernehmen, Netze einhängen
## (wie gelaende.gd:412-418).
static func _aus_speicher(eltern: Node3D, feld: GelaendeFeld, stoff_: Material, text: String,
		d: Dictionary) -> void:
	feld.stoff = stoff_
	feld.zustand_setzen(d["feld"])
	var netze: Array[ArrayMesh] = []
	netze.assign(d["netze"])
	feld.knoten_bauen(eltern, netze, text)


## Normalen, Mulden, Netze; einhängen und ablegen (wie gelaende.gd:421-433).
static func _netze_bauen(eltern: Node3D, feld: GelaendeFeld, stoff_: Material, text: String,
		schluessel_: String) -> void:
	feld.stoff = stoff_
	feld.normalen_rechnen()
	var mulden := feld.mulden_rechnen()
	var netze: Array[ArrayMesh] = []
	for s in feld.anzahl():
		netze.append(feld.stueck_netz(s, mulden))
	feld.knoten_bauen(eltern, netze, text)
	if not schluessel_.is_empty():
		Bauspeicher.ablegen(schluessel_, {"feld": feld.zustand(), "netze": netze})


## Der Geländestoff für ein Thema (jeder Schlüssel freiwillig, ohne Angabe
## der Wert von Level 01): "waldboden", "fels", "erde" (Texturen; Erde ist
## der Schlamm an Wasser und Gruben), "rasen" (Textur für `wald_rasen`, die
## Wiese; null = die der Wegmaske), "rasen_kachel", "uniforms" {Name: Wert}
## für Töne und Kacheln. Je Aufruf ein neuer Stoff.
static func stoff(thema: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GELAENDE_SHADER
	Wegmaske.einrichten(m)
	var waldboden: Texture2D = thema["waldboden"] if thema.has("waldboden") \
			else Materialbibliothek.waldboden().albedo_texture
	var fels: Texture2D = thema["fels"] if thema.has("fels") \
			else Materialbibliothek.fels().albedo_texture
	var erde: Texture2D = thema["erde"] if thema.has("erde") \
			else Materialbibliothek.waldweg().albedo_texture
	m.set_shader_parameter("waldboden", waldboden)
	m.set_shader_parameter("fels", fels)
	m.set_shader_parameter("erde", erde)
	if thema.get("rasen") != null:
		m.set_shader_parameter("wald_rasen", thema["rasen"])
	if thema.has("rasen_kachel"):
		m.set_shader_parameter("wald_rasen_kachel", float(thema["rasen_kachel"]))
	var uniforms: Dictionary = thema.get("uniforms", {})
	for name: String in uniforms:
		m.set_shader_parameter(name, uniforms[name])
	return m


## Nebeltafeln als EIN Netz unter `eltern` (Knoten "Nebeltafeln"), ohne
## Schatten. `tafeln`: [{"mitte": Vector3, "mass": Vector2 (Breite, Höhe),
## "phase": 0..1, "kraft": 0..1}]. `farbe` ist das Nebellicht (meist das der
## Umgebung, etwas heller: Der Dunst über dem Wasser steht vor dem Talnebel,
## nicht in einer anderen Farbe). Rückgabe: der eigene Stoff der Tafeln
## (null ohne Tafeln) – darin "farbe", "staerke", "nah".
## Bau wie gelaende.gd:439-500.
static func nebeltafeln(eltern: Node3D, tafeln: Array, farbe: Color) -> ShaderMaterial:
	if tafeln.is_empty():
		return null
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
	var stoff_ := ShaderMaterial.new()
	stoff_.shader = NEBEL_SHADER
	stoff_.render_priority = 1
	stoff_.set_shader_parameter("farbe", farbe)
	stoff_.set_shader_parameter("staerke", NEBEL_STAERKE)
	stoff_.set_shader_parameter("nah", NEBEL_NAH)
	var knoten := MeshInstance3D.new()
	knoten.name = "Nebeltafeln"
	knoten.mesh = netz
	knoten.material_override = stoff_
	knoten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	knoten.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	eltern.add_child(knoten)
	return stoff_
