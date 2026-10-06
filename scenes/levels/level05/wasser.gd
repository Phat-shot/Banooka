extends Node3D
class_name L05Wasser
## Level 05, Modul „Wasser": was am Hauerhang nass ist (Entwurf L05 §5 A/B/
## D/E, §8.4, §9.1, §1 Nr. 23, Paket P6) – die glänzende Suhle, die
## Rinnsale am Wasserriss, der Tobelbach, der Mühlteich, das Weißwasser im
## gebrochenen Wehr und das Mühlrad.
##
## WAS HIER ENTSTEHT (Seiten wie im Rückblick: q < 0 BILDRECHTS, Schatten
## und Wasser; q > 0 BILDLINKS, Sonnenhang):
## * SUHLE (A, q < 0, hinter der niedrigen Erdböschung): Schlamm aus
##   `Materialbibliothek.moorboden` als `duplicate()` (in Braun getönt,
##   nasser: Der Torf der Bibliothek ist grün), knapp über dem Grund der
##   Mulde des Geländes (`L05Gelaende.SUHLE`); wo die Mulde ansteigt,
##   taucht er unter das Feld. Darauf Pfützen (`Materialbibliothek.pfuetze`,
##   der Glanz), dazu drei auf der Decke um den schlafenden Keiler: Er liegt
##   am Wegrand vor der Suhle (L05Jagd, SCHLAF_Q), und der Entwurf will ihn
##   „in der glänzenden Suhle".
## * RINNSALE am Wasserriss L1: je eines aus beiden Böschungen, unter der
##   Grasnarbe heraus, die Wand hinab und im Spalt bis auf seinen Grund
##   (`Wasserfall.band`, an der gebauten Fläche des Saums, `stand` in
##   `L05Saum`). Beide in EINEM Netz.
## * TOBELBACH (D, q < 0) als `Bachband` (Baukasten G3) im Bett vor dem
##   Ufer: drei Meter breit zwischen dem Fuß der Uferwand und der Südwand,
##   der Spiegel über dem Grund des Betts (`L05Saum.form_ab`), stromab nie
##   steigend. In E läuft er in das Unterwasser (`L05Gelaende.UNTERWASSER`)
##   und am Feldrand aus. Die Seitenrinne L4 und die Mühlrinne L5 münden in
##   ihn: Ihr Grund steht so hoch unter Wasser wie der Bach (eigene kurze
##   Läufe quer durch den Spalt). In den Gerinnen der Fluderjoche D3/D4
##   fließt Wasser (`L05Wegbauten.gerinne_lage`) und fällt an ihrem Ende
##   über das Ufer in den Bach.
## * MÜHLTEICH (E, q > 0): ein ruhiger Spiegel in der Teichmulde des
##   Geländes (`L05Gelaende.TEICH`), als Raster über der Mulde; zum Ufer hin
##   (wenig Wasser über dem Feld) läuft er durchsichtig aus. Er treibt
##   langsam zum Bruch.
## * WEISSWASSER im Wehrbruch L6: der Teich stürzt durch den Bruch nach
##   bildrechts, als Schuss ÜBER der Todeszone (Spiegel ≥ WEHR_RECHTS) und
##   am rechten Ufer hinab ins Unterwasser – darunter ein dunkler, schneller
##   Wasserkörper im Stoff des Bachs (Schaum nach der Schnelle), darüber
##   ein Band aus `Wasserfall.band` (rechts).
## * MÜHLRAD Ø 7 m bei s 291 / q −7 im Unterwasser, unterschlächtig: Die
##   Welle liegt quer zum Weg (das Rad steht längs, ab ≈ 15 m bildrechts im
##   Bild), Schaufeln 0,2 m im Wasser, zwei Böcke tragen die Welle. Es
##   dreht sich im Bildtakt (`_process`) – deshalb ohne Interpolation
##   (`PHYSICS_INTERPOLATION_MODE_OFF`), sonst zitterte es (Glattprobe).
##
## TÖDLICH ist hier nichts (Entwurf §1 Nr. 23): keine Kollision, keine
## Zone, keine `Wasser`-Gefahr. Tödlich bleiben allein die Todeszonen der
## Lücken auf fester Höhe (`Level05.LUECKEN`, `todeszone()`); `wasser()`
## von `KorridorLevel` setzt relativ zur Kurve und wird nicht verwendet.
## Am Wehr liegt die Zone auf Y 2,6 UNTER dem Weißwasser: Wer in den Bruch
## fällt, taucht erst ins Wasser und stirbt dann. Das prüft `probe()`
## (LevelCheck, Opt-in "wasser"): sechs Lückenzonen und keine weitere,
## kein Teil des Wassers tödlich, das Wasser im Bruch über der Zone.
##
## KOSTEN (Entwurf §10: Wasser und Mühlrad 10 Zeichenaufrufe, Handy 8),
## alles ohne Schatten: Bach, Teich, Bruch und Gerinne in EINEM Netz im
## Stoff des Bachs (1); Schlamm (1) und Pfützen (1) der Suhle; die
## Rinnsale (1), die Fälle der Gerinne (1) und das Weißwasser (1) je als
## ein Band; Rad (1) und Böcke (1). Zusammen höchstens 8. Gemessen
## (Messtore 8/60/90/140/218/276/280/296, mit gegen ohne Wasser): Rechner
## und Handy je +2 bis +7, das meiste am Mühlbach (276–296). Sichtweiten
## siehe SICHT_*; Bach und Suhle ohne: Eine Sichtweite zählt ab der Mitte
## der Hülle, die des Bachs (Tobel bis Feldrand) liegt weit vom Bild.
##
## BAUSPEICHER: Das Netz des Bachs (das Ufer wird am gezeichneten Gelände
## abgetastet), Schlamm und Pfützen liegen nach dem ersten Laden je
## Handyweg und Rechner im `Bauspeicher` (das Feld des Handys hat weitere
## Punkte), das Mühlrad als `Bauspeicher.netz`. Die Bänder sind kurz und
## entstehen bei jedem Laden neu. Gemessen (Bauzeitprobe, Rechner): kalt
## 168 und 158 ms für die beiden Schritte, im zweiten Laden 7 und 6 ms.
##
## ABWEICHUNGEN VOM ENTWURF, jede von Code oder Messung erzwungen:
##   * Teich und Bruch sind keine Läufe des Bachbands, sondern ein eigenes
##     Raster im selben Netz: Ein Lauf tastet sein Ufer nur bis 2,6 m über
##     seine halbe Breite ab und läge sonst am Wegende (s 300–304, Feld
##     2,88–2,95, gemessen) flach über der Wiese.
##   * Weißwasser als Schuss mit fallendem Spiegel statt als Fall: Das Ufer
##     rechts ist im Bruch bis auf den Grund (Y 1,0) ausgeschnitten
##     (`L05Saum._ab_in_luecke`), ein echtes Gefälle ließe das Wasser auf
##     Y ≈ 1,6 fallen – unter die Zone (2,6). Der Entwurf verlangt die Zone
##     unter dem Weißwasser; also hält der Schuss über der begehbaren
##     Breite mindestens WEHR_RECHTS und fällt erst dahinter.
##   * Die Schlammfläche ist ein `duplicate()` von `moorboden` mit Braun und
##     weniger Rauheit (Entwurf §1 Nr. 24: geteilte Stoffe nur als Kopie).
##   * Zusätzlich Wasser in den Spalten L4/L5 und in den Gerinnen D3/D4
##     (siehe oben); der Entwurf nennt sie „Seitenrinne", „Mühlrinne" und
##     „tropfend", ohne Wasser blieben es trockene Namen.

