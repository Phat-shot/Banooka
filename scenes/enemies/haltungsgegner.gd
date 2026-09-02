extends Gegner
class_name Haltungsgegner
## Haltungsgegner – ein Wachroboter, der im Takt die Arme hebt und senkt.
##
## Er ist der einzige Gegner, bei dem die Antwort nicht am Modell abzulesen
## ist, sondern am AUGENBLICK. Steckbrief 4-5: "Man muss bei jedem Gegner
## erst lesen, in welchem Zustand er ist, bevor man reagiert."
##
##   ARME UNTEN   Die Schilde liegen vor den Läufen – unten ist zu.
##                Der Kopf steht frei: DRAUFSPRINGEN.
##   ARME OBEN    Die Schilde stehen als Stacheldach über dem Kopf – oben
##                ist zu. Die Läufe stehen frei: DURCHSLIDEN.
##
## ZEICHENSPRACHE (siehe gegner.gd). Es gibt genau EIN helles Zeichen, und
## es WANDERT: Die Wirkstelle leuchtet oben auf der Kronplatte, solange man
## springen muss, und unten an den Beinbändern, solange man sliden muss.
## Wer nur auf das Licht schaut, weiß schon, was zu tun ist – die Haltung
## der Arme sagt dasselbe noch einmal in der Silhouette, für den Fall, dass
## das Licht in einer hellen Kammer untergeht.
##
## Der Drehschlag wirkt NIE. Dafür steht der Klingenkranz an der Hüfte, auf
## Schlaghöhe, und er dreht sich nie weg: Was immer gilt, darf sich auch
## nie bewegen, sonst liest es niemand als Dauerzustand.
##
## VORWARNUNG. Ein Umschalten ohne Vorlauf wäre Glücksspiel: Wer eine
## Sekunde vor dem Wechsel zum Sprung ansetzt, käme genau im falschen
## Moment an. Darum läuft jede Haltung wie bei `Taktflaeche` in drei
## Teilen ab:
##
##   HALTEN   Haltung steht still, die Wirkstelle leuchtet ruhig.
##   WARNUNG  Die Wirkstelle BLINKT und wird dunkler, die kommende glimmt
##            schon an, die Brustlampe schlägt an, die Arme zittern.
##            Die Haltung gilt aber noch – man darf noch angreifen.
##   WECHSEL  Die Arme fahren hinüber. In dieser Zeit zählen BEIDE
##            Angriffsarten: Wer auf die Vorwarnung hin losgelaufen ist,
##            darf nicht daran scheitern, dass er einen Frame zu spät
##            ankommt. Das Fenster ist die Zusage des Bauteils.
##
## TAKTVERTRAG (doku/level-vorbilder.md): `takt` ist die Uhr des Gegners,
## erlaubt sind nur 1,0 · 2,0 · 4,0 Sekunden, Vorgabe 4,0. Ein voller
## Durchlauf enthält BEIDE Haltungen – bei 4,0 s steht jede zwei Sekunden.

enum Haltung {
	ARME_UNTEN,   ## unten zu, oben frei – draufspringen
	ARME_OBEN,    ## oben zu, unten frei – durchsliden
}

enum Lage {
	HALTEN,       ## Haltung steht
	WARNUNG,      ## Vorlauf, Haltung gilt noch
	WECHSEL,      ## Arme fahren, beide Angriffsarten zählen
}

## Erlaubte Werte für `takt` – der Taktvertrag lässt nur diese drei zu.
const TAKTE: Array[float] = [1.0, 2.0, 4.0]
## Blinkschläge je Sekunde in der Warnphase. Bewusst derselbe Wert wie bei
## `Taktflaeche`: Ein Level, in dem zwei Dinge warnen, soll mit EINEM
## Blinkmuster warnen, sonst lernt man zwei.
const WARN_PULS := 7.0
## Leuchtstärke einer aktiven Wirkstelle. Bewusst nicht höher: Mit
## eingeschaltetem Nachglühen brennt eine stärkere Emission zu Weiß aus,
## und dann ist das Zeichen zwar hell, aber farblos – es unterscheidet
## sich nicht mehr von jedem anderen Licht in der Station.
const WIRK_LEUCHTEN := 1.1
## So weit zittern die Arme in der Warnphase (Bogenmaß).
const ZITTERN := 0.055
## Taktrate des Schreitens.
const SCHRITT_TEMPO := 5.5

