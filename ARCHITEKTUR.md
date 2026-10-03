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
| 5 | 16 | Spielergrenze (`LevelWerkzeuge.SPIELERGRENZE`): Leitlinien, Randkörper und erhöhtes Begehbares. Die Figur (Maske 1\|16 = 17) stößt daran an, der Kamerastrahl (1\|8) nicht – er startet sechs Meter vor der Figur, und eine einrückende Wand zwischen Blickpunkt und Figur zöge die Kamera sonst vor die Figur. Bisher nur in Level 01 belegt. |

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
überschreibt die Methode. So der `Fluechtling` (Level 05): Er klebt wie der
Reiter auf der Kurve, und der Reiter ersetzt `_process` samt Takt der
Bodeneffekte. Der Flüchtling holt den Takt zurück und überschreibt
`_bodeneffekte_takten()` mit dem Bodenbegriff der Schiene – am Boden ist,
wer nicht springt (`is_on_floor()` bleibt ohne `move_and_slide` immer
falsch). Slidestaub gibt es auf der Flucht nicht.

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
Sprung-, Feder- und TNT-Kiste stauchen beim Absprung zum Boden hin. Ein
Schlag (Drehschlag, Slide, Bauchplatscher) lässt TNT sofort explodieren;
nur Draufspringen zündet den Countdown (3 s). TNT
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

Die Stelzenspinne hat neben ihrer Trefferzone (Leib, Radius 0,45 m) eine
flache **Fegezone** in Beinbreite (Zylinder, Radius 1,25 m, 0,9 m hoch),
die nur Slide und Bauchplatscher auswertet. Wer zwischen den Beinen, aber
neben der Mitte durchrutschte, kam vorher unbeschadet durch, und die Spinne
blieb stehen. Gemessen (feststehende Spinnen in Level 01): 1,2 m neben der
Mitte vorher 0 von 3 besiegt, jetzt 3 von 3. Schaden gibt weiter nur der Leib.

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
eine Zwei-Pixel-Maske (`EMISSION_OP_MULTIPLY`) nur auf der Beere und ist
schwach (0,15): Die Form kommt aus Licht, Glanz (Rauheit 0,3) und einem
Eigenschatten in den Scheitelfarben (unten 40 % dunkler). Mit 0,45 lag
die Beere flach wie ein Aufkleber. Die Beere hat 14 Ringe zu 22 Segmenten. Die
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

**Game Over** (letztes Leben verloren): Banner, das Level wird wie bei
einem Tod zurückgesetzt (Uhr, HUD und Zeitmodus hängen an
`level_zuruecksetzen`), dann geht es nach `GAME_OVER_PAUSE` (2,5 s) in den
Portalraum, mit vollen Leben. Nur aus einem Level heraus und nur, wenn der
Spieler inzwischen nicht selbst die Szene gewechselt hat.

**Vorladen** (`Spielfluss.vorladen`, `vorladen_naechstes`): Ist der
Portalraum eingeblendet, lädt das nächste offene Level im Hintergrund
(`ResourceLoader.load_threaded_request`, Szene und Skripte, nicht der
Aufbau). Jeder Wechsel mit Ladeschirm holt die Szene über diesen Faden; der
Ladeschirm läuft dabei weiter. Gemessen (Level 01, Rechner, headless,
Zwischenspeicher warm): Szene nach 0,13 statt 2,3 s, spielbereit nach 5,4
statt 7,0 s.

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

**Aufbau:** Jedes starre Glied ist EIN Netz. Die Grundformen eines Glieds
(Kugeln, Kapseln, Kegel, Torus) werden beim ersten Bau über
`SpielerModell.Form` zu einem `ArrayMesh` mit Eckfarben verschmolzen und
für alle weiteren Figuren aufgehoben (`_netze`, nie verändert). 15
Glieder: Rumpf (mit Halstuch), Tuchzipfel, Kopf, zwei Lider, zwei Ohren,
zwei Oberarme, zwei Hände, zwei Beine, Schweif, Schweifspitze – vorher
rund 50 Einzelteile mit je eigenem Draw-Call (dazu noch einmal so viele
im Schatten). Lider und Tuchzipfel werfen keinen Schatten.

**Fließende Haut:** Innerhalb eines Glieds werden die Fellformen (Kugeln,
Kapseln, Kegel mit `ART_FELL`) nicht mehr als Netze aneinandergesteckt. An
jeder Naht lag sonst eine scharfe Kerbe, und die Figur las sich wie aus
Bällen gebaut. `Form` sammelt sie als Abstandsfeld und vereinigt sie weich
(polynomielles smin; der Übergang ist 35 % des kleinsten Radius, 0,8–4 cm).
Ausgelesen wird EINE Haut mit Surface Nets auf einem Gitter, 34 Zellen über
die längste Seite des Glieds (6–20 mm). Mit 56 Zellen kostete die Figur
bei Level 01, 186 m, 248 000 Primitive mehr (903 000, über dem Budget); mit
34 sind es 69 000 mehr (724 000). Die Normalen kommen aus dem Feld, die
Farbe von der nächsten Form, an den Nähten über 6 mm gemischt, jede mit ihrem
Maler. Scharf und als eigenes Netz bleiben Augen, Iris, Pupillen, Glanz,
Nase und Lächeln (`ART_GLATT`/`ART_LICHT`), Halstuch (ein flaches Band:
dünner Ring, hochgezogen) und Knoten sowie das
Innenohr (`teil(…, weich = false)`); ein Glied mit nur einer Form bleibt
dessen Grundnetz. Die Gelenke ZWISCHEN den Gliedern (Kopf, Arme, Beine,
Schweif) bleiben getrennt, weil sie sich bewegen.
Kosten: erster Bau 1,0 s (vorher 15 ms), deshalb liegt jedes Gliednetz im
`Bauspeicher` (`beuteldachs_<name>`); bei 56 Zellen lud der nächste Start
es in 21 ms.

**Stoff (`FELL_CODE`):** ein geteiltes `ShaderMaterial` für alle Glieder.
Die Eckfarbe trägt die Farbe (sRGB, im Shader linearisiert) und im Alpha
die Art der Fläche: 1 Fell (Strähnenrauschen aus der Lage im Glied,
Unterseiten dunkler, weicher Saum an der Silhouette), 0,5 glatt (Augen,
Nase: glänzend), 0 Glanzpunkt (leuchtet). Ohne Textur, ohne Bild- und
Tiefentextur – läuft unter gl_compatibility. Die Zeichnung (heller Bauch,
helle Brille ums Auge, Nasenrücken, Ringe am Schweif, dunkle Ohrspitzen)
malen kleine Maler-Funktionen beim Bau in die Eckfarben.

**Haltungen:** `aktualisiere(…, haltung)` wertet `Spieler.haltung()` auch
für den Beuteldachs aus, nicht nur für Clips eigener Figuren:

