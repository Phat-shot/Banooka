extends Node3D
class_name L05Stimmung
## Level 05, Modul „Stimmung": Abendlicht nach der Strecke, Bewegung in der
## Luft und der Klang der Mühle (Entwurf L05 §8.1, §8.3, §8.4, §9.1, §9.5,
## Paket P8).
##
## BILDREGEL (§8.1): „Die Abendsonne steht hinter der Kamera. Vorn unten ist
## warm, hell und scharf: der Ausweg. Hinten oben ist kühl, dunstig und
## klein: die Herkunft. Dort leuchtet nur die Hauereiche golden." Das tragen
## die Szene (Level05.tscn) und dieser Regler gemeinsam:
## * SZENE: `himmel.gdshader` statt ProceduralSky – Zenit tiefblau, Horizont
##   rosé (der Gegendämmerungsgürtel: Die Kamera schaut von der Sonne weg),
##   Dunstband in der Nebelfarbe, Wolken mit warmem Licht (Menge 0,58),
##   ferne Hügel ab 4,3° (`huegel_hoehe` 0,075 ≥ 0,07, Jury JT10: Weltkante)
##   und eine Waldkante unter dem Horizont. Die Sonne ist LIGHT0 des
##   Himmels; ihr Schein (0,1) liegt hinter der Kamera und färbt nur, was
##   zur Seite sieht. Tiefennebel 16 → 240 m, Dichte 0,85, Kurve 1,4 in
##   einem kühlen Graublau (0,50/0,58/0,76) – aus ihm kommt der kühle Anteil
##   des Bildes und die Tiefe hangauf. Sättigung 1,0 (vorher 1,25), Kontrast
##   1,06, Glow 0,5 ab 1,0. `Bildrahmen` 0,32 in einem warmen Schwarz
##   (0,05/0,03/0,02). Dazu `horizont()` als grober Ring (`_horizont`).
## * SONNE: 26° hoch, rechts hinter der Kamera (Licht fällt nach
##   (0,52/−0,44/0,74): hangauf und nach q > 0), warm (1,0/0,80/0,56).
##   Sie steht fest in der Welt, die Laufrichtung dreht sich unter ihr: 35°
##   zur Laufrichtung bei s 0–30 und 180, 26–27° bei s 90–120, 40° bei
##   s 240–270 (gerechnet aus KURVE, Tangente über ±1 m; Spanne 26–41°).
##   Die 30–40° des Entwurfs (§8.3) hält keine feste Richtung über die
##   ganze Strecke (die Spanne ist 14° breit); auf allen Fotostellen liegt
##   der Weg im Licht.
##   Rechts (q < 0) liegen Wand und Bach im Schatten, links der Sonnenhang
##   im Licht. Schatten ORTHOGONAL (eine Stufe, 70 m) statt zwei Stufen:
##   Die tiefe Sonne hinter der Kamera zieht Schattenwerfer hinter der
##   Kamera in den Schattenpass, mit zwei Stufen wurde die Figur (62 500
##   Dreiecke) zweimal gezeichnet – gemessen 755k–785k Primitive (Grenze
##   §10: 750k), orthogonal 686k–707k bei gleichem Bild.
## * WEITERE LICHTER (nur Licht, nicht im Himmel: `sky_mode` 1):
##   Himmelslicht (0,52/0,62/0,95) von oben, kühles Kantenlicht aus ONO
##   (0,62/0,70/0,95) 0,18 – es hellt die Schattenseite der rechten Wand
##   kühl auf –, warmes Bodenlicht (0,86/0,66/0,42) 0,14 von unten.
## * ABWEICHUNGEN von den Startwerten des Entwurfs (§8.3: „Startwerte,
##   ungeprüft"), erzwungen von den Farbzielen des Kontaktbogens:
##   Mit Sonne 1,0, Himmelslicht 0,38, Umgebung × 0,42 und Belichtung 1,0
##   lag die Helligkeit der acht Fotostellen bei 51–74 (vorher L05 33–100)
##   und der Weg nicht mehr klar am hellsten. Jetzt Sonne 1,25,
##   Himmelslicht 0,45, Umgebung × 0,62, Belichtung 1,15 (Weiß 6).
##   Mit den Nebelfarben des Entwurfs (graugrün in A, lila-grau in B–E)
##   kam der kühle Anteil nur auf 3,6–9,8 % (Ziel ≥ 12 %): Ein Grau mit
##   wenig Sättigung zählt der Bogen nicht als kühl. Die Nebelfarben (Szene
##   und Zonen) und der Dunst des Himmels sind deshalb blauer, bei etwa
##   gleicher Helligkeit; Licht- und Nebelfaktoren der Zonen wie im Entwurf.
##   Gemessen (8 Stellen, Desktop): Helligkeit 62–86, warm 21–41 %, kühl
##   17–26 %, Weg-Luma (P80) 176–195 über der hellsten Kachel außerhalb
##   (118–130), warme Akzente 1,4–3,3 %.
##
## SONNE, zwei Stellungen bei s 60 verglichen (Entwurf §8.3, JT7; Bildpaar
## im Bericht): 35° rechts (Entwurf) und 55° (Jury). Gewählt 35°: Mit 55°
## liegt mehr Weg im Schatten der rechten Wand (s 8: dunkle Wegpixel
## 38,3 → 44,5 %), die rechte Bildhälfte wird dunkler (unten rechts
## Luma 65 → 62 bei s 60, 75 → 71 bei s 140), und der Gewinn an
## Modellierung ist klein; die flache Front, die JT7 befürchtet, nimmt das
## Kantenlicht aus ONO.
##
## ZONEN (§8.3, `Stimmungsregler`, Baukasten G5): Regler nach der Strecke
## s, Werte relativ zur Szene (`licht_faktor` auf das Umgebungslicht,
## `nebel_faktor` verkürzt die Nebelstrecke 16 → 240 m):
##   A Suhle            0–31     Licht 0,75  Nebel 0,9   (0,44/0,50/0,58)
##   B Hohlweg         31–120         1,1         0,85   (0,50/0,58/0,76)
##   C Wurzelterrassen 120–180        1,15        0,8    (0,54/0,60/0,76)
##   D Tobel          180–265         0,9         1,2    (0,42/0,54/0,68)
##   E Mühlbach       265–300         1,2         0,75   (0,56/0,58/0,76)
## Übergänge 10 m breit (A/B 14 m: Dort wacht der Keiler auf, die Luft wird
## weit). Die Eiche nimmt ihren eigenen Nebel mit (`L05Eiche.nebel_stoffe`),
## die Bachnebel-Tafeln ihre Farbe (Nebellicht, heller).
##
## BEWEGUNG (§8.3 „Besonderes", §8.4), jedes Teil EIN MultiMesh ohne
## Schatten, mit harter Sichtweite, fester Saat und ohne globalen Zufall:
## * A: Kronenlicht auf der Decke (Wegdecke, `Level05._abschnitte_rechnen`)
##   und zwei Lichtschächte am Wegrand (SCHAECHTE).
## * B: Pollen im Hohlweg (POLLEN, `Staubflug` hell, langsam, kaum steigend).
## * C: goldener Staub über den drei Wurzeltreppen (STAUB).
## * D: Bachnebel über dem Tobelbach (`GelaendeBau.nebeltafeln`, ein Netz).
## * Laub treibt mit dem Abendwind hangab, auf die Kamera zu (LAUB).
## * Zwei Krähen kreisen über der Hauereiche (`Vogelschwarm`) und fliegen
##   auf, wenn der Keiler erwacht (`L05Jagd.schlaeft`): Sie steigen in
##   KRAEHEN_DAUER um KRAEHEN_HUB, kreisen schneller und schlagen heftiger.
##   Schläft er wieder (Tod vor dem ersten Rastplatz), sitzen sie wieder im
##   Kreis über der Krone. Der Flügelschlag springt dabei EINMAL um, statt
##   mitzugleiten: Der Shader rechnet die Phase als TIME × `schlag_tempo`
##   (voegel.gd), und TIME zählt seit dem Start des Spiels. Ein gleitendes
##   Tempo ergäbe die Frequenz tempo + TIME · d(tempo)/dt – nach 40 s Spiel
##   bis 40 Hz, die Flügel sprängen beim Auffliegen wild. Ein Sprung kostet
##   einen einzigen Phasensprung, wie ein Vogel, der aufschreckt.
##
## KLANG (§8.4, §9.3, Jury JT19): die Mühle als Schleife (`Klang`, „muehle")
## auf einem eigenen `AudioStreamPlayer` – `Klang.spiele` spielt nicht
## räumlich und belegt Stimmen nur kurz. Die Lautstärke folgt dem Abstand
## der Figur zum Rad (MUEHLE_*), mal Gesamtlautstärke (`Klang.
## schleifen_pegel`: stumm und im Browser vor der ersten Eingabe 0). Ist sie
## 0, steht der Spieler. In der Pause hält Godot ihn selbst an (gemessen).
##
## HANDYWEG (§9.5, `Effekte.reduziert`): Staub, Pollen und Laub halbiert,
## kein Funkeln, Lichtschächte nur bis SICHT_SCHACHT_HANDY. Die übrigen
## Punkte des Handywegs stehen in ihren Modulen (Rasen und Streu ×0,5,
## Fernwald ×0,6, Eiche ab 60 m nur fern, Sichtweiten Kisten 40 / Früchte
## 35) bzw. in `LevelBasis` (eine Schattenstufe).
##
## KOSTEN (§10: Stimmung Desktop 12, Handy 6 Zeichenaufrufe): je Teil einer,
## nichts davon wirft Schatten. Gemessen an den acht Fotostellen (s 8, 60,
## 140, 190, 218, 250, 280, 296) als Unterschied mit und ohne diese Teile
## (Rahmen, Horizont, Schächte, Pollen, Staub, Laub, Nebel, Krähen):
## Desktop 4–8 (am meisten bei s 60: Rahmen, Horizont, Krähen, zwei
## Schächte, zwei Pollenräume, Laub), Primitive +680 bis +950. Handyweg
## 4–6: Mit den Schächten bis 75 m waren es dort ebenfalls 4–8, bis 50 m
## (SICHT_SCHACHT_HANDY) fallen sie bei s 60 weg.
## Bauschritt „Abendlicht" kalt 55–59 ms (Bauzeitprobe, Rechner).

