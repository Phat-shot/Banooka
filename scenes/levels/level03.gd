extends KorridorLevel
## Level 03 – "Treibgut"
##
## Ein Fluss durch die Nebelsümpfe. Anders als der Bohlenweg in Level 07
## führt hier kein durchgehender Steg ans Ziel: Zwei lange Abschnitte
## haben überhaupt keinen Boden, dort trägt ein Treibfloß den Spieler.
##
## Der Verlauf lebt vom Wechsel. Laufen, fahren, laufen, fahren – und
## jeder Wechsel ändert, worauf man achten muss:
##
##   Zu Fuß  – wohin springe ich, und was steht mir im Weg?
##   Auf dem Floß – der Weg läuft von allein, die Frage ist nur noch,
##                  wie ich dem ausweiche, was auf mich zukommt.
##
## Das Floß nimmt der Figur die Steuerung NICHT ab: Sie läuft, springt,
## dreht und krabbelt weiter wie sonst, nur eben auf einem Boden, der
## sich bewegt. Deshalb braucht dieses Level keinen zweiten Controller
## wie die Level 04 bis 06.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  26  Anlegestelle  fester Torfgrund, alle Werkzeuge einmal geübt
##    26 –  60  Trittpfähle   Seerosen und Pfahlinseln über offenem Wasser
##    60 – 102  Treibfahrt I  kein Boden; Floß, hängende Minen, Stachelbalken
##   102 – 124  Wehr          Bohlen, die im Takt untertauchen
##   124 – 162  Schilfgasse   schmaler Steg, Gegner, Kisten seitlich im Wasser
##   162 – 192  Treibfahrt II zweite Fahrt, enger und schneller
##   192 – 218  Anhöhe        trockener Grund, Extraleben, Zielportal
##
## Die Wasserfläche ist tödlich. Sie liegt dicht unter dem Weg, damit ein
## Fehltritt sofort zu sehen ist; die Absturzzone darunter ist nur der
## Notnagel für den Fall, dass jemand seitlich daran vorbeifällt.

const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# Strecken-Marken der Abschnitte
const M_ANLEGER := 0.0
const M_PFAEHLE := 26.0
const M_FAHRT1 := 60.0
const M_WEHR := 102.0
const M_SCHILF := 124.0
const M_FAHRT2 := 162.0
const M_ANHOEHE := 192.0
const M_ENDE := 218.0

# Höhen relativ zum Weg
const WASSER_HOEHE := -0.55    ## Wasserspiegel, dicht unter dem Steg
const MOORGRUND := -2.6        ## sichtbarer Grund unter dem Wasser
const ABSTURZ := -3.4          ## Notnagel unterhalb des Wassers

## Mittelhöhe eines Floßdecks. Die Stämme liegen damit halb im Wasser,
## und die Oberkante (`DECK`) endet knapp über dem Wasserspiegel.
const FLOSS_HOEHE := -0.42
## Höhe, auf der der Spieler auf einem Floß steht. Alles, was auf der
## Fahrt über ihm hängt, wird von hier aus gemessen.
const DECK := FLOSS_HOEHE + Wasserplattform.DECK_STAERKE * 0.5
## Wehrbohlen oben und unten. Unten steht das Deck unter dem Wasser –
## genau darin liegt die Drohung.
const BOHLE_OBEN := -0.30
const BOHLE_UNTEN := -1.45

## Höhe, in der ein Stachelbalken das Gehen sperrt, das Krabbeln aber
## nicht. Die aufrechte Kapsel ist 1,30 m hoch, die flache 0,76 m.
const KRIECHHOEHE := 0.95

const FLOSS_GROESSE := Vector2(4.6, 3.4)


