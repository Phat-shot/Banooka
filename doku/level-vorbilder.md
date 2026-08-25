# Level-Steckbriefe: Vorbilder für Raum 3, 4 und 5

> Dieselbe Fassung als lesbare Seite mit echten Farbfeldern:
> <https://claude.ai/code/artifact/92ce93b6-7345-4c5b-94f5-75f50de20c59>
> (Quelle dafür: `doku/level-vorbilder.html`. Beide Fassungen bei Änderungen
> nachziehen – diese Textdatei ist der Arbeitsstand.)

Fünfzehn Level aus drei klassischen Korridor-Plattformern, auseinandergenommen
nach dem, was wir davon brauchen: **Mechanik, Leveldesign, Design**.

**Wozu das dient.** Nicht zum Nachbauen von Inhalten, sondern zum Herausziehen
von Werkzeugen. Ein Level ist für uns interessant, wenn es *eine Frage stellt,
die unsere bisherigen Level nicht stellen*. Aus jeder solchen Frage wird ein
Bauteil, das in jedem unserer Level einsetzbar ist. Erst danach entstehen
eigene Level daraus.

**Was NICHT übernommen wird** (siehe CLAUDE.md): keine Namen, keine Figuren,
keine Assets, keine Texturen, keine Musik. Die Arbeitstitel unten sind unsere
eigenen. Die Farbwerte sind aus Bildschirmfotos *gemessen* – sie beschreiben
eine Stimmung, keine kopierte Palette, und werden für unsere Welten ohnehin
neu gemischt.

**Wie die Farben zu lesen sind.** Je Level sind die sechs Leitfarben eines
Referenzbildes angegeben, ermittelt über eine Farbreduktion auf sechs Töne.
Die Bilder stammen aus der PS1-Ära und sind durchweg dunkler, als sie in
Erinnerung sind; der wichtigere Wert ist deshalb der **Kontrast**, der jeweils
dabeisteht – welche zwei Töne das Bild tragen.

---

## Raum 3 – Vorbilder aus dem ersten Spiel

Gemeinsamer Nenner: **enge Korridore, harte Fallen, wenig Ausweichraum.** Der
Spieler hat dort nur Laufen, Springen und den Drehschlag. Alles, was schwer
ist, ist es durch *Timing*, nicht durch Bewegungsvielfalt. Für uns heißt das:
Diese fünf liefern die Taktgeber.

### 3-1 · Steinschlag
*Vorbild: „Rolling Stones" (Dschungel)*

**Kernmechanik.** Rollende Steinkugeln laufen den Korridor entlang – teils
entgegen, teils von hinten. Sie sind nicht besiegbar und nicht überspringbar;
man weicht in Seitennischen aus oder läuft ihnen davon. Das dreht die
Grundfrage des Levels um: nicht „wohin springe ich", sondern „wann darf ich
überhaupt losgehen".

**Leveldesign.** Gerader Dschungelpfad, kaum Höhenunterschied. Der Weg ist
rhythmisch von steinernen Torbögen unterbrochen; zwischen ihnen liegen die
Nischen. Die Kugel bestimmt den Takt, die Nischen sind die Pausen. Länge über
Wiederholung mit steigender Frequenz.

**Design.** Warm-kalt-Kontrast: sandbrauner Weg gegen türkisgrünen,
geschnitzten Stein. Dunkelgrünes Blattwerk als Rahmen, orangebraune
umgestürzte Stämme quer, rosa Blüten als einzige helle Tupfer.
Gemessen: `#282007` `#572D07` `#654F14` `#9B5F0F` `#B98D26` `#3A512D` –
also fast alles Erde und Holz, das Grün nur als Randband.

**Gegner.** Stinktiere (laufen quer über den Weg), Schildkröten,
fleischfressende Pflanzen (stationär, schnappen im Takt).

**Was es schwer macht.** Zwei Takte gleichzeitig: der Fels und der quer
laufende Gegner. Wer nur auf einen achtet, wird vom anderen erwischt.

**Erkennungsmerkmal.** Der Blick nach hinten über die Schulter auf eine Kugel,
die den ganzen Gang ausfüllt.

**Werkzeuge.** *Neu:* `Rollhindernis` (Kugel läuft die Levelkurve entlang,
tötet bei Berührung, endet in einer Grube), `Nische` (Ausweichbucht als
Korridor-Bauteil). *Vorhanden:* Gegner mit Querpatrouille.