# ---------------------------------------------------------- Takt

## Länge eines vollen Durchlaufs in Sekunden – beide Haltungen zusammen.
##
## Der Setzer rastet auf den Taktvertrag ein, statt einen krummen Wert
## durchzulassen. Ein verschriebenes 3,0 fiele im Spiel nicht auf; es
## würde nur den Rhythmus des ganzen Abschnitts unlernbar machen, und
## genau das ist der Fehler, den der Vertrag verhindern soll.
@export var takt := 4.0:
	set(wert):
		var beste: float = TAKTE[0]
		for t in TAKTE:
			if absf(t - wert) < absf(beste - wert):
				beste = t
		takt = beste

## Dauer der Vorwarnung vor dem Wechsel.
@export var warnzeit := 0.7

## Dauer des Armschwenks.
@export var wechselzeit := 0.5

## Verschiebt den Takt gegenüber anderen Taktgebern, 0…1 = Anteil eines
## vollen Durchlaufs. Zwei Wachen mit 0,0 und 0,5 stehen immer gegenläufig:
## Solange die eine gesprungen werden will, will die andere geslidet werden.
@export var phase := 0.0

# ---------------------------------------------------------- Farben
#
# Wie bei den anderen Gegnern einzeln einstellbar, damit ein Level ihn in
# seine Palette holen kann. `farbe_klingen` und `farbe_chitin` heißen
# absichtlich wie bei Käfer und Krabbe: Ein Level setzt seine Ortsfarben
# einmal, und alle Gegner nehmen daran teil.
#
# Die Grundfläche heißt dagegen `farbe_rumpf` und NICHT `farbe_panzer`,
# obwohl sie dasselbe ist. Grund: `farbe_panzer` ist in den Leveln der
# helle Deckel der Krabbe, gegen den deren dunkle Naht steht. Hier ist es
# umgekehrt – der Rumpf ist das Dunkle, gegen das die Wirkstelle leuchtet.
# Beides aus einem Wert zu bedienen, hieße einen von beiden verlieren; in
# Level 20 stand die Wache damit messingfarben vor einer messingfarbenen
# Wand. `farbe_augen` fehlt ganz: Diese Wache hat keine leuchtenden Augen,
# siehe `farbe_visier`.
#
# ZEICHENSPRACHE: `farbe_wirkstelle` ist die Einladung und muss HELL
# bleiben, `farbe_klingen` die Dauerabsage an den Drehschlag und ebenso.
# Ein Schild im Ton der Wirkstelle nimmt dem Gegner seine ganze Aussage.

## Rumpf, Hüfte und Kopf – die dunkle Grundfläche. Sie muss dunkel
## BLEIBEN: Gegen sie steht die leuchtende Wirkstelle.
@export var farbe_rumpf: Color = Color(0.30, 0.33, 0.37):
	set(wert):
		farbe_rumpf = wert
		_neu_faerben()
## Gelenke, Läufe und Oberarme.
@export var farbe_chitin: Color = Color(0.20, 0.22, 0.25):
	set(wert):
		farbe_chitin = wert
		_neu_faerben()
## Die beiden Schilde an den Armen – die wandernde Absage.
@export var farbe_schild: Color = Color(0.52, 0.56, 0.61):
	set(wert):
		farbe_schild = wert
		_neu_faerben()
## Klingenkranz an der Hüfte und Schildstacheln. Hell halten.
@export var farbe_klingen: Color = Color(0.80, 0.84, 0.88):
	set(wert):
		farbe_klingen = wert
		_neu_faerben()
## Kronplatte und Beinbänder – die Wirkstelle. Hell halten.
@export var farbe_wirkstelle: Color = Color(0.30, 1.0, 0.55):
	set(wert):
		farbe_wirkstelle = wert
		_neu_faerben()
## Brustlampe der Vorwarnung. Sie soll NICHT die Farbe der Wirkstelle
## haben: "gleich passiert etwas" und "hier wirkt es" sind zwei Aussagen.
@export var farbe_warnung: Color = Farben.WARNUNG:
	set(wert):
		farbe_warnung = wert
		_neu_faerben()
