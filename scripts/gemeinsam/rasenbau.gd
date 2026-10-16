extends RefCounted
class_name Rasenbau
## Rasen, Streu und Rahmenfarne an einem Weg – der Kern von Level 01 ohne
## dessen Abschnitte (Baukasten Raum 1, Paket G4; Herkunft scenes/levels/
## level01/rasen.gd, `L01Rasen`: Bau :182-278, Lage :340-366, Setzen
## :375-622, Decke und Boden :629-699, Rahmenfarne :1227-1334, Netze
## :1340-1462).
##
## WARUM EINE KOPIE. `L01Rasen` hält seinen Bau in einem statischen Merker
## (`_bau`) und kennt Level 01 bis in die Abschnitte (Waldsaum, Hangweg,
## Bachwiese, Wurzelrücken). Die Level 03–05 brauchen denselben Rasen nach
## der Wegmaske, dieselbe Streu und dieselben Rahmenfarne mit der K8-Probe,
## aber an ihren eigenen Stellen. Hier ist der Zustand die Instanz; das
## Level ruft je Strecke `decke()`, `boden()`, `streu()` und
## `rahmenfarne()` und am Ende einmal `fertig()`.
##
## WO ES WÄCHST (wie in Level 01):
##   decke        auf der Wegdecke nach der Wegmaske (`Wegmaske`): auf der
##                Spur nichts, daneben Rasenflecken ∝ m² (m = Rasenanteil),
##                an der Trittkante eine innere Reihe, gekippt zur Spur
##   boden        auf dem Gelände neben dem Weg (Höhe aus `hoehe`), lichter
##                im Wald (`wald`), nicht an steilen Stellen
##   streu        ein Stück an einer Stelle (Klee, Kiesel, Pilze, Blüten,
##                Farn, Großblatt, Polster, Büschel); dazu würfeln `decke`
##                und `boden` je Stelle Streu nach der Rate ihres Bereichs
##   rahmenfarne  alle 7–11 m ein großer Farn neben dem Weg, nach K8 geprüft
##                (die Kamera fährt die Strecke ab; kein Umrisspunkt kommt
##                näher als 0,4 an die Bildmitte)
## Um jede Kiste bleibt 1 m frei, hohes Gras und große Streu halten 1,5 m;
## nichts wächst in Sperren (`sperre`, `kreis`).
##
## KOSTEN wie in Level 01: je Stück von `STUECK` m je Art ein Netz, alles
## ohne Schatten, harte Sichtweiten. Mit `Effekte.reduziert` halbe Dichte,
## eine Graslage mit 20 statt 26 Halmen, die schon bei 32 m endet.
##
## ABWEICHUNGEN VOM PLAN (Baukasten §1.4), weil der Code sie verlangt:
##   - `decke` und `boden` nehmen freiwillig den Bereich der Streu (Raten
##     aus rasen.gd); `boden` folgt der Höhe aus `hoehe` statt nur dem
##     Boden auf Deckenhöhe (rasen.gd:688 kannte die Ränder von Level 01)
##     und lässt nur steile Stellen aus.
##   - `rahmenfarne(von, bis, seite, stoff)` nimmt freiwillig den Querbereich
##     (Vorgabe 6,5–8 m wie Level 01 in A); `stoff` null = Bodenstreu-Stoff.
##   - Dazu `sperre`/`kreis` (Stämme, Steine), `strecke_quer`, `lage` und
##     `k8_frei` mit der Kamera des Levels (Abstand, Höhe, Blickvorlauf).
##
## Was nicht hierher kam (bleibt Level 01 eigen): Böschung (`_hang` nach
## `GelaendeSaum.flaeche_punkt`), Lippen rechts (`L01Saum.lippe_q`),
## Wiesenhorste, Bachufer, Wurzelrücken und Moos auf der Borke.

## Länge der Stücke entlang s (m).
const STUECK := 16.0
## Kandidatenraster: zehn Stellen je m², jede wird gewürfelt.
const RASTER := 0.316
const DICHTE_MAX := 10.0
## Rasenflecken je m² als Vorgabe; gekippte Flecken an der Trittkante und
## Büschel als hohes Gras.
const DICHTE_SCHULTER := 6.0
const DICHTE_KANTE := 5.5
const DICHTE_HOCH := 2.5
## Freiraum um Kisten (m, von der Mitte): nichts / nichts Hohes.
const KISTE_FREI := 1.0
const KISTE_HOCH := 1.5
## Sichtweiten der Netze (m, zur Mitte des Stücks).
const SICHT_GRAS := 42.0
const SICHT_DICHT := 22.0
const SICHT_WISPEL := 38.0
const SICHT_STREU := 40.0
const SICHT_FARN := 44.0
## Die Spielkamera für K8, wenn keine angegeben ist (Level 01): so weit
## zurück, so hoch über der Figur, Blickpunkt so weit voraus.
const K8_ABSTAND := 9.5
const K8_HOEHE := 6.0
const K8_VORLAUF := 6.0
## Rahmenfarne bleiben aus den mittleren 40 % des Bildes (|x| < 0,4).
const K8_MITTE := 0.4
## Steiler als so viele Meter auf einen halben Meter: kein Gras (`boden`).
const STEIL := 0.3
## Bereiche (Raten der Streu, rasen.gd:127).
enum Bereich { WALD, SCHULTER, HANG, WIESE, WIESE_WEG, WURZEL, WANDFUSS }


