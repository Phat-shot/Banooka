extends Node
## Geometrische Prüfung eines Levels.
##
## Aufruf:
##   godot --headless --path . res://werkzeuge/LevelCheck.tscn
##
## Prüft, ob alle Kisten und Gegner auf festem Boden stehen, ob die
## Patrouillen-Endpunkte der Gegner noch auf dem Weg liegen und ob die
## Absturzzone einen Sturz neben dem Pfad tatsächlich abfängt.
## Beendet sich mit Rückgabewert 1, wenn Fehler gefunden wurden.
## Der Bodenstrahl einer Kiste schließt nur die Kiste SELBST aus, nicht
## alle Kisten. Vorher tat er das, und jede Kiste auf einer Kiste – eine
## Stufe, wie sie in fast jedem Level steht – wurde als "schwebt 1,10 m"
## gemeldet. Das waren über dreißig Warnungen, die alle nichts bedeuteten,
## und in denen die wenigen echten untergingen. Eine Kiste, die auf einer
## Kiste steht, steht. Ob der Stapel über einer Lücke hängt, sagt dagegen
## die Gruppe `schwebende_kisten` – dafür gibt es sie.
##
## Für die Bäume bleibt es beim alten Ausschluss: Ein Baum, der neben
## einer Kiste steht, soll nicht auf ihr zu stehen scheinen.
##
## Die Bodenstrahlen für Kisten, Gegner und Patrouillen fragen die Ebenen
## 1|16 ab: Auf Ebene 16 („Spielergrenze", `LevelWerkzeuge.SPIELERGRENZE`)
## liegt erhöhtes Begehbares, auf dem die Figur steht und Kisten stehen
## dürfen (Moosbank, Findlingsturm, Oberwurzel in Level 01). Ein Strahl nur
## auf Ebene 1 fiel dort durch und meldete die Kisten als schwebend. In
## Leveln ohne Ebene 16 ändert das nichts.
##
## OPT-IN-PROBEN. Ein Level, das `pruefprofil() -> Dictionary` anbietet,
## bekommt zusätzlich die Proben, die es dort einschaltet. Alle anderen
## Level laufen genau wie vorher.
##   "sicht"       Sichtschlauch der Verfolgerkamera (`_pruefe_sicht`),
##                 dazu der Abgleich mit der echten Kamera
##   "gefaelle"    Blickpunkt im Boden (`_pruefe_gefaelle`)
##   "todeszonen"  begehbare Punkte in einer Todeszone (`_pruefe_todeszonen`)
##   "rand"        Randgang: Wo man vom Weg fallen kann, muss eine Todeszone
##                 fangen (`_pruefe_rand`); ohne eigenen Schlüssel an, wenn
##                 "todeszonen" an ist
##   "wegmaske"    CPU-Wegmaske gegen das Shader-Include (`_pruefe_wegmaske`,
##                 der Teil von `Wegmaskenprobe` ohne Bildschirm)
##   "naht"        Nähte des Geländes an den FLACH-Kanten: Das Level liefert
##                 die Abweichungen über `nahtprobe()` (`_pruefe_naht`)
## Das Level muss dafür `breite_bei(s)` und `boden_bei(s)` anbieten; für
## die Oberseiten des Begehbaren `BEGEHBARES` und `begehbar(name)` wie
## Level 01.
##
## ABGLEICH der Sichtprobe mit der echten Kamera (Level 01, 29.09.2026):
## Die Figur wird an drei Stellen abgesetzt, mit
## `reset_physics_interpolation()`, einem `sofort_ausrichten()` und einer
## Sekunde zum Einschwingen: s 44 Mitte und s 146 rechts am Rand mit freier
## Sicht, s 228 Mitte vier Meter vor der Checkpoint-Kiste, die die Kamera
## dort 13,9 m heranholt (bergauf, siehe `_pruefe_sicht`). Die echte
## KorridorKamera stand jedes Mal auf 0,000 m dort, wo das Modell sie
## ausrechnet; die Grenze ist 0,2 m. Der Abgleich läuft bei jedem Aufruf
## mit, damit das Modell nicht still von `corridor_camera.gd` wegdriftet.
##
## GEGENPROBE (Level 01, nur lokal, nicht eingecheckt): Eine schwebende
## Kiste mitten im Weg (s 36, q 0, Unterkante +1) meldet die Sichtprobe als
## FEHLER (14,9 m herangeholt, vor die Figur, aus der Mitte und im Anlauf);
## eine Todeszone über der Wurzelwiese (Oberkante 9,0 über der Wiese auf
## 7,0) meldet die Todeszonenprobe als FEHLER (s 200,7–207,4).

const MAX_SCHWEBE := 0.7
const MAX_VERSUNKEN := 0.35
## Ab dieser Höhe über dem Objekt gilt ein Treffer als "über mir" und
## damit nicht als Boden.
##
## Nicht knapp über null: Der Boden unter einem Gegner am Hang oder an
## der Wegkante liegt gern ein paar Zentimeter ÜBER seinem Ursprung, und
## eine zu enge Schranke wirft genau diesen Boden weg – der Gegner stünde
## dann laut Prüfung über dem Nichts. Eine Kiste ist einen Meter hoch,
## ihre Oberkante liegt also 1,5 m über dem Ursprung der Kiste darunter;
## 0,6 m trennt beides sauber.
const UEBER_MIR := 0.6

## Bodenstrahlen: fester Boden und Spielergrenze (erhöhtes Begehbares).
const BODEN_MASKE := 1 | LevelWerkzeuge.SPIELERGRENZE

# --- Opt-in-Proben (siehe Kopf) ---
## Der Kamerastrahl, wie `KorridorKamera._freie_sicht` ihn schickt.
const SICHT_MASKE := 1 | LevelWerkzeuge.SICHTSPERRE
## Abstand der Probestellen entlang des Weges.
const SICHT_SCHRITT := 2.0
## Die Randlagen stehen so weit innerhalb der Wegkante.
const SICHT_RANDABSTAND := 0.6
## Weiter darf die Kamera nicht herangeholt werden (Plan K2).
const HERANHOLEN_GRENZE := 1.5
## Steht die Kamera weniger als das HINTER der Figur, gilt sie als "vor"
## ihr: Sie blickt dann an ihr vorbei oder von vorn auf sie.
const HINTER_FIGUR := 0.5
## Tiefer darf der Blickpunkt nicht im Boden liegen (Plan K4).
const GEFAELLE_GRENZE := 0.3
## Die Figur für die Proben: Kapsel wie in Player.tscn.
const FIGUR_RADIUS := 0.38
const FIGUR_HOEHE := 1.3
## Todeszonen liegen auf Ebene 0 und sind so für keine Abfrage sichtbar.
## Für die Proben kommen sie vorübergehend auf diese Ebene, die sonst
## niemand benutzt.
const ZONEN_EBENE := 1 << 19
## Die Probepunkte der Todeszonen liegen so hoch über dem Boden (Mitte der
## Figur, wie die Früchte).
const ZONEN_PRUEFHOEHE := 0.9
## Randgang: Schritt entlang und quer, größte Weite und die Stufe, ab der
## ein Schritt ins Leere führt.
const RAND_SCHRITT := 0.5
const RAND_QUER := 0.25
const RAND_WEIT := 16.0
const RAND_STUFE := 1.6
## Ein Boden höchstens so tief unter dem Weg fängt einen Sturz ohne
## Todeszone auf, von dort geht man zurück (Wurzelwiese, G1-Grube). Die
## Todeszonen liegen nach Plan mindestens sechs Meter unter dem Weg –
## alles, was tiefer liegt, muss eine Zone fangen.
const WEICHER_FALL := 6.0
## Zonen tiefer als das unter dem Weg fangen einen Sturz nicht mehr
## rechtzeitig (42 m Fall sind 1,5 s).
const ZONEN_FALLTIEFE := 45.0
## Größte erlaubte Abweichung zwischen Modell und echter Kamera.
const ABGLEICH_GRENZE := 0.2

var _level: Node3D
var _raum: PhysicsDirectSpaceState3D
var _fehler := 0
var _warnungen := 0
var _ausschluss: Array[RID] = []
## Figur, Kamera und Pfad für die Opt-in-Proben.
var _spieler: CharacterBody3D
var _kamera: KorridorKamera
var _pfad: Path3D
## Alle Kisten, Gegner und die Figur: für Rand- und Zonenproben.
var _bewegliche: Array[RID] = []

