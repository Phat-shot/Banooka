extends Node
## Baukastenprobe: Rechnen die Bausteine für Raum 1 (`scripts/gemeinsam/`)
## mit den Daten von Level 01 genau dasselbe wie die Originale in Level 01?
## (Plan `baukasten.md` §1.7.)
##
##   godot --headless --path <Kopie> res://werkzeuge/Baukastenprobe.tscn
##
## WARUM. Die Bausteine sind KOPIEN aus `level01.gd` und seinen Modulen,
## verallgemeinert (Stufe A der Technikkarte): Level 01 bleibt wörtlich, wie
## es ist. Ob die Kopie dabei etwas verändert hat, zeigt kein Bild – Level
## 01 benutzt sie ja nicht. Diese Probe füttert jeden Baustein mit den
## Konstanten von Level 01 und vergleicht mit dem Original. Erwartet wird
## Gleitkomma-GLEICHHEIT (`==`, keine Toleranz; NAN gleich NAN): Derselbe
## Rechenweg auf denselben Zahlen liefert dieselben Bits. Jede Abweichung
## ist eine echte Änderung am Rechenweg.
##
## Level 01 wird dafür nicht gebaut: Ein `Level01`, das nie in den Baum
## kommt, läuft kein `_ready`; `_verlauf_anlegen()` legt nur die Kurve an,
## und alle Abfragen rechnen allein auf Kurve und Konstanten. Die Bauteile
## (Decke, Leitlinien, Schultern, Todeszonen) baut die Probe in einen
## eigenen, freien Knoten und vergleicht Knoten für Knoten.
##
## TEILE (je Paket einer, Plan §2):
##   Wegdaten (G1)  Abfragen alle 0,5 m von −8 bis 300: abschnitt_bei,
##                  breite_bei, ist_luecke, boden_bei, strang_bei, rand_bei,
##                  weg_von_der_kante, Wegrand, Kanten vor/nach, weg_punkt,
##                  rand_profil links und rechts; Begehbares (Lage,
##                  Querschnitte, Oberkanten, Kollisionsformen); Lücken und
##                  Sprungfälle; Rohbau (Decke samt Netzen und Stufen,
##                  Leitlinien, Schultern, Todeszonen).
##   Stoffe (G3)    Kanten: jedes Profil (ab, ufer, boeschung, wand, stirn
##                  mit und ohne Wegmaske, in_luecke) an jeder Probe der
##                  Linien von Level 01 gegen saum.gd, einzeln und so
##                  zusammengesetzt wie `_profil_rechts`/`_profil_links`;
##                  `flaeche_punkt` gegen den Merker von GelaendeSaum;
##                  Wellen, Klüfte, Überhänge; feste Strecken. Stoffe von
##                  Kanten, Gelände, Wegdecke (Waldweg, Wurzelrücken) und
##                  Bach gegen die Originale, Uniform für Uniform. Die
##                  Lückenlippen Knoten für Knoten samt Netzen. Shadertexte
##                  (bach, nebeltafel, Lippen, Nebelzeilen). Das Bachband
##                  (Abtasten, Band, Kappen) an Probeläufen. `nebelarm` gegen
##                  `L01Weltenbaum._nebelarm` mit der Umgebung von Level 01.
##   Bewuchs (G4)   Waldrahmen gegen L01Wald (statische Merker nach
##                  `_bahn_anlegen`/`_kegel_anlegen` mit Level 01): Auge
##                  (9,5/6) alle 0,5 m, Wegabstand, nächste Probe und quer auf
##                  einem Raster, `weg_frei`, `stamm_frei`, `kegel_frei` (beide
##                  Kegellisten) und `kiste_frei` an festen Hüllen und Füßen
##                  entlang des Wegs; die Netze `fernbaum` und `tannenkrone`
##                  Feld für Feld. Dazu, nicht bitgleich, sondern auf
##                  ±0,3 m: `auge()` gegen den Ort einer echten
##                  `KorridorKamera` nach `sofort_ausrichten()` auf der Kurve
##                  von Level 01, mit 9,5/6 und mit −21/5,6 (Level 05).
##
## Ausgabe: je Prüfung eine Zeile mit der Zahl der Vergleiche, die ersten
## Abweichungen im Wortlaut, am Ende
##   === Baukastenprobe: <n> Vergleiche, <m> Abweichungen ===
## Rückgabe 1, sobald eine Abweichung da ist.

## Abstand der Probestellen und ihr Bereich (Level 01 läuft von −7,5 bis 287,3).
const SCHRITT := 0.5
const VON := -8.0
const BIS := 300.0
## So viele Abweichungen werden je Prüfung im Wortlaut gezeigt.
const ZEIGEN := 8

var _vergleiche := 0
var _abweichungen := 0
## Zähler der laufenden Prüfung (für ihre Zeile).
var _teil_vergleiche := 0
var _teil_abweichungen := 0


func _ready() -> void:
	print("=== Baukastenprobe ===")
	_teil_wegdaten()
	_teil_stoffe()
	_teil_bewuchs()
	print("=== Baukastenprobe: %d Vergleiche, %d Abweichungen ===" % [_vergleiche, _abweichungen])
	get_tree().quit(1 if _abweichungen > 0 else 0)


# ============================================================ Wegdaten (G1)

