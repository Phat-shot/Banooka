extends Node
## Tonsystem: erzeugt alle Klänge im Code und spielt sie ab.
## Als Autoload unter dem Namen "Klang" registriert.
##
## Warum berechnet und nicht geladen: Das Projekt kommt bewusst ohne
## fremde Dateien aus (siehe assets/CREDITS.md). Es gibt hier also keine
## .wav- oder .ogg-Dateien, sondern nur Sinus-, Dreieck-, Rechteck- und
## Rauschbausteine, aus denen jeder Klang zusammengemischt wird.
##
## Aufruf von überall her:
##     Klang.spiele("sprung")
##     Klang.spiele("frucht", 1.2)        # eine Sekunde höher gestimmt
##     Klang.spiele_folge("frucht")       # Kette, klettert in der Tonhöhe
##
## Alle Klänge entstehen EINMAL beim Start und liegen danach als fertige
## AudioStreamWAV bereit. Neu zu rechnen wäre pro Abspielen ein paar
## tausend Sinus-Aufrufe – mitten im Spiel, im selben Bild, in dem der
## Spieler springt. Genau dort darf nichts stocken, und der Speicher für
## alle Klänge zusammen liegt deutlich unter 100 kB.

signal lautstaerke_geaendert(wert: float)

## Abtastrate. 22 kHz reicht für kurze Spielgeräusche vollkommen und
## halbiert Rechenzeit wie Speicher gegenüber 44,1 kHz.
const ABTASTRATE := 22050
## So viele Klänge können gleichzeitig laufen.
const STIMMEN := 12
## Mindestabstand zwischen zwei gleichen Klängen. Ein Drehschlag trifft
## fünf Kisten im selben Bild – ohne diese Sperre lägen fünf identische
## Klänge exakt übereinander, und das ist nicht fünfmal so schön,
## sondern nur fünfmal so laut.
const MINDESTABSTAND := 0.05
const SPEICHERPFAD := "user://klang.cfg"
## Die Mühle (`_bau_muehle`): Länge der Schleife, Takt der Schaufeln (vier je
## Schleife), Überblendung von Ende zu Anfang und der eigene Startwert.
const MUEHLE_LAENGE := 1.92
const MUEHLE_TAKT := 0.48
const MUEHLE_UEBERBLENDUNG := 0.12
const MUEHLE_SAAT := 5291
## Schleifen: Sie entstehen nicht beim Start, sondern beim ersten Abholen
## (`strom`) – die Mühle braucht nur Level 05, und gebaut kostet sie beim
## Programmstart rund 35–50 ms (gemessen, Rechner; auf dem Handy das
## Mehrfache). Level 05 holt sie beim Laden, unter dem Ladeschirm. Ebenso
## der Galopp des Keilers („keiler_lauf", `_bau_galopp`).
const SCHLEIFEN: Array[String] = ["muehle", "keiler_lauf"]
## Einzelklänge, die ebenfalls erst beim ersten `strom()` entstehen: der
## Keiler aus Level 05 (Spiel-Jury L05 R1, Mangel 4 – bis dahin war der
## Verfolger stumm). Level 05 holt sie beim Laden ab (`L05Jagd.anlegen`).
const ABRUF: Array[String] = ["keiler_wecken", "keiler_bruch", "keiler_schnauben"]
## Eigener Startwert der Keilerklänge (wie MUEHLE_SAAT): `_zufall` und
## damit alle übrigen Klänge bleiben unberührt.
const KEILER_SAAT := 7717
## Galopp: ein Sprung dauert 1 / `Keiler.TAKT` (2,2 je Sekunde), die
## Schleife hält vier; die Hufe eines Sprungs schlagen zu diesen Anteilen.
const GALOPP_SPRUNG := 1.0 / 2.2
const GALOPP_SPRUENGE := 4
const GALOPP_HUFE: Array[float] = [0.0, 0.15, 0.42, 0.55]

## Wellenformen der Tonbausteine.
enum Welle { SINUS, DREIECK, RECHTECK }

## Gesamtlautstärke, 0.0 bis 1.0.
var lautstaerke := 0.8:
	set(wert):
		lautstaerke = clampf(wert, 0.0, 1.0)
		lautstaerke_geaendert.emit(lautstaerke)
## Ton ganz aus, ohne die eingestellte Lautstärke zu vergessen.
var stumm := false:
	set(an):
		stumm = an
		lautstaerke_geaendert.emit(lautstaerke)

## name -> AudioStreamWAV
var _kloenge: Dictionary = {}
## name -> eigener Mindestabstand in Sekunden
var _abstaende: Dictionary = {}
## name -> Zeitpunkt des letzten Abspielens
var _zuletzt: Dictionary = {}
var _stimmen: Array[AudioStreamPlayer] = []
var _naechste := 0

## Stand der Tonhöhenkette (siehe `spiele_folge`).
var _folge_name := ""
var _folge_stufe := 0
var _folge_zeit := -99.0

## Darf überhaupt geklungen werden?
##
## Browser starten die Tonausgabe erst nach einer Nutzeraktion (Klick,
## Tastendruck, Antippen). Vorher abgespielte Klänge verschwinden nicht
## nur ungehört, sie hinterlassen je nach Browser auch Meldungen in der
## Konsole. Im Web bleibt das Tonsystem deshalb bis zur ersten Eingabe
## still und schaltet sich in `_input` frei – auf allen anderen
## Plattformen ist es von Anfang an offen.
var _freigegeben := true

