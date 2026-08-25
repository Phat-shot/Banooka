# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Banooka – 3D-Korridor-Plattformer

Eigenständiges Spiel in **Godot 4.7** (GDScript, Renderer *GL Compatibility*),
inspiriert von PS1-Korridor-Plattformern. Ziel: 25 Level plus Geheimlevel,
Portalraum als Hub, Desktop / Web / Android.

**Keine fremden Marken, Namen, Figuren oder Assets.** Alles Sichtbare wird zur
Laufzeit im Code erzeugt.

Ergänzende Dokumente: `ARCHITEKTUR.md` (verbindliche Schnittstellen je Klasse),
`README.md` (Levelinhalte, Export- und Docker-Wege im Detail).

## Befehle

```bash
# Pflicht nach jeder Änderung – muss "ERGEBNIS: SAUBER" melden
bash werkzeuge/pruefe.sh

# Ein einzelnes Level geometrisch prüfen (Kisten/Gegner auf Boden,
# Patrouillen, Absturzzone)
godot --headless --path . werkzeuge/LevelCheck.tscn -- res://scenes/levels/Level03.tscn

# Bilder rendern (braucht xvfb-run auf headless-Maschinen)
xvfb-run -a bash werkzeuge/foto.sh /tmp/bilder verfolger 20,60,110
FOTO_LEVEL=res://scenes/hub/Hub.tscn xvfb-run -a bash werkzeuge/foto.sh /tmp/bilder orbit 0,90,180

# Spielen
godot --path .                       # Hauptszene ist scenes/ui/Splash.tscn
godot --headless --path . --export-debug "Android" build/banooka-debug.apk
```

`pruefe.sh` braucht `godot` im PATH oder `GODOT=/pfad/zu/godot`; ohne das
bricht es mit Rückgabewert 2 ab. **Eine leere Ausgabe ist kein Beweis** –
das Skript hat früher „SAUBER" gemeldet, wenn Godot gar nicht lief.

Die drei Stufen von `pruefe.sh`: Parse-Fehler → jede Szene laden und
instanziieren (findet auch Fehler in `_ready()`) → Geometrie der Level.

Die APK baut `.github/workflows/android.yml` (`workflow_dispatch` oder Push
nach `main`), Artefakt `banooka-apk`.

## Physikwerte (VERBINDLICH – nie ohne Rückfrage ändern)

| Konstante | Wert | Bedeutung |
|---|---|---|
| G | -38 m/s² | Gravitation |
| JUMP_V | 12.2 | Sprungkraft |
| JUMP_CUT | 0.45 | Taste loslassen ⇒ `vel.y` auf `JUMP_V·0.45` kappen |
| DJUMP_V | 10.5 | Doppelsprung (1× pro Luftphase, nicht beim Bauchplatscher) |
| RUN_SPEED | 8.5 | Laufgeschwindigkeit |
| AIR_CTRL | 0.82 | Luftkontrolle |
| SLIDE_SPEED | 13.5 | Slide, Richtung beim Start eingefroren |
| SLIDE_TIME | 0.42 s | Slide-Dauer, Hitbox halbiert |
| SLIDEJUMP_V | 14.5 | Sprung aus dem Slide |
| SLAM_V | -30 | Bauchplatscher |
| SPIN_TIME | 0.55 s | Drehschlag, Wirkradius 1,7 m |

`plattformer-demo.html` im Projektordner ist der Three.js-Prototyp, aus dem
diese Werte stammen.

Steuerung ist **kamerarelativ**: „vorwärts" heißt immer „ins Bild hinein".

## Architektur

### Autoloads (Reihenfolge in `project.godot` beachten)

| Name | Aufgabe |
|---|---|
| `GameState` | Früchte, Leben, Schutz, Kistenzähler, Checkpoint, Debugmodus |
| `Einstellungen` | eigene Spielfigur, Debugmodus – bleibt über Sitzungen |
| `InputHub` | Tastatur, Gamepad und Touch zu **einem** Eingabezustand |
| `Spielfluss` | Szenenwechsel, vier Speicherplätze, Raum- und Levelfreigabe |
| `Ladeschirm` | Ladebildschirm während des mehrbildrigen Levelaufbaus |