func _teil_wegdaten() -> void:
	print("--- Wegdaten gegen Level01 ---")
	var l01 := Level01.new()
	l01.call("_verlauf_anlegen")
	var weg := Wegdaten.new(l01.verlauf, {
		"abschnitte": Level01.ABSCHNITTE, "begehbares": Level01.BEGEHBARES,
		"leitlinien": Level01.LEITLINIEN, "todeszonen": Level01.TODESZONEN,
		"raender": Level01.RAENDER,
	})

	# --- Abfragen alle 0,5 m ---
	_anfang()
	var stellen := 0
	var s := VON
	while s <= BIS + 0.001:
		stellen += 1
		var wo := "s %.1f" % s
		_pruefe("abschnitt_bei " + wo, l01.abschnitt_bei(s), weg.abschnitt_bei(s))
		_pruefe("breite_bei " + wo, l01.breite_bei(s), weg.breite_bei(s))
		_pruefe("ist_luecke " + wo, l01.ist_luecke(s), weg.ist_luecke(s))
		_pruefe("boden_bei " + wo, l01.boden_bei(s), weg.boden_bei(s))
		_pruefe("strang_bei " + wo, l01.strang_bei(s), weg.strang_bei(s))
		_pruefe("rand_bei " + wo, l01.rand_bei(s), weg.rand_bei(s))
		_pruefe("rand_bei 2,0 " + wo, l01.rand_bei(s, 2.0), weg.rand_bei(s, 2.0))
		_pruefe("weg_von_der_kante " + wo, l01.weg_von_der_kante(s, 2.5),
				weg.weg_von_der_kante(s, 2.5))
		_pruefe("Wegrand " + wo, l01.call("_wegrand", s), weg.wegrand(s))
		_pruefe("Kante vor " + wo, l01.call("_kante_vor", s), weg.kante_vor(s))
		_pruefe("Kante nach " + wo, l01.call("_kante_nach", s), weg.kante_nach(s))
		for q: float in [-3.0, 0.0, 2.5]:
			_pruefe("weg_punkt q %.1f %s" % [q, wo], l01.weg_punkt(s, q, 0.9),
					weg.weg_punkt(s, q, 0.9))
		for seite: float in [-1.0, 1.0]:
			_pruefe("rand_profil %+.0f %s" % [seite, wo], l01.rand_profil(s, seite),
					weg.rand_profil(s, seite))
		s += SCHRITT
	_zeile("Abfragen an %d Stellen je %.1f m (%.1f … %.1f)" % [stellen, SCHRITT, VON, BIS])

	# --- Begehbares: Lage, Querschnitte, Oberkanten ---
	_anfang()
	var proben := 0
	for roh: Dictionary in Level01.BEGEHBARES:
		var name := String(roh["name"])
		_pruefe("begehbar " + name, l01.begehbar(name), weg.begehbar(name))
		for p: Vector2 in _oberkanten_stellen(roh):
			proben += 1
			_pruefe("oberkante %s s %.2f q %.2f" % [name, p.x, p.y],
					l01.oberkante(name, p.x, p.y), weg.oberkante(name, p.x, p.y))
	_pruefe("begehbar unbekannt", l01.begehbar("gibt es nicht"), weg.begehbar("gibt es nicht"))
	_zeile("Begehbares: %d Einträge, %d Oberkanten" % [Level01.BEGEHBARES.size(), proben])

	# --- Lücken und Sprungfälle ---
	_anfang()
	var luecken := weg.luecken()
	_pruefe("Zahl der Lücken", Level01.LUECKEN.size(), luecken.size())
	for i in mini(luecken.size(), Level01.LUECKEN.size()):
		var l: Dictionary = Level01.LUECKEN[i]
		_pruefe("Lücke " + String(l["name"]), Vector2(float(l["von"]), float(l["bis"])),
				luecken[i])
	var bahnen: Array[float] = [0.0, 2.4]
	var eigene := weg.sprungfaelle_aus_luecken(Level01.LANDUNG_SPIEL, bahnen)
	var gefunden := 0
	for fall: Dictionary in l01.sprungfaelle():
		var name := String(fall["name"])
		if name == "Mooslog" or name.begins_with("Furt"):
			continue
		var start: Vector2 = fall["start"]
		var passend: Dictionary = {}
		for e: Dictionary in eigene:
			if float(e["kante"]) == float(fall["kante"]) \
					and (e["start"] as Vector2).y == start.y:
				passend = e
		if passend.is_empty():
			_abweichung("Sprungfall %s fehlt in sprungfaelle_aus_luecken" % name)
			continue
		gefunden += 1
		for schluessel: String in ["start", "kante", "von", "landung"]:
			_pruefe("Sprungfall %s %s" % [name, schluessel], fall[schluessel],
					passend[schluessel])
	_zeile("Lücken %d, Sprungfälle über Lücken %d" % [luecken.size(), gefunden])

	# --- Rohbau ---
	var alt := Node3D.new()
	l01.add_child(alt)
	l01.geometrie = alt
	var neu := Node3D.new()

	_anfang()
	l01.call("_weg_bauen")
	var decke := weg.decke_bauen(neu, func(a: Dictionary) -> Material:
		return L01Boden.stoff(l01, a))
	_baum_pruefe("Decke", alt.get_children(), decke.get_children())
	_zeile("Decke: %d Knoten (Netze je Stoff, Kollision, Stufen)" % _zaehle(decke))

	for teil: Array in [["Leitlinien", "_leitlinien_bauen", weg.leitlinien_bauen],
			["Schultern", "_schultern_bauen", weg.schultern_bauen],
			["Todeszonen", "_gefahren_setzen", weg.todeszonen_bauen]]:
		_anfang()
		var vorher := alt.get_child_count()
		l01.call(String(teil[1]))
		var original: Array[Node] = []
		for i in range(vorher, alt.get_child_count()):
			original.append(alt.get_child(i))
		var gebaut: Node3D = (teil[2] as Callable).call(neu)
		var kopie: Array[Node] = [gebaut]
		_baum_pruefe(String(teil[0]), original, kopie)
		_zeile("%s: %d Knoten" % [String(teil[0]), _zaehle(gebaut)])

	# Begehbares: Die Optik von Level 01 baut sich aus seinen Modulen (mit
	# Zwischenspeichern und Modellen) – verglichen werden deshalb Lage und
	# Kollisionsformen, die Optik ist bei Wegdaten ein Platzhalter.
	_anfang()
	var koerper_neu := weg.begehbares_bauen(neu, Callable())
	var i_koerper := 0
	for roh: Dictionary in Level01.BEGEHBARES:
		var name := String(roh["name"])
		var e := l01.begehbar(name)
		var formen_alt: Array[CollisionShape3D] = l01.call("_formen", e)
		var k := koerper_neu.get_child(i_koerper) as StaticBody3D
		i_koerper += 1
		if k == null:
			_abweichung("Begehbares %s: kein Körper" % name)
			continue
		_pruefe("Begehbares %s Name" % name, name, String(k.name))
		_pruefe("Begehbares %s Lage" % name, e["lage"], k.transform)
		_pruefe("Begehbares %s Ebene" % name, int(e["ebene"]), k.collision_layer)
		var formen_neu: Array[Node] = []
		for kind in k.get_children():
			if kind is CollisionShape3D:
				formen_neu.append(kind)
		var alt_knoten: Array[Node] = []
		alt_knoten.assign(formen_alt)
		_baum_pruefe("Begehbares " + name, alt_knoten, formen_neu)
		for f in formen_alt:
			f.free()
	_zeile("Begehbares: %d Körper (Lage, Ebene, Formen)" % i_koerper)

	neu.free()
	l01.free()


## Stellen (s, q), an denen die Oberkante eines Begehbaren verglichen wird:
## bei Körpern um die Mitte, bei Streifen und Sweeps über ihre ganze Länge
## und quer über den Weg hinaus.
func _oberkanten_stellen(e: Dictionary) -> Array[Vector2]:
	var liste: Array[Vector2] = []
	match String(e["form"]):
		"kasten", "zylinder", "kapsel":
			var s: float = e["s"]
			var q: float = e["q"]
			for ds: float in [-1.0, 0.0, 1.0]:
				for dq: float in [-0.5, 0.0, 0.5]:
					liste.append(Vector2(s + ds, q + dq))
		_:
			var s: float = e["von"]
			while s <= float(e["bis"]) + 0.001:
				for q: float in [-12.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 12.0]:
					liste.append(Vector2(s, q))
				s += SCHRITT
	return liste


