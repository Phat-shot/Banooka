# Nutzerentscheidungen P0 (verbindlich, gehen allen Entwürfen und dem Baukastenplan vor)

- R1 (L02): **Spurbindung in 2D: JA.** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt (Seitenanteil ≥ 0,5). Reine Steuerung, keine Physikänderung. CLAUDE.md bekommt dazu eine Zeile (Steuerung).
- R2 (L04): **tempo_max 19 → 15 und Rastplatz-Tempo: JA.** reiter.gd bleibt unverändert; Level04.tscn setzt tempo_max 15, das Level setzt an jedem Rastplatz tempo_start.
- R3 (L05): **Slide-Sprung als Kür: JA.** Slide unter Durchlässen ist Pflicht; der Slide-Sprung belohnt (Abkürzung/Geheimnis), wird nie erzwungen.
- R4 (alle): **Modellbudget: bis ~24 neue CC0-Modelle** (nicht nur 9). G4 übernimmt die volle Wunschliste aus den vier Entwürfen (dedupliziert, rund 24 Dateien, Quaternius/Kenney, CC0), Ersatzlösungen aus baukasten.md §4 Nr. 10 entfallen, wo das echte Modell kommt. .pck-Zuwachs messen und berichten.
- R5 (Figur cash_banooka_rc.glb): offen, wird separat mit dem Nutzer geklärt; die Datei wurde vom Nutzer selbst eingecheckt. Nicht anfassen.

---

# Level 02 „Frostgrat“: Neubau über den Eisgrat zum Gipfelfeuer

Stand HEAD 93b8816. Im Repo habe ich nichts geändert und nichts gerendert. Alle Werte habe ich mit 60-Hz-Physik nachgerechnet, in der Reihenfolge von `player.gd:149-306` (Sprung, Jump-Cut, Schwerkraft, Bewegung). Die Rechenhilfen liegen in `/tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/entwurf_l02/`:
- `sprung.py`: Weiten, Fenster, Touch, schräger Stick, Höhen
- `verlauf_final.py`: Kurve, Kameraplan, Sehnen, Blenden, Feuer, Sonne
- `rest.py`: Gipfelstufe, Wechten, Zapfen, Eis, Richtzeit

Dieser Entwurf ist die einzige Quelle für das Level. Spiel-, Bild- und Technikkonzept sind darin aufgegangen, Widersprüche entscheidet §1.

---

## 0. Pitch

> „Ich habe die Flanke des Eisgrats gequert: erst im Schatten der Nordseite über glatte Simse, dann durch das Sonnentor in der Scharte auf die warme Südseite mit ihren brechenden Wechten. Mit Doppelsprüngen bin ich bis zum Gipfelfeuer hinaufgekommen.“

- **Kalt heißt glatt, warm heißt brüchig.** Eis gibt es nur im Schatten, Wechten und Tropfzapfen nur in der Sonne.
- **Die Seitenansicht ist die Pointe.** Sie macht jede Weite ablesbar und zeigt, was trägt: Fels darunter trägt, Luft darunter bricht.
- **Der Doppelsprung ist der Weitenregler.** Zuerst wird er gefahrlos angeboten, über einer Fangleiste. Dann wird er dreimal gefordert, zweimal flach und einmal als Aufstieg. Am Ende hebt er die Figur auf den Gipfel.
- Das Feuer mit seiner Rauchfahne ist ab dem Start zu sehen. Der Weg biegt davon ab und kommt durch die Scharte von der anderen Seite zurück.

---

## 1. Entscheidungen

Abkürzungen: **S** Spielkonzept, **B** Bildkonzept, **T** Technikkonzept, **J1.n** Jury Spiel & Kamera, **J2.n** Jury Technik & Bild, **RB** Raumbogen, **R** eigene Rechnung.

| # | Entscheidung | Herkunft | Warum |
|---|---|---|---|
| E1 | **Grundriss:** Biwak mit Kurs 160° (SSO) auf den Grat zu. Rechtsbogen r 8 auf Kurs W. Nordflanke auf z −10 nach W (2D). Scharte: Linksecke r 6, 6 m Sonnentor nach S, Linksecke r 9. Südflanke auf z +11 nach O (2D). Gipfelgrat in der Verlängerung nach O. Die Flanken liegen 21 m auseinander. | S, T, R | Beide Flanken laufen im Bild links → rechts, die Kamera steht mit +16,5 beide Male im Abgrund (corridor_camera.gd:413-426). Das Feuer steht vom Start aus 18° links vorn (R). |
| E2 | Länge 287 m, Start bei s 10 (spielbar 277 m) | J1.6, J1.11, J1.9 | Platz für die Gegnerregel (≥ 3 m Ruhe), einen CP vor jeder neuen Gefahr und 10 m Vorlauf hinter dem Start |
| E3 | **Kamera:** nur Standardverfolger (5,6/9,5/6) und Seitenansicht. Zum Auftakt `blick_hoehe` 3,0. In der Scharte 5,6/7/7. | J1.16, J1.9, J1.7, RB | Tiefer und hoher Verfolger sind die Signatur von L04. Mit abstand = vorlauf entsteht in der Kehre keine Drift. |
| E4 | **Kameraplan nach Strecke s** (smoothstep über das Blendfenster). Er blendet alle Felder über, auch Blickziel und `blick_hoehe`. Der Seitenblick nickt nicht mehr. `kamerazone` bleibt für die anderen Level. | T, F1 | Behebt F1, macht 2D fotografierbar und lässt sich von Proben nachrechnen |
| E5 | **Zwei Blendarten:** Eckblende über eine 90°-Ecke (Blick bleibt ±18°) und drehende Blende nur auf Geraden, je 9 m. Driftregel: Die gehaltene Richtung driftet immer gegen eine Wand oder Leitlinie. **Kein Richtungsanker.** | J1.10, J2.2, J2.12, R | Ohne Anker gibt es keinen Eingriff in die Regel „kamerarelativ“ und trotzdem keinen Sturz (§7.2) |
| E6 | 2D-Tiefensperre über Leitlinien bei q ±0,55 (Ebene 16), in den Blenden als Trichter | J2.1 | Die Figurmitte bleibt in ±0,17 m. Was im Bild trifft, trifft auch wirklich (Kisten und Gegner liegen auf q 0). |
| E7 | **Spurbindung in 2D**, nur nach Rückfrage R1 | J1.2 | Mit W+D (45°) fällt das Fenster von P1 auf 0,25 m (R). Das lässt sich nur über die Eingabe beheben. |
| E8 | **Pflicht-Doppelsprünge:** P1 und P3 flach 5,0 m, P2 Höhen-Doppelsprung über 3,0 m auf +2,2. Die Gipfelstufe +2,2 ist ohne Lücke und harmlos. | J1.1, J1.12c, RB | Hält die Raumregel (5,0 m, Reserve 2,08). Bei Doppelsprung nach 0,20 s bleibt ein Fenster von 1,30 m bzw. 2,05 m (§2). |
| E9 | F1 ist eine Fanglücke von 5,0 m über einer vereisten Fangleiste 2,0 m tiefer. Hinweis am Kistenfels und vor F1. | RB, J1.14 | Der erste Doppelsprung ist gefahrlos. Wer ihn nicht kennt, landet weich und bekommt den Hinweis. |
| E10 | **Kalt = glatt:** im Norden 16 m Blankeis, die Fangleiste aus Eis und eine Eismulde, dazu die Pfütze im Biwak. **Warm = brüchig:** alle Wechten und Zapfen liegen im Süden. Ab s ≈ 16 liegt das Biwak im Gratschatten. | J1.12a/b, J2.4, R | Die Leitidee gilt ausnahmslos. Die Schattenkante fällt mit der Eispfütze zusammen. |
| E11 | Wechten auf `Bruchplatte` mit neuen Optionen (Optik, `warn_weite` 0,12, `zerfaellt`, `rueckkehr_frei`). Das Zurücksetzen nach einem Tod ist Pflicht. | J1.4, J2.7, J2.8 | bruchplatte.gd:113 hat keinen Aufrufer, und die Warnung ist in 2D nur 1,8 px groß |
| E12 | Tropfzapfen einzeln im Takt 2,0 s, mit Wartefläche ≥ 2 m. `phase` ist ein Bruchteil des Takts (taktflaeche.gd:120). Es gibt keine Zapfenwelle. | J1.5, J2.17 | Die Welle lief mit 4 m/s und wurde von der Figur eingeholt, außerdem gehört Taktketten-Timing zu L03 |
| E13 | Gegnerregel: nur auf ebenen Stücken ≥ 8 m, ≥ 3 m Abstand zu Landungen, Stufen, Pflichtsprüngen und Wechten. In 2D patrouillieren sie längs auf q 0. Fünf Gegner. | J1.6, J2.16 | – |
| E14 | Sechs Checkpoints: 45, 93, 145, 198,5, 233,5, 262 | J1.11 | Vor jeder neuen tödlichen Gefahr steht ein CP |
| E15 | **Abgrenzung zu L14:** kein Abprall von Gegnern (S5 per Slide-Sprung), Tiefe sichtbar, Fels unter allem, was trägt, Doppelsprung als Kern | J1.3 | Was sich weiter überschneidet, steht in R3 |
| E16 | Erhöhte begehbare Flächen in 3D (Kistenfels, Gipfelzacke, Gipfelplatte) liegen auf Ebene 16 | J1.8, L01 E17 | Der Kamerastrahl (1\|8) startet am Blickziel. Ebene 1 voraus zöge die Kamera vor die Figur. |
| E17 | Scharte: innerer Felskern im Kreis r 8 um (−84,7/0) mit Sichtsperre. Ecke 2 hat r 9. | J1.7, J2.3, R | Die Sehnenhülle bleibt bei q ±1,3 mindestens 0,9 m vor dem Kern |
| E18 | Eine Sonne (205°/22°). Der Lichtwechsel kommt aus Geometrie, Schattenkamm und einem **Stimmungsregler nach s**, der Nebel, Umgebungslicht, Sonnenenergie und Bildrahmen steuert. Erste Schattenstufe ≥ 32 m. Keine OmniLights. | B, T, J2.4, J2.13, J2.14 | `stimmung()` regelt keine Sonne und keinen Nebelbeginn (stimmungszone.gd:25-35) |
| E19 | Spielobjekte hängen in Sichtgruppen je Abschnitt, geschaltet nach s mit Überlappung | J2.6 | Es gibt kein Occlusion Culling. Die Flanke hinter dem Grat würde sonst mitgezeichnet. |
| E20 | Kollision in L01-Bauweise (Variante b): Decke über die volle Breite, keine Bordsteine, Leitlinien auf Ebene 16 | T | Der Verlauf ist ohnehin neu |
| E21 | Gemeinsame Bausteine werden kopiert und verallgemeinert (Stufe A). L01 bleibt unberührt. | Technikkarte | Kein Risiko für L01. Die Umstellung von L01 ist eine eigene Aufgabe. |
| E22 | Kein Wolkenmeer, sondern durchbrochene Nebelbänke über sichtbaren Tälern | B, J2.13 | Abstand zu L14 und L22 |
| E23 | Name „Frostgrat“, level02.gd:2 und Kopfkommentar neu | Vorgabe | Spielfluss.gd:79, README.md:46 |
| E24 | Geheimnisse mit je einer Bewegung: S1 Doppelsprung, S2 Fallenlassen, S3 Eismulde, S4 Bauchplatscher, S5 Slide-Sprung mit Doppelsprung | S, J1.3 | Belohnungsvertrag wie in L01 |