| Zustand | Pose |
|---|---|
| Slide | Bauchrutscher: Rumpf kippt nach vorn (statt gestaucht zu werden), Kopf hoch, Arme voraus, bleibt unter 0,76 m |
| `krabbeln` | auf allen vieren, Hände am Boden, Arme und Beine im Wechsel, unter 0,76 m |
| `hangeln`… | Arme senkrecht und gestreckt (Oberarm × 1,6, die Hand rückt ans Ende) bis an `GRIFF_HOEHE`; `_geduckt` zieht die Beine über 0,54 m, `_spin` reißt sie herum |
| `sitzen` | Beine nach vorn, Hände am Lenker (Kart, Flieger) |
| `reiten` | breitbeinig, vorgebeugt (Wildkatze) |

Drehschlag (Arme waagerecht), Sprung, Lauf und Stand wie bisher; am
Gitter bleiben die Hände beim Drehschlag oben.

`werkzeuge/figurschau.sh <ziel> [posen,gesicht,ruecken,schutz,lauf]`
fotografiert Haltungen und Schutz unter dem Licht von Level 01, ohne das
Level zu bauen (gut eine halbe Minute statt mehrerer).

`stoss()` stößt eine gedämpfte Feder auf dem Knoten `Teile` an. Dessen
Ursprung liegt auf Fußhöhe, die Füße bleiben also am Boden. Der Wert wird
gesetzt, nicht addiert. Die Feder beißt sich weder mit dem Slide-Stauch am
Rumpf noch mit dem Halter einer eigenen Figur noch mit dem Portal-Tween auf
dem Modellknoten; Hitbox und Kollision bleiben unberührt.

Der Spin-Ring ist ein eigener Shader (zwei Schlieren mit heller
Vorderkante, ohne Bild- und Tiefentextur); ausgeblendet ist er
`visible = false` und kostet keinen Draw-Call. Der Beuteldachs blinzelt in
unregelmäßigem Takt.

## Schutz (`scenes/player/schutzmaske.gd`, `class_name Schutzmaske`)

Jeder `Spieler` hängt sich in `_ready()` einen Schutzgeist an. Es gibt
immer genau EINEN, gleich wie viele Ladungen `GameState.schutz` zählt;
die Stufe zeigt sich am Leuchten (`STUFEN`): 1 glimmt, 2 leuchtet mit
kleinem Hof, 3 bekommt einen schwachen Strahlenkranz und blinkende Funken.
Bewusst dezent (Größe `GEIST_GROESSE` 0,8, Leuchten bis 1,0, Hof bis
1,2): Der Geist begleitet die Figur, er ist nicht die Hauptsache im Bild.
Vorher reichten Leuchten bis 1,9 und Hof bis 1,85. Der Hof ist
eine immer zur Kamera gedrehte Fläche (`SCHEIN_CODE`, additiv) und
leuchtet auch in Leveln ohne Glow. Drei Draw-Calls (Maske, Flügel, Hof),
die Flügel schlagen im Vertex-Shader.

| Ereignis | Anzeige |
|---|---|
| Gewinn aus 0 | ploppt an der Schulter auf, Funken |
| Gewinn | Aufblitzen, kurz größer, eine Stufe heller |
| Verlust (bleibt ≥ 1) | Blitz, Funken, zwei Scherben, Flackern, eine Stufe dunkler |
| letzte Ladung | Blitz, Ring, sieben Scherben, schrumpft weg |
| Levelstart | ohne Effekt auf der richtigen Stufe |

Bewegung (`_folgen()`): Platz auf Schulterhöhe NEBEN und etwas HINTER der
Figur, beides in Kamerasicht (Kamera-Rechts, Blickrichtung waagerecht).
Er macht 60 % der Figurbewegung sofort mit, den Rest holt eine gedämpfte
Feder auf (er hängt beim Rennen gut einen halben Meter nach und schießt
beim Anhalten etwas vor), dazu Wippen und kleine Ausflüge. Läuft die
Figur quer durchs Bild, wechselt er auf die Seite hinter ihr, im Bogen
über und hinter die Figur. `_aus_der_sicht()` schiebt ihn aus der
Sichtlinie Kamera–Figur, ein Strahl im Physiktakt (Ebene 1) hält ihn vor
Wänden. Bildtakt wie die Kameras: `top_level`, ohne Interpolation, Ort
über `Bildtakt.ort()`; nach einem Versetzen (Respawn) springt er mit.

## Bildtakt und Physiktakt (Physikinterpolation)

`physics/common/physics_interpolation` ist an. Godot zeichnet alles, was im
Physiktakt (60 Hz) bewegt wird, zwischen seinen letzten beiden
Physikschritten – auf einem Bildschirm mit 144 Hz läuft die Figur in 144
Schritten je Sekunde statt in 60 Stufen. Das gilt für jeden `Node3D` mit
Interpolation, auch für solche, die gar nicht im Physiktakt bewegt werden.
Daraus folgt eine Regel:

**Was im Bildtakt bewegt wird, wird nicht interpoliert.**

- **Im Physiktakt bewegt** – `_physics_process`, `move_and_slide`, eine
  `AnimatableBody3D` mit `sync_to_physics` (sie übernimmt ihre Lage am
  Anfang des Schritts vom Physikserver): Interpolation bleibt an, das ist
  die Vorgabe. Spieler, Reiter, Karts, Flieger, Katze, Keiler, Gegner samt
  eigener Optik, Plattformen, Gefahren, Geschosse.
- **Im Bildtakt bewegt** – `_process`, Tweens (die laufen von Haus aus im
  Bildtakt), AnimationPlayer, Zeitgeber, `aktualisiere()` aus `_process`:
  `physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` am
  bewegten Knoten. Mit Interpolation mischte Godot jedes Bild den Stand des
  letzten Physikschritts hinein, und der Knoten zitterte. Ein Knoten ohne
  Interpolation unter einem interpolierten Elternteil folgt diesem
  trotzdem weich; nur seine eigene Bewegung wird genau so gezeichnet, wie
  sie gesetzt wurde. Der Modus vererbt sich: OFF am Wurzelknoten eines
  Aufbaus gilt für alles darunter. Controls sind von Haus aus OFF, darum
  ist auch die Kulisse des Startbildschirms nie interpoliert worden.
- **Beides an einem Knoten:** Der Tween auf einem interpolierten Körper
  läuft im Physiktakt (`create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)`,
  so schrumpft ein Gegner beim Verpuffen), oder der Körper ist, solange
  ihn der Tween trägt, OFF (die Figur im Portalsog; zurück auf `INHERIT`
  mit `reset_physics_interpolation()`).

Ohne Interpolation laufen heute: `SpielerModell` (auch in Reiter, Flieger
und der Figurvorschau der Optionen), die drei Kameras, `Schutzmaske`,
`Bodenschatten`, Wegweiser und Licht des `Lichtkreis`, `Frucht`, `Marke`,
das Modell der `Kiste`, `Explosion`, Wassertropfen, alle `Effekte`,
Baumkrone, Kleinzeug im Wind, Vogelkreisel, `Levelportal` und `Portal`,
Turbospur des Reiters, Propeller des Fliegers, die Eistore in Level 17,
das Fremdmodell der Gegner (seine Clips und alles an Knochen laufen im
Bildtakt), die Kamera des Startbildschirms und die des Rundgangs beim
Laden (`Rundgang`, in Level und Portalraum).

