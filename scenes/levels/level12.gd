extends KorridorLevel
## Level 12 – "Kesselwerk"
##
## Die Maschinenräume unter einer Burg. Der Boden ist hier zum ersten Mal
## kein Verlass: Er fährt, dreht sich, hebt sich oder ist gar nicht da.
## Jeder Abschnitt nimmt sich eine Art von bewegtem Boden vor und fragt
## nach ihr allein.
##
##     0 –  42  Torhalle       weit · ein zweiter Weg führt nach OBEN
##    42 – 100  Bänderschacht  Fließbänder über zwei Abgründen,
##                             dazu eines gegen die Laufrichtung
##   100 – 148  Kolbenwerk     38 m ohne Boden, nur tauchende Bohlen
##   148 – 198  Drehsaal       eine Kette von Drehscheiben über dem Schacht
##   198 – 248  Ofengang       eng, heiß · Feuerspeier und der Ofen
##   248 – 298  Zahnradsteig   drei Ebenen übereinander · SEITENANSICHT
##   298 – 336  Kesselhalle    Schließtore im Takt, Blöcke schieben
##
## Warum die Reihenfolge so ist: Erst ein Boden, der trägt und schiebt
## (Band), dann einer, der verschwindet und wiederkommt (Kolben), dann
## einer, der sich unter den Füßen dreht (Scheibe). Jede Stufe nimmt die
## vorige als bekannt an.
##
## Farbe: kaltes blaugraues Mauerwerk gegen rostroten Stahl. Die einzige
## warme Lichtquelle ist der Ofen bei 222 m – deshalb hat das Level auch
## keine Sonne, die etwas ausrichtet, sondern lebt von Punktlicht und
## Nebel. Gelbe Seilzüge ziehen die Linien durch die Hallen.
##
## Die Kulisse arbeitet: In den Wänden drehen sich Zahnräder hinter
## Gittern, die niemand berührt. Sie sind der Grund, warum das Werk wie
## ein Ort wirkt und nicht wie eine Sammlung von Fallen.

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --- Farben, die die Bibliothek nicht führt ---
## Kaltes Mauerwerk – der Grundton des ganzen Levels.
const MAUER_TIEF := Color(0.14, 0.18, 0.22)
const MAUER_HELL := Color(0.38, 0.45, 0.51)
## Rostroter Stahl: die warme Gegenfarbe, aber nie als Licht.
const ROSTSTAHL := Color(0.55, 0.24, 0.14)
## Seilzüge. Sie leuchten schwach, damit sie im Dunst die Linie halten.
const SEIL_GELB := Color(0.86, 0.74, 0.24)
## Ofenglut – die einzige warme Lichtquelle im Bild.
const GLUT_TIEF := Color(1.0, 0.42, 0.08)
const GLUT_HELL := Color(1.0, 0.78, 0.34)

# --- Strecken-Marken ---
const M_TORHALLE := 0.0
const M_BAENDER := 42.0
const M_KOLBEN := 100.0
const M_DREHSAAL := 148.0
const M_OFENGANG := 198.0
const M_ZAHNRADSTEIG := 248.0
const M_KESSELHALLE := 298.0
const M_ENDE := 336.0

# --- Höhen ---
const ABSTURZ := -4.6
## Oberer und unterer Stand der Kolben.
const KOLBEN_OBEN := 0.0
const KOLBEN_UNTEN := -2.9
## Höhe, in der ein Balken das Gehen sperrt, das Krabbeln aber nicht.
const KRIECHHOEHE := 0.95


## Der Weg. Zwischen den Abschnitten liegen vier Lücken: zwei kurze im
## Bänderschacht, eine lange im Kolbenwerk, eine im Drehsaal.
const STRECKE := [
	# --- Torhalle ---
	{"von": 0.0, "bis": 42.0, "breite": 15.0, "breite_ende": 9.0},
	# --- Bänderschacht: Podeste, dazwischen tragen die Bänder ---
	{"von": 42.0, "bis": 54.0, "breite": 9.0},
	{"von": 64.0, "bis": 72.0, "breite": 9.0},
	{"von": 82.0, "bis": 98.0, "breite": 9.0},
	{"von": 98.0, "bis": 100.0, "breite": 9.0, "breite_ende": 8.0},
	# --- Kolbenwerk: 104 bis 142 gibt es keinen Boden ---
	{"von": 100.0, "bis": 104.0, "breite": 8.0},
	{"von": 142.0, "bis": 146.0, "breite": 8.0},
	{"von": 146.0, "bis": 148.0, "breite": 8.0, "breite_ende": 11.0},
	# --- Drehsaal: 160 bis 186 tragen nur die Scheiben ---
	{"von": 148.0, "bis": 160.0, "breite": 11.0},
	{"von": 186.0, "bis": 194.0, "breite": 11.0},
	{"von": 194.0, "bis": 198.0, "breite": 11.0, "breite_ende": 6.5},
	# --- Ofengang: der engste Abschnitt, dafür durchgehend fest ---
	{"von": 198.0, "bis": 244.0, "breite": 6.5},
	{"von": 244.0, "bis": 248.0, "breite": 6.5, "breite_ende": 9.0},
	# --- Zahnradsteig: unten fest, die Aufgabe liegt darüber ---
	{"von": 248.0, "bis": 294.0, "breite": 9.0},
	{"von": 294.0, "bis": 298.0, "breite": 9.0, "breite_ende": 12.0},
	# --- Kesselhalle ---
	{"von": 298.0, "bis": 336.0, "breite": 12.0, "breite_ende": 16.0},
]

