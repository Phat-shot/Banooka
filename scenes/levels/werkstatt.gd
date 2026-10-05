extends KorridorLevel
## Werkstatt – jedes Bauteil einmal, hintereinander weg.
##
## Kein Spiellevel. Ein Prüfstand: Nach jeder Änderung an einem Bauteil
## lässt sich hier in einem Durchgang ansehen, ob es noch steht, sich noch
## bewegt und noch aussieht wie gedacht. Ein Fehler in einem Prop fällt
## sonst erst auf, wenn ein Level ihn benutzt – und dann sucht man ihn im
## Level statt im Prop.
##
## Aufruf:
##   FOTO_LEVEL=res://scenes/levels/Werkstatt.tscn \
##       bash werkzeuge/foto.sh /tmp/werkstatt verfolger 8,20,32,...
##
## Die Stationen stehen bewusst weit auseinander und auf breitem Weg: Es
## geht ums Ansehen, nicht ums Bestehen. Wer hier stirbt, hat ein Bauteil
## gefunden, das zu früh trifft.
##
## Station 1–13 zeigen die Spielbauteile aus `korridor_level.gd`, 14–19
## die Schlucht, 20–29 die Bauteile aus Level 01 (Stämme, Kronen, Steine,
## Bewuchs, Zaun, Saum, Waldsetzer, Weltenbaum im Kleinen). 30–33 gehören
## dem Baukasten für Raum 1 (Plan `baukasten.md` §1.7), die neuen Level
## hängen ab 34 an.
##
## Station 30 „Unterbau": der Weg aus `Wegdaten` (scripts/gemeinsam/
## wegdaten.gd) – Terrassen ±1,2 m mit Stufenkollision, Decke ohne
## Bordstein, Leitlinie auf Ebene 16 mit Schulter links, rechts eine offene
## Kante über einer Todeszone „Boden − 6", eine Kiste auf der oberen
## Terrasse (`kiste_auf`), ein Käfer auf der unteren (`gegner_auf`), ein
## Duckdurchlass und eine Tafel, die jeden Aufruf aus der Gruppe
## `LevelBasis.NACH_TOD` anschreibt.
##
## Dahinter die SPRUNGBAHN (Paket G2): zwei flache Lücken, 3,0 und 5,0 m,
## und eine Messhürde. Daran und an Bauteilen der alten Stationen misst
## `sprungfaelle()` jede Art der Sprungprobe einmal (werkzeuge/
## sprungprobe.gd) – mit denselben Maßen, mit denen die Entwürfe von
## Level 02 und 05 rechnen, sodass die Probe ihre Zahlen nachprüfen kann:
##   godot --headless --fixed-fps 60 --path . res://werkzeuge/Sprungprobe.tscn \
##       -- res://scenes/levels/Werkstatt.tscn
## `foto_stelle()` stellt die Figur für Fotos auf die Wegdecke statt 1 m
## über die Kurve – auf den Terrassen schwebte sie sonst oder steckte im Boden.
##
## Station 31 „Themenbühne" (Paket G3): drei Themen hintereinander – Wald,
## Sumpf, Schnee, je 40 m (Schnee bis zum Ziel) –, jedes mit allem, was
## die Raum-1-Level aus den Stoffbausteinen brauchen: Wegdecke ohne
## Bordstein (`Wegdecke`, je Thema ein Stoff), rechts eine Felskante über
## dem Abgrund, die in ein Erdufer über einem Bach übergeht und wieder
## zurück (`Kanten.profil_ab`/`profil_ufer`, gemischt), links eine Böschung
## (`profil_boeschung`), eine Lücke von 3 m mit Stirnwänden (`profil_
## stirn`), Kerbtal und Rinne in den Seiten (`in_luecke`) und Steinen an den
## Lippen (`Wegdecke.lippen`), darunter Gelände (`GelaendeBau`), im Ufer ein
## Bach (`Bachband`), über dem Sumpf Nebeltafeln und hinter ihm ferne Kronen
## mit eigenem Nebel (`Nebelstoff`). Kanten und Gelände liegen im
## Bauspeicher (Schlüssel "werkstatt_…"): Beim zweiten Laden sind es je ein
## Schritt „… wird geladen". Keine Kollision außer Decke, Schulter und
## Leitlinie links; wer rechts über die Kante oder in eine Lücke fällt,
## stirbt 4 m unter der Decke, im Bach an seinem Spiegel.
##
## Station 32 „Bewuchs" (Paket G4): ein Waldweg ohne Bordstein zwischen
## zwei Leitlinien, links ein Hang mit Laub- und Nadelbäumen und Birken,
## rechts eine Wiese mit Weidenhainen, einer Lichtung und einer Mulde –
## gepflanzt von `Baumfabrik.hain` nach den Regeln eines `Waldrahmen`
## (Auge aus der echten Kamera, Freiraum über dem Weg, ein Sichtkegel zum
## Zielportal, Kisten frei), dazu Totholz, Felsen und Treibholz am Fuß der
## Bäume, Sträucher am Rand der Haine (die neuen Rollen M19–M24 aus
## `Fremdmodelle`), ferne Kronen auf dem Hangkamm mit der Himmelsprobe
## (`einsinken`) und Rasen, Streu und Rahmenfarne aus `Rasenbau`. Alles
## steht auf einem eigenen Gelände (`GelaendeBau`, im Bauspeicher).
##
## ZWEI WEGDATEN. `weg` beschreibt den ganzen Prüfstand (die alte Strecke
## samt Station 30 bis 32), damit `breite_bei`, `boden_bei` & Co. überall
## stimmen. Gebaut wird aus `weg` aber nur Station 30 (`_weg_30`), 31
## (`_weg_31`, eigene Lücken für den Stoff der Decke) und 32 (`_weg_32`):
## Der alte Boden bis 450 bleibt der Korridor mit Bordstein, auf dem die
## Stationen 1–29 stehen. Für die alten Stationen ändert `weg` nichts –
## ihre Stellen liegen weit von jeder Kante, Breite und Klemmung bleiben
## dieselben.

## Bis 822,7 m reicht die Kurve (Station 31 und 32 haben sie verlängert,
## siehe `_verlauf_anlegen`).
const M_ENDE := 818.0
const ABSTURZ := -8.0
const WEGBREITE := 12.0
## Bis hier reicht der alte Boden (Korridor mit Bordstein), danach Station 30.
const M_STATION_30 := 450.0

## Abstand zwischen zwei Stationen. Groß genug, dass nichts vom Nachbarn
## überdeckt wird.
const SCHRITT := 14.0

const STRECKE := [
	{"von": 0.0, "bis": 26.0, "breite": WEGBREITE},
	# Lücke 26–34: darüber liegen die Bruchplatten
	{"von": 34.0, "bis": M_STATION_30, "breite": WEGBREITE},
]

## Station 30: die Abschnitte im Schema von Level 01. Die Kurve liegt flach
## (y 0), die Terrassen entstehen über "hoehe". Ohne "hoehe" folgt die
## Decke der Kurve. A verjüngt den alten Weg (12 m) auf 8 m.
##   458  Stufe +1,2 hinauf (springen)
##   470  Stufe −1,2 hinab: zurück UNTER die obere Terrasse geht es nicht
##   480  Stufe −1,2 hinab auf die untere Terrasse (Fels)
##   492  Stufe +1,2 hinauf
##   505  Duckdurchlass, 1,6 m tief
## Die Sprungbahn (G2), flach auf der Kurve:
##   513–516  Lücke 3,0 m
##   529–534  Lücke 5,0 m
##   543,5    Messhürde (Stolperzone bis 544,5)
const LUECKE_3_VON := 513.0
const LUECKE_3_BIS := 516.0
const LUECKE_5_VON := 529.0
const LUECKE_5_BIS := 534.0
## Vorderkante der Stolperzone der Messhürde.
const HUERDE_30 := 543.5
## Schild der Sprungbahn: vor der ersten Lücke und RECHTS über der offenen
## Wegkante. Links hängt über 512 die Nachtodtafel; mit dem Schild links bei
## 526 lagen beide aus der Ferne übereinander (Verfolger bei 486).
const SCHILD_SPRUNGBAHN := 509.0

## Ende von Station 30, Anfang der Themenbühne (Station 31).
const M_STATION_31 := 554.0
## Ende der Themenbühne, Anfang von Station 32 (Bewuchs).
const M_STATION_32 := 690.0

const STATION_30 := [
	{"name": "30A", "von": M_STATION_30, "bis": 458.0, "breite": WEGBREITE,
			"breite_ende": 8.0},
	{"name": "30B", "von": 458.0, "bis": 470.0, "breite": 8.0, "hoehe": 1.2},
	{"name": "30C", "von": 470.0, "bis": 480.0, "breite": 8.0, "hoehe": 0.0},
	{"name": "30D", "von": 480.0, "bis": 492.0, "breite": 8.0, "hoehe": -1.2,
			"stoff": "fels"},
	{"name": "30E", "von": 492.0, "bis": LUECKE_3_VON, "breite": 8.0},
	{"name": "30F", "von": LUECKE_3_BIS, "bis": LUECKE_5_VON, "breite": 8.0},
	{"name": "30G", "von": LUECKE_5_BIS, "bis": M_STATION_31, "breite": 8.0},
]

## Links eine Leitlinie (Ebene 16) 0,6 m außerhalb der Wegkante, dazwischen
## die Schulter; rechts bleibt die Kante offen.
const LEITLINIEN_30 := [
	{"name": "Links 30", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(M_STATION_30, M_STATION_31), "punkte": [
				Vector2(M_STATION_30, -6.4), Vector2(458.0, -4.6), Vector2(M_STATION_31, -4.6)]},
]

## Station 31: die drei Themen in Bau-Reihenfolge (Schlüssel, Name). Jedes
## beginnt bei `M_STATION_31 + THEMA_LAENGE · k`, das letzte reicht bis
## `M_STATION_32`.
const THEMEN_31 := [["wald", "Wald"], ["sumpf", "Sumpf"], ["schnee", "Schnee"]]
const THEMA_LAENGE := 40.0
const WEGBREITE_31 := 8.0
## Innerhalb eines Themas (m ab seinem Anfang): die Lücke …
const LUECKE_31 := Vector2(12.0, 15.0)
## … und das Ufer rechts: blendet 19–23 ein, 35–39 wieder aus (dazwischen
## Erdufer über dem Bach, sonst Felskante über dem Abgrund).
const UFER_31 := Vector4(19.0, 23.0, 35.0, 39.0)
## Höhen relativ zur Decke (die Kurve liegt flach, die Decke auf y 0):
## Grund der Lücke, Fuß der Felskante, Fuß des Ufers, Bachspiegel, Krone
## der Böschung. Die Felskante ist 14 m hoch: Das Profil aus Level 01 legt
## seine Simse 7,2–9,3 m und 11–15 m unter die Kante (saum.gd:723-724) und
## kippt unter gut 13 m Wandhöhe in sich zusammen.
const GRUND_31 := -4.5
const FUSS_31 := -14.0
const UFER_FUSS_31 := -1.6
const SPIEGEL_31 := -1.35
const KRONE_31 := 2.5
## Fußlinie der Böschung (|q|) und Leitlinie links (Ebene 16).
const BOESCHUNG_Q_31 := 4.4
const LEITLINIE_Q_31 := -4.6
## Mitte und Breite des Baches rechts: Die Kante zum Weg liegt im Ufer, die
## andere findet das gezeichnete Gelände.
const BACH_Q_31 := 8.6
const BACH_BREITE_31 := 7.2
## Wer hier fällt, stirbt so tief unter der Decke – höher als der Grund der
## Lücke (−4,5), also bevor die Figur durch den gezeichneten Boden fiele.
const TOD_UNTER_31 := 4.0
## Das Gelände der Themenbühne: Welt-X von–bis (die Strecke läuft hier
## fast genau nach −Z, die Themen stoßen an Linien gleicher Z aneinander).
const GELAENDE_X_31 := Vector2(386.0, 476.0)

const LEITLINIEN_31 := [
	{"name": "Links 31", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(M_STATION_31, M_STATION_32), "punkte": [
				Vector2(M_STATION_31, LEITLINIE_Q_31), Vector2(M_STATION_32, LEITLINIE_Q_31)]},
]

const WEGBREITE_32 := 8.0
## Leitlinien beidseits (Ebene 16), die Schulter dazwischen.
const LEITLINIE_Q_32 := 5.0
const LEITLINIEN_32 := [
	{"name": "Links 32", "aussen": -1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(M_STATION_32, M_ENDE), "punkte": [
				Vector2(M_STATION_32, -LEITLINIE_Q_32), Vector2(M_ENDE, -LEITLINIE_Q_32)]},
	{"name": "Rechts 32", "aussen": 1.0, "hoehe": 6.0, "unten": 3.0,
			"schulter": Vector2(M_STATION_32, M_ENDE), "punkte": [
				Vector2(M_STATION_32, LEITLINIE_Q_32), Vector2(M_ENDE, LEITLINIE_Q_32)]},
]
## Der Hang links: so hoch (über der Decke) steht sein Kamm, so weit vom
## Wegrand beginnt er und so weit liegt der Kamm. Rechts die Mulde: Mitte
## und Tiefe (m) und die Strecke, über die sie reicht.
const HANG_HOCH_32 := 7.0
const HANG_AB_32 := 3.0
const HANG_KAMM_32 := 46.0
const MULDE_Q_32 := 24.0
const MULDE_TIEF_32 := 1.4
const MULDE_S_32 := Vector2(724.0, 776.0)
## Die Lichtung rechts (s von, s bis, q von, q bis): Dort wächst kein Baum,
## der Blick geht über die Wiese in die Mulde.
const LICHTUNG_32 := Vector4(742.0, 756.0, 6.0, 30.0)
## Kisten auf dem Weg (s, q): Bäume, Waldboden und Rasen halten Abstand.
const KISTEN_32 := [Vector2(708.0, -1.6), Vector2(708.0, 1.6), Vector2(764.0, 0.0)]
## Ferne Kronen auf dem Hangkamm: so weit quer, alle so viele Meter.
const FERNE_Q_32 := Vector2(-58.0, -44.0)
const FERNE_SCHRITT_32 := 7.0