func _ready() -> void:
	var pfad := "res://scenes/levels/Level01.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	if OS.get_environment("PRUEF_ASSETS") == "0":
		Einstellungen.fremde_modelle = false
	# Der Zeitmodus tauscht jede dritte Holzkiste gegen eine Zeitkiste aus.
	# Die Geometrieprüfung soll aber immer dieselbe Fassung messen und
	# nicht die, die der Spieler zuletzt eingeschaltet hat – die
	# Einstellung liegt in `user://` und gilt auch für die Prüfkopie.
	# PRUEF_ZEITMODUS=1 misst ausdrücklich die Zeitmodus-Fassung.
	Zeitlauf.aktiv = OS.get_environment("PRUEF_ZEITMODUS") == "1"
	print("Level: ", pfad, "  fremde Modelle: ",
			"an" if Einstellungen.fremde_modelle else "aus")
	_level = load(pfad).instantiate()
	add_child(_level)
	# Der Aufbau läuft über mehrere Bilder (Ladebildschirm) – abwarten.
	if _level.has_signal("aufbau_fertig"):
		await _level.aufbau_fertig
	for i in 4:
		await get_tree().physics_frame
	_raum = get_viewport().world_3d.direct_space_state
	# Alle Kisten aus den Bodenstrahlen ausschließen
	for k in get_tree().get_nodes_in_group("kisten"):
		if k is CollisionObject3D:
			_ausschluss.append((k as CollisionObject3D).get_rid())

	print("=== %s: geometrische Prüfung ===" % pfad.get_file().get_basename())
	_pruefe_objekte("kisten", 0.5)
	_pruefe_objekte("gegner", 0.0)
	_pruefe_baeume()
	_pruefe_gegner_patrouille()
	_pruefe_gegner_blick()
	# Vor der Sturzprobe: Sie versetzt die Figur und lässt sie sterben.
	await _opt_in_proben()
	await _pruefe_absturz()
	# Zuletzt: Die Probe besiegt Gegner, danach fehlen sie jeder anderen.
	await _pruefe_gegner_leben()
	if not _hat_verlauf():
		print("  HINWEIS  kurvenloses Level: Boden-, Patrouillen- und")
		print("           Sturzproben entfallen – sie messen alle gegen den")
		print("           Levelverlauf, und den gibt es hier nicht.")
	print("=== %d Fehler, %d Warnungen ===" % [_fehler, _warnungen])
	get_tree().quit(1 if _fehler > 0 else 0)

func _pruefe_objekte(gruppe: String, soll: float) -> void:
	var liste := get_tree().get_nodes_in_group(gruppe)
	var schlecht := 0
	var absichtlich := 0
	for knoten in liste:
		var n := knoten as Node3D
		if n == null:
			continue
		# Kisten, die als Stufe oder Plattform gedacht sind, stehen
		# absichtlich in der Luft. Sie tragen das Merkmal aus
		# `korridor_level.kiste(..., schwebt = true)`.
		if n.is_in_group("schwebende_kisten"):
			absichtlich += 1
			continue
		# Nur den eigenen Körper ausschließen – was sonst unter der Kiste
		# liegt, ist ihr Boden, auch wenn es selbst eine Kiste ist.
		var eigene: Array[RID] = _alle_koerper(n)
		var treffer := _boden_unter_breit(n.global_position, eigene, n.global_position.y - soll)
		if treffer.is_empty():
			print("  FEHLER  %s bei Strecke %.0f m (%s) hat keinen Boden darunter"
					% [gruppe, _strecke(n.global_position), str(n.global_position.snappedf(0.1))])
			_fehler += 1; schlecht += 1
			continue
		var abstand: float = n.global_position.y - soll - treffer["position"].y
		if abstand > MAX_SCHWEBE:
			print("  schwebt %.2f m: %s bei Strecke %.0f m" % [abstand, gruppe, _strecke(n.global_position)])
			_warnungen += 1; schlecht += 1
		elif abstand < -MAX_VERSUNKEN:
			print("  steckt %.2f m im Boden: %s bei %s" % [-abstand, gruppe, str(n.global_position.snappedf(0.1))])
			_warnungen += 1; schlecht += 1
	if absichtlich > 0:
		print("  %s: %d geprüft, %d auffällig, %d schweben absichtlich"
				% [gruppe, liste.size(), schlecht, absichtlich])
	else:
		print("  %s: %d geprüft, %d auffällig" % [gruppe, liste.size(), schlecht])

## Prüft, ob Bäume wirklich auf dem Boden stehen.
##
## Anders als bei Kisten reicht der Knotenursprung hier nicht: Ein fremdes
## Modell kann seinen Ursprung irgendwo im Geäst haben. Gemessen wird
## deshalb die SICHTBARE Unterkante – die Hülle aller Netze in Weltmaßen.
func _pruefe_baeume() -> void:
	var baeume: Array[Node3D] = []
	_sammle_baeume(_level, baeume)
	var schlecht := 0
	var ohne_boden := 0
	var kulisse := 0
	for baum in baeume:
		# Deko-Bäume ohne Kollision stecken absichtlich in der Wandkrone
		# oder stehen als Kulisse in der Schlucht – sie sollen gar nicht
		# auf dem Boden stehen.
		if not bool(baum.get("kollision")):
			kulisse += 1
			continue
		# Der eigene Stamm darf den Bodenstrahl nicht abfangen.
		var eigene: Array[RID] = []
		for k in _alle_koerper(baum):
			eigene.append(k)
		var unten := _unterkante_welt(baum)
		if unten == INF:
			continue
		var treffer := _boden_unter_ohne(baum.global_position, eigene)
		if treffer.is_empty():
			# Der Waldbestand neben dem Weg steht auf dem sichtbaren
			# Waldboden, der keine Kollision trägt. Das ist Kulisse und
			# kein Fehler – nur gezählt, nicht gemeldet.
			ohne_boden += 1
			continue
		var abstand: float = unten - treffer["position"].y
		if abstand > MAX_SCHWEBE:
			print("  schwebt %.2f m: Baum bei Strecke %.0f m (unter %s, y=%.1f)"
					% [abstand, _strecke(baum.global_position),
					baum.get_parent().name, baum.global_position.y])
			_warnungen += 1; schlecht += 1
		elif abstand < -1.2:
			# Mit Elternknoten und Weltposition: Ein Baum steht selten dort,
			# wo seine Strecke ihn vermuten lässt – er steht weit neben dem
			# Weg, und die Strecke ist nur der nächste Punkt auf der Kurve.
			# Ohne den Platz sucht man ihn im falschen Bauschritt.
			print("  steckt %.2f m im Boden: Baum bei Strecke %.0f m (unter %s, %s)"
					% [-abstand, _strecke(baum.global_position),
					baum.get_parent().name, str(baum.global_position.snappedf(0.1))])
			_warnungen += 1; schlecht += 1
	print("  baeume: %d geprüft, %d auffällig (%d Kulisse in der Wand, %d auf dem Waldboden)"
			% [baeume.size(), schlecht, kulisse, ohne_boden])


func _sammle_baeume(wurzel: Node, hinein: Array[Node3D]) -> void:
	for kind in wurzel.get_children():
		if kind is Baum:
			hinein.append(kind as Node3D)
		else:
			_sammle_baeume(kind, hinein)


## Tiefster Punkt aller sichtbaren Netze in Weltmaßen.
func _unterkante_welt(wurzel: Node) -> float:
	var tiefster := INF
	var netz := wurzel as MeshInstance3D
	if netz != null and netz.mesh != null and netz.visible:
		var kasten := netz.global_transform * netz.mesh.get_aabb()
		tiefster = kasten.position.y
	for kind in wurzel.get_children():
		tiefster = minf(tiefster, _unterkante_welt(kind))
	return tiefster


func _alle_koerper(wurzel: Node) -> Array[RID]:
	var liste: Array[RID] = []
	if wurzel is CollisionObject3D:
		liste.append((wurzel as CollisionObject3D).get_rid())
	for kind in wurzel.get_children():
		liste.append_array(_alle_koerper(kind))
	return liste


func _boden_unter_ohne(pos: Vector3, zusatz: Array[RID]) -> Dictionary:
	var frage := PhysicsRayQueryParameters3D.create(
			pos + Vector3.UP * 4.0, pos + Vector3.DOWN * 30.0)
	frage.exclude = _ausschluss + zusatz
	return _raum.intersect_ray(frage)


func _pruefe_gegner_patrouille() -> void:
	var schlecht := 0
	for knoten in get_tree().get_nodes_in_group("gegner"):
		var g := knoten as Node3D
		var achse: Vector3 = g.get("patrouille_achse")
		var weite: float = g.get("patrouille_weite")
		for vorzeichen: float in [-1.0, 1.0]:
			var p: Vector3 = g.global_position + achse.normalized() * weite * vorzeichen
			if _boden_unter(p).is_empty():
				print("  FEHLER  Patrouille endet im Leeren: Gegner bei Strecke %.0f m, Endpunkt %s"
						% [_strecke(g.global_position), str(p.snappedf(0.1))])
				_fehler += 1; schlecht += 1
	print("  Patrouillen-Endpunkte: %d Probleme" % schlecht)

