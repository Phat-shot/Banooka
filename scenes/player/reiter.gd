extends Spieler
class_name Reiter
## Der Spieler zu Pferde – genauer: auf einer Wildkatze (Level 04).
##
## Ein Ritt-Level läuft nach anderen Regeln als ein Korridor-Level: die
## Katze rennt von selbst und wird immer schneller, gelenkt wird nur quer
## zum Weg, gesprungen wie gewohnt. Anhalten oder umkehren geht nicht.
##
## Deshalb steht der Reiter NICHT auf `move_and_slide`, sondern klebt auf
## der Levelkurve: Strecke, seitlicher Versatz und Höhe sind der ganze
## Zustand, die Weltposition wird daraus jedes Bild neu berechnet. Ein
## Fahren gegen Wände gibt es damit gar nicht erst – Hindernisse sind
## Zonen, die Schaden machen, keine Körper zum Anrempeln.
##
## Er erbt von `Spieler` und ersetzt nur dessen Fortbewegung. Das ist
## nicht Bequemlichkeit: Kisten und Gegner prüfen `koerper is Spieler`, eine
## eigenständige Klasse liefe glatt durch sie hindurch, ohne dass etwas
## zerbricht. Geerbt bleiben damit auch Leben, Unverwundbarkeit und die
## ganze Schnittstelle, die HUD und Kamera erwarten.

## Anfangs- und Höchsttempo in m/s. Als Felder und nicht als Konstanten,
## damit eine Fluchtstrecke andere Werte fahren kann als ein Ritt.
@export var tempo_start := 11.0
@export var tempo_max := 19.0
## So viel schneller wird es je Sekunde.
@export var tempo_anstieg := 0.28
## Vorzeichen der Lenkung. Steht die Kamera vorn und blickt zurück, ist
## rechts auf dem Schirm links auf der Strecke – dann gehört hier -1 hin.
@export var lenk_richtung := 1.0
## Seitliches Lenktempo in m/s.
const LENK_TEMPO := 9.0
## So schnell folgt der seitliche Versatz der Lenkung (kleiner = träger).
const LENK_TRAEGHEIT := 9.0

# ---------------------------------------------------------------- Turbo
#
# NEU für Level 17 ("Frostritt"): Tempo gegen Kontrolle. Die Werte oben
# und die Tabelle in CLAUDE.md bleiben unangetastet – der Turbo ist ein
# ZUSÄTZLICHER, zeitlich begrenzter Faktor obendrauf. Alle Werte dieses
# Blocks sind neu und stehen zur Prüfung.
#
# WARUM die Slide-Taste (○): Sie ist im Ritt frei. Slide und
# Bauchplatscher hängen an `move_and_slide`, das hier gar nicht läuft, und
# angegriffen wird ohnehin dauernd – `angriffe()` gibt fest SPIN und SLIDE
# zurück, die Katze trampelt alles nieder. Die Taste tut hier also nichts,
# und sie ist trotzdem die richtige: Am Boden heißt sie "schneller
# geradeaus, Richtung beim Start eingefroren", und genau das ist der
# Turbo, nur auf vier Beinen. Dazu kommt ein handfester Grund: Sie ist die
# einzige Taste, die der InputHub auch als GEHALTEN meldet
# (`slide_gehalten`). Ein Turbo, über den laufend neu entschieden wird,
# braucht das – ✕ trägt den Sprung, □ kennt nur den Anschlag.

