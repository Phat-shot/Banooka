extends RefCounted
class_name L05Rasen
## Level 05, Modul „Rasen": Rasensaum, Laubstreu und Kupferfarn (Entwurf
## §8.5, §9.1, Paket P7) – über `Rasenbau` (scripts/gemeinsam/) und eigene
## Felder.
##
## WAS HIER WÄCHST (Seiten wie im Rückblick: q < 0 bildrechts, q > 0
## bildlinks):
## * RASENSAUM auf den Kronen der Böschungen (`Level05.ZUEGE`, Art „auf")
##   zwischen A und E, von der Wandkrone KRONE_BAND m nach außen – so weit
##   reicht die Platte des Saums: Die Kamera steht 5,6 m über der Figur und
##   sieht über die 3–5 m hohen Wände auf ihre Kronen. In A (Suhle, samt den
##   niedrigen Kronen dort) und E (Mühlbach) Rasen auf der Decke nach der
##   Wegmaske (`Rasenbau.decke`) und auf der Wiese daneben (WIESE_BREITE),
##   in E weiter hinter dem Ende der Decke bis unter die Kamera am Ziel
##   (AUSLAUF_E).
##   Die Höhe ist die gezeichnete Oberkante (`L05Gelaende.sicht_oberkante`:
##   Krone des Saums oder Gelände, auf den Kronen aus einer Tabelle,
##   `_krone_hoehe`); im Wasser (Suhle, Teich, Unterwasser) wächst nichts.
## * LAUBSTREU am Wegrand (LAUB_STRECKE): Häufchen gefallener Blätter in
##   Ocker, Kupfer, Braun und Gelb an beiden Kanten der Decke (LAUB_RAND),
##   als Haufen im Streustoff (`Bodenstreu.Haufen`, Art GROSS: Sie
##   schrumpfen erst ab 30 m – die Figur steht 21 m vor der Kamera).
## * KUPFERFARN (Adlerfarn im Spätsommer, Entwurf §5 D „Sonnenhang mit
##   Kupferfarn"): auf den Kronen und am Hang bildlinks (q > 0) im Tobel,
##   lichter in C; in den Ecken von A als Rahmenfarne (`Rasenbau.
##   rahmenfarne`, K8-Probe aus der Kamera). Der Stoff ist eine Abschrift von
##   `Farnwerk.stoff()` (`duplicate()`, Entwurf §1 Nr. 24): Der geteilte Stoff
##   bleibt, wie er ist.
## Um Kisten, Stämme (`L05Wald.fuesse`) und Sperren (Suhlgraben, Schlamm um
## den Keiler, Wehrkrone) bleibt es frei.
##
## KOSTEN (Entwurf §10: Rasen, Farn und Streu ≤ 35 Zeichenaufrufe, Handy
## ≤ 20; Ende 42 m). Rasenbau zeichnet je Stück von 16 m und Art ein Netz,
## Laub je Stück von LAUB_STUECK m, Farn von STUECK m eines; alles ohne
## Schatten, mit harten Sichtweiten (Gras 42, Laub 46, Farn 44 m). Mit
## `Effekte.reduziert` halbe Dichte (Rasenbau ×0,5, Laub und Farn ×HANDY).
## Gemessen (Messtore wie `L05Wald`, gegen denselben Stand nur mit Wald,
## Prüfung der P7-Mängel): Desktop +11 … +16 Zeichenaufrufe, Handy +6 … +13;
## bis +94 k Dreiecke im Bild (s 8, Wiese und Decke in A); +10,3 MB
## Grafikspeicher (Handy +5,3).
## BAUZEIT und BAUSPEICHER (Entwurf §9.4: kein Schritt über 400 ms): Gebaut
## wird nur beim ersten Laden, höchstens 0,33 s je Schritt („Rasen an der
## Suhle", ohne das Anlegen; zusammen lagen beide bei 0,42 s); die Kronen
## beider Seiten zusammen über `sicht_oberkante` brauchten 1,2–1,4 s, daher
## die Tabelle und ein Schritt je Seite. Danach liegen die LAGEN im
## Bauspeicher, nicht die Knoten: Rasen und Farn sind MultiMeshes, deren
## Instanzen ohne Grafik nicht auslesbar sind (siehe `L05Ablage`). Aus
## ihnen baut `Rasenbau.fertig` dieselben Knoten wieder (`Bau.zustand`,
## Streu und Laub mit fertigem Netz: `FertigerHaufen`) – ein Schritt von
## rund 10 ms statt sieben Schritten von zusammen 1,2 s.

