extends KorridorLevel
## Level 25 – "Dächergasse"
##
## Die Dächer einer Altstadt, hell und freundlich (Steckbrief 5-5) – und
## damit der ausdrückliche Gegenpol zu Level 23. Wo dort alles im Schwarz
## verschwindet, sieht man hier alles: blauer Himmel, Sandwände,
## Terrakotta, türkise Ornamente. Die farbigste Palette der Reihe.
##
## Kernbauteil ist das `hangelgitter()`. Es ist mehr als ein Hindernis:
## Es ist ein eigener Bewegungszustand mit eigener Hitbox und eigener
## Steuerung. Deshalb stellt jeder Gitterabschnitt eine ANDERE Frage an
## dasselbe Bauteil, statt es viermal gleich zu benutzen.
##
##     0 –  48  Sandgasse      laufen, springen, Sprungteppiche
##    48 – 106  Hangelgasse    zwei Gitter, Beine anziehen
##   106 – 164  Teppichflug    fliegende Teppiche über der Gasse
##   164 – 228  Skorpiondecke  Gitter mit Skorpionen: Drehschlag im Hängen
##   228 – 276  Basar          Gedränge – und der Bruch der eigenen Regel
##   276 – 322  Kuppeln        der helle Abschluss
##
## DIE ZWEI RECHNUNGEN, AUF DENEN DAS LEVEL STEHT:
##
## 1. STACHELBALKEN IM HANGELBAND (Gitter auf 3,20 m, wie in Level 10):
##      Sohlen im Hang        3,20 − 1,55 = 1,65 m
##      Kapsel baumelnd       1,65 … 2,95 m
##      Kapsel angezogen      2,19 … 2,95 m   (untere 0,54 m fallen weg)
##    Die Gefahrzone muss also zwischen 1,65 und 2,19 liegen. Unterkante
##    1,70 bei Dicke 0,23 reicht bis 2,05 – 14 cm Luft zur angezogenen
##    Kapsel. Ein Balken üblicher Dicke (0,55) träfe beide Haltungen und
##    wäre keine Aufgabe, sondern eine Mauer.
##
## 2. SKORPION IN DREHSCHLAGWEITE (Gitter auf 2,70 m):
##      Sohlen im Hang        2,70 − 1,55 = 1,15 m
##      Drehschlagmitte       1,15 + 0,50 = 1,65 m, Reichweite 1,70 m
##      Quer erreicht der Hangelnde bei Gitterbreite 2,6 m ±0,95 m
##    Der Skorpion sitzt deshalb NICHT auf dem Gitter, sondern auf einem
##    Mauervorsprung DANEBEN, Oberkante 0,85 m, seitlich 1,50 m. Von der
##    nahen Seite aus sind das 0,97 m – im Schlagbereich; von der fernen
##    Seite 2,4 m – außer Reichweite, aber auch außer Gefahr. Damit wird
##    aus dem Skorpion eine Entscheidung (quer ausweichen oder schlagen)
##    statt einer Pflichtübung. Säße er auf einem Balken ÜBER dem Gitter,
##    läge er bei jeder Bauweise über 1,70 m entfernt und wäre gar nicht
##    zu treffen – der Drehschlag geht zur Seite, nicht nach oben.
##
## UND EINMAL BRICHT DAS LEVEL SEINE EIGENE REGEL. Bei 248 m steht eine
## Treppe aus nitrogrünen Kisten über der Gasse. Nitro heißt im ganzen
## Spiel: bei Berührung Explosion. Diese hier sind `Kiste.Art.EISEN` und
## explodieren nicht – sie tragen. Wer es merkt, findet die Terrasse mit
## der Extralebenkiste; wer es nicht wagt, verliert nichts. Genau EINMAL
## im Level, nie zweimal.

const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")

# ----------------------------------------------------------- Palette
# Aus dem Vorbild gemessen. Lokale Konstanten, weil `Farben` keine
# Wüstenstadt kennt und ein einzelner Level kein Biom ist.
const TERRAKOTTA := Color(0.792, 0.412, 0.224)     ## #CA6939 – die Mitte
const SAND := Color(0.910, 0.667, 0.369)           ## #E8AA5E – Sandwand
const SCHATTENBRAUN := Color(0.341, 0.180, 0.106)  ## #572E1B – Fuge, Schatten
const LEHMROT := Color(0.643, 0.349, 0.196)        ## #A45932
const HIMMELBLAU := Color(0.231, 0.424, 0.729)     ## #3B6CBA – der Himmel
const GRAULILA := Color(0.635, 0.541, 0.576)       ## #A28A93 – Putz im Schatten
## Ornamentfarben. Türkis ist die Signalfarbe dieses Levels: Sie kommt
## sonst nirgends im Bild vor und markiert deshalb, was wichtig ist.
const TUERKIS := Color(0.16, 0.70, 0.66)
const ORNAMENT_WEISS := Color(0.94, 0.92, 0.86)

# ----------------------------------------------------------- Marken
const M_SANDGASSE := 0.0
const M_HANGELGASSE := 48.0
const M_TEPPICHFLUG := 106.0
const M_SKORPIONDECKE := 164.0
const M_BASAR := 228.0
const M_KUPPELN := 276.0
const M_ENDE := 322.0

# ----------------------------------------------------------- Höhen
const ABSTURZ := -7.0
## Die Gasse zwischen den Häusern. Sie liegt unter der Absturzzone
## (ABSTURZ−5 bis ABSTURZ), damit kein Sturz auf einem Kulissendach endet.
const GASSENGRUND := -14.0
const FLOSS_HOEHE := -0.26
const DECK := FLOSS_HOEHE + Wasserplattform.DECK_STAERKE * 0.5

