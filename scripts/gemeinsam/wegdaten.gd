extends RefCounted
class_name Wegdaten
## Der Weg eines Korridorlevels als Daten: Abschnitte samt Höhen, Begehbares,
## Leitlinien, Todeszonen und Ränder – dazu die Abfragen und der Rohbau
## (Decke, Begehbares, Leitlinien, Schultern, Todeszonen) aus Level 01.
##
## WARUM EINE KOPIE. Level 01 hält all das als Konstanten in `level01.gd`
## (Abfragen :1383-1640, Rohbau :910-1095) und bleibt, wie es ist – es ist
## geprüft und abgenommen, jede Änderung dort müsste der Wächter (Bilder
## und Logs) erst wieder freisprechen. Die Level 02–05 brauchen dieselben
## Abfragen (`kiste()` und `gegner()` setzen sonst relativ zur Kurve, und
## level_check verlangt für seine Opt-in-Proben `breite_bei` UND
## `boden_bei`). Deshalb steht der Code hier ein zweites Mal, ohne den Typ
## `Level01`: Die Daten kommen als Wörterbuch herein, nicht als Konstanten
## einer Klasse. Rechenweg und Reihenfolge sind wörtlich übernommen, damit
## `werkzeuge/baukastenprobe.gd` mit den Daten von Level 01 Gleitkomma-
## Gleichheit messen kann – wer hier etwas „verbessert", bricht diese Probe
## und muss das begründen.
##
## DATEN. Die Schemata sind die aus Level 01:
##   abschnitte   LevelWerkzeuge.korridor (level_werkzeuge.gd:85-101):
##                {von, bis, breite, breite_ende?, hoehe?, hoehe_ende?, stoff?}
##                "hoehe": absolute Welt-Y der Decke, ohne Angabe folgt sie
##                der Kurve (Terrassen, während die Kamera glatt fährt)
##   begehbares   BEGEHBARES (level01.gd:371-389): kasten, zylinder, kapsel,
##                streifen, sweep; "ebene" 1 oder 16, "optik" frei
##   leitlinien   LEITLINIEN (level01.gd:520-525), Ebene 16, "schulter"
##   todeszonen   TODESZONEN (level01.gd:561-571), dazu NEU und freiwillig
##                "unten_y" (Unterkante; ohne Angabe −30 wie bisher)
##   raender      RAENDER (level01.gd:232-249), für `rand_profil`
## Der Zustand gehört der Instanz (Baukasten §0 Nr. 3): Nur der Zwischen-
## speicher des Begehbaren hängt an ihr, nichts ist statisch.
##
## KOORDINATEN wie in Level 01: `s` Strecke auf dem Verlauf, `q` quer dazu
## (positiv = rechts), Höhen relativ zur Wegdecke an der Stelle
## (`boden_bei(s)`), außer wo ein Name auf `_y` endet (Welt-Y).

## Ebene der Spielergrenze (Leitlinien, erhöhtes Begehbares), wie in Level 01.
const SPIELERGRENZE := LevelWerkzeuge.SPIELERGRENZE

var verlauf: Curve3D
var abschnitte: Array[Dictionary] = []
var begehbares: Array[Dictionary] = []
var leitlinien: Array[Dictionary] = []
var todeszonen: Array[Dictionary] = []
var raender: Array[Dictionary] = []

## Berechnete Fassungen der Begehbares-Einträge je Name (wie level01.gd:867).
var _begehbar_berechnet := {}


## `daten`: {"abschnitte", "begehbares", "leitlinien", "todeszonen",
## "raender"}, jeder Schlüssel freiwillig. Die Einträge werden nicht kopiert:
## Konstanten eines Levels bleiben Konstanten.
func _init(kurve: Curve3D, daten: Dictionary) -> void:
	verlauf = kurve
	abschnitte.assign(daten.get("abschnitte", []))
	begehbares.assign(daten.get("begehbares", []))
	leitlinien.assign(daten.get("leitlinien", []))
	todeszonen.assign(daten.get("todeszonen", []))
	raender.assign(daten.get("raender", []))


# =========================================================== Abfragen
#
# Wörtlich wie level01.gd:1382-1640 (Rechenweg und Reihenfolge).

## Der Abschnitt, der `s` enthält, oder {} in einer Lücke.
func abschnitt_bei(s: float) -> Dictionary:
	for a: Dictionary in abschnitte:
		if s >= float(a["von"]) and s <= float(a["bis"]):
			return a
	return {}


## Breite des Weges an dieser Stelle. 0.0 bedeutet: hier ist eine Lücke.
func breite_bei(s: float) -> float:
	var a := abschnitt_bei(s)
	if a.is_empty():
		return 0.0
	var von: float = a["von"]
	var bis: float = a["bis"]
	var t := inverse_lerp(von, bis, s) if bis > von else 0.0
	var breite: float = a["breite"]
	return lerpf(breite, float(a.get("breite_ende", breite)), t)


