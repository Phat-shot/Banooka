extends Node
class_name L05Jagd
## Level 05, Modul „Jagd": der Keiler als Abstand auf der Strecke (Entwurf
## L05 §9.1, §1 Nr. 10, 15 und 16, §2.1, §6.5, §8.4).
##
## Der Keiler ist kein Gegner mit Trefferzone, sondern eine Stelle `s` auf
## dem Verlauf, die mit festem Tempo (TEMPO, knapp unter dem Lauftempo 8,5)
## der Figur nachläuft und nie weiter als HOECHSTABSTAND zurückfällt. Wer
## läuft, hält ihn hinten; wer steht, stolpert oder zögert, wird eingeholt –
## ab FANGABSTAND ist die Figur tot. So steht es in CLAUDE.md („festes
## Tempo"), und die Konstanten sind die alten aus level05.gd unverändert.
##
## ABLAUF (Lage):
##   SCHLAF   bei SCHLAF_S / SCHLAF_Q in der Suhle, rührt sich nicht. Vor CP1
##            ist kein Tod möglich, die Suhle ist Lehrstrecke ohne Druck.
##   Wecken   sobald die Figur WECK_S erreicht – dieselbe Stelle wie der
##            erste Rastplatz (CP1). Abstand dann genau WECK_S − SCHLAF_S =
##            15 m = HOECHSTABSTAND (`weck_abstand`, gemessen VOR seinem
##            ersten Schritt). WARUM nach der Strecke und nicht über die
##            Zone des Rastplatzes: Die Zone ist 2 m tief, ihr Eintritt läge
##            1,4 m früher, der Abstand also nicht mehr 15; und wer sie mit
##            einem Doppelsprung überspringt, weckt ihn trotzdem.
##   JAGD     mit TEMPO, Höhe aus `boden_bei` plus Hopser (unten), seitlich
##            QUER_ANTEIL der Querlage der Figur.
##   UFER     bei UFER_S bleibt er stehen (das gebrochene Wehr L6 beginnt
##            bei 284) und schnaubt – als ZUSTAND, nicht als Augenblick: Er
##            bleibt am Ufer stehen und schnaubt weiter, auch wenn die Figur
##            längst im Zielportal ist (Entwurf §5 E, JT20). Wer an der Kante
##            zögert, wird noch gefangen (bis s 284,0 = UFER_S + FANGABSTAND);
##            über der Lücke ist man ab s 284,5 sicher.
## Ein Ziel-Auslöser gibt es hier nicht: Ziel ist allein das Zielportal
## (Entwurf §1 Nr. 15, `_auf_level_geschafft` ist nicht gegen Doppelaufruf
## geschützt).
##
## HOPSER (Entwurf §9.1, §8.4; nur Optik, der Abstand rechnet weiter auf
## der Strecke). Wo der Weg springt, springt der Keiler: über jede Lücke,
## jede Stufe (zwei Wegstücke, deren Decken mehr als STUFE_MIN auseinander
## liegen: Suhlgraben, Wurzeltreppen) und jede Hürde. Ein Hopser beginnt
## HOPS_ANLAUF vor dem Hindernis und landet HOPS_ANLAUF dahinter; was sich
## dabei überlappt (die zwei Tritte einer Wurzeltreppe), wird EIN Hopser.
## Der Scheitel liegt HOPS_GRUND + HOPS_JE_METER · Weite über der höheren
## Lippe (Weite = Länge des Hindernisses längs, bei einer Stufe 0), über
## einer Hürde HOPS_HUERDE über dem Boden – so lese ich „Hürde 0,6" des
## Entwurfs: kleiner als jeder andere Hopser, die Hürde reicht ihm nur ans
## Knie (0,7 bei 2,6 m Schulter); die Beine zieht die Optik mit `in_luft`
## an (P5). Die Bahn ist eine Wurfparabel
## von Lippe zu Lippe durch diesen Scheitel. WARUM die Lücken über
## `Wegdaten.abschnitte` und nicht über `boden_bei`: `boden_bei` liefert in
## einer Lücke die Höhe zwischen den Lippen (Baukasten §4 Nr. 6) – eine
## Lücke sähe man daran nicht; erst der Abstand zwischen zwei Abschnitten
## zeigt sie. Außerhalb eines Hopsers steht er genau auf `boden_bei` (die
## Jagdprobe misst ≤ 0,05 m).
##
## FINDLINGSGASSE (Entwurf §5 D; P5-Prüfung): Der Keiler ist gut 5 m lang
## (Schnauze 3,2 m vor, Schwanz 2,1 m hinter dem Ursprung) und 1,7 m breit,
## die Gasse zwischen F1 und F2 nur 4,4 m lang – auf der Querlage der Figur
## lief er sichtbar durch beide Steine. Über F1 springt er deshalb (Hopser
## von KEILER_VORN vor der Stirn bis KEILER_HINTEN hinter dem Rücken, mit
## FINDLING_ANLAUF davor und dahinter, Scheitel HOPS_FINDLING: So liegen
## Hufe und Bauch über 1,4 m, solange sie über dem Stein sind). Noch in der
## Luft schwenkt er auf die freie Seite von F2 und läuft dort vorbei
## (`_gassenlage`). Nur Optik: Der Abstand rechnet weiter auf der Strecke.
##
## HANGNEIGUNG als Wert (`hangneigung`): Gefälle der Decke über
## ± NEIGUNG_BASIS in Laufrichtung, in Radiant, positiv bergab; im Hopser
## das mittlere Gefälle von Lippe zu Lippe (die Flughaltung selbst sagt
## `in_luft`). WARUM nicht das Gefälle der Flugbahn: Am Absprung steht die
## Parabel bis 0,89 rad (51°) steil (gemessen) – so kippte die Optik den
## Keiler bei jedem Hopser fast auf den Rücken. Außerhalb der Hopser greift
## die Messung nie über eine Stufe (die Hopser beginnen HOPS_ANLAUF =
## NEIGUNG_BASIS davor). Die Optik kippt ihn damit in P5.
##
## DURCHLASS-BRUCH (Entwurf §9.1, §8.4): Erreicht er die Stirn eines
## Durchlasses bis auf BRUCH_VOR, bricht er hindurch – der Körper (Ebene 16)
## und die Stolperzone gehen aus, die heile Optik geht aus, der Bruch
## („Bruch", von `L05Wegbauten` an den Körper gehängt) geht an. Alles
## über den Körper, den `KorridorLevel.duckdurchlass` zurückgibt; das
## Bauteil selbst bleibt unverändert. Die Figur stört das nie: Ist er bis
## Stirn − 1,5 heran, steht sie – lebend – mindestens 0,5 m hinter der Stirn
## (FANGABSTAND 2).
## HEILEN nach einem Tod (`nach_tod`, Gruppe `LevelBasis.NACH_TOD`): Ein
## Durchlass ist danach genau dann gebrochen, wenn der Keiler an seiner
## neuen Stelle schon bis Stirn − BRUCH_VOR heran ist. Alle Durchlässe
## hinter dem Rastplatz sind damit wieder heil (Entwurf §6.5); die, über die
## er schon hinaus steht, bleiben gebrochen.
##
## NACH EINEM TOD steht der Keiler VORSPRUNG hinter dem Rastplatz, an dem
## die Figur wieder erscheint – genau, nicht über `get_closest_offset` des
## Checkpoints: Der Checkpoint liegt 0,6 m über der Decke, die Decke bis
## 0,64 m neben der Kurve, und am Gefälle lag die Strecke daraus bis
## 0,083 m zu kurz (gemessen an CP2, an CP4 0,080). Liegt der Rastplatz vor
## WECK_S – Start oder Game Over –, schläft er wieder an seinem Platz.
##
## HALTUNGEN rufe ich am Keiler nur, wenn er sie kennt (`has_method`; die
## Optik steht in keiler.gd, Paket P5). Ruft:
##   schlafen()               beim Einschlafen (Start, Tod vor CP1)
##   erwachen()               beim Wecken (Entwurf: 0,5 s im Lauf)
##   aufstehen()              wenn er ohne Wecken aus dem Schlaf in die Jagd
##                            oder ans Ufer kommt (Respawn an einem Rastplatz,
##                            Ruhe der Proben): sofort wach, ohne Effekte
##   in_luft(an: bool)        zu Beginn und am Ende jedes Hopsers
##   schnauben()              bei der Ankunft am Ufer; der Zustand hält an
##   hangneigung(winkel)      jedes Bild, Radiant, positiv bergab
##   durchbrechen(ort, wasser)  wenn er in der Jagd durch einen Durchlass
##                            bricht (nicht beim Heilen und Versetzen): Ort
##                            des Bruchs und, am Fluderjoch, des Gerinnes
##                            (Metadaten "gerinne" am Körper), sonst INF
## Laufen ergibt sich wie bisher aus `aktualisiere(delta, tempo, naehe)`:
## Tempo 1 in der Jagd, 0 am Ufer.
##
## RUHE (`pruefruhe`, Entwurf §1 Nr. 16): Für Sprungprobe, LevelCheck und
## Fotos fängt er nicht und läuft nicht von selbst. Er steht dann in der
## Ruhestellung: VORSPRUNG hinter der Figur (am Ufer höchstens bis UFER_S),
## vor WECK_S schlafend an seinem Platz – und bleibt dort, wohin die Probe
## die Figur auch setzt (jedes Bild neu gestellt), mit Hopser, Neigung und
## gebrochenen Durchlässen wie im Spiel an dieser Stelle. Ein Durchlass
## bricht dort erst, wenn die Figur 10,5 m hinter seiner Stirn steht – keine
## Probe misst dann noch an ihm. Nach einem Tod bleibt die Ruhe.
##
## Die Strecke der Figur kommt aus `LevelBasis.strecke_der_figur()`.