## Fester Startwert für das Rauschen. So klingt jeder Start gleich und
## das Prüfwerkzeug misst bei jedem Lauf dieselben Spitzenpegel.
var _zufall := RandomNumberGenerator.new()


func _ready() -> void:
	# Klänge sollen auch im Pausenmenü und über Szenenwechsel hinweg
	# ausklingen dürfen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_freigegeben = not OS.has_feature("web")
	_laden()
	_baue_stimmen()
	_baue_kloenge()


func _input(event: InputEvent) -> void:
	if _freigegeben:
		return
	# Erst eine echte Nutzeraktion gibt die Tonausgabe im Browser frei.
	if event is InputEventKey or event is InputEventMouseButton \
			or event is InputEventScreenTouch or event is InputEventJoypadButton:
		if event.is_pressed():
			_freigegeben = true


# ---------------------------------------------------------- Schnittstelle

## Spielt einen Klang. `tonhoehe` 1.0 = wie berechnet, 2.0 = eine Oktave
## höher. `staerke` dämpft diesen einen Klang zusätzlich (0.0 bis 1.0).
func spiele(name: String, tonhoehe: float = 1.0, staerke: float = 1.0) -> void:
	if stumm or lautstaerke <= 0.001 or not _freigegeben:
		return
	var strom_ := strom(name)
	if strom_ == null:
		push_warning("Klang unbekannt: %s" % name)
		return
	# Schleifen (die Mühle) laufen nicht über die Stimmen: Eine Stimme bliebe
	# sonst für immer belegt. Wer eine Schleife will, holt sie mit `strom()`
	# und spielt sie selbst, mit `schleifen_pegel()` (Level 05: L05Stimmung).
	if strom_.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return

	var jetzt := Time.get_ticks_msec() / 1000.0
	var abstand := float(_abstaende.get(name, MINDESTABSTAND))
	if jetzt - float(_zuletzt.get(name, -99.0)) < abstand:
		return
	_zuletzt[name] = jetzt

	var stimme := _freie_stimme()
	stimme.stream = strom_
	stimme.pitch_scale = clampf(tonhoehe, 0.25, 4.0)
	stimme.volume_db = linear_to_db(clampf(lautstaerke * staerke, 0.0005, 1.0))
	stimme.play()


## Klang einer Kette: Wer mehrere Früchte hintereinander einsammelt, hört
## eine Tonleiter statt elfmal denselben Ton. Nach `pause` Sekunden ohne
## Nachschub fängt die Leiter wieder unten an.
func spiele_folge(name: String, schritt: float = 0.055, stufen: int = 10,
		pause: float = 0.7) -> void:
	var jetzt := Time.get_ticks_msec() / 1000.0
	if name != _folge_name or jetzt - _folge_zeit > pause:
		_folge_stufe = 0
	else:
		_folge_stufe = mini(_folge_stufe + 1, maxi(stufen - 1, 0))
	_folge_name = name
	_folge_zeit = jetzt
	spiele(name, 1.0 + float(_folge_stufe) * schritt)


## Lautstärke setzen und dauerhaft merken.
##
## Der passendere Ort wäre `autoload/Einstellungen.gd`, wo schon alle
## anderen dauerhaften Einstellungen liegen – die Datei gehört mir aber
## nicht. Bis dahin liegt die Lautstärke in einer eigenen kleinen Datei.
func setze_lautstaerke(wert: float) -> void:
	lautstaerke = wert
	speichern()


func stumm_schalten(an: bool) -> void:
	stumm = an
	speichern()


## Namen aller Klänge (für Prüfwerkzeuge und eine spätere Tonoptionsseite),
## auch der Schleifen, die erst beim ersten `strom()` entstehen.
func namen() -> PackedStringArray:
	var liste := PackedStringArray(_kloenge.keys())
	for name: String in SCHLEIFEN + ABRUF:
		if not liste.has(name):
			liste.append(name)
	liste.sort()
	return liste


## Der fertige Klang zu einem Namen, oder null. Eine Schleife (SCHLEIFEN)
## und ein Klang aus ABRUF entstehen hier beim ersten Abholen.
func strom(name: String) -> AudioStreamWAV:
	if not _kloenge.has(name) and (SCHLEIFEN.has(name) or ABRUF.has(name)):
		_schleifen_bauen(name)
	return _kloenge.get(name) as AudioStreamWAV


## Linearer Pegel für eine Schleife, die der Aufrufer selbst abspielt
## (eigener AudioStreamPlayer, siehe `spiele`): Gesamtlautstärke mal
## `staerke`, 0 bei stummem Ton und im Browser vor der ersten Eingabe.
func schleifen_pegel(staerke: float) -> float:
	if stumm or not _freigegeben:
		return 0.0
	return clampf(lautstaerke * staerke, 0.0, 1.0)


# ---------------------------------------------------------- Spielstand

func speichern() -> void:
	var datei := ConfigFile.new()
	datei.set_value("ton", "lautstaerke", lautstaerke)
	datei.set_value("ton", "stumm", stumm)
	datei.save(SPEICHERPFAD)


func _laden() -> void:
	var datei := ConfigFile.new()
	if datei.load(SPEICHERPFAD) != OK:
		return
	lautstaerke = float(datei.get_value("ton", "lautstaerke", 0.8))
	stumm = bool(datei.get_value("ton", "stumm", false))


# ---------------------------------------------------------- Stimmen

func _baue_stimmen() -> void:
	for i in STIMMEN:
		var spieler := AudioStreamPlayer.new()
		spieler.name = "Stimme%d" % i
		spieler.bus = "Master"
		spieler.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(spieler)
		_stimmen.append(spieler)


