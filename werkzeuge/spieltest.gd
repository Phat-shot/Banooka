extends Node
## Spielt das Spiel selbsttätig durch und nimmt dabei Bilder auf.
##
## Aufruf über werkzeuge/spieltest.sh. Wird dort als Autoload in eine
## Projektkopie eingehängt, damit der Ablauf Szenenwechsel übersteht.
##
## Der Bot bedient das Spiel wie ein Mensch:
##   * Menü und Tafeln über echte Tastenereignisse (Input.parse_input_event)
##   * Laufen über den Joystick-Eingang von InputHub (touch_bewegung)
##   * Springen, Spin und Slide über Tastenereignisse
##
## Zwei Spielarten werden unterschieden:
##   Laufmodus     – der Bot steuert selbst am Korridorverlauf entlang
##                   (Level 01–03)
##   Schienenmodus – die Figur rennt von allein, gelenkt wird nur quer
##                   (Reiter, Rennfahrer; Level 04 und 06).
##                   Erkannt an der Eigenschaft `strecke` der Figur.
##
## Lücken erkennt der Bot per Strahltest nach unten, nicht aus den
## Leveldaten – so prüft er gleichzeitig, ob die Kollisionsgeometrie da ist.
##
## DURCHLÄSSE (Opt-in, Entwurf L05 §9.3): Bietet das Level `duckstellen()`
## an (die Stirnen seiner Duckdurchlässe als Strecken), tippt der Bot im
## Laufmodus DUCK_VORAUS vor jeder Stirn einmal Slide. Ein Strahl fände den
## Riegel nicht: Er beginnt erst 0,95 m über dem Boden, der Hürdenstrahl
## (HUERDE_HOEHE 0,45) geht darunter durch – der Bot liefe aufrecht hinein
## und stolperte. Ohne die Methode läuft der Bot wie bisher.
##
## LAUFLINIE (Opt-in): Bietet das Level `lauflinie()` an – Punkte
## Vector2(s, q) einer Linie quer zum Verlauf –, hält der Bot im Laufmodus
## diese Querlage statt der Mitte (bzw. statt des Ausweichens vor
## Gefahren) und schaut dafür nur LINIE_VORAUS weit voraus. Level 05 braucht
## das für die Findlingsgasse: Zwei versetzte Blöcke quer über die halbe
## Wegbreite, die Lücke dazwischen verlangt ≥ 1 m Querversatz. Gemessen
## ohne Linie: Der Bot lief in der Mitte frontal auf F1 und F2, sprang (der
## Hürdenstrahl sah sie), stolperte an jedem zweimal und wurde in vier von
## vier Anläufen bei s 248,8 gefangen. Mit 5 m Vorausschau schnitte er die
## Gasse diagonal an F1 vorbei. Ohne die Methode läuft der Bot wie bisher.
##
## Umgebungsvariablen:
##   TEST_ZIEL   Ausgabeverzeichnis für die PNGs (Pflicht)
##   TEST_DAUER  Höchstdauer in Sekunden (Vorgabe 600)
##   TEST_LEVEL  Levelnummern mit Komma getrennt (Vorgabe: alle gebauten)
##   TEST_DOPPELSPRUNG  0 = nie doppelt springen. Dann zeigt der Lauf, dass
##               jede Pflichtlücke mit dem einfachen Sprung geht (Lehrlevel).
##   TEST_SPRUENGE  1 = jeden Absprung im Laufmodus mit Stelle und Grund
##               ins Protokoll schreiben (zum Nachsehen, wo der Bot fällt).

const KEY_SPACE := 32
const KEY_J := 74
const KEY_SHIFT := 4194325
const KEY_AB := 4194322
const KEY_AUF := 4194320

## Mittelpunkt des Halbkreises im Portalraum (hub.gd: BOGEN_MITTE).
const BOGEN_MITTE := Vector3(0.0, 0.0, 36.0)
const HALLE_RADIUS := 33.5      ## hub.gd: START_R
## Größter Winkelschritt auf dem Hallenbogen. Die Südkante liegt bei 29 m
## (hub.gd: HALLE_R); eine Sehne auf 33,5 m bleibt bis 60° Öffnung über
## ihr – 20° lassen reichlich Luft für Ausweichschritte.
const BOGEN_SCHRITT := 20.0

const VORAUS := 5.0             ## Zielpunkt so viele Meter voraus
## So weit voraus wird auf Boden geprüft: Fehlt er dort, springt der Bot ab.
## Knapp vor der Kante, wie ein Mensch – der Sprung trägt 4,5 m, und
## früher abgesprungen fehlte er über einer 3-m-Lücke (bei 4,2 m landete
## der Bot vor dem Erdspalt von Level 01 regelmäßig im Spalt). Gut ein
## Physikschritt Verzug kommt noch dazu (0,14 m bei vollem Lauf).
const LUECKE_VORAUS := 0.9
## Hindernis voraus in Kniehöhe (liegender Stamm, Stufe): so weit voraus.
const HUERDE_VORAUS := 1.1
const HUERDE_HOEHE := 0.45
## Slide so weit vor der Stirn eines Durchlasses (Opt-in `duckstellen`).
## Entwurf L05 §2.3: sauber von 3,6–3,9 bis 0,5 m vor der Stirn; 2,2 liegt
## in der Mitte und lässt gut einen Physikschritt Verzug (0,14 m).
const DUCK_VORAUS := 2.2
## Näher als das an der Stirn wird nicht mehr getippt (zu spät für einen
## sauberen Slide).
const DUCK_SPAET := 0.5
## Vorausschau auf der Lauflinie (Opt-in `lauflinie`, siehe Kopf).
const LINIE_VORAUS := 1.5
## Liegt voraus nichts höher als so tief unter den Füßen, ist dort eine
## Lücke. Tiefer als jeder Stufenabsatz (Level 01: 1,6 m), flacher als ein
## Bruch mit Wiesenboden darunter (Level 01, G1: 2,7 m) – den erkannte der
## Bot mit vier Metern Suchtiefe nicht als Lücke und lief hinein.
const LUECKE_TIEFE := 1.8
const BILD_ABSTAND := 4.0       ## Sekunden zwischen zwei Spielbildern
const LEVEL_DAUER := 260.0      ## Höchstdauer je Level
const FLUG_DAUER := 40.0        ## so lange wird im Flugniveau geflogen