## Turbo überhaupt möglich? Aus, solange ein Level ihn nicht einschaltet;
## damit bleiben Level 04 (Ritt) und 05 (Flucht) genau, wie sie waren.
@export var turbo_moeglich := false
## Schub aufs Tempo, solange der Turbo läuft.
@export var turbo_faktor := 1.34
## So viele Sekunden Vollgas am Stück.
@export var turbo_vorrat := 2.4
## So viele Sekunden Vorrat kommen je Sekunde zurück (⇒ 3 s bis voll).
@export var turbo_nachladen := 0.8
## Zwangspause, wenn der Vorrat leer gefahren wird. Wer sparsam vom Gas
## geht, zahlt sie nie – wer ihn ausreizt, immer.
@export var turbo_erschoepfung := 1.1
## Tempo während der Erschöpfung. Unter 1, damit das Ende ein Sacken ist
## und kein bloßes Aufhören.
@export var turbo_bremse := 0.90
## Faktor auf LENK_TRAEGHEIT während des Turbos: Die Katze folgt der
## Lenkung träger, weil sie streckt statt zu wenden.
@export var turbo_lenk_traegheit := 0.40
## Dämpfung der Querfeder. Unter 1 schwingt der Versatz über sein Ziel
## hinaus – man landet neben der Spur, die man treffen wollte.
@export var turbo_daempfung := 0.30
## Die Lenkeingabe zieht stärker am Ziel. Zusammen mit der Dämpfung ist
## das der Kontrollverlust: Man reißt weiter herum, als man wollte.
@export var turbo_lenk_schub := 1.25

## So schnell steigt und fällt der Schub. Der Anlauf ist kurz, der Auslauf
## länger – der Turbo greift sofort, geht aber merklich aus.
const TURBO_ANLAUF := 0.18
const TURBO_AUSLAUF := 0.45
## So lange nach dem Turbo bleibt die Lenkung noch lose. Ohne dieses
## Nachschwingen wäre das Ende ein Schalter statt eines Auslaufs.
const TURBO_NACHSCHWINGEN := 0.7
## Die Farbe des Turbos. Level 17 trägt sie auch an seinen Toren, dort
## eine Spur dunkler, weil sie dort als Glut auf einem Körper sitzt und
## hier als Auflage vor einem. Satter als `Farben.KRISTALL_VIOLETT`: Der
## helle Kristallton lief vor dem Schnee dieses Levels zu Weiß aus.
const SPUR_VIOLETT := Color(0.52, 0.24, 0.94)
## Wie weit der Versatz über den Rand hinausschwingen darf, als Faktor auf
## die Seitengrenze. Ganz ohne Anschlag stünde die Katze nach einem
## harten Zug neben der Rinne.
const TURBO_UEBERHANG := 1.12

signal ziel_erreicht

## Kurve, auf der geritten wird. Setzt das Level.
var verlauf: Curve3D
## Größter seitlicher Versatz an einer Stelle. Setzt das Level; ohne das
## bleibt es bei `halbe_breite`.
var seiten_grenze: Callable = Callable()
var halbe_breite := 4.0
## Liegt an dieser Stelle Boden? Setzt das Level. Weil der Reiter auf der
## Kurve klebt statt zu fallen, merkt er eine Lücke sonst überhaupt nicht –
## er liefe darüber hinweg wie über festen Grund.
var boden_pruefer: Callable = Callable()
## Strecke, ab der das Level geschafft ist.
var ziel_strecke := 0.0

## Zurückgelegte Strecke auf der Kurve.
var strecke := 0.0
## Aktuelles Tempo in m/s.
var tempo := 11.0

var _seitlich := 0.0
var _seitlich_ziel := 0.0
## Quergeschwindigkeit der losen Lenkung – nur im Turbo und im
## Nachschwingen in Gebrauch (siehe `_lose_lenkung`).
var _quer_v := 0.0
## Anteil des Turboschubs (0 bis 1), geglättet.
var _schub := 0.0
## Wie lose die Lenkung gerade ist (0 bis 1). Folgt dem Schub nach oben
## sofort, nach unten erst über `TURBO_NACHSCHWINGEN`.
var _schwingen := 0.0
## Rest des Turbovorrats in Sekunden.
var _turbo_rest := 0.0
## Restliche Zwangspause nach leer gefahrenem Vorrat.
var _erschoepft := 0.0
var _turbo_an := false
## Wie lange der laufende Schub schon anliegt.
var _turbo_lief := 0.0
## Läuft nach dem Turboende ab und bläst die Spur auseinander.
var _turbo_blitz := 0.0

