extends RefCounted
class_name L01Wald
## Level 01, Modul „Wald": der Wald in drei Tiefen (Plan Abschnitte 5, 7, 9,
## 11, 13). Gesetzt mit `Waldsetzer` (scripts/waldsetzer.gd), gebaut aus
## den prozeduralen Helden (`Riesenstamm`, `Kronenwolke`, `Farnwerk`,
## `Findling`) und, wo es sie gibt, aus Fremdmodellen (Felsen, M8).
##
## WAS HIER WÄCHST
##   Hallenwald  A (s −16 … 34): drei Stammreihen je Seite (|q| 7–10, 12–16,
##               18–24) und zwei lockere dahinter, Stämme 12–21 m, Ø 0,5 bis
##               2 m, versetzt, jeder achte schief; drei Heldenstämme mit
##               Brettwurzeln (die Wurzeln zeigen vom Weg weg), ein
##               gestürzter Stamm quer durch die Reihen, Farne am Fuß,
##               Stümpfe, Moosstämme und Felsen am Saum. Die erste Reihe
##               neigt sich zum Weg und schließt über ihm das Dach – erst ab
##               9,5 m, mit Löchern über `Level01.LICHTLOECHER`. Rechts endet
##               der Wald an der Hallenkante (die Enthüllung).
##   Hangwald    links über der Böschung und auf der Krone der Fallklamm
##               (s 30–165), wo das Gelände Wald trägt (`L01Gelaende.wald`):
##               vorn volle Stämme, deren Kronen sich über das linke
##               Wegdrittel neigen (dunkler Rahmen oben links), dahinter
##               schlichte Stämme.
##   Rahmen      die Bäume auf den Felsnadeln unter der Kante
##               (`RAHMENBAUM_STELLEN` "sims"): gedreht, nach außen geneigt,
##               nie im Sichtkegel zum Weltenbaum.
##   Riesen      zwei Torriesen am Riesentor (`TORRIESEN`), drei Talriesen
##               rechts der Bachwiese (`TALRIESEN`), zwei Kanalbäume über C4
##               (sie schließen dort das Dach) und drei Überständer im Tal.
##   Talwald     nah (bis `NAH_WEIT` vom Weg): Kronen mit Blattkarten auf
##               schlichten Stämmen, auf den Riegeln dunkler, Nadelbäume
##               dunkler und kühler, Lichtungen, wo das Gelände Wiese ist;
##               fern: flache Kronen mit angedeutetem Stamm, je Zelle ein
##               Netz, bis 200 m. Dazu graue Totholzstämme.
##   Hecken      rechts der Bachwiese (q 7–9) und um die Wurzelwiese, grün
##               mit blühenden Sträuchern dazwischen.
##
## REGELN (Plan 7, 11)
##   K1  Über |q| < 6 hängt keine Krone tiefer als 9,5 m über der Decke
##       (Hülle der gesetzten Krone gegen jede Wegprobe, `_weg_frei`); kein
##       Stamm steht dort unter 8,8 m (`_stamm_frei`).
##   Kegel  Kein Baum im ±6°-Kegel von der Kamera zur Krone des
##       Weltenbaums, je Station s 22–114 (davor verdeckt ihn der
##       Hallenwald); im Schlussbild (s 274–287) keiner im ±3°-Kegel zum
##       Wasserfall (`Waldsetzer.kegel_frei`).
##   Kante  Talkronen bleiben unter der Felskante von B und C mindestens
##       5 m unter der Decke (`_talkante_frei`).
##   Weg  Kein Stamm und keine Brettwurzel auf begehbarem Boden; Wurzeln
##       werden vom Weg weggedreht (`Waldsetzer.drehung_weg`).
##   Keine Kollision: Alles steht hinter Leitlinien, im Tal oder über dem
##       Kamerastrahl.
##
## KOSTEN (Plan 13: ≤ 70 Zeichenaufrufe, dazu ≤ 40 für Schatten, ≤ 240k
## Dreiecke samt Schatten je Station). Bäume werden je Zelle zu EINEM Netz
## je Stoff verschmolzen (Stämme mit Schatten, Kronen ohne); Farne und
## Felsen als MultiMesh. Harte Sichtweiten je Zelle (`SICHT_*`). Mit
## `Effekte.reduziert` (Web, Handy) wächst der ferne Wald zu 60 %.

# ================================================================ Maße

## Freiraum über dem Weg (Plan K1): so weit quer, ab dieser Höhe.
const FREI_Q := 6.0
const FREI_H := 9.5
## Unter dieser Höhe steht über |q| < 6 kein Stamm (Schluchtsaum.KAMERA_FREI).
const STAMM_FREI_H := 8.8
## Talkronen unter der Felskante (B, C): höchstens so hoch unter der Decke.
const KANTE_TIEFE := 5.0
## So weit reicht die Kantenregel quer über die Lippe hinaus.
const KANTE_WEITE := 14.0
## Bis zu dieser Entfernung vom Weg (waagerecht) steht der nahe Talwald,
## dahinter der ferne.
const NAH_WEIT := 42.0
## Näher als das kommt der ferne Wald dem Weg nicht (dort pflanzen die
## nahen Schritte).
const FERN_AB := 26.0
## So weit hinter der Kronenkante pflanzt der Hangwald; dahinter der ferne.
const HANG_TIEFE := 18.0
## So weit quer reicht der Hallenwald (drei Reihen); dahinter der ferne.
const HALLE_TIEFE := 25.0

## Sichtweiten bis zur Zellmitte (m).
const SICHT_HALLE := 120.0
const SICHT_HANG := 130.0
const SICHT_RAHMEN := 170.0
const SICHT_TAL := 105.0
const SICHT_FERN := 200.0
const SICHT_FARN := 42.0
const SICHT_FELS := 110.0
const SICHT_HECKE := 90.0
const SICHT_KRANZ := 60.0
## Die Riesen stehen als eine Zelle um s 170: vom Grat ab gut s 40 zu sehen.
const SICHT_RIESEN := 150.0
## Zellgrößen (m).
const ZELLE_HANG := 45.0
const ZELLE_TAL := 48.0
const ZELLE_FERN := 64.0
## Rasterweite des fernen Walds (m): Kronen von 5 m Radius schließen sich.
const FERN_RASTER := 10.5

## Laubfarben (Grundton des Stoffs; getönt wird je Baum über die Farbe).
const LAUB_HALLE := Color(0.15, 0.33, 0.14)
const LAUB_TAL := Color(0.21, 0.45, 0.16)
const LAUB_FERN := Color(0.2, 0.42, 0.17)
const LAUB_HECKE := Color(0.19, 0.41, 0.15)
const BLUETE := Color(0.93, 0.76, 0.8)
const FARN := Color(0.2, 0.42, 0.15)
## Tönung der Nadelbäume: dunkler und kühler.
const NADEL_TON := Color(0.6, 0.72, 0.76)
## Tönung des Totholzes: grau, ausgeblichen.
const TOT_TON := Color(0.82, 0.8, 0.78, 0.25)

## Die Hallenwald-Reihen je Seite: Querbereich, Abstand entlang s, Arten.
const REIHEN := [
	{"q": Vector2(7.0, 10.0), "abstand": Vector2(5.5, 7.5), "arten": ["dach", "dach", "hoch", "duenn"]},
	{"q": Vector2(12.0, 16.0), "abstand": Vector2(6.0, 8.0),
			"arten": ["duenn", "schlicht_a", "schlicht_b", "schlicht_a", "schlicht_c"]},
	{"q": Vector2(18.0, 24.0), "abstand": Vector2(6.5, 9.0),
			"arten": ["schlicht_a", "schlicht_b", "schlicht_c"]},
]
## Anfang des Hallenwalds (hinter dem Start) und Ende links (Übergang in den
## Hangwald).
const HALLE_VON := -16.0
const HALLE_LINKS_BIS := 36.0
## Heldenstämme mit Brettwurzeln: (s, q).
const HELDEN := [Vector2(10.6, -8.4), Vector2(19.2, 8.6), Vector2(30.6, -8.8)]
## Stellen, an denen schon etwas steht (Wegbauten): (s, q, Radius).
const BESETZT := [Vector3(3.4, -9.0, 3.0), Vector3(2.6, 9.0, 3.0), Vector3(28.0, 7.0, 3.5),
		Vector3(31.0, 6.5, 2.5), Vector3(8.0, 0.0, 5.0)]
## Der Erdspalt läuft je Seite fünf Meter über die Leitlinien in den Waldboden.
const ERDSPALT := Vector4(24.3, 28.2, 11.5, 0.0)
## Kanalbäume über C4: (s, q, Höhe, Neigung zum Weg in m).
const KANALBAEUME := [Vector4(149.5, 15.5, 27.0, 3.2), Vector4(156.5, 17.5, 28.0, 3.6)]
## Überständer im Tal: Zielorte (Welt-XZ), gesetzt an der nächsten
## geeigneten Stelle.
const UEBERSTAENDER := [Vector2(78.0, -52.0), Vector2(104.0, -100.0), Vector2(58.0, -104.0)]

# ================================================================ Zustand

## Der Verlauf als Proben alle Meter: Punkt (y = Decke), Rechtsvektor,
## halbe Wegbreite; dazu Eimer zu 10 m für die Suche.
static var _bahn_p := PackedVector3Array()
static var _bahn_r := PackedVector3Array()
static var _bahn_s := PackedFloat32Array()
static var _bahn_halb := PackedFloat32Array()
static var _eimer := {}
const EIMER := 10.0
## Abstand zum Weg auf einem Raster (4 m), für den Weit-Test.
static var _feld_d := PackedFloat32Array()
static var _feld_i := PackedInt32Array()
static var _feld_mass := Vector2i.ZERO
const FELD_ZELLE := 4.0
const FELD := Rect2(-90.0, -330.0, 310.0, 385.0)

static var _kegel: Array[Dictionary] = []
static var _netze := {}
static var _kisten: Array[Vector3] = []
## Stämme (Mindestabstand) und Kronen (keine Doppelkronen): Raster über alle
## Schritte.
static var _staemme: Waldsetzer.Raster = null
static var _kronen: Waldsetzer.Raster = null
static var _wurzel: Node3D = null
## Gezählt für `level.debug`; `_grund`: warum `_pflanze` zuletzt nein sagte.
static var _zahlen := {}
static var _grund := ""


# ================================================================ Haken

## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Der Hallenwald wächst", "tun": func() -> void:
			_gemessen("halle", _schritt_halle.bind(level))},
		{"text": "Wald am Hang", "tun": func() -> void:
			_gemessen("hang", _hangwald.bind(level))},
		{"text": "Rahmenbäume und Riesen", "tun": func() -> void:
			_gemessen("riesen", _schritt_riesen.bind(level))},
		{"text": "Wald im Tal", "tun": func() -> void:
			_gemessen("tal", _talwald_nah.bind(level))},
		{"text": "Ferner Wald", "tun": func() -> void:
			_gemessen("fern", _talwald_fern.bind(level))},
		{"text": "Hecken, Felsen und Totholz", "tun": func() -> void:
			_gemessen("rest", _schritt_rest.bind(level))
			if level.debug:
				print("Wald: ", _zahlen)},
	]


## Führt einen Schritt aus und merkt sich seine Dauer (für `level.debug`).
static func _gemessen(was: String, tun: Callable) -> void:
	var t := Time.get_ticks_usec()
	tun.call()
	_zahlen["ms_" + was] = int((Time.get_ticks_usec() - t) / 1000)


static func _schritt_halle(level: Level01) -> void:
	_vorbereiten(level)
	_hallenwald(level)
	if OS.has_environment("WALD_KEGEL"):
		print("HALLE ", _zahlen)


static func _schritt_riesen(level: Level01) -> void:
	_rahmenbaeume(level)
	_riesen(level)


static func _schritt_rest(level: Level01) -> void:
	_hecken(level)
	_felsen(level)
	_aufraeumen()


# ================================================================ Vorbereitung

static func _vorbereiten(level: Level01) -> void:
	_netze.clear()
	_zahlen.clear()
	_kisten = level.kisten_orte()
	_staemme = Waldsetzer.Raster.new(8.0)
	_kronen = Waldsetzer.Raster.new(8.0)
	_wurzel = Node3D.new()
	_wurzel.name = "Wald"
	level.geometrie.add_child(_wurzel)
	_bahn_anlegen(level)
	_kegel_anlegen(level)


## Gibt die Netze frei (sie hängen an den Knoten weiter) und vergisst den
## Verlauf.
static func _aufraeumen() -> void:
	_netze.clear()
	_eimer.clear()
	_feld_d = PackedFloat32Array()
	_feld_i = PackedInt32Array()
	_wurzel = null
	_staemme = null
	_kronen = null


static func _bahn_anlegen(level: Level01) -> void:
	_bahn_p = PackedVector3Array()
	_bahn_r = PackedVector3Array()
	_bahn_s = PackedFloat32Array()
	_bahn_halb = PackedFloat32Array()
	_eimer.clear()
	var s := -18.0
	while s <= 292.0:
		var p := level.weg_punkt(s)
		var r := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP)
		r.y = 0.0
		var i := _bahn_p.size()
		_bahn_p.append(p)
		_bahn_r.append(r.normalized())
		_bahn_s.append(s)
		_bahn_halb.append(float(level.rand_profil(s, 1.0)["wegrand"]))
		var k := Vector2i(floori(p.x / EIMER), floori(p.z / EIMER))
		if not _eimer.has(k):
			_eimer[k] = PackedInt32Array()
		var liste: PackedInt32Array = _eimer[k]
		liste.append(i)
		_eimer[k] = liste
		s += 1.0
	# Abstand zum Weg auf einem groben Raster: jede zweite Probe stempelt
	# ihre Umgebung bis 72 m.
	_feld_mass = Vector2i(ceili(FELD.size.x / FELD_ZELLE), ceili(FELD.size.y / FELD_ZELLE))
	_feld_d = PackedFloat32Array()
	_feld_d.resize(_feld_mass.x * _feld_mass.y)
	_feld_d.fill(1000.0)
	_feld_i = PackedInt32Array()
	_feld_i.resize(_feld_mass.x * _feld_mass.y)
	_feld_i.fill(-1)
	var weite := 72.0
	var n := ceili(weite / FELD_ZELLE)
	for i in range(0, _bahn_p.size(), 2):
		var p := _bahn_p[i]
		var cx := floori((p.x - FELD.position.x) / FELD_ZELLE)
		var cz := floori((p.z - FELD.position.y) / FELD_ZELLE)
		for a in range(maxi(cx - n, 0), mini(cx + n + 1, _feld_mass.x)):
			for b in range(maxi(cz - n, 0), mini(cz + n + 1, _feld_mass.y)):
				var mx := FELD.position.x + (float(a) + 0.5) * FELD_ZELLE
				var mz := FELD.position.y + (float(b) + 0.5) * FELD_ZELLE
				var d := Vector2(mx - p.x, mz - p.z).length()
				var k := b * _feld_mass.x + a
				if d < _feld_d[k]:
					_feld_d[k] = d
					_feld_i[k] = i


## Waagerechter Abstand zum Weg (Mitte), grob (±3 m); 1000 weit draußen.
static func _wegabstand(x: float, z: float) -> float:
	var a := floori((x - FELD.position.x) / FELD_ZELLE)
	var b := floori((z - FELD.position.y) / FELD_ZELLE)
	if a < 0 or b < 0 or a >= _feld_mass.x or b >= _feld_mass.y:
		return 1000.0
	return _feld_d[b * _feld_mass.x + a]


## Die nächste Wegprobe (Index) zu einem Punkt, genau; -1 weit draußen.
static func _naechste(x: float, z: float) -> int:
	var a := floori((x - FELD.position.x) / FELD_ZELLE)
	var b := floori((z - FELD.position.y) / FELD_ZELLE)
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


## Quer zum Weg an der nächsten Probe (positiv rechts).
static func _quer(i: int, x: float, z: float) -> float:
	var r := _bahn_r[i]
	return (x - _bahn_p[i].x) * r.x + (z - _bahn_p[i].z) * r.z


## Alle Wegproben im Umkreis `r` (waagerecht).
static func _proben_nahe(x: float, z: float, r: float) -> PackedInt32Array:
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


## Sichtkegel: von jeder Station des Grats zur Krone des Weltenbaums (±6°),
## vom Schluss zurück zu Kanzel und Wasserfall (±3°).
static func _kegel_anlegen(level: Level01) -> void:
	_kegel.clear()
	var wb: Dictionary = Level01.WELTENBAUM
	var achse: Vector2 = wb["achse"]
	var krone := Vector3(achse.x, float(wb["krone_mitte_y"]), achse.y)
	# Vor s 22 verdeckt der Hallenwald den Riesen ohnehin (Plan 7: erst ab
	# s 24 in der Öffnung).
	var s := 22.0
	while s <= 114.0:
		_kegel.append({"auge": _auge(level, s), "ziel": krone, "winkel": deg_to_rad(6.0)})
		s += 2.0
	var fall := level.fall_punkte("oben")
	var ziele: Array[Vector3] = []
	if not fall.is_empty():
		ziele.append(fall[0])
		ziele.append(fall[fall.size() - 1])
	# Zurück zum Wasserfall erst im Schlussbild (im Kronentor ab s 274; davor
	# stehen die Kronen der Riesen am Rand im Blick, wie ein Wald eben). Die letzten
	# 30 m vor dem Ziel sind frei. Zur Kanzel gibt es keinen Kegel: Der Blick
	# läuft dort längs des Grats, und die Rahmenbäume an seiner Kante
	# gehören zu dem, was man sehen soll.
	s = 274.0
	while s <= 287.0:
		for ziel in ziele:
			_kegel.append({"auge": _auge(level, s), "ziel": ziel, "winkel": deg_to_rad(3.0),
					"ziel_frei": 30.0})
		s += 3.0


## Ort der Verfolgerkamera, wenn die Figur bei `s` in der Mitte steht (9,5 m
## zurück auf der Kurve, 6 m über der Figur).
static func _auge(level: Level01, s: float) -> Vector3:
	var auge := LevelWerkzeuge.punkt_frei(level.verlauf, s - 9.5, 0.0)
	auge.y = level.boden_bei(s) + 6.0
	return auge


# ================================================================ Regeln

## Hält eine Krone (Welt-Hülle) den Freiraum über dem Weg (K1)? Über
## |q| < 6 liegt ihre Unterkante mindestens 9,5 m über der Decke – oder
## die ganze Krone unter dem Weg.
static func _weg_frei(huelle: AABB) -> bool:
	var mitte := huelle.get_center()
	var r := maxf(huelle.size.x, huelle.size.z) * 0.5
	for i in _proben_nahe(mitte.x, mitte.z, r + FREI_Q + 1.0):
		var p := _bahn_p[i]
		var rechts := Vector2(_bahn_r[i].x, _bahn_r[i].z)
		var d := Vector2(mitte.x - p.x, mitte.z - p.z)
		var q := d.dot(rechts)
		var laengs := absf(d.dot(Vector2(-rechts.y, rechts.x)))
		if absf(q) - r >= FREI_Q or laengs > r + 0.6:
			continue
		if huelle.position.y >= p.y + FREI_H or huelle.end.y <= p.y - 0.5:
			continue
		return false
	return true


## Steht ein Stamm (Achse von `fuss` nach `spitze`, Radius `r`) frei vom
## Weg? Kein Teil unter 8,8 m über der Decke näher als 6 m an der Mitte,
## und am Boden bleibt er außerhalb des Begehbaren (`fussweite` = Umriss
## samt Brettwurzeln zum Weg hin).
static func _stamm_frei(fuss: Vector3, spitze: Vector3, r: float, fussweite: float = 0.0,
		zugabe: float = 0.9) -> bool:
	var i0 := _naechste(fuss.x, fuss.z)
	if i0 >= 0:
		var q0 := absf(_quer(i0, fuss.x, fuss.z))
		var p0 := _bahn_p[i0]
		if absf(fuss.y - p0.y) < 3.0 and q0 - maxf(fussweite, r) < _bahn_halb[i0] + zugabe:
			return false
	for k in 10:
		var t := float(k) / 9.0
		var p := fuss.lerp(spitze, t)
		for i in _proben_nahe(p.x, p.z, FREI_Q + r + 1.0):
			var b := _bahn_p[i]
			if p.y > b.y + STAMM_FREI_H or p.y < b.y - 0.5:
				continue
			if absf(_quer(i, p.x, p.z)) - r < FREI_Q:
				return false
	return true


## Talkronen unter der Felskante: Liegt eine Krone rechts von B oder C
## höchstens `KANTE_WEITE` hinter der Lippe, bleibt ihr Scheitel 5 m unter
## der Decke (sonst läse sie sich als Tritt neben dem Weg).
static func _talkante_frei(huelle: AABB) -> bool:
	var mitte := huelle.get_center()
	var r := maxf(huelle.size.x, huelle.size.z) * 0.5
	for i in _proben_nahe(mitte.x, mitte.z, r + KANTE_WEITE + 10.0):
		var s := _bahn_s[i]
		if s < 30.0 or s > 147.0:
			continue
		var q := _quer(i, mitte.x, mitte.z)
		if q <= 0.0:
			continue
		if q - r > _bahn_halb[i] + KANTE_WEITE:
			continue
		if huelle.end.y > _bahn_p[i].y - KANTE_TIEFE:
			return false
	return true


