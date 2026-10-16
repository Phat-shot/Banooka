extends RefCounted
class_name Waldrahmen
## Die Regeln, nach denen Wald neben einem Weg stehen darf – ohne Bezug auf
## Level 01 (Baukasten Raum 1, Paket G4; Herkunft scenes/levels/level01/
## wald.gd, `L01Wald`: Bahn :461-545, Auge :631-637, Regeln :646-754,
## Himmelsprobe :2604-2743).
##
## WARUM EINE KOPIE. `L01Wald` hält seinen Weg in statischen Merkern
## (wald.gd:304-347, Gegenbeispiel in Baukasten §0 Nr. 3) und liest Weg,
## Kamera und Gelände aus `Level01`. Die Level 02–05 brauchen dieselben
## Regeln – keine Krone im Freiraum über dem Weg, kein Stamm auf ihm, kein
## Baum in einem Sichtkegel, keine Krone als Ballon vor dem Himmel –, aber
## mit eigenem Weg und eigener Kamera. Der Rechenweg steht hier deshalb ein
## zweites Mal, wörtlich: Mit den Daten von Level 01 liefern `weg_frei` und
## `kegel_frei` bis aufs Bit dieselben Antworten (`werkzeuge/baukasten-
## probe.gd`, Teil G4). Der ganze Zustand gehört der Instanz; jedes Level
## baut seinen Rahmen selbst und lässt ihn nach dem Bau fallen.
##
## DAS AUGE. wald.gd rechnet die Kamera fest 9,5 m zurück und 6 m hoch
## (:631-637). Hier kommt beides aus der echten `KorridorKamera` (`abstand`,
## `hoehe`), also auch ein Rückblick mit negativem Abstand (Level 05: −21
## m, die Kamera steht VOR der Figur). Abweichung von wald.gd, begründet:
## Die Kamerastation wird wie in `KorridorKamera._folgen` auf die Kurve
## geklemmt (0 … Länge); wald.gd verlängerte die Kurve dort geradeaus. Im
## Inneren der Kurve ist beides gleich, an den Enden stimmt so das Auge mit
## dem Ort der Kamera überein (gemessen ±0,3 m nach `sofort_ausrichten`,
## Baukastenprobe). Sobald die Kamera einen Kameraplan trägt (Paket G6),
## liest `auge()` Abstand und Höhe aus dessen Profil an der Stelle.
##
## REGELN (Plan L01 7, 11; Werte als Vorgabe, je Rahmen änderbar):
##   weg_frei    keine Krone über |q| < frei_q tiefer als frei_h über der
##               Decke (oder ganz unter dem Weg)
##   stamm_frei  kein Stamm unter `stamm_frei_h` über der Decke näher als
##               frei_q an der Mitte; am Boden außerhalb des Begehbaren
##   kegel_frei  keine Krone in einem Sichtkegel (`kegel`, Schema von
##               `Waldsetzer.kegel_frei`)
##   kante_frei  Kronen unter einer Kante (`kanten`) bleiben so tief unter
##               der Decke (wald.gd:696, dort fest rechts s 30–147)
##   kiste_frei  Abstand zu den Kisten (waagerecht)
##   platz       nah genug am Weg, nicht zu nah, nicht in `sperren`
##   einsinken   Himmelsprobe für ferne Bäume: wie tief ein Baum einsinken
##               muss, damit er von keiner Station aus als Scheibe vor dem
##               Himmel hängt (< 0: er fällt weg)
##
## ABWEICHUNGEN VOM PLAN (Baukasten §1.4), weil der Code sie verlangt:
##   - `_init` nimmt freiwillig `optionen` (von, bis, feld): Bitgleichheit
##     mit wald.gd braucht dessen Probenbereich (−18 … 292) und Feld, ein
##     Level mit langer Kurve will die Proben nur dort, wo Wald steht.
##   - `stamm_frei` behält die freiwilligen Werte aus wald.gd (fussweite,
##     zugabe, achse) – `Baumfabrik.pflanze` braucht sie für Brettwurzeln
##     und schiefe Stämme.
##   - Dazu, weil der Hain sie braucht: Kegel, Kanten und Sperren als Daten
##     (wald.gd hatte sie fest für Level 01), `platz`, `kante_frei`, die
##     Raster `staemme`/`kronen`, `naechste`/`quer`/`strecke_quer` und
##     `kegel_entlang`.