## Reichweite, in der der Bot einen Gegner überhaupt beachtet.
const GEGNER_SICHT := 6.0
## Abstände, bei denen der jeweilige Angriff ausgelöst wird.
const SPIN_ABSTAND := 2.6
const SLIDE_ABSTAND := 3.4
const SPRUNG_ABSTAND := 3.2
## Pause zwischen zwei gezielten Angriffen.
const ANGRIFF_PAUSE := 0.45
## So viele Tode je Level, bevor abgebrochen wird.
const TODE_GRENZE := 20
## So lange darf die Figur stehen bleiben, bevor es als Hänger zählt.
## Großzügig, weil Warten hier oft richtig ist: auf ein Treibfloß, auf
## eine Wehrbohle, auf die Lücke in einem Taktfeld.
const HAENGER_ZEIT := 8.0
const HAENGER_GRENZE := 8

var _ziel := ""
var _nr := 0
var _uhr := 0.0
var _ergebnisse: Array[Dictionary] = []
var _fehler: Array[String] = []
var _tote := 0
var _aktuelles_bild := ""
## Zeitpunkt des letzten gezielten Angriffs.
var _letzter_angriff := -9.0
## Doppelsprung als Rettung über Lücken (TEST_DOPPELSPRUNG=0 schaltet ab).
var _doppelsprung := true
## Absprünge protokollieren (TEST_SPRUENGE=1).
var _spruenge_melden := false
## Stirnen der Durchlässe des laufenden Levels (Opt-in, siehe Kopf).
var _duckstellen: Array[float] = []
## Vor dieser Stirn wurde zuletzt Slide getippt – einmal je Anlauf.
var _duck_zuletzt := -INF
## Lauflinie des laufenden Levels (Opt-in, siehe Kopf), (s, q).
var _lauflinie: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ziel = OS.get_environment("TEST_ZIEL")
	_doppelsprung = OS.get_environment("TEST_DOPPELSPRUNG") != "0"
	_spruenge_melden = OS.get_environment("TEST_SPRUENGE") == "1"
	if _ziel.is_empty():
		_ziel = "/tmp/spieltest"
	DirAccess.make_dir_recursive_absolute(_ziel)

	GameState.nachricht.connect(func(text: String, _d: float) -> void:
		_notiz("Meldung: %s" % text))
	# Die großen Momente (Extraleben, alle Kisten, Game Over) laufen als
	# Band über ein eigenes Signal. Nur verbinden, wo es das gibt: Das
	# dritte Argument von spieltest.sh lässt den Bot auch ältere
	# Projektstände prüfen, und dort fehlt es.
	if GameState.has_signal(&"banner"):
		GameState.connect(&"banner", func(text: String, _f: Color, _d: float) -> void:
			_notiz("Band: %s" % text))
	GameState.leben_geaendert.connect(func(anzahl: int) -> void:
		_notiz("Leben: %d" % anzahl))

	_wachhund()
	_ablauf()


func _process(delta: float) -> void:
	_uhr += delta


# ------------------------------------------------------------- Ablauf

func _ablauf() -> void:
	_notiz("=== Spieltest beginnt ===")

	if not await _startbildschirm():
		_ende()
		return

	# Fortschritt stellen, DANN den Portalraum neu aufbauen lassen.
	#
	# Die Reihenfolge ist die ganze Schwierigkeit: `hub.gd` entscheidet beim
	# BAUEN der Szene, vor welchen Raum ein Sperrgitter kommt. Vorher
	# gesetzter Fortschritt ist wertlos, weil der Startbildschirm ein neues
	# Spiel beginnt und dabei alles auf null zieht; nachher gesetzter ist
	# wertlos, weil die Mauer dann schon steht. Also: neues Spiel abwarten,
	# Fortschritt stellen, Portalraum einmal neu betreten.
	#
	# Geschrieben wird dabei nichts: `Spielfluss.speichern()` steigt bei
	# Slot 0 aus, und der Bot waehlt keinen. Der echte Spielstand unter
	# `user://` bleibt unangetastet - er gehoert NICHT zur Projektkopie.
	if _ausdruecklich():
		if await _warte_szene("Hub", 40.0):
			_fortschritt_vortaeuschen(_levelliste())
			Spielfluss.zum_hub()
			await _warte(1.0)

	for nummer in _levelliste():
		if not await _warte_szene("Hub", 40.0):
			_fehler.append("Level %02d: Portalraum kam nicht" % nummer)
			break
		# Der Portalraum wärmt seine Shader unter dem Ladeschirm vor und hält
		# die Figur so lange fest. Erst danach lenken – sonst verschluckt die
		# Sperre die Eingaben und frisst die Zeitgrenzen der Wege auf.
		if not await _warte_aufbau(90.0):
			_fehler.append("Level %02d: Portalraum wurde nicht fertig" % nummer)
			break
		await _warte(1.5)
		if nummer == _levelliste()[0]:
			await _bild("portalraum")

		if not Spielfluss.level_offen(nummer):
			_notiz("Level %02d ist verschlossen – übersprungen" % nummer)
			_ergebnisse.append({"nummer": nummer, "stand": "verschlossen"})
			continue

		await _spiele(nummer)

	# Abschlussbild im Portalraum
	if await _warte_szene("Hub", 40.0):
		await _warte_aufbau(90.0)
		await _warte(2.0)
		await _bild("portalraum_am_ende")
	_ende()


## Startbildschirm: Menü prüfen, neues Spiel auf Platz 1 beginnen.
func _startbildschirm() -> bool:
	if not await _warte_szene("Splash", 20.0):
		_fehler.append("Startbildschirm kam nicht")
		return false
	await _warte(1.8)
	await _bild("startbildschirm")
	# Die Einblendung sperrt die Eingabe rund 1,9 s lang.
	await _warte(1.4)

	var menue := get_tree().current_scene
	var vorher := int(menue.get("_index"))
	_tippe(KEY_AB)
	await _warte(0.5)
	if not is_instance_valid(menue):
		return true
	var nachher := int(menue.get("_index"))
	if nachher == vorher:
		_fehler.append("Menü: Pfeiltaste ab hat nichts bewirkt")
	_tippe(KEY_AUF)
	await _warte(0.5)
	if int(menue.get("_index")) != vorher:
		_fehler.append("Menü: Pfeiltaste auf führte nicht zurück")

	# "Neues Spiel" → Platz wählen → ggf. Überschreiben bestätigen
	for versuch in 4:
		if not is_instance_valid(menue) or get_tree().current_scene != menue:
			break
		_tippe(KEY_SPACE)
		await _warte(0.9)
		# Der letzte Druck startet das Spiel – dann ist das Menü schon weg.
		if not is_instance_valid(menue):
			break
		if menue.get("_tafel_offen") == true:
			await _bild("menue_tafel_%d" % (versuch + 1))
	if is_instance_valid(menue) and get_tree().current_scene == menue:
		_fehler.append("Neues Spiel ließ sich nicht starten")
		return false
	return true


