extends RefCounted
class_name L05Wald
## Level 05, Modul „Wald": der Hangwald in drei Stufen, die Baumtore, Gebüsch,
## Totholz an der Kuppe, Sträucher und Sandsteinfelsen (Entwurf §8.5, §9.1,
## §7.1 K1/K3/K4, Paket P7). Gepflanzt mit `Baumfabrik` nach den Regeln
## eines `Waldrahmen` (scripts/gemeinsam/), gesetzt mit `Waldsetzer`.
##
## WAS HIER WÄCHST (Seiten wie im Rückblick: q < 0 bildrechts, q > 0
## bildlinks):
## * NAH: Haine aus Modellbäumen der Rolle M1 (UNP `CommonTree_1`–`_5`; die
##   Nadelbäume der Rolle bleiben weg, Entwurf §8.5) mit Hainmitten bis
##   NAH_WEIT vom Weg, im Tobel (D) dazu Birkenhaine (M20) mit heller Rinde
##   (BIRKE_BORKE). Kronen mit Blattkarten bis SICHT_NAH (zur Mitte der
##   Hülle ihrer Zelle), danach dieselben Bäume in ihrer Fernfassung bis
##   `_sicht_fern`: Innerhalb von `far` (380, Level05.tscn) verschwindet kein
##   Baum, es wechselt nur die Fassung (Entwurf P7: „ein Fernform-Übergang"),
##   und das frühestens 60 m vor der Kamera, für alle Teile einer Zelle im
##   selben Bild (siehe SICHT_NAH).
## * HANG: von HANG_AB bis HANG_WEIT ferne Kronen (`Baumfabrik.fernbaum`,
##   prozedural – Modellkronen lasen sich aus 100 m als Platten, natur2/
##   LIESMICH) auf einem Raster, wo das Gelände Waldboden trägt, in Hainen
##   (Rauschen über der Dichte), sichtbar bis `_sicht_fern` (Entwurf:
##   ≥ 150 m).
## * FERNBAND: dahinter bis an den Rand des Geländes auf den Talhängen und
##   Kämmen, größer (FERN_GROSS) und lichter, jede Krone nach der Himmelsprobe
##   des Rahmens eingesunken (`Waldrahmen.einsinken`, Höhenraster über das
##   ganze Gelände: ein Waldsaum auf dem Kamm statt Scheiben vor dem Himmel)
##   oder weggelassen; sichtbar bis `_sicht_fern` (Entwurf: ≥ far, JT9 – im
##   Rückblick liegt die Ferne bergauf mitten im Bild).
## * TÖNUNG je Krone (Instanzton, Entwurf §8.5): 60 % oliv, 25 % ocker,
##   15 % kupfer (TOENE) – Spätsommer im Abendlicht; das Laub selbst (LAUB)
##   ist warm, damit Ocker und Kupfer als Faktoren ≤ 1 erreichbar sind (die
##   Scheitelfarbe eines Netzes hat 8 Bit je Kanal).
## * BAUMTORE (Entwurf §5 B) bei s 30 und 120: je Seite eine Buche
##   (`Baumfabrik.baum`, mittlere Fassung, runde Krone ab TOR_UNTEN der Höhe)
##   auf der Böschungskrone bei |q| = TOR_Q, leicht zum Weg geneigt. Die
##   Kronen rahmen den Weg seitlich und lassen über ihm den Himmel offen –
##   durch das Tor sieht man die Eiche (siehe ABWEICHUNGEN).
## * GEBÜSCH (Kronenwolke, 2–4 m) in Gruppen auf den Kronen über Hohlweg und
##   Terrassen, wo K3 keinen Baum zulässt, und am Rand der Haine; Sträucher
##   (M24, im Instanzton wie die Kronen) am Rand der Haine; TOTHOLZ an der
##   Kuppe (M17, `CommonTree_Dead_1/2`); FELSEN (M21, jedes zweite Modell,
##   FELS_MODELLE) sandsteinfarben getönt (FELS_TON) an den Füßen der Bäume
##   und an den Hängen des Tobels. Felsen und Sträucher stehen als MultiMesh
##   unter einer eigenen Wurzel „Waldboden" (`Bodensetzer`, siehe
##   BAUSPEICHER).
##
## REGELN (aus dem `Waldrahmen`, Entwurf §7.1):
##   K1  `weg_frei` (keine Krone über |q| < 6 unter 9,5 m über der Decke)
##       für jede Krone, jeden Busch und Strauch, `stamm_frei` (kein Stamm
##       über dem Weg) für jeden Stamm; die Tore mit TOR_FREI_Q. Gemessen in
##       `Level05.freiraumprobe`.
##   K3  Je Station s 6 … 296 (alle K3_SCHRITT m) ein Kegel ±K3_WINKEL von der
##       Kamera (Auge aus der echten Kamera, −21 / 5,6) zur Mitte jeder Krone
##       der Hauereiche (`Level05.wahrzeichen`), die letzten K3_ZIEL_FREI m
##       vor dem Ziel frei (dort steht nur das Totholz der Kuppe, weit unter
##       den Kronen). Keine Baumkrone und kein Stamm darin; Gebüsch und Tore
##       prüfen statt dessen die Sichtlinien (siehe ABWEICHUNGEN).
##   K4  Kein Stammfuß bei |q| < K4_Q (`sperren` des Rahmens über die ganze
##       Strecke); gezählt in `zahlen` ("staemme_q8"), gemeldet von der
##       Freiraumprobe. Die Tore zählen getrennt ("tore_q8").
##
## KOSTEN (Entwurf §10: Wald ≤ 70 Zeichenaufrufe, dazu ≤ 30 für Schatten;
## Handy ≤ 50). Je Zelle EIN Netz je Stoff (`Waldsetzer`, verschmolzen):
## nah Stämme, Birkenstämme, Kronen, Fernfassung (ZELLE_NAH), Gebüsch
## (ZELLE_BUSCH); Hang und Fernband grob gezellt (ZELLE_HANG, ZELLE_FERN);
## Tore und Totholz je eine Zelle für alle. Schatten werfen nur die Stämme der Tore und das
## Totholz – die Bäume des Hangwalds stehen 20 m und mehr vom Weg, ihre
## Schatten fallen hangauf hinter die Kamera, und jeder Stamm kostete im
## Schattenpass so viele Dreiecke wie im Bild. Sträucher und Felsen als
## MultiMesh (`Waldsetzer.fremd`), wenige Modelle, grob gezellt. Handy
## (`Effekte.reduziert`, Entwurf §9.5): Fernwald und Gebüsch zu
## HANDY_ANTEIL, Haine zu 80 %, gröbere Zellen, Felsen und Sträucher je ein
## Modell (MODELLE_HANDY).
## Gemessen (Messtore 8/60/140/190/218/250/280/296, Verfolger, gegen
## denselben Stand ohne Wald und Rasen, Prüfung der P7-Mängel): Wald
## Desktop +10 … +83 Zeichenaufrufe (s 280; vorher +11 … +67), Handy
## +9 … +48 (s 218); Dreiecke im Bild bis +402 k (s 218), das ganze Level
## höchstens 708 k (s 250, Grenze 750 k); Grafikspeicher +27,0 MB (Handy
## +21,8). Wechsel nah/fern (Kamera die Strecke entlang, nächster Scheitel
## im Bild beim Wechsel): Desktop frühestens 68,5 m, Handy 77,2 m (vorher
## 39 bzw. 32 m und dazu Lücken). Nahe Modellbäume 1016–2092 Dreiecke
## (Stamm und Krone), Torbuchen rund 1150 (Entwurf ≤ 3000).
##
## BAUSPEICHER (Entwurf §9.4): Der fertige Wald liegt nach dem ersten Laden
## im Bauspeicher (`schluessel`: Handyweg, Fremdmodelle, Kamera) – die
## Netze der drei Wurzeln über `L05Ablage`, der Waldboden als Liste seiner
## Stücke, dazu `zahlen`, `fuesse`, `tor_fuesse`. Danach zwei Schritte statt
## vierzehn: Fremdmodelle laden, einhängen; gelesen wird im Hintergrund
## (`Bauspeicher.vorladen`). Gemessen (Bauzeitprobe, Level 05 ganz,
## Rechner): Runde 2 245–284 ms (vor P7 233–243, mit P7 2,5 s), warm
## 2,7–2,8 s (vor P7 2,2, mit P7 4,9), Handy 0,26 / 2,9 s. Kalt bleibt der
## Bau (9,3–10,1 s, vor P7 7,4 s); der größte Schritt des Walds liegt dabei
## bei 0,31 s. Gleichheit von Bau und Ablage: eine Probe vergleicht Knoten,
## Lagen, Einstellungen, Stoffe und Netze (md5) beider Wege – ohne Grafik
## und mit (dort auch die Puffer der MultiMeshes): 0 Abweichungen.
##
## ABWEICHUNGEN VOM ENTWURF, jede von Code oder Messung erzwungen:
##   * TORE: Kronen seitlich ab gut 6 m über der Decke, die sich über dem
##     Weg nicht schließen, statt „Kronen ≥ 10 m" über ihm. Die Sichtlinien
##     zur Eiche kreuzen das Tor bei s 30 je nach Station 10 bis 26 m über
##     dem Weg und bis |q| 15 (gerechnet: nah unten, fern oben) – eine Krone,
##     die sich dort über dem Weg schließt, verdeckt die Eiche von einer
##     Strecke aus. Gemessen schon mit 13,5 m hohen Torbuchen, deren Kronen
##     11–18 m über der Decke nur bis |q| 4,9 reichten: Wahrzeichenprobe
##     81,5 % statt 91,8 %, die bildlinke Krone von s 204–232 zu (Tor bei
##     s 120). Deshalb wählt `_tor_baum` die größte Fassung, die keine
##     Sichtlinie zur Eiche schneidet (`_sichtlinien_anlegen`). K1 halten
##     sie (über |q| ≤ 3,5 nichts zwischen 4,6 und 9,2 m), K3 (±6°) nicht –
##     eine Krone neben dem Weg steht von jeder ferneren Station aus darin,
##     von s 296 aus ist der Kegel bei s 30 gut 30 m weit.
##   * TORE, Form: Die Kronen bleiben rund (zwei einzelne Kronen auf langen
##     Stämmen, kein Bogen); seitlich ausladende Kronen oder zwei Stämme je
##     Seite, ohne die Sichtlinien zu kreuzen, sind Bildfrage für P8. Der
##     Ton ist heller und wärmer (TOR_TON).
##   * K3 räumt den nahen Wald im oberen Teil weit: Gemessen (Karte der
##     Sperre, Baum 12–18 m) steht in A und B bis |q| 36–44 kein Baum, in C
##     bis 20–32. Von den fernen Stationen aus liegt die Sichtlinie zur Eiche
##     nur 15–20 m über dem Tal, und der Kegel ist dort 20–30 m weit. Das ist
##     der „Himmelsspalt über dem Hohlweg" (Entwurf §7.1); der nahe Wald
##     beginnt dort erst an den Hängen, die Kronen über dem Hohlweg trägt
##     Gebüsch (2–4 m, es reicht nicht an die Sichtlinie; die
##     Wahrzeichenprobe misst unverändert 91,8 %).

