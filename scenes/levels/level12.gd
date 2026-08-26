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
## Farbe: Es gibt hier keine Sonne. Jedes Licht im Bild kommt aus der
## Maschine selbst – aus glühenden Rohrbündeln an den Wänden, aus den
## Querrohren über dem Weg und aus dem Ofen bei 222 m. Deshalb ist das
## Werk warm und nicht blaugrau: Rußiges Mauerwerk und rostroter Stahl
## unter orangem Licht, dazu gelbe Seilzüge als Linienführung.
##
## Warum die Rohre Deko UND Beleuchtung sind: Eine Lichtquelle, die man
## im Bild sehen kann, erklärt sich selbst. Ein Weg, der hell ist, ohne
## dass etwas leuchtet, sieht aus wie ein Fehler in der Beleuchtung.
##
## Die Kulisse arbeitet: In den Wänden drehen sich Zahnräder hinter
## Gittern, die niemand berührt; daneben stehen Steigrohre, Ventile,
## Kohle und Schlacke. Sie sind der Grund, warum das Werk wie ein Ort
## wirkt und nicht wie eine Sammlung von Fallen.

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const STAUB := preload("res://scenes/props/Staub.tscn")

# --- Farben, die die Bibliothek nicht führt ---
## Rußiges Mauerwerk – der Grundton des ganzen Levels. Es ist warm
## getönt, weil das einzige Licht hier aus der Glut kommt: Eine Wand, die
## nur von orangem Licht beschienen wird, kann nicht blaugrau aussehen.
const MAUER_TIEF := Color(0.13, 0.10, 0.09)
const MAUER_HELL := Color(0.37, 0.28, 0.22)
## Rostroter Stahl: das zweite Trägermaterial, überall dort, wo gebaut
## und nicht gemauert wurde.
const ROSTSTAHL := Color(0.55, 0.24, 0.14)
## Ruß, Kohle, Schlacke – das Dunkel, das dem Glühen den Rahmen gibt.
const RUSS := Color(0.09, 0.07, 0.06)
const KOHLE := Color(0.13, 0.11, 0.10)
## Eiserner Wegbelag. Er ist das Hellste im Bild und am wenigsten
## gesättigt: Wo der Weg aufhört, hört die Helligkeit auf.
const WEGBLECH := Color(0.86, 0.79, 0.69)
## Der Burgkeller. Blaugrauer Stein gibt es NUR in der Torhalle – dort
## steht man noch im Bauwerk, ab dem Bänderschacht in der Maschine. Der
## kalte Anfang ist es, der das Glühen danach warm aussehen lässt: Ein
## Bild ohne einen einzigen kühlen Ton verliert seine Wärme.
const STEIN_TIEF := Color(0.17, 0.21, 0.26)
const STEIN_HELL := Color(0.44, 0.51, 0.58)
const FLUR_TIEF := Color(0.34, 0.39, 0.47)
const FLUR_HELL := Color(0.64, 0.69, 0.76)
## Tageslicht – es kommt einmal vor, oben in der Torhalle, und nie wieder.
const TAGLICHT := Color(0.70, 0.80, 0.97)
## Seilzüge. Messinggelb und stumpf: Sie laufen dicht über der Kamera
## vorbei, und was dort leuchtet, legt sich als Balken quer übers Bild.
const SEIL_GELB := Color(0.44, 0.36, 0.12)
## Ofenglut – das hellste Licht im Bild.
const GLUT_TIEF := Color(1.0, 0.42, 0.08)
const GLUT_HELL := Color(1.0, 0.78, 0.34)
## Der Ton der Rohre. Er ist dunkler als die Ofenglut und strahlt nur
## schwach ab: Ein Rohr über der Leuchtschwelle brennt im Bild zu Weiß
## aus und sieht dann aus wie eine Leuchtstoffröhre.
const ROHRGLUT := Color(0.86, 0.30, 0.05)
const ROHRGLUT_HELL := Color(0.98, 0.46, 0.11)

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
var _stein_stoff: StandardMaterial3D
var _flur_stoff: StandardMaterial3D


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
		{"text": "Glührohre werden angefahren", "tun": _gluehrohre_bauen},
		{"text": "Seilzüge", "tun": _seilzuege_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Dunst und Punktlicht", "tun": _stimmungen_setzen},
		{"text": "Schutt, Kohle und Rohrwerk", "tun": _deko_bauen},
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


## Blaugrauer Burgstein – nur für die Torhalle.
func _stein_material() -> StandardMaterial3D:
	if _stein_stoff != null:
		return _stein_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1205, 0.018,
			STEIN_TIEF, STEIN_HELL, 256)
	m.normal_enabled = true
	m.normal_texture = Materialbibliothek.normalmap(1206, 0.05, 2.0)
	m.normal_scale = 0.9
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)
	m.roughness = 0.9
	_stein_stoff = m
	return _stein_stoff


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
## abbricht, ist Mauerwerk. Das Blech ist bewusst heller als alles andere
## im Bild: Der Weg soll sich ohne Suchen von seiner Umgebung lösen, und
## unter orangem Licht ist ein zu dunkles Blech nicht mehr zu lesen.
func _boden_bauen() -> void:
	var form := {"tiefe": 12.0, "schritt": 1.0, "kante_hoehe": 0.26,
			"kante_breite": 0.65}
	# Die Torhalle ist noch gepflasterter Burgkeller, alles danach Blech.
	# Der Wechsel liegt genau dort, wo das erste Band losfährt – man
	# betritt die Maschine, und der Boden sagt es einem unter den Füßen.
	LevelWerkzeuge.korridor(geometrie, verlauf, [STRECKE[0]], {
		"oben": _flur_material(),
		"kante": _stein_material(),
		"klippe": _stein_material(),
	}, form)
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE.slice(1), {
		"oben": Materialbibliothek.metall(WEGBLECH),
		"kante": Materialbibliothek.metall(ROSTSTAHL),
		"klippe": _mauer_material(),
	}, form)
	luecken_markieren(ROSTSTAHL)


