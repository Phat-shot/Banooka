extends RefCounted
class_name Effekte
## Gemeinsamer Effekt-Helfer: kurze Teilchenstöße, Kamerawackeln,
## Trefferpause, Bildblitz, Blitzlicht und der Bodenfleck unter Figuren.
##
## Nur statische Funktionen, nichts muss in den Baum gehängt werden – nach
## dem Muster von `Leuchtmarker` und `Explosion.erzeugen`:
##     Effekte.staubwolke(self, global_position)
##     Effekte.funken(self, pos, Farben.KISTE_LEBEN, 16, 5.0)
##     Effekte.erschuettern(self, 0.45)
##
## ------------------------------------------------------------ SCHNITTSTELLE
## Jeder Stoß gibt seinen `CPUParticles3D` zurück, oder `null`, wenn er
## wegen einer Grenze (siehe unten) entfallen ist. Aufrufer müssen `null`
## vertragen. Der Rückgabewert darf IM SELBEN BILD noch nachgestellt
## werden (etwa `flatness`, `gravity`), weil erst am Bildende gezündet
## wird – aber NIE sein Material (`material_override` ist geteilt).
##
## `bei` ist immer ein beliebiger Knoten im Baum (meist `self`); er liefert
## nur Baum, Viewport und Kamera. Der Effekt hängt NICHT an ihm.
## `pos` ist immer global.
##
##   staubwolke(bei, pos, staerke := 1.0, farbe := KEINE_FARBE)
##       Flache Staubwolke am Boden (Landung, Absprung). `pos` = Bodenpunkt.
##       `staerke` 0.1..2 skaliert Menge, Größe und Tempo. Ohne Farbe gilt
##       `Effekte.staubfarbe` des Levels.
##   funken(bei, pos, farbe, anzahl := 10, tempo := 4.5, groesse := 0.2,
##           streuung := 180.0)
##       Leuchtende Funken, additiv. `streuung` in Grad um die Senkrechte:
##       180 = in alle Richtungen, 30 = Fontäne nach oben.
##   aufblitzen(bei, pos, farbe, groesse := 1.2, dauer := 0.12)
##       Ein einzelner heller Lichtfleck, der aufgeht und verlischt.
##   splitter(bei, pos, stoff: Material, anzahl := 10)
##       Bretter mit der Fase der Kiste fliegen im Bogen davon. `stoff` ist
##       das Material der zerbrochenen Kiste (geteilt, wird nur referenziert).
##       `pos` = Mitte der Kiste.
##   rauch(bei, pos, farbe, groesse := 1.0, anzahl := 8)
##       Langsam aufsteigende, weiche Rauchballen (Gegner verpufft, Explosion).
##   ring(bei, pos, farbe, radius, dauer := 0.3, achse := Vector3.UP)
##       Flache Druckwelle. `radius` ist GENAU der sichtbare Außenradius am
##       Ende – so zeigt der Bauchplatscher-Ring den echten Wirkradius.
##       `achse` = Flächennormale (UP = liegt am Boden, BACK = steht aufrecht).
##   lichtsaeule(bei, pos, farbe, hoehe := 6.0, radius := 0.7, dauer := 0.9)
##       Aufschießende Lichtsäule mit steigenden Funken (Checkpoint).
##       Belegt zwei Stöße.
##   blitzlicht(bei, pos, farbe, energie := 6.0, reichweite := 7.0,
##           dauer := 0.35) -> OmniLight3D
##       Kurzes Punktlicht, höchstens `MAX_LICHTER` gleichzeitig.
##   erschuettern(bei, staerke, pos := Vector3.INF) -> void
##       Kamerawackeln, siehe KAMERAVERTRAG. Mit `pos` fällt die Stärke mit
##       dem Abstand zur Figur ab (0 ab `ABFALL_WEITE` Metern).
##   trefferpause(bei, dauer := 0.05) -> void
##       Friert das Spiel für `dauer` Sekunden fast ein (Treffergefühl).
##   bildblitz(bei, farbe, dauer := 0.25) -> void
##       Vollbild-Farbschleier, der ausblendet. Liegt UNTER dem HUD.
##
## Dauerhafte Bausteine (gehören dem Aufrufer, zählen nicht zu den Grenzen):
##   blobschatten(eltern: Node3D, radius := 0.45) -> MeshInstance3D
##   blobschatten_setzen(schatten, punkt, normale, deckkraft, skala := 1.0)
##       Weicher runder Fleck am Boden unter einer Figur in der Luft. Der
##       Aufrufer sucht den Boden per Strahl und setzt ihn jedes Bild.
##   dauerstaub(traeger: Node3D, gleiten := false, farbe := KEINE_FARBE)
##       Lauf- bzw. Slidestaub. Startet AUS; der Aufrufer schaltet `emitting`
##       (nur bei Wechsel, nicht jedes Bild).
##   dauerfunken(traeger: Node3D, ort: Vector3, farbe := Farben.GLUT)
##       Glimmende Zündschnur: sprüht ständig, bis der Träger verschwindet.
##
## Zubehör:
##   vorwaermen(bei)            Shader einmal zeichnen lassen (Ladeschirm).
##   wirbelstoff(farbe, kern, saum) -> ShaderMaterial
##       Neues Material mit `shaders/portal_wirbel.gdshader` (je Portal eins).
##   stoff(art: Stoff) -> StandardMaterial3D   geteilte Teilchenmaterialien
##   teilchen_netz() -> QuadMesh, weiche_textur() -> Texture2D
##       für eigene Emitter (etwa den Funkenkranz eines Portals).
##   aktive() -> int, lichter() -> int      für Prüfwerkzeuge.
##
## Zustand (statisch, überlebt Szenenwechsel):
##   reduziert: bool   halbiert die Mengen und schaltet Wackeln,
##                     Trefferpause, Bildblitz und Blitzlicht ab.
##   ruhig: bool       nur Wackeln, Trefferpause und Bildblitz aus – die
##                     Einstellung „Bildschirmwackeln" (Einstellungen.gd).
##   staubfarbe: Color Farbe für Staub ohne eigene Farbe. Sie überlebt den
##                     Szenenwechsel – deshalb setzt `LevelBasis` sie vor
##                     JEDEM Aufbau auf `STAUBFARBE_VORGABE` (Waldweg), sonst
##                     staubte es in Level 01 noch weiß vom Frostgrat. Jedes
##                     Level, dessen Boden kein Waldweg ist, setzt beim Bauen
##                     seine eigene (Schnee, Bohlen, Stein, Blech, Sand …).
##
## ------------------------------------------------------------ KAMERAVERTRAG
## Eine Kamera, die wackeln kann, hat die Methode
##     func erschuettern(staerke: float) -> void
## `staerke` ist „Trauma" von 0 bis 1: 0 = nichts, 1 = das Heftigste, was
## das Spiel kennt (TNT direkt neben der Figur). Die Kamera
##   * nimmt das MAXIMUM aus altem und neuem Wert, nicht die Summe – sonst
##     schaukelt sich eine Kistenkette zum Erdbeben auf;
##   * lässt den Wert selbst abklingen (etwa 2 je Sekunde);
##   * macht den Ausschlag proportional zu staerke² – kleine Stöße bleiben
##     so klein, große werden deutlich;
##   * setzt ihn beim Neuausrichten (`sofort_ausrichten`) auf 0.
## Abstand und `reduziert` sind hier schon verrechnet. Übliche Stärken:
## Bauchplatscher 0.45, TNT/Nitro 0.7 (mit `pos`), Schutz verloren 0.35,
## Gegner besiegt 0.2, Kiste durch Bauchplatscher 0.15. Kein Wackeln für
## einen gewöhnlichen Kistenbruch – Level 01 hat 43 Kisten.
## Angesprochen wird die Kamera nur per `has_method` (Duck-Typing wie bei
## `sofort_ausrichten`), weil Level 22 eine Flugkamera nutzt und die
## Werkzeuge eigene Kameras haben.
##
## ------------------------------------------------------------ REGELN
## * FARBEN NIE INS MATERIAL. Die Materialien hier sind geteilt; die Farbe
##   jedes Stoßes steckt in `color` des Emitters und läuft über die
##   Scheitelfarbe in den Shader. Wer ein Material ändert, färbt jeden
##   Funken des Spiels um.
## * Effekte hängen an `current_scene`, NIE an Kisten oder Früchten: Der
##   `Leuchtmarker` (Level 23) kopiert beim Aufbau die Materialien des
##   ganzen Unterbaums der Gruppen „kisten" und „fruechte"; ein Funke
##   darunter bekäme ein Eigenleuchten und eine eigene Materialkopie. Und
##   eine Frucht, die sich nach dem Einsammeln freigibt, nähme ihre Funken
##   mit ins Grab. Szenenwechsel räumen so von selbst auf.
## * Warum `CPUParticles3D` und nicht `GPUParticles3D`: siehe `Staubflug`
##   (scenes/props/staub.gd). Unter gl_compatibility fehlt Transform-
##   Feedback je nach Treiber (Android, WebGL) oder liegt still daneben.
##   CPU-Teilchen sind intern ein MultiMesh: ein Draw-Call je Stoß, die
##   Bahn wird auf der CPU gerechnet – bei zehn Teilchen belanglos.
## * Die teure Seite im Web ist Füllrate: große, durchsichtige Flächen dicht
##   vor der Kamera. Deshalb bleiben die Teilchen klein und die Zahl der
##   gleichzeitigen Stöße gedeckelt.