# ============================================================ Stoffe (G3)

func _teil_stoffe() -> void:
	print("--- Kanten, Stoffe, Wasser gegen Level01 (G3) ---")
	var l01 := Level01.new()
	l01.call("_verlauf_anlegen")
	var weg := Wegdaten.new(l01.verlauf, {
		"abschnitte": Level01.ABSCHNITTE, "begehbares": Level01.BEGEHBARES,
		"leitlinien": Level01.LEITLINIEN, "todeszonen": Level01.TODESZONEN,
		"raender": Level01.RAENDER,
	})
	var platte := func(x: float) -> float: return L01Saum._platte(x)
	var ecke := func(x: float) -> float: return 1.0 - smoothstep(32.0, 32.6, x)
	var becken := func(x: float) -> float: return L01Saum._becken(x)
	var pfeiler := func(x: float) -> float: return L01Saum._pfeiler(x)

	# --- Rechts: Lippe von Level 01, jede Probe ---
	_anfang()
	var proben := GelaendeSaum.linie(l01.verlauf, L01Saum._lippe_rechts(l01),
			L01Saum.SCHRITT_RECHTS, L01Saum._feste_s())
	for i in proben.size():
		var probe: Dictionary = proben[i]
		var s: float = probe["s"]
		var bogen: float = probe["bogen"]
		var q: float = probe["q"]
		var kante := l01.boden_bei(s)
		var fuss_y: float = L01Saum._rand_rechts(l01, s)["fuss_y"]
		if is_nan(fuss_y):
			fuss_y = 5.4
		var ov := Kanten.ueberhang_lippe(bogen)
		var wo := "rechts s %.2f" % s
		_profil_pruefe("profil_ab " + wo, L01Saum._profil_ab(l01, s, bogen, q, kante, fuss_y, ov),
				Kanten.profil_ab(s, bogen, q, kante, fuss_y, ov, platte, ecke))
		_profil_pruefe("profil_ufer " + wo, L01Saum._profil_ufer(bogen, kante, fuss_y, ov),
				Kanten.profil_ufer(bogen, kante, fuss_y, ov))
		_profil_pruefe("Profil rechts " + wo, L01Saum._profil_rechts(i, probe, l01),
				_rechts_kopie(probe, l01, platte, ecke))
	_zeile("Rechts: %d Proben (ab, ufer, zusammengesetzt mit Kerbtal)" % proben.size())

	# --- Fläche der rechten Kante: Kanten.flaeche_punkt gegen den Merker
	# von GelaendeSaum (dieselben Querschnitte) ---
	_anfang()
	var g := GelaendeSaum.querschnitte(l01.verlauf, proben, 1.0,
			func(i: int, p_: Dictionary) -> GelaendeSaum.Profil:
				return L01Saum._profil_rechts(i, p_, l01),
			func(_i: int, p_: Dictionary) -> float: return l01.boden_bei(float(p_["s"])),
			func(_i: int, _p: Dictionary) -> float: return 0.0)
	GelaendeSaum.merken(1.0, g)
	var flaeche := {"s": g["s"], "boden": g["boden"], "reihen": g["reihen"]}
	var s_f := 30.0
	while s_f <= 165.0:
		for h: float in [-0.5, -3.0, -9.0, -14.0]:
			_pruefe("flaeche_punkt s %.1f h %.1f" % [s_f, h], GelaendeSaum.flaeche_punkt(s_f, 1.0, h),
					Kanten.flaeche_punkt(flaeche, s_f, h))
		s_f += 0.7
	GelaendeSaum.vergessen()
	_zeile("Fläche der rechten Kante: flaeche_punkt")

	# --- Links: Fuß von Level 01, jede Probe ---
	_anfang()
	proben = GelaendeSaum.linie(l01.verlauf, L01Saum._fuss_links(l01), L01Saum.SCHRITT_LINKS,
			L01Saum._feste_s())
	for i in proben.size():
		var probe: Dictionary = proben[i]
		var s: float = probe["s"]
		var bogen: float = probe["bogen"]
		var q_linie := absf(float(probe["q"]))
		var kante := l01.boden_bei(s)
		var wegrand: float = L01Saum._wegrand(l01, s)
		var krone: float = L01Saum._krone_links(l01, s)
		var wo := "links s %.2f" % s
		for rinne: float in [0.0, 0.6]:
			_profil_pruefe("profil_boeschung %s Rinne %.1f" % [wo, rinne],
					L01Saum._profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne),
					Kanten.profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne))
		_profil_pruefe("profil_wand " + wo,
				L01Saum._profil_wand(s, bogen, q_linie, kante, wegrand, krone),
				Kanten.profil_wand(s, bogen, q_linie, kante, wegrand, krone, becken,
				L01Saum.BECKEN_Y, pfeiler, L01Saum.PFEILER_HOEHE))
		_profil_pruefe("Profil links " + wo, L01Saum._profil_links(i, probe, l01),
				_links_kopie(probe, l01, becken, pfeiler))
	_zeile("Links: %d Proben (boeschung, wand, zusammengesetzt mit Rinne)" % proben.size())

	# --- Stirnen: Kerbe und Fallkerbe (mit Wegmaske), Erdspalt (ohne) ---
	_anfang()
	var stirnen := 0
	for graben: Array in [[56.0, 59.0, L01Saum.KERBE_GRUND, -5.4],
			[118.0, 121.0, L01Saum.FALLKERBE_GRUND, -5.2]]:
		var von: float = graben[0]
		var bis: float = graben[1]
		var grund: float = graben[2]
		var halb := (bis - von) * 0.5
		for ende in 2:
			var s := von if ende == 0 else bis
			var innen := s - 0.01 if ende == 0 else s + 0.01
			var rechts: float = L01Saum._wegrand(l01, innen) - 0.55
			var kante := l01.boden_bei(innen)
			for p_: Dictionary in GelaendeSaum.linie(l01.verlauf,
					PackedVector2Array([Vector2(s, float(graben[3])), Vector2(s, rechts)]),
					L01Saum.SCHRITT_QUER):
				stirnen += 1
				_profil_pruefe("profil_stirn s %.1f q %.2f" % [s, float(p_["q"])],
						L01Saum._profil_stirn(0, p_, kante, grund, halb, false, 0.45, l01),
						Kanten.profil_stirn(p_, kante, grund, halb, false, 0.45, weg))
	for ende in 2:
		var linie := PackedVector2Array()
		var q := -10.6
		while q <= 10.61:
			linie.append(Vector2(L01Saum.erdspalt_linie(q, ende), q))
			q += 0.4
		var kante := l01.boden_bei(25.0 if ende == 0 else 27.5)
		for p_: Dictionary in GelaendeSaum.linie(l01.verlauf, linie, L01Saum.SCHRITT_QUER):
			stirnen += 1
			var eng := pow(smoothstep(5.2, 10.6, absf(float(p_["q"]))), 0.8)
			var halb := 1.25 * (1.0 - eng) + 0.02
			var grund := lerpf(L01Saum.ERDSPALT_GRUND, kante - 2.5, smoothstep(0.55, 1.0, eng))
			_profil_pruefe("Erdspalt %d q %.2f" % [ende, float(p_["q"])],
					L01Saum._profil_erdspalt(0, p_, kante, l01),
					Kanten.profil_stirn(p_, kante, grund, halb, true, L01Saum.ERDSPALT_NARBE))
	_zeile("Stirnen: %d Proben (Kerbe, Fallkerbe mit Wegmaske; Erdspalt)" % stirnen)

	# --- Helfer und feste Strecken ---
	_anfang()
	var x := -40.0
	while x <= 400.0:
		for versatz: float in [1.0, 13.0, 31.0, 42.0]:
			_pruefe("welle %.1f/%.0f" % [x, versatz], L01Saum._welle(x, versatz),
					Kanten.welle(x, versatz))
			_pruefe("kluft %.1f/%.0f" % [x, versatz], L01Saum._kluft(x, versatz),
					Kanten.kluft(x, versatz))
			_pruefe("ueberhang_quer %.1f/%.0f" % [x, versatz],
					L01Saum._ueberhang_quer(x, versatz), Kanten.ueberhang_quer(x, versatz))
		x += 0.37
	var feste_alt := L01Saum._feste_s()
	var feste_neu := Kanten.feste_strecken(weg)
	feste_alt.sort()
	feste_neu.sort()
	_pruefe("feste Strecken (sortiert)", feste_alt, feste_neu)
	_zeile("Wellen, Klüfte, Überhänge, feste Strecken")

	# --- Stoffe ---
	_anfang()
	_stoff_pruefe("Kanten.stoff({})", GelaendeSaum.stoff(), Kanten.stoff({}))
	_stoff_pruefe("GelaendeBau.stoff({})", L01Gelaende._stoff(), GelaendeBau.stoff({}))
	var waldweg: Dictionary = {}
	var wurzel: Dictionary = {}
	for a: Dictionary in Level01.ABSCHNITTE:
		if String(a.get("stoff", "")) == "wurzelruecken":
			if wurzel.is_empty():
				wurzel = a
		elif waldweg.is_empty():
			waldweg = a
	_stoff_pruefe("Wegdecke Waldweg", L01Boden.stoff(l01, waldweg),
			Wegdecke.stoff({}, weg, Level01.ABSCHNITTE, "probe_waldweg"))
	var rinde := Materialbibliothek.rinde()
	_stoff_pruefe("Wegdecke Wurzelrücken", L01Boden.stoff(l01, wurzel),
			Wegdecke.stoff({"wurzelruecken": true, "boden_farbe": rinde.albedo_texture,
			"boden_normal": rinde.normal_texture,
			"flanke": Materialbibliothek.waldweg().albedo_texture,
			"uniforms": {"borke_ton": Color(1.0, 0.95, 0.86), "moos_ton": Color(1.06, 1.04, 0.78)}},
			weg, Level01.ABSCHNITTE, "probe_wurzel"))
	Wegdecke.vergessen("probe_")
	# Der Shader des Baches ist eine Datei mit Kopf: Ihr Text muss mit dem
	# des Originals ENDEN (siehe auch „Shadertexte").
	_stoff_pruefe("Bachband.stoff()", L01Wasser._bach_stoff(L01Wasser._texturen()),
			Bachband.stoff(), true)
	_pruefe("Kronenlicht-Stellen", L01Boden.kronen_stellen(l01),
			Wegdecke.kronen_stellen(Level01.ABSCHNITTE))
	var s_k := -5.0
	while s_k <= 295.0:
		_pruefe("kronenlicht_bei %.1f" % s_k, L01Boden.kronenlicht_bei(l01, s_k),
				Wegdecke.kronenlicht_bei(Level01.ABSCHNITTE, s_k))
		s_k += 0.5
	_zeile("Stoffe: Kanten, Gelände, Wegdecke (2), Bach; Kronenlicht")

	# --- Shadertexte ---
	_anfang()
	var bach := (load("res://shaders/bach.gdshader") as Shader).code
	_pruefe("bach.gdshader endet mit BACH_SHADER % WELLEN_CODE",
			true, bach.ends_with(L01Wasser.BACH_SHADER % L01Wasser.WELLEN_CODE))
	var nebel := (load("res://shaders/nebeltafel.gdshader") as Shader).code
	_pruefe("nebeltafel.gdshader endet mit NEBEL_SHADER_CODE", true,
			nebel.ends_with(L01Gelaende.NEBEL_SHADER_CODE))
	_pruefe("Lippenshader", L01Boden.LIPPEN_SHADER, Wegdecke.LIPPEN_SHADER)
	_pruefe("Nebel-Uniforms", L01Weltenbaum.NEBEL_UNIFORMS, Nebelstoff.NEBEL_UNIFORMS)
	_pruefe("Nebel-Zeile", L01Weltenbaum.NEBEL_ZEILE, Nebelstoff.NEBEL_ZEILE)
	_zeile("Shadertexte: bach, nebeltafel, Lippen, Nebel")

	# --- Lückenlippen ---
	_anfang()
	var alt := Node3D.new()
	l01.add_child(alt)
	l01.geometrie = alt
	var neu := Node3D.new()
	var lippen_alt := L01Boden.lippen_bauen(l01)
	var lippen_neu := Wegdecke.lippen(neu, weg, {"luecken": Level01.LUECKEN})
	_pruefe("Lippen Name", String(lippen_alt.name), String(lippen_neu.name))
	_pruefe("Lippen Zahl", lippen_alt.get_child_count(), lippen_neu.get_child_count())
	for i in mini(lippen_alt.get_child_count(), lippen_neu.get_child_count()):
		var a := lippen_alt.get_child(i) as MeshInstance3D
		var b := lippen_neu.get_child(i) as MeshInstance3D
		var wo := "Lippe %s" % String(a.name)
		_pruefe(wo + " Name", String(a.name), String(b.name))
		_pruefe(wo + " Lage", a.transform, b.transform)
		_pruefe(wo + " Schatten", a.cast_shadow, b.cast_shadow)
		_pruefe(wo + " Sicht", Vector2(a.visibility_range_end, a.visibility_range_end_margin),
				Vector2(b.visibility_range_end, b.visibility_range_end_margin))
		_pruefe(wo + " Flächen", a.mesh.get_surface_count(), b.mesh.get_surface_count())
		_pruefe(wo + " Netz", a.mesh.surface_get_arrays(0), b.mesh.surface_get_arrays(0))
		_stoff_pruefe(wo + " Stoff", a.material_override, b.material_override)
	_zeile("Lückenlippen: %d Netze" % lippen_alt.get_child_count())
	neu.free()

	# --- Bachband an Probeläufen (Ufer über L01Gelaende.hoehe: ohne Modell
	# überall 4,0 – Spiegel 3,9 findet sein Ufer sofort, 4,3 nie) ---
	_anfang()
	var hoehe := func(hx: float, hz: float) -> float: return L01Gelaende.hoehe(hx, hz)
	var punkte := PackedVector3Array([Vector3(0, 3.9, 0), Vector3(6, 3.8, -4),
			Vector3(14, 3.95, -9), Vector3(20, 4.3, -15), Vector3(30, 4.2, -18), Vector3(38, 4.0, -26)])
	var breiten := PackedFloat32Array([3.0, 3.5, 4.0, 2.5, 3.0, 2.0])
	for fall: Array in [[Rect2(-100, -100, 200, 200), "ganz im Feld"],
			[Rect2(-10, -22, 46, 40), "am Feldrand"]]:
		var feld: Rect2 = fall[0]
		var bis := punkte.size()
		for i in punkte.size():
			if not feld.has_point(Vector2(punkte[i].x, punkte[i].z)):
				bis = i
				break
		var zeile_alt: Array[Dictionary] = L01Wasser._lauf_abtasten(punkte, breiten, bis, feld)
		var zeile_neu := Bachband._lauf_abtasten(punkte, breiten, bis, feld)
		_pruefe("Abtasten " + String(fall[1]), zeile_alt, zeile_neu)
		var netz_alt := L01Wasser.Netz.new()
		var netz_neu := Bachband.Netz.new()
		L01Wasser._kappe(netz_alt, zeile_alt, true)
		Bachband._kappe(netz_neu, zeile_neu, true, hoehe)
		L01Wasser._band_schreiben(netz_alt, zeile_alt)
		Bachband._band_schreiben(netz_neu, zeile_neu, hoehe)
		if bis == punkte.size():
			L01Wasser._kappe(netz_alt, zeile_alt, false)
			Bachband._kappe(netz_neu, zeile_neu, false, hoehe)
		var arrays_alt := netz_alt.fertig().surface_get_arrays(0)
		_pruefe("Band " + String(fall[1]), arrays_alt, netz_neu.fertig().surface_get_arrays(0))
		var gebaut := Bachband.bauen(alt, [{"name": "probe", "punkte": punkte, "breite": breiten}],
				Bachband.stoff(), {"hoehe": hoehe, "feld": feld})
		_pruefe("Bachband.bauen " + String(fall[1]), arrays_alt, gebaut.mesh.surface_get_arrays(0))
	_zeile("Bachband: 2 Probeläufe (Abtasten, Band, Kappen, bauen)")

	# --- nebelarm mit der Umgebung von Level 01 ---
	_anfang()
	var szene := (load("res://scenes/levels/Level01.tscn") as PackedScene).instantiate() as Level01
	var umgebung := (szene.get_node("WorldEnvironment") as WorldEnvironment).environment
	for anteil: float in [L01Weltenbaum.NEBEL_ANTEIL, 0.3]:
		var quelle := Weltenbaum.stoff_krone(true)
		_stoff_pruefe("nebelarm %.1f" % anteil, L01Weltenbaum._nebelarm(quelle, szene, anteil),
				Nebelstoff.nebelarm(quelle, umgebung, anteil))
	szene.free()
	_zeile("nebelarm: Krone, Anteil 0,5 und 0,3")

	l01.free()