## Spielt ein einzelnes Level: hinlaufen, durchspielen, Ergebnis notieren.
func _spiele(nummer: int) -> void:
	var hub := get_tree().current_scene
	var portal := _finde_knoten(hub, "Portal%02d" % nummer)
	if portal == null:
		_fehler.append("Level %02d: Portal im Raum nicht gefunden" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "Portal fehlt"})
		return

	_notiz("--- Level %02d: Weg zum Portal ---" % nummer)
	# Erst über den Hallenbogen vor den Raum, dann zum Portal – sonst läuft
	# der Bot bei den hinteren Räumen gegen eine Trennmauer. Der Portalraum
	# setzt die Figur vor den Raum, um den es gerade geht, nicht mehr immer
	# auf 0°; eine gerade Sehne zu einem fernen Raum liefe dann durch die
	# Südmauer. Also in Schritten am Bogen entlang.
	await _bogen_entlang(_bogenwinkel(portal.global_position))
	if not await _gehe_zu(portal.global_position, 25.0, 0.6):
		_fehler.append("Level %02d: Portal nicht erreicht" % nummer)
		await _bild("level%02d_portal_verfehlt" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "Portal nicht erreicht"})
		return

	if not await _warte_szene("Level%02d" % nummer, 30.0):
		_fehler.append("Level %02d: Szene wurde nicht geladen" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "nicht geladen"})
		_zurueck_in_den_hub()
		return
	var start_aufbau := _uhr
	if not await _warte_aufbau(90.0):
		_fehler.append("Level %02d: Aufbau nicht fertig geworden" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "Aufbau hängt"})
		_zurueck_in_den_hub()
		return
	_notiz("Level %02d steht (Aufbau %.1f s)" % [nummer, _uhr - start_aufbau])
	await _warte(0.8)
	await _bild("level%02d_start" % nummer)

	var ergebnis := await _durchlaufen(nummer)
	_ergebnisse.append(ergebnis)


## Läuft auf dem Hallenbogen (Radius HALLE_RADIUS) von der Figur bis zum
## Winkel `ziel`, in Schritten von höchstens BOGEN_SCHRITT Grad.
func _bogen_entlang(ziel: float) -> void:
	var spieler := _spieler()
	if spieler == null:
		return
	var von := _bogenwinkel(spieler.global_position)
	var schritte := maxi(ceili(absf(ziel - von) / BOGEN_SCHRITT), 1)
	for i in range(1, schritte + 1):
		var grad := lerpf(von, ziel, float(i) / float(schritte))
		# Zwischenpunkte großzügig abhaken, nur den letzten genau anlaufen.
		var nahe := 2.0 if i == schritte else 3.0
		if not await _gehe_zu(_bogenort(grad), 12.0, nahe):
			_notiz("Bogen: %.0f° nicht erreicht" % grad)


## Winkel eines Punkts um BOGEN_MITTE wie in hub.gd: 0° zeigt nach -Z,
## positive Winkel nach rechts (+X).
func _bogenwinkel(punkt: Vector3) -> float:
	var d := punkt - BOGEN_MITTE
	return rad_to_deg(atan2(d.x, -d.z))


func _bogenort(grad: float) -> Vector3:
	var t := deg_to_rad(grad)
	return BOGEN_MITTE + Vector3(sin(t) * HALLE_RADIUS, 0.0, -cos(t) * HALLE_RADIUS)


## Zurück in den Portalraum, wenn ein Level abgebrochen wurde.
##
## Ohne das blieb der Bot in der Levelszene stehen, der nächste Durchgang
## wartete vergebens auf den Portalraum, und der Rest des Laufs fiel aus.
## Ein Abbruch darf immer nur EIN Level kosten.
func _zurueck_in_den_hub() -> void:
	InputHub.touch_bewegung = Vector2.ZERO
	if get_tree().current_scene != null \
			and get_tree().current_scene.name != "Hub":
		Spielfluss.zum_hub()


