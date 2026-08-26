extends KorridorLevel
## Level 17 – "Frostritt"
##
## Ein Ritt-Level wie Level 04, aber im Winter und schneller: Das Reittier
## rennt von selbst durch eine enge Schneerinne, gelenkt wird nur quer.
## Anhalten geht nicht, Umkehren auch nicht. Kein Erkunden, reine Reaktion.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  56  Anlauf      – einzelne Hindernisse, viel Platz
##    56 – 124  Eisspur     – die drei Spuren werden eingeführt
##   124 – 196  Totemgang   – zwei Spuren zu, dazu die ersten Lücken
##   196 – 262  Sturmstück  – Höchsttempo, dichteste Folge
##   262 – 320  Auslauf     – es wird wieder weit, Ziel
##
## **Spurhindernisse.** Alles steht auf drei gedachten Spuren – links,
## Mitte, rechts. Nie sind alle drei zu; die Aufgabe ist, früh genug zu
## sehen, WELCHE offen ist. Das ist der ganze Unterschied zu Level 04, wo
## die Hindernisse noch von Hand über die Breite verteilt waren: Ein
## Muster kann man lesen, eine Streuung nur erraten. Die Dichte steigt von
## 19 m Abstand im Anlauf auf 11 m im Sturmstück – bei 18 m/s sind das
## sechs Zehntel einer Sekunde, und das ist die Untergrenze.
##
## **Was es schwer macht: Sichtweite.** Schneefall und Nebel lassen ein
## Hindernis spät auftauchen. Deshalb die Farbregel dieses Levels.
##
## **Die Farbregel.** Die Palette ist rein blau: weißer Schnee, blaugraue
## Eiswände, dunkelblauer Nachthimmel. Der EINZIGE warme Ton im ganzen
## Level ist das Holz der Totems – und ein Totem steht überall dort und nur
## dort, wo etwas gefährlich ist. Gefahr ist damit an der Farbe zu
## erkennen, bevor man die Form erkennt. Genau darum darf sonst nichts
## warm sein, auch nicht die Kulisse.
##
## Gegner zum Besiegen gibt es keine – bei 18 m/s ist ein patrouillierender
## Gegner keine Aufgabe mehr, sondern Zufall. Es wird nur ausgewichen.

const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")

# ------------------------------------------------------------- Palette
#
# Gemessen am Vorbild (doku/level-vorbilder.md, 4-2):
#   #B0BDCA #1A3752 #6F91B0 #3A6694 #9EB6D0 #965127
# Eine reine Blaupalette mit einem einzigen warmen Ton. `Farben` hat für
# Schnee und Eis Passendes; für das Totemholz und die beiden mittleren
# Blautöne nicht – die stehen hier als lokale Konstanten.

const EIS_STAHL := Color(0.690, 0.741, 0.792)    ## #B0BDCA Firn im Schatten
const NACHT_BLAU := Color(0.102, 0.216, 0.322)   ## #1A3752 Nachthimmel, Wandfuß
const EIS_MITTE := Color(0.435, 0.569, 0.690)    ## #6F91B0 Eiswand
const EIS_TIEF_BLAU := Color(0.227, 0.400, 0.580)## #3A6694 Gletscherader
const FIRN_HELL := Color(0.620, 0.714, 0.816)    ## #9EB6D0 Schneekrone
## Der eine warme Ton. Er kommt AUSSCHLIESSLICH an Totems vor.
const TOTEM_HOLZ := Color(0.588, 0.318, 0.153)   ## #965127
const TOTEM_MUSTER := Color(0.780, 0.470, 0.240)
## Wie stark das Totemholz von sich aus glimmt (siehe `_totemholz`).
const TOTEM_GLUT := 0.32
## Länge des Pfahls. Ein Hindernis ist 1,05 bis 1,7 m hoch; das Totem muss
## deutlich darüber hinausragen, sonst verdeckt die Form genau den Fleck,
## der sie ankündigen soll.
const TOTEM_HOEHE := 3.4
## Höhe des Querarms – über beiden Hindernisarten, unter der Spitze.
const TOTEM_ARM := 2.35

# ------------------------------------------------------------- Marken

const M_ANLAUF := 0.0
const M_EISSPUR := 56.0
const M_TOTEMGANG := 124.0
const M_STURM := 196.0
const M_AUSLAUF := 262.0
const M_ENDE := 320.0