## Liegt eine Krone (Welt-Hülle) außerhalb aller Sichtkegel? Geprüft an
## Punkten, die sicher in der Krone liegen: Mitte, Flächenmitten (85 %) und
## Ecken (55 %) der Hülle – eine Kugel um die ganze Hülle sperrte bei
## flachen Schirmkronen viel zu viel.
static func _kegel_frei(huelle: AABB) -> bool:
	var m := huelle.get_center()
	var h := huelle.size * 0.5
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
		if not Waldsetzer.kegel_frei(p, r, _kegel):
			return false
	return true


## Frei von Kisten (waagerecht, `abstand` m)?
static func _kistenfrei(p: Vector3, abstand: float) -> bool:
	for k in _kisten:
		if Vector2(k.x - p.x, k.z - p.z).length() < abstand:
			return false
	return true


# ================================================================ Netze

static func _borke() -> Material:
	return Riesenstamm.borkenstoff()


## Ein Baum (Stamm und Krone), einmal je Bau gebaut. Zwei Fassungen:
##   voll    `Riesenstamm.baum`: Rippen, Brettwurzeln, Äste, die in den
##           Ballen der Krone enden (≈ 1,6–4k + 2–3k Dreiecke). Für alles
##           in den ersten zwanzig Metern neben dem Weg.
##   mittel  ("mittel": true) schlichter Stamm mit drei Aststummeln und eine
##           freie Krone aus drei großen Ballen mit wenigen Karten (≈ 0,2k +
##           0,8k),
##           Oberkante auf `hoehe`, Mitte bei gut zwei Dritteln – Laub statt
##           Lolli. Für die hinteren Reihen und den nahen Talwald.
## Ergebnis wie `Riesenstamm.baum`, dazu "huelle" (AABB der Krone),
## "schatten" (schlichter Stamm gleicher Form: wirft den Schatten, der
## volle Stamm nicht – eine Stufe Schatten kostet so ein Zwanzigstel),
## "kranz" (Verdeckungsring am Fuß oder null), "fuss_radien", "radius".
static func _baum(schluessel: String, o: Dictionary, mit_kranz: bool = false) -> Dictionary:
	if _netze.has(schluessel):
		return _netze[schluessel]
	var b: Dictionary
	var hoehe: float = o.get("hoehe", 14.0)
	var radius: float = o.get("radius", 0.5)
	var saat: int = o.get("saat", 1)
	if bool(o.get("mittel", false)):
		var variante: int = o.get("variante", 0)
		var kr: float = o.get("krone_radius", hoehe * 0.3)
		var kh: float = o.get("krone_hoehe",
				kr * (1.3 if variante == 0 else (0.85 if variante == 1 else 2.2)))
		var stamm := Riesenstamm.schlicht({"hoehe": hoehe - kh * 0.35, "radius": radius,
				"radius_oben": radius * 0.5, "aeste": 3, "ast_start": 0.62,
				"ast_laenge": kr * 0.55, "neigung": o.get("neigung", Vector2.ZERO), "saat": saat})
		var krone := Kronenwolke.netz({"radius": kr, "hoehe": kh, "variante": variante,
				"ballen": int(o.get("ballen", 3)), "karten": int(o.get("karten", 22)),
				"mitte": Vector3(0.0, hoehe - kh * 0.5, 0.0) + _neigung_bei(o, 1.0 - kh * 0.5 / hoehe),
				"saat": saat + 101})
		var box := krone.get_aabb()
		b = {"stamm": stamm, "krone": krone, "krone_unten": box.position.y,
				"krone_oben": box.end.y, "krone_radius": kr, "schatten": stamm}
	elif bool(o.get("krone_frei", false)):
		# Voller Stamm (Rippen, Wurzeln, zwei Aststummel), aber eine freie
		# Krone aus vier Ballen an seiner Spitze: Die Kronen der Hallenbäume
		# liegen fast immer über dem Bildrand – dort lohnen keine Äste, die in
		# ihre Ballen führen.
		var variante: int = o.get("variante", 0)
		var kr: float = o.get("krone_radius", hoehe * 0.26)
		var kh: float = o.get("krone_hoehe",
				kr * (1.3 if variante == 0 else (0.85 if variante == 1 else 2.2)))
		var so := o.duplicate()
		so["aeste"] = 2
		so["ast_start"] = 0.7
		so["ast_laenge"] = kr * 0.5
		var stamm := Riesenstamm.netz(so)
		var krone := Kronenwolke.netz({"radius": kr, "hoehe": kh, "variante": variante,
				"ballen": int(o.get("ballen", 4)), "karten": int(o.get("karten", 28)),
				"mitte": Vector3(0.0, hoehe - kh * 0.35, 0.0) + _neigung_bei(o, 1.0 - kh * 0.35 / hoehe),
				"saat": saat + 101})
		var box := krone.get_aabb()
		b = {"stamm": stamm, "krone": krone, "krone_unten": box.position.y,
				"krone_oben": box.end.y, "krone_radius": kr}
		b["schatten"] = Riesenstamm.schlicht({"hoehe": hoehe, "radius": radius,
				"radius_oben": float(o.get("radius_oben", radius * 0.55)),
				"neigung": o.get("neigung", Vector2.ZERO), "krumm": 0.0, "saat": saat})
	else:
		b = Riesenstamm.baum(o)
		b["schatten"] = Riesenstamm.schlicht({"hoehe": hoehe, "radius": radius,
				"radius_oben": float(o.get("radius_oben", radius * 0.55)),
				"neigung": o.get("neigung", Vector2.ZERO), "krumm": 0.0, "saat": saat})
	var krone_roh: ArrayMesh = b["krone"]
	var krone_netz := _indiziert(krone_roh)
	b["krone"] = krone_netz
	b["huelle"] = krone_netz.get_aabb()
	b["radius"] = radius
	var stamm_netz: ArrayMesh = b["stamm"]
	var fuss: PackedFloat32Array = stamm_netz.get_meta("fuss_radien", PackedFloat32Array())
	b["fuss_radien"] = fuss
	b["kranz"] = null
	if mit_kranz and fuss.size() >= 3:
		var r0 := fuss[0]
		for f in fuss:
			r0 = minf(r0, f)
		b["kranz"] = Findling.kranz(fuss, 0.02, clampf(r0 * 1.6, 0.6, 2.5), 0.62,
				clampf(r0 * 0.15, 0.08, 0.4))
	_netze[schluessel] = b
	if OS.has_environment("WALD_DEBUG"):
		print("BAUM %-12s Stamm %5d  Krone %5d  Krone unten %.1f  Hülle %s" % [schluessel,
				Waldsetzer._dreiecke(stamm_netz), Waldsetzer._dreiecke(krone_netz),
				float(b["krone_unten"]), str(krone_netz.get_aabb().size.snappedf(0.1))])
	return b


## Versatz der Stammachse durch "neigung" in der relativen Höhe t (wie
## `Riesenstamm._achse`, ohne Schwung).
static func _neigung_bei(o: Dictionary, t: float) -> Vector3:
	var n: Vector2 = o.get("neigung", Vector2.ZERO)
	var v := n * pow(clampf(t, 0.0, 1.3), 1.5)
	return Vector3(v.x, 0.0, v.y)