const STRECKE := [
	# --- Anlegestelle: breiter Torfgrund zum Üben ---
	{"von": 0.0, "bis": 26.0, "breite": 11.0, "breite_ende": 9.0},
	# --- Trittpfähle: zwei Pfahlinseln, dazwischen offenes Wasser ---
	{"von": 32.0, "bis": 39.0, "breite": 7.0},
	{"von": 45.0, "bis": 52.0, "breite": 7.0},
	# --- Anleger I: hier legt das erste Floß an ---
	{"von": 55.0, "bis": 60.0, "breite": 8.0},
	# --- 60 bis 96: Treibfahrt I, kein Boden ---
	{"von": 96.0, "bis": 102.0, "breite": 8.0},
	# --- 102 bis 124: Wehr, nur Bohlen ---
	{"von": 124.0, "bis": 156.0, "breite": 6.5, "breite_ende": 7.5},
	{"von": 156.0, "bis": 162.0, "breite": 8.0},
	# --- 162 bis 192: Treibfahrt II, kein Boden ---
	{"von": 192.0, "bis": 218.0, "breite": 11.0},
]


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Fluss wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Moorgrund", "tun": _grund_bauen},
		{"text": "Stege und Anleger", "tun": _boden_bauen},
		{"text": "Wasser steigt", "tun": _wasser_fluten},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Seerosen treiben auf", "tun": _seerosen_setzen},
		{"text": "Flöße werden losgemacht", "tun": _floesse_setzen},
		{"text": "Wehr wird eingehängt", "tun": _wehr_bauen},
		{"text": "Minen und Stachelbalken", "tun": _hindernisse_setzen},
		{"text": "Sumpfwald", "tun": _wald_bauen},
		{"text": "Schilf und Farne", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Der Fluss macht eine große Schleife. Die beiden Fahrten liegen bewusst
## in den Biegungen: Weil das Floß dem Verlauf folgt, dreht sich auf der
## Fahrt das ganze Bild, und die Strecke wirkt länger, als sie ist.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),
		Vector3(0, 0, -14),
		Vector3(7, 0, -31),        # Rechtsbogen ins Moor
		Vector3(21, -0.2, -42),
		Vector3(39, -0.2, -45),    # Trittpfähle
		Vector3(57, -0.2, -40),
		Vector3(71, -0.2, -28),    # Treibfahrt I, weite Biegung
		Vector3(79, -0.2, -12),
		Vector3(78, 0.2, 6),       # Wehr
		Vector3(69, 0.6, 21),
		Vector3(54, 0.9, 30),      # Schilfgasse
		Vector3(36, 1.1, 31),
		Vector3(19, 1.8, 24),      # Treibfahrt II
		Vector3(7, 3.0, 12),       # Anstieg zur Anhöhe
	])


# =========================================================== Boden

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.bohlen(),
		"kante": Materialbibliothek.algen(),
		"klippe": Materialbibliothek.moorboden(),
	}, {"tiefe": 2.4, "schritt": 1.0, "kante_hoehe": 0.24, "kante_breite": 0.6})
	# Die Pfosten an den Lückenrändern sind hier mehr als Warnung: An den
	# Anlegern lesen sie sich als Poller, an denen das Floß festmacht.
	luecken_markieren(Farben.BOHLE.darkened(0.3))


## Der Grund unter dem Wasser. Reine Kulisse – wer hineinfällt, ertrinkt
## vorher.
func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(260.0, 260.0)
	var mi := MeshInstance3D.new()
	mi.name = "Moorgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.moorboden()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.45, 0.0, MOORGRUND)
	geometrie.add_child(mi)


## Wasser längs des ganzen Laufs. In Stücken, weil eine einzige Platte
## der Schleife nicht folgen könnte.
func _wasser_fluten() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ANHOEHE - 4.0:
		var w := wasser(s + schritt * 0.5, Vector2(52.0, schritt + 2.0),
				WASSER_HOEHE)
		w.tiefe = 2.0
		w.toedlich = true
		w.wellen_hoehe = 0.08
		w.wellen_tempo = 0.6
		# Trübes Standwasser statt klarem Blau, und kaum Schimmer. Erst
		# damit heben sich Stege, Flöße und Blätter überhaupt vom Grund ab.
		w.farbe_tief = Farben.TUEMPEL
		w.farbe_hell = Farben.TUEMPEL_HELL
		w.spiegelung = 0.18
		s += schritt


func _absturz_spannen() -> void:
	absturzzonen(18.0, 66.0)


# =========================================================== Auf dem Wasser

