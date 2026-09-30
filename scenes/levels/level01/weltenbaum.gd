extends RefCounted
class_name L01Weltenbaum
## Level 01, Modul „Weltenbaum": der Riese und die Wurzelwendel
## (Plan Abschnitte 5E, 5F, 11 K1/K5, 13).
##
## WAS HIER ENTSTEHT
## * Der **Stamm** (Ø 24 m am Fuß, Ø 16 m bei y 36) mit Brettwurzeln als
##   dünnen Finnen (oben 0,5–0,9 m, am Fuß 2–3 m, der Grat fällt von
##   10–12 m am Stamm bis 9–14 m hinaus), die in den Knoll und die
##   Wurzelgruben auslaufen, tief dunklen Spalten dazwischen mit großen
##   Farnen (`_fussfarne`), fünf fast waagerechten Ästen, Konsolenpilzen in
##   Stufen (`Weltenbaum.konsolen_in`), Efeu, zwei kleinen Maserknollen,
##   Leuchtpilzen und Moosstreifen. Borke in Weltprojektion
##   (`Weltenbaum.stoff_stamm()`), ab 88 m die dunkle Fernfassung.
## * Der **Kronenschirm** aus `Kronenwolke`-Ballen: Unterseite am Rand bei
##   y ≈ 33, Oberseite ≈ 70. Über dem Regal hängt ein Vorhang aus Laub weit
##   über das Tal hinaus (bis r 46) – im Schlussbild das dunkle obere Band.
##   Die Krone wirft keinen Schatten.
## * Die **Wurzelkehle** der Wendel (s 198–273) und das **Wurzelregal** (F):
##   - Innen das Wurzelfleisch: Stränge (Ø 2–4 m, flach gedrückt, mit Knoten)
##     in Stücken, die auftauchen, sich flechten und wieder ins Fleisch
##     tauchen; darüber dünne Faserwurzeln schräg die Flanke hinab. Dahinter
##     ein dunkler Grund, in den Rissen Farne und Leuchtpilze.
##   - Außen die **Außenwurzel**: Ihr Kamm ist der Rindenwulst (genau auf der
##     Kollision, +0,6), ihr Leib wölbt sich darunter 2 m hinaus und 4 m
##     hinab. Damit sie sich nicht als glatter Schlauch liest: große
##     Knorren (1,2–2 m) alle 6–10 m auf dem Leib, an drei Stellen eine
##     dunkle Fuge, die sie in zwei Stränge teilt, acht Seitenwurzeln von
##     0,8 bis 4,4 m Stärke, die sich in die Wurzelgruben stemmen (die
##     dicken mit Maserknolle am Ansatz), und Vorhänge aus Würzelchen und
##     Moos unter dem Bauch (`_vorhaenge_bauen`, Karten mit Alpha-Schnitt).
##     Alles jenseits der Wulstkollision (q > 4,7) und unter ihrer
##     Oberkante.
##   - Unter dem Weg die Schürze und die Wand bis in die Gruben
##     (`boden_unter_wendel`). Die Decke selbst malt `wegboden.gdshader`
##     (Rippen an den Rändern, Querrisse, Knoten); an der Innenkante rollt
##     ein dunkler, bemooster Fuß 0,3 m unter sie (`_flankenfuss`).
##   - Brüche G1 und G2 mit Stirnflächen, die herausstehen und gerissen
##     sind, nicht gesägt: Faserkamm, Borkensaum, Faserbündel, die bis
##     0,5 m vor- und zurückspringen, radiale Fasern statt Jahresringen, ein
##     dunkler Kern, acht abstehende Borkenplatten (`Weltenbaum.bruch_in`
##     mit "zerfetzt"/"scherben"), Farne am Fuß; die Oberwurzel (S4/S5),
##     drei Wurzelbögen (TORE "art": "wurzelbogen") und das Kronentor
##     (s 280): zwei Luftwurzeln vom Südwestast.
##   - Am Regal (F) buckelt die Lippe 0–0,55 m hinaus, ein gedecktes
##     Moospolster greift unruhig auf die Decke, darunter hängen Wurzeln;
##     hinter dem Portal rollt das Ende rund ab (`_regalende`), große Farne
##     sitzen in seinen Ecken – kein Brett mit rechten Winkeln.
##
## PASSFORM. Die Kollision baut der Rohbau (`Level01.BEGEHBARES`). Hier wird
## nur gezeichnet, und zwar so, dass nichts über die Kollision zum Weg hin
## ragt: Jeder Punkt des Wurzelfleischs liegt hinter der Flankenebene
## (q −4 | 0) → (−10 | +9) (`_klemmen` sichert das ab), die Oberwurzel
## hinter q −5,4 mit ihrer Oberseite genau auf der Kollisionsoberkante, der
## Kamm der Außenwurzel genau auf dem Wulst; Knorren und Leib liegen jenseits
## von q 4,7. Wo die Kollision endet, endet auch die Optik (die Oberwurzel
## mit einem Bruch). `optik()` liefert für diese Einträge deshalb einen
## leeren Knoten – die Kehle entsteht in Stücken zu 20–30 m in den
## Bauschritten, damit sie wenige Zeichenaufrufe kostet und die Sichtprüfung
## Stücke außerhalb des Bildes weglässt.
##
## KAMERA (Plan K1, K5). Über dem Weg (|q| ≤ 6) hängt nichts tiefer als die
## Tore selbst; die Unterkante ihrer Stränge liegt auf der TORE-Höhe, oberhalb
## von 6 m tragen sie Sichtkörper auf der Sichtsperre (Ebene 8, wie
## `Schluchtsaum.wurzeltor`). Der Stamm bleibt, wo die Wendel an ihm läuft,
## innerhalb r 13.
##
## KOSTEN (Plan Abschnitt 13, Grenze 16 Zeichenaufrufe + 6 Schatten, 70k
## Primitive). Je Kehlenstück ein Netz mit einer Fläche (Wurzelborke), dazu
## Stamm, grobe und feine Krone, Kronentor, zwei Farn-MultiMeshes in der
## Kehle, eines am Stammfuß und die Vorhänge. Schatten werfen nur drei
## schlichte Schattenkörper (Stamm samt Ästen, Kehle samt Bögen,
## Kronentor): Die nahen Netze zeichnen keine Schattenstufe. Gemessen als
## Differenz mit/ohne dieses Modul (Aufrufe samt Schattenstufen /
## Primitive), vor der Nachbesserung: s 176 15 / 49k, s 212 16 / 54k,
## s 249 18 / 69k, s 262 19 / 69k, s 281 17 / 62k, vom Grat (s 60) 3 / 11k.
## Die Nachbesserung nahm je Kehlenstück die Deckfläche weg (−1) und gab
## Fußfarne und Vorhänge dazu (+1 je, wo sie im Bild sind); die ganze
## Station liegt bei 241–274 Aufrufen und 170–248k Primitiven (s 212–262).
## Ab 88 m übernimmt die Fernfassung (Stamm und Kehle ≈ 4,3k Dreiecke,
## dazu die grobe Krone 5,5k); bis 110 m überlappen Nah und Fern – eine
## Lücke wäre schlimmer als ein paar doppelt gezeichnete Dreiecke.

# ================================================================ Maße

## Radiusverlauf des Stamms, Vector2(Welt-Y, Radius). Die Stammwand, an der
## das Wurzelfleisch endet, liegt auf Höhe der Wendel bei r ≈ 11–12.
const PROFIL := [
	Vector2(-4.0, 12.0), Vector2(6.0, 11.7), Vector2(16.0, 11.3), Vector2(24.0, 10.7),
	Vector2(30.0, 9.6), Vector2(36.0, 8.3), Vector2(44.0, 7.3), Vector2(52.0, 6.2),
	Vector2(61.0, 4.6),
]

## Brettwurzeln, Winkel in Grad (0 = Osten, 90 = Norden): dünne Finnen
## (`Weltenbaum.brettwurzel_in`), deren Grat von 10–12 m am Stamm bis 9–14 m
## hinaus auf null fällt. Die sechs im freien Sektor stemmen den Stamm in
## den Knoll (Süd- und Westseite, von der Bachwiese aus zu sehen); die drei
## unter der Wendel laufen in die Gruben.
const BRETTWURZELN := [
	{"winkel": 178.0, "reichweite": 11.0, "hoehe": 12.0, "dicke": 2.2, "fuss_y": 5.2},
	{"winkel": 203.0, "reichweite": 13.0, "hoehe": 11.0, "dicke": 2.4, "fuss_y": 5.6},
	{"winkel": 226.0, "reichweite": 9.5, "hoehe": 10.0, "dicke": 1.7, "fuss_y": 6.0},
	{"winkel": 246.0, "reichweite": 12.0, "hoehe": 11.5, "dicke": 2.1, "fuss_y": 6.3},
	# Zur Bachwiese hin kurz: Dort läuft der Weg (D) nur 16 m von der Achse.
	{"winkel": 268.0, "reichweite": 7.5, "hoehe": 9.5, "dicke": 1.8, "fuss_y": 6.6},
	{"winkel": 291.0, "reichweite": 5.0, "hoehe": 8.0, "dicke": 1.6, "fuss_y": 6.8},
	{"winkel": 18.0, "reichweite": 13.0, "hoehe": 10.0, "dicke": 2.4, "fuss_y": -2.0},
	{"winkel": 63.0, "reichweite": 14.0, "hoehe": 10.0, "dicke": 2.4, "fuss_y": -2.0},
	{"winkel": 108.0, "reichweite": 12.0, "hoehe": 11.0, "dicke": 2.2, "fuss_y": -1.5},
]

## Die Äste in die Krone, Winkel in Grad. Fast waagerecht (Schirmkrone):
## Der erste läuft nach Südwesten über das Regal – an ihm hängt das
## Kronentor, und im Schlussbild ist seine Unterseite das dunkle obere Band.
const AESTE := [
	{"winkel": 163.0, "y": 29.0, "laenge": 36.0, "steigung": 0.22, "radius": 2.7,
			"wandern": 0.0},
	{"winkel": 222.0, "y": 27.5, "laenge": 33.0, "steigung": 0.21, "radius": 2.6,
			"wandern": 0.08},
	{"winkel": 318.0, "y": 30.0, "laenge": 27.0, "steigung": 0.3, "radius": 2.5,
			"wandern": -0.09},
	{"winkel": 36.0, "y": 31.0, "laenge": 28.0, "steigung": 0.3, "radius": 2.5,
			"wandern": 0.06},
	{"winkel": 100.0, "y": 33.0, "laenge": 26.0, "steigung": 0.34, "radius": 2.4,
			"wandern": -0.07},
]

## Die Stücke der Kehle entlang s. Jedes wird ein eigenes Netz: So lässt
## die Sichtprüfung weg, was hinter der Kamera liegt.
const STUECKE := [Vector2(184.0, 221.0), Vector2(221.0, 246.0), Vector2(246.0, 268.0),
		Vector2(268.0, 296.0)]

## Sichtweiten der Nah- und Fernfassung (Mitte der Hülle bis Kamera).
const NAH_BIS := 110.0
const FERN_AB := 88.0
## Die feine Krone (Nord- bis Südwestsektor): nur von E3 und dem Regal aus.
const KRONE_NAH_BIS := 48.0
const FARN_BIS := 48.0
const RAND := 4.0

## Innenflanke: vom Fuß an der Wegkante 6 m nach innen und 9 m hinauf.
const FLANKE_KOPF := 9.0
const FLANKE_TIEFE := 6.0
## Ab hier steht die Kollision der Innenflanke (Rohbau), bis 273,5.
const FLANKE_VON := 197.0
const FLANKE_BIS := 273.5

## Die Wege der Wendel, die der Rohbau baut: Außenwurzel in drei Teilen
## zwischen den Brüchen, Wulst ab 214.
const G1 := Vector2(210.5, 213.5)
const G2 := Vector2(243.0, 245.5)
## Das Regal endet mit dem Weg; dahinter taucht die Wurzel in den Knoll.
const ENDE := 287.2

## Querschnitt der Außenwurzel mit Kamm (E2/E3): Vector2(q relativ zur
## Wegkante, Höhe über der Decke). Punkt 0 steckt unter der Decke, 3–5 sind
## der Kamm genau auf der Wulstkollision (+0,6 zwischen q 4,2 und 4,55),
## 7–12 der Leib, der sich hinaus- und hinabwölbt, 14 läuft unter den Weg.
const KAMM := [
	Vector2(-0.10, -0.02), Vector2(0.00, 0.12), Vector2(0.07, 0.35), Vector2(0.20, 0.55),
	Vector2(0.38, 0.60), Vector2(0.55, 0.585), Vector2(0.80, 0.46), Vector2(1.10, 0.18),
	Vector2(1.45, -0.35), Vector2(1.85, -1.15), Vector2(2.10, -2.10), Vector2(2.02, -3.0),
	Vector2(1.55, -3.65), Vector2(0.70, -3.98), Vector2(-0.40, -4.05),
]
## Dieselbe Wurzel über der Wurzelwiese (E1): bündig mit der Decke, die
## Flanke läuft in die Wiese.
const FLACH := [
	Vector2(-0.10, -0.02), Vector2(0.02, -0.04), Vector2(0.12, -0.10), Vector2(0.25, -0.18),
	Vector2(0.40, -0.28), Vector2(0.60, -0.42), Vector2(0.88, -0.66), Vector2(1.15, -0.98),
	Vector2(1.38, -1.35), Vector2(1.52, -1.82), Vector2(1.56, -2.35), Vector2(1.45, -2.9),
	Vector2(1.10, -3.4), Vector2(0.45, -3.8), Vector2(-0.40, -4.05),
]
## Die Lippe des Regals (F): außen offen. Innen greift ein Moospolster
## 0,3–0,65 m weit auf die Decke (Punkt 0, knapp darüber, der Rand nach
## Rauschen), außen ein flacher Borkenwulst (Punkte 1–3, +8 cm), dann rundet
## sich die Kante ab und der Leib wölbt sich unter ihr hinaus. Die Punkte
## 1–9 springen nach `_regal_buckel` 0–0,55 m nach außen: Mit der geraden
## Kante las sich das Regal im Schlussbild als Brett mit rechten Winkeln.
## Polster und Wulst gedeckt (Verdeckung 0,7–0,85, Moos in Flecken): Hell
## und satt lag das Polster als grüner Streifen an der Kante.
const LIPPE := [
	Vector2(-0.30, 0.02), Vector2(0.02, 0.06), Vector2(0.16, 0.085), Vector2(0.30, 0.03),
	Vector2(0.42, -0.22), Vector2(0.54, -0.62), Vector2(0.68, -1.15), Vector2(0.82, -1.75),
	Vector2(0.95, -2.35), Vector2(1.02, -3.0), Vector2(0.95, -3.6), Vector2(0.70, -4.1),
	Vector2(0.30, -4.45), Vector2(-0.25, -4.7), Vector2(-0.90, -4.85),
]
## Verdeckung und Moos der Regallippe je Punkt: das Polster hell und grün,
## kein dunkler Strich an seinem Innenrand.
const LIPPE_AO := [0.7, 0.78, 0.84, 0.8, 0.74, 0.68, 0.62, 0.56, 0.5, 0.45, 0.4, 0.36,
		0.32, 0.3, 0.3]
const LIPPE_MOOS := [0.6, 0.5, 0.22, 0.45, 0.6, 0.5, 0.4, 0.3, 0.2, 0.15, 0.12, 0.1,
		0.15, 0.3, 0.4]
## Das Ende des Regals hinter dem Portal (s 287): ein Querschnitt über den
## Rand, Vector2(a, h) – `a` m hinter dem Wegende, `h` über der Decke. Das
## Moospolster greift auf die Decke, dann rollt die Schulter ab und taucht
## wie die Außenwurzel (`_abtauchen`) in den Knoll. `a` ab Punkt 2 wird je
## Querlage gestreckt (`_regalende`): ein runder Umriss statt eines Bretts.
const REGALENDE := [
	Vector2(-0.30, 0.02), Vector2(0.0, 0.055), Vector2(0.28, 0.06), Vector2(0.55, -0.02),
	Vector2(0.85, -0.24), Vector2(1.15, -0.62), Vector2(1.45, -1.15), Vector2(1.72, -1.85),
	Vector2(1.95, -2.7), Vector2(2.1, -3.7), Vector2(2.15, -4.9),
]
const REGALENDE_AO := [0.7, 0.8, 0.84, 0.8, 0.74, 0.66, 0.58, 0.5, 0.42, 0.36, 0.32]
const REGALENDE_MOOS := [0.6, 0.5, 0.3, 0.45, 0.55, 0.45, 0.3, 0.22, 0.18, 0.2, 0.3]
## Verdeckung und Moos je Punkt der Außenwurzel (Kamm oben bemoost, der
## Leib nach unten dunkel).
const AUSSEN_AO := [0.55, 0.9, 1.0, 1.0, 1.0, 1.0, 0.96, 0.88, 0.76, 0.62, 0.5, 0.42,
		0.36, 0.32, 0.3]
