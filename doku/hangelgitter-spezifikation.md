# Hangelgitter – was in `player.gd` passieren muss

Bauanleitung für die Spieler-Seite des `Hangelgitter`-Props
(`scenes/props/hangelgitter.gd`). Alle Zeilennummern beziehen sich auf
`scenes/player/player.gd` im Stand von Commit `d5c8ece` (469 Zeilen).

Das Prop ist fertig und wird nicht mehr angefasst. Es beantwortet dem
Spieler-Code diese Fragen:

| Aufruf | Liefert |
|---|---|
| `Hangelgitter.naechstes(self)` | das nächstgelegene Gitter in Reichweite, sonst `null` |
| `gitter.naechster_punkt(pos)` | Weltpunkt, an dem die Figur hängt (längs und quer beschnitten) |
| `gitter.hangelhoehe()` | Welt-Y der Fußsohlen beim Hängen (= `naechster_punkt().y`) |
| `gitter.laengsachse()` / `gitter.querachse()` | Weltrichtungen des Gitters |
| `gitter.ist_am_ende(pos, richtung)` | hängt die Figur am Rand und will weiter hinaus? |

---

## 1. Die Höhenrechnung

Sie steht auch im Kopfkommentar des Props, hier zum Nachrechnen:

* Sprunghöhe der Füße: `JUMP_V² / (2·|G|) = 12,2² / 76 = **1,96 m**`
* Griffhöhe über den Sohlen: `Hangelgitter.GRIFF_HOEHE = **1,55 m**`
  (Kapsel 1,30 m, Ohrenspitzen 1,42 m, gestreckte Arme eine Handbreit darüber)
* Reichweite der Hände im Scheitel: `1,96 + 1,55 = **3,51 m**`

Daraus:

| Unterkante des Gitters | Urteil |
|---|---|
| unter 2,40 m | verboten (`MINDESTHOEHE`) – die hängende Figur schleift über den Boden |
| 2,6 m – 3,4 m | **bequem**, Vorgabe ist 3,2 m |
| 3,4 m – 3,5 m | nur mit exaktem Scheitelsprung, unfair |
| bis 4,96 m | nur mit Doppelsprung (`DJUMP_V² / 76 = 1,45 m` obendrauf ⇒ 3,41 m Fußhöhe) |

Bei der Vorgabe `hoehe = 3,2` hängen die Sohlen auf **1,65 m** – das sind
84 % der Sprunghöhe, es bleibt also Luft nach oben.

---

## 2. Neue Konstanten (zu den Kennwerten ab Zeile 25)

Keiner dieser Werte rührt an die verbindlichen Physikwerte aus CLAUDE.md.

```gdscript
## Tempo beim Hangeln, längs des Gitters. Zwischen Krabbeln (3,0) und
## Laufen (8,5): Hangeln soll zügig sein, aber nie die schnellere Wahl.
const HANGEL_TEMPO := 3.6
## Tempo quer dazu, entlang einer Sprosse. Langsamer, weil dabei die
## Griffe gewechselt werden statt nachgefasst.
const HANGEL_QUER := 2.0
## Sperre nach dem Loslassen. Ohne sie hinge die Figur im nächsten Bild
## wieder am selben Gitter – sie fällt ja mitten durch die Fangzone.
const HANGEL_SPERRE := 0.3
```

## 3. Neue Zustandsvariablen (zu den Zustandsvariablen ab Zeile 60)

```gdscript
## Gitter, an dem die Figur gerade hängt. `null` = sie hängt nicht.
## Öffentlich, weil `haltung()` und Gegner es lesen sollen.
var hangelgitter: Hangelgitter = null
## Restsperre nach dem Loslassen, in Sekunden.
var _hangel_sperre := 0.0
```

`hangelgitter` ist der einzige Zustand, den es braucht: Hanghöhe,
Richtung und Grenzen liegen alle im Prop. Kein Timer, kein Fortschritt,
keine gemerkte Position – nach einem Respawn ist `null` bereits der
richtige Zustand.

---

## 4. Einbau in `_physics_process` – Reihenfolge

### 4.1 Timer (Zeile 103–105)

Eine Zeile dazu:

```gdscript
_hangel_sperre = maxf(_hangel_sperre - delta, 0.0)
```

### 4.2 `gesperrt` (Zeile 107–112)

Ganz vorn in den Block, **vor** die Schwerkraft:

```gdscript
if gesperrt:
    hangelgitter = null      # NEU: Portalfahrt zieht die Figur vom Gitter
    velocity.x = 0.0
    ...
```

