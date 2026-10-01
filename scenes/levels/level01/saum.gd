extends RefCounted
class_name L01Saum
## Level 01, Modul „Saum": Kanten und Felswände (Plan Abschnitt 8.3).
##
## Alle Ränder des Weges von A bis D als modellierte Profile – kein Würfel,
## kein Bordstein. Gebaut mit `GelaendeSaum` (scripts/gelaende_saum.gd), ein
## Stoff für alles (`shaders/fels_schichten.gdshader`).
##
## RECHTS (offen): eine durchgehende Felskante von der Enthüllung bis zum
## Ende der Fallklamm, dann das Ufer über dem Kanal.
##   Lippe      = Kollisionskante (`rand_profil(s, 1).abstand` samt der
##                Vorsprünge 62/75/89). Darauf eine GRASNARBE: bündig mit der
##                Decke, 0,1–0,33 m Überhang (1D-Rauschen, nur nach außen),
##                vorn Erde, unten fast schwarz; darunter hängen Wurzel- und
##                Halmkarten.
##   Überhang   Die oberen gut sechs Meter liegen UNTER der Lippe (0,45 bis
##                0,85 m zurück, Rauschen nur nach innen): Eine Figur, die
##                über die Kante fällt, fällt an der Wand vorbei, nie in sie
##                hinein; und von oben liest sich die Kante als dunkler Spalt
##                unter hellem Rasen.
##   Schichtfels 70–85° darunter, alle 4–6 m ein Sims (Moos), der auf 3–8 m
##                auftaucht und wieder verschwindet – durchlaufende Simse
##                machten aus der Wand eine Torte. Alle 7–12 m eine
##                senkrechte Kluft (`_kluft`), die die Simse abschneidet;
##                dazwischen treten Pfeiler vor (erst unter dem Überhang).
##                Rinnen aus 3D-Rauschen, Schollen aus Zellrauschen,
##                Schichtbänkchen, die mit den Farbbändern des Stoffs
##                übereinanderliegen.
##   Felsnadeln Wo ein Rahmenbaum unter der Kante steht (`RAHMENBAUM_STELLEN`
##                "sims", dazu unter dem Felsfuß des Torbaums), steht eine
##                Nadel FREI vor der Wand, oben flach auf der Fußhöhe des
##                Baums, unten an die Wand gelehnt. Ein Sims, der so weit
##                hinausträte, läge unter der Lippe, und eine fallende Figur
##                fiele sichtbar durch ihn hindurch.
##   Platten    s 33–51: Unter dem Felsrand des Geländers und der Kanzel
##                (Wegbauten) beginnt die Wand erst unter der Platte.
##   Ufer       C4 (146,5–163): Erdufer mit Moos und Steinen bis auf den
##                Kanal, oben 45°, dann steiler; erst hinter der Stufe 145
##                (über ihr gemischt stand eine Scheibe quer zum Weg). An der
##                Stufe ist die Lippe gerundet, davor steht eine Felsnadel
##                mit runder Kuppe und Brocken im Wasser (`_eckfelsen`).
##   Kerben     Kerbe und Fallkerbe münden als Kerbtal in der Wand: zu den
##                Rändern der Lücke weniger tief, draußen steigt der Grund;
##                an den äußeren Ecken kantige Brocken halb in der Lippe.
##   Enden      Vor s 33 biegt die Kante vom Weg weg und läuft um die Ecke
##                der Hochfläche; hinter C4 läuft das Ufer an der Kante der
##                Bachwiese weiter und taucht bis 163 unter die Wiese, die
##                das Gelände dort anhebt (früher bog es bei 160 recht-
##                winklig nach außen und stand als Erdwand quer im Bild).
##
## LINKS (zu): die Böschung des Hangwegs (Erdhang, am steilsten gut 50°, mit
## Rasen, Erdflecken und halb versenkten Steinen; sie wächst hinter dem
## Erdspalt aus dem Waldboden), die Nische der Moosbank nach der Leitlinien-
## Polylinie (dort liegen alle Profilpunkte in der Querebene des Weges, sonst
## faltete sich das Gitter in ihren hohlen Ecken), dann die Felsnase und die
## wachsende Schichtfelswand der Fallklamm (2 → 14 m, Simse erst ab 5,5 m
## Wandhöhe, Überhang nur ab 10 m über dem Weg, Klüfte wie rechts). Die
## Kronenhöhe aus RAENDER wird über ±6 m gemittelt (sie springt an den
## Grenzen der Einträge) und folgt der glatten Kurve, nicht den Terrassen
## der Decke; an der Böschung wogt sie um ±1,6 m, deren Breite um ±22 %,
## und alle 15–25 m tritt ein Sporn vor oder weicht eine Rinne zurück. In
## der Krone der Fallklamm liegt eine Scharte (`SCHARTE`, s 124–140, bis
## 2,9 m tief): Durch sie blickt das Schlussbild auf den Grat. Bei 112–122
## weicht die Wand für das Felsbecken zurück; dort steht der Wasserfall-
## pfeiler (+11 m, dahinter fällt die Krone wieder ab: ein Felsturm), vor
## dem Becken ein niedriger Felssims auf Deckenhöhe. Bewuchs:
## `Schluchtsaum.bauen` aus den `kronen`-Einträgen, die das Profil liefert,
## auf einer Kurve durch die Decke (`_deckenkurve`), ohne Blattballen;
## Böschung und Felswand je eigener Aufruf mit eigenen Dichten.
##
## QUER: Stirnflächen der Lücken (Erdspalt, Kerbe, Fallkerbe) samt Boden,
## die Stufen 66/133/145, die Ufer der Furt; ihre Grasnarbe tritt in Buckeln
## von 2–3 m 0,15–0,35 m vor (keine Lineal-Kante). Der Erdspalt läuft je
## Seite fünf Meter in den Waldboden und wird dabei schmaler und flacher. In
## den Lücken ist auch der Saum der Seiten ausgeschnitten: rechts als
## Kerbtal (siehe oben), links als Rinne, die als V die Böschung hinauf-
## läuft; in der Fallkerbe läuft das Becken aus. Die Ufer der Furt: Soden-
## schnitt, Erdufer unter 40°, Kiesterrasse an der Wasserlinie; außerhalb
## der Decke biegt die Uferlinie zum Wasser hin aus, ihre Enden tauchen bis
## |q| 10,6 in das Bachufer (`furt_linie`, `furt_kante`, `furt_hoehe` für
## das Gelände); Steine in Gruppen, kantig, halb versenkt.
##
## NÄHTE: Rasen, der an die Decke stößt, liegt 1,5 cm unter ihr und trägt
## ihre Farbe (Include `wald_gemeinsam`, Verdeckung 0,78 wie ihr Rand) – so
## verschwindet die Naht, und gleiche Flächen anderer Module (Nischenboden,
## Kanzel) flackern nicht. Zum Gelände (`L01Gelaende`):
##   FELS_AB    die Wand reicht drei Meter unter "fuss_y"; das Feld liegt
##              darunter.
##   Ecke       um die Ecke der Hochfläche (vor s 33) reicht die Narbe 1,8 m
##              nach innen unter den Waldboden; das Feld bricht 1,35 m
##              hinter der Lippe steil ab, hinter der Wand.
##   BOESCHUNG/FELS_AUF  die Krone läuft 7,5 m hinter die Kronenkante flach
##              aus (0,6–1,1 m ansteigend). Das Feld liest die Querschnitte
##              (`querschnitte_links()`), bleibt unter Hang, Wand, Becken und
##              Krone und deckt deren Ende zu.
##   Furt       unter der Wasserlinie taucht das Ufer unter das Bachbett des
##              Feldes; darüber bleibt das Feld unter ihm.
## Die wirkliche Lippe und die wirklichen Flächen liefern `lippe_q()`,
## `querschnitte_links()` und `GelaendeSaum.flaeche_punkt()`.
##
## KAMERA (Plan K1): Nichts vom Saum hängt unter 8,8 m über den Weg. Die
## Wände stehen neben ihm; der Überhang der Fallklamm tritt erst ab 10 m
## über dem Weg vor, und die Innenkanten der `kronen`-Einträge liegen nie
## näher als 0,75 m an der Wegkante – von einem Überhang hinge eine Ranke
## sonst frei über dem Weg herab.
##
## KOLLISION baut der Saum keine.
##
## KOSTEN (Plan 13: ≤ 30 Zeichenaufrufe, ≤ 50k Dreiecke je Station, keine
## Schatten): Je 30-m-Stück rechts EIN Netz für Felskante, Stirnflächen der
## Lücken und Stufen, Ufer, Steine, Nadeln und die Böden der Vorsprünge (ein
## Stoff), dazu ein Kartennetz (bis `SICHT_KARTEN`); links ein Netz je Stück
## und der Bewuchs (`Schluchtsaum`, nur Laub, bis `SICHT_BEWUCHS`). Ab
## `FERN_AB` zeichnet jedes Stück eine grobe Fassung (jede zweite Reihe und
## jeder zweite Profilpunkt, ein Viertel der Dreiecke). Geschätzt über den
## Sichtkegel der Verfolgerkamera (ohne Verdeckung, also nach oben
## gerundet): 0–18 Zeichenaufrufe und 5–52k Dreiecke je Station, am meisten
## auf dem Hangweg (s 46–70), wo man beide Seiten weit voraus sieht.
## AUFBAU in acht Schritten (`bauschritte`), gemessen ohne Kopf am Desktop:
## Felskante vermessen 0,1 s, Wand und Narbe 0,16 s, die drei Stoff-Schritte
## je 0,23–0,25 s (Texturen der Bibliothek, die sonst hier im ersten Aufruf
## lägen), Spalten, Stufen und Ufer 0,26 s, Böschung 0,28 s, Bewuchs
## 0,38 s – keiner über 0,4 s, zusammen 1,9 s (davon 0,7 s Texturen). `lippe_q` ist O(log n): Lippe und Fuß
## entstehen einmal je Bau (`_linien_anlegen`), ebenso `querschnitte_links`.

const STUECK := 30.0
## Abstand der Querschnitte entlang der Linie (m).
const SCHRITT_RECHTS := 0.7
const SCHRITT_LINKS := 0.7
const SCHRITT_QUER := 0.45
## Sichtweiten (m, vom Kameraort zur Mitte eines Stücks).
const SICHT := 260.0
const SICHT_KARTEN := 55.0
const SICHT_BEWUCHS := 65.0
const SICHT_RAND := 6.0
## Ab hier (m) zeichnen die Kanten ihre grobe Fernfassung.
const FERN_AB := 85.0
## So weit neben einer Stufe oder Lückenkante steht je ein Querschnitt.
const EPS := 0.005
## Felsbecken links in der Fallklamm: Grund (Welt-Y) und Pfeilerhöhe über
## der Kurve.
const BECKEN_Y := 19.0
const PFEILER_HOEHE := 11.0
## Scharte in der linken Wand der Fallklamm: Mitte (s), Tiefe, Breite (m).
const SCHARTE := Vector3(132.0, 2.9, 8.5)
## Grund der Lücken (Welt-Y), wie "fuss_y" der STIRN-Einträge.
const KERBE_GRUND := 16.0
const FALLKERBE_GRUND := 18.0
const ERDSPALT_GRUND := 17.0
## So weit reicht die Narbe am Erdspalt hinter die Lippe (unter den
## Waldboden des Geländes, dessen Wand 0,85 m dahinter steht und das 1,05 m
## dahinter den Waldboden erreicht).
const ERDSPALT_NARBE := 1.15
## Die Felsplatten der Wegbauten rechts (Felsrand unter dem Geländer,
## Kanzel): Außenkante, die Wand beginnt 0,25 m dahinter unter ihnen.
const PLATTE_RAND := 5.7
const KANZEL_RAND := 10.2
const KANZEL_VON := 39.3
const KANZEL_BIS := 48.7
const PLATTE_VON := 33.2
const PLATTE_BIS := 50.8
## Glättung und Rauschen der Narbenpunkte 0–7 rechts.
const GLATT_NARBE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.5]
const RAUSCHEN_NARBE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.15]
## Krone links hinter der Kante: Abstand und Anstieg der Punkte 20–25
## (Böschung und Felswand).
const KRONE_WEITE_B: Array[float] = [0.0, 0.9, 2.0, 3.3, 5.0, 7.5]
const KRONE_HOCH_B: Array[float] = [0.0, 0.08, 0.2, 0.35, 0.6, 1.1]
const KRONE_WEITE_W: Array[float] = [0.8, 1.8, 3.0, 4.5, 6.0, 7.5]
const KRONE_HOCH_W: Array[float] = [0.05, 0.15, 0.25, 0.4, 0.5, 0.6]


## Merker eines Baus: Lippe rechts und Fuß links als Polylinie samt ihren
## Strecken (für die binäre Suche in `lippe_q`), die Querschnitte links
## (`querschnitte_links`) und die Zwischenstände der Bauschritte. Einmal je
## Bau angelegt, beim Verlassen des Levels vergessen (`vergessen`).
static var _lippe := PackedVector2Array()
static var _lippe_s := PackedFloat32Array()
static var _fuss := PackedVector2Array()
static var _fuss_s := PackedFloat32Array()
static var _querschnitte := {}
static var _bau := {}
static var _level_id := 0


## Bauschritte, je {"text": String, "tun": Callable}. Acht Schritte, keiner
## über 0,4 s (Desktop, ohne Kopf gemessen), damit der Ladebalken auch im
## Web nicht lange steht; die Zwischenstände liegen in `_bau`. Die drei
## Stoff-Schritte wärmen die Texturen der Bibliothek vor, die der Stoff der
## Kanten braucht (beim ersten Aufruf je 0,15–0,4 s, danach geteilt – auch
## das Gelände nimmt sie).
static func bauschritte(level: Level01) -> Array:
	vergessen()
	_level_id = level.get_instance_id()
	var id := _level_id
	level.tree_exiting.connect(func() -> void: L01Saum.vergessen(id), CONNECT_ONE_SHOT)
	_linien_anlegen(level)
	return [
		{"text": "Die Felskante wird vermessen", "tun": func() -> void: _rechts_vermessen(level)},
		{"text": "Felswand und Grasnarbe", "tun": func() -> void: _rechts_bauen(level)},
		{"text": "Sandstein wird geschichtet", "tun": func() -> void:
			Materialbibliothek.wurzelfels()
			Riesenstamm.moostextur()
			GelaendeSaum.kartenstoff()},
		{"text": "Kalk wird gebrochen", "tun": func() -> void: Materialbibliothek.fels()},
		{"text": "Erde wird aufgeschüttet", "tun": func() -> void:
			Materialbibliothek.waldboden()
			GelaendeSaum.stoff()},
		{"text": "Spalten, Stufen und Ufer", "tun": func() -> void: _rechts_quer(level)},
		{"text": "Böschung und Schichtfels", "tun": func() -> void: _links(level)},
		{"text": "Farne und Ranken an der Wand", "tun": func() -> void: _links_bewuchs(level)},
	]


## Vergisst alle Merker (Linien, Querschnitte, Flächen); `level_id` ≠ 0:
## nur, wenn sie zu diesem Level gehören.
static func vergessen(level_id: int = 0) -> void:
	if level_id != 0 and level_id != _level_id:
		return
	_lippe = PackedVector2Array()
	_lippe_s = PackedFloat32Array()
	_fuss = PackedVector2Array()
	_fuss_s = PackedFloat32Array()
	_querschnitte = {}
	_bau = {}
	_level_id = 0
	GelaendeSaum.vergessen()


## Lippe rechts und Fuß links (einmal je Bau).
static func _linien_anlegen(level: Level01) -> void:
	if _lippe.is_empty():
		_lippe = _lippe_rechts(level)
		_lippe_s = _strecken(_lippe)
	if _fuss.is_empty():
		_fuss = _fuss_links(level)
		_fuss_s = _strecken(_fuss)


