extends KorridorLevel
## Level 11 – "Steinschlag"
##
## Ein Dschungelpfad, über den Steinkugeln laufen. Die Frage dieses Levels
## ist nicht "wohin springe ich", sondern "wann darf ich überhaupt
## losgehen". Der Brocken gibt den Takt, die Ausweichbuchten sind die
## Pausen dazwischen – und weil eine Bucht nur so viel wert ist, wie sie
## erreichbar ist, wird der Abstand zwischen ihnen von Abschnitt zu
## Abschnitt größer.
##
##     0 –  46  Talgrund     weit und offen; der erste Brocken rollt
##                           NEBEN dem Weg vorbei: Ankündigung, keine Gefahr
##    46 – 104  Bogengang    ein einzelner Brocken kommt entgegen,
##                           drei Buchten dicht beieinander
##   104 – 158  Nischentakt  zwei Brocken mit versetztem Takt,
##                           nur noch zwei Buchten auf 54 m
##   158 – 210  Rückenwind   die Brocken kommen VON HINTEN · SEITENANSICHT
##   210 – 262  Zwiespur     zwei Bahnen, immer ist genau eine frei
##   262 – 312  Steinbruch   Auslöseplatten – der Spieler wirft selbst ab
##   312 – 350  Tempelhof    weit, schnell, alles auf einmal
##
## Warum es keine Lücken im Boden gibt: Ein Level, das gleichzeitig nach
## Sprungweite und nach Takt fragt, beantwortet keine der beiden Fragen
## sauber. Der Weg ist durchgehend fest; was ihn schwer macht, rollt.
##
## Die Buchten sind keine eigenen Bauteile, sondern breite Stellen im
## Korridor. Damit an ihrem Mund keine Kante entsteht, weitet sich der Weg
## über je 2,5 bis 3 m auf und wieder ein – jede Naht in der
## Abschnittsliste trägt links und rechts dieselbe Breite.
##
## Farbe: sandbrauner Weg gegen türkisgrünen Stein, dunkelgrünes Blattwerk
## als Rahmen, rosa Blüten als einzige helle Tupfer. Der Stein ist die
## einzige kalte Farbe im Bild – und er ist genau das, was einen umbringt.
##
## WO EIN AKZENT STEHEN MUSS, DAMIT ER ZÄHLT. Die Blüten lagen anfangs auf
## dem Talboden, also einen Meter TIEFER als der Weg und damit hinter
## dessen Kante versteckt – im Bild waren sie nicht ein einziges Mal zu
## finden. Jetzt stehen sie als Horste auf dem bemoosten Rand des Weges.
##
## Der Grundsatz dahinter gilt für jedes Level: Eine Farbe, die das Bild
## tragen soll, muss dort liegen, wo die Kamera ohnehin hinsieht, nicht
## dort, wo sie inhaltlich hingehört. Der türkise Stein hält sich
## umgekehrt bewusst zurück und bleibt bei Torbögen, Bänken und Klippen –
## nachgemessen ist das Vorbild fast durchgehend warm, und ein Weg mit
## steinerner Fassung war kühler als die Vorlage, nicht wärmer.

const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

# --- Farben, die die Bibliothek nicht führt ---
## Türkisgrüner, geschnitzter Stein: die kalte Seite des Warm-kalt-Kontrasts.
## Eine Spur tiefer und türkiser als das erste Gemisch: Unter dem warmen
## Sonnenlicht des Tals lief der Stein sonst ins Olivgrüne und war von
## Blattwerk nicht mehr zu unterscheiden. Mehr FLÄCHE bekommt er nicht –
## nachgemessen ist das Vorbild fast durchgehend warm.
const STEIN_TIEF := Color(0.07, 0.19, 0.19)
const STEIN_HELL := Color(0.22, 0.46, 0.41)
## Rosa Blüten – die einzigen hellen Tupfer im Blattwerk.
const BLUETE_ROSA := Color(0.94, 0.58, 0.72)
## Talboden unter dem Weg und ferne Hügel.
const TALBODEN_HOEHE := -1.2

# --- Strecken-Marken ---
const M_TALGRUND := 0.0
const M_BOGENGANG := 46.0
const M_NISCHENTAKT := 104.0
const M_RUECKENWIND := 158.0
const M_ZWIESPUR := 210.0
const M_STEINBRUCH := 262.0
const M_TEMPELHOF := 312.0
const M_ENDE := 350.0

const ABSTURZ := -3.4