## Bis so weit vom Weg (waagerecht) stehen die Haine des nahen Walds; ab
## NAH_AB (Hainmitte). Dahinter (ab HANG_AB) der Hang, ab FERN_AB das
## Fernband.
const NAH_AB := 10.0
const NAH_WEIT := 60.0
const HANG_AB := 56.0
const HANG_WEIT := 135.0
const FERN_AB := 128.0
## Hainmitten: so weit mindestens auseinander, gesucht auf einem Raster.
const HAIN_RASTER := 18.0
const HAIN_SCHRITT := 7.0
## Raster der fernen Kronen (m), Hang und Fernband.
const HANG_RASTER := 13.0
## Kronen des Fernbands so viel größer (gröberes Raster, dieselbe Deckung).
const FERN_GROSS := 1.5
const FERN_RASTER := 19.0
## Sichtweiten (m). Godot misst sie von der Kamera zur Mitte der Hülle eines
## Knotens (renderer_scene_cull: transformed_aabb, mit custom_aabb; geprüft:
## eine Hülle 40 m hinter dem Ursprung blendet nach ihrer Mitte aus), und es
## schaltet mit Rand: aus erst über Sicht + Rand, wieder an erst unter
## Sicht − Rand. Ein Stück einer Zelle steht bis 0,71 · Zelle von deren
## Mitte.
## NAH (Kronen mit Karten, Stämme, Birken) und ihre FERNFASSUNG wechseln
## zusammen (`_zellen_angleichen`: eine Hülle je Zelle, derselbe Rand
## RAND_NAH): Ein Baum ist also nie in keiner und nie in beiden Fassungen
## zu sehen. Vorher hatte die Krone Rand 5, die Fernfassung 8 und jede ihre
## eigene Hülle – zwischen 80 und 83 m war die Zelle leer (gemessen: ein
## Hain bei s 203–207 vier Meter Fahrt lang weg, dann als Fernform zurück).
## Gewechselt wird frühestens SICHT_NAH − RAND_NAH − 0,71 · ZELLE_NAH vor
## der Kamera, das ist ≥ 60 m (Prüfung P7: Mit Zelle 64 und Sicht 75
## wechselten Bäume ab rund 30 m, sichtbar als Sprung von glatten Kugeln zu
## Bäumen mit Stamm und Karten; Level 01 wechselt ab 46 m). Gemessen
## (Kamera die Strecke entlang, nächster Scheitel im Bild beim Wechsel):
## siehe KOSTEN. Kleinere Zellen kosten Zeichenaufrufe (je Zelle und Art
## einer), weitere Sicht kostet Dreiecke. Rechner: Zelle 40, Sicht 93 – mit
## Zelle 64 und Sicht 110 kämen +100 k Dreiecke bei s 218 dazu (über
## 750 k). Handy: Zelle 64, Sicht 110 – mit Zelle 40 lägen +17 Zeichen-
## aufrufe darauf (Handy ≤ 50); dafür dort Hang und Gebüsch gröber gezellt
## (ZELLE_HANG_HANDY, ZELLE_BUSCH_HANDY).
## FERN (Fernfassung, Hang, Fernband): Bis `far` (380, Level05.tscn) endet
## keine Zelle, auch nicht beim Wiederkommen: Sicht ≥ far + 0,71 · Zelle +
## Rand (`_sicht_fern`).
## Was keine Fernfassung hat (Gebüsch, Felsen, Sträucher), bleibt bis
## KEIN_PLOPP sicher stehen (Entwurf P7: kein Aufploppen auf 120 m):
## KEIN_PLOPP + Rand (Waldsetzer.RAND, 5) + 0,71 · Zelle (`_sicht_boden`).
## Mit 130 bzw. 120 sprangen sie schon ab 91 bzw. 113 m ins Bild.
const SICHT_NAH := 93.0
const SICHT_NAH_HANDY := 110.0
const RAND_NAH := 4.0
const FERN_FAR := 380.0
const RAND_FERN := 10.0
const KEIN_PLOPP := 120.0
## Zellgrößen (m); mit `Effekte.reduziert` teils gröber.
const ZELLE_NAH := 40.0
const ZELLE_NAH_HANDY := 64.0
const ZELLE_BUSCH := 64.0
const ZELLE_BUSCH_HANDY := 96.0
const ZELLE_HANG := 96.0
const ZELLE_FERN := 128.0
const ZELLE_HANG_HANDY := 192.0
const ZELLE_FERN_HANDY := 192.0
const ZELLE_BODEN := 128.0
## Die Arten, die mit der Fernfassung wechseln (`_zellen_angleichen`).
const NAH_ARTEN: Array[String] = ["stamm", "birke", "krone", "fern"]
## Anteil des fernen Walds (Hang und Fernband) auf dem Handy (Entwurf §9.5).
const HANDY_ANTEIL := 0.6
## K3: Stationen, Kegelwinkel (halb, Grad) und freier Rest vor dem Ziel (m).
const K3_VON := 6.0
const K3_BIS := 296.0
const K3_SCHRITT := 4.0
const K3_WINKEL := 6.0
const K3_ZIEL_FREI := 14.0
## K4: kein Stammfuß näher an der Mitte (m), über diese Strecke.
const K4_Q := 8.0
const K4_STRECKE := Vector2(-40.0, 340.0)
## Wo es steiler ist (Anstieg je m), wächst kein Baum (Südwand im Tobel,
## Lösswände).
const STEIL := 0.9

## Laub (Grundton des Stoffs, warm) und die Instanztöne mit ihrem Anteil.
const LAUB := Color(0.34, 0.42, 0.15)
const TOENE := [
	{"name": "oliv", "ton": Color(0.62, 0.92, 0.95), "anteil": 0.6},
	{"name": "ocker", "ton": Color(0.92, 0.78, 0.55), "anteil": 0.25},
	{"name": "kupfer", "ton": Color(1.0, 0.62, 0.5), "anteil": 0.15},
]
## Ferne Kronen etwas dunkler (Unterdach, Luftperspektive kommt vom Nebel).
const FERN_DUNKEL := 0.88
## Haine: Höhe und Kronenansatz der Modellbäume, Birken.
const BAUM_HOEHE := 14.0
const BAUM_UNTEN := 0.34
const BIRKE_HOEHE := 13.0
const BIRKE_UNTEN := 0.45
## Birkenrinde: hell über die Tönung der Weltborke (der Modellbaum trägt die
## Rinde des Waldes, natur2/LIESMICH), wenig Moos.
const BIRKE_BORKE := {"welt": true, "radius": 0.4, "farbe": Color(2.3, 2.25, 2.1),
		"moos_oben": 0.1, "moos_nord": 0.25, "flechten": 0.2}