## Das Sichtband am Kopf. Dunkel und glasig, ausdrücklich NICHT leuchtend:
## Am ganzen Roboter darf genau ein grünes Licht brennen, sonst weiß
## niemand mehr, welches davon die Wirkstelle ist.
@export var farbe_visier: Color = Color(0.10, 0.13, 0.18):
	set(wert):
		farbe_visier = wert
		_neu_faerben()


## Wie weit die Arme oben sind: 0 = unten, 1 = oben.
var _armwert := 0.0
var _haltung: int = Haltung.ARME_UNTEN
var _lage: int = Lage.HALTEN

var _schultern: Array[Node3D] = []
var _schulter_neigung: Array[float] = []
var _beine: Array[Node3D] = []
var _kronplatte: MeshInstance3D
var _beinbaender: Array[MeshInstance3D] = []
var _warnlampe: MeshInstance3D
# Eigene Kopien, weil sie im Takt ihre Farbe und Leuchtstärke ändern –
# die Materialien der `Materialbibliothek` sind geteilt.
var _stoff_oben: StandardMaterial3D
var _stoff_unten: StandardMaterial3D
var _stoff_warnung: StandardMaterial3D
var _zusammengesackt := false


func _init() -> void:
	# Startet mit gesenkten Armen: der Kopf ist frei, also draufspringen.
	besiegbar_durch = Angriff.FALLEN | Angriff.SLAM
	patrouille_weite = 3.5
	tempo = 1.5
	abprall_hoehe = 14.0
	fruechte = 2


func _ready() -> void:
	super._ready()
	# Ohne diesen Anstoß stünde der Gegner den ersten Frame lang in der
	# Vorgabehaltung, während der Takt schon woanders ist – bei einem
	# versetzten `phase` ein sichtbares Umspringen gleich beim Aufbau.
	_takt_rechnen()
	_bild_stellen()


# ---------------------------------------------------------- Optik