## Schlüssel im Bauspeicher (dazu "voll"/"handy").
const SPEICHER := "l05_wasser_"
## Sichtweiten (m) und Schwelle gegen Flackern: Rinnsale nur von Nahem
## (wie Level 01), Gerinne und Mühlrad wie die Wegbauten.
const SICHT_RINNSAL := 110.0
const SICHT := 150.0
const SICHT_HANDY := 110.0
const SICHT_RAND := 5.0

# =========================================================== Suhle

## Raster der Suhle (s, q): so weit, Abstand der Punkte (Handy × 1,4).
const SUHLE_S := Vector2(5.0, 27.0)
const SUHLE_Q := Vector2(-19.5, -9.3)
const SUHLE_SCHRITT := 0.6
## Der Schlamm liegt so hoch über dem tiefsten Grund der Mulde (m).
const SCHLAMM_UEBER := 0.06
## Tönung des Torfs der Bibliothek (Faktoren je Kanal): aus Moorgrün wird
## dunkelbrauner, nasser Schlamm (gerechnet: Albedo bis 0,34/0,26/0,13
## statt 0,36/0,42/0,25; mit 1,45/0,74/0,62 stand er im Bild lachsrot);
## Rauheit nass.
const SCHLAMM_TON := Color(0.95, 0.62, 0.5)
const SCHLAMM_RAU := 0.3
## Texturmaßstab (Wiederholungen je Meter).
const SCHLAMM_UV := 0.18
## Pfützen Vector4(s, q, Halbachse längs, Halbachse quer): in der Mulde
## (auf dem Schlamm) und auf der Decke um den Keiler (q > −6,6).
const PFUETZEN: Array[Vector4] = [
	Vector4(10.5, -13.4, 1.5, 0.9), Vector4(14.8, -12.2, 1.0, 0.7),
	Vector4(18.6, -14.0, 1.9, 1.1), Vector4(22.0, -12.9, 0.9, 0.6),
	Vector4(12.6, -15.7, 0.8, 0.5),
	Vector4(12.3, -5.3, 0.85, 0.5), Vector4(16.6, -3.4, 0.7, 0.45),
	Vector4(14.9, -6.0, 0.55, 0.32),
]
## So hoch über dem Schlamm bzw. der Decke liegen die Pfützen (m; die
## Bibliothek denkt an rund 2 cm, hier etwas mehr Spiel gegen den Schlamm,
## der selbst nur SCHLAMM_UEBER über dem Feld liegt).
const PFUETZE_UEBER := 0.03

# =========================================================== Rinnsale

## Je Seite (−1 Böschung links, +1 rechts) die Stelle im Wasserriss L1.
const RINNSAL_S := {-1.0: 75.7, 1.0: 77.25}
## Beginn unter der Narbe (m unter der Krone) und Abstand vor der Wand.
const RINNSAL_UNTER_KRONE := 0.55
const RINNSAL_VOR := 0.07
const RINNSAL_WANDERN := 0.12
## Farben (wie `L01Wasser`, das Rinnsal der Kerbe): gedämpft, im Schatten
## der Wand stünde es sonst weiß wie Papier.
const RINNSAL_SCHAUM := Color(0.62, 0.72, 0.74)
const RINNSAL_TIEF := Color(0.14, 0.27, 0.3)

# =========================================================== Bach

## Der Bach beginnt bei BACH_VON (dort hat das Ufer seine Tiefe) und folgt
## dem Bett bis BACH_E; dahinter das Unterwasser.
const BACH_VON := 186.0
const BACH_E := 279.0
const BACH_SCHRITT := 1.5
## Wasser über dem Grund des Betts (m) und Breite des Laufs (das Bett ist
## `L05Gelaende.BETT_BREITE` breit).
const BACH_TIEFE := 0.22
const BACH_BREITE := 2.8
## Die Schnelle (Schaum) der Läufe nach dem Gefälle (`Bachband`) mal so
## viel: Der Tobel fällt bis 9 %, und mit der vollen Schnelle stand der Bach
## im Rückblick als weißer Streifen neben dem Weg (Entwurf §5 D: „kühl
## spiegelnd").
const BACH_SCHNELLE := 0.3
## Farben des Bachs (Thema für `Bachband.stoff`): etwas kühler und dunkler
## als der Waldbach von Level 01, er liegt im Schatten der Südwand.
const BACH_THEMA := {"farbe_tief": Color(0.06, 0.11, 0.12), "farbe_hell": Color(0.14, 0.22, 0.23),
		"himmel_farbe": Color(0.6, 0.68, 0.74)}
## Unterwasser: Spiegel bei s 282 und am Ende der Punkte, Breite des Laufs.
const UNTER_SPIEGEL := Vector2(1.64, 1.48)
const UNTER_BREITE := 7.0
## Der Lauf durch die Spalten L4/L5 beginnt so weit rechts (q > 0) und ist
## so viel breiter als die Lücke (seine Ränder liegen unter der Decke).
const RINNE_Q := 5.4
const RINNE_ZUGABE := 1.2

# =========================================================== Teich, Bruch

## Spiegel des Mühlteichs (Welt-Y). Der Grund der Mulde liegt auf
## `L05Gelaende.TEICH_GRUND` (2,7), die Wiese am Wegende auf 2,88–3,06.
const TEICH_SPIEGEL := 2.92
## Raster des Teichs (s, q) und Abstand der Punkte (Handy × 1,4).
const TEICH_S := Vector2(266.0, 298.5)
const TEICH_Q := Vector2(5.6, 34.0)
const TEICH_SCHRITT := 0.75
## Unter so viel Wasser zeigt der Spiegel seine Mitte; flacher läuft er
## zum Ufer hin aus (Uferabstand des Shaders).
const UFER_TIEFE := 0.18
## Treiben zum Bruch (m/s).
const TEICH_TEMPO := 0.25
## Schuss im Bruch: Spiegel am rechten Ende der begehbaren Breite (q
## −WEHR_Q), mindestens 0,1 über der Zone; dahinter fällt er.
const WEHR_RECHTS := 2.7
const WEHR_Q := 4.3
const WEHR_TEMPO := 2.2
## So weit reicht der Wasserkörper unter die Decke an den Stirnen (m).
const WEHR_UNTER_DECKE := 0.4
## Höchste Oberkante der Todeszone im Bruch (Entwurf §7.3).
const WEHR_ZONE_MAX := 2.6
## Weißwasser (Farben wie die Fälle von Level 01).
const FALL_SCHAUM := Color(0.86, 0.93, 0.95)
const FALL_TIEF := Color(0.2, 0.38, 0.42)

# =========================================================== Gerinne

## Wasser im Gerinne: so tief unter dem Rand, halbe Breite dort.
const GERINNE_UNTER := 0.13
const GERINNE_HALB := 0.42
const GERINNE_TEMPO := 1.6
## Das Wasser schießt mit so viel Tempo (m/s) aus dem Ende des Gerinnes.
const GERINNE_WURF := 1.0

