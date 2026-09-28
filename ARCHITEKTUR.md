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

Dreizehn Arten, eingestellt über `art`. Neue Arten kommen **ans Ende der
Aufzählung**: `LevelBasis` merkt sich im Bauplan den Zahlenwert, und der
darf sich nicht verschieben.

Die **Zeitkiste** (`Art.ZEIT`, `zeit_wert` = 1 bis 9) gehört zum
Zeitmodus. Sie zählt und gibt eine Frucht wie eine Holzkiste; zusätzlich
hält sie die Uhr `zeit_wert` Sekunden an. Level setzen sie nicht selbst:
`LevelBasis._zeitkisten_setzen()` tauscht im Zeitmodus jede dritte
Holzkiste gegen eine – so steht sie immer auf einem geprüften Platz.

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

## Zeitmodus (`autoload/Zeitlauf.gd`)

In den Einstellungen schaltbar (`Einstellungen.zeitmodus`), gilt dann für
jedes betretene Level.

```gdscript
var aktiv: bool                     # Modus gewählt
var laeuft: bool                    # Uhr läuft im aktuellen Level
var zeit: float                     # verstrichene Zeit
var frost: float                    # Reststandzeit aus Zeitkisten
var richtzeit: float                # Saphirgrenze des Levels

func beginnen(level_nummer: int, richt: float) -> void
func beenden() -> float             # < 0 = es lief kein Lauf
func abbrechen() -> void
func einfrieren(sekunden: float) -> void
func stufe_fuer(gelaufen: float, richt: float) -> Stufe
static func als_text(sekunden: float) -> String
```

Drei Stufen: **Saphir** bis zur Richtzeit, **Gold** bis 85 %, **Platin**
bis 72 %. Die Richtzeit liefert das Level über `LevelBasis.zielzeit()`;
0 heißt „ableiten", und abgeleitet wird auf zwei Arten:

* **Lauflevel:** Streckenlänge ÷ 8,5 m/s × 2,8. Der Faktor ist geschätzt,
  nicht erspielt – wer ein Level durchmisst, trägt die Zahl mit
  `zielzeit()` ein.
* **Ritt-, Flucht- und Rennlevel** (die Figur klebt auf der Kurve, erkannt
  an ihrer Eigenschaft `strecke`): Streckenlänge ÷ 15 m/s × 1,5. Sie
  laufen von selbst und deutlich schneller, und Umwege gibt es dort nicht.

Zwei Level setzen ihre Richtzeit von Hand, weil beide Ableitungen sie
verfehlen: **Level 06** (die Kurve ist eine Runde, gefahren werden drei)
und **Level 22** (gar keine Kurve). Der **Tod beendet den Lauf** – er setzt ihn weder zurück (ein
Tod kurz vor dem Ziel wäre sonst die schnellste Abkürzung) noch lässt er
ihn weiterlaufen.

Gewertet wird in `LevelBasis._zeitlauf_werten()`; die Bestzeit landet
über `Spielfluss.zeit_eintragen()` im Spielstand und erscheint im
Portalraum als dritter Stein über dem Tor, mit der Zeit darunter.

Geprüft von `werkzeuge/Zeitprobe.tscn`.

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
func zeit_eintragen(nummer, gelaufen, stufe) -> bool   # true = Bestzeit
func zeit_von(nummer: int) -> Dictionary   # {"zeit": float, "stufe": int}
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

## Effekte (`scripts/effekte.gd`)

`Effekte` bündelt alle kurzen Spielrückmeldungen: Staub, Funken, Blitz, Kistensplitter, Rauch, Druckwellenring, Lichtsäule, Blitzlicht, Kamerawackeln, Trefferpause und Bildblitz. Dazu kommen einige dauerhafte Bausteine: Bodenfleck, Lauf- und Slidestaub sowie Zündschnurglut. Wie `Leuchtmarker` besteht die Klasse nur aus statischen Funktionen: `Effekte.funken(self, pos, Farben.KISTE_LEBEN, 16, 5.0)`. Die vollständige Schnittstelle steht im Kopfkommentar der Datei.

