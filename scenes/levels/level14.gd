extends KorridorLevel
## Level 14 – "Wolkensteg"
##
## Eine Seilbrücke über einem Wolkenmeer. Zwei Planken breit, kein
## Geländer, das trägt, keine Deckung, keine Verzweigung – und vor allem:
## KEIN Boden unter dem Boden. Wer danebentritt, ist weg.
##
## Das ist das Angstlevel der Reihe, und seine Angst kommt nicht von
## Gegnern, sondern von der Sicht: Der Nebel ist dicht und fast weiß, und
## unter dem Steg ist deshalb buchstäblich nichts zu sehen. Man weiß nicht,
## wie tief es ist. Genau das soll man nicht wissen.
##
##     0 –  34  Ankerfels      der letzte feste Grund, breit und ruhig
##    34 –  96  Erste Planken  Bruchplatten: die Planke trägt nur kurz
##    96 – 150  Rutschsteg     blankes Eis auf zwei Planken, SEITENANSICHT
##   150 – 204  Trittkäfer     Gegner als Absprunghilfe über weite Lücken
##   204 – 250  Windbruch      Böen schieben quer, Planken brechen
##   250 – 280  Gipfelanker    fester Fels, das Ziel
##
## Die eine Regel, die das Level einmal selbst bricht: Bei 134 m hängt
## unter dem Steg doch ein Sims. Wer die Nerven hat, absichtlich neben die
## Planken zu springen, findet dort ein Extraleben und eine Sprungfeder
## zurück nach oben. Einmal, nie zweimal – sonst wäre die Grundangst des
## Levels entwertet.
##
## Der Kontrast trägt alles – aber GESCHICHTET, nicht flächig. Der fast
## weiße Dunst (#CED1D6) liegt HINTER dem Spielgeschehen; davor steht der
## Steg in voller Sättigung (Seilbeige, Holzplanken, türkis und blau
## bemalte Pfostenköpfe), und dunkle Felszacken rahmen den unteren
## Bildrand. Die Zacken sind dabei nicht Zierde, sondern Bedingung: Ohne
## sie hätte das Weiß nichts, wogegen es hell wäre – ein Bild aus lauter
## Weiß ist nicht kontrastreich, es ist nur hell.

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const GLETSCHERKRABBE := preload("res://scenes/enemies/Gletscherkrabbe.tscn")
const FROSTMOTTE := preload("res://scenes/enemies/Frostmotte.tscn")
const EISFLAECHE := preload("res://scenes/hazards/Eisflaeche.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")

# --- Farben ---------------------------------------------------------
# Gemessen am Vorbild (doku/level-vorbilder.md, 3-4). `Farben` kennt
# diese Grauabstufungen nicht; sie stehen deshalb lokal.
const WOLKENWEISS := Color(0.808, 0.820, 0.839)   # #CED1D6
const PFOSTENHOLZ := Color(0.263, 0.251, 0.212)   # #434036
const FELSGRAU := Color(0.639, 0.627, 0.639)      # #A3A0A3
const SEILBEIGE := Color(0.616, 0.478, 0.290)     # #9D7A4A
const DUNSTHELL := Color(0.757, 0.733, 0.706)     # #C1BBB4
const STEGHOLZ := Color(0.694, 0.518, 0.310)      # #B1844F
## Die Rahmenzacken. Zwei Töne, weil eine einzige Farbe eine Wand ergibt
## und keine Tiefe: der nahe Fels dunkel und warm, der ferne schon halb
## im Dunst.
const ZACKENNAH := Color(0.180, 0.129, 0.106)     # #2E211B
const ZACKENFELS := Color(0.325, 0.243, 0.204)    # #533E34
const ZACKENFERN := Color(0.549, 0.463, 0.435)    # #8C766F
## Die bemalten Pfostenköpfe. Türkis und Blau sind im Vorbild die einzigen
## kalten Töne im ganzen Bild – gerade deshalb sieht man sie im Weiß.
const KOPF_TUERKIS := Color(0.106, 0.549, 0.541)  # #1B8C8A
const KOPF_BLAU := Color(0.267, 0.431, 0.549)     # #446E8C

# --- Streckenmarken -------------------------------------------------
const M_ANKERFELS := 0.0
const M_PLANKEN := 34.0
const M_RUTSCHSTEG := 96.0
const M_TRITTKAEFER := 150.0
const M_WINDBRUCH := 204.0
const M_GIPFEL := 250.0
const M_ENDE := 280.0

## Flach gehalten: Unter dem Steg ist nichts, ein tieferer Wert würde den
## Sturz nur in die Länge ziehen. Das Sims bei 134 m liegt mit -2,6 m
## bewusst ÜBER dieser Grenze – sonst wäre die Belohnung ein Todesurteil.
const ABSTURZ := -4.0

## Oberkante des Simses unter dem Steg.
const SIMS_HOEHE := -2.6

## Höhe, unter der nur Krabbeln durchkommt.
const KRIECHHOEHE := 0.95

