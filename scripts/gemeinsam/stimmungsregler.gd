extends Node
class_name Stimmungsregler
## Licht und Nebel nach der Strecke der Figur – ohne Bezug auf Level 01
## (Baukasten Raum 1, Paket G5; Herkunft scenes/levels/level01/stimmung.gd,
## `L01Stimmung.Regler` :232-467, Zonenschema :97-135).
##
## WARUM EIN REGLER NACH s. Stimmungszonen als Auslösekästen
## (`Stimmungszone`) blenden über die ZEIT über: Wer an einer Stelle steht,
## sieht je nachdem, woher er kam, eine halbe Überblendung – und ein Foto
## nach 0,8 s Wartezeit auch. Der Regler rechnet jedes Bild aus der Strecke
## `s` die Mischung der Zonen (weiche Ränder über Strecke, nicht über Zeit)
## und geht ihr nur gegen Sprünge (Wiedereinstieg am Checkpoint) mit einer
## Zeitkonstante von einer Sechstelsekunde nach. So sieht jede Stelle immer
## gleich aus. Die Level 02–05 wollen alle genau das (Baukasten §1.1).
##
## ZONEN im Schema von stimmung.gd:120-139, je ein Wörterbuch:
##   name, von, bis        Strecke der Zone (m)
##   rand_von, rand_bis    Breite des weichen Übergangs am Anfang bzw. Ende
##                         (m, sonst `uebergang`); zwei Zonen, die
##                         aneinanderstoßen, tragen an der Naht dieselbe Breite
##   nebel_faktor          verkürzt die Nebelstrecke der Szene (Beginn → Ende)
##   licht_faktor          Faktor auf das Umgebungslicht der Szene
##   nebelfarbe            Nebellicht (zu `farbanteil`, Vorgabe ganz)
##   umgebungsfarbe        Farbe des Umgebungslichts (ebenso)
##   oben                  Faktor auf das Licht von oben (Option "oben")
##   kurve                 `fog_depth_curve` (sonst die der Szene)
##   sonne_farbe           Farbe der Sonne (Option "sonne")
##   sonne_faktor          Faktor auf die Sonnenenergie
## Neu und freiwillig (Baukasten §4 Nr. 9, für die absoluten Werte von
## Level 02):
##   nebel_beginn          `fog_depth_begin` (m). Das Ende rechnet weiter vom
##                         Beginn der SZENE aus: L02 zieht den Beginn von 20
##                         auf 28 m, das Ende bleibt bei 200 m.
##   sonne_energie         Sonnenenergie absolut statt der der Szene (ein
##                         `sonne_faktor` daneben wirkt darauf)
##   rahmen, rahmen_licht  `Bildrahmen.staerke` und `.licht` (Option "rahmen")
## Was eine Zone nicht nennt, nimmt sie von der Szene (Faktoren 1).
##
## OPTIONEN von `anlegen()`:
##   sonne, oben    DirectionalLight3D, deren Energie (und Farbe) er regelt
##   rahmen         ein `Bildrahmen`
##   nebelstoffe    Abschriften aus `Nebelstoff.nebelarm` (eigener Nebel)
##   nebeltafeln    Stoffe aus `GelaendeBau.nebeltafeln`: "farbe" folgt dem
##                  Nebellicht, `NEBELTAFEL_HELLER` heller (wie der Bachnebel
##                  in Level 01)
##   uebergang      Randbreite, wo eine Zone nichts sagt (Vorgabe 8 m)
##   farbanteil     wie weit die Farben zur Zonenfarbe gehen (Vorgabe 1)
##   welt           WorldEnvironment (sonst der Knoten "WorldEnvironment")
##   eltern         wohin er gehängt wird (sonst `level.deko`)
##
## DIE STRECKE kommt aus `level.strecke_der_figur()` statt aus dem nächsten
## Punkt der Kurve (stimmung.gd:328-329): An der Kreuzung von Level 04
## entscheidet sonst die Nähe, welcher Ast gilt (Baukasten §1.8).
##
## KOSTEN (stimmung.gd:259-263): Steht die Figur (weniger als `SCHWELLE_S`
## m seit dem letzten Mischen) und ist der Stand eingeschwungen, kehrt
## `_process` sofort zurück. Solange er nachführt, schreibt er nur, was sich
## um mehr als `SCHWELLE` geändert hat – im Web und auf dem Handy kostet
## jeder Schreibzugriff einen Weg zum Renderer und jeder Stoffparameter ein
## neues Hochladen. `geschrieben` zählt die Schreibzugriffe;
## `werkzeuge/baukastenprobe.gd` prüft daran, dass eine stehende Figur
## nichts kostet. Bewegt keine Knoten, braucht also keine Regel für den
## Bildtakt.
##
## EINGESCHWUNGEN schreibt er den GENAUEN Zielwert (jeden, der vom zuletzt
## geschriebenen abweicht) – anders als Level 01, wo bis zu `SCHWELLE`
## Rest stehen bleibt. Gemessen an der Werkstatt: Nach Station 32 zurück
## vor ihr blieb der Bildrahmen auf 0,001 statt 0 stehen, und ein Rahmen
## über 0 zeichnet (`Bildrahmen._werte_setzen`: sichtbar ab > 0) – ein
## bildschirmfüllender Durchgang mehr, für immer. Und so ist eine Stelle
## im Stand auch bitgleich dieselbe, woher die Figur auch kam. Es kostet
## wenig: Beim Einschwingen schreibt er jeden Wert noch einmal (Lauf von
## s 72 bis 132 über eine Naht von Level 01: 659 statt 633 Schreibzugriffe,
## Baukastenprobe); im Stand kehrt er weiter sofort zurück, und im Inneren
## einer Zone ändert sich die Mischung nicht, also auch dort kein Schreiben.
##
## UNTERSCHIEDE ZU LEVEL 01, begründet:
##   - Keine Zylinderzone (die Wendel um den Weltenbaum, stimmung.gd:142):
##     Das ist ein Einzelstück von Level 01, kein anderes Level braucht sie.
##   - LÜCKEN: Level 01 deckt den ganzen Weg mit Zonen und teilt durch ihre
##     Summe; wo keine Zone liegt, ergäbe das Schwarz und Nebelende 0 (die
##     Summe ist dort 0). Hier füllt die Szene selbst auf, wo die Summe
##     merklich unter 1 liegt (`LUECKE`): Eine Zone kann einzeln stehen und
##     blendet an einem freien Rand in die Grundstimmung. Wo die Zonen
##     decken – an einer Naht gleicher Breite ist die Summe 1 bis auf
##     Rundung –, rechnet er genau wie Level 01.
##   - Nebelfarbe, Umgebungsfarbe und die beiden Faktoren sind freiwillig
##     (Vorgabe: Szene bzw. 1). Die Entwürfe von Level 03 und 04 nennen nur
##     Faktoren, Level 05 keine Umgebungsfarbe.
##   - Die Stoffe bekommt er vom Level (Optionen), statt sie aus Modulen von
##     Level 01 zu holen; den Nebel setzt `Nebelstoff.nebel_setzen`.
## Mit den Zonen von Level 01 (`L01Stimmung.ZONEN`) liefert `mischung()`
## bis aufs Bit dasselbe wie das Original, überall außerhalb der Wendel
## (werkzeuge/baukastenprobe.gd, Teil G5).

