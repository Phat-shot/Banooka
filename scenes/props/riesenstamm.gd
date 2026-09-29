extends RefCounted
class_name Riesenstamm
## Prozedurale Baumstämme: vom schlanken Hallenbaum über den gedrehten
## Rahmenbaum bis zum Talriesen mit Brettwurzeln. Dazu liegende Stämme,
## Stümpfe und eine schlichte Fassung für MultiMesh-Reihen.
##
## Alles sind statische Bauer, die ein `ArrayMesh` liefern – keine Knoten,
## kein `_process`, keine Kollision. Wer den Stamm setzt, entscheidet über
## Kollision, Schatten und Sichtweite (`Waldsetzer`, Level-Module).
##
## Der Stamm liest sich nicht als Rohr, weil er aus dem besteht, was einen
## großen Baum von Weitem ausmacht:
## * **Borkenrippen** – 12 bis 20 Längswülste mit Furchen dazwischen, leicht
##   um den Stamm gedreht, jede anders stark. Aus der Kamera brechen sie den
##   Umriss und fangen Streiflicht.
## * **Brettwurzeln** – 5 bis 8 dünne, geschwungene Bretter, die den Stamm
##   ins Gelände stemmen. Der Stamm schwillt zu ihnen hin an, so wachsen sie
##   aus ihm heraus, statt angeklebt zu sein.
## * **Moos** unten, auf allem, was nach oben schaut, und auf der Nordseite
##   (-Z) – nach Weltlage im Shader, also auch nach einer Drehung richtig.
## * **Verdeckung** als Scheitelfarbe: dunkel am Boden, in den Furchen und
##   in den engen Winkeln zwischen den Wurzeln.
## * Auf Wunsch **Konsolenpilze**, **Efeu**, **Leuchtpilze** und Äste, die
##   in eine `Kronenwolke` führen (`baum()`).
##
## Koordinaten: Fuß der Stammachse im Ursprung, +Y hinauf. Die Stämme stecken
## `VERSENKT` Meter tief im Boden, damit auf unebenem Gelände nie eine Kante
## frei liegt.
##
## Scheiteldaten (für eigene Bauteile im selben Stoff, siehe `bauer()`):
##   COLOR.rgb  Verdeckung bzw. Tönung (Borke) oder die Farbe selbst (Beiwerk)
##   COLOR.a    Moosanteil (0..1) – Moos oben und im Norden rechnet der Shader
##              dazu
##   UV         Borkentextur in Wiederholungen (rundum ganzzahlig, keine Naht)
##   UV2.x      Art: 0 Borke, 1 Eigenfarbe (Pilz, Efeu, Holz), 2 leuchtend
##   UV2.y      wie stark Nordmoos wachsen darf (unten 1, oben 0)
## Instanzfarben eines MultiMesh multiplizieren COLOR – tönen also die Borke
## und skalieren das Moos, ohne die Daten zu zerstören.
##
## Dreiecke (gemessen mit `PROPSCHAU=messung`): Hallenbaum ≈ 1,5k,
## Talriese mit allem Beiwerk ≈ 3,3k (Grenze nah 6k), Stumpf ≈ 0,9k,
## liegend ≈ 0,7k, `schlicht()` ≈ 0,2k (Grenze 300).
##
## Aufruf:
##     var netz := Riesenstamm.netz({"hoehe": 34.0, "radius": 1.6, "pilze": 3})
##     var mi := MeshInstance3D.new()
##     mi.mesh = netz
##     mi.material_override = Riesenstamm.borkenstoff()
##
##     var b := Riesenstamm.baum({"hoehe": 16.0, "radius": 0.4, "saat": 7})
##     # b.stamm (Borke, wirft Schatten), b.krone (Kronenwolke.stoff(), ohne)

## So tief steckt jeder Stamm im Boden.
const VERSENKT := 1.0

## Werte für UV2.x
const BORKE := 0.0
const EIGEN := 1.0
const LEUCHT := 2.0

## Texturwiederholungen der Rinde je Meter: rundum und längs. Die Rinde der
## Bibliothek ist längs gestreckt (Furchen), deshalb die ungleichen Werte.
const KACHEL_U := 1.4
const KACHEL_V := 0.35

## Zahl der Winkel, an denen `fuss_radien` den Umriss am Boden meldet.
const FUSS_WINKEL := 48


# ================================================================ Bauer

## Neuer Sammler für Borkenbauteile. Alles, was hineingeht, muss Farbe, UV,
## UV2 und Normale setzen – `gitter()` und die Bausteine tun das.
static func bauer() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Schließt einen Sammler ab: verschmelzen, Tangenten, fertig.
static func fertig(st: SurfaceTool) -> ArrayMesh:
	st.index()
	st.generate_tangents()
	var netz: ArrayMesh = st.commit()
	return netz


# ================================================================ Stamm

## Ein stehender Stamm. Optionen (alle freiwillig):
##   hoehe            Stammhöhe über dem Boden (14)
##   radius           Radius in Brusthöhe (0.5)
##   radius_oben      Radius oben (radius · 0.55)
##   rippen           Borkenrippen (12–20, aus dem Radius)
##   seiten           Ecken rundum (2 · rippen)
##   rippen_tiefe     Rippenhöhe relativ zum Radius (0.07)
##   drehung          Drehung der Rippen über die Höhe in rad (0.45)
##   ring_abstand     größter Abstand der Ringe (1,5–4 m)
##   neigung          Versatz der Spitze als Vector2 (x, z) in m
##   krumm            Schwung der Achse in m (hoehe · 0,015)
##   anlauf           wie stark der Fuß ausläuft (0.35)
##   brettwurzeln     Anzahl (4 bei dünnen Stämmen bis 7 bei Riesen; schlicht 0)
##   wurzel_reichweite, wurzel_hoehe, wurzel_dicke   in m (aus dem Radius,
##                    höchstens 3,5 / 5 / 0,6 m – für Riesen ausdrücklich setzen)
##   moos             0..1 (1)
##   pilze            Gruppen von Konsolenpilzen (0)
##   efeu             Efeuranken (0)
##   leuchtpilze      Gruppen am Fuß (0)
##   aeste            Äste, die in die Krone führen (0)
##   ast_start        ab welchem Anteil der Höhe Äste abgehen (0.6)
##   ast_laenge       Astlänge in m (hoehe · 0,28)
##   ast_steil        Steigung der Äste in rad (0.75)
##   oben             "offen" (in der Krone), "spitz" oder "bruch"
##   schlicht         8 Ecken, keine Rippen, kein Beiwerk (für Fernreihen)
##   saat             feste Saat (1)
##
## Metadaten am Netz: "ast_spitzen" (PackedVector3Array, samt Leittrieb als
## letztem Punkt), "zweig_spitzen" (Enden der Seitenzweige),
## "ast_radien" (PackedFloat32Array, Astlängen), "fuss_radien"
## (PackedFloat32Array mit `FUSS_WINKEL` Werten: Umriss am Boden samt
## Wurzeln, für `Findling.kranz()`).
static func netz(optionen: Dictionary = {}) -> ArrayMesh:
	var st := bauer()
	var info := stamm_in(st, optionen)
	var ergebnis := fertig(st)
	for schluessel: String in info:
		ergebnis.set_meta(schluessel, info[schluessel])
	return ergebnis


## Schlichte Fassung: 8 Ecken, keine Rippen, vier angedeutete Wurzelwülste,
## höchstens drei Aststummel. Unter 300 Dreiecke – für MultiMesh-Reihen in
## 40–90 m, wo die Rippen ohnehin nicht mehr zu sehen sind.
static func schlicht(optionen: Dictionary = {}) -> ArrayMesh:
	var o := optionen.duplicate()
	o["schlicht"] = true
	return netz(o)


## Ein Stumpf: kurz, mit Bruchkante oben und kleinen Wurzeln.
static func stumpf(radius: float, hoehe: float, optionen: Dictionary = {}) -> ArrayMesh:
	var o := {"hoehe": hoehe, "radius": radius, "radius_oben": radius * 0.92,
			"oben": "bruch", "brettwurzeln": 5, "wurzel_hoehe": minf(hoehe * 0.8, radius * 2.2),
			"wurzel_reichweite": radius * 1.6, "wurzel_dicke": radius * 0.45,
			"rippen_tiefe": 0.09, "drehung": 0.15, "krumm": 0.0, "ring_abstand": 0.6}
	o.merge(optionen, true)
	return netz(o)


