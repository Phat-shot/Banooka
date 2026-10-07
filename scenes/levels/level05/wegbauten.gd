extends RefCounted
class_name L05Wegbauten
## Level 05, Modul „Wegbauten": was am Weg steht und liegt (Entwurf L05
## §5, §8.4, §9.1, Paket P5) – Wildgatter Ü, Wurzelbögen D1/D2, Fluderjoche
## D3/D4 (heil und gebrochen), Wurzelhürden H1/H2, die Findlingsgasse F1/F2,
## Trittstein und Bänke der Geheimnisse G1–G3, die Grabenrampe aus dem
## Suhlgraben, die Wurzeltreppen S1–S3, das gebrochene Wehr und die
## Wegpfähle der Rastplätze.
##
## FINDLING-REGEL (wie `L01Wegbauten`). Jedes Bauteil, an das die Figur
## stößt oder auf dem sie steht, hat seinen Körper aus `KorridorLevel`
## (`duckdurchlass`, `huerde`, `findling_hindernis`) bzw. aus
## `Level05.BEGEHBARES`, und die Optik liegt genau darauf:
##   Durchlass  Unterkante des Riegels auf DUCK_UNTEN (0,95), Oberkante auf
##              RIEGEL_OBEN (1,40) – die Hölzer werden dort plattgedrückt
##              (`_holz`, "oben"/"unten"), über der ganzen Weite, die man
##              erreicht (bis hinter die Leitlinie). Die Unterkante ist hell
##              abgewetzt (Entwurf §8.4: „Unterkante des Riegels hell"), am
##              Gatter und an den Jochen auch der Rücken; die Wurzelbögen
##              behalten oben Borke und Moos (`_wurzelbogen`). Unter 0,95
##              steht über dem Weg nichts.
##   Hürde      die Wurzel genau so breit wie der Körper tief (0,6), ihr
##              Rücken flach auf HUERDE_HOEHE (0,7), hell abgewetzt, die
##              Flanken bemoost; in einem gescherten Rahmen, der wie der
##              Körper der Decke folgt (`_scher_lage`).
##   Findling   `Findling.netz` auf den Kasten des Körpers (Oberseite =
##              Oberkante, Seiten nur nach innen) mit rechteckigem Grundriss
##              (Option „ecke"), im gescherten Rahmen; siehe `_findling`.
##              Gemessen (Strahlen gegen die Körper, h 0,15–1,25):
##              Oberseite 2–12 mm unter der Oberkante, Flanken und
##              Stirnflächen 0,1–1,5 cm dahinter, die Ecken auf der
##              Winkelhalbierenden 1,9–3,1 cm.
##   Bänke      G1–G3 und der Trittstein: `Findling.netz` in der Lage ihres
##              Kastens (`weg.begehbar`), Kisten auf der ebenen Fläche
##              (`_mit_kisten_auf`, wie Level 01).
##   Treppen    die Wurzel an jeder Setzstufe liegt mit dem Rücken bündig in
##              der oberen Decke (+1,2 cm) und tritt 7 cm vor die Stufe.
##   Rampe      halbe Knüppel quer, die Spaltfläche genau auf der Oberseite
##              der Rampe und parallel zu ihr.
## Was man nicht erreicht – Pfosten hinter der Leitlinie, Bögen über 3,5 m,
## Pfähle neben der Wehrkrone, Stümpfe unter der Decke –, darf hinaus.
##
## DURCHLÄSSE (Entwurf §1 Nr. 2, §7.1 K5): massiv nur der Riegel; darüber
## offene Geometrie mit mindestens 60 % freier Fläche, damit die Figur
## dahinter zu sehen bleibt – im Rückblick steht jeder Durchlass zwischen
## Kamera und Figur. Gemessen (Strahlen längs des Weges im Raster 0,1 m
## zwischen Riegel und Kappe, nur die heile Optik): Ü 80 %, D1 85 %, D2 84 %,
## D3 69 %, D4 72 % frei.
##   Ü  Wildgatter: zwei Spaltriegel, Stangen alle 0,5 m (Ø 6–7 cm; an der
##      Stirn nur jede zweite), Pfosten hinter der Leitlinie, Kopfstangen auf
##      4,17–4,39 m.
##   D1, D2  Wurzelbogen: drei Wurzeln als Riegel (die ganze Tiefe von
##      1,8 m ist Körper – so liest sich auch die Tiefe als Masse), zwei
##      geflochtene Bogenwurzeln von Krone zu Krone (über dem Weg ≤ 4,6 m) und
##      ein Vorhang aus Wurzelsträhnen alle 0,3 m (Ø 5–7 cm).
##   D3, D4  Fluderjoch: zwei Böcke hinter den Leitlinien, die Zangen-
##      balken als Riegel (Spaltfläche nach außen), Latten alle 0,42 m, das
##      Gerinne als ausgehöhlter Halbstamm auf 4,02–4,58 m.
## Je Durchlass zwei Netze im Borkenstoff: die heile Optik (Kind des
## Körpers, über `duckdurchlass` „optik") und der Bruch („Bruch",
## unsichtbar, in `Effekte.VORWAERM_GRUPPE` – er wird erst gezeichnet, wenn
## der Keiler hindurchbricht; ohne Vorwärmen stockte dann das Bild). Den
## Wechsel schaltet `L05Jagd` (DURCHLASS-BRUCH, HEILEN) über
## `bruch_stellen`. Im Bruch fehlt die
## Mitte (BRESCHE): Riegel und Zangen hängen gesplittert durch, Stangen,
## Latten und Strähnen hängen als Stümpfe von oben, Stücke liegen am Boden
## (flacher als 0,3 m). Das Gerinne bleibt heil – den Schwall zeigt der
## Keiler als Effekt (`Keiler.durchbrechen`); das Wasser darin und den Fall
## an seinem Ende legt `L05Wasser` (Paket P6, über `gerinne_lage`).
##
## FREIRAUM (Entwurf §7.1 K1): Über |q| ≤ 3,5 steht nichts zwischen 4,6 und
## 9,2 m über dem Weg: Kopfstangen bis 4,39, Bogen bis gut 4,55 (Scheitel
## der Achse 4,3, flach bis |q| 3,7), Gerinne bis 4,58 m; Pfosten, Böcke und
## Pfähle stehen bei |q| ≥ 4,4. Die Freiraumprobe (LevelCheck) misst es.
##
## KOSTEN (Entwurf §10: 30 Zeichenaufrufe, +10 für Schatten; Handy 18).
## Gemessen (Messtore 8/60/90/140/218/280/296, mit gegen ohne Wegbauten):
## Rechner 4–9, Handy 4–9 Zeichenaufrufe. Je Abschnitt A–E ein Netz je
## Stoff: „Holz" (Borkenstoff), „Stein" (`Findling.stoff`), „Kranz"
## (`Findling.kranzstoff`, nur in der Nähe);
## je Durchlass eins (der Bruch erst nach dem Bruch); alle fünf Laternen in
## einem Netz (`Materialbibliothek.leuchtend`, ohne Licht, Entwurf §1 Nr. 22).
## Keine Schatten: Schatten werfen nur Stämme, Kisten, Figur und Keiler
## (§10), und die Sonne steht hinter der Kamera. Sichtweiten SICHT bzw.
## SICHT_HANDY, der Kranz SICHT_KRANZ; die Laternen ohne – sie zeigen die
## Rastplätze den Hang hinauf.
##
## BAUSPEICHER: Die Netze (Abschnitte, Durchlässe heil und gebrochen,
## Laternen) liegen nach dem ersten Laden im `Bauspeicher` (siehe
## `_abschnitt`); die Körper entstehen bei jedem Laden neu.
##
## Körper nur über die Bauteile von `KorridorLevel` (`duckdurchlass`,
## `huerde`, `findling_hindernis`), sonst keine Kollision. Keine
## Zufallsquelle außer `PropWerkzeug.zufall(saat)` und Rauschen mit fester
## Saat.
##
## AUSSERHALB VON LEVEL 05 (Werkstatt, Stationen 34–38; Entwurf §12 P9):
## Durchlass, Hürde, Findling, Stufenwurzel und Wehr gibt es auch öffentlich,
## für jedes `KorridorLevel` – `durchlass`, `huerde_koerper` + `huerde_netz`,
## `findling_koerper` + `findling_netz`, `stufenwurzel`, `wehr`, dazu
## `abschnitt` (Netze eines Sammlers samt Bauspeicher einhängen) und
## `bruch_stellen` (heil/gebrochen umschalten). Was Level 05 dafür aus
## seinen Tabellen liest – wo die Leitlinien stehen und wo die Kronen der
## Böschungen –, kommt als `Rand` herein; Level 05 baut über DIESELBEN
## Funktionen mit seinem eigenen Rand (`_rand_l05`). WARUM so: Die Werkstatt
## soll das Bauteil zeigen, das im Level steht, keine Abschrift. Gemessen
## (Scratch-Probe aller Netze, Formen und Lagen des gebauten Levels, kalt,
## je ein md5): Level 05 baut damit Bit für Bit dasselbe wie vorher.

## Sichtweiten (m) und Schwelle gegen Flackern.
const SICHT := 150.0
const SICHT_HANDY := 110.0
const SICHT_KRANZ := 55.0
const SICHT_RAND := 5.0
## Riegel der Durchlässe: Oberkante (die Unterkante ist DUCK_UNTEN) und die
## halbe Höhe seines Querschnitts vor dem Plattdrücken – knapp mehr als die
## halbe Höhe der Platte (0,225 m): So liegen Rücken und Unterkante ganz auf
## der Platte, die flachen Bänder bleiben aber schmal (gut 0,2 m). Mit
## voller Rundung (0,28–0,32) waren sie 0,33–0,37 m breit, und drei Wurzeln
## lasen sich von oben als Bretterboden.
const RIEGEL_OBEN := 1.4
const RIEGEL_HOCH := 0.24
## Breite der Bresche im Bruch: so weit um die Mitte fehlt alles.
const BRESCHE := 1.5
## Das Gerinne (Unterkante, Rand) über der Decke und sein Halbmesser.
const GERINNE_RAND := 4.58
const GERINNE_R := 0.56
const GERINNE_INNEN := 0.45
## Das Gerinne reicht so weit über die linke Leitlinie hinaus (über das Ufer,
## dort fällt sein Wasser in den Bach) und über die rechte (in die
## Sandsteinwand), und so viel fällt sein Rand über die ganze Länge nach
## links. `L05Wasser` legt das Wasser hinein (`gerinne_lage`).
const GERINNE_LINKS := 2.2
const GERINNE_RECHTS := 1.0
const GERINNE_FALL := 0.08
## Scheitel der Bogenwurzeln (Achse) und ihr Halbmesser dort.
const BOGEN_SCHEITEL := 4.3
const BOGEN_R := 0.18
const BOGEN_FLACH := 3.7
## Kopfstangen des Gatters (Achse) und Halbmesser.
const GATTER_KOPF := 4.28
const GATTER_KOPF_R := 0.11

## Farben im Borkenstoff (linear; Eigenfarbe: ALBEDO = COLOR.rgb).
## Abgewetzt: Rücken und Unterkanten, an denen Wild und Wetter reiben. Hell
## gegen die Borke (Albedo gut doppelt so hoch), aber kein Weiß: Mit 0,4 (linear)
## lasen sich die Rücken der Riegel im Bild als weiße Bretter.
const ABGEWETZT := Color(0.19, 0.15, 0.11)
## Frische Bruchflächen (im Bruch der Durchlässe): heller als alles daneben.
const FRISCH := Color(0.6, 0.48, 0.32)
## Verwittertes Spaltholz und alte Brüche.
const GRAU := Color(0.21, 0.19, 0.16)
## Hirnholz an Schnittenden.
const HIRN := Color(0.13, 0.11, 0.085)
## Das nasse Innere des Gerinnes.
const NASS := Color(0.055, 0.05, 0.045)
## Tönung der Borke: Wurzeln warm, Pfähle und Gatter vergraut, Strähnen hell.
const WURZEL_TON := Color(0.95, 0.85, 0.72)
const PFAHL_TON := Color(0.7, 0.66, 0.6)
const STRAEHNE_TON := Color(1.0, 0.9, 0.76)
## Steine: Sandstein im Tobel (Rotocker), Löss an der Böschungsbank.
const SANDSTEIN_TON := Color(1.0, 0.84, 0.7)
const LOESS_TON := Color(1.0, 0.92, 0.74)
## Laterne der Rastplätze (Entwurf §8.4: Wegpfahl mit leuchtendem Netz).
const LATERNE := Color(1.0, 0.68, 0.32)
const LATERNE_STAERKE := 2.4

