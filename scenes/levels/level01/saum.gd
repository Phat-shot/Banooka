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
##   Schichtfels 70–85° darunter, alle 4–6 m ein Sims (Moos), mit Pfeilern
##                und Rinnen aus 3D-Rauschen und Schichtbänkchen, die mit den
##                Farbbändern des Stoffs übereinanderliegen. Wo ein Rahmenbaum
##                auf einem Sims steht (`RAHMENBAUM_STELLEN` "sims", der
##                Torbaum), tritt der Sims als Pfeiler weit genug hinaus.
##   Platten    s 33–51: Unter dem Felsrand des Geländers und der Kanzel
##                (Wegbauten) beginnt die Wand erst unter der Platte.
##   Ufer       C4 (145–160): Erdufer mit Steinen bis auf den Talboden.
##   Enden      Vor s 33 biegt die Kante vom Weg weg und läuft um die Ecke
##                der Hochfläche; bei s 160 biegt das Ufer nach außen (vor
##                dem rechten Torriesen). Beide Enden sind verschlossen.
##
## LINKS (zu): die Böschung des Hangwegs (33–92, Erdhang 35–60° mit Steinen,
## Nische der Moosbank nach der Leitlinien-Polylinie), dann die Felsnase und
## die wachsende Schichtfelswand der Fallklamm (2 → 14 m, Simse, Überhang
## nur ab 10 m über dem Weg). Bei 112–122 weicht die Wand für das Felsbecken
## zurück; dort steht der Wasserfallpfeiler (+11 m), vor dem Becken ein
## niedriger Felssims auf Deckenhöhe. Die Krone folgt der glatten Kurve,
## nicht den Terrassen der Decke. Bewuchs: `Schluchtsaum.bauen` aus den
## `kronen`-Einträgen, die das Profil liefert (Böschung und Felswand je
## eigener Aufruf, eigene Dichten).
##
## QUER: Stirnflächen der Lücken (Erdspalt, Kerbe, Fallkerbe) samt Boden,
## die Stufen 66/133/145, die Ufer der Furt. Der Erdspalt läuft je Seite
## fünf Meter in den Waldboden und wird dabei schmaler. In den Lücken ist
## auch der Saum der Seiten ausgeschnitten: rechts bis auf den Grund der
## Kerbe (die Kerbe mündet in der Felswand), links als Rinne, die die
## Böschung hinaufläuft; in der Fallkerbe läuft das Becken aus.
##
## NÄHTE: Rasen, der an die Decke stößt, liegt 1,5 cm unter ihr und trägt
## ihre Farbe (Include `wald_gemeinsam`, Verdeckung 0,78 wie ihr Rand) – so
## verschwindet die Naht, und gleiche Flächen anderer Module (Nischenboden,
## Kanzel) flackern nicht. Zum Gelände (`gelaende`, wird später gemergt):
##   FELS_AB    die Wand reicht drei Meter unter "fuss_y"; das Feld liegt
##              darunter.
##   BOESCHUNG/FELS_AUF  die Krone läuft 7,5 m hinter die Kronenkante flach
##              aus (0,6–1,1 m ansteigend); das Feld schließt dort an.
## Die wirkliche Lippe und die wirklichen Flächen liefern `lippe_q()` und
## `GelaendeSaum.flaeche_punkt()`.
##
## KOLLISION baut der Saum keine. KOSTEN (Plan 13: ≤ 30 Zeichenaufrufe,
## ≤ 50k Dreiecke je Station, keine Schatten): je Seite und 30-m-Stück EIN
## Netz (Fels, Erde, Rasen, Steine – ein Stoff) und ein Kartennetz (bis
## `SICHT_KARTEN`), dazu die Stirnflächen und der Bewuchs der linken Seite
## (bis `SICHT_BEWUCHS`).

const STUECK := 30.0
## Abstand der Querschnitte entlang der Linie (m).
const SCHRITT_RECHTS := 0.6
const SCHRITT_LINKS := 0.7
const SCHRITT_QUER := 0.45
## Sichtweiten (m, vom Kameraort zur Mitte eines Stücks).
const SICHT := 260.0
const SICHT_KARTEN := 55.0
const SICHT_BEWUCHS := 120.0
const SICHT_RAND := 6.0
## So weit neben einer Stufe oder Lückenkante steht je ein Querschnitt.
const EPS := 0.005
## Felsbecken links in der Fallklamm: Grund (Welt-Y) und Pfeilerhöhe über
## der Kurve.
const BECKEN_Y := 19.0
const PFEILER_HOEHE := 11.0
## Grund der Lücken (Welt-Y), wie "fuss_y" der STIRN-Einträge.
const KERBE_GRUND := 16.0
const FALLKERBE_GRUND := 18.0
const ERDSPALT_GRUND := 17.0
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


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(level: Level01) -> Array:
	GelaendeSaum.vergessen()
	return [
		{"text": "Die Felskante über dem Tal", "tun": func() -> void: _rechts(level)},
		{"text": "Böschung und Schichtfels", "tun": func() -> void: _links(level)},
		{"text": "Spalten, Stufen und Ufer", "tun": func() -> void: _quer(level)},
	]


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
## (positiv), wie gebaut. Für Rasen, Wald und Gelände.
static func lippe_q(level: Level01, s: float, seite: float) -> float:
	var linie := _lippe_rechts(level) if seite > 0.0 else _fuss_links(level)
	for i in linie.size() - 1:
		var a := linie[i]
		var b := linie[i + 1]
		if s >= a.x and s <= b.x and b.x - a.x > 0.0001:
			return absf(lerpf(a.y, b.y, (s - a.x) / (b.x - a.x)))
	return absf(float(level.rand_profil(s, seite)["abstand"]))