## Der Weg. Breite Stellen sind Buchten; die Flanken davor und danach
## sorgen dafür, dass an jeder Naht links und rechts dieselbe Breite steht.
const STRECKE := [
	# --- Talgrund: weit, verengt sich zum Bogengang hin ---
	{"von": 0.0, "bis": 46.0, "breite": 16.0, "breite_ende": 7.0},
	# --- Bogengang: schmal, drei Buchten dicht hintereinander ---
	{"von": 46.0, "bis": 56.0, "breite": 7.0},
	{"von": 56.0, "bis": 59.0, "breite": 7.0, "breite_ende": 13.0},
	{"von": 59.0, "bis": 64.0, "breite": 13.0},
	{"von": 64.0, "bis": 67.0, "breite": 13.0, "breite_ende": 7.0},
	{"von": 67.0, "bis": 76.0, "breite": 7.0},
	{"von": 76.0, "bis": 79.0, "breite": 7.0, "breite_ende": 13.0},
	{"von": 79.0, "bis": 84.0, "breite": 13.0},
	{"von": 84.0, "bis": 87.0, "breite": 13.0, "breite_ende": 7.0},
	{"von": 87.0, "bis": 96.0, "breite": 7.0},
	{"von": 96.0, "bis": 99.0, "breite": 7.0, "breite_ende": 13.0},
	{"von": 99.0, "bis": 104.0, "breite": 13.0},
	# --- Nischentakt: enger, die Buchten kleiner und weiter auseinander ---
	{"von": 104.0, "bis": 107.0, "breite": 13.0, "breite_ende": 6.5},
	{"von": 107.0, "bis": 124.0, "breite": 6.5},
	{"von": 124.0, "bis": 126.5, "breite": 6.5, "breite_ende": 11.0},
	{"von": 126.5, "bis": 130.0, "breite": 11.0},
	{"von": 130.0, "bis": 132.5, "breite": 11.0, "breite_ende": 6.5},
	{"von": 132.5, "bis": 148.0, "breite": 6.5},
	{"von": 148.0, "bis": 150.5, "breite": 6.5, "breite_ende": 11.0},
	{"von": 150.5, "bis": 154.0, "breite": 11.0},
	{"von": 154.0, "bis": 156.5, "breite": 11.0, "breite_ende": 6.5},
	{"von": 156.5, "bis": 158.0, "breite": 6.5},
	# --- Rückenwind: eine einzige Bucht auf 52 m ---
	{"von": 158.0, "bis": 186.0, "breite": 6.5},
	{"von": 186.0, "bis": 188.5, "breite": 6.5, "breite_ende": 12.0},
	{"von": 188.5, "bis": 192.0, "breite": 12.0},
	{"von": 192.0, "bis": 194.5, "breite": 12.0, "breite_ende": 6.5},
	{"von": 194.5, "bis": 208.0, "breite": 6.5},
	{"von": 208.0, "bis": 210.0, "breite": 6.5, "breite_ende": 10.0},
	# --- Zwiespur: zwei Bahnen nebeneinander, gar keine Bucht ---
	{"von": 210.0, "bis": 260.0, "breite": 10.0},
	{"von": 260.0, "bis": 262.0, "breite": 10.0, "breite_ende": 7.5},
	# --- Steinbruch: eine Bucht, dafür in der Mitte ---
	{"von": 262.0, "bis": 278.0, "breite": 7.5},
	{"von": 278.0, "bis": 280.5, "breite": 7.5, "breite_ende": 12.5},
	{"von": 280.5, "bis": 285.0, "breite": 12.5},
	{"von": 285.0, "bis": 287.5, "breite": 12.5, "breite_ende": 7.5},
	{"von": 287.5, "bis": 307.0, "breite": 7.5},
	{"von": 307.0, "bis": 312.0, "breite": 7.5, "breite_ende": 9.0},
	# --- Tempelhof: weitet sich zum Schluss ---
	{"von": 312.0, "bis": 350.0, "breite": 9.0, "breite_ende": 15.0},
]

## Mitte, Querversatz und Höhe der Steinbänke in den Buchten.
const BUCHTEN := [
	{"strecke": 61.5, "seitlich": 4.4},
	{"strecke": 81.5, "seitlich": -4.4},
	{"strecke": 101.5, "seitlich": 4.4},
	{"strecke": 128.0, "seitlich": -3.5},
	{"strecke": 152.0, "seitlich": 3.5},
	{"strecke": 190.0, "seitlich": -4.0},
	{"strecke": 282.5, "seitlich": 4.2},
]

## Wo ein Torbogen über dem Weg steht.
const BOEGEN := [46.0, 67.0, 87.0, 104.0, 122.0, 144.0, 162.0, 186.0,
		210.0, 240.0, 268.0, 300.0, 322.0]

