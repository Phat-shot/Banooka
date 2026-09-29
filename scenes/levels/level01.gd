extends LevelBasis
## Level 01 – "Wurzelschlucht"
##
## Ein kurviger Waldpfad in fünf Abschnitten. Der Verlauf steckt in einer
## Kurve; alle Objekte werden über `LevelWerkzeuge.punkt(verlauf, strecke,
## seitlich, hoehe)` relativ dazu platziert. Wer den Verlauf ändert,
## verschiebt damit automatisch alles Übrige mit.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  42  Waldrand   – Anlaufstrecke, erste Kisten, Draufspring-Gegner
##    42 – 100  Schlucht   – Rechtskurve, Bach mit Lücken, Federkiste, Spin-Gegner
##   100 – 158  Stacheln   – Linkskurve, Stachelfelder, Slide-Gegner, TNT
##   158 – 208  Kronen     – Anstieg, schmaler Grat, Sprungkisten, Nitro
##   208 – 236  Lichtung   – Lebenskiste, Zielportal

const KISTE := preload("res://scenes/crates/Kiste.tscn")
const FRUCHT := preload("res://scenes/fruits/Frucht.tscn")
const SUMPFKROETE := preload("res://scenes/enemies/Sumpfkroete.tscn")
const STELZENSPINNE := preload("res://scenes/enemies/Stelzenspinne.tscn")
const PANZERKAEFER := preload("res://scenes/enemies/Panzerkaefer.tscn")
const WASSER := preload("res://scenes/hazards/Wasser.tscn")
const STACHELN := preload("res://scenes/hazards/Stacheln.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const WURZEL := preload("res://scenes/props/Wurzel.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const STAUB := preload("res://scenes/props/Staub.tscn")
const LAUBTREIBEN := preload("res://scenes/props/Laubtreiben.tscn")
const VOEGEL := preload("res://scenes/props/Voegel.tscn")
const HORIZONT := preload("res://scenes/props/Horizont.tscn")
const STIMMUNGSZONE := preload("res://scenes/props/Stimmungszone.tscn")

# Strecken-Marken der Abschnitte
const M_WALDRAND := 0.0
const M_SCHLUCHT := 42.0
const M_STACHELN := 100.0
const M_KRONEN := 158.0
const M_LICHTUNG := 208.0
const M_ENDE := 236.0

# Höhen relativ zum Weg
const WALDBODEN_HOEHE := -14.0  ## sichtbarer Waldboden tief unter dem Pfad
const ABSTURZ_HOEHE := -6.0     ## darunter ist der Sturz tödlich
const WASSER_HOEHE := -13.4     ## Bachlauf am Grund der Schlucht (nur Kulisse)

## Die Schluchtwand; ihr Metadatum "kronen" trägt Lagen und Krone jeder
## Säule für den Bewuchs.
var _wand: Node3D


func _baue() -> void:
	for schritt in _bauschritte():
		var tun: Callable = schritt["tun"]
		tun.call()


## Aufbau in Einzelschritten, damit der Ladebildschirm mitläuft.
func _bauschritte() -> Array:
	return [
		{"text": "Wegverlauf", "tun": _verlauf_anlegen},
		{"text": "Waldboden", "tun": _waldboden_bauen},
		{"text": "Schluchtwände türmen sich", "tun": _waende_bauen},
		{"text": "Wurzeln, Ranken und ein Wasserfall", "tun": _bewuchs_bauen},
		{"text": "Weg wird angelegt", "tun": _boden_bauen},
		{"text": "Plattformen", "tun": _plattformen_bauen},
		{"text": "Baumkronen unter dem Grat", "tun": _kronenwald},
		{"text": "Blattwerk am Schluchtrand", "tun": _rankenwerk},
		{"text": "Farne und Pilze", "tun": _wegdeko},
		{"text": "Portale", "tun": _portale_setzen},
		{"text": "Bach und Stacheln", "tun": _gefahren_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Gegner beziehen Stellung", "tun": _gegner_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Staub, Laub und Vögel", "tun": _bewegung_setzen},
		{"text": "Blick ins Tal", "tun": _ausblick},
		{"text": "Licht und Dunst", "tun": _stimmungen},
	]


## Der Weg durch den Wald: zwei große Kurven und ein Anstieg zum Ziel.
func _verlauf_anlegen() -> void:
	# Staub beim Landen und Rennen: die Farbe des Waldwegs, eine Spur ins
	# Kiesgrau – der Weg ist ausgetreten, nicht frisch geharkt. Die Farbe
	# überlebt den Szenenwechsel, deshalb setzt sie jedes Level selbst.
	Effekte.staubfarbe = Farben.WEG_HELL.lerp(Farben.KIES_HELL, 0.3)
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 4),        # Startportal
		Vector3(0, 0, -18),      # gerade Anlaufstrecke
		Vector3(3, 0, -36),      # Beginn der Rechtskurve
		Vector3(13, 0, -52),     # Schlucht
		Vector3(28, 1, -63),
		Vector3(45, 1, -70),     # Ende der Rechtskurve
		Vector3(62, 2, -80),     # Stachelpassage, Linkskurve beginnt
		Vector3(72, 3, -98),
		Vector3(74, 4, -120),
		Vector3(68, 6, -140),    # Anstieg in die Baumkronen
		Vector3(56, 8, -156),
		Vector3(40, 9, -168),
		Vector3(22, 10, -175),   # Lichtung
		Vector3(4, 10, -178),
	])


## Bodenstreifen mit Lücken. Die Lücken sind die Sprungpassagen –
## darunter liegt je nach Abschnitt Wasser oder Abgrund.
## Bodenstreifen mit Lücken. Die Lücken sind die Sprungpassagen –
## darunter liegt der Waldboden, abgefangen von der Absturzzone.
## Diese Liste ist die einzige Quelle für den Wegverlauf: `_breite_bei()`
## liest sie ebenfalls aus, damit Objekte nie neben dem Weg landen.
const ABSCHNITTE := [
	# --- Waldrand: breit und sicher, eine kleine Lücke zum Üben ---
	{"von": 0.0, "bis": 26.0, "breite": 11.0},
	{"von": 30.0, "bis": 42.0, "breite": 10.0},
	# --- Schlucht: schmaler, zwei Lücken über dem Bach ---
	{"von": 42.0, "bis": 56.0, "breite": 9.0, "breite_ende": 7.0},
	{"von": 62.0, "bis": 74.0, "breite": 7.0},
	{"von": 80.0, "bis": 100.0, "breite": 8.0, "breite_ende": 10.0},
	# --- Stachelpassage: breit genug zum Ausweichen ---
	{"von": 100.0, "bis": 128.0, "breite": 10.0},
	{"von": 132.0, "bis": 158.0, "breite": 9.0},
	# --- Baumkronen: schmaler Grat mit Lücken ---
	{"von": 158.0, "bis": 172.0, "breite": 7.0},
	{"von": 178.0, "bis": 190.0, "breite": 6.0},
	{"von": 196.0, "bis": 208.0, "breite": 7.0, "breite_ende": 9.0},
	# --- Lichtung: weite Fläche zum Abschluss ---
	{"von": 208.0, "bis": 236.0, "breite": 13.0},
]

## Die Schluchtwände links und rechts. "Wurzelschlucht" hieß das Level von
## Anfang an – ausgesehen hat es aber wie ein Grat im Nebel: ein heller
## Streifen über einer leeren Fläche, ohne etwas, das den Blick rahmt. Die
## Vorlagen machen es umgekehrt: der Weg ist eng gefasst, die Ränder laufen
## dunkel aus, und dazwischen ist kein Loch, sondern dichte Wand.
##
## `abstand` ist der Abstand von der Wegmitte. In den meisten Abschnitten
## steht die Wand unmittelbar an der Wegkante. Ausnahme sind die Baumkronen
## (158–208): Dort ist der schmale Grat die Aufgabe, also weicht die Wand
## zurück und bleibt reine Kulisse – seitlich herunterfallen kann man dort
## weiterhin. Sie weicht weit zurück und bleibt niedrig: Nach 150 Metern
## Schlucht öffnet sich hier zum ersten Mal der Blick, über ein Meer aus
## Baumkronen, aus dem die Riesen des `_kronenwald()` steigen.
##
## Die Abschnitte überlappen sich um gut einen Meter. Stießen sie genau
## aneinander, klaffte in der Kurve dort, wo der Abstand wechselt, ein
## senkrechter Schlitz, durch den helles Grün von draußen hereinschien.
##
## Die niedrigen Wände der Kronen und der Lichtung stehen in der Sonne statt
## im Schatten der Schlucht. Mit dem Helligkeitsverlauf der hohen Wände
## waren ihre Blockköpfe die hellsten, buntesten Flächen im Bild – heller
## als der Weg und wieder wie Pappkartons. Sie bekommen einen eigenen,
## dunkleren Verlauf.
const WAENDE := [
	{"von": -8.0, "bis": 43.2, "abstand": 5.9, "hoehe": 9.5},
	{"von": 40.8, "bis": 101.2, "abstand": 5.2, "hoehe": 11.0},
	{"von": 98.8, "bis": 159.2, "abstand": 5.6, "hoehe": 10.0},
	{"von": 156.8, "bis": 209.2, "abstand": 12.5, "hoehe": 6.0,
			"helligkeit": Vector2(0.55, 0.84)},
	{"von": 206.8, "bis": 247.0, "abstand": 7.2, "hoehe": 6.5,
			"helligkeit": Vector2(0.55, 0.84)},
]