**Regeln**
- **Farben nie ins Material.** Die Teilchenmaterialien (`Effekte.stoff()`) sind geteilt. Die Farbe jedes Stoßes steckt in `color` des Emitters und kommt als Scheitelfarbe im Shader an.
- **Effekte hängen an `current_scene`**, nie an Kisten oder Früchten. Der `Leuchtmarker` kopiert die Materialien des ganzen Unterbaums der Gruppen „kisten" und „fruechte". Eine eingesammelte Frucht nähme ihre Funken außerdem mit, wenn sie sich freigibt. Ein Szenenwechsel räumt die Effekte von selbst ab.
- **`CPUParticles3D`, nicht `GPUParticles3D`**, aus demselben Grund wie beim `Staubflug`. Jeder Stoß ist `one_shot` und `top_level`, hat keine Physikinterpolation und räumt sich selbst ab: über `finished` und zusätzlich über einen Zeitgeber.
- **Grenzen:** höchstens 24 Stöße gleichzeitig, 8 neue je Bild und 2 Blitzlichter. Wer einen Stoß anfordert, muss `null` als Rückgabe vertragen.
- **`Effekte.staubfarbe` überlebt den Szenenwechsel.** Jedes Level setzt sie deshalb beim Aufbau, auch auf die Vorgabe `Effekte.STAUBFARBE_VORGABE`.
- **`Effekte.reduziert`** halbiert die Mengen und schaltet Wackeln, Trefferpause, Bildblitz und Blitzlicht ab. Vorbelegt ist es nur in Handy-Browsern.
- **Trefferpause:** `Engine.time_scale` wird für höchstens 0,2 s auf 0,05 gesetzt. Im Headless-Betrieb ist sie aus, damit die Messungen der Prüfwerkzeuge stimmen. Für den Zeitmodus ist sie fair, weil die Uhr mit dem verlangsamten Delta zählt.
- **Bildblitz** liegt auf CanvasLayer-Ebene 0, also unter dem HUD (Ebene 1).

**Kameravertrag.** Eine Kamera, die wackeln kann, bietet `func erschuettern(staerke: float) -> void` an. `staerke` ist ein „Trauma"-Wert von 0 bis 1. Die Kamera nimmt das Maximum aus altem und neuem Wert, nicht die Summe. Sie lässt den Wert selbst abklingen (etwa 2 je Sekunde), macht den Ausschlag proportional zu staerke² und setzt ihn in `sofort_ausrichten` auf 0. `Effekte` spricht die Kamera nur per `has_method` an. Abstand und `reduziert` sind dabei schon verrechnet.

Übliche Stärken:

| Ereignis | Stärke |
|---|---|
| Bauchplatscher | 0,45 |
| TNT (mit Position) | 0,7 |
| Schutz verloren | 0,35 |
| Gegner besiegt | 0,2 |
| gewöhnlicher Kistenbruch | kein Wackeln |

**Portalscheibe.** `shaders/portal_wirbel.gdshader` ist für ein QuadMesh von 2r × 2r gebaut. Es arbeitet mit `blend_mix`: Additiv brennt die Scheibe vor hellem Grund zu Weiß aus. `Effekte.wirbelstoff(farbe)` liefert je Portal ein eigenes ShaderMaterial. Das Skript setzt pro Bild nur `puls` (0..1).

**Stolperfallen in Godot 4.7** (gemessen im Prüfstand):
- `CPUParticles3D.emitting` ist von Haus aus `true`. Ohne `emitting = false` vor `add_child` entstehen alle Teilchen, bevor Tempo und Größe gesetzt sind.
- `BILLBOARD_PARTICLES` braucht `billboard_keep_scale = true`, sonst ist jedes Teilchen 1 m groß.
- Bei Weltkoordinaten geht die Drehung des Emitters nicht auf die Teilchen über. Aufgerichtete Ringe brauchen deshalb `local_coords = true`.

**Prüfstand:** `werkzeuge/Effektprobe.tscn` zeigt jeden Effekt an seiner Station und prüft Grenzen, Aufräumen, Kameravertrag und Trefferpause. Headless läuft nur diese Logik. Unter Xvfb mit `EFFEKTPROBE_ZIEL=<Verzeichnis>` und `--fixed-fps 30` entstehen zusätzlich Fotos. Den Aufruf zeigt der Kopfkommentar von `werkzeuge/effektprobe.gd`.