var _stein_stoff: StandardMaterial3D


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Der Pfad wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Talboden", "tun": _talboden_bauen},
		{"text": "Sandweg und Buchten", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Kämme", "tun": _horizont_bauen},
		{"text": "Steinerne Torbögen", "tun": _boegen_bauen},
		{"text": "Bänke in den Buchten", "tun": _buchten_bauen},
		{"text": "Talgrund", "tun": _talgrund_bauen},
		{"text": "Bogengang", "tun": _bogengang_bauen},
		{"text": "Nischentakt", "tun": _nischentakt_bauen},
		{"text": "Rückenwind", "tun": _rueckenwind_bauen},
		{"text": "Zwiespur", "tun": _zwiespur_bauen},
		{"text": "Steinbruch", "tun": _steinbruch_bauen},
		{"text": "Tempelhof", "tun": _tempelhof_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Licht im Blattwerk", "tun": _stimmungen_setzen},
		{"text": "Dschungel", "tun": _dschungel_bauen},
		{"text": "Farn, Blüten und Geröll", "tun": _deko_bauen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Material

## Türkisgrüner Stein für Torbögen, Bänke und Klippen.
##
## Er wird hier gebaut und nicht aus der Materialbibliothek geholt: Deren
## Materialien liegen im Zwischenlager und werden von allen Leveln geteilt –
## sie nachträglich einzufärben würde sie überall verändern.
func _stein_material() -> StandardMaterial3D:
	if _stein_stoff != null:
		return _stein_stoff
	var m := StandardMaterial3D.new()
	m.albedo_texture = Materialbibliothek.rauschtextur(1101, 0.055,
			STEIN_TIEF, STEIN_HELL, 256)
	m.normal_enabled = true
	m.normal_texture = Materialbibliothek.normalmap(1102, 0.11, 1.6)
	m.normal_scale = 0.8
	# Dreiseitige Projektion, weil die Wege- und Blocknetze keine eigenen
	# UVs tragen – ohne sie stünde die Zeichnung an senkrechten Flächen still.
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.55, 0.55, 0.55)
	m.roughness = 0.84
	_stein_stoff = m
	return _stein_stoff


## Färbt ein fertiges Blütenmodell rosa.
##
## `Kleinzeug` würfelt seine Blütenfarbe nur dann selbst, wenn es die
## Blume auch selbst baut. Für Blumen liegt aber ein mitgeliefertes Modell
## im Spiel, und dessen eigener Anstrich gewinnt – `eigene_farbe` bleibt
## wirkungslos, und heraus kamen rote, gelbe und violette Blumen statt der
## rosa Tupfer des Steckbriefs. Am Prop selbst ist das nicht zu ändern,
## ohne es allen anderen Leveln mitzuändern.
##
## Also wird nachgestrichen, und zwar nur die Blüte: Was am Modell grüner
## als rot ist, ist Stiel und Blatt und bleibt, wie es ist.
func _bluete_faerben(knoten: Node) -> void:
	for kind in knoten.get_children():
		_bluete_faerben(kind)
	var mi := knoten as MeshInstance3D
	if mi == null or mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var alt := mi.mesh.surface_get_material(i) as BaseMaterial3D
		if alt != null and alt.albedo_color.g > alt.albedo_color.r:
			continue
		mi.set_surface_override_material(i,
				Materialbibliothek.leuchtend(BLUETE_ROSA, 0.35))


# =========================================================== Verlauf

## Ein langer, flacher Bogen durch das Tal. Höhenunterschied bleibt unter
## einem Meter: Auf einem Pfad, der steigt und fällt, verlöre die Kugel
## ihren gleichmäßigen Takt – und der Takt ist hier das ganze Level.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0.0, 8),
		Vector3(0, 0.0, -16),
		Vector3(6, 0.2, -40),        # Bogengang
		Vector3(20, 0.4, -60),
		Vector3(38, 0.5, -74),       # Nischentakt
		Vector3(60, 0.6, -80),
		Vector3(84, 0.6, -78),
		Vector3(106, 0.5, -68),      # Rückenwind
		Vector3(124, 0.4, -52),
		Vector3(136, 0.4, -32),      # Zwiespur
		Vector3(142, 0.5, -10),
		Vector3(140, 0.6, 12),
		Vector3(130, 0.7, 32),       # Steinbruch
		Vector3(114, 0.8, 48),
		Vector3(94, 0.8, 60),        # Tempelhof
		Vector3(72, 0.9, 66),
		Vector3(48, 0.9, 66),
	])


# =========================================================== Grund

func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.moos(),
		"klippe": _stein_material(),
	}, {"tiefe": 5.0, "schritt": 1.0, "kante_hoehe": 0.22, "kante_breite": 0.7})


## Der Talboden: eine ruhige Fläche knapp unter dem Weg. Sie trägt keine
## Kollision – wer vom Pfad fällt, fällt hindurch und in die Absturzzone.
## Ihr Zweck ist, dass Bäume und Steine neben dem Weg auf etwas stehen.
func _talboden_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(420.0, 420.0)
	var mi := MeshInstance3D.new()
	mi.name = "Talboden"
	mi.mesh = flaeche
	# Bewusst Gras statt Waldboden: Der Weg selbst ist sandbraun, und ein
	# ebenso brauner Untergrund ringsum ließe ihn verschwinden. Erst das
	# Grün ringsum macht aus dem Sandstreifen einen Pfad.
	# Eigene, abgedunkelte Kopie: Die Bibliothek liefert geteilte Materialien,
	# ein Eingriff daran träfe jedes andere Level mit. Dunkler muss sie sein,
	# weil der Bodennebel weg ist – ungedämpft liest sich die 420-m-Fläche
	# als heller Rasen statt als Dschungelgrund, und der Weg verliert seinen
	# Rahmen. Das Dunkel ist hier der Rahmen (Lesbarkeitsvertrag).
	var grund := Materialbibliothek.gras().duplicate() as StandardMaterial3D
	grund.albedo_color = Color(0.42, 0.47, 0.34)
	mi.material_override = grund
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0, 0.0)
	mi.position.y = TALBODEN_HOEHE
	geometrie.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 80.0)


