extends RefCounted
class_name Findling
## Findlinge, deren Optik genau zu ihrer Kollision passt (Plan E13).
##
## Jede begehbare Fläche außerhalb des Pfads ist ein Körper – ein Kasten
## (BoxShape3D) oder ein Zylinder. Sähe der Stein anders aus als sein
## Körper, stünde die Figur in der Luft oder im Fels. Deshalb wird der Stein
## hier AUF den Kasten gebaut:
## * **Oberseite** flach und genau auf der Kastenoberkante (+y/2), in der
##   Mitte ausgetreten (hell, glatt, ohne Moos, höchstens 1,5 cm Mulde).
## * **Kante** mit wechselndem Radius (rundum 30–100 % von `rundung`, bei
##   großen Steinen 0,1–0,3 m): mal scharf gebrochen, mal abgerundet.
## * **Seiten** geschichtet und verbeult, aber nur NACH INNEN und nur unter
##   der Oberkante: Nichts ragt über den Kasten hinaus, was die Figur treffen
##   könnte. Waagerechte **Schichtfugen** alle 0,6–1,0 m (dunkel, die Schicht
##   darüber setzt vor oder zurück), niederfrequente **Beulen** und ein
##   **Anlauf**: Der Stein wird nach oben schmaler (6 % der Höhe, höchstens
##   0,12 m) und steht dadurch wie gewachsener Fels, nicht wie ein Kissen.
## * **Moos** läuft in Zungen über die Kante die Seite hinab und ein Stück
##   auf die Oberseite – kein Ring, der sich als Bordstein läse.
## * **Fuß** 1 m versenkt und unter dem Boden leicht ausgestellt, damit auf
##   unebenem Gelände keine Kante frei liegt.
## * **Verdeckungsring** (`kranz()`): ein flacher, dunkler Kranz aus
##   Scheitelfarben um den Fuß, ohne Schatten und halbdurchsichtig – der
##   Stein sitzt im Boden, statt auf ihm zu stehen.
##
## `brocken()` baut dagegen Deko-Felsen mit gewölbter Oberseite (nie flach,
## sonst sähen sie begehbar aus), `scheibe()` Trittsteine auf einem
## Zylinder: unregelmäßiger Umriss, nasses dunkles Band an der Wasserlinie,
## helle trockene Oberseite.
##
## Koordinaten: wie BoxShape3D – der Kasten `groesse` ist um den Ursprung
## zentriert. Wer den Körper mit einer Verwandlung setzt, setzt den Stein
## mit derselben (`bauen()`).
##
## Scheiteldaten (für den Stoff): COLOR.rgb Verdeckung, COLOR.a Moosanteil,
## UV2.x wie ausgetreten (0..1), UV2.y wie viel Moos oben wachsen darf. Moos
## auf allem, was nach oben schaut, rechnet der Shader dazu. Fels in
## Weltprojektion (Dreifachprojektion), also gleich dicht bei jeder Größe und
## Drehung; heller, warmer Kalk (Luma um 0,55), nicht dunkles Grau.
##
## Dreiecke: höchstens 1,5k (typisch 0,6–1,4k).

const VERSENKT := 1.0
## So weit tritt die Oberkante durch den Anlauf höchstens zurück: Weiter
## stünde die Figur am Rand sichtbar in der Luft.
const ANLAUF_GRENZE := 0.12
## Tiefe einer Schichtfuge (an der tiefsten Stelle). Tiefer, und die
## Schichten lasen sich als gestapelte Reifen.
const FUGE_TIEFE := 0.08
## Neigung der Schichten (tan 4°): Fels liegt nie ganz waagerecht.
const SCHICHT_NEIGUNG := 0.07


## Stein genau auf den Kasten `groesse` (um den Ursprung zentriert).
## Optionen: saat, rundung (größter Kantenradius oben; rundum schwankt er
## zwischen 30 % und 100 %), unruhe (Tiefe der feinen Seitenbuckel), beulen
## (Tiefe der großen Beulen), anlauf (Anteil der Höhe, um den die Oberkante
## gegenüber dem Fuß zurücktritt; höchstens `ANLAUF_GRENZE`), schichten
## (Schichtfugen an/aus), einzug (so weit zieht sich der Stein zum Boden hin
## ein – er liegt auf, statt aus dem Boden zu wachsen; für Deko), eckig
## (Exponent des Grundrisses, Vorgabe 3,6 = gerundetes Rechteck, 2 =
## Ellipse), umriss (Anteil, um den der Grundriss unregelmäßig nach innen
## springt), umriss_aussen (Anteil, um den er höchstens nach außen springt),
## moos (0..1), moos_oben (Moos auf der Oberseite, 0..1), ausgetreten (0..1),
## wasser_y (lokale Höhe einer Wasserlinie: darunter nass und dunkel),
## fuss_aus (Meter, um die der Fuß nach außen ausläuft: voll am Boden, bis
## unter die gerundete Kante – ohne Wasserlinie bis 40 % der Höhe – auf
## null; so steht ein Trittstein mit Anlauf wie gewachsener Fels im Bach
## statt wie eine Trommel. Die Oberkante bleibt, wo sie ist; Vorgabe 0).
static func netz(groesse: Vector3, optionen: Dictionary = {}) -> ArrayMesh:
	var o := _vorgaben_netz(groesse.abs() * 0.5)
	o.merge(optionen, true)
	return _koerper(groesse.abs() * 0.5, o)


