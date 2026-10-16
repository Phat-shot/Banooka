extends RefCounted
class_name L05Saum
## Level 05, Modul „Saum": die Ränder des Weges als modellierte Kanten
## (Entwurf §5 B/C/D, §8.1, §9.1) – Lösswände im Hohlweg, Böschungen über
## den Terrassen, Sandstein am Sonnenhang des Tobels, das Ufer zum Bach,
## die Wehrwände, die Stirnen der Lücken und die Setzstufen der Treppen.
##
## WOHER DIE FORM KOMMT. Die Ränder stehen als Züge in `Level05.ZUEGE` (je
## Seite eine Linie in (s, q) und Stützstellen für Höhe, Wandwinkel,
## Überhang der Grasnarbe und Fels). Dieselben Werte liest das Gelände
## (`L05Gelaende`) über `form_auf`/`form_ab`: Es liegt unter jeder Wand und
## jeder Krone und tritt erst hinter der Krone über sie – so stoßen Saum und
## Gelände ohne Naht aneinander.
##
## PROFILE (je Querschnitt ein `GelaendeSaum.Profil`, gebaut mit den Helfern
## aus `Kanten`):
##   auf    Böschung hinauf, von der Krone her: Krone, Grasnarbe mit
##          Überhang zum Weg (Punkte 0–5, so hängen die Karten aus `Kanten`
##          – Halme und Wurzeln – unter der Narbe), unterschnittene Wand-
##          krone, Wand im Winkel des Zuges, Fuß, Schulter, unter die Decke.
##          Kanten.profil_boeschung (am steilsten gut 50°) und profil_wand
##          (Schichtfels mit Simsen ab 5,5 m) treffen eine Lösswand von
##          3–5 m unter 78–84° mit Narbe nicht; dieses Profil nimmt ihre
##          Teile: Narbe wie `Kanten.profil_ab`, Farben über `Kanten.farbe`,
##          Rauschen der Wand nur nach außen (`GelaendeSaum`: Richtung 2).
##          Die Platte hinter der Krone endet nie über dem gezeichneten
##          Gelände (PLATTE_UNTER, gemessen dort, wohin der Querschnitt
##          wirklich zeigt: `_platte_lage`), und wo der nächste Zug beginnt,
##          sinkt das ganze Profil unter Ufer und Gelände (`uebergabe`).
##   ab     Ufer oder Wehrwand hinab, von der Lippe her (wie `profil_ab`,
##          30 Punkte dort, 16 hier): Narbe über der Lippe, Wand bis aufs
##          Bett, Fuß unter das Bett des Geländes. Erde und Moos am Ufer,
##          Schichtfels an der Wehrwand („fels").
##   Stirn  an den Lippen der sechs Lücken `Kanten.profil_stirn` mit der
##          Wegmaske; unter einer schmalen hellen Lippe schnell dunkel
##          (STIRN_HELL…STIRN_DUNKEL; Entwurf §8.4: dunkle Flanke), an der
##          Landeseite mit längerer Grasnarbe über dem Spalt (STIRN_NAH).
##   Stufe  an jeder Stufe der Decke (Suhlgraben, Wurzeltreppen S1–S3): eine
##          angestrahlte Setzstufe aus Löss mit Narbe nach der Wegmaske; am
##          Graben läuft ihr Fuß als Schlammsohle bis in seine Mitte.
## In einer Lücke laufen die Wände der Seiten bis auf ihren Grund hinab
## (der Spalt hat Seiten), das Ufer wird zur Rinne ausgeschnitten.
##
## BAU: alle Linien über `Kanten.linien_schritte` in GEMEINSAMEN Stücken zu
## 30 m (je Stück ein Netz und ab 85 m seine grobe Fassung, dazu die Karten
## bis 55 m) – mit `seite_schritte` hätte jede der 24 Linien einen eigenen
## Knoten, und der Rückblick sieht fast alle zugleich. Sichtweite 400 m:
## Die Kamera sieht bis 380 m (Level05.tscn), und ein Stück, das in der
## Ferne verschwände, ließe das Gelände unter ihm als Graben stehen. Ein
## Stoff für alles (`thema`), keine Schatten, keine Kollision – die Linien
## sind die Kollisionskanten (Leitlinie, Lippe der Schulter, Stufen).
## Bauspeicher: `speicher()` (Level 05 nennt ihn, `Kanten` legt ab).
##
## FREIRAUM (Entwurf §7.1): K1 – nichts vom Saum liegt über |q| ≤ 3,5; die
## Narbe tritt höchstens `Level05.ZUEGE` „Überhang" (≤ 0,45 m) vor die
## Linie, die Linien liegen bei |q| ≥ 4,1. K3 – die Kronen der Böschungen
## stehen höchstens 5,6 m über der Decke neben dem Weg; ob sie die Eiche
## verdecken, misst `Level05.freiraumprobe`.

