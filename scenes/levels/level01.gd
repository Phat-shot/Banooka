extends LevelBasis
class_name Level01
## Level 01 – „Wurzelschlucht": der Kammweg zum Weltenbaum.
##
## Man beginnt in einem dunklen Hallenwald, tritt nach dreißig Metern auf
## einen Hangweg zwanzig Meter über einem sonnigen Tal und hat von da an das
## Ziel vor Augen: einen Weltenbaum auf der anderen Talseite. Durch die
## Fallklamm geht es an einem Wasserfall vorbei hinab, über die Bachwiese zu
## Füßen des Riesen und auf einer Wurzel, die sich um seinen Stamm windet,
## hinauf bis unter die Krone. Eine Bildregel trägt alles: LINKS ist zu,
## dunkel und nah, RECHTS ist offen, hell und weit.
##
##       0 –  33  A Waldsaum    Hallenwald, Erdspalt, Enthüllung
##      33 – 104  B Hangweg     Grat über dem Tal, Kanzel, Moosbank, Pforte
##     104 – 160  C Fallklamm   Terrassen am Wasserfall hinab
##     160 – 198  D Bachwiese   Furt, zwei Geheimnisse, Wurzelaufgang
##     198 – 273  E Wurzelwendel  Spirale R 22 um den Stamm, +17 %
##     273 – 287  F Kronentor   Wurzelregal, Zielportal bei 283
##
## DATEN. Diese Datei hält ALLE Daten des Levels als Konstanten – Verlauf,
## Wegabschnitte, Ränder, Bach, Begehbares, Leitlinien, Todeszonen, Kisten,
## Gegner, Früchte – und bietet Abfragen darauf an (`breite_bei`,
## `boden_bei`, `rand_profil` …). Wer etwas ans Level baut, liest hier nach
## und rechnet nichts doppelt.
##
## MODULE. Die Optik bauen Module in `scenes/levels/level01/` (je eine
## Klasse mit statischen Funktionen, Parameter `level: Level01`):
##   L01Boden       stoff(level, abschnitt) -> Material, bauschritte(level)
##   L01Saum        bauschritte(level)
##   L01Gelaende    bauschritte(level), hoehe(x, z), optik(level, eintrag)
##   L01Wasser      bauschritte(level)
##   L01Weltenbaum  bauschritte(level), optik(level, eintrag)
##   L01Wegbauten   bauschritte(level), optik(level, eintrag)
##   L01Wald        bauschritte(level)
##   L01Rasen       bauschritte(level)
##   L01Stimmung    bauschritte(level)
## `bauschritte()` liefert [{"text", "tun": Callable}] und wird abgefragt,
## wenn der Verlauf schon steht. Die Schritte laufen in fester Reihenfolge
## (siehe `_bauschritte`). `optik()` bekommt einen Eintrag aus
## `BEGEHBARES` samt berechneter Lage und liefert die Optik passgenau zur
## Kollision; sie wird als Kind des Körpers eingehängt. Liefert ein Haken
## null, steht dort ein grauer Platzhalter.
##
## KOLLISION. Der Rohbau baut sie vollständig, die Module bauen keine:
##   Ebene 1    Wegdecke, Stufenwände, Schultern bis zu den Leitlinien,
##              flache Böden (Startboden, Kanzel, Nischenboden, Wiese)
##   Ebene 16   „Spielergrenze" (`LevelWerkzeuge.SPIELERGRENZE`): Leit-
##              linien, Randkörper, erhöhtes Begehbares. Die Figur (Maske
##              1|16) stößt daran an, der Kamerastrahl (1|8) nicht – er
##              startet sechs Meter VOR der Figur, und eine einrückende Wand
##              zwischen Blickpunkt und Figur zöge die Kamera vor die Figur.
##   Todeszonen Area3D je Streifen (Gruppe "todeszonen"), einseitig, mit
##              der Oberkante mindestens sechs Meter unter dem Weg.
##
## KOORDINATEN. Wie überall `s` = Strecke auf dem Verlauf, `q` = quer dazu
## (positiv = rechts, also zum Tal), Höhen relativ zur Wegdecke an der
## Stelle (`boden_bei(s)`), außer wo ein Name auf `_y` endet (Welt-Y).

const KISTE := preload("res://scenes/crates/Kiste.tscn")
const FRUCHT := preload("res://scenes/fruits/Frucht.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")

# =========================================================== Marken

const M_WALDSAUM := 0.0
const M_HANGWEG := 33.0
const M_FALLKLAMM := 104.0
const M_BACHWIESE := 160.0
const M_WENDEL := 198.0
const M_KRONENTOR := 273.0
const M_ZIEL := 283.0
const M_ENDE := 287.0

## Ebene 5 (Wert 16), siehe Kopf.
const SPIELERGRENZE := LevelWerkzeuge.SPIELERGRENZE

# =========================================================== Verlauf

## Glättung der Kurve. Mit 0,45 schießen die Griffe über, und die Spirale
## eiert. Länge damit 287,0 m; die Richtzeit folgt daraus (94,5 s).
const GLAETTUNG := 0.34

## Stützpunkte des Verlaufs. Die Spirale (E) liegt auf einem Kreis mit R 22
## um die Achse des Weltenbaums, θ 45° → 240° in Schritten von 21,67°.
const PUNKTE := [
	Vector3(0, 26, 4), Vector3(0, 26, -14), Vector3(1, 26, -30),              # A
	Vector3(4, 25.5, -48), Vector3(9, 24.5, -65), Vector3(15, 23.5, -81),     # B
	Vector3(21, 22.6, -95),
	Vector3(27, 21.3, -106), Vector3(33.5, 18.6, -115.5),                     # C
	Vector3(40.5, 15.2, -123.5), Vector3(48.5, 11.6, -130.2), Vector3(57, 9.0, -135.6),
	Vector3(65.5, 7.6, -140.8), Vector3(74, 7.1, -146.3), Vector3(81.5, 7.1, -152.4),  # D
	Vector3(87.58, 7.6, -158.48), Vector3(92.23, 9.04, -165.32),              # E: Spirale
	Vector3(94.02, 10.49, -173.4), Vector3(92.7, 11.93, -181.56),
	Vector3(88.46, 13.38, -188.66), Vector3(81.9, 14.82, -193.7),
	Vector3(73.94, 16.27, -195.95), Vector3(65.72, 17.71, -195.11),
	Vector3(58.38, 19.16, -191.29), Vector3(52.97, 20.6, -185.04),
	Vector3(49.97, 21.0, -179.84), Vector3(46.47, 21.0, -173.78),             # F: Regal
]

# =========================================================== Weg

## Die Wegabschnitte – einzige Quelle für Breite, Höhe und Lücken.
##
## "hoehe"/"hoehe_ende": absolute Welt-Y der Decke (linear); ohne Angabe
## folgt die Decke der Kurve. So fällt der Weg in der Fallklamm in
## Terrassen, während die Kamera die glatte Kurve fährt (Abstand zur Kurve
## höchstens 1,2 m). "stoff" und "kronenlicht" sind Wünsche an L01Boden.
##
## Aneinanderstoßende Einträge gleicher Nahthöhe gelten als durchgehend
## (`strang_bei`); nur echte Lücken und die Stufen bei 66, 133 und 145 sind
## Kanten.
const ABSCHNITTE := [
	{"name": "A1", "von": 0.0, "bis": 25.0, "breite": 10.0,
			"stoff": "waldweg", "kronenlicht": 1.0},
	# Erdspalt 25,0–27,5: 2,5 m flach
	{"name": "A2", "von": 27.5, "bis": 33.0, "breite": 10.0,
			"stoff": "waldweg", "kronenlicht": 0.5},
	{"name": "B1", "von": 33.0, "bis": 56.0, "breite": 9.5,
			"stoff": "waldweg", "kronenlicht": 0.0},
	# Kerbe 56,0–59,0: 3,0 m, landet 0,17 m tiefer
	{"name": "B2", "von": 59.0, "bis": 66.0, "breite": 9.0,
			"stoff": "waldweg", "kronenlicht": 0.0},
	# Felsstufe bei 66: 0,84 m ab. B3 läuft eben, bis die Kurve ihn bei 80
	# wieder einholt.
	{"name": "B3", "von": 66.0, "bis": 80.0, "breite": 9.0,
			"hoehe": 23.90, "hoehe_ende": 23.92,
			"stoff": "waldweg", "kronenlicht": 0.0},
	{"name": "B4", "von": 80.0, "bis": 92.0, "breite": 9.0, "breite_ende": 7.5,
			"stoff": "waldweg", "kronenlicht": 0.0},
	{"name": "B5", "von": 92.0, "bis": 104.0, "breite": 7.5,
			"stoff": "waldweg", "kronenlicht": 0.0},
	{"name": "C1", "von": 104.0, "bis": 118.0, "breite": 7.5,
			"stoff": "waldweg", "kronenlicht": 0.0},
	# Fallkerbe 118,0–121,0: 3,0 m, landet 0,76 m tiefer
	{"name": "C2", "von": 121.0, "bis": 133.0, "breite": 7.5,
			"hoehe": 20.0, "hoehe_ende": 18.0,
			"stoff": "waldweg", "kronenlicht": 0.0},
	# Stufe bei 133: 1,6 m ab
	{"name": "C3", "von": 133.0, "bis": 145.0, "breite": 8.0,
			"hoehe": 16.4, "hoehe_ende": 13.8,
			"stoff": "waldweg", "kronenlicht": 0.0},
	# Stufe bei 145: 1,4 m ab
	{"name": "C4", "von": 145.0, "bis": 160.0, "breite": 8.5, "breite_ende": 12.0,
			"hoehe": 12.4, "hoehe_ende": 8.91,
			"stoff": "waldweg", "kronenlicht": 0.8},
	{"name": "D1", "von": 160.0, "bis": 173.0, "breite": 12.0,
			"stoff": "waldweg", "kronenlicht": 0.5},
	# Furt 173–183: Wasser, zwei Trittsteine (BEGEHBARES)
	{"name": "D2", "von": 183.0, "bis": 194.0, "breite": 12.0,
			"stoff": "waldweg", "kronenlicht": 0.5},
	{"name": "D3", "von": 194.0, "bis": 198.0, "breite": 12.0, "breite_ende": 8.0,
			"stoff": "waldweg", "kronenlicht": 0.5},
	{"name": "E1", "von": 198.0, "bis": 210.5, "breite": 8.0,
			"stoff": "wurzelruecken", "kronenlicht": 0.7},
	# G1 210,5–213,5: 3,0 m, +0,51 m, nicht tödlich (Wiesenboden darunter)
	{"name": "E2", "von": 213.5, "bis": 243.0, "breite": 8.0,
			"stoff": "wurzelruecken", "kronenlicht": 0.7},
	# G2 243,0–245,5: 2,5 m, +0,42 m, tödlich
	{"name": "E3", "von": 245.5, "bis": 273.0, "breite": 8.0,
			"stoff": "wurzelruecken", "kronenlicht": 0.7},
	{"name": "F1", "von": 273.0, "bis": 287.0, "breite": 8.0, "breite_ende": 12.0,
			"stoff": "wurzelruecken", "kronenlicht": 0.6},
]