## Wie weit die Farben von der Grundstimmung zur Zonenfarbe gehen (wie
## stimmung.gd:151: ganz).
const FARBANTEIL := 1.0
## Breite der weichen Übergänge (m Strecke), wo eine Zone nichts sagt.
const UEBERGANG := 8.0
## So schnell geht der Regler der Mischung nach (Zeitkonstante 1/6 s,
## unabhängig von der Bildrate).
const NACHFUEHREN := 6.0
## Nebeltafeln sind das Nebellicht, so viel heller (wie der Bachnebel von
## Level 01, stimmung.gd:161).
const NEBELTAFEL_HELLER := 0.22
## Unter diesen Änderungen schreibt er nichts (Farbanteile, Hundertstel der
## Nebelstrecke bzw. Faktoren).
const SCHWELLE := 0.001
## So weit (m Strecke) muss sich die Figur bewegen, damit er neu mischt.
const SCHWELLE_S := 0.02
## Liegt die Summe der Zonengewichte um mehr als das unter 1, füllt die
## Szene den Rest (siehe Kopf, LÜCKEN). An einer Naht zweier Zonen gleicher
## Randbreite ist die Summe 1 bis auf Rundung – dort bleibt es bei der
## Rechnung von Level 01 (an den drei Nähten von Level 01 an keiner der
## 617 Probestellen der Baukastenprobe anders).
const LUECKE := 1.0e-6