const SCHLUCHT_HOEHE := -13.0   ## Grund der Rinne, reine Kulisse
const ABSTURZ := -5.0

## Wie weit vor dem Ziel die Steuerung abgegeben wird.
const AUSLAUF := 8.0

## Die drei gedachten Spuren. Bei einer Rinnenbreite von 11 m liegt der
## seitliche Anschlag des Reiters bei rund 4,4 m – die Außenspuren müssen
## also erreichbar bleiben, ohne dass man an der Kante klebt.
const SPUR_LINKS := -3.4
const SPUR_MITTE := 0.0
const SPUR_RECHTS := 3.4
## Breite eines Spurhindernisses. Schmaler als der Spurabstand, damit
## zwischen zwei besetzten Spuren immer noch eine Gasse bleibt.
const SPURBREITE := 3.2


const STRECKE := [
	# --- Anlauf: weit, damit sich das Auge an das Tempo gewöhnt ---
	{"von": 0.0, "bis": 56.0, "breite": 13.0},
	# --- Eisspur: schmaler, die drei Spuren werden eingeführt ---
	{"von": 56.0, "bis": 92.0, "breite": 11.0},
	{"von": 97.0, "bis": 124.0, "breite": 11.0},
	# --- Totemgang: drei Lücken über dem gefrorenen Bach ---
	{"von": 124.0, "bis": 148.0, "breite": 11.0},
	{"von": 153.0, "bis": 172.0, "breite": 10.5},
	{"von": 177.0, "bis": 196.0, "breite": 11.0},
	# --- Sturmstück: eng und dicht, die härteste Stelle ---
	{"von": 196.0, "bis": 224.0, "breite": 10.0},
	{"von": 229.0, "bis": 262.0, "breite": 10.5},
	# --- Auslauf: es wird wieder weit ---
	{"von": 262.0, "bis": 320.0, "breite": 14.0},
]

## Die Eiswände. Sie stehen dicht an der Wegkante – die Rinne ist eng, und
## die Enge ist das Gestaltungsmittel. Im Auslauf weichen sie zurück, damit
## das Ziel offen und hell wirkt.
const WAENDE := [
	{"von": -8.0, "bis": 56.0, "abstand": 6.8, "hoehe": 9.0},
	{"von": 56.0, "bis": 124.0, "abstand": 5.8, "hoehe": 10.5},
	{"von": 124.0, "bis": 196.0, "abstand": 5.6, "hoehe": 11.0},
	{"von": 196.0, "bis": 262.0, "abstand": 5.3, "hoehe": 12.0},
	{"von": 262.0, "bis": 328.0, "abstand": 7.5, "hoehe": 6.5},
]

var _reiter: Reiter
## Die beiden Totemmaterialien. Einmal gebaut und an alle Totems verteilt –
## es sind rund dreißig, und jedes bekäme sonst seine eigene Kopie.
var _totem_holz: StandardMaterial3D
var _totem_muster: StandardMaterial3D


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Rinne wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Grund der Rinne", "tun": _grund_bauen},
		{"text": "Eiswände türmen sich", "tun": _waende_bauen},
		{"text": "Schnee legt sich", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Hindernisse auf drei Spuren", "tun": _spuren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Rastplätze", "tun": _checkpoints_setzen},
		{"text": "Frostwald am Rand", "tun": _deko_bauen},
		{"text": "Schneefall", "tun": _schneefall_bauen},
		{"text": "Ferner Grat", "tun": _horizont_bauen},
		{"text": "Das Reittier wird gesattelt", "tun": _reiter_einrichten},
	]


# =========================================================== Verlauf

## Lange, weit gezogene Bögen. Bei 18 m/s wäre eine enge Kurve nicht mehr
## zu lesen, bevor man drinsteckt – und in einem Level, dessen Härte die
## Sichtweite ist, wäre das unfair statt schwer.
##
## Es geht durchgehend bergab: Eine Schneerinne fällt, und das Gefälle
## erklärt, warum das Tier immer schneller wird.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 6, 6),
		Vector3(0, 5.4, -26),
		Vector3(4, 4.6, -60),         # Anlauf
		Vector3(18, 3.8, -92),
		Vector3(42, 3.0, -116),       # Eisspur
		Vector3(72, 2.4, -128),
		Vector3(104, 1.8, -126),      # Totemgang
		Vector3(132, 1.2, -110),
		Vector3(152, 0.6, -86),
		Vector3(162, 0.0, -56),       # Sturmstück
		Vector3(160, -0.6, -24),
		Vector3(148, -1.2, 6),        # Auslauf
		Vector3(130, -1.8, 30),
	])


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.schnee(),
		"kante": Materialbibliothek.firn(),
		"klippe": Materialbibliothek.frostfels(),
	}, {"tiefe": 9.0, "schritt": 1.2, "kante_hoehe": 0.30, "kante_breite": 0.7})
	luecken_markieren(EIS_TIEF_BLAU)