## Blickt jeder Gegner in seine Laufrichtung?
##
## Die Level drehen jeden Gegner auf den Korridor; `_blick_ausrichten`
## rechnet eine WELTrichtung in die Drehung seines Modells um. Früher
## fehlte dabei die eigene Drehung, und in den Kurven von Level 01 liefen
## neun von vierzehn Gegnern 30 bis 70 Grad schräg – im Standbild einer
## Geradeaus-Strecke sieht man das nicht. Hier wird der Blick ohne
## Weichzeichnung gesetzt (Gewicht 1), in Weltrichtung gemessen und
## zurückgestellt: reine Rechnung, keine Simulation.
##
## Jede Art über den Weg, den sie im Spiel nimmt: die meisten über
## `_blick_ausrichten` (die Krabbe mit eigener Fassung, sie läuft
## seitwärts, +X voran), der Werfer über `_zum_spieler_drehen` zu einem
## Probepunkt schräg hinter ihm. Der Schwarm dreht keinen Körper, nur
## seine Tiere – er zählt als "ohne Blickrichtung", statt still zu bestehen.
func _pruefe_gegner_blick() -> void:
	var schlecht := 0
	var geprueft := 0
	var ohne := 0
	var probe := Node3D.new()
	add_child(probe)
	for knoten in get_tree().get_nodes_in_group("gegner"):
		var g := knoten as Gegner
		if g == null or g.besiegt or not is_instance_valid(g.modell):
			continue
		if g is Schwarm:
			ohne += 1
			continue
		var vorher := g.modell.rotation.y
		var soll := g.achse() * g.richtung
		if g is Werfer:
			# Ein Punkt 6 m entfernt, schräg zur Korridorachse: So fällt
			# eine vergessene Korridordrehung in jeder Lage auf.
			soll = (g.global_basis.z + g.global_basis.x * 0.6).normalized()
			probe.global_position = g.global_position + soll * 6.0
			(g as Werfer)._zum_spieler_drehen(1.0, probe)
		else:
			g._blick_ausrichten(1.0, 1.0)
		var blick := g.modell.global_basis.x if g is Gletscherkrabbe \
				else -g.modell.global_basis.z
		g.modell.rotation.y = vorher
		blick.y = 0.0
		soll.y = 0.0
		if blick.length() < 0.01 or soll.length() < 0.01:
			continue
		geprueft += 1
		var treue := blick.normalized().dot(soll.normalized())
		if treue < 0.95:
			print("  FEHLER  %s bei Strecke %.0f m blickt %.0f Grad neben seine Laufrichtung"
					% [g.get_script().get_global_name(), _strecke(g.global_position),
					rad_to_deg(acos(clampf(treue, -1.0, 1.0)))])
			_fehler += 1; schlecht += 1
	probe.queue_free()
	print("  Gegnerblick: %d geprüft, %d schräg, %d ohne Blickrichtung (Schwarm)"
			% [geprueft, schlecht, ohne])


## Leben die Gegner, und sterben sie sauber?
##
## 1. Jeder Gegner mit mitgeliefertem, animiertem Modell spielt einen Clip.
##    Die Clips waren einmal importiert, aber nie gestartet – die Figuren
##    glitten als Standbilder durchs Level, und keine Prüfung merkte es.
## 2. Je Gegnerart wird einer besiegt; nach Todesdauer, Verpuffen und
##    etwas Luft muss er verschwunden sein. Der Tod läuft seitdem über
##    Tweens, Trefferpause und Effekte – bleibt davon etwas hängen, bliebe
##    ein Gegner als Leiche im Level stehen.
## Mit PRUEF_ASSETS=0 gibt es keine Modelle; dann zählt nur Punkt 2.
func _pruefe_gegner_leben() -> void:
	var gegner := get_tree().get_nodes_in_group("gegner")
	var mit_clips := 0
	var stumm := 0
	for knoten in gegner:
		var g := knoten as Gegner
		if g == null or g.besiegt or g._fremd_anim == null:
			continue
		mit_clips += 1
		if g._clip_jetzt.is_empty() or not g._fremd_anim.is_playing():
			print("  FEHLER  %s bei Strecke %.0f m hat ein Modell mit Clips, spielt aber keinen"
					% [g.get_script().get_global_name(), _strecke(g.global_position)])
			_fehler += 1; stumm += 1

	var je_art := {}
	for knoten in gegner:
		var g := knoten as Gegner
		if g == null or g.besiegt:
			continue
		var art := String(g.get_script().get_global_name())
		if not je_art.has(art):
			je_art[art] = g
	for art: String in je_art:
		var g := je_art[art] as Gegner
		g.besiegen(g.besiegbar_durch)
	var warten := roundi((Gegner.TODES_DAUER + 0.5) * Engine.physics_ticks_per_second)
	for i in warten:
		await get_tree().physics_frame
	var liegen := 0
	for art: String in je_art:
		if is_instance_valid(je_art[art]):
			print("  FEHLER  besiegter Gegner %s verschwindet nicht" % art)
			_fehler += 1; liegen += 1
	print("  Gegnerleben: %d Clips geprüft, %d stumm; %d Arten besiegt, %d liegen geblieben"
			% [mit_clips, stumm, je_art.size(), liegen])


## Lässt an mehreren Stellen einen Testkörper neben den Pfad fallen und
## prüft, ob die Absturzzone ihn tötet.
func _pruefe_absturz() -> void:
	var verlauf = _level.get("verlauf")
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	# In Ritt- und Fluchtleveln klebt der Spieler auf der Kurve und setzt
	# seine Position jedes Bild neu – er lässt sich gar nicht neben den Pfad
	# fallen. Die Probe meldete dort sechs Fehler, wo keiner war.
	if verlauf == null:
		print("  Absturzzone: entfällt (kurvenloses Level)")
		return
	if spieler != null and "boden_pruefer" in spieler:
		print("  Absturzzone: entfällt (Schienenlevel, kein Sturz möglich)")
		return
	var stellen := [10.0, 45.0, 90.0, 135.0, 180.0, 225.0]
	var misslungen := 0
	for s: float in stellen:
		# Erst den vorigen Tod ausklingen lassen. Sonst setzt die nächste
		# Stichprobe den Spieler mitten in einen laufenden Respawn – der
		# holt ihn zum Checkpoint zurück, er stirbt nicht, und die Probe
		# meldet einen Fehler, den es nicht gibt.
		for i in 40:
			await get_tree().physics_frame
		var vorher: int = GameState.leben
		spieler.global_position = LevelWerkzeuge.punkt(verlauf, s, 26.0, 2.0)
		spieler.reset_physics_interpolation()
		spieler.set("velocity", Vector3.ZERO)
		for i in 90:
			await get_tree().physics_frame
			if GameState.leben < vorher:
				break
		if GameState.leben >= vorher:
			# Ohne den Namen dessen, was den Sturz aufhält, ist die Meldung
			# nur ein Rätsel. Also gleich mitliefern.
			var halt := _boden_unter(spieler.global_position)
			var worauf := "nichts"
			if not halt.is_empty() and halt["collider"] != null:
				var c: Node3D = halt["collider"]
				worauf = "%s (%s) bei %s" % [c.name, c.get_class(),
						str(c.global_position.snappedf(0.1))]
			# Wo er liegen bleibt, ist die eigentliche Auskunft: Bei einem
			# Verlauf, der eine Schleife macht, kann seitwärts sehr wohl
			# wieder fester Weg liegen – dann ist die Probe kein Fehler,
			# sondern nur schlecht gezielt.
			print("  FEHLER  Sturz bei %.0f m nicht abgefangen: liegt bei %s "
					% [s, str(spieler.global_position.snappedf(0.1))]
					+ "(Strecke %.0f m) auf %s"
					% [_strecke(spieler.global_position), worauf])
			_fehler += 1; misslungen += 1
		GameState.leben = 3
	print("  Absturzzone: %d von %d Stichproben fehlgeschlagen" % [misslungen, stellen.size()])

## Hat dieses Level überhaupt einen Verlauf?
##
## Ein Flugniveau wie Level 22 hat keinen: kein Korridor, keine Kurve,
## kein Boden. Alle Proben, die gegen den Verlauf messen, sind dort nicht
## etwa bestanden oder durchgefallen – sie sind sinnlos. Der Prüfstand
## meldete stattdessen sechs Stürze in ein Level, das aus nichts als Luft
## besteht. Eine Prüfung, die aus Unzuständigkeit einen Fehler macht,
## verdirbt jede Gesamtmeldung, in der sie steht.
func _hat_verlauf() -> bool:
	return _level.get("verlauf") != null


## Wandelt eine Weltposition in die Strecke auf dem Levelverlauf um.
## Ohne Verlauf gibt es keine Strecke; -1 heißt "nicht anwendbar".
func _strecke(pos: Vector3) -> float:
	var verlauf = _level.get("verlauf")
	if verlauf == null:
		return -1.0
	return verlauf.get_closest_offset(pos)


func _boden_unter(pos: Vector3) -> Dictionary:
	return _boden_unter_ausser(pos, _ausschluss)


## Wie `_boden_unter_ausser`; schwebt das Objekt über dem Treffer in der
## Mitte (oder gibt es keinen), zählt der höchste Boden an vier Punkten je
## 0,12 m daneben. Ein Körper aus vielen konvexen Stücken (Streifen,
## Sweeps) hat alle Meter eine Fuge, und ein Strahl genau auf der Fuge
## trifft keines der beiden Stücke – die Kisten auf der Oberwurzel stehen
## auf ganzen Metern und galten so als schwebend, über dem Wurzelfleisch
## darunter. Unter einer Kiste (1 m breit) liegen alle fünf Punkte. Nur im
## Zweifel, damit ein Nachbarboden (eine Stufe) nie einen guten Treffer
## ersetzt. `unterkante`: Welt-Y, auf der das Objekt stehen soll.
func _boden_unter_breit(pos: Vector3, ausser: Array[RID], unterkante: float) -> Dictionary:
	var bester := _boden_unter_ausser(pos, ausser)
	if not bester.is_empty() \
			and unterkante - (bester["position"] as Vector3).y <= MAX_SCHWEBE:
		return bester
	for versatz: Vector3 in [Vector3(0.12, 0, 0), Vector3(-0.12, 0, 0),
			Vector3(0, 0, 0.12), Vector3(0, 0, -0.12)]:
		var t := _boden_unter_ausser(pos + versatz, ausser)
		if not t.is_empty() and (bester.is_empty()
				or (t["position"] as Vector3).y > (bester["position"] as Vector3).y + 0.01):
			bester = t
	return bester