---

### 3-2 · Kesselwerk
*Vorbild: „Castle Machinery" (Burgmaschinerie)*

**Kernmechanik.** Maschinen als Boden: Fließbänder, die den Spieler tragen
oder zurückschieben, Aufzugsplattformen, Kolben und Zahnräder. Der Boden ist
hier zum ersten Mal kein Verlass.

**Leveldesign.** Innenraum über mehrere Ebenen. Der Weg führt genauso oft nach
oben wie nach vorn; die Kamera muss dafür weiter weg. Enge Gänge wechseln mit
hohen Hallen. Ein Geheimweg direkt am Start führt über eine Plattform nach
oben – dort liegen Extraleben statt Kisten.

**Design.** Kaltes blaugraues Mauerwerk, rostroter Stahl, gelbe Seilzüge als
Linienführung, ein orange glühender Ofen als einzige warme Lichtquelle im
Bild. Punktbeleuchtung statt Sonne.
Gemessen: `#241B17` `#5B2515` `#37454E` `#4D4A39` `#ABA786` `#A14635` –
Kontrast trägt zwischen `#37454E` (Stein, kalt) und `#5B2515` (Rost, warm).

**Gegner.** Roboterschildkröten, Holo-Projektoren (blenden Hindernisse ein
und aus), Stachel-Untertassen (fliegen auf fester Bahn).

**Was es schwer macht.** Bewegte Böden über Abgründen. Ein verpasster Absprung
ist nicht korrigierbar, weil der Boden weiterfährt.

**Erkennungsmerkmal.** Reihen kleiner Maschinen hinter Gittern – eine Kulisse,
die arbeitet, ohne dass man sie berührt.

**Werkzeuge.** *Neu:* `Fließband` (Boden mit Eigengeschwindigkeit),
`Zahnrad`/`Walze` (drehendes Hindernis), `Feuerstoß` (Taktgefahr aus einer
Düse). *Vorhanden:* `Wasserplattform` deckt Aufzug und Kolben bereits ab.

---

### 3-3 · Pfahlfeste
*Vorbild: „Native Fortress" (Eingeborenenfestung)*

**Kernmechanik.** Senkrechter Aufstieg. Der Weg führt an einer Festungswand
entlang nach oben, über schmale Holzstege und einzelne Plattformen. Dazu
Fallen, die aus dem Boden schießen, und Werfer, die von oben stören.

**Leveldesign.** Klettern statt Laufen. Die Strecke ist kurz, die Höhe groß.
Fallen stehen dicht: Speersäule, Sprung, Fackel, Sprung. Kein Abschnitt ist
länger als zwei Hindernisse – dafür folgen sie ohne Pause.

**Design.** Warmes Holz in Braunstufen, überzogen mit gesättigten
Stammesmustern in Rot, Türkis und Ocker. Sandiger Boden, große geschnitzte
Tore als Wegmarken. Die Muster sind das ganze Design – die Formen selbst sind
schlichte Kästen.
Gemessen: `#221405` `#572A08` `#935C1A` `#6E4B18` `#B19045` `#9E3D05` –
eine reine Holzpalette; die Musterfarben sind zu kleinflächig für die Messung
und müssen bei uns bewusst gesetzt werden.

**Gegner.** Schildkröten, fleischfressende Pflanzen, Affen (werfen von
Podesten), Stachelsäulen, Fackeln, Speerträger.

**Was es schwer macht.** Dichte. Und dass ein Fehler nicht nur Schaden ist,
sondern Höhe kostet.

**Erkennungsmerkmal.** Das riesige geschnitzte Tor am Ende des Aufstiegs.

**Werkzeuge.** *Neu:* `Werfer` (Gegner mit Wurfgeschoss im Bogen),
`Feuerdüse quer`, `Aufstiegsverlauf` (Korridor, der sich in Stufen übereinander
staffelt statt nur vorwärts). *Vorhanden:* `Stacheln` mit `einfahrbar = true`
ist bereits die Speersäule.

---

### 3-4 · Wolkensteg
*Vorbild: „The High Road" (Seilbrücke über den Wolken)*

**Kernmechanik.** Eine Brücke aus einzelnen Planken über dem Nichts, mit
Lücken, die genau an der Sprungweite liegen. Dazu **Platten, die beim Betreten
wegbrechen**, rutschige Platten, und Gegner, die man als Absprunghilfe
benutzt: Auf eine umgeworfene Schildkröte gesprungen trägt der Sprung weiter.