## Der helle Plattenboden der Torhalle.
func _flur_material() -> StandardMaterial3D:
	if _flur_stoff != null:
		return _flur_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1207, 0.02,
			FLUR_TIEF, FLUR_HELL, 256)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.32, 0.32, 0.32)
	m.roughness = 0.85
	_flur_stoff = m
	return _flur_stoff


func _waende_bauen() -> void:
	# Die Torhallenwand ist Burgmauerwerk und bleibt kalt; erst dahinter
	# beginnt der rußige Teil.
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, [WAENDE[0]],
			_stein_material(), {
		"schritt": 2.6, "lagen": 5, "block": 3.0,
		"sockel": 14.0, "saat": 1208,
		"adermaterial": Materialbibliothek.metall(ROSTSTAHL),
		"deckmaterial": Materialbibliothek.einfarbig(
				Color(0.30, 0.36, 0.42), 0.95),
		"aderdichte": 0.28,
	})
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE.slice(1),
			_mauer_material(), {
		"schritt": 2.6, "lagen": 5, "block": 3.0,
		"sockel": 14.0, "saat": 1204,
		"adermaterial": Materialbibliothek.metall(ROSTSTAHL),
		# Was oben auf den Mauervorsprüngen liegt, ist Ruß. Hier stand
		# einmal Frostgestein – ein blauweißer Belag in einem Raum, der
		# seit Jahren beheizt wird.
		"deckmaterial": Materialbibliothek.einfarbig(RUSS, 0.95),
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

	# Drei kalte Lichtschächte aus der Burg darüber. Sie sind das einzige
	# Tageslicht des Levels und stehen nur hier: Ab dem Bänderschacht
	# leuchtet ausschließlich die Maschine. Der kalte Anfang ist keine
	# Laune – ohne ihn hat das Glühen danach nichts, wogegen es warm sein
	# könnte, und das Level kippt ins Einfarbige.
	for stelle: float in [8.0, 20.0, 32.0]:
		var schacht := OmniLight3D.new()
		schacht.light_color = TAGLICHT
		schacht.light_energy = 2.6
		schacht.omni_range = 20.0
		schacht.omni_attenuation = 1.0
		schacht.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, 9.0)
		deko.add_child(schacht)


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
	# Die Glut bleibt unter der Schwelle, ab der ein Farbkanal anschlägt:
	# Ein Ofenmaul, das zu Weiß ausbrennt, ist kein Feuer mehr, sondern
	# ein Loch in der Wand.
	var glut := Materialbibliothek.leuchtend(GLUT_TIEF, 0.9)
	var glut_hell := Materialbibliothek.leuchtend(GLUT_HELL, 1.0)
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

	# Der Abschnitt hat kein Querrohr über sich – in der Seitenansicht
	# liefe es auf die Linse zu. Sein Licht kommt deshalb von der linken
	# Wand, hoch genug, dass alle drei Ebenen etwas abbekommen.
	for stelle: float in [252.0, 262.0, 272.0, 282.0, 292.0]:
		_glutlicht(stelle, -(_wandabstand(stelle) - 1.2), 4.6, 5.0, 20.0)

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