## Seerosen als Trittsteine in den Lücken, und ein paar als Beiwerk.
##
## In jeder Lücke der Trittpfähle liegt genau ein Blatt in der Mitte: Die
## Lücke ist 6 m breit, ein Sprung trägt gut 5 m – ohne Blatt wäre sie
## nicht zu schaffen, mit Blatt sind es zwei bequeme Sprünge.
func _seerosen_setzen() -> void:
	seerose(29.0, 0.0, FLOSS_HOEHE, 2.6)
	seerose(42.0, -0.8, FLOSS_HOEHE, 2.6)
	seerose(53.5, 0.9, FLOSS_HOEHE, 2.4)

	# Am Wehr: feste Blätter zwischen den tauchenden Bohlen, damit die
	# Stelle ein Rhythmus bleibt und kein reines Glücksspiel.
	seerose(110.0, 2.6, FLOSS_HOEHE, 2.2)
	seerose(117.0, -2.6, FLOSS_HOEHE, 2.2)

	# Beiwerk am Rand, rein fürs Bild.
	for paar in [[36.0, 5.4], [48.0, -5.8], [108.0, -6.2], [131.0, 5.6],
			[144.0, -5.4], [176.0, 6.4], [184.0, -6.0]]:
		var blatt := seerose(paar[0], paar[1], WASSER_HOEHE + 0.06,
				randf_range(1.6, 2.6))
		blatt.farbe = Farben.ALGE.darkened(randf_range(0.0, 0.25))


## Die beiden Treibflöße.
##
## Beide fahren hin und zurück. Das ist Absicht: Wer den Absprung
## verpasst, wartet ein paar Sekunden, statt den Abschnitt zu verlieren.
func _floesse_setzen() -> void:
	# Fahrt I: lang und ruhig – hier lernt man, dass sich der Boden bewegt.
	floss(62.0, 94.0, 0.0, FLOSS_HOEHE, FLOSS_GROESSE, 13.0, 3.0, 3.0)
	# Fahrt II: kürzer und schneller, dafür mit mehr im Weg.
	floss(164.0, 190.0, 0.0, FLOSS_HOEHE, Vector2(4.0, 3.0), 9.0, 2.6, 2.6)

	# Ein zweites, kleines Floß auf Fahrt I, gegenläufig gestartet: Es
	# fährt zurück, während das große vorwärts fährt. Wer will, wechselt
	# unterwegs hinüber und kommt an die Kisten am Rand.
	var nebenfloss := floss(70.0, 88.0, 3.4, FLOSS_HOEHE,
			Vector2(2.6, 2.4), 8.0, 1.4, 1.4)
	nebenfloss.phase = 0.5


## Das Wehr: sechs Bohlen, die versetzt untertauchen.
##
## Der Versatz ist der ganze Trick. Wären alle gleichzeitig oben, wäre es
## ein Steg; wären sie zufällig, wäre es Glück. Versetzt ergibt sich eine
## Welle, die vor dem Spieler herläuft – er muss ihr folgen.
func _wehr_bauen() -> void:
	var stellen := [104.0, 108.0, 112.0, 116.0, 120.0, 123.0]
	var seiten := [0.0, -1.4, 1.2, -1.0, 1.4, 0.0]
	for i in stellen.size():
		wehrbohle(stellen[i], seiten[i], BOHLE_OBEN, BOHLE_UNTEN,
				float(i) * 0.17)


