# Werkzeuge jenseits des geraden Korridors: Kamera, 2D, Ebenen, Sprungmaße (HEAD 93b8816)

Im Repo ist nichts geändert (`git status` leer). Zwei Dinge habe ich nur in einer Kopie im Scratchpad gemacht: eine Probe, die headless durch die Kamerazonen läuft (`…/scratchpad/kamprobe/kopie/werkzeuge/kamzonenprobe.gd`, in einer Kopie von kopie_r4), und eine Sprungsimulation nach der Reihenfolge in player.gd (`…/scratchpad/kamprobe/sprung.py`). Gerendert habe ich nichts.

## 0. Geprüfte Befunde vorweg

**F1 – Die Kamerazone fällt an jeder 12-m-Naht aus.**
- `kamerazone()` legt Stücke von 12 m an: Betreten schaltet auf Seitenansicht, Verlassen auf `_kamera_normal` (korridor_level.gd:928-943, 959-967).
- Die Kapsel (Radius 0,38 m) steckt an der Naht in zwei Stücken zugleich. Das Verlassen des alten Stücks kommt nach dem Betreten des neuen und setzt `seitenblick` auf 0.
- Gemessen in L10 (Zone 78–172): Seitenansicht nur bei s 76,8–91,0. Danach geht sie an jeder Naht nur 0,7–1,6 m lang an, `_seiten_grad` erreicht höchstens 0,29.
- Gemessen in L02 (Zone 98–152): Seitenansicht nur bei s 98,0–110,7.
- Alle Zonen mit kamerazone sind länger als 12 m und deshalb betroffen: L02, L10, L11, L12, L14, L24.
- `Stimmungszone` hat dasselbe Problem schon gelöst („zuletzt betretene Zone führt“, stimmungszone.gd:129-141). Das habe ich nur im Code gelesen, nicht gemessen.

**F2 – Die Seitenkamera in L02 steht 4,1 m statt 15 m neben der Figur.**
- Der Kamerastrahl prüft die Ebenen 1|8 (corridor_camera.gd:334). Er trifft die nahe Leitwand auf Ebene 1 (level02.gd:173-175, Abstand 4,1 m) und holt die Kamera heran.
- Gemessen bei s 106,6: 4,1 m Abstand, quer −3,6 m.
- L10 hat dort keine Leitwand und zeigt die gewollten 17,0 m.

**F3 – Die Werkstatt prüft keinen Streckenverlauf.**
- Die Kurve liegt durchgehend auf y 0 (werkstatt.gd:80-99).
- Es gibt keine Kamerazone, keine Terrasse, keine Stufe und kein Stockwerk. Die Stationen 1–29 sind nur einzelne Bauteile.

**Zur Einzigartigkeit (Nutzerwunsch):** L04 und L05 haben fast dieselben Stützpunkte, einen U-Bogen, der um 6 m steigt (level04.gd:95, level05.gd:110). L02 ist ein ähnlicher Haken mit 14 m Anstieg (level02.gd:135).

## 1. Kameramodi und Übergänge