## Gefangen: unmittelbar bevor die Figur stirbt (für Proben, später Optik).
signal gefangen(abstand: float)

const KEILER := preload("res://scenes/enemies/Keiler.tscn")

## Die Jagd (unverändert aus dem alten level05.gd): 7,4 m/s – wer
## durchläuft, hält ihn hinten; wer steht, hat ihn aus 15 m in zwei
## Sekunden an den Fersen.
const TEMPO := 7.4
const VORSPRUNG := 12.0
const HOECHSTABSTAND := 15.0
const FANGABSTAND := 2.0
## Stolperdauer an Hürden, Durchlässen und Findlingen (`Spieler.stolpern`).
const STOLPER_DAUER := 0.45
## Schlafplatz in der Suhle und die Stelle des Weckens (= CP1).
const SCHLAF_S := 16.0
const SCHLAF_Q := -4.5
const WECK_S := 31.0
## Hier am Ufer vor dem Wehr bleibt er stehen.
const UFER_S := 282.0
## Seitlich folgt er der Figur zu diesem Anteil ihrer Querlage.
const QUER_ANTEIL := 0.4
## Rastplätze, deren Strecke weniger als das vor WECK_S liegt, zählen als
## „vor dem Wecken" (der Checkpoint liegt 0,6 m über der Decke, seine
## Strecke ist also nicht ganz genau 31).
const WECK_SPIEL := 0.5
## Ein Checkpoint gehört zu einem Rastplatz, wenn er höchstens so weit von
## dessen Ort (Decke + 0,6 m) liegt.
const RASTPLATZ_NAEHE := 1.0

