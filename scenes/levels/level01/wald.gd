extends RefCounted
class_name L01Wald
## Level 01, Modul „Wald": der Wald in drei Tiefen (Plan Abschnitte 5, 7, 9,
## 11, 13). Gesetzt mit `Waldsetzer` (scripts/waldsetzer.gd), gebaut aus
## den prozeduralen Helden (`Riesenstamm`, `Kronenwolke`, `Farnwerk`,
## `Findling`) und, wo es sie gibt, aus Fremdmodellen (Felsen, M8).
##
## WAS HIER WÄCHST
##   Hallenwald  A (s −16 … 32): drei Stammreihen je Seite (|q| 7–10, 12–16,
##               18–24), versetzt (±2,4 m), Ø 0,5–2 m, jeder achte schief;
##               dazwischen Unterholz (Sträucher, junge Bäume). Die erste
##               Reihe neigt sich zum Weg und schließt über ihm das Dach –
##               erst ab 9,5 m, mit Löchern über `Level01.LICHTLOECHER` –,
##               die zweite und dritte tragen tiefe Kronen (ab gut 5 m), die
##               die Seiten in Augenhöhe schließen; rechts dazu ein dichter
##               Saum an der Hallenkante und Nadelbäume in der Ecke vor der
##               Enthüllung (s 17–25), damit die Startkamera dort nicht schon
##               ins helle Tal sieht. Drei Heldenstämme mit Brettwurzeln (vom
##               Weg weggedreht), ein gestürzter Stamm quer durch die Reihen,
##               Farne am Fuß, Stümpfe, Moosstämme und Felsen am Saum.
##   Hangwald    links über der Böschung und auf der Krone der Fallklamm
##               (s 31–166), bis `HANG_TIEFE` hinter die Kronenkante des
##               Saums: vorn an der Kante niedrige, breite Astbäume, die sich
##               über das linke Wegdrittel neigen (ab 9,5 m – der dunkle
##               Rahmen oben links), und tief beastete Bäume, deren Laub man
##               von unten sieht; dahinter Kronen nach der Walddichte, dazu
##               Unterholz zwischen den Stämmen.
##   Rahmen      die Bäume auf den Felsnadeln unter der Kante
##               (`RAHMENBAUM_STELLEN` "sims"): gedreht, nach außen geneigt,
##               nie im Sichtkegel zur Krone des Weltenbaums (sonst etwas
##               kleiner); ab `RAHMEN_NAH` schlicht.
##   Riesen      zwei Torriesen am Riesentor (`TORRIESEN`), drei Talriesen
##               rechts der Bachwiese (`TALRIESEN`), zwei Kanalbäume über C4
##               (sie schließen dort das Dach) und drei Überständer im Tal.
##               Alle in voller Größe (Plan M5: 32–38 m, Stamm Ø 3–4 m): Vom
##               Grat aus stehen ihre Kronen vor dem unteren Rand der
##               Weltenbaumkrone – der Größenvergleich, den D braucht.
##   Talwald     nah (bis `NAH_WEIT` vom Weg): in Hainen (Mitten mindestens
##               `HAIN_RASTER` m auseinander, wo das Gelände Wald trägt;
##               drei bis acht Bäume je Hain, mehr und weiter,
##               wo das Gelände dichten Wald trägt), ein großer Baum in der
##               Mitte, viele kleinere darum (Größe 0,6–1,5, schief verteilt),
##               Kronen, die sich überlappen und bis auf gut ein Drittel der
##               Höhe hinabreichen, Sträucher dicht an den Stämmen; zwischen
##               den Hainen offene Wiese mit einzelnen Sträuchern und grauem
##               Totholz; Tönung je Hain (oliv, gelbgrün, blaugrün), auf den
##               Riegeln dunkler, jeder fünfte ein Nadelbaum. Vor der
##               Seitenansicht der Bachwiese eine Lichtung (`LICHTUNG`).
##               Fern (ab `FERN_AB`): grobe Kronen, die bis fast zum Boden
##               reichen, unten breiter und heller (`_fernform`), je Zelle ein
##               Netz, wo das Gelände Wald trägt und kein naher Baum steht –
##               nur auf dem gezeichneten Feld, in Hainen (grobes Rauschen
##               über der Walddichte), nie als Einzelgänger (mindestens zwei
##               Nachbarn in `GRUPPE_WEITE`). Stünde eine Krone von einer
##               Station aus vor dem Himmel (Himmelsprobe `_einsinken`, auf
##               einem Raster der Geländehöhe), sinkt sie in den Boden ein:
##               ein Waldsaum auf dem Kamm statt einer Scheibe in der Luft;
##               hinter einem Kamm so weit, dass sie nicht als Ballon über
##               ihm hängt (wo das zu tief wäre, fällt der Baum weg).
##   Nadelbäume  gestufte, gezackte Kegel (`_tannenkrone`), nah mit
##               Blattkarten, fern ohne: spitze Umrisse neben den runden.
##   Hecken      rechts der Bachwiese (q 7,4–9,4) und um die Wurzelwiese,
##               grün; auf knapp jedem dritten Busch oben Blüten (weiß,
##               gedecktes Rosa, `_bluehend`).
##
## VIER FASSUNGEN EINES BAUMS (`_baum`, Dreiecke je Stamm + Krone)
##   voll        `Riesenstamm.baum`: Rippen, Brettwurzeln, Äste, die in den
##               Ballen der Krone enden (2,6k + 2,4k) – Rahmenbäume, Riesen
##   voll, freie Krone  voller Stamm, freie Krone aus drei bis fünf Ballen
##               an seiner Spitze (1,1–3,2k + 1–1,5k) – Hallen- und Astbäume,
##               deren Kronen meist über dem Bildrand liegen
##   mittel      schlichter Stamm, freie Krone (0,2k + 0,9–1,6k) – hintere
##               Reihen, naher Talwald, Überständer; mit "unten" reicht die
##               Krone bis dorthin hinab (gestreckt), mit "tanne" ist sie
##               eine `_tannenkrone` (0,3–0,5k)
##   fern        grobe Krone und vierseitiger Stamm im Laubstoff (0,25k)
## Die Kronen sitzen nach ihrer wirklichen Hülle: Scheitel auf der
## Baumhöhe, der Stamm endet in ihrer Mitte – Laub statt Lolli. Riesen und
## Rahmenbäume wechseln in der Ferne in eine schlichte Fassung gleicher
## Hülle (`_riese_fern`), Hang- und Talbäume in die ferne.
##
## REGELN (Plan 7, 11)
##   K1  Über |q| < 6 hängt keine Krone tiefer als 9,5 m über der Decke
##       (Hülle der gesetzten Krone gegen jede Wegprobe, `_weg_frei`); kein
##       Stamm steht dort unter 8,8 m (`_stamm_frei`).
##   Kegel  Kein Baum im ±6°-Kegel von der Kamera zur Krone des
##       Weltenbaums, je Station s 22–114 (davor verdeckt ihn der
##       Hallenwald) – ausgenommen die Riesen und Kanalbäume von D; keiner
##       im ±4°-Kegel zu seinem Stamm (y 15) von s 100–126; im Schlussbild
##       (s 274–287) keiner im ±3°-Kegel zum Wasserfall
##       (`Waldsetzer.kegel_frei`). Hält ein Riese einen Kegel nicht, wird
##       nur seine Krone schmaler, nie der ganze Baum kleiner.
##   Kante  Talkronen bleiben unter der Felskante von B und C mindestens
##       5 m unter der Decke (`_talkante_frei`).
##   Weg  Kein Stamm und keine Brettwurzel auf begehbarem Boden; Wurzeln
##       werden vom Weg weggedreht (`Waldsetzer.drehung_weg`).
##   Keine Kollision: Alles steht hinter Leitlinien, im Tal oder über dem
##       Kamerastrahl.
##
## KOSTEN (Plan 13: ≤ 70 Zeichenaufrufe, dazu ≤ 40 für Schatten, ≤ 240k
## Dreiecke samt Schatten je Station). Bäume werden je Zelle zu EINEM Netz
## je Stoff verschmolzen (Stämme, Kronen); Farne und Felsen als MultiMesh.
## Den Schatten eines Stamms wirft ein schlichter gleicher Achse, der nur
## in die Schattenkarte zeichnet ("…_schatten"); Laub wirft keinen, nur
## Felsen, Stümpfe und Moosstämme werfen selbst. Harte Sichtweiten je Zelle
## (`SICHT_*`), in der Ferne die schlichten Fassungen. Mit
## `Effekte.reduziert` (Web, Handy) wächst der ferne Wald zu 60 % und in
## gröberen Zellen (`ZELLE_FERN_WEB`).
## Gemessen (30.09.2026, Verfolger, llvmpipe; Unterschied zum Stand ohne
## Wald, Aufrufe samt Schatten): s 4 +229k/+61, s 31 +215k/+57,
## s 46 +207k/+50, s 70 +209k/+48, s 101 +218k/+47, s 119 +215k/+43,
## s 140 +148k/+32, s 176 +117k/+32, s 212 +108k/+18, s 249 +129k/+19,
## s 281 +176k/+35; Grafikspeicher +20,5 MB. Das ganze Bild im Web
## (`Effekte.reduziert`): 273–449 Aufrufe (s 140: 449, s 4: 442). Der
## Aufbau dauert headless knapp 1,5 s (acht Schritte, je unter 0,4 s), das
## ganze Level 7,3 s gegen 4,6 s für das alte Level 01 (auf derselben
## Maschine, ohne Stimmung).

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
const SICHT_HANG := 85.0
const SICHT_RAHMEN := 110.0
## Bis hierher (Zellmitte) die vollen Rahmenbäume, dahinter die schlichten.
const RAHMEN_NAH := 62.0
const SICHT_TAL := 80.0
const SICHT_FERN := 210.0
const SICHT_FARN := 42.0
const SICHT_FELS := 110.0
const SICHT_HECKE := 60.0
const SICHT_KRANZ := 60.0
## Die Riesen stehen als eine Zelle um s 170: vom Grat ab gut s 40 zu sehen,
## bis `RIESE_NAH` in der vollen Fassung.
const SICHT_RIESEN := 170.0
const RIESE_NAH := 90.0
## Zellgrößen (m).
const ZELLE_HANG := 45.0
const ZELLE_TAL := 48.0
const ZELLE_FERN := 64.0
## Im Web (`Effekte.reduziert`) gröber: weniger Zeichenaufrufe.
const ZELLE_FERN_WEB := 96.0
## Rasterweite des fernen Walds (m): Kronen von 5 m Radius schließen sich.
## Mit 10,5 lag zwischen den Kronen glatter Rasen (Tupfen statt Dach).
const FERN_RASTER := 9.2
## Haine des fernen Walds: Wellenlänge des Rauschens, das die Walddichte
## auf und ab schiebt (m), und die Weite, in der ein Baum mindestens zwei
## Nachbarn braucht (m).
const HAIN_WEITE := 46.0
const GRUPPE_WEITE := 14.0
## Tönung der Haine (mal Laub): oliv-gelb und blaugrün, dazwischen neutral.
const HAIN_GELB := Color(1.0, 0.95, 0.66)
const HAIN_BLAU := Color(0.78, 0.94, 1.0)
## Raster der Geländehöhe für die Himmelsprobe (m).
const HOEHEN_ZELLE := 2.0
## Ferne Kronen (`_fernform`): so viel breiter am Fuß, und dort beginnt
## ihr Farbverlauf von dunkel (0) nach hell (1).
const FERN_FUSS := 0.12
const FERN_UNTEN := 0.4
## Lagen der Ballen einer fernen Krone (`_fernbaum`), je Form (0 rund,
## 1 breit): Höhe über dem Fuß, Abstand von der Achse, Anzahl. Die letzte
## Lage ist der Wipfel.
const FERN_LAGEN := [
	[Vector3(3.4, 1.7, 3), Vector3(6.6, 1.4, 1)],
	[Vector3(3.3, 2.3, 3), Vector3(6.3, 1.5, 1)],
]
## Dort (Anteil der Höhe) beginnt die Krone eines fernen Baums; so weit
## (Anteil der Höhe) sinkt er ein, wenn sie sonst vor dem Himmel stünde,
## und weiter als `FERN_SINKEN_MAX` nie (`_einsinken`).
const FERN_BODEN := 0.1
const FERN_SINKEN := 0.2
const FERN_SINKEN_MAX := 0.5
## Himmelsprobe des fernen Walds (`_einsinken`): So weit zeichnet die
## Korridorkamera (`far`), dahinter ist Himmel. Augen alle `HIMMEL_SCHRITT`
## m entlang des Wegs, Proben alle `HIMMEL_TRITT` m auf dem Sehstrahl.
const KAMERA_FERN := 200.0
const HIMMEL_SCHRITT := 6.0
const HIMMEL_TRITT := 3.0
## Ein Kamm weiter weg als das verdeckt für die Himmelsprobe nichts: Im
## Tiefennebel (12 → 140 m) ist er kaum heller als der Himmel dahinter.
const KAMM_WEIT := 100.0
## Gelände hinter einer Krone zählt nur bis so weit von der Station: Was
## weiter liegt, schneidet die Kamera ab (`far`, sie steht nicht genau im
## Auge der Probe), die Krone stünde vor dem blanken Himmel.
const HIMMEL_HINTER := 175.0

## Naher Talwald: Mindestabstand der Hainmitten (m) und das Raster, auf
## dem sie gesucht werden (m), Mindestabstand der Stämme außerhalb eines
## Hains (m; im Hain 60 %), und die Lichtung vor der Seitenansicht der
## Bachwiese (s von, s bis, q von, q bis).
const HAIN_RASTER := 18.0
const HAIN_SCHRITT := 7.0
const TAL_ABSTAND := 2.3
const LICHTUNG := Vector4(178.0, 194.0, 16.0, 40.0)