## Optik der Begehbaren, die dieses Modul zeichnet (Level05 gibt ihnen nur
## eine leere Marke, `Level05._begehbar_optik`).
const BEGEHBARE: Array[String] = ["G1 Wurzelknie", "Grabenrampe", "G2 Böschungsbank",
		"G3 Trittstein", "G3 Sonnensims"]


## Bauschritte je Abschnitt (Entwurf §9.4 Schritt 6, vor den Kisten).
static func bauschritte(level: Level05) -> Array:
	return [
		{"text": "Wildgatter, Grabenrampe und Wurzelknie", "tun": func() -> void:
			_abschnitt_a(level)},
		{"text": "Wurzelbögen und Hürden", "tun": func() -> void: _abschnitt_b(level)},
		{"text": "Wurzeltreppen", "tun": func() -> void: _abschnitt_c(level)},
		{"text": "Fluderjoche und Findlingsgasse", "tun": func() -> void: _abschnitt_d(level)},
		{"text": "Wehr und Rastplätze", "tun": func() -> void: _abschnitt_e(level)},
	]


# ================================================================ Sammler

## Sammelt je Stoff die Netze eines Abschnitts (Muster
## `L01Wegbauten.Sammler`); `netze()` liefert je Stoff EIN Netz.
class Sammler:
	extends RefCounted
	var holz: SurfaceTool = Riesenstamm.bauer()
	var _stein: SurfaceTool = null
	var _kranz: SurfaceTool = null

	func stein(netz: Mesh, lage: Transform3D) -> void:
		if _stein == null:
			_stein = SurfaceTool.new()
			_stein.begin(Mesh.PRIMITIVE_TRIANGLES)
		for f in netz.get_surface_count():
			_stein.append_from(netz, f, lage)

	func kranz(netz: Mesh, lage: Transform3D) -> void:
		if netz == null:
			return
		if _kranz == null:
			_kranz = SurfaceTool.new()
			_kranz.begin(Mesh.PRIMITIVE_TRIANGLES)
		for f in netz.get_surface_count():
			_kranz.append_from(netz, f, lage)

	## {"Holz", "Stein", "Kranz"} -> ArrayMesh, nur was etwas enthält.
	func netze() -> Dictionary:
		var aus := {}
		var holz_netz := Riesenstamm.fertig(holz)
		if holz_netz.get_surface_count() > 0:
			aus["Holz"] = holz_netz
		if _stein != null:
			aus["Stein"] = _stein.commit()
		if _kranz != null:
			aus["Kranz"] = _kranz.commit()
		return aus


## Wo ein Bauteil steht: die Leitlinien links und rechts und die Kronen der
## Böschungen, je an einer Strecke `s`. Level 05 liest beides aus seinen
## Tabellen (`_rand_l05`), die Werkstatt gibt ihre eigenen Callables.
##   leitlinie  Callable(seite: float, s: float) -> float: Abstand der
##              Leitlinie von der Mitte (> 0), seite −1 links, +1 rechts
##   krone      Callable(seite: float, s: float) -> Vector2: Krone der
##              Böschung (Abstand von der Mitte, Höhe über der Decke), wie
##              `_krone`; nur der Wurzelbogen fragt danach
class Rand:
	extends RefCounted
	var _leitlinie: Callable
	var _krone: Callable

	func _init(leitlinie_: Callable, krone_: Callable) -> void:
		_leitlinie = leitlinie_
		_krone = krone_

	func leitlinie(seite: float, s: float) -> float:
		return float(_leitlinie.call(seite, s))

	func krone(seite: float, s: float) -> Vector2:
		return _krone.call(seite, s) as Vector2


## Der Rand von Level 05: Leitlinien aus LEITLINIEN, Kronen aus den Zügen
## „auf" (`_krone`).
static func _rand_l05(level: Level05) -> Rand:
	return Rand.new(func(seite: float, s: float) -> float: return _leitlinie(seite, s),
			func(seite: float, s: float) -> Vector2: return _krone(level, seite, s))


## Die Netze eines Abschnitts von Level 05 unter „Wegbauten/<anzeige>"
## (`abschnitt`, Schlüssel „l05_wegbauten_…").
static func _abschnitt(level: Level05, schluessel: String, anzeige: String,
		zeichnen: Callable) -> void:
	abschnitt(_wurzel(level), "l05_wegbauten_" + schluessel, anzeige, zeichnen)


## Die Netze eines Abschnitts (`zeichnen.call(sa)` füllt einen Sammler)
## aus dem Bauspeicher (`schluessel`) oder neu gebaut, eingehängt unter
## `eltern`/<anzeige> – je Stoff ein Netz mit Sichtweite, ohne Schatten.
## WARUM der Bauspeicher: Gebaut kosten die fünf Abschnitte von Level 05
## samt Durchlässen rund 0,3 s je Laden (Bauzeitprobe, Runde 2 im selben
## Prozess: 493 statt 207 ms vor P5; Entwurf §9.4: Runde 2 ≤ 0,3 s). Die
## Netze hängen nur an den Daten des Levels und am Code – den deckt die
## Fassung des Speichers ab; die Körper entstehen in jedem Fall neu.
static func abschnitt(eltern: Node3D, schluessel: String, anzeige: String,
		zeichnen: Callable) -> Node3D:
	var netze: Dictionary = Bauspeicher.wert(schluessel, func() -> Variant:
		var sa := Sammler.new()
		zeichnen.call(sa)
		return sa.netze())
	var wurzel := Node3D.new()
	wurzel.name = anzeige
	eltern.add_child(wurzel)
	if netze.has("Holz"):
		_anhaengen(wurzel, "Holz", netze["Holz"] as Mesh, Riesenstamm.borkenstoff(), _sicht())
	if netze.has("Stein"):
		_anhaengen(wurzel, "Stein", netze["Stein"] as Mesh, Findling.stoff(), _sicht())
	if netze.has("Kranz"):
		_anhaengen(wurzel, "Kranz", netze["Kranz"] as Mesh, Findling.kranzstoff(), SICHT_KRANZ)
	return wurzel


static func _sicht() -> float:
	return SICHT_HANDY if Effekte.reduziert else SICHT


