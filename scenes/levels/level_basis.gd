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

## Vorwärmen (`_rundgang`): Abstand der Halte entlang des Verlaufs in
## Metern und die Blickrichtungen je Halt (Gieren gegen den Weg, Grad).
## Zwei Blicke zu je rund 97° Breite (16:9) decken zusammen 177° ab – mehr,
## als die Korridorkamera je zur Seite schaut (gemessen bis 38°).
const RUNDGANG_ABSTAND := 12.0
const RUNDGANG_BLICKE: Array[float] = [40.0, -40.0]
## Breite des Rundgang-Viewports in Bildpunkten (Höhe nach dem Seiten-
## verhältnis des Fensters). Die Shaderfassung hängt nicht an der Größe,
## die Füllrate schon.
const RUNDGANG_BREITE := 320
## Aus nur zum Vergleichen (`werkzeuge/ruckelprobe.gd`, RUCKEL_VORWAERMEN=0).
static var rundgang_an := true

## Schattenstrecke der Sonne im Web und auf dem Handy (`Effekte.reduziert`),
## siehe `_schatten_anpassen()`. Eine kürzere Strecke der Szene bleibt.
const SCHATTEN_WEB := 60.0
const SCHATTEN_HANDY := 50.0

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

## Dauer jedes Bauschritts in Millisekunden, in der Reihenfolge des
## Aufbaus: [{"text": String, "ms": float}]. Gemessen wird nur die Arbeit
## des Schritts selbst, nicht das freigegebene Bild danach. Liest
## `werkzeuge/bauzeitprobe.gd`.
var bauzeiten: Array[Dictionary] = []


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

	# Die Staubfarbe ist statisch und überlebt den Szenenwechsel. VOR dem
	# Aufbau auf die Vorgabe, damit ein Level ohne eigene Farbe nicht im
	# Staub des vorigen läuft; wer eine eigene will, setzt sie in `_baue()`.
	Effekte.staubfarbe = Effekte.STAUBFARBE_VORGABE

	await _aufbauen()
	var abschluss := Time.get_ticks_usec()

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
	_portale_verbinden()
	# VOR dem Zählen und vor dem Bauplan: Die Zeitkisten treten an die
	# Stelle gewöhnlicher Holzkisten, und beides – der Kistenzähler wie
	# der Neuaufbau nach einem Tod – soll die Kiste sehen, die wirklich
	# dasteht.
	_zeitkisten_setzen()
	_kisten_zaehlen()
	_bauplan_erfassen()
	GameState.level_zuruecksetzen.connect(_auf_zuruecksetzen)
	GameState.checkpoint_gesetzt.connect(_stand_sichern)
	_nach_aufbau()
	_schatten_anpassen()
	_bauzeit_merken("Abschluss: Kamera, Kisten", abschluss)
	# Shader übersetzen, solange der Ladeschirm noch steht. Erst nach
	# `_nach_aufbau()` und `_schatten_anpassen()`: Dort stellen Level noch
	# Licht und Schatten um (auf dem Handy eine Schattenstufe), und das
	# ändert, welche Fassung jedes Shaders gebraucht wird.
	var vorwaermen := Time.get_ticks_usec()
	await _rundgang()
	if not is_inside_tree():
		return
	# Teilchen-Shader ebenso – sonst stockt das Spiel beim ersten
	# Kistenbruch. Nach dem Rundgang, weil die Kamera dafür wieder an
	# ihrem Platz stehen muss.
	Effekte.vorwaermen(self)
	_bauzeit_merken("Vorwärmen: Rundgang", vorwaermen)
	# Wer im Level von selbst läuft (die Karts in Level 06), wartet bis
	# hier – sonst liefe es während des Rundgangs schon los, während die
	# Figur noch gesperrt auf der Linie steht.
	_vor_dem_start()
	# Jetzt steht der Boden und die Figur an ihrem Platz: Physik wieder an.
	if _spieler != null:
		if _spieler is CharacterBody3D:
			(_spieler as CharacterBody3D).velocity = Vector3.ZERO
		_spieler.set_physics_process(true)
	# Zweites Aufräumen: Der Wechsel setzt den Touch-Zustand schon zurück,
	# aber während des Aufbaus liegt der Daumen oft noch auf dem Schirm.
	InputHub.zuruecksetzen()
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
	var beginn := Time.get_ticks_usec()
	var schritte := _bauschritte()
	_bauzeit_merken("Bauschritte zusammenstellen", beginn)
	if schritte.is_empty():
		beginn = Time.get_ticks_usec()
		_baue()
		_bauzeit_merken("Aufbau", beginn)
		return
	for i in schritte.size():
		var schritt: Dictionary = schritte[i]
		Ladeschirm.fortschritt(0.05 + 0.9 * float(i) / float(schritte.size()),
				String(schritt.get("text", "")))
		var tun: Callable = schritt["tun"]
		beginn = Time.get_ticks_usec()
		tun.call()
		_bauzeit_merken(String(schritt.get("text", "")), beginn)
		# Ein Bild freigeben, damit die Anzeige weiterläuft
		await get_tree().process_frame


