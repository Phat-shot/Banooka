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
##   `Materialbibliothek.moorboden` als `duplicate()` (satt dunkelbraun
##   getönt, nass glänzend: Der Torf der Bibliothek ist grün), der dem Feld
##   der Mulde (`L05Gelaende.SUHLE`) knapp darüber folgt und sie bis gut
##   einen halben Meter über ihrem Grund deckt; im Grund zusammenhängende
##   Lachen (`Materialbibliothek.pfuetze`, der Glanz), eben auf einem
##   Spiegel. Dazu ein Schlammfleck mit Pfützen auf der Decke um den
##   schlafenden Keiler: Er liegt am Wegrand vor der Suhle (L05Jagd,
##   SCHLAF_Q), und der Entwurf will ihn „in der glänzenden Suhle". Alle
##   Ränder laufen über die Deckung im Alpha aus (Raster, siehe
##   `_suhle_netze`). WARUM so: Als Ebene 6 cm über dem tiefsten Grund
##   deckte der Schlamm nur einen schmalen Streifen der Mulde; im Bild bei
##   s 8 änderten sich 1,6 % der Bildpunkte, die Mulde blieb grauer Kies,
##   und die Pfützen standen als graue Scheiben mit harter Kante im Gras
##   (Prüfung P6).
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
##   zwei Bänder aus `Wasserfall.band` (rechts): der Schuss ab der
##   Bruchkante und der Fall, weiß und gewölbt (`_weisswasser`).
## * MÜHLRAD Ø 7 m bei s 291 / q −8,5 im Unterwasser, unterschlächtig: Die
##   Welle liegt quer zum Lauf, das Rad steht in seiner Fließrichtung (ab
##   ≈ 13 m bildrechts im Bild, von der Kamera her fast von vorn),
##   Schaufeln 0,2 m im Wasser, zwei Böcke tragen die Welle, einer am
##   Ufer, einer im Lauf. Es dreht sich im Bildtakt (`_process`) – deshalb
##   ohne Interpolation (`PHYSICS_INTERPOLATION_MODE_OFF`), sonst zitterte
##   es (Glattprobe).
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
## alles ohne Schatten: Bach, Teich und Bruch in EINEM Netz im Stoff des
## Bachs (1), das Wasser in den Gerinnen in einem zweiten mit Nahblende (1,
## seit den Mängeln der Runde 1, siehe `_flaechen_bauen`); Schlamm (1) und
## Pfützen (1) der Suhle; die Rinnsale (1), die Fälle der Gerinne (1), der
## Schuss (1) und der Fall (1) des Weißwassers je als ein Band; Rad (1)
## und Böcke (1). Zusammen 10; zugleich im Bild höchstens 6 (am
## Mühlbach), weil Suhle und Rinnsale nur von Nahem zu sehen sind. Sichtweiten siehe SICHT_*; der
## Bach ohne: Eine Sichtweite zählt ab der Mitte der Hülle, die des Bachs
## (Tobel bis Feldrand) liegt weit vom Bild.
##
## BAUSPEICHER: Das Netz des Bachs (das Ufer wird am gezeichneten Gelände
## abgetastet), Schlamm und Pfützen liegen nach dem ersten Laden je
## Handyweg und Rechner im `Bauspeicher` (das Feld des Handys hat weitere
## Punkte), das Mühlrad als `Bauspeicher.netz`. Die Bänder sind kurz und
## entstehen bei jedem Laden neu. Gemessen (Bauzeitprobe, Rechner, je vier
## Läufe mit frischem Benutzerordner): kalt 173–225 ms für Flächen und Suhle
## (als Ebene: 135–184) und 111–139 ms für Bänder und Rad, im zweiten
## Laden 2–4 und 5–10 ms; das ganze Level kalt 7,40–7,60 s (vorher
## 7,10–7,65 s), im zweiten Laden 231–325 ms.
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
##   * Die Schlammfläche ist ein `duplicate()` von `moorboden` mit Braun,
##     weniger Rauheit und Spiegelung, die Pfützen eines von `pfuetze` mit
##     Deckung aus der Scheitelfarbe (Entwurf §1 Nr. 24: geteilte Stoffe nur
##     als Kopie).
##   * Das Mühlrad steht 1,5 m weiter im Lauf (q −8,5 statt −7) und in
##     dessen Richtung (siehe RAD_Q).
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

