extends RefCounted
class_name L05Eiche
## Level 05, Modul „Eiche": die Hauereiche auf der Kuppe hinter dem Start
## (Entwurf §8.2, §1 Nr. 19, Paket P4). Das Wahrzeichen des Levels liegt
## hinten, nicht vorn: Man läuft von ihm weg, im Rückblick steht die Eiche
## über dem ganzen Hang und wird immer kleiner.
##
## WAS HIER ENTSTEHT (im Rahmen der Eiche: +X = q > 0, im Rückblick
## BILDLINKS; −Z = hangab, zum Weg und zur Kamera):
## * FUSS: r 2,15, 5,5 m hoch, 7 Brettwurzeln; oben verjüngt er sich in die
##   beiden Hälften hinein. Vorn ein schmaler heller Riss: Der Spalt läuft
##   bis in den Fuß hinab.
## * Zwei STAMMHÄLFTEN, r 1,5 → 0,75, nach außen geneigt (`Riesenstamm.netz`
##   mit `neigung` und `krumm`): ein gespaltener Zwiesel. Ihre Spaltflächen
##   (Option `spalt`, hell und verwittert) schauen schräg nach innen und zur
##   Kamera – eine helle Innenkante des V, so liest es sich als Spalt und
##   nicht als zwei Bäume. Oben spreizen je vier Äste flach in die Krone.
## * Zwei SCHIRMKRONEN (`Kronenwolke` Variante 1) an den Astspitzen,
##   gemessen an der Fernkrone: Mitten bei q −12,2 und +12,3, Y 54,9 und
##   55,1, 15,4 und 15,7 m breit, je 7,1 m hoch – flach und breit, EINE
##   Lage Ballen. Dazwischen die Himmelskerbe (KERBE, 9,0 m). Das Laub
##   herbstgolden mit Durchlicht (GOLDEN, LAUB).
## * FERNFORM ab WECHSEL (Handy WECHSEL_HANDY, Entwurf §9.5): dieselben
##   Stämme als `Riesenstamm.schlicht` (ohne Äste), die Kronen als
##   `Kronenwolke.fern`, über `visibility_range` (Abstand Kamera – Mitte
##   der Hülle). Siehe WECHSEL: ohne Überlappung, Fernkrone in Größe und Ton
##   an die Nahkrone angeglichen.
## * EIGENER NEBEL (`Nebelstoff.nebelarm`): Kronen zu 0,3, Hälften zu 0,4
##   (NEBEL_KRONE, NEBEL_STAMM; bis R1 beide 0,45, die Bild-Jury fand die
##   Eiche nicht golden) – eine dunkle Silhouette mit goldenen
##   Kronen vor dem Dunst. „Für die Kuppe 0,7" des Entwurfs trägt der Fuß
##   der Fernform (NEBEL_KUPPE): Was auf der Kuppe steht, geht mit ihr in
##   den Dunst über, statt als dunkler Klotz auf dem hellen Hang zu stehen.
##   Mit 0,7 auch für die Hälften lasen sie sich im Schlussbild als blasse
##   Stöcke (Bildvergleich P4). Nah entfällt der Unterschied (auf 40 m
##   deckt der Nebel 13 %, 0,45 oder 0,7 davon sind 6 oder 9 %). Das
##   Gelände selbst bleibt unberührt (eine Abschrift seines Stoffs nur für
##   das Stück mit der Kuppe hätte an den Stückgrenzen eine Nebelkante
##   gezogen). OFFEN (Prüfung P4): Hinter der Kuppe ist der Fuß aus der
##   Ferne kaum zu sehen, die 0,7 wirken also fast nirgends – ob „Kuppe"
##   so gemeint ist, entscheidet der Nutzer. Die Krähen über der Eiche
##   setzt die Stimmung (`L05Stimmung`).
##
## ABWEICHUNGEN VOM ENTWURF, jede von Code oder Messung erzwungen:
##   * STAMM_S −9,5 statt −6: Die Querwand Start (`Level05.LEITLINIEN`)
##     steht bei s −4, dahinter beginnt der Startboden. Bei s −6 läge der
##     Fuß samt Anlauf (r 1,9 · 1,35 = 2,57) schon 0,57 m auf dem
##     Startboden, die Brettwurzeln reichten bis 5,3 m von der Achse – bis
##     s −0,7: Die Figur liefe durch Wurzeln und stünde im Stamm. Bei −9,5
##     reicht kein Punkt des Stamms über s −5,1 (gemessen), mit dem
##     dickeren Fuß aus R1 (r 2,15) über s −4,8 – noch 0,8 m vor der
##     Querwand. Die Kuppe des
##     Geländes bleibt bei s −6 (`Level05.EICHE`); 3,5 m neben ihrem
##     Scheitel liegt sie 0,03 m tiefer, die Eiche steht auf Y 26,83 (dem
##     tiefsten Boden unter ihrem Anlauf, siehe `rahmen`).
##   * KERBE 9,0 statt 7 m: Die Abnahme verlangt im Schlussbild (s 296,
##     Kamera bei s 317) mindestens 16 Bildpunkte bei 720 Zeilen. Die Kerbe
##     liegt dort 327 m weit; 7 m sind dann 13,4 px (die Rechnung des
##     Entwurfs nahm 12 px je Grad und 300 m; bei 60° senkrecht sind es in
##     der Bildmitte 10,9 px je Grad). Mit der breiteren Kerbe liegen die
##     Kronenmitten bei q ≈ ±12,5 statt ±11.
##   * Hälften 24,5 statt „≈ 20" m: Die Kronen sitzen an den Astspitzen
##     oben an den Hälften; ihr Ansatz liegt auf Y 30,2, die Kronenmitten
##     sollen nach dem Entwurf bei Y ≈ 55 liegen (gemessen 54,5 und 54,9).
##
## NEBEL. `Nebelstoff` rechnet Tiefennebel wie die Szene (Level05.tscn,
## Entwurf §8.3: 16 → 240 m, seit R1 12 → 210 m, Kurve 1,4). Beim Bau stellt `nebel_einstellen`
## die eigenen Stoffe auf den Nebel der Szene; danach führt sie der
## Stimmungsregler nach der Strecke nach (`L05Stimmung`, Option
## "nebelstoffe" = `nebel_stoffe`). Die Brücke für den Exponentialnebel, der
## bis Paket P8 in der Szene stand, ist entfallen.
##
## KOSTEN (Entwurf §10: Desktop 10 (+3), Handy 6). Nah zwei Netze, Stamm
## (Fuß und Hälften verschmolzen) und Kronen (beide verschmolzen); fern
## drei Flächen, Fuß und Hälften getrennt (für NEBEL_KUPPE) und die
## Kronen. Schatten wirft nur der nahe Stamm; die Kronen keine
## (Kronenwolke, Kopf), die Fernform keine. Nah und fern stehen nie
## zugleich (WECHSEL). Gemessen als Differenz zu P3 (gleiche Fotostellen,
## gleicher Lauf; Messtore 8/60/140/218/280/296, dazu 30/46/56/66/76 und
## Handy 16/26/34): Desktop +3, bei s 8 (Stamm mit Schatten) +4; Handy +3
## überall. Mit dem Übergangsband waren es bei s 60–66 und Handy s 26 +6.

