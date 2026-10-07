extends RefCounted
class_name Baumfabrik
## Bäume für den Wald neben einem Weg: Netze in den Fassungen von Level 01
## und das Pflanzen nach den Regeln eines `Waldrahmen` (Baukasten Raum 1,
## Paket G4; Herkunft scenes/levels/level01/wald.gd: `_baum` :776,
## `_modellbaum` :1017, `_fernbaum` :1060, `_tannenkrone` :1121,
## `_pflanze` :1263, `_hain` :2229, `_bodenstueck` :2311, `_randbusch`
## :2391, `_totholz` :2410).
##
## WARUM EINE KOPIE. In wald.gd hängt alles an statischen Merkern
## (`_netze`, `_staemme`, `_kronen`, `_kegel` …) und an `Level01`
## (Gelände, Kanten, Lichtung). Hier ist jede Funktion statisch und ohne
## Zustand; was ein Bau sich merkt – Netze, Stämme, Kronen, Zähler –,
## liegt im `Waldrahmen` des Levels (`rahmen.netze`, `rahmen.staemme` …).
## Die Netze entstehen mit demselben Rechenweg wie in wald.gd:
## `fernbaum(k)` und `tannenkrone(…)` sind mit den Werten von Level 01
## bitgleich mit `L01Wald._fernbaum`/`_tannenkrone` (Baukastenprobe, G4).
##
## FASSUNGEN EINES BAUMS (`baum()`, wie wald.gd:763-775): voll
## (`Riesenstamm.baum`), voll mit freier Krone ("krone_frei"), mittel
## ("mittel": schlichter Stamm, freie Krone; mit "tanne" eine
## `tannenkrone`) – und `modellbaum()` aus einer Rolle der Fremdmodelle
## (M1, M3, M17, für Raum 1 M19 Weiden, M20 Birken, M22 Totholz). Alle
## liefern dasselbe Wörterbuch: stamm, krone, huelle (Krone), hoehe,
## radius, fuss_radien, kranz, schatten, variante, neigung, krone_unten,
## krone_oben; Modellbäume dazu "fern_netz" (eigene Fernfassung) und
## "modell". Ein Hain (`hain()`) wählt je Baum eine Art aus einer Liste
## und fällt auf den prozeduralen Baum zurück, wenn die Rolle kein Modell
## hat (Schalter `Einstellungen.fremde_modelle` aus, Datei fehlt).
##
## ABWEICHUNGEN VOM PLAN (Baukasten §1.4), weil der Code sie verlangt:
##   - `tannenkrone` hat zusätzlich `saat` (wald.gd braucht sie, ohne sie
##     wäre jede Krone gleich); `fernbaum(k, farbe)`: `farbe` ist die
##     Stammfarbe der Fernfassung, Vorgabe die von Level 01.
##   - `hain` nimmt freiwillig `optionen` (Höhe des Geländes als Callable,
##     Anzahl, Weite, Tönung, Unterholz …) und gibt die Füße der gesetzten
##     Bäume zurück (Plan: void) – wald.gd hielt beides in Konstanten und
##     statischen Merkern.
##   - Dazu, ohne die ein Hain nicht wächst: `baum` (prozeduraler Rückfall
##     ohne Modelle), `pflanze` (die Regeln des Rahmens anwenden und
##     setzen), `randbusch`, `totholz`, `bodenstueck`, `vorrat`.
##
## ARTEN IM SETZER. Der Aufrufer meldet sie an (`Waldsetzer.art`), die
## Vorgaben heißen wie in wald.gd: "stamm" (Borke, verschmolzen), "krone"
## (Kronenstoff, verschmolzen, "karten"), "fern" (Kronenstoff ohne Karten,
## ab der Sichtweite der Krone). Für Modellstämme die Borke in Welt-
## projektion (`borke_welt()`): Die Modelle tragen kein UV für die Rinde.

## Ferne Kronen (`_fernform`): so viel breiter am Fuß, dort beginnt ihr
## Farbverlauf (wald.gd:184-185).
const FERN_FUSS := 0.12
const FERN_UNTEN := 0.4
## Lagen der Ballen einer fernen Krone, je Form (0 rund, 1 breit): Höhe
## über dem Fuß, Abstand von der Achse, Anzahl (wald.gd:189-192).
const FERN_LAGEN := [
	[Vector3(3.4, 1.7, 3), Vector3(6.6, 1.4, 1)],
	[Vector3(3.3, 2.3, 3), Vector3(6.3, 1.5, 1)],
]
## Dort (Anteil der Höhe) beginnt die Krone eines fernen Baums.
const FERN_BODEN := 0.1
## Die Fernfassung eines Modellbaums: so viele Dreiecke (wald.gd:235).
const FERN_MODELL_DREIECKE := 360
## Stammfarbe der Fernfassung im Kronenstoff (wald.gd:1093).
const FERN_STAMM := Color(0.3, 0.26, 0.21, 0.0)
## Tönung der Nadelbäume: dunkler und kühler (wald.gd:249).
const NADEL_TON := Color(0.6, 0.72, 0.76)
## Tönung des Totholzes: grau, ausgeblichen (wald.gd:251).
const TOT_TON := Color(0.82, 0.8, 0.78, 0.25)
## Mindestabstand der Stämme im Hain (wald.gd:219, im Hain 60 %).
const HAIN_ABSTAND := 2.3

## Modellnamen je Rolle (siehe `modellbaum`).
static var _rollen := {}


# =========================================================== Netze