## Abschnitte, in denen die Wand am Weg steht und deshalb eine glatte
## Leitwand davor braucht. Auf dem Grat der Baumkronen fehlt sie mit
## Absicht: Dort soll man abstürzen können.
const LEITWAENDE := [
	{"von": 0.0, "bis": 42.0, "abstand": 5.3},
	{"von": 42.0, "bis": 100.0, "abstand": 4.3},
	{"von": 100.0, "bis": 158.0, "abstand": 4.9},
	{"von": 208.0, "bis": 236.0, "abstand": 6.6},
]


## Die beiden Schluchtwände.
##
## Drei Schichten, wie im Schneelevel: warmes Wurzelgestein als Grundton,
## Bänder aus dunkler Walderde darüber und eine Moosnarbe als Saum auf der
## obersten Lage. Der erste Entwurf nahm das Wurzelmaterial für die Bänder;
## das ist grünlich und ergab zusammen mit der Grasnarbe eine Wand aus
## Limettenwürfeln. Die Wand trägt keine Kollision – dafür steht die glatte
## Leitwand davor, an deren Kästen man nicht hängen bleibt.
##
## Die Schichten laufen in Weltkoordinaten durch die ganze Wand
## (`welt_projektion`): Jeder Block trug vorher dasselbe Stück Muster, nur
## gestreckt, und die Wand las sich als Stapel Pappkartons. Eine Kachel von
## gut drei Metern Höhe gibt Bänder um einen Meter, waagerecht länger
## gezogen – so liegen Schichten: flach, lang und über viele Blöcke hinweg.
##
## Dunkler als früher (`helligkeit`): Die obere Wand war so hell wie der
## Weg. Der Lesbarkeitsvertrag verlangt es umgekehrt – der Weg ist das
## Hellste im Bild, der Fels rahmt ihn.
func _waende_bauen() -> void:
	_wand = LevelWerkzeuge.schluchtwand(geometrie, verlauf, WAENDE,
			Materialbibliothek.wurzelfels(), {
		"schritt": 2.4, "lagen": 4, "block": 3.2,
		"sockel": 16.0, "saat": 1801,
		"adermaterial": Materialbibliothek.waldboden(),
		"deckmaterial": Materialbibliothek.moos(),
		"aderdichte": 0.45,
		"welt_projektion": true,
		"welt_kachel": Vector3(0.19, 0.3, 0.19),
		"helligkeit": Vector2(0.58, 1.04),
		"kronen_merken": true,
	})
	for w in LEITWAENDE:
		LevelWerkzeuge.leitwand(geometrie, verlauf, w["von"], w["bis"],
				w["abstand"], 5.0)

	# Zwischen Wegkante und Wandfuß klaffte ein Spalt bis hinab zum
	# Waldboden; wo die Sonne unten hinfiel, stand er als heller Strich
	# neben dem Weg. Ein Erdsims schließt ihn, knapp unter der Kante –
	# rein optisch, hinter der Leitwand kommt ohnehin niemand hin. Er folgt
	# den Wegstücken und hört an jeder Lücke auf: Liefe er an der Wand
	# weiter, sähe er aus wie ein Pfad um das Loch herum.
	var simse: Array = []
	for a in ABSCHNITTE:
		var von: float = a["von"]
		var bis: float = a["bis"]
		var wand := _wand_bei((von + bis) * 0.5)
		var abstand: float = wand["abstand"]
		if abstand > 8.0:
			continue
		var breite := minf(float(a["breite"]), float(a.get("breite_ende", a["breite"])))
		simse.append({"von": von, "bis": bis, "innen": breite * 0.5 - 0.3,
				"aussen": abstand + 0.5, "hoehe": -0.3})
	var sims := LevelWerkzeuge.sims(geometrie, verlauf, simse,
			Materialbibliothek.waldboden(), 2.0)
	_ohne_schatten(sims)


## Bewuchs an den Wänden – Blattsaum auf der Krone, Ranken, Wurzeln, Farne
## auf den Simsen, große Blätter und Blüten am Wandfuß (siehe
## `Schluchtsaum`) – und die Wahrzeichen, die an der Wand hängen: der
## Wasserfall, die Wurzeltore und ein umgestürzter Stamm. Alles wächst an
## genau der Wand, die `_waende_bauen()` gesetzt hat.
func _bewuchs_bauen() -> void:
	var kronen: Array = _wand.get_meta("kronen", [])
	# Drei Aufrufe über getrennte Säulen – die Stücke sind ohnehin nach
	# Strecke geteilt:
	#   Schlucht  kaum Blüten. Jeder helle Tupfer auf dem dunklen Fels zog
	#             den Blick vom Weg weg, und in Massen las es sich als
	#             Konfetti.
	#   Kronen    niedrige Wände in der Sonne: dichter Blattsaum, der die
	#             Blockköpfe bricht.
	#   Lichtung  blüht üppig und auch hell – sie ist die Belohnung am Ende
	#             und nach der Schlucht der erste Ort mit Farbe.
	var schlucht: Array = []
	var grat: Array = []
	var lichtung: Array = []
	for eintrag in kronen:
		var e: Dictionary = eintrag
		var s: float = e["s"]
		# Bis wohin die Pflanzen am Wandfuß reichen dürfen: bis kurz vor die
		# Außenkante des Weges, über die äußere Hälfte der Rasenkante, nie
		# darüber hinaus. An einer Lücke gilt der Weg daneben.
		var breite := maxf(_breite_bei(s), maxf(_breite_bei(s - 3.0), _breite_bei(s + 3.0)))
		e["weg_rand"] = breite * 0.5 - 0.3 if breite > 0.0 else float(e["abstand"]) - 1.0
		if s >= M_LICHTUNG - 2.0:
			lichtung.append(e)
		elif float(e["abstand"]) > 8.0:
			grat.append(e)
		else:
			schlucht.append(e)
	var bewuchs := {
		"saat": 1802,
		"saum": 2.0,
		"ranken": 2.4,
		"simse": 0.8,
		"fuss": 0.45,
		"blueten": 0.4,
	}
	Schluchtsaum.bauen(deko, verlauf, schlucht, bewuchs)
	bewuchs["saat"] = 1804
	bewuchs["saum"] = 3.0
	Schluchtsaum.bauen(deko, verlauf, grat, bewuchs)
	bewuchs["saat"] = 1803
	bewuchs["blueten"] = 2.0
	bewuchs["helle_blueten"] = true
	Schluchtsaum.bauen(deko, verlauf, lichtung, bewuchs)

	# Der Wasserfall am Ende der ersten langen Geraden: Wer aus dem
	# Waldrand kommt, schaut in der Rechtskurve genau auf diese Wand. Er
	# stürzt mitten in die erste Lücke über dem Bach – der Abgrund bekommt
	# damit eine Tiefe, die man sieht, und die Lücke ist von Weitem als
	# Lücke da. Stand er an ihrem Anfang, schien er auf der Wegkante neben
	# der Kiste aufzuschlagen.
	const FALL_STRECKE := 59.5
	Wasserfall.an_schluchtwand(deko, verlauf, kronen, FALL_STRECKE, -1.0, 4.2, -12.0)
	# Gischt, wo er unten aufschlägt: Wer über die Lücke springt, sieht
	# hinab in Dunst statt auf das Ende eines Bandes.
	var gischt := STAUB.instantiate() as Staubflug
	gischt.raum = Vector3(4.0, 8.0, 4.0)
	gischt.anzahl = 26
	gischt.groesse = 0.45
	gischt.groessen_streuung = 0.4
	gischt.farbe = Color(0.78, 0.88, 0.9)
	gischt.deckkraft = 0.16
	gischt.steiggeschwindigkeit = 0.9
	gischt.wirbel = 0.6
	gischt.funkeln = 0.0
	gischt.saat = 5960
	gischt.position = LevelWerkzeuge.punkt(verlauf, FALL_STRECKE,
			-(float(_wand_bei(FALL_STRECKE)["abstand"]) - 1.4), -12.5)
	deko.add_child(gischt)

	# Wurzeltore an den Abschnittswechseln: Sie geben dem Weg einen Takt,
	# und jedes kündigt an, dass danach etwas Neues kommt.
	for eintrag: Array in [[42.0, 5.5], [100.0, 5.4], [157.0, 5.6]]:
		var strecke: float = eintrag[0]
		Schluchtsaum.wurzeltor(deko, verlauf, strecke, eintrag[1], 4200 + int(strecke))

	# Ein umgestürzter Baumriese, der hoch über der TNT-Kiste von Krone zu
	# Krone liegt – aus der Schlucht schon von Weitem als Silhouette gegen
	# den Himmel zu sehen. Seine Ranken enden über der Kamera, auch wenn
	# die Figur darunter doppelt springt.
	var a := _kronenpunkt(kronen, 85.5, -1.0)
	var b := _kronenpunkt(kronen, 93.5, 1.0)
	Schluchtsaum.baumstamm(deko, a, b, 0.85,
			LevelWerkzeuge.punkt(verlauf, 89.5).y + Schluchtsaum.KAMERA_FREI, 9001)