| Modus | Auslöser | Überblendung | Grenzen |
|---|---|---|---|
| Verfolger am Pfad | Normalfall: Path3D „Verlauf“ (level_basis.gd:92-96, 403-415). Werte stehen in der .tscn: Vorgabe 6,0/9,5/6,0 (`hoehe`/`abstand`/`blick_vorlauf`), L04 6,4/12,5/9,0 | Ort exponentiell geglättet (corridor_camera.gd:458). Höhe träge über `hoehe_folge` 2,6 (:61, :392-397). Stelle auf der Kurve höchstens 26 m/s (:350-363) | Das Blickziel wird nicht geglättet (:438-443, :461). Wer `abstand`/`hoehe`/`vorlauf` zur Laufzeit ändert, erzeugt einen Blicksprung (aus dem Code abgeleitet) |
| Rückblick / Front | Nur für ein ganzes Level, über negatives `abstand`/`blick_vorlauf` (Level05.tscn:64-67: −21/−5) | – | Kein Wechsel mitten im Level. Ein Vorzeichenwechsel fährt die Kamera geradlinig über die Figur, der Blick springt um 180° (abgeleitet, ungeprüft). Die Frontansicht fehlt laut Doku ganz (level-vorbilder.md:83-85, 1013-1015) |
| Seitenansicht (2D) | `kamerazone(von, bis, seitlich, hoehe)` (korridor_level.gd:926-956) | Beide Ansichten werden immer gerechnet und mit smoothstep gemischt, 1/1,6 ≈ 0,63 s (corridor_camera.gd:399-411, 445-446) | Siehe Liste darunter |
| Senkrecht | Kein eigener Modus. L10 löst es mit steiler Kurve, Hebebühnen (`wehrbohle`) und Kisten (level10.gd:202-251) | Höhe nur über `hoehe_folge` | Die Tangente wird waagerecht gerechnet (level_werkzeuge.gd:34-41, corridor_camera.gd:417-420). Ein exakt senkrechtes Kurvenstück fällt auf FORWARD zurück |
| Gerade ohne Pfad | `kurve_pfad` leer (:447-450) | – | Der Bonusraum (L18) hängt die Kamera beim Versetzen um, ein harter Schnitt (bonusraum.gd:666-686) |
| Frei | FolgeKamera im Hub (fester Weltversatz, folge_kamera.gd:13, 84-106), Flugkamera in L22 | – | Eigene Kamerasysteme. Innerhalb eines Levels ist kein Wechsel zwischen Kamera-Knoten vorgesehen |

**Grenzen der Seitenansicht:**
- 2D gibt es nur entlang der Kurve: Die Kamera steht quer zur Tangente an der geführten Stelle (:413-426). Kurven drehen das Bild, deshalb ist die L10-Galerie schnurgerade (level10.gd:105-107).
- Negatives `seitlich` heißt: Im Bild läuft man von rechts nach links (aus :421/:424 abgeleitet). L02, L10, L11 und L14 nutzen negative Werte, L12 und L24 positive.
- Die nahe Wand wird nur bei `Schluchtwand` ausgeblendet (:971-977), nicht bei den L01-Bauteilen (GelaendeSaum, Waldsetzer).
- Die Steuerung bleibt kamerarelativ (player.gd:682-701). Stick hoch heißt in 2D „in die Tiefe“, eine Tiefensperre gibt es nicht. Die einzige Absicherung ist die Regel „alles bei seitlich 0“ (level10.gd:23-26).
- Wer beim Eintritt „vor“ hält, läuft nach der Kameradrehung quer zum Weg (abgeleitet, ungeprüft).

**Was für Kamerawechsel mitten im Level fehlt:**
1. F1 beheben. Möglich sind: Zähler oder „zuletzt betretene führt“, eine einzelne Prisma-Zone wie bei `todeszone` (level_werkzeuge.gd:1147-1177), oder Umschalten über die Strecke s statt über Area3D.
2. Ein Kameraprofil je Abschnitt (`abstand`, `hoehe`, `vorlauf`, `seiten_faktor`, `fov`, `seitenblick`), das auch das Blickziel überblendet. Heute blendet nur `seitenblick`.
3. In 2D-Abschnitten die nahen Grenzen auf Ebene 16 statt 1 legen, sonst tritt F2 auf. Dazu nahe Kulisse der L01-Bauweise ausblenden können.
4. Die Eingaberichtung während des Wechsels festhalten, bis der Stick losgelassen wird. Optional eine Tiefensperre in 2D.
5. Prüfwerkzeuge erweitern:
   - Die Sichtprobe rechnet nur den Verfolger (level_check.gd:712-718).
   - Der Rundgang wärmt nur Verfolgerblicke mit ±40° vor (rundgang.gd:146-165). Ob fehlende Seitenblicke ruckeln, ist ungeprüft.
   - Der Werkstatt fehlt eine Station für den Verlauf (F3).
6. Nicht vorhanden: Rückblick als Abschnitt, Draufsicht, feste Kamerapunkte.

## 2. Bauteil-Katalog

Angabe je Bauteil: Name, Zweck, Kernparameter und Level, in denen es benutzt wird (per grep; W = Werkstatt).