## Raster über der Mulde (s, q; `L05Gelaende.SUHLE`, Grund auf Y 25,6, die
## Decke von A auf 26,0) und Abstand der Punkte (Handy × 1,4).
const SUHLE_S := Vector2(2.0, 29.0)
const SUHLE_Q := Vector2(-20.5, -10.0)
const SUHLE_SCHRITT := 0.5
## Der Schlamm liegt so hoch über dem Feld (m) – er folgt ihm, statt als
## Ebene über dem Grund zu stehen.
const SCHLAMM_UEBER := 0.03
## Er deckt das Feld ganz bis so hoch über dem Grund der Mulde (x) und läuft
## bis y aus; das Rauschen schiebt diese Höhen um ± SCHLAMM_WANDERN.
const SCHLAMM_RAND := Vector2(0.36, 0.62)
const SCHLAMM_WANDERN := 0.14
## Im Grund (bis so hoch darüber) ist er nasser: die Farbe mal SCHLAMM_NASS.
const SCHLAMM_NASS_BIS := 0.3
const SCHLAMM_NASS := 0.72
## Schlamm auf der Decke um den schlafenden Keiler (`L05Jagd.SCHLAF_S`/`_Q`,
## der Leib liegt 2 m hangauf): Ellipsen Vector4(s, q, Halbachse längs,
## Halbachse quer). Raster (s, q) mit Abstand; zum Rand der Decke (die
## Leitlinie liegt auf q −6,6, dahinter die Erdböschung) läuft er ab DECKE_Q.x
## + DECKE_AUSLAUF aus.
const SCHLAMM_DECKE: Array[Vector4] = [Vector4(14.4, -4.6, 4.3, 1.75),
		Vector4(10.6, -5.4, 1.8, 0.95), Vector4(18.4, -4.2, 1.6, 1.0)]
