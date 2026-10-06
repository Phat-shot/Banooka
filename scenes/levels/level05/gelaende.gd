extends RefCounted
class_name L05Gelaende
## Level 05, Modul „Gelände": der Hauerhang als Höhenfeld ohne Kollision
## (Entwurf §9.1) – Kuppe, Suhle, Hohlwegkrone, Terrassenhang, Tobelmulde,
## Mühlwiese, die Talhänge und ein grober Ring bis zur Weltkante.
##
## WAS HIER ENTSTEHT (Seiten wie im Rückblick: q < 0 bildrechts, q > 0
## bildlinks):
## * Talboden: die geglättete Decke (`Level05.decke_glatt`); das Tal fällt
##   mit dem Weg von 26 auf 2 m.
## * Kuppe: um s −6 (`Level05.EICHE`) r 40 m, 3 m hoch, Scheitel auf Y 27
##   (Entwurf §8.2); die Eiche steht 3,5 m dahinter auf ihrem Rücken
##   (`L05Eiche`, Kopf: ABWEICHUNGEN). Hinter ihr ein flacher Sattel,
##   dann ein Kamm (SUEDKAMM), der das Tal oben schließt: Ohne ihn zeigte
##   der Himmel vom Start aus unter dem Horizont seine Bodenfarbe (Jury
##   JT10, Weltkante). Er steht vom Start aus 3° über dem Horizont, von unten
##   im Tal 4°, immer unter der Krone der Eiche; dahinter fällt das Land.
##   Weiter weg darf er nicht: `far` ist 380 m (Level05.tscn), und von der
##   letzten Kamera aus liegt sein Grat schon 369 m weit.
## * Westhang (q < 0): ab q −25 steigt er zum Kamm (Entwurf: „Westhang
##   −25 m"), davor eine flache Hangschulter. Im Tobel (D) steht statt der
##   Schulter die Südwand: vom Bett des Baches 11 m hoch, steiler als 60° –
##   Fels nach dem Stoff, Schatten nach der Sonne.
## * Sonnenhang (q > 0): steigt flacher vom Hohlweg zum Kamm.
## * Hohlwegkrone: hinter jeder Böschung des Saums eine Krone auf ihrer
##   Höhe; das Feld liegt bis 1 m hinter der Wandkrone UNTER der Krone des
##   Saums und tritt bis 2,6 m dahinter über sie (Naht vergraben, gleicher
##   Rasen). Unter Decke, Schulter und Wänden liegt es 0,9 m tief, in Lücken
##   unter deren Grund – und schon 1,2 m vor ihren Lippen, hinter der
##   dunklen Flanke der Stirn (LUECKE_HINTER). Keine Mulde gräbt unter diese
##   Krone: Erst hinter ihr fällt das Land, als Kronenrücken (RUECKEN_*).
##   Wo ein Zug an den nächsten übergibt, mischt das Feld beide Formen
##   (`L05Saum.uebergabe`).
## * Ufer und Wehr: hinter einer Wand hinab das Bett (Bach, Teich,
##   Unterwasser) knapp unter dem Fuß des Saums, der sich darunter
##   einsteckt; im Tobel 3 m breit, dann die Südwand.
## * Suhle: neben dem Weg in A (bildrechts) eine schlammige Mulde hinter
##   einem niedrigen Rand. Mühlwiese in E: flache Wiese um Teich (bildlinks)
##   und Unterwasser (bildrechts), das hinter dem Wehr nach Nordwesten
##   abfließt. Hinter dem Ende der Decke (s 300) laufen die Ränder über 3 m
##   in die Wiese aus; die Spur zeichnet dort der Auslauf der Decke
##   (`Level05.auslauf_halb`), das Feld liegt flach knapp unter ihm.
## * Ring: Die Talhänge laufen zu Kämmen (Westen 38 m, Osten 31 m über dem
##   Tal), die nach Süden flacher werden; hinter den Kämmen fällt das Land
##   wieder. Von jeder Kamera aus liegen die sichtbaren Kämme innerhalb von
##   `far` (380 m, Level05.tscn) – Kammpunkte hinter dieser Weite verdeckt
##   der nähere Hang. Dahinter übernimmt der Himmel (Paket P8: Hügel ≥ 4°).
##
## FORM DES WEGES: Was hier unter Saum und Weg liegen muss, rechnet das Feld
## mit denselben Formeln wie der Saum (`L05Saum.form_auf`/`form_ab`) und
## setzt an den Knicken eigene Punktreihen (`GelaendeFeld.kanten`): Ein
## Raster allein träfe die Krone nur auf ±1 m. Die Reihen folgen den Ecken
## der Linien (`_zug_stuecke`) und liegen quer über jeder Lücke und über dem
## Ende der Decke. Geprüft wird das mit einer Nahtprobe (Trimesh auf Feld,
## Saum und Decke, Strahlen von oben über Decke und Schulter, s 0–300):
## nichts vom Feld über der Kollision, kein Loch unter ihr.
##
## BAU über `GelaendeBau.schritte` (Bauspeicher "l05_gelaende_voll" bzw.
## "…_handy"; der Handyweg setzt die Punkte 1,4-mal weiter auseinander).
## Neun Stücke, also höchstens neun Zeichenaufrufe (Entwurf §10: 12), keine
## Schatten.
##
## (s, q) eines Weltpunkts: über die Tabelle der Kurve, die vor dem Anfang
## und hinter dem Ende geradeaus weiterläuft (`projektion`, Newton auf der
## Tangente). Der Weg ist sanft gekrümmt (Radius über 400 m), also ist die
## Projektion im ganzen Feld eindeutig und stetig.

