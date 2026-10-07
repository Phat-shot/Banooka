extends RefCounted
class_name L01Stimmung
## Level 01, Modul „Stimmung": Licht, Nebel, Lichtschächte und Bewegung
## (Plan Abschnitt 10).
##
## LUFTPERSPEKTIVE. Nahes ist warm, Fernes kühl: Sonne und warmes
## Umgebungslicht malen den Weg und die ersten Meter, der Tiefennebel (ab
## 12 m) zieht alles Ferne in einen kühlen, blauen Dunst. Er trägt das Bild:
## Aus ihm kommt die Tiefe (drei Staffeln – sattes Grün nah, Blaugrün im
## Mittelgrund, blaue Silhouetten in der Ferne), der kühle Anteil jedes
## Bildes, und er hält das Ferne DUNKLER als den Weg (Lesbarkeitsvertrag).
## Vorher lag über allem ein grüngrauer Dunst, den das Streulicht des
## Gegenlichts aus Norden noch gelblich färbte: Die Ferne war heller als der
## Weg und flach, kühl waren 0–5 % des Bildes. Deshalb gibt es in Level 01
## kein Streulicht mehr (`fog_sun_scatter` 0 in Level01.tscn) – der Blick
## geht auf dem Grat genau in das Gegenlicht. Auch im Schlussbild nicht (Plan
## 5F wollte dort leuchtenden Dunst): Die Sonne steht 68° hoch im SSO, der
## Blick geht nach SW leicht abwärts – rund 90° zur Sonne, wo das Streulicht
## (hoch 8 des Kosinus) nichts mehr beiträgt. Golden wird das Ziel durch
## die Sonne selbst: In der Wendel ist sie warm (1,0/0,84/0,60) und 15 %
## stärker, und ein Lichtschacht fällt neben dem Portal aufs Regal.
##
## STIMMUNG ENTLANG DES WEGES (`Regler`). Jeder Abschnitt hat sein Licht,
## gerechnet wie bei `Stimmungszone` (`nebel_faktor` verkürzt die
## Nebelstrecke 12 → 140 m der Szene, `licht_faktor` skaliert das
## Umgebungslicht, "oben" das Himmelslicht der Szene):
##   A Hallenwald   dichter blaugrüner Dunst zwischen den Stämmen (Ende 50 m),
##                  gedämpftes Licht; tritt man hinaus, hebt sich der Dunst
##   B Hangweg      warmes Licht, blaue Ferne bis 225 m – der Weltenbaum
##                  steht als dunkle Silhouette vor dem Dunst (s 31, s 60)
##   C Fallklamm    kühl
##   D Bachwiese    warm grün, blaugrauer Dunst hinter den Riesen
##   E/F Wendel     golden nah, blau fern – EINE Zone als Zylinder um die
##                  Weltenbaumachse (ab der Wurzel, nicht schon auf der
##                  Wiese darunter)
## Die Werte hängen nicht an Auslösekästen mit einer Überblendung über die
## Zeit (`Stimmungszone`), sondern an der Stelle: Der Regler rechnet jedes
## Bild aus der Strecke der Figur die Mischung der Zonen (weiche Übergänge
## über `UEBERGANG` m, an der Enthüllung 18 m) und geht ihr mit einer
## Zeitkonstante von einer Sechstelsekunde nach (unabhängig von der
## Bildrate). Steht die Figur, schreibt er nichts.
## So sieht jede Stelle immer gleich aus – im Spiel wie auf dem Foto, das
## nach 0,8 s Wartezeit sonst eine halbe Überblendung von der vorigen
## Aufnahmestelle zeigte –, und die Zonen der Wendel überlagern sich nicht
## mit denen der Wiese, über der sie sich windet. Der Bachnebel des
## Geländes (`L01Gelaende.nebel_stoff`) folgt der Nebelfarbe.
##
## HIMMEL (Level01.tscn): tieferes Blau, Dunstband in der Nebelfarbe von B,
## Wolken, die zum Horizont hin im Dunst vergehen (`wolken_dunst`) – sonst
## waren tiefe Wolken die hellsten Flecken im Bild.
##
## LICHTSCHÄCHTE (`Lichtschacht`, je mit `Staubflug`): in A durch die zwei
## Löcher im Blätterdach (`Level01.LICHTLOECHER`, Decke = Dach), in C an
## der hohen Wand bis über ihre Krone und aus den Kanalbäumen über C4, in D
## aus den Kronen der Talriesen. Die Bahnen folgen der Sonne der Szene.
##
## BEWEGUNG: Laubtreiben an sechs Stellen, vier Vogelschwärme – zwei helle
## über dem Tal UNTER Augenhöhe (vom Grat aus sieht man auf sie hinab), ein
## dunkler in Augenhöhe neben der Wendel, einer vor dem Schlussbild.
##
## FARBZIELE (Plan 10), gemessen im Schaufenster (l01, 30.09.2026) mit
## `kontaktbogen.py` (hell, warm, kühl) und einer Wegmaske: „Weg" = P80 der
## Helligkeit der sichtbaren Wegdecke, „hellste" = hellste Fläche aus 8 × 5
## außerhalb von Weg und Spielobjekten, „dunkel" = Anteil unter Luma 60 und
## Klasse der größten zusammenhängenden Fläche:
##     s    kühl %  warm %  Weg  hellste  dunkel  größte Fläche
##     4    12,5    18,8    155   101      74 %    dunkel
##    31    25,6    21,0    183   127      50 %    dunkel
##    46    22,1    19,7    188   143      48 %    dunkel
##    70    13,3    21,6    190   110      60 %    dunkel
##   101    10,5    22,6    187    87      65 %    dunkel
##   119    31,0     9,0    174   102      54 %    dunkel
##   140    11,7    21,2    171   138      70 %    dunkel
##   176    16,7    14,2    164   111      61 %    dunkel
##   212    24,7    20,0    148   142      58 %    dunkel
##   249    27,0    23,1    164   128      56 %    dunkel
##   275,5  17,9    18,5     95    89      71 %    dunkel
## Vorher (gleiche Stationen): kühl 0,0–5,0 %, Ferne und Himmel bis 206
## hell gegen einen Weg von 114–170. Knapp sind 212 (Weg aus Borke gegen
## den Himmel) und 275,5: Dort liegt das Regal im Schatten der Äste des
## Weltenbaums (Schattenkörper "StammSchatten"); ohne ihn misst der Weg gut
## 130 statt 95. Die Seitenansichten erfüllen kühl und warm (s 60: 15,5 /
## 11,4 %, s 186: 18,8 / 8,1 %); bei s 186 ist die besonnte Wiese die
## größte Fläche, bei der Nahaufnahme s 53,5 (Rasen und Lippe) ist kaum
## Ferne im Bild (kühl 1,1 %).
##
## KOSTEN (Plan 13: ≤ 18 Zeichenaufrufe): jedes Teil ein MultiMesh, ohne
## Schatten, mit harter Sichtweite. Gemessen je Station +4 (Wendel) bis +17
## (s 140: sechs Schächte, drei Staubsäulen, Laub, ein Schwarm).