## Anteil der Birkenhaine im Tobel (s TOBEL), je Seite (bildlinks q > 0 der
## Sonnenhang mit Birken, Entwurf §5 D).
const TOBEL := Vector2(180.0, 265.0)
const BIRKEN_LINKS := 0.6
const BIRKEN_RECHTS := 0.3
## Baumtore: Strecke, Fußabstand quer (m); über |q| < TOR_FREI_Q keine Krone;
## die Fassungen, die probiert werden (Höhe, Neigung zum Weg an der Spitze,
## Kronenradius, je m).
const TORE: Array[float] = [30.0, 120.0]
const TOR_Q := 10.5
## Dort (Anteil der Höhe) beginnt die Krone der Torbuchen – Laub statt Lolli.
const TOR_UNTEN := 0.36
const TOR_FREI_Q := 4.0
const TOR_HOEHEN: Array[float] = [13.5, 12.5, 11.5, 10.5, 9.5]
const TOR_NEIGUNGEN: Array[float] = [1.6, 0.6]
const TOR_KRONEN: Array[float] = [4.2, 3.4]
## Sichtlinien der Tore: Abstand der Stellen (m, wie die Wahrzeichenprobe)
## und halber Öffnungswinkel um jede Linie (Grad).
const TOR_SICHT_SCHRITT := 2.0
const TOR_SICHT_WINKEL := 0.5
const TOR_BORKE := {"farbe": Color(0.86, 0.88, 0.9), "moos_oben": 0.45, "moos_nord": 0.7}
## Buchenlaub der Tore: zwischen Oliv und Ocker des Hangs, etwas heller.
## Dunkler und satter (0,7 / 0,86 / 0,8) standen sie als zwei dunkle runde
## Kronen auf langen Stämmen im Bild, ein Tor las man nicht (Prüfung P7);
## die Form der Kronen bleibt Bildfrage für P8 (siehe ABWEICHUNGEN).
const TOR_TON := Color(0.88, 0.9, 0.68)
## Totholz an der Kuppe (M17): Bereich (s von, s bis, |q| von, |q| bis),
## Anzahl, Abstand zur Achse der Eiche (m).
const TOT_BEREICH := Vector4(-34.0, 4.0, 13.0, 36.0)
const TOT_ANZAHL := 4
const TOT_EICHE_FREI := 14.0
## Felsen (M21) sandsteinfarben (Entwurf §8.5), so viele Modelle; Felsen im
## Tobel zusätzlich an den Hängen: so viele Versuche.
const FELS_TON := Color(1.0, 0.8, 0.62)
const FELS_MODELLE := 3
const FELS_TOBEL := 70
## Sträucher (M24): so viele Modelle; ihr Laub auf den warmen Grundton LAUB
## gehoben (das „Green" der Modelle ist 0,21/0,42/0,15, natur2): Erst
## darauf wirken die Instanztöne wie bei den Kronen – ohne stand ein sattes
## Grün im Spätsommer (gesehen bei s 60).
const STRAUCH_MODELLE := 2
const STRAUCH_LAUB := Color(1.62, 1.0, 1.0)
## Felsen und Sträucher auf dem Handy: je ein Modell. Mit den Sichtweiten
## für 120 m (`_sicht_boden`) standen bei s 218 vierzehn ihrer Knoten im Bild
## (drei Fels- und zwei Strauchmodelle je Zelle), der Wald lag dort bei +56
## Zeichenaufrufen (Entwurf §10: Handy ≤ 50).
const MODELLE_HANDY := 1
## Gebüsch: Raster (m), ab |q| (hinter der Wandkrone), Strecke, Anteil.
const BUSCH_RASTER := 4.5
const BUSCH_AB := 8.5
const BUSCH_STRECKE := Vector2(-4.0, 270.0)
const BUSCH_DICHTE := 0.32
## Dichte an der Wandkrone (Anteil) und Breite des Übergangs (m) dahinter.
const BUSCH_SAUM := Vector2(0.3, 7.0)
## Saaten (je Schritt ein eigener Zufall, Reihenfolge egal).
const SAAT := 5701

var level: Level05
var rahmen: Waldrahmen
## Gezählt (Bäume je Stufe, Ablehnungen, K4); bleibt nach dem Bau stehen.
var zahlen := {}
## Füße aller Stämme (Welt), für den Rasen und die Zählung K4.
var fuesse := PackedVector3Array()
var tor_fuesse := PackedVector3Array()

var _nah: Waldsetzer
var _hang: Waldsetzer
var _fern: Waldsetzer
var _boden: Bodensetzer
var _mitten: Array[Dictionary] = []
var _busch: ArrayMesh
var _tot: Array[ArrayMesh] = []
var _felsen: Array[Dictionary] = []
var _fels_arten: Array = []
var _straeucher: Array[Dictionary] = []
var _strauch_arten: Array = []
var _rauschen := FastNoiseLite.new()
var _fern_kandidaten: Array[Dictionary] = []
var _sichtlinien: Array[Dictionary] = []
## Die drei Wurzeln (nah, Hang, Fernband) für die Ablage.
var _wurzeln: Array[Node3D] = []


## Die Schritte: liegt der Wald im Bauspeicher (`schluessel`), zwei – die
## Fremdmodelle der Felsen und Sträucher laden (ihre Netze und Stoffe gehen
## nicht in die Ablage, siehe `L05Ablage`) und einhängen. Gelesen wird der
## Wald schon im Hintergrund, während die Schritte davor laufen
## (`Bauspeicher.vorladen`). Sonst der ganze Bau (`_bau_schritte`), der am
## Ende ablegt.
static func bauschritte(level_: Level05) -> Array:
	var w := L05Wald.new()
	w.level = level_
	level_.wald = w
	if Bauspeicher.vorladen(w.schluessel()):
		return [
			{"text": "Felsen und Sträucher", "tun": w._boden_laden},
			{"text": "Der Hangwald wird geladen", "tun": w._aus_speicher},
		]
	return w._bau_schritte()


## Schlüssel im Bauspeicher. Er nennt, was zur Laufzeit wechselt und den
## Wald ändert: Handyweg, Fremdmodelle an/aus, die Kamera (Sichtkegel,
## Himmelsprobe, Sichtweiten; `L05Ablage.kamera_schluessel`). Den Code
## deckt die Fassung des Speichers ab.
func schluessel() -> String:
	var kamera := level.get_node_or_null("CorridorCamera") as KorridorKamera
	return "l05_wald_%s_%s_%s" % ["handy" if Effekte.reduziert else "voll",
			"modelle" if Fremdmodelle.aktiv() else "ohne", L05Ablage.kamera_schluessel(kamera)]


## Der ganze Bau; der letzte Schritt legt ab (`_ablegen`).
func _bau_schritte() -> Array:
	return [
		{"text": "Bäume für den Hang", "tun": _modelle_laden},
		{"text": "Birken und Totholz", "tun": _beiwerk_laden},
		{"text": "Felsen und Sträucher", "tun": _boden_laden},
		{"text": "Der Hangwald wird vermessen", "tun": _vorbereiten},
		{"text": "Baumtore", "tun": _tore},
		{"text": "Wald über dem Hohlweg", "tun": _nahwald.bind(-60.0, 120.0, SAAT + 1)},
		{"text": "Wald über Terrassen und Tobel", "tun": _nahwald.bind(120.0, 340.0, SAAT + 2)},
		{"text": "Totholz, Sträucher und Felsen", "tun": _beiwerk},
		{"text": "Gebüsch am Hohlweg", "tun": _gebuesch},
		{"text": "Wald am Hang", "tun": _hangwald},
		{"text": "Der Himmel über den Kämmen", "tun": _himmel},
		{"text": "Wald auf den Kämmen", "tun": _fernband},
		{"text": "Der Hangwald wächst", "tun": _fertig_nah},
		{"text": "Der ferne Wald wächst", "tun": _fertig_fern},
	]


# ================================================================ Bau

## Die Laubbäume (M1, nur `CommonTree_*`). Die Modelle entstehen kalt im
## Bauspeicher und sind teuer: in drei Schritten (Laubbäume, Birken und
## Totholz, Felsen und Sträucher) – zusammen lagen sie kalt bei 0,6 s.
func _modelle_laden() -> void:
	for n in Fremdmodelle.rolle("M1"):
		if not n.contains("Pine"):
			Fremdmodelle.baum(n, {"hoehe": BAUM_HOEHE, "unten": BAUM_UNTEN,
					"fern_dreiecke": Baumfabrik.FERN_MODELL_DREIECKE})