## Laubfarben (Grundton des Stoffs; getönt wird je Baum über die Farbe).
const LAUB_HALLE := Color(0.15, 0.33, 0.14)
const LAUB_TAL := Color(0.19, 0.41, 0.15)
const LAUB_FERN := Color(0.2, 0.42, 0.17)
const LAUB_HECKE := Color(0.23, 0.47, 0.17)
const BLUETE := Color(0.96, 0.86, 0.88)
## Blüten auf den Hecken (Scheitelfarbe mal `BLUETE` mal Kronenstoff, der
## oben das Rot hebt): weiß und ein gedecktes Rosa.
const BLUETE_WEISS := Color(0.6, 1.0, 0.96)
const BLUETE_ROSA := Color(0.86, 0.8, 0.9)
const FARN := Color(0.2, 0.42, 0.15)
## Tönung der Nadelbäume: dunkler und kühler.
const NADEL_TON := Color(0.6, 0.72, 0.76)
## Tönung des Totholzes: grau, ausgeblichen.
const TOT_TON := Color(0.82, 0.8, 0.78, 0.25)
## Die schlichte Fassung der Riesen (nur vom Grat aus zu sehen, 100–160 m
## vor dem Fuß des Weltenbaums): Stamm und Krone etwas dunkler und kühler
## als die nahe, im vollen Dunst wie der Talwald um sie. Verglichen (s 46):
## Mit dem halben Nebel des Weltenbaums (`RIESE_FERN_NEBELARM`) und
## dunkler Tönung verschmolzen ihre Stämme mit seinem – ein Gewirr dunkler
## Säulen vor dem Stamm, ihre Kronen grüne Schirme vor seiner Krone. Im
## vollen Dunst treten sie zurück, und der Riese steht als dunkle Masse
## dahinter: der Größenvergleich statt eines Hains aus Schirmkiefern.
const RIESE_FERN_STAMM := Color(0.8, 0.8, 0.84)
const RIESE_FERN_KRONE := Color(0.85, 0.9, 0.96)
const RIESE_FERN_NEBELARM := false

## Die Hallenwald-Reihen je Seite: Querbereich, Abstand entlang s, Arten
## (rechts eigene: tief beastete Kronen bis an die Hallenkante – die Halle
## bleibt rechts in Augenhöhe geschlossen, bis sie sich bei s 26 öffnet).
const REIHEN := [
	{"q": Vector2(7.0, 10.0), "abstand": Vector2(4.6, 6.4), "arten": ["dach", "dach", "hoch", "duenn"]},
	{"q": Vector2(12.0, 16.0), "abstand": Vector2(5.0, 7.0),
			"arten": ["tief", "tief", "duenn", "schlicht_a", "schlicht_c"],
			"rechts": ["tief", "tief", "tief", "schlicht_a"]},
	{"q": Vector2(18.0, 24.0), "abstand": Vector2(5.5, 8.0),
			"arten": ["tief", "schlicht_a", "schlicht_b", "schlicht_c"],
			"rechts": ["tief", "tief", "schlicht_c"]},
	# Nur rechts: der Saum an der Hallenkante, dicht und tief beastet.
	{"q": Vector2(20.5, 24.2), "abstand": Vector2(4.0, 5.5), "arten": [], "rechts": ["tief"]},
]
## Anfang des Hallenwalds (hinter dem Start) und Ende links (Übergang in den
## Hangwald).
const HALLE_VON := -16.0
const HALLE_LINKS_BIS := 36.0
## Heldenstämme mit Brettwurzeln: (s, q).
const HELDEN := [Vector2(10.6, -8.4), Vector2(19.2, 8.6), Vector2(29.8, -8.8)]
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

## Sichtkegel (`_kegel_anlegen`): alle, und ohne die Kegel zur Kronenmitte
## des Weltenbaums (für die Riesen der Bachwiese, siehe `_riesen`).
static var _kegel: Array[Dictionary] = []
static var _kegel_ohne_krone: Array[Dictionary] = []
## Das Level, zu dem der Zwischenstand gehört (Aufräumen beim Verlassen).
static var _level_id := 0
static var _level_debug := false
## Augen der Himmelsprobe (Verfolgerkamera je Station) und ihre waagerechte
## Blickrichtung.
static var _himmel_augen := PackedVector3Array()
static var _himmel_blick := PackedVector3Array()
## Geländehöhe auf dem Raster der Himmelsprobe (`_hoehen_anlegen`).
static var _hoehen_raster := PackedFloat32Array()
static var _hoehen_mass := Vector2i.ZERO
## Ferne Bäume zwischen den zwei Schritten des fernen Walds.
static var _fern_kandidaten: Array[Dictionary] = []
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
		{"text": "Rahmenbäume an der Kante", "tun": func() -> void:
			_gemessen("rahmen", _rahmenbaeume.bind(level))},
		{"text": "Riesen an der Bachwiese", "tun": func() -> void:
			_gemessen("riesen", _riesen.bind(level))},
		{"text": "Wald im Tal", "tun": func() -> void:
			_gemessen("tal", _talwald_nah.bind(level))},
		{"text": "Ferner Wald", "tun": func() -> void:
			_gemessen("fern_sammeln", _talwald_fern_sammeln.bind(level))},
		{"text": "Wald auf den Hügeln", "tun": func() -> void:
			_gemessen("fern_setzen", _talwald_fern_setzen)},
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


static func _schritt_rest(level: Level01) -> void:
	_hecken(level)
	_felsen(level)
	_aufraeumen()


# ================================================================ Vorbereitung

static func _vorbereiten(level: Level01) -> void:
	_netze.clear()
	_zahlen.clear()
	# Wird das Level verlassen, bevor der letzte Schritt aufräumt, hielte
	# der Zwischenstand sonst alle Baumnetze (mehrere MB) und einen
	# freigegebenen Knoten bis zum nächsten Bau fest.
	_level_id = level.get_instance_id()
	_level_debug = level.debug
	var id := _level_id
	level.tree_exiting.connect(func() -> void: L01Wald._vergessen(id), CONNECT_ONE_SHOT)
	_kisten = level.kisten_orte()
	_staemme = Waldsetzer.Raster.new(8.0)
	_kronen = Waldsetzer.Raster.new(8.0)
	# Der Torbaum (Wegbauten) steht auf der Felsnase im Hangwald: Stamm und
	# Schirm (gut 5 m nach außen) bleiben frei.
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		if String(stelle["art"]) == "torbaum":
			var s: float = stelle["s"]
			var q: float = stelle["q"]
			var fuss := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			var schirm := LevelWerkzeuge.punkt_frei(level.verlauf, s, q + signf(q) * 5.0)
			_staemme.dazu(Vector2(fuss.x, fuss.z), 3.0)
			_kronen.dazu(Vector2(schirm.x, schirm.z), 4.5)
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
	_himmel_augen = PackedVector3Array()
	_himmel_blick = PackedVector3Array()
	_wurzel = null
	_staemme = null
	_kronen = null
	_hoehen_raster = PackedFloat32Array()
	_hoehen_mass = Vector2i.ZERO


## Vergisst alles, wenn das Level `level_id` geht (auch mitten im Bau).
static func _vergessen(level_id: int) -> void:
	if level_id != _level_id:
		return
	_aufraeumen()
	_bahn_p = PackedVector3Array()
	_bahn_r = PackedVector3Array()
	_bahn_s = PackedFloat32Array()
	_bahn_halb = PackedFloat32Array()
	_kegel.clear()
	_kegel_ohne_krone.clear()
	_kisten.clear()
	_fern_kandidaten.clear()
	_level_id = 0


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
## von der Kuppe über der Fallklamm zu seinem Stamm (±4°), vom Schluss
## zurück zu Kanzel und Wasserfall (±3°). `_kegel_ohne_krone` lässt die
## Kegel zur Kronenmitte weg: Plan 7 verlangt sie für die Rahmenbäume,
## nicht für die Riesen der Bachwiese – deren Kronen stehen vom Grat aus
## vor dem unteren Rand der Weltenbaumkrone, und das ist der
## Größenvergleich, den das Bild braucht.
static func _kegel_anlegen(level: Level01) -> void:
	_kegel.clear()
	_kegel_ohne_krone.clear()
	var wb: Dictionary = Level01.WELTENBAUM
	var achse: Vector2 = wb["achse"]
	var krone := Vector3(achse.x, float(wb["krone_mitte_y"]), achse.y)
	# Vor s 22 verdeckt der Hallenwald den Riesen ohnehin (Plan 7: erst ab
	# s 24 in der Öffnung).
	var s := 22.0
	while s <= 114.0:
		_kegel.append({"auge": _auge(level, s), "ziel": krone, "winkel": deg_to_rad(6.0)})
		s += 2.0
	# Der Stamm vom Grat aus (s 30–98): die Säule unter der Krone (y 30,
	# ±4° deckt y 20–40 bei 150 m; darunter steht ohnehin der Talwald vor
	# dem Knoll). Plan 7 schützte nur die Kronenmitte;
	# eine Sichtlinienprobe gegen die gezeichneten Netze fand vor dem Stamm
	# die Kronen der Rahmenbäume auf den Simsen (von s 31 bis 70 je eine,
	# 7 von 12 Linien bei s 46) und den Torbaum. Nicht für die Riesen von D
	# (wie die Kronenkegel): Der linke Torriese steht vom ganzen Grat aus auf
	# dieser Linie, 100–130 m weit im Dunst vor dem dunklen Stamm – der
	# Größenvergleich. Die letzten 14 m vor der Achse (der Stamm selbst und
	# seine Brettwurzeln) sind frei.
	var saeule := Vector3(achse.x, 30.0, achse.y)
	s = 30.0
	while s <= 98.0:
		# An der Enthüllung (s 30–38) etwas enger: Dort stehen die Rahmen-
		# bäume der hinteren Simse schon 70 m weit, klein vor dem Fuß der
		# Säule.
		_kegel.append({"auge": _auge(level, s), "ziel": saeule,
				"winkel": deg_to_rad(3.0 if s < 40.0 else 4.0),
				"ziel_frei": 14.0})
		s += 4.0
	# Der Stamm (y 15) über der Kuppe von C1 bis zur Fallkerbe und darüber
	# hinaus (Plan 7: bei s 124 bei x −0,03 im Bild); danach verschwindet er
	# über C4 hinter dem Walddach.
	var stamm := Vector3(achse.x, 15.0, achse.y)
	s = 100.0
	while s <= 126.0:
		var k := {"auge": _auge(level, s), "ziel": stamm, "winkel": deg_to_rad(4.0)}
		_kegel.append(k)
		_kegel_ohne_krone.append(k)
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
			var k := {"auge": _auge(level, s), "ziel": ziel, "winkel": deg_to_rad(3.0),
					"ziel_frei": 30.0}
			_kegel.append(k)
			_kegel_ohne_krone.append(k)
		s += 3.0


## Ort der Verfolgerkamera, wenn die Figur bei `s` in der Mitte steht (9,5 m
## zurück auf der Kurve, 6 m über der Figur).
static func _auge(level: Level01, s: float) -> Vector3:
	var auge := LevelWerkzeuge.punkt_frei(level.verlauf, s - 9.5, 0.0)
	# Die Korridorkamera hält 6 m über der Figur, gemessen an der Kurve dort,
	# wo sie selbst steht: bergauf (Wendel, 17 %) 1,6 m tiefer, bergab (C)
	# bis 2,9 m höher als die Figur + 6 m.
	var hier := LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
	auge.y = level.boden_bei(s) + 6.0 + (auge.y - hier.y)
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
		zugabe: float = 0.9, achse: PackedVector3Array = PackedVector3Array()) -> bool:
	var i0 := _naechste(fuss.x, fuss.z)
	if i0 >= 0:
		var q0 := absf(_quer(i0, fuss.x, fuss.z))
		var p0 := _bahn_p[i0]
		if absf(fuss.y - p0.y) < 3.0 and q0 - maxf(fussweite, r) < _bahn_halb[i0] + zugabe:
			return false
	# Die Achse als Punktfolge (geneigte Stämme biegen sich); ohne Angabe
	# gerade vom Fuß zur Spitze.
	var punkte := achse
	if punkte.is_empty():
		for k in 10:
			punkte.append(fuss.lerp(spitze, float(k) / 9.0))
	for p in punkte:
		# Am Fuß zählt der Umriss samt Wurzeln, darüber der Stamm.
		var rr := r if p.y - fuss.y > 1.2 else maxf(r, fussweite)
		for i in _proben_nahe(p.x, p.z, FREI_Q + rr + 1.0):
			var b := _bahn_p[i]
			if p.y > b.y + STAMM_FREI_H or p.y < b.y - 0.5:
				continue
			if absf(_quer(i, p.x, p.z)) - rr < FREI_Q:
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
## flachen Schirmkronen viel zu viel. `ohne_krone`: ohne die Kegel zur
## Kronenmitte des Weltenbaums.
static func _kegel_frei(huelle: AABB, ohne_krone: bool = false) -> bool:
	var alle := _kegel_ohne_krone if ohne_krone else _kegel
	var m := huelle.get_center()
	var h := huelle.size * 0.5
	# Vorab mit der Kugel um die ganze Hülle: Die meisten Kegel liegen weit
	# weg, nur die übrigen prüfen die 15 Punkte (das kostete sonst beim
	# Aufbau gut eine halbe Sekunde).
	var kegel: Array[Dictionary] = []
	var weit := h.length()
	for k in alle:
		if not Waldsetzer.kegel_frei_einzeln(m, weit, k):
			kegel.append(k)
	if kegel.is_empty():
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
		if not Waldsetzer.kegel_frei(p, r, kegel):
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
		# Die Ballen füllen die verlangte Höhe nur zu gut 70 %: Die Krone
		# wird größer bestellt und dann so gesetzt, dass ihr Scheitel auf
		# `hoehe` liegt – der Stamm endet in ihrer Mitte.
		var roh: ArrayMesh
		if bool(o.get("tanne", false)):
			# Nadelbaum: gestufte Kegel, genau so hoch wie verlangt.
			roh = _tannenkrone(kr, hoehe * (1.0 - float(o.get("unten", 0.2))),
					int(o.get("ballen", 6)), 11, int(o.get("karten", 22)), saat + 101)
		else:
			roh = Kronenwolke.netz({"radius": kr, "hoehe": kh * 1.35, "variante": variante,
					"ballen": int(o.get("ballen", 3)), "karten": int(o.get("karten", 22)),
					"saat": saat + 101})
		var rbox := roh.get_aabb()
		# "unten": Dort (Anteil der Höhe) soll die Krone beginnen – reicht sie
		# nicht so weit hinab, wird sie gestreckt (höchstens um 60 %). Tief
		# ansetzende Kronen verbergen den Stamm: Laub statt Lolli.
		var streck := 1.0
		if o.has("unten"):
			streck = clampf(hoehe * (1.0 - float(o["unten"])) / rbox.size.y, 1.0, 1.6)
		var mitte_y := hoehe - rbox.end.y * streck
		var krone := _verschoben(roh, Vector3(0.0, mitte_y, 0.0)
				+ _neigung_bei(o, (mitte_y + rbox.get_center().y * streck) / hoehe), streck)
		var stamm := Riesenstamm.schlicht({"hoehe": mitte_y
				+ (rbox.get_center().y + rbox.size.y * 0.1) * streck,
				"radius": radius, "radius_oben": radius * 0.5, "aeste": 3, "ast_start": 0.62,
				"ast_laenge": kr * 0.55, "neigung": o.get("neigung", Vector2.ZERO), "saat": saat})
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
		var roh := Kronenwolke.netz({"radius": kr, "hoehe": kh * 1.35, "variante": variante,
				"ballen": int(o.get("ballen", 4)), "karten": int(o.get("karten", 28)),
				"saat": saat + 101})
		var rbox := roh.get_aabb()
		# Scheitel gut einen Meter über der Stammspitze
		var mitte_y := hoehe + kh * 0.25 - rbox.end.y
		var krone := _verschoben(roh, Vector3(0.0, mitte_y, 0.0)
				+ _neigung_bei(o, (mitte_y + rbox.get_center().y) / hoehe))
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
	b["hoehe"] = hoehe
	b["neigung"] = o.get("neigung", Vector2.ZERO)
	b["variante"] = int(o.get("variante", 0))
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
	return b