static func _strecken(linie: PackedVector2Array) -> PackedFloat32Array:
	var aus := PackedFloat32Array()
	aus.resize(linie.size())
	for i in linie.size():
		aus[i] = linie[i].x
	return aus


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "saum" – die
## Böden der Vorsprünge. Nur eine Marke: Die Oberseite liegt verschmolzen im
## Netz der rechten Kante (`_vorsprung_flaechen`), passgenau auf der Decke
## bis zur Lippe; die Felsstirn darunter ist das Profil der Kante.
static func optik(_level: Level01, eintrag: Dictionary) -> Node3D:
	if not String(eintrag.get("name", "")).begins_with("Vorsprung"):
		return null
	var marke := Node3D.new()
	marke.name = "Optik (Saum)"
	return marke


## Querabstand der Lippe rechts bzw. des Wandfußes links an der Strecke `s`
## (positiv), wie gebaut. Für Rasen, Wald und Gelände. O(log n): Die Linien
## entstehen einmal je Bau, gesucht wird binär über ihre Strecken; außerhalb
## gilt der Abstand aus `rand_profil`.
static func lippe_q(level: Level01, s: float, seite: float) -> float:
	_linien_anlegen(level)
	var linie := _lippe if seite > 0.0 else _fuss
	var strecken := _lippe_s if seite > 0.0 else _fuss_s
	var n := linie.size()
	# Das erste Segment, dessen Ende nicht vor `s` liegt (senkrechte Stücke
	# wie die Stirn der Kanzel überspringt die Schleife).
	var i := maxi(strecken.bsearch(s, true) - 1, 0)
	while i < n - 1:
		var a := linie[i]
		var b := linie[i + 1]
		if a.x > s:
			break
		if s <= b.x and b.x - a.x > 0.0001:
			return absf(lerpf(a.y, b.y, (s - a.x) / (b.x - a.x)))
		i += 1
	return absf(float(level.rand_profil(s, seite)["abstand"]))


## Die Querschnitte links, wie der Bau sie rechnet (ohne Glättung und
## Rauschen der Fläche), für das Gelände, das unter der Böschung, hinter der
## Wand und am Ende der Krone anschließt: {"s": PackedFloat32Array, "punkte":
## Array[PackedVector2Array] mit Vector2(|q|, Welt-Y) je Profilpunkt – 0
## Schulter, 2–3 Fuß, 4–19 Hang bzw. Wand, 20 Kronenkante, 25 Kronenende}.
## Wo die Fußlinie schräg zum Weg läuft (Nische, Seiten des Beckens), zählt
## vom Versatz entlang ihrer Normale nur der Anteil quer zum Weg; wo sie
## quer zum Weg abbiegt (Ende bei 160), taugt das Profil dafür nicht.
static func querschnitte_links(level: Level01) -> Dictionary:
	if not _querschnitte.is_empty():
		return _querschnitte
	_linien_anlegen(level)
	var proben := GelaendeSaum.linie(level.verlauf, _fuss, SCHRITT_LINKS, _feste_s())
	var strecken := PackedFloat32Array()
	var punkte: Array[PackedVector2Array] = []
	var n := proben.size()
	for i in n:
		var probe: Dictionary = proben[i]
		var p := _profil_links(i, probe, level)
		var q_linie := absf(float(probe["q"]))
		var vor: Dictionary = proben[mini(i + 1, n - 1)]
		var nach: Dictionary = proben[maxi(i - 1, 0)]
		var tangente := Vector2(float(vor["s"]) - float(nach["s"]),
				absf(float(vor["q"])) - absf(float(nach["q"])))
		var quer := tangente.x / maxf(tangente.length(), 0.0001)
		var reihe := PackedVector2Array()
		for j in p.anzahl():
			var q := absf(p.o[j]) if p.absolut[j] == 1 else q_linie + p.o[j] * quer
			reihe.append(Vector2(q, p.y[j]))
		strecken.append(float(probe["s"]))
		punkte.append(reihe)
	# Geteilt – nie verändern.
	_querschnitte = {"s": strecken, "punkte": punkte}
	return _querschnitte


# ================================================================ Stücke

## Sammelt die Netze je Stück: ein Fels-Netz (Stoff `GelaendeSaum.stoff`)
## und ein Kartennetz je Name.
class Stuecke:
	extends RefCounted
	var wurzel: Node3D
	var _opak := {}
	var _fern := {}
	var _karten := {}
	var _namen: Array[String] = []

	func _init(eltern: Node3D, name: String) -> void:
		wurzel = Node3D.new()
		wurzel.name = name
		eltern.add_child(wurzel)

	func opak(name: String) -> SurfaceTool:
		if not _opak.has(name):
			_opak[name] = _neu()
			if not _namen.has(name):
				_namen.append(name)
		return _opak[name]

	## Die Fernfassung eines Stücks (ab `FERN_AB`, nur die groben Gitter).
	func fern(name: String) -> SurfaceTool:
		if not _fern.has(name):
			_fern[name] = _neu()
			if not _namen.has(name):
				_namen.append(name)
		return _fern[name]

	func karten(name: String) -> SurfaceTool:
		if not _karten.has(name):
			_karten[name] = _neu()
			if not _namen.has(name):
				_namen.append(name)
		return _karten[name]

	func _neu() -> SurfaceTool:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		return st

	## Hängt alle Netze an: nah bis `fern_ab`, die Fernfassung ab dort bis
	## `sicht`; ein Stück ohne Fernfassung bleibt bis `sicht` in voller
	## Auflösung.
	func fertig(sicht: float, fern_ab: float, sicht_karten: float, rand: float) -> void:
		for name in _namen:
			var hat_fern := _fern.has(name)
			if _opak.has(name):
				_knoten(name, _opak[name], GelaendeSaum.stoff(), 0.0,
						fern_ab if hat_fern else sicht, rand)
			if hat_fern:
				_knoten(name + " fern", _fern[name], GelaendeSaum.stoff(), fern_ab, sicht, rand)
			if _karten.has(name):
				_knoten(name + " Karten", _karten[name], GelaendeSaum.kartenstoff(), 0.0,
						sicht_karten, rand)

	func _knoten(name: String, st: SurfaceTool, stoff: Material, von: float, bis: float,
			rand: float) -> void:
		st.index()
		var netz := st.commit()
		if netz == null or netz.get_surface_count() == 0:
			return
		var mi := MeshInstance3D.new()
		mi.name = name
		mi.mesh = netz
		mi.material_override = stoff
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_begin = von
		mi.visibility_range_begin_margin = rand if von > 0.0 else 0.0
		mi.visibility_range_end = bis
		mi.visibility_range_end_margin = rand
		wurzel.add_child(mi)


static func _wurzel(level: Level01) -> Node3D:
	var knoten := level.geometrie.get_node_or_null("Saum") as Node3D
	if knoten == null:
		knoten = Node3D.new()
		knoten.name = "Saum"
		level.geometrie.add_child(knoten)
	return knoten


## Name des Stücks, in dem die Strecke `s` liegt. Die Grenzen liegen 3 m
## vor den vollen 30 m: So fällt der Anfang der Böschung (27,7) nicht in ein
## eigenes, winziges Stück.
static func _stueck(prefix: String, s: float) -> String:
	return "%s %d" % [prefix, int(floor((s + 3.0) / STUECK))]


## Schreibt ein Gitter in Stücke nach seiner Strecke; benachbarte Stücke
## teilen sich die Randreihe.
static func _gitter_in_stuecke(st: Stuecke, prefix: String, g: Dictionary,
		norm: Array[PackedVector3Array]) -> void:
	var strecken: PackedFloat32Array = g["s"]
	var n := strecken.size()
	var a := 0
	while a < n - 1:
		var name := _stueck(prefix, strecken[a])
		var b := a
		while b < n - 1 and _stueck(prefix, strecken[b + 1]) == name:
			b += 1
		GelaendeSaum.gitter_schreiben(st.opak(name), g, norm, a, mini(b + 1, n - 1))
		GelaendeSaum.gitter_schreiben(st.fern(name), g, norm, a, mini(b + 1, n - 1), 2)
		a = b + 1


## Verschließt Anfang und Ende eines Gitters.
static func _deckel_an_enden(st: Stuecke, prefix: String, g: Dictionary) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var farben: Array[PackedColorArray] = g["farben"]
	var strecken: PackedFloat32Array = g["s"]
	var boden: PackedFloat32Array = g["boden"]
	var n := reihen.size()
	if n < 2:
		return
	for ende in 2:
		var i := 0 if ende == 0 else n - 1
		var nachbar := 1 if ende == 0 else n - 2
		var aussen := reihen[i][0] - reihen[nachbar][0]
		aussen.y = 0.0
		if aussen.length_squared() < 0.000001:
			continue
		GelaendeSaum.deckel(st.opak(_stueck(prefix, strecken[i])), reihen[i], farben[i],
				aussen.normalized(), boden[i])


# ================================================================ Hilfen

static func _wegrand(level: Level01, s: float) -> float:
	return float(level.rand_profil(s, 1.0)["wegrand"])


static func _kante(_i: int, probe: Dictionary, level: Level01) -> float:
	return level.boden_bei(float(probe["s"]))


static func _kronen(_i: int, probe: Dictionary, level: Level01) -> float:
	var s := clampf(float(probe["s"]), 0.0, Level01.M_ENDE)
	return L01Boden.kronenlicht_bei(level, s)


static func _feste_s() -> PackedFloat32Array:
	var feste := PackedFloat32Array()
	for l: Dictionary in Level01.LUECKEN:
		var von: float = l["von"]
		var bis: float = l["bis"]
		feste.append_array([von, von + EPS * 2.0, bis - EPS * 2.0, bis])
	for s: float in [66.0, 133.0, 145.0]:
		feste.append_array([s - EPS, s + EPS])
	for a: Dictionary in Level01.ABSCHNITTE:
		feste.append(float(a["von"]))
	return feste


## Grund einer Lücke an der Strecke `s` (Welt-Y), NAN außerhalb.
static func _luecken_grund(s: float) -> float:
	if s > 25.0 and s < 27.5:
		return ERDSPALT_GRUND
	if s > 56.0 and s < 59.0:
		return KERBE_GRUND
	if s > 118.0 and s < 121.0:
		return FALLKERBE_GRUND
	return NAN


static func _welle(x: float, versatz: float) -> float:
	return GelaendeSaum.rauschen().get_noise_1d(x + versatz * 37.0)


## Senkrechte Klüfte in den Felswänden (0..1, 1 in der Kluft): alle 7–12 m
## eine, gut einen Meter breit. Sie brechen die waagerechten Lagen – ohne
## sie las sich die Wand als Schokoladentorte.
static func _kluft(bogen: float, versatz: float) -> float:
	var phase := bogen * PI / 9.5 + 1.3 * _welle(bogen * 0.05, versatz)
	return smoothstep(0.86, 0.985, absf(sin(phase)))


## Überhang der Grasnarbe an Stirnflächen, Stufen und Furt (m): 0,15–0,35,
## nur nach außen, in Buckeln von 2–3 m – keine Lineal-Kante.
static func _ueberhang_quer(bogen: float, versatz: float) -> float:
	return clampf(0.25 + 0.11 * _welle(bogen * 0.4, versatz)
			+ 0.05 * _welle(bogen * 1.3, versatz + 5.0), 0.15, 0.35)


static func _farbe(ao: float, erde: float, moos: float, rasen: float) -> Color:
	return Color(ao, erde, moos, rasen)


# ================================================================ Rechts

## Die Lippe rechts als Polylinie [Vector2(s, q)].
static func _lippe_rechts(level: Level01) -> PackedVector2Array:
	var p := PackedVector2Array()
	# Um die Ecke der Hochfläche: außen am Hallenwald vorbei (seine Stämme
	# stehen rechts bis s 26 bei q 7–24), dann zur Wegkante bei 33, außen um
	# den Findling der Enthüllung (s 31, q 5,5–8,3) herum.
	for v: Vector2 in [Vector2(21.0, 30.0), Vector2(23.0, 27.0), Vector2(24.8, 24.6),
			Vector2(26.4, 21.0), Vector2(27.8, 16.6), Vector2(29.2, 13.4), Vector2(30.5, 11.4),
			Vector2(31.6, 10.1), Vector2(32.5, 8.6), Vector2(32.95, 6.6),
			Vector2(PLATTE_VON, PLATTE_RAND - 0.25)]:
		p.append(v)
	# Unter den Platten: Felsrand des Geländers, Kanzel (gerundete Ecken).
	var innen := PLATTE_RAND - 0.25
	var aussen := KANZEL_RAND - 0.25
	for v: Vector2 in [Vector2(KANZEL_VON - 0.2, innen), Vector2(KANZEL_VON - 0.05, innen + 0.2),
			Vector2(KANZEL_VON, innen + 0.8), Vector2(KANZEL_VON, aussen - 0.45),
			Vector2(KANZEL_VON + 0.12, aussen - 0.12), Vector2(KANZEL_VON + 0.45, aussen),
			Vector2(KANZEL_BIS - 0.45, aussen), Vector2(KANZEL_BIS - 0.12, aussen - 0.12),
			Vector2(KANZEL_BIS, aussen - 0.45), Vector2(KANZEL_BIS, innen + 0.8),
			Vector2(KANZEL_BIS + 0.05, innen + 0.2), Vector2(KANZEL_BIS + 0.2, innen),
			Vector2(PLATTE_BIS - 0.4, innen)]:
		p.append(v)
	# Ab dem Ende der Platten die Wegkante, mit den Vorsprüngen.
	var s := PLATTE_BIS + 0.2
	var umrisse: Array = [Level01.VORSPRUNG_62, Level01.VORSPRUNG_75, Level01.VORSPRUNG_89]
	var ende := 159.5
	while s <= ende + 0.001:
		var im_umriss := false
		for u: Array in umrisse:
			var a: Vector2 = u[0]
			var b: Vector2 = u[u.size() - 1]
			if s >= a.x - 0.001 and s <= b.x + 0.001:
				im_umriss = true
				if s < a.x + 0.25:
					for v: Vector2 in u:
						p.append(v)
				break
		# An der Stufe 145 (1,4 m hinab, die Decke wird 0,25 m breiter) ist die
		# Lippe gerundet: ein Bogen 0,3 m nach außen statt einer Ecke.
		if s > 144.45 and s < 145.75:
			if s < 144.55:
				for v: Vector2 in [Vector2(144.6, 0.04), Vector2(144.85, 0.17),
						Vector2(145.05, 0.28), Vector2(145.3, 0.24), Vector2(145.6, 0.08)]:
					p.append(Vector2(v.x, _wegrand(level, v.x) + v.y))
		elif not im_umriss:
			p.append(Vector2(s, _wegrand(level, s)))
		s += 0.5
	# Hinter C4 läuft das Ufer an der Kante der Bachwiese weiter und taucht
	# unter die Wiese, die das Gelände dort bis 162,5 zum Bach hin anhebt:
	# Früher bog es bei 160 rechtwinklig nach außen und stand als Erdwand
	# quer zum Weg (von der Fallklamm aus eine Würfelwand).
	for v: Vector2 in [Vector2(160.0, 6.0), Vector2(161.0, 6.0), Vector2(162.0, 6.0),
			Vector2(UFER_ENDE, 6.0)]:
		p.append(v)
	return _monoton(p)


## Entfernt Punkte, die in s zurücklaufen (außer an senkrechten Stücken wie
## der Kanzelstirn) oder doppelt sind.
static func _monoton(p: PackedVector2Array) -> PackedVector2Array:
	var aus := PackedVector2Array()
	for v in p:
		if not aus.is_empty():
			var letzter := aus[aus.size() - 1]
			if v.distance_to(letzter) < 0.02 or v.x < letzter.x - 0.001:
				continue
		aus.append(v)
	return aus