## Auflagepunkt auf der Wandkrone bei `strecke`: ein Stück hinter der
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
		return LevelWerkzeuge.punkt(verlauf, strecke, seite * 8.0, 11.0)
	return LevelWerkzeuge.punkt(verlauf, strecke,
			seite * (float(beste["innen"]) + 1.0), float(beste["oben"]) + 0.6)


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, ABSCHNITTE, {
		"oben": Materialbibliothek.waldweg(),   # Erde: hebt sich vom Grün ab
		"kante": Materialbibliothek.gras(),     # erhöhte Rasenkante als Begrenzung
		"klippe": Materialbibliothek.fels(),    # Felswand macht die Tiefe sichtbar
	}, {
		"tiefe": 15.5,
		"schritt": 1.0,
		"kante_hoehe": 0.45,
		"kante_breite": 0.8,
	})


## Bewegung in der Kulisse.
##
## Ohne das wirkt die Schlucht wie ein Standbild: Der Wind wiegt zwar Gras
## und Kronen, aber nichts bewegt sich DURCH das Bild. Staub in den
## Lichtschächten, Laub, das in Böen über den Weg gerissen wird, und Vögel
## weit über der Schlucht geben der Kulisse einen Puls. Alles läuft im
## Vertex-Shader auf MultiMesh-Knoten – je Bild kostet es zwei Zuweisungen.
func _bewegung_setzen() -> void:
	var fall := _lichtrichtung()
	var seite := 1.0
	for stelle: float in [18.0, 58.0, 96.0, 132.0, 178.0, 214.0]:
		var staub := STAUB.instantiate() as Staubflug
		staub.raum = Vector3(7.0, 12.0, 7.0)
		staub.anzahl = 70
		staub.saat = int(stelle)
		staub.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, -1.0)
		deko.add_child(staub)

		# Der Staub hieß von Anfang an "Lichtschacht" – nur gab es den
		# Schacht nicht, und die Flusen trieben im Schatten. Jetzt fällt in
		# der Schlucht an jeder Säule ein Bündel Strahlen schräg über die
		# Kante, in der Richtung der Sonne, damit Strahl und Schatten
		# zusammenpassen. Sichtbar nur unterhalb der Wandkrone (`decke`).
		#
		# Nicht über den Kronen und der Lichtung: Dort ist kein Dach, durch
		# das Licht fallen könnte, und die Strahlen standen als Such-
		# scheinwerfer vor dem Himmel – Konkurrenz für das Zielportal.
		#
		# Das Bündel steht seitlich an der Wand, abwechselnd links und
		# rechts: In der Wegmitte fuhr die Kamera mitten hindurch, und jede
		# Bahn kostet Füllrate, auch dort, wo sie ausgeblendet ist.
		if stelle >= M_KRONEN:
			continue
		var wand := _wand_bei(stelle)
		seite = -seite
		var schacht := Lichtschacht.new()
		schacht.richtung = fall
		schacht.laenge = 22.0
		schacht.breite = 2.2
		schacht.anzahl = 4
		schacht.streuung = 1.2
		schacht.staerke = 0.1
		schacht.saat = int(stelle) + 7
		schacht.position = LevelWerkzeuge.punkt(verlauf, stelle, seite * 2.6, -0.5)
		schacht.decke = LevelWerkzeuge.punkt(verlauf, stelle).y + float(wand["hoehe"])
		deko.add_child(schacht)

	for stelle: float in [30.0, 84.0, 140.0, 196.0]:
		var laub := LAUBTREIBEN.instantiate() as Laubtreiben
		laub.flaeche = Vector2(_breite_bei(stelle) + 6.0, 12.0)
		laub.anzahl = 34
		laub.saat = int(stelle)
		laub.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, 0.2)
		# Erst drehen, dann einhängen – die Windrichtung wird beim Aufbau
		# gelesen. Nach der Drehung zeigt -Z den Korridor entlang.
		laub.rotation.y = LevelWerkzeuge.drehung(verlauf, stelle)
		deko.add_child(laub)

	# Vögel über den langen Blicken. Früher kreisten sie 55 m hoch – die
	# Verfolgerkamera schaut knapp 20 Grad nach unten, der obere Bildrand
	# liegt kaum über dem Horizont: So hoch kamen sie erst jenseits der
	# Sichtweite ins Bild, also nie. Zehn bis sechzehn Meter über der
	# Kamera sieht man sie ab rund vierzig Metern Entfernung.
	for eintrag: Array in [[58.0, 18.0, 22.0], [125.0, 20.0, 26.0],
			[185.0, 16.0, 20.0], [228.0, 17.0, 18.0]]:
		var stelle: float = eintrag[0]
		var schwarm := VOEGEL.instantiate() as Vogelschwarm
		schwarm.anzahl = 5 + int(stelle) % 3
		schwarm.hoehe = eintrag[1]
		schwarm.hoehen_streuung = 3.0
		schwarm.radius = eintrag[2]
		schwarm.spannweite = 1.4
		schwarm.linksherum = int(stelle) % 2 == 0
		schwarm.saat = int(stelle)
		schwarm.position = LevelWerkzeuge.punkt(verlauf, stelle, 0.0, 0.0)
		deko.add_child(schwarm)


## Richtung, in die das Sonnenlicht fällt. Aus der Sonne der Szene gelesen
## statt fest eingetragen – wer das Licht umstellt, dreht die Strahlen mit.
func _lichtrichtung() -> Vector3:
	var sonne := _sonne()
	if sonne == null:
		return Vector3(-0.36, -0.89, -0.27)
	return -sonne.global_transform.basis.z.normalized()


## Die schattenwerfende Sonne der Szene, oder null.
func _sonne() -> DirectionalLight3D:
	var sonne := get_node_or_null("Sonne") as DirectionalLight3D
	if sonne != null:
		return sonne
	for kind in get_children():
		if kind is DirectionalLight3D and (kind as DirectionalLight3D).shadow_enabled:
			return kind as DirectionalLight3D
	return null


## Im Web zwei Schattenstufen statt vier. Jede Stufe zeichnet alles, was
## Schatten wirft, noch einmal – gemessen ist das gut ein Drittel aller
## Zeichenaufrufe des Levels. Nur wenn die Szene noch vier Stufen trägt:
## Wer das Licht der Szene selbst umstellt, hat hier das letzte Wort.
func _nach_aufbau() -> void:
	if not OS.has_feature("web"):
		return
	var sonne := _sonne()
	if sonne == null \
			or sonne.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		return
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sonne.directional_shadow_max_distance = minf(sonne.directional_shadow_max_distance, 60.0)
	sonne.directional_shadow_split_1 = 0.2


## Breite des Weges an dieser Stelle. 0.0 bedeutet: hier ist eine Lücke.
func _breite_bei(strecke: float) -> float:
	for a in ABSCHNITTE:
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			var t := inverse_lerp(von, bis, strecke)
			return lerpf(a["breite"], a.get("breite_ende", a["breite"]), t)
	return 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func _rand_bei(strecke: float, sicherheit: float = 1.3) -> float:
	return maxf(_breite_bei(strecke) * 0.5 - sicherheit, 0.0)


## Schiebt eine Strecke vom Rand eines Abschnitts weg, damit Objekte
## nicht auf der Abbruchkante stehen.
func _weg_von_der_kante(strecke: float, abstand: float) -> float:
	for a in ABSCHNITTE:
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			if bis - von <= abstand * 2.0:
				return (von + bis) * 0.5
			return clampf(strecke, von + abstand, bis - abstand)
	return strecke