# ================================================================ Stücke

## Sammelt die Netze je Stück: ein Fels-Netz (Stoff `GelaendeSaum.stoff`)
## und ein Kartennetz je Name.
class Stuecke:
	extends RefCounted
	var wurzel: Node3D
	var _opak := {}
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

	func fertig(sicht: float, sicht_karten: float, rand: float) -> void:
		for name in _namen:
			if _opak.has(name):
				_knoten(name, _opak[name], GelaendeSaum.stoff(), sicht, rand)
			if _karten.has(name):
				_knoten(name + " Karten", _karten[name], GelaendeSaum.kartenstoff(),
						sicht_karten, rand)

	func _knoten(name: String, st: SurfaceTool, stoff: Material, sicht: float,
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
		mi.visibility_range_end = sicht
		mi.visibility_range_end_margin = rand
		wurzel.add_child(mi)


static func _wurzel(level: Level01) -> Node3D:
	var knoten := level.geometrie.get_node_or_null("Saum") as Node3D
	if knoten == null:
		knoten = Node3D.new()
		knoten.name = "Saum"
		level.geometrie.add_child(knoten)
	return knoten


static func _stueck(prefix: String, s: float) -> String:
	return "%s %d" % [prefix, int(floor(s / STUECK))]


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


static func _farbe(ao: float, erde: float, moos: float, rasen: float) -> Color:
	return Color(ao, erde, moos, rasen)


# ================================================================ Rechts

## Die Lippe rechts als Polylinie [Vector2(s, q)].
static func _lippe_rechts(level: Level01) -> PackedVector2Array:
	var p := PackedVector2Array()
	# Um die Ecke der Hochfläche: vom Wald (s 18, q 22) zur Wegkante bei 33,
	# außen um den Findling der Enthüllung (s 31, q 5,5–8,3) herum.
	for v: Vector2 in [Vector2(18.0, 22.0), Vector2(20.0, 19.4), Vector2(22.0, 17.2),
			Vector2(24.0, 15.3), Vector2(26.0, 13.6), Vector2(28.0, 12.1), Vector2(30.0, 10.9),
			Vector2(31.6, 10.0), Vector2(32.5, 8.6), Vector2(32.95, 6.6),
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
	var ende := 159.0
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
		if not im_umriss:
			p.append(Vector2(s, _wegrand(level, s)))
		s += 0.5
	# Das Ufer biegt vor dem rechten Torriesen (s 162, q 9) nach außen.
	for v: Vector2 in [Vector2(159.5, 6.2), Vector2(159.85, 6.8), Vector2(160.05, 8.0),
			Vector2(160.15, 9.8), Vector2(160.2, 12.0), Vector2(160.2, 14.5)]:
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


## Die Felskante rechts.
static func _rechts(level: Level01) -> void:
	var st := Stuecke.new(_wurzel(level), "Rechts")
	var proben := GelaendeSaum.linie(level.verlauf, _lippe_rechts(level), SCHRITT_RECHTS,
			_feste_s())
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, 1.0,
			_profil_rechts.bind(level), _kante.bind(level), _kronen.bind(level))
	GelaendeSaum.merken(1.0, g)
	var norm := GelaendeSaum.normalen(g)
	_gitter_in_stuecke(st, "Rechts", g, norm)
	_deckel_an_enden(st, "Rechts", g)
	_lippenkarten(st, "Rechts", proben, g, 8301)
	_vorsprung_flaechen(st, level)
	st.fertig(SICHT, SICHT_KARTEN, SICHT_RAND)


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
	var ufer := smoothstep(143.5, 146.5, s)
	var p: GelaendeSaum.Profil
	if ufer <= 0.0:
		p = _profil_ab(level, s, bogen, q_lippe, kante, fuss_y, ov)
	elif ufer >= 1.0:
		p = _profil_ufer(bogen, kante, fuss_y, ov)
	else:
		p = _profil_ab(level, s, bogen, q_lippe, kante, fuss_y, ov).gemischt(
				_profil_ufer(bogen, kante, fuss_y, ov), ufer)
	# Der Erdspalt reicht nicht bis zur Ecke der Hochfläche.
	var grund := _luecken_grund(s) if s > 40.0 else NAN
	if not is_nan(grund):
		_in_luecke(p, grund, 0, p.anzahl() - 1, 0.0)
	return p


## Senkt die Punkte `von`..`bis` eines Profils auf den Grund einer Lücke
## (höchstens `grund + anstieg · o`): So ist die Kante an der Lücke
## ausgeschnitten, und zwischen dem letzten Querschnitt davor und dem ersten
## darin steht die Seitenwand der Lücke. Was gesenkt wird, ist dunkler Fels.
static func _in_luecke(p: GelaendeSaum.Profil, grund: float, von: int, bis: int,
		anstieg: float) -> void:
	var o_max := -INF
	for j in range(von, bis + 1):
		var grenze := grund + maxf(p.o[j], 0.0) * anstieg
		if p.absolut[j] == 1:
			grenze = grund
		if p.y[j] <= grenze:
			continue
		p.y[j] = grenze
		# Auf dem Grund nicht zurücklaufen: sonst faltete sich die Fläche.
		if p.absolut[j] == 0:
			o_max = maxf(o_max, p.o[j])
			p.o[j] = o_max
		p.farbe[j] = Color(0.32, 0.5, 0.2, 0.0)
		p.rauschen[j] = 0.0
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
	# aus dem Fels eine Torte. Sie tauchen auf 5–15 m auf und verschwinden.
	var da1 := smoothstep(-0.2, 0.35, _welle(bogen * 0.045, 21.0))
	var da2 := smoothstep(-0.2, 0.35, _welle(bogen * 0.05, 22.0))
	var w1 := (0.5 + 0.45 * (1.0 + _welle(bogen * 0.11, 4.0))) * lerpf(0.06, 1.0, da1)
	var w2 := (0.45 + 0.45 * (1.0 + _welle(bogen * 0.09, 6.0))) * lerpf(0.06, 1.0, da2)
	# Rahmenbäume auf Simsen: Dort tritt der obere Sims als Pfeiler hinaus.
	for stelle: Dictionary in Level01.RAHMENBAUM_STELLEN:
		var art: String = stelle["art"]
		if art != "sims" and art != "torbaum":
			continue
		var s0: float = stelle["s"]
		var weite := 3.4 if art == "sims" else 2.6
		var gewicht := 0.5 + 0.5 * cos(PI * clampf((s - s0) / weite, -1.0, 1.0))
		if gewicht <= 0.001:
			continue
		var tiefe := maxf(-float(stelle["fuss"]), 1.6) + 0.15
		var q0: float = stelle["q"]
		d1 = lerpf(d1, tiefe, gewicht)
		var noetig := q0 + (1.7 if art == "sims" else 1.9) - q_lippe + 0.4
		w1 = lerpf(w1, maxf(w1, noetig), gewicht)
	d2 = maxf(d2, d1 + 2.4)
	var u_ende := minf(6.4, d1 - 1.3)
	var p := GelaendeSaum.Profil.new()
	# --- Grasnarbe (0–5) oder Platte
	var narbe: Array = [
		[-0.45, -0.03, _farbe(0.78, 0.0, 0.05, 1.0)],
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
				0.8, 0.35, -1.0, 0.2)
	# --- Wand zum ersten Sims (14–17)
	var d14 := maxf(u_bis + 0.6, d1 - 1.0)
	p.punkt(_ab_o(d14, u_ende), kante - d14, _farbe(0.72, 0.0, 0.2, 0.0), 1.2, 0.8, 1.0, 0.35)
	p.punkt(_ab_o(d1, u_ende) - 0.05, kante - (d1 - 0.12), _farbe(0.5, 0.2, 0.45, 0.0), 1.6, 0.5)
	p.punkt(_ab_o(d1, u_ende) + w1 * 0.85, kante - (d1 - 0.02), _farbe(0.9, 0.3, 0.7 * da1, 0.0),
			1.6, 0.4)
	p.punkt(_ab_o(d1, u_ende) + w1, kante - (d1 + 0.4), _farbe(0.8, 0.1, 0.35, 0.0), 1.8, 0.5)
	# --- Wand zum zweiten Sims (18–21)
	var dm := (d1 + 0.4 + d2 - 0.12) * 0.5
	p.punkt(_ab_o(dm, u_ende) + w1, kante - dm, _farbe(0.76, 0.0, 0.2, 0.0), 2.0, 1.1, 1.0, 0.35)
	p.punkt(_ab_o(d2, u_ende) + w1 - 0.05, kante - (d2 - 0.12), _farbe(0.52, 0.2, 0.45, 0.0), 2.5, 0.5)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2 * 0.85, kante - (d2 - 0.02), _farbe(0.88, 0.3, 0.7 * da2, 0.0),
			2.5, 0.4)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2, kante - (d2 + 0.4), _farbe(0.78, 0.1, 0.35, 0.0), 2.8, 0.5)
	# --- Unterer Teil bis zum Fuß (22–26)
	for k in 5:
		var t := float(k + 1) / 6.0
		var d := lerpf(d2 + 0.4, h - 0.2, t)
		p.punkt(_ab_o(d, u_ende) + w1 + w2 + 0.25 * t, kante - d,
				_farbe(lerpf(0.74, 0.6, t), 0.0, 0.2, 0.0), lerpf(3.0, 4.5, t), 1.2, 1.0, 0.35)
	# --- Fuß und darunter (27–29): Das Gelände liegt unter der Wand.
	var of := _ab_o(h, u_ende) + w1 + w2 + 0.5
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
	# Ufer (8–24): 60–70°, Erde mit Moos, nach unten nasser.
	for k in 17:
		var t := float(k + 1) / 18.0
		var d := lerpf(0.9, h - 0.4, t)
		var bauch := 0.25 * sin(t * PI) * (1.0 + _welle(bogen * 0.2, 7.0))
		p.punkt(-0.1 + (d - 0.9) * 0.42 + bauch, kante - d,
				_farbe(lerpf(0.7, 0.55, t), lerpf(0.85, 0.5, t), 0.55, 0.0), lerpf(0.8, 2.5, t),
				0.3, 1.0, 0.1)
	var of := -0.1 + (h - 1.3) * 0.42 + 0.3
	p.punkt(of, fuss_y + 0.4, _farbe(0.42, 0.6, 0.5, 0.0), 2.5, 0.2)
	p.punkt(of + 0.4, fuss_y, _farbe(0.38, 0.7, 0.4, 0.0), 3.0, 0.2)
	p.punkt(of + 1.2, fuss_y - 0.5, _farbe(0.36, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.0, fuss_y - 1.5, _farbe(0.34, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.6, fuss_y - 3.0, _farbe(0.32, 0.8, 0.3, 0.0), 3.0, 0.2)
	return p


## Wurzel- und Halmkarten unter der Grasnarbe (Profilpunkte 2–5).
static func _lippenkarten(st: Stuecke, prefix: String, proben: Array[Dictionary],
		g: Dictionary, saat: int) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var strecken: PackedFloat32Array = g["s"]
	var rng := PropWerkzeug.zufall(saat)
	for i in range(1, reihen.size() - 1):
		var s := strecken[i]
		if _platte(s) > 0.2 or not is_nan(_luecken_grund(s)):
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
		_karten_an(st.karten(_stueck(prefix, s)), rng, reihe[2], reihe[4], aussen, laengs,
				float(proben[i]["bogen"]))


## Karten an einer Stelle der Narbe: oben = Narbenkante, unten = Unterseite.
static func _karten_an(st: SurfaceTool, rng: RandomNumberGenerator, oben: Vector3,
		unten: Vector3, aussen: Vector3, laengs: Vector3, _bogen: float) -> void:
	# Halme, die über die Kante hängen.
	if rng.randf() < 0.9:
		var lang := rng.randf_range(0.2, 0.5)
		var ton := Color(0.28, 0.4, 0.12) * rng.randf_range(0.75, 1.15)
		GelaendeSaum.karte(st, oben + Vector3.UP * 0.02 + laengs * rng.randf_range(-0.2, 0.2),
				(Vector3.DOWN * 0.75 + aussen * 0.65), laengs, lang,
				rng.randf_range(0.4, 0.75), GelaendeSaum.ATLAS_HALM, ton)
	# Wurzeln unter der Narbe, gekreuzt: Die Kamera blickt die Kante entlang.
	if rng.randf() < 0.62:
		var lang := rng.randf_range(0.35, 0.8)
		var ton := Color(0.42, 0.32, 0.23) * rng.randf_range(0.8, 1.1)
		var ort := unten + aussen * 0.03 + laengs * rng.randf_range(-0.25, 0.25)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.12, laengs, lang,
				rng.randf_range(0.35, 0.7), GelaendeSaum.ATLAS_WURZEL, ton)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.08, aussen + laengs * 0.3,
				lang * rng.randf_range(0.7, 1.0), rng.randf_range(0.25, 0.45),
				GelaendeSaum.ATLAS_WURZEL, ton * 0.9)


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
	var sk := clampf(s, 33.0, 159.9)
	var hoehe: float = level.rand_profil(sk, -1.0)["hoehe"]
	# Die Böschung wächst hinter dem Erdspalt aus dem Waldboden.
	if s < 41.0:
		hoehe *= lerpf(0.03, 1.0, smoothstep(27.7, 41.0, s))
	hoehe = lerpf(hoehe, PFEILER_HOEHE, _pfeiler(s))
	return LevelWerkzeuge.punkt(level.verlauf, s).y + hoehe