## Das Feld in Welt-XZ und seine Stücke.
const FELD := Rect2(-262.0, -352.0, 524.0, 472.0)
const STUECKE := Vector2i(3, 3)
## Tabelle der Kurve (flach) über s, und wie weit sie vor dem Anfang und
## hinter dem Ende geradeaus reicht.
const S_MIN := -240.0
const S_MAX := 520.0
const S_SCHRITT := 0.5
## Punktabstände: am Weg, bis 40 m, bis 90 m, darüber (m); Handyweg × HANDY.
const ABSTAND_NAH := 1.6
const ABSTAND_MITTE := 3.0
const ABSTAND_WEIT := 6.0
const ABSTAND_FERN := 14.0
const HANDY := 1.4
## So tief liegt das Feld unter Decke, Schulter und Wänden (m).
const UNTER := 0.9
## Krone: von der Wandkrone aus (m) – bis KRONE_UNTEN unter der Krone des
## Saums, ab KRONE_OBEN über ihr (um KRONE_DECKT).
const KRONE_UNTEN := 1.0
const KRONE_OBEN := 2.6
const KRONE_DECKT := 0.3
## Hinter der Krone darf eine Mulde (Teich, Suhle) das Feld erst so weit
## hinter dem Ende der Platte (`L05Saum`, "weit") senken, dann höchstens so
## steil (m je m, gut 31°; siehe `_zug_y`).
const RUECKEN_AB := 0.4
const RUECKEN_NEIGUNG := 0.6
## Bett vor einer Wand hinab: so breit, so tief unter dem Bett des Saums.
const BETT_BREITE := 3.0
const BETT_UNTER := 0.15
## Kuppe um die Eiche: Radius, Höhe über ihrem Fuß.
const KUPPE_R := 40.0
const KUPPE_H := 3.0
## Hinter der Kuppe (m hinter s 0): Sattel (von, bis, 0,6 m tief) und der
## Kamm, der das Tal oben schließt (Anstieg von, bis, Höhe über A). Sein
## Grat liegt bei z ≈ +52: von der letzten Kamera (s 317) 369 m entfernt,
## knapp innerhalb von `far` (380); vom Start aus steht er 3° über dem
## Horizont, von unten im Tal 4° – unter der Krone der Eiche (≥ 6,9°).
const SATTEL := Vector2(14.0, 30.0)
const SUEDKAMM := Vector3(28.0, 52.0, 10.5)
## Am Ende der Decke steigt das Feld auf so vielen Metern bis unter sie;
## dahinter laufen die Ränder auf so vielen Metern in die Wiese aus, und
## quer liegen Punktreihen so weit vor und hinter dem Ende (siehe `_nah`).
const ENDE_RAMPE := 1.2
const ENDE_UEBERGANG := 3.0
const ENDE_REIHE := 0.1
## Hinter dem Ende der Decke bleibt das Feld bis so weit hinter der Leitlinie
## eben auf der Kurve (m; Lippe und Fuß der Ufer, siehe `_nah`).
const ENDE_LIPPE := 0.8
## Unter der Decke vor jeder Lippe liegt das Feld schon so weit wie in der
## Lücke (m): auf ihrem Grund. WARUM: Die Stirn des Saums (`L05Saum`, die
## dunkle Flanke, Entwurf §8.4) steht unter der Narbe 0,4–0,95 m hinter der
## Lippe. Fiel das Feld erst AN der Lippe ab, stand seine Wand vor der Stirn,
## und unter 0,9 m sah man statt der dunklen Flanke den hellen Hang (Fels,
## Moos; gerendert Albedo bis 0,15). Dort quer die Punktreihen, so weit davor
## und dahinter, und so weit zu beiden Seiten (m).
const LUECKE_HINTER := 1.2
const LUECKE_REIHE := 0.12
const LUECKE_QUER := 14.0
## Suhle (A, q < 0): von, bis (s), Anfang hinter der Krone des Saums und
## Mitte (|q|), Tiefe unter der Decke von A.
const SUHLE := Vector4(8.0, 24.0, 10.0, 14.0)
const SUHLE_TIEF := 0.4
## Mühlteich (E, q > 0): Mitte (s, q), Halbachsen, Grund (Welt-Y).
const TEICH := Rect2(284.0, 17.0, 13.0, 11.0)
const TEICH_GRUND := 2.7
## Unterwasser (E, q < 0): Lauf (s, q) und Grund (Welt-Y), Breite (m).
const UNTERWASSER: Array[Vector2] = [Vector2(282.0, -5.0), Vector2(288.0, -9.0),
		Vector2(296.0, -16.0), Vector2(308.0, -21.0), Vector2(330.0, -24.0), Vector2(380.0, -26.0)]
const UNTERWASSER_GRUND := 1.3
const UNTERWASSER_BREITE := 9.0

var level: Level05
## Das Feld (gesetzt mit dem ersten Bauschritt; `hoehe` liest es danach).
var feld: GelaendeFeld
var _anzahl := 0
var _px := PackedFloat32Array()
var _pz := PackedFloat32Array()
var _tx := PackedFloat32Array()
var _tz := PackedFloat32Array()
var _rauschen := FastNoiseLite.new()
var _rauschen_fein := FastNoiseLite.new()
## Zwischenablage für die Abfragen desselben Punkts (Höhe, Farbe, Zusatz).
var _letzt := Vector2(INF, INF)
var _letzt_sq := Vector2.ZERO