## Die Lücken mit Namen – ableitbar aus ABSCHNITTE, hier nur zum Nachschlagen
## (Lückenlippen, Fruchtbögen, Stirnflächen).
const LUECKEN := [
	{"name": "Erdspalt", "von": 25.0, "bis": 27.5, "toedlich": true},
	{"name": "Kerbe", "von": 56.0, "bis": 59.0, "toedlich": true},
	{"name": "Fallkerbe", "von": 118.0, "bis": 121.0, "toedlich": true},
	{"name": "Furt", "von": 173.0, "bis": 183.0, "toedlich": true},
	{"name": "G1", "von": 210.5, "bis": 213.5, "toedlich": false},
	{"name": "G2", "von": 243.0, "bis": 245.5, "toedlich": true},
]

## Die Ränder des Weges, je Seite (-1 links, +1 rechts; 0 = quer, Stirn).
##
## "typ":      FLACH (Gelände schließt bündig an), BOESCHUNG (Erdhang 35–60°
##             hinauf), FELS_AUF (Felswand hinauf), FELS_AB (Felswand hinab),
##             UFER (niedrige Erdkante bis zum Wasser), STIRN (Stirnfläche
##             einer Lücke oder Stufe), WURZEL (baut der Weltenbaum).
## "abstand":  Querabstand, an dem das Profil beginnt (Fuß bzw. Lippe), bis
##             "abstand_ende" linear; fehlt er, ist es die Wegkante.
## "hoehe":    Höhe der Wand über (AUF/BOESCHUNG) bzw. Tiefe unter (AB, UFER)
##             der Wegdecke, bis "hoehe_ende" linear.
## "fuss_y":   Welt-Y des Wandfußes unten (AB, UFER, STIRN), bis "fuss_y_ende".
## "krone_q":  Querabstand, an dem die Böschung oben ausläuft; dahinter steigt
##             der Hangwald bis Welt-Y "hang_y".
## "nische":   Umriss der Moosbank-Nische (wie die Leitlinie, [Vector2(s, q)]).
## Für eine einzelne Stelle rechnet `rand_profil(s, seite)` alles aus.
const RAENDER := [
	# --- links: zu, dunkel, nah ---
	{"von": -8.0, "bis": 33.0, "seite": -1, "typ": "FLACH", "abstand": 5.0},
	{"von": 33.0, "bis": 92.0, "seite": -1, "typ": "BOESCHUNG", "abstand": 5.0,
			"hoehe": 4.0, "hoehe_ende": 6.0, "krone_q": 11.0, "hang_y": 40.0, "nische": [
				Vector2(78.0, -5.3), Vector2(82.0, -9.5), Vector2(84.0, -11.0),
				Vector2(92.0, -11.0), Vector2(95.0, -8.0), Vector2(98.0, -5.3)]},
	{"von": 92.0, "bis": 104.0, "seite": -1, "typ": "FELS_AUF", "abstand": 5.3,
			"hoehe": 3.0, "hoehe_ende": 5.0, "felsnase": true},
	{"von": 104.0, "bis": 133.0, "seite": -1, "typ": "FELS_AUF", "abstand": 4.6,
			"hoehe": 2.0, "hoehe_ende": 9.6},
	{"von": 133.0, "bis": 145.0, "seite": -1, "typ": "FELS_AUF", "abstand": 4.9,
			"hoehe": 9.6, "hoehe_ende": 12.7},
	{"von": 145.0, "bis": 160.0, "seite": -1, "typ": "FELS_AUF", "abstand": 5.1,
			"abstand_ende": 6.8, "hoehe": 12.7, "hoehe_ende": 14.0},
	{"von": 160.0, "bis": 173.0, "seite": -1, "typ": "FLACH"},
	{"von": 173.0, "bis": 183.0, "seite": -1, "typ": "UFER", "hoehe": 1.8,
			"fuss_y": 5.4},
	{"von": 183.0, "bis": 198.0, "seite": -1, "typ": "FLACH"},
	{"von": 198.0, "bis": 288.0, "seite": -1, "typ": "WURZEL"},
	# --- rechts: offen, hell, weit ---
	{"von": -8.0, "bis": 33.0, "seite": 1, "typ": "FLACH", "abstand": 5.0},
	{"von": 33.0, "bis": 40.0, "seite": 1, "typ": "FELS_AB", "hoehe": 19.0,
			"fuss_y": 7.0},
	{"von": 40.0, "bis": 48.0, "seite": 1, "typ": "FELS_AB", "abstand": 9.5,
			"hoehe": 19.0, "fuss_y": 7.0, "kanzel": true},
	{"von": 48.0, "bis": 104.0, "seite": 1, "typ": "FELS_AB", "hoehe": 18.0,
			"hoehe_ende": 20.0, "fuss_y": 7.0, "fuss_y_ende": 2.5},
	{"von": 104.0, "bis": 145.0, "seite": 1, "typ": "FELS_AB", "hoehe": 20.0,
			"hoehe_ende": 8.0, "fuss_y": 2.5, "fuss_y_ende": 5.0},
	{"von": 145.0, "bis": 160.0, "seite": 1, "typ": "UFER", "hoehe": 7.0,
			"hoehe_ende": 3.5, "fuss_y": 5.4, "kanal": true},
	{"von": 160.0, "bis": 173.0, "seite": 1, "typ": "FLACH"},
	{"von": 173.0, "bis": 183.0, "seite": 1, "typ": "UFER", "hoehe": 1.8,
			"fuss_y": 5.4},
	{"von": 183.0, "bis": 198.0, "seite": 1, "typ": "FLACH"},
	{"von": 198.0, "bis": 288.0, "seite": 1, "typ": "WURZEL"},
	# --- quer: Lücken und Stufen ---
	{"von": 25.0, "bis": 27.5, "seite": 0, "typ": "STIRN", "name": "Erdspalt",
			"fuss_y": 17.0, "auslauf": 5.0},
	{"von": 56.0, "bis": 59.0, "seite": 0, "typ": "STIRN", "name": "Kerbe",
			"fuss_y": 16.0},
	{"von": 66.0, "bis": 66.0, "seite": 0, "typ": "STIRN", "name": "Felsstufe",
			"stufe": 0.84},
	{"von": 118.0, "bis": 121.0, "seite": 0, "typ": "STIRN", "name": "Fallkerbe",
			"fuss_y": 18.0},
	{"von": 133.0, "bis": 133.0, "seite": 0, "typ": "STIRN", "name": "Stufe 133",
			"stufe": 1.6},
	{"von": 145.0, "bis": 145.0, "seite": 0, "typ": "STIRN", "name": "Stufe 145",
			"stufe": 1.4},
]

## Der Wasserfallpfeiler links in der Fallklamm: Von ihm stürzt der obere
## Fall (FAELLE "oben"). Höhe über dem Weg.
const WASSERFALLPFEILER := {"von": 112.0, "bis": 122.0, "seite": -1, "q": 7.5,
		"hoehe": 11.0}

# =========================================================== Wasser

## Der Bach als Kette von Punkten (Welt-XZ; "punkt".y = Wasserspiegel).
## Vom Tümpel unter dem unteren Fall am rechten Fuß der Fallklamm entlang
## (C4-Kanal), durch die Furt quer über die Bachwiese, am Westfuß des
## Knolls unter dem Kronentor vorbei ins Tal. Tödlich nur Furt und Kanal;
## unter beiden liegt ohnehin eine Todeszone des Rohbaus.
const BACH := [
	{"name": "Tuempel", "punkt": Vector3(41.7, 6.4, -103.0), "bett_y": 4.6,
			"wasser_y": 6.4, "breite": 12.0, "toedlich": false},
	{"punkt": Vector3(58.0, 6.3, -112.0), "bett_y": 5.0, "wasser_y": 6.3,
			"breite": 6.0, "toedlich": true},
	{"punkt": Vector3(76.0, 6.2, -124.0), "bett_y": 5.0, "wasser_y": 6.2,
			"breite": 6.0, "toedlich": true},
	{"punkt": Vector3(86.0, 6.1, -134.0), "bett_y": 5.0, "wasser_y": 6.1,
			"breite": 7.0, "toedlich": false},
	{"name": "Furt", "punkt": Vector3(72.6, 6.0, -145.3), "bett_y": 5.3,
			"wasser_y": 6.0, "breite": 10.0, "toedlich": true},
	{"punkt": Vector3(60.0, 5.8, -157.0), "bett_y": 4.8, "wasser_y": 5.8,
			"breite": 6.0, "toedlich": false},
	{"punkt": Vector3(50.0, 5.4, -172.0), "bett_y": 4.4, "wasser_y": 5.4,
			"breite": 7.0, "toedlich": false},
	{"punkt": Vector3(44.0, 4.6, -195.0), "bett_y": 3.6, "wasser_y": 4.6,
			"breite": 7.0, "toedlich": false},
	{"punkt": Vector3(40.0, 4.0, -225.0), "bett_y": 3.0, "wasser_y": 4.0,
			"breite": 8.0, "toedlich": false},
]

## Die Fallbänder als Polylinien in Wegkoordinaten: Vector3(s, q, Welt-Y).
## `fall_punkte(name)` rechnet sie in Weltpunkte um.
##   oben     vom Pfeiler (y ≈ 31,5) links in das Felsbecken (y ≈ 19,5)
##   kerbe    das Wasser schießt unter der Fallkerbe hindurch (Bett y ≈ 18)
##   unten    die rechte Wand hinab in den Tümpel
##   rinnsal  in der Kerbe von der Böschung bis über die Felskante
const FAELLE := {
	"oben": [Vector3(116.6, -8.6, 31.5), Vector3(116.8, -8.2, 25.5),
			Vector3(117.0, -7.6, 19.5)],
	"kerbe": [Vector3(119.4, -7.6, 19.2), Vector3(119.5, -4.0, 18.3),
			Vector3(119.5, 0.0, 18.0), Vector3(119.6, 4.2, 17.8)],
	"unten": [Vector3(119.8, 4.6, 17.8), Vector3(120.2, 8.0, 12.0),
			Vector3(120.8, 14.0, 6.4)],
	"rinnsal": [Vector3(57.5, -9.5, 28.8), Vector3(57.5, -5.6, 25.5),
			Vector3(57.5, -4.5, 23.0), Vector3(57.5, 0.0, 21.5),
			Vector3(57.5, 4.8, 20.8), Vector3(57.6, 6.0, 12.0)],
}