## Ein Wachroboter auf zwei Läufen: unten die Beinbänder, an der Hüfte der
## feste Klingenkranz, oben die Kronplatte, dazwischen zwei Schilde an
## langen Schultergelenken.
##
## Die Schilde hängen an EINEM Drehpunkt je Seite und fahren allein über
## dessen `rotation.x` von unten nach oben. Die Neigung nach innen steckt
## in `rotation.z` und bleibt dabei stehen: Godot dreht in der Reihenfolge
## Y-X-Z, das Z wirkt also VOR dem X. Dadurch beschreibt der Schild eine
## saubere Sichel von "vor den Läufen" nach "über dem Kopf", statt beim
## Hochfahren nach außen wegzukippen.
func _baue() -> void:
	var panzer := Materialbibliothek.einfarbig(farbe_rumpf, 0.42, 0.35)
	var chitin := Materialbibliothek.einfarbig(farbe_chitin, 0.55, 0.25)
	var schild := Materialbibliothek.einfarbig(farbe_schild, 0.38, 0.45)
	var klinge := Materialbibliothek.einfarbig(farbe_klingen, 0.25, 0.6)
	var visier := Materialbibliothek.einfarbig(farbe_visier, 0.12, 0.1)

	_stoff_oben = Materialbibliothek.leuchtend(
			farbe_wirkstelle, WIRK_LEUCHTEN).duplicate() as StandardMaterial3D
	_stoff_unten = Materialbibliothek.leuchtend(
			farbe_wirkstelle, WIRK_LEUCHTEN).duplicate() as StandardMaterial3D
	_stoff_warnung = Materialbibliothek.leuchtend(
			farbe_warnung, 0.0).duplicate() as StandardMaterial3D

	# --- Zwei Läufe. Sie sind das Slide-Ziel und dürfen deshalb nicht in
	#     der Silhouette verschwinden: schmal, dunkel, weit auseinander.
	for seite: float in [-1.0, 1.0]:
		var huefte := Node3D.new()
		huefte.name = "Beingelenk"
		huefte.position = Vector3(seite * 0.15, 0.50, 0.0)
		modell.add_child(huefte)
		_beine.append(huefte)
		_teil(huefte, _zylinder(0.075, 0.065, 0.42, 8), chitin,
				Vector3(0.0, -0.22, 0.0), Vector3.ZERO, Vector3.ONE, "Schenkel")
		_teil(huefte, _quader(Vector3(0.20, 0.10, 0.30)), panzer,
				Vector3(0.0, -0.45, -0.04), Vector3.ZERO, Vector3.ONE, "Fuss")
		# Das Beinband – die Wirkstelle für den Slide.
		var band := _teil(huefte, _zylinder(0.115, 0.115, 0.10, 10),
				_stoff_unten, Vector3(0.0, -0.26, 0.0), Vector3.ZERO,
				Vector3.ONE, "Beinband")
		_beinbaender.append(band)

	# --- Hüfte, Rumpf, Kopf ---
	_teil(modell, _quader(Vector3(0.40, 0.22, 0.28)), panzer,
			Vector3(0.0, 0.60, 0.0), Vector3.ZERO, Vector3.ONE, "Huefte")
	_teil(modell, _quader(Vector3(0.56, 0.44, 0.34)), panzer,
			Vector3(0.0, 0.96, 0.0), Vector3.ZERO, Vector3.ONE, "Rumpf")
	_teil(modell, _quader(Vector3(0.28, 0.24, 0.26)), panzer,
			Vector3(0.0, 1.31, 0.0), Vector3.ZERO, Vector3.ONE, "Kopf")
	# Ein glattes Sichtband statt Augen: Es fängt das Licht der Kammer und
	# sagt damit, wo vorn ist, ohne selbst zu leuchten.
	_teil(modell, _quader(Vector3(0.22, 0.07, 0.03)), visier,
			Vector3(0.0, 1.34, -0.145), Vector3.ZERO, Vector3.ONE, "Visier")

	# Brustlampe der Vorwarnung – sie sitzt vorn, weil man den Gegner
	# entgegenkommen sieht und nicht von hinten.
	_warnlampe = _teil(modell, _kugel(0.065, 10, 8), _stoff_warnung,
			Vector3(0.0, 1.02, -0.18), Vector3.ZERO, Vector3.ONE, "Warnlampe")

	# Kronplatte – die Wirkstelle fürs Draufspringen. Flach und breit:
	# Von der Spielkamera aus schräg oben ist sie die größte Fläche, die
	# der Gegner zeigt.
	_kronplatte = _teil(modell, _quader(Vector3(0.36, 0.08, 0.34)),
			_stoff_oben, Vector3(0.0, 1.47, 0.0), Vector3.ZERO,
			Vector3.ONE, "Kronplatte")

	# --- Klingenkranz an der Hüfte: die Dauerabsage an den Drehschlag ---
	# Wie bei der Gletscherkrabbe über je einen Drehpunkt statt über
	# Eulerwinkel – zwei Winkel gleichzeitig ergeben keinen Kranz.
	for i in 10:
		var dreh := Node3D.new()
		dreh.name = "Klingenpunkt"
		dreh.rotation.y = (float(i) / 10.0) * TAU
		modell.add_child(dreh)
		_teil(dreh, _zylinder(0.07, 0.004, 0.26, 5), klinge,
				Vector3(0.0, 0.76, 0.20), Vector3(-84.0, 0.0, 0.0),
				Vector3.ONE, "Klinge")

	# --- Die beiden Schilde an ihren Schultergelenken ---
	for seite: float in [-1.0, 1.0]:
		var schulter := Node3D.new()
		schulter.name = "Schulter"
		# Der Zapfen sitzt ein Stück VOR dem Rumpf. Der Schild schwenkt um
		# die X-Achse dieses Punktes, seine Tiefe bleibt dabei stehen – so
		# steht er unten vor den Läufen und oben vor dem Kopf und wandert
		# nicht beim Hochfahren hinter die Figur.
		schulter.position = Vector3(seite * 0.31, 1.13, -0.10)
		# Nach innen geneigt, damit die Schilde unten VOR den Läufen und
		# oben ÜBER dem Kopf zusammengehen. Ohne die Neigung stünden sie
		# neben dem Gegner und deckten gar nichts ab.
		schulter.rotation.z = -seite * 0.26
		modell.add_child(schulter)
		_schultern.append(schulter)
		_schulter_neigung.append(schulter.rotation.z)

		_teil(schulter, _zylinder(0.065, 0.055, 0.28, 8), chitin,
				Vector3(0.0, -0.14, 0.0), Vector3.ZERO, Vector3.ONE, "Oberarm")
		_teil(schulter, _quader(Vector3(0.42, 0.50, 0.10)), schild,
				Vector3(0.0, -0.52, 0.0), Vector3.ZERO, Vector3.ONE, "Schild")
		# Stacheln an der Schildkante – sie zeigen immer dorthin, wo der
		# Schild gerade zumacht: unten zum Boden, oben in den Himmel.
		for i in 3:
			_teil(schulter, _zylinder(0.048, 0.0, 0.18, 5), klinge,
					Vector3((float(i) - 1.0) * 0.13, -0.86, 0.0),
					Vector3(180.0, 0.0, 0.0), Vector3.ONE, "Stachel%d" % i)


