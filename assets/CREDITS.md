# Assets – Quellen und Lizenzen

Es dürfen ausschließlich CC0- bzw. frei lizenzierte Assets verwendet werden
(z. B. [Kenney.nl](https://kenney.nl), [Quaternius](https://quaternius.com)).
Jede übernommene Datei wird hier mit Quelle und Lizenz eingetragen.

| Datei | Quelle | Lizenz | Anmerkung |
|---|---|---|---|
| `icon.svg` | eigene Erstellung | CC0 | Projekt-Icon |
| `assets/modelle/pruefling.glb` | eigene Erstellung (`werkzeuge/modelltest.gd`) | CC0 | Probefigur zum Prüfen des Modellwegs |
| `assets/modelle/natur/*.glb` (35) | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 | Bäume, Felsen, Pilze, Büsche, Blumen – Lizenztext liegt daneben |
| `assets/modelle/gegner/kroete.glb` | [Quaternius](https://quaternius.com) über [poly.pizza](https://poly.pizza) | CC0 | Laubfrosch, Optik der Sumpfkröte – **verändert**: Haut sumpfblaugrün (0,22 / 0,55 / 0,50) statt laubgrün, sechs runde helle Rückenflecken (auf die Haut gelegte Scheiben), ein Glanzpunkt in jedem Auge, feucht glänzende Haut und Augen |
| `assets/modelle/gegner/kaefer.glb` | Exceptional_3D über [poly.pizza](https://poly.pizza) | CC0 | Marienkäfer, Optik des Panzerkäfers – **umgefärbt**: der Panzer dunkles Mahagoni (0,34 / 0,17 / 0,10) statt rot, damit es kein Marienkäfer mehr ist; die Mittelnaht warmes Creme, die acht Fleckkugeln warngelb, der Kopf warmes Braun (0,32 / 0,22 / 0,14), die Fühler dunkelbraun; alle Flächen glänzender |
| `assets/modelle/gegner/spinne.glb` | [Quaternius](https://quaternius.com) über [poly.pizza](https://poly.pizza) | CC0 | Spinne, Optik der Stelzenspinne – **verändert**: leuchtend rote Augen, ein roter Stachelkamm aus fünf Spitzen auf dem Hinterleib, leichter Glanz auf dem Körper |

## Eigene Figuren einbinden

`.glb`-Dateien in `assets/modelle/` erscheinen im Spiel unter
**Einstellungen → Figur** und stecken in jedem Export, auch in der APK.
Anforderungen und Stolpersteine stehen in `assets/modelle/LIESMICH.md`;
geprüft wird mit `bash werkzeuge/modelltest.sh`.

## Was fremd ist und was nicht

Fremde Modelle tragen ausschließlich **Deko und drei Gegner-Silhouetten**.
Umschaltbar über `Einstellungen.fremde_modelle`; ist der Schalter aus oder
fehlt eine Datei, baut sich jedes Teil wie bisher selbst auf.

Die Änderungen an den Gegnermodellen geschehen zur Laufzeit im Code
(`scenes/enemies/`, `scripts/fremdmodelle.gd`): umgefärbt, bemalt und um
eigene Teile ergänzt. Die `.glb`-Dateien selbst liegen unverändert vor.

| Bereich | Herkunft |
|---|---|
| Bäume, Felsen, Pilze, Büsche, Blumen | Kenney Nature Kit |
| Sumpfkröte, Panzerkäfer, Stelzenspinne | Quaternius bzw. Exceptional_3D – **alle Gegner** |
| Spielfigur, Reiter, Flüchtling, Rennfahrer, Flieger | selbstgebaut |
| Werfer, Schwarm, Flugziel | selbstgebaut – für diese drei gibt es noch kein fremdes Modell |
| Hang-Clips der Spielfigur (`Hang`, `HangDuck`, `HangSpin`) | selbst erzeugt mit `werkzeuge/clip_bauen.py` |
| Kisten, Früchte, Portale, Stacheln, Wasser | selbstgebaut |
| Gelände, Wurzeln, Grasfelder, Portalraum | selbstgebaut |
| **sämtliche Texturen** | selbstgebaut (`FastNoiseLite`) |

## Alles Übrige entsteht im Code

Sämtliche Modelle,
Texturen und Effekte entstehen zur Laufzeit im Code:

- **Modelle** aus Godot-Primitiven (Kapsel, Kugel, Box, Zylinder, Kegel,
  Prisma, Torus) und aus `SurfaceTool`/`ArrayMesh` zusammengesetzt –
  Spielerfigur, Gegner, Kisten, Bäume, Wurzeln, Steine, Portale.
- **Texturen** aus `FastNoiseLite` über `NoiseTexture2D` mit Farbverläufen,
  samt passender Normalmaps (siehe `scripts/materialbibliothek.gd`):
  Rinde, Laub, Gras, Waldboden, Fels, Kistenholz, Metall, Fell.
- **Gelände** prozedural entlang einer `Curve3D` erzeugt
  (`scripts/level_werkzeuge.gd`).
- **Wasser** über einen eigenen Shader (`shaders/wasser.gdshader`), ebenso
  Himmel (`shaders/himmel.gdshader`), Wasserfall und Lichtstrahlen.
- **Schrift** im HUD und auf den Kisten: die in Godot mitgelieferte
  Standardschrift (Open Sans, Apache-2.0).

Damit ist das Projekt frei von fremden Marken, Figuren und Assets.