Der Spieler fragt **nie** `Input` direkt ab, immer `InputHub`.

### Levelklassen

```
LevelBasis (scenes/levels/level_basis.gd)
  └── KorridorLevel (scenes/levels/korridor_level.gd)   ← Level 02 aufwärts
        └── Level02 … Level06
```

`LevelBasis` legt die Knoten `Geometrie`, `Objekte`, `Deko` an, hängt die
Kamera an den Verlauf, setzt den Spieler, zählt Kisten und verbindet
`level_geschafft`. Der Aufbau läuft über `_bauschritte()` verteilt auf
mehrere Bilder, damit der Ladebalken lebt – wer auf das fertige Level
warten muss, hängt sich an `aufbau_fertig`.

`KorridorLevel` verlangt drei Haken – `abschnitte()`, `ende()`,
`absturz_hoehe()` – und liefert dafür `breite_bei()`, `rand_bei()`,
`weg_von_der_kante()`, `kiste()`, `gegner()`, `frucht()`, `plattform()`,
`portale_setzen()`, `absturzzonen()`. **Die Abschnittsliste ist die einzige
Quelle für die Wegbreite**; wer sie umgeht, setzt Objekte neben den Weg.

Level 01 hängt noch direkt an `LevelBasis` und hat eigene Kopien dieser
Helfer (`_breite_bei` usw.) – bewusst so gelassen.

### Rail-Runner (Level 04, 05, 06)

`Reiter`, `Rennfahrer` und `Fluechtling` **erben von `Spieler`**, obwohl sie
kein `move_and_slide` benutzen: Sie kleben auf der Levelkurve und setzen
`global_position` aus Strecke, seitlichem Versatz und Höhe. Die Vererbung
ist nötig, weil Kisten und Gegner `koerper is Spieler` prüfen.

Folge: In `LevelCheck` greift die Absturzprobe bei diesen Leveln nicht und
wird übersprungen.

### Levelreset (`LevelBasis._bauplan_erfassen`)

Das Level merkt sich beim Aufbau für jede Kiste und jeden Gegner Szene,
Elternknoten, Transform und alle `@export`-Werte. Bei Tod oder Game Over
baut es sie daraus neu auf – einzelne Objekte lernen kein Wiederbeleben.
`GameState.setze_checkpoint()` sichert den Stand: Was davor zerbrochen war,
bleibt weg; was danach kam, kommt zurück.

### Optik

Alles prozedural: Meshes über `SurfaceTool` und Primitive, Texturen über
Rauschpuffer. Materialien **immer** über `Materialbibliothek`, Farben über
`Farben`. Rückgaben sind geteilt – vor dem Ändern `.duplicate()`.

`LevelWerkzeuge.schluchtwand()` baut Schluchtwände als MultiMesh aus Quadern
(nicht als gesweepte Fläche) mit bis zu drei Materialien: Grundfels, Adern in
Wellenbändern, Deckschicht als Saum auf der Sollhöhe.

### Kollisionsebenen

| Ebene | Wert | Belegung |
|---|---|---|
| 1 | 1 | Welt: Boden, Plattformen, Kisten, Props |
| 2 | 2 | Spieler |
| 3 | 4 | Gegner |

Triggerzonen sind `Area3D` mit `collision_layer = 0`, `collision_mask = 2`.

## Zeichensprache der Gegner (verbindlich)

Am Modell muss ablesbar sein, was wirkt – siehe Block in
`scenes/enemies/gegner.gd`:

- Drehschlag wirkt **nicht** → Stacheln, Klingen oder Draht auf Schlaghöhe (0,4–1,0 m)
- Draufspringen wirkt **nicht** → Panzer, Zapfen oder Dornen **oben**
- Nur Grätsche → unten nichts Angreifbares