## Die Eiswände: blaugrauer Fels als Grundton, tiefblaue Gletscheradern
## darüber, Firn auf der obersten Lage. Dahinter eine glatte Leitwand – der
## Reiter klebt zwar auf der Kurve und fährt gar nicht gegen Wände, aber
## nach einem Sprung neben die Rinne fängt sie ihn ab.
func _waende_bauen() -> void:
	LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			Materialbibliothek.frostgestein(), {
		"schritt": 2.4, "lagen": 4, "block": 3.0,
		"sockel": 14.0, "saat": 1702,
		"adermaterial": Materialbibliothek.eisfels(),
		"deckmaterial": Materialbibliothek.firn(),
		"aderdichte": 0.22,
	})
	for w in WAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, maxf(w["von"], 0.0),
				minf(w["bis"], M_ENDE), float(w["abstand"]) - 0.4, 6.0)
	# Schneebank: steigt vom Boden zur Wand an und schließt die Fuge.
	var baenke: Array = []
	for w in WAENDE:
		baenke.append({
			"von": maxf(w["von"], -4.0), "bis": w["bis"],
			"innen": float(w["abstand"]) - 2.0,
			"aussen": float(w["abstand"]) + 0.6,
			"hoehe": -0.05,
		})
	LevelWerkzeuge.sims(geometrie, verlauf, baenke, Materialbibliothek.schnee())


func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(340.0, 340.0)
	var mi := MeshInstance3D.new()
	mi.name = "Rinnengrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.eis()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0, SCHLUCHT_HOEHE)
	geometrie.add_child(mi)


## Ferner Grat. Ohne ihn endet die Bodenplatte sichtbar in der Luft. Seine
## Farben liegen dicht am Nebel, damit er nicht die Aufmerksamkeit zieht –
## und beide sind blau, wie alles außer den Totems.
func _horizont_bauen() -> void:
	horizont(280.0, 46.0, NACHT_BLAU.lightened(0.10), EIS_STAHL.darkened(0.30),
			false, SCHLUCHT_HOEHE - 2.0)


func _absturz_spannen() -> void:
	absturzzonen(20.0, 80.0)


# =========================================================== Spurhindernisse

## Ein Hindernis ist eine Zone, kein Körper: Der Reiter klebt auf der Kurve
## und würde gegen einen festen Körper nur hängen bleiben, statt
## abgeworfen zu werden. Dasselbe Vorgehen wie in Level 04.
##
## `als_block` unterscheidet die beiden Optiken: gestürzte Eisblöcke stehen
## hoch, Firnwälle liegen flach. Beide tragen ein Totem – das ist der
## eigentliche Punkt dieser Funktion. Es gibt in diesem Level kein
## Hindernis ohne Totem und kein Totem ohne Hindernis.
func _hindernis(strecke: float, seitlich: float, breite: float,
		als_block: bool) -> void:
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	zone.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	zone.body_entered.connect(_auf_hindernis)
	# Gruppe und Kennwerte, damit sich die Strecke von außen prüfen lässt:
	# ob überall eine Lücke bleibt und wie viel Zeit zum Reagieren ist.
	zone.add_to_group("hindernis")
	zone.set_meta("strecke", strecke)
	zone.set_meta("seitlich", seitlich)
	zone.set_meta("breite", breite)
	objekte.add_child(zone)

	var hoehe := 1.7 if als_block else 1.05
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite, hoehe, 1.4)
	form.shape = kasten
	form.position.y = hoehe * 0.5
	zone.add_child(form)

	if als_block:
		_eisblock(zone, breite, hoehe)
	else:
		_firnwall(zone, breite, hoehe)
	_totem(zone, breite)