## Was auf den Fahrten im Weg hängt.
##
## Zwei Arten, und sie verlangen Verschiedenes:
##   Stachelbalken – hängt quer über der ganzen Rinne. Nur Krabbeln hilft.
##   Hängemine     – schwingt quer über das Deck. Zur Seite gehen hilft,
##                   Krabbeln auch, denn sie hängt über Kopfhöhe.
##
## Vor der ersten Fahrt steht ein Übungsbalken auf festem Grund: Wer dort
## stehen bleibt, kassiert einen Treffer und weiß Bescheid – auf der
## Fahrt über dem Wasser wäre dieselbe Lehre teurer.
func _hindernisse_setzen() -> void:
	# Übung an Land
	stachelbalken(21.0, 0.0, KRIECHHOEHE, Vector2(5.0, 1.0))

	# --- Treibfahrt I ---
	stachelbalken(72.0, 0.0, DECK + KRIECHHOEHE, Vector2(6.0, 1.1))
	stachelbalken(86.0, 0.0, DECK + KRIECHHOEHE, Vector2(6.0, 1.1))
	treibmine(67.0, 1.6, DECK + 0.75, 1.8, 3.4, 0.0, 3.2)
	treibmine(78.0, -1.6, DECK + 0.75, 1.8, 3.0, 0.35, 3.2)
	treibmine(82.0, 1.4, DECK + 0.75, 1.6, 2.6, 0.6, 3.2)
	treibmine(91.0, 0.0, DECK + 0.75, 2.2, 3.8, 0.15, 3.2)

	# --- Wehr: schwimmende Minen zwischen den Bohlen ---
	treibmine(106.0, 2.2, WASSER_HOEHE + 0.3)
	treibmine(114.0, -2.4, WASSER_HOEHE + 0.3, 1.4, 4.4, 0.25)
	treibmine(121.0, 2.0, WASSER_HOEHE + 0.3, 1.2, 3.6, 0.5)

	# --- Treibfahrt II: enger getaktet ---
	stachelbalken(170.0, 0.0, DECK + KRIECHHOEHE, Vector2(5.4, 1.1))
	stachelbalken(180.0, 0.0, DECK + KRIECHHOEHE, Vector2(5.4, 1.1))
	stachelbalken(187.0, 0.0, DECK + KRIECHHOEHE, Vector2(5.4, 1.1))
	treibmine(167.0, -1.3, DECK + 0.75, 1.5, 2.4, 0.0, 3.0)
	treibmine(174.0, 1.3, DECK + 0.75, 1.5, 2.2, 0.4, 3.0)
	treibmine(177.0, -1.3, DECK + 0.75, 1.5, 2.2, 0.8, 3.0)
	treibmine(184.0, 0.0, DECK + 0.75, 1.9, 2.8, 0.2, 3.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 4.0)


# =========================================================== Kisten

## Eine Kiste auf einem Seerosenblatt im Wasser.
##
## Sie steht abseits des sicheren Weges – wer sie will, muss vom Floß
## oder vom Steg herüberspringen und wieder zurück. Genau dafür sind die
## Blätter da: Sie machen das Abseits erreichbar, ohne es zu verschenken.
func kiste_auf_wasser(art: Kiste.Art, strecke: float,
		seitlich: float) -> Kiste:
	seerose(strecke, seitlich, FLOSS_HOEHE, 2.2)
	return kiste(art, strecke, seitlich, DECK + 0.5)


func _kisten_setzen() -> void:
	# ---------- Anlegestelle: jedes Werkzeug einmal ----------
	kiste(Kiste.Art.NORMAL, 6.0, -1.6)
	kiste(Kiste.Art.NORMAL, 6.0, 0.0)
	kiste(Kiste.Art.NORMAL, 6.0, 1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 11.0, 0.0)
	kiste(Kiste.Art.CHECKPOINT, 15.0, -2.4)
	kiste(Kiste.Art.EISEN, 18.0, 1.8)
	kiste(Kiste.Art.NORMAL, 18.0, 1.8, 1.6)
	kiste(Kiste.Art.SCHUTZ, 24.0, -1.4)

	# ---------- Trittpfähle ----------
	kiste(Kiste.Art.NORMAL, 34.0, 0.0)
	kiste(Kiste.Art.NORMAL, 37.0, -1.4)
	kiste_auf_wasser(Kiste.Art.FRUCHT_MEHRFACH, 41.0, 3.6)
	kiste(Kiste.Art.FEDER, 47.0, 0.0)
	kiste(Kiste.Art.NORMAL, 50.0, 1.4)
	kiste(Kiste.Art.CHECKPOINT, 57.0, -2.0)
	kiste(Kiste.Art.NORMAL, 58.5, 1.8)

	# ---------- Treibfahrt I: alles seitlich der Rinne ----------
	# Auf dem Floß selbst steht nichts – ein bewegter Boden voller Kisten
	# nähme genau den Platz weg, den man zum Ausweichen braucht.
	kiste_auf_wasser(Kiste.Art.NORMAL, 69.0, -4.2)
	kiste_auf_wasser(Kiste.Art.NORMAL, 76.0, 4.4)
	kiste_auf_wasser(Kiste.Art.SCHUTZ, 84.0, -4.4)
	kiste_auf_wasser(Kiste.Art.NORMAL, 90.0, 4.2)

	# ---------- Anleger II ----------
	kiste(Kiste.Art.CHECKPOINT, 98.0, -2.2)
	kiste(Kiste.Art.NORMAL, 99.5, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 101.0, 2.0)

	# ---------- Schilfgasse ----------
	kiste(Kiste.Art.NORMAL, 127.0, 0.0)
	kiste(Kiste.Art.NORMAL, 130.0, -1.4)
	kiste(Kiste.Art.TNT, 134.0, 1.2)
	kiste(Kiste.Art.NORMAL, 134.0, -1.2)
	kiste(Kiste.Art.CHECKPOINT, 138.0, -1.8)
	kiste_auf_wasser(Kiste.Art.NORMAL, 141.0, 5.2)
	kiste(Kiste.Art.SPRUNG, 145.0, 0.0)
	kiste(Kiste.Art.NORMAL, 149.0, 1.4)
	kiste(Kiste.Art.TNT, 153.0, -1.0)
	kiste(Kiste.Art.NORMAL, 158.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 160.5, -2.0)

	# ---------- Treibfahrt II ----------
	kiste_auf_wasser(Kiste.Art.NORMAL, 172.0, -4.0)
	kiste_auf_wasser(Kiste.Art.NORMAL, 179.0, 4.0)
	# Zwei Nitro-Kisten dicht an der Rinne, jede auf ihrem Blatt. Das Floß
	# ist 4,0 m breit, die Kisten stehen bei ±2,8 m: Die Durchfahrt ist
	# frei, aber schmal. Wer hier hektisch ausweicht, weicht in eine hinein.
	kiste_auf_wasser(Kiste.Art.NITRO, 188.0, -2.8)
	kiste_auf_wasser(Kiste.Art.NITRO, 188.0, 2.8)

	# ---------- Anhöhe ----------
	kiste(Kiste.Art.NORMAL, 196.0, -2.0)
	kiste(Kiste.Art.NORMAL, 196.0, 0.0)
	kiste(Kiste.Art.NORMAL, 196.0, 2.0)
	kiste(Kiste.Art.LEBEN, 202.0, 0.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 207.0, -1.8)
	kiste(Kiste.Art.NORMAL, 211.0, 1.6)