## Versatz der Stammachse durch "neigung" in der relativen Höhe t (wie
## `Riesenstamm._achse`, ohne Schwung).
static func _neigung_bei(o: Dictionary, t: float) -> Vector3:
	var n: Vector2 = o.get("neigung", Vector2.ZERO)
	var v := n * pow(clampf(t, 0.0, 1.3), 1.5)
	return Vector3(v.x, 0.0, v.y)


## Eine Krone, um `versatz` verschoben und um `streck` in der Höhe gestreckt
## (Karten und Hülle mit), mit geteilten Scheiteln (siehe `_indiziert`).
static func _verschoben(netz: ArrayMesh, versatz: Vector3, streck: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var skala := Vector3(1.0, streck, 1.0)
	st.append_from(netz, 0, Transform3D(Basis.from_scale(skala), versatz))
	st.index()
	var neu := st.commit()
	var box := netz.custom_aabb if netz.custom_aabb.size != Vector3.ZERO else netz.get_aabb()
	neu.custom_aabb = AABB(box.position * skala + versatz, box.size * skala)
	return neu


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
					"variante": 1, "krone_radius": 5.2, "krone_hoehe": 5.0, "rippen": 8,
					"ballen": 3, "brettwurzeln": 4,
					"neigung": Vector2(2.4, 0.0), "pilze": 1, "saat": 1104}, true)
		"ast":
			return _baum("ast", {"krone_frei": true, "hoehe": 12.5, "radius": 0.55,
					"radius_oben": 0.3, "variante": 1, "krone_radius": 5.2, "krone_hoehe": 4.6,
					"neigung": Vector2(3.6, 0.0), "krumm": 0.4, "drehung": 0.9, "pilze": 1,
					"rippen": 10, "saat": 1107}, true)
		"ast_rund":
			return _baum("ast_rund", {"krone_frei": true, "hoehe": 13.5, "radius": 0.5,
					"radius_oben": 0.28, "variante": 0, "krone_radius": 4.6, "krone_hoehe": 6.4,
					"neigung": Vector2(3.0, 0.0), "krumm": 0.5, "drehung": 0.7, "rippen": 10,
					"efeu": 1, "saat": 1110}, true)
		"hoch":
			return _baum("hoch", {"krone_frei": true, "hoehe": 18.0, "radius": 0.45,
					"variante": 0, "krone_radius": 4.4, "krone_hoehe": 6.5, "rippen": 8,
					"ballen": 3, "brettwurzeln": 3,
					"saat": 1101}, true)
		"mittel":
			return _baum("mittel", {"krone_frei": true, "hoehe": 16.0, "radius": 0.62,
					"variante": 0, "krone_radius": 4.8, "krone_hoehe": 6.4, "rippen": 11,
					"efeu": 1, "saat": 1102}, true)
		"duenn":
			return _baum("duenn", {"krone_frei": true, "hoehe": 16.5, "radius": 0.32,
					"variante": 2, "krone_radius": 2.8, "krone_hoehe": 7.0, "rippen": 8,
					"ballen": 3, "brettwurzeln": 3,
					"saat": 1103}, true)
		"tief":
			# Tief beastet: Die Krone beginnt gut fünf Meter über dem Boden. In
			# der zweiten und dritten Reihe (nie über dem Weg) schließt sie die
			# Seiten in Augenhöhe der Kamera – das dunkle Seitenlaub der Halle.
			return _baum("tief", {"mittel": true, "hoehe": 14.0, "radius": 0.5,
					"variante": 0, "krone_radius": 4.6, "krone_hoehe": 8.6, "ballen": 3,
					"karten": 26, "saat": 1109}, true)
		"schlicht_a":
			return _baum("schlicht_a", {"mittel": true, "hoehe": 16.0, "radius": 0.45,
					"variante": 0, "krone_radius": 4.8, "krone_hoehe": 8.6, "ballen": 4,
					"saat": 1105}, true)
		"schlicht_b":
			return _baum("schlicht_b", {"mittel": true, "hoehe": 15.0, "radius": 0.42,
					"variante": 1, "krone_radius": 5.4, "krone_hoehe": 6.6, "saat": 1106}, true)
		"hang_rund", "hang_breit":
			# Hangwald (B/C links): Die Krone beginnt bei knapp einem Drittel
			# der Höhe ("unten"), breit und in vier Ballen gestuft, der Stamm
			# mit Aststummeln endet in ihr. Mit "tief"/"schlicht_a" und den
			# Hochstämmen las sich der Hang aus der Seitenansicht und vom Grat
			# als Lollis: lange, kahle Stämme, die Krone klein ganz oben (am
			# Hang liegt sie aus der Spielkamera über dem Bildrand).
			if art == "hang_rund":
				return _baum("hang_rund", {"mittel": true, "hoehe": 15.0, "radius": 0.5,
						"variante": 0, "krone_radius": 5.2, "krone_hoehe": 9.0, "ballen": 4,
						"unten": 0.3, "karten": 26, "saat": 1111}, true)
			return _baum("hang_breit", {"mittel": true, "hoehe": 13.5, "radius": 0.52,
					"variante": 1, "krone_radius": 6.0, "krone_hoehe": 7.2, "ballen": 4,
					"unten": 0.34, "karten": 26, "saat": 1112}, true)
		_:
			# Nadelbaum: gestufte Kegel bis tief hinab
			return _baum("schlicht_c", {"mittel": true, "tanne": true, "hoehe": 17.0,
					"radius": 0.4, "variante": 2, "krone_radius": 3.2, "ballen": 7,
					"unten": 0.18, "karten": 30, "saat": 1108}, true)


## Talbäume (M3, Rückfall), mittlere Fassung: 0 rund, 1 breit, 2 Nadelbaum,
## 3 groß und rund. Die Kronen setzen bei gut einem Drittel der Höhe an
## ("unten"); der Nadelbaum trägt gestufte Kegel fast bis zum Boden (aus
## vier Ballen auf 14 m war ein Schneemann geworden).
static func _talbaum(k: int) -> Dictionary:
	match k % 4:
		0:
			return _baum("tal0", {"mittel": true, "hoehe": 12.0, "radius": 0.34, "variante": 0,
					"krone_radius": 5.3, "krone_hoehe": 8.0, "ballen": 4, "unten": 0.36,
					"saat": 2101})
		1:
			return _baum("tal1", {"mittel": true, "hoehe": 11.0, "radius": 0.36, "variante": 1,
					"krone_radius": 6.0, "krone_hoehe": 7.8, "ballen": 4, "unten": 0.4,
					"saat": 2102})
		2:
			return _baum("tal2", {"mittel": true, "tanne": true, "hoehe": 14.0, "radius": 0.3,
					"variante": 2, "krone_radius": 3.0, "ballen": 6, "unten": 0.14, "karten": 26,
					"saat": 2103})
		_:
			return _baum("tal3", {"mittel": true, "hoehe": 15.0, "radius": 0.42, "variante": 0,
					"krone_radius": 6.0, "krone_hoehe": 11.0, "ballen": 4, "unten": 0.34,
					"saat": 2104})


## Ferne Bäume: grobe Krone ohne Karten (fünf Ballen, gut 0,3k
## Dreiecke), unten breiter und heller (`_fernform`), und ein angedeuteter
## Stamm im selben Stoff (vier Seiten, dunkel, ohne Wind). Die Krone reicht
## bis auf `FERN_BODEN` der Höhe hinab, der Stamm endet in ihrer Mitte: ein
## Wald aus Laub, keine Lollis. Fuß im Ursprung.
## Die Ballen sitzen eng (`FERN_LAGEN`): ein breiter Kranz unten, ein
## Wipfel darüber, aus der Achse gerückt, die Füllkugel der `Kronenwolke`
## dazwischen – keine Fuge, durch die Himmel scheint. Drei Ballen, auf die
## Höhe gestreckt, lagen auseinander: Vor dem Himmel hing dann der oberste
## allein als Ballon über dem Kamm. Drei Lagen lasen sich als geschnittener
## Buchs, ein zweiballiger Wipfel kostete ein Viertel mehr Dreiecke.
static func _fernbaum(k: int) -> ArrayMesh:
	var schluessel := "fern%d" % k
	if _netze.has(schluessel):
		return _netze[schluessel]
	var hoehe := 12.0 if k != 1 else 11.0
	var roh: ArrayMesh
	if k == 2:
		# Nadelbaum: gestufte Kegel (`_tannenkrone`) – aus vier Ballen auf
		# 14 m war ein Schneemann geworden.
		hoehe = 14.0
		roh = _fernform(_tannenkrone(2.9, hoehe * (1.0 - FERN_BODEN), 5, 7, 0, 3101 + k))
	else:
		# Lagen (Höhe über dem Fuß, Abstand von der Achse, Anzahl) – der
		# Radius der Ballen folgt aus `radius` (52–64 %, flach: 80 % hoch).
		var zentren := PackedVector3Array()
		var dreh := 0.7 * float(k)
		for lage: Vector3 in FERN_LAGEN[k]:
			var n := int(lage.z)
			for i in n:
				var w := dreh + TAU * float(i) / float(n)
				zentren.append(Vector3(cos(w) * lage.y, lage.x, -sin(w) * lage.y))
			dreh += PI / float(maxi(n, 1))
		roh = _fernform(Kronenwolke.fern({"radius": 5.0 if k == 0 else 5.2, "saat": 3101 + k,
				"zentren": zentren}))
	var rbox := roh.get_aabb()
	var streck := clampf(hoehe * (1.0 - FERN_BODEN) / rbox.size.y, 1.0, 2.2)
	var dy := hoehe - rbox.end.y * streck
	var krone := _verschoben(roh, Vector3(0.0, dy, 0.0), streck)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(krone, 0, Transform3D.IDENTITY)
	var r := 0.3 if k != 1 else 0.36
	var oben := dy + rbox.get_center().y * streck
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
	return netz