func _horizont_bauen() -> void:
	horizont(260.0, 42.0, Color(0.16, 0.30, 0.19), Color(0.44, 0.58, 0.50),
			false, TALBODEN_HOEHE - 0.4)


## Steinerne Torbögen als Wegmarken.
##
## Sie geben dem geraden Pfad einen Takt fürs Auge – dieselbe Aufgabe, die
## die Kugel fürs Ohr hat. Die Spannweite ist nach oben gedeckelt, weil die
## Blöcke mit dem Halbmesser wachsen: Ein Bogen über die volle Breite des
## Tempelhofs bestünde aus Quadern von anderthalb Metern Kantenlänge.
func _boegen_bauen() -> void:
	var stoff := _stein_material()
	for s: float in BOEGEN:
		var spannweite := minf(maxf(breite_bei(s), 6.5) * 1.15, 11.0)
		LevelWerkzeuge.torbogen(deko, verlauf, s, spannweite, stoff, 13, 0.0)


## In jeder Bucht eine Steinbank: eine Stufe, auf der etwas liegt.
##
## Ohne sie wäre eine Bucht nur eine leere Ausbuchtung. Mit ihr ist sie ein
## Ort – und der Spieler geht auch dann hinein, wenn gerade nichts rollt.
func _buchten_bauen() -> void:
	var stoff := _stein_material()
	for b in BUCHTEN:
		var s: float = b["strecke"]
		var q: float = b["seitlich"]
		plattform(s, q, 0.05, Vector3(3.0, 1.1, 3.2), stoff)


# =========================================================== Abschnitte

## 0–46 · Talgrund. Frage: Was kann ich, und wie weit reicht der Weg?
##
## Der einzige Abschnitt ohne Gefahr von der Kugel. Der Brocken, der hier
## rollt, läuft weit draußen durch das Unterholz – man sieht ihn, man hört
## ihn, er kann einen nicht erreichen. Genau darum steht er hier: Damit die
## Kugel im Bogengang nicht die erste ist, die man je gesehen hat.
func _talgrund_bauen() -> void:
	rollbrocken(46.0, 6.0, 12.0, -1.6, 2.4, 11.0, 4.0, 0.0)
	rollbrocken(44.0, 8.0, -12.5, -1.8, 2.0, 9.0, 5.5, 0.5)


## 46–104 · Bogengang. Frage: Wann darf ich losgehen?
##
## Ein einziger Brocken, langsam, mit langer Pause, über die ganze Länge
## des Abschnitts. Die drei Buchten liegen 20 m auseinander – knapp mehr,
## als man in einer Pause läuft. Wer die Pause verpasst, wartet.
func _bogengang_bauen() -> void:
	rollbrocken(106.0, 44.0, 0.0, 0.0, 1.9, 7.5, 3.4, 0.0)


## 104–158 · Nischentakt. Frage: Reicht die nächste Bucht noch?
##
## Zwei Brocken mit verschiedenem Tempo – dadurch verschiebt sich das
## Fenster zwischen ihnen von Lauf zu Lauf, statt sich zu wiederholen. Die
## Buchten liegen jetzt 24 m auseinander und sind kleiner.
func _nischentakt_bauen() -> void:
	rollbrocken(158.0, 104.0, 0.0, 0.0, 1.9, 9.0, 2.4, 0.0)
	rollbrocken(158.0, 104.0, 0.0, 0.0, 1.5, 11.5, 2.4, 0.45,
			Rollhindernis.Art.FASS)


## 158–210 · Rückenwind. Frage: Was kommt von hinten?
##
## Hier laufen die Brocken MIT der Laufrichtung: Sie tauchen hinter dem
## Spieler auf und holen ihn ein. Von hinten sieht man sie nicht, deshalb
## läuft dieser Abschnitt als Seitenansicht – von der Seite ist der
## Abstand ablesbar, im Rückenblick nicht.
##
## Es gibt nur eine Bucht, und die liegt spät. Bis dahin hilft kein
## Ausweichen, nur Laufen – die einzige Stelle des Levels, an der man
## schneller sein muss als der Stein.
func _rueckenwind_bauen() -> void:
	rollbrocken(152.0, 212.0, 0.0, 0.0, 1.9, 9.0, 3.0, 0.0)
	rollbrocken(152.0, 212.0, 1.5, 0.0, 1.2, 12.5, 3.0, 0.5,
			Rollhindernis.Art.FASS)