## Freiraum über dem Weg (L01 K1): so weit quer, ab dieser Höhe.
const FREI_Q := 6.0
const FREI_H := 9.5
## Unter dieser Höhe steht über |q| < FREI_Q kein Stamm.
const STAMM_FREI_H := 8.8
## Kantenregel: so tief unter der Decke, so weit quer über die Lippe.
const KANTE_TIEFE := 5.0
const KANTE_WEITE := 14.0
## Eimer der Wegproben (m) und das Raster des Wegabstands (m), dazu die
## Weite, bis zu der jede zweite Probe ihre Umgebung stempelt.
const EIMER := 10.0
const FELD_ZELLE := 4.0
const FELD_WEITE := 72.0
## Die Kamera von Level 01 (CorridorCamera.tscn), wenn keine da ist.
const ABSTAND_VORGABE := 9.5
const HOEHE_VORGABE := 6.0
## Himmelsprobe (wald.gd:199-211): Augen alle so viele m, Proben alle so
## viele m auf dem Sehstrahl; Kämme weiter weg zählen nicht; Gelände hinter
## einer Krone nur bis so weit von der Station; Raster der Geländehöhe.
const HIMMEL_SCHRITT := 6.0
const HIMMEL_TRITT := 3.0
const KAMM_WEIT := 100.0
const HIMMEL_HINTER := 175.0
const HOEHEN_ZELLE := 2.0
## Ferne Bäume: Dort beginnt ihre Krone (Anteil der Höhe), so weit sinken
## sie ein, und weiter nie (wald.gd:196-198).
const FERN_BODEN := 0.1
const FERN_SINKEN := 0.2
const FERN_SINKEN_MAX := 0.5
## Sichtweite der Kamera, wenn keine da ist (CorridorCamera.tscn `far`).
const KAMERA_FERN := 200.0

var weg: Wegdaten
## Die Spielkamera des Levels (darf null sein: dann die Werte von Level 01).
var kamera: KorridorKamera
## Kisten in Welt-Koordinaten (`KorridorLevel.kisten_orte()`); Kisten
## werden VOR dem Wald gesetzt.
var kisten: Array[Vector3] = []
## Sichtkegel, Schema `Waldsetzer.kegel_frei`: {auge, ziel, winkel (rad),
## ziel_frei?}. Leer: keine Kegel.
var kegel: Array[Dictionary] = []
## Vorprüfung von `kegel_frei` (`_kegel_vorbereiten`).
var _kegel_kaesten: Array[AABB] = []
var _kegel_huelle := AABB()
var _kegel_cos := 1.0
var _kegel_erster := {}
var _kegel_letzter := {}
## Kantenregel: {von, bis (Strecke), seite (+1 rechts, −1 links),
## weite? (KANTE_WEITE), tiefe? (KANTE_TIEFE)}. Leer: keine Kanten.
var kanten: Array[Dictionary] = []
## Hier wächst nichts: Vector4(s_von, s_bis, q_von, q_bis).
var sperren: Array[Vector4] = []
## Unter dieser Höhe kein Stamm über dem Weg (Vorgabe STAMM_FREI_H).
var stamm_frei_h := STAMM_FREI_H
## Stämme (Mindestabstand) und Kronen (keine Doppelkronen) über alle
## Schritte eines Levels – wie `L01Wald._staemme`/`_kronen`.
var staemme := Waldsetzer.Raster.new(8.0)
var kronen := Waldsetzer.Raster.new(8.0)
## Gezählt (für `debug`) und warum `Baumfabrik.pflanze` zuletzt nein sagte.
var zahlen := {}
var grund := ""
## Zwischenspeicher der `Baumfabrik` für diesen Bau (Netze je Schlüssel).
var netze := {}
## Das Rechteck (Welt-XZ), über dem der Wegabstand gerastert ist.
var feld := Rect2()

## Der Weg als Proben alle Meter: Punkt (y = Decke), Rechtsvektor, Strecke,
## halbe Wegbreite; dazu Eimer für die Suche.
var _bahn_p := PackedVector3Array()
var _bahn_r := PackedVector3Array()
var _bahn_s := PackedFloat32Array()
var _bahn_halb := PackedFloat32Array()
var _eimer := {}
var _feld_d := PackedFloat32Array()
var _feld_i := PackedInt32Array()
var _feld_mass := Vector2i.ZERO
## Himmelsprobe: Augen, Blickrichtung, Höhenraster (erst bei Bedarf).
var _himmel_augen := PackedVector3Array()
var _himmel_blick := PackedVector3Array()
var _hoehen_raster := PackedFloat32Array()
var _hoehen_mass := Vector2i.ZERO
var _hoehen_feld := Rect2()
var _himmel_bereit := false