## Was ein Stück (STUECK m entlang s) sammelt.
class Sammlung:
	extends RefCounted
	var gras: Array[Transform3D] = []
	var gras_farben := PackedColorArray()
	var bueschel: Array[Transform3D] = []
	var bueschel_farben := PackedColorArray()
	var wispel: Array[Transform3D] = []
	var wispel_farben := PackedColorArray()
	var polster: Array[Transform3D] = []
	var polster_farben := PackedColorArray()
	var farn: Array[Transform3D] = []
	var farn_farben := PackedColorArray()
	var gross: Array[Transform3D] = []
	var gross_farben := PackedColorArray()
	## Rahmenfarne je Stoff (Index in `Rasenbau._rahmen_stoffe`).
	var rahmen := {}
	var haufen: Bodenstreu.Haufen = null


## Querlage an der Strecke `s`: Wegmitte (Welt, y = Decke), rechts, vor,
## halbe Breite (in Lücken 0), Kronenlicht.
class Lage:
	extends RefCounted
	var s := 0.0
	var mitte := Vector3.ZERO
	var rechts := Vector3.RIGHT
	var vor := Vector3.FORWARD
	var halb := 0.0
	var kronen := 0.0

	func punkt(q: float) -> Vector3:
		return mitte + rechts * q


var weg: Wegdaten
## Callable(x, z) -> float: Geländehöhe neben dem Weg (NAN: kein Boden).
var hoehe: Callable
var rng := RandomNumberGenerator.new()
var reduziert := false
var dichte_faktor := 1.0
var sicht_gras := SICHT_GRAS
## Callable(s) -> float, Kronenlicht auf der Decke (leer: 0).
var kronenlicht: Callable = Callable()
## Callable(x, z) -> float, Walddichte 0..1 (leer: 0).
var wald: Callable = Callable()
## Kamera für K8: (abstand, hoehe, blick_vorlauf).
var k8 := Vector3(K8_ABSTAND, K8_HOEHE, K8_VORLAUF)

var _eltern: Node3D
var _name := "Rasen"
var _sammlungen := {}
## Kisten je Meter (floor(s)) als Vector2(s, q).
var _kisten := {}
## Sperren je Meter: Vector4(s, q, halbe Länge in s, halbe Breite in q)
## (Rechteck) oder mit w < 0: Kreis, Radius = −w.
var _sperren := {}
var _teile := {}
var _rahmen_netze: Array[ArrayMesh] = []
var _rahmen_umrisse: Array[PackedVector3Array] = []
var _rahmen_stoffe: Array[Material] = [null]
var _hoehen := {}
var _walder := {}


## `eltern`: dort entsteht beim `fertig()` der Knoten. Optionen (alle
## freiwillig):
##   dichte       Faktor auf alle Dichten (1,0; mit `Effekte.reduziert` ×0,5)
##   sichtweite   der Grasnetze (SICHT_GRAS; reduziert Rasensaum.SICHTWEITE_WEB)
##   kisten       Array[Vector3] Kisten in Welt (`KorridorLevel.kisten_orte`)
##   kronenlicht  Callable(s) -> float
##   wald         Callable(x, z) -> float
##   kamera       KorridorKamera für K8 (sonst die Werte von Level 01)
##   saat         Zufall (91017 wie Level 01)
##   name         Name des Knotens ("Rasen")
func _init(eltern: Node3D, weg_: Wegdaten, hoehe_: Callable, optionen: Dictionary = {}) -> void:
	_eltern = eltern
	weg = weg_
	hoehe = hoehe_
	rng.seed = int(optionen.get("saat", 91017))
	reduziert = Effekte.reduziert
	dichte_faktor = float(optionen.get("dichte", 1.0)) * (0.5 if reduziert else 1.0)
	sicht_gras = Rasensaum.SICHTWEITE_WEB if reduziert \
			else float(optionen.get("sichtweite", SICHT_GRAS))
	kronenlicht = optionen.get("kronenlicht", Callable())
	wald = optionen.get("wald", Callable())
	_name = String(optionen.get("name", "Rasen"))
	var kamera: KorridorKamera = optionen.get("kamera", null)
	if kamera != null:
		k8 = Vector3(kamera.abstand, kamera.hoehe, kamera.blick_vorlauf)
	for saat: int in [5, 9]:
		var netz := Farnwerk.rahmen(saat)
		_rahmen_netze.append(netz)
		_rahmen_umrisse.append(_umriss(netz))
	var kisten: Array = optionen.get("kisten", [])
	for p: Vector3 in kisten:
		var sq := strecke_quer(p)
		var k := floori(sq.x)
		if not _kisten.has(k):
			_kisten[k] = []
		(_kisten[k] as Array).append(sq)


