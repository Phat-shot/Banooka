extends RefCounted
class_name L05Eiche
## Level 05, Modul „Eiche": die Hauereiche auf der Kuppe hinter dem Start
## (Entwurf §8.2, §1 Nr. 19, Paket P4). Das Wahrzeichen des Levels liegt
## hinten, nicht vorn: Man läuft von ihm weg, im Rückblick steht die Eiche
## über dem ganzen Hang und wird immer kleiner.
##
## WAS HIER ENTSTEHT (im Rahmen der Eiche: +X = q > 0, im Rückblick
## BILDLINKS; −Z = hangab, zum Weg und zur Kamera):
## * FUSS: r 1,9, 5 m hoch, 7 Brettwurzeln; oben verjüngt er sich in die
##   beiden Hälften hinein. Vorn ein schmaler heller Riss: Der Spalt läuft
##   bis in den Fuß hinab.
## * Zwei STAMMHÄLFTEN, r 1,1 → 0,6, nach außen geneigt (`Riesenstamm.netz`
##   mit `neigung` und `krumm`): ein gespaltener Zwiesel. Ihre Spaltflächen
##   (Option `spalt`, hell und verwittert) schauen schräg nach innen und zur
##   Kamera – eine helle Innenkante des V, so liest es sich als Spalt und
##   nicht als zwei Bäume. Oben spreizen je vier Äste flach in die Krone.
## * Zwei SCHIRMKRONEN (`Kronenwolke` Variante 1) an den Astspitzen,
##   gemessen an der Fernkrone: Mitten bei q −12,8 und +12,3, Y 54,5 und
##   54,9, 16,6 und 15,7 m breit, 7,5 und 7,3 m hoch – flach und breit, EINE
##   Lage Ballen. Dazwischen die Himmelskerbe (KERBE, 9,0 m).
## * FERNFORM ab WECHSEL (Handy WECHSEL_HANDY, Entwurf §9.5): dieselben
##   Stämme als `Riesenstamm.schlicht` (ohne Äste), die Kronen als
##   `Kronenwolke.fern`, über `visibility_range` (Abstand Kamera – Mitte
##   der Hülle). Siehe WECHSEL: ohne Überlappung, Fernkrone in Größe und Ton
##   an die Nahkrone angeglichen.
## * EIGENER NEBEL (`Nebelstoff.nebelarm`): Kronen und Hälften zu 0,45
##   (NEBEL_KRONE, NEBEL_STAMM) – eine dunkle Silhouette mit goldenen
##   Kronen vor dem Dunst. „Für die Kuppe 0,7" des Entwurfs trägt der Fuß
##   der Fernform (NEBEL_KUPPE): Was auf der Kuppe steht, geht mit ihr in
##   den Dunst über, statt als dunkler Klotz auf dem hellen Hang zu stehen.
##   Mit 0,7 auch für die Hälften lasen sie sich im Schlussbild als blasse
##   Stöcke (Bildvergleich P4). Nah entfällt der Unterschied (auf 40 m
##   deckt der Nebel 13 %, 0,45 oder 0,7 davon sind 6 oder 9 %). Das
##   Gelände selbst bleibt unberührt (eine Abschrift seines Stoffs nur für
##   das Stück mit der Kuppe hätte an den Stückgrenzen eine Nebelkante
##   gezogen). OFFEN (Prüfung P4): Hinter der Kuppe ist der Fuß aus der
##   Ferne kaum zu sehen, die 0,7 wirken also fast nirgends – ob „Kuppe"
##   so gemeint ist, entscheidet der Nutzer. Die Krähen kommen mit der
##   Stimmung (Paket P8).
##
## ABWEICHUNGEN VOM ENTWURF, jede von Code oder Messung erzwungen:
##   * STAMM_S −9,5 statt −6: Die Querwand Start (`Level05.LEITLINIEN`)
##     steht bei s −4, dahinter beginnt der Startboden. Bei s −6 läge der
##     Fuß samt Anlauf (r 1,9 · 1,35 = 2,57) schon 0,57 m auf dem
##     Startboden, die Brettwurzeln reichten bis 5,3 m von der Achse – bis
##     s −0,7: Die Figur liefe durch Wurzeln und stünde im Stamm. Bei −9,5
##     reicht kein Punkt des Stamms über s −5,1 (gemessen). Die Kuppe des
##     Geländes bleibt bei s −6 (`Level05.EICHE`); 3,5 m neben ihrem
##     Scheitel liegt sie 0,03 m tiefer, die Eiche steht auf Y 26,83 (dem
##     tiefsten Boden unter ihrem Anlauf, siehe `rahmen`).
##   * KERBE 9,0 statt 7 m: Die Abnahme verlangt im Schlussbild (s 296,
##     Kamera bei s 317) mindestens 16 Bildpunkte bei 720 Zeilen. Die Kerbe
##     liegt dort 327 m weit; 7 m sind dann 13,4 px (die Rechnung des
##     Entwurfs nahm 12 px je Grad und 300 m; bei 60° senkrecht sind es in
##     der Bildmitte 10,9 px je Grad). Mit der breiteren Kerbe liegen die
##     Kronenmitten bei q ≈ ±12,5 statt ±11.
##   * Hälften 24,5 statt „≈ 20" m: Die Kronen sitzen an den Astspitzen
##     oben an den Hälften; ihr Ansatz liegt auf Y 30,2, die Kronenmitten
##     sollen nach dem Entwurf bei Y ≈ 55 liegen (gemessen 54,5 und 54,9).
##
## NEBEL BIS PAKET P8. `Nebelstoff` rechnet Tiefennebel (wie Level 01).
## Level05.tscn steht noch auf Exponentialnebel (Dichte 0,0035); die
## Stimmung (P8) stellt ihn auf den Tiefennebel des Entwurfs (§8.3) um.
## Bis dahin trüge die Eiche mit `Nebelstoff.nebel_setzen` gar keinen Nebel
## (Dichte 0,0035 · 0,45 auf einer Tiefenkurve von 10–100 m). Deshalb
## übersetzt `nebel_einstellen` Exponentialnebel in die Tiefenkurve des
## Stoffs (siehe EXP_*). Tiefennebel geht unverändert an `nebel_setzen`.
## AUFGABE FÜR P8: `nebel_stoffe` an den Stimmungsregler hängen und die
## Brücke EXP_* samt ihrem Zweig in `nebel_einstellen` entfernen.
##
## KOSTEN (Entwurf §10: Desktop 10 (+3), Handy 6). Nah zwei Netze, Stamm
## (Fuß und Hälften verschmolzen) und Kronen (beide verschmolzen); fern
## drei Flächen, Fuß und Hälften getrennt (für NEBEL_KUPPE) und die
## Kronen. Schatten wirft nur der nahe Stamm; die Kronen keine
## (Kronenwolke, Kopf), die Fernform keine. Nah und fern stehen nie
## zugleich (WECHSEL). Gemessen als Differenz zu P3 (gleiche Fotostellen,
## gleicher Lauf; Messtore 8/60/140/218/280/296, dazu 30/46/56/66/76 und
## Handy 16/26/34): Desktop +3, bei s 8 (Stamm mit Schatten) +4; Handy +3
## überall. Mit dem Übergangsband waren es bei s 60–66 und Handy s 26 +6.