const NAME := "Saum"
## Abstand der Querschnitte an den Seiten und quer über den Weg (m), in den
## Übergaben (`uebergabe`) enger: Dort schrumpft das Kronenband, und das
## Plattenende lief schräg durch die Querschnitte – zwischen zweien stand es
## über dem steil fallenden Feld bis 0,16 m frei (s 180; Prüfung P3, Runde 3).
const SCHRITT := 0.7
const SCHRITT_QUER := 0.45
const SCHRITT_UEBERGABE := 0.35
## Sichtweite der Stücke (siehe Kopf).
const SICHT := 400.0
## Krone hinter der Wand: so weit reicht der Saum hinter die Wandkrone,
## und so hoch steigt er dort (das Gelände tritt vorher über ihn).
const KRONE_WEIT := 2.8
const KRONE_STEIGT := 0.06
## Übergabe (siehe `uebergabe`): Am Ende der Übergabe liegt die Krone so weit
## unter der Decke, und von Platte und Kronenband bleibt dieser Anteil.
const UEBERGABE_SINKT := -0.08
const UEBERGABE_BAND := 0.11
## Das äußere Ende der Platte liegt mindestens so tief unter dem Gelände
## (`L05Gelaende.hoehe`): Es endet nie frei über ihm (siehe `_platte_lage`).
## Es folgt der Linie, geglättet mit PLATTE_GLATT (m, wie jeder Profilpunkt
## mit seinem Fenster, `GelaendeSaum.Profil.glatt`).
const PLATTE_UNTER := 0.12
const PLATTE_GLATT := 2.5
## Stufen der Decke: Querschnitte der Seiten so weit davor und dahinter (m;
## siehe `bauschritte`).
const STUFE_SPIEL := 0.02
## STUFE_ERDE (R4; Bild-Jury R4, Wurzeltreppen: „An beiden Enden jeder
## Stufe sitzt ein lachsfarbener, untexturierter Block mit harter Kante …
## wie ein Platzhalter"): Zwischen den beiden Querschnitten einer Seite an
## der Stufe (STUFE_SPIEL davor und dahinter) steht die Fläche von Fuß und
## Schulter senkrecht – die Höhe der Stufe, vom Fuß der Wand bis unter die
## Decke. Ihre Punkte tragen Rasen (Anteil 1); den zeichnet der Stoff an
## steilen Flächen nicht (fels_schichten.gdshader: `r_anteil` mal
## smoothstep über n.y), und darunter lag der nackte Fels in SANDSTEIN
## (rgb 212/100/38 im Bild s 140). An diesen Querschnitten tragen Fuß,
## Schulter und Decke jetzt Löss im Schatten: Die Stufe läuft als Erde in
## die Wand, auf dem Tritt davor und dahinter verläuft sie über 0,7 m (bis
## zum nächsten Querschnitt) in den Rasen. Den größeren Teil des Blocks
## zeichnete aber die Setzstufe selbst an ihren Enden, wo der Weg Rasen
## trägt (`_profil_stufe`, Anteil `r`; Probe: dieser Ton schwarz, der Block
## blieb lachsfarben) – siehe STUFE_UNTER_DECKE.
const STUFE_ERDE := Color(0.3, 1.0, 0.35, 0.0)
## Verdeckung (.x) und Erde (.y) der Punkte 15–17 des Querschnitts „auf"
## unter der Decke, vom Fuß der Wand bis 0,35 m in den Weg. R4: Sie trugen
## Rasen (1) über Fels (Erde 0–0,05, Verdeckung 0,78); unter der Decke
## liegen sie unsichtbar, aber an jeder Stufe der Decke stehen sie als
## senkrechte Fläche über die Breite des Rasenrands – den Rasen zeichnet der
## Stoff dort nicht, es blieb der Sandstein: der lachsfarbene Block an
## beiden Enden jeder Stufe (s 140: rgb 175/83/28; Probe: diese Punkte
## schwarz, der Block wurde schwarz; die Setzstufe selbst und STUFE_ERDE
## schwarz, er blieb). Jetzt Erde, an der Stufe im Schatten wie der Fuß der
## Setzstufe (`_profil_stufe`, 0,45). Punkt 15 liegt am Fuß auch flach im
## Bild; er behält seine Verdeckung.
const STUFE_UNTER_DECKE := Vector2(0.45, 1.0)
## Welle der Kronenhöhe entlang der Seite (m) und ihr Maßstab (1/m).
const KRONE_WELLE := 0.35
const KRONE_WELLE_DICHTE := 0.045
## Dazu ein feines Zacken der Krone (m, 1/m) und ein Wechsel der Narbe
## (Anteil): Mit der Welle allein (22 m lang) lag die Oberkante der
## Lösswände auf Bildlänge linealgerade, der Hohlweg las sich wie ein
## Betonkanal (Bild-Jury R1, Mangel 5: „Oberkante in Höhe und Grundriss
## verrauschen, ±0,3–0,5 m"). Die Narbe tritt höchstens × (1 + NARBE_WECHSEL)
## vor: 0,45 · 1,15 = 0,52 m, die Linien liegen bei |q| ≥ 4,1 – K1 (über
## |q| ≤ 3,5 frei) bleibt.
const KRONE_ZACKE := 0.3
const KRONE_ZACKE_DICHTE := 0.32
const NARBE_WECHSEL := 0.15
## Uferwand vor dem Wehr bemoost (`_profil_ab`): voll ab y, bis z, aus bei w.
const UFER_MOOS := Vector4(258.0, 264.0, 276.0, 279.0)
## Stirnen der Lücken: Verdeckung (Faktor auf die Albedo, `fels_schichten`)
## unter der Narbe nach der Tiefe unter der Lippe – bis STIRN_TIEFE.x
## STIRN_HELL, ab STIRN_TIEFE.y STIRN_DUNKEL, dazwischen weich.
## GESCHICHTE: Bis Runde 1 trug die ganze Flanke die Verdeckung von
## `Kanten.profil_stirn` (0,12–0,3) mal 0,45 – gerendert 0,002–0,004, die
## Lücken standen als schwarze Rechtecke (Bild-Jury R1, Mangel 6). Runde 1
## hellte die Flanke bis 2,4 m Tiefe auf (0,7 oben); damit lag im Anlauf
## genau das helle Band im Bild: Die Kamera sieht über die nahe Lippe nur
## die oberen 1–2 m der fernen Stirn, und die lasen sich als erdbraune
## Stufe oder Bordkante statt als Abgrund (Bild-Jury R2, Mangel 1; Luma im
## Lückenstreifen 67–88, in Level 01 11). Jetzt ist nur die Lippe hell –
## Narbe, Wurzelfasern, die Lippensteine auf der Decke –, ab 0,4 m Tiefe ist
## die Albedo unter 0,1 wie in Level 01 (Entwurf §8.4).
## R3 (Bild-Jury R3, Mangel „Lücken": „ein exakt rechteckiger, rein
## schwarzer Schlitz mit schnurgeraden Lippen … Die Flanken als Erdprofil
## mit Verlauf von hell nach dunkel statt Schwarz ab 0,4 m"): Unter
## STIRN_TIEFE.x fällt die Verdeckung jetzt stetig ab, auf 1/e je
## STIRN_ABKLINGEN Meter (0,39 bei 0,4 m, 0,18 bei 0,9 m, 0,08 bei 1,5 m)
## – ein Erdprofil, das ins Dunkle geht, statt einer Kante bei 0,4 m; das
## helle Band ist schmal wie vorher, darunter liegt kein gleich helles
## Stück mehr (R2: „Stufe"). Die Lippe bricht unregelmäßig aus
## (STIRN_AUSBRUCH: bis so tief, in Buckeln nach `Kanten.welle`), und in
## der Tiefe liegt Dunst (`L05Stimmung._lueckendunst`).
## STIRN_ZUNGE (R4; Bild-Jury R4, Lücken: „Beide Lippen laufen schnurgerade
## über die ganze Breite, ohne Ausbruch und ohne überhängende Grasnarbe";
## Vorschlag: „2–3 Narbenzungen, die etwa 0,2 m überhängen"): Wo eine Welle
## über den Bogen der Querlinie (Dichte STIRN_ZUNGE_DICHTE je m, je Lippe
## eigener Versatz) über STIRN_ZUNGE_AB steigt, hängt die Narbe bis
## STIRN_ZUNGE weiter über den Spalt und sackt 5 cm ab – auf 7–9 m Breite
## zwei, drei Zungen von gut einem Meter. Nur die Narbe (Punkte 1–3); die
## Kante der Decke und der Körper bleiben gerade (Findling-Regel: Die
## Zunge ist Gras über dem Spalt, kein Boden).
const STIRN_ZUNGE := 0.22
const STIRN_ZUNGE_AB := 0.25
const STIRN_ZUNGE_DICHTE := 0.75
const STIRN_HELL := 0.62
const STIRN_DUNKEL := 0.025
const STIRN_TIEFE := Vector2(0.1, 0.4)
const STIRN_ABKLINGEN := 0.6
const STIRN_AUSBRUCH := 0.14
## Verdeckung der Wand einer Seite an ihrem Fuß, wo sie in einer Lücke in
## den Spalt hinabläuft (`_auf_in_luecke`), und auf dem Grund der Lücke.
## R4 (Bild-Jury R4, Lücken: „Wo die Lippenstufe an die linke Sandsteinwand
## stößt, steht in der Wand ein schwarzes, senkrechtes Loch", s 220;
## Vorschlag: „dort dunkelbraun statt schwarz"): 0,42 bzw. 0,32 statt 0,22
## bzw. 0,06. Das „Loch" ist die Wand der Seite unter der Decke, von Punkt
## 11 bis auf den Grund, im Schatten der Sandsteinwand – mit 0,22 → 0,06
## (und auch mit 0,22 → 0,18) im Bild rgb 34/11/3, 55 % der Bildpunkte
## fast schwarz (x 260–340, y 430–600); mit 0,42 → 0,32 rgb 61/19/4 und
## 8 %: die Sandsteinwand läuft dunkel in den Spalt hinab. Der Spalt
## selbst (die Stirnen, STIRN_DUNKEL) bleibt, wie er ist. Mit 0,76 (bis R2)
## standen dort helle Platten (siehe `_auf_in_luecke`).
const LUECKE_WAND_DUNKEL := 0.42
const LUECKE_GRUND_DUNKEL := 0.32
## LIPPENSTUFE an den Enden einer Lücke (Abschluss R3, eigene Messung s 130:
## die Platten links und rechts des Spalts Luma 70, rgb 140/47/9 – der Spalt
## selbst 6,6): Zwischen dem letzten Querschnitt vor der Lippe (Schulter
## hell, Verdeckung 0,6–0,78) und dem ersten darin (auf dem Grund, 0,06)
## stand ein senkrechter Vorhang von 2–3 m, dessen Farbe linear von hell
## nach dunkel lief, mit den Normalen der Schulter (nach oben) beleuchtet –
## eine angestrahlte Platte. Jetzt stehen in der Lücke zwei Querschnitte
## mehr, LIPPE_STUFE.x und .y hinter der Lippe: Der erste senkt Fuß und
## Schulter nur LIPPE_TIEF unter die Decke, in LIPPE_DUNKEL – der Vorhang
## wird oben ein schmales Erdband wie die Stirn (STIRN_HELL … ), darunter
## dunkel bis auf den Grund. Der Querschnitt knapp vor der Lippe dunkelt
## Fuß und Schulter auf LIPPE_SCHULTER ab: Die Schulter läuft zur Lippe
## hin ins Dunkle, statt an ihr hell abzubrechen.
const LIPPE_STUFE := Vector2(0.02, 0.04)
const LIPPE_TIEF := 0.45
## R4: 0,24 statt 0,16 – dunkle Erde statt Schwarz (siehe LUECKE_WAND_DUNKEL).
const LIPPE_DUNKEL := 0.24
const LIPPE_SCHULTER := 0.5
## Landeseite (die Lippe näher an der Kamera, deren Stirn vom Spalt weg
## zeigt): Die Grasnarbe hängt so viel weiter über den Spalt (m, an ihrem
## Rand; bis höchstens STIRN_NAH_MAX) und deckt den unteren Teil der fernen
## Stirn – so liegt die Lücke im Bild zwischen zwei Rasenkanten.
const STIRN_NAH := 0.28
const STIRN_NAH_MAX := 0.6
## Ein Querschnitt gilt erst so weit hinter einer Lippe als in der Lücke (m;
## siehe `_luecke`). Kleiner als der Querschnitt knapp innerhalb der Lippe
## (`Kanten.feste_strecken`: 2 × EPS = 1 cm).
const LUECKE_SPIEL := 0.002
## Löss der Wände (Ton der Erde im Stoff der Kanten) und Rotocker des
## Sandsteins am Sonnenhang (Ton der warmen Schichtbänke).
## R3 (Bild-Jury R3, Tobel D: „Links steht dieselbe orange Lösswand wie in
## B"; Entwurf §5 D: rotockerfarbene Sandsteinbänder): Der Sandstein röter
## (1,24/0,78/0,58 statt 1,12/0,86/0,68), weniger entsättigt
## (SANDSTEIN_GRAU statt der Vorgabe 0,3 des Stoffs) und in engeren Bänken
## (SCHICHT_DICHTE je m statt 0,35): Auf der 5 m hohen Wand standen zwei
## Bänke, kaum heller als der Löss. Der Löss selbst bleibt (er trägt keine
## Bänke, `fels` 0 in `Level05.ZUEGE`).
## Abschluss R3: Der Ton des Lösses fast neutral (bis R3 1,15/1,0/0,74 auf
## der orangen Erde des Waldwegs) – die Farbe kommt aus der eigenen Textur
## (siehe LÖSSTEXTUR).
const LOESS := Color(1.0, 0.97, 0.92)
const SANDSTEIN := Color(1.24, 0.78, 0.58)
const SANDSTEIN_GRAU := 0.15
const SCHICHT_DICHTE := 0.6
## LÖSSWAND (Abschluss R3; Bild-Jury R3, Lösswände: „Schichtung und
## Wurzelvorhänge aus §5 B sind nicht zu sehen"; Vorschlag: „lösstypische
## senkrechte Rillen und Schichtbänder"). Ohne Fels (Zug „fels" < 0,3) und
## ab RILLE_HOCH m Wand:
##   * RILLEN: alle RILLE_ABSTAND m (± ein Drittel, aus `Kanten.welle`)
##     eine senkrechte Rinne, RILLE_TIEF in die Wand und um RILLE_DUNKEL
##     dunkler, dazwischen Rippen. Ein Querschnitt steht alle 0,7 m – eine
##     Rinne ist ein bis zwei Querschnitte breit, im Bild ein weicher,
##     dunkler Streifen von oben nach unten.
##   * BÄNDER: zwei dunklere Bänder (Bodenhorizonte im Löss) auf
##     BAND_HOEHEN der Wand (Anteil von unten), ihre Höhe wandert mit
##     `Kanten.welle` um ±BAND_WANDERN; um BAND_DUNKEL dunkler und etwas
##     weniger Erde (der Sandstein des Stoffs scheint mit seinen Schichten
##     durch, BAND_FELS).
const RILLE_HOCH := 1.5
const RILLE_ABSTAND := 2.6
const RILLE_TIEF := 0.12
const RILLE_DUNKEL := 0.32
const BAND_HOEHEN := Vector2(0.35, 0.7)
const BAND_WANDERN := 0.12
const BAND_DUNKEL := 0.22
const BAND_FELS := 0.3


## KRONENBAND (R4; Bild-Jury R4, Gesamtbild A–D, Vorschlag 2: „Das
## Kronenband der Böschung im Schatten dunkler machen, damit es als Rahmen
## wirkt"): Auf den Kronen der Böschungen – der Platte des Saums hinter der
## Wandkrone und dem Gelände bis KRONENBAND_WEIT hinter dem Wegrand
## (`L05Gelaende._zusatz`) – liegt die Verdeckung um KRONENBAND_AO tiefer,
## zwischen KRONENBAND_S (weich über 10 m ein und aus): A, B, C und D bis
## vor die Mühlwiese. Ein dunkles Band am oberen Bildrand links und rechts
## statt einer hellen Rasenebene, auf der der Graben liegt; der ferne Hang
## bleibt hell.
const KRONENBAND_AO := 0.8
const KRONENBAND_S := Vector2(20.0, 260.0)
const KRONENBAND_WEIT := 8.0