## Die violette Bewegungsspur samt ihren Teilen. Sie wird nur gebaut, wenn
## das Level den Turbo überhaupt anbietet.
var _spur: Node3D
var _spur_stoff: StandardMaterial3D
var _aura_stoff: StandardMaterial3D
var _schlieren: Array[MeshInstance3D] = []
var _aura: MeshInstance3D
var _spur_licht: OmniLight3D
var _spur_zeit := 0.0
var _hoehe := 0.0
var _vy := 0.0
var _in_luft := false
var _kann_djump := false
## Strecke des letzten Checkpoints – dorthin geht es nach dem Tod zurück.
var _checkpoint := 0.0
var _fertig := false

## Reittier. Fehlt es (Fluchtstrecke zu Fuß), bleibt es schlicht leer.
@onready var _katze: Katze = get_node_or_null("Katze") as Katze


func _ready() -> void:
	super._ready()
	tempo = tempo_start
	_turbo_rest = turbo_vorrat
	if turbo_moeglich:
		_spur_bauen()
	# Der Reiter bewegt sich nicht über die Physik, sondern setzt seine
	# Position selbst. Ebene 2, damit Kisten- und Gegnerzonen ihn finden.
	collision_layer = 2
	collision_mask = 0


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln -= delta
	if verlauf == null or gesperrt or _fertig:
		_stellung_setzen()
		return

	tempo = minf(tempo + tempo_anstieg * delta, tempo_max)
	_turbo_takten(delta)
	strecke += tempo * tempo_faktor() * delta

	_lenken(delta)
	_springen(delta)
	_stellung_setzen()

	if ziel_strecke > 0.0 and strecke >= ziel_strecke:
		_fertig = true
		ziel_erreicht.emit()


## Der Turbo, ein Takt lang.
##
## Gehalten heißt Vollgas, losgelassen heißt Nachladen – ein Schalter wäre
## hier falsch, denn der Reiz ist die laufende Entscheidung, wie viel
## Risiko man gerade will. Wer den Vorrat bis auf den letzten Zehntel
## ausfährt, bekommt die Zwangspause; wer rechtzeitig vom Gas geht, nicht.
func _turbo_takten(delta: float) -> void:
	_turbo_blitz = maxf(_turbo_blitz - delta * 2.5, 0.0)
	if not turbo_moeglich:
		return
	_erschoepft = maxf(_erschoepft - delta, 0.0)

	var will := InputHub.slide_gehalten()
	var lief := _turbo_an
	_turbo_an = will and _turbo_rest > 0.0 and _erschoepft <= 0.0
	if _turbo_an:
		_turbo_lief += delta
		_turbo_rest = maxf(_turbo_rest - delta, 0.0)
		if _turbo_rest <= 0.0:
			_turbo_an = false
			_erschoepft = turbo_erschoepfung
			# Nur bei einem ausgefahrenen Schub ansagen. Wer die Taste
			# gedrückt hält, fährt danach im Sekundentakt kurze Reste leer;
			# die Meldung stünde dann dauernd im Bild.
			if _turbo_lief > 1.2:
				GameState.zeige_nachricht("Ausgepumpt!", 0.9)
	else:
		_turbo_lief = 0.0
		_turbo_rest = minf(_turbo_rest + turbo_nachladen * delta, turbo_vorrat)
	if lief and not _turbo_an:
		_turbo_blitz = 1.0

	_schub = move_toward(_schub, 1.0 if _turbo_an else 0.0,
			delta / (TURBO_ANLAUF if _turbo_an else TURBO_AUSLAUF))
	# Die Lenkung bleibt lose, bis das Nachschwingen abgelaufen ist.
	_schwingen = maxf(_schub, _schwingen - delta / TURBO_NACHSCHWINGEN)


## Faktor auf das Grundtempo. `tempo` selbst bleibt unberührt – der
## Flüchtling in Level 05 misst daran seinen Vorsprung, und die
## Tempowerte des Levels sollen die Tempowerte des Levels bleiben.
func tempo_faktor() -> float:
	var f := 1.0 + _schub * (turbo_faktor - 1.0)
	if _erschoepft > 0.0:
		# Nach dem leeren Vorrat sackt das Tempo unter das normale. Das ist
		# der Preis, und er muss zu spüren sein.
		f *= lerpf(turbo_bremse, 1.0,
				1.0 - clampf(_erschoepft / maxf(turbo_erschoepfung, 0.01), 0.0, 1.0))
	return f


