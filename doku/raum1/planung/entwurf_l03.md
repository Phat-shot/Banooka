# Nutzerentscheidungen P0 (verbindlich, gehen allen Entwürfen und dem Baukastenplan vor)

- R1 (L02): **Spurbindung in 2D: JA.** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt (Seitenanteil ≥ 0,5). Reine Steuerung, keine Physikänderung. CLAUDE.md bekommt dazu eine Zeile (Steuerung).
- R2 (L04): **tempo_max 19 → 15 und Rastplatz-Tempo: JA.** reiter.gd bleibt unverändert; Level04.tscn setzt tempo_max 15, das Level setzt an jedem Rastplatz tempo_start.
- R3 (L05): **Slide-Sprung als Kür: JA.** Slide unter Durchlässen ist Pflicht; der Slide-Sprung belohnt (Abkürzung/Geheimnis), wird nie erzwungen.
- R4 (alle): **Modellbudget: bis ~24 neue CC0-Modelle** (nicht nur 9). G4 übernimmt die volle Wunschliste aus den vier Entwürfen (dedupliziert, rund 24 Dateien, Quaternius/Kenney, CC0), Ersatzlösungen aus baukasten.md §4 Nr. 10 entfallen, wo das echte Modell kommt. .pck-Zuwachs messen und berichten.
- R5 (Figur cash_banooka_rc.glb): offen, wird separat mit dem Nutzer geklärt; die Datei wurde vom Nutzer selbst eingecheckt. Nicht anfassen.

---

# Level 03 „Treibgut“, Neubau: Die fortgerissene Brücke

> **Grundlage:** HEAD 93b8816 (bzw. 052641f, das nur `.gitignore` ergänzt). Im Repo ist nichts geändert, gerendert habe ich nichts.
>
> **Gemessen bzw. gerechnet** habe ich in `/tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/l03_entwurf/`, und zwar mit:
> - `sprung.py`: 60-Hz-Sprünge in der Reihenfolge von player.gd:189-290;
> - `querung.py`: Wartezeiten und Fenster der Bahnen;
> - `kurve.py` und `kopie/werkzeuge/l03e_kurve.gd`: Kurve in Godot 4.7.2 gebacken, Geraden geprüft, Kameraformel nach corridor_camera.gd:366-461 mit dem Plan;
> - `kopie/werkzeuge/l03e_auslauf.gd`: echte Figur bei `--fixed-fps 60`, Landung und Auslauf;
> - `kopie/werkzeuge/l03e_orte.gd`: Weltorte und Fernsicht.
>
> Was nur geschätzt ist, steht als **ungeprüft** dabei.

---

## 0. Pitch

Ein gerader alter Steindamm führt durch braungrünen Sumpfdunst. Ab s ≈ 6 sieht man klein die Brücke, zu der er führt. Dreimal hat der Fluss den Damm durchbrochen, und jedes Mal kippt die Kamera in einen steilen **Hochblick**. Quer zum Weg treibt dort, was die Flut losgerissen hat: Flöße, Stammflöße, Fassflöße und ein Floß, in dessen Bug sich eine Treibmine verfangen hat. Man springt von Bahn zu Bahn hinüber. Wer springt, verliert die Strömung, also zielt man dorthin, wo das Treibgut bei der Landung sein wird.

Zwischen den Querungen steigt man über Mauerterrassen und kriecht unter dem Stützgerüst eines eingestürzten Flutbogens hindurch. Zuletzt geht es eine Rampe hinauf auf den letzten stehenden Brückenbogen. Hinter ihm fehlt der Mittelbogen.

**Leitsatz:** „Die Steinbrücke über den Sumpffluss war fortgerissen, also bin ich dreimal quer über den Strom gesprungen, auf allem, was gerade vorbeitrieb, bis auf den letzten stehenden Brückenbogen.“

---

## 1. Entscheidungen

| # | Entscheidung | Herkunft | Warum |
|---|---|---|---|
| E1 | Gerader Damm. Der Fluss quert ihn dreimal rechtwinklig (Q1 +q, Q2 −q, Q3 +q). Das Ziel liegt auf Bogen 1 (s 290), danach folgen Lücke 296–308, Bogen 3 und Torturm (s 327). | Leitidee, Spielkonzept §1, Jury S8/T2 | Einziges Level mit Querströmung. Das Wahrzeichen ist ein Bauwerk. Für die Lage gilt eine einzige Quelle. |
| E2 | Brückenreste erzählen eine Geschichte: Q1 und Q3 sind **Dammbrüche**. Q2 und C gehören zur **Flutbrücke**: Widerlager s 110–120, zwei Pfeilerstümpfe, der letzte Flutbogen in C. Die **Hauptbrücke** steht am Ziel. | eigene Synthese, Jury T2 | Die drei Brückenlagen aus Spiel- und Bildkonzept werden widerspruchsfrei. Die Q2-Stümpfe gehören damit nicht mehr zur Hauptbrücke. |
| E3 | **Deckregel:** Decktiefe ≥ Weite(Δh) − Lücke + 1,5 m. | Jury S1/T1, gemessen | Mit der alten Teilung blieben 1–4 Bilder bis zum Absturz (gemessen: 3,2-m-Deck 1 Bild, 2,0-m-Deck 4 Bilder). Neu sind es 12–13 Bilder. |
| E4 | Lücken: Q1 1,2/1,4, Q2 2,0, Q3 2,0–2,6 m. Tempo: 1,2 / 1,8 / 1,6–2,4 m/s. | Leitidee, Jury S1/S4 | Steigerung über Tempo und Lücke. Höchstens 3,0 m (Raumbogen). Die 2,8-m-Lücke entfällt. |
| E5 | Q3 bekommt nach B2 eine **Trümmerinsel** (+1,0, 11 × 3,6 m). | Jury S4 | Fünf Bahnen ohne Rast waren der größte Sprung der Steigerung. |
| E6 | **Fassfloß** 4,4 × 3,5 m mit flachem Bohlendeck. Die Zielscheibe ist nur aufgemalt. | Jury S4/T12 | Die Optik deckt sich mit der Kollision; die Fenster sind so groß wie bei den anderen Bahnen. |
| E7 | Die Treibmine sitzt im **Bug des Minenfloßes** als Kind des Trägers (wippen 0, pendel 0). | Jury S5, treibmine.gd:59/:67 | In der Floßlücke erreichte die Mine kein Deck: Sie lag 1,95 m entfernt bei 1,09 m Reichweite. Die Mine schreibt ihre lokale `position` und fährt deshalb ohne Umbau mit. |
| E8 | In Q1 laufen alle Bahnen gleich und sind **vorgehalten**: Versatz −0,75 m je Bahn. Negativ heißt stromauf, gezählt in Fließrichtung. | Spielkonzept §4, Jury S15 | Die erste Querung lehrt den Rhythmus. Ein gerader Sprung aus der Deckmitte trifft die Mitte. |
| E9 | Gegenläufige Bahnen sind **Kehrwasser vor einem Hindernis** und fließen auf das Hindernis zu: Q2 auf die verklausten Bogenöffnungen, Q3 auf Weidenstamm und Wrack. | Jury S20, Bildkonzept §4 | Das Bild erklärt die Richtung. |
| E10 | Neues Bauteil **`Treibbahn`**. `Wasserplattform` und `Treibmine` bleiben unverändert. | Technikkonzept §4, Jury T9 | L09, L24 und L25 nutzen `floss()`. |
| E11 | **Rechen statt Abtauchzone.** Die Stücke laufen unter einer Leitlinie bei \|q\| 13,5 durch (Unterkante +0,35, Ebene 16), die Figur wird abgestreift. Im Bild taucht das Stück per Vertexshader ab. Stromauf tauchen die Stücke spiegelbildlich auf. Rücksprung bei \|q\| 17 auf −1,5. | eigene Lösung aus Jury S10/S17/T15 | Die Gefahr hängt an einer festen, sichtbaren Linie und nicht an der Lage eines Stücks. Der Rücksprung liegt unter deckendem Wasser und unter Kronen. |
| E12 | Anleger erlauben \|q\| ≤ 8, Landestufen \|q\| ≤ 12. | Jury S10 | So bleiben selbst bei 2,4 m/s mindestens 2,1 s bis zum Rechen. |
| E13 | **Kameraplan nach Strecke s**, zustandslos, gemischt per smoothstep. Ränder 6 m. Voll eingeblendet ≥ 6 m vor jeder tödlichen Kante. Ränder liegen in Geraden. | Technikkonzept §3, Jury S2/T4/S18 | F1 tritt nicht auf. Ein Respawn steht sofort im richtigen Profil. |
| E14 | Hochblick 11/6/1 (55,0°) in Q1/Q2, 12/6/1 (57,5°) in Q3. Zielblick 7,5/11/9 (18,1°). | Spiel- und Technikkonzept, Jury T9 | Eine Zahl je Zone und immer ≤ 65°. |
| E15 | Die Kurve besteht aus **drei Beinen mit Stützpunkten alle 6 m**. Die Querungs-Geraden sind exakt. Die Kurve liegt flach auf y 1,2, nur die Rampe folgt der Bodenhöhe. Am Rampenfuß knickt sie um +25°. | gemessen, Jury S11/T2/S8 | Mit ungleichen Abständen (4 m neben 42 m) schleift `kurve_aus_punkten`; gemessen kippt die Tangente dann um 180°. Bei flacher Kurve folgt die Kamera der Figurhöhe. Der Knick zeigt die Bögen schräg. |
| E16 | **Altarm:** Seilfähre (bestehende `Wasserplattform` mit Querfahrt) über einer eingezäunten Fährrinne mit **Ausspülzone**, die kein Leben kostet. Ankerflöße mit wippen 0. | Jury S7/T5/T16 | Kein sichtbarer Rücksprung, keine Fähre über einer watenden Figur, kein Tod vor CP1. |
| E17 | **Abschnitt C ist der letzte Flutbogen** statt der Treibholzhalde. Unten ein Stützgerüst aus zwei Jochen (Pflicht-Krabbeln), oben ein Brüstungsweg auf +3,2 über eine Quadertreppe mit 1,0-m-Stufen. Der Brüstungsweg endet vor dem Gerüst. | Jury S6/T10/T13 | Keine Doppelung mit L04, ein Aufgang ist vorhanden, die Figur bleibt sichtbar, Krabbeln ist wirklich Pflicht. |
| E18 | **L03 führt das Krabbeln ein:** Slide-Taste gehalten, gefahrlos. Der Slide aus L01 löst die Stelle ebenfalls (player.gd:594-603). | Jury S13/T21 | Keine neue Taste, aber eine neue Bewegung. Das gehört in den Raumbogen. |
| E19 | Checkpoints bei s 36,5 / 115,5 / 167 / 191,5 / 244. | Spielkonzept §7, Jury S3 | Vor jeder Querung im vollen Hochblick, nach Q2 und Q3 im vollen Verfolger, nie in einem Rand. |
| E20 | Für S2 und S5 eine **SPRUNG**-Kiste statt FEDER. | Jury S14 | Sie verbraucht sich nicht (FEDER_SPRUENGE 10, kiste.gd:41) und zählt nicht (kiste.gd:1005). |
| E21 | `far` bleibt 200. Die Brücke hat ein **Fernbild** bei ≤ 185 m mit nebelarmem Stoff. | Jury T2/T19 | Der Turm liegt 319 m vor der Startkamera (gemessen), `far` 260 hätte nicht gereicht. |
| E22 | Kein Rückblick, keine Rückschau. Optional ein **Schlussbild nach vorn**, höchstens 2,5 s. | Jury S19/T11, Raumbogen | Rückblick gehört L05. Im Zeitmodus wartet das Level nur 3,0 s (level_basis.gd:444-446). |
| E23 | Alles L01-Nahe nur als **Kopie** (`strom.gdshader`, `dammpflaster.gdshader`, `scripts/gemeinsam/`). Geteiltes nur additiv. | Jury T7 | L01 bleibt pixelgleich. |
| E24 | Höchstens **5 neue Modelle**: `Willow_1/3/5`, `WoodLog`, `TreeStump`. Schilf prozedural. | Jury T8 | Rahmen „rund 25 Modelle“, belegt sind 16. |
| E25 | Sichtweiten für Kisten, Früchte und Gegner sind **Pflicht** (L01-Werte, level01.gd:845-856). | Jury T19 | Eine Kiste kostet 5–7 Zeichenaufrufe. |
| E26 | `zielzeit()` = 98 s. | eigene Rechnung (§6.6) | Die Vorgabe rechnete mit 350,5 m gebackener Länge, das ergäbe 115 s. |
| E27 | Keine Gegner auf Bahnen, Pfeilern oder Insel. 5 Gegner an Land. | Spielkonzept §7 | Gegner im Hochblick auf bewegtem Grund sind nicht fair. |