## Hopser (siehe Kopf): Scheitel über der höheren Lippe.
const HOPS_GRUND := 0.8
const HOPS_JE_METER := 0.25
const HOPS_HUERDE := 0.6
## Absprung so weit vor dem Hindernis, Landung so weit dahinter.
const HOPS_ANLAUF := 1.0
## Ab diesem Höhenunterschied zwischen zwei Wegstücken ist dort eine Stufe.
## Kleiner als jeder Tritt (0,6), größer als jede Naht.
const STUFE_MIN := 0.2
## Hangneigung über ± so viel Strecke.
const NEIGUNG_BASIS := 1.0
## Durchlass-Bruch ab keiler_s ≥ Stirn − BRUCH_VOR (Entwurf §9.1).
const BRUCH_VOR := 1.5
## Findlingsgasse (siehe Kopf): Reichweite des Leibs vor und hinter dem
## Ursprung, halbe Breite samt Luft, Anlauf und Scheitel des Hopsers über
## F1, Übergang der Querlage an F2. Nachgerechnet (ohne Gefälle): Mit
## Scheitel 1,7 über 8,7 m liegt der Ursprung, solange Vorder- oder
## Hinterhufe über F1 sind, mindestens 0,97 m über der oberen Lippe; die
## eingezogenen Hufe hängen 0,35 m über dem Ursprung, im Sprung hebt sich der
## Leib um 0,12 m – zusammen 1,44 m über 1,4. Am Gefälle der Gasse (rund 7 %)
## liegt die Decke am Stein noch 0,1–0,3 m tiefer als die Lippe.
const KEILER_VORN := 2.0
const KEILER_SCHNAUZE := 3.2
const KEILER_HINTEN := 2.1
const KEILER_HALB := 0.95
const FINDLING_ANLAUF := 1.5
const HOPS_FINDLING := 1.7
const GASSE_UEBERGANG := 2.5