const AUSSEN_MOOS := [0.7, 0.45, 0.35, 0.65, 0.75, 0.7, 0.6, 0.4, 0.25, 0.16, 0.12, 0.1,
		0.15, 0.3, 0.4]

## Grundfarbe der Farne in den Rissen: etwas dunkler als das Laub am Weg.
const FARN_FARBE := Color(0.2, 0.4, 0.15)

## EIGENER NEBEL. Vom Grat aus steht der Riese 120–150 m weit im Dunst, der
## dort 55–60 % deckt: Die abgedunkelte Fernborke lag auf dem Wert des
## fernen Talwalds und des Himmelsdunsts, die Krone las sich als ein paar
## blasse Schirmkiefern. Stamm, Krone und ferne Kehle zeichnen deshalb ihren
## Nebel selbst (FOG im Stoff, gl_compatibility-tauglich), mit gleicher
## Farbe, Strecke und Kurve wie die Umgebung, aber nur zu `NEBEL_ANTEIL`:
## eine dunkelblaue Silhouette vor dem Dunst, dunkler als die Hügel davor
## (Plan 7, L4). Aus der Nähe (Wiese, Wendel) ändert das kaum etwas – dort
## deckt der Nebel ohnehin wenig. Der Stimmungsregler schreibt die Werte
## je Zone nach (`nebel_setzen`); die Stoffe sind Abschriften je Aufbau,
## die geteilten Borken- und Kronenstoffe bleiben unberührt.
const NEBEL_ANTEIL := 0.5
const NEBEL_UNIFORMS := """
uniform vec3 nebel_farbe = vec3(0.18, 0.31, 0.5);
uniform float nebel_von = 12.0;
uniform float nebel_bis = 140.0;
uniform float nebel_kurve = 1.1;
uniform float nebel_dichte = 0.0;
"""
const NEBEL_ZEILE := """
	FOG = vec4(nebel_farbe, pow(smoothstep(nebel_von, nebel_bis, length(VERTEX)), nebel_kurve)
			* nebel_dichte);
"""

## Die Abschriften mit eigenem Nebel dieses Aufbaus.
static var _nebel_eigen: Array[ShaderMaterial] = []
## Shader mit eigenem Nebel je Quellshader (einmal übersetzt, nie verändert).
static var _nebel_shader := {}


# ================================================================ Vertrag

## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Der Weltenbaum wächst", "tun": func() -> void: _baum_bauen(level)},
		{"text": "Die Wurzelwendel windet sich", "tun": func() -> void: _kehle_bauen(level)},
		{"text": "Das Kronentor", "tun": func() -> void: _kronentor_bauen(level)},
	]


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "weltenbaum"
## (Innenflanke, Rindenwulst, Oberwurzel, Wurzelkörper). Die Kehle wird in
## Stücken gebaut (siehe Kopf), passgenau auf eben diese Kollision; hier
## steht deshalb nur ein leerer Knoten – kein grauer Platzhalter.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	var leer := Node3D.new()
	leer.name = "Optik"
	return leer


## Radius des Stamms (ohne Rippen) in der Welthöhe `y`.
static func stamm_radius(y: float) -> float:
	return Weltenbaum.profil_radius(_profil(), y)


## Die Stoffe mit eigenem Nebel dieses Aufbaus (Stamm, Krone, ferne
## Kehle) – für den Stimmungsregler.
static func nebel_stoffe() -> Array[ShaderMaterial]:
	return _nebel_eigen


## Schreibt Farbe, Strecke, Kurve und Dichte des Nebels der Umgebung in
## einen Stoff mit eigenem Nebel (Dichte mal `NEBEL_ANTEIL`). Die Farbe
## geht linear in den Shader, wie der Renderer sein Nebellicht rechnet.
static func nebel_setzen(stoff: ShaderMaterial, umgebung: Environment) -> void:
	var c := umgebung.fog_light_color.srgb_to_linear()
	var e := umgebung.fog_light_energy
	stoff.set_shader_parameter("nebel_farbe", Vector3(c.r, c.g, c.b) * e)
	stoff.set_shader_parameter("nebel_von", umgebung.fog_depth_begin)
	stoff.set_shader_parameter("nebel_bis", umgebung.fog_depth_end)
	stoff.set_shader_parameter("nebel_kurve", umgebung.fog_depth_curve)
	stoff.set_shader_parameter("nebel_dichte",
			umgebung.fog_density * NEBEL_ANTEIL if umgebung.fog_enabled else 0.0)


## Achse des Stamms in Weltkoordinaten (y = 0).
static func achse() -> Vector3:
	var a: Vector2 = Level01.WELTENBAUM["achse"]
	return Vector3(a.x, 0.0, a.y)


# ================================================================ Rahmen

## Querrahmen des Weges an einer Stelle: Ursprung auf der Decke in der
## Wegmitte, `r` waagerecht nach rechts (außen), `v` voraus.
class Rahmen:
	var o := Vector3.ZERO
	var r := Vector3.RIGHT
	var v := Vector3.FORWARD

	func p(q: float, h: float) -> Vector3:
		return o + r * q + Vector3.UP * h


## Rahmen entlang des Weges, zwischengespeichert – jede Stelle wird für
## viele Querschnittspunkte gebraucht.
class Bahn:
	var level: Level01
	var _merk := {}

	func _init(l: Level01) -> void:
		level = l

	func rahmen(s: float) -> Rahmen:
		var k := roundi(s * 1000.0)
		if _merk.has(k):
			return _merk[k]
		var ra := Rahmen.new()
		ra.o = LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
		ra.o.y = level.boden_bei(s)
		ra.v = LevelWerkzeuge.richtung(level.verlauf, s)
		ra.r = ra.v.cross(Vector3.UP).normalized()
		_merk[k] = ra
		return ra

	func p(s: float, q: float, h: float) -> Vector3:
		return rahmen(s).p(q, h)


static func _profil() -> PackedVector2Array:
	return PackedVector2Array(PROFIL)


# ================================================================ Baum

static func _baum_bauen(level: Level01) -> void:
	_nebel_eigen.clear()
	var baum := Node3D.new()
	baum.name = "Weltenbaum"
	baum.position = achse()
	level.deko.add_child(baum)
	var bahn := Bahn.new(level)
	var o := _stamm_optionen(level, bahn)

	# Nah: mit allem Beiwerk. Die Schattenstufen zeichnet der schlichte
	# Schattenkörper – die Rippen sähe im Schatten niemand.
	var st := Riesenstamm.bauer()
	var info := Weltenbaum.stamm_in(st, o)
	var nah := _knoten(baum, "StammNah", Riesenstamm.fertig(st),
			_nebelarm(Weltenbaum.stoff_stamm(false), level), false)
	nah.visibility_range_end = NAH_BIS
	nah.visibility_range_end_margin = RAND

	# Der Südwestast (163°) hängt über dem Regal; sein Schatten lag im
	# Schlussbild über dem ganzen vorderen Regal, das dunkelste Bild des
	# Levels (Plan 5F: „das Regal liegt selbst in Sonne"). Der Schattenkörper
	# lässt ihn aus – sichtbar bleibt er, und das Kronentor an ihm wirft
	# seinen Schatten weiter.
	var schatten := Riesenstamm.bauer()
	var so := o.duplicate()
	var schatten_aeste: Array = []
	for a: Dictionary in o["aeste"]:
		var kopie := a.duplicate()
		kopie["weglassen"] = absf(rad_to_deg(float(a["winkel"])) - 163.0) < 1.0
		schatten_aeste.append(kopie)
	so["aeste"] = schatten_aeste
	so["seiten"] = 18
	so["ring_abstand"] = 6.0
	so["schrumpfen"] = 0.95
	so["mit_wurzeln"] = true
	Weltenbaum.stamm_schlicht_in(schatten, so)
	var sk := _knoten(baum, "StammSchatten", Riesenstamm.fertig(schatten),
			Weltenbaum.stoff_stamm(true), true)
	sk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

	var fern_st := Riesenstamm.bauer()
	var fo := o.duplicate()
	fo["seiten"] = 28
	fo["ring_abstand"] = 4.0
	fo["schrumpfen"] = 0.985
	fo["mit_wurzeln"] = true
	Weltenbaum.stamm_schlicht_in(fern_st, fo)
	var fern := _knoten(baum, "StammFern", Riesenstamm.fertig(fern_st),
			_nebelarm(Weltenbaum.stoff_stamm(true), level), false)
	fern.visibility_range_begin = FERN_AB
	fern.visibility_range_begin_margin = RAND

	# Krone: an den Astspitzen und darüber ein Schirm. Die grobe Fassung
	# steht immer; der Sektor über Wendel und Regal hat dazu eine feine
	# Nahfassung mit Blattkarten. Deren Hülle ist klein genug, dass sie von
	# der Wiese und dem Anfang der Wendel aus weggelassen wird.
	var ballen := _kronenballen(info)
	var fein: Array = []
	var grob: Array = []
	for b: Dictionary in ballen:
		if bool(b.get("grob", false)):
			grob.append(b)
			continue
		fein.append(b)
		# Der grobe Zwilling liegt flacher und etwas kleiner innen im feinen.
		var zwilling := b.duplicate()
		zwilling["radius"] = float(b["radius"]) * 0.9
		zwilling["hoehe"] = float(b["radius"]) * 0.55
		grob.append(zwilling)
	_knoten(baum, "Krone", Weltenbaum.krone(grob, true),
			_nebelarm(Weltenbaum.stoff_krone(true), level), false)
	var krone_nah := _knoten(baum, "KroneNah", Weltenbaum.krone(fein, false),
			_nebelarm(Weltenbaum.stoff_krone(false), level), false)
	krone_nah.visibility_range_end = KRONE_NAH_BIS
	krone_nah.visibility_range_end_margin = RAND
	_fussfarne(baum)


## Eine Abschrift von `stoff` mit eigenem Nebel (siehe `NEBEL_ANTEIL`),
## eingestellt auf die Umgebung des Levels und für den Regler vermerkt. Der
## Shader entsteht einmal je Quellshader; ohne passende Stelle im Code
## bleibt der Stoff, wie er ist.
static func _nebelarm(stoff: Material, level: Level01) -> Material:
	var alt := stoff as ShaderMaterial
	if alt == null or alt.shader == null:
		return stoff
	var shader: Shader = _nebel_shader.get(alt.shader)
	if shader == null:
		const MARKE := "void fragment() {"
		var code := alt.shader.code
		if code.count(MARKE) != 1 or code.contains("FOG"):
			push_warning("L01Weltenbaum: Stoff ohne eigenen Nebel (Shader unerwartet).")
			return stoff
		shader = Shader.new()
		shader.code = code.replace(MARKE, NEBEL_UNIFORMS + "\n" + MARKE + NEBEL_ZEILE)
		_nebel_shader[alt.shader] = shader
	var neu := alt.duplicate() as ShaderMaterial
	neu.shader = shader
	var welt := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if welt != null and welt.environment != null:
		nebel_setzen(neu, welt.environment)
	_nebel_eigen.append(neu)
	return neu