## Höchstens so viele Stöße gleichzeitig. Ein Stoß lebt unter 1,2 s.
const MAX_AKTIV := 24
## Höchstens so viele neue Stöße in einem Bild. Fängt Bauchplatscher auf
## einen Kistenhaufen und TNT-Ketten ab, die alle im selben Bild brechen.
## 8 statt 6: Ein Kistenbruch kostet drei Stöße (Splitter, Staub, Blitz);
## zwei Kisten unter einem Bauchplatscher und dessen eigener Ring müssen
## noch hineinpassen, sonst fällt ausgerechnet der Ring weg, der dem
## Spieler die Reichweite zeigt.
const MAX_JE_BILD := 8
## Punktlichter sind unter gl_compatibility teuer (siehe `Lichtkreis`),
## eine TNT-Kette erzeugte vorher eines je Kiste.
const MAX_LICHTER := 2
## Ab dieser Entfernung (Meter) zur Figur wackelt die Kamera nicht mehr.
const ABFALL_WEITE := 14.0
## Spieltempo während der Trefferpause. Nicht 0: Ganz angehalten wirkt es
## wie ein Ruckler, fast angehalten wie ein Aufprall.
const PAUSE_TEMPO := 0.05
## Längste erlaubte Trefferpause. Was länger steht, fühlt sich nicht mehr
## wie Wucht an, sondern wie ein Hänger.
const PAUSE_HOECHSTENS := 0.2
## Tempo der Vorwärmteilchen (siehe `vorwaermen`): 0,2 s Lebenszeit
## reichen so für ein erstes Bild von 20 s.
const VORWAERM_ZEITLUPE := 0.01
## Gruppe für Netze, die selten zu sehen sind und bis dahin verborgen
## stehen (Schutzgeist bei Stufe 0, Spin-Ring). `vorwaermen()` zeichnet je
## einen winzigen Abklatsch, damit ihr Shader nicht erst im Spiel übersetzt
## wird.
const VORWAERM_GRUPPE := "vorwaermen"
## So lange stehen die Abklatsche vor der Kamera, in Sekunden. Das Bild
## nach dem Aufbau ist lang; wie bei den Teilchen soll der Abklatsch es
## sicher erleben.
const VORWAERM_DAUER := 0.8
## Wegstaub im Wald – die Vorgabe für `staubfarbe`.
const STAUBFARBE_VORGABE := Farben.WEG_HELL
## Platzhalter für „keine Farbe angegeben" (Alpha 0).
const KEINE_FARBE := Color(0.0, 0.0, 0.0, 0.0)
## Der Wirbel-Shader für Portalscheiben.
const WIRBEL_SHADER: Shader = preload("res://shaders/portal_wirbel.gdshader")

## Die geteilten Teilchenmaterialien.
## ALPHA   Rauch, Staub: gemischt, weicher Fleck, Billboard.
## ADDITIV Funken, Blitze: addiert, Fleck mit hellem Kern, Billboard.
## RING    Druckwelle: addiert, liegt flach (kein Billboard), Ringtextur.
## SAEULE  Lichtsäule: addiert, kein Billboard, Verlauf über Scheitelfarben.
enum Stoff { ALPHA, ADDITIV, RING, SAEULE }

## Halbiert Mengen, schaltet Wackeln, Trefferpause, Bildblitz und
## Blitzlicht ab. Vorbelegt auf Handys – im Browser wie als App (Android,
## iOS) –, wo Füllrate knapp ist; später kommt ein Schalter in den Optionen
## dazu (Einstellungen.gd).
static var reduziert: bool = _vorbelegung()
## Ruhiges Bild: kein Wackeln, keine Trefferpause, kein Bildblitz. Für
## alle, denen von einem wackelnden Bild übel wird oder die Blitze meiden
## müssen. Anders als `reduziert` bleiben Mengen und Blitzlicht, wie sie
## sind – es geht um das Bild als Ganzes, nicht um Füllrate. Gesetzt von
## `Einstellungen` (Zeile „Bildschirmwackeln" in den Optionen).
static var ruhig: bool = false
## Staubfarbe des laufenden Levels (siehe Kopfkommentar: je Level setzen).
static var staubfarbe: Color = STAUBFARBE_VORGABE