**Leveldesign.** Das schmalste Level des Spiels – zwei Planken breit, kein
Rand, keine Deckung. Rein linear. Die Schwierigkeit steckt allein in der
Abfolge von Lücken; es gibt fast keine Gegner im üblichen Sinn.

**Design.** Der stärkste Kontrast der ganzen Reihe: ein fast weißes Wolkenmeer
gegen dunkle Pfosten und Seile. Am Horizont dunkle Felszacken. Farbe gibt es
kaum – Holzbraun, Seilbeige, sonst Helligkeitsstufen.
Gemessen: `#CED1D6` `#434036` `#A3A0A3` `#8A7557` `#C1BBB4` `#A79367` –
`#CED1D6` gegen `#434036` trägt das ganze Bild.

**Gegner.** Fast nur Schildkröten, und die sind hier Werkzeug statt Feind.

**Was es schwer macht.** Kein Fehler ist verzeihbar. Es gibt keinen Boden
unter dem Boden.

**Erkennungsmerkmal.** Die Seilbrücke, die im Weiß verschwindet.

**Werkzeuge.** *Neu:* `Bruchplatte` (trägt kurz, dann fällt sie),
`Trampolingegner` (Absprung höher als normal), `Seilsteg` (Korridorvariante
mit Seilgeländer und Pfosten). *Vorhanden:* `Eisfläche` ist die rutschige
Platte; die Absprunghöhe kennt `Gegner.abprall_hoehe` bereits.

---

### 3-5 · Abendruinen
*Vorbild: „Sunset Vista" (Ruinen im Abendlicht)*

**Kernmechanik.** Das Ausdauer-Level. Drei Stockwerke, die übereinanderliegen,
mit Fallen, die alle etwas anderes verlangen: Platten, die im Takt heiß werden;
Blöcke, die den Spieler seitlich von der Kante schieben; Fledermäuse, die
Bögen fliegen.

**Leveldesign.** Der Weg staffelt sich dreimal übereinander, statt nur vorwärts
zu laufen. Dadurch sieht man von unten, wo man später oben entlangkommt – das
ist die eigentliche Idee. Länge ist hier bewusst ein Mittel: Das Level fordert
Konzentration über Minuten, nicht über Sekunden.

**Design.** Komplementärkontrast: türkisgrüner Ruinenstein gegen einen warm
orangefarbenen Abendhimmel. Dunkelgrüne Pflanzen wachsen aus den Fugen,
drinnen brennen Fackeln.
Gemessen: `#142218` `#26471B` `#523114` `#34494A` `#5C4C1A` `#91531C` –
`#34494A` (Stein, kühl) gegen `#91531C` (Abendlicht, warm).

**Gegner.** Fledermäuse, Echsen, Feuerplatten, Schiebeblöcke.

**Was es schwer macht.** Nicht eine einzelne Stelle, sondern die Summe. Wer
achtzig Prozent schafft, fängt trotzdem von vorn an.

**Erkennungsmerkmal.** Der Blick von der obersten Ebene zurück über die
Strecke, die man schon gelaufen ist.

**Werkzeuge.** *Neu:* `Schiebeblock` (drückt den Spieler seitlich),
`Taktfläche` (Boden, der periodisch tödlich wird), `Flugbahn-Gegner`
(Fledermaus im Bogen), `Stockwerksverlauf` (mehrere Korridorlagen
übereinander mit Sichtverbindung).

---

## Raum 4 – Vorbilder aus dem zweiten Spiel

Gemeinsamer Nenner: **Der Spieler kann mehr, also darf das Level mehr
verlangen.** Slide, Bauchplatscher und Krabbeln existieren – und werden
gezielt erzwungen: Gegner, die nur per Slide fallen, Gänge, die nur geduckt
passierbar sind. Das ist genau unsere Lage nach dem Krabbeln-Umbau.

### 4-1 · Kanalgrund
*Vorbild: „The Eel Deal" (Kanalisation)*

**Kernmechanik.** **Der Boden ist zeitweise tödlich.** In den Wasserrinnen
takten Stromstöße; man wartet, statt zu rennen. Dazu rollende Giftfässer, die
den Gang entlangkommen, und drehende Rotorblätter als bewegliche Wände.