## Ein Baum in einer der drei prozeduralen Fassungen (wald.gd:776, ohne
## Zwischenspeicher – den hält `rahmen.netze`, siehe `vorrat()`).
## Optionen wie dort: hoehe, radius, saat, "mittel" (variante, krone_radius,
## krone_hoehe, tanne, unten, ballen, karten, neigung), "krone_frei",
## sonst `Riesenstamm.baum`. `mit_kranz`: Verdeckungsring am Fuß.
static func baum(o: Dictionary, mit_kranz: bool = false) -> Dictionary:
	var b: Dictionary
	var hoehe: float = o.get("hoehe", 14.0)
	var radius: float = o.get("radius", 0.5)
	var saat: int = o.get("saat", 1)
	if bool(o.get("mittel", false)):
		var variante: int = o.get("variante", 0)
		var kr: float = o.get("krone_radius", hoehe * 0.3)
		var kh: float = o.get("krone_hoehe",
				kr * (1.3 if variante == 0 else (0.85 if variante == 1 else 2.2)))
		# Die Ballen füllen die verlangte Höhe nur zu gut 70 %: Die Krone
		# wird größer bestellt und dann so gesetzt, dass ihr Scheitel auf
		# `hoehe` liegt – der Stamm endet in ihrer Mitte.
		var roh: ArrayMesh
		if bool(o.get("tanne", false)):
			roh = tannenkrone(kr, hoehe * (1.0 - float(o.get("unten", 0.2))),
					int(o.get("ballen", 6)), 11, int(o.get("karten", 22)), saat + 101)
		else:
			roh = Kronenwolke.netz({"radius": kr, "hoehe": kh * 1.35, "variante": variante,
					"ballen": int(o.get("ballen", 3)), "karten": int(o.get("karten", 22)),
					"saat": saat + 101})
		var rbox := roh.get_aabb()
		# "unten": Dort (Anteil der Höhe) soll die Krone beginnen – reicht sie
		# nicht so weit hinab, wird sie gestreckt (höchstens um 60 %).
		var streck := 1.0
		if o.has("unten"):
			streck = clampf(hoehe * (1.0 - float(o["unten"])) / rbox.size.y, 1.0, 1.6)
		var mitte_y := hoehe - rbox.end.y * streck
		var krone := verschoben(roh, Vector3(0.0, mitte_y, 0.0)
				+ neigung_bei(o, (mitte_y + rbox.get_center().y * streck) / hoehe), streck)
		var stamm := Riesenstamm.schlicht({"hoehe": mitte_y
				+ (rbox.get_center().y + rbox.size.y * 0.1) * streck,
				"radius": radius, "radius_oben": radius * 0.5, "aeste": 3, "ast_start": 0.62,
				"ast_laenge": kr * 0.55, "neigung": o.get("neigung", Vector2.ZERO), "saat": saat})
		var box := krone.get_aabb()
		b = {"stamm": stamm, "krone": krone, "krone_unten": box.position.y,
				"krone_oben": box.end.y, "krone_radius": kr, "schatten": stamm}
	elif bool(o.get("krone_frei", false)):
		# Voller Stamm, freie Krone aus Ballen an seiner Spitze.
		var variante: int = o.get("variante", 0)
		var kr: float = o.get("krone_radius", hoehe * 0.26)
		var kh: float = o.get("krone_hoehe",
				kr * (1.3 if variante == 0 else (0.85 if variante == 1 else 2.2)))
		var so := o.duplicate()
		so["aeste"] = 2
		so["ast_start"] = 0.7
		so["ast_laenge"] = kr * 0.5
		var stamm := Riesenstamm.netz(so)
		var roh := Kronenwolke.netz({"radius": kr, "hoehe": kh * 1.35, "variante": variante,
				"ballen": int(o.get("ballen", 4)), "karten": int(o.get("karten", 28)),
				"saat": saat + 101})
		var rbox := roh.get_aabb()
		var mitte_y := hoehe + kh * 0.25 - rbox.end.y
		var krone := verschoben(roh, Vector3(0.0, mitte_y, 0.0)
				+ neigung_bei(o, (mitte_y + rbox.get_center().y) / hoehe))
		var box := krone.get_aabb()
		b = {"stamm": stamm, "krone": krone, "krone_unten": box.position.y,
				"krone_oben": box.end.y, "krone_radius": kr}
		b["schatten"] = Riesenstamm.schlicht({"hoehe": hoehe, "radius": radius,
				"radius_oben": float(o.get("radius_oben", radius * 0.55)),
				"neigung": o.get("neigung", Vector2.ZERO), "krumm": 0.0, "saat": saat})
	else:
		b = Riesenstamm.baum(o)
		b["schatten"] = Riesenstamm.schlicht({"hoehe": hoehe, "radius": radius,
				"radius_oben": float(o.get("radius_oben", radius * 0.55)),
				"neigung": o.get("neigung", Vector2.ZERO), "krumm": 0.0, "saat": saat})
	b["hoehe"] = hoehe
	b["neigung"] = o.get("neigung", Vector2.ZERO)
	b["variante"] = int(o.get("variante", 0))
	var krone_roh: ArrayMesh = b["krone"]
	var krone_netz := indiziert(krone_roh)
	b["krone"] = krone_netz
	b["huelle"] = krone_netz.get_aabb()
	b["radius"] = radius
	var stamm_netz: ArrayMesh = b["stamm"]
	var fuss: PackedFloat32Array = stamm_netz.get_meta("fuss_radien", PackedFloat32Array())
	b["fuss_radien"] = fuss
	b["kranz"] = null
	if mit_kranz and fuss.size() >= 3:
		var r0 := fuss[0]
		for f in fuss:
			r0 = minf(r0, f)
		b["kranz"] = Findling.kranz(fuss, 0.02, clampf(r0 * 1.6, 0.6, 2.5), 0.62,
				clampf(r0 * 0.15, 0.08, 0.4))
	return b