## Bauschritte: Das Modell entsteht sofort (der Saum und spätere Pakete lesen
## `hoehe`), das Feld in den Schritten von `GelaendeBau`. Der Stoff geht leer
## hinein und wird im ersten Schritt gefüllt (Level05, Kopf: STOFFE) – auch
## vor „Der Hang wird geladen".
static func bauschritte(level_: Level05) -> Array:
	var g := L05Gelaende.new(level_)
	level_.gelaende = g
	var stoff := ShaderMaterial.new()
	var schritte: Array = [{"text": "Waldboden und Fels für den Hang", "tun": func() -> void:
		stoff_uebertragen(stoff, GelaendeBau.stoff(thema()))}]
	schritte.append_array(GelaendeBau.schritte(level_.geometrie, GelaendeBau.schluessel("l05"),
			g._feld_anlegen, stoff, "Der Hang", g._vorbereiten))
	return schritte


## Shader und alle gesetzten Parameter von `quelle` auf `ziel` – für einen
## Stoff, der schon beim Zusammenstellen der Schritte vergeben ist, aber erst
## in einem Schritt entsteht (Level05, Kopf: STOFFE).
static func stoff_uebertragen(ziel: ShaderMaterial, quelle: ShaderMaterial) -> void:
	ziel.shader = quelle.shader
	for u: Dictionary in quelle.shader.get_shader_uniform_list():
		var name := String(u["name"])
		var wert: Variant = quelle.get_shader_parameter(name)
		if wert != null:
			ziel.set_shader_parameter(name, wert)


## Stoff des Geländes: die Böden von Level 01 (Wiese mit dem Rasen der
## Wegmaske wie Decke und Saum, Waldboden, Fels, Schlamm); der Sandstein der
## Felsbänke etwas röter wie am Sonnenhang des Tobels.
static func thema() -> Dictionary:
	return {"uniforms": {"sandstein_ton": Vector3(1.12, 0.9, 0.72),
			"waldboden_ton": Color(0.42, 0.5, 0.34)}}


func _init(level_: Level05) -> void:
	level = level_
	_rauschen.seed = 5501
	_rauschen.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_rauschen.frequency = 0.012
	_rauschen.fractal_octaves = 3
	_rauschen_fein.seed = 5502
	_rauschen_fein.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_rauschen_fein.frequency = 0.07
	_rauschen_fein.fractal_octaves = 2
	_anzahl = int(round((S_MAX - S_MIN) / S_SCHRITT)) + 1
	for i in _anzahl:
		var s := S_MIN + S_SCHRITT * float(i)
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
		var r := LevelWerkzeuge.punkt_frei(level.verlauf, s, 1.0) - p
		_px.append(p.x)
		_pz.append(p.z)
		# Tangente aus der Rechten: r = t × oben ⇒ t = (r.z, −r.x)
		var t := Vector2(r.z, -r.x).normalized()
		_tx.append(t.x)
		_tz.append(t.y)


# ================================================================ Abfragen

## Gezeichnete Höhe an (x, z) (nach dem Bau), sonst die des Modells.
func hoehe(x: float, z: float) -> float:
	if feld != null and feld.fertig():
		return feld.hoehe_bei(x, z)
	return _hoehe(x, z)


## Was die Kamera an (x, z) höchstens verdeckt: Gelände oder die Krone des
## Saums (für die Freiraumprobe K3, `Level05.freiraumprobe`).
func sicht_oberkante(x: float, z: float) -> float:
	var y := hoehe(x, z)
	var sq := projektion(x, z)
	var seite := -1.0 if sq.y < 0.0 else 1.0
	var u := absf(sq.y)
	for zug: Dictionary in level.zuege_bei(seite, sq.x):
		var l := absf(_linie_q(zug, sq.x))
		if String(zug["art"]) == "auf":
			var m := L05Saum.form_auf(level, zug, sq.x)
			if u >= l - 0.1 and u <= l + float(m["lauf"]) + float(m["weit"]):
				y = maxf(y, float(m["krone"]) + L05Saum.KRONE_STEIGT)
		elif u <= l + 0.5:
			y = maxf(y, level.weg.boden_bei(sq.x))
	return y


## (s, q) eines Weltpunkts (Level-Koordinaten).
##
## Erste Schätzung über z (die Kurve läuft überall nach −Z), dann Newton auf
## der Tangente: höchstens 14 Schritte, Schluss bei einem Schritt unter
## 5 mm, danach Punkt und Tangente an der letzten Stelle. Punkt und Tangente
## stehen hier ausgeschrieben, mit genau den Rechnungen von `_punkt` und
## `_tangente` (dieselben Vector2, also dieselbe Rundung) und einmal je
## Stelle statt zweimal: Die Projektion läuft beim kalten Bau rund 160 000
## Mal (Gelände, Rasen, Wald), zwei Aufrufe je Schritt kosteten dort gut
## ein Drittel ihrer Zeit (Paket P8, Bauzeit). Das Ergebnis ist bitgleich.
func projektion(x: float, z: float) -> Vector2:
	if x == _letzt.x and z == _letzt.y:
		return _letzt_sq
	var lo := 0
	var hi := _anzahl - 1
	while hi - lo > 1:
		var mitte := (lo + hi) >> 1
		if _pz[mitte] > z:
			lo = mitte
		else:
			hi = mitte
	var s := S_MIN + S_SCHRITT * float(lo)
	var letzt := float(_anzahl - 1)
	var i_max := _anzahl - 2
	var c := Vector2.ZERO
	var t := Vector2.ZERO
	var schritte := 0
	var fertig := false
	while true:
		var f := clampf((s - S_MIN) / S_SCHRITT, 0.0, letzt)
		var i := mini(floori(f), i_max)
		var u := f - float(i)
		c = Vector2(lerpf(_px[i], _px[i + 1], u), lerpf(_pz[i], _pz[i + 1], u))
		t = Vector2(lerpf(_tx[i], _tx[i + 1], u), lerpf(_tz[i], _tz[i + 1], u)).normalized()
		if fertig:
			break
		var ds := (x - c.x) * t.x + (z - c.y) * t.y
		s = clampf(s + ds, S_MIN, S_MAX)
		schritte += 1
		fertig = absf(ds) < 0.005 or schritte >= 14
	# Rechts = (−t.z, t.x) (wie LevelWerkzeuge: q > 0 rechts in Laufrichtung)
	var q := (x - c.x) * -t.y + (z - c.y) * t.x
	_letzt = Vector2(x, z)
	_letzt_sq = Vector2(s, q)
	return _letzt_sq