# =========================================================== Mühlrad

const RAD_S := 291.0
const RAD_Q := -7.0
## Halbmesser bis an die Schaufelkanten, die Kränze und die Nabe (m).
const RAD_R := 3.5
const KRANZ_R := 3.15
const NABE_R := 0.32
## Schaufeln, Speichen je Kranz, halbe Breite des Rads (zwischen den
## Kränzen, quer zum Weg).
const SCHAUFELN := 16
const SPEICHEN := 8
const RAD_HALB := 0.5
## Die Schaufeln reichen so tief ins Wasser (m).
const RAD_EINTAUCHEN := 0.2
## Umdrehung (rad/s): unterschlächtig, gemächlich.
const RAD_TEMPO := 0.45
## Böcke: so weit neben der Mitte (quer), so breit am Fuß (längs).
const BOCK_Q := 1.55
const BOCK_FUSS := 0.9

var level: Level05
## Das Mühlrad (dreht sich, ohne Interpolation) und sein Winkel.
var rad: MeshInstance3D
var _winkel := 0.0
## Was `probe()` braucht: die Netze mit Wasser im Bruch (Bach, Weißwasser).
var bruch_netze: Array[MeshInstance3D] = []


## Bauschritte (Entwurf §9.4 Schritt 4 und das Mühlrad aus Schritt 6):
## Wasserflächen, dann Bänder und Rad. Der Knoten ist zugleich die Wurzel
## aller Teile (unter `geometrie`) und dreht das Rad.
static func bauschritte(level_: Level05) -> Array:
	var w := L05Wasser.new()
	w.name = "Wasser"
	w.level = level_
	level_.gewaesser = w
	return [
		{"text": "Suhle, Bach und Mühlteich", "tun": func() -> void:
			level_.geometrie.add_child(w)
			w._flaechen_bauen()},
		{"text": "Weißwasser, Rinnsale und Mühlrad", "tun": w._baender_und_rad},
	]


func _process(delta: float) -> void:
	if rad == null:
		return
	# Vorwärts im Bildtakt; der Winkel bleibt klein (fposmod), damit die
	# Drehung nach Stunden nicht an Genauigkeit verliert.
	_winkel = fposmod(_winkel + delta * RAD_TEMPO, TAU)
	rad.transform = Transform3D(Basis(Vector3.RIGHT, _winkel), Vector3.ZERO)


static func _schluessel() -> String:
	return SPEICHER + ("handy" if Effekte.reduziert else "voll")


static func _sicht() -> float:
	return SICHT_HANDY if Effekte.reduziert else SICHT


# ================================================================ Flächen

## Bach, Teich, Bruch und Gerinne (ein Netz) und die Suhle – aus dem
## Bauspeicher oder neu (das Ufer tastet das gezeichnete Gelände ab).
func _flaechen_bauen() -> void:
	var netze: Dictionary = Bauspeicher.wert(_schluessel(), func() -> Variant:
		var suhle := _suhle_netze()
		return {"bach": _bach_netz(), "schlamm": suhle["schlamm"], "pfuetzen": suhle["pfuetzen"]})
	var bach := _knoten("Bach", netze["bach"] as Mesh, Bachband.stoff(BACH_THEMA), 0.0)
	# Die Wellen heben die Fläche um bis zu 0,05 m (wie `Bachband.bauen`).
	bach.extra_cull_margin = 0.5
	bruch_netze.clear()
	bruch_netze.append(bach)
	_knoten("Suhle", netze["schlamm"] as Mesh, _schlamm_stoff(), 0.0)
	_knoten("Pfützen", netze["pfuetzen"] as Mesh, Materialbibliothek.pfuetze(), 0.0)