## Große Farne in den Spalten zwischen den Brettwurzeln des freien Sektors:
## Von der Bachwiese aus füllen sie die dunklen Kehlen am Stammfuß. Ein
## MultiMesh, ohne Schatten, bis 70 m.
static func _fussfarne(baum: Node3D) -> void:
	var rng := PropWerkzeug.zufall(6071)
	var lagen: Array[Transform3D] = []
	for i in 5:
		var a: Dictionary = BRETTWURZELN[i]
		var b: Dictionary = BRETTWURZELN[i + 1]
		var w0 := deg_to_rad(float(a["winkel"]))
		var w1 := deg_to_rad(float(b["winkel"]))
		var y := (float(a["fuss_y"]) + float(b["fuss_y"])) * 0.5
		for k in 3:
			var w := lerpf(w0, w1, rng.randf_range(0.28, 0.72))
			var r := stamm_radius(y) + rng.randf_range(0.6, 3.4)
			var ort := Vector3(cos(w) * r, y - 0.15, -sin(w) * r)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(
					Vector3.ONE * rng.randf_range(0.9, 1.5))
			lagen.append(Transform3D(basis, ort))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Farnwerk.gross(73)
	mm.instance_count = lagen.size()
	for k in lagen.size():
		mm.set_instance_transform(k, lagen[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Fussfarne"
	mmi.multimesh = mm
	mmi.material_override = Farnwerk.stoff(FARN_FARBE)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 70.0
	mmi.visibility_range_end_margin = RAND
	baum.add_child(mmi)


## Die Optionen für `Weltenbaum.stamm_in` – Beiwerk dort, wo man es sieht:
## Konsolenpilze und Leuchtpilze auf der Stammwand knapp über der Kehle,
## Efeu und Knollen auf der freien Seite (Bachwiese, Regal).
static func _stamm_optionen(level: Level01, bahn: Bahn) -> Dictionary:
	var rng := PropWerkzeug.zufall(4711)
	var wurzeln: Array = []
	for w: Dictionary in BRETTWURZELN:
		var neu := w.duplicate()
		neu["winkel"] = deg_to_rad(float(w["winkel"]))
		wurzeln.append(neu)
	var aeste: Array = []
	for a: Dictionary in AESTE:
		var neu := a.duplicate()
		neu["winkel"] = deg_to_rad(float(a["winkel"]))
		neu["zweige"] = 2
		aeste.append(neu)
	# Beiwerk entlang der Wendel: je Stelle der Winkel etwas voraus (dort
	# schaut die Kamera auf die Stammwand) und die Höhe über dem Fleisch.
	var pilze: Array = []
	var leuchten: Array = []
	var s := 203.0
	while s < 284.0:
		var p := bahn.p(s, 0.0, 0.0)
		var w := _winkel(p) + deg_to_rad(rng.randf_range(16.0, 34.0))
		var y := p.y + FLANKE_KOPF + rng.randf_range(2.5, 6.5)
		if rng.randf() < 0.6:
			pilze.append({"winkel": w, "y": y, "breite": rng.randf_range(1.1, 1.7)})
		if rng.randf() < 0.45:
			leuchten.append({"winkel": w + deg_to_rad(rng.randf_range(-12.0, 12.0)),
					"y": p.y + FLANKE_KOPF + rng.randf_range(0.8, 2.0)})
		s += rng.randf_range(9.0, 14.0)
	# Freie Seite: Konsolen und Leuchtpilze in Augenhöhe der Bachwiese.
	for w_grad: float in [199.0, 238.0, 271.0]:
		pilze.append({"winkel": deg_to_rad(w_grad), "y": rng.randf_range(12.0, 18.0),
				"breite": rng.randf_range(1.3, 1.9)})
		leuchten.append({"winkel": deg_to_rad(w_grad + rng.randf_range(-6.0, 6.0)),
				"y": rng.randf_range(8.0, 10.5)})
	var efeu: Array = []
	for w_grad: float in [194.0, 262.0]:
		efeu.append({"winkel": deg_to_rad(w_grad), "von": 6.5,
				"bis": rng.randf_range(20.0, 28.0), "blatt": 0.4, "band": 1.5})
	# Maserknollen klein und hoch: Mit 1,6–2,4 m Radius lagen sie über den
	# Brettwurzeln wie Brotlaibe am Stamm.
	var knollen: Array = []
	for w_grad: float in [214.0, 150.0]:
		knollen.append({"winkel": deg_to_rad(w_grad), "y": rng.randf_range(18.0, 26.0),
				"radius": rng.randf_range(0.8, 1.2)})
	return {
		"profil": _profil(),
		"y_von": -4.0,
		"y_bis": 60.0,
		"rippen": 30,
		"rippen_tiefe": 0.04,
		"drehung": 0.5,
		"ring_min": 1.7,
		"ring_max": 3.8,
		"streifen": 0.6,
		"saat": 2101,
		"boden": func(winkel: float) -> float: return _boden_am_fuss(winkel),
		"verdeckung": func(p: Vector3) -> float: return _stamm_verdeckung(level, p),
		"brettwurzeln": wurzeln,
		"aeste": aeste,
		"pilze": pilze,
		"leuchten": leuchten,
		"efeu": efeu,
		"knollen": knollen,
	}


## Boden rund um den Stammfuß: im Norden und Osten die Wurzelgruben, sonst
## der Knoll (Plan 8.4). Nur für Verdeckung und Moos am Fuß.
static func _boden_am_fuss(winkel: float) -> float:
	var grad := rad_to_deg(wrapf(winkel, -PI, PI))
	var gruben := smoothstep(-40.0, -15.0, grad) * (1.0 - smoothstep(125.0, 150.0, grad))
	return lerpf(6.0, -2.0, gruben)


## Dunkler, wo die Stammwand gleich über dem Wurzelfleisch liegt: Die Kehle
## soll tief wirken, nicht wie ein Band, das außen am Stamm klebt.
static func _stamm_verdeckung(level: Level01, p: Vector3) -> float:
	var s := _s_bei_winkel(atan2(-p.z, p.x))
	if is_nan(s):
		return 1.0
	var kopf := level.boden_bei(s) + FLANKE_KOPF
	return lerpf(0.6, 1.0, smoothstep(kopf - 1.0, kopf + 4.0, p.y))


## Strecke der Wendel, die bei diesem Winkel (Achsraum, 0 = Osten) liegt;
## NAN außerhalb der Wendel und des Regals.
static func _s_bei_winkel(w: float) -> float:
	var grad := rad_to_deg(w)
	if grad < -50.0:
		return NAN
	if grad <= 146.0:
		return 215.0 + (grad + 1.3) / 2.56
	if grad <= 182.0:
		return 273.0 + (grad - 146.0) / 2.43
	return NAN


static func _winkel(p: Vector3) -> float:
	var d := p - achse()
	return atan2(-d.z, d.x)


## Die Ballen des Kronenschirms im Achsraum. An jeder Astspitze ein großer
## Ballen, an den Zweigen kleinere, dazwischen ein Ring und oben die Kuppe.
## Fein (mit Blattkarten) nur im Sektor, unter dem die Wendel ab E3 und das
## Regal liegen (Norden bis Südwesten): Nur von dort sieht man die Krone
## aus der Nähe von unten. Die übrigen sind auch in der Nahfassung "grob"
## (wie die Fernfassung) – von Grat und Wiese aus liegen sie weit weg oder
## über dem Bildrand, und jeder feine Ballen kostet gut tausend Dreiecke.
static func _kronenballen(info: Dictionary) -> Array:
	var rng := PropWerkzeug.zufall(8123)
	var ballen: Array = []
	var spitzen: PackedVector3Array = info["ast_spitzen"]
	var zweige: PackedVector3Array = info["zweig_spitzen"]
	for p in spitzen:
		var fein := _kronen_sektor(p)
		ballen.append({"mitte": p + Vector3(0.0, 1.2, 0.0), "radius": rng.randf_range(10.0, 11.5),
				"variante": 1, "saat": rng.randi_range(1, 99999), "grob": not fein,
				"ballen": 4, "karten": 80})
	# Je Ast ein Zweigballen (der zweite Zweig trägt nur Laub der Nachbarn).
	for k in range(0, zweige.size(), 2):
		var p := zweige[k]
		ballen.append({"mitte": p + Vector3(0.0, 0.8, 0.0), "radius": rng.randf_range(6.5, 8.0),
				"variante": 1, "saat": rng.randi_range(1, 99999), "grob": not _kronen_sektor(p),
				"ballen": 2, "karten": 40})
	for k in 5:
		var w := deg_to_rad(float(AESTE[k]["winkel"]) + 36.0 + rng.randf_range(-8.0, 8.0))
		var d := rng.randf_range(15.0, 19.0)
		var mitte := Vector3(cos(w) * d, rng.randf_range(46.0, 50.0), -sin(w) * d)
		ballen.append({"mitte": mitte, "radius": rng.randf_range(11.0, 12.5), "variante": 1,
				"saat": rng.randi_range(1, 99999), "grob": not _kronen_sektor(mitte),
				"ballen": 3, "karten": 30})
	# Der Kronenvorhang über dem Regal: Laub, das vom Südwestast weit über das
	# Tal hinaushängt. Aus dem Schlussbild (Blick nach Südwesten, gegen die
	# Sonne) ist er das dunkle obere Band; über dem Weg bleibt er ≥ 9,5 m.
	for vorhang: Vector4 in [Vector4(163.0, 43.0, 34.8, 9.0), Vector4(185.0, 42.0, 33.6, 9.0),
			Vector4(200.0, 41.0, 32.8, 9.5), Vector4(216.0, 40.0, 33.2, 9.0)]:
		var w := deg_to_rad(vorhang.x)
		ballen.append({"mitte": Vector3(cos(w) * vorhang.y, vorhang.z, -sin(w) * vorhang.y),
				"radius": vorhang.w, "variante": 1, "saat": rng.randi_range(1, 99999),
				"ballen": 4, "karten": 80})
	ballen.append({"mitte": Vector3(0.0, 57.0, 0.0), "radius": 17.0, "variante": 1,
			"saat": 31, "ballen": 5, "grob": true})
	ballen.append({"mitte": Vector3(1.5, 64.0, -1.0), "radius": 10.5, "variante": 0,
			"saat": 37, "ballen": 4, "grob": true})
	# Der Schirm: eine flache, geschlossene Masse unter den Ballen (Unterseite
	# gut 35, Oberseite gut 46). Ohne ihn stand vom Grat aus zwischen den
	# Ballen der Himmel, und die Krone las sich aus 150 m als fünf, sechs
	# einzelne Schirmkiefern auf dem Wert des Talwalds; so ist sie EINE
	# dunkle Kronenmasse mit dunkler Unterseite.
	ballen.append({"mitte": Vector3(-1.0, 40.5, 1.0), "radius": 29.0, "hoehe": 11.0,
			"variante": 1, "saat": 41, "ballen": 4, "grob": true})
	return ballen


## Liegt ein Punkt (Achsraum) im Sektor der feinen Krone, Norden bis
## Südwesten (Winkel 70°–235°)?
static func _kronen_sektor(p: Vector3) -> bool:
	var grad := rad_to_deg(atan2(-p.z, p.x))
	if grad < 0.0:
		grad += 360.0
	return grad >= 70.0 and grad <= 235.0


# ================================================================ Kehle

## Die Wurzelkehle: nah in Stücken, dazu Schattenkörper und Fernfassung.
static func _kehle_bauen(level: Level01) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Wurzelkehle"
	level.deko.add_child(wurzel)
	var bahn := Bahn.new(level)

	var nah := _ziel(false)
	_kehle_in(nah, bahn, level, "nah")
	var holz := Weltenbaum.stoff_wurzel()
	for i in (nah["stuecke"] as Array).size():
		var stueck: Dictionary = nah["stuecke"][i]
		if bool(stueck["leer_holz"]):
			continue
		var st: SurfaceTool = stueck["holz"]
		st.index()
		st.generate_tangents()
		var netz := st.commit()
		netz.surface_set_material(0, holz)
		var mi := MeshInstance3D.new()
		mi.name = "Kehle%d" % i
		mi.mesh = netz
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = NAH_BIS
		mi.visibility_range_end_margin = RAND
		wurzel.add_child(mi)
	_farne_setzen(wurzel, bahn, level)
	_vorhaenge_bauen(wurzel, bahn, level)

	var schatten := _ziel(true)
	_kehle_in(schatten, bahn, level, "schatten")
	var sk := _knoten(wurzel, "KehleSchatten", Riesenstamm.fertig(schatten["einer"]), holz, true)
	sk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

	var fern := _ziel(true)
	_kehle_in(fern, bahn, level, "fern")
	# Fern in der dunklen Fernborke des Stamms: Aus 150 m sind Furchen nicht
	# zu sehen, wohl aber, ob sich die Wendel vom Dunst abhebt.
	var fk := _knoten(wurzel, "KehleFern", Riesenstamm.fertig(fern["einer"]),
			_nebelarm(Weltenbaum.stoff_stamm(true), level), false)
	fk.visibility_range_begin = FERN_AB
	fk.visibility_range_begin_margin = RAND

	_sichtkoerper_boegen(wurzel, bahn, level)


## Ein Sammelziel: nah je Stück ein Sammler (Wurzelborke), grob (Schatten,
## Ferne) ein einziger.
static func _ziel(grob: bool) -> Dictionary:
	var ziel := {"grob": grob, "stuecke": [], "einer": null}
	if grob:
		ziel["einer"] = Riesenstamm.bauer()
		return ziel
	for v: Vector2 in STUECKE:
		(ziel["stuecke"] as Array).append({"von": v.x, "bis": v.y,
				"holz": Riesenstamm.bauer(), "leer_holz": true})
	return ziel


## Der Sammler für ein Stück der Kehle an der Stelle `s`.
static func _st_bei(ziel: Dictionary, s: float, art: String = "holz") -> SurfaceTool:
	if bool(ziel["grob"]):
		return ziel["einer"]
	var stuecke: Array = ziel["stuecke"]
	for stueck: Dictionary in stuecke:
		if s >= float(stueck["von"]) and s < float(stueck["bis"]):
			stueck["leer_" + art] = false
			return stueck[art]
	var letztes: Dictionary = stuecke[stuecke.size() - 1] if s >= 200.0 else stuecke[0]
	letztes["leer_" + art] = false
	return letztes[art]


## Verteilt ein Gitter mit den Stellen `g["s"]` auf die Stücke.
static func _verteilen(ziel: Dictionary, g: Dictionary, art: String = "holz",
		filter: Callable = Callable()) -> void:
	if bool(ziel["grob"]):
		Weltenbaum.gitter_schreiben(ziel["einer"], g, 0, -1, filter)
		return
	var s_werte: PackedFloat32Array = g["s"]
	for stueck: Dictionary in ziel["stuecke"]:
		var von: float = stueck["von"]
		var bis: float = stueck["bis"]
		var erste := -1
		var letzte := -1
		for i in s_werte.size() - 1:
			if s_werte[i] >= von and s_werte[i] < bis:
				if erste < 0:
					erste = i
				letzte = i
		if erste < 0:
			continue
		stueck["leer_" + art] = false
		Weltenbaum.gitter_schreiben(stueck[art], g, erste, letzte + 1, filter)


## Alles, was zur Kehle gehört, in ein Ziel. `stufe`: "nah", "schatten"
## (schlicht, knapp innerhalb der sichtbaren Form) oder "fern".
static func _kehle_in(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String) -> void:
	var rng := PropWerkzeug.zufall(6007)
	if stufe == "nah":
		_flanke_straenge(ziel, bahn, level)
		_flanke_grund(ziel, bahn, level, 1.2)
		_faserwurzeln(ziel, bahn, level, PropWerkzeug.zufall(6017))
		_flankenfuss(ziel, bahn, level)
		_knorren_bauen(ziel, bahn, level)
		_brueche(ziel, bahn, level, rng)
		_pilze_in_rissen(ziel, bahn, level, rng)
		_regalende(ziel, bahn, level)
	else:
		_flanke_grob(ziel, bahn, level, stufe)
	_aussenwurzel(ziel, bahn, level, stufe)
	_unterbau(ziel, bahn, level, stufe)
	_seitenwurzeln(ziel, bahn, level, stufe, PropWerkzeug.zufall(6011))
	_oberwurzel(ziel, bahn, level, stufe)
	_wurzelboegen(ziel, bahn, level, stufe, PropWerkzeug.zufall(6013))


## Stellen von `von` bis `bis` im Abstand `schritt` (beide Enden dabei).
static func _stellen(von: float, bis: float, schritt: float) -> PackedFloat32Array:
	var n := maxi(ceili((bis - von) / schritt), 1)
	var werte := PackedFloat32Array()
	for i in n + 1:
		werte.append(lerpf(von, bis, float(i) / float(n)))
	return werte


## Gitter aus Querschnitten in Wegkoordinaten. `profile[i]`: Punkte
## Vector2(q, h) an der Stelle `s_werte[i]`, `farben[i]` je Punkt
## (rgb Verdeckung, a Moos), `kerne[i]` ein Punkt im Innern (für die
## Vorderseite). Liefert ein Gitter für `_verteilen`.
static func _loft(bahn: Bahn, s_werte: PackedFloat32Array, profile: Array,
		farben: Array, kerne: Array, ringsum: bool, uv_mass: float, nord: float) -> Dictionary:
	var schnitte: Array[PackedVector3Array] = []
	var welt_kerne := PackedVector3Array()
	for i in s_werte.size():
		var ra := bahn.rahmen(s_werte[i])
		var schnitt := PackedVector3Array()
		for p: Vector2 in profile[i]:
			schnitt.append(ra.p(p.x, p.y))
		schnitte.append(schnitt)
		var k: Vector2 = kerne[i]
		welt_kerne.append(ra.p(k.x, k.y))
	var g := Weltenbaum.zug(schnitte, s_werte, ringsum, {"uv_mass": uv_mass})
	Weltenbaum.gitter_faerben(g, _weiss, nord)
	var kern := func(i: int) -> Vector3: return welt_kerne[i]
	Weltenbaum.orientieren(g, kern)
	var fa: Array = []
	for i in farben.size():
		var reihe: PackedColorArray = (farben[i] as PackedColorArray).duplicate()
		if ringsum:
			reihe.append(reihe[0])
		fa.append(reihe)
	g["f"] = fa
	g["s"] = s_werte
	return g


## Farbe für `gitter_faerben`, wenn die eigentlichen Farben danach kommen.
static func _weiss(_p: Vector3, _n: Vector3) -> Color:
	return Color.WHITE


# ---------------------------------------------------------------- Flanke

## Normale der Flankenebene im Querschnitt: zum Weg und nach oben.
static func _flanken_normale() -> Vector2:
	return Vector2(FLANKE_KOPF, FLANKE_TIEFE).normalized()


## Fuß der Innenflanke (q an der Decke). Bis 273,5 die Wegkante, im Regal
## die Leitlinie „Stammseite F", davor am Aufgang die Leitlinie „Links".
static func _flanke_fuss(s: float) -> float:
	if s < FLANKE_VON:
		# Leitlinie Links: (194,5 | −6,8) → (198,5 | −4,6)
		return lerpf(-6.8, -4.6, clampf((s - 194.5) / 4.0, 0.0, 1.0))
	if s <= 272.5:
		return -4.0
	var ql := lerpf(-4.1, -6.1, clampf((s - 272.5) / 14.8, 0.0, 1.0)) - 0.05
	return lerpf(-4.0, ql, smoothstep(272.5, 274.0, s))


## Punkt auf der Flankenebene, `t` 0 (Fuß) … 1 (Kopf, +9).
static func _flanke_punkt(s: float, t: float) -> Vector2:
	return Vector2(_flanke_fuss(s) - FLANKE_TIEFE * t, FLANKE_KOPF * t)


## Wie weit ein Punkt VOR der Flankenebene liegt (> 0 heißt: zum Weg hin).
static func _vor_flanke(s: float, p: Vector2) -> float:
	var n := _flanken_normale()
	return (p.x - _flanke_fuss(s)) * n.x + p.y * n.y


## Schiebt einen Punkt hinter die Kollision der Flanke zurück: unter der
## Decke hinter die Wegkante, darüber hinter die Ebene, über dem Kopf
## hinter dessen Kante. Nur wo die Kollision steht (sonst gilt die
## Leitlinie, und die Stränge tauchen dort aus dem Boden).
static func _klemmen(s: float, p: Vector2) -> Vector2:
	if s < FLANKE_VON - 0.5:
		return p
	var fuss := _flanke_fuss(s)
	if p.y <= 0.0:
		return Vector2(minf(p.x, fuss), p.y)
	if p.y >= FLANKE_KOPF:
		return Vector2(minf(p.x, fuss - FLANKE_TIEFE + 0.4), p.y)
	var d := _vor_flanke(s, p)
	if d > 0.0:
		return p - _flanken_normale() * d
	return p


## Lage eines Strangs an der Stelle s: Vector3(t auf der Flanke, Radius,
## Rücksprung hinter die Ebene). Strang 0 liegt am Fuß, 1 und 2 flechten
## sich umeinander (wer vorn liegt, berührt die Ebene, der andere taucht
## dahinter weg), 3 liegt oben am Stamm, 4 ist ein dünner Strang, der
## schräg über alle hinwegläuft.
static func _strang(i: int, s: float) -> Vector3:
	var phi := TAU * s / 20.0 + 0.7
	match i:
		0:
			return Vector3(0.07 + 0.015 * sin(s / 9.1),
					1.2 + 0.18 * sin(s / 6.3 + 1.0),
					0.05 + 0.12 * (0.5 + 0.5 * sin(s / 7.7)))
		1:
			return Vector3(0.5 - 0.15 * cos(phi), 1.4 * (1.0 + 0.16 * sin(s / 5.1)),
					2.4 * pow(maxf(0.0, -sin(phi)), 0.8))
		2:
			return Vector3(0.5 + 0.15 * cos(phi), 1.6 * (1.0 + 0.14 * sin(s / 4.3 + 2.0)),
					2.4 * pow(maxf(0.0, sin(phi)), 0.8))
		3:
			return Vector3(0.86 + 0.04 * sin(s / 11.0 + 0.4), 1.3 * (1.0 + 0.14 * sin(s / 6.9)),
					0.2 + 0.3 * (0.5 + 0.5 * sin(s / 8.3 + 1.2)))
		_:
			return Vector3(0.5, 0.6 + 0.1 * sin(s / 3.7), 0.0)


## Die Stränge in Stücken. Wo ein Stück endet, verjüngt es sich und taucht
## hinter die anderen ins Fleisch – so läuft kein Strang als endloser
## Schlauch um den Baum. "t": beim dünnen Strang 4 die Lage auf der Flanke
## (Anfang, Ende), sonst ein Versatz dazu.
const STRANG_STUECKE := [
	{"strang": 0, "von": 185.0, "bis": 291.0, "t": Vector2.ZERO},
	{"strang": 1, "von": 185.0, "bis": 291.0, "t": Vector2.ZERO},
	{"strang": 2, "von": 185.0, "bis": 291.0, "t": Vector2.ZERO},
	{"strang": 3, "von": 186.0, "bis": 224.0, "t": Vector2(0.0, 0.03)},
	{"strang": 3, "von": 219.0, "bis": 252.0, "t": Vector2(0.04, -0.02)},
	{"strang": 3, "von": 247.0, "bis": 291.0, "t": Vector2(-0.02, 0.02)},
	{"strang": 4, "von": 199.0, "bis": 214.0, "t": Vector2(0.22, 0.8)},
	{"strang": 4, "von": 223.0, "bis": 241.0, "t": Vector2(0.82, 0.2)},
	{"strang": 4, "von": 251.0, "bis": 267.0, "t": Vector2(0.25, 0.78)},
	{"strang": 4, "von": 274.0, "bis": 288.0, "t": Vector2(0.72, 0.3)},
]


## Am Aufgang (vor 198) steigen die Stränge aus dem Knoll: je höher ein
## Strang auf der Flanke liegt, desto früher taucht er auf. Am Ende des
## Regals tauchen alle wieder in den Boden.
static func _auftauchen(s: float, t: float, r: float) -> Vector2:
	var versatz := Vector2.ZERO
	var laenge := 6.0 + 7.0 * t
	var f := 1.0 - smoothstep(198.0 - laenge, 198.0, s)
	if f > 0.0:
		versatz += Vector2(-1.8 * f, -(FLANKE_KOPF * t + r + 1.5) * f)
	versatz.y -= _abtauchen(s)
	return versatz


## Wie tief die Wurzel hinter dem Wegende in den Knoll taucht.
static func _abtauchen(s: float) -> float:
	if s <= ENDE:
		return 0.0
	var d := s - ENDE
	return 0.9 * d * d


## Die Stränge des Wurzelfleischs als Ringe in Querschnitten. Der
## Querschnitt ist flach gedrückt (breiter entlang der Flanke als tief),
## Knoten machen ihn stellenweise dicker – nach hinten und zur Seite, nie
## über die Ebene hinaus.
static func _flanke_straenge(ziel: Dictionary, bahn: Bahn, _level: Level01) -> void:
	var n := _flanken_normale()
	var hang := Vector2(-FLANKE_TIEFE, FLANKE_KOPF).normalized()
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5501
	rauschen.frequency = 0.35
	var flecken := FastNoiseLite.new()
	flecken.seed = 5503
	flecken.frequency = 0.16
	var knoten_rng := PropWerkzeug.zufall(5509)
	for nummer in STRANG_STUECKE.size():
		var stueck: Dictionary = STRANG_STUECKE[nummer]
		var i: int = stueck["strang"]
		var von: float = stueck["von"]
		var bis: float = stueck["bis"]
		var t_lage: Vector2 = stueck["t"]
		var offen_vorn := von > 185.5
		var offen_hinten := bis < 290.5
		var seiten := 10 if i < 4 else 7
		# Knoten: kurze Schwellungen an zufälligen Stellen.
		var knoten: Array[Vector2] = []
		var k_s := von + knoten_rng.randf_range(2.0, 7.0)
		while k_s < bis:
			knoten.append(Vector2(k_s, knoten_rng.randf_range(0.2, 0.45)))
			k_s += knoten_rng.randf_range(5.0, 10.0)
		var s_werte := _stellen(von, bis, 0.95)
		var profile: Array = []
		var farben: Array = []
		var kerne: Array = []
		var sicht: Array = []
		# Die Naht liegt hinten (in der Flanke), wo man sie nie sieht.
		var start := atan2(n.y, n.x) + PI
		for s in s_werte:
			var lage := _strang(i, s)
			var u := inverse_lerp(von, bis, s)
			var t := lage.x + lerpf(t_lage.x, t_lage.y, u)
			if i == 4:
				t = lerpf(t_lage.x, t_lage.y, smoothstep(0.0, 1.0, u))
			var r := lage.y
			var zurueck := lage.z
			# Enden: verjüngen und hinter die anderen tauchen.
			var ende := 1.0
			if offen_vorn:
				ende = minf(ende, smoothstep(von, von + 3.5, s))
			if offen_hinten:
				ende = minf(ende, 1.0 - smoothstep(bis - 3.5, bis, s))
			r *= lerpf(0.35, 1.0, ende)
			zurueck += (1.0 - ende) * (r + 1.4)
			var dick := 0.0
			for kn in knoten:
				dick += kn.y * exp(-pow((s - kn.x) / 1.3, 2.0))
			var breite := 1.35 * (1.0 + dick)
			var tiefe := 0.75 * (1.0 + dick * 0.8)
			var mitte := _flanke_punkt(s, t) - n * (r * tiefe + zurueck) + _auftauchen(s, t, r)
			var punkte := PackedVector2Array()
			var fa := PackedColorArray()
			var zu := PackedByteArray()
			for k in seiten:
				var a := start + TAU * float(k) / float(seiten)
				var d := n * cos(a) + hang * sin(a)
				# Beulen nur nach innen: Die Kuppe berührt die Ebene, nie mehr.
				var beule := 1.0 - 0.12 * (0.5 + 0.5 * rauschen.get_noise_2d(s * 1.7,
						float(k) * 2.3 + float(nummer) * 17.0))
				var p := _klemmen(s, mitte + (n * cos(a) * tiefe + hang * sin(a) * breite) * r * beule)
				punkte.append(p)
				var riss := clampf((-_vor_flanke(s, p) - 0.1) / 1.2, 0.0, 1.0)
				var ao := lerpf(1.0, 0.52, riss) * lerpf(0.8, 1.0, smoothstep(-0.4, 1.6, p.y))
				var moos := 0.06 + 0.5 * riss \
						+ 0.6 * maxf(0.0, flecken.get_noise_2d(s, float(nummer) * 9.0 + float(k) * 0.6)) \
						+ (0.2 if p.y < 1.2 else 0.0)
				fa.append(Color(ao, ao, ao, clampf(moos, 0.0, 1.0)))
				zu.append(1 if d.dot(n) > -0.4 else 0)
			profile.append(punkte)
			farben.append(fa)
			kerne.append(mitte)
			sicht.append(zu)
		var g := _loft(bahn, s_werte, profile, farben, kerne, true, 0.55, 0.25)
		var filter := func(zeile: int, spalte: int) -> bool:
			var za: PackedByteArray = sicht[zeile]
			var zb: PackedByteArray = sicht[zeile + 1]
			var j0 := spalte % seiten
			var j1 := (spalte + 1) % seiten
			return za[j0] + za[j1] + zb[j0] + zb[j1] > 0
		_verteilen(ziel, g, "holz", filter)


## Dünne Wurzeln, die schräg die Flanke hinablaufen – vom Stamm über die
## Kuppen der Stränge und über die Risse hinweg bis an die Wegkante. Sie
## brechen das waagerechte Band der Stränge und liegen mit ihrer Kuppe auf
## der Ebene, nie davor.
static func _faserwurzeln(ziel: Dictionary, bahn: Bahn, _level: Level01,
		rng: RandomNumberGenerator) -> void:
	var n := _flanken_normale()
	var s := 199.0 + rng.randf_range(0.0, 3.0)
	while s < 285.0:
		if (s > G1.x - 2.0 and s < G1.y + 1.0) or (s > G2.x - 2.0 and s < G2.y + 1.0):
			s += 2.5
			continue
		# Dichter und kräftiger als zuerst (alle 2–4,5 m, bis 0,34 m): Sie
		# zerteilen die großen, glatten Stränge, die sich von der Seite als
		# gestapelte Brotlaibe lasen.
		var laenge := rng.randf_range(2.0, 6.5) * (1.0 if rng.randf() < 0.5 else -1.0)
		var r := rng.randf_range(0.13, 0.34)
		var t_oben := rng.randf_range(0.7, 1.08)
		var t_unten := rng.randf_range(0.03, 0.3)
		var punkte := PackedVector3Array()
		var radien := PackedFloat32Array()
		var zeilen := 10
		for i in zeilen + 1:
			var u := float(i) / float(zeilen)
			var sp := s + laenge * u + 0.35 * sin(u * 7.0 + s)
			var t := lerpf(t_oben, t_unten, u)
			var p := _klemmen(sp, _flanke_punkt(sp, t) - n * (r * 0.95))
			var ra := bahn.rahmen(sp)
			punkte.append(ra.p(p.x, p.y))
			radien.append(r * lerpf(1.25, 0.6, u))
		var g := Weltenbaum.rohr(punkte, radien, {"seiten": 6, "beulen": 0.12,
				"saat": rng.randi(), "ende": "spitz", "uv_mass": 1.2})
		Weltenbaum.gitter_faerben(g, _faserfarbe, 0.2)
		Weltenbaum.gitter_schreiben(_st_bei(ziel, s), g)
		s += rng.randf_range(2.0, 4.5)


static func _faserfarbe(_p: Vector3, nn: Vector3) -> Color:
	return Color(0.88, 0.88, 0.88, clampf(0.1 + nn.y * 0.3, 0.0, 1.0))


## Der dunkle Grund hinter den Strängen: eine Fläche parallel zur Ebene,
## 1,5–2,2 m dahinter, die oben in die Stammwand übergeht. Durch die Risse
## zwischen den Strängen sieht man sie – dunkel und bemoost, nie ins Leere.
static func _flanke_grund(ziel: Dictionary, bahn: Bahn, level: Level01, schritt: float) -> void:
	var s_werte := _stellen(185.0, 291.0, schritt)
	var n := _flanken_normale()
	var ts := [-0.06, 0.2, 0.45, 0.7, 0.95]
	var zurueck := [0.55, 1.8, 2.1, 1.9, 1.5]
	var profile: Array = []
	var farben: Array = []
	var kerne: Array = []
	for s in s_werte:
		var punkte := PackedVector2Array()
		var fa := PackedColorArray()
		for k in ts.size():
			var t: float = ts[k]
			var z: float = zurueck[k] * (1.0 + 0.18 * sin(s / 3.3 + float(k) * 1.9))
			var p := _flanke_punkt(s, t) - n * z + _auftauchen(s, t, 1.4)
			punkte.append(_klemmen(s, p))
			var ao := 0.38 if k > 0 else 0.28
			fa.append(Color(ao, ao, ao, 0.8 if k > 0 else 0.3))
		# Oben zur Stammwand hinüber.
		for hk: Vector2 in [Vector2(10.4, 0.35), Vector2(12.8, 0.7)]:
			var q_stamm := _stamm_q(bahn, level, s, hk.x)
			var q := minf(q_stamm + hk.y, _flanke_fuss(s) - FLANKE_TIEFE - 0.3)
			var p := Vector2(q, hk.x) + _auftauchen(s, 1.0, 1.4)
			punkte.append(p)
			fa.append(Color(0.42, 0.42, 0.42, 0.7))
		profile.append(punkte)
		farben.append(fa)
		kerne.append(_flanke_punkt(s, 0.5) - n * 6.0)
	var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.5, 0.3)
	_verteilen(ziel, g, "holz")


## q der Stammoberfläche (ohne Rippen) auf der Querlinie an der Stelle s in
## der Höhe h über der Decke – links vom Weg, wo die Linie den Stamm trifft.
static func _stamm_q(bahn: Bahn, _level: Level01, s: float, h: float) -> float:
	var ra := bahn.rahmen(s)
	var r_stamm := stamm_radius(ra.o.y + h)
	var d := Vector2(ra.o.x - achse().x, ra.o.z - achse().z)
	var rr := Vector2(ra.r.x, ra.r.z)
	var b := d.dot(rr)
	var disk := b * b - d.length_squared() + r_stamm * r_stamm
	if disk < 0.0:
		return -(d.length() - r_stamm)
	return -b + sqrt(disk)


## Schlichte Flanke für Schatten und Ferne: die Ebene selbst, knapp
## dahinter, und oben der Übergang zum Stamm.
static func _flanke_grob(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String) -> void:
	var s_werte := _stellen(188.0, 291.0, 3.2 if stufe == "schatten" else 2.5)
	var n := _flanken_normale()
	var zurueck := 0.45 if stufe == "schatten" else 0.25
	var profile: Array = []
	var farben: Array = []
	var kerne: Array = []
	for s in s_werte:
		var punkte := PackedVector2Array()
		var fa := PackedColorArray()
		for t: float in [-0.04, 0.35, 0.7, 1.0]:
			punkte.append(_flanke_punkt(s, t) - n * zurueck + _auftauchen(s, t, 1.3))
			fa.append(Color(0.7, 0.7, 0.7, 0.5))
		var q_stamm := _stamm_q(bahn, level, s, 11.5)
		punkte.append(Vector2(minf(q_stamm + 0.5, _flanke_fuss(s) - FLANKE_TIEFE - 0.3), 11.5)
				+ _auftauchen(s, 1.0, 1.3))
		fa.append(Color(0.5, 0.5, 0.5, 0.6))
		profile.append(punkte)
		farben.append(fa)
		kerne.append(_flanke_punkt(s, 0.5) - n * 6.0)
	var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.5, 0.3)
	_verteilen(ziel, g, "holz")


