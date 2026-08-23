# Architektur und Schnittstellen

Verbindliche Absprachen für alle Objekte im Spiel. Wer neue Szenen baut,
hält sich exakt an diese Schnittstellen – nur so passen die Teile zusammen.

## Grundregeln

1. **Keine fremden Assets.** Alle Meshes und Texturen werden prozedural im
   Code erzeugt (Godot-Primitive, `SurfaceTool`, `ArrayMesh`, Rauschtexturen).
2. **Materialien immer über `Materialbibliothek`** (`scripts/materialbibliothek.gd`)
   beziehen, Farben über `Farben` (`scripts/farben.gd`). Rückgaben werden
   geteilt – nie verändern, bei Bedarf `.duplicate()`.
3. **Szenen sind schlank:** `.tscn` enthält nur Wurzelknoten, Kollisionsformen
   und das Skript. Die Optik baut das Skript in `_ready()` auf. Das vermeidet
   Formatfehler in handgeschriebenen `.tscn`-Dateien.
4. **Deutsch** für Kommentare, Bezeichner und UI-Texte.
5. Nach jeder Änderung `bash werkzeuge/pruefe.sh` – muss `SAUBER` melden.

## Kollisionsebenen

| Ebene | Wert | Belegung |
|---|---|---|
| 1 | 1 | Welt: Boden, Plattformen, Kisten, Felsen, feste Props |
| 2 | 2 | Spieler (`CharacterBody3D`) |
| 3 | 4 | Gegner-Körper |

Trigger-Zonen sind `Area3D` mit `collision_layer = 0` und
`collision_mask = 2` (nur den Spieler beachten).

## Der Spieler (`scenes/player/player.gd`, `class_name Spieler`)

Gruppe: `spieler`

```gdscript
func angriffe() -> int              # Bitmaske, siehe Angriff
func abprallen(hoehe := 16.0)       # schleudert den Spieler nach oben
func schaden_nehmen()               # Tod, außer während invuln > 0
func sterben()
func respawn()
```

Lesbare Felder: `sliding`, `spinning` (Restzeiten in s), `slamming`,
`can_djump`, `invuln`, `velocity`, `gesperrt`.

Signale: `spin_gestartet`, `bauchplatscher_gelandet(pos)`, `gestorben`,
`abgeprallt`.

### Angriffsarten (`scripts/angriff.gd`)

```gdscript
Angriff.SPIN     # 1  Spin-Attacke läuft
Angriff.SLIDE    # 2  Slide läuft
Angriff.SLAM     # 4  Bauchplatscher läuft
Angriff.FALLEN   # 8  fällt schneller als -4 m/s (zum Draufspringen)
```

Prüfung im Ziel:

```gdscript
var maske: int = spieler.angriffe()
if maske & Angriff.SPIN:
    ...
# "von oben getroffen" zusätzlich über die Position prüfen:
if (maske & Angriff.FALLEN) and spieler.global_position.y > global_position.y + 0.5:
    ...
```

## Kisten (`scenes/crates/kiste.gd`, `class_name Kiste`)

Gruppe: `kisten`. Statischer Körper auf Ebene 1, plus `Area3D` für Treffer.

```gdscript
func zerbrechen(art: int = 0) -> void   # art = Angriff-Konstante, 0 = Umgebung
```

Der Bauchplatscher des Spielers ruft `zerbrechen(Angriff.SLAM)` bei allen
Kisten der Gruppe im Radius 2 m auf – jede Kistenart entscheidet selbst,
ob sie darauf reagiert (Eisenkisten z. B. nicht).

Zerbricht eine zählende Kiste, ruft sie `GameState.kiste_zerbrochen()`.
Früchte erzeugt sie über `Frucht.streuen(get_parent(), position, anzahl)`.

## Gegner (`scenes/enemies/gegner.gd`, `class_name Gegner`)

Gruppe: `gegner`.

```gdscript
@export var besiegbar_durch: int        # Bitmaske aus Angriff
func besiegen(art: int = 0) -> void     # Gegner geht kaputt
func _bewegung(delta: float) -> void    # Haken für die Fortbewegung
```

Trifft der Spieler den Gegner ohne passenden Angriff, ruft der Gegner
`spieler.schaden_nehmen()`. Bei erfolgreichem Sprung von oben zusätzlich
`spieler.abprallen(...)`.

## Früchte (`scenes/fruits/frucht.gd`, `class_name Frucht`)

```gdscript
static func streuen(elternteil: Node, pos: Vector3, anzahl := 1) -> void
```

Früchte fliegen ab 2,6 m Abstand zum Spieler und zählen über
`GameState.frucht_einsammeln(1)`.

## Spielstand (`autoload/GameState.gd`)