func _knoten(name_k: String, netz: Mesh, stoff: Material, sicht: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_k
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if sicht > 0.0:
		mi.visibility_range_end = sicht
		mi.visibility_range_end_margin = SICHT_RAND
	add_child(mi)
	return mi


## Höhe des gezeichneten Geländes an (x, z), Level-Koordinaten.
func _feld(x: float, z: float) -> float:
	return level.gelaende.hoehe(x, z)


## Das Netz im Stoff des Bachs: die Läufe über `Bachband` (Tobel und
## Unterwasser, die Spalten L4/L5), dazu Teich, Bruch und Gerinne als
## eigene Flächen im Format des Bandes (`Bachband.Netz`).
func _bach_netz() -> ArrayMesh:
	var hilf := Node3D.new()
	var band := Bachband.bauen(hilf, _laeufe(), ShaderMaterial.new(),
			{"hoehe": _feld, "feld": L05Gelaende.FELD.grow(-6.0)})
	var netz := Bachband.Netz.new()
	_netz_anhaengen(netz, band.mesh as ArrayMesh, BACH_SCHNELLE)
	hilf.free()
	_teich(netz)
	_bruch(netz)
	for d: Dictionary in Level05.DURCHLAESSE:
		if L05Wegbauten.art(d) == "joch":
			_gerinne_wasser(netz, d)
	return netz.fertig()


## Hängt die Fläche eines fertigen Bandes an `netz` an (gleiches Format),
## die Schnelle (COLOR.r) mal `schnelle`.
static func _netz_anhaengen(netz: Bachband.Netz, mesh: ArrayMesh, schnelle: float) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var a := mesh.surface_get_arrays(0)
	var basis := netz.punkte.size()
	netz.punkte.append_array(a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
	netz.uv.append_array(a[Mesh.ARRAY_TEX_UV] as PackedVector2Array)
	netz.uv2.append_array(a[Mesh.ARRAY_TEX_UV2] as PackedVector2Array)
	for c in (a[Mesh.ARRAY_COLOR] as PackedColorArray):
		netz.farben.append(Color(c.r * schnelle, c.g, c.b, c.a))
	for i in (a[Mesh.ARRAY_INDEX] as PackedInt32Array):
		netz.indizes.append(i + basis)


# ---------------------------------------------------------------- Bach

## Der Zug „Ufer links" (das Ufer zum Bach) aus `Level05.ZUEGE`.
static func _ufer_zug() -> Dictionary:
	for z: Dictionary in Level05.ZUEGE:
		if String(z["name"]) == "Ufer links":
			return z
	return {}


## Spiegel des Bachs im Bett an `s` (D): Grund des Betts (wie
## `L05Gelaende._zug_y`: Bett − BETT_UNTER · f) plus BACH_TIEFE.
func _bett_spiegel(s: float) -> float:
	var m := L05Saum.form_ab(level, _ufer_zug(), s)
	return float(m["bett"]) - L05Gelaende.BETT_UNTER * float(m["f"]) + BACH_TIEFE


## Mitte des Betts (q < 0): Lippe, Fuß der Wand, 0,6 m Grube, dann die
## halbe Bettbreite (`L05Gelaende._zug_y`).
func _bett_q(s: float) -> float:
	var m := L05Saum.form_ab(level, _ufer_zug(), s)
	var lippe := absf(Level05.leitlinie_q(Level05.leitlinie_punkte(-1.0), s)) + 0.4
	return -(lippe + float(m["fuss"]) + 0.6 + L05Gelaende.BETT_BREITE * 0.5)


## Spiegel des Unterwassers an `s` (linear über s, dahinter wie am Ende).
static func _unter_spiegel(s: float) -> float:
	var lauf := L05Gelaende.UNTERWASSER
	var ende := lauf[lauf.size() - 1].x
	return lerpf(UNTER_SPIEGEL.x, UNTER_SPIEGEL.y, clampf((s - 282.0) / (ende - 282.0), 0.0, 1.0))


## Die Läufe für `Bachband.bauen`: der Tobelbach samt Unterwasser, dazu je
## einer quer durch die Spalten L4 und L5 (auf dem Spiegel des Bachs dort).
func _laeufe() -> Array:
	var punkte := PackedVector3Array()
	var breiten := PackedFloat32Array()
	var spiegel := INF
	var s := BACH_VON
	while s <= BACH_E + 0.001:
		# Stromab nie steigend: Das Bett folgt der geglätteten Decke, und
		# wo seine Tiefe wechselt, stiege es sonst um Zentimeter.
		spiegel = minf(spiegel, _bett_spiegel(s))
		var p := level.weg_punkt(s, _bett_q(s))
		p.y = spiegel
		punkte.append(p)
		breiten.append(BACH_BREITE)
		s += BACH_SCHRITT
	# Ins Unterwasser: am Fuß des Wehrs entlang, dann seinem Lauf nach.
	var unter: Array[Vector2] = [Vector2(282.0, -7.0), Vector2(286.0, -7.4)]
	for p2: Vector2 in L05Gelaende.UNTERWASSER:
		if p2.x > 287.0:
			unter.append(p2)
	for sq: Vector2 in unter:
		spiegel = minf(spiegel, _unter_spiegel(sq.x))
		var p := level.weg_punkt(sq.x, sq.y)
		p.y = spiegel
		punkte.append(p)
		breiten.append(lerpf(BACH_BREITE, UNTER_BREITE, clampf((sq.x - BACH_E) / 9.0, 0.0, 1.0)))
	var laeufe: Array = [{"name": "Tobelbach", "punkte": punkte, "breite": breiten}]
	for l: Dictionary in Level05.LUECKEN:
		var name_l := String(l["name"])
		if not (name_l.begins_with("L4") or name_l.begins_with("L5")):
			continue
		var mitte := (float(l["von"]) + float(l["bis"])) * 0.5
		var hoehe := _spiegel_bei(punkte, mitte)
		var weit := float(l["bis"]) - float(l["von"]) + RINNE_ZUGABE
		var rinne := PackedVector3Array()
		for q: float in [RINNE_Q, 0.0, _bett_q(mitte) + 0.3]:
			var p := level.weg_punkt(mitte, q)
			p.y = hoehe
			rinne.append(p)
		laeufe.append({"name": name_l, "punkte": rinne,
				"breite": PackedFloat32Array([weit, weit, weit]), "ende_rund": false})
	return laeufe


## Spiegel des Laufs `punkte` an der Strecke `s` (der nächste Punkt).
func _spiegel_bei(punkte: PackedVector3Array, s: float) -> float:
	var beste := INF
	var y := 0.0
	for p in punkte:
		var d := absf(level.verlauf.get_closest_offset(p) - s)
		if d < beste:
			beste = d
			y = p.y
	return y


# ---------------------------------------------------------------- Teich

## Der Mühlteich als Raster über der Mulde (siehe Kopf): Vierecke, an
## deren Ecken irgendwo Wasser über dem Feld steht; den Rest verdeckt das
## Feld. Der Uferabstand kommt aus der Wassertiefe (ab UFER_TIEFE die
## Mitte). Am Weg endet er auf q = TEICH_Q.x, wo im Bruch der Schuss
## beginnt (`_bruch`, auf derselben Höhe). UV.y zählt gegen q: Der Schaum
## treibt zum Weg, also zum Bruch. Nur benutzte Punkte kommen ins Netz.
func _teich(netz: Bachband.Netz) -> void:
	var schritt := TEICH_SCHRITT * (L05Gelaende.HANDY if Effekte.reduziert else 1.0)
	var spalten := ceili((TEICH_Q.y - TEICH_Q.x) / schritt)
	var zeilen := ceili((TEICH_S.y - TEICH_S.x) / schritt)
	var orte: Array[Vector3] = []
	var raster: Array[Vector2] = []
	var tiefen := PackedFloat32Array()
	for i in zeilen + 1:
		var s := lerpf(TEICH_S.x, TEICH_S.y, float(i) / float(zeilen))
		for k in spalten + 1:
			var q := lerpf(TEICH_Q.x, TEICH_Q.y, float(k) / float(spalten))
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			p.y = TEICH_SPIEGEL
			orte.append(p)
			raster.append(Vector2(s, q))
			tiefen.append(p.y - _feld(p.x, p.z))
	var nummer := {}
	for i in zeilen:
		for k in spalten:
			var a := i * (spalten + 1) + k
			var ecken: Array[int] = [a, a + 1, a + spalten + 2, a + spalten + 1]
			var nass := false
			for e in ecken:
				nass = nass or tiefen[e] > 0.0
			if not nass:
				continue
			var n: Array[int] = []
			for e in ecken:
				if not nummer.has(e):
					nummer[e] = netz.punkte.size()
					var ufer := 1.0 - smoothstep(0.0, UFER_TIEFE, tiefen[e])
					netz.punkt(orte[e], Vector2(raster[e].x, -raster[e].y), TEICH_TEMPO,
							Color(0.0, 1.0, ufer))
				n.append(int(nummer[e]))
			netz.viereck(n[0], n[1], n[2], n[3])


# ---------------------------------------------------------------- Bruch

## Spiegel des Schusses über q: vom Teich (q = TEICH_Q.x) bis WEHR_Q rechts
## linear von TEICH_SPIEGEL auf WEHR_RECHTS.
static func wehr_spiegel(q: float) -> float:
	return lerpf(TEICH_SPIEGEL, WEHR_RECHTS, clampf((TEICH_Q.x - q) / (TEICH_Q.x + WEHR_Q), 0.0, 1.0))


## Der dunkle, schnelle Wasserkörper im Bruch (siehe Kopf): von der
## Teichseite bis WEHR_Q rechts, an den Stirnen WEHR_UNTER_DECKE unter die
## Decke; zu den Stirnen hin Ufer (Schaumsaum), am rechten Ende blendet er
## aus – dort übernimmt das Weißwasser (`_weisswasser`).
func _bruch(netz: Bachband.Netz) -> void:
	var bruch: Dictionary = Level05.LUECKEN[5]
	var von := float(bruch["von"]) - WEHR_UNTER_DECKE
	var bis := float(bruch["bis"]) + WEHR_UNTER_DECKE
	var mitte := (von + bis) * 0.5
	var halb := (bis - von) * 0.5
	const LAENGS := 12
	const QUER := 6
	var erste := netz.punkte.size()
	for k in LAENGS + 1:
		var q := lerpf(TEICH_Q.x, -WEHR_Q, float(k) / float(LAENGS))
		var sicht := 1.0 - smoothstep(-WEHR_Q + 0.9, -WEHR_Q, q)
		for i in QUER + 1:
			var s := lerpf(von, bis, float(i) / float(QUER))
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			p.y = wehr_spiegel(q)
			var ufer := smoothstep(0.3, 1.0, absf(s - mitte) / halb)
			netz.punkt(p, Vector2(s, -q), WEHR_TEMPO, Color(0.85, sicht, ufer))
	for k in LAENGS:
		for i in QUER:
			var a := erste + k * (QUER + 1) + i
			netz.viereck(a, a + 1, a + QUER + 2, a + QUER + 1)


# ---------------------------------------------------------------- Gerinne

## Wasser im Gerinne eines Fluderjochs `d` (`L05Wegbauten`, Kopf): ein
## Streifen GERINNE_UNTER unter dem Rand, mit dessen Gefälle nach links,
## von der Sandsteinwand bis ans Ende über dem Bach. Quer läuft er an den
## Wänden des Halbstamms aus (Uferabstand 1).
func _gerinne_wasser(netz: Bachband.Netz, d: Dictionary) -> void:
	var g := L05Wegbauten.gerinne_lage(level, d)
	var von: float = g["von"]
	var bis: float = g["bis"]
	var mitte: float = g["s"]
	var vorn := LevelWerkzeuge.richtung(level.verlauf, mitte)
	vorn.y = 0.0
	vorn = vorn.normalized()
	const TEILE := 16
	var erste := netz.punkte.size()
	for k in TEILE + 1:
		var x := lerpf(bis - 0.1, von + 0.05, float(k) / float(TEILE))
		var y := L05Wegbauten.gerinne_rand_y(level, d, x) - GERINNE_UNTER
		var sicht := 1.0 - smoothstep(von + 0.6, von + 0.05, x)
		for z: float in [-GERINNE_HALB, 0.0, GERINNE_HALB]:
			var p := level.weg_punkt(mitte, x) + vorn * z
			p.y = y
			netz.punkt(p, Vector2(z, -x), GERINNE_TEMPO,
					Color(0.3, sicht, absf(z) / GERINNE_HALB * 0.95))
	for k in TEILE:
		for i in 2:
			var a := erste + k * 3 + i
			netz.viereck(a, a + 1, a + 4, a + 3)


# ================================================================ Suhle

## Schlamm und Pfützen der Suhle (siehe Kopf): {"schlamm", "pfuetzen"}.
## Der Schlamm ist ein Raster über der Mulde, SCHLAMM_UEBER über ihrem
## tiefsten Grund, nur wo er das Feld überragt – an den Rändern taucht er
## darunter. UV in Metern × SCHLAMM_UV.
func _suhle_netze() -> Dictionary:
	var schritt := SUHLE_SCHRITT * (L05Gelaende.HANDY if Effekte.reduziert else 1.0)
	var spalten := ceili((SUHLE_Q.y - SUHLE_Q.x) / schritt)
	var zeilen := ceili((SUHLE_S.y - SUHLE_S.x) / schritt)
	var orte: Array[Vector3] = []
	var feld := PackedFloat32Array()
	var grund := INF
	for i in zeilen + 1:
		var s := lerpf(SUHLE_S.x, SUHLE_S.y, float(i) / float(zeilen))
		for k in spalten + 1:
			var q := lerpf(SUHLE_Q.x, SUHLE_Q.y, float(k) / float(spalten))
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			var h := _feld(p.x, p.z)
			orte.append(p)
			feld.append(h)
			grund = minf(grund, h)
	var y := grund + SCHLAMM_UEBER
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in zeilen:
		for k in spalten:
			var a := i * (spalten + 1) + k
			var ecken: Array[int] = [a, a + 1, a + spalten + 2, a + spalten + 1]
			var drueber := false
			for e in ecken:
				drueber = drueber or feld[e] < y
			if not drueber:
				continue
			var p: Array[Vector3] = []
			for e in ecken:
				p.append(Vector3(orte[e].x, y, orte[e].z))
			_dreieck_oben(st, p[0], p[1], p[2], SCHLAMM_UV)
			_dreieck_oben(st, p[0], p[2], p[3], SCHLAMM_UV)
	st.index()
	return {"schlamm": st.commit(), "pfuetzen": _pfuetzen_netz(y)}


## Ein Dreieck mit der Oberseite nach vorn (Godot: im Uhrzeigersinn von oben
## gesehen, wie `Bachband.Netz.dreieck`), Normale oben, UV aus x/z × `uv`.
static func _dreieck_oben(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv: float) -> void:
	var folge: Array[Vector3] = [a, b, c]
	if (b - a).cross(c - a).y > 0.0:
		folge = [a, c, b]
	for p in folge:
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(p.x, p.z) * uv)
		st.add_vertex(p)


## Der Stoff des Schlamms (siehe Kopf): Kopie von `moorboden`, getönt.
static func _schlamm_stoff() -> StandardMaterial3D:
	var m := Materialbibliothek.moorboden().duplicate() as StandardMaterial3D
	m.albedo_color = SCHLAMM_TON
	m.roughness = SCHLAMM_RAU
	return m


## Pfützen (PFUETZEN): je eine flache Scheibe mit gewelltem Rand, auf dem
## Schlamm (Höhe `schlamm_y`) bzw. auf der Decke. Die Textur der Pfütze
## liegt dreiplanar in der Welt; UV braucht es nicht.
func _pfuetzen_netz(schlamm_y: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := PropWerkzeug.zufall(5801)
	var leitlinie := Level05.leitlinie_punkte(-1.0)
	for pf in PFUETZEN:
		var mitte := LevelWerkzeuge.punkt_frei(level.verlauf, pf.x, pf.y)
		var auf_decke := pf.y > Level05.leitlinie_q(leitlinie, pf.x)
		mitte.y = (level.boden_bei(pf.x) if auf_decke else schlamm_y) + PFUETZE_UEBER
		var vorn := LevelWerkzeuge.richtung(level.verlauf, pf.x)
		vorn.y = 0.0
		vorn = vorn.normalized()
		var rechts := vorn.cross(Vector3.UP).normalized()
		const RAND := 18
		var phase := rng.randf() * TAU
		var rand: Array[Vector3] = []
		for k in RAND:
			var w := TAU * float(k) / float(RAND)
			var r := 1.0 + 0.16 * sin(w * 3.0 + phase) + 0.08 * sin(w * 5.0 + phase * 1.7)
			rand.append(mitte + vorn * cos(w) * pf.z * r + rechts * sin(w) * pf.w * r)
		for k in RAND:
			_dreieck_oben(st, mitte, rand[k], rand[(k + 1) % RAND], 1.0)
	st.index()
	return st.commit()


# ================================================================ Bänder

## Rinnsale, Weißwasser und die Fälle der Gerinne (je ein Band, siehe Kopf),
## dann das Mühlrad.
func _baender_und_rad() -> void:
	var rinnsale: Array[Wasserfall] = []
	for seite: float in [-1.0, 1.0]:
		var bahn := _rinnsal(seite)
		var rechts := LevelWerkzeuge.richtung(level.verlauf, float(RINNSAL_S[seite])).cross(
				Vector3.UP).normalized()
		var band := Wasserfall.band(self, bahn, 0.24, {"name": "Rinnsal", "breite_ende": 0.34,
				"tempo": 3.2, "spalten": 2, "schritt": 0.35, "farbe_schaum": RINNSAL_SCHAUM,
				"farbe_tief": RINNSAL_TIEF, "richtung": rechts * -seite})
		if band != null:
			rinnsale.append(band)
	_sichtweite(_baender_vereinen(rinnsale, "Rinnsale"), SICHT_RINNSAL)
	var faelle: Array[Wasserfall] = []
	for d: Dictionary in Level05.DURCHLAESSE:
		if L05Wegbauten.art(d) == "joch":
			var fall := _gerinne_fall(d)
			if fall != null:
				faelle.append(fall)
	_sichtweite(_baender_vereinen(faelle, "Gerinnefälle"), _sicht())
	var weiss := _weisswasser()
	if weiss != null:
		bruch_netze.append(weiss)
	_muehlrad()


## Harte Sichtweite (wie `L01Wasser._sichtweite`).
static func _sichtweite(knoten: GeometryInstance3D, weite: float) -> void:
	if knoten == null:
		return
	knoten.visibility_range_end = weite
	knoten.visibility_range_end_margin = SICHT_RAND


## Mehrere Bänder in EIN Netz (ein Zeichenaufruf). Das Längenmaß (UV.y,
## Meter ab der Kante) jedes Bandes wird auf das längste gestreckt: Der
## Stoff kennt nur EINE Länge, an der er die Enden ausblendet.
static func _baender_vereinen(baender: Array[Wasserfall], name_b: String) -> Wasserfall:
	if baender.is_empty():
		return null
	var laengen := PackedFloat32Array()
	var laengste := 0.0
	for b in baender:
		var l := float((b.material_override as ShaderMaterial).get_shader_parameter("laenge"))
		laengen.append(l)
		laengste = maxf(laengste, l)
	var punkte := PackedVector3Array()
	var normalen := PackedVector3Array()
	var uv := PackedVector2Array()
	var indizes := PackedInt32Array()
	for i in baender.size():
		var a := (baender[i].mesh as ArrayMesh).surface_get_arrays(0)
		var basis := punkte.size()
		var dehnen := laengste / maxf(laengen[i], 0.001)
		punkte.append_array(a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
		normalen.append_array(a[Mesh.ARRAY_NORMAL] as PackedVector3Array)
		for t in (a[Mesh.ARRAY_TEX_UV] as PackedVector2Array):
			uv.append(Vector2(t.x, t.y * dehnen))
		for k in (a[Mesh.ARRAY_INDEX] as PackedInt32Array):
			indizes.append(k + basis)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = punkte
	arrays[Mesh.ARRAY_NORMAL] = normalen
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indizes
	var netz := ArrayMesh.new()
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var erstes := baender[0]
	erstes.name = name_b
	erstes.mesh = netz
	(erstes.material_override as ShaderMaterial).set_shader_parameter("laenge", laengste)
	for i in range(1, baender.size()):
		baender[i].free()
	return erstes


## Der Zug „auf" einer Seite (Böschung links/rechts) aus `Level05.ZUEGE`.
static func _boeschung(seite: float) -> Dictionary:
	for z: Dictionary in Level05.ZUEGE:
		if float(z["seite"]) == seite and String(z["art"]) == "auf":
			return z
	return {}


## Die Bahn eines Rinnsals am Wasserriss (siehe Kopf): unter der Narbe aus
## der Wand, an der gebauten Fläche des Saums hinab (RINNSAL_VOR davor), im
## Spalt die Wand bis auf seinen Grund und ein Stück auf ihn hinaus.
func _rinnsal(seite: float) -> PackedVector3Array:
	var s: float = RINNSAL_S[seite]
	var zug := _boeschung(seite)
	var stand: Dictionary = level.saum_flaechen.get(String(zug["name"]), {})
	var flaeche: Dictionary = stand.get("flaeche", {})
	var bahn := PackedVector3Array()
	if flaeche.is_empty():
		return bahn
	var m := L05Saum.form_auf(level, zug, s)
	var deck: float = m["deck"]
	var grund: float = Level05.luecke_bei(s).get("grund_y", deck)
	var zum_weg := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP).normalized() * -seite
	# Das Wasser sucht sich seinen Weg: Es wandert längs der Wand um bis zu
	# RINNSAL_WANDERN hin und her (fester Zufall je Seite); ganz gerade las
	# es sich als Glasrohr.
	var rng := PropWerkzeug.zufall(5811 + int(seite))
	var phase := rng.randf() * TAU
	var h := float(m["hoch"]) - RINNSAL_UNTER_KRONE
	while h > grund - deck + 0.3:
		var versatz := RINNSAL_WANDERN * sin(h * 1.7 + phase) * (0.6 + 0.4 * rng.randf())
		var w := Kanten.flaeche_punkt(flaeche, s + versatz, h)
		if not is_nan(w.x):
			bahn.append(w + zum_weg * RINNSAL_VOR)
		h -= 0.35
	if bahn.is_empty():
		return bahn
	var fuss := bahn[bahn.size() - 1]
	fuss.y = grund + 0.06
	bahn.append(fuss + zum_weg * 0.15)
	bahn.append(fuss + zum_weg * 0.55 + Vector3.DOWN * 0.02)
	return bahn


## Spiegel des Tobelbachs an `s` (wie `_laeufe`: stromab nie steigend).
func _bach_spiegel(s: float) -> float:
	var spiegel := INF
	var t := BACH_VON
	while t <= minf(s, BACH_E) + 0.001:
		spiegel = minf(spiegel, _bett_spiegel(t))
		t += BACH_SCHRITT
	return spiegel


## Der Fall am Ende eines Gerinnes (`d`, Fluderjoch): das Wasser schießt mit
## GERINNE_WURF aus dem Halbstamm und fällt frei vor dem Ufer in den Bach.
func _gerinne_fall(d: Dictionary) -> Wasserfall:
	var g := L05Wegbauten.gerinne_lage(level, d)
	var von: float = g["von"]
	var mitte: float = g["s"]
	var aussen := LevelWerkzeuge.richtung(level.verlauf, mitte).cross(Vector3.UP).normalized() * -1.0
	var y := L05Wegbauten.gerinne_rand_y(level, d, von) - GERINNE_UNTER
	var start := level.weg_punkt(mitte, von)
	start.y = y
	var innen := level.weg_punkt(mitte, von + 0.5)
	innen.y = y + 0.01
	var bahn := PackedVector3Array([innen, start])
	bahn.append_array(_wurf(start, aussen, GERINNE_WURF, _bach_spiegel(mitte) + 0.02))
	return Wasserfall.band(self, bahn, 0.3, {"name": "Gerinnefall", "breite_ende": 0.55,
			"bauch": 0.15, "bauch_ab": 1.5, "tempo": 5.5, "spalten": 3, "schritt": 0.4,
			"farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF, "richtung": aussen,
			"ferne": 1.0})


## Wurfbahn eines Strahls ab `start` mit `tempo` (m/s, waagerecht in
## `richtung`) bis auf `ende_y`, ohne `start` selbst, alle 0,05 s.
static func _wurf(start: Vector3, richtung: Vector3, tempo: float, ende_y: float) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var t := 0.0
	var y := start.y
	while y > ende_y + 0.001:
		t += 0.05
		y = maxf(start.y - 0.5 * 9.81 * t * t, ende_y)
		var p := start + richtung * tempo * t
		p.y = y
		aus.append(p)
	return aus


## Das Weißwasser im Bruch (siehe Kopf): aus dem Teich über den Schuss
## (`wehr_spiegel`, knapp darüber), am rechten Ende frei hinab ins
## Unterwasser und dort noch ein Stück weiter.
func _weisswasser() -> Wasserfall:
	var bruch: Dictionary = Level05.LUECKEN[5]
	var mitte := (float(bruch["von"]) + float(bruch["bis"])) * 0.5
	var breite := float(bruch["bis"]) - float(bruch["von"]) + 0.2
	var aussen := LevelWerkzeuge.richtung(level.verlauf, mitte).cross(Vector3.UP).normalized() * -1.0
	var bahn := PackedVector3Array()
	for q: float in [TEICH_Q.x + 1.6, TEICH_Q.x, 2.5, 0.0, -2.5, -WEHR_Q]:
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, mitte, q)
		p.y = wehr_spiegel(q) + 0.04
		bahn.append(p)
	var unten := _unter_spiegel(mitte) + 0.03
	var fall := _wurf(bahn[bahn.size() - 1], aussen, 2.0, unten)
	bahn.append_array(fall)
	var fuss := bahn[bahn.size() - 1]
	bahn.append(fuss + aussen * 0.8)
	bahn.append(fuss + aussen * 1.8)
	var band := Wasserfall.band(self, bahn, breite, {"name": "Weißwasser",
			"breite_ende": breite + 0.6, "bauch": 0.05, "tempo": 4.2, "spalten": 8,
			"schritt": 0.35, "farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF,
			"richtung": aussen, "ferne": 1.0})
	_sichtweite(band, _sicht())
	return band


# ================================================================ Mühlrad

## Das Mühlrad (siehe Kopf) in seinem Rahmen: Mitte über dem Unterwasser
## (die Schaufeln RAD_EINTAUCHEN tief im Wasser), X = Welle (quer zum Weg,
## +q), Y oben, Z gegen die Laufrichtung. `rad` dreht sich um X; die Böcke
## stehen still. Dreht es positiv, laufen die Schaufeln unten hangab – mit
## dem Wasser.
func _muehlrad() -> void:
	var spiegel := _unter_spiegel(RAD_S)
	var mitte := level.weg_punkt(RAD_S, RAD_Q)
	mitte.y = spiegel - RAD_EINTAUCHEN + RAD_R
	var rechts := LevelWerkzeuge.richtung(level.verlauf, RAD_S).cross(Vector3.UP).normalized()
	var rahmen := Node3D.new()
	rahmen.name = "Mühlrad"
	rahmen.transform = Transform3D(Basis(rechts, Vector3.UP, rechts.cross(Vector3.UP)), mitte)
	add_child(rahmen)
	var grund := _feld(mitte.x, mitte.z) - mitte.y
	var stoff := Riesenstamm.borkenstoff()
	rad = MeshInstance3D.new()
	rad.name = "Rad"
	rad.mesh = Bauspeicher.netz("l05_muehlrad", [RAD_R, KRANZ_R, SCHAUFELN, SPEICHEN],
			_rad_netz)
	rad.material_override = stoff
	rad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rad.visibility_range_end = _sicht()
	rad.visibility_range_end_margin = SICHT_RAND
	# Im Bildtakt gedreht (`_process`): ohne Interpolation, sonst mischte
	# Godot den Stand des letzten Physikschritts hinein und das Rad zitterte
	# (Glattprobe, ARCHITEKTUR.md „Bildtakt und Physiktakt").
	rad.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rahmen.add_child(rad)
	var boecke := MeshInstance3D.new()
	boecke.name = "Böcke"
	boecke.mesh = Bauspeicher.netz("l05_muehlboecke", [snappedf(grund, 0.01)],
			_boecke_netz.bind(grund))
	boecke.material_override = stoff
	boecke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	boecke.visibility_range_end = _sicht()
	boecke.visibility_range_end_margin = SICHT_RAND
	rahmen.add_child(boecke)


## Holz des Rads im Rahmen des Rads (siehe `_muehlrad`): Welle und Nabe,
## zwei Kränze, je Kranz SPEICHEN Speichen, SCHAUFELN Schaufeln als flache
## Bretter zwischen den Kränzen.
static func _rad_netz() -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var ton := L05Wegbauten.PFAHL_TON
	var welle_x := BOCK_Q + 0.32
	L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(-welle_x, 0.0, 0.0),
			Vector3(welle_x, 0.0, 0.0), 0.13, 0.13, {"ton": ton, "moos": 0.1, "seiten": 8,
			"saat": 5901, "buckel": 0.02})
	L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(-RAD_HALB - 0.2, 0.0, 0.0),
			Vector3(RAD_HALB + 0.2, 0.0, 0.0), NABE_R, NABE_R, {"ton": ton, "moos": 0.2,
			"seiten": 10, "saat": 5902, "buckel": 0.03})
	for seite in 2:
		var x := -RAD_HALB if seite == 0 else RAD_HALB
		# Kranz: ein geschlossener Ring, flach (breiter als tief).
		var ring := PackedVector3Array()
		var radien := PackedFloat32Array()
		const TEILE := 40
		for k in TEILE + 1:
			var w := TAU * float(k) / float(TEILE)
			ring.append(Vector3(x, cos(w) * KRANZ_R, sin(w) * KRANZ_R))
			radien.append(0.075)
		L05Wegbauten.holz(st, Transform3D.IDENTITY, ring, radien, {"ton": ton, "moos": 0.35,
				"seiten": 6, "saat": 5910 + seite, "buckel": 0.02, "bezug": Vector3.RIGHT,
				"hoch": 1.7, "anfang": "stumpf", "ende": "stumpf"})
		# Speichen: von der Nabe in den Kranz.
		for k in SPEICHEN:
			var w := TAU * float(k) / float(SPEICHEN) + 0.2
			var r := Vector3(0.0, cos(w), sin(w))
			L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(x, 0.0, 0.0) + r * (NABE_R - 0.05),
					Vector3(x, 0.0, 0.0) + r * (KRANZ_R + 0.02), 0.065, 0.05, {"ton": ton,
					"moos": 0.15, "seiten": 6, "saat": 5920 + seite * 10 + k, "anfang": "stumpf",
					"ende": "stumpf", "buckel": 0.02}, 1.2)
	# Schaufeln: radial von innen am Kranz bis RAD_R, quer über beide Kränze.
	var innen := KRANZ_R - 0.55
	var halb_r := (RAD_R - innen) * 0.5
	for k in SCHAUFELN:
		var w := TAU * float(k) / float(SCHAUFELN)
		var r := Vector3(0.0, cos(w), sin(w))
		var mitte := r * (innen + halb_r)
		var dicke := 0.035
		L05Wegbauten.holz(st, Transform3D.IDENTITY, PackedVector3Array([
				mitte + Vector3(-RAD_HALB - 0.14, 0.0, 0.0), mitte,
				mitte + Vector3(RAD_HALB + 0.14, 0.0, 0.0)]),
				PackedFloat32Array([dicke, dicke, dicke]), {"ton": Color(0.86, 0.8, 0.72),
				"moos": 0.2, "seiten": 6, "saat": 5950 + k, "buckel": 0.0, "bezug": r,
				"hoch": halb_r / dicke, "anfang": "stumpf", "ende": "stumpf"})
	return Riesenstamm.fertig(st)


