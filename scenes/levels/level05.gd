extends KorridorLevel
class_name Level05
## Level 05 – „Hauerjagd": den Hauerhang hinab, den Keiler im Nacken.
##
## Unterhalb der gespaltenen Hauereiche schläft der Keiler in seiner Suhle.
## Man schleicht an ihm vorbei; auf dem ersten Rastplatz wacht er auf und
## rennt einem den ganzen Hang hinunter nach – durch den Hohlweg, über die
## Wurzelterrassen, durch den Tobel bis über das gebrochene Wehr am
## Mühlbach. Die Kamera schaut die ganze Zeit zurück (abstand −21): Man
## läuft auf sie zu, hinter einem die Hauer. Unter Wurzelbögen und
## Gerinnen kommt man nur im Slide durch; ein Slide gibt Vorsprung, jeder
## Sprung kostet welchen.
##
##       0 –  31  A Suhle          Diebstahl ohne Druck, Wecken bei 31
##      31 – 120  B Hohlweg        H1, D1, L1, G2, H2, D2
##     120 – 180  C Wurzelterrassen 5 × 1,2 m, L2, L3
##     180 – 265  D Tobel          L4, Kette D3–D4–L5, Findlingsgasse, G3
##     265 – 300  E Mühlbach       Wehrkrone, L6 Wehrbruch (Doppelsprung)
##     300 – 332  Auslauf          nur Kulisse, die Kamera steht bei s + 21
##
## NEUBAU nach dem Entwurf für Raum 1; er steht mit den Messwerten aller
## Pakete in `doku/level05-neubau.md`, und die „Entwurf §…“ in diesem Code
## meinen seine Abschnitte. Gebaut sind der
## ROHBAU (Pakete P1a/P1b: Verlauf, Weg, Bauteile, Spielobjekte, Jagd und
## Proben, voll spielbar), der BODEN (P3: Wegdecke mit Lippen, Gelände,
## Saum), die EICHE (P4), die WEGBAUTEN samt Keiler-Optik (P5), das
## WASSER (P6: Suhle, Rinnsale, Tobelbach, Mühlteich, Weißwasser, Mühlrad),
## WALD und RASEN (P7) und die STIMMUNG (P8: Himmel, Sonne und Lichter,
## Tiefennebel und Bildrahmen in Level05.tscn; Zonen, Horizont, Bewegung
## in der Luft, Krähen und Mühle in `L05Stimmung`). Durchlässe, Hürde,
## Findlinge, Wurzeltreppe und Wehrbruch zeigt die Werkstatt einzeln
## (Stationen 34–38, P9). Nach der ersten Runde der Spiel- und der
## Bild-Jury (R1) kamen dazu: Sicht durch die Durchlässe (Freiraum K5,
## Nahblende), Höchstabstand je Abschnitt und Warten nach dem Respawn
## (`L05Jagd`), Keilerklänge, D4/L5 1,2 m weiter hinten, das verborgene
## Zielportal (ENTKOMMEN_S), die Richtzeit mit Zeitkisten (ZIELZEIT) und
## das Bild der Eiche, der Wände, Lücken, Findlinge und des Lichts – je im
## Kopf des Moduls begründet, gesammelt in `doku/level05-neubau.md`
## (Abschnitt 13, „R1“). Nach der zweiten Runde (R2): Kistengasse am
## Sonnensims hinter dessen Ende, LEBEN-Kiste auf dem Sims, Zeitkisten nur
## auf der Hauptlinie (KISTEN), Richtzeit ohne Kisten (ZIELZEIT), Nacken
## statt Klemme in der Jagd (`L05Jagd`, Kopf), breiter Zielauslöser
## (`_ziel_ausloeser_verbreitern`), Stolpersperre (`_durchlass_stolpern`),
## dunkle Stirnen der Lücken (`L05Saum`) und eine Walze aus Weißwasser im
## Wehrbruch (`L05Wasser`) – gesammelt dort in Abschnitt 13, „R2“.
##
## DATEN. Diese Datei hält alle Daten des Levels als Konstanten (Verlauf,
## Breiten, Lücken, Absätze, Terrassen, Durchlässe, Hürden, Findlinge,
## Begehbares, Leitlinien, Kisten, Früchte, Rastplätze, Geheimnisse) und
## rechnet daraus beim Laden die Wegdaten (`weg`, scripts/gemeinsam/
## wegdaten.gd) – VOR der Schrittliste, wie Level 01. Alle Abfragen
## (`boden_bei`, `breite_bei`, `weg_punkt`, `ist_luecke` …) gehen über `weg`.
##
## MODULE unter `scenes/levels/level05/`, je eine Klasse mit
## `bauschritte(level: Level05)`: `L05Gelaende` (Hang, Kuppe, Kamm,
## Mühlwiese; P3), `L05Saum` (Lösswände, Ufer, Wehrwände, Stirnen und
## Setzstufen; P3), `L05Wasser` (Suhle, Rinnsale am Wasserriss, Tobelbach,
## Mühlteich, Weißwasser im Wehrbruch, Mühlrad – nichts davon tödlich; P6),
## `L05Eiche` (die gespaltene Hauereiche hinter dem Start,
## nah und fern, mit eigenem Nebel; P4), `L05Wegbauten` (Durchlässe heil und
## gebrochen, Hürden, Findlinge, Bänke, Rampe, Treppen, Wehr, Rastpfähle –
## mit ihren Körpern; P5), `L05Wald` (Hangwald nah, am Hang und auf den
## Kämmen, Baumtore, Gebüsch, Totholz, Sträucher, Felsen; P7), `L05Rasen`
## (Rasensaum, Laubstreu, Kupferfarn; P7), `L05Stimmung` (Zonen nach der
## Strecke über den `Stimmungsregler`, Horizontring, Lichtschächte, Pollen,
## Staub, Laub, Bachnebel, Krähen über der Eiche, Mühle als Klangschleife;
## P8, Werte und Abweichungen vom Entwurf in ihrem Kopf) und `L05Jagd`
## (der Keiler: Schlaf, Wecken, Jagd, Hopser, Durchlass-Bruch und Heilen,
## Ufer; P1b; sein Körper und seine Effekte in scenes/enemies/keiler.gd, P5).
##
## BODEN (P3, Entwurf §5, §8, §9.2–9.4). Die Wegdecke trägt den Stoff aus
## `Wegdecke` (Waldweg in Löss, `wegdecke_thema`), an L1–L6 vier bis sechs
## Lippensteine und Leuchtpilze (`lippen_thema`); hinter M_ENDE läuft die
## Spur in einem Streifen ohne Kollision aus (`_auslauf_bauen`). Die Ränder
## stehen als Züge in ZUEGE: Saum und Gelände lesen daraus dieselbe Form
## (siehe dort und die Köpfe der Module). Den Startboden zeichnet das
## Gelände, die Seiten der Wehrkörper der Saum (OHNE_OPTIK). Beim Verlassen
## räumt das Level die Zwischenspeicher von `Wegdecke` und `GelaendeSaum`.
##
## STOFFE. Gelände und Saum bekommen ihren Stoff beim Zusammenstellen der
## Schritte LEER und füllen ihn in einem eigenen Schritt
## (`L05Gelaende.stoff_uebertragen`): der Saum in seinem ersten, das Gelände
## erst vor seinen Netzen; die Texturen der Bibliothek entstehen davor in
## eigenen Schritten (wie L01Saum). WARUM: `GelaendeBau.schritte` und
## `Kanten.linien_schritte` nehmen den Stoff beim Zusammenstellen an. Mit
## fertigen Stoffen dauerte „Bauschritte zusammenstellen" kalt 1252 ms
## (gemessen, ohne Kopf; P1b: 3,6 ms) – die Texturen von Erde, Waldboden,
## Fels, Sandstein, Wegmaske und Rasen in einem Bild, Entwurf §9.4: kein
## Schritt über 400 ms. Kalt rechnen diese Texturen seit den Mängeln von P8
## in Arbeitsfäden (`_enter_tree`, `Bauspeicher.vorrechnen`); vorher lag
## der Löss (`Materialbibliothek.waldweg`) allein bei 490–580 ms in seinem
## Schritt.
##
## PROBEN (Opt-in, je im Kopf des Werkzeugs beschrieben): `pruefprofil`,
## `freiraumprobe` und `wasser_zonenprobe` (LevelCheck), `sprungfaelle` (Sprungprobe), `jagdfaelle`
## und `jagd_zustand` (Jagdprobe), `wahrzeichen` und `wahrzeichen_strecke`
## (Wahrzeichenprobe), `duckstellen` und `lauflinie` (Spieltest-Bot),
## `pruefruhe`, `foto_stelle`.
##
## KOORDINATEN wie überall: `s` Strecke auf dem Verlauf (3D-Bogenlänge),
## `q` quer dazu (positiv = rechts in Laufrichtung, im Rückblick also
## BILDLINKS), Höhen über der Wegdecke, außer wo ein Name auf `_y` endet.
##
## VERLAUF (Entwurf §3). Der Grundriss kommt aus zwölf Stützpunkten (KURVE),
## die Höhe aus KURVENHOEHE, stückweise linear. `kurve_bauen` legt alle 3 m
## einen Punkt auf den Grundriss – so weit entlang, dass die 3D-Bogenlänge
## bis dorthin genau `s` ist – mit der Höhe KURVENHOEHE(s). WARUM: Die
## Höhen der Absätze, die Lippen der Lücken und die Kamera über den
## Durchlässen sind gegen KURVENHOEHE gerechnet. Die Kurve allein durch
## die zwölf Punkte (`kurve_aus_punkten`) lag gemessen bis 0,24 m neben
## KURVENHOEHE (bei s 18), fiel über 21 m steiler als 10 % (Kamera nur
## 3,41 m über der Figur bei s 248) und endete bei 330 statt 332. So
## gebaut (P1a): Länge 332,00 m, |Kurve − KURVENHOEHE| höchstens 0,036 m
## (am Knick bei s 31), Kamera mindestens 3,486 m über der Figur.
## ABGLEICH: Die Stützpunkte des Entwurfs lagen in der Fläche je 30 m
## auseinander; mit dem Gefälle war die 3D-Bogenlänge am Punkt „s300"
## dadurch 301,07 m. Die Punkte unten sind so verschoben (je Abschnitt in
## seiner Richtung gestaucht), dass jeder bei seinem s liegt: gemessen
## höchstens 0,008 m daneben (Grenze ±0,2).
##
## WEG (Entwurf §2.7, §3). Die Decke folgt der Kurve, außer auf den
## Absätzen (waagerecht auf der Kurvenhöhe ihrer Mitte, mit Rampen von 6 m
## auf die Kurve), den fünf Terrassen samt Treppentritten in C und dem
## Suhlgraben. Wo zwei Rampen sich überlappten (62–71 und 200–210), wird
## daraus EINE Rampe von Absatz zu Absatz – das Rechenmodell des Entwurfs
## (boden2.py) ließ dort eine Stufe von 0,21 m stehen. Die Abschnitte
## rechnet `_abschnitte_rechnen` aus diesen Tabellen, Stufen bekommen eine
## Stufenkollision, Lücken sind Lücken (Wegdaten). Die Lippen jeder Lücke
## liegen auf einem Absatz oder einer Terrasse.
##
## KOLLISION (Entwurf §7.2, Baukasten §0 Nr. 5, Variante b):
##   Ebene 1    Wegdecke mit Stufen, Schultern bis an die Leitlinien,
##              Startboden, Grabenrampe, Trittstein G3, Wehrkörper, Kisten
##   Ebene 16   Leitlinien, Körper der Durchlässe, Hürden und Findlinge,
##              Wurzelknie G1, Böschungsbank G2, Sonnensims G3
##   Areas      Stolperzonen (an der Stirn), Rastplätze, Meldungen,
##              Todeszonen
## Die Kamera prüft nur Ebene 8 (`sicht_maske`, Level05.tscn, Entwurf §1
## Nr. 8): Kein Durchlass, keine Kiste und keine Terrasse holt sie heran.
## Was dafür über dem Weg frei bleiben muss, prüft `freiraumprobe`.
##
## LEITLINIEN Höhe 5 über der Decke. `LevelWerkzeuge.leitlinie` misst die
## Höhe über der KURVE, die Decke liegt bis 0,64 m darüber (Absätze,
## Wehrkrone) – deshalb 5,7. An den Geheimnissen G1–G3 dazu 7 m: Von der
## Bank (+2,2) trägt ein Doppelsprung die Füße auf 5,4 m, von G1 (+2,8)
## auf 6,0 m – über 5 m Leitlinie und die Böschung dahinter hinweg aus dem
## Level. G2 und G3 haben eine Nische hinter der Bank (Entwurf §6.3).
##
## TODESZONEN (Entwurf §7.3, Baukasten §4 Nr. 7): Je Lücke eine Zone auf
## fester Höhe, 2 m unter der unteren Lippe, am Wehr auf Y 2,6. Dazu für
## die Sturzprobe „Boden − 8" überall (`Wegdaten.zonen_unter_boden`) statt
## der alten `absturzzonen`. Der Suhlgraben ist nicht tödlich, seitlich
## stürzt man nirgends ab (Leitlinien).
##
## START. Die Figur steht schon in Level05.tscn auf dem Start (0, 26,6, −6).
## Am alten Ort (0, 1, 4) lag sie mitten in der Todeszone „Boden − 8" unter
## dem Startboden, die beim Bau entsteht – sie starb beim Laden, bevor das
## Level stand (gemessen: Leben 5 → 4, im Foto blieb sie unsichtbar).
##
## ABWEICHUNGEN VOM ENTWURF, jede von Code oder Messung erzwungen:
##   * Verlauf aus dichten Punkten statt aus den zwölf (siehe VERLAUF).
##   * Überlappende Rampen als eine (siehe WEG).
##   * Leitlinien 5,7 bzw. 7 statt 5 m (siehe LEITLINIEN).
##   * G2 2,0 m breit (q 4,6–6,6) statt 1,4, die Kisten hintereinander außen
##     auf der Bank: In einer Reihe deckten sie die ganze Bank, und kein
##     Slide-Sprung kam hinauf (Sprungprobe: jede Stelle prallte an der
##     vordersten Kiste ab). Die Nische dahinter beginnt schon bei 78.
##   * G3 (Trittstein und Sims) 5 m später, Trittstein 257 statt 252: Er
##     lag 0,5 m hinter F2 auf derselben Querlage – kein Anlauf, die
##     Sprungprobe konnte die Figur dort nicht einmal absetzen. Ein Sprung
##     mit gehaltener Taste trägt auf den 1,4 m kurzen Stein nur aus
##     2,7–4,9 m vor seiner Stirn (gerechnet).
##   * Das Zielportal ohne Lichtsäule (`portale_auf`, Freiraumprobe K1:
##     Die Säule stand bis 14 m hoch in der Kamerabahn).
##   * Geweckt wird nach der Strecke der Figur, nicht über die Zone des
##     Rastplatzes (siehe L05Jagd, Kopf).
##   * Die Gegenprobe der Jagdprobe zögert 1,2 s statt 0,3 s vor L5: Die
##     Kette verzeiht in der Engine mehr als gerechnet (JAGD_ZOEGERN_LANG).
##   * Der Spieltest-Bot bekommt neben `duckstellen` die `lauflinie`: Ohne
##     sie lief er frontal auf die Findlinge und wurde dort gefangen
##     (werkzeuge/spieltest.gd, Kopf).
##   P3 (Boden):
##   * Der Suhlgraben steht im Stoff der Decke als Lücke (7 von 8): Seine
##     Sohle zeichnet der Saum als Schlamm der Suhle; die Kollision bleibt die
##     Decke (siehe `wegdecke_thema`).
##   * Der Rasen der Decke bleibt der der Wegmaske, nur die Erde ist in Löss
##     getönt: Saum und Gelände tragen denselben Rasen (Naht an der Kante).
##   * Freiraum K3 prüft, ob Gelände und Saum die Kronen der Eiche verdecken
##     (Strahlen zur Mitte und ins Laub, `_freiraum_k3`), nicht einen Kegel von
##     ±6°: Ganz unten im Tal liegt die Krone nur 8° über der Kamera, und
##     ihr eigener Fuß auf der Kuppe läge im Kegel. Den Kegel für Bäume
##     prüft der Waldrahmen (Paket P7).
##   * K1 tastet nur Dreiecke ab, die den freien Raum erreichen können
##     (K1_WEIT): Gelände und Saum hätten die Probe sonst um Minuten
##     verlängert, ohne ein anderes Ergebnis zu liefern.
##   P4 (Eiche, Einzelheiten im Kopf von `L05Eiche`):
##   * Die Stammachse steht bei s −9,5 statt −6 (Fuß und Brettwurzeln
##     reichten sonst über die Querwand auf den Startboden); die Kuppe des
##     Geländes bleibt bei EICHE["s"] = −6.
##   * Die Kerbe ist 9,0 statt 7 m breit: 7 m wären im Schlussbild 13,4
##     statt der verlangten 16 Bildpunkte.
##   * Die Kronen sitzen als Schirme oben an den Ästen der 24,5 m hohen
##     Hälften, ihre Mitten bei q ≈ ±12,5 und Y ≈ 55. K3 prüft die
##     gebauten Kronen (`wahrzeichen`), EICHE nur ohne gebaute Eiche. K1
##     lässt die Eiche aus (sie steht vor s 0, wo K1 nichts prüft).
##   P5 (Wegbauten und Keiler, Einzelheiten in den Köpfen von
##   `L05Wegbauten` und keiler.gd):
##   * Das Gerinne der Fluderjoche bleibt im Bruch heil; den Wasserschwall
##     zeigt der Keiler als Effekt, das Wasser darin legt `L05Wasser` (P6).
##   P6 (Wasser, Einzelheiten im Kopf von `L05Wasser`):
##   * Teich und Bruch als eigenes Raster im Netz des Bachs, das Weißwasser
##     als Schuss über der Zone des Wehrs (Spiegel ≥ 2,7, die Zone 2,6),
##     zusätzlich Wasser in den Spalten L4/L5 und in den Gerinnen D3/D4.
##   * LevelCheck prüft das Wasser über `wasser_zonenprobe` (Opt-in "wasser").
##   * Das Mühlrad steht bei q −8,5 statt −7, in der Richtung des
##     Unterwassers: Am Rand des Laufs hing seine untere Kante über
##     trockenem Grund (Prüfung P6).
##   * Der schlafende Keiler liegt 2 m hangauf von SCHLAF_S, umgedreht, die
##     Schnauze zur Eichelspur (keiler.gd, SCHLAFPLATZ): Stehend steckte er
##     durch das Gatter Ü.
##   P7 (Wald und Rasen, Einzelheiten in den Köpfen von `L05Wald` und
##   `L05Rasen`):
##   * Die Baumtore rahmen den Weg seitlich, ihre Kronen schließen sich nicht
##     über ihm: Jede Krone dort verdeckte die Eiche von einer Strecke aus
##     (gemessen: Wahrzeichenprobe 81,5 % statt 91,8 %).
##   * K3 (±6°) räumt den nahen Wald in A bis C bis |q| 20–44; auf den
##     Kronen über dem Hohlweg steht Gebüsch statt Bäumen.
##   * Die Freiraumprobe meldet K4 (Stammfüße bei |q| < 8, gezählt vom Wald).