## Fährt eine eigene Kamera unter dem Ladeschirm den Verlauf ab und zeigt
## an jedem Halt (alle `RUNDGANG_ABSTAND` m) je ein Bild nach links und
## rechts vorn.
##
## WARUM. Der Compatibility-Renderer (OpenGL ES 3, WebGL 2) übersetzt die
## Fassung eines Shaders erst, wenn das erste Objekt damit gezeichnet wird
## – mit Nebel, Schattenstufen, Instanzen, Lichtern, je nachdem, wo es
## steht. Auf dem Handy kostet jede Fassung Dutzende Millisekunden, und
## sie fielen genau dann an, wenn beim Laufen oder Wenden etwas Neues ins
## Bild kam: „es lädt bei jeder Bewegung nach". Gemessen mit der
## Ruckelprobe (Level 01, Handyweg, llvmpipe): ohne Rundgang 16 Ruckler
## im ersten Durchgang (bis 2,9 s), im zweiten nur noch einer – es war
## Arbeit beim ersten Gebrauch, keine in jedem Bild.
##
## Gezeichnet werden die echten Objekte an ihren echten Orten, also auch
## mit den Lichtern und Schatten, die sie im Spiel haben. Die Sichtweiten
## (`visibility_range`) gelten von jeder Kamera aus; ein Halt alle 12 m
## bringt jedes Objekt am Weg einmal nah genug heran.
##
## In einem EIGENEN, kleinen Viewport in derselben Welt: Übersetzte Shader
## gelten für alle Viewports, aber die Sichtweiten merken sich je Viewport,
## was zuletzt zu sehen war (der Rand `visibility_range_end_margin` wirkt
## als Hysterese). Fuhr die Spielkamera selbst die Runde, standen bei 70 m
## danach Kronen im Bild, die dort sonst fehlen (gerendert). Der Viewport
## übernimmt alles, was die Shaderfassung bestimmt (MSAA, 3D-Skalierung,
## HDR, Schattenatlas für Punktlichter), nur nicht die Größe.
##
## Headless (Prüfwerkzeuge) wird nichts gezeichnet – dort entfällt er.
func _rundgang() -> void:
	if not rundgang_an or verlauf == null or DisplayServer.get_name() == "headless":
		return
	var laenge := verlauf.get_baked_length()
	if laenge <= 0.0:
		return
	var abstand := 8.0
	var hoehe := 4.2
	var vorlauf := 4.0
	var haupt := get_viewport()
	var buehne := SubViewport.new()
	buehne.name = "Rundgang"
	var flaeche := haupt.get_visible_rect().size
	var seitenverhaeltnis := flaeche.x / maxf(flaeche.y, 1.0)
	buehne.size = Vector2i(RUNDGANG_BREITE, maxi(16, roundi(RUNDGANG_BREITE / seitenverhaeltnis)))
	buehne.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	buehne.msaa_3d = haupt.msaa_3d
	buehne.scaling_3d_mode = haupt.scaling_3d_mode
	buehne.scaling_3d_scale = haupt.scaling_3d_scale
	buehne.use_hdr_2d = haupt.use_hdr_2d
	buehne.use_debanding = haupt.use_debanding
	buehne.positional_shadow_atlas_size = haupt.positional_shadow_atlas_size
	buehne.positional_shadow_atlas_16_bits = haupt.positional_shadow_atlas_16_bits
	for quadrant in 4:
		buehne.set_positional_shadow_atlas_quadrant_subdiv(quadrant,
				haupt.get_positional_shadow_atlas_quadrant_subdiv(quadrant))
	var kamera := Camera3D.new()
	# Im Bildtakt versetzt, nie bewegt.
	kamera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _kamera != null:
		kamera.fov = _kamera.fov
		kamera.near = _kamera.near
		kamera.far = _kamera.far
		kamera.cull_mask = _kamera.cull_mask
		kamera.environment = _kamera.environment
		kamera.attributes = _kamera.attributes
		if "abstand" in _kamera:
			abstand = float(_kamera.get("abstand"))
		if "hoehe" in _kamera:
			hoehe = float(_kamera.get("hoehe"))
		if "blick_vorlauf" in _kamera:
			vorlauf = float(_kamera.get("blick_vorlauf"))
	buehne.add_child(kamera)
	add_child(buehne)
	kamera.current = true
	# Das Hauptbild liegt hinter dem Ladeschirm, zeichnete aber jedes Bild
	# die volle Szene mit – auf dem Handy die Hälfte der Rundgangszeit.
	var hauptbild_aus := haupt.disable_3d
	haupt.disable_3d = true
	var halte := maxi(1, ceili(laenge / RUNDGANG_ABSTAND) + 1)
	for i in halte:
		var s := minf(float(i) * RUNDGANG_ABSTAND, laenge)
		var auge := LevelWerkzeuge.punkt_frei(verlauf, s - abstand, 0.0, hoehe)
		var ziel := LevelWerkzeuge.punkt(verlauf, s + vorlauf, 0.0, 1.0)
		if auge.distance_to(ziel) < 0.5:
			continue
		var blick := Basis.looking_at(ziel - auge, Vector3.UP)
		for gieren in RUNDGANG_BLICKE:
			kamera.global_transform = Transform3D(
					Basis(Vector3.UP, deg_to_rad(gieren)) * blick, auge)
			# `process_frame`, nicht `frame_post_draw`: Das nächste
			# `process_frame` kommt nach dem Zeichnen dieses Bildes, und
			# anders als `frame_post_draw` kommt es auch, wenn nicht
			# gezeichnet wird (Fenster verkleinert) – der Aufbau hinge sonst.
			await get_tree().process_frame
			if not is_inside_tree():
				haupt.disable_3d = hauptbild_aus
				return
		Ladeschirm.fortschritt(0.95 + 0.05 * float(i + 1) / float(halte),
				"Licht und Schatten werden vorbereitet")
	haupt.disable_3d = hauptbild_aus
	buehne.queue_free()