func _punkt(s: float) -> Vector2:
	var f := clampf((s - S_MIN) / S_SCHRITT, 0.0, float(_anzahl - 1))
	var i := mini(floori(f), _anzahl - 2)
	var t := f - float(i)
	return Vector2(lerpf(_px[i], _px[i + 1], t), lerpf(_pz[i], _pz[i + 1], t))


func _tangente(s: float) -> Vector2:
	var f := clampf((s - S_MIN) / S_SCHRITT, 0.0, float(_anzahl - 1))
	var i := mini(floori(f), _anzahl - 2)
	var t := f - float(i)
	return Vector2(lerpf(_tx[i], _tx[i + 1], t), lerpf(_tz[i], _tz[i + 1], t)).normalized()


## Weltpunkt (x, z) zu (s, q).
func _welt(s: float, q: float) -> Vector2:
	var c := _punkt(s)
	var t := _tangente(s)
	return c + Vector2(-t.y, t.x) * q


# ================================================================ Feld

func _feld_anlegen() -> GelaendeFeld:
	feld = GelaendeFeld.new()
	feld.bereich = FELD
	feld.stuecke = STUECKE
	feld.hoehe = _hoehe
	feld.abstand = _abstand
	feld.faerben = _faerben
	feld.zusatz = _zusatz
	feld.zusatz2 = _zusatz2
	return feld


## Erster Bauschritt (vor `punkte_setzen`): Punktreihen an den Knicken unter
## dem Saum (siehe Kopf, FORM DES WEGES).
func _vorbereiten(f: GelaendeFeld) -> void:
	# Quer über das Ende der Decke, knapp davor und dahinter: Dort knickt die
	# Rampe der Wehrkrone (19 %) in die flache Kurve (2,5 %), und eine Sehne
	# über den Knick stand bis 6 cm über der Decke. Diese Reihen zuerst: Ein
	# Punkt näher als 18 cm an einem schon gesetzten fällt weg
	# (`GelaendeFeld`), und die Reihen der Ränder enden genau an M_ENDE. Kamen
	# sie zuerst, fehlten die Querpunkte an Lippe und Fuß der Ufer, und das
	# Feld hinter dem Ende lag dort in der Grube des Ufers statt auf der Kurve.
	var kanten: Array = [_querreihe(Level05.M_ENDE - ENDE_REIHE),
			_querreihe(Level05.M_ENDE + ENDE_REIHE)]
	for zug: Dictionary in Level05.ZUEGE:
		# Je Reihe: Abstand (mal Kronenband), ob er ab dem Knick zählt (bei
		# „auf" die Wandkrone, bei „ab" der Fuß der Wand) oder ab der Linie,
		# ein fester Zusatz (m) und ob die Reihe nur liegt, wo das Band voll
		# ist (1), nicht in der Übergabe. Bei „auf" so eine Reihe am Ende der
		# Platte (`L05Saum`, "weit") und eine am Anfang des Kronenrückens
		# (RUECKEN_AB dahinter). WARUM: Hinter KRONE_OBEN lag die nächste
		# Reihe des Rasters bis 1,6 m weiter, oft schon im fallenden Rücken
		# zum Teich. Das gezeichnete Feld lag am Plattenende dann bis 0,16 m
		# unter dem Modell (Nische G3), und die Platte musste sich darunter
		# ducken (Prüfung P3, Runde 3). In der Übergabe liegt das Band schon
		# im Ufer; dort gaben die Reihen dem Übergangsrücken nur schärfere
		# Facetten (CP3 bei 178).
		var reihen: Array[Vector4] = []
		if String(zug["art"]) == "auf":
			reihen.assign([Vector4(KRONE_UNTEN - 0.5, 1.0, 0.0, 0.0),
					Vector4(KRONE_UNTEN, 1.0, 0.0, 0.0), Vector4(KRONE_UNTEN + 0.8, 1.0, 0.0, 0.0),
					Vector4(KRONE_OBEN, 1.0, 0.0, 0.0), Vector4(L05Saum.KRONE_WEIT, 1.0, 0.0, 1.0),
					Vector4(L05Saum.KRONE_WEIT, 1.0, RUECKEN_AB, 1.0)])
		else:
			reihen.assign([Vector4(-0.2, 0.0, 0.0, 0.0), Vector4(0.6, 1.0, 0.0, 0.0),
					Vector4(0.6 + BETT_BREITE, 1.0, 0.0, 0.0),
					Vector4(2.6 + BETT_BREITE, 1.0, 0.0, 0.0)])
		for stellen in _zug_stuecke(zug):
			# Je Stelle Linie, Knick und Maßstab des Kronenbands (das sich in
			# der Übergabe staucht, `L05Saum.form_auf` "band" – seine Reihen
			# mit ihm).
			var linie := PackedFloat32Array()
			var knick := PackedFloat32Array()
			var band := PackedFloat32Array()
			for s in stellen:
				linie.append(absf(_linie_q(zug, s)))
				if String(zug["art"]) == "auf":
					var m := L05Saum.form_auf(level, zug, s)
					knick.append(float(m["lauf"]))
					band.append(float(m["band"]))
				else:
					knick.append(float(L05Saum.form_ab(level, zug, s)["fuss"]))
					band.append(1.0)
			for r in reihen:
				var punkte := PackedVector2Array()
				for k in stellen.size():
					if r.w > 0.0 and band[k] < 1.0:
						# Übergabe: Die Reihe setzt aus (eine neue beginnt dahinter).
						if punkte.size() >= 2:
							kanten.append({"punkte": punkte, "abstand": 1.0,
									"reihen": PackedFloat32Array([0.0])})
						punkte = PackedVector2Array()
						continue
					var u := linie[k] + r.y * knick[k] + r.x * band[k] + r.z
					punkte.append(_welt(stellen[k], float(zug["seite"]) * u))
				if punkte.size() >= 2:
					kanten.append({"punkte": punkte, "abstand": 1.0,
							"reihen": PackedFloat32Array([0.0])})
	# Quer über jede Lücke dort, wo das Feld auf ihren Grund fällt
	# (LUECKE_HINTER vor den Lippen), knapp davor und dahinter: Sonst spannte
	# das Feld Dreiecke von unter der Decke (0,9 m tief) über den Spalt, und
	# zwischen den Stirnen stand ein heller Boden statt des Grunds.
	for l: Dictionary in Level05.LUECKEN:
		var von := float(l["von"]) - LUECKE_HINTER
		var bis := float(l["bis"]) + LUECKE_HINTER
		for s_kante: float in [von - LUECKE_REIHE, von + LUECKE_REIHE, bis - LUECKE_REIHE,
				bis + LUECKE_REIHE]:
			kanten.append(_querreihe(s_kante))
	f.kanten = kanten