## Ein Baum aus Stamm und Krone, die zueinander passen: Die Äste des Stamms
## enden in den Ballen der Krone. So steht keine Kugel auf einem Stock –
## unter dem Dach sieht man die Äste, die das Laub tragen.
##
## Optionen: alle von `netz()` (Vorgaben: 4 Äste) und dazu
##   krone_radius   waagerechter Radius der Krone (hoehe · 0,26)
##   variante       0 rund, 1 breit (Schirm), 2 hoch (schlank)
##   karten         Blattkarten der Krone
## Mit "schlicht" wird auch die Krone zur Fernfassung (grob, ohne Karten):
## zusammen ≈ 0,7k Dreiecke für Reihen in 40–90 m.
## Ergebnis: {"stamm": ArrayMesh, "krone": ArrayMesh, "krone_unten": float,
##            "krone_oben": float, "krone_radius": float}
## `krone_unten` ist die tiefste Stelle des Laubs (lokales Y) – für die
## Regel „Kronen über dem Weg erst ab 9,5 m".
static func baum(optionen: Dictionary = {}) -> Dictionary:
	var hoehe: float = optionen.get("hoehe", 14.0)
	var variante: int = optionen.get("variante", 0)
	var kr: float = optionen.get("krone_radius", hoehe * 0.26)
	var o := {"aeste": 4, "ast_laenge": kr * 0.9, "oben": "offen"}
	match variante:
		1:
			o["ast_start"] = 0.5
			o["ast_steil"] = 0.42
			o["aeste"] = 5
			o["ast_laenge"] = kr * 1.05
		2:
			o["ast_start"] = 0.55
			o["ast_steil"] = 1.0
			o["aeste"] = 4
			o["ast_laenge"] = kr * 0.85
	o.merge(optionen, true)
	var saat: int = o.get("saat", 1)
	var stamm := netz(o)
	var spitzen: PackedVector3Array = stamm.get_meta("ast_spitzen", PackedVector3Array())
	var zweige: PackedVector3Array = stamm.get_meta("zweig_spitzen", PackedVector3Array())
	var krone := Kronenwolke.netz({
		"zentren": spitzen,
		"nebenzentren": zweige,
		"radius": kr,
		"variante": variante,
		"saat": saat + 101,
		"karten": o.get("karten", -1),
		"flach": o.get("schlicht", false),
	})
	var box := krone.get_aabb()
	return {"stamm": stamm, "krone": krone, "krone_unten": box.position.y,
			"krone_oben": box.end.y, "krone_radius": kr}


## Ein liegender Stamm, passend in eine Kapsel: Achse entlang +Y, Mitte im
## Ursprung – genau wie `CapsuleShape3D` mit `radius` und `height = laenge`.
## Wer die Kapsel quer legt, legt das Netz mit derselben Verwandlung.
## Die Enden sind gebrochen (Splitter), das Moos obenauf wächst nach
## Weltlage im Shader. Optionen: saat, rippen, moos, aeste (Stummel, 1).
static func liegend(radius: float, laenge: float, optionen: Dictionary = {}) -> ArrayMesh:
	var saat: int = optionen.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var rippen: int = optionen.get("rippen", 9)
	var seiten := rippen * 2
	var moos: float = optionen.get("moos", 1.0)
	var stummel: int = optionen.get("aeste", 1)
	var rauschen := _rauschen(saat)
	var st := bauer()

	# Gerader Teil zwischen den Halbkugeln der Kapsel; die Splitter ragen in
	# die Halbkugeln hinein, bleiben aber in ihr.
	var halb := maxf(laenge * 0.5 - radius, radius * 0.3)
	var ringe := maxi(4, ceili(halb * 2.0 / 0.7))
	var amplituden := PackedFloat32Array()
	for k in rippen:
		amplituden.append(rng.randf_range(0.015, 0.045))
	# Ein, zwei Astknoten: Beulen, die den Umriss brechen (innerhalb der Kapsel).
	var knoten: Array[Vector3] = []
	for k in rng.randi_range(1, 2):
		knoten.append(Vector3(rng.randf() * TAU, rng.randf_range(-0.7, 0.7) * laenge * 0.5,
				rng.randf_range(0.6, 1.0)))
	var kachel := borkenmass(radius)
	var n_u := maxi(1, roundi(TAU * radius * KACHEL_U * kachel))

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	for i in ringe + 3:
		# Zeile 0 und die letzte: Splitterkante an den Enden
		var ende := i == 0 or i == ringe + 2
		var t := clampf(float(i - 1) / float(ringe), 0.0, 1.0)
		var y := lerpf(-halb, halb, t)
		var r_basis := radius * lerpf(0.86, 0.95, t)
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in seiten + 1:
			var jj := j % seiten
			var winkel := TAU * float(jj) / float(seiten)
			var rel := 1.0
			if jj % 2 == 0:
				rel += amplituden[jj >> 1]
			else:
				rel -= amplituden[jj >> 1] * 0.8
			rel *= 1.0 + 0.05 * rauschen.get_noise_3d(cos(winkel), y * 0.6, sin(winkel))
			for kn in knoten:
				var dw := angle_difference(winkel, kn.x)
				var dy := (y - kn.y) / (radius * 0.9)
				rel += 0.09 * kn.z * exp(-dw * dw / 0.35 - dy * dy)
			var r := minf(r_basis * rel, radius)
			var yy := y
			if ende:
				# Splitter: manche Ecken ragen weit hinaus, dünner werdend.
				var zacke := rng.randf()
				zacke = zacke * zacke * zacke
				var weite := radius * (0.12 + 0.5 * zacke)
				yy = y + weite * (1.0 if i > 0 else -1.0)
				r *= lerpf(0.9, 0.6, zacke)
			zeile.append(Vector3(cos(winkel) * r, yy, -sin(winkel) * r))
			uv.append(Vector2(float(j) / float(seiten) * float(n_u), yy * KACHEL_V * kachel))
			var ao := 0.9 if jj % 2 == 0 else 0.74
			if ende:
				ao *= 0.8
			var m := moos * (0.34 + 0.45 * rauschen.get_noise_3d(cos(winkel) * 2.0, y * 1.1, sin(winkel) * 2.0))
			fa.append(Color(ao, ao, ao, clampf(m, 0.0, 1.0)))
			ar.append(Vector2(BORKE, 0.0))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	gitter(st, zeilen, uvs, farben, arten, true)

	# Bruchflächen: helles, faseriges Holz, zur Mitte hin morsch und dunkel.
	for seite: float in [-1.0, 1.0]:
		var rand := zeilen[0] if seite < 0.0 else zeilen[zeilen.size() - 1]
		var mitte := Vector3(0.0, seite * (halb - radius * 0.1), 0.0)
		_bruchflaeche(st, rand, mitte, Vector3.UP * seite, rng)

	# Aststummel, kurz: Sie ragen höchstens ein Zehntel des Radius aus der
	# Kapsel.
	for k in stummel:
		var y := rng.randf_range(-halb * 0.7, halb * 0.7)
		var winkel := rng.randf() * TAU
		var aussen := Vector3(cos(winkel), 0.0, -sin(winkel))
		var start := Vector3(0.0, y, 0.0) + aussen * radius * 0.5
		var richtung := (aussen + Vector3.UP * rng.randf_range(-0.5, 0.5)).normalized()
		var ende_p := start + richtung * radius * rng.randf_range(0.55, 0.65)
		var punkte := PackedVector3Array([start, start.lerp(ende_p, 0.6), ende_p])
		_rohr(st, punkte, radius * 0.3, radius * 0.22, 6, 0.4, rauschen, false, true)
	return fertig(st)