## Stirn und Tiefe des Duckdurchlasses, Dauer des Stolperns an seiner Stirn
## (wie `STOLPER_DAUER` in Level 05).
const DURCHLASS_30 := 505.0
const DURCHLASS_30_TIEFE := 1.6
const DURCHLASS_30_STOLPERN := 0.45

## Messhürde nach dem Entwurf von Level 05 (§1 Nr. 12): Körper 0,7 m hoch
## und 0,6 m tief, die Stolperzone 1,0 m lang und vom Boden bis 0,8 m hoch,
## mittig um den Körper.
const HUERDE_HOCH := 0.7
const HUERDE_TIEF := 0.6
const HUERDE_ZONE_TIEF := 1.0
const HUERDE_ZONE_HOCH := 0.8

## Eine Landung zählt in der Sprungprobe ab so weit vor dem Rand der
## Gegenseite (wie Level 01, `LANDUNG_SPIEL`).
const LANDUNG_SPIEL := 0.45

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")

## Nur Station 30, 31 bzw. 32, zum Bauen (siehe Kopf, ZWEI WEGDATEN).
var _weg_30: Wegdaten
var _weg_31: Wegdaten
var _weg_32: Wegdaten
## Station 31: das Gelände je Thema (für das Ufer des Baches).
var _felder_31: Array[GelaendeFeld] = []
## Station 32: das Gelände (Bäume und Rasen stehen auf seiner gezeichneten
## Höhe) und der Rahmen des Waldes (Bauschritt Haine, danach verworfen).
var _feld_32: GelaendeFeld
var _rahmen_32: Waldrahmen
var _rasen_32: Rasenbau

## Die Schlucht am Ende (Station 14–18): eine Wand zu beiden Seiten, an der
## die Bauteile aus Level 01 wachsen. Gut einen Meter Luft neben dem Weg,
## damit der Bewuchs am Wandfuß nicht auf dem Weg steht.
const SCHLUCHT := [
	{"von": 212.0, "bis": 268.0, "abstand": WEGBREITE * 0.5 + 1.2, "hoehe": 8.0},
]


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


## Der Verlauf entsteht VOR der Liste (wie in Level 01): Die Bausteine der
## Themenbühne lesen schon beim Zusammenstellen Weg und Bauspeicher.
func _bauschritte() -> Array:
	_verlauf_anlegen()
	# Die Stoffe der Wegdecke liegen je Schlüssel im Zwischenspeicher von
	# `Wegdecke`; beim Verlassen räumen, sonst hielte er Lücken eines
	# Prüfstands, der nicht mehr steht.
	tree_exiting.connect(func() -> void: Wegdecke.vergessen("werkstatt_"), CONNECT_ONE_SHOT)
	var schritte: Array = [
		{"text": "Boden", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Hügel", "tun": _horizont_bauen},
		{"text": "Taktgeber", "tun": _taktgeber_setzen},
		{"text": "Bewegte Böden", "tun": _boeden_setzen},
		{"text": "Auslöser und Schranken", "tun": _schranken_setzen},
		{"text": "Gegner", "tun": _gegner_setzen},
		{"text": "Hangeln und Deckung", "tun": _koerper_setzen},
		{"text": "Schlucht", "tun": _schlucht_setzen},
		{"text": "Blätterdach", "tun": _blaetterdach_setzen},
		{"text": "Stämme, Kronen, Steine", "tun": _waldbauteile_setzen},
		{"text": "Bewuchs", "tun": _bewuchs_setzen},
		{"text": "Zaun, Saum, Wald", "tun": _waldrand_setzen},
		{"text": "Weltenbaum im Kleinen", "tun": _weltenbaum_setzen},
		{"text": "Unterbau aus Wegdaten", "tun": _station_30_setzen},
	]
	schritte.append_array(_station_31_schritte())
	schritte.append_array(_station_32_schritte())
	schritte.append_array([
		{"text": "Portale", "tun": _portale},
		{"text": "Schilder", "tun": _schilder_setzen},
	])
	return schritte


## Eine leichte Kurve, kein gerader Strich: Bauteile, die sich mit dem Weg
## mitdrehen, verraten ihren Fehler nur auf einer Kurve. Die Punkte bis
## (416, −170) tragen Station 30, die letzten sechs die Themenbühne
## (Station 31), die fast genau nach −Z läuft – so stoßen die Gelände der
## Themen an Linien gleicher Z aneinander, ohne sich zu überdecken.
## Ein angehängter Punkt ändert nur das letzte Kurvenstück: Bis s 528,5 ist
## die Kurve bitgleich mit der ohne Station 31 (gemessen alle 0,5 m), von
## dort bis 556,7 (Sprungbahn von Station 30) weicht sie höchstens 3,0 cm
## und 0,42° ab. Der erste neue Punkt liegt dafür nur 10 m weiter in
## derselben Richtung: Je weiter er läge, desto stärker änderte er das
## letzte Stück (15 cm bei 24 m).
##
## Die Wegdaten entstehen hier, vor allen Bauschritten (siehe Kopf).
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),
		Vector3(0, 0, -30),
		Vector3(6, 0, -64),
		Vector3(20, 0, -94),
		Vector3(42, 0, -116),
		Vector3(70, 0, -128),
		Vector3(100, 0, -130),
		Vector3(130, 0, -124),
		Vector3(160, 0, -112),
		Vector3(188, 0, -97),
		Vector3(214, 0, -86),
		Vector3(240, 0, -79),
		Vector3(266, 0, -76),
		Vector3(292, 0, -78),
		Vector3(318, 0, -85),
		Vector3(342, 0, -96),
		Vector3(364, 0, -110),
		Vector3(384, 0, -126),
		Vector3(402, 0, -146),
		Vector3(416, 0, -170),
		Vector3(421, 0, -179),
		Vector3(427, 0, -196),
		Vector3(431, 0, -220),
		Vector3(432, 0, -248),
		Vector3(430, 0, -276),
		Vector3(431, 0, -304),
		# Station 32: erst 10 m geradeaus weiter, dann eine weite Rechts-
		# kurve – das Auge des Waldrahmens muss auch in der Kurve stimmen.
		# Die Kurve bis s 666 bleibt bitgleich, bis 690 (Ende der
		# Themenbühne) weicht sie höchstens 2,7 cm und 0,31° ab (gemessen
		# alle 0,5 m).
		Vector3(431.36, 0, -314),
		Vector3(433, 0, -338),
		Vector3(439, 0, -362),
		Vector3(450, 0, -384),
		Vector3(465, 0, -402),
		Vector3(482, 0, -416),
	])
	var station_31 := _station_31_abschnitte()
	var station_32 := _station_32_abschnitte()
	var alle: Array = STRECKE.duplicate()
	alle.append_array(STATION_30)
	alle.append_array(station_31)
	alle.append_array(station_32)
	weg = Wegdaten.new(verlauf, {"abschnitte": alle})
	_weg_32 = Wegdaten.new(verlauf, {"abschnitte": station_32, "leitlinien": LEITLINIEN_32})
	_weg_30 = Wegdaten.new(verlauf, {"abschnitte": STATION_30, "leitlinien": LEITLINIEN_30})
	# Unter der ganzen Station eine Todeszone „Boden − 6": rechts über die
	# offene Kante, unter jeder Terrasse auf ihrer eigenen Höhe. Sie liegt
	# über den alten Absturzzonen (Kurve − 8), fängt also zuerst.
	_weg_30.todeszonen = Wegdaten.zonen_unter_boden(_weg_30, M_STATION_30, M_STATION_31,
			-30.0, 30.0, 6.0)
	_weg_31 = Wegdaten.new(verlauf, {"abschnitte": station_31, "leitlinien": LEITLINIEN_31})
	# Station 31: „Boden − 4" überall (rechts über die Kante, in den Lücken),
	# dazu je Thema der Bach auf Höhe seines Spiegels.
	var zonen := Wegdaten.zonen_unter_boden(_weg_31, M_STATION_31, M_STATION_32, -30.0, 30.0,
			TOD_UNTER_31, 12.0)
	for k in THEMEN_31.size():
		var a := M_STATION_31 + THEMA_LAENGE * float(k)
		zonen.append({"name": "Bach 31", "von": a + UFER_31.y - 1.0, "bis": a + UFER_31.z + 1.0,
				"q_von": WEGBREITE_31 * 0.5 + 0.8, "q_bis": 20.0, "oben_y": SPIEGEL_31 - 0.1,
				"unten_y": SPIEGEL_31 - 6.0})
	_weg_31.todeszonen = zonen


## Der alte Boden (Station 1–29) und Warnpfosten an den Lücken – nur bis
## Station 30: An der Themenbühne zeigen Steine die Lippen (Wegdecke).
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.moos(),
		"klippe": Materialbibliothek.fels(),
	}, {"tiefe": 4.0, "schritt": 1.2, "kante_hoehe": 0.24, "kante_breite": 0.7})
	# Wie `luecken_markieren()`, aber nicht in Station 31.
	var liste := abschnitte()
	for i in liste.size() - 1:
		var a: Dictionary = liste[i]
		var naechster: Dictionary = liste[i + 1]
		if float(naechster["von"]) >= M_STATION_31:
			break
		if naechster["von"] - a["bis"] > 0.5:
			warnbalken(a["bis"] - 0.5, a.get("breite_ende", a["breite"]))
			warnbalken(naechster["von"] + 0.5, naechster["breite"])


func _absturz_spannen() -> void:
	absturzzonen(18.0, 70.0)


func _horizont_bauen() -> void:
	horizont(200.0, 30.0, Color(0.38, 0.40, 0.34), Color(0.58, 0.62, 0.58),
			true, -7.0)


# =========================================================== Stationen

## Station 1–5: alles, was einen Takt hat.
func _taktgeber_setzen() -> void:
	# 1 · Bruchplatten über der Lücke bei 26–34 m
	bruchplatten_reihe(27.0, 33.0, 4, 0.0, -0.2)

	# 2 · Taktwelle: fünf Flächen mit versetzter Phase
	taktwelle(40.0, 54.0, 5, 0.0, Vector2(2.6, 2.6), 0.2)

	# 3 · Feuerspeier, einer fest und einer schwenkend
	feuerspeier(62.0, -4.2, 1.1, 0.0, 3.4, 0.0)
	feuerspeier(68.0, 4.2, 1.1, 180.0, 3.4, 0.35, true)

	# 4 · Laserzaun mit wandernder Lücke
	laserzaun(78.0, 6.0, true, 1.2)

	# 5 · Rollbrocken, Kugel und Fass nebeneinander
	rollbrocken(86.0, 100.0, -3.0, 0.0, 1.1, 7.0, 2.0, 0.0)
	rollbrocken(86.0, 100.0, 3.0, 0.0, 0.8, 6.0, 2.0, 0.5,
			Rollhindernis.Art.FASS)


## Station 6–8: Böden, die sich bewegen.
func _boeden_setzen() -> void:
	# 6 · Drehscheibe
	drehscheibe(108.0, 0.0, 0.2, 4.2, 34.0)

	# 7 · Fließband
	laufband(118.0, 128.0, 0.0, 0.1, 3.4, 2.5, 1)

	# 8 · Schiebeblock, mit reichlich Luft zur Kante
	schiebeblock(136.0, -2.0, 0.0, Vector3(1.8, 1.2, 1.8), 3.4, true, 1.4, 1.0)


## Station 9–10: Auslöser und Schranken.
func _schranken_setzen() -> void:
	# 9 · Platte, die das Tor offen hält – ein Hindernis, zwei Rollen
	var tor := schliesstuer(150.0, 0.0, 3.6, 2.8, 2.0, 1.6)
	ausloeseplatte(145.0, 0.0, Vector2(2.6, 2.6), 1.2, false, [tor])

	# 10 · Wasserplattform als Aufzug, damit auch das Alte im Bild ist
	wehrbohle(158.0, -3.6, 1.6, -0.4, 0.0)


## Station 11–12: die neuen Gegner.
func _gegner_setzen() -> void:
	werfer(166.0, -3.4)
	schwarm(176.0, 0.0, 10.0)


## Station 13–14: Hangeln und Deckung.
func _koerper_setzen() -> void:
	hangelgitter(188.0, 0.0, 3.2, 9.0)
	deckungsfleck(176.0, 3.0)
	# Zwei Kisten als Größenvergleich – ohne etwas Bekanntes im Bild
	# lässt sich kein Maß beurteilen.
	kiste(Kiste.Art.EISEN, 200.0, -1.6)
	kiste(Kiste.Art.NORMAL, 200.0, 1.6)


