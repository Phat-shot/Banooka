# Nutzerentscheidungen P0 (verbindlich, gehen allen Entwürfen und dem Baukastenplan vor)

- R1 (L02): **Spurbindung in 2D: JA.** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt (Seitenanteil ≥ 0,5). Reine Steuerung, keine Physikänderung. CLAUDE.md bekommt dazu eine Zeile (Steuerung).
- R2 (L04): **tempo_max 19 → 15 und Rastplatz-Tempo: JA.** reiter.gd bleibt unverändert; Level04.tscn setzt tempo_max 15, das Level setzt an jedem Rastplatz tempo_start.
- R3 (L05): **Slide-Sprung als Kür: JA.** Slide unter Durchlässen ist Pflicht; der Slide-Sprung belohnt (Abkürzung/Geheimnis), wird nie erzwungen.
- R4 (alle): **Modellbudget: bis ~24 neue CC0-Modelle** (nicht nur 9). G4 übernimmt die volle Wunschliste aus den vier Entwürfen (dedupliziert, rund 24 Dateien, Quaternius/Kenney, CC0), Ersatzlösungen aus baukasten.md §4 Nr. 10 entfallen, wo das echte Modell kommt. .pck-Zuwachs messen und berichten.
- R5 (Figur cash_banooka_rc.glb): offen, wird separat mit dem Nutzer geklärt; die Datei wurde vom Nutzer selbst eingecheckt. Nicht anfassen.

---

# Gemeinsamer Baukasten für Raum 1 (Level 02–05)

**Stand:** HEAD 052641f (93b8816 plus `.gitignore`). Im Repo ist nichts geändert, gerendert wurde nichts. Alle Datei:Zeile-Belege habe ich in diesem Lauf im Code nachgelesen. Werte, die nur aus den Entwürfen stammen oder nicht gemessen sind, tragen den Vermerk **ungeprüft**.

## 0. Regeln

1. **In den Baukasten kommt nur, was mindestens zwei Entwürfe brauchen.** Alles andere bleibt im Levelpaket. Das gilt auch dann, wenn dieses Paket eine geteilte Datei berührt; dort gilt derselbe Wächter (§2).
2. **Level 01 bleibt wörtlich, wie es ist.**
   - `level01.gd` und `scenes/levels/level01/*` werden nicht angefasst. Der Baukasten kopiert den Code und verallgemeinert ihn (Stufe A der Technikkarte).
   - Geteilte Dateien bekommen nur Zusätze mit einem „Null-Pfad“: Ohne neuen Schalter läuft genau derselbe Ausdruck wie heute.
3. **Der Zustand gehört der Instanz.**
   - Kein neues `static var` für Levelzustand. Gegenbeispiel: wald.gd:304-347.
   - `GelaendeSaum` hält schon heute globalen Zustand (gelaende_saum.gd:65-70, :840-884). Jedes neue Level ruft deshalb beim Verlassen `GelaendeSaum.vergessen()` auf (:846).
4. **Ebenen stehen in den Daten nur als Bitwerte über Konstanten:**
   - 1: Decke, Boden, Kisten
   - 8: `LevelWerkzeuge.SICHTSPERRE` (level_werkzeuge.gd:22)
   - 16: `SPIELERGRENZE` (:1057)
   - Die Figur prüft 1|16, ihre Maske ist 17.
5. **Kollision in Variante b** (Technikkarte 2.3) für alle vier Level: eine Decke ohne Bordstein, Leitlinien auf Ebene 16.
   - Die Bordsteinkollision (level_werkzeuge.gd:136-146) fällt mit den alten Verläufen weg.
   - Der Neuentwurf der Pflichtwege ist vom Nutzer freigegeben.

---

## 1. Bausteine

### 1.1 Übersicht

Spalten 02–05: x = braucht den Baustein, (x) = teilweise.

| Baustein | Ort | Klasse | Quelle | 02 | 03 | 04 | 05 | Paket |
|---|---|---|---|---|---|---|---|---|
| Wegdaten | scripts/gemeinsam/wegdaten.gd | `Wegdaten` | level01.gd:913-1050, 1383-1460 | x | x | x | x | G1 |
| Zusätze im Korridor-Level | scenes/levels/korridor_level.gd | `KorridorLevel` | level01.gd:845-857, 1113-1173 | x | x | (x) | x | G1 |
| Duckdurchlass | korridor_level.gd | – | neu (Stützgerüst L03, Durchlass L05) | | x | | x | G1 |
| Level-Haken | scenes/levels/level_basis.gd | `LevelBasis` | neu | x | x | x | x | G1/G6 |
| `sicht_maske` | scripts/corridor_camera.gd | `KorridorKamera` | :334 | | | x | x | G1 |
| Probenfelder | werkzeuge/sprungprobe.gd, level_check.gd, foto.gd | – | – | x | x | | x | G2 |
| Wegdecke | scripts/gemeinsam/wegdecke.gd | `Wegdecke` | boden.gd:52-160, :479 | x | x | x | x | G3 |
| Kanten | scripts/gemeinsam/kanten.gd, dazu gelaende_saum.gd | `Kanten` | saum.gd:323, :414, :718, :827, :862, :1306, :1349, :1792 | x | x | (x) | x | G3 |
| Geländerahmen | scripts/gemeinsam/gelaende_bau.gd, shaders/nebeltafel.gdshader | `GelaendeBau` | gelaende.gd:215, :263-295, :407-430 | x | x | x | x | G3 |
| Bachband | scripts/gemeinsam/bachband.gd, shaders/bach.gdshader | `Bachband` | wasser.gd:135, :308, :363, :426 | | x | (x) | x | G3 |
| Nebelstoff | scripts/gemeinsam/nebelstoff.gd | `Nebelstoff` | weltenbaum.gd:436-450 | x | x | | x | G3 |
| Waldrahmen, Baumfabrik | scripts/gemeinsam/waldrahmen.gd, baumfabrik.gd | `Waldrahmen`, `Baumfabrik` | wald.gd:461-750, :776-1219, :2229, :2657 | x | x | x | x | G4 |
| Rasenbau | scripts/gemeinsam/rasenbau.gd | `Rasenbau` | rasen.gd:154-280, :439, :629, :661, :1227, :1340 | | x | x | x | G4 |
| 9 Modelle für Raum 1 | assets/modelle/natur2/unp/, `ROLLEN` in fremdmodelle.gd | – | – | x | x | x | x | G4 |
| Stimmungsregler | scripts/gemeinsam/stimmungsregler.gd | `Stimmungsregler` | stimmung.gd:120-139, :264-450 | x | x | x | x | G5 |
| Kameraplan | scripts/kameraplan.gd, dazu Kamera, LevelBasis, Rundgang, level_check | `Kameraplan` | neu | x | x | x | – | G6 |

Alle neuen Klassennamen sind noch frei; ein grep über alle `class_name` im Projekt findet keinen davon.

### 1.2 Weg und Spielunterbau (G1)

**Warum nötig:** `kiste()` und `gegner()` setzen ihre Objekte relativ zur Kurve (korridor_level.gd:695, :748), `boden_bei` gibt es nur in Level 01 (level01.gd:1422). level_check verlangt für die Opt-in-Proben `breite_bei` **und** `boden_bei` (level_check.gd:563).