const STAUB := preload("res://scenes/props/Staub.tscn")
const LAUBTREIBEN := preload("res://scenes/props/Laubtreiben.tscn")
const VOEGEL := preload("res://scenes/props/Voegel.tscn")

# ================================================================ Zonen

## Die Zonen entlang des Weges (s von … bis). "nebelfarbe" und
## "umgebungsfarbe" wirken zu `FARBANTEIL`, die Faktoren ganz; "oben" ist
## ein Faktor auf das Himmelslicht der Szene (Licht von oben, hebt den Weg
## gegen Himmel und Dunst, ohne die Schattenseiten aufzuhellen). Freiwillig:
##   "kurve"        `fog_depth_curve` (sonst die der Szene, 1,1)
##   "sonne_farbe", "sonne_faktor"  Farbe und Stärke der Sonne (Faktor auf
##                  die der Szene; die Schattenkarten bleiben, wie sie sind)
##   "rand_von", "rand_bis"  Breite des weichen Übergangs am Anfang bzw.
##                  Ende (m Strecke, sonst `UEBERGANG`); zwei Zonen, die
##                  aneinanderstoßen, tragen an der Naht dieselbe Breite.
##
## Die Enthüllung (A → B, Naht bei s 27) läuft über 18 m: Mit 8 m wich die
## Nebelwand (Ende 50 → 225 m) in gut einer Sekunde Lauf zurück – im Lauf
## ein Ruck statt eines Heraustretens aus dem Wald –, und bei s 24, wo der
## Plan Wasserfall und Weltenbaum schon in der Öffnung zeigt, reichte der
## Dunst erst 50 m weit. Jetzt sind es dort gut 95 m.
##
## B trägt die steilere Nebelkurve (1,5): Der Talwald in 40–80 m behält
## sein Grün (Nebel bei 60 m gut 4 statt 10 %), die Ferne bleibt blau – so
## stehen drei Staffeln im Bild statt eines blauen Filters über der
## rechten Hälfte. Die Nebelfarbe von B ist dafür etwas weniger satt. Mit
## 1,6 und der harten Naht bei 104 fiel die Pforte (s 101) auf 9 % kühl
## (Ziel ≥ 10 %); die Fallklamm setzt deshalb schon ab s 98 ein (12 m).
const ZONEN := [
	{"name": "Hallenwald", "von": -40.0, "bis": 27.0, "rand_bis": 18.0, "nebel_faktor": 3.4,
			"licht_faktor": 0.85, "nebelfarbe": Color(0.19, 0.36, 0.47),
			"umgebungsfarbe": Color(0.30, 0.40, 0.36)},
	{"name": "Hangweg", "von": 27.0, "bis": 104.0, "rand_von": 18.0, "rand_bis": 12.0,
			"nebel_faktor": 0.6, "licht_faktor": 1.4, "nebelfarbe": Color(0.46, 0.60, 0.74),
			"umgebungsfarbe": Color(0.66, 0.62, 0.48), "oben": 1.25, "kurve": 1.5},
	{"name": "Fallklamm", "von": 104.0, "bis": 160.0, "rand_von": 12.0, "nebel_faktor": 1.0,
			"licht_faktor": 0.9, "nebelfarbe": Color(0.36, 0.52, 0.66),
			"umgebungsfarbe": Color(0.44, 0.56, 0.62)},
	# Reicht bis ans Ende: Auf der Wendel mischt sich die Zylinderzone
	# darüber, und wer von der Wurzel auf die Wiese fällt, steht wieder hier.
	{"name": "Bachwiese", "von": 160.0, "bis": 400.0, "nebel_faktor": 1.5,
			"licht_faktor": 1.05, "nebelfarbe": Color(0.34, 0.48, 0.58),
			"umgebungsfarbe": Color(0.56, 0.60, 0.42), "oben": 1.3},
]