## Läuft der Turbo gerade? Level 17 fragt das ab: Tiefschnee verzeiht
## jedes Tempo außer diesem.
func turbo_laeuft() -> bool:
	return _schub > 0.35


## Höhe über dem Weg. Das Level braucht sie, um zu unterscheiden, ob
## jemand durch ein Feld fährt oder darüber hinwegspringt.
func hoehe() -> float:
	return _hoehe


## Quer zum Weg lenken. Der Versatz folgt der Eingabe träge nach – eine
## rennende Katze springt nicht seitlich, sie zieht in die Kurve.
##
## Im Turbo gilt das doppelt: Dort wird nicht mehr nachgezogen, sondern
## geschwungen (`_lose_lenkung`). Ohne Turbo ist der Weg hier Zeile für
## Zeile derselbe wie zuvor.
func _lenken(delta: float) -> void:
	var eingabe := InputHub.bewegung().x * lenk_richtung
	var zug := 1.0 + _schwingen * (turbo_lenk_schub - 1.0)
	_seitlich_ziel += eingabe * LENK_TEMPO * zug * delta
	var grenze := _grenze_bei(strecke)
	_seitlich_ziel = clampf(_seitlich_ziel, -grenze, grenze)
	if _schwingen <= 0.0:
		_quer_v = 0.0
		_seitlich = lerpf(_seitlich, _seitlich_ziel, minf(delta * LENK_TRAEGHEIT, 1.0))
		return
	_lose_lenkung(delta, grenze)


## Die Lenkung im Turbo: eine schwach gedämpfte Feder statt eines
## Nachziehens.
##
## Der Unterschied ist der ganze Handel dieses Levels. Nachziehen kommt
## nie über das Ziel hinaus – man landet also immer da, wo man hinwollte,
## nur später. Eine Feder mit einer Dämpfung unter 1 schießt darüber
## hinaus und pendelt zurück: Gemessen sind es bei einem kurzen Zug auf
## 2,8 m gut 3,8 m, und zurück kommt der Versatz erst nach knapp einer
## Sekunde. Wer bei Vollgas die Spur wechselt, muss also einrechnen, dass
## die Katze einen Meter zu weit ausholt und dort eine Weile bleibt. Das
## ist das Tempo, das hier gegen Kontrolle getauscht wird.
##
## Die Feder wird beim Übergang mit `_schwingen` eingeblendet, sonst
## machte die Katze im Augenblick des Tastendrucks einen Satz zur Seite.
func _lose_lenkung(delta: float, grenze: float) -> void:
	var omega := LENK_TRAEGHEIT * lerpf(1.0, turbo_lenk_traegheit, _schwingen)
	var daempfung := lerpf(1.0, turbo_daempfung, _schwingen)
	_quer_v += (omega * omega * (_seitlich_ziel - _seitlich)
			- 2.0 * daempfung * omega * _quer_v) * delta
	_seitlich += _quer_v * delta
	# Anschlag am Rand: Die Katze darf über die Spur hinausschwingen, aber
	# nicht aus der Rinne heraus.
	var rand := grenze * TURBO_UEBERHANG
	if absf(_seitlich) > rand:
		_seitlich = clampf(_seitlich, -rand, rand)
		_quer_v = 0.0


func _springen(delta: float) -> void:
	if InputHub.sprung_gedrueckt():
		if not _in_luft:
			_vy = JUMP_V
			_in_luft = true
			_kann_djump = true
			_kein_jump_cut = false
		elif _kann_djump:
			_vy = DJUMP_V
			_kann_djump = false
			_kein_jump_cut = false

	# Taste loslassen kappt den Sprung – gleiche Regel wie zu Fuß.
	if _in_luft and not _kein_jump_cut and not InputHub.sprung_gehalten() \
			and _vy > JUMP_V * JUMP_CUT:
		_vy = JUMP_V * JUMP_CUT
		_kein_jump_cut = true

	_vy += G * delta
	_hoehe += _vy * delta
	if _hoehe <= 0.0:
		if not _boden_da(strecke):
			# Über einer Lücke aufgesetzt: der Sprung kam zu kurz.
			sterben()
			return
		_hoehe = 0.0
		_vy = 0.0
		_in_luft = false
		_kann_djump = false
		_kein_jump_cut = false