## `kisten_` aus `kisten_orte()`. Optionen (alle freiwillig):
##   von, bis   Strecke der Wegproben (Vorgabe: erster Abschnitt − 10 m bis
##              letzter + 5 m; Level 01: −18 … 292)
##   feld       Rect2 (Welt-XZ) des Wegabstand-Rasters (Vorgabe: die Proben
##              samt `FELD_WEITE` und einer Zelle Rand)
func _init(weg_: Wegdaten, kamera_: KorridorKamera, kisten_: Array[Vector3],
		optionen: Dictionary = {}) -> void:
	weg = weg_
	kamera = kamera_
	kisten = kisten_.duplicate()
	var von := -10.0
	var bis := weg.verlauf.get_baked_length() + 5.0
	if not weg.abschnitte.is_empty():
		von = INF
		bis = -INF
		for a: Dictionary in weg.abschnitte:
			von = minf(von, float(a["von"]) - 10.0)
			bis = maxf(bis, float(a["bis"]) + 5.0)
	_bahn_anlegen(float(optionen.get("von", von)), float(optionen.get("bis", bis)),
			optionen.get("feld", Rect2()) as Rect2)


# =========================================================== Bahn

## Wörtlich wie wald.gd:461-507, mit Bereich und Feld als Werten.
func _bahn_anlegen(von: float, bis: float, feld_: Rect2) -> void:
	_bahn_p = PackedVector3Array()
	_bahn_r = PackedVector3Array()
	_bahn_s = PackedFloat32Array()
	_bahn_halb = PackedFloat32Array()
	_eimer.clear()
	var s := von
	while s <= bis:
		var p := weg.weg_punkt(s)
		var r := LevelWerkzeuge.richtung(weg.verlauf, s).cross(Vector3.UP)
		r.y = 0.0
		var i := _bahn_p.size()
		_bahn_p.append(p)
		_bahn_r.append(r.normalized())
		_bahn_s.append(s)
		_bahn_halb.append(float(weg.rand_profil(s, 1.0)["wegrand"]))
		var k := Vector2i(floori(p.x / EIMER), floori(p.z / EIMER))
		if not _eimer.has(k):
			_eimer[k] = PackedInt32Array()
		var liste: PackedInt32Array = _eimer[k]
		liste.append(i)
		_eimer[k] = liste
		s += 1.0
	feld = feld_
	if feld.size == Vector2.ZERO:
		var a := Vector2(INF, INF)
		var b := Vector2(-INF, -INF)
		for p in _bahn_p:
			a = Vector2(minf(a.x, p.x), minf(a.y, p.z))
			b = Vector2(maxf(b.x, p.x), maxf(b.y, p.z))
		var rand := FELD_WEITE + FELD_ZELLE
		feld = Rect2(a - Vector2(rand, rand), b - a + Vector2(rand, rand) * 2.0)
	# Abstand zum Weg auf einem groben Raster: jede zweite Probe stempelt
	# ihre Umgebung bis `FELD_WEITE`.
	_feld_mass = Vector2i(ceili(feld.size.x / FELD_ZELLE), ceili(feld.size.y / FELD_ZELLE))
	_feld_d = PackedFloat32Array()
	_feld_d.resize(_feld_mass.x * _feld_mass.y)
	_feld_d.fill(1000.0)
	_feld_i = PackedInt32Array()
	_feld_i.resize(_feld_mass.x * _feld_mass.y)
	_feld_i.fill(-1)
	var n := ceili(FELD_WEITE / FELD_ZELLE)
	for i in range(0, _bahn_p.size(), 2):
		var p := _bahn_p[i]
		var cx := floori((p.x - feld.position.x) / FELD_ZELLE)
		var cz := floori((p.z - feld.position.y) / FELD_ZELLE)
		for a in range(maxi(cx - n, 0), mini(cx + n + 1, _feld_mass.x)):
			for b in range(maxi(cz - n, 0), mini(cz + n + 1, _feld_mass.y)):
				var mx := feld.position.x + (float(a) + 0.5) * FELD_ZELLE
				var mz := feld.position.y + (float(b) + 0.5) * FELD_ZELLE
				var d := Vector2(mx - p.x, mz - p.z).length()
				var k := b * _feld_mass.x + a
				if d < _feld_d[k]:
					_feld_d[k] = d
					_feld_i[k] = i


## Waagerechter Abstand zum Weg (Mitte), grob (±3 m); 1000 weit draußen.
func wegabstand(x: float, z: float) -> float:
	var a := floori((x - feld.position.x) / FELD_ZELLE)
	var b := floori((z - feld.position.y) / FELD_ZELLE)
	if a < 0 or b < 0 or a >= _feld_mass.x or b >= _feld_mass.y:
		return 1000.0
	return _feld_d[b * _feld_mass.x + a]