## Anteil der Platten-Fassung (0..1) an der Strecke `s`.
static func _platte(s: float) -> float:
	return smoothstep(PLATTE_VON - 0.6, PLATTE_VON + 0.1, s) \
			* (1.0 - smoothstep(PLATTE_BIS - 0.5, PLATTE_BIS + 0.2, s))


## Die Felskante rechts, Schritt 1: Querschnitte und Normalen.
static func _rechts_vermessen(level: Level01) -> void:
	_linien_anlegen(level)
	var proben := GelaendeSaum.linie(level.verlauf, _lippe, SCHRITT_RECHTS, _feste_s())
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, 1.0,
			_profil_rechts.bind(level), _kante.bind(level), _kronen.bind(level))
	GelaendeSaum.merken(1.0, g)
	_bau["rechts_proben"] = proben
	_bau["rechts_g"] = g
	_bau["rechts_norm"] = GelaendeSaum.normalen(g)


## Schritt 2: Gitter, Karten, Vorsprünge, Nadeln und Steine in die Stücke.
static func _rechts_bauen(level: Level01) -> void:
	var st := Stuecke.new(_wurzel(level), "Rechts")
	var proben: Array[Dictionary] = _bau["rechts_proben"]
	var g: Dictionary = _bau["rechts_g"]
	var norm: Array[PackedVector3Array] = _bau["rechts_norm"]
	_gitter_in_stuecke(st, "Rechts", g, norm)
	_deckel_an_enden(st, "Rechts", g)
	_lippenkarten(st, "Rechts", proben, g, 8301)
	_vorsprung_flaechen(st, level)
	_felsnadeln(st, level)
	_eckfelsen(st, level)
	_ufer_steine(st, proben, g, norm)
	_bau["rechts_st"] = st


## Schritt 3: Die Stirnflächen liegen in denselben Stücken (je Stück ein
## Aufruf); danach werden die Netze der rechten Seite fertig.
static func _rechts_quer(level: Level01) -> void:
	var st: Stuecke = _bau["rechts_st"]
	_quer(st, level)
	st.fertig(SICHT, FERN_AB, SICHT_KARTEN, SICHT_RAND)
	_bau.erase("rechts_st")
	_bau.erase("rechts_norm")
	_bau.erase("rechts_proben")
	_bau.erase("rechts_g")


## Rand-Daten rechts, auch vor dem Anfang und hinter dem Ende der Felskante
## (dort gelten die ersten bzw. letzten Werte).
static func _rand_rechts(level: Level01, s: float) -> Dictionary:
	return level.rand_profil(clampf(s, 33.0, 159.9), 1.0)


## Das Profil rechts an einer Probe (30 Punkte, siehe Kopf).
static func _profil_rechts(_i: int, probe: Dictionary, level: Level01) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var q_lippe: float = probe["q"]
	var kante := level.boden_bei(s)
	var r := _rand_rechts(level, s)
	var fuss_y: float = r["fuss_y"]
	if is_nan(fuss_y):
		fuss_y = 5.4
	# Überhang der Grasnarbe: 0,1–0,33 m, nur nach außen.
	var ov := clampf(0.2 + 0.1 * _welle(bogen * 0.9, 1.0) + 0.07 * _welle(bogen * 2.7, 2.0),
			0.1, 0.33)
	# Das Ufer über dem Kanal beginnt erst HINTER der Stufe 145: Über der
	# Stufe gemischt, stand zwischen der tiefen Wand und dem breiten Ufer eine
	# ebene Scheibe quer zum Weg (eine Würfelwand).
	var ufer := _ufer_anteil(s)
	var p: GelaendeSaum.Profil
	if ufer <= 0.0:
		p = _profil_ab(level, s, bogen, q_lippe, kante, fuss_y, ov)
	elif ufer >= 1.0:
		p = _profil_ufer(bogen, kante, fuss_y, ov)
	else:
		p = _profil_ab(level, s, bogen, q_lippe, kante, fuss_y, ov).gemischt(
				_profil_ufer(bogen, kante, fuss_y, ov), ufer)
	# Der Erdspalt reicht nicht bis zur Ecke der Hochfläche. Kerbe und
	# Fallkerbe münden als Kerbtal in der Wand, nicht als Schlitz: Zu den
	# Rändern der Lücke hin wird immer weniger ausgeschnitten, und weiter
	# draußen steigt der Grund (die Seiten lehnen sich gut 50° zurück).
	var grund := _luecken_grund(s) if s > 40.0 else NAN
	if not is_nan(grund):
		var mitte := 57.5 if s < 100.0 else 119.5
		var rand := clampf((absf(s - mitte) - 0.25) / 1.25, 0.0, 1.0)
		_in_luecke(p, grund, 0, p.anzahl() - 1, 1.2, rand, true)
	return p


## Ende der Felskante rechts (unter der Bachwiese).
const UFER_ENDE := 163.0


## Anteil des Ufers (C4) an der Felskante rechts: erst hinter der Stufe.
static func _ufer_anteil(s: float) -> float:
	return smoothstep(146.5, 152.0, s)


## Senkt die Punkte `von`..`bis` eines Profils auf den Grund einer Lücke
## (höchstens `grund + anstieg · o`): So ist die Kante an der Lücke
## ausgeschnitten, und zwischen dem letzten Querschnitt davor und dem ersten
## darin steht die Seitenwand der Lücke. Was gesenkt wird, ist dunkler Fels.
static func _in_luecke(p: GelaendeSaum.Profil, grund: float, von: int, bis: int,
		anstieg: float, rand: float = 0.0, kerbtal: bool = false) -> void:
	var o_max := -INF
	for j in range(von, bis + 1):
		var grenze := grund + maxf(p.o[j], 0.0) * anstieg
		# `rand` (0 in der Mitte der Lücke, 1 an ihren Kanten): Am Hang wird
		# zur Kante hin immer weniger ausgeschnitten – die Rinne ist ein V.
		var hang := smoothstep(0.3, 1.5, p.o[j]) if p.absolut[j] == 0 else 0.0
		if kerbtal:
			# Die Wand unter der Lippe (Versatz um −0,5): Ihr Grund steigt
			# nach draußen, und zu den Rändern der Lücke hin bleibt die ganze
			# Wand stehen – ein Kerbtal statt eines Schlitzes.
			grenze = grund + maxf(p.o[j] + 0.5, 0.0) * anstieg
			hang = 1.0
		grenze = lerpf(grenze, maxf(grenze, p.y[j]), hang * smoothstep(0.0, 1.0, rand))
		if p.absolut[j] == 1:
			grenze = grund
		if p.y[j] <= grenze:
			continue
		p.y[j] = grenze
		# Auf dem Grund nicht zurücklaufen: sonst faltete sich die Fläche.
		if p.absolut[j] == 0:
			o_max = maxf(o_max, p.o[j])
			p.o[j] = o_max
		# Unter dem Weg dunkler Fels, in der Rinne am Hang Erde und Moos.
		p.farbe[j] = Color(0.34, 0.5, 0.2, 0.0).lerp(Color(0.6, 0.75, 0.55, 0.0), hang)
		# Der Grund unter dem Weg bleibt eben, die Rinne am Hang ist rau.
		p.rauschen[j] = 0.3 * hang
		p.richtung[j] = 1.0
		p.schicht[j] = 0.0


## FELS_AB: Grasnarbe, Überhang, Schichtfels mit zwei Simsen, Fuß.
static func _profil_ab(level: Level01, s: float, bogen: float, q_lippe: float,
		kante: float, fuss_y: float, ov: float) -> GelaendeSaum.Profil:
	var h := maxf(kante - fuss_y, 6.0)
	var platte := _platte(s)
	# Simse: Tiefe und Breite wandern langsam entlang der Kante.
	var d1 := clampf(8.2 + 1.1 * _welle(bogen * 0.07, 3.0), 7.2, h * 0.55)
	var d2 := clampf(d1 + 4.6 + 1.0 * _welle(bogen * 0.06, 5.0), d1 + 2.4, maxf(h - 2.2, d1 + 2.4))
	# Die Simse setzen aus: Ein Sims, der die ganze Wand entlangläuft, macht
	# aus dem Fels eine Torte. Sie tauchen auf 3–8 m auf und verschwinden,
	# und jede Kluft schneidet sie ab.
	var kluft := _kluft(bogen, 31.0)
	var da1 := smoothstep(-0.3, 0.25, _welle(bogen * 0.072, 21.0))
	var da2 := smoothstep(-0.3, 0.25, _welle(bogen * 0.08, 22.0))
	var w1 := (0.5 + 0.45 * (1.0 + _welle(bogen * 0.11, 4.0))) * lerpf(0.06, 1.0, da1) \
			* (1.0 - kluft)
	var w2 := (0.45 + 0.45 * (1.0 + _welle(bogen * 0.09, 6.0))) * lerpf(0.06, 1.0, da2) \
			* (1.0 - kluft)
	# Zwischen den Klüften treten Pfeiler vor (nur unterhalb des Überhangs –
	# dort, wo eine fallende Figur längst in der Todeszone ist): Die Wand
	# steht in senkrechten Rippen statt als Torte in Lagen.
	var pfeiler := 0.65 * (1.0 - kluft)
	d2 = maxf(d2, d1 + 2.4)
	var u_ende := minf(6.4, d1 - 1.3)
	var p := GelaendeSaum.Profil.new()
	# Um die Ecke der Hochfläche (vor s 33) liegt keine Decke an der Lippe:
	# Die Narbe reicht dort 1,8 m nach innen, unter den Waldboden des
	# Geländes, dessen Kante 1,35 m hinter der Lippe steil abbricht (hinter
	# der Wand, siehe `L01Gelaende`). Innen trägt sie schon dessen Farbe.
	var ecke := 1.0 - smoothstep(32.0, 32.6, s)
	# --- Grasnarbe (0–5) oder Platte
	var narbe: Array = [
		[lerpf(-0.45, -1.8, ecke), lerpf(-0.03, -0.05, ecke),
				_farbe(0.78, 0.0, 0.05, 1.0).lerp(_farbe(0.62, 0.35, 0.55, 0.45), ecke)],
		[ov * 0.4, -0.006, _farbe(0.78, 0.0, 0.2, 1.0)],
		[ov * 0.8, -0.035, _farbe(0.72, 0.1, 0.3, 0.95)],
		[ov, -0.12, _farbe(0.5, 0.6, 0.3, 0.45)],
		[ov - 0.06, -0.25, _farbe(0.3, 1.0, 0.1, 0.0)],
		[ov - 0.32, -0.33, _farbe(0.18, 1.0, 0.0, 0.0)],
		[-0.35, -0.48, _farbe(0.2, 1.0, 0.0, 0.0)],
		[-0.5, -0.9, _farbe(0.27, 0.75, 0.1, 0.0)],
	]
	var unter_platte: Array = [
		[-0.55, -0.9], [-0.45, -1.3], [-0.35, -1.8], [-0.3, -2.3],
		[-0.25, -2.8], [-0.2, -3.3], [-0.12, -3.8], [0.0, -4.2],
	]
	for j in narbe.size():
		var n: Array = narbe[j]
		var o: float = n[0]
		var y: float = n[1]
		var f: Color = n[2]
		if platte > 0.0:
			var u: Array = unter_platte[j]
			o = lerpf(o, float(u[0]), platte)
			y = lerpf(y, float(u[1]), platte)
			f = f.lerp(_farbe(0.5, 0.1, 0.15, 0.0), platte)
		var glatt: float = GLATT_NARBE[j]
		var rausch: float = RAUSCHEN_NARBE[j] + 0.08 * platte
		p.punkt(o, kante + y, f, glatt, rausch, -1.0)
	# --- Überhang (8–13): nur nach innen
	var u_von := lerpf(1.5, 4.6, platte)
	var u_bis := maxf(lerpf(u_ende, maxf(u_ende, 6.4), platte), u_von + 1.0)
	for k in 6:
		var t := float(k) / 5.0
		var d := lerpf(u_von, u_bis, t)
		var o := lerpf(-0.5, -0.45, t) + platte * lerpf(0.2, 0.0, t)
		p.punkt(o, kante - d, _farbe(lerpf(0.36, 0.68, t), lerpf(0.3, 0.0, t), 0.2, 0.0),
				0.8, 0.35, -1.0, 0.12)
	# --- Wand zum ersten Sims (14–17); in einer Kluft dunkler
	var d14 := maxf(u_bis + 0.6, d1 - 1.0)
	var kl := 1.0 - 0.35 * kluft
	p.punkt(_ab_o(d14, u_ende) + pfeiler * 0.5, kante - d14, _farbe(0.72 * kl, 0.0, 0.2, 0.0),
			1.2, 0.8, 1.0, 0.18)
	p.punkt(_ab_o(d1, u_ende) - 0.05 + pfeiler, kante - (d1 - 0.12),
			_farbe(0.5 * kl, 0.2, 0.45, 0.0), 1.6, 0.5)
	p.punkt(_ab_o(d1, u_ende) + w1 * 0.85 + pfeiler, kante - (d1 - 0.02),
			_farbe(0.9 * kl, 0.3, 0.9 * da1, 0.0), 1.6, 0.4)
	p.punkt(_ab_o(d1, u_ende) + w1 + pfeiler, kante - (d1 + 0.4), _farbe(0.8 * kl, 0.1, 0.35, 0.0),
			1.8, 0.5)
	# --- Wand zum zweiten Sims (18–21)
	var dm := (d1 + 0.4 + d2 - 0.12) * 0.5
	p.punkt(_ab_o(dm, u_ende) + w1 + pfeiler, kante - dm, _farbe(0.76 * kl, 0.0, 0.2, 0.0),
			2.0, 1.1, 1.0, 0.18)
	p.punkt(_ab_o(d2, u_ende) + w1 - 0.05 + pfeiler, kante - (d2 - 0.12),
			_farbe(0.52 * kl, 0.2, 0.45, 0.0), 2.5, 0.5)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2 * 0.85 + pfeiler, kante - (d2 - 0.02),
			_farbe(0.88 * kl, 0.3, 0.9 * da2, 0.0), 2.5, 0.4)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2 + pfeiler, kante - (d2 + 0.4),
			_farbe(0.78 * kl, 0.1, 0.35, 0.0), 2.8, 0.5)
	# --- Unterer Teil bis zum Fuß (22–26)
	for k in 5:
		var t := float(k + 1) / 6.0
		var d := lerpf(d2 + 0.4, h - 0.2, t)
		p.punkt(_ab_o(d, u_ende) + w1 + w2 + 0.25 * t + pfeiler, kante - d,
				_farbe(lerpf(0.74, 0.6, t) * kl, 0.0, 0.2, 0.0), lerpf(3.0, 4.5, t), 1.2, 1.0, 0.18)
	# --- Fuß und darunter (27–29): Das Gelände liegt unter der Wand.
	var of := _ab_o(h, u_ende) + w1 + w2 + 0.5 + pfeiler
	p.punkt(of, fuss_y, _farbe(0.55, 0.45, 0.35, 0.0), 5.0, 0.8)
	p.punkt(of + 1.3, fuss_y - 1.0, _farbe(0.5, 0.7, 0.3, 0.0), 5.0, 0.6)
	p.punkt(of + 2.0, fuss_y - 3.0, _farbe(0.45, 0.8, 0.2, 0.0), 5.0, 0.4)
	return p


## Versatz der Felswand rechts in der Tiefe `d` unter der Kante: bis zum
## Ende des Überhangs 0,5 m hinter der Lippe, darunter 80° (0,18 m je m).
static func _ab_o(d: float, u_ende: float) -> float:
	return -0.5 + 0.18 * maxf(d - u_ende, 0.0)