## Gruppe der Eiche – die Wahrzeichenprobe nimmt sie aus der Verdeckung
## und prüft an ihr, ob die Probepunkte in den Kronen liegen.
const GRUPPE := "wahrzeichen"
## Stammachse auf der Strecke (siehe Kopf, ABWEICHUNGEN).
const STAMM_S := -9.5
## Breite der Himmelskerbe zwischen den Kronen (m): Abstand der innersten
## Ecken der Fernkronen quer (die Nahkronen tragen dazu Blattkarten). Sie
## folgt aus HAELFTE_NEIGUNG (siehe dort) und steht hier nur als Maß,
## gebaut wird sie nicht aus ihr; die Wahrzeichenprobe misst sie im
## Schlussbild nach ("Kerbe bei s 296"). Siehe Kopf, ABWEICHUNGEN.
const KERBE := 9.0
## Kronen an den Ästen (wie `Riesenstamm.baum`): an jeder Astspitze und am
## Leittrieb ein Ballen, eine Füllkugel in der Mitte – Variante 1 (Schirm).
## Nah und fern dieselben Ballen (gleiche Saat, gleiche Zentren). KRONE_R
## ist der Ballenmaßstab: Mit r 7,0 wird jede Krone 15–17 m breit und gut
## 7 m hoch (gemessen an der Fernkrone) – „r 7,5" des Entwurfs als Hülle,
## nicht als Maß der einzelnen Ballen.
const KRONE_R := 7.0
## Mitte eines Astballens über seiner Astspitze (m): `Kronenwolke` hebt
## jeden Ballen um ein Viertel seines Radius (0,52–0,64 · KRONE_R, also
## 0,91–1,12 m). Die Probepunkte der Wahrzeichenprobe liegen dort – sicher
## im Laub (geprüft: Selbsttest der Probe an jeder Stelle).
const BALLEN_HOCH := 1.0
## Laub der Hauereiche: etwas wärmer als `Farben.LAUB` – im Abendlicht soll
## sie golden leuchten (Entwurf §8.1), nicht kühl grün.
const LAUB := Color(0.54, 0.42, 0.13)

## Fuß (siehe Kopf). Oben auf r 0,6 verjüngt: Dort steckt er ganz in den
## beiden Hälften (jede r 1,5, 0,95 m neben der Achse). Mit r 0,8 zwischen
## Hälften von r 1,1 stand sein offener Kopf als dunkler Klotz zwischen
## ihnen (Prüfung P4). Vorn ein schmaler heller Riss ab 40 % der Höhe: flach
## (6 % des Radius, an der Kamera rund 1 m breit) – mit 15 % las er sich als
## helle, kantige Planke. ALT UND KNORRIG (Bild-Jury R1, Mangel 3: „keine
## alte gespaltene Eiche"): Fuß r 2,15 statt 1,9 und 5,5 statt 5 m hoch,
## höhere Brettwurzeln, tiefere Rippen, dunkles Holz im Spalt, je zwei
## Gruppen Pilze und Efeu; die Hälften r 1,5 statt 1,1 (oben 0,75 statt
## 0,6), krummer (0,9 statt 0,5), mit Rippen, Pilzen und Efeu. Mit r 1,1 auf
## 24,5 m standen sie im Bild als zwei dünne Stangen.
## R2 (Bild-Jury R2, Mangel 2: „ohne Brettwurzeln und ohne Masse am
## Fuß"): r 2,5 statt 2,15, 6 statt 5,5 m hoch, höhere Bretter, tiefere
## Rippen – er trägt jetzt die dickeren Hälften (siehe HAELFTE). Weiteste
## Stelle samt Wurzeln gut 5 m von der Achse, also s −4,4: noch vor der
## Querwand bei −4.
const FUSS := {"hoehe": 6.0, "radius": 2.5, "radius_oben": 0.7, "brettwurzeln": 7,
		"wurzel_reichweite": 2.4, "wurzel_hoehe": 3.6, "wurzel_dicke": 0.6, "anlauf": 0.35,
		"krumm": 0.0, "oben": "offen", "pilze": 2, "efeu": 2, "spalt": Vector2(0.0, -1.0),
		"spalt_tiefe": 0.06, "spalt_von": 0.4, "rippen_tiefe": 0.17, "drehung": 0.7,
		"spalt_farbe": Color(0.25, 0.19, 0.13), "saat": 5501}