static func _anhaengen(eltern: Node3D, name: String, netz: Mesh, stoff: Material,
		sicht: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if sicht > 0.0:
		mi.visibility_range_end = sicht
		mi.visibility_range_end_margin = SICHT_RAND
	eltern.add_child(mi)
	return mi


static func _wurzel(level: Level05) -> Node3D:
	var knoten := level.geometrie.get_node_or_null("Wegbauten") as Node3D
	if knoten == null:
		knoten = Node3D.new()
		knoten.name = "Wegbauten"
		level.geometrie.add_child(knoten)
	return knoten


# ================================================================ Abschnitte

## A · Suhle: das Wildgatter Ü, die Grabenrampe, das Wurzelknie G1.
static func _abschnitt_a(level: Level05) -> void:
	level.durchlass_koerper.clear()
	_durchlass(level, Level05.DURCHLAESSE[0])
	_abschnitt(level, "a", "A Suhle", func(sa: Sammler) -> void:
		_grabenrampe(sa, level)
		_wurzelknie(sa, level)
		_rastpfaehle(sa, level, -10.0, 31.5))


## B · Hohlweg: Wurzelbögen D1/D2, Wurzelhürden H1/H2, die Böschungsbank G2.
static func _abschnitt_b(level: Level05) -> void:
	_durchlass(level, Level05.DURCHLAESSE[1])
	_durchlass(level, Level05.DURCHLAESSE[2])
	for h: Dictionary in Level05.HUERDEN:
		huerde_koerper(level, float(h["s"]), String(h["name"]))
	var rand := _rand_l05(level)
	_abschnitt(level, "b", "B Hohlweg", func(sa: Sammler) -> void:
		for i in Level05.HUERDEN.size():
			huerde_netz(sa, level, float(Level05.HUERDEN[i]["s"]), rand, 5300 + i * 17)
		_bank(sa, level, "G2 Böschungsbank", LOESS_TON, 5341)
		_bankwurzeln(sa, level))


## C · Wurzelterrassen: die Wurzeln an den Setzstufen von S1–S3.
static func _abschnitt_c(level: Level05) -> void:
	var rand := _rand_l05(level)
	_abschnitt(level, "c", "C Terrassen", func(sa: Sammler) -> void:
		var nummer := 0
		for t: Dictionary in Level05.TERRASSEN:
			if not String(t["name"]).ends_with("Tritt"):
				continue
			stufenwurzel(sa, level, float(t["von"]), rand, 5400 + nummer * 7)
			stufenwurzel(sa, level, float(t["bis"]), rand, 5403 + nummer * 7)
			nummer += 1
		_rastpfaehle(sa, level, 120.0, 180.0))


## D · Tobel: Fluderjoche D3/D4, Findlingsgasse, Trittstein und Sims G3.
static func _abschnitt_d(level: Level05) -> void:
	_durchlass(level, Level05.DURCHLAESSE[3])
	_durchlass(level, Level05.DURCHLAESSE[4])
	for f: Dictionary in Level05.FINDLINGE:
		findling_koerper(level, float(f["s"]), float(f["q"]), float(f["breite"]),
				String(f["name"]))
	_abschnitt(level, "d", "D Tobel", func(sa: Sammler) -> void:
		for i in Level05.FINDLINGE.size():
			var f: Dictionary = Level05.FINDLINGE[i]
			findling_netz(sa, level, float(f["s"]), float(f["q"]), float(f["breite"]),
					5500 + i * 13)
		_bank(sa, level, "G3 Trittstein", SANDSTEIN_TON, 5531)
		_bank(sa, level, "G3 Sonnensims", SANDSTEIN_TON, 5537)
		_rastpfaehle(sa, level, 180.0, 265.0))


## E · Mühlbach: Pfähle und Bruchkanten des Wehrs, der Wegpfahl von CP5;
## dazu die Laternen ALLER Rastplätze in einem Netz ohne Sichtweite. Die
## Pfähle stehen im Netz ihres Abschnitts: Ein Netz über den ganzen Hang
## hätte die Mitte seiner Hülle bei s ≈ 150, und mit der Sichtweite (vom
## Abstand zu dieser Mitte) verschwände der Pfahl von CP5 im Schlussbild.
static func _abschnitt_e(level: Level05) -> void:
	_abschnitt(level, "e", "E Mühlbach", func(sa: Sammler) -> void:
		_wehr(sa, level)
		_rastpfaehle(sa, level, 265.0, 310.0))
	var laternen := Bauspeicher.netz("l05_laternen", [], func() -> ArrayMesh:
		var glut := Riesenstamm.bauer()
		for i in Level05.RASTPLAETZE.size():
			_laterne(glut, level, Level05.RASTPLAETZE[i], 5740 + i * 3)
		return Riesenstamm.fertig(glut))
	_anhaengen(_wurzel(level), "Laternen", laternen,
			Materialbibliothek.leuchtend(LATERNE, LATERNE_STAERKE), 0.0)


## Die Wegpfähle der Rastplätze mit `von` < s ≤ `bis`.
static func _rastpfaehle(sa: Sammler, level: Level05, von: float, bis: float) -> void:
	for i in Level05.RASTPLAETZE.size():
		var s: float = Level05.RASTPLAETZE[i]
		if s > von and s <= bis:
			_rastpfahl(sa, level, s, 5700 + i * 5)


# ================================================================ Holz

## Ein Holzstück (Wurzel, Stange, Riegel, Pfahl) entlang `punkte` im Raum
## von `lage` ins Borkennetz `st` (Scheitelformat `Riesenstamm`). Optionen:
##   seiten (8), saat (1), buckel (0,06), moos (0,3: COLOR.a), ton (Tönung
##   der Borke), ao (Vector2 Verdeckung am Anfang und Ende, (1, 1))
##   hoch       Höhe des Querschnitts relativ zum Radius (1), gemessen in
##              Richtung `bezug` (Vorgabe oben) quer zur Achse
##   oben, unten  Grenzen in y (Raum von `lage`): Ecken darüber bzw. darunter
##              liegen genau auf der Grenze und tragen `hell` (Eigenfarbe) –
##              der abgewetzte Rücken, die helle Unterkante
##   klemm_x    Vector2: die Grenzen gelten nur für Ecken mit x darin
##   hell       Eigenfarbe der geklemmten Ecken (ABGEWETZT)
##   oben_borke true: Ecken über `oben` bleiben Borke statt `hell` – ein
##              plattgedrückter Rücken ohne helles Band; ihr Moos kommt nur
##              aus dem Stoff (Moos auf Flächen nach oben, fleckig nach der
##              Moostextur), nicht zusätzlich aus `moos`: Mit beidem lag auf
##              jedem Rücken ein durchgehend grüner Streifen.
##   spalt      Richtung (Raum von `lage`) einer Spaltfläche; Ecken, die
##              weiter als spalt_tiefe · Radius von der Achse liegen,
##              liegen auf ihr, in `spalt_farbe` (GRAU)
##   anfang, ende  "offen" (Deckel aus Hirnholz), "spitz", "splitter"
##              (Zacken in `bruch_farbe`, Vorgabe FRISCH), "stumpf" (nichts)
static func _holz(st: SurfaceTool, lage: Transform3D, punkte: PackedVector3Array,
		radien: PackedFloat32Array, o: Dictionary = {}) -> void:
	var n := punkte.size()
	if n < 2:
		return
	var saat: int = o.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var seiten: int = o.get("seiten", 8)
	var buckel: float = o.get("buckel", 0.06)
	var moos: float = o.get("moos", 0.3)
	var ton: Color = o.get("ton", Color.WHITE)
	var ao: Vector2 = o.get("ao", Vector2.ONE)
	var hoch_f: float = o.get("hoch", 1.0)
	var bezug: Vector3 = o.get("bezug", Vector3.UP)
	var oben: float = o.get("oben", INF)
	var unten: float = o.get("unten", -INF)
	var klemm_x: Vector2 = o.get("klemm_x", Vector2(-INF, INF))
	var hell: Color = o.get("hell", ABGEWETZT)
	var oben_borke: bool = o.get("oben_borke", false)
	var spalt: Vector3 = o.get("spalt", Vector3.ZERO)
	var spalt_tiefe: float = o.get("spalt_tiefe", 0.25)
	var spalt_farbe: Color = o.get("spalt_farbe", GRAU)
	var anfang: String = o.get("anfang", "offen")
	var ende: String = o.get("ende", "offen")
	var bruch_farbe: Color = o.get("bruch_farbe", FRISCH)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 1.3

	var r_mittel := 0.0
	for r in radien:
		r_mittel += r
	r_mittel /= float(n)
	var kachel := Riesenstamm.borkenmass(r_mittel)
	var n_u := maxi(1, roundi(TAU * r_mittel * Riesenstamm.KACHEL_U * kachel))
	var drall := rng.randf() * TAU

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var bogen := 0.0
	var vorher_hoch := Vector3.ZERO
	for i in n:
		var t := (punkte[mini(i + 1, n - 1)] - punkte[maxi(i - 1, 0)]).normalized()
		var hoch := bezug - t * bezug.dot(t)
		if hoch.length() < 0.3:
			# Achse fast parallel zum Bezug: den Rahmen vom Ring davor
			# weitertragen (oder eine Querachse nehmen).
			hoch = vorher_hoch if vorher_hoch != Vector3.ZERO else Vector3.BACK
			hoch -= t * hoch.dot(t)
		hoch = hoch.normalized()
		vorher_hoch = hoch
		var quer := hoch.cross(t).normalized()
		if i > 0:
			bogen += punkte[i].distance_to(punkte[i - 1])
		var f := float(i) / float(n - 1)
		var ao_hier := lerpf(ao.x, ao.y, f)
		var r := radien[i]
		var sp := spalt - t * spalt.dot(t)
		var mit_spalt := spalt != Vector3.ZERO and sp.length() > 0.05
		if mit_spalt:
			sp = sp.normalized()
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in seiten + 1:
			var jj := j % seiten
			var w := TAU * float(jj) / float(seiten) + drall
			var dir := quer * cos(w) + hoch * sin(w) * hoch_f
			var rel := 1.0 + buckel * rauschen.get_noise_3d(dir.x * 1.5 + bogen * 0.8,
					dir.y * 1.5, dir.z * 1.5 + float(saat % 97))
			var p := punkte[i] + dir * r * rel
			var art := Riesenstamm.BORKE
			var ruecken := false
			var farbe := Color(ao_hier * ton.r, ao_hier * ton.g, ao_hier * ton.b, 0.0)
			if mit_spalt:
				var d := (p - punkte[i]).dot(sp)
				var grenze := r * spalt_tiefe
				if d > grenze:
					p -= sp * (d - grenze)
					art = Riesenstamm.EIGEN
					var riss := rauschen.get_noise_2d(float(jj) * 2.7, bogen * 1.9) > 0.35
					var g := spalt_farbe * ao_hier * rng.randf_range(0.9, 1.08) * (0.45 if riss else 1.0)
					farbe = Color(g.r, g.g, g.b, 0.0)
			if p.x >= klemm_x.x and p.x <= klemm_x.y:
				if p.y > oben:
					p.y = oben
					if not oben_borke:
						art = Riesenstamm.EIGEN
						var g := hell * rng.randf_range(0.92, 1.06)
						farbe = Color(g.r, g.g, g.b, 0.0)
					else:
						ruecken = true
				elif p.y < unten:
					p.y = unten
					art = Riesenstamm.EIGEN
					var g := hell * rng.randf_range(0.85, 1.0)
					farbe = Color(g.r, g.g, g.b, 0.0)
			if art == Riesenstamm.BORKE and not ruecken:
				var m := moos * (0.4 + 0.6 * rauschen.get_noise_3d(p.x * 4.0 + bogen, p.y * 4.0,
						p.z * 4.0))
				farbe.a = clampf(m, 0.0, 1.0)
			zeile.append(p)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u),
					bogen * Riesenstamm.KACHEL_V * kachel * 2.0))
			fa.append(farbe)
			ar.append(Vector2(art, 0.25))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)

	_ende_formen(zeilen, farben, arten, n - 1, n - 2, ende, rng, radien[n - 1], bruch_farbe)
	_ende_formen(zeilen, farben, arten, 0, 1, anfang, rng, radien[0], bruch_farbe)
	var welt: Array[PackedVector3Array] = []
	for zeile in zeilen:
		welt.append(lage * zeile)
	Riesenstamm.gitter(st, welt, uvs, farben, arten, true)
	if ende == "offen" or ende == "splitter":
		_deckel(st, welt[n - 1], welt[n - 2], HIRN if ende == "offen" else bruch_farbe)
	if anfang == "offen" or anfang == "splitter":
		_deckel(st, welt[0], welt[1], HIRN if anfang == "offen" else bruch_farbe)


## Verformt einen Endring: Spitze (ein Punkt) oder Zacken (gesplittert, in
## der Farbe frischen Holzes).
static func _ende_formen(zeilen: Array[PackedVector3Array], farben: Array[PackedColorArray],
		arten: Array[PackedVector2Array], i: int, nachbar: int, art: String,
		rng: RandomNumberGenerator, r: float, bruch_farbe: Color) -> void:
	if art != "spitz" and art != "splitter":
		return
	var zeile := zeilen[i]
	var mitte := _mitte(zeile)
	var aussen := (mitte - _mitte(zeilen[nachbar])).normalized()
	var fa := farben[i]
	var ar := arten[i]
	for k in zeile.size():
		if art == "spitz":
			zeile[k] = mitte + aussen * r * 0.6
		else:
			var zacke := Riesenstamm.randf_hash(k % (zeile.size() - 1), i + rng.randi_range(0, 3))
			var p := zeile[k] + aussen * r * (0.3 + 2.4 * zacke * zacke * zacke)
			zeile[k] = mitte.lerp(p, lerpf(1.0, 0.65, zacke)) + aussen * r * 0.3 * zacke
			var g := bruch_farbe * rng.randf_range(0.85, 1.1)
			fa[k] = Color(g.r, g.g, g.b, 0.0)
			ar[k] = Vector2(Riesenstamm.EIGEN, 0.0)
	zeilen[i] = zeile
	farben[i] = fa
	arten[i] = ar


static func _mitte(zeile: PackedVector3Array) -> Vector3:
	var summe := Vector3.ZERO
	for k in zeile.size() - 1:
		summe += zeile[k]
	return summe / float(maxi(zeile.size() - 1, 1))


## Deckel über einem Endring, nicht über die Zacken hinaus (wie
## `Totholzzaun`): Hirnholz bzw. frische Bruchfläche, zur Mitte dunkler.
static func _deckel(st: SurfaceTool, rand: PackedVector3Array, nachbar: PackedVector3Array,
		farbe: Color) -> void:
	var mitte := _mitte(rand)
	var aussen := (mitte - _mitte(nachbar)).normalized()
	var tiefst := INF
	for k in rand.size() - 1:
		tiefst = minf(tiefst, (rand[k] - mitte).dot(aussen))
	mitte += aussen * tiefst
	for k in rand.size() - 1:
		Totholzzaun.dreieck(st, mitte, rand[k], rand[k + 1], aussen, farbe * 0.6, farbe, farbe)


## Punktzug durch Stützpunkte (Catmull-Rom), `je` Punkte je Abschnitt.
static func _glatt(stuetzen: PackedVector3Array, je: int = 4) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var n := stuetzen.size()
	if n < 3:
		return stuetzen
	for i in n - 1:
		var p0 := stuetzen[maxi(i - 1, 0)]
		var p1 := stuetzen[i]
		var p2 := stuetzen[i + 1]
		var p3 := stuetzen[mini(i + 2, n - 1)]
		for k in je:
			var t := float(k) / float(je)
			var t2 := t * t
			var t3 := t2 * t
			aus.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	aus.append(stuetzen[n - 1])
	return aus


## Radien längs eines Punktzugs: linear durch die Stützwerte (gleich verteilt).
static func _radien(anzahl: int, stuetzen: PackedFloat32Array) -> PackedFloat32Array:
	var aus := PackedFloat32Array()
	for i in anzahl:
		var f := float(i) / float(maxi(anzahl - 1, 1)) * float(stuetzen.size() - 1)
		var k := mini(floori(f), stuetzen.size() - 2)
		aus.append(lerpf(stuetzen[k], stuetzen[k + 1], f - float(k)))
	return aus


## Ein gerades Stück (Stange, Pfosten) von `a` nach `b`, in Stücken von
## höchstens `stueck` Metern (sonst knickt die Borke nicht mit).
static func _stange(st: SurfaceTool, lage: Transform3D, a: Vector3, b: Vector3, r0: float,
		r1: float, o: Dictionary = {}, stueck: float = 0.8) -> void:
	var anzahl := maxi(ceili(a.distance_to(b) / stueck), 1)
	var punkte := PackedVector3Array()
	var radien := PackedFloat32Array()
	for i in anzahl + 1:
		var t := float(i) / float(anzahl)
		punkte.append(a.lerp(b, t))
		radien.append(lerpf(r0, r1, t))
	_holz(st, lage, punkte, radien, o)


# ================================================================ Lage

## Welttransform an (s, q, h über der Decke): X quer nach rechts, Y hoch,
## −Z den Weg entlang.
static func _lage(level: KorridorLevel, s: float, q: float = 0.0, h: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s)),
			level.weg_punkt(s, q, h))


## Gescherter Rahmen eines Hindernisses mit Mitte `s` und Tiefe `tiefe`
## (Körper aus Querschnitten, `KorridorLevel._hindernis_schnitte`): X quer,
## Y senkrecht, Z von der Mitte der Hinterkante zur Mitte der Vorderkante –
## mit dem Gefälle. So bleiben die Seiten senkrecht wie die des Körpers, und
## die Oberseite folgt der Decke wie seine. Lokal z ∈ [−tiefe/2, tiefe/2],
## y = Höhe über der Decke.
static func _scher_lage(level: KorridorLevel, s: float, q: float, tiefe: float) -> Transform3D:
	var vorn := level.weg_punkt(s - tiefe * 0.5, q)
	var hinten := level.weg_punkt(s + tiefe * 0.5, q)
	var z := (vorn - hinten) / tiefe
	var x := Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s)).x
	return Transform3D(Basis(x, Vector3.UP, z), (vorn + hinten) * 0.5)


## Leitlinie an `s` als Abstand von der Mitte (positiv) auf der Seite.
static func _leitlinie(seite: float, s: float) -> float:
	return absf(Level05.leitlinie_q(Level05.leitlinie_punkte(seite), s))