## Reihum die nächste Stimme, bevorzugt eine gerade freie. Ist alles
## belegt, wird die älteste überschrieben – ein abgeschnittener Klang ist
## besser als ein verschluckter.
func _freie_stimme() -> AudioStreamPlayer:
	for i in _stimmen.size():
		var kandidat := _stimmen[(_naechste + i) % _stimmen.size()]
		if not kandidat.playing:
			_naechste = (_naechste + i + 1) % _stimmen.size()
			return kandidat
	var stimme := _stimmen[_naechste]
	_naechste = (_naechste + 1) % _stimmen.size()
	return stimme


# ---------------------------------------------------------- Klangbau

## Baut alle Klänge einmal auf. Zusammen sind das rund 100 000 Abtastwerte –
## im Millisekundenbereich, einmalig beim Programmstart.
func _baue_kloenge() -> void:
	_zufall.seed = 20260825

	_kloenge["sprung"] = _fertig(_bau_sprung(), 0.45)
	_kloenge["doppelsprung"] = _fertig(_bau_doppelsprung(), 0.45)
	_kloenge["landung"] = _fertig(_bau_landung(), 0.35)
	_kloenge["slide"] = _fertig(_bau_slide(), 0.30)
	_kloenge["drehschlag"] = _fertig(_bau_drehschlag(), 0.40)
	_kloenge["aufschlag"] = _fertig(_bau_aufschlag(), 0.70)
	_kloenge["abprall"] = _fertig(_bau_abprall(), 0.50)
	_kloenge["kiste"] = _fertig(_bau_kiste(), 0.65)
	_kloenge["explosion"] = _fertig(_bau_explosion(), 0.85)
	_kloenge["frucht"] = _fertig(_bau_frucht(), 0.45)
	_kloenge["gegner"] = _fertig(_bau_gegner(), 0.55)
	_kloenge["schaden"] = _fertig(_bau_schaden(), 0.60)
	_kloenge["tod"] = _fertig(_bau_tod(), 0.70)
	_kloenge["checkpoint"] = _fertig(_bau_checkpoint(), 0.60)
	_kloenge["portal"] = _fertig(_bau_portal(), 0.60)
	# Menüklänge leiser als alles im Spiel: Sie kommen bei jedem Tastendruck
	# und sollen bestätigen, nicht auffallen.
	_kloenge["menue_wahl"] = _fertig(_bau_menue_wahl(), 0.16)
	_kloenge["menue_ok"] = _fertig(_bau_menue_ok(), 0.32)

	# Abweichende Sperrzeiten: Landungen sollen nicht klappern, Früchte
	# dürfen schnell perlen, Explosionen reißen Nachbarkisten mit.
	_abstaende["landung"] = 0.14
	_abstaende["frucht"] = 0.03
	_abstaende["kiste"] = 0.06
	_abstaende["explosion"] = 0.09
	_abstaende["gegner"] = 0.06
	# Wer die Pfeiltaste gedrückt hält, hört jeden Schritt.
	_abstaende["menue_wahl"] = 0.03


## Kurzer Aufwärtsschwung – hell, aber nicht schrill.
func _bau_sprung() -> PackedFloat32Array:
	var p := _puffer(0.17)
	_ton(p, 0.0, 0.15, 440.0, 880.0, 0.9, Welle.DREIECK, 0.005, 2.0)
	_ton(p, 0.0, 0.09, 880.0, 1600.0, 0.22, Welle.SINUS, 0.004, 3.0)
	return p


## Zweiter Sprung: dasselbe eine Quinte höher, mit etwas Glitzer obendrauf.
func _bau_doppelsprung() -> PackedFloat32Array:
	var p := _puffer(0.20)
	_ton(p, 0.0, 0.17, 660.0, 1320.0, 0.85, Welle.DREIECK, 0.004, 2.0)
	_ton(p, 0.035, 0.13, 1320.0, 2100.0, 0.28, Welle.SINUS, 0.004, 2.5)
	return p


## Aufsetzen: dumpfer Plopp mit einem Hauch Staub.
func _bau_landung() -> PackedFloat32Array:
	var p := _puffer(0.13)
	_ton(p, 0.0, 0.10, 220.0, 80.0, 0.9, Welle.SINUS, 0.002, 3.0)
	_rauschen(p, 0.0, 0.07, 0.5, 2600.0, 700.0, 250.0, 0.002, 3.0)
	return p


## Rutschen: schmales Zischen, so lang wie SLIDE_TIME.
func _bau_slide() -> PackedFloat32Array:
	var p := _puffer(0.44)
	_rauschen(p, 0.0, 0.42, 1.0, 1400.0, 3400.0, 600.0, 0.06, 1.6)
	return p


## Drehschlag: ein Wusch, dessen Klangfarbe mit der Drehung aufsteigt.
func _bau_drehschlag() -> PackedFloat32Array:
	var p := _puffer(0.30)
	_rauschen(p, 0.0, 0.28, 1.0, 700.0, 5000.0, 400.0, 0.10, 1.4)
	_ton(p, 0.0, 0.26, 300.0, 700.0, 0.26, Welle.DREIECK, 0.03, 1.5)
	return p


## Bauchplatscher: tiefer Aufschlag mit Schockwelle.
func _bau_aufschlag() -> PackedFloat32Array:
	var p := _puffer(0.30)
	_ton(p, 0.0, 0.26, 190.0, 45.0, 1.0, Welle.SINUS, 0.002, 2.5)
	_rauschen(p, 0.0, 0.12, 0.6, 4000.0, 500.0, 150.0, 0.001, 3.0)
	return p