**Verworfen:**
- Teilung „Bahnabstand ≈ Sprungweite“ (Spielkonzept §4).
- Abtauchzone 13–15,5.
- Endlose Treibbahn im Altarm, Watfläche unter einer Bahn, 1,7-m-Rinne ohne Ausspülzone.
- Treibholzhalde mit Krabbelstamm und Steg auf +4,2, dazu das Haldenprofil 7,5/10/6.
- Fassbahn 2,6 × 2,0, Minen in den Floßlücken, Galgenminen, Stachelbalken.
- `far` 250/260.
- Brückenmitte bei s 207 und „Q3 unter der Brücke“ (Bildkonzept).
- Zielschwenk mit Blick zurück.
- Seerosen, Wehr, Längsflöße und Stege als Hauptelemente (gehören L09/L07).
- `Lilypad` und Birken (Modellrahmen).
- Umbau von `Wasserplattform` und `Treibmine` (Spielkonzept §10).
- Checkpoint auf der Q3-Insel: bleibt eine Stellschraube (§11).

### 1.1 Jury-Mängel und Antworten

| Jury | # | Mangel | Antwort |
|---|---|---|---|
| S | 1 | Landung an der Hinterkante | E3. Gemessen 12–13 Bilder bei gehaltenem Stick (§6.2); Probe „Halt“ (P4). |
| S | 2 | Blende zu spät fertig | E13. Voll bei 36/114/190, Kanten bei 42/120/196. |
| S | 3 | CP1 hinter Q1 | E19 |
| S | 4 | Fassbahn < 4 m, keine Rast in Q3 | E5, E6 |
| S | 5 | Minen in den Lücken wirkungslos | E7. Sichere Landezone auf dem Minenfloß 3,71 m (§2). |
| S | 6 | Halde doppelt L04, Höhen widersprüchlich, kein Aufgang, verdeckter Boden | E17. Spinne vor dem Gerüst, danach 5,8 m frei. |
| S | 7 | Altarm-Übungsbahn widersprüchlich | E16 |
| S | 8 | Zwei Brücken, Pfeiler im Strahl, Knick im Q3-Rand | E1/E2/E15. Knick erst ab s 248, die Q3-Gerade reicht bis 248. |
| S | 9 | Ruhende Bahnen sichtbar | §9.3: Die Optik rechnet immer, nur Körper ruhen. |
| S | 10 | Anleger bis in die Abtauchzone | E11/E12 |
| S | 11 | Kamera am Ziel tiefer statt höher | E15. Gemessen: 7,54 m über der Figur bei 18,1° (vorher 5,5 m / 12,7°). Kein Tor über dem Ziel. |
| S | 12 | Doppelstamm trägt optisch weniger | Stammfloß mit flachem Moos- und Bohlenrücken über die volle Kastentiefe (§8.5). |
| S | 13 | Krabbeln ist neu | E18 |
| S | 14 | Federkiste verbraucht sich | E20 |
| S | 15 | Vorzeichen des Versatzes | E8 |
| S | 16 | Luftausgleich kostet Weite | Lehre „vorher auf dem Deck gehen“. Die Wartezeiten „frei“ in §6.2 rechnen mit Gehen. |
| S | 17 | Dunst und Kronen verdecken den Tod | Kronen und Nebeltafeln erst ab \|q\| ≥ 15 (§8.3). |
| S | 18 | Ränder außerhalb der Geraden | E15. Gemessen: Tangente ≤ 0,01° von 27–81 und 99–248. |
| S | 19 | Zielschwenk und Zeitmodus | E22 |
| S | 20 | „Kehrwasser“ passt nicht | E9 |
| T | 1 | Landefalle, Probe blind | E3 und P4 (Kriterium „Halt“) |
| T | 2 | Wahrzeichen widersprüchlich und unsichtbar | E1/E2/E21. „Im Bild ab s ≈ 6“, gemessen (§3). |
| T | 3 | Fremdfigur in den Vorher-Bildern | P0: Nutzerentscheid vor den Nachher-Bildern; `foto.sh` mit leerem Benutzerordner. |
| T | 4 | Blende an der ersten Kante | E13. Mischregel in §7.1. |
| T | 5 | Watende Figur gegen Bahn | E16 |
| T | 6 | Randregel lückenhaft | §7.3/§7.4: Jede Kante ist Leitlinie, tödliches Wasser mit Zone oder Boden mit Kollision. |
| T | 7 | L01 gefährdet | E23 |
| T | 8 | Modellbudget überzogen | E24 |
| T | 9 | Daten widersprüchlich | Dieses Blatt ist die einzige Quelle (§4, §6, §7). |
| T | 10 | Kein Aufgang zum Steg | Quadertreppe in Stufen von 1,0 m (E17) |
| T | 11 | Rückschau | E22 |
| T | 12 | Fassbahn | E6 |
| T | 13 | Krabbelstamm verdeckt die Figur | Stützgerüst mit 0,35-m-Riegeln. Die Figur ist je Riegel höchstens 0,95 m Weg verdeckt (§5 C). |
| T | 14 | Ruhende Querungen sichtbar | wie S9 |
| T | 15 | Rücksprung sichtbar | E11 |
| T | 16 | Kisten auf wippenden Flößen | E16: wippen 0, die Flöße sind auf Grund gelaufen. |
| T | 17 | VRAM nicht geschätzt | §10 |
| T | 18 | Ladezeit-Ziel zu weich | §10: kalt ≤ heute + 1,5 s, warm ≤ 0,6 s |
| T | 19 | Sichtweiten Pflicht | E25. `far` bleibt 200. Handyweg ohne die Kronenebene über der Kamera. |
| T | 20 | Bauteile nach korridor_level.gd | §9.4, P3, P11 |
| T | 21 | Krabbeln nicht gelehrt | E18 |

---

## 2. Feste Größen und Rechenwerte

**Physik** (unverändert, player.gd:13-23): G −38, JUMP_V 12,2, DJUMP_V 10,5, RUN 8,5, AIR_CTRL 0,82 (6,97 m/s in der Luft), SLIDE 13,5 für 0,42 s, SLIDEJUMP 14,5, SLAM −30.

- Es gibt keine Gnadenzeit und keinen Sprungpuffer (player.gd:167, :235).
- Am Boden setzt jedes Bild das Tempo aus der Eingabe (player.gd:208).

**Sprünge** (60 Hz, `sprung.py`; flach 4,38 m auch in der Driftprobe gemessen):

| Δh (m) | −1,0 | −0,9 | −0,7 | 0 | +0,2 | +0,7 | +0,9 | +1,0 |
|---|---|---|---|---|---|---|---|---|
| Weite (m) | 4,91 | 4,86 | 4,76 | 4,38 | 4,26 | 3,92 | 3,77 | 3,69 |
| Flug (s) | 0,70 | 0,69 | 0,68 | 0,625 | 0,61 | 0,56 | 0,54 | 0,525 |

- **Scheitel:** Einzelsprung 1,86 m, Doppelsprung 3,22, Slide-Sprung 2,65, Slide-Sprung mit Doppelsprung 4,01. SPRUNG-Kiste: 5,10 m über der Kistenoberkante.
- **Doppelsprung:** flach bis 8,13 m, bei +2,4 m bis 6,12 m.
- **Bauchplatscher:** nach Bild 15 bzw. 20 landet man nach 2,16 / 2,76 m und 0,31 / 0,39 s.
- **Kante:** Steht die Kapselmitte bis 0,25 m jenseits der Kante, bleibt die Figur stehen; ab 0,30 m fällt sie (Driftprobe). Rechenrand 0,27.