```gdscript
# scripts/gemeinsam/wegdaten.gd – Abfragen und Bau aus level01.gd, ohne Level01-Typ
class_name Wegdaten extends RefCounted
var verlauf: Curve3D
var abschnitte: Array[Dictionary]   # Schema LevelWerkzeuge.korridor (level_werkzeuge.gd:85-101):
                                    # {von, bis, breite, breite_ende?, hoehe?, hoehe_ende?, stoff?}
var begehbares: Array[Dictionary]   # Schema level01.gd:389
var leitlinien: Array[Dictionary]   # Schema level01.gd:525
var todeszonen: Array[Dictionary]   # Schema level01.gd:571
var raender: Array[Dictionary]      # Schema level01.gd:249
func _init(kurve: Curve3D, daten: Dictionary) -> void
# Abfragen, Verhalten wie level01.gd:1383-1460
func abschnitt_bei(s: float) -> Dictionary
func breite_bei(s: float) -> float
func ist_luecke(s: float) -> bool
func rand_bei(s: float, sicherheit := 1.3) -> float
func boden_bei(s: float) -> float            # in Lücken linear zwischen den Kanten (level01.gd:1419-1439)
func ueber_kurve(s: float) -> float          # boden_bei(s) − Kurvenhöhe; für die kurvenrelativen Helfer
func weg_punkt(s: float, q := 0.0, h := 0.0) -> Vector3
func strang_bei(s: float) -> Vector2
func weg_von_der_kante(s: float, abstand: float) -> float
func luecken() -> Array[Vector2]
func rand_profil(s: float, seite: float) -> Dictionary
func begehbar(name: String) -> Dictionary
func oberkante(name: String, s: float, q: float) -> float
# Bau
func decke_bauen(eltern: Node3D, stoff_fuer: Callable) -> Node3D   # :913-941: Netz je Stoff + EINE Kollision mit stufen_kollision
func begehbares_bauen(eltern: Node3D, optik: Callable) -> Node3D   # :945-978
func leitlinien_bauen(eltern: Node3D) -> Node3D                    # :981-989, Ebene 16
func schultern_bauen(eltern: Node3D) -> Node3D                     # :1000-1050
func todeszonen_bauen(eltern: Node3D) -> Node3D                    # über LevelWerkzeuge.todeszone (:1147), Gruppe "todeszonen"
static func zonen_unter_boden(weg: Wegdaten, von: float, bis: float, q_von: float, q_bis: float,
		tiefe := 8.0, unten := 20.0) -> Array[Dictionary]        # „Boden − n“ als Einträge auf fester Höhe
func sprungfaelle_aus_luecken(landung_spiel := 0.45, bahnen: Array[float] = [0.0]) -> Array[Dictionary]  # Muster :1295-1367
```

```gdscript
# scenes/levels/korridor_level.gd – nur Zusätze. L06–L25 setzen `weg` nie (Null-Pfad).
var weg: Wegdaten = null
# abschnitte()/breite_bei()/rand_bei()/weg_von_der_kante() (:52-94):
# mit `weg` wird delegiert, ohne `weg` läuft der Code wie heute.
func boden_bei(s: float) -> float
func ist_luecke(s: float) -> bool
func weg_punkt(s: float, q := 0.0, h := 0.0) -> Vector3
func kiste_auf(art: Kiste.Art, s: float, q: float, ueber := 0.5, schwebt := false) -> Kiste
func frucht_auf(s: float, q: float, ueber := 0.9) -> Node3D
func fruechte_bogen_auf(von: float, bis: float, anzahl: int, q: float, scheitel := 2.6) -> void
func gegner_auf(szene: PackedScene, s: float, q: float, weite: float, quer: bool) -> Gegner  # gegner(:722) mit hoehe = ueber_kurve
func portale_auf(start: float, ziel: float) -> void
func kisten_orte() -> Array[Vector3]          # aus `objekte`; Kisten werden VOR Wald und Rasen gesetzt
func sichtweiten_einrichten(weiten := {}) -> void   # Kopie von level01.gd:845-857, 1136-1173; Vorgabe = L01-Werte
func duckdurchlass(s: float, tiefe: float, optionen := {}) -> StaticBody3D
	# Körper auf Ebene 16, von 0,95 bis 4,4 m über boden_bei, quer über die Wegbreite.
	# optionen: q_von, q_bis, unten, oben, stolperzone (nur an der Stirn, −0,15 bis +0,25),
	#           optik: Callable(s, tiefe) -> Node3D
func nach_tod_melden(knoten: Node) -> void    # in die Gruppe LevelBasis.NACH_TOD
```

```gdscript
# scenes/levels/level_basis.gd – Haken, deren Vorgabe „nichts“ ist
const NACH_TOD := "nach_tod"
func strecke_der_figur() -> float   # kamera_strecke_quelle(), sonst Kamera.strecke(), sonst get_closest_offset
# _zuruecksetzen (:544-567) ruft am Ende:
#   get_tree().call_group(NACH_TOD, "nach_tod", von_vorn)   – in Level 01 ist die Gruppe leer
```

```gdscript
# scripts/corridor_camera.gd – in G1 nur dieser Export, weil L05 ihn vor dem Kameraplan braucht
@export var sicht_maske := 1 | 8    # ersetzt das Literal in _freie_sicht (:334); Vorgabe = heute
```

**Probenhaken (Opt-in über `has_method`, nicht in LevelBasis):**
- `pruefruhe()` hält an, was von selbst läuft: den Keiler (L05), die Taktgefahren (L02) und die Stromuhr (L03, fester Wert).
- `foto_stelle(s, q) -> Vector3` liefert den Weltort der Figur. foto.gd setzt sie heute auf die Kurve + 1 m (foto.gd:246-252). Das ist falsch auf Terrassen (L03, L05) und auf dem Ritt (L04 setzt dort `strecke`).
- Bewusst **nicht** `weg_punkt`: Level 01 hat diese Funktion, foto.gd würde damit L01 anders setzen.

### 1.3 Stoffe, Kanten, Gelände, Wasser (G3)

```gdscript
# scripts/gemeinsam/wegdecke.gd – aus boden.gd; wegboden.gdshader bleibt unverändert
class_name Wegdecke
## thema: {boden_farbe, boden_normal, flanke, wurzelruecken, boden_kachel, rasen (null = Wegmaske),
##         rasen_kachel, uniforms: {name: wert}}
## Höchstens 8 Lücken je Stoff (wegboden.gdshader:79), Kronenlicht ≤ 24 Stellen (:69).
static func stoff(thema: Dictionary, weg: Wegdaten, abschnitte: Array, schluessel: String) -> ShaderMaterial
	# Zwischenspeicher je `schluessel` (Level+Thema+Gruppe), NICHT je Art wie boden.gd:44-57
static func lippen(eltern: Node3D, weg: Wegdaten, thema: Dictionary) -> Node3D   # boden.gd:152ff, Pilze :479
static func vergessen(praefix: String) -> void
```

```gdscript
# scripts/gemeinsam/kanten.gd – Rahmen und Profile aus saum.gd, ohne Level01
class_name Kanten
static func stoff(thema: Dictionary) -> ShaderMaterial   # = GelaendeSaum.stoff_variante(thema)
static func profil_boeschung(bogen: float, q_linie: float, kante_y: float, wegrand: float,
		krone_y: float, rinne: float) -> GelaendeSaum.Profil                    # saum.gd:1306
static func profil_ufer(bogen: float, kante_y: float, fuss_y: float, ueberhang: float) -> GelaendeSaum.Profil  # :827
static func profil_stirn(probe: Dictionary, kante_y: float, grund_y: float, halb: float,
		erdig: bool, innen := 0.45) -> GelaendeSaum.Profil                      # :1792
static func profil_ab(bogen: float, q_lippe: float, kante_y: float, fuss_y: float, ueberhang: float,
		platte: Callable) -> GelaendeSaum.Profil      # :718; _platte(s) wird als Callable übergeben
static func profil_wand(s: float, bogen: float, q_linie: float, kante_y: float,
		becken: Callable) -> GelaendeSaum.Profil      # :1349; _becken(s) wird als Callable übergeben
static func seite_schritte(eltern: Node3D, weg: Wegdaten, seite: float, linie_sq: PackedVector2Array,
		profil: Callable, stoff: Material, name: String, speicher: String) -> Array   # Stuecke :323, :414, Lippen :862

# scripts/gelaende_saum.gd – additiv
static func stoff_variante(thema: Dictionary) -> ShaderMaterial   # stoff() (:753) bleibt, wie es ist
```