**Folgen im Bildtakt:** Wer einem Physikkörper im Bildtakt folgt (Kameras,
Bodenfleck, Masken, Wegweiser, Lichtkreis), liest dessen gezeichneten Ort
über `Bildtakt.ort(ziel)` bzw. `Bildtakt.lage(ziel)` (`scripts/bildtakt.gd`),
nie `global_position` – das ist der Stand des letzten Physikschritts, eine
Treppe mit 60 Stufen je Sekunde. Die Hilfe statt
`get_global_transform_interpolated()`, weil Godot 4.7 den interpolierten Ort
einmal zu Beginn des Bildes ausrechnet und danach diesen Merkwert
zurückgibt: Wird der Körper im selben Bild noch versetzt (Respawn aus einem
Zeitgeber, Bonusraum), wäre er bis zum nächsten Bild veraltet, auch nach
`reset_physics_interpolation()`, und die Kamera flöge von der
Absturzstelle zurück. Liegen Merkwert und wirklicher Ort mehr als
`Bildtakt.VERSETZT` (2 m) auseinander, gilt der wirkliche. Ein Ziel ohne
Interpolation (die Figur im Portalsog) wird genau an `global_transform`
gezeichnet; das gibt die Hilfe dann zurück. Spiellogik (Einsammeln,
Treffer) liest weiter `global_position`.

**Versetzen:** Wer einen interpolierten Körper versetzt, statt ihn zu
bewegen, ruft danach `reset_physics_interpolation()` – sonst zieht Godot
einen Physikschritt lang eine Spur vom alten zum neuen Ort. Das tun
Respawn (Spieler, Reiter, Flieger, Keiler), Levelstart, Startplatz im
Portalraum, Bonusraum, der Dreher im Kart-Rennen, der Rollbrocken am
Bahnanfang, die Plattformen beim Aufbau und die Prüfwerkzeuge
(`foto.gd`, `level_check.gd`). Gerendert nachgeprüft: Im Bildtakt versetzt
und zurückgesetzt, steht der Körper noch im selben Bild am neuen Ort. Ein
Knoten, der neu in den Baum kommt, wird von Godot selbst zurückgesetzt.

**Prüfung:** `werkzeuge/Glattprobe.tscn` (in `pruefe.sh`, Stufe 4) lässt
die Figur in Level 01, im Portalraum und in Level 04 laufen, headless mit
`--fixed-fps 144` bei 60 Physikschritten je Sekunde. Sie misst, wie
unruhig Figur und Welt im Bild laufen (zweite Differenz des Bildpunkts,
Pixel bei 720 Zeilen), und meldet jeden Knoten, der im Bildtakt bewegt,
aber interpoliert wird (ZITTERT), oder im Physiktakt bewegt, aber nicht
interpoliert wird (STUFT). Zuletzt ruft sie `respawn()` zwischen zwei
Physikschritten und prüft, dass die Kamera im selben Bild mitspringt
(sonst FLIEGT NACH). `GLATT_SZENEN=<Liste>` prüft andere Szenen; über
alle 25 Level, Werkstatt, Testlevel, Startbildschirm und Bonusraum
gelaufen, meldete der Wächter nichts mehr.

| Zittern im Bild (px) | Figur vorher | Figur jetzt | Welt vorher | Welt jetzt |
|---|---|---|---|---|
| Level 01 | 2,01 | 0,22 | 1,29 | 0,03 |
| Portalraum | 0,11 | 0,01 | 7,49 | 0,07 |
| Level 04 (Wildkatze) | 1,68 | 0,00 | 1,06 | 0,01 |