**Drift:** Der Absprung nimmt die Fahrt nur ein Bild lang mit (gemessen 0,02–0,04 m). Danach gilt Versatz = v · Flugzeit:

| v (m/s) | 0,8 | 1,2 | 1,6 | 1,8 | 2,0 | 2,2 | 2,4 |
|---|---|---|---|---|---|---|---|
| Versatz bei 0,625 s | 0,50 | 0,75 | 1,00 | 1,12 | 1,25 | 1,38 | 1,50 |

**Treibbahn-Maße:**
- Schleife Λ = 34 m (q −17 … +17).
- Rechen und Schilfsperre bei \|q\| 13,5; die Kapselmitte kommt höchstens bis 13,12.
- Optik taucht von 13,5 bis 15,5 ab. Rücksprung bei \|q\| 17 auf −1,5.
- Die Körper reichen bis höchstens \|q\| 20; die Sturzprobe setzt bei 26 ab (level_check.gd:433-443).
- Deck 0,34 m stark (wasserplattform.gd:76), Oberkante +0,3. Wasser liegt auf Welt-y 0,0.

**Kamera** (Formel aus corridor_camera.gd:428-443, gemessen in der Kurvenprobe):

| Profil | hoehe/abstand/vorlauf | seiten_faktor | Neigung | Boden sichtbar | halbe Bildbreite an der Figur (16:9 / 20:9) |
|---|---|---|---|---|---|
| Verfolger (Grund) | 6 / 9,5 / 6 | 0,85 | 17,9° | – | – |
| Hochblick Q1/Q2 | 11 / 6 / 1 | 0,6 | 55,0° | s −5,0 … +17,6 | 12,8 / 14,8 m |
| Hochblick Q3 | 12 / 6 / 1 | 0,6 | 57,5° | s −5,5 … +17,1 | 13,7 / 15,9 m |
| Zielblick | 7,5 / 11 / 9 | 0,85 | 18,1° | – | – |

Die Figur steht im Hochblick bei y −0,18 bis −0,19, also knapp unter der Bildmitte.

**Regel K-H1:** Der Sichtstrahl prüft Ebene 1|8 (corridor_camera.gd:334). In den Querungen liegt deshalb bei \|q\| ≤ 14 nichts auf Ebene 1|8 über +1,5 m. Ausnahme sind Kisten bei \|q\| ≥ 3 auf Pfeilern und Insel: Der Strahl liegt dort ≥ 5,6 m über der Pfeileroberkante (gerechnet).

---

## 3. Verlauf

```gdscript
## Beine: [Kurs in Grad (0 = -Z, + = rechts), Länge in m]. Stützpunkte gleichmäßig,
## Länge/round(Länge/6) – ungleiche Abstände lassen kurve_aus_punkten schleifen.
const BEINE := [[0.0, 18.0], [-6.0, 75.0], [6.0, 161.0], [31.0, 96.0]]
## Kurvenhöhe: flach 1,2; Rampe 250–278 auf Bodenhöhe (1,2 → 6,0); danach 6,0.
## Ab P0 (0, 1.2, 4); Glättung 0.45 (Vorgabe, level_werkzeuge.gd:493).
```

Gebacken sind es **350,5 m** mit 59 Stützpunkten. `ende()` = 296; dahinter folgt Blickraum über Lücke, Bogen 3 und Torturm.

**Geraden** (gemessen): s 27–81 mit Kurs −6,00° sowie s 99–248 mit +6,00° (Q2, C und Q3 durchgehend). Abweichung quer ≤ 1 mm, Tangente ≤ 0,01°.

**Bögen:** −6° bei s 12–24, +12° bei s 87–99 (Terrassen), +25° bei s 248–260 (Rampenfuß). Es gibt keine Kehre.

| s | x | y (Kurve) | z | Kurs |
|---|---|---|---|---|
| 0 | 0,00 | 1,20 | 4,00 | 0,0° |
| 42 (Kante Q1) | −2,51 | 1,20 | −37,86 | −6,0° |
| 93 (Bogen) | −7,84 | 1,20 | −88,58 | −0,2° |
| 120 (Kante Q2) | −5,02 | 1,20 | −115,42 | +6,0° |
| 196 (Kante Q3) | 2,92 | 1,20 | −191,01 | +6,0° |
| 254 (Knick) | 8,96 | 1,87 | −248,62 | +18,1° |
| 278 | 21,11 | 5,96 | −268,87 | +31,0° |
| 290 (Ziel) | 27,28 | 6,00 | −279,15 | +31,0° |
| 327 (Torturm) | 46,34 | 6,00 | −310,87 | +31,0° |

**Höhen:** Die Böden sind Terrassen auf fester Welthöhe (`korridor()` mit `hoehe`/`hoehe_ende`). Weil die Kurve flach liegt, steht die Kamera immer auf Figurhöhe plus `hoehe`. Gemessen: 6,00 m im Verfolger, 11,00 bzw. 12,00 m im Hochblick, 7,54 m am Ziel. Die Rampe liegt 17,1 % steil, die Kamera steht dort 4,4 m über der Figur, wie bei jedem Anstieg.

**Wahrzeichen** (gemessen, Turmspitze bei s 327 auf +26):
- Von der Startkamera aus 319 m entfernt, Peilung +8°.
- Am Start blickt die Kamera 54,6° steil (START_HERANHOLEN, corridor_camera.gd:132). Ab s ≈ 6 sind es 24,4°, der obere Bildrand liegt dann bei +5,6° und die Turmspitze bei +3,4°: Der Turm ist im Bild.
- Näher als 185 m kommt der Turm ab Spieler-s 148.
- Bogen 1 von s 100 aus: 194 m bei +4°; von s 200 aus: 94 m bei +8°.

---

## 4. Abschnittstabelle

Einträge in `ABSCHNITTE`, Lücken entstehen als Abstand dazwischen. Abkürzungen: **V** Verfolger, **H** Hochblick, **H3** Hochblick Q3, **Z** Zielblick. Alle Höhen sind Welt-y.

| s | Abschnitt | Boden | Breite | Kamera | Inhalt |
|---|---|---|---|---|---|
| 0–10 | A Damm | +1,2 | 8 | V | Start s 2, Kistendreieck s 6 |
| 10–18 | A Bohlenanleger (Stufe −0,9) | +0,3 | 8 | V | Teich \|q\| ≤ 10 mit Watgrund −0,35; Ankerflöße A (s 12–15, q −8,5…−5,5) und B (14–17, +5,5…+8,5); Brückenquader (s 12, q −6,5) |
| 18–25,5 | A Fährrinne | Wasser 0, ungefährlich, Ausspülzone | Rinne \|q\| ≤ 10 | V | Seilfähre 4,0 × 4,3 (Deck s 19,6–23,9), Mitte q −3…+3, 0,8 m/s |
| 25,5–29 | A Kiesbank | +0,3 | 10 | V | S1 Kopfweide (s 26–28, q +6,5…+8,5, +2,6) |
| 29–38 | A Widerlager (Stufe +0,9) | +1,2 | 12 | V → H (Rand 30–36) | 2 Kisten s 32, **CP1 36,5** |
| 38–42 | Anleger Q1 (Stufe −0,9) | +0,3 | 16 | H | Kante 42,0 |
| 42–66,8 | **Q1** Dammbruch | Decks +0,3 | Bahnen ±13,5 | H 11/6/1 | B1 43,2–47,9 · B2 49,1–53,8 · B3 55,0–59,7 · B4 61,1–65,6 |
| 66,8–72 | B Landestufe | +0,3 | 24 | H → V (Rand 72–78) | 3 Kisten s 69,5 |
| 72–87 | B Schilfufer (Stufe +0,9) | +1,2 | 8 | V | 2 Kisten s 80, Kröte s 83 |
| 87–92 / 92–97 | B Terrassen | +2,2 / +3,2 | 8 | V | je 1 Kiste |
| 97–108 | B Damm | +4,2 | 8 | V | Käfer s 100,5, Stapel s 103,5 (q +2,8), SPRUNG s 104 (q −2,5), TNT s 106,5; S2 Pfeilerkopf links |
| 108–110 | B Treppe hinab | +3,15 / +2,1 | 8 | V → H (Rand 108–114) | – |
| 110–120 | Widerlager der Flutbrücke | +1,0 | 12 | H | FRUCHT_MEHRFACH s 113, **CP2 115,5**, Kante 120 |
| 120–157,6 | **Q2** Flutbrücke | Stämme +0,3, Pfeiler +1,0 | ±13,5 | H 11/6/1 | B1 122,0–126,3 (−q) · B2 128,3–132,2 (+q) · **P1 134,2–137,8** (Breite 11) · B3 139,8–144,1 (−q) · B4 146,1–150,0 (+q) · **P2 152,0–155,6**; S3-Stumpf neben P1 bei q +8,5…+11 |
| 157,6–190 | C Ufer und Gasse | +1,2 | 8 (Gasse q −3,5…+1,5 bei s 168–178) | H → V (Rand 160,5–166,5) | 2 Kisten s 162, **CP3 167**, Spinne s 171, Stützgerüst 181,0–182,95, Auslauf 183,3–189,1 |
| 166–178 | C Quadertreppe und Brüstungsweg (Ebene 16) | +2,2 / +3,2 | q +2…+5,5 | V | Käfer s 173, 3 Kisten + FRUCHT_MEHRFACH, S4; Nest unten s 178,5–179,7 |
| 190–196 | Anleger Q3 (Stufe −0,9) | +0,3 | 16 | V → H3 (Rand 184–190) | **CP4 191,5**, Kante 196 |
| 196–233,7 | **Q3** Dammbruch | Decks +0,3, Insel +1,0 | ±13,5 | H3 12/6/1 | B1 198,0–201,9 (+q) · B2 204,1–207,8 (−q) · **Insel 209,8–213,4** · B3 215,4–219,7 (+q, Mine) · B4 222,1–225,6 (−q, Fass) · B5 228,2–231,5 (+q) |
| 233,7–238 | D Landestufe | +0,3 | 24 | H3 → V (Rand 237–243) | 3 Kisten s 236 |
| 238–250 | D Ufer (Stufe +0,9) | +1,2 | 10 | V | **CP5 244**, Kiste s 248 |
| 250–278 | D Rampe, Knick 248–260 | +1,2 → +6,0 | 7 | V | Kröte s 264; Brüstung links offen bei 260–266 zum S5-Sims |
| 278–296 | D Bogen 1 | +6,0 | 6 | V → Z (Rand 280–286) | LEBEN s 286,5, **Ziel 290**, Abbruchkante 296 |
| 296–330 | Kulisse | – | – | – | Lücke 296–308 (vierte Flussschlinge), Pfeiler 308–311, Bogen 3 311–323, Torturm 327 (+26) |