## Eine Punktreihe quer über den Weg an `s` (±LUECKE_QUER, alle 0,8 m).
func _querreihe(s: float) -> Dictionary:
	var punkte := PackedVector2Array()
	var q := -LUECKE_QUER
	while q <= LUECKE_QUER + 0.001:
		punkte.append(_welt(s, q))
		q += 0.8
	return {"punkte": punkte, "abstand": 0.8, "reihen": PackedFloat32Array([0.0])}


## Die Stellen (s), an denen die Reihen eines Zuges ihre Form nehmen: jeden
## Meter, und je Strecke seiner Linie ein eigenes Stück, das an ihren Ecken
## anfängt und endet. WARUM: An der Nische hinter G2 springt die Leitlinie auf
## 0,5 m um 1,25 m nach innen. Mit Stellen nur jeden Meter lief jede Reihe
## als Sehne über diese Ecke; ein Punkt am Fuß der Krone (+2,4 m) lag 0,8 m
## vor der Wand, und das Feld stand 0,25 m über der Schulter. Ein Stück
## beginnt immer mit einem Punkt (`GelaendeFeld.kanten`), die Ecke hat also
## ihren eigenen.
func _zug_stuecke(zug: Dictionary) -> Array[PackedFloat32Array]:
	var von: float = zug["von"]
	var bis: float = zug["bis"]
	var ecken: Array[float] = [von]
	for p: Vector2 in Level05.zug_linie(zug):
		if p.x > ecken[ecken.size() - 1] + 0.05 and p.x < bis - 0.05:
			ecken.append(p.x)
	ecken.append(bis)
	var stuecke: Array[PackedFloat32Array] = []
	for i in ecken.size() - 1:
		var stellen := PackedFloat32Array([ecken[i]])
		var s := floorf(ecken[i]) + 1.0
		while s < ecken[i + 1] - 0.05:
			stellen.append(s)
			s += 1.0
		stellen.append(ecken[i + 1])
		stuecke.append(stellen)
	return stuecke


func _linie_q(zug: Dictionary, s: float) -> float:
	var q := Level05.leitlinie_q(Level05.leitlinie_punkte(float(zug["seite"])), s)
	if String(zug["art"]) == "ab":
		q += float(zug["seite"]) * 0.4
	return q


func _abstand(x: float, z: float) -> float:
	var u := absf(projektion(x, z).y)
	var a := ABSTAND_NAH
	if u > 40.0:
		a = ABSTAND_FERN if u > 90.0 else ABSTAND_WEIT
	elif u > 16.0:
		a = ABSTAND_MITTE
	# Hinter dem Start (Kuppe, Eiche) wie am Weg.
	var sq := projektion(x, z)
	if sq.x < 0.0 and sq.x > -60.0 and u < 50.0:
		a = minf(a, ABSTAND_MITTE)
	return a * (HANDY if Effekte.reduziert else 1.0)


# ================================================================ Höhe

## Das Höhenmodell (siehe Kopf).
func _hoehe(x: float, z: float) -> float:
	var sq := projektion(x, z)
	var s := sq.x
	var q := sq.y
	var u := absf(q)
	var seite := -1.0 if q < 0.0 else 1.0
	var weit := _weit(x, z, s, u, seite)
	var y := weit
	# Am Weg und an seinem Auslauf; hinter dem Start (Querwand bei s −4) gibt
	# es keinen Weg mehr, dort ist alles Kuppe und Kamm.
	if u < 60.0 and s >= -4.0:
		y = _nah(s, q, u, seite, weit)
	return y