## Breite des Rasensaums hinter der Wandkrone (m) und seine Dichte (Flecken
## je m²); die Kronen bekommen ihn in Stücken von KRONE_SCHRITT m (die
## Wandkrone wandert mit der Strecke).
const KRONE_BAND := 2.8
const KRONE_DICHTE := 2.5
const KRONE_SCHRITT := 3.0
const TABELLE_SCHRITT := 0.5
## Rasen auf der Decke und daneben in A und E (Strecke, Breite der Wiese
## neben dem Weg ab der Wegkante).
const ABSCHNITT_A := Vector2(-4.0, 31.0)
const ABSCHNITT_E := Vector2(265.0, 300.0)
const WIESE_BREITE := 8.0
const WIESE_DICHTE := 3.5
## Hinter dem Ende der Decke (M_ENDE) bis hierher die Wiese unter der
## Kamera, von der Zunge des Auslaufs (`Level05.auslauf_halb`) bis
## AUSLAUF_BREITE quer: Am Ziel (296) steht die Kamera 21 m dahinter bei
## 317, der untere Bildrand trifft den Boden rund 5 m vor ihr (Blick 10°
## nach unten, halbes Bildfeld 37,5°, 5,6 m hoch). Ohne das lag im unteren
## Drittel des Schlussbilds nur nackter Grund (Prüfung P7), in A dagegen
## Gras bis an die Kamera. Quer wie die Wiese in A (Wegrand + WIESE_BREITE).
const AUSLAUF_E := 315.0
const AUSLAUF_BREITE := 12.0
## Sperren als Vector4(s, q, halbe Länge, halbe Breite): Suhlgraben,
## Schlamm um den schlafenden Keiler (L05Wasser.DECKE_*), Wehrkrone.
const SPERREN: Array[Vector4] = [
	Vector4(25.8, 0.0, 2.6, 7.0),
	Vector4(14.25, -4.2, 6.75, 2.3),
	Vector4(286.5, 0.0, 7.6, 4.2),
]
## Laubstreu: Strecke, Querlage ab der Wegkante (innen, außen), Abstand der
## Häufchen (m), Sichtweite (m) und Länge ihrer Stücke entlang s (m). Kürzer
## als die Stücke des Farns: Mit 32 m und Sichtweite 40 sprangen Häufchen
## schon 22 m vor der Kamera ins Bild (gemessen: Kamera die Strecke entlang,
## nächster Scheitel im Bild beim Wechsel) – so erst ab 35 m, wie Gras und
## Streu des Rasenbaus (30–39 m).
const LAUB_STRECKE := Vector2(30.0, 280.0)
const LAUB_RAND := Vector2(-1.6, 0.3)
const LAUB_SCHRITT := 0.7
const SICHT_LAUB := 46.0
const LAUB_STUECK := 16.0
## Laubfarben (linear): Ocker, Kupfer, Braun, Gelb.
const LAUB_FARBEN: Array[Color] = [Color(0.62, 0.38, 0.1), Color(0.5, 0.18, 0.05),
		Color(0.3, 0.17, 0.07), Color(0.72, 0.56, 0.14)]
