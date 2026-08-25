extends Spieler
class_name Flieger
## Der Spieler im Doppeldecker – der Flugmodus aus 5-2 „Wolkenjagd".
##
## Reiter und Rennfahrer kleben auf einer Levelkurve: Strecke, Versatz und
## Höhe sind ihr ganzer Zustand. Der Flieger ist der erste Sondermodus OHNE
## Kurve – es gibt keinen Weg, nur einen offenen Kasten Luft, in dem Ziele
## kreisen. Sein Zustand ist deshalb eine Lage (Gier, Nick, Rolle) und ein
## Tempo; die Position ergibt sich Bild für Bild aus der Blickrichtung.
##
## Geerbt wird trotzdem von `Spieler`, aus demselben Grund wie dort: Kisten
## und Gegner prüfen `koerper is Spieler`, und HUD, Kamera und Spielstand
## erwarten diese Schnittstelle. Was NICHT geerbt wird, ist die Fortbewegung:
## `move_and_slide()` wird hier nie aufgerufen, `velocity` bleibt unbenutzt.
## Wie beim Reiter setzt der Flieger seine Weltposition selbst.
##
## Was dabei abzuschalten war (jeweils überschrieben, siehe unten):
##   * `_physics_process` komplett – kein Laufen, kein Sprung, kein Slide
##   * `_process` – das Figurenmodell darf nicht so tun, als liefe es
##   * `angriffe()` – ein Flugzeug trampelt nichts nieder
##   * `abprallen()` – in der Luft gibt es nichts zum Abprallen
##   * `respawn()` – zurück an den Startpunkt statt an einen Checkpoint
##   * Kollisionsebene: Ebene 2, Maske 0 (siehe `_ready`)

# ---------------------------------------------------------------- Flugwerte
#
# Alle Werte hier sind NEU und gelten nur für den Flugmodus. Die Physikwerte
# aus CLAUDE.md (G, JUMP_V, RUN_SPEED …) beschreiben die Figur zu Fuß und
# bleiben unangetastet – ein Flugzeug fällt nicht mit -38 m/s², es fliegt.

## Reisetempo in m/s. Der Luftraum ist 60 m breit; bei 16 m/s dauert eine
## Durchquerung knapp vier Sekunden. Schnell genug, dass eine Kurve etwas
## kostet, langsam genug, um im Flug zu zielen.
const TEMPO_REISE := 16.0
## Tempo bei gedrückter Sprungtaste. Gut 60 % mehr – genug, um ein
## fliehendes Ziel einzuholen, zu wenig, um dem eigenen Schuss davonzufahren.
const TEMPO_SCHUB := 26.0
## Wie schnell sich das Tempo dem Wunsch nähert (je Sekunde). Klein, weil
## ein Motor Zeit braucht: Der Schub soll spürbar anschieben, nicht schalten.
const TEMPO_TRAEGHEIT := 1.6
## Tempoverlust im Steigflug bzw. Gewinn im Sturzflug, in m/s bei voller
## Neigung. Kostet nichts und ist die halbe Miete fürs Fluggefühl: Wer die
## Nase hochzieht, wird langsam und muss sie wieder senken.
const TEMPO_NEIGUNG := 5.0

## Größte Rolle (Neigung um die Längsachse) in Radiant, rund 57°.
## Die Rolle ist die wichtigste einzelne Zutat: Ohne sie sieht jede Kurve
## nach einem schwebenden Kasten aus, der sich dreht.
const ROLL_MAX := 1.0
## Wie schnell die Rolle ihrem Ziel folgt (je Sekunde). Bewusst träge –
## erst legt sich die Maschine, dann zieht sie in die Kurve.
const ROLL_TEMPO := 3.4
## Gierrate je Radiant Rolle. Bei voller Rolle sind das 1,25 rad/s, also
## ein voller Kreis in fünf Sekunden mit rund 13 m Radius – das passt in
## einen 60 m weiten Luftraum, ohne sofort an die Wand zu stoßen.
##
## Dass die Kurve aus der Rolle folgt und nicht direkt aus dem Stick, ist
## die Trägheit: Man kann nicht abbiegen, ohne sich vorher zu legen.
const GIER_AUS_ROLLE := 1.25
## Größte Nicklage in Radiant, rund 36°. Deckel mit Absicht: Wer senkrecht
## steigen kann, verliert im Kasten sofort die Orientierung, und die Kamera
## müsste überschlagen. Der Horizont bleibt so immer im Bild.
const NICK_MAX := 0.62
## Wie schnell die Nicklage ihrem Ziel folgt (je Sekunde).
const NICK_TRAEGHEIT := 3.6