# =========================================================== Weltenbaum

## Der Riese. Achse in Welt-XZ; Radien und Höhen in Metern, Höhen Welt-Y.
## Die Krone ist ein Schirm: Unterseite am Rand y 32, am Stamm y 40.
const WELTENBAUM := {
	"achse": Vector2(72.0, -174.0),
	"r_fuss": 12.0,
	"r_krone": 8.0,
	"krone_mitte_y": 54.0,
	"krone_r": 34.0,
	"unterseite_rand_y": 32.0,
	"unterseite_stamm_y": 40.0,
	"oberseite_y": 72.0,
	"spirale_r": 22.0,
}

# =========================================================== Begehbares

## Alles außerhalb der Wegdecke, worauf man steht oder woran man stößt. Der
## Eintrag legt die KOLLISION fest; die Optik baut der Haken "optik" genau
## darauf (Findling-Regel: sichtbare Oberseite = Kollisionsoberkante).
##
## Formen:
##   kasten    "s", "q" Mitte, "groesse" Vector3(quer, hoch, längs), "oben"
##             Oberkante über dem Weg. Der Kasten folgt der Neigung des
##             Weges zwischen seinen Enden.
##   zylinder  "s", "q", "radius", "hoehe", Oberkante "oben" oder "oben_y".
##   kapsel    "s", "q", "radius", "laenge" (quer über den Weg), "oben".
##   streifen  flacher Boden "von"–"bis" zwischen "innen" und "aussen"
##             (Polylinien [Vector2(s, q)]), Oberkante "oben" über dem Weg
##             oder "oben_y"; "hoehe" = Dicke.
##   sweep     Querschnitt "profil" [Vector2(q, Höhe über dem Weg)] von
##             "von" bis "bis", auf Wunsch linear bis "profil_ende".
## Lokale Achsen der Körper (kasten, zylinder, kapsel): X quer nach rechts,
## Y hoch, -Z den Weg entlang; Ursprung in der Mitte der Form. Streifen und
## Sweeps liegen in Weltkoordinaten (Körper ohne Versatz).
const BEGEHBARES := [
	# --- A ---
	{"name": "Startboden", "form": "streifen", "von": -7.5, "bis": 0.2,
			"innen": [Vector2(-7.5, -5.9), Vector2(0.2, -5.9)],
			"aussen": [Vector2(-7.5, 5.9), Vector2(0.2, 5.9)],
			"oben": 0.0, "hoehe": 2.0, "ebene": 1, "optik": "wegbauten"},
	{"name": "Mooslog", "form": "kapsel", "s": 8.0, "q": 0.0, "radius": 0.4,
			"laenge": 8.8, "oben": 0.8, "ebene": 16, "optik": "wegbauten"},
	# --- B ---
	{"name": "Kanzel", "form": "kasten", "s": 44.0, "q": 7.125,
			"groesse": Vector3(4.75, 3.0, 8.0), "oben": 0.0, "ebene": 1,
			"optik": "wegbauten"},
	{"name": "Kanzelkiefer", "form": "zylinder", "s": 41.6, "q": 8.7,
			"radius": 0.45, "hoehe": 7.0, "oben": 6.0, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Nischenboden", "form": "streifen", "von": 78.0, "bis": 98.0,
			"aussen": [Vector2(78.0, -5.3), Vector2(82.0, -9.5), Vector2(84.0, -11.0),
				Vector2(92.0, -11.0), Vector2(95.0, -8.0), Vector2(98.0, -5.3)],
			"oben": 0.0, "hoehe": 2.0, "ebene": 1, "optik": "wegbauten"},
	{"name": "Moosbank", "form": "kasten", "s": 87.0, "q": -8.25,
			"groesse": Vector3(3.5, 3.6, 8.0), "oben": 2.6, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Pforte links", "form": "kasten", "s": 101.5, "q": -2.975,
			"groesse": Vector3(1.55, 3.6, 4.0), "oben": 2.6, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Pforte rechts", "form": "kasten", "s": 101.5, "q": 2.975,
			"groesse": Vector3(1.55, 3.6, 4.0), "oben": 2.6, "ebene": 16,
			"optik": "wegbauten"},
	# --- D ---
	{"name": "Furtstein 1", "form": "zylinder", "s": 175.9, "q": -1.0,
			"radius": 1.3, "hoehe": 2.0, "oben_y": 7.2, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Furtstein 2", "form": "zylinder", "s": 180.1, "q": 0.8,
			"radius": 1.3, "hoehe": 2.0, "oben_y": 7.2, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Findlingsturm", "form": "kasten", "s": 189.75, "q": 6.8,
			"groesse": Vector3(1.6, 4.0, 2.5), "oben": 3.0, "ebene": 16,
			"optik": "wegbauten"},
	{"name": "Wurzelknie", "form": "kasten", "s": 191.5, "q": -6.8,
			"groesse": Vector3(1.6, 3.4, 3.0), "oben": 2.4, "ebene": 16,
			"optik": "wegbauten"},
	# --- E ---
	# Die Wiese hängt bei 196–200 am Weg; ein Sturz dort kostet nur den
	# Rückweg. Unter G1 läuft sie durch: Wer in den Bruch fällt, landet auf
	# der Wiese und geht über sie zurück.
	{"name": "Wurzelwiese", "form": "streifen", "von": 196.0, "bis": 214.0,
			"innen": [Vector2(196.0, 3.9), Vector2(214.0, 3.9)],
			"aussen": [Vector2(196.0, 12.4), Vector2(214.0, 12.4)],
			"oben_y": 7.0, "hoehe": 2.0, "ebene": 1, "optik": "gelaende"},
	{"name": "Wiesenboden G1", "form": "streifen", "von": 210.0, "bis": 214.0,
			"innen": [Vector2(210.0, -4.2), Vector2(214.0, -4.2)],
			"aussen": [Vector2(210.0, 4.0), Vector2(214.0, 4.0)],
			"oben_y": 7.0, "hoehe": 2.0, "ebene": 1, "optik": "gelaende"},
	# Wurzelkörper unter dem Weg, wo man unter ihn laufen könnte (über der
	# Wiese und an den Stirnseiten von G1). Oberkante knapp unter der Decke.
	{"name": "Wurzelkoerper E1", "form": "sweep", "von": 195.5, "bis": 210.5,
			"profil": [Vector2(-4.0, -0.03), Vector2(4.0, -0.03), Vector2(4.0, -4.5),
				Vector2(-4.0, -4.5)], "ebene": 16, "optik": "weltenbaum"},
	{"name": "Wurzelkoerper E2", "form": "sweep", "von": 213.5, "bis": 218.0,
			"profil": [Vector2(-4.0, -0.03), Vector2(4.0, -0.03), Vector2(4.0, -5.0),
				Vector2(-4.0, -5.0)], "ebene": 16, "optik": "weltenbaum"},
	# Innen steiles Wurzelfleisch (56°, nicht begehbar) bis zur Stammwand.
	{"name": "Innenflanke", "form": "sweep", "von": 197.0, "bis": 273.5,
			"profil": [Vector2(-4.0, -4.0), Vector2(-4.0, -0.03), Vector2(-10.0, 9.0),
				Vector2(-14.0, 9.0), Vector2(-14.0, -4.0)],
			"ebene": 16, "optik": "weltenbaum"},
	# Außen der Rindenwulst über den Wurzelgruben: 0,6 m, fängt die Drift.
	{"name": "Rindenwulst 1", "form": "sweep", "von": 214.0, "bis": 243.0,
			"profil": [Vector2(4.0, -0.8), Vector2(4.0, 0.3), Vector2(4.2, 0.6),
				Vector2(4.55, 0.6), Vector2(4.7, 0.3), Vector2(4.7, -0.8)],
			"ebene": 16, "optik": "weltenbaum"},
	{"name": "Rindenwulst 2", "form": "sweep", "von": 245.5, "bis": 273.0,
			"profil": [Vector2(4.0, -0.8), Vector2(4.0, 0.3), Vector2(4.2, 0.6),
				Vector2(4.55, 0.6), Vector2(4.7, 0.3), Vector2(4.7, -0.8)],
			"ebene": 16, "optik": "weltenbaum"},
	# Luftwurzel am Stamm: Oberkante +3,6 → +5,2, Unterkante ≥ +3,0.
	{"name": "Oberwurzel", "form": "sweep", "von": 250.0, "bis": 263.0,
			"profil": [Vector2(-5.4, 3.0), Vector2(-5.4, 3.6), Vector2(-7.6, 3.6),
				Vector2(-7.6, 3.0)],
			"profil_ende": [Vector2(-5.4, 4.6), Vector2(-5.4, 5.2), Vector2(-7.6, 5.2),
				Vector2(-7.6, 4.6)],
			"ebene": 16, "optik": "weltenbaum"},
]

# =========================================================== Grenzen

## Unsichtbare Leitlinien auf Ebene 16, je [Vector2(s, q)] = Innenseite.
## "aussen": auf welcher Seite der Laufrichtung die Wand steht (+1 rechts,
## -1 links). "schulter": Vector2(von, bis) – dort liegt zwischen Wegkante
## und Leitlinie ein Streifen Boden (Ebene 1), damit man bis an die Wand
## gehen kann und nicht in einen Spalt rutscht.
const LEITLINIEN := [
	{"name": "Querwand Start", "aussen": 1.0, "hoehe": 6.0, "unten": 3.0,
			"punkte": [Vector2(-7.0, -6.2), Vector2(-7.0, 6.2)]},
	{"name": "Links", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(-7.0, 198.0), "punkte": [
				Vector2(-7.0, -5.6), Vector2(33.0, -5.6), Vector2(34.0, -5.3),
				Vector2(78.0, -5.3), Vector2(82.0, -9.5), Vector2(84.0, -11.0),
				Vector2(92.0, -11.0), Vector2(95.0, -8.0), Vector2(98.0, -5.3),
				Vector2(99.2, -3.8), Vector2(103.8, -3.8), Vector2(104.6, -4.6),
				Vector2(133.0, -4.6), Vector2(133.5, -4.9), Vector2(145.0, -4.9),
				Vector2(145.5, -5.1), Vector2(150.0, -5.5), Vector2(160.0, -6.8),
				Vector2(188.5, -6.8), Vector2(189.5, -7.8), Vector2(193.5, -7.8),
				Vector2(194.5, -6.8), Vector2(198.5, -4.6)]},
	{"name": "Rechts A/B", "aussen": 1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(-7.0, 50.0), "punkte": [
				Vector2(-7.0, 5.6), Vector2(33.0, 5.6), Vector2(33.5, 5.2),
				Vector2(39.5, 5.2), Vector2(40.0, 9.8), Vector2(48.0, 9.8),
				Vector2(48.5, 5.2), Vector2(50.0, 5.2)]},
	# Rechts D mit der Hecke der Wurzelwiese (r ≈ 34).
	{"name": "Rechts D", "aussen": 1.0, "hoehe": 6.0, "unten": 5.0,
			"schulter": Vector2(159.5, 194.0), "punkte": [
				Vector2(159.5, 6.8), Vector2(187.0, 6.8), Vector2(188.0, 7.8),
				Vector2(191.5, 7.8), Vector2(192.5, 6.8), Vector2(194.0, 6.8),
				Vector2(196.0, 12.4), Vector2(214.0, 12.4), Vector2(214.4, 4.8)]},
	{"name": "Stammseite F", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"punkte": [Vector2(272.5, -4.1), Vector2(287.3, -6.1)]},
	{"name": "Querwand Ende", "aussen": 1.0, "hoehe": 6.0, "unten": 3.0,
			"punkte": [Vector2(287.3, 6.4), Vector2(287.3, -6.4)]},
]