**Verlauf, Boden, Höhe**
- `LevelWerkzeuge.kurve_aus_punkten(punkte, glaettung=0.45)` (level_werkzeuge.gd:493-502): Kurve aus Stützpunkten, in allen Leveln.
- `punkt`, `punkt_frei`, `richtung`, `drehung` (:24-70): Platzierung relativ zu (s, q, h).
- `korridor(abschnitte {von, bis, breite, breite_ende}, stoffe, optionen)` (:72-154): Lücken entstehen als Abstand zwischen den Einträgen.
  - Wahlweise `hoehe`/`hoehe_ende` (Terrasse auf fester Welthöhe), `nur_decke`, `stufen_kollision`, `ebene` (:85-101).
  - Terrassen und Stufen nutzt bisher nur L01.
- `plattform(s, q, h, größe, stoff)` (korridor_level.gd:100-104): L02, 07, 08, 10–16, 18–21, 23–25.
- Kisten als Treppe oder Aufzug: `kiste(EISEN/SPRUNG/FEDER, …, schwebt=true)` (:689-698), in L10 als Kistenstiege.
- `wehrbohle(s, q, oben, unten, phase, …)` (:161-178): Hebebühne, L03, 09, 10, 12, 23, 24, W.
- `hangelgitter(s, q, hoehe=3.2, laenge, breite)` (:607-616): L08, 10, 25, W.
- `Bonusraum.einbauen`: Raum weit abseits (z 640) im selben Baum, Wechsel durch Versetzen (bonusraum.gd:89). Nur L18.
- Wegverzweigung: L21 mit Galerie auf 3,6 m (level21.gd:547-570). Kein allgemeines Bauteil.
- L01-Datenbauweise: ABSCHNITTE, LUECKEN, BEGEHBARES, LEITLINIEN, RAENDER plus `boden_bei`, `breite_bei`, `weg_punkt` (level01.gd:116, 198, 1391-1460). Nur L01, das von LevelBasis erbt und nicht von KorridorLevel.

**Begrenzung, Tod, Sicht**
- `absturzzonen(schritt, breite)`: relativ zur Kurve (korridor_level.gd:835-851). Regel für Stockwerke in :819-834.
- `LevelWerkzeuge.todeszone(von, bis, q_von, q_bis, oben_y, …)`: auf fester Welthöhe (:1147-1177). Nur L01.
- `leitwand(…, ebene=1)` (:1022-1050): L02, 05, 12, 16, 17, 19–21, 23.
- `leitlinie(punkte_sq, …, ebene)` auf Ebene 16 = Spielergrenze (:1057-1140). Nur L01.
- `torbogen` mit Sichtsperre auf Ebene 8 (:22, :1234ff); dazu `schluchtwand`, `sims`, `luecken_markieren`.

**Kamera und Stimmung**
- `kamerazone`: L02, 10, 11, 12, 14, 24 (F1).
- `stimmung(von, bis, nebelfarbe, …)` in 14-m-Stücken (:624-644), relative Werte in stimmungszone.gd:35-51. Benutzt in 08, 09, 11–16, 18–21, 23–25.
- `horizont`: 07–25, W.
- `dunkelheit`: nur 23.

**Fahrt und bewegte Böden**
- `floss(von, bis, q, h, größe, fahrzeit, pause_a, pause_b, phase)` (:120-140): L03, 09, 24, 25.
- `seerose`: L03, 09. `treibmine`: L03, 23.
- `drehscheibe`, `laufband`, `schiebeblock`: Räume 2–5 und W.

**Taktgefahren**
- `bruchplatte(n_reihe)`, `taktwelle`, `feuerspeier`, `laserzaun`, `rollbrocken`, `ausloeseplatte`, `schliesstuer`, `stacheln`, `stachelbalken` (Krabbeln: Kapsel 1,30 m aufrecht, 0,76 m flach).

**Gegner**
- `gegner()` klemmt Position und Weite auf den Weg (:722-751). Dazu `werfer`, `schwarm`, `deckungsfleck(am_weg)`.
- Keiler (L05) ist kein Gegner mit Trefferzone, sondern ein Abstand auf der Kurve.