## Wendel und Kronentor: ein Zylinder um die Weltenbaumachse, gemessen an
## der Wegdecke unter der Figur. Er beginnt über der Wiese ("unten_y"), die
## Bachwiese darunter bleibt die Bachwiese. Die Sonne ist hier golden
## (Plan 4/5F: „golden nah, blau fern") – warmes Streiflicht auf Borke und
## Regal, gegen den blauen Taldunst des Schlussbilds.
const WENDEL := {"name": "Wendel", "achse": Vector2(72.0, -174.0), "radius": 36.0,
		"unten_y": 8.8, "hoehe": 40.0, "nebel_faktor": 0.8, "licht_faktor": 1.55,
		"nebelfarbe": Color(0.40, 0.55, 0.72), "umgebungsfarbe": Color(0.70, 0.60, 0.46),
		"oben": 1.7, "sonne_farbe": Color(1.0, 0.84, 0.60), "sonne_faktor": 1.15}

## Wie weit die Farben von der Grundstimmung zur Zonenfarbe gehen. Der Plan
## nannte ≈ 0,6; hier gelten die Zonenfarben ganz – die Farbe der Szene ist
## nur noch die des Himmelsdunsts (= Hangweg), und jede Zone ist auf ihre
## Farbziele gestimmt, nicht auf einen Abstand zur Grundfarbe.
const FARBANTEIL := 1.0
## Breite der weichen Übergänge zwischen den Zonen (m Strecke), wo eine
## Zone nichts anderes sagt.
const UEBERGANG := 8.0
## So schnell geht der Regler der Mischung nach (Zeitkonstante 1/6 s,
## unabhängig von der Bildrate). Nur gegen Sprünge (Wiedereinstieg am
## Checkpoint); beim Laufen ändert sich die Mischung ohnehin weich mit der
## Strecke.
const NACHFUEHREN := 6.0
## Der Bachnebel ist das Nebellicht, so viel heller (wie beim Bau).
const BACHNEBEL_HELLER := 0.22
## Unter diesen Änderungen schreibt der Regler nichts (Farbanteile, Meter
## bzw. Faktoren) – ein stehendes Bild kostet ihn nichts.
const SCHWELLE := 0.001
## So weit (m Strecke) muss sich die Figur bewegen, damit er neu mischt.
const SCHWELLE_S := 0.02


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
## Kronentor (F): ein Schacht neben dem Zielportal, durch eine Lücke im
## Kronenvorhang des Südwestasts (Decke = Unterseite der Krone). Er fällt
## auf das Regal und steht vor der dunklen Krone – der Lohn am Ende, und
## das Hellste im Schlussbild neben dem Portal.
const SCHAECHTE_F := [
	{"s": 280.8, "q": 2.6, "decke_y": 33.5},
]
## Das Blätterdach des Hallenwalds liegt so hoch über dem Weg.
const DACH_A := 13.0

