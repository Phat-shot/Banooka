# Banooka

3D-Korridor-Plattformer in **Godot 4** (GDScript), inspiriert von klassischen
PS1-Korridor-Plattformern. Eigenständiges Projekt ohne fremde Marken,
Charaktere oder Assets.

## Stand

Level 01 ist spielbar. Hub und die Level 02–25 folgen.

| Bereich | Status |
|---|---|
| Projektstruktur, Autoloads, Input-Map | fertig |
| Player-Controller (komplettes Move-Set) | fertig |
| Beuteldachs-Modell mit Animationen | fertig |
| Korridor-Kamera (folgt auch Kurven) | fertig |
| HUD + virtuelle Touch-Steuerung | fertig |
| Kisten (9 Arten), Früchte | fertig |
| Gegner (3 Arten) | fertig |
| Wasser, Stacheln, Start-/Zielportal | fertig |
| Wald-Props, prozedurale Texturen | fertig |
| Level 01 "Wurzelschlucht" | fertig |
| Hub und Level 02–25 | offen |

## Level 01 – Wurzelschlucht

Ein 236 m langer Waldpfad auf einem Grat, in fünf Abschnitten. Der Verlauf
steckt in einer `Curve3D`; alle Objekte werden relativ dazu platziert, ein
geänderter Verlauf verschiebt also alles mit.

| Strecke | Abschnitt | Inhalt |
|---|---|---|
| 0–42 m | Waldrand | Anlaufstrecke, erste Kisten, Sumpfkröten zum Draufspringen |
| 42–100 m | Schlucht | Rechtskurve, Bach mit Lücken, Federkiste, Panzerkäfer |
| 100–158 m | Stacheln | Linkskurve, Stachelfelder, Stelzenvögel, TNT-Kette |
| 158–208 m | Baumkronen | Anstieg, schmaler Grat, Sprungfeder, Nitro |
| 208–236 m | Lichtung | Extraleben, Zielportal |

43 Kisten (37 zählen für den Edelstein), 14 Gegner, 82 Früchte, drei
Checkpoints. Wer neben den Pfad fällt, landet in der Absturzzone.

### Gegner

| Gegner | Nur besiegbar durch |
|---|---|
| Sumpfkröte | Draufspringen |
| Stelzenvogel | Slide (der Kamm oben verhindert Draufspringen) |
| Panzerkäfer | Spin-Attacke |

Der Bauchplatscher wirkt bei allen dreien.

### Kisten

`NORMAL` (1 Frucht) · `FRUCHT_MEHRFACH` (5) · `LEBEN` · `FEDER` (10 Absprünge,
je 1 Frucht) · `SPRUNG` (Sprungfeder, unzerstörbar) · `TNT` (3 s Countdown) ·
`NITRO` (explodiert bei Berührung) · `EISEN` (unzerbrechlich) · `CHECKPOINT`

## Starten

Projektordner in Godot 4.3+ öffnen und F5 drücken. Die Hauptszene ist
`scenes/levels/Level01.tscn`. `scenes/levels/Testlevel.tscn` bleibt als
schlichter Testkorridor für den Controller erhalten.

## Prüfen

```bash
bash werkzeuge/pruefe.sh
```

Läuft auf einer Kopie des Projekts und prüft drei Dinge: GDScript-Parse-Fehler,
das Laden und Instanziieren jeder Szene (findet auch Fehler in `_ready()`), und
die Geometrie von Level 01 – ob alle Kisten und Gegner auf festem Boden stehen,
ob Patrouillen nicht ins Leere laufen und ob die Absturzzone greift. Muss
`ERGEBNIS: SAUBER` melden.

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

## Docker: im Browser spielen, ohne Godot

Das Abbild enthält die fertig gebaute Web-Version und liefert sie über
nginx aus. Auf dem Zielrechner wird nur Docker gebraucht.

```bash
docker run --rm -p 8080:80 ghcr.io/phat-shot/banooka:latest
```

Dann <http://localhost:8080> öffnen. Oder aus dem Projektordner heraus
selbst bauen:

```bash
docker compose up -d --build
```

Der Build läuft zweistufig: die erste Stufe lädt Godot samt Web-Templates
und exportiert das Spiel, die zweite enthält nur noch nginx und die
fertigen Dateien. Das WebAssembly wird beim Bauen vorkomprimiert und über
`gzip_static` ausgeliefert – aus rund 34 MB werden etwa 9 MB über die
Leitung. `/gesundheit` liefert einen Health-Check für Orchestrierung.

Der Workflow `.github/workflows/docker.yml` baut das Abbild bei jedem
Push nach `main`, veröffentlicht es in der GitHub Container Registry und
startet es anschließend testweise, um Startseite, WebAssembly-MIME-Typ
und Header zu prüfen.

## Android: APK bauen

`.github/workflows/android.yml` baut bei jedem Push nach `main` ein
Debug-APK und legt es als Artefakt ab. Der Export läuft ohne Gradle über
die vorgefertigten Android-Templates; gebraucht werden nur ein
Schlüsselspeicher und `apksigner`/`zipalign` aus dem Android-SDK, das auf
den GitHub-Läufern bereits vorhanden ist.

Für ein signiertes Release-APK diese Geheimnisse im Repository hinterlegen:

| Geheimnis | Inhalt |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Schlüsselspeicher, base64-kodiert |
| `ANDROID_KEYSTORE_PASSWORD` | Passwort des Schlüsselspeichers |
| `ANDROID_KEY_ALIAS` | Alias des Schlüssels |

Schlüsselspeicher anlegen und kodieren:

```bash
keytool -genkeypair -v -keystore banooka.keystore -alias banooka \
        -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 banooka.keystore
```

Ein Tag `v*` hängt die APKs zusätzlich an die GitHub-Veröffentlichung.

Lokal geht der Export genauso, sobald die Android-Templates über
*Editor → Export-Templates verwalten* installiert sind:

```bash
godot --headless --path . --export-debug "Android" build/banooka-debug.apk
```

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
scenes/player/             Player.tscn, player.gd, beuteldachs.gd (Modell)
scenes/camera/             CorridorCamera.tscn
scenes/crates/             Kiste.tscn + kiste.gd (alle neun Arten)
scenes/enemies/            gegner.gd + Sumpfkroete/Stelzenvogel/Panzerkaefer
scenes/fruits/             Frucht.tscn
scenes/hazards/            Wasser.tscn, Stacheln.tscn
scenes/portals/            StartPortal.tscn, ZielPortal.tscn
scenes/props/              Baum, Wurzel, Stein, Gras, Kleinzeug, Waldstreuer
scenes/levels/             level_basis.gd, Level01.tscn, Testlevel.tscn
scenes/ui/                 HUD.tscn, TouchControls.tscn
scripts/                   angriff, farben, materialbibliothek, level_werkzeuge
shaders/                   wasser.gdshader
werkzeuge/                 pruefe.sh, Szenen- und Levelprüfung, Webserver
assets/CREDITS.md          Quellen und Lizenzen
ARCHITEKTUR.md             verbindliche Schnittstellen
```

## Rendering

Das Projekt nutzt den Renderer **GL Compatibility**, damit die Web- und
Mobil-Exporte ohne Umstellung funktionieren.