## Stammhälften: gemeinsame Optionen; je Seite dazu `neigung`, `spalt` und
## `saat` (`_haelfte`). Ansatz HAELFTE_ANSATZ (x seitlich, y Höhe) im Fuß.
## SCHIRM: Die vier Äste gehen erst ab 80 % der Höhe ab, flach (0,25 rad)
## und lang (5,5 m) – ihre Spitzen liegen so auf 2,6 m Höhe beieinander
## (Y 52,1–54,7), die Ballen bilden eine Lage. Mit Ästen ab 64 % und
## 0,5 rad lagen die Spitzen über 5,5 m verteilt, und jede Krone las sich
## als zwei, drei gestapelte Ballen – eine Pagode aus Tellern (Prüfung P4,
## wie Level 01 in Welle 6). 24,5 m: siehe Kopf, ABWEICHUNGEN.
## R2 (Bild-Jury R2, Mangel 2): „zwei glatte, gebogene Bretter", aus der
## Ferne „Striche": r 2,05 statt 1,5 (oben 1,25 statt 0,75), Rippen 0,2
## statt 0,13 tief und stärker gedreht (0,75), je zwei Gruppen Pilze und
## Efeu. Dazu die HAUPTAESTE (unten) und die Fernform dicker (FERN_DICKE).
## Die Spaltfläche schmaler (Tiefe 0,16 statt 0,3 des Radius: 1,05 statt
## 1,43 Radien breit) und dunkler (0,15/0,11/0,075 statt 0,25/0,19/0,13):
## Breit und hell lasen sich die beiden Innenseiten bei s 8 als glatte,
## längs gemaserte Bretter (eigene Prüfung).
const HAELFTE := {"hoehe": 24.5, "radius": 2.05, "radius_oben": 1.25, "krumm": 0.9,
		"anlauf": 0.0, "brettwurzeln": 0, "aeste": 4, "ast_start": 0.8, "ast_steil": 0.25,
		"ast_laenge": 5.5, "spalt_tiefe": 0.16, "spalt_bis": 0.85, "rippen_tiefe": 0.2,
		"drehung": 0.75, "pilze": 2, "efeu": 2, "spalt_farbe": Color(0.15, 0.11, 0.075)}
## Ansatz im Fuß: Die unterste Kante der Hälften (1 m unter dem Ansatz,
## `Riesenstamm.VERSENKT`) liegt bei 2,6 m, 1,27 m neben der Achse (bei r
## 1,1 waren es 0,75 m, bei 1,5 0,95 m: Die dickeren Hälften rücken
## auseinander, sonst stünden sie ineinander).
const HAELFTE_ANSATZ := Vector2(1.27, 3.6)
## Radius (unten, oben), nach dem die Kronen sitzen (`_haelfte_krone`): der
## der Hälften bis R2.
const KRONE_HAELFTE_R := Vector2(1.5, 0.75)
## Saat je Hälfte (0: q < 0, 1: q > 0): je Seite die erste ab 5502 bzw.
## 6502, deren Krone nicht vor oder hinter den Stamm zieht (Mittel der
## Astspitzen längs ≤ 0,8 m vom Leittrieb, gemessen −0,44 und 0,29) und
## deren Äste nicht weit in die Kerbe greifen – an den Metadaten
## "ast_spitzen" von `Riesenstamm.netz`. Mit den dicken Hälften (R1) neu
## gesucht: Die Äste setzen an der Borke an, der Radius verschiebt also
## jede Spitze, und die alten Saaten 5572/6560 lagen 0,92 m längs bzw.
## griffen 1,8 m weiter in die Kerbe. Gemessen gegen die geneigte Achse in
## der Höhe der Spitze: höchstens 3,19 und 3,43 m innerhalb (die alten
## Saaten mit r 1,1 im selben Maß 2,89 und 3,02; der Radius bringt in Höhe
## der Äste 0,3 m mehr). Fernkronen 15,4 × 17,1 und 15,7 × 20,1 m. Einmal
## vorab gesucht (Hilfsskript außerhalb des Projekts), nicht zur Laufzeit.
const HAELFTE_SAAT: Array[int] = [5550, 6574]
## Versatz der Spitze je Hälfte (x nach außen, z nach hinten): so gewählt,
## dass die innerste Ecke der Fernkrone (mit FERN_SKALA) genau KERBE/2
## neben der Mitte liegt (vorab mit dem Sekantenverfahren gesucht, Fehler
## < 0,005 m; für die dicken Hälften und ihre Saaten neu, R1).
const HAELFTE_NEIGUNG: Array[Vector2] = [Vector2(12.275, 0.6), Vector2(12.490, 0.6)]
## Spaltfläche der Hälften: schaut mehr nach innen (x) als zur Kamera (z) –
## eine helle Innenkante des V. Frontal zur Kamera deckte sie vier Fünftel
## der Hälfte, aus der Ferne las sich der Stamm dann als blasses Brett.
const HAELFTE_SPALT := Vector2(0.75, -0.66)