## Die Mauern ringsum. Sie tragen keine Kollision – dafür steht die
## Leitwand dahinter.
##
## Über den Schächten stehen sie WEITER auseinander als anderswo. Der
## erste Entwurf setzte sie dort auf sieben Meter, also drei Meter neben
## den Weg; ihre beleuchteten Innenflächen liefen aus der Spielkamera
## perspektivisch zusammen und lasen sich als Boden dicht unter den
## Kolben. Ein Abgrund, der wie ein Absatz aussieht, ist keiner.
const WAENDE := [
	{"von": -6.0, "bis": 42.0, "abstand": 10.5, "hoehe": 15.0},
	{"von": 42.0, "bis": 100.0, "abstand": 9.5, "hoehe": 12.0},
	{"von": 100.0, "bis": 148.0, "abstand": 10.5, "hoehe": 13.0},
	{"von": 148.0, "bis": 198.0, "abstand": 9.0, "hoehe": 14.0},
	{"von": 198.0, "bis": 248.0, "abstand": 5.5, "hoehe": 10.0},
	{"von": 248.0, "bis": 298.0, "abstand": 8.0, "hoehe": 17.0},
	{"von": 298.0, "bis": 342.0, "abstand": 11.5, "hoehe": 19.0},
]

var _mauer_stoff: StandardMaterial3D


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Das Werk wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Mauerwerk", "tun": _waende_bauen},
		{"text": "Eiserne Böden", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Torhalle", "tun": _torhalle_bauen},
		{"text": "Der Weg nach oben", "tun": _geheimweg_bauen},
		{"text": "Bänderschacht", "tun": _baender_bauen},
		{"text": "Kolbenwerk", "tun": _kolben_bauen},
		{"text": "Drehsaal", "tun": _drehsaal_bauen},
		{"text": "Ofengang", "tun": _ofengang_bauen},
		{"text": "Der Ofen wird angeheizt", "tun": _ofen_bauen},
		{"text": "Zahnradsteig", "tun": _zahnradsteig_bauen},
		{"text": "Kesselhalle", "tun": _kesselhalle_bauen},
		{"text": "Maschinen hinter Gittern", "tun": _maschinenwand_bauen},
		{"text": "Seilzüge", "tun": _seilzuege_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Dunst und Punktlicht", "tun": _stimmungen_setzen},
		{"text": "Schutt und Bewuchs", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Material

## Kaltes, blaugraues Mauerwerk.
##
## Es wird hier gebaut und nicht aus der Materialbibliothek geholt: Deren
## Materialien liegen im gemeinsamen Zwischenlager – sie nachträglich
## einzufärben würde jedes andere Level mitverändern.
func _mauer_material() -> StandardMaterial3D:
	if _mauer_stoff != null:
		return _mauer_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1201, 0.016,
			MAUER_TIEF, MAUER_HELL, 256)
	m.normal_enabled = true
	m.normal_texture = Materialbibliothek.normalmap(1202, 0.05, 2.0)
	m.normal_scale = 0.9
	# Dreiseitige Projektion: Die Wand- und Wegnetze tragen keine eigenen
	# UVs, ohne sie stünde die Zeichnung an senkrechten Flächen still.
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)
	m.roughness = 0.9
	_mauer_stoff = m
	return _mauer_stoff


# =========================================================== Verlauf

## Eine lange Schleife durch den Berg. Sie steigt stetig, aber flach – das
## Werk arbeitet sich nach oben, ohne dass ein einzelner Abschnitt zur
## Kletterei wird. Nur der Bänderschacht und der Zahnradsteig laufen
## nahezu gerade: Ein Fließband ist ein starres Rechteck und folgt keiner
## Kurve, und in der Seitenansicht würde eine Biegung das Bild schwenken.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0.0, 10),
		Vector3(0, 0.0, -14),
		Vector3(2, 0.3, -38),        # Bänderschacht
		Vector3(12, 0.6, -60),
		Vector3(30, 0.8, -76),
		Vector3(52, 1.0, -84),       # Kolbenwerk
		Vector3(76, 1.2, -84),
		Vector3(98, 1.4, -76),       # Drehsaal
		Vector3(116, 1.8, -62),
		Vector3(128, 2.4, -42),      # Ofengang
		Vector3(134, 3.0, -20),
		Vector3(134, 3.6, 4),
		Vector3(128, 4.2, 28),       # Zahnradsteig
		Vector3(114, 4.6, 48),
		Vector3(96, 4.8, 62),        # Kesselhalle
		Vector3(74, 4.8, 70),
	])


# =========================================================== Grund

## Der Boden ist überall Eisen, die Kanten sind rostig, und was nach unten
## abbricht, ist Mauerwerk. Damit stimmt der Warm-kalt-Kontrast schon im
## Weg selbst, bevor irgendein Bauteil daraufsteht.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.metall(Color(0.60, 0.63, 0.68)),
		"kante": Materialbibliothek.metall(ROSTSTAHL),
		"klippe": _mauer_material(),
	}, {"tiefe": 12.0, "schritt": 1.0, "kante_hoehe": 0.26, "kante_breite": 0.65})
	luecken_markieren(ROSTSTAHL)