const DECKE_S := Vector2(7.5, 21.0)
const DECKE_Q := Vector2(-6.45, -2.0)
const DECKE_SCHRITT := 0.35
const DECKE_AUSLAUF := 0.5
## Ränder der Flecken auf der Decke: Breite des Auslaufs (im Maß der
## Ellipse, 1 − r) und wie weit das Rauschen ihn schiebt – für den Schlamm
## (x) und die Pfützen (y).
const DECKE_WEICH := Vector2(0.35, 0.3)
const DECKE_WANDERN := Vector2(0.2, 0.15)
## Über die Decke (m): Schlamm, darauf die Pfützen.
const DECKE_SCHLAMM := 0.02
const DECKE_PFUETZE := 0.035
## Tönung des Torfs der Bibliothek (Faktoren je Kanal; Albedo dort von
## 0,11/0,15/0,10 bis 0,36/0,42/0,25): satt dunkelbraun, im Mittel
## 0,16/0,12/0,06. Mit 0,95/0,62/0,50 (P6) lag er bei 0,22/0,18/0,09, mit
## 0,85/0,42/0,34 stand er von oben orangerot im Bild, mit 1,45/0,74/0,62
## lachsrot. Mit der tieferen Sonne aus R1 liegt die Mulde fast ganz im
## Schatten ihres Rands; dort ging der Schlamm mit 0,68/0,42/0,32 ins
## Schwarze über (gerendert im Mittel 12/9/7 von 255), daher etwas heller.
const SCHLAMM_TON := Color(0.82, 0.54, 0.4)
## Nass glänzend (Rauheit), aber mit wenig Spiegelung (`metallic_specular`,
## Vorgabe 0,5): Die Kamera sieht die Suhle flach, und dort warf sie den
## Himmel als graulila Schleier zurück (Prüfung P6; im Bild verglichen:
## Rauheit 0,14/0,45/0,6, Spiegelung 0,5/0,3/0,2). So bleibt sie braun, und
## das Licht bricht sich nur noch streifig an der Normalmap. Rauheit 0,42
## statt 0,14: Glatt spiegelte die ganze Fläche den lila Abendhimmel, und die
## Suhle stand im Startbild als graue Asphaltbahn (Bild-Jury R1, Mangel 9);
## den Glanz tragen jetzt die Pfützen allein.
const SCHLAMM_RAU := 0.42
const SCHLAMM_GLANZ := 0.2
## Texturmaßstab (Wiederholungen je Meter).
const SCHLAMM_UV := 0.18
## Pfützen in der Mulde: ein Spiegel so hoch über ihrem Grund; wo Wasser
## steht, sagt ein Feld aus Rauschen (Streuung, Anteil, Rand), das mit der Höhe über
## dem Grund (mal PFUETZE_HANG) sinkt – im flachen Grund zusammenhängende
## Lachen, an den Hängen keine. Der Spiegel bleibt mindestens
## PFUETZE_UEBER über dem Schlamm.
const PFUETZE_SPIEGEL := 0.065
const PFUETZE_STREUUNG := 0.5
const PFUETZE_ANTEIL := 0.2
const PFUETZE_RAND := 0.22
const PFUETZE_HANG := 6.0
const PFUETZE_UEBER := 0.015
## Pfützen auf dem Schlamm der Decke (wie SCHLAMM_DECKE).
const PFUETZEN_DECKE: Array[Vector4] = [Vector4(12.2, -5.3, 1.5, 0.8),
		Vector4(16.9, -3.5, 1.0, 0.55), Vector4(9.9, -5.0, 0.8, 0.45),
		Vector4(18.9, -4.5, 0.8, 0.45)]
## Rauschen für die Ränder (feste Saat) und seine Frequenz (je m).
const SUHLE_SAAT := 5803
const SUHLE_RAUSCHEN := 0.22

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
## Weißwasser: Der Schuss beginnt an der Bruchkante zum Teich (q) und läuft
## so viele Punkte (je 0,05 s Wurf) in den Fall hinein.
const WEHR_KANTE := 4.5
const SCHUSS_UEBER := 4
## Der Fall an der rechten Kante: Wölbung (Anteil der Breite, die zweite
## Lage 1,4-mal), Tempo und Farben – fast weiß auch zwischen den
## Schaumstreifen, sonst stand er von der Seite als hellblaue Glasscheibe
## da (Prüfung P6).
const WEHRFALL_BAUCH := 0.1
const WEHRFALL_TEMPO := 6.5
const WEHRFALL_SCHAUM := Color(0.94, 0.97, 0.98)
const WEHRFALL_TIEF := Color(0.7, 0.8, 0.82)

# =========================================================== Gerinne

## Wasser im Gerinne: so tief unter dem Rand, halbe Breite dort.
const GERINNE_UNTER := 0.13
const GERINNE_HALB := 0.42
const GERINNE_TEMPO := 1.6
## Uferabstand des Shaders bis GERINNE_SAUM vor der Wand (darunter keine
## helle Uferfarbe und kein Schaumsaum, `bach.gdshader` ab 0,45 bzw. 0,6).
const GERINNE_UFER := 0.4
const GERINNE_SAUM := 0.06
## Das Wasser schießt mit so viel Tempo (m/s) aus dem Ende des Gerinnes.
const GERINNE_WURF := 1.0

# =========================================================== Mühlrad

## Mitte des Rads (s, q): 1,5 m weiter im Lauf des Unterwassers als im
## Entwurf (q −7). Dort stand es am Rand des Laufs, und ab s 292 hing die
## untere Kante über trockenem Grund (Prüfung P6, Strahlprobe gegen das
## Bachnetz). Die Ebene des Rads folgt dem Lauf (`_unter_richtung`).
const RAD_S := 291.0
const RAD_Q := -8.5
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