## Halbe Kantenlängen (x, z) der Fläche, die auf der Oberseite sicher eben
## liegt – ohne gerundete Kante, Anlauf und Umrisssprünge. Dort stehen
## Kisten und Figur sichtbar auf dem Stein. `rund` für `scheibe()` (dann ist
## x der Radius).
static func plateau(groesse: Vector3, optionen: Dictionary = {}, rund: bool = false) -> Vector2:
	var h := groesse.abs() * 0.5
	var o := _vorgaben_scheibe(h) if rund else _vorgaben_netz(h)
	o.merge(optionen, true)
	var anlauf := minf(float(o.get("anlauf", 0.0)) * 2.0 * h.y, ANLAUF_GRENZE)
	var rand := float(o["rundung"]) + anlauf + float(o["unruhe"]) * 0.3 \
			+ float(o["umriss"]) * maxf(h.x, h.z)
	return Vector2(maxf(h.x - rand, 0.0), maxf(h.z - rand, 0.0))


static func _vorgaben_netz(h: Vector3) -> Dictionary:
	var klein := minf(h.x, h.z)
	return {
		"eckig": 3.6,
		"rundung": minf(clampf(klein * 0.2, 0.1, 0.3), h.y * 0.5),
		"unruhe": clampf(klein * 0.1, 0.04, 0.2),
		"beulen": clampf(klein * 0.12, 0.06, 0.25),
		"anlauf": 0.06,
		"schichten": true,
		"einzug": 0.0,
		"umriss": 0.035,
		"umriss_aussen": 0.0,
		"kuppe": 0.0,
		"delle": 0.012,
		"moos": 1.0,
		"moos_oben": 1.0,
		"ausgetreten": 1.0,
		"fuss_weite": 0.1,
		"nur_innen": true,
	}


## Trittstein auf einem Zylinder (Radius, Höhe, um den Ursprung zentriert):
## runde, flache Oberseite genau auf +hoehe/2. Der Umriss springt um bis zu
## 16 % nach innen und 5 % nach außen – aus der Münze wird ein Stein.
static func scheibe(radius: float, hoehe: float, optionen: Dictionary = {}) -> ArrayMesh:
	var h := Vector3(radius, hoehe * 0.5, radius)
	var o := _vorgaben_scheibe(h)
	o.merge(optionen, true)
	return _koerper(h, o)


static func _vorgaben_scheibe(h: Vector3) -> Dictionary:
	var radius := h.x
	return {
		"eckig": 2.0,
		"rundung": minf(clampf(radius * 0.12, 0.06, 0.2), h.y * 0.5),
		"unruhe": clampf(radius * 0.07, 0.03, 0.14),
		"beulen": clampf(radius * 0.08, 0.04, 0.15),
		"anlauf": 0.05,
		"schichten": false,
		"einzug": 0.0,
		"umriss": 0.16,
		"umriss_aussen": 0.05,
		"kuppe": 0.0,
		"delle": 0.01,
		"moos": 0.7,
		"moos_oben": 0.25,
		"ausgetreten": 0.9,
		"fuss_weite": 0.08,
		"nur_innen": true,
	}