const M_ENDE := 300.0
## Bis hier reicht die Kurve: Die Kamera steht 21 m weiter auf dem Verlauf
## als die Figur (abstand −21), am Ziel also bei 317.
const KURVE_ENDE := 332.0
const START_S := 6.0
const ZIEL_S := 296.0
## Ab hier „Entkommen!" – nur als Meldung, Ziel ist allein das Zielportal.
## 0,6 m hinter der Lippe des Wehrbruchs (L6 endet bei 289,0), die Zone
## beginnt auf der Decke (`_meldung`, "unten" 0): Bis Runde 1 lag sie ab
## 288,8 und reichte 1 m unter die Decke – eine Figur, die in den letzten
## Dezimetern der Lücke fiel, bekam „Entkommen!" und „Autsch!" im selben
## Bild, und beim echten Entkommen kam die Meldung nicht mehr (Spiel-Jury
## R1, Mangel 8). Ab hier steht auch das Zielportal (`_ziel_zeigen`).
const ENTKOMMEN_S := 289.6
## Hinweis vor dem Gatter Ü (Entwurf §5 A, JS6).
const HINWEIS_S := 11.0
const HINWEIS_SLIDE := "Slide: kurz antippen, nicht halten"

# =========================================================== Verlauf

## Stützpunkte des Grundrisses bei s = 0, 30, …, 330 (abgeglichen, siehe
## Kopf). y ist KURVENHOEHE an der Stelle; die Kurve nimmt die Höhe aber aus
## KURVENHOEHE selbst.
const KURVE := [
	Vector3(0.00, 26.00, 0.00), Vector3(0.00, 26.00, -30.00),
	Vector3(-0.80, 23.56, -59.88), Vector3(-4.18, 21.03, -89.57),
	Vector3(-8.97, 18.50, -119.08), Vector3(-13.05, 15.50, -148.64),
	Vector3(-14.64, 12.50, -178.43), Vector3(-13.95, 9.64, -208.28),
	Vector3(-11.65, 8.47, -238.15), Vector3(-8.47, 5.57, -267.84),
	Vector3(-6.08, 3.00, -297.63), Vector3(-4.58, 2.25, -327.59),
]
## Höhe der Kurve (Kameraschiene) über `s`, stückweise linear (Entwurf §3).
## Die Kurve fällt über 21 m höchstens 10 %: Die Kamera steht so mindestens
## 3,5 m über der Figur (§2.6).
const KURVENHOEHE := [
	Vector2(0.0, 26.0), Vector2(31.0, 26.0), Vector2(120.0, 18.5), Vector2(180.0, 12.5),
	Vector2(208.0, 9.7), Vector2(236.0, 8.86), Vector2(265.0, 6.0), Vector2(300.0, 3.0),
	Vector2(332.0, 2.2),
]
## Abstand der Punkte, aus denen die Kurve gebaut wird.
const KURVE_DICHTE := 3.0

# =========================================================== Weg

## Wegbreite über `s` (Entwurf §2.7), linear zwischen den Punkten:
## A 12, B (Hohlweg) 9,5, C 10, D 9, E (Wehrkrone) 7.
const BREITEN := [
	Vector2(0.0, 12.0), Vector2(29.0, 12.0), Vector2(34.0, 9.5), Vector2(118.0, 9.5),
	Vector2(120.0, 10.0), Vector2(180.0, 10.0), Vector2(184.0, 9.0), Vector2(263.0, 9.0),
	Vector2(267.0, 7.0), Vector2(M_ENDE, 7.0),
]

## Die tödlichen Lücken. "tod_y": Oberkante ihrer Todeszone (Welt-Y), 2 m
## unter der unteren Lippe, am Wehr 2,6 (unter dem Weißwasser, §7.3).
## "grund_y": der gezeichnete Grund (Saum, Gelände), tiefer als die Zone:
## Im Hohlweg und an den Terrassen ein dunkler Spalt 4–5 m unter der
## unteren Lippe, in D auf dem Bett des Tobelbachs (die Rinnen münden
## dort), im Wehrbruch unter dem Wasser. "erdig": Löss und Erde statt Fels.
const LUECKEN := [
	{"name": "L1 Wasserriss", "von": 75.0, "bis": 78.0, "tod_y": 20.2, "grund_y": 17.2,
			"erdig": true},
	{"name": "L2 Terrasse", "von": 136.3, "bis": 139.7, "tod_y": 14.1, "grund_y": 12.1,
			"erdig": true},
	{"name": "L3 Terrasse", "von": 160.3, "bis": 163.7, "tod_y": 11.7, "grund_y": 9.7,
			"erdig": true},
	{"name": "L4 Seitenrinne", "von": 194.0, "bis": 197.5, "tod_y": 9.0, "grund_y": 7.9,
			"erdig": true},
	{"name": "L5 Mühlrinne", "von": 229.7, "bis": 232.7, "tod_y": 7.25, "grund_y": 6.0,
			"erdig": true},
	{"name": "L6 Wehrbruch", "von": 284.0, "bis": 289.0, "tod_y": 2.6, "grund_y": 1.0,
			"erdig": false},
]

## Absätze: waagerecht auf der Kurvenhöhe ihrer Mitte (Welt-Y), Rampen von
## RAMPE Metern davor und dahinter auf die Kurve.
const ABSAETZE := [
	{"name": "Absatz D1", "von": 54.0, "bis": 62.0, "hoehe": 23.72},
	{"name": "Absatz L1", "von": 71.0, "bis": 81.0, "hoehe": 22.21},
	{"name": "Absatz D2", "von": 100.0, "bis": 108.0, "hoehe": 19.85},
	{"name": "Absatz L4", "von": 190.0, "bis": 200.0, "hoehe": 11.0},
	{"name": "Absatz Kette", "von": 210.0, "bis": 236.0, "hoehe": 9.25},
	{"name": "Wehrkrone", "von": 279.0, "bis": 294.0, "hoehe": 4.16},
]
const RAMPE := 6.0

## Die Wurzelterrassen in C (Welt-Y), samt den Treppentritten (je 0,6 m)
## der Wurzeltreppen S1–S3. Zwischen T1/T2 und T3/T4 liegen L2 und L3.
const TERRASSEN := [
	{"name": "T0", "von": 120.0, "bis": 126.0, "hoehe": 18.5},
	{"name": "S1 Tritt", "von": 126.0, "bis": 126.8, "hoehe": 17.9},
	{"name": "T1", "von": 126.8, "bis": 136.3, "hoehe": 17.3},
	{"name": "T2", "von": 139.7, "bis": 150.0, "hoehe": 16.1},
	{"name": "S2 Tritt", "von": 150.0, "bis": 150.8, "hoehe": 15.5},
	{"name": "T3", "von": 150.8, "bis": 160.3, "hoehe": 14.9},
	{"name": "T4", "von": 163.7, "bis": 174.0, "hoehe": 13.7},
	{"name": "S3 Tritt", "von": 174.0, "bis": 174.8, "hoehe": 13.1},
	{"name": "T5", "von": 174.8, "bis": 180.0, "hoehe": 12.5},
]

## Suhlgraben (von, bis, Welt-Y der Sohle): 0,8 m tief, nicht tödlich,
## Rampe rechts hinaus (BEGEHBARES "Grabenrampe").
const SUHLGRABEN := Vector3(23.5, 28.1, 25.2)

## Kronenlicht auf der Decke in A (Entwurf §8.3, Zone A „Kronenlicht"):
## Abschnitte, die vor x beginnen, tragen die Stärke y (`Wegdecke`, Shader
## `wegboden`: gefleckte Helligkeit, Pfad × 0,9–1,05). Bis an den Suhlgraben;
## der Übergang liegt 1,5 m innerhalb der Abschnittsenden (22 → 25).
const KRONENLICHT := Vector2(23.5, 0.6)

## Wegdecke (Entwurf §9.2): Schlüssel im Zwischenspeicher von `Wegdecke` (je
## Level, beim Verlassen geräumt), Löss-Ton der Erde in der Spur (der
## Waldweg der Bibliothek ist dunkelbraun; Löss ist gelblich-ocker und
## heller) und Zahl der Steine je Lippe (§8.4).
const WEG_SCHLUESSEL := "l05_"
const LOESS_WEG := Color(1.12, 1.0, 0.78)
const LIPPEN_STEINE := Vector2i(4, 6)
## Auslauf der Decke hinter M_ENDE (`_auslauf_bauen`): so lang (m), in
## Stücken von AUSLAUF_SCHRITT Metern.
const AUSLAUF_LAENGE := 10.0
const AUSLAUF_SCHRITT := 0.5
## Begehbares ohne eigene Optik (siehe `_begehbar_optik`).
const OHNE_OPTIK: Array[String] = ["Startboden", "Wehrkörper vorn", "Wehrkörper hinten"]

# =========================================================== Bauteile

## Duckdurchlässe: "s" die Stirn, "tiefe" in Laufrichtung (Entwurf §1 Nr. 2).
const DURCHLAESSE := [
	{"name": "Ü Wildgatter", "s": 17.0, "tiefe": 1.6},
	{"name": "D1 Wurzelbogen", "s": 58.0, "tiefe": 1.8},
	{"name": "D2 Wurzelbogen", "s": 104.0, "tiefe": 1.8},
	{"name": "D3 Fluderjoch", "s": 214.0, "tiefe": 1.6},
	{"name": "D4 Fluderjoch", "s": 223.2, "tiefe": 1.6},
]
## Hürden: "s" ihre Mitte (Körper 0,7 × 0,6, Zone 1,0 × 0,8; §1 Nr. 12).
const HUERDEN := [
	{"name": "H1", "s": 44.0},
	{"name": "H2", "s": 93.0},
]
## Findlingsgasse (§5 D, §1 Nr. 17): je 4,6 m breit, 1,6 tief, 1,4 hoch,
## versetzt – die Gasse dazwischen verlangt ≥ 1 m Querversatz.
const FINDLINGE := [
	{"name": "F1", "s": 244.0, "q": -2.2, "breite": 4.6},
	{"name": "F2", "s": 250.0, "q": 2.2, "breite": 4.6},
]

## Alles außerhalb der Wegdecke, worauf man steht (Schema Level 01,
## `Wegdaten.begehbar`). Die Geheimnisse (§6.3):
##   G1 Wurzelknie    hinter dem Start, +2,8, Doppelsprung
##   G2 Böschungsbank +2,2, Slide-Sprung oder Doppelsprung, Einzelsprung nicht
##   G3 Sonnensims    +2,6, über den Trittstein (+1,2) mit zwei Einzelsprüngen
## Der Startboden trägt die Figur zwischen Querwand und Kurvenanfang (die
## Decke beginnt bei s 0), die Grabenrampe führt aus dem Suhlgraben, die
## Wehrkörper liegen unter der Wehrkrone (Optik und Stirn des Bruchs).
const BEGEHBARES := [
	{"name": "Startboden", "form": "streifen", "von": -4.0, "bis": 0.2,
			"innen": [Vector2(-4.0, -6.6), Vector2(0.2, -6.6)],
			"aussen": [Vector2(-4.0, 6.6), Vector2(0.2, 6.6)],
			"oben": 0.0, "hoehe": 2.0, "ebene": 1},
	{"name": "G1 Wurzelknie", "form": "kasten", "s": 1.3, "q": 5.1,
			"groesse": Vector3(3.0, 3.8, 2.6), "oben": 2.8, "ebene": 16},
	{"name": "Grabenrampe", "form": "sweep", "von": 24.6, "bis": 28.1,
			"profil": [Vector2(3.0, 0.0), Vector2(5.5, 0.0), Vector2(5.5, -1.0),
				Vector2(3.0, -1.0)],
			"profil_ende": [Vector2(3.0, 0.8), Vector2(5.5, 0.8), Vector2(5.5, -1.0),
				Vector2(3.0, -1.0)],
			"ebene": 1},
	# G2 2,0 m breit statt 1,4 (bis an die Nische): Vier Kisten in einer
	# Reihe deckten die ganze Bank, und kein Slide-Sprung kam mehr hinauf
	# (Sprungprobe: jede Stelle prallte an der vordersten Kiste ab). Jetzt
	# stehen drei hintereinander an der Außenkante (KISTEN), vorn bleiben gut
	# 2 m zum Landen und innen ein Gang von 1 m.
	{"name": "G2 Böschungsbank", "form": "kasten", "s": 84.5, "q": 5.6,
			"groesse": Vector3(2.0, 3.2, 5.0), "oben": 2.2, "ebene": 16},
	{"name": "G3 Trittstein", "form": "kasten", "s": 257.0, "q": 3.4,
			"groesse": Vector3(1.4, 2.2, 1.4), "oben": 1.2, "ebene": 1},
	{"name": "G3 Sonnensims", "form": "kasten", "s": 260.5, "q": 4.9,
			"groesse": Vector3(1.4, 3.6, 4.0), "oben": 2.6, "ebene": 16},
	{"name": "Wehrkörper vorn", "form": "sweep", "von": 279.0, "bis": 284.0,
			"profil": [Vector2(-3.6, -0.03), Vector2(3.6, -0.03), Vector2(3.6, -1.6),
				Vector2(-3.6, -1.6)], "ebene": 1},
	{"name": "Wehrkörper hinten", "form": "sweep", "von": 289.0, "bis": 294.0,
			"profil": [Vector2(-3.6, -0.03), Vector2(3.6, -0.03), Vector2(3.6, -1.6),
				Vector2(-3.6, -1.6)], "ebene": 1},
]

## Leitlinien (Ebene 16), je [Vector2(s, q)] = Innenseite, 0,6 m außerhalb
## der Wegkante; dazwischen eine Schulter (Ebene 1). Höhe siehe Kopf.
const LEITLINIE_HOCH := 5.7
const LEITLINIE_GEHEIMNIS := 7.0
const LEITLINIEN := [
	{"name": "Querwand Start", "aussen": 1.0, "hoehe": LEITLINIE_GEHEIMNIS, "unten": 3.0,
			"punkte": [Vector2(-4.0, -7.6), Vector2(-4.0, 7.6)]},
	{"name": "Links", "aussen": -1.0, "hoehe": LEITLINIE_HOCH, "unten": 3.0,
			"schulter": Vector2(-4.0, M_ENDE), "punkte": [
				Vector2(-4.0, -6.6), Vector2(29.0, -6.6), Vector2(34.0, -5.35),
				Vector2(118.0, -5.35), Vector2(120.0, -5.6), Vector2(180.0, -5.6),
				Vector2(184.0, -5.1), Vector2(263.0, -5.1), Vector2(267.0, -4.1),
				Vector2(M_ENDE, -4.1)]},
	# Rechts mit den Nischen hinter G2 (78–88) und G3 (258–263).
	{"name": "Rechts", "aussen": 1.0, "hoehe": LEITLINIE_HOCH, "unten": 3.0,
			"schulter": Vector2(-4.0, M_ENDE), "punkte": [
				Vector2(-4.0, 6.6), Vector2(29.0, 6.6), Vector2(34.0, 5.35),
				Vector2(77.5, 5.35), Vector2(78.0, 6.6), Vector2(88.0, 6.6),
				Vector2(88.5, 5.35), Vector2(118.0, 5.35), Vector2(120.0, 5.6),
				Vector2(180.0, 5.6), Vector2(184.0, 5.1), Vector2(257.5, 5.1),
				Vector2(258.0, 6.2), Vector2(263.0, 6.2), Vector2(263.5, 4.98),
				Vector2(267.0, 4.1), Vector2(M_ENDE, 4.1)]},
	{"name": "Rechts G1", "aussen": 1.0, "hoehe": LEITLINIE_GEHEIMNIS, "unten": 3.0,
			"punkte": [Vector2(-4.0, 6.6), Vector2(4.5, 6.6)]},
	{"name": "Rechts G2", "aussen": 1.0, "hoehe": LEITLINIE_GEHEIMNIS, "unten": 3.0,
			"punkte": [Vector2(76.0, 5.35), Vector2(77.5, 5.35), Vector2(78.0, 6.6),
				Vector2(88.0, 6.6), Vector2(88.5, 5.35), Vector2(90.0, 5.35)]},
	{"name": "Rechts G3", "aussen": 1.0, "hoehe": LEITLINIE_GEHEIMNIS, "unten": 3.0,
			"punkte": [Vector2(256.0, 5.1), Vector2(257.5, 5.1), Vector2(258.0, 6.2),
				Vector2(263.0, 6.2), Vector2(263.5, 4.98), Vector2(265.0, 4.6)]},
	{"name": "Querwand Ende", "aussen": 1.0, "hoehe": LEITLINIE_HOCH, "unten": 3.0,
			"punkte": [Vector2(M_ENDE, 5.1), Vector2(M_ENDE, -5.1)]},
]
## Die Sturzprobe fällt neben dem Weg in „Boden − UNTER_BODEN".
const UNTER_BODEN := 8.0

# =========================================================== Rand und Gelände