## Ein Modellbaum der Rolle `rolle` (`Fremdmodelle.baum`) im Format von
## `baum()` – leer, wenn die Rolle kein Modell hat (wald.gd:1017). `nadel`
## wählt unter den Nadelbäumen (Name mit „Pine"), sonst unter den übrigen;
## `wahl` (0..1) das Modell. `ton` tönt den Stamm beim Setzen (zusätzlich
## zur Tönung des Pflanzers; Birkenrinde, Silber, Sandstein …).
##
## Die Modelle einer Rolle merkt sich `_rollen` (je Rolle, Nadel/Laub und
## Schalter der Fremdmodelle): `Fremdmodelle.rolle` fragt für jedes Modell
## der Rolle den Ressourcenlader, ob die Datei liegt – je Baum aufs Neue.
## In Level 05 waren das kalt rund 500 Aufrufe mit 7 850 Dateiabfragen,
## gemessen 0,32–0,45 s der Ladezeit. Die Antwort ist dieselbe (die Dateien
## ändern sich nicht, solange das Spiel läuft); ein Zwischenspeicher der
## Dateilage, kein Zustand eines Levels (wie `Nebelstoff._shader`).
static func modellbaum(rolle: String, nadel: bool, wahl: float, hoehe: float, unten: float,
		ton: Color = Color.WHITE) -> Dictionary:
	var schluessel := "%s|%s|%s" % [rolle, nadel, Fremdmodelle.aktiv()]
	var namen: PackedStringArray = _rollen.get(schluessel, PackedStringArray())
	if not _rollen.has(schluessel):
		for n in Fremdmodelle.rolle(rolle):
			if n.contains("Pine") == nadel:
				namen.append(n)
		_rollen[schluessel] = namen
	if namen.is_empty():
		return {}
	var name := namen[clampi(int(wahl * float(namen.size())), 0, namen.size() - 1)]
	var m := Fremdmodelle.baum(name, {"hoehe": hoehe, "unten": unten,
			"fern_dreiecke": FERN_MODELL_DREIECKE})
	if m.is_empty():
		return {}
	return {"stamm": m["stamm"], "krone": m["krone"], "huelle": m["huelle"],
			"hoehe": float(m["hoehe"]), "radius": float(m["radius"]),
			"fuss_radien": PackedFloat32Array(), "kranz": null, "schatten": m["stamm"],
			"variante": 2 if nadel else 0, "neigung": Vector2.ZERO, "fern_netz": m["fern"],
			"krone_unten": float(m["krone_unten"]), "krone_oben": float(m["krone_oben"]),
			"modell": name, "ton": ton}


## Borke in Weltprojektion für Zellen mit Modellstämmen (wald.gd:1045).
static func borke_welt() -> Material:
	return Riesenstamm.borkenstoff({"welt": true, "radius": 0.4})


## Ferner Baum (wald.gd:1060): grobe Krone ohne Karten, unten breiter und
## heller, ein angedeuteter Stamm im selben Stoff in der Farbe `farbe`
## (Vorgabe wie Level 01). k: 0 rund, 1 breit, 2 Nadelbaum. Fuß im Ursprung.
static func fernbaum(k: int, farbe: Color = FERN_STAMM) -> ArrayMesh:
	var hoehe := 12.0 if k != 1 else 11.0
	var roh: ArrayMesh
	if k == 2:
		hoehe = 14.0
		roh = _fernform(tannenkrone(2.9, hoehe * (1.0 - FERN_BODEN), 5, 7, 0, 3101 + k))
	else:
		var zentren := PackedVector3Array()
		var dreh := 0.7 * float(k)
		for lage_: Vector3 in FERN_LAGEN[k]:
			var n := int(lage_.z)
			for i in n:
				var w := dreh + TAU * float(i) / float(n)
				zentren.append(Vector3(cos(w) * lage_.y, lage_.x, -sin(w) * lage_.y))
			dreh += PI / float(maxi(n, 1))
		roh = _fernform(Kronenwolke.fern({"radius": 5.0 if k == 0 else 5.2, "saat": 3101 + k,
				"zentren": zentren}))
	var rbox := roh.get_aabb()
	var streck := clampf(hoehe * (1.0 - FERN_BODEN) / rbox.size.y, 1.0, 2.2)
	var dy := hoehe - rbox.end.y * streck
	var krone := verschoben(roh, Vector3(0.0, dy, 0.0), streck)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(krone, 0, Transform3D.IDENTITY)
	var r := 0.3 if k != 1 else 0.36
	var oben := dy + rbox.get_center().y * streck
	for j in 4:
		var w0 := TAU * float(j) / 4.0 + 0.4
		var w1 := TAU * float(j + 1) / 4.0 + 0.4
		var a := Vector3(cos(w0) * r, -1.0, -sin(w0) * r)
		var b := Vector3(cos(w1) * r, -1.0, -sin(w1) * r)
		var c := Vector3(cos(w1) * r * 0.6, oben, -sin(w1) * r * 0.6)
		var d := Vector3(cos(w0) * r * 0.6, oben, -sin(w0) * r * 0.6)
		var n := Vector3(cos((w0 + w1) * 0.5), 0.0, -sin((w0 + w1) * 0.5))
		for p: Vector3 in [a, c, b, a, d, c]:
			st.set_color(farbe)
			st.set_uv(Vector2.ZERO)
			st.set_uv2(Vector2(0.0, 0.0))
			st.set_normal(n)
			st.add_vertex(p)
	st.index()
	return st.commit()


