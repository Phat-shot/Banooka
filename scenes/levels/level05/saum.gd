extends RefCounted
class_name L05Saum
## Level 05, Modul „Saum": die Ränder des Weges als modellierte Kanten
## (Entwurf §5 B/C/D, §8.1, §9.1) – Lösswände im Hohlweg, Böschungen über
## den Terrassen, Sandstein am Sonnenhang des Tobels, das Ufer zum Bach,
## die Wehrwände, die Stirnen der Lücken und die Setzstufen der Treppen.
##
## WOHER DIE FORM KOMMT. Die Ränder stehen als Züge in `Level05.ZUEGE` (je
## Seite eine Linie in (s, q) und Stützstellen für Höhe, Wandwinkel,
## Überhang der Grasnarbe und Fels). Dieselben Werte liest das Gelände
## (`L05Gelaende`) über `form_auf`/`form_ab`: Es liegt unter jeder Wand und
## jeder Krone und tritt erst hinter der Krone über sie – so stoßen Saum und
## Gelände ohne Naht aneinander.
##
## PROFILE (je Querschnitt ein `GelaendeSaum.Profil`, gebaut mit den Helfern
## aus `Kanten`):
##   auf    Böschung hinauf, von der Krone her: Krone, Grasnarbe mit
##          Überhang zum Weg (Punkte 0–5, so hängen die Karten aus `Kanten`
##          – Halme und Wurzeln – unter der Narbe), unterschnittene Wand-
##          krone, Wand im Winkel des Zuges, Fuß, Schulter, unter die Decke.
##          Kanten.profil_boeschung (am steilsten gut 50°) und profil_wand
##          (Schichtfels mit Simsen ab 5,5 m) treffen eine Lösswand von
##          3–5 m unter 78–84° mit Narbe nicht; dieses Profil nimmt ihre
##          Teile: Narbe wie `Kanten.profil_ab`, Farben über `Kanten.farbe`,
##          Rauschen der Wand nur nach außen (`GelaendeSaum`: Richtung 2).
##          Die Platte hinter der Krone endet nie über dem gezeichneten
##          Gelände (PLATTE_UNTER, gemessen dort, wohin der Querschnitt
##          wirklich zeigt: `_platte_lage`), und wo der nächste Zug beginnt,
##          sinkt das ganze Profil unter Ufer und Gelände (`uebergabe`).
##   ab     Ufer oder Wehrwand hinab, von der Lippe her (wie `profil_ab`,
##          30 Punkte dort, 16 hier): Narbe über der Lippe, Wand bis aufs
##          Bett, Fuß unter das Bett des Geländes. Erde und Moos am Ufer,
##          Schichtfels an der Wehrwand („fels").
##   Stirn  an den Lippen der sechs Lücken `Kanten.profil_stirn` mit der
##          Wegmaske; unter der Narbe dunkel (Verdeckung × DUNKEL – Albedo
##          höchstens 0,1, Entwurf §8.4: dunkle Flanke).
##   Stufe  an jeder Stufe der Decke (Suhlgraben, Wurzeltreppen S1–S3): eine
##          angestrahlte Setzstufe aus Löss mit Narbe nach der Wegmaske; am
##          Graben läuft ihr Fuß als Schlammsohle bis in seine Mitte.
## In einer Lücke laufen die Wände der Seiten bis auf ihren Grund hinab
## (der Spalt hat Seiten), das Ufer wird zur Rinne ausgeschnitten.
##
## BAU: alle Linien über `Kanten.linien_schritte` in GEMEINSAMEN Stücken zu
## 30 m (je Stück ein Netz und ab 85 m seine grobe Fassung, dazu die Karten
## bis 55 m) – mit `seite_schritte` hätte jede der 24 Linien einen eigenen
## Knoten, und der Rückblick sieht fast alle zugleich. Sichtweite 400 m:
## Die Kamera sieht bis 380 m (Level05.tscn), und ein Stück, das in der
## Ferne verschwände, ließe das Gelände unter ihm als Graben stehen. Ein
## Stoff für alles (`thema`), keine Schatten, keine Kollision – die Linien
## sind die Kollisionskanten (Leitlinie, Lippe der Schulter, Stufen).
## Bauspeicher: `speicher()` (Level 05 nennt ihn, `Kanten` legt ab).
##
## FREIRAUM (Entwurf §7.1): K1 – nichts vom Saum liegt über |q| ≤ 3,5; die
## Narbe tritt höchstens `Level05.ZUEGE` „Überhang" (≤ 0,45 m) vor die
## Linie, die Linien liegen bei |q| ≥ 4,1. K3 – die Kronen der Böschungen
## stehen höchstens 5,6 m über der Decke neben dem Weg; ob sie die Eiche
## verdecken, misst `Level05.freiraumprobe`.