## Das rechte Profil wie `L01Saum._profil_rechts` (saum.gd:636-669), aber
## aus den Bausteinen von `Kanten`.
func _rechts_kopie(probe: Dictionary, l01: Level01, platte: Callable,
		ecke: Callable) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var q_lippe: float = probe["q"]
	var kante := l01.boden_bei(s)
	var fuss_y: float = L01Saum._rand_rechts(l01, s)["fuss_y"]
	if is_nan(fuss_y):
		fuss_y = 5.4
	var ov := Kanten.ueberhang_lippe(bogen)
	var ufer: float = L01Saum._ufer_anteil(s)
	var p: GelaendeSaum.Profil
	if ufer <= 0.0:
		p = Kanten.profil_ab(s, bogen, q_lippe, kante, fuss_y, ov, platte, ecke)
	elif ufer >= 1.0:
		p = Kanten.profil_ufer(bogen, kante, fuss_y, ov)
	else:
		p = Kanten.profil_ab(s, bogen, q_lippe, kante, fuss_y, ov, platte, ecke).gemischt(
				Kanten.profil_ufer(bogen, kante, fuss_y, ov), ufer)
	var grund: float = L01Saum._luecken_grund(s) if s > 40.0 else NAN
	if not is_nan(grund):
		var mitte := 57.5 if s < 100.0 else 119.5
		var rand := clampf((absf(s - mitte) - 0.25) / 1.25, 0.0, 1.0)
		Kanten.in_luecke(p, grund, 0, p.anzahl() - 1, 1.2, rand, true)
	return p