## Die Zonen (Schema `Stimmungsregler`). A reicht vor den Start (Kuppe,
## Rundgang), E über das Ende hinaus (Auslauf).
const ZONEN := [
	{"name": "A Suhle", "von": -60.0, "bis": 31.0, "rand_bis": 14.0, "licht_faktor": 0.75,
			"nebel_faktor": 0.9, "nebelfarbe": Color(0.44, 0.50, 0.58)},
	{"name": "B Hohlweg", "von": 31.0, "bis": 120.0, "rand_von": 14.0, "rand_bis": 10.0,
			"licht_faktor": 1.1, "nebel_faktor": 0.85, "nebelfarbe": Color(0.50, 0.58, 0.76)},
	{"name": "C Wurzelterrassen", "von": 120.0, "bis": 180.0, "rand_von": 10.0,
			"rand_bis": 10.0, "licht_faktor": 1.15, "nebel_faktor": 0.8,
			"nebelfarbe": Color(0.54, 0.60, 0.76)},
	{"name": "D Tobel", "von": 180.0, "bis": 265.0, "rand_von": 10.0, "rand_bis": 10.0,
			"licht_faktor": 0.9, "nebel_faktor": 1.2, "nebelfarbe": Color(0.42, 0.54, 0.68)},
	{"name": "E Mühlbach", "von": 265.0, "bis": 420.0, "rand_von": 10.0, "licht_faktor": 1.2,
			"nebel_faktor": 0.75, "nebelfarbe": Color(0.56, 0.58, 0.76)},
]