## Ränder des Weges, aus denen Saum (`L05Saum`) und Gelände (`L05Gelaende`)
## dieselbe Form lesen. Ein ZUG ist ein Stück Rand auf einer Seite mit einer
## Linie in (s, q) und einer Art:
##   "auf"  eine Böschung hinauf. Die Linie ist ihr Fuß – die Leitlinie, an
##          die die Figur stößt (Entwurf §7.2: „Leitlinien am Böschungsfuß")
##   "ab"   ein Ufer oder eine Wehrwand hinab. Die Linie ist die Lippe,
##          0,4 m außerhalb der Leitlinie: Bis dorthin reicht die Schulter
##          (Kollision Ebene 1, `Wegdaten.schultern_bauen`), und „die Lippe IST
##          die Kollisionskante" (Kanten, Kopf)
## Stützstellen [s, h, Winkel der Wand (Grad), Überhang der Grasnarbe (m),
## Fels (0 Löss und Erde … 1 Schichtfels)], linear dazwischen:
##   auf  h = Krone über der geglätteten Decke (`decke_glatt`): Die Krone
##        folgt dem Hang, nicht den Terrassen und Absätzen der Decke
##   ab   h = Grund (Bett, Teich) unter der geglätteten Decke
## Seiten (Entwurf §5, §8.1): q < 0 ist im Rückblick BILDRECHTS – Schatten und
## Wasser: Lössböschung 3–3,5 m im Hohlweg, im Tobel das Ufer zum Bach, am
## Wehr die Wand zum Unterwasser. q > 0 ist BILDLINKS – der Sonnenhang:
## Löss 4–5 m im Hohlweg, Sandstein im Tobel, am Wehr die Wand zum
## Mühlteich. In A eine niedrige Erdböschung um die Suhle, in C eine Erd-
## böschung über den Terrassen. Löss 78–84° (Entwurf: 70–85°), Narbe
## 0,3–0,45 m Überhang (0,2–0,45). Wo ein Zug endet, läuft seine Höhe gegen
## null, der nächste beginnt flach, und in der Überlappung gibt der eine
## seine Form an den anderen ab (`L05Saum.uebergabe`): Die Böschung sinkt
## mit Platte und Kronenband unter Ufer und Gelände, kein Deckel steht im
## Bild. Am Ende der Decke (M_ENDE) enden beide Seiten mit einer Kante von
## 5 cm, das Feld dahinter liegt eben knapp darunter: Endete ein Zug
## früher (die Teichwand stand bis P3 nur bis 297), fehlte dort der Saum über
## der Schulter, und das Feld darunter (0,9 m tief) stand als schwarzes Loch
## neben dem Wegende im Schlussbild.
const ZUEGE := [
	{"name": "Böschung links", "seite": -1.0, "art": "auf", "von": -4.0, "bis": 182.0,
			"punkte": [
				[-4.0, 0.05, 40.0, 0.1, 0.0], [1.0, 0.75, 45.0, 0.2, 0.0],
				[6.0, 0.7, 45.0, 0.2, 0.0], [10.0, 0.18, 30.0, 0.1, 0.0],
				[23.0, 0.18, 30.0, 0.1, 0.0], [27.0, 0.8, 50.0, 0.2, 0.0],
				[31.0, 2.0, 70.0, 0.3, 0.0], [35.0, 3.1, 80.0, 0.35, 0.0],
				[50.0, 3.4, 82.0, 0.4, 0.0], [68.0, 3.0, 80.0, 0.35, 0.0],
				[90.0, 3.5, 83.0, 0.42, 0.0], [110.0, 3.2, 80.0, 0.38, 0.0],
				[118.0, 2.6, 72.0, 0.32, 0.0], [124.0, 2.2, 62.0, 0.3, 0.0],
				[150.0, 2.0, 60.0, 0.3, 0.0], [172.0, 1.8, 58.0, 0.28, 0.0],
				[178.0, 1.0, 50.0, 0.2, 0.0], [182.0, 0.05, 35.0, 0.1, 0.0]]},
	{"name": "Ufer links", "seite": -1.0, "art": "ab", "von": 179.0, "bis": 300.0,
			"punkte": [
				[179.0, 0.15, 50.0, 0.1, 0.0], [184.0, 1.6, 55.0, 0.25, 0.1],
				[190.0, 2.8, 62.0, 0.3, 0.15], [220.0, 3.0, 64.0, 0.3, 0.2],
				[255.0, 2.8, 62.0, 0.3, 0.2], [268.0, 2.7, 64.0, 0.28, 0.25],
				[276.0, 2.8, 76.0, 0.2, 0.6], [280.0, 2.8, 85.0, 0.12, 0.9],
				[294.0, 2.6, 85.0, 0.12, 0.9], [298.0, 1.2, 70.0, 0.15, 0.5],
				[300.0, 0.3, 50.0, 0.1, 0.2]]},
	{"name": "Böschung rechts", "seite": 1.0, "art": "auf", "von": -4.0, "bis": 279.0,
			"punkte": [
				[-4.0, 0.05, 40.0, 0.1, 0.0], [2.0, 0.9, 45.0, 0.2, 0.0],
				[24.0, 1.1, 50.0, 0.25, 0.0], [28.0, 2.2, 65.0, 0.3, 0.0],
				[33.0, 4.1, 80.0, 0.35, 0.0], [45.0, 4.6, 82.0, 0.4, 0.0],
				[58.0, 4.4, 80.0, 0.38, 0.0], [70.0, 4.0, 78.0, 0.32, 0.0],
				[80.0, 4.6, 80.0, 0.38, 0.0], [95.0, 5.0, 84.0, 0.45, 0.0],
				[108.0, 4.5, 80.0, 0.4, 0.0], [117.0, 3.6, 76.0, 0.35, 0.0],
				[123.0, 2.8, 66.0, 0.3, 0.0], [150.0, 2.5, 64.0, 0.3, 0.0],
				[176.0, 2.8, 66.0, 0.3, 0.1], [183.0, 4.0, 72.0, 0.3, 0.5],
				[195.0, 4.8, 75.0, 0.3, 0.8], [215.0, 5.6, 76.0, 0.3, 0.85],
				[235.0, 5.2, 74.0, 0.3, 0.8], [255.0, 4.4, 72.0, 0.3, 0.7],
				[265.0, 3.0, 64.0, 0.25, 0.4], [272.0, 1.2, 50.0, 0.2, 0.1],
				[279.0, -0.5, 40.0, 0.1, 0.0]]},
	{"name": "Teichwand rechts", "seite": 1.0, "art": "ab", "von": 277.0, "bis": M_ENDE,
			"punkte": [
				[277.0, 0.1, 45.0, 0.1, 0.2], [281.0, 1.4, 84.0, 0.12, 0.9],
				[292.0, 1.4, 84.0, 0.12, 0.9], [297.0, 0.1, 45.0, 0.1, 0.3],
				[M_ENDE, 0.05, 40.0, 0.1, 0.2]]},
]
## Die geglättete Decke (`decke_glatt`): Mittel über ±DECKE_GLATT m, als
## Tabelle in Schritten von GLATT_SCHRITT ab GLATT_VON.
const DECKE_GLATT := 8.0
const GLATT_VON := -60.0
const GLATT_BIS := 460.0
const GLATT_SCHRITT := 0.5
## Die Hauereiche nach dem Entwurf (§8.2): Kuppe des Geländes (s, Y ihres
## Scheitels) und die beiden Schirmkronen als Vector3(q, Y der Mitte,
## Radius) – für das Gelände und, nur solange keine Eiche gebaut ist, für
## die Freiraumprobe (K3). Gebaut wird sie in `L05Eiche`, mit der
## Stammachse 3,5 m weiter hinten (L05Eiche.STAMM_S) und den Kronen an
## Ästen; deren Punkte liefert `wahrzeichen` an K3 und die
## Wahrzeichenprobe.
const EICHE := {"s": -6.0, "boden_y": 27.0,
		"kronen": [Vector3(-11.0, 55.0, 7.5), Vector3(11.0, 55.0, 7.5)]}

# =========================================================== Spiel

## Alle 49 Kisten (§6.4): 46 NORMAL (im Zeitmodus 15 Zeitkisten),
## 2 FRUCHT_MEHRFACH, 1 LEBEN; keine SCHUTZ-Kisten (§1 Nr. 14 – der Keiler
## ruft `sterben()` direkt). Auf q 0 nur im Lehrteil A, sonst q +2,2 bzw.
## +2,0 in Gassen von höchstens drei, 1,2 m auseinander, über `boden_bei`.
## "auf": Name eines Eintrags aus BEGEHBARES, auf dessen Oberkante sie steht.
##
## Die Liste steht in ZÄHLREIHENFOLGE, nicht nach der Strecke: Im Zeitmodus
## wird jede dritte NORMAL-Kiste in der Reihenfolge, in der sie gebaut wird,
## eine Zeitkiste (`LevelBasis._zeitkisten_setzen`, Werte 2/1/3 im Wechsel).
## Zeitkisten stehen AUF dem Weg, nie abseits (Zeitlauf.gd, Kopf); bis
## Runde 2 fielen fünf davon abseits oder hinter das Wehr – in den Graben,
## auf G1 und G2 und 3 m vor das Portal, wo 2 s ihrer Standzeit am Ziel
## verfielen (Spiel-Jury R2, Mangel 2). Deshalb stehen die Kisten der
## Geheimnisse, des Grabens und hinter dem Wehr hier an Stellen, die keine
## Zeitkiste werden, und jede Gasse der Hauptlinie trägt eine, die erste in
## B zwei; die letzte steht bei 272,2, vor dem Wehr. Die Gasse hinter dem
## Sims trägt nur eine (1 s): Mit zweien dort verfielen von den letzten drei
## Zeitkisten (6 s in gut einer Sekunde Lauf) am Ziel noch 1,45 s (gemessen).
## Die 15 mit „Zeit" bezeichneten Einträge sind es (in dieser Reihenfolge
## 2, 1, 3, 2, … s, zusammen 30 s).
##
## Die Gasse am Sonnensims steht HINTER dem Simsende (263,6–266,0). Bis
## Runde 2 lag sie bei 260,0–262,4 neben dem Sims: Seit G3 um 5 m nach
## hinten gerückt war (siehe Kopf, ABWEICHUNGEN), lagen beide nebeneinander
## zwischen denselben Rastplätzen, vom Sims erreichte der Drehschlag die
## Gasse nicht, und zurück konnte man vor dem Keiler nicht – alle 49 Kisten
## gingen praktisch nie (Spiel-Jury R2, Mangel 1). Von hinter dem Sims läuft
## man jetzt auf die Gasse hinab. Die LEBEN-Kiste ist der Lohn auf dem Sims
## (Mangel 6): Hinter dem Wehr, wo sie bis Runde 2 stand, konnte man nicht
## mehr sterben, und beim Betreten eines Levels gibt es ohnehin wieder fünf
## Leben (`Spielfluss.zum_level`). Auf dem Sims hilft sie vor dem Wehr, der
## gefährlichsten Stelle; holen kann man sie nur hinter der Kette, nach CP5
## nicht mehr – sammeln lässt sie sich also nicht durch Sterben.
const KISTEN := [
	# --- Lehrteil A und G1 (Zählung 1–5) ---
	# Auf G1 hinten und außen: Vorn innen bleibt Platz zum Landen.
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 2.0, "q": 4.3, "auf": "G1 Wurzelknie"},
	{"art": Kiste.Art.NORMAL, "s": 0.8, "q": 6.0, "auf": "G1 Wurzelknie"},
	{"art": Kiste.Art.NORMAL, "s": 2.0, "q": 5.5, "auf": "G1 Wurzelknie"},
	{"art": Kiste.Art.NORMAL, "s": 20.4, "q": 0.0},  # Zeit 2
	{"art": Kiste.Art.NORMAL, "s": 21.6, "q": 0.0},
	{"art": Kiste.Art.NORMAL, "s": 24.6, "q": 0.0},  # Grabensohle
	# --- B (6–20), dazwischen G2 und die Grabensohle ---
	{"art": Kiste.Art.NORMAL, "s": 36.0, "q": 2.2},  # Zeit 1
	{"art": Kiste.Art.NORMAL, "s": 37.2, "q": 2.2},
	# G2: drei Kisten hintereinander an der Außenkante der Bank, innen bleibt
	# ein Gang von 1,0 m (q 4,6–5,6). Zu zweit nebeneinander sperrten sie die
	# Bank in voller Breite: Wer ohne Drehschlag landete, lief gegen sie und
	# blieb stehen (Spiel-Jury R1, Mangel 11).
	{"art": Kiste.Art.NORMAL, "s": 84.35, "q": 6.1, "auf": "G2 Böschungsbank"},
	{"art": Kiste.Art.NORMAL, "s": 38.4, "q": 2.2},  # Zeit 3
	{"art": Kiste.Art.NORMAL, "s": 25.8, "q": 0.0},  # Grabensohle
	{"art": Kiste.Art.NORMAL, "s": 85.4, "q": 6.1, "auf": "G2 Böschungsbank"},
	{"art": Kiste.Art.NORMAL, "s": 65.0, "q": 2.2},  # Zeit 2
	{"art": Kiste.Art.NORMAL, "s": 66.2, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 67.4, "q": 2.2},
	# Die Kiste hinter dem Wasserriss in der Kistenspur.
	{"art": Kiste.Art.NORMAL, "s": 80.4, "q": 2.2},  # Zeit 1
	{"art": Kiste.Art.NORMAL, "s": 86.45, "q": 6.1, "auf": "G2 Böschungsbank"},
	{"art": Kiste.Art.NORMAL, "s": 27.0, "q": 0.0},  # Grabensohle
	{"art": Kiste.Art.NORMAL, "s": 110.0, "q": 2.2},  # Zeit 3
	{"art": Kiste.Art.NORMAL, "s": 111.2, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 112.4, "q": 2.2},
	# --- C (21–32), dazwischen G3 und hinter dem Wehr ---
	{"art": Kiste.Art.NORMAL, "s": 128.6, "q": 2.2},  # Zeit 2
	{"art": Kiste.Art.NORMAL, "s": 129.8, "q": 2.2},
	{"art": Kiste.Art.FRUCHT_MEHRFACH, "s": 259.9, "q": 4.9, "auf": "G3 Sonnensims"},
	{"art": Kiste.Art.NORMAL, "s": 261.0, "q": 4.9, "auf": "G3 Sonnensims"},
	{"art": Kiste.Art.LEBEN, "s": 262.1, "q": 4.9, "auf": "G3 Sonnensims"},
	{"art": Kiste.Art.NORMAL, "s": 144.5, "q": 2.2},  # Zeit 1
	{"art": Kiste.Art.NORMAL, "s": 145.7, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 291.5, "q": 2.2},  # hinter dem Wehr
	{"art": Kiste.Art.NORMAL, "s": 152.5, "q": 2.2},  # Zeit 3
	{"art": Kiste.Art.NORMAL, "s": 153.7, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 292.9, "q": 2.2},  # hinter dem Wehr
	{"art": Kiste.Art.NORMAL, "s": 167.5, "q": 2.0},  # Zeit 2
	{"art": Kiste.Art.NORMAL, "s": 168.7, "q": 2.0},
	{"art": Kiste.Art.NORMAL, "s": 169.9, "q": 2.0},
	# --- D (33–43) ---
	{"art": Kiste.Art.NORMAL, "s": 182.0, "q": 2.2},  # Zeit 1
	{"art": Kiste.Art.NORMAL, "s": 183.2, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 184.4, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 200.4, "q": 2.2},  # Zeit 3
	{"art": Kiste.Art.NORMAL, "s": 201.6, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 294.1, "q": 2.2},  # hinter dem Wehr
	{"art": Kiste.Art.NORMAL, "s": 237.0, "q": 2.2},  # Zeit 2
	{"art": Kiste.Art.NORMAL, "s": 238.2, "q": 2.2},
	# Die Gasse hinter dem Simsende von G3 (siehe oben).
	{"art": Kiste.Art.NORMAL, "s": 264.8, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 263.6, "q": 2.2},  # Zeit 1
	{"art": Kiste.Art.NORMAL, "s": 266.0, "q": 2.2},
	# --- E (44–46) ---
	{"art": Kiste.Art.NORMAL, "s": 271.0, "q": 2.2},
	{"art": Kiste.Art.NORMAL, "s": 272.2, "q": 2.2},  # Zeit 3, die letzte
	{"art": Kiste.Art.NORMAL, "s": 273.4, "q": 2.2},
]

## Früchte (§6.4, 119). Die Bögen über Lücken, Hürden und Graben liegen
## 0,8 m (am Graben 1,0 m) neben der Wegmitte, abwechselnd links und rechts:
## Längs auf q 0 stand jeder Bogen aus der Rückblickkamera als senkrechte
## Säule genau auf der Figur (Spiel-Jury R1, Mangel 9; Bild-Jury R1,
## Mangel 11). Eingesammelt werden sie trotzdem (Anziehung ab 2,6 m,
## `Frucht.MAGNET_RADIUS`).
## Schema wie Level 01: "reihe" gleichmäßig von–bis auf
## Höhe "h" (Vorgabe 0,9), auf Wunsch quer von "q" nach "q_ende"; "boden"
## dasselbe auf 0,35 m (weist auf den Slide, Durchlässe); "bogen" über eine
## Lücke, "scheitel" = Höhe der mittleren Frucht über der Decke; "punkte"
## einzelne Vector3(s, q, Höhe über der Decke).
const FRUECHTE := [
	# --- A: 24 ---
	# Eichelspur an der Schnauze des schlafenden Keilers vorbei.
	{"art": "reihe", "von": 7.5, "bis": 12.5, "anzahl": 8, "q": -2.6, "q_ende": 0.0},
	{"art": "boden", "von": 13.6, "bis": 16.6, "anzahl": 4, "q": 0.0},
	# Über den Suhlgraben auf der Bahn des Slide-Sprungs: Scheitel 2,4 über
	# dem Weg ist 3,2 über der Grabensohle (gemessen wird an der Decke).
	{"art": "bogen", "von": 23.0, "bis": 28.6, "anzahl": 6, "q": -1.0, "scheitel": 3.2},
	{"art": "punkte", "punkte": [Vector3(3.6, 4.6, 1.6), Vector3(3.0, 4.6, 2.6),
			Vector3(2.6, 4.6, 3.4), Vector3(0.8, 4.6, 3.7), Vector3(0.4, 4.6, 3.7),
			Vector3(2.0, 4.9, 4.4)]},
	# --- B: 32 ---
	{"art": "bogen", "von": 43.0, "bis": 45.0, "anzahl": 3, "q": 0.8, "scheitel": 1.9},
	{"art": "boden", "von": 54.6, "bis": 57.6, "anzahl": 4, "q": 0.0},
	{"art": "bogen", "von": 74.5, "bis": 78.5, "anzahl": 6, "q": 0.8, "scheitel": 2.2},
	# G2: eine Spur hinauf und oben über den Kisten.
	{"art": "punkte", "punkte": [Vector3(79.6, 3.9, 1.2), Vector3(80.4, 4.4, 2.0),
			Vector3(81.2, 4.9, 2.8), Vector3(81.8, 5.2, 3.3), Vector3(83.0, 5.4, 3.1),
			Vector3(84.2, 5.6, 3.1), Vector3(86.0, 5.6, 4.0)]},
	{"art": "bogen", "von": 92.0, "bis": 94.0, "anzahl": 3, "q": -0.8, "scheitel": 1.9},
	{"art": "boden", "von": 100.6, "bis": 103.6, "anzahl": 4, "q": 0.0},
	{"art": "reihe", "von": 112.0, "bis": 118.0, "anzahl": 5, "q": 0.0},
	# --- C: 21 ---
	{"art": "reihe", "von": 125.4, "bis": 127.4, "anzahl": 3, "q": 0.0},
	{"art": "bogen", "von": 135.8, "bis": 140.2, "anzahl": 6, "q": -0.8, "scheitel": 2.2},
	{"art": "reihe", "von": 149.4, "bis": 151.4, "anzahl": 3, "q": 0.0},
	{"art": "bogen", "von": 159.8, "bis": 164.2, "anzahl": 6, "q": 0.8, "scheitel": 2.2},
	{"art": "reihe", "von": 173.4, "bis": 175.4, "anzahl": 3, "q": 0.0},
	# --- D: 30 ---
	{"art": "bogen", "von": 193.5, "bis": 198.0, "anzahl": 6, "q": -0.8, "scheitel": 2.2},
	{"art": "boden", "von": 210.6, "bis": 213.6, "anzahl": 4, "q": 0.0},
	{"art": "boden", "von": 219.8, "bis": 222.8, "anzahl": 4, "q": 0.0},
	{"art": "bogen", "von": 229.2, "bis": 233.2, "anzahl": 6, "q": 0.8, "scheitel": 2.2},
	# Durch die Findlingsgasse: rechts an F1 vorbei, links an F2.
	{"art": "punkte", "punkte": [Vector3(242.0, 1.8, 0.9), Vector3(244.0, 1.8, 0.9),
			Vector3(247.0, 0.0, 0.9), Vector3(250.0, -1.8, 0.9), Vector3(252.0, -1.8, 0.9)]},
	{"art": "punkte", "punkte": [Vector3(257.0, 3.4, 2.1), Vector3(257.8, 4.0, 3.2),
			Vector3(258.8, 4.9, 3.5), Vector3(262.2, 4.9, 3.5), Vector3(262.2, 4.4, 3.5)]},
	# --- E: 12 ---
	# Auf der Bahn des Doppelsprungs über das Wehr (Füße im Scheitel 3,2).
	{"art": "bogen", "von": 283.5, "bis": 289.5, "anzahl": 7, "q": 0.8, "scheitel": 3.6},
	{"art": "reihe", "von": 290.5, "bis": 295.0, "anzahl": 5, "q": 0.0},
]