## Lichte Höhe der beiden ersten Gitter. Rechnung 1 im Kopf.
const GITTER_HOCH := 3.2
## Lichte Höhe der Skorpiongitter. Rechnung 2 im Kopf.
const GITTER_TIEF := 2.7
## Breite der Skorpiongitter: Sie muss Platz zum Ausweichen lassen.
const GITTER_BREIT := 2.6

## Oberkante der Mauervorsprünge, auf denen die Skorpione sitzen.
const SIMS_OBEN := 0.85
const SIMS_SEITLICH := 1.5

## Unterkante eines Balkens, unter dem nur Krabbeln durchkommt.
const KRIECHHOEHE := 0.95

## Dachhöhe der Nachbarhäuser, auf denen die Kuppeln sitzen.
const KUPPELDACH := -1.6


const STRECKE := [
	{"von": 0.0, "bis": 48.0, "breite": 13.0, "breite_ende": 9.0},
	# Hangelgasse: zwei Dächer, dazwischen nur die Gitter
	{"von": 48.0, "bis": 66.0, "breite": 8.0},
	{"von": 82.0, "bis": 94.0, "breite": 8.0},
	{"von": 106.0, "bis": 122.0, "breite": 9.0},
	# Teppichflug: zwei Löcher, zwei fliegende Teppiche
	{"von": 138.0, "bis": 150.0, "breite": 8.0},
	{"von": 164.0, "bis": 188.0, "breite": 9.0},
	# Skorpiondecke: zwei Gitter mit Vorsprüngen daneben
	{"von": 204.0, "bis": 214.0, "breite": 9.0},
	{"von": 228.0, "bis": 276.0, "breite": 10.0},
	{"von": 276.0, "bis": 322.0, "breite": 12.0, "breite_ende": 9.0},
]

## Die Stufen der Nitro-Treppe: {"strecke", "seitlich", "hoehe"}.
## Sie stehen hier oben, weil sie an zwei Stellen gebraucht werden – beim
## Bauen und beim Nachstreichen nach einem Tod.
const TREPPE := [
	{"strecke": 248.0, "seitlich": -3.2, "hoehe": 1.0},
	{"strecke": 250.0, "seitlich": -4.4, "hoehe": 2.0},
	{"strecke": 252.0, "seitlich": -5.6, "hoehe": 3.0},
	{"strecke": 254.0, "seitlich": -6.8, "hoehe": 4.0},
	{"strecke": 256.0, "seitlich": -8.0, "hoehe": 5.0},
]

var _mat_dach: StandardMaterial3D = null
var _mat_wand: StandardMaterial3D = null
var _mat_putz: StandardMaterial3D = null
## Weltpunkte der Treppenstufen, zum Nachstreichen nach einem Tod.
var _treppenorte: Array[Vector3] = []


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Die Dächer werden vermessen", "tun": _verlauf_anlegen},
		{"text": "Dachflächen", "tun": _boden_bauen},
		{"text": "Die Altstadt darunter", "tun": _altstadt_bauen},
		{"text": "Spitzbögen", "tun": _boegen_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Dünen", "tun": _horizont_bauen},
		{"text": "Sandgasse", "tun": _sandgasse_bauen},
		{"text": "Hangelgasse", "tun": _hangelgasse_bauen},
		{"text": "Teppichflug", "tun": _teppichflug_bauen},
		{"text": "Skorpiondecke", "tun": _skorpiondecke_bauen},
		{"text": "Basar", "tun": _basar_bauen},
		{"text": "Kuppeln", "tun": _kuppeln_bauen},
		{"text": "Stimmungen", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Die Treppe, die nicht explodiert", "tun": _treppe_bauen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Eine flache Schleife über den Dächern. Sie steigt nur wenig – die
## Altstadt ist eben, ihr Auf und Ab steckt in den Häusern, nicht im
## Gelände.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, 0.5, -16),
		Vector3(4, 1.0, -38),        # Sandgasse
		Vector3(16, 1.4, -58),       # Hangelgasse
		Vector3(34, 1.8, -72),
		Vector3(56, 2.2, -78),
		Vector3(78, 2.6, -74),       # Teppichflug
		Vector3(96, 3.0, -60),
		Vector3(106, 3.4, -42),
		Vector3(108, 3.6, -20),      # Skorpiondecke
		Vector3(102, 3.4, 2),
		Vector3(90, 3.0, 20),
		Vector3(72, 2.6, 32),        # Basar
		Vector3(50, 2.2, 38),
		Vector3(28, 2.0, 36),        # Kuppeln
		Vector3(10, 1.6, 26),
	])


# =========================================================== Stoffe

## Die Dachfläche: heller Sand, festgetreten.
func _dachsand() -> StandardMaterial3D:
	if _mat_dach == null:
		_mat_dach = StandardMaterial3D.new()
		_mat_dach.albedo_texture = Materialbibliothek.rauschtextur(
				2501, 0.08, SAND.darkened(0.18), SAND.lightened(0.14))
		_mat_dach.normal_enabled = true
		_mat_dach.normal_texture = Materialbibliothek.normalmap(2501, 0.24, 1.1)
		_mat_dach.normal_scale = 0.4
		_mat_dach.roughness = 0.95
		_mat_dach.uv1_triplanar = true
		_mat_dach.uv1_scale = Vector3(0.32, 0.32, 0.32)
	return _mat_dach