enum Lage { SCHLAF, JAGD, UFER }

var _level: Level05
var _keiler: Keiler
var _figur: Spieler
var _lage := Lage.SCHLAF
var _keiler_s := SCHLAF_S
## Erst nach dem Rundgang (`freigeben`), wenn die Figur losdarf.
var _frei := false
## Proben (siehe Kopf, RUHE).
var _ruhe := false
## Hopser je {von, bis, ya, yb, oben} (Welt-Y der Lippen und des Scheitels),
## nach `von` sortiert; aus `_hopser_rechnen`.
var _hopser: Array[Dictionary] = []
var _im_hopser := false
var _neigung := 0.0
## Abstand im Augenblick des Weckens (NAN, solange er schläft).
var _weck_abstand := NAN
## Körper der Durchlässe (vom Level) und ob sie gerade gebrochen sind.
var _durchlaesse: Array[StaticBody3D] = []
var _gebrochen: Array[bool] = []
## Wie oft er gefangen hat (für Proben).
var _faenge := 0


## Bauschritt des Levels: Keiler und Jagd anlegen, der Keiler schläft.
static func bauschritte(level: Level05) -> Array:
	return [{"text": "Der Keiler schläft", "tun": func() -> void: anlegen(level)}]


static func anlegen(level: Level05) -> L05Jagd:
	var jagd := L05Jagd.new()
	jagd.name = "Jagd"
	jagd._level = level
	level.add_child(jagd)
	jagd._keiler = KEILER.instantiate() as Keiler
	level.objekte.add_child(jagd._keiler)
	jagd._figur = level.get_tree().get_first_node_in_group("spieler") as Spieler
	if jagd._figur == null:
		push_warning("Level 05 ohne Spielfigur – ist Player.tscn in der Szene?")
	jagd._hopser = jagd._hopser_rechnen()
	jagd._durchlaesse.assign(level.durchlass_koerper)
	for i in jagd._durchlaesse.size():
		jagd._gebrochen.append(false)
	level.nach_tod_melden(jagd)
	level.jagd = jagd
	jagd._einschlafen()
	return jagd


## Ab jetzt läuft die Jagd (aus `Level05._vor_dem_start`).
func freigeben() -> void:
	_frei = true


## Siehe Kopf, RUHE. Darf beliebig oft gerufen werden.
func pruefruhe() -> void:
	_ruhe = true
	_ruhestellung(true)


## Schläft der Keiler noch? (Für Proben und Meldungen.)
func schlaeft() -> bool:
	return _lage == Lage.SCHLAF