## Faktor auf die Verdeckung des Kronenbands an `s` (siehe KRONENBAND_AO).
static func kronenband(s: float) -> float:
	var drin := smoothstep(KRONENBAND_S.x - 5.0, KRONENBAND_S.x + 5.0, s) \
			* (1.0 - smoothstep(KRONENBAND_S.y - 5.0, KRONENBAND_S.y + 5.0, s))
	return lerpf(1.0, KRONENBAND_AO, drin)


## Bauschritte: der Stoff, je Seite und Zug „… wird vermessen", die Stirnen
## und Stufen in einem Schritt, dann „Saum wird gebaut" – aus dem
## Bauspeicher nach dem Stoff EIN Schritt „Saum wird geladen".
static func bauschritte(level: Level05) -> Array:
	var linien: Array = []
	var feste := Kanten.feste_strecken(level.weg)
	# Je Stufe der Decke ein Querschnitt STUFE_SPIEL davor und dahinter, jeder
	# mit der Decke seiner Seite. WARUM: `feste_strecken` setzt sie nur 5 mm
	# (Kanten.EPS) neben die Naht, und `GelaendeSaum.linie` verwirft Teil-
	# strecken unter 5 mm Bogenlänge. Auf der Innenseite der Kurve sind es
	# knapp weniger: Am Suhlgraben fehlten links beide Querschnitte (23,495
	# und 23,5, 28,095 und 28,1), und das Gitter lief über 0,7 m von der
	# oberen Decke auf die Sohle – davor eine Kerbe in der Schulter (0,26 m
	# unter der Kollision), in der Grabenecke ein Keil (0,8 m über der
	# Sohle; Prüfung P3, Runde 2).
	var nahte := PackedFloat32Array()
	for st: Vector3 in _stufen(level.weg):
		feste.append_array([st.x - STUFE_SPIEL, st.x + STUFE_SPIEL])
		nahte.append(st.x)
	for i in Level05.ZUEGE.size():
		var zug: Dictionary = Level05.ZUEGE[i]
		var auf := String(zug["art"]) == "auf"
		var linie := Level05.zug_linie(zug)
		# Dazu je ein Querschnitt an jeder Ecke der Linie: Ohne ihn lief das
		# Gitter als Sehne über die Ecke der Nische hinter G2 (die Leitlinie
		# knickt dort um 68°), und in der Ecke blieb ein Fleck Schulter ohne
		# Saum, unter dem nur das Feld lag (0,9 m tief; Nahtprobe P3).
		var feste_zug := feste.duplicate()
		for p: Vector2 in linie:
			feste_zug.append(p.x)
		# Je Lippe die Querschnitte der Lippenstufe (LIPPE_STUFE).
		for l: Dictionary in Level05.LUECKEN:
			for d in [LIPPE_STUFE.x, LIPPE_STUFE.y]:
				feste_zug.append_array([float(l["von"]) + d, float(l["bis"]) - d])
		# In der Übergabe Querschnitte alle SCHRITT_UEBERGABE Meter.
		var von_ueb := _uebergabe_von(zug)
		if not is_nan(von_ueb):
			var s_ueb := von_ueb
			while s_ueb < float(zug["bis"]) - SCHRITT_UEBERGABE * 0.5:
				feste_zug.append(s_ueb)
				s_ueb += SCHRITT_UEBERGABE
		# Die Plattenenden eines Zuges „auf" entstehen beim ersten Querschnitt
		# für alle zugleich (`_platte_lage`); dazu braucht er Linie und Stellen.
		var profil := _profil_auf.bind(level, zug, {"linie": linie, "feste": feste_zug,
				"stufen": nahte}) if auf \
				else _profil_ab.bind(level, zug)
		# Die gebaute Fläche jedes Zuges (`Kanten.flaeche_punkt`): An ihr laufen
		# die Rinnsale des Wasserrisses hinab (`L05Wasser`).
		var stand := {}
		level.saum_flaechen[String(zug["name"])] = stand
		linien.append({"seite": float(zug["seite"]), "linie": linie, "profil": profil,
				"gruppe": String(zug["name"]), "schritt": SCHRITT, "karten": true,
				"saat": 5101 + i, "feste_s": feste_zug, "stand": stand})
	linien.append_array(_querlinien(level))
	# Der Stoff geht leer hinein und wird im ersten Schritt gefüllt (Level05,
	# Kopf: STOFFE): Sandstein und Moos kosten kalt gut 0,1 s.
	var stoff := ShaderMaterial.new()
	var schritte: Array = [{"text": "Sandstein und Moos für die Wände", "tun": func() -> void:
		L05Gelaende.stoff_uebertragen(stoff, Kanten.stoff(thema()))}]
	schritte.append_array(Kanten.linien_schritte(level.geometrie, level.weg, linien, stoff, NAME,
			speicher(), {"sicht": SICHT}))
	schritte.append({"text": "Wurzelvorhänge an den Lösswänden", "tun": func() -> void:
		_wurzelvorhaenge(level)})
	return schritte


## Schlüssel im Bauspeicher. Er nennt `Effekte.reduziert` (bauspeicher.gd,
## Kopf: SCHLÜSSEL): Die Plattenenden liegen unter dem GEZEICHNETEN Feld
## (`_platte_lage`), und das setzt seine Punkte auf dem Handyweg 1,4-mal
## weiter auseinander (`L05Gelaende._abstand`). Mit einem Schlüssel für
## beide lud ein Werkzeug mit gemeinsamem user:// (oder ein späterer
## Schalter im Spiel) einen Saum, der gegen das andere Feld gebaut war.
static func speicher() -> String:
	return "l05_saum_" + ("handy" if Effekte.reduziert else "voll")


## Stoff der Kanten: Erde ist Löss (eigene Textur, siehe LÖSSTEXTUR) – Wände, Narbe von unten, Ufer; die warmen Schichtbänke des
## Sandsteins in Rotocker (Tobel, Sonnenhang, Entwurf §5 D). Rasen, Moos und
## Kalk wie in Level 01 (die Wegdecke trägt denselben Rasen).
## Die Erde der Wände in größerem Maß (ERDE_KACHEL statt 0,4) und mit
## weniger Relief: Im feinen Maß der Wegdecke flimmerten die Risse des Lösses
## auf den Wänden als Rauschen, mit pixeligen hellen Strichen auf der
## Schattenseite (Bild-Jury R1, Mangel 5).
const ERDE_KACHEL := 0.22
const RELIEF := 0.18


static func thema() -> Dictionary:
	return {"erde": loess_textur(), "fels": sandstein_textur(),
			"uniforms": {"erde_ton": LOESS, "fels_warm": SANDSTEIN, "erde_kachel": ERDE_KACHEL,
				"relief": RELIEF, "fels_grau_anteil": SANDSTEIN_GRAU,
				"schicht_dichte": SCHICHT_DICHTE}}


## LÖSSTEXTUR (Abschluss R3; Bild-Jury R3, Lösswände: „gleichförmig orange
## und mit einem Punktmuster texturiert"; Licht und Farbe: „entsättigen und
## um eine Stufe abdunkeln"). Bis R3 trugen die Wände die Erde des
## Waldwegs: ein sattes Orange mit Kieseln (gemessen auf der Lichtseite bei
## s 60 rgb 99/35/2 – fast kein Blau, ein Ton auf der Erde konnte es nicht
## entsättigen, nur abdunkeln). Jetzt eine eigene Textur LOESS_KANTE²:
## fahles Gelbgrau zwischen LOESS_DUNKEL und LOESS_HELL aus einem senkrecht
## um LOESS_STRECKUNG gestreckten Rauschen (Rillen und Sickerspuren, die
## Wand hinab) und einem feinen Fleckrauschen, ohne Kiesel. So hell wie die
## Erde des Waldwegs (deren Mittel gut 0,66/0,52/0,33), aber blasser: Eine
## erste Fassung mit 0,3–0,56 lag auf der Lichtseite bei Luma 14,5 statt
## 50,5 (s 60), mit Streckung 12 dazu wie Bretter. Im Bauspeicher; kalt gut
## 0,1 s in diesem Schritt (zusammen mit Sandstein und Moos).
## R4 (Bild-Jury R4, Licht und Farbe: „Weg und Lösswände um eine weitere
## Stufe entsättigen"): 0,84/0,78/0,66 und 0,55/0,5/0,41 statt 0,86/0,77/0,6
## und 0,56/0,48/0,36.
const LOESS_HELL := Color(0.84, 0.78, 0.66)
const LOESS_DUNKEL := Color(0.55, 0.5, 0.41)
const LOESS_KANTE := 256
const LOESS_STRECKUNG := 6


## SANDSTEINTEXTUR (R4; Bild-Jury R4, Tobel D: „Der Sandstein trägt ein
## Puzzlemuster aus dünnen Umrisslinien"; Vorschlag: „Die Umrisslinien im
## Sandstein weich ausblenden"): Der Fels der Kanten ist die Textur von
## `Materialbibliothek.wurzelfels` – Bänder mit Zellrissen, aus denen im
## warmen Ton des Sandsteins (SANDSTEIN) dünne, geschlossene dunkle Linien
## wurden. Hier dieselbe Textur, zu SANDSTEIN_WEICH mit einer weichen
## Fassung ihrer selbst gemischt (auf ein Viertel verkleinert und bilinear
## zurück): Die Bänder und Flecken bleiben, die Risslinien verlaufen. Gilt
## für allen Fels des Saums (Sandstein, Wehrwände, Ufer). Im Bauspeicher.
const SANDSTEIN_WEICH := 0.65


static func sandstein_textur() -> Texture2D:
	return Bauspeicher.holen("l05_sandstein_textur", _sandstein_bauen) as Texture2D


static func _sandstein_bauen() -> Texture2D:
	var quelle := Materialbibliothek.wurzelfels().albedo_texture
	var bild := quelle.get_image() if quelle != null else null
	if bild == null:
		return quelle
	bild = bild.duplicate() as Image
	if bild.is_compressed():
		bild.decompress()
	bild.clear_mipmaps()
	bild.convert(Image.FORMAT_RGB8)
	var weich := bild.duplicate() as Image
	var b := bild.get_width()
	var h := bild.get_height()
	weich.resize(maxi(b / 4, 4), maxi(h / 4, 4), Image.INTERPOLATE_BILINEAR)
	weich.resize(b, h, Image.INTERPOLATE_BILINEAR)
	var a := bild.get_data()
	var c := weich.get_data()
	for i in a.size():
		a[i] = roundi(lerpf(float(a[i]), float(c[i]), SANDSTEIN_WEICH))
	var neu := Image.create_from_data(b, h, false, Image.FORMAT_RGB8, a)
	neu.generate_mipmaps()
	return ImageTexture.create_from_image(neu)