## Die linke Seite: Böschung, Felsnase, Felswand, Becken.
static func _links(level: Level01) -> void:
	var st := Stuecke.new(_wurzel(level), "Links")
	var proben := GelaendeSaum.linie(level.verlauf, _fuss_links(level), SCHRITT_LINKS,
			_feste_s())
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, -1.0,
			_profil_links.bind(level), _kante.bind(level), _kronen.bind(level))
	GelaendeSaum.merken(-1.0, g)
	var norm := GelaendeSaum.normalen(g)
	_gitter_in_stuecke(st, "Links", g, norm)
	_deckel_an_enden(st, "Links", g)
	_boeschung_steine(st, proben, g, norm)
	_becken_sims(st, level)
	st.fertig(SICHT, SICHT_KARTEN, SICHT_RAND)
	_bewuchs_links(level, proben, g)


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
	var rinne := 1.0 - smoothstep(0.0, 3.2, abseits) if abseits > 0.0 else 0.0
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
			# Kerbe: eine Rinne, die die Böschung hinaufläuft.
			_in_luecke(p, grund, 0, p.anzahl() - 1, 2.2)
		else:
			# Fallkerbe: Nur der Grund des Beckens läuft in die Kerbe aus.
			_in_luecke(p, grund, 0, 2, 0.0)
	return p