# ------------------------------------------------------- Die violette Spur

## Tempo ist hier ein sichtbarer Zustand, kein Zahlenwert: Solange der
## Turbo läuft, zieht das Reittier eine violette Spur.
##
## Warum eigene Netze und kein Partikelfeld: Der Renderer ist
## `gl_compatibility`; dort laufen GPU-Partikel über Transform-Feedback,
## das auf Android und in WebGL fehlen kann (siehe `scenes/props/staub.gd`).
## Ein paar gezeichnete Streifen sind dagegen überall dasselbe Bild.
##
## Drei Teile, weil eines allein nicht reicht:
##   * Schlieren HINTER dem Tier zeigen die Fahrt,
##   * eine Aura AUF dem Tier färbt es selbst – daran erkennt man den
##     Zustand auch im Standbild und von vorn,
##   * ein Licht wirft das Violett auf Schnee und Fell und bindet den
##     Effekt in die Szene ein, statt ihn davorzukleben.
func _spur_bauen() -> void:
	_spur = Node3D.new()
	_spur.name = "Turbospur"
	_spur.visible = false
	add_child(_spur)

	# Eigene Materialien, keine geteilten aus der Bibliothek: Die Deckkraft
	# wird jedes Bild neu gesetzt, das darf kein anderer Knoten abbekommen.
	#
	# Zwei Stück, und zwar mit verschiedener Mischung – der erste Anlauf
	# hatte nur eines, additiv, und das Reittier war im Turbo ein weißer
	# Klumpen ohne Kopf und Beine. Auf einem Level aus Schnee addiert sich
	# jede helle Farbe zu Weiß.
	#   * Die Schlieren werden normal gemischt: So bleiben sie violett,
	#     auch vor der weißen Rinne.
	#   * Die Aura wird additiv und schwach aufgelegt: Sie soll das Fell
	#     färben, nicht ersetzen.
	_spur_stoff = StandardMaterial3D.new()
	_spur_stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spur_stoff.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spur_stoff.cull_mode = BaseMaterial3D.CULL_DISABLED
	_spur_stoff.disable_receive_shadows = true
	_spur_stoff.albedo_color = Color(SPUR_VIOLETT, 0.0)

	_aura_stoff = StandardMaterial3D.new()
	_aura_stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aura_stoff.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_stoff.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_aura_stoff.cull_mode = BaseMaterial3D.CULL_DISABLED
	_aura_stoff.disable_receive_shadows = true
	_aura_stoff.albedo_color = Color(SPUR_VIOLETT, 0.0)

	# Blickrichtung ist -Z, hinten also +Z. Die Schlieren stehen paarweise
	# links und rechts vom Leib und laufen nach hinten aus.
	var netz := BoxMesh.new()
	netz.size = Vector3(0.16, 0.16, 1.0)
	for i in 10:
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var schliere := MeshInstance3D.new()
		schliere.mesh = netz
		schliere.material_override = _spur_stoff
		schliere.position = Vector3(seite * randf_range(0.28, 0.72),
				randf_range(0.45, 1.35), 0.0)
		schliere.set_meta("phase", float(i) / 10.0)
		_spur.add_child(schliere)
		_schlieren.append(schliere)

	# Die Aura liegt als Kapsel über dem Leib der Katze (Widerrist 1,05 m,
	# Länge 2,4 m) und legt sich additiv über das Fell.
	var huelle := CapsuleMesh.new()
	huelle.radius = 0.46
	huelle.height = 2.2
	huelle.radial_segments = 10
	huelle.rings = 4
	_aura = MeshInstance3D.new()
	_aura.mesh = huelle
	_aura.material_override = _aura_stoff
	_aura.rotation.x = PI * 0.5
	_aura.position = Vector3(0.0, 0.88, 0.05)
	_spur.add_child(_aura)

	_spur_licht = OmniLight3D.new()
	_spur_licht.light_color = SPUR_VIOLETT
	_spur_licht.omni_range = 7.0
	_spur_licht.light_energy = 0.0
	_spur_licht.shadow_enabled = false
	_spur_licht.position = Vector3(0.0, 1.0, 0.4)
	_spur.add_child(_spur_licht)


