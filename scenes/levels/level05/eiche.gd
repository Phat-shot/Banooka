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
##   nicht als zwei Bäume. Je vier Äste tragen die Krone.
## * Zwei SCHIRMKRONEN (`Kronenwolke` Variante 1) an den Ästen, gemessen:
##   Mitten bei q −11,8 und +11,0, Y 52,5, je 13–15 m breit und 10 m hoch;
##   dazwischen die Himmelskerbe (KERBE, 9,0 m).
## * FERNFORM ab FERN_AB (Handy FERN_AB_HANDY, Entwurf §9.5): dieselben
##   Stämme als `Riesenstamm.schlicht` (ohne Äste), die Kronen als
##   `Kronenwolke.fern`, über `visibility_range` (Abstand Kamera – Mitte
##   der Hülle). Die Kronen beider Fassungen haben dieselben Ballen
##   (gleiche Saat, gleiche Zentren), so springt beim Wechsel der Umriss
##   nicht.
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
##   gezogen). Die Krähen kommen mit der Stimmung (Paket P8).
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
##     der Bildmitte 10,9 px je Grad). Mit 9,0 m: 18,2 px gerechnet
##     (Wahrzeichenprobe), 18 px im Foto gemessen.
##   * Kronen an Ästen statt um eine feste Mitte, die Hälften dafür 24 m
##     statt „≈ 20" (siehe HAELFTE): Je eine Schirmkrone auf einem Stock las
##     sich als zwei Schirmpinien. Ihre Mitten liegen so bei Y 52,5 statt
##     ≈ 55 (gemessen); die Freiraumprobe K3 (`Level05.freiraumprobe`) prüft
##     weiter die Kronen des Entwurfs aus `Level05.EICHE`, die gebauten
##     prüft die Wahrzeichenprobe.
##
## NEBEL BIS PAKET P8. `Nebelstoff` rechnet Tiefennebel (wie Level 01).
## Level05.tscn steht noch auf Exponentialnebel (Dichte 0,0035); die
## Stimmung (P8) stellt ihn auf den Tiefennebel des Entwurfs (§8.3) um.
## Bis dahin trüge die Eiche mit `Nebelstoff.nebel_setzen` gar keinen Nebel
## (Dichte 0,0035 · 0,45 auf einer Tiefenkurve von 10–100 m). Deshalb
## übersetzt `nebel_einstellen` Exponentialnebel in die Tiefenkurve des
## Stoffs (siehe EXP_*). Tiefennebel geht unverändert an `nebel_setzen`.
##
## KOSTEN (Entwurf §10: Desktop 10 (+3), Handy 6). Nah zwei Netze, Stamm
## (Fuß und Hälften verschmolzen, 3,9k Dreiecke) und Kronen (beide
## verschmolzen, 4,7k); fern drei Flächen, Fuß und Hälften getrennt (für
## NEBEL_KUPPE, 0,3k) und die Kronen (1,6k). Schatten wirft nur der nahe
## Stamm; die Kronen keine (Kronenwolke, Kopf), die Fernform keine. Im
## Übergang (FERN_AB … NAH_BIS) stehen beide Fassungen. Gemessen als
## Differenz zu P3 (gleiche Fotostellen, gleicher Lauf): Desktop +3 bis +6
## (+6 bei s 60 im Übergang, +4 bei s 8 mit Schatten), Handy +3, im
## Übergang (s 26) +6.