func ist_luecke(s: float) -> bool:
	return breite_bei(s) <= 0.0


## Halbe Wegbreite; in einer Lücke die breitere der beiden Kanten.
func wegrand(s: float) -> float:
	var halb := breite_bei(s) * 0.5
	if halb <= 0.0:
		halb = maxf(breite_bei(kante_vor(s)), breite_bei(kante_nach(s))) * 0.5
	return halb


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func rand_bei(s: float, sicherheit: float = 1.3) -> float:
	return maxf(breite_bei(s) * 0.5 - sicherheit, 0.0)


## Welt-Y der Wegdecke. In einer Lücke linear zwischen den Kanten davor und
## danach (für Fruchtbögen und Zonen), vor dem Anfang und hinter dem Ende
## die Höhe des ersten bzw. letzten Abschnitts. Lücken erkennt man an
## `ist_luecke(s)`, nicht an dieser Höhe (Baukasten §4 Nr. 6).
func boden_bei(s: float) -> float:
	var a := abschnitt_bei(s)
	if not a.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, a, s)
	var vorher: Dictionary = {}
	var nachher: Dictionary = {}
	for e: Dictionary in abschnitte:
		if float(e["bis"]) <= s:
			vorher = e
		elif float(e["von"]) >= s and nachher.is_empty():
			nachher = e
	if vorher.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, nachher, float(nachher["von"]))
	if nachher.is_empty():
		return LevelWerkzeuge.eintrag_hoehe(verlauf, vorher, float(vorher["bis"]))
	var ha := LevelWerkzeuge.eintrag_hoehe(verlauf, vorher, float(vorher["bis"]))
	var hb := LevelWerkzeuge.eintrag_hoehe(verlauf, nachher, float(nachher["von"]))
	return lerpf(ha, hb, inverse_lerp(float(vorher["bis"]), float(nachher["von"]), s))


## Höhe der Wegdecke über der Kurve an dieser Stelle. Die alten Helfer von
## `KorridorLevel` (`kiste`, `frucht`, `gegner`) messen ihre Höhe über der
## KURVE (`LevelWerkzeuge.punkt`); wer sie auf eine Terrasse stellt, gibt
## ihnen `ueber_kurve(s) + Höhe über dem Boden`.
func ueber_kurve(s: float) -> float:
	return boden_bei(s) - verlauf.sample_baked(clampf(s, 0.0, verlauf.get_baked_length())).y


## Punkt auf dem Weg: `q` quer, `h` über der Wegdecke. Auch vor dem Anfang
## und hinter dem Ende (dort geradeaus weiter).
func weg_punkt(s: float, q: float = 0.0, h: float = 0.0) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(verlauf, s, q)
	p.y = boden_bei(s) + h
	return p


## Das durchgehende Stück Weg um `s` als Vector2(von, bis): Abschnitte, die
## gleich hoch aneinanderstoßen, zählen zusammen. Nur Lücken und Stufen
## trennen. In einer Lücke: Vector2(s, s).
func strang_bei(s: float) -> Vector2:
	var index := -1
	for i in abschnitte.size():
		var a: Dictionary = abschnitte[i]
		if s >= float(a["von"]) and s <= float(a["bis"]):
			index = i
			break
	if index < 0:
		return Vector2(s, s)
	var anfang := index
	while anfang > 0 and _durchgehend(anfang - 1, anfang):
		anfang -= 1
	var ende := index
	while ende < abschnitte.size() - 1 and _durchgehend(ende, ende + 1):
		ende += 1
	return Vector2(float(abschnitte[anfang]["von"]), float(abschnitte[ende]["bis"]))


func _durchgehend(i: int, j: int) -> bool:
	var a: Dictionary = abschnitte[i]
	var b: Dictionary = abschnitte[j]
	var naht: float = a["bis"]
	if absf(float(b["von"]) - naht) > 0.01:
		return false
	return absf(LevelWerkzeuge.eintrag_hoehe(verlauf, a, naht)
			- LevelWerkzeuge.eintrag_hoehe(verlauf, b, naht)) < 0.05


## Schiebt eine Strecke von der Kante eines Strangs weg, damit Objekte nicht
## auf der Abbruchkante oder an einer Stufe stehen.
func weg_von_der_kante(s: float, abstand: float) -> float:
	if ist_luecke(s):
		return s
	var strang := strang_bei(s)
	if strang.y - strang.x <= abstand * 2.0:
		return (strang.x + strang.y) * 0.5
	return clampf(s, strang.x + abstand, strang.y - abstand)


