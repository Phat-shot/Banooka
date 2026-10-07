extends Node
## Jagdprobe: Hält die Flucht vor dem Verfolger, was der Entwurf rechnet?
## (Level 05, Entwurf §12 P1, §2.5, §6.5)
##
## Aufruf (macht `pruefe.sh` in Stufe 4 für jedes Level, das mitmacht):
##   godot --headless --fixed-fps 60 --path . res://werkzeuge/Jagdprobe.tscn \
##       -- res://scenes/levels/Level05.tscn
## Mit `--fixed-fps 60` ist jedes Bild genau ein Physikschritt: Die Probe
## läuft so schnell, wie der Rechner rechnet, und misst bei jedem Lauf
## dasselbe.
##
## WARUM: Die Jagd rechnet nur mit der Strecke – Tempo 7,4 gegen 8,5, jeder
## Sprung, jeder Slide, jedes Stolpern verschiebt den Abstand. Ob die Kette
## wirklich zwei Fehler verzeiht, sieht man nicht im Bild, und eine spätere
## Änderung am Gelände oder an der Optik (eine Stufe mehr, ein Durchlass
## tiefer) bräche sie still. Deshalb läuft die Probe in `pruefe.sh` mit.
##
## OPT-IN wie die Sprungprobe: Geprüft wird nur ein Level, das
## `jagdfaelle() -> Array[Dictionary]` und `jagd_zustand() -> Dictionary`
## anbietet. Alle anderen melden sich ohne Prüfung ab.
##
## Die ECHTE FIGUR läuft, gelenkt wie ein Mensch am Stick (kamerarelativ,
## wie in der Sprungprobe), nach dem Muster der Messbank des Entwurfs
## (`l05_lenker.gd`): Ein Lenker läuft in jedem Physikschritt VOR der Figur
## (Priorität −100), hält die Richtung auf der Lauflinie und drückt Sprung
## und Slide an festen Stellen. Jeder Fall beginnt mit einem Tod: Die Probe
## setzt den Checkpoint (`GameState.setze_checkpoint`) und lässt die Figur
## sterben – so stellt auch das Spiel den Verfolger neu (`nach_tod`).
##
## EIN FALL (Dictionary aus `jagdfaelle()`):
##   name          Bezeichnung in der Ausgabe
##   checkpoint    Vector3 (Welt): hier erscheint die Figur
##   rastplatz     Strecke dieses Checkpoints: Alle Durchlässe dahinter
##                 müssen nach dem Respawn heil sein (Körper an)
##   aktionen      Array[Dictionary], nach "s" sortiert, je mit "tun":
##                   sprung        Sprung, Taste gehalten bis zur Landung
##                   doppel        dazu der Doppelsprung "nach" s später
##                   slide         Slide angetippt
##                   slide_halten  Slide gedrückt und gehalten bis "bis"
##                   stolpern      kein Slide: in den Durchlass hineinlaufen,
##                                 stolpern, "reaktion" s warten, dann aus
##                                 dem Stand sliden. Stolpert sie bis "bis"
##                                 nicht, ist das ein FEHLER
##                   warten        "dauer" s stehen bleiben, dann weiter;
##                                 mit "sofort": true auch in der Luft (nach
##                                 dem Respawn: Die Figur fällt 0,6 m, und
##                                 der Lenker liefe ihr sonst im Fallen schon
##                                 davon)
##                   stehen        stehen bleiben bis zum Ende des Falls
##                   schweben      an der Strecke "an" über der Decke
##                                 festhalten (über einer Lücke)
##                 Sprung, Slide und Warten lösen erst am Boden aus.
##   spur          Array[Vector2] (s, q): Lauflinie, linear dazwischen; der
##                 Lenker hält auf den Punkt VORAUS m weiter zu
##   Ende, genau eines davon:
##     ende_s      Figur am Boden hinter dieser Strecke
##     ende_dauer  so viele Sekunden nach dem Respawn
##     ende_ufer   so viele Sekunden, nachdem der Verfolger am Ufer steht
##     ende_ziel   so viele Sekunden nach `level_geschafft` des Zielportals
##   erwartet      "ueberlebt" oder "gefangen" (die GEGENPROBE: Die Probe
##                 muss erkennen, dass zu viele Fehler tödlich sind)
##   min_abstand   (frei) Mindestabstand während der Jagd
##   weck_abstand  (frei) Vector2(soll, Spiel): Abstand beim Wecken
##   keiler_start  (frei) Vector2(soll, Spiel): Strecke des Verfolgers im
##                 ersten Bild nach dem Respawn
##   stolpern      (frei, Vorgabe 0) so oft muss die Figur stolpern
##
## `jagd_zustand()` liefert: lage ("schlaf" | "jagd" | "ufer"), keiler_s,
## keiler_y und boden_y (Level-Y des Verfolgers und `boden_bei(keiler_s)`),
## hopser (bool), weck_abstand, faenge (wie oft er gefangen hat),
## durchlaesse [{s, gebrochen, koerper_an}], ufer_s, bruch_vor.
##
## FEHLER, wenn
##   * ein Fall nicht das erwartete Ende nimmt (Tod beim Überleben, kein Fang
##     in der Gegenprobe, ein Tod ohne Fang dort), zu oft oder zu selten
##     stolpert, den Mindestabstand, den Weckabstand oder die Stelle nach dem
##     Respawn verfehlt, in 90 s nicht fertig wird;
##   * ein Durchlass hinter dem Rastplatz nach dem Respawn nicht heil ist,
##     oder irgendwann sein Bruch nicht zur Stelle des Verfolgers passt
##     (gebrochen genau ab keiler_s ≥ Stirn − bruch_vor, Körper aus genau
##     dann);
##   * der Verfolger außerhalb eines Hopsers mehr als HOEHE_SPIEL über oder
##     unter `boden_bei` steht oder im Hopser unter die Decke taucht;
##   * er je über das Ufer hinauskommt;
##   * das Zielportal `level_geschafft` nicht genau einmal meldet, oder der
##     Verfolger danach nicht am Ufer steht.
## Der letzte Fall darf ins Ziel laufen: Danach wechselt das Level nach
## 4,5 s in den Portalraum; die Probe endet vorher.