## Krone eines Nadelbaums (wald.gd:1121): `stufen` gezackte Kegel
## übereinander im Format der `Kronenwolke`, `seiten` Zacken je Kegel,
## `karten` Blattkarten an den Rändern. Fuß im Ursprung, Spitze auf `hoehe`.
## `saat`: der Zufall der Form (in wald.gd ein Pflichtwert).
static func tannenkrone(radius: float, hoehe: float, stufen: int, seiten: int, karten: int,
		saat: int = 1) -> ArrayMesh:
	var rng := PropWerkzeug.zufall(saat)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var raender: Array[Dictionary] = []
	for i in stufen:
		var u := float(i) / float(stufen)
		var r := radius * lerpf(1.0, 0.26, u) * rng.randf_range(0.92, 1.08)
		var y_rand := hoehe * 0.8 * u + rng.randf_range(-0.04, 0.04) * hoehe / float(stufen)
		var y_spitze := hoehe if i == stufen - 1 else minf(y_rand + hoehe * 0.34, hoehe * 0.97)
		var spitze := Vector3(rng.randf_range(-0.05, 0.05) * r, y_spitze,
				rng.randf_range(-0.05, 0.05) * r)
		var unter := Vector3(0.0, y_rand + (y_spitze - y_rand) * 0.3, 0.0)
		var ao := lerpf(0.72, 1.0, u)
		var dreh := rng.randf() * TAU
		var rand := PackedVector3Array()
		for k in seiten:
			var w := dreh + TAU * (float(k) + rng.randf_range(-0.18, 0.18)) / float(seiten)
			var zacke := (1.0 if k % 2 == 0 else 0.78) * rng.randf_range(0.9, 1.1)
			var y := y_rand - r * (0.16 if k % 2 == 0 else 0.06) * rng.randf_range(0.7, 1.3)
			rand.append(Vector3(cos(w) * r * zacke, y, -sin(w) * r * zacke))
		for k in seiten:
			var a := rand[k]
			var b := rand[(k + 1) % seiten]
			var na := _tannen_normale(a, spitze)
			var nb := _tannen_normale(b, spitze)
			var aussen := Vector3(a.x + b.x, 0.0, a.z + b.z).normalized()
			_tannen_dreieck(st, [spitze, a, b], [Vector3.UP, na, nb], aussen + Vector3.UP * 0.3,
					[ao * 0.9, ao, ao], hoehe)
			var nu := (aussen * 0.4 + Vector3.DOWN).normalized()
			_tannen_dreieck(st, [unter, b, a], [nu, nu, nu], nu, [ao * 0.6, ao * 0.7, ao * 0.7],
					hoehe)
			raender.append({"ort": a, "normale": na, "ao": ao})
	var max_karte := 0.0
	for n in karten:
		if raender.is_empty():
			break
		var e: Dictionary = raender[rng.randi_range(0, raender.size() - 1)]
		var ort: Vector3 = e["ort"]
		var groesse := clampf(radius * 0.3, 0.45, 1.1) * rng.randf_range(0.8, 1.2)
		max_karte = maxf(max_karte, groesse)
		var ao: float = e["ao"]
		var f := Color(ao * 1.05, ao * 1.05, ao * 1.03, clampf(0.45 + 0.55 * ort.y / hoehe, 0.0, 1.0))
		var nrm: Vector3 = e["normale"]
		var art := 1.0 + clampf(ort.y / hoehe, 0.0, 0.99)
		ort += nrm * groesse * 0.15
		for c: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0),
				Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
			st.set_color(f)
			st.set_uv(c)
			st.set_uv2(Vector2(art, groesse))
			st.set_normal((nrm + Vector3.UP * 0.6).normalized())
			st.add_vertex(ort)
	var netz := st.commit()
	netz.custom_aabb = netz.get_aabb().grow(max_karte * 0.75 + 0.1)
	return netz


static func _tannen_normale(rand: Vector3, spitze: Vector3) -> Vector3:
	var aussen := Vector3(rand.x, 0.0, rand.z).normalized()
	var steil := (spitze - rand).normalized()
	var n := (aussen - steil * aussen.dot(steil)).normalized()
	return (n + Vector3.UP * 0.35).normalized()


static func _tannen_dreieck(st: SurfaceTool, p: Array, n: Array, aussen: Vector3, ao: Array,
		hoehe: float) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	var reihe: Array[int] = [0, 1, 2]
	if (b - a).cross(c - a).dot(aussen) > 0.0:
		reihe = [0, 2, 1]
	for j in reihe:
		var q: Vector3 = p[j]
		var t := clampf(q.y / hoehe, 0.0, 1.0)
		var v: float = ao[j]
		st.set_color(Color(v, v, v, 0.25 + 0.75 * t))
		st.set_uv(Vector2.ZERO)
		st.set_uv2(Vector2(0.0, t))
		st.set_normal(n[j] as Vector3)
		st.add_vertex(q)


## Form einer fernen Krone: unten breiter und heller (wald.gd:1219).
static func _fernform(netz: ArrayMesh) -> ArrayMesh:
	var arrays := netz.surface_get_arrays(0)
	var ecken: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var box := netz.get_aabb()
	var mitte := box.get_center()
	for i in ecken.size():
		var t := uv2[i].y
		var p := ecken[i]
		var weit := 1.0 + FERN_FUSS * (1.0 - smoothstep(0.0, 0.6, t))
		ecken[i] = Vector3(mitte.x + (p.x - mitte.x) * weit, p.y, mitte.z + (p.z - mitte.z) * weit)
		uv2[i] = Vector2(uv2[i].x, lerpf(FERN_UNTEN, 1.0, t))
	arrays[Mesh.ARRAY_VERTEX] = ecken
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	var neu := ArrayMesh.new()
	neu.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return neu