## Die Lücken als Vector2(von, bis), der Strecke nach. Abgeleitet aus den
## Abschnitten: Wo zwei aufeinanderfolgende mehr als 1 cm auseinander-
## liegen, ist eine Lücke (dieselbe Schwelle wie `_durchgehend`). Stufen
## sind keine Lücken.
func luecken() -> Array[Vector2]:
	var sortiert := abschnitte.duplicate()
	sortiert.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["von"]) < float(b["von"]))
	var liste: Array[Vector2] = []
	for i in sortiert.size() - 1:
		var bis: float = sortiert[i]["bis"]
		var von: float = sortiert[i + 1]["von"]
		if von - bis > 0.01:
			liste.append(Vector2(bis, von))
	return liste


## Der Rand an einer Stelle, ausgerechnet (Schema wie level01.gd:1492-1497):
## {"typ", "abstand", "wegrand", "hoehe", "kante_y", "fuss_y", "krone_y",
## "vorsprung", "eintrag"}.
func rand_profil(s: float, seite: float) -> Dictionary:
	var rand := breite_bei(s) * 0.5
	if rand <= 0.0:
		rand = maxf(breite_bei(kante_vor(s)), breite_bei(kante_nach(s))) * 0.5
	var kante_y := boden_bei(s)
	for r: Dictionary in raender:
		if int(r["seite"]) != int(signf(seite)):
			continue
		var von: float = r["von"]
		var bis: float = r["bis"]
		if s < von or s > bis:
			continue
		var t := inverse_lerp(von, bis, s) if bis > von else 0.0
		var abstand := rand
		if r.has("abstand"):
			var a0: float = r["abstand"]
			abstand = lerpf(a0, float(r.get("abstand_ende", a0)), t)
		# Vorsprünge: Die Lippe springt über den Abstand hinaus.
		var vorsprung := false
		for linie: Array in r.get("umriss", []):
			var q_lippe := polylinie_q(linie, s)
			if not is_nan(q_lippe) and absf(q_lippe) > abstand:
				abstand = absf(q_lippe)
				vorsprung = true
		var hoehe := 0.0
		if r.has("hoehe"):
			var h0: float = r["hoehe"]
			hoehe = lerpf(h0, float(r.get("hoehe_ende", h0)), t)
		var fuss_y := NAN
		if r.has("fuss_y"):
			var f0: float = r["fuss_y"]
			fuss_y = lerpf(f0, float(r.get("fuss_y_ende", f0)), t)
		var typ: String = r["typ"]
		var krone_y := NAN
		if typ == "FELS_AUF" or typ == "BOESCHUNG":
			krone_y = kante_y + hoehe
		return {"typ": typ, "abstand": abstand, "wegrand": rand, "hoehe": hoehe,
				"kante_y": kante_y, "fuss_y": fuss_y, "krone_y": krone_y,
				"vorsprung": vorsprung, "eintrag": r}
	return {"typ": "FLACH", "abstand": rand, "wegrand": rand, "hoehe": 0.0,
			"kante_y": kante_y, "fuss_y": NAN, "krone_y": NAN, "vorsprung": false,
			"eintrag": {}}


## Ende des letzten Abschnitts bis `s` (die Kante VOR einer Lücke); `s`
## selbst, wenn davor keiner endet.
func kante_vor(s: float) -> float:
	var beste := -INF
	for a: Dictionary in abschnitte:
		if float(a["bis"]) <= s:
			beste = maxf(beste, float(a["bis"]))
	return beste if beste > -INF else s


## Anfang des ersten Abschnitts ab `s` (die Kante NACH einer Lücke).
func kante_nach(s: float) -> float:
	var beste := INF
	for a: Dictionary in abschnitte:
		if float(a["von"]) >= s:
			beste = minf(beste, float(a["von"]))
	return beste if beste < INF else s


## Ein Eintrag aus `begehbares` samt berechneter Lage (wie level01.gd:1567):
##   "lage"          Welttransform des Körpers (Formen und Optik liegen darin)
##   "querschnitte"  nur streifen/sweep: Array[PackedVector3Array] in Welt-
##                   koordinaten, je Stelle der Umriss des Querschnitts
##   "stellen"       nur streifen/sweep: die Strecken dazu
## Leeres Wörterbuch, wenn es den Namen nicht gibt.
func begehbar(name: String) -> Dictionary:
	if _begehbar_berechnet.has(name):
		return _begehbar_berechnet[name]
	for roh: Dictionary in begehbares:
		if String(roh["name"]) != name:
			continue
		var e := roh.duplicate(true)
		match String(e["form"]):
			"kasten":
				e["lage"] = _kasten_lage(e)
			"zylinder":
				e["lage"] = _zylinder_lage(e)
			"kapsel":
				e["lage"] = _kapsel_lage(e)
			_:
				e["lage"] = Transform3D.IDENTITY
				var stellen := _stellen(float(e["von"]), float(e["bis"]))
				var schnitte: Array[PackedVector3Array] = []
				for s in stellen:
					schnitte.append(_querschnitt(e, s))
				e["stellen"] = stellen
				e["querschnitte"] = schnitte
		_begehbar_berechnet[name] = e
		return e
	return {}


