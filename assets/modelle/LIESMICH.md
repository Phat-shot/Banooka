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
Diese sechs Namen sind der Standard; sie werden ohne Rücksicht auf
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

Prüfen lässt sich das mit:

    MODELLTEST_DATEI=meinmodell.glb bash werkzeuge/modelltest.sh

## Nach dem Hineinlegen

    godot --headless --path . --import
    bash werkzeuge/modelltest.sh

`pruefling.glb` ist eine selbst erzeugte Probefigur (drei Kästen, CC0).
Sie ist dazu da, den Weg zu prüfen: Erscheint sie in der APK und die
eigene Figur nicht, liegt es an der Datei und nicht am Spiel.