## Das linke Profil wie `L01Saum._profil_links` (saum.gd:1262-1301).
func _links_kopie(probe: Dictionary, l01: Level01, becken: Callable,
		pfeiler: Callable) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var q_linie := absf(float(probe["q"]))
	var kante := l01.boden_bei(s)
	var wegrand: float = L01Saum._wegrand(l01, s)
	var krone: float = L01Saum._krone_links(l01, s)
	var fels := smoothstep(90.5, 93.5, s)
	var abseits := maxf(56.0 - s, s - 59.0)
	var rinne := 1.0 - smoothstep(0.0, 2.2, abseits) if abseits > 0.0 else 0.0
	var p: GelaendeSaum.Profil
	if fels <= 0.0:
		p = Kanten.profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne)
	elif fels >= 1.0:
		p = Kanten.profil_wand(s, bogen, q_linie, kante, wegrand, krone, becken,
				L01Saum.BECKEN_Y, pfeiler, L01Saum.PFEILER_HOEHE)
	else:
		p = Kanten.profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne).gemischt(
				Kanten.profil_wand(s, bogen, q_linie, kante, wegrand, krone, becken,
				L01Saum.BECKEN_Y, pfeiler, L01Saum.PFEILER_HOEHE), fels)
	var grund: float = L01Saum._luecken_grund(s)
	if not is_nan(grund):
		if s < 100.0:
			var rand := clampf((absf(s - 57.5) - 0.2) / 1.3, 0.0, 1.0)
			Kanten.in_luecke(p, grund, 0, p.anzahl() - 1, 2.2, rand)
		else:
			Kanten.in_luecke(p, grund, 0, 2, 0.0)
	var nische := smoothstep(76.0, 78.0, s) * (1.0 - smoothstep(98.0, 100.0, s))
	if nische > 0.0:
		for j in range(1, p.anzahl()):
			if p.absolut[j] == 0:
				p.o[j] = -(q_linie + p.o[j])
				p.absolut[j] = 1
	return p


