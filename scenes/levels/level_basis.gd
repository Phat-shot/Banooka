extends Node3D
class_name LevelBasis
## Gemeinsame Grundlage aller Level.
##
## Ein Level definiert seinen Verlauf als `Curve3D` und baut seinen Inhalt
## in `_baue()` auf. Diese Basisklasse kümmert sich um alles Wiederkehrende:
## Kamera an den Verlauf hängen, Kisten zählen, Zielportal verdrahten,
## Spieler ans Startportal setzen.

## Wird ausgelöst, sobald das Level vollständig aufgebaut ist. Der Aufbau
## läuft über mehrere Bilder, damit der Ladebildschirm mitläuft – wer auf
## das fertige Level warten muss, hängt sich hier an.
signal aufbau_fertig

const KISTE_SZENE := preload("res://scenes/crates/Kiste.tscn")

## Jede so-und-so-vielte Holzkiste wird im Zeitmodus zur Zeitkiste.
const ZEITKISTE_ABSTAND := 3
## Die Zahlen, die der Reihe nach auf den Zeitkisten stehen.
const ZEITKISTE_WERTE := [2, 1, 3]

## Startpunkt des Spielers relativ zum Verlauf (Strecke auf der Kurve).
@export var start_strecke := 2.0
## Hilfslinien und Zahlen ausgeben (nur zum Bauen des Levels).
@export var debug := false

## Verlauf des Korridors. Wird von `_baue()` gesetzt.
var verlauf: Curve3D
## Knoten, unter dem die Levelgeometrie hängt.
var geometrie: Node3D
## Knoten, unter dem Objekte (Kisten, Gegner, Früchte) hängen.
var objekte: Node3D
## Knoten, unter dem die Deko hängt.
var deko: Node3D

var _pfad_knoten: Path3D
var _spieler: Node3D
var _kamera: Camera3D

## Bauplan aller zurücksetzbaren Objekte (Kisten und Gegner), in der
## Reihenfolge, in der sie beim Aufbau entstanden sind. Je Eintrag:
## {"szene", "eltern", "transform", "werte"}.
var _bauplan: Array = []
## Aktuelle Knoten zum Bauplan. Ein freigegebener Platz ist null.
var _lebendig: Array = []
## Stand beim letzten Checkpoint: welche Plätze standen da noch, und wie
## viele Kisten waren zu dem Zeitpunkt zerbrochen.
var _stand_plaetze := {}
var _stand_kisten := 0


func _ready() -> void:
	geometrie = _gruppe("Geometrie")
	objekte = _gruppe("Objekte")
	deko = _gruppe("Deko")

	# Die Figur steht beim Szenenwechsel schon in der Welt, der Boden
	# entsteht aber erst über die nächsten Bilder. Ohne diese Sperre fällt
	# sie während des Aufbaus ins Leere, reißt `TODESHOEHE` und kostet ein
	# Leben, bevor das Level überhaupt zu sehen ist.
	_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	if _spieler != null:
		_spieler.set_physics_process(false)

	await _aufbauen()

	if verlauf != null:
		_pfad_knoten = Path3D.new()
		_pfad_knoten.name = "Verlauf"
		_pfad_knoten.curve = verlauf
		add_child(_pfad_knoten)

	if _spieler == null:
		_spieler = get_tree().get_first_node_in_group("spieler") as Node3D
	_kamera_verbinden()
	_spieler_setzen()
	# Erst Spieler setzen, dann Kamera nachziehen – sonst steht der
	# Spieler beim ersten Bild außerhalb des Sichtfelds.
	if _kamera != null and _kamera.has_method("sofort_ausrichten"):
		_kamera.call("sofort_ausrichten")
	# Jetzt steht der Boden und die Figur an ihrem Platz: Physik wieder an.
	if _spieler != null:
		if _spieler is CharacterBody3D:
			(_spieler as CharacterBody3D).velocity = Vector3.ZERO
		_spieler.set_physics_process(true)
	_portale_verbinden()
	# VOR dem Zählen und vor dem Bauplan: Die Zeitkisten treten an die
	# Stelle gewöhnlicher Holzkisten, und beides – der Kistenzähler wie
	# der Neuaufbau nach einem Tod – soll die Kiste sehen, die wirklich
	# dasteht.
	_zeitkisten_setzen()
	_kisten_zaehlen()
	_bauplan_erfassen()
	# Zweites Aufräumen: Der Wechsel setzt den Touch-Zustand schon zurück,
	# aber während des Aufbaus liegt der Daumen oft noch auf dem Schirm.
	InputHub.zuruecksetzen()
	GameState.level_zuruecksetzen.connect(_auf_zuruecksetzen)
	GameState.checkpoint_gesetzt.connect(_stand_sichern)
	_nach_aufbau()
	# Ganz zuletzt, wenn wirklich alles steht: Die Uhr darf keine
	# Ladezeit mitzählen.
	Zeitlauf.beginnen(Spielfluss.aktuelles_level, _richtzeit())
	Ladeschirm.fortschritt(1.0, "Fertig")
	Ladeschirm.verbergen()
	aufbau_fertig.emit()