**Ebenen:** Wasser 0 · Deck und Anleger +0,3 · Pfeiler und Insel +1,0 · Ufer und Damm +1,2 · Terrassen +2,2/+3,2 · Damm +4,2 · Brüstungsweg +3,2 · Bogen +6,0.

---

## 5. Abschnitte im Einzelnen

### A · Altarm (0–42): Morgen am toten Arm
**Spiel**
- Kistendreieck: Drehschlag.
- Der Bohlenanleger (8 m) führt in den klaren Teich. Waten ist erlaubt, der Grund ist sichtbar und harmlos.
- Die **Fährrinne** quert den Teich. Sie ist zu den Watflächen hin mit Schwimmbäumen eingezäunt (Leitlinie Ebene 16, −0,35 … +0,2; der Anleger liegt mit +0,3 darüber).
- Die **Seilfähre** pendelt quer zum Weg. Man geht am Anleger entlang zur Fähre, wartet also nicht. Wer in die Rinne fällt, landet in der **Ausspülzone** (−0,6 … −2,0) und wird ohne Lebensverlust auf den Anleger (s 16) zurückgesetzt.
- Drift-Lektion: Wer auf der fahrenden Fähre springt, landet 0,5 m gegen die Fahrt versetzt.
- Ankerflöße mit wippen 0 tragen Kisten.
- S1: Kopfweide.

**Bild**
- Damm +1,2, links und rechts der Teich mit Kopfweiden.
- Brückenquader mit Steinmetzzeichen im klaren Wasser, ab s ≈ 6 das Fernbild der Brücke.
- Dichter Morgendunst mit Lichtbändern durch die Weiden (`Lichtschacht`, `Staub` als Weidenflaum), Libellen nur hier.

### Q1 · Dammbruch 1 (42–66,8): Der Strom tritt ins Bild
**Spiel**
- 4 Bahnen, alle +q mit 1,2 m/s. Floß 5,0 × 4,7, B4 4,5 tief, je 4 Stück.
- Vorgehalten um −0,75 m je Bahn (E8), deshalb trifft ein gerader Sprung aus der Deckmitte die nächste Deckmitte.
- Nur der Einstieg verlangt ein Fenster: frei ≤ 0,78 s, stehend ≤ 3,7 s.

**Bild**
- Der Himmel kippt aus dem Bild. Vier lange, weiche Bahnstreifen ziehen von links nach rechts.
- Links liegen Schilfsperre und Weidenvorhang als Quelle, rechts der Treibholzrechen mit Schaumwalze.
- Oben im Bild die Landestufe mit Steintreppe.

### B · Schilfufer (66,8–120): Der Fluss läuft mit
**Spiel**
- Kröte (Drehschlag), dann drei Mauerterrassen zu je +1,0 m, dann der Damm +4,2.
- Vom Damm aus sieht man Q2 unter sich. Die Bahnen laufen dort schon gegenläufig: Die Lektion wird gefahrlos angeboten.
- Käfer: draufspringen. TNT. Über die Treppe hinab aufs Widerlager, CP2.

**Bild**
- Der Strom läuft rechts im Mittelgrund parallel und treibt Treibgut nach Q2 voraus. Links liegt der Schilfgürtel.
- Am Widerlager ist ein Bogenansatz eingemeißelt.

### Q2 · Flutbrücke (120–157,6): Kehrwasser zwischen den Stümpfen
**Spiel**
- Der Hauptstrom (B1, B3) läuft −q, das Kehrwasser (B2, B4) +q zur Verklausung.
- Stammfloß 6,0 lang, 4,3 bzw. 3,9 tief, 1,8 m/s.
- Zwei Pfeiler, 11 × 3,6, mit Kisten als Rastinseln.
- Die Gegenläufer verlangen Fenster: frei ≤ 0,67 s, stehend ≤ 1,17 s.
- S3: Auf B2 fährt man zum Kehrwasserstumpf mit.
- In der Verklausung hängt eine Treibmine, sichtbar und unerreichbar.

**Bild**
- Pfeilerstümpfe mit spitzen Vorköpfen.
- An der +q-Seite hängen die verklausten Bogenöffnungen. Davor dreht sich das Kehrwasser als Schaumwirbel, die Richtung ist auch im Standbild lesbar.
- Links liegt ein Prallhang mit Wurzelwand.

### C · Flutbogen (157,6–196): Was von der Flutbrücke blieb
**Spiel**
- Spinne in der Gasse: Slide.
- Rechts führt die Quadertreppe (+2,2/+3,2) auf den **Brüstungsweg** über der stehenden Bogenhälfte. Dort ein Käfer, 3 Kisten, eine FRUCHT_MEHRFACH-Kiste und S4.
- Der Brüstungsweg endet bei s 178 offen über dem **Nest** (4 Kisten; Bauchplatscher, Schockwelle 2 m).
- Danach kommt das **Stützgerüst**, das jeder Weg durchqueren muss:
  - Zwei Joche im Abstand von 1,6 m über die volle Breite (q −3,9…+4,4).
  - Je drei Riegel, 0,35 × 0,35 m, mit Unterkante 0,95 / 2,40 / 3,70 m über der Gasse, auf Ebene 16.
  - Die Zwischenräume (1,10 und 0,95 m) sind kleiner als die aufrechte Kapsel (1,30). Über den Oberriegel (4,05) kommt auch ein Doppelsprung nicht: Der Scheitel liegt bei 3,22.
  - Also gilt: krabbeln, oder sliden und unter dem Gerüst weiterkrabbeln.
- Danach 5,8 m freier Slide-Auslauf ohne Gegner.

**Bild**
- Halb eingestürzter Bogen, Quader nass bis zur Flutlinie, Gerüstbalken aus Holz.
- Dunkler, mit Lichtflecken; die Spinne steht in einem davon.

**Sicht** (gerechnet, Verfolger 6/9,5): Unter dem Gerüst bleibt die Figur zu sehen. Hinter einem Joch ist ihre Mitte je Riegel höchstens 0,95 m Weg verdeckt (bei d 0,96–1,91 / 3,41–4,36 / 5,61–6,55 m). Das sind ≤ 0,11 s im Lauf und ≤ 0,32 s beim Krabbeln.

### Q3 · Dammbruch 3 (196–233,7): Die Prüfung vor der Brücke
**Spiel**
- B1: Floß 4,6, +q, 1,6 m/s.
- B2: Stammfloß, −q, 2,0 m/s, Kehrwasser vor dem Weidenstamm.
- Insel +1,0 als Rast mit Kisten.
- B3: Minenfloß 5,5, +q, 1,6 m/s, die Mine im Bug. Gefahr reicht bis 1,79 m vom Bug, die sichere Zone ist 3,71 m lang.
- B4: Fassfloß 4,4 mit 5 Stück, −q, 2,2 m/s, Kehrwasser vor dem Wrack. Platscher freiwillig, frühestens ab Bild 20 nach dem Absprung.
- B5: Stammfloß, +q, 2,4 m/s.

**Bild**
- Die schnellste Bahn ist hell und zerrissen.
- Das Minenfloß trägt den Warnring (treibmine.gd:13-15).
- Die Fassdeckel sind als Zielscheibe bemalt.
- Rechts liegt der Rechen aus Dammquadern, links Weidenvorhang und Wrack.
- Die Sonne wird wärmer, das Bild ist hier am klarsten.

### D · Brückenkopf (233,7–296): Auf dem letzten Bogen
**Spiel**
- CP5, danach die Rampe mit Kröte. Durch die Brüstungslücke springt man hinab auf den S5-Sims.
- Auf Bogen 1 LEBEN, dann das Ziel. Hinter der Abbruchkante steht eine Querwand.

**Bild**
- Durch den Knick sieht man die Bögen schräg; ihre sonnige Westflanke zeigt zur Kamera.
- Der Dunst reißt auf, das Licht wird golden.
- Der Zielblick schaut über die Lücke auf Bogen 3 und den Torturm. Dahinter liegt die helle Talpforte.

---

## 6. Spiel

### 6.1 Lehrfolge (erst gefahrlos angeboten, dann gefordert)

| Thema | angeboten | gefordert |
|---|---|---|
| bewegter Boden trägt | Seilfähre (Ausspülzone) | Q1 |
| Absprung nimmt keine Fahrt mit | Fähre, 0,5 m Versatz | Q2/Q3, gegenläufige Bahnen |
| Rhythmus | Q1, gleichläufig und vorgehalten | – |
| gegenläufige Bahnen lesen | Dammblick s 97–108 | Q2 B1→B2, B3→B4 |
| Krabbeln | Stützgerüst, gefahrlos (Slide geht auch) | dieselbe Stelle, Pflicht |
| Bauchplatscher als Landehilfe | Nest | Q3 Fassfloß, freiwillig |
| Treibminen | Mine in der Q2-Verklausung | Q3 Minenfloß |
| Steigerung | Tempo 1,2 → 1,8 → 1,6–2,4 m/s | Lücken 1,2 → 2,0 → 2,0–2,6 m |

### 6.2 Sprungtabelle (Pflicht)