## Laubtreiben (Plan 10).
const LAUB_STELLEN := [20.0, 50.0, 90.0, 150.0, 235.0, 260.0]

## Vogelschwärme: Mitte (s, q), Welt-Y der Flughöhe, Radius, Anzahl, hell
## (von oben gesehen vor dunklem Wald) oder dunkel (vor Himmel und Dunst).
const SCHWAERME := [
	{"s": 62.0, "q": 36.0, "y": 18.0, "radius": 14.0, "anzahl": 6, "hell": true},
	{"s": 98.0, "q": 46.0, "y": 17.0, "radius": 18.0, "anzahl": 5, "hell": true},
	{"s": 254.0, "q": 26.0, "y": 17.5, "radius": 11.0, "anzahl": 5, "hell": false},
	# Vor dem Schlussbild (Blick nach SSW auf Grat und Wasserfall), knapp
	# über dem Talwald westlich des Knolls: Tiefer verschwänden die Vögel
	# zwischen den Kronen.
	{"welt": Vector3(33.0, 23.0, -163.0), "radius": 7.0, "anzahl": 4, "hell": true},
]

## Harte Sichtweiten (Kamera → Knoten).
const SICHT_SCHACHT := 75.0
const SICHT_STAUB := 35.0
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
	regler.sonne = level.get_node_or_null("Sonne") as DirectionalLight3D
	regler.nebelstoffe = L01Weltenbaum.nebel_stoffe().duplicate()
	level.deko.add_child(regler)