static func loess_textur() -> Texture2D:
	return Bauspeicher.holen("l05_loess_textur", _loess_bauen) as Texture2D


static func _loess_bauen() -> Texture2D:
	var k := LOESS_KANTE
	var streifen := FastNoiseLite.new()
	streifen.seed = 5181
	streifen.frequency = 0.07
	streifen.fractal_octaves = 3
	var lang := streifen.get_seamless_image(k, maxi(8, k / LOESS_STRECKUNG), false, false, 0.1)
	lang.resize(k, k, Image.INTERPOLATE_BILINEAR)
	var flecken := FastNoiseLite.new()
	flecken.seed = 5182
	flecken.frequency = 0.035
	flecken.fractal_octaves = 4
	var fein := flecken.get_seamless_image(k, k, false, false, 0.1)
	var a := lang.get_data()
	var b := fein.get_data()
	var schritt_a := a.size() / (k * k)
	var schritt_b := b.size() / (k * k)
	var daten := PackedByteArray()
	daten.resize(k * k * 3)
	for i in k * k:
		var v := 0.45 * float(a[i * schritt_a]) / 255.0 + 0.55 * float(b[i * schritt_b]) / 255.0
		v = smoothstep(0.2, 0.8, v)
		var c := LOESS_DUNKEL.lerp(LOESS_HELL, v)
		daten[i * 3] = roundi(c.r * 255.0)
		daten[i * 3 + 1] = roundi(c.g * 255.0)
		daten[i * 3 + 2] = roundi(c.b * 255.0)
	var bild := Image.create_from_data(k, k, false, Image.FORMAT_RGB8, daten)
	bild.generate_mipmaps()
	return ImageTexture.create_from_image(bild)


# ================================================================ Formen

## Die Form eines Zuges „auf" an der Stelle `s` – dieselbe für Saum und
## Gelände:
##   krone   Welt-Y der Krone (geglättete Decke + h + Welle)
##   deck    Welt-Y der Decke (in einer Lücke zwischen ihren Lippen)
##   hoch    Krone über der Decke, mindestens 6 cm (in der Übergabe weniger)
##   lauf    wie weit die Wandkrone hinter dem Fuß liegt (m, waagerecht)
##   narbe   Überhang der Grasnarbe zum Weg (m)
##   band    Maßstab des Kronenbands (1; in der Übergabe bis UEBERGABE_BAND):
##           die Platte reicht `weit` = KRONE_WEIT · band hinter die Wand-
##           krone, das Gelände (`L05Gelaende`) staucht seine Krone ebenso
##   ueb     Anteil dieses Zuges in der Übergabe (`uebergabe`)
##   winkel, fels  aus dem Zug
## In der Übergabe an den nächsten Zug sinkt die Krone bis UEBERGABE_SINKT
## unter die Decke, und Platte und Kronenband schrumpfen: Am Ende des Zuges
## liegt sein Querschnitt (und damit der Deckel des Gitters) unter Schulter,
## Ufer und Gelände.
static func form_auf(level: Level05, zug: Dictionary, s: float) -> Dictionary:
	var w := Level05.zug_werte(zug, s)
	var deck := level.weg.boden_bei(s)
	var seite: float = zug["seite"]
	var krone := level.decke_glatt(s) + w[0] \
			+ KRONE_WELLE * Kanten.welle(s * KRONE_WELLE_DICHTE, 61.0 + seite) \
			+ KRONE_ZACKE * Kanten.welle(s * KRONE_ZACKE_DICHTE, 83.0 + seite) \
			* smoothstep(0.6, 2.0, w[0])
	var ueb := uebergabe(zug, s)
	var hoch := maxf(krone - deck, 0.06)
	var band := 1.0
	if ueb < 1.0:
		krone = lerpf(deck + UEBERGABE_SINKT, krone, ueb)
		hoch = maxf(krone - deck, lerpf(UEBERGABE_SINKT, 0.06, ueb))
		band = lerpf(UEBERGABE_BAND, 1.0, ueb)
	var f := clampf(hoch, 0.1, 1.0)
	var k := 1.0 / tan(deg_to_rad(clampf(w[1], 25.0, 88.0)))
	return {"krone": deck + hoch, "deck": deck, "hoch": hoch, "f": f, "k": k,
			"lauf": k * (hoch - 0.55 * f), "narbe": w[2] * smoothstep(0.15, 1.2, hoch)
					* (1.0 + NARBE_WECHSEL * Kanten.welle(s * 0.7, 97.0 + seite)),
			"band": band, "weit": KRONE_WEIT * band, "ueb": ueb,
			"winkel": w[1], "fels": w[3]}


## ÜBERGABE: Wo auf derselben Seite der nächste Zug beginnt, bevor `zug`
## endet (Böschung links → Ufer links 179–182, Böschung rechts → Teichwand
## 277–279), gibt `zug` die Form über diese Strecke ab: 1 bis zum Anfang des
## nächsten, 0 an seinem Ende, dazwischen weich. Sonst 1.
## WARUM: Vorher galt in der Überlappung im Gelände hart der Zug, dessen Ende
## weiter weg war, und die Böschung lief mit voller Platte (2,8 m bei
## Krone + 6 cm) bis an ihr Ende. Hinter der Mitte lag das Feld schon im Bett
## des Ufers, und die Platte stand 1–1,9 m frei darüber, am Ende mit einem
## dunklen Deckel (CP3 bei 178, Messtor 280; Prüfung P3, Runde 2).
static func uebergabe(zug: Dictionary, s: float) -> float:
	var von := _uebergabe_von(zug)
	if is_nan(von):
		return 1.0
	return 1.0 - smoothstep(von, float(zug["bis"]), s)


## Wo die Übergabe von `zug` beginnt (der Anfang des nächsten Zuges seiner
## Seite), NAN ohne Übergabe.
static func _uebergabe_von(zug: Dictionary) -> float:
	var bis: float = zug["bis"]
	for z: Dictionary in Level05.ZUEGE:
		if float(z["seite"]) != float(zug["seite"]):
			continue
		# `zug` selbst fällt heraus: Sein Anfang liegt nicht hinter sich.
		var von: float = z["von"]
		if von > float(zug["von"]) and von < bis and float(z["bis"]) > bis:
			return von
	return NAN


## Die Form eines Zuges „ab" an `s`:
##   bett    Welt-Y des Grundes vor der Wand (geglättete Decke − h)
##   deck, tief (Decke über dem Bett, mindestens 5 cm), narbe, fels
##   fuss    wie weit der Fuß der Wand vor der Lippe liegt (m, waagerecht)
static func form_ab(level: Level05, zug: Dictionary, s: float) -> Dictionary:
	var w := Level05.zug_werte(zug, s)
	var deck := level.weg.boden_bei(s)
	var bett := level.decke_glatt(s) - w[0]
	var tief := maxf(deck - bett, 0.05)
	var k := 1.0 / tan(deg_to_rad(clampf(w[1], 25.0, 88.0)))
	return {"bett": deck - tief, "deck": deck, "tief": tief, "f": clampf(tief, 0.1, 1.0),
			"k": k, "fuss": _ab_o(tief, k, w[3]) + 0.1,
			"narbe": w[2] * smoothstep(0.15, 1.0, tief), "fels": w[3]}


## Versatz einer Wand „ab" in der Tiefe `d` unter der Decke: im Winkel des
## Zuges, am erdigen Ufer oben gerundet (die ersten 1,2 m flacher).
static func _ab_o(d: float, k: float, fels: float) -> float:
	return d * k + (1.0 - fels) * 0.35 * minf(d, 1.2)


# ================================================================ Profile