## Birken (M20) und Totholz (M17).
func _beiwerk_laden() -> void:
	for n in Fremdmodelle.rolle("M20"):
		Fremdmodelle.baum(n, {"hoehe": BIRKE_HOEHE, "unten": BIRKE_UNTEN,
				"fern_dreiecke": Baumfabrik.FERN_MODELL_DREIECKE})
	var tot_namen := Fremdmodelle.rolle("M17")
	for k in tot_namen.size():
		var m := Fremdmodelle.baum(tot_namen[k], {"hoehe": 9.0 - 1.5 * float(k % 2), "moos": 0.3})
		if not m.is_empty():
			_tot.append(m["stamm"] as ArrayMesh)
	if _tot.is_empty():
		_tot.append(Riesenstamm.netz({"hoehe": 10.0, "radius": 0.42, "oben": "bruch", "aeste": 3,
				"ast_start": 0.45, "ast_laenge": 3.0, "moos": 0.35, "saat": SAAT + 11}))


## Felsen (M21) und Sträucher (M24) für den Waldboden.
func _boden_laden() -> void:
	# Felsen: sandsteinfarben, wenig Moos; nur einige Modelle (je Modell und
	# Zelle ein Zeichenaufruf), auf dem Handy je eines (MODELLE_HANDY).
	var reduziert := Effekte.reduziert
	_felsen = _rollenwahl("M21", {"toenung": FELS_TON, "moos": 0.08},
			MODELLE_HANDY if reduziert else FELS_MODELLE)
	_straeucher = _rollenwahl("M24", {"laub_toenung": STRAUCH_LAUB},
			MODELLE_HANDY if reduziert else STRAUCH_MODELLE)


## Jedes zweite Modell einer Rolle, höchstens `anzahl` (nur die gebaut, die
## gebraucht werden – `rolle_netze` baute alle sieben Felsen).
static func _rollenwahl(rolle: String, dazu: Dictionary, anzahl: int) -> Array[Dictionary]:
	var aus: Array[Dictionary] = []
	var namen := Fremdmodelle.rolle(rolle)
	var optionen := Fremdmodelle.rolle_optionen(rolle, dazu)
	for k in mini(namen.size(), anzahl):
		var m := Fremdmodelle.netz(namen[k * 2 % namen.size()], optionen)
		if not m.is_empty():
			aus.append(m)
	return aus


## Rahmen (Weg, Kamera, Kisten, K3, K4), Setzer und Arten, Hainmitten.
func _vorbereiten() -> void:
	var kamera := level.get_node_or_null("CorridorCamera") as KorridorKamera
	rahmen = Waldrahmen.new(level.weg, kamera, level.kisten_orte(),
			{"von": -40.0, "bis": Level05.KURVE_ENDE})
	for e: Dictionary in level.wahrzeichen():
		if String(e["name"]).begins_with("Krone"):
			rahmen.kegel_entlang(K3_VON, K3_BIS, K3_SCHRITT, e["mitte"] as Vector3, K3_WINKEL,
					K3_ZIEL_FREI)
	zahlen["kegel"] = rahmen.kegel.size()
	# K4: kein Stammfuß bei |q| < K4_Q (`platz` prüft `sperren` genau quer).
	rahmen.sperren.append(Vector4(K4_STRECKE.x, K4_STRECKE.y, -K4_Q, K4_Q))
	_rauschen.seed = SAAT
	_rauschen.frequency = 1.0 / 46.0
	_rauschen.fractal_octaves = 2

	var reduziert := Effekte.reduziert
	var sicht_nah := SICHT_NAH_HANDY if reduziert else SICHT_NAH
	var zelle_nah := ZELLE_NAH_HANDY if reduziert else ZELLE_NAH
	var modelle := not Fremdmodelle.rolle("M1").is_empty()
	var zelle_busch := ZELLE_BUSCH_HANDY if reduziert else ZELLE_BUSCH
	_nah = Waldsetzer.new(level.deko, "Hangwald", zelle_busch)
	_nah.art("stamm", {"stoff": Baumfabrik.borke_welt() if modelle else Riesenstamm.borkenstoff(),
			"sicht": sicht_nah, "rand": RAND_NAH, "zelle": zelle_nah, "verschmelzen": true})
	_nah.art("birke", {"stoff": Riesenstamm.borkenstoff(BIRKE_BORKE), "sicht": sicht_nah,
			"rand": RAND_NAH, "zelle": zelle_nah, "verschmelzen": true})
	_nah.art("krone", {"stoff": Kronenwolke.stoff(LAUB), "sicht": sicht_nah, "rand": RAND_NAH,
			"zelle": zelle_nah, "verschmelzen": true, "karten": true})
	_nah.art("fern", {"stoff": Kronenwolke.stoff(LAUB, false), "sicht_von": sicht_nah,
			"sicht": _sicht_fern(zelle_nah, RAND_NAH), "rand": RAND_NAH, "zelle": zelle_nah,
			"verschmelzen": true})
	# Tore und Totholz: je eine Zelle, ohne Sichtgrenze (sie stehen im
	# Rückblick lange im Bild und haben keine Fernfassung).
	_nah.art("tor_stamm", {"stoff": Riesenstamm.borkenstoff(TOR_BORKE), "verschmelzen": true,
			"zelle": 0.0})
	_nah.art("tor_stamm_schatten", {"stoff": Riesenstamm.borkenstoff(TOR_BORKE), "schatten": "nur",
			"verschmelzen": true, "zelle": 0.0})
	_nah.art("tor_krone", {"stoff": Kronenwolke.stoff(LAUB), "verschmelzen": true,
			"karten": true, "zelle": 0.0})
	_nah.art("tot", {"stoff": Baumfabrik.borke_welt() if modelle else Riesenstamm.borkenstoff(),
			"schatten": true, "verschmelzen": true, "zelle": 0.0})
	_busch = Baumfabrik.indiziert(Kronenwolke.netz({"radius": 1.9, "hoehe": 2.6, "variante": 1,
			"karten": 18, "ballen": 3, "saat": SAAT + 21}))
	_nah.art("busch", {"stoff": Kronenwolke.stoff(LAUB), "sicht": _sicht_boden(zelle_busch),
			"verschmelzen": true, "karten": true})

	var fern_stoff := Kronenwolke.stoff(LAUB, false)
	var zelle_hang := ZELLE_HANG_HANDY if reduziert else ZELLE_HANG
	_hang = Waldsetzer.new(level.deko, "Wald am Hang", zelle_hang)
	_hang.art("krone", {"stoff": fern_stoff, "sicht": _sicht_fern(zelle_hang, RAND_FERN), "verschmelzen": true,
			"rand": RAND_FERN})
	var zelle_fern := ZELLE_FERN_HANDY if reduziert else ZELLE_FERN
	_fern = Waldsetzer.new(level.deko, "Wald auf den Kämmen", zelle_fern)
	_fern.art("krone", {"stoff": fern_stoff, "sicht": _sicht_fern(zelle_fern, RAND_FERN), "verschmelzen": true,
			"rand": RAND_FERN})
	_boden_anlegen()
	_mitten_suchen()


## Hainmitten (Muster `L01Wald._talwald_nah`, Werkstatt Station 32): auf
## einem Raster von HAIN_SCHRITT m, NAH_AB … NAH_WEIT vom Weg, wo Waldboden
## liegt, mindestens HAIN_RASTER m auseinander.
func _mitten_suchen() -> void:
	var rng := PropWerkzeug.zufall(SAAT + 3)
	var feld := L05Gelaende.FELD
	var x := feld.position.x
	while x < feld.end.x:
		var z := feld.position.y
		while z < feld.end.y:
			var mitte := Vector2(x + rng.randf_range(0.0, HAIN_SCHRITT),
					z + rng.randf_range(0.0, HAIN_SCHRITT))
			z += HAIN_SCHRITT
			var d := rahmen.wegabstand(mitte.x, mitte.y)
			if d > NAH_WEIT or d < NAH_AB:
				continue
			var w := dichte(mitte.x, mitte.y)
			if w < 0.3:
				continue
			var frei := true
			for m: Dictionary in _mitten:
				if (m["p"] as Vector2).distance_squared_to(mitte) < HAIN_RASTER * HAIN_RASTER:
					frei = false
					break
			if frei:
				var sq := level.gelaende.projektion(mitte.x, mitte.y)
				_mitten.append({"p": mitte, "s": sq.x, "q": sq.y, "w": w})
		x += HAIN_SCHRITT
	zahlen["hainmitten"] = _mitten.size()