## Rastplätze (§6.5): Zonen auf `boden_bei`, Breite `breite_bei` + 2. Der
## erste ist zugleich die Stelle des Weckens (L05Jagd.WECK_S).
const RASTPLAETZE: Array[float] = [31.0, 122.0, 178.0, 204.0, 268.0]
## Der Checkpoint eines Rastplatzes liegt so hoch über der Decke (die Figur
## erscheint dort und fällt auf den Weg). L05Jagd erkennt den Rastplatz
## daran wieder.
const RASTPLATZ_UEBER := 0.6
## Die Zone ist so hoch, dass auch ein Doppelsprung (Füße 3,2 + Figur 1,3)
## nicht darüber hinwegkommt, und so tief, dass ein Slide sie nicht
## überspringt.
const RASTPLATZ_HOEHE := 8.0
const RASTPLATZ_TIEFE := 2.0

## Geheimnisse (§6.3) zum Nachschlagen: Ort, Weg hinauf, Inhalt.
const GEHEIMNISSE := [
	{"name": "G1 Eichelvorrat", "auf": "G1 Wurzelknie", "weg": "Doppelsprung",
			"inhalt": "FRUCHT_MEHRFACH, 2 NORMAL, 6 Früchte"},
	{"name": "G2 Böschungsbank", "auf": "G2 Böschungsbank",
			"weg": "Slide-Sprung oder Doppelsprung, Einzelsprung nicht",
			"inhalt": "3 NORMAL, 7 Früchte (Spur und Bank)"},
	{"name": "G3 Sonnensims", "auf": "G3 Sonnensims",
			"weg": "Trittstein, dann zwei Einzelsprünge",
			"inhalt": "FRUCHT_MEHRFACH, NORMAL, LEBEN, 5 Früchte"},
]

## Harte Sichtweiten (Entwurf §9.5, Kostenmessung §10): Spiel und HUD sind
## ohne sie der größte Posten.
const SICHTWEITEN := {"kiste": 50.0, "frucht": 40.0, "kiste_web": 40.0, "frucht_web": 35.0}

## Richtzeit des Zeitmodus (Entwurf §6.6), von Hand gesetzt wie in Level 06
## (level06.gd, `zielzeit`). Die abgeleitete Formel der Basis (296 / 8,5 ×
## 2,8 ≈ 97 s) schenkte hier jede Stufe.
##
## ABGESTUFT STATT KLIPPE (Spiel-Jury R2, Mangel 2). Bei einer Jagd mit
## festem Tempo ist die Uhr ohne Kisten fast fest: Die Ideallinie ohne Kiste
## braucht gemessen 35,28 s (Jagdprobe mit Zeitmodus, 60 Hz), jeder
## Überlebende 35–41 s. Runde 1 setzte die Richtzeit aus einem Lauf, der
## alle Zeitkisten der Hauptlinie mitnahm (1,3 × 11,58 s → 15 s): Wer sauber,
## aber ohne Kistenjagd lief, holte keine Stufe und sah ab s ≈ 130 „Richtzeit
## vorbei"; Saphir verlangte 9–10 der 12 Zeitkisten. Jetzt:
##   Saphir  37,0 s    der saubere Lauf ohne Kisten, mit gut 1,5 s Luft
##                     (ein, zwei Stolperer)
##   Gold    31,45 s   dazu gut 3,8 s Standzeit: zwei, drei Zeitkisten
##   Platin  26,64 s   dazu gut 8,6 s: vier, fünf Zeitkisten
## Die Zeitkisten stehen seit Runde 2 alle auf der Hauptlinie, eine in jeder
## Gasse, die letzte vor dem Wehr (siehe KISTEN): 15 Stück, 30 s Standzeit.
## Ein Drehschlag im Vorbeilaufen kostet kaum Abstand zum Keiler. Was der
## Lauf mit Zeitkisten gemessen bringt, steht in `doku/level05-neubau.md`,
## Abschnitt R2. Dem Nutzer vorzulegen (Spiel-Jury R2: „Der Nutzer
## entscheidet").
const ZIELZEIT := 37.0

# =========================================================== Proben

## Eine Landung zählt ab so weit vor dem Rand der Gegenseite (wie Level 01).
const LANDUNG_SPIEL := 0.45
## Freiraum (Entwurf §7.1, §2.6): K1 über |q| ≤ K1_Q zwischen K1_UNTEN und
## K1_OBEN über dem Weg nichts Sichtbares; K2 Kamera über jedem Durchlass
## mindestens K2_MIN über seinem Boden; die Kamera mindestens
## KAMERA_UEBER_FIGUR über der Figur – 3,5 m laut Entwurf, 5 cm Spiel für
## die Glättung der Kurve an den Knicken der KURVENHOEHE (gemessen 3,486).
const K1_Q := 3.5
const K1_UNTEN := 4.6
const K1_OBEN := 9.2
const K2_MIN := 5.3
const KAMERA_UEBER_FIGUR := 3.45
## K1: Dreiecke werden in Punkten höchstens so weit auseinander abgetastet.
const K1_RASTER := 1.0
## K5 (`_freiraum_k5`): Fenster vor der Stirn eines Durchlasses (sauberer
## Slide, Sprungprobe P1a: −3,75 … −0,5) und vor der Zone einer Hürde
## (−2,75 … −1,0), Schritt, Punkte der Figur Vector2(q, Höhe über der
## Decke) – Füße, Brust (auch 0,25 m seitlich), Kopf –, Breite des
## Streifens, dessen Dreiecke zählen, und der Anteil freier Stellen, den
## die Brust mindestens braucht (Spiel-Jury R1: „Brust frei ≥ 70 %").
const K5_DUCK := Vector2(3.75, 0.5)
const K5_HUERDE := Vector2(2.75, 1.0)
const K5_SCHRITT := 0.25
const K5_PUNKTE: Array[Vector2] = [Vector2(0.0, 0.25), Vector2(0.0, 0.7), Vector2(-0.25, 0.7),
		Vector2(0.25, 0.7), Vector2(0.0, 1.15)]
const K5_QUER := 0.6
const K5_BRUST_MIN := 0.7
## K1: Ein Dreieck, dessen Schwerpunkt weiter als K1_WEIT + sein Umkreis von
## der Kurve liegt, kann keinen Punkt im freien Raum haben: Dort liegt jeder
## Punkt höchstens √(K1_Q² + (K1_OBEN + 0,64)²) ≈ 10,5 m von ihr (0,64 =
## größter Abstand Decke–Kurve, §3). Gelände und Saum haben zigtausend
## Dreiecke weit vom Weg; ohne diese Vorprüfung tastete die Probe sie alle ab.
const K1_WEIT := 10.6
## K3 (Entwurf §7.1): von jeder Stelle K3_VON … M_ENDE (alle K3_SCHRITT m)
## Strahlen von der Kamera zur Mitte jeder Krone der Eiche und zu den
## Probepunkten in ihrem Laub (`wahrzeichen`; ohne gebaute Eiche zu Mitte
## und Rand, K3_RAND · Radius, der Kronen aus EICHE), abgetastet alle
## K3_TAKT m bis K3_VOR · Radius vor der Krone.
const K3_VON := 6.0
const K3_SCHRITT := 2.0
const K3_RAND := 0.6
const K3_TAKT := 1.0
const K3_VOR := 1.2

## Jagdprobe (`jagdfaelle`): wo der Mensch, der durchläuft, slidet und
## springt – je in der Mitte der Fenster, die die Sprungprobe gemessen hat
## (P1a: Durchlass −3,75 … −0,5 vor der Stirn, Hürde −2,75 … −1,00 vor der
## Zone, L1/L5 −1,75 … 0, L2/L3 −2,0 … 0, L4 −1,25 … +0,25 vor der Kante,
## Wehr im Doppelsprung 281,75 … 284,25).
const JAGD_SLIDE_VOR := 2.0
const JAGD_HUERDE_VOR := 2.0
const JAGD_SPRUNG_VOR := {"L1 Wasserriss": 0.75, "L2 Terrasse": 0.75, "L3 Terrasse": 0.75,
		"L4 Seitenrinne": 0.5, "L5 Mühlrinne": 0.75}
const JAGD_WEHR_SPRUNG := 282.75
const JAGD_DOPPEL_NACH := 0.33
## Fehler (Entwurf §2.4/§2.5, jagd.py): gehaltene Taste bis Stirn + 6
## (Messbank l05_messung) – losgelassen spätestens JAGD_LOSLASSEN_VOR vor
## dem nächsten Slide, sonst krabbelt die Figur weiter und der nächste Slide
## kommt nie (player.gd: kein Slide aus dem Krabbeln; D3 + 6 = 220 ist genau
## der Slide vor D4); nach dem Stolpern 0,25 s Reaktion bis zum Slide;
## Zögern 1,5 m vor der Kante.
## GEGENPROBE: Der Entwurf (§2.5, jagd.py) rechnete „Stolpern D3 + D4, dazu
## 0,3 s Zögern vor L5" mit 3,2 m Rest und „drei Fehler je 0,7 s" als
## gefangen. In der Engine bleibt mehr: Der Slide nach dem Stolpern holt den
## Vorsprung des Slides doch noch (13,5 gegen 7,4 m/s), jagd.py zog ihn
## ab. Gemessen (Jagdprobe, Zögern vor L5 nach zwei Stolperern): 0,3 s →
## 6,66 m, 0,7 s → 3,97 m, 0,8 s → 3,23 m, 0,9 s → 2,49 m, ab 1,0 s
## gefangen. Die Gegenprobe zögert deshalb JAGD_ZOEGERN_LANG = 1,2 s –
## sicher über der Schwelle, damit sie wirklich zeigt, dass die Probe einen
## Fang erkennt.
const JAGD_HALTEN_BIS := 6.0
const JAGD_LOSLASSEN_VOR := 0.3
const JAGD_REAKTION := 0.25
const JAGD_ZOEGERN := 0.3
const JAGD_ZOEGERN_LANG := 1.2
const JAGD_ZOEGERN_VOR := 1.5
## Mindestabstand im Ideallauf (Entwurf P1: 10 m; seit R2 rückt der Keiler
## im Nacken heran: C 8 m, E 7,5 m, minus ein Sprung – L05Jagd, Kopf) und
## nach EINEM Fehler an einer Hürde oder einem Durchlass in B (Spiel-Jury
## R2, Mangel 3; über dem Fangabstand 2 mit einem halben Meter Luft).
const JAGD_IDEAL_MIN := 6.0
const JAGD_FEHLER_MIN := 2.5
## Nach dem Respawn so lange stehen, bevor es losgeht (Spiel-Jury R1,
## Mangel 5: „Reaktionsfall ≥ 0,8 s"), und der Abstand, der dann mindestens
## bleiben soll. Bis Runde 2 gut der halbe Weg von VORSPRUNG zum Fangabstand
## (8 m); seit dem Nacken (L05Jagd, Kopf) steht er in C und E ohnehin auf
## 8 bzw. 7,5 m heran, und der Doppelsprung am Wehr kostet dort noch einen
## halben Meter (gemessen an CP5: 7,10 m bei s 287,8, im Ideallauf 7,35 m).
## Geprüft wird also: Die Reaktion drückt ihn nicht unter den Nacken minus
## einen Sprung.
const JAGD_REAKTION_RESPAWN := 1.0
const JAGD_REAKTION_MIN := 6.5
## Am Ufer (Entwurf §5 E): hier stehen bleiben – gefangen; hier über der
## Lücke gehalten – sicher.
const JAGD_STEHEN_S := 283.5
const JAGD_SCHWEBEN_S := 284.5
## Hier endet ein Lauf (hinter dem Wehr, vor dem Zielportal).
const JAGD_ENDE_S := 292.0
## Lauflinie (s, q): in A rechts an den Kisten auf q 0 vorbei, durch das
## Gatter und über die Grabenrampe (q 3,0–5,5) aus dem Suhlgraben; in der
## Findlingsgasse rechts an F1 vorbei (frei ab q +0,48 mit der Kapsel),
## links an F2 (frei bis q −0,48). Gerechnet mit 1,5 m Vorausschau des
## Lenkers: bei F1 q ≥ 1,4, an der Stirn von F2 q ≤ −1,5.
const JAGD_SPUR: Array[Vector2] = [
	Vector2(-10.0, 0.0), Vector2(7.5, 0.0), Vector2(10.5, 4.2), Vector2(28.5, 4.2),
	Vector2(30.5, 0.0), Vector2(241.0, 0.0), Vector2(242.5, 1.8), Vector2(245.6, 1.8),
	Vector2(247.6, -1.8), Vector2(252.0, -1.8), Vector2(254.5, 0.0), Vector2(310.0, 0.0),
]

## Die Jagd (Modul `L05Jagd`); gesetzt von ihrem Bauschritt.
var jagd: L05Jagd
## Körper der Durchlässe in der Reihenfolge von DURCHLAESSE (für den Bruch);
## gefüllt von den Bauschritten der Wegbauten (`L05Wegbauten._durchlass`).
var durchlass_koerper: Array[StaticBody3D] = []
## Meldungen, die nur einmal kommen.
var _gemeldet := {}
## Das Gelände (Modul `L05Gelaende`); gesetzt von seinem ersten Bauschritt.
var gelaende: L05Gelaende
## Die Hauereiche (Modul `L05Eiche`); gesetzt beim Zusammenstellen der
## Schritte, gebaut in ihrem Schritt.
var eiche: L05Eiche
## Das Wasser (Modul `L05Wasser`), gesetzt beim Zusammenstellen der Schritte.
## Nicht „wasser": So heißt das Bauteil von `KorridorLevel`.
var gewaesser: L05Wasser
## Der Wald (Modul `L05Wald`) und Rasen, Laub und Farn (`L05Rasen`), gesetzt
## beim Zusammenstellen der Schritte.
var wald: L05Wald
var rasen: L05Rasen
## Licht, Nebel, Bewegung und Klang (Modul `L05Stimmung`), gesetzt von ihrem
## Bauschritt.
var abendlicht: L05Stimmung
## Gebaute Flächen des Saums je Zug (`Kanten.flaeche_punkt`), Name des
## Zuges -> {"flaeche"}; gefüllt von `L05Saum` (für die Rinnsale).
var saum_flaechen := {}
## Die geglättete Decke als Tabelle (`decke_glatt`), angelegt mit dem Verlauf.
var _glatt := PackedFloat32Array()
## Sind die Texturen angestoßen (`_enter_tree`)?
var _vorgerechnet := false


func ende() -> float:
	return M_ENDE


## Ohne Wirkung: Statt `absturzzonen` liegen Todeszonen auf fester Höhe.
func absturz_hoehe() -> float:
	return -UNTER_BODEN


# =========================================================== Aufbau

## Texturen der Bibliothek, die das Level kalt in Arbeitsfäden vorrechnet
## (siehe `_enter_tree`), in der Reihenfolge, in der der Aufbau sie braucht:
## Löss, dann Wegmaske und Rasen (`Wegmaske.vorrechnen`), dann diese.
const VORRECHNEN_ERST: Array[String] = ["waldweg"]
const VORRECHNEN_DANN: Array[String] = ["waldboden", "fels", "wurzelfels", "pfuetze",
		"rinde", "struktur_holz", "struktur_metall", "struktur_laub"]


## Stößt die Texturen an, bevor der Aufbau beginnt (`Bauspeicher.vorrechnen`).
## `_enter_tree` läuft vor dem `_ready` der Kinder – die Fäden rechnen also
## schon, während die Figur gebaut wird, und danach, während der Hang
## vermessen und trianguliert wird (`L05Gelaende.bauschritte`); die
## Schritte, die sie brauchen, holen sie fertig ab.
##
## WARUM. Kalt (erstes Laden nach jeder Codeänderung) rechnete der
## Hauptfaden diese Texturen Bildpunkt für Bildpunkt in den Schritten:
## gemessen 1,6 s, der Löss allein 0,55 s in einem Schritt (Entwurf §9.4:
## kein Schritt über 400 ms). Sie hängen nur von festen Zahlen ab; geteilt
## werden konnte der Löss ohne Eingriff in den geteilten Code nicht.
## Liegen sie im Bauspeicher, stößt das hier nichts an. Was nie abgeholt
## wird, wartet das Level beim Verlassen ab (`vorrechnungen_verwerfen`).
##
## GRENZE (Entscheidung K1 zu Entwurf §9.4): Kalt ≤ 8 s gilt für den
## Spielweg aus dem Portalraum. Dort ist die Szene samt Skripten meist
## schon vorgeladen (`Spielfluss.vorladen_naechstes`); gemessen 4,85–5,06 s
## Aufbau, ohne Vorladen 7,6–7,8 s gesamt. Die Bauzeitprobe mit Level 05
## allein übersetzt dazu alle Skripte und baut die Figur. Sie darf im Median
## bis 8,5 s liegen (gemessen 8,05 und 8,07 s), warm bis 4 s (2,6–2,8 s).
## Alle Zahlen stammen von einem Rechner. Ein langsamerer hebt sie
## gemeinsam an; Level 01 lag in derselben Probe kalt bei 10,8–11,3 s.
func _enter_tree() -> void:
	if _vorgerechnet:
		return
	_vorgerechnet = true
	Materialbibliothek.vorrechnen(VORRECHNEN_ERST)
	Wegmaske.vorrechnen()
	Materialbibliothek.vorrechnen(VORRECHNEN_DANN)
	tree_exiting.connect(Bauspeicher.vorrechnungen_verwerfen, CONNECT_ONE_SHOT)