## Station 14–18: die Schlucht aus Level 01 im Kleinen – Wand mit
## gemerkten Kronen, Bewuchs daran, Wasserfall, Lichtschacht, Wurzeltor
## und ein umgestürzter Stamm.
func _schlucht_setzen() -> void:
	var wand := LevelWerkzeuge.schluchtwand(geometrie, verlauf, SCHLUCHT,
			Materialbibliothek.wurzelfels(), {
		"schritt": 2.4, "lagen": 3, "block": 3.0, "sockel": 10.0, "saat": 1407,
		"adermaterial": Materialbibliothek.waldboden(),
		"deckmaterial": Materialbibliothek.moos(),
		"welt_projektion": true,
		"welt_kachel": Vector3(0.19, 0.3, 0.19),
		"kronen_merken": true,
	})
	var kronen: Array = wand.get_meta("kronen", [])
	# Ein Erdsims schließt den Spalt zwischen Weg und Wandfuß, wie in
	# Level 01 – sonst steht dort ein heller Streifen Himmel.
	var zone: Dictionary = SCHLUCHT[0]
	LevelWerkzeuge.sims(geometrie, verlauf, [{"von": zone["von"], "bis": zone["bis"],
			"innen": WEGBREITE * 0.5 - 0.3, "aussen": float(zone["abstand"]) + 0.5,
			"hoehe": -0.3}], Materialbibliothek.waldboden(), 2.0)

	# 14 · Bewuchs, mit Blüten, damit auch das dritte Netz im Bild ist
	Schluchtsaum.bauen(deko, verlauf, kronen, {"saat": 1408, "blueten": 1.0})

	# 15 · Wasserfall an der linken Wand
	Wasserfall.an_schluchtwand(deko, verlauf, kronen, 224.0, -1.0, 3.2, -6.0)

	# 16 · Lichtschacht an der rechten Wand, in der Richtung der Sonne
	var schacht := Lichtschacht.new()
	var sonne := get_node_or_null("Sonne") as DirectionalLight3D
	if sonne != null:
		schacht.richtung = -sonne.global_transform.basis.z
	schacht.saat = 1416
	schacht.laenge = 16.0
	schacht.position = LevelWerkzeuge.punkt(verlauf, 234.0, 4.0, -0.5)
	schacht.decke = LevelWerkzeuge.punkt(verlauf, 234.0).y \
			+ float(SCHLUCHT[0]["hoehe"])
	deko.add_child(schacht)

	# 17 · Wurzeltor von Wand zu Wand
	Schluchtsaum.wurzeltor(deko, verlauf, 244.0,
			float(SCHLUCHT[0]["abstand"]), 1417)

	# 18 · Umgestürzter Stamm hoch über dem Weg, von Krone zu Krone
	var a := _kronenpunkt(kronen, 251.0, -1.0)
	var b := _kronenpunkt(kronen, 257.0, 1.0)
	Schluchtsaum.baumstamm(deko, a, b, 0.7,
			LevelWerkzeuge.punkt(verlauf, 254.0).y + 6.0, 1418)


## Station 19: ein Blätterdach neben dem Weg, tief unten – Wald, auf den
## man von oben schaut.
func _blaetterdach_setzen() -> void:
	var rng := PropWerkzeug.zufall(1419)
	var baeume: Array = []
	for i in 14:
		var strecke := rng.randf_range(270.0, 284.0)
		var quer := rng.randf_range(9.0, 18.0)
		baeume.append({
			"fuss": LevelWerkzeuge.punkt(verlauf, strecke, quer, -12.0),
			"hoehe": rng.randf_range(8.0, 10.0),
			"breite": rng.randf_range(2.6, 3.6),
		})
	Schluchtsaum.blaetterdach(deko, baeume, 1420)


# =================================================== Bauteile aus Level 01
#
# Station 20–29. Alles ohne Kollision bis auf den Kasten unter dem
# Findling (Station 22) – die Bauteile stehen am Wegrand, die Mitte bleibt
# frei. Jedes Teil so, wie sein Kopfkommentar es aufruft.

## Station 20–22: Stämme, Kronen, Steine.
func _waldbauteile_setzen() -> void:
	var borke := Riesenstamm.borkenstoff()

	# 20 · Riesenstamm: Talriese mit Brettwurzeln und Beiwerk, oben
	# gebrochen; daneben ein liegender Stamm und ein Stumpf
	var riese := Riesenstamm.netz({"hoehe": 15.0, "radius": 0.9, "brettwurzeln": 6,
			"pilze": 2, "efeu": 1, "leuchtpilze": 1, "oben": "bruch", "saat": 2001})
	_netz_setzen(riese, borke, _lage(298.0, 4.2), true, "Talriese")
	var liegend := Riesenstamm.liegend(0.45, 5.0, {"saat": 2002, "aeste": 2})
	# Die Achse liegt entlang +Y: um X gekippt zeigt sie den Weg entlang.
	var quer := _lage(296.0, -4.0, 0.36)
	quer.basis = quer.basis * Basis(Vector3.RIGHT, -PI * 0.5)
	_netz_setzen(liegend, borke, quer, true, "Liegend")
	_netz_setzen(Riesenstamm.stumpf(0.6, 1.2, {"saat": 2003}), borke,
			_lage(303.0, -4.4), true, "Stumpf")

	# 21 · Kronenwolke: ein Baum mit Ästen in die Krone, dazu die drei
	# Varianten (rund, breit, hoch) und die Fernfassung, bodennah
	var baum := Riesenstamm.baum({"hoehe": 11.0, "radius": 0.3, "aeste": 4, "saat": 2101})
	_netz_setzen(baum["stamm"], borke, _lage(312.0, 4.4), true, "Baum")
	_netz_setzen(baum["krone"], Kronenwolke.stoff(Farben.LAUB), _lage(312.0, 4.4), false,
			"Baumkrone")
	for variante in 3:
		var krone := Kronenwolke.netz({"radius": 1.3, "variante": variante,
				"saat": 2102 + variante})
		_netz_setzen(krone, Kronenwolke.stoff(Farben.LAUB),
				_auf_boden(krone, 307.0 + 3.6 * float(variante), -4.2), false,
				"Krone %d" % variante)
	var fern := Kronenwolke.fern({"radius": 1.6, "saat": 2105})
	_netz_setzen(fern, Kronenwolke.stoff(Farben.LAUB, false), _auf_boden(fern, 318.5, -4.2),
			false, "Krone fern")

	# 22 · Findling genau auf seinem Kasten – der Kasten trägt, man kann
	# hinaufspringen. Daneben ein Deko-Brocken und ein Trittstein.
	var groesse := Vector3(2.4, 1.0, 1.8)
	var kasten := _lage(326.0, 3.4, groesse.y * 0.5)
	var koerper := StaticBody3D.new()
	koerper.name = "Findlingskasten"
	koerper.transform = kasten
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = groesse
	form.shape = box
	koerper.add_child(form)
	geometrie.add_child(koerper)
	Findling.bauen(deko, groesse, kasten, {"saat": 2201})
	_netz_setzen(Findling.brocken(Vector3(1.4, 0.9, 1.2), {"saat": 2202}), Findling.stoff(),
			_lage(324.0, -4.3, 0.3, 0.6), true, "Brocken")
	_netz_setzen(Findling.scheibe(0.8, 0.6, {"saat": 2203, "wasser_y": 0.1}), Findling.stoff(),
			_lage(329.0, -3.6, 0.1), true, "Trittstein")


## Station 23–25: Bewuchs am Boden.
func _bewuchs_setzen() -> void:
	var rng := PropWerkzeug.zufall(2300)

	# 23 · Farnwerk: kleine Farne links, große rechts, ein Rahmenfarn
	var farnstoff := Farnwerk.stoff(Farben.LAUB)
	for k in 5:
		_netz_setzen(Farnwerk.klein(k + 1), farnstoff,
				_lage(334.0 + 2.0 * float(k), rng.randf_range(-5.4, -3.6), 0.0, float(k) * 1.3),
				false, "Farn klein %d" % k)
	for k in 2:
		_netz_setzen(Farnwerk.gross(k + 1), farnstoff,
				_lage(335.0 + 5.0 * float(k), 4.6, 0.0, float(k) * 2.0), false, "Farn gross %d" % k)
	_netz_setzen(Farnwerk.rahmen(1), farnstoff, _lage(342.0, -4.8, 0.0, 0.8), false,
			"Rahmenfarn")

	# 24 · Rasensaum: Flecken und Büschel rechts, Wispelgras über der
	# Kante, Moospolster und Moosflecken links
	var flecken: Array[Transform3D] = []
	var buesche: Array[Transform3D] = []
	var wispel: Array[Transform3D] = []
	var polster: Array[Transform3D] = []
	var moos: Array[Transform3D] = []
	var farben_f := PackedColorArray()
	var farben_b := PackedColorArray()
	var farben_w := PackedColorArray()
	var farben_p := PackedColorArray()
	var farben_m := PackedColorArray()
	for i in 140:
		flecken.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(2.4, 5.8), 0.0,
				rng.randf() * TAU))
		farben_f.append(Rasensaum.farbe(0.9, 1.0, rng.randf_range(0.35, 0.65), 0.0))
	for i in 18:
		buesche.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(5.0, 5.8), 0.0,
				rng.randf() * TAU))
		farben_b.append(Rasensaum.farbe(0.85, 1.0, rng.randf_range(0.4, 0.6), 0.0))
	for i in 8:
		# Wispelgras hängt nach +X über eine Kante: mit der Wegdrehung ist das
		# die rechte Wegkante.
		wispel.append(_lage(346.0 + 1.2 * float(i), 5.85, 0.0, rng.randf_range(-0.3, 0.3)))
		farben_w.append(Rasensaum.farbe(Wegmaske.RAND_VERDECKUNG, 1.0, 0.5, 0.0))
	for i in 6:
		polster.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(-5.4, -3.0), 0.0,
				rng.randf() * TAU))
		farben_p.append(Rasensaum.farbe(0.9, 1.0, 0.5, 0.0))
		moos.append(_lage(rng.randf_range(345.0, 355.0), rng.randf_range(-5.4, -3.0), 0.0,
				rng.randf() * TAU))
		farben_m.append(Rasensaum.farbe(0.9, 1.0, 0.5, 0.0))
	Rasensaum.feld(deko, "Rasen Flecken", Rasensaum.fleck(2401), flecken, farben_f)
	Rasensaum.feld(deko, "Rasen Bueschel", Rasensaum.bueschel(2402), buesche, farben_b)
	Rasensaum.feld(deko, "Rasen Wispel", Rasensaum.wispel(2403), wispel, farben_w)
	Rasensaum.feld(deko, "Rasen Polster", Rasensaum.polster(2404), polster, farben_p)
	Rasensaum.feld(deko, "Rasen Moos", Rasensaum.moosfleck(2405), moos, farben_m,
			Rasensaum.SICHTWEITE, true)

	# 25 · Bodenstreu: Klee, Blüten, Kiesel und Pilze in EINEM Netz, dazu
	# Großblattstauden als Feld
	var haufen := Bodenstreu.Haufen.new(LevelWerkzeuge.punkt(verlauf, 362.0))
	for i in 4:
		haufen.teil(Bodenstreu.klee(rng, 0.35, i % 2 == 0),
				_lage(358.0 + 2.5 * float(i), rng.randf_range(-5.2, -2.8)))
	for i in 5:
		haufen.teil(Bodenstreu.blueten(rng, i % 3, Bodenstreu.BLUETEN_FARBEN[i]),
				_lage(357.0 + 2.2 * float(i), rng.randf_range(2.8, 5.2)))
	for i in 4:
		haufen.teil(Bodenstreu.kiesel(rng, 0.16, 3),
				_lage(rng.randf_range(357.0, 367.0), rng.randf_range(-5.4, -2.6)))
	for i in 3:
		haufen.teil(Bodenstreu.pilze(rng, 0.06, 3, i == 2),
				_lage(359.0 + 3.0 * float(i), rng.randf_range(2.6, 4.4)))
	haufen.knoten(deko, "Streu", 60.0)
	var stauden: Array[Transform3D] = []
	var farben_s := PackedColorArray()
	for i in 3:
		stauden.append(_lage(358.0 + 4.0 * float(i), 5.0, 0.0, rng.randf() * TAU))
		farben_s.append(Color.WHITE)
	Bodenstreu.feld(deko, "Grossblatt", Bodenstreu.grossblatt(rng, 1.0).netz(), stauden,
			farben_s, 60.0)