## Baut den Stamm samt Beiwerk in einen fremden Sammler (für eigene
## Zusammenstellungen wie den Weltenbaum). Rückgabe wie die Metadaten von
## `netz()`.
static func stamm_in(st: SurfaceTool, o: Dictionary) -> Dictionary:
	var saat: int = o.get("saat", 1)
	var rng := PropWerkzeug.zufall(saat)
	var schlicht_: bool = o.get("schlicht", false)
	var hoehe: float = maxf(float(o.get("hoehe", 14.0)), 0.5)
	var radius: float = o.get("radius", 0.5)
	var radius_oben: float = o.get("radius_oben", radius * 0.55)
	var rippen: int = o.get("rippen", 0 if schlicht_ else clampi(12 + int(radius * 4.0), 12, 20))
	var seiten: int = o.get("seiten", 8 if schlicht_ else maxi(16, rippen * 2))
	var tiefe: float = o.get("rippen_tiefe", 0.07)
	var drehung: float = o.get("drehung", 0.45)
	var ring_abstand: float = o.get("ring_abstand", clampf(hoehe / 8.0, 1.5, 4.0))
	var neigung: Vector2 = o.get("neigung", Vector2.ZERO)
	var krumm: float = o.get("krumm", hoehe * 0.015)
	var anlauf: float = o.get("anlauf", 0.35)
	# Schlanke Stämme bekommen wenige, flache Anläufe, Riesen hohe Bretter.
	var anzahl_wurzeln: int = o.get("brettwurzeln",
			0 if schlicht_ else 4 + int(minf(radius, 1.5) * 2.0))
	var reichweite: float = o.get("wurzel_reichweite", clampf(radius * 2.2, 0.5, 3.5))
	var wurzel_hoehe: float = o.get("wurzel_hoehe", clampf(radius * 2.8, 0.6, 5.0))
	var wurzel_dicke: float = o.get("wurzel_dicke", clampf(radius * 0.28, 0.1, 0.6))
	var moos: float = o.get("moos", 1.0)
	var pilze: int = o.get("pilze", 0)
	var efeu: int = o.get("efeu", 0)
	var leuchtpilze: int = o.get("leuchtpilze", 0)
	var aeste: int = o.get("aeste", 0)
	var ast_start: float = o.get("ast_start", 0.6)
	var ast_laenge: float = o.get("ast_laenge", hoehe * 0.28)
	var ast_steil: float = o.get("ast_steil", 0.75)
	var oben: String = o.get("oben", "offen")
	if schlicht_:
		rippen = 0
		pilze = 0
		efeu = 0
		leuchtpilze = 0
		aeste = mini(aeste, 3)
	var rauschen := _rauschen(saat)

	var phase := rng.randf() * TAU
	var schwung := Vector2.from_angle(rng.randf() * TAU)
	var achse := {"hoehe": hoehe, "neigung": neigung, "krumm": krumm, "phase": phase,
			"schwung": schwung, "radius": radius, "radius_oben": radius_oben,
			"anlauf": anlauf}

	# Brettwurzeln vorab würfeln: Der Stamm schwillt zu ihnen hin an.
	# Die schlichte Fassung hat keine Bretter, nur vier Wülste am Fuß.
	var wurzeln: Array[Dictionary] = []
	var wulst_zahl := 4 if schlicht_ else anzahl_wurzeln
	var start_w := rng.randf() * TAU
	for i in wulst_zahl:
		var w := {
			"winkel": start_w + TAU * (float(i) + rng.randf_range(-0.28, 0.28)) / float(wulst_zahl),
			"reichweite": reichweite * rng.randf_range(0.6, 1.15),
			"hoehe": wurzel_hoehe * rng.randf_range(0.6, 1.2),
			"dicke": wurzel_dicke * rng.randf_range(0.8, 1.25),
			"schlange": rng.randf_range(-0.35, 0.35),
			"kruemmung": rng.randf_range(1.5, 2.3),
		}
		var weite: float = w["reichweite"]
		w["wulst"] = weite * (0.5 if schlicht_ else 0.16)
		if schlicht_:
			w["hoehe"] = radius * 2.5
		wurzeln.append(w)

	# Ringhöhen: dicht am Fuß (dort biegt sich der Anlauf), darüber bis
	# `ring_abstand`.
	var hoehen := PackedFloat32Array([-VERSENKT, 0.0])
	var y := 0.0
	var schritt_min := 1.0 if schlicht_ else clampf(radius * 0.35, 0.2, 0.9)
	var schritt_max := maxf(ring_abstand * 1.5, hoehe / 4.5) if schlicht_ else ring_abstand
	while y < hoehe - 0.01:
		var schritt := clampf(schritt_min + y * (0.7 if schlicht_ else 0.45), schritt_min,
				schritt_max)
		schritt *= rng.randf_range(0.85, 1.15)
		y = minf(y + schritt, hoehe)
		if hoehe - y < schritt * 0.35:
			y = hoehe
		hoehen.append(y)

	var amplituden := PackedFloat32Array()
	for k in maxi(rippen, 1):
		amplituden.append(tiefe * rng.randf_range(0.45, 1.4))
	var versatz := PackedFloat32Array()
	for j in seiten:
		versatz.append(rng.randf_range(-0.22, 0.22) * TAU / float(seiten))
	# Dicke Stämme haben größere Borkenplatten: die Kachel wächst mit.
	var kachel := borkenmass(radius)
	var n_u := maxi(1, roundi(TAU * radius * KACHEL_U * kachel))

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var anzahl_ringe := hoehen.size()
	for i in anzahl_ringe:
		var yy := hoehen[i]
		var mitte := _achse(yy, achse)
		var r0 := _profil(yy, achse)
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		# Oben "bruch": die letzte Zeile wird zur Splitterkante.
		var bruchkante := oben == "bruch" and i == anzahl_ringe - 1
		for j in seiten + 1:
			var jj := j % seiten
			var winkel := TAU * float(jj) / float(seiten) + versatz[jj] + drehung * yy / hoehe
			var rel := 1.0
			var furche := false
			if rippen > 0:
				var k := (jj >> 1) % rippen
				if jj % 2 == 0:
					rel += amplituden[k] * (0.75 + 0.5 * rauschen.get_noise_2d(float(k) * 7.3, yy * 0.35))
				else:
					var k2 := ((jj + 1) >> 1) % rippen
					rel -= (amplituden[k] + amplituden[k2]) * 0.4
					furche = true
			else:
				rel += 0.035 * rauschen.get_noise_2d(float(jj) * 5.1, yy * 0.4)
			var beule := 1.0 + 0.06 * rauschen.get_noise_3d(cos(winkel) * 1.3, yy * 0.22, sin(winkel) * 1.3)
			var wulst := _wulst(winkel, yy, wurzeln)
			var r := r0 * rel * beule + wulst
			var y_ecke := yy
			if bruchkante:
				# Meist fast eben abgebrochen, nur an wenigen Rippen ein
				# hoher, dünner Splitter – kein Kranz aus Pappzacken.
				var zacke := rng.randf() * 0.12
				if jj % 2 == 0 and rng.randf() < 0.22:
					zacke = rng.randf_range(0.45, 0.9)
				y_ecke += zacke * radius_oben
				r *= lerpf(0.98, 0.72, zacke)
			var p := mitte + Vector3(cos(winkel) * r, y_ecke - yy, -sin(winkel) * r)
			zeile.append(p)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u), y_ecke * KACHEL_V * kachel))
			var ao := lerpf(0.42, 1.0, smoothstep(-0.4, 2.4, yy))
			if furche:
				ao *= 0.8
			if yy < wurzel_hoehe and not wurzeln.is_empty():
				var an_wurzel := clampf(wulst / maxf(radius * 0.25, 0.01), 0.0, 1.0)
				var eng := (1.0 - an_wurzel) * (1.0 - smoothstep(0.0, wurzel_hoehe * 0.8, yy))
				ao *= 1.0 - 0.28 * eng
			var m := 0.85 * (1.0 - smoothstep(0.1, 2.0 + radius, yy)) + (0.08 if furche else 0.0)
			m += 0.3 * rauschen.get_noise_3d(p.x * 0.9, p.y * 0.5, p.z * 0.9)
			m *= moos
			var nord := moos * (1.0 - smoothstep(0.5, maxf(2.5, hoehe * 0.45), yy))
			fa.append(Color(ao, ao, ao, clampf(m, 0.0, 1.0)))
			ar.append(Vector2(BORKE, nord))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)

	# Spitze: in wenigen Ringen zusammenlaufen lassen.
	if oben == "spitz":
		var letzte := zeilen[zeilen.size() - 1]
		var mitte_oben := _achse(hoehe, achse)
		for stufe: float in [0.45, 0.04]:
			var zeile := PackedVector3Array()
			var uv := PackedVector2Array()
			var fa := PackedColorArray()
			var ar := PackedVector2Array()
			var dy := radius_oben * (2.0 if stufe > 0.1 else 4.5)
			for j in seiten + 1:
				var p := mitte_oben + (letzte[j] - mitte_oben) * stufe + Vector3.UP * dy
				zeile.append(p)
				uv.append(Vector2(float(j) / float(seiten) * float(n_u), p.y * KACHEL_V * kachel))
				fa.append(Color(1.0, 1.0, 1.0, 0.0))
				ar.append(Vector2(BORKE, 0.0))
			zeilen.append(zeile)
			uvs.append(uv)
			farben.append(fa)
			arten.append(ar)

	gitter(st, zeilen, uvs, farben, arten, true)

	if oben == "bruch":
		var rand := zeilen[zeilen.size() - 1]
		_bruchflaeche(st, rand, _achse(hoehe, achse) + Vector3.UP * (radius_oben * 0.1),
				Vector3.UP, rng)

	# Brettwurzeln
	if not schlicht_:
		var r_boden := _profil(0.0, achse)
		for w in wurzeln:
			brettwurzel_in(st, _achse(0.0, achse), float(w["winkel"]), r_boden,
					float(w["reichweite"]), float(w["hoehe"]), float(w["dicke"]),
					float(w["schlange"]), float(w["kruemmung"]), moos, rauschen)

	# Äste, die in die Krone führen, und der Leittrieb als letzter Punkt.
	var spitzen := PackedVector3Array()
	var zweig_spitzen := PackedVector3Array()
	var ast_radien := PackedFloat32Array()
	var ast_seiten := 5 if schlicht_ else 7
	for k in aeste:
		var t := (float(k) + rng.randf_range(0.1, 0.9)) / float(maxi(aeste, 1))
		var ya := lerpf(ast_start, 0.9, t) * hoehe
		var winkel := phase + float(k) * 2.39996 + rng.randf_range(-0.3, 0.3)
		var aussen := Vector3(cos(winkel), 0.0, -sin(winkel))
		var steil := ast_steil * rng.randf_range(0.8, 1.2)
		var laenge := ast_laenge * rng.randf_range(0.75, 1.1) * lerpf(1.1, 0.8, t)
		var start := _achse(ya, achse)
		var ra := _profil(ya, achse) * rng.randf_range(0.42, 0.58)
		var punkte := PackedVector3Array()
		var stuecke := 2 if schlicht_ else 4
		for s in stuecke + 1:
			var f := float(s) / float(stuecke)
			var p := start + aussen * (cos(steil) * laenge * f) \
					+ Vector3.UP * (sin(steil) * laenge * f + laenge * 0.18 * f * f)
			punkte.append(p)
		_rohr(st, punkte, ra, ra * 0.3, ast_seiten, moos * 0.3, rauschen, true, false)
		spitzen.append(punkte[stuecke])
		ast_radien.append(laenge)
		# Ein Zweig in der zweiten Hälfte, schräg zur Seite.
		if not schlicht_:
			var gabel := punkte[2].lerp(punkte[3], rng.randf())
			var seitlich := aussen.cross(Vector3.UP).normalized() * (1.0 if rng.randf() < 0.5 else -1.0)
			var zweig_richtung := (aussen * 0.5 + seitlich * 0.8 + Vector3.UP * 0.5).normalized()
			var zweig_laenge := laenge * rng.randf_range(0.4, 0.55)
			var zweig := PackedVector3Array()
			for s in 3:
				var f := float(s) / 2.0
				zweig.append(gabel + zweig_richtung * zweig_laenge * f
						+ Vector3.UP * zweig_laenge * 0.15 * f * f)
			_rohr(st, zweig, ra * 0.4, ra * 0.12, 5, moos * 0.2, rauschen, true, false)
			zweig_spitzen.append(zweig[2])
	if aeste > 0:
		spitzen.append(_achse(hoehe, achse))
		ast_radien.append(ast_laenge)

	# Beiwerk
	for g in pilze:
		var winkel := rng.randf() * TAU
		var yg := rng.randf_range(minf(1.2, hoehe * 0.25), minf(hoehe * 0.4, 7.0))
		var breite := clampf(radius * rng.randf_range(0.3, 0.45), 0.14, 0.9)
		for k in rng.randi_range(2, 4):
			var yk := yg + float(k) * breite * rng.randf_range(0.45, 0.7)
			var wk := winkel + rng.randf_range(-0.25, 0.25) * 0.5 / maxf(radius, 0.2)
			var ort := _oberflaeche(wk, yk, achse, wurzeln, 0.9)
			konsolenpilz_in(st, ort, Vector3(cos(wk), 0.0, -sin(wk)),
					breite * rng.randf_range(0.7, 1.15), rng)
	for g in efeu:
		_efeu_ranke(st, rng, achse, wurzeln, hoehe, radius, tiefe)
	for g in leuchtpilze:
		# In den Winkeln zwischen zwei Wurzeln, dicht am Stamm.
		var winkel := rng.randf() * TAU
		if wurzeln.size() >= 2:
			var i := rng.randi_range(0, wurzeln.size() - 1)
			var a: float = wurzeln[i]["winkel"]
			var b: float = wurzeln[(i + 1) % wurzeln.size()]["winkel"]
			winkel = a + angle_difference(a, b) * rng.randf_range(0.35, 0.65)
		var boden := _oberflaeche(winkel, 0.05, achse, wurzeln, 1.02)
		var aussen := Vector3(cos(winkel), 0.0, -sin(winkel))
		var groesse := clampf(radius * 0.08, 0.035, 0.3)
		for k in rng.randi_range(3, 6):
			var ort := boden + aussen * rng.randf_range(0.0, groesse * 3.0) \
					+ aussen.cross(Vector3.UP) * rng.randf_range(-groesse * 3.0, groesse * 3.0)
			leuchtpilz_in(st, ort, groesse * rng.randf_range(0.6, 1.3), rng)

	# Umriss am Boden für den Verdeckungskranz.
	var fuss := PackedFloat32Array()
	var r_null := _profil(0.0, achse)
	for k in FUSS_WINKEL:
		var winkel := TAU * float(k) / float(FUSS_WINKEL)
		var r := r_null + _wulst(winkel, 0.0, wurzeln)
		if not schlicht_:
			for w in wurzeln:
				var d := absf(angle_difference(winkel, float(w["winkel"])))
				var spitze := (r_null + float(w["reichweite"])) * clampf(1.0 - d / 0.12, 0.0, 1.0)
				r = maxf(r, spitze)
		fuss.append(r)

	return {"ast_spitzen": spitzen, "zweig_spitzen": zweig_spitzen, "ast_radien": ast_radien,
			"fuss_radien": fuss}