# --- Buchhaltung der Grenzen ---
static var _aktiv := 0
static var _lichter := 0
static var _bild := -1
static var _im_bild := 0

# --- Caches: einmal gebaut, danach NIE verändert. Sie überleben
# Szenenwechsel (wie `Staubflug._shader`) und halten deshalb keine Knoten.
static var _stoffe: Dictionary[int, StandardMaterial3D] = {}
static var _kurven: Dictionary[String, Curve] = {}
static var _verlaeufe: Dictionary[String, Gradient] = {}
static var _saeulen: Dictionary[String, ArrayMesh] = {}
static var _weich: GradientTexture2D = null
static var _ringbild: GradientTexture2D = null
static var _glutbild: GradientTexture2D = null
static var _fleckbild: GradientTexture2D = null
static var _quad: QuadMesh = null
static var _scheibe: PlaneMesh = null
static var _brett: ArrayMesh = null

# --- Bildblitz: eine Schicht je Szene, stirbt mit ihr ---
static var _blitzschicht: CanvasLayer = null
static var _blitzflaeche: ColorRect = null
static var _blitztween: Tween = null


# ================================================================ Stöße

## Flache Staubwolke am Boden. `pos` ist der Bodenpunkt unter der Figur.
static func staubwolke(bei: Node, pos: Vector3, staerke: float = 1.0,
		farbe: Color = KEINE_FARBE) -> CPUParticles3D:
	var s := clampf(staerke, 0.1, 2.0)
	var p := _emitter(bei, pos + Vector3.UP * 0.12, roundi(12.0 * s), 0.6)
	if p == null:
		return null
	var ton := staubfarbe if farbe.a <= 0.0 else farbe
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ALPHA)
	p.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	p.lifetime_randomness = 0.3
	# Ring am Boden: Die Wolke quillt um die Füße herum, nicht aus einem
	# Punkt – ein Punkt sähe aus wie ein Rauchwölkchen aus dem Schuh.
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.35 * sqrt(s)
	p.emission_ring_inner_radius = 0.12
	p.emission_ring_height = 0.05
	# Nach außen treibt ein kurzer radialer Stoß (vom Mittelpunkt weg), nicht
	# die Startrichtung: Mit zufälligen Richtungen flog im ersten Probelauf
	# die Hälfte schräg nach unten in den Boden und verschwand, und der Rest
	# lag als zwei, drei Flecken herum statt als Ring. Die Startrichtung
	# hebt die Wölkchen nur sacht an.
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.3 * s
	p.initial_velocity_max = 0.9 * s
	p.radial_accel_min = 40.0 * s
	p.radial_accel_max = 60.0 * s
	p.radial_accel_curve = _kurve("stoss")
	p.damping_min = 4.0
	p.damping_max = 5.0
	p.gravity = Vector3(0.0, 0.6, 0.0)
	var g := 0.7 + 0.3 * s
	p.scale_amount_min = 0.5 * g
	p.scale_amount_max = 0.85 * g
	p.scale_amount_curve = _kurve("puff")
	p.color = Color(ton.r, ton.g, ton.b, 0.7 * ton.a)
	p.color_ramp = _verlauf("rein_raus")
	return p


## Leuchtende Funken (additiv). `streuung` in Grad um die Senkrechte.
static func funken(bei: Node, pos: Vector3, farbe: Color, anzahl: int = 10,
		tempo: float = 4.5, groesse: float = 0.2,
		streuung: float = 180.0) -> CPUParticles3D:
	var p := _emitter(bei, pos, anzahl, 0.45)
	if p == null:
		return null
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ADDITIV)
	p.lifetime_randomness = 0.35
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.1
	p.direction = Vector3.UP
	p.spread = clampf(streuung, 0.0, 180.0)
	p.initial_velocity_min = tempo * 0.55
	p.initial_velocity_max = tempo
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.gravity = Vector3(0.0, -6.0, 0.0)
	p.scale_amount_min = groesse * 0.7
	p.scale_amount_max = groesse * 1.25
	p.scale_amount_curve = _kurve("aus")
	p.color = farbe
	p.color_ramp = _verlauf("spaet_aus")
	return p


## Ein heller Lichtfleck, der aufgeht und verlischt.
static func aufblitzen(bei: Node, pos: Vector3, farbe: Color,
		groesse: float = 1.2, dauer: float = 0.12) -> CPUParticles3D:
	var p := _emitter(bei, pos, 1, dauer, false)
	if p == null:
		return null
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ADDITIV)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = groesse
	p.scale_amount_max = groesse
	p.scale_amount_curve = _kurve("blitz")
	p.color = farbe
	p.color_ramp = _verlauf("aus")
	return p


## Bretter der zerbrochenen Kiste. `stoff` ist ihr (geteiltes) Material –
## im Dunkellevel die leuchtende Kopie aus `Leuchtmarker`, damit die
## Splitter dort nicht schwarz davonfliegen. Es wird NUR referenziert.
static func splitter(bei: Node, pos: Vector3, stoff_der_kiste: Material,
		anzahl: int = 10) -> CPUParticles3D:
	var p := _emitter(bei, pos, anzahl, 0.9)
	if p == null:
		return null
	p.mesh = _brett_netz()
	p.material_override = stoff_der_kiste
	p.lifetime_randomness = 0.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.32, 0.32, 0.32)
	p.direction = Vector3.UP
	p.spread = 65.0
	p.initial_velocity_min = 4.5
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0.0, -26.0, 0.0)
	# `align_y` richtet die Y-Achse jedes Bretts nach seiner Flugrichtung.
	# Die kehrt sich im Bogen um, also dreht sich jedes Brett im Flug einmal
	# halb herum – das liest sich als Überschlag, ohne dass ein Teilchen
	# einzeln gedreht werden muss (Drehung gibt es bei CPU-Teilchen nur
	# für Billboards).
	p.particle_flag_align_y = true
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _kurve("halten_dann_weg")
	return p


## Weiche, langsam aufsteigende Rauchballen.
static func rauch(bei: Node, pos: Vector3, farbe: Color, groesse: float = 1.0,
		anzahl: int = 8) -> CPUParticles3D:
	var p := _emitter(bei, pos, anzahl, 1.1)
	if p == null:
		return null
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ALPHA)
	p.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	p.lifetime_randomness = 0.3
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3 * groesse
	p.direction = Vector3.UP
	p.spread = 40.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.1
	p.damping_min = 0.3
	p.damping_max = 0.6
	p.gravity = Vector3(0.0, 0.5, 0.0)
	p.scale_amount_min = 0.6 * groesse
	p.scale_amount_max = 1.0 * groesse
	p.scale_amount_curve = _kurve("puff")
	p.color = Color(farbe.r, farbe.g, farbe.b, 0.7 * farbe.a)
	p.color_ramp = _verlauf("rein_raus")
	return p