**Leveldesign.** Enge Gänge mit zwei Gabelungen. Eine davon sieht aus wie eine
Sackgasse voller Nitro – und ist der Geheimweg. Das Level lehrt: Was
offensichtlich falsch aussieht, ist manchmal der richtige Weg.

**Design.** Sehr dunkel. Olivbraune Rohre, teal-grüne Metallwände, giftgrünes
Wasser, rostorange Kisten als einzige warme Signale. Runde Ventile und
Messuhren als Wandschmuck – die Kulisse erzählt „Maschine", ohne dass sich
etwas bewegt.
Gemessen: `#0D1711` `#573015` `#624E29` `#1F4C3F` `#93481B` `#BA9455` –
`#1F4C3F` (Kanalgrün) gegen `#93481B` (Rost).

**Gegner.** Ratten, Aale (takten Strom), Scrubber (Putzroboter auf Bahn),
Fässer.

**Was es schwer macht.** Warten. Das Level bestraft das Tempo, das alle
anderen Level belohnen.

**Erkennungsmerkmal.** Die grün leuchtende Rinne, die man nicht betreten darf.

**Werkzeuge.** *Neu:* `Taktfläche` (dieselbe wie 3-5, hier waagerecht im
Boden), `Rollfass` (dieselbe Familie wie `Rollhindernis`),
`Rotorblatt` (drehendes Hindernis), `Verfolger` (Gegner auf fester Bahn, der
Tempo macht). *Vorhanden:* `Wasser` mit `toedlich = true`.

---

### 4-2 · Frostritt
*Vorbild: „Bear It" (Ritt auf dem Eisbären)*

**Kernmechanik.** Reittier. Vorwärts läuft es von allein, gelenkt wird nur
quer. Dazu ein Turbo, der Tempo gegen Kontrolle tauscht – das ist der
eigentliche Reiz: Der Spieler entscheidet laufend, wie viel Risiko er will.

**Leveldesign.** Schienenlevel. Eine enge Schneerinne, Hindernisse auf drei
gedachten Spuren, TNT-Kisten dazwischen. Kein Erkunden, reine Reaktion.

**Design.** Strahlend weißer Schnee, blaugraue Eiswände, türkisblaue
Eisformationen, dunkelblauer Nachthimmel mit Schneefall. Hölzerne Totems mit
warmen Mustern sind die einzigen Farbtupfer – und deshalb genau da, wo etwas
gefährlich ist.
Gemessen: `#B0BDCA` `#1A3752` `#6F91B0` `#3A6694` `#9EB6D0` `#965127` –
eine reine Blaupalette mit einem einzigen warmen Ton `#965127`.

**Gegner.** Robben, Orcas (springen aus dem Wasser quer über die Bahn),
Totempfähle, TNT.

**Was es schwer macht.** Sichtweite. Hindernisse erscheinen spät.

**Erkennungsmerkmal.** Der Blick von hinten auf Reiter und Tier in der
weißen Rinne.

**Werkzeuge.** *Vorhanden:* `Reiter` (Level 04) kann das schon. *Neu:*
`Spurhindernisse` (Hindernisse rhythmisch auf Spuren verteilen statt von Hand
setzen), `Turbo mit Kontrollverlust` als Eigenschaft des Reiters.

---

### 4-3 · Schwarmpfad
*Vorbild: „Bee-Having" (Dschungel mit Bienenschwärmen)*

**Kernmechanik.** **Verfolgende Schwärme.** Ein Schwarm ist kein einzelner
Gegner, sondern eine Gruppe, die als Ganzes kommt – und mit einem einzigen gut
gesetzten Schlag als Ganzes fällt (Belohnung: Extraleben). Dazu Bodenflecken,
in die man sich kurz eingräbt und unangreifbar ist.

**Leveldesign.** Dschungelpfad, auf dem Schwärme in Wellen kommen. Die
Deckungsflecken liegen rhythmisch – das Level ist ein Wechsel aus Rennen und
Ducken.

**Design.** Rot-maroon gepflasterter Weg mit hellem Sandstreifen in der Mitte,
große Baumstämme als Torbögen, sattes Grün, rote Pilze. Die magentafarbenen
Erdflecken sind Signalfarbe – sie kommen sonst nirgends vor.
Gemessen: `#07180D` `#000101` `#154D2A` `#4B3A1F` `#894113` –
der Referenzschuss ist dunkel; tragend ist `#154D2A` (Dschungelgrün) gegen
`#894113` (Wegrot).