Spalten:
- **Fenster:** Absprungstrecke, die trägt, = min(Tiefe A, Weite − Lücke + 0,27).
- **Landung / Halt:** echte Figur, Absprung an der Kante, Stick gehalten. Landetiefe in B sowie Bilder bis zum Absturz (gemessen).
- **Warten:** gerechnet, „frei“ heißt mit Gehen auf dem Deck, „still“ heißt stehend.

| Sprung | Kante s | Lücke | Δh | Fenster | Landung / Tiefe B | Halt | Warten frei / still |
|---|---|---|---|---|---|---|---|
| Anleger → Fähre | 18,0 | 1,6 | 0 | 3,05 | 2,94 / 4,3 | 12 | 0 (gehen) |
| Fähre → Kiesbank | 23,9 | 1,6 | 0 | 3,05 | Ufer | – | 0 |
| Q1 Anleger → B1 | 42,0 | 1,2 | 0 | 3,45 | 3,34 / 4,7 | 12 | 0,78 / 3,72 |
| Q1 B1→B2, B2→B3 | 47,9 / 53,8 | 1,2 | 0 | 3,45 | 3,34 / 4,7 | 12 | 0,33 / 0,30 |
| Q1 B3→B4 | 59,7 | 1,4 | 0 | 3,25 | 3,14 / 4,5 | 12 | 0,33 / 0,30 |
| Q1 B4 → Landestufe | 65,6 | 1,2 | 0 | 3,45 | Ufer | – | 0,32 |
| Q2 Widerlager → B1 | 120,0 | 2,0 | −0,7 | 3,03 | 2,89 / 4,3 | 12 | 0,65 / 2,03 |
| Q2 B1→B2, B3→B4 | 126,3 / 144,1 | 2,0 | 0 | 2,65 | 2,54 / 3,9 | 12 | 0,67 / 1,17 |
| Q2 B2→P1, B4→P2 | 132,2 / 150,0 | 2,0 | +0,7 | 2,19 | 2,08 / 3,6 | 13 | 0,63 / 0,82 (stehend 6–8 % ohne Fenster: gehen) |
| Q2 P1 → B3 | 137,8 | 2,0 | −0,7 | 3,03 | 2,89 / 4,3 | 12 | 0,68 / 2,02 |
| Q2 P2 → Ufer | 155,6 | 2,0 | +0,2 | 2,53 | 2,42 / Ufer | 28 | 0,32 |
| Q3 Anleger → B1 | 196,0 | 2,0 | 0 | 2,65 | 2,54 / 3,9 | 12 | 0,82 / 3,12 |
| Q3 B1→B2 | 201,9 | 2,2 | 0 | 2,45 | 2,34 / 3,7 | 12 | 0,70 / 1,17 |
| Q3 B2 → Insel | 207,8 | 2,0 | +0,7 | 2,19 | 2,08 / 3,6 | 13 | 0,58 / 0,83 |
| Q3 Insel → B3 | 213,4 | 2,0 | −0,7 | 3,03 | 2,89 / 4,3 | 12 | 0,93 / 3,67 |
| Q3 B3→B4 | 219,7 | 2,4 | 0 | 2,25 | 2,14 / 3,5 | 12 | 0,67 / 1,10 |
| Q3 B4→B5 | 225,6 | 2,6 | 0 | 2,05 | 1,94 / 3,3 | 12 | 0,68 / 0,98 |
| Q3 B5 → Landestufe | 231,5 | 2,2 | 0 | 2,45 | 2,34 / 4,3 | 16 | 0,32 |
| Stufen | 29, 72, 238 / 87, 92, 97 | – | +0,9 / +1,0 | – | – | – | – |

- **Absprung aus 2,0 m vor der Kante:** In allen Fällen gelandet (gemessen, 26–28 Bilder Halt).
- **Abhängen:** Mit „frei“ gibt es keinen Übergang ohne Fenster.
- **Zeit bis zum Rechen** ab q 8: 4,3 / 2,8 / 3,2–2,1 s (Q1 / Q2 / Q3).
- **Pflichtsprünge:** alle Einzelsprünge, höchstens 2,6 m Lücke. Kein Pflicht-Doppelsprung, der gehört L02.

### 6.3 Geheimnisse

| | Ort | Oberkante | Weg hinauf | Reserve | Inhalt |
|---|---|---|---|---|---|
| S1 Kopfweide | s 26–28, q +6,5…+8,5 | +2,6 | Doppelsprung oder Slide-Sprung von der Kiesbank (Δh 2,3) | 0,92 / 0,35 | 2 NORMAL, FRUCHT_MEHRFACH |
| S2 Pfeilerkopf | s 102–105, q −4,4…−7,4 | +7,7 | SPRUNG s 104 (Scheitel +10,3); alternativ Slide-Sprung mit Doppelsprung (4,01) | 2,6 / 0,51 | 3 NORMAL |
| S3 Kehrwasserstumpf | s 134,2–137,8, q +8,5…+11 | +1,0 | auf B2 bis q ≈ 9,5 mitfahren, dann springen (+0,7); zurück auf B3 oder seitlich auf P1 | 2,0 s bis zum Rechen | 2 NORMAL, SCHUTZ |
| S4 Zwickelrest | s 174,5–176,5, q +3,5…+5,5 | +5,4 | Doppelsprung oder Slide-Sprung vom Brüstungsweg (Δh 2,2) | 1,02 / 0,45 | 3 NORMAL |
| S5 Sims | s 260–266, q −4,5…−8,0 | +1,2 | von der Rampe ≈ 2,2 m hinab; zurück per SPRUNG (Scheitel +7,3) oder Doppelsprung | 4,0 / 1,0 | 2 NORMAL, FRUCHT_MEHRFACH |

Jedes Geheimnis wird mit Früchten angekündigt. Die Sims-Kanten sind Leitlinien, man kann dort nicht abstürzen.

### 6.4 Zählung

| | A | Q1 | B | Q2 | C | Q3 | D | Summe |
|---|---|---|---|---|---|---|---|---|
| NORMAL | 9 | – | 13 | 6 | 13 | 2 | 6 | **49** |
| weitere zählende | 2 FM | – | FM, TNT | FM, 2 SCHUTZ | FM | FM | FM, LEBEN | **11** |
| CHECKPOINT / SPRUNG (zählen nicht) | 1 / – | – | 1 / 1 | – | 2 / – | – | 1 / 1 | 5 / 2 |
| Gegner | – | – | Kröte 83, Käfer 100,5 | – | Spinne 171, Käfer 173 (oben) | Minen (4) | Kröte 264 | **5** |
| Früchte (≈) | 18 | 8 auf Decks | 18 | 8 auf Decks + 6 | 18 | 10 auf Decks + 2 | 17 | **≈ 105** |

- **Kisten:** 67, davon zählen 60 (kiste.gd:1005).
- **Zeitkisten:** Im Zeitmodus wird jede dritte NORMAL-Kiste zur Zeitkiste, also 16 (level_basis.gd:31, :350-366).
- **Wo Kisten stehen dürfen:** nur auf festem Boden, auf Pfeilern und Insel bei \|q\| ≥ 3, auf Ankerflößen mit wippen 0. Keine Kiste schwebt.
- **Kistenstapel:** Stapel über 1,3 m nur bei \|q\| ≥ 2,6.
- **Früchte auf Decks:** Sie sind Kinder jedes zweiten Stückkörpers und fahren mit, damit sie nicht ins Wasser locken.

### 6.5 Checkpoints

| CP | s | Boden | Profil beim Respawn | Zweck |
|---|---|---|---|---|
| 1 | 36,5 | Widerlager +1,2 | Hochblick voll | vor Q1 |
| 2 | 115,5 | Widerlager +1,0 | Hochblick voll | vor Q2 |
| 3 | 167,0 | Ufer +1,2 | Verfolger | nach Q2, vor Spinne und Gerüst |
| 4 | 191,5 | Anleger +0,3 | Hochblick voll | vor Q3 |
| 5 | 244,0 | Ufer +1,2 | Verfolger | nach Q3, vor der Rampe |

### 6.6 Richtzeit

`zielzeit()` = 98 s, gerechnet als `ende` 296 / 8,5 · 2,8 = 97,5 s. Daraus folgen Gold 83,3 s und Platin 70,6 s.

Ein geübter Lauf dauert geschätzt etwa 50 s (**ungeprüft**): 34,8 s reiner Weg, ≈ 8 s Warten, ≈ 4 s Gegner und Kisten, ≈ 2 s Fähre. Abgenommen wird mit dem Bot (P4).

---

## 7. Kamera und Kollision

### 7.1 Kameraplan (Daten in level03.gd, Mechanik aus P1)

| Zone | Rand ein | voll | Rand aus | Profil | Gerade (Tangente ±0,01°) |
|---|---|---|---|---|---|
| Q1 | 30–36 | 36–72 | 72–78 | 11/6/1, seiten 0,6 | 27–81 |
| Q2 | 108–114 | 114–160,5 | 160,5–166,5 | 11/6/1, 0,6 | 99–248 |
| Q3 | 184–190 | 190–237 | 237–243 | 12/6/1, 0,6 | 99–248 |
| Ziel | 280–286 | 286–296 | – | 7,5/11/9, 0,85 | 260–296 |

- **Mischregel:**
  - Gewicht w(s) = smoothstep(ein) · (1 − smoothstep(aus)); Profil = Grund + w · (Zone − Grund).
  - Die Zonen liegen ≥ 6 m auseinander, es mischen also nie mehr als zwei Profile.
  - Gemischt werden nur `abstand`, `hoehe`, `blick_vorlauf` und `seiten_faktor`, nie `fov` (corridor_camera.gd:262-264).
  - Gelesen wird an der geführten Stelle `_strecke` (corridor_camera.gd:350-363), die höchstens 26 m/s wandert.
- **Gemessen** (Kurvenprobe): An den Kanten 42, 120 und 196 sowie an CP1, CP2 und CP4 ist das Profil voll. Die Gierrichtung weicht im Rand und in der Zone um höchstens 0,2° von der Tangente ab, deshalb muss die Eingabe nicht festgehalten werden.
- `sofort_ausrichten()` (corridor_camera.gd:163) setzt nach einem Respawn sofort das Profil an dieser Stelle.