## Die nächste Wegprobe (Index) zu einem Punkt, genau; −1 weit draußen.
func naechste(x: float, z: float) -> int:
	var a := floori((x - feld.position.x) / FELD_ZELLE)
	var b := floori((z - feld.position.y) / FELD_ZELLE)
	var grob := -1
	if a >= 0 and b >= 0 and a < _feld_mass.x and b < _feld_mass.y:
		grob = _feld_i[b * _feld_mass.x + a]
	if grob < 0:
		return -1
	var beste := grob
	var bester := INF
	for i in range(maxi(grob - 6, 0), mini(grob + 7, _bahn_p.size())):
		var d := Vector2(x - _bahn_p[i].x, z - _bahn_p[i].z).length_squared()
		if d < bester:
			bester = d
			beste = i
	return beste


## Quer zum Weg an der Probe `i` (positiv rechts).
func quer(i: int, x: float, z: float) -> float:
	var r := _bahn_r[i]
	return (x - _bahn_p[i].x) * r.x + (z - _bahn_p[i].z) * r.z


## (s, q) eines Weltpunkts über die nächste Wegprobe (s auf 1 m genau);
## Vector2(NAN, NAN) weit draußen.
func strecke_quer(x: float, z: float) -> Vector2:
	var i := naechste(x, z)
	if i < 0:
		return Vector2(NAN, NAN)
	return Vector2(_bahn_s[i], quer(i, x, z))


## Halbe Wegbreite und Decke an der Probe `i` (für Pflanzer, die selbst
## prüfen, wie wald.gd:2319).
func halb_bei(i: int) -> float:
	return _bahn_halb[i]


func decke_bei(i: int) -> float:
	return _bahn_p[i].y


## Alle Wegproben im Umkreis `r` (waagerecht).
func _proben_nahe(x: float, z: float, r: float) -> PackedInt32Array:
	var aus := PackedInt32Array()
	var a := Vector2i(floori((x - r) / EIMER), floori((z - r) / EIMER))
	var b := Vector2i(floori((x + r) / EIMER), floori((z + r) / EIMER))
	for i in range(a.x, b.x + 1):
		for j in range(a.y, b.y + 1):
			var k := Vector2i(i, j)
			if not _eimer.has(k):
				continue
			for n: int in _eimer[k]:
				if Vector2(x - _bahn_p[n].x, z - _bahn_p[n].z).length() <= r:
					aus.append(n)
	return aus


# =========================================================== Auge

## Abstand und Höhe der Kamera, wenn die Figur bei `s` steht: aus dem Plan
## der Kamera (ab Paket G6, `profil_bei`), sonst ihren Exports, ohne Kamera
## die Werte von Level 01.
func kamera_werte(s: float) -> Vector2:
	if kamera == null:
		return Vector2(ABSTAND_VORGABE, HOEHE_VORGABE)
	var werte := Vector2(kamera.abstand, kamera.hoehe)
	# Haken für den Kameraplan (Paket G6): Die Kamera hat das Feld heute
	# noch nicht, `get` liefert dann null.
	var plan: Variant = kamera.get("plan")
	if plan is Object and (plan as Object).has_method("profil_bei"):
		var profil: Dictionary = (plan as Object).call("profil_bei", s)
		werte = Vector2(float(profil.get("abstand", werte.x)), float(profil.get("hoehe", werte.y)))
	return werte


## Ort der Verfolgerkamera, wenn die Figur bei `s` in der Mitte auf der
## Decke steht – wie `KorridorKamera._folgen` nach `sofort_ausrichten()`:
## `abstand` zurück auf der Kurve (geklemmt auf die Kurve), `hoehe` über
## der Figur, gemessen an der Kurve dort, wo die Kamera steht (bergauf
## tiefer, bergab höher als Figur + hoehe). Mit 9,5/6 im Inneren der Kurve
## bitgleich mit wald.gd:631-637.
func auge(s: float) -> Vector3:
	var werte := kamera_werte(s)
	var laenge := weg.verlauf.get_baked_length()
	var auge_ := LevelWerkzeuge.punkt_frei(weg.verlauf, clampf(s - werte.x, 0.0, laenge), 0.0)
	var hier := LevelWerkzeuge.punkt_frei(weg.verlauf, s, 0.0)
	auge_.y = weg.boden_bei(s) + werte.y + (auge_.y - hier.y)
	return auge_