```gdscript
func level_starten(start_position: Vector3, kisten_im_level := 0)
func frucht_einsammeln(anzahl := 1)
func kiste_zerbrochen()
func setze_checkpoint(pos: Vector3)
func leben_verlieren()
func zeige_nachricht(text: String, dauer := 1.8)
```

## Speicherplätze (`autoload/Spielfluss.gd`)

Vier Plätze, jeder eine eigene Datei `user://spielstand_<n>.cfg`.
Geschrieben wird **ausschließlich beim Betreten des Portalraums**
(`hub.gd` ruft `Spielfluss.speichern()`), nie mitten im Level – so ist
immer klar, worauf ein Spielstand zurückfällt.

```gdscript
const SLOTS := 4
var aktueller_slot := 0             # 0 = noch keiner gewählt

func slot_daten(slot: int) -> Dictionary   # Kopfdaten, ohne zu laden
func neues_spiel(slot: int) -> void        # Platz leeren und in den Hub
func spiel_laden(slot: int) -> bool        # Platz laden und in den Hub
func speichern() -> void                   # nur mit gewähltem Platz
func slot_loeschen(slot: int) -> void
func bester_stand() -> Dictionary          # weitester Stand aller Plätze
```

Das Startmenü (`scenes/ui/splash.gd`) hat genau drei Einträge – Neues
Spiel, Spiel laden, Einstellungen. Beide Spiel-Einträge öffnen dieselbe
Tafel-Übersicht mit den vier Plätzen; ein belegter Platz fragt vor dem
Überschreiben nach.

## Eingabe (`autoload/InputHub.gd`)

Tastatur, Gamepad und Touch laufen an einer Stelle zusammen; der Spieler
fragt nichts anderes ab.

```gdscript
func bewegung() -> Vector2          # kamerarelativ, x = seitlich, y = vor/zurueck
func sprung_gedrueckt() -> bool
func sprung_gehalten() -> bool      # variable Sprunghoehe
func spin_gedrueckt() -> bool
func slide_gedrueckt() -> bool
func slide_gehalten() -> bool

signal status_gewuenscht            # Statustafel auf/zu
signal eingabeart_geaendert(art: Art)
enum Art { TASTATUR, PAD, TOUCH }   # zuletzt benutzt, siehe `eingabeart`
```

Gamepad-Belegung (Input-Map in `project.godot`), benannt wie auf einem
PlayStation-Controller:

| Aktion | Taste | Godot |
|---|---|---|
| jump | Kreuz ✕ | `JOY_BUTTON_A` |
| slide/slam | Kreis ○ | `JOY_BUTTON_B` |
| spin | Viereck □ | `JOY_BUTTON_X` |
| status | Dreieck △ | `JOY_BUTTON_Y` |
| move | linker Stick, Steuerkreuz | `JOY_AXIS_LEFT_*`, `JOY_BUTTON_DPAD_*` |

Die Touch-Steuerung (`scenes/ui/touch_controls.gd`) meldet ausschließlich
über `touch_*()` hierher; ihre Tasten liegen als Raute wie die
Symboltasten eines Controllers, ihre Größe folgt der Bildschirmdichte
(`DisplayServer.screen_get_dpi()`, Ziel rund 13 mm Durchmesser). Zeichen
und Farben liefert `scripts/pad_symbole.gd` (`class_name PadSymbole`) –
eine Stelle für Touch-Tasten und Statustafel.

Die Statustafel (`scenes/ui/statustafel.gd`, `class_name Statustafel`)
erzeugt der HUD selbst; sie hält den Baum an (`get_tree().paused`) und
sperrt so lange die Touch-Steuerung bis auf die Statustaste. Alles, was
während der Pause bedienbar bleiben muss, läuft auf
`PROCESS_MODE_ALWAYS` – InputHub, Touch-Steuerung und Tafel.

## Eigene Spielfigur (`autoload/Einstellungen.gd`, `scripts/modell_lader.gd`)

```gdscript
Einstellungen.modell_pfad() -> String      # "" = Beuteldachs
Einstellungen.waehle_modell(dateiname: String)
Einstellungen.setze_groesse(faktor: float) # 0.5 .. 2.0
Einstellungen.uebernehmen(quelle: String) -> String   # "" = geklappt

ModellLader.laden(pfad: String, groesse := 1.0) -> Node3D
ModellLader.einpassen(knoten: Node3D, ziel_hoehe: float) -> bool
```