## Ein Bild der Spur. Läuft in `_process` und nicht in der Physik: Es ist
## reines Bild, und beim Fotografieren steht die Physik still.
func _spur_takten(delta: float) -> void:
	if _spur == null:
		return
	# Der Blitz am Ende zählt mit: Der Turbo hört nicht auf, er verpufft.
	var staerke := maxf(_schub, _turbo_blitz * 0.55)
	_spur.visible = staerke > 0.01
	if not _spur.visible:
		return
	_spur_zeit += delta

	_spur_stoff.albedo_color = Color(SPUR_VIOLETT, 0.85 * staerke)
	# Sparsam: Die Aura soll das Fell violett anlaufen lassen. Bei 0,3 war
	# von der Katze nur noch ein heller Klumpen übrig.
	_aura_stoff.albedo_color = Color(SPUR_VIOLETT, 0.15 * staerke)
	_spur_licht.light_energy = 1.6 * staerke

	# Beim Verpuffen fahren die Schlieren weiter auseinander, als sie im
	# Lauf je kommen – das ist das sichtbare Ende.
	var weite := 6.0 + _turbo_blitz * 4.0
	for schliere in _schlieren:
		var t: float = fmod(_spur_zeit * 1.7 + float(schliere.get_meta("phase")), 1.0)
		# Erst hinter der Kruppe anfangen: Schlieren über dem Rücken
		# verdecken das Tier, statt seine Fahrt zu zeigen.
		schliere.position.z = lerpf(1.05, weite, t)
		# Vorn kurz und dick, hinten lang und dünn: So liest sich die
		# Richtung, auch wenn nur ein Standbild davon übrig bleibt.
		schliere.scale = Vector3(1.0 - t * 0.75, 1.0 - t * 0.75,
				lerpf(0.7, 2.6, t))

	var puls := 1.0 + sin(_spur_zeit * 22.0) * 0.05
	_aura.scale = Vector3(puls, 1.0, puls) * (0.85 + 0.25 * staerke) \
			* (1.0 + _turbo_blitz * 0.5)


## Setzt Position und Blickrichtung aus Strecke, Versatz und Höhe.
func _stellung_setzen() -> void:
	if verlauf == null:
		return
	global_position = LevelWerkzeuge.punkt(verlauf, strecke, _seitlich, _hoehe + 0.04)
	rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)

	if is_instance_valid(_katze):
		# Der Galopp nimmt den Turbo mit: Ein Tier, das schneller rennt,
		# setzt auch schneller die Beine.
		_katze.aktualisiere(get_physics_process_delta_time(),
				minf(tempo * tempo_faktor() / maxf(tempo_max, 0.001), 1.35),
				_in_luft)
		# In die Kurve legen: je stärker gelenkt wird, desto schräger.
		var neigung := clampf((_seitlich_ziel - _seitlich) * 0.25, -0.3, 0.3)
		_katze.rotation.z = lerpf(_katze.rotation.z, neigung, 0.2)


func _boden_da(s: float) -> bool:
	return not boden_pruefer.is_valid() or bool(boden_pruefer.call(s))


## Der Reiter sitzt und läuft nicht – der Basis-Zustand des Modells
## (`is_on_floor()`, Slide, Spin) passt hier nicht.
func _process(delta: float) -> void:
	_spur_takten(delta)
	var figur := get_node_or_null("Modell") as SpielerModell
	if figur == null:
		return
	figur.setze_blick(0.0)
	figur.aktualisiere(delta, 0.25, _in_luft, 0.0, 0.0, haltung())
	figur.sichtbarkeit(invuln <= 0.0 or fmod(invuln, 0.2) > 0.1)


## Auf der Wildkatze wird geritten, nicht gelaufen.
func haltung() -> String:
	return "reiten"


func _grenze_bei(s: float) -> float:
	if seiten_grenze.is_valid():
		return maxf(float(seiten_grenze.call(s)), 0.2)
	return halbe_breite


