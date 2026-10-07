extends RefCounted
class_name Kanten
## Kanten am Weg als Querschnitt-Sweeps: Profile und Bauschritte für
## `GelaendeSaum`, ohne Bezug auf Level 01 (Baukasten Raum 1, Paket G3;
## Herkunft scenes/levels/level01/saum.gd, `L01Saum`).
##
## WARUM EINE KOPIE. `L01Saum` baut die Kanten von Level 01 aus dessen
## Konstanten (Becken, Platten, Kanzel, feste Strecken) und hält seinen
## Bau in statischen Merkern. Die Level 02–05 brauchen dieselben Profile
## (Grasnarbe mit Überhang über Schichtfels, Erdufer, Böschung, Stirn einer
## Lücke) und denselben Rahmen (Stücke zu 30 m mit Fernfassung, Wurzel- und
## Halmkarten unter der Narbe), aber mit eigenen Daten. Die Profile stehen
## hier deshalb ein zweites Mal, Rechenweg und Reihenfolge wörtlich: Mit
## den Werten von Level 01 liefern sie bis aufs Bit dieselben Punkte
## (`werkzeuge/baukastenprobe.gd`, Teil G3). Was in saum.gd eine Funktion
## von Level 01 war (die Platten unter der Kanzel, das Becken unter dem
## Pfeiler), kommt als Callable herein; ohne Callable gilt 0.
##
## PROFILE (je Querschnitt ein `GelaendeSaum.Profil`):
##   profil_ab         Lippe über offenem Abgrund: Grasnarbe, Überhang,
##                     Schichtfels mit zwei Simsen, Fuß (30 Punkte, :718)
##   profil_ufer       Grasnarbe, Erdufer, nasser Fuß (30 Punkte, :827) –
##                     mischbar mit `profil_ab` (`Profil.gemischt`)
##   profil_boeschung  Erdhang neben dem Weg bis zur Krone (26 Punkte, :1306)
##   profil_wand       Schichtfelswand mit Simsen und Überhang (26, :1349) –
##                     mischbar mit `profil_boeschung`
##   profil_stirn      Stirn einer Lücke quer zum Weg bis auf ihren Grund
##                     (16 Punkte, :1792); mit `weg` folgt die Narbe der
##                     Wegmaske (ausgetretene Spur bricht krümelig ab)
##   in_luecke         senkt ein Profil auf den Grund einer Lücke (Kerbtal
##                     oder Rinne, :685) – sonst zöge die Narbe einer Seite
##                     als Streifen über die Lücke
## Dazu die Helfer, aus denen die Profile ihre Wellen nehmen (`welle`,
## `kluft`, `ueberhang_lippe`, `ueberhang_quer`, `farbe`).
##
## BAU. `seite_schritte()` liefert die Bauschritte einer Kante entlang einer
## Linie in (s, q): vermessen (Proben, Querschnitte, Normalen), dann bauen
## (Gitter in Stücke, Deckel an den Enden, Karten, Fernfassung). Mit
## `speicher` landen Netze und Querschnitte im `Bauspeicher`; beim nächsten
## Laden (gleicher Code) wird daraus EIN Schritt, der nur einhängt. Der
## Zustand gehört dem Aufruf (Baukasten §0 Nr. 3): Keine statischen Merker
## wie `L01Saum._bau` oder `GelaendeSaum._flaechen` – die gebauten
## Querschnitte stehen, wer sie braucht (Wasserfälle, Gelände), im
## Wörterbuch `optionen["stand"]` unter "flaeche" und lassen sich mit
## `flaeche_punkt()` abfragen.
##
## KOLLISION baut auch dieser Rahmen keine: Die Linie IST die Kollisions-
## kante, über sie hinaus ragt nur Gras.

## Länge eines Stücks (m) und Abstand der Querschnitte entlang der Linie.
const STUECK := 30.0
const SCHRITT := 0.7
## Sichtweiten (m, vom Kameraort zur Mitte eines Stücks) und ab wann die
## grobe Fernfassung zeichnet (wie saum.gd:131-137).
const SICHT := 260.0
const SICHT_KARTEN := 55.0
const SICHT_RAND := 6.0
const FERN_AB := 85.0
## So weit neben einer Stufe oder Lückenkante steht je ein Querschnitt.
const EPS := 0.005
## Glättung und Rauschen der Narbenpunkte 0–7 (`profil_ab`).
const GLATT_NARBE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.5]
const RAUSCHEN_NARBE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.15]
## Krone hinter der Kante: Abstand und Anstieg der Punkte 20–25 (Böschung
## und Felswand).
const KRONE_WEITE_B: Array[float] = [0.0, 0.9, 2.0, 3.3, 5.0, 7.5]
const KRONE_HOCH_B: Array[float] = [0.0, 0.08, 0.2, 0.35, 0.6, 1.1]
const KRONE_WEITE_W: Array[float] = [0.8, 1.8, 3.0, 4.5, 6.0, 7.5]
const KRONE_HOCH_W: Array[float] = [0.05, 0.15, 0.25, 0.4, 0.5, 0.6]
## Töne der Karten unter der Narbe (Halme, Wurzeln) – im Schnee andere.
const HALM_TON := Color(0.28, 0.4, 0.12)
const WURZEL_TON := Color(0.42, 0.32, 0.23)


# ================================================================ Stoff

## Der Stoff der Kanten für ein Thema (`GelaendeSaum.stoff_variante`): mit
## leerem Thema derselbe wie `GelaendeSaum.stoff()`, aber ein eigenes
## Objekt.
static func stoff(thema: Dictionary) -> ShaderMaterial:
	return GelaendeSaum.stoff_variante(thema)


# ================================================================ Helfer

## Scheitelfarbe im Format des Stoffs: Verdeckung, Erde, Moos, Rasen.
static func farbe(ao: float, erde: float, moos: float, rasen: float) -> Color:
	return Color(ao, erde, moos, rasen)


## 1D-Welle aus dem Rauschen der Felsen (saum.gd:488).
static func welle(x: float, versatz: float) -> float:
	return GelaendeSaum.rauschen().get_noise_1d(x + versatz * 37.0)


## Senkrechte Klüfte (0..1, 1 in der Kluft): alle 7–12 m eine, gut einen
## Meter breit (saum.gd:495).
static func kluft(bogen: float, versatz: float) -> float:
	var phase := bogen * PI / 9.5 + 1.3 * welle(bogen * 0.05, versatz)
	return smoothstep(0.86, 0.985, absf(sin(phase)))


## Überhang der Grasnarbe an einer Lippe längs des Weges (m): 0,1–0,33,
## nur nach außen (saum.gd:646).
static func ueberhang_lippe(bogen: float) -> float:
	return clampf(0.2 + 0.1 * welle(bogen * 0.9, 1.0) + 0.07 * welle(bogen * 2.7, 2.0),
			0.1, 0.33)


## Überhang der Grasnarbe an Stirnflächen und Stufen (m): 0,15–0,35, in
## Buckeln von 2–3 m (saum.gd:502).
static func ueberhang_quer(bogen: float, versatz: float) -> float:
	return clampf(0.25 + 0.11 * welle(bogen * 0.4, versatz)
			+ 0.05 * welle(bogen * 1.3, versatz + 5.0), 0.15, 0.35)


