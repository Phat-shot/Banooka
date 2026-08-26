extends KorridorLevel
## Level 24 – "Neonhöhe"
##
## Zukunftsstadt bei Nacht, hoch über allem (Steckbrief 5-4). Das
## Hauptbauteil ist der `laserzaun()`: die senkrechte Schwester der
## Taktfläche. Sie ist Boden, er ist Wand – und in der wandernden
## Betriebsart fehlt immer genau EIN Strahl, sodass er zwei Fragen auf
## einmal stellt: wann, und in welcher Haltung.
##
##     0 –  52  Dachterrasse   der weite Auftakt, ein Zaun zum Kennenlernen
##    52 – 112  Zaunstraße     sechs Zäune, jeder in einer anderen Lage
##   112 – 160  Schwebebahn    zwei Löcher, zwei Schwebeplattformen
##   160 – 226  Pumpturm       Bohlen, die senkrecht aus der Leere steigen
##   226 – 292  Reklamegasse   Takt und Gegner zugleich auf schmalem Steg
##   292 – 344  Antennenspitze SEITENANSICHT: der Blick hinunter
##
## DIE STADT DARUNTER IST KEIN HINTERGRUND, SONDERN EIN MASSSTAB. Ohne
## sie wäre die Leere neben dem Steg einfach schwarz und damit harmlos;
## mit ihr sieht man, wie tief unten der Boden liegt. Deshalb steht sie
## in `_stadt_bauen()` und nicht in der Deko-Restekiste, und deshalb
## staffeln sich ihre Dächer in mehreren Tiefen statt in einer.
##
## `scripts/neonmaterial.gd` liefert dafür den Materialsatz. Sein Prinzip
## ist ein anderes als das der `Materialbibliothek`: nicht Oberfläche mit
## Struktur, sondern dunkler Grundton plus leuchtende Kante. Der Weg folgt
## demselben Prinzip – mintgrüner Boden, Neonstreifen an der Kante,
## stumpfe Fassade an der Klippe.
##
## WARUM DIE NACHT NICHT NUR BLAU IST. Ein Level, das ausschließlich aus
## Blau und Violett besteht, hat keine Farbe mehr, sondern nur noch
## Helligkeit: Alles darin ist dieselbe Farbe in verschiedenen Stufen, und
## das Auge findet nichts, woran es sich festhält. Das Vorbild (Steckbrief
## 5-4) löst das mit **Kupfer und Bronze** – knapp ein Drittel der Fläche
## ist dort warm. Diese Gegenfarbe steht hier in `_kupfer()` und liegt
## überall dort, wo etwas GEBAUT ist: an der Klippe des Stegs, als
## Brüstungspaneel an seinem Rand, als Bahn quer über die Trittfläche, als
## Podest unter jeder Kiste. Das Blau bleibt die Nacht, das Kupfer ist die
## Stadt darin.
##
## Kupfer und Mint tragen beide Eigenlicht. Das ist kein Effekt, sondern
## Notwendigkeit: In diesem Level steht kein Licht außer dem
## Umgebungslicht der Stimmungszonen, und ein Metall ohne Lichtquelle ist
## schwarz. Was hier leuchten soll, muss es selbst tun.
##
## WARUM DIE ZÄUNE ALLE `hoehe = 3.0` UND VIER STRAHLEN HABEN: Diese
## Rechnung steht im Kopf von `laserzaun.gd` und ist der Grund, warum das
## Bauteil überhaupt vier verschiedene Aufgaben stellen kann (krabbeln,
## springen, genau springen, doppelspringen). `korridor_level.laserzaun()`
## setzt beide Werte nicht um – das ist Absicht und wird hier nicht
## umgangen.

const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")

# ----------------------------------------------------------- Gegenfarben
## Die warme Hälfte des Bildes. Sie steht hier und nicht im
## `Neonmaterial`, weil sie diesem Level gehört: Der Materialsatz ist der
## Satz der NACHT, das Kupfer ist das, was Menschen hineingebaut haben.
## Satt und dunkel gewählt: Auf die Paneele fällt bläuliches Mondlicht,
## und jede helle Grundfarbe wird darunter zu blassem Sand. Erst ein
## tiefes Kupfer bleibt Kupfer.
const BRONZE := Color(0.17, 0.08, 0.02)      ## #3D1C08 – Paneel im Schatten
const KUPFER := Color(0.62, 0.29, 0.08)      ## #DB6B1A – Paneel im Licht
const KUPFER_HELL := Color(0.92, 0.50, 0.14) ## Leuchtkante der Paneele

## Der Steg in zwei Tönen. Beide sind gesättigt gehalten und keiner
## entsteht durch Aufhellen: `Color.lightened()` mischt Weiß bei, und ein
## Mint mit Weiß darin wird unter dem bläulichen Mondlicht sofort wieder
## grau – genau der Fehler, den das Level vorher hatte.
const STEG_TIEF := Color(0.16, 0.42, 0.35)
const STEG := Color(0.46, 0.88, 0.74)

# ----------------------------------------------------------- Marken
const M_DACHTERRASSE := 0.0
const M_ZAUNSTRASSE := 52.0
const M_SCHWEBEBAHN := 112.0
const M_PUMPTURM := 160.0
const M_REKLAMEGASSE := 226.0
const M_ANTENNE := 292.0
const M_ENDE := 344.0

# ----------------------------------------------------------- Höhen
const ABSTURZ := -8.0
## Oberkante der höchsten Kulissendächer. Sie liegt UNTER der Absturzzone
## (die spannt sich von ABSTURZ−5 bis ABSTURZ), damit kein Sturz auf einem
## Kulissendach endet statt im Tod.
const STADT_KRONE := -15.0
const STADT_SOHLE := -78.0

