# Level-Steckbriefe: Vorbilder für Raum 3, 4 und 5

> Dieselbe Fassung als lesbare Seite mit echten Farbfeldern:
> <https://claude.ai/code/artifact/92ce93b6-7345-4c5b-94f5-75f50de20c59>
> (Quelle dafür: `doku/level-vorbilder.html`. Beide Fassungen bei Änderungen
> nachziehen – diese Textdatei ist der Arbeitsstand.)

Fünfzehn Level aus drei klassischen Korridor-Plattformern, auseinandergenommen
nach dem, was wir davon brauchen: **Ansicht, Mechanik, Leveldesign, Design**.

**Wozu das dient.** Nicht zum Nachbauen von Inhalten, sondern zum Herausziehen
von Werkzeugen. Ein Level ist für uns interessant, wenn es *eine Frage stellt,
die unsere bisherigen Level nicht stellen*. Aus jeder solchen Frage wird ein
Bauteil, das in jedem unserer Level einsetzbar ist.

**Was NICHT übernommen wird** (siehe CLAUDE.md): keine Namen, keine Figuren,
keine Assets, keine Texturen, keine Musik. Die Arbeitstitel unten sind unsere
eigenen. Es liegen auch keine fremden Bildschirmfotos im Projekt – was hier
steht, sind gemessene Zahlen und eigene Beschreibungen.

---

## Zweite Fassung – was sich geändert hat und warum

Die erste Fassung dieses Dokuments hat die Vorbilder aus der Erinnerung und
aus je *einem* Referenzbild beschrieben. Ein Nachscan über 76 Bildschirmfotos
aller fünfzehn Level hat drei Fehler gezeigt, die sich bereits in die gebauten
Level 11 bis 25 fortgesetzt haben.

**Fehler 1: Die Ansichtsart fehlte ganz.** Die erste Fassung beschrieb alle
fünfzehn als 3D-Korridor. Tatsächlich sind **vier durchgehend 2,5D-Seiten-
ansicht** (3-2, 3-3, 3-5, 4-5), eines wechselt **mitten im Level** zwischen 3D
und 2,5D (5-4), eines ist freier Flug (5-2). Ein Drittel der Vorlagen ist also
gar kein Korridor. Jedes Level hat jetzt eine Zeile **Ansicht**.