## Wie tief die weiche Zone am Rand des Luftraums reicht, in Metern.
const RAND_ZONE := 9.0
## Wie stark die Randzone gegensteuert (als Anteil eines vollen Sticks).
## Über 1.0, damit sie einen dagegenhaltenden Spieler überstimmt – sonst
## klebte man an der Wand, statt zurückgeführt zu werden.
const RAND_LENKUNG := 1.6

## Kürzester Abstand zwischen zwei Schüssen. Die Spin-Taste kennt nur
## „gerade gedrückt", kein Halten (siehe InputHub) – geschossen wird also
## je Tastendruck. Der Takt deckelt bloß das Hämmern auf der Taste.
const SCHUSS_TAKT := 0.16
## Mündungen links und rechts der Nase, im eigenen Koordinatensystem.
const MUENDUNG := Vector3(0.62, 0.1, -1.45)
## Unverwundbarkeit nach einem Treffer. Kürzer als INVULN_ZEIT zu Fuß: Wer
## in eine Feindmaschine fliegt, steckt oft mehrere Bilder lang darin.
const TREFFER_PAUSE := 0.9
## Umdrehungen des Propellers je Sekunde bei Reisetempo.
const PROP_DREHUNG := 22.0

## Größe des Luftraums in Metern (Breite, Höhe, Tiefe).
@export var raum := Vector3(60, 26, 60)
## Mittelpunkt des Luftraums. Die Höhe steht bewusst nicht auf 0: Der
## Kasten reicht damit von 1 m bis 27 m über Grund, nicht von -13 m an.
@export var raum_mitte := Vector3(0, 14, 0)
## Trefferanzeige statt der üblichen drei Leben.
##
## Warum: In der Luft gibt es keinen Boden, keinen Checkpoint und keine
## Möglichkeit stehenzubleiben. Eine Berührung ist hier nicht die Ausnahme
## wie im Korridor, sondern der Normalfall – Ziele kreisen, man weicht aus
## und zielt gleichzeitig. Ein sofortiger Tod je Berührung wäre bei diesem
## Tempo Willkür. Die Anzeige macht jeden Treffer sichtbar, lässt kleine
## Fehler sich summieren und gibt dem Spieler eine Warnung, bevor es
## ernst wird. Erst bei 0 greift `sterben()` – Leben und Respawn laufen
## also wie überall sonst, nur eine Stufe später.
@export var panzerung := 5
## Steuerknüppel-Belegung. Falsch heißt: Stick nach oben = steigen (die
## Erwartung im Arcade-Flug). Wahr heißt: Stick nach vorn = Nase runter
## wie bei einem echten Knüppel.
@export var nick_umkehr := false
## Lackfarben: brauner Rumpf, olivfarbene Tragflächen (Vorbild 5-2).
@export var farbe_rumpf: Color = Farben.RINDE
@export var farbe_flaeche: Color = Farben.MOOR_HELL
## Farbe der eigenen Geschosse.
@export var farbe_schuss: Color = Farben.SPIN_RING

## Restliche Panzerung und Gesamtwert – für HUD und Level.
signal panzerung_geaendert(rest: int, gesamt: int)
## Ein Schuss ist raus (für Kamerawackler oder Anzeigen).
signal geschossen

var panzer_rest := 5
var tempo := TEMPO_REISE

