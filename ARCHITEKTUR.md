# Architektur und Schnittstellen

Verbindliche Absprachen für alle Objekte im Spiel. Wer neue Szenen baut,
hält sich exakt an diese Schnittstellen – nur so passen die Teile zusammen.

## Grundregeln

1. **Keine fremden Assets außer CC0.** Meshes und Texturen werden
   prozedural im Code erzeugt (Godot-Primitive, `SurfaceTool`, `ArrayMesh`,
   Rauschtexturen). Die wenigen CC0-Modelle (Deko, drei Gegner) stehen samt
   ihren Änderungen in `assets/CREDITS.md`.
2. **Materialien immer über `Materialbibliothek`** (`scripts/materialbibliothek.gd`)
   beziehen, Farben über `Farben` (`scripts/farben.gd`). Rückgaben werden
   geteilt – nie verändern, bei Bedarf `.duplicate()`.
3. **Szenen sind schlank:** `.tscn` enthält nur Wurzelknoten, Kollisionsformen
   und das Skript. Die Optik baut das Skript in `_ready()` auf. Das vermeidet
   Formatfehler in handgeschriebenen `.tscn`-Dateien.
4. **Deutsch** für Kommentare, Bezeichner und UI-Texte.
5. Nach jeder Änderung `bash werkzeuge/pruefe.sh` – muss `SAUBER` melden.

### Bewusste Abweichungen im Verschönerungsdurchgang

Physik, Hitboxen und Kollision sollten dabei unverändert bleiben. An diesen
Stellen hat sich das Spiel trotzdem geändert, jeweils mit Absicht:

- **Werfer** (Level 11, 12, 13, 15, 16): Das Modell schaut jetzt richtig
  zum Spieler (`_blickwinkel`), und das Geschoss startet an seiner Hand.
  Der Abwurfpunkt liegt dadurch bis gut 1 m anders als vorher, als die
  Hand oft hinter dem Rücken saß; Ziel, Tempo und Vorhalt sind gleich.
- **Früchte** aus Kisten, Gegnern und den Ballons in Level 22: Der
  Wurfbogen endet auf Abwurfhöhe statt nach fester Flugzeit – rund 0,9 m
  höher und 0,25 m näher an der Quelle, nie mehr halb im Boden.
- **Level 01:** Der Kronenwald ersetzt die Rahmenbäume; deren 27
  Stammkollisionen entfallen. Neben dem Grat (158–208 m) konnte man vorher
  auf einem Stamm unterhalb der Kante stranden, ohne Weg zurück.