## Böschung hinauf (siehe Kopf), 18 Punkte von der Krone zur Decke. `o`
## zählt vom Fuß (der Linie) nach außen; die Narbe tritt zum Weg vor.
static func _profil_auf(i: int, probe: Dictionary, level: Level05,
		zug: Dictionary, lage: Dictionary) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var seite: float = zug["seite"]
	var m := form_auf(level, zug, s)
	var krone: float = m["krone"]
	var deck: float = m["deck"]
	var hoch: float = m["hoch"]
	var f: float = m["f"]
	var k: float = m["k"]
	var lauf: float = m["lauf"]
	var ov: float = m["narbe"]
	var fels: float = m["fels"]
	var erde := lerpf(1.0, 0.2, fels)
	var schicht := lerpf(0.04, 0.16, fels)
	var p := GelaendeSaum.Profil.new()
	# --- Krone und Grasnarbe (0–5): Die Narbe tritt `ov` vor die Wandkrone.
	# Die Platte endet `weit` hinter der Wandkrone, nie über dem gezeichneten
	# Gelände: sonst stünde ihre Kante frei (in der Übergabe liegt das Feld
	# schon im Bett des nächsten Zuges, siehe `uebergabe`; an Ecken der Linie
	# zeigt der Querschnitt schräg, siehe `_platte_lage`).
	var weit: float = m["weit"]
	if not lage.has("y"):
		_platte_lage(level, zug, lage)
	var ende_y := krone + KRONE_STEIGT
	var stellen: PackedFloat32Array = lage["s"]
	if i < stellen.size() and absf(stellen[i] - s) < 0.001:
		ende_y = minf(ende_y, (lage["y"] as PackedFloat32Array)[i])
	else:
		# Nicht die Querschnitte, für die `lage` gerechnet ist (eine andere
		# Abtastung): quer zum Weg prüfen.
		push_warning("L05Saum: Plattenende an s %.2f quer zum Weg geprüft" % s)
		var ende := LevelWerkzeuge.punkt_frei(level.verlauf, s,
				float(probe["q"]) + seite * (lauf + weit))
		var feld := level.gelaende.hoehe(ende.x, ende.z)
		if not is_nan(feld):
			ende_y = minf(ende_y, feld - PLATTE_UNTER)
	var band := kronenband(s)
	p.punkt(lauf + weit, ende_y, Kanten.farbe(0.78 * band, 0.0, 0.1, 1.0), PLATTE_GLATT)
	p.punkt(lauf - ov * 0.4, krone - 0.006 * f, Kanten.farbe(0.78 * band, 0.0, 0.2, 1.0))
	p.punkt(lauf - ov * 0.8, krone - 0.035 * f, Kanten.farbe(0.72 * band, 0.1, 0.3, 0.95))
	p.punkt(lauf - ov, krone - 0.12 * f, Kanten.farbe(0.5, 0.6, 0.3, 0.45))
	p.punkt(lauf - ov + 0.06 * f, krone - 0.25 * f, Kanten.farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(lauf - ov + 0.32 * f, krone - 0.33 * f, Kanten.farbe(0.18, 1.0, 0.0, 0.0))
	# --- Wandkrone unter der Narbe, ausgewaschen (6)
	p.punkt(lauf, krone - 0.5 * f, Kanten.farbe(0.24, erde, 0.05, 0.0), 0.8, 0.04, 2.0)
	# --- Wand (7–12): im Winkel des Zuges, Rinnen nur nach außen, im Fels
	# mit Schichtstufen; oben im Schatten der Narbe dunkler.
	var z_a := hoch - 0.8 * f
	var z_b := minf(0.3 * f, 0.5 * z_a)
	for j in 6:
		var t := float(j) / 5.0
		var z := lerpf(z_a, z_b, t)
		p.punkt(k * z, deck + z,
				Kanten.farbe(lerpf(0.5, 0.82, t), erde, lerpf(0.05, 0.3, t * t), 0.0),
				lerpf(1.6, 0.8, t), lerpf(0.14, 0.08, t) * f, 2.0, schicht * f)
	_loesswand(p, s, seite, hoch, fels, z_a, deck)
	# --- Fuß und Schulter (13–15), dann unter die Decke (16–17, absolut)
	p.punkt(k * z_b * 0.4 + 0.03, deck + 0.4 * z_b, Kanten.farbe(0.6, 0.7, 0.35, 0.2))
	p.punkt(-0.05, deck + 0.015 * f, Kanten.farbe(0.7, 0.35, 0.25, 0.6))
	# Unter der Decke Erde (STUFE_UNTER_DECKE): sichtbar nur an den Stufen.
	var ud := STUFE_UNTER_DECKE
	p.punkt(-0.3, deck - 0.012, Kanten.farbe(0.78, ud.y, 0.1, 1.0))
	var rand := level.weg.wegrand(s)
	p.punkt(seite * rand, deck - 0.015, Kanten.farbe(ud.x, ud.y, 0.05, 1.0), 0.0, 0.0, 1.0, 0.0,
			true)
	p.punkt(seite * (rand - 0.35), deck - 0.03, Kanten.farbe(ud.x, ud.y, 0.05, 1.0), 0.0, 0.0,
			1.0, 0.0, true)
	var l := _luecke(s)
	if not l.is_empty():
		_auf_in_luecke(p, l, s, deck)
	elif _an_stufe(lage, s):
		# An einer Stufe der Decke (siehe STUFE_ERDE): Fuß, Schulter und was
		# unter der Decke lag, als Erde im Schatten der Wand.
		for j in range(13, p.anzahl()):
			p.farbe[j] = STUFE_ERDE
	elif _vor_lippe(s):
		# Knapp vor einer Lippe: Fuß und Schulter dunkel (LIPPE_SCHULTER).
		for j in range(11, 15):
			var c := p.farbe[j]
			c.r *= LIPPE_SCHULTER
			p.farbe[j] = c
	return p


## Die Lösswand an `s` (siehe LÖSSWAND bei LOESS) auf die Wandpunkte 7–12:
## Rillen (Versatz nach außen und dunkler) und Bänder (dunkler, weniger
## Erde). `z_a` Höhe des obersten Wandpunkts über der Decke `deck`.
static func _loesswand(p: GelaendeSaum.Profil, s: float, seite: float, hoch: float,
		fels: float, z_a: float, deck: float) -> void:
	var stark := smoothstep(RILLE_HOCH, RILLE_HOCH + 1.0, hoch) * (1.0 - smoothstep(0.1, 0.3, fels))
	if stark <= 0.0:
		return
	var phase := s * TAU / RILLE_ABSTAND + 2.2 * Kanten.welle(s * 0.06, 71.0 + seite)
	var rille := smoothstep(0.55, 0.95, 0.5 + 0.5 * sin(phase)) * stark
	var band_a := BAND_HOEHEN.x + BAND_WANDERN * Kanten.welle(s * 0.03, 73.0 + seite)
	var band_b := BAND_HOEHEN.y + BAND_WANDERN * Kanten.welle(s * 0.025, 79.0 + seite)
	for j in range(7, 13):
		var z := p.y[j] - deck
		var anteil := clampf(z / maxf(z_a, 0.01), 0.0, 1.0)
		var band := maxf(1.0 - absf(anteil - band_a) / 0.14, 0.0) \
				+ maxf(1.0 - absf(anteil - band_b) / 0.1, 0.0)
		band = minf(band, 1.0) * stark
		var c := p.farbe[j]
		c.r *= (1.0 - RILLE_DUNKEL * rille) * (1.0 - BAND_DUNKEL * band)
		c.g *= 1.0 - BAND_FELS * band
		p.farbe[j] = c
		# Die Rinne tritt in die Wand zurück, oben und unten weniger.
		var mitte := 1.0 - absf(anteil - 0.5) * 1.2
		p.o[j] += RILLE_TIEF * rille * maxf(mitte, 0.2)


## WURZELVORHÄNGE (Abschluss R3; Bild-Jury R3, Lösswände: „Schichtung und
## Wurzelvorhänge aus §5 B sind nicht zu sehen"): Unter der Narbe der
## Lösswände (VORHANG_STRECKE, ohne Fels, ab gut 1,2 m Wand) hängen Büschel
## aus Wurzelkarten die Wand hinab, VORHANG_LANG m lang – in Gruppen
## (Rauschen über VORHANG_GRUPPE m), dazwischen nackte Wand. Die Karten der
## Narbe (0,3 bis 0,9 m, `Kanten._karten_an`) lasen sich aus 15 m als
## Fransen, nicht als Vorhang. Jede Karte liegt auf der Wand: von der
## Wandkrone (Punkt 6) zum Punkt 10 hinab, 5 cm davor, dazu eine zweite
## (seit R4 ebenfalls flach, siehe unten). Gebaut
## aus den Querschnitten des Saums (`saum_flaechen`, auch aus dem
## Bauspeicher), je 30 m ein Netz mit Sichtweite VORHANG_SICHT; eigene Saat.
## R4 (Bild-Jury R4, Lösswände: „reinschwarze, 1 px breite Haarstriche …
## wie Tuschekratzer oder Aliasing"; s 60 links 455 fast schwarze Pixel mit
## hellen Nachbarn): Die zweite Karte stand schräg aus der Wand – aus der
## Kamera fast auf der Kante, ihre Stränge zu Strichen gestaucht und von der
## Seite beleuchtet –, und die Stränge des geteilten Atlas sind 1,6–3,2 von
## 64 Texeln breit: auf einer Karte von 0,35–0,6 m 1–3 cm, aus 10 m Abstand
## ein Bildpunkt (bei 70° Bildwinkel gut 1 cm je Bildpunkt). Jetzt liegen
## beide Karten flach auf der Wand (die zweite VORHANG_ZWEITE davor, kürzer
## und schmaler), mit einem eigenen Atlas (`_vorhang_stoff`): VORHANG_STRAENGE
## Stränge, VORHANG_DICKE Texel breit (3–7 cm, aus 10 m 3–7 Bildpunkte), zur
## Mitte heller (rund), Normale wie die Wand – beleuchtet wie sie, die
## Vorderseite zur Wand hinaus. SCHWARZ waren die Stränge aber vor allem
## wegen ihres Tons: Die Scheitelfarbe wirkt im Bild weit dunkler als ihr
## Wert (gemessen s 60, unbeleuchtet, ohne Atlas: Scheitelfarbe 0,27/0,19/
## 0,11 → Bildpunkte 39/16/0; der Ton bis R4 war 0,5/0,38/0,27 mal dem
## geteilten Atlas mit 0,55–0,95). VORHANG_TON ist darum ein heller Wert
## (0,62/0,45/0,3), der Atlas 0,7–1,0: im Bild warm-braun und HELLER als
## die beschattete Wand dahinter (gemessen s 60, mit und ohne Vorhänge:
## Stränge im Mittel rgb 85/42/22, Luma 53 gegen 31 der Wand an denselben
## Bildpunkten) – keine dunklen Striche mehr.
const VORHANG_STRECKE := Vector2(31.0, 182.0)
const VORHANG_LANG := Vector2(0.8, 2.1)
const VORHANG_GRUPPE := 7.0
const VORHANG_DICHTE := 0.9
const VORHANG_TON := Color(0.62, 0.45, 0.3)
const VORHANG_SICHT := 60.0
const VORHANG_STUECK := 30.0
const VORHANG_ZWEITE := 0.06
const VORHANG_STRAENGE := 5
const VORHANG_DICKE := Vector2(4.0, 7.0)
const VORHANG_ATLAS := Vector2i(64, 128)


static func _wurzelvorhaenge(level: Level05) -> void:
	var rng := PropWerkzeug.zufall(5171)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = 5172
	rauschen.frequency = 1.0 / VORHANG_GRUPPE
	var stuecke := {}
	for zug: Dictionary in Level05.ZUEGE:
		if String(zug["art"]) != "auf":
			continue
		var stand: Dictionary = level.saum_flaechen.get(String(zug["name"]), {})
		var flaeche: Dictionary = stand.get("flaeche", {})
		if flaeche.is_empty():
			continue
		var seite: float = zug["seite"]
		var strecken: PackedFloat32Array = flaeche["s"]
		var reihen: Array = flaeche["reihen"]
		for i in range(1, strecken.size() - 1):
			var s := strecken[i]
			if s < VORHANG_STRECKE.x or s > VORHANG_STRECKE.y or level.weg.ist_luecke(s):
				continue
			var m := form_auf(level, zug, s)
			var w := clampf(0.45 + 1.1 * rauschen.get_noise_1d(s + 57.0 * seite), 0.0, 1.0) \
					* VORHANG_DICHTE * smoothstep(1.2, 2.2, float(m["hoch"])) \
					* (1.0 - smoothstep(0.1, 0.3, float(m["fels"])))
			var reihe: PackedVector3Array = reihen[i]
			var krone := reihe[6]
			var unten := reihe[10]
			var aussen := reihe[3] - reihe[0]
			aussen.y = 0.0
			var laengs: Vector3 = (reihen[i + 1] as PackedVector3Array)[6] \
					- (reihen[i - 1] as PackedVector3Array)[6]
			laengs.y = 0.0
			if aussen.length_squared() < 0.0001 or laengs.length_squared() < 0.0001:
				continue
			aussen = aussen.normalized()
			laengs = laengs.normalized()
			var runter := (unten - krone).normalized()
			var wand := krone.distance_to(reihe[12])
			for k in 2:
				var wurf := rng.randf()
				var lang := minf(rng.randf_range(VORHANG_LANG.x, VORHANG_LANG.y), wand * 0.85)
				var breit := rng.randf_range(0.35, 0.6)
				var versatz := rng.randf_range(-0.3, 0.3)
				var ton := VORHANG_TON * rng.randf_range(0.75, 1.1)
				if wurf > w:
					continue
				var ort := krone + aussen * 0.05 + laengs * versatz + Vector3.UP * 0.04
				var schluessel := floori(s / VORHANG_STUECK)
				if not stuecke.has(schluessel):
					var neu := SurfaceTool.new()
					neu.begin(Mesh.PRIMITIVE_TRIANGLES)
					stuecke[schluessel] = neu
				var st: SurfaceTool = stuecke[schluessel]
				_vorhang_karte(st, ort, runter + aussen * 0.03, laengs, aussen, lang, breit,
						ton, false)
				_vorhang_karte(st, ort + aussen * VORHANG_ZWEITE + laengs * breit * 0.2,
						runter + aussen * 0.03, laengs, aussen, lang * 0.7, breit * 0.7,
						ton * 0.85, true)
	var wurzel := Node3D.new()
	wurzel.name = "Wurzelvorhänge"
	level.geometrie.add_child(wurzel)
	for schluessel: int in stuecke:
		var mi := MeshInstance3D.new()
		mi.name = "Vorhang %d" % schluessel
		mi.mesh = (stuecke[schluessel] as SurfaceTool).commit()
		mi.material_override = _vorhang_stoff()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = VORHANG_SICHT
		mi.visibility_range_end_margin = 5.0
		wurzel.add_child(mi)


## Eine Karte des Wurzelvorhangs (siehe R4 bei VORHANG_STRECKE): oben an
## `oben`, hängt entlang `runter` um `laenge`, `breite` entlang `quer`; die
## Normale ist `aussen` (die Wand), beidseitig. `gespiegelt` nimmt den Atlas
## von rechts nach links (die zweite Karte zeigt so andere Stränge).
static func _vorhang_karte(st: SurfaceTool, oben: Vector3, runter: Vector3, quer: Vector3,
		aussen: Vector3, laenge: float, breite: float, ton: Color, gespiegelt: bool) -> void:
	var r := runter.normalized()
	var q := quer.normalized()
	var a := oben - q * breite * 0.5
	var b := oben + q * breite * 0.5
	var c := b + r * laenge
	var d := a + r * laenge
	var u0 := 1.0 if gespiegelt else 0.0
	var u1 := 1.0 - u0
	var ecken: Array[Vector3] = [a, b, c, a, c, d]
	var uvs: Array[Vector2] = [Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0),
			Vector2(u0, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)]
	var unten := ton.darkened(0.3)
	var farben: Array[Color] = [ton, ton, unten, ton, unten, unten]
	# Die Vorderseite zeigt nach `aussen` (Godot: im Uhrzeigersinn, wie
	# `GelaendeSaum.dreieck`). Sieht die Kamera die Rückseite, kehrt der
	# beidseitige Stoff die Normale um – die Stränge lagen dann unbeleuchtet,
	# schwarz, auf der hellen Wand.
	var reihe: Array[int] = [0, 1, 2, 3, 4, 5]
	if (b - a).cross(c - a).dot(aussen) > 0.0:
		reihe = [0, 2, 1, 3, 5, 4]
	for k in reihe:
		st.set_normal(aussen)
		st.set_color(farben[k])
		st.set_uv(uvs[k])
		st.add_vertex(ecken[k])