func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			_mauer_material(), {
		"schritt": 2.6, "lagen": 5, "block": 3.0,
		"sockel": 14.0, "saat": 1204,
		"adermaterial": Materialbibliothek.metall(ROSTSTAHL),
		"deckmaterial": Materialbibliothek.frostgestein(),
		"aderdichte": 0.22,
	})
	# Die Sichtwand ist ein Dreiecksnetz und taugt nicht als Begrenzung –
	# an ihren Zacken bliebe man hängen. Dahinter läuft eine glatte Wand.
	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), w["abstand"] - 0.6, 6.0)


## Die Schächte bekommen mit Absicht KEINEN Boden.
##
## Der erste Entwurf legte in jeden Schacht eine Fläche zehn Meter unter
## dem Weg. Sie sollte Tiefe zeigen und tat das Gegenteil: Im Dunst nahm
## sie dessen helle Farbe an, lag waagerecht unter den Kolben und sah aus
## wie ein Boden, auf dem ein Fehltritt glimpflich ausgeht. Jetzt reicht
## die unterste Blocklage der Mauern vierzehn Meter hinab, und darunter
## ist nichts – ein Schacht ohne sichtbares Ende.


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


# =========================================================== Abschnitte

## 0–42 · Torhalle. Frage: Wohin führt der Weg, der nicht nach vorn führt?
##
## Weit, hell für dieses Level, ohne bewegten Boden. Die einzige Aufgabe
## ist zu bemerken, dass es hier zwei Wege gibt – der eine liegt vor einem,
## der andere über einem.
func _torhalle_bauen() -> void:
	# Zwei Blöcke, die quer über den Hallenboden fahren: eine erste
	# Kostprobe davon, dass hier alles in Bewegung ist.
	schiebeblock(20.0, -2.6, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.8, 1.2)
	schiebeblock(30.0, 2.6, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.8, 1.2,
			0.5)
	# Ein Balken über dem Ausgang: Wer hinaus will, krabbelt.
	stachelbalken(38.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


## Der Geheimweg gleich am Anfang.
##
## Eine Sprungfeder am Hallenrand, darüber vier Absätze und eine Empore.
## Oben liegen KEINE Kisten, sondern Extraleben – eine Bonusrunde belohnt
## das Hinsehen, sie soll nicht in den Kistenzähler eingreifen. Wer
## danebenspringt, landet auf dem Hallenboden und kann es noch einmal
## versuchen; darunter liegt kein Abgrund.
func _geheimweg_bauen() -> void:
	var stoff := _mauer_material()
	kiste(Kiste.Art.SPRUNG, 8.0, 4.2)
	plattform(12.0, 5.6, 4.4, Vector3(3.0, 0.5, 3.0), stoff)
	plattform(16.0, 6.4, 5.8, Vector3(3.0, 0.5, 3.0), stoff)
	plattform(20.0, 6.8, 7.2, Vector3(3.0, 0.5, 3.0), stoff)
	plattform(24.5, 6.8, 8.4, Vector3(6.0, 0.6, 5.0), stoff)
	kiste(Kiste.Art.LEBEN, 23.5, 6.8, 9.0)
	kiste(Kiste.Art.LEBEN, 25.5, 6.8, 9.0)
	frucht(12.0, 5.6, 5.4)
	frucht(16.0, 6.4, 6.8)
	frucht(20.0, 6.8, 8.2)
	fruechte_reihe(22.5, 26.5, 5, 6.8, 9.6)


## 42–100 · Bänderschacht. Frage: Bin ich schneller als der Boden?
##
## Zwei Bänder tragen über je zehn Meter Abgrund; sie sind die Brücke, und
## man muss sie nehmen. Das dritte Band liegt auf festem Grund und läuft
## GEGEN die Laufrichtung – die einzige Stelle des Levels, an der Stehen
## bleiben Rückschritt bedeutet.
##
## Warum das Gegenband nicht über dem Abgrund liegt: Ein Boden, der einen
## rückwärts in ein Loch schiebt, ist keine Aufgabe, sondern eine Strafe.
func _baender_bauen() -> void:
	laufband(53.0, 65.0, 0.0, 0.0, 4.2, 3.4, 1)
	laufband(71.0, 83.0, 0.0, 0.0, 4.2, 3.4, 1)
	# Auf dem ersten Band steht ein Block, der quer darüberfährt: Das Band
	# nimmt einem die Zeit zum Überlegen ab.
	schiebeblock(59.0, 0.0, 0.05, Vector3(1.4, 1.0, 1.4), 2.6, true, 1.2, 0.7)
	# Hängender Balken über dem zweiten Band – hier wird auf dem fahrenden
	# Boden gekrabbelt.
	stachelbalken(77.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.0))

	laufband(86.0, 96.0, 0.0, 0.03, 4.2, 2.8, -1)
	feuerspeier(91.0, -3.0, 1.0, 0.0, 3.2, 0.0)