## Flache Druckwelle. `radius` ist der sichtbare Außenradius am Ende.
## `achse` ist die Flächennormale (UP liegt am Boden).
static func ring(bei: Node, pos: Vector3, farbe: Color, radius: float,
		dauer: float = 0.3, achse: Vector3 = Vector3.UP) -> CPUParticles3D:
	var p := _emitter(bei, pos, 1, dauer, false)
	if p == null:
		return null
	# Lokale Koordinaten: Bei Weltkoordinaten geht die Drehung des Emitters
	# NICHT auf die Teilchen über – ein aufgerichteter Ring lag im ersten
	# Probelauf trotzdem flach. Lokal dreht der Knoten das ganze MultiMesh
	# mit. Der Ring fliegt nirgendwohin, also geht dabei nichts verloren.
	p.local_coords = true
	var n := achse.normalized() if achse.length_squared() > 0.0001 else Vector3.UP
	if not n.is_equal_approx(Vector3.UP):
		p.quaternion = Quaternion(Vector3.UP, n)
	p.mesh = _scheiben_netz()
	p.material_override = stoff(Stoff.RING)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.gravity = Vector3.ZERO
	# Die Scheibe hat Radius 1 und der Lichtsaum sitzt an ihrem Rand –
	# der Skalierwert IST damit der sichtbare Radius.
	p.scale_amount_min = radius
	p.scale_amount_max = radius
	p.scale_amount_curve = _kurve("ring")
	p.color = farbe
	p.color_ramp = _verlauf("spaet_aus")
	return p


## Aufschießende Lichtsäule mit steigenden Funken. Belegt zwei Stöße.
static func lichtsaeule(bei: Node, pos: Vector3, farbe: Color,
		hoehe: float = 6.0, radius: float = 0.7,
		dauer: float = 0.9) -> CPUParticles3D:
	var p := _emitter(bei, pos, 1, dauer, false)
	if p == null:
		return null
	p.mesh = _saeulen_netz(radius, hoehe)
	p.material_override = stoff(Stoff.SAEULE)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.gravity = Vector3.ZERO
	# Getrennte Achsen: Die Säule schießt in die Höhe (Y wächst von fast 0)
	# und wird dabei etwas schmaler. Das Netz steht mit dem Fuß im Ursprung,
	# deshalb wächst sie vom Boden aus und nicht aus der Mitte.
	p.split_scale = true
	p.scale_curve_x = _kurve("schmaler")
	p.scale_curve_y = _kurve("wachsen")
	p.scale_curve_z = _kurve("schmaler")
	p.color = farbe
	p.color_ramp = _verlauf("spaet_aus")

	var f := _emitter(bei, pos, 12, dauer * 1.2)
	if f != null:
		f.mesh = teilchen_netz()
		f.material_override = stoff(Stoff.ADDITIV)
		f.lifetime_randomness = 0.3
		f.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		f.emission_ring_axis = Vector3.UP
		f.emission_ring_radius = radius
		f.emission_ring_inner_radius = radius * 0.6
		f.emission_ring_height = 0.3
		f.direction = Vector3.UP
		f.spread = 8.0
		f.initial_velocity_min = 2.0
		f.initial_velocity_max = 5.0
		f.gravity = Vector3(0.0, 1.5, 0.0)
		f.scale_amount_min = 0.1
		f.scale_amount_max = 0.17
		f.scale_amount_curve = _kurve("aus")
		f.color = farbe.lightened(0.4)
		f.color_ramp = _verlauf("spaet_aus")
	return p