```gdscript
# scripts/gemeinsam/gelaende_bau.gd – Schrittrahmen aus gelaende.gd:263-295, 407-430
class_name GelaendeBau
static func schritte(eltern: Node3D, schluessel: String, feld_bauen: Callable,
		stoff: Material, text := "Gelände") -> Array   # Schlüssel "<lNN>_gelaende_<voll|handy>"
static func stoff(thema: Dictionary) -> ShaderMaterial
static func nebeltafeln(eltern: Node3D, tafeln: Array, farbe: Color) -> ShaderMaterial
	# Shader wird aus der Zeichenkette NEBEL_SHADER_CODE (gelaende.gd:215) als Datei angelegt

# scripts/gemeinsam/bachband.gd + shaders/bach.gdshader (Kopie von BACH_SHADER, wasser.gd:135)
class_name Bachband
static func bauen(eltern: Node3D, laeufe: Array, stoff: ShaderMaterial) -> MeshInstance3D   # :308, :363, :426
static func stoff(thema: Dictionary) -> ShaderMaterial

# scripts/gemeinsam/nebelstoff.gd – aus weltenbaum.gd:436-450
class_name Nebelstoff
static func nebelarm(stoff: Material, umgebung: Environment, anteil: float) -> Material
```

### 1.4 Bewuchs und Modelle (G4)

```gdscript
# scripts/gemeinsam/waldrahmen.gd – Regeln aus wald.gd, das Auge kommt aus der echten Kamera
class_name Waldrahmen extends RefCounted
func _init(weg: Wegdaten, kamera: KorridorKamera, kisten: Array[Vector3]) -> void
func auge(s: float) -> Vector3   # statt wald.gd:631-637 (fest 9,5 m zurück / 6 m hoch); kann
                                 # abstand < 0 (L05: −21) und nutzt den Plan, sobald es ihn gibt
func wegabstand(x: float, z: float) -> float                     # Bahn :461-545, Bereich aus `weg`
func weg_frei(huelle: AABB, frei_q := 6.0, frei_h := 9.5) -> bool  # :646
func stamm_frei(fuss: Vector3, spitze: Vector3, r: float) -> bool  # :667
func kegel_frei(huelle: AABB) -> bool                              # :718
func kiste_frei(p: Vector3, abstand: float) -> bool                # :750
func einsinken(fuss: Vector3, hoch: float, hoehe: Callable) -> float   # :2657

# scripts/gemeinsam/baumfabrik.gd – aus wald.gd
class_name Baumfabrik
static func modellbaum(rolle: String, nadel: bool, wahl: float, hoehe: float, unten: float,
		ton := Color.WHITE) -> Dictionary                                   # :1017
static func fernbaum(k: int, farbe: Color) -> ArrayMesh                      # :1060
static func tannenkrone(radius: float, hoehe: float, stufen: int, seiten: int, karten: int) -> ArrayMesh  # :1121
static func hain(ws: Waldsetzer, rahmen: Waldrahmen, rng: RandomNumberGenerator,
		mitte: Vector2, arten: Array) -> void                               # :2229

# scripts/gemeinsam/rasenbau.gd – Kern aus rasen.gd
class_name Rasenbau extends RefCounted
func _init(eltern: Node3D, weg: Wegdaten, hoehe: Callable, optionen := {}) -> void   # dichte, sichtweite,
                                                                     # ×0,5 bei Effekte.reduziert, kisten
func decke(von: float, bis: float, seite: float, dichte: float) -> void            # :629
func boden(von: float, bis: float, seite: float, q_von: float, q_bis: float, dichte: float) -> void  # :661
func streu(s: float, q: float, art: String, mass: float) -> void                     # :439
func rahmenfarne(von: float, bis: float, seite: float, stoff: Material) -> void      # :1227
func fertig() -> Node3D                                                              # :1340
```

**Neue Modelle (Entscheidung §4, Nr. 10).** Heute liegen 16 UNP-Modelle in `natur2/unp/` (CREDITS.md:12), der Rahmen ist „rund 25“ (natur2/LIESMICH.md:22, :102). Für Raum 1 kommen genau diese 9 dazu, alle schon als .glb im Scratchpad `modelle/fbxprojekt/glb/`:

| Modell | Nutzer |
|---|---|
| `Willow_1`, `Willow_3`, `Willow_5` | L03 |
| `BirchTree_1`, `BirchTree_3` | L04, L05 |
| `Rock_1`, `Rock_3` | L02 (mit Schneemaske), L04, L05 (sandsteinfarben getönt) |
| `CommonTree_Dead_3` | L02, L04 |
| `WoodLog` | L03, L04 |

- Neue Einträge in `ROLLEN` sind rein additiv: `rolle()` sucht exakte Namen (fremdmodelle.gd:503-519). Rollen von L01 und Portalraum ändern sich deshalb nicht.
- Achtung: Birkenrinde heißt im Paket „White“ und läuft als Klasse `borke` (fremdmodelle.gd:362-365). Beabsichtigt, aber **ungeprüft** im Bild.

### 1.5 Stimmung (G5)

```gdscript
# scripts/gemeinsam/stimmungsregler.gd – aus stimmung.gd:264-450 (class Regler)
class_name Stimmungsregler extends Node
## Zone im Schema von stimmung.gd:120-139:
##   {name, von, bis, rand_von?, rand_bis?, nebel_faktor, licht_faktor, nebelfarbe, umgebungsfarbe,
##    oben?, kurve?, sonne_farbe?, sonne_faktor?}
## neu und freiwillig: nebel_beginn (m), rahmen (Bildrahmen.staerke, bildrahmen.gd:22),
##   rahmen_licht (:38), sonne_energie
static func anlegen(level: LevelBasis, zonen: Array, optionen := {}) -> Stimmungsregler
	# optionen: sonne, oben (Knoten), rahmen (Bildrahmen), nebelstoffe: Array[ShaderMaterial],
	#           uebergang := 8.0
func mischung(s: float) -> Dictionary
func neu_rechnen() -> void
# Die Strecke liest er über level.strecke_der_figur() statt über get_closest_offset
# (stimmung.gd:329) – an der Kreuzung von L04 entscheidet sonst die Nähe.
```

### 1.6 Kameraplan (G6)

**Befunde aus dem Code:**
- Heute überblendet nur `seitenblick` (corridor_camera.gd:403-411).
- `hoehe`, `abstand`, `blick_vorlauf` und `seiten_faktor` sind reine Exports, die Blickhöhe ist fest +1,0 (:442).
- Der Sichtstrahl prüft fest die Ebenen 1|8 (:334).
- `kamerazone()` schaltet über Area3D-Stücke von 12 m (korridor_level.gd:926-967). Den Ausfall an den Nähten (F1) hat die Kamera-Karte gemessen; ich habe den Code gelesen, aber nicht nachgemessen.