## Bodenstrahl, der genau die übergebenen Körper ignoriert.
##
## Der Strahl beginnt ZWEI METER ÜBER dem Objekt, damit auch ein halb
## eingesunkenes noch einen Boden findet. Damit fängt er aber auch alles
## ein, was ÜBER dem Objekt liegt – die Kiste, die auf ihm steht, das
## Podest darüber. Nichts davon ist sein Boden. Solche Treffer werden
## deshalb der Reihe nach ausgeschlossen und der Strahl erneut geschickt,
## bis der erste Treffer wirklich unter dem Objekt liegt.
func _boden_unter_ausser(pos: Vector3, ausser: Array[RID]) -> Dictionary:
	var sperre := ausser.duplicate()
	for versuch in 8:
		var abfrage := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 2.0,
				pos + Vector3.DOWN * 14.0)
		abfrage.collision_mask = BODEN_MASKE
		abfrage.collide_with_areas = false
		abfrage.exclude = sperre
		var treffer := _raum.intersect_ray(abfrage)
		if treffer.is_empty():
			return treffer
		var hoehe: float = (treffer["position"] as Vector3).y
		if hoehe <= pos.y + UEBER_MIR:
			return treffer
		sperre.append(treffer["rid"] as RID)
	return {}


# ============================================================ Opt-in-Proben

## Die Proben, die das Level über `pruefprofil()` einschaltet (siehe Kopf).
## Ohne `pruefprofil()` geschieht hier nichts.
func _opt_in_proben() -> void:
	if not _level.has_method("pruefprofil") or not _hat_verlauf():
		return
	var profil: Dictionary = _level.call("pruefprofil")
	var sicht := bool(profil.get("sicht", false))
	var gefaelle := bool(profil.get("gefaelle", false))
	var zonen := bool(profil.get("todeszonen", false))
	var rand := bool(profil.get("rand", zonen))
	if bool(profil.get("wegmaske", false)):
		_pruefe_wegmaske()
	if bool(profil.get("naht", false)):
		_pruefe_naht()
	if not (sicht or gefaelle or zonen or rand):
		return
	if not _level.has_method("breite_bei") or not _level.has_method("boden_bei"):
		print("  FEHLER  pruefprofil() ohne breite_bei(s) und boden_bei(s) – die Proben brauchen beides")
		_fehler += 1
		return
	_spieler = get_tree().get_first_node_in_group("spieler") as CharacterBody3D
	_kamera = _korridorkamera(_level)
	_pfad = _level.get("_pfad_knoten") as Path3D
	_bewegliche = _ausschluss.duplicate()
	for gruppe: String in ["gegner", "spieler"]:
		for k in get_tree().get_nodes_in_group(gruppe):
			_bewegliche.append_array(_alle_koerper(k))
	var stellen := _figurstellen()
	if sicht or gefaelle:
		if _kamera == null:
			print("  Sichtschlauch/Gefälle: entfallen (keine KorridorKamera im Level)")
		else:
			var modelle := _kamera_modelle(stellen)
			if sicht:
				var anlauf := _anlaufstellen()
				var anlauf_modelle := _kamera_modelle(anlauf)
				_pruefe_sicht(stellen, modelle, anlauf, anlauf_modelle)
				var alle: Array[Dictionary] = []
				alle.append_array(stellen)
				alle.append_array(anlauf)
				var alle_modelle: Array[Dictionary] = []
				alle_modelle.append_array(modelle)
				alle_modelle.append_array(anlauf_modelle)
				await _kamera_abgleich(alle, alle_modelle)
			if gefaelle:
				_pruefe_gefaelle(stellen, modelle)
	if zonen or rand:
		var vorher: Dictionary = await _zonen_abfragbar({})
		if zonen:
			_pruefe_todeszonen(stellen)
		if rand:
			_pruefe_rand()
		await _zonen_abfragbar(vorher)


## Wegmaske (Plan P3): Konstanten der CPU-Maske gleich denen im Shader-
## Include, das Weltrauschen der GPU gleich dem der CPU. Den Abgleich der
## gezeichneten Maske (braucht einen Renderer) macht `pruefe.sh` über
## `werkzeuge/wegmaskenprobe.sh`.
func _pruefe_wegmaske() -> void:
	var probleme := 0
	for zeile in Wegmaskenprobe.ohne_bild():
		if zeile.begins_with("ABWEICHUNG"):
			print("  FEHLER  Wegmaske: " + zeile.trim_prefix("ABWEICHUNG").strip_edges())
			_fehler += 1
			probleme += 1
	print("  Wegmaske: CPU und Shader-Include verglichen, %d Probleme" % probleme)


## Nähte des Geländes (Level 01, Plan 8.4): Das Level liefert über
## `nahtprobe()` je Abweichung eine Zeile "ABWEICHUNG …" und zuletzt
## "GEPRUEFT n" (siehe `L01Gelaende.nahtprobe`).
func _pruefe_naht() -> void:
	if not _level.has_method("nahtprobe"):
		print("  FEHLER  pruefprofil() meldet \"naht\", aber das Level hat kein nahtprobe()")
		_fehler += 1
		return
	var zeilen: PackedStringArray = _level.call("nahtprobe")
	var probleme := 0
	var geprueft := "?"
	for zeile in zeilen:
		if zeile.begins_with("ABWEICHUNG"):
			probleme += 1
			if probleme <= 12:
				print("  FEHLER  Naht: " + zeile.trim_prefix("ABWEICHUNG").strip_edges())
		elif zeile.begins_with("GEPRUEFT"):
			geprueft = zeile.trim_prefix("GEPRUEFT").strip_edges()
	if probleme > 12:
		print("  FEHLER  Naht: … und %d weitere" % (probleme - 12))
	_fehler += probleme
	print("  Naht: %s Geländepunkte an FLACH-Kanten geprüft, %d Abweichungen" % [geprueft, probleme])


func _korridorkamera(wurzel: Node) -> KorridorKamera:
	for k in wurzel.find_children("*", "Camera3D", true, false):
		if k is KorridorKamera:
			return k as KorridorKamera
	return null


func _verlauf() -> Curve3D:
	return _level.get("verlauf") as Curve3D


## Die Probestellen der Sicht-, Gefälle- und Zonenprobe: alle
## `SICHT_SCHRITT` Meter je eine links am Rand, in der Mitte und rechts am
## Rand (Rand = halbe Breite − `SICHT_RANDABSTAND`), mit dem Fußpunkt, auf
## dem die Figur dort stünde. Über Lücken steht sie nicht.
func _figurstellen() -> Array[Dictionary]:
	var verlauf := _verlauf()
	var laenge := verlauf.get_baked_length()
	var stellen: Array[Dictionary] = []
	var s := 0.0
	while s <= laenge - 0.5:
		var breite: float = _level.call("breite_bei", s)
		if breite > 0.0:
			var rand := maxf(breite * 0.5 - SICHT_RANDABSTAND, 0.0)
			for q: float in [-rand, 0.0, rand]:
				var fuss := _figur_ort(verlauf, s, q)
				if fuss.is_finite():
					stellen.append({"s": s, "q": q, "fuss": fuss})
		s += SICHT_SCHRITT
	return stellen


## Wo stünde die Figur bei (s, q)? Der Bodenstrahl (1|16) beginnt 1,5 m
## über der Wegdecke: hoch genug für Kisten und Stufen, zu tief für
## erhöhtes Begehbares wie die Pfortenkörper, auf das man nur springt. Passt
## die Figur dort nicht hin, weil sie in einem Körper stäke, rückt die Stelle
## in Schritten von 0,25 m zur Mitte. Vector3.INF: Hier steht sie nicht.
func _figur_ort(verlauf: Curve3D, s: float, q: float) -> Vector3:
	var boden: float = _level.call("boden_bei", s)
	for versuch in 17:
		var qq := q - signf(q) * 0.25 * float(versuch)
		if versuch > 0 and (q == 0.0 or signf(qq) != signf(q)):
			break
		var p := LevelWerkzeuge.punkt_frei(verlauf, s, qq)
		var frage := PhysicsRayQueryParameters3D.create(Vector3(p.x, boden + 1.5, p.z),
				Vector3(p.x, boden - 4.0, p.z), BODEN_MASKE)
		var treffer := _raum.intersect_ray(frage)
		if treffer.is_empty():
			return Vector3.INF
		var fuss: Vector3 = treffer["position"]
		if _figur_passt(fuss):
			return fuss
	return Vector3.INF


var _figur_form: CapsuleShape3D

## Passt die Kapsel der Figur, eine Handbreit angehoben, an diesen Fußpunkt?
func _figur_passt(fuss: Vector3) -> bool:
	if _figur_form == null:
		_figur_form = CapsuleShape3D.new()
		_figur_form.radius = FIGUR_RADIUS
		_figur_form.height = FIGUR_HOEHE
	var frage := PhysicsShapeQueryParameters3D.new()
	frage.shape = _figur_form
	frage.transform = Transform3D(Basis.IDENTITY,
			fuss + Vector3.UP * (FIGUR_HOEHE * 0.5 + 0.12))
	frage.collision_mask = BODEN_MASKE
	return _raum.intersect_shape(frage, 1).is_empty()