## Dieselbe Krone mit geteilten Scheiteln: `Kronenwolke` gibt jedes Dreieck
## mit eigenen Ecken aus. Verschmolzen zu Hunderten kostete das den
## dreifachen Speicher.
static func _indiziert(netz: ArrayMesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(netz, 0)
	st.index()
	var neu := st.commit()
	neu.custom_aabb = netz.custom_aabb
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu


## Die Hallen- und Hangbäume (M1, Rückfall). Voll: "dach" (breit, oben zum
## Weg geneigt – lokal +X –, trägt das Blätterdach über dem Weg), "ast"
## (niedrig und breit, weit zum Weg geneigt: Äste über dem Weg), "hoch",
## "mittel", "duenn". Mittel: "schlicht_a" (rund), "schlicht_b" (breit),
## "schlicht_c" (Nadelbaum, schlank).
static func _hallenbaum(art: String) -> Dictionary:
	match art:
		"dach":
			return _baum("dach", {"krone_frei": true, "hoehe": 19.0, "radius": 0.6,
					"variante": 1, "krone_radius": 5.2, "krone_hoehe": 5.0, "rippen": 10,
					"neigung": Vector2(2.4, 0.0), "pilze": 1, "saat": 1104}, true)
		"ast":
			return _baum("ast", {"hoehe": 12.0, "radius": 0.55, "radius_oben": 0.3,
					"variante": 1, "krone_radius": 4.8, "ast_start": 0.45, "ast_steil": 0.4,
					"aeste": 5, "karten": 40, "neigung": Vector2(3.4, 0.0), "krumm": 0.4,
					"drehung": 0.9, "pilze": 1, "rippen": 10, "saat": 1107}, true)
		"hoch":
			return _baum("hoch", {"krone_frei": true, "hoehe": 18.0, "radius": 0.45,
					"variante": 0, "krone_radius": 4.4, "krone_hoehe": 6.5, "rippen": 10,
					"saat": 1101}, true)
		"mittel":
			return _baum("mittel", {"krone_frei": true, "hoehe": 16.0, "radius": 0.62,
					"variante": 0, "krone_radius": 4.8, "krone_hoehe": 6.4, "rippen": 11,
					"efeu": 1, "saat": 1102}, true)
		"duenn":
			return _baum("duenn", {"krone_frei": true, "hoehe": 16.5, "radius": 0.32,
					"variante": 2, "krone_radius": 2.8, "krone_hoehe": 7.0, "rippen": 10,
					"saat": 1103}, true)
		"schlicht_a":
			return _baum("schlicht_a", {"mittel": true, "hoehe": 17.0, "radius": 0.45,
					"variante": 0, "krone_radius": 4.6, "krone_hoehe": 7.5, "saat": 1105}, true)
		"schlicht_b":
			return _baum("schlicht_b", {"mittel": true, "hoehe": 16.0, "radius": 0.4,
					"variante": 1, "krone_radius": 5.0, "krone_hoehe": 5.2, "saat": 1106}, true)
		_:
			return _baum("schlicht_c", {"mittel": true, "hoehe": 17.0, "radius": 0.4,
					"variante": 2, "krone_radius": 2.6, "krone_hoehe": 9.0, "saat": 1108}, true)


## Talbäume (M3, Rückfall), mittlere Fassung: 0 rund, 1 breit, 2 Nadelbaum,
## 3 groß und rund.
static func _talbaum(k: int) -> Dictionary:
	match k % 4:
		0:
			return _baum("tal0", {"mittel": true, "hoehe": 12.0, "radius": 0.34, "variante": 0,
					"krone_radius": 4.2, "krone_hoehe": 5.6, "saat": 2101})
		1:
			return _baum("tal1", {"mittel": true, "hoehe": 11.0, "radius": 0.36, "variante": 1,
					"krone_radius": 4.8, "krone_hoehe": 4.2, "saat": 2102})
		2:
			return _baum("tal2", {"mittel": true, "hoehe": 13.0, "radius": 0.3, "variante": 2,
					"krone_radius": 2.4, "krone_hoehe": 8.0, "ballen": 4, "saat": 2103})
		_:
			return _baum("tal3", {"mittel": true, "hoehe": 14.0, "radius": 0.42, "variante": 0,
					"krone_radius": 5.0, "krone_hoehe": 6.6, "saat": 2104})


## Ferne Bäume: flache Krone ohne Karten (vier grobe Ballen, gut 0,3k
## Dreiecke) und ein angedeuteter Stamm im selben Stoff (vier Seiten,
## dunkel, ohne Wind) – aus 60 m und mehr sähe man sonst Kronen auf nichts
## schweben. Die Krone nimmt die oberen gut zwei Drittel der Höhe ein, der
## Stamm steckt in ihr: ein Wald aus Laub, keine Lollis. Fuß im Ursprung.
static func _fernbaum(k: int) -> ArrayMesh:
	var schluessel := "fern%d" % k
	if _netze.has(schluessel):
		return _netze[schluessel]
	var hoehe := 12.0
	var o := {"radius": 5.0, "hoehe": 6.4, "saat": 3101 + k, "ballen": 3}
	match k:
		1:
			o["variante"] = 1
			o["radius"] = 5.6
			o["hoehe"] = 4.8
			hoehe = 11.0
		2:
			# Nadelbaum: schlank und hoch
			o["variante"] = 2
			o["radius"] = 2.5
			o["hoehe"] = 9.0
			o["ballen"] = 4
			hoehe = 14.0
	var kh: float = o["hoehe"]
	o["mitte"] = Vector3(0.0, hoehe - kh * 0.5, 0.0)
	var krone := Kronenwolke.fern(o)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(krone, 0, Transform3D.IDENTITY)
	var r := 0.3 if k != 1 else 0.36
	var oben := hoehe - kh * 0.5
	var dunkel := Color(0.3, 0.26, 0.21, 0.0)
	for j in 4:
		var w0 := TAU * float(j) / 4.0 + 0.4
		var w1 := TAU * float(j + 1) / 4.0 + 0.4
		var a := Vector3(cos(w0) * r, -1.0, -sin(w0) * r)
		var b := Vector3(cos(w1) * r, -1.0, -sin(w1) * r)
		var c := Vector3(cos(w1) * r * 0.6, oben, -sin(w1) * r * 0.6)
		var d := Vector3(cos(w0) * r * 0.6, oben, -sin(w0) * r * 0.6)
		var n := Vector3(cos((w0 + w1) * 0.5), 0.0, -sin((w0 + w1) * 0.5))
		for p: Vector3 in [a, c, b, a, d, c]:
			st.set_color(dunkel)
			st.set_uv(Vector2.ZERO)
			st.set_uv2(Vector2(0.0, 0.0))
			st.set_normal(n)
			st.add_vertex(p)
	st.index()
	var netz := st.commit()
	_netze[schluessel] = netz
	if OS.has_environment("WALD_DEBUG"):
		print("FERN %d  %d Dreiecke" % [k, Waldsetzer._dreiecke(netz)])
	return netz


## Stoff eines Baumteils in der Farbe eines Tons mit ±6 % Farbwärme.
static func _ton(rng: RandomNumberGenerator, hell: Vector2, waerme: float = 0.06) -> Color:
	var v := rng.randf_range(hell.x, hell.y)
	var w := rng.randf_range(-waerme, waerme)
	return Color(clampf(v * (1.0 + w), 0.0, 1.0), clampf(v, 0.0, 1.0),
			clampf(v * (1.0 - w), 0.0, 1.0), 1.0)


## Welt-Hülle einer lokalen AABB unter `lage`.
static func _huelle(lage: Transform3D, box: AABB) -> AABB:
	return lage * box


## Lage eines Baums: Fuß, Drehung um Y, Maßstab (quer, hoch), Schiefe
## (Winkel in rad um eine waagerechte Achse `kipp_achse`).
static func _lage(fuss: Vector3, drehung: float, quer: float, hoch: float,
		schief: float = 0.0, kipp_achse: Vector3 = Vector3.RIGHT) -> Transform3D:
	var basis := Basis(Vector3.UP, drehung).scaled_local(Vector3(quer, hoch, quer))
	if absf(schief) > 0.0001:
		basis = Basis(kipp_achse.normalized(), schief) * basis
	return Transform3D(basis, fuss)


## Setzt einen Baum, wenn er alle Regeln hält. `stamm_art`/`krone_art`
## sind Arten im Setzer `ws`; "" lässt den Teil weg. Rückgabe: gesetzt?
static func _pflanze(ws: Waldsetzer, b: Dictionary, lage: Transform3D, stamm_art: String,
		krone_art: String, stamm_ton: Color, krone_ton: Color, optionen: Dictionary = {}) -> bool:
	var huelle := _huelle(lage, b["huelle"] as AABB)
	if not _weg_frei(huelle):
		_zaehle("nein_k1")
		_grund = "k1 Krone %s" % str(huelle) if OS.has_environment("WALD_KEGEL") else "k1"
		return false
	if bool(optionen.get("talkante", false)) and not _talkante_frei(huelle):
		_zaehle("nein_kante")
		_grund = "kante"
		return false
	var krone_r := maxf(huelle.size.x, huelle.size.z) * 0.5
	if not _kegel_frei(huelle):
		_zaehle("nein_kegel")
		_grund = "kegel"
		if OS.has_environment("WALD_KEGEL"):
			for k: Dictionary in _kegel:
				var alt := _kegel
				_kegel = [k]
				var frei := _kegel_frei(huelle)
				_kegel = alt
				if not frei:
					_grund = "kegel %s -> %s, Krone %s" % [str((k["auge"] as Vector3).snappedf(0.1)),
							str((k["ziel"] as Vector3).snappedf(0.1)), str(huelle)]
					break
		return false
	var fuss := lage.origin
	var stamm: ArrayMesh = b["stamm"]
	var s_box := stamm.get_aabb()
	var spitze := lage * Vector3(0.0, s_box.end.y * 0.9, 0.0)
	# Stammradius in Brusthöhe (aus dem Netz, mal Maßstab)
	var r := float(b.get("radius", 0.5)) * maxf(lage.basis.x.length(), lage.basis.z.length())
	var fussweite := float(optionen.get("fussweite", r))
	if not bool(optionen.get("ohne_stammtest", false)) \
			and not _stamm_frei(fuss, spitze, r, fussweite, float(optionen.get("zugabe", 0.9))):
		_zaehle("nein_stamm")
		_grund = "stamm"
		return false
	if not Waldsetzer.kegel_frei(fuss.lerp(spitze, 0.75), r * 2.0, _kegel):
		_zaehle("nein_kegel_stamm")
		_grund = "kegel_stamm"
		return false
	if not stamm_art.is_empty():
		ws.setze(stamm_art, stamm, lage, stamm_ton)
		# Den Schatten wirft der schlichte Stamm gleicher Form.
		if ws.hat_art(stamm_art + "_schatten") and b.get("schatten") != null:
			ws.setze(stamm_art + "_schatten", b["schatten"] as ArrayMesh, lage)
	if not krone_art.is_empty():
		ws.setze(krone_art, b["krone"] as ArrayMesh, lage, krone_ton)
	var kranz_art: String = optionen.get("kranz", "")
	if not kranz_art.is_empty() and b["kranz"] != null:
		# Der Ring liegt flach am Fuß, auch unter einem schiefen Stamm.
		var flach := Basis(Vector3.UP, float(optionen.get("drehung", 0.0))).scaled_local(
				Vector3(lage.basis.x.length(), 1.0, lage.basis.z.length()))
		ws.setze(kranz_art, b["kranz"] as ArrayMesh, Transform3D(flach, fuss), Color(1, 1, 1, 1))
	_kronen.dazu(Vector2(huelle.get_center().x, huelle.get_center().z), krone_r * 0.75)
	return true


static func _zaehle(was: String, n: int = 1) -> void:
	_zahlen[was] = int(_zahlen.get(was, 0)) + n


# ================================================================ Hallenwald

static func _hallenwald(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Hallenwald", 0.0)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_HALLE, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_HALLE,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_HALLE), "sicht": SICHT_HALLE,
			"verschmelzen": true, "karten": true})
	ws.art("kranz", {"stoff": Findling.kranzstoff(), "sicht": SICHT_KRANZ,
			"verschmelzen": true})
	ws.art("farn", {"stoff": Farnwerk.stoff(FARN), "sicht": SICHT_FARN})
	var farne: Array[ArrayMesh] = [Farnwerk.klein(41), Farnwerk.klein(42), Farnwerk.gross(43)]
	var rng := PropWerkzeug.zufall(4101)

	# Heldenstämme zuerst: Sie haben ihren Platz.
	for k in HELDEN.size():
		var stelle: Vector2 = HELDEN[k]
		var b := _baum("held%d" % k, {"hoehe": 20.0 + float(k), "radius": 0.9 + 0.08 * float(k),
				"variante": 1, "krone_radius": 5.0, "ast_start": 0.6, "aeste": 5, "karten": 60,
				"rippen": 14,
				"brettwurzeln": 6, "wurzel_reichweite": 2.3, "wurzel_hoehe": 3.2,
				"wurzel_dicke": 0.34, "pilze": 2, "efeu": 1 + k % 2, "saat": 1201 + k}, true)
		var fuss := _boden(level, stelle.x, stelle.y)
		var zum_weg := -signf(stelle.y) * _rechts_bei(level, stelle.x)
		var dreh: Dictionary = Waldsetzer.drehung_weg(b["fuss_radien"], zum_weg)
		var lage := _lage(fuss, float(dreh["drehung"]), 1.0, 1.0)
		if _pflanze(ws, b, lage, "stamm", "krone", Color(0.92, 0.92, 0.92), _ton(rng, Vector2(0.84, 0.95)),
				{"kranz": "kranz", "drehung": float(dreh["drehung"]),
				"fussweite": float(dreh["weite"])}):
			_staemme.dazu(Vector2(fuss.x, fuss.z), 3.2)
			_farne_um(ws, farne, fuss, 1.4, 4, rng)
			_zaehle("helden")

	for seite: float in [-1.0, 1.0]:
		for reihe in REIHEN.size():
			var e: Dictionary = REIHEN[reihe]
			var qb: Vector2 = e["q"]
			var ab: Vector2 = e["abstand"]
			var arten: Array = e["arten"]
			var s := HALLE_VON + rng.randf_range(0.0, ab.x)
			var bis := HALLE_LINKS_BIS if seite < 0.0 else 30.0
			while s < bis:
				var ss := s + rng.randf_range(-2.4, 2.4)
				var q := seite * rng.randf_range(qb.x, qb.y)
				s += rng.randf_range(ab.x, ab.y)
				if not _halle_platz(level, ss, q):
					_zaehle("halle_nein_platz")
					continue
				var fuss := _boden(level, ss, q)
				var abstand := 4.2 if reihe < 3 else 5.0
				if not _staemme.frei(Vector2(fuss.x, fuss.z), abstand * 0.5):
					_zaehle("halle_nein_abstand")
					continue
				var art: String = arten[rng.randi_range(0, arten.size() - 1)]
				# Hält die Wahl eine Regel nicht (meist K1: Krone zu tief über
				# dem Weg), versucht es ein schlanker Baum mit freier Drehung.
				var versuche: Array[String] = [art]
				if reihe < 3:
					versuche.append("hoch" if art != "hoch" else "duenn")
				for versuch_art in versuche:
					var b := _hallenbaum(versuch_art)
					# Zum Weg (lokal +X) neigt sich nur der Dachbaum; sonst frei.
					var richtung := -seite * _rechts_bei(level, ss)
					var dreh := rng.randf() * TAU
					if versuch_art == "dach":
						dreh = atan2(-richtung.z, richtung.x) + rng.randf_range(-0.35, 0.35)
					var quer := rng.randf_range(0.8, 1.25)
					var hoch := rng.randf_range(0.9, 1.12)
					var schief := 0.0
					var kipp := Vector3.RIGHT
					if rng.randf() < 0.13 and versuch_art != "dach":
						schief = deg_to_rad(rng.randf_range(5.0, 8.0))
						var w := rng.randf() * TAU
						kipp = Vector3(cos(w), 0.0, sin(w))
					var lage := _lage(fuss, dreh, quer, hoch, schief, kipp)
					var mit_kranz := reihe < 3
					var ton_stamm := _ton(rng, Vector2(0.78, 0.98), 0.03)
					var ton_krone := _ton(rng, Vector2(0.78, 0.98))
					if rng.randf() < 0.18:
						ton_krone = ton_krone * NADEL_TON
					if _pflanze(ws, b, lage, "stamm", "krone", ton_stamm, ton_krone,
							{"kranz": "kranz" if mit_kranz else "", "drehung": dreh}):
						_staemme.dazu(Vector2(fuss.x, fuss.z), abstand * 0.5)
						_zaehle("halle")
						if reihe < 2 and rng.randf() < 0.6:
							_farne_um(ws, farne, fuss, 0.5 + quer * 0.5, rng.randi_range(1, 3), rng)
						break

	# Das Dach über dem Weg: die Kronen der ersten Reihe reichen bis q ±3;
	# dazwischen schließen Kronen ohne eigenen Stamm (sie hängen an den
	# Ästen der Randbäume), nie tiefer als 9,5 m über dem Weg und nicht
	# über den Lichtlöchern.
	var dach := _baum("dachkrone", {"mittel": true, "hoehe": 16.0, "radius": 0.4, "variante": 1,
			"krone_radius": 5.0, "krone_hoehe": 4.4, "ballen": 4, "karten": 30, "saat": 1301})
	var s_dach := -6.0
	while s_dach < 24.5:
		var q := rng.randf_range(-1.5, 1.5)
		var ss := s_dach + rng.randf_range(-1.0, 1.0)
		s_dach += rng.randf_range(6.0, 8.0)
		if _im_lichtloch(ss, q, 3.5):
			continue
		var p := level.weg_punkt(ss, q)
		var box: AABB = dach["huelle"]
		var y := p.y + FREI_H + 1.6 - box.position.y * 0.95
		var lage := _lage(Vector3(p.x, y, p.z), rng.randf() * TAU, rng.randf_range(0.9, 1.1), 0.95)
		var huelle := _huelle(lage, box)
		if not _weg_frei(huelle):
			continue
		ws.setze("krone", dach["krone"] as ArrayMesh, lage, _ton(rng, Vector2(0.72, 0.88)))
		_zaehle("dachkronen")

	# Der gestürzte Stamm quer durch die Reihen links, Stümpfe und
	# Moosstämme am Saum.
	var liegend := Riesenstamm.liegend(0.55, 13.0, {"saat": 1401, "rippen": 11, "aeste": 2})
	var von := _boden(level, 14.0, -10.5)
	var nach := _boden(level, 21.0, -22.0)
	ws.setze("stamm", liegend, _liegend_lage(von, nach, 0.55 * 0.55), Color(0.9, 0.9, 0.9))
	ws.setze("stamm_schatten", liegend, _liegend_lage(von, nach, 0.55 * 0.55))
	_deko_saum(level, ws, rng)
	var z := ws.fertig()
	_zaehle("halle_knoten", int(z["knoten"]))
	_zaehle("halle_dreiecke", int(z["dreiecke"]))