## Einzelne Plattformen über den Lücken und als Kletterhilfen.
func _plattformen_bauen() -> void:
	var fels := Materialbibliothek.fels()
	var gras := Materialbibliothek.gras()

	# Trittstein in der ersten Lücke (Waldrand)
	_stein_plattform(28.0, 0.0, -0.4, Vector3(3.0, 0.8, 3.0), fels)

	# Schlucht: zwei versetzte Felsplateaus in den Lücken
	_stein_plattform(59.0, -1.5, 0.4, Vector3(3.2, 0.8, 3.2), fels)
	_stein_plattform(77.0, 1.8, 0.8, Vector3(3.0, 0.8, 3.0), fels)

	# Stachelpassage: erhöhter Umweg über zwei Grasplateaus
	_stein_plattform(112.0, -3.6, 1.8, Vector3(4.0, 0.7, 5.0), gras)
	_stein_plattform(120.0, -3.6, 3.0, Vector3(4.0, 0.7, 4.0), gras)
	_stein_plattform(130.0, 0.0, 0.6, Vector3(4.5, 0.8, 3.0), fels)

	# Baumkronen: Stufen im Anstieg und Trittsteine in den Lücken
	_stein_plattform(175.0, 0.0, 1.2, Vector3(3.0, 0.8, 3.0), fels)
	_stein_plattform(193.0, -1.2, 2.0, Vector3(2.8, 0.8, 2.8), fels)
	_stein_plattform(199.0, 1.4, 3.2, Vector3(2.8, 0.8, 2.8), fels)


## Plattform relativ zum Verlauf setzen, mit dem Weg mitgedreht.
func _stein_plattform(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, material: Material) -> StaticBody3D:
	var pos := LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	return LevelWerkzeuge.plattform(geometrie, pos, groesse, material,
			LevelWerkzeuge.drehung(verlauf, strecke))


# =========================================================== Portale

func _portale_setzen() -> void:
	var start := STARTPORTAL.instantiate()
	start.position = LevelWerkzeuge.punkt(verlauf, 1.0, 0.0, 0.1)
	start.rotation.y = LevelWerkzeuge.drehung(verlauf, 1.0)
	objekte.add_child(start)

	var ziel := ZIELPORTAL.instantiate()
	ziel.position = LevelWerkzeuge.punkt(verlauf, M_ENDE - 4.0, 0.0, 0.1)
	ziel.rotation.y = LevelWerkzeuge.drehung(verlauf, M_ENDE - 4.0)
	objekte.add_child(ziel)


# =========================================================== Gefahren

func _gefahren_setzen() -> void:
	# --- Bach am Grund der Schlucht. Reine Kulisse: der Spieler wird
	# schon von der Absturzzone weit darüber abgefangen. ---
	_wasser(50.0, Vector2(26.0, 40.0), WASSER_HOEHE).toedlich = false
	_wasser(86.0, Vector2(26.0, 40.0), WASSER_HOEHE).toedlich = false
	# --- Absturzzone: wer vom Pfad fällt, überlebt es nicht ---
	_absturzzonen()
	# --- Lücken sichtbar markieren ---
	_luecken_markieren()

	# --- Stachelfelder in der Stachelpassage ---
	_stacheln(106.0, 0.0, Vector2(4.0, 3.0), false)
	_stacheln(118.0, 1.0, Vector2(5.0, 3.0), true)
	_stacheln(142.0, -1.0, Vector2(4.5, 3.5), false)
	_stacheln(150.0, 2.0, Vector2(3.0, 3.0), true)

	# --- Stacheln auf dem schmalen Grat der Baumkronen ---
	_stacheln(184.0, -1.6, Vector2(2.5, 4.0), false)


func _wasser(strecke: float, flaeche: Vector2, hoehe: float,
		seitlich: float = 0.0) -> Wasser:
	var w := WASSER.instantiate() as Wasser
	w.flaeche = flaeche
	w.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	# Der Bach spiegelt den Horizont des Himmels statt eines Weißschleiers
	# und glitzert in der Sonne; Level 01 hat Glow, dort blühen die Punkte.
	w.himmel_farbe = Color(0.70, 0.80, 0.84)
	w.glitzer = 1.0
	return w


func _stacheln(strecke: float, seitlich: float, flaeche: Vector2,
		einfahrbar: bool) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = einfahrbar
	st.versatz = fmod(strecke, 2.0)
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	st.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(st)
	return st


# =========================================================== Kisten

func _kisten_setzen() -> void:
	# ---------- Waldrand: die Grundlagen ----------
	_kiste(Kiste.Art.NORMAL, 10.0, -1.2)
	_kiste(Kiste.Art.NORMAL, 10.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 10.0, 1.2)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 14.0, 0.0)
	# Stapel: obere Kiste nur durch Draufspringen oder Spin erreichbar
	_kiste(Kiste.Art.NORMAL, 22.0, -1.0)
	_kiste(Kiste.Art.NORMAL, 22.0, -1.0, 1.5)
	_kiste(Kiste.Art.NORMAL, 22.0, 1.0)
	_kiste(Kiste.Art.SCHUTZ, 22.0, -2.2)
	_kiste(Kiste.Art.CHECKPOINT, 34.0, 0.0)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 38.5, -1.8)

	# ---------- Schlucht: Federkiste und Eisenplattformen ----------
	_kiste(Kiste.Art.FEDER, 50.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 53.5, 1.6)
	# Eisenkisten als Trittstufen über die zweite Lücke
	_kiste(Kiste.Art.EISEN, 64.5, -1.0)
	_kiste(Kiste.Art.EISEN, 66.5, -1.0, 1.5, true)
	_kiste(Kiste.Art.NORMAL, 66.5, -1.0, 2.5)
	_kiste(Kiste.Art.NORMAL, 70.0, 1.4)
	# TNT-Kette: die TNT reißt die Nachbarn mit
	_kiste(Kiste.Art.NORMAL, 84.0, -1.1)
	_kiste(Kiste.Art.TNT, 84.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 84.0, 1.1)
	_kiste(Kiste.Art.NORMAL, 85.2, 0.0)
	_kiste(Kiste.Art.CHECKPOINT, 96.0, 0.0)

	# ---------- Stachelpassage: Nitro als Fallstrick ----------
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 112.0, -3.6, 1.8 + 0.85)
	_kiste(Kiste.Art.NORMAL, 120.0, -3.6, 3.0 + 0.85)
	_kiste(Kiste.Art.NITRO, 134.0, -1.4)
	_kiste(Kiste.Art.NORMAL, 134.0, 0.2)
	_kiste(Kiste.Art.NORMAL, 135.4, 0.2)
	_kiste(Kiste.Art.NORMAL, 136.8, 0.2)
	_kiste(Kiste.Art.FEDER, 148.0, 1.8)
	_kiste(Kiste.Art.SCHUTZ, 150.0, 2.2)
	_kiste(Kiste.Art.CHECKPOINT, 154.0, 0.0)

	# ---------- Baumkronen: Sprungfedern und Nitro auf dem Grat ----------
	_kiste(Kiste.Art.SPRUNG, 162.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 162.0, 0.0, 4.0, true)
	_kiste(Kiste.Art.NORMAL, 163.4, 0.0, 4.0, true)
	_kiste(Kiste.Art.NITRO, 186.0, 1.4)
	_kiste(Kiste.Art.NITRO, 187.4, 1.4)
	_kiste(Kiste.Art.NORMAL, 186.7, -1.2)
	_kiste(Kiste.Art.FEDER, 194.0, -1.2, 2.0 + 0.5)
	_kiste(Kiste.Art.TNT, 204.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 204.0, -1.2)
	_kiste(Kiste.Art.NORMAL, 204.0, 1.2)

	# ---------- Lichtung: Belohnung ----------
	_kiste(Kiste.Art.LEBEN, 214.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 219.0, -2.0)
	_kiste(Kiste.Art.NORMAL, 219.0, 0.0)
	_kiste(Kiste.Art.NORMAL, 219.0, 2.0)
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, 224.0, 0.0)


## `schwebt = true` heißt: Diese Kiste steht ABSICHTLICH in der Luft und
## ist selbst der Boden – eine Trittstufe über der Lücke, eine Belohnung
## über der Sprungfeder. Dieselbe Abmachung wie in `KorridorLevel.kiste()`;
## ohne sie meldet das Prüfwerkzeug jede solche Kiste als Versehen, und in
## neun von zehn Fällen hat es damit recht.
func _kiste(art: Kiste.Art, strecke: float, seitlich: float,
		hoehe: float = 0.5, schwebt := false) -> Kiste:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	if schwebt:
		k.add_to_group("schwebende_kisten")
	k.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	k.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(k)
	return k