## Längster Fall in Physikschritten (90 s).
const FALL_MAX := 60 * 90
## Der Lenker hält auf die Lauflinie so weit voraus zu.
const VORAUS := 1.5
## Höhe des Verfolgers außerhalb der Hopser: so weit neben `boden_bei`.
const HOEHE_SPIEL := 0.05
## So viele Bilder nach dem Respawn werden die Durchlässe geprüft (der
## Körper schaltet aufgeschoben).
const RESPAWN_BILDER := 3
## Über einer Lücke so hoch über der Decke gehalten.
const SCHWEBEN_HOEHE := 0.05


## Ruft den Lenker in jedem Physikschritt vor der Figur.
class Takt extends Node:
	var rufen := Callable()

	func _physics_process(_delta: float) -> void:
		if rufen.is_valid():
			rufen.call()


var _level: Node3D
var _spieler: CharacterBody3D
var _takt: Takt
var _verlauf: Curve3D
var _fehler := 0
var _geschafft := 0

# --- über alle Fälle ---
var _hoehe_max := 0.0
var _hoehe_bilder := 0
var _unter_max := -INF
var _hopser_bilder := 0
var _keiler_max := -INF
var _ufer_s := INF

# --- je Fall ---
var _fall: Dictionary = {}
var _aktiv := false
var _fertig := false
var _bild := 0
var _aktionen: Array[Dictionary] = []
var _ausgeloest: Array[bool] = []
var _spur: Array[Vector2] = []
var _tot := false
var _letzte_s := 0.0
var _tod_s := NAN
var _min_abstand := INF
var _min_s := NAN
var _weck := NAN
var _weck_bild := -1
## Schlief der Verfolger nach dem Respawn? Nur dann zählt das Wecken.
var _schlief := false
var _stolpern := 0
var _stolper_orte: Array[String] = []
var _stolperte := false
var _krabbel_bilder := 0
var _hopser := 0
var _war_hopser := false
var _ufer_bild := -1
var _ziel_bild := -1
var _geschafft_vorher := 0
var _fall_fehler: Array[String] = []
var _durchlass_gemeldet := {}
# Tasten und Zustände des Lenkers
var _taste_sprung := false
var _sprung_bild := -1
var _doppel_bilder := -1
var _in_luft := false
var _slide_los := false
var _halten_bis := NAN
var _warten_rest := 0
var _stehen := false
var _schweben := Vector3.INF
var _stolper_aktion := -1
var _stolper_phase := 0
var _reaktion_rest := 0