# ---------------------------------------------------------------- Achse, Profil

static func _achse(y: float, a: Dictionary) -> Vector3:
	var hoehe: float = a["hoehe"]
	var neigung: Vector2 = a["neigung"]
	var krumm: float = a["krumm"]
	var phase: float = a["phase"]
	var schwung: Vector2 = a["schwung"]
	var t := clampf(y / hoehe, 0.0, 1.3)
	var versatz := neigung * pow(t, 1.5) + schwung * krumm * sin(t * PI * 1.3 + phase) * t
	return Vector3(versatz.x, y, versatz.y)


## Grundradius in der Höhe y: oben verjüngt, unten zum Anlauf geweitet.
## Der Anlauf reicht bei dünnen Stämmen bis Brusthöhe, bei dicken bis zum
## Anderthalbfachen des Radius – sonst läge er bei einem Riesen als flache
## Schürze auf dem Boden.
static func _profil(y: float, a: Dictionary) -> float:
	var radius: float = a["radius"]
	var radius_oben: float = a["radius_oben"]
	var hoehe: float = a["hoehe"]
	var anlauf: float = a["anlauf"]
	var brust := minf(maxf(1.3, radius * 1.5), hoehe * 0.5)
	if y <= brust:
		var t := clampf(1.0 - y / brust, 0.0, 1.8)
		return radius * (1.0 + anlauf * t * t)
	var u := clampf((y - brust) / maxf(hoehe - brust, 0.01), 0.0, 1.0)
	return lerpf(radius, radius_oben, pow(u, 0.85))


