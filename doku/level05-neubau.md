# Level 05 „Hauerjagd" – Neubau: der Hauerhang

> **Stand:** Das ist der Entwurf, nach dem Level 05 in den Paketen P1a bis
> P9 neu gebaut wurde (Commits `c426f42` … P9, Abschnitt 13). In der
> Umsetzung haben sich einzelne Maße verschoben, jeweils von einer Messung
> erzwungen – etwa die Leitlinien (5,7 m statt 5, an den Geheimnissen 7 m),
> die Eiche (Achse bei s −9,5, Kerbe 9 m statt 7), das Mühlrad (q −8,5),
> der Schatten (orthogonal statt zwei Stufen) und die Richtzeit (48 s statt
> vorläufig 46, seit den Mängeln der Jury-Runde R1 15 s mit Zeitkisten).
> Abschnitt 13 nennt Paket für Paket (und R1), was gebaut und was
> gemessen wurde, Abschnitt 14 die Abweichungen, Abschnitt 15, was offen
> oder ungeprüft ist. Maßgeblich sind die Daten in
> `scenes/levels/level05.gd` und die Kopfkommentare der Module unter
> `scenes/levels/level05/`. Zeilenangaben wie `level05.gd:402` beziehen
> sich auf den Stand vor dem Neubau.

Leitender Entwurf aus einer Leitidee, einem Spiel-, einem Bild- und einem
Technikkonzept und zwei Jury-Urteilen (Spiel und Kamera, Technik und Bild).
Die Nutzerentscheidungen gingen vor; für dieses Level zählt eine: **Der
Slide-Sprung ist Kür** (Slide unter Durchlässen ist Pflicht, der
Slide-Sprung belohnt, wird aber nie erzwungen).

Vor dem Bau gemessen wurde in einer Kopie mit einer **Messbank**: Sie fährt
die echte Figur (`Player.tscn`) über Kästen, headless mit `--fixed-fps 60`.
Die Bank hat keine Kamera, die Eingabe geht roh geradeaus. Im Level mit
Kurve und kamerarelativer Steuerung ist die Sprungprobe verbindlich. Die
Rechenskripte (Keilerabstand, Höhen, Kamera, Sicht auf die Eiche) lagen
nur in der Bauumgebung und sind nicht im Repo; nachprüfbar sind die Werte
über `Sprungprobe`, `Jagdprobe`, `LevelCheck` und `Wahrzeichenprobe`.

Werte, die so markiert sind, haben folgende Herkunft:
- **(gemessen)**: Messbank oder Kostenbild vor dem Bau.
- **(gerechnet)**: Rechenmodell der Bauumgebung (nicht im Repo).
- **(ungeprüft)**: nicht bestätigt.

Kürzel für die Herkunft: LI Leitidee, SP Spielkonzept, BI Bildkonzept, TE Technikkonzept, JS# und JT# Jury Spiel/Kamera bzw. Technik/Bild, M eigene Messung.

---

## 0. Pitch

Unterhalb der gespaltenen Hauereiche schläft der Keiler in seiner Suhle, die Eicheln vor der Schnauze. Ich schleiche an ihm vorbei und klaue sie. Auf dem ersten Rastplatz knackt ein Ast, und von da an rennt er mir den ganzen Hang hinunter nach: durch den Hohlweg, über die Wurzelterrassen, durch den Tobel bis über das gebrochene Wehr am Mühlbach. Die Kamera schaut die ganze Zeit zurück: Ich laufe auf sie zu, hinter mir die Hauer, ganz hinten die Eiche, die immer kleiner wird. Unter Wurzelbögen und Gerinnen komme ich nur im Slide durch. Ein Slide gibt Vorsprung, jeder Sprung kostet welchen.

---

## 1. Entscheidungen

| # | Entscheidung | Herkunft | Warum |
|---|---|---|---|
| 1 | Durchgehend Rückblick mit den Szenenwerten (Level05.tscn:63-67). Kein Kamerawechsel, kein 2D, keine Kamerazone. Im Kameraplan trägt L05 nichts ein. | LI, Raumbogen | Rückblick gibt es nur in 05. Jeder Wechsel kostet Abstand. |
| 2 | **Durchlass:** Körper von 0,95 bis 4,4 m auf Ebene 16, Tiefe 1,6–1,8 m. Sichtbar: massiver Riegel 0,95–1,40 m, darüber ein Vorhang oder Latten mit ≥ 60 % offener Fläche als echte Geometrie, Kappe 4,2–4,6 m. | LI, JS2 gegen SP/JT1 | Die Körperhöhe sperrt Doppelsprung (Scheitel 3,21) und Slide-Sprung plus Doppel (4,01, beide gemessen); der Slide ist damit Pflicht. Die offene Geometrie behebt die Verdeckung aus BI-K5' und TE-B1. |
| 3 | Stolperzone am Durchlass nur an der Stirn: s −0,15 … +0,25, Höhe 0,85–4,4. | JT1, M | Eine Zone über die ganze Tiefe ließ Spieler beim Aufrichten am Ausgang stolpern (gemessen: 13 „S“ bei frühem Slide). Nur an der Stirn gibt es 0 Stolperer. |
| 4 | **Slide ist Pflicht, Slide-Sprung ist Kür.** Angeboten im Suhlgraben, belohnt an der G2-Bank. Er entsteht von selbst bei spätem Slide vor L5 und geht als Kür am Wehr. **Vom Nutzer bestätigt** (Abweichung vom Raumbogen „prüft Slide-Sprung“). | JS2, JT3 | Der Doppelsprung schlägt den Slide-Sprung in Höhe und Weite. Kein Maß erzwingt den Slide-Sprung fair. |
| 5 | **Wehr 5,0 m flach. Doppelsprung ist Pflicht.** | JS5, JT2, M | Gemessen: Einzelsprung trägt an keiner Stelle, Doppelsprung im Scheitel hat 2,6 m Fenster, Slide-Sprung als Kür 0,80 m. Bei 4,6 m trug der Einzelsprung im Glücksfenster von 0,40 m. Reserve 7,08 − 5,0 = 2,08 m ≥ 1,5. |
| 6 | Terrassen: 5 Absätze à 1,2 m, alle 12 m. Die Kurve fällt dort genau 10 %. | SP, JS13, JT4 | Kamera ≥ 3,50 m über der Figur; \|Boden − Kurve\| ≤ 0,64 m (gerechnet). Die Sprungprobe hat 0,3 m Luft zu ZU_TIEF. |
| 7 | Stufen sind **Wurzeltreppen** aus zwei Tritten à 0,6 m. Lücken haben eine scharfe Lippe mit Steinen. | JS10 | Im Rückblick sehen Stufe und Lücke sonst gleich aus. |
| 8 | Kamera `sicht_maske = 8` (neues Export, Vorgabe 1\|8). Terrassen und Kisten bleiben auf Ebene 1. | TE3.1, JS1, JT4 | Der Kamerastrahl trifft sonst Kisten. Damit entfallen „stufen_ebene“ und die Terrassen auf Ebene 16. |
| 9 | `far = 380` nur in Level05.tscn. | TE-B4, JT13 | Im Schlussbild liegt die Krone bis zu 334 m entfernt. |
| 10 | Der Keiler schläft bei s 16, q −4,5. Wecken und CP1 sind derselbe Auslöser bei s 31. | JS9, JT14, CLAUDE.md | Abstand beim Wecken genau 15 m, kein Sprung durch den Deckel (level05.gd:402). Kein Aufholspurt, denn CLAUDE.md sagt „festes Tempo“. Vor CP1 ist kein Tod möglich. |
| 11 | L5 (Mühlrinne) liegt 4,9 m hinter dem Ausgang von D4 und ist 3,0 m breit. | JS4, M | Gemessen: Bei 2,2 m Abstand und 3,5 m Breite gibt es ein Loch im Fenster, bei 4,9/3,0 hat der Laufsprung 1,75 m. Die Folge „Durchlass, dann Lücke“ zeigt der gefahrlose Suhlgraben vorher mit demselben Abstand. |
| 12 | Hürde: 0,7 m hoch, 0,6 m tief, Zone 1,0 × 0,8 m. | SP, M | Gemessen: stolperfreies Fenster 1,95 m (0,23 s). Wer hineinslidet, stolpert immer. Hürde heißt springen, Durchlass heißt sliden. |
| 13 | Kisten bei q +2,2, in Gassen von höchstens 3 Kisten, ≥ 5 m hinter Hürden und Findlingen, ≥ 6 m vor Lücken und Durchlässen. Auf q 0 liegen Kisten nur im Lehrteil A. | JS7, JT14 | So stehen keine Blöcke auf der Fluchtlinie, und die Kisten liegen im Licht. Ein Slide zerbricht die ganze Gasse (kiste.gd:61). |
| 14 | Keine SCHUTZ-Kisten. | SP-Befund 8, JT8 | Der Keiler ruft `sterben()` direkt (level05.gd:411). Schutz wirkt dort nicht. |
| 15 | Ein Ziel-Auslöser: das Zielportal auf `boden_bei(296)`. „Entkommen!“ ist nur eine Meldung ab s 289. | JT16 | `_auf_level_geschafft` ist nicht gegen Doppelaufruf geschützt (level_basis.gd:437-449). |
| 16 | `pruefruhe()` ist Pflicht in P1: Foto, Sprungprobe und LevelCheck halten den Keiler an. | JT5, TE3.5 | `_vor_dem_start` läuft vor `aufbau_fertig` (level_basis.gd:136/150), der Keiler steht in keiner Gegnergruppe (sprungprobe.gd:99). |
| 17 | Findlinge nur als **Findlingsgasse** in D (s 244/250, versetzt, je 4,6 m breit). | JS11 | Einzelne Findlinge auf 9,5 m Breite sind trivial. Die Gasse ist das einzige Ausweich-Element, mit ≥ 1 m Querversatz. |
| 18 | Fünf Rastplätze: 31, 122, 178, 204, 268. | JS11, JT14 | CP4 bei 204 sichert die schwerste Stelle D3/D4/L5. Jeder Rastplatz liegt ≥ 12 m vor einer Lücke und ≥ 6 m vor einem Hindernis. |
| 19 | Die Eiche steht bei s −6 auf der Kuppe. Gespaltener Zwiesel, zwei Schirmkronen mit **7 m** Himmelskerbe. | BI, JT12 | Eine Kerbe von 2–3 m ist auf 300 m 6 px breit; 7 m sind 16 px bei 720p. |
| 20 | `zielzeit()` = 1,3 × Bot-Zeit, vorläufig 46 s. | L06-Muster (level06.gd:64-73), JS12 | Siehe 6.6. |
| 21 | Ankündigen nur über Früchte, Lippen, helle Unterkanten und Ton. | JT7 | Mit der Sonne im Rücken fallen Schatten hangauf, hinter den Werfer. |
| 22 | Rastplatz-Laterne als leuchtendes Netz, ohne Licht. | JT11 | `Lichtkreis` ist das Dunkel-Modul (lichtkreis.gd:2-7). |
| 23 | Bach als Bachband. Tödlich ist nur `todeszone()` auf fester Höhe. | JT18 | `wasser()` setzt relativ zur Kurve (korridor_level.gd:776). |
| 24 | Neue UNP-Modelle bekommen nur neue Rollen; geteilte Stoffe werden nur als `duplicate()` geändert. | JT8 | Level 01 und der Portalraum bleiben pixelgleich. |

**Verworfen:**
- Oberkante 2,0 m (SP, JT1): Der Doppelsprung ginge darüber, das Lernziel wäre nicht erzwungen (Widerspruch zur Leitidee).
- Sichtloch-Shader (TE3.4): in gl_compatibility ungeprüft, ersetzt durch offene Geometrie.
- Wehr 4,6 m flach: Glücksfenster gemessen.
- Wehrkrone +2,0 m (TE-B6): Am Schluss ginge es bergauf, der Kopf wäre 0,52 s verdeckt, die Fangregel müsste die Höhe kennen.
- 6 × 1,4-m-Terrassen: 15,3 % Gefälle.
- Gitterschatten als Ankündigung.
- Kenney-Pilze: verletzt `kenney_ab` (fremdmodelle.gd:378).
- G3 auf dem Fluderdach: nicht erreichbar, der Körper reicht bis 4,4 m.
- Aufholspurt beim Wecken.
- H4 und einzelne Findlinge bei 254/258.
- Richtzeit 30 s (JS12) und die Formel mit 108,7 s.
- „Krabbeln ist tödlich“ (LI, TE-Probe 4): widerlegt, siehe 2.4.

---

## 2. Feste Größen und Rechenwerte

### 2.1 Unverändert

- **Physik:** player.gd:12-23. Kapsel r 0,38, aufrecht 0–1,30 m, flach 0–0,76 m (Player.tscn:6-12), Figur-Maske 17 (Player.tscn:19-20).
- **Keiler:** Tempo 7,4, Vorsprung 12, Höchstabstand 15, Fangabstand 2, Stolpern 0,45 s (level05.gd:45-49).
- **Kamera:** hoehe 5,6, abstand −21, blick_vorlauf −5, seiten_faktor 0,35, fov 60.