## Zwei Profile Punkt für Punkt: alle acht Felder.
func _profil_pruefe(was: String, a: GelaendeSaum.Profil, b: GelaendeSaum.Profil) -> void:
	_pruefe(was + " o", a.o, b.o)
	_pruefe(was + " y", a.y, b.y)
	_pruefe(was + " farbe", a.farbe, b.farbe)
	_pruefe(was + " glatt", a.glatt, b.glatt)
	_pruefe(was + " rauschen", a.rauschen, b.rauschen)
	_pruefe(was + " richtung", a.richtung, b.richtung)
	_pruefe(was + " schicht", a.schicht, b.schicht)
	_pruefe(was + " absolut", a.absolut, b.absolut)


## Zwei Stoffe Uniform für Uniform: Shadertext (mit `text_endet` muss der
## der Kopie nur auf den des Originals enden – eine Datei mit Kopf),
## Priorität, jeder Parameter (Texturen müssen dasselbe Objekt sein,
## Rauschtexturen dieselben Einstellungen), Metadaten.
func _stoff_pruefe(was: String, a: Material, b: Material, text_endet := false) -> void:
	var ma := a as ShaderMaterial
	var mb := b as ShaderMaterial
	if ma == null or mb == null:
		_pruefe(was + " ShaderMaterial", ma != null, mb != null)
		return
	if text_endet:
		_pruefe(was + " Shadertext endet gleich", true, mb.shader.code.ends_with(ma.shader.code))
	else:
		_pruefe(was + " Shadertext", ma.shader.code, mb.shader.code)
	_pruefe(was + " Priorität", ma.render_priority, mb.render_priority)
	for u: Dictionary in ma.shader.get_shader_uniform_list():
		var name := String(u["name"])
		var va: Variant = ma.get_shader_parameter(name)
		var vb: Variant = mb.get_shader_parameter(name)
		if va is NoiseTexture2D and vb is NoiseTexture2D:
			var ra := va as NoiseTexture2D
			var rb := vb as NoiseTexture2D
			var fa := ra.noise as FastNoiseLite
			var fb := rb.noise as FastNoiseLite
			_pruefe("%s %s Rauschen" % [was, name], [ra.width, ra.height, ra.seamless,
					ra.generate_mipmaps, fa.seed, fa.frequency, fa.noise_type, fa.fractal_octaves,
					ra.color_ramp.colors, ra.color_ramp.offsets],
					[rb.width, rb.height, rb.seamless, rb.generate_mipmaps, fb.seed, fb.frequency,
					fb.noise_type, fb.fractal_octaves, rb.color_ramp.colors, rb.color_ramp.offsets])
			continue
		_pruefe("%s %s" % [was, name], va, vb)
	_pruefe(was + " Meta", ma.get_meta("nebel_anteil", -1.0), mb.get_meta("nebel_anteil", -1.0))


# ============================================================ Bewuchs (G4)

## So weit darf `Waldrahmen.auge()` vom Ort der echten Kamera abweichen (m).
const AUGE_TOLERANZ := 0.3