## Läuft ein Level bis zum Ende ab.
func _durchlaufen(nummer: int) -> Dictionary:
	var szene := get_tree().current_scene
	var verlauf: Curve3D = szene.get("verlauf")
	if verlauf == null:
		# Das Flugniveau hat keine Kurve. Messen lässt sich hier nichts,
		# aber es lässt sich fliegen: vorwärts halten und zählen, was
		# dabei passiert. Das findet immerhin einen sofortigen Tod.
		return await _fliegen(nummer)
	var laenge := verlauf.get_baked_length()
	var spieler := _spieler()
	var schiene: bool = spieler != null and spieler.get("strecke") != null
	_duckstellen.clear()
	_duck_zuletzt = -INF
	if szene.has_method("duckstellen"):
		_duckstellen.assign(szene.call("duckstellen"))
		_notiz("Level %02d: %d Durchlässe (duckstellen)" % [nummer, _duckstellen.size()])
	_lauflinie.clear()
	if szene.has_method("lauflinie"):
		_lauflinie.assign(szene.call("lauflinie"))
		_notiz("Level %02d: Lauflinie mit %d Punkten" % [nummer, _lauflinie.size()])
	_notiz("Level %02d: Weg %.0f m, Kisten %d, %s"
			% [nummer, laenge, GameState.kisten_gesamt,
			"Schienenmodus" if schiene else "Laufmodus"])

	var start := _uhr
	var letztes_bild := _uhr
	var letzter_spin := 0.0
	var letzter_fortschritt := _uhr
	var beste := 0.0
	var leben_vorher := GameState.leben
	var tode := 0
	var djump := false
	var haenger := 0
	var letzte_pos := spieler.global_position
	var stand := "Zeit abgelaufen"
	# Wo die Figur zuletzt Boden unter den Füßen hatte: Nach einem Tod steht
	# sie schon wieder am Checkpoint, und "Tod bei 107 m" sagte nur, wo.
	var boden_s := 0.0

	while _uhr - start < LEVEL_DAUER:
		await get_tree().physics_frame
		if get_tree().current_scene != szene:
			stand = "geschafft" if Spielfluss.geschafft.has(nummer) else "verlassen"
			break
		spieler = _spieler()
		if spieler == null:
			stand = "Spielfigur verschwunden"
			_fehler.append("Level %02d: Spielfigur verschwunden" % nummer)
			break
		if spieler.get("gesperrt") == true:
			InputHub.touch_bewegung = Vector2.ZERO
			continue

		var s: float = float(spieler.get("strecke")) if schiene \
				else verlauf.get_closest_offset(spieler.global_position)
		beste = maxf(beste, s)
		if GameState.leben == leben_vorher and spieler.has_method("is_on_floor") \
				and spieler.call("is_on_floor"):
			boden_s = s

		if schiene:
			_schiene_steuern(spieler, verlauf, s, laenge)
		else:
			djump = _laufen(spieler, szene, verlauf, s, laenge, djump)

		# Erst der gezielte Angriff auf den nächsten Gegner, dann – falls
		# keiner in Reichweite ist – der Spin für die Kisten am Weg.
		if not _kampf(spieler, verlauf, s) and _uhr - letzter_spin > 1.1:
			letzter_spin = _uhr
			_tippe(KEY_J)

		if GameState.leben != leben_vorher:
			if GameState.leben < leben_vorher:
				tode += 1
				_tote += 1
				# Wer war schuld? Ohne diese Zeile steht im Bericht nur
				# "gestorben bei 34 m", und man sucht die Ursache im Bild.
				_notiz("Level %02d: Tod %d bei %.0f m (zuletzt am Boden bei %.1f m) – %s"
						% [nummer, tode, s, boden_s, _todesumstand(spieler, verlauf, s)])
				if tode <= 6:
					await _bild("level%02d_tod%d_bei_%dm" % [nummer, tode, int(s)])
			leben_vorher = GameState.leben
			if tode >= TODE_GRENZE:
				_fehler.append("Level %02d: %d Tode bei %.0f von %.0f m - abgebrochen"
						% [nummer, TODE_GRENZE, s, laenge])
				stand = "zu viele Tode"
				break

		# Hänger erkennen: die Figur bewegt sich nicht mehr vom Fleck.
		# (Am Streckenbesten festgemacht schlüge das nach jedem Tod an,
		#  weil der Respawn zurücksetzt.)
		if spieler.global_position.distance_to(letzte_pos) > 1.5:
			letzte_pos = spieler.global_position
			letzter_fortschritt = _uhr
		if _uhr - letzter_fortschritt > HAENGER_ZEIT:
			haenger += 1
			_notiz("Level %02d: Hänger bei %.0f m (%d.)" % [nummer, s, haenger])
			_taste_ab(KEY_SPACE)
			_sprung_halten(0.25)
			letzter_fortschritt = _uhr
			if haenger >= HAENGER_GRENZE:
				await _bild("level%02d_haenger_bei_%dm" % [nummer, int(s)])
				_fehler.append("Level %02d: bei %.0f m von %.0f m festgehangen"
						% [nummer, s, laenge])
				stand = "festgehangen"
				break

		if _uhr - letztes_bild > BILD_ABSTAND:
			letztes_bild = _uhr
			await _bild("level%02d_%03dm" % [nummer, int(s)])

	InputHub.touch_bewegung = Vector2.ZERO
	# Wer nicht durchs Zielportal geht, muss selbst zurück - sonst wartet
	# der Test vergebens auf den Portalraum.
	if get_tree().current_scene == szene:
		_notiz("Level %02d wird abgebrochen, zurueck in den Portalraum" % nummer)
		Spielfluss.zum_hub()
	if stand == "Zeit abgelaufen":
		_fehler.append("Level %02d: in %.0f s nicht geschafft (bis %.0f von %.0f m)"
				% [nummer, LEVEL_DAUER, beste, laenge])
	_notiz("Level %02d: %s, weiteste Stelle %.0f von %.0f m, Tode %d"
			% [nummer, stand, beste, laenge, tode])
	return {
		"nummer": nummer, "stand": stand, "weit": beste, "laenge": laenge,
		"tode": tode, "kisten": GameState.kisten_zerbrochen,
		"kisten_gesamt": GameState.kisten_gesamt, "fruechte": GameState.fruechte,
		# Die reine Spielzeit im Level, ohne Aufbau und ohne Portalraum.
		# Sie ist die einzige Zahl im Projekt, die sagt, wie lange ein
		# Level WIRKLICH dauert – daraus kommen die Richtzeiten des
		# Zeitmodus (`LevelBasis.zielzeit()`).
		"dauer": _uhr - start,
	}


## Wählt gegen den nächsten Gegner voraus den Angriff, der bei ihm wirkt.
## Gibt true zurück, wenn gerade ein Gegner behandelt wird.
##
## Das war die größte Lücke des Bots: Er lief mit Dauerspin vorwärts, und
## jeder Gegner, der NICHT auf Spin hört – der Panzerkäfer will einen
## Sprung von oben, die Stelzenspinne einen Slide –, kostete ihn ein
## Leben. Zwölf Tode am selben Fleck waren dann kein Levelfehler, sondern
## ein Botfehler. Welcher Angriff wirkt, steht am Gegner selbst
## (`besiegbar_durch`, siehe `scenes/enemies/gegner.gd`); der Bot muss es
## nur lesen.
func _kampf(spieler: Node3D, verlauf: Curve3D, s: float) -> bool:
	var gegner := _naechster_gegner(spieler, verlauf, s)
	if gegner == null:
		return false
	if _uhr - _letzter_angriff < ANGRIFF_PAUSE:
		return true
	var abstand := spieler.global_position.distance_to(gegner.global_position)
	var maske := int(gegner.get("besiegbar_durch"))

	# Reihenfolge nach Sicherheit: Der Spin trifft rundum, der Slide
	# braucht nur die Richtung, der Sprung von oben das genaueste Timing.
	if (maske & Angriff.SPIN) != 0 and abstand < SPIN_ABSTAND:
		_letzter_angriff = _uhr
		_tippe(KEY_J)
		return true
	if (maske & Angriff.SLIDE) != 0 and abstand < SLIDE_ABSTAND:
		_letzter_angriff = _uhr
		_taste_ab(KEY_SHIFT)
		_spaeter(0.4, func() -> void: _taste_auf(KEY_SHIFT))
		return true
	if (maske & (Angriff.FALLEN | Angriff.SLAM)) != 0 and spieler.is_on_floor() \
			and abstand < SPRUNG_ABSTAND and abstand > SPRUNG_ABSTAND - 1.4:
		_letzter_angriff = _uhr
		_taste_ab(KEY_SPACE)
		_sprung_halten(0.3)
		return true
	return true


## Was in Reichweite stand, als die Figur starb. Nennt den nächsten
## Gegner mit seiner verwundbaren Stelle und die nächste gefährliche
## Kiste – das reicht fast immer, um die Ursache zu benennen.
func _todesumstand(spieler: Node3D, verlauf: Curve3D, s: float) -> String:
	var teile: Array[String] = []
	var g := _naechster_gegner(spieler, verlauf, s)
	if g != null:
		teile.append("Gegner %s in %.1f m (besiegbar durch %s)"
				% [g.get_class() if g.get_script() == null
				else String(g.get_script().resource_path.get_file().get_basename()),
				spieler.global_position.distance_to(g.global_position),
				Angriff.als_text(int(g.get("besiegbar_durch")))])
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var k := knoten as Kiste
		if k == null or not is_instance_valid(k):
			continue
		if k.art != Kiste.Art.NITRO and k.art != Kiste.Art.TNT:
			continue
		var abstand := spieler.global_position.distance_to(k.global_position)
		if abstand < 4.0:
			teile.append("%s-Kiste in %.1f m"
					% ["Nitro" if k.art == Kiste.Art.NITRO else "TNT", abstand])
	if not spieler.is_on_floor():
		teile.append("in der Luft")
	if teile.is_empty():
		teile.append("nichts in Reichweite – vermutlich Sturz")
	return ", ".join(teile)