### 2.2 Sprungmaße (60 Hz)

- **Scheitel:** Einzelsprung 1,86, Slide-Sprung 2,65, Doppelsprung 3,21, Slide-Sprung plus Doppel 4,01 (letzte beiden gemessen).
- **Weite flach:** Einzelsprung 4,38, Slide-Sprung 5,31, Doppelsprung im Scheitel 7,08–7,14, Doppelsprung bei bestem Timing 8,13.

### 2.3 Absprungfenster (gemessen, Raster 0,05 m)

Gezählt wird der Absprung an der Stelle des Kapselmittelpunkts, die Kante liegt bei 0.

| Fall | Fenster | Bemerkung |
|---|---|---|
| Einzel 3,0 flach | −1,80 … +0,15 = **1,95 m** | |
| Einzel 3,4 / −1,2 | −1,95 … +0,15 = **2,10 m** | |
| Einzel 3,5 flach | −1,25 … +0,15 = **1,40 m** | |
| Einzel 4,6 / 5,0 / 5,2 flach | 0,40 / **0** / 0 m | |
| Slide-Sprung 4,6 / 5,0 / 5,2 | 1,25 / **0,80** / 0,50 m | Slide 2 m vor dem Absprung gedrückt |
| Doppel (Scheitel) 5,0 / 5,2 | **2,6** / 2,3 m | |
| Wurzelhürde 0,7 | −2,95 … −1,00 = **1,95 m** | ohne Stolpern; Slide hinein: immer Stolpern |
| Bank +2,2 | Einzel nie; Slide-Sprung −3,8 … −0,4 (≥ 3,4 m); Doppel überall | frontal gemessen |
| Bank +2,8 | Doppel aus −4,0 … −0,4 | trägt |
| Durchlass, Tiefe 1,6 | Slide-Druck sauber −3,9 … −0,5 = **3,4 m**; ohne Stolpern −6,2 … −0,5 = 5,7 m | jenseits von 3,4 m wird gekrabbelt |
| Durchlass, Tiefe 1,8 | sauber −3,6 … −0,5 = **3,1 m** | ab −0,4 Stolpern |
| Durchlass aus dem Stand (0,6 m vor der Stirn) | geht durch | Slide braucht nur Richtung und Boden (player.gd:217-220) |
| L5 3,0 m, 4,9 m hinter dem Ausgang | Laufsprung ≥ 1,75 m (Raster 0,25); mit spätem Slide 2,75 m | bei 2,2 m Abstand / 3,5 m Breite: Loch bei +2,3 |

### 2.4 Zeitkosten gegen reines Laufen (gemessen)

Der Keiler holt je Sekunde Verlust 7,4 m auf; Laufen gewinnt 1,1 m/s zurück, höchstens bis 15 m.

| Aktion | Zeit | Abstand zum Keiler |
|---|---|---|
| Einzelsprung | +0,117 s | −0,87 m |
| Hürde | +0,135 s | −1,0 m |
| Doppelsprung | +0,183 s | −1,35 m |
| Slide | −0,25 s | +1,85 m |
| Slide-Sprung | +0,033 s | −0,24 m |
| Durchlass mit zu frühem Slide (Zwangskrabbeln) | bis +0,27 s | bis −2,0 m |
| Durchlass mit gehaltener Taste | bis +0,63 s | bis −4,7 m |
| Stolpern | 0,45 s Stillstand plus Reaktion | ≈ −5 m |

**Krabbeln ist nicht tödlich.**

### 2.5 Keilerabstand über die ganze Strecke (gerechnet, mit den Kosten aus 2.4; gemessen siehe 13, P1b)

| Lauf | Mindestabstand |
|---|---|
| Ideallauf | 12,8 m |
| Jeder Durchlass zu früh | 11,8 m |
| Jeder Durchlass mit gehaltener Taste | 6,5 m |
| Stolpern an D3 | 9,8 m |
| Stolpern an D3 und D4 | 5,4 m |
| Dasselbe, dazu 0,3 s Zögern vor L5 | 3,2 m |
| Drei Fehler in Folge D3/D4/L5 | gefangen |

Die Kette verzeiht also zwei Fehler.

### 2.6 Kamera (gerechnet)

- **Höhe:** Die Kamera steht über der Figur bei 5,6 − (Kurve(s) − Kurve(s+21)). Die Kurve fällt über 21 m höchstens 10,0 %, also steht die Kamera ≥ 3,50 m über der Figur. Mit der Trägheit sind es in C 3,2–5,0 m (JS).
- **Über den Durchlässen:** 5,60 / 5,60 / 5,88 / 5,67 / 6,05 m über dem Durchlassboden (Ü, D1, D2, D3, D4). Das sind ≥ 1,0 m über der Kappe (4,6).
- **Vorausblick:** 14 m, ≈ 1,65 s (JS bestätigt).

### 2.7 Breiten

| Abschnitt | Breite |
|---|---|
| A | 12 m |
| B (Hohlweg) | 9,5 m |
| C | 10 m |
| D | 9 m |
| E (Wehrkrone) | 7 m |

---

## 3. Verlauf

`LevelWerkzeuge.kurve_aus_punkten`. Den Grundriss übernehme ich aus SP, die Höhen sind neu. Der Kurs liegt zwischen −6° und +8° (gerechnet).

```
s0 (0, 26.00, 0)        s30 (0, 26.00, -30)      s60 (-0.8, 23.56, -60)
s90 (-4.2, 21.03, -89.8) s120 (-9.0, 18.50, -119.4) s150 (-13.1, 15.50, -149.1)
s180 (-14.7, 12.50, -179.0) s210 (-14.0, 9.64, -209.0) s240 (-11.7, 8.47, -238.9)
s270 (-8.5, 5.57, -268.8) s300 (-6.1, 3.00, -298.7) s330 (-4.6, 2.25, -328.6)
```

**Kurvenhöhe (Kameraschiene), stückweise linear:**

| s | 0–31 | 120 | 180 | 208 | 236 | 265 | 300 | 332 |
|---|---|---|---|---|---|---|---|---|
| Höhe | 26,0 | 18,5 | 12,5 | 9,7 | 8,86 | 6,0 | 3,0 | 2,2 |

**Boden (`boden_bei`):** gleich der Kurve, mit vier Ausnahmen:
- **Absätze** sind waagerecht auf der Kurvenhöhe ihrer Mitte, mit Rampen von 6 m (14–19 %):

  | Absatz | Bodenhöhe |
  |---|---|
  | 54–62 | 23,72 |
  | 71–81 | 22,21 |
  | 100–108 | 19,85 |
  | 190–200 | 11,00 |
  | 210–236 | 9,25 |
  | 279–294 (Wehrkrone) | 4,16 |

- **Terrassen:**

  | T0 120–126 | T1 126,8–136,3 | T2 139,7–150 | T3 150,8–160,3 | T4 163,7–174 | T5 174,8–180 |
  |---|---|---|---|---|---|
  | 18,5 | 17,3 | 16,1 | 14,9 | 13,7 | 12,5 |

  Treppentritte à 0,6 m liegen bei 126,0–126,8, 150,0–150,8 und 174,0–174,8.
- **Suhlgraben** 23,5–28,1 auf 25,2.
- Ergebnis (gerechnet): \|Boden − Kurve\| ≤ 0,64 m. Alle Lückenlippen liegen auf Absätzen oder Terrassen. Der Δh steht in der Sprungtabelle.

**Länge und Ränder:**
- `M_ENDE` 300, Ziel 296, Kurve bis 332 (Kamera bei s+21; TE-B14).
- Die Eiche steht bei s −6 über `punkt_frei` vor dem Kurvenanfang.
- s ist die 3D-Bogenlänge. P1 gleicht die Stützpunkte so ab, dass alle s aus Abschnitt 4 auf ±0,2 m stimmen.

---

## 4. Abschnittstabelle

| s | Abschnitt | Welt-Y Boden | Kamera | Inhalt |
|---|---|---|---|---|
| 0–31 | A Suhle | 26,0 (Graben 25,2) | Rückblick | G1 0–2/q+5; Start 6; Keiler schläft 16/q−4,5; Ü 17,0–18,6; Suhlgraben 23,5–28,1; CP1 und Wecken 31 |
| 31–120 | B Hohlweg | 26,0 → 18,5 | Rückblick | Kistengasse 36; H1 44; D1 58,0–59,8; L1 75,0–78,0; G2 82–87/q+5; H2 93; D2 104,0–105,8 |
| 120–180 | C Wurzelterrassen | 18,5 → 12,5 in 5 × 1,2 | Rückblick, Kamera 3,2–5 m über der Figur | CP2 122; S1 126; L2 136,3–139,7; S2 150; L3 160,3–163,7; S3 174; CP3 178 |
| 180–265 | D Tobel | 12,5 → 6,0 | Rückblick | L4 194,0–197,5; CP4 204; D3 214,0–215,6; D4 223,2–224,8; L5 229,7–232,7; Findlingsgasse 244/250; G3 252–258 |
| 265–300 | E Mühlbach | 6,0 → 3,0 (Wehrkrone 4,16) | Rückblick | CP5 268; Keiler hält bei 282; L6 Wehr 284,0–289,0; „Entkommen!“ ab 289; Mühlrad 291/q−7; Ziel 296 |
| 300–332 | Auslauf | 3,0 → 2,2 | Kamera bleibt am Kurvenende stehen | nur Kulisse |

Es gibt eine Ebene mit Höhenstufen, keine übereinanderliegenden Wege.

---

## 5. Die Abschnitte im Einzelnen

### A · Suhle (0–31): Diebstahl ohne Druck

**Spiel:**
- Start bei s 6. Eine Eichelspur aus 8 Früchten führt an der Schnauze des schlafenden Keilers vorbei (q −2,6 → 0).
- **Ü (Wildgatter) 17,0–18,6:**
  - Früchte liegen am Boden auf 0,35 m Höhe, 13,6–16,6.
  - Einmalige Meldung „Slide: kurz antippen, nicht halten“ (JS6). Wer hält, krabbelt mit 3 m/s weiter (player.gd:597-600).
  - 2 Kisten auf q 0 bei 20,4 und 21,6. Hier zeigt sich, dass der Slide Kisten zerbricht.
- **Suhlgraben 23,5–28,1:**
  - 0,8 m tief, nicht tödlich, Rampe auf q +3…+5,5 hinaus, 3 Kisten in der Sohle.
  - Fruchtbogen auf der Bahn des Slide-Sprungs (Scheitel 2,4).
  - Ein Einzelsprung trägt nur im Glücksfenster von 0,40 m; wer hineinfällt, verliert nichts.
  - Der Graben liegt 4,9 m hinter dem Gatter, also genau wie L5 hinter D4. Damit ist „Durchlass, dann Lücke“ einmal gefahrlos geübt (JS4).
- **CP1 bei 31:** Ein Totholzast knackt, Krähen fliegen auf, der Keiler springt auf und rennt los. Abstand beim Wecken 15 m. Er bricht als Erstes durch das Gatter.

**Bild:**
- Mittelachse: Spaltstamm der Eiche hinten (die Kronen liegen am Start über dem Bildrand), Figur in der Mitte, schlafender Keiler als dunkle Rückenform rechts vorn in der glänzenden Suhle (`moorboden`, `pfuetze`).
- Kronenlicht, 2 Lichtschächte.
- Graben ohne Steinlippen: harmlose Gräben bekommen keine.

### B · Hohlweg (31–120): Löss, links Licht, rechts Schatten

**Spiel:**

| s | Element |
|---|---|
| 36 | Kistengasse (q +2,2), freiwilliger Slide-Spurt |
| 44 | H1: Sprung unter Druck |
| 58,0–59,8 | D1 (Wurzelbogen): Slide gefordert |
| 75,0–78,0 | L1 Wasserriss: erste tödliche Lücke, 3,0 m flach |
| 82–87 | G2 Böschungsbank |
| 93 | H2 |
| 104,0–105,8 | D2 |
| 110 | Kistengasse |

**Bild:**
- Lössböschungen, rechts 3–3,5 m und schattenwerfend, links 4–5 m und angestrahlt. Oben Grasnarbe mit 0,2–0,45 m Überhang und Wurzelvorhängen.
- Baumtore aus zwei geneigten Buchen bei 30 und 120, Kronen ≥ 10 m.
- Wurzelbögen spannen von Böschung zu Böschung. Der Riegel ist eine dicke, oben abgewetzte, helle Wurzel; darüber hängen Wurzelsträhnen mit ≥ 60 % offener Fläche.
- Der Wasserriss hat dunkle Flanken mit Albedo ≤ 0,1; aus beiden Böschungskerben rinnt Wasser.

### C · Wurzelterrassen (120–180): die Treppe zur Eiche

**Spiel:**
- Zuerst eine gefahrlose Wurzeltreppe (S1).
- Dann L2 mit 3,4 m bei −1,2, Fenster 2,10 m; S2; L3 wie L2; S3.
- Der Keiler springt sichtbar mit einem Staubpuff hinterher.

