extends Node3D
class_name Laserzaun
## Laserzaun: senkrechte Taktbarriere aus waagerechten Strahlen.
##
## Der Verwandte der Taktfläche, aber hochkant: Sie ist Boden, er ist Wand.
## Zwischen zwei Pfosten liegen `strahlen` Strahlen übereinander; wer einen
## berührt, nimmt Schaden. Vorbild ist die Zukunftsstadt (5-4).
##
## Zwei Betriebsarten:
##   GLEICHZEITIG – alle Strahlen gehen zusammen an und aus. Eine simple
##                  Tür mit Zeitfenster: durchlaufen, solange sie offen ist.
##   WANDERND     – es fehlt immer genau EIN Strahl, und diese Lücke
##                  wandert von unten nach oben. Das ist die interessantere
##                  Art, weil sie zwei Fragen auf einmal stellt: wann, und
##                  in welcher Haltung.
##
## WARUM DIE HÖHEN SO LIEGEN (`hoehe` 3.0 bei 4 Strahlen):
## Die Strahlen sitzen bei 0,30 · 1,20 · 2,10 · 3,00 m, also im Abstand
## 0,90 m, der unterste bewusst tief. Daraus ergibt sich beim Wandern eine
## Leiter aus vier verschiedenen Aufgaben:
##
##   Lücke unten (0,30 fehlt)  – frei bis 1,15 m: krabbelnd (0,76 m) durch,
##                               aufrecht (1,30 m) nicht. Die Krabbel-Lücke.
##   Lücke bei 1,20            – Fenster 0,35 bis 2,05 m: aufrecht passt,
##                               aber die Füße müssen über 0,35 m sein –
##                               also springen.
##   Lücke bei 2,10            – Füße zwischen 1,25 und 1,65 m: der Sprung
##                               (Scheitel rund 1,96 m) muss sitzen.
##   Lücke oben (3,00 fehlt)   – Füße über 2,15 m: nur mit Doppelsprung.
##
## Mit `hoehe = 2.6` ginge das NICHT auf: Bei vier Strahlen bliebe zwischen
## zwei Strahlen ein Fenster von 1,30 m – genau die Körperhöhe. Dann wäre
## jede Lücke eine Krabbellücke und der Zaun stellte nur noch eine einzige
## Frage. Die 3,0 m sind der kleinste Wert, bei dem beides gilt: unten zu
## eng zum Stehen, oben weit genug zum Durchspringen. Wer die Werte ändert,
## bekommt beim Start eine Warnung, wenn diese Rechnung nicht mehr aufgeht.

enum Art {
	GLEICHZEITIG,  ## alle Strahlen takten gemeinsam an und aus
	WANDERND,      ## immer ein Strahl fehlt, die Lücke wandert nach oben
}

## Lichte Weite zwischen den Pfostenmitten in Metern.
@export var breite := 4.0

## Höhe des obersten Strahls in Metern. Siehe Kopfkommentar – dieser Wert
## entscheidet darüber, welche Haltungen der Zaun verlangt.
@export var hoehe := 3.0

## Anzahl der waagerechten Strahlen (mindestens 2).
@export var strahlen := 4

## Betriebsart.
@export var art: Art = Art.WANDERND

## Dauer EINES Schritts in Sekunden. GLEICHZEITIG: so lange sind die
## Strahlen an, so lange aus. WANDERND: so lange steht die Lücke auf einer
## Höhe; ein voller Umlauf dauert `takt` mal `strahlen`. Für WANDERND sind
## darum kürzere Werte (1,0 bis 1,5) meist besser – sonst wartet der
## Spieler zu lange, bis „seine" Lücke wieder unten ist.
## TAKTVERTRAG (doku/level-vorbilder.md): erlaubt sind nur 1,0 · 2,0 · 4,0,
## damit mehrere Taktgeber nebeneinander ein lernbares Muster ergeben.
@export var takt := 2.0

## Verschiebt den Takt gegen andere Zäune (0..1 = Anteil eines Umlaufs).
@export var phase := 0.0

## Vorwarnung in Sekunden: So lange glimmt ein Strahl auf, bevor er
## scharf wird. Ohne das wäre jeder Treffer eine Überraschung.
@export var warnzeit := 0.4