const NAME := "Saum"
## Abstand der Querschnitte an den Seiten und quer über den Weg (m), in den
## Übergaben (`uebergabe`) enger: Dort schrumpft das Kronenband, und das
## Plattenende lief schräg durch die Querschnitte – zwischen zweien stand es
## über dem steil fallenden Feld bis 0,16 m frei (s 180; Prüfung P3, Runde 3).
const SCHRITT := 0.7
const SCHRITT_QUER := 0.45
const SCHRITT_UEBERGABE := 0.35
## Sichtweite der Stücke (siehe Kopf).
const SICHT := 400.0
## Krone hinter der Wand: so weit reicht der Saum hinter die Wandkrone,
## und so hoch steigt er dort (das Gelände tritt vorher über ihn).
const KRONE_WEIT := 2.8
const KRONE_STEIGT := 0.06
## Übergabe (siehe `uebergabe`): Am Ende der Übergabe liegt die Krone so weit
## unter der Decke, und von Platte und Kronenband bleibt dieser Anteil.
const UEBERGABE_SINKT := -0.08
const UEBERGABE_BAND := 0.11
## Das äußere Ende der Platte liegt mindestens so tief unter dem Gelände
## (`L05Gelaende.hoehe`): Es endet nie frei über ihm (siehe `_platte_lage`).
## Es folgt der Linie, geglättet mit PLATTE_GLATT (m, wie jeder Profilpunkt
## mit seinem Fenster, `GelaendeSaum.Profil.glatt`).
const PLATTE_UNTER := 0.12
const PLATTE_GLATT := 2.5
## Stufen der Decke: Querschnitte der Seiten so weit davor und dahinter (m;
## siehe `bauschritte`).
const STUFE_SPIEL := 0.02
## Welle der Kronenhöhe entlang der Seite (m) und ihr Maßstab (1/m).
const KRONE_WELLE := 0.35
const KRONE_WELLE_DICHTE := 0.045
## Stirnen der Lücken: Verdeckung unter der Narbe mal DUNKEL. Gerendert
## (Modus „unshaded", linear; Gegenprobe Tafel sRGB 0,5 → 0,216 statt 0,214)
## liegt die Albedo mitten auf allen zwölf Flanken bei 0,002–0,004, im 95.
## Perzentil höchstens 0,006 (Entwurf §8.4: ≤ 0,1) – seit das Gelände dort
## hinter der Stirn liegt (`L05Gelaende.LUECKE_HINTER`).
const DUNKEL := 0.45
## Ein Querschnitt gilt erst so weit hinter einer Lippe als in der Lücke (m;
## siehe `_luecke`). Kleiner als der Querschnitt knapp innerhalb der Lippe
## (`Kanten.feste_strecken`: 2 × EPS = 1 cm).
const LUECKE_SPIEL := 0.002
## Löss der Wände (Ton der Erde im Stoff der Kanten) und Rotocker des
## Sandsteins am Sonnenhang (Ton der warmen Schichtbänke).
const LOESS := Color(1.15, 1.0, 0.74)
const SANDSTEIN := Color(1.12, 0.86, 0.68)


## Bauschritte: der Stoff, je Seite und Zug „… wird vermessen", die Stirnen
## und Stufen in einem Schritt, dann „Saum wird gebaut" – aus dem
## Bauspeicher nach dem Stoff EIN Schritt „Saum wird geladen".
static func bauschritte(level: Level05) -> Array:
	var linien: Array = []
	var feste := Kanten.feste_strecken(level.weg)
	# Je Stufe der Decke ein Querschnitt STUFE_SPIEL davor und dahinter, jeder
	# mit der Decke seiner Seite. WARUM: `feste_strecken` setzt sie nur 5 mm
	# (Kanten.EPS) neben die Naht, und `GelaendeSaum.linie` verwirft Teil-
	# strecken unter 5 mm Bogenlänge. Auf der Innenseite der Kurve sind es
	# knapp weniger: Am Suhlgraben fehlten links beide Querschnitte (23,495
	# und 23,5, 28,095 und 28,1), und das Gitter lief über 0,7 m von der
	# oberen Decke auf die Sohle – davor eine Kerbe in der Schulter (0,26 m
	# unter der Kollision), in der Grabenecke ein Keil (0,8 m über der
	# Sohle; Prüfung P3, Runde 2).
	for st: Vector3 in _stufen(level.weg):
		feste.append_array([st.x - STUFE_SPIEL, st.x + STUFE_SPIEL])
	for i in Level05.ZUEGE.size():
		var zug: Dictionary = Level05.ZUEGE[i]
		var auf := String(zug["art"]) == "auf"
		var linie := Level05.zug_linie(zug)
		# Dazu je ein Querschnitt an jeder Ecke der Linie: Ohne ihn lief das
		# Gitter als Sehne über die Ecke der Nische hinter G2 (die Leitlinie
		# knickt dort um 68°), und in der Ecke blieb ein Fleck Schulter ohne
		# Saum, unter dem nur das Feld lag (0,9 m tief; Nahtprobe P3).
		var feste_zug := feste.duplicate()
		for p: Vector2 in linie:
			feste_zug.append(p.x)
		# In der Übergabe Querschnitte alle SCHRITT_UEBERGABE Meter.
		var von_ueb := _uebergabe_von(zug)
		if not is_nan(von_ueb):
			var s_ueb := von_ueb
			while s_ueb < float(zug["bis"]) - SCHRITT_UEBERGABE * 0.5:
				feste_zug.append(s_ueb)
				s_ueb += SCHRITT_UEBERGABE
		# Die Plattenenden eines Zuges „auf" entstehen beim ersten Querschnitt
		# für alle zugleich (`_platte_lage`); dazu braucht er Linie und Stellen.
		var profil := _profil_auf.bind(level, zug, {"linie": linie, "feste": feste_zug}) if auf \
				else _profil_ab.bind(level, zug)
		linien.append({"seite": float(zug["seite"]), "linie": linie, "profil": profil,
				"gruppe": String(zug["name"]), "schritt": SCHRITT, "karten": true,
				"saat": 5101 + i, "feste_s": feste_zug})
	linien.append_array(_querlinien(level))
	# Der Stoff geht leer hinein und wird im ersten Schritt gefüllt (Level05,
	# Kopf: STOFFE): Sandstein und Moos kosten kalt gut 0,1 s.
	var stoff := ShaderMaterial.new()
	var schritte: Array = [{"text": "Sandstein und Moos für die Wände", "tun": func() -> void:
		L05Gelaende.stoff_uebertragen(stoff, Kanten.stoff(thema()))}]
	schritte.append_array(Kanten.linien_schritte(level.geometrie, level.weg, linien, stoff, NAME,
			speicher(), {"sicht": SICHT}))
	return schritte


