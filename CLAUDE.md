# Projekt: 3D-Korridor-Plattformer (Arbeitstitel)

Eigenständiges 3D-Plattformer-Spiel, inspiriert von klassischen PS1-Korridor-Plattformern.
**Keine fremden Marken, Namen, Charaktere oder Assets verwenden** (kein "Crash", kein Original-Content).

## Ziel
- 25 Level + Geheimlevel, Hub-Raum mit Level-Portalen
- Plattformen: Desktop (Windows/macOS/Linux), Web (HTML5), später Android/iOS
- Engine: **Godot 4.x** (GDScript)

## Referenz
`plattformer-demo.html` im Projektordner = spielbarer Physik-Prototyp (Three.js).
Die Physikwerte daraus sind verbindlich und 1:1 zu übernehmen.

## Move-Set & Physikwerte (VERBINDLICH)
| Konstante | Wert | Bedeutung |
|---|---|---|
| G | -38 m/s² | Gravitation |
| JUMP_V | 12.2 | Sprungkraft (fixe Höhe) |
| JUMP_CUT | 0.45 | Taste loslassen ⇒ vel.y auf JUMP_V·0.45 kappen (variable Sprunghöhe) |
| DJUMP_V | 10.5 | Doppelsprung (2. Sprung in der Luft, schwächer, mit kurzem Spin-Effekt 0.2 s) |
| RUN_SPEED | 8.5 | Laufgeschwindigkeit |
| AIR_CTRL | 0.82 | Faktor Luftkontrolle |
| SLIDE_SPEED | 13.5 | Slide-Tempo, Richtung beim Start eingefroren |
| SLIDE_TIME | 0.42 s | Slide-Dauer, Hitbox halbiert |
| SLIDEJUMP_V | 14.5 | Slide-Jump: Sprung während Slide ⇒ höher als Normalsprung |
| SLAM_V | -30 | Bauchplatscher: Slide-Taste in der Luft ⇒ senkrecht runter |
| SPIN_TIME | 0.55 s | Spin-Attacke (zerbricht Kisten, besiegt Gegner), Wirkradius 1,7 m |

Regeln:
- Doppelsprung nur 1× pro Luftphase; Reset bei Bodenkontakt; nicht während Bauchplatscher.
- Steuerung ist **kamerarelativ**: „vorwärts" heißt immer „ins Bild hinein", auch in Kurven.
- Treffer von oben zählen noch 0,25 s nach dem schnellsten Fall nach (Fall-Gedächtnis),
  weil `move_and_slide` beim Aufsetzen `vel.y` sofort auf 0 zieht.
- Bauchplatscher zerbricht bei Landung Kisten im Radius 2 m (Schockwelle).
- Kisten zerbrechen durch: Spin, Bauchplatscher, Draufspringen mit Fallgeschwindigkeit.

## Stand der Level
01 Wurzelschlucht (Wald) · 02 Frostgrat (Schnee) · 03 Moorbrücken (Sumpf) ·
04 Katzensprung (Ritt auf der Wildkatze) · 05 Wettrennen (Karts, drei Runden).
06–25 offen.

Die Level 04 und 05 laufen nicht über `move_and_slide`, sondern kleben auf
der Levelkurve (`Reiter`, `Rennfahrer` – beide erben von `Spieler`, weil
Kisten und Gegner `koerper is Spieler` prüfen).

## Spielsysteme
- **Kisten:** normal (gibt Frucht), Checkpoint (setzt Respawn), später: TNT-artig (Timer), Bounce, Eisen (unzerbrechlich)
- **Sammeln:** Früchte (100 ⇒ Extraleben), Kisten-Zähler pro Level (alle ⇒ Edelstein-Äquivalent)
- **Leben/Respawn:** Tod ⇒ letzter Checkpoint; 0 Leben ⇒ Levelanfang
- **Hub:** Raum mit Portalen, 5 Level pro Abschnitt freischalten

## Projektstruktur (Godot)
```
res://
  scenes/
    player/Player.tscn + player.gd     # CharacterBody3D
    crates/  fruits/  hazards/  enemies/
    levels/Level01.tscn … Level25.tscn
    hub/Hub.tscn
    ui/HUD.tscn
  scripts/  assets/  autoload/GameState.gd
```

## Regeln für Claude Code
1. Eine Aufgabe pro Durchlauf (erst Controller, dann Kisten, dann je 1 Level). Keine Massen-Generierung von Leveln.
2. Nach jeder Änderung: Szene muss in Godot 4 fehlerfrei laden (keine Parse-Fehler in GDScript).
3. Physikwerte NIE ohne Rückfrage ändern.
4. Nur CC0/frei lizenzierte Assets (Kenney.nl, Quaternius); Quelle in assets/CREDITS.md eintragen.
5. Input: Tastatur + Touch (virtuelle Buttons) von Anfang an; Input-Map in project.godot pflegen.
6. Deutsch für Kommentare und UI-Texte.

## Steuerung (Input-Map)
| Aktion | Tastatur | Controller (PlayStation) | Touch |
|---|---|---|---|
| move | WASD/Pfeile | linker Stick / Steuerkreuz | Joystick links |
| jump | Leertaste | Kreuz ✕ (JOY_BUTTON_A) | Taste ✕ (2× tippen = Doppelsprung) |
| spin | J / Strg | Viereck □ (JOY_BUTTON_X) | Taste □ |
| slide/slam | Shift | Kreis ○ (JOY_BUTTON_B) | Taste ○ (in der Luft = Bauchplatscher) |
| status | Tab | Dreieck △ (JOY_BUTTON_Y) | Taste △ |

Die Slide-Taste macht dreierlei, je nach Lage: mit Richtung am Boden den
Slide, in der Luft den Bauchplatscher, und aus dem Stand **gehalten** das
Krabbeln. Krabbeln ist kein Schalter – losgelassen richtet sich die Figur
wieder auf und läuft normal weiter. Wo über ihr kein Platz zum Aufrichten
ist, krabbelt sie weiter, auch ohne Taste; Springen ist dort gesperrt.

Die Touch-Tasten liegen als Raute wie die Symboltasten eines Controllers und
tragen dieselben Farben; ihre Größe folgt der Bildschirmdichte (Ziel rund
13 mm Durchmesser), nicht der Pixelzahl.
