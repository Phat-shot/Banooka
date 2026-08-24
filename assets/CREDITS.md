# Assets – Quellen und Lizenzen

Es dürfen ausschließlich CC0- bzw. frei lizenzierte Assets verwendet werden
(z. B. [Kenney.nl](https://kenney.nl), [Quaternius](https://quaternius.com)).
Jede übernommene Datei wird hier mit Quelle und Lizenz eingetragen.

| Datei | Quelle | Lizenz | Anmerkung |
|---|---|---|---|
| `icon.svg` | eigene Erstellung | CC0 | Projekt-Icon |
| `assets/modelle/pruefling.glb` | eigene Erstellung (`werkzeuge/modelltest.gd`) | CC0 | Probefigur zum Prüfen des Modellwegs |

## Eigene Figuren einbinden

`.glb`-Dateien in `assets/modelle/` erscheinen im Spiel unter
**Einstellungen → Figur** und stecken in jedem Export, auch in der APK.
Anforderungen und Stolpersteine stehen in `assets/modelle/LIESMICH.md`;
geprüft wird mit `bash werkzeuge/modelltest.sh`.

## Bisheriger Stand

**Es werden keine fremden Asset-Dateien verwendet.** Sämtliche Modelle,
Texturen und Effekte entstehen zur Laufzeit im Code:

- **Modelle** aus Godot-Primitiven (Kapsel, Kugel, Box, Zylinder, Kegel,
  Prisma, Torus) und aus `SurfaceTool`/`ArrayMesh` zusammengesetzt –
  Spielerfigur, Gegner, Kisten, Bäume, Wurzeln, Steine, Portale.
- **Texturen** aus `FastNoiseLite` über `NoiseTexture2D` mit Farbverläufen,
  samt passender Normalmaps (siehe `scripts/materialbibliothek.gd`):
  Rinde, Laub, Gras, Waldboden, Fels, Kistenholz, Metall, Fell.
- **Gelände** prozedural entlang einer `Curve3D` erzeugt
  (`scripts/level_werkzeuge.gd`).
- **Wasser** über einen eigenen Shader (`shaders/wasser.gdshader`).
- **Schrift** im HUD und auf den Kisten: die in Godot mitgelieferte
  Standardschrift (Open Sans, Apache-2.0).

Damit ist das Projekt frei von fremden Marken, Figuren und Assets.