## Gruppe der Eiche – die Wahrzeichenprobe nimmt sie aus der Verdeckung
## und prüft an ihr, ob die Probepunkte in den Kronen liegen.
const GRUPPE := "wahrzeichen"
## Stammachse auf der Strecke (siehe Kopf, ABWEICHUNGEN).
const STAMM_S := -9.5
## Breite der Himmelskerbe zwischen den Kronen (m): Abstand der innersten
## Ecken der Fernkronen quer (die Nahkronen tragen dazu Blattkarten). Sie
## folgt aus HAELFTE_NEIGUNG (siehe dort) und steht hier nur als Maß,
## gebaut wird sie nicht aus ihr; die Wahrzeichenprobe misst sie im
## Schlussbild nach ("Kerbe bei s 296"). Siehe Kopf, ABWEICHUNGEN.
const KERBE := 9.0
## Kronen an den Ästen (wie `Riesenstamm.baum`): an jeder Astspitze und am
## Leittrieb ein Ballen, eine Füllkugel in der Mitte – Variante 1 (Schirm).
## Nah und fern dieselben Ballen (gleiche Saat, gleiche Zentren). KRONE_R
## ist der Ballenmaßstab: Mit r 7,0 wird jede Krone 15–17 m breit und gut
## 7 m hoch (gemessen an der Fernkrone) – „r 7,5" des Entwurfs als Hülle,
## nicht als Maß der einzelnen Ballen.
const KRONE_R := 7.0
## Mitte eines Astballens über seiner Astspitze (m): `Kronenwolke` hebt
## jeden Ballen um ein Viertel seines Radius (0,52–0,64 · KRONE_R, also
## 0,91–1,12 m). Die Probepunkte der Wahrzeichenprobe liegen dort – sicher
## im Laub (geprüft: Selbsttest der Probe an jeder Stelle).
const BALLEN_HOCH := 1.0
## Laub der Hauereiche: etwas wärmer als `Farben.LAUB` – im Abendlicht soll
## sie golden leuchten (Entwurf §8.1), nicht kühl grün.
const LAUB := Color(0.3, 0.46, 0.15)