## Krone eines Nadelbaums: `stufen` gezackte Kegel übereinander, die sich
## überlappen (unten `radius`, oben ein Viertel davon), jeder mit einer
## flachen Unterseite, damit man von unten nicht hineinsieht. Im Format der
## `Kronenwolke` (COLOR: Verdeckung, Alpha Windgewicht; UV2.y: Höhe in der
## Krone; Blattkarten mit UV2.x ≥ 1), also im selben Stoff. Eine spitze
## Silhouette neben den runden – aus gestapelten Kugeln wurde ein Schneemann.
## Fuß der Krone im Ursprung, Spitze auf `hoehe`. `seiten`: Zacken je Kegel.
static func _tannenkrone(radius: float, hoehe: float, stufen: int, seiten: int, karten: int,
		saat: int) -> ArrayMesh:
	var rng := PropWerkzeug.zufall(saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var raender: Array[Dictionary] = []
	for i in stufen:
		var u := float(i) / float(stufen)
		var r := radius * lerpf(1.0, 0.26, u) * rng.randf_range(0.92, 1.08)
		var y_rand := hoehe * 0.8 * u + rng.randf_range(-0.04, 0.04) * hoehe / float(stufen)
		var y_spitze := hoehe if i == stufen - 1 else minf(y_rand + hoehe * 0.34, hoehe * 0.97)
		var spitze := Vector3(rng.randf_range(-0.05, 0.05) * r, y_spitze,
				rng.randf_range(-0.05, 0.05) * r)
		var unter := Vector3(0.0, y_rand + (y_spitze - y_rand) * 0.3, 0.0)
		var ao := lerpf(0.72, 1.0, u)
		var dreh := rng.randf() * TAU
		var rand := PackedVector3Array()
		for k in seiten:
			var w := dreh + TAU * (float(k) + rng.randf_range(-0.18, 0.18)) / float(seiten)
			# Zacken: abwechselnd Spitze und Kerbe, die Spitzen hängen durch.
			var zacke := (1.0 if k % 2 == 0 else 0.78) * rng.randf_range(0.9, 1.1)
			var y := y_rand - r * (0.16 if k % 2 == 0 else 0.06) * rng.randf_range(0.7, 1.3)
			rand.append(Vector3(cos(w) * r * zacke, y, -sin(w) * r * zacke))
		for k in seiten:
			var a := rand[k]
			var b := rand[(k + 1) % seiten]
			var na := _tannen_normale(a, spitze)
			var nb := _tannen_normale(b, spitze)
			var aussen := Vector3(a.x + b.x, 0.0, a.z + b.z).normalized()
			# Oberseite
			_tannen_dreieck(st, [spitze, a, b], [Vector3.UP, na, nb], aussen + Vector3.UP * 0.3,
					[ao * 0.9, ao, ao], hoehe)
			# Unterseite (dunkel, nach unten)
			var nu := (aussen * 0.4 + Vector3.DOWN).normalized()
			_tannen_dreieck(st, [unter, b, a], [nu, nu, nu], nu, [ao * 0.6, ao * 0.7, ao * 0.7],
					hoehe)
			raender.append({"ort": a, "normale": na, "ao": ao})
	# Blattkarten an den Rändern der Kegel: Sie fransen die Zacken aus.
	var max_karte := 0.0
	for n in karten:
		if raender.is_empty():
			break
		var e: Dictionary = raender[rng.randi_range(0, raender.size() - 1)]
		var ort: Vector3 = e["ort"]
		var groesse := clampf(radius * 0.3, 0.45, 1.1) * rng.randf_range(0.8, 1.2)
		max_karte = maxf(max_karte, groesse)
		var ao: float = e["ao"]
		var f := Color(ao * 1.05, ao * 1.05, ao * 1.03, clampf(0.45 + 0.55 * ort.y / hoehe, 0.0, 1.0))
		var nrm: Vector3 = e["normale"]
		var art := 1.0 + clampf(ort.y / hoehe, 0.0, 0.99)
		ort += nrm * groesse * 0.15
		for c: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0),
				Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
			st.set_color(f)
			st.set_uv(c)
			st.set_uv2(Vector2(art, groesse))
			st.set_normal((nrm + Vector3.UP * 0.6).normalized())
			st.add_vertex(ort)
	var netz := st.commit()
	netz.custom_aabb = netz.get_aabb().grow(max_karte * 0.75 + 0.1)
	return netz


## Normale am Rand eines Kegels: nach außen und oben (die Neigung der
## Kegelfläche), halb zur Mitte der Krone gebogen wie bei `Kronenwolke`.
static func _tannen_normale(rand: Vector3, spitze: Vector3) -> Vector3:
	var aussen := Vector3(rand.x, 0.0, rand.z).normalized()
	var steil := (spitze - rand).normalized()
	var n := (aussen - steil * aussen.dot(steil)).normalized()
	return (n + Vector3.UP * 0.35).normalized()


## Ein Dreieck der Tannenkrone, Vorderseite nach `aussen` (Godot: von außen
## gesehen im Uhrzeigersinn), mit Farbe (Verdeckung je Ecke) und UV2 (Höhe).
static func _tannen_dreieck(st: SurfaceTool, p: Array, n: Array, aussen: Vector3, ao: Array,
		hoehe: float) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	var reihe: Array[int] = [0, 1, 2]
	if (b - a).cross(c - a).dot(aussen) > 0.0:
		reihe = [0, 2, 1]
	for j in reihe:
		var q: Vector3 = p[j]
		var t := clampf(q.y / hoehe, 0.0, 1.0)
		var v: float = ao[j]
		st.set_color(Color(v, v, v, 0.25 + 0.75 * t))
		st.set_uv(Vector2.ZERO)
		st.set_uv2(Vector2(0.0, t))
		st.set_normal(n[j] as Vector3)
		st.add_vertex(q)