**Gegner.** Bienenschwärme, grabende Gegner.

**Was es schwer macht.** Man darf nicht stehenbleiben, muss aber genau zielen.

**Erkennungsmerkmal.** Die magentafarbenen Flecken im roten Weg.

**Werkzeuge.** *Neu:* `Schwarm` (Gruppe, die zusammen verfolgt und zusammen
fällt), `Deckungsfleck` (Stelle, an der geduckt niemand herankommt – passt
unmittelbar auf unser Krabbeln).

---

### 4-4 · Sturmruinen
*Vorbild: „Ruination" (Ruinen im Gewitter)*

**Kernmechanik.** **Böden, die sich drehen und kippen.** Rotierende Säulen als
Plattformen, Platten, die beim Betreten kippen und fallen. Dazu Statuen, die
im Takt Feuer speien, und Gorillas, die Stämme werfen.

**Leveldesign.** Ruinenpfad mit großen Steinbauwerken, nachts im Gewitter. Die
Drehplattformen stehen oft dort, wo auch ein Gegner steht – der Spieler muss
zwei bewegte Dinge gleichzeitig lesen.

**Design.** Nasses blaugraues Steinwerk, dunkler Gewitterhimmel, orangefarbenes
Fackelfeuer, violette und magentafarbene Akzente. Blitze als kurze
Vollbeleuchtung.
Gemessen: `#1E1511` `#582511` `#41364F` `#6E44B7` `#953720` `#E0C4E2` –
`#41364F` (Sturmstein) gegen `#6E44B7` (Violett) und `#953720` (Feuer).

**Gegner.** Possums (harmlos, aber im Weg), Affen, Echsen (**nur per Slide**
zu besiegen – ihr Kragen schützt gegen Sprung und Drehschlag), Gorillas
(Wurfgeschoss), Götzenköpfe (Feuerstoß, teils schwenkend).

**Was es schwer macht.** Gegner auf drehenden Plattformen.

**Erkennungsmerkmal.** Der Blitz, der für einen Moment die ganze Ruine zeigt.

**Werkzeuge.** *Neu:* `Drehplattform` (rotiert um die Hochachse),
`Kippplattform` (fällt nach kurzer Standzeit – Verwandte der `Bruchplatte`),
`Feuerspeier` (gerichteter Stoß im Takt, wahlweise schwenkend),
`Werfer` (wie 3-3). *Vorhanden:* `Gegner.besiegbar_durch` kann „nur Slide"
bereits ausdrücken.

---

### 4-5 · Kolbengang
*Vorbild: „Piston It Away" (Raumstation)*

**Kernmechanik.** **Ein Hindernis, zwei Rollen.** Riesige Kolben versperren
den Gang – manche muss man passieren, während sie oben sind, auf andere muss
man sich stellen und hochfahren lassen. Dazu Gegner, deren Haltung bestimmt,
wie man sie besiegt: Arme unten = draufspringen, Arme oben = durchsliden.

**Leveldesign.** Innenraumkorridor mit Rückwegen: Um alle Kisten zu bekommen,
muss man den Weg zurücklaufen. Ein Todesweg zweigt ab – ohne Rettungsnetz,
dafür mit dem besten Preis.

**Design.** Warme sandfarbene Wandkacheln mit Ziernaht, Messing- und
Kupferrohre, grün leuchtende Bildschirme mit Symbolen, graues Metall,
orangefarbene Roboter. Warm und messingfarben gegen kaltes Grünleuchten.
Gemessen: `#1C100D` `#512F11` `#6B4C20` `#4D5650` `#926630` `#A19279` –
`#926630` (Messing) gegen `#4D5650` (Stahl).

**Gegner.** Laufroboter (nur Slide), Tentakelroboter (haltungsabhängig),
Schrumpfstrahlen (ausgelöst durch Bodenplatten), Schildträger (schieben).

**Was es schwer macht.** Man muss bei jedem Gegner erst lesen, in welchem
Zustand er ist, bevor man reagiert.

**Erkennungsmerkmal.** Der Kolben, der wie ein Stempel aus der Decke kommt.