func _auf_hindernis(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
		koerper.call("schaden_nehmen")


## Gestürzter Eisblock: drei kantige Brocken, ineinandergeschoben.
func _eisblock(eltern: Node3D, breite: float, hoehe: float) -> void:
	var st := PropWerkzeug.bauer()
	for i in 3:
		var t := float(i) / 2.0
		var kasten := PropWerkzeug.kasten(Vector3(
				breite * randf_range(0.36, 0.5),
				hoehe * randf_range(0.62, 1.0),
				randf_range(0.7, 1.2)))
		PropWerkzeug.anfuegen(st, kasten, Transform3D(
				Basis(Vector3.UP, (t - 0.5) * 0.9),
				Vector3(lerpf(-breite * 0.28, breite * 0.28, t),
						hoehe * 0.42, (t - 0.5) * 0.45)))
	var knoten := PropWerkzeug.mesh_knoten("Eisblock", PropWerkzeug.fertig(st),
			Materialbibliothek.eis())
	if knoten != null:
		eltern.add_child(knoten)


## Firnwall: eine flache, breite Schneewehe, über die man nicht kommt.
func _firnwall(eltern: Node3D, breite: float, hoehe: float) -> void:
	var walze := CylinderMesh.new()
	walze.top_radius = hoehe * 0.5
	walze.bottom_radius = hoehe * 0.62
	walze.height = breite
	walze.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = walze
	mi.material_override = Materialbibliothek.firn()
	mi.rotation.z = PI * 0.5
	mi.position.y = hoehe * 0.42
	eltern.add_child(mi)


## Das Totemholz als Material.
##
## `kistenholz` allein reichte nicht. Es legt die Farbe zwischen
## `farbe * 0,55` und `farbe.lightened(0,34)`, und dieser dunkle Schnitt
## fiel unter blauem Mondlicht, blauem Umgebungslicht und blauem Nebel auf
## Schiefergrau zusammen: Gemessen kam vom warmen Ton so gut wie nichts an,
## obwohl `TOTEM_HOLZ` mit #965127 warm gesetzt ist. Ein Gefahrenzeichen,
## das nur im Quelltext warm ist, ist keins.
##
## Zwei Gegenmittel, beide nötig:
##   * Der Ton geht heller in die Textur, damit vom dunklen Ende der
##     Holzmaserung noch Farbe übrig bleibt.
##   * Eine schwache Eigenglut in genau diesem Ton. Glut hängt nicht am
##     Licht der Szene – sie trägt das Warm durch Dunst und Nachtblau,
##     ohne dass an der Beleuchtung des Levels gedreht werden muss. Und
##     nur das Totem glimmt, die Palette bleibt sonst unberührt.
func _totemholz(farbe: Color) -> StandardMaterial3D:
	# Sättigung halten, nicht aufhellen: `lightened` zöge den Ton nach
	# Rosa, und blass ist so schlecht lesbar wie dunkel.
	var grund := Color(minf(farbe.r * 1.25, 1.0), minf(farbe.g * 1.25, 1.0),
			minf(farbe.b * 1.25, 1.0))
	# Die Bibliothek gibt geteilte Materialien zurück – verändert wird nur
	# eine eigene Kopie.
	var m := Materialbibliothek.kistenholz(grund).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = grund
	m.emission_energy_multiplier = TOTEM_GLUT
	return m


## Ein hölzernes Totem neben dem Hindernis – der einzige warme Ton im
## ganzen Level.
##
## Es steht am Rand des Hindernisses, nicht darauf: Bei der Sichtweite
## dieses Levels sieht man den warmen Fleck eher als die Form daneben, und
## dann weiß man schon, dass man ausweichen muss, bevor man weiß, wovor.
##
## Der erste Anlauf war ein Pfahl von 2,6 m mit drei schmalen Ringen. Er
## kam auf zwei Zehntel Prozent Bildfläche und las sich schiefergrau – zu
## wenig Fläche, zu dunkles Holz. Jetzt trägt das Totem vier Teile, die
## jedes für sich Fläche machen:
##   * einen breiten Fuß am Boden, dort liegt bei dieser tiefen
##     Verfolgerkamera die meiste Bildfläche,
##   * einen deutlich dickeren Pfahl mit vier breiten Ringen,
##   * einen geschnitzten Kopf, der über allem steht und schon aus der
##     Ferne als Marke zu sehen ist,
##   * einen Querarm mit drei Warnbrettern, der über das Hindernis reicht
##     und damit genau die Spur überdeckt, die zu ist.
func _totem(eltern: Node3D, breite: float) -> void:
	if _totem_holz == null:
		_totem_holz = _totemholz(TOTEM_HOLZ)
		_totem_muster = _totemholz(TOTEM_MUSTER)

	# Fuß, Pfahl und Querarm in EINEM Mesh – ein Zeichen, ein Knoten.
	var st := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.62, 0.40, 0.55, 8, true),
			Transform3D(Basis(), Vector3(0.0, 0.275, 0.0)))
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.stumpf(0.33, 0.27, TOTEM_HOEHE, 8, true),
			Transform3D(Basis(), Vector3(0.0, 0.5 + TOTEM_HOEHE * 0.5, 0.0)))
	# Der Querarm ist ein Ausleger und bekommt bewusst keine zweite Stütze
	# jenseits des Hindernisses: Wo zwei Nachbarspuren zu sind, stünden
	# zwei Pfähle eine Handbreit nebeneinander, und aus dem Zeichen würde
	# ein Zaun.
	PropWerkzeug.anfuegen(st,
			PropWerkzeug.kasten(Vector3(breite * 0.9, 0.24, 0.28)),
			Transform3D(Basis(), Vector3(-breite * 0.45 - 0.1, TOTEM_ARM, 0.0)))
	var knoten := PropWerkzeug.mesh_knoten("Totem", PropWerkzeug.fertig(st),
			_totem_holz)
	if knoten == null:
		return
	knoten.position = Vector3(breite * 0.5 + 0.45, 0.0, 0.0)
	eltern.add_child(knoten)

	# Das Muster im helleren Warmton als zweites Mesh: Ringe, Kopf, Spitze
	# und die drei Bretter am Arm. Sie sind der Teil, der aus der Ferne als
	# Fleck übrig bleibt, wenn die Schnitzerei längst nicht mehr zu
	# erkennen ist.
	var mst := PropWerkzeug.bauer()
	for i in 4:
		PropWerkzeug.anfuegen(mst, PropWerkzeug.stumpf(0.40, 0.40, 0.24, 8, true),
				Transform3D(Basis(), Vector3(0.0, 0.95 + float(i) * 0.62, 0.0)))
	PropWerkzeug.anfuegen(mst, PropWerkzeug.kasten(Vector3(0.86, 0.5, 0.62)),
			Transform3D(Basis(), Vector3(0.0, TOTEM_HOEHE + 0.35, 0.0)))
	PropWerkzeug.anfuegen(mst, PropWerkzeug.stumpf(0.30, 0.0, 0.55, 6, true),
			Transform3D(Basis(), Vector3(0.0, TOTEM_HOEHE + 0.88, 0.0)))
	for i in 3:
		var t := (float(i) + 0.5) / 3.0
		PropWerkzeug.anfuegen(mst, PropWerkzeug.kasten(Vector3(0.52, 0.62, 0.14)),
				Transform3D(Basis(), Vector3(-breite * 0.9 * t - 0.1,
						TOTEM_ARM - 0.48, 0.0)))
	var mknoten := PropWerkzeug.mesh_knoten("Totemmuster",
			PropWerkzeug.fertig(mst), _totem_muster)
	if mknoten != null:
		knoten.add_child(mknoten)