## Horizont (`KorridorLevel.horizont`): Radius um die Mitte der Strecke, Höhe
## der Kuppen, Fuß unter der Mitte (m) und Farbe (wird vom Nebel gedeckt).
const HORIZONT_R := 300.0
const HORIZONT_HOCH := 30.0
const HORIZONT_FUSS := -14.0
const HORIZONT_FARBE := Color(0.30, 0.36, 0.40)

## Lichtschächte in A (Fuß s, q): am Wegrand, nicht in der Bahn der Kamera
## (lichtschacht.gd: nah ausgeblendet, aber jedes Pixel gezeichnet). Die
## Öffnung liegt SCHACHT_DECKE über der Decke.
const SCHAECHTE: Array[Vector2] = [Vector2(9.0, 6.8), Vector2(23.0, -7.0)]
const SCHACHT_DECKE := 14.0
const SICHT_SCHACHT := 75.0
## Handyweg: Die Schächte stehen dann nur bis hierher (siehe KOSTEN).
const SICHT_SCHACHT_HANDY := 50.0

## Pollen im Hohlweg: Mitten (s) der Räume, Raum (quer, hoch, längs).
const POLLEN: Array[float] = [40.0, 64.0, 88.0, 112.0]
const POLLEN_RAUM := Vector3(9.0, 4.5, 14.0)
const POLLEN_ANZAHL := 70
const POLLEN_FARBE := Color(1.0, 0.96, 0.78)
const SICHT_POLLEN := 40.0
## Staub über den Wurzeltreppen (s der Treppen S1–S3, Mitte der Tritte).
const STAUB: Array[float] = [126.4, 150.4, 174.4]
const STAUB_RAUM := Vector3(8.0, 3.5, 4.0)
const STAUB_ANZAHL := 50
const STAUB_FARBE := Color(1.0, 0.86, 0.6)
const SICHT_STAUB := 35.0
## Laub (s): hangab mit dem Abendwind, auf die Kamera zu. Die Richtung ist
## lokal: −Z den Weg entlang (wachsendes s), +X rechts.
const LAUB: Array[float] = [52.0, 98.0, 142.0, 236.0, 272.0]
const LAUB_ANZAHL := 28
const LAUB_WIND := Vector3(0.3, 0.0, -0.95)
const SICHT_LAUB := 42.0