## Kegel von der Kamera zu `ziel` an jeder Station von `von` bis `bis` (alle
## `schritt` m), halber Öffnungswinkel `winkel_grad`, die letzten
## `ziel_frei` m vor dem Ziel frei (Muster wald.gd:567-626).
func kegel_entlang(von: float, bis: float, schritt: float, ziel: Vector3, winkel_grad: float,
		ziel_frei: float = 0.0) -> void:
	var s := von
	while s <= bis:
		var k := {"auge": auge(s), "ziel": ziel, "winkel": deg_to_rad(winkel_grad)}
		if ziel_frei > 0.0:
			k["ziel_frei"] = ziel_frei
		kegel.append(k)
		s += schritt


# =========================================================== Regeln

## Hält eine Krone (Welt-Hülle) den Freiraum über dem Weg? Über |q| <
## `frei_q` liegt ihre Unterkante mindestens `frei_h` über der Decke –
## oder die ganze Krone unter dem Weg (wald.gd:646).
func weg_frei(huelle: AABB, frei_q: float = FREI_Q, frei_h: float = FREI_H) -> bool:
	var mitte := huelle.get_center()
	var r := maxf(huelle.size.x, huelle.size.z) * 0.5
	for i in _proben_nahe(mitte.x, mitte.z, r + frei_q + 1.0):
		var p := _bahn_p[i]
		var rechts := Vector2(_bahn_r[i].x, _bahn_r[i].z)
		var d := Vector2(mitte.x - p.x, mitte.z - p.z)
		var q := d.dot(rechts)
		var laengs := absf(d.dot(Vector2(-rechts.y, rechts.x)))
		if absf(q) - r >= frei_q or laengs > r + 0.6:
			continue
		if huelle.position.y >= p.y + frei_h or huelle.end.y <= p.y - 0.5:
			continue
		return false
	return true


## Steht ein Stamm (Achse von `fuss` nach `spitze`, Radius `r`) frei vom
## Weg? Kein Teil unter `stamm_frei_h` über der Decke näher als FREI_Q an
## der Mitte, und am Boden bleibt er außerhalb des Begehbaren (`fussweite`
## = Umriss samt Brettwurzeln zum Weg hin). wald.gd:667.
func stamm_frei(fuss: Vector3, spitze: Vector3, r: float, fussweite: float = 0.0,
		zugabe: float = 0.9, achse: PackedVector3Array = PackedVector3Array()) -> bool:
	var i0 := naechste(fuss.x, fuss.z)
	if i0 >= 0:
		var q0 := absf(quer(i0, fuss.x, fuss.z))
		var p0 := _bahn_p[i0]
		if absf(fuss.y - p0.y) < 3.0 and q0 - maxf(fussweite, r) < _bahn_halb[i0] + zugabe:
			return false
	var punkte := achse
	if punkte.is_empty():
		for k in 10:
			punkte.append(fuss.lerp(spitze, float(k) / 9.0))
	for p in punkte:
		# Am Fuß zählt der Umriss samt Wurzeln, darüber der Stamm.
		var rr := r if p.y - fuss.y > 1.2 else maxf(r, fussweite)
		for i in _proben_nahe(p.x, p.z, FREI_Q + rr + 1.0):
			var b := _bahn_p[i]
			if p.y > b.y + stamm_frei_h or p.y < b.y - 0.5:
				continue
			if absf(quer(i, p.x, p.z)) - rr < FREI_Q:
				return false
	return true


## Kronen unter einer Kante (`kanten`): Liegt eine Krone auf der Seite der
## Kante höchstens `weite` hinter dem Wegrand, bleibt ihr Scheitel `tiefe`
## unter der Decke – sonst läse sie sich als Tritt neben dem Weg
## (wald.gd:696, dort fest für B und C rechts).
func kante_frei(huelle: AABB) -> bool:
	if kanten.is_empty():
		return true
	var mitte := huelle.get_center()
	var r := maxf(huelle.size.x, huelle.size.z) * 0.5
	for e: Dictionary in kanten:
		var weite := float(e.get("weite", KANTE_WEITE))
		var tiefe := float(e.get("tiefe", KANTE_TIEFE))
		var seite := float(e.get("seite", 1.0))
		for i in _proben_nahe(mitte.x, mitte.z, r + weite + 10.0):
			var s := _bahn_s[i]
			if s < float(e["von"]) or s > float(e["bis"]):
				continue
			var q := quer(i, mitte.x, mitte.z) * seite
			if q <= 0.0:
				continue
			if q - r > _bahn_halb[i] + weite:
				continue
			if huelle.end.y > _bahn_p[i].y - tiefe:
				return false
	return true