## Leuchtfarbe der Strahlen. Vorgabe ist ein Neon-Cyan – eine Farbe, die
## in keinem unserer Naturlevel vorkommt und deshalb sofort als Technik
## und als Gefahr gelesen wird.
@export var farbe := Color(0.25, 0.95, 1.0)

## Höhe des untersten Strahls. Bewusst tief: Nur so ist die unterste Lücke
## niedrig genug, dass man sich hindurchkrabbeln MUSS.
const UNTERSTER := 0.30
## Sichtbare Kantenlänge eines Strahls (Höhe und Tiefe).
const STRAHL_DICKE := 0.10
## Tiefe des Schadenskastens. Deutlich größer als der sichtbare Strahl:
## Bei 8,5 m/s legt der Spieler pro Physikschritt rund 0,14 m zurück und
## flöge sonst durch einen 0,10 m dünnen Strahl hindurch, ohne ihn je zu
## berühren. Nur in Z aufgedickt – Höhe und Breite bleiben ehrlich.
const ZONEN_TIEFE := 0.30
const PFOSTEN_RADIUS := 0.16
## Körpermaße des Spielers, gegen die die Lückenrechnung geprüft wird.
const KAPSEL_AUFRECHT := 1.30
const KAPSEL_KRABBELND := 0.76

var _hoehen: Array[float] = []
var _netze: Array[MeshInstance3D] = []
var _materialien: Array[StandardMaterial3D] = []
var _zonen: Array[Area3D] = []
var _zeit := 0.0


func _ready() -> void:
	add_to_group("gefahren")
	_hoehen = _hoehen_rechnen()
	_aufbauen()
	_masse_pruefen()


func _physics_process(delta: float) -> void:
	_zeit += delta
	var p := fposmod(_zeit + phase * _umlauf(), _umlauf())
	for i in _netze.size():
		var scharf := _scharf(i, p)
		_strahl_zeigen(i, scharf, _warnt(i, p))
		if not scharf:
			continue
		for koerper in _zonen[i].get_overlapping_bodies():
			if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
				koerper.schaden_nehmen()


# ---------------------------------------------------------------- Takt

## Dauer eines vollen Umlaufs.
func _umlauf() -> float:
	var schritte := _netze.size() if art == Art.WANDERND else 2
	return maxf(takt, 0.05) * float(maxi(schritte, 1))


## Welcher Strahl fehlt gerade? Nur bei WANDERND sinnvoll.
func _luecke(p: float) -> int:
	return int(p / maxf(takt, 0.05)) % maxi(_netze.size(), 1)


## Ist Strahl `i` gerade tödlich?
func _scharf(i: int, p: float) -> bool:
	if art == Art.WANDERND:
		return i != _luecke(p)
	return p >= maxf(takt, 0.05)


## Glimmt Strahl `i` gerade als Vorwarnung? Das ist der Fall, wenn er noch
## aus ist, aber in weniger als `warnzeit` wieder scharf wird.
func _warnt(i: int, p: float) -> bool:
	if _scharf(i, p):
		return false
	# In beiden Betriebsarten dauert ein Schritt `takt`; der Strahl wird am
	# Ende des laufenden Schritts scharf.
	var schritt := maxf(takt, 0.05)
	return schritt - fposmod(p, schritt) < warnzeit


# ---------------------------------------------------------------- Bild

## Drei Zustände, drei Helligkeiten. Ein ausgeschalteter Strahl bleibt als
## dunkle Linie stehen: Der Spieler soll sehen, wo das Licht gleich wieder
## sein wird, statt eine leere Lücke für einen Ausgang zu halten.
func _strahl_zeigen(i: int, scharf: bool, warnt: bool) -> void:
	var material := _materialien[i]
	var netz := _netze[i]
	if scharf:
		material.albedo_color = farbe
		material.emission_energy_multiplier = 2.4
		netz.scale = Vector3.ONE
		return
	if warnt:
		# Schnelles Pulsen – das Auge liest Blinken als „gleich passiert was".
		var puls := 0.5 + 0.5 * sin(_zeit * 24.0)
		material.albedo_color = farbe.darkened(0.35 * (1.0 - puls))
		material.emission_energy_multiplier = 0.5 + puls * 1.5
		netz.scale = Vector3(1.0, 0.7 + puls * 0.3, 0.7 + puls * 0.3)
		return
	material.albedo_color = farbe.darkened(0.72)
	material.emission_energy_multiplier = 0.12
	netz.scale = Vector3(1.0, 0.55, 0.55)


