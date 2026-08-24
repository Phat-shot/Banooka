# Mitgelieferte Spielfiguren

Hier hineingelegte `.glb`-Dateien erscheinen im Spiel unter
**Einstellungen → Figur** und stecken in jedem Export – auch in der APK
und im Browser. Das ist der verlässliche Weg für eigene Modelle.

Der zweite Weg, „Datei wählen" im Einstellungsbild, kopiert eine Datei
nach `user://modelle`. Der funktioniert am Rechner gut, auf Android aber
nur mit Speicher-Berechtigung und passendem Dateidialog – für unsere
eigenen Figuren ist er deshalb der falsche.

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

## Nach dem Hineinlegen

    godot --headless --path . --import
    bash werkzeuge/modelltest.sh

`pruefling.glb` ist eine selbst erzeugte Probefigur (drei Kästen, CC0).
Sie ist dazu da, den Weg zu prüfen: Erscheint sie in der APK und die
eigene Figur nicht, liegt es an der Datei und nicht am Spiel.