## Stelle des Keilers auf dem Verlauf.
func keiler_strecke() -> float:
	return _keiler_s


## Hangneigung in Radiant, positiv bergab (siehe Kopf).
func hangneigung() -> float:
	return _neigung


## Zustand für Proben (`Level05.jagd_zustand`, werkzeuge/jagdprobe.gd).
func zustand() -> Dictionary:
	var d: Array[Dictionary] = []
	for i in _durchlaesse.size():
		var koerper := _durchlaesse[i]
		var an := false
		if is_instance_valid(koerper):
			an = true
			for kind in koerper.get_children():
				if kind is CollisionShape3D and (kind as CollisionShape3D).disabled:
					an = false
		d.append({"s": float(koerper.get_meta("strecke", 0.0)) if is_instance_valid(koerper) else 0.0,
				"gebrochen": _gebrochen[i], "koerper_an": an})
	var y := NAN
	if is_instance_valid(_keiler):
		y = _level.to_local(_keiler.global_position).y
	return {
		"lage": ["schlaf", "jagd", "ufer"][_lage],
		"keiler_s": _keiler_s,
		"keiler_y": y,
		"boden_y": _level.boden_bei(_keiler_s),
		"hopser": _im_hopser,
		"hopser_zahl": _hopser.size(),
		"neigung": _neigung,
		"weck_abstand": _weck_abstand,
		"faenge": _faenge,
		"durchlaesse": d,
		"ufer_s": UFER_S,
		"fangabstand": FANGABSTAND,
		"vorsprung": VORSPRUNG,
		"bruch_vor": BRUCH_VOR,
	}


func wecken() -> void:
	if _lage != Lage.SCHLAF:
		return
	_keiler_s = SCHLAF_S
	_weck_abstand = _level.strecke_der_figur() - SCHLAF_S
	_lage = Lage.JAGD
	_haltung("erwachen")


func nach_tod(_von_vorn: bool) -> void:
	if _ruhe:
		_ruhestellung(true)
		return
	var s_cp := _checkpoint_strecke()
	if s_cp < WECK_S - WECK_SPIEL:
		_einschlafen()
		return
	_keiler_s = minf(s_cp - VORSPRUNG, UFER_S)
	_lage_setzen(Lage.UFER if _keiler_s >= UFER_S else Lage.JAGD)
	_stellen(_keiler_s, 0.0, true)
	_durchlaesse_pruefen()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_figur) or not is_instance_valid(_keiler):
		return
	if _ruhe:
		_ruhestellung(false)
		return
	if not _frei:
		return
	var s_figur := _level.strecke_der_figur()
	if _lage == Lage.SCHLAF:
		if s_figur < WECK_S:
			return
		wecken()
	if _lage == Lage.JAGD:
		# Er läuft immer – und fällt nie weiter zurück als HOECHSTABSTAND.
		_keiler_s = maxf(_keiler_s + TEMPO * delta, s_figur - HOECHSTABSTAND)
		if _keiler_s >= UFER_S:
			_keiler_s = UFER_S
			_lage_setzen(Lage.UFER)
		_durchlaesse_pruefen(true)
	var abstand := s_figur - _keiler_s
	var naehe := 1.0 - clampf(abstand / HOECHSTABSTAND, 0.0, 1.0)
	_stellen(_keiler_s, _gassenlage(_keiler_s, _querlage(s_figur) * QUER_ANTEIL))
	_keiler.aktualisiere(delta, 1.0 if _lage == Lage.JAGD else 0.0, naehe)
	if abstand <= FANGABSTAND and _figur.invuln <= 0.0:
		_faenge += 1
		gefangen.emit(abstand)
		_figur.sterben()


func _einschlafen() -> void:
	_lage = Lage.SCHLAF
	_keiler_s = SCHLAF_S
	_weck_abstand = NAN
	_stellen(SCHLAF_S, SCHLAF_Q, true)
	_haltung("schlafen")
	_durchlaesse_pruefen()