# =========================================================== Gegner

## Gegner stehen nur dort, wo fester Boden ist.
##
## Auf den Fahrten wäre ein patrouillierender Gegner unfair: Er stünde
## still im Raum, während der Boden unter dem Spieler wegfährt – kein
## Können, nur Pech. Dort übernehmen Minen und Balken.
func _gegner_setzen() -> void:
	# ---------- Anlegestelle: Draufspringen auf sicherem Grund ----------
	gegner(PANZERKAEFER, 10.0, 0.0, 3.5, true)
	gegner(PANZERKAEFER, 23.0, -1.2, 2.5, true)

	# ---------- Trittpfähle: Drehschlag auf engem Stand ----------
	gegner(SUMPFKROETE, 35.0, 0.0, 2.0, true)
	gegner(SUMPFKROETE, 48.0, 0.0, 2.0, true)

	# ---------- Anleger II ----------
	gegner(PANZERKAEFER, 100.0, 0.0, 2.0, true)

	# ---------- Schilfgasse: die dichteste Stelle des Levels ----------
	gegner(STELZENSPINNE, 129.0, -1.2, 2.6, true)
	gegner(SUMPFKROETE, 136.0, 0.8, 2.4, true)
	gegner(STELZENSPINNE, 143.0, -0.8, 2.8, true)
	gegner(STELZENSPINNE, 151.0, 1.0, 2.6, true)
	gegner(SUMPFKROETE, 159.0, 0.0, 2.2, true)

	# ---------- Anhöhe ----------
	gegner(SUMPFKROETE, 200.0, 2.0, 3.0, true)
	gegner(PANZERKAEFER, 209.0, -1.6, 3.0, true)


# =========================================================== Früchte