## 100–148 · Kolbenwerk. Frage: Wann steht der Boden oben?
##
## 38 m ohne jeden festen Grund. Sechs Bohlen tauchen versetzt ab und
## kommen wieder; sie stehen lange oben und kurz unten, damit die Stelle
## ein Rhythmus wird und keine Wartezeit.
##
## Der Versatz von 0,17 je Bohle ist bewusst kein Sechstel: Bei einem
## Sechstel liefe eine saubere Welle durch, und man könnte den ganzen Weg
## in einem Zug durchlaufen, ohne je zu warten.
func _kolben_bauen() -> void:
	var stellen := [107.0, 113.0, 119.0, 125.0, 131.0, 137.0]
	var seiten := [0.0, -1.4, 1.2, -1.0, 1.4, 0.0]
	for i in stellen.size():
		wehrbohle(stellen[i], seiten[i], KOLBEN_OBEN, KOLBEN_UNTEN,
				float(i) * 0.17, Vector2(3.6, 3.2), 2.6, 1.1)
	# Ein Feuerspeier von der Seite über der Mitte: Wer auf einer Bohle
	# wartet, wartet nicht beliebig lange.
	feuerspeier(122.0, -3.2, 1.2, 0.0, 3.6, 0.35, true)


## 148–198 · Drehsaal. Frage: Wie bleibe ich auf dem Kreis?
##
## Fünf Drehscheiben über dem Schacht. Sie drehen abwechselnd links und
## rechts herum; zwei taumeln dazu. Der Trick ist nicht die Sprungweite –
## die ist klein –, sondern der Absprung von einer Fläche, die sich unter
## den Füßen wegdreht.
func _drehsaal_bauen() -> void:
	var stellen := [162.5, 168.0, 173.5, 179.0, 184.0]
	var seiten := [0.0, -1.8, 1.6, -1.4, 0.0]
	for i in stellen.size():
		var richtung: int = 1 if i % 2 == 0 else -1
		drehscheibe(stellen[i], seiten[i], 0.0, 4.2, 30.0 + float(i) * 4.0,
				richtung, 0.0, 0.0, i == 1 or i == 3)
	# Auf den festen Rändern davor und danach: Blöcke, die zum Rand
	# schieben – der Absprung soll nicht in Ruhe zu setzen sein.
	schiebeblock(155.0, 0.0, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.6, 0.9)
	schiebeblock(190.0, 0.0, 0.0, Vector3(1.8, 1.2, 1.8), 4.0, true, 1.6, 0.9,
			0.5)
	deckungsfleck(191.0, -3.0)


## 198–248 · Ofengang. Frage: Wo ist gerade keine Flamme?
##
## Der engste Abschnitt: 6,5 m breit, fester Boden, keine Lücke. Alles,
## was hier gefährlich ist, kommt aus einer Düse und hat einen Takt.
## Die Speier stehen abwechselnd links und rechts – zwischen zwei
## gegenüberliegenden ist immer genau ein Fenster offen.
func _ofengang_bauen() -> void:
	feuerspeier(204.0, -2.9, 1.0, 0.0, 3.0, 0.0)
	feuerspeier(210.0, 2.9, 1.0, 180.0, 3.0, 0.5)
	feuerspeier(216.0, -2.9, 1.0, 0.0, 3.0, 0.25)
	feuerspeier(228.0, 2.9, 1.2, 180.0, 3.2, 0.0, true)
	feuerspeier(234.0, -2.9, 1.0, 0.0, 3.0, 0.6)
	feuerspeier(240.0, 2.9, 1.0, 180.0, 3.0, 0.15)
	# Ein Rest der alten Elektrik, kurz vor dem Ausgang: Die Lücke wandert,
	# mal muss man krabbeln, mal springen.
	laserzaun(245.0, 6.0, true, 1.1)
	deckungsfleck(222.0, 0.0, 1.4)


## Der Ofen selbst: die einzige warme Lichtquelle des Levels.
##
## Er steht in der linken Wand des Ofengangs und ist reine Kulisse – man
## kann ihn nicht betreten und nicht auslösen. Sein Zweck ist das Licht:
## Ohne ihn wäre der ganze Abschnitt blaugrau wie der Rest, und die
## Flammen der Speier hätten nichts, wovon sie kommen könnten.
func _ofen_bauen() -> void:
	var glut := Materialbibliothek.leuchtend(GLUT_TIEF, 2.4)
	var glut_hell := Materialbibliothek.leuchtend(GLUT_HELL, 3.2)
	var eisen := Materialbibliothek.metall(ROSTSTAHL)

	for stelle: float in [216.0, 222.0, 228.0]:
		var gruppe := Node3D.new()
		gruppe.name = "Ofen"
		gruppe.position = LevelWerkzeuge.punkt(verlauf, stelle, -4.6, 0.0)
		gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, stelle)
		deko.add_child(gruppe)

		var rahmen := MeshInstance3D.new()
		var kasten := BoxMesh.new()
		kasten.size = Vector3(1.1, 3.0, 3.2)
		rahmen.mesh = kasten
		rahmen.material_override = eisen
		rahmen.position.y = 1.5
		gruppe.add_child(rahmen)

		var maul := MeshInstance3D.new()
		var loch := BoxMesh.new()
		loch.size = Vector3(0.35, 1.9, 2.1)
		maul.mesh = loch
		maul.material_override = glut_hell if stelle == 222.0 else glut
		maul.position = Vector3(0.5, 1.3, 0.0)
		gruppe.add_child(maul)

		var licht := OmniLight3D.new()
		licht.light_color = GLUT_HELL
		licht.light_energy = 4.5 if stelle == 222.0 else 3.0
		licht.omni_range = 16.0
		licht.omni_attenuation = 1.4
		licht.position = Vector3(1.6, 1.4, 0.0)
		gruppe.add_child(licht)