## Der Steg. Zwei Planken breit heißt hier 4,4 m – schmaler als jeder
## andere Abschnitt des Spiels; nur die beiden Anker sind breit.
const STRECKE := [
	# --- Ankerfels ---
	{"von": 0.0, "bis": 34.0, "breite": 13.0, "breite_ende": 6.0},
	# --- Erste Planken: kurze feste Stücke, dazwischen Bruchplatten ---
	{"von": 34.0, "bis": 44.0, "breite": 4.6},
	{"von": 52.0, "bis": 60.0, "breite": 4.6},
	{"von": 70.0, "bis": 78.0, "breite": 4.6},
	{"von": 88.0, "bis": 96.0, "breite": 4.6},
	# --- Rutschsteg ---
	{"von": 96.0, "bis": 108.0, "breite": 5.0},
	{"von": 116.0, "bis": 130.0, "breite": 5.0},
	{"von": 138.0, "bis": 150.0, "breite": 5.0},
	# --- Trittkäfer ---
	{"von": 150.0, "bis": 162.0, "breite": 5.2},
	{"von": 172.0, "bis": 184.0, "breite": 5.2},
	{"von": 194.0, "bis": 204.0, "breite": 5.2},
	# --- Windbruch ---
	{"von": 204.0, "bis": 214.0, "breite": 4.4},
	{"von": 222.0, "bis": 232.0, "breite": 4.4},
	{"von": 240.0, "bis": 250.0, "breite": 4.4},
	# --- Gipfelanker ---
	{"von": 250.0, "bis": 280.0, "breite": 9.0, "breite_ende": 15.0},
]

## Die beiden Anker sind Fels, alles dazwischen ist Holz. Zwei Aufrufe,
## weil `korridor()` je Aufruf nur EINEN Materialsatz kennt.
const BODEN_FELS := [
	{"von": 0.0, "bis": 34.0, "breite": 13.0, "breite_ende": 6.0},
	{"von": 250.0, "bis": 280.0, "breite": 9.0, "breite_ende": 15.0},
]
const BODEN_STEG := [
	{"von": 34.0, "bis": 44.0, "breite": 4.6},
	{"von": 52.0, "bis": 60.0, "breite": 4.6},
	{"von": 70.0, "bis": 78.0, "breite": 4.6},
	{"von": 88.0, "bis": 96.0, "breite": 4.6},
	{"von": 96.0, "bis": 108.0, "breite": 5.0},
	{"von": 116.0, "bis": 130.0, "breite": 5.0},
	{"von": 138.0, "bis": 150.0, "breite": 5.0},
	{"von": 150.0, "bis": 162.0, "breite": 5.2},
	{"von": 172.0, "bis": 184.0, "breite": 5.2},
	{"von": 194.0, "bis": 204.0, "breite": 5.2},
	{"von": 204.0, "bis": 214.0, "breite": 4.4},
	{"von": 222.0, "bis": 232.0, "breite": 4.4},
	{"von": 240.0, "bis": 250.0, "breite": 4.4},
]


## Zwischenspeicher der Zackenanstriche – zwei Töne, aber ein paar hundert
## Kegel; ohne ihn stünde je Kegel ein eigenes Material im Speicher.
var _zackenstoffe: Dictionary = {}


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Der Steg wird gespannt", "tun": _verlauf_anlegen},
		{"text": "Wolkenmeer", "tun": _wolkenmeer_bauen},
		{"text": "Anker und Planken", "tun": _boden_bauen},
		{"text": "Pfosten und Seile", "tun": _seilgelaender_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Felszacken", "tun": _horizont_bauen},
		{"text": "Rahmenzacken am Bildrand", "tun": _rahmenzacken_bauen},
		{"text": "Erste Planken", "tun": _planken_bauen},
		{"text": "Rutschsteg", "tun": _rutschsteg_bauen},
		{"text": "Das Sims unter dem Steg", "tun": _sims_bauen},
		{"text": "Trittkäfer", "tun": _trittkaefer_bauen},
		{"text": "Windbruch", "tun": _windbruch_bauen},
		{"text": "Gipfelanker", "tun": _gipfel_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Dunst", "tun": _stimmungen_setzen},
		{"text": "Kulisse auf den Ankern", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Rein linear – zwei weite Bögen, sonst geradeaus.
##
## Der Steg hängt in der Mitte um dreieinhalb Meter durch und steigt zum
## Gipfelanker wieder an. Das Durchhängen ist nicht Zierde: Wer auf der
## abfallenden Hälfte steht, sieht den Steg vor sich weiterlaufen; wer auf
## der steigenden steht, sieht ihn im Weiß verschwinden. Dieselbe Brücke
## erzählt so zwei verschiedene Dinge, je nachdem, wo man gerade ist.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0.0, 0.00, 8.0),
		Vector3(0.3, -0.13, 0.7),
		Vector3(0.8, -0.33, -6.6),
		Vector3(1.4, -0.58, -13.9),
		Vector3(2.2, -0.86, -21.2),
		Vector3(3.4, -1.15, -28.5),
		Vector3(5.0, -1.45, -35.8),
		Vector3(6.9, -1.76, -43.1),
		Vector3(9.1, -2.05, -50.4),
		Vector3(11.7, -2.34, -57.7),
		Vector3(14.6, -2.61, -65.0),
		Vector3(17.6, -2.85, -72.3),
		Vector3(20.6, -3.07, -79.6),
		Vector3(23.7, -3.25, -86.9),
		Vector3(26.5, -3.40, -94.2),
		Vector3(29.1, -3.51, -101.5),
		Vector3(31.2, -3.57, -108.8),
		Vector3(32.8, -3.60, -116.1),
		Vector3(33.8, -3.58, -123.4),
		Vector3(34.2, -3.53, -130.7),
		Vector3(33.8, -3.43, -138.0),
		Vector3(32.8, -3.29, -145.3),
		Vector3(31.0, -3.11, -152.6),
		Vector3(28.6, -2.91, -159.9),
		Vector3(25.6, -2.67, -167.2),
		Vector3(22.2, -2.41, -174.5),
		Vector3(18.4, -2.13, -181.8),
		Vector3(14.3, -1.83, -189.1),
		Vector3(10.2, -1.53, -196.4),
		Vector3(6.1, -1.22, -203.7),
		Vector3(2.2, -0.93, -211.0),
		Vector3(-1.5, -0.65, -218.3),
		Vector3(-4.7, -0.39, -225.6),
		Vector3(-7.6, -0.17, -232.9),
		Vector3(-9.9, 0.24, -240.2),
		Vector3(-11.8, 1.09, -247.5),
		Vector3(-13.2, 1.93, -254.8),
		Vector3(-14.1, 2.77, -262.1),
		Vector3(-14.6, 3.61, -269.4),
		Vector3(-14.8, 4.45, -276.7),
		Vector3(-14.8, 5.29, -284.0),
	])


# =========================================================== Grund

func _boden_bauen() -> void:
	var form := {"tiefe": 1.4, "schritt": 0.9,
			"kante_hoehe": 0.16, "kante_breite": 0.45}
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_FELS, {
		"oben": Materialbibliothek.firn(),
		"kante": Materialbibliothek.einfarbig(FELSGRAU, 0.95),
		"klippe": Materialbibliothek.einfarbig(PFOSTENHOLZ.lightened(0.12), 1.0),
	}, form)
	# Die Planken sind flach: `tiefe` 0,9 statt der üblichen 2,8. Ein
	# dicker Klippenrand sähe aus wie eine Mauer und nähme dem Steg genau
	# das, was ihn ausmacht – dass er dünn ist.
	LevelWerkzeuge.korridor(geometrie, verlauf, BODEN_STEG, {
		"oben": Materialbibliothek.kistenholz(STEGHOLZ),
		"kante": Materialbibliothek.kistenholz(PFOSTENHOLZ),
		"klippe": Materialbibliothek.kistenholz(PFOSTENHOLZ),
	}, {"tiefe": 0.9, "schritt": 0.8,
			"kante_hoehe": 0.14, "kante_breite": 0.4})
	luecken_markieren(PFOSTENHOLZ)