## Der nächste Gegner voraus auf unserer Bahn.
func _naechster_gegner(spieler: Node3D, verlauf: Curve3D, s: float) -> Node3D:
	var bester: Node3D = null
	var beste := 1.0e9
	for knoten in get_tree().get_nodes_in_group("gegner"):
		var g := knoten as Node3D
		if g == null or not is_instance_valid(g) or g.is_queued_for_deletion():
			continue
		if g.get("besiegbar_durch") == null:
			continue
		var gs: float = verlauf.get_closest_offset(g.global_position)
		if gs < s - 1.5 or gs > s + GEGNER_SICHT:
			continue
		var abstand := spieler.global_position.distance_to(g.global_position)
		# Nur was wirklich im Weg steht, nicht der Gegner drei Meter neben
		# dem Steg.
		if abstand > GEGNER_SICHT or abstand > beste:
			continue
		beste = abstand
		bester = g
	return bester


## Level ohne Levelkurve (Flugniveau): eine Weile vorwärts halten.
func _fliegen(nummer: int) -> Dictionary:
	_notiz("Level %02d: kein Verlauf – Flugniveau, es wird nur geflogen" % nummer)
	var szene := get_tree().current_scene
	var start := _uhr
	var leben_vorher := GameState.leben
	var tode := 0
	var letztes_bild := _uhr
	while _uhr - start < FLUG_DAUER:
		await get_tree().physics_frame
		if get_tree().current_scene != szene:
			break
		InputHub.touch_bewegung = Vector2(0.0, -1.0)
		if GameState.leben != leben_vorher:
			if GameState.leben < leben_vorher:
				tode += 1
				_tote += 1
			leben_vorher = GameState.leben
		if _uhr - letztes_bild > BILD_ABSTAND:
			letztes_bild = _uhr
			await _bild("level%02d_flug_%03ds" % [nummer, int(_uhr - start)])
	InputHub.touch_bewegung = Vector2.ZERO
	_notiz("Level %02d: Flug geprüft, Tode %d" % [nummer, tode])
	_zurueck_in_den_hub()
	return {"nummer": nummer, "stand": "Flug geprüft", "weit": 0.0,
			"laenge": 0.0, "tode": tode, "kisten": GameState.kisten_zerbrochen,
			"kisten_gesamt": GameState.kisten_gesamt,
			"fruechte": GameState.fruechte, "dauer": _uhr - start}


# ------------------------------------------------------------- Steuerung

## Laufmodus: dem Verlauf folgen, vor Lücken springen.
func _laufen(spieler: Node3D, szene: Node, verlauf: Curve3D, s: float,
		laenge: float, djump: bool) -> bool:
	var seitlich := _ausweichen(szene, verlauf, s)
	var vorlauf := VORAUS
	if not _lauflinie.is_empty():
		vorlauf = LINIE_VORAUS
		seitlich = _linie_q(s + vorlauf)
	var zielpunkt := _punkt(verlauf, minf(s + vorlauf, laenge), seitlich)
	var nach := zielpunkt - spieler.global_position
	nach.y = 0.0
	InputHub.touch_bewegung = _eingabe(nach)

	if spieler.is_on_floor():
		if _duck_tippen(s):
			return false
		# Gesucht wird ab Fußhöhe, nicht ab der Kurve: In Terrassen liegt die
		# Decke bis 1,2 m neben ihr.
		var voraus := _punkt(verlauf, minf(s + LUECKE_VORAUS, laenge), seitlich)
		voraus.y = spieler.global_position.y
		var luecke := not _boden_bei(spieler, voraus, 1.2, LUECKE_TIEFE)
		if luecke or _huerde_voraus(spieler, nach):
			if _spruenge_melden:
				_notiz("Absprung bei %.1f m (%s, seitlich %.1f)"
						% [s, "Lücke" if luecke else "Hürde", seitlich])
			_taste_ab(KEY_SPACE)
			_sprung_halten(0.22)
		return false
	# Im Sinkflug über festem Boden, voraus aber eine Lücke: anhalten und
	# landen, statt über eine schmale Plattform hinauszufliegen (Trittsteine
	# einer Furt). Ein Mensch lässt dort den Stick los.
	if spieler.velocity.y < 0.0 \
			and _boden_bei(spieler, spieler.global_position, 0.3, 2.5):
		var danach := _punkt(verlauf, minf(s + 1.0, laenge), seitlich)
		danach.y = spieler.global_position.y
		if not _boden_bei(spieler, danach, 0.3, 3.0):
			InputHub.touch_bewegung = Vector2.ZERO
	if _doppelsprung and not djump and spieler.velocity.y < 0.5 \
			and not _boden_bei(spieler, spieler.global_position):
		if _spruenge_melden:
			_notiz("Doppelsprung bei %.1f m" % s)
		_tippe(KEY_SPACE)
		return true
	return djump


## Querlage der Lauflinie an der Stelle `s` (linear, davor und dahinter wie
## am ersten bzw. letzten Punkt).
func _linie_q(s: float) -> float:
	if s <= _lauflinie[0].x:
		return _lauflinie[0].y
	for i in _lauflinie.size() - 1:
		var a := _lauflinie[i]
		var b := _lauflinie[i + 1]
		if s <= b.x:
			return lerpf(a.y, b.y, (s - a.x) / (b.x - a.x))
	return _lauflinie[_lauflinie.size() - 1].y


## Durchlass voraus (Opt-in `duckstellen`, siehe Kopf): einmal Slide tippen,
## sobald die Figur DUCK_VORAUS vor einer Stirn ist. Nach einem Respawn vor
## der Stirn gilt sie wieder als offen.
func _duck_tippen(s: float) -> bool:
	if _duckstellen.is_empty():
		return false
	if s < _duck_zuletzt - DUCK_VORAUS - 1.0:
		_duck_zuletzt = -INF
	for stirn in _duckstellen:
		if stirn == _duck_zuletzt:
			continue
		if s >= stirn - DUCK_VORAUS and s < stirn - DUCK_SPAET:
			_duck_zuletzt = stirn
			if _spruenge_melden:
				_notiz("Slide bei %.1f m vor dem Durchlass bei %.1f m" % [s, stirn])
			_slide_tippen()
			return true
	return false