**Kistenarten** (kiste.gd:24-38): NORMAL, FRUCHT_MEHRFACH, LEBEN, FEDER, SPRUNG, TNT, NITRO, EISEN, CHECKPOINT, SCHUTZ, UMRISS, AUSLOESER, ZEIT.

## 3. Sprungmaße

Grundlage: Physik mit 60 Hz (keine Angabe in project.godot, also Vorgabe; Kommentar :112), semi-implizit gerechnet: `vel.y += G·dt` kommt vor `move_and_slide` (player.gd:279-290). Dadurch liegen die echten Werte 0,1–0,2 m unter der Formel v²/2g. Die L21-Rechnung (level21.gd:557-563) und die Hangel-Doku benutzen die Formelwerte.

**Scheitelhöhe der Füße (Formelwert in Klammern):**
- Einfachsprung: 1,86 m (1,96)
- Doppelsprung im Scheitel: 3,22 m (3,41)
- Slide-Sprung: 2,65 m (2,77)
- Slide-Sprung plus Doppelsprung: 4,01 m (4,22)
- Federkiste 15 m/s: 2,84 m; Abprall vom Gegner 16 m/s: 3,24 m; Sprungfeder 20 m/s: 5,10 m (danach ist ein Doppelsprung möglich, player.gd:395)
- Kleinster Hopser: 0,54 m

**Weite Mittelpunkt zu Mittelpunkt** (voller Anlauf, Taste gehalten; Δh = Ziel minus Absprung, Werte in Metern):

| Δh | Einfach | mit Doppelsprung (bestes Timing) | Slide-Sprung | Slide-Sprung mit Doppelsprung |
|---|---|---|---|---|
| −4 | 6,08 | 10,15 | 6,83 | 10,98 |
| −2 | 5,35 | 9,24 | 6,16 | 10,12 |
| 0 | 4,38 (0,63 s) | 8,13 (1,16 s) | 5,31 (0,75 s) | 9,11 (1,29 s) |
| +1 | 3,69 | 7,41 | 4,76 | 8,50 |
| +1,5 | 3,16 | 6,90 | 4,42 | 8,16 |
| +1,9 | – | 6,67 | 4,09 | 7,82 |
| +3,0 | – | 5,14 | – | 6,85 |
| +3,4 | – | – | – | 6,34 |

- Der weiteste Doppelsprung kommt spät im Fall, nicht im Scheitel. Flach mit Doppelsprung im Scheitel sind es nur 7,08 m.
- Bauchplatscher: `vel.y` wird auf −30 gesetzt, die Schwerkraft wirkt weiter. Aus 1,96 m dauert der Fall 0,067 s, aus 3,41 m 0,117 s, aus 6 m 0,183 s.
- Slide am Boden: 25 Bilder lang, 5,77 m weit.

**Abgleich mit player.gd:**
- **Luftkontrolle:** In der Luft gilt immer genau Eingabe × 6,97 m/s, ohne Trägheit (:189-209).
- **Slide-Sprung:** Er trägt waagerecht nicht 13,5 m/s weiter, denn `sliding` wird beim Absprung auf 0 gesetzt (:244). Mehr Weite kommt nur aus der längeren Flugzeit.
- **Slide über die Kante:** Der Slide läuft mit 13,5 m/s weiter, bis die 0,42 s um sind (:191-194). Danach gibt es weder Sprung noch Doppelsprung.
- **Coyote-Zeit:** keine. Gesprungen wird nur, wenn `is_on_floor()` am Anfang des Bildes gilt (:167, :240). Wer über eine Kante läuft, hat danach keinen Sprung und keinen Doppelsprung (`can_djump` wird am Boden auf false gesetzt, :301).
- **Sprungpuffer:** keiner (`just_pressed`, InputHub.gd:103-104).
- **Slide-Richtung:** beim Start eingefroren und kamerarelativ (:220). Loslassen der Taste kappt auf 5,49 m/s (:261-263).
- **Bauchplatscher:** Die waagerechte Steuerung bleibt aktiv, obwohl CLAUDE.md „senkrecht runter“ sagt (:189-209 vor :222-229).
- **Todeshöhe:** −12 Welt-Y (:28, :308). Ein Verlauf darf nicht tiefer führen.