## Krone der Böschung „auf" auf einer Seite an `s`: Vector2(Abstand der
## Wandkrone von der Mitte, Höhe der Krone über der Decke). Ohne Böschung
## dort (Ufer) Vector2(Leitlinie, 0).
static func _krone(level: Level05, seite: float, s: float) -> Vector2:
	for zug in level.zuege_bei(seite, s):
		if String(zug["art"]) == "auf":
			var f := L05Saum.form_auf(level, zug, s)
			return Vector2(_leitlinie(seite, s) + float(f["lauf"]), float(f["hoch"]))
	return Vector2(_leitlinie(seite, s), 0.0)


# ================================================================ Durchlässe

## Körper, Optik und Bruch eines Durchlasses von Level 05 (Entwurf §1
## Nr. 2/3); der Körper kommt in `level.durchlass_koerper` (für `L05Jagd`).
static func _durchlass(level: Level05, d: Dictionary) -> void:
	level.durchlass_koerper.append(durchlass(level, d, _rand_l05(level), "l05_durchlass"))


## Ein Durchlass in einem beliebigen Korridorlevel: `d` wie DURCHLAESSE
## ({"name", "s" = Stirn, "tiefe"}; die Bauart steht im Namen, `art`),
## `rand` sagt, wo Leitlinien und Kronen stehen, `speicher` ist die Art im
## Bauspeicher (`Bauspeicher.netz`, Argumente Name und heil/gebrochen –
## je Level ein eigener Name). Rückgabe: der Körper aus
## `KorridorLevel.duckdurchlass` mit Stolperzone (L05Jagd.STOLPER_DAUER),
## darin die heile Optik („Optik") und der verborgene Bruch („Bruch",
## `Effekte.VORWAERM_GRUPPE`); umschalten mit `bruch_stellen`.
static func durchlass(level: KorridorLevel, d: Dictionary, rand: Rand,
		speicher: String) -> StaticBody3D:
	var s: float = d["s"]
	var tiefe: float = d["tiefe"]
	var bauart := art(d)
	var optik := func(_s: float, _t: float) -> Node3D:
		return _durchlass_netz(level, d, false, rand, speicher)
	var koerper := level.duckdurchlass(s, tiefe, {"stolperzone": L05Jagd.STOLPER_DAUER,
			"optik": optik})
	koerper.name = String(d["name"])
	koerper.set_meta("art", bauart)
	if bauart == "joch":
		# Woher das Wasser schwappt (Keiler.durchbrechen): Mitte des Gerinnes.
		koerper.set_meta("gerinne", GERINNE_RAND - GERINNE_R * 0.5)
	var bruch := _durchlass_netz(level, d, true, rand, speicher)
	bruch.name = "Bruch"
	bruch.visible = false
	bruch.add_to_group(Effekte.VORWAERM_GRUPPE)
	koerper.add_child(bruch)
	return koerper


## Einen Durchlass (Körper aus `durchlass`) heil oder gebrochen stellen:
## gebrochen sind Körper und Stolperzone aus, die heile Optik verborgen und
## der Bruch sichtbar – heil umgekehrt. Aufgeschoben, weil es mitten im
## Physikschritt geschehen darf (L05Jagd, Durchlass-Bruch und Heilen).
static func bruch_stellen(koerper: StaticBody3D, gebrochen: bool) -> void:
	for kind in koerper.get_children():
		if kind is CollisionShape3D:
			kind.set_deferred("disabled", gebrochen)
		elif kind is Area3D:
			kind.set_deferred("monitoring", not gebrochen)
		elif kind is Node3D:
			(kind as Node3D).visible = gebrochen if kind.name == &"Bruch" else not gebrochen


## Bauart nach dem Namen: Gatter (Ü), Wurzelbogen (D1, D2), Fluderjoch.
## Öffentlich: `L05Wasser` legt Wasser in die Gerinne der Joche.
## Ohne Rücksicht auf Groß- und Kleinschreibung: „Ü Wildgatter" enthält
## „gatter" klein – mit `contains("Gatter")` wurde Ü bis P5 als Fluderjoch
## gebaut, samt Gerinne und Wasserschwall.
static func art(d: Dictionary) -> String:
	var name := String(d["name"])
	if name.containsn("gatter"):
		return "gatter"
	if name.containsn("wurzelbogen"):
		return "bogen"
	return "joch"


## Ein Netz eines Durchlasses im Raum seiner Mitte (`_lage` bei s + tiefe/2):
## Die Stirn liegt bei z = +tiefe/2, der Ausgang bei −tiefe/2.
static func _durchlass_netz(level: KorridorLevel, d: Dictionary, kaputt: bool, rand: Rand,
		speicher: String) -> MeshInstance3D:
	var s: float = d["s"]
	var tiefe: float = d["tiefe"]
	var mitte := s + tiefe * 0.5
	var lage := _lage(level, mitte)
	var netz := Bauspeicher.netz(speicher, [String(d["name"]), kaputt], func() -> ArrayMesh:
		var st := Riesenstamm.bauer()
		var saat := int(s * 10.0) + (500 if kaputt else 0)
		match art(d):
			"gatter":
				_gatter(st, rand, mitte, tiefe, kaputt, saat)
			"bogen":
				_wurzelbogen(st, rand, mitte, tiefe, kaputt, saat)
			_:
				_fluderjoch(st, rand, mitte, tiefe, kaputt, saat)
		return Riesenstamm.fertig(st))
	var mi := MeshInstance3D.new()
	mi.name = "Optik"
	mi.mesh = netz
	mi.material_override = Riesenstamm.borkenstoff()
	mi.transform = lage
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = _sicht()
	mi.visibility_range_end_margin = SICHT_RAND
	return mi


## Durchhang eines gebrochenen Stücks, das bei `fest` (x) noch hält und bei
## `lose` gebrochen ist: 0 am festen Ende, `tief` am losen.
static func _durchhang(x: float, fest: float, lose: float, tief: float) -> float:
	var t := clampf((x - fest) / (lose - fest), 0.0, 1.0)
	return tief * t * t


## Ein Riegel quer über den Durchlass von x `von` bis `bis` auf der Tiefe
## `z`, Achse auf der Mitte zwischen DUCK_UNTEN und RIEGEL_OBEN, geklemmt
## über [−klemm, klemm]. `kaputt`: in zwei Stücken, die von den Enden her
## durchhängen und in der Bresche gesplittert enden. `o` wie `_holz`.
static func _riegel(st: SurfaceTool, von: float, bis: float, z: float, r: float, klemm: float,
		kaputt: bool, bruch: Vector2, durchhang: Vector2, o: Dictionary, welle: float = 0.03) -> void:
	var y := (KorridorLevel.DUCK_UNTEN + RIEGEL_OBEN) * 0.5
	var oo := o.duplicate()
	oo["oben"] = RIEGEL_OBEN
	oo["unten"] = KorridorLevel.DUCK_UNTEN
	oo["klemm_x"] = Vector2(-klemm, klemm)
	var saat: int = o.get("saat", 1)
	if not kaputt:
		var punkte := PackedVector3Array()
		var x := von
		while x < bis + 0.001:
			punkte.append(Vector3(x, y, z + welle * sin(x * 0.9 + float(saat))))
			x += 0.6
		if punkte[punkte.size() - 1].x < bis - 0.05:
			punkte.append(Vector3(bis, y, z))
		_holz(st, Transform3D.IDENTITY, punkte, _radien(punkte.size(),
				PackedFloat32Array([r, r * 0.97, r])), oo)
		return
	# Gebrochen: links bis bruch.x, rechts ab bruch.y; die losen Enden hängen.
	for teil in 2:
		var fest := von if teil == 0 else bis
		var lose := bruch.x if teil == 0 else bruch.y
		var tief := durchhang.x if teil == 0 else durchhang.y
		var punkte := PackedVector3Array()
		var anzahl := maxi(ceili(absf(lose - fest) / 0.5), 2)
		for i in anzahl + 1:
			var x := lerpf(fest, lose, float(i) / float(anzahl))
			punkte.append(Vector3(x, y - _durchhang(x, fest, lose, tief),
					z + welle * sin(x * 0.9 + float(saat))))
		var ot := oo.duplicate()
		ot["ende"] = "splitter"
		ot["saat"] = saat + teil * 3
		ot["unten"] = -INF
		_holz(st, Transform3D.IDENTITY, punkte, _radien(punkte.size(),
				PackedFloat32Array([r, r * 0.96])), ot)


## Stücke, die beim Bruch auf den Boden gefallen sind: liegend, flacher als
## 0,3 m, quer verstreut um die Bresche.
static func _truemmer(st: SurfaceTool, rng: RandomNumberGenerator, halb_z: float, anzahl: int,
		r: Vector2, laenge: Vector2, o: Dictionary) -> void:
	for i in anzahl:
		var x := rng.randf_range(-BRESCHE - 1.2, BRESCHE + 1.2)
		var z := rng.randf_range(-halb_z - 0.6, halb_z + 0.6)
		var w := rng.randf() * TAU
		var l := rng.randf_range(laenge.x, laenge.y)
		var rr := rng.randf_range(r.x, r.y)
		var richtung := Vector3(cos(w), 0.0, sin(w))
		var a := Vector3(x, rr * 0.8, z) - richtung * l * 0.5
		var b := Vector3(x, rr * 0.8 + rng.randf_range(-0.04, 0.06), z) + richtung * l * 0.5
		var ot := o.duplicate()
		ot["saat"] = int(o.get("saat", 1)) + 40 + i
		ot["anfang"] = "splitter"
		ot["ende"] = "splitter"
		_stange(st, Transform3D.IDENTITY, a, b, rr, rr * 0.9, ot)


## Ü Wildgatter (siehe Kopf).
static func _gatter(st: SurfaceTool, rand: Rand, mitte: float, tiefe: float, kaputt: bool,
		saat: int) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var links := rand.leitlinie(-1.0, mitte)
	var rechts := rand.leitlinie(1.0, mitte)
	var px := Vector2(-(links + 0.17), rechts + 0.17)
	var zr := tiefe * 0.5 - 0.28
	var holz := {"ton": PFAHL_TON, "moos": 0.35, "seiten": 8}
	# Pfosten: hinter den Leitlinien, oben gekerbt (spitz).
	for x: float in [px.x, px.y]:
		for z: float in [zr, -zr]:
			var o := holz.duplicate()
			o["saat"] = saat + int(x * 3.0 + z * 7.0)
			o["ende"] = "spitz"
			o["anfang"] = "stumpf"
			_stange(st, Transform3D.IDENTITY, Vector3(x, -0.6, z),
					Vector3(x + rng.randf_range(-0.04, 0.04), 4.72, z), 0.17, 0.14, o)
		# Querholz oben über die Tiefe
		var oq := holz.duplicate()
		oq["saat"] = saat + int(x * 5.0)
		_stange(st, Transform3D.IDENTITY, Vector3(x, 4.48, zr + 0.3), Vector3(x, 4.46, -zr - 0.3),
				0.09, 0.085, oq)
	# Riegel: Spaltholz, die Spaltfläche nach außen (zur Kamera am Ausgang).
	for k in 2:
		var z := zr if k == 0 else -zr
		var o := holz.duplicate()
		o["saat"] = saat + 11 + k
		o["spalt"] = Vector3(0.0, 0.0, signf(z))
		o["moos"] = 0.45
		o["hoch"] = RIEGEL_HOCH / 0.28
		_riegel(st, px.x - 0.12, px.y + 0.12, z, 0.28, maxf(links, rechts) + 0.25, kaputt,
				Vector2(-BRESCHE + rng.randf_range(-0.2, 0.1), BRESCHE - rng.randf_range(0.0, 0.3)),
				Vector2(rng.randf_range(0.38, 0.5), rng.randf_range(0.32, 0.45)), o)
		# Kopfstange
		var ok := holz.duplicate()
		ok["saat"] = saat + 21 + k
		ok["ende"] = "stumpf"
		ok["anfang"] = "stumpf"
		_stange(st, Transform3D.IDENTITY, Vector3(px.x - 0.1, GATTER_KOPF, z),
				Vector3(px.y + 0.1, GATTER_KOPF + 0.02, z), GATTER_KOPF_R, GATTER_KOPF_R * 0.92, ok,
				1.2)
	# Stangen alle 0,5 m in beiden Ebenen, auf gleicher Höhe quer (so liegen
	# sie im Rückblick hintereinander und lassen die Lücken offen), Ø 6–7 cm:
	# Mit 8–10 cm war die Figur dahinter aus der Kamera nur in 12 von 42
	# Stellungen frei.
	var x := -links + 0.3
	var nr := 0
	while x < rechts - 0.25:
		for k in 2:
			# Vorn (an der Stirn, weg von der Kamera) nur jede zweite: Aus der
			# Kamera über dem Weg liegen die Ebenen nicht deckungsgleich, und
			# doppelt so viele Striche lasen sich als dichtes Gitter.
			if k == 0 and nr % 2 == 1:
				continue
			var z := zr if k == 0 else -zr
			var o := holz.duplicate()
			o["saat"] = saat + 100 + nr * 2 + k
			o["seiten"] = 6
			o["moos"] = 0.2
			o["anfang"] = "stumpf"
			o["ende"] = "stumpf"
			var r := rng.randf_range(0.03, 0.036)
			var kipp := rng.randf_range(-0.015, 0.015)
			var unten := RIEGEL_OBEN - 0.1
			var oben := GATTER_KOPF
			if not kaputt:
				_stange(st, Transform3D.IDENTITY, Vector3(x, unten, z), Vector3(x + kipp, oben, z),
						r, r * 0.85, o, 1.0)
			elif absf(x) < BRESCHE + 0.9:
				# Gebrochen: Stümpfe hängen von der Kopfstange.
				var o2 := o.duplicate()
				o2["anfang"] = "splitter"
				var bis_y := oben - rng.randf_range(0.4, 1.4)
				_stange(st, Transform3D.IDENTITY, Vector3(x + kipp * 2.0, bis_y, z + rng.randf_range(-0.06, 0.06)),
						Vector3(x + kipp, oben, z), r * 0.9, r * 0.85, o2, 1.0)
			else:
				# Am Rand der Bresche folgt die Stange dem durchhängenden Riegel.
				var fest := px.x if x < 0.0 else px.y
				var lose := -BRESCHE if x < 0.0 else BRESCHE
				var sack := _durchhang(x, fest, lose, 0.42)
				_stange(st, Transform3D.IDENTITY, Vector3(x, unten - sack, z), Vector3(x + kipp, oben, z),
						r, r * 0.85, o, 1.0)
		x += 0.5
		nr += 1
	if kaputt:
		_truemmer(st, rng, zr, 3, Vector2(0.1, 0.13), Vector2(0.5, 1.0), holz)
		_truemmer(st, rng, zr, 5, Vector2(0.04, 0.05), Vector2(0.4, 0.9), holz)


