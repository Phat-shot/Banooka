extends RefCounted
class_name Totholzzaun
## Ein Spaltzaun aus Totholz: grau verwitterte Pfosten, dazwischen zwei
## gespaltene Riegel, hier und da einer gebrochen oder heruntergefallen,
## Flechten und Moos obenauf. Dazu `stueck()`, der Baustein darunter: ein
## Holzstück (rund oder gespalten) entlang eines Punktzugs – auch für Äste
## und Wurzeln im selben Stoff.
##
## Der Zaun steht dort, wo man nicht hinfallen soll, und sieht so aus, als
## hätte ihn vor Jahren jemand gesetzt und seitdem nur der Wald gepflegt:
## * **Pfosten** 1,1–1,35 m, leicht schief (bis 5°), oben keilförmig
##   gespalten oder schräg gebrochen, 0,4 m versenkt.
## * **Riegel** halbrund gespalten: außen Rinde (Flechten, Moos), innen die
##   graue Spaltfläche. Sie liegen abwechselnd vor und hinter den Pfosten,
##   hängen leicht durch und stehen an den Enden über.
## * **Verfall**: ein Feld mit nur einem Riegel, einer, der mit einem Ende
##   auf den Boden gerutscht ist, ein abgebrochener Stumpf – gewürfelt aus
##   der Saat, also bei jedem Aufbau gleich.
## * **Geborstener Endpfosten** (Option): dicker, höher, oben in Splittern.
##
## Keine Kollision, keine Knoten: `bauen()` liefert EIN Netz im
## Scheitelformat von `Riesenstamm` (COLOR.rgb Verdeckung · Tönung, COLOR.a
## Moos, UV Rinde, UV2.x Art: 0 Rinde, 1 Eigenfarbe) – der Aufrufer
## verschmilzt es mit seinen übrigen Holzteilen und setzt `stoff()` oder,
## um einen Zeichenaufruf zu sparen, den gewöhnlichen
## `Riesenstamm.borkenstoff()`: Die graue Rinde steckt dann allein in der
## Tönung (`ton`, Vorgabe `RINDE_TON`), die Spaltflächen tragen ohnehin
## Eigenfarbe.
##
## Maße: Pfosten Ø 20–25 cm, Riegel Ø 15–19 cm – dünner lasen sie sich
## aus der Spielkamera (8–15 m) als Striche, nicht als Holz.
##
## Dreiecke: gut 150 je Meter Zaun.

## So tief stecken die Pfosten im Boden.
const VERSENKT := 0.4
## Graues, verwittertes Holz der Spaltflächen (Eigenfarbe, ≤ 1).
const HOLZ_GRAU := Color(0.6, 0.57, 0.52)
## Tönung der Rinde: blasser und grauer als lebende Borke.
const RINDE_TON := Color(0.86, 0.84, 0.8)

static var _stoff: ShaderMaterial = null


## Stoff für Totholz: Borke der Bibliothek, grau getönt, viele Flechten,
## Moos obenauf. Geteilt – nie verändern.
static func stoff() -> ShaderMaterial:
	if _stoff == null:
		_stoff = Riesenstamm.borkenstoff({"farbe": Color(0.93, 0.9, 0.86), "flechten": 1.0,
				"moos_oben": 0.5, "moos_nord": 0.35})
	return _stoff