## Gruppe der Eiche – die Wahrzeichenprobe nimmt sie aus der Verdeckung.
const GRUPPE := "wahrzeichen"
## Stammachse auf der Strecke (siehe Kopf, ABWEICHUNGEN).
const STAMM_S := -9.5
## Breite der Himmelskerbe zwischen den Kronen (m): Abstand der innersten
## Ecken der Fernkronen quer (die Nahkronen tragen dazu Blattkarten; gemessen
## 9,02). Sie folgt aus HAELFTE_NEIGUNG (siehe dort) und steht hier nur als
## Maß, gebaut wird sie nicht aus ihr; die Wahrzeichenprobe misst sie im
## Schlussbild nach ("Kerbe bei s 296"). Siehe Kopf, ABWEICHUNGEN.
const KERBE := 9.0
## Kronen an den Ästen (wie `Riesenstamm.baum`): Ballen an den Astspitzen
## und am Leittrieb, eine Füllkugel in der Mitte – Variante 1 (Schirm). Nah
## und fern dieselben Ballen (gleiche Saat, gleiche Zentren), so springt beim
## Wechsel der Umriss nicht. KRONE_R ist der Ballenmaßstab: Mit r 7,0 wird
## jede Krone 13–15 m breit und 10 m hoch (gemessen am Netz) – „r 7,5" des
## Entwurfs als Hülle, nicht als Maß der einzelnen Ballen.
const KRONE_R := 7.0
## Laub der Hauereiche: etwas wärmer als `Farben.LAUB` – im Abendlicht soll
## sie golden leuchten (Entwurf §8.1), nicht kühl grün.
const LAUB := Color(0.3, 0.46, 0.15)

## Fuß (siehe Kopf). Oben auf r 0,8 verjüngt: Dort steckt er ganz in den
## beiden Hälften (jede r 1,1, 0,75 m neben der Achse), kein Rand und keine
## Bruchfläche schaut zwischen ihnen heraus. Vorn ein schmaler heller Riss
## (Spaltfläche flach, ab 30 % der Höhe) – der Spalt läuft bis in den Fuß.
const FUSS := {"hoehe": 5.0, "radius": 1.9, "radius_oben": 0.8, "brettwurzeln": 7,
		"wurzel_reichweite": 2.4, "wurzel_hoehe": 2.4, "wurzel_dicke": 0.6, "anlauf": 0.35,
		"krumm": 0.0, "oben": "offen", "pilze": 1, "efeu": 1, "spalt": Vector2(0.0, -1.0),
		"spalt_tiefe": 0.15, "spalt_von": 0.3, "saat": 5501}
## Stammhälften: gemeinsame Optionen; je Seite dazu `neigung`, `spalt` und
## `saat` (`_haelfte`). Ansatz HAELFTE_ANSATZ (x seitlich, y Höhe) im Fuß.
## Vier Äste je Hälfte tragen die Krone (ohne sie stand je eine Scheibe auf
## einem Stock – im Bild zwei Schirmpinien, keine Eiche). 24 m statt „≈ 20":
## Die Krone sitzt an den Astspitzen, also tiefer als die Spitze; mit 24 m
## liegt ihre Mitte bei Y 52,5 (gemessen; Entwurf ≈ 55).
const HAELFTE := {"hoehe": 24.0, "radius": 1.1, "radius_oben": 0.6, "krumm": 0.5,
		"anlauf": 0.0, "brettwurzeln": 0, "aeste": 4, "ast_start": 0.64, "ast_steil": 0.5,
		"ast_laenge": 4.6, "spalt_tiefe": 0.3, "spalt_bis": 0.85}
## Ansatz im Fuß: Die unterste Kante der Hälften (1 m unter dem Ansatz,
## `Riesenstamm.VERSENKT`) liegt bei 2,4 m, wo der Fuß noch r 1,9 hat – sie
## steckt also ganz in ihm.
const HAELFTE_ANSATZ := Vector2(0.75, 3.4)
## Saat je Hälfte (0: q < 0, 1: q > 0): unter den ersten 400 Saaten je Seite
## die, deren vier Äste nicht in die Kerbe zeigen (keine Astspitze mehr als
## 0,6 m innerhalb der Achse) und die Krone nicht vor oder hinter den Stamm
## ziehen (Mittel der Spitzen längs ≤ 1,2 m) – gemessen an den Metadaten
## "ast_spitzen" von `Riesenstamm.netz`. Einmal vorab gesucht (Hilfsskript
## außerhalb des Projekts), nicht zur Laufzeit.
const HAELFTE_SAAT: Array[int] = [5572, 6804]
## Versatz der Spitze je Hälfte (x nach außen, z nach hinten): so gewählt,
## dass die innerste Ecke der Fernkrone genau KERBE/2 neben der Mitte liegt
## (vorab mit dem Sekantenverfahren gesucht, Fehler < 0,005 m; gebaut und
## gemessen 9,02 m).
const HAELFTE_NEIGUNG: Array[Vector2] = [Vector2(12.528, 0.6), Vector2(12.071, 0.6)]
## Spaltfläche der Hälften: schaut mehr nach innen (x) als zur Kamera (z) –
## eine helle Innenkante des V. Frontal zur Kamera deckte sie vier Fünftel
## der Hälfte, aus der Ferne las sich der Stamm dann als blasses Brett.
const HAELFTE_SPALT := Vector2(0.75, -0.66)