## UFER: Grasnarbe, Erdufer mit Steinen, nasser Fuß (30 Punkte wie FELS_AB).
static func _profil_ufer(bogen: float, kante: float, fuss_y: float,
		ov: float) -> GelaendeSaum.Profil:
	var h := maxf(kante - fuss_y, 1.5)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, kante - 0.03, _farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, kante - 0.006, _farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, kante - 0.035, _farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, kante - 0.12, _farbe(0.5, 0.7, 0.3, 0.4))
	p.punkt(ov - 0.06, kante - 0.25, _farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3, kante - 0.33, _farbe(0.2, 1.0, 0.0, 0.0))
	p.punkt(-0.2, kante - 0.48, _farbe(0.24, 1.0, 0.05, 0.0), 0.3, 0.05, -1.0)
	p.punkt(-0.15, kante - 0.9, _farbe(0.32, 0.9, 0.2, 0.0), 0.5, 0.1, -1.0)
	# Ufer (8–24): oben 45°, dann 60–70°, Erde mit Moos, nach unten nasser.
	for k in 17:
		var t := float(k + 1) / 18.0
		var d := lerpf(0.9, h - 0.4, t)
		var bauch := 0.25 * sin(t * PI) * (1.0 + _welle(bogen * 0.2, 7.0))
		p.punkt(_ufer_o(d) + bauch, kante - d,
				_farbe(lerpf(0.74, 0.55, t), lerpf(0.7, 0.5, t), lerpf(0.8, 0.5, t),
				0.45 * (1.0 - t)), lerpf(0.8, 2.5, t), 0.35, 1.0, 0.1)
	var of := _ufer_o(h - 0.4) + 0.3
	p.punkt(of, fuss_y + 0.4, _farbe(0.42, 0.6, 0.5, 0.0), 2.5, 0.2)
	p.punkt(of + 0.4, fuss_y, _farbe(0.38, 0.7, 0.4, 0.0), 3.0, 0.2)
	p.punkt(of + 1.2, fuss_y - 0.5, _farbe(0.36, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.0, fuss_y - 1.5, _farbe(0.34, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.6, fuss_y - 3.0, _farbe(0.32, 0.8, 0.3, 0.0), 3.0, 0.2)
	return p


## Versatz des Ufers in der Tiefe `d`: die ersten 1,4 m unter 45°, dann 68°.
static func _ufer_o(d: float) -> float:
	return -0.1 + minf(d - 0.9, 1.4) * 1.0 + maxf(d - 2.3, 0.0) * 0.4


## Wurzel- und Halmkarten unter der Grasnarbe (Profilpunkte 2–5).
static func _lippenkarten(st: Stuecke, prefix: String, proben: Array[Dictionary],
		g: Dictionary, saat: int) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var strecken: PackedFloat32Array = g["s"]
	var rng := PropWerkzeug.zufall(saat)
	for i in range(1, reihen.size() - 1):
		var s := strecken[i]
		# Nicht unter den Platten, in den Lücken und hinter C4 (dort liegt
		# das Ufer unter der Bachwiese)
		if _platte(s) > 0.2 or not is_nan(_luecken_grund(s)) or s > 159.5:
			continue
		var reihe := reihen[i]
		var laengs := reihen[i + 1][3] - reihen[i - 1][3]
		laengs.y = 0.0
		if laengs.length_squared() < 0.0001:
			continue
		laengs = laengs.normalized()
		var aussen := reihe[3] - reihe[0]
		aussen.y = 0.0
		if aussen.length_squared() < 0.0001:
			continue
		aussen = aussen.normalized()
		# Punkt 1 liegt bei 0,4 · Überhang, Punkt 3 beim Überhang
		var vor := (reihe[3] - reihe[1]).dot(aussen) / 0.6
		_karten_an(st.karten(_stueck(prefix, s)), rng, reihe[2], reihe[4], aussen, laengs,
				float(proben[i]["bogen"]), vor)


## Karten an einer Stelle der Narbe: oben = Narbenkante, unten = Unterseite.
## `vor` = wie weit die Narbe hier über die Lippe tritt (m): Wurzeln hängen
## in Büscheln unter den Vorsprüngen, nicht als Strichcode die Kante entlang.
static func _karten_an(st: SurfaceTool, rng: RandomNumberGenerator, oben: Vector3,
		unten: Vector3, aussen: Vector3, laengs: Vector3, _bogen: float,
		vor: float = 0.2) -> void:
	# Halme, die über die Kante hängen.
	if rng.randf() < 0.9:
		var lang := rng.randf_range(0.2, 0.5)
		var ton := Color(0.28, 0.4, 0.12) * rng.randf_range(0.75, 1.15)
		GelaendeSaum.karte(st, oben + Vector3.UP * 0.02 + laengs * rng.randf_range(-0.2, 0.2),
				(Vector3.DOWN * 0.75 + aussen * 0.65), laengs, lang,
				rng.randf_range(0.4, 0.75), GelaendeSaum.ATLAS_HALM, ton)
	# Wurzeln unter der Narbe, gekreuzt: Die Kamera blickt die Kante entlang.
	# Heller als die Erde dahinter (sonst schwarze Striche), selten, und wo
	# die Narbe vortritt, gehäuft.
	if rng.randf() < 0.25 * lerpf(0.3, 2.2, smoothstep(0.14, 0.28, vor)):
		var lang := rng.randf_range(0.3, 0.9)
		var ton := Color(0.42, 0.32, 0.23) * 1.3 * rng.randf_range(0.8, 1.1)
		var ort := unten + aussen * 0.03 + laengs * rng.randf_range(-0.25, 0.25)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.12, laengs, lang,
				rng.randf_range(0.35, 0.7), GelaendeSaum.ATLAS_WURZEL, ton)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.08, aussen + laengs * 0.3,
				lang * rng.randf_range(0.7, 1.0), rng.randf_range(0.25, 0.45),
				GelaendeSaum.ATLAS_WURZEL, ton * 0.9)


## Steine im Ufer über dem Kanal (C4): halb versenkt, bemoost.
static func _ufer_steine(st: Stuecke, proben: Array[Dictionary], g: Dictionary,
		norm: Array[PackedVector3Array]) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var boden: PackedFloat32Array = g["boden"]
	var rng := PropWerkzeug.zufall(8451)
	for i in range(2, reihen.size() - 2, 3):
		var s: float = proben[i]["s"]
		if s < 145.5 or s > 159.5 or rng.randf() > 0.7:
			continue
		var j := rng.randi_range(10, 24)
		var p := reihen[i][j]
		var n := norm[i][j]
		var r := rng.randf_range(0.3, 0.75)
		var basis := Basis(Quaternion(Vector3.UP, n.lerp(Vector3.UP, 0.4).normalized())) \
				* Basis(Vector3.UP, rng.randf() * TAU)
		GelaendeSaum.stein(st.opak(_stueck("Rechts", s)), p - n * r * 0.3,
				Vector3(r * rng.randf_range(1.0, 1.5), r * rng.randf_range(0.6, 0.85),
				r * rng.randf_range(0.9, 1.3)), basis, rng.randi_range(1, 900),
				_farbe(0.84, 0.05, 0.7, 0.0), boden[i], 0.6)


## Felsnadeln vor der Wand, auf denen die Rahmenbäume stehen
## (`RAHMENBAUM_STELLEN` "sims"), und eine unter dem Felsfuß des Torbaums.
## Eine Nadel steht FREI vor der Wand, mit einem Spalt dazwischen: Ein Sims,
## der so weit hinausträte, läge unter der Lippe – und eine Figur, die über
## die Kante fällt, fiele sichtbar durch ihn hindurch. Oben flach und
## bemoost, genau auf der Fußhöhe des Baums; unten breiter, geschichtet und
## verbeult, bis drei Meter unter den Wandfuß (dort liegt das Gelände).
static func _felsnadeln(st: Stuecke, level: Level01) -> void:
	var rng := PropWerkzeug.zufall(8601)
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		var art: String = stelle["art"]
		if art != "sims" and art != "torbaum":
			continue
		# Der Torbaum steht links auf der Felsnase – dort trägt ihn die Wand.
		if art == "torbaum" and float(stelle["q"]) < 0.0:
			continue
		var s: float = stelle["s"]
		var q: float = stelle["q"]
		var kante := level.boden_bei(s)
		var oben_y := kante + float(stelle["fuss"])
		var radius := Vector2(2.3, 1.9)
		if art == "torbaum":
			# Unter dem Felsfuß der Wegbauten (gewölbt, bis gut 5 m unter
			# den Weg), etwas weiter draußen.
			oben_y = kante - 4.6
			q += 0.35
			radius = Vector2(1.5, 1.4)
		var fuss_y: float = float(_rand_rechts(level, s)["fuss_y"]) - 3.0
		var mitte := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
		var laengs := LevelWerkzeuge.richtung(level.verlauf, s)
		var quer := laengs.cross(Vector3.UP).normalized()
		# Unten lehnt die Nadel an der Wand: Ihr Fuß rückt zur Lippe hin.
		var wand := LevelWerkzeuge.punkt_frei(level.verlauf, s, lippe_q(level, s, 1.0) + 1.2)
		_nadel(st.opak(_stueck("Rechts", s)), mitte, wand, quer, laengs, radius, fuss_y, oben_y,
				kante, rng)


## Gebrochener Fels an den Ecken der Felskante: an der Stufe 145 (dort
## stand die Kante als Winkel über dem Kanal) eine Nadel mit runder Kuppe
## und ein paar Brocken im Wasser; an den äußeren Ecken von Kerbe und
## Fallkerbe je zwei kantige Brocken, halb in der Lippe – so verschwinden
## die Ecken der Kerben. Alle Oberkanten liegen unter der Decke und sind
## nicht eben (nichts, was begehbar aussähe).
static func _eckfelsen(st: Stuecke, level: Level01) -> void:
	var rng := PropWerkzeug.zufall(8651)
	var kante := level.boden_bei(145.6)
	var fuss_y: float = float(_rand_rechts(level, 145.6)["fuss_y"]) - 3.0
	var laengs := LevelWerkzeuge.richtung(level.verlauf, 145.6)
	var quer := laengs.cross(Vector3.UP).normalized()
	var mitte := LevelWerkzeuge.punkt_frei(level.verlauf, 145.6, 6.3)
	var wand := LevelWerkzeuge.punkt_frei(level.verlauf, 145.6, lippe_q(level, 145.6, 1.0) + 1.0)
	_nadel(st.opak(_stueck("Rechts", 145.6)), mitte, wand, quer, laengs, Vector2(1.5, 1.3),
			fuss_y, kante - 1.3, kante, rng, false)
	# Brocken am Fuß der Nadel, im Kanal
	for b: Vector4 in [Vector4(144.2, 2.6, -4.6, 0.9), Vector4(147.0, 3.3, -5.2, 1.1),
			Vector4(146.2, 1.9, -6.0, 0.7)]:
		_brocken(st, level, b.x, b.y, b.z, b.w, rng)
	# Ecken von Kerbe und Fallkerbe (außen, halb in der Lippe)
	for ecke: Vector2 in [Vector2(56.0, -1.0), Vector2(59.0, 1.0), Vector2(118.0, -1.0),
			Vector2(121.0, 1.0)]:
		# nach innen in die Lücke (+1) oder aus ihr heraus (−1)
		var zur_luecke := -ecke.y
		_brocken(st, level, ecke.x + zur_luecke * 0.35, 0.35, -0.95, 0.7, rng)
		_brocken(st, level, ecke.x + zur_luecke * 0.9, 0.9, -1.9, 0.55, rng)


## Ein kantiger Brocken an der Felskante rechts: `s`, `q_ab` (Abstand von der
## Lippe nach außen), `y_ab` (Mitte unter der Decke), Radius `r`.
static func _brocken(st: Stuecke, level: Level01, s: float, q_ab: float, y_ab: float, r: float,
		rng: RandomNumberGenerator) -> void:
	var p := LevelWerkzeuge.punkt_frei(level.verlauf, s, lippe_q(level, s, 1.0) + q_ab)
	var kante := level.boden_bei(s)
	p.y = kante + y_ab
	var kipp := Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
			.normalized(), rng.randf_range(0.15, 0.45))
	var basis := kipp * Basis(Vector3.UP, rng.randf() * TAU)
	GelaendeSaum.stein(st.opak(_stueck("Rechts", s)), p,
			Vector3(r * rng.randf_range(1.0, 1.35), r * rng.randf_range(0.7, 0.95),
			r * rng.randf_range(0.85, 1.2)), basis, rng.randi_range(1, 900),
			_farbe(0.8, 0.05, 0.55, 0.0), kante, 0.0, true)


## Eine Felsnadel: Ringe von `fuss_y` bis `oben_y`, elliptisch (`radius`
## quer × längs), unten breiter, mit Schichtstufen und Rauschen; oben ein
## flacher, bemooster Deckel – oder (`flach` aus) eine runde Kuppe.
static func _nadel(st: SurfaceTool, mitte: Vector3, wand: Vector3, quer: Vector3,
		laengs: Vector3, radius: Vector2, fuss_y: float, oben_y: float, kante: float,
		rng: RandomNumberGenerator, flach: bool = true) -> void:
	const SEITEN := 16
	var hoehe := oben_y - fuss_y
	var ringe := maxi(ceili(hoehe / 0.7), 3)
	var reihen: Array[PackedVector3Array] = []
	var farben: Array[PackedColorArray] = []
	var uv2: Array[PackedVector2Array] = []
	var phase := rng.randf() * TAU
	for i in ringe + 1:
		var t := float(i) / float(ringe)
		var y := lerpf(fuss_y, oben_y - 0.25, t)
		var weite := lerpf(1.6, 1.0, smoothstep(0.0, 0.75, t))
		# Die untere Hälfte steht an der Wand, oben löst sich die Nadel.
		var ring_mitte := wand.lerp(mitte, smoothstep(0.1, 0.65, t))
		ring_mitte.y = mitte.y
		var reihe := PackedVector3Array()
		var fr := PackedColorArray()
		var uv := PackedVector2Array()
		for k in SEITEN + 1:
			var w := TAU * float(k % SEITEN) / float(SEITEN) + phase
			var richtung := quer * cos(w) * radius.x + laengs * sin(w) * radius.y
			var p := ring_mitte + richtung * weite
			p.y = y
			var aussen := richtung.normalized()
			var v := GelaendeSaum.verschiebung(p)
			p += aussen * (v * 0.6 - (1.0 - GelaendeSaum.schicht_vortritt(p)) * 0.2)
			reihe.append(p)
			fr.append(_farbe(lerpf(0.62, 0.8, t) * lerpf(0.8, 1.05, 0.5 + 0.5 * v), 0.1 * (1.0 - t),
					0.25 + 0.3 * t, 0.0))
			uv.append(Vector2(0.0, maxf(kante - y, 0.0)))
		reihen.append(reihe)
		farben.append(fr)
		uv2.append(uv)
	# Oben: ein gerundeter Rand und ein flacher Deckel – oder eine unebene,
	# runde Kuppe aus zwei enger werdenden Ringen.
	var letzte := reihen[reihen.size() - 1]
	var mitte_oben := Vector3(mitte.x, oben_y, mitte.z)
	var kuppe := PackedVector2Array([Vector2(0.14, 0.0)]) if flach \
			else PackedVector2Array([Vector2(0.3, -0.1), Vector2(0.62, 0.25)])
	var rand := PackedVector3Array()
	var rand_f := PackedColorArray()
	for stufe: Vector2 in kuppe:
		rand = PackedVector3Array()
		rand_f = PackedColorArray()
		var rand_uv := PackedVector2Array()
		for k in letzte.size():
			var p := letzte[k]
			var zur_mitte := mitte_oben - Vector3(p.x, oben_y, p.z)
			var buckel := 0.0 if flach else 0.25 * GelaendeSaum.verschiebung(p * 1.7)
			var y := oben_y + stufe.y + buckel
			rand.append(Vector3(p.x, y, p.z) + zur_mitte * stufe.x)
			rand_f.append(_farbe(0.84, 0.25, 0.95, 0.45))
			rand_uv.append(Vector2(0.0, maxf(kante - y, 0.0)))
		reihen.append(rand)
		farben.append(rand_f)
		uv2.append(rand_uv)
	if not flach:
		mitte_oben.y += 0.45
	var g := {"reihen": reihen, "farben": farben, "uv2": uv2, "vorzeichen": 1.0}
	# Vorzeichen so, dass die Normalen aus der Nadel zeigen.
	var a := reihen[1]
	var b := reihen[2]
	var f := (a[1] - a[0]).cross(b[0] - a[0])
	var nach_aussen := a[0] - Vector3(mitte.x, a[0].y, mitte.z)
	if f.dot(nach_aussen) < 0.0:
		g["vorzeichen"] = -1.0
	var norm := GelaendeSaum.normalen(g)
	GelaendeSaum.gitter_schreiben(st, g, norm, 0, reihen.size() - 1)
	var deckel_f := _farbe(0.86, 0.2, 1.0, 0.6)
	var uv_oben := Vector2(0.0, maxf(kante - oben_y, 0.0))
	for k in rand.size() - 1:
		GelaendeSaum.dreieck(st, mitte_oben + Vector3.UP * 0.05, rand[k], rand[k + 1], Vector3.UP,
				deckel_f, rand_f[k], rand_f[k + 1], uv_oben, uv_oben, uv_oben)