Ohne das fällt die Figur während der Portal-Animation zwar herunter,
`hangelgitter` bleibt aber gesetzt – und schnappt beim Entsperren wieder
nach oben.

### 4.3 Der Hangel-Block – direkt nach Zeile 114

Das ist die entscheidende Stelle. Der Block gehört **zwischen Zeile 114
(`var am_boden := is_on_floor()`) und Zeile 116
(`# --- Horizontale Bewegung ---`)** und endet mit `return`:

```gdscript
	# --- Hangeln ---
	# Steht vor allem anderen, weil Hangeln kein Zustand NEBEN Laufen,
	# Slide und Sprung ist, sondern statt ihnen: Wer hängt, hat weder
	# Boden noch Schwerkraft, und genau das macht die Stelle schwer.
	if hangelgitter == null and not am_boden and not slamming \
			and sliding <= 0.0 and _hangel_sperre <= 0.0:
		_einhaengen(Hangelgitter.naechstes(self))
	if hangelgitter != null:
		_hangeln(delta)
		return
```

Damit übersprungen und **bewusst nicht** ausgeführt werden:

| Zeilen | Was | Warum übersprungen |
|---|---|---|
| 116–139 | Laufen, Luftkontrolle, Eis | Tempo und Richtung kommen aus dem Gitter |
| 146–157 | Slide, Bauchplatscher | Slide-Taste heißt hier „loslassen" |
| 159–160 | `_kriechen_pruefen()` | Krabbeln braucht Boden |
| 162–183 | Sprung, Doppelsprung | Absprung läuft eigens, mit anderen Regeln |
| 185–189 | Jump-Cut | keine Sprunghöhe zu kappen |
| 191–198 | Spin-Attacke | „man hat beim Hangeln kaum Handlungsmöglichkeiten" (Steckbrief 5-5) |
| 202–211 | Schwerkraft, `move_and_slide()` | in `_hangeln()` selbst, ohne Schwerkraft |
| 213–224 | Landung | es wird nicht gelandet |

**Nicht** übersprungen werden dürfen: `_hitbox_aktualisieren()` (Zeile 200)
und die Absturzprüfung (Zeile 226–228) – beide gehören in `_hangeln()`
hinein, siehe unten.

---

## 5. Die neuen Funktionen

Alle drei gehören in den Abschnitt `# --- Intern ---` (ab Zeile 351),
`hangeln_beenden()` in die Schnittstelle (ab Zeile 239).

```gdscript
## Hängt die Figur ein. `null` wird stillschweigend geschluckt, damit die
## Fundstelle oben ohne zweite Abfrage auskommt.
func _einhaengen(gitter: Hangelgitter) -> void:
	if gitter == null:
		return
	hangelgitter = gitter
	velocity = Vector3.ZERO
	sliding = 0.0
	slamming = false
	kriechen = false
	can_djump = true
	_kein_jump_cut = false
	# WICHTIG: Das Fall-Gedächtnis muss weg. Es wird sonst nur in Zeile
	# 206–209 abgebaut, und die läuft beim Hangeln nie – die Figur zählte
	# den Sprung, mit dem sie ans Gitter kam, für immer als Treffer von oben.
	_fall_rest = 0.0
	global_position = gitter.naechster_punkt(global_position)
	reset_physics_interpolation()
	Klang.spiele("landung", 1.3, 0.7)


## Hangeln: ein vollständiger Ersatz für Laufen und Fallen.
func _hangeln(delta: float) -> void:
	var gitter := hangelgitter
	if not is_instance_valid(gitter):
		hangeln_beenden()
		return

	var eingabe := _kamerarelativ(InputHub.bewegung())

	# Absprung: trägt nach oben und in die Blickrichtung, der Doppelsprung
	# bleibt übrig. Das ist der Weg vom Gitter auf den nächsten Dachrand.
	if InputHub.sprung_gedrueckt():
		hangeln_beenden()
		velocity = Vector3(eingabe.x * RUN_SPEED * AIR_CTRL, JUMP_V,
				eingabe.y * RUN_SPEED * AIR_CTRL)
		can_djump = true
		Klang.spiele("sprung")
		return

	# Loslassen: senkrecht fallen. Dieselbe Taste, die am Boden den Slide
	# und in der Luft den Bauchplatscher macht – hier heißt sie „runter".
	if InputHub.slide_gedrueckt():
		hangeln_beenden()
		velocity = Vector3.ZERO
		return

	# Die Eingabe wird auf die beiden Gitterachsen zerlegt. So bleibt die
	# Steuerung kamerarelativ, auch wenn das Gitter schräg zur Kamera hängt.
	var wunsch := Vector3(eingabe.x, 0.0, eingabe.y)
	var laengs := gitter.laengsachse()
	var quer := gitter.querachse()
	var zug := laengs * laengs.dot(wunsch) * HANGEL_TEMPO \
			+ quer * quer.dot(wunsch) * HANGEL_QUER

	velocity = Vector3(zug.x, 0.0, zug.z)
	move_and_slide()
	# Nach der Bewegung zurück auf das Gitter setzen. Das ist zugleich die
	# Grenze: `naechster_punkt()` beschneidet längs wie quer, die Figur
	# kann also nicht über das Ende hinausrutschen.
	global_position = gitter.naechster_punkt(global_position)

	if eingabe.length() > 0.1:
		_blick_y = atan2(-eingabe.x, -eingabe.y)
	_tempo = clampf(zug.length() / HANGEL_TEMPO, 0.0, 1.0)
	_hitbox_aktualisieren()
	if global_position.y < TODESHOEHE:
		sterben()


## Löst die Figur vom Gitter und sperrt das sofortige Wiedereinhängen.
## Öffentlich, weil Schaden, Tod und die Portalfahrt es ebenfalls brauchen.
func hangeln_beenden() -> void:
	if hangelgitter == null:
		return
	hangelgitter = null
	_hangel_sperre = HANGEL_SPERRE
```