## Gerüst nach Entwurf §9.4: Hang (Gelände), Hohlweg (Decke, Kollision,
## Lippen), Böschungen, Stufen und Ufer (Saum), Suhle, Bach und Mühlbach
## samt Mühlrad (Wasser), die Hauereiche, Wegbauten
## (je Abschnitt ein Schritt), Spiel, Wald und Rasen, Keiler. Was ein
## späteres Paket baut (Licht), fehlt noch; die Reihenfolge der übrigen
## Schritte bleibt.
func _bauschritte() -> Array:
	_verlauf_anlegen()
	# Beim Verlassen räumen (Baukasten §0 Nr. 3): Die Stoffe der Wegdecke
	# liegen je Schlüssel im Zwischenspeicher von `Wegdecke`, und
	# `GelaendeSaum` hält Flächen in statischen Merkern.
	tree_exiting.connect(func() -> void:
		Wegdecke.vergessen(WEG_SCHLUESSEL)
		GelaendeSaum.vergessen(), CONNECT_ONE_SHOT)
	# Die Texturen der Bibliothek, die Decke, Gelände und Saum teilen, in
	# eigenen Schritten vor dem ersten Stoff, der sie braucht: dem des Hangs
	# (siehe STOFFE im Kopf und `L05Gelaende.bauschritte`).
	var texturen: Array = [
		{"text": "Löss wird gesiebt", "tun": func() -> void: Materialbibliothek.waldweg()},
		{"text": "Spur und Rasen werden ausgelegt", "tun": func() -> void:
			Wegmaske.textur()
			Wegmaske.rasen_textur()},
	]
	var schritte: Array = L05Gelaende.bauschritte(self, texturen)
	schritte.append({"text": "Der Hohlweg wird gelegt", "tun": _weg_bauen})
	schritte.append_array(L05Saum.bauschritte(self))
	schritte.append_array(L05Wasser.bauschritte(self))
	schritte.append_array(L05Eiche.bauschritte(self))
	schritte.append_array(L05Wegbauten.bauschritte(self))
	schritte.append({"text": "Kisten, Früchte, Rastplätze", "tun": _spiel_setzen})
	# Wald und Rasen nach den Kisten: Sie halten Abstand zu ihnen.
	schritte.append_array(L05Wald.bauschritte(self))
	schritte.append_array(L05Rasen.bauschritte(self))
	schritte.append_array(L05Stimmung.bauschritte(self))
	schritte.append_array(L05Jagd.bauschritte(self))
	return schritte


func _verlauf_anlegen() -> void:
	Effekte.staubfarbe = Farben.WEG_HELL.lerp(Farben.KIES_HELL, 0.3)
	verlauf = kurve_bauen()
	start_strecke = START_S
	weg = Wegdaten.new(verlauf, {
		"abschnitte": _abschnitte_rechnen(),
		"begehbares": BEGEHBARES,
		"leitlinien": LEITLINIEN,
	})
	weg.todeszonen = _todeszonen_rechnen()
	_glatt_rechnen()


## Die Kurve (siehe Kopf, VERLAUF): erst der Grundriss durch KURVE (flach),
## dann alle KURVE_DICHTE Meter ein Punkt darauf, so weit entlang, dass die
## 3D-Bogenlänge bis dorthin `s` ist, mit der Höhe KURVENHOEHE(s).
static func kurve_bauen() -> Curve3D:
	var flach: Array[Vector3] = []
	for p: Vector3 in KURVE:
		flach.append(Vector3(p.x, 0.0, p.z))
	var grund := LevelWerkzeuge.kurve_aus_punkten(flach)
	var punkte: Array[Vector3] = []
	var s := 0.0
	while s < KURVE_ENDE - 0.5:
		punkte.append(_kurvenpunkt(grund, s))
		s += KURVE_DICHTE
	punkte.append(_kurvenpunkt(grund, KURVE_ENDE))
	return LevelWerkzeuge.kurve_aus_punkten(punkte)


static func _kurvenpunkt(grund: Curve3D, s: float) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(grund, _grundlaenge(s))
	p.y = kurvenhoehe(s)
	return p


## KURVENHOEHE an der Stelle `s` (linear, vor dem Anfang und hinter dem
## Ende wie dort).
static func kurvenhoehe(s: float) -> float:
	var erster: Vector2 = KURVENHOEHE[0]
	if s <= erster.x:
		return erster.y
	for i in KURVENHOEHE.size() - 1:
		var a: Vector2 = KURVENHOEHE[i]
		var b: Vector2 = KURVENHOEHE[i + 1]
		if s <= b.x:
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	var letzter: Vector2 = KURVENHOEHE[KURVENHOEHE.size() - 1]
	return letzter.y


## Länge im Grundriss bis zur 3D-Bogenlänge `s`. KURVENHOEHE ist stückweise
## linear in `s`, die Neigung k also je Stück fest: Ein Meter Bogen ist dort
## √(1 − k²) Meter Grundriss.
static func _grundlaenge(s: float) -> float:
	var laenge := 0.0
	var bis_hier := 0.0
	for i in KURVENHOEHE.size() - 1:
		var a: Vector2 = KURVENHOEHE[i]
		var b: Vector2 = KURVENHOEHE[i + 1]
		var k := (b.y - a.y) / (b.x - a.x)
		var ende_stueck := minf(s, b.x)
		if ende_stueck > bis_hier:
			laenge += (ende_stueck - bis_hier) * sqrt(1.0 - k * k)
			bis_hier = ende_stueck
		if s <= b.x:
			break
	if s > bis_hier:
		laenge += s - bis_hier
	return laenge


func _kurve_y(s: float) -> float:
	return verlauf.sample_baked(clampf(s, 0.0, verlauf.get_baked_length())).y


## Breite laut BREITEN an der Stelle `s`.
static func breite_nach_tabelle(s: float) -> float:
	var erster: Vector2 = BREITEN[0]
	if s <= erster.x:
		return erster.y
	for i in BREITEN.size() - 1:
		var a: Vector2 = BREITEN[i]
		var b: Vector2 = BREITEN[i + 1]
		if s <= b.x:
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	var letzter: Vector2 = BREITEN[BREITEN.size() - 1]
	return letzter.y


## Die Abschnitte im Schema der Wegdaten aus den Tabellen (siehe Kopf, WEG):
##  1. feste Stücke – Terrassen, Suhlgraben, Absätze mit ihren Rampen
##     (Rampen beginnen und enden auf der Höhe der fertigen Kurve, damit an
##     keiner Naht eine Stufe entsteht);
##  2. dazwischen folgt die Decke der Kurve (ohne "hoehe");
##  3. geschnitten an jeder Lückengrenze und jeder Stützstelle der Breite,
##     Lücken fallen heraus.
func _abschnitte_rechnen() -> Array[Dictionary]:
	var fest: Array[Dictionary] = []
	for t: Dictionary in TERRASSEN:
		var h: float = t["hoehe"]
		fest.append({"name": t["name"], "von": t["von"], "bis": t["bis"], "h0": h, "h1": h})
	fest.append({"name": "Suhlgraben", "von": SUHLGRABEN.x, "bis": SUHLGRABEN.y,
			"h0": SUHLGRABEN.z, "h1": SUHLGRABEN.z})
	for i in ABSAETZE.size():
		var a: Dictionary = ABSAETZE[i]
		var name_a: String = a["name"]
		var von: float = a["von"]
		var bis: float = a["bis"]
		var h: float = a["hoehe"]
		fest.append({"name": name_a, "von": von, "bis": bis, "h0": h, "h1": h})
		# Rampe davor, außer sie fällt mit der Rampe hinter dem vorigen
		# Absatz zusammen (dann baut jener die gemeinsame).
		var vorher_frei := i == 0 or float(ABSAETZE[i - 1]["bis"]) + RAMPE <= von - RAMPE
		if vorher_frei:
			fest.append({"name": "Rampe vor " + name_a, "von": von - RAMPE, "bis": von,
					"h0": _kurve_y(von - RAMPE), "h1": h})
		var nachher_frei := i == ABSAETZE.size() - 1 \
				or bis + RAMPE <= float(ABSAETZE[i + 1]["von"]) - RAMPE
		if nachher_frei:
			var ende_rampe := minf(bis + RAMPE, M_ENDE)
			fest.append({"name": "Rampe hinter " + name_a, "von": bis, "bis": ende_rampe,
					"h0": h, "h1": _kurve_y(ende_rampe)})
		else:
			var naechster: Dictionary = ABSAETZE[i + 1]
			fest.append({"name": "Rampe nach " + String(naechster["name"]), "von": bis,
					"bis": naechster["von"], "h0": h, "h1": naechster["hoehe"]})
	fest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["von"]) < float(b["von"]))
	# Lückenlos über den ganzen Weg; zwischen festen Stücken die Kurve.
	var stuecke: Array[Dictionary] = []
	var bis_hier := 0.0
	for f in fest:
		var f_von: float = f["von"]
		if f_von < bis_hier - 0.001:
			push_error("Level 05: festes Wegstück %s überlappt seinen Vorgänger" % String(f["name"]))
		if f_von > bis_hier + 0.001:
			stuecke.append({"name": "Kurve", "von": bis_hier, "bis": f_von})
		stuecke.append(f)
		bis_hier = f["bis"]
	if bis_hier < M_ENDE - 0.001:
		stuecke.append({"name": "Kurve", "von": bis_hier, "bis": M_ENDE})
	var schnitte: Array[float] = []
	for l: Dictionary in LUECKEN:
		schnitte.append(float(l["von"]))
		schnitte.append(float(l["bis"]))
	for b: Vector2 in BREITEN:
		schnitte.append(b.x)
	var liste: Array[Dictionary] = []
	for st in stuecke:
		var st_von: float = st["von"]
		var st_bis: float = st["bis"]
		var grenzen: Array[float] = [st_von]
		for x in schnitte:
			if x > st_von + 0.001 and x < st_bis - 0.001 and not grenzen.has(x):
				grenzen.append(x)
		grenzen.append(st_bis)
		grenzen.sort()
		for k in grenzen.size() - 1:
			var a := grenzen[k]
			var b := grenzen[k + 1]
			if _in_luecke((a + b) * 0.5):
				continue
			var e := {"name": st["name"], "von": a, "bis": b,
					"breite": breite_nach_tabelle(a), "breite_ende": breite_nach_tabelle(b)}
			if a < KRONENLICHT.x:
				e["kronenlicht"] = KRONENLICHT.y
			if st.has("h0"):
				var h0: float = st["h0"]
				var h1: float = st["h1"]
				e["hoehe"] = lerpf(h0, h1, inverse_lerp(st_von, st_bis, a))
				e["hoehe_ende"] = lerpf(h0, h1, inverse_lerp(st_von, st_bis, b))
			liste.append(e)
	return liste


static func _in_luecke(s: float) -> bool:
	for l: Dictionary in LUECKEN:
		if s > float(l["von"]) and s < float(l["bis"]):
			return true
	return false


## Todeszonen (siehe Kopf): „Boden − UNTER_BODEN" von hinter der Querwand
## bis zum Ende der Kurve, dazu je Lücke eine auf fester Höhe.
func _todeszonen_rechnen() -> Array[Dictionary]:
	var zonen := Wegdaten.zonen_unter_boden(weg, -8.0, KURVE_ENDE, -30.0, 30.0, UNTER_BODEN)
	for l: Dictionary in LUECKEN:
		var von: float = l["von"]
		var bis: float = l["bis"]
		var tod_y: float = l["tod_y"]
		var halb := maxf(breite_nach_tabelle(von), breite_nach_tabelle(bis)) * 0.5 + 2.0
		zonen.append({"name": l["name"], "von": von - 0.5, "bis": bis + 0.5,
				"q_von": -halb, "q_bis": halb, "oben_y": tod_y, "unten_y": tod_y - 12.0})
	return zonen


## Die Decke mit dem Stoff des Hohlwegs (EIN Stoff, also EIN Netz),
## Schultern, Leitlinien, Begehbares, Todeszonen und die Steine an den
## Lippen der sechs Lücken.
func _weg_bauen() -> void:
	var stoff := Wegdecke.stoff(wegdecke_thema(), weg, weg.abschnitte, WEG_SCHLUESSEL + "waldweg")
	weg.decke_bauen(geometrie, func(_a: Dictionary) -> Material: return stoff)
	weg.schultern_bauen(geometrie)
	weg.leitlinien_bauen(geometrie)
	weg.begehbares_bauen(geometrie, _begehbar_optik)
	weg.todeszonen_bauen(geometrie)
	Wegdecke.lippen(geometrie, weg, lippen_thema())
	_auslauf_bauen(stoff)


## Der AUSLAUF der Decke: hinter M_ENDE läuft die Spur über AUSLAUF_LAENGE
## Meter in die Wiese aus – ein Streifen ohne Kollision im Stoff der Decke,
## auf der Kurve, der sich wie eine Zunge rundet (`auslauf_halb`). Die
## Wegmaske rechnet quer in halben Breiten (UV2.x), also wird die helle Spur
## mit ihm schmal und endet rund; seine Ränder sind Rasen wie der des Felds.
## (Linear verjüngt stand die Spur als lange, gerade Spitze im Schlussbild.)
## WARUM: Vorher endete die Decke an M_ENDE auf ganzer Breite mit einem
## geraden Strich, und dahinter begann die dunkelbraune „ausgetretene Spur"
## des Felds (Schlamm) – eine harte Materialkante quer durch das Schlussbild
## (Prüfung P3, Runde 2). Der Shader kennt kein Ende der Spur; seine Lücken
## (8 Plätze, 7 belegt) brächen sie nur krümelig ab wie an einer Lippe.
## Das Feld liegt darunter 2 cm tiefer (`L05Gelaende`, flach bis über den
## Rand, `auslauf_halb`).
func _auslauf_bauen(stoff: Material) -> void:
	var stuecke: Array[Dictionary] = []
	var s := M_ENDE
	while s < M_ENDE + AUSLAUF_LAENGE - 0.001:
		var bis := minf(s + AUSLAUF_SCHRITT, M_ENDE + AUSLAUF_LAENGE)
		stuecke.append({"name": "Auslauf", "von": s, "bis": bis,
				"breite": auslauf_halb(s) * 2.0, "breite_ende": auslauf_halb(bis) * 2.0})
		s = bis
	var netz := LevelWerkzeuge.korridor(geometrie, verlauf, stuecke, {"oben": stoff}, {
		"nur_decke": true, "uv_quer": true, "schritt": AUSLAUF_SCHRITT, "quer_teilung": 4,
		"kollision": false,
	})
	netz.name = "Wegauslauf"
	for kind in netz.get_children():
		kind.name = "Auslauf"
	_ohne_schatten(netz)


## Halbe Breite des Auslaufs an `s` (0 außerhalb): an M_ENDE die der Decke,
## dann als Viertelellipse bis auf 5 cm am Ende.
static func auslauf_halb(s: float) -> float:
	if s < M_ENDE or s > M_ENDE + AUSLAUF_LAENGE:
		return 0.0
	var t := (s - M_ENDE) / AUSLAUF_LAENGE
	return maxf(breite_nach_tabelle(M_ENDE) * 0.5 * sqrt(maxf(1.0 - t * t, 0.0)), 0.05)


## Thema der Wegdecke (Entwurf §9.2 und Schritt 2 von §9.4): der Waldweg der
## Bibliothek, die Erde in Löss getönt (`erde_ton`). Der Rasen (`wald_rasen`)
## bleibt der der Wegmaske: Saum und Gelände tragen denselben, nur so bleibt
## die Naht an der Wegkante unsichtbar. Lücken: die sechs der Wegdaten und
## der Suhlgraben (`luecken_zusatz`) – zusammen 7, der Shader fasst 8. Den
## Graben führt der Stoff als Lücke, obwohl dort Decke liegt: Die helle Spur
## bricht an seinen Kanten krümelig ab wie an einer Lippe, und seine Sohle
## zeichnet der Saum (Schlamm der Suhle, `L05Saum`), nicht die Decke.
func wegdecke_thema() -> Dictionary:
	return {"uniforms": {"erde_ton": LOESS_WEG},
			"luecken_zusatz": [Vector3(SUHLGRABEN.x, SUHLGRABEN.y, 1.0)]}


## Thema der Lippen (Entwurf §8.4): je Lippe vier bis sechs helle Steine
## bündig an der Kante und Leuchtpilze an den Ecken, an L1–L6. Der
## Suhlgraben bekommt keine (§5 A): Harmlose Gräben tragen keine Steine.
func lippen_thema() -> Dictionary:
	var luecken: Array[Dictionary] = []
	for l: Dictionary in LUECKEN:
		luecken.append({"name": "L05 " + String(l["name"]), "von": l["von"], "bis": l["bis"]})
	return {"luecken": luecken, "lippen_steine": LIPPEN_STEINE, "name": "L05"}


## Optik des Begehbaren: Bänke, Trittstein und Grabenrampe zeichnet
## `L05Wegbauten` in seinen Abschnitten (verschmolzen je Stoff) – hier steht
## nur eine leere Marke. Ohne eigene Optik bleiben (OHNE_OPTIK) der
## Startboden – den Boden dort zeichnet das Gelände – und die Wehrkörper
## unter der Wehrkrone, deren Seiten der Saum als Wehrwände zeichnet: Ihre
## Oberseite lag mit der Schulter des Saums in einer Ebene und flimmerte.
## Was keiner zeichnet, bekäme einen grauen Platzhalter ohne Schatten.
func _begehbar_optik(e: Dictionary) -> Node3D:
	var name_e := String(e["name"])
	if OHNE_OPTIK.has(name_e) or L05Wegbauten.BEGEHBARE.has(name_e):
		var leer := Node3D.new()
		leer.name = "OhneOptik" if OHNE_OPTIK.has(name_e) else "Optik (Wegbauten)"
		return leer
	var sicht := weg.platzhalter(e)
	_ohne_schatten(sicht)
	return sicht