**Bild:**
- Die Setzstufen zeigen zur Sonne und sind angestrahlt, die Kanten sind helle Wurzeln.
- Treppen sind zweistufig mit einer Fruchtlinie hinab. Lücken haben eine scharfe Lippe mit 4–6 hellen Steinen und einen Fruchtbogen.
- Staub über den Stufen.

### D · Tobel (180–265): Bach rechts, Höhepunkt

**Spiel:**
- L4 Seitenrinne mit 3,5 m, das engste Pflichtfenster mit 1,40 m. Danach CP4 bei 204.
- **Kette:**
  - D3 bei 214,0–215,6, D4 bei 223,2–224,8 (bis R1 222,0–223,6).
  - Zwischen D3 und D4 liegt keine Kiste.
  - L5 bei 229,7–232,7 (bis R1 228,5–231,5). D4 und L5 liegen seit R1
    1,2 m weiter hinten: Wer aus D3 sofort wieder slidet, kommt nicht
    mehr im Slide an D4 an, und hinter D4 bleibt Anlauf bis L5 (Spiel-Jury
    R1, Mangel 7). Der Slide-Sprung an L5 bleibt Kür.
- **Findlingsgasse:**
  - F1 bei 244, q −2,2, 4,6 × 1,6 × 1,4.
  - F2 bei 250, q +2,2.
  - Die Lücke zwischen beiden ist 4,6 m lang; man muss ≥ 1 m querversetzen.
- G3 bei 252–258.

**Bild:**
- Rechts liegt der Bach tief im Schatten der Südwand, kühl spiegelnd, mit Bachnebel. Links der Sonnenhang mit Kupferfarn und Sandsteinbändern in Rotocker; Birken.
- Durchlässe als **Fluderjoch:** das Mühlgerinne auf 4,0–4,6 m, tropfend, auf zwei Böcken; der Zangenbalken als Riegel 0,95–1,40, dazwischen Latten mit ≥ 60 % offener Fläche. D4 verdeckt D3 nicht, weil die Sichtlinie bei 2,7–3,5 m durch den offenen Teil geht (JS8, im Bild prüfen).

### E · Mühlbach (265–300): über das gebrochene Wehr

**Spiel:**
- CP5 bei 268, Kistengasse bei 271.
- Der Weg läuft auf der Wehrkrone. **L6 Wehrbruch 284,0–289,0: Doppelsprung.**
- Der Keiler schlittert bei `UFER_S` 282 und hält. Wer an der Kante zögert, wird gefangen. Über der Lücke ist man ab s ≈ 284,5 sicher.
- Nach dem Wehr: LEBEN-Kiste und 2 Kisten, dann das Ziel bei 296.

**Bild und Schluss:**
- Links (q > 0) der ruhige Mühlteich, rechts Weißwasser im Bruch (`Wasserfall.band`, wasserfall.gd:196), das Mühlrad mit Ø 7 m bei 291/q −7.
- Schlussbild ohne Kamerawechsel: Die Figur kommt auf die Kamera zu, oben am Ufer schnaubt der Keiler (auch nach dem Ziel, JT20), ganz hinten steht die Eiche golden und klein (gerechnet bei y +0,48 im Bild).

---

## 6. Spiel

### 6.1 Lehrfolge (anbieten → fordern)

1. **Schleichen (A):** Gefahr sehen, ohne Druck.
2. **Ü:** Slide angeboten, Krabbeln geht auch. Kisten zeigen: Slide zerbricht sie.
3. **Suhlgraben:** Slide-Sprung angeboten, dazu die Folge „Durchlass, dann Lücke“, gefahrlos.
4. **Kistengasse 36:** Slide als Spurt (+1,85 m).
5. **H1 / D1 / L1:** Sprung, Slide und tödliche Lücke, je einmal unter Druck.
6. **G2:** Slide-Sprung belohnt.
7. **H2 / D2:** Wiederholung.
8. **C:** erst eine gefahrlose Treppe, dann Lücken abwärts.
9. **D:** schmalstes Fenster (L4), dann die Kette D3–D4–L5 als Prüfung, die Gasse (Ausweichen) als Ausklang.
10. **E:** Doppelsprung als Abschlussprüfung des Raums (bekannt aus L02, in L05 bei G1 angeboten).

### 6.2 Sprungtabelle (Pflicht)

| Stelle | s | Art | Maß | Δh | Reichweite | Reserve | Fenster (gemessen) |
|---|---|---|---|---|---|---|---|
| H1, H2 | 44 / 93 | Einzel | 0,7 hoch | 0 | Scheitel 1,86 | 1,16 | 1,95 m / 0,23 s |
| L1 Wasserriss | 75,0–78,0 | Einzel | 3,0 | 0 | 4,38 | 1,38 | 1,95 m |
| L2, L3 Terrasse | 136,3 / 160,3 | Einzel | 3,4 | −1,2 | 5,00 | 1,60 | 2,10 m |
| L4 Seitenrinne | 194,0–197,5 | Einzel | 3,5 | 0 | 4,38 | 0,88 | 1,40 m / 0,165 s |
| L5 Mühlrinne | 229,7–232,7 | Einzel (Slide-Sprung Kür) | 3,0 | 0 | 4,38 / 5,31 | 1,38 | 1,75 m |
| L6 Wehr | 284,0–289,0 | **Doppel** | 5,0 | 0 | 7,08 | 2,08 | 2,6 m; Einzel 0; Slide-Sprung (Kür) 0,80 m |
| Ü, D1–D4 | 17 / 58 / 104 / 214 / 223,2 | Slide | Tiefe 1,6 bzw. 1,8 | – | Slide 5,6 | – | 3,4 bzw. 3,1 m sauber, 5,7 m ohne Stolpern |
| S1–S3 | 126 / 150 / 174 | hinablaufen | 2 × 0,6 | – | – | – | – |
| Findlingsgasse | 244 / 250 | ausweichen | ≥ 1 m quer | – | – | – | – |

Raumregeln:
- Pflicht-Einzelsprünge ≤ 3,5 m ✓.
- Doppelsprung 5,0 m mit ≥ 1,5 m Reserve ✓.
- Keine Stufe tiefer als 1,2 m (ZU_TIEF 1,5, sprungprobe.gd:55) ✓.

### 6.3 Geheimnisse

| | Ort | Höhe | Weg hinauf | Inhalt | Kosten |
|---|---|---|---|---|---|
| G1 Eichelvorrat | s 0–2, q +5, Wurzelknie | +2,8 | Doppelsprung (gemessen: trägt) | FRUCHT_MEHRFACH, 2 NORMAL, 6 Früchte | keine (vor der Jagd) |
| G2 Böschungsbank | s 82–87, q +4,6…+6,0 | +2,2 | Slide-Sprung (Fenster ≥ 3,4 m) oder Doppelsprung, Einzelsprung nicht | 4 NORMAL, 3 Früchte | ≈ 1–2 m Abstand (gerechnet) |
| G3 Sonnensims | s 253,5–257,5, q +4,2…+5,6 | +2,6 | Trittstein bei 252/q +3,4 (1,2 m, Ebene 1, ohne Stolperzone), dann zwei Einzelsprünge | FRUCHT_MEHRFACH, 2 NORMAL, 5 Früchte | ≈ 8 m Abstand (gerechnet), nur mit vollem Vorsprung |

Die Leitlinien bekommen an G2 und G3 eine Nische hinter der Bank (JS13).

### 6.4 Zählung

**Kisten: 49.** Davon 46 NORMAL (im Zeitmodus 15 Zeitkisten), 2 FRUCHT_MEHRFACH, 1 LEBEN.

| Abschnitt | Lage |
|---|---|
| A | 7 NORMAL: 20,4 / 21,6 auf q 0; Grabensohle 24,6 / 25,8 / 27,0; G1 2. Dazu FRUCHT_MEHRFACH auf G1 |
| B | 13: 36,0–38,4 (3); 65,0–67,4 (3); G2 (4); 110,0–112,4 (3) |
| C | 9: T1 128,6 / 129,8; T2 144,5 / 145,7; T3 152,5 / 153,7; T4 167,5 / 168,7 / 169,9 (q +2,0) |
| D | 12: 182,0–184,4 (3); 200,4 / 201,6; 237,0 / 238,2; 260,0–262,4 (3); G3 (2). Dazu FRUCHT_MEHRFACH auf G3 |
| E | 5: 271,0–273,4 (3); 292,9 / 294,1. Dazu LEBEN bei 291,5 |

Alle Kisten außer in A und den Geheimnissen liegen auf q +2,2 bzw. +2,0 und werden über `boden_bei` gesetzt, Abstand untereinander 1,2 m.

**Früchte ≈ 119:**

| Abschnitt | Anzahl | Inhalt |
|---|---|---|
| A | 24 | Eichelspur 8, Ü-Bodenlinie 4, Grabenbogen 6, G1 6 |
| B | 32 | Bögen über H1/H2 je 3, Bodenlinien vor D1/D2 je 4, L1-Bogen 6, Spur und Bank G2 7, Lauflinie 112–118 5 |
| C | 21 | Treppenlinien 3 × 3, Bögen über L2/L3 je 6 |
| D | 30 | Bögen über L4/L5 je 6, Bodenlinien vor D3/D4 je 4, Gassenlinie 5, G3 5 |
| E | 12 | Wehrbogen auf der Doppelsprungbahn 7, Ziel 5 |

### 6.5 Checkpoints

Zonen wie heute (level05.gd:287-331), aber auf `boden_bei` und `breite_bei + 2`.

| CP | s | nächste Lücke | Abstand | nächstes Hindernis |
|---|---|---|---|---|
| CP1 + Wecken | 31 | L1 | 44 m | H1, 13 m |
| CP2 | 122 | L2 | 14,3 m | – |
| CP3 | 178 | L4 | 16 m | – |
| CP4 | 204 | L5 | 24,5 m | D3, 10 m |
| CP5 | 268 | L6 | 16 m | – |

Nach einem Tod steht der Keiler bei s_CP − 12. Hinter dem Rastplatz sind alle Durchlässe wieder heil.

### 6.6 Richtzeit

**Vorschlag: `zielzeit()` = 46 s, vorläufig**, mit Gold 39,1 s und Platin 33,1 s.

- Die Formel ergäbe 296 / 8,5 × 2,8 ≈ 97 s; damit wären alle Stufen geschenkt.
- Ideallauf ohne Zeitkisten ≈ 34,4 s (gerechnet: A 2,7 s + ab CP1 30,9 s + 0,8 s).
- Endgültig: 1,3 × Bot-Zeit aus Spieltest bzw. Jagdprobe, auf ganze Sekunden gerundet, nach dem Muster von L06 (level06.gd:64-73).
- Damit gilt: Saphir für jeden Überlebenden mit 1–2 Fehlern, Gold für einen sauberen Lauf, Platin für einen fast perfekten Lauf plus 1–2 Zeitkisten. Die Kistengassen sind Slide-Linien, Zeitkisten kosten also kaum Zeit.
- JS12 (30 s) verworfen: Saphir verlangte dann ≥ 4,4 s Frost, also Kistenjagd unter Druck. Für Raum 1 ist das zu hart.

---

## 7. Kamera, Kollision, Todeszonen

### 7.1 Kamera

Level05.tscn:
- `far = 380`.
- `sicht_maske = 8`: neues `@export` in corridor_camera.gd, Vorgabe `1 | 8`; `_freie_sicht` (:334) liest es. Falls der Kameraplan es schon anlegt, nur nutzen.
- Schatten: `directional_shadow_mode = 1` (2 Stufen), max 70 m, `split_1` 0,45. Heute stehen dort 4 Stufen auf 90 m (Level05.tscn:55, JT6). Der Handyweg nimmt automatisch eine Stufe auf 50 m (level_basis.gd:264-266).

**Freiraum-Regeln (K):**

| Regel | Inhalt |
|---|---|
| K1 | Über \|q\| ≤ 3,5 ist zwischen 4,6 und 9,2 m über dem Weg nichts Sichtbares. Durchlass-Kappen ≤ 4,6, Kronen ≥ 9,5. |
| K2 | Bei Durchlässen darf Boden − Kurve auf den 21 m davor nicht steigen (5,6 + off(s−21) − off(s_D) ≥ 5,3; gerechnet 5,60–6,05). |
| K3 | Der Kegel ±6° von der Kamera zur Eichenkrone bleibt frei: ein Himmelsspalt über dem Hohlweg. `Waldrahmen` nimmt das Auge aus der echten Kamera (wald.gd:631-637 ist fest 9,5/6). |
| K4 | Von s+12 bis s+21 stehen keine Stämme bei \|q\| < 8. |
| K5 | In Durchlässen ist nur der Riegel 0,95–1,40 massiv; der Rest hat ≥ 60 % offene Fläche als Geometrie. |

### 7.2 Ebenen

| Ebene | Inhalt |
|---|---|
| 1 | Wegdecke, Terrassen und Treppen (`stufen_kollision`), Grabenrampe, Trittstein, Wehrkrone, Kisten |
| 16 (`SPIELERGRENZE`) | Leitlinien am Böschungsfuß (Höhe 5, mit Nischen an G2/G3), Körper der Durchlässe, Hürden und Findlinge, Wehrpfähle |
| Areas (Maske 2) | Stolperzonen (Durchlass nur an der Stirn), Rastplätze, Todeszonen |