## (s, q) eines Weltpunkts zur Kurve.
func strecke_quer(p: Vector3) -> Vector2:
	var s := weg.verlauf.get_closest_offset(p)
	var mitte := weg.verlauf.sample_baked(s)
	var rechts := LevelWerkzeuge.richtung(weg.verlauf, s).cross(Vector3.UP).normalized()
	var d := p - mitte
	d.y = 0.0
	return Vector2(s, d.dot(rechts))


## Nichts wächst im Rechteck um (s, q): halbe Länge entlang s, halbe Breite.
func sperre(s: float, q: float, laenge: float, breite: float) -> void:
	var v := Vector4(s, q, laenge, breite)
	for k in range(floori(s - laenge) - 2, floori(s + laenge) + 3):
		if not _sperren.has(k):
			_sperren[k] = []
		(_sperren[k] as Array).append(v)


## Nichts wächst im Kreis um (s, q).
func kreis(s: float, q: float, radius: float) -> void:
	var v := Vector4(s, q, radius, -radius)
	for k in range(floori(s - radius) - 2, floori(s + radius) + 3):
		if not _sperren.has(k):
			_sperren[k] = []
		(_sperren[k] as Array).append(v)


func _sammlung(s: float) -> Sammlung:
	var i := floori(s / STUECK)
	if not _sammlungen.has(i):
		_sammlungen[i] = Sammlung.new()
	return _sammlungen[i]


func _haufen(s: float) -> Bodenstreu.Haufen:
	var sa := _sammlung(s)
	if sa.haufen == null:
		var mitte := (floorf(s / STUECK) + 0.5) * STUECK
		sa.haufen = Bodenstreu.Haufen.new(weg.weg_punkt(mitte))
	return sa.haufen


## Geländehöhe in einer Zelle von 0,5 m (für Abbruchproben).
func _hoehe_zelle(p: Vector3) -> float:
	var k := Vector2i(floori(p.x * 2.0), floori(p.z * 2.0))
	if not _hoehen.has(k):
		_hoehen[k] = float(hoehe.call((float(k.x) + 0.5) * 0.5, (float(k.y) + 0.5) * 0.5))
	return _hoehen[k]


## Walddichte in einer Zelle von 1 m (0 ohne `wald`).
func _wald(p: Vector3) -> float:
	if not wald.is_valid():
		return 0.0
	var k := Vector2i(floori(p.x), floori(p.z))
	if not _walder.has(k):
		_walder[k] = float(wald.call(float(k.x) + 0.5, float(k.y) + 0.5))
	return _walder[k]


## Abstand zur nächsten Kiste in (s, q) (INF, wenn keine nah ist).
func _kiste_abstand(s: float, q: float) -> float:
	var beste := INF
	for k in range(floori(s) - 2, floori(s) + 3):
		if not _kisten.has(k):
			continue
		for v: Vector2 in _kisten[k]:
			beste = minf(beste, Vector2(s, q).distance_to(v))
	return beste


## Abstand zur nächsten Sperre (negativ: darin); INF, wenn keine nah ist.
func _sperr_abstand(s: float, q: float) -> float:
	var k := floori(s)
	if not _sperren.has(k):
		return INF
	var beste := INF
	for v: Vector4 in _sperren[k]:
		var d: float
		if v.w < 0.0:
			d = Vector2(s, q).distance_to(Vector2(v.x, v.y)) + v.w
		else:
			var ds := absf(s - v.x) - v.z
			var dq := absf(q - v.y) - v.w
			d = Vector2(maxf(ds, 0.0), maxf(dq, 0.0)).length() + minf(maxf(ds, dq), 0.0)
		beste = minf(beste, d)
	return beste


## Querlage an `s` (rasen.gd:353).
func lage(s: float) -> Lage:
	var l := Lage.new()
	var kurve := weg.verlauf
	l.s = s
	var a := LevelWerkzeuge.punkt_frei(kurve, s, 0.0)
	var r := LevelWerkzeuge.punkt_frei(kurve, s, 1.0) - a
	r.y = 0.0
	l.rechts = r.normalized()
	l.vor = Vector3.UP.cross(l.rechts).normalized()
	a.y = weg.boden_bei(s)
	l.mitte = a
	l.halb = weg.breite_bei(s) * 0.5
	l.kronen = float(kronenlicht.call(s)) if kronenlicht.is_valid() else 0.0
	return l


# =========================================================== Strecken