## Kupferfarn: Farbe des Stoffs, Strecken (s von, s bis, Dichte je m²) auf
## der Sonnenseite, Breite des Streifens hinter der Wandkrone (m), Sicht.
const KUPFER := Color(0.62, 0.3, 0.1)
const FARN_STRECKEN: Array[Vector3] = [Vector3(184.0, 262.0, 0.16), Vector3(124.0, 178.0, 0.06)]
const FARN_BAND := 12.0
const SICHT_FARN := 44.0
## Länge der Stücke des Farns entlang s (m).
const STUECK := 32.0
## Laub und Farn auf dem Handy (Entwurf §9.5: Gras und Streu ×0,5).
const HANDY := 0.5
const SAAT := 5801

var level: Level05
var bau: Bau
var _farn_stoff: ShaderMaterial
## Kisten als (s, q), für Laub und Farn.
var _kisten: Array[Vector2] = []
## Kronen einer Seite (siehe `_tabelle_anlegen`).
var _tabelle := PackedVector2Array()
var _tabelle_von := 0.0
## Lagen von Laub und Farn (für die Ablage): {"laub": Stück -> Haufen
## (`haufen_daten`), "farn": Vector2i(Stück, Form) -> {lagen, farben}}.
var _laub_farn := {}


## Die Schritte: liegen die Lagen im Bauspeicher (`schluessel`, im
## Hintergrund vorgeladen wie der Wald), einer, der daraus die Knoten baut
## (`_aus_speicher`); sonst der ganze Bau, der am Ende ablegt (`_fertig`).
static func bauschritte(level_: Level05) -> Array:
	var r := L05Rasen.new()
	r.level = level_
	level_.rasen = r
	if Bauspeicher.vorladen(r.schluessel()):
		return [{"text": "Rasen wird ausgerollt", "tun": r._aus_speicher}]
	return r._bau_schritte()


## Schlüssel im Bauspeicher: wie `L05Wald.schluessel` (der Rasen hält
## Abstand zu den Stämmen des Walds, K8 rechnet mit der Kamera).
func schluessel() -> String:
	var kamera := level.get_node_or_null("CorridorCamera") as KorridorKamera
	return "l05_rasen_%s_%s_%s" % ["handy" if Effekte.reduziert else "voll",
			"modelle" if Fremdmodelle.aktiv() else "ohne", L05Ablage.kamera_schluessel(kamera)]


## Der Bau in Schritten. „Rasen an der Suhle" lag kalt bei 422 ms (Entwurf
## §9.4: kein Schritt über 400 ms) – Anlegen und Säen sind getrennt.
func _bau_schritte() -> Array:
	return [
		{"text": "Rasen wird angelegt", "tun": _anlegen},
		{"text": "Rasen an der Suhle", "tun": _wiese_a},
		{"text": "Rasen auf den Kronen links", "tun": _kronen.bind(-1.0)},
		{"text": "Rasen auf den Kronen rechts", "tun": _kronen.bind(1.0)},
		{"text": "Rasen am Mühlbach", "tun": _wiese_e},
		{"text": "Laub am Wegrand und Kupferfarn", "tun": _laub_und_farn},
		{"text": "Rasen wird ausgerollt", "tun": _fertig},
	]


# ================================================================ Bau

## Legt den Bau an: Kisten, Stämme und Sperren, der Stoff des Kupferfarns.
func _anlegen() -> void:
	bau = _bau_neu()
	for k in level.kisten_orte():
		_kisten.append(bau.strecke_quer(k))
	for v in SPERREN:
		bau.sperre(v.x, v.y, v.z, v.w)
	if level.wald != null:
		for f in level.wald.fuesse + level.wald.tor_fuesse:
			var sq := bau.strecke_quer(f)
			if absf(sq.y) < 40.0:
				bau.kreis(sq.x, sq.y, 0.8)
	_farn_stoff_anlegen()


## A: Decke nach der Wegmaske, Wiese daneben (samt der niedrigen Kronen um
## die Suhle), Rahmenfarne.
func _wiese_a() -> void:
	_abschnitt(ABSCHNITT_A)
	for seite: float in [-1.0, 1.0]:
		bau.rahmenfarne(ABSCHNITT_A.x + 2.0, ABSCHNITT_A.y - 4.0, seite, _farn_stoff)