Die Figur stößt an Ebene 16 (gemessen). `_kann_aufstehen` prüft mit Maske 17 (player.gd:610-628).

### 7.3 Todeszonen

- `absturz_hoehe()` = −7, `absturzzonen(20, 60)`: Die Sturzprobe bei q 26 fällt nach ≈ 41 Bildern in die Zone, die Probe wartet 90 (TE-B9, JS13).
- L1–L6 bekommen je eine `todeszone()` auf fester Höhe (level_werkzeuge.gd:1147, Gruppe `todeszonen`), Oberkante ≥ 2 m unter der unteren Lippe. Am Wehr liegt sie auf Y 2,6 unter dem Weißwasser.
- Der Suhlgraben ist nicht tödlich. Seitlich abstürzen kann man nirgends.
- Tiefster Boden 3,0, weit über TODESHOEHE −12 (player.gd:28).

---

## 8. Bild

### 8.1 Bildregel

„Die Abendsonne steht hinter der Kamera. Vorn unten ist warm, hell und scharf: der Ausweg. Hinten oben ist kühl, dunstig und klein: die Herkunft. Dort leuchtet nur die Hauereiche golden.“

- Eiche, Keiler, Läufer und Ausweg liegen auf der Mittelachse.
- Rahmen gibt es nur seitlich: bildlinks (q > 0) Sonnenhang, bildrechts (q < 0) Schatten und Wasser (level_werkzeuge.gd:50-52).
- Nur in diesem Level sieht man die eigene Spur zurück bis zum Start.

### 8.2 Hauereiche (gerechnet)

- **Ort:** s −6 auf der Kuppe (Y 27).
- **Fuß:** r 1,9, 5 m hoch, 7 Brettwurzeln.
- **Stamm:** zwei Hälften mit r 1,1 → 0,6, je ≈ 20 m, nach außen geneigt (`Riesenstamm.netz` mit `neigung`/`krumm`, riesenstamm.gd:99-113). Die Spaltflächen sind hell und verwittert und zeigen zur Kamera; dafür braucht `Riesenstamm` eine neue Option `spalt`.
- **Kronen:** 2 × `Kronenwolke` Variante 1 (kronenwolke.gd:30), r 7,5, Mitten bei q ±11 und Y ≈ 55, mit **7 m Kerbe**.
- **Fernform:** ab 85–100 m über `visibility_range`, `schlicht` plus `Kronenwolke.fern`, `nebelarm` mit Anteil 0,45, für die Kuppe 0,7.
- **Sicht:** auf 95 % der Stellen 6–296 im Bildstumpf 16:9 (ohne Verdeckung durch Gelände). Ab s ≈ 20 sind die Kronen im Bild, am Start der Spaltstamm.
- **Beiwerk:** zwei Krähen kreisen über der Eiche.

### 8.3 Licht, Himmel, Nebel

Alle Werte sind Startwerte (ungeprüft).

- **Himmel:** `himmel.gdshader` statt ProceduralSky (Level05.tscn:8):

  | Uniform | Wert |
  |---|---|
  | zenit | (0,16/0,30/0,58) |
  | horizont (rosé) | (0,84/0,64/0,60) |
  | dunst | Nebelfarbe |
  | Wolken | (1,0/0,82/0,70), Menge 0,58 |
  | huegel_hoehe | ≥ 0,07 (≥ 4°, Weltkante JT10) |
  | schein | 0,1 |

  Dazu `horizont()` (korridor_level.gd:652) und ein grober Geländering.
- **Sonne:** 30–40° rechts hinter der Kamera, Höhe 26°, Farbe (1,0/0,80/0,56), Energie 1,0. Schattensaum ≤ 3 m rechts; Hauptlinie und Kisten liegen im Licht. In P8 werden zwei Varianten verglichen (JT7).
- **Weitere Lichter:**

  | Licht | Farbe | Stärke |
  |---|---|---|
  | Himmelslicht | (0,52/0,62/0,95) | 0,38 |
  | kühles Kantenlicht aus ONO | (0,62/0,70/0,95) | 0,18 |
  | warmes Bodenlicht | – | 0,14 |
  | Umgebung | (0,40/0,44/0,60) | × 0,42 |

- **Nebel und Umgebung:** Tiefennebel (fog_mode 1) 16 → 240 m, Dichte 0,85, Kurve 1,4. Sättigung 1,0 statt 1,25, Kontrast 1,06, Glow 0,5 ab 1,0. `Bildrahmen` mit Stärke 0,32 und Farbe (0,05/0,03/0,02).
- **Zonen:** Regler nach Strecke s (`Stimmungsregler`, keine Area-Stücke), Werte relativ:

  | Zone | Licht | Nebel | Nebelfarbe | Besonderes |
  |---|---|---|---|---|
  | A 0–31 | 0,75 | 0,9 | (0,46/0,48/0,46) | Kronenlicht, 2 Schächte |
  | B 31–120 | 1,1 | 0,85 | (0,56/0,60/0,72) | Pollen |
  | C 120–180 | 1,15 | 0,8 | (0,58/0,60/0,70) | Staub |
  | D 180–265 | 0,9 | 1,2 | (0,48/0,56/0,64) | Bachnebel-Tafeln |
  | E 265–300 | 1,2 | 0,75 | (0,62/0,60/0,70) | weiteste Sicht |

- **Farbziele (kontaktbogen):** Weg-Luma am höchsten, kühl ≥ 12 %, warm ≤ 55 %, warme Akzente ≤ 6 %.

### 8.4 Lesbarkeit (Ankündigung ab ≈ 14 m)

| Element | Zeichen |
|---|---|
| Tödliche Lücke | 4–6 helle Lippensteine bündig, Pilze als Kopie von `_pilz` (level01/boden.gd:479), dunkle Flanke mit Albedo ≤ 0,1, Fruchtbogen |
| Durchlass | Unterkante des Riegels hell, Früchte am Boden in Slide-Richtung, Vorhang offen |
| Hürde | hell abgewetzter Rücken, Moosflanken, kleiner Fruchtbogen |
| Stufe | Wurzeltreppe, Fruchtlinie hinab, keine Steine |
| Findlingsgasse | Fruchtlinie durch die freie Gasse |
| Rastplatz | Wegpfahl mit leuchtendem Netz (`Materialbibliothek.leuchtend`) |
| Mühlrad | ab ≈ 15 m bildrechts im Bild (gerechnet), Klang „muehle“ als Schleife |

**Keiler:**
- Dunkle Silhouette mit elfenbeinfarbenen Hauern, Augenglut nach `naehe`, goldene Staubfahne, Atemdampf.
- Hopser über Stufen und Lücken mit Staub.
- Durchlässe splittern, an D3/D4 kommt ein Wasserschwall aus dem Gerinne.
- Am Ufer schlittert und schnaubt er.

### 8.5 Modelle

| Rolle | Quelle | Lizenz und Ort | Hinweis |
|---|---|---|---|
| Hang- und Böschungsbäume | UNP `CommonTree_1–5` | CC0, im Repo (CREDITS.md:12) | Instanzton 60 % oliv, 25 % ocker, 15 % kupfer; Laub ohne Schatten |
| Totholz an der Kuppe | UNP `CommonTree_Dead_1/2` | CC0, im Repo | – |
| Birken im Tobel | UNP `BirchTree_1–5` | CC0, in `natur2/unp/` (Baukasten G4, CREDITS.md) | Rolle M20 |
| Sträucher, Beeren | UNP `Bush_1/2`, `BushBerries_1/2` | wie oben | Rolle M24 |
| Felsen im Tobel | UNP `Rock_1–7`, `Rock_Moss_*` | CC0, wie oben | sandsteinfarben getönt; Rolle M21 |
| Eiche, Baumtore, Fernwald, Wurzeln | `Riesenstamm`, `Kronenwolke` | prozedural | – |
| Findlinge, Trittstein | `Findling.netz` (findling.gd:71) | prozedural | – |
| Unterwuchs | `Farnwerk.stoff` in Kupfer (Adlerfarn), `Rasensaum`, `Bodenstreu` (Laub) | prozedural | Stoffe nur über `duplicate()` |
| Keiler | keiler.gd | selbstgebaut | – |

Keine Kenney-Modelle und keine Nadelbäume. Höchstens 25 Modelle, nahe Bäume ≤ 3000 Dreiecke (natur2/LIESMICH.md).

---

## 9. Technik

### 9.1 Module

`scenes/levels/level05.gd` bleibt `class_name Level05 extends KorridorLevel`.

- **Daten:** KURVE, KURVENHOEHE, ABSAETZE, TERRASSEN, STRECKE, LUECKEN, DURCHLAESSE, HUERDEN, FINDLINGE, KISTEN, FRUECHTE, RASTPLAETZE, GEHEIMNISSE, EICHE, JAGD.
- **Abfragen:** `boden_bei`, `weg_punkt`, `ist_luecke`, `pruefprofil`, `sprungfaelle`, `duckstellen`, `wahrzeichen`, `gelaende_hoehe`, `pruefruhe`, `zielzeit`.

Je Modul eine Klasse unter `scenes/levels/level05/` mit `static func bauschritte(level: Level05) -> Array`. Den Zustand halten Instanzen des Levels, kein `static var`.

| Datei | Klasse | Inhalt |
|---|---|---|
| jagd.gd | `L05Jagd extends Node` | Schlaf → Wecken (CP1) → Jagd → Ufer (282) → Schnauben auch nach dem Ziel. Höhe aus `boden_bei` plus Hopser (Scheitel 0,8 + 0,25·Weite, Hürde 0,6). Durchlass-Bruch ab keiler_s ≥ s_D − 1,5 (Körper aus, Bruchnetz an), Heilen beim Respawn. `_nach_tod` vor `WECK_S` schläft wieder. `pruefruhe()`. Ersetzt level05.gd:363-430; die Jagdkonstanten bleiben. |
| gelaende.gd | `L05Gelaende` | Westhang (−25 m), Kuppe r 40 / +3 m, Suhle, Hohlwegkrone, Terrassenhang, Tobelmulde, Mühlwiese, grober Ring bis zur Weltkante |
| saum.gd | `L05Saum` | Lössböschungen 70–85°, Stirnen an Terrassen und Lücken, Ufer, Wehrwände |
| wasser.gd | `L05Wasser` | Suhle, Rinnsale, Tobelbach (Bachband), Mühlteich, Wehrfall, Mühlrad (`PHYSICS_INTERPOLATION_MODE_OFF`) |
| eiche.gd | `L05Eiche` | nah und fern, Nebelanteil |
| wegbauten.gd | `L05Wegbauten` | Optik genau auf der Kollision (Findling-Regel): Gatter, Wurzelbogen, Fluderjoch (heil und gebrochen), Hürden, Findlinge, Treppen, Grabenrampe, Wehr, Rastplätze |
| wald.gd | `L05Wald` | Waldsetzer in drei Stufen, nah ≥ 150 m, Fernband ≥ far (JT9) |
| rasen.gd | `L05Rasen` | Rasensaum auf den Kronen, in A und E; Laubstreu am Wegrand; Kupferfarn |
| stimmung.gd | `L05Stimmung` | Regler nach s; Staub, Laub, Pollen, Krähen, Klangschleife Mühle |

### 9.2 Gemeinsame Bausteine

Was L02–L04 unter `scripts/gemeinsam/` schon angelegt haben, wird genutzt; den Rest legt L05 an. Level-01-Dateien werden nie geändert, nur kopiert.

| Baustein | Quelle | Weg |
|---|---|---|
| `Wegdecke.stoff/lippen` | wegboden (`erde_ton`, `wald_rasen`, `luecken[8]`, wegboden.gdshader:56-80), boden.gd:479 | Cache je Level, nicht je Art (boden.gd:44). 6 Lücken + Graben ≤ 8 |
| `Kanten.profil_boeschung/stirn/ufer`, `seite_schritte` | saum.gd:1306 / :1792 / :827, Rahmen :323/:414 | kopieren |
| `GelaendeBau.schritte` | gelaende.gd:263-295, :407-430 | Muster; Schlüssel `l05_gelaende_voll/handy` |
| `Bachband` + shaders/bach.gdshader | wasser.gd:135, :363, :426 | kopieren |
| `Stoffzusatz.nebelarm` | weltenbaum.gd:436-450 | kopieren |
| `Waldrahmen`, `Baumfabrik` | wald.gd:646-750, :776-1219 | kopieren; Auge aus der echten Kamera |
| `Stimmungsregler` | stimmung.gd:264 | kopieren |

### 9.3 Änderungen an geteilten Dateien

Alle sind additiv und haben heutige Vorgaben.