## Fuß (siehe Kopf). Oben auf r 0,45 verjüngt: Dort steckt er ganz in den
## beiden Hälften (jede r 1,1, 0,75 m neben der Achse; vorn decken sie
## zwischen sich 0,5 m). Mit r 0,8 stand sein offener Kopf als dunkler
## Klotz zwischen ihnen (Prüfung P4). Vorn ein schmaler heller Riss ab 40 %
## der Höhe: flach (6 % des Radius, an der Kamera rund 1 m breit) – mit
## 15 % las er sich als helle, kantige Planke.
const FUSS := {"hoehe": 5.0, "radius": 1.9, "radius_oben": 0.45, "brettwurzeln": 7,
		"wurzel_reichweite": 2.4, "wurzel_hoehe": 2.4, "wurzel_dicke": 0.6, "anlauf": 0.35,
		"krumm": 0.0, "oben": "offen", "pilze": 1, "efeu": 1, "spalt": Vector2(0.0, -1.0),
		"spalt_tiefe": 0.06, "spalt_von": 0.4, "saat": 5501}
## Stammhälften: gemeinsame Optionen; je Seite dazu `neigung`, `spalt` und
## `saat` (`_haelfte`). Ansatz HAELFTE_ANSATZ (x seitlich, y Höhe) im Fuß.
## SCHIRM: Die vier Äste gehen erst ab 80 % der Höhe ab, flach (0,25 rad)
## und lang (5,5 m) – ihre Spitzen liegen so auf 2,6 m Höhe beieinander
## (Y 52,1–54,7), die Ballen bilden eine Lage. Mit Ästen ab 64 % und
## 0,5 rad lagen die Spitzen über 5,5 m verteilt, und jede Krone las sich
## als zwei, drei gestapelte Ballen – eine Pagode aus Tellern (Prüfung P4,
## wie Level 01 in Welle 6). 24,5 m: siehe Kopf, ABWEICHUNGEN.
const HAELFTE := {"hoehe": 24.5, "radius": 1.1, "radius_oben": 0.6, "krumm": 0.5,
		"anlauf": 0.0, "brettwurzeln": 0, "aeste": 4, "ast_start": 0.8, "ast_steil": 0.25,
		"ast_laenge": 5.5, "spalt_tiefe": 0.3, "spalt_bis": 0.85}