## Terrakotta: die Mitte der Palette, für Kanten und Brüstungen.
func _terrakotta() -> StandardMaterial3D:
	if _mat_wand == null:
		_mat_wand = StandardMaterial3D.new()
		_mat_wand.albedo_texture = Materialbibliothek.rauschtextur(
				2502, 0.06, SCHATTENBRAUN, TERRAKOTTA)
		_mat_wand.normal_enabled = true
		_mat_wand.normal_texture = Materialbibliothek.normalmap(2502, 0.15, 1.5)
		_mat_wand.normal_scale = 0.6
		_mat_wand.roughness = 0.92
		_mat_wand.uv1_triplanar = true
		_mat_wand.uv1_scale = Vector3(0.26, 0.26, 0.26)
	return _mat_wand


## Verputzte Hauswand, im Schatten leicht graulila.
func _lehmputz() -> StandardMaterial3D:
	if _mat_putz == null:
		_mat_putz = StandardMaterial3D.new()
		_mat_putz.albedo_texture = Materialbibliothek.rauschtextur(
				2503, 0.05, GRAULILA.darkened(0.25), SAND.darkened(0.06))
		_mat_putz.normal_enabled = true
		_mat_putz.normal_texture = Materialbibliothek.normalmap(2503, 0.18, 0.9)
		_mat_putz.normal_scale = 0.35
		_mat_putz.roughness = 0.96
		_mat_putz.uv1_triplanar = true
		_mat_putz.uv1_scale = Vector3(0.2, 0.2, 0.2)
	return _mat_putz


# =========================================================== Grund

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _dachsand(),
		"kante": _terrakotta(),
		"klippe": _lehmputz(),
	}, {"tiefe": 3.2, "schritt": 1.0, "kante_hoehe": 0.30, "kante_breite": 0.7})
	luecken_markieren(TERRAKOTTA)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


## Ferne Dünen unter einem hellen Himmel. Der nahe Ton ist Terrakotta,
## der ferne fast weiß – so wirkt die Ebene weit, ohne dass Nebel nötig
## wäre.
func _horizont_bauen() -> void:
	horizont(240.0, 26.0, LEHMROT, SAND.lightened(0.35),
			true, GASSENGRUND - 2.0)


# =========================================================== Kulisse

## Die Altstadt neben und unter dem Weg.
##
## Reine Sichtkörper ohne Kollision: Es sind mehrere hundert Quader, und
## keiner davon soll je etwas tragen. Ein StaticBody3D je Haus wäre
## verschwendete Physik – und ein Kulissendach in Absturzhöhe würde einen
## Sturz auffangen, der tödlich sein soll.
##
## Drei Bänder: die Häuser dicht am Weg (ihre Dächer liegen knapp unter
## der Weghöhe und geben der Gasse eine Wand), ein mittleres Band tiefer,
## und ganz unten die Gassensohle. Erst das macht aus einer Leere neben
## dem Steg eine Stadt, in die man hinunterschaut.
func _altstadt_bauen() -> void:
	var wuerfel := randi()
	seed(25001)
	var putz := _lehmputz()
	var ton := _terrakotta()

	for i in 96:
		var s := randf_range(-16.0, M_ENDE + 16.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var lage := i % 3
		var nah: Array[float] = [9.0, 18.0, 34.0]
		var fern: Array[float] = [18.0, 34.0, 62.0]
		var quer: float = seite * randf_range(nah[lage], fern[lage])
		var dach: float = -1.2 - float(lage) * 2.6 - randf_range(0.0, 3.2)
		var breit := randf_range(5.0, 11.0)
		var tief := randf_range(5.0, 11.0)

		_sichtquader(s, quer, (dach + GASSENGRUND) * 0.5,
				Vector3(breit, dach - GASSENGRUND, tief), putz)
		# Dachbrüstung: der schmale Terrakottastreifen, der jedes Dach in
		# den Vorlagen umläuft. Er ist es, der die Altstadt lesbar macht –
		# ohne ihn sind es Kartons.
		_sichtquader(s, quer, dach + 0.25, Vector3(breit + 0.4, 0.5, tief + 0.4),
				ton)
		# Und jedes dritte Haus bekommt eine türkise Fensterreihe.
		if i % 3 == 0:
			_sichtquader(s, quer + seite * breit * 0.5, dach - 2.0,
					Vector3(0.3, 0.9, tief * 0.7),
					Materialbibliothek.einfarbig(TUERKIS, 0.5))

	# Die Gassensohle, tief unten. Sie schließt die Stadt nach unten ab.
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(300.0, 300.0)
	var boden := MeshInstance3D.new()
	boden.name = "Gassensohle"
	boden.mesh = flaeche
	boden.material_override = _dachsand()
	boden.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0,
			GASSENGRUND)
	geometrie.add_child(boden)
	seed(wuerfel)