func _teil_bewuchs() -> void:
	print("--- Bewuchs gegen wald.gd ---")
	var l01 := Level01.new()
	l01.call("_verlauf_anlegen")
	var weg := Wegdaten.new(l01.verlauf, {
		"abschnitte": Level01.ABSCHNITTE, "begehbares": Level01.BEGEHBARES,
		"leitlinien": Level01.LEITLINIEN, "todeszonen": Level01.TODESZONEN,
		"raender": Level01.RAENDER,
	})
	L01Wald._bahn_anlegen(l01)
	L01Wald._kegel_anlegen(l01)
	var rahmen := Waldrahmen.new(weg, null, [], {"von": -18.0, "bis": 292.0,
			"feld": L01Wald.FELD})
	var laenge := l01.verlauf.get_baked_length()

	# --- Auge mit 9,5/6: wald.gd verlängert die Kurve vor dem Anfang
	# geradeaus, der Rahmen klemmt wie die Kamera – verglichen wird, wo die
	# Kamerastation auf der Kurve liegt.
	_anfang()
	var s := 9.5
	var stellen := 0
	while s <= laenge:
		stellen += 1
		_pruefe("auge s %.1f" % s, L01Wald._auge(l01, s), rahmen.auge(s))
		s += SCHRITT
	_zeile("Auge 9,5/6 an %d Stellen (9,5 … %.1f)" % [stellen, laenge])

	# --- Wegabstand, nächste Probe, quer: Raster über das Feld von wald.gd.
	_anfang()
	var feld: Rect2 = L01Wald.FELD
	var punkte := 0
	var x := feld.position.x + 0.7
	while x < feld.end.x:
		var z := feld.position.y + 1.3
		while z < feld.end.y:
			punkte += 1
			var wo := "x %.1f z %.1f" % [x, z]
			_pruefe("wegabstand " + wo, L01Wald._wegabstand(x, z), rahmen.wegabstand(x, z))
			var i := L01Wald._naechste(x, z)
			_pruefe("naechste " + wo, i, rahmen.naechste(x, z))
			if i >= 0:
				_pruefe("quer " + wo, L01Wald._quer(i, x, z), rahmen.quer(i, x, z))
			z += 3.7
		x += 3.7
	_zeile("Wegabstand, nächste Probe, quer an %d Punkten" % punkte)

	# --- Regeln an festen Hüllen und Füßen entlang des Wegs ---
	var huellen: Array[AABB] = []
	var fuesse: Array[Vector3] = []
	var groessen: Array[Vector3] = [Vector3(6.0, 5.0, 6.0), Vector3(10.0, 4.0, 8.0),
			Vector3(3.0, 8.0, 3.0)]
	s = -10.0
	while s <= 290.0:
		for q: float in [-14.0, -9.0, -6.5, -4.0, 0.0, 4.0, 6.5, 9.0, 14.0]:
			var p := weg.weg_punkt(s, q)
			fuesse.append(p)
			for h: float in [-3.0, 2.0, 6.0, 9.0, 12.0]:
				for g in groessen:
					huellen.append(AABB(p + Vector3(0.0, h, 0.0) - g * 0.5, g))
		s += 3.0
	_anfang()
	for h in huellen:
		_pruefe("weg_frei %s" % str(h), L01Wald._weg_frei(h), rahmen.weg_frei(h))
	_zeile("weg_frei an %d Hüllen" % huellen.size())
	_anfang()
	for p in fuesse:
		for r: float in [0.4, 0.9]:
			var spitze := p + Vector3(0.6, 12.0, -0.4)
			_pruefe("stamm_frei %s r %.1f" % [str(p), r], L01Wald._stamm_frei(p, spitze, r, r * 2.0),
					rahmen.stamm_frei(p, spitze, r, r * 2.0))
	_zeile("stamm_frei an %d Füßen" % fuesse.size())
	_anfang()
	rahmen.kegel.assign(L01Wald._kegel)
	for h in huellen:
		_pruefe("kegel_frei %s" % str(h), L01Wald._kegel_frei(h, false), rahmen.kegel_frei(h))
	rahmen.kegel.assign(L01Wald._kegel_ohne_krone)
	for h in huellen:
		_pruefe("kegel_frei ohne Krone %s" % str(h), L01Wald._kegel_frei(h, true),
				rahmen.kegel_frei(h))
	_zeile("kegel_frei an %d Hüllen, %d bzw. %d Kegel" % [huellen.size(),
			L01Wald._kegel.size(), L01Wald._kegel_ohne_krone.size()])
	_anfang()
	var kisten: Array[Vector3] = []
	for e: Dictionary in Level01.KISTEN:
		kisten.append(weg.weg_punkt(float(e["s"]), float(e["q"])))
	L01Wald._kisten = kisten
	rahmen.kisten = kisten.duplicate()
	for p in fuesse:
		_pruefe("kiste_frei %s" % str(p), L01Wald._kistenfrei(p, 2.0), rahmen.kiste_frei(p, 2.0))
	_zeile("kiste_frei an %d Füßen, %d Kisten" % [fuesse.size(), kisten.size()])

	# --- Netze: Fernbäume und Tannenkronen Feld für Feld ---
	_anfang()
	L01Wald._netze.clear()
	for k in 3:
		_netz_pruefe("fernbaum %d" % k, L01Wald._fernbaum(k), Baumfabrik.fernbaum(k))
	for werte: Array in [[3.2, 13.9, 7, 11, 30, 1209], [2.9, 12.6, 5, 7, 0, 3103],
			[3.0, 12.04, 6, 11, 26, 2204]]:
		_netz_pruefe("tannenkrone %s" % str(werte),
				L01Wald._tannenkrone(werte[0], werte[1], werte[2], werte[3], werte[4], werte[5]),
				Baumfabrik.tannenkrone(werte[0], werte[1], werte[2], werte[3], werte[4], werte[5]))
	L01Wald._netze.clear()
	_zeile("Netze: 3 Fernbäume, 3 Tannenkronen")
	L01Wald._vergessen(0)

	# --- Auge gegen die echte Kamera ---
	_auge_gegen_kamera(l01, weg, 9.5, 6.0, 6.0)
	# Wie Level05.tscn: Rückblick, der Blickpunkt 5 m hinter der Figur.
	_auge_gegen_kamera(l01, weg, -21.0, 5.6, -5.0)
	l01.free()


## Stellt eine `KorridorKamera` auf die Kurve von Level 01, setzt eine Figur
## mitten auf die Decke und vergleicht nach `sofort_ausrichten()` den Ort
## der Kamera mit `Waldrahmen.auge()` – alle 2 m über die ganze Kurve.
## `vorlauf`: Blickpunkt der Kamera (ändert ihren Ort nicht, nur die
## Blickrichtung – mit 6 m hinter einem Rückblick stünde er unter ihr).
## Keine Kollision in der Welt: Der Sichtstrahl der Kamera trifft nichts.
func _auge_gegen_kamera(l01: Level01, weg: Wegdaten, abstand: float, hoehe: float,
		vorlauf: float) -> void:
	_anfang()
	var kurve := Path3D.new()
	kurve.name = "Kurve"
	kurve.curve = l01.verlauf
	add_child(kurve)
	var figur := Node3D.new()
	figur.name = "Figur"
	figur.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(figur)
	var kamera := (load("res://scenes/camera/CorridorCamera.tscn") as PackedScene).instantiate() \
			as KorridorKamera
	kamera.abstand = abstand
	kamera.hoehe = hoehe
	kamera.blick_vorlauf = vorlauf
	kamera.kurve_pfad = NodePath("../Kurve")
	kamera.ziel_pfad = NodePath("../Figur")
	add_child(kamera)
	var rahmen := Waldrahmen.new(weg, kamera, [])
	var laenge := l01.verlauf.get_baked_length()
	var groesste := 0.0
	var wo := 0.0
	var stellen := 0
	var s := 0.0
	while s <= laenge:
		figur.global_position = weg.weg_punkt(s)
		kamera.sofort_ausrichten()
		var d := kamera.global_position.distance_to(rahmen.auge(s))
		_vergleiche += 1
		_teil_vergleiche += 1
		stellen += 1
		if d > groesste:
			groesste = d
			wo = s
		if d > AUGE_TOLERANZ:
			_abweichung("auge %.1f/%.1f s %.1f: Kamera %s, Rahmen %s (%.3f m)" % [abstand, hoehe,
					s, str(kamera.global_position), str(rahmen.auge(s)), d])
		s += 2.0
	_zeile("Auge %.1f/%.1f gegen die Kamera an %d Stellen, größte %.3f m (s %.0f)" % [
			abstand, hoehe, stellen, groesste, wo])
	kamera.free()
	figur.free()
	kurve.free()


## Zwei Netze Feld für Feld (alle Flächen) samt eigener Hülle.
func _netz_pruefe(was: String, a: Mesh, b: Mesh) -> void:
	_pruefe(was + " Flächen", a.get_surface_count(), b.get_surface_count())
	for f in mini(a.get_surface_count(), b.get_surface_count()):
		var fa := a.surface_get_arrays(f)
		var fb := b.surface_get_arrays(f)
		for k in fa.size():
			_pruefe("%s Fläche %d Feld %d" % [was, f, k], fa[k], fb[k])
	_pruefe(was + " Hülle", a.get_aabb(), b.get_aabb())
	if a is ArrayMesh and b is ArrayMesh:
		_pruefe(was + " eigene Hülle", (a as ArrayMesh).custom_aabb, (b as ArrayMesh).custom_aabb)