## Darf an dieser Stelle auf dieser Seite Kulisse stehen?
##
## Im Zahnradsteig sieht die Kamera von RECHTS auf den Weg. Alles, was
## dort rechts an der Wand hängt, steht zwischen Linse und Figur und
## nimmt das halbe Bild – dieselbe Regel, nach der auch die Zahnräder
## alle links sitzen.
func _seite_erlaubt(strecke: float, seite: float) -> bool:
	return seite < 0.0 or strecke < 246.0 or strecke > 296.0


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
	var stoff := Materialbibliothek.metall(SEIL_GELB)
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
	_rohr_stueck(a, b, 0.055, stoff, 6)


## Ein gerader Strang zwischen zwei Punkten im Weltmaßstab.
##
## Seile, Glührohre und Ketten sind dieselbe Aufgabe: einen Zylinder so
## zu drehen, dass er von A nach B zeigt. Deshalb steht das nur einmal da.
func _rohr_stueck(a: Vector3, b: Vector3, radius: float, stoff: Material,
		segmente := 8) -> void:
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
	zylinder.top_radius = radius
	zylinder.bottom_radius = radius
	zylinder.height = laenge
	zylinder.radial_segments = segmente
	var mi := MeshInstance3D.new()
	mi.mesh = zylinder
	mi.material_override = stoff
	# Der Zylinder liegt entlang seiner eigenen Y-Achse – also zeigt die
	# Y-Achse der Basis den Strang entlang.
	mi.transform = Transform3D(Basis(quer, vor, hoch), (a + b) * 0.5)
	deko.add_child(mi)


# =========================================================== Glut