## Deko-Fels ungefähr in der Größe `groesse`: gewölbt, stärker verbeult, auch
## nach außen. Nicht zum Draufstehen gedacht und ohne Passform.
static func brocken(groesse: Vector3, optionen: Dictionary = {}) -> ArrayMesh:
	var h := groesse.abs() * 0.5
	var klein := minf(h.x, h.z)
	var o := {
		"eckig": 2.6,
		"rundung": minf(klein * 0.45, h.y * 0.7),
		"unruhe": clampf(klein * 0.2, 0.05, 0.6),
		"beulen": clampf(klein * 0.15, 0.05, 0.3),
		"anlauf": 0.08,
		"schichten": h.y > 0.6,
		"einzug": minf(clampf(klein * 0.15, 0.05, 0.5), h.y * 0.5),
		"umriss": 0.12,
		"umriss_aussen": 0.0,
		"kuppe": h.y * 0.28,
		"delle": 0.0,
		"moos": 1.0,
		"moos_oben": 1.0,
		"ausgetreten": 0.0,
		"fuss_weite": 0.12,
		"nur_innen": false,
	}
	o.merge(optionen, true)
	return _koerper(h, o)


## Verdeckungsring um einen sternförmigen Umriss: `radien` sind die Abstände
## des Umrisses vom Ursprung in gleichen Winkelschritten (0 = +X, weiter
## über -Z). Der Kranz liegt flach auf der Höhe `y`, beginnt `innen` Meter
## innerhalb des Umrisses (unter dem Körper, damit kein heller Spalt
## bleibt), ist dort `staerke` dunkel und läuft `breite` Meter außerhalb
## aus. Stoff: `kranzstoff()`, ohne Schatten.
## Für Stämme: `Findling.kranz(netz.get_meta("fuss_radien"), 0.02, 1.2, 0.65, 0.3)`.
static func kranz(radien: PackedFloat32Array, y: float, breite: float,
		staerke: float = 0.6, innen: float = 0.2) -> ArrayMesh:
	var n := radien.size()
	if n < 3:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ringe := PackedFloat32Array([0.0, 0.3, 1.0])
	var alphas := PackedFloat32Array([staerke, staerke * 0.55, 0.0])
	var punkte: Array[PackedVector3Array] = []
	for k in ringe.size():
		var reihe := PackedVector3Array()
		for j in n + 1:
			var w := TAU * float(j % n) / float(n)
			# Umriss geglättet, sonst stehen Spitzen der Wurzeln als Zacken
			var r := radien[j % n] * 0.6 + (radien[(j + 1) % n] + radien[(j + n - 1) % n]) * 0.2
			var rr := maxf(r - innen, 0.0) if k == 0 else r + breite * ringe[k]
			reihe.append(Vector3(cos(w) * rr, y, -sin(w) * rr))
		punkte.append(reihe)
	var dunkel := Color(0.02, 0.025, 0.015)
	for k in ringe.size() - 1:
		for j in n:
			var a := punkte[k][j]
			var b := punkte[k][j + 1]
			var c := punkte[k + 1][j]
			var d := punkte[k + 1][j + 1]
			var fa := Color(dunkel.r, dunkel.g, dunkel.b, alphas[k])
			var fc := Color(dunkel.r, dunkel.g, dunkel.b, alphas[k + 1])
			_flach(st, a, c, b, fa, fc, fa)
			_flach(st, b, c, d, fa, fc, fc)
	var ergebnis: ArrayMesh = st.commit()
	return ergebnis


## Kranz für einen Stein aus `netz()`/`scheibe()`: um den Fuß des Kastens,
## auf dessen Unterkante (Boden).
static func kranz_fuer(groesse: Vector3, optionen: Dictionary = {}) -> ArrayMesh:
	var h := groesse.abs() * 0.5
	var o := _vorgaben_netz(h)
	o.merge(optionen, true)
	var eckig: float = o["eckig"]
	var breite: float = optionen.get("breite", clampf(minf(h.x, h.z) * 0.6, 0.35, 1.2))
	# Der Stein zieht sich zum Boden hin ein: Der Kranz beginnt unter ihm.
	var innen := float(o["einzug"]) + float(o["unruhe"]) * 1.6 + 0.08
	var n := 40
	var radien := PackedFloat32Array()
	for j in n:
		var w := TAU * float(j) / float(n)
		var p := _superellipse(w, h.x, h.z, eckig)
		radien.append(p.length())
	return kranz(radien, -h.y + 0.025, breite, optionen.get("staerke", 0.6), innen)


## Setzt Stein und Kranz als Knoten unter `eltern`, mit der Verwandlung des
## Körpers (`trafo` = globale Lage des Kastenmittelpunkts). Der Stein wirft
## Schatten, der Kranz nicht. Optionen wie `netz()`, dazu "kranz" (true).
static func bauen(eltern: Node3D, groesse: Vector3, trafo: Transform3D,
		optionen: Dictionary = {}) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = "Findling"
	knoten.transform = trafo
	var stein := MeshInstance3D.new()
	stein.name = "Stein"
	stein.mesh = netz(groesse, optionen)
	stein.material_override = stoff()
	knoten.add_child(stein)
	if optionen.get("kranz", true):
		var ring := MeshInstance3D.new()
		ring.name = "Kranz"
		ring.mesh = kranz_fuer(groesse, optionen)
		ring.material_override = kranzstoff()
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		knoten.add_child(ring)
	eltern.add_child(knoten)
	return knoten