## Welt-Y der Oberseite eines Begehbaren an (s, q) – für Kisten und
## Früchte darauf.
func oberkante(name: String, s: float, q: float) -> float:
	var e := begehbar(name)
	if e.is_empty():
		return boden_bei(s)
	match String(e["form"]):
		"kasten":
			var lage: Transform3D = e["lage"]
			var groesse: Vector3 = e["groesse"]
			# Die Oberseite ist eine Ebene: Höhe über der Stelle ablesen.
			var oben := lage * Vector3(0.0, groesse.y * 0.5, 0.0)
			var normale := lage.basis.y.normalized()
			var p := weg_punkt(s, q)
			if absf(normale.y) < 0.001:
				return oben.y
			return oben.y - ((p.x - oben.x) * normale.x + (p.z - oben.z) * normale.z) / normale.y
		"zylinder":
			var lage: Transform3D = e["lage"]
			return lage.origin.y + float(e["hoehe"]) * 0.5
		"kapsel":
			var lage: Transform3D = e["lage"]
			return lage.origin.y + float(e["radius"])
		"streifen":
			if e.has("oben_y"):
				return float(e["oben_y"])
			return boden_bei(s) + float(e.get("oben", 0.0))
		"sweep":
			var profil := _profil_bei(e, s)
			var oben := -INF
			for i in profil.size():
				var a := profil[i]
				var b := profil[(i + 1) % profil.size()]
				if (q - a.x) * (q - b.x) <= 0.0 and absf(b.x - a.x) > 0.0001:
					oben = maxf(oben, lerpf(a.y, b.y, (q - a.x) / (b.x - a.x)))
			if oben == -INF:
				return boden_bei(s)
			return boden_bei(s) + oben
	return boden_bei(s)


## q einer Polylinie [Vector2(s, q)] an der Stelle `s`; NAN außerhalb.
static func polylinie_q(punkte: Array, s: float) -> float:
	if punkte.is_empty():
		return NAN
	var erster: Vector2 = punkte[0]
	var letzter: Vector2 = punkte[punkte.size() - 1]
	if s < erster.x - 0.001 or s > letzter.x + 0.001:
		return NAN
	for i in punkte.size() - 1:
		var a: Vector2 = punkte[i]
		var b: Vector2 = punkte[i + 1]
		if s >= a.x and s <= b.x:
			if b.x - a.x < 0.0001:
				return b.y
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	return letzter.y if s >= letzter.x else erster.y


# =========================================================== Rohbau
#
# Wie level01.gd:910-1095. Jede Funktion hängt einen eigenen Knoten unter
# `eltern` und gibt ihn zurück; die Reihenfolge bestimmt das Level.

## Die Wegdecke: je Stoff ein sichtbares Netz, dazu EINE unsichtbare
## Kollision über alle Abschnitte – nur so kennt die Stufenkollision alle
## Nachbarn. Ohne Kante und Klippe (Variante b, Baukasten §0 Nr. 5): Ränder
## baut das Level. `stoff_fuer(abschnitt) -> Material`; null (oder ein
## leeres Callable) heißt Waldweg.
func decke_bauen(eltern: Node3D, stoff_fuer: Callable) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Wegdecke"
	eltern.add_child(wurzel)
	var gruppen := {}
	var reihenfolge: Array[Material] = []
	for a: Dictionary in abschnitte:
		var stoff: Material = null
		if stoff_fuer.is_valid():
			stoff = stoff_fuer.call(a) as Material
		if stoff == null:
			stoff = Materialbibliothek.waldweg()
		if not gruppen.has(stoff):
			gruppen[stoff] = []
			reihenfolge.append(stoff)
		(gruppen[stoff] as Array).append(a)
	for stoff in reihenfolge:
		var netz := LevelWerkzeuge.korridor(wurzel, verlauf, gruppen[stoff],
				{"oben": stoff}, {
			"nur_decke": true, "uv_quer": true, "schritt": 1.0,
			"quer_teilung": 2, "kollision": false,
		})
		netz.name = "Weg"
		# Der Boden wirft keinen Schatten, den jemand sähe; jede Schatten-
		# stufe zeichnete ihn trotzdem noch einmal.
		for kind in netz.get_children():
			if kind is GeometryInstance3D:
				(kind as GeometryInstance3D).cast_shadow = \
						GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var boden := LevelWerkzeuge.korridor(wurzel, verlauf, abschnitte, {}, {
		"nur_decke": true, "schritt": 1.0, "sichtbar": false,
		"kollision": true, "stufen_kollision": true, "ebene": 1,
	})
	boden.name = "Wegboden"
	return wurzel