## Station 26–28: Zaun, Saum und ein kleiner Wald.
func _waldrand_setzen() -> void:
	# 26 · Totholzzaun am rechten Rand, mit geborstenem Endpfosten
	var linie := PackedVector3Array()
	var s := 368.0
	while s <= 381.0:
		linie.append(LevelWerkzeuge.punkt(verlauf, s, 5.3))
		s += 1.0
	_netz_setzen(Totholzzaun.bauen(linie, {"saat": 2601, "aussen": 1.0,
			"ende_geborsten": true, "verfall": 0.5}), Totholzzaun.stoff(), Transform3D.IDENTITY,
			true, "Totholzzaun")

	# 27 · GelaendeSaum: eine Felsbank am linken Rand
	_saum_setzen(383.0, 394.0)

	# 28 · Waldsetzer: ein Hain aus vier Bäumen und Farnen in drei Arten,
	# Stämme und Kronen je Zelle verschmolzen, Farne als MultiMesh
	var ws := Waldsetzer.new(deko, "Waldprobe", 20.0)
	ws.art("stamm", {"stoff": Riesenstamm.borkenstoff(), "schatten": true, "sicht": 120.0,
			"verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(Farben.LAUB_DUNKEL), "sicht": 120.0,
			"verschmelzen": true, "karten": true})
	ws.art("farn", {"stoff": Farnwerk.stoff(Farben.LAUB), "sicht": 60.0})
	var rng := PropWerkzeug.zufall(2800)
	for k in 4:
		var b := Riesenstamm.baum({"hoehe": rng.randf_range(9.0, 11.0),
				"radius": rng.randf_range(0.24, 0.3), "aeste": 3, "saat": 2801 + k})
		var lage := _lage(397.0 + 3.6 * float(k), 4.8 if k % 2 == 0 else -4.8, 0.0,
				rng.randf() * TAU)
		var ton := Color(1.0, 1.0, 1.0).darkened(rng.randf_range(0.0, 0.15))
		ws.setze("stamm", b["stamm"], lage, ton)
		ws.setze("krone", b["krone"], lage, ton)
	var farn := Farnwerk.klein(7)
	for k in 8:
		ws.setze("farn", farn, _lage(rng.randf_range(397.0, 408.0),
				rng.randf_range(3.2, 5.6) * (1.0 if k % 2 == 0 else -1.0), 0.0,
				rng.randf() * TAU))
	ws.fertig()


## Eine Felsbank aus `GelaendeSaum`: Fuß im Rasen am Wegrand, Schichtfels,
## ein kleiner Überhang, Grasnarbe obenauf und hinten wieder hinab. Die
## Enden schließt `deckel()`.
func _saum_setzen(von: float, bis: float) -> void:
	const SEITE := -1.0
	var q := -WEGBREITE * 0.5 + 0.6
	var proben := GelaendeSaum.linie(verlauf, PackedVector2Array([Vector2(von, q),
			Vector2(bis, q)]), 0.8)
	var g := GelaendeSaum.querschnitte(verlauf, proben, SEITE, _saum_profil,
			func(_i: int, _probe: Dictionary) -> float: return 0.0,
			func(_i: int, _probe: Dictionary) -> float: return 0.0)
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var farben: Array[PackedColorArray] = g["farben"]
	var n := reihen.size()
	if n < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	GelaendeSaum.gitter_schreiben(st, g, GelaendeSaum.normalen(g), 0, n - 1)
	for ende in 2:
		var i := 0 if ende == 0 else n - 1
		var aussen := reihen[i][0] - reihen[1 if ende == 0 else n - 2][0]
		aussen.y = 0.0
		if aussen.length_squared() > 0.000001:
			GelaendeSaum.deckel(st, reihen[i], farben[i], aussen.normalized(), 0.0)
	st.index()
	_netz_setzen(st.commit(), GelaendeSaum.stoff(), Transform3D.IDENTITY, false, "Saum")


## Querschnitt der Felsbank: Versatz nach außen und Welt-Y, Farbe als
## (Verdeckung, Erde, Moos, Rasen). Zur Mitte der Bank hin höher.
func _saum_profil(i: int, _probe: Dictionary) -> GelaendeSaum.Profil:
	var h := 2.6 + 0.8 * sin(float(i) * 0.45)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.5, -0.02, Color(0.78, 0.0, 0.1, 1.0))
	p.punkt(0.0, 0.0, Color(0.5, 0.7, 0.3, 0.3))
	p.punkt(0.15, 0.35, Color(0.35, 0.8, 0.1, 0.0), 0.8, 0.12, 2.0)
	p.punkt(0.3, h * 0.35, Color(0.6, 0.15, 0.05, 0.0), 1.6, 0.25, 2.0, 0.12)
	p.punkt(0.45, h * 0.65, Color(0.65, 0.1, 0.05, 0.0), 1.6, 0.25, 2.0, 0.12)
	p.punkt(0.4, h * 0.9, Color(0.55, 0.1, 0.2, 0.0), 0.8, 0.15, 1.0)
	p.punkt(0.65, h, Color(0.7, 0.2, 0.5, 0.3))
	p.punkt(1.2, h + 0.08, Color(0.8, 0.0, 0.2, 1.0))
	p.punkt(2.4, h + 0.1, Color(0.8, 0.0, 0.1, 1.0))
	p.punkt(3.0, h * 0.6, Color(0.5, 0.4, 0.2, 0.3), 1.6, 0.2, 2.0)
	p.punkt(3.3, -1.5, Color(0.3, 0.6, 0.1, 0.0), 1.6, 0.2, 2.0)
	return p


## Station 29: der Weltenbaum im Maßstab 1:8 – rund 3 statt 24 m Stamm-
## durchmesser. Der echte (Level 01) passt auf keinen Prüfstand, und ein
## Platz für ein größeres Muster zöge Nähte quer über den Weg; die
## Bausteine sind dieselben: Stamm aus `profil` mit Brettwurzeln, Ästen,
## Konsolen, Knollen, Efeu und Leuchtpilzen, darauf der Kronenschirm aus
## Ballen. Die Borke in Weltprojektion mit der Kachel für diesen Radius –
## die des Riesen (`Weltenbaum.stoff_stamm`) wäre hier achtmal zu grob.
func _weltenbaum_setzen() -> void:
	var fuss := _lage(432.0, 3.6)
	var st := Riesenstamm.bauer()
	var info := Weltenbaum.stamm_in(st, {
		"profil": PackedVector2Array([Vector2(-1.0, 2.0), Vector2(0.5, 1.6),
				Vector2(3.0, 1.3), Vector2(8.0, 1.1), Vector2(12.0, 1.0)]),
		"y_von": -1.0, "y_bis": 12.0, "rippen": 24, "ring_min": 0.5, "ring_max": 1.2,
		"saat": 2901,
		"brettwurzeln": [
			{"winkel": 0.4, "reichweite": 2.2, "hoehe": 1.4, "dicke": 0.22, "fuss_y": -0.5},
			{"winkel": 2.2, "reichweite": 1.9, "hoehe": 1.2, "dicke": 0.2, "fuss_y": -0.5},
			{"winkel": 3.6, "reichweite": 2.4, "hoehe": 1.6, "dicke": 0.22, "fuss_y": -0.5},
			{"winkel": 5.1, "reichweite": 1.8, "hoehe": 1.1, "dicke": 0.2, "fuss_y": -0.5},
		],
		"aeste": [
			{"winkel": 0.8, "y": 9.2, "laenge": 2.6, "steigung": 0.5, "radius": 0.32},
			{"winkel": 2.9, "y": 9.8, "laenge": 2.3, "steigung": 0.55, "radius": 0.28},
			{"winkel": 4.8, "y": 10.4, "laenge": 2.4, "steigung": 0.5, "radius": 0.28},
		],
		"pilze": [{"winkel": 1.6, "y": 2.6, "breite": 0.9}],
		"knollen": [{"winkel": 4.2, "y": 3.4, "radius": 0.3}],
		"efeu": [{"winkel": 2.6, "von": 0.0, "bis": 5.5}],
		"leuchten": [{"winkel": 5.6, "y": 0.6}],
	})
	_netz_setzen(Riesenstamm.fertig(st), Riesenstamm.borkenstoff({"welt": true, "radius": 1.5}),
			fuss, true, "Weltenbaum")
	var spitzen: PackedVector3Array = info["ast_spitzen"]
	var ballen: Array = []
	for k in spitzen.size():
		ballen.append({"mitte": spitzen[k], "radius": 1.8, "variante": 1, "saat": 2910 + k})
	ballen.append({"mitte": Vector3(0.0, 12.6, 0.0), "radius": 2.2, "variante": 1, "saat": 2920})
	_netz_setzen(Weltenbaum.krone(ballen, false), Weltenbaum.stoff_krone(), fuss, false,
			"Weltenbaum Krone")


# =================================================== Baukasten Raum 1

## Station 30: der Unterbau aus `Wegdaten` und die Helfer `*_auf` aus
## `KorridorLevel` (Paket G1). Abnahme (Plan G1): Der Rückweg unter die
## obere Terrasse ist gesperrt (Stufenkollision und zwei Meter dicke
## Schulter); der Duckdurchlass sperrt die aufrechte Kapsel und lässt Slide
## und Krabbeln durch, ein Doppelsprung kommt nicht darüber; ein Tod
## schreibt `nach_tod(false)` an die Tafel.
func _station_30_setzen() -> void:
	# Die untere Terrasse in Fels, der Rest fällt auf den Waldweg zurück
	# (null): zwei Stoffe, also zwei Netze und eine Kollision.
	_weg_30.decke_bauen(geometrie, func(a: Dictionary) -> Material:
		if String(a.get("stoff", "")) == "fels":
			return Materialbibliothek.fels()
		return null)
	_weg_30.leitlinien_bauen(geometrie)
	_weg_30.schultern_bauen(geometrie)
	_weg_30.todeszonen_bauen(geometrie)

	# Auf der oberen Terrasse (+1,2): zwei Kisten über die Decke gesetzt.
	kiste_auf(Kiste.Art.NORMAL, 464.0, -2.0)
	kiste_auf(Kiste.Art.FRUCHT_MEHRFACH, 464.0, 2.0)
	# Auf der unteren Terrasse (−1,2) ein Käfer, der längs patrouilliert: Die
	# Weite klemmt am Strang 480–492, nicht an der Kurve.
	gegner_auf(PANZERKAEFER, 486.0, 0.0, 3.0, false)
	# Bogen über die Stufe hinauf, gemessen an der Decke.
	fruechte_bogen_auf(489.5, 494.5, 5, 0.0, 2.2)
	for i in 3:
		frucht_auf(500.0 + 1.2 * float(i), 0.0, 0.45)

	duckdurchlass(DURCHLASS_30, DURCHLASS_30_TIEFE, {
		"stolperzone": DURCHLASS_30_STOLPERN,
		"optik": _durchlass_optik,
	})
	_messhuerde(HUERDE_30)

	var tafel := Nachtodtafel.new()
	tafel.name = "Nachtodtafel"
	tafel.text = "30 nach_tod\nnoch kein Aufruf"
	tafel.font_size = 72
	tafel.pixel_size = 0.012
	tafel.modulate = Color(0.85, 0.95, 1.0)
	tafel.outline_size = 18
	tafel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Hinter dem Durchlass und links über der Leitlinie: Näher und weiter
	# innen stünde sie der Verfolgerkamera vor 494–500 mitten im Bild.
	tafel.position = weg_punkt(512.0, -5.6, 3.0)
	deko.add_child(tafel)
	nach_tod_melden(tafel)


## Messhürde der Sprungbahn: Körper auf Ebene 16 wie der Duckdurchlass, die
## Stolperzone an seiner Stelle (`stolpern` mit der Dauer des Durchlasses).
## Nur ein Prüfling für die Art `huerde` der Sprungprobe – das Bauteil
## `huerde()` mit Optik baut erst das Paket von Level 05. `s` ist die
## Vorderkante der Zone; quer reicht beides bis an die Leitlinie.
func _messhuerde(s: float) -> void:
	var halb := breite_bei(s) * 0.5 + 1.0
	var mitte := s + HUERDE_ZONE_TIEF * 0.5
	var koerper := StaticBody3D.new()
	koerper.name = "Messhuerde"
	koerper.collision_layer = LevelWerkzeuge.SPIELERGRENZE
	koerper.collision_mask = 0
	var schnitte: Array[PackedVector3Array] = [
		_durchlass_schnitt(mitte - HUERDE_TIEF * 0.5, -halb, halb, 0.0, HUERDE_HOCH),
		_durchlass_schnitt(mitte + HUERDE_TIEF * 0.5, -halb, halb, 0.0, HUERDE_HOCH),
	]
	koerper.add_child(Wegdaten.prisma(schnitte[0], schnitte[1]))
	var zone := Area3D.new()
	zone.name = "Stolperzone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.monitorable = false
	zone.add_child(Wegdaten.prisma(
			_durchlass_schnitt(s, -halb, halb, 0.0, HUERDE_ZONE_HOCH),
			_durchlass_schnitt(s + HUERDE_ZONE_TIEF, -halb, halb, 0.0, HUERDE_ZONE_HOCH)))
	zone.body_entered.connect(_durchlass_stolpern.bind(DURCHLASS_30_STOLPERN))
	koerper.add_child(zone)
	var netz := MeshInstance3D.new()
	netz.name = "Platzhalter"
	netz.mesh = Wegdaten.schnittnetz(schnitte)
	netz.material_override = Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	koerper.add_child(netz)
	geometrie.add_child(koerper)