## Die Wegdecke einer Seite (`seite` −1 links, +1 rechts) von `von` bis
## `bis`: Rasen nach der Maske, `dichte` Flecken je m² (Vorgabe
## DICHTE_SCHULTER), die innere Reihe an der Trittkante gekippt.
func decke(von: float, bis: float, seite: float, dichte: float = DICHTE_SCHULTER,
		bereich: int = Bereich.SCHULTER) -> void:
	var s := von
	while s < bis:
		_decke(lage(s), seite, dichte, bereich)
		s += RASTER


## Das Gelände neben dem Weg auf einer Seite von |q| `q_von` bis `q_bis`
## (q ab der Wegmitte), von `von` bis `bis`: voller Rasen nach der Höhe aus
## `hoehe`, lichter im Wald, kein Gras an steilen Stellen; ab der
## Walddichte 0,35 die Streu des Waldes (`wald_bereich`).
func boden(von: float, bis: float, seite: float, q_von: float, q_bis: float,
		dichte: float = DICHTE_SCHULTER, bereich: int = Bereich.SCHULTER,
		wald_bereich: int = Bereich.WALD) -> void:
	var s_lauf := von
	while s_lauf < bis:
		var l := lage(s_lauf)
		s_lauf += RASTER
		var q_lauf := q_von
		while q_lauf < q_bis:
			var q := seite * (q_lauf + rng.randf() * RASTER)
			q_lauf += RASTER
			var s := l.s + rng.randf_range(-0.14, 0.14)
			var p := l.punkt(q)
			var y: float = hoehe.call(p.x, p.z)
			if is_nan(y):
				continue
			if absf(_hoehe_zelle(l.punkt(q + seite * 0.5)) - y) > STEIL:
				continue
			p.y = y
			var w := _wald(p)
			var aussen := absf(q) - l.halb
			var ao := lerpf(Wegmaske.RAND_VERDECKUNG, 1.0, smoothstep(0.0, 2.5, aussen)) \
					* lerpf(1.0, 0.38, w)
			var g := 1.0 - smoothstep(0.15, 0.6, w)
			_stelle(s, q, p, 1.0, ao, l.kronen, dichte * g, 0.0,
					bereich if w < 0.35 else wald_bereich)


## Ein Stück Streu an (s, q), auf der Decke oder dem Gelände: "klee",
## "kiesel", "pilz", "pilz_leucht", "bluete" (Gruppe), "farn", "grossblatt",
## "polster", "bueschel" (hohes Gras). `mass` skaliert das Stück.
func streu(s: float, q: float, art: String, mass: float = 1.0) -> void:
	var l := lage(s)
	var p := l.punkt(q)
	if absf(q) > l.halb:
		var y: float = hoehe.call(p.x, p.z)
		if is_nan(y):
			return
		p.y = y
	match art:
		"klee", "kiesel", "pilz", "pilz_leucht":
			_teil(s, p, art, mass)
		"bluete":
			_bluetengruppe(s, p, Bereich.WIESE, mass)
		"farn":
			_farn(s, p, mass)
		"grossblatt":
			_grossblatt(s, p, mass)
		"polster":
			_polster(s, p, mass, l.kronen)
		"bueschel":
			var sa := _sammlung(s)
			sa.bueschel.append(_bueschel_lage(p - Vector3(0.0, 0.012, 0.0), 0.5 * mass, Vector3.ZERO))
			sa.bueschel_farben.append(Rasensaum.farbe(0.86, 1.0, rng.randf_range(0.3, 0.9),
					l.kronen))
		_:
			push_warning("Rasenbau.streu: unbekannte Art „%s“" % art)