## Ein reiner Sichtkörper ohne Kollision, relativ zum Verlauf gesetzt.
func _sichtquader(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, stoff: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var form := BoxMesh.new()
	form.size = groesse
	mi.mesh = form
	mi.material_override = stoff
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	mi.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(mi)
	return mi


## Ornamentale Bögen über dem Weg.
##
## `LevelWerkzeuge.torbogen()` setzt einen echten Halbkreis von Boden zu
## Boden. Jeder Bogen bekommt hier zusätzlich einen türkisen Scheitelstein
## – die Signalfarbe des Levels sitzt damit genau dort, wo der Blick beim
## Durchlaufen hängen bleibt.
func _boegen_bauen() -> void:
	var ton := _terrakotta()
	var zier := Materialbibliothek.einfarbig(TUERKIS, 0.4)
	for s: float in [14.0, 40.0, 58.0, 112.0, 176.0, 210.0, 244.0, 268.0,
			292.0, 314.0]:
		var breite := maxf(breite_bei(s), 7.0)
		if breite < 1.0:
			continue
		LevelWerkzeuge.torbogen(deko, verlauf, s, breite * 1.02, ton, 13, 0.0)
		_sichtquader(s, 0.0, breite * 0.52, Vector3(1.1, 0.5, 0.9), zier)


# =========================================================== Abschnitte

## 0–48 · Sandgasse. Die Frage: Wie hoch kommst du?
##
## Der Auftakt zeigt das Sprungteppich-Prinzip: `Kiste.Art.SPRUNG` ist
## eine unzerstörbare Feder mit `SPRUNG_ABPRALL = 20`, also deutlich mehr
## als der eigene Sprung (12,2). Wer sie nimmt, erreicht die höheren
## Dächer – und wer die höheren Dächer erreicht, findet dort Früchte.
## Damit ist der Sprungteppich von Anfang an als Werkzeug eingeführt und
## nicht als Hindernis.
func _sandgasse_bauen() -> void:
	var ton := _terrakotta()
	# Ein höheres Dach neben dem Weg, nur über die Feder erreichbar.
	plattform(20.0, -5.0, 3.2, Vector3(6.0, 0.8, 6.0), ton)
	plattform(30.0, 5.0, 4.0, Vector3(5.0, 0.8, 5.0), ton)
	# Zwei Trittstufen zurück auf den Weg – ein Aufstieg ohne Rückweg
	# wäre eine Sackgasse.
	plattform(25.0, -2.6, 1.6, Vector3(2.6, 0.6, 2.6), ton)
	plattform(35.0, 2.0, 1.4, Vector3(2.6, 0.6, 2.6), ton)

	stacheln(12.0, 1.6, Vector2(3.0, 2.4), false, TERRAKOTTA)
	stacheln(43.0, -1.6, Vector2(3.0, 2.6), true, TERRAKOTTA)
	stachelbalken(46.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.2))


## 48–106 · Hangelgasse. Die Frage: Kannst du hängend klein werden?
##
## Zwei Gitter über zwei Gassen. Unter jedem hängt ein Stachelbalken
## genau in dem schmalen Band zwischen baumelnden und angezogenen Beinen
## (Rechnung 1 im Kopf). Er lässt sich nicht überspringen und nicht
## unterlaufen – die einzige Antwort ist die Slide-Taste gehalten, also
## dieselbe Taste, die am Boden krabbeln lässt. Das ist der Sinn dieses
## Abschnitts: dieselbe Regel, andere Richtung. Wer hängt, wird OBEN
## schmal.
func _hangelgasse_bauen() -> void:
	hangelgitter(74.0, 0.0, GITTER_HOCH, 18.0, 2.2)
	stachelbalken(74.0, 0.0, 1.70, Vector2(5.0, 0.9), 0.23)

	hangelgitter(100.0, 0.0, GITTER_HOCH, 14.0, 2.2)
	# Beim zweiten Mal zwei Balken kurz hintereinander: Man muss die
	# Beine nicht nur anziehen, sondern angezogen HALTEN und dabei
	# weiterhangeln.
	stachelbalken(97.0, 0.0, 1.70, Vector2(4.4, 0.9), 0.23)
	stachelbalken(102.5, 0.0, 1.70, Vector2(4.4, 0.9), 0.23)

	# Auf den Dächern davor und dazwischen: Deckung und ein Feuerspeier,
	# damit die Gitter nicht die einzige Aufgabe sind.
	deckungsfleck(56.0, 2.2)
	feuerspeier(88.0, -3.0, 1.0, 0.0, 3.0, 0.0)


## 106–164 · Teppichflug. Die Frage: Springst du auf etwas, das fliegt?
##
## Zwei fliegende Teppiche über der Gasse. Sie sind `floss()` mit Kurve,
## folgen also dem Verlauf um die Biegung und fahren zurück – wer den
## Absprung verpasst, wartet, statt neu anfangen zu müssen.
##
## Der zweite Teppich ist kleiner und schneller, und über ihm hängt ein
## kurzes Gitter als Notausstieg: Wer daneben springt, kann sich noch
## fangen. Das ist die einzige Stelle, an der ein Gitter kein Weg,
## sondern eine zweite Chance ist.
func _teppichflug_bauen() -> void:
	var eins := floss(124.0, 136.0, 0.0, FLOSS_HOEHE, Vector2(4.4, 3.8),
			5.2, 1.8, 1.8)
	_teppich_anstrich(eins, TUERKIS)

	var neben := floss(126.0, 134.0, 4.8, FLOSS_HOEHE, Vector2(2.6, 2.6),
			3.6, 1.0, 1.0, 0.5)
	_teppich_anstrich(neben, ORNAMENT_WEISS)

	var zwei := floss(152.0, 162.0, 0.0, FLOSS_HOEHE, Vector2(3.6, 3.2),
			4.0, 1.2, 1.2, 0.25)
	_teppich_anstrich(zwei, LEHMROT)

	hangelgitter(157.0, 0.0, GITTER_HOCH, 9.0, 2.2)

	# Auf den Absätzen: je ein Sprungteppich, der zurück auf Weghöhe
	# bringt, und ein Balken, der den Anlauf bremst.
	stachelbalken(118.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))
	taktflaeche(144.0, 0.0, Vector2(3.0, 3.0), 0.0)