## Bachnebel: von, bis (s), Abstand der Tafeln (m, ± 20 %), Höhe (m), so viel
## breiter als der Bach (m), Saat.
const NEBEL_STRECKE := Vector2(190.0, 262.0)
const NEBEL_SCHRITT := 6.0
const NEBEL_HOCH := Vector2(2.0, 2.8)
const NEBEL_BREITER := Vector2(1.0, 2.5)
const NEBEL_SAAT := 5801

## Krähen über der Eiche: so hoch über der Mitte der Kerbe kreisen sie, so
## weit, so viele; beim Wecken steigen sie in KRAEHEN_DAUER s um KRAEHEN_HUB
## m, der Umlauf (U/min) geht von ruhig auf aufgeschreckt, der Flügelschlag
## (je s) springt sofort um (siehe Kopf, BEWEGUNG).
const KRAEHEN_UEBER := 7.0
const KRAEHEN_RADIUS := 9.0
const KRAEHEN_ANZAHL := 2
const KRAEHEN_FARBE := Color(0.07, 0.07, 0.09)
const KRAEHEN_DAUER := 3.5
const KRAEHEN_HUB := 10.0
const KRAEHEN_UMLAUF := Vector2(1.2, 3.6)
const KRAEHEN_SCHLAG := Vector2(1.5, 3.4)

## Mühle: Pegel (0..1) nah am Rad, voll bis MUEHLE_NAH m, still ab
## MUEHLE_WEIT m (Abstand Figur – Rad, 3D). Das Rad steht bei s 291; ab
## MUEHLE_WEIT hört man es etwa ab s 225 (D4, L5).
const MUEHLE_LAUT := 0.6
const MUEHLE_NAH := 10.0
const MUEHLE_WEIT := 70.0

## Saaten (feste Zufälle der Teile).
const SAAT := 5800

var level: Level05
## Der Regler (für Proben).
var regler: Stimmungsregler
var kraehen: Vogelschwarm
var muehle: AudioStreamPlayer
## Stoff der Bachnebel-Tafeln (null ohne Tafeln).
var nebel: ShaderMaterial

var _kraehen_y := 0.0
var _flug := 0.0
var _flug_gesetzt := -1.0
var _rad := Vector3.ZERO
var _spieler: Node3D