## Rasen (1) oder ausgetretene Spur (0) an einer Probe einer Linie quer
## über den Weg, nach der Wegmaske der Decke (saum.gd:1752): Dieselbe Maske
## malt die Decke, so läuft die Spur über die Lippe weiter.
static func rasen_anteil(weg: Wegdaten, probe: Dictionary) -> float:
	var s: float = probe["s"]
	var halb := maxf(weg.breite_bei(s - 0.05), weg.breite_bei(s + 0.05)) * 0.5
	if halb <= 0.0:
		return 1.0
	var p: Vector3 = probe["p"]
	return Wegmaske.wert(float(probe["q"]) / halb, s, Vector2(p.x, p.z))


# ================================================================ Profile

## FELS_AB: Grasnarbe, Überhang, Schichtfels mit zwei Simsen, Fuß
## (30 Punkte; saum.gd:718-817). Die Lippe liegt an der Linie (Versatz 0),
## die oberen gut sechs Meter UNTER ihr (0,45–0,5 m zurück, Rauschen nur
## nach innen): Wer über die Kante fällt, fällt an der Wand vorbei.
##   s, bogen      Strecke und Bogenlänge der Probe
##   q_lippe       q der Linie (wie im Original ohne Wirkung, für Aufrufer
##                 mit eigener Fassung)
##   kante_y       Welt-Y der Decke an der Lippe, `fuss_y` Fuß der Wand
##   ueberhang     Überhang der Narbe (`ueberhang_lippe`)
##   platte        Callable(s) -> 0..1: Anteil einer Felsplatte über der
##                 Kante (Level 01: Geländer und Kanzel); leer = 0
##   ecke          Callable(s) -> 0..1: Anteil einer Ecke ohne Decke an der
##                 Lippe, dort reicht die Narbe 1,8 m zurück; leer = 0
static func profil_ab(s: float, bogen: float, _q_lippe: float, kante_y: float,
		fuss_y: float, ueberhang: float, platte_bei: Callable = Callable(),
		ecke_bei: Callable = Callable()) -> GelaendeSaum.Profil:
	var kante := kante_y
	var ov := ueberhang
	var h := maxf(kante - fuss_y, 6.0)
	var platte: float = platte_bei.call(s) if platte_bei.is_valid() else 0.0
	# Simse: Tiefe und Breite wandern langsam entlang der Kante.
	var d1 := clampf(8.2 + 1.1 * welle(bogen * 0.07, 3.0), 7.2, h * 0.55)
	var d2 := clampf(d1 + 4.6 + 1.0 * welle(bogen * 0.06, 5.0), d1 + 2.4, maxf(h - 2.2, d1 + 2.4))
	# Die Simse setzen aus (3–8 m), und jede Kluft schneidet sie ab.
	var kl_ := kluft(bogen, 31.0)
	var da1 := smoothstep(-0.3, 0.25, welle(bogen * 0.072, 21.0))
	var da2 := smoothstep(-0.3, 0.25, welle(bogen * 0.08, 22.0))
	var w1 := (0.5 + 0.45 * (1.0 + welle(bogen * 0.11, 4.0))) * lerpf(0.06, 1.0, da1) \
			* (1.0 - kl_)
	var w2 := (0.45 + 0.45 * (1.0 + welle(bogen * 0.09, 6.0))) * lerpf(0.06, 1.0, da2) \
			* (1.0 - kl_)
	# Zwischen den Klüften treten Pfeiler vor (nur unterhalb des Überhangs).
	var pfeiler := 0.65 * (1.0 - kl_)
	d2 = maxf(d2, d1 + 2.4)
	var u_ende := minf(6.4, d1 - 1.3)
	var p := GelaendeSaum.Profil.new()
	var ecke: float = ecke_bei.call(s) if ecke_bei.is_valid() else 0.0
	# --- Grasnarbe (0–5) oder Platte
	var narbe: Array = [
		[lerpf(-0.45, -1.8, ecke), lerpf(-0.03, -0.05, ecke),
				farbe(0.78, 0.0, 0.05, 1.0).lerp(farbe(0.62, 0.35, 0.55, 0.45), ecke)],
		[ov * 0.4, -0.006, farbe(0.78, 0.0, 0.2, 1.0)],
		[ov * 0.8, -0.035, farbe(0.72, 0.1, 0.3, 0.95)],
		[ov, -0.12, farbe(0.5, 0.6, 0.3, 0.45)],
		[ov - 0.06, -0.25, farbe(0.3, 1.0, 0.1, 0.0)],
		[ov - 0.32, -0.33, farbe(0.18, 1.0, 0.0, 0.0)],
		[-0.35, -0.48, farbe(0.2, 1.0, 0.0, 0.0)],
		[-0.5, -0.9, farbe(0.27, 0.75, 0.1, 0.0)],
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
			f = f.lerp(farbe(0.5, 0.1, 0.15, 0.0), platte)
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
		p.punkt(o, kante - d, farbe(lerpf(0.36, 0.68, t), lerpf(0.3, 0.0, t), 0.2, 0.0),
				0.8, 0.35, -1.0, 0.12)
	# --- Wand zum ersten Sims (14–17); in einer Kluft dunkler
	var d14 := maxf(u_bis + 0.6, d1 - 1.0)
	var kl := 1.0 - 0.35 * kl_
	p.punkt(_ab_o(d14, u_ende) + pfeiler * 0.5, kante - d14, farbe(0.72 * kl, 0.0, 0.2, 0.0),
			1.2, 0.8, 1.0, 0.18)
	p.punkt(_ab_o(d1, u_ende) - 0.05 + pfeiler, kante - (d1 - 0.12),
			farbe(0.5 * kl, 0.2, 0.45, 0.0), 1.6, 0.5)
	p.punkt(_ab_o(d1, u_ende) + w1 * 0.85 + pfeiler, kante - (d1 - 0.02),
			farbe(0.9 * kl, 0.3, 0.9 * da1, 0.0), 1.6, 0.4)
	p.punkt(_ab_o(d1, u_ende) + w1 + pfeiler, kante - (d1 + 0.4), farbe(0.8 * kl, 0.1, 0.35, 0.0),
			1.8, 0.5)
	# --- Wand zum zweiten Sims (18–21)
	var dm := (d1 + 0.4 + d2 - 0.12) * 0.5
	p.punkt(_ab_o(dm, u_ende) + w1 + pfeiler, kante - dm, farbe(0.76 * kl, 0.0, 0.2, 0.0),
			2.0, 1.1, 1.0, 0.18)
	p.punkt(_ab_o(d2, u_ende) + w1 - 0.05 + pfeiler, kante - (d2 - 0.12),
			farbe(0.52 * kl, 0.2, 0.45, 0.0), 2.5, 0.5)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2 * 0.85 + pfeiler, kante - (d2 - 0.02),
			farbe(0.88 * kl, 0.3, 0.9 * da2, 0.0), 2.5, 0.4)
	p.punkt(_ab_o(d2, u_ende) + w1 + w2 + pfeiler, kante - (d2 + 0.4),
			farbe(0.78 * kl, 0.1, 0.35, 0.0), 2.8, 0.5)
	# --- Unterer Teil bis zum Fuß (22–26)
	for k in 5:
		var t := float(k + 1) / 6.0
		var d := lerpf(d2 + 0.4, h - 0.2, t)
		p.punkt(_ab_o(d, u_ende) + w1 + w2 + 0.25 * t + pfeiler, kante - d,
				farbe(lerpf(0.74, 0.6, t) * kl, 0.0, 0.2, 0.0), lerpf(3.0, 4.5, t), 1.2, 1.0, 0.18)
	# --- Fuß und darunter (27–29): Das Gelände liegt unter der Wand.
	var of := _ab_o(h, u_ende) + w1 + w2 + 0.5 + pfeiler
	p.punkt(of, fuss_y, farbe(0.55, 0.45, 0.35, 0.0), 5.0, 0.8)
	p.punkt(of + 1.3, fuss_y - 1.0, farbe(0.5, 0.7, 0.3, 0.0), 5.0, 0.6)
	p.punkt(of + 2.0, fuss_y - 3.0, farbe(0.45, 0.8, 0.2, 0.0), 5.0, 0.4)
	return p