## 164–228 · Skorpiondecke. Die Frage: Schlägst du zu, während du hängst?
##
## Zwei Gitter, tiefer gehängt als die der Hangelgasse (2,70 statt 3,20 m)
## und breiter (2,6 statt 2,2 m). Beides ist Rechnung, nicht Geschmack –
## siehe Rechnung 2 im Kopf: Tiefer, damit der Drehschlag die Skorpione
## auf den Mauervorsprüngen erreicht; breiter, damit man ihnen auch quer
## ausweichen kann.
##
## Damit stellt der Abschnitt eine echte Wahl: schlagen und weiterhangeln,
## oder auf die andere Gitterseite wechseln und vorbeiziehen. Der
## Drehschlag ist schneller, das Ausweichen sicherer.
func _skorpiondecke_bauen() -> void:
	_skorpionsgasse(196.0, 18.0, [192.0, 200.0], [1.0, -1.0])
	_skorpionsgasse(221.0, 16.0, [218.0, 224.0], [-1.0, 1.0])

	# Auf dem festen Dach dazwischen ein Werfer und eine Taktwelle: Der
	# Abschnitt soll nicht nur aus Hängen bestehen.
	taktwelle(206.0, 212.0, 3, 0.0, Vector2(2.6, 2.6), 0.33)
	stachelbalken(186.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))
	deckungsfleck(180.0, -2.4)


## Ein Gitter über der Gasse, mit Mauervorsprüngen für die Skorpione.
##
## `seiten` gibt je Vorsprung an, auf welcher Seite er sitzt (+1 rechts,
## −1 links). Sie wechseln bewusst: Wer einmal auf die sichere Seite
## gewechselt ist, muss beim nächsten Skorpion wieder hinüber.
func _skorpionsgasse(mitte: float, laenge: float, stellen: Array,
		seiten: Array) -> void:
	hangelgitter(mitte, 0.0, GITTER_TIEF, laenge, GITTER_BREIT)
	for i in stellen.size():
		var s: float = stellen[i]
		var seite: float = seiten[i]
		# Der Vorsprung: eine Konsole aus der Gassenwand. Seine Oberkante
		# liegt bei 0,85 m – unter den Sohlen des Hangelnden (1,15 m), er
		# steht dem Hangeln also nicht im Weg.
		plattform(s, seite * SIMS_SEITLICH, SIMS_OBEN - 0.3,
				Vector3(2.8, 0.6, 3.2), _terrakotta())
		_skorpion(s, seite * SIMS_SEITLICH)


## Ein Deckenskorpion auf einem Mauervorsprung.
##
## Genommen ist die `Stelzenspinne`: hoher Leib auf langen Beinen, im
## Bild von unten genau die Silhouette, die ein Skorpion an der Wand
## abgibt. Sie wird hier auf `Angriff.SPIN` umgestellt – ihre Vorgabe
## (Slide und Bauchplatscher) hilft einem Hangelnden nicht weiter, der
## nur eine einzige Angriffsart hat. `besiegbar_durch` ist genau dafür
## als `@export` gedacht.
##
## Gesetzt wird ohne die Bauhilfe `gegner()`: Die begrenzt Ort und
## Patrouille auf die Wegbreite, und über einer Lücke ist die null.
func _skorpion(strecke: float, seitlich: float) -> Gegner:
	var g := STELZENSPINNE.instantiate() as Gegner
	g.besiegbar_durch = Angriff.SPIN
	g.patrouille_weite = 0.8
	g.tempo = 1.0
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized()
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, SIMS_OBEN)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


## 228–276 · Basar. Die Frage: Gedränge – wo ist überhaupt noch Platz?
##
## Der dichteste Abschnitt: Marktstände als Schiebeblöcke, Werfer mit
## Töpfen, Sprungteppiche zwischen den Ständen. Und hier steht die
## Treppe, die das Level seine eigene Regel brechen lässt (siehe Kopf und
## `_treppe_bauen()`).
func _basar_bauen() -> void:
	var ton := _terrakotta()
	# Marktstände: Sonnensegel über dem Weg, zwischen denen man
	# hindurchmuss.
	for i in 6:
		var s := 232.0 + float(i) * 7.0
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		_sichtquader(s, seite * 3.8, 2.7, Vector3(3.4, 0.16, 3.0),
				Materialbibliothek.einfarbig(
						TUERKIS if i % 2 == 0 else LEHMROT, 0.7))
		_sichtquader(s, seite * 3.8, 1.35, Vector3(0.16, 2.7, 0.16), ton)

	schiebeblock(238.0, -2.6, 0.0, Vector3(1.8, 1.2, 1.8), 3.6, true, 1.4, 1.0)
	schiebeblock(262.0, 2.6, 0.0, Vector3(1.8, 1.2, 1.8), 3.6, true, 1.4, 1.0,
			0.5)
	taktwelle(242.0, 256.0, 4, 2.6, Vector2(2.6, 2.6), 0.25)
	feuerspeier(270.0, -3.6, 1.0, 0.0, 3.4, 0.0, true)
	laufband(258.0, 266.0, -2.0, 0.06, 3.0, 2.2, 1)