## Ansatz im Fuß: Die unterste Kante der Hälften (1 m unter dem Ansatz,
## `Riesenstamm.VERSENKT`) liegt bei 2,4 m, wo der Fuß noch r 1,9 hat – sie
## steckt also ganz in ihm.
const HAELFTE_ANSATZ := Vector2(0.75, 3.4)
## Saat je Hälfte (0: q < 0, 1: q > 0): je Seite die erste ab 5502 bzw.
## 6502, deren Krone nicht vor oder hinter den Stamm zieht (Mittel der
## Astspitzen längs ≤ 0,8 m vom Leittrieb, gemessen 0,21 und 0,44) und
## deren Äste nicht weit in die Kerbe greifen (keine Spitze mehr als 2,5 m
## innerhalb der Achse, gemessen 2,26 und 2,32) – an den Metadaten
## "ast_spitzen" von `Riesenstamm.netz`. Die Kronen werden so etwa so tief
## wie breit (Fernkrone 16,6 × 17,8 und 15,7 × 15,7 m). Einmal vorab
## gesucht (Hilfsskript außerhalb des Projekts), nicht zur Laufzeit.
const HAELFTE_SAAT: Array[int] = [5572, 6560]
## Versatz der Spitze je Hälfte (x nach außen, z nach hinten): so gewählt,
## dass die innerste Ecke der Fernkrone (mit FERN_SKALA) genau KERBE/2
## neben der Mitte liegt (vorab mit dem Sekantenverfahren gesucht, Fehler
## < 0,005 m).
const HAELFTE_NEIGUNG: Array[Vector2] = [Vector2(12.647, 0.6), Vector2(11.88, 0.6)]
## Spaltfläche der Hälften: schaut mehr nach innen (x) als zur Kamera (z) –
## eine helle Innenkante des V. Frontal zur Kamera deckte sie vier Fünftel
## der Hälfte, aus der Ferne las sich der Stamm dann als blasses Brett.
const HAELFTE_SPALT := Vector2(0.75, -0.66)

## WECHSEL nah → fern nach Abstand (Kamera – Mitte der Hülle), Entwurf
## §8.2 „ab 85–100 m", §9.5 „Handy ab 60 m nur als Fernform". OHNE
## ÜBERLAPPUNG: Nah endet und fern beginnt an derselben Schwelle, RAND ist
## die Schwelle gegen Flackern (Godot schaltet ohne Überblenden erst RAND
## jenseits um, beide Fassungen im selben Bild, siehe `_wechsel_setzen`).
## Mit einem Übergangsband (85–100 m) standen beide Kronen ineinander –
## ihre Ballen gleich, die Oberflächen aber verschieden verrauscht – und der
## Wechsel war doppelt zu sehen (Prüfung P4). Überblenden
## (`visibility_range_fade_mode`) zeichnet der Compatibility-Renderer nicht
## (gemessen: die Fassung steht im Band voll deckend). Keine von beiden
## stünde nur, wenn die Kamera zum ALLERERSTEN Mal mitten im Band ±RAND
## hinschaut; sie beginnt aber 38 m vor der Eiche (Wahrzeichenprobe, s 6),
## und jeder spätere Sprung (Rücksetzen auf einen Rastplatz) behält die
## Fassung, die zuletzt stand. Im Lauf vom Start weg wechselt die Eiche
## bei s 72, auf dem Handy bei s 32 (Bildfolgen im Schritt 0,5 m, P4-Mängel).
const WECHSEL := 100.0
const WECHSEL_HANDY := 60.0
const RAND := 4.0
## Die Fernkrone hat keine Blattkarten. Ohne Angleich war sie beim Wechsel
## um ein Siebtel kleiner (Fläche im Bild, die Karten fransen die Nahkrone
## aus) und dunkler. Gemessen bei s 56 und 70 (Desktop, Fotos mit nur nah
## gegen nur fern): mit FERN_SKALA (um die Mitte jeder Krone) 98 % der
## Fläche, mit LAUB_FERN mittlere Farbe auf ±1 Stufe gleich (91/67/13
## gegen 91/68/14). Was bleibt, ist der Glanz der Karten.
const FERN_SKALA := 1.07
const LAUB_FERN := Color(0.376, 0.549, 0.173)
## Eigener Nebel (siehe Kopf).
const NEBEL_KRONE := 0.45
const NEBEL_STAMM := 0.45
const NEBEL_KUPPE := 0.7
## Exponentialnebel 1 − e^(−ρd) als Tiefenkurve des Stoffs:
## pow(smoothstep(0, EXP_BIS/ρ, d), 0,5) · EXP_DECKUNG. Angepasst auf
## ρd 0,07 … 1,4 (bei ρ 0,0035: 20 … 400 m), größte Abweichung 0,016
## (gerechnet; bei 35/100/200/320 m: 0,104/0,280/0,504/0,685 statt
## 0,115/0,295/0,503/0,674). Brücke bis P8 (siehe Kopf).
const EXP_BIS := 1.47
const EXP_DECKUNG := 0.74
const EXP_KURVE := 0.5