## Die Grundstimmung als Zone: Sie nennt nichts, nimmt also alles von der
## Szene.
const _SZENE := {}

var level: LevelBasis
var welt: WorldEnvironment
## Das Licht von oben, oder null.
var oben: DirectionalLight3D
## Die Sonne, oder null.
var sonne: DirectionalLight3D
## Der Bildrahmen, oder null.
var rahmen: Bildrahmen
## Stoffe mit eigenem Nebel (`Nebelstoff.nebelarm`).
var nebelstoffe: Array[ShaderMaterial] = []
## Stoffe der Nebeltafeln (`GelaendeBau.nebeltafeln`).
var nebeltafeln: Array[ShaderMaterial] = []
## Die Zonen (eine Kopie: Ein Prüfwerkzeug darf sie zur Laufzeit verstellen
## und `neu_rechnen()` rufen).
var zonen: Array = []
var uebergang := UEBERGANG
var farbanteil := FARBANTEIL
## Zahl der Schreibzugriffe seit dem Anlegen (je geänderter Wert einer) –
## für Proben.
var geschrieben := 0

var _umgebung: Environment
var _grund := {}
var _stand := {}
var _ziel := {}
## Was zuletzt geschrieben wurde, je Schlüssel.
var _zuletzt := {}
var _spieler: Node3D
var _sofort := true
var _s_alt := INF
var _ruhig := false


## Legt einen Regler für `level` an und hängt ihn ein (Optionen im Kopf).
## Ohne WorldEnvironment mit Umgebung: null.
static func anlegen(level_: LevelBasis, zonen_: Array, optionen := {}) -> Stimmungsregler:
	var welt_ := optionen.get("welt", level_.get_node_or_null("WorldEnvironment")) \
			as WorldEnvironment
	if welt_ == null or welt_.environment == null:
		push_warning("Stimmungsregler: keine WorldEnvironment mit Umgebung – kein Regler.")
		return null
	var regler := Stimmungsregler.new()
	regler.name = "Stimmungsregler"
	regler.level = level_
	regler.welt = welt_
	regler.zonen = zonen_.duplicate(true)
	regler.sonne = optionen.get("sonne") as DirectionalLight3D
	regler.oben = optionen.get("oben") as DirectionalLight3D
	regler.rahmen = optionen.get("rahmen") as Bildrahmen
	regler.nebelstoffe.assign(optionen.get("nebelstoffe", []) as Array)
	regler.nebeltafeln.assign(optionen.get("nebeltafeln", []) as Array)
	regler.uebergang = float(optionen.get("uebergang", UEBERGANG))
	regler.farbanteil = float(optionen.get("farbanteil", FARBANTEIL))
	var vorgabe: Node = level_.deko if level_.deko != null else level_
	var eltern := optionen.get("eltern", vorgabe) as Node
	eltern.add_child(regler)
	return regler


## Die Umgebung der Szene ist eine Unterressource, die allen Instanzen
## gehört – sie wird deshalb einmal kopiert (wie in `Stimmungszone`).
func _ready() -> void:
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
	if rahmen != null:
		_grund["rahmen"] = rahmen.staerke
		_grund["rahmen_licht"] = rahmen.licht
	_ungenutzt_melden()


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
	if _spieler == null or level == null or level.verlauf == null:
		return
	var s := level.strecke_der_figur()
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
			if not _stand.has(k):
				# Ein Schlüssel, den es vorher nicht gab (Zonen zur Laufzeit
				# verstellt): gleich dorthin.
				_stand[k] = z
			elif z is Color:
				_stand[k] = (_stand[k] as Color).lerp(z as Color, anteil)
			else:
				_stand[k] = lerpf(float(_stand[k]), float(z), anteil)
	_ruhig = _abstand(_stand, _ziel) < SCHWELLE
	if _ruhig:
		_stand = _ziel.duplicate()
	_schreiben(_ruhig)


