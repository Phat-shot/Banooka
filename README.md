# Banooka

3D-Korridor-Plattformer in **Godot 4** (GDScript), inspiriert von klassischen
PS1-Korridor-Plattformern. Eigenständiges Projekt ohne fremde Marken,
Charaktere oder Assets.

## Stand

Grundgerüst mit vollständigem Player-Controller. Kisten, Früchte, Gegner,
Hub und die Level 01–25 folgen in eigenen Schritten.

| Bereich | Status |
|---|---|
| Projektstruktur, Autoloads, Input-Map | fertig |
| Player-Controller (komplettes Move-Set) | fertig |
| Korridor-Kamera | fertig |
| HUD + virtuelle Touch-Steuerung | fertig |
| Testkorridor zum Ausprobieren | fertig |
| Kisten / Früchte / Gegner / Hazards | offen |
| Hub und Level 01–25 | offen |

## Starten

Projektordner in Godot 4.3+ öffnen und F5 drücken. Die Hauptszene ist
`scenes/levels/Testlevel.tscn` – ein reiner Testkorridor für den Controller.

## Im Browser starten

Der Web-Export ist als Preset **Web** in `export_presets.cfg` hinterlegt
(Ausgabe nach `export/web/`, ohne Thread-Unterstützung – damit läuft der
Build auf jedem beliebigen Webserver, auch auf GitHub Pages oder itch.io).

### Bereits exportierten Build starten

```bash
python3 werkzeuge/web_server.py
```

Der Server lauscht auf <http://localhost:8060/> und öffnet den Browser.
Ein anderer Port geht per `python3 werkzeuge/web_server.py 9000`,
ohne Browser-Start mit `--no-open`.

Wichtig: Ein Godot-Web-Export lässt sich **nicht** per Doppelklick auf
`index.html` öffnen – Browser blockieren WebAssembly über `file://`.
Es muss immer über `http://` ausgeliefert werden.

### Neu exportieren

Einmalig Godot und die Export-Templates installieren:

```bash
sudo pacman -S godot
```

Danach im Editor unter *Editor → Export-Templates verwalten* die zur
Godot-Version passenden Templates herunterladen (einmalig, ca. 1 GB).

Export dann entweder im Editor über *Projekt → Exportieren → Web*, oder
auf der Kommandozeile:

```bash
godot --headless --path . --export-release "Web" export/web/index.html
python3 werkzeuge/web_server.py
```

### Auf dem Handy testen

Der Server lauscht auf allen Netzwerkschnittstellen. Vom Handy im selben
WLAN `http://<IP-des-Rechners>:8060/` aufrufen – dann erscheinen auch die
virtuellen Touch-Buttons, die am Desktop ausgeblendet bleiben.

## Steuerung

| Aktion | Tastatur | Touch |
|---|---|---|
| Laufen | WASD / Pfeiltasten | Joystick links unten |
| Sprung | Leertaste | Button JUMP |
| Doppelsprung | Leertaste in der Luft | JUMP erneut tippen |
| Spin-Attacke | J / Strg | Button SPIN |
| Slide | Shift (in Bewegung) | Button SLIDE |
| Slide-Jump | Shift, dann Leertaste | SLIDE, dann JUMP |
| Bauchplatscher | Shift in der Luft | SLIDE in der Luft |

Die Sprunghöhe ist variabel: Taste früh loslassen ergibt einen kurzen Sprung.

## Physikwerte

Alle Werte stammen 1:1 aus `plattformer-demo.html` und sind in
`scenes/player/player.gd` als Konstanten hinterlegt. Sie sind laut
`CLAUDE.md` verbindlich und werden nicht ohne Rückfrage geändert.

## Projektstruktur

```
autoload/GameState.gd      Früchte, Leben, Kisten-Zähler, Checkpoint
autoload/InputHub.gd       Tastatur + Touch zu einem Eingabezustand gebündelt
scenes/player/             Player.tscn + player.gd (CharacterBody3D)
scenes/camera/             CorridorCamera.tscn
scenes/ui/                 HUD.tscn, TouchControls.tscn
scenes/levels/             Testlevel.tscn (später Level01 … Level25)
scenes/crates|fruits|hazards|enemies|hub/   noch leer
scripts/                   szenenunabhängige Skripte
assets/CREDITS.md          Quellen und Lizenzen
```

## Rendering

Das Projekt nutzt den Renderer **GL Compatibility**, damit die Web- und
Mobil-Exporte ohne Umstellung funktionieren.