## Die Baumtore (siehe Kopf): je Seite eine Buche, leicht zum Weg geneigt,
## die Krone über der Böschung neben dem Weg. Probiert Fassungen (TOR_HOEHEN
## × TOR_NEIGUNGEN × TOR_KRONEN, die größte zuerst), bis K1 hält (über
## |q| < TOR_FREI_Q keine Krone), der Stamm frei vom Weg steht und keine
## Sichtlinie zur Eiche getroffen wird (`_sichtlinien_anlegen`); hält das
## keine, die Fassung mit den wenigsten getroffenen Stellen.
func _tore() -> void:
	_sichtlinien_anlegen()
	var saat := SAAT + 31
	for s in TORE:
		for seite: float in [-1.0, 1.0]:
			saat += 1
			_tor_baum(s, seite, saat)
	_sichtlinien.clear()


## Sichtlinien zur Eiche für die Tore: je Stelle der Wahrzeichenprobe
## (`Level05.wahrzeichen_strecke`, alle TOR_SICHT_SCHRITT m) ein schmaler
## Kegel (TOR_SICHT_WINKEL) vom Auge zu jedem Probepunkt der beiden Kronen.
## WARUM nicht K3: Von jeder ferneren Station steht eine Krone über oder
## neben dem Weg im ±6°-Kegel (siehe Kopf, ABWEICHUNGEN); was die Eiche
## wirklich verdeckt, sind die Linien zu ihrem Laub (gemessen: Mit 13,5 m
## hohen Torbuchen ohne diese Probe verdeckte das Tor bei s 120 die
## bildlinke Krone von s 204 bis 232, Wahrzeichenprobe 81,5 %). Die Probe
## prüft die Hülle der Krone, auf den Winkel geweitet – strenger als die
## Netze selbst: Die kleinste Fassung bei s 120 bildlinks schneidet so noch
## Linien, die Wahrzeichenprobe misst mit allen vier Toren 91,8 %.
func _sichtlinien_anlegen() -> void:
	_sichtlinien.clear()
	var strecke := level.wahrzeichen_strecke()
	var ziele: Array[Vector3] = []
	for e: Dictionary in level.wahrzeichen():
		if String(e["name"]).begins_with("Krone"):
			for p: Vector3 in e["punkte"]:
				ziele.append(p)
	var s := strecke.x
	while s <= strecke.y:
		var auge := rahmen.auge(s)
		for z in ziele:
			_sichtlinien.append({"auge": auge, "ziel": z, "winkel": deg_to_rad(TOR_SICHT_WINKEL),
					"s": s})
		s += TOR_SICHT_SCHRITT


## Stellen, an denen die Hülle eine Sichtlinie schneidet: Die Linie trifft
## die Hülle (auf den Winkel geweitet) und ihr Kegel die Kugel um sie. Erst
## der Schnitt mit der Hülle (C++), dann der Kegel (acos/asin in GDScript) –
## dieselbe Zählung, aber die meisten Linien fallen schon beim ersten Test
## heraus (kalt 189 ms für vier Tore mit je bis zu 20 Fassungen).
func _sicht_getroffen(huelle: AABB) -> int:
	var stellen := {}
	var mitte := huelle.get_center()
	var r := huelle.size.length() * 0.5
	for k: Dictionary in _sichtlinien:
		if stellen.has(k["s"]):
			continue
		var auge: Vector3 = k["auge"]
		var ziel: Vector3 = k["ziel"]
		var weit := auge.distance_to(mitte) * tan(float(k["winkel"]))
		if not huelle.grow(weit).intersects_segment(auge, ziel):
			continue
		if not Waldsetzer.kegel_frei_einzeln(mitte, r, k):
			stellen[k["s"]] = true
	return stellen.size()


func _tor_baum(s: float, seite: float, saat: int) -> void:
	var p := LevelWerkzeuge.punkt_frei(level.verlauf, s + seite * 0.6, seite * TOR_Q)
	var y := level.gelaende.sicht_oberkante(p.x, p.z)
	if is_nan(y):
		return
	var mitte := LevelWerkzeuge.punkt_frei(level.verlauf, s, 0.0)
	var richtung := Vector2(mitte.x - p.x, mitte.z - p.z).normalized()
	var lage := Transform3D(Basis.IDENTITY, Vector3(p.x, y - 0.1, p.z))
	var beste := {}
	var beste_zahl := 1 << 30
	for hoch in TOR_HOEHEN:
		for neigung in TOR_NEIGUNGEN:
			for krone in TOR_KRONEN:
				var o := {"mittel": true, "hoehe": hoch, "radius": 0.46, "krone_radius": krone,
						"variante": 0, "ballen": 3, "karten": 34, "unten": TOR_UNTEN,
						"neigung": richtung * neigung, "saat": saat}
				var b := Baumfabrik.baum(o)
				var huelle := lage * (b["huelle"] as AABB)
				if not rahmen.weg_frei(huelle, TOR_FREI_Q, Waldrahmen.FREI_H):
					rahmen.zaehle("tor_k1")
					continue
				var achse := PackedVector3Array()
				for k in 12:
					var t := float(k) / 11.0
					achse.append(lage * (Vector3(0.0, t * hoch * 0.95, 0.0)
							+ Baumfabrik.neigung_bei(b, t * 0.95)))
				if not rahmen.stamm_frei(lage.origin, achse[achse.size() - 1], 0.46, 0.0, 0.2, achse):
					rahmen.zaehle("tor_stamm")
					continue
				var zahl := _sicht_getroffen(huelle)
				if zahl < beste_zahl:
					beste_zahl = zahl
					beste = {"b": b, "huelle": huelle, "hoch": hoch, "neigung": neigung,
							"krone": krone}
				if zahl == 0:
					break
			if beste_zahl == 0:
				break
		if beste_zahl == 0:
			break
	if beste.is_empty():
		rahmen.zaehle("tor_ohne_platz")
		return
	var b: Dictionary = beste["b"]
	var huelle: AABB = beste["huelle"]
	if not rahmen.kegel_frei(huelle):
		rahmen.zaehle("tore_im_kegel")
	_nah.setze("tor_stamm", b["stamm"] as ArrayMesh, lage, Color(0.92, 0.92, 0.92))
	_nah.setze("tor_stamm_schatten", b["schatten"] as ArrayMesh, lage)
	_nah.setze("tor_krone", b["krone"] as ArrayMesh, lage,
			TOR_TON * Baumfabrik.ton(PropWerkzeug.zufall(saat), Vector2(0.9, 1.0), 0.03))
	rahmen.staemme.dazu(Vector2(p.x, p.z), 3.0)
	rahmen.kronen.dazu(Vector2(huelle.get_center().x, huelle.get_center().z),
			maxf(huelle.size.x, huelle.size.z) * 0.35)
	tor_fuesse.append(lage.origin)
	rahmen.zaehle("tore")
	rahmen.zaehle("tore_sicht_getroffen", beste_zahl)
	zahlen["tor_%.0f_%+.0f" % [s, seite]] = \
			"Höhe %.1f, Neigung %.1f, Krone r %.1f: %.1f–%.1f über der Decke, Sichtlinien an %d Stellen" % [
				float(beste["hoch"]), float(beste["neigung"]), float(beste["krone"]),
				huelle.position.y - level.boden_bei(s), huelle.end.y - level.boden_bei(s),
				beste_zahl]


## Der nahe Wald zwischen `von` und `bis` (Strecke der Hainmitte): je Mitte
## ein Hain (`Baumfabrik.hain`), im Tobel teils Birken; Sträucher am Rand.
func _nahwald(von: float, bis: float, saat: int) -> void:
	var rng := PropWerkzeug.zufall(saat)
	var arten_laub := _arten_laub()
	var arten_birke := _arten_birke()
	var reduziert := Effekte.reduziert
	for m: Dictionary in _mitten:
		var s: float = m["s"]
		if s < von or s >= bis:
			continue
		var p: Vector2 = m["p"]
		var q: float = m["q"]
		var w: float = m["w"]
		var dicht := smoothstep(0.3, 0.9, w)
		var birken := 0.0
		if s > TOBEL.x and s < TOBEL.y:
			birken = BIRKEN_LINKS if q > 0.0 else BIRKEN_RECHTS
		var birke := rng.randf() < birken
		var anzahl := roundi(lerpf(3.0, 7.0, dicht) * rng.randf_range(0.8, 1.15)
				* (0.8 if reduziert else 1.0))
		var weite := lerpf(4.5, 8.5, dicht)
		var vorher := fuesse.size()
		var neu := Baumfabrik.hain(_nah, rahmen, rng, p, arten_birke if birke else arten_laub, {
			"hoehe": boden, "nah": NAH_AB * 0.6, "weit": NAH_WEIT + 10.0,
			"anzahl": maxi(anzahl, 2), "weite": weite, "ton": Color.WHITE,
			"stamm": "birke" if birke else "stamm", "krone": "krone", "fern": "fern",
			"kante": false})
		for f in neu:
			var y := boden(f.x, f.y)
			fuesse.append(Vector3(f.x, y if not is_nan(y) else 0.0, f.y))
		rahmen.zaehle("birken" if birke else "laubbaeume", fuesse.size() - vorher)
		if not _straeucher.is_empty() and rng.randf() < 0.6:
			_strauch_am_hain(rng, p, weite)
		if not _felsen.is_empty():
			for f in neu:
				if Baumfabrik.streu(f, 37) < 0.3:
					Baumfabrik.bodenstueck(_boden, rahmen, f, _felsen, _fels_arten, boden, 6.0,
							NAH_WEIT + 10.0)


