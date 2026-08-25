# Banooka

3D-Korridor-Plattformer in **Godot 4** (GDScript), inspiriert von klassischen
PS1-Korridor-Plattformern. Eigenständiges Projekt ohne fremde Marken,
Charaktere oder Assets.

## Stand

Der erste Abschnitt ist spielbar: Portalraum und die Level 01–05.
Die Level 06–25 folgen.

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
| Level 02 "Frostgrat" (Schnee) | fertig |
| Level 03 "Moorbrücken" (Sumpf) | fertig |
| Level 04 "Katzensprung" (Ritt) | fertig |
| Level 05 "Wettrennen" (Karts) | fertig |
| Eigene Spielfigur in den Einstellungen | fertig |
| Level 06–25 | offen |

## Level 01 – Wurzelschlucht

Ein 236 m langer Waldpfad auf einem Grat, in fünf Abschnitten. Der Verlauf
steckt in einer `Curve3D`; alle Objekte werden relativ dazu platziert, ein
geänderter Verlauf verschiebt also alles mit.

| Strecke | Abschnitt | Inhalt |
|---|---|---|
| 0–42 m | Waldrand | Anlaufstrecke, erste Kisten, Sumpfkröten für den Drehschlag |
| 42–100 m | Schlucht | Rechtskurve, Bach mit Lücken, Federkiste, Panzerkäfer |
| 100–158 m | Stacheln | Linkskurve, Stachelfelder, Stelzenvögel, TNT-Kette |
| 158–208 m | Baumkronen | Anstieg, schmaler Grat, Sprungfeder, Nitro |
| 208–236 m | Lichtung | Extraleben, Zielportal |

43 Kisten (37 zählen für den Edelstein), 14 Gegner, 82 Früchte, drei
Checkpoints. Wer neben den Pfad fällt, landet in der Absturzzone.

### Gegner

| Gegner | Nur besiegbar durch |
|---|---|
| Sumpfkröte | Drehschlag (der glitschige Rücken lässt Sprünge abrutschen) |
| Stelzenspinne | Slide (der Kamm oben verhindert Draufspringen) |
| Panzerkäfer | Draufspringen (die Panzernaht hält kein Gewicht) |

Der Bauchplatscher wirkt bei allen dreien.

### Kisten

`NORMAL` (1 Frucht) · `FRUCHT_MEHRFACH` (5) · `LEBEN` · `FEDER` (10 Absprünge,
je 1 Frucht) · `SPRUNG` (Sprungfeder, unzerstörbar) · `TNT` (3 s Countdown) ·
`NITRO` (explodiert bei Berührung) · `EISEN` (unzerbrechlich) · `CHECKPOINT`

## Level 02 – Frostgrat

Ein verschneiter Grat über 212 m, der um 14 m zum Gipfel ansteigt.
Eisplatten in den Lücken, Eiszapfenfelder, tief darunter ein gefrorener
See als Kulisse. 35 Kisten, 11 Gegner, drei Rastpunkte.

## Level 03 – Moorbrücken

Ein Bohlenweg durchs Moor, 212 m. Unter dem Weg liegt kein Abgrund,
sondern tödliches Wasser – derselbe Fehltritt endet hier mit einem
Platsch statt im Nichts. Schmale Stege, Wurzelinseln, Schilfgürtel.
35 Kisten, 13 Gegner.

## Level 04 – Katzensprung

Ein Ritt-Level: Der Beuteldachs sitzt auf einer Wildkatze, die von selbst
rennt und dabei von 11 auf 19 m/s beschleunigt. Gelenkt wird nur quer,
gesprungen wie gewohnt; anhalten oder umkehren geht nicht. Steine und
Stämme stehen abwechselnd links, rechts und in der Mitte – es bleibt
immer genau eine Lücke, die Aufgabe ist, sie früh genug zu sehen.
Kisten zerbrechen im Vorbeirennen. Vier Rastplätze auf 320 m.

Die Lücken im Weg sind 5 m breit: ein Sprung trägt bei Anfangstempo
7,1 m. Nach einem Sturz beginnt das Tempo wieder unten, eine breitere
Lücke wäre dort zur Sackgasse geworden.

## Level 05 – Wettrennen

Drei Runden auf einem geschlossenen Rundkurs gegen vier Gegner-Karts.

| Element | Wirkung |
|---|---|
| Schubfeld | sofortiger Schub, liegt auf der Ideallinie |
| Schubkiste | sammelt eine Ladung, □ zündet sie (bis zu drei) |
| Loch | wer nicht springt, dreht sich und verliert Zeit |