## Das Land fern vom Weg: Talboden, Hänge, Kuppe, Sattel und Hochfläche.
func _weit(x: float, z: float, s: float, u: float, seite: float) -> float:
	var boden := level.decke_glatt(s)
	var hang := _hang(s, u, seite)
	# Hinter dem Start: ein flacher Sattel hinter der Kuppe, dann der Kamm,
	# der das Tal oben schließt, dahinter fällt das Land (siehe Kopf).
	if s < 0.0:
		var hinten := -s
		boden = 26.0 - 0.6 * smoothstep(SATTEL.x, SATTEL.y, hinten) \
				+ SUEDKAMM.z * smoothstep(SUEDKAMM.x, SUEDKAMM.y, hinten) \
				- 9.0 * smoothstep(SUEDKAMM.y + 8.0, SUEDKAMM.y + 68.0, hinten)
		hang *= 1.0 - 0.45 * smoothstep(0.0, 90.0, hinten)
	var y := boden + hang
	# Kuppe um die Eiche
	var eiche_s: float = Level05.EICHE["s"]
	var d := Vector2(s - eiche_s, u).length()
	if d < KUPPE_R:
		var k := 1.0 - (d / KUPPE_R) * (d / KUPPE_R)
		y = maxf(y, float(Level05.EICHE["boden_y"]) - KUPPE_H + KUPPE_H * k * k)
	# Buckel: am Weg flach, in der Ferne Kuppen und Rinnen
	var stark := lerpf(0.25, 3.0, smoothstep(28.0, 130.0, u))
	y += stark * _rauschen.get_noise_2d(x, z) + 0.12 * _rauschen_fein.get_noise_2d(x, z)
	return y


## Anstieg der Talhänge über dem Talboden je Seite (m), siehe Kopf.
func _hang(s: float, u: float, seite: float) -> float:
	var r: float
	if seite < 0.0:
		var normal := 2.0 * smoothstep(8.0, 25.0, u) + 30.0 * smoothstep(25.0, 150.0, u) \
				+ 6.0 * smoothstep(140.0, 215.0, u)
		# Tobel: die Südwand direkt hinter dem Bach.
		var tobel := 11.0 * smoothstep(11.0, 20.0, u) + 22.0 * smoothstep(24.0, 150.0, u) \
				+ 5.0 * smoothstep(140.0, 215.0, u)
		var w := smoothstep(176.0, 190.0, s) * (1.0 - smoothstep(262.0, 276.0, s))
		r = lerpf(normal, tobel, w)
	else:
		r = 24.0 * smoothstep(30.0, 175.0, u) + 7.0 * smoothstep(150.0, 220.0, u)
	# Hinter den Kämmen fällt es wieder.
	r -= 16.0 * smoothstep(222.0, 262.0, u)
	return r


## Am Weg (|q| < 60): Decke, Ränder, Lücken, Suhle, Teich, Unterwasser;
## `weit` ist das Land dahinter. Hinter dem Ende der Decke laufen die Ränder
## über ENDE_UEBERGANG Meter in die Wiese aus (von ihrer Form an M_ENDE, der
## Kurve folgend): Dort enden beide Züge, und ohne Übergang stünde quer über
## das Schlussbild eine Stufe von bis 0,3 m im Gras.
func _nah(s: float, q: float, u: float, seite: float, weit: float) -> float:
	# Mulden: Suhle, Teich, Unterwasser (nur graben, nie aufschütten; wie
	# tief, regelt `_zug_y`).
	var mulde := _mulden(s, q, u, seite)
	var y := _rand(s, u, seite, weit, mulde)
	var ende := Level05.M_ENDE
	if s > ende and s < ende + ENDE_UEBERGANG:
		var am_ende := _rand(ende, u, seite, weit, mulde) + _kurve_y(s) - _kurve_y(ende)
		# Schulter und Lippe der Ränder laufen eben weiter: Die Gruben unter
		# ihnen (Bett − 0,6 · f) lagen hinter dem Ende offen, und die Narben
		# der Ufer standen dort als dunkle Zacken 5–11 cm darüber
		# (Prüfung P3, Runde 2).
		# Unter dem Auslauf 2 cm unter ihm, daneben auf der Kurve, also auf
		# Höhe der Decke an M_ENDE: Die Narben der Ufer enden knapp darunter,
		# ihre Deckel liegen im Feld.
		var l_weg := absf(Level05.leitlinie_q(Level05.leitlinie_punkte(seite), s))
		var eben := _kurve_y(s) - (0.02 if u < Level05.auslauf_halb(s) else 0.0)
		am_ende = lerpf(maxf(am_ende, eben), am_ende,
				smoothstep(l_weg + ENDE_LIPPE, l_weg + ENDE_LIPPE + 1.0, u))
		y = minf(lerpf(am_ende, y, smoothstep(ende, ende + ENDE_UEBERGANG, s)), mulde)
	return y


## Höhe der Kurve (Welt-Y) an `s`.
func _kurve_y(s: float) -> float:
	return level.verlauf.sample_baked(clampf(s, 0.0, level.verlauf.get_baked_length())).y