### 7.2 Ebenen und Kamerastrahl

| Ebene | Inhalt |
|---|---|
| 1 | Wegdecke (eine Kollision mit `stufen_kollision`), Ufer, Pfeiler, Insel, Bogendeck, Treibstücke, Fähre, Ankerflöße, Kisten |
| 16 (Spielergrenze) | Leitlinien, Rechen, Schilfsperren, Schwimmbäume, Stützgerüst, Quadertreppe, Brüstungsweg, Geheimnis-Körper, Brüstungen |
| 8 | nur die Bogenleibung von Bogen 1 als Sichtsperre, Unterkante ≥ +4,5 über dem Gelände; der Weg verläuft obendrüber |

Die Figur-Maske 17 gibt es schon (Player.tscn:19-20). Der Kamerastrahl prüft 1|8 (corridor_camera.gd:334) und trifft daher keine Leitlinie. Am Ziel steht kein Tor über dem Weg.

### 7.3 Spielergrenze (Leitlinien, 5 m hoch)

- **A:** ±4,4 (Damm), Teichrand ±10,5, Schwimmbäume entlang s 18,0 und 25,5, Widerlager ±6,4, Anleger ±8,4, Querwand hinter dem Start.
- **Querungen:**
  - Rechen und Schilfsperre bei \|q\| 13,5 von Kante zu Kante, Unterkante +0,35 (`leitlinie(… unten 0,85, hoehe 3,8, ebene 16)`, level_werkzeuge.gd:1076).
  - Landestufen ±12,4.
- **B:** ±4,4, um den Pfeilerkopf bei −7,8; Widerlager ±6,4.
- **C:** links −3,9 (Gasse) bzw. −4,4; Brüstung +5,9; rechts +4,4 nach dem Brüstungsweg.
- **D:** Ufer ±5,4; Rampe ±3,9 mit Lücke links bei 260–266; Sims mit eigenen Linien; Bogen ±3,4; Querwand 295,6.

### 7.4 Todeszonen

- **Wasser der Querungen:** je ein `Wasser`-Knoten, tödlich, Fläche ausgeblendet; sichtbar ist das Strom-Band (Muster der L01-Furt).
  - Q1: s 41,8–67,0
  - Q2: s 119,8–157,8
  - Q3: s 195,8–233,9
  - jeweils q ±20, Oberkante Welt 0,0.
- **Grund:** `LevelWerkzeuge.todeszone()` auf Welt −6 (q ±40, s −10…340), Gruppe `todeszonen` (level_werkzeuge.gd:1147). `absturzzonen()` entfällt (korridor_level.gd:819-834).
- **Altarm:** Ausspülzone statt Tod.
- **Rechen:** keine Zone; die Figur wird abgestreift und fällt ins Wasser. Rückfall ist eine Area an der Rechenfront (§11, R2).
- **Sturzprobe** (s 10/45/90/135/180/225, q 26): Dort liegt keine Kollision, die Körper reichen nur bis \|q\| ≤ 20. Der Fall bis −6 ist 7–9 m tief.
- **Jede Kante** ist Leitlinie, tödliches Wasser mit Zone oder Boden mit Kollision (`pruefprofil` mit `rand`).

### 7.5 Vorwärmen

Der Rundgang folgt mit Plan (P1) einem Halt alle 12 m mit dem Profil an dieser Stelle. Gieren ±40° im Verfolger, 0/±30° im Hochblick. Dazu der Zielblick und, falls gebaut, das Schlussbild. Im Hochblick werden so Strom-Shader, Schaum, Treibgut und Weiden von oben vorgewärmt.

---

## 8. Bild

### 8.1 Bildregeln
1. **Was trägt, ist hell und warm** (Pflaster, Deckquader, Deckholz, Fassdeckel; Luma 0,45–0,65). **Was tötet, ist dunkel:** Der Strom ist deckend, Luma ≤ 0,2.
2. **Wo man den Grund sieht, ist das Wasser harmlos** (Altarm). Die Fährrinne ist dunkel, spült aber nur zurück.
3. **Die Strömung zeigt sich im Wasser:** Bahnstreifen mit eigenem Tempo, Bugwelle und Kielwasser, deren Länge mit dem Tempo wächst. Keine Pfeile, keine Warnbalken; `luecken_markieren` entfällt.
4. **Treibgut kommt aus dem Grün und verschwindet unter Holz.** Gegenläufer fließen auf ihr Hindernis zu.
5. **Je höher, desto mehr Brücke.** Die Flutlinie (Welt-y ≈ +1,9) ist ein Parameter nur in neuen Stoffen (`mauerwerk`, Treibgut), nicht in geteilten.

### 8.2 Wahrzeichen
- **Fernbild:** ein Netz aus Brücke und Turm, eine Fläche, nebelarmer Stoff (Kopie von weltenbaum.gd:436-450).
  - Es steht auf der Sichtlinie bei min(Abstand, 185 m) und ist mit Faktor 185/Abstand skaliert, sein Winkel bleibt also gleich.
  - Ab Spieler-s 148 übernimmt die Fernstufe der echten Ruine: ≤ 2 Flächen, darunter ≤ 4 Flächen in der Nähe (`visibility_range`).
- **Steigerung entlang des Wegs:** Quader im Altarm (s 12), Widerlager (s 110), Pfeilerstümpfe (Q2), Flutbogen (C), Bogen 1 (Ziel), Lücke, Bogen 3, Torturm.

### 8.3 Hochblick-Bühne
- **Spielfeld:** hell bei \|q\| ≤ 10. Die Flügel bei 10–27 sind dunkel und ergeben zugleich ≥ 25 % dunklen Rahmen.
- **Rechen** bei 13,5, am Bildrand (§2).
- **Weidenkronen und Nebeltafeln** erst ab \|q\| ≥ 15, nie über Abstreif- oder Spielzone.
- **Kanten:** An der Absprungkante steht bei \|q\| ≤ 5 nichts über +1,2.
- **Sonne:** 60° hoch, von hinten links (aus SSW). Ihr Spiegel liegt hinter der Kamera, das Wasser zeigt seine Eigenfarbe.

### 8.4 Licht und Farbe (Startwerte, im Bild zu stimmen)
- **Level03.tscn wie Level01.tscn:**
  - `himmel.gdshader`: Zenit 0,30/0,40/0,46; Horizont 0,66/0,68/0,58; Dunst 0,60/0,62/0,50; Wolkendeckung 0,85.
  - **Tiefennebel** `fog_mode 1`: 14 → 120 m, Deckkraft 0,85. Kein Höhennebel; der alte (Level03.tscn:28-36) trübte den Hochblick.
  - Sonne 1,0/0,93/0,78 mit Stärke 0,65.
  - Himmelslicht 0,60/0,70/0,72 mit 0,35; Moorreflex 0,52/0,50/0,30 mit 0,12.
  - Glow an, Bildrahmen 0,30.
- **Strom:** tief 0,09/0,10/0,06, hell 0,22/0,23/0,13, Schaum 0,82/0,82/0,70, deckend.
- **Altarm:** tief 0,18/0,22/0,12, hell 0,36/0,40/0,22, `grund_alpha` 0,5, `himmel_farbe` = Horizont (wasser.gd:50-57).
- **Stimmungszonen** (Regler-Kopie, Ränder 6 m):

| Zone | s | Nebel × | Licht × | Sonne |
|---|---|---|---|---|
| Altarm | 0–29 | 1,6 | 0,9 | – |
| Q1 | 36–72 | 0,45 | 1,15 | – |
| Schilfufer | 78–108 | 1,0 | 1,0 | – |
| Q2 | 114–160 | 0,45 | 1,2 | ×1,1 |
| Flutbogen | 167–184 | 1,2 | 0,85 | – |
| Q3 | 190–237 | 0,45 | 1,25 | 1,0/0,86/0,64 |
| Brückenkopf | 243–296 | 0,7 | 1,35 | golden ×1,15 |

- **Farbziele** (kontaktbogen.py:94-95):
  - Verfolger: Der Weg hat die höchste Luma; warm ≤ 50 %, kühl 6–12 %. Das ist bewusst anders als L01, wo kühl ≥ 10 % gilt.
  - Hochblick: Decks und Ufer ≥ 2× die Luma des Stroms; Strom ≥ 35 % der Fläche; Warnrot ≤ 2 %.
  - Für den Hochblick braucht der Kontaktbogen eine neue Messgröße „Deck/Wasser“ (Vorschlag).

### 8.5 Modelle

| Rolle | Quelle | Lizenz | Stand |
|---|---|---|---|
| Weiden am Ufer und als Vorhang über den Bahnenden | Quaternius Ultimate Nature Pack `Willow_1/3/5`, 1946/1044/1624 Dreiecke, Stoffe Wood/DarkGreen | CC0 (`natur2/LIZENZ_UltimateNaturePack.txt`) | liegt in `scratchpad/modelle/fbxprojekt/glb/`, nach `assets/modelle/natur2/unp/`; CREDITS-Zeile 12 ergänzen |
| Treibholz, Rechenholz | UNP `WoodLog` (464), `TreeStump` (232) | CC0 | dito |
| Totholz, Moosfelsen, Moosstämme | UNP `CommonTree_Dead_1/2`, `Rock_Moss_*`, `WoodLog_Moss`, `TreeStump_Moss` | CC0 | im Repo |
| Fernwald | `Kronenwolke.fern` (kronenwolke.gd:168) | eigen | im Repo |
| Schilf, Rohrkolben, Seggen | prozedural (`Schilf`: `Rasensaum.bueschel`/`wispel` gestreckt plus Kolbenkopf) | eigen | neu |
| Brücke, Quader, Pfeiler, Insel, Flutbogen, Gerüst | prozedural (`Bogenruine`, Stoff `mauerwerk`) | eigen | neu |
| Floß, Stammfloß (flacher Rücken), Fassfloß, Minenfloß | prozedural, Treibbahn-Optik | eigen | neu |
| Großblatt, Farn | `Bodenstreu.grossblatt`, `Farnwerk.stoff(farbe)` | eigen | im Repo |