# =========================================================== Gegner

func _gegner_setzen() -> void:
	# ---------- Waldrand: Drehschlag lernen ----------
	_gegner(SUMPFKROETE, 18.0, 0.0, 3.5, true)
	_gegner(SUMPFKROETE, 39.0, 1.5, 3.0, true)

	# ---------- Schlucht: Draufspringen lernen ----------
	_gegner(PANZERKAEFER, 52.0, 0.0, 2.5, true)
	_gegner(PANZERKAEFER, 70.5, -1.0, 3.0, true)
	_gegner(SUMPFKROETE, 88.0, 0.0, 3.0, true)

	# ---------- Stachelpassage: Slide lernen ----------
	_gegner(STELZENSPINNE, 110.0, -1.0, 3.0, true)
	_gegner(STELZENSPINNE, 123.0, 0.5, 3.5, true)
	_gegner(PANZERKAEFER, 138.0, -2.0, 2.5, true)
	_gegner(STELZENSPINNE, 146.0, 0.0, 3.0, true)

	# ---------- Baumkronen: alles gemischt ----------
	_gegner(SUMPFKROETE, 166.0, 0.0, 2.5, true)
	_gegner(PANZERKAEFER, 182.0, 1.2, 2.0, false)
	_gegner(STELZENSPINNE, 200.0, 0.0, 2.5, true)

	# ---------- Lichtung: letzte Wache ----------
	_gegner(PANZERKAEFER, 216.0, 3.5, 3.0, true)
	_gegner(SUMPFKROETE, 222.0, -3.5, 3.0, true)


## Setzt einen Gegner auf den Weg. `quer` bestimmt, ob er quer zum
## Korridor patrouilliert (true) oder ihm entlang (false).
func _gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool) -> Gegner:
	var g := szene.instantiate() as Gegner
	# Nicht direkt an die Abbruchkante stellen
	strecke = _weg_von_der_kante(strecke, 2.5)
	# Der Gegner darf beim Patrouillieren nicht vom Weg laufen: seitlicher
	# Versatz und Weite werden auf die Wegbreite an dieser Stelle begrenzt.
	var rand := _rand_bei(strecke)
	if quer:
		seitlich = clampf(seitlich, -rand * 0.5, rand * 0.5)
		weite = minf(weite, maxf(rand - absf(seitlich), 0.5))
	else:
		seitlich = clampf(seitlich, -rand, rand)
		# Entlang des Weges: Weite so kürzen, dass beide Enden auf dem Weg liegen
		var frei := 99.0
		for a in ABSCHNITTE:
			if strecke >= a["von"] and strecke <= a["bis"]:
				frei = minf(strecke - a["von"], a["bis"] - strecke) - 1.0
		weite = minf(weite, maxf(frei, 0.5))
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized() if quer else richtung
	# Position VOR add_child setzen: die Gegner merken sich in _ready()
	# ihre Startposition für die Patrouille.
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.05)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	# Führungslinien aus Früchten weisen den Weg und markieren Sprünge
	_fruechte_reihe(6.0, 9.0, 4, 0.0, 0.9)
	_fruechte_reihe(16.0, 20.0, 5, -1.4, 0.9)
	_fruechte_reihe(26.5, 29.5, 4, 0.0, 2.2)      # Bogen über die erste Lücke
	_fruechte_reihe(30.5, 33.5, 4, 0.0, 2.2)
	_fruechte_reihe(44.0, 48.0, 5, 1.2, 0.9)
	_fruechte_reihe(56.5, 61.5, 5, -1.5, 2.6)     # über den Bach
	_fruechte_reihe(74.5, 79.5, 5, 1.8, 2.6)
	_fruechte_reihe(90.0, 95.0, 5, 0.0, 0.9)
	_fruechte_reihe(102.0, 105.0, 4, -2.5, 0.9)
	_fruechte_reihe(113.0, 119.0, 6, -3.6, 3.0)   # auf dem Umweg über die Plateaus
	_fruechte_reihe(126.0, 130.0, 5, 2.2, 0.9)
	_fruechte_reihe(144.0, 148.0, 5, -1.8, 0.9)
	_fruechte_reihe(160.0, 164.0, 4, -1.8, 0.9)
	_fruechte_reihe(172.5, 177.5, 5, 0.0, 2.8)    # über die Grat-Lücke
	_fruechte_reihe(190.5, 195.5, 5, 0.0, 3.4)
	_fruechte_reihe(209.0, 213.0, 5, 0.0, 0.9)
	_fruechte_reihe(226.0, 230.0, 6, 0.0, 0.9)


func _fruechte_reihe(von: float, bis: float, anzahl: int,
		seitlich: float, hoehe: float) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		var s := lerpf(von, bis, t)
		var f := FRUCHT.instantiate()
		f.position = LevelWerkzeuge.punkt(verlauf, s, seitlich, hoehe)
		objekte.add_child(f)


# =========================================================== Waldboden

## Der Pfad verläuft auf einem Grat. Weit darunter liegt der Waldboden –
## sichtbar, aber nicht begehbar; wer hinunterfällt, stirbt vorher in der
## Absturzzone. Darauf wächst das Blättermeer unter den Baumkronen und das
## Tal am Ende.
func _waldboden_bauen() -> void:
	# Bis ans Ende der Kurve, nicht nur bis zum Ziel: Hinter dem Zielportal
	# schaute man sonst über die Bodenkante ins Leere.
	LevelWerkzeuge.korridor(geometrie, verlauf, [
		{"von": 0.0, "bis": verlauf.get_baked_length(), "breite": 110.0},
	], {
		"oben": Materialbibliothek.waldboden(),
		"kante": Materialbibliothek.waldboden(),
		"klippe": Materialbibliothek.fels(),
	}, {
		"tiefe": 22.0,
		"schritt": 4.0,
		"kollision": false,
		"kante_hoehe": 0.0,
		"kante_breite": 0.0,
		"hoehe_versatz": WALDBODEN_HOEHE,   # tief unter dem Weg
	})


## Reihe unsichtbarer Bereiche unter dem Pfad, die den Sturz beenden.
func _absturzzonen() -> void:
	var schritt := 18.0
	var s := 0.0
	while s < M_ENDE:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(70.0, 5.0, schritt + 4.0)
		form.shape = box
		zone.add_child(form)
		zone.position = LevelWerkzeuge.punkt(verlauf, s + schritt * 0.5,
				0.0, ABSTURZ_HOEHE - 2.5)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s + schritt * 0.5)
		zone.body_entered.connect(_auf_absturz)
		geometrie.add_child(zone)
		s += schritt