**Verworfen:**
- **5,5 m flach als Pflicht.** Mit Touch (0,10 + 0,10 s) bleibt ein Fenster von 0,70 m, bei 30° Stick 0,90 m (R).
- **Stufe +1,9 auf 4,5 oder 5,0 m.** Doppelsprung bei 0,15 s ergibt 0,20 m bzw. „–“ (R).
- Zapfenwelle, Krabbenabprall in S5, Felsband in 2D.
- Wechte im Biwak und Wechtenmulde im Norden.
- Auftakt mit Kamera auf 1,8 m Höhe und Gipfelkamera 8/13.
- Richtungsanker.
- Zonen über `stimmung()`.
- Kehre r 7 mit Profil 7/4.
- Wolkenmeerfläche.
- Holiday-Hütte, Kenney `tree_cone` und die grün gedeckelten `rock_*`.
- TNT am Gipfel.

**Abweichungen von der gewählten Leitidee** (Bestätigung über R2):

| Leitidee | Hier | Grund |
|---|---|---|
| ≈ 250 m | 287 m (spielbar 277) | E2 |
| erste Wechte im Biwak | erste Wechte bei s 180,5 auf der Südseite über einer Mulde | Leitsatz „warm = brüchig“, J1.12a. Das Biwak liegt im Luv und im Schatten. |
| Pflicht 5,5 m flach; Stufe +1,9 auf 5,0 m | 5,0 m flach; 3,0 m auf +2,2 | J1.1. Bei +1,9 auf 5,0 m bleiben 1,05 m Reserve. |
| Krabbenabprall auf Felsband (2D) | S5 per Slide-Sprung mit Doppelsprung am Gipfel | J1.3, Kopffreiheit in 2D |
| Gipfelgrat mit Kamera 8/13 | Standardverfolger | RB: hoher Verfolger gehört zu L04 |
| Lichtwechsel über `stimmung()` | Regler nach s, eine Sonne | E18 |
| CP 36/100/128/172 | 45/93/145/198,5/233,5/262 | E14 |
| Gipfel bei Y +24 | Gipfelplatte Y 18,3 | Wechten, Zapfen und Gegner brauchen ebene Stücke, die Südflanke steigt daher nur 12 → 14 |
| Gipfelgrat 45 m | 27 m | J1.12c |

**Rückfragen an den Nutzer, vor Paket A:**
- **R1 – Spurbindung in 2D (Steuerung, keine Physik).** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt, sobald der Seitenanteil ≥ 0,5 ist. CLAUDE.md bekommt dazu eine Zeile. Ohne die Spurbindung scheitern P1 und P3 bei W+D.
- **R2 – Abweichungen** aus der Tabelle oben.
- **R3 – L14** soll später seinen 2D-Eis-Bruchplatten-Teil abgrenzen (Rest aus J1.3).
- **R4 – Figur:** `cash_banooka_rc.glb` steht nicht in CREDITS und ähnelt laut zwei Berichten der ausgeschlossenen Figur. Das ist zu klären, bevor es Nachher-Bilder gibt. Selbst geprüft habe ich es nicht.

### Jury-Abgleich

| Mangel | Erledigt durch |
|---|---|
| J1.1 Reserve nur bei Doppelsprung im Scheitel | E8, Fenster bei 0,20 s in §2 und §6.2, Probe bei 0,20/0,25/0,33 s |
| J1.2 / J2.1 Tiefe in 2D | E6, E7 |
| J1.3 L14 | E15, R3 |
| J1.4 / J2.8 Bruchplatten | E11 |
| J1.5 / J2.17 Zapfen | E12 |
| J1.6 / J2.16 Gegner | E13, Tabelle in §6.4 |
| J1.7 / J2.3 Kehre | E3, E17, §7.5 |
| J1.8 Gipfelkamera | E16; Kisten am Gipfel bei \|q\| ≥ 2,2; `pruefprofil` „sicht“ |
| J1.9 / J2.5 Auftakt | 10 m Vorlauf, `blick_hoehe` 3,0: Füße bei −30,5°, Bildunterkante −39,5° (R) |
| J1.10 Blenden | E5, leere Fenster |
| J1.11 Gefahren nach CP4 | CP5 vor P3. P3 landet auf Fels, nicht auf einer Wechte. |
| J1.12 Leitidee | E10, E8, Gipfelstufe |
| J1.13 / J2.13 Widersprüche | dieser Entwurf, Konstanten in level02.gd |
| J1.14 Hinweis | E9 |
| J1.15 Biwak im 2D-Bild | drehende Blende erst 4,6 m nach Ecke A. Gerechnet: Biwakpunkte liegen bei s 63–70 außerhalb des Kegels. §7.5. |
| J1.16 Signatur | E3 |
| J1.17 Kleinkram | Steigung auf `boden_bei` ≤ 15 %. Überhänge ≥ 5,0 m über der Decke (Kopf beim Doppelsprung 4,52 + 0,5). Nach der Wechtenreihe kein Gegner. Kein Anker. |
| J2.2 / J2.12 Anker | E5, E7 |
| J2.4 Licht | E10, E18, §8.2 |
| J2.6 Budget | E19, Graubau-Messung in B1 |
| J2.7 Warnung | E11 |
| J2.9 Scheinboden | Krone = Südweg + 3 (§3), Strahlprobe in B2 |
| J2.10 Aufwand, Ladezeit | Ziel ≤ L01, B in vier Durchläufe geteilt |
| J2.11 Sprungprobe | §9.3: 1 Bild vor dem Doppelsprung loslassen, Fenster als Einheit |
| J2.14 Schattennaht | E18 |
| J2.15 15-%-Regel | Steigung auf `boden_bei` gerechnet |
| J2.18 Assets | §8.4 |
| J2.19 Figur | R4 |

---

## 2. Feste Größen und Rechenwerte

**Physik** (unverändert, CLAUDE.md): G −38, JUMP_V 12,2, JUMP_CUT 0,45, DJUMP_V 10,5, RUN 8,5, AIR_CTRL 0,82 (6,97 m/s in der Luft, ohne Trägheit, player.gd:189-209), SLIDE 13,5/0,42 s, SLIDEJUMP_V 14,5, SLAM −30, Spin 0,55 s / 1,7 m. Es gibt weder Coyote-Zeit noch Sprungpuffer (player.gd:167/240).

**Höhen bei 60 Hz** (`sprung.py`): Einfachsprung 1,86. Doppelsprung im Scheitel 3,21, am besten 3,22. Slide-Sprung 2,65. Slide-Sprung mit Doppelsprung 4,01. Abprall (14) 2,46, mit Doppelsprung 3,83.

**Weite Mitte zu Mitte** (Absprung an der Kante, Taste gehalten, 1 Bild vor dem Doppelsprung losgelassen):

| Δh | Einfach | Doppel bei 0,15 / 0,20 / 0,25 s | Doppel im Scheitel | bester Doppelsprung |
|---|---|---|---|---|
| −2,0 | 5,35 | 6,40 / 6,86 / 7,26 | 7,87 | 9,24 |
| 0 | 4,38 | 5,56 / 6,05 / 6,47 | 7,08 | 8,13 |
| +0,5 | 4,07 | 5,31 / 5,81 / 6,24 | 6,85 | 7,80 |
| +1,0 | 3,69 | 5,02 / 5,54 / 5,98 | 6,60 | 7,41 |
| +2,2 | – | 4,06 / 4,70 / 5,19 | 5,83 | 6,36 |

**Absprungfenster in m vor der Kante, Landekante 0,27:**

| Fall | Doppel 0,15 / 0,20 / 0,25 / 0,33 s | Touch 0,10 + 0,10 s | Stick 20° / 30° / 45° | Doppelsprung-Zeitbereich an der Kante |
|---|---|---|---|---|
| 5,0 flach (F1, P1, P3) | 0,85 / **1,30** / 1,75 / 2,35 | 1,20 | 1,95 / 1,40 / 0,25 | 0,08–0,65 s |
| 5,5 flach (verworfen) | 0,35 / 0,80 / 1,25 / 1,85 | 0,70 | 1,45 / 0,90 / – | 0,12–0,65 s |
| 3,0 auf +2,2 (P2) | 1,35 / **2,05** / 2,50 / 3,05 | 1,70 | 3,25 / 2,80 / 1,80 | 0,10–0,53 s |
| 4,5 auf +1,9 (verworfen) | 0,20 / 0,75 / 1,20 / 1,80 | 0,55 | – | 0,15–0,57 s |