## Rahmenfarne auf einer Seite von `von` bis `bis` (rasen.gd:1227): je 7–11
## m einer bei |q| `q_von` … `q_bis` auf dem Gelände (höchstens 1 m über
## oder unter der Decke), quer zum Weg gestaucht. K8 wird gerechnet: Die
## Kamera fährt die Strecke ab, auf der er rahmt (Figur 0,5 m hinter bis
## 3,5 m vor ihm); passt er nicht, wird er kleiner, rückt nach außen oder
## entfällt. `stoff`: eigener Farnstoff (null: der von `Bodenstreu`).
func rahmenfarne(von: float, bis: float, seite: float, stoff: Material = null,
		q_von: float = 6.5, q_bis: float = 8.0) -> void:
	var stoff_index := _rahmen_stoffe.find(stoff)
	if stoff_index < 0:
		_rahmen_stoffe.append(stoff)
		stoff_index = _rahmen_stoffe.size() - 1
	var s := von + rng.randf_range(0.0, 4.0)
	while s < bis:
		var l := lage(s)
		var q_wahl := rng.randf_range(q_von, q_bis)
		var drehung := rng.randf() * TAU
		var stauchen := rng.randf_range(0.55, 0.72)
		var mass_wunsch := rng.randf_range(0.9, 1.25)
		var farbe := _laub(1.3)
		var nummer := posmod(floori(s / STUECK), 2)
		var umriss: PackedVector3Array = _rahmen_umrisse[nummer]
		var gesetzt := false
		for versuch in 3:
			var p := l.punkt(seite * (q_wahl + float(versuch) * 0.8))
			var y: float = hoehe.call(p.x, p.z)
			if is_nan(y) or absf(y - l.mitte.y) > 1.0:
				continue
			p.y = y - 0.05
			var q_ist := (p - l.mitte).dot(l.rechts)
			if _kiste_abstand(s, q_ist) <= 2.0 or _sperr_abstand(s, q_ist) <= 0.6:
				continue
			var rahmen := Basis(l.rechts, Vector3.UP, l.rechts.cross(Vector3.UP))
			var form := rahmen * Basis.from_scale(Vector3(stauchen, 1.0, 1.12)) * rahmen.transposed()
			var mass := mass_wunsch
			while mass >= 0.6:
				var lage_ := Transform3D(form * Basis(Vector3.UP, drehung)
						* Basis.from_scale(Vector3.ONE * mass), p)
				if k8_frei(s, lage_, umriss):
					var sa := _sammlung(s)
					var schluessel := Vector2i(stoff_index, nummer)
					if not sa.rahmen.has(schluessel):
						var leer: Array[Transform3D] = []
						sa.rahmen[schluessel] = {"lagen": leer, "farben": PackedColorArray()}
					var eintrag: Dictionary = sa.rahmen[schluessel]
					var lagen: Array[Transform3D] = eintrag["lagen"]
					lagen.append(lage_)
					var farben: PackedColorArray = eintrag["farben"]
					farben.append(farbe)
					eintrag["farben"] = farben
					gesetzt = true
					break
				mass -= 0.1
			if gesetzt:
				break
		s += rng.randf_range(7.0, 11.0)


## K8 für einen Farn an `s_farn` in `lage_` (Umriss im Netzraum): Die
## Kamera (`k8`) folgt der Figur von 0,5 m hinter bis 3,5 m vor dem Farn,
## Blickpunkt `vorlauf` voraus auf Figurhöhe + 1 m, 60° senkrecht bei 16:9
## (rasen.gd:1282). Kein sichtbarer Umrisspunkt darf näher als K8_MITTE an
## die Bildmitte.
func k8_frei(s_farn: float, lage_: Transform3D, umriss: PackedVector3Array) -> bool:
	var kurve := weg.verlauf
	var laenge := kurve.get_baked_length()
	var tan_v := tan(deg_to_rad(30.0))
	var tan_h := tan_v * 16.0 / 9.0
	var welt := PackedVector3Array()
	for u in umriss:
		welt.append(lage_ * u)
	var s_fig := s_farn - 0.5
	while s_fig <= s_farn + 3.51:
		var fig_y := weg.boden_bei(s_fig)
		var mitte := kurve.sample_baked(clampf(s_fig, 0.0, laenge))
		var kam := kurve.sample_baked(clampf(s_fig - k8.x, 0.0, laenge))
		kam.y += fig_y - mitte.y + k8.y
		var blick := kurve.sample_baked(clampf(s_fig + k8.z, 0.0, laenge))
		blick.y = fig_y + 1.0
		var vorn := (blick - kam).normalized()
		var rechts := vorn.cross(Vector3.UP).normalized()
		var oben := rechts.cross(vorn)
		for w in welt:
			var d := w - kam
			var tiefe := d.dot(vorn)
			if tiefe < 0.3:
				continue
			var x := d.dot(rechts) / (tiefe * tan_h)
			var y := d.dot(oben) / (tiefe * tan_v)
			if absf(y) <= 1.0 and absf(x) < K8_MITTE:
				return false
		s_fig += 1.0
	return true


# =========================================================== Setzen

## Gras (und vielleicht Streu) an der Stelle `p` (rasen.gd:375).
func _stelle(s: float, q: float, p: Vector3, m: float, ao: float, kronen: float,
		dichte: float, hoch: float, bereich: int, kipp: Vector3 = Vector3.ZERO,
		kante: float = 0.0) -> void:
	var kiste := _kiste_abstand(s, q)
	if kiste < KISTE_FREI:
		return
	var sperr := _sperr_abstand(s, q)
	if sperr < 0.05:
		return
	if sperr < 0.55:
		hoch = maxf(hoch, 1.0 - sperr / 0.55)
	if kiste < KISTE_HOCH:
		hoch = 0.0
	var wurf := rng.randf() * DICHTE_MAX
	var fleck := dichte * dichte_faktor
	var bueschel := (kante + DICHTE_HOCH * hoch) * dichte_faktor
	if wurf < fleck + bueschel:
		var w := Wegmaske.welt(Vector2(p.x, p.z))
		var feld := smoothstep(0.25, 0.8, w.g * 0.55 + w.b * 0.45)
		var h := lerpf(0.15, 0.34, feld) * rng.randf_range(0.8, 1.2)
		h *= lerpf(0.6, 1.0, smoothstep(0.3, 0.9, m))
		if bereich == Bereich.WIESE:
			h *= 1.15
		elif bereich == Bereich.WURZEL:
			h *= 0.55
		var sa := _sammlung(s)
		var farbe := Rasensaum.farbe(ao, m, rng.randf_range(0.25, 0.75), kronen)
		if wurf < fleck + kante * dichte_faktor:
			var k := kipp if wurf >= fleck else Vector3.ZERO
			sa.gras.append(_bueschel_lage(p - Vector3(0.0, 0.012, 0.0), h, k))
			sa.gras_farben.append(farbe)
		else:
			if hoch > 0.0 and rng.randf() < hoch:
				h = rng.randf_range(0.45, 0.6)
			sa.bueschel.append(_bueschel_lage(p - Vector3(0.0, 0.012, 0.0), h, kipp))
			sa.bueschel_farben.append(farbe)
	_streu_zufall(s, p, m, bereich, kiste, sperr, kronen)