# ================================================================ Körper

## Punkt des Grundrisses (Superellipse) im Winkel w, z = -sin wie beim
## Riesenstamm (so zeigen die Gitter nach außen).
static func _superellipse(w: float, a: float, b: float, n: float) -> Vector2:
	var c := cos(w)
	var s := sin(w)
	var e := 2.0 / n
	return Vector2(a * signf(c) * pow(absf(c), e), -b * signf(s) * pow(absf(s), e))


## Umriss gleichmäßig nach Bogenlänge verteilt: [Punkte, Außennormalen].
static func _umriss(a: float, b: float, n_exp: float, anzahl: int) -> Array[PackedVector2Array]:
	const DICHT := 256
	var dicht := PackedVector2Array()
	var laengen := PackedFloat32Array([0.0])
	for i in DICHT + 1:
		dicht.append(_superellipse(TAU * float(i) / float(DICHT), a, b, n_exp))
		if i > 0:
			laengen.append(laengen[i - 1] + dicht[i].distance_to(dicht[i - 1]))
	var gesamt := laengen[DICHT]
	var punkte := PackedVector2Array()
	var k := 0
	for j in anzahl:
		var ziel := gesamt * float(j) / float(anzahl)
		while k < DICHT - 1 and laengen[k + 1] < ziel:
			k += 1
		var t := (ziel - laengen[k]) / maxf(laengen[k + 1] - laengen[k], 1e-6)
		punkte.append(dicht[k].lerp(dicht[k + 1], t))
	var normalen := PackedVector2Array()
	for j in anzahl:
		var vor := punkte[(j + 1) % anzahl]
		var nach := punkte[(j + anzahl - 1) % anzahl]
		var tangente := (vor - nach).normalized()
		var normale := Vector2(tangente.y, -tangente.x)
		if normale.dot(punkte[j]) < 0.0:
			normale = -normale
		normalen.append(normale)
	return [punkte, normalen]