## Ein Zaun entlang `linie` (Weltpunkte auf dem Boden, in Laufrichtung).
## Optionen:
##   saat             feste Saat (1)
##   abstand          Pfostenabstand in m (2,5)
##   hoehe            Pfostenhöhe über dem Boden (1,2)
##   aussen           +1: Riegel rechts der Laufrichtung, −1 links (+1)
##   luecken          Array[Vector2]: Strecken (Bogenlänge auf `linie`), in
##                    denen kein Zaun steht – dort stehen etwa Findlinge
##   ende_geborsten   der letzte Pfosten ist ein geborstener Stumpf (false)
##   verfall          0..1, wie viel gebrochen und heruntergefallen ist (0,35)
##   ton              Tönung der Rinde (Color ≤ 1, Vorgabe `RINDE_TON`)
static func bauen(linie: PackedVector3Array, optionen: Dictionary = {}) -> ArrayMesh:
	var st := Riesenstamm.bauer()
	var saat: int = optionen.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var abstand: float = optionen.get("abstand", 2.5)
	var hoehe: float = optionen.get("hoehe", 1.2)
	var aussen: float = optionen.get("aussen", 1.0)
	var luecken: Array = optionen.get("luecken", [])
	var geborsten: bool = optionen.get("ende_geborsten", false)
	var verfall: float = optionen.get("verfall", 0.35)
	var ton: Color = optionen.get("ton", RINDE_TON)

	# Bogenlänge der Linie, um Pfosten gleichmäßig zu verteilen.
	var laengen := PackedFloat32Array([0.0])
	for i in range(1, linie.size()):
		laengen.append(laengen[i - 1] + linie[i].distance_to(linie[i - 1]))
	var gesamt := laengen[laengen.size() - 1]
	if gesamt < 0.5:
		return Riesenstamm.fertig(st)

	# Pfosten: gleichmäßig mit Streuung, nicht in Lücken. Eine Lücke hat an
	# beiden Enden einen Pfosten, damit die Riegel dort enden.
	var stellen: Array[float] = []
	var teile := maxi(roundi(gesamt / abstand), 1)
	for i in teile + 1:
		var l := gesamt * float(i) / float(teile)
		if i > 0 and i < teile:
			l += rng.randf_range(-0.22, 0.22) * abstand
		if not _in_luecke(l, luecken, 0.0):
			stellen.append(l)
	for luecke: Vector2 in luecken:
		for l: float in [luecke.x, luecke.y]:
			if l > 0.05 and l < gesamt - 0.05 and not _in_luecke(l, luecken, -0.05):
				stellen.append(l)
	stellen.sort()
	# Zu dicht beieinander (Lückenpfosten neben einem regulären): weg damit.
	var gefiltert: Array[float] = []
	for l in stellen:
		if gefiltert.is_empty() or l - gefiltert[gefiltert.size() - 1] > abstand * 0.45:
			gefiltert.append(l)
	stellen = gefiltert

	var koepfe: Array[Vector3] = []
	var fuesse: Array[Vector3] = []
	for k in stellen.size():
		var l := stellen[k]
		var fuss := _auf_linie(linie, laengen, l)
		var richtung := _richtung(linie, laengen, l)
		var seite := richtung.cross(Vector3.UP).normalized() * aussen
		var letzter := k == stellen.size() - 1
		var ph := hoehe * rng.randf_range(0.9, 1.1)
		var pr := rng.randf_range(0.1, 0.125)
		var schief := Vector3(rng.randf_range(-0.07, 0.07), 0.0, rng.randf_range(-0.07, 0.07))
		if geborsten and letzter:
			ph = hoehe * 1.35
			pr = 0.17
			schief = seite * 0.1 + richtung * 0.06
		var kopf := fuss + (Vector3.UP + schief).normalized() * ph
		var punkte := PackedVector3Array([fuss - Vector3.UP * VERSENKT, fuss.lerp(kopf, 0.5), kopf])
		var radien := PackedFloat32Array([pr * 1.08, pr, pr * 0.94])
		stueck(st, punkte, radien, {"saat": saat * 31 + k, "seiten": 7,
				"ende": "splitter" if (geborsten and letzter) else "keil",
				"moos": 0.35, "ao": Vector2(0.55, 1.0), "ton": ton})
		koepfe.append(kopf)
		fuesse.append(fuss)

	# Riegel zwischen je zwei Pfosten, außer über einer Lücke.
	for k in stellen.size() - 1:
		var mitte_l := (stellen[k] + stellen[k + 1]) * 0.5
		if _in_luecke(mitte_l, luecken, 0.0):
			continue
		var a_fuss := fuesse[k]
		var b_fuss := fuesse[k + 1]
		var feld := b_fuss - a_fuss
		var laenge := feld.length()
		if laenge < 0.3:
			continue
		var richtung := feld / laenge
		var seite := richtung.cross(Vector3.UP).normalized() * aussen
		var wurf := rng.randf()
		for riegel in 2:
			var h := hoehe * (0.42 if riegel == 0 else 0.82) + rng.randf_range(-0.05, 0.05)
			# Abwechselnd vor und hinter den Pfosten.
			var vorn := seite * (0.14 if (k + riegel) % 2 == 0 else -0.14) * 0.9
			var a := a_fuss + Vector3.UP * h + vorn - richtung * rng.randf_range(0.12, 0.28)
			var b := b_fuss + Vector3.UP * (h + rng.randf_range(-0.06, 0.06)) + vorn \
					+ richtung * rng.randf_range(0.12, 0.28)
			var rr := rng.randf_range(0.075, 0.095)
			var bruch := "splitter"
			if wurf < verfall * 0.25 and riegel == 1:
				# Oberer Riegel fehlt: nur ein Stumpf am ersten Pfosten.
				b = a.lerp(b, rng.randf_range(0.2, 0.35)) + Vector3.DOWN * 0.03
			elif wurf < verfall * 0.55 and riegel == 0:
				# Unterer Riegel mit einem Ende auf den Boden gerutscht.
				b = b_fuss + vorn * 1.6 + Vector3.UP * (rr * 0.8) + richtung * 0.1
			elif wurf < verfall * 0.8 and riegel == 1:
				# Gebrochen und durchgesackt: zwei Stücke mit Knick.
				var knick := a.lerp(b, rng.randf_range(0.4, 0.6)) + Vector3.DOWN * 0.22
				_riegel(st, rng, a, knick, rr, seite, saat * 97 + k * 2 + riegel, "splitter", ton)
				_riegel(st, rng, knick + richtung * 0.05, b, rr, seite, saat * 89 + k * 2 + riegel,
						"splitter", ton)
				continue
			_riegel(st, rng, a, b, rr, seite, saat * 53 + k * 2 + riegel, bruch, ton)
	return Riesenstamm.fertig(st)