# ---------------------------------------------------------------- Außenwurzel

## Halbe Wegbreite (Kante), auch hinter dem Wegende.
static func _kante(level: Level01, s: float) -> float:
	var b := level.breite_bei(s)
	if b <= 0.0:
		b = 12.0 if s > 280.0 else 8.0
	return b * 0.5


## Querschnitt der Außenwurzel an der Stelle s, Vector2(q, h).
static func _aussenprofil(level: Level01, s: float, rauschen: FastNoiseLite) -> PackedVector2Array:
	var e := _kante(level, s)
	var kamm := smoothstep(G1.y, G1.y + 0.8, s) * (1.0 - smoothstep(272.4, 273.4, s))
	var lippe := smoothstep(272.4, 273.6, s)
	var flach := clampf(1.0 - kamm - lippe, 0.0, 1.0)
	# Der Leib wölbt sich ungleich weit hinaus – an den Seitenwurzeln mehr.
	var wulst := 1.0 + 0.22 * rauschen.get_noise_1d(s * 0.9) + 0.1 * sin(s / 2.9)
	var tief := 1.0 + 0.15 * sin(s / 5.7 + 0.4)
	var stellen := _seitenwurzel_stellen()
	for i in stellen.size():
		wulst += 0.35 * _seitenwurzel_dicke(i) * exp(-pow((s - stellen[i]) / 2.2, 2.0))
	# Knorren im Profil: flache Buckel außen am Kamm, jenseits der
	# Wulstkollision (q > 4,7) und unter ihrer Oberkante (+0,6) – nichts, was
	# man für begehbar hielte. Die großen Knorren sitzen als eigene Körper
	# darunter (`_knorren_bauen`).
	var knorren := 0.0
	for kn in _knorren():
		knorren += kn.y * exp(-pow((s - kn.x) / kn.z, 2.0))
	knorren *= kamm
	# Spalten: An drei Stellen teilt sich die Außenwurzel in zwei Stränge –
	# eine dunkle Fuge läuft mitten durch den Leib.
	var fuge := _fuge(s) * kamm
	var punkte := PackedVector2Array()
	for k in KAMM.size():
		var pk: Vector2 = KAMM[k]
		if k >= 6:
			pk = Vector2(0.55 + (pk.x - 0.55) * wulst, 0.46 + (pk.y - 0.46) * tief)
		if k >= 6 and k <= 9:
			var gewicht: float = [0.5, 0.85, 0.6, 0.25][k - 6]
			pk += Vector2(0.18, 1.0) * knorren * gewicht
		if k >= 8 and k <= 12:
			# Die Fuge zieht die Punkte 9–11 nach innen, der untere Strang
			# (12) wölbt sich dafür etwas hinaus.
			var ein: float = [0.1, 0.55, 0.85, 0.5, -0.22][k - 8]
			pk.x -= ein * fuge
		var pf: Vector2 = FLACH[k]
		var pl: Vector2 = _lippe_punkt(k, s, rauschen) if lippe > 0.0 else LIPPE[k]
		var p := pk * kamm + pf * flach + pl * lippe
		punkte.append(Vector2(e + p.x, p.y - _abtauchen(s)))
	return punkte