## Früchte führen den Blick. Auf den Fahrten liegen sie tiefer als sonst,
## weil der Spieler dort auf dem Floßdeck steht und nicht auf dem Weg.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 20.0, 8, 0.0)
	fruechte_bogen(26.5, 31.5, 5, 0.0, 2.2)
	fruechte_reihe(33.0, 38.0, 4, 0.0)
	fruechte_bogen(39.5, 44.5, 5, -0.8, 2.2)
	fruechte_reihe(46.0, 51.0, 4, 0.0)
	fruechte_bogen(52.5, 54.5, 3, 0.9, 1.6)

	# Fahrt I: eine Spur mittig, damit man beim Ausweichen nicht vergisst,
	# wo die Rinne ist.
	fruechte_reihe(63.0, 93.0, 12, 0.0, DECK + 0.9)
	fruechte_reihe(70.0, 88.0, 5, 3.4, DECK + 0.9)

	fruechte_reihe(97.0, 101.0, 3, 0.0)
	# Wehr: die Früchte sitzen über den Bohlen und zeigen den Takt an.
	fruechte_bogen(103.0, 124.0, 9, 0.0, 1.8)

	fruechte_reihe(126.0, 154.0, 10, 0.0)
	fruechte_reihe(157.0, 161.0, 3, 0.0)

	fruechte_reihe(165.0, 189.0, 10, 0.0, DECK + 0.9)
	fruechte_reihe(194.0, 214.0, 9, 0.0)


# =========================================================== Kulisse

## Sumpfwald: kahle Stämme im Wasser, dazwischen einzelne Kronen. Auf
## Höhe der Fahrten stehen sie weiter draußen – die Rinne bleibt frei,
## sonst nähmen sie auf der Fahrt die Sicht nach vorn.
func _wald_bauen() -> void:
	var wuerfel := randi()
	seed(30311)
	for i in 74:
		var s := randf_range(-6.0, M_ENDE + 6.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var frei := _fahrt_hier(s)
		var quer := seite * randf_range(9.0 if frei else 7.0, 27.0)
		var totholz := i % 3 == 0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if totholz else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(5.0, 12.0)
		baum.staerke = randf_range(0.6, 1.1)
		baum.saat = 4200 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.ALGE, randf())
		baum.kollision = false
		var fuss := WASSER_HOEHE - 0.4 if s < M_ANHOEHE else -0.2
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, fuss)
		deko.add_child(baum)
	seed(wuerfel)


## Liegt diese Stelle in einem der beiden Fahrtabschnitte?
func _fahrt_hier(strecke: float) -> bool:
	return (strecke > M_FAHRT1 and strecke < M_WEHR) \
			or (strecke > M_FAHRT2 and strecke < M_ANHOEHE)


## Schilf am Ufer, Farne auf festem Grund, Wurzeln aus dem Wasser.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(30312)

	# Schilfhorste. Auf den Fahrten säumen sie die Rinne und machen sie
	# überhaupt erst als Rinne lesbar – deshalb stehen sie dort weiter
	# draußen und niedriger. Dicht am Floß nähmen sie die Sicht nach vorn,
	# und genau die braucht man, um den Hindernissen auszuweichen.
	for i in 58:
		var s := randf_range(2.0, M_ANHOEHE)
		var rand := rand_bei(s, 0.4)
		var frei := _fahrt_hier(s)
		var abstand := rand + randf_range(0.6, 3.0) if rand >= 1.0 \
				else randf_range(5.0, 8.5)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.position = LevelWerkzeuge.punkt(verlauf, s, seite * abstand,
				WASSER_HOEHE + 0.1)
		horst.flaeche = Vector2(2.4, 2.4) if frei else Vector2(3.0, 3.0)
		horst.halm_hoehe = randf_range(0.5, 0.85) if frei \
				else randf_range(0.7, 1.3)
		horst.farbe_unten = Farben.ALGE.darkened(0.35)
		horst.farbe_oben = Farben.SCHILF
		horst.saat = 5200 + i
		deko.add_child(horst)

	# Farne und Pilze auf dem festen Grund
	for i in 28:
		var s: float = randf_range(2.0, 24.0) if i % 2 == 0 \
				else randf_range(M_ANHOEHE, M_ENDE - 4.0)
		var rand := rand_bei(s, 0.9)
		if rand < 1.2:
			continue
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 3 == 0 else Kleinzeug.Art.FARN
		kleinzeug.saat = 6200 + i
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(kleinzeug)

	# Wurzeln, die aus dem Wasser greifen
	for i in 24:
		var s := randf_range(M_PFAEHLE, M_ANHOEHE)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate()
		if "saat" in w:
			w.set("saat", 8200 + i)
		w.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(5.0, 13.0), WASSER_HOEHE - 0.2)
		w.rotation.y = randf() * TAU
		deko.add_child(w)
	seed(wuerfel)