func _ready() -> void:
	var pfad := "res://scenes/levels/Level05.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	# Die Probe misst immer dieselbe Fassung, egal was in `user://` steht.
	Zeitlauf.aktiv = false
	_level = (load(pfad) as PackedScene).instantiate() as Node3D
	var fertig := [false]
	if _level.has_signal("aufbau_fertig"):
		_level.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_level)
	var name_kurz := pfad.get_file().get_basename()
	if not _level.has_method("jagdfaelle") or not _level.has_method("jagd_zustand"):
		print("=== Jagdprobe %s: keine Jagdfälle (nicht angemeldet) ===" % name_kurz)
		get_tree().quit(0)
		return
	var gewartet := 0
	while not fertig[0] and gewartet < 3600:
		gewartet += 1
		await get_tree().physics_frame
	_spieler = get_tree().get_first_node_in_group("spieler") as CharacterBody3D
	var verlauf: Variant = _level.get("verlauf")
	if _spieler == null or not verlauf is Curve3D:
		print("  FEHLER  Jagdprobe: keine Figur oder kein Levelverlauf")
		get_tree().quit(1)
		return
	_verlauf = verlauf as Curve3D
	_spieler.connect("gestorben", _auf_tod)
	for knoten in _alle(_level):
		if knoten.has_signal("level_geschafft"):
			knoten.connect("level_geschafft", func() -> void: _geschafft += 1)
	_takt = Takt.new()
	_takt.name = "Lenker"
	_takt.process_physics_priority = -100
	_takt.rufen = _lenken
	add_child(_takt)
	for f in 3:
		await get_tree().physics_frame

	print("=== Jagdprobe %s ===" % name_kurz)
	var faelle: Array = _level.call("jagdfaelle")
	if faelle.is_empty():
		_fehler += 1
		print("  FEHLER  jagdfaelle() lieferte keinen einzigen Fall")
	for fall: Dictionary in faelle:
		await _fall_pruefen(fall)
	_gesamt_auswerten()
	print("=== Jagdprobe: %d Fälle, %d Fehler ===" % [faelle.size(), _fehler])
	get_tree().quit(1 if _fehler > 0 else 0)


func _auf_tod() -> void:
	if _aktiv and not _tot:
		_tot = true
		_tod_s = _letzte_s


# =========================================================== Ein Fall

func _fall_pruefen(fall: Dictionary) -> void:
	_fall = fall
	var name: String = fall["name"]
	_zuruecksetzen()
	# Respawn am Checkpoint: genau wie im Spiel.
	InputHub.zuruecksetzen()
	GameState.leben = 50
	var vorher: Dictionary = _level.call("jagd_zustand")
	var faenge_vorher: int = vorher["faenge"]
	var checkpoint: Vector3 = fall["checkpoint"]
	GameState.setze_checkpoint(checkpoint)
	_spieler.call("sterben")
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")
	await get_tree().physics_frame
	# Erstes Bild nach dem Respawn: `nach_tod` ist gelaufen, der Verfolger
	# hat noch keinen Schritt getan.
	var z: Dictionary = _level.call("jagd_zustand")
	var start_text := ""
	if fall.has("keiler_start"):
		var soll: Vector2 = fall["keiler_start"]
		var ist: float = z["keiler_s"]
		start_text = ", Keiler bei %.2f (soll %.2f)" % [ist, soll.x]
		if absf(ist - soll.x) > soll.y + 0.0001:
			_fall_fehler.append("Keiler nach dem Respawn bei s %.2f, soll %.2f ± %.2f"
					% [ist, soll.x, soll.y])
	for f in RESPAWN_BILDER - 1:
		await get_tree().physics_frame
	var heil_text := _durchlaesse_nach_respawn(float(fall.get("rastplatz", -INF)))
	_schlief = String((_level.call("jagd_zustand") as Dictionary)["lage"]) == "schlaf"
	# Lauf
	_geschafft_vorher = _geschafft
	_aktiv = true
	while not _fertig:
		await get_tree().physics_frame
	_aktiv = false
	InputHub.zuruecksetzen()
	z = _level.call("jagd_zustand")
	var gefangen := int(z["faenge"]) > faenge_vorher
	_fall_auswerten(name, z, gefangen, start_text + heil_text)