## 210–262 · Zwiespur. Frage: Welche Bahn ist gerade frei?
##
## Zwei Brocken auf festen Spuren, um eine halbe Runde versetzt. Jeder
## deckt seine Hälfte samt Mitte ab; die freie Seite wechselt. Kein
## Ausweichen zur Seite mehr, sondern eine Entscheidung: links oder rechts.
func _zwiespur_bauen() -> void:
	rollbrocken(262.0, 208.0, -2.5, 0.0, 2.4, 9.5, 2.0, 0.0)
	rollbrocken(262.0, 208.0, 2.5, 0.0, 2.4, 9.5, 2.0, 0.5)
	# Schiebeblöcke in der Mitte: Sie drücken den Spieler genau dorthin,
	# wo die Bahn gerade belegt ist.
	schiebeblock(226.0, 0.0, 0.0, Vector3(1.6, 1.1, 1.6), 3.0, true, 1.6, 1.0)
	schiebeblock(246.0, 0.0, 0.0, Vector3(1.6, 1.1, 1.6), 3.0, true, 1.6, 1.0,
			0.5)


## 262–312 · Steinbruch. Frage: Was löse ich selbst aus?
##
## Zwei Brocken warten oben und rühren sich erst, wenn jemand auf die
## Platte tritt. Die Platte leuchtet, wenn sie gedrückt ist – der
## Zusammenhang zwischen dem eigenen Schritt und dem, was gleich kommt,
## soll erkennbar sein. Der erste Abwurf kommt entgegen, der zweite von
## hinten; dazwischen liegt die einzige Bucht.
func _steinbruch_bauen() -> void:
	var abwurf := rollbrocken(312.0, 262.0, 0.0, 0.0, 2.0, 8.5, 0.0, 0.0)
	abwurf.auf_abruf = true
	ausloeseplatte(267.0, 0.0, Vector2(3.2, 2.6), 1.0, false, [abwurf])

	var nachschlag := rollbrocken(262.0, 312.0, -1.8, 0.0, 1.3, 12.0, 0.0, 0.0,
			Rollhindernis.Art.FASS)
	nachschlag.auf_abruf = true
	ausloeseplatte(292.0, 0.0, Vector2(3.2, 2.6), 1.0, false, [nachschlag])

	# Dazu ein Brocken, der ohne Zutun läuft: Sonst wäre der Abschnitt
	# still, solange man die Platten meidet.
	rollbrocken(312.0, 260.0, 2.2, 0.0, 1.4, 10.0, 4.5, 0.25)


## 312–350 · Tempelhof. Frage: Halte ich den Takt, wenn er nicht mehr aufhört?
##
## Der Weg weitet sich, die Brocken werden größer und schneller, und die
## Pausen fallen weg. Ausgewichen wird jetzt im Freien statt in Buchten –
## der Abschnitt fragt nach demselben Können wie der Bogengang, aber ohne
## den Ort, an dem man sicher ist.
func _tempelhof_bauen() -> void:
	rollbrocken(350.0, 310.0, 0.0, 0.0, 2.6, 12.0, 1.8, 0.0)
	rollbrocken(350.0, 310.0, -3.5, 0.0, 1.5, 9.0, 2.6, 0.4,
			Rollhindernis.Art.FASS)
	rollbrocken(350.0, 310.0, 3.5, 0.0, 1.5, 9.0, 2.6, 0.75,
			Rollhindernis.Art.FASS)
	deckungsfleck(330.0, 5.0)


## Der Rückenwind läuft als Seitenansicht.
##
## Die Kamera steht links, weil der Weg dort eine Rechtskurve macht – von
## der Kurvenaußenseite bleibt der Blick auf den ganzen Gang frei.
func _kamerazonen_setzen() -> void:
	kamerazone(164.0, 204.0, -16.0, 3.4)