static func _riegel(st: SurfaceTool, rng: RandomNumberGenerator, a: Vector3, b: Vector3,
		r: float, seite: Vector3, saat: int, ende: String, ton: Color) -> void:
	var d := b - a
	var mitte := a + d * 0.5 + Vector3.DOWN * d.length() * 0.012
	var punkte := PackedVector3Array([a, a.lerp(mitte, 0.5), mitte, mitte.lerp(b, 0.5), b])
	var radien := PackedFloat32Array([r, r * 1.02, r, r * 0.97, r * 0.95])
	# Die Spaltfläche zeigt mal nach oben, mal zur Seite.
	var spalt := (Vector3.UP * rng.randf_range(-0.3, 1.0) + seite * rng.randf_range(-1.0, 1.0)).normalized()
	stueck(st, punkte, radien, {"saat": saat, "seiten": 7, "form": "gespalten",
			"spalt": spalt, "ende": ende, "moos": 0.45, "ao": Vector2(0.85, 0.85), "ton": ton})


static func _in_luecke(l: float, luecken: Array, rand: float) -> bool:
	for luecke: Vector2 in luecken:
		if l > luecke.x - rand and l < luecke.y + rand:
			return true
	return false


static func _auf_linie(linie: PackedVector3Array, laengen: PackedFloat32Array, l: float) -> Vector3:
	for i in range(1, linie.size()):
		if l <= laengen[i] or i == linie.size() - 1:
			var t := clampf((l - laengen[i - 1]) / maxf(laengen[i] - laengen[i - 1], 0.0001), 0.0, 1.0)
			return linie[i - 1].lerp(linie[i], t)
	return linie[linie.size() - 1]


static func _richtung(linie: PackedVector3Array, laengen: PackedFloat32Array, l: float) -> Vector3:
	var a := _auf_linie(linie, laengen, maxf(l - 0.3, 0.0))
	var b := _auf_linie(linie, laengen, minf(l + 0.3, laengen[laengen.size() - 1]))
	var d := b - a
	d.y = 0.0
	return d.normalized() if d.length() > 0.0001 else Vector3.FORWARD


# ================================================================ Holzstück