Der Touch-Fall rechnet mit Jump-Cut beim Loslassen zwischen den beiden Tipps. Die Stickwinkel gelten mit Doppelsprung im Scheitel, bei P2 mit dem besten Zeitpunkt.

**Weitere Werte:**
- **Gipfelstufe +2,2 ohne Lücke:** Ab Doppelsprung nach 0,20 s gelingt der Absprung bis 4,95 m vor der Wand. Der Einfachsprung gelingt nie.
- **Eis, Ausrollen aus vollem Lauf:** Glätte 0,7 → 0,28 m, 0,85 → 0,61 m, 0,95 → 1,42 m. Die Jury nennt bis zum Stillstand 1,61 m.
- **Wechte** (2,3 m Deck, Kapsel 0,76 m): Beim Laufen steht man 0,36 s darauf, im Flug 0,44 s. Die Warnzeit ist 0,6 s. Die Reihe aus 4 Wechten ist 10,4 m lang und in 1,22 s überlaufen.
- **Tropfzapfen** (Radius 0,7 + Kapsel 0,38): Die Gefahrstrecke ist 2,16 m lang und in 0,25 s durchlaufen. Wer sie innerhalb von 1,60 s nach dem Ende der Gefahrphase betritt, ist sicher.

**Breiten:**

| Abschnitt | Breite der Decke | Begehbar |
|---|---|---|
| Biwak | 9 m, mit Bucht am Kistenfels | ganze Breite |
| Hüttenweg | 4 m | ganze Breite |
| 2D-Simse | 2,8 m sichtbar | 1,1 m zwischen den Leitlinien ±0,55 |
| Scharte | 3,4 m, beidseitig Fels | ganze Breite |
| Gipfelgrat | 6 m, offen | ganze Breite |

**Kamera:** fov 60 senkrecht (91,5° waagerecht bei 16:9). Seitenansicht mit 16,5 m Abstand, 3,0 m über der Kurve, Neigung −7,3°. Das Bild zeigt Weg −8,4 bis +10,4 m, ist etwa 34 m breit, und eine Kiste nimmt etwa 6 % der Bildhöhe ein.

**Ebenen:** 1 = Decke, Fangleiste, Mulden, Wechten, Kisten und Firndecke. 4 (Wert 8) = Sichtsperre. 5 (Wert 16) = Leitlinien, Kistenfels, Gipfelzacke und Gipfelplatte (Player-Maske 17).

---

## 3. Verlauf

`LevelWerkzeuge.kurve_aus_punkten(PUNKTE, 0.45)`. Bögen bekommen Punkte alle 15° oder enger, Geraden einen Anschlusspunkt 2 m vor und nach jedem Bogen. Ohne diese Punkte knickte die Kurve am Bogenanfang (gerechnet: Gier sprang um 20°).

| Stück | Punkte (x, z), Y siehe unten | s |
|---|---|---|
| Vorlauf + Biwak, Kurs 160° | (−12,11/−52,69) · (−8,01/−41,41) · (−3,90/−30,13) · (−1,17/−22,62) · (−0,48/−20,74) | 0 · 12 · 24 · 32 · 34,0 |
| Ecke A, rechts r 8, 110°, Mitte (−8/−18), 340° → 450° | 8 Bogenpunkte bis (−8/−10) | 34,0 → 49,4 |
| Nordgerade, Kurs W, z −10 | x −10 · −22 · −34 · −46 · −58 · −70 · −80 · −89,62 · −91,62 | 51,6 … 133,2 |
| Ecke 1, links r 6, Mitte (−91,62/−4), 270° → 180° | 6 Bogenpunkte bis (−97,62/−4) | 133,2 → 142,6 |
| Sonnentor, Kurs S | (−97,62/−2) · (−97,62/0) | 142,6 → 148,6 |
| Ecke 2, links r 9, Mitte (−88,62/2), 180° → 90° | 6 Bogenpunkte bis (−88,62/11) | 148,6 → 162,8 |
| Südgerade und Gipfel, Kurs O, z +11 | x −86,62 · −76 · −64 · … · 32 · 35,83 | 164,8 … 287,3 |

Nachgerechnet: Länge 287,3 m. Die Nordgerade weicht 0,008 m ab, die Südgerade 0,000 m.

**Y-Stützwerte der Kurve** (s, Y): (0, 0) (32, 0) (36, 1,0) (45, 1,0) (49, 2,0) (54, 2,0) (63, 3,0) (79, 3,0) (81, 4,0) (117, 4,0) (121, 6,2) (127, 6,2) (129, 7,2) (133, 7,6) (142,4, 8,4) (148,4, 8,4) (162,5, 11,0) (167, 11,4) (176, 12,0) (194, 12,0) (197, 13,0) (224, 13,0) (227, 14,0) (251, 14,0) (260, 14,6) (270, 14,6) (272, 15,6) (276, 15,6) (278,5, 16,1) (282, 16,1) (284, 18,3) (287, 18,3).
- Die Decke liegt auf Terrassen (`hoehe`/`hoehe_ende`, `stufen_kollision`) und weicht von der Kurve höchstens 0,8 m ab.

**Gratkrone (Höhenmodell, Pflicht):**
- Allgemein Krone = Südweg + 3 m. Zwischen x −25 und −10 sind es Südweg + 4,5 m, damit das Biwak ab s 16 sicher im Schatten liegt.
- Daraus folgt über der Nordflanke eine Wand von etwa 14 m am Anfang und etwa 7 m an der Scharte. Ab s ≈ 90 erscheint die Krone im 2D-Bild.
- Der Südweg bleibt hinter der Krone verdeckt. Das verhindert den Scheinboden (J2.9).

**Gerechnet (`verlauf_final.py`):**
- **Feuer:** Bei s 10 steht es 81 m entfernt, 9,8° hoch und 18° links. Die Bildoberkante liegt mit `blick_hoehe` 3,0 bei +20,5°, mit dem Standardverfolger bei s 30 bei +13,5° (Feuer bei 12,7°).
- **Sonne 205°/22°:** Der Strahl kreuzt die Gratachse
  - vom Start aus 19,3 m hoch (Krone 16, also Sonne),
  - ab s 18 in 15,9 m Höhe oder tiefer (Krone ≥ 17, also Schatten),
  - von der Nordflanke aus 7,8–13,9 m hoch (Schatten).
- Die Scharte (Krone 9–10) lässt Licht durch.

---

## 4. Abschnittstabelle

| s | Stück | Y (Decke) | Breite | Kamera | Inhalt |
|---|---|---|---|---|---|
| 0–10 | Vorlauf | 0 | 9 | K1 Auftakt | Schneewall, Querleitlinie bei 1 |
| 10–15 | Biwakstart (Sonne) | 0 | 9 | K1 | Start 10, Startportal 11, Kistenreihe 13 (3) |
| 15–19 | Eispfütze (Schattenkante ≈ 16) | 0 | 9 | K1 | Glätte 0,7 |
| 18–26 | – | – | – | Blende K1 → K2 (nur `blick_hoehe`) | – |
| 20–23 | Kistenfels S1 | 0, Fels +2,6 | Bucht q +3,6…+6,0 | – | Hinweis bei 18 |
| 23–32 | Krabbenfeld | 0 | 9 | K2 | Krabbe 25,5–29,5 |
| 34 | Stufe +1,0 | 1,0 | – | – | Ecke A beginnt |
| 34–49,4 | Ecke A | 1,0 → 2,0 (Stufe 47) | 9 → 4 | K2 | Wiesel 37–42, **CP1 45** an der Hütte (außen) |
| 49,4–54 | Hüttenweg | 2,0 | 4 | K2 | Kisten 50,5 (2) |
| 54–63 | Blende 3D → 2D, drehend | 2,0 → 3,0 | Trichter → ±0,55 | K2 → K3 | leer |
| 63–66 | Nordflanke | 3,0 | 2,8 | K3 Seite N | Kisten 64,0 / 65,2 |
| 66–76 | Eisband | 3,0 | 2,8 | K3 | Glätte 0,85 |
| 76–79 | griffig, Stufe +1,0 bei 79 | 3,0 → 4,0 | 2,8 | K3 | – |
| 79–86 | Lehrsims | 4,0 | 2,8 | K3 | Hinweis bei 80, Kiste 81,0 |
| 86–91 | **F1** Fanglücke 5,0 | Fangleiste 2,0 (Eis 0,85) | – | K3 | Rückstufe 3,0 bei 86–87,5, S2: Kisten 88,8 / 90,0 |
| 91–100 | Felsnase | 4,0 | 2,8 | K3 | **CP2 93,0** |
| 100–105 | **P1** 5,0 flach | – | – | K3 | Doppelbogen aus Früchten |
| 105–108 | Landeeis | 4,0 | 2,8 | K3 | Glätte 0,85 |
| 108–116 | Mottensims | 4,0 | 2,8 | K3 | Motte 109–113 |
| 116–119 | **P2** 3,0 auf +2,2 | – | – | K3 | – |
| 119–122 | Landung | 6,2 | 2,8 | K3 | – |
| 122–127 | Eismulde S3 | 6,2, Mulde 5,6 | 2,8 | K3 | Eis 0,95 auf 123–126, Motte 122,5–126,5, Kisten 124,0 / 125,2 |
| 127–133 | Stufe +1,0 bei 129 | 7,2 → 7,6 | 2,8 | K3 | Kiste 130,5, Fruchtkiste 131,5 |
| 133,2–142,6 | Eckblende (Ecke 1) | 7,6 → 8,4 | Trichter → 3,4 | K3 → K4 | leer; außen Leitlinie und Felswulst ≤ 1 m |
| 142,6–148,6 | Sonnentor | 8,4 | 3,4 | K4 Scharte | **CP3 145** mit Steinmann, Lichtschwelle bei 144 |
| 148,6–162,8 | Ecke 2 | 8,4 → 11,0 (18 %) | 3,4 | K4 | Kisten 151 / 156 und Fruchtkiste 160,5 (alle q +1,0) |
| 162,8–167 | Südaustritt | 11,0 → 11,4 | 3,4 | K4 | Kiste 165,5 |
| 167–176 | Blende 3D → 2D, drehend | 11,4 → 12,0 | Trichter | K4 → K5 | leer |
| 176–186 | Wechtenlehre | 12,0 | 2,8 | K5 Seite S | Kisten 177,5 / 178,7, Lehrwechte 180,5–182,8 über Mulde −0,5, Kiste 183,8 auf Fels |
| 186–194 | Zapfenlehre | 12,0 | 2,8 | K5 | Schutz 187,5, Wartefläche 188,5–190,5, **Z1** bei 192,0 |
| 196 | Stufe +1,0 | 13,0 | – | – | – |
| 196–203 | Vorplatz | 13,0 | 2,8 | K5 | **CP4 198,5** |
| 203–213,4 | **Wechtenreihe** | 13,0 | 2,8 | K5 | 4 × 2,3 m, Fugen 0,4, über dem Abgrund |
| 213,4–224 | Krabbenband | 13,0 | 2,8 | K5 | Krabbe 218–222 |
| 224,5 | Stufe +1,0 | 14,0 | – | – | – |
| 225–233 | Zapfenwarte | 14,0 | 2,8 | K5 | Wartefläche 226–228,5, **Z2** bei 230,0 |
| 233–238 | Anlauf | 14,0 | 2,8 | K5 | **CP5 233,5** |
| 238–243 | **P3** 5,0 flach | – | – | K5 | – |
| 243–251 | Firnstück | 14,0 | 2,8 | K5 | Firnloch S4 245,5–248,5 (−1,2), Kiste 249,8 |
| 251–260 | Gipfeltor, Blende 2D → 3D, drehend | 14,0 → 14,6 | Trichter → 6 | K5 → K6 | leer; außen Torzahn ≤ 1 m und Leitlinie bis 264 |
| 260–266,5 | Gipfelgrat | 14,6 | 6, offen ab 264 | K6 | **CP6 262** (q −1,5), Kisten 264,5 (q ±2,2) |
| 266,5–269 | G-a 2,5 flach | – | – | K6 | – |
| 269–276 | Zackenstufe | 14,6 → 15,6 (Stufe 271) | 6 | K6 | S5 Gipfelzacke 272,5–274,5, q −2,0…−3,4, Oberkante 19,0 |
| 276–278,5 | G-b 2,5 auf +0,5 | – | – | K6 | – |
| 278,5–282 | Anlauf | 16,1 | 6, Leitlinien | K6 | – |
| 282 | **Gipfelstufe** +2,2 (Doppelsprung) | 18,3 | – | K6 | – |
| 282–287 | Gipfelplatte | 18,3 | 6 | K6 | Lebenkiste 284,0 (q +2,0), Ziel 285,0, Gipfelfeuer bei `punkt_frei(289)` |