## Schwebeplattformen: Deckhöhe und begehbare Fläche darüber.
const FLOSS_HOEHE := -0.28
const DECK := FLOSS_HOEHE + Wasserplattform.DECK_STAERKE * 0.5
## Hubbohlen des Pumpturms: oben bündig mit dem Steg, unten außer Reichweite.
const BOHLE_OBEN := -0.20
const BOHLE_UNTEN := -3.60
const BOHLE_DECK := BOHLE_OBEN + Wasserplattform.DECK_STAERKE * 0.5

## Unterkante eines Balkens, unter dem nur Krabbeln durchkommt.
const KRIECHHOEHE := 0.95


const STRECKE := [
	{"von": 0.0, "bis": 52.0, "breite": 14.0, "breite_ende": 10.0},
	{"von": 52.0, "bis": 112.0, "breite": 9.0},
	# Schwebebahn: zwei Absätze, dazwischen nur die fahrenden Plattformen
	{"von": 112.0, "bis": 120.0, "breite": 8.0},
	{"von": 136.0, "bis": 144.0, "breite": 8.0},
	{"von": 160.0, "bis": 178.0, "breite": 9.0},
	# Pumpturm: zwei Löcher, überbrückt von steigenden Bohlen
	{"von": 196.0, "bis": 208.0, "breite": 9.0},
	{"von": 226.0, "bis": 292.0, "breite": 9.0, "breite_ende": 8.0},
	{"von": 292.0, "bis": 344.0, "breite": 7.0, "breite_ende": 9.0},
]

var _mat_kante: StandardMaterial3D = null
var _mat_kupfer: StandardMaterial3D = null
var _mat_kupfer_hell: StandardMaterial3D = null
var _mat_steg: StandardMaterial3D = null


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Die Höhe wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Stege und Dächer", "tun": _boden_bauen},
		{"text": "Die Stadt darunter", "tun": _stadt_bauen},
		{"text": "Leuchtkanten", "tun": _kanten_bauen},
		{"text": "Kupferpaneele", "tun": _paneele_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Ferne Türme", "tun": _horizont_bauen},
		{"text": "Dachterrasse", "tun": _dachterrasse_bauen},
		{"text": "Zaunstraße", "tun": _zaunstrasse_bauen},
		{"text": "Schwebebahn", "tun": _schwebebahn_bauen},
		{"text": "Pumpturm", "tun": _pumpturm_bauen},
		{"text": "Reklamegasse", "tun": _reklamegasse_bauen},
		{"text": "Antennenspitze", "tun": _antenne_bauen},
		{"text": "Seitenansicht", "tun": _kamerazonen_setzen},
		{"text": "Stimmungen", "tun": _stimmungen_setzen},
		{"text": "Portale", "tun": _portale},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
	]


# =========================================================== Verlauf

## Eine große Schleife über den Dächern, die stetig steigt: von y = 0 am
## Start bis y = 16 an der Antennenspitze. Das Steigen ist nicht Zierde –
## am Ende soll die Stadt tiefer unten liegen als am Anfang, sonst wäre
## der letzte Abschnitt nur ein weiterer Steg.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, 1, -18),
		Vector3(6, 2, -40),          # Dachterrasse
		Vector3(18, 3, -60),         # Zaunstraße
		Vector3(36, 4, -74),
		Vector3(58, 5, -82),
		Vector3(80, 6, -80),         # Schwebebahn
		Vector3(100, 7, -70),
		Vector3(114, 8, -52),
		Vector3(120, 9, -32),        # Pumpturm
		Vector3(118, 10, -10),
		Vector3(108, 11, 10),
		Vector3(92, 12, 26),         # Reklamegasse
		Vector3(72, 13, 36),
		Vector3(50, 14, 42),
		Vector3(28, 15, 42),         # Antennenspitze
		Vector3(8, 16, 36),
	])


# =========================================================== Stoffe

## Die Leuchtkante des Weges: ein helleres Mint als der Steg selbst.
##
## Sie war früher cyan. Cyan ist aber dieselbe Farbfamilie wie die
## Fassaden ringsum, und ein cyanfarbenes Band auf einem blaugrauen Steg
## sagt nur "hell", nicht "hier ist der Rand". Mint über Mint sagt beides:
## Der Steg ist ein Band, seine Kante ist die hellere Linie darin – so
## beschreibt es der Steckbrief.
##
## `Neonmaterial.streifen()` gibt eine geteilte Instanz mit voller
## Leuchtstärke heraus – die gehört allen und darf nicht verändert
## werden. Für die Wegkante ist sie zu grell: Ein 344 m langes Band mit
## Stärke 3,2 überstrahlte alles, was darauf steht. Deshalb eine eigene
## Kopie mit gedämpftem Wert, genau wie es der Kopf des Materialsatzes
## vorschlägt.
func _kantenlicht() -> StandardMaterial3D:
	if _mat_kante == null:
		_mat_kante = Neonmaterial.streifen(
				Color(0.72, 1.0, 0.90)).duplicate() as StandardMaterial3D
		_mat_kante.emission_energy_multiplier = 1.0
	return _mat_kante


## Kupferpaneel: die warme Gegenfarbe des Levels.
##
## Metallisch und rau zugleich – ein Spiegel wäre in einem Level ohne
## Lichtquellen schwarz, ein mattes Blech ohne Metallanteil wäre Pappe.
## Das Eigenlicht folgt der Rauschtextur statt einer flachen Farbe:
## Nur so bleibt die Fläche eine Fläche mit Zeichnung und wird nicht zum
## gleichmäßig leuchtenden Rechteck.
func _kupfer() -> StandardMaterial3D:
	if _mat_kupfer == null:
		var zeichnung := Materialbibliothek.rauschtextur(2401, 0.05,
				BRONZE, KUPFER)
		var m := StandardMaterial3D.new()
		m.albedo_texture = zeichnung
		m.emission_enabled = true
		m.emission_texture = zeichnung
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = 0.30
		m.normal_enabled = true
		m.normal_texture = Materialbibliothek.normalmap(2402, 0.11, 1.5)
		m.normal_scale = 0.6
		m.roughness = 0.52
		m.metallic = 0.45
		m.metallic_specular = 0.45
		# Dreiachsig wie der Grundton der Stadt: Paneele stehen hier
		# senkrecht an der Klippe und liegen flach auf dem Steg.
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 1.8
		m.uv1_scale = Vector3(0.32, 0.32, 0.32)
		_mat_kupfer = m
	return _mat_kupfer