## BOESCHUNG: Rasen bis an den Fuß, ein Erdhang als Kosinus-S (am
## steilsten gut 50°), oben Waldboden.
static func _profil_boeschung(bogen: float, q_linie: float, kante: float,
		wegrand: float, krone: float, rinne: float) -> GelaendeSaum.Profil:
	var h := maxf(krone - kante, 0.12)
	var voll := smoothstep(0.5, 3.5, h)
	var breite := maxf(lerpf(3.0, 11.0 - q_linie, voll), 2.6 + h * 0.55)
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
		y -= 1.8 * rinne * smoothstep(0.05, 0.3, t) * (1.0 - smoothstep(0.75, 1.0, t))
		p.punkt(0.3 + (breite - 0.3) * t + buckel, y,
				_farbe(lerpf(0.7, 0.86, t) * lerpf(1.0, 0.88, steil) * lerpf(1.0, 0.8, rinne),
				lerpf(erde, 0.8, rinne * 0.6), 0.6, gras * (1.0 - rinne * 0.6)),
				lerpf(0.8, 2.5, t), lerpf(0.3, 0.4, t), 1.0 if t > 0.25 else 2.0)
	# Kronenkante und Krone (20–25)
	var k0 := breite
	for k in 6:
		var weiter: float = KRONE_WEITE_B[k]
		var hoch: float = KRONE_HOCH_B[k] * voll
		p.punkt(k0 + weiter, krone + hoch, _farbe(0.78, 0.3, 0.75, lerpf(0.85, 0.6, float(k) / 5.0)),
				2.5, 0.3)
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
	var wa := (0.5 + 0.35 * (1.0 + _welle(bogen * 0.12, 11.0))) * ka * (1.0 - 0.7 * becken)
	var wb := (0.45 + 0.35 * (1.0 + _welle(bogen * 0.1, 12.0))) * kb * (1.0 - 0.7 * becken)
	var zone := minf(2.4, 0.3 * h)
	var oben := h - zone
	# Überhang nur ab 10 m über dem Weg, höchstens so weit, dass die Kante
	# nicht näher als 2,8 m an die Wegmitte kommt.
	var ovd := 1.4 * smoothstep(10.2, 12.0, h) * smoothstep(10.0, 11.0, ueber_weg - zone)
	ovd = minf(ovd, q_linie + _wand_o(oben) + wa + wb - 2.8)
	ovd = maxf(ovd, 0.0)
	var wand := _farbe(0.72, 0.0, 0.22, 0.0)
	var ecke := _farbe(0.5, 0.15, 0.5, 0.0)
	var sims := _farbe(0.9, 0.3, 1.0, 0.0)
	# 4–7: bis zum ersten Sims
	p.punkt(_wand_o(ha * 0.5), fuss_y + ha * 0.5, wand, 1.0, 0.5, 2.0, 0.25)
	p.punkt(_wand_o(ha) - 0.03, fuss_y + ha - 0.12 * ka, ecke, 1.4, 0.35, 2.0)
	p.punkt(_wand_o(ha) + wa * 0.85, fuss_y + ha, sims.lerp(wand, 1.0 - ka), 1.6, 0.25, 2.0)
	p.punkt(_wand_o(ha) + wa, fuss_y + ha + 0.35 * ka, _farbe(0.8, 0.1, 0.5, 0.0), 1.6, 0.3, 2.0)
	# 8–11: zum zweiten Sims
	var hm := (ha + 0.35 * ka + hb - 0.12 * kb) * 0.5
	p.punkt(_wand_o(hm) + wa, fuss_y + hm, wand, 1.8, 0.55, 2.0, 0.25)
	p.punkt(_wand_o(hb) + wa - 0.03, fuss_y + hb - 0.12 * kb, ecke, 2.0, 0.35, 2.0)
	p.punkt(_wand_o(hb) + wa + wb * 0.85, fuss_y + hb, sims.lerp(wand, 1.0 - kb), 2.2, 0.25, 2.0)
	p.punkt(_wand_o(hb) + wa + wb, fuss_y + hb + 0.35 * kb, _farbe(0.8, 0.1, 0.5, 0.0), 2.2,
			0.3, 2.0)
	# 12–14: bis unter den Überhang
	var hc := hb + 0.35 * kb
	for k in 3:
		var t := float(k + 1) / 3.0
		var hh := lerpf(hc, oben, t)
		p.punkt(_wand_o(hh) + wa + wb, fuss_y + hh, wand, 2.4, 0.6, 2.0, 0.25)
	# 15–19: Überhang und Kante
	var fo := _wand_o(oben) + wa + wb
	var dunkel := _farbe(0.34, 0.1, 0.0, 0.0)
	p.punkt(fo - 0.3 * ovd, fuss_y + h - zone * 0.7, wand.lerp(dunkel, minf(ovd, 1.0)), 2.4, 0.4, 2.0)
	p.punkt(fo - 0.85 * ovd, fuss_y + h - zone * 0.44, wand.lerp(dunkel, minf(ovd, 1.0) * 0.8),
			2.4, 0.35)
	p.punkt(fo - ovd, fuss_y + h - zone * 0.2, wand, 2.4, 0.3)
	p.punkt(fo - 0.9 * ovd, fuss_y + h - zone * 0.06, _farbe(0.8, 0.1, 0.6, 0.1), 2.4, 0.25)
	p.punkt(fo - 0.6 * ovd, fuss_y + h, _farbe(0.82, 0.25, 0.8, 0.3), 2.4, 0.2)
	# 20–25: Kronenkante und Krone
	for k in 6:
		var weiter: float = KRONE_WEITE_W[k]
		var hoch: float = KRONE_HOCH_W[k]
		p.punkt(fo - 0.6 * ovd + weiter, fuss_y + h + hoch,
				_farbe(0.78, 0.3, 0.8, lerpf(0.75, 0.55, float(k) / 5.0)), 2.5, 0.3)
	return p