func _zuruecksetzen() -> void:
	_fertig = false
	_bild = 0
	_aktionen.assign(_fall.get("aktionen", []))
	_ausgeloest.clear()
	for i in _aktionen.size():
		_ausgeloest.append(false)
	_spur.assign(_fall.get("spur", [Vector2(-1000.0, 0.0), Vector2(1000.0, 0.0)]))
	_tot = false
	_tod_s = NAN
	_min_abstand = INF
	_min_s = NAN
	_weck = NAN
	_weck_bild = -1
	_stolpern = 0
	_stolper_orte.clear()
	_stolperte = false
	_krabbel_bilder = 0
	_hopser = 0
	_war_hopser = false
	_ufer_bild = -1
	_ziel_bild = -1
	_fall_fehler.clear()
	_durchlass_gemeldet.clear()
	_taste_sprung = false
	_sprung_bild = -1
	_doppel_bilder = -1
	_in_luft = false
	_slide_los = false
	_halten_bis = NAN
	_warten_rest = 0
	_stehen = false
	_schweben = Vector3.INF
	_stolper_aktion = -1
	_stolper_phase = 0
	_reaktion_rest = 0


## Durchlässe hinter dem Rastplatz müssen heil sein (Körper an).
func _durchlaesse_nach_respawn(rastplatz: float) -> String:
	if is_inf(rastplatz):
		return ""
	var z: Dictionary = _level.call("jagd_zustand")
	var dahinter := 0
	var heil := 0
	for d: Dictionary in z["durchlaesse"]:
		if float(d["s"]) <= rastplatz:
			continue
		dahinter += 1
		if not bool(d["gebrochen"]) and bool(d["koerper_an"]):
			heil += 1
		else:
			_fall_fehler.append("Durchlass bei s %.1f hinter dem Rastplatz %.0f nach dem Respawn nicht heil (gebrochen %s, Körper an %s)"
					% [float(d["s"]), rastplatz, str(d["gebrochen"]), str(d["koerper_an"])])
	return ", Durchlässe dahinter heil %d/%d" % [heil, dahinter]