## Abprallen von Feder, Sprungfeder oder Gegnerkopf: ein Boing.
func _bau_abprall() -> PackedFloat32Array:
	var p := _puffer(0.24)
	_ton(p, 0.0, 0.22, 260.0, 1100.0, 0.9, Welle.DREIECK, 0.004, 1.6)
	_ton(p, 0.02, 0.14, 520.0, 1400.0, 0.25, Welle.SINUS, 0.004, 2.0)
	return p


## Kiste zerbricht: vier Holzknackser über einem kurzen Bumms.
func _bau_kiste() -> PackedFloat32Array:
	var p := _puffer(0.28)
	_rauschen(p, 0.0, 0.05, 0.9, 6000.0, 2000.0, 800.0, 0.001, 3.0)
	for i in 4:
		var start := 0.012 + float(i) * 0.034
		_ton(p, start, 0.022, 900.0 - float(i) * 160.0, 400.0, 0.5,
				Welle.DREIECK, 0.001, 4.0)
	_ton(p, 0.0, 0.16, 200.0, 70.0, 0.45, Welle.SINUS, 0.002, 3.0)
	_rauschen(p, 0.02, 0.20, 0.35, 3000.0, 900.0, 600.0, 0.01, 2.0)
	return p


## TNT und Nitro: satter Knall, immer noch ohne Schrecken.
func _bau_explosion() -> PackedFloat32Array:
	var p := _puffer(0.50)
	_ton(p, 0.0, 0.45, 140.0, 35.0, 1.0, Welle.SINUS, 0.002, 2.0)
	_rauschen(p, 0.0, 0.40, 0.9, 5000.0, 300.0, 120.0, 0.003, 2.0)
	return p


## Frucht: zwei helle Glöckchen, A5 und E6 – eine Quinte aufwärts.
func _bau_frucht() -> PackedFloat32Array:
	var p := _puffer(0.26)
	_ton(p, 0.0, 0.12, 880.0, 880.0, 0.7, Welle.SINUS, 0.004, 3.0)
	_ton(p, 0.0, 0.10, 1760.0, 1760.0, 0.18, Welle.SINUS, 0.004, 3.5)
	_ton(p, 0.07, 0.18, 1318.5, 1318.5, 0.7, Welle.SINUS, 0.004, 3.0)
	_ton(p, 0.07, 0.13, 2637.0, 2637.0, 0.16, Welle.SINUS, 0.004, 3.5)
	return p


## Gegner besiegt: ein kurzes komisches "Bopp", kein Schmerzenslaut.
func _bau_gegner() -> PackedFloat32Array:
	var p := _puffer(0.25)
	_ton(p, 0.0, 0.10, 500.0, 900.0, 0.6, Welle.RECHTECK, 0.003, 2.0)
	_ton(p, 0.085, 0.15, 900.0, 260.0, 0.7, Welle.DREIECK, 0.003, 2.0)
	_rauschen(p, 0.0, 0.06, 0.35, 3000.0, 1000.0, 400.0, 0.001, 3.0)
	return p


## Treffer einstecken: absteigend, aber weich – der Schutz hält ja oft.
func _bau_schaden() -> PackedFloat32Array:
	var p := _puffer(0.30)
	_ton(p, 0.0, 0.28, 620.0, 200.0, 0.9, Welle.DREIECK, 0.004, 1.8)
	_ton(p, 0.0, 0.12, 310.0, 150.0, 0.32, Welle.SINUS, 0.004, 2.5)
	return p


## Tod: vier absteigende Töne (G5–E5–C5–G4) und ein weicher Schlusston.
func _bau_tod() -> PackedFloat32Array:
	var p := _puffer(0.62)
	var toene := [784.0, 659.3, 523.3, 392.0]
	for i in toene.size():
		_ton(p, float(i) * 0.115, 0.17, toene[i], toene[i], 0.8,
				Welle.DREIECK, 0.005, 2.5)
	_ton(p, 0.44, 0.17, 196.0, 150.0, 0.45, Welle.SINUS, 0.008, 2.0)
	return p


## Checkpoint: aufsteigender Dur-Dreiklang mit ausgehaltener Oktave.
func _bau_checkpoint() -> PackedFloat32Array:
	var p := _puffer(0.52)
	var toene := [523.3, 659.3, 784.0]
	for i in toene.size():
		_ton(p, float(i) * 0.085, 0.20, toene[i], toene[i], 0.6,
				Welle.SINUS, 0.005, 2.5)
	_ton(p, 0.255, 0.26, 1046.5, 1046.5, 0.8, Welle.SINUS, 0.006, 2.0)
	_ton(p, 0.255, 0.20, 2093.0, 2093.0, 0.18, Welle.SINUS, 0.006, 3.0)
	return p


## Portal: ein Sog, der über zwei Oktaven aufsteigt und anschwillt statt
## anzuschlagen, darüber ein Luftzug und am Ende helles Glitzern in einer
## Dur-Folge. So lang wie das Einsaugen am Tor (0,6 s) plus Nachklang.
func _bau_portal() -> PackedFloat32Array:
	var p := _puffer(0.82)
	_ton(p, 0.0, 0.64, 196.0, 784.0, 0.75, Welle.DREIECK, 0.40, 1.3)
	_ton(p, 0.0, 0.64, 392.0, 1568.0, 0.22, Welle.SINUS, 0.40, 1.5)
	_rauschen(p, 0.0, 0.62, 0.40, 500.0, 5200.0, 300.0, 0.36, 1.6)
	var glitzer := [1318.5, 1568.0, 2093.0, 2637.0, 3136.0]
	for i in glitzer.size():
		_ton(p, 0.30 + float(i) * 0.07, 0.24, glitzer[i], glitzer[i], 0.26,
				Welle.SINUS, 0.004, 3.0)
	return p