## Decke und Ränder an (s, |q| = u) samt der Mulden (Höhe `mulde`, INF ohne;
## siehe `_nah`). Wo zwei Züge sich überlappen, gibt der frühere seine Form
## an den nächsten ab (`L05Saum.uebergabe`): Das Feld mischt beide, so wie
## der Saum die Böschung dort unter die Erde zieht.
func _rand(s: float, u: float, seite: float, weit: float, mulde: float) -> float:
	var zuege := level.zuege_bei(seite, s)
	# Wo die Decke gezeichnet ist (0 … M_ENDE), liegt das Feld unter ihr; davor
	# (Startboden, ohne eigene Optik) und dahinter (Wiese) IST es der Boden:
	# 2 cm unter der Kollision bzw. auf der Kurve, die am Ende der Decke deren
	# Höhe hat.
	var deck_da := s >= 0.0 and s <= Level05.M_ENDE
	var deck := level.weg.boden_bei(s)
	var flach := deck - 0.02
	if s > Level05.M_ENDE:
		flach = _kurve_y(s) - 0.02
	var unter := deck - UNTER if deck_da else flach
	var luecke := _luecke_weit(s)
	if not luecke.is_empty():
		unter = float(luecke["grund_y"]) - 0.6
	# Am Ende der Decke steigt das Feld unter ihr bis knapp unter sie: Dahinter
	# IST es der Boden, und eine Stufe von 0,9 m stünde dort im Bild.
	if deck_da and s > Level05.M_ENDE - ENDE_RAMPE:
		unter = lerpf(unter, deck - 0.04, smoothstep(Level05.M_ENDE - ENDE_RAMPE, Level05.M_ENDE, s))
	if zuege.is_empty():
		# FLACH: bündig an der Wegkante (hinter M_ENDE am Rand des Auslaufs),
		# dann ins Land.
		var l_weg := absf(Level05.leitlinie_q(Level05.leitlinie_punkte(seite), s))
		var rand := level.weg.wegrand(s) if deck_da else Level05.auslauf_halb(s)
		var y := flach + maxf(weit - flach, 0.0) * smoothstep(rand + 1.0, rand + 9.0, u)
		if deck_da and u < l_weg + 0.6:
			y = unter if not luecke.is_empty() else flach
		return minf(y, mulde)
	var zug: Dictionary = zuege[0]
	if zuege.size() > 1:
		# Überlappung: Der früher endende Zug gibt seine Form ab.
		var b: Dictionary = zuege[1]
		if float(b["bis"]) < float(zug["bis"]):
			var tausch := zug
			zug = b
			b = tausch
		var y_b := _zug_y(b, s, u, weit, mulde, deck, flach, unter, deck_da, luecke)
		var ueb := L05Saum.uebergabe(zug, s)
		if ueb <= 0.0:
			return y_b
		return lerpf(y_b, _zug_y(zug, s, u, weit, mulde, deck, flach, unter, deck_da, luecke), ueb)
	return _zug_y(zug, s, u, weit, mulde, deck, flach, unter, deck_da, luecke)


## Höhe des Felds für einen Zug an (s, |q| = u), samt Mulden.
## AUF: unter Wand und Schulter tief, hinter der Wandkrone das Kronenband
## (KRONE_UNTEN … KRONE_OBEN, mal "band" aus `L05Saum.form_auf`), dahinter
## Krone + KRONE_DECKT oder das Land. Eine Mulde gräbt nie unter das Band
## und den Kronenrücken: Erst RUECKEN_AB hinter dem Ende der Platte darf das
## Feld mit RUECKEN_NEIGUNG fallen. WARUM: Die Teichmulde reichte bis an den
## Weg, und die Platte der Böschung rechts stand s 255–279 bis 4,2 m frei
## über dem Feld (Messtor 280; Prüfung P3, Runde 2).
## AB: unter der Schulter tief, vor der Wand das Bett, dann das Land.
func _zug_y(zug: Dictionary, s: float, u: float, weit: float, mulde: float, deck: float,
		flach: float, unter: float, deck_da: bool, luecke: Dictionary) -> float:
	var y: float
	var l := absf(_linie_q(zug, s))
	if String(zug["art"]) == "auf":
		var m := L05Saum.form_auf(level, zug, s)
		var krone: float = m["krone"]
		var band: float = m["band"]
		var o := u - l - float(m["lauf"])
		if u < l - 0.05 and not deck_da:
			y = flach
		elif o < (KRONE_UNTEN - 0.5) * band:
			y = minf(unter, deck - UNTER) if u >= l - 0.05 else unter
		elif o < KRONE_UNTEN * band:
			y = lerpf(unter, krone - 0.45, (o / band - KRONE_UNTEN + 0.5) / 0.5)
		elif o < KRONE_OBEN * band:
			y = lerpf(krone - 0.45, krone + KRONE_DECKT,
					(o / band - KRONE_UNTEN) / (KRONE_OBEN - KRONE_UNTEN))
		else:
			y = maxf(krone + KRONE_DECKT, weit)
		var gegraben := minf(y, mulde)
		if o >= KRONE_UNTEN * band and gegraben < y:
			var ruecken := krone + KRONE_DECKT \
					- maxf(o - float(m["weit"]) - RUECKEN_AB, 0.0) * RUECKEN_NEIGUNG
			gegraben = maxf(gegraben, minf(y, ruecken))
		return gegraben
	var m := L05Saum.form_ab(level, zug, s)
	var bett: float = m["bett"]
	# Wo der Zug ausläuft (das Bett kommt bis an die Decke), wird auch die
	# Grube hinter seiner Wand flach: Der Saum ist dort winzig und deckte sie
	# nicht mehr.
	var f: float = m["f"]
	var o := u - l - float(m["fuss"])
	if u < l - 0.2:
		y = unter
	elif o < 0.6:
		y = bett - 0.6 * f if luecke.is_empty() else minf(bett - 0.6 * f, unter)
	elif o < 0.6 + BETT_BREITE:
		y = bett - BETT_UNTER * f
	else:
		var hoch := maxf(weit, bett - BETT_UNTER * f)
		y = lerpf(bett - BETT_UNTER * f, hoch, smoothstep(0.6 + BETT_BREITE, 2.6 + BETT_BREITE, o))
	return minf(y, mulde)


## Die Lücke an `s` samt LUECKE_HINTER Metern unter der Decke vor ihren
## Lippen, sonst {}.
static func _luecke_weit(s: float) -> Dictionary:
	for l: Dictionary in Level05.LUECKEN:
		if s > float(l["von"]) - LUECKE_HINTER and s < float(l["bis"]) + LUECKE_HINTER:
			return l
	return {}