In 2D liegen 145 m (52 %), mit den halben Blenden 166 m (60 %).

---

## 5. Die Abschnitte im Einzelnen

### A · Biwak (0–63): „Ziel vor Augen“
- **Spiel:**
  - Kistenreihe, dann die Eispfütze genau an der Schattenkante (kalt = glatt).
  - Kistenfels: Ein Hinweis bietet den Doppelsprung an. Der Einfachsprung kommt nicht auf 2,6 m, der Doppelsprung schon (Zeitbereich 0,15–0,48 s, Reserve 0,62).
  - Krabbe und Wiesel sind aus L01 bekannt (Draufspringen, Slide). CP1 an der Hütte.
- **Bild:**
  - Start in der Sonne, danach blauer Schatten. Vorn links leuchtet der goldene Gipfel mit dem Feuer.
  - Die Rauchfahne steigt 6–8 m senkrecht und knickt dann mit dem NO-Wind nach SW ab.
  - Die Nordwand des Grats steht als Eisfall im Schatten. Das Simsband der Nordflanke ist schon als helle Linie zu sehen.
  - Die Baumgrenze ist nur hier: Kiefern, nördlich und östlich des Wegs.
  - Hütte prozedural: Trockenmauer aus `Findling.brocken` (findling.gd:152), Firstbalken aus `Riesenstamm.liegend` (riesenstamm.gd:209), Schneedach, warmes Fenster, Kaminrauch.
- **Frei halten:**
  - Innenseite von Ecke A: Kreis r 6 um (−8/−18) bis Weg + 1 m. Dort liegen die Sehne und die Bahn der drehenden Blende.
  - Westteil x −16…−4, z −27…−10: höchstens Weg − 1,5 m. Das ist der Vordergrund der Seitenkamera.

### B · Nordflanke (63–133, 2D): „Die kalte Wand“
- **Spiel:**
  - Eisband zum Spüren, Stufe, dann Hinweis und F1 über der vereisten Fangleiste.
  - Von der Leiste kommt man über zwei Stufen zurück oder per Doppelsprung (+2,0, Scheitel 3,22) direkt hinauf.
  - CP2, dann P1 (Pflicht).
  - Landung auf Eis, die Motte auf griffigem Grund, dann P2 als Aufstieg.
  - Eismulde mit Motte 2 und Kisten: Drehschlag auf Eis, gefahrlos, keine Kante in der Nähe.
- **Bild:**
  - Die Wand füllt das Bild bis s ≈ 90. Danach kommt die Krone dazu, die Sonne steht knapp über der Krone oben rechts (Gegenlicht), der Weg bleibt im Schatten.
  - Gefrorener Fall bei s 70–90 (`Wasserfall.band`, wasserfall.gd:196, Eisfarben, Tempo 0; ungeprüft), an seinem Fuß eine Kristallader.
  - Blankeis-Simse: blaugrüne, durchscheinende Stirn mit Glanzkante, ohne Schneekappe.
  - Schneesimse: runde weiße Kappe über grauem Fels.
  - Lücken: Die Kappe bricht ab, eine Lippe mit Zierzapfen hängt unter der Weghöhe, dahinter läuft eine dunkle senkrechte Rinne.

### C · Scharte (133–176): „Das Sonnentor“
- **Spiel:** ummauert und ohne Gefahr. CP3 mit Steinmann, ein paar Kisten außen in Ecke 2. Zum Luftholen.
- **Bild:**
  - Zwei Felstürme. Am Boden kippt bei s 144 eine Schattenkante von Blau nach Gold (Lichtschwelle). Die Sonne selbst ist nicht im Bild, die Bildoberkante liegt bei +10,5°.
  - Lichtschacht durch das Tor (lichtschacht.gd).
  - Steinmann mit Wimpel, Fahnenshader wie im Portalraum.
  - Kür: Silhouette des Weltenbaums im SSW, als Fernform mit 2–3 Draw-Calls. Optional.

### D · Südflanke (176–251, 2D): „Die warme Seite“
- **Spiel:**
  - **Lehrwechte über einer Mulde:** Wer an der Kiste stehen bleibt, sackt 0,5 m ab und hat dabei gesehen, wie die Warnung aussieht.
  - Schutzkiste, dann der erste Zapfen mit Wartefläche. Regel: warten, bis er gefallen ist, dann durch.
  - CP4, dann die **Wechtenreihe**: nicht stehen bleiben.
  - Krabbe, der zweite Zapfen, CP5, dann **P3**. Danach das Firnloch S4 für den Bauchplatscher.
- **Bild:**
  - Frontlicht, niedrige Krone mit Wechtenkämmen, oben etwa 30 % Tiefblau. Die Rauchfahne kommt von rechts herein.
  - Im Spielband (Weg −1…+5 m) liegen nur Schnee und Blauschatten. Warmer Fels erst ab Weg + 4 m, damit Kisten und Früchte Kontrast behalten.
  - Wechten: eingerollte Schneezungen mit blauer Unterseite, darunter Luft und ihr Schatten an der Wand.
  - Zapfen hängen an Felsdächern ≥ 5,0 m über der Decke und sind dreimal so groß wie Zierzapfen. Am Aufschlagpunkt liegt dauerhaft ein Splitterstern.

### E · Gipfelgrat (251–287): „Das Feuer“
- **Spiel:**
  - Gipfeltor (außen geschlossen), CP6, dann G-a und G-b als Einzelsprünge.
  - S5: Slide-Sprung mit Doppelsprung auf die Zacke.
  - Zum Schluss die Gipfelstufe mit Doppelsprung. Wer sie verfehlt, fällt nur zurück auf die Terrasse.
- **Bild:**
  - Ein 6 m breites, helles Band mit Felszähnen an den Scharten und Schneestangen mit roter Spitze statt Warnpfosten.
  - Talseitig Nebelbänke, dazwischen Gletscher (N) und Wald (S).
  - Auflicht von rechts hinten. Das Feuer steht vor kühlem Osthimmel.
  - Feuerring aus `Findling.kranz` (findling.gd:189). Flammen als MultiMesh mit einer Kopie des Hub-Shaders (hub.gd:262ff), Funken über `Staub`. Der Schein ist eine additive Scheibe statt eines OmniLights.

---

## 6. Spiel

### 6.1 Lehrfolge
1. Kistenreihe (13).
2. Eispfütze an der Schattenkante.
3. **Doppelsprung angeboten:** Kistenfels mit Hinweis.
4. Krabbe (Draufspringen) und Wiesel (Slide).
5. CP1, dann die Seitenansicht.
6. Eisband.
7. **F1 gefahrlos:** Wer weiter will, braucht den Doppelsprung.
8. CP2.
9. **P1 gefordert.**
10. Motte auf griffigem Grund.
11. **P2 gefordert (Aufstieg).**
12. Motte über Eis.
13. Scharte und CP3: Licht wird warm.
14. **Lehrwechte gefahrlos.**
15. Zapfen mit Schutzkiste.
16. CP4.
17. **Wechtenreihe gefordert.**
18. Krabbe und Zapfen 2.
19. CP5.
20. **P3.**
21. Firnloch.
22. Gipfelgrat mit Einzelsprüngen, Gipfelstufe mit Doppelsprung zum Feuer.