## Die Böcke unter der Welle (still, im Rahmen des Rads): je Seite zwei
## Pfosten aus dem Grund (`grund`, Y relativ zur Mitte) bis unter die Welle,
## ein Lagerbalken quer darunter, eine Strebe.
static func _boecke_netz(grund: float) -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var holz := {"ton": L05Wegbauten.PFAHL_TON, "moos": 0.5, "seiten": 8, "anfang": "stumpf"}
	for seite in 2:
		var x := -BOCK_Q if seite == 0 else BOCK_Q
		for z: float in [-BOCK_FUSS, BOCK_FUSS]:
			var o := holz.duplicate()
			o["saat"] = 5980 + seite * 4 + int(z > 0.0)
			o["ende"] = "stumpf"
			L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(x, grund - 0.4, z),
					Vector3(x, -0.3, z * 0.15), 0.12, 0.1, o)
		var ob := holz.duplicate()
		ob["saat"] = 5990 + seite
		ob["ende"] = "offen"
		ob["anfang"] = "offen"
		L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(x, -0.25, -0.55),
				Vector3(x, -0.25, 0.55), 0.11, 0.11, ob)
		var os := holz.duplicate()
		os["saat"] = 5995 + seite
		os["seiten"] = 6
		os["ende"] = "stumpf"
		L05Wegbauten.stange(st, Transform3D.IDENTITY, Vector3(x, grund * 0.55, -BOCK_FUSS * 0.6),
				Vector3(x, grund * 0.55, BOCK_FUSS * 0.6), 0.06, 0.06, os)
	return Riesenstamm.fertig(st)