## Schlüssel im Bauspeicher. Er nennt `Effekte.reduziert` (bauspeicher.gd,
## Kopf: SCHLÜSSEL): Die Plattenenden liegen unter dem GEZEICHNETEN Feld
## (`_platte_lage`), und das setzt seine Punkte auf dem Handyweg 1,4-mal
## weiter auseinander (`L05Gelaende._abstand`). Mit einem Schlüssel für
## beide lud ein Werkzeug mit gemeinsamem user:// (oder ein späterer
## Schalter im Spiel) einen Saum, der gegen das andere Feld gebaut war.
static func speicher() -> String:
	return "l05_saum_" + ("handy" if Effekte.reduziert else "voll")


## Stoff der Kanten: Erde ist Löss (die Erde des Waldwegs, gelb-ocker
## getönt) – Wände, Narbe von unten, Ufer; die warmen Schichtbänke des
## Sandsteins in Rotocker (Tobel, Sonnenhang, Entwurf §5 D). Rasen, Moos und
## Kalk wie in Level 01 (die Wegdecke trägt denselben Rasen).
static func thema() -> Dictionary:
	return {"erde": Materialbibliothek.waldweg().albedo_texture,
			"uniforms": {"erde_ton": LOESS, "fels_warm": SANDSTEIN}}


# ================================================================ Formen

## Die Form eines Zuges „auf" an der Stelle `s` – dieselbe für Saum und
## Gelände:
##   krone   Welt-Y der Krone (geglättete Decke + h + Welle)
##   deck    Welt-Y der Decke (in einer Lücke zwischen ihren Lippen)
##   hoch    Krone über der Decke, mindestens 6 cm (in der Übergabe weniger)
##   lauf    wie weit die Wandkrone hinter dem Fuß liegt (m, waagerecht)
##   narbe   Überhang der Grasnarbe zum Weg (m)
##   band    Maßstab des Kronenbands (1; in der Übergabe bis UEBERGABE_BAND):
##           die Platte reicht `weit` = KRONE_WEIT · band hinter die Wand-
##           krone, das Gelände (`L05Gelaende`) staucht seine Krone ebenso
##   ueb     Anteil dieses Zuges in der Übergabe (`uebergabe`)
##   winkel, fels  aus dem Zug
## In der Übergabe an den nächsten Zug sinkt die Krone bis UEBERGABE_SINKT
## unter die Decke, und Platte und Kronenband schrumpfen: Am Ende des Zuges
## liegt sein Querschnitt (und damit der Deckel des Gitters) unter Schulter,
## Ufer und Gelände.
static func form_auf(level: Level05, zug: Dictionary, s: float) -> Dictionary:
	var w := Level05.zug_werte(zug, s)
	var deck := level.weg.boden_bei(s)
	var krone := level.decke_glatt(s) + w[0] \
			+ KRONE_WELLE * Kanten.welle(s * KRONE_WELLE_DICHTE, 61.0 + float(zug["seite"]))
	var ueb := uebergabe(zug, s)
	var hoch := maxf(krone - deck, 0.06)
	var band := 1.0
	if ueb < 1.0:
		krone = lerpf(deck + UEBERGABE_SINKT, krone, ueb)
		hoch = maxf(krone - deck, lerpf(UEBERGABE_SINKT, 0.06, ueb))
		band = lerpf(UEBERGABE_BAND, 1.0, ueb)
	var f := clampf(hoch, 0.1, 1.0)
	var k := 1.0 / tan(deg_to_rad(clampf(w[1], 25.0, 88.0)))
	return {"krone": deck + hoch, "deck": deck, "hoch": hoch, "f": f, "k": k,
			"lauf": k * (hoch - 0.55 * f), "narbe": w[2] * smoothstep(0.15, 1.2, hoch),
			"band": band, "weit": KRONE_WEIT * band, "ueb": ueb,
			"winkel": w[1], "fels": w[3]}