- **Kamera** (corridor_camera.gd): `sicht_maske`.
- **Reiter, Floß:** keine.
- **Keiler** (keiler.gd): von 33 Netzen auf 7 Glieder (Rumpf, Kopf, Augen, 4 Beine) mit Scheitelfarben. Neue Haltungen `schlafen`, `erwachen` (0,5 s im Lauf), `in_luft`, Hangneigung, `schnauben`; Augenglut nach `naehe`. Nur L05 benutzt ihn.
- **korridor_level.gd** (L01 erbt nicht davon, level01.gd:1):
  - `boden_bei(s)` aus `abschnitte()` über `eintrag_hoehe` (level_werkzeuge.gd:165), in Lücken NAN;
  - `kiste_auf`, `frucht_auf`, `portal_auf`;
  - Bauteile `duckdurchlass(s, tiefe, optik)`, `huerde(s, optik)`, `findling_hindernis(s, q, breite)`;
  - `sichtweiten_einrichten(kiste, frucht, gegner)` nach level01.gd:845-857/1136-1175.
- **Klang.gd:** neuer Klang „muehle“ (`_bau_muehle`). Schleife und Lautstärke regelt L05Stimmung, denn `Klang.spiele` spielt nicht räumlich (Klang.gd:102).
- **Werkzeuge:**
  - sprungprobe.gd: Feld `art` (lauf, slide, doppel, duck, huerde) sowie `pflicht` und `darf_nicht_tragen`; `pruefruhe` nach :100.
  - level_check.gd: Maske von der Kamera statt :81/:751; `pruefruhe` vor Sturzprobe und Sichtprobe.
  - foto.gd: `pruefruhe` nach :168.
  - spieltest.gd: Opt-in `duckstellen()`.
  - schaufenster.sh:101-110: Teile `l05` und `l05seite`.
  - Neu: `werkzeuge/jagdprobe.gd`.

### 9.4 Bauschritte, Bauspeicher, Ladezeit

Verlauf und Wegdaten entstehen vor der Schrittliste (wie level01.gd:878-879). Reihenfolge:

1. Hang: vermessen, Stücke, Farbe (warm: „Der Hang wird geladen“)
2. Hohlweg: Decke, Kollision, Leitlinien, Todeszonen
3. Böschungen links, rechts, Stufen und Ufer (`l05_saum_*`)
4. Suhle, Bach und Mühlbach
5. Die Hauereiche
6. Wurzelbögen und Hürden, Wehr und Mühle
7. Kisten, Früchte, Rastplätze (vor Wald und Rasen)
8. Hangwald, Kamm und Ferne
9. Rasen, Streu
10. Abendlicht
11. Der Keiler schläft

**Ziel (Bauzeitprobe headless):** kalt ≤ 8 s, warm ≤ 4 s, Runde 2 ≤ 0,3 s, kein Schritt über 400 ms. Heute: 4,9 / 2,5 s.

Neue Skripte ändern den Bauspeicher-Fingerabdruck (bauspeicher.gd:187). L01 baut danach einmal kalt; das kostet Ladezeit, ändert aber kein Bild.

### 9.5 Handyweg (`Effekte.reduziert`)

- Gras und Streu ×0,5, Fernwald ×0,6, Staub und Laub halbiert, kein Glitzern.
- Eiche ab 60 m nur als Fernform.
- Sichtweiten: Kisten 40 / Früchte 35 (Desktop 50 / 40, ab Kamera).
- Eine Schattenstufe (automatisch).

---

## 10. Leistungsbudget

**Gemessen** (Kopie, L05 ohne Boden, Wände, Bäume und Gras; mit Figur, Keiler alt mit 33 Netzen, 60 Kisten, allen Früchten, HUD und Himmel; Schatten wie heute mit 4 Stufen):

| Stelle | Draw-Calls ohne Sichtweiten | mit Sichtweiten 50/40 | Handy (reduziert + Touch, 40/35) |
|---|---|---|---|
| s 60 | 208 | **170** (179k Primitive) | **232** |
| s 220 | 314 | **208** (200k Primitive) | **236** |

Damit ist JT6 bestätigt: Spiel + HUD ist ohne Sichtweiten der größte Posten.

| Modul | Desktop | Handy | Mittel |
|---|---|---|---|
| Spiel + HUD (gemessen) | 170–208 | 232–236 | Sichtweiten |
| Keiler verschmolzen, 33 → 7 Netze | −40 bis −60 (gerechnet) | −35 bis −50 | Glieder, 2 statt 4 Schattenstufen |
| Weg + Lippen | 8 | 8 | 1 Decke, Lippen je Lücke verschmolzen |
| Saum | 30 | 24 | Stücke, keine Schatten |
| Gelände + Ring | 12 | 12 | – |
| Wasser + Mühlrad | 10 | 8 | – |
| Eiche | 10 (+3) | 6 | nah/fern |
| Wegbauten | 30 (+10) | 18 | je Abschnitt verschmolzen |
| Wald | 70 (+30) | 50 | Waldsetzer, Laub ohne Schatten |
| Rasen, Farn, Streu | 35 | 20 | Ende 42 m |
| Stimmung | 12 | 6 | – |
| **Summe** | **≈ 380–420** | **≈ 340–350** | |

**Grenzen:**
- Desktop ≤ 500 je Fotostelle, Ziel ≤ 450.
- Handy ≤ 450, Ziel ≤ 405 (10 % Reserve).
- Primitive ≤ 750k; gemessen 179–200k plus geschätzt ≈ 350k für das Level.
- VRAM ≤ 140 MB (gemessen 41,8 MB für Spiel + HUD).

Schatten werfen nur Stämme, Kisten, Figur und Keiler.

---

## 11. Risiken

1. **Slide-Sprung:** Er ist nur Kür (Entscheidung 4, vom Nutzer bestätigt). Eine faire Pflichtstelle gibt es nicht (gemessen).
2. **Nebenbefund `cash_banooka_rc.glb`:** fehlt in CREDITS; laut CREDITS.md:46 ist die Spielfigur selbstgebaut. Die Standardfigur ist prozedural (Einstellungen.gd:103-112). Das klärt der Nutzer gesondert; die Datei hat er selbst eingecheckt. Die Bilder laufen mit frischem Profil.
3. **Durchlass liest sich nicht als geschlossen:** Bei ≥ 60 % offener Fläche könnte jemand hindurchspringen wollen. Abnahme im Bild bei s 90 und 218; Rückfall Vorhang 45–50 % offen. Die Oberkante bleibt.
4. **`sicht_maske 8`:** Die Kamera wird nie mehr herangeholt. Die K-Regeln (7.1) sichern das ab; die Sichtprobe läuft mit Kameramaske und Freiraumprobe K1/K2.
5. **`far 380`:** Tiefengenauigkeit auf dem Handy ungeprüft (Saum in der Ferne). Abnahme mit Handyfoto bei s 280/296.
6. **Messbank ohne Kamera:** Kurs ±8° und kamerarelative Steuerung können die Fenster um Zentimeter verschieben. Verbindlich ist die Sprungprobe im Level (P1).
7. **Eiche:** 95 % sind gegen das Wegprofil gerechnet, ohne Gelände und Bäume. Die Wahrzeichenprobe muss ≥ 70 % messen.
8. **Keiler-Hopser auf Terrassen und an der Kuppe:** nur Optik. Jagdprobe: Höhe ≤ 0,05 m vom Boden außerhalb von Hopsern.
9. **Touch-Tasten** verdecken eventuell untere Bildecken mit Kisten; Fotos bei 90/218 mit `FOTO_TOUCH=1`.
10. **Level 01 bleibt gleich**, obwohl geteilte Dateien berührt werden (Kamera, KorridorLevel, Klang, Werkzeuge, Werkstatt). Nachweis nach jedem Paket (Wächter) und in P9.
11. **Ladezeit:** neue Module, Bauspeicher-Fingerabdruck.
12. **Sonnenrichtung:** Frontlicht modelliert wenig. Zwei Varianten im Bild (P8).
13. **Zeitmodus:** Die Richtzeit ist vorläufig, Messung in P8.

---

## 12. Arbeitspakete

Reihenfolge nach CLAUDE.md Regel 1: erst Kameraplan, dann L02–L04, dann diese Pakete. Jedes Paket ist ein eigener Durchlauf.

### P1 `rohbau`: Kurve, Kollision, Spiel, Jagd, Proben
- **Ziel:** Graubox, voll spielbar.
- **Dateien:**
  - level05.gd (Daten, Abfragen), level05/jagd.gd, Level05.tscn (`far`, `sicht_maske`, Schatten);
  - corridor_camera.gd (`sicht_maske`);
  - korridor_level.gd (`boden_bei`, `*_auf`, `duckdurchlass`, `huerde`, `findling_hindernis`, `sichtweiten_einrichten`);
  - sprungprobe.gd, level_check.gd, foto.gd, spieltest.gd (Opt-in), neu werkzeuge/jagdprobe.gd.
- **Abnahme:**
  - `parse.sh`; `PRUEF_LEVEL=01,05 pruefe.sh` meldet SAUBER.
  - LevelCheck mit `pruefprofil` {sicht, todeszonen, rand}.
  - Sprungprobe: Fenster wie in 6.2 (Raster 0,25; L4 ≥ 1,25; Wehr: Doppel ≥ 2,0, Einzel `darf_nicht_tragen`, Slide-Sprung `pflicht:false`; Durchlass ≥ 3,0 m sauber; Hürde ≥ 1,5).
  - Jagdprobe:
    - Ideallauf, Mindestabstand ≥ 10 m;
    - jeder Rastplatz mit 3 s ohne Tod;
    - Krabbeln überlebbar;
    - zwei Stolperer in D3/D4 überlebbar;
    - Keilerhöhe ≤ 0,05 m vom Boden.
  - Spieltest mit `duckstellen`, auch mit `TEST_DOPPELSPRUNG=0` (muss am Wehr scheitern).
  - Messtor-Fotos verfolger 8/60/140/218/280/296 mit `pruefruhe`, Desktop und Handy: Spiel + HUD ≤ 170/240.

### P2 `gemeinsam`: fehlende Bausteine
- **Ziel:** 9.2, soweit L02–L04 es nicht schon gebaut haben.
- **Dateien:** `scripts/gemeinsam/*`, shaders/bach.gdshader.
- **Abnahme:** Schaufenster L01 und Portalraum pixelgleich (`getbbox` None, `werte.tsv` gleich); Bauzeitprobe L01 mit gleichen Schritttexten.

### P3 `gelaende` + `saum`
- **Ziel:** Hang, Kuppe, Hohlweg, Terrassen, Tobel, Weltkante; Lösswände, Stirnen, Ufer.
- **Dateien:** level05/gelaende.gd, level05/saum.gd.
- **Abnahme:**
  - Fotos seite 40/150/240 ohne Nähte.
  - Bauspeicher warm ≤ 4 s.
  - Sturzprobe grün.

### P4 `eiche`
- **Ziel:** Zwiesel mit Spalt, Kronen mit 7 m Kerbe, Fernform, `nebelarm`.
- **Dateien:** level05/eiche.gd, riesenstamm.gd (Option `spalt`, Vorgabe aus).
- **Abnahme:**
  - Wahrzeichenprobe ≥ 70 %.
  - Kerbe ≥ 16 px bei 720p auf s 296.
  - Werkstatt-Station Riesenstamm unverändert.

### P5 `wegbauten` + Keiler-Optik
- **Ziel:** Gatter, Wurzelbogen, Fluderjoch (heil und Bruch), Hürde, Findlinge, Treppen, Wehr, Rastplatz-Pfahl, Mühle; keiler.gd mit 7 Gliedern und Haltungen.
- **Dateien:** level05/wegbauten.gd, keiler.gd.
- **Abnahme:**
  - Durchlass im Bild offen und doch geschlossen lesbar (Fotos 90/218).
  - Bruchnetze in `VORWAERM_GRUPPE`.
  - Glattprobe L05 ohne ZITTERT.
  - Keiler ≤ 19 Draw-Calls (Desktop).

### P6 `wasser`
- **Ziel:** Suhle, Rinnsale, Bachband, Mühlteich, Wehrfall, Mühlrad.
- **Dateien:** level05/wasser.gd.
- **Abnahme:**
  - Todeszone nur im Wehr.
  - Mühlrad ab ≈ 15 m im Bild.
  - Draw-Calls Wasser ≤ 10.

### P7 `wald` + `rasen`
- **Ziel:** drei Waldstufen mit Fernband, K3/K4 frei, Kupferfarn, Laubstreu; Modelle importieren.
- **Dateien:** level05/wald.gd, level05/rasen.gd, `natur2/unp/` (Birke, Busch, Rock), CREDITS.md:12.
- **Abnahme:**
  - Kein Stamm bei \|q\| < 8 im Vordergrund.
  - Kein sichtbares Aufploppen auf 120 m.
  - Portalraum und L01 pixelgleich (neue Rollen).

### P8 `stimmung` + `leistung`
- **Ziel:** Licht, Himmel, Nebel, Zonen, Bewegung, Klang; Budget; Richtzeit.
- **Dateien:** level05/stimmung.gd, Level05.tscn, Klang.gd.
- **Abnahme:**
  - Je Fotostelle Desktop ≤ 500 (Ziel 450) und Handy ≤ 450 (Ziel 405), Primitive ≤ 750k, VRAM ≤ 140 MB.
  - kontaktbogen-Farbziele gegen die L05-Zeile in vorher/bogen.jpg.
  - Zwei Sonnenvarianten bei s 60.
  - Rundgangprobe und Ruckelprobe (`RUCKEL_REDUZIERT=1`) mit L05.
  - Bauzeit kalt ≤ 8 s.
  - `zielzeit()` aus Spieltest × 1,3.
  - Nachher-Bilder erst nach der Klärung zu `cash_banooka_rc.glb`.