---

## 6. Rein und raus – die Entscheidungen und warum

**Rein: automatisch bei Berührung der Fangzone.** Keine Taste.

Begründung: Die Fangzone ist nur 0,6 m hoch und sitzt unmittelbar unter
dem Gitter – sie wird ausschließlich getroffen, wenn jemand bewusst
dorthin springt. Ein Gitter steht nie im Weg, es ist immer Ziel. Eine
Zusatztaste in der Luft wäre auf Touch außerdem kaum zu treffen, und der
Steckbrief zu 5-5 will die Schwierigkeit im Ausweichen haben, nicht im
Zugreifen. Gesperrt ist das Einhängen nur, solange `_hangel_sperre` läuft,
während eines Bauchplatschers (wer runter will, will runter) und während
eines Slides.

**Raus, Weg 1 – Sprungtaste: Absprung.** `JUMP_V` nach oben, waagerecht
`RUN_SPEED · AIR_CTRL` in Eingaberichtung, Doppelsprung wieder verfügbar.
Das ist der normale Weg weiter und trägt 1,96 m hoch und rund 4,5 m weit.

**Raus, Weg 2 – Slide-Taste: loslassen.** Senkrechter Fall ohne Impuls.
Die Slide-Taste ist im ganzen Spiel die „nach unten"-Taste (Slide,
Bauchplatscher, Krabbeln); hier ist sie es auch. Ein Bauchplatscher
direkt aus dem Hang heraus ist damit eine Tastenfolge (loslassen, dann
noch einmal drücken) statt eines Sonderfalls.

**Raus, Weg 3 – Ende des Gitters: gar nicht.** Die Figur bleibt hängen
und kommt nicht weiter; `naechster_punkt()` beschneidet sie. Automatisch
loszulassen wäre ein Verrat: Ein Gitter hängt über einer Gasse, und wer
zu weit hangelt, stürbe, ohne etwas falsch gemacht zu haben. Am Ende
springt man ab – das ist eine Entscheidung, kein Unfall.

`ist_am_ende(pos, richtung)` wird dafür **nicht** gebraucht; es ist für
das HUD, für Gegner und für eine mögliche „am Ende zappeln"-Animation da.
Wer will, blendet damit einen Hinweis ein.

---

## 7. Bewegung

* **längs** (von Sprosse zu Sprosse): `HANGEL_TEMPO = 3,6 m/s`
* **quer** (entlang einer Sprosse): `HANGEL_QUER = 2,0 m/s`

Beides gleichzeitig, weil sich die Eingabe auf beide Achsen zerlegt. Quer
ist absichtlich möglich: Ein Gitter mit `breite = 2,0` gibt ±0,65 m
nutzbaren Spielraum quer – genug, um einem Deckenskorpion auszuweichen,
zu wenig, um ihn zu ignorieren. Ein Gitter, das nur eine Schiene sein
soll, bekommt `breite = 0,9`; dann bleibt quer nichts übrig.

Rückwärts hangeln geht ohne Sonderfall, weil die Zerlegung Vorzeichen
kennt.

---

## 8. Hitbox, Haltung, Clip