**Werkzeuge.** *Neu:* `Auslöseplatte` (Betreten löst etwas aus),
`Strahlfalle` (Geschoss aus einer Wand), `Haltungsgegner` (wechselt zwischen
zwei Zuständen, die verschiedene Antworten verlangen). *Vorhanden:*
`Wasserplattform` senkrecht ist bereits der Kolben.

---

## Raum 5 – Vorbilder aus dem dritten Spiel

Gemeinsamer Nenner: **Jedes Level bringt eine eigene Regel mit.** Nicht mehr
nur neue Hindernisse, sondern neue Grundbedingungen – Dunkelheit, Fliegen,
Hangeln. Das ist der teuerste, aber auch der lohnendste Raum.

### 5-1 · Sandgrab
*Vorbild: „Sphynxinator" (ägyptisches Grab)*

**Kernmechanik.** Speerböden, die im Takt aus dem Boden schießen, und
**Türen, die sich schließen** – ein Zeitfenster, durch das man hindurch muss.
Gleich am Anfang eine Gabelung: Der rechte Weg ist leicht, der linke nur mit
Slide-Sprung, Doppelsprung und Drehschlag hintereinander erreichbar.

**Leveldesign.** Zwei Wege mit unterschiedlichem Anspruch, die am Ende wieder
zusammenlaufen. Dazu ein Geheimnis, das nur findet, wer am Start **rückwärts**
läuft.

**Design.** Warmer ockerfarbener Sandstein, Wände voller bemalter Hieroglyphen
in Rot, Türkis und Blau auf Tan. Sandiger Boden mit grün gefasstem Wegband,
Fackelorange. Der Boden ist hell, die Wände sind Muster.
Gemessen: `#60200E` `#26120D` `#9B501A` `#A03F16` `#E68D36` `#4E4827` –
durchweg warm; `#E68D36` (Fackellicht) ist der Blickfang.

**Gegner.** Mumien, Flammenwerfer hinter Deckung, Skorpione.

**Was es schwer macht.** Die Türfenster sind kurz, und dahinter geht es sofort
weiter.

**Erkennungsmerkmal.** Der Gang mit den bemalten Wänden und dem grünen
Wegband.

**Werkzeuge.** *Neu:* `Schließtür` (Zeitfenster), `Wegverzweigung` (zwei
Routen mit eigenem Anspruch, die zusammenlaufen), `Rückwärtsgeheimnis`.
*Vorhanden:* `Stacheln` einfahrbar ist der Speerboden.

---

### 5-2 · Wolkenjagd
*Vorbild: „Mad Bombers" (Doppeldecker)*