## Stoff der Wurzelvorhänge: eigener Atlas (VORHANG_ATLAS Texel, weiß getönt,
## die Farbe aus den Scheitelfarben), Alpha-Scissor, beidseitig, matt.
## Gebaut beim ersten Aufruf (gut 8000 Texel, eigene Saat).
static var _vorhang_stoff_fertig: StandardMaterial3D = null


static func _vorhang_stoff() -> StandardMaterial3D:
	if _vorhang_stoff_fertig != null:
		return _vorhang_stoff_fertig
	var bild := Image.create(VORHANG_ATLAS.x, VORHANG_ATLAS.y, false, Image.FORMAT_RGBA8)
	# Der durchsichtige Grund in der Farbe der Stränge, nicht schwarz: Die
	# Mipmaps mischen ihn in die Ränder, und mit Schwarz trug jeder Strang
	# aus der Ferne einen dunklen Saum aus einzelnen Punkten.
	bild.fill(Color(0.85, 0.85, 0.85, 0.0))
	var rng := PropWerkzeug.zufall(5173)
	var breite := float(VORHANG_ATLAS.x)
	for k in VORHANG_STRAENGE:
		var x := breite * (float(k) + rng.randf_range(0.3, 0.7)) / float(VORHANG_STRAENGE)
		var dicke := rng.randf_range(VORHANG_DICKE.x, VORHANG_DICKE.y)
		var lang := rng.randf_range(0.6, 1.0) * float(VORHANG_ATLAS.y)
		_vorhang_strang(bild, x, 0.0, rng.randf_range(-0.12, 0.12), dicke, lang, rng, 0)
	bild.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(bild)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_vorhang_stoff_fertig = m
	return m


## Ein Strang des Vorhang-Atlas von (x, y) nach unten: dünner werdend,
## leicht pendelnd, zur Mitte heller; verzweigt sich höchstens zweimal.
static func _vorhang_strang(bild: Image, x: float, y: float, drift: float, dicke: float,
		laenge: float, rng: RandomNumberGenerator, tiefe: int) -> void:
	var schritte := int(laenge)
	var phase := rng.randf() * TAU
	for k in schritte:
		var t := float(k) / float(maxi(schritte, 1))
		var d := maxf(dicke * lerpf(1.0, 0.35, t), 1.6)
		var cx := x + sin(float(k) * 0.07 + phase) * 1.8
		var cy := int(y) + k
		if cy >= bild.get_height():
			break
		for dx in range(-ceili(d), ceili(d) + 1):
			var px := int(cx) + dx
			if px < 0 or px >= bild.get_width():
				continue
			var rand := absf(float(px) + 0.5 - cx) / (d * 0.5)
			if rand > 1.0:
				continue
			var hell := lerpf(1.0, 0.7, rand * rand) * lerpf(1.0, 0.85, t)
			bild.set_pixel(px, cy, Color(hell, hell, hell, 1.0))
		x += drift
		if tiefe < 2 and t > 0.25 and t < 0.7 and rng.randf() < 0.012:
			_vorhang_strang(bild, cx, float(cy), -drift + rng.randf_range(-0.25, 0.25),
					d * 0.65, (1.0 - t) * laenge * 0.7, rng, tiefe + 1)
			tiefe += 1


## Liegt der Querschnitt an `s` an einer Stufe der Decke (STUFE_SPIEL davor
## oder dahinter; `lage["stufen"]` aus `bauschritte`)?
static func _an_stufe(lage: Dictionary, s: float) -> bool:
	for naht: float in lage.get("stufen", PackedFloat32Array()) as PackedFloat32Array:
		if absf(absf(s - naht) - STUFE_SPIEL) < 0.004:
			return true
	return false


## Liegt `s` knapp vor einer Lippe (höchstens 0,01 m, außerhalb der Lücke)?
static func _vor_lippe(s: float) -> bool:
	for l: Dictionary in Level05.LUECKEN:
		var von: float = l["von"]
		var bis: float = l["bis"]
		if (s <= von + LUECKE_SPIEL and s > von - 0.01) or (s >= bis - LUECKE_SPIEL and s < bis + 0.01):
			return true
	return false


## PLATTENENDEN eines Zuges „auf", für alle Querschnitte zugleich (beim
## ersten Aufruf von `_profil_auf`; legt in `lage` "s" und "y" ab): je
## Querschnitt das Welt-Y von Punkt 0. Das Ende steht dort, wo
## `GelaendeSaum.querschnitte` es hinsetzt – auf der mit PLATTE_GLATT
## geglätteten Linie, entlang IHRER Normale –, und es liegt PLATTE_UNTER
## unter dem gezeichneten Gelände: an diesem Ort und ein Viertel und halb
## zum Ende der Nachbarn hin. Zwischen zwei Enden läuft die Kante gerade;
## mit diesen Proben liegt sie auch dort unter dem Feld.
## WARUM: Bis Runde 3 prüfte der Saum quer zum Weg (`punkt_frei` an
## q + lauf + weit). An einer Ecke der Leitlinie zeigt der Querschnitt aber
## anders: Am Ausgang der Nische G3 (die Linie springt von 263,0 auf 263,5
## um 1,2 m nach innen) fächern die Querschnitte bis 36° nach +s auf. Sie
## trugen die Krone von 263,5 (9,38) über s 264–267, wo das Feld schon auf
## 8,9 liegt; die Prüfung quer zum Weg traf das höhere Feld daneben, und die
## Platte stand bis 0,5 m frei – ein Grasbrett im Messtor 280 und an CP5
## (Prüfung P3, Runde 3).
static func _platte_lage(level: Level05, zug: Dictionary, lage: Dictionary) -> void:
	var seite: float = zug["seite"]
	var proben := GelaendeSaum.linie(level.weg.verlauf, lage["linie"], SCHRITT, lage["feste"])
	# Dieselbe Mischung zweier Fassungen wie `GelaendeSaum.querschnitte` für
	# einen Punkt mit `glatt` = PLATTE_GLATT.
	var fenster := GelaendeSaum.FENSTER
	var k := 0
	while k < fenster.size() - 2 and fenster[k + 1] < PLATTE_GLATT:
		k += 1
	var t := clampf(inverse_lerp(fenster[k], fenster[k + 1], PLATTE_GLATT), 0.0, 1.0)
	var a := GelaendeSaum.glaetten(proben, fenster[k], seite)
	var b := GelaendeSaum.glaetten(proben, fenster[k + 1], seite)
	var pa: PackedVector3Array = a["p"]
	var pb: PackedVector3Array = b["p"]
	var na: PackedVector3Array = a["n"]
	var nb: PackedVector3Array = b["n"]
	var n := proben.size()
	var stellen := PackedFloat32Array()
	var enden := PackedVector2Array()
	var kronen := PackedFloat32Array()
	for i in n:
		var s: float = proben[i]["s"]
		var m := form_auf(level, zug, s)
		var e := pa[i].lerp(pb[i], t) \
				+ na[i].lerp(nb[i], t).normalized() * (float(m["lauf"]) + float(m["weit"]))
		stellen.append(s)
		enden.append(Vector2(e.x, e.z))
		kronen.append(float(m["krone"]) + KRONE_STEIGT)
	var hoehen := PackedFloat32Array()
	for i in n:
		var y := kronen[i]
		var orte := PackedVector2Array([enden[i]])
		for j: int in [i - 1, i + 1]:
			if j >= 0 and j < n:
				orte.append_array([enden[i].lerp(enden[j], 0.25), enden[i].lerp(enden[j], 0.5)])
		for o: Vector2 in orte:
			var feld := level.gelaende.hoehe(o.x, o.y)
			if not is_nan(feld):
				y = minf(y, feld - PLATTE_UNTER)
		hoehen.append(y)
	lage["s"] = stellen
	lage["y"] = hoehen
