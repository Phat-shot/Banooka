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
	var strom_ := _kloenge.get(name) as AudioStreamWAV
	if strom_ == null:
		push_warning("Klang unbekannt: %s" % name)
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


## Namen aller Klänge (für Prüfwerkzeuge und eine spätere Tonoptionsseite).
func namen() -> PackedStringArray:
	var liste := PackedStringArray(_kloenge.keys())
	liste.sort()
	return liste


## Der fertige Klang zu einem Namen, oder null.
func strom(name: String) -> AudioStreamWAV:
	return _kloenge.get(name) as AudioStreamWAV


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

## Baut alle Klänge einmal auf. Zusammen sind das rund 80 000 Abtastwerte –
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

	# Abweichende Sperrzeiten: Landungen sollen nicht klappern, Früchte
	# dürfen schnell perlen, Explosionen reißen Nachbarkisten mit.
	_abstaende["landung"] = 0.14
	_abstaende["frucht"] = 0.03
	_abstaende["kiste"] = 0.06
	_abstaende["explosion"] = 0.09
	_abstaende["gegner"] = 0.06


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