## Die Werte an der Strecke `s` (ohne Nachführen). Schlüssel wie
## stimmung.gd:388-390; "nebelbeginn" nur, wenn eine Zone `nebel_beginn`
## nennt, "rahmen" und "rahmen_licht" nur mit Bildrahmen.
##
## Rechenweg und Reihenfolge wie stimmung.gd:353-390 – das ist die
## Bedingung für die Bitgleichheit, die die Baukastenprobe verlangt. Die
## Szene steht als letzte „Zone" an der Stelle der Wendel.
func mischung(s: float) -> Dictionary:
	var summe := 0.0
	var mit_beginn := false
	for z: Dictionary in zonen:
		summe += _kasten(s, z)
		mit_beginn = mit_beginn or z.has("nebel_beginn")
	var luecke := 1.0 - summe
	if luecke <= LUECKE:
		luecke = 0.0
	var rest := 1.0 / maxf(summe + luecke, 0.0001)
	var farbe := Color(0, 0, 0)
	var umgebung := Color(0, 0, 0)
	var sonnenfarbe := Color(0, 0, 0)
	var ende := 0.0
	var kurve := 0.0
	var licht := 0.0
	var von_oben := 0.0
	var sonnenlicht := 0.0
	var nebelbeginn := 0.0
	var rahmen_staerke := 0.0
	var rahmen_licht := 0.0
	var grund_farbe: Color = _grund["nebelfarbe"]
	var grund_umgebung: Color = _grund["umgebungsfarbe"]
	var grund_sonne: Color = _grund["sonne_farbe"]
	var beginn: float = _grund["nebelbeginn"]
	var strecke := maxf(float(_grund["nebelende"]) - beginn, 1.0)
	for i in zonen.size() + 1:
		var z: Dictionary = _SZENE if i == zonen.size() else zonen[i]
		var a := luecke * rest if i == zonen.size() else _kasten(s, z) * rest
		if a <= 0.0:
			continue
		farbe += grund_farbe.lerp(z.get("nebelfarbe", grund_farbe) as Color, farbanteil) * a
		umgebung += grund_umgebung.lerp(z.get("umgebungsfarbe", grund_umgebung) as Color,
				farbanteil) * a
		sonnenfarbe += (z.get("sonne_farbe", grund_sonne) as Color) * a
		ende += (beginn + strecke / float(z.get("nebel_faktor", 1.0))) * a
		kurve += float(z.get("kurve", _grund["kurve"])) * a
		licht += float(_grund["licht"]) * float(z.get("licht_faktor", 1.0)) * a
		von_oben += float(_grund["oben"]) * float(z.get("oben", 1.0)) * a
		sonnenlicht += float(z.get("sonne_energie", _grund["sonne"])) \
				* float(z.get("sonne_faktor", 1.0)) * a
		if mit_beginn:
			nebelbeginn += float(z.get("nebel_beginn", beginn)) * a
		if rahmen != null:
			rahmen_staerke += float(z.get("rahmen", _grund["rahmen"])) * a
			rahmen_licht += float(z.get("rahmen_licht", _grund["rahmen_licht"])) * a
	farbe.a = 1.0
	umgebung.a = 1.0
	sonnenfarbe.a = 1.0
	var werte := {"nebelfarbe": farbe, "umgebungsfarbe": umgebung, "nebelende": ende,
			"kurve": kurve, "licht": licht, "oben": von_oben, "sonne": sonnenlicht,
			"sonne_farbe": sonnenfarbe}
	if mit_beginn:
		werte["nebelbeginn"] = nebelbeginn
		# Ein Beginn hinter dem Ende kehrte den Nebel um.
		werte["nebelende"] = maxf(ende, nebelbeginn + 1.0)
	if rahmen != null:
		werte["rahmen"] = rahmen_staerke
		werte["rahmen_licht"] = rahmen_licht
	return werte