# ---------------------------------------------------------- Takt

## Bestimmt Haltung und Lage aus der Uhr und setzt `besiegbar_durch`.
##
## Ein voller Durchlauf enthält beide Haltungen, jede also eine halbe
## Runde. Warn- und Wechselzeit sind darin gedeckelt: Bei `takt` 1,0 wäre
## eine halbe Runde 0,5 s, und die absoluten 0,7 s Vorwarnung fräßen die
## Haltung ganz auf – dann stünde der Gegner nie still und wäre nicht mehr
## zu lesen. Lieber ein kurzer Vorlauf als gar keine Haltung.
func _takt_rechnen() -> void:
	var runde := maxf(takt, 0.5)
	var halb := runde * 0.5
	var wechsel := clampf(wechselzeit, 0.05, halb * 0.34)
	var warn := clampf(warnzeit, 0.05, halb * 0.40)
	var halten := halb - warn - wechsel

	var p := fposmod(_zeit + phase * runde, runde)
	_haltung = Haltung.ARME_UNTEN if p < halb else Haltung.ARME_OBEN
	var im_halb := p - (0.0 if p < halb else halb)

	var ziel := 0.0 if _haltung == Haltung.ARME_UNTEN else 1.0
	if im_halb < halten:
		_lage = Lage.HALTEN
		_armwert = ziel
	elif im_halb < halten + warn:
		_lage = Lage.WARNUNG
		_armwert = ziel
	else:
		_lage = Lage.WECHSEL
		# Weich ein und aus: Ein linearer Schwenk sieht aus, als würde der
		# Arm geworfen; die S-Kurve sieht nach Maschine aus.
		var t := (im_halb - halten - warn) / maxf(wechsel, 0.01)
		_armwert = lerpf(ziel, 1.0 - ziel, smoothstep(0.0, 1.0, t))

	if _lage == Lage.WECHSEL:
		# Im Schwenk zählt beides – siehe Kopfkommentar.
		besiegbar_durch = Angriff.FALLEN | Angriff.SLIDE | Angriff.SLAM
	elif _haltung == Haltung.ARME_UNTEN:
		besiegbar_durch = Angriff.FALLEN | Angriff.SLAM
	else:
		besiegbar_durch = Angriff.SLIDE | Angriff.SLAM


## Setzt Arme, Wirkstellen und Warnlampe auf die errechnete Lage.
func _bild_stellen() -> void:
	var puls := 0.0
	if _lage == Lage.WARNUNG:
		puls = 0.5 + 0.5 * sin(_zeit * TAU * WARN_PULS)

	for i in _schultern.size():
		var schulter := _schultern[i]
		if not is_instance_valid(schulter):
			continue
		schulter.rotation.x = _armwert * PI
		# Zittern in der Warnphase: Farbe allein geht in einer hellen
		# Kammer unter, Bewegung fängt den Blick auch am Bildrand.
		schulter.rotation.z = _schulter_neigung[i] + puls * ZITTERN

	# Oben leuchtet, solange die Arme unten sind – und umgekehrt. In der
	# Warnphase blinkt die noch gültige Stelle aus und die kommende an:
	# Damit ist nicht nur zu sehen, DASS gleich gewechselt wird, sondern
	# auch, WOHIN.
	var oben := (1.0 - _armwert) * (1.0 - 0.75 * puls * (1.0 - _armwert))
	var unten := _armwert * (1.0 - 0.75 * puls * _armwert)
	if _lage == Lage.WARNUNG:
		oben += puls * 0.45 * _armwert
		unten += puls * 0.45 * (1.0 - _armwert)
	_wirkstelle_stellen(_stoff_oben, oben)
	_wirkstelle_stellen(_stoff_unten, unten)

	if _stoff_warnung != null:
		var an := puls if _lage == Lage.WARNUNG else 0.0
		_stoff_warnung.emission_energy_multiplier = an * 2.4
		_stoff_warnung.albedo_color = farbe_warnung.darkened(0.75).lerp(
				farbe_warnung, an)