## Pfosten und Seile längs des Stegs.
##
## Ohne Kollision und mit Absicht: Das Geländer TRÄGT nicht, es zeigt nur
## an, wo der Steg ist. Im weißen Dunst ist eine helle Planke gegen einen
## hellen Himmel kaum zu sehen – die dunklen Pfosten sind das Einzige,
## woran das Auge den Weg festhält. Genau daher kommt der Kontrast des
## Vorbilds: fast weiß gegen fast schwarz.
func _seilgelaender_bauen() -> void:
	var holz := Materialbibliothek.einfarbig(PFOSTENHOLZ, 0.95)
	var seil := Materialbibliothek.einfarbig(SEILBEIGE, 0.9)
	var kopf := [Materialbibliothek.einfarbig(KOPF_TUERKIS, 0.6),
			Materialbibliothek.einfarbig(KOPF_BLAU, 0.6)]
	var zaehler := 0
	for eintrag in BODEN_STEG:
		var von: float = eintrag["von"]
		var bis: float = eintrag["bis"]
		var s := von + 1.0
		while s < bis - 0.5:
			var halb := breite_bei(s) * 0.5 - 0.25
			for seite: float in [-1.0, 1.0]:
				var pfahl := BoxMesh.new()
				pfahl.size = Vector3(0.22, 1.35, 0.22)
				var mi := MeshInstance3D.new()
				mi.mesh = pfahl
				mi.material_override = holz
				mi.position = LevelWerkzeuge.punkt(verlauf, s, seite * halb, 0.6)
				mi.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
				deko.add_child(mi)
				# Der bemalte Pfostenkopf. Er ist klein und trägt nichts –
				# aber er ist der einzige kalte Fleck im Bild, und im
				# weißen Dunst zieht ihn das Auge sofort heraus. Ohne ihn
				# ist der Steg eine graue Linie in einer grauen Fläche.
				var haube := BoxMesh.new()
				haube.size = Vector3(0.34, 0.26, 0.34)
				var kappe := MeshInstance3D.new()
				kappe.mesh = haube
				kappe.material_override = kopf[zaehler % 2]
				kappe.position = LevelWerkzeuge.punkt(verlauf, s,
						seite * halb, 1.40)
				kappe.rotation.y = mi.rotation.y
				deko.add_child(kappe)
				# Zwei Seile zwischen diesem Pfosten und dem nächsten.
				if s + 4.0 < bis - 0.5:
					_seilstueck(s, s + 4.0, seite * halb, 1.15, seil)
					_seilstueck(s, s + 4.0, seite * halb, 0.62, seil)
			zaehler += 1
			s += 4.0


## Ein durchhängendes Seilstück zwischen zwei Pfosten.
func _seilstueck(von: float, bis: float, seitlich: float, hoehe: float,
		stoff: Material) -> void:
	var teile := 4
	for i in teile:
		var t := (float(i) + 0.5) / float(teile)
		var durchhang := sin(t * PI) * 0.16
		var s := lerpf(von, bis, t)
		var stueck := BoxMesh.new()
		stueck.size = Vector3(0.12, 0.12, (bis - von) / float(teile) + 0.05)
		var mi := MeshInstance3D.new()
		mi.mesh = stueck
		mi.material_override = stoff
		mi.position = LevelWerkzeuge.punkt(verlauf, s, seitlich,
				hoehe - durchhang)
		mi.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		deko.add_child(mi)