## Lage eines Büschels der Höhe `h` (rasen.gd:421).
func _bueschel_lage(fuss: Vector3, h: float, kipp: Vector3) -> Transform3D:
	var mass := h / Rasensaum.BEZUG
	var quer := lerpf(1.0, mass, 0.5) * rng.randf_range(0.85, 1.2)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(quer, mass, quer))
	var winkel := kipp.length()
	if winkel > 0.001:
		var achse := Vector3.UP.cross(kipp / winkel).normalized()
		basis = Basis(achse, winkel) * basis
	else:
		basis = Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(),
				rng.randf_range(0.0, 0.12)) * basis
	return Transform3D(basis, fuss)


## Streu an einer Kandidatenstelle (0,1 m²): je Art gewürfelt nach der Rate
## des Bereichs (je m², rasen.gd:439).
func _streu_zufall(s: float, p: Vector3, m: float, bereich: int, kiste: float, sperr: float,
		kronen: float) -> void:
	var f := 0.1 * dichte_faktor
	var r_klee := 0.0
	var r_bluete := 0.0
	var r_kiesel := 0.0
	var r_pilz := 0.0
	var r_moos := 0.0
	var r_farn := 0.0
	var r_gross := 0.0
	var leucht := 0.0
	match bereich:
		Bereich.WALD:
			r_klee = 0.02
			r_bluete = 0.01
			r_pilz = 0.02
			r_moos = 0.035
			r_farn = 0.1
			leucht = 0.6
		Bereich.SCHULTER:
			r_klee = 0.035
			r_bluete = 0.05
			r_kiesel = 0.012 + 0.08 * (1.0 - smoothstep(0.35, 0.7, m)) * smoothstep(0.1, 0.3, m)
			r_pilz = 0.003
		Bereich.HANG:
			r_klee = 0.01
			r_bluete = 0.025
			r_moos = 0.02
			r_farn = 0.06
			r_pilz = 0.004
		Bereich.WIESE:
			r_klee = 0.06
			r_bluete = 0.22
			r_farn = 0.004
		Bereich.WIESE_WEG:
			r_klee = 0.05
			r_bluete = 0.06
			r_kiesel = 0.05 * (1.0 - smoothstep(0.35, 0.7, m)) * smoothstep(0.1, 0.3, m)
		Bereich.WURZEL:
			r_moos = 0.12
			r_farn = 0.05
			r_pilz = 0.015
			r_bluete = 0.025
			leucht = 0.85
		Bereich.WANDFUSS:
			r_moos = 0.05
			r_farn = 0.05
			r_gross = 0.03
			r_pilz = 0.01
			r_bluete = 0.01
	var gross_frei := kiste >= KISTE_HOCH and sperr > 0.3
	if m > 0.75 and rng.randf() < r_klee * f:
		_teil(s, p, "klee", rng.randf_range(0.8, 1.25))
	if m > 0.8 and gross_frei and rng.randf() < r_bluete * f:
		_bluetengruppe(s, p, bereich)
	if rng.randf() < r_kiesel * f:
		_teil(s, p, "kiesel", rng.randf_range(0.7, 1.3))
	if gross_frei and rng.randf() < r_pilz * f:
		_teil(s, p, "pilz_leucht" if rng.randf() < leucht else "pilz", rng.randf_range(0.8, 1.3))
	if rng.randf() < r_moos * f:
		_polster(s, p, rng.randf_range(0.7, 1.4), kronen)
	if gross_frei and rng.randf() < r_farn * f:
		_farn(s, p, rng.randf_range(0.7, 1.3))
	if gross_frei and rng.randf() < r_gross * f:
		_grossblatt(s, p, rng.randf_range(0.8, 1.2))


## Ein Teil aus dem Vorrat (je Art sechs Formen) in den Haufen des Stücks.
func _teil(s: float, p: Vector3, art: String, mass: float, farbe: Color = Color.WHITE) -> void:
	var formen := _formen(art)
	var t: Bodenstreu.Teil = formen[rng.randi() % formen.size()]
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	_haufen(s).teil(t, Transform3D(basis, p), farbe)