## E: Decke nach der Wegmaske und die Wiese daneben, bis unter die Kamera
## (siehe AUSLAUF_E).
func _wiese_e() -> void:
	_abschnitt(ABSCHNITT_E)
	for seite: float in [-1.0, 1.0]:
		var s := ABSCHNITT_E.y
		while s < AUSLAUF_E:
			var innen := Level05.auslauf_halb(s) + 0.3
			bau.boden(s, minf(s + KRONE_SCHRITT, AUSLAUF_E), seite, innen, AUSLAUF_BREITE,
					WIESE_DICHTE, Rasenbau.Bereich.WIESE)
			s += KRONE_SCHRITT


func _abschnitt(ab: Vector2) -> void:
	for seite: float in [-1.0, 1.0]:
		bau.decke(maxf(ab.x, 0.0), ab.y, seite)
		var s := ab.x
		while s < ab.y:
			# In Stücken, weil die Breite wandert.
			var rand := level.weg.wegrand(clampf(s, 0.0, Level05.M_ENDE)) + 0.3
			bau.boden(s, minf(s + KRONE_SCHRITT, ab.y), seite, rand, rand + WIESE_BREITE,
					WIESE_DICHTE, Rasenbau.Bereich.WIESE)
			s += KRONE_SCHRITT


## Rasensaum auf den Kronen der Böschung einer Seite (Zug „auf") zwischen A
## und E, von der Wandkrone KRONE_BAND nach außen. Die Höhe kommt hier aus
## einer Tabelle der Kronen (`_krone_hoehe`): `hoehe` (über
## `L05Gelaende.sicht_oberkante`) rechnete für jede Stelle die Form des
## Zuges neu und brauchte für beide Seiten 1,2–1,4 s (gemessen,
## Bauzeitprobe).
func _kronen(seite: float) -> void:
	var allgemein := bau.hoehe
	bau.hoehe = _krone_hoehe
	for zug: Dictionary in Level05.ZUEGE:
		if String(zug["art"]) != "auf" or float(zug["seite"]) != seite:
			continue
		var von: float = maxf(float(zug["von"]), ABSCHNITT_A.y)
		var bis: float = minf(float(zug["bis"]), ABSCHNITT_E.x)
		_tabelle_anlegen(zug, von, bis)
		var s := von
		while s < bis:
			var innen := _wandkrone(zug, s)
			if not is_nan(innen):
				bau.boden(s, minf(s + KRONE_SCHRITT, bis), seite, innen, innen + KRONE_BAND,
						KRONE_DICHTE, Rasenbau.Bereich.SCHULTER)
			s += KRONE_SCHRITT
	bau.hoehe = allgemein


## Tabelle der Krone eines Zuges über s (alle TABELLE_SCHRITT m): Y der
## gezeichneten Krone (Saum, `L05Saum.form_auf` + KRONE_STEIGT) und |q|, bis
## zu dem ihre Platte reicht.
func _tabelle_anlegen(zug: Dictionary, von: float, bis: float) -> void:
	_tabelle_von = von
	_tabelle = PackedVector2Array()
	var linie := Level05.leitlinie_punkte(float(zug["seite"]))
	var s := von
	while s <= bis + TABELLE_SCHRITT:
		var m := L05Saum.form_auf(level, zug, s)
		var l := absf(Level05.leitlinie_q(linie, s))
		_tabelle.append(Vector2(float(m["krone"]) + L05Saum.KRONE_STEIGT,
				l + float(m["lauf"]) + float(m["weit"])))
		s += TABELLE_SCHRITT


## Höhe auf der Krone an (x, z): die Krone aus der Tabelle, wo die Platte
## des Saums liegt, sonst (und wo es höher ist) das Gelände.
func _krone_hoehe(x: float, z: float) -> float:
	var g := level.gelaende
	var sq := g.projektion(x, z)
	if level.wald != null and level.wald.nass(sq.x, sq.y):
		return NAN
	var y := g.hoehe(x, z)
	var i := clampi(roundi((sq.x - _tabelle_von) / TABELLE_SCHRITT), 0, _tabelle.size() - 1)
	var k := _tabelle[i]
	if absf(sq.y) <= k.y:
		y = maxf(y, k.x)
	return y