## Liegt eine Krone (Welt-Hülle) außerhalb aller Sichtkegel (`kegel`)?
## Geprüft an Punkten, die sicher in der Krone liegen: Mitte, Flächenmitten
## (85 %) und Ecken (55 %) der Hülle (wald.gd:718).
##
## VORPRÜFUNG mit Kästen (`_kegel_vorbereiten`), dieselben Antworten: Eine
## Kugel (Mitte m, Radius r), die `Waldsetzer.kegel_frei_einzeln` im Kegel
## findet, hat ihre Mitte näher als L·tan w + r/cos w an der Achse von Auge
## bis Ziel (L Länge, w halber Öffnungswinkel; aus θ − asin(r/d) < w und
## Abstand längs ≤ L). Liegt m außerhalb des Kastens um die Achse, der um
## L·tan w und dann um r/cos w (+5 cm gegen Rundung) geweitet ist, bliebe
## die Prüfung ohne Treffer – sie entfällt. Erst gegen den Kasten um alle
## Kegel, dann je Kegel. In Level 05 (rund 290 Kegel, rund 1 000 Kronen)
## liefen sonst rund 200 000 Einzelprüfungen beim kalten Bau (Paket P8).
func kegel_frei(huelle: AABB) -> bool:
	var m := huelle.get_center()
	var h := huelle.size * 0.5
	# Vorab mit der Kugel um die ganze Hülle: Die meisten Kegel liegen weit
	# weg, nur die übrigen prüfen die 15 Punkte.
	var nahe: Array[Dictionary] = []
	var weit := h.length()
	_kegel_vorbereiten()
	var rand := weit / _kegel_cos + 0.05
	var alle := _kegel_huelle
	if m.x < alle.position.x - rand or m.x > alle.end.x + rand \
			or m.y < alle.position.y - rand or m.y > alle.end.y + rand \
			or m.z < alle.position.z - rand or m.z > alle.end.z + rand:
		return true
	for i in kegel.size():
		var b := _kegel_kaesten[i]
		if m.x < b.position.x - rand or m.x > b.end.x + rand \
				or m.y < b.position.y - rand or m.y > b.end.y + rand \
				or m.z < b.position.z - rand or m.z > b.end.z + rand:
			continue
		var k := kegel[i]
		if not Waldsetzer.kegel_frei_einzeln(m, weit, k):
			nahe.append(k)
	if nahe.is_empty():
		return true
	var punkte: Array[Vector3] = [m]
	for achse in 3:
		for vz: float in [-1.0, 1.0]:
			var d := Vector3.ZERO
			d[achse] = h[achse] * 0.85 * vz
			punkte.append(m + d)
	for ix: float in [-1.0, 1.0]:
		for iy: float in [-1.0, 1.0]:
			for iz: float in [-1.0, 1.0]:
				punkte.append(m + Vector3(h.x * ix, h.y * iy, h.z * iz) * 0.55)
	var r := minf(minf(h.x, h.y), h.z) * 0.3
	for p in punkte:
		if not Waldsetzer.kegel_frei(p, r, nahe):
			return false
	return true


## Kästen der Vorprüfung von `kegel_frei` (siehe dort): je Kegel die Achse
## von Auge bis Ziel, geweitet um L·tan w; dazu der Kasten um alle und der
## kleinste Kosinus der Öffnungswinkel. Neu gerechnet, wenn sich die Liste
## geändert hat (Zahl, erster oder letzter Eintrag – `kegel` wird nur
## angehängt oder ganz ersetzt, `werkzeuge/baukastenprobe.gd`).
func _kegel_vorbereiten() -> void:
	var n := kegel.size()
	if n == _kegel_kaesten.size() and (n == 0 or (is_same(kegel[0], _kegel_erster)
			and is_same(kegel[n - 1], _kegel_letzter))):
		return
	_kegel_kaesten.clear()
	_kegel_cos = 1.0
	_kegel_huelle = AABB()
	for i in n:
		var k := kegel[i]
		var auge: Vector3 = k["auge"]
		var ziel: Vector3 = k["ziel"]
		var winkel: float = k["winkel"]
		var kasten := AABB(auge, Vector3.ZERO).expand(ziel)
		kasten = kasten.grow(auge.distance_to(ziel) * tan(winkel))
		_kegel_kaesten.append(kasten)
		_kegel_cos = minf(_kegel_cos, cos(winkel))
		_kegel_huelle = kasten if i == 0 else _kegel_huelle.merge(kasten)
	_kegel_cos = maxf(_kegel_cos, 0.01)
	_kegel_erster = kegel[0] if n > 0 else {}
	_kegel_letzter = kegel[n - 1] if n > 0 else {}