## Anschwellen des Stamms zu den Wurzeln hin.
static func _wulst(winkel: float, y: float, wurzeln: Array[Dictionary]) -> float:
	var summe := 0.0
	var yy := maxf(y, 0.0)
	for w in wurzeln:
		var hh: float = float(w["hoehe"]) * 0.75
		if yy >= hh:
			continue
		var d := angle_difference(winkel, float(w["winkel"]))
		var f := 1.0 - yy / hh
		summe += float(w["wulst"]) * exp(-(d * d) / float(w.get("breite", 0.07))) * f * f
	return summe


## Punkt auf der Stammoberfläche (ohne Rippen), `ueber` > 1 hebt ihn ab.
static func _oberflaeche(winkel: float, y: float, a: Dictionary, wurzeln: Array[Dictionary],
		ueber: float) -> Vector3:
	var r := _profil(y, a) * ueber + _wulst(winkel, y, wurzeln)
	return _achse(y, a) + Vector3(cos(winkel) * r, 0.0, -sin(winkel) * r)


## Maßstab der Borke: Bei dicken Stämmen werden die Platten größer, sonst
## läse sich ein Riese wie ein feinporiger Pfahl. 1 bei dünnen Stämmen.
static func borkenmass(radius: float) -> float:
	return 1.0 / (1.0 + 0.35 * maxf(radius - 0.3, 0.0))


static func _rauschen(saat: int) -> FastNoiseLite:
	var r := FastNoiseLite.new()
	r.seed = saat
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX
	r.frequency = 1.0
	r.fractal_octaves = 2
	return r


# ================================================================ Bausteine

## Eine Brettwurzel: ein dünnes, geschwungenes Brett von der Stammachse
## bei `mitte` in Richtung `winkel` (0 = +X, gegen den Uhrzeigersinn von
## oben, z = -sin). Sie beginnt im Stamm (`r_stamm` = Radius am Boden),
## reicht `reichweite` Meter hinaus und steigt am Stamm `hoehe` Meter hoch.
## Die Oberkante fällt hohl zur Spitze (`kruemmung` 1,5–2,3), die Spitze
## taucht in den Boden. `schlange` biegt sie seitlich.
static func brettwurzel_in(st: SurfaceTool, mitte: Vector3, winkel: float, r_stamm: float,
		reichweite: float, hoehe: float, dicke: float, schlange: float, kruemmung: float,
		moos: float, rauschen: FastNoiseLite) -> void:
	const SPALTEN := 8
	var stufen := PackedFloat32Array([0.0, 0.42, 0.76, 0.93, 1.0, 0.93, 0.76, 0.42, 0.0])
	var r0 := r_stamm * 0.72
	var r1 := r_stamm + reichweite
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	for i in SPALTEN:
		var s := float(i) / float(SPALTEN - 1)
		var rho := lerpf(r0, r1, s)
		var w := winkel + schlange * sin(s * PI) * reichweite / maxf(rho, 0.1) * 0.5
		var er := Vector3(cos(w), 0.0, -sin(w))
		var et := Vector3(-sin(w), 0.0, -cos(w))
		var oben := hoehe * pow(1.0 - s, kruemmung) - 0.3 * s * s
		var unten := -VERSENKT * 0.7
		var halb := dicke * 0.5 * (1.0 - 0.5 * s)
		var basis := mitte + er * rho
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		var bogen := 0.0
		var vorher := Vector3.ZERO
		for k in stufen.size():
			var v := stufen[k]
			var seite := 1.0 if k < 4 else (-1.0 if k > 4 else 0.0)
			var yy := lerpf(unten, oben, v)
			var dick := halb * (sqrt(maxf(0.0, 1.0 - v * v * v)) * 0.85 + 0.15) \
					* (1.0 + 0.6 * (1.0 - v) * (1.0 - v))
			if k == 4:
				dick = 0.0
			var beule := 1.0 + 0.25 * rauschen.get_noise_3d(basis.x * 0.7, yy * 0.7, basis.z * 0.7)
			var p := basis + Vector3.UP * yy + et * seite * dick * beule
			if k > 0:
				bogen += p.distance_to(vorher)
			vorher = p
			zeile.append(p)
			uv.append(Vector2(bogen * KACHEL_U, rho * KACHEL_V * 2.5) * borkenmass(r_stamm))
			var ao := lerpf(0.5, 1.0, smoothstep(-0.3, 1.2, yy)) * lerpf(0.7, 1.0, smoothstep(0.0, 0.3, s))
			var m := 0.2 + 0.6 * (1.0 - smoothstep(0.0, 0.8, yy)) + (0.12 if v > 0.9 else 0.0)
			m += 0.3 * rauschen.get_noise_3d(p.x * 1.1, p.y * 1.1, p.z * 1.1)
			fa.append(Color(ao, ao, ao, clampf(m * moos, 0.0, 1.0)))
			ar.append(Vector2(BORKE, 0.8 * moos))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	gitter(st, zeilen, uvs, farben, arten, false)


## Ein Konsolenpilz: halbrunde Konsole am Stamm bei `ort`, `aussen` zeigt
## vom Stamm weg. Oben gewölbt mit hellem Rand und ockerfarbenen Zonen,
## unten flach und hell.
static func konsolenpilz_in(st: SurfaceTool, ort: Vector3, aussen: Vector3, breite: float,
		rng: RandomNumberGenerator) -> void:
	var er := Vector3(aussen.x, 0.0, aussen.z).normalized()
	var et := Vector3.UP.cross(er).normalized()
	var tiefe := breite * rng.randf_range(0.5, 0.75)
	var dick := breite * rng.randf_range(0.14, 0.22)
	const K := 6
	var rand_oben := PackedVector3Array()
	var rand_unten := PackedVector3Array()
	var ring := PackedVector3Array()
	var welle := rng.randf() * TAU
	for k in K + 1:
		var a := lerpf(-PI * 0.5, PI * 0.5, float(k) / float(K))
		var w := 1.0 + 0.1 * sin(a * 5.0 + welle)
		var rp := ort + et * sin(a) * breite * 0.5 * w + er * (cos(a) * tiefe * w - dick * 0.3)
		rand_oben.append(rp + Vector3.UP * dick * 0.2)
		rand_unten.append(rp - Vector3.UP * dick * 0.25)
		ring.append(ort + (rp - ort) * 0.55 + Vector3.UP * dick * 0.8)
	var kopf := ort + Vector3.UP * dick * 1.0 - er * dick * 0.4
	var bauch := ort - Vector3.UP * dick * 0.35
	var dunkel := Color(0.3, 0.18, 0.09)
	var ocker := Color(0.62, 0.38, 0.15) * rng.randf_range(0.85, 1.05)
	var creme := Color(0.8, 0.64, 0.38)
	var unten_farbe := Color(0.74, 0.66, 0.5)
	var art := Vector2(EIGEN, 0.0)
	for k in K:
		_tri(st, kopf, ring[k], ring[k + 1], Vector3.UP + er * 0.3, dunkel, ocker, ocker, art)
		_tri(st, ring[k], rand_oben[k], rand_oben[k + 1], Vector3.UP + er * 0.5, ocker, creme, creme, art)
		_tri(st, ring[k], rand_oben[k + 1], ring[k + 1], Vector3.UP + er * 0.5, ocker, creme, ocker, art)
		var raus := (rand_oben[k] + rand_oben[k + 1]) * 0.5 - ort
		_tri(st, rand_oben[k], rand_unten[k], rand_unten[k + 1], raus, creme, unten_farbe, unten_farbe, art)
		_tri(st, rand_oben[k], rand_unten[k + 1], rand_oben[k + 1], raus, creme, unten_farbe, creme, art)
		_tri(st, bauch, rand_unten[k + 1], rand_unten[k], Vector3.DOWN, unten_farbe * 0.8,
				unten_farbe, unten_farbe, art)