- Danach sind es 21 von rund 25 Modellen; für L02, L04 und L05 bleiben 4.
- Die Kenney-Würfelbäume (baum.gd:131-140) fallen weg.
- **Ungeprüft:** ob die Weidenzweige hängen und wie die Stoffklasse von `DarkGreen` ausfällt (`_NAMEN_KLASSE`, fremdmodelle.gd:362).

---

## 9. Technik

### 9.1 Module (Zustand in Instanzen, kein `static var`)

```
scenes/levels/level03.gd      Daten (BEINE, ABSCHNITTE, BEGEHBARES, QUERUNGEN, LEITLINIEN,
                              TODESZONEN, KAMERAPLAN, KISTEN, GEGNER, FRUECHTE, STIMMUNG),
                              Abfragen (boden_bei, breite_bei, weg_punkt, kisten_orte,
                              pruefprofil, sprungfaelle, querungsziel), Bauschritte
scenes/levels/level03/
  strom.gd      L03Strom      Mäanderband, Bahnstreifen mit Nähten, Altarm, Fährrinne, Schaum
  ufer.gd       L03Ufer       Ufer- und Pfeilerkanten über Kanten/GelaendeSaum
  gelaende.gd   L03Gelaende   Höhenmodell: Aue +0,3…+0,8, Flussbett −1,5, Altarm −0,35, Talflanken 120–190 m
  bruecke.gd    L03Bruecke    Bogenruine nah/fern, Fernbild, Widerlager, Pfeiler, Insel, Flutbogen, Gerüst
  bewuchs.gd    L03Bewuchs    Weiden, Totholz, Felsen (Waldsetzer), Schilf, Rasen, Streu
  stimmung.gd   L03Stimmung   Zonen für den Stimmungsregler, Staub, Libellen
neu: scenes/props/treibbahn.gd, scenes/props/bogenruine.gd, scenes/props/schilf.gd,
     shaders/mauerwerk.gdshader, shaders/strom.gdshader (Kopie von BACH_SHADER,
     level01/wasser.gd:135), shaders/dammpflaster.gdshader (Kopie mit #include wald_gemeinsam)
```

### 9.2 Gemeinsame Bausteine

Sie kommen aus dem L02-Durchlauf (Technikkarte 3.2); L03 übernimmt sie nur.
- `Wegdaten` mit `boden_bei` (nötig für level_check.gd:564)
- `Wegdecke`, Stoff-Cache je Level und Thema, nicht je Art (Fehler boden.gd:44)
- `Kanten` (GelaendeSaum-Stoffvariante „sumpf“, Profile `ufer`/`stirn`/`boeschung` aus saum.gd:827/:1792/:1306)
- `GelaendeBau` (Muster gelaende.gd:263-295)
- `Stimmungsregler` (aus stimmung.gd:264)
- `Nebelstoff.nebelarm` (aus weltenbaum.gd:436-450)
- `Waldrahmen` mit dem Auge aus der echten Kamera

L01 delegiert nicht (Stufe A).

### 9.3 `Treibbahn` (scenes/props/treibbahn.gd)

- **Daten je Bahn:** s-Mitte, Tiefe, Richtung (±1), Tempo, Stück {art, länge}, Anzahl, Versatz (m, in Fließrichtung, negativ = stromauf). Die konkreten Werte stehen in §4 und §5.
- **Lage:** u_k(t) = fposmod(versatz + tempo·t + k·Λ/n + Λ/2, Λ) − Λ/2, und q = richtung · u.
  - Die **Stromuhr** gehört dem Level: t = (physikbilder − f₀)/60, gestartet in `_vor_dem_start()` (level_basis.gd:292). Bilder und Proben sind damit reproduzierbar.
- **Körper:**
  - Je Stück ein `AnimatableBody3D` mit `sync_to_physics`, Ebene 1, Maske 0. Form: Kasten Länge × 0,34 × Tiefe.
  - Gesetzt wird in einem einzigen Schreibzugriff auf `transform` (wasserplattform.gd:119-126). Nach dem Rücksprung folgt `reset_physics_interpolation()`.
  - Körper weiter als 60 m von der Figur ruhen.
- **Optik:**
  - Je Querung und Art ein `MultiMeshInstance3D` (`custom_aabb` über die Querung, `PHYSICS_INTERPOLATION_MODE_OFF`).
  - Der Puffer wird einmal je Bild gesetzt, mit t_bild = t − dt + fraction·dt. Die Optik rechnet **immer**, auch wenn die Körper ruhen.
  - Der Vertexshader lässt das Stück ab \|q\| 13,5 abtauchen bzw. auftauchen und wippt es um ±4 cm, nur im Bild.
  - Ein Schaum-MultiMesh je Querung zeigt Bugwelle und Kielwasser.
- **Kinder:** Treibminen am Bug (B3) und Früchte.
- **API für Probe und Bot:** `uhr_setzen(t)`, `stuecke_bei(t)`, `traeger(bahn, i)`, `landepunkt(bahn, i, t)`.

### 9.4 Änderungen an geteilten Teilen (alle additiv)

| Teil | Änderung | Warum L01 und die anderen gleich bleiben |
|---|---|---|
| corridor_camera.gd | `plan` (null = heute, P1); optional `schlussfahrt(ziel, dauer)` | Ohne Plan dieselben Ausdrücke |
| level_basis.gd, rundgang.gd | Haken `kameraplan()` (Vorgabe `[]`), `Rundgang.blicke_plan()` | Leerer Plan heißt alter Pfad; `blicke_entlang` bleibt unverändert |
| korridor_level.gd | `treibbahn()`, `rechen()`, `seilfaehre()` (Wasserplattform mit `strecke_a = strecke_b`, `seitlich_a ≠ seitlich_b`, wasserplattform.gd:112-136), `ausspuelzone()`, `pfeiler()` | Nur neue Funktionen |
| level_check.gd | Sichtmodell mit Plan (:718-746); Proben „kameraplan“ und „querung“ als Opt-in | `pruefprofil` ist Opt-in |
| sprungprobe.gd | Feld `art` (Vorgabe „lauf“); `halt` (10 Bilder Stick nach der Landung); `bewegt` | L01-Fälle ohne Feld bleiben unverändert |
| spieltest.gd | `querungsziel()`, Gruppe `krabbelstellen` | Opt-in |
| fremdmodelle.gd | Rolle „weide“ | Risiko `_NAMEN_KLASSE`: Hub und L01 vergleichen |
| werkstatt.gd | Stationen hinten anhängen | Stationen 1–29 bleiben |
| **Reiter** (reiter.gd), **Keiler** (level05.gd), **Wasserplattform**, **Treibmine**, Player.tscn | **keine** | – |

### 9.5 Bauschritte und Bauspeicher

Vor der Liste wird der Verlauf angelegt, wie in level01.gd:878-879. Danach die Schritte:
1. Damm und Anleger: Decken und eine einzige Kollision.
2. Ufer: je Seite und 30-m-Stück ein Schritt.
3. Gelände: vermessen, formen ×n, färben (`l03_gelaende_voll|handy`).
4. Fluss: Strom (`l03_strom`), Altarm, Wasserzonen, Ausspülzone.
5. Brücke und Pfeiler (`l03_bruecke_nah|fern`).
6. Grenzen: Leitlinien, Rechen, Schwimmbäume, Todeszone.
7. „Treibgut wird losgemacht“: Treibbahnen (die Uhr steht), Fähre, Ankerflöße.
8. Kisten, Gegner, Früchte, Portale (aus Tabellen).
9. Weiden und Schilf (mehrere Schritte).
10. Stimmung.

In `_vor_dem_start()` starten Stromuhr und Fähre.

Jede Skriptänderung leert die Fassung des Bauspeichers (bauspeicher.gd:33-40). L01 lädt danach einmal kalt.

### 9.6 Handyweg (`Effekte.reduziert`)
- Weiden, Totholz und Schilf jedes zweite Stück.
- Rasen und Streu ×0,5.
- Ohne Kronenebene dicht unter der Hochblick-Kamera.
- Ohne Staub, Libellen und Glitzern.
- Schatten 50/60 m (level_basis.gd:26-27).
- Sichtweiten Web 55/45/60 (level01.gd:853-855).
- Bugwelle, Bahnstreifen und Bodenschatten bleiben, weil sie Lesbarkeit sind.

---

## 10. Leistungsbudget

**Heute (gemessen, vorher/l03.log):** 656 / 505 / 502 / 432 Zeichenaufrufe bei s 10/60/130/220, Handyweg 508 bei s 10. Primitive bis 397k, VRAM 83,7 MB, Bauzeit kalt 4686 ms und warm 245 ms.

**Ziel:** Desktop 285–500, Handy ≤ 450, Primitive ≤ 600k (Rahmen 750k), VRAM ≤ 130 MB. Bauzeit kalt ≤ 6,2 s (Desktop headless) bzw. ≤ 6,8 s (Handyweg), warm ≤ 0,6 s.

Zeichenaufrufe je Bild nach Modul (**Schätzung, ungeprüft**):

| Modul | s 10 (V) | s 60/130/220 (H) | s 178 (V) | s 288 (Z) |
|---|---|---|---|---|
| Weg, Lippen | 4 | 3 | 4 | 4 |
| Ufer, Kanten | 12 | 6 | 12 | 10 |
| Gelände | 8 | 4 | 6 | 8 |
| Strom, Altarm, Schaum | 5 | 4 | 3 | 4 |
| Treibbahnen (+ Schatten) | – | 2–4 (+2–4), Q3 mit Minen +9 | – | – |
| Brücke und Reste (+ Schatten) | 3 | 3 (+2) | 5 (+3) | 6 (+4) |
| Bewuchs (+ Schatten) | 45 (+15) | 20 (+6) | 40 (+12) | 40 (+12) |
| Schilf, Rasen, Streu | 25 | 10 | 22 | 20 |
| Stimmung | 6 | 2 | 4 | 4 |
| Spiel und HUD (+ Schatten) | 200 (+40) | 170 (+30) | 200 (+40) | 180 (+35) |
| **Summe** | **≈ 365** | **≈ 260–280** | **≈ 350** | **≈ 330** |