## WECHSEL nah → fern nach Abstand (Kamera – Mitte der Hülle), Entwurf
## §8.2 „ab 85–100 m", §9.5 „Handy ab 60 m nur als Fernform". OHNE
## ÜBERLAPPUNG: Nah endet und fern beginnt an derselben Schwelle, RAND ist
## die Schwelle gegen Flackern (Godot schaltet ohne Überblenden erst RAND
## jenseits um, beide Fassungen im selben Bild, siehe `_wechsel_setzen`).
## Mit einem Übergangsband (85–100 m) standen beide Kronen ineinander –
## ihre Ballen gleich, die Oberflächen aber verschieden verrauscht – und der
## Wechsel war doppelt zu sehen (Prüfung P4). Überblenden
## (`visibility_range_fade_mode`) zeichnet der Compatibility-Renderer nicht
## (gemessen: die Fassung steht im Band voll deckend). Keine von beiden
## stünde nur, wenn die Kamera zum ALLERERSTEN Mal mitten im Band ±RAND
## hinschaut; sie beginnt aber 38 m vor der Eiche (Wahrzeichenprobe, s 6),
## und jeder spätere Sprung (Rücksetzen auf einen Rastplatz) behält die
## Fassung, die zuletzt stand. Im Lauf vom Start weg wechselt die Eiche
## bei s 72, auf dem Handy bei s 32 (Bildfolgen im Schritt 0,5 m, P4-Mängel).
const WECHSEL := 100.0
const WECHSEL_HANDY := 60.0
const RAND := 4.0
## Die Fernkrone hat keine Blattkarten. Ohne Angleich war sie beim Wechsel
## um ein Siebtel kleiner (Fläche im Bild, die Karten fransen die Nahkrone
## aus) und dunkler. Gemessen bei s 56 und 70 (Desktop, Fotos mit nur nah
## gegen nur fern): mit FERN_SKALA (um die Mitte jeder Krone) 98 % der
## Fläche, mit LAUB_FERN mittlere Farbe auf ±1 Stufe gleich (91/67/13
## gegen 91/68/14). Was bleibt, ist der Glanz der Karten.
const FERN_SKALA := 1.07
const LAUB_FERN := Color(0.66, 0.51, 0.16)
## Eigener Nebel (siehe Kopf). R2: Kronen 0,12 statt 0,3, Hälften 0,25 statt
## 0,4 – im Schlussbild stand die Eiche blass rosa im Dunst statt golden
## (Bild-Jury R2, Mangel 2; Entwurf §8.1: „Dort leuchtet nur die Hauereiche
## golden").
const NEBEL_KRONE := 0.12
const NEBEL_STAMM := 0.25
const NEBEL_KUPPE := 0.7

## HAUPTÄSTE UND LAPPEN (Bild-Jury R2, Mangel 2). Bis R2 trugen die Hälften
## je eine flache Schirmkrone an vier Ästen, die erst bei 80 % der Höhe
## abgingen und ganz im Laub steckten: Von s 30 an standen zwei dünne Stiele
## mit flachen Pfannkuchenkronen ohne sichtbare Äste im Bild, aus der Ferne
## zwei Pilzhüte auf Strichen. Jetzt gehen von jeder Hälfte vier Hauptäste
## ab (Vector4: Anteil der Höhe, Richtung in rad – 0 nach außen, positiv
## nach vorn, hangab zur Kamera –, Länge, Steigung in rad), nie nach innen
## in die Kerbe, und an jedem hängt ein runder Lappen Laub (LAPPEN_R, Mitte
## LAPPEN_HOCH über der Astspitze). So wird jede Krone eine breite,
## unregelmäßige Haube aus mehreren Lappen; jeder Lappen ist unten dunkel
## (`Kronenwolke`: Farbe nach der Höhe in seiner Krone), und zwischen Stamm
## und Laub sieht man die Äste. Die Schirmkronen und ihre Probepunkte
## (`wahrzeichen`, Kerbe) bleiben, wie sie sind.
## Vier je Hälfte, ab 56 % der Höhe und flach (0,22–0,4 rad), weit hinaus
## (6,5–9 m): Breit ausladend ist eine Eiche. Mit drei kurzen, steilen Ästen
## ab 55 % hingen die Lappen in der Fernform als Stapel unter der
## Schirmkrone (ein Pilzbüschel), mit Ästen ab 44 % als Pagode aus
## Tellern (eigene Prüfung bei s 296); so dicht unter der Schirmkrone
## wachsen die Lappen mit ihr zu einer Haube zusammen.
const HAUPTAESTE: Array[Vector4] = [Vector4(0.56, 0.15, 9.0, 0.22),
		Vector4(0.6, 0.95, 8.0, 0.3), Vector4(0.66, -0.95, 8.0, 0.3),
		Vector4(0.72, 0.45, 6.5, 0.4)]
## Radius der Hauptäste am Ansatz und an der Spitze (m). Lappen mit
## LAPPEN_R 4,4: Mit 3,5 standen sie aus der Ferne (s 90, 140) als eigene
## Stockwerke unter der Schirmkrone – eine Pagode aus Pilzhüten; größer
## überlappen sie zu EINER Krone von gut 13 bis 29 m Höhe.
const AST_R := Vector2(0.6, 0.22)
const LAPPEN_R := 4.4
const LAPPEN_HOCH := 1.0
## Die Hälften der Fernform so viel dicker (Radius): Auf 300 m und mehr
## lasen sie sich als Striche (Bild-Jury R2: „mindestens 2× Strichbreite").
## Dazu sind die Hälften selbst dicker (HAELFTE); fern oben r 1,5 statt
## 0,86 wie bis R2. Beim Wechsel nah → fern bei 100 m springt der Rand um
## 0,41 m (Fuß) bis 0,25 m (oben), bei 60° Blickfeld in 720p 2,6 bzw.
## 1,6 Bildpunkte je Seite.
const FERN_DICKE := 1.2