## Das Wolkenmeer: zwei sehr große, unbeleuchtete Scheiben weit unter dem
## Steg. Sie sind reine Kulisse und liegen bewusst tiefer als die
## Absturzzone – niemand landet je auf ihnen.
func _wolkenmeer_bauen() -> void:
	for i in 2:
		var flaeche := PlaneMesh.new()
		flaeche.size = Vector2(900.0, 900.0)
		var stoff := StandardMaterial3D.new()
		stoff.albedo_color = WOLKENWEISS if i == 0 else DUNSTHELL
		stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var mi := MeshInstance3D.new()
		mi.name = "Wolkenmeer%d" % i
		mi.mesh = flaeche
		mi.material_override = stoff
		mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0,
				-26.0 - float(i) * 14.0)
		deko.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(10.0, 76.0)


## Dunkle Felszacken am Horizont – der einzige feste Punkt im Weiß.
func _horizont_bauen() -> void:
	horizont(320.0, 44.0, Color(0.34, 0.33, 0.31), Color(0.62, 0.62, 0.63),
			false, -22.0)


## Die Rahmenzacken: dunkle Felsspitzen, die von unten ins Bild ragen.
##
## Sie sind der Grund, warum das Weiß dieses Levels überhaupt als hell
## gelesen wird. Ein Bild aus lauter Weiß hat keinen Kontrast, es hat nur
## Helligkeit – erst eine dunkle Silhouette am unteren Bildrand gibt dem
## Dunst etwas, wogegen er hell sein kann. Das Vorbild hat den stärksten
## Kontrast der Reihe, und er kommt genau daher: geschichtet, nicht flächig.
##
## Sie stehen paarweise links und rechts des Stegs, nie darunter: In der
## Mitte wären sie eine Andeutung von Grund, und dieses Level darf keinen
## Grund andeuten. Aus demselben Grund tragen sie keine Kollision und ihre
## Spitzen enden mindestens einen Meter unter der Planke – wer neben den
## Steg tritt, fällt an ihnen vorbei.
func _rahmenzacken_bauen() -> void:
	var wuerfel := randi()
	seed(14900)
	# Drei Ringe je Seite, von innen nach außen: {Abstand vom Steg,
	# Spitzenhöhe, Zackenhöhe, Dicke}. Der innerste rahmt den unteren
	# Bildrand, die beiden äußeren staffeln sich dahinter – erst dadurch
	# wird aus einer Silhouette eine Landschaft.
	var ringe := [
		{"quer": Vector2(4.6, 7.0), "spitze": Vector2(-6.0, -10.0),
			"hoehe": Vector2(7.0, 11.0), "dicke": Vector2(2.6, 4.2),
			"farbe": ZACKENNAH, "jedes": 1},
		{"quer": Vector2(9.5, 16.0), "spitze": Vector2(-10.0, -16.0),
			"hoehe": Vector2(10.0, 15.0), "dicke": Vector2(3.4, 5.6),
			"farbe": ZACKENFELS, "jedes": 1},
		{"quer": Vector2(22.0, 44.0), "spitze": Vector2(-18.0, -28.0),
			"hoehe": Vector2(16.0, 26.0), "dicke": Vector2(5.0, 9.0),
			"farbe": ZACKENFERN, "jedes": 2},
	]
	var s := -10.0
	var i := 0
	while s < M_ENDE + 16.0:
		# Immer beide Seiten: Ein Rahmen, der nur links steht, ist kein
		# Rahmen, sondern eine Wand – und genau so sah der erste Versuch
		# aus, der die Seiten abwechselnd besetzte.
		for seite: float in [-1.0, 1.0]:
			for ring: Dictionary in ringe:
				if i % int(ring["jedes"]) != 0:
					continue
				var q: Vector2 = ring["quer"]
				var sp: Vector2 = ring["spitze"]
				var ho: Vector2 = ring["hoehe"]
				var di: Vector2 = ring["dicke"]
				_felszacke(s + randf_range(-6.0, 6.0),
						seite * randf_range(q.x, q.y),
						randf_range(sp.x, sp.y), randf_range(ho.x, ho.y),
						randf_range(di.x, di.y), ring["farbe"])
		s += randf_range(15.0, 21.0)
		i += 1
	seed(wuerfel)