## Versatz der Stammachse durch "neigung" in der relativen Höhe t
## (wald.gd:874).
static func neigung_bei(o: Dictionary, t: float) -> Vector3:
	var n: Vector2 = o.get("neigung", Vector2.ZERO)
	var v := n * pow(clampf(t, 0.0, 1.3), 1.5)
	return Vector3(v.x, 0.0, v.y)


## Eine Krone, um `versatz` verschoben und um `streck` in der Höhe gestreckt
## (wald.gd:882).
static func verschoben(netz: ArrayMesh, versatz: Vector3, streck: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var skala := Vector3(1.0, streck, 1.0)
	st.append_from(netz, 0, Transform3D(Basis.from_scale(skala), versatz))
	st.index()
	var neu := st.commit()
	var box := netz.custom_aabb if netz.custom_aabb.size != Vector3.ZERO else netz.get_aabb()
	neu.custom_aabb = AABB(box.position * skala + versatz, box.size * skala)
	return neu


## Dasselbe Netz mit geteilten Scheiteln (wald.gd:897).
static func indiziert(netz: ArrayMesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(netz, 0)
	st.index()
	var neu := st.commit()
	neu.custom_aabb = netz.custom_aabb
	for m in netz.get_meta_list():
		neu.set_meta(m, netz.get_meta(m))
	return neu


## Ein Netz aus dem Vorrat des Rahmens, beim ersten Mal mit `bauen`
## gebaut (Callable() -> Variant). Der Vorrat lebt so lange wie der Rahmen.
static func vorrat(rahmen: Waldrahmen, schluessel: String, bauen: Callable) -> Variant:
	if not rahmen.netze.has(schluessel):
		rahmen.netze[schluessel] = bauen.call()
	return rahmen.netze[schluessel]


# =========================================================== Helfer

## Farbe eines Tons mit ±`waerme` Farbwärme (wald.gd:1239).
static func ton(rng: RandomNumberGenerator, hell: Vector2, waerme: float = 0.06) -> Color:
	var v := rng.randf_range(hell.x, hell.y)
	var w := rng.randf_range(-waerme, waerme)
	return Color(clampf(v * (1.0 + w), 0.0, 1.0), clampf(v, 0.0, 1.0),
			clampf(v * (1.0 - w), 0.0, 1.0), 1.0)


## Lage eines Baums: Fuß, Drehung um Y, Maßstab (quer, hoch), Schiefe um
## `kipp_achse` (wald.gd:1253).
static func lage(fuss: Vector3, drehung: float, quer: float, hoch: float,
		schief: float = 0.0, kipp_achse: Vector3 = Vector3.RIGHT) -> Transform3D:
	var basis := Basis(Vector3.UP, drehung).scaled_local(Vector3(quer, hoch, quer))
	if absf(schief) > 0.0001:
		basis = Basis(kipp_achse.normalized(), schief) * basis
	return Transform3D(basis, fuss)


## Feste Streuung 0..1 nach dem Ort, ohne Würfel (wald.gd:2221).
static func streu(p: Vector2, saat: int) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233 + float(saat) * 1.618) * 43758.5453, 1.0)


# =========================================================== Pflanzen