## Menü, Auswahl gewechselt: ein weiches, kurzes Ticken um 1,8 kHz.
func _bau_menue_wahl() -> PackedFloat32Array:
	var p := _puffer(0.045)
	_ton(p, 0.0, 0.04, 1800.0, 1650.0, 1.0, Welle.SINUS, 0.002, 3.5)
	_ton(p, 0.0, 0.02, 3600.0, 3300.0, 0.12, Welle.SINUS, 0.001, 4.0)
	return p


## Baut eine Schleife aus SCHLEIFEN oder einen Klang aus ABRUF (siehe
## `strom`).
func _schleifen_bauen(name: String) -> void:
	match name:
		"muehle":
			_kloenge["muehle"] = _schleife(_bau_muehle(), 0.5, MUEHLE_LAENGE)
		"keiler_lauf":
			_kloenge["keiler_lauf"] = _keiler_klang(_bau_galopp, 0.55,
					GALOPP_SPRUNG * float(GALOPP_SPRUENGE))
		"keiler_wecken":
			_kloenge["keiler_wecken"] = _keiler_klang(_bau_keiler_wecken, 0.7)
		"keiler_bruch":
			_kloenge["keiler_bruch"] = _keiler_klang(_bau_keiler_bruch, 0.75)
		"keiler_schnauben":
			_kloenge["keiler_schnauben"] = _keiler_klang(_bau_keiler_schnauben, 0.6)


## Ein Keilerklang aus seinem eigenen Zufall (KEILER_SAAT): `bauer` füllt
## den Puffer, `pegel` wie bei `_fertig`; mit `schleife` > 0 eine Schleife
## dieser Länge (`_schleife_gefaltet`).
func _keiler_klang(bauer: Callable, pegel: float, schleife: float = 0.0) -> AudioStreamWAV:
	var gemeinsam := _zufall
	_zufall = RandomNumberGenerator.new()
	_zufall.seed = KEILER_SAAT
	var p: PackedFloat32Array = bauer.call()
	_zufall = gemeinsam
	if schleife > 0.0:
		return _schleife_gefaltet(p, pegel, schleife)
	return _fertig(p, pegel)


## Wecken (Entwurf L05 §0: „knackt ein Ast"): ein trockener Ast bricht –
## zwei Knacke und ein Splittern –, dann fährt der Keiler mit einem rauen
## Grunzen hoch, das in ein Quieken kippt, zuletzt ein Schnauben.
func _bau_keiler_wecken() -> PackedFloat32Array:
	var p := _puffer(1.1)
	_rauschen(p, 0.0, 0.03, 1.0, 7000.0, 3000.0, 1500.0, 0.001, 3.0)
	_ton(p, 0.0, 0.06, 320.0, 180.0, 0.35, Welle.SINUS, 0.001, 3.0)
	_rauschen(p, 0.04, 0.05, 0.8, 6000.0, 2500.0, 1500.0, 0.001, 3.0)
	for k in 4:
		var t := 0.09 + float(k) * 0.03 + _zufall.randf_range(0.0, 0.015)
		_rauschen(p, t, 0.02, 0.35, 5000.0, 3000.0, 1800.0, 0.001, 3.0)
	_ton(p, 0.28, 0.42, 105.0, 150.0, 0.5, Welle.RECHTECK, 0.03, 1.2)
	_ton(p, 0.28, 0.42, 210.0, 420.0, 0.22, Welle.DREIECK, 0.05, 1.4)
	_rauschen(p, 0.28, 0.42, 0.35, 900.0, 600.0, 150.0, 0.03, 1.3)
	_rauschen(p, 0.76, 0.26, 0.8, 2200.0, 600.0, 300.0, 0.01, 2.0)
	return p


## Durchbruch: Holz splittert (ein Krachen, dann Splitter), dumpfer Stoß
## des Schädels, Grollen, ein paar fallende Stücke.
func _bau_keiler_bruch() -> PackedFloat32Array:
	var p := _puffer(0.75)
	_rauschen(p, 0.0, 0.06, 1.0, 7000.0, 2500.0, 1200.0, 0.001, 3.0)
	_ton(p, 0.0, 0.25, 95.0, 45.0, 0.9, Welle.SINUS, 0.002, 2.5)
	_rauschen(p, 0.0, 0.5, 0.45, 600.0, 150.0, 60.0, 0.005, 1.5)
	for k in 6:
		var t := 0.02 + float(k) * 0.045 + _zufall.randf_range(0.0, 0.02)
		_rauschen(p, t, 0.04, 0.6, 5000.0, 2000.0, 1500.0, 0.001, 3.0)
	for k in 4:
		var t := 0.26 + float(k) * 0.09 + _zufall.randf_range(0.0, 0.03)
		var f := _zufall.randf_range(380.0, 560.0)
		_ton(p, t, 0.035, f, f * 0.7, 0.3, Welle.DREIECK, 0.001, 4.0)
	return p


