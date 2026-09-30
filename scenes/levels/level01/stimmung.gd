extends RefCounted
class_name L01Stimmung
## Level 01, Modul „Stimmung": Licht, Nebel, Lichtschächte und Bewegung
## (Plan Abschnitt 10).
##
## LUFTPERSPEKTIVE. Nahes ist warm, Fernes kühl: Die Sonne (Level01.tscn)
## malt den Weg und alles in den ersten Metern warm, der Tiefennebel (ab
## 12 m) zieht das Ferne in einen kühlen Dunst. Aus ihm kommt der kühle
## Anteil jedes Bildes (Ferne, Himmel, Wasser), und er hält das Ferne
## dunkler als den Weg (Lesbarkeitsvertrag: Weg am hellsten, dunkler Rahmen).
##
## STIMMUNG ENTLANG DES WEGES (`Regler`). Jeder Abschnitt hat sein Licht,
## RELATIV zur Grundstimmung der Szene wie bei `Stimmungszone`
## (`nebel_faktor` verkürzt die Nebelstrecke, `licht_faktor` skaliert das
## Umgebungslicht, `FARBANTEIL` zieht die Farben ein Stück zur Zonenfarbe):
##   A Hallenwald   kühl, gedämpft grün, dichter Dunst zwischen den Stämmen
##   B Hangweg      golden, klar, kühl-blaue Ferne (Nebel reicht weit, der
##                  Weltenbaum liest sich als Silhouette vor dem Dunst)
##   C Fallklamm    kühl, Gischt
##   D Bachwiese    warm grün
##   E/F Wendel     golden – EINE Zone als Zylinder um die Weltenbaumachse
##                  (ab der Wurzel, nicht schon auf der Wiese darunter)
## Die Werte hängen nicht an Auslösekästen und einer Überblendung über die
## Zeit (`Stimmungszone`), sondern an der Stelle: Der Regler rechnet jedes
## Bild aus der Strecke der Figur die Mischung der Zonen (weiche Übergänge
## über `UEBERGANG` m) und geht ihr in einer knappen Zehntelsekunde nach.
## So sieht jede Stelle immer gleich aus – im Spiel wie auf dem Foto, das
## nach 0,8 s Wartezeit sonst eine halbe Überblendung von der vorigen
## Aufnahmestelle zeigte –, und die Zonen der Wendel überlagern sich nicht
## mit denen der Wiese, über der sie sich windet. Der Bachnebel des
## Geländes (`L01Gelaende.nebel_stoff`) folgt der Nebelfarbe.
##
## LICHTSCHÄCHTE (`Lichtschacht`, je mit `Staubflug`): in A durch die zwei
## Löcher im Blätterdach (`Level01.LICHTLOECHER`, Decke = Dach), in C an
## der linken Wand bis über ihre Krone, in D aus den Kronen der Talriesen
## (Decke ≈ y 24). Die Bahnen folgen der Sonne der Szene.
##
## BEWEGUNG: Laubtreiben an sechs Stellen, vier Vogelschwärme – zwei über
## dem Tal UNTER Augenhöhe (vom Grat aus sieht man auf sie hinab), einer in
## Weghöhe neben der Wendel, einer unter dem Regal über dem Bach.
##
## KOSTEN (Plan 13: ≤ 18 Zeichenaufrufe): jedes Teil ein MultiMesh, ohne
## Schatten, mit harter Sichtweite; von einer Stelle aus sind höchstens
## zwei Schächte samt Staub, ein Laubfeld und ein, zwei Schwärme im Bild.

const STAUB := preload("res://scenes/props/Staub.tscn")
const LAUBTREIBEN := preload("res://scenes/props/Laubtreiben.tscn")
const VOEGEL := preload("res://scenes/props/Voegel.tscn")

# ================================================================ Zonen