```gdscript
# scripts/kameraplan.gd
class_name Kameraplan extends RefCounted
const FELDER := ["hoehe", "abstand", "blick_vorlauf", "seiten_faktor", "blick_hoehe"]
const SEITE := ["seitlich", "seiten_hoehe"]       # eine Zone mit seitlich ≠ 0 ist eine Seitenzone
var grund: Dictionary                             # KorridorKamera.grundprofil()
var zonen: Array[Dictionary] = []                 # {name, von, bis, ein, aus, profil}
var decken: Array[Dictionary] = []                # {von, bis, y}, gemessen an der KAMERA-Strecke s − abstand
var min_blende_s := 0.6                           # wie die heutige Seitenblende 1/1,6 s (:67-71)
var tempo := 8.5                                  # Ritt: 15
func _init(grundprofil: Dictionary) -> void
func zone(name: String, von: float, bis: float, profil: Dictionary, ein := 6.0, aus := 6.0) -> Kameraplan
func decke(von: float, bis: float, y_max: float) -> Kameraplan
## w_i(s) = smoothstep(von−ein, von, s) · (1 − smoothstep(bis, bis+aus, s))
## Profil = grund + Σ w_i · (zone_i − grund); fehlende Felder nimmt die Zone vom Grund.
## Zustandslos: Nach einem Respawn steht sofort das richtige Profil.
func profil_bei(s: float) -> Dictionary
func seitenanteil_bei(s: float) -> float          # Σ w_i über die Seitenzonen
func decke_bei(kamera_s: float) -> float          # INF ohne Deckel
func blendfenster() -> Array[Vector2]
## Datenregeln: Σ w ≤ 1 (Ränder, die sich überlappen, decken sich genau), Fenster ≥ min_blende_s · tempo,
## abstand wechselt das Vorzeichen nie, keine Zone trägt fov.
func pruefen() -> PackedStringArray
```

```gdscript
# scripts/corridor_camera.gd – Zusätze; plan == null ⇒ dieselben Ausdrücke wie heute
var plan: Kameraplan = null
var strecke_quelle: Callable = Callable()   # liefert s der Figur; leer = get_closest_offset (:382)
func grundprofil() -> Dictionary            # die Exports; blick_hoehe 1,0
func profil() -> Dictionary                 # Profil an der geführten Stelle (Proben, Rundgang, Waldrahmen)
func strecke() -> float                     # _strecke
```

**Änderungen in `_folgen` (:366-461), nur mit gesetztem `plan`:**
- Das Profil wird an der geführten Stelle `strecke` gelesen (:382, höchstens 26 m/s, :361).
- `_fehlstrecke` rechnet mit dem `abstand` aus dem Profil (:220-224).
- `blick_hinten.y` wird zu `… + blick_hoehe` (:442).
- `mischung` ist der Seitenanteil. Kein zweites smoothstep: Das steckt schon im Gewicht w.
- `seitenblick` ist der gewichtete Mittelwert der Seitenzonen.
- `blick_seite.y` folgt der geglätteten Höhe statt `p.y` (:426).
- Danach gilt der Deckel: `wunsch.y = minf(wunsch.y, decke_bei(strecke − abstand))`.
- Das Sichtfeld wird nie gemischt (`_szenen_fov`, :259-264).

**Haken in LevelBasis** (beide in `_kamera_verbinden`, :403-415):
- `kameraplan() -> Kameraplan` mit Vorgabe null. Ist ein Plan da, setzt ihn das Level an die Kamera.
- `kamera_strecke_quelle() -> Callable` mit Vorgabe leer. Nur Level 04 liefert hier `_reiter.strecke`. **Nicht automatisch:** Figuren mit `strecke` gibt es auch in L06 und L17 (level_basis.gd:334-335).

**Rundgang:**
- Neu ist `static func blicke_plan(kurve: Curve3D, plan: Kameraplan, abstand_halte := 12.0) -> Array[Transform3D]`:
  - im Verfolger ±40° wie heute,
  - im Hoch- und im Seitenblick 0° und ±30°,
  - dazu ein Halt in jeder Blendmitte.
- `blicke_entlang` (rundgang.gd:146-165) bleibt unverändert. Der Portalraum ruft ihn über seine eigenen Blicke auf (hub.gd:565).
- `LevelBasis.rundgang_blicke` (:195-211) nimmt `blicke_plan` nur, wenn ein Plan gesetzt ist.

**Was nicht in den Baukasten kommt:**
- **Spurbindung in 2D** (Änderung an `_kamerarelativ`, player.gd:682-701): Sie braucht nur L02 und ändert die Steuerung. Sie kommt erst nach Rückfrage R1 und dann ins L02-Paket.
- **Richtungsanker:** Kein Entwurf braucht ihn (§4, Nr. 17).

### 1.7 Prüfwerkzeuge (G2, Kamerateil in G6)

**Sprungprobe** (sprungprobe.gd): neues Feld `art`. Ohne `art` läuft die Probe wie heute (:14-22), die Fälle von L01 bleiben unverändert.

| `art` | Ablauf | Nutzer |
|---|---|---|
| `einfach` (Vorgabe) | wie heute | alle |
| `doppel` | Doppelsprung nach `doppel_t` (Vorgabe [0,20; 0,25; 0,33] s); die Taste geht 1 Bild vorher los | 02, 05 |
| `slide`, `slide_doppel` | Slide `slide_vor` m vor dem Absprung | 02 (S5), 05 |
| `duck` | Fenster für den Slide-Druck vor einem Duckdurchlass; Stolpern zählt als Fehler | 03, 05 |
| `huerde` | Einzelsprung über eine Stolperzone | 05 |
| `ueberlauf` | ohne Sprung über eine Strecke laufen und lebend ankommen | 02 (Wechten) |
| `bewegt` | Landung auf einem bewegten Träger, danach `halt` Bilder den Stick halten | 03 |

- Weitere Felder: `fenster_min` (Vorgabe 1,25, :52), `tief_erlaubt` (Vorgabe `ZU_TIEF` 1,5, :55), `pflicht` (true) und `darf_nicht_tragen`.
- Die Fanglücke F1 von L02 wird damit zu zwei Fällen: `einfach` mit `darf_nicht_tragen` und `tief_erlaubt` 2,2, dazu `doppel`.
- Vor jedem Versuch wird `pruefruhe()` aufgerufen.

**level_check:**
- `pruefruhe()` vor der Sturzprobe (:425-445) und vor der Sichtprobe.
- Ab G6:
  - `_kamera_modell` (:712-745) liest das Profil aus dem Plan;
  - `SICHT_MASKE` (:81) kommt aus `_kamera.sicht_maske`, in L01 bleibt der Wert 1|8;
  - Opt-in-Probe `"kameraplan"`.

**Weitere Werkzeuge:**
- **foto.gd:** `foto_stelle` und `pruefruhe`, beide Opt-in.
- **Neu: `werkzeuge/kameraplanprobe.gd`**, dazu Stufe 4 in `pruefe.sh`. Die Probe läuft bei `^func kameraplan`, nach dem Muster von pruefe.sh:116-118.
- **Neu: `werkzeuge/baukastenprobe.gd` (headless).** Sie füttert die Bausteine mit den Daten von Level 01 und vergleicht mit den Originalen:
  - `Wegdaten` gegen `boden_bei`/`breite_bei`/`strang_bei`/`rand_profil` alle 0,5 m;
  - `Kanten.profil_*` gegen saum.gd;
  - `Waldrahmen.weg_frei`/`kegel_frei` gegen wald.gd;
  - `Stimmungsregler.mischung` gegen `L01Stimmung.Regler.mischung` an s 10/60/130/220.
  - Erwartet wird Gleitkomma-Gleichheit. So ist die Herauslösung ohne ein einziges Bild belegt.