### P9 `doku` + `werkstatt`
- **Ziel:**
  - Bauteile Duckdurchlass (3 Optiken mit Bruch), Wurzelhürde, Findlingshindernis, Wurzeltreppe mit Terrassenlücke 1,2 m und Wehrbruch in die nächsten freien Werkstatt-Stationen (`M_ENDE` anheben, werkstatt.gd:22).
  - Einträge in doku/level-vorbilder.md, README und ARCHITEKTUR.
- **Abnahme:**
  - Werkstatt lädt fehlerfrei.
  - `VORHER=HEAD SCHAUFENSTER_TEILE=l01,l01seite,l01nah,hub` gegen den Arbeitsstand: `werte.tsv` gleich, Differenzbilder leer (vorher HEAD gegen HEAD).
  - Bauzeitprobe L05 → L01 im selben Prozess.
  - level_check, Sprungprobe und Wegmaskenprobe für L01 melden SAUBER.

---

## 13. Umsetzung: Pakete, Commits, Messwerte

Gemessen wurde jeweils in einer Kopie des Arbeitsstands, ohne Kopf
(llvmpipe, 4 CPUs). Zeiten sind Zeiten dieses Rechners. Draw-Calls und
Primitive gelten für die Fotostellen (Messtore) 8, 60, 140, 218, 280 und
296, gemessen mit `foto.sh` und `FOTO_WERTE`. „Zeilengleich“ heißt: Das
Protokoll der Probe stimmt Zeile für Zeile mit dem Stand davor überein.

Nach jedem Paket lief der Wächter: `parse.sh` und `pruefe.sh` SAUBER,
Schaufenster-Teil `wache` 6 von 6 Bildern pixelgleich, die Protokolle von
Level 01 (LevelCheck, Sprungprobe, Bauzeit) gleich. Die gemeinsamen
Bausteine aus P2 (Wegdecke, Kanten, GelaendeBau, Bachband, Nebelstoff,
Waldrahmen, Baumfabrik, Rasenbau, Stimmungsregler) stammen aus dem Baukasten
G0–G5 (`5b1b59d` … `fa041a0`). Die Kamera bekam ihre Maske (`sicht_maske`)
und die Freiraumprobe in G6-teil (`49511c8`).

### P1a Rohbau (`c426f42`)

- **Kurve:** alle 3 m ein Punkt bei der 3D-Bogenlänge s, aus den zwölf
  Stützpunkten und KURVENHOEHE. Die Stützpunkte liegen höchstens 0,008 m
  neben ihrem s (vorher bis 1,07 m). Die Kurve liegt höchstens 0,036 m
  neben KURVENHOEHE. Die Kamera steht mindestens 3,486 m über der Figur.
  |Boden − Kurve| höchstens 0,646 m (Entwurf 0,64).
- **Spiel:** 49 Kisten, 119 Früchte, 5 Rastplätze, 3 Geheimnisse, Portale
  bei 6 und 296. Sichtweiten Kisten/Früchte 50/40 m, Handy 40/35 m.
- **Proben:** LevelCheck 0 Fehler, 0 Warnungen (`pruefprofil` {sicht,
  todeszonen, rand, freiraum}). Sprungprobe 21 Fälle, davon 6 Kür, 0 Fehler.
- **Kür knapp:** L6 Slide-Sprung 0,75 m (Entwurf 0,80). G3: Trittstein
  1,00 m, Sims 0,50 m. Der Slide-Sprung auf G2 trägt nur bis 0,9 m vor der
  Stirn (Entwurf 0,4). Suhlgraben 1,00 m. L5, D1, D2 und D4 liegen genau auf
  ihrer Mindestbreite.

### P1b Jagd (`1884b2b`)

- **Keiler** (`L05Jagd`): Hopser über Lücken, Stufen und Hürden, Scheitel
  0,8 + 0,25 · Weite, über Hürden 0,6. Er bricht durch einen Durchlass, sobald
  er auf 1,5 m an der Stirn ist. Nach einem Tod steht er genau 12 m hinter dem
  Rastplatz, und die Durchlässe dahinter sind heil.
- **Jagdprobe** (neu, 13 Fälle, 0 Fehler):

  | Lauf | gemessen | gerechnet (§2.5) |
  |---|---|---|
  | Ideallauf, kleinster Abstand | 14,44 m | 12,8 m |
  | Abstand beim Wecken | 15,13 m | 15 m |
  | jeder Durchlass mit gehaltener Taste | 12,02 m | 6,5 m |
  | gestolpert an D3 und D4 | 6,66 m | 5,4 m |
  | dasselbe, dazu 0,3 s Zögern vor L5 | 6,66 m | 3,2 m |

  Gefangen wird man erst, wenn man 1,0 s vor L5 zögert (0,9 s: 2,49 m
  Abstand), weil der Slide nach dem Stolpern den Vorsprung zurückholt.
- **Nach einem Tod** steht der Keiler genau bei s 19, 110, 166, 192 und 256,
  also 12 m hinter dem jeweiligen Rastplatz.
- **Spieltest** (Bot mit `duckstellen` und `lauflinie`): geschafft in 40,7 s.
  Mit `TEST_DOPPELSPRUNG=0` starb er sechsmal, jedes Mal über dem Wehr.

### P3 Boden (`87751c0`, Mängel `be6e5b1`, `395f801`, `75e0a9c`)

- Wegdecke „Waldweg in Löss“ mit sieben Lücken im Shader (L1–L6 und der
  Suhlgraben), an L1–L6 Lippensteine und Leuchtpilze. Dazu das Gelände
  (`L05Gelaende`) und der Saum (`L05Saum`: Lösswände 70–85°, Ufer,
  Wehrwände, Stirnen, Setzstufen).
- **Lippen:** Narbe gegen Kollision −0,028 … +0,014 m.
- **Nähte:** Nahtprobe über die ganze Strecke 29907 Stellen, dicht an
  Graben, Übergängen und Wegende 62674 Stellen. Kein Gelände über der
  Kollision, keine Löcher.
- **Kronenprobe:** Am Ende von Runde 3 ist nichts mehr zu hoch.
- **Freie Plattenkanten:** 0 von 1846 Querschnitten.
- **Flanken der Lücken:** Albedo 0,002–0,004, im 95. Perzentil höchstens
  0,006 (Entwurf ≤ 0,1).
- **Bauzeit:** kalt 5,4 s, warm 1,9 s, Runde 2 173 ms.
- **Draw-Calls:** Rechner höchstens 288, Handy höchstens 298.

### P4 Hauereiche (`76dcee9`, Mängel `041622b`)

- Gespaltene Eiche aus `Riesenstamm` mit der neuen Option `spalt` (ohne sie
  sind alle 107 Optionssätze bitgleich) und `Kronenwolke`. Sie hat eine Nah-
  und eine Fernform. Ab 100 m (Handy 60 m) wechseln beide Formen im selben
  Bild: Desktop bei s 72, Handy bei s 32.
- **Wahrzeichenprobe** (neu): 134 von 146 Stellen (91,8 %) frei im Bild
  (Ziel ≥ 70 %). Selbsttest 10 von 10 Punkten innen, 1350 Blicke, 0 Fehler.
- **Kerbe:** bei s 296 gerechnet 18,2 px, im Foto 18 px (Ziel ≥ 16).
- **Bauzeit:** Schritt „Die Hauereiche“ kalt 225 ms, warm 12 ms.

### P5 Wegbauten und Keiler (`3ec9df4`, Mängel `e879978`)

- **Durchlässe:** Wildgatter Ü, Wurzelbögen D1/D2 und Fluderjoche D3/D4, je
  heil und gebrochen. Der Riegel liegt genau bei 0,95–1,40 m. Die Stränge
  darunter sind zu 67–81 % offen (Ziel ≥ 60 %).
- **Passform:** Optik auf der Kollision innerhalb von 3 cm. Die Findlinge
  liegen −1,8 … +0,4 cm an ihren Flanken.
- **Sicht durch die Durchlässe:** Hinter Ü ist die Figur aus der Kamera im
  Mittel zu 70 % frei, hinter D3/D4 zu 30–31 %.
- **Keiler:** 8–16 Draw-Calls (vorher 66–90, Ziel ≤ 19). Glattprobe 0
  Abweichungen.

### P6 Wasser (`a8103d8`, Mängel `08b5c84`)

- Suhle, Rinnsale am Wasserriss, Tobelbach, Mühlteich, Weißwasser im
  Wehrbruch und Mühlrad (Ø 7 m bei s 291). Nichts davon ist tödlich.
- **Wehr:** Das Wasser liegt über |q| ≤ 3,5 mindestens auf Y 2,72, die
  Todeszone auf 2,60. 81 Todeszonen, davon 6 an Lücken.
- **Kosten:** Wasser und Mühlrad +1 … +7 Draw-Calls (Ziel ≤ 10). Rechner
  höchstens 204, Handy 267.
- **Bauzeit:** kalt 7,40–7,60 s.

### P7 Wald und Rasen (`c923de3`, Mängel `9a264b6`)

- **Wald:** in drei Stufen, nah, am Hang und als Fernband. Dazu Baumtore bei
  s 30 und 120, Birken im Tobel, Sträucher und Felsen. Kein Stammfuß bei
  |q| < 8 (0 von 627). Die Wahrzeichenprobe misst weiter 91,8 %.
- **Rasen:** Rasensaum, Laubstreu und Kupferfarn.
- **Bauspeicher:** Wald und Rasen liegen nach dem ersten Laden dort ab. Bau
  gegen Ablage: 0 Abweichungen.
- **Wechsel nah/fern:** frühestens 68,5 m (Rechner) bzw. 77,2 m (Handy) vor
  der Kamera.
- **Bauzeit:** Runde 2 245–284 ms, warm 2,7–2,8 s, kalt 9,3–10,1 s. Kalt lag
  damit über 8 s; das wurde in P8 behoben.

### P8 Stimmung, Klang, Leistung (`22c4ce4`, Mängel `81a941f`, `6d3aefa`)

- Himmel, Sonne 26° hoch 35° rechts hinter der Kamera, Tiefennebel 16 →
  240 m, Bildrahmen, Zonen A–E über den `Stimmungsregler`. Dazu Pollen,
  Staub, Laub, Bachnebel, Krähen und die Mühle als Klangschleife (neuer
  Klang „muehle“; die übrigen 17 Klänge bytegleich).
- **Kosten:**

  | | Desktop | Handy | Grenze |
  |---|---|---|---|
  | Draw-Calls | 177–305 | 243–324 | 500 bzw. 450 |
  | Primitive | ≤ 707k | | 750k |
  | VRAM | 101,0 MB | 76,7 MB | 140 MB |

- **Bauzeit** (Level 05 allein, sechs Läufe):
  - kalt 7,15–8,47 s, Median 8,05 s;
  - größter Schritt 272–368 ms;
  - warm 2,6–2,8 s, Runde 2 0,26–0,28 s.

  Die Grenze „kalt ≤ 8 s“ gilt für den Spielweg aus dem Portalraum. Für
  Level 05 allein ist ein Median bis 8,5 s erlaubt (Kopf von `level05.gd`,
  `_enter_tree`).
- **Richtzeit:** 48 s = 1,3 × 37,0 s Uhrzeit des Bots. Gold 40,8 s, Platin
  34,56 s. Der Ideallauf der Jagdprobe dauert 35,0 s.

### P9 Werkstatt und Doku

- **Werkstatt:** neue Stationen 34–38 auf einer verlängerten Kurve. `M_ENDE`
  steigt von 818 auf 1112, die Kurve endet bei 1122,9 m. Station 33
  (818–910) bleibt für den Kameraplan (G6) frei.
- **Kurve bitgleich:** Die alten Punkte und ihre Griffe sind unverändert.
  Alle 6064 gebackenen Punkte der alten Kurve sind gleich. In 0,1-m-Schritten
  bis 822,72 m stimmen Lage, Drehung und Oben überein.

  | Station | s | zeigt | Sprungprobe (Raster 0,25 m) |
  |---|---|---|---|
  | 34 | 910–998 | Wildgatter, Wurzelbogen, Fluderjoch, je heil (Tiefe 1,6/1,8/1,6) und 14 m dahinter gebrochen | heil: sauber 3,25 m je Optik (Ziel ≥ 3,0); gebrochen: Überlauf bis +937,6 / +965,9 / +993,6 |
  | 35 | 998–1014 | Wurzelhürde | Fenster 1,80 m im Raster 0,05 (Ziel ≥ 1,5; Station 30 „Hürde 0,7“: 1,80) |
  | 36 | 1014–1040 | Findlingsgasse, 4,6 m breit, versetzt um ±2,2 | Überlauf schräg durch die Gasse bis +1034,0 |
  | 37 | 1040–1084 | Wurzeltreppe (2 × 0,6 m), Terrassenlücke 3,4 m bei −1,2 m | Treppe bis +1051,8; Lücke 2,00 m (Ziel 1,85) |
  | 38 | 1084–1112 | Wehrkrone 7 m breit, Wehrbruch 5,0 m | Doppelsprung 2,25 m (Ziel 2,0); Einzelsprung trägt nicht; Slide-Sprung Kür 0,75 m |