## Form einer fernen Krone: unten breiter (ein Hügel aus Laub, der auf dem
## Boden aufsitzt, statt einer Linse mit flacher Unterseite) und unten
## heller – der Kronenstoff dunkelt nach der Höhe in der Krone (UV2.y) ab,
## aus 60 m und mehr war die Unterseite eine schwarze Scheibe vor dem
## besonnten Hang. Hier beginnt der Verlauf bei `FERN_UNTEN`.
static func _fernform(netz: ArrayMesh) -> ArrayMesh:
	var arrays := netz.surface_get_arrays(0)
	var ecken: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var box := netz.get_aabb()
	var mitte := box.get_center()
	for i in ecken.size():
		var t := uv2[i].y
		var p := ecken[i]
		var weit := 1.0 + FERN_FUSS * (1.0 - smoothstep(0.0, 0.6, t))
		ecken[i] = Vector3(mitte.x + (p.x - mitte.x) * weit, p.y, mitte.z + (p.z - mitte.z) * weit)
		uv2[i] = Vector2(uv2[i].x, lerpf(FERN_UNTEN, 1.0, t))
	arrays[Mesh.ARRAY_VERTEX] = ecken
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	var neu := ArrayMesh.new()
	neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return neu


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
		_grund = "k1"
		return false
	if bool(optionen.get("talkante", false)) and not _talkante_frei(huelle):
		_zaehle("nein_kante")
		_grund = "kante"
		return false
	var krone_r := maxf(huelle.size.x, huelle.size.z) * 0.5
	var ohne_krone := bool(optionen.get("ohne_krone", false))
	if not _kegel_frei(huelle, ohne_krone):
		_zaehle("nein_kegel")
		_grund = "kegel"
		if _level_debug and not ohne_krone:
			_grund = "kegel zur Krone" if _kegel_frei(huelle, true) else "kegel zu Stamm/Fall"
		return false
	var fuss := lage.origin
	var stamm: ArrayMesh = b["stamm"]
	var s_box := stamm.get_aabb()
	var spitze := lage * Vector3(0.0, s_box.end.y * 0.9, 0.0)
	# Stammradius in Brusthöhe (aus dem Netz, mal Maßstab)
	var r := float(b.get("radius", 0.5)) * maxf(lage.basis.x.length(), lage.basis.z.length())
	# Ohne Angabe: der weiteste Wurzelradius (Brettwurzeln ragen am Fuß
	# weit über den Stamm hinaus).
	var fuss_r := r
	var fr: PackedFloat32Array = b.get("fuss_radien", PackedFloat32Array())
	for f in fr:
		fuss_r = maxf(fuss_r, f * maxf(lage.basis.x.length(), lage.basis.z.length()))
	var fussweite := float(optionen.get("fussweite", fuss_r))
	# Die Achse samt Neigung (die steckt im Netz, nicht in der Lage).
	var achse := PackedVector3Array()
	var h: float = b.get("hoehe", s_box.end.y)
	for k in 12:
		var t := float(k) / 11.0
		achse.append(lage * (Vector3(0.0, t * h * 0.95, 0.0) + _neigung_bei(b, t * 0.95)))
	spitze = achse[achse.size() - 1]
	if not bool(optionen.get("ohne_stammtest", false)) \
			and not _stamm_frei(fuss, spitze, r, fussweite, float(optionen.get("zugabe", 0.9)),
			achse):
		_zaehle("nein_stamm")
		_grund = "stamm"
		return false
	if not Waldsetzer.kegel_frei(fuss.lerp(spitze, 0.75), r * 2.0,
			_kegel_ohne_krone if ohne_krone else _kegel):
		_zaehle("nein_kegel_stamm")
		_grund = "kegel_stamm"
		return false
	# "zeichnen": gezeichnet wird so, geprüft wurde `lage` – nur für Lagen,
	# die ganz in der geprüften Hülle bleiben (kleiner oder gleich).
	var bild: Transform3D = optionen.get("zeichnen", lage)
	if not stamm_art.is_empty():
		ws.setze(stamm_art, stamm, bild, stamm_ton)
		# Den Schatten wirft der schlichte Stamm gleicher Form.
		if ws.hat_art(stamm_art + "_schatten") and b.get("schatten") != null:
			ws.setze(stamm_art + "_schatten", b["schatten"] as ArrayMesh, bild)
	if not krone_art.is_empty():
		ws.setze(krone_art, b["krone"] as ArrayMesh, bild, krone_ton)
	# Fernfassung (grobe Krone mit Stamm), sichtbar, wo die Zelle der vollen
	# endet: gleiche Höhe, gleiche Drehung.
	var fern_art: String = optionen.get("fern", "")
	if not fern_art.is_empty():
		var v: int = b.get("variante", 0)
		var k := 2 if v == 2 else (1 if v == 1 else 0)
		var netz := _fernbaum(k)
		var hoch := float(b.get("hoehe", 12.0)) * bild.basis.y.length()
		var f := hoch / netz.get_aabb().end.y
		var breit := bild.basis.x.length() / maxf(bild.basis.y.length(), 0.001)
		var fern_lage := Transform3D(bild.basis.orthonormalized().scaled_local(
				Vector3(f * breit, f, f * breit)), fuss)
		ws.setze(fern_art, netz, fern_lage, krone_ton)
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
	# Stämme und Kronen in Streifen quer zum Weg (er läuft hier nach
	# Norden), links und rechts getrennt: Was hinter der Kamera liegt, fällt
	# als Ganzes aus dem Sichtkegel. Die Kronen in schmalen Streifen (12 m) –
	# bei 22 m zeichnete die Kamera am Start (s 4) noch die Kronen über und
	# hinter sich –, die Stämme in breiten (22 m): Jede Zelle mit Schatten
	# kostet je Schattenstufe einen Aufruf mehr.
	var ws := Waldsetzer.new(_wurzel, "Hallenwald", 0.0)
	var streifen := Vector2(1000.0, 22.0)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_HALLE, "verschmelzen": true,
			"zelle": streifen})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_HALLE,
			"verschmelzen": true, "zelle": streifen})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_HALLE), "sicht": SICHT_HALLE,
			"verschmelzen": true, "karten": true, "zelle": Vector2(1000.0, 12.0)})
	ws.art("kranz", {"stoff": Findling.kranzstoff(), "sicht": SICHT_KRANZ,
			"verschmelzen": true})
	ws.art("farn", {"stoff": Farnwerk.stoff(FARN), "sicht": SICHT_FARN})
	var farne: Array[ArrayMesh] = [Farnwerk.klein(41), Farnwerk.klein(42), Farnwerk.gross(43)]
	var rng := PropWerkzeug.zufall(4101)

	# Heldenstämme zuerst: Sie haben ihren Platz.
	for k in HELDEN.size():
		var stelle: Vector2 = HELDEN[k]
		var b := _baum("held%d" % k, {"krone_frei": true, "hoehe": 20.0 + float(k),
				"radius": 0.9 + 0.08 * float(k), "variante": 1, "krone_radius": 5.6,
				"krone_hoehe": 5.4, "ballen": 5, "karten": 36, "rippen": 12,
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
			var arten: Array = e["rechts"] if seite > 0.0 and e.has("rechts") else e["arten"]
			if arten.is_empty():
				continue
			var s := HALLE_VON + rng.randf_range(0.0, ab.x)
			var bis := HALLE_LINKS_BIS if seite < 0.0 else 30.0
			while s < bis:
				var s_platz := s
				s += rng.randf_range(ab.x, ab.y)
				# Je Platz bis zu vier Würfe (versetzt um ±2,4 m längs), bis
				# einer frei ist.
				var ss := s_platz
				var q := 0.0
				var fuss := Vector3.ZERO
				var abstand := 3.8
				var frei := false
				for wurf in 4:
					ss = s_platz + rng.randf_range(-2.4, 2.4)
					q = seite * rng.randf_range(qb.x, qb.y)
					if not _halle_platz(level, ss, q):
						continue
					fuss = _boden(level, ss, q)
					if _staemme.frei(Vector2(fuss.x, fuss.z), abstand * 0.5):
						frei = true
						break
				if not frei:
					_zaehle("halle_ohne_platz")
					continue
				var art: String = arten[rng.randi_range(0, arten.size() - 1)]
				# Links in der ersten Reihe oft ein Astbaum: Seine Krone hängt
				# ab 9,5 m über dem linken Wegdrittel – das Laub oben links im
				# Bild (bis in den Hangweg hinein).
				if reihe == 0 and seite < 0.0 and ss > 6.0 and rng.randf() < 0.55:
					art = "ast_rund" if rng.randf() < 0.5 else "ast"
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
					if versuch_art == "dach" or versuch_art.begins_with("ast"):
						dreh = atan2(-richtung.z, richtung.x) + rng.randf_range(-0.35, 0.35)
					var quer := rng.randf_range(0.8, 1.25)
					var hoch := rng.randf_range(0.9, 1.12)
					var schief := 0.0
					var kipp := Vector3.RIGHT
					if rng.randf() < 0.13 and versuch_art != "dach" and not versuch_art.begins_with("ast"):
						schief = deg_to_rad(rng.randf_range(5.0, 8.0))
						var w := rng.randf() * TAU
						kipp = Vector3(cos(w), 0.0, sin(w))
					var lage := _lage(fuss, dreh, quer, hoch, schief, kipp)
					var mit_kranz := reihe < 1
					var ton_stamm := _ton(rng, Vector2(0.78, 0.98), 0.03)
					var ton_krone := _ton(rng, Vector2(0.78, 0.98))
					if rng.randf() < 0.18:
						ton_krone = ton_krone * NADEL_TON
					if _pflanze(ws, b, lage, "stamm", "krone", ton_stamm, ton_krone,
							{"kranz": "kranz" if mit_kranz else "", "drehung": dreh}):
						_staemme.dazu(Vector2(fuss.x, fuss.z), abstand * 0.5)
						_zaehle("halle")
						if reihe < 1 and rng.randf() < 0.7:
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

	_unterholz(level, ws, rng)

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


## Unterholz zwischen den Reihen: Sträucher und junge Bäume, im Stoff der
## Kronen (kein eigener Zeichenaufruf). Sie schließen die Lücken zwischen
## den Stämmen in Augenhöhe – der Hallenwald bekommt eine Tiefe, statt als
## Säulenreihe auf Rasen zu stehen.
static func _unterholz(level: Level01, ws: Waldsetzer, rng: RandomNumberGenerator) -> void:
	var busch := _indiziert(Kronenwolke.netz({"radius": 1.5, "variante": 1, "karten": 18,
			"ballen": 3, "saat": 4301}))
	var jung := _baum("jungbaum", {"mittel": true, "hoehe": 6.5, "radius": 0.14, "variante": 0,
			"krone_radius": 2.2, "krone_hoehe": 3.6, "ballen": 3, "karten": 16, "saat": 4302})
	for seite: float in [-1.0, 1.0]:
		var s := HALLE_VON + rng.randf_range(0.0, 3.0)
		var bis := HALLE_LINKS_BIS - 4.0 if seite < 0.0 else 24.0
		while s < bis:
			var ss := s
			s += rng.randf_range(3.6, 5.8)
			var q := seite * rng.randf_range(8.8, 19.0)
			if not _halle_platz(level, ss, q):
				continue
			var fuss := _boden(level, ss, q)
			if not _staemme.frei(Vector2(fuss.x, fuss.z), 1.4):
				continue
			if rng.randf() < 0.3:
				var lage := _lage(fuss, rng.randf() * TAU, rng.randf_range(0.8, 1.2),
						rng.randf_range(0.8, 1.25))
				if _pflanze(ws, jung, lage, "stamm", "krone", Color(0.9, 0.9, 0.88),
						_ton(rng, Vector2(0.8, 1.0))):
					_staemme.dazu(Vector2(fuss.x, fuss.z), 1.2)
					_zaehle("jungbaeume")
			else:
				var gross := rng.randf_range(0.7, 1.4)
				var lage := _lage(fuss + Vector3.UP * 0.35 * gross, rng.randf() * TAU,
						gross * rng.randf_range(0.9, 1.2), gross)
				ws.setze("krone", busch, lage, _ton(rng, Vector2(0.72, 0.95)))
				_staemme.dazu(Vector2(fuss.x, fuss.z), 1.0)
				_zaehle("unterholz")
	# Die Ecke vor der Enthüllung (rechts, s 17–25): Die Startkamera
	# (herangeholt, steil) sieht oben rechts unter den Kronen hindurch über
	# die Hallenkante ins Tal – ein heller Nebelfleck, bevor die Enthüllung
	# ihn zeigen soll. Nadelbäume, deren Kronen bis fast zum Boden reichen,
	# und große Büsche schließen sie; bei s 26 öffnet sich das Bild.
	var tanne := _hallenbaum("schlicht_c")
	for versuch in 24:
		var ss := rng.randf_range(17.0, 25.0)
		var q := rng.randf_range(10.5, 20.0)
		if not _halle_platz(level, ss, q):
			continue
		var fuss := _boden(level, ss, q)
		if not _staemme.frei(Vector2(fuss.x, fuss.z), 0.7):
			continue
		if rng.randf() < 0.6:
			var gross := rng.randf_range(0.62, 0.9)
			if _pflanze(ws, tanne, _lage(fuss, rng.randf() * TAU, gross, gross), "stamm", "krone",
					Color(0.85, 0.85, 0.82), _ton(rng, Vector2(0.72, 0.9)) * NADEL_TON):
				_staemme.dazu(Vector2(fuss.x, fuss.z), 1.6)
				_zaehle("eckbaeume")
				continue
		var gross := rng.randf_range(1.3, 1.9)
		var lage := _lage(fuss + Vector3.UP * 0.35 * gross, rng.randf() * TAU,
				gross * rng.randf_range(0.9, 1.2), gross)
		ws.setze("krone", busch, lage, _ton(rng, Vector2(0.66, 0.88)))
		_staemme.dazu(Vector2(fuss.x, fuss.z), 1.3)
		_zaehle("eckbuesche")
	# Rechts zur Hallenkante hin dichter Unterwuchs zwischen den Stämmen.
	var s2 := -12.0 + rng.randf_range(0.0, 2.0)
	while s2 < 24.0:
		var ss := s2
		s2 += rng.randf_range(2.2, 3.4)
		var q := rng.randf_range(16.0, 24.5)
		if not _halle_platz(level, ss, q):
			continue
		var fuss := _boden(level, ss, q)
		if not _staemme.frei(Vector2(fuss.x, fuss.z), 1.0):
			continue
		if rng.randf() < 0.4:
			var lage := _lage(fuss, rng.randf() * TAU, rng.randf_range(0.9, 1.3),
					rng.randf_range(0.9, 1.35))
			if _pflanze(ws, jung, lage, "stamm", "krone", Color(0.9, 0.9, 0.88),
					_ton(rng, Vector2(0.75, 0.95))):
				_staemme.dazu(Vector2(fuss.x, fuss.z), 1.2)
				_zaehle("jungbaeume")
		else:
			var gross := rng.randf_range(1.1, 1.8)
			var lage := _lage(fuss + Vector3.UP * 0.35 * gross, rng.randf() * TAU,
					gross * rng.randf_range(0.9, 1.2), gross)
			ws.setze("krone", busch, lage, _ton(rng, Vector2(0.68, 0.9)))
			_staemme.dazu(Vector2(fuss.x, fuss.z), 1.2)
			_zaehle("unterholz")


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
	ws.art("fern", {"stoff": Kronenwolke.stoff(LAUB_HALLE, false), "sicht_von": SICHT_HANG,
			"sicht": SICHT_FERN, "verschmelzen": true, "rand": 8.0})
	var unterholz := _indiziert(Kronenwolke.netz({"radius": 1.7, "hoehe": 2.4, "variante": 1,
			"karten": 18, "ballen": 3, "saat": 5301}))
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
			# Nie im Kameraraum (|q| < 6), auch wo die Kronenkante der Wand
			# dicht am Weg liegt (Fallklamm).
			var q := -maxf(kante.x + u, FREI_Q + 0.8)
			var tiefe := u
			u += rng.randf_range(5.0, 7.5)
			var fuss := _boden(level, ss, q)
			var w := L01Gelaende.wald(fuss.x, fuss.z)
			# Die erste Reihe an der Kante rahmt das Bild, egal was der Boden
			# sagt (der Rasen der Krone läuft dort erst in Waldboden über);
			# ab und zu eine Lücke. Weiter hinten entscheidet die Walddichte.
			var schwelle := rng.randf_range(0.35, 0.75)
			if tiefe < 4.0:
				schwelle = -1.0 if rng.randf() < 0.8 else 2.0
			elif tiefe < 9.0:
				schwelle = rng.randf_range(0.1, 0.45)
			if w < schwelle:
				continue
			# Nur oben auf der Krone, nicht in der Wand
			if fuss.y < kante.y - 1.2:
				continue
			if not _staemme.frei(Vector2(fuss.x, fuss.z), 2.4):
				continue
			# Vorn eher tiefe Kronen: Vom Weg aus sieht man den Hang von unten,
			# hohe Bäume zeigten dort nur Stämme auf Rasen, ihr Laub läge über
			# dem Bildrand.
			# Keine dünnen Hochstämme vorn: Aus der Seitenansicht und vom Grat
			# aus lasen sie sich als Lollis (lange, kahle, parallele Stämme mit
			# kleiner Krone ganz oben). Dafür Nadelbäume, gut ein Viertel.
			# Hinten tief ansetzende, breite Kronen (`hang_rund`/`hang_breit`):
			# Laub bis gut 4 m über dem Boden statt Stämmen mit einem Kopf.
			var vorn := tiefe < 10.0
			var art := "dach"
			if not vorn or rng.randf() >= 0.3:
				var auswahl: Array = ["tief", "hang_rund", "schlicht_c", "tief", "hang_breit",
						"schlicht_c"] if vorn else ["hang_rund", "hang_breit", "hang_rund",
						"schlicht_c", "hang_breit", "tief"]
				art = String(auswahl[rng.randi_range(0, auswahl.size() - 1)])
			# Ganz vorn an der Kante (bis s 110) oft ein Astbaum: niedrig und
			# breit, zum Weg geneigt – seine Äste hängen über dem linken
			# Wegdrittel (ab 9,5 m) und rahmen das Bild oben links.
			var versuche: Array[String] = [art]
			if art.begins_with("hang"):
				# Passt die breite Krone nicht (Kamerahülle, Nachbarn), der
				# schmalere tief beastete Baum.
				versuche.append("tief")
			if tiefe < 3.2 and ss < 110.0 and rng.randf() < 0.7:
				versuche = ["ast" if rng.randf() < 0.5 else "ast_rund", "dach"]
			for versuch_art in versuche:
				var b := _hallenbaum(versuch_art)
				var zum_weg := _rechts_bei(level, ss)
				var dreh := rng.randf() * TAU
				if versuch_art == "dach" or versuch_art.begins_with("ast"):
					dreh = atan2(-zum_weg.z, zum_weg.x) + rng.randf_range(-0.4, 0.4)
				var hoch := rng.randf_range(0.9, 1.15)
				# Leicht schief (bis 5°), nie parallel wie Zaunpfähle.
				var kipp := Vector3(rng.randf() - 0.5, 0.0, rng.randf() - 0.5)
				var lage := _lage(fuss, dreh, rng.randf_range(0.85, 1.25), hoch,
						deg_to_rad(rng.randf_range(0.0, 5.0)) if kipp.length() > 0.05 else 0.0,
						kipp if kipp.length() > 0.05 else Vector3.RIGHT)
				var ton_krone := _ton(rng, Vector2(0.8, 1.0))
				if rng.randf() < 0.2 and not versuch_art.begins_with("ast"):
					ton_krone = ton_krone * NADEL_TON
				if _pflanze(ws, b, lage, "stamm", "krone", _ton(rng, Vector2(0.78, 0.96), 0.03),
						ton_krone, {"fern": "fern"}):
					_staemme.dazu(Vector2(fuss.x, fuss.z), 2.4)
					_zaehle("hang")
					if versuch_art.begins_with("ast"):
						_zaehle("hang_ast")
					# Unterholz zwischen den Stämmen: Vom Weg aus sieht man den
					# Hang von unten, dort sonst nur Stämme auf Rasen.
					if rng.randf() < 0.6:
						var w2 := rng.randf() * TAU
						var ort := fuss + Vector3(cos(w2), 0.0, sin(w2)) * rng.randf_range(2.2, 3.4)
						ort.y = L01Gelaende.hoehe(ort.x, ort.z)
						_randbusch(ws, unterholz, ort, rng)
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
	# Nah (bis `RAHMEN_NAH`) die volle Fassung, dahinter die schlichte der
	# Riesen: Vom Start (s 4) aus stehen sie knapp 80 m weit im Dunst.
	var ws := Waldsetzer.new(_wurzel, "Rahmenbaeume", 0.0)
	var laub := Kronenwolke.stoff(Color(0.18, 0.38, 0.15))
	ws.art("stamm", {"stoff": _borke(), "sicht": RAHMEN_NAH, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_RAHMEN,
			"verschmelzen": true})
	ws.art("krone", {"stoff": laub, "sicht": RAHMEN_NAH, "verschmelzen": true, "karten": true})
	ws.art("stamm_fern", {"stoff": _borke(), "sicht_von": RAHMEN_NAH, "sicht": SICHT_RAHMEN,
			"verschmelzen": true})
	ws.art("krone_fern", {"stoff": laub, "sicht_von": RAHMEN_NAH, "sicht": SICHT_RAHMEN,
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
		var hoehe: float = stelle["hoehe"]
		# Die weiteren Fassungen neigen sich weit über das Tal und bleiben
		# niedriger: Vom Grat aus stehen die Simse (s 50–98) nahe der Linie
		# zum Stamm des Weltenbaums, die aufrechte Krone stand davor. Gebaut
		# wird eine Fassung erst, wenn ein Versuch sie braucht (Ladezeit).
		var fassung := func(weit: int) -> Dictionary:
			return _baum("rahmen%d_%d" % [nummer, weit], {
					"hoehe": hoehe * [1.0, 0.72, 0.56][weit], "radius": 0.48,
					"radius_oben": 0.24, "variante": 0, "krone_radius": [3.3, 3.3, 3.0][weit],
					"ast_start": 0.5, "aeste": 5, "drehung": 1.5, "krumm": 0.6,
					"neigung": Vector2([3.2, 5.5, 5.0][weit], 0.0),
					"karten": 50, "pilze": 1, "efeu": 1, "brettwurzeln": 5, "rippen": 12,
					"wurzel_reichweite": 1.4, "wurzel_hoehe": 1.6, "saat": 6201 + nummer * 7})
		# Versuche: erst wie geplant, dann weiter hinaus gedreht und kleiner,
		# dann die weit geneigte Fassung. Lokal +X (die Neigung) zeigt über
		# das Tal, leicht in Laufrichtung.
		var grund := atan2(-aussen.z, aussen.x)
		for versuch in 24:
			var b: Dictionary = fassung.call(versuch >> 3)
			var v := versuch % 8
			var f := 1.0 - 0.06 * floorf(float(v) * 0.5)
			var w := grund + (0.35 if v % 2 == 0 else -0.35) * (1.0 - float(v) / 8.0)
			# ab dem dritten Versuch auch weiter hinaus (die Nadel ist breit)
			var ort := fuss + aussen * 0.4 * floorf(float(v) * 0.5)
			var lage := _lage(ort, w, f, f)
			var ton := _ton(rng, Vector2(0.82, 0.96))
			if _pflanze(ws, b, lage, "stamm", "krone", Color(0.9, 0.88, 0.86), ton,
					{"ohne_stammtest": true}):
				var fern := _riese_fern("rahmen%d_%d" % [nummer, versuch >> 3], b)
				ws.setze("stamm_fern", fern["stamm"] as ArrayMesh, lage, Color(0.9, 0.88, 0.86))
				ws.setze("krone_fern", fern["krone"] as ArrayMesh, lage, ton)
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
	# Nah (bis `RIESE_NAH`) die volle Fassung, dahinter eine schlichte mit
	# gleichem Umriss: Vom Grat aus stehen die Riesen 100–160 m weit im
	# Dunst, dort zählten sonst 5k Dreiecke je Baum.
	var ws := Waldsetzer.new(_wurzel, "Riesen", 70.0)
	var laub := Kronenwolke.stoff(Color(0.2, 0.42, 0.15))
	ws.art("stamm", {"stoff": _borke(), "sicht": RIESE_NAH, "verschmelzen": true})
	ws.art("stamm_schatten", {"stoff": _borke(), "schatten": "nur", "sicht": SICHT_RIESEN,
			"verschmelzen": true})
	ws.art("krone", {"stoff": laub, "sicht": RIESE_NAH, "verschmelzen": true, "karten": true})
	ws.art("kranz", {"stoff": Findling.kranzstoff(), "sicht": SICHT_KRANZ + 20.0,
			"verschmelzen": true})
	# Die schlichte Fassung sieht man nur vom Grat aus, 100–160 m weit vor
	# dem Fuß des Weltenbaums (siehe `RIESE_FERN_STAMM`).
	var borke_fern: Material = _borke()
	var laub_fern: Material = laub
	if RIESE_FERN_NEBELARM:
		borke_fern = L01Weltenbaum.nebelarm(borke_fern, level)
		laub_fern = L01Weltenbaum.nebelarm(laub_fern, level)
	ws.art("stamm_fern", {"stoff": borke_fern,
			"sicht_von": RIESE_NAH, "sicht": SICHT_RIESEN, "verschmelzen": true})
	ws.art("krone_fern", {"stoff": laub_fern, "sicht_von": RIESE_NAH,
			"sicht": SICHT_RIESEN, "verschmelzen": true, "karten": true})
	var rng := PropWerkzeug.zufall(7101)
	var liste: Array[Dictionary] = []
	# Die Torriesen stehen am Riesentor dicht an der Wiese (q ±9): kurze
	# Wurzeln, und deren Spitzen – sie tauchen flach in den Boden – dürfen
	# bis 0,3 m an die Wegkante (die Leitlinie steht bei 6,8).
	for t: Dictionary in Level01.TORRIESEN:
		liste.append({"s": t["s"], "q": t["q"], "hoehe": t["hoehe"], "radius": t["radius"],
				"reichweite": 1.2, "neigung": 0.0, "zugabe": 0.3, "riese": true})
	for t: Dictionary in Level01.TALRIESEN:
		liste.append({"s": t["s"], "q": t["q"], "hoehe": t["hoehe"], "radius": t["radius"],
				"reichweite": 2.4, "neigung": 0.0, "zugabe": 0.9, "riese": true})
	for k: Vector4 in KANALBAEUME:
		liste.append({"s": k.x, "q": k.y, "hoehe": k.z, "radius": 0.95, "reichweite": 2.0,
				"neigung": k.w, "zugabe": 0.9, "riese": false})
	for i in liste.size():
		var e: Dictionary = liste[i]
		var s: float = e["s"]
		var q: float = e["q"]
		var hoehe: float = e["hoehe"]
		var r: float = e["radius"]
		var geneigt: float = e["neigung"]
		var riese: bool = e["riese"]
		# Die Riesen behalten Höhe und Stamm (Plan M5: 32–38 m, Ø 3–4 m); die
		# Kegel zur Kronenmitte des Weltenbaums gelten für sie nicht, auch
		# nicht für die Kanalbäume, die mit ihnen das Dach über C4 und der
		# Wiese bilden (siehe `_kegel_anlegen`). Hält einer trotzdem eine
		# Regel nicht (der Kegel zum Stamm, das Schlussbild), wird nur seine
		# Krone schmaler; die Kanalbäume dürfen dazu ein Stück längs rücken.
		var versuche: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(0.85, 0.0), Vector2(0.72, 0.0)]
		if not riese:
			versuche.append_array([Vector2(1.0, -3.0), Vector2(1.0, 3.0), Vector2(0.8, -3.0),
					Vector2(0.8, 3.0), Vector2(0.7, -5.0)])
		var gesetzt := false
		for v in versuche:
			var b := _baum("riese%d_%d" % [i, roundi(v.x * 100.0)], {"hoehe": hoehe, "radius": r,
					"radius_oben": r * 0.5, "variante": 1, "krone_radius": hoehe * 0.25 * v.x,
					"ast_start": 0.68 if geneigt > 0.0 else 0.56, "aeste": 6,
					"ast_steil": 0.55, "brettwurzeln": 7, "wurzel_reichweite": float(e["reichweite"]),
					"wurzel_hoehe": r * 2.6, "wurzel_dicke": r * 0.26, "pilze": 2, "efeu": 1,
					"rippen": 16, "karten": 90, "neigung": Vector2(geneigt, 0.0),
					"saat": 7201 + i * 13}, true)
			var fuss := _boden(level, s + v.y, q)
			var zum_weg := -signf(q) * _rechts_bei(level, s + v.y)
			var dreh: Dictionary = Waldsetzer.drehung_weg(b["fuss_radien"], zum_weg)
			var w := float(dreh["drehung"])
			if geneigt > 0.0:
				# Die Neigung (lokal +X) zeigt zum Weg: Das Dach über C4.
				w = atan2(-zum_weg.z, zum_weg.x)
			var lage := _lage(fuss, w, 1.0, 1.0)
			var ton := _ton(rng, Vector2(0.84, 0.96))
			if _pflanze(ws, b, lage, "stamm", "krone", Color(0.94, 0.93, 0.92), ton,
					{"kranz": "kranz", "drehung": w,
					"fussweite": float(dreh["weite"]), "zugabe": float(e["zugabe"]),
					"ohne_stammtest": geneigt > 0.0, "ohne_krone": true}):
				var fern := _riese_fern("riese%d_%d" % [i, roundi(v.x * 100.0)], b)
				# Die schlichte Fassung sieht man nur vom Grat (100–160 m), etwas
				# dunkler und kühler getönt (`RIESE_FERN_STAMM`).
				ws.setze("stamm_fern", fern["stamm"] as ArrayMesh, lage, RIESE_FERN_STAMM)
				ws.setze("krone_fern", fern["krone"] as ArrayMesh, lage, ton * RIESE_FERN_KRONE)
				_staemme.dazu(Vector2(fuss.x, fuss.z), r + 2.5)
				_zaehle("riesen")
				if v != Vector2(1.0, 0.0):
					_zaehle("riesen_angepasst")
				if _level_debug:
					print("Wald: Riese s %.1f q %.1f: Krone ×%.2f, längs %+.1f m, Höhe %.1f m" % [
							s, q, v.x, v.y, float(b["krone_oben"])])
				gesetzt = true
				break
			if _level_debug:
				print("Wald: Riese s %.1f q %.1f, Krone ×%.2f, längs %+.1f: nein (%s)" % [
						s, q, v.x, v.y, _grund])
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


## Schlichte Fassung eines Riesen (oder Rahmenbaums): der Schattenstamm
## (acht Seiten, gleiche Achse) und eine Krone aus fünf groben Ballen über
## derselben Hülle wie die volle – der Umriss springt beim Wechsel nicht.
static func _riese_fern(schluessel: String, b: Dictionary) -> Dictionary:
	var name := schluessel + "_fern"
	if _netze.has(name):
		return _netze[name]
	var huelle: AABB = b["huelle"]
	var kr := maxf(huelle.size.x, huelle.size.z) * 0.36
	var krone := _indiziert(Kronenwolke.netz({"radius": kr, "hoehe": huelle.size.y * 0.72,
			"variante": 1, "ballen": 5, "karten": 24, "mitte": huelle.get_center(),
			"saat": huelle.size.x as int + 17}))
	var f := {"stamm": b["schatten"], "krone": krone}
	_netze[name] = f
	return f


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
## Hangwald ist – in Hainen statt auf einem Raster (sonst eine Plantage aus
## gleichen Schirmen auf Rasen): Hainmitten gut 18 m auseinander, wo das
## Gelände Wald trägt (`L01Gelaende.wald` ≥ 0,2), je Hain drei bis
## acht Bäume in bis zu 9 m um die Mitte (mehr und weiter, wo das Gelände
## dichten Wald trägt), deren Kronen sich überlappen; ein großer Baum in
## der Mitte, darum viele kleinere. Zwischen den Hainen offene Wiese mit
## einzelnen Sträuchern und Totholz. Unter den Kronen Unterholz, damit
## kein Rasen durch den Wald scheint. Tönung je Hain.
static func _talwald_nah(level: Level01) -> void:
	if _level_debug:
		for k in 4:
			var b := _talbaum(k)
			var h: AABB = b["huelle"]
			print("Wald: Talbaum %d: Höhe %.1f, Krone %.1f–%.1f (unten %.0f %%), breit %.1f" % [k,
					float(b["hoehe"]), h.position.y, h.end.y, 100.0 * h.position.y / float(b["hoehe"]),
					h.size.x])
		for k in 3:
			var box := _fernbaum(k).get_aabb()
			print("Wald: Fernbaum %d: %.1f–%.1f, breit %.1f × %.1f" % [k, box.position.y, box.end.y,
					box.size.x, box.size.z])
	var ws := Waldsetzer.new(_wurzel, "Talwald", ZELLE_TAL)
	ws.art("stamm", {"stoff": _borke(), "sicht": SICHT_TAL, "verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_TAL), "sicht": SICHT_TAL,
			"verschmelzen": true, "karten": true})
	# Hinter `SICHT_TAL` dieselben Bäume in der Fernfassung.
	ws.art("fern", {"stoff": Kronenwolke.stoff(LAUB_TAL, false), "sicht_von": SICHT_TAL,
			"sicht": SICHT_FERN, "verschmelzen": true, "rand": 8.0})
	var rng := PropWerkzeug.zufall(8101)
	var tot: Array[ArrayMesh] = [
		Riesenstamm.netz({"hoehe": 11.0, "radius": 0.42, "oben": "bruch", "aeste": 3,
				"ast_start": 0.45, "ast_laenge": 3.0, "moos": 0.35, "saat": 8201}),
		Riesenstamm.netz({"hoehe": 8.0, "radius": 0.5, "oben": "bruch", "aeste": 2,
				"ast_start": 0.5, "ast_laenge": 2.4, "moos": 0.4, "brettwurzeln": 4,
				"saat": 8202})]
	var rand_busch := _indiziert(Kronenwolke.netz({"radius": 1.9, "hoehe": 2.6, "variante": 1,
			"karten": 18, "ballen": 3, "saat": 8301}))
	var hain := FastNoiseLite.new()
	hain.seed = 8102
	hain.frequency = 1.0 / HAIN_WEITE
	hain.fractal_octaves = 2
	# Hainmitten: Kandidaten auf einem feinen Raster (`HAIN_SCHRITT`), eine
	# Mitte nur, wo das Gelände Wald trägt und keine andere näher als
	# `HAIN_RASTER` liegt. Ein grobes Raster fand in schmalen Waldstreifen
	# (am Fuß der Wand von B, am Talrand) oft keinen Punkt – unter dem Grat
	# lag dann nur Wiese.
	var mitten: Array[Vector2] = []
	var wiese := HAIN_SCHRITT * HAIN_SCHRITT / (21.0 * 21.0)
	var x := FELD.position.x
	while x < FELD.end.x:
		var z := FELD.position.y
		while z < FELD.end.y:
			var mitte := Vector2(x + rng.randf_range(0.0, HAIN_SCHRITT),
					z + rng.randf_range(0.0, HAIN_SCHRITT))
			z += HAIN_SCHRITT
			var d := _wegabstand(mitte.x, mitte.y)
			if d > NAH_WEIT + 6.0 or d < 3.0:
				continue
			var w := L01Gelaende.wald(mitte.x, mitte.y)
			if w < 0.2:
				# Wiese: ab und zu ein Strauch oder ein toter Baum.
				var y := L01Gelaende.hoehe(mitte.x, mitte.y)
				if _tal_platz(level, mitte, false):
					if w > 0.08 and rng.randf() < 0.45 * wiese:
						_randbusch(ws, rand_busch, Vector3(mitte.x, y, mitte.y), rng)
					elif rng.randf() < 0.12 * wiese and d > 16.0:
						_totholz(ws, tot, Vector3(mitte.x, y, mitte.y), rng)
				continue
			var frei := true
			for m in mitten:
				if m.distance_squared_to(mitte) < HAIN_RASTER * HAIN_RASTER:
					frei = false
					break
			if not frei:
				continue
			mitten.append(mitte)
			var dicht := smoothstep(0.2, 0.85, w)
			var anzahl := roundi(lerpf(3.0, 8.0, dicht) * rng.randf_range(0.8, 1.15))
			var weite := lerpf(4.5, 9.0, dicht)
			_hain(level, ws, rng, mitte, anzahl, weite, _hainton(hain, mitte.x, mitte.y),
					rand_busch)
		x += HAIN_SCHRITT
	_zaehle("tal_haine", mitten.size())
	_totholz_tal(ws, tot, rng)
	var zz := ws.fertig()
	_zaehle("tal_knoten", int(zz["knoten"]))
	_zaehle("tal_dreiecke", int(zz["dreiecke"]))


## Eine feste Streuung 0..1 nach dem Ort (ohne Würfel): für Werte, die
## neu dazukamen, ohne die Würfelfolge – und damit alle folgenden
## Platzierungen – zu verschieben.
static func _streu(p: Vector2, saat: int) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233 + float(saat) * 1.618) * 43758.5453, 1.0)


## Ein Hain des nahen Talwalds um `mitte` (Welt-XZ): `anzahl` Bäume in bis
## zu `weite` m, getönt mit `ton_hain`. Der erste steht nahe der Mitte und
## ist der größte. Stämme halten im Hain nur 60 % des üblichen Abstands –
## die Kronen überlappen sich. Unter gut jedem dritten Baum ein Strauch.
static func _hain(level: Level01, ws: Waldsetzer, rng: RandomNumberGenerator, mitte: Vector2,
		anzahl: int, weite: float, ton_hain: Color, busch: ArrayMesh) -> void:
	for n in anzahl:
		var gesetzt := false
		for wurf in 3:
			var w := rng.randf() * TAU
			var r := (sqrt(rng.randf()) * weite) if n > 0 else rng.randf_range(0.0, 1.2)
			var p := mitte + Vector2(cos(w), sin(w)) * r
			if not _tal_platz(level, p, true):
				continue
			if not _staemme.frei(p, TAL_ABSTAND * 0.6):
				continue
			var y := L01Gelaende.hoehe(p.x, p.y)
			var nadel := rng.randf() < 0.2
			var k := 2
			if not nadel:
				var auswahl: Array[int] = [0, 3, 0, 3, 1]
				k = auswahl[rng.randi_range(0, auswahl.size() - 1)]
			var b := _talbaum(k)
			# Wenige große, viele kleine: der erste groß, die übrigen schief
			# verteilt zwischen 0,6 und 1,2.
			var groesse := rng.randf_range(1.15, 1.5) if n == 0 \
					else lerpf(0.6, 1.25, pow(rng.randf(), 1.4))
			var lage := _lage(Vector3(p.x, y, p.y), rng.randf() * TAU,
					groesse * rng.randf_range(0.9, 1.1), groesse)
			# Breit und gedrungen oder schmal und hoch, je Baum: Mit nur leicht
			# gestreckten Kronen stand im Tal dutzendfach derselbe Stapel aus
			# Polstern. Gezeichnet wird er in der geprüften Hülle gestaucht
			# (Höhe 74–100 %, Breite 78–100 %, gestreut nach dem Ort, `_streu`):
			# Würfelfolge, Prüfungen und damit der Wald bleiben, wie sie waren
			# – mit neuen Würfen stand in der Seitenansicht der Wiese (s 186)
			# plötzlich ein Stamm dicht vor der Kamera.
			var bild := Transform3D(lage.basis.scaled_local(Vector3(
					lerpf(0.78, 1.0, _streu(p, 17)), lerpf(0.74, 1.0, _streu(p, 11)),
					lerpf(0.78, 1.0, _streu(p, 17)))), lage.origin)
			var ton := ton_hain * _ton(rng, Vector2(0.86, 1.0), 0.03)
			if nadel:
				ton = ton * NADEL_TON
			elif _auf_riegel(p.x, p.y):
				ton = ton * Color(0.78, 0.84, 0.84)
			var ok := _pflanze(ws, b, lage, "stamm", "krone", _ton(rng, Vector2(0.8, 0.95), 0.03),
					ton, {"talkante": true, "fern": "fern", "zeichnen": bild})
			if not ok and groesse > 0.75:
				# Unter der Kante: ein kleinerer Baum passt vielleicht.
				groesse = 0.65
				lage = _lage(Vector3(p.x, y, p.y), rng.randf() * TAU, 0.7, groesse)
				ok = _pflanze(ws, b, lage, "stamm", "krone", Color(0.9, 0.9, 0.9), ton,
						{"talkante": true, "fern": "fern"})
			if not ok:
				continue
			_staemme.dazu(p, TAL_ABSTAND * 0.6)
			_zaehle("tal")
			gesetzt = true
			# Unterholz dicht am Stamm: Unter den Kronen soll kein heller Rasen
			# liegen, und der Stamm verschwindet im Laub.
			if rng.randf() < 0.55:
				var wb := rng.randf() * TAU
				var ort := p + Vector2(cos(wb), sin(wb)) * rng.randf_range(1.6, 2.6)
				if _tal_platz(level, ort, false):
					_randbusch(ws, busch, Vector3(ort.x, L01Gelaende.hoehe(ort.x, ort.y), ort.y), rng,
							0.1)
			break
		if not gesetzt:
			_zaehle("tal_ohne_platz")
	# Am Rand des Hains ein, zwei Sträucher: Der Wald endet nicht an Stämmen.
	for k in rng.randi_range(0, 2):
		var wb := rng.randf() * TAU
		var ort := mitte + Vector2(cos(wb), sin(wb)) * (weite + rng.randf_range(1.5, 3.5))
		if _tal_platz(level, ort, false):
			_randbusch(ws, busch, Vector3(ort.x, L01Gelaende.hoehe(ort.x, ort.y), ort.y), rng)


## Darf der nahe Talwald bei `p` (Welt-XZ) pflanzen? Nah am Weg (3 m bis
## `NAH_WEIT`), nicht links von A bis C4 (dort Hallen- und Hangwald), nicht
## rechts im Hallenwald, und nicht in der Lichtung vor der Seitenansicht
## der Bachwiese (`LICHTUNG`: s 178–194, q 16–40 – der Blick von dort über
## die Wiese auf den Stammfuß, und aus der Wiese ins Tal; dort auch keine
## Sträucher). `baum`: ein Baum (sonst ein Strauch).
static func _tal_platz(level: Level01, p: Vector2, baum: bool) -> bool:
	var d := _wegabstand(p.x, p.y)
	if d > NAH_WEIT or d < 3.0:
		return false
	var i := _naechste(p.x, p.y)
	if i < 0:
		return false
	var s := _bahn_s[i]
	var q := _quer(i, p.x, p.y)
	if q < 0.0 and s < 166.0:
		return false
	if q > 0.0 and s < 26.0:
		return false
	var rand := 0.0 if baum else 3.0
	if s > LICHTUNG.x - rand and s < LICHTUNG.y + rand and q > LICHTUNG.z - rand \
			and q < LICHTUNG.w:
		return false
	return true

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


## Ein Strauch am Waldrand (im Stoff der Kronen, kein eigener Aufruf).
static func _randbusch(ws: Waldsetzer, netz: ArrayMesh, fuss: Vector3,
		rng: RandomNumberGenerator, abstand: float = 1.4) -> void:
	if not _staemme.frei(Vector2(fuss.x, fuss.z), abstand):
		return
	var gross := rng.randf_range(0.75, 1.35)
	var lage := _lage(fuss + Vector3.UP * 0.5 * gross, rng.randf() * TAU,
			gross * rng.randf_range(0.9, 1.2), gross)
	var huelle := lage * netz.get_aabb()
	if not _weg_frei(huelle) or not _talkante_frei(huelle):
		return
	var i := _naechste(fuss.x, fuss.z)
	if i >= 0 and absf(_quer(i, fuss.x, fuss.z)) < _bahn_halb[i] + 2.5 \
			and absf(fuss.y - _bahn_p[i].y) < 3.0:
		return
	ws.setze("krone", netz, lage, _ton(rng, Vector2(0.8, 1.0)))
	_staemme.dazu(Vector2(fuss.x, fuss.z), 1.2)
	_zaehle("randbuesche")


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


## Der ferne Wald, erster Schritt: die Kandidaten. Flache Kronen mit
## angedeutetem Stamm, überall, wo das Gelände Wald trägt, keine nahe Krone
## steht und das Gelände gezeichnet ist (`L01Gelaende.FELD`) – in Hainen:
## Ein grobes Rauschen (`HAIN_WEITE`) schiebt die Walddichte auf und ab, so
## wechseln dichte Haine und Lichtungen, statt dass ein Raster das Tal
## gleichmäßig betupft. Größen schief verteilt (viele kleine, wenige große),
## Tönung je Hain (oliv, gelbgrün, blaugrün).
static func _talwald_fern_sammeln(level: Level01) -> void:
	_fern_kandidaten.clear()
	_himmel_anlegen(level)
	_hoehen_anlegen()
	var gelaende: Rect2 = L01Gelaende.FELD.grow(-2.0)
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1), _fernbaum(2)]
	var rng := PropWerkzeug.zufall(9101)
	var hain := FastNoiseLite.new()
	hain.seed = 9102
	hain.frequency = 1.0 / HAIN_WEITE
	hain.fractal_octaves = 2
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
			var w := L01Gelaende.wald(px, pz) + hain.get_noise_2d(px, pz) * 0.32
			if w < rng.randf_range(0.16, 0.5):
				continue
			if not _kronen.frei(Vector2(px, pz), 3.6):
				continue
			if d < NAH_WEIT + 6.0 and not _nah_leer(px, pz):
				continue
			var y := L01Gelaende.hoehe(px, pz)
			var nadel := rng.randf() < 0.2
			# Schirmkronen selten: Flach lesen sie sich im Dunst als Scheiben.
			var k := 2 if nadel else (1 if rng.randf() < 0.25 else 0)
			var groesse := lerpf(0.72, 1.45, pow(rng.randf(), 1.7)) * (1.08 if y > 16.0 else 1.0)
			var groesse_y := groesse * lerpf(0.76, 1.14, _streu(Vector2(px, pz), 13))
			var dreh := rng.randf() * TAU
			var lage := _lage(Vector3(px, y, pz), dreh,
					groesse * remap(rng.randf_range(0.9, 1.15), 0.9, 1.15, 0.84, 1.3), groesse_y)
			var huelle := lage * netze[k].get_aabb()
			if not _talkante_frei(huelle) or not _weg_frei(huelle):
				continue
			if not _kegel_frei(huelle):
				continue
			var ton := _hainton(hain, px, pz) * _ton(rng, Vector2(0.86, 1.0), 0.04)
			if nadel:
				ton = ton * NADEL_TON
			elif _auf_riegel(px, pz):
				ton = ton * Color(0.78, 0.84, 0.84)
			# Erst nach allen Würfen des Zufalls: Die übrigen Bäume stehen
			# genau dort, wo sie ohne diese Prüfung stünden.
			if not gelaende.has_point(Vector2(px, pz)):
				_zaehle("fern_ohne_boden")
				continue
			_fern_kandidaten.append({"lage": lage, "k": k, "ton": ton,
					"p": Vector2(px, pz), "y": y, "groesse": groesse_y})
			_kronen.dazu(Vector2(px, pz), 3.6 * groesse)
		x += raster