- **Handyweg:** etwa −100 je Station (Bewuchs, Schilf, Stimmung, Sichtweiten), also rund 260–270. Die Hebel sind die gleichen wie in L01, wo sie 387–436 ergaben (doku/level01-neubau.md:5).
- **Primitive:** Weiden-MultiMesh ≈ 90k, Schilf ≈ 160k, Gelände und Ufer ≈ 80k, Brücke ≈ 40k, Spiel ≈ 60k, zusammen ≈ 450k (**ungeprüft**).
- **Neue Laufzeittexturen** (RGB8 mit Mipmaps, materialbibliothek.gd:123):
  - `mauerwerk`: Albedo und Normal je 512², ≈ 2,1 MB
  - `dammpflaster`: 2 × 512², ≈ 2,1 MB
  - Schaum: 256², ≈ 0,3 MB
  - Der Strom nutzt das L01-Rauschen.
- **Messen** mit `FOTO_WERTE`.

---

## 11. Risiken

1. **Sprünge ohne Mitnahme fühlen sich fremd an.** Gegenmittel: Lehre auf der Fähre, großzügige Fenster (§6.2), Abnahme im Spiel.
2. **Abstreifen am Rechen ist ungeprüft.** Offen ist, wie `move_and_slide` eine Plattformbewegung gegen eine Wand verrechnet. Fall im Flosstest; Rückfall ist eine Todeszone an der Rechenfront (Area, Ebene 0, Maske 2).
3. **MultiMesh-Optik gegen interpolierten Körper:** Die Glattprobe kann ZITTERT/STUFT melden (**ungeprüft**). Rückfall: je Stück eine MeshInstance mit Interpolation, plus etwa 20 Zeichenaufrufe.
4. **Kameraplan (P1)** muss L01 pixelgleich lassen. Ob die Bilder exakt reproduzierbar sind, ist **ungeprüft** (Technikkarte 3.4).
5. **Ausspülzone** ist neuer Code: Kamera und Interpolation beim Versetzen.
6. **Fernbild:** Die Parallaxe ist falsch, unsichtbar bei 185 m im Nebel. **Ungeprüft** im Bild.
7. **Modelle:** Hängeform der Weiden und Stoffklasse sind **ungeprüft**.
8. **Hochblick am Handy mit Touch-Tasten** (`FOTO_TOUCH=1`) ist **ungeprüft**. Die Figur steht bei y −0,19, die Tasten liegen in den unteren Ecken.
9. **Q3 ohne Checkpoint auf der Insel:** Wird es zu hart, kommt dort ein CHECKPOINT dazu (Stellschraube).
10. **Fremdfigur** `cash_banooka_rc.glb` steht nicht in CREDITS (einstellungen.cfg:3 wählt sie). Herkunft **ungeprüft**, Entscheid in P0.

---

## 12. Arbeitspakete (Reihenfolge)

Jedes Paket endet mit `bash werkzeuge/pruefe.sh` → **ERGEBNIS: SAUBER**. Skripte samt `.uid`, Texte deutsch, Physikwerte unberührt. Gerendert wird nur gezielt in einer Projektkopie.

**P0 `klaerung`** (Nutzer, vor dem Bau)
- **Ziel:** Entscheidungen zu
  - der Figur `cash_banooka_rc.glb` (Lizenz oder aus dem Export nehmen; Nachher-Bilder mit leerem Benutzerordner);
  - der Modellquote des Raums (L03: 5);
  - Schlussbild nach vorn ja oder nein;
  - dem Raumbogen-Eintrag „L03 führt Krabbeln ein“;
  - der Richtzeit 98 s.
- **Abnahme:** Entscheide sind notiert.

**P1 `kameraplan`** (gemeinsamer Durchlauf vor L02)
- **Ziel:** `scripts/kameraplan.gd`, `plan` in corridor_camera.gd, Haken in level_basis.gd, `blicke_plan` in rundgang.gd, Sichtmodell und Probe „kameraplan“ in level_check.gd (Neigung ≤ 65°, Tangente ±1° von Randbeginn bis Randende, Zonen überlappen nur in Rändern), Werkstatt-Station.
- **Abnahme:**
  - Schaufenster `l01,l01seite,l01nah,hub` gegen `VORHER=HEAD` pixelgleich, `werte.tsv` gleich.
  - L02/L10 ohne Plan unverändert.

**P2 `gemeinsam`** (kommt mit L02, §9.2)
- **Ziel:** L03 übernimmt nur.
- **Abnahme:** wie in der Technikkarte 3.4.

**P3 `treibbahn`**
- **Ziel:** `scenes/props/treibbahn.gd` sowie `treibbahn()`, `rechen()`, `seilfaehre()`, `ausspuelzone()`, `pfeiler()` in korridor_level.gd; Werkstatt-Stationen 30–32 (Treibbahn mit Rechen, Seilfähre mit Ausspülzone, Stützgerüst).
- **Abnahme:**
  - Flosstest-Fälle: Mitnahme ≤ 0,05 m, Abstreifen, Rücksprung ohne Spur, Ausspülen ohne Lebensverlust.
  - Glattprobe mit der Werkstatt ohne ZITTERT/STUFT.
  - Bauzeit der Station ≤ 50 ms.

**P4 `rohbau03`**
- **Ziel:** level03.gd neu nach §3–§7 als Graubox. Dazu:
  - `kameraplan()`, `zielzeit()` = 98, `pruefprofil()` = {sicht, gefaelle, todeszonen, rand, kameraplan, querung};
  - `sprungfaelle()`: Stufen, Fähre und Querungen (`art` „bewegt“ mit `halt`);
  - `querungsziel()` für den Bot;
  - Level03.tscn mit Grundprofil 6/9,5/6 und `far` 200.
- **Abnahme:**
  - Sprungprobe: alle Fälle tragen, Halt ≥ 10 Bilder bei Absprung bis zur Kante.
  - Probe „querung“: 12/12 Takte, Warten frei ≤ 1,0 s.
  - LevelCheck sauber (Kisten und Gegner auf Boden, Sturzprobe an 6 Stellen).
  - Spieltest-Rauchlauf `TEST_LEVEL=3` bis ins Ziel; die Zeittafel zeigt 98 s.

**P5 `bruecke`**
- **Ziel:** `bogenruine.gd` nah, fern und Fernbild; `mauerwerk.gdshader`; Widerlager, Pfeilerkopf, Pfeiler, Insel, Flutbogen, Gerüst-Optik genau auf der Kollision; Bauspeicher.
- **Abnahme:**
  - Verfolgerfotos bei s 10 und 290: Turm bei s 10 im Bild.
  - Nah ≤ 4 (+3) Aufrufe, fern ≤ 2, Fernbild 1.

**P6 `ufer_gelaende`**
- **Ziel:** `gelaende.gd` (Mäander), `ufer.gd` mit Profilen, `dammpflaster.gdshader`, Lippen an den Dammbrüchen.
- **Abnahme:**
  - Fotos s 10 und 178 im Verfolger: kein Bordstein, keine PlaneMesh am Horizont.
  - Gelände ≤ 8 Aufrufe, Ufer ≤ 12.

**P7 `strom`**
- **Ziel:** `strom.gdshader` (Kopie mit Tempo je Spalte in UV2.x, doppelte Vertices an den Bahnnähten), Altarm klar, Treibgut-Netze (Stammfloß mit flachem Rücken), Schaum und Rechenwalze.
- **Abnahme:**
  - Foto s 60/130/220 im Hochblick: Decks ≥ 2× Strom-Luma, Strom ≥ 35 % der Fläche.
  - Strom ≤ 6 Aufrufe.

**P8 `bewuchs`**
- **Ziel:** 5 Modelle importieren und in CREDITS eintragen; Rolle „weide“; Waldsetzer, Schilf, Rasen, Streu; Deckung erst ab \|q\| ≥ 15.
- **Abnahme:**
  - Hub- und L01-Schaufenster unverändert.
  - Bewuchs ≤ 60 (+20) Aufrufe.

**P9 `stimmung`**
- **Ziel:** Level03.tscn (Himmel, Tiefennebel, Lichter, Bildrahmen), Stimmungszonen, Staub, Libellen.
- **Abnahme:** Farbziele laut Kontaktbogen (§8.4) an s 10/60/130/178/220/290.

**P10 `leistung`**
- **Ziel:** Messung und Handyweg.
- **Abnahme:**
  - `FOTO_BUDGET_DRAW=500` an 6 Stellen.
  - `FOTO_REDUZIERT=1 FOTO_TOUCH=1 FOTO_BUDGET_DRAW=450` bei s 60/130/220.
  - Primitive ≤ 600k, VRAM ≤ 130 MB.
  - Bauzeitprobe in 2 Runden, Desktop und reduziert: kalt ≤ heute + 1,5 s, warm ≤ 0,6 s.
  - Rundgang- und Ruckelprobe ohne Befund.

**P11 `doku`**
- **Ziel:**
  - CLAUDE.md, L03-Absatz neu: „Level 03 quert den Sumpffluss dreimal im Hochblick: Treibgut fährt quer zum Weg (`Treibbahn`), der Absprung nimmt keine Fahrt mit. Die Steuerung bleibt die normale – anders als in 04 und 06.“
  - Raumbogen: Krabbeln in L03.
  - doku/level-vorbilder.md: „Neu aus dem Neubau von Level 03“ (Treibbahn, Rechen, Seilfähre, Ausspülzone, Hochblick, Bogenruine, Stützgerüst).
  - Werkstatt-Station 33 (Bogenruine 1:2 mit Fernbild).
  - CREDITS.
  - Optional das Schlussbild (≤ 2,5 s).
- **Abnahme:** `pruefe.sh` SAUBER; Schaufenster L01 und Hub pixelgleich.