## Ein, zwei Sträucher (M24) am Rand eines Hains (wie Werkstatt Station 32).
func _strauch_am_hain(rng: RandomNumberGenerator, mitte: Vector2, weite: float) -> void:
	for i in rng.randi_range(1, 2):
		var w := rng.randf() * TAU
		var ort := mitte + Vector2(cos(w), sin(w)) * (weite + rng.randf_range(1.5, 3.5))
		if not rahmen.platz(ort, NAH_AB * 0.6, NAH_WEIT + 10.0, 2.0) \
				or not rahmen.staemme.frei(ort, 1.2):
			continue
		var y := boden(ort.x, ort.y)
		if is_nan(y):
			continue
		# Gewürfelt wie mit allen Modellen: Mit einem (Handy) zöge
		# `randi_range(0, 0)` keine Zahl, und der ganze Hain danach stünde
		# anders.
		var k := rng.randi_range(0, STRAUCH_MODELLE - 1) % _straeucher.size()
		var modell: Dictionary = _straeucher[k]
		var gross := rng.randf_range(0.8, 1.3)
		var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * gross),
				Vector3(ort.x, y - 0.05, ort.y))
		if not rahmen.weg_frei(lage * (modell["huelle"] as AABB)):
			continue
		var namen: Array[String] = []
		namen.assign(_strauch_arten[k])
		# Instanzton wie Bäume und Gebüsch (TOENE): Ungetönt stand das satte
		# Grün der Modelle im Bild (gesehen bei s 60). Der Ton kommt aus einem
		# eigenen Zufall nach dem Ort – der Zufall des Hains (Lage aller
		# folgenden Bäume) bleibt, wie er war.
		var ton := Baumfabrik.ton(rng, Vector2(0.78, 0.95), 0.06) \
				* _ton_waehlen(PropWerkzeug.zufall(int(Baumfabrik.streu(ort, 73) * 9999.0)))
		_boden.setze_fremd(namen, modell, lage, ton)
		rahmen.staemme.dazu(ort, 1.2)
		rahmen.zaehle("straeucher")


## Gebüsch (Kronenwolke, 2–4 m) am Rand der Haine und dort, wo K3 keinen
## Baum zulässt – auf den Kronen über dem Hohlweg und den Terrassen. Büsche
## reichen nicht an die Sichtlinie zur Eiche: Von fern liegt sie 15–20 m
## über dem Tal, ein Busch auf der Krone endet 6–8 m über der Decke (die
## Wahrzeichenprobe misst es). Sie stehen in einer eigenen Art mit
## `_sicht_boden` (Entwurf P7: kein Aufploppen auf 120 m).
func _gebuesch() -> void:
	var rng := PropWerkzeug.zufall(SAAT + 71)
	var anteil := HANDY_ANTEIL if Effekte.reduziert else 1.0
	var feld := L05Gelaende.FELD
	var x := feld.position.x
	while x < feld.end.x:
		var z := feld.position.y
		while z < feld.end.y:
			var p := Vector2(x + rng.randf_range(0.0, BUSCH_RASTER), z + rng.randf_range(0.0, BUSCH_RASTER))
			z += BUSCH_RASTER
			var wurf := rng.randf()
			var gross := rng.randf_range(0.75, 1.45)
			var dreh := rng.randf() * TAU
			var d := rahmen.wegabstand(p.x, p.y)
			if d > NAH_WEIT or d < BUSCH_AB - 3.0:
				continue
			var sq := level.gelaende.projektion(p.x, p.y)
			if absf(sq.y) < BUSCH_AB or sq.x < BUSCH_STRECKE.x or sq.x > BUSCH_STRECKE.y:
				continue
			# In Gruppen: ein feines Rauschen hebt die Dichte fleckweise. An der
			# Wandkrone setzt das Gebüsch dünn ein (BUSCH_SAUM): Mit voller
			# Dichte ab BUSCH_AB säumte es die Kronen als Strauchband wie eine
			# Parkhecke (Bild-Jury R1, Mangel 4).
			var w := BUSCH_DICHTE * clampf(0.2 + 1.6 * _rauschen.get_noise_2d(p.x * 2.3, p.y * 2.3)
					+ 0.5, 0.0, 2.0) * (1.0 - smoothstep(30.0, NAH_WEIT, absf(sq.y))) \
					* lerpf(BUSCH_SAUM.x, 1.0, smoothstep(BUSCH_AB, BUSCH_AB + BUSCH_SAUM.y,
						absf(sq.y)))
			if wurf > w * anteil:
				continue
			if not rahmen.platz(p, BUSCH_AB - 3.0, NAH_WEIT) or not rahmen.staemme.frei(p, 1.6):
				continue
			var y := boden(p.x, p.y)
			if is_nan(y):
				continue
			var lage := Baumfabrik.lage(Vector3(p.x, y + 0.35 * gross, p.y), dreh,
					gross * rng.randf_range(0.9, 1.2), gross)
			if not rahmen.weg_frei(lage * _busch.get_aabb()):
				continue
			_nah.setze("busch", _busch, lage, _ton_waehlen(rng) * Color(0.86, 0.9, 0.86))
			rahmen.staemme.dazu(p, 1.4)
			rahmen.zaehle("gebuesch")
		x += BUSCH_RASTER


## Totholz an der Kuppe (M17) und Sandsteinfelsen an den Hängen des Tobels.
func _beiwerk() -> void:
	var rng := PropWerkzeug.zufall(SAAT + 41)
	var eiche := LevelWerkzeuge.punkt_frei(level.verlauf, L05Eiche.STAMM_S, 0.0)
	var gesetzt := 0
	for versuch in 160:
		if gesetzt >= TOT_ANZAHL:
			break
		var s := rng.randf_range(TOT_BEREICH.x, TOT_BEREICH.y)
		var q := rng.randf_range(TOT_BEREICH.z, TOT_BEREICH.w) * (-1.0 if rng.randf() < 0.5 else 1.0)
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
		if Vector2(p.x - eiche.x, p.z - eiche.z).length() < TOT_EICHE_FREI:
			continue
		var y := boden(p.x, p.z)
		if is_nan(y):
			continue
		var huelle := AABB(Vector3(p.x - 4.0, y, p.z - 4.0), Vector3(8.0, 10.0, 8.0))
		if not rahmen.kegel_frei(huelle):
			continue
		var vorher := int(rahmen.zahlen.get("totholz", 0))
		Baumfabrik.totholz(_nah, rahmen, _tot, Vector3(p.x, y, p.z), rng, "tot")
		if int(rahmen.zahlen.get("totholz", 0)) > vorher:
			gesetzt += 1
			fuesse.append(Vector3(p.x, y, p.z))
	if _felsen.is_empty():
		return
	# Felsen im Tobel: an den Hängen über dem Bach, nie auf dem Weg. Am Fuß
	# der Südwand (Bachsohle) wächst nichts: `boden` liefert dort NAN (bei
	# |q| < 45 unter der Decke − 0,6 m), also auch keinen Fels.
	for versuch in FELS_TOBEL:
		var s := rng.randf_range(TOBEL.x + 4.0, TOBEL.y - 4.0)
		var q := rng.randf_range(9.0, 26.0) * (-1.0 if rng.randf() < 0.45 else 1.0)
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
		Baumfabrik.bodenstueck(_boden, rahmen, Vector2(p.x, p.z), _felsen, _fels_arten, boden, 6.0,
				NAH_WEIT + 10.0)


## Der Wald am Hang: ferne Kronen auf einem Raster, HANG_AB … HANG_WEIT vom
## Weg (Muster `L01Wald._talwald_fern_sammeln`).
func _hangwald() -> void:
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1)]
	var rng := PropWerkzeug.zufall(SAAT + 51)
	var anteil := HANDY_ANTEIL if Effekte.reduziert else 1.0
	_raster(HANG_RASTER, HANG_AB, HANG_WEIT, anteil, rng, func(e: Dictionary) -> void:
		var k: int = e["k"]
		_hang.setze("krone", netze[k], e["lage"] as Transform3D, e["ton"] as Color)
		fuesse.append(e["fuss"] as Vector3)
		rahmen.zaehle("hang"))