## Borke der Eiche: Rinde der Bibliothek, etwas wenig Moos oben (Licht).
const BORKE := {"moos_oben": 0.35, "moos_nord": 0.6}
const BORKE_FERN := {"fern": true, "moos_oben": 0.35}

var level: Level05
## Die Eiche im Level (Gruppe GRUPPE).
var wurzel: Node3D
## Abschriften mit eigenem Nebel (für die Stimmung, P8).
var nebel_stoffe: Array[ShaderMaterial] = []
## Kronen (Mitten und Größen der Hüllen der Fernkronen, die Mitten ihrer
## Astballen) und die innersten Ecken an der Kerbe, in Weltkoordinaten –
## für `wahrzeichen`.
var kronen_mitten: Array[Vector3] = []
var kronen_groessen: Array[Vector3] = []
var kronen_ballen: Array[PackedVector3Array] = []
var kerben_kanten: Array[Vector3] = []


static func bauschritte(level_: Level05) -> Array:
	var e := L05Eiche.new()
	e.level = level_
	level_.eiche = e
	return [{"text": "Die Hauereiche", "tun": e._bauen}]


# ================================================================ Bau

func _bauen() -> void:
	var wechsel := WECHSEL_HANDY if Effekte.reduziert else WECHSEL
	wurzel = Node3D.new()
	wurzel.name = "Hauereiche"
	wurzel.add_to_group(GRUPPE)
	wurzel.transform = rahmen()
	level.deko.add_child(wurzel)

	var stamm_nah := _knoten("StammNah", stamm_netz(false),
			_nebelarm(Riesenstamm.borkenstoff(BORKE), NEBEL_STAMM), true)
	# Fern zwei Flächen: der Fuß auf der Kuppe mit mehr Nebel (NEBEL_KUPPE),
	# die Hälften wie die Kronen.
	var borke_fern := Riesenstamm.borkenstoff(BORKE_FERN)
	var stamm_fern := _knoten("StammFern", stamm_netz(true),
			_nebelarm(borke_fern, NEBEL_KUPPE), false)
	stamm_fern.set_surface_override_material(1, _nebelarm(borke_fern, NEBEL_STAMM))

	var kronen_fern := kronen_netz(true)
	var kn := _knoten("KronenNah", kronen_netz(false),
			_nebelarm(Kronenwolke.stoff(LAUB), NEBEL_KRONE), false)
	var kf := _knoten("KronenFern", kronen_fern,
			_nebelarm(Kronenwolke.stoff(LAUB_FERN, false), NEBEL_KRONE), false)
	var nah: Array[MeshInstance3D] = [stamm_nah, kn]
	var fern: Array[MeshInstance3D] = [stamm_fern, kf]
	_wechsel_setzen(nah, fern, wechsel)

	# Probepunkte für `wahrzeichen` aus der Fernkrone (die steht im Bild,
	# solange die Kerbe zählt), in Weltkoordinaten.
	var r := wurzel.global_transform
	for m: Vector3 in kronen_fern.get_meta("mitten", PackedVector3Array()):
		kronen_mitten.append(r * m)
	for g: Vector3 in kronen_fern.get_meta("groessen", PackedVector3Array()):
		kronen_groessen.append(g)
	for k: Vector3 in kronen_fern.get_meta("kanten", PackedVector3Array()):
		kerben_kanten.append(r * k)
	var ballen: PackedVector3Array = kronen_fern.get_meta("ballen", PackedVector3Array())
	var je: int = ballen.size() / 2
	for i in 2:
		var welt := PackedVector3Array()
		for k in je:
			welt.append(r * ballen[i * je + k])
		kronen_ballen.append(welt)
	nebel_einstellen(_umgebung())