## Todeszonen (Plan Abschnitt 12), einseitig. Oberkante "oben_y" fest oder
## "unter_weg" Meter unter der Wegdecke (je Stück neu gerechnet). Die Regel:
## höchstens min(Weg − 6, tiefstes Begehbares im Umriss − 2,5).
const TODESZONEN := [
	{"name": "K-A links", "von": -8.0, "bis": 33.0, "q_von": -36.0, "q_bis": -5.6,
			"oben_y": 20.0},
	{"name": "K-A rechts", "von": -8.0, "bis": 33.0, "q_von": 5.6, "q_bis": 36.0,
			"oben_y": 20.0},
	{"name": "K-Spalt", "von": 24.0, "bis": 28.5, "q_von": -12.0, "q_bis": 12.0,
			"oben_y": 20.0},
	{"name": "K-B", "von": 33.0, "bis": 104.0, "q_von": 4.8, "q_bis": 40.0,
			"unter_weg": 6.0},
	{"name": "K-Kerbe", "von": 55.0, "bis": 60.0, "q_von": -12.0, "q_bis": 12.0,
			"oben_y": 18.5},
	{"name": "K-C", "von": 104.0, "bis": 150.0, "q_von": 3.8, "q_bis": 40.0,
			"unter_weg": 6.0},
	{"name": "K-Fallkerbe", "von": 117.0, "bis": 122.0, "q_von": -12.0,
			"q_bis": 12.0, "oben_y": 14.0},
	{"name": "K-Kanal", "von": 145.0, "bis": 165.0, "q_von": 4.3, "q_bis": 30.0,
			"oben_y": 3.5},
	{"name": "K-D", "von": 160.0, "bis": 186.0, "q_von": 7.5, "q_bis": 40.0,
			"oben_y": 1.0},
	{"name": "K-Furt", "von": 173.0, "bis": 183.0, "q_von": -7.0, "q_bis": 7.0,
			"oben_y": 5.0},
	{"name": "K-Wiese", "von": 194.0, "bis": 216.0, "q_von": 14.0, "q_bis": 40.0,
			"oben_y": 1.0},
	{"name": "K-E", "von": 214.0, "bis": 273.0, "q_von": 4.6, "q_bis": 40.0,
			"unter_weg": 6.0},
	# G2 ist tödlich; unter dem Bruch selbst liegt sonst nichts.
	{"name": "K-G2", "von": 242.0, "bis": 246.5, "q_von": -4.2, "q_bis": 4.8,
			"unter_weg": 6.0},
	{"name": "K-F", "von": 273.0, "bis": 290.0, "q_von": 4.2, "q_bis": 40.0,
			"oben_y": 14.0},
	{"name": "K-F Ende", "von": 287.3, "bis": 300.0, "q_von": -30.0, "q_bis": 30.0,
			"oben_y": 14.0},
]

# =========================================================== Orte für Module

## Löcher im Blätterdach des Hallenwalds (für Wald und Lichtschächte).
const LICHTLOECHER := [
	{"s": 14.0, "q": 3.5, "radius": 3.0},
	{"s": 22.0, "q": -3.0, "radius": 3.0},
]

## Wurzeltore und Kronentor. "abstand": halbe lichte Weite von Fuß zu Fuß,
## "scheitel": Höhe über dem Weg; Sichtsperre erst ab 6 m.
const TORE := [
	{"name": "Waldtor", "s": 3.0, "abstand": 7.5, "scheitel": 9.2},
	{"name": "Pfortentor", "s": 101.5, "abstand": 4.4, "scheitel": 9.2},
	{"name": "Riesentor", "s": 162.0, "abstand": 9.0, "scheitel": 10.0},
	{"name": "Kronentor", "s": 280.0, "abstand": 5.3, "scheitel": 9.5},
]

## Die zwei Torriesen an der Einfahrt zur Bachwiese.
const TORRIESEN := [
	{"s": 162.0, "q": -9.0, "hoehe": 34.0, "radius": 1.8},
	{"s": 162.0, "q": 9.0, "hoehe": 36.0, "radius": 1.8},
]

## Die drei Talriesen rechts der Bachwiese (Stamm Ø 3–4 m).
const TALRIESEN := [
	{"s": 166.0, "q": 12.5, "hoehe": 36.0, "radius": 1.8},
	{"s": 184.0, "q": 11.5, "hoehe": 32.0, "radius": 1.6},
	{"s": 198.0, "q": 14.8, "hoehe": 38.0, "radius": 2.0},
]

## Rahmenbäume und Enthüllungsrahmen. "fuss": Höhe des Stammfußes über dem
## Weg (negativ = auf einem Sims unter der Kante).
const RAHMENBAUM_STELLEN := [
	{"s": 28.0, "q": 7.0, "fuss": 0.0, "hoehe": 12.0, "art": "totholz"},
	{"s": 31.0, "q": 6.5, "fuss": 0.0, "hoehe": 1.8, "art": "findling"},
	{"s": 41.6, "q": 8.7, "fuss": 0.0, "hoehe": 9.0, "art": "drehkiefer"},
	{"s": 50.0, "q": 9.5, "fuss": -7.0, "hoehe": 14.0, "art": "sims"},
	{"s": 76.0, "q": 10.5, "fuss": -8.5, "hoehe": 15.0, "art": "sims"},
	{"s": 98.0, "q": 9.0, "fuss": -6.5, "hoehe": 13.0, "art": "sims"},
	{"s": 101.5, "q": 7.0, "fuss": -1.0, "hoehe": 22.0, "art": "torbaum"},
]

# =========================================================== Spiel

## Alle 62 Kisten. "stapel": 1 = auf einer Kiste; "auf": Name eines
## Eintrags aus BEGEHBARES, auf dessen Oberkante die Kiste steht.
## Keine schwebenden Kisten; Stapel nur bei |q| ≥ 2,6.
const KISTEN := [
	# --- A: 9 ---
	{"art": Kiste.Art.NORMAL, "s": 12.0, "q": -1.0},
	{"art": Kiste.Art.NORMAL, "s": 12.0, "q": 1.0},
	{"art": Kiste.Art.NORMAL, "s": 13.4, "q": 0.0},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 15.5, "q": -2.5},
	{"art": Kiste.Art.NORMAL, "s": 21.0, "q": -2.8},
	{"art": Kiste.Art.NORMAL, "s": 21.0, "q": -2.8, "stapel": 1},
	{"art": Kiste.Art.NORMAL, "s": 21.0, "q": 1.0},
	{"art": Kiste.Art.SCHUTZ, "s": 21.0, "q": 2.6},
	{"art": Kiste.Art.NORMAL, "s": 30.5, "q": -2.0},
	# --- B: 13 ---
	{"art": Kiste.Art.CHECKPOINT, "s": 44.0, "q": 6.0},
	{"art": Kiste.Art.NORMAL, "s": 46.5, "q": 7.5},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 46.5, "q": 8.6},
	{"art": Kiste.Art.NORMAL, "s": 52.0, "q": -1.5},
	{"art": Kiste.Art.NORMAL, "s": 52.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 75.0, "q": -1.2},
	{"art": Kiste.Art.NORMAL, "s": 75.0, "q": 1.2},
	{"art": Kiste.Art.FEDER, "s": 80.5, "q": -3.4},
	{"art": Kiste.Art.NORMAL, "s": 85.0, "q": -7.5, "auf": "Moosbank"},
	{"art": Kiste.Art.NORMAL, "s": 86.5, "q": -8.0, "auf": "Moosbank"},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 88.5, "q": -8.5, "auf": "Moosbank"},
	{"art": Kiste.Art.NORMAL, "s": 96.0, "q": -2.8},
	{"art": Kiste.Art.NORMAL, "s": 96.0, "q": -2.8, "stapel": 1},
	# --- C: 10 ---
	{"art": Kiste.Art.CHECKPOINT, "s": 107.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 111.0, "q": 1.5},
	{"art": Kiste.Art.NORMAL, "s": 124.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 124.0, "q": 1.2},
	{"art": Kiste.Art.TNT, "s": 127.7, "q": -2.3},
	{"art": Kiste.Art.NORMAL, "s": 126.5, "q": -2.3},
	{"art": Kiste.Art.NORMAL, "s": 128.9, "q": -2.3},
	{"art": Kiste.Art.NORMAL, "s": 127.7, "q": -1.1},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 137.0, "q": -2.0},
	{"art": Kiste.Art.NORMAL, "s": 154.0, "q": 2.0},
	# --- D: 13 ---
	{"art": Kiste.Art.CHECKPOINT, "s": 166.0, "q": 0.0},
	{"art": Kiste.Art.NITRO, "s": 168.0, "q": -3.4},
	{"art": Kiste.Art.NORMAL, "s": 169.2, "q": -3.4},
	{"art": Kiste.Art.NORMAL, "s": 171.0, "q": 3.0},
	{"art": Kiste.Art.NORMAL, "s": 171.0, "q": 4.2},
	{"art": Kiste.Art.NORMAL, "s": 184.5, "q": -1.6},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 184.5, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 184.5, "q": 1.6},
	{"art": Kiste.Art.NORMAL, "s": 189.2, "q": 6.8, "auf": "Findlingsturm"},
	{"art": Kiste.Art.NORMAL, "s": 190.4, "q": 6.8, "auf": "Findlingsturm"},
	{"art": Kiste.Art.NORMAL, "s": 191.5, "q": -6.8, "auf": "Wurzelknie"},
	{"art": Kiste.Art.NORMAL, "s": 196.5, "q": 2.6},
	{"art": Kiste.Art.NORMAL, "s": 196.5, "q": 2.6, "stapel": 1},
	# --- E: 14 ---
	{"art": Kiste.Art.NORMAL, "s": 202.0, "q": -1.5},
	{"art": Kiste.Art.NORMAL, "s": 202.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 226.0, "q": -1.2},
	{"art": Kiste.Art.CHECKPOINT, "s": 232.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 236.0, "q": 1.5},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 236.0, "q": -1.5},
	# Auf der Oberwurzel bei q -6,0 statt -6,5: Weiter innen stäke die Kiste
	# mit ihrer Innenkante im Wurzelfleisch.
	{"art": Kiste.Art.NORMAL, "s": 253.0, "q": -6.0, "auf": "Oberwurzel"},
	{"art": Kiste.Art.NORMAL, "s": 255.5, "q": -6.0, "auf": "Oberwurzel"},
	{"art": Kiste.Art.NORMAL, "s": 258.0, "q": -6.0, "auf": "Oberwurzel"},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 261.0, "q": -6.0, "auf": "Oberwurzel"},
	{"art": Kiste.Art.SPRUNG, "s": 257.0, "q": -2.4},
	{"art": Kiste.Art.TNT, "s": 268.0, "q": -1.5},
	{"art": Kiste.Art.NORMAL, "s": 268.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 268.0, "q": 1.5},
	# --- F: 3 ---
	{"art": Kiste.Art.LEBEN, "s": 278.0, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 280.5, "q": -3.0},
	{"art": Kiste.Art.NORMAL, "s": 280.5, "q": 3.0},
]