static func _ohne_schatten(wurzel: Node) -> void:
	if wurzel is GeometryInstance3D:
		(wurzel as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for kind in wurzel.get_children():
		_ohne_schatten(kind)


## Für LevelCheck (Oberseiten des Begehbaren) und Kisten auf Begehbarem.
func begehbar(name_: String) -> Dictionary:
	return weg.begehbar(name_)


# =========================================================== Rand und Gelände

## Welt-Y der Decke, über ±DECKE_GLATT m gemittelt (Lücken überbrückt, vor dem
## Anfang die Decke von A, hinter M_ENDE die Kurve): Darauf liegen Kronen und
## Betten der Ränder (ZUEGE), damit sie dem Hang folgen und nicht den Stufen
## der Terrassen und Absätze.
func decke_glatt(s: float) -> float:
	var f := clampf((s - GLATT_VON) / GLATT_SCHRITT, 0.0, float(_glatt.size() - 1))
	var i := mini(floori(f), _glatt.size() - 2)
	return lerpf(_glatt[i], _glatt[i + 1], f - float(i))


func _glatt_rechnen() -> void:
	var n := int(round((GLATT_BIS - GLATT_VON) / GLATT_SCHRITT)) + 1
	# Summen von vorn: das Mittel eines Fensters ohne innere Schleife.
	var summen := PackedFloat64Array()
	summen.resize(n + 1)
	summen[0] = 0.0
	for i in n:
		var s := GLATT_VON + GLATT_SCHRITT * float(i)
		var y := _kurve_y(s) if s > M_ENDE else weg.boden_bei(s)
		summen[i + 1] = summen[i] + y
	var fenster := int(round(DECKE_GLATT / GLATT_SCHRITT))
	_glatt.resize(n)
	for i in n:
		var a := maxi(i - fenster, 0)
		var b := mini(i + fenster, n - 1)
		_glatt[i] = (summen[b + 1] - summen[a]) / float(b - a + 1)


## Werte eines Zuges (ZUEGE) an der Stelle `s`: [h, Winkel, Überhang, Fels];
## vor dem ersten und hinter dem letzten Punkt wie dort.
static func zug_werte(zug: Dictionary, s: float) -> PackedFloat32Array:
	var punkte: Array = zug["punkte"]
	var a: Array = punkte[0]
	if s <= float(a[0]):
		return PackedFloat32Array([a[1], a[2], a[3], a[4]])
	for i in range(1, punkte.size()):
		var b: Array = punkte[i]
		if s <= float(b[0]):
			var t := (s - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			return PackedFloat32Array([lerpf(a[1], b[1], t), lerpf(a[2], b[2], t),
					lerpf(a[3], b[3], t), lerpf(a[4], b[4], t)])
		a = b
	return PackedFloat32Array([a[1], a[2], a[3], a[4]])


## Die Züge einer Seite (−1/+1), die `s` enthalten.
func zuege_bei(seite: float, s: float) -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	for z: Dictionary in ZUEGE:
		if float(z["seite"]) == seite and s >= float(z["von"]) and s <= float(z["bis"]):
			liste.append(z)
	return liste


## Die Linie eines Zuges als [Vector2(s, q)]: die Leitlinie seiner Seite
## zwischen "von" und "bis", bei "ab" 0,4 m weiter außen (die Lippe am Ende
## der Schulter). Vor dem Anfang und hinter dem Ende der Leitlinie (M_ENDE)
## mit ihrem ersten bzw. letzten Abstand.
static func zug_linie(zug: Dictionary) -> PackedVector2Array:
	var seite: float = zug["seite"]
	var punkte := leitlinie_punkte(seite)
	var von: float = zug["von"]
	var bis: float = zug["bis"]
	var aussen := seite * (0.4 if String(zug["art"]) == "ab" else 0.0)
	var linie := PackedVector2Array([Vector2(von, leitlinie_q(punkte, von) + aussen)])
	for p: Vector2 in punkte:
		if p.x > von + 0.01 and p.x < bis - 0.01:
			linie.append(Vector2(p.x, p.y + aussen))
	linie.append(Vector2(bis, leitlinie_q(punkte, bis) + aussen))
	return linie


## Punkte der Leitlinie einer Seite ("Links" q < 0, "Rechts" q > 0).
static func leitlinie_punkte(seite: float) -> Array:
	var name_l := "Links" if seite < 0.0 else "Rechts"
	for e: Dictionary in LEITLINIEN:
		if String(e["name"]) == name_l:
			return e["punkte"]
	return []


## q der Leitlinie an `s`, vor und hinter ihr wie an ihren Enden.
static func leitlinie_q(punkte: Array, s: float) -> float:
	var erster: Vector2 = punkte[0]
	var letzter: Vector2 = punkte[punkte.size() - 1]
	return Wegdaten.polylinie_q(punkte, clampf(s, erster.x, letzter.x))


## Die Lücke, in der `s` liegt (Eintrag aus LUECKEN), sonst {}.
static func luecke_bei(s: float) -> Dictionary:
	for l: Dictionary in LUECKEN:
		if s > float(l["von"]) and s < float(l["bis"]):
			return l
	return {}


## Gezeichnete Höhe des Geländes an (x, z) in Level-Koordinaten (Entwurf
## §9.1, für Eiche, Wald und Rasen); NAN, solange es nicht steht.
func gelaende_hoehe(x: float, z: float) -> float:
	return gelaende.hoehe(x, z) if gelaende != null else NAN


# =========================================================== Spiel

## Sichtweiten zuerst (sie greifen bei allem, was danach unter `objekte`
## eintritt), dann Kisten, Früchte, Rastplätze, Meldungen, Portale.
func _spiel_setzen() -> void:
	sichtweiten_einrichten(SICHTWEITEN)
	for e: Dictionary in KISTEN:
		var art: Kiste.Art = e["art"]
		var s: float = e["s"]
		var q: float = e["q"]
		var ueber := 0.5
		if e.has("auf"):
			ueber = weg.oberkante(String(e["auf"]), s, q) - boden_bei(s) + 0.5
		kiste_auf(art, s, q, ueber)
	_fruechte_setzen()
	for s in RASTPLAETZE:
		_rastplatz(s)
	_meldung(HINWEIS_S, HINWEIS_SLIDE, 2.4)
	_meldung(ENTKOMMEN_S + 0.4, "Entkommen!", 2.4, 0.0)
	# Ohne Lichtsäule (siehe `portale_auf`): Im Rückblick stünde sie mitten
	# in der Kamerabahn.
	portale_auf(START_S, ZIEL_S, 0.0)
	_ziel_verbergen()
	_ziel_ausloeser_verbreitern()


func _fruechte_setzen() -> void:
	for e: Dictionary in FRUECHTE:
		match String(e["art"]):
			"reihe", "boden":
				var anzahl: int = e["anzahl"]
				var von: float = e["von"]
				var bis: float = e["bis"]
				var q: float = e["q"]
				var q_ende: float = e.get("q_ende", q)
				var h: float = 0.35 if String(e["art"]) == "boden" else float(e.get("h", 0.9))
				for i in anzahl:
					var t := float(i) / maxf(float(anzahl - 1), 1.0)
					frucht_auf(lerpf(von, bis, t), lerpf(q, q_ende, t), h)
			"bogen":
				fruechte_bogen_auf(float(e["von"]), float(e["bis"]), int(e["anzahl"]),
						float(e["q"]), float(e["scheitel"]))
			"punkte":
				for p: Vector3 in e["punkte"]:
					frucht_auf(p.x, p.y, p.z)


## Rastplatz: eine Zone quer über den Weg (auf der Decke, Breite + 2 m). Den
## Wegpfahl mit der Laterne baut `L05Wegbauten`.
func _rastplatz(s: float) -> void:
	var zone := Area3D.new()
	zone.name = "Rastplatz %.0f" % s
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.monitorable = false
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite_bei(s) + 2.0, RASTPLATZ_HOEHE, RASTPLATZ_TIEFE)
	form.shape = kasten
	zone.add_child(form)
	zone.position = weg_punkt(s, 0.0, RASTPLATZ_HOEHE * 0.5 - 1.0)
	zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
	zone.body_entered.connect(_auf_rastplatz.bind(s))
	objekte.add_child(zone)


func _auf_rastplatz(koerper: Node3D, s: float) -> void:
	if not koerper is Spieler:
		return
	var ort := to_global(weg_punkt(s, 0.0, RASTPLATZ_UEBER))
	if GameState.checkpoint.distance_to(ort) > 1.0:
		GameState.setze_checkpoint(ort)
		GameState.zeige_nachricht("Rastplatz", 1.2)


## Meldung, die beim ersten Durchlaufen von `s` einmal erscheint. Die Zone
## ist 0,8 m tief und RASTPLATZ_HOEHE hoch, ihre Unterkante `unten` über der
## Decke (Vorgabe 1 m darunter, wie die Rastplätze).
func _meldung(s: float, text: String, dauer: float, unten := -1.0) -> void:
	var zone := Area3D.new()
	zone.name = "Meldung %.0f" % s
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.monitorable = false
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite_bei(s) + 2.0, RASTPLATZ_HOEHE, 0.8)
	form.shape = kasten
	zone.add_child(form)
	zone.position = weg_punkt(s, 0.0, RASTPLATZ_HOEHE * 0.5 + unten)
	zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
	zone.body_entered.connect(func(koerper: Node3D) -> void:
		if koerper is Spieler and not _gemeldet.has(text):
			_gemeldet[text] = true
			GameState.zeige_nachricht(text, dauer))
	objekte.add_child(zone)


## ZIELPORTAL (Spiel-Jury R1, Mangel 6; Bild-Jury R1, Mangel 2): Im
## Rückblick steht das Portal zwischen Figur und Kamera. Sichtbar vom
## Anlauf auf das Wehr an verdeckte die leuchtende Kugel die Landestelle des
## Pflicht-Doppelsprungs (289–291) und die Figur bis auf die Ohren (Bilder
## s 280–289). Es bleibt deshalb unsichtbar – Ring, Scheibe, Funken,
## Schein und Bodenfleck; der Auslöser wirkt immer –, bis die Figur
## ENTKOMMEN_S erreicht (hinter der Lippe, auf der Decke), dann geht es mit
## einem Lichtschlag auf wie das Startportal (`Portal._startauftritt`).
## Gemessen wird die Strecke der Figur und nicht über die Zone der Meldung:
## So steht es auch, wenn eine Probe oder ein Foto die Figur dorthin setzt.
var _zielportal: Portal = null
var _ziel_offen := false


func _ziel_verbergen() -> void:
	for kind in objekte.get_children():
		if kind is Portal and (kind as Portal).ist_ziel:
			_zielportal = kind as Portal
	if _zielportal == null:
		return
	for teil: String in ["Optik", "Lichtfleck"]:
		var n := _zielportal.get_node_or_null(teil) as Node3D
		if n != null:
			n.visible = false
			n.scale = Vector3.ONE * 0.05


## ZIELAUSLÖSER (Spiel-Jury R2, Mangel 4): Der Auslöser des Zielportals
## ist ein Zylinder mit r 1,04 auf q 0 (ZielPortal.tscn); die Wehrkrone ist
## 7 m breit. Wer auf q ≥ 1,6 lief – etwa an der Kistengasse hinter dem
## Wehr entlang –, lief am Portal vorbei an die Querwand bei 300 und musste
## zurück ins Bild (gemessen: q 1,6 und 2,0 in 90 s nicht geschafft, q 1,1
## geschafft). Hier bekommt NUR dieses Portal einen Kasten über die ganze
## Breite des Weges plus 1 m je Seite, ZIEL_AUSLOESER_TIEF lang (so tief wie
## der Zylinder auf seiner Mitte) und so hoch wie er. Die Form des Knotens
## wird ersetzt, nicht die Ressource der geteilten Szene. Gegen einen
## zweiten Aufruf schützt das Portal selbst (`Portal._ausgeloest`); es
## saugt die Figur von dort, wo sie den Kasten betritt, in seine Mitte.
const ZIEL_AUSLOESER_TIEF := 2.08
const ZIEL_AUSLOESER_HOCH := 2.3


func _ziel_ausloeser_verbreitern() -> void:
	if _zielportal == null:
		return
	var form := _zielportal.get_node_or_null("Kollision") as CollisionShape3D
	if form == null:
		push_warning("Level 05: Zielportal ohne Knoten \"Kollision\" – Auslöser bleibt schmal")
		return
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite_bei(ZIEL_S) + 2.0, ZIEL_AUSLOESER_HOCH, ZIEL_AUSLOESER_TIEF)
	form.shape = kasten


## STOLPERSPERRE (Spiel-Jury R2, Mangel 5): Nach einem Stolpern löst keine
## Stolperzone dieses Levels für STOLPER_SPERRE s nach dessen Ende ein
## zweites aus. WARUM: Wer an einer Hürde 0,6 m zu spät sprang, stolperte in
## der Luft, landete vor der Zone und lief gleich wieder hinein – zweimal
## gestolpert (H1 Mindestabstand 6,70 m, H2 7,04 m), während wer gar nicht
## sprang nur einmal stolperte (7,75 / 7,99 m). Der späte Versuch wog also
## schwerer als keiner; auch der Spieltest-Bot stolperte an H2 zweimal,
## 0,5 s auseinander. Die Sperre gilt für Hürden, Durchlässe und Findlinge
## gleich. Sie hält nur, solange die Figur waagerecht höchstens
## STOLPER_SPERRE_WEITE von der Stelle des Stolperns bleibt – wer hochspringt
## und zurückfällt, bleibt dort; wer weiterläuft oder versetzt wird (Proben
## setzen die Figur zwischen zwei Versuchen zurück), verlässt sie. Zwei
## Hindernisse liegen nirgends näher als 9 m (D3–D4: 9,2 m), ein zweites
## Stolpern dort zählt also weiter.
## Umgesetzt als Überschreibung des Handlers aus `KorridorLevel` – die Zonen
## rufen ihn über ihre Verbindung (`_stolperzone`); die geteilte Datei und
## jedes andere Level (auch die Werkstatt) bleiben, wie sie sind.
const STOLPER_SPERRE := 0.6
const STOLPER_SPERRE_WEITE := 1.5
var _stolper_sperre := 0.0
var _stolper_ort := Vector3.ZERO


func _durchlass_stolpern(koerper: Node3D, dauer: float) -> void:
	var figur := koerper as Spieler
	if figur == null or _stolper_sperre > 0.0:
		return
	if figur.invuln <= 0.0:
		_stolper_sperre = dauer + STOLPER_SPERRE
		_stolper_ort = figur.global_position
	figur.stolpern(dauer)


func _physics_process(delta: float) -> void:
	if _stolper_sperre > 0.0:
		_stolper_sperre = maxf(_stolper_sperre - delta, 0.0)
		if _spieler != null:
			var weg := _spieler.global_position - _stolper_ort
			weg.y = 0.0
			if weg.length() > STOLPER_SPERRE_WEITE:
				_stolper_sperre = 0.0
	if _ziel_offen or _zielportal == null or _spieler == null:
		return
	if strecke_der_figur() >= ENTKOMMEN_S \
			and to_local(_spieler.global_position).y >= boden_bei(ENTKOMMEN_S) - 0.5:
		_ziel_zeigen()


func _ziel_zeigen() -> void:
	_ziel_offen = true
	var tween := create_tween().set_parallel(true)
	for teil: String in ["Optik", "Lichtfleck"]:
		var n := _zielportal.get_node_or_null(teil) as Node3D
		if n == null:
			continue
		n.visible = true
		tween.tween_property(n, "scale", Vector3.ONE, Portal.EINBLEND_ZEIT) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var optik := _zielportal.get_node_or_null("Optik") as Node3D
	if optik != null:
		Effekte.aufblitzen(_zielportal, optik.global_position,
				_zielportal.farbe().lightened(0.3), _zielportal.radius * 2.6, 0.22)


## Die Jagd beginnt erst, wenn die Figur losdarf (nach dem Rundgang).
func _vor_dem_start() -> void:
	if jagd != null:
		jagd.freigeben()


func zielzeit() -> float:
	return ZIELZEIT


# =========================================================== Proben

## Opt-in-Proben von `werkzeuge/level_check.gd` (Entwurf P1).
func pruefprofil() -> Dictionary:
	return {"sicht": true, "todeszonen": true, "rand": true, "freiraum": true, "wasser": true}


## Opt-in "wasser" von LevelCheck (Paket P6): Todeszonen unverändert, kein
## Wasser tödlich, die Zone am Wehr unter dem Weißwasser (`L05Wasser.probe`).
## Nicht verwechseln mit `werkzeuge/wasserprobe.gd`: Das zählt die
## Wasser-Gefahren eines Levels.
func wasser_zonenprobe() -> PackedStringArray:
	return L05Wasser.probe(self, gewaesser)


## Probepunkte des Wahrzeichens für `werkzeuge/wahrzeichenprobe.gd` und
## die Freiraumprobe K3 (Entwurf §11 Nr. 7, §7.1 K3; P4): je Krone und für
## die Kerbe ein Eintrag {"name", "punkte"} in Weltkoordinaten – die
## Kronenpunkte im Laub, dazu "mitte" und "radius" der Hülle; die Kerbe mit
## "kanten" (die innersten Ecken der Kronen). Aus der gebauten Eiche
## (`L05Eiche.wahrzeichen`); vor ihrem Bauschritt leer.
func wahrzeichen() -> Array[Dictionary]:
	if eiche == null:
		var leer: Array[Dictionary] = []
		return leer
	return eiche.wahrzeichen()


## Stellen der Wahrzeichenprobe: vom Start bis zum Ziel (Entwurf P4).
func wahrzeichen_strecke() -> Vector2:
	return Vector2(START_S, ZIEL_S)


## Hält an, was von selbst läuft: den Keiler (L05Jagd, Ruhestellung).
func pruefruhe() -> void:
	if jagd != null:
		jagd.pruefruhe()


## Fotos (werkzeuge/foto.gd): die Figur auf die Wegdecke, nicht 1 m über
## die Kurve – auf Terrassen und Absätzen schwebte sie sonst.
func foto_stelle(s: float, q: float) -> Vector3:
	return weg_punkt(s, q)