## Optik des Duckdurchlasses an Station 30, nach dem Entwurf von Level 05
## (§1 Nr. 2): ein massiver Riegel 0,95–1,40 m, darüber Latten mit viel
## Luft dazwischen, eine Kappe bis 4,4 m und zwei Pfosten außen. Alles ohne
## Kollision – die trägt der Körper.
func _durchlass_optik(s: float, tiefe: float) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Durchlassoptik"
	var mitte := s + tiefe * 0.5
	var lage := Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, mitte)),
			weg_punkt(mitte))
	var holz := Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	var breite := breite_bei(mitte) + 2.0
	_kasten(wurzel, holz, lage, Vector3(breite, 0.45, tiefe), Vector3(0.0, 1.175, 0.0))
	_kasten(wurzel, holz, lage, Vector3(breite, 0.2, tiefe), Vector3(0.0, 4.3, 0.0))
	for k in 6:
		var q := lerpf(-breite * 0.5 + 0.6, breite * 0.5 - 0.6, float(k) / 5.0)
		_kasten(wurzel, holz, lage, Vector3(0.14, 2.8, 0.14), Vector3(q, 2.8, 0.0))
	for seite: float in [-1.0, 1.0]:
		_kasten(wurzel, holz, lage, Vector3(0.3, 5.9, 0.3),
				Vector3(seite * breite * 0.5, 4.4 - 2.95, 0.0))
	return wurzel


func _kasten(eltern: Node3D, stoff: Material, lage: Transform3D, groesse: Vector3,
		versatz: Vector3) -> void:
	var netz := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = groesse
	netz.mesh = form
	netz.material_override = stoff
	netz.transform = lage * Transform3D(Basis(), versatz)
	eltern.add_child(netz)


## Station 30: zählt die Aufrufe aus der Gruppe `LevelBasis.NACH_TOD` und
## schreibt den letzten an – ein Tod muss hier „nach_tod(false)" zeigen,
## ein Game Over „nach_tod(true)".
class Nachtodtafel extends Label3D:
	var anzahl := 0
	var zuletzt := ""

	func nach_tod(von_vorn: bool) -> void:
		anzahl += 1
		zuletzt = "nach_tod(%s)" % str(von_vorn)
		text = "30 nach_tod\n%d× – zuletzt %s" % [anzahl, zuletzt]


## Station 31: die Abschnitte – je Thema einer vor und einer hinter der
## Lücke, mit dem Thema als "stoff" (danach wählt die Decke ihren Stoff).
## Im Wald liegt Kronenlicht auf der Decke.
func _station_31_abschnitte() -> Array:
	var liste: Array = []
	for k in THEMEN_31.size():
		var thema: String = THEMEN_31[k][0]
		var a := M_STATION_31 + THEMA_LAENGE * float(k)
		var b := a + THEMA_LAENGE if k < THEMEN_31.size() - 1 else M_STATION_32
		var licht := 0.5 if thema == "wald" else 0.0
		liste.append({"name": "31 %s A" % thema, "von": a, "bis": a + LUECKE_31.x,
				"breite": WEGBREITE_31, "stoff": thema, "kronenlicht": licht})
		liste.append({"name": "31 %s B" % thema, "von": a + LUECKE_31.y, "bis": b,
				"breite": WEGBREITE_31, "stoff": thema, "kronenlicht": licht})
	return liste


## Station 31: die Bauschritte. Je Thema vier Kanten (rechts, links, die
## Stirn vor und hinter der Lücke) und das Gelände, jeweils mit Bauspeicher;
## davor die Decke samt Grenzen, danach Lippen, Bäche, Nebel und Kronen.
func _station_31_schritte() -> Array:
	_felder_31.clear()
	var schritte: Array = [{"text": "Themenbühne: Wegdecke und Grenzen",
			"tun": _station_31_decke}]
	for k in THEMEN_31.size():
		var thema: String = THEMEN_31[k][0]
		var name: String = THEMEN_31[k][1]
		var a := M_STATION_31 + THEMA_LAENGE * float(k)
		var b := a + THEMA_LAENGE if k < THEMEN_31.size() - 1 else M_STATION_32
		var stoff := Kanten.stoff(_thema_kante(thema))
		var karten := thema != "schnee"
		schritte.append_array(Kanten.seite_schritte(geometrie, _weg_31, 1.0,
				PackedVector2Array([Vector2(a, WEGBREITE_31 * 0.5), Vector2(b, WEGBREITE_31 * 0.5)]),
				_profil_rechts_31.bind(a), stoff, "Kante %s rechts" % name,
				"werkstatt_kante_%s_rechts" % thema,
				{"karten": karten, "saat": 3101 + k}))
		schritte.append_array(Kanten.seite_schritte(geometrie, _weg_31, -1.0,
				PackedVector2Array([Vector2(a, -BOESCHUNG_Q_31), Vector2(b, -BOESCHUNG_Q_31)]),
				_profil_links_31.bind(a), stoff, "Kante %s links" % name,
				"werkstatt_kante_%s_links" % thema))
		# Die Stirnen quer über den Weg: links in die Böschung hinein, rechts
		# bis in den Fels unter der Lippe (dort steht am Rand der Lücke noch
		# die ganze Kante, wie saum.gd:1766-1782). Rechts 0,4 statt 0,55 m
		# vor dem Wegrand: Die Narbe der rechten Kante beginnt 0,45 m hinter
		# ihrer Lippe – mit 0,55 blieb dazwischen ein Streifen von 10 cm ohne
		# Fläche unter der Decke (Lippenprobe), durch den man dort, wo die
		# Decke an der Lippe ausfranst, ins Leere sähe.
		for ende in 2:
			var s := a + (LUECKE_31.x if ende == 0 else LUECKE_31.y)
			var vorwaerts := 1.0 if ende == 0 else -1.0
			var kante := _weg_31.boden_bei(s - 0.01 * vorwaerts)
			schritte.append_array(Kanten.seite_schritte(geometrie, _weg_31, -vorwaerts,
					PackedVector2Array([Vector2(s, -BOESCHUNG_Q_31 - 0.4),
							Vector2(s, WEGBREITE_31 * 0.5 - 0.4)]),
					_profil_stirn_31.bind(kante), stoff,
					"Stirn %s %d" % [name, ende + 1], "werkstatt_stirn_%s_%d" % [thema, ende + 1],
					{"karten": karten, "karten_maske": true, "saat": 3111 + k * 2 + ende,
					"kante": func(_s: float) -> float: return kante}))
		schritte.append_array(GelaendeBau.schritte(geometrie,
				GelaendeBau.schluessel("werkstatt_" + thema), _feld_31.bind(a, b),
				GelaendeBau.stoff(_thema_gelaende(thema)), "Gelände " + name))
	schritte.append({"text": "Themenbühne: Lippen, Bäche, Nebel", "tun": _station_31_wasser})
	return schritte


## Decke (je Thema ein Stoff, eine Kollision), Leitlinie, Schulter und
## Todeszonen der Themenbühne.
func _station_31_decke() -> void:
	_weg_31.decke_bauen(geometrie, func(a: Dictionary) -> Material:
		var thema := String(a.get("stoff", "wald"))
		return Wegdecke.stoff(_thema_weg(thema), _weg_31, _weg_31.abschnitte,
				"werkstatt_" + thema))
	_weg_31.leitlinien_bauen(geometrie)
	_weg_31.schultern_bauen(geometrie)
	_weg_31.todeszonen_bauen(geometrie)


## Rechts: Felskante über dem Abgrund, dazwischen Erdufer über dem Bach
## (gemischt wie in Level 01 an C4); in der Lücke ein Kerbtal.
func _profil_rechts_31(_i: int, probe: Dictionary, a: float) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var kante := _weg_31.boden_bei(s)
	var ov := Kanten.ueberhang_lippe(bogen)
	var u := s - a
	var ufer := smoothstep(UFER_31.x, UFER_31.y, u) * (1.0 - smoothstep(UFER_31.z, UFER_31.w, u))
	var p: GelaendeSaum.Profil
	if ufer <= 0.0:
		p = Kanten.profil_ab(s, bogen, float(probe["q"]), kante, kante + FUSS_31, ov)
	elif ufer >= 1.0:
		p = Kanten.profil_ufer(bogen, kante, kante + UFER_FUSS_31, ov)
	else:
		p = Kanten.profil_ab(s, bogen, float(probe["q"]), kante, kante + FUSS_31, ov).gemischt(
				Kanten.profil_ufer(bogen, kante, kante + UFER_FUSS_31, ov), ufer)
	if _weg_31.ist_luecke(s):
		var mitte := a + (LUECKE_31.x + LUECKE_31.y) * 0.5
		var rand := clampf((absf(s - mitte) - 0.25) / 1.25, 0.0, 1.0)
		Kanten.in_luecke(p, kante + GRUND_31, 0, p.anzahl() - 1, 1.2, rand, true)
	return p


## Links: Böschung bis zur Krone; vor und hinter der Lücke eine Rinne, in
## ihr ein V bis auf den Grund (wie die Kerbe in Level 01).
func _profil_links_31(_i: int, probe: Dictionary, a: float) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var kante := _weg_31.boden_bei(s)
	var krone := kante + KRONE_31 + 0.8 * Kanten.welle(s * 0.04, 41.0)
	var von := a + LUECKE_31.x
	var bis := a + LUECKE_31.y
	var abseits := maxf(von - s, s - bis)
	var rinne := 1.0 - smoothstep(0.0, 2.2, abseits) if abseits > 0.0 else 0.0
	var p := Kanten.profil_boeschung(bogen, absf(float(probe["q"])), kante,
			_weg_31.wegrand(s), krone, rinne)
	if _weg_31.ist_luecke(s):
		var rand := clampf((absf(s - (von + bis) * 0.5) - 0.2) / 1.3, 0.0, 1.0)
		Kanten.in_luecke(p, kante + GRUND_31, 0, p.anzahl() - 1, 2.2, rand)
	return p


## Die Stirn an einer Lippe: Fels bis auf den Grund, die Narbe folgt der
## Wegmaske.
func _profil_stirn_31(_i: int, probe: Dictionary, kante: float) -> GelaendeSaum.Profil:
	var halb := (LUECKE_31.y - LUECKE_31.x) * 0.5
	return Kanten.profil_stirn(probe, kante, kante + GRUND_31, halb, false, 0.45, _weg_31)


## Das Gelände eines Themas (von `a` bis `b`): ein Rechteck über die ganze
## Breite der Bühne zwischen den Z der beiden Enden, zwei Stücke. Die Höhe
## ist EINE Funktion für alle Themen (`_hoehe_31`), so schließen die Felder
## an ihren Grenzen ohne Stufe; nur der Stoff wechselt.
func _feld_31(a: float, b: float) -> GelaendeFeld:
	var z_a := verlauf.sample_baked(a).z
	var z_b := verlauf.sample_baked(b).z
	var feld := GelaendeFeld.new()
	feld.bereich = Rect2(GELAENDE_X_31.x, z_b, GELAENDE_X_31.y - GELAENDE_X_31.x, z_a - z_b)
	feld.stuecke = Vector2i(2, 1)
	feld.hoehe = _hoehe_31
	feld.abstand = func(x: float, z: float) -> float:
		var sq := _sq_31(x, z)
		return clampf(1.0 + (absf(sq.y) - 6.0) * 0.12, 1.0, 4.0)
	feld.faerben = _faerben_31
	feld.zusatz = func(_p: Vector3, _n: Vector3, mulde: float) -> Vector2:
		return Vector2(clampf(1.0 - mulde * 0.25, 0.65, 1.0), 0.0)
	_felder_31.append(feld)
	return feld


## (s, q) eines Weltpunkts zur Kurve der Werkstatt.
func _sq_31(x: float, z: float) -> Vector2:
	var p := Vector3(x, 0.0, z)
	var s := verlauf.get_closest_offset(p)
	var mitte := verlauf.sample_baked(s)
	var rechts := LevelWerkzeuge.richtung(verlauf, s).cross(Vector3.UP).normalized()
	var d := p - mitte
	d.y = 0.0
	return Vector2(s, d.dot(rechts))


## Höhe des Geländes der Themenbühne. Es bleibt UNTER allem, was die Kanten
## zeichnen: rechts unter dem Fuß der Felskante bzw. als Bett des Baches mit
## einem Ufer gegenüber, links unter der Böschung, deren Krone es hinten
## zudeckt; unter der Decke 1,5 m tief, unter der Lücke unter ihrem Grund.
## Vor der Bühne (Station 30) liegt es tief und aus dem Weg.
func _hoehe_31(x: float, z: float) -> float:
	var sq := _sq_31(x, z)
	var s := sq.x
	var q := sq.y
	if s < M_STATION_31 - 0.5:
		return -9.0
	var k := clampi(int(floor((s - M_STATION_31) / THEMA_LAENGE)), 0, THEMEN_31.size() - 1)
	var a := M_STATION_31 + THEMA_LAENGE * float(k)
	var u := s - a
	var rand := WEGBREITE_31 * 0.5
	var y := -1.5
	if q > rand:
		var r := q - rand
		var fels := FUSS_31 - 0.5 if r > 2.8 else FUSS_31 - 3.0
		var ufer := smoothstep(UFER_31.x, UFER_31.y, u) * (1.0 - smoothstep(UFER_31.z, UFER_31.w, u))
		# Bett, gegenüber ein Wiesenufer 1 m unter der Decke, dahinter fällt
		# es wieder auf den Fuß der Felskante ab (sonst stünde es von der
		# Seite gesehen vor dem Weg).
		var bett := -2.4 if r < 1.5 else -2.2
		if r > 8.5:
			bett = lerpf(-2.2, -1.0, smoothstep(8.5, 11.0, r))
		if r > 13.0:
			bett = lerpf(-1.0, fels, smoothstep(13.0, 18.0, r))
		y = lerpf(fels, bett, ufer)
	elif q < -rand:
		var l := -q - rand
		var krone := KRONE_31 + 0.8 * Kanten.welle(s * 0.04, 41.0)
		if l < 8.5:
			y = lerpf(-1.5, krone - 0.6, clampf((l - 0.4) / 8.1, 0.0, 1.0))
		else:
			y = lerpf(krone - 0.6, krone + 1.2, clampf((l - 8.5) / 9.5, 0.0, 1.0)) \
					+ maxf(l - 18.0, 0.0) * 0.05
	# Unter der Lücke und ihren Rinnen: unter dem Grund.
	var luecke := LUECKE_31.x - 1.0 <= u and u <= LUECKE_31.y + 1.0
	if luecke and q < rand + 3.0:
		var grund := GRUND_31 - 0.5 + maxf(-q - rand, 0.0) * 1.6
		y = minf(y, grund)
	return y