## Darf im Hallenwald bei (s, q) ein Stamm stehen?
static func _halle_platz(level: Level01, s: float, q: float) -> bool:
	# Rechts endet der Wald an der Hallenkante (Enthüllung); dort bleibt ein
	# Streifen frei, damit kein Stamm über der Lippe steht.
	if q > 0.0:
		var kante := _polylinie(L01Gelaende.HALLENKANTE, s)
		if is_nan(kante) or q > kante - 2.5:
			return false
		if s > 25.0:
			return false
	# Der Erdspalt und was die Wegbauten dort schon hingestellt haben.
	if s > ERDSPALT.x and s < ERDSPALT.y and absf(q) < ERDSPALT.z:
		return false
	for b: Vector3 in BESETZT:
		if Vector2(s - b.x, q - b.y).length() < b.z:
			return false
	# Links hinter s 33 steigt die Böschung: Dort pflanzt der Hangwald.
	if q < 0.0 and s > 32.0:
		return false
	return absf(q) > float(level.rand_profil(s, signf(q))["wegrand"]) + 1.6


static func _im_lichtloch(s: float, q: float, weite: float) -> bool:
	for l: Dictionary in Level01.LICHTLOECHER:
		if Vector2(s - float(l["s"]), q - float(l["q"])).length() < float(l["radius"]) + weite:
			return true
	return false


## Ein paar Farne um einen Stammfuß, nie auf dem Weg.
static func _farne_um(ws: Waldsetzer, farne: Array[ArrayMesh], fuss: Vector3, r: float,
		anzahl: int, rng: RandomNumberGenerator) -> void:
	for k in anzahl:
		var w := rng.randf() * TAU
		var d := r + rng.randf_range(0.3, 1.2)
		var x := fuss.x + cos(w) * d
		var zz := fuss.z + sin(w) * d
		var i := _naechste(x, zz)
		if i >= 0 and absf(_quer(i, x, zz)) < _bahn_halb[i] + 0.9:
			continue
		if not _kistenfrei(Vector3(x, 0.0, zz), 1.5):
			continue
		var y := L01Gelaende.hoehe(x, zz)
		var gross := rng.randf() < 0.12
		var netz := farne[2] if gross else farne[rng.randi_range(0, 1)]
		var skala := rng.randf_range(0.7, 1.0) if gross else rng.randf_range(0.9, 1.5)
		var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * skala),
				Vector3(x, y - 0.05, zz))
		ws.setze("farn", netz, lage, _ton(rng, Vector2(0.75, 1.0), 0.05))
		_zaehle("farne")


## Stümpfe, Moosstämme und Felsen an den Säumen von A (|q| 6,2–9).
static func _deko_saum(level: Level01, ws: Waldsetzer, rng: RandomNumberGenerator) -> void:
	var stuempfe: Array[ArrayMesh] = [Riesenstamm.stumpf(0.5, 0.9, {"saat": 1501}),
			Riesenstamm.stumpf(0.38, 0.6, {"saat": 1502}),
			Riesenstamm.stumpf(0.62, 1.3, {"saat": 1503, "pilze": 1})]
	var stellen := [Vector3(-3.0, -7.2, 0), Vector3(6.0, 6.9, 1), Vector3(16.5, -6.8, 2),
			Vector3(22.8, 7.4, 0), Vector3(-10.0, 7.0, 2)]
	for st: Vector3 in stellen:
		var fuss := _boden(level, st.x, st.y)
		if not _staemme.frei(Vector2(fuss.x, fuss.z), 0.8):
			continue
		var netz := stuempfe[int(st.z)]
		var lage_stumpf := _lage(fuss, rng.randf() * TAU, 1.0, 1.0)
		ws.setze("stamm", netz, lage_stumpf, Color(0.9, 0.88, 0.86))
		ws.setze("stamm_schatten", netz, lage_stumpf)
		_staemme.dazu(Vector2(fuss.x, fuss.z), 0.8)
		_zaehle("stuempfe")
	# Moosstämme längs am Saum, halb im Boden.
	var logs := [Vector4(-1.0, -7.4, 4.4, 0.36), Vector4(12.0, 7.6, 5.2, 0.42),
			Vector4(18.0, -7.8, 3.6, 0.32)]
	for l: Vector4 in logs:
		var netz := Riesenstamm.liegend(l.w, l.z, {"saat": 1510 + int(l.x), "rippen": 9,
				"aeste": 1})
		var a := _boden(level, l.x - l.z * 0.5, l.y + rng.randf_range(-0.4, 0.4))
		var b := _boden(level, l.x + l.z * 0.5, l.y + rng.randf_range(-0.4, 0.4))
		if not _staemme.frei(Vector2((a.x + b.x) * 0.5, (a.z + b.z) * 0.5), 1.0):
			continue
		ws.setze("stamm", netz, _liegend_lage(a, b, l.w * 0.6), Color(0.88, 0.9, 0.86))
		ws.setze("stamm_schatten", netz, _liegend_lage(a, b, l.w * 0.6))
		_zaehle("moosstaemme")