## Sprungfälle für `werkzeuge/sprungprobe.gd` (Entwurf §6.2, P1). Die
## Grenzen sind die gemessenen Fenster des Entwurfs minus einen Raster-
## schritt (0,25), bzw. die Grenzen aus P1: L1 und L5 ≥ 1,75, L2/L3 ≥ 1,85,
## L4 ≥ 1,25; das Wehr nur im Doppelsprung (im Scheitel, 0,33 s) ≥ 2,0 –
## der Einzelsprung darf nicht tragen; Durchlässe als Slide sauber ≥ 3,0,
## Hürden ≥ 1,5. Kür mit `pflicht: false`: G1 Doppelsprung, G2 Slide-
## Sprung, Suhlgraben, G3 und der Slide-Sprung am Wehr (R3: Slide-Sprung
## nur als Kür); an G2 darf der Einzelsprung nicht tragen (Pflicht).
## Jeder Fall startet nach dem letzten Hindernis davor: hinter D3 für D4,
## hinter D4 für L5.
func sprungfaelle() -> Array[Dictionary]:
	var faelle: Array[Dictionary] = []
	var fenster := {"L1 Wasserriss": 1.75, "L2 Terrasse": 1.85, "L3 Terrasse": 1.85,
			"L4 Seitenrinne": 1.25, "L5 Mühlrinne": 1.75}
	var anlauf := {"L1 Wasserriss": 70.0, "L2 Terrasse": 131.3, "L3 Terrasse": 155.3,
			"L4 Seitenrinne": 189.0, "L5 Mühlrinne": 225.3}
	for l: Dictionary in LUECKEN:
		var name_l: String = l["name"]
		if not fenster.has(name_l):
			continue
		var kante: float = l["von"]
		var start: float = anlauf[name_l]
		faelle.append({"name": name_l, "art": "einfach", "start": Vector2(start, 0.0),
				"kante": kante, "von": maxf(kante - 2.75, start + 1.5),
				"landung": float(l["bis"]) - LANDUNG_SPIEL, "fenster_min": fenster[name_l]})
	var wehr: Dictionary = LUECKEN[5]
	var wehr_von: float = wehr["von"]
	var wehr_landung: float = float(wehr["bis"]) - LANDUNG_SPIEL
	faelle.append({"name": "L6 Wehr Doppel", "art": "doppel", "start": Vector2(278.0, 0.0),
			"kante": wehr_von, "von": 280.0, "landung": wehr_landung, "doppel_t": [0.33],
			"fenster_min": 2.0})
	faelle.append({"name": "L6 Wehr Einzel", "art": "einfach", "start": Vector2(278.0, 0.0),
			"kante": wehr_von, "von": 281.0, "landung": wehr_landung, "darf_nicht_tragen": true})
	faelle.append({"name": "L6 Wehr Slide-Sprung", "art": "slide", "start": Vector2(278.0, 0.0),
			"kante": wehr_von, "von": 280.5, "landung": wehr_landung, "pflicht": false})
	# Durchlässe: Start 9 m vor der Stirn, bei D4 hinter D3 (Ausgang 215,6).
	# Angekommen ist, wer 0,5 m hinter dem Ausgang steht: Hinter Ü stehen
	# die Kisten auf q 0 (20,4), vor denen ein früher Slide stehen bleibt.
	for d: Dictionary in DURCHLAESSE:
		var stirn: float = d["s"]
		var tiefe: float = d["tiefe"]
		var start := stirn - 9.0
		if String(d["name"]).begins_with("D4"):
			start = 216.1
		faelle.append({"name": String(d["name"]), "art": "duck", "start": Vector2(start, 0.0),
				"kante": stirn, "von": maxf(stirn - 5.0, start + 1.0),
				"landung": stirn + tiefe + 0.5, "fenster_min": 3.0})
	for h: Dictionary in HUERDEN:
		var vorn := float(h["s"]) - HUERDE_ZONE_LAENGE * 0.5
		faelle.append({"name": String(h["name"]), "art": "huerde",
				"start": Vector2(vorn - 5.5, 0.0), "kante": vorn, "von": vorn - 4.0,
				"landung": vorn + HUERDE_ZONE_LAENGE + 2.0, "fenster_min": 1.5})
	# --- Geheimnisse: Bänke statt Lücken ---
	# Bei einer Bank ist "kante" die letzte Absprungstelle, die das Mess-
	# fenster des Entwurfs noch nennt (0,4 m vor der Stirn), nicht die Stirn
	# selbst: Dort springt niemand hinauf. Die Bahn liegt ganz über der Bank –
	# wer sie verfehlt, prallt an der Stirn ab ("k") und landet nicht daneben
	# auf dem Weg, was die Probe sonst als getragen zählte.
	# G1 vom Startboden vor s 0 (die Decke und das Knie beginnen bei 0).
	faelle.append({"name": "G1 Wurzelknie Doppel", "art": "doppel", "start": Vector2(-3.6, 4.6),
			"kante": -0.4, "von": -3.15, "landung": 0.3, "doppel_t": [0.25, 0.33],
			"pflicht": false})
	# G2: Die Nische rechts beginnt hinter L1 (78), die Bahn q 5,3 liegt
	# über der Bank. Der Slide beginnt am Start (Slide 2 m vor der Stelle
	# läge noch in L1); bis 84 trägt er, jede Stelle ist ein Slide-Sprung.
	# Gemessen trägt er bis 0,9 m vor der Stirn (Entwurf: 0,4 – dort ohne
	# Kisten und mit dem Slide 2 m vor dem Absprung), daher die Kante 81,1.
	faelle.append({"name": "G2 Bank Einzel", "art": "einfach", "start": Vector2(78.4, 5.3),
			"kante": 81.6, "von": 78.75, "landung": 82.3, "darf_nicht_tragen": true})
	faelle.append({"name": "G2 Bank Slide-Sprung", "art": "slide", "start": Vector2(78.4, 5.3),
			"kante": 81.1, "von": 78.85, "landung": 82.3, "pflicht": false})
	# Suhlgraben neben den Kisten (q −2): Landung erst auf der Gegenseite
	# zählt, nicht in der Sohle (0,8 tiefer). Entwurf: Slide-Sprung über
	# 4,6 m 1,25 m Fenster (Raster 0,05) – hier im Raster 0,25 ≥ 1,0.
	faelle.append({"name": "Suhlgraben Slide-Sprung", "art": "slide",
			"start": Vector2(19.2, -2.0), "kante": SUHLGRABEN.x, "von": 21.2,
			"landung": SUHLGRABEN.y, "tief_erlaubt": 0.4, "pflicht": false, "fenster_min": 1.0})
	# G3: hinter F2 auf den Trittstein (+1,2), dann vom Trittstein auf den
	# Sims (+1,4 darüber). Mit gehaltener Taste trägt ein Sprung auf den
	# 1,4 m kurzen Stein nur aus 2,7–4,9 m vor seiner Stirn (gerechnet), die
	# Kante also 2,7 m davor; vom Stein misst die Probe nur, ob der Sims
	# trägt (Landung höchstens 0,5 m unter dem Stein zählt).
	var stein: Dictionary = weg.begehbar("G3 Trittstein")
	var stein_s: float = stein["s"]
	var stein_vorn := stein_s - float((stein["groesse"] as Vector3).z) * 0.5
	faelle.append({"name": "G3 Trittstein", "art": "einfach", "start": Vector2(251.2, 3.4),
			"kante": stein_vorn - 2.7, "von": 251.45, "landung": stein_vorn + 0.1,
			"pflicht": false})
	faelle.append({"name": "G3 Sonnensims", "art": "einfach", "start": Vector2(stein_s - 0.5, 3.4),
			"ziel": Vector2(stein_s + 3.5, 4.9), "kante": stein_s, "von": stein_s - 0.25,
			"landung": stein_s + 1.6, "tief_erlaubt": 0.5, "pflicht": false})
	return faelle


## Stirnen der Durchlässe für den Spieltest-Bot (werkzeuge/spieltest.gd,
## Opt-in): Er tippt Slide davor – sonst liefe er hinein und stolperte.
func duckstellen() -> Array[float]:
	var liste: Array[float] = []
	for d: Dictionary in DURCHLAESSE:
		liste.append(float(d["s"]))
	return liste


## Lauflinie für den Spieltest-Bot (Opt-in): dieselbe wie die der
## Jagdprobe – in A rechts an den Kisten vorbei über die Grabenrampe, in der
## Findlingsgasse rechts an F1, links an F2 vorbei.
func lauflinie() -> Array[Vector2]:
	return JAGD_SPUR


## Zustand der Jagd für werkzeuge/jagdprobe.gd (`L05Jagd.zustand`).
func jagd_zustand() -> Dictionary:
	return jagd.zustand() if jagd != null else {}


## Fälle für werkzeuge/jagdprobe.gd (Entwurf §12 P1, §2.5; Schema im Kopf
## der Probe). Jeder Fall beginnt mit einem Tod: Die Probe setzt den
## Checkpoint, die Figur stirbt und erscheint dort – genau so stellt das
## Spiel den Keiler (L05Jagd.nach_tod).
##   Ideallauf     vom Start bis hinter das Wehr: kein Tod vor CP1, Abstand
##                 beim Wecken 15, Mindestabstand ≥ JAGD_IDEAL_MIN (Entwurf
##                 P1: 10; seit R2 rückt der Keiler im Nacken auf 8 bzw.
##                 7,5 m heran, L05Jagd, Kopf)
##   Ein Fehler    je einmal Stolpern an H1, D1, H2, D2 (Spiel-Jury R2,
##                 Mangel 3: „ein Fehler bleibt überall überlebbar"),
##                 Mindestabstand ≥ JAGD_FEHLER_MIN
##   Rastplatz s   Respawn: Keiler bei s − `L05Jagd.vorsprung_bei(s)`,
##                 Durchlässe dahinter heil, 3 s weiter ohne Tod; nur die
##                 Aktionen ab dem Rastplatz (die davor lösten sonst gleich
##                 nach dem Respawn aus – Spiel-Jury R1, Mangel 12)
##   Reaktion s    dasselbe, aber die Figur steht nach dem Respawn erst
##                 JAGD_REAKTION_RESPAWN s (Spiel-Jury R1, Mangel 5): Der
##                 Keiler wartet, bis sie sich regt (L05Jagd, RESPAWN_WARTEN)
##   Stehen        nach dem Respawn an CP2 stehen bleiben: gefangen – das
##                 Warten des Keilers ist begrenzt (Gegenprobe)
##   Krabbeln      an jedem Durchlass die Taste gehalten (gerechnet 6,5 m)
##   Stolpern      an D3 und D4 (gerechnet 5,4 m), dasselbe mit 0,3 s
##                 Zögern vor L5 (gerechnet 3,2 m)
##   Gegenprobe    D3 und D4 gestolpert, 1,2 s gezögert vor L5: gefangen
##                 (siehe JAGD_ZOEGERN_LANG)
##   Ufer          stehen bei 283,5: gefangen; über der Lücke bei 284,5:
##                 sicher, 1 s nachdem er am Ufer steht
##   Ziel          von CP5 ins Zielportal: einmal geschafft, er schnaubt
##                 weiter
func jagdfaelle() -> Array[Dictionary]:
	var anfang := to_global(LevelWerkzeuge.punkt(verlauf, START_S, 0.0, RASTPLATZ_UEBER))
	var ideal := _jagdlinie({})
	var faelle: Array[Dictionary] = [
		{"name": "Ideallauf", "checkpoint": anfang, "rastplatz": START_S, "aktionen": ideal,
				"spur": JAGD_SPUR, "ende_s": JAGD_ENDE_S, "erwartet": "ueberlebt",
				"min_abstand": JAGD_IDEAL_MIN,
				"weck_abstand": Vector2(L05Jagd.WECK_S - L05Jagd.SCHLAF_S, 0.2)},
	]
	var cp1: float = RASTPLAETZE[0]
	for name_f: String in ["H1", "D1 Wurzelbogen", "H2", "D2 Wurzelbogen"]:
		var fehler := _jagdlinie({name_f: "stolpern"})
		var stelle := 0.0
		for a: Dictionary in fehler:
			if String(a.get("wo", "")) == name_f:
				stelle = float(a["s"])
		faelle.append({"name": "Ein Fehler an %s" % name_f, "checkpoint": _rastplatz_ort(cp1),
				"rastplatz": cp1, "aktionen": _aktionen_ab(fehler, cp1), "spur": JAGD_SPUR,
				"ende_s": stelle + 18.0, "erwartet": "ueberlebt", "stolpern": 1,
				"min_abstand": JAGD_FEHLER_MIN})
	for s in RASTPLAETZE:
		var ab := _aktionen_ab(ideal, s)
		var start := Vector2(s - L05Jagd.vorsprung_bei(s), 0.1)
		faelle.append({"name": "Rastplatz %.0f" % s, "checkpoint": _rastplatz_ort(s),
				"rastplatz": s, "aktionen": ab, "spur": JAGD_SPUR, "ende_dauer": 3.0,
				"erwartet": "ueberlebt", "keiler_start": start})
		var reaktion: Array[Dictionary] = [{"s": s - 5.0, "tun": "warten",
				"dauer": JAGD_REAKTION_RESPAWN, "sofort": true, "wo": "Respawn"}]
		reaktion.append_array(ab)
		faelle.append({"name": "Reaktion %.1f s an %.0f" % [JAGD_REAKTION_RESPAWN, s],
				"checkpoint": _rastplatz_ort(s), "rastplatz": s, "aktionen": reaktion,
				"spur": JAGD_SPUR, "ende_dauer": 4.0, "erwartet": "ueberlebt",
				"keiler_start": start, "min_abstand": JAGD_REAKTION_MIN})
	var cp2: float = RASTPLAETZE[1]
	var stehen: Array[Dictionary] = [{"s": cp2 - 5.0, "tun": "stehen", "wo": "Respawn"}]
	faelle.append({"name": "Stehen nach dem Respawn an %.0f" % cp2,
			"checkpoint": _rastplatz_ort(cp2), "rastplatz": cp2, "aktionen": stehen,
			"spur": JAGD_SPUR, "ende_dauer": 6.0, "erwartet": "gefangen"})
	var halten := {}
	for d: Dictionary in DURCHLAESSE:
		halten[String(d["name"])] = "halten"
	faelle.append({"name": "Krabbeln an jedem Durchlass", "checkpoint": anfang,
			"rastplatz": START_S, "aktionen": _jagdlinie(halten), "spur": JAGD_SPUR,
			"ende_s": JAGD_ENDE_S, "erwartet": "ueberlebt"})
	var stolpern := {"D3 Fluderjoch": "stolpern", "D4 Fluderjoch": "stolpern"}
	faelle.append({"name": "Stolpern an D3 und D4", "checkpoint": anfang,
			"rastplatz": START_S, "aktionen": _jagdlinie(stolpern), "spur": JAGD_SPUR,
			"ende_s": JAGD_ENDE_S, "erwartet": "ueberlebt", "stolpern": 2})
	var zoegern := stolpern.duplicate()
	zoegern["L5 Mühlrinne"] = "zoegern"
	faelle.append({"name": "Stolpern D3, D4, Zögern L5", "checkpoint": anfang,
			"rastplatz": START_S, "aktionen": _jagdlinie(zoegern), "spur": JAGD_SPUR,
			"ende_s": JAGD_ENDE_S, "erwartet": "ueberlebt", "stolpern": 2})
	var drei := stolpern.duplicate()
	drei["L5 Mühlrinne"] = "zoegern_lang"
	faelle.append({"name": "Gegenprobe D3, D4, Zögern 1,2 s", "checkpoint": anfang,
			"rastplatz": START_S, "aktionen": _jagdlinie(drei), "spur": JAGD_SPUR,
			"ende_s": JAGD_ENDE_S, "erwartet": "gefangen", "stolpern": 2})
	var cp5: float = RASTPLAETZE[RASTPLAETZE.size() - 1]
	faelle.append({"name": "Ufer: Stand bei %.1f" % JAGD_STEHEN_S,
			"checkpoint": _rastplatz_ort(cp5), "rastplatz": cp5,
			"aktionen": _jagdlinie({"L6 Wehrbruch": "stehen"}), "spur": JAGD_SPUR,
			"ende_ufer": 1.0, "erwartet": "gefangen"})
	faelle.append({"name": "Ufer: über der Lücke bei %.1f" % JAGD_SCHWEBEN_S,
			"checkpoint": _rastplatz_ort(cp5), "rastplatz": cp5,
			"aktionen": _jagdlinie({"L6 Wehrbruch": "schweben"}), "spur": JAGD_SPUR,
			"ende_ufer": 1.0, "erwartet": "ueberlebt"})
	faelle.append({"name": "Ziel", "checkpoint": _rastplatz_ort(cp5), "rastplatz": cp5,
			"aktionen": ideal, "spur": JAGD_SPUR, "ende_ziel": 3.0, "erwartet": "ueberlebt"})
	return faelle


## Die Aktionen aus `aktionen`, die ab dem Rastplatz `s` liegen.
static func _aktionen_ab(aktionen: Array[Dictionary], s: float) -> Array[Dictionary]:
	var ab: Array[Dictionary] = []
	for a in aktionen:
		if float(a["s"]) >= s:
			ab.append(a)
	return ab


func _rastplatz_ort(s: float) -> Vector3:
	return to_global(weg_punkt(s, 0.0, RASTPLATZ_UEBER))


## Die Aktionen eines Laufs, nach `s` sortiert (Schema im Kopf der
## Jagdprobe). `abw` je Name eines Durchlasses "halten" oder "stolpern", je
## Hürde "stolpern" (hineinlaufen, nach der Reaktion springen), je Lücke
## "zoegern" oder "zoegern_lang", am Wehr "stehen" oder "schweben"; sonst
## der Ideallauf.
func _jagdlinie(abw: Dictionary) -> Array[Dictionary]:
	var aktionen: Array[Dictionary] = []
	for d: Dictionary in DURCHLAESSE:
		var name_d: String = d["name"]
		var stirn: float = d["s"]
		match String(abw.get(name_d, "")):
			"halten":
				aktionen.append({"s": stirn - JAGD_SLIDE_VOR, "tun": "slide_halten",
						"bis": stirn + JAGD_HALTEN_BIS, "wo": name_d})
			"stolpern":
				aktionen.append({"s": stirn - 3.0, "tun": "stolpern", "bis": stirn + 1.0,
						"reaktion": JAGD_REAKTION, "wo": name_d})
			_:
				aktionen.append({"s": stirn - JAGD_SLIDE_VOR, "tun": "slide", "wo": name_d})
	for h: Dictionary in HUERDEN:
		var name_h: String = h["name"]
		var vorn := float(h["s"]) - HUERDE_ZONE_LAENGE * 0.5
		if String(abw.get(name_h, "")) == "stolpern":
			aktionen.append({"s": vorn - 3.0, "tun": "stolpern", "bis": vorn + 1.0,
					"reaktion": JAGD_REAKTION, "danach": "sprung", "wo": name_h})
		else:
			aktionen.append({"s": vorn - JAGD_HUERDE_VOR, "tun": "sprung", "wo": name_h})
	for l: Dictionary in LUECKEN:
		var name_l: String = l["name"]
		var kante: float = l["von"]
		var art := String(abw.get(name_l, ""))
		if not JAGD_SPRUNG_VOR.has(name_l):
			# Das Wehr: Doppelsprung, oder davor stehen bleiben bzw. darüber
			# gehalten werden.
			match art:
				"stehen":
					aktionen.append({"s": JAGD_STEHEN_S, "tun": "stehen", "wo": name_l})
				"schweben":
					aktionen.append({"s": kante, "tun": "schweben", "an": JAGD_SCHWEBEN_S,
							"wo": name_l})
				_:
					aktionen.append({"s": JAGD_WEHR_SPRUNG, "tun": "doppel",
							"nach": JAGD_DOPPEL_NACH, "wo": name_l})
			continue
		if art == "zoegern" or art == "zoegern_lang":
			aktionen.append({"s": kante - JAGD_ZOEGERN_VOR, "tun": "warten",
					"dauer": JAGD_ZOEGERN if art == "zoegern" else JAGD_ZOEGERN_LANG,
					"wo": name_l})
		aktionen.append({"s": kante - float(JAGD_SPRUNG_VOR[name_l]), "tun": "sprung",
				"wo": name_l})
	aktionen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["s"]) < float(b["s"]))
	# Gehaltene Taste vor dem nächsten Slide loslassen (siehe JAGD_LOSLASSEN_VOR).
	for i in aktionen.size():
		if String(aktionen[i]["tun"]) != "slide_halten":
			continue
		for k in range(i + 1, aktionen.size()):
			if String(aktionen[k]["tun"]).begins_with("slide") or String(aktionen[k]["tun"]) == "stolpern":
				aktionen[i]["bis"] = minf(float(aktionen[i]["bis"]),
						float(aktionen[k]["s"]) - JAGD_LOSLASSEN_VOR)
				break
	return aktionen


