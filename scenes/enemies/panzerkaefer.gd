extends Gegner
class_name Panzerkaefer
## Schwer gepanzerter Käfer.
##
## NUR durch Draufspringen (Angriff.FALLEN von oben) oder den
## Bauchplatscher zu besiegen: Sein Panzer ist rundgeschliffen, Drehschlag
## und Slide rutschen daran ab. Die Panzernaht auf dem Rücken hält
## dagegen kein volles Gewicht aus.
##
## Bewegung: patrouilliert stur geradeaus und dreht an den Endpunkten
## umständlich um. Beim Draufspringen bricht er zusammen und der Spieler
## prallt ab.

const DREH_DAUER := 0.55     ## So lange braucht er zum Umdrehen
const HOPS_DAUER := 0.3      ## Hopser zu Beginn des Umdrehens (nur Optik)
const SCHRITT_TEMPO := 5.0   ## Taktrate des Sechsbeinlaufs

# ---------------------------------------------------------- Farben
#
# Der Käfer läuft in mehr Leveln als in den Wäldern, für die er gebaut
# wurde. Damit ein Level ihn in seine eigene Palette holen kann, ohne
# dass ein zweiter Gegner entstehen muss, sind seine Flächen einzeln
# einstellbar. Vorgabe ist überall der bisherige Ton: Wer nichts setzt,
# sieht nichts Neues.
#
# ZEICHENSPRACHE (siehe gegner.gd): Warnstreifen und Naht liegen auf dem
# Rücken – genau dort, wo das Draufspringen wirkt. Sie müssen HELL gegen
# den Panzer stehen bleiben. Ein Panzer im Ton der Streifen nimmt dem
# Käfer seine Anleitung; dann muss der Spieler wieder ausprobieren.

## Panzer und Schädel – die dunkle Grundfläche.
@export var farbe_panzer: Color = Farben.FELS.darkened(0.72):
	set(wert):
		farbe_panzer = wert
		_neu_faerben()
## Beine und Fühler.
@export var farbe_chitin: Color = Farben.RINDE.darkened(0.55):
	set(wert):
		farbe_chitin = wert
		_neu_faerben()
## Warnstreifen und Stirnband. Der helle Gegenpol zum Panzer.
@export var farbe_streifen: Color = Farben.KISTE_FEDER:
	set(wert):
		farbe_streifen = wert
		_neu_faerben()
## Mittelnaht und Zangen – die Bruchstelle auf dem Rücken.
@export var farbe_naht: Color = Farben.FELS_HELL.darkened(0.1):
	set(wert):
		farbe_naht = wert
		_neu_faerben()
## Glühende Augenpunkte.
@export var farbe_augen: Color = Farben.WARNUNG:
	set(wert):
		farbe_augen = wert
		_neu_faerben()
## Panzerfarbe der mitgelieferten Käferfigur.
##
## Eigener Wert und nicht `farbe_panzer`: Das fremde Modell hat für den
## ganzen Rücken nur EIN Material. Was hier auf Panzer, Naht und Streifen
## verteilt ist, muss dort ein einziger Ton tragen, und der liegt deshalb
## etwas wärmer: ein dunkles Mahagoni. Fast schwarz (wie früher) lag der
## Käfer als Loch auf dem dunklen Weg; so bleibt er dunkel, zeigt aber
## Form und Glanz. Wer den Käfer umfärbt, setzt beide.
@export var farbe_fremdmodell: Color = Color(0.34, 0.17, 0.10):
	set(wert):
		farbe_fremdmodell = wert
		_neu_faerben()


var _dreht := 0.0
## Wurde er von oben geknackt (Draufspringen, Bauchplatscher)?
var _geknackt := false

var _panzer: MeshInstance3D
var _kopf: Node3D
var _beine: Array[Node3D] = []
var _fuehler: Array[Node3D] = []
## Material des sichtbaren Panzers – die Scherben beim Knacken tragen es.
var _panzerstoff: Material

## Bemalungen des mitgelieferten Modells, je Farbsatz einmal gebaut.
static var _zeichnungen: Dictionary[String, ArrayMesh] = {}


func _init() -> void:
	# Nur Gewicht von oben knackt die Panzernaht.
	besiegbar_durch = Angriff.FALLEN | Angriff.SLAM
	patrouille_weite = 5.0
	tempo = 1.9
	abprall_hoehe = 14.0


# ---------------------------------------------------------- Optik