## Setzt einen Baum `b` in `lage`, wenn er alle Regeln des Rahmens hält
## (wald.gd:1263). `stamm_art`/`krone_art`: Arten im Setzer, "" lässt den
## Teil weg. Optionen: "kante" (Kantenregel prüfen), "fussweite",
## "zugabe", "ohne_stammtest", "zeichnen" (gezeichnet wird so, geprüft
## `lage` – nur für Lagen in der geprüften Hülle), "fern" (Art der
## Fernfassung), "kranz" (Art des Verdeckungsrings), "drehung".
## Rückgabe: gesetzt? Der Grund für ein Nein steht in `rahmen.grund`.
static func pflanze(ws: Waldsetzer, rahmen: Waldrahmen, b: Dictionary, lage_: Transform3D,
		stamm_art: String, krone_art: String, stamm_ton: Color, krone_ton: Color,
		optionen: Dictionary = {}) -> bool:
	var huelle := lage_ * (b["huelle"] as AABB)
	if not rahmen.weg_frei(huelle):
		rahmen.zaehle("nein_frei")
		rahmen.grund = "frei"
		return false
	if bool(optionen.get("kante", false)) and not rahmen.kante_frei(huelle):
		rahmen.zaehle("nein_kante")
		rahmen.grund = "kante"
		return false
	var krone_r := maxf(huelle.size.x, huelle.size.z) * 0.5
	if not rahmen.kegel_frei(huelle):
		rahmen.zaehle("nein_kegel")
		rahmen.grund = "kegel"
		return false
	var fuss := lage_.origin
	var stamm: ArrayMesh = b["stamm"]
	var s_box := stamm.get_aabb()
	var r := float(b.get("radius", 0.5)) * maxf(lage_.basis.x.length(), lage_.basis.z.length())
	var fuss_r := r
	var fr: PackedFloat32Array = b.get("fuss_radien", PackedFloat32Array())
	for f in fr:
		fuss_r = maxf(fuss_r, f * maxf(lage_.basis.x.length(), lage_.basis.z.length()))
	var fussweite := float(optionen.get("fussweite", fuss_r))
	var achse := PackedVector3Array()
	var h: float = b.get("hoehe", s_box.end.y)
	for k in 12:
		var t := float(k) / 11.0
		achse.append(lage_ * (Vector3(0.0, t * h * 0.95, 0.0) + neigung_bei(b, t * 0.95)))
	var spitze := achse[achse.size() - 1]
	if not bool(optionen.get("ohne_stammtest", false)) \
			and not rahmen.stamm_frei(fuss, spitze, r, fussweite, float(optionen.get("zugabe", 0.9)),
			achse):
		rahmen.zaehle("nein_stamm")
		rahmen.grund = "stamm"
		return false
	if not Waldsetzer.kegel_frei(fuss.lerp(spitze, 0.75), r * 2.0, rahmen.kegel):
		rahmen.zaehle("nein_kegel_stamm")
		rahmen.grund = "kegel_stamm"
		return false
	var bild: Transform3D = optionen.get("zeichnen", lage_)
	var eigen_ton: Color = b.get("ton", Color.WHITE)
	if not stamm_art.is_empty():
		ws.setze(stamm_art, stamm, bild, stamm_ton * eigen_ton)
		if ws.hat_art(stamm_art + "_schatten") and b.get("schatten") != null:
			ws.setze(stamm_art + "_schatten", b["schatten"] as ArrayMesh, bild)
	if not krone_art.is_empty() and b.get("krone") != null:
		ws.setze(krone_art, b["krone"] as ArrayMesh, bild, krone_ton)
	var fern_art: String = optionen.get("fern", "")
	if not fern_art.is_empty() and b.get("krone") != null:
		var v: int = b.get("variante", 0)
		var k := 2 if v == 2 else (1 if v == 1 else 0)
		var netz: ArrayMesh
		if b.has("fern_netz"):
			netz = b["fern_netz"]
		else:
			netz = vorrat(rahmen, "fern%d" % k, func() -> ArrayMesh: return fernbaum(k))
		var hoch := float(b.get("hoehe", 12.0)) * bild.basis.y.length()
		var f := hoch / netz.get_aabb().end.y
		var breit := bild.basis.x.length() / maxf(bild.basis.y.length(), 0.001)
		var fern_lage := Transform3D(bild.basis.orthonormalized().scaled_local(
				Vector3(f * breit, f, f * breit)), fuss)
		ws.setze(fern_art, netz, fern_lage, krone_ton)
	var kranz_art: String = optionen.get("kranz", "")
	if not kranz_art.is_empty() and b.get("kranz") != null:
		var flach := Basis(Vector3.UP, float(optionen.get("drehung", 0.0))).scaled_local(
				Vector3(lage_.basis.x.length(), 1.0, lage_.basis.z.length()))
		ws.setze(kranz_art, b["kranz"] as ArrayMesh, Transform3D(flach, fuss), Color(1, 1, 1, 1))
	rahmen.kronen.dazu(Vector2(huelle.get_center().x, huelle.get_center().z), krone_r * 0.75)
	return true