## Begehbares mit Kollision und Optik. `optik(eintrag) -> Node3D` bekommt
## den berechneten Eintrag (`begehbar`) und baut die Optik passgenau auf die
## Kollision; sie wird Kind des Körpers. Liefert sie null (oder ist das
## Callable leer), steht dort ein grauer Platzhalter in der Form der Kollision.
func begehbares_bauen(eltern: Node3D, optik: Callable) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Begehbares"
	eltern.add_child(wurzel)
	for roh: Dictionary in begehbares:
		var e := begehbar(String(roh["name"]))
		var koerper := StaticBody3D.new()
		koerper.name = String(e["name"])
		koerper.collision_layer = int(e["ebene"])
		koerper.collision_mask = 0
		koerper.transform = e["lage"]
		for form in formen(e):
			koerper.add_child(form)
		var sicht: Node3D = null
		if optik.is_valid():
			sicht = optik.call(e) as Node3D
		if sicht == null:
			sicht = platzhalter(e)
		if sicht != null:
			koerper.add_child(sicht)
		wurzel.add_child(koerper)
	return wurzel


## Unsichtbare Leitlinien auf Ebene 16 (Spielergrenze).
func leitlinien_bauen(eltern: Node3D) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Leitlinien"
	eltern.add_child(wurzel)
	for e: Dictionary in leitlinien:
		var linie := LevelWerkzeuge.leitlinie(wurzel, verlauf, e["punkte"],
				float(e.get("hoehe", 6.0)), SPIELERGRENZE, float(e.get("unten", 3.0)),
				1.0, float(e.get("aussen", 0.0)))
		linie.name = String(e["name"])
	return wurzel


## Boden zwischen Wegkante und Leitlinie (Ebene 1), bündig mit der Decke –
## wo eine Leitlinie "schulter" trägt (level01.gd:992-999). Je Abschnitt
## getrennt, damit die Schulter an Stufen mit der Decke springt; zwei Meter
## dick, damit man unter einer oberen Schulter nicht hindurchkommt.
func schultern_bauen(eltern: Node3D) -> Node3D:
	var koerper := StaticBody3D.new()
	koerper.name = "Schultern"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	for e: Dictionary in leitlinien:
		if not e.has("schulter"):
			continue
		var bereich: Vector2 = e["schulter"]
		var punkte: Array = e["punkte"]
		for a: Dictionary in abschnitte:
			var von := maxf(float(a["von"]), bereich.x)
			var bis := minf(float(a["bis"]), bereich.y)
			if bis - von < 0.05:
				continue
			var anzahl := maxi(ceili(bis - von), 1)
			var vorher := PackedVector3Array()
			for i in anzahl + 1:
				var s := lerpf(von, bis, float(i) / float(anzahl))
				var jetzt := _schulter_schnitt(a, punkte, s)
				if not vorher.is_empty() and not jetzt.is_empty():
					koerper.add_child(prisma(vorher, jetzt))
				vorher = jetzt
	eltern.add_child(koerper)
	return koerper


func _schulter_schnitt(a: Dictionary, punkte: Array, s: float) -> PackedVector3Array:
	var schnitt := PackedVector3Array()
	var q_linie := polylinie_q(punkte, s)
	if is_nan(q_linie):
		return schnitt
	var seite := signf(q_linie)
	var von: float = a["von"]
	var bis: float = a["bis"]
	var t := inverse_lerp(von, bis, s) if bis > von else 0.0
	var breite_a: float = a["breite"]
	var halb := lerpf(breite_a, float(a.get("breite_ende", breite_a)), t) * 0.5
	var innen := halb - 0.15
	var aussen := absf(q_linie) + 0.4
	if aussen <= innen + 0.2:
		return schnitt
	var oben := LevelWerkzeuge.eintrag_hoehe(verlauf, a, s)
	for p: Vector2 in [Vector2(innen, oben), Vector2(aussen, oben),
			Vector2(aussen, oben - 2.0), Vector2(innen, oben - 2.0)]:
		var w := LevelWerkzeuge.punkt_frei(verlauf, s, seite * p.x)
		schnitt.append(Vector3(w.x, p.y, w.z))
	return schnitt


