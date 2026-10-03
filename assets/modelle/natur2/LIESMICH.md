# natur2 – Stilmodelle für Level 01 und den Portalraum

Hier liegen die CC0-Naturmodelle, die das neue Level 01 „Wurzelschlucht"
und der Portalraum streuen: Bäume, Totholz, bemooste Felsen, Stumpf und
Moosstamm. Jedes Paket bekommt einen eigenen Unterordner, sein Lizenztext
liegt daneben, und in `assets/CREDITS.md` steht je Paket eine Zeile.

Gelesen werden die Dateien ausschließlich über `Fremdmodelle`
(`scripts/fremdmodelle.gd`):

- `Fremdmodelle.baum()` macht aus einem Baum Netze im Format der
  prozeduralen Bäume – Stamm wie `Riesenstamm` (Borke in Weltprojektion),
  Krone wie `Kronenwolke` (mit Blattkarten), dazu eine Fernfassung. So
  teilen Modell- und prozedurale Bäume eine Zeichnung und einen Stoff
  (ARCHITEKTUR.md, „Modellbäume").
- `Fremdmodelle.netz()` verschmilzt alles andere zu einem Netz mit
  höchstens drei Flächen im Stoff des Waldes (`moosdecke()`, `laubstoff()`).

Welche Datei welche Rolle trägt, steht in `Fremdmodelle.ROLLEN` (Rollen
M1–M18 aus dem Levelplan).

## Stand: Ultimate Nature Pack (`unp/`, 16 Modelle)

| Rolle | Dateien | wo |
|---|---|---|
| M1 Hallen- und Hangbäume | `CommonTree_1`–`_5`, `PineTree_1`, `_2`, `_3`, `_5` | Level 01: hintere Reihen des Hangwalds; Portalraum: Waldsaum hinter der Nordmauer, `CommonTree_3`/`_4` und `PineTree_2`/`_5` (schmale Kronen) in den Räumen |
| M3 Talwald nah | `CommonTree_1`, `_2`, `_5`, `PineTree_1`, `_3` | Level 01: alle Bäume des nahen Talwalds samt ihrer Fernfassung |
| M8 Felsen | `Rock_Moss_2`, `_5`, `_6` | Level 01: Deko-Felsen am Saum, Waldboden der Haine |
| M16 Moosstämme, Stümpfe | `WoodLog_Moss`, `TreeStump_Moss` | Level 01: Waldboden der Haine |
| M17 Totholz | `CommonTree_Dead_1`, `_2` | Level 01: Totholz im Tal; Portalraum: Nebelsümpfe, Sand und Neon (Waldsaum) |

Die Dateien sind die FBX-Modelle des Pakets, mit Godot 4.7 in `.glb`
umgewandelt (FBX-Import über ufbx, Ausgabe über `GLTFDocument`): Form und
Materialnamen bleiben, nur das Format ändert sich (aus „White.001" wird
„White_001"; `Fremdmodelle` liest beide ohne die Nummer). Godot liest die
FBX headless auch selbst; `.glb` ist es, weil der Ordner, die Modellschau
und `Fremdmodelle` glTF erwarten – so gibt es im Projekt ein Modellformat.
Umwandeln (in einem Hilfsprojekt mit den FBX-Dateien):

    var szene := load("res://…/CommonTree_1.fbx") as PackedScene
    var wurzel := szene.instantiate()
    var doc := GLTFDocument.new()
    var zustand := GLTFState.new()
    doc.append_from_scene(wurzel, zustand)
    doc.write_to_filesystem(zustand, "/pfad/CommonTree_1.glb")

Die Materialien heißen nach ihrer Farbe („Green", „Wood", „White" …).
`NETZ_FARBEN` legt sie auf die Farben des Waldes, `_NAMEN_KLASSE` ordnet
sie zu (Birkenrinde „White" wäre nach der Farbe Fels, Beeren wären Borke),
die Option `klassen` überschreibt das je Rolle (M16: Grün auf dem Holz ist
Moos).

**Bewusst nicht genommen** – verglichen in der Modellschau und im Level:
Die Büsche des Pakets (`Bush_*`) stehen als gestapelte Kuppeln da, die
Pflanzen (`Plant_*`) sind keine Farne und auf Rollengröße drei Meter breit
– dort bleiben `Kronenwolke`, `Farnwerk` und `Bodenstreu`. Blumen und Gras
des Pakets sind nicht verdrahtet: Für M14 und M15 gibt es keinen Streuer,
der Modelle nimmt, `Bodenstreu` und `Rasensaum` decken beides ab. Ebenso der ferne Talwald: Aus
100 m lasen sich die kantigen Modellkronen als schwebende Platten, als
weiche Kugeln an ihren Stellen als Pilze auf Stielen.

## Messwerte

MESSWERTE_FOLGEN

## Einkaufsliste für später: Stylized Nature MegaKit

Das Quaternius **Stylized Nature MegaKit** (CC0) war die erste Wahl. Es
gibt es nur über itch.io (`quaternius.itch.io`), und das war in der
Bauumgebung gesperrt (CONNECT 403; quaternius.com selbst ging, poly.pizza
antwortete mit einer Browser-Prüfung). Die Rollen nennen seine Dateien
weiter in der Stufe `primaer`: Liegt es eines Tages in `megakit/`, gewinnt
es dort, wo es etwas hat, vor dem Ultimate Nature Pack (`ersatz`).

| Rolle | Datei |
|---|---|
| M1 Hallen- und Hangbäume (auch M3) | `megakit/CommonTree_1`, `_3`, `_5`, `megakit/Pine_1`, `_3` |
| M2 Rahmenbäume | `megakit/TwistedTree_1`, `_3` |
| M7 Konsolenpilze | `megakit/Mushroom_Laetiporus` |
| M8 Felsen | `megakit/Rock_Medium_1`, `_2` |
| M9 Kiesel | `megakit/Pebble_Round_1` |
| M11 Büsche | `megakit/Bush_Common`, `megakit/Bush_Common_Flowers` |
| M12 Farne | `megakit/Fern_1` |
| M13 Großblatt | `megakit/Plant_1` |
| M14 Blumen, Klee | `megakit/Flower_3_Group`, `megakit/Clover_1` |
| M15 Gras-Akzente | `megakit/Grass_Wispy_Tall` |
| M18 Pilze | `megakit/Mushroom_Common` |

Stimmt ein Name nicht, wird `ROLLEN` angepasst, nicht die Datei
umbenannt. Für M11–M15 und M18 gibt es heute keinen Streuer, der Modelle
nimmt (außer M12/M13 in `L01Rasen`): Wer sie hinzufügt, verdrahtet sie
dort, wo heute der Rückfall steht.

## Anforderungen an die Dateien

| Punkt | Wert |
|---|---|
| Format | glTF (`.gltf` + `.bin` + Texturen im selben Ordner) oder `.glb` |
| Komprimierung | **keine**: kein Draco, kein Meshopt, kein Basis-Universal |
| Texturen | nach dem Import VRAM-komprimiert: in der `.import` jeder Textur `compress/mode=2` (ETC2/ASTC ist im Projekt an) – das Ultimate Nature Pack bringt keine |
| Dreiecke | nahe Bäume ≤ 3000 (sonst `max_dreiecke` in `ROLLEN` setzen); `baum()` dünnt Stämme auf 1200 aus |
| Budget | höchstens rund 25 Modelle, VRAM ≤ 140 MB im Level, `.pck` höchstens 30 MB größer |

Unbeleuchtete Materialien (`KHR_materials_unlit`), fehlende Normalen,
gespiegelte Knoten und Alphaschnitt verarbeitet `netz()` selbst; ein
Prüfmodell in der Modellschau deckt genau diese Fälle ab.

## Ablauf beim Hinzufügen

1. Paket herunterladen, die ausgewählten Dateien samt Texturen in den
   Unterordner legen, den Lizenztext als `LIZENZ_<Paket>.txt` daneben.
2. Importieren: `godot --headless --path . --import`, danach die
   `compress/mode` der neuen Texturen prüfen.
3. Modellschau:

       MODELLSCHAU_NETZ=1 MODELLSCHAU_BILD=/tmp/netz.png \
           godot --path . res://werkzeuge/Modellschau.tscn

   Sie listet je Modell Flächen, Dreiecke, Hülle und Kronenunterkante,
   meldet `FEHLER` bei mehr als drei Flächen, unbeleuchteten Flächen und
   nahen Bäumen über 3000 Dreiecken, prüft die Modellbäume (`baum()`:
   Höhe, Fuß im Boden, Blattkarten, Dreiecke von Stamm, Krone und
   Fernfassung) und endet mit `=== 0 Abweichungen`. Die Bilder (Übersicht,
   Streuung aus der Spielkamera, Nahaufnahmen) zeigen jedes Modell im
   Licht und in der Tönung von Level 01 – keine rosa, keine flach
   leuchtenden Flächen. Die Schau nennt auch den VRAM-Zuwachs der Netze.
4. `.pck` vorher und nachher exportieren und die Größe notieren.
5. CREDITS-Zeile, dann `PRUEF_ASSETS=0` und `PRUEF_ASSETS=1 bash werkzeuge/pruefe.sh`
   – beide müssen SAUBER melden.

Die `.md`- und `.txt`-Dateien hier gehen nicht in den Export
(`export_filter` nimmt nur Ressourcen); CC0 verlangt keine Weitergabe des
Lizenztexts.

Achtung Bauspeicher: Die Netze von `baum()` liegen im `Bauspeicher`,
dessen Fassung nur die Skripte kennt. Wer eine Modelldatei austauscht,
ohne ein Skript zu ändern, leert `user://bauspeicher` von Hand.