# ---------------------------------------------------------- Schnittstelle

## Beim Ritt trampelt die Katze alles nieder, was im Weg steht: Kisten
## zerbrechen und Gegner fallen durch bloße Berührung. Im Sprung kommt
## das Draufspringen dazu, damit ein Käfer auch von oben zählt.
func angriffe() -> int:
	var maske := Angriff.SPIN | Angriff.SLIDE
	if _vy < Angriff.FALL_SCHWELLE:
		maske |= Angriff.FALLEN
	return maske


## Beim Ritt gibt die Kurve die Blickrichtung vor, nicht der Levelstart.
func setze_blickrichtung(_winkel: float) -> void:
	pass


## Federkisten und besiegte Gegner werfen den Reiter samt Katze hoch.
func abprallen(hoehe: float = ABPRALL_V) -> void:
	_vy = hoehe
	_in_luft = true
	_kann_djump = true
	_kein_jump_cut = true


## Ein Treffer wirft vom Rücken – wie im Vorbild endet jede Berührung
## eines Hindernisses den Ritt und setzt zum letzten Checkpoint zurück.
## Während der Unverwundbarkeit wirkungslos.
func schaden_nehmen() -> void:
	if invuln > 0.0 or _fertig:
		return
	if GameState.schutz_verbrauchen():
		invuln = INVULN_ZEIT
		return
	sterben()


func sterben() -> void:
	if _fertig:
		return
	gestorben.emit()
	GameState.leben_verlieren()
	respawn()


## Der Basis-Respawn setzt auf `GameState.checkpoint`; hier zählt die
## Strecke auf der Kurve.


## Zurück zum letzten Checkpoint auf der Strecke.
func respawn() -> void:
	strecke = _sichere_strecke(_checkpoint)
	_seitlich = 0.0
	_seitlich_ziel = 0.0
	_hoehe = 0.0
	_vy = 0.0
	_in_luft = false
	tempo = tempo_start
	_quer_v = 0.0
	_schub = 0.0
	_schwingen = 0.0
	_turbo_an = false
	_turbo_lief = 0.0
	_erschoepft = 0.0
	_turbo_rest = turbo_vorrat
	invuln = INVULN_ZEIT
	_stellung_setzen()
	# Nach einem Versetzen die Interpolation zurücksetzen, sonst zieht
	# Godot eine Spur vom alten zum neuen Ort – bei einem Respawn quer
	# durchs halbe Level.
	reset_physics_interpolation()
	# Kamera mitnehmen, sonst steht der Reiter kurz außerhalb des Bildes
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")


## Sucht rückwärts eine Stelle mit festem Boden und etwas Anlauf davor.
##
## Ohne das kann ein Rastplatz, der zu dicht vor einer Lücke liegt, das
## Spiel aufhängen: Man erscheint auf der Kante, läuft im nächsten Bild
## hinein, stirbt und wird auf dieselbe Kante zurückgesetzt – eine
## Todesschleife, die im Millisekundentakt zwischen "Autsch" und
## "GAME OVER" wechselt. Die Stelle selbst zu prüfen genügt nicht; es
## braucht auch Weg dahinter, sonst reicht die Zeit zum Springen nicht.
func _sichere_strecke(wunsch: float) -> float:
	const ANLAUF := 7.0      ## so viel fester Boden muss dahinter liegen
	const SCHRITT := 1.0
	const HOECHSTENS := 40.0 ## weiter zurück wird nicht gesucht
	var s := maxf(wunsch, 0.0)
	var zurueck := 0.0
	while zurueck <= HOECHSTENS:
		if _boden_da(s) and _boden_da(s + ANLAUF):
			return s
		s = maxf(s - SCHRITT, 0.0)
		zurueck += SCHRITT
		if s <= 0.0:
			break
	return maxf(wunsch, 0.0)


## Setzt den Rückkehrpunkt. Die Checkpoint-Kiste meldet über GameState eine
## Position; das Level rechnet sie in eine Strecke um und ruft dies auf.
func setze_checkpoint(s: float) -> void:
	_checkpoint = maxf(_checkpoint, s)