func _fall_auswerten(name: String, z: Dictionary, gefangen: bool, vorspann: String) -> void:
	var erwartet: String = _fall.get("erwartet", "ueberlebt")
	var teile: Array[String] = []
	if _tot:
		teile.append(("gefangen bei s %.1f" if gefangen else "gestorben (nicht gefangen) bei s %.1f")
				% _tod_s)
	elif _bild >= FALL_MAX:
		teile.append("nicht fertig nach %d s" % (FALL_MAX / 60))
		_fall_fehler.append("in %d s nicht fertig (zuletzt s %.1f)" % [FALL_MAX / 60, _letzte_s])
	else:
		teile.append("überlebt bis s %.1f" % _letzte_s)
	if not is_inf(_min_abstand):
		teile.append("Mindestabstand %.2f m bei s %.1f" % [_min_abstand, _min_s])
	if not is_nan(_weck):
		teile.append("Wecken %.2f m" % _weck)
		if _weck_bild >= 0 and not _tot:
			teile.append("Zeit ab Wecken %.2f s" % (float(_bild - _weck_bild) / 60.0))
	teile.append("Stolpern %d%s" % [_stolpern,
			(" (%s)" % ", ".join(_stolper_orte)) if _stolpern > 0 else ""])
	if _krabbel_bilder > 0:
		teile.append("Krabbeln %.2f s" % (float(_krabbel_bilder) / 60.0))
	teile.append("Hopser %d" % _hopser)
	var gebrochen := 0
	var durchlaesse: Array = z["durchlaesse"]
	for d: Dictionary in durchlaesse:
		if bool(d["gebrochen"]):
			gebrochen += 1
	teile.append("Durchlässe gebrochen %d/%d" % [gebrochen, durchlaesse.size()])
	if _fall.has("ende_ziel"):
		teile.append("geschafft %d×, Keiler %s bei %.2f" % [_geschafft - _geschafft_vorher,
				String(z["lage"]), float(z["keiler_s"])])
	print("JAGD %-32s %s%s" % [name, ", ".join(teile), vorspann])

	if erwartet == "gefangen":
		if not _tot:
			_fall_fehler.append("Gegenprobe: nicht gefangen (Mindestabstand %.2f m) – die Kette verzeiht hier zu viel"
					% _min_abstand)
		elif not gefangen:
			_fall_fehler.append("gestorben bei s %.1f, aber nicht vom Verfolger" % _tod_s)
	elif _tot:
		_fall_fehler.append("%s bei s %.1f, soll überleben"
				% ["gefangen" if gefangen else "gestorben", _tod_s])
	var soll_stolpern := int(_fall.get("stolpern", 0))
	if _stolpern != soll_stolpern:
		_fall_fehler.append("%d× gestolpert, soll %d×" % [_stolpern, soll_stolpern])
	if _fall.has("min_abstand") and not _tot:
		var min_soll: float = _fall["min_abstand"]
		if _min_abstand < min_soll:
			_fall_fehler.append("Mindestabstand %.2f m unter %.2f" % [_min_abstand, min_soll])
	if _fall.has("weck_abstand"):
		var weck_soll: Vector2 = _fall["weck_abstand"]
		if is_nan(_weck):
			_fall_fehler.append("der Verfolger wurde nicht geweckt")
		elif absf(_weck - weck_soll.x) > weck_soll.y + 0.0001:
			_fall_fehler.append("Abstand beim Wecken %.2f, soll %.2f ± %.2f"
					% [_weck, weck_soll.x, weck_soll.y])
	if _fall.has("ende_ziel"):
		var mal := _geschafft - _geschafft_vorher
		if mal != 1:
			_fall_fehler.append("level_geschafft %d×, soll genau 1×" % mal)
		if String(z["lage"]) != "ufer":
			_fall_fehler.append("nach dem Ziel steht der Verfolger nicht am Ufer (%s bei %.2f)"
					% [String(z["lage"]), float(z["keiler_s"])])
	for f in _fall_fehler:
		_fehler += 1
		print("  FEHLER  %s: %s" % [name, f])


func _gesamt_auswerten() -> void:
	var z: Dictionary = _level.call("jagd_zustand")
	print("JAGD Keilerhöhe: %d Hopser im Level; außerhalb höchstens %.3f m neben boden_bei (%d Bilder), im Hopser %s (%d Bilder)"
			% [int(z.get("hopser_zahl", 0)), _hoehe_max, _hoehe_bilder,
			"nie unter der Decke" if _unter_max <= HOEHE_SPIEL
			else "bis %.3f m UNTER der Decke" % _unter_max, _hopser_bilder])
	if _hoehe_max > HOEHE_SPIEL:
		_fehler += 1
		print("  FEHLER  Keilerhöhe außerhalb der Hopser bis %.3f m neben boden_bei (höchstens %.2f)"
				% [_hoehe_max, HOEHE_SPIEL])
	if _unter_max > HOEHE_SPIEL:
		_fehler += 1
		print("  FEHLER  Keiler im Hopser bis %.3f m unter der Decke" % _unter_max)
	print("JAGD Keiler höchstens bei s %.2f (Ufer %.2f)" % [_keiler_max, _ufer_s])
	if _keiler_max > _ufer_s + 0.001:
		_fehler += 1
		print("  FEHLER  Keiler bis s %.2f, über das Ufer %.2f hinaus" % [_keiler_max, _ufer_s])


# =========================================================== Lenker