## D1/D2 Wurzelbogen (siehe Kopf).
static func _wurzelbogen(st: SurfaceTool, rand: Rand, mitte: float, tiefe: float,
		kaputt: bool, saat: int) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var links := rand.leitlinie(-1.0, mitte)
	var rechts := rand.leitlinie(1.0, mitte)
	var krone_l := rand.krone(-1.0, mitte)
	var krone_r := rand.krone(1.0, mitte)
	var wurzel := {"ton": WURZEL_TON, "moos": 0.5, "seiten": 9, "buckel": 0.09}
	var y := (KorridorLevel.DUCK_UNTEN + RIEGEL_OBEN) * 0.5
	# Riegel: drei Wurzeln über die Tiefe, die aus der Wand kommen und in die
	# andere Wand tauchen; über dem Weg flach auf 0,95–1,40. Die äußeren
	# liegen so weit innen, dass Achse, Welle (3 cm) und Halbmesser samt
	# Buckeln (0,31 · 1,1) in ±tiefe/2 bleiben – mit Welle 0,12 standen sie
	# bis 16 cm vor der Stirn bzw. hinter dem Ausgang, Optik ohne Körper.
	# Flach auf DUCK_UNTEN schon ab 0,1 m vor der Leitlinie: Stieg die
	# Wurzel erst dort zur Wand, lag ihre Unterkante am Rand bis 4 cm über
	# dem Körper. Der Rücken bleibt Borke mit Moos (`oben_borke`): Hell
	# abgewetzt lasen sich die drei Rücken von oben (s 90) als Bretterboden,
	# heller als der Weg; hell bleibt nur die Unterkante (§8.4).
	var halb_z := tiefe * 0.5
	var r_riegel := 0.31
	var welle := 0.03
	for k in 3:
		var zc := lerpf(halb_z - r_riegel * 1.1 - welle, -(halb_z - r_riegel * 1.1 - welle),
				float(k) / 2.0)
		var o := wurzel.duplicate()
		o["saat"] = saat + k * 5
		o["hoch"] = RIEGEL_HOCH / 0.29
		o["oben"] = RIEGEL_OBEN
		o["unten"] = KorridorLevel.DUCK_UNTEN
		o["klemm_x"] = Vector2(-links - 0.25, rechts + 0.25)
		o["oben_borke"] = true
		o["anfang"] = "spitz"
		o["ende"] = "spitz"
		var phase := float(k) * 2.1
		var stuetzen := PackedVector3Array([Vector3(-links - 1.6, 2.3, zc - 0.2),
				Vector3(-links - 0.75, 1.35, zc), Vector3(-links - 0.1, y, zc)])
		var x := -links + 1.0
		while x < rechts - 0.7:
			stuetzen.append(Vector3(x, y, zc + welle * sin(x * 0.8 + phase)))
			x += 1.3
		stuetzen.append_array([Vector3(rechts + 0.1, y, zc), Vector3(rechts + 0.75, 1.4, zc),
				Vector3(rechts + 1.6, 2.4, zc + 0.2)])
		var linie := _glatt(stuetzen, 3)
		var radien := _radien(linie.size(), PackedFloat32Array([0.2, r_riegel, 0.3, 0.29, 0.3,
				r_riegel, 0.2]))
		if not kaputt:
			_holz(st, Transform3D.IDENTITY, linie, radien, o)
		else:
			# Gerissen: zwei Stücke, die losen Enden hängen in die Bresche.
			var riss := Vector2(-0.4 - 0.45 * float(k) + rng.randf_range(-0.2, 0.2),
					0.5 + 0.35 * float(2 - k) + rng.randf_range(-0.2, 0.2))
			for teil in 2:
				var punkte := PackedVector3Array()
				var rr := PackedFloat32Array()
				var tief := rng.randf_range(0.35, 0.55)
				var fest := -links if teil == 0 else rechts
				var lose := riss.x if teil == 0 else riss.y
				for i in linie.size():
					var p := linie[i]
					if (teil == 0 and p.x > lose) or (teil == 1 and p.x < lose):
						continue
					p.y -= _durchhang(p.x, fest, lose, tief)
					punkte.append(p)
					rr.append(radien[i])
				if teil == 1:
					punkte.reverse()
					rr.reverse()
				var ot := o.duplicate()
				ot["ende"] = "splitter"
				ot["unten"] = -INF
				ot["saat"] = saat + k * 5 + teil
				_holz(st, Transform3D.IDENTITY, punkte, rr, ot)
	# Bogen: zwei Wurzeln von Krone zu Krone, umeinander geflochten.
	# Über |q| ≤ BOGEN_FLACH bleibt er unter BOGEN_SCHEITEL (K1: über 3,5 m
	# Querlage nichts über 4,6 m); erst dahinter steigt bzw. fällt er zu den
	# Kronen (rechts bis 4,7 m).
	var bogen_stuetzen := PackedVector3Array([
		Vector3(-krone_l.x - 0.9, krone_l.y - 0.35, 0.0),
		Vector3(-krone_l.x + 0.1, krone_l.y + 0.12, 0.0),
		Vector3(-BOGEN_FLACH, BOGEN_SCHEITEL - 0.08, 0.0),
		Vector3(0.0, BOGEN_SCHEITEL, 0.0),
		Vector3(BOGEN_FLACH, BOGEN_SCHEITEL - 0.08, 0.0),
		Vector3(krone_r.x - 0.1, krone_r.y + 0.12, 0.0),
		Vector3(krone_r.x + 0.9, krone_r.y - 0.35, 0.0)])
	var bogen := _glatt(bogen_stuetzen, 5)
	for k in 2:
		var punkte := PackedVector3Array()
		for p in bogen:
			punkte.append(p + Vector3(0.0, 0.05 * sin(p.x * 1.1 + float(k) * PI),
					0.26 * cos(p.x * 1.1 + float(k) * PI)))
		var o := wurzel.duplicate()
		o["saat"] = saat + 30 + k
		o["anfang"] = "spitz"
		o["ende"] = "spitz"
		o["moos"] = 0.6
		_holz(st, Transform3D.IDENTITY, punkte, _radien(punkte.size(),
				PackedFloat32Array([0.12, 0.24, BOGEN_R, BOGEN_R * 0.9, BOGEN_R, 0.24, 0.12])), o)
	# Vorhang: Strähnen alle 0,3 m vom Bogen hinab bis knapp über den Riegel,
	# Ø 5–7 cm (mit 7–10 cm verdeckte bei s 90 eine Strähne die Figur fast).
	var x := -links + 0.35
	var nr := 0
	while x < rechts - 0.3:
		var seite := 1.0 if nr % 2 == 0 else -1.0
		var z := 0.18 * seite + rng.randf_range(-0.06, 0.06)
		var oben := _bogen_y(bogen, x) - 0.06
		var lang := rng.randf() < 0.72
		var unten := RIEGEL_OBEN + rng.randf_range(0.02, 0.3) if lang \
				else rng.randf_range(2.0, 3.2)
		if kaputt and absf(x) < BRESCHE + 0.7:
			unten = oben - rng.randf_range(0.3, 1.2)
		elif kaputt and absf(x) < BRESCHE + 1.6:
			unten = maxf(unten, 1.65 + rng.randf_range(0.0, 0.3))
		var punkte := PackedVector3Array()
		var schwung := rng.randf() * TAU
		for i in 6:
			var t := float(i) / 5.0
			punkte.append(Vector3(x + 0.05 * sin(t * 4.0 + schwung), lerpf(oben, unten, t),
					z + 0.05 * cos(t * 3.0 + schwung)))
		var o := {"ton": STRAEHNE_TON, "moos": 0.1, "seiten": 5, "buckel": 0.12,
				"saat": saat + 60 + nr, "anfang": "stumpf",
				"ende": "splitter" if kaputt and absf(x) < BRESCHE + 0.7 else "spitz"}
		var r := rng.randf_range(0.026, 0.036)
		_holz(st, Transform3D.IDENTITY, punkte, PackedFloat32Array([r, r * 0.9, r * 0.75,
				r * 0.6, r * 0.45, r * 0.3]), o)
		x += 0.3
		nr += 1
	if kaputt:
		_truemmer(st, rng, halb_z, 2, Vector2(0.12, 0.15), Vector2(0.6, 1.0), wurzel)
		_truemmer(st, rng, halb_z, 4, Vector2(0.03, 0.04), Vector2(0.5, 1.1),
				{"ton": STRAEHNE_TON, "moos": 0.1, "seiten": 5})


## Höhe des Bogens (Achse) bei x, linear zwischen seinen Punkten.
static func _bogen_y(bogen: PackedVector3Array, x: float) -> float:
	for i in bogen.size() - 1:
		var a := bogen[i]
		var b := bogen[i + 1]
		if (x >= a.x and x <= b.x) or (x <= a.x and x >= b.x):
			return lerpf(a.y, b.y, inverse_lerp(a.x, b.x, x))
	return bogen[0].y