## Eine Reihe Spurhindernisse mit gleichmäßigem Abstand.
##
## `muster` ist je Takt eine Liste der BELEGTEN Spuren (-1 links, 0 Mitte,
## 1 rechts). Nie sind alle drei belegt – das prüft die Funktion selbst und
## lässt im Zweifel die Mitte frei, statt eine Wand zu bauen, durch die
## niemand kommt.
func _spurreihe(von: float, bis: float, muster: Array,
		als_block := true) -> void:
	var spuren := [SPUR_LINKS, SPUR_MITTE, SPUR_RECHTS]
	for i in muster.size():
		var s := lerpf(von, bis, float(i) / maxf(float(muster.size() - 1), 1.0))
		var belegt: Array = muster[i]
		if belegt.size() >= 3:
			belegt = [belegt[0], belegt[1]]
		for spur in belegt:
			_hindernis(s, spuren[int(spur) + 1], SPURBREITE,
					als_block if int(spur) != 0 else not als_block)


## Alles, was ausgewichen werden muss – von weit gestellt bis dicht.
##
## Die Abstände steigen streng: 19 m im Anlauf, 16 m in der Eisspur, 12 m
## im Totemgang, 11 m im Sturmstück, wieder 16 m im Auslauf. Bei
## Höchsttempo sind 11 m sechs Zehntel einer Sekunde. Enger wird es nicht –
## ab da ist es nicht mehr Reaktion, sondern Auswendiglernen.
##
## Die Saat ist fest: Ein Eisblock soll bei jedem Anlauf gleich aussehen,
## sonst kann man die Stelle nicht wiedererkennen.
func _spuren_setzen() -> void:
	var wuerfel := randi()
	seed(17500)

	# ---------- Anlauf: eine Spur zu, viel Zeit ----------
	# Erst einzeln, damit man merkt, dass es Spuren SIND.
	_spurreihe(15.0, 53.0, [[-1], [1], [0]])

	# ---------- Eisspur: zwei Spuren zu, die Gasse wandert ----------
	_spurreihe(70.0, 118.0, [[-1, 0], [0, 1], [-1, 1], [0, 1]])

	# ---------- Totemgang: Lücken im Boden, Hindernisse davor ----------
	# Vor jeder Lücke steht ein Hindernis: Man muss die Spur schon
	# gewechselt haben, wenn man abspringt.
	_spurreihe(132.0, 144.0, [[1], [-1, 0]], false)
	_spurreihe(158.0, 170.0, [[-1], [0, 1]])
	_spurreihe(182.0, 194.0, [[1], [-1, 0]], false)

	# ---------- Sturmstück: dichteste Folge, Wechseltakt ----------
	_spurreihe(205.0, 216.0, [[-1, 0], [0, 1]])
	_spurreihe(234.0, 256.0, [[-1, 1], [0, 1], [-1, 0]])

	# ---------- Auslauf: es wird wieder ruhiger ----------
	_spurreihe(272.0, 304.0, [[0], [-1], [1]], false)
	seed(wuerfel)