### 6.2 Sprungtabelle (Pflicht)

| Stelle | s | Art | Lücke | Δh | Reichweite (Scheitel / bester) | Reserve | Fenster bei Doppel 0,20 s | Touch 0,10 + 0,10 | griffiger Anlauf |
|---|---|---|---|---|---|---|---|---|---|
| Stufen | 34, 47, 79, 129, 196, 224,5, 271 | Einfach | 0 | +1,0 | Scheitel 1,86 | 0,86 | – | – | – |
| F1 (angeboten) | 86–91 | Doppel / Fang | 5,0 | 0 (Leiste −2,0) | 7,08 / 8,13 | 2,08 | 1,30 | 1,20 | 7 m |
| P1 | 100–105 | Doppel | 5,0 | 0 | 7,08 / 8,13 | 2,08 | 1,30 | 1,20 | 6 m |
| P2 | 116–119 | Doppel, Höhe | 3,0 | +2,2 | 5,83 / 6,36 | 2,83 | 2,05 | 1,70 | 3 m |
| Wechtenreihe | 203–213,4 | Lauf | 4 × 2,3 | 0 | 0,36 s je Wechte | 0,24 s Puffer | – | – | 4,5 m |
| P3 | 238–243 | Doppel | 5,0 | 0 | 7,08 / 8,13 | 2,08 | 1,30 | 1,20 | 4 m |
| G-a | 266,5–269 | Einfach | 2,5 | 0 | 4,38 | 1,88 | – | – | 4 m |
| G-b | 276–278,5 | Einfach | 2,5 | +0,5 | 4,07 | 1,57 | – | – | 5 m |
| Gipfelstufe | 282 | Doppel, Höhe | 0 | +2,2 | Scheitel 3,22 | 1,02 Höhe | 4,95 m | – | 3,5 m |

- Der Einfachsprung kommt über keinen Pflicht-Doppelsprung (gerechnet: nirgends erfolgreich).
- An F1 landet der Einfachsprung auf der Leiste: Weite 5,35 bei −2, er rutscht an der Gegenstirn ab.
- Eis endet überall ≥ 3 m vor einer tödlichen Kante, vor jedem Pflicht-Doppelsprung liegen ≥ 3 m griffiger Anlauf.
- Stickwinkel: Ohne R1 trägt P1/P3 bei 30° noch mit einem Fenster von 1,40 m, bei 45° nur mit 0,25 m.

### 6.3 Geheimnisse

| | Ort | Weg | Rechnung | Inhalt |
|---|---|---|---|---|
| S1 Kistenfels | 20–23, q +3,6…+6,0, +2,6 | Doppelsprung | 3,22 gegen 2,6 → 0,62 Reserve, Einfach 1,86 reicht nicht | 2 normal, 1 Fruchtkiste |
| S2 Fangleiste | 86–91, −2,0, Eis | absichtlich hinunter | zurück über +1/+1 oder per Doppelsprung | 2 normal |
| S3 Eismulde | 122–127, −0,6 | hineinrutschen | – | 2 normal |
| S4 Firnloch | 245,5–248,5, −1,2 | Bauchplatscher bricht die Firndecke (Radius 2,0, player.gd:27) | hinaus per Einfachsprung (Reserve 0,66) | 2 normal, 1 Fruchtkiste |
| S5 Gipfelzacke | 272,5–274,5, q −2,0…−3,4, +3,4 | Slide-Sprung mit Doppelsprung | 4,01 → Reserve 0,61, Doppelsprung-Zeitbereich 0,20–0,55 s. Doppelsprung allein (3,22) und Slide-Sprung allein (2,65) reichen nicht. Keine Fläche in Reichweite (Gipfelplatte 8,5 m entfernt, dahinter). | 2 normal, 1 Fruchtkiste |

### 6.4 Zählung

**Kisten (41):**

| | Biwak | Nord | Scharte | Süd | Gipfel | Summe |
|---|---|---|---|---|---|---|
| normal | 7 | 8 | 3 | 6 | 4 | **28** → 9 Zeitkisten (level_basis.gd:350-366) |
| Frucht | 1 | 1 | 1 | 1 | 1 | 5 |
| Sonder | CP1 | CP2 | CP3 | Schutz, CP4, CP5 | CP6, Leben | 8 |

Kisten werden in Streckenreihenfolge gesetzt.
- In 2D liegen sie auf q 0.
- In Ecke 2 stehen sie nur außen (q +1,0).
- Am Gipfel stehen sie bei \|q\| ≥ 2,2.
- Höhe übergeben als `boden_bei(s) − kurve_y(s)`.

**Gegner (5):**

| Gegner | s | Abschnitt | Lehre | Regel erfüllt |
|---|---|---|---|---|
| Gletscherkrabbe | 25,5–29,5 | A, ebene Terrasse 23–32 | Draufspringen | ≥ 3 m vor Stufe 34 |
| Schneewiesel | 37–42 | A, 3D | Slide | 3 m nach Stufe 34, nur in 3D |
| Frostmotte | 109–113 | B, längs | Drehschlag | 4 m nach Landung P1, 3 m vor Anlauf P2 |
| Frostmotte | 122,5–126,5 | B, über der Eismulde | Drehschlag auf Eis | keine Kante näher als 3 m |
| Gletscherkrabbe | 218–222 | D, längs | Draufspringen | 4,6 m nach der Wechtenreihe |

**Früchte (≈ 110):**
- Biwak 20, Nord 36, Scharte 10, Süd 28, Gipfel 16.
- Über F1, P1 und P3 je ein Doppelbogen (`fruechte_bogen`, korridor_level.gd:769) mit Scheiteln 1,8 und 3,2.
- Über P2 und der Gipfelstufe ein steiler Bogen bis +3,0.

### 6.5 Checkpoints
| CP | s | Ort |
|---|---|---|
| CP1 | 45 | Hütte |
| CP2 | 93 | vor P1 |
| CP3 | 145 | Steinmann |
| CP4 | 198,5 | vor der Wechtenreihe |
| CP5 | 233,5 | vor P3 |
| CP6 | 262 | Gipfeltor |

- Zwischen CP4 und CP5 liegen drei tödliche Stellen (Wechtenreihe, Krabbe, Z2), danach nur P3.
- **Nach jedem Tod** setzt `GameState.level_zuruecksetzen` (GameState.gd:17/164) alle Bruchplatten zurück.

### 6.6 Richtzeit
- Formel 287,3 / 8,5 × 2,8 = **94,5 s**, Gold 80,4 s, Platin 68,1 s (level_basis.gd:316-325). Kein `zielzeit()`-Override.
- Ein guter Lauf dauert geschätzt etwa 50–55 s (ungeprüft).

---

## 7. Kamera und Kollision

### 7.1 Kameraplan (`KAMERA` in level02.gd)

| Eintrag | s | Art | hoehe | abstand | vorlauf | blick_hoehe | seitlich | seiten_hoehe |
|---|---|---|---|---|---|---|---|---|
| K1 Auftakt | 0–18 | Verfolger | 5,6 | 9,5 | 6,0 | 3,0 | – | – |
| K2 Biwak | 26–54 | Verfolger | 5,6 | 9,5 | 6,0 | 1,0 | – | – |
| K3 Nord | 63–133,2 | Seite | – | – | – | – | +16,5 | 3,0 |
| K4 Scharte | 142,6–167 | Verfolger | 5,6 | 7,0 | 7,0 | 1,0 | – | – |
| K5 Süd | 176–251 | Seite | – | – | – | – | +16,5 | 3,0 |
| K6 Gipfel | 260–287,3 | Verfolger | 5,6 | 9,5 | 6,0 | 1,0 | – | – |

`seiten_faktor` ist überall 0,85. Die Lücken zwischen den Einträgen sind Blendfenster.

**Gerechnet:**
- **Blickrichtung (Gier):**
  - 18–26: konstant 160°.
  - 54–63: 265° → 180°.
  - Eckblende 133,2–142,6: 165°–200°.
  - 167–176: 92° → 0°.
  - 251–260: 0° → 90°.
- **Je 0,5 m Weg:** höchstens 1,87 m Kamerasprung (s 134) und 9,5° Gieränderung (s 171).
- **Drift in Ecke 2:** Die Kamera weicht ≤ 10° vom Kurs ab, in der Mitte ≤ 2°.

**Regeln, die `Kameraplan.pruefen()` meldet:**
- Ein Blendfenster ist 8–10 m lang und **leer**: keine Kiste, kein Gegner, keine Stufe, keine Lücke, kein Eis.
- Drehende Fenster liegen auf Geraden (Krümmung ≤ 3°). Ein Eckfenster liegt genau über einer 90°-Ecke, die Gierspanne der Mischkamera ist ≤ 40°.
- Die Driftseite ist geschlossen (§7.2).
- Das Vorzeichen von `abstand` wechselt nie direkt.
- 2D-Einträge: Krümmung ≤ 3°, Steigung von `boden_bei` ≤ 15 %.
- Je 0,5 m: Kamerasprung ≤ 2,0 m, Gier ≤ 10°.

### 7.2 Übergänge und Steuerung
Die Steuerung bleibt kamerarelativ (player.gd:682-701). Die Driftregel sorgt dafür, dass eine gehaltene Richtung immer in eine Wand führt:

| Blende | Art | gehaltene Richtung driftet | dort steht |
|---|---|---|---|
| 54–63 | 3D → 2D, drehend | „hoch“ nach S (Gratseite) | innere Leitlinie, Gratwand |
| 133,2–142,6 | Eckblende | „rechts“ (W) in die Außenkurve | äußere Leitlinie und Felswulst ≤ 1 m; danach führt die Linie nach S weiter |
| 167–176 | 3D → 2D, drehend | „hoch“ nach N (Gratseite) | innere Leitlinie |
| 251–260 | 2D → 3D, drehend | „rechts“ nach S (Abgrund) | äußere Leitlinie und Torzahn ≤ 1 m bis s 264 |