## Borke der Eiche: Rinde der Bibliothek, etwas wenig Moos oben (Licht).
const BORKE := {"moos_oben": 0.35, "moos_nord": 0.6}
## Fern dunkel und warm, kaum Streifen und Flechten (R2): Mit Farbe 0,5/
## 0,43/0,36 und den Streifen der Vorgabe (0,55) standen die Hälften bei
## s 296 als weiß gestreifte Striche vor dem Dunst (eigene Prüfung).
const BORKE_FERN := {"fern": true, "moos_oben": 0.35, "farbe": Color(0.36, 0.27, 0.19),
		"streifen": 0.2, "flechten": 0.2}

var level: Level05
## Die Eiche im Level (Gruppe GRUPPE).
var wurzel: Node3D
## Abschriften mit eigenem Nebel (für den Stimmungsregler, `L05Stimmung`).
var nebel_stoffe: Array[ShaderMaterial] = []
## Kronen (Mitten und Größen der Hüllen der Fernkronen, die Mitten ihrer
## Astballen) und die innersten Ecken an der Kerbe, in Weltkoordinaten –
## für `wahrzeichen`.
var kronen_mitten: Array[Vector3] = []
var kronen_groessen: Array[Vector3] = []
var kronen_ballen: Array[PackedVector3Array] = []
var kerben_kanten: Array[Vector3] = []


static func bauschritte(level_: Level05) -> Array:
	var e := L05Eiche.new()
	e.level = level_
	level_.eiche = e
	return [{"text": "Die Hauereiche", "tun": e._bauen}]


# ================================================================ Bau

func _bauen() -> void:
	var wechsel := WECHSEL_HANDY if Effekte.reduziert else WECHSEL
	wurzel = Node3D.new()
	wurzel.name = "Hauereiche"
	wurzel.add_to_group(GRUPPE)
	wurzel.transform = rahmen()
	level.deko.add_child(wurzel)

	var stamm_nah := _knoten("StammNah", stamm_netz(false),
			_nebelarm(Riesenstamm.borkenstoff(BORKE), NEBEL_STAMM), true)
	# Fern zwei Flächen: der Fuß auf der Kuppe mit mehr Nebel (NEBEL_KUPPE),
	# die Hälften wie die Kronen.
	var borke_fern := Riesenstamm.borkenstoff(BORKE_FERN)
	var stamm_fern := _knoten("StammFern", stamm_netz(true),
			_nebelarm(borke_fern, NEBEL_KUPPE), false)
	stamm_fern.set_surface_override_material(1, _nebelarm(borke_fern, NEBEL_STAMM))

	var kronen_fern := kronen_netz(true)
	var kn := _knoten("KronenNah", kronen_netz(false),
			_golden(_nebelarm(Kronenwolke.stoff(LAUB), NEBEL_KRONE)), false)
	var kf := _knoten("KronenFern", kronen_fern,
			_golden(_nebelarm(Kronenwolke.stoff(LAUB_FERN, false), NEBEL_KRONE)), false)
	var nah: Array[MeshInstance3D] = [stamm_nah, kn]
	var fern: Array[MeshInstance3D] = [stamm_fern, kf]
	_wechsel_setzen(nah, fern, wechsel)
	# Die Hauptäste setzen auf der Achse an, die `achse_haelfte` nachrechnet;
	# an der Spitze muss sie den Leittrieb von `Riesenstamm` treffen.
	for i in 2:
		var o := _haelfte(i, false)
		var spitzen: PackedVector3Array = Riesenstamm.netz(o).get_meta("ast_spitzen")
		var abweichung := spitzen[spitzen.size() - 1].distance_to(
				achse_haelfte(o, float(o["hoehe"])))
		if abweichung > 0.01:
			push_warning("L05Eiche: Achse der Hälfte %d weicht %.3f m vom Leittrieb ab – die Hauptäste stehen neben dem Stamm"
					% [i, abweichung])

	# Probepunkte für `wahrzeichen` aus der Fernkrone (die steht im Bild,
	# solange die Kerbe zählt), in Weltkoordinaten.
	var r := wurzel.global_transform
	for m: Vector3 in kronen_fern.get_meta("mitten", PackedVector3Array()):
		kronen_mitten.append(r * m)
	for g: Vector3 in kronen_fern.get_meta("groessen", PackedVector3Array()):
		kronen_groessen.append(g)
	for k: Vector3 in kronen_fern.get_meta("kanten", PackedVector3Array()):
		kerben_kanten.append(r * k)
	var ballen: PackedVector3Array = kronen_fern.get_meta("ballen", PackedVector3Array())
	var je: int = ballen.size() / 2
	for i in 2:
		var welt := PackedVector3Array()
		for k in je:
			welt.append(r * ballen[i * je + k])
		kronen_ballen.append(welt)
	nebel_einstellen(_umgebung())


## Lage und Rahmen der Eiche: Ursprung auf dem Fuß der Stammachse, +X nach
## q > 0, −Z hangab (Richtung +s). Höhe: der tiefste Boden unter dem Fuß
## (Achse und Ring auf dem Anlauf), damit kein Stück des Fußes schwebt;
## ohne Gelände `Level05.EICHE["boden_y"]`.
func rahmen() -> Transform3D:
	var ort := LevelWerkzeuge.punkt_frei(level.verlauf, STAMM_S, 0.0)
	var quer := LevelWerkzeuge.punkt_frei(level.verlauf, STAMM_S, 1.0) - ort
	quer.y = 0.0
	quer = quer.normalized()
	var hangab := quer.cross(Vector3.UP).normalized() * -1.0
	var basis := Basis(quer, Vector3.UP, -hangab)
	ort.y = float(Level05.EICHE["boden_y"])
	if level.gelaende != null:
		var tief := level.gelaende.hoehe(ort.x, ort.z)
		var anlauf := float(FUSS["radius"]) * (1.0 + float(FUSS["anlauf"]))
		for k in 8:
			var w := TAU * float(k) / 8.0
			var p := ort + (quer * cos(w) + hangab * sin(w)) * anlauf
			tief = minf(tief, level.gelaende.hoehe(p.x, p.z))
		ort.y = tief
	return Transform3D(basis, ort)