## Mischt die Zonen nach der Strecke der Figur und schreibt Nebel,
## Umgebungslicht und Sonne in eine eigene Kopie der Levelumgebung.
##
## Die Umgebung der Szene ist eine Unterressource, die allen Instanzen
## gehört – sie wird deshalb einmal kopiert (wie in `Stimmungszone`). Die
## Stoffe, in die er sonst schreibt (Bachnebel, Weltenbaum-Nebel), baut das
## Level je Aufbau selbst; geteilte, zwischengespeicherte Stoffe fasst er
## nicht an. Bewegt keine Knoten, braucht also keine Regel für den
## Bildtakt.
##
## Kosten: Steht die Figur (weniger als `SCHWELLE_S` m seit dem letzten
## Mischen) und ist der Stand eingeschwungen, kehrt er sofort zurück.
## Geschrieben wird nur, was sich um mehr als `SCHWELLE` geändert hat – im
## Web und auf dem Handy kostet jeder Schreibzugriff einen Weg zum Renderer
## und jeder Stoffparameter ein neues Hochladen des Stoffpuffers.
class Regler:
	extends Node

	var level: Level01
	var welt: WorldEnvironment
	var bachnebel: ShaderMaterial
	## Das Licht von oben (Level01.tscn "Himmelslicht"), oder null.
	var oben: DirectionalLight3D
	## Die Sonne (Level01.tscn "Sonne"), oder null.
	var sonne: DirectionalLight3D
	## Stoffe mit eigenem Nebel (Uniforms "nebel_*"), je Aufbau gebaut.
	var nebelstoffe: Array[ShaderMaterial] = []
	## Die Zonen und die Wendel – als Kopie, damit ein Prüfwerkzeug sie zur
	## Laufzeit verstellen kann (`neu_rechnen`).
	var zonen: Array = []
	var wendel: Dictionary = {}
	var farbanteil := FARBANTEIL

	var _umgebung: Environment
	var _grund := {}
	var _stand := {}
	var _ziel := {}
	var _geschrieben := {}
	var _spieler: Node3D
	var _sofort := true
	var _s_alt := INF
	var _ruhig := false

	func _ready() -> void:
		zonen = ZONEN.duplicate(true)
		wendel = WENDEL.duplicate(true)
		_umgebung = welt.environment.duplicate() as Environment
		welt.environment = _umgebung
		_grund = {
			"nebelfarbe": _umgebung.fog_light_color,
			"nebelende": _umgebung.fog_depth_end,
			"nebelbeginn": _umgebung.fog_depth_begin,
			"kurve": _umgebung.fog_depth_curve,
			"licht": _umgebung.ambient_light_energy,
			"umgebungsfarbe": _umgebung.ambient_light_color,
			"oben": oben.light_energy if oben != null else 0.0,
			"sonne": sonne.light_energy if sonne != null else 0.0,
			"sonne_farbe": sonne.light_color if sonne != null else Color.WHITE,
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
		_s_alt = INF

	func _process(delta: float) -> void:
		if _spieler == null or not is_instance_valid(_spieler):
			_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler == null or level.verlauf == null:
			return
		var ort := level.to_local(_spieler.global_position)
		var s := level.verlauf.get_closest_offset(ort)
		var bewegt := absf(s - _s_alt) >= SCHWELLE_S
		if not bewegt and not _sofort and _ruhig:
			return
		if bewegt or _sofort or _ziel.is_empty():
			_ziel = mischung(s)
			_s_alt = s
		var anteil := 1.0 if _sofort else 1.0 - exp(-NACHFUEHREN * delta)
		_sofort = false
		if _stand.is_empty():
			_stand = _ziel.duplicate()
		else:
			for k: String in _ziel:
				var z: Variant = _ziel[k]
				if z is Color:
					_stand[k] = (_stand[k] as Color).lerp(z as Color, anteil)
				else:
					_stand[k] = lerpf(float(_stand[k]), float(z), anteil)
		_ruhig = _abstand(_stand, _ziel) < SCHWELLE
		if _ruhig:
			_stand = _ziel.duplicate()
		_schreiben()

	## Die Werte an der Strecke `s` (ohne Nachführen).
	func mischung(s: float) -> Dictionary:
		var summe := 0.0
		for z: Dictionary in zonen:
			summe += _kasten(s, z)
		var w_wendel := _zylinder(s)
		var rest := (1.0 - w_wendel) / maxf(summe, 0.0001)
		var farbe := Color(0, 0, 0)
		var umgebung := Color(0, 0, 0)
		var sonnenfarbe := Color(0, 0, 0)
		var ende := 0.0
		var kurve := 0.0
		var licht := 0.0
		var von_oben := 0.0
		var sonnenlicht := 0.0
		var grund_farbe: Color = _grund["nebelfarbe"]
		var grund_umgebung: Color = _grund["umgebungsfarbe"]
		var grund_sonne: Color = _grund["sonne_farbe"]
		var beginn: float = _grund["nebelbeginn"]
		var strecke := maxf(float(_grund["nebelende"]) - beginn, 1.0)
		for i in zonen.size() + 1:
			var z: Dictionary = wendel if i == zonen.size() else zonen[i]
			var a := w_wendel if i == zonen.size() else _kasten(s, z) * rest
			if a <= 0.0:
				continue
			farbe += grund_farbe.lerp(z["nebelfarbe"] as Color, farbanteil) * a
			umgebung += grund_umgebung.lerp(z["umgebungsfarbe"] as Color, farbanteil) * a
			sonnenfarbe += (z.get("sonne_farbe", grund_sonne) as Color) * a
			ende += (beginn + strecke / float(z["nebel_faktor"])) * a
			kurve += float(z.get("kurve", _grund["kurve"])) * a
			licht += float(_grund["licht"]) * float(z["licht_faktor"]) * a
			von_oben += float(_grund["oben"]) * float(z.get("oben", 1.0)) * a
			sonnenlicht += float(_grund["sonne"]) * float(z.get("sonne_faktor", 1.0)) * a
		farbe.a = 1.0
		umgebung.a = 1.0
		sonnenfarbe.a = 1.0
		return {"nebelfarbe": farbe, "umgebungsfarbe": umgebung, "nebelende": ende,
				"kurve": kurve, "licht": licht, "oben": von_oben, "sonne": sonnenlicht,
				"sonne_farbe": sonnenfarbe}

	## Gewicht einer Zone mit weichen Rändern ("rand_von"/"rand_bis").
	func _kasten(s: float, z: Dictionary) -> float:
		var von: float = z["von"]
		var bis: float = z["bis"]
		var hv := float(z.get("rand_von", UEBERGANG)) * 0.5
		var hb := float(z.get("rand_bis", UEBERGANG)) * 0.5
		return smoothstep(von - hv, von + hv, s) * (1.0 - smoothstep(bis - hb, bis + hb, s))

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

	## Größter Unterschied zweier Stände (Farben je Kanal, Nebelende in
	## Hundertsteln seiner Länge, sonst der Wert).
	func _abstand(a: Dictionary, b: Dictionary) -> float:
		var d := 0.0
		for k: String in b:
			d = maxf(d, _unterschied(k, a.get(k), b[k]))
		return d

	func _unterschied(k: String, a: Variant, b: Variant) -> float:
		if a == null:
			return INF
		if b is Color:
			var ca := a as Color
			var cb := b as Color
			return maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b))
		if k == "nebelende":
			return absf(float(a) - float(b)) * 0.01
		return absf(float(a) - float(b))

	## Hat sich `k` seit dem letzten Schreiben merklich geändert? Merkt sich
	## den neuen Wert, wenn ja.
	func _neu(k: String) -> bool:
		var wert: Variant = _stand[k]
		if _unterschied(k, _geschrieben.get(k), wert) < SCHWELLE:
			return false
		_geschrieben[k] = wert
		return true

	func _schreiben() -> void:
		var farbe: Color = _stand["nebelfarbe"]
		var nebel_neu := false
		if _neu("nebelfarbe"):
			_umgebung.fog_light_color = farbe
			if bachnebel != null:
				bachnebel.set_shader_parameter("farbe", farbe.lightened(BACHNEBEL_HELLER))
			nebel_neu = true
		if _neu("nebelende"):
			_umgebung.fog_depth_end = float(_stand["nebelende"])
			nebel_neu = true
		if _neu("kurve"):
			_umgebung.fog_depth_curve = float(_stand["kurve"])
			nebel_neu = true
		if _neu("licht"):
			_umgebung.ambient_light_energy = float(_stand["licht"])
		if _neu("umgebungsfarbe"):
			_umgebung.ambient_light_color = _stand["umgebungsfarbe"]
		if oben != null and _neu("oben"):
			oben.light_energy = float(_stand["oben"])
		if sonne != null:
			if _neu("sonne"):
				sonne.light_energy = float(_stand["sonne"])
			if _neu("sonne_farbe"):
				sonne.light_color = _stand["sonne_farbe"]
		if nebel_neu:
			for stoff in nebelstoffe:
				L01Weltenbaum.nebel_setzen(stoff, _umgebung)


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

	# F: durch den Kronenvorhang aufs Regal.
	for e: Dictionary in SCHAECHTE_F:
		var s: float = e["s"]
		var fuss := level.weg_punkt(s, float(e["q"]), -0.3)
		_schacht(wurzel, fuss, fall, float(e["decke_y"]), 16.0, 5, 0.12, 1.4, int(s * 10.0))
		_staub(wurzel, fuss, Vector3(4.5, 8.0, 4.5), 60, int(s * 10.0) + 1)


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
		laub.anzahl = 16 if Effekte.reduziert else 32
		laub.groesse = 0.19
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
