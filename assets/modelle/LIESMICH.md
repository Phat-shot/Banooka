# Mitgelieferte Spielfiguren

Hier hineingelegte `.glb`-Dateien erscheinen im Spiel unter
**Einstellungen → Figur** und stecken in jedem Export – auch in der APK
und im Browser. Das ist der verlässliche Weg für eigene Modelle.

Der zweite Weg, „Datei wählen" im Einstellungsbild, legt eine Datei nach
`user://modelle`. Den gibt es auf allen drei Plattformen, er verhält sich
aber überall etwas anders:

| Plattform | Wie | Wo die Datei landet |
|---|---|---|
| Rechner | Dateidialog von Godot | `~/.local/share/godot/app_userdata/Banooka/modelle` |
| Browser | Hochladefeld der Seite | im Browser selbst (IndexedDB), **pro Browser und pro Adresse** |
| Android | Dateidialog des Geräts | App-Ordner; braucht Speicher-Berechtigung |

Für **unsere eigenen** Figuren ist dieser Weg trotzdem der falsche: Was
im Browser hochgeladen wurde, sieht nur der eine Browser, und beim
Leeren der Websitedaten ist es weg. Mitgeliefert gehört sie hierher.

## Anforderungen an die Datei

| Punkt | Wert |
|---|---|
| Format | `.glb` (selbstenthaltend, Texturen eingebettet) |
| Komprimierung | **keine** – kein Draco, kein Meshopt, kein Basis-Universal |
| Blickrichtung | Figur schaut nach **−Z** |
| Fußhöhe | auf `y = 0`; die Höhe wird automatisch auf 1,42 m eingepasst |
| Kollision | keine – die Kapsel in `Player.tscn` ist maßgeblich |

Draco ist der häufigste Grund für „lädt nicht": Viele Werkzeuge schalten
die Komprimierung beim Ausgeben von sich aus ein. In Blender steht der
Haken unter *Datei → Exportieren → glTF 2.0 → Komprimierung*; er muss
aus sein. Das Spiel meldet diesen Fall inzwischen im Klartext, statt die
Figur stumm verschwinden zu lassen.

## Animationen: der Satz, den jede Figur mitbringen soll

Bringt eine Figur ein Skelett mit, führt das Spiel sie über ihre Clips.
Diese elf Namen sind der Standard; sie werden ohne Rücksicht auf
Groß- und Kleinschreibung erkannt, deutsche Entsprechungen ebenso.

| Clip | Dauer | Schleife | Wann |
|---|---|---|---|
| `IdlePose` | 0,1 s | nein | Rückfall, wenn `Idle` fehlt |
| `Idle` | 3 s | ja | steht still |
| `WalkSlow` | 1,6 s | ja | Eingabe unter 35 % |
| `Walk` | 1,0 s | ja | Eingabe 35–75 % |
| `Run` | 0,6 s | ja | Eingabe über 75 % |
| `Jump` | 1,15 s | **nein** | einmalig beim Abheben |
| `Slide` | 0,9 s | **nein** | einmalig beim Ansetzen |
| `Spin` | 0,4 s | ja | solange gedreht wird |
| `Crawl` | 1,2 s | ja | krabbelt (Slide-Taste aus dem Stand gehalten) |
| `Ride` | 0,8 s | ja | auf der Wildkatze (Level 04) |
| `Sit` | 2,0 s | ja | im Kart (Level 06) |

**Haltungen schlagen alles andere.** `Crawl`, `Ride` und `Sit` werden nicht
aus Tempo und Zustand erraten, sondern vom Spielcode gesetzt: Wer im Kart
sitzt, soll nicht zwischendurch einen Gehzyklus zeigen, nur weil sich die
Figur über die Strecke bewegt.

Fehlt einer, greift der nächstbeste: Eine Figur mit nur `Walk` benutzt ihn
auch zum Schlendern. Fehlt `Jump`, `Slide` oder `Spin`, bleibt der letzte
Bodenclip stehen und die eingebaute Ganzkörper-Stauchung zeigt den Zustand.

**Haltephasen.** `Jump` und `Slide` sind länger, als der Zustand im Spiel
dauert. Der Sprung wird deshalb am Scheitel angehalten, solange die Figur
fliegt, und der Slide in der Grätsche, solange gerutscht wird; beim
Aufsetzen bzw. Aufstehen springt das Spiel in den Schlussteil des Clips.
Die Marken sind Anteile der Cliplänge, keine festen Sekunden – eine Figur
mit anders langen Clips passt also ebenfalls.

**`Spin` dreht selbst.** Bringt eine Figur den Clip mit, dreht das Spiel
den Knoten NICHT zusätzlich, sonst wirbelte sie doppelt so schnell. Der
Wirkradius des Drehschlags bleibt bei 1,7 m (verbindlicher Physikwert aus
CLAUDE.md) und ist damit größer als die Armspannweite – das ist Absicht,
knapp danebengedreht soll trotzdem treffen.

**Kein Knochen unter die Sohle.** `y = 0` ist der Boden, und zwar in
jedem Clip, nicht nur im Ruhestand. Ein Clip, der tiefer greift, lässt die
Figur im Spiel ein Stück im Boden verschwinden – bei `Crawl` und `Slide`
passiert das schnell, weil dort Hand und Fuß flach aufliegen. Die Sohlen-
ebene ist nicht verhandelbar: Das Spiel setzt die Figur auf den Boden der
Kollisionskapsel, es kann eine zu tiefe Pose nicht erraten.

Prüfen lässt sich das mit:

    MODELLTEST_DATEI=meinmodell.glb bash werkzeuge/modelltest.sh
    bash werkzeuge/figur.sh /tmp/posen meinmodell.glb

Das zweite Werkzeug misst je Clip den tiefsten Knochen und legt zu jedem
ein Bild ab. Gemessen wird an den Knochen, nicht an der Netzhülle: Godot
meldet für gehäutete Netze immer die Hülle der Ruhepose.

## Wenn die Figur in Bewegung Zipfel zieht

Zwei Fehler beim Ausgeben fallen im Standbild nicht auf, reißen aber in
Bewegung lange Flächen durchs Bild. Für beide liegt ein Werkzeug bereit;
`cash_banooka_rc.glb` ist damit bereits gerichtet.

| Fehler | Was man sieht | Werkzeug |
|---|---|---|
| Hautgewichte am falschen Knochen | Platten und Fäden, die von einem Körperteil zum anderen spannen | `python3 werkzeuge/gewichte_richten.py <datei>` |
| Clip greift unter die Sohlenebene | Figur sinkt in bestimmten Posen in den Boden | `python3 werkzeuge/clips_richten.py <datei>` |

Beide arbeiten auf der Datei selbst und melden jede Änderung einzeln.

## Nach dem Hineinlegen

    godot --headless --path . --import
    bash werkzeuge/modelltest.sh
    bash werkzeuge/figur.sh /tmp/posen meinmodell.glb

`pruefling.glb` ist eine selbst erzeugte Probefigur (drei Kästen, CC0).
Sie ist dazu da, den Weg zu prüfen: Erscheint sie in der APK und die
eigene Figur nicht, liegt es an der Datei und nicht am Spiel.