## Jeder Physikschritt vor der Figur: messen, Ende prüfen, lenken.
func _lenken() -> void:
	if not _aktiv or _fertig:
		return
	_bild += 1
	var z: Dictionary = _level.call("jagd_zustand")
	var s: float = _level.call("strecke_der_figur")
	if _tot:
		_fertig = true
		return
	_messen(z, s)
	if _ende_erreicht(s):
		_fertig = true
		InputHub.zuruecksetzen()
		return
	_steuern(s, _spieler.is_on_floor())
	_letzte_s = s


func _messen(z: Dictionary, s: float) -> void:
	var lage: String = z["lage"]
	var keiler_s: float = z["keiler_s"]
	_ufer_s = float(z["ufer_s"])
	if lage == "jagd":
		var abstand := s - keiler_s
		if abstand < _min_abstand:
			_min_abstand = abstand
			_min_s = s
		if _schlief and is_nan(_weck) and not is_nan(float(z["weck_abstand"])):
			_weck = z["weck_abstand"]
			_weck_bild = _bild
	if lage == "ufer" and _ufer_bild < 0:
		_ufer_bild = _bild
	_keiler_max = maxf(_keiler_max, keiler_s)
	var dy := float(z["keiler_y"]) - float(z["boden_y"])
	var hopser: bool = z["hopser"]
	if hopser:
		_unter_max = maxf(_unter_max, -dy)
		_hopser_bilder += 1
		if not _war_hopser:
			_hopser += 1
	else:
		_hoehe_max = maxf(_hoehe_max, absf(dy))
		_hoehe_bilder += 1
	_war_hopser = hopser
	var bruch_vor: float = z["bruch_vor"]
	for d: Dictionary in z["durchlaesse"]:
		var ds: float = d["s"]
		var soll := lage != "schlaf" and keiler_s >= ds - bruch_vor
		var gebrochen: bool = d["gebrochen"]
		if (gebrochen != soll or bool(d["koerper_an"]) == gebrochen) \
				and not _durchlass_gemeldet.has(ds):
			_durchlass_gemeldet[ds] = true
			_fall_fehler.append("Durchlass bei s %.1f: gebrochen %s, Körper an %s, Keiler bei %.2f (Bruch ab %.2f)"
					% [ds, str(gebrochen), str(d["koerper_an"]), keiler_s, ds - bruch_vor])
	var rest: Variant = _spieler.get("_stolpern")
	var stolpert := rest is float and float(rest) > 0.0
	if stolpert and not _stolperte:
		_stolpern += 1
		_stolper_orte.append("s %.1f" % s)
	_stolperte = stolpert
	if _spieler.get("kriechen") == true:
		_krabbel_bilder += 1


func _ende_erreicht(s: float) -> bool:
	if _bild >= FALL_MAX:
		return true
	if _fall.has("ende_s"):
		return s >= float(_fall["ende_s"]) and _spieler.is_on_floor()
	if _fall.has("ende_dauer"):
		return _bild >= roundi(float(_fall["ende_dauer"]) * 60.0)
	if _fall.has("ende_ufer"):
		return _ufer_bild >= 0 and _bild - _ufer_bild >= roundi(float(_fall["ende_ufer"]) * 60.0)
	if _fall.has("ende_ziel"):
		if _ziel_bild < 0 and _geschafft > _geschafft_vorher:
			_ziel_bild = _bild
		return _ziel_bild >= 0 and _bild - _ziel_bild >= roundi(float(_fall["ende_ziel"]) * 60.0)
	return false


func _steuern(s: float, am_boden: bool) -> void:
	if _slide_los:
		InputHub.touch_slide(false)
		_slide_los = false
	# Laufende Tasten und Zustände
	if _taste_sprung:
		if not am_boden:
			_in_luft = true
		if _doppel_bilder > 0:
			if _bild == _sprung_bild + _doppel_bilder - 1:
				InputHub.touch_sprung(false)
			elif _bild == _sprung_bild + _doppel_bilder and not am_boden:
				InputHub.touch_sprung(true)
		if _in_luft and am_boden:
			InputHub.touch_sprung(false)
			_taste_sprung = false
	if not is_nan(_halten_bis) and s >= _halten_bis:
		InputHub.touch_slide(false)
		_halten_bis = NAN
	_stolpern_fuehren(s, am_boden)
	# Neue Aktionen, der Reihe nach
	for i in _aktionen.size():
		if _ausgeloest[i]:
			continue
		var a := _aktionen[i]
		if s < float(a["s"]):
			break
		if not _ausloesen(a, i, am_boden):
			break
		_ausgeloest[i] = true
	# Richtung
	var eingabe := Vector2.ZERO
	if not _schweben.is_finite():
		if _warten_rest > 0:
			_warten_rest -= 1
		elif not _stehen:
			var hin := _level.to_global(LevelWerkzeuge.punkt_frei(_verlauf, s + VORAUS,
					_spur_q(s + VORAUS)))
			var d := hin - _spieler.global_position
			d.y = 0.0
			eingabe = _eingabe_fuer(d.normalized())
	else:
		_spieler.global_position = _schweben
		_spieler.velocity = Vector3.ZERO
	InputHub.touch_bewegung = eingabe