## Schnauben am Ufer: zwei Stöße aus der Wurfscheibe, der zweite mit
## flatternden Lefzen.
func _bau_keiler_schnauben() -> PackedFloat32Array:
	var p := _puffer(0.5)
	_rauschen(p, 0.0, 0.18, 0.9, 1800.0, 500.0, 250.0, 0.01, 1.6)
	_rauschen(p, 0.22, 0.24, 1.0, 1500.0, 400.0, 200.0, 0.01, 1.4)
	_ton(p, 0.22, 0.2, 72.0, 55.0, 0.35, Welle.RECHTECK, 0.02, 1.5)
	return p


## Galopp (Schleife über GALOPP_SPRUENGE Sprünge): je Sprung vier Hufe –
## ein dumpfer Schlag mit etwas Erde, unterschiedlich stark –, jeden
## zweiten Sprung ein kurzes Grunzen. Was über das Ende hinausreicht, legt
## `_schleife_gefaltet` an den Anfang: So schließt die Schleife ohne Naht.
func _bau_galopp() -> PackedFloat32Array:
	var laenge := GALOPP_SPRUNG * float(GALOPP_SPRUENGE)
	var p := _puffer(laenge + 0.25)
	var staerken: Array[float] = [1.0, 0.75, 0.95, 0.7]
	for k in GALOPP_SPRUENGE:
		var t0 := float(k) * GALOPP_SPRUNG
		for i in GALOPP_HUFE.size():
			var t := t0 + GALOPP_HUFE[i] * GALOPP_SPRUNG + _zufall.randf_range(0.0, 0.008)
			var f := 125.0 - 10.0 * float(i % 2)
			_ton(p, t, 0.07, f, f * 0.45, 0.9 * staerken[i], Welle.SINUS, 0.002, 3.0)
			_rauschen(p, t, 0.06, 0.45 * staerken[i], 1500.0, 500.0, 200.0, 0.002, 3.0)
		if k % 2 == 1:
			_ton(p, t0 + 0.3, 0.16, 96.0, 80.0, 0.3, Welle.RECHTECK, 0.02, 1.6)
			_rauschen(p, t0 + 0.3, 0.16, 0.22, 700.0, 400.0, 120.0, 0.02, 1.5)
	return p


## Mühlrad am Mühlbach (Level 05), als nahtlose Schleife von MUEHLE_LAENGE:
## ein Bett aus Wasserrauschen, je Takt eine Schaufel, die ins Wasser
## schlägt (Platscher mit fallendem Filter und einem dumpfen Plopp), jede
## zweite mit einem Holzklopfen der Welle, einmal je Umlauf das Knarren des
## Lagers und ein paar Gluckser. Abgespielt wird sie nicht über `spiele`,
## sondern von L05Stimmung mit eigenem Spieler und nach der Strecke
## geregelt – `spiele` spielt nicht räumlich (Entwurf L05 §8.4, §9.3).
##
## NAHTLOS: Gerechnet wird MUEHLE_UEBERBLENDUNG länger als die Schleife;
## der Überhang wird über den Anfang geblendet (`_schleife`). Damit das nur
## Rauschen trifft, liegen alle Ereignisse zwischen 0,15 und 1,8 s, und die
## Überblendung hält die Leistung gleich (Sinus/Kosinus). Das Rauschen der
## Schleife zieht aus einem eigenen Zufall (MUEHLE_SAAT), nicht aus
## `_zufall` – die anderen Klänge bleiben unberührt.
func _bau_muehle() -> PackedFloat32Array:
	var gemeinsam := _zufall
	_zufall = RandomNumberGenerator.new()
	_zufall.seed = MUEHLE_SAAT
	var p := _puffer(MUEHLE_LAENGE + MUEHLE_UEBERBLENDUNG)
	# Bett: rauschendes Wasser unter dem Rad, darüber feine Gischt.
	_rauschen_fest(p, 0.55, 700.0, 160.0)
	_rauschen_fest(p, 0.16, 2600.0, 1200.0)
	var takte := int(round(MUEHLE_LAENGE / MUEHLE_TAKT))
	for k in takte:
		var t := 0.15 + float(k) * MUEHLE_TAKT
		# Die Schaufel schlägt ins Wasser: Platscher von hell nach dumpf …
		_rauschen(p, t, 0.22, 0.9, 2600.0, 500.0, 300.0, 0.004, 2.2)
		# … und ein Plopp, jede Schaufel ein wenig anders.
		var f := 150.0 - 12.0 * float(k % 3)
		_ton(p, t + 0.01, 0.12, f, f * 0.57, 0.45, Welle.SINUS, 0.003, 2.5)
		# Holz auf Holz: die Welle im Lager, jede zweite Schaufel.
		if k % 2 == 0:
			_ton(p, t + 0.24, 0.035, 520.0 - 40.0 * float(k), 380.0, 0.32,
					Welle.DREIECK, 0.001, 4.0)
	# Knarren des Lagers einmal je Umlauf, rau und tief.
	_ton(p, 0.9, 0.42, 92.0, 118.0, 0.2, Welle.RECHTECK, 0.06, 1.2)
	_ton(p, 0.9, 0.42, 184.0, 236.0, 0.1, Welle.DREIECK, 0.06, 1.2)
	# Gluckser im Unterwasser.
	for _i in 5:
		var t := _zufall.randf_range(0.2, 1.72)
		var f := _zufall.randf_range(300.0, 650.0)
		_ton(p, t, 0.05, f, f * 1.4, 0.18, Welle.SINUS, 0.005, 2.0)
	_zufall = gemeinsam
	return p