## Die Oberseiten der Vorsprünge: Rasen bündig mit der Decke von der
## Wegkante bis unter die Grasnarbe der Lippe; zur Spitze hin tritt Fels
## durch.
static func _vorsprung_flaechen(st: Stuecke, level: Level01) -> void:
	for name: String in ["Vorsprung 62", "Vorsprung 75", "Vorsprung 89"]:
		var e := level.begehbar(name)
		if e.is_empty():
			continue
		var umriss: Array = e["aussen"]
		var von: float = e["von"]
		var bis: float = e["bis"]
		var schritte := maxi(ceili((bis - von) / 0.35), 2)
		var reihen: Array[PackedVector3Array] = []
		var farben: Array[PackedColorArray] = []
		var uv2: Array[PackedVector2Array] = []
		var strecken := PackedFloat32Array()
		for k in schritte + 1:
			var s := lerpf(von, bis, float(k) / float(schritte))
			var kante := level.boden_bei(s)
			var innen := _wegrand(level, s) - 0.35
			var aussen := maxf(_polylinie(umriss, s) - 0.25, innen + 0.01)
			var reihe := PackedVector3Array()
			var fr := PackedColorArray()
			var uv := PackedVector2Array()
			for m in 7:
				var t := float(m) / 6.0
				var q := lerpf(innen, aussen, t)
				var w := LevelWerkzeuge.punkt_frei(level.verlauf, s, q)
				w.y = kante - 0.012
				reihe.append(w)
				var spitze := smoothstep(0.55, 1.0, t) * smoothstep(1.2, 2.2, aussen - innen)
				var fleck := 0.5 + 0.5 * GelaendeSaum.verschiebung(w * 1.7)
				fr.append(_farbe(lerpf(0.78, 0.86, spitze), 0.0, 0.7 * spitze,
						1.0 - 0.75 * spitze * smoothstep(0.3, 0.7, fleck)))
				uv.append(Vector2(0.0, 0.0))
			reihen.append(reihe)
			farben.append(fr)
			uv2.append(uv)
			strecken.append(s)
		var g := {"reihen": reihen, "farben": farben, "uv2": uv2, "s": strecken,
				"vorzeichen": GelaendeSaum.vorzeichen(reihen)}
		var norm := GelaendeSaum.normalen(g)
		GelaendeSaum.gitter_schreiben(st.opak(_stueck("Rechts", (von + bis) * 0.5)), g, norm,
				0, reihen.size() - 1)


static func _polylinie(punkte: Array, s: float) -> float:
	for i in punkte.size() - 1:
		var a: Vector2 = punkte[i]
		var b: Vector2 = punkte[i + 1]
		if s >= a.x and s <= b.x:
			if b.x - a.x < 0.0001:
				return b.y
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	var letzter: Vector2 = punkte[punkte.size() - 1]
	var erster: Vector2 = punkte[0]
	return letzter.y if s >= letzter.x else erster.y


# ================================================================ Links

## Der Fuß links als Polylinie [Vector2(s, q)] (q negativ): Böschung,
## Nische, Felsnase, Fallklamm mit dem Becken, Knick nach außen bei 160.
static func _fuss_links(_level: Level01) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v: Vector2 in [
			Vector2(27.7, -5.0), Vector2(77.2, -5.0),
			# Nische der Moosbank (wie die Leitlinie)
			Vector2(78.0, -5.3), Vector2(82.0, -9.5), Vector2(84.0, -11.0), Vector2(92.0, -11.0),
			Vector2(95.0, -8.0), Vector2(98.0, -5.3),
			# Felsnase, dann die Fallklamm
			Vector2(103.6, -5.3), Vector2(104.4, -4.6),
			# Felsbecken unter dem Wasserfallpfeiler
			Vector2(111.4, -4.6), Vector2(112.6, -5.8), Vector2(113.6, -8.2), Vector2(114.6, -9.6),
			Vector2(115.6, -10.0), Vector2(119.6, -10.0), Vector2(120.7, -9.3),
			Vector2(121.7, -7.2), Vector2(122.5, -5.2), Vector2(123.1, -4.6),
			Vector2(133.0, -4.6), Vector2(133.5, -4.9), Vector2(145.0, -4.9),
			Vector2(145.5, -5.1), Vector2(150.0, -5.55), Vector2(157.6, -6.4),
			# Vor dem linken Torriesen (s 162, q −9) nach außen
			Vector2(158.6, -6.7), Vector2(159.35, -7.3), Vector2(159.8, -8.5),
			Vector2(160.0, -10.2), Vector2(160.1, -12.6), Vector2(160.15, -15.0)]:
		p.append(v)
	return p


## Anteil des Beckens (0..1) an der Strecke `s`.
static func _becken(s: float) -> float:
	return smoothstep(112.4, 114.0, s) * (1.0 - smoothstep(120.4, 122.2, s))


## Anteil des Wasserfallpfeilers (0..1).
static func _pfeiler(s: float) -> float:
	return smoothstep(112.0, 114.6, s) * (1.0 - smoothstep(119.6, 122.0, s))


## Welt-Y der Krone links: glatte Kurve + Wandhöhe (RAENDER), am Anfang aus
## dem Waldboden wachsend, am Pfeiler +11 m.
static func _krone_links(level: Level01, s: float) -> float:
	return LevelWerkzeuge.punkt(level.verlauf, s).y + _hoehe_links(level, s) \
			+ _pfeiler(s) * PFEILER_HOEHE


## Wandhöhe links über der Kurve (RAENDER "hoehe"), über ±6 m gemittelt: An
## den Grenzen der Einträge springt sie (Böschung 6 m → Felsnase 3 m bei 92,
## Felsnase 5 m → Fallklamm 2 m bei 104), und die Krone stünde dort als
## Stufe quer im Bild. Die Böschung wächst hinter dem Erdspalt aus dem
## Waldboden; am Wasserfallpfeiler ist die Wand um `_pfeiler` höher.
static func _hoehe_links(level: Level01, s: float) -> float:
	var summe := 0.0
	var gewicht := 0.0
	for k in range(-4, 5):
		var g := 1.0 - absf(float(k)) / 5.0
		var sk := clampf(s + float(k) * 1.5, 33.0, 159.9)
		summe += float(level.rand_profil(sk, -1.0)["hoehe"]) * g
		gewicht += g
	var hoehe := summe / gewicht
	# Die Krone der Böschung wogt um ±1,6 m (Wellen von 25–40 m): keine
	# Linie in gleicher Höhe neben dem Weg.
	hoehe += 1.6 * _welle(s * 0.033, 41.0) * smoothstep(36.0, 44.0, s) \
			* (1.0 - smoothstep(84.0, 91.0, s))
	if s < 41.0:
		hoehe *= lerpf(0.03, 1.0, smoothstep(27.7, 41.0, s))
	# Eine Scharte in der Krone der Fallklamm: Durch sie blickt das
	# Schlussbild (Kronentor, s 281) zurück auf den Grat – sonst verstellte
	# die Krone bei s 126–134 den Weg des Grats um bis zu 2 m.
	var d := (s - SCHARTE.x) / SCHARTE.z
	hoehe -= SCHARTE.y * exp(-d * d)
	return hoehe * (1.0 - _pfeiler(s))


## Die linke Seite: Böschung, Felsnase, Felswand, Becken.
static func _links(level: Level01) -> void:
	_linien_anlegen(level)
	var st := Stuecke.new(_wurzel(level), "Links")
	var proben := GelaendeSaum.linie(level.verlauf, _fuss, SCHRITT_LINKS, _feste_s())
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, -1.0,
			_profil_links.bind(level), _kante.bind(level), _kronen.bind(level))
	GelaendeSaum.merken(-1.0, g)
	var norm := GelaendeSaum.normalen(g)
	_gitter_in_stuecke(st, "Links", g, norm)
	_deckel_an_enden(st, "Links", g)
	_boeschung_steine(st, proben, g, norm)
	_abbrueche(st, proben, g, norm)
	_becken_sims(st, level)
	st.fertig(SICHT, FERN_AB, SICHT_KARTEN, SICHT_RAND)
	_bau["links_proben"] = proben
	_bau["links_g"] = g


## Der Bewuchs der linken Seite (eigener Schritt).
static func _links_bewuchs(level: Level01) -> void:
	var proben: Array[Dictionary] = _bau["links_proben"]
	var g: Dictionary = _bau["links_g"]
	_bewuchs_links(level, proben, g)
	_bau.erase("links_proben")
	_bau.erase("links_g")


## Das Profil links (26 Punkte): 0 Schulter unter der Decke (absolut),
## 1 Rasen vor dem Fuß, 2 Zehe, 3 Fuß, 4–19 Hang bzw. Wand, 20 Kronenkante,
## 21–25 Krone, die flach in den Hang ausläuft.
static func _profil_links(_i: int, probe: Dictionary, level: Level01) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var bogen: float = probe["bogen"]
	var q_linie := absf(float(probe["q"]))
	var kante := level.boden_bei(s)
	var wegrand := _wegrand(level, s)
	var krone := _krone_links(level, s)
	var fels := smoothstep(90.5, 93.5, s)
	var p: GelaendeSaum.Profil
	# Die Rinne der Kerbe senkt die Böschung schon vor und nach der Lücke
	# ein: ein Graben, der den Hang herabkommt, kein Schlitz.
	var abseits := maxf(56.0 - s, s - 59.0)
	var rinne := 1.0 - smoothstep(0.0, 2.2, abseits) if abseits > 0.0 else 0.0
	if fels <= 0.0:
		p = _profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne)
	elif fels >= 1.0:
		p = _profil_wand(s, bogen, q_linie, kante, wegrand, krone)
	else:
		p = _profil_boeschung(bogen, q_linie, kante, wegrand, krone, rinne).gemischt(
				_profil_wand(s, bogen, q_linie, kante, wegrand, krone), fels)
	var grund := _luecken_grund(s)
	if not is_nan(grund):
		if s < 100.0:
			# Kerbe: eine Rinne, die die Böschung hinaufläuft – ein V, das
			# zur Mitte der Lücke tiefer wird; nur unter dem Weg senkrecht.
			var rand := clampf((absf(s - 57.5) - 0.2) / 1.3, 0.0, 1.0)
			_in_luecke(p, grund, 0, p.anzahl() - 1, 2.2, rand)
		else:
			# Fallkerbe: Nur der Grund des Beckens läuft in die Kerbe aus.
			_in_luecke(p, grund, 0, 2, 0.0)
	# In der Nische liegen alle Punkte in der Querebene des Weges: An ihren
	# hohlen Ecken liefen weit außen liegende Punkte sonst aufeinander zu,
	# und das Gitter faltete sich zu Stufen.
	var nische := smoothstep(76.0, 78.0, s) * (1.0 - smoothstep(98.0, 100.0, s))
	if nische > 0.0:
		for j in range(1, p.anzahl()):
			if p.absolut[j] == 0:
				p.o[j] = -(q_linie + p.o[j])
				p.absolut[j] = 1
	return p


## BOESCHUNG: Rasen bis an den Fuß, ein Erdhang als Kosinus-S (am
## steilsten gut 50°), oben Waldboden.
static func _profil_boeschung(bogen: float, q_linie: float, kante: float,
		wegrand: float, krone: float, rinne: float) -> GelaendeSaum.Profil:
	var h := maxf(krone - kante, 0.12)
	var voll := smoothstep(0.5, 3.5, h)
	var breite := maxf(lerpf(3.0, 11.0 - q_linie, voll), 2.6 + h * 0.55)
	# Die Breite wandert um ±22 %, und alle 15–25 m tritt ein Sporn vor
	# oder weicht eine Rinne zurück (oben am Hang, bis gut einen Meter)
	breite *= 1.0 + 0.22 * _welle(bogen * 0.035, 42.0) * voll
	var sporn := 1.1 * _welle(bogen * 0.055, 43.0) * voll
	var p := GelaendeSaum.Profil.new()
	p.punkt(-(wegrand - 0.35), kante - 0.03, _farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0, 1.0, 0.0, true)
	p.punkt(-0.22, kante - 0.015, _farbe(0.78, 0.05, 0.2, 1.0))
	p.punkt(0.05, kante + 0.02, _farbe(0.74, 0.2, 0.45, 0.85), 0.4, 0.05, 2.0)
	p.punkt(0.3, kante + 0.12, _farbe(0.7, 0.35, 0.5, 0.7), 0.6, 0.12, 2.0)
	for k in 16:
		var t := float(k + 1) / 16.0
		var f := 0.5 - 0.5 * cos(PI * t)
		var steil := sin(PI * t)
		# Buckel und Mulden entlang des Hangs.
		var buckel := 0.35 * _welle(bogen * 0.3 + t * 2.6, 8.0)
		# Rasen und Moos, wo es flacher ist; Erde bricht in Flecken durch,
		# wo der Hang steil ist oder das Rauschen es will.
		var gras := clampf(0.85 - 0.5 * steil + 0.55 * _welle(bogen * 0.26 + t * 2.1, 16.0),
				0.0, 1.0)
		var erde := clampf(0.2 + 0.65 * steil - 0.35 * gras, 0.08, 0.9)
		var y := kante + 0.12 + (h - 0.12) * f
		y -= 1.2 * rinne * smoothstep(0.05, 0.3, t) * (1.0 - smoothstep(0.75, 1.0, t))
		p.punkt(0.3 + (breite - 0.3) * t + buckel + sporn * smoothstep(0.25, 0.75, t), y,
				_farbe(lerpf(0.7, 0.86, t) * lerpf(1.0, 0.88, steil) * lerpf(1.0, 0.9, rinne),
				lerpf(erde, 0.8, rinne * 0.6), 0.6, gras * (1.0 - rinne * 0.6)),
				lerpf(0.8, 2.5, t), lerpf(0.3, 0.4, t), 1.0 if t > 0.25 else 2.0)
	# Kronenkante und Krone (20–25)
	var k0 := breite + sporn
	for k in 6:
		var weiter: float = KRONE_WEITE_B[k]
		var hoch: float = KRONE_HOCH_B[k] * voll
		p.punkt(k0 + weiter, krone + hoch, _farbe(0.78, 0.3, 0.75, lerpf(0.85, 0.6, float(k) / 5.0)),
				maxf(2.5, k0 + weiter), 0.3)
	return p