## Höhenraster der Himmelsprobe über das ganze Gelände (der Rahmen legt es
## sonst nur über den Wegabstand an, das Fernband steht weiter draußen) und
## die Kandidaten des Fernbands.
func _himmel() -> void:
	rahmen.himmel_vorbereiten(level.gelaende.hoehe, L05Gelaende.FELD.grow(-2.0))
	var rng := PropWerkzeug.zufall(SAAT + 61)
	var anteil := HANDY_ANTEIL if Effekte.reduziert else 1.0
	_raster(FERN_RASTER, FERN_AB, INF, anteil, rng, func(e: Dictionary) -> void:
		_fern_kandidaten.append(e))


## Das Fernband: jede Krone nach der Himmelsprobe eingesunken oder weg.
func _fernband() -> void:
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1)]
	for e: Dictionary in _fern_kandidaten:
		var k: int = e["k"]
		var lage: Transform3D = e["lage"]
		var ton: Color = e["ton"]
		var hoch := netze[k].get_aabb().end.y * lage.basis.y.length()
		var tief := rahmen.einsinken(e["fuss"] as Vector3, hoch, level.gelaende.hoehe)
		if tief < 0.0:
			rahmen.zaehle("fern_ballon")
			continue
		if tief > 0.0:
			lage.origin.y -= tief
			ton = ton * Color(0.92, 0.97, 1.04)
			rahmen.zaehle("fern_gesunken")
		_fern.setze("krone", netze[k], lage, ton)
		fuesse.append(e["fuss"] as Vector3)
		rahmen.zaehle("fern")
	_fern_kandidaten.clear()


## Ferne Kronen auf einem Raster (Hang und Fernband): `ab` … `bis` vom Weg
## (|q|), wo Waldboden liegt (Dichte mit Rauschen), nicht neben einem nahen
## Baum, frei von K1/K3. `setzen` bekommt {lage, k, ton, fuss}.
func _raster(raster: float, ab: float, bis: float, anteil: float, rng: RandomNumberGenerator,
		setzen: Callable) -> void:
	var netze: Array[ArrayMesh] = [_fernbaum(0), _fernbaum(1)]
	var feld := L05Gelaende.FELD.grow(-4.0)
	var x := feld.position.x
	while x < feld.end.x:
		var z := feld.position.y
		while z < feld.end.y:
			var px := x + rng.randf_range(-0.42, 0.42) * raster
			var pz := z + rng.randf_range(-0.42, 0.42) * raster
			z += raster
			var wurf := rng.randf()
			var wahl := rng.randf()
			var gross_wurf := rng.randf()
			var dreh := rng.randf() * TAU
			if wurf > anteil:
				continue
			var sq := level.gelaende.projektion(px, pz)
			var u := absf(sq.y)
			if u < ab or u >= bis:
				continue
			var w := dichte(px, pz) + _rauschen.get_noise_2d(px, pz) * 0.32
			if w < lerpf(0.16, 0.5, Baumfabrik.streu(Vector2(px, pz), 71)):
				continue
			if not rahmen.kronen.frei(Vector2(px, pz), 3.6):
				continue
			var y := boden(px, pz)
			if is_nan(y):
				continue
			# Schirmkronen selten (wie L01): flach lesen sie sich im Dunst als
			# Scheiben.
			var k := 1 if wahl < 0.18 else 0
			var groesse := lerpf(0.75, 1.35, gross_wurf) * (FERN_GROSS if u >= FERN_AB else 1.0)
			var lage := Baumfabrik.lage(Vector3(px, y, pz), dreh, groesse * 1.05, groesse)
			var huelle := lage * netze[k].get_aabb()
			if not rahmen.weg_frei(huelle) or not rahmen.kegel_frei(huelle):
				rahmen.zaehle("fern_nein_regel")
				continue
			var ton := _ton_waehlen(rng) * FERN_DUNKEL
			ton.a = 1.0
			setzen.call({"lage": lage, "k": k, "ton": ton, "fuss": Vector3(px, y, pz)})
			rahmen.kronen.dazu(Vector2(px, pz), 3.6 * groesse)
		x += raster


## Die Netze des nahen Walds; danach zählt der Rahmen die Stämme (K4).
func _fertig_nah() -> void:
	var zz := _nah.fertig()
	_zellen_angleichen(_nah.wurzel)
	_wurzeln.append(_nah.wurzel)
	var zb := _boden.fertig()
	rahmen.zaehle("boden_knoten", int(zb["knoten"]))
	rahmen.zaehle("boden_dreiecke", int(zb["dreiecke"]))
	rahmen.zaehle("nah_knoten", int(zz["knoten"]))
	rahmen.zaehle("nah_dreiecke", int(zz["dreiecke"]))
	_nah = null


## Die Netze von Hang und Fernband; danach ist der Bau fertig und der Rahmen
## wird losgelassen (seine Zahlen bleiben in `zahlen`).
func _fertig_fern() -> void:
	for ws: Waldsetzer in [_hang, _fern]:
		var zz := ws.fertig()
		rahmen.zaehle("fern_knoten", int(zz["knoten"]))
		rahmen.zaehle("fern_dreiecke", int(zz["dreiecke"]))
		_wurzeln.append(ws.wurzel)
	_hang = null
	_fern = null
	_zaehlen()
	zahlen.merge(rahmen.zahlen, true)
	if level.debug:
		print("L05Wald: ", zahlen)
	rahmen = null
	_ablegen()


## Legt den fertigen Wald in den Bauspeicher (siehe `L05Ablage`): die
## Knoten der drei Wurzeln, dazu, was Rasen und Freiraumprobe vom Wald
## lesen (`zahlen`, `fuesse`, `tor_fuesse`).
func _ablegen() -> void:
	var daten := L05Ablage.sichern(_wurzeln, _tafel())
	if daten.is_empty():
		return
	for st: Dictionary in _boden.stuecke:
		if int(st["modell"]) < 0:
			push_error("L05Wald: ein Stück Waldboden ohne bekanntes Modell, nicht abgelegt")
			return
	daten["boden"] = _boden.stuecke
	daten["zahlen"] = zahlen
	daten["fuesse"] = fuesse
	daten["tor_fuesse"] = tor_fuesse
	Bauspeicher.ablegen(schluessel(), daten)
	_boden = null


## Der Wald aus dem Bauspeicher. Lässt er sich nicht lesen oder kennt die
## Tafel einen Schlüssel nicht (die Fremdmodelle fehlen, obwohl der Schalter
## an ist), wird hier wie beim ersten Mal gebaut – in diesem einen Schritt.
func _aus_speicher() -> void:
	var gesichert: Variant = Bauspeicher.gespeichert(schluessel())
	var d: Dictionary = gesichert if gesichert is Dictionary else {}
	if not d.has("knoten") or not L05Ablage.einhaengen(level.deko, d, _tafel()):
		for schritt: Dictionary in _bau_schritte():
			(schritt["tun"] as Callable).call()
		return
	_boden_anlegen()
	for st: Dictionary in d.get("boden", []):
		var namen: Array[String] = []
		namen.assign(st["namen"])
		_boden.setze_fremd(namen, _boden.modelle[int(st["modell"])], st["lage"] as Transform3D,
				st["farbe"] as Color)
	_boden.fertig()
	_boden = null
	zahlen = d.get("zahlen", {}) as Dictionary
	fuesse = d.get("fuesse", PackedVector3Array()) as PackedVector3Array
	tor_fuesse = d.get("tor_fuesse", PackedVector3Array()) as PackedVector3Array
	if level.debug:
		print("L05Wald: ", zahlen)


## Stoffe und fremde Netze des Walds je Schlüssel (`L05Ablage`): beim
## Ablegen und Einhängen aus denselben Aufrufen, die beim Bau die Arten
## bekommen (alle geteilt und zwischengespeichert, also dieselben Objekte).
func _tafel() -> Dictionary:
	var modelle := not Fremdmodelle.rolle("M1").is_empty()
	var t := {
		"borke": Baumfabrik.borke_welt() if modelle else Riesenstamm.borkenstoff(),
		"borke_birke": Riesenstamm.borkenstoff(BIRKE_BORKE),
		"borke_tor": Riesenstamm.borkenstoff(TOR_BORKE),
		"laub": Kronenwolke.stoff(LAUB),
		"laub_fern": Kronenwolke.stoff(LAUB, false),
	}
	return t


## Der Setzer des Waldbodens (Felsen M21, Sträucher M24 als MultiMesh je
## Modellfläche, `Waldsetzer.fremd`) mit seinen Arten – beim Bau und beim
## Laden gleich. Eigene Wurzel „Waldboden" neben den Wurzeln des Walds: Die
## Ablage nimmt keine MultiMeshes (siehe `L05Ablage`), der Waldboden wird
## beim Laden aus seinen Stücken neu gesetzt.
func _boden_anlegen() -> void:
	_boden = Bodensetzer.new(level.deko, "Waldboden", ZELLE_BODEN)
	_boden.modelle.assign(_felsen + _straeucher)
	_fels_arten.clear()
	_strauch_arten.clear()
	var o := {"sicht": _sicht_boden(ZELLE_BODEN), "schatten": false, "zelle": ZELLE_BODEN}
	for k in _felsen.size():
		_fels_arten.append(_boden.fremd("fels%d" % k, _felsen[k], o))
	for k in _straeucher.size():
		_strauch_arten.append(_boden.fremd("strauch%d" % k, _straeucher[k], o))