- **Portalraum:** Die Figur startet vor dem Raum, um den es gerade geht
  (siehe „Startplatz"), nicht mehr in der Hallenmitte. Die Kollision ist
  unverändert; die Obelisken in Raum 5 stecken ohne eigenen Körper in der
  Rückwand.

## Kollisionsebenen

| Ebene | Wert | Belegung |
|---|---|---|
| 1 | 1 | Welt: Boden, Plattformen, Kisten, Felsen, feste Props |
| 2 | 2 | Spieler (`CharacterBody3D`) |
| 3 | 4 | Gegner-Körper |
| 4 | 8 | Sichtsperre (`LevelWerkzeuge.SICHTSPERRE`): fragt nur der Kamerastrahl ab – Deko, die den Blick verstellen kann, ohne den Weg zu sperren (Torbögen, Wurzeltore) |

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

### Optik (`player.gd`, Abschnitt „Optik")

Alle Rückmeldungen fürs Auge hängen an wenigen Haken, die den Zustand der
Figur nur lesen – Tempo, Hitbox und Zeitgeber schreiben sie nie.

| Anlass | Rückmeldung |
|---|---|
| Absprung, Doppelsprung | Strecken (`SpielerModell.stoss()`), Staub; beim Doppelsprung ein Luftring |
| Landung | Stauchen nach Wucht, ab einem echten Sprung Staub |
| Drehschlag am Boden | Staub, der sich mitdreht |
| Bauchplatscher | Ring genau im Wirkradius (2 m), Staub, Wackeln 0,45 |
| Schutzbruch | Wackeln 0,35, Trefferpause, roter Bildblitz |
| Tod | dunkler Schleier über dem Schnitt, danach Auftauchen am Checkpoint |

Die Bauchplatscher-Optik läuft vor der Kistenschleife, damit der Ring nie
an der Grenze von 8 Effekten je Bild scheitert. Die Trefferpause
(`Effekte.trefferpause`) löst die Figur nur beim Bauchplatscher mit
Kistentreffer und beim Schutzbruch aus. Als Treffer zählt nur eine Kiste,
die dabei wirklich zerbricht (sie gibt sich frei): Eisen- und
Sprungkisten, ein Umriss, der noch nicht da ist, und schon glimmendes TNT
halten das Bild nicht an.

Bodenfleck, Lauf- und Slidestaub und das Auftauchen bekommt nur die Figur
zu Fuß (`_mit_bodeneffekten()`). Reiter, Rennfahrer und Flieger werden
getragen und führen ihr Modell selbst; eine Unterklasse, die wieder läuft,
überschreibt die Methode.

### Bodenschatten (`scripts/bodenschatten.gd`, `class_name Bodenschatten`)

Ein weicher Fleck genau unter der Figur – die klassische Landehilfe, denn
der schräge Sonnenschatten zeigt nicht, über welcher Kante man steht.

- Ein Strahl je Bild trifft nur Ebene 1 und keine Areas, also nie Wasser
  oder Todeszonen.
- Mit der Höhe wird der Fleck kleiner und blasser; am Boden bleibt er als
  Kontaktschatten.
- `staerke` (0..1) blendet ihn aus; die Figur koppelt sie an die
  Modellgröße (Portal, Auftauchen).
- Das Material gehört dem Fleck (`Effekte.blobschatten`). Er trägt ein
  eigenes, satteres Scheibenbild – die Vorgabe war auf dem dunklen
  Waldweg nicht zu sehen.

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

**Netz und Schatten.** Das Netz hängt nur an der Art: Es wird einmal je
Art gebaut und von allen Kisten geteilt (statische Zwischenspeicher,
überleben Szenenwechsel). Die Materialien setzt jede Kiste selbst als
Flächenmaterial. Die Reihenfolge der Flächen bleibt Holz, Rahmen, Metall,
Akzent (Level 25 streicht Fläche 0 und 1 um); leere Gruppen fallen weg,
welche Rolle auf welcher Fläche liegt, steht in `_korpus_rollen`. Den
Schatten wirft der **Schattenriss**: dieselbe Geometrie in EINER Fläche,
`SHADOWS_ONLY`, ohne eigenes Material (der `Leuchtmarker` lässt ihn
deshalb in Ruhe). Der Korpus selbst wirft keinen Schatten, denn jede
Fläche kostet in jeder Schattenstufe einen Zeichenaufruf.

**Bruch.** `Effekte.splitter` mit dem Material, das der Korpus GERADE
trägt (`_bruchstoff()`): im Dunkellevel die Leuchtkopie, in Level 25 der
Nitroanstrich. Dazu Staub, Blitz und ein Farbakzent je Art: Checkpoint =
Lichtsäule + Ring, Leben/Schutz/Mehrfachfrucht/Zeit = Funken in
Kistenfarbe, Auslöser = Ring mit 3 m. TNT und Nitro wackeln die Kamera mit
0,7 (nach Abstand).

**Federn und Zünden** sind reine Optik auf `_modell`, die Kollision bleibt:
Sprung-, Feder- und TNT-Kiste stauchen beim Absprung zum Boden hin. TNT
glimmt ab dem Zünden an der Zündschnur (`Effekte.dauerfunken`, erst beim
Zünden angelegt) und glüht im Sekundentakt auf – auf einer eigenen
Materialkopie, das geteilte TNT-Holz bleibt unberührt.

### Explosion (`scenes/crates/explosion.gd`, `class_name Explosion`)

```gdscript
static func erzeugen(elternteil, pos, wirkradius := 3.0, ton := Farben.WARNUNG)
static func vorwaermen(bei: Node)   # einmal je Szene
```

Druckwelle mit Fresnel-Shader (nur der Rand leuchtet, additiv), dazu Glut,
Feuerball, ein Bodenring genau im Wirkradius, Rauch und
`Effekte.blitzlicht` (gedeckelt). Keine Materialien aus der
`Materialbibliothek` je Funke. `vorwaermen()` zeichnet den Shader einmal
unsichtbar vor der Kamera; TNT- und Nitrokisten rufen es selbst auf.

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

**Blickrichtung.** Level drehen jeden Gegner auf den Korridor
(`g.rotation.y = LevelWerkzeuge.drehung(...)`). Weltrichtungen
(Patrouillenachse, Weg zum Spieler) gehen deshalb immer über
`_blickwinkel(d)` in die Drehung des Modells; es zieht die Korridordrehung
ab. Alle Arten drehen über `_blick_ausrichten()` (die Gletscherkrabbe mit
eigener Fassung, sie läuft seitwärts, +X voran), der Werfer über
`_zum_spieler_drehen()`. Wer den Weltwinkel direkt ins Modell schreibt,
lässt den Gegner in Kurven schräg laufen.

**Mitgelieferte Modelle** (Kröte, Spinne, Käfer; `fremdmodell()`) hängen
unter `fremdhalter`: Stauchen und Wippen gehen auf den Halter, die
Einpassung bleibt am Modell. Oberflächen stellt
`Fremdmodelle.gegner(bezeichnung, ziel_groesse, nach_hoehe, drehung, farben, stoff)`
je glTF-Materialname ein (`rauheit`, `glanz`, `leuchten`, `farbe`); ohne
Angabe bleibt alles matt wie Laub und Fels. `_clip(wunsch, blende,
tempo_faktor, schleife)` spielt Clips nach Wortstamm („idle", „jump",
„walk", „attack", „death"); Dauerschleifen starten versetzt und laufen im
Eigentempo (±8 %). `_koerper_halten(clip)` nimmt den Körperanstieg aus
Sprung- und Todesclip heraus: Die Höhe führt das Skript, und an ihr hängt
die Trefferzone.

**Zeichnung auf Modellen** (ZEICHENSPRACHE, in `_zeichen_am_fremdmodell()`):
- `_bemalung(netz, flaeche, auswahl, abstand)` löst Dreiecke einer Fläche
  heraus und färbt sie um (Käfer: helle Naht in `farbe_naht`, Warnflecken
  in `farbe_streifen`). Die Dreiecke rücken entlang der je Ort gemittelten
  Normalen nach außen, sonst klaffen sie auf flach schattierten Modellen
  auseinander.
- `_tupfen(netz, flaeche, flecken, farbe, abstand)` legt runde Scheiben auf
  die Oberseite, für Netze mit zu groben Dreiecken (Kröte, `farbe_flecken`).
- `_an_knochen(figur, knochen, teil, lage)` hängt ein Teil über die
  Bindepose an einen Knochen (Stachelkamm der Spinne, Augenglanz der Kröte).

Bemalung und Tupfen tragen Knochengewichte und gehen in jedem Clip mit.
Beide werden je Farbsatz einmal gebaut (statischer Zwischenspeicher);
`_neu_faerben()` baut beim Umfärben neu.

**Overlay** `shaders/gegner_glanz.gdshader`: Jeder Gegner hat ein eigenes
`ShaderMaterial` als `material_overlay`, die geteilten Materialien darunter
bleiben unberührt. Es trägt einen Randsaum, den nur direkte Lichter
beleuchten (kein Umgebungslicht, kein Nebel), und den warmweißen
Trefferblitz (`blitz` 1 → 0). Netze mit dem Meta `ohne_glanz` (Zeichnung,
Kamm) bekommen es erst beim Treffer, Netze mit `kein_blitz` nie (Podest des
Werfers).

**Abstandsstufen:** `_nach_abstand()` prüft alle 0,25 s mit 4 m Hysterese
und setzt nur beim Wechsel: Clips bis 38 m (`ANIM_WEITE`), Overlay bis
34 m (`GLANZ_WEITE`), Modellschatten bis 34 m (`SCHATTEN_WEITE`).

**Besiegen.** `besiegen()` ruft `_todesstart(art)` (je Gegner und Angriff
ein eigener Tod) und `_treffer_zeigen()`; danach läuft je Bild
`_todesanimation()`, zum Schluss `_verpuffen()`.
- `_treffer_zeigen()`: Blitz, 0,07 s Starre mit Aufblähen auf 1,18,
  `Effekte.aufblitzen` und `funken` in `_trefferfarbe()`, `erschuettern(0.2)`,
  `trefferpause(0.05)`, der Klang mit `_klanghoehe()`. Der Saum erlischt in
  0,25 s.
- `_verpuffen()`: 0,15 s vor dem Ende schrumpft der Gegner selbst (nicht
  `modell`) in ein Rauchwölkchen in der Körpermitte, nie im Boden.
- `TODES_DAUER` bleibt 1,0 s, dann `queue_free`. `besiegt` und die
  Trefferzone sind wie bisher sofort aus.

Weggeschleuderte Gegner fliegen über `_flugschritt()`: Ein Strahl auf
Ebene 1 lässt sie an Wänden abprallen und am Boden einmal nachhopsen,
danach bleiben sie liegen; über einem Abgrund fallen sie weiter.
`_taumeln()` dreht um die Körpermitte `_todes_mitte` und legt den Gegner
flach auf `_liege_hoehe`; beide Werte setzt der Gegner in `_init()`.

| Gegner | Angriff | Tod |
|---|---|---|
| Panzerkäfer | Draufspringen, Bauchplatscher | knackt: helle Scherben, Ring |
| Sumpfkröte | Drehschlag | fliegt, bleibt auf dem Rücken liegen |
| Sumpfkröte | Bauchplatscher | wird platt |
| Stelzenspinne | Slide | wird weggefegt |
| Stelzenspinne | Bauchplatscher | wird platt |

**Prüfung** (`werkzeuge/level_check.gd`, jedes Level in `pruefe.sh`):
- „Gegnerblick": Jede Art wird über ihren eigenen Weg gemessen, Blick gleich
  Laufrichtung. Der Schwarm zählt als „ohne Blickrichtung".
- „Gegnerleben": Jedes Modell mit Clips spielt einen. Je Art wird einer
  besiegt und muss nach `TODES_DAUER` + 0,5 s verschwunden sein.

## Früchte (`scenes/fruits/frucht.gd`, `class_name Frucht`)

```gdscript
static func streuen(elternteil: Node, pos: Vector3, anzahl := 1) -> void
```

Früchte fliegen ab 2,6 m Abstand zum Spieler und zählen über
`GameState.frucht_einsammeln(1)`.

Alle Früchte teilen EIN Netz mit EINER Fläche (Beere, Stiel, Blätter;
Farbe aus Scheitelfarben) und EIN Material. Das Eigenleuchten liegt über
eine Zwei-Pixel-Maske (`EMISSION_OP_MULTIPLY`) nur auf der Beere. Die
Frucht wirft keinen Schatten: ein Zeichenaufruf je Frucht statt bis zu
zehn. Beim Einsammeln verlässt sie sofort Gruppe und Trefferzone, ploppt
0,13 s und gibt sich dann frei; Funken und Blitz hängen an der Szene. Aus
einer Kiste geschleudert, endet der Wurfbogen auf Abwurfhöhe.

## Spielstand (`autoload/GameState.gd`)

```gdscript
func level_starten(start_position: Vector3, kisten_im_level := 0)
func frucht_einsammeln(anzahl := 1)
func kiste_zerbrochen()
func setze_checkpoint(pos: Vector3)
func leben_verlieren()
func zeige_nachricht(text: String, dauer := 1.8)
func zeige_banner(text: String, farbe := Farben.UI_GOLD, dauer := 2.0)
```

`zeige_nachricht` meldet über das Signal `nachricht(text, dauer)` – es
behält seine zwei Parameter. `zeige_banner` hat ein eigenes Signal
`banner(text, farbe, dauer)`: das große schräge Band im HUD, nur für
seltene Momente (Extraleben, alle Kisten, Game Over).

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

### Levelnamen und Auswertung

```gdscript
const LEVEL_NAMEN: Array[String]               # die 25 Namen
func level_name(nummer: int) -> String         # "Wurzelschlucht"
func level_kopfzeile(nummer: int) -> String    # "LEVEL 01 · WURZELWALD"
func level_abschliessen(alle_kisten: bool, ohne_tod := false) -> void
signal level_abgeschlossen(daten: Dictionary)  # Auswertung, Felder im Kopfkommentar
signal zeit_gewertet(daten: Dictionary)        # {"nummer", "zeit", "stufe", "bestzeit"}
var titelkarte_faellig: bool                   # nur zum_level() setzt sie
```

Maßgeblich für die Namen ist `LEVEL_NAMEN`; wer einen braucht, fragt
`level_name()`. `zum_level()` übergibt dem Ladeschirm weiter „Level 01"
als Titel, Namen und Kopfzeile holt sich der Ladeschirm selbst.

`level_abschliessen()` (vom Zielportal) trägt das Level sofort in
`geschafft` ein, gespeichert wird aber erst beim Betreten des Portalraums.
Deshalb lässt sich die Statustafel während der Auswertung am Ziel nicht
öffnen: „Neu starten" führte sonst an diesem Speichern vorbei ins Level.

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

Die Touch-Steuerung (`scenes/ui/touch_controls.gd`, Gruppe
`touchsteuerung`) meldet ausschließlich über `touch_*()` hierher; ihre
Tasten liegen als Raute wie die Symboltasten eines Controllers, ihre Größe
folgt der Bildschirmdichte (`DisplayServer.screen_get_dpi()`, Ziel rund
13 mm Durchmesser). Zeichen und Farben liefert `scripts/pad_symbole.gd`
(`class_name PadSymbole`) – eine Stelle für Touch-Tasten und Statustafel.
Über die Gruppe fragt die Rennanzeige, ob die Daumentasten im Bild liegen;
dann steht ihr Tacho unten in der Mitte statt unter den Tasten.

Die Statustafel (`scenes/ui/statustafel.gd`, `class_name Statustafel`)
erzeugt der HUD selbst; sie hält den Baum an (`get_tree().paused`) und
sperrt so lange die Touch-Steuerung bis auf die Statustaste (Signal
`umgeschaltet(offen)`). Alles, was während der Pause bedienbar bleiben
muss, läuft auf `PROCESS_MODE_ALWAYS` – InputHub, Touch-Steuerung, Tafel
und ihre Knöpfe.

- **Knöpfe** (`MenueEintrag`): Weiterspielen (vorgewählt), Neu starten
  (nur im Level), Level verlassen (im Portalraum: Zum Hauptmenü).
  Bestätigen (Enter/✕) löst den **gewählten** Knopf aus.
- **Fortsetzen:** Das Spiel läuft erst am Ende des Bildes weiter, damit der
  ✕-Druck nicht noch als Sprung zählt.
- **Inhalt:** Die Legende misst ihre Zeilen, lange Erklärungen brechen um;
  die Tastenhinweise folgen der Eingabeart.
- **Schnittstelle:** `setzen(an)`, `umschalten()`, Signal `umgeschaltet(offen)`.
- **Gesperrt** bleibt sie, solange ein Knoten in der Gruppe `auswertung`
  (Auswertung am Ziel) oder `uebergang` (ein Levelportal saugt die Figur
  ein) steht.

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

Der Controller kennt nur diese Methoden; die letzten beiden sind reine
Anzeige:

```gdscript
func aktualisiere(delta, tempo: float, luft: bool, slide: float, spin: float)
func setze_blick(winkel: float)
func sichtbarkeit(sichtbar: bool)
func stoss(wert: float)        # > 0 stauchen (Landung), < 0 strecken (Absprung)
func kneifen(dauer := 0.3)     # Augen zukneifen (nur Beuteldachs)
```

`_baue()` erzeugt die Geometrie, `_animiere()` bewegt sie pro Frame.

`stoss()` stößt eine gedämpfte Feder auf dem Knoten `Teile` an. Dessen
Ursprung liegt auf Fußhöhe, die Füße bleiben also am Boden. Der Wert wird
gesetzt, nicht addiert. Die Feder beißt sich weder mit dem Slide-Stauch am
Rumpf noch mit dem Halter einer eigenen Figur noch mit dem Portal-Tween auf
dem Modellknoten; Hitbox und Kollision bleiben unberührt.

Der Spin-Ring ist ein eigener Shader (zwei Schlieren mit heller
Vorderkante, ohne Bild- und Tiefentextur); ausgeblendet ist er
`visible = false` und kostet keinen Draw-Call. Der Beuteldachs blinzelt in
unregelmäßigem Takt.

## Kamera (`scripts/corridor_camera.gd`, `class_name KorridorKamera`)

Ohne `kurve_pfad` gerader Korridor Richtung -Z. Mit einem `Path3D` in
`kurve_pfad` fährt die Kamera auf der Kurve hinter dem Spieler her und
folgt damit auch Biegungen im Level.

- **Wackeln:** `erschuettern(staerke)` nach dem Kameravertrag (siehe
  Effekte). Nur Nicken und Rollen, kein Gieren: Die Steuerung ist
  kamerarelativ und soll nicht mitwackeln. Gewackelt wird nur in Bildern,
  in denen `look_at` die Basis neu gesetzt hat, so sammelt sich nichts an.
  Portalraum- und Flugkamera (`folge_kamera.gd`, `flugkamera.gd`) nutzen
  dieselbe `KorridorKamera.wackelbasis()`; die Flugkamera glättet dabei aus
  einer ungewackelten Lage.
- **Sichtfeld:** weitet sich mit dem gemessenen Tempo um bis zu 3° zwischen
  9 und 15 m/s, im Slide kommen 2° dazu, im Stand bleibt es neutral. Ein
  von außen gesetztes `fov` gilt als neue Grundlage.
- **Breite Bildschirme:** waagerecht höchstens 100°
  (`sichtfeld_begrenzt()`), auch in der Portalraum-Kamera. Bei 16:9 ändert
  sich nichts.
- **Höhe:** folgt bildratenunabhängig mit `1 - exp(-hoehe_folge * delta)`.
- **Levelstart:** Am Kurvenanfang fehlt der Abstand nach hinten. Der
  Blickpunkt rückt dann quadratisch heran (`START_HERANHOLEN`, mindestens
  1,5 m voraus); vorher lag die Figur bei Strecke 2 ganz unter dem
  Bildrand. Auf Rundkursen wie Level 06 entfällt das.

## Level (`scenes/levels/level_basis.gd`, `class_name LevelBasis`)

Ein Level erbt von `LevelBasis` und baut seinen Inhalt in `_baue()` auf –
oder, wenn `_bauschritte()` eine Liste liefert, Schritt für Schritt mit
einem freigegebenen Bild dazwischen, damit der Ladeschirm lebendig bleibt.
Die Basisklasse legt die Knoten `Geometrie`, `Objekte` und `Deko` an,
hängt die Kamera an den Verlauf, setzt den Spieler ans Startportal,
zählt die Kisten und verbindet das Signal `level_geschafft`. Steht alles,
sendet sie `aufbau_fertig`.

- **Vor dem Aufbau** setzt die Basis `Effekte.staubfarbe` auf
  `Effekte.STAUBFARBE_VORGABE` (Waldweg); wer eine eigene Farbe will,
  setzt sie in `_baue()` bzw. einem Bauschritt. Jedes Lauflevel, dessen
  Boden kein Waldweg ist, tut das in `_boden_bauen()` (Schnee, Bohlen,
  Schlick, Stein, Blech, Sand, Dächer). Der Staub ist unbeleuchtet: In
  dunklen Leveln bleibt seine Farbe dunkel, sonst glimmt er auf.
- **Nach dem Ausrichten der Kamera** ruft sie `Effekte.vorwaermen(self)`,
  solange der Ladeschirm noch steht. Explosion und Lichtsäule des
  Zielportals wärmen ihre Shader selbst vor.
- Das Wackeln beim Bauchplatscher und den Bildblitz beim Tod löst die
  Figur selbst aus; Level müssen dafür nichts verbinden.

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
static func schluchtwand(elternteil, kurve, abschnitte, material,
        optionen := {}) -> Node3D
```

`abschnitte` ist eine Liste `{"von", "bis", "breite", "breite_ende"}`.
Lücken zwischen den Abschnitten sind die Sprungpassagen. Level 01 hält
diese Liste in `ABSCHNITTE` als einzige Quelle und leitet daraus
`_breite_bei()`, `_rand_bei()` und `_weg_von_der_kante()` ab – so kann
kein Objekt neben dem Weg oder auf einer Abbruchkante landen.

Godot zeichnet Dreiecke als Vorderseite, wenn ihre Punkte aus
Blickrichtung **im Uhrzeigersinn** liegen (empirisch bestimmt).

**Schluchtwand.** Blöcke ohne Kollision (begrenzt wird mit `leitwand()`),
`abschnitte`: `{"von", "bis", "abstand", "hoehe"}`. Freiwillige Optionen,
ohne Angabe bleibt alles wie vorher:

| Option | Wirkung |
|---|---|
| `welt_projektion` | Textur in Weltkoordinaten statt je Block: Die Gesteinsschichten laufen durch die ganze Wand |
| `welt_kachel` | Kachelung dazu je Weltachse (1/m, `Vector3`); ohne Angabe die des Materials |
| `helligkeit` | `Vector2(unten, oben)` für den Farbverlauf der Wand. Ein Eintrag in `abschnitte` darf ein eigenes `"helligkeit"` tragen (etwa für niedrige Wände in praller Sonne) |
| `kronen_merken` | legt je Wandsäule Lagen und Krone als Metadatum `"kronen"` an der Wand ab – für Bewuchs, der der Wand folgt (`Schluchtsaum`, `Wasserfall`) |

**Stimmungszone** (`scripts/stimmungszone.gd`) ändert Nebel und
Umgebungslicht, solange der Spieler drinsteht; es regelt immer nur die
zuletzt betretene Zone. Absolut über `nebelfarbe`, `nebeldichte`,
`umgebungslicht`, `umgebungsfarbe` – oder **relativ zur Grundstimmung**
der Szene, dann passt der Abschnitt zu jedem Grundlicht: `nebel_faktor`
(Vielfaches der Dichte), `licht_faktor` (Vielfaches des Umgebungslichts),
`farbanteil` (wie weit die Farben zur Zonenfarbe gehen, 0..1). Im
Tiefennebel (`FOG_MODE_DEPTH`) ist `fog_density` die größte Deckkraft;
über 1 kippt die Farbe über den Nebel hinaus. Dort verkürzt
`nebel_faktor` deshalb die Nebelstrecke,
`fog_depth_end = beginn + (ende - beginn) / faktor`; die Deckkraft bleibt,
wie das Level sie gestimmt hat, und wird auf 1 begrenzt.

## Props (`scenes/props/`)

`Baum` (LAUBBAUM/NADELBAUM/TOTHOLZ), `Wurzel`, `Stein`, `Grasfeld`
(MultiMesh + Wind-Vertexshader, ein Zeichenaufruf), `Kleinzeug`
(FARN/PILZ/BUSCH/BLUME), `Waldstreuer`, `Horizont`. Jedes hat `saat` für
reproduzierbaren Zufall; Bäume, Wurzeln und Steine haben Kollision
auf Ebene 1, Gras und Kleinzeug nicht.

Freiwillige Schalter, ohne Angabe bleibt alles wie vorher:
- `Baum`: `hoechsthoehe` (Obergrenze für `hoehe`, Vorgabe 14 m – für
  Baumriesen anheben), `eigenbau` (selbst bauen statt Kenney-Modell),
  `kronenfuelle` (mehr, kleinere Blattballen; über 1 wird die Krone
  verschmolzen gebaut).
- `Kleinzeug`: `eigenbau` – das Kenney-Paket hat keinen Farn.
- `Horizont`: `kronen` (bewaldete Kuppen statt kahler Zacken), `nur_nah`
  (nur die nahe Kette).

### Bewuchs und Wahrzeichen (Level 01)

Ohne Schatten und ohne Kollision (das Wurzeltor hat nur eine Sichtsperre);
Blatt- und Blütennetze werden vor dem Tangentenbau verschmolzen
(`index()`).

- `Schluchtsaum.bauen(eltern, kurve, kronen, optionen)` – Bewuchs an einer
  Schluchtwand mit `kronen_merken`:
  `var wand := LevelWerkzeuge.schluchtwand(..., {"kronen_merken": true})`,
  dann `Schluchtsaum.bauen(deko, verlauf, wand.get_meta("kronen"), {...})`.
  Blattsaum auf der Krone, Ranken (sie legen sich über Simse, enden über
  Überhängen und hängen nie unter 1,3 m), Wurzeln, Luftwurzelvorhänge,
  Farne und Großblätter am Wandfuß. In Stücke zu 30 m je Seite geschnitten,
  je Stück bis zu drei Netze (Laub, Wurzelholz, Blüten). Optionen `saat`,
  `laubfarbe`, `saum`, `ranken`, `wurzeln`, `vorhaenge`, `simse`, `fuss`,
  `blueten` und `helle_blueten` (auch weiße und gelbe Blüten; ohne sie
  blüht es nur gedeckt und nur in Farnen, nie an Ranken). Ein
  Säuleneintrag in `kronen` darf `"weg_rand"` tragen: den Querabstand, bis
  zu dem die Pflanzen am Wandfuß höchstens reichen (ohne: einen Meter vor
  der Wand).
- `Schluchtsaum.wurzeltor(eltern, kurve, strecke, abstand, saat, fuss := 3.2, scheitel := 9.2)`
  – Wurzelbogen von Wand zu Wand, Scheitel hoch über Doppelsprung und
  Kamera, mit Sichtkörpern auf der Sichtsperre wie `LevelWerkzeuge.torbogen`.
  Oberhalb von 6 m umfassen die Sichtkörper die ganzen Stränge (2,7 m
  Querschnitt), nicht nur die Bogenlinie. Freie Ranken hängen am Tor
  keine: Die Kamera (6 m über dem Weg, im Doppelsprung 8,4 m) fuhr durch
  sie hindurch.
- `Schluchtsaum.baumstamm(eltern, a, b, dicke, tiefste, saat)` –
  umgestürzter Stamm von Krone zu Krone; Ranken samt Blättern nie tiefer
  als `tiefste` (Welt-Y). Level 01 gibt Weghöhe + `Schluchtsaum.KAMERA_FREI`
  (8,8 m) an.
- `Schluchtsaum.blaetterdach(eltern, baeume, saat, laubfarbe)` – viele
  Baumkronen in zwei Netzen (Kronen, Stämme), für Wald, auf den man von
  oben schaut. `baeume`: `[{"fuss", "hoehe", "breite"}]`.
- `Wasserfall.an_schluchtwand(eltern, kurve, kronen, strecke, seite, breite := 3.0, bis := -12.0)`
  – ein Band, das der Wandform folgt; unbeleuchteter Rauschshader ohne
  Bildschirm- oder Tiefenpuffer, nie ganz deckend.
- `Lichtschacht` (`MultiMeshInstance3D`) – gemalte Sonnenstrahlen:
  additive Bahnen, die sich zur Kamera drehen, ein Zeichenaufruf.
  `richtung` am besten `-sonne.global_transform.basis.z`. `decke` (Welt-Y
  der Öffnung, etwa die Wandkrone) blendet die Bahnen darüber aus – vor
  hellem Himmel lesen sie sich als Suchscheinwerfer. Mit
  `Effekte.reduziert` zeichnet ein Bündel höchstens drei Bahnen. Das
  Bündel neben die Kamerabahn stellen, nicht in die Wegmitte: Auch eine
  ausgeblendete Bahn kostet Füllrate. Nach dem Aufbau nicht mehr bewegen
  (feste Hülle).

Wald, der hinter einer Schluchtwand steht, sieht die Kamera nie; er
kostet trotzdem Zeichenaufrufe in jeder Schattenstufe. Level 01 pflanzt
deshalb nur dort, wo man hineinschaut.

## Gefahren und Portale

`Wasser` (`flaeche`, `tiefe`, `toedlich`) mit eigenem Wellen-Shader;
freiwillig `himmel_farbe` (Farbe der Spiegelung bei flachem Blick, am
besten die Horizontfarbe des Himmels) und `glitzer` (Sonnenglitzern, nur in
Leveln mit Glow – ohne flimmern die Punkte bloß). Beide sind aus, solange
man sie nicht setzt. `Stacheln` (`flaeche`, `einfahrbar`, `takt`),
`Portal` (`ist_ziel`). Das Zielportal sperrt den Spieler, zieht ihn ein
und löst `level_geschafft` aus.

**Portal** (`scenes/portals/portal.gd`, `class_name Portal`):
- Die Scheibe ist ein QuadMesh mit `Effekte.wirbelstoff`: Das Ziel saugt
  (`richtung` −1), der Start stößt aus (+1). Beim Einsaugen ändern sich
  `drall`, `sog` und `helligkeit`, nie `tempo` (siehe Effekte).
- Der Funkenkranz ist EIN `CPUParticles3D`, um 90° gekippt, und kreist im
  Drehsinn der Scheibe: das Ziel im Uhrzeigersinn (von vorn), der Start
  andersherum. Der Lichtfleck am Boden ist nicht breiter als das Portal und
  blendet beim Startportal mit dem Tor ein.
- Das Zielportal trägt eine **Lichtsäule** (`saeulen_hoehe`, Vorgabe 14 m,
  0 = keine; Level mit Decke über dem Ziel kürzen sie). Aus der Ferne weist
  sie den Weg, aus der Nähe bleibt nur ein Hauch.
- Beim Heraustreten aus dem Startportal ruft das Portal `stoss(-0.3)` am
  Knoten „Modell" der Figur auf, falls es die Methode gibt.

## Portalraum (`scenes/hub/`)

Der Portalraum wird vollständig in `hub.gd` gebaut; `Hub.tscn` enthält nur
Umgebung, Licht, Spieler, Kamera und HUD.

- **Licht:** Die Sonne steht tief im Nordosten (gut 30°) hinter den
  Räumen: Die Rückwände rahmen die Tore dunkel, der Hallenboden liegt in
  der Sonne (Lesbarkeitsvertrag). Ein schwaches, kühles Himmelslicht von
  Südwesten (Kameraseite, ohne Schatten) hebt die beschatteten Wände an.
  Glow ab 0,95, Tiefennebel ab 22 m. **Kein Punktlicht:** Was leuchten soll
  (Ringe, Flammen, Siegel, Strahlen des Mittelsteins), ist heller als 1 und
  glüht über den Glow; vor jedem offenen Tor liegt ein additiver
  Lichtfleck.
- **Sammelnetze:** Wiederkehrende Teile sind je Raum oder für den ganzen
  Saal EIN Netz: Pflaster (die Scheitelfarbe trägt Streuung, Verdeckung und
  Laufspuren), Bogenreihen, Brüstung, Halter, Fahnen (Shader mit Wappen),
  Flammen (ein MultiMesh mit Lichthof), Fortschrittssteine, Siegelschleier.
- **Mauern:** Nur die Rückwände haben Körper (Sockel, Gesims, Deckfläche,
  Wandpfeiler), weil hinter der Nordmauer nie eine Kamera steht. Süd- und
  Seitenmauern bleiben einseitige Flächen ohne Deckfläche: Die Kamera steht
  oft außerhalb, und eine Deckfläche läge als Balken quer im Bild.
- **Tore** (`levelportal.gd`, `class_name Levelportal`): `nummer`,
  `eigene_pfeiler`, `akzent` und `wirbel` vor `add_child()` setzen. Der
  grüne Ring heißt „offen", der Wirbel darin (`Effekte.wirbelstoff`) trägt
  die Farbe seines Raums (`wirbel`, gesetzt von `hub._wirbelfarben`).
  Verschlossene Tore zeigen dieselbe Scheibe dunkel und fast still. Ab 6 m
  erwacht ein offenes Tor; seinen Namen zeigt nur das nächste. Mit
  `eigene_pfeiler = false` baut das Tor nur die Kollision seiner Pfeiler,
  die Säulen zeichnet die Bogenreihe des Raums.
- **Betreten:** Die Figur wird eingesogen, dazu Funken, Blitz, Ring und
  eine Kreisblende auf die Scheibe; der Levelname steht groß über der Iris
  (CanvasLayer 50). Der Wirbel dreht dabei über `drall`/`sog`/`helligkeit`
  und die Drehung des Knotens auf, nie über `tempo`. Bis zum Szenenwechsel
  steht das Tor in der Gruppe `uebergang`, und die Statustafel bleibt zu:
  Die Iris liegt über dem HUD und schließt sich auch bei angehaltenem Spiel.
- **Pflaster:** Die Oberkante der Steine liegt auf dem Kollisionsboden
  (y = 0), Fase und Fugen darunter; Mittelstein und Schwellen stehen 2,5
  bis 3,5 cm darüber. Das Pflaster hat keine eigene Kollision – lag es
  höher, standen die Füße im Stein, und der Bodenfleck verschwand darunter.
  Die Raumböden beginnen erst hinter dem letzten Pflasterband.
- **Raumnamen** über den Toren auf 5,2 m: Höher lagen sie über dem oberen
  Bildrand der Portalraum-Kamera und waren nur im Sprung zu sehen.
- **Ankunft:** Vor dem Ausblenden des Ladeschirms wärmt der Portalraum
  die Teilchen-Shader vor (`Effekte.vorwaermen`, zwei Bilder nach dem
  Aufbau), damit Lichtsäule und Ring der Ankunft nicht stocken.
- **Torpfeiler:** Steht einer zwischen Kamera und Figur, löst er sich samt
  Kragstein, Kappe, Fahne, Halter und Flamme in ein Pixelraster auf
  (Distance-Fade-Dither; die Sammel-Shader bekommen die Werte je Torseite
  als `aufloesen[10]`). Nur Werte ändern sich, nie der Modus – kein Shader
  wird im Spiel neu übersetzt.
- **Siegel:** Vor einem gesperrten Raum stehen ein Lichtschleier mit
  Schloss-Zeichen und eine Steintafel; die Kollision ist unverändert das
  Riegelband aus 13 Kästen. Ein Raum, der seit dem letzten Besuch
  aufgegangen ist, wird einmal sichtbar entsiegelt.
- **Startplatz:** vor dem Raum, der gerade entsiegelt wird; sonst vor dem
  Raum des zuletzt betretenen Levels (zählt nur bei offenem Raum); sonst
  vor dem letzten offenen, nicht abgeschlossenen Raum. Beim neuen Spiel ist
  das der Wurzelwald mit Tor 01.
- **Laufzeit-Merker:** `portalraum_letztes_level_<Platz>` und
  `portalraum_offene_raeume_<Platz>` liegen als Metaangaben an der
  Baumwurzel: Sie überleben den Szenenwechsel, werden aber nie gespeichert.
- **Wegweiser:** zeigt im Raum des nächsten ungeschafften Tors auf die
  kleinste Nummer, in der Farbe des Zielraums, mit Kompassring am Boden.

## Effekte (`scripts/effekte.gd`)

`Effekte` bündelt alle kurzen Spielrückmeldungen: Staub, Funken, Blitz, Kistensplitter, Rauch, Druckwellenring, Lichtsäule, Blitzlicht, Kamerawackeln, Trefferpause und Bildblitz. Dazu kommen einige dauerhafte Bausteine: Bodenfleck, Lauf- und Slidestaub sowie Zündschnurglut. Wie `Leuchtmarker` besteht die Klasse nur aus statischen Funktionen: `Effekte.funken(self, pos, Farben.KISTE_LEBEN, 16, 5.0)`. Die vollständige Schnittstelle steht im Kopfkommentar der Datei.

**Regeln**
- **Farben nie ins Material.** Die Teilchenmaterialien (`Effekte.stoff()`) sind geteilt. Die Farbe jedes Stoßes steckt in `color` des Emitters und kommt als Scheitelfarbe im Shader an.
- **Effekte hängen an `current_scene`**, nie an Kisten oder Früchten. Der `Leuchtmarker` kopiert die Materialien des ganzen Unterbaums der Gruppen „kisten" und „fruechte". Eine eingesammelte Frucht nähme ihre Funken außerdem mit, wenn sie sich freigibt. Ein Szenenwechsel räumt die Effekte von selbst ab.
- **`CPUParticles3D`, nicht `GPUParticles3D`**, aus demselben Grund wie beim `Staubflug`. Jeder Stoß ist `one_shot` und `top_level`, hat keine Physikinterpolation und räumt sich selbst ab: über `finished` und zusätzlich über einen Zeitgeber.
- **Grenzen:** höchstens 24 Stöße gleichzeitig, 8 neue je Bild und 2 Blitzlichter. Wer einen Stoß anfordert, muss `null` als Rückgabe vertragen. Die Reihenfolge der Aufrufe ist der Rang: Wer mehrere Stöße auf einmal anlegt, legt die wichtigsten zuerst an. Eine Kiste legt beim Bruch zuerst ihre eigenen Stöße an (`_truemmer`) und erst danach alles, was sie auslöst (Früchte, Umrisse); die Explosion reiht Feuerball, Ring, Glut und Rauch in dieser Folge.
- **`Effekte.staubfarbe` überlebt den Szenenwechsel.** `LevelBasis` setzt sie deshalb vor jedem Aufbau auf `Effekte.STAUBFARBE_VORGABE` (Waldweg); ein Level mit eigenem Boden setzt sie beim Bauen.
- **`Effekte.ruhig`** (Einstellung „Bildschirmwackeln" aus) schaltet Wackeln, Trefferpause und Bildblitz ab. Auch das HUD blitzt dann nicht: kein roter Schleier beim Tod, kein roter Rand beim Schutzbruch.
- **Vorwärmen:** Die Teilchen von `vorwaermen()` laufen in Zeitlupe (`VORWAERM_ZEITLUPE`). Das erste Bild nach einem Aufbau ist lang, und mit gewöhnlichem Tempo verglühten sie darin, ehe sie gezeichnet wurden.
- **`Effekte.reduziert`** halbiert die Mengen und schaltet Wackeln, Trefferpause, Bildblitz und Blitzlicht ab. Vorbelegt ist es nur in Handy-Browsern.
- **Trefferpause:** `Engine.time_scale` wird für höchstens 0,2 s auf 0,05 gesetzt. Im Headless-Betrieb ist sie aus, damit die Messungen der Prüfwerkzeuge stimmen. Für den Zeitmodus ist sie fair, weil die Uhr mit dem verlangsamten Delta zählt.
- **Bildblitz** liegt auf CanvasLayer-Ebene 0, also unter dem HUD (Ebene 10, siehe HUD).

**Kameravertrag.** Eine Kamera, die wackeln kann, bietet `func erschuettern(staerke: float) -> void` an. `staerke` ist ein „Trauma"-Wert von 0 bis 1. Die Kamera nimmt das Maximum aus altem und neuem Wert, nicht die Summe. Sie lässt den Wert selbst abklingen (etwa 2 je Sekunde), macht den Ausschlag proportional zu staerke² und setzt ihn in `sofort_ausrichten` auf 0. `Effekte` spricht die Kamera nur per `has_method` an. Abstand und `reduziert` sind dabei schon verrechnet.

Übliche Stärken:

| Ereignis | Stärke |
|---|---|
| Bauchplatscher | 0,45 |
| TNT (mit Position) | 0,7 |
| Schutz verloren | 0,35 |
| Gegner besiegt | 0,2 |
| gewöhnlicher Kistenbruch | kein Wackeln |

**Portalscheibe.** `shaders/portal_wirbel.gdshader` ist für ein QuadMesh von 2r × 2r gebaut. Es arbeitet mit `blend_mix`: Additiv brennt die Scheibe vor hellem Grund zu Weiß aus. `Effekte.wirbelstoff(farbe)` liefert je Portal ein eigenes ShaderMaterial. Das Skript setzt pro Bild nur `puls` (0..1). **`tempo` nie animieren:** Der Shader rechnet `TIME * tempo`, jede Änderung springt um Hunderte Umdrehungen. Zum Einsaugen ändert man `drall`, `sog` und `helligkeit`.

**Stolperfallen in Godot 4.7** (gemessen im Prüfstand):
- `CPUParticles3D.emitting` ist von Haus aus `true`. Ohne `emitting = false` vor `add_child` entstehen alle Teilchen, bevor Tempo und Größe gesetzt sind.
- `BILLBOARD_PARTICLES` braucht `billboard_keep_scale = true`, sonst ist jedes Teilchen 1 m groß.
- Bei Weltkoordinaten geht die Drehung des Emitters nicht auf die Teilchen über. Aufgerichtete Ringe brauchen deshalb `local_coords = true`.
- `tangential_accel` dreht um die Richtung von `gravity`: Die Engine bildet das Kreuzprodukt aus dem Abstand zur Emittermitte und der Schwerkraft. Mit `gravity = Vector3.ZERO` ist die Tangentialkraft null, die Teilchen treiben nur radial. Ein Kranz, der kreisen soll, braucht einen Hauch Schwerkraft entlang der Drehachse, etwa `Vector3(0, 0.001, 0)` in lokalen Koordinaten (siehe `Portal._baue_funkenkranz`). Mit +Y als Achse kreist ein positiver Wert, von +Z gesehen, im Uhrzeigersinn.

**Prüfstand:** `werkzeuge/Effektprobe.tscn` zeigt jeden Effekt an seiner Station und prüft Grenzen, Aufräumen, Kameravertrag und Trefferpause. Headless läuft nur diese Logik. Unter Xvfb mit `EFFEKTPROBE_ZIEL=<Verzeichnis>` und `--fixed-fps 30` entstehen zusätzlich Fotos. Den Aufruf zeigt der Kopfkommentar von `werkzeuge/effektprobe.gd`.

## Bild und Licht (`project.godot`, Levelszenen)

**Renderer:** Das Projekt läuft auf `gl_compatibility` (Web-Export).
Keine `SCREEN_TEXTURE`/`DEPTH_TEXTURE`, keine Compute-Shader, kein
SDFGI oder Volumetric Fog. Gemessen unter Godot 4.7.2, nicht vermutet:
- **Unbeleuchtete Materialien** geben nur die Albedo aus – Emission kommt
  nicht an. Leuchten über 1 (und damit Glow) gibt es dort nur über eine
  Albedo über 1: `Materialbibliothek.leuchtschleier(farbe, staerke, additiv)`.
  Zum Pulsieren `.duplicate()` und `albedo_color` animieren.
  `transparent(…, leuchten)` leuchtet nicht.
- **Glow:** feste vier Stufen, immer „Screen"; `glow_blend_mode`,
  `glow_strength`, `glow_levels` und `glow_mix` werden ignoriert. Die
  Schwelle gilt für den sRGB-kodierten Wert vor dem Tonemapping und ist bis
  etwa 4 nutzbar. Additive und unbeleuchtete Flächen (Lichtschacht,
  Wasserfall) blühen mit einer Schwelle um 1,0 nicht zu stark.
- **Nebel:** `fog_aerial_perspective` wirkt nicht. Tiefennebel
  (`fog_mode = 1`) und `fog_sun_scatter` wirken; im Tiefenmodus ist
  `fog_density` die größte Deckkraft (0..1), keine Dichte je Meter.
- **Lichter:** höchstens 8 je Netz und 32 je Bild. Jedes Punktlicht zeichnet
  alles in seiner Reichweite ein weiteres Mal.
- **SSAO** gibt es (der Renderer rechnet mit doppelter `ssao_intensity` und
  halbem `ssao_radius`), es kostet aber einen zusätzlichen Tiefendurchgang.

**`project.godot` kennt keine Kommentare.** Godot liest `#` dort nicht als
Kommentarzeichen: Die Zeile wird Teil des nächsten Schlüssels, dessen Wert
unter einem Unsinnsnamen landet, und die gemeinte Einstellung bleibt still
auf der Vorgabe. Begründungen stehen deshalb hier, nicht in der Datei (der
Editor verwirft Kommentare beim Speichern ohnehin). Nach jeder Änderung
nachsehen, was wirklich gilt: `ProjectSettings.get_setting("rendering/…")`.
**Offen:** Der `#`-Block in `[physics]` verschluckt auf dieselbe Weise
`common/physics_interpolation=true` – die Physikinterpolation ist aus.

| `rendering/…` | Rechner | Browser (`.web`) | Warum |
|---|---|---|---|
| `anti_aliasing/quality/msaa_3d` | 1 (2x) | 1 (2x), Handy 0 | Glättet Stacheln, Kisten- und Wandkanten. Kostet rund 14 MB Grafikspeicher bei 720p, gut 30 MB bei 1080p, keine Draw-Calls. Handys im Browser (`Effekte.reduziert`) schaltet `Einstellungen._ready()` zur Laufzeit ab – dort zählt die Füllrate. |
| `lights_and_shadows/directional_shadow/size` | 4096 | 2048 | 16 statt 64 MB. Level 01 sieht in der Nahansicht fast gleich aus. |

**Kein FXAA.** `screen_space_aa` gibt es unter gl_compatibility nicht: Godot
4.7.2 meldet „Screen-space AA is only available when using the Forward+ or
Mobile renderer" und lässt die Einstellung fallen. Handys im Browser
zeichnen deshalb ungeglättet.

**Sonnen prüfen.** `.tscn` speichert eine `Transform3D` zeilenweise (Zeilen
der Basis, nicht Spalten). Ein abgeschriebener Wert lässt das Licht leicht
von UNTEN kommen – Level 01 war so nur vom Umgebungslicht beleuchtet, und
mehrere andere Level tragen dieselbe Sonne noch. Probe:
`-licht.global_transform.basis.z` ist die Laufrichtung des Lichts, ihr y
muss negativ sein.

**Licht in Level 01** (Werte in `Level01.tscn`):
- Sonne 68° hoch aus Süd-Südost, hinter der Kamera; 0,6, warm, Glanz 0,2,
  `sky_mode = 1`. Schatten: 2 Kaskaden bis 70 m, die erste bis 17,5 m
  (4 Kaskaden kosteten rund 500 Draw-Calls mehr). Steil genug, dass der Weg
  die hellste Fläche ist und die Wände nur gestreift werden.
- Gegenlicht flach von Norden (0,14, warm) – das `LIGHT0` des Himmels, es
  malt den warmen Schein am Horizont.
- Himmelslicht von oben, kühl blau (0,42), und Umgebung kühl
  (0,40/0,50/0,70) × 0,4: Die Schattenwand wird neutral bis kühl statt
  sattbraun, so trennt sich die Sonnen- von der Schattenseite.
- Bodenlicht warm von unten (0,12) gegen schwarze Unterseiten.
- Tiefennebel erst ab 12 m (Lesbarkeitsvertrag), bis 140 m, Farbe
  grünlicher Dunst.
- Glow ab HDR 1,0: Es blühen Portal, Früchte und Funken, nicht der Weg.
- ACES, Belichtung 0,95. Keine Farbkorrektur (Kontrast und Sättigung 1):
  Die Sonne bringt beides schon mit, mehr machte die Felswände unruhig.
- SSAO aus: in Level 01 kaum sichtbar.
- `Bildrahmen` mit 0,35.
- Abschnittsstimmungen über relative `Stimmungszone`n
  (`level01.gd::_stimmungen()`): Schlucht kühl und dunstig, Baumkronen hell
  und golden, Lichtung warm.

**Himmel (`shaders/himmel.gdshader`).** Verlauf, Dunstband, Wolken aus
einer Rauschtextur, warmer Schein zu `LIGHT0`, ferne Hügel
(`huegel_hoehe`), optional eine Sonnenscheibe und – unter dem Horizont –
gestaffelte Waldrücken mit Nebel in den Tälern (`wald_kante`). Sie füllen
den Blick hinter dem Zielportal dunkel; vorher stand dort eine helle
Fläche, heller als der Weg. Das Dunstband ersetzt die Luftperspektive:
`dunst` muss gleich `fog_light_color` sein, sonst sieht man, wo die
Geometrie endet. Kein `TIME`, kein `POSITION`, keine Uniforms pro Bild –
jede Änderung rendert die Radiance-Cubemap neu. `LIGHT0` ist das erste
Richtungslicht ohne `sky_mode = 1`; Füll- und Hauptlichter, die den
Himmel nicht bemalen sollen, stehen deshalb darauf. Die Rauschtextur
entsteht beim Laden auf der CPU: 256² genügt, 512² sah gleich aus und
dauerte viermal so lange.

**Bildrahmen (`scripts/bildrahmen.gd`, `class_name Bildrahmen`).** Dunkle
Bildecken als CanvasLayer auf Ebene -1 (unter Bildblitz und HUD), ohne
`SCREEN_TEXTURE`: ein bildschirmfüllendes Rechteck mit vormultipliziertem
Alpha, ein Durchgang. Als Knoten in die Levelszene hängen oder
`Bildrahmen.einsetzen(eltern, rand := 0.3, rand_farbe, schein := 0.0)`.
Der warme Schein von oben (`licht`) taugt nur für Level mit dunklem
oberem Bildrand; vor hellem Himmel wäscht er das Blau grau.

## UI-Stil (`scripts/ui_stil.gd`, `class_name UiStil`)

Eine Stelle für das Aussehen aller Menüs und Anzeigen, im Code gebaut wie
`Materialbibliothek` – ohne `.tres`. Die einzige Datei ist die
Anzeigeschrift Lilita One (`assets/schrift/`, SIL OFL 1.1). Farben stehen
in `Farben` im Abschnitt `UI_*` (Gold, Hell, Matt, Kontur, Grund, Nacht,
Treffer, Herz, Silber, Bronze). Für Früchte, Kisten, Warnung und
Edelsteine gelten die Spielfarben, damit ein HUD-Symbol so aussieht wie das
Ding in der Welt.

- **Schriften:** `UiStil.schrift(&"text" | &"fett" | &"zahl" | &"titel" | &"logo" | &"sperr" | &"schwung")`
  – FontVariations zweier Schnitte. Was man **liest** – Fließtext,
  Menüeinträge, Beschriftungen, Hinweise, Kicker (`&"text"`, `&"fett"`,
  `&"sperr"`) –, steht in der eingebauten Schrift (Open Sans SemiBold).
  Was man **auf einen Blick erfasst** – Schriftzug, Titel, Banner, Zähler,
  Uhren (`&"logo"`, `&"titel"`, `&"schwung"`, `&"zahl"`) –, in Lilita One.
  Die Datei wird einmal geladen und nie verändert; jede Lilita-Art hat
  die Grundschrift (fett, gleiche Schräge) als `fallbacks` für Zeichen,
  die Lilita fehlen (Latin Extended-A wie Ā ł; ✕ ○ □ △ fehlen beiden und
  kommen als Formen aus `PadSymbole`). Weil `get_ascent()` das Maximum
  über die Ersatzschriften nimmt, melden Lilita-Arten die Oberlänge der
  Grundschrift – Grundlinien, die daraus gerechnet werden, bleiben
  stehen. Fehlt die Datei, schreibt alles in der Grundschrift.
  Lilita hat nur **proportionale Ziffern** und kein `tnum`. Deshalb setzen
  `text()` und `textbreite()` bei `&"zahl"` jede Ziffer mittig in ein Fach
  von der Breite der breitesten Ziffer – die Uhr des Zeitmodus zittert
  nicht. Wer `schrift(&"zahl")` direkt an `draw_string` oder ein
  `Label3D` gibt, bekommt proportionale Ziffern; für feste Zahlen (Portal-
  nummern) ist das gleich. Kleine Zahlen, die neben Text stehen
  (Ladeprozent, Stufenwert „80 %" im Menü), bleiben in `&"fett"`: Open
  Sans hat von Haus aus gleich breite Ziffern, bleibt klein sauberer und
  passt zu den Wahlwerten derselben Menüzeilen.
- **Flächen:** `UiStil.flaeche(art)` / `UiStil.zeichne(auf, feld, art)` mit
  `&"tafel"`, `&"kachel"`, `&"chip"`, `&"knopf"`, `&"knopf_gewaehlt"`, `&"balken"`,
  `&"balken_voll"`, `&"pille"`, `&"band"`, `&"schalter"`, `&"mulde"`. **Geteilt,
  nie verändern.** Feste Abwandlungen über `getoent()`, `gerahmt()` und
  `variante()` (ebenfalls geteilt). Für animierte Werte `eigene()`: Die Kopie
  gehört dem Aufrufer. Kapselformen nur breiter als hoch – ein Quadrat mit
  voller Rundung zeigt in StyleBoxFlat eine Naht, Kreise zeichnet
  `fassung()`. Auch breiter als hoch zeigt eine Kapsel, deren Eckradius
  genau die halbe Höhe ist, mit Kantenglättung ein helles Nahtpixel an den
  Enden; `&"chip"` ist deshalb für 46 px Höhe gebaut (Radius 22).
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
  `iris_auf(mitte)`. Jede Oberfläche (HUD, Startbildschirm, Ladeschirm,
  Levelportal) legt sich ihre eigene an. Die Blende läuft auch bei
  angehaltenem Spiel und ist unsichtbar, solange sie nichts deckt. Die Iris
  ist ein einfacher canvas_item-Shader und läuft auch auf WebGL2.

## HUD (`scenes/ui/hud.gd`, `HUD.tscn`)

Alles ist mit `UiStil` gezeichnet und zeichnet nur neu, solange sich etwas
bewegt.

| CanvasLayer | Inhalt |
|---|---|
| -1 | `Bildrahmen` der Levelszene |
| 0 | Bildblitz der `Effekte` |
| 2 | Rennanzeige, Flugtafel (Level 22) |
| 10 | HUD samt Statustafel und Touch-Steuerung |
| 50 | Blende beim Betreten eines Levelportals |
| 128 | Ladeschirm |

Neue Überlagerungen bleiben unter 10, damit die Statustafel sie beim
Anhalten verdeckt.

- **Chips oben links:** Früchte (Beere im Fortschrittsring bis zum
  Extraleben), Leben (ein Herz, „×5") und Kisten („12/39"; grün mit
  Edelstein, sobald alle zerbrochen sind). Eingesammelte Früchte fliegen
  von der Figur in den Zähler, die Zahl zählt beim Ankommen hoch. Nach 6 s
  ohne Änderung treten die Chips leicht zurück.
- **Meldungen:** `GameState.zeige_nachricht()` erscheint als Kapsel oben in
  der Mitte, `GameState.zeige_banner()` als großes schräges Band.
- **Tod und Treffer:** `level_zuruecksetzen` löst einen dunkelroten Blitz
  aus (`UiStil.Blende`, unter den Zählern). Ein vom Schutz abgefangener
  Treffer färbt den Bildrand rot. Beides entfällt wie jeder Bildblitz bei
  `Effekte.ruhig` („Bildschirmwackeln" aus) und `Effekte.reduziert`.
- **Titelkarte:** „LEVEL 01 · WURZELWALD / Wurzelschlucht" links unten, am
  Signal `aufbau_fertig` des Levels – nur, wenn es über
  `Spielfluss.zum_level()` betreten wurde (`titelkarte_faellig`).
  Werkzeuge, die Level direkt laden, bekommen keine Karte ins Bild. Liegen
  die Touch-Tasten im Bild, steht sie höher, über dem Joystick.
- **Auswertung am Ziel** (Gruppe `auswertung`): `Spielfluss.level_abgeschlossen`
  und `zeit_gewertet` füttern die Karte. Früchte zählen hoch, der
  Kistenbalken füllt sich, die Edelsteine springen in ihre Fassungen (neue
  mit „NEU"); dazu Zeitstufe und Bestzeit, im Rennen der Platz (aus der
  Gruppe `rennanzeige`), und Konfetti. Im Rennen feiert sie nur das Podest:
  ab Platz 4 ein silbergraues „ZIEL!" ohne Konfetti, Platz 1 bekommt eine
  zweite Salve. Solange die Karte steht, schweigen Meldungen und Bänder.
  Den Wechsel in den Portalraum macht weiter `LevelBasis`.
- **Zeittafel:** Die Uhr ist zur besten noch erreichbaren Stufe hin
  getönt. Darunter stehen drei Rauten (Platin, Gold, Saphir) und etwa
  „Gold bis 1:08,00". Solange die Uhr steht, zählt ein Ring die Standzeit
  herunter.

## Menüs und Ladeschirm

Alle Menüs zeichnen mit `UiStil`; das Theme steht an jeder UI-Wurzel.

**Menüeintrag** (`scenes/ui/menue_eintrag.gd`, `class_name MenueEintrag`) –
der eine Baustein aller gezeichneten Menüs (Startbildschirm,
Speicherplätze, Einstellungen, Statustafel).
- `setze_auswahl(an, sofort := false)` blendet weich über; `sofort` nur für
  Einträge, die gerade erst entstehen. `druecken()` drückt den Eintrag kurz
  ein, ohne die Tat zu verzögern – die Menüs rufen es vor jeder Tat auf.
- Wertzeilen über `art`: `WAHL` (‹ `wert` ›, links/rechts schaltet; lange
  Werte werden verkleinert und hinten gekürzt), `SCHALTER` (nach
  `eingeschaltet`, der Knopf gleitet), `STUFEN` (`stufe` von `stufen`
  Balken). `wert_geschoben(richtung)` lässt den Pfeil der Seite
  herausschnellen. Beschriftung und Wert stehen getrennt: Wer Werte
  ändert, trägt sie in die bestehenden Einträge ein, statt das Menü neu zu
  bauen.
- Verborgen ruht ein Eintrag ganz, auch gewählt.
- Klänge spielt das Menü, nicht der Eintrag: `MenueEintrag.klang_wahl()` /
  `klang_ok()`. Der Wahlklang wartet bis zum Bildende und entfällt, wenn im
  selben Bild bestätigt wird – ein Tipp klingt einmal. Kennt `Klang`
  „menue_wahl"/„menue_ok", werden diese gespielt.

**Startbildschirm** (`scenes/ui/splash.gd`, `splash_kulisse.gd`):
- Eigener Himmelsshader ohne `TIME`/`POSITION` (die Umgebungskarte
  entsteht einmal), Wolken als Rauschbild, beim Start synchron gerechnet;
  Glühen ist an.
- Lichtfahnen als EIN Netz mit Achsen-Billboard-Shader (additiv, ohne
  Nebel und Schatten, ein Draw-Call): fünf Bündel schmaler Bahnen, über dem
  Kronendach und links hinter Titel und Menü ausgeblendet. Pollen als
  `Staubflug` mit freier Mitte um die Kamerabahn.
- Der Schriftzug besteht aus sieben Buchstabenfeldern mit einem
  gemeinsamen canvas_item-Shader (Wippen, Glanzstreif), ohne Neuzeichnen.
- Die Eröffnung kürzt nur ein echter Druck ab, keine Mausbewegung und kein
  leichter Stickausschlag: Der Tween wird ans Ende gespult. Zurück aus den
  Einstellungen läuft sie auf gut ein Drittel verkürzt. In der
  Speicherplatz-Tafel tut ein Tipp auf einen gesperrten (leeren) Platz
  nichts.
- `_index` und `_tafel_offen` liest der Spieltest – nicht umbenennen.

**Einstellungen** (`scenes/ui/optionen.gd`): Die Figurvorschau steht in
einer eigenen 3D-Welt auf einem kantigen Baumstumpf (Rinde mit Wurzeln,
Schnittfläche mit Jahresringen). Den gleichen Dateinamen neu übernehmen
baut die Vorschau neu; kann sie die Datei nicht zeigen, nennt die Meldung
den Grund.

**Ladeschirm** (`autoload/Ladeschirm.gd`, CanvasLayer 128):

```gdscript
Ladeschirm.zeigen(titel, dauer := 0.0)   # 0 = sofort deckend
signal eingeblendet                      # erst, wenn der Schirm wirklich deckt
Ladeschirm.fortschritt(anteil, text)     # vollendet ein laufendes Einblenden
Ladeschirm.verbergen()                   # weich ausblenden
Ladeschirm.abblenden(dauer) / aufblenden(dauer) -> Tween   # nur Dunkel, ohne Titel
```

Wer mit `dauer` einblendet und danach blockierend wechselt, wartet auf
`eingeblendet`. Ein erneutes `zeigen()` ersetzt ein laufendes Einblenden
(das Signal kommt am Ende des neuen); nur `verbergen()` bricht ab und
meldet sofort, damit niemand ewig wartet. Aus dem Titel „Level 01" macht
der Schirm über `Spielfluss.level_name()` selbst Kopfzeile und Namen
(„LEVEL 01 · WURZELWALD" über „Wurzelschlucht").

Aussehen je Raum (`RAUMTOENE`, Eintrag 0 = Portalraum): Farbton, Schein und
ein Scherenschnitt im unteren Drittel (Tannen, Schilf und Steg, Mauer und
Türme, Schlote, Dünen und Dächer, im Portalraum die fünf Portalringe). Die
Formen liefern statische Helfer (`reihe()`, `baum()`, `zerlege()`, über
`preload` des Skripts); auch die Einstellungen zeichnen damit ihren
Waldrand. Zerlegt wird einmal je Raum und Bildgröße (Zwischenspeicher für
bis zu 12), gezeichnet mit `RenderingServer.canvas_item_add_triangle_array`.
`zerlege()` fragt jede Form nur über ihrer eigenen Breite ab; über alle
Stellen dauerte das Schilf der Nebelsümpfe eine Viertelsekunde.