## D3/D4 Fluderjoch (siehe Kopf).
static func _fluderjoch(st: SurfaceTool, rand: Rand, mitte: float, tiefe: float,
		kaputt: bool, saat: int) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var links := rand.leitlinie(-1.0, mitte)
	var rechts := rand.leitlinie(1.0, mitte)
	var holz := {"ton": PFAHL_TON, "moos": 0.3, "seiten": 8}
	var halb_z := tiefe * 0.5
	var zp := halb_z - 0.18
	var zz := halb_z - 0.09
	var bock_x := Vector2(-(links + 0.55), rechts + 0.24)
	var holm_y := GERINNE_RAND - GERINNE_R - 0.1
	# Böcke: links auf der Uferkante (die Pfosten stehen tief im Hang),
	# rechts dicht an der Sandsteinwand, nach außen gelehnt wie sie.
	for b in 2:
		var x := bock_x.x if b == 0 else bock_x.y
		var lehnen := 0.0 if b == 0 else 0.42
		var fuss_y := -2.4 if b == 0 else -0.5
		for z: float in [zp, -zp]:
			var o := holz.duplicate()
			o["saat"] = saat + b * 7 + int(z * 10.0)
			o["anfang"] = "stumpf"
			o["ende"] = "stumpf"
			_stange(st, Transform3D.IDENTITY, Vector3(x, fuss_y, z),
					Vector3(x + lehnen, holm_y + 0.05, z), 0.14, 0.12, o)
		var oh := holz.duplicate()
		oh["saat"] = saat + 30 + b
		_stange(st, Transform3D.IDENTITY, Vector3(x + lehnen, holm_y, zp + 0.3),
				Vector3(x + lehnen, holm_y, -zp - 0.3), 0.11, 0.11, oh)
		# Kreuzstreben in der Ebene des Bocks
		for k in 2:
			var a := Vector3(x + lehnen * 0.1, 0.25, zp if k == 0 else -zp)
			var e := Vector3(x + lehnen * 0.9, holm_y - 0.35, -zp if k == 0 else zp)
			var os := holz.duplicate()
			os["saat"] = saat + 40 + b * 2 + k
			os["seiten"] = 6
			_stange(st, Transform3D.IDENTITY, a, e, 0.06, 0.055, os)
	# Zangen: Halbhölzer vorn und hinten, die Spaltfläche nach außen.
	var klemm := maxf(links, rechts) + 0.25
	for k in 2:
		var z := zz if k == 0 else -zz
		var o := holz.duplicate()
		o["saat"] = saat + 50 + k
		o["spalt"] = Vector3(0.0, 0.0, signf(z))
		o["spalt_tiefe"] = 0.3
		o["hoch"] = RIEGEL_HOCH / 0.27
		_riegel(st, bock_x.x - 0.35, bock_x.y + 0.3, z - signf(z) * 0.1, 0.27, klemm, kaputt,
				Vector2(-BRESCHE * 0.6 + rng.randf_range(-0.3, 0.2), BRESCHE * 0.5
				+ rng.randf_range(-0.2, 0.3)), Vector2(rng.randf_range(0.35, 0.5),
				rng.randf_range(0.3, 0.45)), o, 0.0)
	# Latten alle 0,42 m in beiden Ebenen, gespalten, die Fläche nach außen.
	var gerinne_unten := GERINNE_RAND - GERINNE_R
	var x := -links + 0.3
	var nr := 0
	while x < rechts - 0.25:
		for k in 2:
			var z := (zz - 0.04) if k == 0 else -(zz - 0.04)
			var o := holz.duplicate()
			o["saat"] = saat + 100 + nr * 2 + k
			o["seiten"] = 6
			o["moos"] = 0.15
			o["spalt"] = Vector3(0.0, 0.0, signf(z))
			o["spalt_tiefe"] = 0.2
			o["anfang"] = "stumpf"
			o["ende"] = "stumpf"
			var r := rng.randf_range(0.058, 0.066)
			var unten := RIEGEL_OBEN - 0.08
			var oben := gerinne_unten + 0.12
			if not kaputt:
				_stange(st, Transform3D.IDENTITY, Vector3(x, unten, z), Vector3(x, oben, z), r, r,
						o, 1.0)
			elif absf(x) < BRESCHE + 0.9:
				var o2 := o.duplicate()
				o2["anfang"] = "splitter"
				var kipp := rng.randf_range(-0.12, 0.12)
				_stange(st, Transform3D.IDENTITY, Vector3(x + kipp, oben - rng.randf_range(0.35, 1.2),
						z), Vector3(x, oben, z), r, r, o2, 1.0)
			else:
				var fest := bock_x.x if x < 0.0 else bock_x.y
				var lose := -BRESCHE * 0.6 if x < 0.0 else BRESCHE * 0.5
				var sack := _durchhang(x, fest, lose, 0.4)
				_stange(st, Transform3D.IDENTITY, Vector3(x, unten - sack, z), Vector3(x, oben, z),
						r, r, o, 1.0)
		x += 0.42
		nr += 1
	_gerinne(st, -(links + GERINNE_LINKS), rechts + GERINNE_RECHTS, saat + 200)
	if kaputt:
		_truemmer(st, rng, halb_z, 2, Vector2(0.1, 0.13), Vector2(0.6, 1.1), holz)
		_truemmer(st, rng, halb_z, 5, Vector2(0.05, 0.06), Vector2(0.5, 1.0), holz)


## Lage des Gerinnes eines Fluderjochs `d` für `L05Wasser`: {"s": Mitte
## des Jochs (dort steht sein Rahmen, `_lage`), "von", "bis": x seiner
## Enden (x = q im Rahmen; links über dem Bach, rechts in der Wand)}.
static func gerinne_lage(level: Level05, d: Dictionary) -> Dictionary:
	var mitte := float(d["s"]) + float(d["tiefe"]) * 0.5
	return {"s": mitte, "von": -(_leitlinie(-1.0, mitte) + GERINNE_LINKS),
			"bis": _leitlinie(1.0, mitte) + GERINNE_RECHTS}


## Welt-Y des Randes (Achse) des Gerinnes von `d` an der Stelle x, mit
## seinem Gefälle wie in `_gerinne` (ohne die Beulen der Borke).
static func gerinne_rand_y(level: Level05, d: Dictionary, x: float) -> float:
	var g := gerinne_lage(level, d)
	var von: float = g["von"]
	var bis: float = g["bis"]
	var fall := GERINNE_FALL * (bis - x) / (bis - von)
	return level.boden_bei(float(g["s"])) + GERINNE_RAND - fall


## Ein Holzstück bzw. eine Stange wie die Bauteile hier (`_holz`, `_stange`),
## für das Mühlrad in `L05Wasser`: ein Holz, eine Borke, ein Stoff.
static func holz(st: SurfaceTool, lage: Transform3D, punkte: PackedVector3Array,
		radien: PackedFloat32Array, o: Dictionary = {}) -> void:
	_holz(st, lage, punkte, radien, o)


static func stange(st: SurfaceTool, lage: Transform3D, a: Vector3, b: Vector3, r0: float,
		r1: float, o: Dictionary = {}, stueck: float = 0.8) -> void:
	_stange(st, lage, a, b, r0, r1, o, stueck)


## Das Gerinne: ein ausgehöhlter Halbstamm (U) quer über den Weg von x `von`
## bis `bis`, Rand auf GERINNE_RAND, leicht fallend nach links (dorthin
## fließt das Wasser, über die Uferkante in den Bach). Außen Borke, der Rand
## grau verwittert, innen nass und dunkel.
static func _gerinne(st: SurfaceTool, von: float, bis: float, saat: int) -> void:
	# Profil (z, y) relativ zur Achse auf Randhöhe, in Laufrichtung des
	# Rings (siehe `Riesenstamm.gitter`): außen von +z über den Boden nach
	# −z, Rand links, innen zurück, Rand rechts.
	var profil := PackedVector2Array()
	var art := PackedFloat32Array()
	var farbe := PackedColorArray()
	const BOGEN := 9
	for i in BOGEN + 1:
		var w := PI * float(i) / float(BOGEN)
		profil.append(Vector2(cos(w) * GERINNE_R, -sin(w) * GERINNE_R))
		art.append(Riesenstamm.BORKE)
		farbe.append(Color(0.9, 0.88, 0.85, 0.15))
	for i in BOGEN + 1:
		var w := PI - PI * float(i) / float(BOGEN)
		profil.append(Vector2(cos(w) * GERINNE_INNEN, -sin(w) * GERINNE_INNEN))
		art.append(Riesenstamm.EIGEN)
		farbe.append(Color(NASS.r, NASS.g, NASS.b, 0.0) if i > 0 and i < BOGEN \
				else Color(GRAU.r, GRAU.g, GRAU.b, 0.0))
	profil.append(profil[0])
	art.append(art[0])
	farbe.append(farbe[0])
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 0.9
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var anzahl := maxi(ceili((bis - von) / 0.5), 2)
	for k in anzahl + 1:
		var x := lerpf(von, bis, float(k) / float(anzahl))
		var fall := GERINNE_FALL * (bis - x) / (bis - von)
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for i in profil.size():
			var p := profil[i]
			var beule := 1.0 + 0.03 * rauschen.get_noise_2d(x * 2.0, float(i))
			zeile.append(Vector3(x, GERINNE_RAND - fall + p.y * beule, p.x * beule))
			uv.append(Vector2(float(i) / float(profil.size() - 1) * 3.0,
					(x - von) * Riesenstamm.KACHEL_V * 2.0))
			fa.append(farbe[i])
			ar.append(Vector2(art[i], 0.25))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)
	# Stirnseiten: Hirnholz zwischen Außen- und Innenbogen.
	for ende in 2:
		var zeile := zeilen[0] if ende == 0 else zeilen[zeilen.size() - 1]
		var aussen := Vector3.LEFT if ende == 0 else Vector3.RIGHT
		for i in BOGEN:
			var a := zeile[i]
			var b := zeile[i + 1]
			var c := zeile[2 * BOGEN + 1 - i]
			var d := zeile[2 * BOGEN - i]
			Totholzzaun.dreieck(st, a, b, c, aussen, HIRN, HIRN, HIRN)
			Totholzzaun.dreieck(st, b, d, c, aussen, HIRN, HIRN, HIRN)


# ================================================================ Hürden

## Wurzelhürde (Entwurf §1 Nr. 12, §8.4): eine Wurzel quer über den Weg, so
## dick wie der Körper tief ist, der Rücken flach auf HUERDE_HOEHE und hell
## abgewetzt, die Flanken bemoost; an den Enden taucht sie in die Wände.
## Daneben eine dünne Nebenwurzel, flach im Boden.
##
## `huerde_koerper` baut den Körper (mit Stolperzone, Optik nur als Marke),
## `huerde_netz` die Wurzel in einen Sammler; beide für jedes Korridorlevel.
static func huerde_koerper(level: KorridorLevel, s: float, name: String) -> StaticBody3D:
	var koerper := level.huerde(s, {"stolperzone": L05Jagd.STOLPER_DAUER,
			"optik": func(_s: float, _t: float) -> Node3D: return _marke()})
	koerper.name = name
	return koerper


static func huerde_netz(sa: Sammler, level: KorridorLevel, s: float, rand: Rand,
		saat: int) -> void:
	var lage := _scher_lage(level, s, 0.0, KorridorLevel.HUERDE_TIEFE)
	var links := rand.leitlinie(-1.0, s)
	var rechts := rand.leitlinie(1.0, s)
	var r := KorridorLevel.HUERDE_TIEFE * 0.5
	# Höher als die Hürde: Der Rücken wird gut 0,3 m breit plattgedrückt
	# (Rücken − Körper gemessen −3,5 … 0 cm mit einem schmaleren Band, an den
	# Rändern fiel die Rundung schon ab); unten 5 cm im Boden.
	var hoch := 1.35
	var y := KorridorLevel.HUERDE_HOEHE - r * hoch + 0.06
	var stuetzen := PackedVector3Array([Vector3(-links - 1.4, 1.5, 0.15),
			Vector3(-links - 0.5, 0.75, 0.05), Vector3(-links + 0.4, y, 0.0)])
	var x := -links + 1.6
	while x < rechts - 1.0:
		stuetzen.append(Vector3(x, y, 0.02 * sin(x * 0.8 + float(saat))))
		x += 1.4
	stuetzen.append_array([Vector3(rechts - 0.4, y, 0.0), Vector3(rechts + 0.5, 0.8, -0.05),
			Vector3(rechts + 1.4, 1.6, -0.15)])
	var linie := _glatt(stuetzen, 3)
	_holz(sa.holz, lage, linie, _radien(linie.size(), PackedFloat32Array([0.24, r, r * 0.97, r,
			0.36])), {"saat": saat, "seiten": 11, "hoch": hoch, "buckel": 0.04, "moos": 0.85,
			"ton": WURZEL_TON, "oben": KorridorLevel.HUERDE_HOEHE,
			"klemm_x": Vector2(-links - 0.3, rechts + 0.3), "anfang": "spitz", "ende": "spitz"})
	var neben := _glatt(PackedVector3Array([Vector3(-links - 0.6, 0.2, -0.32),
			Vector3(-2.0, 0.08, -0.16), Vector3(0.6, 0.02, -0.12), Vector3(1.8, -0.12, -0.2)]), 3)
	_holz(sa.holz, lage, neben, _radien(neben.size(), PackedFloat32Array([0.12, 0.1, 0.07])),
			{"saat": saat + 5, "seiten": 7, "moos": 0.7, "ton": WURZEL_TON, "anfang": "spitz",
			"ende": "spitz"})