## Versatz der Felswand links in der Höhe `hh` über dem Fuß: gut 2° nach
## hinten geneigt.
static func _wand_o(hh: float) -> float:
	return 0.12 + 0.035 * hh


## Steine in der Böschung: halb im Hang versenkt, bemoost; ein paar kleine
## am Fuß (außerhalb der Schulter, an die die Figur herankommt).
static func _boeschung_steine(st: Stuecke, proben: Array[Dictionary], g: Dictionary,
		norm: Array[PackedVector3Array]) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var boden: PackedFloat32Array = g["boden"]
	var rng := PropWerkzeug.zufall(8401)
	for i in range(2, reihen.size() - 2, 3):
		var s: float = proben[i]["s"]
		if s < 33.0 or s > 92.0 or not is_nan(_luecken_grund(s)) \
				or (s > 55.0 and s < 60.0):
			continue
		if rng.randf() > 0.6:
			continue
		var j := rng.randi_range(6, 16)
		var p := reihen[i][j]
		var n := norm[i][j]
		var r := rng.randf_range(0.35, 0.95)
		var hoch := n.lerp(Vector3.UP, 0.5).normalized()
		var basis := Basis(Vector3.UP, rng.randf() * TAU)
		basis = Basis(Quaternion(Vector3.UP, hoch)) * basis
		GelaendeSaum.stein(st.opak(_stueck("Links", s)), p - n * r * 0.32,
				Vector3(r * rng.randf_range(1.0, 1.5), r * rng.randf_range(0.55, 0.8),
				r * rng.randf_range(0.9, 1.3)), basis, rng.randi_range(1, 900),
				_farbe(0.86, 0.0, 0.75, 0.0), boden[i])
		# Kleine Steine am Fuß
		if rng.randf() < 0.45:
			var pf := reihen[i][4]
			var rf := rng.randf_range(0.15, 0.3)
			GelaendeSaum.stein(st.opak(_stueck("Links", s)), pf + n * 0.02,
					Vector3(rf * 1.3, rf * 0.7, rf), Basis(Vector3.UP, rng.randf() * TAU),
					rng.randi_range(1, 900), _farbe(0.8, 0.1, 0.6, 0.0), boden[i])


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
			"laubfarbe": Farben.LAUB_HELL, "saum": 0.0, "ranken": 0.12, "wurzeln": 0.0,
			"vorhaenge": 0.0, "simse": 0.14, "fuss": 0.22, "blueten": 0.4})
	b.name = "Bewuchs Böschung"
	var w := Schluchtsaum.bauen(wurzel, kurve, wand, {"saat": 8502,
			"laubfarbe": Farben.LAUB_HELL, "saum": 0.0, "ranken": 0.42, "wurzeln": 0.08,
			"vorhaenge": 0.04, "simse": 0.42, "fuss": 0.32, "blueten": 0.3})
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