## FELS_AUF: Schichtfelswand mit zwei Simsen und einem Überhang, der erst
## ab 10 m über dem Weg vortritt. Im Becken steht sie auf dessen Grund.
static func _profil_wand(s: float, bogen: float, q_linie: float, kante: float,
		wegrand: float, krone: float) -> GelaendeSaum.Profil:
	var becken := _becken(s)
	var fuss_y := lerpf(kante, BECKEN_Y, becken)
	var h := maxf(krone - fuss_y, 0.6)
	var ueber_weg := krone - kante
	var p := GelaendeSaum.Profil.new()
	p.punkt(-(wegrand - 0.35), lerpf(kante - 0.03, BECKEN_Y - 0.03, becken),
			_farbe(0.78, 0.0, 0.05, 1.0 - becken).lerp(_farbe(0.35, 0.4, 0.2, 0.0), becken),
			0.0, 0.0, 1.0, 0.0, true)
	p.punkt(-0.25, lerpf(kante - 0.015, BECKEN_Y, becken),
			_farbe(0.76, 0.1, 0.25, 1.0).lerp(_farbe(0.42, 0.45, 0.3, 0.0), becken))
	p.punkt(0.0, fuss_y + 0.04, _farbe(0.6, 0.55, 0.5, 0.3 * (1.0 - becken)), 0.4, 0.05, 2.0)
	p.punkt(0.12, fuss_y + 0.35, _farbe(0.55, 0.25, 0.35, 0.0), 0.6, 0.15, 2.0, 0.15)
	# Simse und Überhang, sanft eingeblendet, damit benachbarte Querschnitte
	# gleich gebaut sind.
	var ka := smoothstep(5.5, 8.0, h)
	var kb := smoothstep(9.0, 11.5, h)
	var ha := clampf(4.2 + 0.8 * _welle(bogen * 0.09, 9.0), 0.4, 0.38 * h)
	var hb := clampf(ha + 4.4 + 0.8 * _welle(bogen * 0.08, 10.0), ha + 0.6, 0.66 * h)
	# Senkrechte Klüfte schneiden die Simse ab und treten 0,8 m zurück
	# (vom Weg weg), erst ab gut 4 m Wandhöhe.
	var kluft := _kluft(bogen, 32.0) * smoothstep(4.0, 6.5, h) * (1.0 - _pfeiler(s))
	var zurueck := 0.8 * kluft
	# Die Simse setzen aus (Stücke von 3–8 m)
	var da := smoothstep(-0.35, 0.2, _welle(bogen * 0.075, 33.0))
	var db := smoothstep(-0.35, 0.2, _welle(bogen * 0.085, 34.0))
	var wa := (0.5 + 0.35 * (1.0 + _welle(bogen * 0.12, 11.0))) * ka * (1.0 - 0.7 * becken) \
			* (1.0 - kluft) * lerpf(0.15, 1.0, da)
	var wb := (0.45 + 0.35 * (1.0 + _welle(bogen * 0.1, 12.0))) * kb * (1.0 - 0.7 * becken) \
			* (1.0 - kluft) * lerpf(0.15, 1.0, db)
	var zone := minf(2.4, 0.3 * h)
	var oben := h - zone
	# Überhang nur ab 10 m über dem Weg, höchstens so weit, dass die Kante
	# nicht näher als 2,8 m an die Wegmitte kommt.
	var ovd := 1.4 * smoothstep(10.2, 12.0, h) * smoothstep(10.0, 11.0, ueber_weg - zone)
	ovd = minf(ovd, q_linie + _wand_o(oben) + wa + wb - 2.8)
	ovd = maxf(ovd, 0.0)
	var kl := 1.0 - 0.35 * kluft
	var wand := _farbe(0.72 * kl, 0.0, 0.22, 0.0)
	var ecke := _farbe(0.5 * kl, 0.15, 0.5, 0.0)
	var sims := _farbe(0.9 * kl, 0.3, 1.0, 0.0)
	var zr := zurueck
	# 4–7: bis zum ersten Sims
	p.punkt(_wand_o(ha * 0.5) + zr * 0.5, fuss_y + ha * 0.5, wand, 1.0, 0.5, 2.0, 0.16)
	p.punkt(_wand_o(ha) - 0.03 + zr, fuss_y + ha - 0.12 * ka, ecke, 1.4, 0.35, 2.0)
	p.punkt(_wand_o(ha) + wa * 0.85 + zr, fuss_y + ha, sims.lerp(wand, 1.0 - ka), 1.6, 0.25, 2.0)
	p.punkt(_wand_o(ha) + wa + zr, fuss_y + ha + 0.35 * ka, _farbe(0.8 * kl, 0.1, 0.5, 0.0), 1.6,
			0.3, 2.0)
	# 8–11: zum zweiten Sims
	var hm := (ha + 0.35 * ka + hb - 0.12 * kb) * 0.5
	p.punkt(_wand_o(hm) + wa + zr, fuss_y + hm, wand, 1.8, 0.55, 2.0, 0.16)
	p.punkt(_wand_o(hb) + wa - 0.03 + zr, fuss_y + hb - 0.12 * kb, ecke, 2.0, 0.35, 2.0)
	p.punkt(_wand_o(hb) + wa + wb * 0.85 + zr, fuss_y + hb, sims.lerp(wand, 1.0 - kb), 2.2, 0.25,
			2.0)
	p.punkt(_wand_o(hb) + wa + wb + zr, fuss_y + hb + 0.35 * kb, _farbe(0.8 * kl, 0.1, 0.5, 0.0),
			2.2, 0.3, 2.0)
	# 12–14: bis unter den Überhang
	var hc := hb + 0.35 * kb
	for k in 3:
		var t := float(k + 1) / 3.0
		var hh := lerpf(hc, oben, t)
		p.punkt(_wand_o(hh) + wa + wb + zr * (1.0 - t * 0.6), fuss_y + hh, wand, 2.4, 0.6, 2.0,
				0.16)
	# 15–19: Überhang und Kante
	var fo := _wand_o(oben) + wa + wb
	var dunkel := _farbe(0.34, 0.1, 0.0, 0.0)
	p.punkt(fo - 0.3 * ovd, fuss_y + h - zone * 0.7, wand.lerp(dunkel, minf(ovd, 1.0)), 2.4, 0.4, 2.0)
	p.punkt(fo - 0.85 * ovd, fuss_y + h - zone * 0.44, wand.lerp(dunkel, minf(ovd, 1.0) * 0.8),
			2.4, 0.35)
	p.punkt(fo - ovd, fuss_y + h - zone * 0.2, wand, 2.4, 0.3)
	p.punkt(fo - 0.9 * ovd, fuss_y + h - zone * 0.06, _farbe(0.8, 0.1, 0.6, 0.1), 2.4, 0.25)
	p.punkt(fo - 0.6 * ovd, fuss_y + h, _farbe(0.82, 0.25, 0.8, 0.3), 2.4, 0.2)
	# 20–25: Kronenkante und Krone. Hinter dem Pfeiler fällt die Krone
	# wieder auf die Höhe der Wand ab: ein Felsturm, kein Tafelberg.
	var turm := _pfeiler(s) * PFEILER_HOEHE
	for k in 6:
		var weiter: float = KRONE_WEITE_W[k]
		var hoch: float = KRONE_HOCH_W[k] - turm * smoothstep(0.5, 5.0, float(k)) * 0.9
		p.punkt(fo - 0.6 * ovd + weiter, fuss_y + h + hoch,
				_farbe(0.78, 0.12, 0.8, lerpf(0.75, 0.55, float(k) / 5.0)),
				maxf(2.5, fo + weiter), 0.3 + 0.3 * _pfeiler(s))
	return p


## Versatz der Felswand links in der Höhe `hh` über dem Fuß: gut 2° nach
## hinten geneigt.
static func _wand_o(hh: float) -> float:
	return 0.12 + 0.035 * hh


## Steine in der Böschung: kantig (gebrochener Fels, keine Kartoffeln), zu
## gut 60 % im Hang, zur Hangneigung gekippt, in Gruppen – je ein großer
## (0,9–1,4 m) mit zwei, drei kleinen daneben –, alle 7–13 m eine Gruppe.
static func _boeschung_steine(st: Stuecke, proben: Array[Dictionary], g: Dictionary,
		norm: Array[PackedVector3Array]) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var boden: PackedFloat32Array = g["boden"]
	var rng := PropWerkzeug.zufall(8401)
	var i := 4
	while i < reihen.size() - 4:
		var s: float = proben[i]["s"]
		if s < 34.0 or s > 91.0 or (s > 54.5 and s < 60.5):
			i += 2
			continue
		var j := rng.randi_range(7, 15)
		var zahl := rng.randi_range(3, 4)
		for k in zahl:
			var gross := k == 0
			var ii := clampi(i + (0 if gross else rng.randi_range(-3, 3)), 0, reihen.size() - 1)
			var jj := clampi(j + (0 if gross else rng.randi_range(-2, 2)), 5, 17)
			var p := reihen[ii][jj]
			var n := norm[ii][jj]
			var r := rng.randf_range(0.9, 1.4) if gross else rng.randf_range(0.25, 0.5)
			var hoch := n.lerp(Vector3.UP, 0.3).normalized()
			var basis := Basis(Quaternion(Vector3.UP, hoch)) * Basis(Vector3.UP, rng.randf() * TAU)
			var mass := Vector3(r * rng.randf_range(1.0, 1.4), r * rng.randf_range(0.6, 0.85),
					r * rng.randf_range(0.85, 1.2))
			GelaendeSaum.stein(st.opak(_stueck("Links", float(proben[ii]["s"]))),
					p - hoch * mass.y * 0.25, mass, basis, rng.randi_range(1, 900),
					_farbe(0.84, 0.0, 0.5, 0.0), boden[ii], 0.0, true)
		i += rng.randi_range(10, 18)


## Abbruchkanten in der Böschung: Hier und da ist der Hang abgerutscht,
## und eine Grasnarbe steht als kleine Kante über dunkler Erde, aus der
## Wurzeln hängen – dieselbe Kante wie an der Lippe rechts, nur klein. Je
## Kante 3–7 m lang, auf einer Höhenlinie des Hangs, zu den Enden hin
## auslaufend.
static func _abbrueche(st: Stuecke, proben: Array[Dictionary], g: Dictionary,
		norm: Array[PackedVector3Array]) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var boden: PackedFloat32Array = g["boden"]
	var rng := PropWerkzeug.zufall(8471)
	var i := rng.randi_range(4, 14)
	while i < reihen.size() - 14:
		var s: float = proben[i]["s"]
		if s < 36.0 or s > 89.0 or (s > 52.0 and s < 62.0):
			i += 3
			continue
		var laenge := rng.randi_range(7, 11)
		var j := rng.randi_range(8, 12)
		var hoch := rng.randf_range(0.6, 1.0)
		var name := _stueck("Links", s)
		var vorher := PackedVector3Array()
		var vorher_f := PackedColorArray()
		for k in laenge + 1:
			var ii := i + k
			var t := float(k) / float(laenge)
			var mass := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(0.7, 1.0, t))
			# Im Grundriss ein Bogen: in der Mitte den Hang hinauf
			var jb := j + int(round(2.0 * sin(t * PI)))
			var p := reihen[ii][jb]
			var n := norm[ii][jb]
			var runter := reihen[ii][jb - 2] - reihen[ii][jb + 2]
			runter.y = 0.0
			runter = runter.normalized()
			var h := hoch * mass
			# Grasnarbe, darunter eine senkrechte Erdwand zum Hang hin (kein
			# Unterschnitt: der lag im Schatten und las sich als Loch), deren
			# Fuß im Hang steckt
			var reihe := PackedVector3Array([
					p + n * 0.02 - runter * 0.3,
					p + n * (0.03 + h * 0.15) + runter * (0.05 + h * 0.3),
					p + runter * (0.1 + h * 0.45) + Vector3.DOWN * h * 0.2,
					p + runter * (0.12 + h * 0.48) + Vector3.DOWN * h * 0.95,
					p + runter * (0.2 + h * 0.5) - n * 0.2 + Vector3.DOWN * (h + 0.1)])
			# Die Abbruchfläche ist Erde, keine Höhle: braun, nicht schwarz
			var f := PackedColorArray([_farbe(0.8, 0.1, 0.4, 0.9), _farbe(0.78, 0.2, 0.4, 0.85),
					_farbe(0.55, 0.9, 0.15, 0.1), _farbe(0.44, 1.0, 0.05, 0.0),
					_farbe(0.36, 1.0, 0.0, 0.0)])
			if not vorher.is_empty():
				for m in reihe.size() - 1:
					var aussen := (reihe[m] + reihe[m + 1]) * 0.5 - (p - n * 0.1)
					var uv := Vector2(0.0, maxf(boden[ii] - p.y, 0.0))
					GelaendeSaum.dreieck(st.opak(name), vorher[m], vorher[m + 1], reihe[m], aussen,
							vorher_f[m], vorher_f[m + 1], f[m], uv, uv, uv)
					GelaendeSaum.dreieck(st.opak(name), vorher[m + 1], reihe[m + 1], reihe[m], aussen,
							vorher_f[m + 1], f[m + 1], f[m], uv, uv, uv)
				# Wurzeln unter der kleinen Narbe
				if mass > 0.5 and rng.randf() < 0.55:
					var laengs := (reihe[2] - vorher[2]).normalized()
					var ton := Color(0.42, 0.32, 0.23) * rng.randf_range(0.8, 1.1)
					GelaendeSaum.karte(st.karten(name), reihe[2] - runter * 0.05, Vector3.DOWN
							+ runter * 0.1, laengs, rng.randf_range(0.2, 0.5) * mass,
							rng.randf_range(0.25, 0.5), GelaendeSaum.ATLAS_WURZEL, ton)
			vorher = reihe
			vorher_f = f
			# Unter der Mitte liegt, was abgebrochen ist
			if k == laenge / 2:
				for m in rng.randi_range(2, 3):
					var jj := clampi(j - 3 - rng.randi_range(0, 2), 4, 18)
					var iq := clampi(ii + rng.randi_range(-2, 2), 0, reihen.size() - 1)
					var r := rng.randf_range(0.2, 0.42)
					GelaendeSaum.stein(st.opak(name), reihen[iq][jj] - norm[iq][jj] * r * 0.3,
							Vector3(r * 1.3, r * 0.7, r), Basis(norm[iq][jj].cross(Vector3.RIGHT)
							.normalized() if absf(norm[iq][jj].x) < 0.9 else Vector3.FORWARD,
							rng.randf_range(0.2, 0.6)) * Basis(Vector3.UP, rng.randf() * TAU),
							rng.randi_range(1, 900), _farbe(0.78, 0.35, 0.3, 0.0), boden[iq], 0.0,
							true)
		# Abbrüche alle 20–30 m, nicht als Kratzer an jeder Ecke
		i += laenge + rng.randi_range(24, 36)