## UI-Stil (`scripts/ui_stil.gd`, `class_name UiStil`)

Eine Stelle für das Aussehen aller Menüs und Anzeigen, im Code gebaut wie
`Materialbibliothek` – ohne `.tres` und ohne Schriftdateien. Farben stehen
in `Farben` im Abschnitt `UI_*` (Gold, Hell, Matt, Kontur, Grund, Nacht,
Treffer, Herz, Silber, Bronze). Für Früchte, Kisten, Warnung und
Edelsteine gelten die Spielfarben, damit ein HUD-Symbol so aussieht wie das
Ding in der Welt.

- **Schriften:** `UiStil.schrift(&"text" | &"fett" | &"zahl" | &"titel" | &"logo" | &"sperr" | &"schwung")`
  – FontVariations der eingebauten Schrift. `&"zahl"` hat gleich breite
  Ziffern, `&"logo"` ist der alte Schriftzug des Startbildschirms.
- **Flächen:** `UiStil.flaeche(art)` / `UiStil.zeichne(auf, feld, art)` mit
  `&"tafel"`, `&"kachel"`, `&"chip"`, `&"knopf"`, `&"knopf_gewaehlt"`, `&"balken"`,
  `&"balken_voll"`, `&"pille"`, `&"band"`, `&"schalter"`, `&"mulde"`. **Geteilt,
  nie verändern.** Feste Abwandlungen über `getoent()`, `gerahmt()` und
  `variante()` (ebenfalls geteilt). Für animierte Werte `eigene()`: Die Kopie
  gehört dem Aufrufer. Kapselformen nur breiter als hoch – ein Quadrat mit
  voller Rundung zeigt in StyleBoxFlat eine Naht, Kreise zeichnet
  `fassung()`.
- **Text:** `UiStil.text(auf, pos, inhalt, groesse, farbe, art, kontur, ausrichtung, breite)`
  zeichnet mit Kontur (`Farben.UI_KONTUR`) und weichem Schatten. Ohne
  `breite` ist `pos.x` der Anker für links, Mitte oder rechts. Dazu
  `absatz()`, `textbreite()`, `passend()` (Schriftgröße, die in eine Breite
  passt) und `kuerzen()` (mit „…").
- **Theme:** `theme = UiStil.thema()` an **jeder** UI-Wurzel selbst setzen.
  Ein CanvasLayer unterbricht die Vererbung, deshalb reicht es nicht, das
  Theme einmal an der Wurzel des Baums zu setzen.
- **Symbole:** `frucht()`, `herz()`, `kiste()`, `edelstein()`, `raute()`,
  `fassung()`, `balken()`, `verlauf()`, `vignette()`, `radialverlauf()`.
- **Bewegung:** `pop()`, `einblenden()`, `ausblenden()`, `einschweben()`,
  `ausschweben()`, `zaehle_hoch()` und `vollenden()` liefern Tweens. Pro
  Knoten und Kanal läuft immer nur einer; ein neuer bricht den alten ab.
  Das beseitigt die Wettläufe, bei denen ein altes Ausblenden einen gerade
  gezeigten Knoten wieder versteckte. Für `_process` gibt es `annaehern()`
  und `federkurve()`.
- **Blende:** `UiStil.Blende` ist ein Vollbild-ColorRect für Übergänge mit
  `zu()`, `auf()`, `blitz(farbe, dauer, halten)`, `iris_zu(mitte)` und
  `iris_auf(mitte)`. Jede Oberfläche (HUD, Startbildschirm, Ladeschirm) legt
  sich ihre eigene an. Die Blende läuft auch bei angehaltenem Spiel und ist
  unsichtbar, solange sie nichts deckt. Die Iris ist ein einfacher
  canvas_item-Shader und läuft auch auf WebGL2.

**Renderer:** Das Projekt läuft auf `gl_compatibility` (Web-Export).
Keine `SCREEN_TEXTURE`/`DEPTH_TEXTURE`, keine Compute-Shader, kein
SDFGI oder Volumetric Fog.