# ------------------------------------------------------------- Kameramodell

## Rechnet `KorridorKamera._folgen` für eine stehende Figur nach, im
## Verfolgerbetrieb und eingeschwungen: geführte Strecke = nächster Punkt
## der Kurve, Höhenversatz = Figurhöhe über der Kurve, seitlich zu
## `seiten_faktor`, Blickpunkt `blick_vorlauf` voraus auf Figurhöhe + 1,
## am Kurvenanfang herangeholt (START_HERANHOLEN). Die Werte liest es von
## der Kamera des Levels. Ergebnis: {"blick", "wunsch", "strecke"}.
func _kamera_modell(fuss: Vector3) -> Dictionary:
	var kurve := _verlauf()
	var zu_welt := _pfad.global_transform if _pfad != null else Transform3D.IDENTITY
	var laenge := kurve.get_baked_length()
	var strecke := kurve.get_closest_offset(zu_welt.affine_inverse() * fuss)
	var mitte := zu_welt * kurve.sample_baked(strecke)
	var versatz := fuss - mitte
	versatz.y = 0.0
	var hoehe_versatz := fuss.y - mitte.y
	var abstand := _kamera.abstand
	var hinten := zu_welt * kurve.sample_baked(clampf(strecke - abstand, 0.0, laenge))
	var wunsch := hinten + Vector3.UP * (hoehe_versatz + _kamera.hoehe) \
			+ versatz * _kamera.seiten_faktor
	# Wie `_fehlstrecke`: Auf einem Rundkurs fehlt am Anfang nichts.
	var fehlt := 0.0
	var ende := kurve.point_count - 1
	if kurve.get_point_position(0).distance_to(kurve.get_point_position(ende)) >= 12.0:
		fehlt = maxf(abstand - strecke, 0.0)
	var vorlauf := maxf(_kamera.blick_vorlauf
			- KorridorKamera.START_HERANHOLEN * fehlt * fehlt / maxf(abstand, 0.1),
			minf(_kamera.blick_vorlauf, 1.5))
	var blick := zu_welt * kurve.sample_baked(clampf(strecke + vorlauf, 0.0, laenge))
	blick.y = mitte.y + hoehe_versatz + 1.0
	blick += versatz * _kamera.seiten_faktor
	return {"blick": blick, "wunsch": wunsch, "strecke": strecke}


## Wie `KorridorKamera._freie_sicht`: Strahl vom Blickpunkt zur Wunschlage
## auf 1|8, die Figur ausgenommen. Treffer näher als SICHT_MINDEST zählen
## nicht. Ergebnis: {"kamera": wo sie stünde, "treffer": der Strahltreffer
## oder {}}.
func _freie_sicht(blick: Vector3, wunsch: Vector3) -> Dictionary:
	var frage := PhysicsRayQueryParameters3D.create(blick, wunsch, SICHT_MASKE)
	if _spieler != null:
		frage.exclude = [_spieler.get_rid()]
	var treffer := _raum.intersect_ray(frage)
	if treffer.is_empty():
		return {"kamera": wunsch, "treffer": {}}
	var weg: Vector3 = (treffer["position"] as Vector3) - blick
	var laenge := weg.length()
	if laenge <= KorridorKamera.SICHT_MINDEST:
		return {"kamera": wunsch, "treffer": {}}
	var kamera := blick + weg.normalized() * maxf(laenge - KorridorKamera.SICHT_PUFFER,
			KorridorKamera.SICHT_MINDEST)
	return {"kamera": kamera, "treffer": treffer}


## Modell und freie Sicht je Probestelle, dazu der Boden am Blickpunkt.
func _kamera_modelle(stellen: Array[Dictionary]) -> Array[Dictionary]:
	var modelle: Array[Dictionary] = []
	for st in stellen:
		var m := _kamera_modell(st["fuss"] as Vector3)
		m.merge(_freie_sicht(m["blick"] as Vector3, m["wunsch"] as Vector3))
		m["boden"] = _boden_am_blick(m["blick"] as Vector3)
		modelle.append(m)
	return modelle


## Fester Boden (Ebene 1, ohne Kisten) senkrecht über oder unter dem
## Blickpunkt, bis drei Meter weit – oder {}.
func _boden_am_blick(blick: Vector3) -> Dictionary:
	var frage := PhysicsRayQueryParameters3D.create(blick + Vector3.UP * 3.0,
			blick + Vector3.DOWN * 3.0, 1, _ausschluss)
	return _raum.intersect_ray(frage)


# ------------------------------------------------------------- Sichtprobe

## Sichtschlauch der Verfolgerkamera (Plan K2).
##
## Je Probestelle der Strahl, den die Kamera schickt. Bewertet wird, wohin
## er sie holen würde:
##   FEHLER    fester Körper (Ebene 1) holt sie mehr als HERANHOLEN_GRENZE
##             heran, oder irgendein Treffer setzt sie vor die Figur – auch
##             eine Kiste, die regelgerecht auf dem Boden steht (Plan P2);
##             gestapelte oder schwebende Kisten im Schlauch sind immer
##             FEHLER (Plan K3: Stapel gehören außen neben den Schlauch)
##   WARNUNG   eine Kiste auf dem Boden, die die Kamera heranholt, aber
##             hinter der Figur lässt (Kisten zerbrechen, die Stelle ist
##             flüchtig), eine Sichtsperre (Ebene 8, sie ist dafür da), oder
##             der Boden, wenn der Blickpunkt in ihm liegt (die Ursache
##             meldet die Gefälleprobe)
## Bergauf trifft der Strahl jede Kiste, die 3,4–4,6 m vor der Figur am
## Hang steht: Der Blickpunkt liegt auf Figur +1, die Kamera nur auf
## Figur +4,4, und die Kiste reicht bei 17 % bis Figur +1,7. Kisten gehören
## dort auf ebene Absätze (Level 01, Wendel).
## Nahe Treffer (unter SICHT_MINDEST) ignoriert die Kamera, die Probe auch.
##
## Zu den Querlagen kommt der Anlauf auf jede Kiste (`_anlaufstellen`).
func _pruefe_sicht(stellen: Array[Dictionary], modelle: Array[Dictionary],
		anlauf: Array[Dictionary], anlauf_modelle: Array[Dictionary]) -> void:
	var bereiche := _bereiche(_sicht_funde(stellen, modelle), ["lage", "art", "name", "schwer"],
			SICHT_SCHRITT)
	bereiche.append_array(_bereiche(_sicht_funde(anlauf, anlauf_modelle),
			["lage", "art", "name", "schwer"], 0.5))
	bereiche.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["von"]) < float(b["von"]))
	var fehler := 0
	var zaehler := {"kiste": 0, "sperre": 0, "boden": 0}
	for b in bereiche:
		var text := "Sichtschlauch s %s %s: %s holt die Kamera %.1f m heran%s" % [
				_spanne(b), b["lage"], b["name"], float(b["wert"]),
				", vor die Figur" if bool(b["vor"]) else ""]
		if bool(b["schwer"]):
			print("  FEHLER  " + text)
			_fehler += 1
			fehler += 1
		else:
			print("  WARNUNG " + text)
			_warnungen += 1
			var art: String = b["art"]
			zaehler[art] = int(zaehler.get(art, 0)) + 1
	print("  Sichtschlauch: %d Stellen geprüft (%d im Anlauf auf Kisten), %d Fehler; Warnungen: %d Kisten, %d Sichtsperren, %d Boden"
			% [stellen.size() + anlauf.size(), anlauf.size(), fehler, int(zaehler["kiste"]),
			int(zaehler["sperre"]), int(zaehler["boden"])])


## Anlauf auf jede Kiste. Wer eine Kiste zerschlagen oder auf sie springen
## will, läuft in ihrer Querlage auf sie zu – und genau dort trifft der
## Strahl einen Stapel (die Querlagen −Rand/0/+Rand gehen an den meisten
## Kisten vorbei). Stellen 3–5,5 m vor jeder Kiste, halbmeterweise, in
## ihrer Querlage (höchstens bis zum Rand). Kisten neben dem Weg (auf
## Simsen und Wurzeln) haben keinen Anlauf auf dem Weg.
##
## Dazu die Querlagen, in denen der Strahl die Kiste mittig trifft: Die
## Kamera folgt seitlich nur zu `seiten_faktor`, der Strahl liegt also bei
## 0,85 · q der Figur. Wer bei q 3 läuft, schickt ihn durch eine Kiste bei
## q 2,6 – in keiner der Lagen oben. Deshalb auch q/0,85 und ±0,5 m daneben.
func _anlaufstellen() -> Array[Dictionary]:
	var faktor := _kamera.seiten_faktor if _kamera != null else 0.85
	var verlauf := _verlauf()
	var stellen: Array[Dictionary] = []
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var k := knoten as Kiste
		if k == null:
			continue
		var s_k := _strecke(k.global_position)
		var versatz := k.global_position - verlauf.sample_baked(s_k)
		versatz.y = 0.0
		var q_k := versatz.dot(LevelWerkzeuge.richtung(verlauf, s_k).cross(Vector3.UP).normalized())
		var halb: float = float(_level.call("breite_bei", s_k)) * 0.5
		if absf(q_k) > halb + 0.5:
			continue
		var lagen: Array[float] = [q_k]
		if faktor > 0.01:
			var mittig := q_k / faktor
			for dq: float in [0.0, -0.5, 0.5]:
				lagen.append(mittig + dq)
		var d := 3.0
		while d <= 5.51:
			var s := s_k - d
			d += 0.5
			var breite: float = _level.call("breite_bei", s)
			if breite <= 0.0:
				continue
			var rand := maxf(breite * 0.5 - SICHT_RANDABSTAND, 0.0)
			var gesetzt: Array[float] = []
			for lage in lagen:
				var q := clampf(lage, -rand, rand)
				var doppelt := false
				for g in gesetzt:
					if absf(g - q) < 0.2:
						doppelt = true
				if doppelt:
					continue
				gesetzt.append(q)
				var fuss := _figur_ort(verlauf, s, q)
				if fuss.is_finite():
					stellen.append({"s": s, "q": q, "fuss": fuss, "lage": "im Anlauf"})
	stellen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["s"]) < float(b["s"]))
	return stellen