static func _koerper(h: Vector3, o: Dictionary) -> ArrayMesh:
	var saat: int = o.get("saat", 1)
	var eckig: float = o["eckig"]
	var rr: float = o["rundung"]
	var unruhe: float = o["unruhe"]
	var beulen: float = o.get("beulen", 0.0)
	var kuppe: float = o["kuppe"]
	var delle: float = o["delle"]
	var moos: float = o["moos"]
	var ausgetreten: float = o["ausgetreten"]
	var fuss_weite: float = o["fuss_weite"]
	var nur_innen: bool = o["nur_innen"]
	var einzug: float = o.get("einzug", 0.0)
	var anlauf: float = minf(float(o.get("anlauf", 0.0)) * 2.0 * h.y, ANLAUF_GRENZE)
	var schichten: bool = o.get("schichten", false)
	var umriss_unruhe: float = o.get("umriss", 0.0)
	var umriss_aussen: float = o.get("umriss_aussen", 0.0)
	var moos_oben: float = o.get("moos_oben", 1.0)
	var wasser_y: float = o.get("wasser_y", -INF)
	var fuss_aus: float = o.get("fuss_aus", 0.0)
	var aus_bis: float = -h.y + 0.8 * h.y
	if wasser_y > -INF:
		# Über dem Wasser sichtbar: Die Flanke läuft bis unter die Kante aus.
		aus_bis = maxf(h.y - rr - 0.15, wasser_y + 0.3)
	var rng := PropWerkzeug.zufall(saat + 101)
	var rauschen := FastNoiseLite.new()
	rauschen.seed = saat
	rauschen.frequency = 0.9
	rauschen.fractal_octaves = 2
	var grob := FastNoiseLite.new()
	grob.seed = saat + 17
	grob.frequency = 0.28
	# Zellrauschen: Jede Zelle wölbt sich vor, an den Grenzen knickt die
	# Fläche ein – wie Bruchflächen an einem gerundeten Block.
	var facetten := FastNoiseLite.new()
	facetten.seed = saat + 31
	facetten.noise_type = FastNoiseLite.TYPE_CELLULAR
	facetten.frequency = 0.55 / maxf(sqrt(minf(h.x, h.z)), 0.5)
	facetten.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	# Wo Moos über die Kante läuft (Zungen statt Ring).
	var zungen := FastNoiseLite.new()
	zungen.seed = saat + 53
	zungen.frequency = 0.8

	var umfang := TAU * sqrt((h.x * h.x + h.z * h.z) * 0.5)
	var anzahl := clampi(int(umfang / 0.38), 20, 40)
	anzahl += anzahl % 2
	var um := _umriss(h.x, h.z, eckig, anzahl)
	var punkte2: PackedVector2Array = um[0]
	var normalen2: PackedVector2Array = um[1]
	# Grundriss unregelmäßig: springt nach innen (bei Deko auch nach außen,
	# bei Trittsteinen ein wenig).
	if umriss_unruhe > 0.0 or umriss_aussen > 0.0:
		for j in anzahl:
			var w := TAU * float(j) / float(anzahl)
			var n := 0.7 * grob.get_noise_2d(cos(w) * 2.2, sin(w) * 2.2) \
					+ 0.3 * rauschen.get_noise_2d(cos(w) * 1.6, sin(w) * 1.6)
			var f := lerpf(1.0 - umriss_unruhe, 1.0 + umriss_aussen,
					clampf(0.5 + 0.8 * n, 0.0, 1.0))
			if not nur_innen:
				f = 1.0 + umriss_unruhe * n * 0.8
			punkte2[j] = punkte2[j] * f

	# Eigenschaften je Ecke rundum: Kantenradius, Moos über der Kante, Tiefe
	# der Schichtfugen.
	var kanten_r := PackedFloat32Array()
	var zunge := PackedFloat32Array()
	var zungen_laenge := PackedFloat32Array()
	var fugen_tiefe := PackedFloat32Array()
	for j in anzahl:
		var b := punkte2[j]
		var n_r := grob.get_noise_2d(b.x * 1.9 + 11.0, b.y * 1.9)
		kanten_r.append(lerpf(rr * 0.3, rr, clampf(0.5 + 0.9 * n_r, 0.0, 1.0)))
		zunge.append(smoothstep(0.08, 0.4, zungen.get_noise_2d(b.x, b.y)))
		zungen_laenge.append(lerpf(0.3, 1.3,
				clampf(0.5 + 0.6 * zungen.get_noise_2d(b.x * 2.3 + 40.0, b.y * 2.3), 0.0, 1.0)))
		# Die Fugen reißen ab: Auf gut einem Drittel des Umfangs fehlen sie,
		# sonst liefen sie als Ringe um den Stein.
		fugen_tiefe.append(smoothstep(-0.15, 0.35,
				rauschen.get_noise_2d(b.x * 1.3, b.y * 1.3 + 7.0)))

	# Zeilen von unten nach oben. Art 0 = unter dem Boden (nach außen),
	# 1 = Seite, 2 = Kante (Winkel "w"), 3 = Deckel (Anteil "f" zur Mitte).
	# Seitenzeilen mit "y" = NAN liegen je Ecke dort, wo deren Kante beginnt.
	var kipp := Vector2.from_angle(rng.randf() * TAU) * SCHICHT_NEIGUNG
	var zeilen_def: Array[Dictionary] = []
	zeilen_def.append({"art": 0, "y": -h.y - VERSENKT, "p": 1.0})
	zeilen_def.append({"art": 0, "y": -h.y - 0.35, "p": 0.6})
	var seite_def: Array[Dictionary] = [{"art": 1, "y": -h.y}]
	var oben_frei := h.y - rr - 0.2
	if schichten and oben_frei > -h.y + 0.5:
		# Waagerechte Schichtfugen alle 0,6–1,0 m: Die Fuge liegt tiefer und
		# dunkel, die Schicht darüber setzt vor oder zurück an. So liest sich
		# der Block als geschichteter Fels, nicht als Kissen.
		var y := -h.y + rng.randf_range(0.45, 0.85)
		while y < oben_frei:
			seite_def.append({"art": 1, "y": y, "fuge": 1.0})
			seite_def.append({"art": 1, "y": y + 0.07, "stufe": rng.randf_range(-1.0, 1.0)})
			y += rng.randf_range(0.6, 1.0)
	else:
		var seiten := clampi(int((2.0 * h.y - rr) / 0.6), 1, 3)
		for k in range(1, seiten):
			seite_def.append({"art": 1, "y": lerpf(-h.y, h.y - rr, float(k) / float(seiten))})
	if wasser_y > -h.y + 0.1 and wasser_y < h.y - rr - 0.2:
		# Zeilen an der Wasserlinie, damit das nasse Band scharf sitzt.
		seite_def.append({"art": 1, "y": wasser_y - 0.06})
		seite_def.append({"art": 1, "y": minf(wasser_y + 0.14, h.y - rr - 0.05)})
	seite_def.sort_custom(func(x: Dictionary, y2: Dictionary) -> bool:
		return float(x["y"]) < float(y2["y"]))
	zeilen_def.append_array(seite_def)
	zeilen_def.append({"art": 1, "y": NAN})
	for e: float in [30.0, 60.0, 90.0]:
		zeilen_def.append({"art": 2, "w": deg_to_rad(e)})
	for f: float in [0.8, 0.52, 0.24]:
		zeilen_def.append({"art": 3, "f": f})

	var zeilen: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var farben: Array[PackedColorArray] = []
	var arten: Array[PackedVector2Array] = []
	var kante_oben := PackedVector3Array()
	for z in zeilen_def:
		var art: int = z["art"]
		var zeile := PackedVector3Array()
		var uv := PackedVector2Array()
		var fa := PackedColorArray()
		var ar := PackedVector2Array()
		for j in anzahl + 1:
			var jj := j % anzahl
			var basis := punkte2[jj]
			var nrm := normalen2[jj]
			var r_k := kanten_r[jj]
			# Deko-Brocken runden gleichmäßig, Begehbares je Ecke anders.
			var r_rand := r_k if nur_innen else rr
			var y_kante := h.y - r_rand
			var p: Vector3
			var tief := 0.0
			var ao := 1.0
			var m := 0.0
			var abgetreten := 0.0
			match art:
				0:
					var y: float = z["y"]
					var weite := basis + nrm * (basis.length() * fuss_weite * float(z["p"]) + fuss_aus)
					p = Vector3(weite.x, y, weite.y)
					ao = 0.32
					m = 0.6
				1:
					var y: float = z["y"]
					if is_nan(y):
						y = y_kante
					elif z.has("fuge") or z.has("stufe"):
						# Schichtfugen liegen schräg, bleiben aber unter der Kante.
						y = clampf(y + kipp.dot(basis), -h.y + 0.05, y_kante - 0.08)
					var u := clampf((y + h.y) / maxf(2.0 * h.y, 0.01), 0.0, 1.0)
					# Bauch (nur Deko): zum Boden hin eingezogen.
					var bauch := einzug * pow(1.0 - smoothstep(0.0, 0.62, u), 1.5)
					var oben_anteil := smoothstep(-h.y + 0.3, y_kante, y)
					var n1 := rauschen.get_noise_3d(basis.x, y, basis.y)
					var zelle := facetten.get_noise_3d(basis.x, y * 0.8, basis.y)
					var beule := beulen * (0.5 + 0.5 * grob.get_noise_3d(basis.x * 1.4, y * 0.9,
							basis.y * 1.4)) * lerpf(1.0, 0.3, oben_anteil)
					tief = bauch + anlauf * u + beule \
							+ unruhe * (0.3 + 0.25 * n1) * lerpf(1.0, 0.4, oben_anteil) \
							+ unruhe * 1.1 * (0.5 + 0.5 * zelle) * lerpf(1.0, 0.25, oben_anteil)
					var fuge: float = z.get("fuge", 0.0)
					tief += fuge * fugen_tiefe[jj] * FUGE_TIEFE
					tief += float(z.get("stufe", 0.0)) * 0.03 * fugen_tiefe[jj]
					if not nur_innen:
						var n2 := grob.get_noise_3d(basis.x, y * 0.7, basis.y)
						tief -= unruhe * 0.9 * maxf(-n2, 0.0)
					else:
						tief = maxf(tief, 0.0)
					var q := basis - nrm * tief
					if fuss_aus > 0.0:
						q += nrm * fuss_aus * (1.0 - smoothstep(-h.y, aus_bis, y))
					p = Vector3(q.x, y, q.y)
					var ueber_boden := y + h.y
					ao = lerpf(0.6, 1.0, smoothstep(0.0, 0.9, ueber_boden))
					ao *= 1.0 - 0.3 * clampf((tief - anlauf * u) / maxf(unruhe * 1.8 + beulen, 0.001),
							0.0, 1.0)
					ao *= 1.0 - 0.45 * fuge * fugen_tiefe[jj]
					# Moos: unten am Fuß, in den Fugen, und in Zungen, die von der
					# Kante die Seite hinablaufen.
					m = lerpf(0.55, 0.08, smoothstep(0.0, 0.8, ueber_boden)) + 0.25 * fuge
					var laenge := zungen_laenge[jj]
					m += 0.95 * moos_oben * zunge[jj] \
							* smoothstep(y_kante - laenge, y_kante - laenge * 0.3, y)
				2:
					var winkel: float = z["w"]
					var n1 := rauschen.get_noise_3d(basis.x, h.y, basis.y)
					tief = anlauf + unruhe * 0.3 * (0.5 + 0.5 * n1) + r_rand * (1.0 - cos(winkel))
					var q := basis - nrm * tief
					var kuppen_anteil := kuppe * 0.15 if kuppe > 0.0 else 0.0
					var y := h.y - r_rand + r_rand * sin(winkel) + kuppen_anteil * sin(winkel)
					y = minf(y, h.y + kuppen_anteil)
					p = Vector3(q.x, y, q.y)
					# Moos nur, wo eine Zunge über die Kante läuft – nie als
					# durchgehender grüner Saum (der läse sich als Bordstein).
					m = moos_oben * (0.1 + 0.9 * zunge[jj]) * lerpf(0.75, 1.1, sin(winkel))
				3:
					var f: float = z["f"]
					# Deckel: vom oberen Kantenring zur Mitte.
					var rand_p := kante_oben[jj]
					var q2 := Vector2(rand_p.x, rand_p.z) * f
					var wolbung := kuppe * (1.0 - f * f)
					var mulde := delle * (1.0 - f * f)
					var feine := 0.0
					if not nur_innen:
						feine = 0.06 * kuppe * rauschen.get_noise_2d(q2.x * 2.0, q2.y * 2.0)
					var y := h.y + (kante_oben[jj].y - h.y) * f + wolbung - mulde + feine
					if nur_innen:
						y = minf(y, h.y)
					p = Vector3(q2.x, y, q2.y)
					abgetreten = ausgetreten * smoothstep(0.85, 0.25, f)
					var polster := 0.5 + 0.5 * grob.get_noise_2d(q2.x * 1.7, q2.y * 1.7)
					m = moos_oben * (zunge[jj] * lerpf(0.1, 0.85, f)
							+ 0.4 * smoothstep(0.62, 0.85, polster) * f) * (1.0 - abgetreten)
			if wasser_y > -INF:
				var nass := 1.0 - smoothstep(wasser_y - 0.05, wasser_y + 0.2, p.y)
				ao *= lerpf(1.0, 0.45, nass)
				var linie := 1.0 - smoothstep(0.0, 0.16, absf(p.y - wasser_y - 0.04))
				ao *= 1.0 - 0.25 * linie
				m = maxf(m, 0.7 * linie)
			m = clampf((m + 0.3 * rauschen.get_noise_3d(p.x * 1.7, p.y * 1.7, p.z * 1.7)) * moos,
					0.0, 1.0)
			ao *= 0.92 + 0.08 * grob.get_noise_3d(p.x * 3.0, p.y * 3.0, p.z * 3.0)
			zeile.append(p)
			uv.append(Vector2.ZERO)
			fa.append(Color(ao, ao, ao, m))
			ar.append(Vector2(abgetreten, moos_oben))
		if art == 2 and is_equal_approx(float(z["w"]), deg_to_rad(90.0)):
			kante_oben = zeile
		zeilen.append(zeile)
		uvs.append(uv)
		farben.append(fa)
		arten.append(ar)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Riesenstamm.gitter(st, zeilen, uvs, farben, arten, true)

	# Mitte des Deckels als Fächer.
	var letzte := zeilen[zeilen.size() - 1]
	var mitte := Vector3(0.0, h.y + kuppe - delle, 0.0)
	if not nur_innen:
		mitte.y = h.y + kuppe
	mitte.y = minf(mitte.y, h.y + kuppe)
	var mitte_farbe := Color(1.0, 1.0, 1.0, 0.0)
	var mitte_art := Vector2(ausgetreten, moos_oben)
	var letzte_farben := farben[farben.size() - 1]
	var letzte_arten := arten[arten.size() - 1]
	for j in anzahl:
		var a := letzte[j]
		var b := letzte[j + 1]
		# Vorderseite nach oben: cross(b-a, c-a) muss nach unten zeigen.
		var reihenfolge := [mitte, a, b]
		var fr := [mitte_farbe, letzte_farben[j], letzte_farben[j + 1]]
		var ar := [mitte_art, letzte_arten[j], letzte_arten[j + 1]]
		if (a - mitte).cross(b - mitte).y > 0.0:
			reihenfolge = [mitte, b, a]
			fr = [mitte_farbe, letzte_farben[j + 1], letzte_farben[j]]
			ar = [mitte_art, letzte_arten[j + 1], letzte_arten[j]]
		for e in 3:
			var ecke: Vector3 = reihenfolge[e]
			st.set_color(fr[e])
			st.set_uv(Vector2.ZERO)
			st.set_uv2(ar[e])
			st.set_normal(Vector3.UP)
			st.add_vertex(ecke)
	st.index()
	var ergebnis: ArrayMesh = st.commit()
	return ergebnis