## Der ferne Wald, zweiter Schritt: Einzelgänger fallen weg (eine Krone
## allein am Hang liest sich immer als Scheibe; nur Gruppen ab drei Bäumen
## bleiben), dann die Himmelsprobe (`_einsinken`): Stünde das untere Laub
## einer Krone von einer Station aus frei vor dem Himmel – auf dem Rücken
## der Randhügel, am Westhang –, sinkt der Baum ein, die Krone steckt im
## Boden: ein Waldsaum auf dem Kamm statt einer Scheibe in der Luft. Er
## wird dazu etwas kühler (Luftperspektive). Weg fällt nur, wer hinter
## einem Kamm als Ballon über ihm hinge und dafür zu tief sinken müsste.
static func _talwald_fern_setzen() -> void:
	var zellen := {}
	for i in _fern_kandidaten.size():
		var p: Vector2 = _fern_kandidaten[i]["p"]
		var kz := Vector2i(floori(p.x / GRUPPE_WEITE), floori(p.y / GRUPPE_WEITE))
		if not zellen.has(kz):
			zellen[kz] = PackedInt32Array()
		var liste: PackedInt32Array = zellen[kz]
		liste.append(i)
		zellen[kz] = liste
	var ws := Waldsetzer.new(_wurzel, "Fernwald", ZELLE_FERN_WEB if Effekte.reduziert else ZELLE_FERN)
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_FERN, false), "sicht": SICHT_FERN,
			"verschmelzen": true, "rand": 10.0})
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1), _fernbaum(2)]
	for e: Dictionary in _fern_kandidaten:
		var p: Vector2 = e["p"]
		var kz := Vector2i(floori(p.x / GRUPPE_WEITE), floori(p.y / GRUPPE_WEITE))
		var nachbarn := 0
		for a in range(kz.x - 1, kz.x + 2):
			for b in range(kz.y - 1, kz.y + 2):
				var k2 := Vector2i(a, b)
				if not zellen.has(k2):
					continue
				for j: int in zellen[k2]:
					var q: Vector2 = _fern_kandidaten[j]["p"]
					if q != p and q.distance_to(p) < GRUPPE_WEITE:
						nachbarn += 1
		if nachbarn < 2:
			_zaehle("fern_einzeln")
			continue
		var k: int = e["k"]
		var lage: Transform3D = e["lage"]
		var ton: Color = e["ton"]
		var groesse: float = e["groesse"]
		var hoch := netze[k].get_aabb().end.y * groesse
		var tief := _einsinken(Vector3(p.x, float(e["y"]), p.y), hoch)
		if tief < 0.0:
			_zaehle("fern_ballon")
			continue
		if tief > 0.0:
			lage.origin.y -= tief
			ton = ton * Color(0.92, 0.97, 1.04)
			_zaehle("fern_gesunken")
		ws.setze("krone", netze[k], lage, ton)
		_zaehle("fern")
	_fern_kandidaten.clear()
	var zz := ws.fertig()
	_zaehle("fern_knoten", int(zz["knoten"]))
	_zaehle("fern_dreiecke", int(zz["dreiecke"]))