func _formen(art: String) -> Array:
	if _teile.has(art):
		return _teile[art]
	var formen := []
	var frng := PropWerkzeug.zufall((hash(art) & 0xffff) + 17)
	for i in 6:
		match art:
			"klee":
				formen.append(Bodenstreu.klee(frng, frng.randf_range(0.22, 0.42), i < 2))
			"kiesel":
				formen.append(Bodenstreu.kiesel(frng, frng.randf_range(0.1, 0.2), frng.randi_range(1, 4)))
			"pilz":
				formen.append(Bodenstreu.pilze(frng, frng.randf_range(0.035, 0.06), frng.randi_range(1, 4)))
			"pilz_leucht":
				formen.append(Bodenstreu.pilze(frng, frng.randf_range(0.025, 0.045),
						frng.randi_range(2, 5), true))
	_teile[art] = formen
	return formen


## Eine Blütengruppe: Art und Farbe nach Bereich (rasen.gd:537).
func _bluetengruppe(s: float, p: Vector3, bereich: int, mass: float = 1.0) -> void:
	var moeglich: Array[Vector2i] = []
	match bereich:
		Bereich.WALD:
			moeglich = [Vector2i(0, 0)]
		Bereich.WURZEL:
			moeglich = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
		Bereich.HANG, Bereich.WANDFUSS:
			moeglich = [Vector2i(2, 2), Vector2i(2, 2), Vector2i(0, 0), Vector2i(2, 3)]
		Bereich.WIESE, Bereich.WIESE_WEG:
			moeglich = [Vector2i(1, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(0, 0),
					Vector2i(2, 2), Vector2i(0, 4), Vector2i(2, 3)]
		_:
			moeglich = [Vector2i(1, 1), Vector2i(0, 0), Vector2i(2, 2), Vector2i(1, 1)]
	var wahl := moeglich[rng.randi() % moeglich.size()]
	var schluessel := "bluete_%d_%d" % [wahl.x, wahl.y]
	if not _teile.has(schluessel):
		var formen := []
		var frng := PropWerkzeug.zufall(wahl.x * 31 + wahl.y * 7 + 5)
		for i in 4:
			formen.append(Bodenstreu.blueten(frng, wahl.x, Bodenstreu.BLUETEN_FARBEN[wahl.y],
					frng.randf_range(0.18, 0.32)))
		_teile[schluessel] = formen
	_teil(s, p, schluessel, rng.randf_range(0.85, 1.2) * mass)


## Ein Moospolster im Stoff des Rasens (rasen.gd:568, ohne Wurzelrücken).
func _polster(s: float, p: Vector3, mass: float, kronen: float) -> void:
	var sa := _sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) \
			* Basis.from_scale(Vector3(mass, mass * rng.randf_range(0.6, 1.1), mass))
	sa.polster.append(Transform3D(basis, p - Vector3(0.0, 0.015, 0.0)))
	sa.polster_farben.append(Rasensaum.farbe(0.85, 1.0, rng.randf_range(0.2, 0.7), kronen))


## Ein kleiner Farn ins Feld des Stücks.
func _farn(s: float, p: Vector3, mass: float) -> void:
	var sa := _sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	sa.farn.append(Transform3D(basis, p - Vector3(0.0, 0.03, 0.0)))
	sa.farn_farben.append(_laub(1.0))


func _grossblatt(s: float, p: Vector3, mass: float) -> void:
	var sa := _sammlung(s)
	var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * mass)
	sa.gross.append(Transform3D(basis, p - Vector3(0.0, 0.03, 0.0)))
	sa.gross_farben.append(_laub(1.1) * Color(0.95, 1.0, 0.85))


## Laubgrün (linear) mit ±12 % Streuung, `hell` als Faktor.
func _laub(hell: float) -> Color:
	var g := Farben.LAUB.srgb_to_linear()
	var t := rng.randf_range(0.85, 1.15) * hell
	return Color(g.r * t * rng.randf_range(0.9, 1.15), g.g * t, g.b * t * rng.randf_range(0.85, 1.1))


## Die Wegdecke einer Seite an der Lage `l` (rasen.gd:629).
func _decke(l: Lage, seite: float, dichte: float, bereich: int, lippe: float = INF) -> void:
	if l.halb <= 0.0:
		return
	var pendel := Wegmaske.pendel(l.s)
	var k := 0
	while true:
		var q := seite * (float(k) + rng.randf()) * RASTER
		k += 1
		if absf(q) > l.halb:
			break
		var s := l.s + rng.randf_range(-0.14, 0.14)
		var p := l.punkt(q)
		var w := Wegmaske.welt(Vector2(p.x, p.z))
		var qn := q / l.halb
		var m := Wegmaske.wert_aus(qn, s, w.r)
		if m < 0.2:
			continue
		var kante := smoothstep(0.25, 0.45, m) * (1.0 - smoothstep(0.55, 0.75, m))
		var zur_spur := -signf(qn - pendel)
		var kipp := l.rechts * zur_spur * deg_to_rad(rng.randf_range(25.0, 40.0))
		var hoch := 1.0 - smoothstep(0.1, 0.8, lippe - absf(q))
		_stelle(s, q, p, m, Wegmaske.verdeckung(qn), l.kronen, dichte * m * m, hoch, bereich,
				kipp, DICHTE_KANTE * kante)