## Slide antippen wie mit der linken Umschalttaste. WARUM nicht
## `_tippe(KEY_SHIFT)`: Die Input-Map legt Slide auf die LINKE Umschalttaste
## (`location` 1, project.godot), und Godot vergleicht die Seite mit – ein
## Ereignis ohne Seite löst „slide" nicht aus (gemessen: Ort 0 → nicht
## gedrückt, Ort 1 → gedrückt). Die Slide-Angriffe in `_kampf` gehen deshalb
## ins Leere; das bleibt so, sonst liefe der Bot in anderen Leveln anders.
func _slide_tippen() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_SHIFT
	e.physical_keycode = KEY_SHIFT
	e.location = KEY_LOCATION_LEFT
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	var los := e.duplicate() as InputEventKey
	los.pressed = false
	_spaeter(0.08, func() -> void:
		Input.parse_input_event(los)
		Input.flush_buffered_events())


## Steht in Laufrichtung knapp voraus etwas in Kniehöhe, über das man
## springen muss (ein liegender Stamm, eine Stufe hinauf)? Kisten zählen
## nicht – die zerschlägt der Drehschlag –, Gegner auch nicht (`_kampf`).
## Ohne diese Probe stand der Bot in Level 01 vor dem Mooslog, bis die
## Hängerwache nach acht Sekunden einen Sprung auslöste.
func _huerde_voraus(spieler: Node3D, richtung: Vector3) -> bool:
	var flach := Vector3(richtung.x, 0.0, richtung.z)
	if flach.length_squared() < 0.0001:
		return false
	var von := spieler.global_position + Vector3.UP * HUERDE_HOEHE
	var frage := PhysicsRayQueryParameters3D.create(von,
			von + flach.normalized() * HUERDE_VORAUS, _maske(spieler), _ohne(spieler))
	frage.collide_with_areas = false
	var treffer := spieler.get_world_3d().direct_space_state.intersect_ray(frage)
	if treffer.is_empty():
		return false
	var ding: Object = treffer["collider"]
	if ding is Kiste or ding is Gegner:
		return false
	return absf((treffer["normal"] as Vector3).y) < 0.5


## Schienenmodus: nur quer lenken und über Lücken springen.
func _schiene_steuern(spieler: Node3D, verlauf: Curve3D, s: float,
		laenge: float) -> void:
	var jetzt := float(spieler.get("_seitlich"))
	var grenze := 3.0
	var wert = spieler.get("seitlich_grenze")
	if wert != null:
		grenze = float(wert)
	var ziel := _freie_spur(spieler, verlauf, s, laenge, grenze)
	var lenk := 1.0
	var lr = spieler.get("lenk_richtung")
	if lr != null:
		lenk = float(lr)
	InputHub.touch_bewegung = Vector2(
			clampf((ziel - jetzt) * 0.8, -1.0, 1.0) * lenk, 0.0)

	# Lücke voraus: die Figur rennt schnell, also früher springen
	var in_luft: bool = spieler.get("_in_luft") == true
	if not in_luft and not _boden_bei(spieler,
			_punkt(verlauf, minf(s + 7.0, laenge), jetzt)):
		_taste_ab(KEY_SPACE)
		_sprung_halten(0.25)


## Sucht die Spur voraus, in der kein Hindernis steht.
func _freie_spur(spieler: Node3D, verlauf: Curve3D, s: float, laenge: float,
		grenze: float) -> float:
	var jetzt := float(spieler.get("_seitlich"))
	# Hindernisse voraus als (Strecke, seitlicher Versatz, halbe Breite)
	var sperren: Array = []
	for ding in get_tree().get_nodes_in_group("hindernis"):
		if not (ding is Node3D):
			continue
		var gs: float = verlauf.get_closest_offset(ding.global_position)
		if gs < s + 1.0 or gs > s + 16.0:
			continue
		var mitte := verlauf.sample_baked(clampf(gs, 0.0, laenge))
		sperren.append([gs,
				(ding.global_position - mitte).dot(_rechts(verlauf, gs)),
				_hindernisbreite(ding)])

	var beste := jetzt
	var bester_wert := -1.0e9
	for i in 9:
		var kandidat := lerpf(-grenze, grenze, float(i) / 8.0)
		var wert := 0.0
		# Freie Bahn: je weiter voraus noch Boden liegt, desto besser
		for d in [4.0, 8.0, 12.0]:
			var stelle := _punkt(verlauf, minf(s + d, laenge), kandidat)
			if _boden_bei(spieler, stelle):
				wert += 10.0
			else:
				break
		# Abzug für jedes Hindernis, das diese Spur versperrt
		for sperre in sperren:
			var abstand: float = absf(kandidat - float(sperre[1]))
			var noetig: float = float(sperre[2]) + 1.0
			if abstand < noetig:
				# Nahe Hindernisse wiegen schwerer als ferne
				wert -= 60.0 * (noetig - abstand) / noetig \
						* (17.0 - float(sperre[0]) + s) / 16.0
		# Nah an der jetzigen Spur bleiben, wenn gleich gut
		wert -= absf(kandidat - jetzt) * 0.5
		if wert > bester_wert:
			bester_wert = wert
			beste = kandidat
	return beste


## Halbe Breite eines Hindernisses. Die Level bauen es als Area3D mit
## einem Kasten; ohne Form wird ein mittlerer Wert angenommen.
func _hindernisbreite(ding: Node3D) -> float:
	for kind in ding.get_children():
		if kind is CollisionShape3D and kind.shape is BoxShape3D:
			return (kind.shape as BoxShape3D).size.x * 0.5
	return 1.7


## Weicht Stacheln und Wasser voraus seitlich aus.
func _ausweichen(szene: Node, verlauf: Curve3D, s: float) -> float:
	var rand := 2.5
	if szene.has_method("breite_bei"):
		rand = maxf(float(szene.call("breite_bei", s)) * 0.5 - 1.6, 0.0)
	elif szene.has_method("_breite_bei"):
		rand = maxf(float(szene.call("_breite_bei", s)) * 0.5 - 1.6, 0.0)
	var stoerer: Array[Node] = []
	stoerer.append_array(get_tree().get_nodes_in_group("gefahren"))
	stoerer.append_array(get_tree().get_nodes_in_group("gegner"))
	var naechste := 1.0e9
	var ausweichen := 0.0
	for ding in stoerer:
		if not (ding is Node3D):
			continue
		var gs: float = verlauf.get_closest_offset(ding.global_position)
		if gs < s + 0.5 or gs > s + 9.0 or gs > naechste:
			continue
		var mitte := verlauf.sample_baked(clampf(gs, 0.0, verlauf.get_baked_length()))
		var versatz: float = (ding.global_position - mitte).dot(_rechts(verlauf, gs))
		naechste = gs
		ausweichen = clampf(-signf(versatz) * rand if absf(versatz) > 0.3 else rand,
				-rand, rand)
	return ausweichen