## Versatz der Felswand von `profil_ab` in der Tiefe `d` unter der Kante:
## bis zum Ende des Überhangs 0,5 m hinter der Lippe, darunter 80°.
static func _ab_o(d: float, u_ende: float) -> float:
	return -0.5 + 0.18 * maxf(d - u_ende, 0.0)


## UFER: Grasnarbe, Erdufer mit Moos, nasser Fuß (30 Punkte wie FELS_AB,
## also mischbar; saum.gd:827-853). Die ersten 1,4 m unter 45°, dann 68°.
static func profil_ufer(bogen: float, kante_y: float, fuss_y: float,
		ueberhang: float) -> GelaendeSaum.Profil:
	var kante := kante_y
	var ov := ueberhang
	var h := maxf(kante - fuss_y, 1.5)
	var p := GelaendeSaum.Profil.new()
	p.punkt(-0.45, kante - 0.03, farbe(0.78, 0.0, 0.05, 1.0))
	p.punkt(ov * 0.4, kante - 0.006, farbe(0.78, 0.0, 0.2, 1.0))
	p.punkt(ov * 0.8, kante - 0.035, farbe(0.72, 0.15, 0.3, 0.95))
	p.punkt(ov, kante - 0.12, farbe(0.5, 0.7, 0.3, 0.4))
	p.punkt(ov - 0.06, kante - 0.25, farbe(0.3, 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3, kante - 0.33, farbe(0.2, 1.0, 0.0, 0.0))
	p.punkt(-0.2, kante - 0.48, farbe(0.24, 1.0, 0.05, 0.0), 0.3, 0.05, -1.0)
	p.punkt(-0.15, kante - 0.9, farbe(0.32, 0.9, 0.2, 0.0), 0.5, 0.1, -1.0)
	# Ufer (8–24): oben 45°, dann 60–70°, Erde mit Moos, nach unten nasser.
	for k in 17:
		var t := float(k + 1) / 18.0
		var d := lerpf(0.9, h - 0.4, t)
		var bauch := 0.25 * sin(t * PI) * (1.0 + welle(bogen * 0.2, 7.0))
		p.punkt(_ufer_o(d) + bauch, kante - d,
				farbe(lerpf(0.74, 0.55, t), lerpf(0.7, 0.5, t), lerpf(0.8, 0.5, t),
				0.45 * (1.0 - t)), lerpf(0.8, 2.5, t), 0.35, 1.0, 0.1)
	var of := _ufer_o(h - 0.4) + 0.3
	p.punkt(of, fuss_y + 0.4, farbe(0.42, 0.6, 0.5, 0.0), 2.5, 0.2)
	p.punkt(of + 0.4, fuss_y, farbe(0.38, 0.7, 0.4, 0.0), 3.0, 0.2)
	p.punkt(of + 1.2, fuss_y - 0.5, farbe(0.36, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.0, fuss_y - 1.5, farbe(0.34, 0.8, 0.3, 0.0), 3.0, 0.2)
	p.punkt(of + 2.6, fuss_y - 3.0, farbe(0.32, 0.8, 0.3, 0.0), 3.0, 0.2)
	return p


## Versatz des Ufers in der Tiefe `d`: die ersten 1,4 m unter 45°, dann 68°.
static func _ufer_o(d: float) -> float:
	return -0.1 + minf(d - 0.9, 1.4) * 1.0 + maxf(d - 2.3, 0.0) * 0.4


## BOESCHUNG: Rasen bis an den Fuß, ein Erdhang als Kosinus-S (am
## steilsten gut 50°), oben die Krone, die 7,5 m flach ausläuft (26 Punkte;
## saum.gd:1306-1344). Punkt 0 liegt absolut unter der Decke (q =
## −(wegrand − 0,35)): Die Kante liegt links des Weges.
##   q_linie   |q| der Fußlinie, `wegrand` halbe Wegbreite
##   krone_y   Welt-Y der Kronenkante, `rinne` 0..1: ein Graben, der den
##             Hang herabkommt (vor und hinter einer Lücke)
static func profil_boeschung(bogen: float, q_linie: float, kante_y: float,
		wegrand: float, krone_y: float, rinne: float) -> GelaendeSaum.Profil:
	var kante := kante_y
	var krone := krone_y
	var h := maxf(krone - kante, 0.12)
	var voll := smoothstep(0.5, 3.5, h)
	var breite := maxf(lerpf(3.0, 11.0 - q_linie, voll), 2.6 + h * 0.55)
	# Die Breite wandert um ±22 %, und alle 15–25 m tritt ein Sporn vor
	# oder weicht eine Rinne zurück.
	breite *= 1.0 + 0.22 * welle(bogen * 0.035, 42.0) * voll
	var sporn := 1.1 * welle(bogen * 0.055, 43.0) * voll
	var p := GelaendeSaum.Profil.new()
	p.punkt(-(wegrand - 0.35), kante - 0.03, farbe(0.78, 0.0, 0.05, 1.0), 0.0, 0.0, 1.0, 0.0, true)
	p.punkt(-0.22, kante - 0.015, farbe(0.78, 0.05, 0.2, 1.0))
	p.punkt(0.05, kante + 0.02, farbe(0.74, 0.2, 0.45, 0.85), 0.4, 0.05, 2.0)
	p.punkt(0.3, kante + 0.12, farbe(0.7, 0.35, 0.5, 0.7), 0.6, 0.12, 2.0)
	for k in 16:
		var t := float(k + 1) / 16.0
		var f := 0.5 - 0.5 * cos(PI * t)
		var steil := sin(PI * t)
		# Buckel und Mulden entlang des Hangs.
		var buckel := 0.35 * welle(bogen * 0.3 + t * 2.6, 8.0)
		# Rasen und Moos, wo es flacher ist; Erde bricht in Flecken durch.
		var gras := clampf(0.85 - 0.5 * steil + 0.55 * welle(bogen * 0.26 + t * 2.1, 16.0),
				0.0, 1.0)
		var erde := clampf(0.2 + 0.65 * steil - 0.35 * gras, 0.08, 0.9)
		var y := kante + 0.12 + (h - 0.12) * f
		y -= 1.2 * rinne * smoothstep(0.05, 0.3, t) * (1.0 - smoothstep(0.75, 1.0, t))
		p.punkt(0.3 + (breite - 0.3) * t + buckel + sporn * smoothstep(0.25, 0.75, t), y,
				farbe(lerpf(0.7, 0.86, t) * lerpf(1.0, 0.88, steil) * lerpf(1.0, 0.9, rinne),
				lerpf(erde, 0.8, rinne * 0.6), 0.6, gras * (1.0 - rinne * 0.6)),
				lerpf(0.8, 2.5, t), lerpf(0.3, 0.4, t), 1.0 if t > 0.25 else 2.0)
	# Kronenkante und Krone (20–25)
	var k0 := breite + sporn
	for k in 6:
		var weiter: float = KRONE_WEITE_B[k]
		var hoch: float = KRONE_HOCH_B[k] * voll
		p.punkt(k0 + weiter, krone + hoch, farbe(0.78, 0.3, 0.75, lerpf(0.85, 0.6, float(k) / 5.0)),
				maxf(2.5, k0 + weiter), 0.3)
	return p


## FELS_AUF: Schichtfelswand mit zwei Simsen und einem Überhang, der erst
## ab 10 m über dem Weg vortritt (26 Punkte wie BOESCHUNG; saum.gd:1349-
## 1431). Optional ein Becken vor der Wand, in dem sie auf dessen Grund
## steht, und ein Pfeiler, der die Krone erhöht (Level 01: Wasserfall):
##   becken    Callable(s) -> 0..1, Anteil des Beckens; `becken_y` sein Grund
##   pfeiler   Callable(s) -> 0..1, Anteil des Pfeilers; `pfeiler_hoehe` (m)
## Ohne Callable gilt 0.
static func profil_wand(s: float, bogen: float, q_linie: float, kante_y: float,
		wegrand: float, krone_y: float, becken_bei: Callable = Callable(),
		becken_y: float = 0.0, pfeiler_bei: Callable = Callable(),
		pfeiler_hoehe: float = 0.0) -> GelaendeSaum.Profil:
	var kante := kante_y
	var krone := krone_y
	var becken: float = becken_bei.call(s) if becken_bei.is_valid() else 0.0
	var pfeiler: float = pfeiler_bei.call(s) if pfeiler_bei.is_valid() else 0.0
	var fuss_y := lerpf(kante, becken_y, becken)
	var h := maxf(krone - fuss_y, 0.6)
	var ueber_weg := krone - kante
	var p := GelaendeSaum.Profil.new()
	p.punkt(-(wegrand - 0.35), lerpf(kante - 0.03, becken_y - 0.03, becken),
			farbe(0.78, 0.0, 0.05, 1.0 - becken).lerp(farbe(0.35, 0.4, 0.2, 0.0), becken),
			0.0, 0.0, 1.0, 0.0, true)
	p.punkt(-0.25, lerpf(kante - 0.015, becken_y, becken),
			farbe(0.76, 0.1, 0.25, 1.0).lerp(farbe(0.42, 0.45, 0.3, 0.0), becken))
	p.punkt(0.0, fuss_y + 0.04, farbe(0.6, 0.55, 0.5, 0.3 * (1.0 - becken)), 0.4, 0.05, 2.0)
	p.punkt(0.12, fuss_y + 0.35, farbe(0.55, 0.25, 0.35, 0.0), 0.6, 0.15, 2.0, 0.15)
	# Simse und Überhang, sanft eingeblendet, damit benachbarte Querschnitte
	# gleich gebaut sind.
	var ka := smoothstep(5.5, 8.0, h)
	var kb := smoothstep(9.0, 11.5, h)
	var ha := clampf(4.2 + 0.8 * welle(bogen * 0.09, 9.0), 0.4, 0.38 * h)
	var hb := clampf(ha + 4.4 + 0.8 * welle(bogen * 0.08, 10.0), ha + 0.6, 0.66 * h)
	# Senkrechte Klüfte schneiden die Simse ab und treten 0,8 m zurück.
	var kluft_ := kluft(bogen, 32.0) * smoothstep(4.0, 6.5, h) * (1.0 - pfeiler)
	var zurueck := 0.8 * kluft_
	# Die Simse setzen aus (Stücke von 3–8 m)
	var da := smoothstep(-0.35, 0.2, welle(bogen * 0.075, 33.0))
	var db := smoothstep(-0.35, 0.2, welle(bogen * 0.085, 34.0))
	var wa := (0.5 + 0.35 * (1.0 + welle(bogen * 0.12, 11.0))) * ka * (1.0 - 0.7 * becken) \
			* (1.0 - kluft_) * lerpf(0.15, 1.0, da)
	var wb := (0.45 + 0.35 * (1.0 + welle(bogen * 0.1, 12.0))) * kb * (1.0 - 0.7 * becken) \
			* (1.0 - kluft_) * lerpf(0.15, 1.0, db)
	var zone := minf(2.4, 0.3 * h)
	var oben := h - zone
	# Überhang nur ab 10 m über dem Weg, höchstens so weit, dass die Kante
	# nicht näher als 2,8 m an die Wegmitte kommt.
	var ovd := 1.4 * smoothstep(10.2, 12.0, h) * smoothstep(10.0, 11.0, ueber_weg - zone)
	ovd = minf(ovd, q_linie + _wand_o(oben) + wa + wb - 2.8)
	ovd = maxf(ovd, 0.0)
	var kl := 1.0 - 0.35 * kluft_
	var wand := farbe(0.72 * kl, 0.0, 0.22, 0.0)
	var ecke := farbe(0.5 * kl, 0.15, 0.5, 0.0)
	var sims := farbe(0.9 * kl, 0.3, 1.0, 0.0)
	var zr := zurueck
	# 4–7: bis zum ersten Sims
	p.punkt(_wand_o(ha * 0.5) + zr * 0.5, fuss_y + ha * 0.5, wand, 1.0, 0.5, 2.0, 0.16)
	p.punkt(_wand_o(ha) - 0.03 + zr, fuss_y + ha - 0.12 * ka, ecke, 1.4, 0.35, 2.0)
	p.punkt(_wand_o(ha) + wa * 0.85 + zr, fuss_y + ha, sims.lerp(wand, 1.0 - ka), 1.6, 0.25, 2.0)
	p.punkt(_wand_o(ha) + wa + zr, fuss_y + ha + 0.35 * ka, farbe(0.8 * kl, 0.1, 0.5, 0.0), 1.6,
			0.3, 2.0)
	# 8–11: zum zweiten Sims
	var hm := (ha + 0.35 * ka + hb - 0.12 * kb) * 0.5
	p.punkt(_wand_o(hm) + wa + zr, fuss_y + hm, wand, 1.8, 0.55, 2.0, 0.16)
	p.punkt(_wand_o(hb) + wa - 0.03 + zr, fuss_y + hb - 0.12 * kb, ecke, 2.0, 0.35, 2.0)
	p.punkt(_wand_o(hb) + wa + wb * 0.85 + zr, fuss_y + hb, sims.lerp(wand, 1.0 - kb), 2.2, 0.25,
			2.0)
	p.punkt(_wand_o(hb) + wa + wb + zr, fuss_y + hb + 0.35 * kb, farbe(0.8 * kl, 0.1, 0.5, 0.0),
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
	var dunkel := farbe(0.34, 0.1, 0.0, 0.0)
	p.punkt(fo - 0.3 * ovd, fuss_y + h - zone * 0.7, wand.lerp(dunkel, minf(ovd, 1.0)), 2.4, 0.4, 2.0)
	p.punkt(fo - 0.85 * ovd, fuss_y + h - zone * 0.44, wand.lerp(dunkel, minf(ovd, 1.0) * 0.8),
			2.4, 0.35)
	p.punkt(fo - ovd, fuss_y + h - zone * 0.2, wand, 2.4, 0.3)
	p.punkt(fo - 0.9 * ovd, fuss_y + h - zone * 0.06, farbe(0.8, 0.1, 0.6, 0.1), 2.4, 0.25)
	p.punkt(fo - 0.6 * ovd, fuss_y + h, farbe(0.82, 0.25, 0.8, 0.3), 2.4, 0.2)
	# 20–25: Kronenkante und Krone. Hinter einem Pfeiler fällt die Krone
	# wieder auf die Höhe der Wand ab: ein Felsturm, kein Tafelberg.
	var turm := pfeiler * pfeiler_hoehe
	for k in 6:
		var weiter: float = KRONE_WEITE_W[k]
		var hoch: float = KRONE_HOCH_W[k] - turm * smoothstep(0.5, 5.0, float(k)) * 0.9
		p.punkt(fo - 0.6 * ovd + weiter, fuss_y + h + hoch,
				farbe(0.78, 0.12, 0.8, lerpf(0.75, 0.55, float(k) / 5.0)),
				maxf(2.5, fo + weiter), 0.3 + 0.3 * pfeiler)
	return p


## Versatz der Felswand von `profil_wand` in der Höhe `hh` über dem Fuß:
## gut 2° nach hinten geneigt.
static func _wand_o(hh: float) -> float:
	return 0.12 + 0.035 * hh


## STIRN: Grasnarbe, Erdband, Wand bis auf den Grund, der Grund bis zur
## Mitte der Lücke (16 Punkte; saum.gd:1792-1834). Für eine Linie QUER über
## den Weg an der Lippe einer Lücke.
##   probe     aus `GelaendeSaum.linie` ("bogen", mit `weg` auch "s", "q", "p")
##   kante_y   Welt-Y der Decke an der Lippe, `grund_y` Grund der Lücke
##   halb      halbe Länge der Lücke (bis zur Mitte)
##   erdig     true = Erdwand (Erdspalt), sonst Fels
##   innen     so weit reicht die Narbe hinter die Lippe zurück
##   weg       gesetzt: Die Narbe folgt der Wegmaske – auf der Spur
##             krümelig abgebrochen (4–24 cm), daneben Rasen in Buckeln; in
##             einer flachen Lücke nasser Fels bis aufs Wasser. Mit gleich
##             breiter Narbe quer über den Weg las sich die Lippe als grüner
##             Bordstein (Level 01, Welle 6).
static func profil_stirn(probe: Dictionary, kante_y: float, grund_y: float, halb: float,
		erdig: bool, innen: float = 0.45, weg: Wegdaten = null) -> GelaendeSaum.Profil:
	var kante := kante_y
	var grund := grund_y
	var bogen: float = probe["bogen"]
	var ov := ueberhang_quer(bogen, 13.0)
	var r := 1.0
	if weg != null:
		r = rasen_anteil(weg, probe)
		ov = clampf(0.2 + 0.3 * welle(bogen * 0.9, 13.0) + 0.12 * welle(bogen * 2.3, 18.0),
				0.03, 0.4)
		# Auf der Spur: krümelig abgebrochen, 4–24 cm hinaus, fast jeder
		# Querschnitt anders.
		ov = lerpf(0.04 + 0.2 * (0.5 + 0.5 * welle(bogen * 1.7, 21.0)), ov, r)
	var e := 0.8 if erdig else 0.25
	var p := GelaendeSaum.Profil.new()
	p.punkt(-innen, kante - (0.03 if innen <= 0.45 else 0.05),
			farbe(0.78, (1.0 - r) * 0.8, 0.05, r))
	p.punkt(ov * 0.4, kante - 0.006, farbe(lerpf(0.66, 0.78, r), (1.0 - r) * 0.85, 0.2 * r, r))
	p.punkt(ov * 0.8, kante - lerpf(0.06, 0.035, r),
			farbe(lerpf(0.52, 0.72, r), lerpf(0.9, 0.1, r), 0.3 * r, 0.95 * r))
	p.punkt(ov, kante - lerpf(0.18, 0.12, r), farbe(0.5, lerpf(0.9, 0.6, r), 0.3 * r, 0.45 * r))
	# Flache Lücke (gut 2 m): Man sieht die Wand bis aufs Wasser, nasser,
	# bemooster Fels statt eines schwarzen Schlitzes.
	var tief := kante - grund
	var nass := (1.0 - smoothstep(2.6, 4.0, tief)) if weg != null else 0.0
	p.punkt(ov - 0.06, kante - 0.25, farbe(lerpf(0.3, 0.42, nass), 1.0, 0.1, 0.0))
	p.punkt(ov - 0.3, kante - 0.33, farbe(lerpf(0.18, 0.36, nass), 1.0, 0.0, 0.0))
	p.punkt(-0.35, kante - 0.5, farbe(lerpf(0.2, 0.38, nass), 1.0, 0.3 * nass, 0.0), 0.0,
			0.05, -1.0)
	p.punkt(-0.45, kante - 1.0, farbe(lerpf(0.26, 0.42, nass), lerpf(maxf(e, 0.7), 0.3, nass),
			lerpf(0.1, 0.45, nass), 0.0), 0.0, 0.15, -1.0)
	for k in 5:
		var t := float(k) / 4.0
		var y := kante - lerpf(1.9, tief - 0.3, t)
		p.punkt(-0.5 + 0.1 * t, y, farbe(lerpf(lerpf(0.3, 0.44, nass), lerpf(0.12, 0.3, nass), t),
				e, lerpf(0.15, 0.5, nass), 0.0), 0.0, 0.3, -1.0, 0.2 * (1.0 - e))
	p.punkt(-0.12, grund, farbe(0.1, 0.7, 0.2, 0.0))
	p.punkt(halb * 0.6, grund - 0.02, farbe(0.08, 0.8, 0.2, 0.0))
	p.punkt(halb + 0.05, grund - 0.05, farbe(0.08, 0.8, 0.2, 0.0))
	return p


## Senkt die Punkte `von`..`bis` eines Profils auf den Grund einer Lücke
## (höchstens `grund + anstieg · o`): So ist eine Kante an der Lücke
## ausgeschnitten, und zwischen dem letzten Querschnitt davor und dem
## ersten darin steht die Seitenwand der Lücke (saum.gd:685-714). `rand`
## (0 in der Mitte der Lücke, 1 an ihren Kanten): Am Hang wird zur Kante
## hin immer weniger ausgeschnitten – die Rinne ist ein V. `kerbtal`: Die
## Wand unter einer Lippe bleibt zu den Rändern hin ganz stehen, ihr Grund
## steigt nach draußen – ein Kerbtal statt eines Schlitzes.
static func in_luecke(p: GelaendeSaum.Profil, grund: float, von: int, bis: int,
		anstieg: float, rand: float = 0.0, kerbtal: bool = false) -> void:
	var o_max := -INF
	for j in range(von, bis + 1):
		var grenze := grund + maxf(p.o[j], 0.0) * anstieg
		var hang := smoothstep(0.3, 1.5, p.o[j]) if p.absolut[j] == 0 else 0.0
		if kerbtal:
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


# ================================================================ Bau

## Die Bauschritte einer Kante, je {"text", "tun"}.
##   eltern    Knoten, unter dem der Sammelknoten `name` entsteht
##   weg       Wegdaten: Höhe der Decke an jeder Probe (UV2.y, die Tiefe
##             unter der Wegkante), Lücken und Abschnittsgrenzen
##   seite     +1 rechts, −1 links: Die Normale der Linie zeigt vom Weg weg.
##             Für eine Linie QUER über den Weg an einer Lippe (Stirn):
##             −1, wenn die Lücke in +s liegt, sonst +1
##   linie_sq  die Linie als [Vector2(s, q)]
##   profil    Callable(i: int, probe: Dictionary) -> GelaendeSaum.Profil
##   stoff     Stoff der Netze (`Kanten.stoff(thema)`)
##   name      Name des Sammelknotens und der Stücke, Text der Schritte
##   speicher  Schlüssel im `Bauspeicher` ("" = nicht speichern); er muss
##             Level und Kante nennen (z. B. "l05_kante_rechts")
## `optionen` (alles freiwillig):
##   schritt        Abstand der Querschnitte (0,7 m)
##   feste_s        Strecken, an denen ein Querschnitt stehen MUSS
##                  (Vorgabe `feste_strecken(weg)`: Lückenränder, Stufen,
##                  Abschnittsanfänge)
##   kante          Callable(s) -> Welt-Y der Wegkante (Vorgabe boden_bei)
##   kronen         Callable(s) -> Kronenlicht 0..1 (Vorgabe 0)
##   deckel         Enden verschließen (true)
##   karten         Wurzel- und Halmkarten unter der Narbe (false; nur für
##                  Profile mit Narbe an den Punkten 0–5: ab, ufer, stirn)
##   karten_maske   nur wo die Wegmaske Rasen zeigt (false; für Stirnen)
##   saat           Zufall der Karten (8301)
##   halm_ton, wurzel_ton  Töne der Karten
##   sicht, fern_ab, sicht_karten, rand  Sichtweiten (wie Level 01)
##   stand          Wörterbuch, in das "flaeche" geschrieben wird (siehe
##                  `flaeche_punkt`) – auch, wenn aus dem Speicher geladen
static func seite_schritte(eltern: Node3D, weg: Wegdaten, seite: float,
		linie_sq: PackedVector2Array, profil: Callable, stoff: Material, name: String,
		speicher: String, optionen: Dictionary = {}) -> Array:
	var stand: Dictionary = optionen.get("stand", {})
	if not speicher.is_empty():
		var gesichert: Variant = Bauspeicher.gespeichert(speicher)
		if gesichert is Dictionary:
			var d: Dictionary = gesichert
			return [{"text": name + " wird geladen", "tun": func() -> void:
					_aus_speicher(eltern, name, stoff, d, stand)}]
	var bau := {}
	return [
		{"text": name + " wird vermessen", "tun": func() -> void:
			_vermessen(weg, seite, linie_sq, profil, optionen, bau)},
		{"text": name + " wird gebaut", "tun": func() -> void:
			_bauen(eltern, weg, name, stoff, speicher, optionen, bau, stand)},
	]


## Wie `seite_schritte`, aber für MEHRERE Linien in GEMEINSAMEN Stücken: Je
## 30 m entsteht ein Netz für alles, was dort steht (beide Seiten, Stirnen,
## Stufen), statt eines Knotens mit eigenen Stücken je Linie. WARUM: Ein Level
## mit zwei Seiten in je zwei Zügen und zwanzig Stirnen und Stufen (Level 05)
## käme mit `seite_schritte` auf einen Knoten je Linie – im Rückblick sieht
## die Kamera die ganze Strecke, also fast alle zugleich, je einen
## Zeichenaufruf (bis 40, Entwurf L05 §10: 30). Gemeinsame Stücke kosten
## höchstens einen je Stück.
##   linien    [Dictionary] je Linie:
##               seite, linie, profil   wie bei `seite_schritte`
##               gruppe   Text des Vermessungsschritts (Linien derselben
##                        Gruppe werden in EINEM Schritt vermessen; Vorgabe
##                        `name`)
##               stand    Wörterbuch für "flaeche" wie `optionen["stand"]`
##             und je Linie die Optionen von `seite_schritte`: schritt,
##             feste_s, kante, kronen, deckel, karten, karten_maske, saat,
##             halm_ton, wurzel_ton
##   optionen  für das gemeinsame Netz: sicht, fern_ab, sicht_karten, rand
## Bauspeicher wie `seite_schritte` (ein Eintrag für alle Linien). Die
## Bauschritte: je Gruppe „… wird vermessen", dann „<name> wird gebaut" –
## oder, aus dem Speicher, EIN Schritt „<name> wird geladen".
static func linien_schritte(eltern: Node3D, weg: Wegdaten, linien: Array, stoff: Material,
		name: String, speicher: String, optionen: Dictionary = {}) -> Array:
	if not speicher.is_empty():
		var gesichert: Variant = Bauspeicher.gespeichert(speicher)
		if gesichert is Dictionary:
			var d: Dictionary = gesichert
			return [{"text": name + " wird geladen", "tun": func() -> void:
					_linien_laden(eltern, name, stoff, d, linien)}]
	var bau := {}
	var gruppen := {}
	var reihenfolge: Array[String] = []
	for i in linien.size():
		var gruppe := String((linien[i] as Dictionary).get("gruppe", name))
		if not gruppen.has(gruppe):
			gruppen[gruppe] = []
			reihenfolge.append(gruppe)
		(gruppen[gruppe] as Array).append(i)
	var schritte: Array = []
	for gruppe in reihenfolge:
		var nummern: Array = gruppen[gruppe]
		schritte.append({"text": gruppe + " wird vermessen", "tun": func() -> void:
			for i: int in nummern:
				var l: Dictionary = linien[i]
				var b := {}
				_vermessen(weg, float(l["seite"]), l["linie"], l["profil"], l, b)
				bau[i] = b})
	schritte.append({"text": name + " wird gebaut", "tun": func() -> void:
		_linien_bauen(eltern, weg, name, stoff, speicher, optionen, linien, bau)})
	return schritte


## Schritt 2 von `linien_schritte`: alle Gitter in gemeinsame Stücke, Deckel
## und Karten je Linie; Netze einhängen und ablegen.
static func _linien_bauen(eltern: Node3D, weg: Wegdaten, name: String, stoff: Material,
		speicher: String, optionen: Dictionary, linien: Array, bau: Dictionary) -> void:
	var st := Stuecke.new(name)
	var flaechen := {}
	for i in linien.size():
		var l: Dictionary = linien[i]
		var b: Dictionary = bau[i]
		var proben: Array[Dictionary] = b["proben"]
		var g: Dictionary = b["g"]
		var norm: Array[PackedVector3Array] = b["norm"]
		if (g["reihen"] as Array).size() >= 2:
			_gitter_in_stuecke(st, name, g, norm)
			if bool(l.get("deckel", true)):
				_deckel_an_enden(st, name, g)
			if bool(l.get("karten", false)):
				_lippenkarten(st, name, proben, g, weg, l)
		if l.has("stand"):
			var flaeche := {"s": g["s"], "boden": g["boden"], "reihen": g["reihen"]}
			(l["stand"] as Dictionary)["flaeche"] = flaeche
			flaechen[i] = flaeche
	var netze := st.netze(float(optionen.get("sicht", SICHT)),
			float(optionen.get("fern_ab", FERN_AB)),
			float(optionen.get("sicht_karten", SICHT_KARTEN)),
			float(optionen.get("rand", SICHT_RAND)))
	_knoten_bauen(eltern, name, stoff, netze)
	if not speicher.is_empty():
		Bauspeicher.ablegen(speicher, {"netze": netze, "flaechen": flaechen})
	bau.clear()


## `linien_schritte` aus dem Speicher: Netze einhängen, Flächen in die
## `stand`-Wörterbücher der Linien.
static func _linien_laden(eltern: Node3D, name: String, stoff: Material, d: Dictionary,
		linien: Array) -> void:
	var netze: Array[Dictionary] = []
	netze.assign(d["netze"])
	_knoten_bauen(eltern, name, stoff, netze)
	var flaechen: Dictionary = d.get("flaechen", {})
	for i: int in flaechen:
		if i >= linien.size() or not (linien[i] as Dictionary).has("stand"):
			continue
		var f: Dictionary = flaechen[i]
		var reihen: Array[PackedVector3Array] = []
		reihen.assign(f["reihen"])
		((linien[i] as Dictionary)["stand"] as Dictionary)["flaeche"] = {"s": f["s"],
				"boden": f["boden"], "reihen": reihen}


## Strecken, an denen jede Kante einen Querschnitt braucht: beide Ränder
## jeder Lücke (und je einer knapp innerhalb), beide Seiten jeder Stufe und
## jeder Abschnittsanfang (wie saum.gd:464-474).
static func feste_strecken(weg: Wegdaten) -> PackedFloat32Array:
	var feste := PackedFloat32Array()
	for l: Vector2 in weg.luecken():
		feste.append_array([l.x, l.x + EPS * 2.0, l.y - EPS * 2.0, l.y])
	for i in range(1, weg.abschnitte.size()):
		var a: Dictionary = weg.abschnitte[i - 1]
		var b: Dictionary = weg.abschnitte[i]
		var naht: float = b["von"]
		if absf(float(a["bis"]) - naht) < 0.01 and absf(
				LevelWerkzeuge.eintrag_hoehe(weg.verlauf, a, naht)
				- LevelWerkzeuge.eintrag_hoehe(weg.verlauf, b, naht)) >= 0.05:
			feste.append_array([naht - EPS, naht + EPS])
	for a: Dictionary in weg.abschnitte:
		feste.append(float(a["von"]))
	return feste


## Schritt 1: Proben, Querschnitte, Normalen.
static func _vermessen(weg: Wegdaten, seite: float, linie_sq: PackedVector2Array,
		profil: Callable, optionen: Dictionary, bau: Dictionary) -> void:
	var feste: PackedFloat32Array = optionen["feste_s"] if optionen.has("feste_s") \
			else feste_strecken(weg)
	var proben := GelaendeSaum.linie(weg.verlauf, linie_sq, float(optionen.get("schritt",
			SCHRITT)), feste)
	var kante: Callable = optionen.get("kante", Callable())
	var kronen: Callable = optionen.get("kronen", Callable())
	var tiefe_bei := func(_i: int, probe: Dictionary) -> float:
		var s: float = probe["s"]
		return float(kante.call(s)) if kante.is_valid() else weg.boden_bei(s)
	var kronen_bei := func(_i: int, probe: Dictionary) -> float:
		return float(kronen.call(float(probe["s"]))) if kronen.is_valid() else 0.0
	var g := GelaendeSaum.querschnitte(weg.verlauf, proben, seite, profil, tiefe_bei,
			kronen_bei)
	bau["proben"] = proben
	bau["g"] = g
	bau["norm"] = GelaendeSaum.normalen(g)


## Schritt 2: Gitter in die Stücke, Deckel, Karten; Netze einhängen und
## ablegen.
static func _bauen(eltern: Node3D, weg: Wegdaten, name: String, stoff: Material,
		speicher: String, optionen: Dictionary, bau: Dictionary, stand: Dictionary) -> void:
	var proben: Array[Dictionary] = bau["proben"]
	var g: Dictionary = bau["g"]
	var norm: Array[PackedVector3Array] = bau["norm"]
	var st := Stuecke.new(name)
	if (g["reihen"] as Array).size() >= 2:
		_gitter_in_stuecke(st, name, g, norm)
		if bool(optionen.get("deckel", true)):
			_deckel_an_enden(st, name, g)
		if bool(optionen.get("karten", false)):
			_lippenkarten(st, name, proben, g, weg, optionen)
	var netze := st.netze(float(optionen.get("sicht", SICHT)),
			float(optionen.get("fern_ab", FERN_AB)),
			float(optionen.get("sicht_karten", SICHT_KARTEN)),
			float(optionen.get("rand", SICHT_RAND)))
	_knoten_bauen(eltern, name, stoff, netze)
	var flaeche := {"s": g["s"], "boden": g["boden"], "reihen": g["reihen"]}
	stand["flaeche"] = flaeche
	if not speicher.is_empty():
		Bauspeicher.ablegen(speicher, {"netze": netze, "flaeche": flaeche})
	bau.clear()


## Ein gesicherter Bau: Netze einhängen, Querschnitte in `stand`.
static func _aus_speicher(eltern: Node3D, name: String, stoff: Material, d: Dictionary,
		stand: Dictionary) -> void:
	var netze: Array[Dictionary] = []
	netze.assign(d["netze"])
	_knoten_bauen(eltern, name, stoff, netze)
	var f: Dictionary = d["flaeche"]
	var reihen: Array[PackedVector3Array] = []
	reihen.assign(f["reihen"])
	stand["flaeche"] = {"s": f["s"], "boden": f["boden"], "reihen": reihen}


## Hängt die Netze unter einen Sammelknoten `name`: je Eintrag ein
## MeshInstance3D ohne Schatten mit seinen Sichtweiten; Kartennetze mit dem
## Kartenstoff, alle anderen mit `stoff`.
static func _knoten_bauen(eltern: Node3D, name: String, stoff: Material,
		netze: Array[Dictionary]) -> Node3D:
	var wurzel := Node3D.new()
	wurzel.name = name
	eltern.add_child(wurzel)
	for e: Dictionary in netze:
		var mi := MeshInstance3D.new()
		mi.name = String(e["name"])
		mi.mesh = e["netz"]
		mi.material_override = GelaendeSaum.kartenstoff() if bool(e["karten"]) else stoff
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var von: float = e["von"]
		var rand: float = e["rand"]
		mi.visibility_range_begin = von
		mi.visibility_range_begin_margin = rand if von > 0.0 else 0.0
		mi.visibility_range_end = float(e["bis"])
		mi.visibility_range_end_margin = rand
		wurzel.add_child(mi)
	return wurzel


## Sammelt die Netze je Stück: ein Fels-Netz, seine Fernfassung und ein
## Kartennetz je Name (wie saum.gd:323-393, aber ohne Knoten: `netze()`
## gibt Einträge zurück, die sich in den Bauspeicher legen lassen).
class Stuecke:
	extends RefCounted
	var prefix: String
	var _opak := {}
	var _fern := {}
	var _karten := {}
	var _namen: Array[String] = []

	func _init(prefix_: String) -> void:
		prefix = prefix_

	func opak(name: String) -> SurfaceTool:
		if not _opak.has(name):
			_opak[name] = _neu()
			if not _namen.has(name):
				_namen.append(name)
		return _opak[name]

	## Die Fernfassung eines Stücks (ab `fern_ab`, nur die groben Gitter).
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

	## Die Netze als [{name, netz, karten, von, bis, rand}]: nah bis
	## `fern_ab`, die Fernfassung ab dort bis `sicht`; ein Stück ohne
	## Fernfassung bleibt bis `sicht` in voller Auflösung.
	func netze(sicht: float, fern_ab: float, sicht_karten: float,
			rand: float) -> Array[Dictionary]:
		var aus: Array[Dictionary] = []
		for name in _namen:
			var hat_fern := _fern.has(name)
			if _opak.has(name):
				_eintrag(aus, name, _opak[name], false, 0.0, fern_ab if hat_fern else sicht, rand)
			if hat_fern:
				_eintrag(aus, name + " fern", _fern[name], false, fern_ab, sicht, rand)
			if _karten.has(name):
				_eintrag(aus, name + " Karten", _karten[name], true, 0.0, sicht_karten, rand)
		return aus

	func _eintrag(aus: Array[Dictionary], name: String, st: SurfaceTool, karten_: bool,
			von: float, bis: float, rand: float) -> void:
		st.index()
		var netz := st.commit()
		if netz == null or netz.get_surface_count() == 0:
			return
		aus.append({"name": name, "netz": netz, "karten": karten_, "von": von, "bis": bis,
				"rand": rand})


## Name des Stücks, in dem die Strecke `s` liegt (Grenzen 3 m vor den
## vollen 30 m, wie saum.gd:408).
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


## Verschließt Anfang und Ende eines Gitters (saum.gd:430-446).
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


## Wurzel- und Halmkarten unter der Grasnarbe (Profilpunkte 2–5), nicht in
## Lücken; mit "karten_maske" nur, wo die Wegmaske Rasen zeigt (saum.gd:862-
## 914 und 1729-1745).
static func _lippenkarten(st: Stuecke, prefix: String, proben: Array[Dictionary],
		g: Dictionary, weg: Wegdaten, optionen: Dictionary) -> void:
	var reihen: Array[PackedVector3Array] = g["reihen"]
	var strecken: PackedFloat32Array = g["s"]
	var rng := PropWerkzeug.zufall(int(optionen.get("saat", 8301)))
	var maske := bool(optionen.get("karten_maske", false))
	var halm: Color = optionen.get("halm_ton", HALM_TON)
	var wurzel: Color = optionen.get("wurzel_ton", WURZEL_TON)
	for i in range(1, reihen.size() - 1):
		var s := strecken[i]
		if weg.ist_luecke(s):
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
		# Auf der ausgetretenen Spur hängt kein Gras über die Lippe.
		if maske and rng.randf() > rasen_anteil(weg, proben[i]):
			continue
		_karten_an(st.karten(_stueck(prefix, s)), rng, reihe[2], reihe[4], aussen, laengs,
				vor, halm, wurzel)


## Karten an einer Stelle der Narbe: oben = Narbenkante, unten = Unterseite.
## `vor` = wie weit die Narbe hier über die Lippe tritt (m): Wurzeln hängen
## in Büscheln unter den Vorsprüngen (saum.gd:893-914).
static func _karten_an(st: SurfaceTool, rng: RandomNumberGenerator, oben: Vector3,
		unten: Vector3, aussen: Vector3, laengs: Vector3, vor: float, halm: Color,
		wurzel: Color) -> void:
	# Halme, die über die Kante hängen.
	if rng.randf() < 0.9:
		var lang := rng.randf_range(0.2, 0.5)
		var ton := halm * rng.randf_range(0.75, 1.15)
		GelaendeSaum.karte(st, oben + Vector3.UP * 0.02 + laengs * rng.randf_range(-0.2, 0.2),
				(Vector3.DOWN * 0.75 + aussen * 0.65), laengs, lang,
				rng.randf_range(0.4, 0.75), GelaendeSaum.ATLAS_HALM, ton)
	# Wurzeln unter der Narbe, gekreuzt: Die Kamera blickt die Kante entlang.
	if rng.randf() < 0.25 * lerpf(0.3, 2.2, smoothstep(0.14, 0.28, vor)):
		var lang := rng.randf_range(0.3, 0.9)
		var ton := wurzel * 1.3 * rng.randf_range(0.8, 1.1)
		var ort := unten + aussen * 0.03 + laengs * rng.randf_range(-0.25, 0.25)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.12, laengs, lang,
				rng.randf_range(0.35, 0.7), GelaendeSaum.ATLAS_WURZEL, ton)
		GelaendeSaum.karte(st, ort, Vector3.DOWN + aussen * 0.08, aussen + laengs * 0.3,
				lang * rng.randf_range(0.7, 1.0), rng.randf_range(0.25, 0.45),
				GelaendeSaum.ATLAS_WURZEL, ton * 0.9)


# ================================================================ Fläche

## Ein Punkt auf der gebauten Fläche einer Kante (`stand["flaeche"]` aus
## `seite_schritte`) an der Strecke `s`, `hoehe` Meter über der Wegkante
## dort: im Querschnitt von innen nach außen die erste Stelle, an der die
## Fläche diese Höhe kreuzt (wie `GelaendeSaum.flaeche_punkt`, aber ohne
## statischen Merker). Ohne Fläche oder außerhalb: Vector3(NAN, NAN, NAN).
static func flaeche_punkt(flaeche: Dictionary, s: float, hoehe: float) -> Vector3:
	var leer := Vector3(NAN, NAN, NAN)
	if flaeche.is_empty():
		return leer
	var strecken: PackedFloat32Array = flaeche["s"]
	var boden: PackedFloat32Array = flaeche["boden"]
	var reihen: Array[PackedVector3Array] = []
	reihen.assign(flaeche["reihen"])
	var i := -1
	for k in strecken.size() - 1:
		var a := minf(strecken[k], strecken[k + 1])
		var b := maxf(strecken[k], strecken[k + 1])
		if s >= a and s <= b:
			i = k
			break
	if i < 0:
		return leer
	var spanne := strecken[i + 1] - strecken[i]
	var t := (s - strecken[i]) / spanne if absf(spanne) > 0.0001 else 0.0
	var y := lerpf(boden[i], boden[i + 1], t) + hoehe
	var pa := _kreuzung(reihen[i], y)
	var pb := _kreuzung(reihen[i + 1], y)
	if is_nan(pa.x) or is_nan(pb.x):
		return leer
	return pa.lerp(pb, t)


static func _kreuzung(reihe: PackedVector3Array, y: float) -> Vector3:
	for j in reihe.size() - 1:
		var a := reihe[j]
		var b := reihe[j + 1]
		if (a.y - y) * (b.y - y) <= 0.0 and absf(b.y - a.y) > 0.0001:
			return a.lerp(b, (y - a.y) / (b.y - a.y))
	return Vector3(NAN, NAN, NAN)