## Eine einzelne Zacke: ein schlanker Kegel mit abgesetztem Sockel.
##
## Zwei Kegel statt einem, weil ein einzelner Kegel wie ein Hütchen
## aussieht; der breitere Sockel darunter macht daraus einen Felsdorn.
## `spitze` ist die Höhe der Spitze über dem Weg – sie ist negativ, die
## Zacke ragt also von unten herein und hört unter dem Steg auf.
func _felszacke(strecke: float, seitlich: float, spitze: float,
		hoehe: float, dicke: float, farbe: Color) -> void:
	# Unbeleuchtet und ohne Nebeleinfluss. Beides absichtlich: Eine
	# beleuchtete Zacke bekommt von der weißen Umgebung eine helle
	# Sonnenseite, und der Dunst zieht sie vollends ins Weiß – am Ende
	# stünden dort blasse Hütchen statt Silhouetten. Die Zacke ist aber
	# kein Gegenstand, den man betrachtet, sondern ein Scherenschnitt vor
	# dem Dunst. Gestaffelte Tiefe macht hier die Farbe, nicht der Nebel.
	var stoff := _scherenschnitt(farbe)
	# Drei gestapelte Kegelstümpfe, von unten nach oben schlanker: unten,
	# Mitte, Spitze. Ein einzelner Kegel ergibt ein Hütchen; erst der Knick
	# zwischen den Stücken macht daraus einen Felsdorn. Je Zeile:
	# Radius unten, Radius oben, Höhe, Mitte über der Spitze.
	var teile := [
		[dicke * 1.0, dicke * 0.62, hoehe * 0.45, -hoehe * 0.825],
		[dicke * 0.60, dicke * 0.30, hoehe * 0.32, -hoehe * 0.44],
		[dicke * 0.31, 0.0, hoehe * 0.28, -hoehe * 0.14],
	]
	for teil: Array in teile:
		var kegel := CylinderMesh.new()
		kegel.bottom_radius = teil[0]
		kegel.top_radius = teil[1]
		kegel.height = teil[2]
		kegel.radial_segments = 6
		kegel.rings = 0
		var mi := MeshInstance3D.new()
		mi.mesh = kegel
		mi.material_override = stoff
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Jedes Stück ein wenig versetzt und verdreht – eine lotrechte
		# Reihe gleicher Kegel liest sich als Zaun, nicht als Fels.
		mi.position = LevelWerkzeuge.punkt(verlauf, strecke,
				seitlich + randf_range(-0.3, 0.3), spitze + teil[3])
		mi.rotation.y = randf() * TAU
		mi.rotation.z = randf_range(-0.07, 0.07)
		mi.scale = Vector3(1.0, 1.0, randf_range(0.75, 1.3))
		deko.add_child(mi)


## Unbeleuchteter, nebelfreier Anstrich für die Rahmenzacken.
##
## Steht hier und nicht in der `Materialbibliothek`: Sie ist gemeinsames
## Gut, und ein Stoff, der den Nebel abschaltet, taugt nur für dieses eine
## Level – überall sonst wäre er ein Fehler, der lange unbemerkt bliebe.
func _scherenschnitt(farbe: Color) -> StandardMaterial3D:
	if not _zackenstoffe.has(farbe):
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.disable_fog = true
		_zackenstoffe[farbe] = m
	return _zackenstoffe[farbe]


# =========================================================== Abschnitte

## 34–96 · Erste Planken. Die Frage dieses Abschnitts ist nicht "reicht
## der Sprung", sondern "reicht die ZEIT": Jede Platte wackelt, kippt und
## fällt. Wer stehen bleibt, um zu zielen, steht auf nichts mehr.
##
## Die Reihen werden von Lücke zu Lücke länger und die Platten kleiner.
func _planken_bauen() -> void:
	bruchplatten_reihe(45.5, 50.5, 3, 0.0, -0.14, Vector2(2.6, 2.6))
	bruchplatten_reihe(61.5, 68.5, 4, 0.0, -0.14, Vector2(2.4, 2.4))
	# Ab hier versetzt: Die Platten liegen abwechselnd links und rechts,
	# der Weg wird zum Zickzack.
	for i in 4:
		var s := lerpf(79.5, 86.5, float(i) / 3.0)
		bruchplatte(s, -1.1 if i % 2 == 0 else 1.1, -0.14,
				Vector2(2.2, 2.2))
	# Ein Balken über der letzten festen Planke: krabbeln, während die
	# nächste Platte schon wartet.
	stachelbalken(92.0, 0.0, KRIECHHOEHE, Vector2(4.4, 1.0))


## 96–150 · Rutschsteg. Blankes Eis auf zwei Planken. Auf dem Eis greift
## nichts, und der Steg hat keinen Rand, der einen aufhält – wer zu
## schnell hineinläuft, rutscht seitlich hinaus.
##
## Hier liegt auch die Kamerazone: Von hinten ist eine Lücke über einem
## weißen Nichts gar nicht zu schätzen, von der Seite schon.
func _rutschsteg_bauen() -> void:
	for stelle: float in [100.0, 105.0, 120.0, 126.0, 142.0, 147.0]:
		var flaeche := EISFLAECHE.instantiate() as Eisflaeche
		flaeche.flaeche = Vector2(4.2, 4.4)
		flaeche.glaette = 0.9
		flaeche.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, 0.02)
		flaeche.rotation.y = LevelWerkzeuge.drehung(verlauf, stelle)
		objekte.add_child(flaeche)
	bruchplatten_reihe(109.5, 114.5, 3, 0.0, -0.14, Vector2(2.4, 2.4))
	bruchplatten_reihe(131.5, 136.5, 3, 0.0, -0.14, Vector2(2.4, 2.4))
	# Zwei Böen über dem Eis: schieben genau dort, wo nichts greift.
	schiebeblock(123.0, 0.0, 0.0, Vector3(1.3, 1.2, 1.3), 2.6, true, 1.5, 1.1)
	schiebeblock(145.0, 0.0, 0.0, Vector3(1.3, 1.2, 1.3), 2.6, true, 1.5, 1.1,
			0.5)