## Tönung eines Hains: oliv, gelbgrün oder blaugrün, weich überblendet nach
## einem zweiten groben Rauschen. So liest sich der Wald aus der Ferne in
## Flecken, die mit der Entfernung kleiner werden, statt als Tupfen gleicher
## Farbe.
static func _hainton(hain: FastNoiseLite, x: float, z: float) -> Color:
	var n := hain.get_noise_2d(x * 0.61 + 311.0, z * 0.61 - 173.0) * 1.6
	if n < 0.0:
		return HAIN_GELB.lerp(Color.WHITE, clampf(1.0 + n, 0.0, 1.0))
	return Color.WHITE.lerp(HAIN_BLAU, clampf(n, 0.0, 1.0))


## Die Augen der Himmelsprobe: die Verfolgerkamera alle `HIMMEL_SCHRITT` m
## mit ihrer waagerechten Blickrichtung (zum Blickpunkt 6 m voraus).
static func _himmel_anlegen(level: Level01) -> void:
	_himmel_augen = PackedVector3Array()
	_himmel_blick = PackedVector3Array()
	var s := 0.0
	while s <= Level01.M_ENDE:
		var auge := _auge(level, s)
		var blick := level.weg_punkt(s + 6.0) - auge
		blick.y = 0.0
		_himmel_augen.append(auge)
		_himmel_blick.append(blick.normalized())
		s += HIMMEL_SCHRITT