## Tiefschwarzer Panzer mit gelben Warnstreifen, dicht über dem Boden.
## Die Streifen liegen quer über dem Rücken und sind daher genau das,
## was die Spielkamera von schräg oben zu sehen bekommt.
## Mitgeliefertes Modell für diesen Gegner.
## Marienkäfer von Exceptional_3D – roter Panzer, gut lesbar von oben.
func fremdmodell() -> Dictionary:
	# Die Form stimmt – ein gewölbter Panzer ist genau das, worauf man
	# springt. Die Farbe stimmte nicht: Ein Marienkäfer ist kein Gegner,
	# den man zertritt. Der Panzer wird deshalb dunkel umgefärbt, die
	# schwarzen Flecken bleiben als Zeichnung stehen (und werden in
	# `_zeichen_am_fremdmodell` zur Warnzeichnung). CC0 erlaubt das;
	# die Änderung ist in assets/CREDITS.md vermerkt.
	#
	# Oberfläche: Die matte Vorgabe der Fremdmodelle (für Laub und Fels)
	# ließ den Panzer aussehen wie Ton. Chitin glänzt – und ein Glanzlicht
	# oben auf der Wölbung zeigt zugleich, wo man landet. Die schwarzen
	# Teile (Beine, Kopf, Flecken) lagen unter der Grenze, ab der
	# `_struktur_geben` Oberfläche verleiht, und standen als flache Löcher
	# im Bild; ein warmes Fastschwarz hebt sie knapp darüber.
	return {
		"datei": "kaefer", "groesse": 1.30, "drehung": PI,
		"farben": {"red": farbe_fremdmodell},
		"stoff": {
			"red": {"rauheit": 0.4, "glanz": 0.3},
			"black": {"farbe": Color(0.10, 0.08, 0.06), "rauheit": 0.5, "glanz": 0.25},
		},
	}


## Die Zeichnung des Marienkäfers wird zur Anleitung umgedeutet: Die
## dunkle Mittelnaht der Flügeldecken leuchtet in `farbe_naht` – das ist
## die Bruchstelle, auf die man springt –, die Flecken tragen
## `farbe_streifen` als Warnfarbe. Beides liegt genau oben auf dem Panzer,
## also dort, wo das Draufspringen wirkt (ZEICHENSPRACHE in gegner.gd).
func _zeichen_am_fremdmodell(figur: Node3D) -> void:
	var netz := _hauptnetz(figur)
	if netz == null:
		return
	var panzer_nr := _flaeche_nach_name(netz.mesh, "red")
	if panzer_nr >= 0:
		_panzerstoff = netz.get_surface_override_material(panzer_nr)
	var schluessel := "%s|%s" % [farbe_naht.to_html(), farbe_streifen.to_html()]
	if not _zeichnungen.has(schluessel):
		var naht := farbe_naht
		var flecken := farbe_streifen
		# Netzraum des Käfers: x quer, y längs (negativ = Kopf), z oben.
		# Der Panzer reicht von y -0,004 bis 0,030 und bis z 0,013.
		var auswahl := func(mitte: Vector3, normale: Vector3) -> Color:
			if mitte.z < NAHT_UNTERKANTE or normale.z < 0.3 or mitte.y < PANZER_VORNE:
				return Effekte.KEINE_FARBE
			return naht if absf(mitte.x) < NAHT_BREITE else flecken
		var bild := _bemalung(netz.mesh, _flaeche_nach_name(netz.mesh, "black"),
				auswahl, 0.0005)
		if bild == null:
			return
		_zeichnungen[schluessel] = bild
	var zeichnung := _bemalung_zeigen(figur, _zeichnungen[schluessel])
	if zeichnung != null:
		zeichnung.set_meta("ohne_glanz", true)


## Grenzen der Bemalung im Netzraum des Käfermodells (siehe oben).
const NAHT_BREITE := 0.0016
const NAHT_UNTERKANTE := 0.0035
const PANZER_VORNE := -0.0035


func _trefferfarbe() -> Color:
	return farbe_streifen if farbe_streifen.get_luminance() > 0.3 else farbe_naht


func _klanghoehe() -> float:
	return 0.8