## 276–322 · Kuppeln. Die Frage: alles noch einmal, im Hellen.
##
## Der Abschluss ist absichtlich der freundlichste Teil des Levels: weite
## Dächer, ein paar Kuppeln, kein einziger neuer Mechanismus. Nach der
## Skorpiondecke und dem Basar soll das Ende ein Auslaufen sein, kein
## letzter Prüfstein.
func _kuppeln_bauen() -> void:
	var ton := _terrakotta()
	var zier := Materialbibliothek.einfarbig(TUERKIS, 0.4)
	for stelle: Array in [[284.0, -7.6, 2.6], [298.0, 7.8, 3.0],
			[312.0, -7.2, 2.4]]:
		var s: float = stelle[0]
		var q: float = stelle[1]
		var r: float = stelle[2]
		var kuppel := MeshInstance3D.new()
		var form := SphereMesh.new()
		form.radius = r
		form.height = r * 1.7
		form.is_hemisphere = true
		kuppel.mesh = form
		kuppel.material_override = ton
		# Sie sitzen auf den Nachbardächern der Kulisse, nicht auf dem
		# Weg: Ein Sichtkörper ohne Kollision mitten im Weg wäre eine
		# Wand, durch die man hindurchläuft.
		kuppel.position = LevelWerkzeuge.punkt(verlauf, s, q, KUPPELDACH)
		deko.add_child(kuppel)
		_sichtquader(s, q, KUPPELDACH + r * 0.85 + 0.4,
				Vector3(0.3, 1.2, 0.3), zier)

	plattform(292.0, 0.0, 0.7, Vector3(4.0, 1.4, 4.0), ton)
	stacheln(304.0, 2.0, Vector2(3.0, 2.6), true, TERRAKOTTA)
	stachelbalken(308.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))


## Streicht ein Floß als fliegenden Teppich an.
##
## `Wasserplattform` nimmt ihre Farbe nur VOR `add_child()` an, die
## Bauhilfe `floss()` hängt sie aber selbst ein. Statt die Bauhilfe zu
## ändern, wird hier nachträglich das Material aller Sichtkörper
## überschrieben – ein Floß aus Baumstämmen wäre über einer Altstadtgasse
## ein Fremdkörper.
func _teppich_anstrich(teppich: Wasserplattform, farbe: Color) -> void:
	var stoff := Materialbibliothek.einfarbig(farbe, 0.85)
	var stapel: Array[Node] = [teppich]
	while not stapel.is_empty():
		var k: Node = stapel.pop_back()
		for kind in k.get_children():
			stapel.push_back(kind)
		if k is MeshInstance3D:
			(k as MeshInstance3D).material_override = stoff

	# Eine Borte rings um den Teppich, in der Gegenfarbe. Ohne sie ist er
	# eine einfarbige Platte; mit ihr sieht man von oben sofort, wo er
	# aufhört – und darauf kommt es beim Absprung an.
	var bild := teppich.get_node_or_null("Bild")
	if bild == null:
		return
	var borte := Materialbibliothek.einfarbig(ORNAMENT_WEISS, 0.7)
	var oben := Wasserplattform.DECK_STAERKE * 0.5 + 0.03
	var x := teppich.groesse.x * 0.5 + 0.05
	var z := teppich.groesse.y * 0.5 + 0.05
	var kanten := [
		[Vector3(teppich.groesse.x + 0.2, 0.08, 0.16), Vector3(0.0, oben, -z)],
		[Vector3(teppich.groesse.x + 0.2, 0.08, 0.16), Vector3(0.0, oben, z)],
		[Vector3(0.16, 0.08, teppich.groesse.y + 0.2), Vector3(-x, oben, 0.0)],
		[Vector3(0.16, 0.08, teppich.groesse.y + 0.2), Vector3(x, oben, 0.0)],
	]
	for kante: Array in kanten:
		var balken := MeshInstance3D.new()
		var form := BoxMesh.new()
		form.size = kante[0]
		balken.mesh = form
		balken.material_override = borte
		balken.position = kante[1]
		bild.add_child(balken)


# =========================================================== Der Regelbruch

## Die Treppe, die nicht explodiert.
##
## Fünf Kisten in Nitrogrün, frei über der Gasse gestaffelt, jede einen
## Meter höher als die vorige. Im ganzen übrigen Spiel heißt Nitrogrün:
## Berührung = Explosion. Diese fünf sind `Kiste.Art.EISEN` – sie
## explodieren nicht, sie tragen. Oben wartet eine Terrasse mit einer
## Extralebenkiste.
##
## Warum das funktioniert, ohne unfair zu sein: Es kostet nichts, sie
## NICHT zu benutzen. Der Weg geht daneben weiter. Wer sie betritt, hat
## vorher etwas bemerkt – dass ihr Zeichen nicht das Nitrozeichen ist,
## oder dass eine Nitrokiste nie schwebt. Genau darum geht es: Das Level
## bricht seine Regel einmal und belohnt den, der es merkt.
##
## Der Anstrich sitzt auf den Flächen der Kiste, nicht auf ihrer Art.
## Nach einem Tod baut `LevelBasis` die Kisten aus dem Bauplan neu auf –
## dann sind es wieder graue Eisenkisten. Deshalb hängt sich
## `_nach_aufbau()` an `GameState.level_zuruecksetzen` und streicht nach.
func _treppe_bauen() -> void:
	_treppenorte.clear()
	for stufe in TREPPE:
		var k := kiste(Kiste.Art.EISEN, float(stufe["strecke"]),
				float(stufe["seitlich"]), float(stufe["hoehe"]), true)
		_treppenorte.append(k.global_position)

	# Die Terrasse am Kopf der Treppe.
	plattform(259.0, -9.4, 5.4, Vector3(7.0, 0.7, 7.0), _terrakotta())
	kiste(Kiste.Art.LEBEN, 259.0, -9.4, 6.3)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 257.6, -10.6, 6.3)
	kiste(Kiste.Art.NORMAL, 260.4, -10.6, 6.3)
	kiste(Kiste.Art.NORMAL, 257.6, -8.2, 6.3)
	kiste(Kiste.Art.NORMAL, 260.4, -8.2, 6.3)
	fruechte_reihe(256.0, 262.0, 5, -9.4, 7.0)

	_treppe_streichen()