## Stamm samt Fuß als EIN Netz (eine Fläche, ein Zeichenaufruf), aus dem
## Bauspeicher. `fern`: die schlichte Fassung, ohne Äste (in 100 m sind sie
## 3 Bildpunkte dünn und stecken in der Krone).
static func stamm_netz(fern: bool) -> ArrayMesh:
	return Bauspeicher.netz("l05_eiche_stamm", [FUSS, HAELFTE, HAELFTE_ANSATZ, HAELFTE_NEIGUNG,
			HAELFTE_SPALT, HAELFTE_SAAT, HAUPTAESTE, AST_R, FERN_DICKE, fern],
			func() -> ArrayMesh: return _stamm_bauen(fern))


static func _stamm_bauen(fern: bool) -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var fuss := FUSS.duplicate()
	if fern:
		fuss["schlicht"] = true
	st.append_from(Riesenstamm.netz(fuss), 0, Transform3D.IDENTITY)
	# Fern: der Fuß als eigene Fläche (0), die Hälften als zweite (1) – für
	# den eigenen Nebel des Fußes (siehe Kopf, EIGENER NEBEL).
	var netz: ArrayMesh = null
	if fern:
		netz = st.commit()
		st = Riesenstamm.bauer()
	# Die Hauptäste in einem eigenen Sammler: Erst `Riesenstamm.fertig`
	# rechnet ihre Tangenten (die Rinde trägt eine Normalentextur).
	var aeste := Riesenstamm.bauer()
	for i in 2:
		st.append_from(Riesenstamm.netz(_haelfte(i, fern)), 0, _ansatz(i))
		for k in HAUPTAESTE.size():
			var ast := hauptast(i, k)
			L05Wegbauten.holz(aeste, Transform3D.IDENTITY, ast["punkte"], ast["radien"],
					{"seiten": 6 if fern else 10, "buckel": 0.1, "moos": 0.45,
					"saat": HAELFTE_SAAT[i] + 300 + k, "anfang": "stumpf", "ende": "spitz"})
	st.append_from(Riesenstamm.fertig(aeste), 0, Transform3D.IDENTITY)
	return st.commit(netz)


## Hauptast `k` der Hälfte `i` im Rahmen der Eiche (siehe HAUPTAESTE):
## {"punkte", "radien", "spitze"}. Er beginnt auf der Achse der Hälfte, im
## Holz, und läuft nach außen und oben – mit einem leichten Bogen zur Seite.
static func hauptast(i: int, k: int) -> Dictionary:
	var o := _haelfte(i, false)
	var seite := -1.0 if i == 0 else 1.0
	var a: Vector4 = HAUPTAESTE[k]
	var start := _ansatz(i) * achse_haelfte(o, a.x * float(o["hoehe"]))
	var aussen := Vector3(seite * cos(a.y), 0.0, -sin(a.y)).normalized()
	var quer := aussen.cross(Vector3.UP) * (1.0 if k % 2 == 0 else -1.0)
	var punkte := PackedVector3Array()
	var radien := PackedFloat32Array()
	for n in 6:
		var f := float(n) / 5.0
		punkte.append(start + aussen * (cos(a.w) * a.z * f) + quer * 0.35 * sin(f * PI)
				+ Vector3.UP * (sin(a.w) * a.z * f + 0.12 * a.z * f * f))
		radien.append(lerpf(AST_R.x, AST_R.y, f))
	return {"punkte": punkte, "radien": radien, "spitze": punkte[5]}


## Achse der Hälfte (Optionen `o`) in der Höhe `y`, im Rahmen der Hälfte:
## dieselbe Rechnung wie `Riesenstamm._achse` (Neigung mit t^1,5, Schwung
## nach Phase und Richtung, die beiden ersten Würfe der Saat). Dass sie
## übereinstimmt, prüft `_bauen` an der Spitze (dem Leittrieb der Äste).
static func achse_haelfte(o: Dictionary, y: float) -> Vector3:
	var rng := PropWerkzeug.zufall(int(o["saat"]))
	var phase := rng.randf() * TAU
	var schwung := Vector2.from_angle(rng.randf() * TAU)
	var t := clampf(y / float(o["hoehe"]), 0.0, 1.3)
	var v: Vector2 = (o["neigung"] as Vector2) * pow(t, 1.5) \
			+ schwung * float(o["krumm"]) * sin(t * PI * 1.3 + phase) * t
	return Vector3(v.x, y, v.y)


## Optionen der Hälfte `i` (0: q < 0, 1: q > 0).
static func _haelfte(i: int, fern: bool) -> Dictionary:
	var seite := -1.0 if i == 0 else 1.0
	var o := HAELFTE.duplicate()
	o["neigung"] = Vector2(seite * HAELFTE_NEIGUNG[i].x, HAELFTE_NEIGUNG[i].y)
	o["spalt"] = Vector2(-seite * HAELFTE_SPALT.x, HAELFTE_SPALT.y)
	o["saat"] = HAELFTE_SAAT[i]
	if fern:
		o["schlicht"] = true
		o["aeste"] = 0
		o["radius"] = float(o["radius"]) * FERN_DICKE
		o["radius_oben"] = float(o["radius_oben"]) * FERN_DICKE
	return o