## Ein Holzstück entlang `punkte` mit dem Radius `radien` je Punkt, in
## `st` (Sammler aus `Riesenstamm.bauer()`). Für Pfosten, Riegel, Äste und
## Wurzeln. Optionen:
##   form     "rund" (Vorgabe) oder "gespalten": halbrund, die Spaltfläche
##            zeigt nach "spalt" (Vector3) und trägt Eigenfarbe (graues Holz)
##   seiten   Ecken rundum (8)
##   ende     "offen", "keil" (oben keilförmig gespalten), "splitter"
##            (Zacken), "spitz" (läuft aus), "bruch" (schräg gebrochen)
##   anfang   wie `ende`, für den ersten Punkt (Vorgabe "offen")
##   moos     Moosanteil 0..1 (0,3)
##   ao       Vector2: Verdeckung am Anfang und am Ende (1, 1)
##   ton      Color ≤ 1: Tönung der Rinde über die Scheitelfarbe (weiß)
##   buckel   Tiefe der Beulen relativ zum Radius (0,06)
##   drehung  Drall der Rippen in rad je Meter (0): Drehwuchs
##   saat     feste Saat
static func stueck(st: SurfaceTool, punkte: PackedVector3Array, radien: PackedFloat32Array,
		optionen: Dictionary = {}) -> void:
	var n := punkte.size()
	if n < 2:
		return
	var saat: int = optionen.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var seiten: int = optionen.get("seiten", 8)
	var gespalten := String(optionen.get("form", "rund")) == "gespalten"
	var spalt: Vector3 = optionen.get("spalt", Vector3.UP)
	var ende: String = optionen.get("ende", "offen")
	var anfang: String = optionen.get("anfang", "offen")
	var moos: float = optionen.get("moos", 0.3)
	var ao: Vector2 = optionen.get("ao", Vector2(1.0, 1.0))
	var ton: Color = optionen.get("ton", Color(1.0, 1.0, 1.0))
	var buckel: float = optionen.get("buckel", 0.06)
	var drehung: float = optionen.get("drehung", 0.0)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 1.3

	# Rahmen mit Paralleltransport: (n1, n2, t) rechtshändig, damit die
	# Vorderseite nach außen zeigt (siehe Riesenstamm.gitter).
	var t0 := (punkte[1] - punkte[0]).normalized()
	var hilfe := Vector3.UP if absf(t0.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var n1 := hilfe.cross(t0).normalized()
	var r_mittel := 0.0
	for r in radien:
		r_mittel += r
	r_mittel /= float(radien.size())
	var kachel := Riesenstamm.borkenmass(r_mittel)
	var n_u := maxi(1, roundi(TAU * r_mittel * Riesenstamm.KACHEL_U * kachel))
	var drall := rng.randf() * TAU

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var bogen := 0.0
	for i in n:
		var t: Vector3
		if i == 0:
			t = t0
		elif i == n - 1:
			t = (punkte[n - 1] - punkte[n - 2]).normalized()
		else:
			t = (punkte[i + 1] - punkte[i - 1]).normalized()
		n1 = (n1 - t * n1.dot(t)).normalized()
		var n2 := t.cross(n1).normalized()
		if i > 0:
			bogen += punkte[i].distance_to(punkte[i - 1])
		var f := float(i) / float(n - 1)
		var r := radien[i]
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		var ao_hier := lerpf(ao.x, ao.y, f)
		# Spaltrichtung quer zur Achse
		var sp := spalt - t * spalt.dot(t)
		sp = sp.normalized() if sp.length() > 0.01 else n1
		for j in seiten + 1:
			var jj := j % seiten
			var a := TAU * float(jj) / float(seiten) + drall + bogen * drehung
			var dir := n1 * cos(a) + n2 * sin(a)
			var rel := 1.0 + buckel * rauschen.get_noise_3d(dir.x * 1.5 + bogen * 0.8,
					dir.y * 1.5, dir.z * 1.5 + float(saat % 97))
			if jj % 2 == 1:
				rel -= buckel * 0.6
			var p := dir * r * rel
			var art := Riesenstamm.BORKE
			var farbe := Color(ao_hier * ton.r, ao_hier * ton.g, ao_hier * ton.b, 0.0)
			if gespalten:
				var d := p.dot(sp)
				var grenze := r * 0.22
				if d > grenze:
					p -= sp * (d - grenze)
					art = Riesenstamm.EIGEN
					var g := HOLZ_GRAU * rng.randf_range(0.88, 1.08) * ao_hier
					farbe = Color(g.r, g.g, g.b, 0.0)
			var m := moos * (0.4 + 0.6 * rauschen.get_noise_3d(p.x * 4.0 + bogen, p.y * 4.0, p.z * 4.0))
			farbe.a = clampf(m, 0.0, 1.0) if art == Riesenstamm.BORKE else 0.0
			zeile.append(punkte[i] + p)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u),
					bogen * Riesenstamm.KACHEL_V * kachel * 2.0))
			fa.append(farbe)
			ar.append(Vector2(art, 0.25))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)

	# Enden: Die letzte (erste) Zeile wird verformt, dann ein Deckel.
	_ende_formen(zeilen, n - 1, n - 2, ende, rng, radien[n - 1])
	_ende_formen(zeilen, 0, 1, anfang, rng, radien[0])
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)
	if ende != "spitz":
		_deckel(st, zeilen[n - 1], zeilen[n - 2], rng)
	if anfang != "spitz":
		_deckel(st, zeilen[0], zeilen[1], rng)