## Frei von Kisten (waagerecht, `abstand` m)? wald.gd:750.
func kiste_frei(p: Vector3, abstand: float) -> bool:
	for k in kisten:
		if Vector2(k.x - p.x, k.z - p.z).length() < abstand:
			return false
	return true


## Darf bei `p` (Welt-XZ) etwas wachsen? `nah` bis `weit` m vom Weg (grob,
## `wegabstand`) und in keiner Sperre (`sperren`, mit `rand` m Zugabe –
## Sträucher halten Abstand zu Lichtungen, wald.gd:2359).
func platz(p: Vector2, nah: float = 3.0, weit: float = 42.0, rand: float = 0.0) -> bool:
	var d := wegabstand(p.x, p.y)
	if d > weit or d < nah:
		return false
	if sperren.is_empty():
		return true
	var sq := strecke_quer(p.x, p.y)
	if is_nan(sq.x):
		return true
	for v in sperren:
		if sq.x > v.x - rand and sq.x < v.y + rand and sq.y > v.z - rand and sq.y < v.w + rand:
			return false
	return true


## Zählt für `debug`.
func zaehle(was: String, n: int = 1) -> void:
	zahlen[was] = int(zahlen.get(was, 0)) + n


# =========================================================== Himmelsprobe

## Wie tief (m) muss ein ferner Baum (Fuß `fuss`, Höhe `hoch`) einsinken,
## damit er von keiner Station aus als Scheibe in der Luft hängt? 0: gar
## nicht; < 0: das geht nicht, er fällt weg. `hoehe`: Callable(x, z) ->
## float, die gezeichnete Geländehöhe (NAN, wo keines ist); beim ersten
## Aufruf wird sie auf ein Raster über `feld` gelegt (`himmel_vorbereiten`).
## Regeln wörtlich wie wald.gd:2636-2682.
func einsinken(fuss: Vector3, hoch: float, hoehe: Callable) -> float:
	if not _himmel_bereit:
		himmel_vorbereiten(hoehe, feld)
	var fern := KAMERA_FERN if kamera == null else kamera.far
	var unten := fuss + Vector3.UP * hoch * (FERN_BODEN + 0.1)
	var tief := 0.0
	for k in _himmel_augen.size():
		var auge_ := _himmel_augen[k]
		var zu := unten - auge_
		var e := zu.length()
		if e < 40.0 or e > fern - 2.0:
			continue
		# Nur, was diese Kamera ungefähr im Bild hat (±56° waagerecht).
		if Vector3(zu.x, 0.0, zu.z).normalized().dot(_himmel_blick[k]) < 0.55:
			continue
		var dir := zu / e
		if _gelaende_im_strahl(unten, dir, 2.0, HIMMEL_HINTER - e):
			continue
		if _gelaende_im_strahl(auge_, dir, 3.0, minf(e - 2.0, KAMM_WEIT)):
			continue
		var noetig := hoch * FERN_SINKEN
		var kamm := _kammhoehe(auge_, fuss)
		if kamm > fuss.y - 1.5:
			noetig = maxf(noetig, fuss.y + hoch * FERN_BODEN + 0.5 - kamm)
		if noetig > hoch * FERN_SINKEN_MAX:
			return -1.0
		tief = maxf(tief, noetig)
	return tief


## Legt die Augen der Himmelsprobe (die Kamera alle HIMMEL_SCHRITT m mit
## ihrer waagerechten Blickrichtung zum Blickpunkt `blick_vorlauf` voraus)
## und das Höhenraster über `bereich` an (wald.gd:2604-2633). Ein Rückblick
## (abstand < 0) schaut zurück: Die Richtung folgt dem Blickpunkt der Kamera.
func himmel_vorbereiten(hoehe: Callable, bereich: Rect2) -> void:
	_himmel_bereit = true
	_himmel_augen = PackedVector3Array()
	_himmel_blick = PackedVector3Array()
	var vorlauf := 6.0 if kamera == null else kamera.blick_vorlauf
	var von := 0.0
	var bis := weg.verlauf.get_baked_length()
	if not weg.abschnitte.is_empty():
		von = INF
		bis = -INF
		for a: Dictionary in weg.abschnitte:
			von = minf(von, float(a["von"]))
			bis = maxf(bis, float(a["bis"]))
	var s := maxf(von, 0.0)
	while s <= bis:
		var auge_ := auge(s)
		var blick := weg.weg_punkt(s + vorlauf) - auge_
		blick.y = 0.0
		_himmel_augen.append(auge_)
		_himmel_blick.append(blick.normalized())
		s += HIMMEL_SCHRITT
	_hoehen_feld = bereich
	_hoehen_mass = Vector2i(ceili(bereich.size.x / HOEHEN_ZELLE) + 1,
			ceili(bereich.size.y / HOEHEN_ZELLE) + 1)
	_hoehen_raster = PackedFloat32Array()
	_hoehen_raster.resize(_hoehen_mass.x * _hoehen_mass.y)
	var i := 0
	for b in _hoehen_mass.y:
		var z := bereich.position.y + float(b) * HOEHEN_ZELLE
		for a in _hoehen_mass.x:
			var h: float = hoehe.call(bereich.position.x + float(a) * HOEHEN_ZELLE, z)
			_hoehen_raster[i] = h if not is_nan(h) else -1000.0
			i += 1