**Kernmechanik.** **Fliegen und Schießen.** Freie Bewegung im Luftraum statt
Korridor, Trefferanzeige statt Leben, eine Zielvorgabe („fünf abschießen")
statt eines Zielportals.

**Leveldesign.** Kein Weg. Ein offener Raum über Schneebergen, in dem Ziele
kreisen. Der Fortschritt ist ein Zähler.

**Design.** Fahlgrauer Dunsthimmel, weiße Wolken und Schneeberge, ein
braun-olivfarbener eigener Doppeldecker, rote Feindmaschinen, gelbe und weiße
Ballons. Die Farbe steckt fast nur in den Zielen – der Hintergrund ist
absichtlich fast einfarbig.
Gemessen: `#3D4E64` `#525869` `#403B3C` `#BCBDC9` `#24252C` `#8C735F` –
alles Grau; `#BCBDC9` gegen `#24252C`.

**Gegner.** Feindflugzeuge in zwei Größen.

**Was es schwer macht.** Zielen im Raum, während man selbst ausweicht.

**Erkennungsmerkmal.** Der eigene Flügel am unteren Bildrand.

**Werkzeuge.** *Neu und teuer:* `Flugmodus` (eigener Controller, freie
Bewegung, Schuss), `Trefferanzeige` statt Leben, `Zielzähler` als
Levelabschluss. **Das ist der größte Brocken der fünfzehn** – ein eigener
Bewegungsmodus wie `Reiter` und `Rennfahrer`, aber ohne Kurve.

---

### 5-3 · Funkenlicht
*Vorbild: „Bug Lite" (Grab bei Nacht)*

**Kernmechanik.** **Dunkelheit als Regel.** Es gibt nur ein mitwanderndes
Licht; man sieht wenige Meter weit. Gefahren erscheinen erst im Lichtkreis.
Dazu Scheinwerferfelder, die beim Durchqueren Fallen auslösen.

**Leveldesign.** Schmaler Grabgang, absichtlich ohne Verzweigung – Orientierung
wäre im Dunkeln unfair. Die Länge einer Passage ist durch die Sichtweite
begrenzt: Ein Sprung darf nie weiter gehen, als das Licht reicht.

**Design.** Fast schwarz. Ein warmer Lichtkreis um die Figur, Kisten und
Edelsteine leuchten von selbst, Wände nur angedeutet in Ocker. Das ist die
radikalste Gestaltung der fünfzehn: Fast alles ist nicht zu sehen.
Gemessen: `#120F0C` `#523019` `#A05524` `#61492F` `#3F434A` `#6685CA` –
`#120F0C` füllt das Bild, `#A05524` ist der Lichtkreis, `#6685CA` der
leuchtende Kristall.

**Gegner.** Krokodile, Mumien, Schlangen – alle erst spät sichtbar.

**Was es schwer macht.** Man kann nicht vorausplanen.

**Erkennungsmerkmal.** Der Lichtkreis im Schwarz.

**Werkzeuge.** *Neu:* `Lichtkreis` (Level-Eigenschaft: Umgebungslicht aus, ein
mitgeführtes Licht an), `Leuchtmarker` (Kisten, Früchte und Kanten leuchten
von selbst, damit sie im Dunkeln lesbar bleiben), `Auslösefeld`
(dasselbe Bauteil wie die `Auslöseplatte` aus 4-5, hier flächig).

---

### 5-4 · Neonhöhe
*Vorbild: „Future Frenzy" (Zukunftsstadt)*

**Kernmechanik.** **Laserzäune**, die im Takt an- und ausgehen – dieselbe Idee
wie die Taktfläche, aber senkrecht und damit als Wand statt als Boden. Dazu
schwebende Plattformen auf festen Bahnen hoch über der Stadt.

**Leveldesign.** Hochhausdächer und Stege, senkrecht gestaffelt, mit viel
Leere darunter. Die Stadt selbst ist Kulisse und Tiefenmesser zugleich.

**Design.** Tiefblaue und violette Nacht, Neonstreifen in Cyan, Magenta und
Grün, blau-weiße Glasfronten, mintgrüne Böden. Kalt, kontrastreich, alles
glüht ein wenig. Der Gegenentwurf zu jedem Naturlevel.
Gemessen: `#1B1424` `#2E2C5B` `#4E4E9A` `#584049` `#9E7E6A` `#3A4AA9` –
tiefes Blau in drei Stufen; die Neonfarben sind zu kleinflächig für die
Messung und müssen bei uns als Leuchtmaterial gesetzt werden.

**Gegner.** Stachelpanzer, fliegende Assistenten, Kugelroboter, Laserzäune.

**Was es schwer macht.** Lasertakt und Absturzgefahr zugleich.

**Erkennungsmerkmal.** Der Blick nach unten in eine leuchtende Stadt.

**Werkzeuge.** *Neu:* `Laserzaun` (senkrechte Taktbarriere),
`Neon-Materialsatz` (Leuchtmaterialien und dunkle Grundtöne als Satz).
*Vorhanden:* `Wasserplattform` mit Kurve ist die Schwebeplattform.

---

### 5-5 · Dächergasse
*Vorbild: „Hang'em High" (arabische Dächer)*

**Kernmechanik.** **Hangeln.** Ein Gitter unter der Decke, an dem sich die
Figur entlangzieht – eine neue Fortbewegungsart neben Laufen und Springen.
Dazu fliegende Teppiche als Plattformen und Sprungteppiche als Trampoline.

**Leveldesign.** Dächer einer Altstadt, viel Auf und Ab, Sprünge zwischen
Teppichen. Ein Geheimweg führt über eine Treppe aus Nitro-Kisten, die hier
ausnahmsweise nicht explodieren – dieselbe Idee wie die Sackgasse in 4-1:
Das Level bricht seine eigene Regel und belohnt den, der es merkt.

**Design.** Warme Terrakotta- und Sandwände, ornamentale Spitzbögen in Rot,
Weiß und Türkis, helle Sandböden, blauer Himmel. Hell und freundlich – der
Gegenpol zu 5-3.
Gemessen: `#CA6939` `#E8AA5E` `#572E1B` `#A45932` `#3B6CBA` `#A28A93` –
`#E8AA5E` (Sandwand) gegen `#3B6CBA` (Himmel), dazu `#CA6939` als
Terrakotta-Mitte. Die farbigste Palette der fünfzehn.

**Gegner.** Affen mit Töpfen, Skorpione an der Decke (treffen beim Hangeln!),
Assistenten mit Krummsäbel, Teppichreiter.

**Was es schwer macht.** Hangeln und Ausweichen gleichzeitig – man hat beim
Hangeln kaum Handlungsmöglichkeiten.

**Erkennungsmerkmal.** Die Figur, die unter einem Gitter hängt, während unten
die Gasse durchläuft.

**Werkzeuge.** *Neu und groß:* `Hangelgitter` (neuer Bewegungszustand mit
eigener Hitbox und eigenen Clips). *Vorhanden:* `Kiste` in den Arten `FEDER`
und `SPRUNG` ist das Trampolin; `Wasserplattform` ist der fliegende Teppich.

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

### Neu – kleine Bauteile, große Wirkung

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
| `Laserzaun` | 5-4 | senkrechte Taktbarriere (Verwandte der Taktfläche) |
| `Fließband` | 3-2 | Boden mit Eigengeschwindigkeit |
| `Schiebeblock` | 3-5 | drückt den Spieler seitlich |
| `Schwarm` | 4-3 | Gruppe, die zusammen verfolgt und zusammen fällt |
| `Deckungsfleck` | 4-3 | geduckt unangreifbar – nutzt unser Krabbeln |
| `Nische` | 3-1 | Ausweichbucht als Korridor-Bauteil |

### Neu – Level-Eigenschaften statt Einzelteile

| Werkzeug | Aus | Kurz |
|---|---|---|
| `Lichtkreis` + `Leuchtmarker` | 5-3 | Dunkellevel: Licht wandert mit, Wichtiges leuchtet selbst |
| `Stockwerksverlauf` | 3-5, 3-3 | mehrere Korridorlagen übereinander mit Sichtverbindung |
| `Wegverzweigung` | 5-1, 4-1 | zwei Routen mit eigenem Anspruch, die zusammenlaufen |
| `Spurhindernisse` | 4-2 | Hindernisse rhythmisch auf Spuren verteilen |
| `Neon-Materialsatz` | 5-4 | Leuchtmaterialien und dunkle Grundtöne als Satz |

### Neu – große Brocken, eigene Runde

| Werkzeug | Aus | Warum teuer |
|---|---|---|
| `Hangelgitter` | 5-5 | neuer Bewegungszustand im Spieler: eigene Hitbox, eigener Clip, eigene Steuerung |
| `Flugmodus` | 5-2 | eigener Controller ohne Levelkurve, Schusssystem, Trefferanzeige, Zielzähler |

---

## Was mir beim Durchsehen aufgefallen ist

**Drei Muster wiederholen sich, und die sind wertvoller als jedes Einzelteil:**

1. **Ein Hindernis mit zwei Rollen.** Der Kolben ist Wand *und* Aufzug; die
   Schildkröte ist Feind *und* Trampolin; die Nitro-Treppe ist Todesfalle
   *und* Geheimweg. Das kostet nichts extra und verdoppelt die Fragen, die ein
   Bauteil stellen kann.

2. **Das Level bricht einmal seine eigene Regel** – und belohnt den, der es
   merkt. Die Sackgasse, die keine ist (4-1); die Nitro-Kisten, die nicht
   explodieren (5-5); der Rückweg am Start (5-1). Immer genau einmal pro
   Level, nie zweimal.

3. **Die Signalfarbe kommt sonst nirgends vor.** Magenta im roten Dschungelweg
   (4-3), warmes Holz in der blauen Eisrinne (4-2), Orange im grauen
   Kanal (4-1). Gefahr und Belohnung sind an der Farbe zu erkennen, bevor man
   die Form erkennt. Das ist bei uns bisher nur bei den Kisten so.

**Und eine Warnung an uns selbst:** Zehn der fünfzehn Level bauen ihre
Schwierigkeit aus *Takt*. Wir haben derzeit fast keine Taktgeber – unsere
Hindernisse stehen still oder patrouillieren. Die `Taktfläche`, der
`Feuerspeier` und die `Bruchplatte` sind deshalb wichtiger als alles andere
auf der Liste; mit diesen dreien allein ließe sich die Hälfte der Vorbilder
sinngemäß bauen.