## Baut das Level auf. Liefert `_bauschritte()` eine Liste, wird sie
## Schritt für Schritt abgearbeitet und dazwischen jeweils ein Bild
## freigegeben – so bleibt der Ladebildschirm während des Aufbaus lebendig
## und meldet Fortschritt. Sonst wird einmalig `_baue()` aufgerufen.
func _aufbauen() -> void:
	var schritte := _bauschritte()
	if schritte.is_empty():
		_baue()
		return
	for i in schritte.size():
		var schritt: Dictionary = schritte[i]
		Ladeschirm.fortschritt(0.05 + 0.9 * float(i) / float(schritte.size()),
				String(schritt.get("text", "")))
		var tun: Callable = schritt["tun"]
		tun.call()
		# Ein Bild freigeben, damit die Anzeige weiterläuft
		await get_tree().process_frame


## Haken: Hier baut das konkrete Level seinen Inhalt auf.
## Wird nur genutzt, wenn `_bauschritte()` leer ist.
func _baue() -> void:
	pass


## Haken: Aufbau in einzelnen Schritten, je ein Wörterbuch
## {"text": String, "tun": Callable}. Ermöglicht einen Ladebalken.
func _bauschritte() -> Array:
	return []


## Haken: Wird ganz am Schluss aufgerufen, wenn alles steht.
func _nach_aufbau() -> void:
	pass


## Haken: Richtzeit des Levels für den Zeitmodus, in Sekunden.
## 0 heißt: aus der Länge des Verlaufs ableiten.
func zielzeit() -> float:
	return 0.0


## Richtzeit, auf die sich die drei Stufen des Zeitlaufs beziehen.
##
## Die Ableitung aus der Streckenlänge ist grob, aber sie ist ehrlich
## grob: Ein doppelt so langes Level bekommt doppelt so viel Zeit, und
## kein Level fällt durchs Raster, nur weil jemand vergessen hat, eine
## Zahl einzutragen. Wer es genauer will, überschreibt `zielzeit()`.
func _richtzeit() -> float:
	var eigen := zielzeit()
	if eigen > 0.0:
		return eigen
	if verlauf == null or verlauf.get_baked_length() <= 1.0:
		return Zeitlauf.RICHTZEIT_ERSATZ
	var laenge := verlauf.get_baked_length()
	if _auf_schiene():
		return laenge / Zeitlauf.RITTTEMPO * Zeitlauf.RITT_FAKTOR
	return laenge / Zeitlauf.LAUFTEMPO * Zeitlauf.ZEITFAKTOR


## Klebt die Figur auf der Levelkurve (Ritt, Flucht, Rennen)?
##
## Erkannt an der Eigenschaft `strecke`, die nur diese Figuren haben –
## dieselbe Prüfung nutzt der Spieltest-Bot. Ein Rittlevel rennt von
## selbst und deutlich schneller; seine Richtzeit kommt deshalb aus einer
## anderen Rechnung.
func _auf_schiene() -> bool:
	return _spieler != null and _spieler.get("strecke") != null


## Setzt im Zeitmodus Zeitkisten an die Stelle gewöhnlicher Holzkisten.
##
## WARUM ERSETZEN UND NICHT DAZUSTELLEN. Eine zusätzliche Kiste bräuchte
## einen Platz, und den kennt nur, wer das Level gebaut hat: Der Weg ist
## an manchen Stellen zwei Meter breit, an anderen ist er ein Steg über
## Wasser. Eine Holzkiste dagegen steht bereits an einer geprüften
## Stelle, auf dem Weg und in Reichweite. Damit stimmt zugleich der
## Kistenzähler weiter: Es kommt keine Kiste dazu, es geht keine
## verloren, und "alle Kisten" bleibt im Zeitmodus dieselbe Aufgabe.
##
## Außerhalb des Zeitmodus passiert hier gar nichts – die Level sehen
## dann aus wie zuvor.
func _zeitkisten_setzen() -> void:
	if not Zeitlauf.aktiv:
		return
	var umgebaut := 0
	var gezaehlt := 0
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var alt := knoten as Kiste
		if alt == null or not is_instance_valid(alt) or alt.art != Kiste.Art.NORMAL:
			continue
		gezaehlt += 1
		if gezaehlt % ZEITKISTE_ABSTAND != 0:
			continue
		if _zeitkiste_tauschen(alt, ZEITKISTE_WERTE[umgebaut % ZEITKISTE_WERTE.size()]):
			umgebaut += 1
	if debug:
		print("Zeitkisten gesetzt: ", umgebaut)