## Wie `_schleife`, aber für Ereignisse statt eines Rauschbetts: Was über
## `laenge` hinausreicht, wird zum Anfang ADDIERT, nicht überblendet – so
## klingt ein Huf, der über die Naht reicht, genau wie jeder andere.
func _schleife_gefaltet(werte: PackedFloat32Array, pegel: float, laenge: float) -> AudioStreamWAV:
	var n := mini(int(laenge * ABTASTRATE), werte.size())
	if n == 0:
		return null
	for i in range(n, werte.size()):
		werte[i % n] += werte[i]
	werte.resize(n)
	var spitze := 0.0
	for wert in werte:
		spitze = maxf(spitze, absf(wert))
	var faktor := (pegel / spitze) if spitze > 0.0 else 0.0
	var daten := PackedByteArray()
	daten.resize(n * 2)
	for i in n:
		var v := clampf(werte[i] * faktor, -1.0, 1.0)
		daten.encode_s16(i * 2, int(round(v * 32767.0)))
	var strom_ := AudioStreamWAV.new()
	strom_.format = AudioStreamWAV.FORMAT_16_BITS
	strom_.mix_rate = ABTASTRATE
	strom_.stereo = false
	strom_.loop_mode = AudioStreamWAV.LOOP_FORWARD
	strom_.loop_begin = 0
	strom_.loop_end = n
	strom_.data = daten
	return strom_


## Menü, bestätigt: zwei Glöckchen eine Quarte aufwärts (G5–C6), kürzer
## und tiefer als die Frucht, damit man beide auseinanderhält.
func _bau_menue_ok() -> PackedFloat32Array:
	var p := _puffer(0.17)
	_ton(p, 0.0, 0.06, 784.0, 784.0, 0.7, Welle.SINUS, 0.003, 2.5)
	_ton(p, 0.0, 0.05, 1568.0, 1568.0, 0.14, Welle.SINUS, 0.003, 3.0)
	_ton(p, 0.055, 0.11, 1046.5, 1046.5, 0.8, Welle.SINUS, 0.003, 2.2)
	_ton(p, 0.055, 0.08, 2093.0, 2093.0, 0.14, Welle.SINUS, 0.003, 3.0)
	return p


# ---------------------------------------------------------- Bausteine

func _puffer(dauer: float) -> PackedFloat32Array:
	var p := PackedFloat32Array()
	p.resize(maxi(int(dauer * ABTASTRATE), 1))
	return p


## Hüllkurve: linearer Anstieg, danach Abfall auf null.
## `kruemmung` > 1 lässt den Klang schnell wegsacken (Schlag), Werte um 1
## ergeben ein gleichmäßiges Ausklingen.
func _huelle(t: float, anstieg: float, kruemmung: float) -> float:
	if anstieg > 0.0 and t < anstieg:
		return t / anstieg
	var rest := (t - anstieg) / maxf(1.0 - anstieg, 0.0001)
	return pow(1.0 - clampf(rest, 0.0, 1.0), kruemmung)


## Mischt einen Ton in den Puffer. Die Frequenz gleitet logarithmisch von
## `f_von` nach `f_bis` – so klingt der Übergang gleichmäßig, während ein
## linearer Verlauf unten hektisch und oben zäh wirkt.
func _ton(puffer: PackedFloat32Array, start: float, dauer: float,
		f_von: float, f_bis: float, staerke: float,
		form: Welle = Welle.SINUS, anstieg: float = 0.005,
		kruemmung: float = 2.0) -> void:
	var anzahl := int(dauer * ABTASTRATE)
	if anzahl <= 0:
		return
	var i0 := int(start * ABTASTRATE)
	var n := puffer.size()
	var verhaeltnis := maxf(f_bis, 1.0) / maxf(f_von, 1.0)
	var phase := 0.0
	var anstieg_anteil := clampf(anstieg / dauer, 0.0, 0.9)
	for i in anzahl:
		var t := float(i) / float(anzahl)
		var f := maxf(f_von, 1.0) * pow(verhaeltnis, t)
		phase += TAU * f / float(ABTASTRATE)
		var j := i0 + i
		if j < 0 or j >= n:
			continue
		var wert := 0.0
		match form:
			Welle.DREIECK:
				wert = asin(sin(phase)) * (2.0 / PI)
			Welle.RECHTECK:
				wert = 0.6 if sin(phase) >= 0.0 else -0.6
			_:
				wert = sin(phase)
		puffer[j] += wert * staerke * _huelle(t, anstieg_anteil, kruemmung)


## Mischt gefiltertes Rauschen in den Puffer.
##
## Rohes Rauschen klingt nach kaputtem Radio. Zwei einpolige Filter machen
## daraus etwas Brauchbares: ein Tiefpass mit wandernder Grenzfrequenz
## (`tief_von` -> `tief_bis`) bestimmt die Klangfarbe – aufsteigend ergibt
## ein Zischen, absteigend einen Aufschlag –, ein Hochpass bei `hoch`
## nimmt das Wummern heraus.
func _rauschen(puffer: PackedFloat32Array, start: float, dauer: float,
		staerke: float, tief_von: float, tief_bis: float,
		hoch: float = 200.0, anstieg: float = 0.003,
		kruemmung: float = 2.0) -> void:
	var anzahl := int(dauer * ABTASTRATE)
	if anzahl <= 0:
		return
	var i0 := int(start * ABTASTRATE)
	var n := puffer.size()
	var verhaeltnis := maxf(tief_bis, 20.0) / maxf(tief_von, 20.0)
	var anstieg_anteil := clampf(anstieg / dauer, 0.0, 0.9)
	# Hochpass = Signal minus seinem eigenen Tiefpass; dessen Beiwert
	# ändert sich nicht und wird deshalb nur einmal berechnet.
	var b := 1.0 - exp(-TAU * hoch / float(ABTASTRATE))
	var tief := 0.0
	var basis := 0.0
	for i in anzahl:
		var t := float(i) / float(anzahl)
		var grenze := maxf(tief_von, 20.0) * pow(verhaeltnis, t)
		var a := 1.0 - exp(-TAU * minf(grenze, ABTASTRATE * 0.45) / float(ABTASTRATE))
		tief += a * (_zufall.randf_range(-1.0, 1.0) - tief)
		basis += b * (tief - basis)
		var j := i0 + i
		if j < 0 or j >= n:
			continue
		# Faktor 2.5: Die Filterung nimmt dem Rauschen viel Pegel, ohne
		# den Ausgleich verschwände es neben den Tönen.
		puffer[j] += (tief - basis) * 2.5 * staerke \
				* _huelle(t, anstieg_anteil, kruemmung)