## Gewicht einer Zone mit weichen Rändern ("rand_von"/"rand_bis").
func _kasten(s: float, z: Dictionary) -> float:
	var von: float = z["von"]
	var bis: float = z["bis"]
	var hv := float(z.get("rand_von", uebergang)) * 0.5
	var hb := float(z.get("rand_bis", uebergang)) * 0.5
	return smoothstep(von - hv, von + hv, s) * (1.0 - smoothstep(bis - hb, bis + hb, s))


## Größter Unterschied zweier Stände (Farben je Kanal, Nebelende und
## -beginn in Hundertsteln ihrer Meter, sonst der Wert).
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
	if k == "nebelende" or k == "nebelbeginn":
		return absf(float(a) - float(b)) * 0.01
	return absf(float(a) - float(b))


## Hat sich `k` seit dem letzten Schreiben merklich geändert (`genau`:
## überhaupt)? Merkt sich den neuen Wert und zählt den Schreibzugriff, wenn
## ja.
func _neu(k: String, genau: bool) -> bool:
	var wert: Variant = _stand[k]
	var alt: Variant = _zuletzt.get(k)
	if genau:
		if alt != null and alt == wert:
			return false
	elif _unterschied(k, alt, wert) < SCHWELLE:
		return false
	_zuletzt[k] = wert
	geschrieben += 1
	return true


## Schreibt den Stand: beim Nachführen nur merkliche Änderungen, `genau`
## (eingeschwungen) jede.
func _schreiben(genau: bool) -> void:
	var farbe: Color = _stand["nebelfarbe"]
	var nebel_neu := false
	if _neu("nebelfarbe", genau):
		_umgebung.fog_light_color = farbe
		for tafel in nebeltafeln:
			tafel.set_shader_parameter("farbe", farbe.lightened(NEBELTAFEL_HELLER))
		nebel_neu = true
	if _neu("nebelende", genau):
		_umgebung.fog_depth_end = float(_stand["nebelende"])
		nebel_neu = true
	if _stand.has("nebelbeginn") and _neu("nebelbeginn", genau):
		_umgebung.fog_depth_begin = float(_stand["nebelbeginn"])
		nebel_neu = true
	if _neu("kurve", genau):
		_umgebung.fog_depth_curve = float(_stand["kurve"])
		nebel_neu = true
	if _neu("licht", genau):
		_umgebung.ambient_light_energy = float(_stand["licht"])
	if _neu("umgebungsfarbe", genau):
		_umgebung.ambient_light_color = _stand["umgebungsfarbe"]
	if oben != null and _neu("oben", genau):
		oben.light_energy = float(_stand["oben"])
	if sonne != null:
		if _neu("sonne", genau):
			sonne.light_energy = float(_stand["sonne"])
		if _neu("sonne_farbe", genau):
			sonne.light_color = _stand["sonne_farbe"]
	if rahmen != null:
		if _neu("rahmen", genau):
			rahmen.staerke = float(_stand["rahmen"])
		if _neu("rahmen_licht", genau):
			rahmen.licht = float(_stand["rahmen_licht"])
	if nebel_neu:
		for stoff in nebelstoffe:
			Nebelstoff.nebel_setzen(stoff, _umgebung)


## Eine Zone, die etwas regeln will, wofür der Knoten fehlt (Sonne, Licht
## von oben, Bildrahmen), wirkt nicht – das soll beim Bauen auffallen, nicht
## erst im Bild.
func _ungenutzt_melden() -> void:
	var fehlt := {}
	for z: Dictionary in zonen:
		if oben == null and z.has("oben"):
			fehlt["oben (Option oben)"] = true
		if sonne == null and (z.has("sonne_farbe") or z.has("sonne_faktor")
				or z.has("sonne_energie")):
			fehlt["sonne_* (Option sonne)"] = true
		if rahmen == null and (z.has("rahmen") or z.has("rahmen_licht")):
			fehlt["rahmen* (Option rahmen)"] = true
	if not fehlt.is_empty():
		push_warning("Stimmungsregler: Zonen nennen %s, der Knoten fehlt – das wirkt nicht."
				% ", ".join(PackedStringArray(fehlt.keys())))