## Ein kleiner Leuchtpilz (Hut und Stiel), `groesse` = Hutradius. Der Hut
## leuchtet warm (UV2.x = LEUCHT), der Stiel ist blass.
static func leuchtpilz_in(st: SurfaceTool, ort: Vector3, groesse: float,
		rng: RandomNumberGenerator) -> void:
	var stiel_h := groesse * rng.randf_range(1.2, 2.2)
	var neig := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
	var hut := ort + neig * stiel_h
	var stiel := Color(0.82, 0.78, 0.66)
	var glut := Color(1.0, 0.62, 0.26).lerp(Color(1.0, 0.8, 0.4), rng.randf())
	const N := 6
	var a := neig.cross(Vector3.RIGHT).normalized()
	if a.length_squared() < 0.01:
		a = Vector3.FORWARD
	var b := neig.cross(a).normalized()
	for k in N:
		var w0 := TAU * float(k) / float(N)
		var w1 := TAU * float(k + 1) / float(N)
		var d0 := a * cos(w0) + b * sin(w0)
		var d1 := a * cos(w1) + b * sin(w1)
		# Stiel
		var s0 := ort + d0 * groesse * 0.22 - neig * 0.2
		var s1 := ort + d1 * groesse * 0.22 - neig * 0.2
		var t0 := hut + d0 * groesse * 0.16
		var t1 := hut + d1 * groesse * 0.16
		_tri(st, s0, t0, t1, d0 + d1, stiel * 0.7, stiel, stiel, Vector2(EIGEN, 0.0))
		_tri(st, s0, t1, s1, d0 + d1, stiel * 0.7, stiel, stiel * 0.7, Vector2(EIGEN, 0.0))
		# Hut: flacher Kegel mit Unterseite
		var r0 := hut + d0 * groesse - neig * groesse * 0.25
		var r1 := hut + d1 * groesse - neig * groesse * 0.25
		var kuppe := hut + neig * groesse * 0.55
		_tri(st, kuppe, r0, r1, neig + (d0 + d1) * 0.5, glut, glut * 0.8, glut * 0.8,
				Vector2(LEUCHT, 0.0))
		_tri(st, hut, r1, r0, -neig, glut * 0.5, glut * 0.6, glut * 0.6, Vector2(LEUCHT, 0.0))


## Eine Efeuranke, die sich den Stamm hinaufwindet: ein Band aus Blättern,
## unten dicht und breit, oben licht. Die Blätter liegen fast flach auf der
## Borke und schauen ein wenig nach oben ins Licht.
static func _efeu_ranke(st: SurfaceTool, rng: RandomNumberGenerator, achse: Dictionary,
		wurzeln: Array[Dictionary], hoehe: float, radius: float, tiefe: float) -> void:
	var winkel := rng.randf() * TAU
	var drift := rng.randf_range(-0.1, 0.1) / maxf(radius, 0.3)
	var bis := minf(hoehe * rng.randf_range(0.35, 0.6), 11.0)
	var blatt := clampf(radius * 0.1 + 0.1, 0.12, 0.34)
	var band := clampf(radius * 0.35, 0.25, 0.9)
	var schritt := blatt * 0.55
	var phase := rng.randf() * TAU
	var y := 0.1
	while y < bis:
		var anteil := y / bis
		var mitte_w := winkel + drift * y + 0.3 * sin(y * 0.7 + phase) / maxf(radius, 0.3)
		# Oben lichter und schmaler: die Ranke läuft aus.
		var anzahl := rng.randi_range(1, 3) if anteil < 0.6 else rng.randi_range(0, 2)
		for n in anzahl:
			var quer_m := rng.randf_range(-1.0, 1.0) * band * lerpf(1.0, 0.45, anteil)
			var w := mitte_w + quer_m / maxf(radius, 0.2)
			var aussen := Vector3(cos(w), 0.0, -sin(w))
			var ort := _oberflaeche(w, y + rng.randf_range(-schritt, schritt) * 0.5, achse,
					wurzeln, 1.0 + tiefe * 1.2)
			var seit := aussen.cross(Vector3.UP).normalized()
			var g := blatt * rng.randf_range(0.7, 1.3) * lerpf(1.0, 0.7, anteil)
			var dreh := rng.randf_range(-1.2, 1.2)
			var richtung := (Vector3.UP * cos(dreh) + seit * sin(dreh)).normalized()
			richtung = (richtung + aussen * 0.35).normalized()
			var normale := (aussen * 0.8 + Vector3.UP * 0.35 - richtung * 0.2).normalized()
			var quer := richtung.cross(normale).normalized() * g * 0.62
			var basis := ort + aussen * 0.02
			var spitze := basis + richtung * g
			# Herzform aus vier Dreiecken: breite Lappen, stumpfe Spitze.
			var mitte_b := basis + richtung * g * 0.45 + normale * g * 0.08
			var l1 := basis + richtung * g * 0.38 + quer
			var l2 := basis + richtung * g * 0.38 - quer
			var s1 := basis + richtung * g * 0.8 + quer * 0.45
			var s2 := basis + richtung * g * 0.8 - quer * 0.45
			var gruen := Color(0.15, 0.27, 0.08).lerp(Color(0.26, 0.4, 0.13), rng.randf())
			gruen = gruen * lerpf(0.85, 1.1, rng.randf())
			var art := Vector2(EIGEN, 0.0)
			_tri(st, basis, l1, mitte_b, normale, gruen * 0.7, gruen, gruen * 1.05, art)
			_tri(st, mitte_b, l1, s1, normale, gruen * 1.05, gruen, gruen * 1.1, art)
			_tri(st, mitte_b, s1, spitze, normale, gruen * 1.05, gruen * 1.1, gruen * 1.15, art)
			_tri(st, basis, mitte_b, l2, normale, gruen * 0.7, gruen * 1.05, gruen, art)
			_tri(st, mitte_b, s2, l2, normale, gruen * 1.05, gruen * 1.1, gruen, art)
			_tri(st, mitte_b, spitze, s2, normale, gruen * 1.05, gruen * 1.15, gruen * 1.1, art)
		y += schritt * rng.randf_range(0.7, 1.3)


## Bruchfläche über einem Ring von Randpunkten: faseriges, helles Holz, zur
## Mitte hin eingesunken und dunkler (morsch). `aussen` zeigt aus dem Holz.
static func _bruchflaeche(st: SurfaceTool, rand: PackedVector3Array, mitte: Vector3,
		aussen: Vector3, rng: RandomNumberGenerator) -> void:
	var n := rand.size() - 1
	var holz := Color(0.46, 0.34, 0.21)
	var morsch := Color(0.16, 0.1, 0.06)
	# Innenring auf gemeinsamer Höhe knapp über dem Bruchgrund: Die Splitter
	# stehen darüber, statt die Fläche mit sich hochzuziehen.
	var grund := INF
	for j in n:
		grund = minf(grund, (rand[j] - mitte).dot(aussen))
	var innen := PackedVector3Array()
	var toene := PackedFloat32Array()
	for j in n:
		var p := rand[j]
		var flach := p - aussen * ((p - mitte).dot(aussen) - grund)
		var q := mitte + (flach - mitte) * 0.6
		q += aussen * rng.randf_range(-0.02, 0.06) * p.distance_to(mitte)
		innen.append(q)
		toene.append(rng.randf_range(0.8, 1.1))
	var tief := mitte + aussen * (grund - mitte.distance_to(rand[0]) * 0.18)
	var art := Vector2(EIGEN, 0.0)
	for j in n:
		var j2 := (j + 1) % n
		var a := holz * toene[j]
		var b := holz * toene[j2]
		_tri(st, rand[j], innen[j], innen[j2], aussen, a * 0.8, a, b, art)
		_tri(st, rand[j], innen[j2], rand[j2], aussen, a * 0.8, b, b * 0.8, art)
		_tri(st, tief, innen[j2], innen[j], aussen, morsch, b * 0.7, a * 0.7, art)