## Kurzes Punktlicht, das ausblendet. Höchstens `MAX_LICHTER` zugleich;
## bei `reduziert` gar keines. Ohne Schatten: Ein Schatten eines
## Punktlichts ist unter gl_compatibility das Teuerste überhaupt.
static func blitzlicht(bei: Node, pos: Vector3, farbe: Color,
		energie: float = 6.0, reichweite: float = 7.0,
		dauer: float = 0.35) -> OmniLight3D:
	if reduziert or not _im_baum(bei) or _lichter >= MAX_LICHTER:
		return null
	var licht := OmniLight3D.new()
	licht.name = "Blitzlicht"
	licht.top_level = true
	licht.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	licht.position = pos           # top_level: Position ist global
	licht.light_color = farbe
	licht.light_energy = energie
	licht.omni_range = reichweite
	licht.shadow_enabled = false
	_lichter += 1
	licht.tree_exited.connect(func() -> void: _lichter = maxi(_lichter - 1, 0))
	_einhaengen(bei, licht)
	# Über den Baum erzeugt und an das Licht gebunden: Das geht auch, wenn
	# `_einhaengen` das Licht erst am Bildende einhängt.
	var t := bei.get_tree().create_tween().bind_node(licht)
	t.tween_property(licht, "light_energy", 0.0, maxf(dauer, 0.02)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(licht.queue_free)
	return licht


# ================================================================ Bildschirm

## Kamerawackeln (siehe KAMERAVERTRAG oben). Mit `pos` fällt die Stärke
## mit dem Abstand zwischen Ereignis und Figur ab.
static func erschuettern(bei: Node, staerke: float,
		pos: Vector3 = Vector3.INF) -> void:
	if reduziert or ruhig or not _im_baum(bei):
		return
	var kamera := bei.get_viewport().get_camera_3d()
	if kamera == null or not kamera.has_method("erschuettern"):
		return
	var wert := staerke
	if pos.is_finite():
		# Abstand zur FIGUR, nicht zur Kamera: Die Kamera hängt 6 bis 8 m
		# hinter ihr, und eine Explosion direkt am Spieler bekäme sonst
		# nur die halbe Wucht.
		var bezug := kamera.global_position
		var spieler := bei.get_tree().get_first_node_in_group("spieler") as Node3D
		if spieler != null:
			bezug = spieler.global_position
		wert *= clampf(1.0 - bezug.distance_to(pos) / ABFALL_WEITE, 0.0, 1.0)
	if wert <= 0.01:
		return
	kamera.call("erschuettern", clampf(wert, 0.0, 1.0))


## Trefferpause: Das Spiel läuft `dauer` Sekunden (echte Zeit) mit
## `PAUSE_TEMPO`. Aus bei `reduziert`, im Headless-Betrieb und solange
## schon eine Pause läuft (mehrere Treffer im selben Bild stapeln nicht).
##
## ZEITMODUS: Die Pause ist fair. `Zeitlauf` zählt mit dem Bild-Delta, das
## `Engine.time_scale` mitverlangsamt – die Uhr steht also, solange die
## Figur steht. Der Spieler verliert keine Spielzeit.
## HEADLESS: Die Prüfwerkzeuge (Hangeltest, Kriechtest, Zeitprobe ...)
## messen in Physikbildern; eine Pause verschöbe dort die Messwerte.
static func trefferpause(bei: Node, dauer: float = 0.05) -> void:
	if reduziert or ruhig or not _im_baum(bei):
		return
	if DisplayServer.get_name() == "headless":
		return
	if not is_equal_approx(Engine.time_scale, 1.0):
		return
	Engine.time_scale = PAUSE_TEMPO
	# ignore_time_scale: Der Zeitgeber selbst darf nicht mit verlangsamt
	# werden, sonst dauerte die Pause zwanzigmal so lang.
	# process_always: Auch wenn das Statusmenü im selben Moment pausiert,
	# muss das Tempo zurückkommen.
	bei.get_tree().create_timer(clampf(dauer, 0.0, PAUSE_HOECHSTENS),
			true, false, true).timeout.connect(_pause_ende)


## Vollbild-Farbschleier, der in `dauer` Sekunden ausblendet. `farbe.a` ist
## die Anfangsdeckkraft. Die Schicht liegt auf Ebene 0, also UNTER dem HUD
## (Standardebene 1) – Punktzahl und Leben bleiben lesbar.
static func bildblitz(bei: Node, farbe: Color, dauer: float = 0.25) -> void:
	if reduziert or ruhig or not _im_baum(bei):
		return
	var flaeche := _blitzflaeche_holen(bei)
	if flaeche == null:
		return
	if _blitztween != null and _blitztween.is_valid():
		_blitztween.kill()
	flaeche.color = farbe
	flaeche.visible = true
	_blitztween = bei.get_tree().create_tween().bind_node(flaeche)
	_blitztween.tween_property(flaeche, "color:a", 0.0, maxf(dauer, 0.02)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_blitztween.tween_callback(flaeche.hide)


# ================================================================ Dauerhaftes

## Weicher runder Fleck am Boden – die klassische Landehilfe: Wo der Fleck
## liegt, landet die Figur. Er hängt unter `eltern` (meist der Spieler),
## ist aber `top_level`: Der Aufrufer setzt ihn jedes Bild per
## `blobschatten_setzen()` auf den Bodenpunkt, den ein Strahl nach unten
## findet (Strahl ohne Areas, sonst liegt der Fleck auf Wasser- oder
## Todeszonen). Das Material gehört diesem Fleck allein.
static func blobschatten(eltern: Node3D, radius: float = 0.45) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Blobschatten"
	var netz := PlaneMesh.new()
	netz.size = Vector2.ONE * radius * 2.0
	mi.mesh = netz
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_color = Color(0.0, 0.0, 0.0, 0.45)
	m.albedo_texture = _fleck_textur()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.disable_receive_shadows = true
	# Vor den anderen durchsichtigen Dingen zeichnen: Staub, der über dem
	# Fleck aufwirbelt, soll darüber liegen, nicht darunter.
	m.render_priority = -1
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mi.visible = false
	if eltern.is_inside_tree():
		mi.position = eltern.global_position
	eltern.add_child(mi)
	return mi


## Setzt den Fleck auf `punkt` (Bodentreffer), richtet ihn an `normale` aus
## und stellt Deckkraft (0..1) und Größe (Anteil vom Baumaß) ein. Hebt ihn
## 4 cm von der Fläche ab, damit er nicht mit dem Boden flimmert.
static func blobschatten_setzen(schatten: MeshInstance3D, punkt: Vector3,
		normale: Vector3, deckkraft: float, skala: float = 1.0) -> void:
	if schatten == null or not is_instance_valid(schatten):
		return
	var n := normale.normalized() if normale.length_squared() > 0.0001 else Vector3.UP
	var b := Basis(Quaternion(Vector3.UP, n)).scaled(Vector3.ONE * maxf(skala, 0.01))
	schatten.global_transform = Transform3D(b, punkt + n * 0.04)
	var m := schatten.material_override as StandardMaterial3D
	if m != null:
		m.albedo_color.a = clampf(deckkraft, 0.0, 1.0)
	schatten.visible = deckkraft > 0.005


## Lauf- oder Slidestaub unter einer Figur (`gleiten` = Slide: dichter,
## schneller). Hängt als Kind am Träger, 5 cm über dessen Ursprung, und
## startet mit `emitting = false`. Der Aufrufer schaltet `emitting` – nur
## bei einem Wechsel (Wert zwischenspeichern), nicht jedes Bild. Aus
## geschaltet leben die vorhandenen Wölkchen noch zu Ende.
## Die Wölkchen bleiben in der Welt liegen (`local_coords = false`), die
## Figur läuft aus ihnen heraus – darum braucht es keine Richtung, und es
## ist egal, ob sich der Körper oder nur das Modell dreht.
## Farbe später ändern: `p.color` (Eigenschaft des Emitters, NIE das Material).
static func dauerstaub(traeger: Node3D, gleiten: bool = false,
		farbe: Color = KEINE_FARBE) -> CPUParticles3D:
	var ton := staubfarbe if farbe.a <= 0.0 else farbe
	var p := CPUParticles3D.new()
	p.name = "Slidestaub" if gleiten else "Laufstaub"
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.position = Vector3(0.0, 0.05, 0.0)
	p.emitting = false
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ALPHA)
	p.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.15
	p.direction = Vector3.UP
	p.gravity = Vector3(0.0, 0.5, 0.0)
	p.scale_amount_curve = _kurve("puff")
	p.color_ramp = _verlauf("rein_raus")
	if gleiten:
		p.amount = _menge(24)
		p.lifetime = 0.35
		p.spread = 50.0
		p.initial_velocity_min = 1.5
		p.initial_velocity_max = 3.0
		p.damping_min = 3.0
		p.damping_max = 5.0
		p.scale_amount_min = 0.3
		p.scale_amount_max = 0.5
		p.color = Color(ton.r, ton.g, ton.b, 0.55 * ton.a)
	else:
		p.amount = _menge(8)
		p.lifetime = 0.4
		p.spread = 35.0
		p.initial_velocity_min = 0.3
		p.initial_velocity_max = 0.8
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.4
		p.color = Color(ton.r, ton.g, ton.b, 0.4 * ton.a)
	traeger.add_child(p)
	return p


## Sprühende Glut an einem festen Punkt des Trägers (`ort` lokal), etwa
## die Zündschnur einer TNT-Kiste. Läuft sofort und bis der Träger geht.
## NICHT beim Aufbau einer Kiste anlegen, sondern erst beim Zünden: Der
## `Leuchtmarker` kopiert sonst auch hierfür ein Material.
static func dauerfunken(traeger: Node3D, ort: Vector3,
		farbe: Color = Farben.GLUT) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Glut"
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.position = ort
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.amount = _menge(10)
	p.lifetime = 0.3
	p.lifetime_randomness = 0.4
	p.mesh = teilchen_netz()
	p.material_override = stoff(Stoff.ADDITIV)
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	p.gravity = Vector3(0.0, -4.0, 0.0)
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.11
	p.scale_amount_curve = _kurve("aus")
	p.color = farbe
	p.color_ramp = _verlauf("spaet_aus")
	traeger.add_child(p)
	p.emitting = true
	return p


# ================================================================ Zubehör

## Zeichnet jeden Teilchenstoff einmal fast unsichtbar vor der Kamera.
##
## Unter gl_compatibility wird ein Shader erst beim ersten Zeichnen
## übersetzt. Ohne Vorwärmen stockt das Spiel genau beim ersten
## Kistenbruch oder beim ersten Einsammeln – dem Moment, in dem der
## Spieler hinsieht. Aufruf beim Levelaufbau, solange der Ladeschirm
## noch steht. Erzeugt KEIN Licht, die Lichtgrenze bleibt unberührt.
## Teilchen auf einem MultiMesh brauchen eine eigene Shaderfassung;
## deshalb auch das Kistenholz, obwohl die Kisten selbst es schon zeigen.
##
## Die Teilchen laufen in Zeitlupe (`VORWAERM_ZEITLUPE`): Das Bild nach
## einem Aufbau ist lang – es zeichnet die ganze Szene zum ersten Mal. Mit
## gewöhnlichem Tempo verglühten die Teilchen (0,2 s) in diesem einen
## Schritt, ehe sie je gezeichnet wurden, und übersetzt wurde nichts.
## Weggeräumt werden sie trotzdem pünktlich, über den Zeitgeber aus
## `_emitter` (0,8 s).
static func vorwaermen(bei: Node) -> void:
	if not _im_baum(bei):
		return
	var ort := Vector3.ZERO
	var kamera := bei.get_viewport().get_camera_3d()
	if kamera != null:
		ort = kamera.global_position - kamera.global_basis.z * 4.0
	var unsichtbar := Color(1.0, 1.0, 1.0, 0.004)
	for art: Stoff in [Stoff.ALPHA, Stoff.ADDITIV, Stoff.RING, Stoff.SAEULE]:
		var p := _emitter(bei, ort, 1, 0.2, false)
		if p == null:
			return
		p.speed_scale = VORWAERM_ZEITLUPE
		match art:
			Stoff.RING:
				p.mesh = _scheiben_netz()
			Stoff.SAEULE:
				p.mesh = _saeulen_netz(0.7, 6.0)
			_:
				p.mesh = teilchen_netz()
		p.material_override = stoff(art)
		p.initial_velocity_max = 0.0
		p.gravity = Vector3.ZERO
		p.scale_amount_min = 0.05
		p.scale_amount_max = 0.05
		p.color = unsichtbar
	var b := _emitter(bei, ort, 1, 0.2, false)
	if b != null:
		b.speed_scale = VORWAERM_ZEITLUPE
		b.mesh = _brett_netz()
		b.material_override = Materialbibliothek.kistenholz(Farben.HOLZ)
		b.initial_velocity_max = 0.0
		b.gravity = Vector3.ZERO
		b.scale_amount_min = 0.01
		b.scale_amount_max = 0.01
	# Verborgene Netze (`VORWAERM_GRUPPE`): Was nicht gezeichnet wird, wird
	# nicht übersetzt – der Rundgang sieht sie also nie.
	for knoten in bei.get_tree().get_nodes_in_group(VORWAERM_GRUPPE):
		var vorbild := knoten as MeshInstance3D
		if vorbild == null or vorbild.mesh == null:
			continue
		var abklatsch := MeshInstance3D.new()
		abklatsch.name = "Vorwaermen"
		abklatsch.mesh = vorbild.mesh
		abklatsch.material_override = vorbild.material_override
		for i in vorbild.get_surface_override_material_count():
			abklatsch.set_surface_override_material(i, vorbild.get_surface_override_material(i))
		abklatsch.cast_shadow = vorbild.cast_shadow
		abklatsch.top_level = true
		abklatsch.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		abklatsch.transform = Transform3D(Basis.from_scale(Vector3.ONE * 0.01), ort)
		bei.add_child(abklatsch)
		bei.get_tree().create_timer(VORWAERM_DAUER).timeout.connect(abklatsch.queue_free)


## Neues Material für eine Portalscheibe (QuadMesh 2r × 2r). Jedes Portal
## bekommt sein eigenes, weil es seinen eigenen `puls` setzt; der Shader
## darunter ist geteilt und wird nur einmal übersetzt. Ohne Kern- und
## Saumfarbe werden beide aus `farbe` abgeleitet: Kern dunkel (Tiefe),
## Saum hell (Schein).
static func wirbelstoff(farbe: Color, kern: Color = KEINE_FARBE,
		saum: Color = KEINE_FARBE) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WIRBEL_SHADER
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kern", farbe.darkened(0.8) if kern.a <= 0.0 else kern)
	m.set_shader_parameter("saum_farbe", farbe.lightened(0.25) if saum.a <= 0.0 else saum)
	return m


## Geteiltes Teilchenmaterial einer Art. NIE verändern (siehe REGELN).
static func stoff(art: Stoff) -> StandardMaterial3D:
	if _stoffe.has(art):
		return _stoffe[art]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.vertex_color_use_as_albedo = true
	# Die Teilchenfarbe kommt als Scheitelfarbe an. Als sRGB markiert wird
	# sie genauso umgerechnet wie `albedo_color` – ein Funke in
	# `Farben.FRUCHT` hat dann denselben Ton wie die Frucht.
	m.vertex_color_is_srgb = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# `billboard_keep_scale` ist Pflicht: Ohne es baut Godot das Billboard
	# aus der reinen Kamerabasis, und die Teilchengröße aus
	# `scale_amount` geht verloren – jeder Funke war im ersten Probelauf
	# einen Meter groß, ein 12-cm-Blitz so groß wie ein 36-cm-Blitz.
	match art:
		Stoff.ALPHA:
			m.albedo_texture = weiche_textur()
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.billboard_keep_scale = true
		Stoff.ADDITIV:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_texture = _glut_textur()
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.billboard_keep_scale = true
		Stoff.RING:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_texture = _ring_textur()
		Stoff.SAEULE:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_stoffe[art] = m
	return m


## Einheitsviereck (1 × 1 m) für Billboard-Teilchen.
static func teilchen_netz() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad


## Weicher runder Fleck: Weiß in der Mitte, zum Rand durchsichtig.
static func weiche_textur() -> Texture2D:
	if _weich == null:
		# Mit Körper bis gut zur Hälfte: Ein rein linearer Abfall ließe von
		# jedem Wölkchen nur das innerste Drittel sichtbar.
		_weich = _radial(64, PackedFloat32Array([0.0, 0.4, 1.0]),
				PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.72),
				Color(1, 1, 1, 0)]))
	return _weich