## Fassungen nach Abstand (Kamera – Mitte der Hülle), Rand gegen Flackern.
const NAH_BIS := 100.0
const FERN_AB := 85.0
const NAH_BIS_HANDY := 60.0
const FERN_AB_HANDY := 50.0
const RAND := 4.0
## Eigener Nebel (siehe Kopf).
const NEBEL_KRONE := 0.45
const NEBEL_STAMM := 0.45
const NEBEL_KUPPE := 0.7
## Exponentialnebel 1 − e^(−ρd) als Tiefenkurve des Stoffs:
## pow(smoothstep(0, EXP_BIS/ρ, d), 0,5) · EXP_DECKUNG. Angepasst auf
## ρd 0,07 … 1,4 (bei ρ 0,0035: 20 … 400 m), größte Abweichung 0,016
## (gerechnet; bei 35/100/200/320 m: 0,104/0,280/0,504/0,685 statt
## 0,115/0,295/0,503/0,674).
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
## Kronen (Mitten und Größen der Hüllen der Fernkronen) und die innersten
## Ecken an der Kerbe, in Weltkoordinaten – für `wahrzeichen`.
var kronen_mitten: Array[Vector3] = []
var kronen_groessen: Array[Vector3] = []
var kerben_kanten: Array[Vector3] = []


static func bauschritte(level_: Level05) -> Array:
	var e := L05Eiche.new()
	e.level = level_
	level_.eiche = e
	return [{"text": "Die Hauereiche", "tun": e._bauen}]


# ================================================================ Bau

func _bauen() -> void:
	var nah_bis := NAH_BIS_HANDY if Effekte.reduziert else NAH_BIS
	var fern_ab := FERN_AB_HANDY if Effekte.reduziert else FERN_AB
	wurzel = Node3D.new()
	wurzel.name = "Hauereiche"
	wurzel.add_to_group(GRUPPE)
	wurzel.transform = rahmen()
	level.deko.add_child(wurzel)

	var stamm_nah := _knoten("StammNah", stamm_netz(false),
			_nebelarm(Riesenstamm.borkenstoff(BORKE), NEBEL_STAMM), true)
	stamm_nah.visibility_range_end = nah_bis
	stamm_nah.visibility_range_end_margin = RAND
	# Fern zwei Flächen: der Fuß auf der Kuppe mit mehr Nebel (NEBEL_KUPPE),
	# die Hälften wie die Kronen.
	var borke_fern := Riesenstamm.borkenstoff(BORKE_FERN)
	var stamm_fern := _knoten("StammFern", stamm_netz(true),
			_nebelarm(borke_fern, NEBEL_KUPPE), false)
	stamm_fern.set_surface_override_material(1, _nebelarm(borke_fern, NEBEL_STAMM))
	stamm_fern.visibility_range_begin = fern_ab
	stamm_fern.visibility_range_begin_margin = RAND

	var kronen_nah := kronen_netz(false)
	var kronen_fern := kronen_netz(true)
	var kn := _knoten("KronenNah", kronen_nah,
			_nebelarm(Kronenwolke.stoff(LAUB), NEBEL_KRONE), false)
	kn.visibility_range_end = nah_bis
	kn.visibility_range_end_margin = RAND
	var kf := _knoten("KronenFern", kronen_fern,
			_nebelarm(Kronenwolke.stoff(LAUB, false), NEBEL_KRONE), false)
	kf.visibility_range_begin = fern_ab
	kf.visibility_range_begin_margin = RAND

	# Probepunkte für `wahrzeichen` aus der Fernkrone (die steht im Bild,
	# solange die Kerbe zählt), in Weltkoordinaten.
	var r := wurzel.global_transform
	for m: Vector3 in kronen_fern.get_meta("mitten", PackedVector3Array()):
		kronen_mitten.append(r * m)
	for g: Vector3 in kronen_fern.get_meta("groessen", PackedVector3Array()):
		kronen_groessen.append(g)
	for k: Vector3 in kronen_fern.get_meta("kanten", PackedVector3Array()):
		kerben_kanten.append(r * k)
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
## Bauspeicher. `fern`: die schlichte Fassung, ohne Äste (in 85 m sind sie
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
## Fernkrone: dieselben Ballen). Metadaten (im Rahmen der Eiche): "mitten"
## und "groessen" (Hüllen der Fernkronen), "kanten" (die innersten Ecken der
## Fernkronen an der Kerbe); custom_aabb über beide samt Blattkarten.
static func kronen_netz(fern: bool) -> ArrayMesh:
	return Bauspeicher.netz("l05_eiche_kronen", [HAELFTE, HAELFTE_ANSATZ, HAELFTE_NEIGUNG,
			HAELFTE_SAAT, KRONE_R, fern], func() -> ArrayMesh: return _kronen_bauen(fern))