# =========================================================== Kisten

## Kisten stehen in Reihen längs des Weges: im Vorbeirennen zerbrechen sie
## ohnehin, die Aufgabe ist nur, die richtige Spur zu treffen.
##
## Die TNT-Kisten dazwischen sind die zweite Frage: Ihr Zünder läuft drei
## Sekunden, und in drei Sekunden ist man fünfzig Meter weiter. Wer sie
## mitnimmt, hat den Zähler; wer sie stehen lässt, hat sein Bild frei.
func _kisten_setzen() -> void:
	# ---------- Anlauf ----------
	_kistenreihe(8.0, 5, SPUR_MITTE)
	_kistenreihe(26.0, 4, SPUR_LINKS)
	_kistenreihe(42.0, 4, SPUR_RECHTS)

	# ---------- Eisspur ----------
	# Ab hier liegt jede Reihe in der Spur, die das nächste Hindernis
	# freilässt: Die Kisten sind damit nicht nur Beute, sondern die Ansage,
	# wo man gleich sein muss.
	_kistenreihe(60.0, 5, SPUR_MITTE)
	_kistenreihe(76.0, 4, SPUR_RECHTS)
	kiste(Kiste.Art.TNT, 88.0, SPUR_LINKS)
	kiste(Kiste.Art.NORMAL, 89.6, SPUR_LINKS)
	_kistenreihe(106.0, 4, SPUR_LINKS)
	kiste(Kiste.Art.TNT, 112.0, SPUR_RECHTS)

	# ---------- Totemgang ----------
	_kistenreihe(126.0, 4, SPUR_MITTE)
	_kistenreihe(160.0, 4, SPUR_RECHTS)
	kiste(Kiste.Art.TNT, 166.0, SPUR_LINKS)
	kiste(Kiste.Art.NORMAL, 167.6, SPUR_LINKS)
	_kistenreihe(184.0, 4, SPUR_LINKS)

	# ---------- Sturmstück ----------
	_kistenreihe(207.0, 4, SPUR_RECHTS)
	kiste(Kiste.Art.TNT, 220.0, SPUR_MITTE)
	_kistenreihe(240.0, 5, SPUR_LINKS)
	kiste(Kiste.Art.TNT, 250.0, SPUR_RECHTS)
	kiste(Kiste.Art.NORMAL, 251.6, SPUR_RECHTS)

	# ---------- Auslauf ----------
	_kistenreihe(264.0, 5, SPUR_LINKS)
	_kistenreihe(286.0, 6, SPUR_MITTE)
	_kistenreihe(304.0, 5, SPUR_MITTE)

	# Schutz vor den beiden dichtesten Folgen, gut sichtbar in der Mitte.
	kiste(Kiste.Art.SCHUTZ, 62.0, SPUR_LINKS)
	kiste(Kiste.Art.SCHUTZ, 198.0, SPUR_MITTE)
	kiste(Kiste.Art.SCHUTZ, 231.0, SPUR_MITTE)
	# Ein Extraleben kurz vor dem Ziel.
	kiste(Kiste.Art.LEBEN, 298.0, SPUR_RECHTS)


