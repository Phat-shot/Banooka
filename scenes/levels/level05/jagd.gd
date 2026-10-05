extends Node
class_name L05Jagd
## Level 05, Modul „Jagd": der Keiler als Abstand auf der Strecke (Entwurf
## L05 §9.1, §1 Nr. 10, 15 und 16, §2.1).
##
## Der Keiler ist kein Gegner mit Trefferzone, sondern eine Stelle `s` auf
## dem Verlauf, die mit festem Tempo (TEMPO, knapp unter dem Lauftempo 8,5)
## der Figur nachläuft und nie weiter als HOECHSTABSTAND zurückfällt. Wer
## läuft, hält ihn hinten; wer steht, stolpert oder zögert, wird eingeholt –
## ab FANGABSTAND ist die Figur tot. So steht es in CLAUDE.md („festes
## Tempo"), und die Konstanten sind die alten aus level05.gd unverändert.
##
## ABLAUF:
##   Schlaf   bei SCHLAF_S / SCHLAF_Q in der Suhle, rührt sich nicht. Vor CP1
##            ist kein Tod möglich, die Suhle ist Lehrstrecke ohne Druck.
##   Wecken   sobald die Figur WECK_S erreicht – dieselbe Stelle wie der
##            erste Rastplatz (CP1). Abstand dann genau WECK_S − SCHLAF_S =
##            15 m = HOECHSTABSTAND. WARUM nach der Strecke und nicht über
##            die Zone des Rastplatzes: Die Zone ist 2 m tief, ihr Eintritt
##            läge 1,4 m früher, der Abstand also nicht mehr 15; und wer sie
##            mit einem Doppelsprung überspringt, weckt ihn trotzdem.
##   Jagd     mit TEMPO, Stellung `boden_bei` (Höhe der Wegdecke, in Lücken
##            zwischen den Lippen) und seitlich QUER_ANTEIL der Querlage der
##            Figur, wie vorher.
##   Ufer     bei UFER_S bleibt er stehen (das gebrochene Wehr L6 beginnt
##            bei 284). Wer an der Kante zögert, wird noch gefangen; über
##            der Lücke ist man ab s 284 sicher. Gefangen wird auch dort nur
##            nach der Strecke.
## Ein Ziel-Auslöser gibt es hier nicht: Ziel ist allein das Zielportal
## (Entwurf §1 Nr. 15, `_auf_level_geschafft` ist nicht gegen Doppelaufruf
## geschützt).
##
## NACH EINEM TOD (`nach_tod`, Gruppe LevelBasis.NACH_TOD): Der Keiler
## steht VORSPRUNG hinter dem Rastplatz, an dem die Figur wieder erscheint
## (Strecke des Checkpoints). Liegt der vor WECK_S – Start oder Game Over –,
## schläft er wieder an seinem Platz.
##
## RUHE (`pruefruhe`, Entwurf §1 Nr. 16): Für Sprungprobe, LevelCheck und
## Fotos fängt er nicht und läuft nicht von selbst. Er steht dann in der
## Ruhestellung: VORSPRUNG hinter der Figur (am Ufer höchstens bis UFER_S),
## vor WECK_S schlafend an seinem Platz – und bleibt dort, wohin die Probe
## die Figur auch setzt (jedes Bild neu gestellt). So zeigen Fotos und
## Kostenmessung ihn dort, wo er im Spiel stünde; gemessen hatte der Entwurf
## seine Kosten genau so (§10). Nach einem Tod bleibt die Ruhe.
##
## Die Strecke der Figur kommt aus `LevelBasis.strecke_der_figur()`. Der
## Keiler behält vorerst sein altes Netz aus keiler.gd; Haltungen (Schlaf,
## Erwachen, Hopser, Schnauben), Bruch der Durchlässe und Staub kommen mit
## der Optik (Paket P5).

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


func wecken() -> void:
	if _lage != Lage.SCHLAF:
		return
	_lage = Lage.JAGD
	_keiler_s = SCHLAF_S


func nach_tod(_von_vorn: bool) -> void:
	if _ruhe:
		_ruhestellung(true)
		return
	var s_cp := _level.verlauf.get_closest_offset(_level.to_local(GameState.checkpoint))
	if s_cp < WECK_S - WECK_SPIEL:
		_einschlafen()
		return
	_keiler_s = minf(s_cp - VORSPRUNG, UFER_S)
	_lage = Lage.UFER if _keiler_s >= UFER_S else Lage.JAGD
	_stellen(_keiler_s, 0.0, true)


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
			_lage = Lage.UFER
	var abstand := s_figur - _keiler_s
	var naehe := 1.0 - clampf(abstand / HOECHSTABSTAND, 0.0, 1.0)
	_stellen(_keiler_s, _querlage(s_figur) * QUER_ANTEIL)
	_keiler.aktualisiere(delta, 1.0 if _lage == Lage.JAGD else 0.0, naehe)
	if abstand <= FANGABSTAND and _figur.invuln <= 0.0:
		_figur.sterben()


func _einschlafen() -> void:
	_lage = Lage.SCHLAF
	_keiler_s = SCHLAF_S
	_stellen(SCHLAF_S, SCHLAF_Q, true)


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
	_lage = Lage.UFER if _keiler_s >= UFER_S else Lage.JAGD
	_stellen(_keiler_s, _querlage(s_figur) * QUER_ANTEIL, versetzt)


## Der Keiler auf der Wegdecke bei (s, q), mit dem Weg gedreht.
## `versetzt`: ein Sprung an einen anderen Ort (Schlafplatz, Rastplatz,
## Probe) – dann ohne Zwischenbild, sonst zöge Godot eine Spur dorthin.
## Im Lauf bleibt die Interpolation an, sonst ruckelte er bei mehr als 60
## Bildern je Sekunde.
func _stellen(s: float, q: float, versetzt := false) -> void:
	if not is_instance_valid(_keiler):
		return
	var ort := _level.weg_punkt(s, q)
	_keiler.global_position = _level.to_global(ort)
	_keiler.rotation.y = LevelWerkzeuge.drehung(_level.verlauf, s)
	if versetzt:
		_keiler.reset_physics_interpolation()


## Querlage der Figur an ihrer Strecke (positiv = rechts).
func _querlage(s: float) -> float:
	if not is_instance_valid(_figur):
		return 0.0
	var mitte := _level.verlauf.sample_baked(clampf(s, 0.0, _level.verlauf.get_baked_length()))
	var versatz := _level.to_local(_figur.global_position) - mitte
	versatz.y = 0.0
	return versatz.dot(LevelWerkzeuge.richtung(_level.verlauf, s).cross(Vector3.UP).normalized())