## Lage wechseln; aus dem Schlaf ohne Wecken steht er sofort auf, am Ufer
## beginnt das Schnauben (siehe Kopf, HALTUNGEN).
func _lage_setzen(neu: Lage) -> void:
	if neu == _lage:
		return
	var aus_schlaf := _lage == Lage.SCHLAF
	_lage = neu
	if aus_schlaf and neu != Lage.SCHLAF:
		_haltung("aufstehen")
	if neu == Lage.UFER:
		_haltung("schnauben")


## Ruhestellung für Proben (siehe Kopf, RUHE). `versetzt` wie bei `_stellen`.
func _ruhestellung(versetzt: bool) -> void:
	if not is_instance_valid(_keiler):
		return
	var s_figur := _level.strecke_der_figur() if is_instance_valid(_figur) else 0.0
	if s_figur < WECK_S - WECK_SPIEL:
		if _lage != Lage.SCHLAF or versetzt:
			_einschlafen()
		return
	_keiler_s = minf(s_figur - VORSPRUNG, UFER_S)
	_lage_setzen(Lage.UFER if _keiler_s >= UFER_S else Lage.JAGD)
	_stellen(_keiler_s, _gassenlage(_keiler_s, _querlage(s_figur) * QUER_ANTEIL), versetzt)
	_durchlaesse_pruefen()


## Strecke des Rastplatzes, an dem die Figur wieder erscheint (siehe Kopf,
## NACH EINEM TOD); sonst die nächste Stelle der Kurve am Checkpoint.
func _checkpoint_strecke() -> float:
	for s in Level05.RASTPLAETZE:
		var ort := _level.to_global(_level.weg_punkt(s, 0.0, Level05.RASTPLATZ_UEBER))
		if ort.distance_to(GameState.checkpoint) <= RASTPLATZ_NAEHE:
			return s
	return _level.verlauf.get_closest_offset(_level.to_local(GameState.checkpoint))


## Der Keiler auf der Wegdecke bei (s, q), mit dem Weg gedreht, im Hopser
## auf seiner Bahn. `versetzt`: ein Sprung an einen anderen Ort
## (Schlafplatz, Rastplatz, Probe) – dann ohne Zwischenbild, sonst zöge
## Godot eine Spur dorthin. Im Lauf bleibt die Interpolation an, sonst
## ruckelte er bei mehr als 60 Bildern je Sekunde.
func _stellen(s: float, q: float, versetzt := false) -> void:
	if not is_instance_valid(_keiler):
		return
	var ort := _level.weg_punkt(s, q)
	ort.y = _hoehe(s)
	_keiler.global_position = _level.to_global(ort)
	_keiler.rotation.y = LevelWerkzeuge.drehung(_level.verlauf, s)
	if versetzt:
		_keiler.reset_physics_interpolation()
	var im_hopser := not _hopser_bei(s).is_empty()
	if im_hopser != _im_hopser:
		_im_hopser = im_hopser
		_haltung("in_luft", [im_hopser])
	_neigung = _neigung_bei(s)
	_haltung("hangneigung", [_neigung])


## Ruft eine Haltung am Keiler, wenn er sie kennt (siehe Kopf, HALTUNGEN).
func _haltung(methode: String, argumente: Array = []) -> void:
	if is_instance_valid(_keiler) and _keiler.has_method(methode):
		_keiler.callv(methode, argumente)


## Querlage des Keilers bei `s`: `q`, an F2 auf die freie Seite geklemmt
## (siehe Kopf, FINDLINGSGASSE) – voll, solange ein Teil des Leibs neben F2
## ist, davor (in der Luft über F1) und danach weich über GASSE_UEBERGANG.
func _gassenlage(s: float, q: float) -> float:
	if Level05.FINDLINGE.size() < 2:
		return q
	var f: Dictionary = Level05.FINDLINGE[1]
	var mitte: float = f["s"]
	var halb_tief := KorridorLevel.FINDLING_TIEFE * 0.5
	var seite := -signf(float(f["q"]))
	var grenze := float(f["q"]) + seite * (float(f["breite"]) * 0.5 + KEILER_HALB)
	var von := mitte - halb_tief - KEILER_SCHNAUZE
	var bis := mitte + halb_tief + KEILER_HINTEN
	var w := smoothstep(von - GASSE_UEBERGANG, von, s) \
			* (1.0 - smoothstep(bis, bis + GASSE_UEBERGANG, s))
	if w <= 0.0:
		return q
	var frei := minf(q, grenze) if seite < 0.0 else maxf(q, grenze)
	return lerpf(q, frei, w)