func _bauzeit_merken(text: String, beginn: int) -> void:
	bauzeiten.append({"text": text, "ms": float(Time.get_ticks_usec() - beginn) / 1000.0})


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


## Im Web höchstens zwei Schattenstufen und Schatten nur bis SCHATTEN_WEB.
## Jede Stufe zeichnet alles, was Schatten wirft, noch einmal. Aus vier
## Stufen werden zwei (die erste bis 12 m); hat die Szene schon zwei,
## bleibt die erste so lang wie dort (17,5 m), nur die zweite endet früher.
## Eine kürzere Strecke der Szene bleibt.
##
## Auf dem Handy (`Effekte.reduziert`) EINE Stufe bis SCHATTEN_HANDY.
## Gemessen (Paket leistung, Schattenprobe mit Touch-Tasten): Die Sonne
## kostete dort 70–140 Aufrufe, eine Stufe spart davon 40–60 (s 4: 537 →
## 481, s 140: 469 → 409); die Strecke selbst kaum etwas (60 → 45 m: 0–11).
## Die Schärfe am Fuß der Figur leidet auf dem kleinen Schirm kaum, und der
## Bodenschatten liegt ohnehin darunter.
##
## Gemessen in Level 01, gilt aber für jedes Level: Seit die Handy-App den
## Handyweg nimmt, liefen die übrigen Level dort sonst mit vier Stufen bis
## 70–90 m.
func _schatten_anpassen() -> void:
	if not OS.has_feature("web") and not Effekte.reduziert:
		return
	var sonne := _schattensonne()
	if sonne == null:
		return
	var weite := sonne.directional_shadow_max_distance
	if Effekte.reduziert:
		sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sonne.directional_shadow_max_distance = minf(weite, SCHATTEN_HANDY)
		return
	var neu := minf(weite, SCHATTEN_WEB)
	if sonne.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sonne.directional_shadow_split_1 = 0.2
	elif sonne.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS:
		sonne.directional_shadow_split_1 = clampf(
				weite * sonne.directional_shadow_split_1 / neu, 0.05, 0.95)
	sonne.directional_shadow_max_distance = neu


## Die schattenwerfende Sonne der Szene, oder null.
func _schattensonne() -> DirectionalLight3D:
	var sonne := get_node_or_null("Sonne") as DirectionalLight3D
	if sonne != null and sonne.shadow_enabled:
		return sonne
	for kind in get_children():
		if kind is DirectionalLight3D and (kind as DirectionalLight3D).shadow_enabled:
			return kind as DirectionalLight3D
	return null


## Haken: Unmittelbar bevor die Figur losdarf, nach dem Rundgang. Hier
## gibt ein Level frei, was von selbst läuft und bis dahin stehen musste.
func _vor_dem_start() -> void:
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
