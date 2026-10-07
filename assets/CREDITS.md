# Assets – Quellen und Lizenzen

Es dürfen ausschließlich CC0- bzw. frei lizenzierte Assets verwendet werden
(z. B. [Kenney.nl](https://kenney.nl), [Quaternius](https://quaternius.com)).
Jede übernommene Datei wird hier mit Quelle und Lizenz eingetragen.

| Datei | Quelle | Lizenz | Anmerkung |
|---|---|---|---|
| `icon.svg` | eigene Erstellung | CC0 | Projekt-Icon |
| `assets/modelle/pruefling.glb` | eigene Erstellung (`werkzeuge/modelltest.gd`) | CC0 | Probefigur zum Prüfen des Modellwegs |
| `assets/modelle/natur/*.glb` (35) | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 | Bäume, Felsen, Pilze, Büsche, Blumen – Lizenztext liegt daneben. In Level 01 über `Fremdmodelle.netz()` zur Laufzeit **verändert**: zu einem Netz verschmolzen, Felsen, Kiesel und Stämme unterteilt und nachgeformt (gewölbt statt flach, Stämme rund), alle Stoffe ersetzt (`moosdecke`, `laubstoff`), Farben auf den Waldboden gelegt; die Dateien selbst bleiben unverändert |
| `assets/modelle/natur2/unp/*.glb` (16): `CommonTree_1`–`_5`, `PineTree_1`, `_2`, `_3`, `_5`, `CommonTree_Dead_1`, `_2`, `Rock_Moss_2`, `_5`, `_6`, `TreeStump_Moss`, `WoodLog_Moss` | Quaternius [Ultimate Nature Pack](https://quaternius.com/packs/ultimatenature.html) (Download über Google Drive) | CC0 | Bäume, Totholz, bemooste Felsen, Stumpf und Moosstamm für Level 01 und den Portalraum, dazu in Level 05 der Hangwald (`CommonTree_1`–`_5`, Rolle M1) und das Totholz an der Kuppe (`CommonTree_Dead_1`, `_2`, Rolle M17) – Lizenztext `LIZENZ_UltimateNaturePack.txt` liegt daneben. Die FBX-Dateien des Pakets sind mit Godot 4.7 (FBX-Import, `GLTFDocument`) **in .glb umgewandelt**, Form und Materialnamen unverändert. Zur Laufzeit **verändert** (`Fremdmodelle.baum()` / `netz()`): auf Rollenhöhe skaliert, Stammfuß in den Ursprung und 1 m in den Boden verlängert, Normalen geglättet und ausgedünnt; Stämme im Borkenstoff des Waldes (Weltprojektion, Moos am Fuß), Kronen im Kronenstoff der `Kronenwolke` mit zur Kronenmitte gebogenen Normalen, Verdeckung und eigenen Blattkarten, nach unten gestreckt; Felsen und Holz in `moosdecke()`; alle Farben auf den Wald gelegt (`NETZ_FARBEN`). Die MegaKit-Einkaufsliste (`natur2/LIESMICH.md`) bleibt offen: Das Paket gibt es nur über itch.io, und das war in der Bauumgebung gesperrt |
| `assets/modelle/natur2/unp/*.glb` (24, Raum 1): `Willow_1`, `_3`, `_5`, `BirchTree_1`–`_5`, `Rock_1`–`_7`, `CommonTree_Dead_3`–`_5`, `WoodLog`, `TreeStump`, `Bush_1`, `_2`, `BushBerries_1`, `_2` | Quaternius [Ultimate Nature Pack](https://quaternius.com/packs/ultimatenature.html) (Download über Google Drive, Unterordner „FBX“ des Paketordners) | CC0 | Weiden, Birken, Felsen ohne Moos, kahles Totholz, Treibholz, Stumpf und Sträucher für Raum 1 (Level 02–05, Rollen M19–M24 in `Fremdmodelle.ROLLEN`; in Level 05 die Birken im Tobel (M20), die sandsteinfarben getönten Felsen (M21) und die Sträucher (M24); dazu die Werkstatt, Station 32) – Lizenztext `LIZENZ_UltimateNaturePack.txt` liegt daneben. Am 05.10.2026 einzeln frisch aus dem Paket geladen (die Paketseite nennt CC0, die `License.txt` im Paket lautet unverändert auf CC0 1.0 Universal) und mit Godot 4.7.2 umgewandelt wie die Zeile darüber; die 24 .glb sind bitgleich mit einer früheren Umwandlung derselben Dateien. Zur Laufzeit **verändert** wie oben (`baum()`/`netz()`). Hinweis: quaternius.com/license zeigt seit 28.08.2026 eine eigene Lizenz (QAL) für spätere Veröffentlichungen; sie gilt nach ihrem Abschnitt 7 nicht rückwirkend, und dieses Paket steht auf seiner Seite weiter als CC0 |
| `assets/modelle/gegner/kroete.glb` | [Quaternius](https://quaternius.com) über [poly.pizza](https://poly.pizza) | CC0 | Laubfrosch, Optik der Sumpfkröte – **verändert**: Haut sumpfblaugrün (0,22 / 0,55 / 0,50) statt laubgrün, sechs runde helle Rückenflecken (auf die Haut gelegte Scheiben), ein Glanzpunkt in jedem Auge, feucht glänzende Haut und Augen |
| `assets/modelle/gegner/kaefer.glb` | Exceptional_3D über [poly.pizza](https://poly.pizza) | CC0 | Marienkäfer, Optik des Panzerkäfers – **umgefärbt**: der Panzer dunkles Mahagoni (0,34 / 0,17 / 0,10) statt rot, damit es kein Marienkäfer mehr ist; die Mittelnaht warmes Creme, die acht Fleckkugeln warngelb, der Kopf warmes Braun (0,32 / 0,22 / 0,14), die Fühler dunkelbraun; alle Flächen glänzender |
| `assets/modelle/gegner/spinne.glb` | [Quaternius](https://quaternius.com) über [poly.pizza](https://poly.pizza) | CC0 | Spinne, Optik der Stelzenspinne – **verändert**: leuchtend rote Augen, ein roter Stachelkamm aus fünf Spitzen auf dem Hinterleib, leichter Glanz auf dem Körper |
| `assets/schrift/LilitaOne-Regular.ttf` | [Lilita One](https://fonts.google.com/specimen/Lilita+One) von Juan Montoreano, über [google/fonts](https://github.com/google/fonts/tree/main/ofl/lilitaone) | SIL Open Font License 1.1 (OFL-1.1) | Anzeigeschrift der Oberfläche: Schriftzug BANOOKA, Titel, Banner, Zähler und Uhren (`scripts/ui_stil.gd`). **Unverändert** eingebunden – "Lilita" ist ein reservierter Schriftname, eine veränderte Fassung dürfte nicht so heißen. Copyright (c) 2011 Juan Montoreano; Lizenztext `assets/schrift/OFL.txt` liegt daneben |

## Eigene Figuren einbinden

`.glb`-Dateien in `assets/modelle/` erscheinen im Spiel unter
**Einstellungen → Figur** und stecken in jedem Export, auch in der APK.
Anforderungen und Stolpersteine stehen in `assets/modelle/LIESMICH.md`;
geprüft wird mit `bash werkzeuge/modelltest.sh`.

## Was fremd ist und was nicht

Fremde Modelle tragen ausschließlich **Deko und drei Gegner-Silhouetten**.
Umschaltbar über `Einstellungen.fremde_modelle`; ist der Schalter aus oder
fehlt eine Datei, baut sich jedes Teil wie bisher selbst auf. Dazu kommt
eine fremde **Schrift** für Titel und Zahlen; fehlt die Datei, schreibt
`UiStil` alles in der eingebauten Schrift.

Die Änderungen an den Gegnermodellen geschehen zur Laufzeit im Code
(`scenes/enemies/`, `scripts/fremdmodelle.gd`): umgefärbt, bemalt und um
eigene Teile ergänzt. Die `.glb`-Dateien selbst liegen unverändert vor.
Ebenso die Naturmodelle für Level 01, Level 05 und den Portalraum: `Fremdmodelle.netz()`
und `Fremdmodelle.baum()` nehmen aus der Datei nur die Form (und bei
texturierten Paketen die Textur, getönt); Stoff, Moos, Licht und Farbe kommen
aus dem Spiel.

| Bereich | Herkunft |
|---|---|
| Bäume, Felsen, Pilze, Büsche, Blumen | Kenney Nature Kit |
| Talbäume, hintere Hangbäume, Totholz und Waldboden in Level 01, Waldsaum und Raumbäume im Portalraum, Hangwald und Totholz an der Kuppe in Level 05 | Quaternius Ultimate Nature Pack |
| Weiden, Birken, Felsen, kahles Totholz, Treibholz und Sträucher für Raum 1 (Rollen M19–M24: Werkstatt-Station 32; in Level 05 Birken im Tobel, Sandsteinfelsen und Sträucher) | Quaternius Ultimate Nature Pack |
| Sumpfkröte, Panzerkäfer, Stelzenspinne | Quaternius bzw. Exceptional_3D – **alle Gegner** |
| Spielfigur, Reiter, Rennfahrer, Flieger | selbstgebaut |
| Werfer, Schwarm, Flugziel | selbstgebaut – für diese drei gibt es noch kein fremdes Modell |
| Hang-Clips der Spielfigur (`Hang`, `HangDuck`, `HangSpin`) | selbst erzeugt mit `werkzeuge/clip_bauen.py` |
| Kisten, Früchte, Portale, Stacheln, Wasser | selbstgebaut |
| Gelände, Wurzeln, Grasfelder, Portalraum | selbstgebaut |
| **sämtliche Texturen** | selbstgebaut (`FastNoiseLite`) |
| Anzeigeschrift (Logo, Titel, Banner, Zahlen) | Lilita One, SIL OFL 1.1 – die **einzige fremde Schrift** |
| Text, Hinweise, Beschriftungen | Open Sans SemiBold, in Godot mitgeliefert (SIL OFL 1.1) |

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
- **Schrift** für Text und auf den Kisten: die in Godot mitgelieferte
  Standardschrift (Open Sans SemiBold, SIL OFL 1.1 – so steht es in
  Godots eigener Lizenzliste, `Engine.get_copyright_info()`; früher stand
  hier irrtümlich Apache-2.0). Titel, Banner und Zahlen stehen
  in Lilita One (siehe Tabelle oben) – die einzige Schriftdatei im Projekt.

Damit ist das Projekt frei von fremden Marken und Figuren; fremd sind
nur die oben aufgeführten freien Modelle und die Schrift Lilita One.