## Gewichte der vier Böden (R Wiese, G Waldboden, B Fels, A Schlamm): Fels,
## wo es steil ist, Schlamm am Bach, Waldboden oben auf der Krone, sonst
## Wiese.
func _faerben_31(p: Vector3, n: Vector3) -> Color:
	var fels := 1.0 - smoothstep(0.62, 0.82, n.y)
	var schlamm := (1.0 - smoothstep(-1.1, -0.5, p.y)) * (1.0 - fels)
	var oben := smoothstep(1.4, 2.6, p.y) * (1.0 - fels)
	var wiese := maxf(1.0 - fels - schlamm - oben, 0.0)
	return Color(wiese, oben, fels, schlamm)


## Lippen, Bäche, Nebeltafeln und ferne Kronen der Themenbühne (nach dem
## Gelände: Das Bachband sucht sein Ufer im gezeichneten Feld).
func _station_31_wasser() -> void:
	var umgebung: Environment = null
	var welt := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if welt != null:
		umgebung = welt.environment
	for k in THEMEN_31.size():
		var thema: String = THEMEN_31[k][0]
		var a := M_STATION_31 + THEMA_LAENGE * float(k)
		var lippen := _thema_weg(thema).duplicate()
		lippen["name"] = thema
		lippen["luecken"] = [{"name": "31 " + thema, "von": a + LUECKE_31.x,
				"bis": a + LUECKE_31.y}]
		Wegdecke.lippen(geometrie, _weg_31, lippen)
		# Der Bach im Ufer: Spiegelpunkte alle 2 m, rund an beiden Enden.
		var punkte := PackedVector3Array()
		var breiten := PackedFloat32Array()
		var s := a + UFER_31.y + 0.5
		while s <= a + UFER_31.z + 0.01:
			var p := LevelWerkzeuge.punkt_frei(verlauf, s, BACH_Q_31)
			p.y = _weg_31.boden_bei(s) + SPIEGEL_31
			punkte.append(p)
			breiten.append(BACH_BREITE_31)
			s += 2.0
		var feld := _felder_31[k]
		var bach := Bachband.bauen(geometrie, [{"name": "Bach " + thema, "punkte": punkte,
				"breite": breiten}], Bachband.stoff(_thema_bach(thema)),
				{"hoehe": feld.hoehe_bei})
		bach.name = "Bach " + thema
	# Über dem Sumpf Dunst; die Farbe ist das Nebellicht, etwas heller.
	var a_sumpf := M_STATION_31 + THEMA_LAENGE
	var tafeln: Array = []
	for i in 3:
		var p := LevelWerkzeuge.punkt_frei(verlauf, a_sumpf + 25.0 + 4.0 * float(i),
				BACH_Q_31 + 0.6 * float(i % 2))
		p.y = SPIEGEL_31 + 0.75
		tafeln.append({"mitte": p, "mass": Vector2(6.5, 2.2), "phase": 0.3 * float(i),
				"kraft": 1.0})
	var licht := Color(0.6, 0.66, 0.62)
	if umgebung != null:
		licht = umgebung.fog_light_color.lightened(0.22)
	GelaendeBau.nebeltafeln(geometrie, tafeln, licht)
	# Hinter dem Sumpf ferne Kronen im eigenen, halben Nebel: Sie stehen
	# dunkel vor dem Dunst, statt in ihm zu verschwinden.
	var kronen_stoff := Nebelstoff.nebelarm(Kronenwolke.stoff(Farben.LAUB_DUNKEL, false),
			umgebung)
	for i in 4:
		var krone := Kronenwolke.fern({"radius": 3.2, "saat": 3141 + i})
		var lage := _lage(a_sumpf + 6.0 + 9.0 * float(i), -30.0 - 3.0 * float(i % 2),
				KRONE_31 + 4.0)
		_netz_setzen(krone, kronen_stoff, lage, false, "Ferne Krone %d" % i)


## Thema der Wegdecke (`Wegdecke.stoff`): Wald wie Level 01 (leer), Sumpf
## mit Moorboden, Schnee mit Schnee in der Spur und Firn statt Rasen.
func _thema_weg(thema: String) -> Dictionary:
	match thema:
		"sumpf":
			var moor := Materialbibliothek.moorboden()
			return {"boden_farbe": moor.albedo_texture, "boden_normal": moor.normal_texture,
					"boden_kachel": 0.3, "lippen_korn": moor.albedo_texture,
					"uniforms": {"erde_ton": Color(1.15, 1.1, 0.95)}}
		"schnee":
			var schnee := Materialbibliothek.schnee()
			var firn := Materialbibliothek.firn()
			return {"boden_farbe": schnee.albedo_texture, "boden_normal": schnee.normal_texture,
					"boden_kachel": 0.22, "rasen": firn.albedo_texture, "rasen_kachel": 0.3,
					"lippen_korn": firn.albedo_texture, "lippen_pilze": false,
					"uniforms": {"erde_ton": Color(1.0, 1.0, 1.0)}}
	return {}


## Thema der Kanten (`Kanten.stoff`): Wald wie Level 01, Sumpf mit Moor-
## erde und Algen, Schnee mit Frostgestein, Firn und Schnee statt Moos.
func _thema_kante(thema: String) -> Dictionary:
	match thema:
		"sumpf":
			return {"erde": Materialbibliothek.moorboden().albedo_texture,
					"moos": Materialbibliothek.algen().albedo_texture,
					"uniforms": {"erde_ton": Color(0.7, 0.68, 0.58)}}
		"schnee":
			return {"fels": Materialbibliothek.frostgestein().albedo_texture,
					"kalk": Materialbibliothek.frostgestein().albedo_texture,
					"erde": Materialbibliothek.firn().albedo_texture,
					"moos": Materialbibliothek.schnee().albedo_texture,
					"rasen": Materialbibliothek.firn().albedo_texture, "rasen_kachel": 0.3,
					"uniforms": {"moos_ton": Color(1.5, 1.5, 1.55), "erde_ton": Color(1.0, 1.0, 1.0)}}
	return {}


## Thema des Geländes (`GelaendeBau.stoff`).
func _thema_gelaende(thema: String) -> Dictionary:
	match thema:
		"sumpf":
			var moor := Materialbibliothek.moorboden().albedo_texture
			return {"waldboden": moor, "erde": moor,
					"uniforms": {"waldboden_ton": Color(0.75, 0.8, 0.65)}}
		"schnee":
			var schnee := Materialbibliothek.schnee().albedo_texture
			var firn := Materialbibliothek.firn().albedo_texture
			return {"waldboden": schnee, "fels": Materialbibliothek.frostgestein().albedo_texture,
					"erde": firn, "rasen": firn, "rasen_kachel": 0.3,
					"uniforms": {"waldboden_ton": Color(1.0, 1.0, 1.0),
							"moos_ton": Color(1.0, 1.0, 1.0)}}
	return {}


## Thema des Baches (`Bachband.stoff`): Wald wie Level 01, im Sumpf
## braun-trüb, im Schnee kalt und dunkel.
func _thema_bach(thema: String) -> Dictionary:
	match thema:
		"sumpf":
			return {"farbe_tief": Color(0.08, 0.08, 0.04), "farbe_hell": Color(0.2, 0.18, 0.1),
					"farbe_schaum": Color(0.62, 0.62, 0.5)}
		"schnee":
			return {"farbe_tief": Color(0.04, 0.09, 0.14), "farbe_hell": Color(0.12, 0.22, 0.3),
					"himmel_farbe": Color(0.78, 0.86, 0.94)}
	return {}


## Lage am Weg: Strecke, Querabstand (rechts positiv), Höhe und eine
## Drehung um die Hochachse, ausgerichtet nach der Wegrichtung (+X zeigt
## nach rechts, -Z den Weg entlang).
func _lage(strecke: float, quer: float, hoehe: float = 0.0, dreh: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, strecke) + dreh),
			LevelWerkzeuge.punkt(verlauf, strecke, quer, hoehe))


## Lage für ein Netz, das um seine Mitte gebaut ist: die Unterkante knapp
## über den Weg.
func _auf_boden(netz: Mesh, strecke: float, quer: float) -> Transform3D:
	return _lage(strecke, quer, 0.2 - netz.get_aabb().position.y)