- **Werkstatt-Proben:** Sprungprobe 22 Fälle, 0 Fehler. Die bisherigen 9
  Fälle sind zeilengleich zu HEAD. LevelCheck 0 Fehler, 0 Warnungen
  (11 Kisten, 3 Gegner).
- **Level 05 nach dem Umbau:** Die Optiken stellt `L05Wegbauten` jetzt
  außerhalb von Level 05 bereit. Sprung- und Jagdprobe L05 sind zeilengleich,
  und die Netze sind je Knoten gleich (ohne die bewegten Teile).
- **Abnahme P9:**
  - Schaufenster `VORHER=HEAD` mit den Teilen l01, l01seite, l01nah und hub
    gegen den Arbeitsstand: 17 von 17 Bildern pixelgleich, `werte.tsv`
    gleich. Gegenprobe HEAD gegen HEAD ebenfalls 17 von 17.
  - Bauzeitprobe Level 05, dann Level 01 im selben Prozess, zwei Runden,
    je zwei Läufe gegen HEAD unter denselben Bedingungen:
    - Die Schritte sind dieselben wie bei HEAD (Runde 1: 57 und 56,
      Runde 2: 24 und 49), es gibt keine Fehler.
    - Level 05 kalt 12,6–14,5 s (HEAD 12,3–14,9).
    - Level 01 danach 11,4–11,5 s (HEAD 10,7–11,5).
    - Runde 2: Level 05 0,39–0,48 s (HEAD 0,36–0,37), Level 01 4,9–5,3 s
      (HEAD 4,8–4,9).
  - Wächter:
    - `parse.sh` SAUBER (208 Skripte).
    - `pruefe.sh` SAUBER. Darin für Level 01: LevelCheck 0/0, Sprungprobe
      15 Fälle 0 Fehler, Wegmaskenprobe 0 Abweichungen (GPU-Abgleich
      höchstens 0,0091 bei Grenze 0,02).
    - `wache` 6 von 6 Bildern pixelgleich.
    - Die Protokolle von Level 01 (LevelCheck, Sprungprobe, Bauzeit) sind
      nach der Normalisierung gleich.

### R1 Mängel der Spiel- und der Bild-Jury

Jeder Punkt ist im Kopf des geänderten Moduls begründet; hier die
Übersicht mit den Messungen (Jagd-, Sprung-, Wahrzeichenprobe, LevelCheck,
Klangprobe, Fotos `--fixed-fps 30` mit festem Zufall).

**Spiel**
- **Figur hinter Riegeln und Latten (schwer):** Die Durchlässe tragen ihre
  Riegel nur noch an der Stirn, Unterkante 1,25 m (`RIEGEL_KANTE`), das
  Gatter Stangen nur in der Stirnebene alle 0,9 m, die Joche Latten alle
  0,7 m, alle mit einer Gasse von 0,9 m über der Wegmitte (`GASSE`). Was
  näher als 6,5–10 m vor der Kamera und höher als 1,9–2,7 m liegt, blendet
  ein Raster aus (`L05Wegbauten.nahblende`; so auch das Gerinnewasser).
  Neue Probe K5 im LevelCheck (`level05.gd`, `_freiraum_k5`): Sichtlinien
  Kamera → Figur im Anlauf jedes Durchlasses und jeder Hürde. Vorher Brust
  (0,7 m) frei zu 0–29 % (Ü 29, D1 0, D2 0, D3 10, D4 5, H2 58 %), jetzt
  79 % an allen fünf Durchlässen, H1/H2 100 %; Kopf 64–79 %.
- **Zeitmodus (mittel):** Richtzeit 15 s statt 48 s, Referenz mit den
  Zeitkisten der Hauptlinie (Variante a der Jury, dem Nutzer vorzulegen):
  Ideallinie ohne Kisten 35,28 s, mit den Kistenreihen 11,58 s (34 Kisten,
  23,7 s Standzeit); Gold 12,75 s, Platin 10,8 s.
- **Keiler nie nah (mittel):** Höchstabstand je Abschnitt 15 → 14 → 13 →
  12 → 11 m (`L05Jagd.HOECHST_STAFFEL`). Ideallauf Mindestabstand 10,44 m
  (vorher 14,44); „Stolpern an D3 und D4“ überlebt mit 3,74 m.
- **Keiler stumm (mittel):** vier neue Klänge (`Klang.gd`, additiv, eigene
  Saat): Galopp als Schleife nach Nähe, Wecken, Durchbruch, Schnauben.
  Klangprobe 22 Klänge, 0 Fehler; die Kennwerte der 18 alten (Dauer,
  Samples, Pegel, Spitze, RMS) zeilengleich zu HEAD.
- **Respawn (mittel):** Der Keiler wartet bis 1 s, bis die Figur sich regt
  (`RESPAWN_WARTEN`). Fälle „Reaktion 1,0 s“ an allen fünf Rastplätzen
  überleben (Mindestabstand 11,6 m), „Stehen nach dem Respawn“ wird
  gefangen (Gegenprobe).
- **Zielportal (mittel):** Es ist verborgen, bis die Figur das Ufer hinter
  dem Wehr erreicht (`ENTKOMMEN_S` 289,6), und wächst dann auf.
- **D3 → D4 (mittel):** D4 auf 223,2, L5 auf 229,7–232,7. Kettenprobe D3 ×
  D4 im Raster (40 Fälle): alle überleben, Mindestabstand 11,74 m.
  Sprungprobe L5 Fenster 1,75 m.
- **Leicht:** Meldung „Entkommen!“ erst über dem Ufer; Fruchtbögen 0,8–1,0 m
  neben der Wegmitte; G2-Kisten aus der Bahn (eine am Weg, drei auf der
  Bank); Jagdprobe: Rastplatzfälle mit den Aktionen ab dem Rastplatz,
  „warten“ mit `sofort`.

**Bild**
- **Figur hinter D1/D2-Bogen und Jochkäfig (schwer):** wie oben (K5,
  Nahblende); Fotos bei 43, 90, 196, 220 zeigen die Figur frei.
- **Zielportal im Vordergrund (schwer):** verborgen bis zum Ufer (oben).
- **Hauereiche (schwer):** Fuß r 2,15, Hälften r 1,5 statt 1,1, krummer,
  mit Rippen, Pilzen, Efeu, dunklem Spaltholz; Laub herbstgolden mit
  Durchlicht. Saaten der Hälften neu gesucht (5550/6574), Neigung neu
  gerechnet (Kerbe 9,0 m). Wahrzeichenprobe 91,8 % (wie vorher), Kerbe im
  Schlussbild 17,7 px (vorher 18,2; Grenze 16).
- **Parkartig, zu hell (mittel):** Sonne 17° statt 26°, wärmer, 1,5;
  Belichtung 0,9 statt 1,15; Kantenlicht 0,3 statt 0,18 (hellt die
  Schattenseite); Nebel 12 → 210 m, Dichte 0,9; Gebüsch an den
  Wandkronen dünner (`BUSCH_SAUM`). Helligkeit siehe Tabelle unten.
- **Wände (mittel):** Oberkante mit Zacken (±0,3 m, `KRONE_ZACKE`), Narbe
  wechselnd; Erde in gröberem Maß, weniger Relief; Moos- und Farnstreifen
  in der Südwand.
- **Lücken als schwarze Kästen (mittel):** Verdeckung der Stirn nach der
  Tiefe (`STIRN_VERDECKUNG`, oben 0,7, ab 2,4 m 0,05). L5 bei s 218
  (Fläche der Lücke, Luma 0–255): Mittel 9 → 28, 90. Perzentil 1 → 72.
- **Klobige Findlinge (mittel):** Ecken 7 statt 4 cm, Oberkante bis 30
  statt 22 cm gerundet (Abstand zum Körper höchstens 2–3 cm).
- **Startbild (mittel):** Keiler schläft quer (Schnauze, Ohren, Hauer im
  Umriss), Kamm und Hauer heller bzw. größer; Suhle rau (0,42) und
  heller getönt statt Asphaltglanz; Gatter mit 14 statt 20 Stangen.
- **Vordergrund (mittel):** Nahblende (oben). „Totholzast“ bei s 30 ist H1
  und kündigt die Hürde an – kein Mangel.

**Messungen nach R1** (Desktop, gleiche Fotostellen wie die Jury):

| | vorher (Bild-Jury R1) | nach R1 |
|---|---|---|
| Desktop 8/30/60/90/140/196/218/250/280/296: Helligkeit | 61–86 | 50–70 (Level 01 laut Jury 45–64) |
| warm / kühl (Ziel ≤ 55 % / ≥ 12 %) | 21–42 % / 17–25 % | 23–41 % / 18–24 % |
| Draw-Calls / Primitive / VRAM | 177–305 / ≤ 704k / 101,0 MB | 182–302 / ≤ 705k / 100,0 MB |
| Handy 8/60/90/140/218/250/280/296: Draw-Calls / Primitive / VRAM | 243–324 / ≤ 635k / 76,7 MB | 243–320 / ≤ 621k / 75,9 MB |
| Seite 40/150/240/286: Helligkeit | 54–67 | 41–50 |
| Wahrzeichenprobe / Kerbe s 296 | 91,8 % / 18,2 px | 91,8 % / 17,7 px |
| LevelCheck / Sprungprobe / Jagdprobe | 0/0 (ohne K5), 21 Fälle, 13 Fälle | 0/0 samt K5, 21 Fälle 0 Fehler, 19 Fälle 0 Fehler (neu: Reaktion 1,0 s an fünf Rastplätzen, Stehen nach dem Respawn) |

- **Bauzeit** (Level 05 allein, frischer Benutzerordner, je drei Läufe
  abwechselnd gegen HEAD auf derselben Maschine): kalt 14,3–15,7 s (HEAD
  15,8–16,7 s), größter Schritt 419–655 ms (HEAD 534–576 ms), Runde 2
  0,38–0,50 s (HEAD 0,37–0,43 s); in beiden Ständen 58 Bilder bis zum
  Ende des Aufbaus.
- **Werkstatt:** LevelCheck 0 Fehler, 0 Warnungen; Sprungprobe 22 Fälle
  0 Fehler, zeilengleich zu HEAD.
- **Wächter:** `parse.sh` SAUBER (208 Skripte); `pruefe.sh` SAUBER; `wache`
  6 von 6 Bildern pixelgleich, Kosten +0; Protokolle von Level 01
  (LevelCheck, Sprungprobe, Bauzeit) nach der Normalisierung gleich.

Ungeprüft: ein Lauf von Hand, der Klang auf einem Gerät, die Bilder auf
einer echten GPU (alle Bilder llvmpipe).

### R2 Mängel der Spiel- und der Bild-Jury

Wie in R1 steht jeder Punkt im Kopf des geänderten Moduls; hier die
Übersicht mit den Messungen. Gemessen mit der Jagdprobe, der Sprungprobe,
dem LevelCheck und der Juryprobe der Spiel-Jury (Jagdprobe mit Zusatzfällen,
Scratch), 60 Hz, frischer Benutzerordner je Lauf.

**Spiel**
- **Kisten-Edelstein unmöglich (schwer):** Die Gasse am Sonnensims liegt
  hinter dem Simsende (263,6/264,8/266,0 statt 260,0–262,4), die
  LEBEN-Kiste als Lohn auf dem Sims (262,1, Mangel 6), dafür eine
  NORMAL-Kiste hinter dem Wehr (291,5). Sammellauf „Alles einsammeln“ ohne
  Tod (G1 per Doppelsprung, A samt Graben, alle Gassen mit Drehschlag, die
  Kiste 80,4 und G2 per Doppelsprung mit Bauchplatscher, G3 über den
  Trittstein, vom Simsende Sprung mit Platscher auf die Gasse, Drehschlag):
  49/49, Band „Alle Kisten!“, Abschluss `kisten: true` – in drei Varianten
  des Platschers an G2 (83,6/84,0/84,4). Vorher 45/49.
- **Richtzeit als Klippe (mittel):** `ZIELZEIT` 37 s statt 15 s – Saphir für
  den sauberen Lauf ohne Kisten, Gold 31,45 s, Platin 26,64 s (Vorschlag
  der Jury; dem Nutzer vorzulegen). Die Zeitkisten stehen alle auf der
  Hauptlinie (Liste in Zählreihenfolge, `KISTEN`), je Gasse eine, in der
  ersten Gasse von B zwei, die letzte bei 272,2 vor dem Wehr; 15 Stück,
  30 s. Gemessen (Juryprobe mit Zeitmodus): Ideallinie ohne Kisten
  35,28 s → Saphir; jede zweite Kistenreihe 19,57 s → Platin; alle Reihen
  7,58 s; am Ziel Frost 0,00 (vorher verfielen dort 2,0 s, in einem
  Zwischenstand mit zwei Zeitkisten in der Simsgasse 1,45 s).