## Laubstreu am Wegrand und Kupferfarn, je Stück von LAUB_STUECK bzw.
## STUECK m als Haufen bzw. Feld: erst die Lagen (`_laub_farn`, für die
## Ablage), dann die Knoten daraus – beim Laden mit derselben Funktion.
func _laub_und_farn() -> void:
	var anteil := HANDY if Effekte.reduziert else 1.0
	var formen: Array[Bodenstreu.Teil] = []
	var frng := PropWerkzeug.zufall(SAAT + 2)
	for i in 6:
		formen.append(_laubhaeufchen(frng))
	var rng := PropWerkzeug.zufall(SAAT + 3)
	var haufen := {}
	var s := LAUB_STRECKE.x
	while s < LAUB_STRECKE.y:
		s += LAUB_SCHRITT * rng.randf_range(0.6, 1.4)
		for seite: float in [-1.0, 1.0]:
			if rng.randf() > anteil * 0.8:
				continue
			var halb := level.weg.wegrand(s)
			if halb <= 0.0 or level.ist_luecke(s):
				continue
			var q := seite * (halb + rng.randf_range(LAUB_RAND.x, LAUB_RAND.y))
			if not _kiste_frei(s, q):
				continue
			var p := level.weg_punkt(s, q, 0.012)
			var i := floori(s / LAUB_STUECK)
			if not haufen.has(i):
				haufen[i] = Bodenstreu.Haufen.new(
						level.weg_punkt((float(i) + 0.5) * LAUB_STUECK, 0.0))
			var t: Bodenstreu.Teil = formen[rng.randi() % formen.size()]
			var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU)
					* Basis.from_scale(Vector3.ONE * rng.randf_range(0.8, 1.3)), p)
			(haufen[i] as Bodenstreu.Haufen).teil(t, lage)
	var laub := {}
	for i: int in haufen:
		laub[i] = haufen_daten(haufen_fertig(haufen[i] as Bodenstreu.Haufen))
	_laub_farn = {"laub": laub, "farn": _kupferfarn(anteil)}
	_laub_farn_einhaengen(_laub_farn)


## Kupferfarn auf der Sonnenseite (q > 0) hinter der Wandkrone
## (FARN_STRECKEN): die Felder je Stück und Form, Vector2i(Stück, Form) ->
## {lagen, farben}.
func _kupferfarn(anteil: float) -> Dictionary:
	var rng := PropWerkzeug.zufall(SAAT + 5)
	var zug := _zug("Böschung rechts")
	var felder := {}
	for st in FARN_STRECKEN:
		var s := st.x
		while s < st.y:
			s += 1.0
			var innen := _wandkrone(zug, s)
			if is_nan(innen):
				continue
			var anzahl := st.z * FARN_BAND * anteil
			while anzahl > 0.0:
				if rng.randf() > anzahl:
					break
				anzahl -= 1.0
				var ss := s + rng.randf_range(-0.5, 0.5)
				var q := innen + 0.4 + pow(rng.randf(), 1.4) * FARN_BAND
				var p := LevelWerkzeuge.punkt_frei(level.verlauf, ss, q)
				var y := hoehe(p.x, p.z)
				if is_nan(y):
					continue
				var k := 2 if rng.randf() < 0.35 else rng.randi_range(0, 1)
				var mass := rng.randf_range(0.8, 1.3)
				var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU)
						* Basis.from_scale(Vector3.ONE * mass), Vector3(p.x, y - 0.04, p.z))
				var schluessel := Vector2i(floori(ss / STUECK), k)
				if not felder.has(schluessel):
					var leer: Array[Transform3D] = []
					felder[schluessel] = {"lagen": leer, "farben": PackedColorArray()}
				var e: Dictionary = felder[schluessel]
				(e["lagen"] as Array[Transform3D]).append(lage)
				var farben: PackedColorArray = e["farben"]
				var v := rng.randf_range(0.8, 1.15)
				farben.append(Color(v * rng.randf_range(0.95, 1.08), v, v * rng.randf_range(0.85, 1.0)))
				e["farben"] = farben
	return felder