## Eine Wirkstelle auf `anteil` stellen: 0 = tot und dunkel, 1 = Einladung.
## Die Albedofarbe wandert mit, nicht nur das Leuchten – eine erloschene
## Stelle, die weiter in ihrer hellen Farbe dasteht, sagt immer noch
## "hier".
func _wirkstelle_stellen(stoff: StandardMaterial3D, anteil: float) -> void:
	if stoff == null:
		return
	var a := clampf(anteil, 0.0, 1.0)
	stoff.albedo_color = farbe_wirkstelle.darkened(0.72).lerp(farbe_wirkstelle, a)
	stoff.emission = farbe_wirkstelle
	stoff.emission_energy_multiplier = a * WIRK_LEUCHTEN


# ---------------------------------------------------------- Bewegung

func _bewegung(delta: float) -> void:
	_takt_rechnen()
	_bild_stellen()

	_phase += delta * tempo * SCHRITT_TEMPO
	_patrouille_schritt(tempo * delta)
	_blick_ausrichten(delta, 7.0)

	# Schwerer Zweibeinergang: die Läufe schwingen gegenphasig, der ganze
	# Roboter wiegt sich im Schritt.
	for i in _beine.size():
		var bein := _beine[i]
		if is_instance_valid(bein):
			bein.rotation.x = sin(_phase + PI * float(i)) * 0.34
	if is_instance_valid(modell):
		modell.position.y = absf(sin(_phase)) * 0.035


# ---------------------------------------------------------- Tod

func _todesstart(art: int) -> void:
	# Wer von oben kommt, tritt ihn zusammen; der Slide fegt ihn weg.
	# Zwei Angriffsarten, zwei Tode – sonst sähe der Treffer immer gleich
	# aus, obwohl der Spieler zwei verschiedene Fragen beantwortet hat.
	_zusammengesackt = (art & (Angriff.FALLEN | Angriff.SLAM)) != 0
	if _zusammengesackt:
		_wegflug = Vector3.ZERO


func _todesanimation(delta: float) -> void:
	if not _zusammengesackt:
		super._todesanimation(delta)
		return
	if is_instance_valid(modell):
		modell.scale = modell.scale.lerp(Vector3(1.25, 0.09, 1.15),
				minf(delta * 11.0, 1.0))
	for schulter in _schultern:
		if is_instance_valid(schulter):
			schulter.rotation.x = sin(_zeit * 22.0) * 0.7


# ---------------------------------------------------------- Umfärben

## Baut die Optik neu auf, wenn eine Farbe nach dem Einhängen gesetzt wird.
##
## Nötig, weil die Meshes samt Material in `_baue()` entstehen, und das
## läuft in `_ready()`. Ein Level, das die Wache erst aufstellt und dann
## einfärbt, träfe sonst nur noch die Variable. Wie bei Käfer und Krabbe.
##
## Ein besiegter Gegner wird nicht angefasst: Seine Todesanimation steckt
## in Skalierung und Drehung des Modells, ein Neubau setzte sie zurück.
func _neu_faerben() -> void:
	if besiegt or not is_inside_tree() or not is_instance_valid(modell):
		return
	for kind in modell.get_children():
		modell.remove_child(kind)
		kind.queue_free()
	_schultern.clear()
	_schulter_neigung.clear()
	_beine.clear()
	_beinbaender.clear()
	_kronplatte = null
	_warnlampe = null
	_baue()
	_fremdmodell_setzen()
	_bild_stellen()