## Stirnflächen der Lücken, Stufen und die Ufer der Furt.
static func _quer(level: Level01) -> void:
	var st := Stuecke.new(_wurzel(level), "Quer")
	# Kerbe und Fallkerbe: nur der Teil unter der Decke; die Seiten sind im
	# Profil der Kanten ausgeschnitten.
	_graben(st, level, 56.0, 59.0, KERBE_GRUND, -5.4, 5.4, false, 5601)
	_graben(st, level, 118.0, 121.0, FALLKERBE_GRUND, -6.1, 4.4, false, 11801)
	_erdspalt(st, level)
	for s: float in [66.0, 133.0, 145.0]:
		_stufe(st, level, s)
	_furt(st, level)
	st.fertig(SICHT, SICHT_KARTEN, SICHT_RAND)


## Eine Wand quer zum Weg entlang `linie` [Vector2(s, q)], nach `vorwaerts`
## (+1: die Lücke liegt in +s) offen; `profil_bei` wie bei den Kanten.
static func _querwand(st: Stuecke, level: Level01, linie: PackedVector2Array,
		vorwaerts: float, profil_bei: Callable, name: String, saat: int,
		karten: bool = true) -> Dictionary:
	var proben := GelaendeSaum.linie(level.verlauf, linie, SCHRITT_QUER)
	var g := GelaendeSaum.querschnitte(level.verlauf, proben, -vorwaerts, profil_bei,
			_kante_quer.bind(level, linie[0].x), _kronen.bind(level))
	var norm := GelaendeSaum.normalen(g)
	GelaendeSaum.gitter_schreiben(st.opak(name), g, norm, 0, proben.size() - 1)
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
			_karten_an(st.karten(name), rng, reihe[2], reihe[4], aussen.normalized(),
					laengs.normalized(), 0.0)
	return g