## Höhe der Mulden an (s, q), INF wo keine ist.
func _mulden(s: float, q: float, u: float, seite: float) -> float:
	var y := INF
	if seite < 0.0 and s > SUHLE.x - 6.0 and s < SUHLE.y + 6.0:
		var innen := smoothstep(SUHLE.x - 6.0, SUHLE.x, s) * (1.0 - smoothstep(SUHLE.y, SUHLE.y + 6.0, s))
		var quer := smoothstep(SUHLE.z, SUHLE.z + 1.5, u) * (1.0 - smoothstep(SUHLE.w + 2.0, SUHLE.w + 6.0, u))
		if innen * quer > 0.0:
			y = minf(y, 26.0 + 0.4 - (SUHLE_TIEF + 0.4) * innen * quer)
	if seite > 0.0:
		var e := Vector2((s - TEICH.position.x) / TEICH.size.x,
				(u - TEICH.position.y) / TEICH.size.y).length()
		if e < 1.9:
			y = minf(y, TEICH_GRUND + 2.9 * smoothstep(0.85, 1.9, e))
	if seite < 0.0 and s > UNTERWASSER[0].x - 4.0:
		var d := _abstand_lauf(Vector2(s, q), UNTERWASSER)
		var halb := UNTERWASSER_BREITE * 0.5
		if d < halb + 6.0:
			y = minf(y, UNTERWASSER_GRUND + 3.4 * smoothstep(halb - 1.5, halb + 6.0, d))
	return y


## Abstand eines Punkts (s, q) von einem Lauf aus Punkten (s, q).
static func _abstand_lauf(p: Vector2, lauf: Array[Vector2]) -> float:
	var beste := INF
	for i in lauf.size() - 1:
		var a := lauf[i]
		var b := lauf[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		beste = minf(beste, p.distance_to(a + ab * t))
	return beste


# ================================================================ Farbe

## Gewichte der vier Böden (R Wiese, G Waldboden, B Fels, A Schlamm): Fels,
## wo es steil ist; Schlamm in Betten und Mulden; Waldboden am Hohlweg und
## am Westhang (Buchenwald, Paket P7); Wiese in A und E und am Sonnenhang.
func _faerben(p: Vector3, n: Vector3) -> Color:
	var sq := projektion(p.x, p.z)
	var s := sq.x
	var u := absf(sq.y)
	var fels := 1.0 - smoothstep(0.6, 0.8, n.y)
	var boden := level.decke_glatt(s)
	var nass := (1.0 - smoothstep(-2.0, -0.9, p.y - boden)) * smoothstep(5.5, 7.0, u)
	if sq.y < 0.0 and s > SUHLE.x - 2.0 and s < SUHLE.y + 2.0 and u > SUHLE.z:
		nass = maxf(nass, 1.0 - smoothstep(-0.25, 0.1, p.y - 26.0))
	nass *= 1.0 - fels
	var wald := smoothstep(28.0, 40.0, s) * (1.0 - smoothstep(255.0, 270.0, s))
	# Die fernen Hänge tragen Wald (Paket P7), nur Kuppe, Kamm und Mühlwiese
	# bleiben Wiese.
	var wiese_zone := maxf(1.0 - smoothstep(-20.0, 0.0, s), smoothstep(262.0, 280.0, s))
	wald = maxf(wald, smoothstep(40.0, 80.0, u) * (1.0 - wiese_zone))
	# Am Weg Wiese: Dort tritt das Feld über die Krone des Saums (dessen Narbe
	# trägt denselben Rasen), und die Kronen des Hohlwegs bleiben Rasen
	# (Entwurf §9.1: Rasensaum auf den Kronen).
	wald *= smoothstep(18.0, 30.0, u) * (1.0 - fels) * (1.0 - nass)
	# Hinter s 300 keine eigene Spur: Die zeichnet der Auslauf der Decke
	# (`Level05._auslauf_bauen`) im Löss der Decke, das Feld bleibt Wiese.
	var wiese := maxf(1.0 - fels - wald - nass, 0.0)
	return Color(wiese, wald, fels, nass)


## UV2: Verdeckung (Mulden, die Wegkante wie die Decke 0,78) und Kronenlicht
## (keines – das Dach kommt mit dem Wald).
func _zusatz(p: Vector3, _n: Vector3, mulde: float) -> Vector2:
	var sq := projektion(p.x, p.z)
	var ao := clampf(1.0 - mulde * 0.25, 0.65, 1.0)
	var rand := level.weg.wegrand(sq.x) if sq.x >= -4.0 and sq.x <= Level05.M_ENDE \
			else Level05.auslauf_halb(sq.x)
	ao = minf(ao, lerpf(0.78, 1.0, smoothstep(rand + 0.5, rand + 4.0, absf(sq.y))))
	return Vector2(ao, 0.0)


## UV1: Tönung – kühl auf der Schattenseite, im Tobel und an Wasser, warm am
## Sonnenhang; am Weg 0 wie die Decke.
func _zusatz2(p: Vector3, n: Vector3) -> Vector2:
	var sq := projektion(p.x, p.z)
	var u := absf(sq.y)
	var weg_nah := smoothstep(6.0, 14.0, u)
	var t := 0.45 if sq.y > 0.0 else -0.45
	var tobel := smoothstep(178.0, 190.0, sq.x) * (1.0 - smoothstep(262.0, 276.0, sq.x))
	if sq.y < 0.0:
		t -= 0.35 * tobel
	t -= 0.4 * (1.0 - smoothstep(-1.6, -0.6, p.y - level.decke_glatt(sq.x)))
	t += 0.15 * (n.y - 0.8)
	return Vector2(clampf(t * weg_nah, -1.0, 1.0), 0.0)