## Tauscht eine Holzkiste gegen eine Zeitkiste am selben Platz.
## Die Optik entsteht in `_ready()`, deshalb muss die neue Kiste wirklich
## eine neue sein – ein Umsetzen von `art` käme zu spät.
func _zeitkiste_tauschen(alt: Kiste, wert: int) -> bool:
	var eltern := alt.get_parent()
	if eltern == null:
		return false
	var neu := KISTE_SZENE.instantiate() as Kiste
	if neu == null:
		return false
	neu.art = Kiste.Art.ZEIT
	neu.zeit_wert = wert
	if alt.is_in_group("schwebende_kisten"):
		neu.add_to_group("schwebende_kisten")
	var lage := alt.transform
	# Erst aus dem Baum nehmen, dann freigeben: `queue_free()` allein
	# räumt erst am Ende des Bildes, und bis dahin stünde die alte Kiste
	# noch in der Gruppe – der Kistenzähler zählte sie mit.
	eltern.remove_child(alt)
	alt.queue_free()
	eltern.add_child(neu)
	neu.transform = lage
	return true


func _gruppe(bezeichnung: String) -> Node3D:
	var vorhanden := get_node_or_null(NodePath(bezeichnung)) as Node3D
	if vorhanden != null:
		return vorhanden
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	add_child(knoten)
	return knoten


func _kamera_verbinden() -> void:
	for kind in get_children():
		if kind is Camera3D:
			_kamera = kind
			break
	if _kamera == null:
		return
	if _pfad_knoten != null and "kurve_pfad" in _kamera:
		_kamera.kurve_pfad = _kamera.get_path_to(_pfad_knoten)
	if _spieler != null and "ziel_pfad" in _kamera:
		_kamera.ziel_pfad = _kamera.get_path_to(_spieler)
	if _kamera.has_method("_ziel_suchen"):
		_kamera.call("_ziel_suchen")


func _spieler_setzen() -> void:
	if _spieler == null or verlauf == null:
		return
	var start := LevelWerkzeuge.punkt(verlauf, start_strecke, 0.0, 0.6)
	_spieler.global_position = start
	_spieler.reset_physics_interpolation()
	if _spieler.has_method("setze_blickrichtung"):
		_spieler.call("setze_blickrichtung", LevelWerkzeuge.drehung(verlauf, start_strecke))
	GameState.level_starten(start)


## Sucht das Zielportal und hängt sich an dessen Signal.
func _portale_verbinden() -> void:
	for knoten in _alle_knoten(self):
		if knoten.has_signal("level_geschafft"):
			if not knoten.is_connected("level_geschafft", _auf_level_geschafft):
				knoten.connect("level_geschafft", _auf_level_geschafft)


func _auf_level_geschafft() -> void:
	if debug:
		print("Level geschafft – Kisten: %d/%d, Früchte: %d"
				% [GameState.kisten_zerbrochen, GameState.kisten_gesamt, GameState.fruechte])
	var alle_kisten := GameState.kisten_gesamt > 0 \
			and GameState.kisten_zerbrochen >= GameState.kisten_gesamt
	Spielfluss.level_abschliessen(alle_kisten, GameState.ohne_tod)
	var warten := 4.5
	if await _zeitlauf_werten():
		warten = 3.0
	# Kurz die Schlussmeldung stehen lassen, dann zurück in den Portalraum
	await get_tree().create_timer(warten).timeout
	Spielfluss.zum_hub()


## Schließt einen laufenden Zeitlauf ab und meldet das Ergebnis.
## Rückgabe: true, wenn ein Lauf gewertet wurde.
func _zeitlauf_werten() -> bool:
	var gelaufen := Zeitlauf.beenden()
	if gelaufen < 0.0:
		return false
	var stufe := Zeitlauf.stufe_fuer(gelaufen, Zeitlauf.richtzeit)
	var bestzeit := Spielfluss.zeit_eintragen(Spielfluss.aktuelles_level,
			gelaufen, stufe)
	# Erst die Meldung des Portals stehen lassen, dann die Zeit.
	await get_tree().create_timer(2.6).timeout
	var text := "Zeit %s" % Zeitlauf.als_text(gelaufen)
	if stufe != Zeitlauf.Stufe.KEINE:
		text += " – %s!" % Zeitlauf.stufen_name(stufe)
	if bestzeit:
		text += "  (Bestzeit)"
	GameState.zeige_nachricht(text, 3.0)
	return true


