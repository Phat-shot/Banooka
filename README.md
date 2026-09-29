# Banooka

3D-Korridor-Plattformer in **Godot 4** (GDScript), inspiriert von klassischen
PS1-Korridor-Plattformern. Eigenständiges Projekt ohne fremde Marken,
Charaktere oder Assets.

## Stand

Alle 25 Level und der Portalraum sind gebaut und spielbar. Der Portalraum
gliedert sie in fünf Räume zu je fünf Leveln; ein Raum öffnet, wenn der
vorige abgeschlossen ist.

Danach kam ein Verschönerungsdurchgang in acht Paketen – Level 01, Licht,
Portalraum, Spieler, Kisten, Gegner, Menüs, HUD – auf zwei gemeinsamen
Grundlagen: `scripts/effekte.gd` (Staub, Funken, Kamerawackeln,
Trefferpause) und `scripts/ui_stil.gd` (ein Aussehen für alle Menüs und
Anzeigen). Physik, Hitboxen, Zeiten, Eingabe und Spielstand blieben dabei
unverändert; die wenigen bewussten Ausnahmen (Wurfpunkt der Werfer,
Fruchtbogen, Stämme in Level 01, Startplatz im Portalraum) stehen in
`ARCHITEKTUR.md` unter „Bewusste Abweichungen im Verschönerungsdurchgang".
Was sich an Bild und Kosten getan hat, zeigt das Schaufenster
(siehe „Bildvergleich und Kostenmessung"); die Schnittstellen stehen in
`ARCHITEKTUR.md`.

| Bereich | Status |
|---|---|
| Projektstruktur, Autoloads, Input-Map | fertig |
| Player-Controller (komplettes Move-Set) | fertig |
| Beuteldachs-Modell mit Animationen | fertig |
| Korridor-Kamera (folgt auch Kurven) | fertig |
| HUD + virtuelle Touch-Steuerung | fertig |
| Kisten (13 Arten), Früchte | fertig |
| Gegner (8 Arten) | fertig |
| Wasser, Stacheln, Taktgeber, Portale | fertig |
| Props und prozedurale Texturen | fertig |
| Portalraum mit vier Speicherplätzen | fertig |
| Level 01–25 | fertig |
| Zeitmodus mit Zeitkisten und Zeitrelikten | fertig |
| Eigene Spielfigur in den Einstellungen | fertig |
| Verschönerungsdurchgang (acht Pakete, siehe oben) | fertig |

## Die 25 Level

| Raum | Level |
|---|---|
| 1 · Wurzelwald | 01 Wurzelschlucht (Wald) · 02 Frostgrat (Schnee) · 03 Treibgut (Treibflöße) · 04 Katzensprung (Ritt) · 05 Hauerjagd (Flucht) |
| 2 · Nebelsümpfe | 06 Wettrennen (Karts) · 07 Moorbrücken (Bohlenweg) · 08 Torfstich (Bänder und Pressen) · 09 Sumpfgeysir (Gasfontänen) · 10 Hebewerk (senkrecht, 2D-Abschnitt) |
| 3 · Steinfeste | 11 Steinschlag · 12 Kesselwerk · 13 Pfahlfeste · 14 Wolkensteg · 15 Abendruinen |
| 4 · Rost und Ranken | 16 Kanalgrund · 17 Frostritt (Schiene) · 18 Schwarmpfad (Deckung) · 19 Sturmruinen (Drehscheiben) · 20 Kolbengang (Laserzäune) |
| 5 · Sand und Neon | 21 Sandgrab (Gabelung) · 22 Wolkenjagd (Flug) · 23 Funkenlicht (Dunkellevel) · 24 Neonhöhe (Dächer) · 25 Dächergasse (Hangeln) |

Vier Level laufen nicht über den normalen Controller, sondern kleben auf
der Levelkurve: die beiden Ritt-Level 04 und 05, das Rennen 06 und der
Flug 22.

## Level 01 – Wurzelschlucht

Ein 236 m langer Waldpfad auf einem Grat, in fünf Abschnitten. Der Verlauf
steckt in einer `Curve3D`; alle Objekte werden relativ dazu platziert, ein
geänderter Verlauf verschiebt also alles mit. So ist jedes Korridorlevel
gebaut.

| Strecke | Abschnitt | Inhalt |
|---|---|---|
| 0–42 m | Waldrand | Anlaufstrecke, erste Kisten, Sumpfkröten für den Drehschlag |
| 42–100 m | Schlucht | Rechtskurve, Bach mit Lücken, Federkiste, Panzerkäfer, TNT-Kette |
| 100–158 m | Stacheln | Linkskurve, Stachelfelder, Stelzenspinnen, Nitro |
| 158–208 m | Baumkronen | Anstieg, schmaler Grat, Sprungfeder, Nitro |
| 208–236 m | Lichtung | Extraleben, Zielportal |

45 Kisten, 14 Gegner, drei Checkpoints. Wer neben den Pfad fällt, landet
in der Absturzzone.

**Wahrzeichen.** Die Schluchtwände sind bewachsen: Blattsaum auf der
Kante, Ranken über den Simsen, Wurzeln, Farne und große Blätter am
Wandfuß. An den Abschnittswechseln (42, 100 und 157 m) spannen sich
Wurzeltore hoch über den Weg. Bei 59,5 m stürzt ein Wasserfall die linke
Wand hinab in die Bachlücke, über der TNT-Kette liegt ein umgestürzter
Baumriese von Krone zu Krone, und an vier Stellen bis 158 m fallen
Lichtschächte schräg über die Wandkante. Über den Baumkronen werden die
Wände niedrig und der Blick geht auf ein Meer aus Wipfeln unter dem Grat,
daneben stehen einzelne Baumriesen. Am Ziel rahmt ein Wurzelbogen das
Portal, links daneben steigt der Weltenbaum aus dem Tal, und bewaldete
Hügel schließen den Horizont. Jeder Abschnitt hat sein eigenes Licht: die
Schlucht kühl und dunstig, die Baumkronen hell und golden, die Lichtung
warm.

### Gegner

Acht Tiere bespielen die fünfundzwanzig Level. Die drei aus Level 01
zeigen die Regel: Jeder Gegner ist nur durch **einen** Angriff zu
besiegen, und die Stelle, an der er wirkt, ist hell abgesetzt.

| Gegner | Nur besiegbar durch |
|---|---|
| Sumpfkröte | Drehschlag (der glitschige Rücken lässt Sprünge abrutschen) |
| Stelzenspinne | Slide (der Kamm oben verhindert Draufspringen) |
| Panzerkäfer | Draufspringen (die Panzernaht hält kein Gewicht) |

Der Bauchplatscher wirkt bei allen dreien.

### Kisten

`NORMAL` (1 Frucht) · `FRUCHT_MEHRFACH` (5) · `LEBEN` · `FEDER` (10 Absprünge,
je 1 Frucht) · `SPRUNG` (Sprungfeder, unzerstörbar) · `TNT` (3 s Countdown) ·
`NITRO` (explodiert bei Berührung) · `EISEN` (unzerbrechlich) · `CHECKPOINT` ·
`SCHUTZ` (fängt einen Treffer ab) · `UMRISS` und `AUSLOESER` (das Gerippe
wird fest, wenn sein Auslöser fällt) · `ZEIT` (hält im Zeitmodus die Uhr an)

## Zeitmodus

In den Einstellungen schaltbar. Jedes betretene Level wird dann auf Zeit
gespielt: Oben in der Bildmitte läuft eine Uhr, und jede dritte Holzkiste
ist eine **Zeitkiste** – violett, mit Zifferblatt und Zahl. Wer sie
zerschlägt, hält die Uhr für so viele Sekunden an. Sie zählt und gibt
eine Frucht wie jede Holzkiste, der Kistenzähler bleibt also derselbe.

Drei Stufen hängen an der Richtzeit des Levels: **Saphir** bis zur
Richtzeit, **Gold** bis 85 %, **Platin** bis 72 %. Bestzeit und Stufe
stehen danach am Levelportal im Portalraum.

Ein Tod beendet den Lauf – er setzt ihn nicht zurück. Sonst wäre ein Tod
kurz vor dem Ziel die schnellste Abkürzung.

## Starten

Projektordner in Godot 4.7.2 öffnen und F5 drücken. Die Hauptszene ist
`scenes/ui/Splash.tscn` – Startbildschirm, Speicherplatz wählen,
Portalraum. `scenes/levels/Testlevel.tscn` bleibt als schlichter
Testkorridor für den Controller erhalten, `scenes/levels/Werkstatt.tscn`
zeigt alle Bauteile einzeln.

## Prüfen

```bash
bash werkzeuge/pruefe.sh
```

Läuft auf einer Kopie des Projekts und prüft in vier Stufen: GDScript-Parse-
Fehler; das Laden und Instanziieren jeder Szene (findet auch Fehler in
`_ready()`); die Geometrie **jedes** Levels – ob Kisten und Gegner auf festem
Boden stehen, ob Patrouillen nicht ins Leere laufen, ob die Absturzzone greift;
und zuletzt alles, was nur in Bewegung zu prüfen ist: Krabbeln, Treibflöße,
Hangeln, Deckungsflecken, Dunkellevel, Umrisskisten und den Zeitmodus. Muss
`ERGEBNIS: SAUBER` melden.

`PRUEF_LEVEL=08,09 bash werkzeuge/pruefe.sh` grenzt die Geometrieprüfung auf
einzelne Level ein – der volle Lauf dauert einige Minuten.

Zwei Werkzeuge daneben, die nicht prüfen, sondern **messen** und deshalb
nicht in `pruefe.sh` stecken:

```bash
bash werkzeuge/spieltest.sh /tmp/spieltest 3000   # Bot spielt selbst
bash werkzeuge/lauf.sh res://werkzeuge/Zeittafel.tscn   # Richtzeiten
```

Der Spieltest-Bot geht denselben Weg wie ein Spieler – Startbildschirm,
Portalraum, Level – und legt dabei Bilder ab; `TEST_LEVEL=8,9` grenzt ihn
ein. Er sichert den echten Spielstand vorher und holt ihn danach zurück.
Er spielt allerdings deutlich schlechter als ein Mensch: Er findet keine
Deckung, verpasst Absprünge und stürzt in Lücken. Sein Bericht taugt als
Rauchtest ("kommt das Level überhaupt zustande, tötet es sofort?"), nicht
als Schwierigkeitsurteil.

`Zeittafel` druckt für jedes Level die Richtzeit des Zeitmodus samt ihrer
Herkunft.

### Bildvergleich und Kostenmessung (`werkzeuge/schaufenster.sh`, `foto.sh`, `kontaktbogen.py`)

Jede sichtbare Änderung wird an Bild UND Preis gemessen. Der Preis zählt, weil das Spiel im Browser und auf Mobilgeräten läuft (WebGL2, Compatibility-Renderer). Das Werkzeug dafür ist ein fester Bildersatz, das „Schaufenster“: Splash, Hub und Level 01, immer aus denselben Blickwinkeln.

```
export PATH=~/godot-bin:$PATH
VORHER=HEAD bash werkzeuge/schaufenster.sh /tmp/schau   # Stand von HEAD  -> /tmp/schau/vorher/
bash werkzeuge/schaufenster.sh /tmp/schau               # Arbeitsstand     -> /tmp/schau/jetzt/
SCHAUFENSTER_TEILE=l01 bash werkzeuge/schaufenster.sh /tmp/schau   # nur ein Teil
```

- **Teile:**
  - `splash`: Splash, zwei Aufnahmen im Abstand von 70 Bildern
  - `hub`: verfolger 0, 14, 60
  - `l01`: verfolger 4, 30, 50, 75, 112, 136, 170, 192, 216, 233
  - `l01seite`: seite 50, 170
  - `l01nah`: nah 30
- **Ausgabe je Seite:**
  - `<teil>/*.png` mit den Aufnahmen
  - `<teil>/werte.tsv` mit den Kosten je Bild
  - `werte.tsv` mit allen Teilen zusammen
  - `<teil>.png` als Kontaktbogen

  Sobald beide Seiten da sind, kommen `vergleich_<teil>.png` dazu (vorher | jetzt | Differenz × 4) und die Tabelle „Draw-Calls vorher -> jetzt“.
- **Vergleichbarkeit:** Godot läuft mit `--fixed-fps 30`. Jedes Bild ist damit genau 1/30 s Spielzeit, auf einer Grafikkarte wie unter llvmpipe. FOTO_*-Variablen aus der Shell werden verworfen. Gemessenes Rauschen zwischen zwei gleichen Läufen:
  - Splash und Hub: pixelgleich.
  - Level 01: mittlere Abweichung 0,1–1,0 (Skala 0–255), Draw-Calls ±2. Ursache sind bewegte Gegner.

  Kleinere Unterschiede als diese sind also kein Befund.
- **`VORHER=<ref>`** rendert aus `git archive`, das Arbeitsverzeichnis bleibt unberührt. Werkzeug von heute, Spiel von damals: `foto.gd` und `Foto.tscn` kommen aus dem Arbeitsstand, damit auch alte Stände Kostenwerte liefern.
- **Ohne Bildschirm:** Ohne `DISPLAY` startet `foto.sh` selbst einen unsichtbaren X-Server (`xvfb-run`). Gezeichnet wird dann mit Mesa/llvmpipe, langsam (2–3 Bilder/s), aber pixelgenau. Der ganze Satz dauerte vor der Verschönerung rund 4 min, heute deutlich länger (siehe unten).
- **Kostenzeile je Aufnahme** (`foto.gd`): `draw 2025  obj 2043  prim 859k  vram 94.4 MB  knoten 3555`. Das sind Zählwerte, keine Zeiten; sie sind also zwischen Rechnern vergleichbar. `draw` schließt die Schattenkarten der Sonne ein. Getrennt ausweisen kann der Compatibility-Renderer sie nicht.
  - Gemessen an Level 01 (Stand 612b7de): Ohne Sonnenschatten sind es bei 4 m 1286 statt 2026 Draw-Calls, bei 170 m 480 statt 1027.
  - Jede Fläche kostet in jeder Schattenstufe der Sonne einen Draw-Call. `cast_shadow` aus bei Kleinkram spart deshalb je Objekt so viele Draw-Calls, wie die Sonne Stufen hat – in Level 01 waren es vier, seit der Verschönerung sind es zwei.

  `FOTO_BUDGET_DRAW=N` warnt, wenn ein Bild das Budget überschreitet.
- **Neu in `foto.sh`** (Aufruf wie bisher):
  - `GODOT` wird beachtet.
  - `FOTO_ARGS` reicht weitere Godot-Argumente durch (z. B. `"--fixed-fps 30"`).
  - `FOTO_KOPIE` nimmt eine schon importierte Kopie.
  - `FOTO_ZEITLIMIT` begrenzt die Laufzeit.
  - `FOTO_WERTE` ist die Datei für die Kostentabelle.
  - Skriptfehler aus dem Import werden angezeigt, statt nur als fehlende Bilder aufzufallen.
- **Kontaktbogen einzeln:** `uvx --with pillow python werkzeuge/kontaktbogen.py <ordner>` oder `… --vergleich --diff <vorher> <jetzt> -o out.png`. Die Beschriftung zeigt die Kosten und die Farbwerte `hell` (mittlere Luma 0–255), `warm` (Farbton 330–60°) und `kühl` (180–260°). `warm` und `kühl` sind Anteile aller Pixel in %; gezählt werden nur kräftige (Sättigung ≥ 25 %, Helligkeit ≥ 15 %).

**Vor und nach der Verschönerung** (Draw-Calls je Aufnahme; vorher Stand
612b7de, nachher der zusammengeführte Stand 16227ef):

| Teil | vorher | nachher |
|---|---|---|
| Splash | 214 / 216 | 247 / 249 |
| Hub | 662 / 671 / 654 | 476 / 497 / 496 |
| Level 01, verfolger | 4 m 2025 · 30 m 2005 · 50 m 1912 · 75 m 2151 · 112 m 1717 · 136 m 1559 · 170 m 1027 · 192 m 833 · 216 m 566 · 233 m 302 | 4 m 611 · 30 m 981 · 50 m 892 · 75 m 730 · 112 m 553 · 136 m 649 · 170 m 511 · 192 m 414 · 216 m 323 · 233 m 225 |
| Level 01, seite | 50 m 1026 · 170 m 2916 | 50 m 428 · 170 m 1036 |
| Level 01, nah | 30 m 382 | 30 m 228 |
| VRAM | Level 01 94,4 MB, Hub 59,6 MB, Splash 63,7 MB | Level 01 108,7 MB, Hub 83,8 MB, Splash 79,2 MB |

Level 01 kostet trotz Bewuchs, Wasserfall und Lichtschächten je nach
Stelle 25 bis 70 % weniger: Die Sonne zeichnet nur noch zwei statt vier Schattenstufen,
Kisten, Früchte und Bewuchs werfen keinen oder einen zusammengefassten
Schatten, und Wald wächst nur, wo man hineinschaut. Der Portalraum spart
über Sammelnetze. Der Splash legt zu (Himmel, Lichtfahnen, Glühen); gut
drei Draw-Calls davon kommen aus dem Speicherstand des Messrechners, der
dort „5 geschafft" zeigt. Der Rundgang im Portalraum folgt jetzt dem
Hallenbogen, die Aufnahmen 14 und 60 stehen deshalb etwas anders als
vorher. Der VRAM wächst um 14 bis 24 MB; rund 14 MB davon kostet 2× MSAA
am Rechner (bei 720p).

Level 01 rendert seit der Verschönerung deutlich langsamer: Unter
llvmpipe mit geteilten Kernen brauchte `l01` gut 15 min, mehr als das
Zeitlimit von 900 s je Teil. Für solche Läufe `SCHAUFENSTER_ZEITLIMIT`
anheben (Sekunden je Teil).

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

### Eigene Spielfigur im Browser

„Einstellungen → Figur → Datei wählen …" gibt es auch im Browser. Dort
öffnet die Seite ein Hochladefeld; die gewählte `.glb` wandert in den
Speicher des Browsers und steht danach in der Figurenliste. Sie bleibt
dort, bis die Websitedaten geleert werden, und ist an diesen einen
Browser gebunden – wer sie überall haben will, legt sie stattdessen nach
`assets/modelle/` (siehe `assets/modelle/LIESMICH.md`).

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
Darunter stehen drei Knöpfe: Weiterspielen (vorgewählt), Neu starten (nur
im Level) und Level verlassen (im Portalraum: Zum Hauptmenü); ✕ löst den
gewählten aus.

## Physikwerte

Alle Werte stammen 1:1 aus `plattformer-demo.html` und sind in
`scenes/player/player.gd` als Konstanten hinterlegt. Sie sind laut
`CLAUDE.md` verbindlich und werden nicht ohne Rückfrage geändert.

## Projektstruktur

```
autoload/GameState.gd      Früchte, Leben, Kisten-Zähler, Checkpoint
autoload/Einstellungen.gd  eigene Spielfigur, bleibt über Sitzungen erhalten
autoload/InputHub.gd       Tastatur, Gamepad und Touch zu einem Eingabezustand
autoload/Spielfluss.gd     Speicherplätze, Levelnamen, Szenenwechsel
autoload/Ladeschirm.gd     Ladeschirm über jedem Szenenwechsel
scenes/player/             Player.tscn, player.gd, beuteldachs.gd (Modell)
scenes/camera/             CorridorCamera.tscn
scenes/crates/             Kiste.tscn + kiste.gd (13 Arten), explosion.gd
scenes/enemies/            gegner.gd + Sumpfkroete/Stelzenspinne/Panzerkaefer
scenes/fruits/             Frucht.tscn
scenes/hazards/            Wasser.tscn, Stacheln.tscn
scenes/portals/            StartPortal.tscn, ZielPortal.tscn
scenes/hub/                Hub.tscn, hub.gd, levelportal.gd, wegweiser.gd
scenes/props/              Baum, Wurzel, Stein, Gras, Kleinzeug, Waldstreuer,
                           Horizont, Schluchtsaum, Wasserfall, Lichtschacht
scenes/levels/             level_basis.gd, korridor_level.gd,
                           Level01–Level25.tscn, Testlevel.tscn, Werkstatt.tscn
scenes/mounts/             katze.gd (Reittier, Level 04)
scenes/vehicles/           kart.gd (Level 06)
scenes/ui/                 HUD.tscn, TouchControls.tscn, statustafel.gd,
                           menue_eintrag.gd, Splash.tscn, Optionen.tscn
                           (Einstellungen)
scripts/                   angriff, farben, materialbibliothek, level_werkzeuge,
                           pad_symbole (Controller-Zeichen ✕ ○ □ △),
                           modell_lader (eigene glTF-Figur einpassen),
                           effekte, ui_stil, bildrahmen, bodenschatten,
                           stimmungszone
shaders/                   wasser, himmel, portal_wirbel, gegner_glanz,
                           bildrahmen (.gdshader)
werkzeuge/                 pruefe.sh, Szenen- und Levelprüfung, Spieltest-Bot,
                           Bild- und Messwerkzeuge, Webserver
assets/CREDITS.md          Quellen und Lizenzen
ARCHITEKTUR.md             verbindliche Schnittstellen
```

## Rendering

Das Projekt nutzt den Renderer **GL Compatibility**, damit die Web- und
Mobil-Exporte ohne Umstellung funktionieren.