## Ein Hain um `mitte` (Welt-XZ, wald.gd:2229): `anzahl` Bäume in bis zu
## `weite` m, der erste nahe der Mitte und der größte, die übrigen schief
## verteilt (0,6–1,25); Stämme halten im Hain 60 % des üblichen Abstands,
## die Kronen überlappen sich; unter gut jedem zweiten Baum ein Strauch.
##
## `arten`: woraus der Hain wächst, je Eintrag
##   {"rolle": "M3" (Fremdmodelle, "" = nur prozedural), "nadel": false,
##    "hoehe": 12.0, "unten": 0.36, "gewicht": 1.0 (Anteil der Wahl),
##    "ton": Color (Kronentönung, mal Hainton), "stamm_ton": Color,
##    "rueckfall": {Optionen für `baum()`} (ohne Modell; Vorgabe ein
##    mittlerer Laubbaum in Höhe und Ansatz der Art)}
## `optionen`:
##   hoehe     Callable(x, z) -> float: Geländehöhe (PFLICHT; NAN = kein Boden)
##   anzahl, weite   (5, 7,0)
##   ton       Tönung des Hains (Color.WHITE)
##   busch     ArrayMesh fürs Unterholz in der Kronenart (null = keins)
##   nah, weit Abstand zum Weg (`Waldrahmen.platz`, 3 … 42)
##   stamm, krone, fern   Arten im Setzer ("stamm", "krone", "fern")
##   kante     Kantenregel prüfen (true)
## Rückgabe: die Füße der gesetzten Bäume (Welt-XZ) – etwa für
## `bodenstueck()`, das erst nach allen Hainen setzt (Abweichung vom Plan,
## dort `void`: wald.gd sammelt sie in einem statischen Merker).
static func hain(ws: Waldsetzer, rahmen: Waldrahmen, rng: RandomNumberGenerator, mitte: Vector2,
		arten: Array, optionen: Dictionary = {}) -> PackedVector2Array:
	var fuesse := PackedVector2Array()
	var hoehe: Callable = optionen["hoehe"]
	var anzahl := int(optionen.get("anzahl", 5))
	var weite := float(optionen.get("weite", 7.0))
	var ton_hain: Color = optionen.get("ton", Color.WHITE)
	var busch: ArrayMesh = optionen.get("busch", null)
	var nah := float(optionen.get("nah", 3.0))
	var weit := float(optionen.get("weit", 42.0))
	var stamm_art := String(optionen.get("stamm", "stamm"))
	var krone_art := String(optionen.get("krone", "krone"))
	var fern_art := String(optionen.get("fern", "fern"))
	var kante := bool(optionen.get("kante", true))
	var summe := 0.0
	for a: Dictionary in arten:
		summe += float(a.get("gewicht", 1.0))
	if arten.is_empty() or summe <= 0.0:
		return fuesse
	for n in anzahl:
		var gesetzt := false
		for wurf in 3:
			var w := rng.randf() * TAU
			var r := (sqrt(rng.randf()) * weite) if n > 0 else rng.randf_range(0.0, 1.2)
			var p := mitte + Vector2(cos(w), sin(w)) * r
			if not rahmen.platz(p, nah, weit):
				continue
			if not rahmen.staemme.frei(p, HAIN_ABSTAND * 0.6):
				continue
			var y: float = hoehe.call(p.x, p.y)
			if is_nan(y):
				continue
			var art := _art_waehlen(arten, summe, rng.randf())
			var b := _baum_der_art(rahmen, art, streu(p, 23))
			# Wenige große, viele kleine.
			var groesse := rng.randf_range(1.15, 1.5) if n == 0 \
					else lerpf(0.6, 1.25, pow(rng.randf(), 1.4))
			var l := lage(Vector3(p.x, y, p.y), rng.randf() * TAU,
					groesse * rng.randf_range(0.9, 1.1), groesse)
			# Breit und gedrungen oder schmal und hoch, je Baum, in der
			# geprüften Hülle gestaucht (nach dem Ort gestreut, wald.gd:2254).
			var bild := Transform3D(l.basis.scaled_local(Vector3(
					lerpf(0.78, 1.0, streu(p, 17)), lerpf(0.74, 1.0, streu(p, 11)),
					lerpf(0.78, 1.0, streu(p, 17)))), l.origin)
			var krone_ton := ton_hain * ton(rng, Vector2(0.86, 1.0), 0.03) \
					* (art.get("ton", Color.WHITE) as Color)
			if bool(art.get("nadel", false)):
				krone_ton = krone_ton * NADEL_TON
			var stamm_ton := ton(rng, Vector2(0.8, 0.95), 0.03) \
					* (art.get("stamm_ton", Color.WHITE) as Color)
			var ok := pflanze(ws, rahmen, b, l, stamm_art, krone_art, stamm_ton, krone_ton,
					{"kante": kante, "fern": fern_art, "zeichnen": bild})
			if not ok and groesse > 0.75:
				# Unter einer Kante: ein kleinerer Baum passt vielleicht.
				groesse = 0.65
				l = lage(Vector3(p.x, y, p.y), rng.randf() * TAU, 0.7, groesse)
				ok = pflanze(ws, rahmen, b, l, stamm_art, krone_art, Color(0.9, 0.9, 0.9),
						krone_ton, {"kante": kante, "fern": fern_art})
			if not ok:
				continue
			rahmen.staemme.dazu(p, HAIN_ABSTAND * 0.6)
			rahmen.zaehle("hain")
			fuesse.append(p)
			gesetzt = true
			if busch != null and rng.randf() < 0.55:
				var wb := rng.randf() * TAU
				var ort := p + Vector2(cos(wb), sin(wb)) * rng.randf_range(1.6, 2.6)
				if rahmen.platz(ort, nah, weit, 3.0):
					var oy: float = hoehe.call(ort.x, ort.y)
					if not is_nan(oy):
						randbusch(ws, rahmen, busch, Vector3(ort.x, oy, ort.y), rng, 0.1, krone_art)
			break
		if not gesetzt:
			rahmen.zaehle("hain_ohne_platz")
	# Am Rand des Hains ein, zwei Sträucher: Der Wald endet nicht an Stämmen.
	if busch != null:
		for k in rng.randi_range(0, 2):
			var wb := rng.randf() * TAU
			var ort := mitte + Vector2(cos(wb), sin(wb)) * (weite + rng.randf_range(1.5, 3.5))
			if rahmen.platz(ort, nah, weit, 3.0):
				var oy: float = hoehe.call(ort.x, ort.y)
				if not is_nan(oy):
					randbusch(ws, rahmen, busch, Vector3(ort.x, oy, ort.y), rng, 1.4, krone_art)
	return fuesse


## Gewichtete Wahl einer Art (`wurf` 0..1).
static func _art_waehlen(arten: Array, summe: float, wurf: float) -> Dictionary:
	var ziel := wurf * summe
	for a: Dictionary in arten:
		ziel -= float(a.get("gewicht", 1.0))
		if ziel < 0.0:
			return a
	return arten[arten.size() - 1]


## Der Baum einer Art: Modell der Rolle, sonst der prozedurale Rückfall
## (beides im Vorrat des Rahmens).
static func _baum_der_art(rahmen: Waldrahmen, art: Dictionary, wahl: float) -> Dictionary:
	var rolle := String(art.get("rolle", ""))
	var nadel := bool(art.get("nadel", false))
	var hoehe := float(art.get("hoehe", 12.0))
	var unten := float(art.get("unten", 0.36))
	if not rolle.is_empty():
		var m := modellbaum(rolle, nadel, wahl, hoehe, unten,
				art.get("stamm_ton", Color.WHITE) as Color)
		if not m.is_empty():
			return m
	var o: Dictionary = art.get("rueckfall", {})
	if o.is_empty():
		o = {"mittel": true, "hoehe": hoehe, "radius": 0.34, "variante": 2 if nadel else 0,
				"krone_radius": 3.0 if nadel else 5.3, "krone_hoehe": 8.0,
				"ballen": 6 if nadel else 4, "unten": unten, "tanne": nadel, "saat": 2101}
	var schluessel := "rueckfall|" + var_to_str(o)
	return vorrat(rahmen, schluessel, func() -> Dictionary: return baum(o))