- **Keiler nie nah (mittel):** `L05Jagd` holt mit höchstens 10,5 m/s auf
  (`AUFHOL_TEMPO`) statt mit jedem Tempo der Figur mitgezogen zu werden,
  und die Staffel folgt der Strecke: Wecken 15, B 9,5, C 8 (Nacken), D 14
  (fällt zurück), E 7,5 m. Jagdprobe 23 Fälle, 0 Fehler: Ideallauf
  Mindestabstand 7,35 m (am Wehr; vorher 10,44), in C 7,7–7,8 m nach
  dem Sprung über L2; neu „Ein Fehler“ an H1/D1/H2/D2: 6,08 / 3,91 / 3,37
  / 3,95 m; Stolpern an D3 und D4 4,46 m (vorher 3,74); Gegenprobe
  gefangen. Kettenprobe der Jury (D3 × D4, 28 Fälle): alle überleben,
  11,93 m (vorher 11,74). Ein Slide gibt jetzt auch im Nacken Vorsprung
  (13,5 gegen 10,5 m/s). Nach dem Respawn steht er überall 12 m zurück und
  holt die Staffel auf; „Reaktion 1,0 s“ hält an allen Rastplätzen
  ≥ 7,1 m (`JAGD_REAKTION_MIN` 6,5 statt 8: im Nacken steht er ohnehin so
  nah).
- **Ziel neben dem Portal (leicht):** Der Auslöser des Zielportals ist in
  Level 05 ein Kasten über die ganze Breite (`_ziel_ausloeser_verbreitern`,
  nur die Form des Knotens). Juryprobe „Ziel“ auf q 1,6 und 2,0: geschafft
  (vorher nach 90 s nicht).
- **Doppeltes Stolpern (leicht):** Stolpersperre 0,6 s nach dem Stolpern,
  solange die Figur waagerecht innerhalb 1,5 m bleibt (Überschreibung des
  Handlers in `level05.gd`, die geteilte Datei bleibt). Hürde 0,6 m zu spät
  gesprungen: H1 1× gestolpert, 8,65 m (vorher 2×, 6,70 m), H2 1×, 5,96 m
  (vorher 2×, 7,04). Sprungprobe der Hürden zeilengleich zu vorher.
- **LEBEN-Kiste ohne Wert (leicht):** auf dem Sims (siehe oben).

**Bild**
- **Lücken als Stufe (schwer):** Die ferne Stirn ist nur an der Lippe hell
  (bis 0,1 m 0,62), ab 0,4 m Tiefe dunkel (0,025; `L05Saum`, STIRN_*); an
  der Landeseite hängt die Grasnarbe 0,28 m weiter über den Spalt. Im
  Wehrbruch steht eine Walze aus Weißwasser bis gut einen halben Meter
  unter die Lippe (`L05Wasser`, WEHR_WALZE). Luma 0–255 im Streifen
  zwischen ferner und naher Lippe (q −2 … 2, aus der Kamera projiziert,
  Früchte ausgenommen; Gegenmessung an den Bildern der Jury):

  | Stelle | Jury R2 (eigene Messung) | jetzt |
  |---|---|---|
  | L1, s 72 | 81,5 | 29,4 (Median 0) |
  | L5, s 226 | 63,2 | 14,2 (Median 0) |
  | L6, s 280 | 78,7 | 66,0 – Weißwasser |
  | L6, s 284 | 69,3 | 62,3 – Weißwasser |

  Am Wehr ist der Streifen hell, weil dort die Walze steht – die Jury
  verlangt beides (Luma ≤ 30 und Weißwasser bis unter die Lippe); die
  Stirn darüber ist dunkel.

---

## 14. Abweichungen vom Entwurf

Jede Abweichung ist im Kopf des jeweiligen Moduls begründet. Hier stehen
sie gesammelt, mit der Messung, die sie erzwungen hat.

| Stelle | Entwurf | gebaut | Grund (gemessen) |
|---|---|---|---|
| Kurve | aus zwölf Stützpunkten | alle 3 m ein Punkt | aus zwölf Punkten lag die Höhe bis 0,24 m neben KURVENHOEHE, die Kamera nur 3,41 m über der Figur, die Kurve endete bei 330 statt 332 |
| Rampen 62–71, 200–210 | zwei überlappende | je eine | das Rechenmodell ließ eine Stufe von 0,21 m |
| Leitlinien | 5 m | 5,7 m; an G1–G3 7 m | sie messen über der Kurve, der Boden liegt bis 0,64 m darüber; ein Doppelsprung von der Bank bringt die Füße auf 5,4 bzw. 6,0 m |
| G2 | 1,4 m breit | 2,0 m, Kisten zu zweit hinten | mit vier Kisten in einer Reihe prallte jeder Slide-Sprung ab |
| G3 | Trittstein 252 | 5 m später (257) | er lag 0,5 m hinter F2 auf derselben Querlage, ohne Anlauf |
| Zielportal | mit Lichtsäule | ohne | die Freiraumprobe K1 fand die Säule in der Kamerabahn |
| Figur | Szene setzt sie später | schon am Start in Level05.tscn | am alten Ort lag sie in der Todeszone (Leben 5 → 4 beim Laden) |
| Wecken | über die Zone des Rastplatzes | nach der Strecke der Figur | die Zone ist 2 m tief, ihr Eintritt läge 1,4 m früher (Abstand nicht mehr 15 m); nach der Strecke weckt ihn auch, wer die Zone mit einem Doppelsprung überspringt |
| Eiche | Achse s −6, Kerbe 7 m, Kronen Y ≈ 55 | s −9,5, Kerbe 9 m, Kronen Y 54,9/55,1 an Ästen; seit R1 Hälften r 1,5, Laub golden | Fuß und Brettwurzeln reichten über die Querwand; 7 m sind im Schlussbild nur 13,4 px; Kronen um eine feste Mitte lasen sich als Schirmpinien; mit r 1,1 standen die Hälften als Stangen im Bild (Bild-Jury R1) |
| Mühlrad | q −7 | q −8,5, in Fließrichtung gedreht | Schaufeln ohne Wasser darüber (33 Punkte, jetzt 0) |
| Baumtore | Kronen über dem Weg | Kronen seitlich | Wahrzeichenprobe 81,5 % statt 91,8 % |
| Schatten | zwei Stufen | orthogonal | mit zwei Stufen 755k–785k Primitive (Grenze 750k) |
| Licht | Startwerte §8.3 | Sonne 17° hoch, 1,5, Himmelslicht 0,45, Kantenlicht 0,3, Umgebung × 0,62, Belichtung 0,9, Nebel 12 → 210 m (bis R1: Sonne 26°, 1,25, Kantenlicht 0,18, Belichtung 1,15, Nebel 16 → 240 m) | mit den Startwerten Helligkeit 51–74 und kühl nur 3,6–9,8 %; mit den Werten bis R1 parkartig hell gegen Level 01 (Bild-Jury R1) |
| Richtzeit | vorläufig 46 s | 37 s (R1: 15 s, davor 48 s) | Saphir für den sauberen Lauf ohne Kisten (35,28 s), Gold und Platin über die Zeitkisten der Hauptlinie; mit 15 s holte ohne Kistenjagd niemand eine Stufe, mit 48 s jeder Kistensammler Platin (Spiel-Jury R1/R2 – dem Nutzer vorzulegen) |
| Keiler | Tempo 7,4, Höchstabstand 15 | Tempo 7,4, Staffel nach der Strecke (15/9,5/8/14/7,5), aufholen mit höchstens 10,5 m/s | mit 15 m bzw. der Klemme je Abschnitt hing er im sauberen Lauf immer am Höchstabstand, ein Slide gab keinen Vorsprung (Spiel-Jury R1/R2 – dem Nutzer vorzulegen) |
| Kette D3–D4–L5 | D4 222,0, L5 228,5 | D4 223,2, L5 229,7 | aus D3 kam man im zweiten Slide an D4 an, und hinter D4 fehlte Anlauf (Spiel-Jury R1) |
| Lücken-Stirn | dunkle Flanke (Albedo ≤ 0,1) | helle Lippe bis 0,1 m, ab 0,4 m dunkel (R1: hell bis 2,4 m) | ganz dunkel standen die Lücken als schwarze Kästen im Bild (Bild-Jury R1), hell bis 2,4 m als Stufen (Bild-Jury R2) |
| Kisten | Gasse 260,0–262,4, LEBEN 291,5 | Gasse 263,6–266,0, LEBEN auf G3 | Gasse und Sims lagen nebeneinander zwischen denselben Rastplätzen, 49/49 ging nicht; hinter dem Wehr war die LEBEN-Kiste ohne Wert (Spiel-Jury R2) |
| Werkstatt (P9) | Stationen ab 33 | 34–38, Station 33 frei | Baukasten §4 Nr. 12: Station 33 gehört dem Kameraplan |

---

## 15. Offen und ungeprüft (Stand R1)

**Dem Nutzer vorzulegen**
- **Richtzeit (R1):** 15 s nach Variante a der Spiel-Jury (Referenz mit
  den Zeitkisten der Hauptlinie, siehe `level05.gd`, ZIELZEIT). Ohne
  Zeitkisten ist im Zeitmodus keine Stufe zu holen. Die Alternativen der
  Jury (Zeitkisten aus der Hauptlinie nehmen oder die Richtzeit ohne
  Kisten rechnen) sind nicht gebaut.
- **Höchstabstand je Abschnitt (R1):** 15 → 14 → 13 → 12 → 11 m – Werte der
  Spiel-Jury, gebaut; ob die Steigerung reicht, zeigt nur ein Lauf von Hand.
- **Nebel der Eiche:** „für die Kuppe 0,7“. Heute trägt nur der Fuß der
  Fernform 0,7.
- **Bildfragen:** die Torbuchen (zwei runde Kronen, kein Bogen). Der
  Hohlweg in A und B bleibt offen: Ihn räumt der Sichtkegel K3 zur Eiche.
  Die Bänke und der Trittstein von G1–G3 sind kantig geblieben (ihre
  Oberseiten tragen Kisten bzw. die Landung, R1 nicht geändert).
- **Spielfigur:** die Datei `cash_banooka_rc.glb` (Risiko 2). Das klärt der
  Nutzer gesondert.

**Ungeprüft**
- Ein echter Lauf von Hand. Ein echtes Gerät, eine echte GPU, der
  Web-Export ohne Threads. Den Klang der Mühle hat niemand gehört.
- Die Ladezeit auf dem Spielweg aus dem Portalraum mit echtem Vorladen (die
  Probe lud die Szene synchron).
- Der Wechsel der Eiche von nah zu fern ist nicht unsichtbar: Der
  gesprenkelte Saum der Blattkarten verschwindet beim Wechsel.
- Woher die ObjectDB-Lecks am Ende der Proben kommen (Sprungprobe 7,
  Jagdprobe 9–13).
- Die Ruckelprobe zeigt bei Bild 308/309 (Wendung bei s ≈ 3) wiederkehrend
  100–110 ms CPU, mal im ersten, mal im zweiten Durchgang.
- Rundgang 610/612: Das Fernstück „Saum 9 fern“ gehört weggelassen oder
  ausdrücklich ausgenommen.

**Spieltest-Bot**
- Er meldet nach Level 05 „Kisten 0/0“: Er liest den Zähler erst zurück im
  Portalraum, wo `GameState` ihn zurückgesetzt hat (Spiel-Jury R1, leicht).
  Das Werkzeug ist geteilt – eine Korrektur änderte die Ausgabe aller
  Level; nicht geändert.
- Er springt an Hürden zu spät, rund 1,1 m vor der Stirn.
- Seine Slide-Angriffe in `_kampf` drücken Shift ohne Seite und lösen
  deshalb nie einen Slide aus. Das bleibt bewusst so, sonst liefe der Bot in
  anderen Leveln anders.
- Unter xvfb zeigen seine Bilder nur Grau und das HUD.

**Beobachtet, nicht geändert**
- Am Rand der Teichmulde steht im Gelände eine Kante von etwa 4 m.
- An der Naht von Platte und Feld ist eine feine helle Linie zu sehen.
- Die Füße der Ab-Wände bei 279 und 299 stehen bis +0,28 m hoch, vom Weg
  abgewandt.

**Werkstatt (P9)**
- Die Werkstatt-Kamera folgt von hinten und nicht im Rückblick wie in
  Level 05. Sie fährt deshalb durch die Kappen der Durchlässe (Bilder bei
  984 und 997).
- Der Hügelring der Werkstatt (`horizont`, Radius aus `ende()`) stand vorher
  hinter Station 32 etwa 115 m vor dem Weg. Jetzt steht er hinter
  Station 38, etwa 139 m davor. Dort schneidet ihn die Sichtweite der Kamera
  (200 m) wie vorher am alten Ende. Vor Station 33 steht er jetzt mindestens
  217 m entfernt.
- Im Wehrbruch und im Jochgraben liegt der Höhennebel der Werkstatt
  (`fog_height` 0,2) als heller Dunst.

**Weiter offen aus G6:** Kameraplan, `_kamera_modell`, Kameraplanprobe und
Station 33; der ABGLEICH-Absatz im Kopf von `level_check.gd`.