static func _flach(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		fa: Color, fb: Color, fc: Color) -> void:
	# Vorderseite nach oben
	var pb := b
	var pc := c
	var fbb := fb
	var fcc := fc
	if (b - a).cross(c - a).y > 0.0:
		pb = c
		pc = b
		fbb = fc
		fcc = fb
	st.set_normal(Vector3.UP)
	st.set_color(fa)
	st.add_vertex(a)
	st.set_color(fbb)
	st.add_vertex(pb)
	st.set_color(fcc)
	st.add_vertex(pc)


# ================================================================ Stoff

static var _stoff: ShaderMaterial = null
static var _kranzstoff: ShaderMaterial = null

## Fels der Bibliothek in Dreifachprojektion (Welt), Moos nach Maske und
## nach oben, ausgetretene Mitte hell und glatt. Geteilt – nie verändern.
static func stoff() -> ShaderMaterial:
	if _stoff != null:
		return _stoff
	var shader := Shader.new()
	shader.code = STEIN_SHADER
	_stoff = ShaderMaterial.new()
	_stoff.shader = shader
	var fels := Materialbibliothek.fels()
	_stoff.set_shader_parameter("fels", fels.albedo_texture)
	_stoff.set_shader_parameter("fels_normal", fels.normal_texture)
	_stoff.set_shader_parameter("moos", Riesenstamm.moostextur())
	return _stoff