## Bauschritt (Entwurf §9.4: „Abendlicht", vor dem Keiler).
static func bauschritte(level_: Level05) -> Array:
	return [{"text": "Abendlicht", "tun": func() -> void: anlegen(level_)}]


static func anlegen(level_: Level05) -> L05Stimmung:
	var st := L05Stimmung.new()
	st.name = "Stimmung"
	st.level = level_
	level_.abendlicht = st
	level_.deko.add_child(st)
	var sonne := level_.get_node_or_null("Sonne") as DirectionalLight3D
	var fall := -sonne.global_transform.basis.z.normalized() if sonne != null \
			else Vector3(0.516, -0.438, 0.736)
	st._horizont()
	st._schaechte(fall)
	st._pollen_und_staub()
	st._laub()
	st._bachnebel()
	st._kraehen_setzen()
	st._muehle_anlegen()
	var optionen := {
		"sonne": sonne,
		"oben": level_.get_node_or_null("Himmelslicht"),
		"rahmen": level_.get_node_or_null("Bildrahmen"),
		"nebeltafeln": [st.nebel] if st.nebel != null else [],
		"nebelstoffe": level_.eiche.nebel_stoffe if level_.eiche != null else [],
		"eltern": st,
	}
	st.regler = Stimmungsregler.anlegen(level_, ZONEN, optionen)
	return st


# ================================================================ Licht

## Ferne Hügelkette als Abschluss hinter dem Geländering (Entwurf §8.3,
## Jury JT10): eine Kette aus Kuppen (`kronen`, nur die nahe), außerhalb des
## Geländes (HORIZONT_R um die Mitte der Strecke, das Feld reicht bis 270 m
## von dort), im Dunst – unbeleuchtet, der Nebel macht sie zur Nebelfarbe.
## Sie schließt, was unter den gemalten Hügeln des Himmels zu den Seiten
## offen bliebe. Ein Zeichenaufruf, rund 660 Dreiecke.
func _horizont() -> void:
	var h := level.horizont(HORIZONT_R, HORIZONT_HOCH, HORIZONT_FARBE,
			HORIZONT_FARBE.lightened(0.15), false, HORIZONT_FUSS)
	h.name = "Horizont"
	h.kronen = true
	h.nur_nah = true
	# Neu bauen: `horizont()` hängt ihn schon ein, und erst der Setzer von
	# `radius` baut mit `kronen` und `nur_nah` neu.
	h.radius = h.radius


func _schaechte(fall: Vector3) -> void:
	var wurzel := _wurzel("Lichtschaechte")
	var i := 0
	for e in SCHAECHTE:
		var fuss := level.weg_punkt(e.x, e.y, -0.3)
		var schacht := Lichtschacht.new()
		schacht.name = "Schacht"
		schacht.richtung = fall
		schacht.laenge = 18.0
		schacht.breite = 2.0
		schacht.anzahl = 4
		schacht.streuung = 1.4
		schacht.staerke = 0.09
		schacht.saat = SAAT + 1 + i
		schacht.decke = level.boden_bei(e.x) + SCHACHT_DECKE
		schacht.position = fuss
		schacht.visibility_range_end = SICHT_SCHACHT_HANDY if Effekte.reduziert \
				else SICHT_SCHACHT
		wurzel.add_child(schacht)
		i += 1


# ================================================================ Bewegung

## Pollen (B) und Staub (C), siehe POLLEN/STAUB.
func _pollen_und_staub() -> void:
	var wurzel := _wurzel("Pollen und Staub")
	var reduziert := Effekte.reduziert
	var i := 0
	for s in POLLEN:
		var p := _flug_raum(s, POLLEN_RAUM, POLLEN_ANZAHL, SAAT + 10 + i, SICHT_POLLEN)
		p.name = "Pollen"
		p.groesse = 0.04
		p.farbe = POLLEN_FARBE
		p.deckkraft = 0.55
		p.steiggeschwindigkeit = 0.06
		p.wirbel = 0.5
		p.wirbel_tempo = 0.25
		p.funkeln = 0.0 if reduziert else 0.45
		wurzel.add_child(p)
		i += 1
	for s in STAUB:
		var p := _flug_raum(s, STAUB_RAUM, STAUB_ANZAHL, SAAT + 20 + i, SICHT_STAUB)
		p.name = "Staub"
		p.groesse = 0.05
		p.farbe = STAUB_FARBE
		p.deckkraft = 0.7
		p.steiggeschwindigkeit = 0.18
		p.funkeln = 0.0 if reduziert else 0.6
		wurzel.add_child(p)
		i += 1