## Die Funde der Sichtprobe an diesen Stellen, einzeln (siehe `_pruefe_sicht`).
func _sicht_funde(stellen: Array[Dictionary], modelle: Array[Dictionary]) -> Array[Dictionary]:
	var funde: Array[Dictionary] = []
	for i in stellen.size():
		var m := modelle[i]
		var treffer: Dictionary = m["treffer"]
		if treffer.is_empty():
			continue
		var st := stellen[i]
		var fuss: Vector3 = st["fuss"]
		var blick: Vector3 = m["blick"]
		var wunsch: Vector3 = m["wunsch"]
		var kamera: Vector3 = m["kamera"]
		var heran := wunsch.distance_to(kamera)
		var vorn := blick - wunsch
		vorn.y = 0.0
		var hinter := (fuss - kamera).dot(vorn.normalized())
		var vor_figur := hinter < HINTER_FIGUR
		var art := _trefferart(treffer, m["boden"] as Dictionary, blick)
		var schwer := false
		match art:
			"kiste":
				# Heranholen an eine Kiste ist flüchtig (sie zerbricht), vor
				# die Figur nie: Die Kamera schwenkte bei jedem Anlauf an ihr
				# vorbei (Plan P2, Level 01 bergauf in der Wendel).
				schwer = vor_figur
			"kiste_regelwidrig":
				schwer = true
			"sperre", "boden":
				schwer = vor_figur
			_:
				if heran <= HERANHOLEN_GRENZE and not vor_figur:
					continue
				schwer = true
		funde.append({"s": st["s"],
				"lage": String(st.get("lage", _lage_name(float(st["q"])))), "art": art,
				"name": _koerper_name(treffer["collider"] as Object),
				"wert": heran, "vor": vor_figur, "schwer": schwer})
	return funde


## "kiste", "kiste_regelwidrig", "sperre", "boden" oder "fest".
func _trefferart(treffer: Dictionary, boden: Dictionary, blick: Vector3) -> String:
	var c := treffer["collider"] as Object
	if c is Kiste:
		return "kiste" if _kiste_steht(c as Kiste) else "kiste_regelwidrig"
	if c is CollisionObject3D:
		var ebene := (c as CollisionObject3D).collision_layer
		if (ebene & LevelWerkzeuge.SICHTSPERRE) != 0 and (ebene & 1) == 0:
			return "sperre"
	if not boden.is_empty() and boden["collider"] == c \
			and (boden["position"] as Vector3).y > blick.y:
		return "boden"
	return "fest"


## Steht die Kiste regelgerecht auf festem Boden – nicht auf einer anderen
## Kiste und nicht in der Luft?
func _kiste_steht(k: Kiste) -> bool:
	var unten := _boden_unter_breit(k.global_position, _alle_koerper(k), k.global_position.y - 0.5)
	if unten.is_empty() or unten["collider"] is Kiste:
		return false
	return k.global_position.y - 0.5 - (unten["position"] as Vector3).y <= MAX_SCHWEBE


func _koerper_name(c: Object) -> String:
	if c is Kiste:
		var k := c as Kiste
		return "Kiste %s bei s %.1f" % [Kiste.Art.keys()[k.art], _strecke(k.global_position)]
	var n := c as Node
	if n == null:
		return "?"
	var eltern := n.get_parent()
	if eltern != null and eltern != _level.get("geometrie"):
		return "%s (%s)" % [n.name, eltern.name]
	return String(n.name)


func _lage_name(q: float) -> String:
	if q < -0.01:
		return "links"
	if q > 0.01:
		return "rechts"
	return "Mitte"


## Fasst Funde zu Strecken zusammen: aufeinanderfolgende Stellen (Abstand
## höchstens `schritt`) mit gleichen Werten in `schluessel`. Je Bereich
## "von", "bis", der größte "wert" und "vor", wenn es einmal zutraf.
func _bereiche(funde: Array[Dictionary], schluessel: Array, schritt: float) -> Array[Dictionary]:
	var offen := {}
	var fertig: Array[Dictionary] = []
	for f in funde:
		var teile := PackedStringArray()
		for k: String in schluessel:
			teile.append(str(f.get(k, "")))
		var kennung := "|".join(teile)
		var s: float = f["s"]
		if offen.has(kennung):
			var b: Dictionary = offen[kennung]
			if s - float(b["bis"]) <= schritt + 0.01:
				b["bis"] = s
				b["wert"] = maxf(float(b["wert"]), float(f.get("wert", 0.0)))
				b["vor"] = bool(b["vor"]) or bool(f.get("vor", false))
				continue
			fertig.append(b)
		var neu := f.duplicate()
		neu["von"] = s
		neu["bis"] = s
		neu["wert"] = float(f.get("wert", 0.0))
		neu["vor"] = bool(f.get("vor", false))
		offen[kennung] = neu
	for kennung: String in offen:
		fertig.append(offen[kennung])
	fertig.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["von"]) < float(b["von"]))
	return fertig


func _spanne(b: Dictionary) -> String:
	var von := "%.1f" % float(b["von"])
	var bis := "%.1f" % float(b["bis"])
	return von if von == bis else von + "–" + bis


# ------------------------------------------------------------- Abgleich

## Setzt die Figur an drei Stellen ab und vergleicht die echte Kamera mit
## dem Modell. Gewählt wird aus den Probestellen: vorn in der Wegmitte mit
## freier Sicht, hinter der Hälfte am rechten Rand mit freier Sicht, und
## eine Stelle, an der der Strahl trifft und die Kamera weit heranholt (so
## wird auch die Treffermathematik geprüft; auch aus dem Anlauf auf
## Kisten) – sonst eine dritte freie Stelle am linken Rand. Nie näher als
## 5,5 m an einem Gegner, nie auf einer Kiste.
func _kamera_abgleich(stellen: Array[Dictionary], modelle: Array[Dictionary]) -> void:
	if _spieler == null:
		return
	var laenge := _verlauf().get_baked_length()
	var wahl: Array[int] = [
		_abgleich_stelle(stellen, modelle, laenge * 0.15, 0, false),
		_abgleich_stelle(stellen, modelle, laenge * 0.5, 1, false),
		_abgleich_stelle(stellen, modelle, 0.0, 0, true),
	]
	if wahl[2] < 0:
		wahl[2] = _abgleich_stelle(stellen, modelle, laenge * 0.75, -1, false)
	var groesste := 0.0
	var geprueft := 0
	for i in wahl:
		if i < 0:
			continue
		var fuss: Vector3 = stellen[i]["fuss"]
		_spieler.global_position = fuss + Vector3.UP * 0.02
		_spieler.velocity = Vector3.ZERO
		_spieler.reset_physics_interpolation()
		for k in 10:
			await get_tree().physics_frame
		_kamera.sofort_ausrichten()
		for k in 60:
			await get_tree().physics_frame
		await get_tree().process_frame
		var ort := Bildtakt.ort(_spieler)
		var m := _kamera_modell(ort)
		var soll: Vector3 = _freie_sicht(m["blick"] as Vector3, m["wunsch"] as Vector3)["kamera"]
		var ist := _kamera.global_position
		var abweichung := ist.distance_to(soll)
		var heran := (m["wunsch"] as Vector3).distance_to(soll)
		groesste = maxf(groesste, abweichung)
		geprueft += 1
		var text := "Kamera-Abgleich s %.1f %s (Kamera %.1f m herangeholt, steht bei %s): Abweichung %.3f m" % [
				float(stellen[i]["s"]),
				String(stellen[i].get("lage", _lage_name(float(stellen[i]["q"])))),
				heran, str(ist.snappedf(0.01)), abweichung]
		if abweichung > ABGLEICH_GRENZE:
			print("  FEHLER  " + text)
			_fehler += 1
		else:
			print("  " + text)
	print("  Kamera-Abgleich: %d Stellen geprüft, Abweichung höchstens %.3f m (Grenze %.1f)"
			% [geprueft, groesste, ABGLEICH_GRENZE])