## Das Sims: die eine Stelle, an der das Level seine eigene Regel bricht.
##
## Sechzig Meter lang hat es behauptet, unter dem Steg sei nichts. Hier
## stimmt das nicht – zweieinhalb Meter tiefer und sieben Meter seitlich
## hängt ein Felssims mit einem Extraleben darauf. Es liegt ÜBER der
## Absturzgrenze (-4,0 m), der Sprung dorthin ist also sicher, sobald man
## ihn wagt. Zurück geht es über die Sprungfeder.
##
## Genau einmal im Level, nie zweimal: Wäre es zweimal so, hörte der
## Spieler auf, dem Nichts unter dem Steg zu glauben – und damit wäre der
## Grundgedanke des Levels dahin.
func _sims_bauen() -> void:
	var fels := Materialbibliothek.einfarbig(FELSGRAU, 0.95)
	var seit := -7.0
	plattform(134.0, seit, SIMS_HOEHE - 0.4, Vector3(6.0, 0.8, 7.0), fels)
	# Ein schmaler Tritt auf halbem Weg hinaus – ohne ihn wäre der Sprung
	# geraten statt gewagt.
	plattform(134.0, -3.6, SIMS_HOEHE + 0.5, Vector3(1.8, 0.5, 1.8), fels)
	kiste(Kiste.Art.LEBEN, 134.0, seit, SIMS_HOEHE + 0.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 132.0, seit - 1.6, SIMS_HOEHE + 0.5)
	kiste(Kiste.Art.NORMAL, 136.0, seit + 1.6, SIMS_HOEHE + 0.5)
	kiste(Kiste.Art.SPRUNG, 131.0, seit + 1.0, SIMS_HOEHE + 0.5)
	for i in 5:
		frucht(132.0 + float(i) * 1.0, seit, SIMS_HOEHE + 1.4)


## 150–204 · Trittkäfer. Drei Lücken, die zu weit sind – bis auf den
## Käfer, der mitten darin auf einem Pfosten sitzt.
##
## Hier ist der Gegner Werkzeug statt Feind: Wer von oben auf ihn tritt,
## wird höher abgeworfen als jeder eigene Sprung trägt. Das ist ein
## Hindernis mit zwei Rollen, und es kostet nichts extra.
func _trittkaefer_bauen() -> void:
	_trittpfosten(167.0, 0.0, 17.5)
	_trittpfosten(186.5, -1.4, 17.0)
	_trittpfosten(190.5, 1.4, 18.0)
	# Auf dem festen Stück davor steht einer zum Üben – dort ist ein
	# Fehlversuch kein Sturz.
	_trittpfosten(157.0, 1.6, 17.5)
	bruchplatten_reihe(163.0, 165.0, 2, 0.0, -0.14, Vector2(2.4, 2.4))
	bruchplatten_reihe(169.0, 171.0, 2, 0.0, -0.14, Vector2(2.4, 2.4))
	feuerspeier(180.0, -3.0, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(199.0, 3.0, 1.0, 180.0, 3.2, 0.4)


## Käfer auf einem einzelnen Pfosten mitten in der Lücke.
##
## Er wird von Hand gesetzt, nicht über `gegner()`: In einer Lücke ist die
## Wegbreite null, und `gegner()` würde ihn deshalb auf die Wegmitte
## zwingen und ohne Boden stehen lassen. Position und Patrouillenweite
## müssen VOR `add_child` stehen – `Gegner._ready()` merkt sich seinen
## Startplatz und zöge ihn sonst im ersten Bild dorthin zurück.
func _trittpfosten(strecke: float, seitlich: float,
		abprall := 17.0) -> Gegner:
	plattform(strecke, seitlich, -0.55, Vector3(2.4, 1.1, 2.4),
			Materialbibliothek.kistenholz(PFOSTENHOLZ))
	_pfostenschaft(strecke, seitlich)
	var g := PANZERKAEFER.instantiate() as Gegner
	g.patrouille_weite = 0.0
	g.abprall_hoehe = abprall
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.05)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


## Der Schaft unter einem Pfosten – er verschwindet nach unten im Dunst.
func _pfostenschaft(strecke: float, seitlich: float) -> void:
	var schaft := BoxMesh.new()
	schaft.size = Vector3(0.5, 9.0, 0.5)
	var mi := MeshInstance3D.new()
	mi.mesh = schaft
	mi.material_override = Materialbibliothek.einfarbig(PFOSTENHOLZ, 0.95)
	mi.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, -5.6)
	mi.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	deko.add_child(mi)


## 204–250 · Windbruch. Der schmalste Steg des Levels (4,4 m), und
## gleichzeitig fährt in jedem Abschnitt eine Bö quer darüber.
##
## Der Block ist schmal genug, dass links oder rechts von ihm immer noch
## gut ein Meter Planke frei bleibt – aber nur einer, und der wechselt die
## Seite. Wer nicht mitgeht, wird geschoben, und geschoben werden heißt
## hier fallen.
func _windbruch_bauen() -> void:
	schiebeblock(208.0, 0.0, 0.0, Vector3(1.4, 1.3, 1.4), 2.8, true, 1.3, 0.8)
	schiebeblock(212.0, 0.0, 0.0, Vector3(1.4, 1.3, 1.4), 2.8, true, 1.3, 0.8,
			0.5)
	bruchplatten_reihe(215.5, 220.5, 3, 0.0, -0.14, Vector2(2.2, 2.2))

	schiebeblock(226.0, 0.0, 0.0, Vector3(1.4, 1.3, 1.4), 2.8, true, 1.1, 0.7,
			0.25)
	taktwelle(228.0, 231.0, 2, 0.0, Vector2(2.4, 2.4), 0.4)
	for i in 4:
		var s := lerpf(233.5, 238.5, float(i) / 3.0)
		bruchplatte(s, -1.0 if i % 2 == 0 else 1.0, -0.14, Vector2(2.0, 2.0))

	schiebeblock(244.0, 0.0, 0.0, Vector3(1.4, 1.3, 1.4), 2.8, true, 1.0, 0.6)
	laserzaun(247.0, 4.4, true, 1.1)