func _auf_absturz(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("sterben"):
		koerper.call("sterben")


# =========================================================== Wald

## Der Wald unter dem Grat der Baumkronen.
##
## Früher standen neun Waldbestände und vierundzwanzig Rahmenbäume auf dem
## Waldboden entlang der ganzen Strecke, rund hundertfünfzig Bäume. Gesehen
## hat man nur die in den Baumkronen: Überall sonst stehen die Schluchtwände
## dicht am Weg und reichen bis unter den Waldboden, was dahinter wächst,
## verdeckt der Fels vollständig. Gezeichnet wurde es trotzdem, samt vier
## Schattenstufen – ein gutes Drittel aller Zeichenaufrufe des Levels ging an
## Bäume, die niemand sieht.
##
## Jetzt wächst Wald nur dort, wo man hineinschaut, neben dem Grat, in zwei
## Ringen:
##   nah   Kronen knapp UNTER dem Grat, ein Blättermeer, über das der Weg
##         führt. Die Wipfel bleiben deutlich unter der Wegkante, an den
##         Lücken noch tiefer – was auf Weghöhe grünt, sieht begehbar aus.
##   fern  Riesen, deren Stämme aus dem Blättermeer steigen und deren Kronen
##         neben dem Weg das Bild rahmen, weit genug draußen für die Kamera.
## Das Blättermeer ist ein einziges Netz (`Schluchtsaum.blaetterdach`), die
## Riesen bauen sich selbst (`eigenbau`): Die Kenney-Bäume, auf zwölf Meter
## aufgeblasen, standen hier als große flache Platten im Bild.
func _kronenwald() -> void:
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 15803
	var toene := [Farben.LAUB, Farben.LAUB_DUNKEL, Farben.LAUB_HELL,
			Farben.LAUB_DUNKEL, Farben.LAUB_GELB, Farben.LAUB]
	var nummer := 0

	# --- nah: das Blättermeer ---
	# Ein einziges Netz statt eines `Baum` je Wipfel: Von oben sieht man
	# ohnehin nur Kronen, und fünfzig Bäume kosteten hundert Zeichenaufrufe.
	var dach: Array = []
	var s := M_KRONEN + 1.0
	while s < M_LICHTUNG - 1.0:
		for seite: float in [-1.0, 1.0]:
			var strecke := s + wuerfel.randf_range(-1.2, 1.2)
			var rand := maxf(_breite_bei(strecke) * 0.5, 3.0)
			# An den Lücken deutlich tiefer, unter der Absturzzone: Wer dort
			# hinabschaut, soll den Absturz sehen und nicht ein Polster, auf
			# dem er landen könnte. Auch neben dem Grat liegen die Wipfel ein
			# gutes Stück unter der Kante – knapp darunter standen sie aus
			# der Kamera wie Büsche am Wegrand.
			var tiefer := 0.0 if _breite_bei(strecke) > 0.0 \
					and _breite_bei(strecke - 2.5) > 0.0 \
					and _breite_bei(strecke + 2.5) > 0.0 else 6.0
			dach.append({
				"fuss": LevelWerkzeuge.punkt(verlauf, strecke,
						seite * (rand + wuerfel.randf_range(1.6, 4.8)), WALDBODEN_HOEHE),
				"hoehe": -WALDBODEN_HOEHE - wuerfel.randf_range(3.2, 5.0) - tiefer,
				"breite": wuerfel.randf_range(2.6, 3.8),
			})
			# Ein zweiter, tieferer Ring bis an die Wand: Ohne ihn sah man
			# zwischen Wipfeln und Fels auf den kahlen Waldboden hinab.
			var aussen := s + wuerfel.randf_range(-1.8, 1.8)
			dach.append({
				"fuss": LevelWerkzeuge.punkt(verlauf, aussen,
						seite * wuerfel.randf_range(9.0, 11.5), WALDBODEN_HOEHE),
				"hoehe": -WALDBODEN_HOEHE - wuerfel.randf_range(5.0, 7.0),
				"breite": wuerfel.randf_range(3.0, 4.2),
			})
		s += wuerfel.randf_range(3.2, 4.4)
	Schluchtsaum.blaetterdach(deko, dach, 15804)

	# --- fern: Riesen neben dem Grat ---
	# Zwischen Blättermeer und Wand, locker gestellt und nur wenig über die
	# Wegkante ragend: Sie sollen den ersten offenen Blick des Levels rahmen,
	# nicht verstellen. Standen sie dichter und höher, füllten gestapelte
	# Kronen das linke und rechte Bilddrittel. Weiter hinaus geht es nicht –
	# ab 12,5 m steht die Kronenwand, und dahinter wären sie verschwunden.
	s = M_KRONEN + 4.0
	var seite_fern := 1.0
	while s < M_LICHTUNG - 2.0:
		# Nicht neben eine Lücke: Dort soll der Blick hinab frei sein, und
		# eine Krone auf Weghöhe gleich daneben sah aus wie ein Busch, auf
		# dem man landen könnte.
		if _breite_bei(s) <= 0.0 or _breite_bei(s - 3.0) <= 0.0 \
				or _breite_bei(s + 3.0) <= 0.0:
			s += 2.0
			continue
		var b := BAUM.instantiate() as Baum
		b.eigenbau = true
		b.kollision = false
		b.kronenform = Baum.Kronenform.HOCH
		b.kronenfuelle = 1.5
		b.hoechsthoehe = 22.0
		b.hoehe = -WALDBODEN_HOEHE + wuerfel.randf_range(0.0, 3.0)
		b.staerke = wuerfel.randf_range(1.2, 1.6)
		b.laubfarbe = toene[nummer % toene.size()]
		b.saat = 5900 + nummer
		b.position = LevelWerkzeuge.punkt(verlauf, s,
				seite_fern * wuerfel.randf_range(9.5, 11.0), WALDBODEN_HOEHE)
		b.rotation.y = wuerfel.randf() * TAU
		deko.add_child(b)
		nummer += 1
		seite_fern = -seite_fern
		s += wuerfel.randf_range(8.0, 11.0)

	# Ein abgestorbener Riese, der aus dem Blättermeer ragt: kahles Holz als
	# Silhouette zwischen all dem Grün.
	var tot := BAUM.instantiate() as Baum
	tot.art = Baum.Art.TOTHOLZ
	tot.kollision = false
	tot.hoehe = 14.0
	tot.staerke = 1.4
	tot.saat = 196
	tot.position = LevelWerkzeuge.punkt(verlauf, 199.0, -7.5, WALDBODEN_HOEHE)
	deko.add_child(tot)


## Das Ende des Weges: Hinter dem Zielportal bricht der Grat ab, und der
## Blick geht über ein Tal voller Baumkronen bis zu bewaldeten Hügeln.
##
## Vorher endeten Weg, Waldboden und Wände kurz hinter dem Portal, die
## Kurve lief aber noch zwanzig Meter weiter – das letzte Bild des Levels
## schaute ins Leere. Jetzt steht dort, wo der Grat abbricht, ein
## Weltenbaum aus dem Tal herauf; seine Krone schließt das Bild nach oben,
## ein Wurzelbogen rahmt das Portal, und unten wächst Wald.
func _ausblick() -> void:
	# Der Weltenbaum. Sein Stamm steigt hinter dem Ende des Grats aus dem
	# Tal, links neben dem Portal, und die Krone sitzt so hoch, dass die
	# Kamera sie nur am oberen Bildrand anschneidet: Man sieht eine Säule
	# von Stamm, und das Übrige denkt sich jeder selbst größer, als man es
	# bauen könnte. Vorher stand er genau auf der Achse und niedriger – die
	# Krone deckte als dunkler Schirm das Tal zu, das der Wurzelbogen rahmen
	# soll.
	var riese := BAUM.instantiate() as Baum
	riese.eigenbau = true
	riese.kollision = false
	riese.hoechsthoehe = 40.0
	riese.hoehe = 40.0
	riese.staerke = 3.5
	riese.kronenfuelle = 1.8
	riese.kronenform = Baum.Kronenform.SCHIRM
	riese.laubfarbe = Farben.LAUB
	riese.saat = 2501
	riese.position = LevelWerkzeuge.punkt(verlauf, 257.0, -6.5, WALDBODEN_HOEHE)
	riese.rotation.y = 0.6
	deko.add_child(riese)
	# Sein Schatten fiele ins Tal, vom Weg weg – gezeichnet würde er
	# trotzdem, in vier Schattenstufen.
	_ohne_schatten(riese)

	# Wurzelbogen über dem Ende des Weges, hinter dem Portal: Er rahmt es
	# aus der Verfolgerkamera wie ein Tor. Ohne Kollision – er steht auf der
	# Wegkante, und der Weg endet ohnehin an ihm.
	var bogen := WURZEL.instantiate() as Wurzel
	bogen.kollision = false
	# Ohne Nebenwurzeln: Bei knapp sieben Metern Bogenhöhe liefen sie als
	# lange dünne Stäbe vom Scheitel zum Boden und kreuzten sich genau
	# hinter dem Portal.
	bogen.nebenwurzeln = false
	bogen.spannweite = 13.6
	bogen.hoehe = 6.8
	bogen.dicke = 1.05
	bogen.segmente = 12
	bogen.saat = 2350
	bogen.position = LevelWerkzeuge.punkt(verlauf, M_ENDE - 1.2, 0.0, 0.0)
	bogen.rotation.y = LevelWerkzeuge.drehung(verlauf, M_ENDE - 1.2)
	deko.add_child(bogen)
	# Dasselbe helle Wurzelholz wie an den Wänden – im Gegenlicht las sich
	# das dunkle als schwarzer Strich.
	for kind in bogen.get_children():
		if kind is MeshInstance3D:
			(kind as MeshInstance3D).material_override = Schluchtsaum.wurzelholz()

	# Das Tal unter dem Grat: Baumkronen, deren Wipfel deutlich unter der
	# Wegkante bleiben – ein Blätterdach, ein Netz.
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 23701
	var tal: Array = []
	for i in 22:
		var strecke := wuerfel.randf_range(M_ENDE + 1.0, 258.0)
		var quer := wuerfel.randf_range(1.5, 16.0) * (1.0 if i % 2 == 0 else -1.0)
		tal.append({
			"fuss": LevelWerkzeuge.punkt(verlauf, strecke, quer, WALDBODEN_HOEHE),
			"hoehe": -WALDBODEN_HOEHE - wuerfel.randf_range(3.0, 6.5),
			"breite": wuerfel.randf_range(2.8, 4.2),
		})
	Schluchtsaum.blaetterdach(deko, tal, 23702)

	# Bewaldete Hügel rings um das Level. Zu sehen sind sie nur, wo die
	# Wände den Blick freigeben: über den Kronen und hier am Ende. Der
	# Mittelpunkt liegt mitten im Level, der Radius weit genug draußen,
	# dass der Ring nirgends näher als gut siebzig Meter kommt; die ferne
	# zweite Kette stünde jenseits der Sichtweite und entfällt. Die
	# Bodenscheibe liegt unter dem tiefsten Waldboden, damit sie nirgends
	# durch die Schlucht schneidet.
	var hz := HORIZONT.instantiate() as Horizont
	hz.radius = 170.0
	hz.hoehe = 27.0
	hz.zacken = 110
	hz.kronen = true
	hz.nur_nah = true
	hz.fuss = -16.0
	# Ferne ist heller und blauer: Die Hügel liegen im Dunst zwischen dem
	# Waldgrün und der Farbe des Horizonts.
	hz.farbe_nah = Color(0.32, 0.42, 0.37)
	hz.boden_farbe = Color(0.24, 0.32, 0.25)
	hz.position = Vector3(37.0, 0.0, -87.0)
	deko.add_child(hz)


## Jeder Abschnitt ein eigenes Licht: Über dem Bach der Schlucht wird es
## kühl und dunstig, auf dem Grat der Baumkronen hell und golden, auf der
## Lichtung warm. Vorher stand das ganze Level im selben grünen Dunst, und
## die Abschnitte unterschieden sich nur durch die Wegbreite.
##
## Die Zonen rechnen RELATIV zur Grundstimmung der Szene (Faktor auf Dichte
## und Umgebungslicht, halber Weg zur Zonenfarbe; im Tiefennebel verkürzt
## oder verlängert der Faktor die Nebelstrecke, siehe `Stimmungszone`): So
## bleibt der Unterschied bestehen, auch wenn das Grundlicht des Levels neu
## gestimmt wird. Die Nahzone bleibt davon unberührt – Nebel liegt hinter
## dem Spiel.
func _stimmungen() -> void:
	_stimmung(M_SCHLUCHT + 6.0, M_STACHELN, Color(0.30, 0.42, 0.40), 1.3,
			0.9, Color(0.44, 0.56, 0.62))
	_stimmung(M_KRONEN + 2.0, M_LICHTUNG, Color(0.62, 0.60, 0.44), 0.7,
			1.2, Color(0.64, 0.62, 0.50))
	_stimmung(M_LICHTUNG, M_ENDE + 8.0, Color(0.66, 0.56, 0.38), 0.75,
			1.25, Color(0.70, 0.60, 0.46))


## Stimmungszonen in Stücken entlang des Weges – ein einzelner Kasten
## folgte der Kurve nicht. Wie `KorridorLevel.stimmung()`, das diesem
## Level nicht zur Verfügung steht.
func _stimmung(von: float, bis: float, nebelfarbe: Color, nebel: float,
		licht: float, umgebung: Color) -> void:
	var schritt := 14.0
	var s := von
	while s < bis:
		var laenge := minf(schritt, bis - s)
		var z := STIMMUNGSZONE.instantiate() as Stimmungszone
		z.nebelfarbe = nebelfarbe
		z.nebel_faktor = nebel
		z.licht_faktor = licht
		z.umgebungsfarbe = umgebung
		z.farbanteil = 0.5
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(40.0, 24.0, laenge)
		form.shape = box
		z.add_child(form)
		z.position = LevelWerkzeuge.punkt(verlauf, s + laenge * 0.5, 0.0, 6.0)
		z.rotation.y = LevelWerkzeuge.drehung(verlauf, s + laenge * 0.5)
		geometrie.add_child(z)
		s += laenge


## Schaltet den Schattenwurf eines ganzen Unterbaums ab.
func _ohne_schatten(knoten: Node) -> void:
	var geo := knoten as GeometryInstance3D
	if geo != null:
		geo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for kind in knoten.get_children():
		_ohne_schatten(kind)


## Blattwerk auf der Schluchtkante.
##
## In den Vorlagen ist der Weg von großen Blattformen gesäumt, und die
## Bildränder laufen dunkel aus – das rahmt den Weg wie einen Tunnel. Unser
## Rand war dagegen leer: erst Weg, dann Wand, dann Himmel. Diese Büschel
## sitzen oben auf der Wand, hängen also über die Kante ins Bild und
## schließen es nach oben.
##
## Sie stehen weit außerhalb des Wegs und tragen keine Kollision – sie sind
## Rahmen, kein Hindernis.
func _rankenwerk() -> void:
	var wuerfel := randi()
	seed(10145)
	# Vier Grüntöne plus zwei Farbtupfer: in den Vorlagen sitzt zwischen dem
	# Grün immer ein Magenta- oder Gelbfleck, sonst wird die Wand eine
	# einzige grüne Masse.
	var toene := [Farben.LAUB_DUNKEL, Farben.LAUB, Farben.LAUB_DUNKEL,
			Farben.LAUB_HELL, Farben.BLUETE_MAGENTA, Farben.LAUB_GELB]
	for i in 58:
		var s := randf_range(-4.0, M_ENDE + 4.0)
		var wand := _wand_bei(s)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var b := BAUM.instantiate() as Baum
		b.art = Baum.Art.LAUBBAUM
		b.kronenform = Baum.Kronenform.BREIT
		b.hoehe = randf_range(3.2, 5.0)
		b.staerke = randf_range(0.5, 0.9)
		b.saat = 4400 + i
		b.laubfarbe = toene[i % toene.size()]
		b.kollision = false
		b.wind = false
		# Die Bäume stehen HINTER der Kante auf der Wandkrone, mit dem Fuß
		# knapp darunter – so wachsen sie sichtbar aus dem Rand heraus.
		#
		# Vorher saßen sie auf der Wandfläche selbst und wurden um die halbe
		# Baumhöhe darunter versenkt, damit nur die Krone herausschaut. Das
		# ging auf, solange der Stamm lang und kahl war. Fremde Modelle
		# haben aber kurze Stämme und tief sitzende Kronen: Da hing der
		# Stamm unter der Kante frei in der Luft über der Schlucht.
		# Deutlich hinter der Kante und mit dem Fuß auf Kronenhöhe: Standen
		# sie dichter an der Wand, stachen die Kronen durch die Felswand ins
		# Bild – große flache Flecken mitten auf dem Gestein.
		b.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * (wand["abstand"] + randf_range(3.0, 7.5)),
				wand["hoehe"] + randf_range(0.0, 0.4))
		deko.add_child(b)
		# Die Kamera schwebt unter der Wandkrone und sieht nie auf sie
		# hinauf – der Schatten dieser Bäume fiele genau dorthin.
		_ohne_schatten(b)
	seed(wuerfel)