## Ein Raum schwebender Teilchen am Weg bei `s`, mit dem Weg gedreht; der
## Handyweg halbiert die Zahl (§9.5). Noch nicht eingehängt: `Staubflug`
## baut in `_ready`, alle Werte gehen also vorher hinein.
func _flug_raum(s: float, raum: Vector3, anzahl: int, saat: int, sicht: float) -> Staubflug:
	var p := Staubflug.new()
	p.raum = raum
	p.anzahl = maxi(anzahl >> 1, 1) if Effekte.reduziert else anzahl
	p.saat = saat
	p.position = level.weg_punkt(s, 0.0, -0.2)
	p.rotation.y = LevelWerkzeuge.drehung(level.verlauf, s)
	p.visibility_range_end = sicht
	return p


## Laub, das hangab treibt (siehe LAUB).
func _laub() -> void:
	var wurzel := _wurzel("Laubtreiben")
	var i := 0
	for s in LAUB:
		var laub := Laubtreiben.new()
		laub.name = "Laub"
		laub.flaeche = Vector2(maxf(level.breite_bei(s), 6.0) + 4.0, 14.0)
		laub.hoehe = 1.8
		laub.anzahl = LAUB_ANZAHL >> 1 if Effekte.reduziert else LAUB_ANZAHL
		laub.groesse = 0.17
		laub.saat = SAAT + 40 + i
		laub.windrichtung = LAUB_WIND.normalized()
		laub.position = level.weg_punkt(s, 0.0, 0.15)
		laub.rotation.y = LevelWerkzeuge.drehung(level.verlauf, s)
		laub.visibility_range_end = SICHT_LAUB
		wurzel.add_child(laub)
		i += 1


## Bachnebel über dem Tobelbach (D), ein Netz (`GelaendeBau.nebeltafeln`).
func _bachnebel() -> void:
	var bach := level.gewaesser
	if bach == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = NEBEL_SAAT
	var tafeln: Array[Dictionary] = []
	var s := NEBEL_STRECKE.x
	while s <= NEBEL_STRECKE.y:
		var ort := bach.bach_ort(s)
		var hoch := rng.randf_range(NEBEL_HOCH.x, NEBEL_HOCH.y)
		tafeln.append({"mitte": ort + Vector3(0.0, hoch * 0.5 - 0.25, 0.0),
				"mass": Vector2(L05Wasser.BACH_BREITE + rng.randf_range(NEBEL_BREITER.x,
						NEBEL_BREITER.y), hoch),
				"phase": rng.randf(), "kraft": rng.randf_range(0.65, 1.0)})
		s += NEBEL_SCHRITT * rng.randf_range(0.8, 1.2)
	var welt := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var farbe := welt.environment.fog_light_color if welt != null else Color(0.48, 0.56, 0.64)
	nebel = GelaendeBau.nebeltafeln(_wurzel("Bachnebel"), tafeln,
			farbe.lightened(Stimmungsregler.NEBELTAFEL_HELLER))