## 250–280 · Gipfelanker. Fester Fels, breiter Grund, kein Abgrund mehr.
## Nach zweihundertfünfzig Metern ohne Rand ist das die eigentliche
## Belohnung – und deshalb steht hier auch nichts Gefährliches.
func _gipfel_bauen() -> void:
	var fels := Materialbibliothek.einfarbig(FELSGRAU, 0.95)
	# Zwei Findlinge als Sicht- und Sprungmarken.
	plattform(258.0, -4.6, 0.9, Vector3(3.2, 1.8, 3.2), fels)
	plattform(266.0, 4.8, 1.2, Vector3(3.4, 2.4, 3.4), fels)
	frucht(258.0, -4.6, 2.6)
	frucht(266.0, 4.8, 3.2)


## Die Seitenansicht liegt genau dort, wo es nur um Sprungweiten geht.
##
## Über einem weißen Nichts ist eine Lücke von hinten nicht zu schätzen:
## Es fehlt jeder Anhaltspunkt, weil unten kein Boden ist, an dem das Auge
## die Entfernung ablesen könnte. Von der Seite ist sie einfach zu sehen.
func _kamerazonen_setzen() -> void:
	kamerazone(98.0, 148.0, -16.0, 3.0)


## Der Dunst.
##
## Die Grundstimmung steht in der Szene (Level14.tscn) und ist bereits
## dicht; hier wird sie nur noch abgestuft: Am Ankerfels ist die Luft
## etwas klarer, über der Mitte des Stegs am dichtesten, am Gipfel reißt
## sie wieder auf. Damit hat das Level einen Anfang, eine Mitte und ein
## Ende, ohne dass sich die Form ändert.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 36.0, Color(0.86, 0.87, 0.89), 0.018, 1.05,
			Color(0.84, 0.86, 0.90), 44.0)
	stimmung(90.0, 160.0, Color(0.90, 0.91, 0.93), 0.018, 1.05,
			Color(0.90, 0.92, 0.95), 44.0)
	stimmung(252.0, M_ENDE, Color(0.82, 0.84, 0.88), 0.018, 1.05,
			Color(0.82, 0.85, 0.90), 48.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 4.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Ankerfels: der einzige Ort mit Platz ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -2.6)
	kiste(Kiste.Art.NORMAL, 8.0, -2.2)
	kiste(Kiste.Art.NORMAL, 8.0, 0.0)
	kiste(Kiste.Art.NORMAL, 8.0, 2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 13.0, 0.0)
	kiste(Kiste.Art.EISEN, 18.0, 2.4)
	kiste(Kiste.Art.NORMAL, 18.0, 2.4, 1.6)
	kiste(Kiste.Art.SCHUTZ, 23.0, -2.2)
	kiste(Kiste.Art.NORMAL, 28.0, 1.4)
	kiste(Kiste.Art.NORMAL, 32.0, -1.2)

	# ---------- Erste Planken: nur je eine Kiste je festem Stück ----------
	kiste(Kiste.Art.NORMAL, 37.0, 0.0)
	kiste(Kiste.Art.NORMAL, 42.0, -1.0)
	kiste(Kiste.Art.CHECKPOINT, 58.0, -1.2)
	kiste(Kiste.Art.NORMAL, 58.0, 1.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 73.0, 0.0)
	kiste(Kiste.Art.NORMAL, 76.0, -1.2)
	kiste(Kiste.Art.SCHUTZ, 90.0, 1.2)
	kiste(Kiste.Art.NORMAL, 94.0, -1.2)

	# ---------- Rutschsteg: alles auf den eisfreien Enden ----------
	kiste(Kiste.Art.NORMAL, 98.0, 1.4)
	kiste(Kiste.Art.NORMAL, 107.0, -1.4)
	kiste(Kiste.Art.CHECKPOINT, 120.0, 1.4)
	kiste(Kiste.Art.NORMAL, 129.0, -1.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 140.0, 1.4)
	kiste(Kiste.Art.NORMAL, 149.0, -1.4)

	# ---------- Trittkäfer ----------
	kiste(Kiste.Art.NORMAL, 152.0, -1.4)
	kiste(Kiste.Art.SCHUTZ, 160.0, 1.4)
	kiste(Kiste.Art.CHECKPOINT, 180.0, -1.4)
	kiste(Kiste.Art.NORMAL, 182.0, 1.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 196.0, 0.0)
	kiste(Kiste.Art.NORMAL, 202.0, -1.4)

	# ---------- Windbruch ----------
	kiste(Kiste.Art.NORMAL, 206.0, 1.2)
	kiste(Kiste.Art.NORMAL, 213.0, -1.2)
	kiste(Kiste.Art.TNT, 224.0, 0.0)
	kiste(Kiste.Art.NORMAL, 231.0, 1.2)
	kiste(Kiste.Art.CHECKPOINT, 246.0, -1.2)
	kiste(Kiste.Art.NORMAL, 249.0, 1.2)

	# ---------- Gipfelanker ----------
	kiste(Kiste.Art.NORMAL, 254.0, -2.4)
	kiste(Kiste.Art.NORMAL, 254.0, 0.0)
	kiste(Kiste.Art.NORMAL, 254.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 262.0, -2.0)
	kiste(Kiste.Art.LEBEN, 270.0, 0.0)
	kiste(Kiste.Art.NORMAL, 275.0, -3.0)
	kiste(Kiste.Art.NORMAL, 275.0, 3.0)


# =========================================================== Gegner