Ein Rennen kennt keinen Tod: In ein Loch zu fallen kostet Zeit, kein
Leben. Die Gegner fahren mit unterschiedlichem Können und einem
Gummiband, das nur nach vorn zieht – ein Führender wird nicht gebremst,
sonst wäre der eigene Vorsprung wertlos.

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
virtuellen Touch-Tasten, die am Desktop ausgeblendet bleiben.

## Docker: im Browser spielen, ohne Godot

Das Abbild enthält die fertig gebaute Web-Version und liefert sie über
nginx aus. Auf dem Zielrechner wird nur Docker gebraucht.

```bash
docker run --rm -p 8080:80 ghcr.io/phat-shot/banooka:latest
```

Dann <http://localhost:8080> öffnen.

Das Paket erbt die Sichtbarkeit des Repositories und ist damit vorerst
privat – zum Ziehen ist eine Anmeldung nötig:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u Phat-shot --password-stdin
```

Wer es ohne Anmeldung erreichbar machen will, stellt das Paket unter
*GitHub → Packages → banooka → Package settings* auf öffentlich. Oder aus dem Projektordner heraus
selbst bauen:

```bash
docker compose up -d --build
```

Der Build läuft zweistufig: die erste Stufe lädt Godot samt Web-Templates
und exportiert das Spiel, die zweite enthält nur noch nginx und die
fertigen Dateien. Das WebAssembly wird beim Bauen vorkomprimiert und über
`gzip_static` ausgeliefert – aus rund 34 MB werden etwa 9 MB über die
Leitung. `/gesundheit` liefert einen Health-Check für Orchestrierung.

### Auf den neuesten Stand kommen

`docker compose up -d` allein benutzt weiter das Abbild, das schon lokal
liegt. Deshalb steht in `docker-compose.yml` jetzt `pull_policy: always`;
wer `docker run` benutzt, zieht vorher von Hand:

```bash
docker pull ghcr.io/phat-shot/banooka:latest
```

Welcher Stand tatsächlich ausgeliefert wird, steht unter
<http://localhost:8080/fassung.txt> – die Kennung dort ist der kurze
Commit-Hash. Stimmt sie nicht mit `git log -1 --format=%h` überein, läuft
ein altes Abbild.

**Warum die Spieldaten unter `/spiel/<Baukennung>/` liegen:** Der
Godot-Web-Export schreibt bei jedem Bau dieselben Dateinamen
(`index.pck`, `index.wasm`). Frühere Abbilder haben sie mit `immutable`
und einem Jahr Haltbarkeit ausgeliefert – solche Dateien fragt der
Browser gar nicht mehr nach, und man bekam nach einem Pull weiter das
alte Spiel, im Extremfall eine Fassung ohne Startbildschirm. Ändert sich
dagegen der Pfad bei jedem Bau, muss der Browser neu laden. Die
Einstiegsseite unter `/` ist nur eine Weiterleitung dorthin und wird mit
`no-store` ausgeliefert.

Der Workflow `.github/workflows/docker.yml` baut das Abbild bei jedem
Push nach `main`, veröffentlicht es in der GitHub Container Registry und
startet es anschließend testweise. Geprüft wird dabei auch, dass die
Einstiegsseite auf den Bau *dieses* Commits zeigt und nicht
zwischengespeichert wird – ein alter Stand fällt damit im Bau auf und
nicht erst beim Spielen.

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

| Aktion | Tastatur | Controller | Touch |
|---|---|---|---|
| Laufen | WASD / Pfeiltasten | linker Stick / Steuerkreuz | Joystick links unten |
| Sprung | Leertaste | Kreuz ✕ | Taste ✕ |
| Doppelsprung | Leertaste in der Luft | ✕ in der Luft | ✕ erneut tippen |
| Spin-Attacke | J / Strg | Viereck □ | Taste □ |
| Slide | Umschalt (in Bewegung) | Kreis ○ | Taste ○ |
| Slide-Jump | Umschalt, dann Leertaste | ○, dann ✕ | ○, dann ✕ |
| Bauchplatscher | Umschalt in der Luft | ○ in der Luft | ○ in der Luft |
| Statustafel | Tab | Dreieck △ | Taste △ |

Die Sprunghöhe ist variabel: Taste früh loslassen ergibt einen kurzen Sprung.

Die Belegung folgt einem PlayStation-Controller; Godot kennt dieselben
Tasten als A/B/X/Y, sodass auch ein Xbox- oder generisches Gamepad passt
(dort liegt Sprung auf A, Slide auf B, Spin auf X, Status auf Y).

### Touch-Steuerung

Die vier Tasten liegen als Raute wie die Symboltasten eines Controllers –
△ oben, □ links, ○ rechts, ✕ unten – und tragen dieselben Farben. Ihre
Größe richtet sich nach der Bildschirmdichte: angepeilt sind rund 13 mm
Durchmesser, damit sie auf dem Handy unter dem Daumen liegen und nicht
nach Pixelmaß schrumpfen. Der Joystick zeigt einen blassen Ring an seiner
Ruhestelle und springt beim Berühren unter den Finger.

Die Steuerung erscheint nur auf Geräten mit Touchscreen und blendet sich
aus, sobald jemand zum Controller greift; beim nächsten Antippen ist sie
wieder da.

### Eigene Spielfigur

Unter *Einstellungen* im Startmenü lässt sich statt des Beuteldachses eine
eigene Figur einsetzen. Sie wird beim Start eingepasst: auf Spielergröße
skaliert (1,42 m), waagerecht mittig gestellt und mit den Füßen auf den
Boden gesetzt – egal, in welcher Einheit modelliert wurde. Ein Regler
justiert die Größe zwischen 0,5× und 2×, eine Vorschau zeigt das Ergebnis.

Nur **glTF** (`.glb`, `.gltf`) – andere Formate braucht Godot beim Bauen zu
importieren und kann sie zur Laufzeit nicht lesen. Selbstenthaltendes
`.glb` ist die sichere Wahl; bei `.gltf` liegen Textur- und Binärdateien
daneben und müssen mitkopiert werden.

Zwei Wege in den Ablageordner (der Pfad steht unten im Einstellungsbild):

* *Datei wählen …* öffnet einen Dateidialog und kopiert die Datei hinein
  (nicht im Browser – dort gibt es keinen Dateizugriff).
* Die Datei von Hand nach `<Benutzerdaten>/modelle/` legen.

Weil die Gliedmaßen einer fremden Datei unbekannt sind, wird sie nur als
Ganzes bewegt: Laufwippen, gestreckt in der Luft, flach im Slide. Ist die
Datei kaputt oder verschwunden, erscheint wieder der Beuteldachs.

### Statustafel

△ (bzw. Tab) hält das Spiel an und zeigt eine Übersicht: wo man gerade
ist, Früchte, Leben, Kisten, freigeschaltete Level und die vollständige
Steuerung. Erneutes △, Abbrechen oder ein Tippen ins Bild schließt sie.

## Physikwerte

Alle Werte stammen 1:1 aus `plattformer-demo.html` und sind in
`scenes/player/player.gd` als Konstanten hinterlegt. Sie sind laut
`CLAUDE.md` verbindlich und werden nicht ohne Rückfrage geändert.

## Projektstruktur

```
autoload/GameState.gd      Früchte, Leben, Kisten-Zähler, Checkpoint
autoload/Einstellungen.gd  eigene Spielfigur, bleibt über Sitzungen erhalten
autoload/InputHub.gd       Tastatur, Gamepad und Touch zu einem Eingabezustand
scenes/player/             Player.tscn, player.gd, beuteldachs.gd (Modell)
scenes/camera/             CorridorCamera.tscn
scenes/crates/             Kiste.tscn + kiste.gd (alle neun Arten)
scenes/enemies/            gegner.gd + Sumpfkroete/Stelzenspinne/Panzerkaefer
scenes/fruits/             Frucht.tscn
scenes/hazards/            Wasser.tscn, Stacheln.tscn
scenes/portals/            StartPortal.tscn, ZielPortal.tscn
scenes/props/              Baum, Wurzel, Stein, Gras, Kleinzeug, Waldstreuer
scenes/levels/             level_basis.gd, korridor_level.gd,
                           Level01–Level05.tscn, Testlevel.tscn
scenes/mounts/             katze.gd (Reittier, Level 04)
scenes/vehicles/           kart.gd (Level 05)
scenes/ui/                 HUD.tscn, TouchControls.tscn, statustafel.gd,
                           Splash.tscn, Optionen.tscn (Einstellungen)
scripts/                   angriff, farben, materialbibliothek, level_werkzeuge,
                           pad_symbole (Controller-Zeichen ✕ ○ □ △),
                           modell_lader (eigene glTF-Figur einpassen)
shaders/                   wasser.gdshader
werkzeuge/                 pruefe.sh, Szenen- und Levelprüfung, Webserver
assets/CREDITS.md          Quellen und Lizenzen
ARCHITEKTUR.md             verbindliche Schnittstellen
```

## Rendering

Das Projekt nutzt den Renderer **GL Compatibility**, damit die Web- und
Mobil-Exporte ohne Umstellung funktionieren.