## Die Zonen entlang des Weges (s von … bis). "nebelfarbe" und
## "umgebungsfarbe" wirken zu `FARBANTEIL`, die Faktoren ganz; "streuung"
## ist ein Faktor auf `fog_sun_scatter`.
const ZONEN := [
	{"name": "Hallenwald", "von": -40.0, "bis": 30.0, "nebel_faktor": 3.4,
			"licht_faktor": 0.85, "nebelfarbe": Color(0.19, 0.36, 0.47),
			"umgebungsfarbe": Color(0.30, 0.40, 0.36), "streuung": 0.0},
	{"name": "Hangweg", "von": 30.0, "bis": 104.0, "nebel_faktor": 0.6,
			"licht_faktor": 1.15, "nebelfarbe": Color(0.42, 0.58, 0.76),
			"umgebungsfarbe": Color(0.66, 0.62, 0.48), "streuung": 0.0},
	{"name": "Fallklamm", "von": 104.0, "bis": 160.0, "nebel_faktor": 1.0,
			"licht_faktor": 0.9, "nebelfarbe": Color(0.36, 0.52, 0.66),
			"umgebungsfarbe": Color(0.44, 0.56, 0.62), "streuung": 0.0},
	# Reicht bis ans Ende: Auf der Wendel mischt sich die Zylinderzone
	# darüber, und wer von der Wurzel auf die Wiese fällt, steht wieder hier.
	{"name": "Bachwiese", "von": 160.0, "bis": 400.0, "nebel_faktor": 1.5,
			"licht_faktor": 1.05, "nebelfarbe": Color(0.34, 0.48, 0.58),
			"umgebungsfarbe": Color(0.56, 0.60, 0.42), "streuung": 0.0, "oben": 1.3},
]

## Wendel und Kronentor: ein Zylinder um die Weltenbaumachse, gemessen an
## der Wegdecke unter der Figur. Er beginnt über der Wiese ("unten_y"), die
## Bachwiese darunter bleibt die Bachwiese.
const WENDEL := {"name": "Wendel", "achse": Vector2(72.0, -174.0), "radius": 36.0,
		"unten_y": 8.8, "hoehe": 40.0, "nebel_faktor": 0.8, "licht_faktor": 1.45,
		"nebelfarbe": Color(0.40, 0.55, 0.72), "umgebungsfarbe": Color(0.70, 0.60, 0.46),
		"streuung": 0.0, "oben": 1.5}

## Wie weit die Farben von der Grundstimmung zur Zonenfarbe gehen.
const FARBANTEIL := 1.0
## Breite der weichen Übergänge zwischen den Zonen (m Strecke).
const UEBERGANG := 8.0
## So schnell geht der Regler der Mischung nach (Anteil je Sekunde). Nur
## gegen Sprünge (Wiedereinstieg am Checkpoint); beim Laufen ändert sich
## die Mischung ohnehin weich mit der Strecke.
const NACHFUEHREN := 6.0
## Der Bachnebel ist das Nebellicht, so viel heller (wie beim Bau).
const BACHNEBEL_HELLER := 0.22

# ================================================================ Licht

## Lichtschächte in C: Fuß (s, q). Ohne "decke_y" reichen sie bis über die
## Krone der linken Wand (dort, wo die hohe Wand im Schatten steht), mit
## "decke_y" fallen sie aus den Kronen der Kanalbäume über C4, die dort das
## Dach schließen.
const SCHAECHTE_C := [
	{"s": 138.5, "q": -3.5},
	{"s": 150.5, "q": 3.4, "decke_y": 22.0},
	{"s": 157.5, "q": 2.6, "decke_y": 22.0},
]
## Talriesen: Füße der Schächte rechts auf der Wiese, Decke = Kronen.
const SCHAECHTE_D := [
	{"s": 168.5, "q": 5.2},
	{"s": 187.0, "q": 5.6},
	{"s": 196.5, "q": 3.6},
]
## Die Kronen der Talriesen beginnen so hoch (Welt-Y).
const KRONEN_D_Y := 22.0
## Das Blätterdach des Hallenwalds liegt so hoch über dem Weg.
const DACH_A := 13.0

## Laubtreiben (Plan 10).
const LAUB_STELLEN := [20.0, 50.0, 90.0, 150.0, 235.0, 260.0]

## Vogelschwärme: Mitte (s, q), Welt-Y der Flughöhe, Radius, Anzahl, hell
## (von oben gesehen vor dunklem Wald) oder dunkel (vor Himmel und Dunst).
const SCHWAERME := [
	{"s": 62.0, "q": 36.0, "y": 18.0, "radius": 14.0, "anzahl": 6, "hell": true},
	{"s": 98.0, "q": 46.0, "y": 17.0, "radius": 18.0, "anzahl": 5, "hell": true},
	{"s": 236.0, "q": 30.0, "y": 15.0, "radius": 12.0, "anzahl": 5, "hell": false},
	{"welt": Vector3(58.0, 13.5, -150.0), "radius": 10.0, "anzahl": 4, "hell": true},
]

## Harte Sichtweiten (Kamera → Knoten).
const SICHT_SCHACHT := 75.0
const SICHT_STAUB := 45.0
const SICHT_LAUB := 42.0