## Lage und Rahmen der Eiche: Ursprung auf dem Fuß der Stammachse, +X nach
## q > 0, −Z hangab (Richtung +s). Höhe: der tiefste Boden unter dem Fuß
## (Achse und Ring auf dem Anlauf), damit kein Stück des Fußes schwebt;
## ohne Gelände `Level05.EICHE["boden_y"]`.
func rahmen() -> Transform3D:
	var ort := LevelWerkzeuge.punkt_frei(level.verlauf, STAMM_S, 0.0)
	var quer := LevelWerkzeuge.punkt_frei(level.verlauf, STAMM_S, 1.0) - ort
	quer.y = 0.0
	quer = quer.normalized()
	var hangab := quer.cross(Vector3.UP).normalized() * -1.0
	var basis := Basis(quer, Vector3.UP, -hangab)
	ort.y = float(Level05.EICHE["boden_y"])
	if level.gelaende != null:
		var tief := level.gelaende.hoehe(ort.x, ort.z)
		var anlauf := float(FUSS["radius"]) * (1.0 + float(FUSS["anlauf"]))
		for k in 8:
			var w := TAU * float(k) / 8.0
			var p := ort + (quer * cos(w) + hangab * sin(w)) * anlauf
			tief = minf(tief, level.gelaende.hoehe(p.x, p.z))
		ort.y = tief
	return Transform3D(basis, ort)


## Stamm samt Fuß als EIN Netz (eine Fläche, ein Zeichenaufruf), aus dem
## Bauspeicher. `fern`: die schlichte Fassung, ohne Äste (in 100 m sind sie
## 3 Bildpunkte dünn und stecken in der Krone).
static func stamm_netz(fern: bool) -> ArrayMesh:
	return Bauspeicher.netz("l05_eiche_stamm", [FUSS, HAELFTE, HAELFTE_ANSATZ, HAELFTE_NEIGUNG,
			HAELFTE_SPALT, HAELFTE_SAAT, fern], func() -> ArrayMesh: return _stamm_bauen(fern))


static func _stamm_bauen(fern: bool) -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var fuss := FUSS.duplicate()
	if fern:
		fuss["schlicht"] = true
	st.append_from(Riesenstamm.netz(fuss), 0, Transform3D.IDENTITY)
	# Fern: der Fuß als eigene Fläche (0), die Hälften als zweite (1) – für
	# den eigenen Nebel des Fußes (siehe Kopf, EIGENER NEBEL).
	var netz: ArrayMesh = null
	if fern:
		netz = st.commit()
		st = Riesenstamm.bauer()
	for i in 2:
		st.append_from(Riesenstamm.netz(_haelfte(i, fern)), 0, _ansatz(i))
	return st.commit(netz)


## Optionen der Hälfte `i` (0: q < 0, 1: q > 0).
static func _haelfte(i: int, fern: bool) -> Dictionary:
	var seite := -1.0 if i == 0 else 1.0
	var o := HAELFTE.duplicate()
	o["neigung"] = Vector2(seite * HAELFTE_NEIGUNG[i].x, HAELFTE_NEIGUNG[i].y)
	o["spalt"] = Vector2(-seite * HAELFTE_SPALT.x, HAELFTE_SPALT.y)
	o["saat"] = HAELFTE_SAAT[i]
	if fern:
		o["schlicht"] = true
		o["aeste"] = 0
	return o


## Lage der Hälfte `i` im Rahmen der Eiche.
static func _ansatz(i: int) -> Transform3D:
	var seite := -1.0 if i == 0 else 1.0
	return Transform3D(Basis.IDENTITY, Vector3(seite * HAELFTE_ANSATZ.x, HAELFTE_ANSATZ.y, 0.0))


