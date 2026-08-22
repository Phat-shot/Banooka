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