## Die Knoten von Laub und Farn aus ihren Lagen (`_laub_farn`), unter einer
## Wurzel „Laub und Farn".
func _laub_farn_einhaengen(d: Dictionary) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Laub und Farn"
	level.deko.add_child(wurzel)
	var laub: Dictionary = d["laub"]
	for i: int in laub:
		haufen_aus(laub[i] as Dictionary).knoten(wurzel, "Laub %d" % i, SICHT_LAUB)
	var netze: Array[ArrayMesh] = [Farnwerk.klein(3), Farnwerk.klein(8),
			Farnwerk.netz({"laenge": 1.0, "wedel": 6, "fiedern": 7, "zacken": 0,
				"steil": Vector2(0.45, 1.05), "schwere": 0.28, "saat": SAAT + 4})]
	var felder: Dictionary = d["farn"]
	for schluessel: Vector2i in felder:
		var e: Dictionary = felder[schluessel]
		var lagen: Array[Transform3D] = []
		lagen.assign(e["lagen"])
		Bodenstreu.feld(wurzel, "Kupferfarn %d %d" % [schluessel.x, schluessel.y],
				netze[schluessel.y], lagen, e["farben"] as PackedColorArray, SICHT_FARN, _farn_stoff)


## Rasenbau fertig, dann ablegen: die Lagen aus Rasenbau (`Bau.zustand`)
## und von Laub und Farn. WARUM die Lagen und nicht die Knoten: Rasen und
## Farn sind MultiMeshes, deren Instanzen ohne Grafik nicht auslesbar sind
## (siehe `L05Ablage`). `fertig` baut aus den Lagen in rund 20 ms dieselben
## Knoten (Bauzeitprobe, P7: „Rasen wird ausgerollt" 19–27 ms).
func _fertig() -> void:
	if bau == null:
		return
	var zustand := bau.zustand()
	bau.fertig()
	bau = null
	if not _laub_farn.is_empty():
		Bauspeicher.ablegen(schluessel(), {"rasen": zustand, "laub_farn": _laub_farn})
	_laub_farn = {}


## Der Rasen aus dem Bauspeicher: Laub und Farn, dann der Rasen – in der
## Reihenfolge des Baus, mit denselben Funktionen. Lässt er sich nicht lesen,
## wird hier wie beim ersten Mal gebaut.
func _aus_speicher() -> void:
	var gesichert: Variant = Bauspeicher.gespeichert(schluessel())
	var d: Dictionary = gesichert if gesichert is Dictionary else {}
	_farn_stoff_anlegen()
	var neu := _bau_neu()
	var stoffe: Array[Material] = [null, _farn_stoff]
	if not d.has("rasen") or not d.has("laub_farn") \
			or not neu.zustand_setzen(d["rasen"] as Dictionary, stoffe):
		neu = null
		for schritt: Dictionary in _bau_schritte():
			(schritt["tun"] as Callable).call()
		return
	_laub_farn_einhaengen(d["laub_farn"] as Dictionary)
	neu.fertig()


## Ein Rasenbau mit Kisten, Kamera (K8), Walddichte und Saat des Levels.
func _bau_neu() -> Bau:
	var kamera := level.get_node_or_null("CorridorCamera") as KorridorKamera
	var optionen := {"kisten": level.kisten_orte(), "kamera": kamera, "saat": SAAT + 1,
			"name": "Rasen"}
	if level.wald != null:
		optionen["wald"] = level.wald.dichte
	return Bau.new(level.deko, level.weg, hoehe, optionen)