func _kistenreihe(von: float, anzahl: int, seitlich: float) -> void:
	for i in anzahl:
		kiste(Kiste.Art.NORMAL, von + float(i) * 1.6, seitlich)


# =========================================================== Früchte

## Über jede Lücke ein Bogen: Er zeigt, wo abgesprungen werden muss. Bei
## dieser Sichtweite ist das keine Zierde, sondern die Ansage.
func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 18.0, 8, SPUR_MITTE)
	fruechte_reihe(22.0, 34.0, 7, SPUR_LINKS)
	fruechte_reihe(38.0, 54.0, 8, SPUR_RECHTS)
	fruechte_reihe(58.0, 84.0, 10, SPUR_MITTE)
	fruechte_bogen(91.0, 98.0, 6, SPUR_MITTE, 3.4)
	fruechte_reihe(102.0, 120.0, 8, SPUR_LINKS)
	fruechte_reihe(126.0, 146.0, 8, SPUR_MITTE)
	fruechte_bogen(147.0, 154.0, 6, SPUR_MITTE, 3.6)
	fruechte_reihe(156.0, 170.0, 7, SPUR_RECHTS)
	fruechte_bogen(171.0, 178.0, 6, SPUR_MITTE, 3.6)
	fruechte_reihe(180.0, 192.0, 7, SPUR_LINKS)
	fruechte_reihe(198.0, 222.0, 10, SPUR_MITTE)
	fruechte_bogen(223.0, 230.0, 6, SPUR_MITTE, 3.8)
	fruechte_reihe(234.0, 258.0, 10, SPUR_MITTE)
	fruechte_reihe(264.0, 314.0, 18, SPUR_MITTE)


# =========================================================== Checkpoints

## Rastplätze: eine Zone quer über den Weg, die dem Reiter seine Strecke
## als Rückkehrpunkt meldet. Die Checkpoint-Kiste aus den Laufleveln taugt
## hier nicht – sie merkt sich eine Weltposition, der Reiter braucht aber
## eine Strecke auf der Kurve. Dasselbe Vorgehen wie in Level 04.
##
## Als Marke stehen hier keine Wimpel, sondern zwei Totems: In diesem Level
## ist Holz die Farbe der Gefahr, und ein Rastplatz liegt immer unmittelbar
## vor der nächsten, dichteren Folge.
func _checkpoints_setzen() -> void:
	for s: float in [M_EISSPUR, M_TOTEMGANG, M_STURM, M_AUSLAUF]:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, 1.2)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(20.0, 5.0, 1.5)
		form.shape = kasten
		zone.add_child(form)
		zone.body_entered.connect(_auf_checkpoint.bind(s))
		objekte.add_child(zone)

		for seite: float in [-1.0, 1.0]:
			var pfosten := Node3D.new()
			pfosten.position = LevelWerkzeuge.punkt(verlauf, s,
					seite * (breite_bei(s) * 0.5 - 0.8), 0.0)
			pfosten.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
			deko.add_child(pfosten)
			_totem(pfosten, 0.0)


func _auf_checkpoint(koerper: Node3D, s: float) -> void:
	if koerper is Reiter:
		(koerper as Reiter).setze_checkpoint(s)
		GameState.zeige_nachricht("Rastplatz", 1.2)


# =========================================================== Kulisse