## Läuft geradewegs zu einer Weltposition.
func _gehe_zu(ziel: Vector3, hoechstdauer: float, nahe: float) -> bool:
	var szene := get_tree().current_scene
	var start := _uhr
	var letzter_sprung := 0.0
	var letzte_stelle := Vector3.ZERO
	var steht_seit := _uhr
	while _uhr - start < hoechstdauer:
		await get_tree().physics_frame
		if get_tree().current_scene != szene:
			return true
		var spieler := _spieler()
		if spieler == null:
			return false
		var nach := ziel - spieler.global_position
		nach.y = 0.0
		if nach.length() < nahe:
			InputHub.touch_bewegung = Vector2.ZERO
			return true
		# Steht die Figur an einer Mauer oder Säule fest, seitlich ausscheren
		if spieler.global_position.distance_to(letzte_stelle) > 1.0:
			letzte_stelle = spieler.global_position
			steht_seit = _uhr
		var seitlich := 0.0
		if _uhr - steht_seit > 1.2:
			seitlich = 1.0 if fmod(_uhr - steht_seit, 3.0) < 1.5 else -1.0
		if seitlich != 0.0:
			nach = nach.normalized() * 0.4 \
					+ nach.normalized().cross(Vector3.UP) * seitlich
		InputHub.touch_bewegung = _eingabe(nach)
		# Gegen Hängenbleiben an Kanten: ab und zu springen
		if _uhr - letzter_sprung > 2.0 and spieler.is_on_floor():
			letzter_sprung = _uhr
			_taste_ab(KEY_SPACE)
			_sprung_halten(0.2)
	InputHub.touch_bewegung = Vector2.ZERO
	return false


## Rechnet eine Weltrichtung in die Eingabe um, die der Spieler erwartet
## (er dreht sie kamerarelativ zurück).
func _eingabe(welt: Vector3) -> Vector2:
	var flach := Vector3(welt.x, 0.0, welt.z)
	if flach.length_squared() < 0.0001:
		return Vector2.ZERO
	flach = flach.normalized()
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return Vector2(flach.x, flach.z)
	var basis := kamera.global_transform.basis
	var vor := Vector3(-basis.z.x, 0.0, -basis.z.z)
	var rechts := Vector3(basis.x.x, 0.0, basis.x.z)
	if vor.length_squared() < 0.0001 or rechts.length_squared() < 0.0001:
		return Vector2(flach.x, flach.z)
	vor = vor.normalized()
	rechts = rechts.normalized()
	return Vector2(flach.dot(rechts), -flach.dot(vor)).normalized()


## Ist unter diesem Punkt fester Boden in Reichweite?
##
## Gefragt wird genau, worauf die Figur stehen kann (ihre eigene Maske,
## in Level 01 also auch Ebene 16 mit Findlingen und Wurzeln), und ohne die
## Figur selbst. Vorher traf der Strahl mit der Vorgabemaske in der Luft die
## eigene Kapsel – der Doppelsprung über einer Lücke kam dadurch nie.
func _boden_bei(spieler: Node3D, punkt: Vector3, oben: float = 3.0,
		unten: float = 4.0) -> bool:
	var raum := spieler.get_world_3d().direct_space_state
	var frage := PhysicsRayQueryParameters3D.create(
			punkt + Vector3.UP * oben, punkt + Vector3.DOWN * unten,
			_maske(spieler), _ohne(spieler))
	frage.collide_with_areas = false
	return not raum.intersect_ray(frage).is_empty()


## Die Ebenen, an denen die Figur anstößt (Vorgabe 1|16).
func _maske(spieler: Node3D) -> int:
	var koerper := spieler as CollisionObject3D
	if koerper != null and koerper.collision_mask != 0:
		return koerper.collision_mask
	return 1 | 16


## Die Figur selbst, damit kein Strahl an ihr hängen bleibt.
func _ohne(spieler: Node3D) -> Array[RID]:
	var koerper := spieler as CollisionObject3D
	if koerper == null:
		return []
	return [koerper.get_rid()]


func _punkt(verlauf: Curve3D, strecke: float, seitlich: float) -> Vector3:
	var laenge := verlauf.get_baked_length()
	var s := clampf(strecke, 0.0, laenge)
	return verlauf.sample_baked(s) + _rechts(verlauf, s) * seitlich


func _rechts(verlauf: Curve3D, strecke: float) -> Vector3:
	var laenge := verlauf.get_baked_length()
	var s := clampf(strecke, 0.0, laenge)
	var d := verlauf.sample_baked(minf(s + 0.5, laenge)) \
			- verlauf.sample_baked(maxf(s - 0.5, 0.0))
	d.y = 0.0
	if d.length() < 0.001:
		return Vector3.RIGHT
	return d.normalized().cross(Vector3.UP).normalized()


# ------------------------------------------------------------- Eingabe