**werkzeuge/sprungprobe.gd – was sie misst:**
- Sie läuft nur für Level, die `sprungfaelle()` liefern: je Fall `{name, start Vector2(s,q), kante, von, ziel?, landung?}` (:34-50). `pruefe.sh` ruft sie für jedes Level auf (pruefe.sh:116-129).
- Die echte Figur läuft mit vollem Tempo an, Taste und Richtung gehalten, ohne Doppelsprung (:166). Abgesprungen wird an Stellen von `von` bis zur Kante im Abstand von 0,25 m, dazu einmal 0,25 m hinter der Kante.
- Fehler gibt es, wenn der Absprung an der Kante nicht trägt oder das Fenster kürzer als 1,25 m ist (:24-29, :139-158).
- Eine Landung mehr als 1,5 m unter dem Absprung zählt als Sturz (:55, :208).
- Eichung aus pruefe_r9.log (L01): Kerbe 3,0 m und −0,17 m ergibt ein Fenster von 2,0 m; G1 3,0 m und +0,51 m genau 1,25 m (an der Grenze). Daraus abgeleitet: flache Pflichtlücken höchstens etwa 3,7 m, mit +0,5 m höchstens 3,0 m.

**So sichert man die Pflichtsprünge eines neuen Verlaufs ab:**
- Die Fälle aus den Lückendaten ableiten, wie L01 es tut (level01.gd:1310-1367, `LANDUNG_SPIEL` 0,45 in :1295).
- Je Bahn einen Fall mit eigenem q anlegen; Diagonalen über `ziel`.

**Grenzen der Probe:**
- Keine Fälle für Doppelsprung, Slide-Sprung, Feder, Gitter oder Floß. Dafür bräuchte jeder Fall ein Feld „art“.
- Sprünge nach unten über 1,5 m enden immer als Sturz.
- s kommt aus `get_closest_offset`; bei übereinanderliegenden Ebenen ist das mehrdeutig.

## 4. Reiter, Floß und Keiler mit Höhe, Kamerawechsel und 2D

**Reiter (L04)**
- **Höhe:** Er klebt auf der Kurve (reiter.gd:455-459). Gesprungen wird relativ zur Kurve; eine Landung über einer Lücke ist der Tod, Boden gibt es nur über `boden_pruefer(s)` (:297-326, :472; level04.gd:395-397).
  - Möglich sind also nur Rampen in der Kurve: keine Stufen, keine Plattformen, keine zweite Ebene.
  - Nötig wäre eine Bodenhöhe aus einem Strahl oder aus `boden_hoehe(s,q)` sowie `boden_pruefer(s,q)`.
- **Kamerawechsel:** funktioniert technisch. Er liegt auf Ebene 2 (:160-166), die Zonen fassen ihn.
- **2D:** Die Lenkung liest den rohen Stick-x-Wert (:257) und ist nicht kamerarelativ. In der Seitenansicht lenkt Stick rechts deshalb in die Tiefe. Nötig wäre, die Lenkung in 2D zu sperren oder auf Stick-y umzulegen.

**Floß (L03)**
- **Höhe:** Es fährt mit fester Höhe über der Kurve und dreht sich nur um Y (wasserplattform.gd:127-138). Steigt die Kurve, fährt das Floß bergauf.
  - Das Wasser liegt in 18-m-Platten relativ zur Kurve (level03.gd:178-195), dort entstehen Stufen. L10 rechnet die Welthöhe je Platte aus (level10.gd:165-181).
  - Für eine Stromschnelle bräuchten Floß und Wasser ein Profil in Welthöhe.
- **Kamera und 2D:** gehen wie zu Fuß, denn die Figur steuert normal. In 2D ist die Tiefe aber nicht zu sehen, also alles auf q 0 legen. Das Floß ist 4,6 m breit (level03.gd:71).

**Keiler (L05)**
- **Höhe:** s kommt aus `get_closest_offset` (level05.gd:394), der Keiler steht auf `sample_baked` der Kurve (:415-424).
  - Auf Terrassen oder Plattformen schwebt oder versinkt er.
  - Bei Stockwerken springt s.