## Der niedrige Felssims zwischen Weg und Becken (Deckenhöhe, Kollision ist
## die Schulter des Rohbaus), innen senkrecht in das Becken.
static func _becken_sims(st: Stuecke, level: Level01) -> void:
	for bereich: Vector2 in [Vector2(112.2, 118.0), Vector2(121.0, 122.6)]:
		var proben := GelaendeSaum.linie(level.verlauf,
				PackedVector2Array([Vector2(bereich.x, -5.0), Vector2(bereich.y, -5.0)]), 0.5)
		var g := GelaendeSaum.querschnitte(level.verlauf, proben, -1.0,
				_profil_sims.bind(level), _kante.bind(level), _kronen.bind(level))
		var norm := GelaendeSaum.normalen(g)
		var name := _stueck("Links", (bereich.x + bereich.y) * 0.5)
		GelaendeSaum.gitter_schreiben(st.opak(name), g, norm, 0, proben.size() - 1)
		var reihen: Array[PackedVector3Array] = g["reihen"]
		var farben: Array[PackedColorArray] = g["farben"]
		var boden: PackedFloat32Array = g["boden"]
		for ende in 2:
			var i := 0 if ende == 0 else reihen.size() - 1
			var nachbar := 1 if ende == 0 else reihen.size() - 2
			var aussen := reihen[i][3] - reihen[nachbar][3]
			aussen.y = 0.0
			GelaendeSaum.deckel(st.opak(name), reihen[i], farben[i], aussen.normalized(), boden[i])


static func _profil_sims(_i: int, probe: Dictionary, level: Level01) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var kante := level.boden_bei(s)
	var wegrand := _wegrand(level, s)
	var p := GelaendeSaum.Profil.new()
	var a := true
	p.punkt(-(wegrand - 0.35), kante - 0.03, _farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0, 1.0, 0.0, a)
	p.punkt(-(wegrand + 0.1), kante - 0.015, _farbe(0.78, 0.0, 0.2, 1.0), 0.0, 0.0, 1.0, 0.0, a)
	p.punkt(-4.45, kante - 0.02, _farbe(0.8, 0.1, 0.6, 0.6), 0.0, 0.0, 1.0, 0.0, a)
	p.punkt(-4.95, kante - 0.06, _farbe(0.8, 0.0, 0.85, 0.1), 0.0, 0.06, 1.0, 0.0, a)
	p.punkt(-5.25, kante - 0.32, _farbe(0.66, 0.0, 0.5, 0.0), 0.0, 0.1, 1.0, 0.1, a)
	p.punkt(-5.4, lerpf(kante, BECKEN_Y, 0.5), _farbe(0.5, 0.1, 0.3, 0.0), 0.0, 0.12, 1.0, 0.15, a)
	p.punkt(-5.5, BECKEN_Y + 0.3, _farbe(0.38, 0.3, 0.2, 0.0), 0.0, 0.08, 1.0, 0.0, a)
	p.punkt(-5.8, BECKEN_Y - 0.05, _farbe(0.34, 0.4, 0.1, 0.0), 0.0, 0.0, 1.0, 0.0, a)
	return p


## Bewuchs der linken Seite über `Schluchtsaum.bauen`: je Querschnitt ein
## `kronen`-Eintrag aus dem gebauten Profil. Die Innenkanten sind nie
## näher als 0,75 m an der Wegkante: Unter einem Überhang hinge eine Ranke
## sonst frei über dem Weg herab, und die Kamera fährt 6 m über der Figur.
##
## `Schluchtsaum` misst alle Höhen vom Punkt seiner Kurve aus. Die Decke
## liegt in den Terrassen aber bis 1,2 m neben dem Verlauf – Farne am
## Wandfuß stünden dort in der Luft oder im Boden. Deshalb bekommt er eine
## eigene Kurve durch die Decke (`_deckenkurve`), und die Strecken der
## Einträge werden auf sie umgerechnet.
static func _bewuchs_links(level: Level01, proben: Array[Dictionary], g: Dictionary) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var decke := _deckenkurve(level, 30.0, 162.0)
	var boeschung: Array = []
	var wand: Array = []
	for i in reihen.size():
		var s: float = proben[i]["s"]
		# Nicht am Anfang, in der Kerbe, am Pfeiler (dort fällt das Wasser)
		# und in der Fallkerbe, nicht im Knick am Ende.
		if s < 34.0 or s > 159.3 or (s > 55.0 and s < 60.0) or (s > 112.8 and s < 121.8):
			continue
		var e := _kronen_eintrag(level, s, reihen[i], decke)
		if s < 92.0:
			boeschung.append(e)
		else:
			wand.append(e)
	var wurzel := _wurzel(level)
	var kurve: Curve3D = decke["kurve"]
	# Auf der Böschung keine Blattballen (sie lesen sich als Kissen) und nur
	# wenige Wurzeln; Farne auf den Buckeln, am Fuß und an der Kante.
	var b := Schluchtsaum.bauen(wurzel, kurve, boeschung, {"saat": 8501,
			"laubfarbe": Farben.LAUB_HELL, "saum": 0.0, "ranken": 0.0, "wurzeln": 0.0,
			"vorhaenge": 0.0, "simse": 0.08, "fuss": 0.14, "blueten": 0.0})
	b.name = "Bewuchs Böschung"
	var w := Schluchtsaum.bauen(wurzel, kurve, wand, {"saat": 8502,
			"laubfarbe": Farben.LAUB_HELL, "saum": 0.0, "ranken": 0.3, "wurzeln": 0.0,
			"vorhaenge": 0.0, "simse": 0.3, "fuss": 0.28, "blueten": 0.0})
	w.name = "Bewuchs Felswand"
	for knoten: Node3D in [b, w]:
		for kind in knoten.get_children():
			if kind is GeometryInstance3D:
				var gi := kind as GeometryInstance3D
				gi.visibility_range_end = SICHT_BEWUCHS
				gi.visibility_range_end_margin = SICHT_RAND


## Eine Kurve durch die Wegdecke (XZ des Verlaufs, Y der Decke, alle 0,5 m
## ein Punkt, gerade Stücke dazwischen) von `von` bis `bis`, dazu die
## Umrechnung der Strecke: "alt" (Verlauf) → "neu" (diese Kurve).
static func _deckenkurve(level: Level01, von: float, bis: float) -> Dictionary:
	var kurve := Curve3D.new()
	kurve.bake_interval = 0.1
	var alt := PackedFloat32Array()
	var neu := PackedFloat32Array()
	var laenge := 0.0
	var vorher := Vector3.ZERO
	var s := von
	while s <= bis + 0.001:
		var p := LevelWerkzeuge.punkt(level.verlauf, s)
		p.y = level.boden_bei(s)
		if kurve.point_count > 0:
			laenge += p.distance_to(vorher)
		kurve.add_point(p)
		alt.append(s)
		neu.append(laenge)
		vorher = p
		s += 0.5
	return {"kurve": kurve, "alt": alt, "neu": neu}


## Strecke `s` des Verlaufs auf der Deckenkurve.
static func _auf_decke(decke: Dictionary, s: float) -> float:
	var alt: PackedFloat32Array = decke["alt"]
	var neu: PackedFloat32Array = decke["neu"]
	var i := clampi(int(floor((s - alt[0]) / 0.5)), 0, alt.size() - 2)
	var t := clampf((s - alt[i]) / maxf(alt[i + 1] - alt[i], 0.0001), 0.0, 1.0)
	return lerpf(neu[i], neu[i + 1], t)


## Ein Eintrag für `Schluchtsaum.bauen` aus einem Querschnitt links: Höhen
## relativ zur Decke, q als Abstand von der Mitte, "s" auf der Deckenkurve.
static func _kronen_eintrag(level: Level01, s: float, reihe: PackedVector3Array,
		decke: Dictionary) -> Dictionary:
	var mitte := LevelWerkzeuge.punkt(level.verlauf, s)
	mitte.y = level.boden_bei(s)
	var rechts := LevelWerkzeuge.richtung(level.verlauf, s).cross(Vector3.UP).normalized()
	var wegrand := _wegrand(level, s)
	var mindest := wegrand + 0.75
	var schichten: Array = []
	for j in range(3, 20):
		var a := reihe[j]
		var b := reihe[j + 1]
		var unten := minf(a.y, b.y) - mitte.y
		var oben := maxf(a.y, b.y) - mitte.y
		if oben - unten < 0.02:
			continue
		var qa := _quer_ab(a, mitte, rechts)
		var qb := _quer_ab(b, mitte, rechts)
		schichten.append([unten, oben, maxf(minf(qa, qb), mindest), qb < qa - 0.25])
	return {"s": _auf_decke(decke, s), "seite": -1.0, "oben": reihe[20].y - mitte.y,
			"innen": maxf(_quer_ab(reihe[20], mitte, rechts), mindest),
			"abstand": _quer_ab(reihe[3], mitte, rechts), "schichten": schichten,
			"weg_rand": wegrand + 0.1}


static func _quer_ab(p: Vector3, mitte: Vector3, rechts: Vector3) -> float:
	var d := p - mitte
	d.y = 0.0
	return absf(d.dot(rechts))


# ================================================================ Quer

## Stirnflächen der Lücken, Stufen und die Ufer der Furt (in die Stücke der
## rechten Kante).
static func _quer(st: Stuecke, level: Level01) -> void:
	# Kerbe und Fallkerbe: nur der Teil unter der Decke; die Seiten sind im
	# Profil der Kanten ausgeschnitten.
	_graben(st, level, 56.0, 59.0, KERBE_GRUND, -5.4, NAN, false, 5601)
	_graben(st, level, 118.0, 121.0, FALLKERBE_GRUND, -5.2, NAN, false, 11801)
	_erdspalt(st, level)
	for s: float in [66.0, 133.0, 145.0]:
		_stufe(st, level, s)
	_furt(st, level)


## Eine Wand quer zum Weg entlang `linie` [Vector2(s, q)], nach `vorwaerts`
## (+1: die Lücke liegt in +s) offen; `profil_bei` wie bei den Kanten.
static func _querwand(st: Stuecke, level: Level01, linie: PackedVector2Array,
		vorwaerts: float, profil_bei: Callable, name: String, saat: int,
		karten: bool = true, nach_maske: bool = false) -> Dictionary:
	var proben := GelaendeSaum.linie(level.verlauf, linie, SCHRITT_QUER)
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, -vorwaerts, profil_bei,
			_kante_quer.bind(level, linie[0].x), _kronen.bind(level))
	var norm := GelaendeSaum.normalen(g)
	GelaendeSaum.gitter_schreiben(st.opak(name), g, norm, 0, proben.size() - 1)
	GelaendeSaum.gitter_schreiben(st.fern(name), g, norm, 0, proben.size() - 1, 2)
	if karten:
		var reihen: Array[PackedVector3Array] = g["reihen"]
		var rng := PropWerkzeug.zufall(saat)
		for i in range(1, reihen.size() - 1):
			var reihe := reihen[i]
			var laengs := (reihen[i + 1][3] - reihen[i - 1][3])
			laengs.y = 0.0
			var aussen := reihe[3] - reihe[0]
			aussen.y = 0.0
			if laengs.length_squared() < 0.0001 or aussen.length_squared() < 0.0001:
				continue
			var vor := (reihe[3] - reihe[1]).dot(aussen.normalized()) / 0.6
			# Auf der ausgetretenen Spur hängt kein Gras über die Lippe.
			if nach_maske and rng.randf() > _rasen_anteil(level, proben[i]):
				continue
			_karten_an(st.karten(name), rng, reihe[2], reihe[4], aussen.normalized(),
					laengs.normalized(), 0.0, vor)
	return g


## Rasen (1) oder ausgetretene Spur (0) an einer Probe einer Querwand, nach
## der Wegmaske der Decke (`Wegmaske.wert`) – dieselbe Maske, die die Decke
## malt, so läuft die Spur über die Lippe weiter.
static func _rasen_anteil(level: Level01, probe: Dictionary) -> float:
	var s: float = probe["s"]
	var halb := maxf(level.breite_bei(s - 0.05), level.breite_bei(s + 0.05)) * 0.5
	if halb <= 0.0:
		return 1.0
	var p: Vector3 = probe["p"]
	return Wegmaske.wert(float(probe["q"]) / halb, s, Vector2(p.x, p.z))


static func _kante_quer(_i: int, _probe: Dictionary, level: Level01, s_kante: float) -> float:
	return level.boden_bei(s_kante)


## Der Graben unter einer Lücke: zwei Stirnwände und der Grund.
static func _graben(st: Stuecke, level: Level01, von: float, bis: float, grund: float,
		q_links: float, q_rechts: float, erdig: bool, saat: int) -> void:
	var halb := (bis - von) * 0.5
	var name := _stueck("Rechts", von)
	for ende in 2:
		var s := von if ende == 0 else bis
		# Rechts endet die Wand im Fels unter der Lippe: Dort steht am Rand
		# der Lücke noch die ganze Felskante (das Kerbtal beginnt voll und
		# wird zur Mitte tiefer, siehe `_profil_rechts`).
		var rechts := q_rechts
		if is_nan(rechts):
			rechts = _wegrand(level, s - 0.01 if ende == 0 else s + 0.01) - 0.55
		var linie := PackedVector2Array([Vector2(s, q_links), Vector2(s, rechts)])
		var kante := level.boden_bei(s - 0.01 if ende == 0 else s + 0.01)
		_querwand(st, level, linie, 1.0 if ende == 0 else -1.0,
				_profil_stirn.bind(kante, grund, halb, erdig, 0.45, level), name, saat + ende,
				true, true)