## Der Kupferfarn: eine Abschrift von `Farnwerk.stoff()` (siehe Kopf).
func _farn_stoff_anlegen() -> void:
	if _farn_stoff != null:
		return
	_farn_stoff = Farnwerk.stoff().duplicate() as ShaderMaterial
	_farn_stoff.set_shader_parameter("farbe", KUPFER)


# ================================================================ Abfragen

## Höhe für Rasen und Farn an (x, z): die gezeichnete Oberkante (Krone des
## Saums oder Gelände); NAN im Wasser.
func hoehe(x: float, z: float) -> float:
	var g := level.gelaende
	var sq := g.projektion(x, z)
	if level.wald != null and level.wald.nass(sq.x, sq.y):
		return NAN
	return g.sicht_oberkante(x, z)


## |q| der Wandkrone eines Zuges „auf" an `s` (Linie + Lauf der Wand + 0,1 m),
## NAN, wo er nicht gilt oder flach in der Übergabe liegt.
func _wandkrone(zug: Dictionary, s: float) -> float:
	if s < float(zug["von"]) or s > float(zug["bis"]):
		return NAN
	var m := L05Saum.form_auf(level, zug, s)
	if float(m["ueb"]) < 0.5:
		return NAN
	var l := absf(Level05.leitlinie_q(Level05.leitlinie_punkte(float(zug["seite"])), s))
	return l + float(m["lauf"]) + 0.1


## Mindestens 1 m von jeder Kiste (wie `Rasenbau.KISTE_FREI`)?
func _kiste_frei(s: float, q: float) -> bool:
	for k in _kisten:
		if Vector2(s, q).distance_to(k) < Rasenbau.KISTE_FREI:
			return false
	return true


static func _zug(name_: String) -> Dictionary:
	for z: Dictionary in Level05.ZUEGE:
		if String(z["name"]) == name_:
			return z
	return {}


## Ein Häufchen Laub: 7–13 Blätter (je vier Dreiecke, eine flache Raute mit
## geknickter Mittelrippe), flach und leicht gekippt, 7–12 cm lang.
func _laubhaeufchen(rng: RandomNumberGenerator) -> Bodenstreu.Teil:
	var t := Bodenstreu.Teil.new()
	for i in rng.randi_range(7, 13):
		var w := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.34
		var mitte := Vector3(cos(w) * r, rng.randf_range(0.004, 0.02), sin(w) * r)
		var lang := rng.randf_range(0.07, 0.12)
		var breit := lang * rng.randf_range(0.45, 0.65)
		var dreh := rng.randf() * TAU
		var vor := Vector3(cos(dreh), 0.0, sin(dreh))
		var quer := Vector3(-vor.z, 0.0, vor.x)
		var kipp := Vector3(rng.randf_range(-0.35, 0.35), 1.0, rng.randf_range(-0.35, 0.35)).normalized()
		vor = (vor - kipp * vor.dot(kipp)).normalized()
		quer = (quer - kipp * quer.dot(kipp)).normalized()
		var farbe := LAUB_FARBEN[rng.randi() % LAUB_FARBEN.size()] * rng.randf_range(0.8, 1.15)
		farbe.a = 0.0
		var hell := farbe * 1.18
		hell.a = 0.0
		var a := mitte - vor * lang * 0.5
		var b := mitte + vor * lang * 0.5
		var rippe := mitte + kipp * lang * 0.06
		var l := mitte + quer * breit * 0.5
		var re := mitte - quer * breit * 0.5
		t.dreieck(a, l, rippe, kipp, farbe, farbe, hell, Bodenstreu.GROSS)
		t.dreieck(rippe, l, b, kipp, hell, farbe, farbe, Bodenstreu.GROSS)
		t.dreieck(a, rippe, re, kipp, farbe, hell, farbe, Bodenstreu.GROSS)
		t.dreieck(rippe, b, re, kipp, hell, farbe, farbe, Bodenstreu.GROSS)
	return t