## Bach, Teich und Bruch (ein Netz), das Gerinnewasser und die Suhle – aus dem
## Bauspeicher oder neu (das Ufer tastet das gezeichnete Gelände ab).
func _flaechen_bauen() -> void:
	var netze: Dictionary = Bauspeicher.wert(_schluessel(), func() -> Variant:
		var suhle := _suhle_netze()
		return {"bach": _bach_netz(), "gerinne": _gerinne_netz(), "schlamm": suhle["schlamm"],
				"pfuetzen": suhle["pfuetzen"]})
	var stoff := Bachband.stoff(BACH_THEMA)
	var bach := _knoten("Bach", netze["bach"] as Mesh, stoff, 0.0)
	# Die Wellen heben die Fläche um bis zu 0,05 m (wie `Bachband.bauen`).
	bach.extra_cull_margin = 0.5
	# Das Wasser in den Gerinnen blendet nahe der Kamera aus wie die Joche
	# selbst (`L05Wegbauten.nahblende`) – sonst schwebte es dort allein.
	var gerinne := _knoten("Gerinnewasser", netze["gerinne"] as Mesh,
			L05Wegbauten.nahblende(stoff, L05Wegbauten.NAH_IMMER), 0.0)
	gerinne.extra_cull_margin = 0.5
	bruch_netze.clear()
	bruch_netze.append(bach)
	_knoten("Suhle", netze["schlamm"] as Mesh, _schlamm_stoff(), SICHT_RINNSAL)
	_knoten("Pfützen", netze["pfuetzen"] as Mesh, _pfuetzen_stoff(), SICHT_RINNSAL)


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
	return netz.fertig()


## Das Wasser in den Gerinnen der Fluderjoche als eigenes Netz im Stoff des
## Bachs: Es blendet nahe der Kamera aus wie die Joche (siehe
## `_flaechen_bauen`); bis Runde 1 hing es am Netz des Bachs.
func _gerinne_netz() -> ArrayMesh:
	var netz := Bachband.Netz.new()
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


## Fließrichtung des Unterwassers (waagerecht) an `s`: das Stück des Laufs
## `L05Gelaende.UNTERWASSER`, in dem `s` liegt (an den Enden das erste bzw.
## letzte).
func _unter_richtung(s: float) -> Vector3:
	var lauf := L05Gelaende.UNTERWASSER
	var i := 0
	while i < lauf.size() - 2 and lauf[i + 1].x <= s:
		i += 1
	var d := level.weg_punkt(lauf[i + 1].x, lauf[i + 1].y) - level.weg_punkt(lauf[i].x, lauf[i].y)
	d.y = 0.0
	return d.normalized()


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
## von der Sandsteinwand bis ans Ende über dem Bach. Ruhig und dunkel
## (Schnelle 0, Uferabstand bis GERINNE_UFER: die Farbe der Tiefe, kein
## Schaumsaum); erst auf den letzten GERINNE_SAUM Metern zur Wand des
## Halbstamms läuft es aus (Uferabstand 1,1). WARUM: Steht die Figur an L4,
## schwebt die Rückblickkamera rund 1 m über dem Gerinne von D3, und
## schäumendes Bachwasser füllte das untere Siebtel des Bildes (Prüfung P6).
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
		var innen := GERINNE_HALB - GERINNE_SAUM
		for z: float in [-GERINNE_HALB, -innen, 0.0, innen, GERINNE_HALB]:
			var p := level.weg_punkt(mitte, x) + vorn * z
			p.y = y
			var ufer := 1.1 if absf(z) > innen + 0.001 else absf(z) / innen * GERINNE_UFER
			netz.punkt(p, Vector2(z, -x), GERINNE_TEMPO, Color(0.0, sicht, ufer))
	for k in TEILE:
		for i in 4:
			var a := erste + k * 5 + i
			netz.viereck(a, a + 1, a + 6, a + 5)