## Stärke der Fuge (0..1) an der Stelle s: drei Stellen, an denen sich die
## Außenwurzel in zwei Stränge teilt, mit weichem Ein- und Auslauf.
static func _fuge(s: float) -> float:
	var f := 0.0
	for z: Vector2 in [Vector2(219.5, 227.5), Vector2(236.5, 241.5), Vector2(259.5, 267.0)]:
		f = maxf(f, smoothstep(z.x, z.x + 1.8, s) * (1.0 - smoothstep(z.y - 1.8, z.y, s)))
	return f


## Wie weit die Lippe des Regals an der Stelle s nach außen buckelt
## (0–0,55 m, Buckel von 1,5–2 m): nur nach außen, jenseits der Kollision.
static func _regal_buckel(s: float, rauschen: FastNoiseLite) -> float:
	return clampf(0.24 + 0.4 * rauschen.get_noise_1d(s * 2.4 + 17.0)
			+ 0.16 * rauschen.get_noise_1d(s * 5.5 + 5.0), 0.0, 0.55)


## Punkt `k` der Regallippe an der Stelle s (siehe `LIPPE`): der Innenrand
## des Moospolsters nach Rauschen 0,3–0,65 m auf der Decke, die Außenseite
## um den Buckel hinaus (zum Bauch hin auslaufend).
static func _lippe_punkt(k: int, s: float, rauschen: FastNoiseLite) -> Vector2:
	var p: Vector2 = LIPPE[k]
	if k == 0:
		return Vector2(p.x - 0.35 * (0.5 + 0.5 * rauschen.get_noise_1d(s * 2.3 + 40.0)), p.y)
	var anteil := 1.0
	if k > 9:
		anteil = [0.7, 0.4, 0.15, 0.0, 0.0][k - 10]
	return p + Vector2(_regal_buckel(s, rauschen) * anteil, 0.0)


## Knorren im Profil: Vector3(s, Höhe, halbe Länge), fest gewürfelt.
## Höchstens 0,22 m, damit der Buckel unter der Wulstoberkante bleibt.
static func _knorren() -> Array[Vector3]:
	var liste: Array[Vector3] = []
	var rng := PropWerkzeug.zufall(5521)
	var s := 216.0
	while s < 271.0:
		if s < G2.x - 1.5 or s > G2.y + 1.5:
			liste.append(Vector3(s, rng.randf_range(0.1, 0.22), rng.randf_range(0.8, 1.5)))
		s += rng.randf_range(5.5, 9.0)
	return liste


## Die Außenwurzel in drei Teilen zwischen den Brüchen.
static func _aussenwurzel(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String) -> void:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5507
	rauschen.frequency = 0.25
	var flecken := FastNoiseLite.new()
	flecken.seed = 5519
	flecken.frequency = 0.14
	var schritt := 1.05 if stufe == "nah" else 2.5
	var auswahl := [0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
	if stufe != "nah":
		auswahl = [0, 4, 7, 10, 12, 14]
	for teil: Vector2 in [Vector2(196.0, G1.x), Vector2(G1.y, G2.x), Vector2(G2.y, ENDE + 3.8)]:
		var s_werte := _stellen(teil.x, teil.y, schritt)
		var profile: Array = []
		var farben: Array = []
		var kerne: Array = []
		for s in s_werte:
			var voll := _aussenprofil(level, s, rauschen)
			var lip := smoothstep(272.4, 273.6, s)
			var punkte := PackedVector2Array()
			var fa := PackedColorArray()
			for k: int in auswahl:
				var p := voll[k]
				if stufe == "schatten":
					# knapp innerhalb der sichtbaren Form
					p = p.lerp(Vector2(_kante(level, s) + 0.7, -1.8), 0.08)
				punkte.append(p)
				var ao: float = AUSSEN_AO[k]
				# In der Fuge fast schwarz.
				if k >= 9 and k <= 11:
					ao *= 1.0 - 0.7 * _fuge(s) * [0.6, 1.0, 0.6][k - 9]
				# Moos in Flecken, nicht als Teppich.
				var fleck := maxf(0.0, flecken.get_noise_2d(s, float(k) * 0.7))
				var moos: float = AUSSEN_MOOS[k] * (0.35 + 1.1 * fleck) \
						+ 0.15 * rauschen.get_noise_2d(s * 1.3, float(k) * 3.0)
				if lip > 0.0:
					# Am Regal: Polster und Wulst grün, der Leib wie sonst.
					ao = lerpf(ao, LIPPE_AO[k], lip)
					moos = lerpf(moos, float(LIPPE_MOOS[k]) * (0.35 + 1.1 * fleck), lip)
				fa.append(Color(ao, ao, ao, clampf(moos, 0.0, 1.0)))
			profile.append(punkte)
			farben.append(fa)
			kerne.append(Vector2(_kante(level, s) + 0.6, -1.8 - _abtauchen(s)))
		var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.6, 0.35)
		_verteilen(ziel, g, "holz")


## Boden unter der Wendel (Welt-Y), auf den Unterbau und Seitenwurzeln
## hinabreichen (sie stecken 1–2 m darunter): erst die Wurzelwiese (7,0),
## dann die Wurzelgruben (−2, Plan 8.4), am Regal der Knoll mit dem Bach.
## Für das Gelände: Liegt der Boden dort tiefer, schweben die Wurzelfüße.
static func boden_unter_wendel(s: float) -> float:
	var y := lerpf(6.2, -2.0, smoothstep(214.0, 221.0, s))
	return lerpf(y, 4.6, smoothstep(262.0, 274.0, s))


## Unter dem Weg: die Schürze von der Außenwurzel nach innen und die Wand
## hinab bis in die Gruben. Die Schürze bricht mit dem Weg (G2), die Wand
## darunter läuft durch: Durch den Bruch sieht man an ihr vorbei in die
## Tiefe.
static func _unterbau(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String) -> void:
	var schritt := 1.2 if stufe == "nah" else 3.0
	for teil: Vector2 in [Vector2(G1.y, G2.x), Vector2(G2.y, ENDE + 3.8)]:
		var s_werte := _stellen(teil.x, teil.y, schritt)
		var profile: Array = []
		var farben: Array = []
		var kerne: Array = []
		for s in s_werte:
			var e := _kante(level, s)
			var ab := _abtauchen(s)
			var unten := -4.05 if s < 273.0 else -4.85
			var punkte := PackedVector2Array([Vector2(e - 0.4, unten - ab),
					Vector2(e - 2.4, unten - 0.55 - ab), Vector2(e - 6.0, unten - 1.35 - ab),
					Vector2(-4.6, -6.8 - ab)])
			profile.append(punkte)
			farben.append(PackedColorArray([Color(0.3, 0.3, 0.3, 0.4), Color(0.26, 0.26, 0.26, 0.5),
					Color(0.24, 0.24, 0.24, 0.5), Color(0.26, 0.26, 0.26, 0.55)]))
			kerne.append(Vector2(-1.0, -1.0 - ab))
		var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.5, 0.3)
		_verteilen(ziel, g, "holz")
	# Die Wand darunter, durchgehend.
	var s_werte := _stellen(G1.y + 0.5, ENDE + 3.8, schritt * 1.4)
	var profile: Array = []
	var farben: Array = []
	var kerne: Array = []
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5513
	rauschen.frequency = 0.3
	for s in s_werte:
		var deck := level.boden_bei(s)
		var boden := boden_unter_wendel(s) - deck
		var ab := _abtauchen(s)
		var mitte := (-10.0 + boden) * 0.5
		var w := rauschen.get_noise_1d(s)
		var punkte := PackedVector2Array([Vector2(-4.6, -6.8 - ab),
				Vector2(-5.8 + 0.5 * w, -10.0 - ab), Vector2(-6.3 - 0.6 * w, mitte - ab),
				Vector2(-5.6, boden + 2.5), Vector2(-3.5, boden - 1.2)])
		profile.append(punkte)
		var streifen := 0.35 + 0.4 * (0.5 + 0.5 * sin(s * 1.9))
		farben.append(PackedColorArray([Color(0.26, 0.26, 0.26, 0.55),
				Color(0.3, 0.3, 0.3, streifen), Color(0.34, 0.34, 0.34, streifen),
				Color(0.3, 0.3, 0.3, 0.6), Color(0.22, 0.22, 0.22, 0.7)]))
		kerne.append(Vector2(-12.0, mitte - ab))
	var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.45, 0.3)
	_verteilen(ziel, g, "holz")


# ---------------------------------------------------------------- Seitenwurzeln

## Wo Seitenwurzeln aus der Außenwurzel in die Gruben tauchen – nicht an
## den Füßen der Wurzelbögen, sonst läse sich Bogen und Seitenwurzel als
## ein einziger Fangarm.
static func _seitenwurzel_stellen() -> Array[float]:
	return [217.0, 223.0, 234.5, 240.0, 248.0, 258.5, 264.0, 270.5]


## Dicke der Seitenwurzel `i` relativ zum Strebepfeiler (Radius 1,55–2,2 m):
## drei mächtige, dazwischen schlanke bis 0,4 m. Gleich dick las sich die
## Wendel als Rohr auf Stelzen.
static func _seitenwurzel_dicke(i: int) -> float:
	return [1.0, 0.38, 0.72, 0.26, 0.9, 0.44, 0.3, 0.85][i % 8]


static func _seitenwurzeln(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String,
		rng: RandomNumberGenerator) -> void:
	var seiten := 10 if stufe == "nah" else 5
	for nummer in _seitenwurzel_stellen().size():
		var sw: float = _seitenwurzel_stellen()[nummer]
		var e := _kante(level, sw)
		var deck := level.boden_bei(sw)
		var boden := boden_unter_wendel(sw + 3.0) - deck
		# Fest je Stelle, nicht aus dem Würfel: Nah-, Schatten- und
		# Fernfassung müssen dieselbe Wurzel zeigen.
		var drift := (Riesenstamm.randf_hash(nummer + 3, 17) * 2.0 - 1.0) * 2.5
		# Ein Strebepfeiler: aus dem Leib der Außenwurzel erst hinaus, dann
		# in weitem Bogen hinab; am Boden läuft er breit aus.
		var punkte_sqh := [
			Vector3(sw, e + 0.9, -1.6), Vector3(sw + 0.3 * drift, e + 3.2, -3.4),
			Vector3(sw + 0.6 * drift, e + 5.4, -6.6), Vector3(sw + 0.85 * drift, e + 7.0, boden * 0.62),
			Vector3(sw + drift, e + 8.2, boden + 3.0), Vector3(sw + 1.1 * drift, e + 9.4, boden + 0.4),
			Vector3(sw + 1.15 * drift, e + 10.2, boden - 1.8),
		]
		var dicke := _seitenwurzel_dicke(nummer)
		# Schlanke Wurzeln hängen steiler und näher am Leib.
		if dicke < 0.6:
			for k in punkte_sqh.size():
				var p: Vector3 = punkte_sqh[k]
				punkte_sqh[k] = Vector3(p.x, e + (p.y - e) * lerpf(0.55, 1.0, dicke), p.z)
		var punkte := PackedVector3Array()
		for p: Vector3 in punkte_sqh:
			punkte.append(bahn.p(p.x, p.y, p.z))
		var radien := PackedFloat32Array([2.2, 2.0, 1.75, 1.55, 1.6, 1.95, 2.2])
		for k in radien.size():
			radien[k] *= dicke * (0.85 if stufe == "schatten" else 1.0)
		var g := Weltenbaum.rohr(punkte, radien, {"seiten": seiten, "beulen": 0.1,
				"saat": 700 + nummer, "uv_mass": 0.5})
		var tiefe := deck + boden
		var farbe := func(p: Vector3, nn: Vector3) -> Color:
			var ao := lerpf(0.3, 0.85, smoothstep(tiefe, deck - 0.5, p.y))
			return Color(ao, ao, ao, clampf(0.25 + nn.y * 0.5, 0.0, 1.0))
		Weltenbaum.gitter_faerben(g, farbe, 0.3)
		var st := _st_bei(ziel, sw)
		Weltenbaum.gitter_schreiben(st, g)
		if stufe != "nah" or dicke < 0.6:
			continue
		# Maserknolle, wo die Seitenwurzel aus der Außenwurzel bricht.
		var aussen := (bahn.rahmen(sw).r * 0.85 + Vector3.DOWN * 0.35).normalized()
		Weltenbaum.knolle_in(st, bahn.p(sw, e + 2.2, -1.6), aussen,
				rng.randf_range(1.5, 1.9) * dicke, rng, 0.55)
		# Ein zweiter, dünner Ausläufer auf halber Höhe.
		if rng.randf() < 0.6:
			var ab := punkte[2]
			var seit := bahn.rahmen(sw).v * (1.0 if drift < 0.0 else -1.0)
			var zweig := PackedVector3Array([ab, ab + seit * 2.2 + Vector3.DOWN * 2.5,
					ab + seit * 3.6 + Vector3.DOWN * 6.0 + bahn.rahmen(sw).r * 1.2,
					ab + seit * 4.2 + Vector3.DOWN * (absf(boden) - 6.0)])
			var gz := Weltenbaum.rohr(zweig, PackedFloat32Array([0.9, 0.8, 0.7, 0.75]),
					{"seiten": 7, "beulen": 0.1, "saat": rng.randi(), "uv_mass": 0.5})
			var zweigfarbe := func(p: Vector3, nn: Vector3) -> Color:
				var ao := lerpf(0.3, 0.7, smoothstep(tiefe, deck - 4.0, p.y))
				return Color(ao, ao, ao, clampf(0.2 + nn.y * 0.5, 0.0, 1.0))
			Weltenbaum.gitter_faerben(gz, zweigfarbe, 0.3)
			Weltenbaum.gitter_schreiben(st, gz)


# ---------------------------------------------------------------- Knorren