## Todeszonen nach `todeszonen` (Gruppe "todeszonen", level_werkzeuge.gd:1153).
## "unter_weg": Oberkante je Stück so tief unter der Decke, an keiner Stufe
## vorbei; "am_rand": Innengrenze je Stück an der Wegkante; sonst "oben_y"
## fest. "unten_y" (freiwillig) setzt die Unterkante, ohne Angabe −30 wie
## in Level 01.
func todeszonen_bauen(eltern: Node3D) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = "Todeszonen"
	eltern.add_child(wurzel)
	for e: Dictionary in todeszonen:
		var von: float = e["von"]
		var bis: float = e["bis"]
		var q_von: float = e.get("q_von", 0.0)
		var q_bis: float = e["q_bis"]
		var unten_y: float = e.get("unten_y", -30.0)
		# "am_rand": Innengrenze je Stück an der Wegkante (level01.gd:565-570).
		var am_rand: float = e.get("am_rand", NAN)
		var zonen: Array[Area3D] = []
		if e.has("unter_weg"):
			# In Stücken, die an keiner Stufe vorbeilaufen: Die Oberkante
			# folgt dem Weg je Stück linear.
			var tief: float = e["unter_weg"]
			var grenzen: Array[float] = [von]
			for a: Dictionary in abschnitte:
				for g: float in [float(a["von"]), float(a["bis"])]:
					if g > von + 0.01 and g < bis - 0.01 and not grenzen.has(g):
						grenzen.append(g)
			grenzen.append(bis)
			grenzen.sort()
			for i in grenzen.size() - 1:
				var a_s := grenzen[i]
				var b_s := grenzen[i + 1]
				var teile := maxi(ceili((b_s - a_s) / 6.0), 1)
				for k in teile:
					var s0 := lerpf(a_s, b_s, float(k) / float(teile))
					var s1 := lerpf(a_s, b_s, float(k + 1) / float(teile))
					# Knapp innerhalb des Stücks messen, damit die Stufe nicht
					# den Wert des Nachbarn liefert.
					var y0 := boden_bei(s0 + 0.01) - tief
					var y1 := boden_bei(s1 - 0.01) - tief
					var innen := q_von
					if not is_nan(am_rand):
						var kante := minf(wegrand(s0 + 0.01), wegrand(s1 - 0.01))
						innen = signf(q_bis) * (kante - am_rand)
					zonen.append(LevelWerkzeuge.todeszone(wurzel, verlauf, s0, s1,
							innen, q_bis, y0, y1, unten_y))
		else:
			zonen.append(LevelWerkzeuge.todeszone(wurzel, verlauf, von, bis,
					q_von, q_bis, float(e["oben_y"]), NAN, unten_y))
		for z in zonen:
			z.name = String(e["name"])
	return wurzel


## Todeszonen „Boden − tiefe" als Einträge auf FESTER Höhe, zum Anhängen an
## `todeszonen`: von `von` bis `bis`, quer `q_von`–`q_bis`, in Stücken von
## höchstens sechs Metern, die an keiner Abschnittsgrenze vorbeilaufen. Je
## Stück liegt die Oberkante `tiefe` unter der TIEFSTEN Decke des Stücks
## (Anfang, Mitte, Ende), die Unterkante `unten` darunter.
##
## Wozu, wenn es "unter_weg" gibt: Eine Zone mit fester Oberkante folgt
## keiner Neigung, sie bleibt also auch unter einem Hang überall mindestens
## `tiefe` unter dem Weg – und die Unterkante wandert mit (statt fest bei
## −30), was Level weit über oder unter null brauchen. Statt `absturzzonen()`
## (hängt an der Kurve, keine Gruppe, Baukasten §4 Nr. 7).
static func zonen_unter_boden(weg: Wegdaten, von: float, bis: float, q_von: float,
		q_bis: float, tiefe := 8.0, unten := 20.0) -> Array[Dictionary]:
	var grenzen: Array[float] = [von]
	for a: Dictionary in weg.abschnitte:
		for g: float in [float(a["von"]), float(a["bis"])]:
			if g > von + 0.01 and g < bis - 0.01 and not grenzen.has(g):
				grenzen.append(g)
	grenzen.append(bis)
	grenzen.sort()
	var zonen: Array[Dictionary] = []
	for i in grenzen.size() - 1:
		var a_s := grenzen[i]
		var b_s := grenzen[i + 1]
		var teile := maxi(ceili((b_s - a_s) / 6.0), 1)
		for k in teile:
			var s0 := lerpf(a_s, b_s, float(k) / float(teile))
			var s1 := lerpf(a_s, b_s, float(k + 1) / float(teile))
			var tiefster := minf(minf(weg.boden_bei(s0 + 0.01), weg.boden_bei(s1 - 0.01)),
					weg.boden_bei((s0 + s1) * 0.5))
			var oben := tiefster - tiefe
			zonen.append({"name": "Unter dem Boden", "von": s0, "bis": s1,
					"q_von": q_von, "q_bis": q_bis, "oben_y": oben, "unten_y": oben - unten})
	return zonen