## Wandwerte an dieser Stelle. Innerhalb eines Abschnitts sind sie fest.
func _wand_bei(strecke: float) -> Dictionary:
	for w in WAENDE:
		if strecke >= w["von"] and strecke <= w["bis"]:
			return w
	return WAENDE[0]


## Niedrige Deko auf dem Weg selbst: Wurzeln, Findlinge, Gras, Kleinzeug.
## Alles bleibt unter Kniehöhe, damit die Sicht frei bleibt.
func _wegdeko() -> void:
	# Wurzelbögen quer über den Weg – Hindernisse zum Drüberspringen
	for stelle in [[20.0, 0.0, 4.5], [72.0, 0.0, 4.0], [144.0, -0.5, 4.5],
			[180.0, 0.0, 3.5], [212.0, 0.5, 5.0]]:
		var strecke: float = stelle[0]
		var w := WURZEL.instantiate() as Wurzel
		w.spannweite = stelle[2]
		w.hoehe = 1.0
		w.saat = int(strecke) * 3
		w.position = LevelWerkzeuge.punkt(verlauf, strecke, stelle[1], 0.0)
		w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke) + PI * 0.5
		deko.add_child(w)

	# Findlinge am Wegesrand, innerhalb der Kante
	for i in 16:
		var s := 12.0 + float(i) * 14.0
		if s > M_ENDE - 6.0:
			break
		var seite := 1.0 if i % 2 == 0 else -1.0
		var st := STEIN.instantiate() as Stein
		st.groesse = 0.55 + float(i % 3) * 0.3
		st.saat = 700 + i * 11
		st.bemoost = i % 3 == 0
		st.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.1), 0.5), -0.15)
		deko.add_child(st)

	# Grasnarben entlang des Weges, direkt an der Kante
	for i in 22:
		var s := 5.0 + float(i) * 10.5
		if s > M_ENDE - 4.0:
			break
		var seite := -1.0 if i % 2 == 0 else 1.0
		var g := GRASFELD.instantiate() as Grasfeld
		g.flaeche = Vector2(3.2, 5.0)
		g.anzahl = 150
		g.saat = 200 + i * 7
		g.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.6), 0.4), 0.0)
		g.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		deko.add_child(g)

	# Farne, Pilze, Büsche und Blumen
	var arten := [Kleinzeug.Art.FARN, Kleinzeug.Art.PILZ, Kleinzeug.Art.BUSCH,
			Kleinzeug.Art.BLUME]
	for i in 44:
		var s := 4.0 + float(i) * 5.2
		if s > M_ENDE - 3.0:
			break
		var seite := -1.0 if i % 2 == 0 else 1.0
		var k := KLEINZEUG.instantiate() as Kleinzeug
		k.art = arten[i % arten.size()]
		k.groesse = 0.45 + float(i % 4) * 0.18
		k.saat = 900 + i * 5
		# Farne immer selbst gebaut: Das Kenney-Paket hat keinen, und ohne
		# diesen Schalter stand im ganzen Wurzelwald kein einziger Farn.
		k.eigenbau = k.art == Kleinzeug.Art.FARN
		k.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * maxf(_rand_bei(s, 1.4) - float(i % 3) * 0.5, 0.3), 0.0)
		k.rotation.y = float(i) * 0.9
		deko.add_child(k)
		# Knöchelhoch: Ihr Schatten ist ein Fleck unter ihnen, kostet aber
		# je Schattenstufe einen Zeichenaufruf.
		_ohne_schatten(k)