# ================================================================ Steine

## Findling der Findlingsgasse: `Findling.netz` genau auf den Körper, im
## gescherten Rahmen; Sandstein; Verdeckungsring um den Fuß. Körper
## (`findling_koerper`, Optik als Marke) und Netz (`findling_netz`, in einen
## Sammler) getrennt, für jedes Korridorlevel.
static func findling_koerper(level: KorridorLevel, s: float, q: float, breite: float,
		name: String) -> StaticBody3D:
	var koerper := level.findling_hindernis(s, q, breite,
			{"stolperzone": L05Jagd.STOLPER_DAUER,
			"optik": func(_s: float, _q: float, _b: float) -> Node3D: return _marke()})
	koerper.name = name
	return koerper


static func findling_netz(sa: Sammler, level: KorridorLevel, s: float, q: float,
		breite: float, saat: int) -> void:
	var groesse := Vector3(breite, KorridorLevel.FINDLING_HOEHE, KorridorLevel.FINDLING_TIEFE)
	var lage := _scher_lage(level, s, q, groesse.z)
	lage.origin.y += groesse.y * 0.5
	# Flanken und Ecken auf dem Körper: Grundriss als Rechteck mit Ecken von
	# 4 cm (`Findling` Option „ecke"), ohne Anlauf und Umrisssprünge; Beulen,
	# Unruhe und Facetten zusammen gut 1 cm, die Schichtfugen 1,2 cm tief
	# (Option „fuge_tiefe", Vorgabe 8 cm) – sie lesen sich über ihr dunkles
	# Band, nicht über die Tiefe; die Körnung gibt der Stoff.
	# WARUM: Die Gasse ist das Ausweich-Element unter Jagddruck, man läuft die
	# Innenecken eng an. Mit Superellipse (Exponent 5), Beulen 5 cm und den
	# Umrisssprüngen der Vorgabe lag die sichtbare Flanke 9–37 cm hinter dem
	# Körper, an der Gassenecke der Stirn (im Band der Stolperzone) bis 1,4 m:
	# Man stolperte an einer Ecke, die man noch weit weg sah. Die Gestalt
	# kommt jetzt aus den Sandsteinbändern, der Oberkante (rundum 7–22 cm
	# gerundet, darunter bleibt die Flanke auf dem Körper) und dem Moos. Der
	# starre Rahmen reicht: Der Weg dreht sich über die Tiefe eines Steins um
	# 0,004 rad, an seinen Enden 4–5 mm Versatz zum Körper (gemessen).
	var o := {"saat": saat, "moos": 0.8, "ecke": 0.04, "beulen": 0.004, "unruhe": 0.005,
			"anlauf": 0.0, "umriss": 0.0, "rundung": 0.22, "fuge_tiefe": 0.012}
	var netz := _getoent(Findling.netz(groesse, o), SANDSTEIN_TON)
	sa.stein(netz, lage)
	sa.kranz(_fussring(netz, -groesse.y * 0.5, 0.7), lage)


## Bank eines Geheimnisses oder Trittstein: `Findling.netz` in der Lage des
## Kastens aus BEGEHBARES, Kisten auf der ebenen Fläche, Ring am Boden.
static func _bank(sa: Sammler, level: Level05, name: String, ton: Color, saat: int) -> void:
	var e := level.begehbar(name)
	if e.is_empty():
		return
	var groesse: Vector3 = e["groesse"]
	var lage: Transform3D = e["lage"]
	var boden := -(float(e["oben"]) - groesse.y * 0.5)
	var o := _mit_kisten_auf(level, name, lage, groesse, {"saat": saat, "moos": 0.9})
	var netz := _getoent(Findling.netz(groesse, o), ton)
	sa.stein(netz, lage)
	sa.kranz(_fussring(netz, boden, clampf(minf(groesse.x, groesse.z) * 0.3, 0.35, 0.8)), lage)


## G1 Wurzelknie: der Stein im Griff der Eichenwurzeln. Sie kommen von der
## Außenseite (hinter der Leitlinie, +x) aus dem Boden, steigen an der
## Außenwand hoch, laufen über die Oberseite (dort in den Kasten geklemmt)
## und tauchen an der Wegseite IN den Kasten (Achse 0,13 m innen, Halbmesser
## dort ≤ 0,12) bis in den Boden. WARUM so: Vorher kamen sie von hinten (−s)
## über den Startboden und hingen vorn 0,25–2,0 m hoch vor dem Kasten – die
## Figur lief durch sie hindurch (Optik ohne Körper im erreichbaren Raum).
## Hinter der Leitlinie und im Kasten erreicht man sie nicht.
static func _wurzelknie(sa: Sammler, level: Level05) -> void:
	var name := "G1 Wurzelknie"
	var e := level.begehbar(name)
	if e.is_empty():
		return
	_bank(sa, level, name, Color(0.92, 0.9, 0.86), 5101)
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	var wurzel := {"ton": WURZEL_TON, "moos": 0.75, "seiten": 9, "buckel": 0.06,
			"oben": h.y + 0.015, "klemm_x": Vector2(-h.x, h.x), "anfang": "spitz", "ende": "spitz"}
	# Zwei Wurzeln quer über den Stein, zwischen den Kisten hindurch.
	for k in 2:
		var z := 0.55 - 0.9 * float(k)
		var linie := _glatt(PackedVector3Array([Vector3(h.x + 0.7, boden - 0.4, z + 0.25),
				Vector3(h.x + 0.26, h.y - 0.6, z + 0.15), Vector3(h.x - 0.1, h.y - 0.05, z + 0.1),
				Vector3(0.0, h.y - 0.07, z), Vector3(-h.x + 0.35, h.y - 0.1, z - 0.05),
				Vector3(-h.x + 0.13, h.y - 0.5, z - 0.08), Vector3(-h.x + 0.14, boden + 0.3, z - 0.12),
				Vector3(-h.x + 0.3, boden - 0.4, z - 0.15)]), 4)
		var o := wurzel.duplicate()
		o["saat"] = 5110 + k
		_holz(sa.holz, lage, linie, _radien(linie.size(), PackedFloat32Array([0.26, 0.2, 0.15,
				0.12, 0.11])), o)


## Wurzeln, die aus der Böschung über die Bank G2 greifen (oben geklemmt).
static func _bankwurzeln(sa: Sammler, level: Level05) -> void:
	var e := level.begehbar("G2 Böschungsbank")
	if e.is_empty():
		return
	var lage: Transform3D = e["lage"]
	var g: Vector3 = e["groesse"]
	var h := g * 0.5
	var boden := -(float(e["oben"]) - h.y)
	for k in 2:
		# Vorn (+z, wo man landet), die Kisten stehen hinten (z −0,5 … −2,5).
		var z := 0.2 + 1.4 * float(k)
		# An der Wegseite mit der Achse 0,12 m im Kasten (Halbmesser dort ≤ 0,1):
		# Mit 0,05 standen die Wurzeln 3–6 cm vor der Bank in den Weg.
		var linie := _glatt(PackedVector3Array([Vector3(h.x + 0.9, h.y + 1.4, z + 0.3),
				Vector3(h.x - 0.1, h.y - 0.06, z), Vector3(-h.x + 0.5, h.y - 0.1, z - 0.2),
				Vector3(-h.x + 0.12, h.y - 0.7, z - 0.25), Vector3(-h.x + 0.2, boden - 0.2,
				z - 0.4)]), 4)
		_holz(sa.holz, lage, linie, _radien(linie.size(), PackedFloat32Array([0.16, 0.11, 0.08])),
				{"saat": 5350 + k, "ton": WURZEL_TON, "moos": 0.5, "seiten": 7, "buckel": 0.1,
				"oben": h.y + 0.015, "klemm_x": Vector2(-h.x, h.x), "anfang": "spitz",
				"ende": "spitz"})


## Optionen für einen Stein, auf dem Kisten stehen: Die ebene Fläche
## (`Findling.plateau`) muss jede Kiste ganz tragen (wie Level 01).
static func _mit_kisten_auf(level: Level05, name: String, lage: Transform3D, groesse: Vector3,
		optionen: Dictionary) -> Dictionary:
	var noetig := Vector2.ZERO
	var h := groesse * 0.5
	for k: Dictionary in Level05.KISTEN:
		if String(k.get("auf", "")) != name:
			continue
		var lokal := lage.affine_inverse() * level.weg_punkt(float(k["s"]), float(k["q"]))
		if absf(lokal.x) > h.x or absf(lokal.z) > h.z:
			continue
		noetig.x = maxf(noetig.x, absf(lokal.x) + 0.5)
		noetig.y = maxf(noetig.y, absf(lokal.z) + 0.5)
	var o := optionen.duplicate()
	for versuch in 8:
		var platte := Findling.plateau(groesse, o)
		if platte.x >= noetig.x and platte.y >= noetig.y:
			break
		o["rundung"] = float(o.get("rundung", 0.3)) * 0.6
		o["umriss"] = float(o.get("umriss", 0.035)) * 0.5
		o["anlauf"] = float(o.get("anlauf", 0.06)) * 0.5
		o["unruhe"] = float(o.get("unruhe", 0.1)) * 0.6
	return o


## Verdeckungsring genau um den Fuß eines Netzes auf der Höhe `y` (wie
## `L01Wegbauten._fussring`).
static func _fussring(netz: ArrayMesh, y: float, breite: float, staerke: float = 0.55) -> ArrayMesh:
	const N := 36
	var radien := PackedFloat32Array()
	radien.resize(N)
	for f in netz.get_surface_count():
		var punkte: PackedVector3Array = netz.surface_get_arrays(f)[Mesh.ARRAY_VERTEX]
		for p in punkte:
			if absf(p.y - y) > 0.3:
				continue
			var d := Vector2(p.x, p.z)
			var w := atan2(-d.y, d.x)
			var k := posmod(int(floor(w / TAU * float(N) + 0.5)), N)
			radien[k] = maxf(radien[k], d.length())
	for runde in 3:
		for k in N:
			if radien[k] <= 0.0:
				radien[k] = maxf(radien[(k + 1) % N], radien[(k + N - 1) % N]) * 0.97
	return Findling.kranz(radien, y + 0.025, breite, staerke, 0.25)


## Kopie eines Netzes mit getönten Scheitelfarben (RGB · ton, A bleibt).
static func _getoent(netz: ArrayMesh, ton: Color) -> ArrayMesh:
	var neu := ArrayMesh.new()
	for f in netz.get_surface_count():
		var arrays := netz.surface_get_arrays(f)
		var farben: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in farben.size():
			var c := farben[i]
			farben[i] = Color(c.r * ton.r, c.g * ton.g, c.b * ton.b, c.a)
		arrays[Mesh.ARRAY_COLOR] = farben
		neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return neu


## Leere Marke als Optik eines Körpers, dessen Netz im Abschnitt liegt.
static func _marke() -> Node3D:
	var marke := Node3D.new()
	marke.name = "Optik (Wegbauten)"
	return marke


# ================================================================ Rampe, Treppen