## ÜBERGABE: Wo auf derselben Seite der nächste Zug beginnt, bevor `zug`
## endet (Böschung links → Ufer links 179–182, Böschung rechts → Teichwand
## 277–279), gibt `zug` die Form über diese Strecke ab: 1 bis zum Anfang des
## nächsten, 0 an seinem Ende, dazwischen weich. Sonst 1.
## WARUM: Vorher galt in der Überlappung im Gelände hart der Zug, dessen Ende
## weiter weg war, und die Böschung lief mit voller Platte (2,8 m bei
## Krone + 6 cm) bis an ihr Ende. Hinter der Mitte lag das Feld schon im Bett
## des Ufers, und die Platte stand 1–1,9 m frei darüber, am Ende mit einem
## dunklen Deckel (CP3 bei 178, Messtor 280; Prüfung P3, Runde 2).
static func uebergabe(zug: Dictionary, s: float) -> float:
	var von := _uebergabe_von(zug)
	if is_nan(von):
		return 1.0
	return 1.0 - smoothstep(von, float(zug["bis"]), s)


## Wo die Übergabe von `zug` beginnt (der Anfang des nächsten Zuges seiner
## Seite), NAN ohne Übergabe.
static func _uebergabe_von(zug: Dictionary) -> float:
	var bis: float = zug["bis"]
	for z: Dictionary in Level05.ZUEGE:
		if float(z["seite"]) != float(zug["seite"]):
			continue
		# `zug` selbst fällt heraus: Sein Anfang liegt nicht hinter sich.
		var von: float = z["von"]
		if von > float(zug["von"]) and von < bis and float(z["bis"]) > bis:
			return von
	return NAN


## Die Form eines Zuges „ab" an `s`:
##   bett    Welt-Y des Grundes vor der Wand (geglättete Decke − h)
##   deck, tief (Decke über dem Bett, mindestens 5 cm), narbe, fels
##   fuss    wie weit der Fuß der Wand vor der Lippe liegt (m, waagerecht)
static func form_ab(level: Level05, zug: Dictionary, s: float) -> Dictionary:
	var w := Level05.zug_werte(zug, s)
	var deck := level.weg.boden_bei(s)
	var bett := level.decke_glatt(s) - w[0]
	var tief := maxf(deck - bett, 0.05)
	var k := 1.0 / tan(deg_to_rad(clampf(w[1], 25.0, 88.0)))
	return {"bett": deck - tief, "deck": deck, "tief": tief, "f": clampf(tief, 0.1, 1.0),
			"k": k, "fuss": _ab_o(tief, k, w[3]) + 0.1,
			"narbe": w[2] * smoothstep(0.15, 1.0, tief), "fels": w[3]}


## Versatz einer Wand „ab" in der Tiefe `d` unter der Decke: im Winkel des
## Zuges, am erdigen Ufer oben gerundet (die ersten 1,2 m flacher).
static func _ab_o(d: float, k: float, fels: float) -> float:
	return d * k + (1.0 - fels) * 0.35 * minf(d, 1.2)


# ================================================================ Profile