## Taste drücken. Das Ereignis wird sofort ausgewertet, nicht erst mit dem
## nächsten gezeichneten Bild: Unter llvmpipe liegen bei 15 Bildern je
## Sekunde vier Physikschritte dazwischen, und der Bot sprang so bis zu
## 0,6 m später ab, als er wollte – an der Furt lief er deshalb ins Wasser.
func _taste_ab(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _taste_auf(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _tippe(code: int) -> void:
	_taste_ab(code)
	_spaeter(0.08, func() -> void: _taste_auf(code))


## Hält die Sprungtaste, damit der Sprung seine volle Höhe bekommt.
func _sprung_halten(dauer: float) -> void:
	_spaeter(dauer, func() -> void: _taste_auf(KEY_SPACE))


func _spaeter(sekunden: float, was: Callable) -> void:
	get_tree().create_timer(sekunden, true, true).timeout.connect(
			was, CONNECT_ONE_SHOT)


# ------------------------------------------------------------- Hilfen

## Trägt so viel Fortschritt ein, dass die genannten Level erreichbar sind.
##
## Ohne das prüfte der Bot nichts: Ein frisches Projekt hat nur Raum 1 offen,
## und ein Lauf mit `TEST_LEVEL=11,16,…` übersprang alles als "verschlossen" –
## der Bericht meldete trotzdem "keine Auffälligkeiten". Ein stiller Nulltest
## ist schlimmer als ein roter.
##
## Die Sperre einfach zu übergehen war der falsche Hebel: Der Portalraum
## stellt für gesperrte Räume eine echte TRENNMAUER auf, der Bot lief dagegen
## und meldete "Portal nicht erreicht". `raum_offen()` will echten
## Fortschritt sehen, also bekommt es den – jedes gebaute Level der Vorräume
## wird als geschafft eingetragen.
##
## `GameState.debug` wäre der bequeme Weg und ist trotzdem falsch: Es macht
## die Figur unverwundbar, damit zählen Treffer nicht mehr und der Durchlauf
## prüft wieder nichts.
func _fortschritt_vortaeuschen(liste: Array[int]) -> void:
	var hoechstes := 1
	for nummer in liste:
		hoechstes = maxi(hoechstes, nummer)
	Spielfluss.freigeschaltet = maxi(Spielfluss.freigeschaltet, hoechstes)

	var letzter_raum := Spielfluss.raum_von_level(hoechstes)
	for raum in range(1, letzter_raum):
		for nummer in Spielfluss.level_im_raum(raum):
			if Spielfluss.level_gebaut(nummer) and not Spielfluss.geschafft.has(nummer):
				Spielfluss.geschafft[nummer] = {
					"kisten": true, "ohne_tod": true, "fruechte": 0,
				}
	_notiz("Fortschritt gestellt: Räume 1 bis %d gelten als geschafft"
			% maxi(letzter_raum - 1, 0))


## Hat der Aufrufer die Level ausdrücklich genannt?
##
## Dann prüft der Bot sie auch, egal was der Spielstand sagt. `level_offen()`
## hängt nämlich nicht nur an der Levelfreigabe, sondern am RAUM-Fortschritt:
## Raum 3 öffnet erst, wenn Raum 2 abgeschlossen ist. Ein frisches Projekt
## hat nur Raum 1 offen, und ein Lauf mit `TEST_LEVEL=11,16,…` übersprang
## deshalb stillschweigend alles und meldete am Ende "keine Auffälligkeiten".
##
## `GameState.debug` wäre der bequeme Weg, macht die Figur aber unverwundbar
## und damit den ganzen Test wertlos – Treffer würden nicht mehr zählen.
func _ausdruecklich() -> bool:
	return not OS.get_environment("TEST_LEVEL").is_empty()


func _levelliste() -> Array[int]:
	var liste: Array[int] = []
	var vorgabe := OS.get_environment("TEST_LEVEL")
	if not vorgabe.is_empty():
		for teil in vorgabe.split(","):
			liste.append(int(teil.strip_edges()))
		return liste
	for nummer in range(1, Spielfluss.LEVEL_GESAMT + 1):
		if Spielfluss.level_gebaut(nummer):
			liste.append(nummer)
	return liste


func _spieler() -> Node3D:
	return get_tree().get_first_node_in_group("spieler") as Node3D


func _warte(sekunden: float) -> void:
	await get_tree().create_timer(sekunden, true, true).timeout


func _warte_szene(bezeichnung: String, hoechstdauer: float) -> bool:
	var start := _uhr
	while _uhr - start < hoechstdauer:
		var szene := get_tree().current_scene
		if szene != null and szene.name == bezeichnung:
			_notiz("Szene: %s" % bezeichnung)
			return true
		await get_tree().process_frame
	_notiz("FEHLER: Szene '%s' kam nicht (Wartezeit %.0f s)" % [bezeichnung, hoechstdauer])
	return false


## Wartet, bis der Ladebildschirm weg ist und die Figur in der Welt steht.
##
## Früher wurde zusätzlich ein `verlauf` verlangt. Das ist für 24 der 25
## Level richtig und für eines falsch: Das Flugniveau (Level 22) hat gar
## keine Kurve, wartete deshalb neunzig Sekunden vergebens und riss den
## ganzen Rest des Laufs mit sich – der Bot kam nie in den Portalraum
## zurück, und die Level 23 bis 25 fielen still aus dem Bericht.
func _warte_aufbau(hoechstdauer: float) -> bool:
	var start := _uhr
	while _uhr - start < hoechstdauer:
		await get_tree().process_frame
		var szene := get_tree().current_scene
		if szene == null:
			continue
		if not Ladeschirm.ist_sichtbar() and _spieler() != null:
			return true
	return false


func _finde_knoten(wurzel: Node, bezeichnung: String) -> Node3D:
	if wurzel == null:
		return null
	for kind in wurzel.get_children():
		if kind.name == bezeichnung and kind is Node3D:
			return kind
		var treffer := _finde_knoten(kind, bezeichnung)
		if treffer != null:
			return treffer
	return null


func _bild(bezeichnung: String) -> void:
	await RenderingServer.frame_post_draw
	var bild := get_viewport().get_texture().get_image()
	_nr += 1
	var name := "%s/%03d_%s.png" % [_ziel, _nr, bezeichnung]
	if bild.save_png(name) != OK:
		_notiz("FEHLER: Bild ließ sich nicht speichern: %s" % name)


func _notiz(text: String) -> void:
	print("TEST: [%6.1f s] %s" % [_uhr, text])


func _ende() -> void:
	InputHub.touch_bewegung = Vector2.ZERO
	print("TEST-BERICHT-ANFANG")
	print("Gesamtzeit: %.0f s, Tode insgesamt: %d, Bilder: %d" % [_uhr, _tote, _nr])
	for e in _ergebnisse:
		if e.has("laenge"):
			print("Level %02d: %-16s %4.0f / %4.0f m | %5.1f s | Tode %d | Kisten %d/%d | Früchte %d"
					% [e["nummer"], e["stand"], e["weit"], e["laenge"],
					float(e.get("dauer", 0.0)), e["tode"],
					e["kisten"], e["kisten_gesamt"], e["fruechte"]])
		else:
			print("Level %02d: %s" % [e["nummer"], e["stand"]])
	print("Freigeschaltet bis Level: %d" % Spielfluss.freigeschaltet)
	print("Geschafft: %s" % str(Spielfluss.geschafft.keys()))
	if _fehler.is_empty():
		print("Keine Auffälligkeiten")
	else:
		for f in _fehler:
			print("AUFFÄLLIG: %s" % f)
	print("TEST-BERICHT-ENDE")
	get_tree().quit()


func _wachhund() -> void:
	var dauer := 600.0
	if not OS.get_environment("TEST_DAUER").is_empty():
		dauer = float(OS.get_environment("TEST_DAUER"))
	await get_tree().create_timer(dauer, true, true).timeout
	_notiz("FEHLER: Höchstdauer %.0f s erreicht – Abbruch" % dauer)
	_fehler.append("Höchstdauer erreicht, Test abgebrochen")
	_ende()