# ---------------------------------------------------------------- Aufbau

## Gleiche Abstände vom untersten Strahl bis `hoehe`.
func _hoehen_rechnen() -> Array[float]:
	var zahl := maxi(strahlen, 2)
	var abstand := (maxf(hoehe, UNTERSTER + 0.4) - UNTERSTER) / float(zahl - 1)
	var liste: Array[float] = []
	for i in zahl:
		liste.append(UNTERSTER + abstand * float(i))
	return liste


func _aufbauen() -> void:
	_pfosten_bauen()
	for i in _hoehen.size():
		_strahl_bauen(i, _hoehen[i])


## Zwei Pfosten links und rechts, in einem Netz. Sie ragen über den
## obersten Strahl hinaus, damit der Zaun oben abgeschlossen wirkt.
func _pfosten_bauen() -> void:
	var laenge: float = _hoehen[_hoehen.size() - 1] + 0.3
	var st := PropWerkzeug.bauer()
	for i in 2:
		var seite := -1.0 if i == 0 else 1.0
		PropWerkzeug.anfuegen(st, PropWerkzeug.stumpf(PFOSTEN_RADIUS * 1.3,
				PFOSTEN_RADIUS, laenge, 8, true),
				Transform3D(Basis(), Vector3(breite * 0.5 * seite,
						laenge * 0.5, 0.0)))
	var knoten := PropWerkzeug.mesh_knoten("Pfosten", PropWerkzeug.fertig(st),
			Materialbibliothek.metall(Farben.KISTE_EISEN))
	if knoten != null:
		add_child(knoten)


## Ein Strahl: dünner Leuchtkasten plus flacher Schadenskasten.
func _strahl_bauen(i: int, y: float) -> void:
	# Jeder Strahl braucht eine eigene Materialkopie, weil er unabhängig
	# von den anderen hell und dunkel wird; das Material aus der
	# Bibliothek ist geteilt und dürfte nicht verändert werden.
	var material: StandardMaterial3D = Materialbibliothek.leuchtend(farbe, 2.4).duplicate()
	_materialien.append(material)

	var netz := PropWerkzeug.mesh_knoten("Strahl%d" % i,
			PropWerkzeug.kasten(Vector3(breite, STRAHL_DICKE, STRAHL_DICKE)),
			material, false)
	if netz == null:
		return
	netz.position.y = y
	add_child(netz)
	_netze.append(netz)

	var zone := Area3D.new()
	zone.name = "Zone%d" % i
	zone.collision_layer = 0
	zone.collision_mask = 2      # nur den Spieler beachten
	zone.position.y = y
	var form := BoxShape3D.new()
	form.size = Vector3(breite, STRAHL_DICKE, ZONEN_TIEFE)
	var kollision := CollisionShape3D.new()
	kollision.name = "Form"
	kollision.shape = form
	zone.add_child(kollision)
	add_child(zone)
	_zonen.append(zone)


## Prüft die Lückenrechnung aus dem Kopfkommentar und meldet sich, wenn
## geänderte Werte den Zaun um seine Aufgabe bringen. Lieber eine Warnung
## im Protokoll als ein Level, in dem eine Lücke unpassierbar ist.
func _masse_pruefen() -> void:
	if _hoehen.size() < 2:
		return
	var bodenluecke: float = _hoehen[1] - STRAHL_DICKE * 0.5
	var oben: int = 2 if _hoehen.size() > 2 else 1
	var fenster: float = _hoehen[oben] - _hoehen[0] - STRAHL_DICKE
	if bodenluecke >= KAPSEL_AUFRECHT:
		push_warning("Laserzaun: unterste Lücke (%.2f m) ist auch aufrecht passierbar – das Krabbeln entfällt." % bodenluecke)
	elif bodenluecke < KAPSEL_KRABBELND + 0.15:
		push_warning("Laserzaun: unterste Lücke (%.2f m) ist selbst krabbelnd zu eng." % bodenluecke)
	if art == Art.WANDERND and fenster < KAPSEL_AUFRECHT + 0.25:
		push_warning("Laserzaun: Fenster zwischen zwei Strahlen (%.2f m) ist zu klein zum Durchspringen – hoehe erhöhen oder strahlen verringern." % fenster)