## Die neun Gegner, je drei. "quer": patrouilliert quer zum Weg, sonst
## entlang. Die Lehre folgt dem Angebot: Kröte nach dem Kistendreieck
## (Drehschlag), Käfer unter der Felsstufe (Draufspringen), Spinne in der
## engen Pforte (Slide).
const GEGNER := [
	{"art": "kroete", "s": 18.0, "q": 0.0, "weite": 3.5, "quer": true},
	{"art": "kaefer", "s": 69.5, "q": 0.0, "weite": 1.25, "quer": false},
	{"art": "spinne", "s": 101.5, "q": 0.0, "weite": 1.0, "quer": true},
	{"art": "kaefer", "s": 140.0, "q": 0.0, "weite": 2.5, "quer": true},
	{"art": "spinne", "s": 170.0, "q": 1.0, "weite": 2.0, "quer": true},
	{"art": "kroete", "s": 194.5, "q": 0.0, "weite": 2.5, "quer": true},
	{"art": "kroete", "s": 222.0, "q": 0.0, "weite": 2.0, "quer": true},
	# Zugleich Trampolin: Abprall plus Doppelsprung (4,03 m) trägt auf das
	# niedrige Ende der Oberwurzel (Geheimnis S5).
	{"art": "kaefer", "s": 249.0, "q": -1.5, "weite": 1.25, "quer": false},
	{"art": "spinne", "s": 263.0, "q": 0.0, "weite": 2.0, "quer": true},
]

## Früchte. "reihe": gleichmäßig von–bis auf Höhe "h" (Vorgabe 0,9);
## "boden": dasselbe knapp über dem Boden (weist auf den Slide); "bogen":
## über eine Lücke, "scheitel" = Höhe der mittleren Frucht über dem Weg;
## "punkte": einzelne Vector3(s, q, h).
const FRUECHTE := [
	# --- A ---
	{"art": "reihe", "von": 5.0, "bis": 7.0, "anzahl": 4, "q": 0.0},
	{"art": "reihe", "von": 15.0, "bis": 19.5, "anzahl": 4, "q": -1.2},
	{"art": "bogen", "von": 24.0, "bis": 28.5, "anzahl": 6, "q": 0.0, "scheitel": 2.2},
	# --- B ---
	{"art": "reihe", "von": 36.0, "bis": 40.0, "anzahl": 5, "q": 1.0},
	{"art": "bogen", "von": 55.0, "bis": 60.0, "anzahl": 6, "q": 0.0, "scheitel": 2.2},
	{"art": "reihe", "von": 62.0, "bis": 65.0, "anzahl": 3, "q": 0.0},
	# Die Moosbank kündigt sich an: eine Spur von der Feder hinauf.
	{"art": "punkte", "punkte": [Vector3(81.3, -4.3, 2.4), Vector3(82.1, -5.3, 3.2),
			Vector3(82.9, -6.3, 3.6)]},
	{"art": "punkte", "punkte": [Vector3(89.8, -7.4, 3.5), Vector3(90.5, -8.4, 3.5)]},
	{"art": "boden", "von": 97.0, "bis": 101.0, "anzahl": 5, "q": 0.0},
	# --- C ---
	{"art": "reihe", "von": 108.0, "bis": 112.0, "anzahl": 5, "q": -1.0},
	{"art": "bogen", "von": 117.0, "bis": 122.0, "anzahl": 6, "q": 0.0, "scheitel": 2.3},
	{"art": "reihe", "von": 135.0, "bis": 138.5, "anzahl": 4, "q": 1.5},
	{"art": "reihe", "von": 148.0, "bis": 157.0, "anzahl": 8, "q": -1.0},
	# --- D ---
	{"art": "boden", "von": 163.0, "bis": 169.0, "anzahl": 6, "q": 1.5},
	# Auf jedem Trittstein drei (Oberkante 7,2 absolut, hier relativ).
	{"art": "stein", "name": "Furtstein 1", "anzahl": 3},
	{"art": "stein", "name": "Furtstein 2", "anzahl": 3},
	{"art": "punkte", "punkte": [Vector3(187.8, 5.0, 2.2), Vector3(188.4, 5.8, 3.3)]},
	{"art": "punkte", "punkte": [Vector3(190.4, -7.2, 3.3), Vector3(190.4, -6.4, 3.3),
			Vector3(192.6, -6.8, 3.3)]},
	# --- E ---
	{"art": "reihe", "von": 205.0, "bis": 209.0, "anzahl": 5, "q": 0.0},
	{"art": "bogen", "von": 209.5, "bis": 214.5, "anzahl": 6, "q": 0.0, "scheitel": 2.3},
	{"art": "reihe", "von": 216.0, "bis": 220.0, "anzahl": 5, "q": 0.0},
	{"art": "reihe", "von": 227.5, "bis": 230.5, "anzahl": 3, "q": 0.5},
	{"art": "reihe", "von": 237.5, "bis": 241.5, "anzahl": 4, "q": 0.0},
	{"art": "bogen", "von": 242.0, "bis": 246.5, "anzahl": 6, "q": 0.0, "scheitel": 2.3},
	# Geheimnis S5: vom Käfer aus hinauf zur Oberwurzel.
	{"art": "punkte", "punkte": [Vector3(249.2, -2.4, 3.0), Vector3(249.8, -3.6, 3.9),
			Vector3(250.4, -4.8, 4.4)]},
	# Geheimnis S4: über der Sprungfeder.
	{"art": "punkte", "punkte": [Vector3(257.0, -2.4, 3.2), Vector3(257.0, -2.4, 4.5),
			Vector3(257.0, -2.4, 5.8)]},
	# --- F ---
	{"art": "reihe", "von": 274.0, "bis": 277.0, "anzahl": 4, "q": 0.0},
]

# =========================================================== Laufzeit

## Berechnete Fassungen der BEGEHBARES-Einträge (mit Lage und Querschnitten),
## je Name. Entsteht beim ersten Zugriff, wenn der Verlauf steht.
var _begehbar_berechnet := {}


# =========================================================== Aufbau