## Beide Kronen als EIN Netz, je an den Ästen der nahen Hälfte (auch die
## Fernkrone: dieselben Ballen, um FERN_SKALA vergrößert). Metadaten (im
## Rahmen der Eiche): "mitten" und "groessen" (Hüllen der Fernkronen),
## "kanten" (die innersten Ecken der Fernkronen an der Kerbe), "ballen"
## (je Krone gleich viele Punkte, erst die bildrechte: Astspitzen und
## Leittrieb um BALLEN_HOCH gehoben – die Mitten der Astballen);
## custom_aabb über beide samt Blattkarten.
static func kronen_netz(fern: bool) -> ArrayMesh:
	return Bauspeicher.netz("l05_eiche_kronen", [HAELFTE, HAELFTE_ANSATZ, HAELFTE_NEIGUNG,
			HAELFTE_SAAT, KRONE_R, FERN_SKALA, BALLEN_HOCH, fern],
			func() -> ArrayMesh: return _kronen_bauen(fern))


static func _kronen_bauen(fern: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box := AABB()
	var mitten := PackedVector3Array()
	var groessen := PackedVector3Array()
	var kanten := PackedVector3Array()
	var ballen := PackedVector3Array()
	for i in 2:
		var seite := -1.0 if i == 0 else 1.0
		var haelfte := Riesenstamm.netz(_haelfte(i, false))
		var spitzen: PackedVector3Array = haelfte.get_meta("ast_spitzen")
		var o := {"zentren": spitzen, "nebenzentren": haelfte.get_meta("zweig_spitzen"),
				"radius": KRONE_R, "variante": 1, "saat": HAELFTE_SAAT[i] + 101}
		var lage := _ansatz(i)
		var fern_netz := Kronenwolke.fern(o)
		# Fernkrone um ihre Mitte vergrößert (siehe FERN_SKALA).
		var mitte := fern_netz.get_aabb().get_center()
		var gross := Transform3D(Basis.from_scale(Vector3.ONE * FERN_SKALA),
				mitte * (1.0 - FERN_SKALA))
		var netz := fern_netz if fern else Kronenwolke.netz(o)
		st.append_from(netz, 0, lage * gross if fern else lage)
		# Mit Blattkarten: Die Hülle der Krone steht in custom_aabb (die
		# Karten zieht erst der Shader auf).
		var huelle := netz.custom_aabb if netz.custom_aabb.has_volume() else netz.get_aabb()
		var b := lage * gross * huelle if fern else lage * huelle
		box = b if i == 0 else box.merge(b)
		var fern_huelle := gross * fern_netz.get_aabb()
		mitten.append(lage * fern_huelle.get_center())
		groessen.append(fern_huelle.size)
		kanten.append(lage * gross * _innerste_ecke(fern_netz, seite))
		for p in spitzen:
			ballen.append(lage * (p + Vector3.UP * BALLEN_HOCH))
	var ergebnis := st.commit()
	ergebnis.custom_aabb = box
	ergebnis.set_meta("mitten", mitten)
	ergebnis.set_meta("groessen", groessen)
	ergebnis.set_meta("kanten", kanten)
	ergebnis.set_meta("ballen", ballen)
	return ergebnis


## Die Ecke einer Krone, die am weitesten zur Kerbe reicht: bei der Krone
## auf `seite` (+1: q > 0) die mit dem kleinsten seite · x. Die Vergrößerung
## um die Mitte (FERN_SKALA) erhält diese Wahl.
static func _innerste_ecke(netz: ArrayMesh, seite: float) -> Vector3:
	var ecken: PackedVector3Array = netz.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var beste := Vector3.ZERO
	var wert := INF
	for p in ecken:
		if seite * p.x < wert:
			wert = seite * p.x
			beste = p
	return beste


func _knoten(name_: String, netz: ArrayMesh, stoff: Material, schatten: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	mi.mesh = netz
	for f in netz.get_surface_count():
		mi.set_surface_override_material(f, stoff)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wurzel.add_child(mi)
	return mi


## Nah bis `wechsel`, fern ab `wechsel` (siehe WECHSEL). Alle Knoten
## bekommen dieselbe Hülle (`custom_aabb`, die Vereinigung aller samt
## Blattkarten): Godot misst die Sichtweite von der Kamera zur Mitte der
## Hülle, mit gleicher Mitte schalten Stamm und Kronen im selben Bild –
## keine Lücke, kein Bild mit beiden Fassungen, EIN Wechsel statt zweier
## (mit je eigener Hülle wechselten die Kronen bei s 69,5, die Stämme erst
## bei s 73; Bildfolge P4-Mängel).
func _wechsel_setzen(nah: Array[MeshInstance3D], fern: Array[MeshInstance3D],
		wechsel: float) -> void:
	var huelle := AABB()
	var erste := true
	for mi: MeshInstance3D in nah + fern:
		var h := _netzhuelle(mi.mesh)
		huelle = h if erste else huelle.merge(h)
		erste = false
	for mi in nah:
		mi.custom_aabb = huelle
		mi.visibility_range_end = wechsel
		mi.visibility_range_end_margin = RAND
	for mi in fern:
		mi.custom_aabb = huelle
		mi.visibility_range_begin = wechsel
		mi.visibility_range_begin_margin = RAND


static func _netzhuelle(netz: Mesh) -> AABB:
	var a := netz.get_aabb()
	if netz is ArrayMesh and (netz as ArrayMesh).custom_aabb.has_volume():
		a = a.merge((netz as ArrayMesh).custom_aabb)
	return a


# ================================================================ Nebel

## Abschrift mit eigenem Nebel zum `anteil`; gemerkt für `nebel_einstellen`.
func _nebelarm(stoff: Material, anteil: float) -> Material:
	var neu := Nebelstoff.nebelarm(stoff, null, anteil)
	if neu != stoff and neu is ShaderMaterial:
		nebel_stoffe.append(neu as ShaderMaterial)
	return neu


## Schreibt den Nebel von `umgebung` in die eigenen Stoffe (siehe Kopf,
## NEBEL BIS PAKET P8).
func nebel_einstellen(umgebung: Environment) -> void:
	if umgebung == null:
		return
	for stoff in nebel_stoffe:
		Nebelstoff.nebel_setzen(stoff, umgebung)
		if umgebung.fog_enabled and umgebung.fog_mode == Environment.FOG_MODE_EXPONENTIAL \
				and umgebung.fog_density > 0.0:
			var anteil := float(stoff.get_meta("nebel_anteil", Nebelstoff.ANTEIL))
			stoff.set_shader_parameter("nebel_von", 0.0)
			stoff.set_shader_parameter("nebel_bis", EXP_BIS / umgebung.fog_density)
			stoff.set_shader_parameter("nebel_kurve", EXP_KURVE)
			stoff.set_shader_parameter("nebel_dichte", EXP_DECKUNG * anteil)


func _umgebung() -> Environment:
	var welt := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	return welt.environment if welt != null else null


# ================================================================ Abfragen

## Probepunkte des Wahrzeichens (für `Level05.wahrzeichen`), in
## Weltkoordinaten. Je Krone {"name", "punkte", "mitte", "radius"}: die
## Mitten ihrer Astballen (an den vier Astspitzen und am Leittrieb, siehe
## BALLEN_HOCH) – Punkte IM Laub, über die ganze Breite der Krone verteilt;
## dazu Mitte und halbe Breite der Hülle (für die Freiraumprobe K3). Früher
## standen hier Punkte auf 0,6 der halben Hülle; bei Kronen aus Ballen an
## Astspitzen lag der äußere davon neben der Krone in der Luft (Prüfung P4).
## Dazu die Kerbe – ihre Mitte und je 1 m darüber und darunter – samt den
## beiden innersten Ecken ("kanten"). Leer vor dem Bau.
func wahrzeichen() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	if kronen_mitten.size() != 2 or kerben_kanten.size() != 2 or kronen_ballen.size() != 2:
		return liste
	for i in 2:
		liste.append({"name": "Krone bildrechts" if i == 0 else "Krone bildlinks",
				"punkte": kronen_ballen[i], "mitte": kronen_mitten[i],
				"radius": kronen_groessen[i].x * 0.5})
	var k := (kerben_kanten[0] + kerben_kanten[1]) * 0.5
	liste.append({"name": "Kerbe", "punkte": PackedVector3Array([k, k + Vector3.UP,
			k - Vector3.UP]), "kanten": PackedVector3Array(kerben_kanten)})
	return liste