## Die gezeichnete Geländehöhe auf einem Raster (`HOEHEN_ZELLE` m) über
## `L01Gelaende.FELD`, einmal gelesen: Die Himmelsprobe fragt sie hundert-
## tausendfach ab, die Dreiecke des Felds zu suchen kostete dort den
## größten Teil der Bauzeit.
static func _hoehen_anlegen() -> void:
	var feld: Rect2 = L01Gelaende.FELD
	_hoehen_mass = Vector2i(ceili(feld.size.x / HOEHEN_ZELLE) + 1,
			ceili(feld.size.y / HOEHEN_ZELLE) + 1)
	_hoehen_raster = PackedFloat32Array()
	_hoehen_raster.resize(_hoehen_mass.x * _hoehen_mass.y)
	var i := 0
	for b in _hoehen_mass.y:
		var z := feld.position.y + float(b) * HOEHEN_ZELLE
		for a in _hoehen_mass.x:
			var h := L01Gelaende.hoehe(feld.position.x + float(a) * HOEHEN_ZELLE, z)
			_hoehen_raster[i] = h if not is_nan(h) else -1000.0
			i += 1


## Wie tief (m) muss ein ferner Baum (Fuß `fuss`, Höhe `hoch`) einsinken,
## damit er von keiner Station aus als Scheibe in der Luft hängt? 0: gar
## nicht; < 0: das geht nicht, er fällt weg.
## Die Krone schwebt, wenn von einer Station aus ihr unteres Laub frei im
## Blick liegt und dahinter bis `HIMMEL_HINTER` von der Station kein
## Gelände mehr kommt: Sie steht vor dem Himmel, ihr angedeuteter Stamm
## verschwindet im Dunst – auf der Rückseite der Randhügel, am Westhang, am
## Rand des Felds.
## Dass ein Kamm davor nur den Stamm verdeckt, reicht nicht, und ein Kamm
## weiter als `KAMM_WEIT` zählt gar nicht: Im Dunst ist er kaum heller als
## der Himmel. Verdeckt ein naher Kamm auch das untere Laub, ragt nur der
## Wipfel hinter ihm auf; steht dahinter ein Hang, liest sie sich vor ihm
## als Wald. Beides darf sein.
## Schwebt sie, zählt, ob die Station ihren Fuß sicher sieht (1,5 m über
## der Sichtlinie über den Kamm davor, `_kammhoehe`): Dann steht der Baum
## auf einem Kamm und sinkt um `FERN_SINKEN` seiner Höhe ein – ein
## Waldsaum auf dem Kamm. Verdeckt ihr ein Kamm den Fuß (fast), hinge die
## Krone als Ballon über ihm, mit Himmel dazwischen: Dann sinkt er, bis die
## Unterseite der Krone hinter dem Kamm liegt – höchstens um
## `FERN_SINKEN_MAX` seiner Höhe (sonst läge die Krone von näheren
## Stationen aus als Hügel am Hang).
static func _einsinken(fuss: Vector3, hoch: float) -> float:
	# Das untere Laub: Die Krone beginnt bei `FERN_BODEN` der Höhe.
	var unten := fuss + Vector3.UP * hoch * (FERN_BODEN + 0.1)
	var tief := 0.0
	for k in _himmel_augen.size():
		var auge := _himmel_augen[k]
		var zu := unten - auge
		var e := zu.length()
		if e < 40.0 or e > KAMERA_FERN - 2.0:
			continue
		# Nur, was diese Kamera ungefähr im Bild hat (±56° waagerecht).
		if Vector3(zu.x, 0.0, zu.z).normalized().dot(_himmel_blick[k]) < 0.55:
			continue
		var dir := zu / e
		if _gelaende_im_strahl(unten, dir, 2.0, HIMMEL_HINTER - e):
			continue
		if _gelaende_im_strahl(auge, dir, 3.0, minf(e - 2.0, KAMM_WEIT)):
			continue
		var noetig := hoch * FERN_SINKEN
		var kamm := _kammhoehe(auge, fuss)
		if kamm > fuss.y - 1.5:
			noetig = maxf(noetig, fuss.y + hoch * FERN_BODEN + 0.5 - kamm)
		if noetig > hoch * FERN_SINKEN_MAX:
			return -1.0
		tief = maxf(tief, noetig)
	return tief


## Höhe der Sichtlinie von `auge` über das Gelände davor, am Ort `ziel`
## (waagerecht gemessen): Was dort tiefer liegt, verdeckt ein Kamm. -INF,
## wenn nichts davor liegt. Fein abgetastet (2 m, zwischen den Punkten des
## Rasters gemittelt) – ein schmaler Grat verdeckt oft gerade die paar
## Meter, um die es geht; nur für Kronen, die schon als schwebend gelten.
static func _kammhoehe(auge: Vector3, ziel: Vector3) -> float:
	var flach := Vector2(ziel.x - auge.x, ziel.z - auge.z)
	var weit := flach.length()
	if weit < 8.0:
		return -INF
	var dir := flach / weit
	var steil := -INF
	var t := 3.0
	while t < weit - 4.0:
		var h := _raster_hoehe(auge.x + dir.x * t, auge.z + dir.y * t)
		if not is_nan(h):
			steil = maxf(steil, (h - auge.y) / t)
		t += HOEHEN_ZELLE
	if steil == -INF:
		return -INF
	return auge.y + steil * weit


## Geländehöhe aus dem Raster der Himmelsprobe, zwischen den vier nächsten
## Punkten gemittelt (NAN außerhalb des Felds).
static func _raster_hoehe(x: float, z: float) -> float:
	var fx := (x - L01Gelaende.FELD.position.x) / HOEHEN_ZELLE
	var fz := (z - L01Gelaende.FELD.position.y) / HOEHEN_ZELLE
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


## Liegt Gelände über dem Strahl `von` + t · `dir` für t in [ab, bis]? Aus
## dem Raster (`_hoehen_anlegen`), nächster Punkt; die Schritte wachsen mit
## der Weite (Hügel in 150 m sind breit). Außerhalb des gezeichneten Felds
## ist keines.
static func _gelaende_im_strahl(von: Vector3, dir: Vector3, ab: float, bis: float) -> bool:
	var x0 := L01Gelaende.FELD.position.x
	var z0 := L01Gelaende.FELD.position.y
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
	var bluete: Array[ArrayMesh] = []
	for k in 3:
		busch.append(_indiziert(Kronenwolke.netz({"radius": 1.35 + 0.15 * float(k),
				"hoehe": 2.3 + 0.25 * float(k), "variante": 0, "karten": 26, "ballen": 3,
				"saat": 9601 + k})))
		bluete.append(_bluehend(busch[k], BLUETE_ROSA if k == 1 else BLUETE_WEISS))
	var rng := PropWerkzeug.zufall(9501)
	# Stücke der Hecke: [von, bis, q von Leitlinie (innen), Breite]
	var stuecke := [Vector4(159.8, 172.3, 7.4, 1.9), Vector4(183.8, 194.4, 7.4, 1.9)]
	for st: Vector4 in stuecke:
		var s := st.x
		while s < st.y:
			for reihe in 2:
				var q := st.z + 0.35 + float(reihe) * st.w * 0.55 + rng.randf_range(-0.2, 0.3)
				var ss := s + float(reihe) * 0.9 + rng.randf_range(-0.3, 0.3)
				_busch(level, ws, busch, bluete, ss, q, rng)
			s += rng.randf_range(1.6, 2.3)
	# Um die Wurzelwiese: der Linie von (194, 6,8) über (196, 12,4) bis
	# (214, 12,4) nach, dann quer zurück zum Wulst.
	var linie := [Vector2(194.2, 7.6), Vector2(196.2, 13.3), Vector2(214.6, 13.3)]
	var s2 := 194.4
	while s2 < 214.6:
		var q := _polylinie(linie, s2)
		if not is_nan(q):
			_busch(level, ws, busch, bluete, s2, q + rng.randf_range(0.0, 0.5), rng)
			if rng.randf() < 0.6:
				_busch(level, ws, busch, bluete, s2 + 0.8, q + 1.3 + rng.randf_range(0.0, 0.5), rng)
		s2 += rng.randf_range(1.5, 2.1)
	var z := ws.fertig()
	_zaehle("hecke_knoten", int(z["knoten"]))


## Ein blühender Busch aus einem grünen: dieselbe Krone im Blütenstoff
## (`BLUETE`, fast weiß), der Körper über die Scheitelfarbe grün wie die
## übrigen (`LAUB_HECKE`), und nur Blattkarten oben auf der Krone (ab
## halber Höhe, nach oben dichter) in der Farbe `bluete`. Vorher war
## jeder fünfte Busch ganz rosa – unten vom Kronenstoff violett
## abgedunkelt las er sich als Zuckerwatte, die lauteste Form im Bild.
static func _bluehend(netz: ArrayMesh, bluete: Color) -> ArrayMesh:
	var arrays := netz.surface_get_arrays(0)
	var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var ecken: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var gruen := Color(LAUB_HECKE.r / BLUETE.r, LAUB_HECKE.g / BLUETE.g, LAUB_HECKE.b / BLUETE.b)
	for i in farben.size():
		var f := farben[i]
		var ton := gruen
		if uv2[i].x >= 0.5:
			# Blattkarte: vier Ecken am selben Ort, der Zufall hängt am Ort.
			var t := uv2[i].x - 1.0
			var p := ecken[i]
			var zufall := fposmod(sin(p.x * 12.9898 + p.y * 78.233 + p.z * 37.719) * 43758.55, 1.0)
			if zufall < smoothstep(0.45, 0.85, t) * 0.8:
				ton = bluete
		farben[i] = Color(f.r * ton.r, f.g * ton.g, f.b * ton.b, f.a)
	arrays[Mesh.ARRAY_COLOR] = farben
	var neu := ArrayMesh.new()
	neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	neu.custom_aabb = netz.custom_aabb
	return neu


static func _busch(level: Level01, ws: Waldsetzer, busch: Array[ArrayMesh],
		bluete: Array[ArrayMesh], s: float, q: float, rng: RandomNumberGenerator) -> void:
	var fuss := _boden(level, s, q)
	if not _kistenfrei(fuss, 1.8):
		return
	var i := _naechste(fuss.x, fuss.z)
	if i >= 0 and absf(_quer(i, fuss.x, fuss.z)) < _bahn_halb[i] + 1.2:
		return
	var wahl := rng.randi_range(0, busch.size() - 1)
	var netz := busch[wahl]
	var hoch := rng.randf_range(0.8, 1.3)
	var lage := _lage(fuss + Vector3.UP * (netz.get_aabb().size.y * 0.36 * hoch), rng.randf() * TAU,
			rng.randf_range(0.9, 1.25), hoch)
	# Jeder Busch ist grün; auf knapp jedem dritten sitzen oben Blüten.
	var bluehend := rng.randf() < 0.3
	ws.setze("bluete" if bluehend else "gruen", bluete[wahl] if bluehend else netz, lage,
			_ton(rng, Vector2(0.88, 1.0) if bluehend else Vector2(0.85, 1.0)))
	_zaehle("buesche")


# ================================================================ Felsen

## Deko-Felsen und Totholz: am Saum des Hallenwalds, am Hang zwischen den
## Stämmen und am Rand der Bachwiese. Fremdmodelle (M8), sonst `Findling.brocken`. Die
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
	# Totholz an der Bachwiese: ein Moosstamm hinter der Hecke, zwei Stümpfe
	# (M16, Rückfall – die Kenney-Stämme taugen erst ab 40 m).
	ws.art("holz", {"stoff": _borke(), "schatten": true, "sicht": SICHT_FELS,
			"verschmelzen": true})
	var moosstamm := Riesenstamm.liegend(0.48, 6.5, {"saat": 9921, "rippen": 10, "aeste": 1})
	var a := _boden(level, 165.0, 10.6)
	var b := _boden(level, 170.5, 11.8)
	if _staemme.frei(Vector2((a.x + b.x) * 0.5, (a.z + b.z) * 0.5), 1.5):
		ws.setze("holz", moosstamm, _liegend_lage(a, b, 0.48 * 0.55), Color(0.9, 0.9, 0.86))
		_zaehle("moosstaemme")
	for st: Vector3 in [Vector3(192.8, 10.2, 0.55), Vector3(186.4, -9.4, 0.45)]:
		var fuss := _boden(level, st.x, st.y)
		if not _staemme.frei(Vector2(fuss.x, fuss.z), 0.9):
			continue
		ws.setze("holz", Riesenstamm.stumpf(st.z, st.z * 1.8, {"saat": 9930 + int(st.x)}),
				_lage(fuss, rng.randf() * TAU, 1.0, 1.0), Color(0.9, 0.88, 0.86))
		_zaehle("stuempfe")
	ws.fertig()