## Die glühende Kante eines Kupferpaneels.
##
## Dasselbe Verhältnis wie zwischen Steg und Wegkante: Die Fläche trägt
## die Farbe, ein schmaler Streifen daran macht sie lesbar. Unbeleuchtet,
## damit sie aus jedem Blickwinkel gleich hell bleibt.
func _kupferlicht() -> StandardMaterial3D:
	if _mat_kupfer_hell == null:
		_mat_kupfer_hell = Neonmaterial.streifen(
				KUPFER_HELL).duplicate() as StandardMaterial3D
		_mat_kupfer_hell.emission_energy_multiplier = 0.55
	return _mat_kupfer_hell


## Die Trittfläche des Stegs.
##
## Eine eigene Fassung statt `Neonmaterial.boden()`: Dort ist das Mint auf
## den gemessenen Wert des Vorbilds gesetzt und wird von allem geteilt,
## was die Zukunftsstadt benutzt. Hier soll der Steg das Hellste im Bild
## sein, und unter blauem Umgebungslicht wird jede reflektierte Farbe
## blau. Deshalb ein Eigenlicht auf der eigenen Zeichnung: Der Steg
## leuchtet mintgrün, egal welche Farbe gerade auf ihn fällt.
func _stegboden() -> StandardMaterial3D:
	if _mat_steg == null:
		var zeichnung := Materialbibliothek.rauschtextur(2403, 0.07,
				STEG_TIEF, STEG)
		var m := StandardMaterial3D.new()
		m.albedo_texture = zeichnung
		m.emission_enabled = true
		m.emission_texture = zeichnung
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = 0.34
		m.normal_enabled = true
		m.normal_texture = Materialbibliothek.normalmap(5402, 0.19, 1.1)
		m.normal_scale = 0.45
		# Etwas nasser Glanz wie auf einer Straße bei Nacht, aber nur
		# etwas: Ein stark metallischer Steg spiegelt das blaue Mondlicht
		# und ist wieder grau.
		m.roughness = 0.45
		m.metallic = 0.15
		m.metallic_specular = 0.4
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 1.6
		m.uv1_scale = Vector3(0.34, 0.34, 0.34)
		_mat_steg = m
	return _mat_steg


# =========================================================== Grund

## Der Weg trägt den Materialsatz der Stadt: mintgrüne Trittfläche,
## leuchtende Kante, Kupferpaneele an der Klippe. Damit ist die
## Wegkante von oben wie von der Seite die hellste Linie im Bild – in
## einem Level mit so viel Leere daneben ist das keine Zierde, sondern
## die wichtigste Auskunft, die das Bild geben kann.
##
## Die Klippe ist der größte warme Streifen des Levels: Sie läuft über
## die ganzen 344 m mit und steht in jeder Einstellung genau dort, wo das
## Auge ohnehin hinsieht – an der Kante zwischen Steg und Leere.
func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": _stegboden(),
		"kante": _kantenlicht(),
		# Die Klippe laeuft ueber die vollen 344 m und ist damit die groesste
		# Flaeche im Bild. Kupfer lag hier zunaechst als warmer Gegenpart -
		# gemessen stimmte es dann, gesehen war es falsch: Das Lachsbraun
		# verwaesserte die tiefblaue Neonnacht, von der dieses Level lebt.
		# Der warme Ton bleibt, aber als AKZENT auf Bruestung, Bordbahnen
		# und Dachaufbauten, nicht als Grundflaeche.
		"klippe": Neonmaterial.grund(),
	}, {"tiefe": 2.4, "schritt": 1.0, "kante_hoehe": 0.22, "kante_breite": 0.55})
	luecken_markieren(Neonmaterial.NEON_MAGENTA)


func _absturz_spannen() -> void:
	absturzzonen(16.0, 90.0)


## Ferne Türme statt ferner Hügel: dieselbe Zackenkette, nur in den
## Farben der Nacht. Der Fuß liegt auf der Stadtsohle, damit sich die
## Silhouette hinter den nahen Häusern fortsetzt statt über ihnen zu
## schweben.
func _horizont_bauen() -> void:
	horizont(260.0, 52.0, Neonmaterial.NACHT,
			Neonmaterial.BLAU_TIEF, false, STADT_SOHLE + 6.0)


# =========================================================== Die Stadt