## Bauschritte, je {"text": String, "tun": Callable}. Laufen als letzte.
static func bauschritte(level: Level01) -> Array:
	return [
		{"text": "Licht und Nebel", "tun": func() -> void:
			_regler_anlegen(level)},
		{"text": "Sonnenstrahlen fallen durch das Laub", "tun": func() -> void:
			_schaechte_setzen(level)},
		{"text": "Laub und Vögel", "tun": func() -> void:
			_laub_setzen(level)
			_voegel_setzen(level)},
	]


# ================================================================ Regler

static func _regler_anlegen(level: Level01) -> void:
	var welt := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if welt == null or welt.environment == null:
		return
	var regler := Regler.new()
	regler.name = "Stimmungsregler"
	regler.level = level
	regler.welt = welt
	regler.bachnebel = L01Gelaende.nebel_stoff()
	regler.oben = level.get_node_or_null("Himmelslicht") as DirectionalLight3D
	level.deko.add_child(regler)


## Mischt die Zonen nach der Strecke der Figur und schreibt Nebel und
## Umgebungslicht in eine eigene Kopie der Levelumgebung.
##
## Die Umgebung der Szene ist eine Unterressource, die allen Instanzen
## gehört – sie wird deshalb einmal kopiert (wie in `Stimmungszone`).
## Bewegt keine Knoten, braucht also keine Regel für den Bildtakt.
class Regler:
	extends Node

	var level: Level01
	var welt: WorldEnvironment
	var bachnebel: ShaderMaterial
	## Das Licht von oben (Level01.tscn "Himmelslicht"), oder null.
	var oben: DirectionalLight3D
	## Die Zonen und die Wendel – als Kopie, damit ein Prüfwerkzeug sie zur
	## Laufzeit verstellen kann (`neu_rechnen`).
	var zonen: Array = []
	var wendel: Dictionary = {}
	var farbanteil := FARBANTEIL

	var _umgebung: Environment
	var _grund := {}
	var _stand := {}
	var _spieler: Node3D
	var _sofort := true

	func _ready() -> void:
		zonen = ZONEN.duplicate(true)
		wendel = WENDEL.duplicate(true)
		_umgebung = welt.environment.duplicate() as Environment
		welt.environment = _umgebung
		_grund = {
			"nebelfarbe": _umgebung.fog_light_color,
			"nebelende": _umgebung.fog_depth_end,
			"nebelbeginn": _umgebung.fog_depth_begin,
			"licht": _umgebung.ambient_light_energy,
			"umgebungsfarbe": _umgebung.ambient_light_color,
			"streuung": _umgebung.fog_sun_scatter,
			"oben": oben.light_energy if oben != null else 0.0,
		}

	## Die Grundstimmung, wie die Szene sie mitbrachte (Kopie).
	func grund() -> Dictionary:
		return _grund.duplicate()

	## Setzt eine neue Grundstimmung (für Prüfwerkzeuge) und springt hin.
	func grund_setzen(werte: Dictionary) -> void:
		_grund.merge(werte, true)
		neu_rechnen()

	## Beim nächsten Bild ohne Nachführen auf die Mischung springen.
	func neu_rechnen() -> void:
		_sofort = true

	func _process(delta: float) -> void:
		if _spieler == null or not is_instance_valid(_spieler):
			_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null or level.verlauf == null:
			return
		var ort := level.to_local(_spieler.global_position)
		var s := level.verlauf.get_closest_offset(ort)
		var ziel := mischung(s)
		var anteil := 1.0 if _sofort else clampf(delta * NACHFUEHREN, 0.0, 1.0)
		_sofort = false
		if _stand.is_empty():
			_stand = ziel
		else:
			for k: String in ziel:
				var z: Variant = ziel[k]
				if z is Color:
					_stand[k] = (_stand[k] as Color).lerp(z as Color, anteil)
				else:
					_stand[k] = lerpf(float(_stand[k]), float(z), anteil)
		_schreiben()

	## Die Werte an der Strecke `s` (ohne Nachführen).
	func mischung(s: float) -> Dictionary:
		var gewichte: Array[float] = []
		var summe := 0.0
		for z: Dictionary in zonen:
			var w := _kasten(s, float(z["von"]), float(z["bis"]))
			gewichte.append(w)
			summe += w
		var w_wendel := _zylinder(s)
		var rest := 1.0 - w_wendel
		var farbe := Color(0, 0, 0)
		var umgebung := Color(0, 0, 0)
		var ende := 0.0
		var licht := 0.0
		var streuung := 0.0
		var von_oben := 0.0
		var alle: Array[Dictionary] = []
		var anteile: Array[float] = []
		for i in zonen.size():
			if gewichte[i] <= 0.0:
				continue
			alle.append(zonen[i] as Dictionary)
			anteile.append(rest * gewichte[i] / maxf(summe, 0.0001))
		if w_wendel > 0.0:
			alle.append(wendel)
			anteile.append(w_wendel)
		var grund_farbe: Color = _grund["nebelfarbe"]
		var grund_umgebung: Color = _grund["umgebungsfarbe"]
		var beginn: float = _grund["nebelbeginn"]
		var grund_ende: float = _grund["nebelende"]
		for i in alle.size():
			var z: Dictionary = alle[i]
			var a := anteile[i]
			var zf := grund_farbe.lerp(z["nebelfarbe"] as Color, farbanteil)
			var zu := grund_umgebung.lerp(z["umgebungsfarbe"] as Color, farbanteil)
			farbe += zf * a
			umgebung += zu * a
			ende += (beginn + maxf(grund_ende - beginn, 1.0) / float(z["nebel_faktor"])) * a
			licht += float(_grund["licht"]) * float(z["licht_faktor"]) * a
			streuung += float(_grund["streuung"]) * float(z.get("streuung", 1.0)) * a
			von_oben += float(_grund["oben"]) * float(z.get("oben", 1.0)) * a
		farbe.a = 1.0
		umgebung.a = 1.0
		return {"nebelfarbe": farbe, "umgebungsfarbe": umgebung, "nebelende": ende,
				"licht": licht, "streuung": streuung, "oben": von_oben}

	## Gewicht einer Zone von … bis mit weichen Rändern.
	func _kasten(s: float, von: float, bis: float) -> float:
		var h := UEBERGANG * 0.5
		return smoothstep(von - h, von + h, s) * (1.0 - smoothstep(bis - h, bis + h, s))

	## Gewicht der Zylinderzone an der Wegdecke unter `s`.
	func _zylinder(s: float) -> float:
		var p := level.weg_punkt(s)
		var achse: Vector2 = wendel["achse"]
		var r := Vector2(p.x, p.z).distance_to(achse)
		var radius: float = wendel["radius"]
		var unten: float = wendel["unten_y"]
		var deckel := unten + float(wendel["hoehe"])
		return (1.0 - smoothstep(radius - 6.0, radius + 2.0, r)) \
				* smoothstep(unten, unten + 2.0, p.y) \
				* (1.0 - smoothstep(deckel - 2.0, deckel, p.y))

	func _schreiben() -> void:
		var farbe: Color = _stand["nebelfarbe"]
		_umgebung.fog_light_color = farbe
		_umgebung.fog_depth_end = float(_stand["nebelende"])
		_umgebung.ambient_light_energy = float(_stand["licht"])
		_umgebung.ambient_light_color = _stand["umgebungsfarbe"]
		_umgebung.fog_sun_scatter = float(_stand["streuung"])
		if oben != null:
			oben.light_energy = float(_stand["oben"])
		if bachnebel != null:
			bachnebel.set_shader_parameter("farbe", farbe.lightened(BACHNEBEL_HELLER))