## Lage eines liegenden Stamms (Achse +Y) von `a` nach `b`, um `heben`
## über dem Boden (Rest steckt im Boden).
static func _liegend_lage(a: Vector3, b: Vector3, heben: float) -> Transform3D:
	var y := (b - a).normalized()
	var x := y.cross(Vector3.UP).normalized()
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	var zz := x.cross(y).normalized()
	var mitte := (a + b) * 0.5 + Vector3.UP * heben
	return Transform3D(Basis(x, y, zz), mitte)


## Welt-Ort am Boden bei (s, q): das Gelände, nicht die Decke.
static func _boden(level: Level01, s: float, q: float) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
	p.y = L01Gelaende.hoehe(p.x, p.z)
	return p


static func _rechts_bei(level: Level01, s: float) -> Vector3:
	var r := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP)
	r.y = 0.0
	return r.normalized()


## q einer Polylinie [Vector2(s, q)] an der Stelle `s`; NAN außerhalb.
static func _polylinie(punkte: Array, s: float) -> float:
	if punkte.is_empty():
		return NAN
	var erster: Vector2 = punkte[0]
	var letzter: Vector2 = punkte[punkte.size() - 1]
	if s < erster.x or s > letzter.x:
		return NAN
	for i in punkte.size() - 1:
		var a: Vector2 = punkte[i]
		var b: Vector2 = punkte[i + 1]
		if s >= a.x and s <= b.x:
			if b.x - a.x < 0.0001:
				return b.y
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	return letzter.y


# ================================================================ Hangwald

## Links über der Böschung (B) und auf der Krone der Fallklamm (C): ab der
## Kronenkante des Saums, wo das Gelände Wald trägt. Vorn volle Stämme mit
## Kronen, die sich zum Weg neigen (über dem linken Wegdrittel erst ab
## 9,5 m), dahinter schlichte.
static func _hangwald(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Hangwald", ZELLE_HANG)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_HANG, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_HANG,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_HALLE), "sicht": SICHT_HANG,
			"verschmelzen": true, "karten": true})
	var quer := L01Saum.querschnitte_links(level)
	var strecken: PackedFloat32Array = quer.get("s", PackedFloat32Array())
	var punkte: Array = quer.get("punkte", [])
	var rng := PropWerkzeug.zufall(5101)
	var s := 31.0
	while s < 166.0:
		var kante := _kronenkante(strecken, punkte, s)
		if is_nan(kante.x):
			kante = Vector2(11.0, level.boden_bei(s) + 5.0)
		var u := rng.randf_range(0.5, 3.0)
		while u < HANG_TIEFE:
			var ss := s + rng.randf_range(-2.6, 2.6)
			var q := -(kante.x + u)
			var tiefe := u
			u += rng.randf_range(5.0, 7.5)
			var fuss := _boden(level, ss, q)
			var w := L01Gelaende.wald(fuss.x, fuss.z)
			# Vorn dichter: Die erste Reihe rahmt das Bild, egal was der
			# Boden sagt; weiter hinten entscheidet die Walddichte.
			var schwelle := rng.randf_range(0.18, 0.55) if tiefe < 7.0 else rng.randf_range(0.35, 0.8)
			if w < schwelle:
				continue
			# Nur oben auf der Krone, nicht in der Wand
			if fuss.y < kante.y - 1.2:
				continue
			if not _staemme.frei(Vector2(fuss.x, fuss.z), 2.4):
				continue
			var vorn := tiefe < 10.0
			var art := "dach"
			if not vorn or rng.randf() >= 0.55:
				var auswahl: Array = ["hoch", "mittel", "duenn"] if vorn \
						else ["schlicht_a", "schlicht_b", "schlicht_c"]
				art = String(auswahl[rng.randi_range(0, auswahl.size() - 1)])
			# Ganz vorn an der Kante (bis s 110) oft ein Astbaum: niedrig und
			# breit, zum Weg geneigt – seine Äste hängen über dem linken
			# Wegdrittel (ab 9,5 m) und rahmen das Bild oben links.
			var versuche: Array[String] = [art]
			if tiefe < 3.2 and ss < 110.0 and rng.randf() < 0.7:
				versuche = ["ast", "dach"]
			for versuch_art in versuche:
				var b := _hallenbaum(versuch_art)
				var zum_weg := _rechts_bei(level, ss)
				var dreh := rng.randf() * TAU
				if versuch_art == "dach" or versuch_art == "ast":
					dreh = atan2(-zum_weg.z, zum_weg.x) + rng.randf_range(-0.4, 0.4)
				var hoch := rng.randf_range(0.9, 1.15)
				var lage := _lage(fuss, dreh, rng.randf_range(0.85, 1.25), hoch)
				var ton_krone := _ton(rng, Vector2(0.8, 1.0))
				if rng.randf() < 0.2 and versuch_art != "ast":
					ton_krone = ton_krone * NADEL_TON
				if _pflanze(ws, b, lage, "stamm", "krone", _ton(rng, Vector2(0.78, 0.96), 0.03),
						ton_krone):
					_staemme.dazu(Vector2(fuss.x, fuss.z), 2.4)
					_zaehle("hang")
					if versuch_art == "ast":
						_zaehle("hang_ast")
					break
		s += rng.randf_range(5.5, 7.5)
	var z := ws.fertig()
	_zaehle("hang_knoten", int(z["knoten"]))
	_zaehle("hang_dreiecke", int(z["dreiecke"]))


## Kronenkante links (|q|, Welt-Y) an der Strecke s aus den Querschnitten des
## Saums (Punkt 20); NAN außerhalb.
static func _kronenkante(strecken: PackedFloat32Array, punkte: Array, s: float) -> Vector2:
	if strecken.is_empty() or s < strecken[0] or s > strecken[strecken.size() - 1]:
		return Vector2(NAN, NAN)
	var i := clampi(strecken.bsearch(s), 1, strecken.size() - 1)
	var reihe: PackedVector2Array = punkte[i]
	var vorher: PackedVector2Array = punkte[i - 1]
	if reihe.size() <= 20 or vorher.size() <= 20:
		return Vector2(NAN, NAN)
	var t := inverse_lerp(strecken[i - 1], strecken[i], s)
	return vorher[20].lerp(reihe[20], clampf(t, 0.0, 1.0))


# ================================================================ Rahmen und Riesen

## Die Rahmenbäume auf den Felsnadeln unter der Kante: gedreht, nach außen
## (über das Tal) geneigt. Wo die Krone im Sichtkegel zum Weltenbaum stünde,
## neigt sich der Baum weiter hinaus oder bleibt kleiner.
static func _rahmenbaeume(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Rahmenbaeume", 0.0)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_RAHMEN, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_RAHMEN,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(Color(0.18, 0.38, 0.15)), "sicht": SICHT_RAHMEN,
			"verschmelzen": true, "karten": true})
	var rng := PropWerkzeug.zufall(6101)
	var nummer := 0
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if String(stelle["art"]) != "sims":
			continue
		nummer += 1
		var s: float = stelle["s"]
		var q: float = stelle["q"]
		var fuss := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
		fuss.y = level.boden_bei(s) + float(stelle["fuss"])
		var aussen := _rechts_bei(level, s)
		var gesetzt := false
		var b := _baum("rahmen%d" % nummer, {"hoehe": float(stelle["hoehe"]), "radius": 0.48,
				"radius_oben": 0.24, "variante": 0, "krone_radius": 3.3, "ast_start": 0.5,
				"aeste": 5, "drehung": 1.5, "krumm": 0.6, "neigung": Vector2(3.2, 0.0),
				"karten": 50, "pilze": 1, "efeu": 1, "brettwurzeln": 5, "rippen": 12,
				"wurzel_reichweite": 1.4, "wurzel_hoehe": 1.6, "saat": 6201 + nummer * 7})
		# Versuche: erst wie geplant, dann weiter hinaus gedreht und kleiner.
		# Lokal +X (die Neigung) zeigt über das Tal, leicht in Laufrichtung.
		var grund := atan2(-aussen.z, aussen.x)
		for versuch in 8:
			var f := 1.0 - 0.06 * floorf(float(versuch) * 0.5)
			var w := grund + (0.35 if versuch % 2 == 0 else -0.35) * (1.0 - float(versuch) / 8.0)
			# ab dem dritten Versuch auch weiter hinaus (die Nadel ist breit)
			var ort := fuss + aussen * 0.4 * floorf(float(versuch) * 0.5)
			var lage := _lage(ort, w, f, f)
			if _pflanze(ws, b, lage, "stamm", "krone", Color(0.9, 0.88, 0.86),
					_ton(rng, Vector2(0.82, 0.96)), {"ohne_stammtest": true}):
				gesetzt = true
				_zaehle("rahmen")
				break
		if not gesetzt:
			push_warning("Wald: Rahmenbaum bei s %.1f ohne Platz (%s)" % [s, _grund])
	ws.fertig()