## Anzahl der gerade lebenden Stöße (für Prüfwerkzeuge).
static func aktive() -> int:
	return _aktiv


## Anzahl der gerade leuchtenden Blitzlichter (für Prüfwerkzeuge).
static func lichter() -> int:
	return _lichter


# ================================================================ Intern

## Kern aller Stöße: ein einmaliger, sich selbst räumender Emitter.
## `mit_menge = false` für Einzelteilchen (Blitz, Ring), deren Zahl
## `reduziert` nicht halbieren darf.
static func _emitter(bei: Node, pos: Vector3, anzahl: int, dauer: float,
		mit_menge: bool = true) -> CPUParticles3D:
	if not _im_baum(bei):
		return null
	var bild := Engine.get_process_frames()
	if bild != _bild:
		_bild = bild
		_im_bild = 0
	if _aktiv >= MAX_AKTIV or _im_bild >= MAX_JE_BILD:
		return null
	_im_bild += 1
	_aktiv += 1

	var p := CPUParticles3D.new()
	p.name = "Effekt"
	# Vorgabe ist `emitting = true`: Ohne das hier entstünden die Teilchen
	# beim Einhängen, noch bevor der Aufrufer Tempo und Größe eingestellt
	# hat – alle mit Tempo 0 an einem Fleck (so im ersten Probelauf).
	p.emitting = false
	# top_level: Die Position ist global, egal wo `current_scene` steht.
	# Position VOR add_child (ARCHITEKTUR.md), sonst entsteht der erste
	# Schwung am Ursprung.
	p.top_level = true
	p.position = pos
	# Physikinterpolation ist im Projekt an. Ein Emitter, der mit ihr
	# eingehängt wird, zöge im ersten Bild eine Spur vom Ursprung her.
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.amount = _menge(anzahl) if mit_menge else maxi(anzahl, 1)
	p.lifetime = maxf(dauer, 0.02)
	p.tree_exited.connect(func() -> void: _aktiv = maxi(_aktiv - 1, 0))
	p.finished.connect(p.queue_free)
	_einhaengen(bei, p)
	# Gezündet wird erst am Bildende. `emitting = true` rechnet sofort den
	# ersten Schritt, und bei `explosiveness = 1` entstehen dabei ALLE
	# Teilchen – mit den Werten, die in diesem Moment eingestellt sind. Der
	# Aufrufer stellt Tempo, Größe und Farbe aber erst nach `_emitter()`
	# ein; sofort gezündet flöge alles mit den Vorgaben (Schwerkraft -9,8,
	# weiß, 1 m groß) los.
	p.set_deferred("emitting", true)
	# Rückfall: `finished` kommt nicht, wenn der Emitter nie verarbeitet
	# wird (etwa außerhalb des Bildes oder im pausierten Baum). Der Zeitgeber
	# pausiert mit dem Spiel und läuft mit dessen Tempo, wie die Teilchen.
	bei.get_tree().create_timer(p.lifetime * 1.5 + 0.5, false) \
			.timeout.connect(p.queue_free)
	return p