## Querlage der Figur an ihrer Strecke (positiv = rechts).
func _querlage(s: float) -> float:
	if not is_instance_valid(_figur):
		return 0.0
	var mitte := _level.verlauf.sample_baked(clampf(s, 0.0, _level.verlauf.get_baked_length()))
	var versatz := _level.to_local(_figur.global_position) - mitte
	versatz.y = 0.0
	return versatz.dot(LevelWerkzeuge.richtung(_level.verlauf, s).cross(Vector3.UP).normalized())


# =========================================================== Hopser

## Welt-Y (Level) des Keilers an der Stelle `s`: im Hopser seine Bahn,
## sonst die Decke.
func _hoehe(s: float) -> float:
	var h := _hopser_bei(s)
	if h.is_empty():
		return _level.boden_bei(s)
	return _bahn(h, s)


## Hangneigung an der Stelle `s` (siehe Kopf, HANGNEIGUNG).
func _neigung_bei(s: float) -> float:
	var h := _hopser_bei(s)
	if not h.is_empty():
		return atan2(float(h["ya"]) - float(h["yb"]), float(h["bis"]) - float(h["von"]))
	return atan2(_level.boden_bei(s - NEIGUNG_BASIS) - _level.boden_bei(s + NEIGUNG_BASIS),
			2.0 * NEIGUNG_BASIS)


func _hopser_bei(s: float) -> Dictionary:
	for h in _hopser:
		if s < float(h["von"]):
			break
		if s <= float(h["bis"]):
			return h
	return {}


## Wurfparabel von (von, ya) nach (bis, yb) mit dem Scheitel `oben`: Mit
## p = oben − ya und q = oben − yb liegt der Scheitel bei
## t0 = √p / (√p + √q), und y(t) = oben − p · ((t − t0) / t0)² trifft bei
## t = 1 genau yb.
static func _bahn(h: Dictionary, s: float) -> float:
	var oben: float = h["oben"]
	var p := oben - float(h["ya"])
	var q := oben - float(h["yb"])
	var t0 := sqrt(p) / (sqrt(p) + sqrt(q))
	var t := inverse_lerp(float(h["von"]), float(h["bis"]), s)
	return oben - p * pow((t - t0) / t0, 2.0)