# ================================================================ Licht

## Richtung, in die das Sonnenlicht fällt – aus der Sonne der Szene.
static func _lichtrichtung(level: Level01) -> Vector3:
	var sonne := level.get_node_or_null("Sonne") as DirectionalLight3D
	if sonne == null:
		return Vector3(-0.097, -0.927, -0.362)
	return -sonne.global_transform.basis.z.normalized()


static func _schaechte_setzen(level: Level01) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Lichtschaechte"
	level.deko.add_child(wurzel)
	var fall := _lichtrichtung(level)
	# Waagerechter Versatz je Meter Fallhöhe: So weit neben dem Loch im
	# Dach trifft der Strahl auf.
	var versatz := Vector3(fall.x, 0.0, fall.z) / maxf(-fall.y, 0.1)

	# A: durch die Löcher im Blätterdach.
	for loch: Dictionary in Level01.LICHTLOECHER:
		var s: float = loch["s"]
		var oben := level.weg_punkt(s, float(loch["q"]), DACH_A)
		var fuss := oben + versatz * DACH_A
		fuss.y = level.weg_punkt(level.verlauf.get_closest_offset(fuss)).y - 0.3
		_schacht(wurzel, fuss, fall, oben.y + 0.5, 18.0, 5, 0.15, 1.3, int(s * 10.0))
		_staub(wurzel, fuss, Vector3(4.5, DACH_A - 1.0, 4.5), 60, int(s * 10.0) + 1)

	# C: an der linken Wand, bis über ihre Krone.
	for e: Dictionary in SCHAECHTE_C:
		var s: float = e["s"]
		var fuss := level.weg_punkt(s, float(e["q"]), -0.3)
		var krone := float(e.get("decke_y", NAN))
		if is_nan(krone):
			krone = float(level.rand_profil(s, -1.0)["krone_y"]) + 1.0
		if is_nan(krone):
			krone = fuss.y + 9.0
		_schacht(wurzel, fuss, fall, krone, 18.0, 4, 0.1, 1.2, int(s * 10.0))
		_staub(wurzel, fuss, Vector3(4.0, minf(krone - fuss.y, 10.0), 4.0), 50,
				int(s * 10.0) + 1)

	# D: aus den Kronen der Talriesen.
	for e: Dictionary in SCHAECHTE_D:
		var s: float = e["s"]
		var fuss := level.weg_punkt(s, float(e["q"]), -0.3)
		_schacht(wurzel, fuss, fall, KRONEN_D_Y, 18.0, 4, 0.08, 1.6, int(s * 10.0))
		_staub(wurzel, fuss, Vector3(5.0, 9.0, 5.0), 60, int(s * 10.0) + 1)