- **Kamera:** Der Rückblick gilt nur levelweit. Der Wechsel zwischen Rückblick und Seitenansicht ginge über die Seitenblende; Rückblick zu Verfolger fehlt.
  - Beim Wechsel dreht sich die Steuerung um („runter“ wird zu „rechts“), deshalb ist das Festhalten der Eingabe nötig.
- **2D:** Die Hindernisse sind Area3D plus StaticBody (:160-200), in 2D also auf q 0 stellen.
  - Der Keiler bleibt höchstens 15 m zurück (:47). Bei 17 m Seitenabstand liegt er knapp am Bildrand (abgeleitet, ungeprüft).

## 5. Was ein Level mit neuem Verlauf liefern muss

1. **Verlauf:** in `_verlauf_anlegen()` über `kurve_aus_punkten`.
   - Kein senkrechtes Stück; 2D-Abschnitte gerade halten.
   - Welt-Y immer über −12.
   - Dazu `ende()`, `abschnitte()` und `absturz_hoehe()` liefern.
2. **Boden:** `korridor()` oder die L01-Daten (`nur_decke`, `stufen_kollision`, `boden_bei`).
   - Auf Terrassen nicht `kiste()` oder `gegner()` benutzen: Die setzen relativ zur Kurve (korridor_level.gd:695, :748).
3. **Start und Ziel:** `start_strecke` (level_basis.gd:36) und `portale_setzen()` (korridor_level.gd:669-679). Das Zielportal löst `level_geschafft` aus (level_basis.gd:430-449).
4. **Checkpoints:** Kiste CHECKPOINT (Weltort). Im Ritt eigene Zonen, die `Reiter.setze_checkpoint(s)` aufrufen (level04.gd:344-347). Den Keiler nach einem Tod neu stellen (wie `_nach_tod` in L05).
5. **Todeszonen:** `absturzzonen()` nur, solange es eine einzige Ebene gibt. Bei Stockwerken `todeszone()` auf fester Höhe (korridor_level.gd:819-834).
   - Die Sturzprobe setzt die Figur bei s 10, 45, 90, 135, 180 und 225 26 m seitlich ab (level_check.gd:433-443). Liegt dort fester Boden, meldet sie einen Fehler.
6. **Grenzen:** Leitlinien für die Figur auf Ebene 16 (Figur-Maske 17 = 1|16, Player.tscn:19-20). Der Kamerastrahl prüft nur 1|8, deshalb in 2D keine nahe Grenze auf Ebene 1 (F2). Deko, die den Blick verstellt, kommt auf Ebene 8 (Sichtsperre).
7. **Kamera:** Werte in der `LevelNN.tscn`. Auf `kamerazone` kann man sich erst nach der Behebung von F1 verlassen.
8. **Prüfung:**
   - `pruefprofil()` mit `breite_bei` und `boden_bei` (level_check.gd:29-45, 549-604).
   - `sprungfaelle()` für die Sprungprobe.
   - Der LevelCheck läuft automatisch für alle `LevelNN.tscn` (pruefe.sh:52-61).
9. **Rundgang und Vorwärmen:**
   - Der Rundgang läuft automatisch alle 12 m mit ±40° (level_basis.gd:22-23, 184-211).
   - Nebenwege über `_rundgang_pfade()` (:300); das überschreibt bisher kein Level.
   - Seitenblicke müsste man über ein eigenes `rundgang_blicke()` ergänzen.
   - Aufbau in `_bauschritte()`, alles, was von selbst läuft, erst in `_vor_dem_start()` freigeben.
10. **Hub und Spielfluss:**
    - Szene und Name nur in `LEVEL_SZENEN` und `LEVEL_NAMEN` eintragen (Spielfluss.gd:32-57, 78-82).
    - Richtzeit: Länge / 8,5 × 2,8, auf der Schiene Länge / 15 × 1,5 (Zeitlauf.gd:41-61, level_basis.gd:316-335). Genauer über `zielzeit()`, wie L06 und L22.
    - Die Kistenzahl zählt LevelBasis selbst (:473-485). Im Zeitmodus wird jede dritte NORMAL-Kiste zur Zeitkiste (:350-366), also genug NORMAL-Kisten an geprüften Stellen setzen.