static func _im_baum(bei: Node) -> bool:
	return bei != null and is_instance_valid(bei) and bei.is_inside_tree()


## Effekte gehören der laufenden Szene: Ein Szenenwechsel räumt sie ab.
static func _eltern(bei: Node) -> Node:
	var szene := bei.get_tree().current_scene
	return szene if szene != null else bei.get_tree().root


## Hängt einen Effektknoten an die laufende Szene. Steckt die Szene noch
## mitten im Aufbau (ein `_ready()` weiter unten im Baum löst den Effekt
## aus), nimmt sie keine Kinder an – dann am Bildende, was man nicht sieht:
## Gezeichnet wird ohnehin erst danach.
static func _einhaengen(bei: Node, knoten: Node) -> void:
	var eltern := _eltern(bei)
	if eltern.is_node_ready():
		eltern.add_child(knoten)
	else:
		eltern.add_child.call_deferred(knoten)


static func _menge(anzahl: int) -> int:
	return maxi(1, roundi(float(anzahl) * (0.5 if reduziert else 1.0)))


## `mobile` ist die App auf Android und iOS. Früher fragte das nur
## nach dem Browser: Die APK lief auf dem Rechnerweg – volle Dichten, zwei
## Schattenstufen, MSAA.
static func _vorbelegung() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
			or OS.has_feature("web_ios")


static func _pause_ende() -> void:
	# Nur zurückstellen, was diese Pause gesetzt hat – falls inzwischen
	# jemand anderes das Tempo führt (Zeitlupe, Menü), bleibt es dessen.
	if is_equal_approx(Engine.time_scale, PAUSE_TEMPO):
		Engine.time_scale = 1.0


static func _blitzflaeche_holen(bei: Node) -> ColorRect:
	# Die Schicht hängt an der Szene und stirbt mit ihr; danach ist die
	# Referenz ungültig und es wird neu gebaut. Nicht `is_inside_tree()`
	# prüfen: Eine eben erst (am Bildende) eingehängte Schicht ist noch
	# nicht im Baum, und ein zweiter Blitz im selben Bild baute sonst eine
	# zweite.
	if is_instance_valid(_blitzschicht) and is_instance_valid(_blitzflaeche) \
			and not _blitzschicht.is_queued_for_deletion():
		return _blitzflaeche
	var schicht := CanvasLayer.new()
	schicht.name = "Bildblitz"
	schicht.layer = 0
	# Läuft auch im pausierten Baum weiter: Öffnet jemand im Blitz das
	# Statusmenü, bliebe der Schleier sonst stehen.
	schicht.process_mode = Node.PROCESS_MODE_ALWAYS
	var flaeche := ColorRect.new()
	flaeche.name = "Schleier"
	flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flaeche.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flaeche.color = Color(1.0, 1.0, 1.0, 0.0)
	flaeche.visible = false
	schicht.add_child(flaeche)
	_einhaengen(bei, schicht)
	_blitzschicht = schicht
	_blitzflaeche = flaeche
	return flaeche