Nur glTF (`.glb`/`.gltf`): zur Laufzeit steht kein Importer bereit, alles
andere ließe sich im fertigen Export nicht lesen. Eingepasst wird über die
zusammengefasste Hülle aller Netze — auf `ZIEL_HOEHE` (1,42 m) skaliert,
waagerecht mittig, Füße auf y = 0. Gerechnet wird über die Kette der
Kindverwandlungen, **nicht** über `global_transform`: der frisch geladene
Knoten hängt noch nicht im Baum. Kollisionsformen aus der Datei werden
verworfen, maßgeblich ist die Kapsel in `Player.tscn`.

`SpielerModell` lädt die Figur in `_baue_eigenes()` und behält seine
Schnittstelle unverändert. Sie sitzt in einem Halter auf Fußhöhe, damit ein
Stauchen sie zu Boden drückt statt in der Luft schrumpfen zu lassen; bewegt
wird sie nur als Ganzes (`_animiere_eigenes()`), da ihre Gliedmaßen
unbekannt sind. Fehlt oder klemmt die Datei, wird der Beuteldachs gebaut.

## Spielermodell (`scenes/player/beuteldachs.gd`, `class_name SpielerModell`)

Der Controller kennt nur diese drei Methoden:

```gdscript
func aktualisiere(delta, tempo: float, luft: bool, slide: float, spin: float)
func setze_blick(winkel: float)
func sichtbarkeit(sichtbar: bool)
```

`_baue()` erzeugt die Geometrie, `_animiere()` bewegt sie pro Frame.

## Kamera (`scripts/corridor_camera.gd`)

Ohne `kurve_pfad` gerader Korridor Richtung -Z. Mit einem `Path3D` in
`kurve_pfad` fährt die Kamera auf der Kurve hinter dem Spieler her und
folgt damit auch Biegungen im Level.

## Level (`scenes/levels/level_basis.gd`, `class_name LevelBasis`)

Ein Level erbt von `LevelBasis` und baut seinen Inhalt in `_baue()` auf.
Die Basisklasse legt die Knoten `Geometrie`, `Objekte` und `Deko` an,
hängt die Kamera an den Verlauf, setzt den Spieler ans Startportal,
zählt die Kisten und verbindet das Signal `level_geschafft`.

**Wichtig:** Position immer *vor* `add_child()` setzen. Gegner merken
sich in `_ready()` ihre Startposition für die Patrouille – wird die
Position erst danach gesetzt, springen sie zum Ursprung zurück.

Props werden als Szene instanziiert (`preload(".../Baum.tscn").instantiate()`),
nicht über `Baum.new()`.

## Levelbau (`scripts/level_werkzeuge.gd`, `class_name LevelWerkzeuge`)

```gdscript
static func kurve_aus_punkten(punkte: Array, glaettung := 0.45) -> Curve3D
static func korridor(elternteil, kurve, abschnitte, material,
        tiefe := 6.0, schritt := 1.0, mit_kollision := true) -> MeshInstance3D
static func plattform(elternteil, pos, groesse, material, drehung_y := 0.0)
static func punkt(kurve, strecke, seitlich := 0.0, hoehe := 0.0) -> Vector3
static func richtung(kurve, strecke) -> Vector3
static func drehung(kurve, strecke) -> float
```

`abschnitte` ist eine Liste `{"von", "bis", "breite", "breite_ende"}`.
Lücken zwischen den Abschnitten sind die Sprungpassagen. Level 01 hält
diese Liste in `ABSCHNITTE` als einzige Quelle und leitet daraus
`_breite_bei()`, `_rand_bei()` und `_weg_von_der_kante()` ab – so kann
kein Objekt neben dem Weg oder auf einer Abbruchkante landen.

Godot zeichnet Dreiecke als Vorderseite, wenn ihre Punkte aus
Blickrichtung **im Uhrzeigersinn** liegen (empirisch bestimmt).

## Props (`scenes/props/`)

`Baum` (LAUBBAUM/NADELBAUM/TOTHOLZ), `Wurzel`, `Stein`, `Grasfeld`
(MultiMesh + Wind-Vertexshader, ein Zeichenaufruf), `Kleinzeug`
(FARN/PILZ/BUSCH/BLUME), `Waldstreuer`. Jedes hat `saat` für
reproduzierbaren Zufall; Bäume, Wurzeln und Steine haben Kollision
auf Ebene 1, Gras und Kleinzeug nicht.

## Gefahren und Portale

`Wasser` (`flaeche`, `tiefe`, `toedlich`) mit eigenem Wellen-Shader,
`Stacheln` (`flaeche`, `einfahrbar`, `takt`), `Portal` (`ist_ziel`).
Das Zielportal sperrt den Spieler, zieht ihn ein und löst
`level_geschafft` aus.

**Renderer:** Das Projekt läuft auf `gl_compatibility` (Web-Export).
Keine `SCREEN_TEXTURE`/`DEPTH_TEXTURE`, keine Compute-Shader, kein
SDFGI oder Volumetric Fog.