# =========================================================== Lücken

## Markiert jede Abbruchkante: zwei Pfosten mit Querbalken und quer über
## den Weg eine Schwelle aus hellen Steinplatten, damit Löcher von weitem
## als Löcher erkennbar sind.
##
## Vorher lag dort ein leuchtend gelber Streifen, und die Pfosten trugen
## gelbe Kappen – aus der Verfolgerkamera das Grellste im ganzen Bild, eine
## Baustelle mitten im Wald. Die Aufgabe bleibt, die Mittel kommen jetzt
## aus dem Wald: Die Schwelle ist heller und grauer als der Weg und liegt
## als Linie quer zur Laufrichtung; auf den Pfosten wachsen leuchtende
## Pilze. Je Lücke drei Netze statt zwölf Knoten – je Lücke und nicht für
## das ganze Level, damit eine Lücke hinter der Kamera auch nicht mehr
## gezeichnet wird.
func _luecken_markieren() -> void:
	var wuerfel := PropWerkzeug.zufall(4242)
	var holzstoff := Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
	var plattenstoff := PropWerkzeug.mit_scheitelfarben(
			Materialbibliothek.einfarbig(Color(0.86, 0.84, 0.78)))
	var pilzstoff := _pilzleuchten()
	for i in ABSCHNITTE.size() - 1:
		var a: Dictionary = ABSCHNITTE[i]
		var naechster: Dictionary = ABSCHNITTE[i + 1]
		if naechster["von"] - a["bis"] <= 0.5:
			continue
		var holz := PropWerkzeug.bauer()
		var pilze := PropWerkzeug.bauer()
		var platten := PropWerkzeug.bauer()
		_kantenmarke(holz, pilze, platten, wuerfel, a["bis"] - 0.5,
				a.get("breite_ende", a["breite"]), 1.0)
		_kantenmarke(holz, pilze, platten, wuerfel, naechster["von"] + 0.5,
				naechster["breite"], -1.0)

		var knoten := PropWerkzeug.mesh_knoten("Kantenpfosten", PropWerkzeug.fertig(holz),
				holzstoff)
		if knoten != null:
			deko.add_child(knoten)
		# Die Schwelle liegt flach am Boden, ihr Schatten wäre nicht zu sehen.
		# Verschmolzen wie der Bewuchs (siehe `Schluchtsaum._blattnetz`).
		platten.index()
		knoten = PropWerkzeug.mesh_knoten("Kantenschwelle",
				PropWerkzeug.fertig_mit_tangenten(platten), plattenstoff, false)
		if knoten != null:
			deko.add_child(knoten)
		pilze.index()
		knoten = PropWerkzeug.mesh_knoten("Kantenpilze",
				PropWerkzeug.fertig_mit_tangenten(pilze), pilzstoff, false)
		if knoten != null:
			deko.add_child(knoten)


## Pfosten, Balken, Pilze und Schwelle einer Kante. `zur_luecke` zeigt
## entlang des Weges auf das Loch (+1 = voraus, -1 = zurück).
func _kantenmarke(holz: SurfaceTool, pilze: SurfaceTool, platten: SurfaceTool,
		wuerfel: RandomNumberGenerator, strecke: float, breite: float,
		zur_luecke: float) -> void:
	var halb := breite * 0.5 - 0.55
	var basis := Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, strecke))

	for seite: float in [-1.0, 1.0]:
		var fuss := LevelWerkzeuge.punkt(verlauf, strecke, seite * halb, 0.45)
		PropWerkzeug.anfuegen(holz, PropWerkzeug.stumpf(0.11, 0.09, 1.1, 8, true),
				Transform3D(basis, fuss + Vector3.UP * 0.55))
		# Ein Hut obenauf und zwei Konsolenpilze am Pfosten, zur Wegmitte
		# gedreht – sie leuchten dahin, wo man hinschaut.
		var kopf := fuss + Vector3.UP * 1.1
		PropWerkzeug.klumpen(pilze, wuerfel, kopf + Vector3.UP * 0.04,
				Vector3(0.2, 0.1, 0.2), Vector3(0.0, wuerfel.randf() * TAU, 0.0),
				8, 3, 0.12, false, Color(0.55, 0.5, 0.45), Color.WHITE,
				kopf.y - 0.05, kopf.y + 0.14)
		for k in 2:
			var h := 0.35 + float(k) * 0.3 + wuerfel.randf_range(-0.05, 0.05)
			var nach_innen := basis * Vector3(-seite, 0.0, wuerfel.randf_range(-0.6, 0.6))
			var mitte := fuss + Vector3.UP * h + nach_innen.normalized() * 0.1
			PropWerkzeug.klumpen(pilze, wuerfel, mitte,
					Vector3(0.1, 0.035, 0.1) * wuerfel.randf_range(0.8, 1.2),
					Vector3(0.0, wuerfel.randf() * TAU, 0.0), 7, 2, 0.15, false,
					Color(0.6, 0.55, 0.5), Color.WHITE, mitte.y - 0.04, mitte.y + 0.04)

	# Querbalken auf Kniehöhe – warnt, ohne die Sicht auf die Lücke zu nehmen
	PropWerkzeug.anfuegen(holz, PropWerkzeug.kasten(Vector3(halb * 2.0, 0.1, 0.08)),
			Transform3D(basis, LevelWerkzeuge.punkt(verlauf, strecke, 0.0, 0.62)))

	# Schwelle: eine Reihe flacher Platten über die ganze Wegbreite, knapp
	# vor der Kante. Helle, graue Steine auf braunem Weg – die Linie ist
	# aus der Verfolgerkamera so deutlich wie der Streifen, nur ohne Glühen.
	var anzahl := maxi(int(halb * 2.0 / 0.95), 4)
	for k in anzahl:
		var t := (float(k) + 0.5) / float(anzahl)
		var quer := lerpf(-halb - 0.2, halb + 0.2, t) + wuerfel.randf_range(-0.12, 0.12)
		var laengs := -zur_luecke * wuerfel.randf_range(0.05, 0.3)
		# Eingesunken und fast gleich groß, in einem warmen Kalkton: Kühl,
		# hoch und verschieden groß lasen sich die Platten aus der Nähe als
		# Trittsteine, die jemand auf den Weg gelegt hat.
		var ort := LevelWerkzeuge.punkt(verlauf, strecke + laengs, quer, 0.0)
		var r := Vector3(wuerfel.randf_range(0.45, 0.52), wuerfel.randf_range(0.045, 0.065),
				wuerfel.randf_range(0.32, 0.4))
		var hell := wuerfel.randf_range(0.86, 1.0)
		PropWerkzeug.klumpen(platten, wuerfel, ort, r,
				Vector3(wuerfel.randf_range(-0.05, 0.05),
						LevelWerkzeuge.drehung(verlauf, strecke) + wuerfel.randf_range(-0.5, 0.5),
						wuerfel.randf_range(-0.05, 0.05)),
				7, 3, 0.26, true, Color(0.76, 0.72, 0.64) * hell,
				Color(0.94, 0.9, 0.82) * hell, ort.y - r.y, ort.y + r.y)


## Leuchtstoff der Kantenpilze: warmes Weiß, deutlich schwächer und weniger
## gesättigt als das alte Warngelb. Eigenes Material – das der Bibliothek
## wird nie verändert.
func _pilzleuchten() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1.0, 0.86, 0.62)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.78, 0.45)
	m.emission_energy_multiplier = 0.9
	m.roughness = 0.5
	return m