## Grabenrampe: halbe Knüppel quer über die Rampe, die Spaltfläche oben und
## parallel zur Rampe genau auf ihrer Oberseite; darunter zwei Längshölzer,
## die die Seite zum Graben schließen.
static func _grabenrampe(sa: Sammler, level: Level05) -> void:
	var e := level.begehbar("Grabenrampe")
	if e.is_empty():
		return
	var von: float = e["von"]
	var bis: float = e["bis"]
	var profil: Array = e["profil"]
	var profil_ende: Array = e["profil_ende"]
	var q0 := (profil[0] as Vector2).x
	var q1 := (profil[1] as Vector2).x
	var h0 := (profil[0] as Vector2).y
	var h1 := (profil_ende[0] as Vector2).y
	# Die Rampe misst ihre Höhe über der Sohle des Grabens (dort liegt die
	# Decke, `boden_bei`); hinter dem Graben läge sie 0,8 m höher.
	var sohle := level.boden_bei((von + bis) * 0.5)
	var rampe := func(s: float, q: float) -> Vector3:
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
		p.y = sohle + lerpf(h0, h1, clampf(inverse_lerp(von, bis, s), 0.0, 1.0))
		return p
	var rng := PropWerkzeug.zufall(5150)
	# Halbmesser 0,16 bei 0,3 m Abstand: Die Spaltflächen (0,31 m breit)
	# stoßen ohne Fuge aneinander.
	var r := 0.16
	var abstand := 0.3
	var s := von + abstand * 0.5
	var nr := 0
	while s < bis - abstand * 0.25:
		var a: Vector3 = rampe.call(s - r, q0)
		var b: Vector3 = rampe.call(s + r, q0)
		var quer: Vector3 = (rampe.call(s, q1) - rampe.call(s, q0)).normalized()
		var normale := quer.cross(b - a).normalized()
		if normale.y < 0.0:
			normale = -normale
		# Die Spaltfläche liegt 0,25 · r vor der Achse (`_holz`): Achse so weit
		# unter der Oberseite der Rampe, die Fläche parallel zu ihr.
		# Die Enden bündig mit den Seiten der Rampe: 8–10 cm darüber hinaus
		# ragten sie zur Wegseite in die Luft über dem Graben.
		var achse_a: Vector3 = rampe.call(s, q0 + 0.01) - normale * r * 0.25
		var achse_b: Vector3 = rampe.call(s, q1 - 0.01) - normale * r * 0.25 \
				+ Vector3.UP * rng.randf_range(-0.01, 0.0)
		_stange(sa.holz, Transform3D.IDENTITY, achse_a, achse_b, r, r * rng.randf_range(0.92, 1.0),
				{"saat": 5160 + nr, "seiten": 9, "spalt": normale, "spalt_tiefe": 0.25,
				"spalt_farbe": GRAU * 1.15, "moos": 0.4, "ton": PFAHL_TON}, 1.4)
		s += abstand
		nr += 1
	# Längshölzer unter den Knüppeln
	for k in 2:
		var q := q0 + 0.12 if k == 0 else q1 - 0.12
		var a: Vector3 = rampe.call(von - 0.2, q) + Vector3.DOWN * 0.24
		var b: Vector3 = rampe.call(bis + 0.15, q) + Vector3.DOWN * 0.22
		_stange(sa.holz, Transform3D.IDENTITY, a, b, 0.12, 0.11, {"saat": 5190 + k,
				"ton": PFAHL_TON, "moos": 0.6})


## Wurzel an einer Setzstufe bei `s` (die obere Decke vor `s`): Rücken
## bündig in der Decke, 7 cm vor der Stufe; an den Enden in die Wände (bis
## 1,3 m hinter die Leitlinien, 0,9–1,0 m über der oberen Decke).
static func stufenwurzel(sa: Sammler, level: KorridorLevel, s: float, rand: Rand,
		saat: int) -> void:
	var oben := level.boden_bei(s - 0.05)
	var punkt := LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
	var lage := Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(level.verlauf, s)),
			Vector3(punkt.x, oben, punkt.z))
	var links := rand.leitlinie(-1.0, s)
	var rechts := rand.leitlinie(1.0, s)
	var r := 0.13
	var y := -r + 0.02
	var stuetzen := PackedVector3Array([Vector3(-links - 1.3, 0.9, 0.3),
			Vector3(-links - 0.4, 0.2, 0.12), Vector3(-links + 0.5, y, r - 0.07)])
	var x := -links + 1.8
	while x < rechts - 1.2:
		stuetzen.append(Vector3(x, y, r - 0.07 + 0.015 * sin(x * 1.3 + float(saat))))
		x += 1.5
	stuetzen.append_array([Vector3(rechts - 0.5, y, r - 0.07), Vector3(rechts + 0.4, 0.25, 0.12),
			Vector3(rechts + 1.3, 1.0, 0.3)])
	var linie := _glatt(stuetzen, 3)
	_holz(sa.holz, lage, linie, _radien(linie.size(), PackedFloat32Array([0.1, r, r * 1.05, r,
			0.1])), {"saat": saat, "seiten": 9, "moos": 0.35, "ton": WURZEL_TON, "buckel": 0.05,
			"oben": 0.012, "klemm_x": Vector2(-links - 0.3, rechts + 0.3), "hell": ABGEWETZT * 1.1,
			"anfang": "spitz", "ende": "spitz"})


# ================================================================ Wehr, Rastplätze

## Das gebrochene Wehr von Level 05 (L6 auf der Wehrkrone; `wehr`).
static func _wehr(sa: Sammler, level: Level05) -> void:
	var luecke: Dictionary = Level05.LUECKEN[5]
	var krone := Vector2.ZERO
	for a: Dictionary in Level05.ABSAETZE:
		if String(a["name"]) == "Wehrkrone":
			krone = Vector2(a["von"], a["bis"])
	wehr(sa, level, float(luecke["von"]), float(luecke["bis"]), krone,
			float(luecke["grund_y"]), _rand_l05(level))


## Das gebrochene Wehr: Pfahlreihen neben der Krone (hinter den
## Leitlinien), an den Lippen des Bruchs herausragende Holme und in der
## Lücke gebrochene Pfähle – alles unter der Decke bzw. außerhalb der
## Reichweite. `von`/`bis` die Lücke, `krone` Anfang und Ende der Wehrkrone
## (Strecke), `grund_y` Welt-Y, auf dem die gebrochenen Pfähle in der Lücke
## stehen (Level 05: der Grund unter dem Weißwasser, 1,0).
static func wehr(sa: Sammler, level: KorridorLevel, von: float, bis: float, krone: Vector2,
		grund_y: float, rand: Rand) -> void:
	var rng := PropWerkzeug.zufall(5600)
	var pfahl := {"ton": PFAHL_TON, "moos": 0.5, "seiten": 8}
	# Pfahlreihen
	for seite: float in [-1.0, 1.0]:
		var s := krone.x + 0.3
		var nr := 0
		while s < krone.y - 0.2:
			if s > von - 0.6 and s < bis + 0.6:
				s += 0.95
				continue
			if rng.randf() > 0.12:
				var q := seite * (rand.leitlinie(seite, s) + 0.3 + rng.randf_range(-0.04, 0.06))
				var boden := level.boden_bei(s)
				var fuss := level.weg_punkt(s, q)
				fuss.y = boden - 1.4
				var kopf := level.weg_punkt(s + rng.randf_range(-0.05, 0.05),
						q + seite * rng.randf_range(0.0, 0.08))
				kopf.y = boden + rng.randf_range(0.35, 0.95)
				var o := pfahl.duplicate()
				o["saat"] = 5610 + nr + int(seite * 50.0)
				o["anfang"] = "stumpf"
				o["ende"] = "offen" if rng.randf() < 0.6 else "splitter"
				o["bruch_farbe"] = GRAU
				var r := rng.randf_range(0.12, 0.15)
				_stange(sa.holz, Transform3D.IDENTITY, fuss, kopf, r, r * 0.92, o)
			s += 0.95 + rng.randf_range(-0.08, 0.08)
			nr += 1
	# Holme, die an den Lippen in den Bruch ragen (Oberkante 6–12 cm unter
	# der Decke).
	for lippe in 2:
		var s_lippe := von if lippe == 0 else bis
		var richtung := 1.0 if lippe == 0 else -1.0
		var boden := level.boden_bei(s_lippe - richtung * 0.1)
		for k in 3:
			var q := -2.5 + 2.5 * float(k) + rng.randf_range(-0.4, 0.4)
			var r := rng.randf_range(0.11, 0.15)
			var a := level.weg_punkt(s_lippe - richtung * 0.9, q)
			var b := level.weg_punkt(s_lippe + richtung * rng.randf_range(0.35, 0.9),
					q + rng.randf_range(-0.2, 0.2))
			a.y = boden - r - 0.06
			b.y = boden - r - rng.randf_range(0.08, 0.3)
			_stange(sa.holz, Transform3D.IDENTITY, a, b, r, r * 0.9, {"saat": 5650 + lippe * 5 + k,
					"ton": PFAHL_TON, "moos": 0.3, "anfang": "stumpf", "ende": "splitter",
					"bruch_farbe": GRAU * 1.3})
	# Gebrochene Pfähle in der Lücke, unter dem Wasser bis 0,75 m unter die Decke.
	var oben_y := level.boden_bei(von - 0.1) - 0.75
	for k in 4:
		var s := lerpf(von + 0.6, bis - 0.6, float(k) / 3.0) + rng.randf_range(-0.3, 0.3)
		var q := rng.randf_range(-3.0, 3.0)
		var fuss := level.weg_punkt(s, q)
		fuss.y = grund_y
		var kopf := level.weg_punkt(s + rng.randf_range(-0.3, 0.3), q + rng.randf_range(-0.3, 0.3))
		kopf.y = oben_y - rng.randf_range(0.0, 0.6)
		_stange(sa.holz, Transform3D.IDENTITY, fuss, kopf, 0.14, 0.13, {"saat": 5680 + k,
				"ton": PFAHL_TON, "moos": 0.6, "anfang": "stumpf", "ende": "splitter",
				"bruch_farbe": GRAU * 1.2})


## Wegpfahl eines Rastplatzes (Entwurf §8.4, §1 Nr. 22): hinter der rechten
## Leitlinie (bildlinks), ein Arm, daran die Laterne – ihr Rahmen im Holz,
## ihr Kern als leuchtendes Netz (`_laterne`, kein Licht).
static func _rastpfahl(sa: Sammler, level: Level05, s: float, saat: int) -> void:
	var rechts := _leitlinie(1.0, s)
	var lage := _lage(level, s)
	var x := rechts + 0.32
	var o := {"ton": PFAHL_TON, "moos": 0.35, "seiten": 8, "saat": saat, "anfang": "stumpf"}
	_stange(sa.holz, lage, Vector3(x, -0.8, 0.0), Vector3(x + 0.05, 2.72, 0.02), 0.12, 0.1, o)
	# Arm zum Weg, die Laterne hängt knapp hinter der Leitlinie.
	var arm_y := 2.52
	var ox := o.duplicate()
	ox["saat"] = saat + 1
	ox["seiten"] = 6
	_stange(sa.holz, lage, Vector3(x + 0.05, arm_y, 0.0), Vector3(rechts + 0.08, arm_y + 0.04, 0.0),
			0.04, 0.035, ox)
	var mitte := _laternen_mitte(s)
	# Rahmen: vier Stäbe, Deckel und Boden.
	for k in 4:
		var w := TAU * float(k) / 4.0 + 0.4
		var d := Vector3(cos(w), 0.0, sin(w)) * 0.1
		var os := ox.duplicate()
		os["saat"] = saat + 10 + k
		os["seiten"] = 4
		os["anfang"] = "stumpf"
		os["ende"] = "stumpf"
		_stange(sa.holz, lage, mitte + d + Vector3(0.0, -0.17, 0.0),
				mitte + d + Vector3(0.0, 0.17, 0.0), 0.014, 0.014, os)
	for k in 2:
		var y := 0.18 if k == 0 else -0.18
		var od := ox.duplicate()
		od["saat"] = saat + 20 + k
		od["seiten"] = 8
		_stange(sa.holz, lage, mitte + Vector3(0.0, y - 0.03, 0.0), mitte + Vector3(0.0, y + 0.03, 0.0),
				0.125, 0.125, od)
	# Haken
	_stange(sa.holz, lage, Vector3(rechts + 0.14, arm_y, 0.0), mitte + Vector3(0.0, 0.2, 0.0), 0.012,
			0.012, {"seiten": 4, "saat": saat + 30, "ton": Color(0.3, 0.3, 0.3)})


## Mitte der Laterne eines Rastplatzes bei `s` (Raum von `_lage(level, s)`):
## knapp hinter der rechten Leitlinie, unter dem Arm.
static func _laternen_mitte(s: float) -> Vector3:
	return Vector3(_leitlinie(1.0, s) + 0.14, 2.2, 0.0)


## Kern der Laterne: ein gestreckter Achtkant, leuchtend (in `glut`).
static func _laterne(glut: SurfaceTool, level: Level05, s: float, saat: int) -> void:
	var mitte := _laternen_mitte(s)
	var kern := PackedVector3Array([mitte + Vector3(0.0, -0.16, 0.0), mitte + Vector3(0.0, -0.1, 0.0),
			mitte + Vector3(0.0, 0.1, 0.0), mitte + Vector3(0.0, 0.16, 0.0)])
	_holz(glut, _lage(level, s), kern, PackedFloat32Array([0.04, 0.085, 0.085, 0.04]),
			{"seiten": 8, "saat": saat, "buckel": 0.0, "moos": 0.0})