## Verformt die Endzeile: Keil (zwei Schrägen), Splitter (Zacken), Spitze
## (Punkt), Bruch (schräg).
static func _ende_formen(zeilen: Array[PackedVector3Array], i: int, nachbar: int, art: String,
		rng: RandomNumberGenerator, r: float) -> void:
	if art == "offen":
		return
	var zeile := zeilen[i]
	var mitte := Vector3.ZERO
	for k in zeile.size() - 1:
		mitte += zeile[k]
	mitte /= float(zeile.size() - 1)
	var aussen := (mitte - _mitte(zeilen[nachbar])).normalized()
	var quer := aussen.cross(Vector3.UP)
	if quer.length() < 0.1:
		quer = aussen.cross(Vector3.RIGHT)
	quer = quer.normalized()
	var schraeg := rng.randf_range(0.6, 1.4)
	for k in zeile.size():
		var p := zeile[k]
		var rel := p - mitte
		match art:
			"keil":
				p += aussen * (r * 1.2 - absf(rel.dot(quer)) * 1.4)
			"splitter":
				var zacke := Riesenstamm.randf_hash(k % (zeile.size() - 1), i + 7)
				p += aussen * r * (0.3 + 2.6 * zacke * zacke * zacke)
				p = mitte + (p - mitte) * lerpf(1.0, 0.7, zacke)
			"spitz":
				p = mitte + aussen * r * 1.5
			"bruch":
				p += aussen * rel.dot(quer) * schraeg
		zeile[k] = p
	zeilen[i] = zeile


static func _mitte(zeile: PackedVector3Array) -> Vector3:
	var summe := Vector3.ZERO
	for k in zeile.size() - 1:
		summe += zeile[k]
	return summe / float(maxi(zeile.size() - 1, 1))


## Deckel über einer Endzeile: graues Hirnholz, zur Mitte dunkler.
static func _deckel(st: SurfaceTool, rand: PackedVector3Array, nachbar: PackedVector3Array,
		rng: RandomNumberGenerator) -> void:
	var mitte := _mitte(rand)
	var aussen := (mitte - _mitte(nachbar)).normalized()
	# Nicht über die Zacken hinaus: Die Mitte sitzt auf der Höhe des
	# niedrigsten Randpunkts.
	var tiefst := INF
	for k in rand.size() - 1:
		tiefst = minf(tiefst, (rand[k] - mitte).dot(aussen))
	mitte += aussen * tiefst
	var holz := HOLZ_GRAU * rng.randf_range(0.85, 1.0)
	var kern := HOLZ_GRAU * 0.45
	for k in rand.size() - 1:
		dreieck(st, mitte, rand[k], rand[k + 1], aussen, kern, holz, holz)


## Ein Dreieck in Eigenfarbe (UV2.x = EIGEN) im Scheitelformat von
## `Riesenstamm`, Vorderseite nach `aussen`, Flächennormale.
static func dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var ecken: Array[Vector3] = [a, b, c]
	var farben: Array[Color] = [fa, fb, fc]
	# Vorderseite: cross(b-a, c-a) zeigt ENTGEGEN der Außenrichtung.
	if kreuz.dot(aussen) > 0.0:
		ecken = [a, c, b]
		farben = [fa, fc, fb]
		kreuz = -kreuz
	var n := -kreuz.normalized()
	for e in 3:
		var p := ecken[e]
		var f := farben[e]
		st.set_color(Color(f.r, f.g, f.b, 0.0))
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 3.0)
		st.set_uv2(Vector2(Riesenstamm.EIGEN, 0.0))
		st.set_normal(n)
		st.add_vertex(p)
