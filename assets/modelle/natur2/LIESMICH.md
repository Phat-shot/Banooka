# natur2 – Stilmodelle für Level 01

Hier liegen die CC0-Naturmodelle, die das neue Level 01 „Wurzelschlucht"
streut: Bäume, Büsche, Farne, Felsen, Kiesel, Pilze, Totholz. Jedes Paket
bekommt einen eigenen Unterordner, sein Lizenztext liegt daneben, und in
`assets/CREDITS.md` steht je Paket eine Zeile.

Gelesen werden die Dateien ausschließlich über `Fremdmodelle.netz()`
(`scripts/fremdmodelle.gd`): Jedes Modell wird zu einem Netz mit höchstens
drei Flächen verschmolzen, beleuchtet und in den Stoff des Waldes gesetzt
(`moosdecke()`, `laubstoff()`). Welche Datei welche Rolle trägt, steht in
`Fremdmodelle.ROLLEN` (Rollen M1–M18 aus dem Levelplan).

## Stand: leer – die Rückfälle greifen

Beim Bau dieses Ordners (29.09.2026) waren alle drei Quellen gesperrt:
`kenney.nl`, `quaternius.com` und `poly.pizza` lehnte die Netzwerkrichtlinie
der Bauumgebung ab (CONNECT 403). Der Ordner ist deshalb absichtlich leer.

Ohne natur2 läuft alles weiter:

| Rollen | was sie heute bekommen |
|---|---|
| M8 Felsen, M9 Kiesel, M11 Büsche, M14 Blumen, M16 Stämme, M18 Pilze | die vorhandenen Kenney-Modelle aus `../natur/`, über `netz()` nachgeformt (aus Tischplatten werden gewölbte Findlinge, Stämme rund) und bemoost |
| M1–M3 Bäume, M7 Konsolenpilze, M10 Trittsteine, M12 Farne, M13 Großblatt, M15 Wispelgras, M17 Totholz | den prozeduralen Rückfall des Aufrufers (`Riesenstamm`, `Kronenwolke`, `Findling`, `Farnwerk`, `Schluchtsaum`, `Rasensaum`, `Baum` TOTHOLZ) |

`Fremdmodelle.rolle("M1")` ist dann leer; genau daran erkennt der Streuer,
dass er selbst bauen muss.

## Messwerte (Stand: leer, Kenney-Rückfälle über `netz()`)

| Größe | Wert | gemessen mit |
|---|---|---|
| VRAM, Texturen | +2,1 MB | Modellschau (`MODELLSCHAU_NETZ=1`): alle 20 Rollenmodelle, ihre Stoffe und das Prüfmodell. Davon Moosmuster 0,35 MB (256², Mipmaps); der Rest sind die Muster `fels`, `rinde`, `laub` der Materialbibliothek, die das Level ohnehin teilt |
| VRAM, Puffer | +1,3 MB | ebenda: 20 Netze, je Fläche zweifach (Gesamtnetz und Einzelfläche) |
| `.pck` (Web) | +0,05 MB (2 813 668 → 2 866 052 Byte) | `--export-pack "Web"` vor und nach diesem Paket; nur Skripte, keine Dateien |
| Dreiecke | Felsen 576–680, Kiesel 64–96, Stamm 384, Büsche 16–104, Blumen 76, Pilze 48–144 | Modellschau |

Grenze aus dem Plan: VRAM-Zuwachs ≤ 30 MB, `.pck` ≤ +30 MB. Mit den
Paketen oben kommen deren Texturen dazu – nach dem Hinzufügen neu messen
und hier eintragen.

## Einkaufsliste (höchstens 20 Modelle)

| Unterordner | Paket | Quelle | Lizenz |
|---|---|---|---|
| `megakit/` | Quaternius **Stylized Nature MegaKit** (Standard, kostenlos) | quaternius.com – der Knopf führt oft zu drive.google.com oder quaternius.itch.io | CC0 |
| `unp/` | Quaternius **Ultimate Nature Pack** | quaternius.com; Einzelmodelle mit CC0-Vermerk auch auf poly.pizza | CC0 |
| `kenney/` | Kenney **Nature Kit**, vollständig | kenney.nl/assets/nature-kit | CC0 |

Die Auswahl (20), Namen wie im Plan – nach dem Herunterladen prüfen:

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
| M16 Moosstämme | `unp/WoodLog_Moss` |
| M18 Pilze | `megakit/Mushroom_Common` |

Weitere Namen aus `ROLLEN` (etwa `DeadTree_1`, `RockPath_Round_Wide`,
`TreeStump_Moss`, Kenneys `stump_old`) sind vorgesehen, aber nur, wenn das
Budget es hergibt. Stimmt ein Name nicht, wird `ROLLEN` angepasst, nicht
die Datei umbenannt.

## Anforderungen an die Dateien

| Punkt | Wert |
|---|---|
| Format | glTF (`.gltf` + `.bin` + Texturen im selben Ordner) oder `.glb` |
| Komprimierung | **keine**: kein Draco, kein Meshopt, kein Basis-Universal |
| Texturen | nach dem Import VRAM-komprimiert: in der `.import` jeder Textur `compress/mode=2` (ETC2/ASTC ist im Projekt an) |
| Dreiecke | nahe Bäume ≤ 3000 (sonst `max_dreiecke` in `ROLLEN` setzen) |
| Budget | ≤ 20 Modelle, VRAM ≤ 140 MB im Level, `.pck` höchstens 30 MB größer |

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
   nahen Bäumen über 3000 Dreiecken und endet mit `=== 0 Abweichungen`.
   Die Bilder (Übersicht, Streuung aus der Spielkamera, Nahaufnahmen)
   zeigen jedes Modell im Licht und in der Tönung von Level 01 – keine
   rosa, keine flach leuchtenden Flächen. Die Schau nennt auch den
   VRAM-Zuwachs der Netze.
4. `.pck` vorher und nachher exportieren und die Größe notieren.
5. CREDITS-Zeile, dann `PRUEF_ASSETS=0` und `PRUEF_ASSETS=1 bash werkzeuge/pruefe.sh`
   – beide müssen SAUBER melden.

Die `.md`- und `.txt`-Dateien hier gehen nicht in den Export
(`export_filter` nimmt nur Ressourcen); CC0 verlangt keine Weitergabe des
Lizenztexts.