## 248–298 · Zahnradsteig. Frage: Welche Ebene trägt weiter?
##
## Drei Ebenen übereinander. Unten läuft fester Hallenboden – wer stürzt,
## verliert den Weg, nicht das Leben. Darüber zwei Reihen Absätze; nur die
## obere führt an den Kisten vorbei, und sie bricht zweimal ab, sodass man
## hinunter und wieder hinauf muss.
##
## Der Abschnitt läuft als Seitenansicht: Aus dem Rückenblick ist nicht zu
## erkennen, welcher Absatz höher liegt.
func _zahnradsteig_bauen() -> void:
	var stoff := _mauer_material()

	# Mittlere Ebene: durchgehend, aber niedrig.
	var mitte := [254.0, 259.0, 264.0, 269.0, 274.0, 279.0, 284.0, 289.0]
	for i in mitte.size():
		plattform(mitte[i], 0.0, 2.6 + float(i) * 0.06,
				Vector3(3.2, 0.5, 3.2), stoff)

	# Obere Ebene: zweimal unterbrochen. Der Aufstieg geht über Federn.
	kiste(Kiste.Art.SPRUNG, 251.0, 0.0)
	for i in 3:
		plattform(256.0 + float(i) * 5.0, 0.0, 5.6 + float(i) * 0.1,
				Vector3(3.0, 0.5, 3.0), stoff)
	kiste(Kiste.Art.SPRUNG, 271.0, 2.6)
	for i in 3:
		plattform(274.0 + float(i) * 5.0, 0.0, 5.9 + float(i) * 0.1,
				Vector3(3.0, 0.5, 3.0), stoff)
	plattform(292.0, 0.0, 6.2, Vector3(4.4, 0.6, 3.6), stoff)

	# Drehende Walzen zwischen den Ebenen: Sie tragen und schieben zugleich.
	drehscheibe(266.5, 0.0, 5.7, 3.4, 38.0, -1)
	drehscheibe(284.5, 0.0, 6.0, 3.4, 38.0, 1)


## 298–336 · Kesselhalle. Frage: Komme ich durch, bevor es zufällt?
##
## Drei Tore hintereinander, jedes mit eigenem Takt, und dazwischen
## Blöcke, die quer schieben. Das letzte Tor steht offen, solange jemand
## auf der Platte davor steht – und weil man nicht gleichzeitig auf der
## Platte und hinter dem Tor sein kann, muss man den Nachlauf ausnutzen.
func _kesselhalle_bauen() -> void:
	schliesstuer(306.0, 0.0, 4.0, 3.0, 2.2, 1.5, 0.0)
	schliesstuer(315.0, 0.0, 4.0, 3.0, 2.0, 1.6, 0.35)
	schiebeblock(310.5, 0.0, 0.0, Vector3(2.0, 1.2, 2.0), 4.4, true, 1.5, 0.8)
	schiebeblock(319.5, 0.0, 0.0, Vector3(2.0, 1.2, 2.0), 4.4, true, 1.5, 0.8,
			0.5)

	# Das letzte Tor hängt an einer Platte statt an der Uhr.
	var tor := schliesstuer(328.0, 0.0, 4.4, 3.2, 0.6, 6.0, 0.6)
	ausloeseplatte(322.0, 0.0, Vector2(3.0, 3.0), 1.6, false, [tor])

	laufband(300.0, 308.0, 0.0, 0.03, 4.0, 2.4, -1)
	feuerspeier(313.0, -3.6, 1.0, 0.0, 3.4, 0.2)
	feuerspeier(325.0, 3.6, 1.0, 180.0, 3.4, 0.7)


## Reihen kleiner Maschinen hinter Gittern.
##
## Sie stehen hinter der Leitwand und sind nie zu erreichen; sie arbeiten
## nur. Genau das ist ihr Zweck – eine Kulisse, die sich bewegt, macht aus
## einem Gang einen Betrieb. Die Zahnräder liegen alle auf der LINKEN
## Seite, weil die Seitenansicht des Zahnradsteigs von rechts kommt: Was
## zwischen Kamera und Spieler steht, nimmt das halbe Bild.
func _maschinenwand_bauen() -> void:
	var eisen := Materialbibliothek.metall(ROSTSTAHL)
	var stellen := [46.0, 60.0, 74.0, 88.0, 152.0, 166.0, 180.0,
			252.0, 262.0, 272.0, 282.0, 292.0, 304.0, 318.0, 330.0]
	for i in stellen.size():
		var s: float = stellen[i]
		# Hinter die Leitwand, nicht neben den Weg: Die Wegbreite wechselt
		# innerhalb eines Abschnitts, der Wandabstand nicht.
		var quer := -(_wandabstand(s) + 0.9)
		drehscheibe(s, quer, 1.2 + float(i % 3) * 0.9, 3.0,
				34.0 + float(i % 4) * 9.0, 1 if i % 2 == 0 else -1)
		_gitter_bauen(s, quer + 1.7, eisen)