## Aufbau in fester Reihenfolge: Weg → Saum → Gelände → Wasser →
## Begehbares → Weltenbaum → Wegbauten → Wald → Rasen → Boden-Marken →
## Gefahren, Kisten, Gegner, Früchte, Portale → Stimmung.
##
## Der Verlauf entsteht VOR der Liste: Die Module dürfen beim Zusammen-
## stellen ihrer Schritte schon auf ihn und die Abfragen schauen.
func _bauschritte() -> Array:
	_verlauf_anlegen()
	var schritte: Array = [{"text": "Der Weg wird angelegt", "tun": _weg_bauen}]
	schritte.append_array(L01Saum.bauschritte(self))
	schritte.append_array(L01Gelaende.bauschritte(self))
	schritte.append_array(L01Wasser.bauschritte(self))
	schritte.append({"text": "Felsen, Wurzeln und Grenzen", "tun": _begehbares_bauen})
	schritte.append_array(L01Weltenbaum.bauschritte(self))
	schritte.append_array(L01Wegbauten.bauschritte(self))
	schritte.append_array(L01Wald.bauschritte(self))
	schritte.append_array(L01Rasen.bauschritte(self))
	schritte.append_array(L01Boden.bauschritte(self))
	schritte.append_array([
		{"text": "Abgründe", "tun": _gefahren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Portale", "tun": _portale_setzen},
	])
	schritte.append_array(L01Stimmung.bauschritte(self))
	return schritte


func _verlauf_anlegen() -> void:
	# Staub beim Landen und Rennen: die Farbe des Waldwegs, eine Spur ins
	# Kiesgrau. Die Farbe überlebt den Szenenwechsel, deshalb setzt sie
	# jedes Level selbst (LevelBasis setzt vor dem Aufbau die Vorgabe).
	Effekte.staubfarbe = Farben.WEG_HELL.lerp(Farben.KIES_HELL, 0.3)
	verlauf = LevelWerkzeuge.kurve_aus_punkten(PUNKTE, GLAETTUNG)
	_begehbar_berechnet.clear()


## Die Wegdecke: je Stoff ein sichtbares Netz (L01Boden.stoff), dazu EINE
## Kollision über alle Abschnitte – nur so kennt die Stufenkollision alle
## Nachbarn. Ohne Kante und Klippe: Ränder baut der Saum.
func _weg_bauen() -> void:
	var gruppen := {}
	var reihenfolge: Array[Material] = []
	for a: Dictionary in ABSCHNITTE:
		var stoff: Material = L01Boden.stoff(self, a)
		if stoff == null:
			stoff = Materialbibliothek.waldweg()
		if not gruppen.has(stoff):
			gruppen[stoff] = []
			reihenfolge.append(stoff)
		(gruppen[stoff] as Array).append(a)
	for stoff in reihenfolge:
		var weg := LevelWerkzeuge.korridor(geometrie, verlauf, gruppen[stoff],
				{"oben": stoff}, {
			"nur_decke": true, "uv_quer": true, "schritt": 1.0,
			"quer_teilung": 2, "kollision": false,
		})
		weg.name = "Weg"
		# Der Boden wirft keinen Schatten, den jemand sähe; jede Schatten-
		# stufe zeichnete ihn trotzdem noch einmal.
		for kind in weg.get_children():
			if kind is GeometryInstance3D:
				(kind as GeometryInstance3D).cast_shadow = \
						GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var boden := LevelWerkzeuge.korridor(geometrie, verlauf, ABSCHNITTE, {}, {
		"nur_decke": true, "schritt": 1.0, "sichtbar": false,
		"kollision": true, "stufen_kollision": true, "ebene": 1,
	})
	boden.name = "Wegboden"


## Begehbares mit Kollision und Optik, Leitlinien und Schultern.
func _begehbares_bauen() -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Begehbares"
	geometrie.add_child(wurzel)
	for roh: Dictionary in BEGEHBARES:
		var e := begehbar(String(roh["name"]))
		var koerper := StaticBody3D.new()
		koerper.name = String(e["name"])
		koerper.collision_layer = int(e["ebene"])
		koerper.collision_mask = 0
		koerper.transform = e["lage"]
		for form in _formen(e):
			koerper.add_child(form)
		var optik := _optik(e)
		if optik == null:
			optik = _platzhalter(e)
		if optik != null:
			koerper.add_child(optik)
		wurzel.add_child(koerper)
	_leitlinien_bauen()
	_schultern_bauen()


func _optik(e: Dictionary) -> Node3D:
	match String(e.get("optik", "")):
		"wegbauten":
			return L01Wegbauten.optik(self, e)
		"weltenbaum":
			return L01Weltenbaum.optik(self, e)
		"gelaende":
			return L01Gelaende.optik(self, e)
	return null


func _leitlinien_bauen() -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Leitlinien"
	geometrie.add_child(wurzel)
	for e: Dictionary in LEITLINIEN:
		var linie := LevelWerkzeuge.leitlinie(wurzel, verlauf, e["punkte"],
				float(e.get("hoehe", 6.0)), SPIELERGRENZE, float(e.get("unten", 3.0)),
				1.0, float(e.get("aussen", 0.0)))
		linie.name = String(e["name"])


## Boden zwischen Wegkante und Leitlinie (Ebene 1), bündig mit der Decke.
##
## Die Leitlinie steht mit Absicht ein Stück außerhalb der Wegkante: Der
## Rasen dort sieht begehbar aus, also muss er es sein. Ohne diesen
## Streifen rutschte die Figur in den Spalt zwischen Decke und Wand und
## klemmte dort, halb versunken. Je Wegabschnitt getrennt, damit die
## Schulter an den Stufen mit der Decke springt; zwei Meter dick, damit man
## unter einer oberen Schulter nicht hindurchkommt.
func _schultern_bauen() -> void:
	var koerper := StaticBody3D.new()
	koerper.name = "Schultern"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	for e: Dictionary in LEITLINIEN:
		if not e.has("schulter"):
			continue
		var bereich: Vector2 = e["schulter"]
		var punkte: Array = e["punkte"]
		for a: Dictionary in ABSCHNITTE:
			var von := maxf(float(a["von"]), bereich.x)
			var bis := minf(float(a["bis"]), bereich.y)
			if bis - von < 0.05:
				continue
			var anzahl := maxi(ceili(bis - von), 1)
			var vorher := PackedVector3Array()
			for i in anzahl + 1:
				var s := lerpf(von, bis, float(i) / float(anzahl))
				var jetzt := _schulter_schnitt(a, punkte, s)
				if not vorher.is_empty() and not jetzt.is_empty():
					koerper.add_child(_prisma(vorher, jetzt))
				vorher = jetzt
	geometrie.add_child(koerper)


func _schulter_schnitt(a: Dictionary, punkte: Array, s: float) -> PackedVector3Array:
	var schnitt := PackedVector3Array()
	var q_linie := _polylinie_q(punkte, s)
	if is_nan(q_linie):
		return schnitt
	var seite := signf(q_linie)
	var von: float = a["von"]
	var bis: float = a["bis"]
	var t := inverse_lerp(von, bis, s) if bis > von else 0.0
	var breite_a: float = a["breite"]
	var halb := lerpf(breite_a, float(a.get("breite_ende", breite_a)), t) * 0.5
	var innen := halb - 0.15
	var aussen := absf(q_linie) + 0.4
	if aussen <= innen + 0.2:
		return schnitt
	var oben := LevelWerkzeuge.eintrag_hoehe(verlauf, a, s)
	for p: Vector2 in [Vector2(innen, oben), Vector2(aussen, oben),
			Vector2(aussen, oben - 2.0), Vector2(innen, oben - 2.0)]:
		var w := LevelWerkzeuge.punkt_frei(verlauf, s, seite * p.x)
		schnitt.append(Vector3(w.x, p.y, w.z))
	return schnitt


## Todeszonen nach TODESZONEN.
func _gefahren_setzen() -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Todeszonen"
	geometrie.add_child(wurzel)
	for e: Dictionary in TODESZONEN:
		var von: float = e["von"]
		var bis: float = e["bis"]
		var q_von: float = e["q_von"]
		var q_bis: float = e["q_bis"]
		var zonen: Array[Area3D] = []
		if e.has("unter_weg"):
			# In Stücken, die an keiner Stufe vorbeilaufen: Die Oberkante
			# folgt dem Weg je Stück linear.
			var tief: float = e["unter_weg"]
			var grenzen: Array[float] = [von]
			for a: Dictionary in ABSCHNITTE:
				for g: float in [float(a["von"]), float(a["bis"])]:
					if g > von + 0.01 and g < bis - 0.01 and not grenzen.has(g):
						grenzen.append(g)
			grenzen.append(bis)
			grenzen.sort()
			for i in grenzen.size() - 1:
				var a_s := grenzen[i]
				var b_s := grenzen[i + 1]
				var teile := maxi(ceili((b_s - a_s) / 6.0), 1)
				for k in teile:
					var s0 := lerpf(a_s, b_s, float(k) / float(teile))
					var s1 := lerpf(a_s, b_s, float(k + 1) / float(teile))
					# Knapp innerhalb des Stücks messen, damit die Stufe nicht
					# den Wert des Nachbarn liefert.
					var y0 := boden_bei(s0 + 0.01) - tief
					var y1 := boden_bei(s1 - 0.01) - tief
					zonen.append(LevelWerkzeuge.todeszone(wurzel, verlauf, s0, s1,
							q_von, q_bis, y0, y1))
		else:
			zonen.append(LevelWerkzeuge.todeszone(wurzel, verlauf, von, bis,
					q_von, q_bis, float(e["oben_y"])))
		for z in zonen:
			z.name = String(e["name"])


# =========================================================== Spielobjekte

func _kisten_setzen() -> void:
	for e: Dictionary in KISTEN:
		var k := KISTE.instantiate() as Kiste
		k.art = e["art"]
		var s: float = e["s"]
		var auf: String = e.get("auf", "")
		if not auf.is_empty() and int(begehbar(auf).get("ebene", 1)) == SPIELERGRENZE:
			# Die Kiste steht auf Ebene 16. Der Bodenstrahl der Prüfung fragt
			# (noch) nur Ebene 1 ab und fände darunter nichts oder einen Boden
			# Meter tiefer. Bis er 1|16 abfragt, gilt sie als absichtlich ohne
			# Ebene-1-Boden; die zweite Gruppe sagt, warum.
			k.add_to_group("schwebende_kisten")
			k.add_to_group("kisten_auf_spielergrenze")
		k.position = kisten_ort(e)
		k.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		objekte.add_child(k)


## Weltort der Kiste aus einem KISTEN-Eintrag (Mitte, 0,5 m über dem Boden).
func kisten_ort(e: Dictionary) -> Vector3:
	var s: float = e["s"]
	var q: float = e["q"]
	var auf: String = e.get("auf", "")
	var p := weg_punkt(s, q)
	if not auf.is_empty():
		p.y = oberkante(auf, s, q)
	p.y += 0.5 + float(e.get("stapel", 0))
	return p


## Weltorte aller Kisten (für Freiräume im Bewuchs).
func kisten_orte() -> Array[Vector3]:
	var orte: Array[Vector3] = []
	for e: Dictionary in KISTEN:
		orte.append(kisten_ort(e))
	return orte


func _gegner_setzen() -> void:
	for e: Dictionary in GEGNER:
		var szene: PackedScene = SUMPFKROETE
		match String(e["art"]):
			"kaefer":
				szene = PANZERKAEFER
			"spinne":
				szene = STELZENSPINNE
		_gegner(szene, float(e["s"]), float(e["q"]), float(e["weite"]), bool(e["quer"]))


## Setzt einen Gegner so, dass er beim Patrouillieren nicht vom Weg läuft:
## seitlicher Versatz und Weite werden auf die Wegbreite begrenzt, die
## Strecke von der Kante weggeschoben. Kanten sind nur echte Lücken und
## Stufen – eine Naht zweier gleich hoher Abschnitte ist keine.
func _gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool) -> Gegner:
	var g := szene.instantiate() as Gegner
	strecke = weg_von_der_kante(strecke, 2.5)
	var rand := rand_bei(strecke)
	if quer:
		seitlich = clampf(seitlich, -rand * 0.5, rand * 0.5)
		weite = minf(weite, maxf(rand - absf(seitlich), 0.5))
	else:
		seitlich = clampf(seitlich, -rand, rand)
		var strang := strang_bei(strecke)
		var frei := minf(strecke - strang.x, strang.y - strecke) - 1.0
		weite = minf(weite, maxf(frei, 0.5))
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized() if quer else richtung
	# Position VOR add_child: Gegner merken sich in _ready() ihre Startposition.
	g.position = weg_punkt(strecke, seitlich, 0.05)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


func _fruechte_setzen() -> void:
	for e: Dictionary in FRUECHTE:
		match String(e["art"]):
			"reihe", "boden":
				var hoehe: float = 0.45 if String(e["art"]) == "boden" else float(e.get("h", 0.9))
				var anzahl: int = e["anzahl"]
				for i in anzahl:
					var t := float(i) / maxf(float(anzahl - 1), 1.0)
					_frucht(lerpf(float(e["von"]), float(e["bis"]), t), float(e["q"]), hoehe)
			"bogen":
				# Grundhöhe 0,9 an beiden Enden, die Mitte auf dem Scheitel.
				var anzahl: int = e["anzahl"]
				var scheitel: float = e["scheitel"]
				for i in anzahl:
					var t := float(i) / maxf(float(anzahl - 1), 1.0)
					_frucht(lerpf(float(e["von"]), float(e["bis"]), t), float(e["q"]),
							0.9 + sin(t * PI) * (scheitel - 0.9))
			"punkte":
				for p: Vector3 in e["punkte"]:
					_frucht(p.x, p.y, p.z)
			"stein":
				var stein := begehbar(String(e["name"]))
				var s: float = stein["s"]
				var q: float = stein["q"]
				var oben := oberkante(String(e["name"]), s, q)
				var anzahl: int = e["anzahl"]
				for i in anzahl:
					var t := float(i) / maxf(float(anzahl - 1), 1.0)
					var p := weg_punkt(s + lerpf(-0.6, 0.6, t), q)
					p.y = oben + 0.9
					_frucht_welt(p)


func _frucht(s: float, q: float, h: float) -> void:
	_frucht_welt(weg_punkt(s, q, h))


func _frucht_welt(p: Vector3) -> void:
	var f := FRUCHT.instantiate() as Node3D
	f.position = p
	objekte.add_child(f)