**Spurbindung (nur nach R1):**
- Wann: Seitenanteil des Plans ≥ 0,5 und \|x\| ≥ 0,5 · \|v\|.
- Was: Die Eingabe wird zu „Bild-rechts, auf die Tangente projiziert“, mit Vorzeichen aus x und Betrag \|v\|; die Tiefe entfällt. Sonst bleibt die Eingabe kamerarelativ, die Tiefe stößt an ±0,55.
- Abgefragt nur, wenn `has_method` an der Kamera trifft (FolgeKamera im Hub und Flugkamera in L22 bleiben unberührt).
- Ein Richtungsanker entfällt.

### 7.3 Spielergrenze (Leitlinien, Ebene 16)
| Abschnitt | Leitlinien |
|---|---|
| Biwak | ±4,5 mit Bucht um den Kistenfels; Querlinie bei s 1 |
| Ecke A | auf 4 m verengt |
| Trichter 54–63 und 167–176 | ±Rand → ±0,55 |
| Nord und Süd (2D) | ±0,55 durchgehend, auch über Lücken; an F1 mit `unten` 3 bis zur Leiste |
| Eckblende | außen bis ±1,7 geweitet |
| Scharte | ±1,7 |
| Gipfeltor | außen bis s 264 |
| Gipfel 264–278,5 | offen |
| Gipfel 278,5–287 | ±3,0, dazu eine Querlinie hinter dem Feuer |

### 7.4 Todeszonen (`todeszone()`, level_werkzeuge.gd:1147, Gruppe `todeszonen`)
Nicht über `absturzzonen()`: Deren Kästen sind 60 m breit und reichten bis auf die andere Flanke.

| Zone | s | quer | Oberkante | unten |
|---|---|---|---|---|
| T-Nord | 79–133 | −3…+40 | Boden − 8 (−4,0 → −0,4), unter F1 ≤ −0,5 | −30 |
| T-Süd | 176–251 | −3…+40 | Boden − 8 (4,0 → 6,0) | Boden − 20 |
| T-Gipfel | 264–287 | ±3,2…±40, unter G-a und G-b volle Breite | Boden − 6 | Boden − 20 |

- Biwak, Scharte und die Nordflanke bis s 79 haben keine Lücke und bekommen keine Zone.
- **Sturzproben bei q +26** (level_check.gd:433-443, gerechnet):
  - s 10 / 45 außerhalb jeder Kollision → TODESHOEHE.
  - s 90 → T-Nord.
  - s 135 außen im Leeren → TODESHOEHE.
  - s 180 / 225 → T-Süd.
- Keine Überschneidung mit Biwak, Fangleiste, Mulden oder Firnloch. Prüft die Todeszonenprobe.

### 7.5 Sichtregeln
- **Scharte:**
  - Was höher als Weg + 1,5 m ist, liegt im Kreis r 8 um (−84,7/0). Dieser Kern trägt die Sichtsperre (Ebene 4).
  - Die Sehnenhülle (q ±1,3, s 128–180) hält ≥ 0,9 m Abstand. Am nächsten kommt sie am Mittelpunkt von Ecke 2 (r 5,31, 3,3 m hoch) und an Ecke 1 (r 2,55).
  - Der Westturm steht bei x ≤ −99,3 und z ≥ −6. Die Eckblende-Kamera fährt bei z ≤ −10,6 vorbei.
- **Eckblende:** Die Kamera fährt 1,3–14,4 m außen und 3,3–5,6 m über dem Weg. Dort steht nichts über Weg + 1 m.
- **2D-Streifen:** Zwischen q +0,6 und +16,5 und von Weg + 1 bis + 5 m liegt nichts auf 1\|8. Sichtbare Deko liegt dort ≤ Weg − 1,5 m (V0).
- **Sichtachse Start → Feuer** frei. Das prüft ein Strahl in B2.

---

## 8. Bild

### 8.1 Bildgesetze
1. Was trägt, hat Fels darunter. Was bricht, hat Luft darunter.
2. Schatten heißt kalt und glatt, Sonne heißt warm und brüchig. Dazu gehört: Das Biwak liegt ab s 16 im Schatten.
3. Der Wind kommt immer aus NO. Rauch, Schneefahnen und Treibschnee ziehen nach SW.
4. In 2D ist die einzige helle Waagerechte im Bereich Weg ±3 m begehbar. Schneebänder in der Wand liegen schräg oder ≥ 4 m über dem Weg.
5. Die Tiefe ist sichtbar: Fels, Gletscher und Wald, nur durchbrochene Nebelbänke.

Palette wie im Bildkonzept:

| Fläche | Farbe |
|---|---|
| Sonnenschnee | (0,95/0,92/0,86) |
| Schattenschnee | `Farben.SCHNEE_SCHATTEN` |
| Blankeis | (0,30/0,52/0,58) |
| Frostfels im Schatten | (0,16/0,20/0,28) |
| Frostfels in der Sonne | warmgrau (0,58/0,52/0,46) |
| Akzente | ≤ 6 % der Fläche |

### 8.2 Licht und Farbe
- **Sonne:** Azimut 205°, Höhe 22°, Farbe (1,0/0,87/0,68).
  - Am Rechner zwei Schattenstufen, die erste ≥ 32 m (J2.14), 70 m weit, im Web 60 m.
  - Auf dem Handy eine Stufe bis 50 m (level_basis.gd:263-266).
  - Ein **Schattenkamm** (SHADOWS_ONLY, grob) verschattet Biwak und Nordflanke.
- **Himmel** `himmel.gdshader`:
  - Zenit (0,10/0,26/0,58), Horizont (0,62/0,72/0,84), Dunst (0,70/0,78/0,88), Boden (0,34/0,42/0,52).
  - Schein (1,0/0,78/0,52), `hof_staerke` 0,5, `wolken_menge` 0,62, Fernkette über `huegel_hoehe`.
- **Umgebung:** Kontrast und Sättigung 1,0 statt 1,14 und 1,2 (Level02.tscn:38-41). Keine OmniLights außer an den Portalen.
- **Tiefennebel** (`fog_mode` 1): Beginn in 3D 20 m, in 2D 28 m, Ende 200 m. `sun_scatter` 0,6 ist im Compatibility-Renderer ungeprüft.
- **Stimmungsregler nach s:**

| Zone | s | Nebel | Umgebung | Sonnenenergie | Bildrahmen |
|---|---|---|---|---|---|
| A Sonne | 0–14 | (0,70/0,76/0,84) | (0,66/0,68/0,74) | 1,0 | Stärke 0,3 |
| A Schatten | 20–54 | (0,62/0,72/0,84) | (0,56/0,64/0,80) | 0,6 | 0,3 |
| B | 63–128 | (0,56/0,68/0,84) | (0,52/0,64/0,86) | 0,55 | 0,3, `licht_ort` (0,9/−0,2) warm 0,15 |
| C | 140–167 | (0,80/0,76/0,70) | (0,70/0,68/0,66) | 1,0 | 0,25 |
| D | 176–251 | (0,74/0,78/0,86) | (0,74/0,66/0,56) | 1,1 | 0,25 |
| E | 260– | (0,78/0,80/0,88) | (0,78/0,70/0,62) | 1,0 | 0,3 |

  Zwischen den Zonen wird über s überblendet. Die Sonnenenergie sichert den Lichtwechsel auch dort, wo der Handy-Schatten nicht hinreicht.
- **Farbziele** (kontaktbogen.py):

| Abschnitt | kühl | warm | Sonst |
|---|---|---|---|
| A | ≥ 30 % | ≤ 25 % | – |
| B | 40–70 % | ≤ 15 % | größte dunkle Fläche ist die Wand |
| C | – | 20–45 % | – |
| D | ≥ 30 % | ≤ 45 % | dunkle Fläche ≥ 20 % (Abweichung vom L01-Vertrag ≥ 25 %) |
| E | – | ≤ 35 % | – |

  In jedem Bild ist die Weg-Luma am höchsten.

### 8.3 2D-Staffel

| Ebene | Abstand | Inhalt | Luma |
|---|---|---|---|
| V0 | 4–10 m | Felsnadeln und Krummholz, ≤ Weg − 1,5, ohne Kollision | ≤ 0,15 |
| V1 | 16,5 m | Simse mit Lippe 0,1–0,25 m über der Stirn, Wechten, Spielobjekte | Kappe am hellsten |
| V2 | 17–24 m | Gratwand mit Relief, Eisvorhängen, schrägen Rinnen, Kristallen (MultiMesh, selbstleuchtend 1,4–2,0) | Nord 0,18–0,32 |
| V3 | – | Krone mit Wechtenkämmen und Schneefahnen | – |
| V4 | 60–190 m | Gipfelring, Rauchfahne | – |
| U | Weg − 2 und tiefer | Felsstirn bis in den Dunst | – |

Flocken nur in V0.

### 8.4 Modelle (nur CC0)

| Rolle | Quelle | Lizenz und Stand |
|---|---|---|
| Kiefern (Biwak), 25–30 Stück, Sichtweite 90 m | Quaternius Ultimate Nature Pack `PineTree_1/2/3/5` | CC0, `assets/modelle/natur2/unp/`, steht in CREDITS |
| Totholz, Krummholz | UNP `CommonTree_Dead_1/2` (Repo), `_3–5` (Scratchpad `modelle/fbxprojekt/glb/`) | CC0; 3–5 importieren, CREDITS ergänzen |
| Felsen | UNP `Rock_1–7` (Scratchpad) | CC0; importieren, CREDITS.md:12 zählt Dateien einzeln auf, also ergänzen |
| Simse, Kistenfels, Zacke, Hüttenmauer, Feuerring | `Findling.netz/brocken/kranz` | eigener Code |
| Hüttenbalken | `Riesenstamm.liegend` | eigener Code |
| Ferntannen | Fernform nach dem Muster `L01Wald._fernbaum` | eigener Code |
| Schnee-, Firn- und Eistexturen | Materialbibliothek (prozedural, materialbibliothek.gd:366-745) | eigener Code |