## LUECKE_SPIEL hinter der Lippe. WARUM: Die Proben kommen als Vector2 (32
## Bit) an; die Lippe 136,3 etwa als 136,300003, also schon IN der Lücke. Der
## Querschnitt an der Lippe lag dann auf dem Grund, und die Schulter tauchte
## zwischen ihm und dem Querschnitt davor 0,7 m vor der Stirn ab: ein Schlitz
## von 0,25 × 0,8 m hinter der Narbe der Stirn (L2, L3; P3-Prüfung).
static func _luecke(s: float) -> Dictionary:
	var l := Level05.luecke_bei(s)
	if l.is_empty() or s <= float(l["von"]) + LUECKE_SPIEL or s >= float(l["bis"]) - LUECKE_SPIEL:
		return {}
	return l


## In einer Lücke `l`: Fuß, Schulter und was unter der Decke lag, auf den
## Grund der Lücke – die Wand der Seite läuft bis dorthin hinab, dunkel.
## R3 (Bild-Jury R3, Mangel „Lücken": „Links und rechts schließen glatte,
## plattenförmige Stirnwände ab, die wie Kästen wirken"): Die Fläche von
## der Wand (Punkt 11, knapp über der Decke) hinab auf den Grund lief von
## der Helligkeit der Wand (Verdeckung 0,76) linear ins Dunkle – im Bild
## zwei helle Platten links und rechts des Spalts. Jetzt beginnt sie mit
## LUECKE_WAND_DUNKEL: Die Wand der Seite verschwindet mit der Stirn im
## Dunkel des Spalts, nur ihr oberer Teil über der Decke bleibt hell.
## Abschluss R3: Die ersten Querschnitte hinter der Lippe sind die
## Lippenstufe (siehe LIPPE_STUFE): nur LIPPE_TIEF unter der Decke `deck`.
static func _auf_in_luecke(p: GelaendeSaum.Profil, l: Dictionary, s: float,
		deck: float) -> void:
	var grund: float = l["grund_y"]
	var stufe := minf(s - float(l["von"]), float(l["bis"]) - s) < (LIPPE_STUFE.x + LIPPE_STUFE.y) * 0.5
	var c := p.farbe[11]
	c.r = minf(c.r, LUECKE_WAND_DUNKEL)
	p.farbe[11] = c
	for j in range(12, p.anzahl()):
		if stufe:
			p.y[j] = minf(p.y[j], deck - LIPPE_TIEF - (0.0 if j < 15 else 0.05))
			p.farbe[j] = Kanten.farbe(LIPPE_DUNKEL, 0.9, 0.15, 0.0)
		else:
			var tiefe := 0.1 if j == 13 else -0.03
			p.y[j] = grund + (0.25 if j == 12 else tiefe)
			p.farbe[j] = Kanten.farbe(LUECKE_GRUND_DUNKEL, 0.9, 0.2, 0.0)
		p.rauschen[j] = 0.0
		p.schicht[j] = 0.0


## Ufer oder Wehrwand hinab (siehe Kopf), 16 Punkte von der Decke zum Bett.
## `o` zählt von der Lippe (der Linie) nach außen.
static func _profil_ab(_i: int, probe: Dictionary, level: Level05,
		zug: Dictionary) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var seite: float = zug["seite"]
	var m := form_ab(level, zug, s)
	var deck: float = m["deck"]
	var bett: float = m["bett"]
	var tief: float = m["tief"]
	var f: float = m["f"]
	var k: float = m["k"]
	var ov: float = m["narbe"]
	var fels: float = m["fels"]
	var erde := lerpf(0.85, 0.15, fels)
	# R2 (Bild-Jury R2, Mangel 6: „bei s 262 ragt ein oranges Wandstück
	# senkrecht aus Gras und Wasser"): Wo der Hang das Ufer nicht mehr
	# deckt (sein Tobel klingt 258–268 aus, `L05Gelaende`) und die Wand vor
	# dem Wehr steiler wird, steht sie offen über dem Bach – dort nass und
	# bemoost statt Löss (UFER_MOOS).
	var bemoost := smoothstep(UFER_MOOS.x, UFER_MOOS.y, s) \
			* (1.0 - smoothstep(UFER_MOOS.z, UFER_MOOS.w, s))
	erde *= 1.0 - 0.75 * bemoost
	# Am Ufer tritt die Narbe über eine ausgewaschene Kante, an der Mauer
	# kaum.
	var unter := lerpf(0.2, 0.02, fels) * f
	var p := GelaendeSaum.Profil.new()
	# --- Narbe (0–5) von unter der Decke über die Lippe
	var rand := level.weg.wegrand(s)
	p.punkt(seite * (rand - 0.35), deck - 0.03, Kanten.farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0,
			1.0, 0.0, true)
	p.punkt(ov * 0.4, deck - 0.006 * f, Kanten.farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, deck - 0.035 * f, Kanten.farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, deck - 0.12 * f, Kanten.farbe(0.5, 0.7, 0.3, 0.4))
	p.punkt(ov - 0.06 * f, deck - 0.25 * f, Kanten.farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3 * f, deck - 0.33 * f, Kanten.farbe(0.2, 1.0, 0.0, 0.0))
	p.punkt(-unter, deck - 0.48 * f, Kanten.farbe(0.24, erde, 0.05, 0.0), 0.3, 0.05, -1.0)
	# --- Wand (7–12) bis über das Bett, nach unten nasser und moosiger
	var d_a := 0.65 * f
	var d_b := maxf(tief - 0.3 * f, d_a + 0.02)
	for j in 6:
		var t := float(j) / 5.0
		var d := lerpf(d_a, d_b, t)
		p.punkt(_ab_o(d, k, fels) - unter * (1.0 - t), deck - d,
				Kanten.farbe(lerpf(0.5, 0.64, t) * (1.0 - 0.25 * bemoost), erde,
						maxf(lerpf(0.15, 0.6, t), 0.85 * bemoost), 0.0),
				lerpf(0.8, 2.0, t), lerpf(0.1, 0.18, t) * f, 1.0, lerpf(0.02, 0.15, fels) * f)
	# --- Fuß und unter das Bett (13–15)
	var fuss: float = m["fuss"]
	p.punkt(fuss + 0.25 * f, bett + 0.04, Kanten.farbe(0.42, 0.6, 0.5, 0.0), 2.0, 0.1)
	p.punkt(fuss + 1.0 * f, bett - 0.35 * f, Kanten.farbe(0.38, 0.7, 0.4, 0.0), 2.5, 0.1)
	p.punkt(fuss + 2.2 * f, bett - 1.4 * f, Kanten.farbe(0.34, 0.8, 0.3, 0.0), 3.0, 0.1)
	var l := _luecke(s)
	if not l.is_empty():
		_ab_in_luecke(p, s, l, deck)
	elif _vor_lippe(s):
		# Knapp vor einer Lippe: Narbe und Wand dunkel (LIPPE_SCHULTER).
		for j in range(1, 10):
			var c := p.farbe[j]
			c.r *= LIPPE_SCHULTER
			p.farbe[j] = c
	return p


## In einer Lücke: alles über dem Grund der Lücke (nach außen 1,2 m je Meter
## ansteigend) auf diesen Grund – eine Rinne durch Ufer oder Wehr, zur
## Mitte der Lücke tiefer, an ihren Rändern bleibt mehr stehen.
## Abschluss R3 (eigene Prüfung s 186: am Ufer stand an L4 bildrechts noch
## eine helle Platte, wie an den Böschungen vor der LIPPENSTUFE): Die ersten
## Querschnitte hinter der Lippe senken nur bis LIPPE_TIEF unter die Decke
## `deck`, in LIPPE_DUNKEL; die Rinne dahinter ist dunkler (0,08 statt 0,2).
static func _ab_in_luecke(p: GelaendeSaum.Profil, s: float, l: Dictionary,
		deck: float) -> void:
	var grund: float = l["grund_y"]
	var mitte := (float(l["von"]) + float(l["bis"])) * 0.5
	var halb := (float(l["bis"]) - float(l["von"])) * 0.5
	var rand := clampf((absf(s - mitte) - halb + 0.9) / 0.9, 0.0, 1.0)
	var stufe := minf(s - float(l["von"]), float(l["bis"]) - s) < (LIPPE_STUFE.x + LIPPE_STUFE.y) * 0.5
	var o_max := -INF
	for j in p.anzahl():
		var o := maxf(p.o[j], 0.0) if p.absolut[j] == 0 else 0.0
		var grenze := grund + o * 1.2 + rand * 0.6
		if stufe:
			grenze = maxf(grenze, deck - LIPPE_TIEF)
		if p.y[j] <= grenze:
			continue
		p.y[j] = grenze
		if p.absolut[j] == 0:
			o_max = maxf(o_max, p.o[j])
			p.o[j] = o_max
		p.farbe[j] = Kanten.farbe(LIPPE_DUNKEL if stufe else 0.08, 0.8, 0.35, 0.0)
		p.rauschen[j] = 0.0
		p.schicht[j] = 0.0