static func _kante_quer(_i: int, _probe: Dictionary, level: Level01, s_kante: float) -> float:
	return level.boden_bei(s_kante)


## Der Graben unter einer Lücke: zwei Stirnwände und der Grund.
static func _graben(st: Stuecke, level: Level01, von: float, bis: float, grund: float,
		q_links: float, q_rechts: float, erdig: bool, saat: int) -> void:
	var halb := (bis - von) * 0.5
	var name := _stueck("Quer", von)
	for ende in 2:
		var s := von if ende == 0 else bis
		var linie := PackedVector2Array([Vector2(s, q_links), Vector2(s, q_rechts)])
		var kante := level.boden_bei(s - 0.01 if ende == 0 else s + 0.01)
		_querwand(st, level, linie, 1.0 if ende == 0 else -1.0,
				_profil_stirn.bind(kante, grund, halb, erdig), name, saat + ende)


## STIRN: Grasnarbe, Erdband, Wand bis auf den Grund, der Grund bis zur
## Mitte der Lücke (16 Punkte).
static func _profil_stirn(_i: int, probe: Dictionary, kante: float, grund: float,
		halb: float, erdig: bool) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var ov := clampf(0.18 + 0.1 * _welle(bogen * 1.1, 13.0), 0.1, 0.3)
	var e := 0.8 if erdig else 0.25
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, kante - 0.03, _farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, kante - 0.006, _farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, kante - 0.035, _farbe(0.72, 0.1, 0.3, 0.95))
	p.punkt(ov, kante - 0.12, _farbe(0.5, 0.6, 0.3, 0.45))
	p.punkt(ov - 0.06, kante - 0.25, _farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3, kante - 0.33, _farbe(0.18, 1.0, 0.0, 0.0))
	p.punkt(-0.35, kante - 0.5, _farbe(0.2, 1.0, 0.0, 0.0), 0.0, 0.05, -1.0)
	p.punkt(-0.45, kante - 1.0, _farbe(0.26, maxf(e, 0.7), 0.1, 0.0), 0.0, 0.15, -1.0)
	var tief := kante - grund
	for k in 5:
		var t := float(k) / 4.0
		var y := kante - lerpf(1.9, tief - 0.3, t)
		p.punkt(-0.5 + 0.1 * t, y, _farbe(lerpf(0.3, 0.12, t), e, 0.15, 0.0), 0.0,
				0.3, -1.0, 0.2 * (1.0 - e))
	p.punkt(-0.12, grund, _farbe(0.1, 0.7, 0.2, 0.0))
	p.punkt(halb * 0.6, grund - 0.02, _farbe(0.08, 0.8, 0.2, 0.0))
	p.punkt(halb + 0.05, grund - 0.05, _farbe(0.08, 0.8, 0.2, 0.0))
	return p


## Der Erdspalt (25,0–27,5): zwei Erdwände, die je Seite fünf Meter in den
## Waldboden laufen und dabei zusammenrücken, bis der Riss sich schließt.
static func _erdspalt(st: Stuecke, level: Level01) -> void:
	var name := _stueck("Quer", 25.0)
	for ende in 2:
		var linie := PackedVector2Array()
		var q := -10.6
		while q <= 10.61:
			var aq := absf(q)
			var eng := pow(smoothstep(5.2, 10.6, aq), 0.8)
			var zacke := 0.18 * sin(q * 1.3 + float(ende) * 2.0) * smoothstep(5.2, 7.0, aq)
			var s := 25.0 + 1.24 * eng + zacke if ende == 0 else 27.5 - 1.24 * eng + zacke
			linie.append(Vector2(s, q))
			q += 0.4
		var kante := level.boden_bei(25.0 if ende == 0 else 27.5)
		_querwand(st, level, linie, 1.0 if ende == 0 else -1.0,
				_profil_erdspalt.bind(kante, level), name, 2501 + ende)