## Rohr entlang eines Punktzugs (Äste, Zweige, Stummel). Rahmen mit
## Paralleltransport, damit es sich nicht verdrillt.
static func _rohr(st: SurfaceTool, punkte: PackedVector3Array, r0: float, r1: float,
		seiten: int, moos: float, rauschen: FastNoiseLite, spitz: bool,
		gebrochen: bool) -> void:
	var n := punkte.size()
	if n < 2:
		return
	var t0 := (punkte[1] - punkte[0]).normalized()
	var hilfe := Vector3.UP if absf(t0.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var normale := t0.cross(hilfe).normalized()
	var n_u := maxi(1, roundi(TAU * r0 * KACHEL_U))
	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var bogen := 0.0
	var zeilen_zahl := n + (1 if spitz or gebrochen else 0)
	for i in zeilen_zahl:
		var ii := mini(i, n - 1)
		var t: Vector3
		if ii == 0:
			t = t0
		elif ii == n - 1:
			t = (punkte[n - 1] - punkte[n - 2]).normalized()
		else:
			t = (punkte[ii + 1] - punkte[ii - 1]).normalized()
		normale = (normale - t * normale.dot(t)).normalized()
		var bi := t.cross(normale)
		var f := float(ii) / float(n - 1)
		var rad := lerpf(r0, r1, f)
		var mitte := punkte[ii]
		if i >= n:
			# Abschluss: Spitze oder Bruch
			rad = r1 * (0.12 if spitz else 0.5)
			mitte += t * r1 * (1.6 if spitz else 0.3)
		if ii > 0 and i < n:
			bogen += punkte[ii].distance_to(punkte[ii - 1])
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in seiten + 1:
			var a := TAU * float(j % seiten) / float(seiten)
			var richtung := normale * cos(a) + bi * sin(a)
			var r := rad * (1.0 + 0.08 * rauschen.get_noise_3d(mitte.x + richtung.x,
					mitte.y + richtung.y, mitte.z + richtung.z))
			var p := mitte + richtung * r
			if i >= n and gebrochen:
				p += t * rad * randf_hash(j, i) * 1.2
			zeile.append(p)
			uv.append(Vector2(float(j) / float(seiten) * float(n_u), bogen * KACHEL_V * 2.0))
			var ao := lerpf(0.72, 1.0, f)
			fa.append(Color(ao, ao, ao, clampf(moos, 0.0, 1.0)))
			ar.append(Vector2(BORKE, 0.3))
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)
	gitter(st, zeilen, uvs, farben, arten, true)
	if gebrochen:
		# Bruchfläche: helles Holz, zur Mitte hin eingesunken.
		var rand := zeilen[zeilen.size() - 1]
		var t_ende := (punkte[n - 1] - punkte[n - 2]).normalized()
		var mitte_ende := punkte[n - 1] + t_ende * r1 * 0.1
		var holz := Color(0.5, 0.37, 0.23)
		for j in seiten:
			_tri(st, mitte_ende, rand[j], rand[j + 1], t_ende, holz * 0.6, holz, holz,
					Vector2(EIGEN, 0.0))


## Fester Pseudozufall 0..1 aus zwei Ganzzahlen (für Splitter ohne rng).
static func randf_hash(a: int, b: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h) % 1000) / 1000.0


# ================================================================ Gitter

## Schreibt ein Gitter aus `zeilen` (gleich lange Punktreihen) als Dreiecke.
## Die Normalen kommen aus den Nachbarn im Gitter – über die Naht eines
## geschlossenen Rings (`ringsum`) hinweg, so gibt es keine Lichtkante.
## Die Vorderseite zeigt nach cross(d_spalte, d_zeile); `wenden` dreht sie.
## Bei `ringsum` ist die letzte Spalte die erste noch einmal (mit anderem
## UV) – so schließt die Textur ohne Naht.
static func gitter(st: SurfaceTool, zeilen: Array[PackedVector3Array],
		uvs: Array[PackedVector2Array], farben: Array[PackedColorArray],
		arten: Array[PackedVector2Array], ringsum: bool, wenden: bool = false) -> void:
	var r := zeilen.size()
	if r < 2:
		return
	var c := zeilen[0].size()
	var normalen: Array[PackedVector3Array] = []
	for i in r:
		var reihe := PackedVector3Array()
		reihe.resize(c)
		var zeile := zeilen[i]
		var vorher := zeilen[maxi(i - 1, 0)]
		var nachher := zeilen[mini(i + 1, r - 1)]
		for j in c:
			var jl := j - 1
			var jr := j + 1
			if ringsum:
				if jl < 0:
					jl = c - 2
				if jr > c - 1:
					jr = 1
			else:
				jl = maxi(jl, 0)
				jr = mini(jr, c - 1)
			var du := zeile[jr] - zeile[jl]
			var dv := nachher[j] - vorher[j]
			var n := du.cross(dv)
			if n.length_squared() < 1e-14:
				reihe[j] = Vector3.ZERO
				continue
			n = n.normalized()
			reihe[j] = -n if wenden else n
		normalen.append(reihe)
	# Entartete Normalen (Pole, Spitzen) von der Nachbarzeile übernehmen.
	for i in r:
		for j in c:
			if normalen[i][j] == Vector3.ZERO:
				var ersatz := Vector3.UP
				if i > 0 and normalen[i - 1][j] != Vector3.ZERO:
					ersatz = normalen[i - 1][j]
				elif i < r - 1 and normalen[i + 1][j] != Vector3.ZERO:
					ersatz = normalen[i + 1][j]
				normalen[i][j] = ersatz
	for i in r - 1:
		for j in c - 1:
			if wenden:
				_g(st, zeilen, normalen, uvs, farben, arten, i, j)
				_g(st, zeilen, normalen, uvs, farben, arten, i, j + 1)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j)
				_g(st, zeilen, normalen, uvs, farben, arten, i, j + 1)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j + 1)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j)
			else:
				_g(st, zeilen, normalen, uvs, farben, arten, i, j)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j)
				_g(st, zeilen, normalen, uvs, farben, arten, i, j + 1)
				_g(st, zeilen, normalen, uvs, farben, arten, i, j + 1)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j)
				_g(st, zeilen, normalen, uvs, farben, arten, i + 1, j + 1)


static func _g(st: SurfaceTool, zeilen: Array[PackedVector3Array],
		normalen: Array[PackedVector3Array], uvs: Array[PackedVector2Array],
		farben: Array[PackedColorArray], arten: Array[PackedVector2Array], i: int, j: int) -> void:
	st.set_color(farben[i][j])
	st.set_uv(uvs[i][j])
	st.set_uv2(arten[i][j])
	st.set_normal(normalen[i][j])
	st.add_vertex(zeilen[i][j])


## Ein Dreieck mit eigener Farbe je Ecke, Vorderseite nach `aussen`,
## Flächennormale. UV planar aus der Lage (damit die Tangenten nie entarten).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, aussen: Vector3,
		fa: Color, fb: Color, fc: Color, art: Vector2) -> void:
	var kreuz := (b - a).cross(c - a)
	if kreuz.length_squared() < 1e-14:
		return
	var pb := b
	var pc := c
	var fbb := fb
	var fcc := fc
	# Vorderseite: cross(b-a, c-a) zeigt ENTGEGEN der Außenrichtung
	# (siehe PropWerkzeug.flaeche).
	if kreuz.dot(aussen) > 0.0:
		pb = c
		pc = b
		fbb = fc
		fcc = fb
		kreuz = -kreuz
	var n := -kreuz.normalized()
	for e in 3:
		var p := a if e == 0 else (pb if e == 1 else pc)
		var f := fa if e == 0 else (fbb if e == 1 else fcc)
		st.set_color(Color(f.r, f.g, f.b, 0.0))
		st.set_uv(Vector2(p.x + p.y * 0.5, p.z + p.y * 0.5) * 3.0)
		st.set_uv2(art)
		st.set_normal(n)
		st.add_vertex(p)


# ================================================================ Stoff

static var _stoffe: Dictionary = {}
static var _shader_uv: Shader = null
static var _shader_welt: Shader = null
static var _moos: ImageTexture = null