var _gier := 0.0
var _nick := 0.0
var _rolle := 0.0
var _schuss_rest := 0.0
var _propeller: Node3D
var _start_ort := Vector3.ZERO
var _start_gier := 0.0


func _ready() -> void:
	super._ready()
	# Der Flieger bewegt sich nicht über die Physik, sondern setzt seine
	# Position selbst. Ebene 2, damit die Trefferzonen der Flugziele ihn
	# finden; Maske 0, weil er selbst nichts anrempeln soll – die Grenzen
	# des Luftraums sind gerechnet, keine Wände.
	collision_layer = 2
	collision_mask = 0
	_start_ort = global_position
	_start_gier = rotation.y
	_gier = _start_gier
	tempo = TEMPO_REISE
	panzer_rest = maxi(panzerung, 1)
	_baue_doppeldecker()
	panzerung_geaendert.emit(panzer_rest, panzerung)


func _physics_process(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	_schuss_rest = maxf(_schuss_rest - delta, 0.0)
	if gesperrt:
		return

	_steuern(delta)
	_fliegen(delta)
	_schiessen()


## Das Figurenmodell wird wie beim Reiter von Hand geführt. Der Basiszustand
## (`is_on_floor()`, Slide, Spin) ergibt hier keinen Sinn – die Figur sitzt.
func _process(delta: float) -> void:
	var figur := get_node_or_null("Modell") as SpielerModell
	if figur == null:
		return
	figur.setze_blick(0.0)
	figur.aktualisiere(delta, 0.0, false, 0.0, 0.0, haltung())
	figur.sichtbarkeit(invuln <= 0.0 or fmod(invuln, 0.2) > 0.1)

	if is_instance_valid(_propeller):
		# Der Propeller dreht mit dem Tempo – steht er still, wirkt die
		# ganze Maschine tot, auch wenn sie sich bewegt.
		_propeller.rotation.z += PROP_DREHUNG * (tempo / TEMPO_REISE) * delta


# ---------------------------------------------------------------- Steuerung

## Lage aus der Eingabe fortschreiben.
##
## Bewusst NICHT kamerarelativ: Zu Fuß muss „vorwärts" ins Bild zeigen,
## weil Figur und Kamera unabhängig voneinander stehen. Hier hängt die
## Kamera hinter der Maschine, und „vorwärts" ist immer die Nase. Eine
## Umrechnung über die Kameraebene würde sogar schaden – in der Schräglage
## ist das „rechts" der Kamera gekippt, und der Stick würde gegen die
## eigene Fluglage arbeiten. Gelenkt wird deshalb im Flugzeugsystem.
func _steuern(delta: float) -> void:
	var stick := InputHub.bewegung()
	# eingabe.y ist -1 für „vorwärts" (siehe Input-Map)
	var hoch := stick.y if nick_umkehr else -stick.y
	var quer := stick.x

	var lenkung := _randlenkung()
	quer = clampf(quer + lenkung.x, -1.0, 1.0)
	hoch = clampf(hoch + lenkung.y, -1.0, 1.0)

	# Rechts drücken = nach rechts legen. Bei Blickrichtung -Z dreht ein
	# positives rotation.z die rechte Fläche nach oben, also andersherum.
	var rolle_ziel := -quer * ROLL_MAX
	_rolle = lerpf(_rolle, rolle_ziel, minf(delta * ROLL_TEMPO, 1.0))

	var nick_ziel := hoch * NICK_MAX
	_nick = lerpf(_nick, nick_ziel, minf(delta * NICK_TRAEGHEIT, 1.0))

	# Die Kurve folgt der Rolle, nicht dem Stick: erst legen, dann drehen.
	_gier += _rolle * GIER_AUS_ROLLE * delta
	_gier = wrapf(_gier, -PI, PI)

	# Reihenfolge YXZ (Godots Standard) ist genau Gier, Nick, Rolle.
	rotation = Vector3(_nick, _gier, _rolle)


## Sanftes Zurücklenken an den Rändern des Luftraums.
##
## Gibt einen Zuschlag auf den Stick zurück (quer, hoch), keinen Stoß auf
## die Position: Ein hartes Anhalten an einer unsichtbaren Wand wäre der
## sicherste Weg, den Luftraum als Käfig zu zeigen. So dreht die Maschine
## von selbst ab, und der Spieler sieht nur, dass sie eine Kurve fliegt.
func _randlenkung() -> Vector2:
	var rel := global_position - raum_mitte
	var halb := raum * 0.5
	var stoss := Vector3.ZERO
	for achse in 3:
		var weich: float = maxf(halb[achse] - RAND_ZONE, 0.5)
		var ueber: float = absf(rel[achse]) - weich
		if ueber > 0.0:
			stoss[achse] = -signf(rel[achse]) * clampf(ueber / RAND_ZONE, 0.0, 1.0)
	if stoss.length_squared() < 0.000001:
		return Vector2.ZERO

	# In die eigene Lage umrechnen: x = nach rechts, y = nach oben,
	# z = nach hinten.
	var lokal := global_transform.basis.inverse() * stoss
	if lokal.z > 0.0:
		# Frontal auf die Wand zu: die Rückholrichtung zeigt nach hinten,
		# quer und hoch wären fast null und die Maschine flöge stur weiter,
		# bis die harte Klemme unten greift. Also zu einer Seite drängen.
		var seite := signf(lokal.x)
		if seite == 0.0:
			seite = 1.0
		lokal.x = seite * maxf(absf(lokal.x), lokal.z)
	return Vector2(lokal.x, lokal.y) * RAND_LENKUNG


func _fliegen(delta: float) -> void:
	var wunsch := TEMPO_SCHUB if InputHub.sprung_gehalten() else TEMPO_REISE
	# Steigen kostet Tempo, Sinken bringt welches.
	wunsch -= sin(_nick) * TEMPO_NEIGUNG
	tempo = lerpf(tempo, wunsch, minf(delta * TEMPO_TRAEGHEIT, 1.0))

	global_position += -global_transform.basis.z * tempo * delta

	# Notklemme. Sollte nie greifen – das Zurücklenken oben fängt vorher ab.
	# Sie steht hier nur, damit ein Ausreißer (Schub genau in die Ecke,
	# Bildaussetzer) den Spieler nicht aus der Welt trägt.
	var rel := global_position - raum_mitte
	var halb := raum * 0.5
	global_position = raum_mitte + Vector3(
			clampf(rel.x, -halb.x, halb.x),
			clampf(rel.y, -halb.y, halb.y),
			clampf(rel.z, -halb.z, halb.z))


func _schiessen() -> void:
	if not InputHub.spin_gedrueckt() or _schuss_rest > 0.0:
		return
	_schuss_rest = SCHUSS_TAKT
	var basis := global_transform.basis
	for seite: float in [-1.0, 1.0]:
		var ort := global_position + basis * Vector3(MUENDUNG.x * seite,
				MUENDUNG.y, MUENDUNG.z)
		Flugschuss.abfeuern(get_parent(), ort, -basis.z, self, farbe_schuss)
	geschossen.emit()
	# Es gibt noch keinen eigenen Klang fürs Bordgeschütz; der Kistenknacks
	# hoch gestimmt und leise ist als Platzhalter kurz und trocken genug.
	Klang.spiele("kiste", 1.8, 0.3)


# ------------------------------------------------------------ Schnittstelle

## Im Doppeldecker wird gesessen, nicht gelaufen.
func haltung() -> String:
	return "sitzen"


## Ein Flugzeug trampelt nichts nieder. Kisten und Gegner am Boden gehen
## den Flugmodus nichts an – sie sollen weder zerbrechen noch zählen.
func angriffe() -> int:
	return Angriff.KEINER


## In der Luft gibt es nichts, wovon man abprallen könnte.
func abprallen(_hoehe: float = ABPRALL_V) -> void:
	pass


## Beim Levelstart die Anfangsrichtung setzen – anders als bei Reiter und
## Rennfahrer ist das hier sinnvoll, weil keine Kurve die Richtung vorgibt.
func setze_blickrichtung(winkel: float) -> void:
	_gier = winkel
	_start_gier = winkel
	rotation = Vector3(0.0, winkel, 0.0)


## Jeder Schaden geht über die Trefferanzeige.
func schaden_nehmen() -> void:
	treffer_nehmen(1)


## Ein Treffer kostet Panzerung; bei 0 gilt es als Tod.
func treffer_nehmen(schaden: int = 1) -> void:
	if invuln > 0.0 or gesperrt:
		return
	invuln = TREFFER_PAUSE
	# Eine Schutzladung fängt den Treffer ganz ab – wie zu Fuß.
	if GameState.schutz_verbrauchen():
		Klang.spiele("schaden")
		return
	panzer_rest = maxi(panzer_rest - maxi(schaden, 1), 0)
	panzerung_geaendert.emit(panzer_rest, panzerung)
	if panzer_rest <= 0:
		sterben()
		return
	Klang.spiele("schaden")


## Zurück an den Startpunkt mit voller Panzerung. Der Basis-Respawn setzt
## auf `GameState.checkpoint` und hantiert mit den Slide-Hitboxen – beides
## ergibt in der Luft nichts.
## Setzt den Punkt, an den `respawn()` zurückführt.
##
## Nötig, weil `_ready()` den Startpunkt aus der Szenentransformation
## nimmt – also bevor ein Level den Flieger irgendwohin stellen kann. Wer
## ihn danach versetzt, fliegt ab dem ersten Tod wieder an der alten
## Stelle los. Beim Bau von Level 22 aufgefallen; dort steht der
## Startpunkt deshalb bisher in der Szene.
func setze_start(ort: Vector3, gier := 0.0) -> void:
	_start_ort = ort
	_start_gier = gier
	global_position = ort
	_gier = gier
	rotation = Vector3(0.0, gier, 0.0)


func respawn() -> void:
	global_position = _start_ort
	_gier = _start_gier
	_nick = 0.0
	_rolle = 0.0
	rotation = Vector3(0.0, _gier, 0.0)
	tempo = TEMPO_REISE
	invuln = INVULN_ZEIT
	gesperrt = false
	panzer_rest = maxi(panzerung, 1)
	panzerung_geaendert.emit(panzer_rest, panzerung)
	# Nach einem Versetzen die Interpolation zurücksetzen, sonst zieht
	# Godot eine Spur vom Absturzort zum Startpunkt.
	reset_physics_interpolation()
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")


# ---------------------------------------------------------------- Optik

## Baut den Doppeldecker aus Grundkörpern.
##
## Alles Feststehende wird je Material zu EINEM Netz verschmolzen – drei
## Meshknoten statt zwanzig. Nur der Propeller bleibt eigenständig, weil
## er sich drehen muss.
func _baue_doppeldecker() -> void:
	var rumpf_stoff := Materialbibliothek.metall(farbe_rumpf)
	var flaechen_stoff := Materialbibliothek.metall(farbe_flaeche)
	var dunkel := Materialbibliothek.einfarbig(farbe_rumpf.darkened(0.6), 0.6)

	# --- Rumpf, Nase, Leitwerk (braun) ---
	var st := PropWerkzeug.bauer()
	# Der Zylinder steht in Godot auf Y; um 90° gekippt liegt er auf Z.
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.28, 0.17, 2.4, 8),
			PropWerkzeug.ort(Vector3(0, 0, 0.1), Vector3(PI * 0.5, 0, 0)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(0.2, 0.27, 0.45, 8, true),
			PropWerkzeug.ort(Vector3(0, 0, -1.32), Vector3(-PI * 0.5, 0, 0)))
	# Seitenflosse und Höhenleitwerk
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(0.09, 0.62, 0.55)),
			PropWerkzeug.ort(Vector3(0, 0.38, 1.05)))
	PropWerkzeug.anfuegen(st, PropWerkzeug.kasten(Vector3(1.7, 0.08, 0.45)),
			PropWerkzeug.ort(Vector3(0, 0.08, 1.12)))
	var rumpf := PropWerkzeug.mesh_knoten("Rumpf", PropWerkzeug.fertig(st),
			rumpf_stoff, true)
	if rumpf != null:
		add_child(rumpf)

	# --- Tragflächen (oliv) ---
	var stf := PropWerkzeug.bauer()
	PropWerkzeug.anfuegen(stf, PropWerkzeug.kasten(Vector3(4.4, 0.09, 0.92)),
			PropWerkzeug.ort(Vector3(0, -0.14, -0.18)))
	PropWerkzeug.anfuegen(stf, PropWerkzeug.kasten(Vector3(4.7, 0.09, 0.98)),
			PropWerkzeug.ort(Vector3(0, 0.76, -0.34)))
	var flaechen := PropWerkzeug.mesh_knoten("Tragflaechen",
			PropWerkzeug.fertig(stf), flaechen_stoff, true)
	if flaechen != null:
		add_child(flaechen)

	# --- Streben und Fahrwerk (dunkel) ---
	var std := PropWerkzeug.bauer()
	for seite: float in [-1.0, 1.0]:
		for x: float in [0.7, 1.7]:
			PropWerkzeug.anfuegen(std, PropWerkzeug.kasten(Vector3(0.07, 0.92, 0.08)),
					PropWerkzeug.ort(Vector3(seite * x, 0.31, -0.26)))
		# Fahrwerk – macht von der Seite erkennbar, wo unten ist
		PropWerkzeug.anfuegen(std, PropWerkzeug.kasten(Vector3(0.07, 0.34, 0.07)),
				PropWerkzeug.ort(Vector3(seite * 0.36, -0.42, -0.5)))
		PropWerkzeug.anfuegen(std, PropWerkzeug.stumpf(0.16, 0.16, 0.08, 8, true),
				PropWerkzeug.ort(Vector3(seite * 0.36, -0.6, -0.5),
						Vector3(0, 0, PI * 0.5)))
	# Cockpitrand, damit die Figur nicht auf dem Rumpf zu kleben scheint
	PropWerkzeug.anfuegen(std, PropWerkzeug.stumpf(0.26, 0.26, 0.1, 8),
			PropWerkzeug.ort(Vector3(0, 0.22, 0.3), Vector3(PI * 0.5, 0, 0)))
	var teile := PropWerkzeug.mesh_knoten("Streben", PropWerkzeug.fertig(std),
			dunkel, false)
	if teile != null:
		add_child(teile)

	# --- Propeller: dreht sich um die Längsachse ---
	_propeller = Node3D.new()
	_propeller.name = "Propeller"
	_propeller.position = Vector3(0, 0, -1.6)
	add_child(_propeller)
	var stp := PropWerkzeug.bauer()
	for winkel: float in [0.0, PI * 0.5]:
		PropWerkzeug.anfuegen(stp, PropWerkzeug.kasten(Vector3(0.1, 1.5, 0.04)),
				PropWerkzeug.ort(Vector3.ZERO, Vector3(0, 0, winkel)))
	var blaetter := PropWerkzeug.mesh_knoten("Blaetter", PropWerkzeug.fertig(stp),
			dunkel, false)
	if blaetter != null:
		_propeller.add_child(blaetter)
	# Angedeutete Kreisscheibe – bei der Drehzahl sieht man von den Blättern
	# ohnehin nur einen Schleier, und der verrät, dass der Motor läuft.
	var scheibe := PropWerkzeug.mesh_knoten("Scheibe",
			PropWerkzeug.stumpf(0.78, 0.78, 0.02, 12),
			Materialbibliothek.transparent(farbe_flaeche.lightened(0.4), 0.2), false)
	if scheibe != null:
		scheibe.rotation.x = PI * 0.5
		_propeller.add_child(scheibe)