## Löst eine Aktion aus; false, wenn sie noch warten muss (nicht am Boden).
func _ausloesen(a: Dictionary, i: int, am_boden: bool) -> bool:
	match String(a["tun"]):
		"sprung", "doppel":
			if not am_boden:
				return false
			InputHub.touch_sprung(true)
			_taste_sprung = true
			_in_luft = false
			_sprung_bild = _bild
			_doppel_bilder = -1
			if String(a["tun"]) == "doppel":
				_doppel_bilder = maxi(roundi(float(a["nach"]) * 60.0), 2)
		"slide":
			if not am_boden:
				return false
			InputHub.touch_slide(true)
			_slide_los = true
		"slide_halten":
			if not am_boden:
				return false
			InputHub.touch_slide(true)
			_halten_bis = a["bis"]
		"stolpern":
			_stolper_aktion = i
			_stolper_phase = 0
		"warten":
			if not am_boden and not bool(a.get("sofort", false)):
				return false
			_warten_rest = roundi(float(a["dauer"]) * 60.0)
		"stehen":
			_stehen = true
		"schweben":
			var ort: Vector3 = _level.call("weg_punkt", float(a["an"]), 0.0, SCHWEBEN_HOEHE)
			_schweben = _level.to_global(ort)
		_:
			_fall_fehler.append("unbekannte Aktion \"%s\"" % String(a["tun"]))
	return true


## Stolpern (siehe Kopf): hineinlaufen, stolpern, Reaktion, Slide aus dem
## Stand.
func _stolpern_fuehren(s: float, am_boden: bool) -> void:
	if _stolper_aktion < 0:
		return
	var a := _aktionen[_stolper_aktion]
	match _stolper_phase:
		0:
			if _stolperte:
				_stolper_phase = 1
			elif s > float(a["bis"]):
				_fall_fehler.append("an %s nicht gestolpert" % String(a.get("wo", "?")))
				_stolper_aktion = -1
		1:
			if not _stolperte:
				_stolper_phase = 2
				_reaktion_rest = roundi(float(a.get("reaktion", 0.0)) * 60.0)
		2:
			if _reaktion_rest > 0:
				_reaktion_rest -= 1
			elif am_boden:
				InputHub.touch_slide(true)
				_slide_los = true
				_stolper_aktion = -1


## Querlage der Lauflinie an der Stelle `s`.
func _spur_q(s: float) -> float:
	if _spur.is_empty():
		return 0.0
	if s <= _spur[0].x:
		return _spur[0].y
	for i in _spur.size() - 1:
		var a := _spur[i]
		var b := _spur[i + 1]
		if s <= b.x:
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	return _spur[_spur.size() - 1].y


## Welt-Richtung -> Stick, kamerarelativ wie die echte Steuerung.
func _eingabe_fuer(d: Vector3) -> Vector2:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return Vector2(d.x, d.z)
	var vor := -kamera.global_transform.basis.z
	vor.y = 0.0
	vor = vor.normalized()
	var rechts := kamera.global_transform.basis.x
	rechts.y = 0.0
	rechts = rechts.normalized()
	return Vector2(d.dot(rechts), -d.dot(vor))


func _alle(wurzel: Node) -> Array[Node]:
	var liste: Array[Node] = []
	for kind in wurzel.get_children():
		liste.append(kind)
		liste.append_array(_alle(kind))
	return liste