## Streicht alle Eisenkisten an den Treppenorten in Nitrogrün.
##
## Getroffen wird über den Ort, nicht über eine gemerkte Knotenkennung:
## Nach einem Tod sind es andere Knoten an denselben Stellen.
func _treppe_streichen() -> void:
	for k in get_tree().get_nodes_in_group("kisten"):
		var kasten := k as Kiste
		if kasten == null or kasten.art != Kiste.Art.EISEN:
			continue
		for ort in _treppenorte:
			if kasten.global_position.distance_to(ort) < 0.4:
				_nitro_anstrich(kasten)
				break


## Gibt einer Kiste das Aussehen einer Nitrokiste.
##
## Die Kiste baut ihr Netz in `_ready()` als EIN Mesh mit vier
## Materialflächen: Korpus, Rahmen, Beschläge, Zeichen. Überschrieben
## werden nur die ersten beiden – das Zeichen bleibt das der Eisenkiste
## und ist damit der ehrliche Hinweis für den, der genau hinsieht.
func _nitro_anstrich(kasten: Kiste) -> void:
	var korpus := kasten.get_node_or_null("Modell/Korpus") as MeshInstance3D
	if korpus == null or korpus.mesh == null:
		return
	var haut := Materialbibliothek.kistenholz(
			Farben.KISTE_NITRO).duplicate() as StandardMaterial3D
	haut.emission_enabled = true
	haut.emission = Farben.KISTE_NITRO
	haut.emission_energy_multiplier = 0.2
	korpus.set_surface_override_material(0, haut)
	if korpus.mesh.get_surface_count() > 1:
		korpus.set_surface_override_material(1,
				Materialbibliothek.kistenholz(Farben.KISTE_NITRO.darkened(0.55)))


func _nach_aufbau() -> void:
	GameState.level_zuruecksetzen.connect(_auf_neuaufbau)


func _auf_neuaufbau(_von_vorn: bool) -> void:
	# Aufgeschoben, weil `LevelBasis` die Kisten selbst erst aufgeschoben
	# neu aufstellt – vorher stünde an den Treppenorten noch nichts.
	_treppe_streichen.call_deferred()


# =========================================================== Stimmung

## Zwei Stimmungen, beide warm.
##
## Über den Gassen der Hangelabschnitte steht der Dunst etwas dichter und
## sandiger – dort schaut man am weitesten hinunter, und ohne Dunst wäre
## die Tiefe flach. Am Basar wird das Licht wärmer und satter: Der
## dichteste Abschnitt soll auch der farbigste sein.
func _stimmungen_setzen() -> void:
	stimmung(48.0, 164.0, SAND.lightened(0.15), 0.014, 1.15,
			Color(0.92, 0.84, 0.72), 56.0)
	stimmung(228.0, 276.0, TERRAKOTTA.lightened(0.25), 0.010, 1.25,
			Color(0.98, 0.82, 0.62), 56.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 5.0)


# =========================================================== Kisten

## 52 Kisten. Dazu kommen in `_treppe_bauen()` die fünf Stufen der
## Nitro-Treppe und die fünf auf der Terrasse darüber – 62 im Level.
##
## Über den Gassen steht keine: Eine Kiste auf einem Hangelgitter wäre
## nicht zu erreichen, und eine auf einem fliegenden Teppich ist ein
## bewegter StaticBody3D, auf dem es sich schlecht steht.
func _kisten_setzen() -> void:
	# ---------- Sandgasse ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.6)
	kiste(Kiste.Art.NORMAL, 9.0, -2.4)
	kiste(Kiste.Art.NORMAL, 9.0, 0.0)
	kiste(Kiste.Art.NORMAL, 9.0, 2.4)
	kiste(Kiste.Art.SPRUNG, 17.0, -3.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 20.0, -5.0, 4.1)
	kiste(Kiste.Art.SPRUNG, 27.0, 3.2)
	kiste(Kiste.Art.SCHUTZ, 30.0, 5.0, 4.9)
	kiste(Kiste.Art.NORMAL, 34.0, -2.2)
	kiste(Kiste.Art.EISEN, 39.0, 2.0)
	kiste(Kiste.Art.NORMAL, 39.0, 2.0, 1.6, true)
	kiste(Kiste.Art.NORMAL, 44.0, -0.6)

	# ---------- Hangelgasse: nur auf den Dächern ----------
	kiste(Kiste.Art.CHECKPOINT, 60.0, -2.4)
	kiste(Kiste.Art.NORMAL, 52.0, 2.2)
	kiste(Kiste.Art.NORMAL, 57.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 63.0, 2.2)
	kiste(Kiste.Art.NORMAL, 85.0, -2.2)
	kiste(Kiste.Art.NORMAL, 85.0, 2.2)
	kiste(Kiste.Art.SCHUTZ, 91.0, 0.0)

	# ---------- Teppichflug ----------
	kiste(Kiste.Art.CHECKPOINT, 118.0, -2.4)
	kiste(Kiste.Art.NORMAL, 110.0, 2.4)
	kiste(Kiste.Art.NORMAL, 114.0, -2.4)
	kiste(Kiste.Art.TNT, 121.0, 0.0)
	kiste(Kiste.Art.NORMAL, 141.0, -2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 145.0, 2.2)
	kiste(Kiste.Art.NORMAL, 148.0, 0.0)

	# ---------- Skorpiondecke ----------
	kiste(Kiste.Art.NORMAL, 168.0, -2.4)
	kiste(Kiste.Art.NORMAL, 168.0, 2.4)
	kiste(Kiste.Art.SCHUTZ, 174.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 180.0, 2.4)
	kiste(Kiste.Art.NORMAL, 184.0, -2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 208.0, 0.0)
	kiste(Kiste.Art.NORMAL, 211.0, -2.4)
	kiste(Kiste.Art.NORMAL, 211.0, 2.4)

	# ---------- Basar: hier ist Platz für Stapel ----------
	kiste(Kiste.Art.CHECKPOINT, 240.0, 0.0)
	kiste(Kiste.Art.NORMAL, 231.0, -3.0)
	kiste(Kiste.Art.NORMAL, 231.0, 3.0)
	kiste(Kiste.Art.EISEN, 246.0, 3.2)
	kiste(Kiste.Art.NORMAL, 246.0, 3.2, 1.6, true)
	kiste(Kiste.Art.NORMAL, 246.0, 3.2, 2.6, true)
	kiste(Kiste.Art.NITRO, 252.0, 0.0)
	kiste(Kiste.Art.NORMAL, 252.0, -2.6)
	kiste(Kiste.Art.SPRUNG, 258.0, 3.4)
	kiste(Kiste.Art.FEDER, 266.0, -3.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 272.0, 0.0)

	# ---------- Kuppeln ----------
	kiste(Kiste.Art.NORMAL, 280.0, -2.6)
	kiste(Kiste.Art.NORMAL, 280.0, 0.0)
	kiste(Kiste.Art.NORMAL, 280.0, 2.6)
	kiste(Kiste.Art.CHECKPOINT, 300.0, -2.4)
	kiste(Kiste.Art.SCHUTZ, 306.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 314.0, 0.0)
	kiste(Kiste.Art.NORMAL, 318.0, -2.2)