## Die Glührohre – Kulisse und Beleuchtung in einem.
##
## In diesem Werk gibt es keine Sonne und kein Fenster. Alles, was man
## sieht, sieht man, weil ein Rohr daneben glüht. Darum sind die Rohre
## nicht Beiwerk, sondern die gesamte Grundbeleuchtung des Levels.
##
## Drei Lagen laufen als Bündel an beiden Wänden entlang, hinter der
## Leitwand – erreichbar ist keins davon. Alle 28 m quert ein einzelnes
## Rohr über dem Weg; das ist das Bild, an dem man das Level erkennt,
## und zugleich die Stelle, an der der Boden am wärmsten wird.
##
## Warum nicht jedes Rohrstück ein eigenes Licht bekommt: Ein Punktlicht
## alle 16 m reicht für einen durchgehend hellen Weg. Die Rohre dazwischen
## leuchten als Fläche mit und kosten nichts.
func _gluehrohre_bauen() -> void:
	var glut := Materialbibliothek.leuchtend(ROHRGLUT, 0.85)
	var glut_hell := Materialbibliothek.leuchtend(ROHRGLUT_HELL, 1.15)
	var eisen := Materialbibliothek.metall(ROSTSTAHL)

	# --- Wandbündel ---
	# Sie laufen über Kopfhöhe. Auf Augenhöhe stünde eine glühende Linie
	# genau dort, wo man die Kante des Weges sucht.
	# Erst ab dem Bänderschacht. In der Torhalle steht man noch im
	# Burgkeller: Dort ist der Stein blaugrau und das Licht kalt, und
	# genau dieser Anfang ist es, an dem man die Maschine danach als
	# heiß empfindet.
	var s := 44.0
	var zaehler := 0
	while s < M_ENDE - 6.0:
		# Im Ofengang läuft kein Bündel: Der Gang ist 6,5 m breit, die
		# Kamera rückt dort dicht heran, und ein Rohr an dieser Wand legt
		# sich als Balken über den unteren Bildrand. Licht gibt dort
		# ohnehin der Ofen, und die Wand gehört den Düsen.
		if s > 194.0 and s < 246.0:
			s += 8.0
			zaehler += 1
			continue
		for seite: float in [-1.0, 1.0]:
			if not _seite_erlaubt(s, seite):
				continue
			var quer_a := seite * (_wandabstand(s) - 0.5)
			var quer_b := seite * (_wandabstand(s + 8.0) - 0.5)
			for i in 2:
				var h := 2.9 + float(i) * 0.52
				_rohr_stueck(
						LevelWerkzeuge.punkt(verlauf, s, quer_a, h),
						LevelWerkzeuge.punkt(verlauf, s + 8.0, quer_b, h),
						0.18, glut_hell if i == 0 else glut)
			# Eine Schelle je Bündelanfang: Ohne sie schwebt das Bündel.
			_schelle_bauen(s, quer_a, eisen)
		# Das Licht wechselt von Bündel zu Bündel die Seite. Beidseitig
		# wäre der Weg schattenlos flach, einseitig wäre eine Levelhälfte
		# dunkel; im Wechsel stehen die Schatten quer über dem Weg.
		var lichtseite: float = 1.0 if zaehler % 2 == 0 else -1.0
		# In den weiten Hallen rückt das Licht von der Wand weg zur Mitte:
		# Aus elf Metern Abstand käme auf dem Weg nichts mehr an.
		_glutlicht(s + 4.0,
				lichtseite * minf(_wandabstand(s + 4.0) - 1.4, 5.5),
				2.6, 4.6, 17.0)
		zaehler += 1
		s += 8.0

	# --- Querrohre über dem Weg ---
	# Nicht über den Schächten: Dort steht die Kamera tiefer, und ein Rohr
	# quer im Bild würde genau die Kante verdecken, auf die man springt.
	# Im Zahnradsteig steht keins: Dort blickt die Kamera von der Seite,
	# und ein Rohr quer zum Weg läuft dann geradewegs auf die Linse zu.
	for stelle: float in [46.0, 74.0, 152.0, 194.0, 210.0, 232.0,
			302.0, 312.0, 322.0]:
		var weite := _wandabstand(stelle) - 0.6
		# Der dunklere Ton, obwohl es das auffälligste Rohr des Levels ist:
		# Beim Durchlaufen schiebt es sich bis dicht vor die Kamera, und
		# der helle Ton brennt dort zu einem weißen Balken aus.
		_rohr_stueck(
				LevelWerkzeuge.punkt(verlauf, stelle, -weite, 5.4),
				LevelWerkzeuge.punkt(verlauf, stelle, weite, 5.4),
				0.24, glut, 10)
		# Zwei Aufhängungen, sonst hängt das Rohr an nichts.
		for seite: float in [-1.0, 1.0]:
			_rohr_stueck(
					LevelWerkzeuge.punkt(verlauf, stelle, seite * weite, 5.4),
					LevelWerkzeuge.punkt(verlauf, stelle, seite * weite, 7.4),
					0.09, eisen, 6)
		_glutlicht(stelle, 0.0, 4.7, 5.0, 18.0)


## Ein Punktlicht aus der Glut. Ohne Schatten: Es sind über dreißig davon
## im Level, und ihre Aufgabe ist Helligkeit, nicht Zeichnung – die
## Zeichnung machen der Ofen und das Sonnenersatzlicht der Szene.
func _glutlicht(strecke: float, seitlich: float, hoehe: float,
		staerke: float, reichweite: float) -> void:
	var licht := OmniLight3D.new()
	licht.light_color = GLUT_HELL
	licht.light_energy = staerke
	licht.omni_range = reichweite
	licht.omni_attenuation = 1.2
	licht.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	deko.add_child(licht)