## Die Stadt unter dem Weg.
##
## Gebaut aus `plattform()`-Quadern mit `Neonmaterial.grund()`, dazu
## Glasbänder und Neonstreifen als reine Sichtkörper. Die Türme tragen
## Kollision, weil `plattform()` sie mitbringt; das stört nicht, denn
## ihre Dächer liegen unter `STADT_KRONE` und damit unter der
## Absturzzone – wer fällt, ist tot, bevor er ein Dach erreicht.
##
## Drei Tiefenlagen statt einer: nah und hoch, mittel, fern und tief. Ein
## einzelnes Band von Häusern in gleicher Tiefe liest sich als Tapete;
## erst die Staffelung macht daraus einen Raum, in den man hinunterschaut.
func _stadt_bauen() -> void:
	var wuerfel := randi()
	seed(24001)
	var fassade := Neonmaterial.grund()

	for i in 54:
		var s := randf_range(-24.0, M_ENDE + 24.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var lage := i % 3
		var nah: Array[float] = [16.0, 34.0, 56.0]
		var fern: Array[float] = [34.0, 58.0, 92.0]
		var quer: float = seite * randf_range(nah[lage], fern[lage])
		var dach: float = STADT_KRONE - float(lage) * 9.0 - randf_range(0.0, 14.0)
		var hoch := dach - randf_range(18.0, 46.0)
		var breit := randf_range(7.0, 16.0)
		var tief := randf_range(7.0, 16.0)

		plattform(s, quer, (dach + hoch) * 0.5, Vector3(breit, dach - hoch, tief),
				fassade)

		# Glasfront: ein leuchtendes Stockwerkband je Turm. Ohne dieses
		# Eigenlicht wäre eine Glasfläche bei Nacht ein schwarzes Loch in
		# der Fassade; mit ihm ist sie ein beleuchtetes Stockwerk.
		var baender := randi_range(2, 4)
		for j in baender:
			var y := lerpf(hoch + 4.0, dach - 3.0, (float(j) + 0.5) / float(baender))
			_sichtquader(s, quer, y, Vector3(breit * 1.01, 1.6, tief * 1.01),
					Neonmaterial.glas())

		# Und eine Neonkante auf dem Dach. Die Farbe zählt durch, damit
		# die Stadt nicht in einer einzigen Farbe glüht.
		_sichtquader(s, quer, dach + 0.35,
				Vector3(breit * 1.04, 0.32, tief * 1.04),
				Neonmaterial.streifen(Neonmaterial.NEON[i % 3]))
	seed(wuerfel)


## Ein reiner Sichtkörper ohne Kollision, relativ zum Verlauf gesetzt.
##
## `plattform()` bringt immer einen StaticBody3D mit. Für Glasbänder,
## Neonstreifen und Reklametafeln wäre das Verschwendung: Es sind
## hunderte, und keiner davon soll je etwas tragen.
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


## Leuchtstreifen dicht neben dem Weg, alle 6 m ein Stück.
##
## Sie laufen unterhalb der Wegkante mit und zeichnen den Steg auch dann
## nach, wenn die Kamera flach von der Seite schaut – in der
## Seitenansicht der Antennenspitze ist das der einzige Hinweis darauf,
## wo der Steg aufhört.
func _kanten_bauen() -> void:
	var farben: Array[Color] = [Neonmaterial.NEON_CYAN,
			Neonmaterial.NEON_MAGENTA, Neonmaterial.NEON_GRUEN]
	var i := 0
	for a in STRECKE:
		var s: float = float(a["von"]) + 3.0
		while s < float(a["bis"]) - 2.0:
			var halb := breite_bei(s) * 0.5
			var stoff := Neonmaterial.streifen(farben[(i / 3) % 3])
			for seite: float in [-1.0, 1.0]:
				_sichtquader(s, seite * (halb + 0.12), -0.55,
						Vector3(0.16, 0.5, 4.4), stoff)
			s += 6.0
			i += 1


## Die Kupferpaneele – der warme Gegenpart zur blauen Nacht.
##
## Drei Lagen, weil eine nicht reicht: Ein warmer Ton, der nur am
## Horizont steht, ändert am Eindruck des Weges nichts. Die Wärme muss
## dort liegen, wo man beim Laufen ohnehin hinschaut.
##
##   * Brüstungen knapp AUSSERHALB der Trittfläche. Sie tragen bewusst
##     keine Kollision: Wer über die Kante geht, soll fallen. Eine
##     Brüstung, die hält, nähme dem Level seine einzige Drohung.
##   * Bordbahnen INNEN am Rand der Trittfläche, als flache Bleche. Sie
##     fassen das Mint ein, statt es zu ersetzen.
##   * Querbahnen alle 9 m über den ganzen Steg. Sie geben dem langen
##     Band einen Takt fürs Auge – man sieht beim Laufen, dass man
##     vorankommt.
##
## Die Querbahnen liegen um eine halbe Teilung gegen die Brüstungen
## versetzt, damit nicht alles Warme an derselben Stelle zusammenfällt.
func _paneele_bauen() -> void:
	var paneel := _kupfer()
	var glut := _kupferlicht()
	for a in STRECKE:
		var von: float = float(a["von"])
		var bis: float = float(a["bis"])

		# Bordbahnen: durchgehend, in 4-m-Stücken, damit sie der Biegung
		# folgen. Ein einzelner langer Quader stünde in der Kurve schräg
		# über der Kante.
		var s := von + 1.0
		while s < bis - 1.0:
			var halb := breite_bei(s) * 0.5
			for seite: float in [-1.0, 1.0]:
				_sichtquader(s, seite * (halb - 0.72), 0.03,
						Vector3(1.25, 0.06, 4.1), paneel)
			s += 4.0

		# Querbahnen alle 7 m.
		s = von + 4.0
		while s < bis - 2.0:
			_sichtquader(s, 0.0, 0.03,
					Vector3(maxf(breite_bei(s) - 2.8, 1.0), 0.06, 1.8), paneel)
			s += 7.0

		# Brüstungen alle 6,5 m, versetzt gegen die Querbahnen.
		s = von + 2.5
		while s < bis - 2.0:
			var halb2 := breite_bei(s) * 0.5
			for seite: float in [-1.0, 1.0]:
				var aussen := seite * (halb2 + 0.34)
				_sichtquader(s, aussen, 0.44, Vector3(0.28, 1.05, 3.8), paneel)
				_sichtquader(s, aussen, 0.99, Vector3(0.36, 0.09, 3.9), glut)
			s += 6.5


# =========================================================== Abschnitte

## 0–52 · Dachterrasse. Die Frage: Was tut ein Laserzaun, der nur an und
## aus geht?
##
## Die einfache Betriebsart zuerst: `GLEICHZEITIG` ist eine Tür mit
## Zeitfenster, mehr nicht. Wer sie hier begreift, versteht in der
## Zaunstraße sofort, was die wandernde Lücke daraus macht.
func _dachterrasse_bauen() -> void:
	laserzaun(24.0, 12.0, false, 1.8)
	laserzaun(44.0, 10.6, false, 1.5, 0.4)

	# Ein Aufbau auf dem Dach, über den man springt oder um den man läuft.
	# Kupfer, nicht Fassade: Was auf dem Dach steht, ist Technik – und
	# Technik ist in diesem Level die warme Seite.
	plattform(14.0, -3.4, 0.7, Vector3(4.0, 1.4, 4.0), _kupfer())
	_sichtquader(14.0, -3.4, 1.45, Vector3(4.2, 0.22, 4.2),
			Neonmaterial.streifen(Neonmaterial.NEON_GRUEN))
	plattform(34.0, 3.6, 0.5, Vector3(3.4, 1.0, 3.4), _kupfer())

	# Ein Fließband als Lüftungsschacht: Der Boden hat hier schon ein
	# eigenes Tempo, bevor irgendetwas taktet.
	laufband(6.0, 14.0, 2.0, 0.06, 3.2, 2.4, 1)


## 52–112 · Zaunstraße. Die Frage: In welcher Haltung kommst du durch?
##
## Sechs wandernde Zäune mit gegeneinander versetzten Phasen. Der Trick
## liegt in den Phasen, nicht in der Zahl: Stünden alle im Gleichtakt,
## wäre es EINE Aufgabe, sechsmal gestellt. Versetzt ergibt sich eine
## Kette, in der man mal warten und mal durchlaufen muss – und wer im
## falschen Augenblick losläuft, steht vor dem zweiten Zaun.
##
## Der kürzere Takt (1,0 bis 1,3 s) ist Absicht: Bei einem langen Takt
## wartet man, bis "die eigene" Lücke wieder unten ist, und Warten ist
## keine Aufgabe.
func _zaunstrasse_bauen() -> void:
	var stellen: Array[float] = [58.0, 68.0, 77.0, 88.0, 98.0, 107.0]
	var takte: Array[float] = [1.3, 1.2, 1.1, 1.2, 1.0, 1.1]
	for i in stellen.size():
		laserzaun(stellen[i], 9.0, true, takte[i], float(i) * 0.17)

	# Zwischen den Zäunen zwei Schiebeblöcke: Wer vor einem Zaun wartet,
	# steht nicht sicher.
	schiebeblock(73.0, -3.0, 0.0, Vector3(1.6, 1.2, 1.6), 3.4, true, 1.3, 0.9)
	schiebeblock(93.0, 3.0, 0.0, Vector3(1.6, 1.2, 1.6), 3.4, true, 1.3, 0.9, 0.5)

	# Und ein Balken über dem Weg, unter dem nur Krabbeln durchkommt –
	# dieselbe Haltung wie unter der untersten Lücke eines Zauns, aber
	# ohne Uhr. Die ruhige Übung vor der getakteten Fassung.
	stachelbalken(63.0, 0.0, KRIECHHOEHE, Vector2(6.5, 1.1))


## 112–160 · Schwebebahn. Die Frage: Springst du auf etwas, das fährt?
##
## Zwei Löcher zu je 16 m, jedes von einer Schwebeplattform bedient. Sie
## folgen der Levelkurve, laufen also mit dem Weg um die Biegung, und sie
## fahren zurück – wer den Absprung verpasst, wartet, statt neu anfangen
## zu müssen.
##
## Auf der ersten Plattform steht ein Laserzaun am Zielufer: Man muss
## also nicht nur überfahren, sondern im richtigen Augenblick ankommen.
func _schwebebahn_bauen() -> void:
	var eins := floss(122.0, 134.0, 0.0, FLOSS_HOEHE, Vector2(4.4, 3.6),
			5.0, 1.6, 1.6)
	_neon_anstrich(eins, Neonmaterial.NEON_CYAN)

	# Ein zweites, kleineres Floß versetzt daneben: Wer will, wechselt
	# unterwegs und kommt an die Kisten am Rand.
	var neben := floss(124.0, 132.0, 4.6, FLOSS_HOEHE, Vector2(2.6, 2.6),
			3.4, 1.0, 1.0, 0.5)
	_neon_anstrich(neben, Neonmaterial.NEON_GRUEN)

	var zwei := floss(146.0, 158.0, 0.0, FLOSS_HOEHE, Vector2(4.0, 3.4),
			4.4, 1.4, 1.4, 0.25)
	_neon_anstrich(zwei, Neonmaterial.NEON_MAGENTA)

	# Der Zaun steht auf dem festen Absatz hinter dem ersten Loch.
	laserzaun(138.0, 8.0, true, 1.2, 0.3)
	laserzaun(162.0, 9.0, true, 1.3, 0.6)


## 160–226 · Pumpturm. Die Frage: Steigst du mit, wenn der Boden
## hochfährt?
##
## Zwei Löcher zu je 18 m, und darin steigen und sinken Bohlen. Oben
## stehen sie lange, unten kurz – sonst wäre die Stelle kein Rhythmus,
## sondern eine Wartezeit. Die Phasen laufen als Welle nach vorn: Wer im
## Takt losgeht, läuft durch; wer stehenbleibt, fängt von vorn an.
##
## `BOHLE_UNTEN` liegt bei −3,6 m, also außer Sprungreichweite von unten.
## Eine gesunkene Bohle ist kein Notausstieg, sondern ein fehlender
## Boden.
func _pumpturm_bauen() -> void:
	var erste: Array[float] = [181.0, 185.0, 189.0, 193.0]
	var zweite: Array[float] = [211.0, 215.0, 219.0, 223.0]
	var seiten: Array[float] = [0.0, -1.4, 1.4, 0.0]
	for i in erste.size():
		var a := wehrbohle(erste[i], seiten[i], BOHLE_OBEN, BOHLE_UNTEN,
				float(i) * 0.18, Vector2(3.6, 3.2), 2.6, 1.1)
		_neon_anstrich(a, Neonmaterial.NEON_CYAN)
		var b := wehrbohle(zweite[i], -seiten[i], BOHLE_OBEN, BOHLE_UNTEN,
				0.5 + float(i) * 0.18, Vector2(3.4, 3.0), 2.4, 1.2)
		_neon_anstrich(b, Neonmaterial.NEON_MAGENTA)

	# Auf dem Absatz dazwischen: eine Drehscheibe, die den Anlauf für das
	# zweite Loch verdreht. Ein Hindernis mit zwei Rollen – sie ist Boden
	# und Störung zugleich.
	drehscheibe(202.0, 0.0, 0.15, 4.2, 26.0)
	taktflaeche(198.0, -2.6, Vector2(2.6, 2.6), 0.0)
	taktflaeche(206.0, 2.6, Vector2(2.6, 2.6), 0.5)

	# Vor beiden Löchern ein Zaun: Man springt nicht nur auf die Bohle,
	# man springt zum richtigen Zeitpunkt los.
	laserzaun(174.0, 9.0, true, 1.2, 0.0)
	laserzaun(230.0, 9.0, true, 1.1, 0.45)


## 226–292 · Reklamegasse. Die Frage: Takt und Gegner zugleich, auf
## einem Steg, der schmaler wird.
##
## Der erste Abschnitt mit vielen Gegnern. Bis hierher hat die Stadt
## selbst die Schwierigkeit getragen; jetzt kommt dazu, dass man
## zwischen zwei Zäunen jemanden loswerden muss. Die Reklametafeln an den
## Seiten sind nicht nur Zierde – sie geben dem Auge, das die ganze Zeit
## in die Leere geschaut hat, wieder eine Wand.
func _reklamegasse_bauen() -> void:
	for i in 9:
		var s := 232.0 + float(i) * 7.0
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		_sichtquader(s, seite * 7.5, 3.6, Vector3(0.5, 5.4, 4.6),
				_kupfer())
		_sichtquader(s, seite * 7.1, 3.6, Vector3(0.24, 4.6, 3.8),
				Neonmaterial.streifen(Neonmaterial.NEON[i % 3]))

	taktwelle(238.0, 254.0, 5, 0.0, Vector2(2.8, 2.8), 0.22)
	laserzaun(262.0, 9.0, true, 1.1, 0.2)
	feuerspeier(270.0, -3.4, 1.0, 0.0, 3.2, 0.0)
	feuerspeier(278.0, 3.4, 1.0, 180.0, 3.2, 0.5)
	laserzaun(286.0, 8.4, true, 1.0, 0.55)

	laufband(244.0, 252.0, 0.0, 0.06, 3.4, 2.4, -1)
	deckungsfleck(258.0, 2.4)


## 292–344 · Antennenspitze. Die Frage: alles auf einmal, und dabei nach
## unten schauen.
##
## Der schmalste Abschnitt liegt am höchsten Punkt, und die Kamera
## schwenkt hier zur Seite. Das ist der Sinn der ganzen Kulisse: Erst in
## der Seitenansicht sieht man, wie weit unten die Stadt liegt – von
## hinten schaut man immer nur nach vorn.
func _antenne_bauen() -> void:
	laserzaun(300.0, 7.0, true, 1.1, 0.0)
	laserzaun(312.0, 7.4, true, 1.0, 0.35)
	laserzaun(326.0, 8.2, true, 1.0, 0.7)

	bruchplatten_reihe(304.0, 310.0, 3, 0.0, -0.08)
	schiebeblock(318.0, -2.4, 0.0, Vector3(1.6, 1.2, 1.6), 3.0, true, 1.2, 0.8)
	stachelbalken(332.0, 0.0, KRIECHHOEHE, Vector2(6.0, 1.1))

	# Die Antenne selbst: ein Mast am Ende, damit der höchste Punkt des
	# Levels auch von weitem einer ist.
	_sichtquader(340.0, 0.0, 9.0, Vector3(0.5, 18.0, 0.5),
			_kupfer())
	for i in 4:
		_sichtquader(340.0, 0.0, 4.0 + float(i) * 3.4,
				Vector3(2.2 - float(i) * 0.4, 0.22, 2.2 - float(i) * 0.4),
				Neonmaterial.streifen(Neonmaterial.NEON_CYAN))


## Streicht eine Schwebeplattform in den Farben der Stadt.
##
## `Wasserplattform` baut ihr Aussehen in `_ready()` und nimmt ihre Farbe
## nur VOR `add_child()` an – die Bauhilfen in `korridor_level.gd` hängen
## sie aber selbst ein. Statt die Bauhilfe zu ändern, wird hier
## nachträglich das Material aller Sichtkörper überschrieben: Ein Floß
## aus Baumstämmen wäre in einer Zukunftsstadt ein Fremdkörper.
func _neon_anstrich(scheibe: Wasserplattform, farbe: Color) -> void:
	var rumpf := _kupfer()
	var stapel: Array[Node] = [scheibe]
	while not stapel.is_empty():
		var k: Node = stapel.pop_back()
		for kind in k.get_children():
			stapel.push_back(kind)
		if k is MeshInstance3D:
			(k as MeshInstance3D).material_override = rumpf

	# Dazu ein Leuchtrahmen rings um das Deck. Er hängt unter "Bild" und
	# wippt deshalb mit. Ein durchgehend leuchtendes Deck wäre eine
	# Fläche ohne Form – ein Rahmen dagegen zeigt genau das, worauf es
	# hier ankommt: wo die Plattform aufhört.
	var bild := scheibe.get_node_or_null("Bild")
	if bild == null:
		return
	var licht := Neonmaterial.streifen(farbe)
	var oben := Wasserplattform.DECK_STAERKE * 0.5 + 0.05
	var x := scheibe.groesse.x * 0.5 + 0.06
	var z := scheibe.groesse.y * 0.5 + 0.06
	var kanten := [
		[Vector3(scheibe.groesse.x + 0.24, 0.1, 0.14), Vector3(0.0, oben, -z)],
		[Vector3(scheibe.groesse.x + 0.24, 0.1, 0.14), Vector3(0.0, oben, z)],
		[Vector3(0.14, 0.1, scheibe.groesse.y + 0.24), Vector3(-x, oben, 0.0)],
		[Vector3(0.14, 0.1, scheibe.groesse.y + 0.24), Vector3(x, oben, 0.0)],
	]
	for kante: Array in kanten:
		var balken := MeshInstance3D.new()
		var form := BoxMesh.new()
		form.size = kante[0]
		balken.mesh = form
		balken.material_override = licht
		balken.position = kante[1]
		bild.add_child(balken)


# =========================================================== Kamera

## Die Antennenspitze läuft als Seitenansicht.
##
## Gewählt ist genau der Abschnitt, in dem es um Sprungweiten und um die
## Tiefe darunter geht: Von der Seite ist beides abzuschätzen, von hinten
## keines von beiden.
func _kamerazonen_setzen() -> void:
	kamerazone(298.0, 338.0, 17.0, 3.2)


## Licht und Nebel je Abschnitt.
##
## Drei Stimmungen: Über den Dächern steht der Dunst blau und dicht, in
## der Reklamegasse färbt ihn das Neon violett, an der Antennenspitze
## reißt er auf – ganz oben ist die Luft klar, und man sieht bis zum
## Horizont.
func _stimmungen_setzen() -> void:
	stimmung(0.0, 112.0, Neonmaterial.BLAU_TIEF, 0.018, 0.65,
			Neonmaterial.BLAU, 60.0)
	stimmung(226.0, 292.0, Color(0.24, 0.12, 0.30), 0.018, 0.7,
			Color(0.42, 0.24, 0.52), 60.0)
	stimmung(294.0, M_ENDE, Neonmaterial.NACHT, 0.008, 0.65,
			Neonmaterial.BLAU_TIEF, 60.0)


# =========================================================== Portale

func _portale() -> void:
	portale_setzen(1.0, 5.0)


# =========================================================== Kisten

## Eine Kiste auf einem beleuchteten Podest.
##
## Kisten sind Holzkästen in Erdfarben – im Wald leuchten sie, in dieser
## Nacht waren sie dunkle Kästen auf dunklem Weg und schlicht nicht zu
## finden. Die `Kiste` selbst umzufärben verbietet sich: Der Kistenvertrag
## gilt über alle 25 Level, und eine Kiste, die hier anders aussieht als
## dort, kostet mehr, als sie einbringt.
##
## Also bleibt die Kiste, wie sie ist, und der Steg unter ihr ändert sich:
## eine glühende Kupferplatte mit hellem Rand. Die Kiste steht dadurch als
## dunkle Silhouette in einem hellen Fleck – dieselbe Lesehilfe, die die
## Stadt ringsum benutzt, nur umgedreht.
##
## Nur für Kisten, die auf dem Steg stehen. Eine gestapelte Kiste bekommt
## keins: Ihr Podest ist die Kiste darunter.
func _podestkiste(art: Kiste.Art, strecke: float, seitlich: float) -> void:
	kiste(art, strecke, seitlich)
	_sichtquader(strecke, seitlich, 0.02, Vector3(1.62, 0.05, 1.62),
			_kupferlicht())
	_sichtquader(strecke, seitlich, 0.045, Vector3(1.34, 0.05, 1.34),
			_kupfer())


## 51 Kisten. Auf den Absätzen der Schwebebahn und des Pumpturms stehen
## bewusst wenige: Dort ist der Platz knapp, und eine Kiste, die man
## zwischen zwei Sprüngen zerschlagen soll, ist keine Belohnung, sondern
## eine Falle.
func _kisten_setzen() -> void:
	# ---------- Dachterrasse ----------
	_podestkiste(Kiste.Art.CHECKPOINT, 4.0, -3.0)
	_podestkiste(Kiste.Art.NORMAL, 10.0, -3.0)
	_podestkiste(Kiste.Art.NORMAL, 10.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 10.0, 3.0)
	_podestkiste(Kiste.Art.FRUCHT_MEHRFACH, 18.0, 0.0)
	_podestkiste(Kiste.Art.EISEN, 30.0, -2.6)
	kiste(Kiste.Art.NORMAL, 30.0, -2.6, 1.6, true)
	_podestkiste(Kiste.Art.SCHUTZ, 38.0, 2.6)
	_podestkiste(Kiste.Art.NORMAL, 48.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 48.0, -2.4)

	# ---------- Zaunstraße: immer zwischen zwei Zäunen ----------
	_podestkiste(Kiste.Art.NORMAL, 54.0, -2.4)
	_podestkiste(Kiste.Art.CHECKPOINT, 62.0, 2.4)
	_podestkiste(Kiste.Art.NORMAL, 72.0, -2.4)
	_podestkiste(Kiste.Art.TNT, 82.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 82.0, -2.2)
	_podestkiste(Kiste.Art.NORMAL, 82.0, 2.2)
	_podestkiste(Kiste.Art.FRUCHT_MEHRFACH, 93.0, -2.2)
	_podestkiste(Kiste.Art.NORMAL, 103.0, 2.4)
	_podestkiste(Kiste.Art.SCHUTZ, 110.0, 0.0)

	# ---------- Schwebebahn: nur auf den Absätzen ----------
	_podestkiste(Kiste.Art.CHECKPOINT, 116.0, -2.2)
	_podestkiste(Kiste.Art.NORMAL, 118.0, 2.2)
	_podestkiste(Kiste.Art.NORMAL, 140.0, -2.2)
	_podestkiste(Kiste.Art.FRUCHT_MEHRFACH, 142.0, 2.2)
	_podestkiste(Kiste.Art.NORMAL, 164.0, -2.4)
	_podestkiste(Kiste.Art.NORMAL, 164.0, 2.4)

	# ---------- Pumpturm ----------
	_podestkiste(Kiste.Art.CHECKPOINT, 172.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 176.0, -2.6)
	_podestkiste(Kiste.Art.SCHUTZ, 199.0, -2.6)
	_podestkiste(Kiste.Art.NORMAL, 206.0, 2.6)
	_podestkiste(Kiste.Art.NORMAL, 228.0, -2.4)
	_podestkiste(Kiste.Art.NORMAL, 228.0, 2.4)

	# ---------- Reklamegasse: hier ist Platz für Stapel ----------
	_podestkiste(Kiste.Art.CHECKPOINT, 232.0, 0.0)
	_podestkiste(Kiste.Art.EISEN, 236.0, -3.0)
	kiste(Kiste.Art.NORMAL, 236.0, -3.0, 1.6, true)
	kiste(Kiste.Art.NORMAL, 236.0, -3.0, 2.6, true)
	_podestkiste(Kiste.Art.NORMAL, 248.0, 3.0)
	_podestkiste(Kiste.Art.FRUCHT_MEHRFACH, 256.0, 0.0)
	_podestkiste(Kiste.Art.NITRO, 266.0, -2.6)
	_podestkiste(Kiste.Art.NORMAL, 266.0, 2.6)
	_podestkiste(Kiste.Art.FEDER, 274.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 282.0, -2.6)
	_podestkiste(Kiste.Art.NORMAL, 282.0, 2.6)
	_podestkiste(Kiste.Art.LEBEN, 290.0, 0.0)

	# ---------- Antennenspitze ----------
	_podestkiste(Kiste.Art.CHECKPOINT, 296.0, -2.0)
	_podestkiste(Kiste.Art.NORMAL, 296.0, 2.0)
	_podestkiste(Kiste.Art.NORMAL, 308.0, 0.0)
	_podestkiste(Kiste.Art.SCHUTZ, 316.0, 2.0)
	_podestkiste(Kiste.Art.NORMAL, 322.0, -2.0)
	_podestkiste(Kiste.Art.FRUCHT_MEHRFACH, 330.0, 0.0)
	_podestkiste(Kiste.Art.NORMAL, 336.0, -2.4)
	_podestkiste(Kiste.Art.NORMAL, 336.0, 2.4)


# =========================================================== Gegner

## 17 Gegner. Keiner steht auf einer fahrenden Plattform oder einer
## Hubbohle: Er stünde dort still im Raum, während der Boden unter dem
## Spieler wegfährt, und das ist keine Aufgabe, sondern ein Ärgernis.
func _gegner_setzen() -> void:
	# ---------- Dachterrasse ----------
	gegner(PANZERKAEFER, 12.0, -2.5, 4.0, true)
	gegner(SUMPFKROETE, 28.0, 2.0, 3.5, true)
	gegner(STELZENSPINNE, 42.0, -2.0, 3.0, true)

	# ---------- Zaunstraße: wenige, der Takt trägt hier ----------
	gegner(SUMPFKROETE, 66.0, 0.0, 2.2, true)
	gegner(PANZERKAEFER, 85.0, 0.0, 2.4, true)
	gegner(STELZENSPINNE, 102.0, 0.0, 2.2, true)

	# ---------- Schwebebahn: nur auf den Absätzen ----------
	gegner(PANZERKAEFER, 116.0, 0.0, 1.8, true)
	gegner(SUMPFKROETE, 167.0, 0.0, 2.2, true)

	# ---------- Pumpturm ----------
	gegner(STELZENSPINNE, 202.0, 0.0, 2.0, true)
	werfer(172.0, 2.6)

	# ---------- Reklamegasse: die dichteste Stelle ----------
	gegner(PANZERKAEFER, 240.0, -2.6, 3.6, true)
	gegner(SUMPFKROETE, 252.0, 2.4, 3.0, true)
	werfer(260.0, -2.8)
	schwarm(272.0, 0.0, 11.0)
	gegner(STELZENSPINNE, 284.0, 2.4, 2.8, true)

	# ---------- Antennenspitze ----------
	gegner(PANZERKAEFER, 314.0, 0.0, 2.0, true)
	gegner(SUMPFKROETE, 330.0, 0.0, 2.0, true)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(5.0, 48.0, 16, 0.0)
	fruechte_reihe(55.0, 110.0, 20, 0.0)
	# Über den beiden Löchern der Schwebebahn: die Spur zeigt die Fahrt an.
	fruechte_reihe(122.0, 134.0, 6, 0.0, DECK + 0.9)
	fruechte_reihe(146.0, 158.0, 6, 0.0, DECK + 0.9)
	fruechte_reihe(162.0, 176.0, 6, 0.0)
	fruechte_reihe(181.0, 193.0, 5, 0.0, BOHLE_DECK + 0.9)
	fruechte_reihe(197.0, 207.0, 5, 0.0)
	fruechte_reihe(211.0, 223.0, 5, 0.0, BOHLE_DECK + 0.9)
	fruechte_bogen(228.0, 236.0, 5, 0.0, 2.2)
	fruechte_reihe(238.0, 290.0, 18, 0.0)
	fruechte_reihe(294.0, 340.0, 16, 0.0)