# ================================================================ Suhle

## Schlamm und Pfützen der Suhle (siehe Kopf): {"schlamm", "pfuetzen"} –
## je EIN Netz aus der Mulde und der Decke um den Keiler. Alles sind Raster
## mit Deckung im Alpha der Scheitelfarbe: Die Ränder laufen über einen
## halben Meter aus, statt als Kante einer Fläche oder Scheibe im Gras zu
## stehen (Prüfung P6).
func _suhle_netze() -> Dictionary:
	var rauschen := FastNoiseLite.new()
	rauschen.seed = SUHLE_SAAT
	rauschen.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	rauschen.frequency = SUHLE_RAUSCHEN
	rauschen.fractal_octaves = 2
	var handy := L05Gelaende.HANDY if Effekte.reduziert else 1.0
	var schlamm := SurfaceTool.new()
	schlamm.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pfuetzen := SurfaceTool.new()
	pfuetzen.begin(Mesh.PRIMITIVE_TRIANGLES)
	_mulde_schreiben(schlamm, pfuetzen, rauschen, SUHLE_SCHRITT * handy)
	_decke_schreiben(schlamm, pfuetzen, rauschen, DECKE_SCHRITT * handy)
	schlamm.index()
	pfuetzen.index()
	return {"schlamm": schlamm.commit(), "pfuetzen": pfuetzen.commit()}


## Schlamm und Lachen in der Mulde (Raster SUHLE_S × SUHLE_Q): Der Schlamm
## liegt SCHLAMM_UEBER über dem Feld und deckt es bis SCHLAMM_RAND über dem
## tiefsten Grund, im Grund nasser (dunkler). Die Lachen liegen eben auf
## PFUETZE_SPIEGEL über dem Grund, wo das Rauschen (zweite Lage, versetzt)
## im Flachen Wasser stehen lässt (siehe PFUETZE_*).
func _mulde_schreiben(schlamm: SurfaceTool, pfuetzen: SurfaceTool, rauschen: FastNoiseLite,
		schritt: float) -> void:
	var spalten := ceili((SUHLE_Q.y - SUHLE_Q.x) / schritt)
	var zeilen := ceili((SUHLE_S.y - SUHLE_S.x) / schritt)
	var orte := PackedVector3Array()
	var raster := PackedVector2Array()
	var feld := PackedFloat32Array()
	var grund := INF
	for i in zeilen + 1:
		var s := lerpf(SUHLE_S.x, SUHLE_S.y, float(i) / float(zeilen))
		for k in spalten + 1:
			var q := lerpf(SUHLE_Q.x, SUHLE_Q.y, float(k) / float(spalten))
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			var h := _feld(p.x, p.z)
			orte.append(p)
			raster.append(Vector2(s, q))
			feld.append(h)
			grund = minf(grund, h)
	var boden := PackedVector3Array()
	var boden_farbe := PackedColorArray()
	var lache := PackedVector3Array()
	var lache_farbe := PackedColorArray()
	for e in orte.size():
		var s := raster[e].x
		var q := raster[e].y
		var ueber := feld[e] - grund
		var rand := ueber + rauschen.get_noise_2d(s, q) * SCHLAMM_WANDERN
		var nass := lerpf(SCHLAMM_NASS, 1.0, smoothstep(0.05, SCHLAMM_NASS_BIS, ueber))
		boden.append(Vector3(orte[e].x, feld[e] + SCHLAMM_UEBER, orte[e].z))
		boden_farbe.append(Color(nass, nass, nass,
				1.0 - smoothstep(SCHLAMM_RAND.x, SCHLAMM_RAND.y, rand)))
		var wasser := rauschen.get_noise_2d(s * 1.3 + 41.0, q * 1.3 - 17.0) * PFUETZE_STREUUNG \
				+ PFUETZE_ANTEIL - ueber * PFUETZE_HANG
		lache.append(Vector3(orte[e].x, maxf(grund + PFUETZE_SPIEGEL,
				feld[e] + SCHLAMM_UEBER + PFUETZE_UEBER), orte[e].z))
		lache_farbe.append(Color(1.0, 1.0, 1.0, smoothstep(0.0, PFUETZE_RAND, wasser)))
	_raster_schreiben(schlamm, boden, boden_farbe, zeilen, spalten)
	_raster_schreiben(pfuetzen, lache, lache_farbe, zeilen, spalten)