## Freiraum über der Kamerabahn (Opt-in "freiraum" in level_check.gd;
## Entwurf §7.1 K1/K2 und §2.6). Mit `sicht_maske = 8` holt nichts auf
## Ebene 1 die Kamera heran – was in ihrer Bahn steht, sähe man also durch
## sie hindurch. Diese Probe ist die Wache dafür. Je Abweichung eine Zeile
## "ABWEICHUNG …", zuletzt "GEPRUEFT n" (n Stellen der Kamerabahn):
##   Kamera  an jeder Stelle 0–M_ENDE (alle 0,5 m) steht die Kamera
##           mindestens KAMERA_UEBER_FIGUR über der Figur:
##           hoehe − (Kurve(s) − Kurve(s − abstand))
##   K2      steht die Kamera über einem Durchlass (alle 0,2 m über seine
##           Tiefe), dann mindestens K2_MIN über seinem Boden:
##           hoehe + (Boden − Kurve)(s + abstand) − (Boden − Kurve)(s)
##   K1      kein sichtbares Netz hat einen Punkt über |q| ≤ K1_Q zwischen
##           K1_UNTEN und K1_OBEN über der Decke (0 ≤ s ≤ KURVE_ENDE). Die
##           Dreiecke werden im Raster K1_RASTER abgetastet; Kisten und
##           Früchte zählen mit ihrer Oberkante, Teilchen nicht.
##   K3      Gelände und Saum verdecken die Kronen der Eiche nicht
##           (`_freiraum_k3`).
##   K4      kein Stammfuß bei |q| < 8 (`_freiraum_k4`, Zählung des Walds).
##   K5      die Figur bleibt aus der Kamera zu sehen, wo es zählt: im
##           sauberen Slide-Fenster jedes Durchlasses und im Sprungfenster
##           jeder Hürde (`_freiraum_k5`).
## Werte aus der Kamera des Levels (`hoehe`, `abstand`).
func freiraumprobe() -> PackedStringArray:
	var zeilen := PackedStringArray()
	var kamera := _kamera as KorridorKamera
	var hoehe := kamera.hoehe if kamera != null else 5.6
	var abstand := kamera.abstand if kamera != null else -21.0
	var stellen := 0
	var tiefste := INF
	var s := 0.0
	while s <= M_ENDE + 0.001:
		var ueber := hoehe - (_kurve_y(s) - _kurve_y(s - abstand))
		tiefste = minf(tiefste, ueber)
		if ueber < KAMERA_UEBER_FIGUR:
			zeilen.append("ABWEICHUNG Kamera bei s %.1f nur %.2f m über der Figur (mindestens %.2f)"
					% [s, ueber, KAMERA_UEBER_FIGUR])
		stellen += 1
		s += 0.5
	var k2_tiefste := INF
	for d: Dictionary in DURCHLAESSE:
		var stirn: float = d["s"]
		var tiefe: float = d["tiefe"]
		var si := stirn
		while si <= stirn + tiefe + 0.001:
			var ueber := hoehe + _ueber_kurve(si + abstand) - _ueber_kurve(si)
			k2_tiefste = minf(k2_tiefste, ueber)
			if ueber < K2_MIN:
				zeilen.append("ABWEICHUNG K2 %s: Kamera bei s %.1f nur %.2f m über dem Boden (mindestens %.1f)"
						% [String(d["name"]), si, ueber, K2_MIN])
			stellen += 1
			si += 0.2
	var k1 := _freiraum_k1()
	zeilen.append_array(k1["zeilen"] as PackedStringArray)
	print("  Freiraum: Kamera mindestens %.3f m über der Figur, über Durchlässen mindestens %.2f m; K1 %d Netze, %d Punkte, %d Objekte"
			% [tiefste, k2_tiefste, int(k1["netze"]), int(k1["punkte"]), int(k1["objekte"])])
	var k3 := _freiraum_k3(hoehe, abstand)
	zeilen.append_array(k3["zeilen"] as PackedStringArray)
	stellen += int(k3["stellen"])
	zeilen.append_array(_freiraum_k4())
	var k5 := _freiraum_k5(hoehe, abstand)
	zeilen.append_array(k5["zeilen"] as PackedStringArray)
	stellen += int(k5["stellen"])
	zeilen.append("GEPRUEFT %d" % stellen)
	return zeilen


## K5 (Spiel-Jury R1, Mangel 1; Bild-Jury R1, Mangel 1): Sieht die Kamera
## die Figur, wenn der Spieler entscheiden muss? Fenster: das saubere
## Slide-Fenster jedes Durchlasses (K5_DUCK vor der Stirn, Sprungprobe) und
## das Sprungfenster jeder Hürde (K5_HUERDE vor ihrer Zone). An jeder Stelle
## (alle K5_SCHRITT m) Strecken von der eingeschwungenen Kamera (Kurve bei
## s − abstand, `hoehe` darüber, Mitte des Weges) zu den Punkten K5_PUNKTE
## der Figur (q, Höhe über der Decke) gegen die Dreiecke der heilen Optik
## ALLER Durchlässe – durch D4 schaut man beim Anlauf auf D3. Ein Treffer
## zählt nicht, wo die Nahblende ihn zu mehr als der Hälfte ausdünnt
## (`L05Wegbauten.NAH_ABSTAND`, `NAH_HOEHE`, Höhe im Rahmen des
## Durchlasses). Getestet werden nur Dreiecke, die über |x| ≤ K5_QUER im
## Rahmen ihres Durchlasses reichen (die Strecken laufen über der Mitte).
## ABWEICHUNG, wenn die Brust (Punkte mit Höhe 0,7) in einem Fenster an
## weniger als K5_BRUST_MIN der Stellen frei ist.
func _freiraum_k5(hoehe: float, abstand: float) -> Dictionary:
	var zeilen := PackedStringArray()
	var optiken: Array[Dictionary] = []
	for i in durchlass_koerper.size():
		var koerper := durchlass_koerper[i]
		if not is_instance_valid(koerper):
			continue
		var optik := koerper.get_node_or_null("Optik") as MeshInstance3D
		if optik == null or optik.mesh == null:
			continue
		var lage := global_transform.affine_inverse() * optik.global_transform
		var dreiecke := PackedVector3Array()
		var faces := optik.mesh.get_faces()
		for k in range(0, faces.size() - 2, 3):
			var a := faces[k]
			var b := faces[k + 1]
			var c := faces[k + 2]
			if minf(a.x, minf(b.x, c.x)) > K5_QUER or maxf(a.x, maxf(b.x, c.x)) < -K5_QUER:
				continue
			dreiecke.append(lage * a)
			dreiecke.append(lage * b)
			dreiecke.append(lage * c)
		optiken.append({"s": float(DURCHLAESSE[i]["s"]), "dreiecke": dreiecke,
				"innen": lage.affine_inverse()})
	var fenster: Array[Dictionary] = []
	for d: Dictionary in DURCHLAESSE:
		var stirn: float = d["s"]
		fenster.append({"name": String(d["name"]), "von": stirn - K5_DUCK.x, "bis": stirn - K5_DUCK.y})
	for h: Dictionary in HUERDEN:
		var vorn := float(h["s"]) - HUERDE_ZONE_LAENGE * 0.5
		fenster.append({"name": String(h["name"]), "von": vorn - K5_HUERDE.x,
				"bis": vorn - K5_HUERDE.y})
	var stellen := 0
	for f in fenster:
		var frei := {}
		var gesamt := {}
		var si: float = f["von"]
		while si <= float(f["bis"]) + 0.001:
			var auge := verlauf.sample_baked(clampf(si - abstand, 0.0, verlauf.get_baked_length()))
			auge.y += hoehe
			for p: Vector2 in K5_PUNKTE:
				var ziel := weg_punkt(si, p.x, p.y)
				var schluessel := "%.2f" % p.y
				gesamt[schluessel] = int(gesamt.get(schluessel, 0)) + 1
				if _k5_frei(auge, ziel, si, abstand, optiken):
					frei[schluessel] = int(frei.get(schluessel, 0)) + 1
			stellen += 1
			si += K5_SCHRITT
		var teile := PackedStringArray()
		for schluessel: String in gesamt:
			var anteil := float(frei.get(schluessel, 0)) / float(gesamt[schluessel])
			teile.append("%s m %.0f %%" % [schluessel.replace(".", ","), anteil * 100.0])
			if schluessel == "0.70" and anteil < K5_BRUST_MIN:
				zeilen.append("ABWEICHUNG K5 %s: Brust nur zu %.0f %% frei (mindestens %.0f %%)"
						% [String(f["name"]), anteil * 100.0, K5_BRUST_MIN * 100.0])
		print("  Freiraum K5 %-16s s %.2f–%.2f: frei %s" % [String(f["name"]), float(f["von"]),
				float(f["bis"]), ", ".join(teile)])
	return {"zeilen": zeilen, "stellen": stellen}


## Ist die Strecke Kamera → Figur frei (siehe `_freiraum_k5`)? Getestet
## werden nur Durchlässe zwischen Figur und Kamera.
func _k5_frei(auge: Vector3, ziel: Vector3, s: float, abstand: float,
		optiken: Array[Dictionary]) -> bool:
	for o in optiken:
		var os: float = o["s"]
		if os < s - 3.0 or os > s - abstand + 1.0:
			continue
		var dreiecke: PackedVector3Array = o["dreiecke"]
		var innen: Transform3D = o["innen"]
		for k in range(0, dreiecke.size() - 2, 3):
			var treffer: Variant = Geometry3D.segment_intersects_triangle(auge, ziel,
					dreiecke[k], dreiecke[k + 1], dreiecke[k + 2])
			if treffer == null:
				continue
			var p: Vector3 = treffer
			var sicht := maxf(smoothstep(L05Wegbauten.NAH_ABSTAND.x, L05Wegbauten.NAH_ABSTAND.y,
					p.distance_to(auge)), 1.0 - smoothstep(L05Wegbauten.NAH_HOEHE.x,
					L05Wegbauten.NAH_HOEHE.y, (innen * p).y))
			if sicht >= 0.5:
				return false
	return true


## K4 (Entwurf §7.1, Paket P7): kein Stammfuß bei |q| < 8 – gezählt vom
## Wald beim Bau (`L05Wald.zahlen`); die Baumtore zählen getrennt. Die
## Kegel K3 für Bäume prüft der Waldrahmen beim Pflanzen.
func _freiraum_k4() -> PackedStringArray:
	var zeilen := PackedStringArray()
	if wald == null or not wald.zahlen.has("staemme_q8"):
		return zeilen
	var n := int(wald.zahlen["staemme_q8"])
	print("  Freiraum K4: %d Stammfüße, davon %d bei |q| < %.0f; Baumtore %d, davon %d bei |q| < %.0f; Kronen im Kegel K3 abgewiesen: %d"
			% [int(wald.zahlen.get("staemme", 0)), n, L05Wald.K4_Q, wald.tor_fuesse.size(),
				int(wald.zahlen.get("tore_q8", 0)), L05Wald.K4_Q, int(wald.zahlen.get("nein_kegel", 0))])
	if n > 0:
		zeilen.append("ABWEICHUNG K4: %d Stammfüße bei |q| < %.0f" % [n, L05Wald.K4_Q])
	return zeilen


## K3 (siehe `freiraumprobe`): Verdecken Gelände oder Saum die Kronen der
## Eiche? Getestet gegen `L05Gelaende.sicht_oberkante` (gezeichnetes Feld,
## Kronen der Böschungen). Ziele sind die gebauten Kronen: Mitte der Hülle
## und die Probepunkte im Laub aus `wahrzeichen` (wie die
## Wahrzeichenprobe). Erst ohne gebaute Eiche die Kronen des Entwurfs aus
## EICHE (Mitte und vier Punkte auf K3_RAND des Radius). Die Bäume (Paket
## P7) prüft der Waldrahmen mit seinem Kegel. Ohne Gelände: nichts zu
## prüfen.
func _freiraum_k3(hoehe: float, abstand: float) -> Dictionary:
	var zeilen := PackedStringArray()
	if gelaende == null:
		return {"zeilen": zeilen, "stellen": 0}
	var ziele: Array[Vector3] = []
	var radien: Array[float] = []
	for e: Dictionary in wahrzeichen():
		if not String(e["name"]).begins_with("Krone"):
			continue
		var radius: float = e["radius"]
		ziele.append(e["mitte"] as Vector3)
		radien.append(radius)
		for p: Vector3 in e["punkte"]:
			ziele.append(p)
			radien.append(radius)
	if ziele.is_empty():
		var eiche_s: float = EICHE["s"]
		var kronen: Array = EICHE["kronen"]
		for k: Vector3 in kronen:
			var mitte := LevelWerkzeuge.punkt_frei(verlauf, eiche_s, k.x)
			mitte.y = k.y
			var r := k.z * K3_RAND
			for d: Vector3 in [Vector3.ZERO, Vector3(r, 0.0, 0.0), Vector3(-r, 0.0, 0.0),
					Vector3(0.0, r, 0.0), Vector3(0.0, -r, 0.0)]:
				ziele.append(mitte + d)
				radien.append(k.z)
	var stellen := 0
	var verdeckt := 0
	var knappste := INF
	var s := K3_VON
	while s <= M_ENDE + 0.001:
		var auge := verlauf.sample_baked(clampf(s - abstand, 0.0, verlauf.get_baked_length()))
		auge.y += hoehe
		for i in ziele.size():
			var strahl := ziele[i] - auge
			var bis := strahl.length() - K3_VOR * radien[i]
			var richtung := strahl.normalized()
			var t := K3_TAKT
			var frei := true
			while t < bis:
				var p := auge + richtung * t
				var luft := p.y - gelaende.sicht_oberkante(p.x, p.z)
				knappste = minf(knappste, luft)
				if luft < 0.0:
					frei = false
					break
				t += K3_TAKT
			if not frei:
				verdeckt += 1
				zeilen.append("ABWEICHUNG K3 bei s %.1f: Strahl %d zur Eichenkrone verdeckt" % [s, i])
		stellen += 1
		s += K3_SCHRITT
	print("  Freiraum K3: %d Stellen, %d Strahlen je Stelle, %d verdeckt, knappster Abstand %.2f m"
			% [stellen, ziele.size(), verdeckt, knappste])
	return {"zeilen": zeilen, "stellen": stellen}


## K1 (siehe `freiraumprobe`): je Netz eine Zeile mit der Spanne, in der es
## in den freien Raum ragt.
func _freiraum_k1() -> Dictionary:
	var funde := {}
	var netze := 0
	var punkte := 0
	var objekte_n := 0
	var laenge := verlauf.get_baked_length()
	for wurzel: Node in [geometrie, deko, objekte]:
		for knoten in wurzel.find_children("*", "GeometryInstance3D", true, false):
			var g := knoten as GeometryInstance3D
			if not g.is_visible_in_tree() or _k1_spielobjekt(g) != null:
				continue
			# Die Eiche steht vor dem Kurvenanfang, wo K1 nichts prüft
			# (`_k1_pruefen`: s ≤ 0) – ihre Dreiecke nur abzutasten, hieße
			# Zeit und änderte die Zählung im Protokoll.
			if eiche != null and eiche.wurzel != null and eiche.wurzel.is_ancestor_of(g):
				continue
			var dreiecke := PackedVector3Array()
			if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
				var faces := (g as MeshInstance3D).mesh.get_faces()
				for p in faces:
					dreiecke.append(to_local(g.global_transform * p))
			elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
				var mm := (g as MultiMeshInstance3D).multimesh
				if mm.mesh == null:
					continue
				var faces := mm.mesh.get_faces()
				for k in mm.instance_count:
					var lage := g.global_transform * mm.get_instance_transform(k)
					for p in faces:
						dreiecke.append(to_local(lage * p))
			else:
				continue
			netze += 1
			for i in range(0, dreiecke.size() - 2, 3):
				var a := dreiecke[i]
				var b := dreiecke[i + 1]
				var c := dreiecke[i + 2]
				var schwer := (a + b + c) / 3.0
				var umkreis := maxf(schwer.distance_to(a), maxf(schwer.distance_to(b),
						schwer.distance_to(c)))
				var naechst := verlauf.sample_baked(verlauf.get_closest_offset(schwer))
				if schwer.distance_to(naechst) - umkreis > K1_WEIT:
					continue
				for p in _dreieck_raster(a, b, c):
					punkte += 1
					_k1_pruefen(p, String(g.name), laenge, funde)
	# Kisten und Früchte mit ihrer Oberkante (ein Punkt je Objekt).
	for kind in objekte.get_children():
		if kind is Kiste:
			objekte_n += 1
			_k1_pruefen((kind as Node3D).position + Vector3.UP * 0.5, "Kiste", laenge, funde)
		elif kind is Frucht:
			objekte_n += 1
			_k1_pruefen((kind as Node3D).position + Vector3.UP * 0.35, "Frucht", laenge, funde)
	var zeilen := PackedStringArray()
	for name_f: String in funde:
		var f: Vector3 = funde[name_f]
		zeilen.append("ABWEICHUNG K1 %s bei s %.1f–%.1f: bis %.2f m über dem Weg (frei %.1f–%.1f über |q| ≤ %.1f)"
				% [name_f, f.x, f.y, f.z, K1_UNTEN, K1_OBEN, K1_Q])
	return {"zeilen": zeilen, "netze": netze, "punkte": punkte, "objekte": objekte_n}


## Kiste oder Frucht, zu der ein Netz gehört (die zählen über ihre Lage).
func _k1_spielobjekt(knoten: Node) -> Node:
	var n := knoten
	while n != null and n != objekte:
		if n is Kiste or n is Frucht:
			return n
		n = n.get_parent()
	return null


## Punkte eines Dreiecks, höchstens K1_RASTER auseinander, dazu der
## Schwerpunkt.
static func _dreieck_raster(a: Vector3, b: Vector3, c: Vector3) -> PackedVector3Array:
	var laengste := maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a)))
	var n := maxi(ceili(laengste / K1_RASTER), 1)
	var liste := PackedVector3Array()
	for i in n + 1:
		for j in n + 1 - i:
			liste.append(a + (b - a) * (float(i) / float(n)) + (c - a) * (float(j) / float(n)))
	liste.append((a + b + c) / 3.0)
	return liste


## Liegt `p` (Level-Koordinaten) im freien Raum K1? Funde je Name als
## Vector3(s von, s bis, größte Höhe).
func _k1_pruefen(p: Vector3, name_: String, laenge: float, funde: Dictionary) -> void:
	var s := verlauf.get_closest_offset(p)
	if s <= 0.001 or s >= laenge - 0.001:
		return
	var mitte := verlauf.sample_baked(s)
	var quer := Vector2(p.x - mitte.x, p.z - mitte.z).length()
	if quer > K1_Q:
		return
	var h := p.y - boden_bei(s)
	if h <= K1_UNTEN or h >= K1_OBEN:
		return
	if funde.has(name_):
		var f: Vector3 = funde[name_]
		funde[name_] = Vector3(minf(f.x, s), maxf(f.y, s), maxf(f.z, h))
	else:
		funde[name_] = Vector3(s, s, h)