## Torriesen, Talriesen, Kanalbäume und Überständer: je ein Riese aus
## `Riesenstamm.baum` mit Brettwurzeln, die vom Weg weg zeigen.
static func _riesen(level: Level01) -> void:
	# Zellen zu 70 m: Die Riesen am Weg und die Überständer im Tal sind
	# getrennte Knoten mit eigener Sichtweite.
	var ws := Waldsetzer.new(_wurzel, "Riesen", 70.0)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_RIESEN, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_RIESEN,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(Color(0.2, 0.42, 0.15)), "sicht": SICHT_RIESEN,
			"verschmelzen": true, "karten": true})
	ws.art("kranz", {"stoff": Findling.kranzstoff(), "sicht": SICHT_KRANZ + 20.0,
			"verschmelzen": true})
	var rng := PropWerkzeug.zufall(7101)
	var liste: Array[Dictionary] = []
	# Die Torriesen stehen am Riesentor dicht an der Wiese (q ±9): kurze
	# Wurzeln, und deren Spitzen – sie tauchen flach in den Boden – dürfen
	# bis 0,3 m an die Wegkante (die Leitlinie steht bei 6,8).
	for t: Dictionary in Level01.TORRIESEN:
		liste.append({"s": t["s"], "q": t["q"], "hoehe": t["hoehe"], "radius": t["radius"],
				"reichweite": 1.2, "neigung": 0.0, "zugabe": 0.3})
	for t: Dictionary in Level01.TALRIESEN:
		liste.append({"s": t["s"], "q": t["q"], "hoehe": t["hoehe"], "radius": t["radius"],
				"reichweite": 2.4, "neigung": 0.0, "zugabe": 0.9})
	for k: Vector4 in KANALBAEUME:
		liste.append({"s": k.x, "q": k.y, "hoehe": k.z, "radius": 0.95, "reichweite": 2.0,
				"neigung": k.w, "zugabe": 0.9})
	for i in liste.size():
		var e: Dictionary = liste[i]
		var s: float = e["s"]
		var q: float = e["q"]
		var hoehe: float = e["hoehe"]
		var r: float = e["radius"]
		var geneigt: float = e["neigung"]
		var b := _baum("riese%d" % i, {"hoehe": hoehe, "radius": r, "radius_oben": r * 0.5,
				"variante": 1, "krone_radius": hoehe * 0.25,
				"ast_start": 0.68 if geneigt > 0.0 else 0.56, "aeste": 6,
				"ast_steil": 0.55, "brettwurzeln": 7, "wurzel_reichweite": float(e["reichweite"]),
				"wurzel_hoehe": r * 2.6, "wurzel_dicke": r * 0.26, "pilze": 2, "efeu": 1,
				"rippen": 16, "karten": 90, "neigung": Vector2(geneigt, 0.0),
				"saat": 7201 + i * 13}, true)
		var fuss := _boden(level, s, q)
		var zum_weg := -signf(q) * _rechts_bei(level, s)
		var dreh: Dictionary = Waldsetzer.drehung_weg(b["fuss_radien"], zum_weg)
		var w := float(dreh["drehung"])
		if geneigt > 0.0:
			# Die Neigung (lokal +X) zeigt zum Weg: Das Dach über C4.
			w = atan2(-zum_weg.z, zum_weg.x)
		# Steht die Krone vom Grat aus vor dem Weltenbaum (Sichtkegel), bleibt
		# der Riese kleiner: bis zu sechs Stufen zu je 6 % der Höhe.
		var gesetzt := false
		for stufe in 7:
			var f := 1.0 - 0.06 * float(stufe)
			var lage := _lage(fuss, w, lerpf(1.0, f, 0.5), f)
			if _pflanze(ws, b, lage, "stamm", "krone", Color(0.94, 0.93, 0.92),
					_ton(rng, Vector2(0.84, 0.96)), {"kranz": "kranz", "drehung": w,
					"fussweite": float(dreh["weite"]) * f, "zugabe": float(e["zugabe"]),
					"ohne_stammtest": geneigt > 0.0}):
				_staemme.dazu(Vector2(fuss.x, fuss.z), r + 2.5)
				_zaehle("riesen")
				_zaehle("riesen_stufe", stufe)
				gesetzt = true
				break
		if not gesetzt:
			push_warning("Wald: Riese bei s %.1f, q %.1f verletzt eine Regel (%s)" % [s, q, _grund])
	# Überständer im Tal: an der nächsten Stelle mit Wald auf tiefem Grund.
	for i in UEBERSTAENDER.size():
		var ziel: Vector2 = UEBERSTAENDER[i]
		var ort := _talstelle(ziel, rng)
		if is_nan(ort.x):
			continue
		# Man sieht sie nur von weitem (mindestens 42 m): mittlere Fassung
		# mit großer Krone aus fünf Ballen.
		var b := _baum("ueber%d" % i, {"mittel": true, "hoehe": 22.0 + 2.0 * float(i),
				"radius": 0.9, "variante": i % 2, "krone_radius": 7.0, "krone_hoehe": 9.0,
				"ballen": 5, "karten": 40, "saat": 7401 + i * 11})
		var lage := _lage(ort, rng.randf() * TAU, 1.0, 1.0)
		if _pflanze(ws, b, lage, "stamm", "krone", Color(0.9, 0.9, 0.9),
				_ton(rng, Vector2(0.86, 0.98)), {"talkante": true}):
			_staemme.dazu(Vector2(ort.x, ort.z), 4.0)
			_zaehle("ueberstaender")
	ws.fertig()


## Eine Stelle für einen Überständer nahe `ziel`: Wald, tiefer Grund, weit
## genug vom Weg und vom Bach. NAN, wenn nichts passt.
static func _talstelle(ziel: Vector2, rng: RandomNumberGenerator) -> Vector3:
	var beste := Vector3(NAN, NAN, NAN)
	var bester := -INF
	for k in 40:
		var x := ziel.x + rng.randf_range(-16.0, 16.0)
		var z := ziel.y + rng.randf_range(-16.0, 16.0)
		var y := L01Gelaende.hoehe(x, z)
		var w := L01Gelaende.wald(x, z)
		if w < 0.5 or y > 9.0 or _wegabstand(x, z) < 42.0:
			continue
		var wert := w - absf(y - 6.0) * 0.1 - Vector2(x, z).distance_to(ziel) * 0.02
		if wert > bester:
			bester = wert
			beste = Vector3(x, y, z)
	return beste


# ================================================================ Talwald

## Der nahe Talwald: alles bis `NAH_WEIT` vom Weg, was nicht Hallen- oder
## Hangwald ist – Kronen mit Karten auf schlichten Stämmen, dazu Totholz.
static func _talwald_nah(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Talwald", ZELLE_TAL)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_TAL, "verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_TAL), "sicht": SICHT_TAL,
			"verschmelzen": true, "karten": true})
	var rng := PropWerkzeug.zufall(8101)
	var tot: Array[ArrayMesh] = [
		Riesenstamm.netz({"hoehe": 11.0, "radius": 0.42, "oben": "bruch", "aeste": 3,
				"ast_start": 0.45, "ast_laenge": 3.0, "moos": 0.35, "saat": 8201}),
		Riesenstamm.netz({"hoehe": 8.0, "radius": 0.5, "oben": "bruch", "aeste": 2,
				"ast_start": 0.5, "ast_laenge": 2.4, "moos": 0.4, "brettwurzeln": 4,
				"saat": 8202})]
	var raster := 6.4
	var x := FELD.position.x
	while x < FELD.end.x:
		var z := FELD.position.y
		while z < FELD.end.y:
			var px := x + rng.randf_range(0.0, raster)
			var pz := z + rng.randf_range(0.0, raster)
			z += raster
			var d := _wegabstand(px, pz)
			if d > NAH_WEIT or d < 3.0:
				continue
			var i := _naechste(px, pz)
			if i < 0:
				continue
			var s := _bahn_s[i]
			var q := _quer(i, px, pz)
			# Links von A bis C4 pflanzen Hallen- und Hangwald.
			if q < 0.0 and s < 166.0:
				continue
			if q > 0.0 and s < 26.0:
				continue
			var y := L01Gelaende.hoehe(px, pz)
			var w := L01Gelaende.wald(px, pz)
			if w < rng.randf_range(0.3, 0.72):
				# Lichtung: ab und zu ein toter Baum am Rand
				if w > 0.12 and rng.randf() < 0.035 and d > 16.0:
					_totholz(ws, tot, Vector3(px, y, pz), rng)
				continue
			if not _staemme.frei(Vector2(px, pz), 2.3):
				continue
			var nadel := rng.randf() < 0.18
			var k := 2
			if not nadel:
				var auswahl: Array[int] = [0, 1, 3]
				k = auswahl[rng.randi_range(0, 2)]
			var b := _talbaum(k)
			var groesse := rng.randf_range(0.8, 1.2)
			var lage := _lage(Vector3(px, y, pz), rng.randf() * TAU, groesse * rng.randf_range(0.9, 1.1),
					groesse)
			var ton := _ton(rng, Vector2(0.82, 1.0))
			if nadel:
				ton = ton * NADEL_TON
			elif _auf_riegel(px, pz):
				ton = ton * Color(0.78, 0.84, 0.84)
			if _pflanze(ws, b, lage, "stamm", "krone", _ton(rng, Vector2(0.8, 0.95), 0.03), ton,
					{"talkante": true}):
				_staemme.dazu(Vector2(px, pz), 2.3)
				_zaehle("tal")
			else:
				# Unter der Kante: ein kleinerer Baum passt vielleicht.
				lage = _lage(Vector3(px, y, pz), rng.randf() * TAU, 0.7, 0.62)
				if _pflanze(ws, b, lage, "stamm", "krone", Color(0.9, 0.9, 0.9), ton,
						{"talkante": true}):
					_staemme.dazu(Vector2(px, pz), 1.6)
					_zaehle("tal_klein")
		x += raster
	_totholz_tal(ws, tot, rng)
	var zz := ws.fertig()
	_zaehle("tal_knoten", int(zz["knoten"]))
	_zaehle("tal_dreiecke", int(zz["dreiecke"]))


## Graue Totholzstämme im Tal: an Waldrändern (wo der Wald in Wiese
## übergeht), 18–110 m vom Weg, auf der offenen Seite. Höchstens `anzahl`.
static func _totholz_tal(ws: Waldsetzer, tot: Array[ArrayMesh], rng: RandomNumberGenerator,
		anzahl: int = 8) -> void:
	var gesetzt := 0
	var versuche := 0
	while gesetzt < anzahl and versuche < 400:
		versuche += 1
		var px := rng.randf_range(10.0, 150.0)
		var pz := rng.randf_range(-230.0, -10.0)
		var d := _wegabstand(px, pz)
		if d < 18.0 or d > 110.0:
			continue
		var i := _naechste(px, pz)
		if i >= 0 and _quer(i, px, pz) < 0.0 and _bahn_s[i] < 166.0:
			continue
		var w := L01Gelaende.wald(px, pz)
		if w < 0.12 or w > 0.5:
			continue
		var vorher := int(_zahlen.get("totholz", 0))
		_totholz(ws, tot, Vector3(px, L01Gelaende.hoehe(px, pz), pz), rng)
		if int(_zahlen.get("totholz", 0)) > vorher:
			gesetzt += 1


static func _totholz(ws: Waldsetzer, tot: Array[ArrayMesh], fuss: Vector3,
		rng: RandomNumberGenerator) -> void:
	if not _staemme.frei(Vector2(fuss.x, fuss.z), 2.0):
		return
	var netz := tot[rng.randi_range(0, tot.size() - 1)]
	var lage := _lage(fuss, rng.randf() * TAU, rng.randf_range(0.9, 1.2), rng.randf_range(0.85, 1.2),
			deg_to_rad(rng.randf_range(0.0, 9.0)), Vector3(rng.randf() - 0.5, 0.0, rng.randf() - 0.5))
	var spitze := lage * Vector3(0.0, netz.get_aabb().end.y, 0.0)
	if not _stamm_frei(fuss, spitze, 0.6) or not _talkante_frei(lage * netz.get_aabb()):
		return
	ws.setze("stamm", netz, lage, TOT_TON)
	_staemme.dazu(Vector2(fuss.x, fuss.z), 2.0)
	_zaehle("totholz")