static func _schacht(eltern: Node3D, fuss: Vector3, fall: Vector3, decke: float,
		laenge: float, anzahl: int, staerke: float, streuung: float, saat: int) -> void:
	var schacht := Lichtschacht.new()
	schacht.name = "Schacht"
	schacht.richtung = fall
	schacht.laenge = laenge
	schacht.breite = 2.0
	schacht.anzahl = anzahl
	schacht.streuung = streuung
	schacht.staerke = staerke
	schacht.saat = saat
	schacht.decke = decke
	schacht.position = fuss
	schacht.visibility_range_end = SICHT_SCHACHT
	eltern.add_child(schacht)


static func _staub(eltern: Node3D, fuss: Vector3, raum: Vector3, anzahl: int,
		saat: int) -> void:
	var staub := STAUB.instantiate() as Staubflug
	staub.name = "Staub"
	staub.raum = raum
	staub.anzahl = maxi(anzahl >> 1, 1) if Effekte.reduziert else anzahl
	staub.saat = saat
	staub.position = fuss
	staub.visibility_range_end = SICHT_STAUB
	eltern.add_child(staub)


# ================================================================ Bewegung

static func _laub_setzen(level: Level01) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Laubtreiben"
	level.deko.add_child(wurzel)
	for s: float in LAUB_STELLEN:
		var laub := LAUBTREIBEN.instantiate() as Laubtreiben
		laub.name = "Laub"
		laub.flaeche = Vector2(maxf(level.breite_bei(s), 6.0) + 4.0, 14.0)
		laub.hoehe = 1.8
		laub.anzahl = 16 if Effekte.reduziert else 30
		laub.saat = int(s) + 4000
		# Schräg über den Weg zur Talseite: nach der Drehung zeigt -Z den
		# Weg entlang, +X nach rechts.
		laub.windrichtung = Vector3(0.45, 0.0, 0.9).normalized()
		laub.position = level.weg_punkt(s, 0.0, 0.15)
		laub.rotation.y = LevelWerkzeuge.drehung(level.verlauf, s)
		laub.visibility_range_end = SICHT_LAUB
		wurzel.add_child(laub)


static func _voegel_setzen(level: Level01) -> void:
	var wurzel := Node3D.new()
	wurzel.name = "Voegel"
	level.deko.add_child(wurzel)
	var i := 0
	for e: Dictionary in SCHWAERME:
		var mitte: Vector3
		if e.has("welt"):
			mitte = e["welt"]
		else:
			mitte = LevelWerkzeuge.punkt(level.verlauf, float(e["s"]), float(e["q"]))
			mitte.y = float(e["y"])
		var schwarm := VOEGEL.instantiate() as Vogelschwarm
		schwarm.name = "Schwarm"
		schwarm.anzahl = int(e["anzahl"])
		# Der Schwarm fliegt mindestens 8 m über seinem Knoten.
		schwarm.hoehe = 9.0
		schwarm.hoehen_streuung = 2.5
		schwarm.radius = float(e["radius"])
		schwarm.spannweite = 1.3
		schwarm.linksherum = i % 2 == 0
		schwarm.umdrehungen_je_minute = 1.6
		schwarm.saat = 7100 + i
		if bool(e["hell"]):
			schwarm.farbe = Color(0.80, 0.78, 0.72)
		schwarm.position = mitte - Vector3.UP * 9.0
		wurzel.add_child(schwarm)
		i += 1