**Fehler 2: Die Farbmessung maß das Falsche.** Eine Farbreduktion auf sechs
Töne liefert *flächengewichtete* Farben. Sie gibt zwangsläufig Himmel, Boden
und Wand zurück und wirft die kleinen, gesättigten Akzente weg, die die
Aussage tragen. Die erste Fassung hat das zweimal selbst bemerkt („zu
kleinflächig für die Messung") und nichts daraus gefolgert.

Belegfall: Bei 5-5 verschluckt die Sechs-Ton-Reduktion den kräftig blauen
Himmel restlos – alle sechs Töne kommen warm heraus, obwohl 14,1 % der Fläche
kühl sind. Genau dieser Ausfall steckt heute in Level 25: 0,2 % kühl.

Die Paletten stehen deshalb neu als **zwei Trägerfarben mit Flächenanteil**
plus **Signalfarben unter 6 % Fläche**, dazu der **Warm-kühl-Anteil** als
nachprüfbare Zahl. Gemessen wird über *alle* Bilder eines Levels, nicht über
eines.

**Fehler 3: Aus zwei Bildern wurde eines.** Bei 3-5 nannte die erste Fassung
einen Komplementärkontrast aus türkisgrünem Stein und orangefarbenem Himmel.
Beide Farben gibt es – aber **nie im selben Bild**. Das Level läuft durch drei
Paletten nacheinander. Unser Level 15 hat den vermeintlichen Kontrast
gleichmäßig über 360 m verrührt und kommt auf 0,0 % kühl.

**Quelle der Zahlen.** Gemessen an Bildschirmfotos der Neuauflage, nicht der
PS1-Fassung. Aufbau, Ansicht und Mechanik sind dieselben, die Farben sind
heller und satter. Für uns ist das der brauchbarere Bezug – die erste Fassung
merkte selbst an, die PS1-Bilder seien „durchweg dunkler, als sie in
Erinnerung sind".

---

## Die fünf Verträge

Das Wichtigste an den Vorbildern steht nicht in den einzelnen Leveln, sondern
unter ihnen. Fünf Regeln gelten über alle drei Spiele hinweg – und weil sie
über allem gelten, kann man dort jedes Level auf den ersten Blick lesen.

### 1. Der Ansichtsvertrag

Die Kamera ist kein Standpunkt, sondern ein **Ventil für Information**. Es
gibt drei Betriebsarten, und sie gelten für einen ganzen Abschnitt oder ein
ganzes Level – nicht als Ausnahme in einem 3D-Level:

| Ansicht | Was sie leistet |
|---|---|
| **3D-Verfolger** | Tiefe ist lesbar, Seitwärtsbewegung ist frei. Die Vorwarnzeit hängt daran, wie weit der Gang einsehbar ist. |
| **2,5D-Seitenansicht** | Sprungweite und Höhe sind exakt ablesbar, Tiefe fällt weg. Damit werden dichte Sprungfolgen erst fair. |
| **Frontansicht** | Die Figur läuft auf die Kamera zu. Man sieht nicht, was hinter einem herkommt – die Sicht selbst ist die Aufgabe. |

Bei uns kennt `corridor_camera.gd` nur Verfolger und Seitenansicht, und die
Seitenansicht nur als `kamerazone()` innerhalb eines 3D-Levels. Die
Frontansicht fehlt ganz.

### 2. Der Kistenvertrag

Die Signalfarben sind **global**, nicht levelweise. Dieselbe Farbe bedeutet in
allen drei Spielen und in allen fünfzehn Leveln dasselbe:

| Aussehen | Bedeutung |
|---|---|
| grelles Grün, Aufdruck | tödlich bei jeder Berührung |
| Rot mit gelber Schrift | Zünder, kurzer Countdown |
| Orange mit gelbem Zeichen | Umrisskiste – erscheint erst, wenn ihr Auslöser fällt |
| weißer Umriss, körperlos | noch nicht vorhanden, wartet auf den Auslöser |
| türkisgrün leuchtend | Rettungspunkt oder Ausgang |

Deshalb muss ein Level seine Gefahren nicht selbst erklären. Die erste Fassung
hat daraus eine levelspezifische Regel gemacht („die Signalfarbe kommt sonst
nirgends *im Level* vor") und daraus die magentafarbenen Deckungsflecken
abgeleitet. Die stärkere Regel ist die globale.

Zweitens: Kisten sind ein **Layout-Werkzeug**. Sie stehen dort, wo sie den
Spieler von der sicheren Linie wegholen – über einer Grube, hinter einer
Nitrokiste, nur mit Slide-Sprung erreichbar. Bei uns stehen sie in Reihen
entlang des Wegs; von rund 58 Kisten je Level sind null bis drei riskant
platziert.

### 3. Der Taktvertrag

In einem Abschnitt schlägt **alles auf derselben Uhr**, und die Uhr läuft in
ganzen Sekunden. Nur dadurch wird eine Passage lernbar: Man liest den Rhythmus
einmal und geht dann durch.

Unsere Taktgeber laufen jeder auf eigener Uhr:

| Bauteil | Zyklus | Quelle |
|---|---|---|
| `Taktflaeche` | 2,0 + 0,6 + 1,2 = **3,8 s** | fest im Bauteil, kein Parameter |
| `Feuerspeier` | 1,8 + 0,7 + 1,1 = **3,6 s** | fest im Bauteil, kein Parameter |
| `Laserzaun` | **2,4 s** | `takt` |
| `Stacheln` (einfahrbar) | **2,4 s** | `takt` |
| `Schliesstuer` | 2,2 + 1,6 + 2·0,5 = **4,8 s** | fest im Bauteil |

Taktfläche und Feuerspeier nebeneinander wiederholen ihr gemeinsames Muster
erst nach **68,4 Sekunden**. Das ist kein Takt, das ist Rauschen.

**Verbindlich für neue Bauteile:** Jeder Taktgeber bekommt einen `takt`-Wert
als Parameter, Vorgabe **2,0 s**; erlaubt sind nur ganzzahlige Vielfache und
Teiler davon (1,0 · 2,0 · 4,0). Der Versatz ist ein Bruchteil davon.


**Stand: umgesetzt.** `Taktflaeche` und `Feuerspeier` haben einen
`takt`-Wert bekommen (Vorgabe 4,0 s); die Ruhe ist der Rest, damit Warn- und
Gefahrzeit absolute Reaktionszeiten bleiben. `Laserzaun`, `Stacheln` und
`Werfer` stehen auf 2,0 s, `Schliesstuer` und `Bruchplatte` auf 4,0 s. Die
von Hand gesetzten Takte in Level 13, 16 und 21 sind aufs Raster gezogen.
Einzige Ausnahme, und sie ist als solche im Code vermerkt: das
plattengehaltene Tor in Level 20 – ein Schalter, kein Taktgeber.

### 4. Der Lesbarkeitsvertrag

Drei Beobachtungen, die in allen fünfzehn Vorbildern gelten:

- **Die größte einzelne Fläche ist ein dunkler Ton.** In elf von fünfzehn
  Leveln liegt der größte Farbanteil unter 20 % Helligkeit – Blattwerk,
  Schatten, Nachthimmel, Schachtdunkel. Das Dunkel ist der Rahmen.
- **Die begehbare Fläche ist das Hellste und am wenigsten Gesättigte im
  Bild.** Alles andere rahmt sie ein. Wo der Weg aufhört, hört die Helligkeit
  auf – man muss die Kante nicht suchen.
- **Dunst liegt HINTER dem Spielgeschehen, nicht darüber.** Bei 3-4 ist der
  Nebel fast weiß, aber die Brücke davor steht in voller Sättigung: warmes
  Seilbeige, Holzplanken, türkis bemalte Pfostenköpfe, knallgrüne Gegner.
  Zusätzlich rahmen dunkle Felszacken den unteren Bildrand. Unser Level 14
  hat den Nebel über allem – Kontrast 6,6 von 255, der niedrigste aller
  fünfzehn, bei einem Vorbild mit dem höchsten.

**Verbindlich:** Nebeldichte und Umgebungslicht dürfen die Nahzone bis rund
zwölf Meter nicht anfassen. Ein Level braucht mindestens eine dunkle
Rahmenfläche und eine helle Wegfläche.

### 5. Der Belohnungsvertrag

Ein Level hat drei Ebenen, nicht eine:

1. **Ankommen** – der Hauptweg.
2. **Alle Kisten** – ein Zähler, der ständig sichtbar ist. Bei uns gebaut
   (`GameState.kisten_gesamt`, `ohne_tod` für den zweiten Edelstein) – aber
   ohne Level, die ihn fordern.
3. **Der Bonusraum** – ein eigener kleiner Raum in eigener Gestaltung, betreten
   über gesammelte Marken, **ohne Todesstrafe**. Dort liegt in vielen
   Vorbildern der größere Teil der Kisten. Fehlt bei uns vollständig.

Dazu kommt in den späteren Vorbildern der **zweite Ausgang**: ein Weg, der
nicht ins Ziel führt, sondern woandershin – gedeckelt durch Können oder durch
einen Gegenstand aus einem anderen Level.

---

## Raum 3 – Vorbilder aus dem ersten Spiel

Gemeinsamer Nenner: **enge Korridore, harte Fallen, wenig Ausweichraum.** Der
Spieler hat dort nur Laufen, Springen und den Drehschlag. Alles, was schwer
ist, ist es durch *Timing*, nicht durch Bewegungsvielfalt. Diese fünf liefern
die Taktgeber.

Zu beachten: **drei der fünf sind ganz oder überwiegend Seitenansicht.** Raum 3
ist damit nicht der Korridorraum, für den wir ihn gehalten haben.

---

### 3-1 · Steinschlag
*Vorbild: „Rolling Stones" (Dschungel)*

**Ansicht.** 3D-Verfolger, aber mit deutlich **steilerer Aufsicht** als bei uns.
Der Bonusraum ist ein eigener, flach gehaltener Raum.

**Kernmechanik.** Rollende Steinkugeln laufen den Korridor entlang – teils
entgegen, teils von hinten. Sie sind nicht besiegbar und nicht überspringbar;
man weicht in Seitennischen aus oder läuft ihnen davon. Das dreht die
Grundfrage des Levels um: nicht „wohin springe ich", sondern „wann darf ich
überhaupt losgehen".

**Leveldesign.** *Korrigiert:* Der Weg ist **abgesenkt** – ein gemauerter Graben,
über dessen Rand der Dschungel auf beiden Seiten höher steht. Man läuft in
einer Rinne, nicht auf einem Pfad. Die steinernen Wegmarken sind **flach in die
Wand eingelassene geschnitzte Scheiben**, keine freistehenden Bögen über dem
Weg. Kaum Höhenunterschied über die Länge, Länge über Wiederholung mit
steigender Frequenz.

**Design.** *Korrigiert:* deutlich farbiger als in der ersten Fassung
angenommen. Der Nahbereich trägt kräftig gesättigte Tupfer – rosa Blüten,
rotviolette Hochblätter, breite hellgrüne Blätter, ein blaugrüner Gegner. Die
Trägerflächen sind das dunkle Blattwerk und die dunkle Grabenwand; der Weg
selbst ist heller, moosig überzogener Stein.

- Träger: `#1F170B` 22 % · `#09151B` 22 %
- Signal: `#841D0C` 1,7 % · `#8C4211` 2,5 % · `#925D1D` 3,2 %
- warm 56,5 % · kühl 21,4 % · Helligkeit 50

**Gegner.** Querläufer über den Weg, gepanzerte Kriecher, stationäre Schnapper
im Takt.

**Was es schwer macht.** Zwei Takte gleichzeitig: der Fels und der quer laufende
Gegner. Wer nur auf einen achtet, wird vom anderen erwischt.

**Erkennungsmerkmal.** Der Blick über die Schulter auf eine Kugel, die den
ganzen Gang ausfüllt – in der Vorlage über die **Frontansicht** gelöst, nicht
über eine Seitenansicht.

**Werkzeuge.** *Neu:* `Rollhindernis`, `Nische`, **`Frontansicht`**,
`Wandscheibe` (Wegmarke, die nicht über dem Weg steht und deshalb die Kamera
nicht verdeckt). *Vorhanden:* Gegner mit Querpatrouille.

**Abgleich mit Level 11.** Kühl 8,1 % statt 21,4 %, Helligkeit 97 statt 50 – zu
hell und zu farbarm. Die 40 rosa Blüten ergeben 0 von 5,3 Mio. Pixeln. Die
Torbögen stehen über dem Weg und verschlucken bei 330 m die Kamera.

---

### 3-2 · Kesselwerk
*Vorbild: „Castle Machinery" (Burgmaschinerie)*

**Ansicht.** **Durchgehend 2,5D-Seitenansicht.** Das ist kein Korridor.

**Kernmechanik.** Maschinen als Boden: Fließbänder, die tragen oder
zurückschieben, Aufzugsplattformen, Kolben und Zahnräder. Der Boden ist hier
zum ersten Mal kein Verlass.

**Leveldesign.** Innenraum über mehrere Ebenen, senkrecht gestaffelt. Der Weg
führt genauso oft nach oben wie nach vorn. Enge Gänge wechseln mit hohen
Hallen. Ein Geheimweg direkt am Start führt nach oben – dort liegen Extraleben
statt Kisten.

**Design.** *Korrigiert:* Das Level ist **warm**, nicht kalt. Blaugraues
Mauerwerk gibt es nur im ersten Abschnitt; danach tragen rostbrauner Stahl und
vor allem **glühend orange Rohrbündel** das Bild. Diese Rohre sind zugleich die
Lichtquelle – es gibt keine Sonne, alles Licht kommt aus der Maschine.
Punktbeleuchtung, harte Schatten, dazu grün leuchtende Kisten als Gegenakzent.

- Träger: `#2E1510` 27 % · `#16110F` 22 %
- Signal: `#A01B0A` 1,1 % · `#C24413` 2,0 % · `#AB5429` 2,0 %
- warm 69,0 % · kühl 10,9 % · Helligkeit 51

**Gegner.** Maschinenkriecher, Projektoren, die Hindernisse ein- und
ausblenden, fliegende Störer auf fester Bahn.

**Was es schwer macht.** Bewegte Böden über Abgründen. Ein verpasster Absprung
ist nicht korrigierbar, weil der Boden weiterfährt.

**Erkennungsmerkmal.** Das glühende Rohr, das quer durchs Bild läuft und den
ganzen Raum färbt.

**Werkzeuge.** *Neu:* `Fließband`, `Zahnrad`/`Walze`, `Feuerstoß`,
**`Seitenansicht als Betriebsart`**, `Glührohr` (Deko, die zugleich Licht ist).
*Vorhanden:* `Wasserplattform` deckt Aufzug und Kolben ab.

**Abgleich mit Level 12.** **Farblich umgedreht:** unser Level hat 14,4 % warm
und 71,3 % kühl, das Vorbild 69,0 % warm und 10,9 % kühl. Wir haben eine kalte
blaue Halle gebaut, wo eine glühende steht. Dazu stehen bei uns Totholzbäume,
Grasbüschel und eine Sumpfkröte in der Burgmaschinerie.

---

### 3-3 · Pfahlfeste
*Vorbild: „Native Fortress" (Eingeborenenfestung)*

**Ansicht.** **Durchgehend 2,5D-Seitenansicht.**

**Kernmechanik.** Senkrechter Aufstieg über schmale Holzstege und einzelne
Plattformen. Dazu Fallen, die aus dem Boden schießen, und Werfer, die von oben
stören.

**Leveldesign.** Klettern statt Laufen. Die Strecke ist kurz, die Höhe groß.
Fallen stehen dicht: Speersäule, Sprung, Fackel, Sprung. Kein Abschnitt ist
länger als zwei Hindernisse – dafür folgen sie ohne Pause. Das Level hat zwei
Hälften: erst ein dunkler Innenraum zwischen riesigen Stämmen, dann ein
Aufstieg im Freien.

**Design.** *Korrigiert:* **keine reine Holzpalette.** Die zweite Hälfte spielt
vor **blauem Himmel mit Wolken** und einer violetten Fernlandschaft; helle,
fast cremefarbene Palisadenspitzen kommen dazu. Zusammen sind das rund 29 % der
Fläche und 18,4 % ausgesprochen kühl.

Die Muster sind großflächige, kontraststarke Grafikbänder – Zickzack in Rot,
Schwarz und Creme, dazu breite türkisgrüne Ringe –, die etwa ein Drittel der
Säulenfläche einnehmen. Keine schmalen Zierstreifen. Die Formen darunter sind
schlichte Zylinder und Kästen; die Muster sind das ganze Design.

- Träger: `#603313` 28 % · `#2B1D0F` 25 %, dazu `#895223` 19 %
- Kühle Flächen: `#BBAEA5` 12 % · `#827674` 10 % · `#495059` 7 %
- warm 70,7 % · kühl 18,4 % · Helligkeit 80

**Gegner.** Kriecher, Schnapper, Werfer von Podesten, Stachelsäulen, Fackeln.

**Was es schwer macht.** Dichte. Und dass ein Fehler nicht nur Schaden ist,
sondern Höhe kostet.

**Erkennungsmerkmal.** Die gemusterte Säule vor blauem Himmel, zwischen
Palisadenspitzen.

**Werkzeuge.** *Neu:* `Werfer`, `Feuerdüse quer`, `Aufstiegsverlauf`,
**`Musterband`** (breites Grafikband als Materialschicht, nicht als Ring).
*Vorhanden:* `Stacheln` mit `einfahrbar` ist die Speersäule.

**Abgleich mit Level 13.** Kühl 0,1 % statt 18,4 % – unser `MUSTER_TUERKIS` ist
gesetzt, kommt aber nicht im Bild an, und der Himmel fehlt als Gegengewicht.
Dazu hängen Bäume und Steine ohne Boden in der Luft neben der Feste.

---

### 3-4 · Wolkensteg
*Vorbild: „The High Road" (Seilbrücke über den Wolken)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** Eine Brücke aus einzelnen Planken über dem Nichts, mit
Lücken, die genau an der Sprungweite liegen. Dazu Platten, die beim Betreten
wegbrechen, rutschige Platten, und Gegner, die man als Absprunghilfe benutzt.

**Leveldesign.** Das schmalste Level der Reihe – zwei Planken breit, kein Rand,
keine Deckung. Rein linear. Die Schwierigkeit steckt allein in der Abfolge von
Lücken; es gibt fast keine Gegner im üblichen Sinn.

**Design.** Der stärkste Kontrast der ganzen Reihe – aber **geschichtet**, nicht
flächig. Der Dunst ist fast weiß und liegt **hinter** dem Spielgeschehen. Die
Brücke davor steht in voller Sättigung: warmes Seilbeige, Holzplanken, türkis
und blau bemalte Pfostenköpfe, knallgrüngelbe Gegner, orangegrüne Früchte.
Dazu rahmen **dunkle Felszacken den unteren Bildrand** – ohne sie hätte das
Weiß nichts, wogegen es hell wäre.

- Träger: `#D1D2D6` 32 % · `#575B4A` 25 %
- Signal: `#734029` 2,6 % · `#7B5C40` 2,7 % · `#446E8C` 1,6 %
- warm 14,5 % · kühl 15,1 % · Helligkeit 167

**Gegner.** Fast nur Kriecher, und die sind hier Werkzeug statt Feind.

**Was es schwer macht.** Kein Fehler ist verzeihbar. Es gibt keinen Boden unter
dem Boden.

**Erkennungsmerkmal.** Die Seilbrücke, die im Weiß verschwindet – während das
Seil selbst warm und scharf bleibt.

**Werkzeuge.** *Neu:* `Bruchplatte`, `Trampolingegner`, `Seilsteg`,
**`Rahmenzacken`** (dunkle Silhouetten am unteren Bildrand als Kontrastanker).
*Vorhanden:* `Eisfläche`, `Gegner.abprall_hoehe`.

**Abgleich mit Level 14.** Der einzige Fall, in dem die erste Fassung die
Trägerfarben richtig gemessen hat – und trotzdem der größte Fehlschlag. Unser
Level: warm 0,1 %, kühl 0,0 %, Helligkeit 245, Kontrast 6,6. Das Vorbild hat
den höchsten Kontrast der Reihe, unser Level den niedrigsten. Ursache in
`Level14.tscn`: `fog_density 0.042` bei `fog_light_energy 1.3`,
`ambient_light_energy 1.45`, `tonemap_exposure 1.2`.

---

### 3-5 · Abendruinen
*Vorbild: „Sunset Vista" (Ruinen im Abendlicht)*

**Ansicht.** **Überwiegend 2,5D-Seitenansicht**, mit einzelnen 3D-Passagen.

**Kernmechanik.** Das Ausdauer-Level. Mehrere Stockwerke übereinander, mit
Fallen, die alle etwas anderes verlangen: Platten, die im Takt heiß werden;
Blöcke, die den Spieler seitlich von der Kante schieben; Flieger, die Bögen
ziehen.

**Leveldesign.** Der Weg staffelt sich mehrfach übereinander. Von unten sieht
man, wo man später oben entlangkommt – das ist die eigentliche Idee. Länge ist
bewusst ein Mittel: Konzentration über Minuten, nicht über Sekunden.

**Design.** *Grundlegend korrigiert:* **kein Komplementärkontrast, sondern drei
Paletten nacheinander.**

1. **Kühler Tempel im Sumpf** – blaugrüner Stein, dunkelgrünes Laub, graugrünes
   Wasser, warme Reliefs als Tupfer.
2. **Roter Sandstein unter magentafarbenem Abendhimmel** – der Himmel ist
   pink-magenta, nicht orange. Wände voller eingeschnittener Reliefs in einem
   dunkleren Rot als die Fläche: Struktur ohne zusätzliche Farbe.
3. **Helles Blätterdach unter blauem Himmel mit weißen Wolken.**

Die erste Fassung hat Palette 1 und Palette 2 zu einem gleichzeitigen Kontrast
verrechnet. Das ist der Fehler, der in Level 15 steckt.

- Träger: `#27271C` 29 % · `#962F20` 23 %
- Signal: `#BE2828` 2,4 % · `#B44428` 3,1 %
- warm 71,3 % · kühl 16,9 % · Helligkeit 73

**Gegner.** Flieger im Bogen, Echsen, Feuerplatten, Schiebeblöcke.

**Was es schwer macht.** Nicht eine einzelne Stelle, sondern die Summe. Wer
achtzig Prozent schafft, fängt trotzdem von vorn an.

**Erkennungsmerkmal.** Der Blick von der obersten Ebene zurück über die
Strecke, die man schon gelaufen ist.

**Werkzeuge.** *Neu:* `Schiebeblock`, `Taktfläche`, `Flugbahn-Gegner`,
`Stockwerksverlauf`, **`Palettenwechsel`** (Level durchläuft mehrere
Grundpaletten statt einer – gehört zu `stimmung()`, aber als Entwurfsmittel,
nicht als Wetter).

**Abgleich mit Level 15.** Kühl 0,0 % statt 16,9 %. `RUINENSTEIN` ist mit
`#34494A` richtig kühl gesetzt, aber die Sonne in `Level15.tscn` ist
`Color(1, 0.66, 0.33)` bei Energie 1,6 und der Nebel `(0.72, 0.44, 0.2)` – der
kühle Stein kommt nie kühl an.

---

## Raum 4 – Vorbilder aus dem zweiten Spiel

Gemeinsamer Nenner: **Der Spieler kann mehr, also darf das Level mehr
verlangen.** Slide, Bauchplatscher und Krabbeln existieren – und werden gezielt
erzwungen: Gegner, die nur per Slide fallen, Gänge, die nur geduckt passierbar
sind. Das ist genau unsere Lage nach dem Krabbeln-Umbau.

Neu gegenüber Raum 3: In vier von fünf Leveln ist ein **Bonusraum** im Bild
belegt, und die Kistenzähler laufen sichtbar mit.

---

### 4-1 · Kanalgrund
*Vorbild: „The Eel Deal" (Kanalisation)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** **Der Boden ist zeitweise tödlich.** In den Wasserrinnen
takten Stromstöße; man wartet, statt zu rennen. Dazu rollende Giftfässer, die
den Gang entlangkommen, und drehende Rotorblätter als bewegliche Wände.

**Leveldesign.** *Korrigiert:* Der Gang ist eine **runde Röhre**. Die Wände
krümmen sich nach oben in die Decke, es gibt keinen Himmel und keine offene
Kante – der Raum ist geschlossen. Das ist der Grund, warum das Level dunkel
sein darf, ohne unlesbar zu werden: Es gibt keine Ferne, in der sich etwas
verlieren könnte. Zwei Gabelungen; eine sieht wie eine Sackgasse voller Nitro
aus und ist der Geheimweg.

**Design.** *Korrigiert:* deutlich heller und farbiger als angenommen. Die
Röhre ist tealgrün, davor liegen messingfarbene Rohrbögen; an der Decke sitzen
**Lampen, die warme Lichtinseln werfen**. Auf halber Höhe läuft ein
**waagerechtes ockerfarbenes Leitband** die ganze Röhre entlang – dieselbe
Aufgabe wie unsere gelben Seilzüge in Level 12. Dazu gelb-schwarze
Warnschraffuren an den Kanten und einzelne violett ausgeleuchtete Abschnitte.

- Träger: `#091712` 25 % · `#313B27` 20 %
- Signal: `#236251` 4,2 % · `#6E1E0A` 2,5 % · `#6E3D18` 3,7 %
- warm 34,3 % · kühl 41,0 % · Helligkeit 45

**Gegner.** Nager, Stromgeber im Wasser, Putzroboter auf fester Bahn, Fässer.

**Was es schwer macht.** Warten. Das Level bestraft das Tempo, das alle anderen
Level belohnen.

**Erkennungsmerkmal.** Die runde Röhre, die sich vor einem schließt, mit der
Lampenreihe an der Decke.

**Werkzeuge.** *Neu:* `Taktfläche` waagerecht, `Rollfass`, `Rotorblatt`,
`Verfolger` (Gegner auf fester Bahn, der Tempo macht), **`Röhrengang`**
(Korridor mit geschlossener Decke und gekrümmten Wänden), **`Deckenlampe`**
(Lichtinsel als Wegmarke), **`Leitband`** (waagerechter Streifen als
Höhenreferenz). *Vorhanden:* `Wasser` mit `toedlich`.

**Abgleich mit Level 16.** Helligkeit **2,5 statt 45** – achtzehnmal dunkler als
das Vorbild. Ursache: Ambient 0,55, Sonne 0,65, dunkelgrüner Nebel 0,038 und
**null Punktlichter im ganzen Level**. Unser Gang ist außerdem oben offen, wo
das Vorbild eine geschlossene Röhre hat.

---

### 4-2 · Frostritt
*Vorbild: „Bear It" (Ritt auf dem Eisbären)*

**Ansicht.** 3D-Verfolger, tief und nah – die Sichtweite nach vorn ist bewusst
kurz.

**Kernmechanik.** Reittier. Vorwärts läuft es von allein, gelenkt wird nur quer.
Dazu ein **Turbo, der Tempo gegen Kontrolle tauscht** – das ist der eigentliche
Reiz. *Neu belegt:* Der Turbo ist im Bild **farblich gekennzeichnet**, durch eine
violette Bewegungsspur am Reittier. Tempo ist dort nicht nur ein Zahlenwert,
sondern ein sichtbarer Zustand.

**Leveldesign.** Schienenlevel. Eine enge Schneerinne, Hindernisse auf drei
gedachten Spuren, Nitrokisten dazwischen. Kein Erkunden, reine Reaktion.

**Design.** Strahlend weißer Schnee, blaugraue Eiswände, türkisblaue
Eisformationen, dunkelblauer Himmel. *Korrigiert:* Der Gefahrenzeiger ist nicht
warmes Holz, sondern die **grelle Nitro-Kiste** – grün auf blauem Eis, und
damit die einzige Farbe im Level, die dort sonst nicht vorkommt. Die
geschnitzten Pfähle sind Wegmarken, keine Warnungen.

- Träger: `#063257` 21 % · `#4A81A7` 19 %
- Signal: `#065696` 4,1 %
- warm 1,2 % · kühl 94,4 % · Helligkeit 107

**Gegner.** Tiere, die quer über die Bahn springen, Pfähle, Nitro.

**Was es schwer macht.** Sichtweite. Hindernisse erscheinen spät.

**Erkennungsmerkmal.** Der Blick von hinten auf Reiter und Tier in der weißen
Rinne – mit violetter Spur, wenn der Turbo läuft.

**Werkzeuge.** *Vorhanden:* `Reiter` (Level 04). *Neu:* `Spurhindernisse`,
**`Turbo mit Kontrollverlust`** samt eigener Einfärbung.

**Abgleich mit Level 17.** Palette trifft (kühl 98,9 % gegen 94,4 %) – eines der
zwei am besten getroffenen Level. **Der Turbo fehlt jedoch ganz.** Und unsere
Totems sind mit `#965127` warm gesetzt, kommen im Bild aber auf 0,2 % und lesen
sich schiefergrau; als Gefahrenzeichen taugen sie so nicht.

---

### 4-3 · Schwarmpfad
*Vorbild: „Bee-Having" (Dschungel mit Schwärmen)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** **Verfolgende Schwärme.** Ein Schwarm ist kein einzelner
Gegner, sondern eine Gruppe, die als Ganzes kommt – und mit einem einzigen gut
gesetzten Schlag als Ganzes fällt. Dazu Bodenflecken, in die man sich kurz
eingräbt und unangreifbar ist.

**Leveldesign.** Dschungelpfad, auf dem Schwärme in Wellen kommen. Die
Deckungsflecken liegen rhythmisch – das Level ist ein Wechsel aus Rennen und
Ducken. Zusätzlich versperren **Wände aus Nitrokisten** quer den Weg.

**Design.** Rotbrauner Weg mit hellem Sandstreifen in der Mitte, große Stämme
als Torbögen, sattes Grün, rote Pilze mit weißen Punkten, türkis bemalte
Zeichen an den Felswänden, weiße Schneeflecken am Rand. *Wichtig:* Die
auffälligsten Farben im Bild sind die **Kisten** – grelles Nitro-Grün und
orange Umrisskisten. Die Signalwirkung kommt aus dem globalen Kistenvertrag,
nicht aus einer levelspezifischen Erfindung.

- Träger: `#292413` 22 % · `#722C10` 20 %
- Signal: `#9F310E` 2,9 % · `#833412` 4,4 %
- Von Hand ergänzt: `#C0357A` (Magenta der Deckungsflecken) – stand so in der
  ersten Fassung, im Nachscan über 5 Bilder aber nicht angetroffen; ohne Flächenwert.
- warm 75,9 % · kühl 8,1 % · Helligkeit 77

**Gegner.** Schwärme, grabende Gegner.

**Was es schwer macht.** Man darf nicht stehenbleiben, muss aber genau zielen.

**Erkennungsmerkmal.** Die Wand aus grünen Nitrokisten quer über dem roten Weg.

**Werkzeuge.** *Neu:* `Schwarm`, `Deckungsfleck`, **`Nitrowand`** (Reihe
Nitrokisten als Sperre, die nur der Auslöser räumt).

**Abgleich mit Level 18.** Warm 5,8 % statt 75,9 % – unser Dschungel ist ein
flächiger Grünschleier, das Vorbild wird vom warmen roten Weg getragen. Und die
Deckungsflecken, auf denen das ganze Level steht, messen im Bild `(116, 68, 58)`
gegen den Weg `(46, 79, 18)`: ein stumpfes Braun auf rotbraunem Weg. Grüner
Nebel und grünes Umgebungslicht entsättigen das Magenta zu Schlamm.

---

### 4-4 · Sturmruinen
*Vorbild: „Ruination" (Ruinen im Gewitter)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** **Böden, die sich drehen und kippen.** Rotierende Säulen als
Plattformen, Platten, die beim Betreten kippen und fallen. Dazu Statuen, die im
Takt Feuer speien, und Werfer.

**Leveldesign.** Ruinenpfad mit großen Steinbauwerken, nachts im Gewitter. Die
Drehplattformen stehen oft dort, wo auch ein Gegner steht – der Spieler muss
zwei bewegte Dinge gleichzeitig lesen. Im Bild belegt: **weiße Umrisskisten**,
die erst durch ihren Auslöser körperlich werden, und ein **Bonusraum**.

**Design.** *Korrigiert:* Das Level ist dunkel, aber **die Silhouette liegt
dunkel vor hell**. Die Ruinen am Horizont sind schwarze Umrisse vor einem
helleren blaugrauen Regenhimmel – daran liest man ihre Form. Der begehbare
Stein ist tealgrün bemoost und deutlich heller als der Hintergrund. Dazu
orangefarbenes Fackelfeuer als einziger warmer Ton, Regenstreifen als Struktur
und Blitze als senkrechte helle Akzente.

- Träger: `#0A0F17` 21 % · `#415159` 19 %
- Signal: `#2B506B` 2,0 % · `#3C6871` 2,7 %
- warm 9,4 % · kühl 74,4 % · Helligkeit 53

**Gegner.** Harmlose Läufer im Weg, Werfer, Echsen (**nur per Slide** zu
besiegen), Feuerspeier, teils schwenkend.

**Was es schwer macht.** Gegner auf drehenden Plattformen.

**Erkennungsmerkmal.** Der Blitz, der für einen Moment die ganze Ruine zeigt –
und die schwarzen Ruinenumrisse, die auch ohne ihn lesbar bleiben.

**Werkzeuge.** *Neu:* `Drehplattform`, `Kippplattform`, `Feuerspeier`, `Werfer`,
**`Umrisskiste`** + **`Auslöserkiste`**, **`Bonusraum`**, **`Silhouettenband`**
(Kulisse dunkel vor hellerem Himmel statt dunkel vor dunkel). *Vorhanden:*
`Gegner.besiegbar_durch` kann „nur Slide" bereits ausdrücken.

**Abgleich mit Level 19.** Helligkeit **9,6 statt 53**. Bei uns steht Dunkel vor
Dunkel – im Säulengang sieht man die fünf Scheiben über dem Abgrund zwischen
zwei Blitzen nicht. Dazu glüht unser Boden im Affenhof orangerot wie Lava, wo
das Vorbild nassen blaugrauen Stein hat.

---

### 4-5 · Kolbengang
*Vorbild: „Piston It Away" (Raumstation)*

**Ansicht.** **Durchgehend 2,5D-Seitenansicht.**

**Kernmechanik.** **Ein Hindernis, zwei Rollen.** Riesige Kolben versperren den
Gang – manche muss man passieren, während sie oben sind, auf andere muss man
sich stellen und hochfahren lassen. Dazu Gegner, deren Haltung bestimmt, wie
man sie besiegt: Arme unten = draufspringen, Arme oben = durchsliden.

**Leveldesign.** Innenraumkorridor mit Rückwegen: Um alle Kisten zu bekommen,
muss man den Weg zurücklaufen. Ein Todesweg zweigt ab – ohne Rettungsnetz,
dafür mit dem besten Preis. Bonusraum im Bild belegt, Kistenzähler sichtbar.

**Design.** *Grundlegend korrigiert:* Es sind **keine sandfarbenen Wandkacheln**.
Die Wände sind **olivgelbe Fliesen mit sichtbarem Fugenraster und Nieten**, auf
zylindrischen Tanks; davor liegen dichte Bündel aus **Kupfer- und
Bronzerohren** in mehreren Durchmessern. Die Stege sind gebürsteter Stahl mit
hellem Kantenglanz. Als kalte Gegenfarbe **grün leuchtende Ventilräder und
Sichtscheiben**; der Hintergrund ist blauschwarze Leere.

- Träger: `#0C0C18` 29 % · `#321815` 19 %
- Signal: `#A36630` 3,0 % · `#8D441C` 2,9 % · `#601B0C` 2,7 %
- warm 62,7 % · kühl 20,0 % · Helligkeit 57

**Gegner.** Laufroboter (nur Slide), Haltungsgegner, Bodenplatten, die etwas
auslösen, Schieber.

**Was es schwer macht.** Man muss bei jedem Gegner erst lesen, in welchem
Zustand er ist, bevor man reagiert.

**Erkennungsmerkmal.** Das Rohrbündel im Vordergrund, durch das man den Steg
dahinter sieht.

**Werkzeuge.** *Neu:* `Auslöseplatte`, `Strahlfalle`, **`Haltungsgegner`**,
**`Rohrbündel`** (Vordergrunddeko mit Durchblick), **`Fliesenwand`** (flaches
Raster mit Fuge, kein Rauschen). *Vorhanden:* `Wasserplattform` senkrecht ist
bereits der Kolben.

**Abgleich mit Level 20.** Kühl 0,5 % statt 20,0 % – das grüne Leuchten als
Gegenfarbe fehlt fast ganz. Und unsere Wand ist
`Materialbibliothek.fels().duplicate()` mit sandfarbenem Albedo: Das Rauschen
der Felstextur schlägt durch, es liest sich als Höhle statt als Station. Dazu
laufen Schneewiesel, Gletscherkrabben und Frostmotten durch die Raumstation.

---

## Raum 5 – Vorbilder aus dem dritten Spiel

Gemeinsamer Nenner: **Jedes Level bringt eine eigene Regel mit.** Nicht mehr
nur neue Hindernisse, sondern neue Grundbedingungen – Dunkelheit, Fliegen,
Hangeln. Das ist der teuerste, aber auch der lohnendste Raum.

Was in der ersten Fassung fehlte: In diesem Raum kommen zwei **Meta-Systeme**
dazu, die jedes Level rückwirkend verändern – Fähigkeiten, die man anderswo
bekommt und mit denen man in alte Level zurückgeht, und **Zeitläufe**, die
jedes Level zwingen, sauber und schnell durchlaufbar zu sein. Beides steht bei
uns nicht auf der Karte.

---

### 5-1 · Sandgrab
*Vorbild: „Sphynxinator" (ägyptisches Grab)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** Speerböden, die im Takt aus dem Boden schießen, und **Türen,
die sich schließen** – ein Zeitfenster, durch das man hindurch muss. Gleich am
Anfang eine Gabelung: Der eine Weg ist leicht, der andere nur mit Slide-Sprung,
Doppelsprung und Drehschlag hintereinander erreichbar.

**Leveldesign.** Zwei Wege mit unterschiedlichem Anspruch, die am Ende wieder
zusammenlaufen. Dazu ein Geheimnis, das nur findet, wer am Start **rückwärts**
läuft.

**Design.** *Bestätigt.* Der Boden ist **helle, fast cremefarbene Fliese** mit
sichtbaren Fugen – das Hellste im Bild. An beiden Wegrändern läuft ein
schmales **rot-grünes Zierband** mit; es sagt auf jeden Blick, wie breit der
Weg gerade ist. Die Wände tragen große, flächige Bildfelder in Tan-auf-Tan mit
roten, türkisen und blauen Akzenten. In den offenen Abschnitten steht über den
Wänden ein **kühles blaugraues Nichts** – das ist das einzige Gegengewicht zur
durchweg warmen Palette.

- Träger: `#33191A` 27 % · `#7B2C0D` 18 %
- Signal: `#9C430C` 3,7 % · `#932C08` 2,2 %
- warm 94,1 % · kühl 2,3 % · Helligkeit 82

**Gegner.** Wickelgestalten, Flammenwerfer hinter Deckung, Skorpione.

**Was es schwer macht.** Die Türfenster sind kurz, und dahinter geht es sofort
weiter.

**Erkennungsmerkmal.** Der Gang mit den bemalten Wänden und dem farbigen
Wegband.

**Werkzeuge.** *Neu:* `Schließtür`, `Wegverzweigung`, `Rückwärtsgeheimnis`,
**`Wandbildfeld`** (großflächige Zeichnung auf der Wand statt Streifen).
*Vorhanden:* `Stacheln` einfahrbar ist der Speerboden.

**Abgleich mit Level 21.** Das am besten getroffene Level der Reihe – warm
98,1 % gegen 94,1 %, Helligkeit 90 gegen 82. Zwei Kleinigkeiten: Unser Boden
ist mittleres Orange, wo das Vorbild fast cremefarben ist; und über den Wänden
liegt bei uns orangener Dunst statt des kühlen Nichts.

---

### 5-2 · Wolkenjagd
*Vorbild: „Mad Bombers" (Doppeldecker)*

**Ansicht.** **Freier Flug** – keine Levelkurve, kein Korridor.

**Kernmechanik.** **Fliegen und Schießen.** Freie Bewegung im Luftraum,
Trefferanzeige statt Leben, eine Zielvorgabe statt eines Zielportals.

**Leveldesign.** Kein Weg. Ein offener Raum über Schneebergen, in dem Ziele
kreisen. Der Fortschritt ist ein Zähler.

**Design.** *Bestätigt und messbar:* Die Palette ist durchgehend Grau in
mehreren Helligkeiten. Die Messung findet **keine einzige Signalfarbe über der
Sättigungsschwelle** – das ist genau die Absicht: Farbe steckt ausschließlich in
den Zielen. Wer im Dunst einen Farbfleck sieht, weiß sofort, dass es ein Ziel
ist.

- Träger: `#A9BDD7` 23 % · `#7586A5` 20 %
- Signal: keine – Absicht
- warm 5,8 % · kühl 83,3 % · Helligkeit 159

**Gegner.** Feindmaschinen in zwei Größen, dazu Ballons als leichtere Ziele.

**Was es schwer macht.** Zielen im Raum, während man selbst ausweicht.

**Erkennungsmerkmal.** Der eigene Flügel am unteren Bildrand.

**Werkzeuge.** *Neu und teuer:* `Flugmodus`, `Trefferanzeige` statt Leben,
`Zielzähler` als Levelabschluss.

**Abgleich mit Level 22.** Trifft den Steckbrief. Zwei Abweichungen: Unser Level
ist mit Helligkeit 201 gegen 159 zu hell, und das normale HUD mit Herzen und
Früchtezähler läuft neben der Zieltafel weiter – gefordert war die
Trefferanzeige **statt** der Leben.

---

### 5-3 · Funkenlicht
*Vorbild: „Bug Lite" (Grab bei Nacht)*

**Ansicht.** 3D-Verfolger.

**Kernmechanik.** **Dunkelheit als Regel.** Es gibt nur ein mitwanderndes
Licht; man sieht wenige Meter weit. Gefahren erscheinen erst im Lichtkreis.
Dazu Felder, die beim Durchqueren Fallen auslösen.

**Leveldesign.** Schmaler Grabgang, absichtlich ohne Verzweigung – Orientierung
wäre im Dunkeln unfair. Die Länge einer Passage ist durch die Sichtweite
begrenzt: Ein Sprung darf nie weiter gehen, als das Licht reicht.

**Design.** *Grundlegend korrigiert:* **Das Level ist nicht fast schwarz.**
Gemessen sind rund **47 % der Fläche warmer Ocker in gut lesbarer Helligkeit**.
Man sieht mehrere Meter weit: Säulen mit gemalten Bändern in Türkis, Rot und
Schwarz, die Rippelstruktur im Sandboden, einzelne Reliefs. Schwarz ist die
**Ferne** und der Himmel, nicht die Umgebung. Der mitgeführte Lichtkreis nimmt
dem Level die Weitsicht, nicht die Sichtbarkeit.

- Träger: `#080505` 24 % · `#834313` 19 %, dazu `#B07325` 15 % · `#D59F3E` 13 %
- Signal: `#A3440B` 3,0 % · `#A75811` 4,2 %
- warm 76,7 % · kühl 0,6 % · Helligkeit 60

**Gegner.** Kriechtiere und Wickelgestalten, alle erst spät sichtbar.

**Was es schwer macht.** Man kann nicht vorausplanen.

**Erkennungsmerkmal.** Der Lichtkreis im Schwarz – aber mit lesbaren Wänden
darin.

**Werkzeuge.** *Neu:* `Lichtkreis`, `Leuchtmarker`, `Auslösefeld`.
**Ergänzt:** Der Lichtkreis braucht ein **Restlicht**, das die Nahzone auf rund
ein Viertel Helligkeit hält – sonst ist er kein Licht, sondern eine Blende.

**Abgleich mit Level 23.** Helligkeit **4,2 statt 60** – vierzehnmal dunkler als
sein Vorbild, und damit das am weitesten abgewichene Level der Reihe. Die
Figur selbst ist im Bild kaum auszumachen; die Wände sind reines Schwarz statt
angedeutetem Ocker.

---

### 5-4 · Neonhöhe
*Vorbild: „Future Frenzy" (Zukunftsstadt)*

**Ansicht.** **Gemischt.** Teils 3D-Verfolger auf geschwungenen Stegen, teils
reine 2,5D-Seitenansicht – im selben Level. Der Wechsel ist Absicht: Wo es eng
und sprunglastig wird, klappt die Ansicht auf die Seite.

**Kernmechanik.** **Laserzäune**, die im Takt an- und ausgehen – dieselbe Idee
wie die Taktfläche, aber senkrecht und damit als Wand statt als Boden. Dazu
schwebende Plattformen auf festen Bahnen hoch über der Stadt.

**Leveldesign.** Hochhausdächer und Stege, senkrecht gestaffelt, mit viel Leere
darunter. Die Stadt selbst ist Kulisse und Tiefenmesser zugleich.

**Design.** *Korrigiert:* nicht durchgehend kalt. Tiefblaue und violette
Nachtflächen tragen das Bild, aber **kupfer- und bronzefarbene Wandpaneele**
liefern einen kräftigen warmen Gegenpart – gemessen 31,7 % warm. Der Steg ist
ein **helles mintgrünes Band mit hellerer Kante**, das Hellste im Bild; die
Neonstreifen und Leuchtscheiben liegen **hinter** der Spielebene, nicht darin.

- Träger: `#585078` 20 % · `#1C1C3D` 19 %
- Signal: `#3C58BD` 4,9 % · `#1E4DCC` 3,7 % · `#3D70B6` 2,0 %
- warm 31,7 % · kühl 46,3 % · Helligkeit 88

**Gegner.** Stachelroboter, fliegende Störer, Kugelroboter, Laserzäune.

**Was es schwer macht.** Lasertakt und Absturzgefahr zugleich.

**Erkennungsmerkmal.** Der Blick nach unten in eine leuchtende Stadt.

**Werkzeuge.** *Neu:* `Laserzaun`, `Neon-Materialsatz`, **`Ansichtswechsel im
Level`** (3D und 2,5D nacheinander, nicht als Zone). *Vorhanden:*
`Wasserplattform` mit Kurve ist die Schwebeplattform.

**Abgleich mit Level 24.** Unser bestes Bild der Reihe (Kontrast 51), aber
**warm 0,4 % statt 31,7 %** – die kupferfarbenen Wände fehlen ganz, unser Level
ist rein kalt. Dazu sind die Kisten dunkle Kästen auf dunklem Weg und kaum
auszumachen, und der Boden liest sich blaugrau statt mintgrün.

---

### 5-5 · Dächergasse
*Vorbild: „Hang'em High" (Altstadtdächer)*

**Ansicht.** 3D-Verfolger. Der Bonusraum ist ein völlig anders gestalteter
dunkler Innenraum – der Bruch ist Absicht.

**Kernmechanik.** **Hangeln.** Ein Gitter unter der Decke, an dem sich die Figur
entlangzieht – eine neue Fortbewegungsart neben Laufen und Springen. Dazu
fliegende Teppiche als Plattformen und Sprungteppiche als Trampoline.

**Leveldesign.** Dächer einer Altstadt, viel Auf und Ab, Sprünge zwischen
Teppichen. Ein Geheimweg führt über eine Treppe aus Nitrokisten, die hier
ausnahmsweise nicht explodieren – dieselbe Idee wie die Sackgasse in 4-1: Das
Level bricht seine eigene Regel und belohnt den, der es merkt.

**Design.** *Korrigiert:* Der **kräftig blaue Himmel steht in jeder
Außenaufnahme** und trägt 14,1 % der Fläche – er ist das Gegengewicht zur
warmen Wand, nicht ein Streifen am Rand. Dazu türkis-weiße Ornamentfelder in
den Spitzbögen, dunkle Holzgitterfenster als tiefer Kontrast, und ein sehr
heller cremefarbener Bodenbelag. Terrakotta liegt dazwischen, nicht über allem.

**Hinweis zur Methode:** Bei diesem Level verschluckt die alte Sechs-Ton-
Reduktion den Himmel restlos – alle sechs Töne kommen warm heraus. Das ist der
sauberste Beleg dafür, warum die Methode getauscht wurde.

- Träger: `#90543A` 21 % · `#6D362C` 21 %, dazu `#C89F70` 14 %
- Signal: `#A44B22` 4,3 % · `#A9260B` 3,3 %
- warm 80,8 % · kühl 14,1 % · Helligkeit 89

**Gegner.** Werfer mit Töpfen, Skorpione an der Decke (treffen beim Hangeln!),
Angreifer mit Klinge, Teppichreiter.

**Was es schwer macht.** Hangeln und Ausweichen gleichzeitig – man hat beim
Hangeln kaum Handlungsmöglichkeiten.

**Erkennungsmerkmal.** Die Figur, die unter einem Gitter hängt, während unten
die Gasse durchläuft.

**Werkzeuge.** *Neu und groß:* `Hangelgitter`. *Vorhanden:* `Kiste` in den Arten
`FEDER` und `SPRUNG` ist das Trampolin; `Wasserplattform` ist der fliegende
Teppich.

**Abgleich mit Level 25.** Kühl 0,2 % statt 14,1 % und Helligkeit 171 statt 89 –
der Sanddunst hat den Himmel und die Gasse unter dem Gitter weggenommen. Damit
fehlt genau das Erkennungsmerkmal. Ornamente in Rot, Weiß und Türkis gibt es
bei uns nicht, die Spitzbögen sind glatte Terrakotta.

---

## Werkzeugliste – was daraus zu bauen ist

Zusammengefasst und entdoppelt. Die Reihenfolge ist ein Vorschlag: erst das,
was in den meisten Leveln vorkommt und wenig kostet.

### Schon vorhanden – nur einsetzen

| Werkzeug | Deckt ab |
|---|---|
| `Wasserplattform` (2 Punkte + Kurve) | Aufzug (3-2), Kolben (4-5), Schwebeplattform (5-4), fliegender Teppich (5-5) |
| `Stacheln` mit `einfahrbar` | Speersäule (3-3), Speerboden (5-1) |
| `Eisfläche` | rutschige Platte (3-4) |
| `Kiste` (FEDER / SPRUNG) | Sprungteppich (5-5) |
| `Gegner.besiegbar_durch` | „nur per Slide" (4-4), Haltungsgegner-Grundlage (4-5) |
| `Gegner.abprall_hoehe` | Trampolingegner (3-4) |
| `Wasser` mit `toedlich` | Kanalrinne (4-1) |
| `Reiter` | Reittier (4-2) |
| `Treibmine` | hängende und schwimmende Hindernisse |
| `GameState.kisten_gesamt` + `ohne_tod` | die zwei Edelsteine – gebaut, aber von keinem Level gefordert |

### Gebaut und im Einsatz – und woher es kommt

Diese zwanzig standen in der ersten Fassung noch auf der Wunschliste und sind
inzwischen gebaut. Die Herkunftsspalte bleibt: Sie sagt, gegen welches Vorbild
ein Bauteil zu prüfen ist.

| Werkzeug | Aus | Kurz |
|---|---|---|
| `Bruchplatte` | 3-4, 4-4 | trägt kurz, dann fällt sie; Vorwarnung durch Wackeln |
| `Taktfläche` | 3-5, 4-1 | Fläche, die periodisch tödlich wird; Vorwarnung durch Farbe |
| `Rollhindernis` | 3-1, 4-1 | Kugel oder Fass rollt die Kurve entlang |
| `Drehplattform` | 4-4 | dreht sich um die Hochachse, nimmt den Spieler mit |
| `Feuerspeier` | 3-3, 3-5, 4-4, 5-1 | gerichteter Stoß im Takt, wahlweise schwenkend |
| `Werfer` | 3-3, 4-4 | Gegner mit Wurfgeschoss im Bogen |
| `Auslöseplatte` | 4-5, 5-3 | Betreten löst etwas aus |
| `Schließtür` | 5-1 | Zeitfenster im Weg |
| `Laserzaun` | 5-4 | senkrechte Taktbarriere |
| `Fließband` | 3-2 | Boden mit Eigengeschwindigkeit |
| `Schiebeblock` | 3-5 | drückt den Spieler seitlich |
| `Schwarm` | 4-3 | Gruppe, die zusammen verfolgt und zusammen fällt |
| `Deckungsfleck` | 4-3 | geduckt unangreifbar — nutzt unser Krabbeln |
| `Lichtkreis + Leuchtmarker` | 5-3 | Dunkellevel: Licht wandert mit, Wichtiges leuchtet selbst |
| `Stockwerksverlauf` | 3-5, 3-3 | mehrere Korridorlagen übereinander mit Sichtverbindung |
| `Wegverzweigung` | 5-1, 4-1 | zwei Routen mit eigenem Anspruch, die zusammenlaufen |
| `Spurhindernisse` | 4-2 | Hindernisse rhythmisch auf Spuren verteilen |
| `Neon-Materialsatz` | 5-4 | Leuchtmaterialien und dunkle Grundtöne als Satz |
| `Hangelgitter` | 5-5 | neuer Bewegungszustand: eigene Hitbox, eigener Clip, eigene Steuerung |
| `Flugmodus` | 5-2 | eigener Controller ohne Levelkurve, Schuss, Trefferanzeige, Zielzähler |

### Offen – aus der ersten Fassung

| Werkzeug | Aus | Warum es fehlt auffällt |
|---|---|---|
| `Turbo mit Kontrollverlust` | 4-2 | Der eigentliche Reiz des Vorbilds. Im Bild sogar eigens eingefärbt. |
| `Haltungsgegner` | 4-5 | Kernidee des Levels: erst lesen, dann reagieren. |
| `Verfolger` | 4-1 | Der Tempomacher, der das Warten erzwingt. |
| `Strahlfalle` | 4-5 | Bisher durch `Werfer` behelfsmäßig abgedeckt. |
| `Nische` | 3-1 | Bei uns als Wegverbreiterung gelöst – vertretbar. |

### Offen – neu aus dem Nachscan

| Werkzeug | Aus | Kurz |
|---|---|---|
| **`Seitenansicht als Betriebsart`** | 3-2, 3-3, 3-5, 4-5 | Ansicht des ganzen Levels, nicht Zone im 3D-Level |
| **`Ansichtswechsel im Level`** | 5-4 | 3D und 2,5D nacheinander |
| **`Frontansicht`** | 3-1 | Figur läuft auf die Kamera zu; die Sicht ist die Aufgabe |
| **`Umrisskiste` + `Auslöserkiste`** | 4-3, 4-4, 5-5 | Kiste wird erst körperlich, wenn ihr Auslöser fällt |
| **`Bonusraum`** | 3-1, 4-4, 4-5, 5-5 | eigener kleiner Raum, eigene Gestaltung, ohne Todesstrafe |
| **`Nitrowand`** | 4-3, 5-5 | Reihe Nitrokisten als Sperre |
| **`Röhrengang`** | 4-1 | geschlossene Decke, gekrümmte Wände, keine Ferne |
| **`Deckenlampe`** + **`Leitband`** | 4-1, 3-2 | Lichtinsel und waagerechter Streifen als Wegmarke |
| **`Silhouettenband`** | 4-4 | Kulisse dunkel vor hellerem Himmel |
| **`Rahmenzacken`** | 3-4 | dunkle Silhouetten am unteren Bildrand als Kontrastanker |
| **`Musterband`** | 3-3 | breites Grafikband als Materialschicht |
| **`Fliesenwand`** + **`Rohrbündel`** | 4-5 | flaches Raster mit Fuge; Vordergrunddeko mit Durchblick |
| **`Wandbildfeld`** | 5-1 | großflächige Zeichnung statt Streifen |
| **`Palettenwechsel`** | 3-5 | mehrere Grundpaletten je Level als Entwurfsmittel |
| **`Glührohr`** | 3-2 | Deko, die zugleich Lichtquelle ist |
| **`Unverwundbarkeit`** | alle | dritte Schutzladung als Zeitfenster statt als dritter Puffer |
| **`Zeitlauf`** | Raum 5 | zwingt jedes Level, sauber durchlaufbar zu sein |

---

## Abgleich: Vorbild gegen unser Level

Gemessen über alle Bildschirmfotos je Vorbild und über je sieben gerenderte
Stellen je eigenem Level. Die Zahlen sind mit `werkzeuge/foto.sh` reproduzierbar.

| | Vorbild | warm | kühl | hell | | unser Level | warm | kühl | hell |
|---|---|---|---|---|---|---|---|---|---|
| 3-1 | Rolling Stones | 56,5 | 21,4 | 50 | → | L11 Steinschlag | 68,0 | 8,1 | 97 |
| 3-2 | Castle Machinery | 69,0 | 10,9 | 51 | → | L12 Kesselwerk | **14,4** | **71,3** | 43 |
| 3-3 | Native Fortress | 70,7 | 18,4 | 80 | → | L13 Pfahlfeste | 98,4 | **0,1** | 115 |
| 3-4 | The High Road | 14,5 | 15,1 | 167 | → | L14 Wolkensteg | **0,1** | **0,0** | **245** |
| 3-5 | Sunset Vista | 71,3 | 16,9 | 73 | → | L15 Abendruinen | 99,4 | **0,0** | 91 |
| 4-1 | The Eel Deal | 34,3 | 41,0 | 45 | → | L16 Kanalgrund | 0,4 | 1,0 | **2,5** |
| 4-2 | Bear It | 1,2 | 94,4 | 107 | → | L17 Frostritt | 0,2 | 98,9 | 131 |
| 4-3 | Bee-Having | 75,9 | 8,1 | 77 | → | L18 Schwarmpfad | **5,8** | 0,2 | 101 |
| 4-4 | Ruination | 9,4 | 74,4 | 53 | → | L19 Sturmruinen | 5,5 | 41,5 | **9,6** |
| 4-5 | Piston It Away | 62,7 | 20,0 | 57 | → | L20 Kolbengang | 95,0 | **0,5** | 60 |
| 5-1 | Sphynxinator | 94,1 | 2,3 | 82 | → | L21 Sandgrab | 98,1 | 0,5 | 90 |
| 5-2 | Mad Bombers | 5,8 | 83,3 | 159 | → | L22 Wolkenjagd | 0,1 | 0,0 | 201 |
| 5-3 | Bug Lite | 76,7 | 0,6 | 60 | → | L23 Funkenlicht | 1,0 | 0,3 | **4,2** |
| 5-4 | Future Frenzy | 31,7 | 46,3 | 88 | → | L24 Neonhöhe | **0,4** | 94,4 | 41 |
| 5-5 | Hang'em High | 80,8 | 14,1 | 89 | → | L25 Dächergasse | 95,6 | **0,2** | 171 |

Nah dran: **21** und **17**. Weit weg: **23** (14× zu dunkel), **16** (18× zu
dunkel), **14** (Kontrast 6,6 bei einem Vorbild mit dem höchsten der Reihe),
**12** (Warm-kühl vertauscht), **24** (der warme Gegenpart fehlt ganz).

---

## Befunde

**Die drei Muster aus der ersten Fassung gelten weiter** – sie waren richtig
beobachtet:

1. **Ein Hindernis mit zwei Rollen.** Der Kolben ist Wand *und* Aufzug; der
   Kriecher ist Feind *und* Trampolin; die Nitrotreppe ist Todesfalle *und*
   Geheimweg.
2. **Das Level bricht einmal seine eigene Regel** – und belohnt den, der es
   merkt. Immer genau einmal pro Level, nie zweimal.
3. **Die Signalfarbe kommt sonst nirgends vor.** *Präzisiert:* Das gilt nicht
   levelweise, sondern **spielweit** – siehe Kistenvertrag.

**Vier Befunde kommen aus dem Nachscan dazu:**

4. **Ein Drittel der Vorbilder sind keine Korridore.** Vier sind durchgehend
   Seitenansicht, eines wechselt mitten im Level. Wir haben alle fünfzehn als
   3D-Korridor gebaut. Das erklärt auch, warum die Verfolgerkamera in Level 12
   und 20 in der Geometrie steckenbleibt: Diese Räume sind für eine
   Seitenkamera entworfen.

5. **Unsere Level sind entweder zu hell oder zu dunkel – nie mittig.** Sieben
   der fünfzehn weichen um mehr als das Doppelte von der Helligkeit ihres
   Vorbilds ab, in beide Richtungen. Der gemeinsame Grund ist immer derselbe:
   Nebeldichte und Umgebungslicht regeln das *ganze* Bild, statt nur die Ferne.

6. **Der Gegenton fehlt fast überall.** In acht Leveln liegt unser
   Kühl-Anteil unter einem Prozent, wo das Vorbild zwischen 14 und 20 Prozent
   hat. Das Albedo ist im Code jedes Mal richtig gesetzt – es kommt nur nicht
   durch den Nebel.

7. **Der Takt ist bei uns kein Takt.** Zehn der fünfzehn Vorbilder bauen ihre
   Schwierigkeit aus Rhythmus. Unsere Taktgeber liefen auf 3,8 s, 3,6 s, 2,4 s
   und 4,8 s – gemeinsames Muster erst nach über einer Minute. Siehe
   Taktvertrag.

**Wo zuerst ansetzen.** Der Taktvertrag ist die kleinste Änderung mit der
größten Wirkung – er betrifft zehn Level und ist eine Zahl je Bauteil. Danach
der Lesbarkeitsvertrag (Nebel nur in die Ferne), der die sieben
Helligkeitsausreißer auf einmal erledigt. Die Ansichtsart ist der teuerste
Punkt und sollte warten, bis der Rest steht.