## Sprungfälle für `werkzeuge/sprungprobe.gd` aus den Lücken (Muster
## level01.gd:1317-1329): je Lücke und Bahn `q` ein Fall, Anlauf vier Meter
## vor der Kante, Reihe der Absprungstellen zwei Meter zurück, Landung zählt
## ab `landung_spiel` vor der Gegenkante (die Kapsel, r 0,38, steht dort noch).
func sprungfaelle_aus_luecken(landung_spiel := 0.45,
		bahnen: Array[float] = [0.0]) -> Array[Dictionary]:
	var faelle: Array[Dictionary] = []
	for luecke in luecken():
		var kante := luecke.x
		for q in bahnen:
			faelle.append({"name": "Lücke %.1f" % kante + (" q %+.1f" % q if q != 0.0 else ""),
					"start": Vector2(kante - 4.0, q), "kante": kante, "von": kante - 2.0,
					"landung": luecke.y - landung_spiel})
	return faelle


# =========================================================== Formen

func _kasten_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var groesse: Vector3 = e["groesse"]
	var oben: float = e.get("oben", 0.0)
	var a := weg_punkt(s - groesse.z * 0.5, q, oben)
	var b := weg_punkt(s + groesse.z * 0.5, q, oben)
	var vor := (b - a).normalized()
	var rechts := vor.cross(Vector3.UP).normalized()
	var hoch := rechts.cross(vor).normalized()
	var basis := Basis(rechts, hoch, -vor)
	return Transform3D(basis, (a + b) * 0.5 - hoch * groesse.y * 0.5)


func _zylinder_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var hoehe: float = e["hoehe"]
	var mitte := weg_punkt(s, q)
	var oben: float = e["oben_y"] if e.has("oben_y") else mitte.y + float(e.get("oben", 0.0))
	mitte.y = oben - hoehe * 0.5
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, s)), mitte)


func _kapsel_lage(e: Dictionary) -> Transform3D:
	var s: float = e["s"]
	var q: float = e["q"]
	var mitte := weg_punkt(s, q, float(e.get("oben", 0.0)) - float(e["radius"]))
	return Transform3D(Basis(Vector3.UP, LevelWerkzeuge.drehung(verlauf, s)), mitte)


## Kollisionsformen eines berechneten Eintrags, im Raum seines Körpers.
func formen(e: Dictionary) -> Array[CollisionShape3D]:
	var liste: Array[CollisionShape3D] = []
	match String(e["form"]):
		"kasten":
			var form := CollisionShape3D.new()
			var kasten := BoxShape3D.new()
			kasten.size = e["groesse"]
			form.shape = kasten
			liste.append(form)
		"zylinder":
			var form := CollisionShape3D.new()
			var walze := CylinderShape3D.new()
			walze.radius = e["radius"]
			walze.height = e["hoehe"]
			form.shape = walze
			liste.append(form)
		"kapsel":
			var form := CollisionShape3D.new()
			var kapsel := CapsuleShape3D.new()
			kapsel.radius = e["radius"]
			kapsel.height = e["laenge"]
			form.shape = kapsel
			# Die Kapsel liegt quer über dem Weg: ihre Achse (lokal Y) auf X.
			form.rotation.z = PI * 0.5
			liste.append(form)
		_:
			var schnitte: Array[PackedVector3Array] = e["querschnitte"]
			for i in schnitte.size() - 1:
				liste.append(prisma(schnitte[i], schnitte[i + 1]))
	return liste


## Konvexe Hülle zweier Querschnitte als Kollisionsform.
static func prisma(a: PackedVector3Array, b: PackedVector3Array) -> CollisionShape3D:
	var form := CollisionShape3D.new()
	var huelle := ConvexPolygonShape3D.new()
	var punkte := a.duplicate()
	punkte.append_array(b)
	huelle.points = punkte
	form.shape = huelle
	return form


## Die Strecken, an denen ein Streifen oder Sweep geschnitten wird: höchstens
## einen Meter auseinander und genau an jeder Abschnittsgrenze, damit die
## Höhe an Stufen nicht verschmiert.
func _stellen(von: float, bis: float) -> PackedFloat32Array:
	var grenzen: Array[float] = [von, bis]
	for a: Dictionary in abschnitte:
		for g: float in [float(a["von"]), float(a["bis"])]:
			if g > von + 0.05 and g < bis - 0.05 and not grenzen.has(g):
				grenzen.append(g)
	grenzen.sort()
	var stellen := PackedFloat32Array()
	for i in grenzen.size() - 1:
		var teile := maxi(ceili(grenzen[i + 1] - grenzen[i]), 1)
		for k in teile:
			stellen.append(lerpf(grenzen[i], grenzen[i + 1], float(k) / float(teile)))
	stellen.append(bis)
	return stellen