## Optionen der Hälfte `i`, nach denen die Kronen sitzen (`_kronen_bauen`):
## wie `_haelfte`, aber mit dem Radius KRONE_HAELFTE_R. WARUM: Die Äste von
## `Riesenstamm` setzen an der Borke an, der Radius verschiebt jede
## Astspitze (gemessen: mit r 2,05 statt 1,5 eine Spitze 2,1 m weiter in die
## Kerbe). Saaten und Neigungen (HAELFTE_SAAT, HAELFTE_NEIGUNG) sind auf die
## Spitzen bei r 1,5 gesucht; mit den Spitzen der dicken Hälften fiel die
## Kerbe bei s 296 auf 15,6 px (Ziel ≥ 16) und die Wahrzeichenprobe auf
## 70,5 %. Die Äste der dicken Hälften enden so 0,2–2,1 m neben den
## Kronenzentren, im Laub.
static func _haelfte_krone(i: int) -> Dictionary:
	var o := _haelfte(i, false)
	o["radius"] = KRONE_HAELFTE_R.x
	o["radius_oben"] = KRONE_HAELFTE_R.y
	return o


## Lage der Hälfte `i` im Rahmen der Eiche.
static func _ansatz(i: int) -> Transform3D:
	var seite := -1.0 if i == 0 else 1.0
	return Transform3D(Basis.IDENTITY, Vector3(seite * HAELFTE_ANSATZ.x, HAELFTE_ANSATZ.y, 0.0))


## Beide Kronen als EIN Netz, je an den Ästen der nahen Hälfte (auch die
## Fernkrone: dieselben Ballen, um FERN_SKALA vergrößert). Metadaten (im
## Rahmen der Eiche): "mitten" und "groessen" (Hüllen der Fernkronen),
## "kanten" (die innersten Ecken der Fernkronen an der Kerbe), "ballen"
## (je Krone gleich viele Punkte, erst die bildrechte: Astspitzen und
## Leittrieb um BALLEN_HOCH gehoben – die Mitten der Astballen);
## custom_aabb über beide samt Blattkarten.
static func kronen_netz(fern: bool) -> ArrayMesh:
	return Bauspeicher.netz("l05_eiche_kronen", [HAELFTE, KRONE_HAELFTE_R, HAELFTE_ANSATZ, HAELFTE_NEIGUNG,
			HAELFTE_SAAT, KRONE_R, FERN_SKALA, BALLEN_HOCH, HAUPTAESTE, AST_R, LAPPEN_R,
			LAPPEN_HOCH, fern], func() -> ArrayMesh: return _kronen_bauen(fern))