## Zwei Krähen über der Hauereiche (siehe KRAEHEN_*): Mitte über der Kerbe
## zwischen den Kronen (`Level05.wahrzeichen`), ohne Eiche über EICHE.
func _kraehen_setzen() -> void:
	var mitte := Vector3.ZERO
	var gefunden := false
	for e: Dictionary in level.wahrzeichen():
		if String(e["name"]) == "Kerbe":
			var kanten: PackedVector3Array = e["kanten"]
			mitte = level.to_local((kanten[0] + kanten[1]) * 0.5)
			gefunden = true
	if not gefunden:
		var eiche: Dictionary = Level05.EICHE
		mitte = LevelWerkzeuge.punkt_frei(level.verlauf, float(eiche["s"]), 0.0)
		mitte.y = float(eiche["boden_y"]) + 28.0
	var schwarm := Vogelschwarm.new()
	schwarm.name = "Kraehen"
	schwarm.anzahl = KRAEHEN_ANZAHL
	schwarm.radius = KRAEHEN_RADIUS
	schwarm.radius_streuung = 0.25
	# Vogelschwarm: Flughöhe mindestens 8 m über dem Knoten.
	schwarm.hoehe = 8.0
	schwarm.hoehen_streuung = 1.5
	schwarm.spannweite = 1.3
	schwarm.groessen_streuung = 0.1
	schwarm.farbe = KRAEHEN_FARBE
	schwarm.umdrehungen_je_minute = KRAEHEN_UMLAUF.x
	schwarm.schlag_tempo = KRAEHEN_SCHLAG.x
	schwarm.saat = SAAT + 60
	_kraehen_y = mitte.y + KRAEHEN_UEBER - 8.0
	schwarm.position = Vector3(mitte.x, _kraehen_y, mitte.z)
	# Im Bildtakt gehoben (`_process`): ohne Interpolation, sonst zitterte
	# der Schwarm (Glattprobe, ARCHITEKTUR.md „Bildtakt und Physiktakt").
	schwarm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_wurzel("Kraehen").add_child(schwarm)
	kraehen = schwarm


# ================================================================ Klang

func _muehle_anlegen() -> void:
	muehle = AudioStreamPlayer.new()
	muehle.name = "Muehle"
	muehle.bus = "Master"
	muehle.stream = Klang.strom("muehle")
	add_child(muehle)
	_rad = level.weg_punkt(L05Wasser.RAD_S, L05Wasser.RAD_Q)
	if level.gewaesser != null and level.gewaesser.rad != null:
		_rad = level.to_local(level.gewaesser.rad.global_position)


# ================================================================ Lauf

func _process(delta: float) -> void:
	_kraehen_regeln(delta)
	_muehle_regeln()


## Auffliegen beim Wecken, Rückkehr, wenn er wieder schläft (siehe Kopf).
## Höhe und Umlauf gleiten, der Flügelschlag springt beim ersten Bild nach
## dem Wecken bzw. Einschlafen um. Schreibt nur, wenn sich etwas geändert hat.
func _kraehen_regeln(delta: float) -> void:
	if kraehen == null:
		return
	var wach := level.jagd != null and not level.jagd.schlaeft()
	_flug = minf(_flug + delta / KRAEHEN_DAUER, 1.0) if wach else 0.0
	if _flug == _flug_gesetzt:
		return
	var umschlag := (_flug > 0.0) != (_flug_gesetzt > 0.0)
	_flug_gesetzt = _flug
	var t := smoothstep(0.0, 1.0, _flug)
	kraehen.position.y = _kraehen_y + KRAEHEN_HUB * t
	kraehen.umdrehungen_je_minute = lerpf(KRAEHEN_UMLAUF.x, KRAEHEN_UMLAUF.y, t)
	if not umschlag:
		return
	var kreisel := kraehen.get_node_or_null("Kreisel") as MultiMeshInstance3D
	if kreisel != null and kreisel.material_override is ShaderMaterial:
		(kreisel.material_override as ShaderMaterial).set_shader_parameter("schlag_tempo",
				KRAEHEN_SCHLAG.y if _flug > 0.0 else KRAEHEN_SCHLAG.x)


## Lautstärke der Mühle nach dem Abstand der Figur zum Rad (siehe Kopf).
func _muehle_regeln() -> void:
	if muehle == null or muehle.stream == null:
		return
	if _spieler == null or not is_instance_valid(_spieler):
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null:
			return
	var d := level.to_local(_spieler.global_position).distance_to(_rad)
	var pegel: float = Klang.schleifen_pegel(MUEHLE_LAUT
			* (1.0 - smoothstep(MUEHLE_NAH, MUEHLE_WEIT, d)))
	if pegel <= 0.001:
		if muehle.playing:
			muehle.stop()
		return
	muehle.volume_db = linear_to_db(pegel)
	if not muehle.playing:
		muehle.play()


# ================================================================ Hilfen

func _wurzel(name_w: String) -> Node3D:
	var w := Node3D.new()
	w.name = name_w
	add_child(w)
	return w