# ================================================================ Probe

## Opt-in "wasser" von `werkzeuge/level_check.gd` (über `Level05.wasserprobe`,
## Form wie `freiraumprobe`): je Abweichung eine Zeile "ABWEICHUNG …",
## zuletzt "GEPRUEFT n".
##   1. Todeszonen: genau eine je Lücke aus `Level05.LUECKEN` mit der
##      Oberkante "tod_y", und so viele Zonen wie Einträge in den Wegdaten
##      (keine dazu, keine weg).
##   2. Kein Teil des Wassers tödlich: nichts darunter in der Gruppe
##      `todeszonen` oder `wasser` (die Gefahr `Wasser.tscn`), kein
##      Kollisionsobjekt.
##   3. Wehr: Die Zone des Bruchs reicht höchstens bis WEHR_ZONE_MAX, und
##      jeder Punkt des Wassers im Bruch über der begehbaren Breite liegt
##      über ihr (Entwurf §7.3: „auf Y 2,6 unter dem Weißwasser").
static func probe(level_: Level05, wasser: L05Wasser) -> PackedStringArray:
	var zeilen := PackedStringArray()
	var geprueft := 0
	# --- 1. Todeszonen
	var oben := {}
	var anzahl := 0
	for k in level_.get_tree().get_nodes_in_group("todeszonen"):
		if not level_.is_ancestor_of(k):
			continue
		anzahl += 1
		var name_z := String(k.name)
		for l: Dictionary in Level05.LUECKEN:
			if name_z == String(l["name"]):
				var hoch := -INF
				for f in k.find_children("*", "CollisionShape3D", true, false):
					var form := f as CollisionShape3D
					var huelle := form.shape as ConvexPolygonShape3D
					if huelle == null:
						continue
					for p in huelle.points:
						hoch = maxf(hoch, level_.to_local(form.global_transform * p).y)
				(oben.get_or_add(name_z, []) as Array).append(hoch)
	for l: Dictionary in Level05.LUECKEN:
		var name_l := String(l["name"])
		var liste: Array = oben.get(name_l, [])
		geprueft += 1
		if liste.size() != 1:
			zeilen.append("ABWEICHUNG Todeszone %s: %d statt einer" % [name_l, liste.size()])
		elif absf(float(liste[0]) - float(l["tod_y"])) > 0.001:
			zeilen.append("ABWEICHUNG Todeszone %s: Oberkante %.3f statt %.2f"
					% [name_l, float(liste[0]), float(l["tod_y"])])
	geprueft += 1
	if anzahl != level_.weg.todeszonen.size():
		zeilen.append("ABWEICHUNG %d Todeszonen im Level, die Wegdaten nennen %d"
				% [anzahl, level_.weg.todeszonen.size()])
	# --- 2. Nichts am Wasser ist tödlich
	if wasser == null:
		zeilen.append("ABWEICHUNG kein Wasser gebaut")
		zeilen.append("GEPRUEFT %d" % geprueft)
		return zeilen
	for k in wasser.find_children("*", "Node", true, false):
		geprueft += 1
		if k.is_in_group("todeszonen") or k.is_in_group("wasser") or k is CollisionObject3D:
			zeilen.append("ABWEICHUNG %s ist tödlich oder fest" % String(wasser.get_path_to(k)))
	# --- 3. Wehr: Zone unter dem Weißwasser
	var bruch: Dictionary = Level05.LUECKEN[5]
	var zone_y: float = (oben.get(String(bruch["name"]), [INF]) as Array)[0]
	if zone_y > WEHR_ZONE_MAX + 0.001:
		zeilen.append("ABWEICHUNG Todeszone %s: Oberkante %.2f über %.1f"
				% [String(bruch["name"]), zone_y, WEHR_ZONE_MAX])
	var von := float(bruch["von"])
	var bis := float(bruch["bis"])
	var halb := level_.breite_bei(von - 0.5) * 0.5
	var tiefste := INF
	var punkte := 0
	for netz in wasser.bruch_netze:
		var lage := level_.global_transform.affine_inverse() * netz.global_transform
		for f in netz.mesh.get_faces():
			var p := lage * f
			var s := level_.verlauf.get_closest_offset(p)
			if s < von or s > bis:
				continue
			var mitte := LevelWerkzeuge.punkt_frei(level_.verlauf, s, 0.0)
			var rechts := LevelWerkzeuge.richtung(level_.verlauf, s).cross(Vector3.UP).normalized()
			if absf((p - mitte).dot(rechts)) > halb:
				continue
			punkte += 1
			tiefste = minf(tiefste, p.y)
	geprueft += punkte
	if punkte == 0:
		zeilen.append("ABWEICHUNG Wehr: kein Wasser über der begehbaren Breite des Bruchs")
	elif tiefste <= zone_y:
		zeilen.append("ABWEICHUNG Wehr: Wasser bis Y %.2f, nicht über der Zone (%.2f)"
				% [tiefste, zone_y])
	print("  Wasser: Wehrzone Oberkante %.2f, Wasser im Bruch über |q| ≤ %.1f mindestens Y %.2f (%d Punkte)"
			% [zone_y, halb, tiefste, punkte])
	zeilen.append("GEPRUEFT %d" % geprueft)
	return zeilen