# ============================================================ Vergleich

func _anfang() -> void:
	_teil_vergleiche = 0
	_teil_abweichungen = 0


func _zeile(was: String) -> void:
	print("  %-60s %6d Vergleiche, %d Abweichungen" % [was, _teil_vergleiche,
			_teil_abweichungen])


func _pruefe(was: String, original: Variant, kopie: Variant) -> void:
	_vergleiche += 1
	_teil_vergleiche += 1
	if _gleich(original, kopie):
		return
	_abweichung("%s: Level01 %s, Kopie %s" % [was, _kurz(original), _kurz(kopie)])


func _abweichung(text: String) -> void:
	_abweichungen += 1
	_teil_abweichungen += 1
	if _teil_abweichungen <= ZEIGEN:
		print("  ABWEICHUNG  " + text)


func _kurz(wert: Variant) -> String:
	var text := str(wert)
	return text if text.length() <= 160 else text.substr(0, 160) + " …"


## Gleichheit bis aufs Bit, NAN gleich NAN, Wörterbücher und Listen
## rekursiv. Objekte (Stoffe) müssen dasselbe Objekt sein.
func _gleich(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			var x: float = a
			var y: float = b
			return x == y or (is_nan(x) and is_nan(y))
		TYPE_VECTOR3:
			# Komponentenweise, NAN gleich NAN (flaeche_punkt liefert NAN-Punkte).
			var va: Vector3 = a
			var vb: Vector3 = b
			for k in 3:
				if not (va[k] == vb[k] or (is_nan(va[k]) and is_nan(vb[k]))):
					return false
			return true
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			if da.size() != db.size():
				return false
			for k: Variant in da:
				if not db.has(k) or not _gleich(da[k], db[k]):
					return false
			return true
		TYPE_ARRAY:
			var la: Array = a
			var lb: Array = b
			if la.size() != lb.size():
				return false
			for i in la.size():
				if not _gleich(la[i], lb[i]):
					return false
			return true
	return a == b


## Vergleicht zwei Knotenlisten Knoten für Knoten samt allen Kindern: Klasse,
## Lage, Ebenen, Gruppen, Formen (Maße, Punkte, Flächen) und Netze (alle
## Flächenfelder, Stoff, Schatten). Namen nur, wo sie lesbar gesetzt sind.
func _baum_pruefe(was: String, alt: Array[Node], neu: Array[Node]) -> void:
	_pruefe(was + " Zahl der Knoten", alt.size(), neu.size())
	for i in mini(alt.size(), neu.size()):
		_knoten_pruefe("%s/%d" % [was, i], alt[i], neu[i])


func _knoten_pruefe(pfad: String, a: Node, b: Node) -> void:
	_pruefe(pfad + " Klasse", a.get_class(), b.get_class())
	if a is Node3D and b is Node3D:
		_pruefe(pfad + " Lage", (a as Node3D).transform, (b as Node3D).transform)
		_pruefe(pfad + " sichtbar", (a as Node3D).visible, (b as Node3D).visible)
	if a is CollisionObject3D and b is CollisionObject3D:
		_pruefe(pfad + " Ebene", (a as CollisionObject3D).collision_layer,
				(b as CollisionObject3D).collision_layer)
		_pruefe(pfad + " Maske", (a as CollisionObject3D).collision_mask,
				(b as CollisionObject3D).collision_mask)
		_pruefe(pfad + " Gruppe todeszonen", a.is_in_group("todeszonen"),
				b.is_in_group("todeszonen"))
	if a is CollisionShape3D and b is CollisionShape3D:
		_form_pruefe(pfad, (a as CollisionShape3D).shape, (b as CollisionShape3D).shape)
	if a is MeshInstance3D and b is MeshInstance3D:
		var ma := a as MeshInstance3D
		var mb := b as MeshInstance3D
		_pruefe(pfad + " Stoff", ma.material_override, mb.material_override)
		_pruefe(pfad + " Schatten", ma.cast_shadow, mb.cast_shadow)
		_pruefe(pfad + " Flächen", ma.mesh.get_surface_count(), mb.mesh.get_surface_count())
		for f in mini(ma.mesh.get_surface_count(), mb.mesh.get_surface_count()):
			_pruefe("%s Fläche %d" % [pfad, f], ma.mesh.surface_get_arrays(f),
					mb.mesh.surface_get_arrays(f))
	var lesbar_a := not String(a.name).begins_with("@")
	var lesbar_b := not String(b.name).begins_with("@")
	if lesbar_a and lesbar_b:
		_pruefe(pfad + " Name", String(a.name), String(b.name))
	_pruefe(pfad + " Kinder", a.get_child_count(), b.get_child_count())
	for i in mini(a.get_child_count(), b.get_child_count()):
		_knoten_pruefe("%s/%d" % [pfad, i], a.get_child(i), b.get_child(i))


func _form_pruefe(pfad: String, a: Shape3D, b: Shape3D) -> void:
	if a == null or b == null:
		_pruefe(pfad + " Form vorhanden", a != null, b != null)
		return
	_pruefe(pfad + " Formklasse", a.get_class(), b.get_class())
	if a is BoxShape3D and b is BoxShape3D:
		_pruefe(pfad + " Kasten", (a as BoxShape3D).size, (b as BoxShape3D).size)
	elif a is ConvexPolygonShape3D and b is ConvexPolygonShape3D:
		_pruefe(pfad + " Punkte", (a as ConvexPolygonShape3D).points,
				(b as ConvexPolygonShape3D).points)
	elif a is ConcavePolygonShape3D and b is ConcavePolygonShape3D:
		_pruefe(pfad + " Dreiecke", (a as ConcavePolygonShape3D).get_faces(),
				(b as ConcavePolygonShape3D).get_faces())
	elif a is CylinderShape3D and b is CylinderShape3D:
		_pruefe(pfad + " Walze", Vector2((a as CylinderShape3D).radius,
				(a as CylinderShape3D).height), Vector2((b as CylinderShape3D).radius,
				(b as CylinderShape3D).height))
	elif a is CapsuleShape3D and b is CapsuleShape3D:
		_pruefe(pfad + " Kapsel", Vector2((a as CapsuleShape3D).radius,
				(a as CapsuleShape3D).height), Vector2((b as CapsuleShape3D).radius,
				(b as CapsuleShape3D).height))


func _zaehle(wurzel: Node) -> int:
	var n := 1
	for kind in wurzel.get_children():
		n += _zaehle(kind)
	return n