## Schelle: das Blech, mit dem ein Rohrbündel an der Mauer hängt.
func _schelle_bauen(strecke: float, seitlich: float, stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Schelle"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var blech := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = Vector3(0.5, 2.1, 0.22)
	blech.mesh = form
	blech.material_override = stoff
	blech.position = Vector3(0.0, 2.05, 0.0)
	gruppe.add_child(blech)


func _kamerazonen_setzen() -> void:
	kamerazone(252.0, 294.0, 15.0, 4.2)


## Dunst und Grundlicht je Abschnitt.
##
## Ab dem Bänderschacht ist der Dunst warm, weil er nur streut, was die
## Maschine abgibt. Nur die Torhalle bleibt kühl: Dort fällt Licht aus
## der Burg herein, danach nie wieder. Ein blaugrauer Dunst weiter hinten
## würde behaupten, dass irgendwo draußen Tageslicht steht.
##
## Die Dichte bleibt niedrig: Der Nahbereich bis zwölf Meter darf vom
## Dunst nicht angefasst werden, sonst verliert der Weg seine Kante.
func _stimmungen_setzen() -> void:
	# Die Torhalle allein ist kühl: Man steht noch im Bauwerk.
	stimmung(0.0, 40.0, Color(0.26, 0.33, 0.43), 0.012, 1.3,
			Color(0.42, 0.54, 0.70), 46.0)
	stimmung(42.0, 196.0, Color(0.38, 0.22, 0.14), 0.015, 1.35,
			Color(0.54, 0.36, 0.24), 40.0)
	stimmung(198.0, 246.0, Color(0.50, 0.27, 0.14), 0.016, 1.25,
			Color(0.66, 0.41, 0.22), 32.0)
	stimmung(248.0, 296.0, Color(0.41, 0.25, 0.16), 0.015, 1.4,
			Color(0.58, 0.40, 0.28), 44.0)
	stimmung(298.0, M_ENDE, Color(0.47, 0.30, 0.19), 0.014, 1.5,
			Color(0.64, 0.46, 0.32), 52.0)


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
## Es laufen nur zwei Arten hier unten: der Panzerkäfer als
## Maschinenkriecher und die Stelzenspinne als das, was in einem
## Kesselhaus zwischen den Rohren hängt. Eine Sumpfkröte stand hier
## einmal – die gehört in Raum 2 und nicht unter eine Burg.
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
	gegner(STELZENSPINNE, 68.0, 0.0, 2.2, true)
	gegner(STELZENSPINNE, 90.0, 0.0, 2.4, true)

	# ---------- Kolbenwerk ----------
	gegner(PANZERKAEFER, 102.0, 0.0, 1.8, true)

	# ---------- Drehsaal ----------
	gegner(STELZENSPINNE, 154.0, 0.0, 3.0, true)
	schwarm(190.0, 0.0, 10.0)
	gegner(PANZERKAEFER, 192.0, 0.0, 2.4, true)

	# ---------- Ofengang: einer im Gang, mehr passt nicht ----------
	gegner(STELZENSPINNE, 207.0, 0.0, 1.6, true)
	gegner(PANZERKAEFER, 226.0, 0.0, 1.6, true)

	# ---------- Zahnradsteig: unten, damit oben das Springen zählt ----------
	gegner(STELZENSPINNE, 257.0, -2.0, 2.6, true)
	gegner(PANZERKAEFER, 271.0, 2.0, 2.6, true)
	werfer(286.0, -3.0)

	# ---------- Kesselhalle ----------
	gegner(PANZERKAEFER, 303.0, -2.5, 3.5, true)
	gegner(PANZERKAEFER, 317.0, 2.5, 3.0, true)
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

## Was in einer arbeitenden Maschinenhalle herumsteht.
##
## Hier unten wächst nichts, hier läuft etwas. Die Kulisse besteht
## deshalb aus dem, was eine Maschine braucht und was sie abwirft:
## Steigrohre und Ventile an den Wänden, Nietbleche als Wandhaut, Ketten
## aus der Höhe, Kohle und Schlacke am Wegrand, Funkenflug über den
## heißen Stellen.
##
## An dieser Stelle standen einmal Totholzbäume, Farn, Pilze und
## Grasbüschel. Die waren aus dem Wurzelwald übernommen und machten aus
## der Halle eine Ruine unter freiem Himmel – das Werk hier ist aber in
## Betrieb, und über ihm liegt eine Burg.
##
## Alles ohne Kollision und immer AUSSERHALB des Weges: Wo dem Boden
## ohnehin nicht zu trauen ist, darf nichts zusätzlich im Weg stehen.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(31201)
	var eisen := Materialbibliothek.metall(ROSTSTAHL)
	var stahl := Materialbibliothek.metall(Color(0.44, 0.35, 0.30))
	var kohle := Materialbibliothek.einfarbig(KOHLE, 0.98)
	var schlacke := Materialbibliothek.einfarbig(Color(0.24, 0.19, 0.16), 0.95)

	# Steigrohre an den Wänden. Sie geben der Mauer ein Maß – ohne sie ist
	# eine fünfzehn Meter hohe Wand eine Fläche ohne Größe.
	for i in 26:
		var s := randf_range(3.0, M_ENDE - 5.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		if not _seite_erlaubt(s, seite):
			continue
		_steigrohr(s, seite * (_wandabstand(s) - 0.55),
				randf_range(4.5, 9.5), eisen)

	# Ventilräder. Sie sitzen tief, in Greifhöhe eines Heizers – nicht
	# oben, wo sie niemand erreichen könnte.
	for i in 18:
		var s := randf_range(4.0, M_ENDE - 6.0)
		var seite: float = -1.0 if i % 3 == 0 else 1.0
		if not _seite_erlaubt(s, seite):
			continue
		_ventil(s, seite * (_wandabstand(s) - 0.6), randf_range(1.3, 2.6),
				seite, eisen)

	# Nietbleche: die Wandhaut dort, wo nicht gemauert, sondern beplankt
	# wurde. Die Nietreihe ist der Maßstab, an dem das Auge die Größe
	# der Halle abliest.
	for i in 16:
		var s := randf_range(4.0, M_ENDE - 6.0)
		var seite: float = 1.0 if i % 2 == 0 else -1.0
		if not _seite_erlaubt(s, seite):
			continue
		_nietblech(s, seite * (_wandabstand(s) - 0.44), seite, stahl)

	# Ketten aus der Höhe. Sie hängen frei und enden im Nichts – genau das
	# macht eine Decke glaubhaft, die man nie zu sehen bekommt.
	for i in 14:
		var s := randf_range(6.0, M_ENDE - 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		if not _seite_erlaubt(s, seite):
			continue
		_kette(s, seite * (_wandabstand(s) - 1.4), 8.2,
				randf_range(2.0, 4.5), stahl)

	# Kohle am Wegrand: der dunkle Ton, der dem Glühen den Rahmen gibt.
	# Nur wo der Rand breit genug ist, sonst liegt der Haufen auf der
	# Laufspur.
	for i in 22:
		var s := randf_range(3.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 1.2)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		_haufen(s, seite * randf_range(rand * 0.7, rand), 7, 0.22, 0.55,
				0.8, kohle)

	# Schlacke: was aus dem Ofen fällt und liegen bleibt. Hier lagen
	# einmal die fertigen Felsmodelle – die tragen Grasbüschel auf dem
	# Kopf, und Gras wächst unter einer Burg nicht.
	for i in 44:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 1.0)
		if rand < 1.6:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		_haufen(s, seite * randf_range(rand * 0.8, rand), 3, 0.3, 0.85,
				0.5, schlacke)

	# Funkenflug. Er steht nur dort, wo auch Glut ist: über dem Ofengang,
	# an den Querrohren und am Fuß der Kesselhalle. Ein Funke ohne Feuer
	# darunter wäre eine Behauptung.
	var stellen := [46.0, 122.0, 210.0, 222.0, 232.0, 302.0, 322.0]
	for i in stellen.size():
		var s: float = stellen[i]
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var funken := STAUB.instantiate() as Staubflug
		funken.raum = Vector3(2.4, 5.0, 3.0)
		funken.anzahl = 46
		funken.groesse = 0.07
		funken.farbe = GLUT_HELL
		funken.deckkraft = 0.9
		# Funken steigen, Staub fällt: Das Vorzeichen ist der ganze
		# Unterschied zwischen einem Kesselhaus und einem Dachboden.
		funken.steiggeschwindigkeit = 0.85
		funken.wirbel = 0.5
		funken.funkeln = 1.0
		funken.saat = 9300 + i
		funken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (_wandabstand(s) - 1.6), 1.4)
		deko.add_child(funken)
	seed(wuerfel)


## Senkrechtes Rohr an der Mauer, mit Flanschen an den Stößen.
func _steigrohr(strecke: float, seitlich: float, hoehe: float,
		stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Steigrohr"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, -0.3)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var strang := MeshInstance3D.new()
	var rohr := CylinderMesh.new()
	rohr.top_radius = 0.22
	rohr.bottom_radius = 0.22
	rohr.height = hoehe
	rohr.radial_segments = 8
	strang.mesh = rohr
	strang.material_override = stoff
	strang.position.y = hoehe * 0.5
	gruppe.add_child(strang)

	for h: float in [0.9, hoehe * 0.55, hoehe - 0.5]:
		var flansch := MeshInstance3D.new()
		var scheibe := CylinderMesh.new()
		scheibe.top_radius = 0.36
		scheibe.bottom_radius = 0.36
		scheibe.height = 0.16
		scheibe.radial_segments = 8
		flansch.mesh = scheibe
		flansch.material_override = stoff
		flansch.position.y = h
		gruppe.add_child(flansch)


## Handrad auf einem Wandkasten. Die Radachse zeigt quer zum Weg, damit
## das Rad als Kreis und nicht als Strich im Bild steht.
func _ventil(strecke: float, seitlich: float, hoehe: float, seite: float,
		stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Ventil"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var kasten := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = Vector3(0.24, 0.85, 0.85)
	kasten.mesh = form
	kasten.material_override = stoff
	gruppe.add_child(kasten)

	# Das Rad steht auf der Seite, die zum Weg zeigt – auf der anderen
	# sähe es niemand.
	var rad := Node3D.new()
	rad.position.x = -seite * 0.3
	rad.rotation.z = PI * 0.5
	gruppe.add_child(rad)

	var reifen := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.24
	ring.outer_radius = 0.34
	ring.rings = 6
	ring.ring_segments = 12
	reifen.mesh = ring
	reifen.material_override = stoff
	rad.add_child(reifen)

	for dreh in 2:
		var speiche := MeshInstance3D.new()
		var balken := BoxMesh.new()
		balken.size = Vector3(0.62, 0.06, 0.06) if dreh == 0 \
				else Vector3(0.06, 0.06, 0.62)
		speiche.mesh = balken
		speiche.material_override = stoff
		rad.add_child(speiche)


## Genietetes Wandblech. Ohne die Nietreihe ist es nur eine Platte.
func _nietblech(strecke: float, seitlich: float, seite: float,
		stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Nietblech"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 2.3)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var platte := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = Vector3(0.16, 1.7, 2.8)
	platte.mesh = form
	platte.material_override = stoff
	gruppe.add_child(platte)

	for i in 8:
		var niet := MeshInstance3D.new()
		var kugel := SphereMesh.new()
		kugel.radius = 0.06
		kugel.height = 0.12
		kugel.radial_segments = 6
		kugel.rings = 3
		niet.mesh = kugel
		niet.material_override = stoff
		niet.position = Vector3(-seite * 0.1,
				0.7 if i < 4 else -0.7,
				-1.05 + float(i % 4) * 0.7)
		gruppe.add_child(niet)


## Hängende Kette. Die Glieder stehen abwechselnd quer – nur daran ist
## eine Kette von einem Seil zu unterscheiden.
func _kette(strecke: float, seitlich: float, oben: float, laenge: float,
		stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Kette"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	var glieder := clampi(int(laenge / 0.22), 4, 22)
	for i in glieder:
		var glied := MeshInstance3D.new()
		var form := BoxMesh.new()
		form.size = Vector3(0.1, 0.26, 0.17)
		glied.mesh = form
		glied.material_override = stoff
		glied.position.y = oben - float(i) * 0.21
		glied.rotation.y = 0.0 if i % 2 == 0 else PI * 0.5
		gruppe.add_child(glied)


## Ein Haufen kantiger Brocken, wild gedreht.
##
## Kohle und Schlacke sind dieselbe Form in zwei Größen und zwei Tönen –
## rund und gewachsen darf hier unten nichts aussehen.
func _haufen(strecke: float, seitlich: float, teile: int, kante_min: float,
		kante_max: float, streuung: float, stoff: Material) -> void:
	var gruppe := Node3D.new()
	gruppe.name = "Haufen"
	gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	gruppe.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(gruppe)

	for i in teile:
		var brocken := MeshInstance3D.new()
		var form := BoxMesh.new()
		var kante := randf_range(kante_min, kante_max)
		form.size = Vector3(kante, kante * randf_range(0.6, 1.0),
				kante * randf_range(0.7, 1.2))
		brocken.mesh = form
		brocken.material_override = stoff
		brocken.position = Vector3(randf_range(-streuung, streuung),
				randf_range(0.0, kante * 0.6),
				randf_range(-streuung * 1.2, streuung * 1.2))
		brocken.rotation = Vector3(randf() * TAU, randf() * TAU,
				randf() * TAU)
		gruppe.add_child(brocken)