## Zählt alle zählenden Kisten im Level und meldet sie dem Spielstand.
func _kisten_zaehlen() -> void:
	var anzahl := 0
	for kiste in get_tree().get_nodes_in_group("kisten"):
		if kiste.has_method("zaehlt_mit"):
			if kiste.call("zaehlt_mit"):
				anzahl += 1
		else:
			anzahl += 1
	GameState.kisten_gesamt = anzahl
	GameState.kisten_zerbrochen = 0
	GameState.kisten_geaendert.emit(0, anzahl)
	if debug:
		print("Kisten im Level: ", anzahl)


# ------------------------------------------------- Zurücksetzen

## Merkt sich, was zurücksetzbar ist.
##
## Ohne das blieb ein Level nach dem Tod leergeräumt: Kisten waren fort,
## Gegner besiegt, und wer alle Kisten wollte, musste das Level über den
## Portalraum neu starten. Statt jeder Kiste ein Wiederbeleben beizubringen
## merkt sich das Level, WIE sie entstanden ist, und baut sie neu.
func _bauplan_erfassen() -> void:
	_bauplan.clear()
	_lebendig.clear()
	for knoten in _alle_knoten(self):
		if not (knoten.is_in_group("kisten") or knoten.is_in_group("gegner")):
			continue
		var teil := knoten as Node3D
		if teil == null or teil.scene_file_path.is_empty():
			continue
		_bauplan.append({
			"szene": teil.scene_file_path,
			"eltern": get_path_to(teil.get_parent()),
			"transform": teil.transform,
			"werte": _exportwerte(teil),
		})
		_lebendig.append(teil)
	_stand_sichern()


## Alle im Skript deklarierten und gespeicherten Eigenschaften eines
## Knotens – also genau das, was ein Level per @export einstellt.
func _exportwerte(knoten: Node) -> Dictionary:
	var werte := {}
	for eintrag in knoten.get_property_list():
		var art: int = eintrag.get("usage", 0)
		if art & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if art & PROPERTY_USAGE_STORAGE == 0:
			continue
		werte[String(eintrag["name"])] = knoten.get(String(eintrag["name"]))
	return werte


## Sichert den Stand: Welche Plätze stehen noch, wie viele Kisten sind hin.
func _stand_sichern() -> void:
	_stand_plaetze.clear()
	for i in _lebendig.size():
		if is_instance_valid(_lebendig[i]):
			_stand_plaetze[i] = true
	_stand_kisten = GameState.kisten_zerbrochen


func _auf_zuruecksetzen(von_vorn: bool) -> void:
	# Aufgeschoben, weil zerbrochene Kisten mit queue_free() erst am Ende
	# des Bildes verschwinden – sonst stünden sie doppelt da.
	_zuruecksetzen.call_deferred(von_vorn)


func _zuruecksetzen(von_vorn: bool) -> void:
	if von_vorn:
		_stand_plaetze.clear()
		for i in _bauplan.size():
			_stand_plaetze[i] = true
		_stand_kisten = 0

	var wieder := 0
	for i in _bauplan.size():
		var soll_stehen: bool = _stand_plaetze.has(i)
		var steht: bool = is_instance_valid(_lebendig[i])
		if soll_stehen and not steht:
			_lebendig[i] = _aufstellen(_bauplan[i])
			wieder += 1
		elif not soll_stehen and steht:
			# Nach dem Checkpoint zerbrochen und seither wieder aufgebaut:
			# darf nicht doppelt stehen bleiben.
			_lebendig[i].queue_free()
			_lebendig[i] = null

	GameState.kisten_zerbrochen = _stand_kisten
	GameState.kisten_geaendert.emit(GameState.kisten_zerbrochen, GameState.kisten_gesamt)
	if debug and wieder > 0:
		print("Level zurückgesetzt: %d Objekte wieder aufgestellt" % wieder)


func _aufstellen(eintrag: Dictionary) -> Node3D:
	var szene := load(String(eintrag["szene"])) as PackedScene
	if szene == null:
		return null
	var knoten := szene.instantiate() as Node3D
	if knoten == null:
		return null
	var werte: Dictionary = eintrag["werte"]
	for name in werte:
		knoten.set(String(name), werte[name])
	var eltern := get_node_or_null(eintrag["eltern"] as NodePath)
	if eltern == null:
		eltern = objekte
	eltern.add_child(knoten)
	knoten.transform = eintrag["transform"]
	return knoten


func _alle_knoten(wurzel: Node) -> Array[Node]:
	var liste: Array[Node] = []
	for kind in wurzel.get_children():
		liste.append(kind)
		liste.append_array(_alle_knoten(kind))
	return liste