## Ein Haufen (Laub, Streu) mit fertigem Netz: einmal gebaut (`Haufen.netz`
## aus den Scheiteln kostete beim Laden 18 ms für die Streu), als Daten für
## die Ablage und zurück.
static func haufen_fertig(h: Bodenstreu.Haufen) -> FertigerHaufen:
	var f := FertigerHaufen.new(h.ursprung)
	f.fertig_netz = null if h.leer() else h.netz()
	return f


static func haufen_daten(h: FertigerHaufen) -> Dictionary:
	return {"ursprung": h.ursprung, "netz": h.fertig_netz}


static func haufen_aus(d: Dictionary) -> FertigerHaufen:
	var f := FertigerHaufen.new(d["ursprung"] as Vector3)
	f.fertig_netz = d["netz"] as ArrayMesh
	return f


## Ein Haufen, dessen Netz schon gebaut ist: `knoten` (Bodenstreu) hängt es
## ein, ohne es aus den Scheiteln neu zu bauen.
class FertigerHaufen:
	extends Bodenstreu.Haufen
	var fertig_netz: ArrayMesh

	func netz() -> ArrayMesh:
		return fertig_netz

	func leer() -> bool:
		return fertig_netz == null


## `Rasenbau` mit einem Zustand für den Bauspeicher: Was `fertig` zu Knoten
## macht – je Stück die Lagen und Farben von Halmen, Büscheln, Wispeln,
## Moos, Farnen, Großblättern und Rahmenfarnen und der Streuhaufen –, als
## Daten heraus (`zustand`) und wieder hinein (`zustand_setzen`); danach
## baut `fertig` wie beim ersten Mal. WARUM hier und nicht in rasenbau.gd:
## Der geteilte Baustein bleibt unberührt (Null-Pfad); die Felder, die hier
## gelesen werden, sind die von `Rasenbau.Sammlung`.
class Bau:
	extends Rasenbau

	const FELDER: Array[String] = ["gras", "bueschel", "wispel", "polster", "farn", "gross"]

	func zustand() -> Dictionary:
		var aus := {}
		for i: int in _sammlungen:
			var sa: Rasenbau.Sammlung = _sammlungen[i]
			# Die Streu bekommt hier ihr fertiges Netz: `fertig` baut es dann
			# nicht noch einmal.
			if sa.haufen != null:
				sa.haufen = L05Rasen.haufen_fertig(sa.haufen)
			var e := {"rahmen": sa.rahmen.duplicate(true),
					"haufen": {} if sa.haufen == null else L05Rasen.haufen_daten(
						sa.haufen as L05Rasen.FertigerHaufen)}
			for f in FELDER:
				e[f] = sa.get(f)
				e[f + "_farben"] = sa.get(f + "_farben")
			aus[i] = e
		return {"sammlungen": aus, "stoffe": _rahmen_stoffe.size()}

	## false, wenn die Stoffe der Rahmenfarne nicht passen (dann bleibt der
	## Bau leer).
	func zustand_setzen(d: Dictionary, stoffe: Array[Material]) -> bool:
		if int(d.get("stoffe", -1)) != stoffe.size():
			return false
		_rahmen_stoffe = stoffe
		_sammlungen = {}
		var sammlungen: Dictionary = d["sammlungen"]
		for i: int in sammlungen:
			var e: Dictionary = sammlungen[i]
			var sa := Rasenbau.Sammlung.new()
			for f in FELDER:
				var lagen: Array[Transform3D] = sa.get(f)
				lagen.assign(e[f])
				sa.set(f + "_farben", e[f + "_farben"] as PackedColorArray)
			var rahmen: Dictionary = e["rahmen"]
			for rs: Vector2i in rahmen:
				var r: Dictionary = rahmen[rs]
				var lagen: Array[Transform3D] = []
				lagen.assign(r["lagen"])
				sa.rahmen[rs] = {"lagen": lagen, "farben": r["farben"] as PackedColorArray}
			var haufen: Dictionary = e["haufen"]
			if not haufen.is_empty():
				sa.haufen = L05Rasen.haufen_aus(haufen)
			_sammlungen[i] = sa
		return true