## Schlamm und Pfützen auf der Decke um den Keiler (SCHLAMM_DECKE,
## PFUETZEN_DECKE): eben über der Decke, die Ränder aus den Ellipsen und
## dem Rauschen; zum Rand der Decke hin laufen beide aus.
func _decke_schreiben(schlamm: SurfaceTool, pfuetzen: SurfaceTool, rauschen: FastNoiseLite,
		schritt: float) -> void:
	var spalten := ceili((DECKE_Q.y - DECKE_Q.x) / schritt)
	var zeilen := ceili((DECKE_S.y - DECKE_S.x) / schritt)
	var boden := PackedVector3Array()
	var boden_farbe := PackedColorArray()
	var lache := PackedVector3Array()
	var lache_farbe := PackedColorArray()
	for i in zeilen + 1:
		var s := lerpf(DECKE_S.x, DECKE_S.y, float(i) / float(zeilen))
		var decke := level.boden_bei(s)
		for k in spalten + 1:
			var q := lerpf(DECKE_Q.x, DECKE_Q.y, float(k) / float(spalten))
			var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
			var rand := smoothstep(DECKE_Q.x, DECKE_Q.x + DECKE_AUSLAUF, q)
			var n := rauschen.get_noise_2d(s, q)
			boden.append(Vector3(p.x, decke + DECKE_SCHLAMM, p.z))
			boden_farbe.append(Color(1.0, 1.0, 1.0, smoothstep(0.0, DECKE_WEICH.x,
					_flecken(SCHLAMM_DECKE, s, q) + n * DECKE_WANDERN.x) * rand))
			lache.append(Vector3(p.x, decke + DECKE_PFUETZE, p.z))
			lache_farbe.append(Color(1.0, 1.0, 1.0, smoothstep(0.0, DECKE_WEICH.y,
					_flecken(PFUETZEN_DECKE, s, q) + n * DECKE_WANDERN.y) * rand))
	_raster_schreiben(schlamm, boden, boden_farbe, zeilen, spalten)
	_raster_schreiben(pfuetzen, lache, lache_farbe, zeilen, spalten)


## Höchster Wert 1 − r über die Ellipsen Vector4(s, q, Halbachse längs,
## quer) an (s, q), r der Ellipsenabstand (1 auf dem Rand); kleiner 0 außen.
static func _flecken(flecken: Array[Vector4], s: float, q: float) -> float:
	var wert := -INF
	for f in flecken:
		wert = maxf(wert, 1.0 - Vector2((s - f.x) / f.z, (q - f.y) / f.w).length())
	return wert


## Ein Raster aus (`zeilen` + 1) × (`spalten` + 1) Punkten (zeilenweise) als
## Dreiecke in `st`, mit Scheitelfarbe (Alpha = Deckung); Vierecke, an deren
## Ecken nirgends Deckung ist, entfallen. Oberseite nach oben (Godot: im
## Uhrzeigersinn von oben gesehen, wie `Bachband.Netz.dreieck`), Normale
## oben, UV aus x/z × SCHLAMM_UV (die Pfütze liest ihre Textur dreiplanar).
static func _raster_schreiben(st: SurfaceTool, orte: PackedVector3Array, farben: PackedColorArray,
		zeilen: int, spalten: int) -> void:
	for i in zeilen:
		for k in spalten:
			var a := i * (spalten + 1) + k
			var ecken: Array[int] = [a, a + 1, a + spalten + 2, a + spalten + 1]
			var deckt := false
			for e in ecken:
				deckt = deckt or farben[e].a > 0.002
			if not deckt:
				continue
			for paar in 2:
				var dreieck := PackedInt32Array([ecken[0], ecken[1 + paar], ecken[2 + paar]])
				var pa := orte[dreieck[0]]
				if (orte[dreieck[1]] - pa).cross(orte[dreieck[2]] - pa).y > 0.0:
					dreieck = PackedInt32Array([dreieck[0], dreieck[2], dreieck[1]])
				for e in dreieck:
					st.set_normal(Vector3.UP)
					st.set_color(farben[e])
					st.set_uv(Vector2(orte[e].x, orte[e].z) * SCHLAMM_UV)
					st.add_vertex(orte[e])