## Frostwald auf den Simsen und Eisbrocken am Wandfuß.
##
## Beides bewusst kühl gefärbt: Ein Nadelbaum in seinem normalen Grün wäre
## in dieser Palette schon der zweite warme Ton und nähme den Totems ihren
## Vorrang. Hier ist alles blau, was nicht Totem ist.
func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(17001)
	for i in 84:
		var s := randf_range(-8.0, M_ENDE + 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM if i % 4 != 0 else Baum.Art.TOTHOLZ
		baum.hoehe = randf_range(5.0, 11.0)
		baum.staerke = randf_range(0.6, 1.1)
		baum.saat = 17100 + i
		baum.laubfarbe = Farben.NADEL_FROST.lerp(EIS_MITTE, randf() * 0.6)
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(8.0, 30.0),
				randf_range(-1.5, 2.5))
		deko.add_child(baum)

	for i in 38:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 1.4)
		if rand < 1.8:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var brocken := STEIN.instantiate() as Stein
		brocken.groesse = randf_range(0.6, 1.6)
		brocken.bemoost = false
		brocken.kollision = false
		brocken.saat = 17300 + i
		brocken.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.8, rand), 0.0)
		brocken.rotation.y = randf() * TAU
		deko.add_child(brocken)
	seed(wuerfel)


## Schneefall über der ganzen Rinne.
##
## Er ist nicht Zierat: Die Härte dieses Levels ist die Sichtweite, und der
## Schnee ist das, was sie nimmt. Ein einzelnes großes Partikelfeld folgt
## dem Reiter nicht; stattdessen liegen mehrere Felder entlang der Strecke,
## und jedes deckt sein Stück ab.
func _schneefall_bauen() -> void:
	var flocke := Materialbibliothek.leuchtend(FIRN_HELL.lightened(0.4), 0.35)
	var s := 0.0
	while s < M_ENDE:
		var feld := GPUParticles3D.new()
		feld.amount = 90
		feld.lifetime = 5.0
		feld.preprocess = 5.0
		feld.visibility_aabb = AABB(Vector3(-16.0, -14.0, -14.0),
				Vector3(32.0, 24.0, 28.0))

		var stoff := ParticleProcessMaterial.new()
		stoff.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		stoff.emission_box_extents = Vector3(14.0, 0.5, 13.0)
		stoff.direction = Vector3(0.25, -1.0, 0.1)
		stoff.spread = 12.0
		stoff.initial_velocity_min = 1.6
		stoff.initial_velocity_max = 3.0
		stoff.gravity = Vector3(0.4, -1.4, 0.0)
		stoff.scale_min = 0.5
		stoff.scale_max = 1.4
		feld.process_material = stoff

		var korn := QuadMesh.new()
		korn.size = Vector2(0.09, 0.09)
		feld.draw_pass_1 = korn
		feld.material_override = flocke

		feld.position = LevelWerkzeuge.punkt(verlauf, s + 13.0, 0.0, 10.0)
		feld.rotation.y = LevelWerkzeuge.drehung(verlauf, s + 13.0)
		deko.add_child(feld)
		s += 26.0


# =========================================================== Reiter

## Der Reiter braucht drei Auskünfte vom Level: die Kurve, wie weit er
## seitlich darf und wo Boden ist. Ohne die letzte liefe er über Lücken
## hinweg, als wäre nichts – er fällt ja nicht, er klebt auf der Kurve.
##
## Genauso eingerichtet wie in Level 04; die Tempowerte stehen in
## `Level17.tscn` am Reiter-Knoten.
func _reiter_einrichten() -> void:
	_reiter = get_tree().get_first_node_in_group("spieler") as Reiter
	if _reiter == null:
		push_warning("Level 17 ohne Reiter – ist Reiter.tscn in der Szene?")
		return
	_reiter.verlauf = verlauf
	_reiter.seiten_grenze = func(s: float) -> float: return rand_bei(s, 1.1)
	_reiter.boden_pruefer = func(s: float) -> bool: return breite_bei(s) > 0.0
	_reiter.ziel_strecke = M_ENDE - AUSLAUF
	_reiter.strecke = 2.0
	if not _reiter.ziel_erreicht.is_connected(_auf_ziel):
		_reiter.ziel_erreicht.connect(_auf_ziel)


func _auf_ziel() -> void:
	_reiter.gesperrt = true
	GameState.zeige_nachricht("Geschafft!", 3.0)
	_auf_level_geschafft()