## Fast keine Gegner im üblichen Sinn – das ist Absicht und stammt vom
## Vorbild: Die Schwierigkeit steckt allein in der Abfolge der Lücken.
##
## Die vier Käfer auf den Pfosten stehen in `_trittkaefer_bauen()`; sie
## sind Werkzeug, nicht Feind. Was hier steht, sind die wenigen echten
## Gegner: Krabben auf den beiden Ankern, wo Platz zum Ausweichen ist, und
## Frostmotten über dem Steg, denen man NICHT ausweichen kann – die
## einzige Stelle, an der der Drehschlag über dem Nichts gebraucht wird.
func _gegner_setzen() -> void:
	# ---------- Ankerfels ----------
	gegner(GLETSCHERKRABBE, 11.0, -2.0, 4.0, true)
	gegner(FROSTMOTTE, 20.0, 1.6, 3.4, true)
	gegner(GLETSCHERKRABBE, 30.0, 0.0, 2.0, true)

	# ---------- Erste Planken ----------
	gegner(FROSTMOTTE, 40.0, 0.0, 1.2, true)
	gegner(FROSTMOTTE, 74.0, 0.0, 1.2, true)

	# ---------- Rutschsteg ----------
	gegner(FROSTMOTTE, 103.0, 0.0, 1.2, true)
	gegner(GLETSCHERKRABBE, 124.0, 0.0, 1.2, true)
	gegner(FROSTMOTTE, 145.0, 0.0, 1.2, true)

	# ---------- Trittkäfer ----------
	gegner(FROSTMOTTE, 176.0, 0.0, 1.4, true)
	gegner(GLETSCHERKRABBE, 199.0, 0.0, 1.2, true)

	# ---------- Windbruch ----------
	gegner(FROSTMOTTE, 210.0, 0.0, 1.0, true)
	gegner(FROSTMOTTE, 242.0, 0.0, 1.0, true)

	# ---------- Gipfelanker ----------
	gegner(GLETSCHERKRABBE, 260.0, -2.0, 4.0, true)
	gegner(FROSTMOTTE, 272.0, 2.0, 3.6, true)


# =========================================================== Früchte

## Über jeder Lücke ein Bogen. Im weißen Dunst ist die Früchtekette oft
## das Erste, was vom nächsten Steg zu sehen ist – sie ist hier weniger
## Belohnung als Wegweiser.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 32.0, 10, 0.0)
	fruechte_bogen(44.0, 52.0, 5, 0.0, 2.4)
	fruechte_reihe(53.0, 59.0, 3, 0.0)
	fruechte_bogen(60.0, 70.0, 6, 0.0, 2.6)
	fruechte_reihe(71.0, 77.0, 3, 0.0)
	fruechte_bogen(78.0, 88.0, 6, 0.0, 2.6)
	fruechte_reihe(89.0, 95.0, 3, 0.0)
	fruechte_reihe(97.0, 107.0, 5, 0.0)
	fruechte_bogen(108.0, 116.0, 5, 0.0, 2.4)
	fruechte_reihe(117.0, 129.0, 6, 0.0)
	fruechte_bogen(130.0, 138.0, 5, 0.0, 2.4)
	fruechte_reihe(139.0, 149.0, 5, 0.0)
	fruechte_bogen(162.0, 172.0, 6, 0.0, 3.4)
	fruechte_bogen(184.0, 194.0, 6, 0.0, 3.4)
	fruechte_reihe(205.0, 213.0, 4, 0.0)
	fruechte_bogen(214.0, 222.0, 5, 0.0, 2.6)
	fruechte_reihe(223.0, 231.0, 4, 0.0)
	fruechte_bogen(232.0, 240.0, 5, 0.0, 2.6)
	fruechte_reihe(252.0, 278.0, 10, 0.0)


# =========================================================== Kulisse

## Kulisse gibt es nur auf den beiden Ankern – auf dem Steg wäre jeder
## Grashalm eine Lüge, weil dort nichts wächst und nichts liegt.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(14001)

	for i in 12:
		var s: float = randf_range(1.0, 30.0) if i % 2 == 0 \
				else randf_range(252.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 1.6)
		if rand < 2.0:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate() as Stein
		stein.saat = 14100 + i
		stein.groesse = randf_range(0.6, 1.8)
		stein.bemoost = false
		stein.kollision = false
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)

	# Ein paar zähe Krüppelkiefern auf dem Gipfelanker – das erste Grün
	# nach dem ganzen Weiß und damit das Zeichen, dass es geschafft ist.
	for i in 9:
		var s := randf_range(254.0, M_ENDE + 2.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM
		baum.hoehe = randf_range(3.5, 6.5)
		baum.staerke = randf_range(0.5, 0.9)
		baum.saat = 14300 + i
		baum.laubfarbe = Farben.NADEL_FROST
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(7.0, 16.0), -0.4)
		deko.add_child(baum)

	for i in 16:
		var s: float = randf_range(2.0, 28.0) if i % 2 == 0 \
				else randf_range(253.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 1.2)
		if rand < 1.6:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(2.2, 2.2)
		horst.halm_hoehe = randf_range(0.22, 0.42)
		horst.farbe_unten = Color(0.42, 0.44, 0.40)
		horst.farbe_oben = Color(0.70, 0.72, 0.66)
		horst.saat = 14500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.02)
		deko.add_child(horst)

	for i in 10:
		var s: float = randf_range(2.0, 28.0) if i % 2 == 0 \
				else randf_range(253.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 1.2)
		if rand < 1.6:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.BUSCH
		kleinzeug.saat = 14700 + i
		kleinzeug.groesse = randf_range(0.35, 0.7)
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.6, rand), 0.0)
		deko.add_child(kleinzeug)
	seed(wuerfel)