static func _kronen_bauen(fern: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box := AABB()
	var mitten := PackedVector3Array()
	var groessen := PackedVector3Array()
	var kanten := PackedVector3Array()
	var ballen := PackedVector3Array()
	for i in 2:
		var seite := -1.0 if i == 0 else 1.0
		var haelfte := Riesenstamm.netz(_haelfte_krone(i))
		var spitzen: PackedVector3Array = haelfte.get_meta("ast_spitzen")
		var o := {"zentren": spitzen, "nebenzentren": haelfte.get_meta("zweig_spitzen"),
				"radius": KRONE_R, "variante": 1, "saat": HAELFTE_SAAT[i] + 101}
		var lage := _ansatz(i)
		var fern_netz := Kronenwolke.fern(o)
		# Fernkrone um ihre Mitte vergrößert (siehe FERN_SKALA).
		var mitte := fern_netz.get_aabb().get_center()
		var gross := Transform3D(Basis.from_scale(Vector3.ONE * FERN_SKALA),
				mitte * (1.0 - FERN_SKALA))
		var netz := fern_netz if fern else Kronenwolke.netz(o)
		st.append_from(netz, 0, lage * gross if fern else lage)
		# Mit Blattkarten: Die Hülle der Krone steht in custom_aabb (die
		# Karten zieht erst der Shader auf).
		var huelle := netz.custom_aabb if netz.custom_aabb.has_volume() else netz.get_aabb()
		var b := lage * gross * huelle if fern else lage * huelle
		box = b if i == 0 else box.merge(b)
		var fern_huelle := gross * fern_netz.get_aabb()
		mitten.append(lage * fern_huelle.get_center())
		groessen.append(fern_huelle.size)
		kanten.append(lage * gross * _innerste_ecke(fern_netz, seite))
		for p in spitzen:
			ballen.append(lage * (p + Vector3.UP * BALLEN_HOCH))
		# Die Lappen an den Hauptästen (siehe HAUPTAESTE), im Rahmen der
		# Eiche; fern um ihre eigene Mitte vergrößert wie die Schirmkrone.
		for k in HAUPTAESTE.size():
			var mitte_l: Vector3 = (hauptast(i, k)["spitze"] as Vector3) + Vector3.UP * LAPPEN_HOCH
			var ol := {"mitte": mitte_l, "radius": LAPPEN_R, "variante": 0, "ballen": 5,
					"saat": HAELFTE_SAAT[i] + 201 + k}
			var lappen := Kronenwolke.fern(ol) if fern else Kronenwolke.netz(ol)
			var lage_l := Transform3D(Basis.from_scale(Vector3.ONE * FERN_SKALA),
					mitte_l * (1.0 - FERN_SKALA)) if fern else Transform3D.IDENTITY
			st.append_from(lappen, 0, lage_l)
			var huelle_l := lappen.custom_aabb if lappen.custom_aabb.has_volume() \
					else lappen.get_aabb()
			box = box.merge(lage_l * huelle_l)
	var ergebnis := st.commit()
	ergebnis.custom_aabb = box
	ergebnis.set_meta("mitten", mitten)
	ergebnis.set_meta("groessen", groessen)
	ergebnis.set_meta("kanten", kanten)
	ergebnis.set_meta("ballen", ballen)
	return ergebnis


## Die Ecke einer Krone, die am weitesten zur Kerbe reicht: bei der Krone
## auf `seite` (+1: q > 0) die mit dem kleinsten seite · x. Die Vergrößerung
## um die Mitte (FERN_SKALA) erhält diese Wahl.
static func _innerste_ecke(netz: ArrayMesh, seite: float) -> Vector3:
	var ecken: PackedVector3Array = netz.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var beste := Vector3.ZERO
	var wert := INF
	for p in ecken:
		if seite * p.x < wert:
			wert = seite * p.x
			beste = p
	return beste


func _knoten(name_: String, netz: ArrayMesh, stoff: Material, schatten: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	mi.mesh = netz
	for f in netz.get_surface_count():
		mi.set_surface_override_material(f, stoff)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wurzel.add_child(mi)
	return mi


## Nah bis `wechsel`, fern ab `wechsel` (siehe WECHSEL). Alle Knoten
## bekommen dieselbe Hülle (`custom_aabb`, die Vereinigung aller samt
## Blattkarten): Godot misst die Sichtweite von der Kamera zur Mitte der
## Hülle, mit gleicher Mitte schalten Stamm und Kronen im selben Bild –
## keine Lücke, kein Bild mit beiden Fassungen, EIN Wechsel statt zweier
## (mit je eigener Hülle wechselten die Kronen bei s 69,5, die Stämme erst
## bei s 73; Bildfolge P4-Mängel).
func _wechsel_setzen(nah: Array[MeshInstance3D], fern: Array[MeshInstance3D],
		wechsel: float) -> void:
	var huelle := AABB()
	var erste := true
	for mi: MeshInstance3D in nah + fern:
		var h := _netzhuelle(mi.mesh)
		huelle = h if erste else huelle.merge(h)
		erste = false
	for mi in nah:
		mi.custom_aabb = huelle
		mi.visibility_range_end = wechsel
		mi.visibility_range_end_margin = RAND
	for mi in fern:
		mi.custom_aabb = huelle
		mi.visibility_range_begin = wechsel
		mi.visibility_range_begin_margin = RAND


static func _netzhuelle(netz: Mesh) -> AABB:
	var a := netz.get_aabb()
	if netz is ArrayMesh and (netz as ArrayMesh).custom_aabb.has_volume():
		a = a.merge((netz as ArrayMesh).custom_aabb)
	return a


## GOLDEN (Bild-Jury R1, Mangel 3; Entwurf §8.1: „Dort leuchtet nur die
## Hauereiche golden"): Die Kronen tragen herbstgoldenes Laub (LAUB,
## LAUB_FERN) und mehr Durchlicht als der übrige Wald, oben wärmer – im
## Abendlicht glimmen sie von innen. Nur auf den eigenen Abschriften
## (`_nebelarm`), der geteilte Kronenstoff bleibt, wie er ist.
const DURCHLICHT := 0.62
const TON_OBEN := Vector3(1.9, 1.3, 0.85)


func _golden(stoff: Material) -> Material:
	if stoff is ShaderMaterial and stoff != Kronenwolke.stoff(LAUB) \
			and stoff != Kronenwolke.stoff(LAUB_FERN, false):
		(stoff as ShaderMaterial).set_shader_parameter("durchlicht", DURCHLICHT)
		(stoff as ShaderMaterial).set_shader_parameter("ton_oben", TON_OBEN)
	return stoff


# ================================================================ Nebel

## Abschrift mit eigenem Nebel zum `anteil`; gemerkt für `nebel_einstellen`.
func _nebelarm(stoff: Material, anteil: float) -> Material:
	var neu := Nebelstoff.nebelarm(stoff, null, anteil)
	if neu != stoff and neu is ShaderMaterial:
		nebel_stoffe.append(neu as ShaderMaterial)
	return neu


## Schreibt den Nebel von `umgebung` in die eigenen Stoffe (siehe Kopf,
## NEBEL).
func nebel_einstellen(umgebung: Environment) -> void:
	if umgebung == null:
		return
	for stoff in nebel_stoffe:
		Nebelstoff.nebel_setzen(stoff, umgebung)


func _umgebung() -> Environment:
	var welt := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	return welt.environment if welt != null else null


# ================================================================ Abfragen

## Probepunkte des Wahrzeichens (für `Level05.wahrzeichen`), in
## Weltkoordinaten. Je Krone {"name", "punkte", "mitte", "radius"}: die
## Mitten ihrer Astballen (an den vier Astspitzen und am Leittrieb, siehe
## BALLEN_HOCH) – Punkte IM Laub, über die ganze Breite der Krone verteilt;
## dazu Mitte und halbe Breite der Hülle (für die Freiraumprobe K3). Früher
## standen hier Punkte auf 0,6 der halben Hülle; bei Kronen aus Ballen an
## Astspitzen lag der äußere davon neben der Krone in der Luft (Prüfung P4).
## Dazu die Kerbe – ihre Mitte und je 1 m darüber und darunter – samt den
## beiden innersten Ecken ("kanten"). Leer vor dem Bau.
func wahrzeichen() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	if kronen_mitten.size() != 2 or kerben_kanten.size() != 2 or kronen_ballen.size() != 2:
		return liste
	for i in 2:
		liste.append({"name": "Krone bildrechts" if i == 0 else "Krone bildlinks",
				"punkte": kronen_ballen[i], "mitte": kronen_mitten[i],
				"radius": kronen_groessen[i].x * 0.5})
	var k := (kerben_kanten[0] + kerben_kanten[1]) * 0.5
	liste.append({"name": "Kerbe", "punkte": PackedVector3Array([k, k + Vector3.UP,
			k - Vector3.UP]), "kanten": PackedVector3Array(kerben_kanten)})
	return liste