## Der Borkenstoff: Rinde der Bibliothek (Farbe und Normalen), Moos nach
## Scheitelmaske, Weltlage (oben, Norden) und Flecken, Verdeckung aus der
## Scheitelfarbe, Beiwerk (Pilze, Efeu, Holz) in Eigenfarbe, Leuchtpilze
## mit Eigenleuchten. Geteilt – nie verändern.
##
## Optionen:
##   welt   Rinde in Weltprojektion statt über UV (senkrechte Furchen, für
##          Riesen, deren Teile nahtlos ineinander übergehen sollen;
##          `welt_kachel` = Vector2(rundum, längs) Wiederholungen je Meter)
##   farbe  Tönung der Borke (Vorgabe weiß = Rinde wie in der Bibliothek)
##   moos_farbe, moos_oben (0.6), moos_nord (0.8), flechten (0.6)
static func borkenstoff(optionen: Dictionary = {}) -> ShaderMaterial:
	var schluessel := JSON.stringify(optionen)
	if _stoffe.has(schluessel):
		return _stoffe[schluessel]
	var welt: bool = optionen.get("welt", false)
	if welt and _shader_welt == null:
		_shader_welt = Shader.new()
		_shader_welt.code = BORKE_SHADER.replace("//WELT", "#define WELT")
	if not welt and _shader_uv == null:
		_shader_uv = Shader.new()
		_shader_uv.code = BORKE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader_welt if welt else _shader_uv
	var rinde := Materialbibliothek.rinde()
	m.set_shader_parameter("rinde", rinde.albedo_texture)
	m.set_shader_parameter("rinde_normal", rinde.normal_texture)
	m.set_shader_parameter("moos", moostextur())
	m.set_shader_parameter("borke_farbe", optionen.get("farbe", Color(1.0, 1.0, 1.0)))
	m.set_shader_parameter("moos_farbe", optionen.get("moos_farbe", Color(1.0, 1.0, 1.0)))
	m.set_shader_parameter("moos_oben", optionen.get("moos_oben", 0.6))
	m.set_shader_parameter("flechten", optionen.get("flechten", 0.6))
	m.set_shader_parameter("moos_nord", optionen.get("moos_nord", 0.8))
	m.set_shader_parameter("welt_kachel", optionen.get("welt_kachel", Vector2(0.5, 0.14)))
	_stoffe[schluessel] = m
	return m


## Moos als Detailtextur, 128²: RGB = Moosfarbe mit hellen Polstern und
## dunklen Lücken, A = Fleckenrauschen (wo das Moos zuerst wächst).
## Auch `Findling` nutzt sie.
static func moostextur() -> ImageTexture:
	if _moos != null:
		return _moos
	const K := 128
	var grob := FastNoiseLite.new()
	grob.seed = 9101
	grob.frequency = 0.035
	grob.fractal_octaves = 3
	var fein := FastNoiseLite.new()
	fein.seed = 9102
	fein.noise_type = FastNoiseLite.TYPE_CELLULAR
	fein.frequency = 0.16
	fein.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var bild_grob := grob.get_seamless_image(K, K)
	var bild_fein := fein.get_seamless_image(K, K)
	var dg := bild_grob.get_data()
	var df := bild_fein.get_data()
	var daten := PackedByteArray()
	daten.resize(K * K * 4)
	var dunkel := Farben.MOOS * 0.5
	var hell := Farben.MOOS_HELL * 0.92
	var stufe_g := dg.size() / (K * K)
	var stufe_f := df.size() / (K * K)
	for i in K * K:
		var g := float(dg[i * stufe_g]) / 255.0
		var f := float(df[i * stufe_f]) / 255.0
		# Polster: hell in der Zelle, dunkel in den Fugen
		var t := clampf(f * 1.35 - 0.1, 0.0, 1.0) * (0.75 + 0.5 * g)
		var c := dunkel.lerp(hell, clampf(t, 0.0, 1.0))
		daten[i * 4] = int(clampf(c.r, 0.0, 1.0) * 255.0)
		daten[i * 4 + 1] = int(clampf(c.g, 0.0, 1.0) * 255.0)
		daten[i * 4 + 2] = int(clampf(c.b, 0.0, 1.0) * 255.0)
		daten[i * 4 + 3] = int(clampf(g * 0.8 + f * 0.2, 0.0, 1.0) * 255.0)
	var bild := Image.create_from_data(K, K, false, Image.FORMAT_RGBA8, daten)
	bild.generate_mipmaps()
	_moos = ImageTexture.create_from_image(bild)
	return _moos


## Rinde über UV (Vorgabe) oder in Weltprojektion (`#define WELT`). Moos:
## Scheitelmaske + nach oben + nach Norden (-Z), mit Flecken am Rand; wo
## Moos wächst, glättet sich die Normale. Beiwerk (UV2.x ≥ 0,5) nimmt die
## Scheitelfarbe als Farbe, Leuchtpilze (≥ 1,5) leuchten.
const BORKE_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
//WELT

uniform sampler2D rinde : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rinde_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moos : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 borke_farbe : source_color = vec4(1.0);
uniform vec4 moos_farbe : source_color = vec4(1.0);
uniform float moos_oben = 0.6;
uniform float moos_nord = 0.8;
uniform float flechten = 0.6;
uniform vec2 welt_kachel = vec2(0.5, 0.14);

varying vec3 v_wn;
#ifdef WELT
varying vec3 v_welt;
#endif

void vertex() {
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
#ifdef WELT
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
#endif
}

void fragment() {
	float art = UV2.x;
	float borke = 1.0 - step(0.5, art);
	vec3 wn = normalize(v_wn);
#ifdef WELT
	vec2 uv_x = vec2(v_welt.z * welt_kachel.x, v_welt.y * welt_kachel.y);
	vec2 uv_z = vec2(v_welt.x * welt_kachel.x, v_welt.y * welt_kachel.y);
	float ax = wn.x * wn.x;
	float az = wn.z * wn.z;
	float wx = ax / max(ax + az, 0.0001);
	vec3 rc = mix(texture(rinde, uv_z).rgb, texture(rinde, uv_x).rgb, wx);
	vec3 rn = mix(texture(rinde_normal, uv_z).rgb, texture(rinde_normal, uv_x).rgb, wx);
	vec2 moos_uv = mix(uv_z, uv_x, step(0.5, wx)) * vec2(1.6, 5.0);
#else
	vec3 rc = texture(rinde, UV).rgb;
	vec3 rn = texture(rinde_normal, UV).rgb;
	vec2 moos_uv = UV * vec2(1.3, 4.5);
#endif
	vec4 mt = texture(moos, moos_uv);
	// großflächig: Flecken für Flechten und eine ruhige Farbschwankung
	vec4 gross = texture(moos, moos_uv * 0.12 + vec2(0.37, 0.61));
	float m = COLOR.a;
	m += moos_oben * smoothstep(0.45, 0.95, wn.y);
	m += moos_nord * UV2.y * smoothstep(0.05, 0.85, -wn.z);
	float anteil = smoothstep(0.42, 0.62, m * 0.8 + (mt.a - 0.5) * 0.75) * borke;
	float flechte = smoothstep(0.6, 0.8, gross.a) * (1.0 - anteil) * flechten;

	vec3 borke_farbe_ = rc * borke_farbe.rgb * (0.82 + 0.36 * gross.a);
	float luma = dot(borke_farbe_, vec3(0.3, 0.55, 0.15));
	borke_farbe_ = mix(borke_farbe_, vec3(0.6, 0.64, 0.54) * (0.5 + luma * 1.3), flechte * 0.6);
	vec3 moos_farbe_ = mt.rgb * moos_farbe.rgb;
	vec3 flaeche = mix(borke_farbe_, moos_farbe_, anteil) * COLOR.rgb;
	ALBEDO = mix(COLOR.rgb, flaeche, borke);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), rn, borke * (1.0 - anteil * 0.75));
	NORMAL_MAP_DEPTH = 1.6;
	ROUGHNESS = mix(0.7, 0.95, borke);
	SPECULAR = 0.3;
	EMISSION = COLOR.rgb * 1.8 * step(1.5, art);
}
"""