## Index einer Probestelle für den Abgleich, oder -1. `seite`: -1 links,
## 0 Mitte, +1 rechts. `mit_treffer`: die Stelle, an der die Kamera am
## weitesten herangeholt würde (mindestens 2 m); sonst die erste freie ab
## `ab`.
func _abgleich_stelle(stellen: Array[Dictionary], modelle: Array[Dictionary],
		ab: float, seite: int, mit_treffer: bool) -> int:
	var beste := -1
	var bester_wert := 2.0
	for i in stellen.size():
		var st := stellen[i]
		var s: float = st["s"]
		var q: float = st["q"]
		var fuss: Vector3 = st["fuss"]
		if s < ab or not _fern_von_gegnern(fuss, 5.5):
			continue
		# Auf dem Weg, nicht auf einer Kiste.
		var boden: float = _level.call("boden_bei", s)
		if absf(fuss.y - boden) > 0.3:
			continue
		var m := modelle[i]
		var trifft := not (m["treffer"] as Dictionary).is_empty()
		if mit_treffer:
			var heran := (m["wunsch"] as Vector3).distance_to(m["kamera"] as Vector3)
			if trifft and heran > bester_wert:
				beste = i
				bester_wert = heran
			continue
		if trifft or int(signf(q)) != seite:
			continue
		return i
	return beste


func _fern_von_gegnern(p: Vector3, abstand: float) -> bool:
	for g in get_tree().get_nodes_in_group("gegner"):
		if (g as Node3D).global_position.distance_to(p) < abstand:
			return false
	return true


# ------------------------------------------------------------- Gefälle

## Liegt der Blickpunkt im Boden? Bergauf rückt der Boden sechs Meter vor
## der Figur über ihre Höhe + 1 m; bis 20 % bleibt der Blickpunkt darüber
## oder knapp darin, und die Kamera ignoriert den Austritt (unter
## SICHT_MINDEST). Tiefer als GEFAELLE_GRENZE ist FEHLER (Plan K4).
func _pruefe_gefaelle(stellen: Array[Dictionary], modelle: Array[Dictionary]) -> void:
	var funde: Array[Dictionary] = []
	var tiefste := -INF
	var tiefste_s := 0.0
	for i in stellen.size():
		var boden: Dictionary = modelle[i]["boden"]
		if boden.is_empty():
			continue
		var blick: Vector3 = modelle[i]["blick"]
		var tiefe := (boden["position"] as Vector3).y - blick.y
		if tiefe > tiefste:
			tiefste = tiefe
			tiefste_s = float(stellen[i]["s"])
		if tiefe > GEFAELLE_GRENZE:
			funde.append({"s": stellen[i]["s"], "lage": _lage_name(float(stellen[i]["q"])),
					"wert": tiefe})
	var bereiche := _bereiche(funde, ["lage"], SICHT_SCHRITT)
	for b in bereiche:
		print("  FEHLER  Gefälle s %s %s: Blickpunkt %.2f m im Boden (Grenze %.1f)"
				% [_spanne(b), b["lage"], float(b["wert"]), GEFAELLE_GRENZE])
		_fehler += 1
	if tiefste > 0.0:
		print("  Gefälle: %d Stellen geprüft, %d Probleme; Blickpunkt höchstens %.2f m im Boden (s %.0f)"
				% [stellen.size(), bereiche.size(), tiefste, tiefste_s])
	else:
		print("  Gefälle: %d Stellen geprüft, %d Probleme; Blickpunkt nirgends im Boden"
				% [stellen.size(), bereiche.size()])


# ------------------------------------------------------------- Todeszonen

## Legt alle Todeszonen für Punkt- und Strahlabfragen auf ZONEN_EBENE, oder
## stellt mit dem Rückgabewert des ersten Aufrufs den alten Stand wieder
## her. Die Zonen selbst merken nichts davon: Sie erkennen die Figur weiter
## über ihre Maske.
func _zonen_abfragbar(vorher: Dictionary) -> Dictionary:
	var alt := {}
	for z in get_tree().get_nodes_in_group("todeszonen"):
		var zone := z as Area3D
		if zone == null:
			continue
		if vorher.is_empty():
			alt[zone] = [zone.collision_layer, zone.monitorable]
			zone.collision_layer = ZONEN_EBENE
			zone.monitorable = true
		elif vorher.has(zone):
			var werte: Array = vorher[zone]
			zone.collision_layer = int(werte[0])
			zone.monitorable = bool(werte[1])
	await get_tree().physics_frame
	return alt


## Die Todeszone, in der der Punkt liegt, oder null. Dazu zwei Punkte
## wenige Zentimeter daneben: Die Zonen bestehen aus Prismen zu drei
## Metern, und ein Punkt genau auf einer Fuge läge in keinem.
func _zone_bei(p: Vector3) -> Area3D:
	var frage := PhysicsPointQueryParameters3D.new()
	frage.collide_with_areas = true
	frage.collide_with_bodies = false
	frage.collision_mask = ZONEN_EBENE
	for versatz: Vector3 in [Vector3.ZERO, Vector3(0.04, 0.0, 0.02), Vector3(-0.02, 0.0, -0.04)]:
		frage.position = p + versatz
		for t in _raum.intersect_point(frage, 4):
			var c := t["collider"] as Node
			if c != null and c.is_in_group("todeszonen"):
				return c as Area3D
	return null


## Liegt ein begehbarer Punkt in einer Todeszone (Plan Abschnitt 12)?
## Geprüft werden die Probestellen (alle 2 m, drei Querlagen) und die
## Oberseiten aus BEGEHBARES, je ZONEN_PRUEFHOEHE darüber. Den Boden bis
## an die Leitlinien – Schultern, Vorsprünge, Kanzel – prüft der Randgang
## Schritt für Schritt mit.
func _pruefe_todeszonen(stellen: Array[Dictionary]) -> void:
	var punkte: Array[Dictionary] = []
	for st in stellen:
		punkte.append({"s": st["s"], "name": "Weg " + _lage_name(float(st["q"])),
				"punkt": st["fuss"]})
	punkte.append_array(_begehbar_oberseiten())
	var funde: Array[Dictionary] = []
	for p in punkte:
		var zone := _zone_bei((p["punkt"] as Vector3) + Vector3.UP * ZONEN_PRUEFHOEHE)
		if zone != null:
			funde.append({"s": p["s"], "name": p["name"], "zone": String(zone.name)})
	var bereiche := _bereiche(funde, ["name", "zone"], SICHT_SCHRITT)
	for b in bereiche:
		print("  FEHLER  Todeszone %s reicht über begehbaren Boden: %s bei s %s"
				% [b["zone"], b["name"], _spanne(b)])
		_fehler += 1
	print("  Todeszonen: %d begehbare Punkte geprüft, %d Probleme" % [punkte.size(), bereiche.size()])


## Punkte auf den Oberseiten aller Einträge aus BEGEHBARES, je
## {"s", "name", "punkt"}. Kästen, Walzen und Kapseln über ihre Lage;
## Streifen und Sweeps über ihre Querschnitte: jede nicht steile Kante, die
## oben liegt (das Innere des Querschnitts ist darunter).
func _begehbar_oberseiten() -> Array[Dictionary]:
	var punkte: Array[Dictionary] = []
	var skript := _level.get_script() as Script
	if skript == null or not _level.has_method("begehbar"):
		return punkte
	var liste: Variant = skript.get_script_constant_map().get("BEGEHBARES")
	if not liste is Array:
		return punkte
	for roh: Dictionary in liste:
		var name := String(roh["name"])
		var e: Dictionary = _level.call("begehbar", name)
		if e.is_empty():
			continue
		var auf: Array[Vector3] = []
		match String(e["form"]):
			"kasten":
				var lage: Transform3D = e["lage"]
				var g: Vector3 = e["groesse"]
				for fx: float in [-0.35, 0.0, 0.35]:
					for fz: float in [-0.35, 0.0, 0.35]:
						auf.append(lage * Vector3(fx * g.x, g.y * 0.5, fz * g.z))
			"zylinder":
				var lage: Transform3D = e["lage"]
				var r: float = e["radius"]
				var h: float = e["hoehe"]
				auf.append(lage * Vector3(0.0, h * 0.5, 0.0))
				for w in 4:
					var winkel := TAU * float(w) / 4.0
					auf.append(lage * Vector3(cos(winkel) * r * 0.6, h * 0.5, sin(winkel) * r * 0.6))
			"kapsel":
				var lage: Transform3D = e["lage"]
				var r: float = e["radius"]
				var halb := maxf(float(e["laenge"]) * 0.5 - r, 0.0)
				for k in 5:
					auf.append(lage * Vector3(lerpf(-halb, halb, float(k) / 4.0), r, 0.0))
			_:
				var schnitte: Array = e.get("querschnitte", [])
				for schnitt: PackedVector3Array in schnitte:
					auf.append_array(_schnitt_oberseite(schnitt))
		for p in auf:
			punkte.append({"s": _strecke(p), "name": name, "punkt": p})
	return punkte