## Licht und Dunst je Abschnitt.
##
## Offen und hell an den beiden Enden, dumpf und grün in den engen
## Abschnitten dazwischen. Im Steinbruch steht Staub in der Luft: dichter
## Dunst in einem warmen Ton, damit der Abschnitt sich vom Blattgrün löst.
##
## Das Umgebungslicht ist überall abgesenkt. Der Weg war ein gutes
## Stück heller als im Vorbild, und Helligkeit frisst Farbe: Je mehr Licht
## auf dem Sand liegt, desto weiter laufen Weg, Stein und Blattwerk auf
## dasselbe helle Graugrün zu. Kühler dürfen die Töne dabei NICHT werden –
## der Weg ist die warme Seite des Kontrasts, und ein kühler Dunst darüber
## dreht das Level ins Grüne, statt den Stein hervorzuholen.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 44.0, Color(0.62, 0.62, 0.46), 0.007, 0.88,
			Color(0.58, 0.58, 0.47), 54.0)
	stimmung(48.0, 158.0, Color(0.32, 0.40, 0.30), 0.016, 0.68,
			Color(0.41, 0.45, 0.36), 44.0)
	stimmung(162.0, 262.0, Color(0.42, 0.47, 0.35), 0.013, 0.76,
			Color(0.47, 0.50, 0.41), 44.0)
	stimmung(264.0, 310.0, Color(0.64, 0.57, 0.41), 0.018, 0.8,
			Color(0.60, 0.55, 0.45), 44.0)
	stimmung(314.0, M_ENDE, Color(0.62, 0.63, 0.46), 0.007, 0.88,
			Color(0.59, 0.60, 0.49), 60.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(2.0, 5.0)


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Talgrund: Platz zum Üben ----------
	kiste(Kiste.Art.CHECKPOINT, 4.0, -3.0)
	kiste(Kiste.Art.NORMAL, 9.0, -2.2)
	kiste(Kiste.Art.NORMAL, 9.0, 0.0)
	kiste(Kiste.Art.NORMAL, 9.0, 2.2)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 15.0, 0.0)
	kiste(Kiste.Art.EISEN, 21.0, 2.6)
	kiste(Kiste.Art.NORMAL, 21.0, 2.6, 1.6)
	kiste(Kiste.Art.SCHUTZ, 27.0, -2.4)
	kiste(Kiste.Art.NORMAL, 33.0, 1.8)
	kiste(Kiste.Art.TNT, 39.0, 0.0)
	kiste(Kiste.Art.NORMAL, 39.0, -2.0)

	# ---------- Bogengang: was zählt, liegt in den Buchten ----------
	kiste(Kiste.Art.NORMAL, 51.0, -1.8)
	kiste(Kiste.Art.NORMAL, 61.5, 4.4, 1.1)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 61.5, 2.4)
	kiste(Kiste.Art.CHECKPOINT, 68.0, -1.8)
	kiste(Kiste.Art.NORMAL, 73.0, 1.8)
	kiste(Kiste.Art.SCHUTZ, 81.5, -4.4, 1.1)
	kiste(Kiste.Art.NORMAL, 81.5, -2.4)
	kiste(Kiste.Art.NORMAL, 91.0, 1.6)
	kiste(Kiste.Art.LEBEN, 101.5, 4.4, 1.1)

	# ---------- Nischentakt: eng, also wenig und flach ----------
	kiste(Kiste.Art.NORMAL, 112.0, 1.5)
	kiste(Kiste.Art.NORMAL, 118.0, -1.5)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 128.0, -3.5, 1.1)
	kiste(Kiste.Art.CHECKPOINT, 134.0, -1.6)
	kiste(Kiste.Art.NORMAL, 141.0, 1.6)
	kiste(Kiste.Art.SCHUTZ, 152.0, 3.5, 1.1)
	kiste(Kiste.Art.NORMAL, 156.0, -1.5)

	# ---------- Rückenwind: nichts, was zum Stehenbleiben verführt ----------
	kiste(Kiste.Art.NORMAL, 166.0, 1.6)
	kiste(Kiste.Art.NORMAL, 176.0, -1.6)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 190.0, -4.0, 1.1)
	kiste(Kiste.Art.NORMAL, 190.0, -2.0)
	kiste(Kiste.Art.CHECKPOINT, 196.0, 1.6)
	kiste(Kiste.Art.NORMAL, 203.0, -1.6)

	# ---------- Zwiespur: die Kisten stehen auf den Bahnen ----------
	kiste(Kiste.Art.NORMAL, 216.0, -2.5)
	kiste(Kiste.Art.NORMAL, 216.0, 2.5)
	kiste(Kiste.Art.EISEN, 232.0, 0.0)
	kiste(Kiste.Art.NORMAL, 232.0, 0.0, 1.6)
	kiste(Kiste.Art.SCHUTZ, 240.0, -3.2)
	kiste(Kiste.Art.NORMAL, 240.0, 3.2)
	kiste(Kiste.Art.CHECKPOINT, 258.0, 3.0)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 252.0, 0.0)

	# ---------- Steinbruch ----------
	kiste(Kiste.Art.NORMAL, 272.0, -1.8)
	kiste(Kiste.Art.NORMAL, 276.0, 1.8)
	kiste(Kiste.Art.LEBEN, 282.5, 4.2, 1.1)
	kiste(Kiste.Art.NORMAL, 282.5, 2.2)
	kiste(Kiste.Art.TNT, 296.0, 0.0)
	kiste(Kiste.Art.NORMAL, 296.0, -2.0)
	kiste(Kiste.Art.NORMAL, 303.0, 2.0)

	# ---------- Tempelhof: hier ist Platz für Stapel ----------
	kiste(Kiste.Art.CHECKPOINT, 316.0, -3.0)
	kiste(Kiste.Art.EISEN, 322.0, -3.6)
	kiste(Kiste.Art.NORMAL, 322.0, -3.6, 1.6)
	kiste(Kiste.Art.NORMAL, 322.0, -3.6, 2.6)
	kiste(Kiste.Art.NORMAL, 328.0, 3.6)
	kiste(Kiste.Art.FEDER, 332.0, 0.0)
	kiste(Kiste.Art.NORMAL, 338.0, -2.4)
	kiste(Kiste.Art.NORMAL, 338.0, 0.0)
	kiste(Kiste.Art.NORMAL, 338.0, 2.4)
	kiste(Kiste.Art.FRUCHT_MEHRFACH, 344.0, -2.0)
	kiste(Kiste.Art.NORMAL, 344.0, 2.0)