## Böschung hinauf (siehe Kopf), 18 Punkte von der Krone zur Decke. `o`
## zählt vom Fuß (der Linie) nach außen; die Narbe tritt zum Weg vor.
static func _profil_auf(i: int, probe: Dictionary, level: Level05,
		zug: Dictionary, lage: Dictionary) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var seite: float = zug["seite"]
	var m := form_auf(level, zug, s)
	var krone: float = m["krone"]
	var deck: float = m["deck"]
	var hoch: float = m["hoch"]
	var f: float = m["f"]
	var k: float = m["k"]
	var lauf: float = m["lauf"]
	var ov: float = m["narbe"]
	var fels: float = m["fels"]
	var erde := lerpf(1.0, 0.2, fels)
	var schicht := lerpf(0.04, 0.16, fels)
	var p := GelaendeSaum.Profil.new()
	# --- Krone und Grasnarbe (0–5): Die Narbe tritt `ov` vor die Wandkrone.
	# Die Platte endet `weit` hinter der Wandkrone, nie über dem gezeichneten
	# Gelände: sonst stünde ihre Kante frei (in der Übergabe liegt das Feld
	# schon im Bett des nächsten Zuges, siehe `uebergabe`; an Ecken der Linie
	# zeigt der Querschnitt schräg, siehe `_platte_lage`).
	var weit: float = m["weit"]
	if not lage.has("y"):
		_platte_lage(level, zug, lage)
	var ende_y := krone + KRONE_STEIGT
	var stellen: PackedFloat32Array = lage["s"]
	if i < stellen.size() and absf(stellen[i] - s) < 0.001:
		ende_y = minf(ende_y, (lage["y"] as PackedFloat32Array)[i])
	else:
		# Nicht die Querschnitte, für die `lage` gerechnet ist (eine andere
		# Abtastung): quer zum Weg prüfen.
		push_warning("L05Saum: Plattenende an s %.2f quer zum Weg geprüft" % s)
		var ende := LevelWerkzeuge.punkt_frei(level.verlauf, s,
				float(probe["q"]) + seite * (lauf + weit))
		var feld := level.gelaende.hoehe(ende.x, ende.z)
		if not is_nan(feld):
			ende_y = minf(ende_y, feld - PLATTE_UNTER)
	p.punkt(lauf + weit, ende_y, Kanten.farbe(0.78, 0.0, 0.1, 1.0), PLATTE_GLATT)
	p.punkt(lauf - ov * 0.4, krone - 0.006 * f, Kanten.farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(lauf - ov * 0.8, krone - 0.035 * f, Kanten.farbe(0.72, 0.1, 0.3, 0.95))
	p.punkt(lauf - ov, krone - 0.12 * f, Kanten.farbe(0.5, 0.6, 0.3, 0.45))
	p.punkt(lauf - ov + 0.06 * f, krone - 0.25 * f, Kanten.farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(lauf - ov + 0.32 * f, krone - 0.33 * f, Kanten.farbe(0.18, 1.0, 0.0, 0.0))
	# --- Wandkrone unter der Narbe, ausgewaschen (6)
	p.punkt(lauf, krone - 0.5 * f, Kanten.farbe(0.24, erde, 0.05, 0.0), 0.8, 0.04, 2.0)
	# --- Wand (7–12): im Winkel des Zuges, Rinnen nur nach außen, im Fels
	# mit Schichtstufen; oben im Schatten der Narbe dunkler.
	var z_a := hoch - 0.8 * f
	var z_b := minf(0.3 * f, 0.5 * z_a)
	for j in 6:
		var t := float(j) / 5.0
		var z := lerpf(z_a, z_b, t)
		p.punkt(k * z, deck + z,
				Kanten.farbe(lerpf(0.5, 0.82, t), erde, lerpf(0.05, 0.3, t * t), 0.0),
				lerpf(1.6, 0.8, t), lerpf(0.14, 0.08, t) * f, 2.0, schicht * f)
	# --- Fuß und Schulter (13–15), dann unter die Decke (16–17, absolut)
	p.punkt(k * z_b * 0.4 + 0.03, deck + 0.4 * z_b, Kanten.farbe(0.6, 0.7, 0.35, 0.2))
	p.punkt(-0.05, deck + 0.015 * f, Kanten.farbe(0.7, 0.35, 0.25, 0.6))
	p.punkt(-0.3, deck - 0.012, Kanten.farbe(0.78, 0.05, 0.1, 1.0))
	var rand := level.weg.wegrand(s)
	p.punkt(seite * rand, deck - 0.015, Kanten.farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0, 1.0, 0.0,
			true)
	p.punkt(seite * (rand - 0.35), deck - 0.03, Kanten.farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0,
			1.0, 0.0, true)
	var l := _luecke(s)
	if not l.is_empty():
		_auf_in_luecke(p, l)
	return p


## PLATTENENDEN eines Zuges „auf", für alle Querschnitte zugleich (beim
## ersten Aufruf von `_profil_auf`; legt in `lage` "s" und "y" ab): je
## Querschnitt das Welt-Y von Punkt 0. Das Ende steht dort, wo
## `GelaendeSaum.querschnitte` es hinsetzt – auf der mit PLATTE_GLATT
## geglätteten Linie, entlang IHRER Normale –, und es liegt PLATTE_UNTER
## unter dem gezeichneten Gelände: an diesem Ort und ein Viertel und halb
## zum Ende der Nachbarn hin. Zwischen zwei Enden läuft die Kante gerade;
## mit diesen Proben liegt sie auch dort unter dem Feld.
## WARUM: Bis Runde 3 prüfte der Saum quer zum Weg (`punkt_frei` an
## q + lauf + weit). An einer Ecke der Leitlinie zeigt der Querschnitt aber
## anders: Am Ausgang der Nische G3 (die Linie springt von 263,0 auf 263,5
## um 1,2 m nach innen) fächern die Querschnitte bis 36° nach +s auf. Sie
## trugen die Krone von 263,5 (9,38) über s 264–267, wo das Feld schon auf
## 8,9 liegt; die Prüfung quer zum Weg traf das höhere Feld daneben, und die
## Platte stand bis 0,5 m frei – ein Grasbrett im Messtor 280 und an CP5
## (Prüfung P3, Runde 3).
static func _platte_lage(level: Level05, zug: Dictionary, lage: Dictionary) -> void:
	var seite: float = zug["seite"]
	var proben := GelaendeSaum.linie(level.weg.verlauf, lage["linie"], SCHRITT, lage["feste"])
	# Dieselbe Mischung zweier Fassungen wie `GelaendeSaum.querschnitte` für
	# einen Punkt mit `glatt` = PLATTE_GLATT.
	var fenster := GelaendeSaum.FENSTER
	var k := 0
	while k < fenster.size() - 2 and fenster[k + 1] < PLATTE_GLATT:
		k += 1
	var t := clampf(inverse_lerp(fenster[k], fenster[k + 1], PLATTE_GLATT), 0.0, 1.0)
	var a := GelaendeSaum.glaetten(proben, fenster[k], seite)
	var b := GelaendeSaum.glaetten(proben, fenster[k + 1], seite)
	var pa: PackedVector3Array = a["p"]
	var pb: PackedVector3Array = b["p"]
	var na: PackedVector3Array = a["n"]
	var nb: PackedVector3Array = b["n"]
	var n := proben.size()
	var stellen := PackedFloat32Array()
	var enden := PackedVector2Array()
	var kronen := PackedFloat32Array()
	for i in n:
		var s: float = proben[i]["s"]
		var m := form_auf(level, zug, s)
		var e := pa[i].lerp(pb[i], t) \
				+ na[i].lerp(nb[i], t).normalized() * (float(m["lauf"]) + float(m["weit"]))
		stellen.append(s)
		enden.append(Vector2(e.x, e.z))
		kronen.append(float(m["krone"]) + KRONE_STEIGT)
	var hoehen := PackedFloat32Array()
	for i in n:
		var y := kronen[i]
		var orte := PackedVector2Array([enden[i]])
		for j: int in [i - 1, i + 1]:
			if j >= 0 and j < n:
				orte.append_array([enden[i].lerp(enden[j], 0.25), enden[i].lerp(enden[j], 0.5)])
		for o: Vector2 in orte:
			var feld := level.gelaende.hoehe(o.x, o.y)
			if not is_nan(feld):
				y = minf(y, feld - PLATTE_UNTER)
		hoehen.append(y)
	lage["s"] = stellen
	lage["y"] = hoehen
## LUECKE_SPIEL hinter der Lippe. WARUM: Die Proben kommen als Vector2 (32
## Bit) an; die Lippe 136,3 etwa als 136,300003, also schon IN der Lücke. Der
## Querschnitt an der Lippe lag dann auf dem Grund, und die Schulter tauchte
## zwischen ihm und dem Querschnitt davor 0,7 m vor der Stirn ab: ein Schlitz
## von 0,25 × 0,8 m hinter der Narbe der Stirn (L2, L3; P3-Prüfung).
static func _luecke(s: float) -> Dictionary:
	var l := Level05.luecke_bei(s)
	if l.is_empty() or s <= float(l["von"]) + LUECKE_SPIEL or s >= float(l["bis"]) - LUECKE_SPIEL:
		return {}
	return l


## In einer Lücke `l`: Fuß, Schulter und was unter der Decke lag, auf den
## Grund der Lücke – die Wand der Seite läuft bis dorthin hinab, dunkel.
static func _auf_in_luecke(p: GelaendeSaum.Profil, l: Dictionary) -> void:
	var grund: float = l["grund_y"]
	for j in range(12, p.anzahl()):
		var tiefe := 0.1 if j == 13 else -0.03
		p.y[j] = grund + (0.25 if j == 12 else tiefe)
		p.farbe[j] = Kanten.farbe(0.12, 0.8, 0.2, 0.0)
		p.rauschen[j] = 0.0
		p.schicht[j] = 0.0


## Ufer oder Wehrwand hinab (siehe Kopf), 16 Punkte von der Decke zum Bett.
## `o` zählt von der Lippe (der Linie) nach außen.
static func _profil_ab(_i: int, probe: Dictionary, level: Level05,
		zug: Dictionary) -> GelaendeSaum.Profil:
	var s: float = probe["s"]
	var seite: float = zug["seite"]
	var m := form_ab(level, zug, s)
	var deck: float = m["deck"]
	var bett: float = m["bett"]
	var tief: float = m["tief"]
	var f: float = m["f"]
	var k: float = m["k"]
	var ov: float = m["narbe"]
	var fels: float = m["fels"]
	var erde := lerpf(0.85, 0.15, fels)
	# Am Ufer tritt die Narbe über eine ausgewaschene Kante, an der Mauer
	# kaum.
	var unter := lerpf(0.2, 0.02, fels) * f
	var p := GelaendeSaum.Profil.new()
	# --- Narbe (0–5) von unter der Decke über die Lippe
	var rand := level.weg.wegrand(s)
	p.punkt(seite * (rand - 0.35), deck - 0.03, Kanten.farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0,
			1.0, 0.0, true)
	p.punkt(ov * 0.4, deck - 0.006 * f, Kanten.farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, deck - 0.035 * f, Kanten.farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, deck - 0.12 * f, Kanten.farbe(0.5, 0.7, 0.3, 0.4))
	p.punkt(ov - 0.06 * f, deck - 0.25 * f, Kanten.farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3 * f, deck - 0.33 * f, Kanten.farbe(0.2, 1.0, 0.0, 0.0))
	p.punkt(-unter, deck - 0.48 * f, Kanten.farbe(0.24, erde, 0.05, 0.0), 0.3, 0.05, -1.0)
	# --- Wand (7–12) bis über das Bett, nach unten nasser und moosiger
	var d_a := 0.65 * f
	var d_b := maxf(tief - 0.3 * f, d_a + 0.02)
	for j in 6:
		var t := float(j) / 5.0
		var d := lerpf(d_a, d_b, t)
		p.punkt(_ab_o(d, k, fels) - unter * (1.0 - t), deck - d,
				Kanten.farbe(lerpf(0.5, 0.64, t), erde, lerpf(0.15, 0.6, t), 0.0),
				lerpf(0.8, 2.0, t), lerpf(0.1, 0.18, t) * f, 1.0, lerpf(0.02, 0.15, fels) * f)
	# --- Fuß und unter das Bett (13–15)
	var fuss: float = m["fuss"]
	p.punkt(fuss + 0.25 * f, bett + 0.04, Kanten.farbe(0.42, 0.6, 0.5, 0.0), 2.0, 0.1)
	p.punkt(fuss + 1.0 * f, bett - 0.35 * f, Kanten.farbe(0.38, 0.7, 0.4, 0.0), 2.5, 0.1)
	p.punkt(fuss + 2.2 * f, bett - 1.4 * f, Kanten.farbe(0.34, 0.8, 0.3, 0.0), 3.0, 0.1)
	var l := _luecke(s)
	if not l.is_empty():
		_ab_in_luecke(p, s, l)
	return p


## In einer Lücke: alles über dem Grund der Lücke (nach außen 1,2 m je Meter
## ansteigend) auf diesen Grund – eine Rinne durch Ufer oder Wehr, zur
## Mitte der Lücke tiefer, an ihren Rändern bleibt mehr stehen.
static func _ab_in_luecke(p: GelaendeSaum.Profil, s: float, l: Dictionary) -> void:
	var grund: float = l["grund_y"]
	var mitte := (float(l["von"]) + float(l["bis"])) * 0.5
	var halb := (float(l["bis"]) - float(l["von"])) * 0.5
	var rand := clampf((absf(s - mitte) - halb + 0.9) / 0.9, 0.0, 1.0)
	var o_max := -INF
	for j in p.anzahl():
		var o := maxf(p.o[j], 0.0) if p.absolut[j] == 0 else 0.0
		var grenze := grund + o * 1.2 + rand * 0.6
		if p.y[j] <= grenze:
			continue
		p.y[j] = grenze
		if p.absolut[j] == 0:
			o_max = maxf(o_max, p.o[j])
			p.o[j] = o_max
		p.farbe[j] = Kanten.farbe(0.2, 0.8, 0.35, 0.0)
		p.rauschen[j] = 0.0
		p.schicht[j] = 0.0


## Stirn an der Lippe einer Lücke (`Kanten.profil_stirn` mit der Wegmaske):
## unter der Narbe dunkel, bis auf den Grund.
static func _profil_stirn(_i: int, probe: Dictionary, level: Level05, kante: float,
		grund: float, halb: float, erdig: bool) -> GelaendeSaum.Profil:
	var p := Kanten.profil_stirn(probe, kante, grund, halb, erdig, 0.45, level.weg)
	for j in range(6, p.anzahl()):
		var c := p.farbe[j]
		c.r *= DUNKEL
		p.farbe[j] = c
	return p


## Setzstufe einer Treppe oder Kante des Suhlgrabens (12 bzw. 13 Punkte):
## Narbe nach der Wegmaske (auf der Spur Erde), angestrahlte Lösswand,
## darunter der Fuß in die untere Decke – am Graben eine Schlammsohle bis
## `weit` in den Graben (seine Mitte: dort trifft sie die Sohle der anderen
## Kante; die Decke zeichnet dort nichts, siehe `Level05.wegdecke_thema`).
static func _profil_stufe(_i: int, probe: Dictionary, level: Level05, oben: float,
		unten: float, weit: float, graben: bool) -> GelaendeSaum.Profil:
	var bogen: float = probe["bogen"]
	var r := Kanten.rasen_anteil(level.weg, probe)
	var ov := lerpf(0.04 + 0.12 * (0.5 + 0.5 * Kanten.welle(bogen * 1.7, 23.0)),
			Kanten.ueberhang_quer(bogen, 14.0) * 0.7, r)
	var h := oben - unten
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, oben - 0.03, Kanten.farbe(0.78, (1.0 - r) * 0.8, 0.05, r))
	p.punkt(ov * 0.4, oben - 0.006, Kanten.farbe(lerpf(0.68, 0.78, r), (1.0 - r) * 0.85,
			0.2 * r, r))
	p.punkt(ov * 0.8, oben - 0.035, Kanten.farbe(lerpf(0.6, 0.72, r), lerpf(0.9, 0.1, r),
			0.3 * r, 0.95 * r))
	p.punkt(ov, oben - lerpf(0.12, 0.1, r), Kanten.farbe(0.55, lerpf(0.95, 0.6, r), 0.3 * r,
			0.45 * r))
	p.punkt(ov - 0.06, oben - 0.2, Kanten.farbe(0.5, 1.0, 0.1, 0.0))
	p.punkt(-0.2, oben - minf(0.32, h * 0.45), Kanten.farbe(0.62, 1.0, 0.05, 0.0), 0.0, 0.04,
			-1.0)
	# Die Setzstufe zeigt zur Sonne und zur Kamera: hell, kaum Moos.
	p.punkt(-0.26, lerpf(oben, unten, 0.6), Kanten.farbe(0.86, 1.0, 0.08, 0.0), 0.0, 0.1, -1.0,
			0.05)
	p.punkt(-0.22, unten + 0.06, Kanten.farbe(0.74, 0.9, 0.25, 0.0), 0.0, 0.05, -1.0)
	if graben:
		# Schlammsohle der Suhle: nass, moosig, eben bis zur Mitte.
		p.punkt(-0.1, unten - 0.02, Kanten.farbe(0.55, 1.0, 0.5, 0.1))
		p.punkt(0.4, unten - 0.03, Kanten.farbe(0.5, 1.0, 0.55, 0.05))
		p.punkt(weit * 0.6, unten - 0.035, Kanten.farbe(0.48, 1.0, 0.6, 0.0))
		p.punkt(weit, unten - 0.04, Kanten.farbe(0.48, 1.0, 0.6, 0.0))
	else:
		p.punkt(-0.1, unten - 0.015, Kanten.farbe(0.66, 0.3, 0.3, 0.4))
		p.punkt(0.3, unten - 0.03, Kanten.farbe(0.78, 0.0, 0.1, 0.9))
		p.punkt(weit, unten - 0.035, Kanten.farbe(0.78, 0.0, 0.05, 1.0))
	return p


# ================================================================ Querlinien

## Die Linien quer über den Weg: je Lücke zwei Stirnen, je Stufe der Decke
## eine Setzstufe. Jede reicht von Fuß zu Fuß der Seiten (bzw. bis hinter die
## Lippe eines Ufers), damit die Ecken mit den Wänden der Seiten schließen.
static func _querlinien(level: Level05) -> Array:
	var weg := level.weg
	var linien: Array = []
	var nummer := 0
	for l: Dictionary in Level05.LUECKEN:
		var von: float = l["von"]
		var bis: float = l["bis"]
		var halb := (bis - von) * 0.5
		var grund: float = l["grund_y"]
		var erdig: bool = l["erdig"]
		for ende in 2:
			var s := von if ende == 0 else bis
			var vorwaerts := 1.0 if ende == 0 else -1.0
			var kante := weg.boden_bei(s - 0.01 * vorwaerts)
			linien.append(_querlinie(level, s, -vorwaerts,
					_profil_stirn.bind(level, kante, grund, halb, erdig), kante, 5201 + nummer))
			nummer += 1
	# Stufen der Decke (Graben, Treppen; die Absätze haben Rampen).
	for st: Vector3 in _stufen(weg):
		var naht := st.x
		var h_a := st.y
		var h_b := st.z
		# Die untere Decke liegt vorn (+s) oder hinten; dorthin zeigt die Wand.
		var vorwaerts := 1.0 if h_a > h_b else -1.0
		var graben := naht > Level05.SUHLGRABEN.x - 0.01 and naht < Level05.SUHLGRABEN.y + 0.01
		var weit := (Level05.SUHLGRABEN.y - Level05.SUHLGRABEN.x) * 0.5 + 0.05 if graben else 0.6
		linien.append(_querlinie(level, naht, -vorwaerts,
				_profil_stufe.bind(level, maxf(h_a, h_b), minf(h_a, h_b), weit, graben),
				maxf(h_a, h_b), 5301 + nummer))
		nummer += 1
	return linien


## Die Stufen der Decke als Vector3(Naht, Höhe davor, Höhe dahinter): wo zwei
## Abschnitte bündig aneinanderstoßen, aber nicht gleich hoch.
static func _stufen(weg: Wegdaten) -> Array[Vector3]:
	var stufen: Array[Vector3] = []
	for i in range(1, weg.abschnitte.size()):
		var a: Dictionary = weg.abschnitte[i - 1]
		var b: Dictionary = weg.abschnitte[i]
		var naht: float = b["von"]
		if absf(float(a["bis"]) - naht) > 0.01:
			continue
		var h_a := LevelWerkzeuge.eintrag_hoehe(weg.verlauf, a, naht)
		var h_b := LevelWerkzeuge.eintrag_hoehe(weg.verlauf, b, naht)
		if absf(h_a - h_b) >= 0.05:
			stufen.append(Vector3(naht, h_a, h_b))
	return stufen


## Eine Querlinie an `s` von Seite zu Seite.
static func _querlinie(level: Level05, s: float, seite: float, profil: Callable, kante: float,
		saat: int) -> Dictionary:
	var links := _quer_ende(level, -1.0, s)
	var rechts := _quer_ende(level, 1.0, s)
	return {"seite": seite, "linie": PackedVector2Array([Vector2(s, links), Vector2(s, rechts)]),
			"profil": profil, "gruppe": "Stirnen und Stufen", "schritt": SCHRITT_QUER,
			"karten": true, "karten_maske": true, "saat": saat,
			"kante": func(_s: float) -> float: return kante}


## Wo eine Querlinie an der Seite `seite` endet: am Fuß einer Böschung knapp
## in der Wand, an einem Ufer hinter dessen Lippe.
static func _quer_ende(level: Level05, seite: float, s: float) -> float:
	var q := Level05.leitlinie_q(Level05.leitlinie_punkte(seite), s)
	for zug: Dictionary in level.zuege_bei(seite, s):
		if String(zug["art"]) == "ab":
			return q + seite * 0.55
	return q + seite * 0.1