## Die Punkte auf den oberen, nicht steilen Kanten eines senkrechten
## Querschnitts (Weltpunkte, alle auf einer Querlinie).
func _schnitt_oberseite(schnitt: PackedVector3Array) -> Array[Vector3]:
	var auf: Array[Vector3] = []
	if schnitt.size() < 3:
		return auf
	# In die Ebene des Schnitts: u quer, v hoch.
	var quer := Vector3.ZERO
	for p in schnitt:
		var d := p - schnitt[0]
		d.y = 0.0
		if d.length() > quer.length():
			quer = d
	if quer.length() < 0.01:
		return auf
	quer = quer.normalized()
	var flach: Array[Vector2] = []
	for p in schnitt:
		flach.append(Vector2((p - schnitt[0]).dot(quer), p.y))
	for i in flach.size():
		var a := flach[i]
		var b := flach[(i + 1) % flach.size()]
		var breite := absf(b.x - a.x)
		if breite < 0.1 or absf(b.y - a.y) > breite:
			continue
		for t: float in [0.25, 0.75]:
			var m := a.lerp(b, t)
			if Geometry2D.is_point_in_polygon(m + Vector2(0.0, 0.05), PackedVector2Array(flach)):
				continue
			var w := schnitt[i].lerp(schnitt[(i + 1) % schnitt.size()], t)
			auf.append(w)
	return auf


# ------------------------------------------------------------- Randgang

## Geht an jeder Stelle (alle RAND_SCHRITT Meter, um ein Viertel versetzt)
## von der Wegmitte nach links und rechts, in RAND_QUER-Schritten, bis eine
## Wand (Ebene 1|16) im Weg steht. Wo der nächste Schritt keinen Boden
## innerhalb RAND_STUFE findet, fällt man: Darunter muss eine Todeszone
## liegen, und zwar über jedem Boden (sonst strandet man tief unten), oder
## ein Boden höchstens WEICHER_FALL unter dem Weg (von dort geht es zurück:
## Wurzelwiese, G1-Grube). Jeder Schritt mit Boden ist begehbar und darf in
## keiner Todeszone liegen.
##
## Bodenstrahlen je Schritt dreifach, ±0,12 m längs versetzt: Die Nähte
## zweier konvexer Stücke trifft ein Strahl genau auf der Fuge nicht.
func _pruefe_rand() -> void:
	var verlauf := _verlauf()
	var laenge := verlauf.get_baked_length()
	var loecher: Array[Dictionary] = []
	var in_zone: Array[Dictionary] = []
	var weich := {}
	var gaenge := 0
	var s := -6.0 + RAND_SCHRITT * 0.5
	while s <= laenge:
		var luecke := bool(_level.call("ist_luecke", s)) if _level.has_method("ist_luecke") \
				else float(_level.call("breite_bei", s)) <= 0.0
		if not (luecke and s >= 0.0):
			for seite: float in [-1.0, 1.0]:
				gaenge += 1
				var e := _randgang(verlauf, s, seite)
				if e.has("loch"):
					loecher.append(e)
				if e.has("weich"):
					var name: String = e["weich"]
					weich[name] = int(weich.get(name, 0)) + 1
				for z: Dictionary in e.get("zonen", []):
					in_zone.append(z)
		s += RAND_SCHRITT
	for b in _bereiche(loecher, ["lage", "loch"], RAND_SCHRITT):
		print("  FEHLER  Rand s %s %s: %s (%s)" % [_spanne(b), b["lage"], b["loch"], b["genauer"]])
		_fehler += 1
	for b in _bereiche(in_zone, ["lage", "zone"], RAND_SCHRITT):
		print("  FEHLER  Todeszone %s reicht über begehbaren Boden am Rand %s, s %s"
				% [b["zone"], b["lage"], _spanne(b)])
		_fehler += 1
	var landungen := PackedStringArray()
	for name: String in weich:
		landungen.append("%s %d×" % [name, int(weich[name])])
	print("  Randgang: %d Gänge geprüft, %d Löcher, %d Stellen in Todeszonen; weiche Landung: %s"
			% [gaenge, _bereiche(loecher, ["lage", "loch"], RAND_SCHRITT).size(),
			in_zone.size(), ", ".join(landungen) if not landungen.is_empty() else "keine"])


## Ein Gang von der Mitte nach `seite`. Ergebnis: {} ohne Befund, sonst mit
## "loch" (Beschreibung), "weich" (Name des auffangenden Bodens) und
## "zonen" (begehbare Punkte in Todeszonen), dazu "s" und "lage".
func _randgang(verlauf: Curve3D, s: float, seite: float) -> Dictionary:
	var ergebnis := {"s": s, "lage": _lage_name(seite)}
	var zonen: Array[Dictionary] = []
	var deck: float = _level.call("boden_bei", s)
	var q := 0.0
	var vorher := LevelWerkzeuge.punkt_frei(verlauf, s, 0.0)
	vorher.y = deck + 0.9
	while absf(q) < RAND_WEIT:
		q += seite * RAND_QUER
		var p := LevelWerkzeuge.punkt_frei(verlauf, s, q)
		p.y = deck + 0.9
		# Wand: ein Strahl vom letzten Schritt her stößt an, oder der Schritt
		# steckt schon in einem Körper. Das Zweite braucht es an schrägen
		# Flanken (das Wurzelfleisch der Wendel, 56°): Dort beginnt der
		# Strahl bereits im Körper und trifft ihn nicht, während der
		# Bodenstrahl die Flanke als Boden findet – der Gang stiege sonst
		# die Flanke hinauf und meldete in ihr ein Loch.
		var laengs := LevelWerkzeuge.punkt_frei(verlauf, s + 0.12, q) - p
		laengs.y = 0.0
		if _in_koerper(p, laengs):
			break
		var wand := false
		for h: float in [-0.5, 0.0, 0.5]:
			var frage := PhysicsRayQueryParameters3D.create(vorher + Vector3.UP * h,
					p + Vector3.UP * h, BODEN_MASKE, _bewegliche)
			if not _raum.intersect_ray(frage).is_empty():
				wand = true
				break
		if wand:
			break
		var boden := {}
		for d: float in [0.0, 1.0, -1.0]:
			var pp := p + laengs * d
			var frage := PhysicsRayQueryParameters3D.create(pp + Vector3.UP * 0.6,
					pp + Vector3.DOWN * RAND_STUFE, BODEN_MASKE, _bewegliche)
			boden = _raum.intersect_ray(frage)
			if not boden.is_empty():
				break
		if boden.is_empty():
			_randgang_fall(ergebnis, p, laengs, deck, q)
			break
		var zone := _zone_bei((boden["position"] as Vector3) + Vector3.UP * ZONEN_PRUEFHOEHE)
		if zone != null:
			zonen.append({"s": s, "lage": ergebnis["lage"], "zone": String(zone.name)})
		vorher = p
	if not zonen.is_empty():
		ergebnis["zonen"] = zonen
	return ergebnis


## Steckt ein Punkt über dem Schritt (Figurmitte ±0,5 m, dazu je `laengs`
## davor und dahinter) in einem festen Körper (1|16)? Längs versetzt aus
## demselben Grund wie die Bodenstrahlen: Ein Punkt genau auf der Fuge
## zweier konvexer Stücke liegt für die Abfrage in keinem von beiden.
## Trimesh-Böden haben kein Inneres und zählen hier nicht – sie sind Boden.
func _in_koerper(p: Vector3, laengs: Vector3) -> bool:
	for d: float in [0.0, 1.0, -1.0]:
		for h: float in [-0.5, 0.0, 0.5]:
			var frage := PhysicsPointQueryParameters3D.new()
			frage.position = p + laengs * d + Vector3.UP * h
			frage.collision_mask = BODEN_MASKE
			frage.exclude = _bewegliche
			if not _raum.intersect_point(frage, 1).is_empty():
				return true
	return false


## Der Schritt bei `p` führt ins Leere. Fängt eine Todeszone den Sturz, ist
## alles gut; fängt ein naher Boden ihn auf, heißt das "weich"; sonst ein
## Loch.
func _randgang_fall(ergebnis: Dictionary, p: Vector3, laengs: Vector3, deck: float,
		q: float) -> void:
	var zone_y := -INF
	for d: float in [0.0, 1.0, -1.0]:
		var pp := p + laengs * d
		if _zone_bei(pp) != null:
			zone_y = pp.y
			break
		var abwaerts := PhysicsRayQueryParameters3D.create(pp,
				pp + Vector3.DOWN * ZONEN_FALLTIEFE, ZONEN_EBENE)
		abwaerts.collide_with_areas = true
		abwaerts.collide_with_bodies = false
		var t := _raum.intersect_ray(abwaerts)
		if not t.is_empty():
			zone_y = maxf(zone_y, (t["position"] as Vector3).y)
	var frage := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 60.0,
			BODEN_MASKE, _bewegliche)
	var boden := _raum.intersect_ray(frage)
	var boden_y := -INF
	var boden_name := "keiner"
	if not boden.is_empty():
		boden_y = (boden["position"] as Vector3).y
		boden_name = "%s auf %.1f" % [_koerper_name(boden["collider"] as Object), boden_y]
	if zone_y > -INF and zone_y > boden_y:
		return
	if boden_y > -INF and deck - boden_y <= WEICHER_FALL:
		ergebnis["weich"] = _koerper_name(boden["collider"] as Object)
		return
	# "loch" fasst gleiche Ursachen über viele Stellen zusammen, "genauer"
	# nennt die Werte der ersten.
	ergebnis["loch"] = "kein Boden, darunter %s, %s" % [
			"nichts" if boden.is_empty() else _koerper_name(boden["collider"] as Object),
			"keine Todeszone" if zone_y == -INF else "Todeszone erst darunter"]
	ergebnis["genauer"] = "ab q %.1f: Boden %s, Todeszone %s" % [
			q, boden_name, "keine" if zone_y == -INF else "auf %.1f" % zone_y]