- **Nicht verwendet:** Kenney `tree_cone` und `rock_*` (grüne Kappen), das Holiday Kit, `campfire_stones` (nicht im Repo), die UNP-Modelle `*_Snow` (Drive meldet „Quota exceeded“).
- **Schnee auf Modellen und Kanten ist neuer Code** (S):
  - Eine Schneetextur für den Moos-Kanal mit demselben Alpha (fels_schichten.gdshader:151-153, 182-186).
  - Eine Schneemaske nach Welt-oben für Felsmodelle (fremdmodelle.gd:820) und Kronen.

---

## 9. Technik

### 9.1 Level-02-Dateien
- **`level02.gd`** (`Level02 extends KorridorLevel`):
  - Konstanten `PUNKTE`, `Y_KURVE`, `ABSCHNITTE`, `LUECKEN`, `BEGEHBARES`, `LEITLINIEN`, `TODESZONEN`, `KISTEN`, `GEGNER`, `FRUECHTE`, `KAMERA`, `STIMMUNG`, `SICHTGRUPPEN`.
  - Abfragen über `Wegdaten`.
  - `_bauschritte`, `pruefprofil()` = {sicht, gefaelle, todeszonen, rand, kameraplan} und `sprungfaelle()`. Die beiden müssen im Levelskript stehen (pruefe.sh:116-118, level_check.gd:1223).
- **Module in `scenes/levels/level02/`:** Zustand in Instanzen, Zufall über `PropWerkzeug.zufall`, nie `seed()`.
  - `grat.gd`: `GelaendeSaum` mit FELS_AUF, FELS_AB und STIRN, Schneestoff.
  - `massiv.gd`: `GelaendeFeld` für Grat, Kar, Täler und Gipfelring, Nebeltafeln, Schattenkamm.
  - `wegbauten.gd`: Simse, Kistenfels, Hütte, Steinmann, Tor, Gipfelzacke, Gipfelfeuer.
  - `eis.gd`: Eisdecken, Wechten-Optik, Zapfen-Optik, Kristalle.
  - `bewuchs.gd`: `Waldsetzer` mit Kiefern, Totholz und Felsen.
  - `stimmung.gd`: Regler, Treibschnee (`Laubtreiben`, Wind nach SW), Rauchband, Funken.
- **Bauschritte** in Reihenfolge, der Verlauf entsteht vor der Liste (wie level01.gd:878):
  1. Weg
  2. Grat
  3. Massiv
  4. Begehbares, Leitlinien, Zonen
  5. Wegbauten
  6. Kisten, Gegner, Früchte, Portale
  7. Eis
  8. Bewuchs
  9. Stimmung
  10. Kameraplan und Sichtgruppen

### 9.2 Gemeinsame Bausteine (`scripts/gemeinsam/`, Stufe A, kopiert)

| Baustein | Herkunft | Inhalt |
|---|---|---|
| `wegdaten.gd` | level01.gd:1383-1869 | `boden_bei`, `breite_bei`, `weg_punkt`, `strang_bei`, `begehbar`, `rand_profil`; Bau von Korridor, Leitlinien und Zonen |
| `wegdecke.gd` | boden.gd | `wegboden`-Stoff mit Zwischenspeicher **je Level und Abschnitt**, wegen 8 Lücken je Stoff (wegboden.gdshader:79). Nie `L01Boden.stoff`, weil boden.gd:44 nur nach Art speichert. |
| `kanten.gd` | saum.gd:718/1306/1349/1792 | Profile ohne Bezug auf Level01 |
| `gelaende_bau.gd` | gelaende.gd:263-295, 405-430 | Bauspeicher-Schritte für `GelaendeFeld` |
| `stimmungsregler.gd` | stimmung.gd:264ff | Regler nach s, mit `nebel_beginn` und Bildrahmen |
| `nebelstoff.gd` | weltenbaum.gd:436-450 | Nebel in eine Shader-Kopie schreiben |
| `sichtgruppen.gd` | neu | Abschnittsknoten nach `kamera.strecke()` mit Überlappung ein- und ausblenden |

Die Umstellung von L01 auf diese Bausteine ist eine eigene Aufgabe.

### 9.3 Geteilte Änderungen

| Datei | Änderung | Ohne Plan oder Option |
|---|---|---|
| `scripts/kameraplan.gd` (neu) | Einträge, `profil_bei(s)`, `fenster_bei(s)`, `pruefen()`; auch Profile für Hoch- und Rückblick (für L03/L05) | – |
| `scripts/corridor_camera.gd` | Plan-Zweig in `_folgen`: Profil nach `_strecke`, Mischung nach s, `blick_hoehe`, Seitenblick-Ziel auf geglätteter Höhe. Dazu `sollage()`, `strecke()`, `spur()` (R1). FOV nur über `_szenen_fov` (:262-264). | `kameraplan == null` → alter Pfad zeichengleich |
| `level_basis.gd`, `scripts/rundgang.gd` | Plan an die Kamera hängen. Rundgang mit Plan: Verfolger ±40°, Seite 0°/±25°, Hoch- und Rückblick. | gleiche Blickliste |
| `scenes/player/player.gd` | Spurbindung in `_kamerarelativ` (nur nach R1) | greift nie |
| `korridor_level.gd` | `kameraplan_setzen`, `tropfzapfen()`, `firndecke()`, `bruchplatten_zuruecksetzen_anbinden()` | nur auf Aufruf |
| `scenes/props/bruchplatte.gd` | Exports `optik` (Callable, leer = Bretter), `warn_weite` (0,045), `zerfaellt` (false), `rueckkehr_frei` (false) | Vorgaben wie heute |
| `scenes/hazards/eisflaeche.gd` | `platte := true` | L14 unverändert |
| `scenes/hazards/tropfzapfen.gd` (neu) | Takt 2,0, Warnung 0,6 (Glanz, Zittern), Gefahr 0,15, r 0,7, `phase` als Taktbruchteil, Schaden über `schaden_nehmen()`, Optik ohne Interpolation | – |
| `scenes/hazards/firndecke.gd` (neu) | StaticBody auf Ebene 1, bricht bei `bauchplatscher_gelandet` im Umkreis von 2,0 m und kehrt nicht zurück | – |
| `gelaende_saum.gd`, `materialbibliothek.gd` | `stoff_variante()`, Schneetextur | `stoff()` unverändert |
| `werkzeuge/sprungprobe.gd` | Felder `art` (einfach, doppel, fang, stufe_doppel, slide_doppel, lauf), `doppel_t` [0,20, 0,25, 0,33], `fenster_min` 1,25, `tief_erlaubt`. Loslassen 1 Bild vor dem Doppelsprung. Vor jedem Versuch Bruchplatten zurücksetzen und Taktgefahren abschalten. Eingabe über `stick_fuer()`. | L01-Fälle unverändert |
| `werkzeuge/kameraplanprobe.gd` (neu), `pruefe.sh` Stufe 4 | Läuft bei `^const KAMERA` | – |
| `level_check.gd` | Probe „kameraplan“ (Opt-in): Kamerastreifen per Strahl alle 2 m, Sichtprobe über `sollage()` | – |
| Werkstatt | Stationen 30–34: Terrassen und Leitlinie 16; drehende Blende und 2D mit F1, P1, P2; Eckblende mit Kehre r 9 und Kern; Wechten, Zapfen, Firndecke; Hoch- und Rückblick | – |

**L01 bleibt gleich**, wenn vier Bedingungen erfüllt sind:
1. `level01.gd` und `level01/*` werden nicht angefasst.
2. `steuerbasis()` liefert ohne Plan genau `kamera.global_transform.basis`.
3. Der Nachweis läuft über Schaufenster `VORHER=HEAD` mit festem Takt und fester Saat: `getbbox() is None`, `werte.tsv` gleich, Sprungprobe- und LevelCheck-Logs zeilengleich.
4. Die Bauzeitprobe zählt erst ab Runde 2 (bauspeicher.gd:34-41).

### 9.4 Reiter, Floß, Keiler
In L02 ändert sich an ihnen nichts.
- **Reiter:** Der Kameraplan ist allgemein gebaut (Gruppe „spieler“ und Kurve). Der Reiter liest den Stick roh (reiter.gd:257), die Spurbindung wirkt auf ihn also nicht. L04 bekommt laut Raumbogen ohnehin keine Seitenansicht.
- **Floß:** unberührt.
- **Keiler:** L05 kann den Rückblick in seinem eigenen Durchlauf als einzigen Planeintrag setzen.

### 9.5 Bauspeicher und Ladezeit
- Schlüssel `l02_<modul>_<voll|handy>`. Nach jeder Skriptänderung ist der Speicher kalt.
- Ziel headless: warm ≤ 5,0 s, kalt ≤ 12,7 s, also höchstens die L01-Werte (6,4 / 12,7). Heute braucht L02 2,58 / 5,0 s.

### 9.6 Handyweg (`Effekte.reduziert`)
- Streu und Treibschnee ×0,5, zweite Lage der Schneefahnen aus.
- `Waldsetzer` setzt jedes zweite Stück, der Gipfelring wird gröber (`abstand` ×1,5).
- Eine Schattenstufe bis 50 m.
- Sichtweiten wie in L01: Kisten 55 m (level01.gd:845-857).
- Kristalle müssen auch ohne Glow lesbar sein (Glow auf dem Handy ungeprüft).

---

## 10. Leistungsbudget

Rahmen: Rechner etwa 285–500 Draw-Calls, Handy ≤ 450, Primitive ≤ 750k, VRAM ≤ 140 MB. **Ziel: Rechner ≤ 450, Handy ≤ 400, Primitive ≤ 600k.** Alle Zahlen unten sind Schätzungen und ungeprüft.