## Gefiltertes Rauschen wie `_rauschen`, aber über den ganzen Puffer, mit
## fester Grenzfrequenz und ohne Hülle – das Bett einer Schleife. Die
## Beiwerte stehen fest und werden einmal gerechnet: `_rauschen` rechnet je
## Abtastwert eine Potenz und eine Exponentialfunktion, für zwei Sekunden
## Bett kostete das beim Programmstart rund 60–100 ms.
func _rauschen_fest(puffer: PackedFloat32Array, staerke: float, tief: float,
		hoch: float) -> void:
	var a := 1.0 - exp(-TAU * minf(tief, ABTASTRATE * 0.45) / float(ABTASTRATE))
	var b := 1.0 - exp(-TAU * hoch / float(ABTASTRATE))
	var tp := 0.0
	var basis := 0.0
	var faktor := 2.5 * staerke
	for j in puffer.size():
		tp += a * (_zufall.randf_range(-1.0, 1.0) - tp)
		basis += b * (tp - basis)
		puffer[j] += (tp - basis) * faktor


## Normiert den fertigen Puffer auf `pegel` und packt ihn in einen
## AudioStreamWAV.
##
## Die Normierung hat zwei Aufgaben: Sie verhindert Übersteuern (der
## Spitzenwert liegt danach exakt bei `pegel` < 1.0) und stimmt die
## Klänge untereinander ab – wie laut ein Baustein gemischt wurde, ist
## danach egal, es zählt nur noch `pegel`.
func _fertig(werte: PackedFloat32Array, pegel: float) -> AudioStreamWAV:
	var n := werte.size()
	if n == 0:
		return null

	# Ein Sprung von 0 auf den ersten Abtastwert (und zurück am Ende)
	# hört man als Knacksen. Zwei kurze Rampen nehmen ihn heraus.
	var ein := mini(int(0.001 * ABTASTRATE), n)
	var aus := mini(int(0.008 * ABTASTRATE), n)
	for i in ein:
		werte[i] *= float(i) / float(ein)
	for i in aus:
		werte[n - 1 - i] *= float(i) / float(aus)

	var spitze := 0.0
	for wert in werte:
		spitze = maxf(spitze, absf(wert))
	var faktor := (pegel / spitze) if spitze > 0.0 else 0.0

	var daten := PackedByteArray()
	daten.resize(n * 2)
	for i in n:
		var v := clampf(werte[i] * faktor, -1.0, 1.0)
		daten.encode_s16(i * 2, int(round(v * 32767.0)))

	var strom_ := AudioStreamWAV.new()
	strom_.format = AudioStreamWAV.FORMAT_16_BITS
	strom_.mix_rate = ABTASTRATE
	strom_.stereo = false
	strom_.loop_mode = AudioStreamWAV.LOOP_DISABLED
	strom_.data = daten
	return strom_


## Wie `_fertig`, aber als Schleife über `laenge` Sekunden: Der Puffer ist
## länger, sein Überhang hinter `laenge` wird über den Anfang geblendet
## (Sinus/Kosinus, gleiche Leistung für Rauschen), dann abgeschnitten. Ohne
## die Rampen von `_fertig` – die hörte man in jeder Runde als Loch.
func _schleife(werte: PackedFloat32Array, pegel: float, laenge: float) -> AudioStreamWAV:
	var n := mini(int(laenge * ABTASTRATE), werte.size())
	var ueber := mini(werte.size() - n, n)
	if n == 0:
		return null
	for i in ueber:
		var w := float(i) / float(maxi(ueber, 1)) * PI * 0.5
		werte[i] = werte[i] * sin(w) + werte[n + i] * cos(w)
	werte.resize(n)

	var spitze := 0.0
	for wert in werte:
		spitze = maxf(spitze, absf(wert))
	var faktor := (pegel / spitze) if spitze > 0.0 else 0.0

	var daten := PackedByteArray()
	daten.resize(n * 2)
	for i in n:
		var v := clampf(werte[i] * faktor, -1.0, 1.0)
		daten.encode_s16(i * 2, int(round(v * 32767.0)))

	var strom_ := AudioStreamWAV.new()
	strom_.format = AudioStreamWAV.FORMAT_16_BITS
	strom_.mix_rate = ABTASTRATE
	strom_.stereo = false
	strom_.loop_mode = AudioStreamWAV.LOOP_FORWARD
	strom_.loop_begin = 0
	strom_.loop_end = n
	strom_.data = daten
	return strom_