func _netz_setzen(netz: Mesh, stoff: Material, lage: Transform3D, schatten: bool,
		name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = netz
	mi.material_override = stoff
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if schatten \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = lage
	deko.add_child(mi)
	return mi


## Auflagepunkt auf der Wandkrone (wie in Level 01): ein Stück hinter der
## Kante, auf ihrer Oberseite.
func _kronenpunkt(kronen: Array, strecke: float, seite: float) -> Vector3:
	var beste: Dictionary = {}
	var abstand := INF
	for eintrag in kronen:
		var e: Dictionary = eintrag
		if float(e["seite"]) != seite:
			continue
		var d := absf(float(e["s"]) - strecke)
		if d < abstand:
			abstand = d
			beste = e
	if beste.is_empty():
		return LevelWerkzeuge.punkt(verlauf, strecke, seite * 8.0, 8.0)
	return LevelWerkzeuge.punkt(verlauf, strecke,
			seite * (float(beste["innen"]) + 1.0), float(beste["oben"]) + 0.6)


# ======================================================= Station 32

## Laubfarbe der Kronen (wie der nahe Talwald in Level 01).
const LAUB_32 := Color(0.19, 0.41, 0.15)
## Woraus die Haine wachsen (`Baumfabrik.hain`): am Hang Laub- und
## Nadelbäume aus M3 und Birken (M20), auf der Wiese Weiden (M19) und
## Birken. Ohne Modelle der prozedurale Rückfall in derselben Höhe.
const ARTEN_HANG_32 := [
	{"rolle": "M3", "hoehe": 12.0, "unten": 0.36, "gewicht": 2.0},
	{"rolle": "M20", "hoehe": 11.0, "unten": 0.42, "gewicht": 2.0,
			"ton": Color(1.06, 1.08, 0.92)},
	{"rolle": "M3", "nadel": true, "hoehe": 14.0, "unten": 0.14, "gewicht": 1.0},
]
const ARTEN_WIESE_32 := [
	{"rolle": "M19", "hoehe": 9.0, "unten": 0.3, "gewicht": 3.0},
	{"rolle": "M20", "hoehe": 10.0, "unten": 0.45, "gewicht": 1.0},
]
## Tönungen der Haine (wie wald.gd:178-179: neutral, oliv-gelb, blaugrün).
const HAINTOENE_32 := [Color(1.0, 1.0, 1.0), Color(1.0, 0.95, 0.66), Color(0.78, 0.94, 1.0)]

## Füße der gesetzten Bäume (Welt-XZ), damit der Rasen sie ausspart.
var _fuesse_32 := PackedVector2Array()


## Station 32: ein Abschnitt Waldweg, ohne Kronenlicht – mit dem Schatten
## der Kronen (0,5 wie im Wald der Themenbühne) lag die Decke als dunkles
## Band zwischen dem hellen Gelände: Hier steht der Weg im Offenen.
func _station_32_abschnitte() -> Array:
	return [{"name": "32 Bewuchs", "von": M_STATION_32, "bis": M_ENDE,
			"breite": WEGBREITE_32, "stoff": "wald"}]


## Station 32: Decke samt Grenzen und Kisten, das Gelände (Bauspeicher),
## die Haine und der Rasen – in dieser Reihenfolge: Die Kisten stehen vor
## dem Wald, der Wald vor dem Rasen (der seine Stämme ausspart).
func _station_32_schritte() -> Array:
	var schritte: Array = [{"text": "Bewuchs: Wegdecke, Grenzen, Kisten",
			"tun": _station_32_decke}]
	schritte.append_array(GelaendeBau.schritte(geometrie,
			GelaendeBau.schluessel("werkstatt_bewuchs"), _feld_32_anlegen,
			GelaendeBau.stoff({}), "Gelände Bewuchs"))
	schritte.append({"text": "Bewuchs: Haine", "tun": _station_32_haine})
	# Der Rasen in drei Schritten (je Seite einer, dann die Netze): in einem
	# lag er bei gut einer Sekunde.
	schritte.append({"text": "Bewuchs: Rasen links", "tun": _station_32_rasen.bind(-1.0)})
	schritte.append({"text": "Bewuchs: Rasen rechts", "tun": _station_32_rasen.bind(1.0)})
	schritte.append({"text": "Bewuchs: Rasen wird ausgerollt", "tun": _station_32_rasen_fertig})
	return schritte


func _station_32_decke() -> void:
	_weg_32.decke_bauen(geometrie, func(_a: Dictionary) -> Material:
		return Wegdecke.stoff(_thema_weg("wald"), _weg_32, _weg_32.abschnitte,
				"werkstatt_bewuchs"))
	_weg_32.leitlinien_bauen(geometrie)
	_weg_32.schultern_bauen(geometrie)
	for k: Vector2 in KISTEN_32:
		kiste_auf(Kiste.Art.NORMAL, k.x, k.y)


## Das Gelände von Station 32: ein Rechteck um die Kurve (70 m Rand), drei
## mal drei Stücke; an den Wegkanten je eine Punktreihe, damit es dort genau
## an die Decke stößt.
func _feld_32_anlegen() -> GelaendeFeld:
	var a := Vector2(INF, INF)
	var b := Vector2(-INF, -INF)
	var s := M_STATION_32
	while s <= M_ENDE + 4.0:
		var p := verlauf.sample_baked(s)
		a = Vector2(minf(a.x, p.x), minf(a.y, p.z))
		b = Vector2(maxf(b.x, p.x), maxf(b.y, p.z))
		s += 4.0
	# Oben (Z) schließt das Feld bündig an die Themenbühne an.
	var z_oben := verlauf.sample_baked(M_STATION_32).z
	var feld := GelaendeFeld.new()
	feld.bereich = Rect2(a.x - 70.0, a.y - 70.0, b.x - a.x + 140.0, z_oben - (a.y - 70.0))
	feld.stuecke = Vector2i(3, 3)
	feld.hoehe = _hoehe_32
	feld.abstand = func(x: float, z: float) -> float:
		var sq := _sq_31(x, z)
		return clampf(1.0 + (absf(sq.y) - 6.0) * 0.12, 1.0, 4.0)
	feld.faerben = _faerben_32
	# UV2.x Verdeckung: am Wegrand wie der Rand der Decke ab 0,78 (wie
	# gelaende.gd:2082-2087) – ohne lag die Decke als dunkles Band im
	# hellen Gelände.
	feld.zusatz = func(p: Vector3, _n: Vector3, mulde: float) -> Vector2:
		var rand := WEGBREITE_32 * 0.5
		var u := absf(_sq_31(p.x, p.z).y)
		var ao := clampf(1.0 - mulde * 0.25, 0.65, 1.0)
		ao = minf(ao, lerpf(1.0, Wegmaske.RAND_VERDECKUNG, 1.0 - smoothstep(rand, rand + 2.5, u)))
		return Vector2(ao, 0.0)
	for seite: float in [-1.0, 1.0]:
		var linie := PackedVector2Array()
		s = M_STATION_32 + 0.5
		while s <= M_ENDE + 3.0:
			var p := LevelWerkzeuge.punkt_frei(verlauf, s, seite * (WEGBREITE_32 * 0.5 + 0.05))
			linie.append(Vector2(p.x, p.z))
			s += 1.0
		feld.kanten.append({"punkte": linie, "abstand": 1.0, "reihen": PackedFloat32Array([0.0])})
	_feld_32 = feld
	return feld


## Höhe des Geländes von Station 32: unter der Decke knapp darunter, an der
## Wegkante bündig, links ein Hang bis zum Kamm (`HANG_HOCH_32`) mit
## sanften Wellen, rechts eine Wiese mit einer Mulde, weiter draußen leicht
## ansteigend.
func _hoehe_32(x: float, z: float) -> float:
	var sq := _sq_31(x, z)
	var s := sq.x
	var q := sq.y
	var aussen := absf(q) - WEGBREITE_32 * 0.5
	if aussen <= 0.05:
		return -0.06
	var y: float
	if q < 0.0:
		y = lerpf(0.0, HANG_HOCH_32, smoothstep(HANG_AB_32, HANG_KAMM_32, aussen)) \
				+ 0.8 * sin(s * 0.07 + 1.3) * smoothstep(6.0, 20.0, aussen) \
				- maxf(aussen - HANG_KAMM_32, 0.0) * 0.12
	else:
		var mulde_s := smoothstep(MULDE_S_32.x, MULDE_S_32.x + 12.0, s) \
				* (1.0 - smoothstep(MULDE_S_32.y - 12.0, MULDE_S_32.y, s))
		var mulde_q := 1.0 - smoothstep(0.0, 9.0, absf(q - MULDE_Q_32))
		y = 0.25 * sin(s * 0.11) * smoothstep(3.0, 9.0, aussen) \
				- MULDE_TIEF_32 * mulde_s * mulde_q + 2.5 * smoothstep(34.0, 70.0, aussen)
	return lerpf(-0.03, y, smoothstep(0.05, 1.6, aussen))


## Gewichte der Böden (R Wiese, G Waldboden, B Fels, A Schlamm): Fels, wo
## es steil ist, Waldboden oben am Hang, Schlamm in der Mulde.
func _faerben_32(p: Vector3, n: Vector3) -> Color:
	var fels := 1.0 - smoothstep(0.7, 0.86, n.y)
	var wald := smoothstep(1.2, 3.0, p.y) * (1.0 - fels)
	var schlamm := (1.0 - smoothstep(-1.0, -0.6, p.y)) * (1.0 - fels)
	var wiese := maxf(1.0 - fels - wald - schlamm, 0.0)
	return Color(wiese, wald, fels, schlamm)


## Walddichte von Station 32 (0..1): am Hang dicht, auf der Wiese in
## Flecken (für die Hainwahl und den Rasen).
func _wald_32(x: float, z: float) -> float:
	var sq := _sq_31(x, z)
	var aussen := absf(sq.y) - WEGBREITE_32 * 0.5
	if sq.y < 0.0:
		return 0.9 * smoothstep(4.0, 14.0, aussen)
	var flecken := 0.5 + 0.5 * sin(sq.x * 0.075 + 0.6) * cos(sq.y * 0.12)
	return flecken * smoothstep(4.0, 12.0, aussen)


## Die Haine von Station 32 (Muster `L01Wald._talwald_nah`): Hainmitten
## mindestens 18 m auseinander auf einem Raster von 7 m, 9–40 m vom Weg,
## wo `_wald_32` Wald trägt; je Hain 3–7 Bäume. Dazu Waldboden am Fuß der
## Bäume (M21 Felsen, M23 Treibholz und Stumpf), Sträucher am Rand der
## Haine (M24), Totholz auf der Wiese (M22) und ferne Kronen auf dem Kamm,
## die nach der Himmelsprobe einsinken. Alle Regeln aus dem `Waldrahmen`:
## Freiraum über dem Weg, ein Sichtkegel zum Zielportal, Kisten frei, die
## Lichtung rechts gesperrt.
func _station_32_haine() -> void:
	var kamera := get_node_or_null("CorridorCamera") as KorridorKamera
	_rahmen_32 = Waldrahmen.new(weg, kamera, kisten_orte(),
			{"von": M_STATION_32 - 6.0, "bis": M_ENDE + 4.0})
	var rahmen := _rahmen_32
	rahmen.sperren.append(LICHTUNG_32)
	rahmen.kegel_entlang(M_STATION_32 + 4.0, M_ENDE - 34.0, 4.0,
			weg_punkt(M_ENDE - 4.0, 0.0, 2.0), 4.0, 10.0)
	var hoehe := _feld_32.hoehe_bei
	var modelle := not Fremdmodelle.rolle("M3").is_empty()
	var ws := Waldsetzer.new(deko, "Bewuchs 32", 48.0)
	ws.art("stamm", {"stoff": Baumfabrik.borke_welt() if modelle else Riesenstamm.borkenstoff(),
			"sicht": 90.0, "verschmelzen": true})
	ws.art("krone", {"stoff": Kronenwolke.stoff(LAUB_32), "sicht": 90.0,
			"verschmelzen": true, "karten": true})
	ws.art("fern", {"stoff": Kronenwolke.stoff(LAUB_32, false), "sicht_von": 90.0,
			"sicht": 200.0, "verschmelzen": true, "rand": 8.0})
	var umgebung: Environment = null
	var welt := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if welt != null:
		umgebung = welt.environment
	ws.art("fernwald", {"stoff": Nebelstoff.nebelarm(Kronenwolke.stoff(Farben.LAUB_DUNKEL, false),
			umgebung), "sicht": 220.0, "verschmelzen": true, "rand": 10.0})
	var boden_modelle: Array[Dictionary] = []
	boden_modelle.append_array(Fremdmodelle.rolle_netze("M21", {}, 20.0))
	boden_modelle.append_array(Fremdmodelle.rolle_netze("M23", {}, 20.0))
	var boden_arten: Array = []
	for k in boden_modelle.size():
		boden_arten.append(ws.fremd("boden%d" % k, boden_modelle[k],
				{"sicht": 70.0, "schatten": false, "zelle": 96.0}))
	var straeucher := Fremdmodelle.rolle_netze("M24", {}, 20.0)
	var strauch_arten: Array = []
	for k in straeucher.size():
		strauch_arten.append(ws.fremd("strauch%d" % k, straeucher[k],
				{"sicht": 70.0, "schatten": false, "zelle": 96.0}))
	var rng := PropWerkzeug.zufall(3201)
	var busch := Baumfabrik.indiziert(Kronenwolke.netz({"radius": 1.9, "hoehe": 2.6,
			"variante": 1, "karten": 18, "ballen": 3, "saat": 8301}))
	var bereich := _feld_32.bereich
	var mitten: Array[Vector2] = []
	_fuesse_32 = PackedVector2Array()
	var x := bereich.position.x
	while x < bereich.end.x:
		var z := bereich.position.y
		while z < bereich.end.y:
			var mitte := Vector2(x + rng.randf_range(0.0, 7.0), z + rng.randf_range(0.0, 7.0))
			z += 7.0
			var d := rahmen.wegabstand(mitte.x, mitte.y)
			if d > 40.0 or d < 9.0:
				continue
			var sq := _sq_31(mitte.x, mitte.y)
			if sq.x < M_STATION_32 + 2.0 or sq.x > M_ENDE - 2.0:
				continue
			var w := _wald_32(mitte.x, mitte.y)
			if w < 0.3:
				continue
			var frei := true
			for m in mitten:
				if m.distance_squared_to(mitte) < 18.0 * 18.0:
					frei = false
					break
			if not frei:
				continue
			mitten.append(mitte)
			var dicht := smoothstep(0.3, 0.9, w)
			var arten: Array = ARTEN_HANG_32 if sq.y < 0.0 else ARTEN_WIESE_32
			_fuesse_32.append_array(Baumfabrik.hain(ws, rahmen, rng, mitte, arten, {
				"hoehe": hoehe, "busch": busch, "nah": 6.0, "weit": 44.0,
				"anzahl": roundi(lerpf(3.0, 7.0, dicht) * rng.randf_range(0.8, 1.15)),
				"weite": lerpf(4.5, 8.5, dicht),
				"ton": HAINTOENE_32[rng.randi_range(0, HAINTOENE_32.size() - 1)]}))
			if not straeucher.is_empty():
				_straeucher_32(ws, rng, mitte, lerpf(4.5, 8.5, dicht), straeucher, strauch_arten)
		x += 7.0
	rahmen.zaehle("haine", mitten.size())
	for p in _fuesse_32:
		if Baumfabrik.streu(p, 37) < 0.4:
			Baumfabrik.bodenstueck(ws, rahmen, p, boden_modelle, boden_arten, hoehe, 6.0, 44.0)
	_totholz_32(ws, rng)
	_fernwald_32(ws, rng)
	var zz := ws.fertig()
	rahmen.zaehle("knoten", int(zz["knoten"]))
	rahmen.zaehle("dreiecke", int(zz["dreiecke"]))
	if debug:
		print("Bewuchs 32: ", rahmen.zahlen)


## Ein, zwei Sträucher (M24) am Rand eines Hains, nicht im Freiraum über
## dem Weg und nicht an einem Stamm.
func _straeucher_32(ws: Waldsetzer, rng: RandomNumberGenerator, mitte: Vector2, weite: float,
		modelle: Array[Dictionary], arten: Array) -> void:
	var rahmen := _rahmen_32
	for i in rng.randi_range(1, 2):
		var w := rng.randf() * TAU
		var ort := mitte + Vector2(cos(w), sin(w)) * (weite + rng.randf_range(1.5, 3.5))
		if not rahmen.platz(ort, 6.5, 44.0) or not rahmen.staemme.frei(ort, 1.2):
			continue
		var y := _feld_32.hoehe_bei(ort.x, ort.y)
		if is_nan(y):
			continue
		var k := rng.randi_range(0, modelle.size() - 1)
		var modell: Dictionary = modelle[k]
		var gross := rng.randf_range(0.8, 1.3)
		var lage := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * gross),
				Vector3(ort.x, y - 0.05, ort.y))
		if not rahmen.weg_frei(lage * (modell["huelle"] as AABB)):
			continue
		var namen: Array[String] = []
		namen.assign(arten[k])
		ws.setze_fremd(namen, modell, lage, Baumfabrik.ton(rng, Vector2(0.82, 1.0), 0.04))
		rahmen.staemme.dazu(ort, 1.2)
		rahmen.zaehle("straeucher")