func _baue() -> void:
	var panzer_mat := Materialbibliothek.einfarbig(farbe_panzer, 0.35, 0.25)
	_panzerstoff = panzer_mat
	var chitin := Materialbibliothek.einfarbig(farbe_chitin, 0.55)
	var streifen_mat := Materialbibliothek.einfarbig(farbe_streifen, 0.5)
	var naht_mat := Materialbibliothek.einfarbig(farbe_naht, 0.4, 0.3)
	var glut := Materialbibliothek.leuchtend(farbe_augen, 1.3)

	# --- Sechs Laufbeine, jeweils an einem eigenen Drehpunkt ---
	for seite: float in [-1.0, 1.0]:
		for paar in 3:
			var huefte := Node3D.new()
			huefte.name = "Huefte"
			huefte.position = Vector3(0.34 * seite, 0.26, -0.36 + float(paar) * 0.36)
			modell.add_child(huefte)
			_beine.append(huefte)

			_teil(huefte, _zylinder(0.055, 0.045, 0.34, 6), chitin,
					Vector3(0.15 * seite, -0.05, 0.0),
					Vector3(0.0, 0.0, 66.0 * seite), Vector3.ONE, "Schenkel")
			_teil(huefte, _zylinder(0.045, 0.025, 0.30, 6), chitin,
					Vector3(0.28 * seite, -0.19, 0.0),
					Vector3(0.0, 0.0, 14.0 * seite), Vector3.ONE, "Schiene")

	# --- Sehr flacher, breiter Panzer ---
	_panzer = _teil(modell, _kugel(0.55, 16, 10), panzer_mat, Vector3(0.0, 0.30, 0.06),
			Vector3.ZERO, Vector3(1.02, 0.44, 1.30), "Panzer")

	# Drei gelbe Warnstreifen quer über den Rücken. Sie hängen am Panzer
	# und werden mit ihm gestaucht, liegen also immer sauber auf.
	var streifen: Array = [[-0.30, 0.500], [0.0, 0.565], [0.30, 0.500]]
	for i in streifen.size():
		var s = streifen[i]
		_teil(_panzer, _kugel(s[1], 14, 8), streifen_mat, Vector3(0.0, 0.0, s[0]),
				Vector3.ZERO, Vector3(1.0, 1.0, 0.085), "Warnstreifen%d" % i)

	# Mittelnaht als Beschlag
	_teil(_panzer, _quader(Vector3(0.07, 0.07, 0.52)), naht_mat,
			Vector3(0.0, 0.50, 0.0), Vector3.ZERO, Vector3(1.0, 2.2, 1.0), "Naht")

	# --- Kopf mit kräftigen Zangen und Fühlern ---
	_kopf = Node3D.new()
	_kopf.name = "Kopf"
	_kopf.position = Vector3(0.0, 0.26, -0.64)
	modell.add_child(_kopf)

	_teil(_kopf, _kugel(0.29, 12, 8), panzer_mat, Vector3.ZERO,
			Vector3.ZERO, Vector3(0.92, 0.66, 0.82), "Schaedel")
	_teil(_kopf, _kugel(0.24, 12, 8), streifen_mat, Vector3(0.0, 0.0, -0.02),
			Vector3.ZERO, Vector3(1.16, 0.86, 0.30), "Stirnband")

	for seite: float in [-1.0, 1.0]:
		# Kräftige Zangen nach vorn
		_teil(_kopf, _zylinder(0.075, 0.0, 0.44, 6), naht_mat,
				Vector3(0.13 * seite, -0.05, -0.24),
				Vector3(-80.0, 0.0, 20.0 * seite), Vector3.ONE, "Zange")
		# Glühende Augenpunkte
		_teil(_kopf, _kugel(0.07, 8, 6), glut, Vector3(0.155 * seite, 0.06, -0.14),
				Vector3.ZERO, Vector3.ONE, "Auge")
		# Fühler an eigenem Drehpunkt, damit sie wackeln können
		var wurzel := Node3D.new()
		wurzel.name = "Fuehlerwurzel"
		wurzel.position = Vector3(0.11 * seite, 0.12, -0.14)
		_kopf.add_child(wurzel)
		_fuehler.append(wurzel)
		_teil(wurzel, _zylinder(0.032, 0.015, 0.46, 6), chitin,
				Vector3(0.09 * seite, 0.19, -0.08),
				Vector3(-28.0, 0.0, 24.0 * seite), Vector3.ONE, "Fuehler")


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	if _dreht > 0.0:
		# Umdrehen: kurz stehen bleiben und sich neu ausrichten
		_dreht -= delta
	else:
		_phase += delta * tempo * SCHRITT_TEMPO
		if _patrouille_schritt(tempo * delta):
			_dreht = DREH_DAUER

	_blick_ausrichten(delta, 6.0)
	_animiere()