## Der Stoff des Schlamms (siehe Kopf): Kopie von `moorboden`, getönt, nass,
## durchsichtig nach der Deckung (Scheitelfarbe). Er zeichnet vor den
## Pfützen (`render_priority`): Beide sind durchsichtig und schreiben keine
## Tiefe, die Reihenfolge entschiede sonst der Abstand der Mitten.
static func _schlamm_stoff() -> StandardMaterial3D:
	var m := Materialbibliothek.moorboden().duplicate() as StandardMaterial3D
	m.albedo_color = SCHLAMM_TON
	m.roughness = SCHLAMM_RAU
	m.metallic_specular = SCHLAMM_GLANZ
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.render_priority = -1
	return m


## Der Stoff der Pfützen: Kopie von `pfuetze`, ihr Alpha mal der Deckung.
static func _pfuetzen_stoff() -> StandardMaterial3D:
	var m := Materialbibliothek.pfuetze().duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	return m


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
	bruch_netze.append_array(_weisswasser())
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


## Ort auf dem Spiegel des Tobelbachs an `s` (Level-Koordinaten): Mitte des
## Betts, Höhe des Spiegels – für den Bachnebel der Stimmung (`L05Stimmung`).
func bach_ort(s: float) -> Vector3:
	var p := level.weg_punkt(s, _bett_q(s))
	p.y = _bach_spiegel(s)
	return p


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