## Totholz auf der Wiese (M22, ohne Modelle der Rückfall aus wald.gd:2154):
## höchstens fünf Stämme 12–40 m vom Weg, wo kaum Wald steht.
func _totholz_32(ws: Waldsetzer, rng: RandomNumberGenerator) -> void:
	var tot: Array[ArrayMesh] = []
	var namen := Fremdmodelle.rolle("M22")
	for k in namen.size():
		var m := Fremdmodelle.baum(namen[k], {"hoehe": 8.0 - 1.5 * float(k % 2), "moos": 0.3})
		if not m.is_empty():
			tot.append(m["stamm"])
	if tot.is_empty():
		tot = [Riesenstamm.netz({"hoehe": 11.0, "radius": 0.42, "oben": "bruch", "aeste": 3,
					"ast_start": 0.45, "ast_laenge": 3.0, "moos": 0.35, "saat": 8201})]
	var bereich := _feld_32.bereich
	var gesetzt := 0
	for versuch in 300:
		if gesetzt >= 5:
			break
		var p := Vector2(rng.randf_range(bereich.position.x, bereich.end.x),
				rng.randf_range(bereich.position.y, bereich.end.y))
		var sq := _sq_31(p.x, p.y)
		if sq.y <= 0.0 or sq.x < M_STATION_32 + 4.0 or sq.x > M_ENDE - 4.0:
			continue
		if not _rahmen_32.platz(p, 12.0, 40.0) or _wald_32(p.x, p.y) > 0.4:
			continue
		var y := _feld_32.hoehe_bei(p.x, p.y)
		if is_nan(y):
			continue
		var vorher := int(_rahmen_32.zahlen.get("totholz", 0))
		Baumfabrik.totholz(ws, _rahmen_32, tot, Vector3(p.x, y, p.y), rng)
		if int(_rahmen_32.zahlen.get("totholz", 0)) > vorher:
			gesetzt += 1


## Ferne Kronen auf dem Hangkamm (links, q −58 … −44): `Baumfabrik.fernbaum`,
## jede nach der Himmelsprobe des Rahmens eingesunken (ein Waldsaum auf dem
## Kamm statt Scheiben vor dem Himmel) oder weggelassen.
func _fernwald_32(ws: Waldsetzer, rng: RandomNumberGenerator) -> void:
	var rahmen := _rahmen_32
	var hoehe := _feld_32.hoehe_bei
	var s := M_STATION_32 + 4.0
	while s < M_ENDE - 4.0:
		var p := LevelWerkzeuge.punkt_frei(verlauf, s + rng.randf_range(-2.0, 2.0),
				rng.randf_range(FERNE_Q_32.x, FERNE_Q_32.y))
		s += FERNE_SCHRITT_32
		var y: float = hoehe.call(p.x, p.z)
		if is_nan(y):
			continue
		var k := rng.randi_range(0, 2)
		var netz: ArrayMesh = Baumfabrik.vorrat(rahmen, "fern%d" % k,
				func() -> ArrayMesh: return Baumfabrik.fernbaum(k))
		var groesse := rng.randf_range(0.85, 1.25)
		var tief := rahmen.einsinken(Vector3(p.x, y, p.z), netz.get_aabb().end.y * groesse, hoehe)
		if tief < 0.0:
			rahmen.zaehle("fern_ballon")
			continue
		if tief > 0.0:
			rahmen.zaehle("fern_gesunken")
		var ton := Baumfabrik.ton(rng, Vector2(0.85, 1.0), 0.04)
		if k == 2:
			ton = ton * Baumfabrik.NADEL_TON
		ws.setze("fernwald", netz, Baumfabrik.lage(Vector3(p.x, y - tief, p.z), rng.randf() * TAU,
				groesse, groesse), ton)
		rahmen.zaehle("fern")


## Rasen, Streu und Rahmenfarne von Station 32 (`Rasenbau`) auf einer
## Seite: auf der Decke nach der Wegmaske, links bis 14 m auf den Hang,
## rechts bis 18 m über die Wiese; Stämme und Kisten bleiben frei. Der
## erste Aufruf legt den Bau an.
func _station_32_rasen(seite: float) -> void:
	if _rasen_32 == null:
		var kamera := get_node_or_null("CorridorCamera") as KorridorKamera
		_rasen_32 = Rasenbau.new(deko, weg, _feld_32.hoehe_bei, {
			"kisten": kisten_orte(), "kamera": kamera, "wald": _wald_32, "saat": 3202,
			"name": "Rasen 32",
			"kronenlicht": func(s: float) -> float:
				return Wegdecke.kronenlicht_bei(_weg_32.abschnitte, s),
		})
		for p in _fuesse_32:
			var sq := _rasen_32.strecke_quer(Vector3(p.x, 0.0, p.y))
			_rasen_32.kreis(sq.x, sq.y, 0.7)
	var rasen := _rasen_32
	rasen.decke(M_STATION_32, M_ENDE, seite)
	rasen.boden(M_STATION_32, M_ENDE, seite, WEGBREITE_32 * 0.5, 14.0 if seite < 0.0 else 18.0,
			Rasenbau.DICHTE_SCHULTER,
			Rasenbau.Bereich.SCHULTER if seite < 0.0 else Rasenbau.Bereich.WIESE)
	rasen.rahmenfarne(M_STATION_32 + 2.0, M_ENDE - 6.0, seite, null, 6.4, 8.0)
	if seite > 0.0:
		# Blütengruppen an der rechten Wegkante, gesetzt statt gewürfelt.
		for i in 10:
			rasen.streu(M_STATION_32 + 6.0 + 11.0 * float(i), 5.6 + 1.2 * float(i % 3), "bluete")
	else:
		# Pilze an den Füßen der Hangbäume.
		for p in _fuesse_32:
			var sq := rasen.strecke_quer(Vector3(p.x, 0.0, p.y))
			if sq.y < 0.0 and sq.y > -16.0:
				rasen.streu(sq.x + 0.9, sq.y + 0.6, "pilz", 1.1)


## Die Netze des Rasens; danach sind Rasen und Waldrahmen fertig.
func _station_32_rasen_fertig() -> void:
	if _rasen_32 != null:
		_rasen_32.fertig()
	_rasen_32 = null
	_rahmen_32 = null


# ======================================================= Probenhaken

## Die Sprungfälle der Werkstatt (Paket G2): jede Art der Sprungprobe
## einmal, an der Sprungbahn von Station 30 und an alten Stationen. Die
## ersten drei Fälle sind die Abnahme des Pakets; ihre Sollwerte stehen
## in den Entwürfen (gemessen bzw. gerechnet mit 0,05 m Raster, daher hier
## dasselbe Raster):
##   Einfach 3,0  Fenster 1,95 ± 0,25 m (Messbank L05 §2.3: −1,80 … +0,15)
##   Doppel 5,0   Fenster ≥ 1,30 m bei Doppelsprung nach 0,20 s (L02 §2;
##                0,25 s: 1,75, 0,33 s: 2,35)
##   Duck 1,6     sauber ≥ 3,0 m (Messbank: −3,9 … −0,5 = 3,4 m)
## Die übrigen zeigen jede weitere Art einmal in Gebrauch: Einzelsprung
## über 5,0 darf nicht tragen (Wehr L05, P1/P3 L02), der Slide-Sprung
## darüber ist Kür (Messbank 0,80 m), Slide und Doppelsprung zusammen,
## Hürde ≥ 1,5 m (Entwurf L05, Paket P1), Überlauf über die Bruchplatten
## (Station 1), Landung auf dem Fließband (Station 7) mit zehn Bildern Halt.
## Das Fließband liegt auf festem Boden: Der Fall zeigt nur, dass `bewegt`
## läuft. Einen bewegten Träger über einer echten Lücke misst erst das Floß
## im Paket von Level 03.
## Die Fälle laufen in `pruefe.sh` mit (Stufe 4, voller Lauf).
func sprungfaelle() -> Array[Dictionary]:
	var drei := LUECKE_3_VON
	var fuenf := LUECKE_5_VON
	var landung_drei := LUECKE_3_BIS - LANDUNG_SPIEL
	var landung_fuenf := LUECKE_5_BIS - LANDUNG_SPIEL
	return [
		{"name": "Einfach 3,0", "art": "einfach", "start": Vector2(drei - 5.0, 0.0),
				"kante": drei, "von": drei - 3.0, "landung": landung_drei,
				"schritt": 0.05, "fenster_min": 1.7},
		{"name": "Doppel 5,0", "art": "doppel", "start": Vector2(fuenf - 5.5, 0.0),
				"kante": fuenf, "von": fuenf - 3.5, "landung": landung_fuenf,
				"schritt": 0.05, "fenster_min": 1.3},
		{"name": "Duck 1,6", "art": "duck", "start": Vector2(DURCHLASS_30 - 9.0, 0.0),
				"kante": DURCHLASS_30, "von": DURCHLASS_30 - 6.5,
				"landung": DURCHLASS_30 + DURCHLASS_30_TIEFE + 1.0,
				"schritt": 0.05, "fenster_min": 3.0},
		{"name": "Einfach 5,0", "art": "einfach", "start": Vector2(fuenf - 5.5, 0.0),
				"kante": fuenf, "von": fuenf - 2.0, "landung": landung_fuenf,
				"darf_nicht_tragen": true},
		{"name": "Slide-Sprung 5,0", "art": "slide", "start": Vector2(fuenf - 5.5, 0.0),
				"kante": fuenf, "von": fuenf - 2.0, "landung": landung_fuenf,
				"schritt": 0.05, "pflicht": false},
		{"name": "Slide-Doppel 5,0", "art": "slide_doppel", "start": Vector2(fuenf - 5.5, 0.0),
				"kante": fuenf, "von": fuenf - 2.0, "landung": landung_fuenf,
				"doppel_t": [0.25]},
		{"name": "Hürde 0,7", "art": "huerde", "start": Vector2(HUERDE_30 - 5.5, 0.0),
				"kante": HUERDE_30, "von": HUERDE_30 - 4.0,
				"landung": HUERDE_30 + HUERDE_ZONE_TIEF + 2.0,
				"schritt": 0.05, "fenster_min": 1.5},
		{"name": "Bruchplatten", "art": "ueberlauf", "start": Vector2(18.0, 0.0),
				"bis": 36.0},
		{"name": "Fliessband", "art": "bewegt", "start": Vector2(111.5, 0.0),
				"kante": 116.0, "von": 114.0, "landung": 118.3},
	]


## Fotos (werkzeuge/foto.gd): die Figur auf die Wegdecke, nicht 1 m über
## die Kurve.
func foto_stelle(s: float, q: float) -> Vector3:
	return weg_punkt(s, q)


func _portale() -> void:
	portale_setzen(1.0, 4.0)


## Nummernschilder an jeder Station.
##
## Ohne sie ist auf einem Bild nicht zu sagen, welches Bauteil man gerade
## sieht – und genau das ist der Zweck dieses Levels.
func _schilder_setzen() -> void:
	var stationen := {
		30.0: "1 Bruchplatte", 47.0: "2 Taktwelle", 65.0: "3 Feuerspeier",
		78.0: "4 Laserzaun", 93.0: "5 Rollbrocken", 108.0: "6 Drehscheibe",
		123.0: "7 Fliessband", 136.0: "8 Schiebeblock",
		148.0: "9 Platte + Tor", 158.0: "10 Wehrbohle",
		166.0: "11 Werfer", 176.0: "12 Schwarm + Deckung",
		188.0: "13 Hangelgitter",
		216.0: "14 Schluchtsaum", 224.0: "15 Wasserfall",
		234.0: "16 Lichtschacht", 244.0: "17 Wurzeltor",
		254.0: "18 Baumstamm", 276.0: "19 Blaetterdach",
		298.0: "20 Riesenstamm", 312.0: "21 Kronenwolke", 326.0: "22 Findling",
		338.0: "23 Farnwerk", 350.0: "24 Rasensaum", 362.0: "25 Bodenstreu",
		374.0: "26 Totholzzaun", 388.0: "27 GelaendeSaum",
		402.0: "28 Waldsetzer", 432.0: "29 Weltenbaum (1:8)",
		452.0: "30 Unterbau (Wegdaten)", SCHILD_SPRUNGBAHN: "30 Sprungbahn",
		# Am Anfang jedes Themas: So steht das Schild schon hinter der
		# Verfolgerkamera, wenn die Figur an die Lücke kommt.
		M_STATION_31 + 0.3: "31 Themenbühne: Wald",
		M_STATION_31 + THEMA_LAENGE + 0.3: "31 Sumpf",
		M_STATION_31 + THEMA_LAENGE * 2.0 + 0.3: "31 Schnee",
		M_STATION_32 + 0.3: "32 Bewuchs (Waldrahmen, Rasenbau)",
	}
	for strecke: float in stationen:
		var quer := -WEGBREITE * 0.5 + 0.8
		if strecke == SCHILD_SPRUNGBAHN:
			quer = -quer
		var schild := Label3D.new()
		schild.text = String(stationen[strecke])
		schild.font_size = 96
		schild.pixel_size = 0.012
		schild.modulate = Color(1.0, 0.94, 0.7)
		schild.outline_size = 24
		schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		schild.no_depth_test = true
		schild.position = LevelWerkzeuge.punkt(verlauf, strecke, quer, 3.4)
		deko.add_child(schild)