## Sechsbeinlauf im Dreifußgang, wippender Panzer, tastende Fühler.
func _animiere() -> void:
	var laeuft := _dreht <= 0.0

	for i in _beine.size():
		var bein := _beine[i]
		if not is_instance_valid(bein):
			continue
		# Dreifußgang: benachbarte Beine laufen gegenphasig
		var versatz := PI * float((i % 3) + int(i / 3))
		var schwung := sin(_phase + versatz) if laeuft else 0.0
		bein.rotation.x = schwung * 0.4
		bein.position.y = 0.26 + maxf(schwung, 0.0) * 0.04

	if is_instance_valid(_panzer):
		_panzer.position.y = 0.30 + (sin(_phase * 2.0) * 0.02 if laeuft else 0.0)
		_panzer.rotation.z = sin(_phase) * 0.05 if laeuft else 0.0

	for i in _fuehler.size():
		var wurzel := _fuehler[i]
		if is_instance_valid(wurzel):
			var seite := -1.0 if i == 0 else 1.0
			wurzel.rotation.x = sin(_zeit * 3.4 + float(i)) * 0.25
			wurzel.rotation.y = cos(_zeit * 2.6 + float(i)) * 0.2 * seite

	if is_instance_valid(_kopf):
		_kopf.rotation.y = sin(_zeit * 1.6) * 0.12

	# Das mitgelieferte Modell hat kein Skelett: Laufen heißt hier
	# Watscheln und Wippen des ganzen Körpers, im Takt der eigenen Beine.
	# Beim Umdrehen ein kleiner Hopser – das "umständliche" Wenden.
	if fremdhalter != null:
		if laeuft:
			fremdhalter.rotation.z = sin(_phase) * 0.06
			fremdhalter.rotation.x = sin(_phase * 2.0) * 0.025
			fremdhalter.position.y = absf(sin(_phase * 2.0)) * 0.025
			fremdhalter.scale = Vector3.ONE
		else:
			var t := clampf((DREH_DAUER - _dreht) / HOPS_DAUER, 0.0, 1.0)
			var hops := sin(t * PI)
			fremdhalter.rotation.z = 0.0
			fremdhalter.rotation.x = -hops * 0.12
			fremdhalter.position.y = hops * 0.09
			fremdhalter.scale = Vector3(1.0 - hops * 0.05, 1.0 + hops * 0.1, 1.0 - hops * 0.05)


# ---------------------------------------------------------- Tod

func _todesstart(art: int) -> void:
	# Er wird an Ort und Stelle plattgetreten, nicht weggeschleudert.
	_wegflug = Vector3.ZERO
	_geknackt = (art & (Angriff.FALLEN | Angriff.SLAM)) != 0
	if not _geknackt:
		return
	# Der Panzer springt: Scherben in seinem eigenen Material fliegen
	# davon, flach über den Boden läuft ein Ring. Die Splitter der Kisten
	# sind Bretter; kleiner skaliert lesen sie sich als Panzerstücke.
	var mitte := global_position + Vector3.UP * 0.3
	if _panzerstoff != null:
		var scherben := Effekte.splitter(self, mitte, _panzerstoff, 7)
		if scherben != null:
			scherben.emission_box_extents = Vector3(0.35, 0.1, 0.45)
			scherben.scale_amount_min = 0.3
			scherben.scale_amount_max = 0.5
			scherben.initial_velocity_min = 3.5
			scherben.initial_velocity_max = 6.0
	Effekte.ring(self, global_position + Vector3.UP * 0.06, _trefferfarbe(), 1.0, 0.25)


func _todesanimation(delta: float) -> void:
	# Der Panzer bricht ein: breit und flach, die Beine zappeln noch.
	if is_instance_valid(modell):
		modell.scale = modell.scale.lerp(Vector3(1.35, 0.08, 1.25), minf(delta * 11.0, 1.0))
	for bein in _beine:
		if is_instance_valid(bein):
			bein.rotation.x = sin(_zeit * 26.0) * 0.8
	# Das Modell hat keine Beine zum Zappeln – dafür zittert der ganze
	# Körper, und das Zittern klingt ab.
	if fremdhalter != null:
		var rest := clampf(_tot_zeit / TODES_DAUER, 0.0, 1.0)
		fremdhalter.rotation = Vector3(0.0, 0.0, sin(_zeit * 30.0) * 0.08 * rest)
		fremdhalter.position.y = 0.0
		fremdhalter.scale = Vector3.ONE


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das den Käfer erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Die Materialien der
## `Materialbibliothek` sind geteilt und dürfen nicht nachträglich
## verändert werden – deshalb der Neubau, wie ihn auch die Props halten
## (`baum.gd`, `deckungsfleck.gd`).
##
## Ein besiegter Käfer wird nicht angefasst: Seine Todesanimation steckt
## in Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_beine.clear()
	_fuehler.clear()
	_panzer = null
	_kopf = null
	_baue()
	_fremdmodell_setzen()