- **schaufenster.sh:** Teil `wache` (§2).

**Werkstatt:**
- Stationen 30–33 gehören dem Baukasten, die Level hängen ab Station 34 in Bau-Reihenfolge an. `M_ENDE` (werkstatt.gd:22) wird dafür angehoben.
- Die Kurve der Werkstatt liegt laut Kamera-Karte F3 flach. Terrassen entstehen deshalb über `hoehe`-Einträge.

### 1.8 Reiter, Floß, Keiler

Keine der drei Klassen braucht eine Änderung, die mehr als ein Level nutzt:

| Klasse | Lage |
|---|---|
| **Reiter** (reiter.gd) | Nur L04 reitet; L17 teilt die Klasse. Alles, was L04 braucht, ist Leveldatum oder Haken: `tempo_start`/`tempo_max` (:23-24), `seiten_grenze` (:101), `boden_pruefer` (:106), `strecke` (:111), `setze_checkpoint` (:602). reiter.gd bleibt unverändert. |
| **Wasserplattform/Treibmine** | Die Seilfähre in L03 läuft über `floss()` (korridor_level.gd:120-140). `Treibbahn` ist ein neues Bauteil nur für L03. L09, L24 und L25 bleiben unberührt. |
| **Keiler** | Nur L05 (level05.gd:363-430, keiler.gd). |

Gemeinsam ist nur, was **um** die drei herum gebraucht wird:
- **Streckengeber** `strecke_der_figur()` und `kamera_strecke_quelle()`. Sie lösen die Mehrdeutigkeit an der Kreuzung von L04 für Kamera und Stimmungsregler.
- **Gruppe `nach_tod`:**
  - L02 Wechten: Bruchplatte, dazu ein neuer Wrapper `nach_tod(_von_vorn)` um das vorhandene `zuruecksetzen()` (bruchplatte.gd:113).
  - L05: Durchlässe heilen.
  - L04: Rastplatz-Tempo.
- **`pruefruhe()`** für L02, L03 und L05.

### 1.9 Was Level 01 dafür ändern muss: nichts

level01.gd erbt von `LevelBasis`, nicht von `KorridorLevel` (level01.gd:1). Berührt werden nur diese geteilten Dateien:

| Datei | Zusatz | Warum L01 gleich bleibt | Nachweis |
|---|---|---|---|
| corridor_camera.gd | `sicht_maske`, `plan`, `strecke_quelle`, `profil()`, `strecke()` | Vorgabe 1\|8 entspricht :334. Ohne Plan rechnen Lokale mit den Exportwerten, Ausdrücke und Reihenfolge wie in :366-461. | Wächter W, Kamera-Abgleich in level_check (:47-60) |
| level_basis.gd | Haken, `call_group` | Die Haken liefern null bzw. ein leeres Callable; die Gruppe ist leer. | W, Bauzeitprobe |
| rundgang.gd | `blicke_plan` neu | `blicke_entlang` bleibt unverändert. | Rundgangprobe: gleiche Blickzahl für L01 und Hub |
| korridor_level.gd | `weg`, `*_auf`, Duckdurchlass … | L01 erbt nicht davon; L06–L25 setzen `weg` nie. | `pruefe.sh` über alle Level |
| gelaende_saum.gd | `stoff_variante` | `stoff()` (:753) bleibt unverändert. | W |
| fremdmodelle.gd | neue `ROLLEN` | exakte Namen (:503-519) | W, auch für den Portalraum |
| werkzeuge/* | Opt-in-Felder | `has_method` bzw. ohne Feld wie heute | Logs von Sprungprobe und LevelCheck für L01 zeilengleich |
| Bauspeicher | – | Die Fassung ist ein md5 über alle Skripte (bauspeicher.gd:35-49). L01 baut nach jedem Paket einmal kalt; das Bild ändert sich dadurch nicht. | Bauzeitprobe Runde 2 |

Geteilte Shader und Props, die einzelne Levelpakete berühren, laufen unter demselben Wächter:
- `himmel.gdshader`: Sturmwand für L04.
- `BORKE_SHADER` (riesenstamm.gd:1181): für L04. Der Portalraum nutzt ihn über `borkenstoff` (hub.gd:1531).
- `Riesenstamm`: Option `spalt` für L05.
- **Regel dafür:** Eine neue Uniform nur als Zweig `if (wert > 0.0) { … }` mit Vorgabe 0, nie als `mix(…, 0.0)`. Dass L01 dabei pixelgleich bleibt, ist **ungeprüft**, bis der Wächter es zeigt. Rückfall ist eine Shader-Kopie.

---

## 2. Arbeitspakete

### Wächter W (Abnahme jedes Pakets, Baukasten wie Level)

1. `bash werkzeuge/parse.sh` meldet keinen Fehler.
2. `bash werkzeuge/pruefe.sh` meldet für alle Level `ERGEBNIS: SAUBER` (pruefe.sh:161).
3. **Level 01 und Portalraum unverändert:**
   - `SCHAUFENSTER_TEILE=wache` einmal mit `VORHER=HEAD` und einmal auf dem Arbeitsstand, jeweils `FOTO_ARGS="--fixed-fps 30"`.
   - Teil `wache` sind 6 Bilder: L01 Verfolger bei s 4 / 101 / 212 / 275,5, L01 Seite bei s 186, Portalraum Verfolger 14. Die Stellen stammen aus schaufenster.sh:101-110.
4. **Werte in `werte.tsv`:** draw ±2; objekte, primitive und knoten gleich; vram ±0,5 MB.
5. **Bilder:** `ImageChops.difference(a, b).getbbox() is None`. Ist das nicht erfüllt, darf die mittlere Abweichung höchstens dem HEAD-gegen-HEAD-Rauschen aus G0 entsprechen.
6. **Logs von L01:**
   - Sprungprobe zeilengleich;
   - LevelCheck gleich bis auf Zeitangaben;
   - Bauzeitprobe in Runde 2 mit gleicher Zahl und gleichen Texten der Schritte.
7. **Nur für Levelpakete zusätzlich:** Leistungsrahmen an den Messstellen des Entwurfs, gemessen mit `FOTO_WERTE`.
   - Rechner ≤ 500 Draw-Calls, Ziel ≤ 450;
   - Handy (`FOTO_REDUZIERT=1 FOTO_TOUCH=1`) ≤ 450;
   - Primitive ≤ 750k;
   - Bauzeit Runde 2 nicht über der von L01.

### Reihenfolge der Pakete

**P0 – Rückfragen an den Nutzer** (vor G6 und vor den Levelpaketen):

| # | Frage | betrifft |
|---|---|---|
| R1 | Spurbindung in 2D | L02 |
| R2 | `tempo_max` 15 und `tempo_start` je Rastplatz | L04 |
| R3 | Slide-Sprung nur als Kür | L05 |
| R4 | Modellbudget für Raum 1: die 9 aus §1.4 oder mehr | alle |
| R5 | Figur `assets/modelle/cash_banooka_rc.glb` | alle |

Zu R5: Die Datei liegt im Repo, in assets/CREDITS.md fehlt ein Eintrag (grep); laut CREDITS.md:46 ist die Spielfigur selbstgebaut. Die Herkunft der Datei ist **ungeprüft**. Die Frage muss vor allen Nachher-Bildern geklärt sein; bis dahin laufen die Bilder mit frischem Profil.

**G0 `waechter`**
- **Ziel:** Messbasis für den Wächter.
- **Dateien:** werkzeuge/schaufenster.sh (Teil `wache`).
- **Abnahme:**
  - HEAD zweimal gegen sich selbst laufen lassen und den Rauschwert notieren (die Reproduzierbarkeit ist laut Technikkarte **ungeprüft**).
  - `pruefe.sh` SAUBER.
  - Kein Spielcode geändert.

**G1 `unterbau`**
- **Ziel:** §1.2.
- **Dateien:**
  - neu `scripts/gemeinsam/wegdaten.gd`;
  - korridor_level.gd, level_basis.gd;
  - corridor_camera.gd (nur `sicht_maske`);
  - werkstatt.gd: Station 30 mit Terrassen ±1,2 und Stufenkollision, Schulter, Leitlinie 16, Duckdurchlass, Todeszone unter dem Boden und `kiste_auf` auf einer Terrasse;
  - neu `werkzeuge/baukastenprobe.gd` (Teil Wegdaten).
- **Abnahme:**
  - W.
  - Die Baukastenprobe findet `Wegdaten` mit L01-Daten gleich `Level01` an allen 0,5-m-Stellen.
  - An Station 30:
    - Der Rückweg unter die obere Terrasse ist gesperrt.
    - Der Duckdurchlass sperrt die aufrechte Kapsel (1,30 m, Player.tscn:6-8) und lässt Slide und Krabbeln durch. Ein Doppelsprung (Scheitel 3,22) kommt nicht über 4,4 m.
    - Ein Tod löst `nach_tod(false)` in der Gruppe aus.
  - LevelCheck der Werkstatt sauber.

**G2 `proben`**
- **Ziel:** §1.7 ohne Kamerateil.
- **Dateien:** sprungprobe.gd, level_check.gd, foto.gd; `sprungfaelle()` in werkstatt.gd.
- **Abnahme:**
  - W, Sprungprobe von L01 zeilengleich.
  - Die Probe läuft direkt auf der Werkstatt (`… Sprungprobe.tscn -- res://scenes/levels/Werkstatt.tscn`) und trifft die Zahlen der Entwürfe:
    - `einfach`, 3,0 m flach: Fenster 1,95 ± 0,25 m (Messbank L05);
    - `doppel`, 5,0 m flach: Fenster ≥ 1,30 m bei 0,20 s (L02 §2);
    - `duck`, Tiefe 1,6: sauber ≥ 3,0 m (L05).

**G3 `stoffe`**
- **Ziel:** §1.3.
- **Dateien:**
  - neu `scripts/gemeinsam/{wegdecke,kanten,gelaende_bau,bachband,nebelstoff}.gd`, `shaders/{bach,nebeltafel}.gdshader`;
  - gelaende_saum.gd (`stoff_variante`);
  - Werkstatt-Station 31 als „Themenbühne“: je 40 m Wald, Sumpf und Schnee mit Lücke, Stirn, Ufer und Böschung.
- **Abnahme:**
  - W; Wegmaskenprobe sauber.
  - Die Baukastenprobe findet die Profile gleich saum.gd.
  - Fotos von Station 31 (Verfolger und Seite, ≤ 4 Bilder): kein Bordstein, Lippe ±3 cm auf der Kollision.
  - Bauzeitprobe `BAUZEIT_SZENEN=…Werkstatt.tscn,…Level01.tscn`: L01 behält Lücken und Kronenlicht. Das prüft, dass der Zwischenspeicher je Schlüssel greift und der Fehler aus boden.gd:44 nicht auftritt.
  - Runde 2 lädt Gelände und Kanten aus dem Bauspeicher.

**G4 `bewuchs`**
- **Ziel:** §1.4.
- **Dateien:**
  - neu `scripts/gemeinsam/{waldrahmen,baumfabrik,rasenbau}.gd`;
  - 9 Modelle plus `.import` nach `natur2/unp/`, assets/CREDITS.md:12, natur2/LIESMICH.md (Stand 25);
  - `ROLLEN` in fremdmodelle.gd;
  - Werkstatt-Station 32 mit Hain und Rasen.
- **Abnahme:**
  - W, ausdrücklich auch für den Portalraum.
  - Die Baukastenprobe findet `weg_frei`/`kegel_frei` gleich wald.gd.
  - `Waldrahmen.auge(s)` trifft den Ort der echten Kamera nach `sofort_ausrichten()` auf ±0,3 m, mit 9,5/6 und mit −21/5,6.
  - Der Zuwachs von `.pck` bleibt im Rahmen (LIESMICH.md:102).
  - Glattprobe der Werkstatt sauber.

**G5 `stimmung`**
- **Ziel:** §1.5.
- **Dateien:** neu `scripts/gemeinsam/stimmungsregler.gd`; Zonen an Station 32.
- **Abnahme:**
  - W.
  - Die Baukastenprobe findet `mischung` mit `L01Stimmung.ZONEN` gleich dem Original.
  - Bei stehender Figur schreibt der Regler nichts (Kostenregel aus stimmung.gd:255-262).

**→ Neubau Level 05** (Pakete P1 und P3–P9 des Entwurfs; P2 ist in G1–G5 aufgegangen). Danach kommt erst:

**G6 `kameraplan`**
- **Ziel:** §1.6.
- **Dateien:**
  - neu `scripts/kameraplan.gd`, `werkzeuge/kameraplanprobe.gd`;
  - corridor_camera.gd, level_basis.gd, rundgang.gd, level_check.gd, pruefe.sh;
  - Werkstatt-Station 33: Hochblick, Seite mit Eck- und Drehblende, tiefe Kamera mit Deckel.
- **Abnahme:**
  - W, dazu Kamera-Abgleich in level_check für L01 unverändert.
  - An Station 33, je 0,5 m:
    - Kamerasprung ≤ 2,0 m, Gier ≤ 10°;
    - in der Seitenansicht 16–17,5 m Abstand;
    - außerhalb jeder Zone Seitenanteil 0.
  - Ein Respawn mitten in einer Zone steht schon im ersten Bild im richtigen Profil.
  - `pruefen()` meldet einen absichtlich falschen Plan (Σ w > 1).
  - Rundgangprobe für die Werkstatt; für L01 und den Portalraum bleibt die Blickzahl gleich.
  - Renntest L06 und Glattprobe L04 (alt) unverändert, weil `strecke_quelle` dort nicht gesetzt ist.
  - 2 Fotos von Station 33 (Hochblick, Seite).

**→ Neubau L03, dann L04, dann L02**, jeweils nach den Paketen des Entwurfs. Diese Pakete aus den Entwürfen sind dabei schon erledigt:

| Entwurf | aufgegangen in |
|---|---|
| L03 P1, P2 | G1–G6 |
| L04 P1 | G6 |
| L02 Paket A | G6; die Spurbindung wandert ins L02-Paket B1 und kommt erst nach R1 |

Jedes Levelpaket endet mit W.

---

## 3. Was je Level eigen bleibt

| | L02 Frostgrat | L03 Treibgut | L04 Katzensprung | L05 Hauerjagd |
|---|---|---|---|---|
| **Leitidee / Kamera** | 2D über zwei Flanken: Seitenzonen, Eck- und Drehblende, Driftregel | dreimal Hochblick quer zum Strom | Ritt mit tiefer, Brücken- und erhöhter Kamera; Kreuzung | durchgehend Rückblick (abstand −21, Level05.tscn:65); kein Plan, `sicht_maske` 8, `far` 380 |
| **Daten** | `PUNKTE`, `Y_KURVE`, `ABSCHNITTE`, `LUECKEN`, `BEGEHBARES`, `LEITLINIEN`, `TODESZONEN`, `KISTEN`, `GEGNER`, `FRUECHTE`, `KAMERA`, `STIMMUNG`, `SICHTGRUPPEN` | `BEINE` (Stützpunkte alle 6 m), `QUERUNGEN`, `KAMERAPLAN`, Tabellen | G3-Kurve aus `SEGMENTE` (nicht `kurve_aus_punkten`), `STAEMME`, `HINDERNISSE`, `RASTPLAETZE`, `KAMERA` | `KURVE`, `KURVENHOEHE`, `ABSAETZE`, `TERRASSEN`, `DURCHLAESSE`, `HUERDEN`, `JAGD`, `EICHE` |
| **Eigene neue Teile** | Sichtgruppen; Wechten über Optionen an bruchplatte.gd; Tropfzapfen; Firndecke; `eisflaeche.platte`; Flammen-Shader als Kopie von hub.gd:262ff; Hütte, Steinmann, Gipfelfeuer | `Treibbahn` mit Stromuhr; `rechen`, `seilfaehre`, `ausspuelzone`, `pfeiler`; `Bogenruine`, `mauerwerk.gdshader`; `strom.gdshader` als Kopie von bach; Schilf; Fernbild | `Stammbahn`, `Wurzelteller`, `Flatterband`, Weidenröschen; `ritt_hindernis`, `ritt_rastplatz`, `fruechte_bahn`; Rittprobe; `ritt_fahrplan`; Neigung der Katze | `L05Jagd` (Schlaf, Wecken, Ufer); keiler.gd mit 7 Gliedern; Eiche; Optiken für Durchlass, Hürde und Findlingsgasse; Mühlrad; Klang „muehle“; `duckstellen`; Jagdprobe |
| **Geteilte Dateien im Levelpaket (unter W)** | player.gd und `spur()` an der Kamera (nach R1); bruchplatte.gd; eisflaeche.gd; Schneetextur in materialbibliothek.gd; Schneemaske über `moosdecke` (fremdmodelle.gd:812) | spieltest.gd (`querungsziel`) | riesenstamm.gd (`bruch_farbe`, Silber in `BORKE_SHADER` :1181); himmel.gdshader (Sturmwand); foto.gd setzt `strecke`; Level04.tscn `tempo_max` (R2) | riesenstamm.gd (`spalt`); Klang.gd; spieltest.gd (`duckstellen`) |
| **Stoffthema** | Schnee, Firn, Eis; Rasen-Uniform aus | Damm-Pflaster, Sumpf, Altarm | Waldweg, silberne Rinde | Waldweg, Löss, Sandstein, Kupferfarn |
| **Modelle (von den 9)** | Rock_1/3, Dead_3 | Willow_1/3/5, WoodLog | BirchTree_1/3, Rock_1/3, Dead_3, WoodLog | BirchTree_1/3, Rock_1/3 |
| **Proben** | `sprungfaelle` (doppel, ueberlauf), `pruefprofil` mit kameraplan | `sprungfaelle` (bewegt), Probe „querung“ | Rittprobe; `pruefprofil` {wegmaske} | `sprungfaelle` (doppel, duck, huerde), Jagdprobe |
| **Richtzeit** | 1,3 × Bot | 1,3 × Bot | 1,3 × Bot | 1,3 × Bot |

---

## 4. Widersprüche zwischen den Entwürfen und Entscheidung

| # | Widerspruch | Entscheidung |
|---|---|---|
| 1 | **Datenmodell des Kameraplans:** L02 nutzt lückenlose Einträge, deren Lücken die Blendfenster sind (§7.1). L03 nutzt Grund plus Zonen mit Rändern (§7.1). L04 will `setze(von, werte, blende_m)` plus `decke` (§9.2). L05 braucht keinen Plan. | Grund plus Zonen mit `ein`/`aus` außerhalb von [von, bis], additiv gemischt. Die Einträge von L02 werden zu aneinanderstoßenden Zonen mit deckungsgleichen Rändern; das ergibt genau die Mischung (1−t)·A + t·B. Der Deckel ist optional. |
| 2 | **Was gemischt wird:** L03 mischt nur 4 Felder, L02 auch `blick_hoehe` und die Seite. | Gemischt werden alle Profilfelder außer `fov`. Der Seitenanteil läuft getrennt. Die Vorgaben sind die Exportwerte, ohne Zone bleibt alles wie heute. |
| 3 | **Länge der Blende:** L02 nimmt 8–10 m, L03 6 m, L04 ≥ 1,05 s. | `pruefen()` verlangt ≥ `min_blende_s` · `tempo`; Vorgabe 0,6 s (heutige 1/1,6 s, corridor_camera.gd:67-71). L04 setzt 1,0 s bei 15 m/s. |
| 4 | **Woher die Strecke s kommt:** L02 und L03 nehmen die geführte Kamerastrecke, L04 die Strecke des Reiters. | Opt-in `kamera_strecke_quelle()`. Automatisch über die Eigenschaft `strecke` ginge es nicht: Dann änderten sich L06 und L17 (level_basis.gd:334-335). |
| 5 | **Sichtstrahl und Ebenen:** L02 legt erhöhtes Begehbares auf 16, L03 bleibt bei 1\|8 mit Freiraumregel, L04 und L05 setzen `sicht_maske` 8. Die Schreibweise mischt Ebenennummer und Bitwert („Ebene 4 (Wert 8)“, „Ebene 16“). | Export `sicht_maske` mit Vorgabe 1\|8; jedes Level wählt selbst und belegt die Wahl mit einer Freiraumprobe. Begehbares liegt immer auf 16, Kisten auf 1 (wie in L01). In den Daten stehen nur Bitwerte über Konstanten. |
| 6 | **`boden_bei` in Lücken:** L05 will NAN. L01 interpoliert (level01.gd:1419-1439), und level_check ruft `boden_bei` an beliebigen Stellen auf (:678, :1090, :1353). | Interpoliert wie L01. Lücken liefert `ist_luecke(s)`. |
| 7 | **Todeszonen:** L05 nutzt `absturzzonen(20, 60)` plus `todeszone`; L02 und L03 nur `todeszone`. | Nur `todeszone()` (Gruppe `todeszonen`, level_werkzeuge.gd:1153) und für die Sturzprobe `zonen_unter_boden`. `absturzzonen` hat keine Gruppe und hängt an der Kurve (korridor_level.gd:835-851); sie entfällt in 02–05. |
| 8 | **Namen in der Sprungprobe:** Bei L02 heißt „lauf“ Überlaufen ohne Sprung, bei L03 und L05 Einzelsprung. | `einfach` als Vorgabe (heutiges Verhalten), `ueberlauf` für L02. „fang“ und „stufe_doppel“ entfallen und werden über Felder abgebildet (§1.7). |
| 9 | **Form der Stimmung:** L02 setzt absolute Farben, Sonnenenergie, Bildrahmen und Nebelbeginn; L03 und L04 relative Faktoren; L05 relative Faktoren plus Nebelfarbe. | Schema von `ZONEN` aus L01 (stimmung.gd:120-139) plus die optionalen Felder `nebel_beginn`, `rahmen`, `rahmen_licht`, `sonne_energie`. |
| 10 | **Modellbudget:** Gewünscht sind 24 neue Dateien (L02 10, L03 5, L04 5, L05 16). Rahmen „rund 25“, belegt 16, also 9 frei (LIESMICH.md:22, :102). | Die 9 aus §1.4. Ersatz für den Rest: Büsche in L05 über Farnwerk/Kronenwolke; Dead_4/5 über getöntes Dead_1–3; TreeStump über TreeStump_Moss; Birch_2/4/5 über skaliertes Birch_1/3; Rock_2/4–7 über Rock_1/3 und Findling. Mehr nur nach R4. |
| 11 | **Shader der Wegdecke:** L03 will eine Kopie `dammpflaster`, L04 Uniforms in wegboden. | Keine Kopie. Das Pflaster ist eine Textur im Thema von `Wegdecke`. Neue Uniforms nur als `if (wert > 0)`-Zweig mit Vorgabe 0; W belegt die Gleichheit. Eine Kopie gibt es nur als Rückfall. |
| 12 | **Nummern der Werkstatt-Stationen:** L02 30–34, L03 30–33, L05 „nächste freie“. | G-Pakete belegen 30–33, die Level folgen ab 34 in Bau-Reihenfolge. |
| 13 | **Richtzeit:** L02 nimmt die Formel (94,5 s), L03 98 s, L04 32 s, L05 46 s (1,3 × Bot). | Für alle vier `zielzeit()` = 1,3 × Bot-Zeit, gerundet, nach dem Muster von L06 (level06.gd:64-73: Bot 59 s, Richtzeit 78 s). Die Zahlen der Entwürfe sind Startwerte. Die Formel gäbe bei ≈ 50 s Lauf jede Stufe geschenkt (L02 §6.6, L03 §6.6, **ungeprüft**). |
| 14 | **Höhe von Kisten, Früchten und Gegnern:** L02 rechnet `boden_bei − kurve_y` an `kiste()`, L05 will `kiste_auf`, L01 nutzt `kisten_ort` (level01.gd:1113). | `kiste_auf`, `frucht_auf`, `gegner_auf` und `portale_auf` in KorridorLevel. L04 behält `kiste()`, weil dort Kurve und Kappe zusammenfallen. |
| 15 | **Zurücksetzen nach einem Tod:** L02 baut `bruchplatten_zuruecksetzen_anbinden`, L05 `_nach_tod` mit Durchlässen, L04 setzt das Tempo am Rastplatz. | Eine Gruppe `nach_tod` in `LevelBasis._zuruecksetzen`. Bruchplatten kommen **nicht** automatisch hinein, sonst änderte sich das Verhalten in L14 und anderen. |
| 16 | **Ruhe für Proben:** L05 `pruefruhe`, L02 „Taktgefahren abschalten“, L03 `uhr_setzen`. | Ein Haken `pruefruhe()`; foto, level_check und sprungprobe rufen ihn. L03 setzt dort die Stromuhr fest. |
| 17 | **Eingabe beim Kamerawechsel:** Die Kamera-Karte schlägt Festhalten vor; L02 will keinen Anker, sondern die Driftregel; L03 misst Gier ≤ 0,2°. | Kein Richtungsanker. Die Driftregel und der Stick-Halt vor jedem Fenster laufen in `kameraplanprobe`. |
| 18 | **Blicke im Rundgang:** L02 Seite 0°/±25°, L03 Hochblick 0°/±30°, L04 ein Halt je Blende. | `blicke_plan`: Verfolger ±40°, Hochblick und Seite 0°/±30°, Halt in jeder Blendmitte. |
| 19 | **Namen und Orte:** `nebelstoff.gd` / `Stoffzusatz` / `Nebelstoff`; `scripts/gemeinsam` gegen `scenes/props`. | Logik in `scripts/gemeinsam/`, Formen in `scenes/props/` (Treibbahn, Stammbahn, Wurzelteller). Namen wie in §1.1. |
| 20 | **Kamerazone F1:** In der Technik- und der Kamera-Karte ein Fehler zum Beheben. | Raum 1 nutzt `kamerazone` nicht mehr. Der Fix für L10, L11, L12, L14 und L24 ist eine eigene Aufgabe (Muster stimmungszone.gd:129-141), weil er diese Level sichtbar ändert. |
| 21 | **Kollision:** Die Technikkarte will Variante b nur nach Rückfrage, L02 E20 wählt b. | Variante b für alle vier, weil die Verläufe neu sind und der Nutzer den Neuentwurf der Pflichtwege erlaubt hat. |
| 22 | **Spurbindung:** L02 legt sie in das gemeinsame Kamerapaket A. | Nicht in den Baukasten. Ins L02-Paket nach R1, weil nur L02 eine Seitenansicht hat und es eine Steuerungsänderung ist. |
| 23 | **Name von L02:** Der Auftrag sagt „Frostschlucht“, CLAUDE.md, README.md:46 und Spielfluss.gd:79 sagen „Frostgrat“. | Frostgrat; level02.gd:2 wird im L02-Paket nachgezogen. |

Kein Widerspruch, aber am Raumbogen geprüft: Der Doppelsprung ist Pflicht in L02, L04 (im Ritt) und L05 (Wehr). Gelehrt wird er in L02; L04 bietet ihn am Horst und L05 an G1 vorher gefahrlos an. Krabbeln lehrt L03, L05 fordert den Slide unter Druck.

---

## 5. Empfohlene Reihenfolge: L05, L03, L04, L02

Die Gesamtfolge: P0 → G0–G5 → **L05** → G6 → **L03** → **L04** → **L02**.

**1. L05 Hauerjagd zuerst**
- Waldthema wie L01: Wegdecke (Waldweg), Böschung, Stirn, Ufer, Gelände, Bachband, Waldrahmen, Rasenbau und Stimmungsregler werden gegen ein bekanntes Bild abgenommen.
- Die zwei schwierigsten Verallgemeinerungen treffen ihn sofort:
  - das Auge aus der echten Kamera mit abstand −21 statt der festen 9,5/6 (wald.gd:631-637);
  - `boden_bei` auf Terrassen für den Keiler.
- Vom Kameraplan braucht L05 nur `sicht_maske` (G1). Die riskanteste geteilte Änderung (`_folgen`) kommt deshalb erst danach.
- R3 ändert nur die Bewertung des Slide-Sprungs, nicht den Bau.

**2. L03 Treibgut**
- Erster Nutzer des Kameraplans mit echter Figur. Sicht-, Sturz- und Sprungprobe greifen damit voll; beim Reiter entfallen sie (level_check.gd:430-432).
- Der Plan ist dort am einfachsten: nur Höhe und Abstand, Ränder auf Geraden, keine Drehung.
- Der Strom baut auf dem Bachband aus L05 auf.
- Die Treibbahn ist abgeschlossen und betrifft nur L03.

**3. L04 Katzensprung**
- Zweites Waldthema, also geringes Risiko bei den Stoffen.
- Nutzt aus dem Plan nur `strecke_quelle` und `decke`.
- Die eigene Rittprobe hängt an keinem anderen Level.
- R2 ist bis dahin beantwortet.

**4. L02 Frostgrat zuletzt**
- Das höchste Risiko liegt dort:
  - ein neues Stoffthema für alle Bausteine (Schnee in Wegdecke, Kanten und Modellen);
  - 2D mit Eck- und Drehblende;
  - die Spurbindung als Steuerungsänderung (nach R1);
  - drei neue Gefahren;
  - eine Kehre mit Sichthülle.
- L02 bekommt dafür einen Kameraplan und Proben, die schon an zwei Leveln gereift sind.
- **Nachteil:** Die Doppelsprung-Lehre entsteht nach L04 und L05, die ihn schon fordern. Spielbar bleiben die Zwischenstände trotzdem, weil beide ihn vorher gefahrlos anbieten.
- **Wer die Spielreihenfolge 02 → 05 will:** Dann trifft der schwierigste Fall des Plans den Baukasten zuerst, und das Schneethema wird ohne Vergleichsbild abgenommen.