## Die Hopser aus den Wegstücken und den Hürden (siehe Kopf, HOPSER). Nur
## bis UFER_S: Weiter kommt er nicht.
func _hopser_rechnen() -> Array[Dictionary]:
	var hindernisse: Array[Dictionary] = []
	var stuecke: Array[Dictionary] = _level.weg.abschnitte.duplicate()
	stuecke.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["von"]) < float(b["von"]))
	for i in stuecke.size() - 1:
		var e: Dictionary = stuecke[i]
		var f: Dictionary = stuecke[i + 1]
		var ende: float = e["bis"]
		var anfang: float = f["von"]
		if anfang > ende + 0.001:
			hindernisse.append({"a": ende, "b": anfang, "huerde": false})
		elif absf(LevelWerkzeuge.eintrag_hoehe(_level.verlauf, e, ende)
				- LevelWerkzeuge.eintrag_hoehe(_level.verlauf, f, anfang)) > STUFE_MIN:
			hindernisse.append({"a": ende, "b": ende, "huerde": false})
	for h: Dictionary in Level05.HUERDEN:
		var mitte: float = h["s"]
		var halb := KorridorLevel.HUERDE_TIEFE * 0.5
		hindernisse.append({"a": mitte - halb, "b": mitte + halb, "huerde": true})
	if not Level05.FINDLINGE.is_empty():
		var f1: Dictionary = Level05.FINDLINGE[0]
		var halb_f := KorridorLevel.FINDLING_TIEFE * 0.5
		hindernisse.append({"a": float(f1["s"]) - halb_f - KEILER_VORN,
				"b": float(f1["s"]) + halb_f + KEILER_HINTEN, "huerde": false, "findling": true})
	hindernisse.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["a"]) < float(b["a"]))
	# Überlappende zu einem zusammenfassen.
	var gruppen: Array[Dictionary] = []
	for h in hindernisse:
		if not gruppen.is_empty():
			var letzte: Dictionary = gruppen[gruppen.size() - 1]
			if float(h["a"]) - HOPS_ANLAUF <= float(letzte["b"]) + HOPS_ANLAUF:
				letzte["b"] = maxf(float(letzte["b"]), float(h["b"]))
				letzte["huerde"] = bool(letzte["huerde"]) and bool(h["huerde"])
				letzte["findling"] = bool(letzte.get("findling", false)) or bool(h.get("findling", false))
				continue
		gruppen.append(h.duplicate())
	var liste: Array[Dictionary] = []
	for g in gruppen:
		var a: float = g["a"]
		var b: float = g["b"]
		var anlauf := FINDLING_ANLAUF if bool(g.get("findling", false)) else HOPS_ANLAUF
		var von := a - anlauf
		var bis := b + anlauf
		if von >= UFER_S:
			continue
		if bis > UFER_S:
			push_warning("Level 05: Hopser %.1f–%.1f reicht über das Ufer (%.0f)" % [von, bis, UFER_S])
		var ya := _level.boden_bei(von)
		var yb := _level.boden_bei(bis)
		var scheitel := HOPS_HUERDE if bool(g["huerde"]) else HOPS_GRUND + HOPS_JE_METER * (b - a)
		if bool(g.get("findling", false)):
			scheitel = HOPS_FINDLING
		liste.append({"von": von, "bis": bis, "ya": ya, "yb": yb,
				"oben": maxf(ya, yb) + scheitel})
	return liste


# =========================================================== Durchlässe

## Jeden Durchlass auf den Stand bringen, der zur Stelle des Keilers passt
## (siehe Kopf, DURCHLASS-BRUCH und HEILEN). `wirkung`: in der Jagd – dann
## bricht er sichtbar hindurch (`durchbrechen`).
func _durchlaesse_pruefen(wirkung: bool = false) -> void:
	for i in _durchlaesse.size():
		var koerper := _durchlaesse[i]
		if not is_instance_valid(koerper):
			continue
		var stirn: float = koerper.get_meta("strecke", 0.0)
		var soll := _lage != Lage.SCHLAF and _keiler_s >= stirn - BRUCH_VOR
		if soll != _gebrochen[i]:
			_durchlass_stellen(i, soll, wirkung)


## Körper und Stolperzone aus bzw. an, heile Optik und Bruch umschalten
## (`L05Wegbauten.bruch_stellen`, aufgeschoben, weil das mitten im
## Physikschritt geschieht – dieselbe Schaltung zeigt die Werkstatt).
func _durchlass_stellen(i: int, gebrochen: bool, wirkung: bool = false) -> void:
	_gebrochen[i] = gebrochen
	var koerper := _durchlaesse[i]
	if gebrochen and wirkung:
		var mitte := float(koerper.get_meta("strecke", 0.0)) \
				+ float(koerper.get_meta("tiefe", 0.0)) * 0.5
		var q := _querlage(_level.strecke_der_figur()) * QUER_ANTEIL
		var ort := _level.to_global(_level.weg_punkt(mitte, q, 1.2))
		var wasser := Vector3.INF
		if koerper.has_meta("gerinne"):
			wasser = _level.to_global(_level.weg_punkt(mitte, q, float(koerper.get_meta("gerinne"))))
		_haltung("durchbrechen", [ort, wasser])
	L05Wegbauten.bruch_stellen(koerper, gebrochen)