static func _kronen_bauen(fern: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box := AABB()
	var mitten := PackedVector3Array()
	var groessen := PackedVector3Array()
	var kanten := PackedVector3Array()
	for i in 2:
		var seite := -1.0 if i == 0 else 1.0
		var haelfte := Riesenstamm.netz(_haelfte(i, false))
		var o := {"zentren": haelfte.get_meta("ast_spitzen"),
				"nebenzentren": haelfte.get_meta("zweig_spitzen"), "radius": KRONE_R,
				"variante": 1, "saat": HAELFTE_SAAT[i] + 101}
		var lage := _ansatz(i)
		var fern_netz := Kronenwolke.fern(o)
		var netz := fern_netz if fern else Kronenwolke.netz(o)
		st.append_from(netz, 0, lage)
		# Mit Blattkarten: Die Hülle der Krone steht in custom_aabb (die
		# Karten zieht erst der Shader auf).
		var huelle := netz.custom_aabb if netz.custom_aabb.has_volume() else netz.get_aabb()
		var b := lage * huelle
		box = b if i == 0 else box.merge(b)
		mitten.append(lage * fern_netz.get_aabb().get_center())
		groessen.append(fern_netz.get_aabb().size)
		kanten.append(lage * _innerste_ecke(fern_netz, seite))
	var ergebnis := st.commit()
	ergebnis.custom_aabb = box
	ergebnis.set_meta("mitten", mitten)
	ergebnis.set_meta("groessen", groessen)
	ergebnis.set_meta("kanten", kanten)
	return ergebnis


## Die Ecke einer Krone, die am weitesten zur Kerbe reicht: bei der Krone
## auf `seite` (+1: q > 0) die mit dem kleinsten seite · x.
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

## Probepunkte des Wahrzeichens (für `Level05.wahrzeichen`): je Krone die
## Mitte und vier Punkte auf 0,6 der halben Hülle (quer und hoch), dazu die
## Kerbe – ihre Mitte und je 1 m darüber und darunter – samt den beiden
## innersten Ecken ("kanten"). Leer vor dem Bau.
func wahrzeichen() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	if kronen_mitten.size() != 2 or kerben_kanten.size() != 2:
		return liste
	var quer := wurzel.global_transform.basis.x
	for i in 2:
		var m := kronen_mitten[i]
		var r := kronen_groessen[i].x * 0.3
		var h := kronen_groessen[i].y * 0.3
		liste.append({"name": "Krone bildrechts" if i == 0 else "Krone bildlinks",
				"punkte": PackedVector3Array([m, m + quer * r, m - quer * r,
					m + Vector3.UP * h, m - Vector3.UP * h])})
	var k := (kerben_kanten[0] + kerben_kanten[1]) * 0.5
	liste.append({"name": "Kerbe", "punkte": PackedVector3Array([k, k + Vector3.UP,
			k - Vector3.UP]), "kanten": PackedVector3Array(kerben_kanten)})
	return liste