## Liegt ein Punkt auf einem der Riegel im Tal (dunkles Band)?
static func _auf_riegel(x: float, z: float) -> bool:
	for k in L01Gelaende.RIEGEL.size():
		var r: Vector4 = L01Gelaende.RIEGEL[k]
		var m: Vector2 = L01Gelaende.RIEGEL_MASS[k]
		var a := Vector2(r.x, r.y)
		var ab := Vector2(r.z, r.w) - a
		var t := clampf((Vector2(x, z) - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if Vector2(x, z).distance_to(a + ab * t) < m.x * 0.7:
			return true
	return false


## Der ferne Wald: flache Kronen mit angedeutetem Stamm, je Zelle ein Netz,
## überall, wo das Gelände Wald trägt und keine nahe Krone steht.
static func _talwald_fern(_level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Fernwald", ZELLE_FERN)
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_FERN, false), "sicht": SICHT_FERN,
			"verschmelzen": true, "rand": 10.0})
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1), _fernbaum(2)]
	var rng := PropWerkzeug.zufall(9101)
	var anteil := 0.6 if Effekte.reduziert else 1.0
	var raster := FERN_RASTER
	var x := FELD.position.x + 4.0
	while x < FELD.end.x - 4.0:
		var z := FELD.position.y + 4.0
		while z < FELD.end.y - 4.0:
			var px := x + rng.randf_range(-3.8, 3.8)
			var pz := z + rng.randf_range(-3.8, 3.8)
			z += raster
			if rng.randf() > anteil:
				continue
			var d := _wegabstand(px, pz)
			if d < FERN_AB:
				continue
			var w := L01Gelaende.wald(px, pz)
			if w < rng.randf_range(0.28, 0.7):
				continue
			if not _kronen.frei(Vector2(px, pz), 3.6):
				continue
			if d < NAH_WEIT + 6.0 and not _nah_leer(px, pz):
				continue
			var y := L01Gelaende.hoehe(px, pz)
			var nadel := rng.randf() < 0.2
			var k := 2 if nadel else rng.randi_range(0, 1)
			var groesse := rng.randf_range(0.85, 1.25) * (1.1 if y > 16.0 else 1.0)
			var lage := _lage(Vector3(px, y, pz), rng.randf() * TAU,
					groesse * rng.randf_range(0.9, 1.15), groesse)
			var huelle := lage * netze[k].get_aabb()
			if not _talkante_frei(huelle) or not _weg_frei(huelle):
				continue
			if not _kegel_frei(huelle):
				continue
			var ton := _ton(rng, Vector2(0.78, 1.0))
			if nadel:
				ton = ton * NADEL_TON
			elif _auf_riegel(px, pz):
				ton = ton * Color(0.76, 0.82, 0.82)
			ws.setze("krone", netze[k], lage, ton)
			_kronen.dazu(Vector2(px, pz), 3.6 * groesse)
			_zaehle("fern")
		x += raster
	var zz := ws.fertig()
	_zaehle("fern_knoten", int(zz["knoten"]))
	_zaehle("fern_dreiecke", int(zz["dreiecke"]))


## Hat der nahe Wald hier bewusst nichts gepflanzt (Hallen-, Hang- und
## Talwald decken das Nahe ab)? Nur wo keiner der drei zuständig war, darf
## der ferne Wald bis `FERN_AB` heran.
static func _nah_leer(x: float, z: float) -> bool:
	var i := _naechste(x, z)
	if i < 0:
		return true
	var s := _bahn_s[i]
	var q := _quer(i, x, z)
	# Links von A bis C: Hallen- und Hangwald reichen bis `HALLE_TIEFE`
	# bzw. `HANG_TIEFE` hinter die Kronenkante (höchstens gut 11 m
	# quer); rechts der nahe Talwald bis `NAH_WEIT`.
	if q < 0.0 and s < 166.0:
		var grenze := HALLE_TIEFE if s < 33.0 else HANG_TIEFE + 12.0
		return absf(q) > grenze + 2.0
	if q > 0.0 and s < 26.0:
		return absf(q) > HALLE_TIEFE + 2.0
	return false


# ================================================================ Hecken

## Hecken rechts der Bachwiese (q 7,3–9,4) und um die Wurzelwiese: grüne
## Sträucher, dazwischen blühende. Hinter der Leitlinie, niedriger als die
## Kamera je käme, und nie über einer Kiste.
static func _hecken(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Hecken", 0.0)
	ws.art("gruen", {"stoff": Kronenwolke.stoff(LAUB_HECKE), "sicht": SICHT_HECKE,
			"verschmelzen": true, "karten": true})
	ws.art("bluete", {"stoff": Kronenwolke.stoff(BLUETE), "sicht": SICHT_HECKE,
			"verschmelzen": true, "karten": true})
	var busch: Array[ArrayMesh] = []
	for k in 3:
		busch.append(Kronenwolke.netz({"radius": 1.15 + 0.15 * float(k), "variante": 1 if k != 1 else 0,
				"karten": 26, "ballen": 5, "saat": 9601 + k}))
	var rng := PropWerkzeug.zufall(9501)
	# Stücke der Hecke: [von, bis, q von Leitlinie (innen), Breite]
	var stuecke := [Vector4(159.8, 172.3, 7.4, 1.9), Vector4(183.8, 194.4, 7.4, 1.9)]
	for st: Vector4 in stuecke:
		var s := st.x
		while s < st.y:
			for reihe in 2:
				var q := st.z + 0.35 + float(reihe) * st.w * 0.55 + rng.randf_range(-0.2, 0.3)
				var ss := s + float(reihe) * 0.9 + rng.randf_range(-0.3, 0.3)
				_busch(level, ws, busch, ss, q, rng)
			s += rng.randf_range(1.6, 2.3)
	# Um die Wurzelwiese: der Linie von (194, 6,8) über (196, 12,4) bis
	# (214, 12,4) nach, dann quer zurück zum Wulst.
	var linie := [Vector2(194.2, 7.6), Vector2(196.2, 13.3), Vector2(214.6, 13.3)]
	var s2 := 194.4
	while s2 < 214.6:
		var q := _polylinie(linie, s2)
		if not is_nan(q):
			_busch(level, ws, busch, s2, q + rng.randf_range(0.0, 0.5), rng)
			if rng.randf() < 0.6:
				_busch(level, ws, busch, s2 + 0.8, q + 1.3 + rng.randf_range(0.0, 0.5), rng)
		s2 += rng.randf_range(1.5, 2.1)
	var z := ws.fertig()
	_zaehle("hecke_knoten", int(z["knoten"]))


static func _busch(level: Level01, ws: Waldsetzer, busch: Array[ArrayMesh], s: float, q: float,
		rng: RandomNumberGenerator) -> void:
	var fuss := _boden(level, s, q)
	if not _kistenfrei(fuss, 1.8):
		return
	var i := _naechste(fuss.x, fuss.z)
	if i >= 0 and absf(_quer(i, fuss.x, fuss.z)) < _bahn_halb[i] + 1.2:
		return
	var netz := busch[rng.randi_range(0, busch.size() - 1)]
	var hoch := rng.randf_range(0.8, 1.3)
	var lage := _lage(fuss + Vector3.UP * (netz.get_aabb().size.y * 0.3 * hoch), rng.randf() * TAU,
			rng.randf_range(0.85, 1.2), hoch)
	var bluehend := rng.randf() < 0.28
	ws.setze("bluete" if bluehend else "gruen", netz, lage,
			_ton(rng, Vector2(0.85, 1.0) if bluehend else Vector2(0.78, 1.0)))
	_zaehle("buesche")


# ================================================================ Felsen

## Deko-Felsen: am Saum des Hallenwalds, am Hang zwischen den Stämmen und am
## Rand der Bachwiese. Fremdmodelle (M8), sonst `Findling.brocken`. Die
## Oberseiten sind gewölbt – nichts sieht begehbar aus –, und alles liegt
## hinter den Leitlinien.
static func _felsen(level: Level01) -> void:
	var ws := Waldsetzer.new(_wurzel, "Felsen", 0.0)
	var rng := PropWerkzeug.zufall(9901)
	var modelle := Fremdmodelle.rolle_netze("M8", {}, 20.0)
	var arten: Array = []
	for k in modelle.size():
		arten.append(ws.fremd("fels%d" % k, modelle[k], {"sicht": SICHT_FELS}))
	var rueckfall: Array[ArrayMesh] = []
	if modelle.is_empty():
		ws.art("fels", {"stoff": Findling.stoff(), "schatten": true, "sicht": SICHT_FELS,
				"verschmelzen": true})
		rueckfall = [Findling.brocken(Vector3(2.2, 1.3, 1.7), {"saat": 9911}),
				Findling.brocken(Vector3(1.5, 0.9, 1.3), {"saat": 9912}),
				Findling.brocken(Vector3(2.8, 1.6, 2.1), {"saat": 9913})]
	# (s, q, Größe)
	var stellen := [Vector3(-6.0, 7.8, 1.1), Vector3(4.5, -7.6, 0.8), Vector3(9.5, 8.2, 0.9),
			Vector3(15.0, -9.4, 1.2), Vector3(24.0, -8.6, 0.8), Vector3(21.5, 12.0, 1.0),
			Vector3(-2.5, -13.5, 1.3), Vector3(163.5, -8.4, 1.0), Vector3(167.5, 10.8, 0.9),
			Vector3(189.0, -9.6, 1.1), Vector3(186.0, 10.2, 0.8)]
	for st: Vector3 in stellen:
		var fuss := _boden(level, st.x, st.y)
		if not _staemme.frei(Vector2(fuss.x, fuss.z), 0.8 * st.z):
			continue
		var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(
				Vector3(st.z, st.z * rng.randf_range(0.8, 1.05), st.z * rng.randf_range(0.85, 1.1))),
				fuss - Vector3.UP * 0.25 * st.z)
		if not modelle.is_empty():
			var k := rng.randi_range(0, modelle.size() - 1)
			var namen: Array[String] = []
			namen.assign(arten[k])
			ws.setze_fremd(namen, modelle[k], lage, _ton(rng, Vector2(0.85, 1.0), 0.03))
		else:
			ws.setze("fels", rueckfall[rng.randi_range(0, rueckfall.size() - 1)], lage,
					_ton(rng, Vector2(0.85, 1.0), 0.03))
		_staemme.dazu(Vector2(fuss.x, fuss.z), 0.8 * st.z)
		_zaehle("felsen")
	ws.fertig()