Jedes Setting bekommt eigene Gegner (3–6 Typen). Eine Sumpfkröte im
Gletscher ist keine Gegnerwahl, sondern eine fehlende.

## Konventionen

1. **Deutsch** für Kommentare, Bezeichner und UI-Texte.
2. Szenen sind schlank: `.tscn` enthält nur Wurzelknoten, Kollisionsformen
   und Skript; die Optik baut `_ready()`.
3. **Position immer VOR `add_child()`** setzen – Gegner merken sich in
   `_ready()` ihre Startposition für die Patrouille.
4. Props als Szene instanziieren (`preload(...).instantiate()`), nicht `.new()`.
5. Nur CC0/frei lizenzierte Assets, Quelle in `assets/CREDITS.md`.
6. Input-Map in `project.godot` pflegen; Tastatur **und** Touch von Anfang an.

## Fallstricke (teuer erkauft)

- **`rauschtextur()` ist Simplex + Farbverlauf = Wolken.** Für Fels, Eis und
  Schnee Zellrauschen (`_zellen`) mit echter Höhen- und Normalkarte nehmen.
  Kachelung und Normalenstärke zu drehen hilft nicht.
- **`Area3D` meldet Überlappungen erst im nächsten Physikschritt.** Bei
  18 m/s ist der Spieler dann 0,30 m weiter – Höhenschwellen für „von oben
  getroffen" funktionieren deshalb nicht, die Fallrichtung schon.
- **`ProjectSettings.get_setting()` liefert ein geteiltes Dictionary.**
  Mutieren und zurückschreiben verdoppelt Input-Map-Einträge.
- Der Todes-Zeitgeber der Gegner läuft in `_physics_process` – Tests müssen
  `physics_frame` abwarten, nicht `process_frame`.
- Godots Ausgabe ist beim Weiterleiten blockweise gepuffert: Ein per
  `timeout` abgebrochener Lauf verliert seine Ausgabe komplett. In eine
  Datei umleiten statt in `head`.
- Level bauen über mehrere Bilder – in Werkzeugen `await aufbau_fertig`.
- Godot zeichnet Dreiecke als Vorderseite, wenn ihre Punkte aus
  Blickrichtung **im Uhrzeigersinn** liegen.

## Stand der Level

| Nr. | Titel | Setting | Besonderheit |
|---|---|---|---|
| 01 | Wurzelschlucht | Wald | einziges Level noch direkt auf `LevelBasis` |
| 02 | Frostschlucht | Schnee/Eis | Schlitterstrecken, 2D-Abschnitt |
| 03 | Moorbrücken | Sumpf | Bohlenweg |
| 04 | Katzensprung | Ritt | `Reiter` auf der Levelkurve |
| 05 | Hauerjagd | Flucht | Kamera vor dem Spieler, `Fluechtling` |
| 06 | Wettrennen | Karts | Rundkurs, drei Runden, `Rennfahrer` |

07–25 offen. Räume à fünf Level (`Spielfluss.LEVEL_JE_RAUM`); ein Raum
öffnet erst, wenn der vorige abgeschlossen ist – im Debugmodus alles offen.

## Steuerung (Input-Map)

| Aktion | Tastatur | Controller (PlayStation) | Touch |
|---|---|---|---|
| move | WASD/Pfeile | linker Stick / Steuerkreuz | Joystick links |
| jump | Leertaste | Kreuz ✕ (`JOY_BUTTON_A`) | ✕ (2× tippen = Doppelsprung) |
| spin | J / Strg | Viereck □ (`JOY_BUTTON_X`) | □ |
| slide/slam | Shift | Kreis ○ (`JOY_BUTTON_B`) | ○ (in der Luft = Bauchplatscher) |
| status | Tab | Dreieck △ (`JOY_BUTTON_Y`) | △ |

Die Touch-Tasten liegen als Raute wie die Symboltasten eines Controllers und
tragen dieselben Farben; ihre Größe folgt der Bildschirmdichte (Ziel rund
13 mm Durchmesser), nicht der Pixelzahl.