static func _kurve(name: String) -> Curve:
	if _kurven.has(name):
		return _kurven[name]
	var k := Curve.new()
	match name:
		"aus":                          # schrumpft gleichmäßig weg
			k.add_point(Vector2(0.0, 1.0))
			k.add_point(Vector2(1.0, 0.0))
		"puff":                         # quillt schnell auf, dann langsam
			k.add_point(Vector2(0.0, 0.35), 0.0, 2.2)
			k.add_point(Vector2(1.0, 1.0))
		"blitz":
			k.add_point(Vector2(0.0, 0.4), 0.0, 2.5)
			k.add_point(Vector2(1.0, 1.0))
		"ring":                         # schießt raus, bremst am Wirkradius
			k.add_point(Vector2(0.0, 0.15), 0.0, 3.0)
			k.add_point(Vector2(1.0, 1.0))
		"stoss":                        # nur am Anfang: kurzer Schub
			k.add_point(Vector2(0.0, 1.0))
			k.add_point(Vector2(0.2, 0.0))
			k.add_point(Vector2(1.0, 0.0))
		"halten_dann_weg":              # Bretter: erst ganz, am Ende weg
			k.add_point(Vector2(0.0, 1.0))
			k.add_point(Vector2(0.7, 1.0))
			k.add_point(Vector2(1.0, 0.0))
		"wachsen":                      # Säule: fast 0, nie ganz (Basis!)
			k.add_point(Vector2(0.0, 0.02), 0.0, 4.0)
			k.add_point(Vector2(0.35, 1.0))
			k.add_point(Vector2(1.0, 1.0))
		"schmaler":
			k.add_point(Vector2(0.0, 1.0))
			k.add_point(Vector2(1.0, 0.55))
		_:
			push_error("Effekte: unbekannte Kurve '%s'" % name)
			k.add_point(Vector2(0.0, 1.0))
			k.add_point(Vector2(1.0, 1.0))
	k.bake()
	_kurven[name] = k
	return k


## Deckkraftverläufe über die Lebenszeit. Weiß, damit `color` des
## Emitters den Ton allein bestimmt (Rampe × Farbe).
static func _verlauf(name: String) -> Gradient:
	if _verlaeufe.has(name):
		return _verlaeufe[name]
	var g := Gradient.new()
	match name:
		"aus":
			g.offsets = PackedFloat32Array([0.0, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		"spaet_aus":                    # lange sichtbar, dann schnell weg
			g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85),
					Color(1, 1, 1, 0)])
		"rein_raus":                    # weich einblenden, lang ausblenden
			g.offsets = PackedFloat32Array([0.0, 0.12, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1),
					Color(1, 1, 1, 0)])
		_:
			push_error("Effekte: unbekannter Verlauf '%s'" % name)
	_verlaeufe[name] = g
	return g


static func _radial(kante: int, stellen: PackedFloat32Array,
		farben: PackedColorArray) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = stellen
	g.colors = farben
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = kante
	t.height = kante
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


## Funke und Blitz: ein voll deckender Kern mit Hof. Mit dem weichen Fleck
## allein bleibt von einem 20-cm-Funken ein 6-cm-Pünktchen übrig – der
## sichtbare Teil des weichen Flecks ist nur sein innerstes Drittel.
static func _glut_textur() -> Texture2D:
	if _glutbild == null:
		_glutbild = _radial(64, PackedFloat32Array([0.0, 0.18, 0.42, 1.0]),
				PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1),
				Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)]))
	return _glutbild


## Druckwellenring: innen fast leer, heller Saum ganz außen, harte
## Außenkante bei 1 – daher „Radius = sichtbarer Radius".
static func _ring_textur() -> Texture2D:
	if _ringbild == null:
		_ringbild = _radial(128,
				PackedFloat32Array([0.0, 0.55, 0.86, 0.96, 1.0]),
				PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.05),
				Color(1, 1, 1, 0.45), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	return _ringbild


## Bodenfleck: fester Kern, weicher Rand (ein weicher Fleck ohne Kern sähe
## aus wie ein Schmutzrand, nicht wie ein Schatten).
static func _fleck_textur() -> Texture2D:
	if _fleckbild == null:
		_fleckbild = _radial(64, PackedFloat32Array([0.0, 0.5, 1.0]),
				PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8),
				Color(1, 1, 1, 0)]))
	return _fleckbild


## Liegende Scheibe mit Radius 1 für den Ring.
static func _scheiben_netz() -> PlaneMesh:
	if _scheibe == null:
		_scheibe = PlaneMesh.new()
		_scheibe.size = Vector2(2.0, 2.0)
	return _scheibe


## Ein Kistenbrett mit derselben Fase wie die Kiste selbst – so sehen die
## Splitter aus wie Teile DIESER Kiste und nicht wie graue Würfel.
static func _brett_netz() -> ArrayMesh:
	if _brett == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Kistengeometrie.quader(st, Vector3.ZERO, Vector3(0.21, 0.045, 0.025),
				0.008, 2.5)
		st.index()
		st.generate_tangents()
		_brett = st.commit()
	return _brett


## Offener Zylinder, Fuß im Ursprung. Die Deckkraft läuft über die
## Scheitelfarbe von unten (voll) nach oben (null) – so braucht die Säule
## keine Textur, deren UV bei Godots Zylinder ohnehin nicht 0..1 wäre.
static func _saeulen_netz(radius: float, hoehe: float) -> ArrayMesh:
	var schluessel := "%.2f_%.2f" % [radius, hoehe]
	if _saeulen.has(schluessel):
		return _saeulen[schluessel]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segmente := 20
	# Höhe (Anteil) und Deckkraft der Ringe.
	# Unten nicht ganz deckend: Additiv auf hellem Weg brennt eine volle
	# Säule am Fuß zu einem weißen Klotz aus.
	var ringe: Array[Vector2] = [Vector2(0.0, 0.75), Vector2(0.3, 0.5),
			Vector2(1.0, 0.0)]
	for i in segmente:
		var w0 := TAU * float(i) / float(segmente)
		var w1 := TAU * float(i + 1) / float(segmente)
		var r0 := Vector3(cos(w0), 0.0, sin(w0))
		var r1 := Vector3(cos(w1), 0.0, sin(w1))
		for j in ringe.size() - 1:
			var u := ringe[j]
			var o := ringe[j + 1]
			var a := r0 * radius + Vector3.UP * u.x * hoehe
			var b := r1 * radius + Vector3.UP * u.x * hoehe
			var c := r1 * radius + Vector3.UP * o.x * hoehe
			var d := r0 * radius + Vector3.UP * o.x * hoehe
			var ca := Color(1, 1, 1, u.y)
			var co := Color(1, 1, 1, o.y)
			for eck: Array in [[a, r0, ca], [b, r1, ca], [c, r1, co],
					[a, r0, ca], [c, r1, co], [d, r0, co]]:
				st.set_normal(eck[1] as Vector3)
				st.set_color(eck[2] as Color)
				st.add_vertex(eck[0] as Vector3)
	var netz := st.commit()
	_saeulen[schluessel] = netz
	return netz