## Abstand der Mauer an dieser Stelle. Außerhalb aller Wandabschnitte
## liefert sie den weitesten Wert, damit nichts in den Weg rutscht.
func _wandabstand(strecke: float) -> float:
	for w in WAENDE:
		if strecke >= w["von"] and strecke <= w["bis"]:
			return w["abstand"]
	return 11.5


## Senkrechte Stäbe vor einer Maschine.
func _gitter_bauen(strecke: float, seitlich: float, stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Gitter"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)
	for i in 7:
		var stab := MeshInstance3D.new()
		var form := BoxMesh.new()
		form.size = Vector3(0.09, 4.2, 0.09)
		stab.mesh = form
		stab.material_override = stoff
		stab.position = Vector3(0.0, 2.1, -1.8 + float(i) * 0.6)
		gruppe.add_child(stab)


## Gelbe Seilzüge unter der Decke.
##
## Sie sind die Linienführung des Levels: In einem Raum ohne Himmel fehlt
## dem Auge sonst jede durchgehende Kante. Die Seile laufen paarweise über
## dem Weg und hängen zwischen den Aufhängungen leicht durch.
func _seilzuege_bauen() -> void:
	var stoff := Materialbibliothek.leuchtend(SEIL_GELB, 0.4)
	for seite: float in [-1.0, 1.0]:
		var s := 6.0
		while s < M_ENDE - 8.0:
			# In den Lücken liefert `breite_bei` 0 – dort halten die Seile
			# einen festen Abstand, statt über die Mitte zu kreuzen.
			var quer_a := seite * clampf(breite_bei(s) * 0.5 - 0.6, 3.0, 5.0)
			var quer_b := seite * clampf(breite_bei(s + 7.0) * 0.5 - 0.6,
					3.0, 5.0)
			var a := LevelWerkzeuge.punkt(verlauf, s, quer_a, 6.6)
			var b := LevelWerkzeuge.punkt(verlauf, s + 7.0, quer_b, 6.6)
			# Ein Seil hängt durch: Der Mittelpunkt liegt tiefer als die
			# beiden Enden, sonst sieht die Reihe aus wie ein Lineal.
			var mitte := (a + b) * 0.5 + Vector3.DOWN * 0.35
			_seil_stueck(a, mitte, stoff)
			_seil_stueck(mitte, b, stoff)
			s += 7.0


func _seil_stueck(a: Vector3, b: Vector3, stoff: Material) -> void:
	var strang := b - a
	var laenge := strang.length()
	if laenge < 0.05:
		return
	var vor := strang / laenge
	var quer := vor.cross(Vector3.UP)
	if quer.length() < 0.001:
		quer = Vector3.RIGHT
	quer = quer.normalized()
	var hoch := quer.cross(vor).normalized()

	var zylinder := CylinderMesh.new()
	zylinder.top_radius = 0.055
	zylinder.bottom_radius = 0.055
	zylinder.height = laenge
	zylinder.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = zylinder
	mi.material_override = stoff
	# Der Zylinder liegt entlang seiner eigenen Y-Achse – also zeigt die
	# Y-Achse der Basis den Strang entlang.
	mi.transform = Transform3D(Basis(quer, vor, hoch), (a + b) * 0.5)
	deko.add_child(mi)


func _kamerazonen_setzen() -> void:
	kamerazone(252.0, 294.0, 15.0, 4.2)


## Dunst und Grundlicht je Abschnitt.
##
## Das Werk ist durchweg kalt und blaugrau; nur der Ofengang kippt ins
## Orange, und die Kesselhalle behält einen Rest davon. Die Torhalle ist
## am hellsten – von dort kommt Tageslicht herein, danach nie wieder.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 40.0, Color(0.38, 0.44, 0.51), 0.012, 1.25,
			Color(0.48, 0.55, 0.63), 46.0)
	stimmung(42.0, 196.0, Color(0.26, 0.32, 0.39), 0.020, 1.00,
			Color(0.36, 0.44, 0.54), 40.0)
	stimmung(198.0, 246.0, Color(0.46, 0.28, 0.17), 0.028, 0.85,
			Color(0.56, 0.36, 0.22), 32.0)
	stimmung(248.0, 296.0, Color(0.28, 0.34, 0.41), 0.018, 1.05,
			Color(0.38, 0.46, 0.56), 44.0)
	stimmung(298.0, M_ENDE, Color(0.40, 0.35, 0.34), 0.016, 1.15,
			Color(0.52, 0.46, 0.42), 52.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Torhalle ----------
	kiste(Kiste.Art.CHECKPOINT, 3.0, -3.0)
	kiste(Kiste.Art.NORMAL, 7.0, -2.4)
	kiste(Kiste.Art.NORMAL, 7.0, 0.0)
	kiste(Kiste.Art.NORMAL, 7.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 13.0, 0.0)
	kiste(Kiste.Art.EISEN, 18.0, -3.4)
	kiste(Kiste.Art.NORMAL, 18.0, -3.4, 1.6)
	kiste(Kiste.Art.SCHUTZ, 25.0, -2.6)
	kiste(Kiste.Art.NORMAL, 31.0, 0.0)
	kiste(Kiste.Art.TNT, 35.0, -2.2)
	kiste(Kiste.Art.NORMAL, 35.0, 2.2)

	# ---------- Bänderschacht: alles auf den Podesten ----------
	kiste(Kiste.Art.NORMAL, 45.0, -2.4)
	kiste(Kiste.Art.NORMAL, 45.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 50.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 68.0, -2.4)
	kiste(Kiste.Art.NORMAL, 68.0, 2.4)
	kiste(Kiste.Art.SCHUTZ, 85.0, -2.6)
	kiste(Kiste.Art.NORMAL, 94.0, 2.6)
	kiste(Kiste.Art.NORMAL, 97.0, -2.6)

	# ---------- Kolbenwerk: nur an den beiden festen Enden ----------
	kiste(Kiste.Art.CHECKPOINT, 102.0, -2.0)
	kiste(Kiste.Art.NORMAL, 102.0, 2.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 144.0, 0.0)
	kiste(Kiste.Art.NORMAL, 144.0, -2.2)

	# ---------- Drehsaal ----------
	kiste(Kiste.Art.CHECKPOINT, 152.0, -3.4)
	kiste(Kiste.Art.NORMAL, 152.0, 3.4)
	kiste(Kiste.Art.EISEN, 157.0, 0.0)
	kiste(Kiste.Art.NORMAL, 157.0, 0.0, 1.6)
	kiste(Kiste.Art.NORMAL, 188.0, -3.2)
	kiste(Kiste.Art.SCHUTZ, 192.0, 3.2)

	# ---------- Ofengang: eng, also flach und dicht am Rand ----------
	kiste(Kiste.Art.NORMAL, 201.0, -1.6)
	kiste(Kiste.Art.CHECKPOINT, 210.0, -1.6)
	kiste(Kiste.Art.NORMAL, 220.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 231.0, -1.6)
	kiste(Kiste.Art.NORMAL, 237.0, 1.6)
	kiste(Kiste.Art.NORMAL, 243.0, -1.6)

	# ---------- Zahnradsteig: die Belohnung liegt oben ----------
	kiste(Kiste.Art.NORMAL, 254.0, 0.0, 3.4)
	kiste(Kiste.Art.NORMAL, 264.0, 0.0, 3.4)
	kiste(Kiste.Art.NORMAL, 256.0, 0.0, 6.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 261.0, 0.0, 6.5)
	kiste(Kiste.Art.NORMAL, 266.0, 0.0, 6.6)
	kiste(Kiste.Art.CHECKPOINT, 268.0, -3.2)
	kiste(Kiste.Art.NORMAL, 274.0, 0.0, 6.7)
	kiste(Kiste.Art.SCHUTZ, 279.0, 0.0, 6.8)
	kiste(Kiste.Art.NORMAL, 284.0, 0.0, 6.9)
	kiste(Kiste.Art.LEBEN, 292.0, 0.0, 7.0)
	kiste(Kiste.Art.NORMAL, 289.0, 0.0, 3.5)

	# ---------- Kesselhalle ----------
	kiste(Kiste.Art.NORMAL, 301.0, -3.0)
	kiste(Kiste.Art.NORMAL, 301.0, 3.0)
	# Nichts in die Bahn der Schiebeblöcke bei 310,5 und 319,5: Sie fahren
	# 2,2 m nach beiden Seiten und sind 2 m breit, decken also ±3,2 m ab.
	kiste(Kiste.Art.NITRO, 304.0, 3.4)
	kiste(Kiste.Art.NORMAL, 311.0, -4.2)
	kiste(Kiste.Art.CHECKPOINT, 320.0, -4.4)
	kiste(Kiste.Art.EISEN, 324.0, 3.6)
	kiste(Kiste.Art.NORMAL, 324.0, 3.6, 1.6)
	kiste(Kiste.Art.FEDER, 331.0, 0.0)
	kiste(Kiste.Art.NORMAL, 334.0, -3.0)
	kiste(Kiste.Art.NORMAL, 334.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 334.0, 3.0)


# =========================================================== Gegner

## Gegner stehen nur auf festem Boden.
##
## Auf Bändern, Bohlen und Scheiben wäre ein patrouillierender Gegner
## unfair: Er stünde still im Raum, während der Boden unter dem Spieler
## wegfährt. Dort übernehmen Speier, Blöcke und der Takt.
func _gegner_setzen() -> void:
	# ---------- Torhalle ----------
	gegner(PANZERKAEFER, 11.0, -2.0, 4.0, true)
	gegner(STELZENSPINNE, 22.0, 2.0, 3.5, true)
	werfer(29.0, -5.0)

	# ---------- Bänderschacht: nur auf den Podesten ----------
	gegner(PANZERKAEFER, 47.0, 0.0, 2.4, true)
	gegner(SUMPFKROETE, 68.0, 0.0, 2.2, true)
	gegner(STELZENSPINNE, 90.0, 0.0, 2.4, true)

	# ---------- Kolbenwerk ----------
	gegner(PANZERKAEFER, 102.0, 0.0, 1.8, true)

	# ---------- Drehsaal ----------
	gegner(STELZENSPINNE, 154.0, 0.0, 3.0, true)
	schwarm(190.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 192.0, 0.0, 2.4, true)

	# ---------- Ofengang: einer im Gang, mehr passt nicht ----------
	gegner(SUMPFKROETE, 207.0, 0.0, 1.6, true)
	gegner(PANZERKAEFER, 226.0, 0.0, 1.6, true)

	# ---------- Zahnradsteig: unten, damit oben das Springen zählt ----------
	gegner(STELZENSPINNE, 257.0, -2.0, 2.6, true)
	gegner(PANZERKAEFER, 271.0, 2.0, 2.6, true)
	werfer(286.0, -3.0)

	# ---------- Kesselhalle ----------
	gegner(PANZERKAEFER, 303.0, -2.5, 3.5, true)
	gegner(SUMPFKROETE, 317.0, 2.5, 3.0, true)
	schwarm(330.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 333.0, -3.0, 4.0, true)


# =========================================================== Früchte

## Früchte zeigen, welche Ebene gemeint ist.
##
## Auf dem Zahnradsteig laufen drei Reihen übereinander – erst daran ist
## von der Seite zu erkennen, dass die obere Reihe die vollständige ist.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 34.0, 11, 0.0)
	fruechte_reihe(44.0, 52.0, 4, 0.0)
	fruechte_reihe(55.0, 63.0, 4, 0.0, 1.4)
	fruechte_reihe(66.0, 70.0, 3, 0.0)
	fruechte_reihe(73.0, 81.0, 4, 0.0, 1.4)
	fruechte_reihe(84.0, 97.0, 6, 0.0)
	fruechte_bogen(106.0, 138.0, 11, 0.0, 1.6)
	fruechte_reihe(150.0, 158.0, 4, 0.0)
	fruechte_bogen(162.0, 184.0, 8, 0.0, 1.8)
	fruechte_reihe(188.0, 196.0, 4, 0.0)
	fruechte_reihe(200.0, 246.0, 16, 0.0)
	fruechte_reihe(250.0, 292.0, 12, 0.0)
	fruechte_reihe(254.0, 289.0, 8, 0.0, 3.6)
	fruechte_reihe(256.0, 284.0, 7, 0.0, 6.6)
	fruechte_reihe(300.0, 334.0, 12, 0.0)


# =========================================================== Kulisse

## Was in einem verlassenen Werk wächst und was von ihm abfällt.
##
## Bretterstapel und Streben aus Totholz an den Wänden, Schutt auf dem
## Boden, Farn und Pilz in den feuchten Ecken, Grasbüschel in den Fugen.
## Alles ohne Kollision und immer AUSSERHALB des Weges – die Halle soll
## bewohnt aussehen, aber nichts darf im Weg stehen, wo der Boden ohnehin
## schon nicht zu trauen ist.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(31201)

	# Streben und Gerüsthölzer an den Wänden. Über den Lücken steht nichts:
	# `breite_bei` liefert dort 0, und ein Rand, den es nicht gibt, taugt
	# nicht als Standort.
	for i in 34:
		var s := randf_range(2.0, M_ENDE - 4.0)
		if breite_bei(s) < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var holz := BAUM.instantiate() as Baum
		holz.art = Baum.Art.TOTHOLZ
		holz.hoehe = randf_range(4.0, 9.0)
		holz.staerke = randf_range(0.7, 1.4)
		holz.saat = 9500 + i
		holz.wind = false
		holz.kollision = false
		holz.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + randf_range(2.0, 4.0)), -0.4)
		holz.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		# Leicht angelehnt statt senkrecht – gebaut sieht zu ordentlich aus.
		holz.rotation.z = seite * randf_range(0.08, 0.22)
		deko.add_child(holz)

	# Schutt: heruntergefallenes Mauerwerk an den Rändern.
	for i in 48:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 1.0)
		if rand < 1.6:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var brocken := STEIN.instantiate() as Stein
		brocken.saat = 9700 + i
		brocken.groesse = randf_range(0.4, 1.3)
		brocken.bemoost = false
		brocken.flach = i % 3 == 0
		brocken.kollision = false
		brocken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.8, rand), 0.0)
		brocken.rotation.y = randf() * TAU
		deko.add_child(brocken)

	# Farn und Pilz, wo es feucht ist: an den Wänden, nie auf dem Weg.
	for i in 40:
		var s := randf_range(2.0, M_ENDE - 4.0)
		if breite_bei(s) < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var bewuchs := KLEINZEUG.instantiate() as Kleinzeug
		bewuchs.art = Kleinzeug.Art.PILZ if i % 5 == 0 else Kleinzeug.Art.FARN
		bewuchs.groesse = randf_range(0.35, 0.6)
		bewuchs.saat = 9900 + i
		bewuchs.wind = false
		bewuchs.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + randf_range(0.5, 2.0)), -0.3)
		deko.add_child(bewuchs)

	# Gras in den Fugen der Randstreifen.
	for i in 30:
		var s := randf_range(2.0, M_ENDE - 4.0)
		if breite_bei(s) < 1.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(1.8, 1.8)
		horst.halm_hoehe = randf_range(0.25, 0.5)
		horst.farbe_unten = Farben.MOOS.darkened(0.3)
		horst.farbe_oben = Farben.FLECHTE
		horst.wind_staerke = 0.02
		horst.saat = 10100 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 - 0.3), 0.24)
		deko.add_child(horst)
	seed(wuerfel)