## Der Umriss eines Netzes für `k8_frei` (rasen.gd:1316).
static func _umriss(netz: Mesh) -> PackedVector3Array:
	var weiteste: Array[Vector3] = []
	weiteste.resize(24)
	weiteste.fill(Vector3.ZERO)
	var hoechste: Array[Vector3] = []
	hoechste.resize(24)
	hoechste.fill(Vector3.ZERO)
	for f in netz.get_surface_count():
		var ecken: PackedVector3Array = netz.surface_get_arrays(f)[Mesh.ARRAY_VERTEX]
		for e in ecken:
			var r := Vector2(e.x, e.z).length()
			var fach := posmod(floori((atan2(e.z, e.x) + PI) / TAU * 24.0), 24)
			if r > Vector2(weiteste[fach].x, weiteste[fach].z).length():
				weiteste[fach] = e
			if e.y > hoechste[fach].y:
				hoechste[fach] = e
	var umriss := PackedVector3Array(weiteste)
	umriss.append_array(PackedVector3Array(hoechste))
	return umriss


# =========================================================== Netze

## Legt je Stück die Netze an (rasen.gd:1340) und gibt den Knoten zurück.
## Danach ist der Bau leer; ein zweiter Aufruf baut nichts mehr.
func fertig() -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = _name
	_eltern.add_child(wurzel)
	var schluessel := _sammlungen.keys()
	schluessel.sort()
	var farn_netze: Array[ArrayMesh] = [Farnwerk.klein(3), Farnwerk.klein(8), Farnwerk.klein(13)]
	var gross_rng := PropWerkzeug.zufall(4411)
	var gross_netze: Array[ArrayMesh] = [Bodenstreu.grossblatt(gross_rng, 1.0).netz(),
			Bodenstreu.grossblatt(gross_rng, 1.0).netz()]
	var sicht_wispel := minf(SICHT_WISPEL, sicht_gras)
	var sicht_streu := minf(SICHT_STREU, sicht_gras)
	var halme := 20 if reduziert else 26
	for i: int in schluessel:
		var sa: Sammlung = _sammlungen[i]
		var n := posmod(i, 3)
		var weit: Array[Transform3D] = []
		var weit_farben := PackedColorArray()
		var nah: Array[Transform3D] = []
		var nah_farben := PackedColorArray()
		for k in sa.gras.size():
			if k % 2 == 0 or reduziert:
				weit.append(sa.gras[k])
				weit_farben.append(sa.gras_farben[k])
			else:
				nah.append(sa.gras[k])
				nah_farben.append(sa.gras_farben[k])
		Rasensaum.feld(wurzel, "Gras %d" % i, Rasensaum.fleck(11 + n, halme), weit, weit_farben,
				sicht_gras)
		Rasensaum.feld(wurzel, "Gras nah %d" % i, Rasensaum.fleck(14 + n, halme), nah, nah_farben,
				SICHT_DICHT)
		Rasensaum.feld(wurzel, "Bueschel %d" % i, Rasensaum.bueschel(31 + n), sa.bueschel,
				sa.bueschel_farben, sicht_gras)
		Rasensaum.feld(wurzel, "Wispel %d" % i, Rasensaum.wispel(21 + n), sa.wispel,
				sa.wispel_farben, sicht_wispel)
		Rasensaum.feld(wurzel, "Moos %d" % i, Rasensaum.polster(41 + n), sa.polster,
				sa.polster_farben, sicht_streu)
		if sa.haufen != null:
			sa.haufen.knoten(wurzel, "Streu %d" % i, sicht_streu)
		Bodenstreu.feld(wurzel, "Farne %d" % i, farn_netze[n], sa.farn, sa.farn_farben, SICHT_FARN)
		Bodenstreu.feld(wurzel, "Grossblatt %d" % i, gross_netze[posmod(i, 2)], sa.gross,
				sa.gross_farben, SICHT_FARN)
		for rs: Vector2i in sa.rahmen:
			var eintrag: Dictionary = sa.rahmen[rs]
			var lagen: Array[Transform3D] = eintrag["lagen"]
			Bodenstreu.feld(wurzel, "Rahmenfarne %d %d" % [i, rs.x], _rahmen_netze[rs.y], lagen,
					eintrag["farben"] as PackedColorArray, SICHT_FARN, _rahmen_stoffe[rs.x])
	_sammlungen.clear()
	return wurzel