## Waldsetzer, der jedes gesetzte Fremdmodell mitschreibt: Modell (Index in
## `modelle`), Arten, Lage, Ton. Daraus setzt `_aus_speicher` den Waldboden
## Stück für Stück neu – mit `Waldsetzer.fertig`, also wie beim Bau.
class Bodensetzer:
	extends Waldsetzer
	var modelle: Array[Dictionary] = []
	var stuecke: Array[Dictionary] = []

	func setze_fremd(namen: Array[String], modell: Dictionary, lage: Transform3D,
			farbe: Color = Color(1, 1, 1, 1)) -> void:
		var k := -1
		for i in modelle.size():
			if is_same(modelle[i], modell):
				k = i
				break
		stuecke.append({"namen": namen.duplicate(), "modell": k, "lage": lage, "farbe": farbe})
		super(namen, modell, lage, farbe)


## K4 (siehe Kopf): Stammfüße bei |q| < K4_Q, getrennt nach Toren und dem
## übrigen Wald.
func _zaehlen() -> void:
	var n := 0
	for f in fuesse:
		var sq := level.gelaende.projektion(f.x, f.z)
		if sq.x >= K4_STRECKE.x and sq.x <= K4_STRECKE.y and absf(sq.y) < K4_Q:
			n += 1
	var t := 0
	for f in tor_fuesse:
		var sq := level.gelaende.projektion(f.x, f.z)
		if absf(sq.y) < K4_Q:
			t += 1
	zahlen["staemme"] = fuesse.size()
	zahlen["staemme_q8"] = n
	zahlen["tore_q8"] = t


## Eine Hülle je Zelle für Nah- und Fernfassung (siehe SICHT_NAH): Die
## Knoten einer Zelle (NAH_ARTEN, Name "<art> <x>,<z>" aus `Waldsetzer.
## fertig`) bekommen als `custom_aabb` die Vereinigung ihrer Hüllen. Godot
## misst die Sichtweite zu deren Mitte – so wechseln Krone, Stamm, Birke und
## Fernfassung einer Zelle im selben Bild. Die Hülle ist kaum größer als die
## der Kronen allein (sie umfassen die Stämme), das Aussortieren am Bildrand
## bleibt fast gleich.
static func _zellen_angleichen(wurzel: Node3D) -> void:
	var gruppen := {}
	for c in wurzel.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var teile := String(mi.name).split(" ")
		if teile.size() != 2 or not NAH_ARTEN.has(teile[0]):
			continue
		var huelle := mi.transform * mi.mesh.get_aabb()
		if gruppen.has(teile[1]):
			var g: Dictionary = gruppen[teile[1]]
			g["huelle"] = (g["huelle"] as AABB).merge(huelle)
			(g["knoten"] as Array).append(mi)
		else:
			gruppen[teile[1]] = {"huelle": huelle, "knoten": [mi]}
	for z: String in gruppen:
		var g: Dictionary = gruppen[z]
		var h: AABB = g["huelle"]
		for mi: MeshInstance3D in g["knoten"]:
			mi.custom_aabb = AABB(h.position - mi.position, h.size)


## Sichtweite einer Art ohne Fernfassung (siehe KEIN_PLOPP).
static func _sicht_boden(zelle: float) -> float:
	return KEIN_PLOPP + Waldsetzer.RAND + 0.71 * zelle


## Sichtweite einer fernen Art: Bis `far` der Spielkamera endet keine Zelle
## der Größe `zelle`, auch nicht beim Wiederkommen (Rand `rand`).
func _sicht_fern(zelle: float, rand: float) -> float:
	var far := FERN_FAR
	if rahmen != null and rahmen.kamera != null:
		far = rahmen.kamera.far
	return far + 0.71 * zelle + rand


# ================================================================ Abfragen

## Walddichte 0..1 an (x, z): wie der Waldboden des Geländes
## (`L05Gelaende._faerben`) – am Weg ab gut 14 m, die fernen Hänge außer
## Kuppe, Kamm und Mühlwiese.
func dichte(x: float, z: float) -> float:
	var sq := level.gelaende.projektion(x, z)
	var s := sq.x
	var u := absf(sq.y)
	var wiese := maxf(1.0 - smoothstep(-20.0, 0.0, s), smoothstep(262.0, 280.0, s))
	var w := maxf(smoothstep(28.0, 40.0, s) * (1.0 - smoothstep(255.0, 270.0, s)),
			smoothstep(40.0, 80.0, u) * (1.0 - wiese))
	return w * smoothstep(14.0, 24.0, u)


## Boden für einen Baum an (x, z): die gezeichnete Höhe des Geländes, NAN wo
## nichts wachsen soll – steil (Südwand, Wände), im Wasser (Suhle, Teich,
## Unterwasser, Bach) oder außerhalb des Felds.
func boden(x: float, z: float) -> float:
	var g := level.gelaende
	var y := g.hoehe(x, z)
	if is_nan(y):
		return NAN
	var dx := g.hoehe(x + 1.0, z) - g.hoehe(x - 1.0, z)
	var dz := g.hoehe(x, z + 1.0) - g.hoehe(x, z - 1.0)
	if Vector2(dx, dz).length() * 0.5 > STEIL:
		return NAN
	var sq := g.projektion(x, z)
	if y < level.decke_glatt(sq.x) - 0.6 and absf(sq.y) < 45.0:
		return NAN
	if nass(sq.x, sq.y):
		return NAN
	return y


## Liegt (s, q) im Wasser oder an seinem Rand (Suhle, Teich, Unterwasser)?
func nass(s: float, q: float) -> bool:
	if s > L05Wasser.SUHLE_S.x - 2.0 and s < L05Wasser.SUHLE_S.y + 2.0 \
			and q > L05Wasser.SUHLE_Q.x - 2.0 and q < L05Wasser.SUHLE_Q.y + 1.0:
		return true
	if s > L05Wasser.TEICH_S.x - 3.0 and s < L05Wasser.TEICH_S.y + 3.0 \
			and q > L05Wasser.TEICH_Q.x - 1.0 and q < L05Wasser.TEICH_Q.y + 3.0:
		return true
	var lauf := L05Gelaende.UNTERWASSER
	for i in lauf.size() - 1:
		var a := lauf[i]
		var b := lauf[i + 1]
		var ab := b - a
		var t := clampf((Vector2(s, q) - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if Vector2(s, q).distance_to(a + ab * t) < L05Gelaende.UNTERWASSER_BREITE * 0.5 + 3.0:
			return true
	return false


# ================================================================ Helfer

## Arten der Laubhaine: Modellbäume der Rolle M1 (nur Laubbäume), je Ton.
func _arten_laub() -> Array:
	var arten := []
	for t: Dictionary in TOENE:
		arten.append({"rolle": "M1", "hoehe": BAUM_HOEHE, "unten": BAUM_UNTEN,
				"gewicht": float(t["anteil"]), "ton": t["ton"]})
	return arten


## Arten der Birkenhaine (M20): mehr Ocker – Birken gilben früh.
func _arten_birke() -> Array:
	var arten := []
	for t: Dictionary in TOENE:
		var anteil := float(t["anteil"])
		if String(t["name"]) == "ocker":
			anteil += 0.15
		elif String(t["name"]) == "oliv":
			anteil -= 0.15
		arten.append({"rolle": "M20", "hoehe": BIRKE_HOEHE, "unten": BIRKE_UNTEN,
				"gewicht": anteil, "ton": (t["ton"] as Color) * Color(1.04, 1.06, 0.9)})
	return arten


## Ein Ton nach den Anteilen von TOENE, leicht gestreut.
func _ton_waehlen(rng: RandomNumberGenerator) -> Color:
	var wurf := rng.randf()
	var gewaehlt: Color = TOENE[0]["ton"]
	for t: Dictionary in TOENE:
		wurf -= float(t["anteil"])
		if wurf < 0.0:
			gewaehlt = t["ton"]
			break
	return gewaehlt * Baumfabrik.ton(rng, Vector2(0.88, 1.0), 0.03)


## Ferne Krone k (0 rund, 1 breit) aus dem Vorrat des Rahmens.
func _fernbaum(k: int) -> ArrayMesh:
	return Baumfabrik.vorrat(rahmen, "fern%d" % k,
			func() -> ArrayMesh: return Baumfabrik.fernbaum(k)) as ArrayMesh