func _portale_setzen() -> void:
	var start := STARTPORTAL.instantiate() as Node3D
	start.position = weg_punkt(1.0, 0.0, 0.1)
	start.rotation.y = LevelWerkzeuge.drehung(verlauf, 1.0)
	objekte.add_child(start)

	var ziel := ZIELPORTAL.instantiate() as Node3D
	# Unter der Krone: Die Lichtsäule endet bei y 33, die Unterseite der
	# Krone liegt dort bei 34 und mehr.
	ziel.set("saeulen_hoehe", 12.0)
	ziel.position = weg_punkt(M_ZIEL, 0.0, 0.1)
	ziel.rotation.y = LevelWerkzeuge.drehung(verlauf, M_ZIEL)
	objekte.add_child(ziel)


## Im Web zwei Schattenstufen statt vier. Jede Stufe zeichnet alles, was
## Schatten wirft, noch einmal. Nur wenn die Szene noch vier Stufen trägt:
## Wer das Licht der Szene selbst umstellt, hat hier das letzte Wort.
func _nach_aufbau() -> void:
	if debug:
		_zaehlen()
	if not OS.has_feature("web"):
		return
	var sonne := _sonne()
	if sonne == null \
			or sonne.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		return
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sonne.directional_shadow_max_distance = minf(sonne.directional_shadow_max_distance, 60.0)
	sonne.directional_shadow_split_1 = 0.2


## Die schattenwerfende Sonne der Szene, oder null.
func _sonne() -> DirectionalLight3D:
	var sonne := get_node_or_null("Sonne") as DirectionalLight3D
	if sonne != null:
		return sonne
	for kind in get_children():
		if kind is DirectionalLight3D and (kind as DirectionalLight3D).shadow_enabled:
			return kind as DirectionalLight3D
	return null


func _zaehlen() -> void:
	var fruechte := 0
	for kind in objekte.get_children():
		if kind is Frucht:
			fruechte += 1
	print("Level 01: Weg %.1f m, Kisten %d, Gegner %d, Früchte %d" % [
			verlauf.get_baked_length(), KISTEN.size(), GEGNER.size(), fruechte])


# =========================================================== Abfragen

## Die Proben, die dieses Level ausdrücklich will (werkzeuge/level_check.gd).
func pruefprofil() -> Dictionary:
	return {"sicht": true, "gefaelle": true, "todeszonen": true}


## Der Eintrag aus ABSCHNITTE, der `s` enthält, oder {} in einer Lücke.
func abschnitt_bei(s: float) -> Dictionary:
	for a: Dictionary in ABSCHNITTE:
		if s >= float(a["von"]) and s <= float(a["bis"]):
			return a
	return {}


## Breite des Weges an dieser Stelle. 0.0 bedeutet: hier ist eine Lücke.
func breite_bei(s: float) -> float:
	var a := abschnitt_bei(s)
	if a.is_empty():
		return 0.0
	var von: float = a["von"]
	var bis: float = a["bis"]
	var t := inverse_lerp(von, bis, s) if bis > von else 0.0
	var breite: float = a["breite"]
	return lerpf(breite, float(a.get("breite_ende", breite)), t)


func ist_luecke(s: float) -> bool:
	return breite_bei(s) <= 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func rand_bei(s: float, sicherheit: float = 1.3) -> float:
	return maxf(breite_bei(s) * 0.5 - sicherheit, 0.0)


## Welt-Y der Wegdecke. In einer Lücke linear zwischen den Kanten davor und
## danach (für Fruchtbögen und Zonen), vor dem Anfang und hinter dem Ende
## die Höhe des ersten bzw. letzten Abschnitts.
func boden_bei(s: float) -> float:
	var a := abschnitt_bei(s)
	if not a.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, a, s)
	var vorher: Dictionary = {}
	var nachher: Dictionary = {}
	for e: Dictionary in ABSCHNITTE:
		if float(e["bis"]) <= s:
			vorher = e
		elif float(e["von"]) >= s and nachher.is_empty():
			nachher = e
	if vorher.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, nachher, float(nachher["von"]))
	if nachher.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, vorher, float(vorher["bis"]))
	var ha := LevelWerkzeuge.eintrag_hoehe(verlauf, vorher, float(vorher["bis"]))
	var hb := LevelWerkzeuge.eintrag_hoehe(verlauf, nachher, float(nachher["von"]))
	return lerpf(ha, hb, inverse_lerp(float(vorher["bis"]), float(nachher["von"]), s))


## Punkt auf dem Weg: `q` quer, `h` über der Wegdecke. Auch vor dem Anfang
## und hinter dem Ende (dort geradeaus weiter).
func weg_punkt(s: float, q: float = 0.0, h: float = 0.0) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(verlauf, s, q)
	p.y = boden_bei(s) + h
	return p


## Das durchgehende Stück Weg um `s` als Vector2(von, bis): Abschnitte, die
## gleich hoch aneinanderstoßen, zählen zusammen. Nur Lücken und Stufen
## trennen. In einer Lücke: Vector2(s, s).
func strang_bei(s: float) -> Vector2:
	var index := -1
	for i in ABSCHNITTE.size():
		var a: Dictionary = ABSCHNITTE[i]
		if s >= float(a["von"]) and s <= float(a["bis"]):
			index = i
			break
	if index < 0:
		return Vector2(s, s)
	var anfang := index
	while anfang > 0 and _durchgehend(anfang - 1, anfang):
		anfang -= 1
	var ende := index
	while ende < ABSCHNITTE.size() - 1 and _durchgehend(ende, ende + 1):
		ende += 1
	return Vector2(float(ABSCHNITTE[anfang]["von"]), float(ABSCHNITTE[ende]["bis"]))


func _durchgehend(i: int, j: int) -> bool:
	var a: Dictionary = ABSCHNITTE[i]
	var b: Dictionary = ABSCHNITTE[j]
	var naht: float = a["bis"]
	if absf(float(b["von"]) - naht) > 0.01:
		return false
	return absf(LevelWerkzeuge.eintrag_hoehe(verlauf, a, naht)
			- LevelWerkzeuge.eintrag_hoehe(verlauf, b, naht)) < 0.05


## Schiebt eine Strecke von der Kante eines Strangs weg, damit Objekte nicht
## auf der Abbruchkante oder an einer Stufe stehen.
func weg_von_der_kante(s: float, abstand: float) -> float:
	if ist_luecke(s):
		return s
	var strang := strang_bei(s)
	if strang.y - strang.x <= abstand * 2.0:
		return (strang.x + strang.y) * 0.5
	return clampf(s, strang.x + abstand, strang.y - abstand)


## Der Rand an einer Stelle, ausgerechnet: {"typ", "abstand" (Querabstand des
## Profilanfangs), "wegrand" (halbe Wegbreite, in Lücken die der Kanten),
## "hoehe", "kante_y" (Welt-Y der Decke), "fuss_y", "krone_y" (NAN, wo es
## keinen gibt), "eintrag"}. Für die Nähte zwischen Saum und Gelände.
func rand_profil(s: float, seite: float) -> Dictionary:
	var wegrand := breite_bei(s) * 0.5
	if wegrand <= 0.0:
		wegrand = maxf(breite_bei(_kante_vor(s)), breite_bei(_kante_nach(s))) * 0.5
	var kante_y := boden_bei(s)
	for r: Dictionary in RAENDER:
		if int(r["seite"]) != int(signf(seite)):
			continue
		var von: float = r["von"]
		var bis: float = r["bis"]
		if s < von or s > bis:
			continue
		var t := inverse_lerp(von, bis, s) if bis > von else 0.0
		var abstand := wegrand
		if r.has("abstand"):
			var a0: float = r["abstand"]
			abstand = lerpf(a0, float(r.get("abstand_ende", a0)), t)
		var hoehe := 0.0
		if r.has("hoehe"):
			var h0: float = r["hoehe"]
			hoehe = lerpf(h0, float(r.get("hoehe_ende", h0)), t)
		var fuss_y := NAN
		if r.has("fuss_y"):
			var f0: float = r["fuss_y"]
			fuss_y = lerpf(f0, float(r.get("fuss_y_ende", f0)), t)
		var typ: String = r["typ"]
		var krone_y := NAN
		if typ == "FELS_AUF" or typ == "BOESCHUNG":
			krone_y = kante_y + hoehe
		return {"typ": typ, "abstand": abstand, "wegrand": wegrand, "hoehe": hoehe,
				"kante_y": kante_y, "fuss_y": fuss_y, "krone_y": krone_y, "eintrag": r}
	return {"typ": "FLACH", "abstand": wegrand, "wegrand": wegrand, "hoehe": 0.0,
			"kante_y": kante_y, "fuss_y": NAN, "krone_y": NAN, "eintrag": {}}


func _kante_vor(s: float) -> float:
	var beste := -INF
	for a: Dictionary in ABSCHNITTE:
		if float(a["bis"]) <= s:
			beste = maxf(beste, float(a["bis"]))
	return beste if beste > -INF else s


func _kante_nach(s: float) -> float:
	var beste := INF
	for a: Dictionary in ABSCHNITTE:
		if float(a["von"]) >= s:
			beste = minf(beste, float(a["von"]))
	return beste if beste < INF else s


## Die Fallbänder aus FAELLE als Weltpunkte.
func fall_punkte(name: String) -> PackedVector3Array:
	var punkte := PackedVector3Array()
	for p: Vector3 in FAELLE.get(name, []):
		var w := LevelWerkzeuge.punkt_frei(verlauf, p.x, p.y)
		punkte.append(Vector3(w.x, p.z, w.z))
	return punkte


## Ein Eintrag aus BEGEHBARES samt berechneter Lage:
##   "lage"          Welttransform des Körpers (Formen und Optik liegen darin)
##   "querschnitte"  nur streifen/sweep: Array[PackedVector3Array] in Welt-
##                   koordinaten, je Stelle der Umriss des Querschnitts
##   "stellen"       nur streifen/sweep: die Strecken dazu
## Leeres Wörterbuch, wenn es den Namen nicht gibt.
func begehbar(name: String) -> Dictionary:
	if _begehbar_berechnet.has(name):
		return _begehbar_berechnet[name]
	for roh: Dictionary in BEGEHBARES:
		if String(roh["name"]) != name:
			continue
		var e := roh.duplicate(true)
		match String(e["form"]):
			"kasten":
				e["lage"] = _kasten_lage(e)
			"zylinder":
				e["lage"] = _zylinder_lage(e)
			"kapsel":
				e["lage"] = _kapsel_lage(e)
			_:
				e["lage"] = Transform3D.IDENTITY
				var stellen := _stellen(float(e["von"]), float(e["bis"]))
				var schnitte: Array[PackedVector3Array] = []
				for s in stellen:
					schnitte.append(_querschnitt(e, s))
				e["stellen"] = stellen
				e["querschnitte"] = schnitte
		_begehbar_berechnet[name] = e
		return e
	return {}