| Posten | 2D-Bild | Biwak 3D | Gipfel 3D | Mittel |
|---|---|---|---|---|
| Wegdecke | 2 | 2 | 2 | ein Stoff je Abschnitt |
| Grat, Saum | 8–12 | 10–16 | 8–12 | Stücke von 30 m, keine Schatten |
| Massiv, Ring, Horizont | 4–6 | 6–8 | 6–8 | – |
| Wegbauten | 3–6 | 6–10 | 4–6 | je Abschnitt verschmolzen |
| Eis, Wechten, Zapfen, Kristalle | 8–14 | 2 | 0 | Kristalle als 1 MultiMesh |
| Bewuchs | 0–4 | 20–35 (+8) | 2–6 | Waldsetzer |
| Stimmung | 4–6 | 4–6 | 6–8 | – |
| Himmel, Rahmen, Schattenkamm | 2 (+2) | 2 (+2) | 2 (+2) | – |
| Spiel und HUD | 120–180 (+25) | 150–200 (+35) | 120–170 (+30) | Kisten 5–7 Aufrufe je Stück |
| **Summe** | **≈ 180–260** | **≈ 250–330** | **≈ 200–280** | – |

- **Sichtgruppen:**

| Gruppe | sichtbar bei s |
|---|---|
| Biwak | 0–80 |
| Nord | 40–160 |
| Scharte | 120–190 |
| Süd | 150–270 |
| Gipfel | ≥ 215 |

  Gelände, Feuer und Rauch bleiben immer sichtbar.
- **Messplan:** Schon im Graubau (B1) wird an s 12, 90, 145, 208, 240 und 275 gemessen, am Rechner und auf dem Handyweg. Danach nach jedem Paket erneut.

---

## 11. Risiken
1. **Kameraplan in `corridor_camera.gd` ist eine geteilte Änderung.** Gegenmittel: Null-Pfad zeichengleich, Pixel- und Logvergleich für L01 und Hub (§9.3).
2. **R1 wird abgelehnt.** Dann scheitern P1 und P3 mit Tastatur-Diagonale (Fenster 0,25 m). Rückfall: bei 2D-Eintritt ein Hinweis „nur → halten“, und P1/P3 werden als Höhen-Doppelsprung (3,0 m auf +2,2) gebaut. Die Raumregel „flach 5,0–5,5“ wäre dann in L02 nicht erfüllt, das bräuchte eine erneute Rückfrage.
3. **Licht auf dem Handy:** Der Grat ist bis 50 m vom Biwak entfernt, der Schatten reicht vielleicht nicht. Gegenmittel: Regler für die Sonnenenergie, Abnahme der Farbziele auf beiden Wegen.
4. **Die Hülle der Eckblende** kann durch spätere Felsmodellierung verletzt werden. Gegenmittel: Hüllprobe in der Kameraplanprobe.
5. **Überschneidung mit L14** (2D, Eis, Bruchplatten) besteht teilweise weiter (R3).
6. **Schneekappen** brauchen neuen Shader- und Modellcode. `Wasserfall.band` als Eisfall und als Rauch ist ungeprüft. Rückfall: eigener, einfacher Bandstoff.
7. **Sehnen in der Scharte:** `GelaendeSaum` und `GelaendeFeld` haben keine Kollision. Die Sichtsperre des Kerns muss als eigener Körper gebaut werden.
8. **Aufwand und Ladezeit:** L01 hat 16 981 Zeilen. Gegenmittel: vier Durchläufe mit Messung, gemeinsame Bausteine statt Kopien je Level.
9. **`get_closest_offset`:** Die Flanken liegen 21 m auseinander, Biwak und Gipfel ≥ 20 m. Das sollte eindeutig bleiben, die Kameraplanprobe prüft es.
10. **Figur und Lizenz (R4)** blockieren die Nachher-Bilder.
11. Die Drive-Downloads (`*_Snow`) bleiben gesperrt. Es ist nichts eingeplant, das sie braucht.

---

## 12. Arbeitspakete

Jedes Paket ist ein Durchlauf nach CLAUDE.md Regel 1 und endet so:
- `bash werkzeuge/parse.sh` meldet keinen Fehler.
- `bash werkzeuge/pruefe.sh` meldet **ERGEBNIS: SAUBER** für alle Level.
- Höchstens 6 Bilder per `foto.sh` in die Kopie.
- Committet wird nur, was zum Paket gehört.

Physikwerte bleiben unverändert, alle Texte sind deutsch.

### A `kameraplan` (geteilt, vor L02, nach R1)
- **Ziel:** Kameraplan nach s mit Eck- und Drehblenden, Profilen für Hoch- und Rückblick, Vorwärmen, Proben und Werkstatt-Stationen. Spurbindung nur nach R1.
- **Dateien:**
  - neu `scripts/kameraplan.gd`, `werkzeuge/kameraplanprobe.gd`;
  - `scripts/corridor_camera.gd`, `scenes/levels/level_basis.gd`, `scripts/rundgang.gd`, `scenes/levels/korridor_level.gd` (nur `kameraplan_setzen`), `scenes/player/player.gd` (R1);
  - `werkzeuge/sprungprobe.gd`, `werkzeuge/level_check.gd`, `werkzeuge/pruefe.sh`;
  - `scenes/levels/werkstatt.gd` und `Werkstatt.tscn` (Stationen 30–34);
  - `doku/level-vorbilder.md`, ARCHITEKTUR; CLAUDE.md (R1-Zeile).
- **Abnahme:**
  - L01 und Hub pixelgleich, `werte.tsv` gleich, Sprungprobe-Log L01 zeilengleich.
  - Werkstatt bei 0,5-m-Schritten: Kamerasprung ≤ 2,0 m, Gier ≤ 10°, in 2D Seitenabstand 16–17,5 m, außerhalb `seiten_grad` 0.
  - Driftprobe: Stick 6 m vor jedem Fenster 3 s halten, die Figur bleibt auf dem Weg.
  - In 2D Querabweichung ≤ 0,2 m.
  - Station 31 per Foto in 2D.

### B1 `l02_rohbau`: Verlauf, Daten, Graubau, Spiel
- **Ziel:** das ganze Spiel aus §4 und §6 als graue Körper.
- **Dateien:**
  - `scenes/levels/level02.gd` (neu, Name „Frostgrat“), `Level02.tscn` (Start s 10, Kamera-Grundwerte);
  - `scripts/gemeinsam/wegdaten.gd`, `sichtgruppen.gd`; `level02/*.gd` als Stubs;
  - `bruchplatte.gd` (Optionen), `eisflaeche.gd` (`platte`);
  - neu `tropfzapfen.gd/.tscn`, `firndecke.gd/.tscn`;
  - `korridor_level.gd`: `tropfzapfen`, `firndecke`, Reset-Anbindung;
  - Werkstatt-Stationen für Zapfen, Firndecke und Wechtenoptionen; level-vorbilder.md.
- **Abnahme:**
  - `pruefprofil` meldet keine Fehler.
  - Sprungprobe SAUBER:

    | Fall | Prüfung |
    |---|---|
    | F1 | einfach überlebt auf der Leiste, Doppelsprung landet ≥ 91 |
    | P1, P3 | Fenster ≥ 1,25 bei Doppelsprung 0,20 s |
    | P2 | Fenster ≥ 1,25 bei 0,15 s |
    | G-a, G-b | wie heute |
    | Gipfelstufe | Doppelsprung trägt |
    | Wechtenreihe | Lauf 199 → 217 lebend |

  - `TEST_LEVEL=2 spieltest.sh` läuft durch.
  - Tod auf der zweiten Wechte: Nach dem Respawn stehen alle Wechten.
  - Draws im Graubau an den sechs Stellen gemessen, am Rechner und auf dem Handy; §10 wird danach kalibriert.

### B2 `l02_grat`: Kanten, Massiv, Gelände, Schattenkamm
- **Dateien:** `level02/grat.gd`, `level02/massiv.gd`; `scripts/gemeinsam/kanten.gd`, `gelaende_bau.gd`; `gelaende_saum.gd` (`stoff_variante`); Schneetextur in `materialbibliothek.gd`.
- **Abnahme:**
  - Krone ≥ Südweg + 2.
  - Strahl Start → Feuer frei.
  - Im Seitenbild bei s 90 und 200 keine fremde Wegdecke.
  - Hüllprobe der Scharte frei.
  - `foto seite` und `verfolger` bei s 12, 90, 200.
  - Bauzeit warm ≤ 5,0 s.

### B3 `l02_eis_wegbauten`: Simse, Bauten, Eis, Wechten, Zapfen, Feuer
- **Dateien:** `level02/wegbauten.gd`, `level02/eis.gd`; neu `shaders/flamme.gdshader` als Kopie aus hub.gd:262ff (der Hub bleibt unberührt).
- **Abnahme:**
  - Findling-Regel: Optik = Kollision ±3 cm.
  - Wechten-Warnung im 2D-Bild sichtbar (Ausschlag ≥ 0,12, Riss ≥ 0,15 m).
  - Glattprobe für neue bewegte Deko.
  - Fotos bei s 90, 185, 208, 285.

### B4 `l02_stimmung`: Licht, Bewuchs, Handyweg, Endabnahme
- **Dateien:**
  - `scripts/gemeinsam/stimmungsregler.gd`, `nebelstoff.gd`; `level02/stimmung.gd`, `level02/bewuchs.gd`;
  - `Level02.tscn` (Himmel, Umgebung, Sonne, Bildrahmen);
  - `assets/modelle/natur2/unp/` (`Rock_1–7`, `CommonTree_Dead_3–5`), `assets/CREDITS.md`, `natur2/LIESMICH.md`;
  - `werkzeuge/schaufenster.sh` (Teile `l02`, `l02seite`, `l02handy`).
- **Abnahme:**
  - Farbziele aus §8.2 am Rechner und auf dem Handy.
  - Rechner ≤ 450, Handy ≤ 450 (Ziel 400), Primitive ≤ 600k, VRAM ≤ 140 MB.
  - Bauzeit warm ≤ 5,0 s, kalt ≤ 12,7 s.
  - Rundgang-, Glatt- und Ruckelprobe (`RUCKEL_REDUZIERT=1`) für L02 sauber.
  - L01 und Hub pixelgleich.
  - Schaufenster bei s 12, 90, 145, 208, 240, 275.
  - Doku: README und level-vorbilder.md nachgezogen.