## Stirn an der Lippe einer Lücke (`Kanten.profil_stirn` mit der Wegmaske):
## unter einer schmalen hellen Lippe schnell dunkel (STIRN_HELL …
## STIRN_DUNKEL, siehe dort), bis auf den Grund. Die Punkte 0–3 (Lippe und
## Narbe) behalten ihre Farbe; an der Landeseite (`nah`) hängt die Narbe
## weiter über den Spalt (STIRN_NAH).
static func _profil_stirn(_i: int, probe: Dictionary, level: Level05, kante: float,
		grund: float, halb: float, erdig: bool, nah: bool) -> GelaendeSaum.Profil:
	var p := Kanten.profil_stirn(probe, kante, grund, halb, erdig, 0.45, level.weg)
	for j in range(4, p.anzahl()):
		var c := p.farbe[j]
		var tief := maxf(kante - p.y[j] - STIRN_TIEFE.x, 0.0)
		c.r = STIRN_DUNKEL + (STIRN_HELL - STIRN_DUNKEL) * exp(-tief / STIRN_ABKLINGEN)
		p.farbe[j] = c
	# Ausbrüche der Lippe (siehe STIRN_AUSBRUCH): Narbe und Lippe sacken in
	# Buckeln von gut 1–2 m ab, die Wand darunter folgt bis 0,33 m.
	var bogen: float = probe["bogen"]
	var aus := STIRN_AUSBRUCH * smoothstep(0.1, 0.7, Kanten.welle(bogen * 0.55, 41.0)) \
			* (0.6 + 0.4 * Kanten.welle(bogen * 2.1, 43.0))
	for j in range(1, mini(6, p.anzahl())):
		p.y[j] -= maxf(aus, 0.0) * (1.0 if j < 4 else 0.5)
	if nah:
		for j in range(1, 4):
			p.o[j] = minf(p.o[j] + STIRN_NAH * float(j) / 3.0, STIRN_NAH_MAX)
	# Narbenzungen (R4, siehe STIRN_ZUNGE): Die Narbe hängt in Zungen über
	# den Spalt und sackt dort etwas ab.
	var zunge := smoothstep(STIRN_ZUNGE_AB, STIRN_ZUNGE_AB + 0.3,
			Kanten.welle(bogen * STIRN_ZUNGE_DICHTE, 47.0 + (5.0 if nah else 0.0)))
	if zunge > 0.0:
		for j in range(1, 4):
			p.o[j] += STIRN_ZUNGE * zunge * float(j) / 3.0
			p.y[j] -= 0.05 * zunge * float(j) / 3.0
	return p


## Setzstufe einer Treppe oder Kante des Suhlgrabens (12 bzw. 13 Punkte):
## Narbe nach der Wegmaske (auf der Spur Erde), angestrahlte Lösswand,
## darunter der Fuß in die untere Decke – am Graben eine Schlammsohle bis
## `weit` in den Graben (seine Mitte: dort trifft sie die Sohle der anderen
## Kante; die Decke zeichnet dort nichts, siehe `Level05.wegdecke_thema`).
static func _profil_stufe(_i: int, probe: Dictionary, level: Level05, oben: float,
		unten: float, weit: float, graben: bool) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var r := Kanten.rasen_anteil(level.weg, probe)
	var ov := lerpf(0.04 + 0.12 * (0.5 + 0.5 * Kanten.welle(bogen * 1.7, 23.0)),
			Kanten.ueberhang_quer(bogen, 14.0) * 0.7, r)
	var h := oben - unten
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, oben - 0.03, Kanten.farbe(0.78, (1.0 - r) * 0.8, 0.05, r))
	# R4 (Bild-Jury R4, Wurzeltreppen: „zwei schnurgerade Leisten über die
	# ganze Wegbreite"): Die Narbe auf der Spur und die Lippe unter ihr im
	# Schatten (Verdeckung 0,58/0,5/0,42/0,4 statt 0,68/0,6/0,55/0,5) – die
	# helle Kante tragen nur noch die Rücken der Wurzeln.
	p.punkt(ov * 0.4, oben - 0.006, Kanten.farbe(lerpf(0.58, 0.78, r), (1.0 - r) * 0.85,
			0.2 * r, r))
	p.punkt(ov * 0.8, oben - 0.035, Kanten.farbe(lerpf(0.5, 0.72, r), lerpf(0.9, 0.1, r),
			0.3 * r, 0.95 * r))
	p.punkt(ov, oben - lerpf(0.12, 0.1, r), Kanten.farbe(lerpf(0.42, 0.55, r),
			lerpf(0.95, 0.6, r), 0.3 * r, 0.45 * r))
	p.punkt(ov - 0.06, oben - 0.2, Kanten.farbe(0.4, 1.0, 0.1, 0.0))
	p.punkt(-0.2, oben - minf(0.32, h * 0.45), Kanten.farbe(0.55, 1.0, 0.05, 0.0), 0.0, 0.04,
			-1.0)
	# Die Setzstufe zeigt zur Sonne und zur Kamera: hell, kaum Moos. Abschluss
	# R3 (eigene Prüfung s 140: mit dem hellen Löss lag jede Stufe als
	# helles Band über die ganze Breite, wie ein Bordstein): etwas dunkler und
	# zum Fuß hin feucht und bemoost; R4 noch eine Stufe dunkler.
	p.punkt(-0.26, lerpf(oben, unten, 0.6), Kanten.farbe(0.58, 1.0, 0.15, 0.0), 0.0, 0.1, -1.0,
			0.05)
	p.punkt(-0.22, unten + 0.06, Kanten.farbe(0.45, 0.9, 0.45, 0.0), 0.0, 0.05, -1.0)
	if graben:
		# Schlammsohle der Suhle: nass, moosig, eben bis zur Mitte.
		p.punkt(-0.1, unten - 0.02, Kanten.farbe(0.55, 1.0, 0.5, 0.1))
		p.punkt(0.4, unten - 0.03, Kanten.farbe(0.5, 1.0, 0.55, 0.05))
		p.punkt(weit * 0.6, unten - 0.035, Kanten.farbe(0.48, 1.0, 0.6, 0.0))
		p.punkt(weit, unten - 0.04, Kanten.farbe(0.48, 1.0, 0.6, 0.0))
	else:
		p.punkt(-0.1, unten - 0.015, Kanten.farbe(0.66, 0.3, 0.3, 0.4))
		p.punkt(0.3, unten - 0.03, Kanten.farbe(0.78, 0.0, 0.1, 0.9))
		p.punkt(weit, unten - 0.035, Kanten.farbe(0.78, 0.0, 0.05, 1.0))
	return p


# ================================================================ Querlinien

## Die Linien quer über den Weg: je Lücke zwei Stirnen, je Stufe der Decke
## eine Setzstufe. Jede reicht von Fuß zu Fuß der Seiten (bzw. bis hinter die
## Lippe eines Ufers), damit die Ecken mit den Wänden der Seiten schließen.
static func _querlinien(level: Level05) -> Array:
	var weg := level.weg
	var linien: Array = []
	var nummer := 0
	for l: Dictionary in Level05.LUECKEN:
		var von: float = l["von"]
		var bis: float = l["bis"]
		var halb := (bis - von) * 0.5
		var grund: float = l["grund_y"]
		var erdig: bool = l["erdig"]
		for ende in 2:
			var s := von if ende == 0 else bis
			var vorwaerts := 1.0 if ende == 0 else -1.0
			var kante := weg.boden_bei(s - 0.01 * vorwaerts)
			linien.append(_querlinie(level, s, -vorwaerts,
					_profil_stirn.bind(level, kante, grund, halb, erdig, ende == 1), kante,
					5201 + nummer))
			nummer += 1
	# Stufen der Decke (Graben, Treppen; die Absätze haben Rampen).
	for st: Vector3 in _stufen(weg):
		var naht := st.x
		var h_a := st.y
		var h_b := st.z
		# Die untere Decke liegt vorn (+s) oder hinten; dorthin zeigt die Wand.
		var vorwaerts := 1.0 if h_a > h_b else -1.0
		var graben := naht > Level05.SUHLGRABEN.x - 0.01 and naht < Level05.SUHLGRABEN.y + 0.01
		var weit := (Level05.SUHLGRABEN.y - Level05.SUHLGRABEN.x) * 0.5 + 0.05 if graben else 0.6
		var linie := _querlinie(level, naht, -vorwaerts,
				_profil_stufe.bind(level, maxf(h_a, h_b), minf(h_a, h_b), weit, graben),
				maxf(h_a, h_b), 5301 + nummer)
		# Setzstufen ohne Karten (Bild-Jury R3, Treppen): Halme und Wurzeln
		# unter der Narbe standen dort als Zickzack-Fries über die ganze
		# Breite und an den Enden als tiefschwarze, gezackte Silhouetten
		# (unbeleuchtete Rückseiten) – die Kante tragen die Stufenwurzeln
		# (`L05Wegbauten.stufenwurzel`). An den Stirnen der Lücken bleiben sie.
		linie["karten"] = false
		linien.append(linie)
		nummer += 1
	return linien


## Die Stufen der Decke als Vector3(Naht, Höhe davor, Höhe dahinter): wo zwei
## Abschnitte bündig aneinanderstoßen, aber nicht gleich hoch.
static func _stufen(weg: Wegdaten) -> Array[Vector3]:
	var stufen: Array[Vector3] = []
	for i in range(1, weg.abschnitte.size()):
		var a: Dictionary = weg.abschnitte[i - 1]
		var b: Dictionary = weg.abschnitte[i]
		var naht: float = b["von"]
		if absf(float(a["bis"]) - naht) > 0.01:
			continue
		var h_a := LevelWerkzeuge.eintrag_hoehe(weg.verlauf, a, naht)
		var h_b := LevelWerkzeuge.eintrag_hoehe(weg.verlauf, b, naht)
		if absf(h_a - h_b) >= 0.05:
			stufen.append(Vector3(naht, h_a, h_b))
	return stufen


## Eine Querlinie an `s` von Seite zu Seite.
static func _querlinie(level: Level05, s: float, seite: float, profil: Callable, kante: float,
		saat: int) -> Dictionary:
	var links := _quer_ende(level, -1.0, s)
	var rechts := _quer_ende(level, 1.0, s)
	return {"seite": seite, "linie": PackedVector2Array([Vector2(s, links), Vector2(s, rechts)]),
			"profil": profil, "gruppe": "Stirnen und Stufen", "schritt": SCHRITT_QUER,
			"karten": true, "karten_maske": true, "saat": saat,
			"kante": func(_s: float) -> float: return kante}


## Wo eine Querlinie an der Seite `seite` endet: am Fuß einer Böschung knapp
## in der Wand, an einem Ufer hinter dessen Lippe.
static func _quer_ende(level: Level05, seite: float, s: float) -> float:
	var q := Level05.leitlinie_q(Level05.leitlinie_punkte(seite), s)
	for zug: Dictionary in level.zuege_bei(seite, s):
		if String(zug["art"]) == "ab":
			return q + seite * 0.55
	return q + seite * 0.1