# =========================================================== Gegner

## Gegner stehen NICHT in den Buchten.
##
## Eine Bucht ist die Pause; wer dort auf einen Gegner trifft, hat keine.
## Sie stehen dazwischen – das ist der zweite Takt, von dem der Steckbrief
## spricht: Wer nur auf den Stein achtet, läuft in das Tier.
func _gegner_setzen() -> void:
	# ---------- Talgrund ----------
	gegner(PANZERKAEFER, 13.0, -2.0, 4.5, true)
	gegner(SUMPFKROETE, 22.0, 1.5, 3.5, true)
	werfer(30.0, -5.0)
	gegner(STELZENSPINNE, 36.0, 2.0, 3.5, true)

	# ---------- Bogengang: quer über den schmalen Gang ----------
	gegner(PANZERKAEFER, 71.0, 0.0, 1.8, true)
	gegner(SUMPFKROETE, 92.0, 0.0, 1.8, true)

	# ---------- Nischentakt ----------
	gegner(STELZENSPINNE, 115.0, 0.0, 1.6, true)
	gegner(PANZERKAEFER, 138.0, 0.0, 1.6, true)

	# ---------- Rückenwind: die Spinne steht IM Weg ----------
	gegner(STELZENSPINNE, 170.0, 0.0, 1.6, true)
	gegner(SUMPFKROETE, 182.0, 0.0, 1.6, true)
	gegner(PANZERKAEFER, 200.0, 0.0, 1.6, true)

	# ---------- Zwiespur: sie laufen quer über beide Bahnen ----------
	gegner(PANZERKAEFER, 221.0, -1.5, 3.0, true)
	gegner(SUMPFKROETE, 236.0, 1.5, 3.0, true)
	schwarm(250.0, 0.0, 10.0)

	# ---------- Steinbruch ----------
	gegner(STELZENSPINNE, 274.0, 0.0, 2.0, true)
	werfer(298.0, 2.4)

	# ---------- Tempelhof: die dichteste Stelle ----------
	gegner(PANZERKAEFER, 318.0, -2.5, 4.0, true)
	gegner(SUMPFKROETE, 326.0, 2.0, 3.5, true)
	schwarm(334.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 342.0, -2.5, 4.0, true)


# =========================================================== Früchte

## Früchte liegen auf der Bahn, die gerade sicher ist.
##
## Im Bogengang laufen sie in der Mitte und biegen zu den Buchten ab; auf
## der Zwiespur liegen zwei getrennte Spuren, damit man sieht, dass es
## zwei Bahnen sind, bevor der erste Brocken kommt.
func _fruechte_setzen() -> void:
	fruechte_reihe(5.0, 30.0, 10, 0.0)
	fruechte_bogen(32.0, 42.0, 6, 0.0, 2.4)
	fruechte_reihe(48.0, 58.0, 5, 0.0)
	fruechte_bogen(59.0, 64.0, 4, 4.4, 1.6)
	fruechte_reihe(68.0, 78.0, 5, 0.0)
	fruechte_bogen(79.0, 84.0, 4, -4.4, 1.6)
	fruechte_reihe(88.0, 98.0, 5, 0.0)
	fruechte_reihe(108.0, 124.0, 7, 0.0)
	fruechte_reihe(133.0, 148.0, 7, 0.0)
	fruechte_reihe(160.0, 206.0, 16, 0.0)
	fruechte_reihe(212.0, 258.0, 12, -2.5)
	fruechte_reihe(212.0, 258.0, 12, 2.5)
	fruechte_reihe(264.0, 306.0, 14, 0.0)
	fruechte_bogen(314.0, 324.0, 6, 0.0, 2.6)
	fruechte_reihe(326.0, 346.0, 9, 0.0)


# =========================================================== Kulisse

## Dschungel als Rahmen.
##
## Nah am Weg steht nichts Hohes: In den engen Abschnitten muss der Blick
## nach vorn frei bleiben, sonst sieht man den Brocken erst, wenn er da
## ist. Die Bäume stehen deshalb ab acht Metern und werden nach außen hin
## höher.
func _dschungel_bauen() -> void:
	var wuerfel := randi()
	seed(31101)
	for i in 132:
		var s := randf_range(-10.0, M_ENDE + 10.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var nah := maxf(breite_bei(s) * 0.5 + 2.5, 8.0)
		var quer := seite * randf_range(nah, nah + 20.0)
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.TOTHOLZ if i % 7 == 0 else Baum.Art.LAUBBAUM
		baum.kronenform = Baum.Kronenform.HOCH if i % 3 == 0 \
				else Baum.Kronenform.SCHIRM
		baum.hoehe = randf_range(6.0, 13.5)
		baum.staerke = randf_range(0.6, 1.3)
		baum.saat = 8100 + i
		baum.laubfarbe = Farben.LAUB_DUNKEL.lerp(Farben.LAUB, randf() * 0.7)
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s, quer, TALBODEN_HOEHE)
		deko.add_child(baum)

	# Umgestürzte Stämme quer am Wegrand: der orangebraune Gegenton zum
	# Blattgrün. Sie liegen halb neben dem Weg, damit sie nicht im Weg
	# stehen – sie sollen den Blick fassen, nicht den Lauf bremsen.
	for i in 22:
		var s := randf_range(6.0, M_ENDE - 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stamm := BAUM.instantiate() as Baum
		stamm.art = Baum.Art.TOTHOLZ
		stamm.hoehe = randf_range(5.0, 9.0)
		stamm.staerke = randf_range(0.9, 1.6)
		stamm.saat = 8300 + i
		stamm.kollision = false
		stamm.wind = false
		stamm.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + 2.6), TALBODEN_HOEHE + 0.35)
		stamm.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		# Um die eigene Längsachse gekippt: aus dem Baum wird ein liegender
		# Stamm, der quer zum Weg zeigt.
		stamm.rotation.z = PI * 0.5 * seite
		deko.add_child(stamm)
	seed(wuerfel)