## Höhe der Sichtlinie von `auge_` über das Gelände davor am Ort `ziel`
## (wald.gd:2690); −INF, wenn nichts davor liegt.
func _kammhoehe(auge_: Vector3, ziel: Vector3) -> float:
	var flach := Vector2(ziel.x - auge_.x, ziel.z - auge_.z)
	var weit := flach.length()
	if weit < 8.0:
		return -INF
	var dir := flach / weit
	var steil := -INF
	var t := 3.0
	# `_raster_hoehe` ausgeschrieben (dieselben Rechnungen, also dieselben
	# Werte): Die Himmelsprobe ruft sie in Level 05 rund 190 000-mal, der
	# Aufruf selbst kostete dort ein Drittel der Zeit (Paket P8, Bauzeit).
	var x0 := _hoehen_feld.position.x
	var z0 := _hoehen_feld.position.y
	var nx := _hoehen_mass.x
	var nz := _hoehen_mass.y
	while t < weit - 4.0:
		var fx := (auge_.x + dir.x * t - x0) / HOEHEN_ZELLE
		var fz := (auge_.z + dir.y * t - z0) / HOEHEN_ZELLE
		var a := floori(fx)
		var b := floori(fz)
		if a >= 0 and b >= 0 and a < nx - 1 and b < nz - 1:
			var u := fx - float(a)
			var v := fz - float(b)
			var i := b * nx + a
			var oben := lerpf(_hoehen_raster[i], _hoehen_raster[i + 1], u)
			var unten := lerpf(_hoehen_raster[i + nx], _hoehen_raster[i + nx + 1], u)
			var h := lerpf(oben, unten, v)
			if not is_nan(h):
				steil = maxf(steil, (h - auge_.y) / t)
		t += HOEHEN_ZELLE
	if steil == -INF:
		return -INF
	return auge_.y + steil * weit


## Geländehöhe aus dem Raster, zwischen den vier nächsten Punkten gemittelt
## (NAN außerhalb).
func _raster_hoehe(x: float, z: float) -> float:
	var fx := (x - _hoehen_feld.position.x) / HOEHEN_ZELLE
	var fz := (z - _hoehen_feld.position.y) / HOEHEN_ZELLE
	var a := floori(fx)
	var b := floori(fz)
	if a < 0 or b < 0 or a >= _hoehen_mass.x - 1 or b >= _hoehen_mass.y - 1:
		return NAN
	var u := fx - float(a)
	var v := fz - float(b)
	var i := b * _hoehen_mass.x + a
	var oben := lerpf(_hoehen_raster[i], _hoehen_raster[i + 1], u)
	var unten := lerpf(_hoehen_raster[i + _hoehen_mass.x], _hoehen_raster[i + _hoehen_mass.x + 1], u)
	return lerpf(oben, unten, v)


## Liegt Gelände über dem Strahl `von` + t · `dir` für t in [ab, bis]?
func _gelaende_im_strahl(von: Vector3, dir: Vector3, ab: float, bis: float) -> bool:
	var x0 := _hoehen_feld.position.x
	var z0 := _hoehen_feld.position.y
	var nx := _hoehen_mass.x
	var nz := _hoehen_mass.y
	var f := 1.0 / HOEHEN_ZELLE
	var t := ab
	while t < bis:
		var a := roundi((von.x + dir.x * t - x0) * f)
		var b := roundi((von.z + dir.z * t - z0) * f)
		if a >= 0 and b >= 0 and a < nx and b < nz \
				and _hoehen_raster[b * nx + a] > von.y + dir.y * t:
			return true
		t += HIMMEL_TRITT + t * 0.03
	return false