static func _profil_erdspalt(i: int, probe: Dictionary, kante: float,
		_level: Level01) -> GelaendeSaum.Profil:
	var q: float = probe["q"]
	var aq := absf(q)
	var eng := pow(smoothstep(5.2, 10.6, aq), 0.8)
	var halb := 1.25 * (1.0 - eng) + 0.02
	# Zu den Enden hin wird der Riss auch flacher.
	var grund := lerpf(ERDSPALT_GRUND, kante - 2.5, smoothstep(0.55, 1.0, eng))
	return _profil_stirn(i, probe, kante, grund, halb, true)


## Eine Stufe (66, 133, 145): Grasnarbe der oberen Decke, Fels bis auf die
## untere, unter deren Rand eingesteckt.
static func _stufe(st: Stuecke, level: Level01, s: float) -> void:
	var oben := level.boden_bei(s - 0.01)
	var unten := level.boden_bei(s + 0.01)
	var q := maxf(_wegrand(level, s - 0.01), _wegrand(level, s + 0.01)) + 0.55
	_querwand(st, level, PackedVector2Array([Vector2(s, -q), Vector2(s, q)]), 1.0,
			_profil_stufe.bind(oben, unten), _stueck("Quer", s), int(s) * 13)


static func _profil_stufe(_i: int, probe: Dictionary, oben: float,
		unten: float) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var ov := clampf(0.18 + 0.1 * _welle(bogen * 1.1, 14.0), 0.1, 0.3)
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


## Die Ufer der Furt (173 und 183): Grasnarbe, Erdufer, Steine an der
## Wasserlinie; der Grund läuft bis zur Mitte der Furt.
static func _furt(st: Stuecke, level: Level01) -> void:
	var name := _stueck("Quer", 178.0)
	var rng := PropWerkzeug.zufall(17301)
	for ende in 2:
		var s := 173.0 if ende == 0 else 183.0
		var vorwaerts := 1.0 if ende == 0 else -1.0
		var kante := level.boden_bei(s - 0.01 * vorwaerts)
		var g := _querwand(st, level, PackedVector2Array([Vector2(s, -9.5), Vector2(s, 9.5)]),
				vorwaerts, _profil_furt.bind(kante), name, 17310 + ende)
		# Steine an der Wasserlinie, nicht im Anlauf auf die Trittsteine.
		var frei_q := -1.0 if ende == 0 else 0.8
		var reihen: Array[PackedVector3Array] = g["reihen"]
		var boden: PackedFloat32Array = g["boden"]
		for i in range(1, reihen.size() - 1, 2):
			var p := reihen[i][8]
			var q_hier := -9.5 + 19.0 * float(i) / float(reihen.size() - 1)
			if absf(q_hier - frei_q) < 1.8 or rng.randf() > 0.6:
				continue
			var r := rng.randf_range(0.18, 0.45)
			var vor := (reihen[i][9] - reihen[i][7])
			vor.y = 0.0
			GelaendeSaum.stein(st.opak(name), p + vor.normalized() * rng.randf_range(-0.2, 0.5)
					+ Vector3.DOWN * r * 0.25, Vector3(r * 1.3, r * 0.7, r),
					Basis(Vector3.UP, rng.randf() * TAU), rng.randi_range(1, 900),
					_farbe(0.8, 0.2, 0.55, 0.0), boden[i])


static func _profil_furt(_i: int, probe: Dictionary, kante: float) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var ov := clampf(0.16 + 0.1 * _welle(bogen * 1.1, 15.0), 0.08, 0.28)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, kante - 0.03, _farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, kante - 0.006, _farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, kante - 0.035, _farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, kante - 0.12, _farbe(0.5, 0.65, 0.3, 0.4))
	p.punkt(ov - 0.05, kante - 0.22, _farbe(0.6, 0.5, 0.4, 0.5))
	p.punkt(0.05, kante - 0.4, _farbe(0.66, 0.3, 0.5, 0.75), 0.0, 0.05)
	p.punkt(0.4, kante - 0.72, _farbe(0.66, 0.4, 0.6, 0.55), 0.0, 0.12)
	p.punkt(0.8, 6.3, _farbe(0.56, 0.65, 0.6, 0.15), 0.0, 0.12)
	p.punkt(1.2, 6.02, _farbe(0.36, 0.6, 0.4, 0.0), 0.0, 0.1)
	p.punkt(1.6, 5.75, _farbe(0.34, 0.5, 0.3, 0.0), 0.0, 0.1)
	p.punkt(2.2, 5.45, _farbe(0.32, 0.5, 0.3, 0.0), 0.0, 0.08)
	p.punkt(3.0, 5.3, _farbe(0.3, 0.55, 0.3, 0.0))
	p.punkt(4.2, 5.25, _farbe(0.3, 0.55, 0.3, 0.0))
	p.punkt(5.05, 5.22, _farbe(0.3, 0.55, 0.3, 0.0))
	return p