## Welt-Y der Oberseite eines Begehbaren an (s, q) – für Kisten und
## Früchte darauf.
func oberkante(name: String, s: float, q: float) -> float:
	var e := begehbar(name)
	if e.is_empty():
		return boden_bei(s)
	match String(e["form"]):
		"kasten":
			var lage: Transform3D = e["lage"]
			var groesse: Vector3 = e["groesse"]
			# Die Oberseite ist eine Ebene: Höhe über der Stelle ablesen.
			var oben := lage * Vector3(0.0, groesse.y * 0.5, 0.0)
			var normale := lage.basis.y.normalized()
			var p := weg_punkt(s, q)
			if absf(normale.y) < 0.001:
				return oben.y
			return oben.y - ((p.x - oben.x) * normale.x + (p.z - oben.z) * normale.z) / normale.y
		"zylinder":
			var lage: Transform3D = e["lage"]
			return lage.origin.y + float(e["hoehe"]) * 0.5
		"kapsel":
			var lage: Transform3D = e["lage"]
			return lage.origin.y + float(e["radius"])
		"streifen":
			if e.has("oben_y"):
				return float(e["oben_y"])
			return boden_bei(s) + float(e.get("oben", 0.0))
		"sweep":
			var profil := _profil_bei(e, s)
			var oben := -INF
			for i in profil.size():
				var a := profil[i]
				var b := profil[(i + 1) % profil.size()]
				if (q - a.x) * (q - b.x) <= 0.0 and absf(b.x - a.x) > 0.0001:
					oben = maxf(oben, lerpf(a.y, b.y, (q - a.x) / (b.x - a.x)))
			if oben == -INF:
				return boden_bei(s)
			return boden_bei(s) + oben
	return boden_bei(s)


# =========================================================== Begehbares: Formen

func _kasten_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var groesse: Vector3 = e["groesse"]
	var oben: float = e.get("oben", 0.0)
	var a := weg_punkt(s - groesse.z * 0.5, q, oben)
	var b := weg_punkt(s + groesse.z * 0.5, q, oben)
	var vor := (b - a).normalized()
	var rechts := vor.cross(Vector3.UP).normalized()
	var hoch := rechts.cross(vor).normalized()
	var basis := Basis(rechts, hoch, -vor)
	return Transform3D(basis, (a + b) * 0.5 - hoch * groesse.y * 0.5)


func _zylinder_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var hoehe: float = e["hoehe"]
	var mitte := weg_punkt(s, q)
	var oben: float = e["oben_y"] if e.has("oben_y") else mitte.y + float(e.get("oben", 0.0))
	mitte.y = oben - hoehe * 0.5
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, s)), mitte)


func _kapsel_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var mitte := weg_punkt(s, q, float(e.get("oben", 0.0)) - float(e["radius"]))
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, s)), mitte)


## Kollisionsformen eines berechneten Eintrags, im Raum seines Körpers.
func _formen(e: Dictionary) -> Array[CollisionShape3D]:
	var formen: Array[CollisionShape3D] = []
	match String(e["form"]):
		"kasten":
			var form := CollisionShape3D.new()
			var kasten := BoxShape3D.new()
			kasten.size = e["groesse"]
			form.shape = kasten
			formen.append(form)
		"zylinder":
			var form := CollisionShape3D.new()
			var walze := CylinderShape3D.new()
			walze.radius = e["radius"]
			walze.height = e["hoehe"]
			form.shape = walze
			formen.append(form)
		"kapsel":
			var form := CollisionShape3D.new()
			var kapsel := CapsuleShape3D.new()
			kapsel.radius = e["radius"]
			kapsel.height = e["laenge"]
			form.shape = kapsel
			# Die Kapsel liegt quer über dem Weg: ihre Achse (lokal Y) auf X.
			form.rotation.z = PI * 0.5
			formen.append(form)
		_:
			var schnitte: Array[PackedVector3Array] = e["querschnitte"]
			for i in schnitte.size() - 1:
				formen.append(_prisma(schnitte[i], schnitte[i + 1]))
	return formen


func _prisma(a: PackedVector3Array, b: PackedVector3Array) -> CollisionShape3D:
	var form := CollisionShape3D.new()
	var huelle := ConvexPolygonShape3D.new()
	var punkte := a.duplicate()
	punkte.append_array(b)
	huelle.points = punkte
	form.shape = huelle
	return form


## Die Strecken, an denen ein Streifen oder Sweep geschnitten wird: höchstens
## einen Meter auseinander und genau an jeder Abschnittsgrenze, damit die
## Höhe an Stufen nicht verschmiert.
func _stellen(von: float, bis: float) -> PackedFloat32Array:
	var grenzen: Array[float] = [von, bis]
	for a: Dictionary in ABSCHNITTE:
		for g: float in [float(a["von"]), float(a["bis"])]:
			if g > von + 0.05 and g < bis - 0.05 and not grenzen.has(g):
				grenzen.append(g)
	grenzen.sort()
	var stellen := PackedFloat32Array()
	for i in grenzen.size() - 1:
		var teile := maxi(ceili(grenzen[i + 1] - grenzen[i]), 1)
		for k in teile:
			stellen.append(lerpf(grenzen[i], grenzen[i + 1], float(k) / float(teile)))
	stellen.append(bis)
	return stellen


func _profil_bei(e: Dictionary, s: float) -> Array[Vector2]:
	var profil: Array[Vector2] = []
	var anfang: Array = e["profil"]
	var ende: Array = e.get("profil_ende", anfang)
	var von: float = e["von"]
	var bis: float = e["bis"]
	var t := clampf(inverse_lerp(von, bis, s), 0.0, 1.0) if bis > von else 0.0
	for i in anfang.size():
		var a: Vector2 = anfang[i]
		var b: Vector2 = ende[i]
		profil.append(a.lerp(b, t))
	return profil


## Umriss eines Streifens oder Sweeps an der Stelle `s`, in Weltpunkten.
func _querschnitt(e: Dictionary, s: float) -> PackedVector3Array:
	var schnitt := PackedVector3Array()
	if String(e["form"]) == "sweep":
		var boden := boden_bei(s)
		for p in _profil_bei(e, s):
			var w := LevelWerkzeuge.punkt_frei(verlauf, s, p.x)
			schnitt.append(Vector3(w.x, boden + p.y, w.z))
		return schnitt
	# Streifen: innen (Polylinie oder Wegkante) bis außen, flach.
	var aussen := _polylinie_q(e["aussen"], s)
	var innen := 0.0
	if e.has("innen"):
		innen = _polylinie_q(e["innen"], s)
	else:
		var halb := breite_bei(s) * 0.5
		if halb <= 0.0:
			halb = maxf(breite_bei(s - 0.05), breite_bei(s + 0.05)) * 0.5
		innen = signf(aussen) * maxf(halb - 0.1, 0.0)
	var oben: float = e["oben_y"] if e.has("oben_y") else boden_bei(s) + float(e.get("oben", 0.0))
	var unten := oben - float(e.get("hoehe", 1.0))
	for p: Vector2 in [Vector2(innen, oben), Vector2(aussen, oben),
			Vector2(aussen, unten), Vector2(innen, unten)]:
		var w := LevelWerkzeuge.punkt_frei(verlauf, s, p.x)
		schnitt.append(Vector3(w.x, p.y, w.z))
	return schnitt


## q einer Polylinie [Vector2(s, q)] an der Stelle `s`; NAN außerhalb.
func _polylinie_q(punkte: Array, s: float) -> float:
	if punkte.is_empty():
		return NAN
	var erster: Vector2 = punkte[0]
	var letzter: Vector2 = punkte[punkte.size() - 1]
	if s < erster.x - 0.001 or s > letzter.x + 0.001:
		return NAN
	for i in punkte.size() - 1:
		var a: Vector2 = punkte[i]
		var b: Vector2 = punkte[i + 1]
		if s >= a.x and s <= b.x:
			if b.x - a.x < 0.0001:
				return b.y
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	return letzter.y if s >= letzter.x else erster.y


# =========================================================== Platzhalter

## Grauer Platzhalter genau in der Form der Kollision – solange kein Modul
## eine Optik liefert.
func _platzhalter(e: Dictionary) -> Node3D:
	var netz := MeshInstance3D.new()
	netz.name = "Platzhalter"
	match String(e["form"]):
		"kasten":
			var kasten := BoxMesh.new()
			kasten.size = e["groesse"]
			netz.mesh = kasten
		"zylinder":
			var walze := CylinderMesh.new()
			walze.top_radius = e["radius"]
			walze.bottom_radius = e["radius"]
			walze.height = e["hoehe"]
			netz.mesh = walze
		"kapsel":
			var kapsel := CapsuleMesh.new()
			kapsel.radius = e["radius"]
			kapsel.height = e["laenge"]
			netz.mesh = kapsel
			netz.rotation.z = PI * 0.5
		_:
			netz.mesh = _schnittnetz(e["querschnitte"])
	netz.material_override = Materialbibliothek.einfarbig(Color(0.52, 0.52, 0.5))
	return netz


## Netz aus einer Folge gleich langer Querschnitte: Mantel und zwei Deckel.
func _schnittnetz(schnitte: Array[PackedVector3Array]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in schnitte.size() - 1:
		var a := schnitte[i]
		var b := schnitte[i + 1]
		var mitte := _schwerpunkt(a)
		var laengs := (_schwerpunkt(b) - mitte).normalized()
		for k in a.size():
			var k2 := (k + 1) % a.size()
			var rand_mitte := (a[k] + a[k2]) * 0.5
			var n := rand_mitte - mitte
			n -= laengs * n.dot(laengs)
			_netz_dreieck(st, a[k], a[k2], b[k], n)
			_netz_dreieck(st, a[k2], b[k2], b[k], n)
	for ende in 2:
		var schnitt := schnitte[0] if ende == 0 else schnitte[schnitte.size() - 1]
		var nachbar := schnitte[1] if ende == 0 else schnitte[schnitte.size() - 2]
		var mitte := _schwerpunkt(schnitt)
		var n := mitte - _schwerpunkt(nachbar)
		for k in schnitt.size():
			_netz_dreieck(st, mitte, schnitt[k], schnitt[(k + 1) % schnitt.size()], n)
	return st.commit()


func _schwerpunkt(punkte: PackedVector3Array) -> Vector3:
	var summe := Vector3.ZERO
	for p in punkte:
		summe += p
	return summe / maxf(float(punkte.size()), 1.0)


## Dreieck mit Wicklung und Normale wie `LevelWerkzeuge._dreieck`.
func _netz_dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3) -> void:
	var n := normale.normalized()
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tausch := b
		b = c
		c = tausch
	for p: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(p)