**Hitbox: die aufrechte Kapsel, unverändert.** `_hitbox_aktualisieren()`
(Zeile 401–409) schaltet auf `sliding > 0.0 or kriechen` um; beides ist
beim Hangeln `false`/`0.0`, also ist ohne jede Änderung die richtige
Kapsel aktiv. Der Aufruf muss aber trotzdem in `_hangeln()` stehen – sonst
bliebe die flache Slide-Kapsel stehen, wenn jemand aus einem Slide-Jump
heraus ins Gitter greift.

Die aufrechte Kapsel ist auch die gewollte: Sie hängt von 1,65 m bis
2,95 m, ragt also in genau die Höhe, in der Deckengegner sitzen. Das ist
die Aufgabe des Levels, keine Panne.

**`haltung()` (Zeile 246–247)** wird zu:

```gdscript
func haltung() -> String:
	if hangelgitter != null:
		return "hangeln"
	return "krabbeln" if kriechen else ""
```

**Clip.** Der Standardsatz in `assets/modelle/LIESMICH.md` braucht eine
zwölfte Zeile:

| Clip | Dauer | Schleife | Wann |
|---|---|---|---|
| `Hang` | 1,4 s | ja | hängt am Hangelgitter |

Erkannt werden soll er wie die anderen ohne Rücksicht auf Groß- und
Kleinschreibung, deutsche Namen mit. In `beuteldachs.gd` sind das vier
Stellen:

1. neben Zeile 68 eine Variable `var _clip_hangeln := ""`
2. in `_clips_zuordnen()` (Zeile 514–525) eine Zeile
   `_clip_hangeln = _erster_clip(["hang", "hangeln", "haengen"])`
   – ans Ende, `"hang"` kollidiert mit keinem der elf bisherigen Namen
3. in der Schleifenliste Zeile 533–534 dazu (`LOOP_LINEAR`): eine Haltung
   läuft endlos, wie `Crawl`, `Ride` und `Sit`
4. in `_clip_zu_haltung()` (Zeile 583–592) der Fall
   `"hangeln": return _clip_hangeln`

Achtung: Das gilt nur für **fremde Figuren mit Skelett**. Der eigene
Beuteldachs bekommt `haltung` gar nicht zu sehen – Zeile 455–458 reicht
sie nur an `_animiere_eigenes()` weiter, `_animiere()` läuft ohne. Er
ignoriert schon heute `"krabbeln"`. Beim Hangeln zeigt er deshalb die
Luftpose (gestreckt), weil `_process()` in Zeile 234 `not is_on_floor()`
übergibt und das beim Hängen `true` ist. Das ist nicht falsch, aber
lieblos; eine gehobene Armhaltung in `_animiere()` wäre ein eigener,
kleiner Schritt danach.

---

## 9. Schaden, Tod, Respawn

**Schaden (`schaden_nehmen()`, Zeile 309–316).** Ein Treffer muss die
Figur vom Gitter reißen. Sonst hängt sie im Wirkbereich eines
Deckengegners fest und verliert dort in einer Sekunde alle drei
Schutzladungen. Der Aufruf gehört **nach** die Unverwundbarkeitsprüfung
und **vor** die Schutzladung:

```gdscript
func schaden_nehmen() -> void:
	if invuln > 0.0:
		return
	hangeln_beenden()      # NEU: ein Treffer reißt die Hände vom Gitter
	if GameState.schutz_verbrauchen():
		...
```

Nach `hangeln_beenden()` fällt die Figur im nächsten Bild ganz normal –
`velocity` ist noch `Vector3.ZERO`, die Schwerkraft in Zeile 203 greift
sofort wieder.

**Tod.** `sterben()` (Zeile 319–323) braucht nichts, weil es `respawn()`
ruft.

**Respawn (Zeile 326–348).** Zu den anderen Rücksetzungen:

```gdscript
	hangelgitter = null
	_hangel_sperre = 0.0
```

Die Sperre wird bewusst auf 0 gesetzt und nicht gestartet: Wer an einem
Checkpoint unter einem Gitter erscheint, soll wieder hinaufspringen
dürfen. `reset_physics_interpolation()` steht in Zeile 344 schon da.

**`abprallen()` (Zeile 293–300)** braucht keine Änderung – eine
Federkiste unter einem Gitter schleudert die Figur hinauf, sie greift zu,
`_einhaengen()` setzt `velocity` auf null. Genau richtig.

---

## 10. Fallstricke

1. **`_fall_rest` läuft nie ab.** Es wird ausschließlich in Zeile 206–209
   auf- und abgebaut, und die Zeilen laufen beim Hangeln nicht. Wer mit
   Fallgeschwindigkeit ins Gitter greift, hätte für immer `Angriff.FALLEN`
   in `angriffe()` (Zeile 260) stehen und zerbräche im Vorbeihangeln
   jede Kiste. Deshalb `_fall_rest = 0.0` in `_einhaengen()`.