# =========================================================== Gegner

## 19 Gegner hier, dazu vier Skorpione – 23 im Level. Die Skorpione
## stehen nicht hier, sondern in
## `_skorpiondecke_bauen()`: Sie gehören zur Gasse, nicht zur Aufstellung –
## ihr Ort ist aus der Gitterhöhe gerechnet und keine Wahl.
##
## Die Werfer tragen Töpfe statt Stämmen – `Geschoss.Art.TOPF` ist genau
## dafür da und macht aus dem Waldwerfer den Affen auf dem Dach.
func _gegner_setzen() -> void:
	# ---------- Sandgasse ----------
	gegner(PANZERKAEFER, 11.0, -2.4, 4.0, true)
	gegner(SUMPFKROETE, 24.0, 2.0, 3.5, true)
	werfer(33.0, -4.0, Geschoss.Art.TOPF)
	gegner(STELZENSPINNE, 42.0, 0.0, 2.6, true)

	# ---------- Hangelgasse: auf den Dächern ----------
	gegner(SUMPFKROETE, 54.0, -1.6, 2.4, true)
	gegner(PANZERKAEFER, 62.0, 1.6, 2.4, true)
	gegner(STELZENSPINNE, 88.0, 0.0, 2.2, true)

	# ---------- Teppichflug ----------
	gegner(PANZERKAEFER, 112.0, -2.0, 2.8, true)
	werfer(119.0, 2.6, Geschoss.Art.TOPF)
	gegner(SUMPFKROETE, 144.0, 0.0, 2.2, true)

	# ---------- Skorpiondecke ----------
	gegner(PANZERKAEFER, 170.0, -2.0, 3.0, true)
	schwarm(182.0, 0.0, 10.0)
	gegner(SUMPFKROETE, 209.0, 0.0, 2.4, true)

	# ---------- Basar: die dichteste Stelle ----------
	gegner(PANZERKAEFER, 234.0, -3.0, 4.0, true)
	werfer(244.0, 4.0, Geschoss.Art.TOPF)
	gegner(SUMPFKROETE, 250.0, 2.6, 3.4, true)
	schwarm(264.0, -2.0, 10.0)
	gegner(STELZENSPINNE, 270.0, 2.4, 3.0, true)

	# ---------- Kuppeln ----------
	gegner(PANZERKAEFER, 296.0, 0.0, 3.5, true)


# =========================================================== Früchte

## Unter den Gittern liegen die Früchte auf Hangelhöhe: Die Spur zeigt
## an, wo entlang gehangelt wird, und ist damit die einzige Anleitung,
## die das Level für sein Kernbauteil braucht.
func _fruechte_setzen() -> void:
	fruechte_reihe(5.0, 44.0, 15, 0.0)
	fruechte_reihe(18.0, 22.0, 3, -5.0, 4.4)
	fruechte_reihe(28.0, 32.0, 3, 5.0, 5.2)
	fruechte_reihe(50.0, 64.0, 6, 0.0)
	# Gitter 1 und 2 (lichte Höhe 3,20 m, Sohlen bei 1,65 m)
	fruechte_reihe(67.0, 81.0, 7, 0.0, 1.9)
	fruechte_reihe(95.0, 105.0, 5, 0.0, 1.9)
	fruechte_reihe(108.0, 120.0, 6, 0.0)
	fruechte_reihe(124.0, 136.0, 6, 0.0, DECK + 0.9)
	fruechte_reihe(152.0, 162.0, 5, 0.0, DECK + 0.9)
	fruechte_reihe(166.0, 186.0, 8, 0.0)
	# Gitter 3 und 4 (lichte Höhe 2,70 m, Sohlen bei 1,15 m)
	fruechte_reihe(189.0, 203.0, 7, 0.0, 1.4)
	fruechte_reihe(215.0, 227.0, 6, 0.0, 1.4)
	fruechte_reihe(230.0, 274.0, 16, 0.0)
	fruechte_reihe(278.0, 318.0, 15, 0.0)