## STIRN: Grasnarbe, Erdband, Wand bis auf den Grund, der Grund bis zur
## Mitte der Lücke (16 Punkte).
## Mit `level` (Kerbe, Fallkerbe) folgt die Narbe der Wegmaske: Wo die
## Spur über die Lippe läuft, ist sie ausgetretene Erde, die kaum vorsteht
## und krümelig abbricht; daneben Rasen, der in Buckeln (0–0,4 m, 1–2 m
## lang) über die Kante hängt. Mit gleich breiter Grasnarbe quer über den
## Weg las sich die Lippe als grüner Bordstein.
static func _profil_stirn(_i: int, probe: Dictionary, kante: float, grund: float,
		halb: float, erdig: bool, innen: float = 0.45,
		level: Level01 = null) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var ov := _ueberhang_quer(bogen, 13.0)
	var r := 1.0
	if level != null:
		r = _rasen_anteil(level, probe)
		ov = clampf(0.2 + 0.3 * _welle(bogen * 0.9, 13.0) + 0.12 * _welle(bogen * 2.3, 18.0),
				0.03, 0.4)
		# Auf der Spur: krümelig abgebrochen, 4–24 cm hinaus, fast jeder
		# Querschnitt anders (mit 5–13 cm stand die Kante in der
		# Nahaufnahme als gerade Linie).
		ov = lerpf(0.04 + 0.2 * (0.5 + 0.5 * _welle(bogen * 1.7, 21.0)), ov, r)
	var e := 0.8 if erdig else 0.25
	var p := GelaendeSaum.Profil.new()
	# `innen` > 0,45: Die Narbe reicht weiter zurück, unter den Waldboden des
	# Geländes (Erdspalt, dessen Wände das Gelände dahinter nachzieht).
	p.punkt(-innen, kante - (0.03 if innen <= 0.45 else 0.05),
			_farbe(0.78, (1.0 - r) * 0.8, 0.05, r))
	p.punkt(ov * 0.4, kante - 0.006, _farbe(lerpf(0.66, 0.78, r), (1.0 - r) * 0.85, 0.2 * r, r))
	p.punkt(ov * 0.8, kante - lerpf(0.06, 0.035, r),
			_farbe(lerpf(0.52, 0.72, r), lerpf(0.9, 0.1, r), 0.3 * r, 0.95 * r))
	p.punkt(ov, kante - lerpf(0.18, 0.12, r), _farbe(0.5, lerpf(0.9, 0.6, r), 0.3 * r, 0.45 * r))
	# Flache Kerbe (Fallkerbe, gut 2 m): Man sieht die Wand bis aufs Wasser,
	# nasser, bemooster Fels statt eines schwarzen Schlitzes.
	var tief := kante - grund
	var nass := (1.0 - smoothstep(2.6, 4.0, tief)) if level != null else 0.0
	p.punkt(ov - 0.06, kante - 0.25, _farbe(lerpf(0.3, 0.42, nass), 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3, kante - 0.33, _farbe(lerpf(0.18, 0.36, nass), 1.0, 0.0, 0.0))
	p.punkt(-0.35, kante - 0.5, _farbe(lerpf(0.2, 0.38, nass), 1.0, 0.3 * nass, 0.0), 0.0,
			0.05, -1.0)
	p.punkt(-0.45, kante - 1.0, _farbe(lerpf(0.26, 0.42, nass), lerpf(maxf(e, 0.7), 0.3, nass),
			lerpf(0.1, 0.45, nass), 0.0), 0.0, 0.15, -1.0)
	for k in 5:
		var t := float(k) / 4.0
		var y := kante - lerpf(1.9, tief - 0.3, t)
		p.punkt(-0.5 + 0.1 * t, y, _farbe(lerpf(lerpf(0.3, 0.44, nass), lerpf(0.12, 0.3, nass), t),
				e, lerpf(0.15, 0.5, nass), 0.0), 0.0, 0.3, -1.0, 0.2 * (1.0 - e))
	p.punkt(-0.12, grund, _farbe(0.1, 0.7, 0.2, 0.0))
	p.punkt(halb * 0.6, grund - 0.02, _farbe(0.08, 0.8, 0.2, 0.0))
	p.punkt(halb + 0.05, grund - 0.05, _farbe(0.08, 0.8, 0.2, 0.0))
	return p


## Der Erdspalt (25,0–27,5): zwei Erdwände, die je Seite fünf Meter in den
## Waldboden laufen und dabei zusammenrücken, bis der Riss sich schließt.
static func _erdspalt(st: Stuecke, level: Level01) -> void:
	var name := _stueck("Rechts", 25.0)
	for ende in 2:
		var linie := PackedVector2Array()
		var q := -10.6
		while q <= 10.61:
			linie.append(Vector2(erdspalt_linie(q, ende), q))
			q += 0.4
		var kante := level.boden_bei(25.0 if ende == 0 else 27.5)
		_querwand(st, level, linie, 1.0 if ende == 0 else -1.0,
				_profil_erdspalt.bind(kante, level), name, 2501 + ende)


## Die Lippe einer Wand des Erdspalts (`ende` 0 bei s 25, 1 bei 27,5) bei
## Querabstand `q`: Strecke s. Bis 5,2 m voll offen, dann rücken die Wände
## zusammen, bei 10,6 m schließt sich der Riss; ab 5,2 m mit Zacken. Die
## Wand selbst steht 0,4–0,5 m hinter der Lippe (Rauschen bis 0,3 m weiter
## zurück), die Narbe reicht `ERDSPALT_NARBE` zurück. Für das Gelände.
static func erdspalt_linie(q: float, ende: int) -> float:
	var aq := absf(q)
	var eng := pow(smoothstep(5.2, 10.6, aq), 0.8)
	var zacke := 0.18 * sin(q * 1.3 + float(ende) * 2.0) * smoothstep(5.2, 7.0, aq)
	return 25.0 + 1.24 * eng + zacke if ende == 0 else 27.5 - 1.24 * eng + zacke


static func _profil_erdspalt(i: int, probe: Dictionary, kante: float,
		_level: Level01) -> GelaendeSaum.Profil:
	var q: float = probe["q"]
	var aq := absf(q)
	var eng := pow(smoothstep(5.2, 10.6, aq), 0.8)
	var halb := 1.25 * (1.0 - eng) + 0.02
	# Zu den Enden hin wird der Riss auch flacher.
	var grund := lerpf(ERDSPALT_GRUND, kante - 2.5, smoothstep(0.55, 1.0, eng))
	return _profil_stirn(i, probe, kante, grund, halb, true, ERDSPALT_NARBE)


## Eine Stufe (66, 133, 145): Grasnarbe der oberen Decke, Fels bis auf die
## untere, unter deren Rand eingesteckt.
static func _stufe(st: Stuecke, level: Level01, s: float) -> void:
	var oben := level.boden_bei(s - 0.01)
	var unten := level.boden_bei(s + 0.01)
	var q := maxf(_wegrand(level, s - 0.01), _wegrand(level, s + 0.01)) + 0.55
	_querwand(st, level, PackedVector2Array([Vector2(s, -q), Vector2(s, q)]), 1.0,
			_profil_stufe.bind(oben, unten), _stueck("Rechts", s), int(s) * 13)


static func _profil_stufe(_i: int, probe: Dictionary, oben: float,
		unten: float) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var ov := _ueberhang_quer(bogen, 14.0)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, oben - 0.03, _farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, oben - 0.006, _farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, oben - 0.035, _farbe(0.72, 0.1, 0.3, 0.95))
	p.punkt(ov, oben - 0.12, _farbe(0.5, 0.6, 0.3, 0.45))
	p.punkt(ov - 0.06, oben - 0.24, _farbe(0.34, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.25, oben - 0.3, _farbe(0.28, 1.0, 0.05, 0.0))
	var h := oben - unten
	p.punkt(-0.25, oben - minf(0.42, h * 0.45), _farbe(0.32, 0.9, 0.1, 0.0), 0.0, 0.04, -1.0)
	p.punkt(-0.3, lerpf(oben, unten, 0.6), _farbe(0.45, 0.35, 0.2, 0.0), 0.0, 0.12, -1.0, 0.12)
	p.punkt(-0.28, unten + 0.06, _farbe(0.45, 0.45, 0.35, 0.0), 0.0, 0.06, -1.0)
	p.punkt(-0.1, unten - 0.015, _farbe(0.6, 0.3, 0.3, 0.4))
	p.punkt(0.3, unten - 0.03, _farbe(0.78, 0.0, 0.1, 0.9))
	p.punkt(0.6, unten - 0.035, _farbe(0.78, 0.0, 0.05, 1.0))
	return p


## Die Ufer der Furt (173 und 183): Grasnarbe, ein Sodenschnitt, ein
## Erdufer unter 40° zu einer Kiesterrasse an der Wasserlinie, darunter der
## Grund bis zur Mitte der Furt. Außerhalb der Decke (|q| > 6,4) biegt die
## Uferlinie zum Wasser hin aus, und ihre Enden tauchen bis |q| 10,6 in das
## Bachufer des Geländes – kein Graben mit Lineal-Kante und kein
## abgeschnittenes Ende. Steine liegen in kleinen Gruppen, halb versenkt.
static func _furt(st: Stuecke, level: Level01) -> void:
	var name := _stueck("Rechts", 178.0)
	var rng := PropWerkzeug.zufall(17301)
	for ende in 2:
		var s := 173.0 if ende == 0 else 183.0
		var vorwaerts := 1.0 if ende == 0 else -1.0
		var kante := level.boden_bei(s - 0.01 * vorwaerts)
		var linie := PackedVector2Array()
		var q := -FURT_ENDE_Q
		while q <= FURT_ENDE_Q + 0.001:
			linie.append(Vector2(furt_linie(q, ende), q))
			q += 0.4
		var g := _querwand(st, level, linie, vorwaerts, _profil_furt.bind(kante, ende), name,
				17310 + ende)
		# Frei bleibt der Anlauf auf den Trittstein dieses Ufers.
		var stein := level.begehbar("Furtstein %d" % (ende + 1))
		_furt_steine(st, name, g, ende, rng, float(stein.get("q", 0.0)))


## Steingruppen am Ufer der Furt (je 2–4, einer größer), auf Böschung und
## Terrasse, halb versenkt, zur Böschung gekippt; nicht im Anlauf auf die
## Trittsteine und nicht in einer Reihe.
static func _furt_steine(st: Stuecke, name: String, g: Dictionary, _ende: int,
		rng: RandomNumberGenerator, frei_q: float) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var boden: PackedFloat32Array = g["boden"]
	var norm := GelaendeSaum.normalen(g)
	var n := reihen.size()
	var gruppen := 0
	var i := rng.randi_range(2, 6)
	while i < n - 2 and gruppen < 7:
		var q_hier := lerpf(-FURT_ENDE_Q, FURT_ENDE_Q, float(i) / float(n - 1))
		if absf(q_hier - frei_q) < 2.2:
			i += 3
			continue
		gruppen += 1
		var zahl := rng.randi_range(2, 4)
		for k in zahl:
			var ii := clampi(i + rng.randi_range(-2, 2), 0, n - 1)
			# Böschung (5–6) oder Terrasse (7–8)
			var j := rng.randi_range(5, 8)
			var t := rng.randf()
			var p := reihen[ii][j].lerp(reihen[ii][j + 1], t)
			var nn := norm[ii][j]
			var r := rng.randf_range(0.4, 0.9) if k == 0 else rng.randf_range(0.15, 0.4)
			var hoch := nn.lerp(Vector3.UP, 0.35).normalized()
			var basis := Basis(Quaternion(Vector3.UP, hoch)) * Basis(Vector3.UP, rng.randf() * TAU)
			var mass := Vector3(r * rng.randf_range(1.0, 1.4), r * rng.randf_range(0.6, 0.85),
					r * rng.randf_range(0.85, 1.2))
			# gut die Hälfte steckt im Ufer
			GelaendeSaum.stein(st.opak(name), p - hoch * mass.y * 0.12, mass, basis,
					rng.randi_range(1, 900), _farbe(0.8, 0.15, 0.6, 0.0), boden[ii], 0.0, true)
		i += rng.randi_range(5, 11)


## Halbe Länge der Uferlinien der Furt (|q|) und die Höhe, auf die ihre
## Enden sinken (das Bachufer des Geländes); die Kiesterrasse liegt knapp
## über dem Wasser (6,0).
const FURT_ENDE_Q := 10.6
const FURT_ENDE_Y := 6.4
const FURT_TERRASSE := 6.12


## Die Uferlinie der Furt (`ende` 0 bei s 173, 1 bei 183) bei Querabstand
## `q`: Strecke s. Bis |q| 6,4 genau die Deckenkante, dahinter biegt sie
## bis 0,7 m zum Wasser hin aus. Für das Gelände.
static func furt_linie(q: float, ende: int) -> float:
	var aq := absf(q)
	var bogen := 0.7 * smoothstep(6.4, 9.0, aq) \
			+ 0.14 * sin(q * 1.1 + float(ende) * 2.0) * smoothstep(6.4, 7.6, aq)
	return 173.0 + bogen if ende == 0 else 183.0 - bogen


## Oberkante des Ufers der Furt bei `q` (`kante` = Decke an der Linie): Ab
## |q| 8,2 sinkt sie bis zum Ende auf das Bachufer. Für das Gelände.
static func furt_kante(q: float, kante: float) -> float:
	return lerpf(kante, FURT_ENDE_Y, smoothstep(8.2, FURT_ENDE_Q, absf(q)))


## Höhe der Uferfläche der Furt `d` Meter vor der Uferlinie (zum Wasser
## hin), `k` = Oberkante (`furt_kante`), ohne Überhang und Rauschen: die
## Stützstellen von `_profil_furt`. Für das Gelände (es bleibt darunter).
static func furt_hoehe(d: float, k: float) -> float:
	var stellen := _furt_stellen(k)
	if d <= stellen[0].x:
		return stellen[0].y
	for j in stellen.size() - 1:
		var a := stellen[j]
		var b := stellen[j + 1]
		if d <= b.x:
			return lerpf(a.y, b.y, clampf((d - a.x) / maxf(b.x - a.x, 0.0001), 0.0, 1.0))
	return stellen[stellen.size() - 1].y


## Bis zu diesem Abstand vor der Uferlinie der Furt liegt das Ufer über dem
## Bachbett des Geländes (danach taucht es unter).
static func furt_hoehe_bis(k: float) -> float:
	return _furt_stellen(k)[6].x


## Die Stützstellen des Ufers (Abstand vor der Linie, Welt-Y): Narbe, Soden-
## schnitt 0,35 m, 40°-Böschung, Kiesterrasse, unter Wasser zum Grund.
static func _furt_stellen(k: float) -> PackedVector2Array:
	var schnitt := minf(0.35, maxf(k - FURT_TERRASSE, 0.0) * 0.5)
	var boeschung := maxf(k - schnitt - FURT_TERRASSE, 0.0) / 0.84
	var t0 := 0.12 + boeschung
	return PackedVector2Array([Vector2(0.0, k - 0.03), Vector2(0.12, k - schnitt),
			Vector2(0.12 + boeschung * 0.5, lerpf(k - schnitt, FURT_TERRASSE, 0.5) + 0.04),
			Vector2(t0, FURT_TERRASSE), Vector2(t0 + 0.55, FURT_TERRASSE - 0.05),
			Vector2(t0 + 0.9, 5.6), Vector2(t0 + 1.4, 4.9), Vector2(t0 + 2.2, 4.5),
			Vector2(t0 + 3.4, 4.45), Vector2(t0 + 4.3, 4.4)])


## Das Ufer der Furt (14 Punkte): 0 Narbe über der Decke (reicht bis zur
## Deckenkante zurück, wo die Linie ausbiegt), 1–3 Narbe mit Überhang,
## 4 Sodenschnitt, 5–6 Böschung, 7–8 Kiesterrasse, 9–13 unter Wasser zum
## Grund.
static func _profil_furt(_i: int, probe: Dictionary, kante: float, ende: int) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var q: float = probe["q"]
	var k := furt_kante(q, kante)
	var ov := _ueberhang_quer(bogen, 15.0) * lerpf(1.0, 0.4, smoothstep(8.2, FURT_ENDE_Q, absf(q)))
	var zurueck := absf(furt_linie(q, ende) - (173.0 if ende == 0 else 183.0))
	var st := _furt_stellen(k)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45 - zurueck, k - 0.03, _farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, k - 0.006, _farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, k - 0.035, _farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, k - 0.12, _farbe(0.5, 0.65, 0.3, 0.4))
	# Sodenschnitt: Erde unter der Narbe, heller, mit Wurzeln
	p.punkt(ov - 0.05, st[1].y + 0.04, _farbe(0.58, 0.75, 0.2, 0.15), 0.0, 0.03)
	# Böschung unter 40°: Erde mit Moos und Gras, nach unten nasser
	p.punkt(st[2].x, st[2].y, _farbe(0.7, 0.55, 0.6, 0.45), 0.0, 0.1)
	p.punkt(st[3].x - 0.08, st[3].y + 0.05, _farbe(0.64, 0.6, 0.5, 0.2), 0.0, 0.1)
	# Kiesterrasse: hell, trocken, kaum Moos
	p.punkt(st[3].x + 0.1, st[3].y, _farbe(0.82, 0.35, 0.05, 0.0), 0.0, 0.06)
	p.punkt(st[4].x, st[4].y, _farbe(0.74, 0.4, 0.1, 0.0), 0.0, 0.06)
	# Unter der Wasserlinie taucht das Ufer unter das Bachbett des Geländes
	# (Bett 5,0–5,6): Den Grund der Furt zeichnet das Gelände, durchgehend
	# mit dem Bach, sonst lägen zwei Böden aufeinander.
	p.punkt(st[5].x, st[5].y, _farbe(0.4, 0.6, 0.35, 0.0), 0.0, 0.1)
	p.punkt(st[6].x, st[6].y, _farbe(0.34, 0.5, 0.3, 0.0), 0.0, 0.08)
	p.punkt(st[7].x, st[7].y, _farbe(0.32, 0.5, 0.3, 0.0), 0.0, 0.05)
	p.punkt(st[8].x, st[8].y, _farbe(0.3, 0.55, 0.3, 0.0))
	p.punkt(st[9].x, st[9].y, _farbe(0.3, 0.55, 0.3, 0.0))
	return p