## Das Weißwasser im Bruch (siehe Kopf) in zwei Bändern. Der SCHUSS beginnt
## an der Bruchkante zum Teich (WEHR_KANTE), liegt knapp über dem Spiegel
## des Schusses (`wehr_spiegel`) und läuft SCHUSS_UEBER Punkte in den Fall
## hinein (er blendet auf seinem letzten Fünftel aus, das läge sonst vor der
## rechten Kante). Der FALL stürzt von der rechten Kante frei hinab ins
## Unterwasser und läuft dort aus: heller, schneller und gewölbt
## (WEHRFALL_*). WARUM getrennt: Begann ein Band schon über dem Teich, lag
## sein Anfang als weißes Blatt mit harter Kante auf dem Spiegel, und als
## EIN Band (eine Farbe, ein Bauch für Schuss und Fall) las sich der Fall
## von der Seite als durchsichtige, hellblaue Scheibe (Prüfung P6). Ein
## Bauch auf dem Schuss wölbte ihn nach oben. Rückgabe: beide Knoten.
func _weisswasser() -> Array[Wasserfall]:
	var bruch: Dictionary = Level05.LUECKEN[5]
	var mitte := (float(bruch["von"]) + float(bruch["bis"])) * 0.5
	var breite := float(bruch["bis"]) - float(bruch["von"]) + 0.2
	var aussen := LevelWerkzeuge.richtung(level.verlauf, mitte).cross(Vector3.UP).normalized() * -1.0
	var schuss := PackedVector3Array()
	for q: float in [WEHR_KANTE, 2.5, 0.0, -2.5, -WEHR_Q]:
		var p := LevelWerkzeuge.punkt_frei(level.verlauf, mitte, q)
		p.y = wehr_spiegel(q) + 0.04
		schuss.append(p)
	var fall := PackedVector3Array([schuss[schuss.size() - 1]])
	fall.append_array(_wurf(fall[0], aussen, 2.0, _unter_spiegel(mitte) + 0.03))
	var fuss := fall[fall.size() - 1]
	fall.append(fuss + aussen * 0.8)
	fall.append(fuss + aussen * 1.8)
	for i in range(1, mini(SCHUSS_UEBER + 1, fall.size())):
		schuss.append(fall[i])
	var baender: Array[Wasserfall] = []
	var oben := Wasserfall.band(self, schuss, breite, {"name": "Weißwasser",
			"breite_ende": breite + 0.2, "bauch": 0.05, "tempo": 4.2, "spalten": 8,
			"schritt": 0.35, "farbe_schaum": FALL_SCHAUM, "farbe_tief": FALL_TIEF,
			"richtung": aussen, "ferne": 1.0})
	# Der Fall in zwei Lagen (ein Netz, `_baender_vereinen`): Der Stoff deckt
	# höchstens 0,45 bis 0,85; zwei Lagen mit verschobenem Muster decken
	# 0,7 bis 0,98, und der Fall steht weiß statt gläsern.
	var lagen: Array[Wasserfall] = []
	for lage in 2:
		var bahn := PackedVector3Array()
		for p in fall:
			bahn.append(p + (aussen * 0.1 + Vector3.DOWN * 0.03) * float(lage))
		var band := Wasserfall.band(self, bahn, breite + 0.1 + 0.4 * float(lage), {
				"name": "Wehrfall", "breite_ende": breite + 0.8 + 0.4 * float(lage),
				"bauch": WEHRFALL_BAUCH * (1.0 + 0.4 * float(lage)), "bauch_ab": 0.6,
				"tempo": WEHRFALL_TEMPO, "spalten": 8, "schritt": 0.2,
				"farbe_schaum": WEHRFALL_SCHAUM, "farbe_tief": WEHRFALL_TIEF,
				"richtung": aussen, "ferne": 1.0})
		if band != null:
			lagen.append(band)
	var unten := _baender_vereinen(lagen, "Wehrfall")
	for band: Wasserfall in [oben, unten]:
		if band != null:
			_sichtweite(band, _sicht())
			baender.append(band)
	return baender


# ================================================================ Mühlrad

## Das Mühlrad (siehe Kopf) in seinem Rahmen: Mitte über dem Unterwasser
## (die Schaufeln RAD_EINTAUCHEN tief im Wasser), X = Welle (quer zum Lauf
## des Unterwassers), Y oben, Z gegen die Fließrichtung. `rad` dreht sich
## um X; die Böcke stehen still. Dreht es positiv, laufen die Schaufeln
## unten mit dem Wasser.
func _muehlrad() -> void:
	var spiegel := _unter_spiegel(RAD_S)
	var mitte := level.weg_punkt(RAD_S, RAD_Q)
	mitte.y = spiegel - RAD_EINTAUCHEN + RAD_R
	var welle := _unter_richtung(RAD_S).cross(Vector3.UP).normalized()
	var rahmen := Node3D.new()
	rahmen.name = "Mühlrad"
	rahmen.transform = Transform3D(Basis(welle, Vector3.UP, welle.cross(Vector3.UP)), mitte)
	add_child(rahmen)
	# Die Böcke reichen bis unter den tiefsten Grund an ihren vier Füßen: Der
	# eine steht am Ufer, der andere im Lauf.
	var grund := INF
	for x: float in [-BOCK_Q, BOCK_Q]:
		for z: float in [-BOCK_FUSS, BOCK_FUSS]:
			var fuss := rahmen.transform * Vector3(x, 0.0, z)
			grund = minf(grund, _feld(fuss.x, fuss.z) - mitte.y)
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

## Opt-in "wasser" von `werkzeuge/level_check.gd` (über `Level05.wasser_zonenprobe`,
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