„Vorher" ist f2f77cf, also ohne Interpolation. Die Streuung des Wegs der
Figur von Bild zu Bild fiel dabei von 1,37 / 1,18 / 1,18 (58–65 % der
Bilder ohne Bewegung) auf 0,09 / 0,00 / 0,01. Im Portalraum blickt die
Kamera per `look_at` auf die Figur: Die Figur stand im Bild still, und die
ganze Welt sprang – das war das Ruckeln dort. Nur den Schalter umzulegen
hätte nicht gereicht: Dann zitterten in Level 04 216 Knoten (Früchte,
Baumkronen, die Figur selbst), in Level 01 141, im Portalraum 53, und nach
einem Respawn zwischen zwei Physikschritten flog die Kamera von der
Absturzstelle zurück (1 bis 2 m je Bild, die Probe prüft das als
„Versetzen"). Heute springt sie im selben Bild mit.

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
- **Schatten im Web und auf dem Handy** (`_schatten_anpassen()`, direkt
  nach `_nach_aufbau()`): für jedes Level dieselbe Regel an der
  schattenwerfenden Sonne – statisch als `LevelBasis.schatten_regel(szene)`,
  die auch der Portalraum aufruft. Im Web höchstens zwei Stufen bis
  `SCHATTEN_WEB` (60 m), auf dem Handy (`Effekte.reduziert`) eine
  orthogonale Stufe bis `SCHATTEN_HANDY` (50 m). Früher stand das nur in
  Level 01; seit die App den Handyweg nimmt, liefen alle anderen Level dort
  mit vier Stufen bis 70–90 m. Gemessen (`FOTO_REDUZIERT`, verfolger 40 m):
  Level 05 341 → 261 Draw-Calls, Level 02 1937 → 1589.
- **Rundgang unter dem Ladeschirm** (`_rundgang()`, Ablauf in
  `scripts/rundgang.gd`, `class_name Rundgang`): Wenn alles steht –
  Kamera ausgerichtet, Zeitkisten gesetzt, `_nach_aufbau()` und
  `_schatten_anpassen()` gelaufen (dort ändern sich Licht und Schatten,
  und damit die Shaderfassungen) –, zeigt eine eigene Kamera in einem
  eigenen kleinen Viewport derselben Welt eine Liste von Blicken, je Blick
  ein Bild (`Rundgang.fahren(bei, blicke, vorbild, von, bis)`). Das Level
  baut die Blicke aus dem Verlauf (`rundgang_blicke()`,
  `Rundgang.blicke_entlang`): alle `RUNDGANG_ABSTAND` (12) m je ein Bild
  40° links und rechts vorn, die Kamera wie die Korridorkamera dahinter
  und darüber; dasselbe auf jedem Nebenweg aus dem Haken
  `_rundgang_pfade() -> Array[Curve3D]` (Vorgabe leer – eine eigene Kurve,
  die der Verlauf nicht berührt; was nur seitlich oder erhöht neben dem
  Verlauf liegt, sieht er schon von dort, geprüft mit
  `werkzeuge/rundgangprobe.gd`). Der Portalraum nutzt denselben Ablauf
  mit eigenen Blicken. Eigener Viewport, weil sich die
  Sichtweiten je Viewport merken, was zuletzt zu sehen war (der Rand
  wirkt als Hysterese): Fuhr die Spielkamera selbst, standen bei 70 m
  danach Kronen im Bild, die dort sonst fehlen. Der Viewport übernimmt
  MSAA, 3D-Skalierung, HDR und den Schattenatlas der Punktlichter, also
  alles, was die Shaderfassung bestimmt. Das Hauptbild zeichnet solange
  kein 3D (`disable_3d`) – es läge ohnehin hinter dem Ladeschirm. Der
  Compatibility-Renderer übersetzt jede Shaderfassung erst beim ersten
  Zeichnen, mit Nebel, Schattenstufen, Instanzen und Lichtern, wie das
  Objekt gerade steht; ohne Rundgang fiel das beim Laufen an, genau wenn
  Neues ins Bild kam (siehe „Ladezeit und Ruckler"). Danach
  `Rundgang.ausklingen(self)`: zwei Bilder, in denen das Hauptbild wieder
  zeichnet, dann `Effekte.vorwaermen(self)` für die Teilchen und für
  alles in der Gruppe `Effekte.VORWAERM_GRUPPE` – Netze, die bis zum
  ersten Gebrauch verborgen sind und die der Rundgang darum nie sieht
  (Schutzgeist bei Stufe 0, Spin-Ring, der Wegweiser im Portalraum): je
  ein winziger Abklatsch vor der Kamera –, dann noch zwei Bilder. Vorher
  blendete der Ladeschirm gleich nach `Effekte.vorwaermen` aus, und die
  beiden ersten Bilder darunter kosteten in Level 01 1,6 und 1,1 s
  Rechenzeit (Handyweg, llvmpipe), jetzt höchstens 81 ms. Dann
  `_vor_dem_start()`: Dort gibt ein Level frei, was von selbst läuft
  (Level 06 die Gegnerkarts – sie fuhren während des Rundgangs sonst
  sekundenlang voraus). Erst danach bekommt die Figur ihre Physik zurück
  und die Uhr des Zeitmodus läuft an. Headless entfällt der Rundgang;
  `Rundgang.an = false` schaltet ihn zum Vergleichen ab.
  Explosion und Lichtsäule des Zielportals wärmen ihre Shader selbst vor.
- **Bauzeiten:** `bauzeiten` hält die Dauer jedes Bauschritts, des
  Abschlusses und des Rundgangs (`[{"text", "ms"}]`), gelesen von
  `werkzeuge/bauzeitprobe.gd`.
- Das Wackeln beim Bauchplatscher und den Bildblitz beim Tod löst die
  Figur selbst aus; Level müssen dafür nichts verbinden.

**Wichtig:** Position immer *vor* `add_child()` setzen. Gegner merken
sich in `_ready()` ihre Startposition für die Patrouille – wird die
Position erst danach gesetzt, springen sie zum Ursprung zurück.

Props werden als Szene instanziiert (`preload(".../Baum.tscn").instantiate()`),
nicht über `Baum.new()`.

## Ladezeit und Ruckler (`scripts/bauspeicher.gd`, Rundgang)

Gebaut für die Meldung vom Pixel 8 (APK): „Level lädt lange, und bei
Bewegung scheint es vor- und nachzuladen; hat man eine Richtung
eingeschlagen, passt es erstmal." Beides ist gemessen, nicht vermutet.

**Messwerkzeuge** (Aufruf im Kopf der Dateien, Werte in README.md):
- `werkzeuge/bauzeitprobe.gd` – headless; lädt Level 01 und den
  Portalraum und druckt Laden, Instanziieren und jeden Bauschritt
  (`bauzeiten` von Level und Portalraum). Zweimal mit demselben
  `XDG_DATA_HOME` gestartet, zeigt der zweite Lauf den Stand mit
  gefülltem Bauspeicher.
- `werkzeuge/ruckelprobe.gd` / `ruckelprobe.sh` – unter Xvfb; fährt
  dieselbe Zickzackfahrt zweimal und meldet jedes Bild, das deutlich über
  dem Median liegt. Ruckler nur im ersten Durchgang sind Arbeit beim ersten
  Gebrauch, Ruckler in beiden Arbeit in jedem Bild. Im Portalraum
  (`RUCKEL_LEVEL=res://scenes/hub/Hub.tscn`) dreht sich die Figur erst auf
  der Stelle und läuft dann den Hallenbogen ab, in jeden offenen Raum an
  allen fünf Toren entlang, vor jedem versiegelten bis ans Siegel; der
  Spielstand „mitte" (`RUCKEL_STAND`) stellt jede Art Tor einmal hin.
  `RUCKEL_BESUCHE=2` baut die Szene zweimal nacheinander (der Portalraum
  wird nach jedem Level neu betreten). Gezählt wird neben der echten
  Bildzeit die Rechenzeit des Prozesses aus /proc (`RUCKEL_MASS=cpu`):
  Auf dem geteilten Rechner lief oft ein zweiter Godot mit, und die
  echten Bildzeiten zeigten dann in beiden Durchgängen Dutzende Ausreißer
  (71 und 2 in einem Lauf, 57 und 44 in einem anderen); die Rechenzeit
  des Hauptfadens nicht. Mesas eigener Shader-Speicher in `~/.cache` ist
  dabei aus (`MESA_SHADER_CACHE_DISABLE`), sonst übersetzte ein zweiter
  Lauf kaum noch etwas – wie ein erster Start nach der Installation.
- `werkzeuge/rundgangprobe.gd` – headless, ohne Zeichnen: Liegt jedes
  sichtbare Objekt einer Szene in wenigstens einem Blick ihres Rundgangs
  (`rundgang_blicke()`), auf einer gezeichneten Ebene und innerhalb seiner
  Sichtweite? Sichtkegel im Seitenverhältnis 16:9 der Projekteinstellung
  (headless ist das Fenster quadratisch, ein schmalerer Kegel meldete
  Dutzende Kisten als ungesehen). Portalraum 346 von 346, Level 21 1148
  von 1148, Level 01 745 von 748 (zwei leere Farn-Sammelnetze und eine
  Krone, die von jedem Halt gut 200 m weit weg liegt – hinter der
  Fernebene der Kamera). Die Gabelung in Level 21 ist darum kein Nebenweg
  für `_rundgang_pfade()`: Galerie und unterer Weg liegen neben demselben
  Verlauf und sind von dort aus ganz im Bild.

**Ruckler.** Ohne Vorwärmen gab es im ersten Durchgang 16 Ruckler (bis
2,9 s unter llvmpipe), im zweiten einen: Es war das Übersetzen von
Shaderfassungen, sobald etwas Neues ins Bild kam – genau das „Nachladen
bei Bewegung". Kein Skript baut beim Laufen etwas neu auf. Abhilfe ist
der Rundgang in `LevelBasis` (siehe „Level"): Danach war das längste Bild
im ersten Durchgang 0,43 s statt 2,9 s – so lang wie die Ausreißer im
zweiten, die von den geteilten Kernen kommen –, und das erste Bild nach
dem Ladeschirm sank von 14 s auf 0,16 s. Der Rundgang selbst dauerte
unter llvmpipe 16,5 s, fast nur Übersetzen, das vorher beim Spielen
anfiel. Gerendert nachgeprüft: Am Rechner sieht Level 01 bei 4, 70 und
176 m gleich aus (mittlere Abweichung 0,5 bei gleicher Spielzeit,
innerhalb des Rauschens bewegter Gegner).

**Ruckler im Portalraum.** Der Portalraum wärmte nur die Teilchen vor;
was vom Startplatz aus nicht zu sehen war, übersetzte der Renderer erst
beim Hinlaufen. Gemessen mit der Ruckelprobe (Handyweg, 640 × 360,
Stand „mitte", Rechenzeit des Hauptfadens; vorher = b837a09): im ersten
Durchgang 3 Ruckler bis 721 ms (in einem zweiten Lauf 14 bis 649 ms),
im zweiten keiner. Seit dem Rundgang (siehe „Portalraum") keiner mehr
im ersten Durchgang, das längste Bild 40 ms. Beim zweiten Besuch kam
vorher an derselben Stelle wieder ein Ruckler (342 ms), jetzt keiner.
Der Ladeschirm steht dafür länger: unter llvmpipe 28,6 s statt 27,3 s
beim ersten Besuch – das Übersetzen fiel vorher zum großen Teil schon in
die ersten Bilder unter dem Ladeschirm – und 5,3 s statt 4,2 s beim
zweiten. Am Rechner zeigen die Orbitbilder 0–270° dieselben Draw-Calls
wie vorher; auf dem Handyweg sparen die Schatten (eine Stufe) bis 53
(Orbit 90: 519 → 466, auf der Fahrt höchstens 483 → 454). Der Rundgang
belegt einmalig 2 MB Grafikspeicher mehr (86,1 → 88,2 MB im Orbitbild,
auch mit nur einem Blick, und auch mit halb so breitem Viewport); über
drei Besuche hintereinander blieb es bei 63,1 MB.

**Ladezeit.** Die Zeit verteilt sich über gut 50 Bauschritte; den größten
Einzelposten trugen die Bildpunktschleifen der Texturen (Waldweg allein
0,6 s), danach die Netze von Kronen und Stämmen. Beides liegt nach dem
ersten Laden im **Bauspeicher**:

```gdscript
Bauspeicher.holen(schluessel, erzeuger) -> Resource     # Image, Textur, Material …
Bauspeicher.wert(schluessel, erzeuger) -> Variant       # Dictionary usw., als Metadaten
Bauspeicher.netz(art, argumente: Array, erzeuger) -> ArrayMesh
```

- Ordner `user://bauspeicher`, je Eintrag eine komprimierte `.res`.
  Geschrieben wird erst in eine Zwischendatei, dann umbenannt; was sich
  nicht lesen lässt, wird neu gerechnet.
- **Fassung:** md5 über alle Skripte unter `res://scripts`,
  `res://scenes`, `res://autoload` (wie sie im Paket liegen, im Export die
  `.gdc`) und die Engine-Version. Ändert sich daran etwas, wird der ganze
  Ordner beim ersten Zugriff geleert. Darum muss niemand eine
  Versionsnummer pflegen – aber der **Schlüssel** muss alles nennen, was
  sich zur Laufzeit ändern kann (Farben, Größen, `Effekte.reduziert`).
  `Bauspeicher.netz` bildet ihn aus `var_to_str(argumente)`; Argumente mit
  Objekten werden nie gespeichert.
- Darin liegen: die Texturmaterialien und Strukturen der
  `Materialbibliothek` (`_hole(…, platte = true)`), die Farbbilder der
  Varianten (Normal-, Rauheits- und Verdeckungskarte bleiben mit der
  Struktur geteilt), Weltrauschen und Rasentextur der `Wegmaske`, das
  Blattbild der `Kronenwolke`, der Wurzelvorhang des Weltenbaums und die
  Netze von `Kronenwolke.netz`, `Riesenstamm.netz`/`liegend`,
  `Farnwerk.netz`, `Findling.netz`/`brocken` und `Weltenbaum.krone`. Für
  Level 01 und den Portalraum rund 400 Dateien, 20 MB.
- **Nicht** hinein gehört, was schneller gebaut als gelesen ist
  (einfarbige Materialien, kleine Netze) und was Godot selbst nachlädt
  (`NoiseTexture2D` speichert nur ihre Einstellungen).
- `Bauspeicher.an = false` schaltet ihn ab (Vergleich). Die Prüfwerkzeuge
  laufen mit leerem `user://` und rechnen also alles.

## Level 01 (`scenes/levels/level01.gd`, `class_name Level01`)

Level 01 ist seit dem Neubau anders gebaut als die übrigen Level: Die
Szenendatei `level01.gd` hält **alle Daten** als Konstanten (Verlauf
`PUNKTE`, `ABSCHNITTE` mit Welt-Höhe je Abschnitt, Ränder, Bach,
`BEGEHBARES`, Leitlinien, Todeszonen, Kisten, Gegner, Früchte) und bietet
Abfragen darauf an (`breite_bei`, `boden_bei`, `rand_bei`, `rand_profil`,
`ist_luecke`, `weg_von_der_kante`, `pruefprofil`). Die Optik bauen Module
in `scenes/levels/level01/`, je eine Klasse mit statischen Funktionen und
dem Parameter `level: Level01`:

| Modul | Aufgabe |
|---|---|
| `L01Boden` | Wegdecke ohne Bordstein (`shaders/wegboden.gdshader`), Lückenlippen |
| `L01Saum` | Kanten und Felswände als modellierte Profile (`GelaendeSaum`, `fels_schichten`) |
| `L01Gelaende` | Tal als Höhenfeld ohne Kollision (`GelaendeFeld`), `hoehe(x, z)` |
| `L01Wasser` | Bach, Furt, zweistufiger Wasserfall (`Wasserfall.band`) |
| `L01Weltenbaum` | der Riese, die Wurzelwendel, Kronentor (`Weltenbaum`) |
| `L01Wegbauten` | Setpieces am Weg: Wurzelnest, Geländer (`Totholzzaun`), Kanzel, Pforte, Furtsteine |
| `L01Wald` | Wald in drei Tiefen (`Waldsetzer`) |
| `L01Rasen` | Rasensaum, Bodenstreu, Rahmenfarne (`Rasensaum`, `Bodenstreu`) |
| `L01Stimmung` | Licht, Nebel, Lichtschächte, Laub, Vögel (positionsabhängiger Regler statt `Stimmungszone`) |

`bauschritte(level)` liefert `[{"text", "tun": Callable}]`; `level01.gd`
hängt die Schritte in fester Reihenfolge an. `optik(level, eintrag)` bekommt
einen Eintrag aus `BEGEHBARES` und liefert die Optik **passgenau zur
Kollision** – die Kollision baut allein `level01.gd`, die Module bauen
keine. Fehlt eine Optik, steht ein grauer Platzhalter.

**Wiederverwendbare Bauteile** (Schnittstelle jeweils im Kopfkommentar):
`Riesenstamm`, `Kronenwolke`, `Findling` (Optik genau auf einem
Kollisionskasten), `Farnwerk` (Farne ohne Alpha), `Rasensaum`,
`Bodenstreu`, `Totholzzaun`, `Weltenbaum`, `Wasserfall.band`
(`scenes/props/`); `Wegmaske` (CPU-Maske = GPU-Maske für Weg und Halme),
`GelaendeSaum`, `GelaendeFeld`, `Waldsetzer` (`scripts/`); die Shader
`wegboden`, `fels_schichten`, `gelaende` mit den Includes
`wald_gemeinsam.gdshaderinc` und `fels_gemeinsam.gdshaderinc`.
Die Werkstatt zeigt sie einzeln (Station 20–29, `werkstatt.gd`), jedes so
aufgerufen, wie sein Kopfkommentar es beschreibt; der Weltenbaum steht dort
im Maßstab 1:8, `GelaendeFeld` und `Wegmaske` nur mittelbar (die Halme
lesen die Maske, das Höhenfeld fehlt).
`Fremdmodelle.netz()` verschmilzt CC0-Modelle aus `assets/modelle/natur2/`
zu MultiMesh-tauglichen Netzen (Felsen, Stümpfe, Moosstämme),
`Fremdmodelle.baum()` macht aus einem Modellbaum Netze im Format der
prozeduralen Bäume (siehe unten „Modellbäume"). Welche Rolle welches
Modell trägt, steht in `Fremdmodelle.ROLLEN`; fehlt eine Datei oder ist
`Einstellungen.fremde_modelle` aus, fällt jedes Bauteil auf seinen
prozeduralen Rückfall zurück.

**Modellbäume** (`Fremdmodelle.baum(name, {hoehe, unten, …})`, Quaternius
Ultimate Nature Pack in `natur2/unp/`). Aus der Datei kommt nur die Form,
der Rest aus dem Wald, damit Modell- und prozedurale Bäume dieselbe
Zeichnung teilen:

| Netz | Format | Stoff |
|---|---|---|
| `stamm` | wie `Riesenstamm` (COLOR: Verdeckung, Alpha Moos; UV2: Art, Nordmoos), Normalen geglättet, auf 1200 Dreiecke ausgedünnt, Fuß 1 m in den Boden | `Riesenstamm.borkenstoff({"welt": true})` – Weltprojektion, die Modelle haben keine brauchbaren UV und keine Tangenten |
| `krone` | wie `Kronenwolke` (COLOR: Verdeckung, Alpha Wind; UV2.y Höhe in der Krone), Normalen zur Kronenmitte gebogen, nach unten gestreckt bis `unten` · Höhe (höchstens 1,6-fach), 30–160 eigene Blattkarten | `Kronenwolke.stoff()` |
| `fern` | Krone ohne Karten und Stamm dunkel im Kronenformat, ausgedünnt auf 360 Dreiecke, dazu 24 große Karten | `Kronenwolke.stoff(farbe, false)` |

Alle drei liegen im `Bauspeicher` (`fremdbaum_*`, Schlüssel: Pfad und
Optionen). Level 01 setzt sie über `L01Wald._modellbaum` im nahen
Talwald (M3, Höhe und Kronenansatz der Rückfallformen), in den hinteren
Reihen des Hangwalds (M1, eigene Stammart „m_stamm" mit Schatten) und
als Totholz im Tal (M17); der Talwald zeichnet seine Stämme dann ganz in
Weltborke. Der ferne Talwald bleibt prozedural: Aus 100 m lasen sich die
kantigen Modellkronen als schwebende Platten. Am Fuß der Hainbäume liegen
Felsen, Stümpfe und Moosstämme (M8, M16, `_bodenstueck`) – gesetzt, wenn
alle Haine stehen, nach dem Ort gestreut (`_streu`), damit die Würfelfolge
des Walds unverändert bleibt; ohne Schatten, MultiMesh je Modell, Zellen
zu 96 m, Sicht 70 m, im Web jedes zweite.

**Prüfungen nur für Level 01** (Opt-in über `pruefprofil()` bzw.
`sprungfaelle()`): `level_check.gd` prüft zusätzlich Kamerasicht, Gefälle,
Todeszonen-Überschneidung, Ränder und Nähte; `werkzeuge/Sprungprobe.tscn`
(in `pruefe.sh` Stufe 4) prüft, ob jeder Pflichtsprung trägt;
`werkzeuge/Wegmaskenprobe.tscn` vergleicht CPU- und GPU-Wegmaske.

Den Bauplan mit allen Maßen hält `doku/level01-neubau.md` fest.

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
- **Waldsaum und Raumbäume** (`_umland_modellwald`, `_raumbaum`): Hinter
  der Nordmauer stehen in zwei Reihen Modellbäume aus natur2
  (`Fremdmodelle.baum`, wie in Level 01), Art und Laubfarbe nach dem Raum
  davor (Wurzelwald Laub, Nebelsümpfe Moos und Totholz, Steinfeste Nadeln
  im Frost, Rost und Ranken Dschungel, Sand und Neon kahl); die Laub- und
  Nadelbäume in Wurzelwald und Rost und Ranken sind dieselben Modelle mit
  schmalen Kronen. Alle zusammen sind EIN `Waldsetzer` mit je einem Netz
  für Stämme und Kronen hinter der Mauer (ohne Schatten) und in den Räumen
  (Stamm mit Schatten, die Krone wirft den ihrer Fernfassung). Ein Raumbaum
  behält die Kollision des Kenney-Baums, den `Baum` dort setzte (Zylinder,
  Radius 0,055 · Höhe · Stärke, 60 % der Höhe). Ohne Modelle baut alles wie
  vorher (`Baum`).
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
- **Laden und Vorwärmen** (`_vorwaermen_und_zeigen`): Der Saal entsteht
  in `_ready()` in einem Zug; danach dieselbe Schattenregel wie in jedem
  Level (`LevelBasis.schatten_regel`: im Web zwei Stufen bis 60 m, auf
  dem Handy eine orthogonale bis 50 m – am Rechner bleibt alles, wie es
  war). Unter dem Ladeschirm folgt der Rundgang (`Rundgang`, siehe
  „Level") mit den Blicken aus `rundgang_blicke()`: die Folgekamera, wie
  sie über der Figur stünde – am Startplatz (zuerst; das erste Bild nach
  dem Ladeschirm), alle 10° auf dem Hallenbogen, in jedem offenen Raum
  links, mittig und rechts an der Portalreihe, vor jedem versiegelten am
  Siegel. Die Kamera schaut im Portalraum immer gleich nach Norden, also
  entscheidet nur der Platz, was ins Bild kommt; 19 Blicke bei einem neuen
  Spiel, 23 bei drei offenen Räumen, 27 bei allen. `werkzeuge/rundgangprobe.gd`
  prüft, dass jedes sichtbare Objekt in einem Blick liegt (346 von 346,
  Stand „mitte"); verborgen bleiben nur die Levelnamen über den Toren, und
  die nutzen dieselben Stoffe wie die Nummern. Den Wegweiser, der erst
  einblendet, wärmt `Effekte.VORWAERM_GRUPPE` vor, die Iris-Blende des
  Tors ein Bildpunkt unter dem Ladeschirm (`_iris_vorwaermen`). Danach die
  Teilchen (`Effekte.vorwaermen`, Lichtsäule und Ring der Ankunft), zwei
  Bilder, Ausblenden, `aufbau_fertig`. Die Figur ist dabei gesperrt
  (`Spieler.gesperrt`, gesetzt in `_spieler_setzen`): Schwerkraft ja, keine
  Eingabe – Tastatur und Touch-Stick (`_input`) erreichen sie sonst auch
  unter dem Ladeschirm, und wer beim Laden vorwärts hielt, lief während
  des Rundgangs ungesehen durch die Halle bis in ein offenes Tor. Frei
  wird sie erst kurz vor dem Ausblenden (`_spieler_freigeben`: Tempo auf
  null, `InputHub.zuruecksetzen()`), wie im Level. Der Rundgang läuft
  bei jedem Besuch: Beim zweiten Besuch der Sitzung übersetzte er keinen
  Shader mehr, ließ man ihn aber weg, kam derselbe Ruckler wieder (Zahlen
  unter „Ladezeit und Ruckler").
- **`aufbau_fertig`** kommt mit dem Ausblenden des Ladeschirms, wie im
  Level; Fotos und Proben warten darauf. `bauzeiten` hält Aufbau und
  Vorwärmen.
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
- **`Effekte.reduziert`** halbiert die Mengen und schaltet Wackeln, Trefferpause, Bildblitz und Blitzlicht ab. Vorbelegt ist es auf Handys: im Browser (`web_android`, `web_ios`) und als App (`mobile`). Früher fragte es nur nach dem Browser; die APK lief auf dem Rechnerweg (volle Dichten, zwei Schattenstufen, MSAA).
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

**`project.godot` kommentiert nur mit `;`.** `#` ist dort KEIN
Kommentarzeichen: Die Zeile wird Teil des nächsten Schlüssels, dessen Wert
unter einem Unsinnsnamen landet, und die gemeinte Einstellung bleibt still
auf der Vorgabe. So stand `common/physics_interpolation=true` lange unter
einem `#`-Block – gelesen wurde `physics/#DerSpieler…common/physics_interpolation`,
die Interpolation war aus. Begründungen stehen deshalb vor allem hier; die
`;`-Zeilen in der Datei verwirft der Editor beim Speichern ohnehin. Nach
jeder Änderung nachsehen, was wirklich gilt:
`ProjectSettings.get_setting("physics/common/physics_interpolation")`.

| Einstellung | Rechner | Browser (`.web`) | Handy-App (`.mobile`) | Warum |
|---|---|---|---|---|
| `rendering/anti_aliasing/quality/msaa_3d` | 1 (2x) | 1 (2x), Handy 0 | 0 | Glättet Stacheln, Kisten- und Wandkanten. Kostet rund 14 MB Grafikspeicher bei 720p, gut 30 MB bei 1080p, keine Draw-Calls. Handys im Browser (`Effekte.reduziert`) schaltet `Einstellungen._ready()` zur Laufzeit ab – dort zählt die Füllrate; die App hat es schon in der Projektdatei aus. |
| `rendering/lights_and_shadows/directional_shadow/size` | 4096 | 2048 | 2048 | 16 statt 64 MB. Level 01 sieht in der Nahansicht fast gleich aus. |
| `rendering/scaling_3d/scale` | 1,0 | 1,0 | 0,8 | Ein Pixel 8 zeichnet sonst 2400 × 1080 Bildpunkte, mit Gras, Farnen und Nebel – das ist die Füllrate, an der Handys hängen. 0,8 spart gut ein Drittel der Bildpunkte; HUD und Menüs bleiben scharf (2D). Gerendert nachgeprüft: Der Compatibility-Renderer skaliert bilinear. |
| `rendering/textures/default_filters/anisotropic_filtering_level` | 2 (4x) | 2 (4x) | 1 (2x) | Schräg gesehene Böden (Weg, Hänge) holen weniger Texel; auf dem kleinen Schirm nicht zu sehen. |
| `application/run/max_fps` | 0 | 0 | 60 | Bei 120 Hz wechseln sonst 8- und 17-ms-Bilder, sobald ein Bild länger braucht; dazu wird das Gerät warm und drosselt. |

Die Überschreibungen `.mobile` gelten nur in der App. Am Rechner stellen
`FOTO_REDUZIERT=1` (`foto.gd`, Handy im Browser) und `RUCKEL_REDUZIERT=1`
(`ruckelprobe.gd`, App samt 3D-Skalierung) den Handyweg nach.

**Kein FXAA.** `screen_space_aa` gibt es unter gl_compatibility nicht: Godot
4.7.2 meldet „Screen-space AA is only available when using the Forward+ or
Mobile renderer" und lässt die Einstellung fallen. Handys im Browser
zeichnen deshalb ungeglättet.

**Sonnen prüfen.** `.tscn` speichert eine `Transform3D` zeilenweise (Zeilen
der Basis, nicht Spalten). Ein abgeschriebener Wert lässt das Licht leicht
von UNTEN kommen – Level 01 war so nur vom Umgebungslicht beleuchtet. Probe:
`-licht.global_transform.basis.z` ist die Laufrichtung des Lichts, ihr y
muss negativ sein. `python3 werkzeuge/lichtprobe.py` rechnet das für jedes
`DirectionalLight3D` in jeder Szene nach (Richtung, Höhe, Azimut der Quelle,
Energie) und endet mit Rückgabe 1, sobald ein schattenwerfendes Licht von
unten kommt. Lichter, die erst ein Skript baut, sieht es nicht.

Level 02–10, 23–25 und die Werkstatt trugen dieselbe abgeschriebene Sonne,
`Transform3D(0.6, 0, -0.8, -0.71552, …)`: Licht 32° von unten. Gemeint war
die Basis spaltenweise; transponiert steht die Sonne 63° hoch von rechts
hinter der Kamera (Lichtrichtung −0,36/−0,89/−0,27 – genau die
Vorgaberichtung des `Lichtschacht`). Seitdem liegt Sonne auf den Wegen, und
die Level werfen zum ersten Mal Schatten. Wo der Weg dabei ausbrannte, ist
die Sonne schwächer: Level 02 (Schnee) 1,9 → 0,9, Level 05 1,6 → 1,3,
Level 24 (Nacht, Mondlicht) 0,75 → 0,5. In Level 23 dimmt der `Lichtkreis`
die Sonne ohnehin auf 10 %.

Die übrigen Szenen folgten in Runde 4; seitdem meldet die Lichtprobe kein
Licht mehr von unten. Azimut = Richtung zur Quelle, 0° = +Z (hinter der
Kamera, solange der Weg nach −Z läuft), +90° = rechts. Höhe vorher war
negativ, also unter dem Horizont:

| Szene | Licht | vorher | nachher | Energie |
|---|---|---|---|---|
| Level 11 | Sonne | −18°, aus +59° | 32°, aus −55° (links hinten) | 1,0 → 0,7 |
| Level 12 | Hallenglut | −50°, aus −32° | 55°, aus +20° | 0,5 → 0,3, Farbe kühl-neutral (0,85/0,88/1) statt orange |
| Level 14 | Sonne | −38°, aus −39° | 45°, aus +30° | 0,95 → 0,2; Belichtung 1,0 → 0,6 |
| Level 16 | Sonne | −18°, aus −57° | 60°, aus +53° | 1,45 → 1,05 |
| Level 17 | Mondlicht | −18°, aus −57° | 50°, aus −110° | 0,8 → 0,25, Farbe blauer (0,45/0,62/1) |
| Level 18 | Sonne | −21°, aus −77° | 60°, aus −110° | 1,8 → 0,25; Belichtung 1,34 → 1,2 |
| Level 19 | Sonne | −14°, aus −101° | 53°, aus +107° (rechts) | 2,2 → 0,45 |
| Level 20 | Sonne | −34°, aus −47° | 45°, aus −100° | 0,85 |
| Level 21 | Sonne | −24°, aus −61° | 50°, aus +53° | 0,95 → 0,65 |
| Level 22 | Sonne | −25°, aus −52° | 37°, aus +46° | 0,9 → 0,55 |
| Testlevel | Sonne | −32°, aus −71° | 63°, aus +53° | 1,6 |

Der Azimut ist meist der der transponierten Basis, also der gemeinte.
Ausnahmen sind Level 17, 18 und 20 (unten) und Level 19. Die Höhe ist dort
angehoben, wo sie zwischen hohen Wänden zu flach war:
Level 16 (Kanal) hatte transponiert 32°, Level 17 und 21 (Schluchten) 32°
bzw. 42°; der Weg lag dann großteils im Schatten der Wände.

Level 19 war keine reine Zeilenabschrift – auch transponiert lief das
Licht nach oben (+0,8). Die Höhe ist dort gespiegelt: Die Quelle steht
jetzt rechts, und der Weg, der nach links abbiegt, liegt auf 13 % seiner
Länge im Gegenlicht statt auf 40 % mit der waagerechten Richtung des alten
Werts (aus den Kontrollpunkten von `_verlauf_anlegen` nachgerechnet).

Die Energien sind am Bild gestimmt, je Level drei Aufnahmen (`foto.sh
verfolger` bei 40 m, Mitte und rund 80 %, Level 22 `orbit` aus der Höhe
des Fliegers, das Testlevel `orbit`), mit der Stimmungszone der Stelle.
Mittlere Helligkeit (`kontaktbogen.py`, Luma 0–255), vorher → nachher:
Level 11 85/58/96 → 123/92/111, Level 12 67/40/85 → 82/42/84, Level 14
207/207/210 → 210/209/214, Level 16 22/16/19 → 51/24/21, Level 17
105/101/99 → 126/111/108, Level 18 119/85/64 → 135/91/90, Level 19
60/36/57 → 72/48/75, Level 20 73/60/68 → 65/54/64, Level 21 124/44/59 →
159/67/88, Level 22 192/187/187/201 → 199/198/190/189, Testlevel 42/41/43
→ 48/52/51. Die Zahlen gelten für die erste Fassung; die Nachbesserung
unten ändert sie für Level 12, 14, 16, 18 und 19. Die Draw-Calls ändern sich
je nach Stelle in beide Richtungen, weil die Schattenwerfer jetzt über dem
Bild liegen statt darunter. An einzelnen Stellen steigen sie deutlich, auch
auf dem Handyweg; eine Spanne für alle Stellen ist nicht gemessen.

Je Level, was dabei zählte:
- **Level 11, 18, 21:** Die alten Werte (1,0, 1,8, 0,95) waren für Licht
  von unten gestimmt, das den Weg nie traf. Von oben mit derselben Energie
  wurde das Bild bei 40 m deutlich heller (Level 11 85 → 131, Level 18
  119 → 142, Level 21 105 → 145), und in Level 11 kippten Früchte in der
  Sonne ins Gelbe; daher weniger Energie.
- **Level 12, `Hallenglut`:** derselbe Fehler, kein gewollter Ofenschein.
  Die Basis hat dasselbe Muster wie die abgeschriebenen Sonnen und ergibt
  transponiert 55° von oben hinter der Kamera. Die Lichtquellen des Levels
  hängen an den Wänden und ÜBER dem Weg (Rohrbündel, Querrohre, der Ofen in
  der Wand bei 222 m, kalte Lichtschächte in der Torhalle); unter dem Weg
  glüht nichts, die Abgründe sind dunkel. `level12.gd` verlangt das
  Wegblech als hellste Fläche im Bild – Licht von unten trifft es nie, und
  die „Zeichnung" des Ersatzlichts lag an Decken und Unterseiten. Im Bild:
  40 m 67 → 82; bei 270 m liegen die Schatten der Deckenträger als Streifen
  auf dem Hallenboden. Mit der alten orangen Farbe wurde die Torhalle
  wärmer (kühle Pixel 64 % → 42 %). `level12.gd` will sie aber als den
  einzigen kühlen Ort („Der kalte Anfang ist es, der das Glühen danach warm
  aussehen lässt"). Daher hat die `Hallenglut` jetzt eine kühl-neutrale Farbe
  (0,85/0,88/1) und die Energie 0,3. Das Glühen tragen die Glutlichter und
  der Ofen.
- **Level 14:** Der Steg liegt im Weiß ganz oben in der Tonkurve. Mit
  Sonne von oben brannte das Eis im Rutschsteg (90–160 m) weiß aus. Das
  bläuliche Eis ist aber das Spielsignal für „glatt“, und die Früchte
  kippten ins Blassgelbe. Die Stimmungszone 90–160 m setzt das
  Umgebungslicht dort fest auf 1,05 (`level14.gd`). Abhilfe: Belichtung
  1,0 → 0,6, Sonne 0,2. Damit Himmel und Dunst nicht grau werden, sind die
  Himmelsenergie (×1,125) und das Licht im Nebel (0,9 → 1,5) angehoben.
  Eis wieder hellblau, Früchte orange, Stege mit Schatten.
- **Level 16:** Mit 1,45 von oben kippten Früchte ins Gelbe und der dunkle
  Körper der Spinne wurde blass; 1,05.
- **Level 17, 18, 20:** Die Wege biegen nach rechts ab (+X). Mit dem
  transponierten Azimut (+53°, +65°, +37°) lag ein großer Teil im
  Gegenlicht. Gespiegelt auf −110°/−110°/−100° steht die Quelle hinter
  der Kamera, solange sie nach +X schaut.
- **Level 18:** Der helle Sandstreifen auf dem Weg brannte mit 1,1 aus,
  und die orange Frucht verschwand darauf (gleiche Farbe, gleiche Luma).
  Sonne 0,25, Belichtung 1,34 → 1,2: Der Streifen brennt nicht mehr aus.
- **Level 17 (Nacht):** Von oben wird der Schnee schnell weiß und
  neutral: Schon mit 0,4 und der alten Lichtfarbe sanken die kühlen Pixel
  von 91–94 % auf 51–73 %. Mit 0,25 und blauerem Licht sind es 75–90 %,
  der Schatten von Reiter und Tier liegt auf der Rinne.
- **Level 19 (Sturm):** Früher setzte der Blitz Sonne UND Umgebungslicht
  aufs Siebenfache. Mit der Sonne von oben brannte der Weg im Blitz weiß
  aus. Jetzt geht die Sonne im Blitz aus (`BLITZ_SONNE = 0`), und nur das
  Umgebungslicht steigt (`BLITZ_STAERKE = 7`). Ein Blitz erhellt den
  ganzen Himmel, sein Licht kommt von überall und wirft keine Schatten.
  Im Blitz sieht der Weg damit aus wie vor der Umstellung. Ruhende Sonne
  0,6 → 0,45.
- **Level 20:** Die Halle hat ein Dach; die Sonne trifft den Boden nur
  durch Lücken. Etwas dunkler als vorher, die Wände tragen das Licht.
- **Level 22:** Wolken und Berge sind Grau in drei Stufen, Farbe tragen
  nur die Ziele. Mit 0,9 von oben wurden die Wolkenoberseiten fast weiß;
  0,55 hält das Bild bei der alten Helligkeit.

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