## Stoff des Verdeckungskranzes: unbeleuchtet, halbdurchsichtig, schreibt
## keine Tiefe. Geteilt – nie verändern.
static func kranzstoff() -> ShaderMaterial:
	if _kranzstoff != null:
		return _kranzstoff
	var shader := Shader.new()
	shader.code = KRANZ_SHADER
	_kranzstoff = ShaderMaterial.new()
	_kranzstoff.shader = shader
	return _kranzstoff


const STEIN_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D fels : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D fels_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moos : source_color, filter_linear_mipmap, repeat_enable;
uniform float kachel = 0.45;
// Heller, warmer Kalk statt dunklem Grau (Luma um 0,55 in der Sonne).
uniform vec4 stein_farbe : source_color = vec4(1.16, 1.08, 0.92, 1.0);
uniform vec4 moos_farbe : source_color = vec4(1.0);
uniform float moos_oben = 0.22;
uniform float entsaettigen = 0.3;

varying vec3 v_welt;
varying vec3 v_wn;

vec3 auspacken(vec4 t) {
	vec2 xy = t.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

void vertex() {
	v_welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_wn);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 p = v_welt * kachel;
	vec2 ux = p.zy;
	vec2 uy = p.xz;
	vec2 uz = p.xy;
	vec3 farbe = texture(fels, ux).rgb * w.x + texture(fels, uy).rgb * w.y + texture(fels, uz).rgb * w.z;
	// Findlinge sind grauer als der Schichtfels der Wände.
	farbe = mix(farbe, vec3(dot(farbe, vec3(0.3, 0.55, 0.15))), entsaettigen);
	vec3 tx = auspacken(texture(fels_normal, ux));
	vec3 ty = auspacken(texture(fels_normal, uy));
	vec3 tz = auspacken(texture(fels_normal, uz));
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	vec3 nw = normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);

	float abgetreten = UV2.x;
	vec2 moos_uv = (w.y > 0.5 ? uy : (w.x > w.z ? ux : uz)) * 2.4;
	vec4 mt = texture(moos, moos_uv);
	float m = COLOR.a + moos_oben * UV2.y * smoothstep(0.55, 0.92, n.y) * (1.0 - abgetreten);
	float anteil = smoothstep(0.42, 0.6, m * 0.85 + (mt.a - 0.5) * 0.8);
	nw = normalize(mix(nw, n, clamp(anteil * 0.7 + abgetreten * 0.45, 0.0, 1.0)));

	// Ausgetreten und trocken: heller und glatter.
	vec3 stein = farbe * stein_farbe.rgb * mix(1.0, 1.14, abgetreten);
	ALBEDO = mix(stein, mt.rgb * moos_farbe.rgb, anteil) * COLOR.rgb;
	ROUGHNESS = mix(0.9, 0.6, abgetreten);
	SPECULAR = 0.35;
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
"""

const KRANZ_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
"""