func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(31102)

	# Felsbrocken am Wegrand – dieselbe Familie wie die Kugeln, damit man
	# glaubt, dass sie irgendwo herkommen.
	for i in 44:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var stein := STEIN.instantiate() as Stein
		stein.saat = 8500 + i
		stein.groesse = randf_range(0.7, 2.6)
		stein.bemoost = i % 3 != 0
		stein.kollision = false
		stein.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + randf_range(1.2, 7.0)),
				TALBODEN_HOEHE)
		stein.rotation.y = randf() * TAU
		deko.add_child(stein)

	# Grasinseln zwischen Weg und Blattwerk.
	for i in 66:
		var s := randf_range(0.0, M_ENDE)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(3.0, 3.0)
		horst.halm_hoehe = randf_range(0.5, 1.1)
		horst.farbe_unten = Farben.GRAS_DUNKEL
		horst.farbe_oben = Farben.LAUB_GELB
		horst.saat = 8700 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + randf_range(1.0, 8.0)),
				TALBODEN_HOEHE + 0.05)
		deko.add_child(horst)

	# Farn und Pilz auf dem Weg selbst, Blüten nur am Rand: Rosa ist der
	# einzige helle Ton im Bild und soll nicht mit den Früchten streiten.
	for i in 52:
		var s := randf_range(2.0, M_ENDE - 4.0)
		var rand := rand_bei(s, 1.1)
		if rand < 1.4:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var kleinzeug := KLEINZEUG.instantiate() as Kleinzeug
		kleinzeug.art = Kleinzeug.Art.PILZ if i % 4 == 0 else Kleinzeug.Art.FARN
		kleinzeug.groesse = randf_range(0.5, 1.0)
		kleinzeug.saat = 8900 + i
		kleinzeug.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(rand * 0.7, rand), 0.0)
		deko.add_child(kleinzeug)

	# Blütenhorste auf dem bemoosten Rand des Weges.
	#
	# Horste statt Einzelblumen: Eine einzelne Blume von einem halben
	# Meter ist aus der Verfolgerkamera ein Pixel. Drei bis fünf dicht
	# beieinander sind ein Fleck – und ein Fleck ist das, was der
	# Steckbrief mit "heller Tupfer" meint.
	#
	# Sie stehen INNEN auf dem Weg, knapp neben der Kante. Draußen wäre
	# kein Boden: Wer den Rand verlässt, hängt in der Luft über dem
	# Talboden, und genau dort standen sie vorher.
	for i in 34:
		var s := randf_range(3.0, M_ENDE - 5.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var halb := breite_bei(s) * 0.5
		var horst := randi_range(3, 5)
		for j in horst:
			var bluete := KLEINZEUG.instantiate() as Kleinzeug
			bluete.art = Kleinzeug.Art.BLUME
			bluete.groesse = randf_range(0.7, 1.2)
			bluete.saat = 9100 + i * 8 + j
			bluete.eigene_farbe = true
			bluete.farbe = BLUETE_ROSA
			bluete.position = LevelWerkzeuge.punkt(verlauf,
					s + randf_range(-1.6, 1.6),
					seite * (halb - randf_range(0.15, 1.5)), 0.02)
			deko.add_child(bluete)
			# Nachstreichen erst NACH dem Einhängen – vorher gibt es das
			# Modell noch nicht, das gefärbt werden soll.
			_bluete_faerben(bluete)

	# Wurzelbögen am Rand der engen Abschnitte.
	for i in 18:
		var s := randf_range(M_BOGENGANG, M_ZWIESPUR)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var w := WURZEL.instantiate() as Wurzel
		w.saat = 9300 + i
		w.spannweite = randf_range(3.0, 6.5)
		w.hoehe = randf_range(0.8, 1.8)
		w.kollision = false
		w.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (breite_bei(s) * 0.5 + randf_range(1.5, 5.0)),
				TALBODEN_HOEHE)
		w.rotation.y = randf() * TAU
		deko.add_child(w)
	seed(wuerfel)