func _profil_bei(e: Dictionary, s: float) -> Array[Vector2]:
	var profil: Array[Vector2] = []
	var anfang: Array = e["profil"]
	var ende: Array = e.get("profil_ende", anfang)
	var von: float = e["von"]
	var bis: float = e["bis"]
	var t := clampf(inverse_lerp(von, bis, s), 0.0, 1.0) if bis > von else 0.0
	for i in anfang.size():
		var a: Vector2 = anfang[i]
		var b: Vector2 = ende[i]
		profil.append(a.lerp(b, t))
	return profil


## Umriss eines Streifens oder Sweeps an der Stelle `s`, in Weltpunkten.
func _querschnitt(e: Dictionary, s: float) -> PackedVector3Array:
	var schnitt := PackedVector3Array()
	if String(e["form"]) == "sweep":
		var boden := boden_bei(s)
		for p in _profil_bei(e, s):
			var w := LevelWerkzeuge.punkt_frei(verlauf, s, p.x)
			schnitt.append(Vector3(w.x, boden + p.y, w.z))
		return schnitt
	# Streifen: innen (Polylinie oder Wegkante) bis außen, flach.
	var aussen := polylinie_q(e["aussen"], s)
	var innen := 0.0
	if e.has("innen"):
		innen = polylinie_q(e["innen"], s)
	else:
		var halb := breite_bei(s) * 0.5
		if halb <= 0.0:
			halb = maxf(breite_bei(s - 0.05), breite_bei(s + 0.05)) * 0.5
		innen = signf(aussen) * maxf(halb - 0.1, 0.0)
	var oben: float = e["oben_y"] if e.has("oben_y") else boden_bei(s) + float(e.get("oben", 0.0))
	var unten := oben - float(e.get("hoehe", 1.0))
	for p: Vector2 in [Vector2(innen, oben), Vector2(aussen, oben),
			Vector2(aussen, unten), Vector2(innen, unten)]:
		var w := LevelWerkzeuge.punkt_frei(verlauf, s, p.x)
		schnitt.append(Vector3(w.x, p.y, w.z))
	return schnitt


# =========================================================== Platzhalter

## Grauer Platzhalter genau in der Form der Kollision – solange keine Optik
## geliefert wird (wie level01.gd:1798-1823).
func platzhalter(e: Dictionary) -> Node3D:
	var netz := MeshInstance3D.new()
	netz.name = "Platzhalter"
	match String(e["form"]):
		"kasten":
			var kasten := BoxMesh.new()
			kasten.size = e["groesse"]
			netz.mesh = kasten
		"zylinder":
			var walze := CylinderMesh.new()
			walze.top_radius = e["radius"]
			walze.bottom_radius = e["radius"]
			walze.height = e["hoehe"]
			netz.mesh = walze
		"kapsel":
			var kapsel := CapsuleMesh.new()
			kapsel.radius = e["radius"]
			kapsel.height = e["laenge"]
			netz.mesh = kapsel
			netz.rotation.z = PI * 0.5
		_:
			netz.mesh = schnittnetz(e["querschnitte"])
	netz.material_override = Materialbibliothek.einfarbig(Color(0.52, 0.52, 0.5))
	return netz


## Netz aus einer Folge gleich langer Querschnitte: Mantel und zwei Deckel.
static func schnittnetz(schnitte: Array[PackedVector3Array]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in schnitte.size() - 1:
		var a := schnitte[i]
		var b := schnitte[i + 1]
		var mitte := _schwerpunkt(a)
		var laengs := (_schwerpunkt(b) - mitte).normalized()
		for k in a.size():
			var k2 := (k + 1) % a.size()
			var rand_mitte := (a[k] + a[k2]) * 0.5
			var n := rand_mitte - mitte
			n -= laengs * n.dot(laengs)
			_netz_dreieck(st, a[k], a[k2], b[k], n)
			_netz_dreieck(st, a[k2], b[k2], b[k], n)
	for ende in 2:
		var schnitt := schnitte[0] if ende == 0 else schnitte[schnitte.size() - 1]
		var nachbar := schnitte[1] if ende == 0 else schnitte[schnitte.size() - 2]
		var mitte := _schwerpunkt(schnitt)
		var n := mitte - _schwerpunkt(nachbar)
		for k in schnitt.size():
			_netz_dreieck(st, mitte, schnitt[k], schnitt[(k + 1) % schnitt.size()], n)
	return st.commit()


static func _schwerpunkt(punkte: PackedVector3Array) -> Vector3:
	var summe := Vector3.ZERO
	for p in punkte:
		summe += p
	return summe / maxf(float(punkte.size()), 1.0)


## Dreieck mit Wicklung und Normale wie `LevelWerkzeuge._dreieck`.
static func _netz_dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3) -> void:
	var n := normale.normalized()
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tausch := b
		b = c
		c = tausch
	for p: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(p)