## Ein Strauch am Waldrand im Stoff der Kronen (wald.gd:2391).
static func randbusch(ws: Waldsetzer, rahmen: Waldrahmen, netz: ArrayMesh, fuss: Vector3,
		rng: RandomNumberGenerator, abstand: float = 1.4, art: String = "krone") -> void:
	if not rahmen.staemme.frei(Vector2(fuss.x, fuss.z), abstand):
		return
	var gross := rng.randf_range(0.75, 1.35)
	var l := lage(fuss + Vector3.UP * 0.5 * gross, rng.randf() * TAU,
			gross * rng.randf_range(0.9, 1.2), gross)
	var huelle := l * netz.get_aabb()
	if not rahmen.weg_frei(huelle) or not rahmen.kante_frei(huelle):
		return
	var i := rahmen.naechste(fuss.x, fuss.z)
	if i >= 0 and absf(rahmen.quer(i, fuss.x, fuss.z)) < rahmen.halb_bei(i) + 2.5 \
			and absf(fuss.y - rahmen.decke_bei(i)) < 3.0:
		return
	ws.setze(art, netz, l, ton(rng, Vector2(0.8, 1.0)))
	rahmen.staemme.dazu(Vector2(fuss.x, fuss.z), 1.2)
	rahmen.zaehle("randbuesche")


## Ein toter Baum (`tot`: Stämme, etwa die Stämme von `modellbaum("M17"/
## "M22")`) am Fuß `fuss`, schief bis 9° (wald.gd:2410).
static func totholz(ws: Waldsetzer, rahmen: Waldrahmen, tot: Array[ArrayMesh], fuss: Vector3,
		rng: RandomNumberGenerator, art: String = "stamm") -> void:
	if tot.is_empty() or not rahmen.staemme.frei(Vector2(fuss.x, fuss.z), 2.0):
		return
	var netz := tot[rng.randi_range(0, tot.size() - 1)]
	var l := lage(fuss, rng.randf() * TAU, rng.randf_range(0.9, 1.2), rng.randf_range(0.85, 1.2),
			deg_to_rad(rng.randf_range(0.0, 9.0)), Vector3(rng.randf() - 0.5, 0.0, rng.randf() - 0.5))
	var spitze := l * Vector3(0.0, netz.get_aabb().end.y, 0.0)
	if not rahmen.stamm_frei(fuss, spitze, 0.6) or not rahmen.kante_frei(l * netz.get_aabb()):
		return
	ws.setze(art, netz, l, TOT_TON)
	rahmen.staemme.dazu(Vector2(fuss.x, fuss.z), 2.0)
	rahmen.zaehle("totholz")


## Ein Stück Waldboden neben dem Baum bei `p` (wald.gd:2311): ein Modell
## aus `modelle` (`Fremdmodelle.rolle_netze`, etwa M8/M16, für Raum 1 M21
## Felsen und M23 Treibholz) 1,8–3,2 m vom Stamm, nie auf dem Weg, an
## Kisten oder einem anderen Stamm. `arten[k]`: die Arten von `modelle[k]`
## im Setzer (`Waldsetzer.fremd`). Felsen (Name mit „Rock") 0,3–0,55 der
## Rollengröße und ein Zehntel eingesunken, Holz 0,6–0,95. Nach dem Ort
## gestreut; mit `Effekte.reduziert` nur jedes zweite.
static func bodenstueck(ws: Waldsetzer, rahmen: Waldrahmen, p: Vector2, modelle: Array[Dictionary],
		arten: Array, hoehe: Callable, nah: float = 3.0, weit: float = 42.0) -> void:
	if modelle.is_empty() or (Effekte.reduziert and streu(p, 61) < 0.5):
		return
	var w := streu(p, 41) * TAU
	var ort := p + Vector2(cos(w), sin(w)) * lerpf(1.8, 3.2, streu(p, 43))
	if not rahmen.platz(ort, nah, weit, 3.0) or not rahmen.staemme.frei(ort, 0.9):
		return
	var i := rahmen.naechste(ort.x, ort.y)
	if i >= 0 and absf(rahmen.quer(i, ort.x, ort.y)) < rahmen.halb_bei(i) + 2.5:
		return
	var y: float = hoehe.call(ort.x, ort.y)
	if is_nan(y) or not rahmen.kiste_frei(Vector3(ort.x, y, ort.y), 2.0):
		return
	var k := clampi(int(streu(p, 47) * float(modelle.size())), 0, modelle.size() - 1)
	var modell: Dictionary = modelle[k]
	var fels := String(modell.get("name", "")).contains("Rock")
	var gross := lerpf(0.3, 0.55, streu(p, 53)) if fels else lerpf(0.6, 0.95, streu(p, 53))
	var huelle: AABB = modell["huelle"]
	var l := Transform3D(Basis(Vector3.UP, streu(p, 59) * TAU).scaled(Vector3.ONE * gross),
			Vector3(ort.x, y - huelle.size.y * gross * (0.1 if fels else 0.04), ort.y))
	var namen: Array[String] = []
	namen.assign(arten[k])
	ws.setze_fremd(namen, modell, l, ton(PropWerkzeug.zufall(int(streu(p, 67) * 9999.0)),
			Vector2(0.82, 1.0), 0.04))
	rahmen.staemme.dazu(ort, 0.9)
	rahmen.zaehle("waldboden")