## Große Knorren auf dem Leib der Außenwurzel: 1,2–2 m lange, 0,3–0,55 m
## hohe Buckel alle 6–10 m, dort, wo die Spielkamera auf den Leib schaut
## (zwischen Kamm und Bauch). Sie liegen ganz jenseits der Wulstkollision
## (q > 4,7) und unter ihrer Oberkante (+0,6) – Beiwerk, das nichts
## Begehbares vortäuscht. Nicht an Seitenwurzeln (die haben ihre
## Maserknolle), nicht an den Füßen der Wurzelbögen, nicht an G2.
static func _knorren_bauen(ziel: Dictionary, bahn: Bahn, level: Level01) -> void:
	var rng := PropWerkzeug.zufall(6041)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5507
	rauschen.frequency = 0.25
	var sperren: Array[Vector2] = [Vector2(G2.x - 2.0, G2.y + 2.0), Vector2(227.0, 231.0),
			Vector2(251.0, 255.0)]
	for sw: float in _seitenwurzel_stellen():
		sperren.append(Vector2(sw - 2.3, sw + 2.3))
	var s := 216.5 + rng.randf_range(0.0, 2.0)
	while s < 271.0:
		var frei := true
		for sp in sperren:
			if s > sp.x and s < sp.y:
				frei = false
		if not frei:
			s += 1.0
			continue
		var profil := _aussenprofil(level, s, rauschen)
		var a := profil[7]
		var b := profil[8]
		var mitte := a.lerp(b, rng.randf_range(0.35, 0.65))
		var t2 := (b - a).normalized()
		var n2 := Vector2(-t2.y, t2.x)
		if n2.x < 0.0:
			n2 = -n2
		var ra := bahn.rahmen(s)
		var aussen := (ra.r * n2.x + Vector3.UP * n2.y).normalized()
		var quer := (ra.r * -n2.y + Vector3.UP * n2.x).normalized()
		var ort := ra.p(mitte.x, mitte.y) - aussen * 0.05
		_knorre_in(_st_bei(ziel, s), ort, aussen, quer, ra.v, rng.randf_range(0.6, 1.0),
				rng.randf_range(0.45, 0.62), rng.randf_range(0.3, 0.55), rng)
		s += rng.randf_range(6.0, 10.0)


## Ein Knorren: ovaler, verbeulter Buckel, zu 15 % eingesunken. `laengs`
## und `quer` spannen die Unterlage, `aussen` zeigt von ihr weg; Halbachsen
## `a_l`, `a_q`, Höhe `hoch`.
static func _knorre_in(st: SurfaceTool, mitte: Vector3, aussen: Vector3, quer: Vector3,
		laengs: Vector3, a_l: float, a_q: float, hoch: float, rng: RandomNumberGenerator) -> void:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = rng.randi()
	rauschen.frequency = 2.2
	const SEITEN := 12
	var breiten := PackedFloat32Array([1.1, 1.0, 0.86, 0.62, 0.32, 0.0])
	var g := {"p": [], "uv": [], "ringsum": true}
	var kerne := PackedVector3Array()
	for i in breiten.size():
		var b := breiten[i]
		var h := sqrt(maxf(0.0, 1.0 - minf(b, 1.0) * minf(b, 1.0))) * hoch
		if b > 1.0:
			h = -hoch * 0.18
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		for j in SEITEN + 1:
			var w := TAU * float(j % SEITEN) / float(SEITEN)
			var p := mitte + laengs * cos(w) * a_l * b + quer * sin(w) * a_q * b + aussen * h
			p += aussen * hoch * 0.18 * rauschen.get_noise_3dv(p) * minf(b * 2.0, 1.0)
			zeile.append(p)
			uv.append(Vector2(float(j) / float(SEITEN) * 2.0, float(i) * 0.35))
		(g["p"] as Array).append(zeile)
		(g["uv"] as Array).append(uv)
		kerne.append(mitte - aussen * hoch)
	var farbe := func(p: Vector3, n: Vector3) -> Color:
		var ao := lerpf(0.42, 1.0, clampf((p - mitte).dot(aussen) / maxf(hoch, 0.01), 0.0, 1.0))
		return Color(ao, ao, ao, clampf(0.15 + n.y * 0.7, 0.0, 1.0))
	Weltenbaum.gitter_faerben(g, farbe, 0.4)
	Weltenbaum.orientieren(g, func(i: int) -> Vector3: return kerne[i])
	Weltenbaum.neu_faerben(g, farbe, 0.4)
	Weltenbaum.gitter_schreiben(st, g)


# ---------------------------------------------------------------- Vorhänge

static var _vorhang_stoff: ShaderMaterial = null