2. **`_kann_aufstehen()` (Zeile 381–397) darf nicht dazwischenfunken.**
   Sie wird in Zeile 163 vor dem Sprung und in Zeile 371/373 beim
   Krabbeln gefragt. Beide Stellen liegen hinter dem `return` des
   Hangel-Blocks und werden nie erreicht – **vorausgesetzt, der Block
   steht wirklich vor Zeile 116.** Steht er weiter unten, dann prüft
   Zeile 163 mit der Stehkapsel gegen eine Dachkonstruktion über dem
   Gitter, meldet „kein Platz" und der Absprung bliebe aus.

3. **`_kriechen_pruefen()` (Zeile 365–373) beim Loslassen.** Ihre erste
   Zeile setzt `kriechen = false`, sobald `am_boden` falsch ist – die
   fallende Figur ist also automatisch aufrecht. Kein Eingriff nötig,
   aber `kriechen = false` gehört trotzdem in `_einhaengen()`, weil man
   auch aus dem Krabbeln heraus (über eine Federkiste) ans Gitter kommen
   kann.

4. **Absturzzonen.** Die Prüfung in Zeile 226–228 läuft beim Hangeln
   nicht mit, deshalb steht sie am Ende von `_hangeln()` noch einmal.
   Wichtiger ist der andere Fall: Tödliche Bereiche
   (`Wasser` mit `toedlich`, `Stacheln`) sind Area3D mit Maske 2 und
   greifen die hängende Kapsel genauso wie die laufende. Ein Gitter über
   einer Wasserrinne muss also mindestens seine 2,40 m Mindesthöhe
   über der Oberkante dieser Zone hängen, nicht über dem Wasserspiegel.

5. **Das Wiedereinhängen nach dem Loslassen.** Die Figur fällt beim
   Loslassen durch die eigene Fangzone. Ohne `HANGEL_SPERRE` greift sie
   im nächsten Bild sofort wieder zu und lässt sich nie mehr los. 0,3 s
   reichen: In dieser Zeit fällt sie `½·38·0,3² = 1,7 m` und ist damit
   aus der 0,6 m hohen Zone heraus.

6. **`move_and_slide()` plus Rücksetzen.** Beides in dieser Reihenfolge
   ist Absicht: `move_and_slide()` lässt Wände weiterhin blocken,
   `naechster_punkt()` hält danach nur Höhe und Grenzen. Umgekehrt
   – erst setzen, dann bewegen – wäre die Höhe um einen Frame verzögert
   und die Figur würde sichtbar sägen.

7. **`is_on_floor()` beim Hangeln.** Es ist `false`, weil `velocity.y`
   null ist und nichts unter den Füßen liegt – solange das Gitter hoch
   genug hängt. Das Prop erzwingt dafür `MINDESTHOEHE = 2,40 m` und warnt,
   wenn ein Level darunter geht. Ein zu tiefes Gitter würde die Figur
   jedes zweite Bild „landen" lassen; darauf muss der Spieler-Code nicht
   reagieren, das Prop verhindert es.

8. **Die Schienenfiguren sind nicht betroffen.** `Reiter`
   (`scenes/player/reiter.gd`, Zeile 77) und `Rennfahrer`
   (`scenes/player/rennfahrer.gd`, Zeile 106) überschreiben
   `_physics_process()` vollständig und `haltung()` ebenfalls. Der
   Hangel-Block läuft dort nie – richtig so, in einem Ritt- oder
   Rennlevel hat ein Gitter nichts verloren.

9. **Zwei Gitter übereinander.** `Hangelgitter.naechstes()` wählt das mit
   dem dichtesten Griffpunkt. Wer zwei Lagen stapelt, sollte mindestens
   1,4 m Abstand lassen, sonst schnappt der Absprung von der unteren Lage
   sofort in die obere. Das ist ein Levelbau-Hinweis, kein Codeproblem.

10. **Gitter auf einer bewegten Plattform.** Funktioniert von selbst:
    `naechster_punkt()` rechnet über `to_local()`/`to_global()` und folgt
    damit jedem Elterntransform. Getestet ist es nicht.

---

## 11. Prüfen

```
bash werkzeuge/parse.sh
```

Und im Spiel: Ein Gitter mit `hoehe = 3.2` über einer Lücke aufhängen,
darunter durchlaufen (nichts passiert), springen (greift zu), hangeln,
mit ✕ abspringen, mit ○ loslassen. Fällt das Loslassen sofort wieder ins
Gitter, ist `HANGEL_SPERRE` nicht angekommen.