## Wurzel- und Moosvorhänge unter dem Leib der Außenwurzel: Karten mit
## Alpha-Schnitt (0,5–1,1 m breit, 1,2–3,2 m lang), die vom Bauch in die
## Gruben hängen und sich im Wind leise wiegen (nur im Vertexshader, kein
## Knoten bewegt sich). Ohne Schatten, EIN Netz, bis 70 m sichtbar. Sie
## brechen die glatte Unterkante, die die Wendel von der Seite als
## Schlauch zeigte.
static func _vorhaenge_bauen(eltern: Node3D, bahn: Bahn, level: Level01) -> void:
	var rng := PropWerkzeug.zufall(6053)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5507
	rauschen.frequency = 0.25
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := 214.5
	var anzahl := 0
	# Am Regal (ab 273,5) hängen sie weiter außen, unter dem Buckel der Lippe:
	# Im Schlussbild brechen sie die Unterkante vor dem Tal.
	while s < 286.5:
		var weiter := rng.randf_range(0.9, 2.1)
		var regal := s > 273.5
		var bei_wurzel := false
		for sw: float in _seitenwurzel_stellen():
			if absf(s - sw) < 1.4:
				bei_wurzel = true
		if (s > G2.x - 0.6 and s < G2.y + 0.6) or bei_wurzel or (s > 271.5 and s < 273.5):
			s += weiter
			continue
		var profil := _aussenprofil(level, s, rauschen)
		var haken := profil[11].lerp(profil[12], rng.randf())
		if regal:
			haken = profil[7].lerp(profil[8], rng.randf())
		var ra := bahn.rahmen(s)
		var oben := ra.p(haken.x - 0.08, haken.y + 0.05)
		var breite := rng.randf_range(0.5, 1.1)
		var laenge := rng.randf_range(1.2, 3.2)
		if regal:
			laenge = rng.randf_range(1.6, 3.6)
			weiter = rng.randf_range(1.2, 2.6)
		var gier := rng.randf_range(-1.2, 1.2)
		var achse := (ra.v * cos(gier) + ra.r * sin(gier)).normalized()
		var unten := oben + Vector3.DOWN * laenge + ra.r * laenge * rng.randf_range(0.0, 0.12)
		var u0 := 0.0 if rng.randf() < 0.5 else 0.5
		var ton := rng.randf_range(0.8, 1.1)
		var farbe := Color(ton, ton, ton * rng.randf_range(0.9, 1.05), 1.0)
		var normale := achse.cross(Vector3.DOWN).normalized()
		var ecken: Array[Vector3] = [oben - achse * breite * 0.5, oben + achse * breite * 0.5,
				unten + achse * breite * 0.5 * 0.8, unten - achse * breite * 0.5 * 0.8]
		var uvs: Array[Vector2] = [Vector2(u0, 0.0), Vector2(u0 + 0.5, 0.0), Vector2(u0 + 0.5, 1.0),
				Vector2(u0, 1.0)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_color(farbe)
			st.set_normal(normale)
			st.set_uv(uvs[k])
			st.add_vertex(ecken[k])
		anzahl += 1
		s += weiter
	if anzahl == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Wurzelvorhaenge"
	mi.mesh = st.commit()
	mi.material_override = _vorhangstoff()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 70.0
	mi.visibility_range_end_margin = RAND
	eltern.add_child(mi)


## Stoff der Vorhänge, geteilt – nie verändern.
static func _vorhangstoff() -> ShaderMaterial:
	if _vorhang_stoff != null:
		return _vorhang_stoff
	var shader := Shader.new()
	shader.code = VORHANG_SHADER
	_vorhang_stoff = ShaderMaterial.new()
	_vorhang_stoff.shader = shader
	_vorhang_stoff.set_shader_parameter("bild", _vorhangbild())
	return _vorhang_stoff


## Bild der Vorhänge, 256²: links und rechts je ein Satz dünner Wurzeln,
## die von oben herabhängen, sich schlängeln und verzweigen, oben
## Moospolster. Graubraun hinter den Wurzeln (Alpha 0), damit die Mipmaps
## nicht dunkel ausfransen; in den kleineren Stufen hält Alpha die Deckung.
static func _vorhangbild() -> ImageTexture:
	const K := 256
	const HALB := 128
	var bild := Image.create_empty(K, K, false, Image.FORMAT_RGBA8)
	bild.fill(Color8(70, 56, 40, 0))
	var rng := PropWerkzeug.zufall(6061)
	for haelfte in 2:
		var x0 := float(haelfte * HALB)
		for n in 13:
			var x := x0 + rng.randf_range(6.0, float(HALB) - 6.0)
			var dicke := rng.randf_range(1.3, 3.4)
			var laenge := rng.randf_range(0.4, 1.0) * float(K)
			var welle := rng.randf_range(2.0, 7.0)
			var takt := rng.randf_range(0.02, 0.06)
			var phase := rng.randf() * TAU
			var ton := rng.randf_range(0.7, 1.0)
			for y in int(laenge):
				var f := float(y) / laenge
				var cx := x + welle * sin(float(y) * takt + phase) * f
				var halb := maxf(dicke * (1.0 - 0.75 * f) * 0.5, 0.45)
				var farbe := Color(0.24, 0.17, 0.11).lerp(Color(0.46, 0.36, 0.25), f * 0.8) * ton
				for px in range(int(floor(cx - halb)), int(ceil(cx + halb)) + 1):
					if px < int(x0) or px >= int(x0) + HALB:
						continue
					bild.set_pixel(px, y, Color(farbe.r, farbe.g, farbe.b, 1.0))
			# Eine Seitenwurzel ab halber Höhe.
			if rng.randf() < 0.5:
				var y_ab := int(laenge * rng.randf_range(0.25, 0.55))
				var richtung := -1.0 if rng.randf() < 0.5 else 1.0
				for k in int(laenge * 0.35):
					var yy := y_ab + k
					if yy >= K:
						break
					var px := int(x + welle * sin(float(yy) * takt + phase) * 0.5 + richtung * float(k) * 0.35)
					if px >= int(x0) and px < int(x0) + HALB:
						bild.set_pixel(px, yy, Color(0.3, 0.22, 0.14, 1.0))
		# Moospolster am oberen Rand.
		for n in 7:
			var mx := x0 + rng.randf_range(4.0, float(HALB) - 4.0)
			var my := rng.randf_range(0.0, 26.0)
			var r := rng.randf_range(7.0, 16.0)
			var gruen := Color(0.2, 0.3, 0.09).lerp(Color(0.32, 0.4, 0.13), rng.randf())
			for py in range(maxi(0, int(my - r)), mini(K, int(my + r))):
				for px in range(maxi(int(x0), int(mx - r)), mini(int(x0) + HALB, int(mx + r))):
					var d := Vector2(float(px) - mx, (float(py) - my) * 1.4).length()
					if d < r * (0.75 + 0.25 * sin(float(px) * 1.7 + float(py))):
						var hell := 0.8 + 0.2 * (1.0 - d / r)
						bild.set_pixel(px, py, Color(gruen.r * hell, gruen.g * hell, gruen.b * hell, 1.0))
	bild.generate_mipmaps()
	_deckung_halten(bild)
	return ImageTexture.create_from_image(bild)


## Hebt Alpha in den Mipmaps so weit an, dass bei der Schwelle 0,5 etwa so
## viel deckt wie in der vollen Auflösung (dünne Wurzeln verschwänden
## sonst in der Ferne).
static func _deckung_halten(bild: Image) -> void:
	var daten := bild.get_data()
	var k := bild.get_width()
	var soll := _deckung(daten, 0, k * k, 1.0)
	for stufe in range(1, bild.get_mipmap_count() + 1):
		var start := bild.get_mipmap_offset(stufe)
		var kante := maxi(k >> stufe, 1)
		var anzahl := kante * kante
		if anzahl < 4:
			break
		var lo := 1.0
		var hi := 6.0
		for versuch in 8:
			var mittel := (lo + hi) * 0.5
			if _deckung(daten, start, anzahl, mittel) < soll:
				lo = mittel
			else:
				hi = mittel
		var faktor := (lo + hi) * 0.5
		for i in anzahl:
			var j := start + i * 4 + 3
			daten[j] = mini(255, int(float(daten[j]) * faktor))
	bild.set_data(k, k, true, Image.FORMAT_RGBA8, daten)


static func _deckung(daten: PackedByteArray, start: int, anzahl: int, faktor: float) -> float:
	var zaehler := 0
	for i in anzahl:
		if float(daten[start + i * 4 + 3]) * faktor >= 127.5:
			zaehler += 1
	return float(zaehler) / float(anzahl)


const VORHANG_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D bild : source_color, filter_linear_mipmap, repeat_disable;

void vertex() {
	// Wiegen im Wind, unten stärker als oben (UV.y 0 oben, 1 unten).
	float w = UV.y * UV.y * 0.12;
	VERTEX.x += sin(TIME * 0.8 + VERTEX.z * 0.6 + VERTEX.y * 0.2) * w;
	VERTEX.z += cos(TIME * 0.7 + VERTEX.x * 0.5) * w * 0.7;
}

void fragment() {
	vec4 t = texture(bild, UV);
	ALBEDO = t.rgb * COLOR.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
}
"""


# ---------------------------------------------------------------- Fuß

## Der Fuß des Fleischs an der Wegkante: ein dunkler, bemooster Saum, der
## 0,3 m unter die Decke rollt und die Flanke ein Stück hinaufläuft. Ohne
## ihn schien zwischen Wegkante und unterstem Strang eine helle Linie
## durch. Früher schlossen das Borkenleisten AUF der Decke – sie lagen
## beinahe in ihrer Ebene und flimmerten gegen sie; die Rippen am Rand malt
## jetzt `wegboden.gdshader`. Im Regal (F) spannt der Saum auch den Streifen
## zwischen Wegkante und Leitlinie. An den Brüchen endet er mit der Decke.
static func _flankenfuss(ziel: Dictionary, bahn: Bahn, level: Level01) -> void:
	var n := _flanken_normale()
	for teil: Vector2 in [Vector2(198.0, G1.x), Vector2(G1.y, G2.x), Vector2(G2.y, 287.0)]:
		var s_werte := _stellen(teil.x, teil.y, 0.9)
		var profile: Array = []
		var farben: Array = []
		var kerne: Array = []
		for s in s_werte:
			var kante := -_kante(level, s)
			var fuss := minf(_flanke_fuss(s), kante)
			var welle := 0.035 * sin(s * 1.7) + 0.03 * sin(s * 0.63 + 1.0)
			profile.append(PackedVector2Array([
				Vector2(kante + 0.16, -0.32),
				Vector2(kante + 0.02, -0.012),
				Vector2(fuss - 0.02, -0.006),
				_flanke_punkt(s, 0.04 + welle * 0.4) - n * 0.02,
				_flanke_punkt(s, 0.11 + welle) - n * 0.05,
			]))
			farben.append(PackedColorArray([Color(0.3, 0.3, 0.3, 0.5),
					Color(0.36, 0.36, 0.36, 0.75), Color(0.4, 0.4, 0.4, 0.8),
					Color(0.48, 0.48, 0.48, 0.85), Color(0.55, 0.55, 0.55, 0.6)]))
			kerne.append(Vector2(fuss - 1.2, -1.2))
		var g := _loft(bahn, s_werte, profile, farben, kerne, false, 0.6, 0.3)
		_verteilen(ziel, g, "holz")


## Das Ende des Regals hinter dem Portal: Die Decke endet bei s 287 mit
## einer geraden Kante quer zum Weg, im Schlussbild die Hinterkante eines
## Bretts mit zwei rechten Ecken vor dem Tal. Darüber legt sich ein
## Moospolster mit unruhigem Innenrand, dann rollt die Schulter in runden
## Buckeln ab und taucht wie die Außenwurzel in den Knoll (`REGALENDE`).
## Hinter der Leitlinie der Endquerwand (287,3), also nie begehbar; an den
## Seiten läuft der Umriss in die Lippe bzw. die Flanke aus.
static func _regalende(ziel: Dictionary, bahn: Bahn, level: Level01) -> void:
	var ende := Level01.M_ENDE
	var ra := bahn.rahmen(ende)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5531
	rauschen.frequency = 0.5
	var links := _flanke_fuss(ende) - 0.1
	var rechts := _kante(level, ende) + 0.25
	var schnitte: Array[PackedVector3Array] = []
	var laengs := PackedFloat32Array()
	var farben: Array = []
	var kerne := PackedVector3Array()
	var q := links
	while q <= rechts + 0.001:
		# Rund im Grundriss: in der Mitte gut 1,3-mal so weit hinaus, an den
		# Seiten knapp; dazu Buckel.
		var t := inverse_lerp(links, rechts, q) * 2.0 - 1.0
		var rund := sqrt(maxf(1.0 - t * t, 0.0))
		var weit := (0.7 + 1.1 * rund) * (0.85 + 0.4 * rauschen.get_noise_1d(q * 1.3))
		var innen := 0.15 + 0.5 * (0.5 + 0.5 * rauschen.get_noise_1d(q * 2.6 + 30.0))
		var reihe := PackedVector3Array()
		var fa := PackedColorArray()
		for k in REGALENDE.size():
			var p: Vector2 = REGALENDE[k]
			var a := -innen if k == 0 else (p.x if k == 1 else p.x * weit)
			var h := p.y
			# An den Seiten tiefer: dort taucht schon die Lippe bzw. die Flanke.
			h -= 0.25 * absf(t) * float(k) / float(REGALENDE.size() - 1)
			reihe.append(ra.o + ra.r * q + ra.v * a + Vector3.UP * h)
			var fleck := 0.5 + 0.5 * rauschen.get_noise_2d(q * 1.7, float(k) * 1.1)
			var ao: float = REGALENDE_AO[k]
			var moos := float(REGALENDE_MOOS[k]) * (0.3 + 0.95 * fleck)
			fa.append(Color(ao, ao, ao, clampf(moos, 0.0, 1.0)))
		schnitte.append(reihe)
		laengs.append(q)
		farben.append(fa)
		kerne.append(ra.o + ra.r * q - ra.v * 1.5 + Vector3.DOWN * 2.0)
		q += 0.35
	if schnitte.size() < 2:
		return
	var g := Weltenbaum.zug(schnitte, laengs, false, {"uv_mass": 0.6})
	Weltenbaum.gitter_faerben(g, _weiss, 0.3)
	var kern := func(i: int) -> Vector3: return kerne[i]
	Weltenbaum.orientieren(g, kern)
	g["f"] = farben
	var s_werte := PackedFloat32Array()
	for i in schnitte.size():
		s_werte.append(ende)
	g["s"] = s_werte
	_verteilen(ziel, g, "holz")


# ---------------------------------------------------------------- Brüche

## Stirnflächen der Wurzelbrüche G1 (über der Wiese) und G2 (über der
## Grube): der Querschnitt der Wurzel unter der Decke, gesplittert – an der
## Sprunglippe nur kurze Späne.
static func _brueche(ziel: Dictionary, bahn: Bahn, level: Level01,
		rng: RandomNumberGenerator) -> void:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5507
	rauschen.frequency = 0.25
	for stelle: Vector2 in [Vector2(G1.x, 1.0), Vector2(G1.y, -1.0), Vector2(G2.x, 1.0),
			Vector2(G2.y, -1.0)]:
		var s := stelle.x
		var e := _kante(level, s)
		var aussen := _aussenprofil(level, s, rauschen)
		var umriss := PackedVector2Array([Vector2(-4.0, -0.02), Vector2(0.0, -0.02)])
		for k in range(1, 14):
			umriss.append(aussen[k] - Vector2(0.03, 0.03))
		if s < 230.0:
			# über der Wiese: bis unter deren Boden
			var boden := 7.0 - level.boden_bei(s) - 0.6
			umriss.append(Vector2(e - 0.4, boden))
			umriss.append(Vector2(-4.1, boden))
		else:
			umriss.append(Vector2(e - 2.4, -4.6))
			umriss.append(Vector2(e - 6.0, -5.4))
			umriss.append(Vector2(-4.55, -6.7))
			umriss.append(Vector2(-4.3, -3.0))
		var ra := bahn.rahmen(s)
		var welt := PackedVector3Array()
		for p in umriss:
			welt.append(ra.p(p.x, p.y))
		# Gerissen, nicht gesägt: Aus der Spielkamera stand die Stirn von G1
		# als rote, ebene Tafel mit Jahresringen im Bild (ein Viertel davon).
		Weltenbaum.bruch_in(_st_bei(ziel, s), welt, ra.v * stelle.y, rng,
				{"splitter": 1.0, "flach_ueber": ra.o.y - 0.3, "zerfetzt": 1.0, "scherben": 8})


# ---------------------------------------------------------------- Oberwurzel

## Oberkante der Oberwurzel über der Decke (Kollision: +3,6 bei 250 → +5,2
## bei 263), außerhalb linear weiter.
static func _oberwurzel_oben(s: float) -> float:
	return 3.6 + (s - 250.0) / 13.0 * 1.6


## Die Luftwurzel am Stamm (Geheimnisse S4/S5): Oberseite genau auf der
## Kollision, die Wegseite hinter q −5,4, darunter eine dunkle Hohlkehle
## zum Fleisch. Vorher taucht sie aus der Flanke; oben endet sie mit der
## Kollision in einem Bruch – liefe sie sichtbar weiter, stünde man auf
## ihr ins Leere.
static func _oberwurzel(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String) -> void:
	var schritt := 0.6 if stufe == "nah" else 2.0
	var s_werte := _stellen(246.5, 263.1, schritt)
	var form := [
		Vector2(-5.42, -0.55), Vector2(-5.42, -0.3), Vector2(-5.47, -0.09), Vector2(-5.6, 0.0),
		Vector2(-6.3, 0.0), Vector2(-7.0, 0.0), Vector2(-7.6, -0.02), Vector2(-8.1, -0.35),
		Vector2(-8.3, -1.0), Vector2(-7.7, -1.5), Vector2(-6.8, -1.6), Vector2(-6.0, -1.2),
	]
	var ao := [0.55, 0.8, 0.95, 1.0, 1.0, 1.0, 1.0, 0.85, 0.5, 0.35, 0.32, 0.38]
	var moos := [0.2, 0.3, 0.5, 0.8, 0.9, 0.9, 0.8, 0.5, 0.3, 0.3, 0.35, 0.3]
	if stufe != "nah":
		form = [Vector2(-5.45, -0.5), Vector2(-5.6, 0.0), Vector2(-7.6, 0.0), Vector2(-8.2, -0.8),
				Vector2(-6.6, -1.5)]
		ao = [0.6, 1.0, 1.0, 0.5, 0.35]
		moos = [0.3, 0.8, 0.8, 0.3, 0.3]
	var profile: Array = []
	var farben: Array = []
	var kerne: Array = []
	for s in s_werte:
		var oben := _oberwurzel_oben(s)
		var sinken := 0.9 * maxf(250.0 - s, 0.0)
		var weiter := maxf(s - 263.0, 0.0)
		var hinein := -2.0 * weiter
		var steigen := 0.4 * weiter
		var punkte := PackedVector2Array()
		var fa := PackedColorArray()
		for k in form.size():
			var p: Vector2 = form[k]
			var pp := Vector2(p.x + hinein, oben + p.y - sinken + steigen)
			if s >= 249.9 and s <= 263.1:
				pp.x = minf(pp.x, -5.42)
			punkte.append(pp)
			var a: float = ao[k]
			fa.append(Color(a, a, a, float(moos[k])))
		profile.append(punkte)
		farben.append(fa)
		kerne.append(Vector2(-6.8 + hinein, oben - 0.7 - sinken + steigen))
	var g := _loft(bahn, s_werte, profile, farben, kerne, true, 0.6, 0.3)
	_verteilen(ziel, g, "holz")
	if stufe == "nah":
		var s_ende := s_werte[s_werte.size() - 1]
		var ra := bahn.rahmen(s_ende)
		var ring := PackedVector3Array()
		for p: Vector2 in profile[profile.size() - 1]:
			ring.append(ra.p(p.x, p.y) - ra.v * 0.03)
		Weltenbaum.bruch_in(_st_bei(ziel, s_ende), ring, ra.v, PropWerkzeug.zufall(6023),
				{"splitter": 0.35, "flach_ueber": ra.o.y + _oberwurzel_oben(s_ende) - 0.25,
				"moos": false})


# ---------------------------------------------------------------- Wurzelbögen

## Die Mittellinie eines Wurzelbogens (Welt): aus dem Fleisch hinter der
## Flanke hoch über den Weg und außen auf die Außenwurzel. `unterkante` ist
## die Höhe der Bogenunterseite über der Wegmitte (TORE "scheitel").
static func _bogen_linie(bahn: Bahn, level: Level01, tor: Dictionary) -> PackedVector3Array:
	var s: float = tor["s"]
	var h: float = float(tor["scheitel"]) + 1.7
	var fuss := _flanke_fuss(s)
	var aussen: float = _kante(level, s) + float(tor["abstand"]) - 4.0 + 1.6
	var steuer: Array[Vector3] = [
		Vector3(-1.2, fuss - 9.2, 6.4), Vector3(-0.8, fuss - 7.0, 9.4),
		Vector3(-0.4, fuss - 4.4, h + 0.4), Vector3(0.0, -2.2, h + 0.2),
		Vector3(0.3, 0.6, h - 0.1), Vector3(0.6, 3.0, h - 0.9),
		Vector3(0.9, aussen - 0.4, h - 3.0), Vector3(1.1, aussen + 0.2, 5.4),
		Vector3(1.2, aussen + 0.1, 2.2), Vector3(1.2, aussen - 0.2, -0.4),
		Vector3(1.1, aussen - 0.5, -1.7),
	]
	if s < G1.x:
		# Über der Wurzelwiese: Der Bogen greift weit hinaus und setzt hinter
		# der Hecke auf, damit auf der begehbaren Wiese kein Fuß ohne
		# Kollision steht.
		var deck := level.boden_bei(s)
		var wiese := 7.0 - deck
		steuer = [
			Vector3(-1.2, fuss - 9.2, 6.4), Vector3(-0.8, fuss - 7.0, 9.4),
			Vector3(-0.4, fuss - 4.4, h + 0.4), Vector3(0.0, -2.2, h + 0.2),
			Vector3(0.3, 1.0, h - 0.1), Vector3(0.6, 5.0, h - 0.8),
			Vector3(0.9, 9.4, h - 2.8), Vector3(1.1, 12.9, wiese + 4.2),
			Vector3(1.2, 14.1, wiese + 0.6), Vector3(1.2, 14.5, wiese - 1.2),
		]
	var linie := PackedVector3Array()
	var n := steuer.size()
	for i in n - 1:
		var p0 := steuer[maxi(i - 1, 0)]
		var p1 := steuer[i]
		var p2 := steuer[i + 1]
		var p3 := steuer[mini(i + 2, n - 1)]
		for k in 3:
			var t := float(k) / 3.0
			var c := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)
			linie.append(bahn.p(s + c.x, c.y, c.z))
	var letzte := steuer[n - 1]
	linie.append(bahn.p(s + letzte.x, letzte.y, letzte.z))
	# Teilbogen ("teil"): Die Wurzel steigt aus dem Fleisch, reicht über den
	# Weg und bricht ab, ohne sich außen zu schließen – nur der Bogen bei
	# CP4 (s 229) ist ganz, so kündigt allein er etwas an (Plan 7).
	if tor.has("teil"):
		linie = linie.slice(0, maxi(4, roundi(float(linie.size()) * float(tor["teil"]))))
	return linie


## Die Wurzelbögen aus TORE: drei Stränge, die sich um die Mittellinie
## winden, dick an den Füßen, dünner im Scheitel.
static func _wurzelboegen(ziel: Dictionary, bahn: Bahn, level: Level01, stufe: String,
		rng: RandomNumberGenerator) -> void:
	for tor: Dictionary in Level01.TORE:
		if String(tor.get("art", "")) != "wurzelbogen":
			continue
		var s: float = tor["s"]
		var linie := _bogen_linie(bahn, level, tor)
		var teil := tor.has("teil")
		var st := _st_bei(ziel, s)
		var anzahl := 3 if stufe == "nah" else 1
		for strang in anzahl:
			var phase := TAU * float(strang) / 3.0 + rng.randf_range(-0.3, 0.3)
			var windung := rng.randf_range(0.14, 0.2)
			var aus := rng.randf_range(0.55, 0.7) if anzahl > 1 else 0.0
			var r := rng.randf_range(0.72, 0.92) if anzahl > 1 else 1.5
			if stufe == "schatten":
				r *= 0.85
			var punkte := PackedVector3Array()
			var radien := PackedFloat32Array()
			var lauf := 0.0
			for i in linie.size():
				var t := linie[mini(i + 1, linie.size() - 1)] - linie[maxi(i - 1, 0)]
				t = t.normalized()
				var seit := t.cross(Vector3.UP).normalized()
				if seit.length_squared() < 0.01:
					seit = bahn.rahmen(s).v
				var auf := seit.cross(t).normalized()
				if i > 0:
					lauf += linie[i].distance_to(linie[i - 1])
				var w := phase + lauf * windung * TAU / 3.0
				punkte.append(linie[i] + (seit * cos(w) + auf * sin(w)) * aus)
				var rel := float(i) / float(linie.size() - 1)
				# dick in Fleisch und Außenwurzel, im Scheitel dünner; ein
				# Teilbogen läuft spitz aus
				var dick := 1.0 + 0.45 * (1.0 - smoothstep(0.0, 0.3, rel))
				if teil:
					dick *= lerpf(1.0, 0.3, smoothstep(0.55, 1.0, rel))
				else:
					dick += 0.35 * smoothstep(0.7, 1.0, rel)
				radien.append(r * dick * (0.85 + 0.15 * sin(lauf * 0.9 + phase)))
			var g := Weltenbaum.rohr(punkte, radien, {"seiten": 8 if stufe == "nah" else 5,
					"beulen": 0.1, "saat": rng.randi(), "uv_mass": 0.7,
					"ende": "spitz" if teil else "offen"})
			var deck := level.boden_bei(s)
			var farbe := func(p: Vector3, nn: Vector3) -> Color:
				var ao := lerpf(0.45, 1.0, smoothstep(deck - 1.0, deck + 6.0, p.y))
				return Color(ao, ao, ao, clampf(0.15 + nn.y * 0.7, 0.0, 1.0))
			Weltenbaum.gitter_faerben(g, farbe, 0.3)
			Weltenbaum.gitter_schreiben(st, g)


## Sichtkörper der Wurzelbögen (Ebene 8, nur die Kamera fragt sie ab):
## entlang der Mittellinie, wo sie höher als 6 m über dem Weg liegt – wie
## `Schluchtsaum.wurzeltor`. So fährt die Kamera nie in die Stränge.
static func _sichtkoerper_boegen(eltern: Node3D, bahn: Bahn, level: Level01) -> void:
	var sperre := StaticBody3D.new()
	sperre.name = "Sichtsperre"
	sperre.collision_layer = LevelWerkzeuge.SICHTSPERRE
	sperre.collision_mask = 0
	eltern.add_child(sperre)
	for tor: Dictionary in Level01.TORE:
		if String(tor.get("art", "")) != "wurzelbogen":
			continue
		var s: float = tor["s"]
		var deck := level.boden_bei(s)
		_sichtkoerper_linie(sperre, _bogen_linie(bahn, level, tor), deck + 6.0, 2.6)


static func _sichtkoerper_linie(sperre: StaticBody3D, linie: PackedVector3Array,
		ab_y: float, dick: float) -> void:
	for i in linie.size() - 1:
		var a := linie[i]
		var b := linie[i + 1]
		if minf(a.y, b.y) < ab_y:
			continue
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(dick, dick, a.distance_to(b) + 0.2)
		form.shape = kasten
		form.transform = PropWerkzeug.ausrichten_z(a, b)
		sperre.add_child(form)


# ---------------------------------------------------------------- Pilze, Farne

## Lage der beiden Flechtstränge auf der Flanke: Vector2(unterer, oberer).
static func _risse(s: float) -> Vector2:
	var a := _strang(1, s).x
	var b := _strang(2, s).x
	return Vector2(minf(a, b), maxf(a, b))


## Leuchtpilze in den Rissen des Fleischs (zwischen Strang 0 und 1, dort
## sieht man vom Weg aus hinein) und am Fuß der Außenwurzel.
static func _pilze_in_rissen(ziel: Dictionary, bahn: Bahn, level: Level01,
		rng: RandomNumberGenerator) -> void:
	var n := _flanken_normale()
	var s := 200.0
	while s < 285.0:
		if (s > G1.x - 1.0 and s < G1.y + 1.0) or (s > G2.x - 1.0 and s < G2.y + 1.0):
			s += 2.0
			continue
		var t := (_strang(0, s).x + _risse(s).x) * 0.5 + rng.randf_range(-0.03, 0.03)
		var p := _flanke_punkt(s, t) - n * rng.randf_range(0.7, 1.0)
		var st := _st_bei(ziel, s)
		var ra := bahn.rahmen(s)
		for k in rng.randi_range(4, 7):
			var q := p + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.2, 0.25))
			q = _klemmen(s, q)
			var ort := ra.p(q.x, q.y) + ra.v * rng.randf_range(-0.6, 0.6)
			Weltenbaum.leuchtpilz_in(st, ort, rng.randf_range(0.1, 0.19), rng)
		s += rng.randf_range(6.0, 9.5)


## Farne in den oberen Rissen (zwischen den Strängen 1–3), als MultiMesh
## in zwei Hälften der Wendel: Der Farnstoff wiegt die Wedel um den Fuß
## jeder Instanz, verschmolzen ginge das nicht.
static func _farne_setzen(eltern: Node3D, bahn: Bahn, level: Level01) -> void:
	var rng := PropWerkzeug.zufall(6029)
	var n := _flanken_normale()
	for haelfte: Vector2 in [Vector2(199.0, 238.0), Vector2(238.0, 285.0)]:
		var lagen: Array[Transform3D] = []
		var s := haelfte.x + rng.randf_range(0.0, 2.0)
		while s < haelfte.y:
			var risse := _risse(s)
			var t := (risse.x + risse.y) * 0.5 if rng.randf() < 0.5 \
					else (risse.y + _strang(3, s).x) * 0.5
			var p := _klemmen(s, _flanke_punkt(s, t) - n * rng.randf_range(0.5, 0.9))
			var ra := bahn.rahmen(s)
			var normale := (ra.r * n.x + Vector3.UP * n.y).normalized()
			var auf := (Vector3.UP * 0.55 + normale * 0.45).normalized()
			var basis := Basis(Quaternion(Vector3.UP, auf)) * Basis(Vector3.UP, rng.randf() * TAU)
			basis = basis.scaled(Vector3.ONE * rng.randf_range(1.1, 1.8))
			lagen.append(Transform3D(basis, ra.p(p.x, p.y)))
			s += rng.randf_range(4.2, 6.2)
		lagen.append_array(_kammfarne(bahn, level, haelfte, rng))
		lagen.append_array(_bruch_und_endfarne(bahn, level, haelfte, rng))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = Farnwerk.klein(71 if haelfte.x < 200.0 else 72)
		mm.instance_count = lagen.size()
		for k in lagen.size():
			mm.set_instance_transform(k, lagen[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Farne"
		mmi.multimesh = mm
		mmi.material_override = Farnwerk.stoff(FARN_FARBE)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = FARN_BIS
		mmi.visibility_range_end_margin = RAND
		eltern.add_child(mmi)


## Farnbüschel auf dem Kamm der Außenwurzel (dem Rindenwulst), alle 3,5–7 m:
## Aus der Spielkamera sieht man vom Leib der Außenwurzel nur den Kamm, und
## als glattes, gleichmäßig gebogenes Band las er sich als Schlauch. Die
## Büschel brechen die Linie; weich, man läuft hindurch. Nicht näher als
## 1,6 m an einer Kiste (am Außenrand stehen welche) und nicht an G2.
static func _kammfarne(bahn: Bahn, level: Level01, haelfte: Vector2,
		rng: RandomNumberGenerator) -> Array[Transform3D]:
	var lagen: Array[Transform3D] = []
	var kisten := level.kisten_orte()
	var s := maxf(haelfte.x, G1.y + 1.5) + rng.randf_range(0.0, 2.0)
	var bis := minf(haelfte.y, 272.0)
	while s < bis:
		var weiter := rng.randf_range(3.5, 7.0)
		if s > G2.x - 1.2 and s < G2.y + 1.2:
			s += weiter
			continue
		var ra := bahn.rahmen(s)
		var q := _kante(level, s) + rng.randf_range(0.28, 0.5)
		var ort := ra.p(q, 0.56)
		var frei := true
		for k: Vector3 in kisten:
			if Vector2(k.x - ort.x, k.z - ort.z).length() < 1.6:
				frei = false
		if frei:
			var auf := (Vector3.UP * 0.8 + ra.r * 0.2).normalized()
			var basis := Basis(Quaternion(Vector3.UP, auf)) * Basis(Vector3.UP, rng.randf() * TAU)
			lagen.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.75, 1.25)), ort))
		s += weiter
	return lagen


## Farne am Stumpf von G1 (am Fuß der Bruchfläche in der Wurzelwiese und
## außen auf der Wurzel) und an den Ecken des Regalendes hinter dem
## Portal (auf dem Moospolster, außerhalb der Leitlinie): Sie nehmen den
## Bruchkanten die Härte.
static func _bruch_und_endfarne(bahn: Bahn, level: Level01, haelfte: Vector2,
		rng: RandomNumberGenerator) -> Array[Transform3D]:
	var orte: Array[Vector3] = []
	if haelfte.x < G1.y and haelfte.y > G1.y:
		var wiese := 7.0 - level.boden_bei(G1.y)
		var e := _kante(level, G1.y)
		orte.append(Vector3(G1.y + 0.35, e + 1.6, wiese + 0.05))
		orte.append(Vector3(G1.y + 0.5, -4.6, wiese + 0.05))
		orte.append(Vector3(G1.x - 0.6, e + 1.3, wiese + 0.05))
	if haelfte.y > 270.0:
		# Genau auf die Ecken, groß: Sie nehmen dem Ende die rechten Winkel
		# (weich, man läuft hindurch; die Kisten stehen 6 m davor).
		for sq: Vector2 in [Vector2(-0.3, -5.6), Vector2(-0.2, 5.7), Vector2(0.25, 1.9),
				Vector2(-1.6, 5.9)]:
			orte.append(Vector3(Level01.M_ENDE + sq.x, sq.y, 0.03))
	var lagen: Array[Transform3D] = []
	for o in orte:
		var ra := bahn.rahmen(o.x)
		var gross := 2.3 if o.x > 280.0 and absf(o.y) > 5.0 else 1.45
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE
				* gross * rng.randf_range(0.85, 1.15))
		lagen.append(Transform3D(basis, ra.p(o.y, o.z)))
	return lagen


# ================================================================ Kronentor

## Das Kronentor (TORE "Kronentor", s 280): zwei Luftwurzeln, die vom
## Südwestast herabhängen und sich über dem Regal zu einem Spitzbogen
## kreuzen. Innen stehen sie hinter der Leitlinie „Stammseite F" im
## Fleisch, außen hängt die eine an der Lippe vorbei bis in den Knoll.
## Dunkle Borke mit warmem Randlicht (`Weltenbaum.stoff_tor`): Das Tor steht
## im Gegenlicht vor dem Taldunst und soll sich dort als Rahmen lesen.
static func _kronentor_bauen(level: Level01) -> void:
	var tor: Dictionary = {}
	for t: Dictionary in Level01.TORE:
		if String(t["name"]) == "Kronentor":
			tor = t
	if tor.is_empty():
		return
	var bahn := Bahn.new(level)
	var knoten := Node3D.new()
	knoten.name = "Kronentor"
	level.deko.add_child(knoten)
	var rng := PropWerkzeug.zufall(6101)
	var linien := _tor_linien(bahn, level, tor)
	var st := Riesenstamm.bauer()
	var schatten := Riesenstamm.bauer()
	for linie: PackedVector3Array in linien:
		# Drei dünne, ungleiche Stränge umeinander gewunden, die sich stellenweise
		# lösen: eine Luftwurzel, kein Rohr.
		for strang in 3:
			var phase := TAU * float(strang) / 3.0 + rng.randf_range(-0.4, 0.4)
			var aus := rng.randf_range(0.26, 0.4)
			var r0 := rng.randf_range(0.2, 0.3)
			var punkte := PackedVector3Array()
			var radien := PackedFloat32Array()
			var lauf := 0.0
			for i in linie.size():
				var t := (linie[mini(i + 1, linie.size() - 1)] - linie[maxi(i - 1, 0)]).normalized()
				var seit := t.cross(Vector3.UP).normalized()
				if seit.length_squared() < 0.01:
					seit = Vector3.RIGHT
				var auf := seit.cross(t).normalized()
				if i > 0:
					lauf += linie[i].distance_to(linie[i - 1])
				var w := phase + lauf * 0.45
				var loesen := 1.0 + 0.35 * maxf(0.0, sin(lauf * 0.21 + phase * 2.0))
				punkte.append(linie[i] + (seit * cos(w) + auf * sin(w)) * aus * loesen)
				radien.append(r0 * (1.0 + 0.25 * sin(lauf * 0.7 + phase)))
			var g := Weltenbaum.rohr(punkte, radien, {"seiten": 6, "beulen": 0.12,
					"saat": rng.randi(), "uv_mass": 0.9})
			Weltenbaum.gitter_faerben(g, _torfarbe, 0.2)
			Weltenbaum.gitter_schreiben(st, g)
		var gs := Weltenbaum.rohr(linie, PackedFloat32Array(_gleich(linie.size(), 0.6)),
				{"seiten": 5, "beulen": 0.0, "saat": 3})
		Weltenbaum.gitter_faerben(gs, _weiss, 0.2)
		Weltenbaum.gitter_schreiben(schatten, gs)
	# Dünne Luftwurzeln, die vom Ast hängen und hoch über dem Weg enden.
	var deck := level.boden_bei(float(tor["s"]))
	for k in 5:
		var s := float(tor["s"]) + rng.randf_range(-4.0, 4.0)
		var q := rng.randf_range(-3.0, 4.5)
		var oben := bahn.p(s, q, 0.0)
		var ast := _suedwestast(oben)
		oben.y = ast.x - ast.y * 0.5
		var ende_y := deck + rng.randf_range(10.2, 12.0)
		if oben.y - ende_y < 1.0:
			continue
		var punkte := PackedVector3Array()
		for i in 5:
			var t := float(i) / 4.0
			punkte.append(Vector3(oben.x + 0.3 * sin(t * 3.0 + float(k)), lerpf(oben.y, ende_y, t),
					oben.z + 0.3 * cos(t * 2.0 + float(k))))
		var g := Weltenbaum.rohr(punkte, PackedFloat32Array([0.14, 0.12, 0.1, 0.08, 0.05]),
				{"seiten": 5, "ende": "spitz", "saat": rng.randi(), "uv_mass": 1.2})
		Weltenbaum.gitter_faerben(g, _torfarbe, 0.2)
		Weltenbaum.gitter_schreiben(st, g)
	var mi := _knoten(knoten, "Luftwurzeln", Riesenstamm.fertig(st), Weltenbaum.stoff_tor(), false)
	mi.visibility_range_end = NAH_BIS
	mi.visibility_range_end_margin = RAND
	var sk := _knoten(knoten, "Schatten", Riesenstamm.fertig(schatten), Weltenbaum.stoff_tor(), true)
	sk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

	var sperre := StaticBody3D.new()
	sperre.name = "Sichtsperre"
	sperre.collision_layer = LevelWerkzeuge.SICHTSPERRE
	sperre.collision_mask = 0
	knoten.add_child(sperre)
	for linie: PackedVector3Array in linien:
		_sichtkoerper_linie(sperre, linie, deck + 6.0, 2.0)


## Luftwurzeln des Tors: kaum Verdeckung, Moos nur obenauf.
static func _torfarbe(_p: Vector3, nn: Vector3) -> Color:
	return Color(0.82, 0.82, 0.82, clampf(nn.y * 0.6, 0.0, 1.0))


static func _gleich(n: int, wert: float) -> Array[float]:
	var a: Array[float] = []
	for i in n:
		a.append(wert)
	return a


## Mitte und Radius des Südwestasts (AESTE[0]) über einem Weltpunkt – wie
## `Weltenbaum.ast_in` ihn baut: fast waagerecht aus dem Stamm, dann
## hinauf. Rückgabe Vector2(Welt-Y der Achse, Radius).
static func _suedwestast(p: Vector3) -> Vector2:
	var a: Dictionary = AESTE[0]
	var y0: float = a["y"]
	var laenge: float = a["laenge"]
	var steigung: float = a["steigung"]
	var radius: float = a["radius"]
	var r0 := stamm_radius(y0) * 0.55
	var weite := Vector2(p.x - achse().x, p.z - achse().z).length()
	var t := clampf((weite - r0) / laenge, 0.0, 1.0)
	var y := y0 + laenge * (steigung * t * 0.45 + steigung * 0.9 * t * t) \
			- radius * 0.5 * (1.0 - t) * (1.0 - t)
	return Vector2(y, lerpf(radius, radius * 0.28, pow(t, 0.8)))


## Die zwei Mittellinien des Kronentors: jede vom Ast herab, über den Weg
## hinweg zur anderen Seite. Sie kreuzen sich im Scheitel.
static func _tor_linien(bahn: Bahn, level: Level01, tor: Dictionary) -> Array[PackedVector3Array]:
	var s: float = tor["s"]
	var deck := level.boden_bei(s)
	# Mittellinie über der Bündelweite: Die Unterkante der Stränge liegt auf
	# dem Scheitel aus TORE.
	var h: float = float(tor["scheitel"]) + 1.1
	var e := _kante(level, s)
	var halb: float = tor["abstand"]
	# Oben stecken die Wurzeln in der Achse des Asts.
	var ast := _suedwestast(bahn.p(s, 0.0, 0.0)).x - deck
	var innen := _flanke_fuss(s)
	var boden_aussen := boden_unter_wendel(s + 3.0) - deck
	# Ein wenig vor und zurück (erste Komponente, s): Luftwurzeln hängen nie
	# in einer Ebene.
	var a: Array[Vector3] = [
		Vector3(0.6, 1.8, ast), Vector3(0.8, 1.0, h + 3.6), Vector3(0.4, 0.2, h + 0.9),
		Vector3(0.0, -1.6, h + 0.1), Vector3(0.2, -3.8, h - 1.5), Vector3(-0.3, -halb - 0.7, h - 3.9),
		Vector3(-0.1, innen - 1.5, 4.2), Vector3(-0.4, innen - 2.1, 1.3),
		Vector3(-0.5, innen - 2.6, -1.2),
	]
	var b: Array[Vector3] = [
		Vector3(-0.6, -1.8, ast), Vector3(-0.8, -1.0, h + 3.6), Vector3(-0.4, -0.2, h + 0.9),
		Vector3(0.0, 1.6, h + 0.1), Vector3(-0.2, 3.8, h - 1.5), Vector3(0.3, halb + 0.7, h - 3.9),
		Vector3(0.1, e + 1.25, 3.0), Vector3(0.4, e + 1.35, -1.0), Vector3(0.2, e + 1.7, -6.0),
		Vector3(0.6, e + 2.4, boden_aussen * 0.7), Vector3(0.5, e + 3.0, boden_aussen - 1.0),
	]
	var linien: Array[PackedVector3Array] = []
	for steuer: Array[Vector3] in [a, b]:
		var linie := PackedVector3Array()
		var n := steuer.size()
		for i in n - 1:
			var p0 := steuer[maxi(i - 1, 0)]
			var p1 := steuer[i]
			var p2 := steuer[i + 1]
			var p3 := steuer[mini(i + 2, n - 1)]
			for k in 4:
				var t := float(k) / 4.0
				var c := 0.5 * ((2.0 * p1) + (-p0 + p2) * t
						+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
						+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)
				linie.append(bahn.p(s + c.x, c.y, c.z))
		var letzte := steuer[n - 1]
		linie.append(bahn.p(s + letzte.x, letzte.y, letzte.z))
		linien.append(linie)
	return linien


# ================================================================ Knoten

## Ein Netz als Knoten; ohne Schatten, außer `schatten`.
static func _knoten(eltern: Node3D, bezeichnung: String, netz: Mesh, stoff: Material,
		schatten: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eltern.add_child(mi)
	return mi
