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
##                   (Reiter, Flüchtling, Rennfahrer; Level 04–06).
##                   Erkannt an der Eigenschaft `strecke` der Figur.
##
## Lücken erkennt der Bot per Strahltest nach unten, nicht aus den
## Leveldaten – so prüft er gleichzeitig, ob die Kollisionsgeometrie da ist.
##
## Umgebungsvariablen:
##   TEST_ZIEL   Ausgabeverzeichnis für die PNGs (Pflicht)
##   TEST_DAUER  Höchstdauer in Sekunden (Vorgabe 600)
##   TEST_LEVEL  Levelnummern mit Komma getrennt (Vorgabe: alle gebauten)

const KEY_SPACE := 32
const KEY_J := 74
const KEY_SHIFT := 4194325
const KEY_AB := 4194322
const KEY_AUF := 4194320

## Mittelpunkt des Halbkreises im Portalraum (hub.gd: BOGEN_MITTE).
const BOGEN_MITTE := Vector3(0.0, 0.0, 36.0)
const HALLE_RADIUS := 33.5      ## hub.gd: START_R

const VORAUS := 5.0             ## Zielpunkt so viele Meter voraus
const LUECKE_VORAUS := 4.2      ## so weit voraus wird auf Boden geprüft
const BILD_ABSTAND := 4.0       ## Sekunden zwischen zwei Spielbildern
const LEVEL_DAUER := 150.0      ## Höchstdauer je Level

var _ziel := ""
var _nr := 0
var _uhr := 0.0
var _ergebnisse: Array[Dictionary] = []
var _fehler: Array[String] = []
var _tote := 0
var _aktuelles_bild := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ziel = OS.get_environment("TEST_ZIEL")
	if _ziel.is_empty():
		_ziel = "/tmp/spieltest"
	DirAccess.make_dir_recursive_absolute(_ziel)

	GameState.nachricht.connect(func(text: String, _d: float) -> void:
		_notiz("Meldung: %s" % text))
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

	for nummer in _levelliste():
		if not await _warte_szene("Hub", 40.0):
			_fehler.append("Level %02d: Portalraum kam nicht" % nummer)
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
	# Erst in die Hallenmitte vor dem Raum, dann zum Portal – sonst läuft
	# der Bot bei den hinteren Räumen gegen eine Trennmauer.
	var richtung := (portal.global_position - BOGEN_MITTE)
	richtung.y = 0.0
	var vorplatz := BOGEN_MITTE + richtung.normalized() * HALLE_RADIUS
	await _gehe_zu(vorplatz, 25.0, 2.0)
	if not await _gehe_zu(portal.global_position, 25.0, 0.6):
		_fehler.append("Level %02d: Portal nicht erreicht" % nummer)
		await _bild("level%02d_portal_verfehlt" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "Portal nicht erreicht"})
		return

	if not await _warte_szene("Level%02d" % nummer, 30.0):
		_fehler.append("Level %02d: Szene wurde nicht geladen" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "nicht geladen"})
		return
	var start_aufbau := _uhr
	if not await _warte_aufbau(90.0):
		_fehler.append("Level %02d: Aufbau nicht fertig geworden" % nummer)
		_ergebnisse.append({"nummer": nummer, "stand": "Aufbau hängt"})
		return
	_notiz("Level %02d steht (Aufbau %.1f s)" % [nummer, _uhr - start_aufbau])
	await _warte(0.8)
	await _bild("level%02d_start" % nummer)

	var ergebnis := await _durchlaufen(nummer)
	_ergebnisse.append(ergebnis)


## Läuft ein Level bis zum Ende ab.
func _durchlaufen(nummer: int) -> Dictionary:
	var szene := get_tree().current_scene
	var verlauf: Curve3D = szene.get("verlauf")
	if verlauf == null:
		_fehler.append("Level %02d: kein Verlauf vorhanden" % nummer)
		return {"nummer": nummer, "stand": "kein Verlauf"}
	var laenge := verlauf.get_baked_length()
	var spieler := _spieler()
	var schiene: bool = spieler != null and spieler.get("strecke") != null
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

		if schiene:
			_schiene_steuern(spieler, verlauf, s, laenge)
		else:
			djump = _laufen(spieler, szene, verlauf, s, laenge, djump)

		if _uhr - letzter_spin > 0.7:
			letzter_spin = _uhr
			_tippe(KEY_J)

		if GameState.leben != leben_vorher:
			if GameState.leben < leben_vorher:
				tode += 1
				_tote += 1
				if tode <= 6:
					await _bild("level%02d_tod%d_bei_%dm" % [nummer, tode, int(s)])
			leben_vorher = GameState.leben
			if tode >= 12:
				_fehler.append("Level %02d: 12 Tode bei %.0f von %.0f m - abgebrochen"
						% [nummer, s, laenge])
				stand = "zu viele Tode"
				break

		# Hänger erkennen: die Figur bewegt sich nicht mehr vom Fleck.
		# (Am Streckenbesten festgemacht schlüge das nach jedem Tod an,
		#  weil der Respawn zurücksetzt.)
		if spieler.global_position.distance_to(letzte_pos) > 1.5:
			letzte_pos = spieler.global_position
			letzter_fortschritt = _uhr
		if _uhr - letzter_fortschritt > 5.0:
			haenger += 1
			_notiz("Level %02d: Hänger bei %.0f m (%d.)" % [nummer, s, haenger])
			_taste_ab(KEY_SPACE)
			_sprung_halten(0.25)
			letzter_fortschritt = _uhr
			if haenger >= 5:
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
	}


# ------------------------------------------------------------- Steuerung

## Laufmodus: dem Verlauf folgen, vor Lücken springen.
func _laufen(spieler: Node3D, szene: Node, verlauf: Curve3D, s: float,
		laenge: float, djump: bool) -> bool:
	var seitlich := _ausweichen(szene, verlauf, s)
	var zielpunkt := _punkt(verlauf, minf(s + VORAUS, laenge), seitlich)
	var nach := zielpunkt - spieler.global_position
	nach.y = 0.0
	InputHub.touch_bewegung = _eingabe(nach)

	if spieler.is_on_floor():
		if not _boden_bei(spieler, _punkt(verlauf, minf(s + LUECKE_VORAUS, laenge), seitlich)):
			_taste_ab(KEY_SPACE)
			_sprung_halten(0.22)
		return false
	if not djump and spieler.velocity.y < 0.5 \
			and not _boden_bei(spieler, spieler.global_position):
		_tippe(KEY_SPACE)
		return true
	return djump


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
func _boden_bei(spieler: Node3D, punkt: Vector3) -> bool:
	var raum := spieler.get_world_3d().direct_space_state
	var frage := PhysicsRayQueryParameters3D.create(
			punkt + Vector3.UP * 3.0, punkt + Vector3.DOWN * 4.0)
	frage.collide_with_areas = false
	return not raum.intersect_ray(frage).is_empty()


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

func _taste_ab(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)


func _taste_auf(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = false
	Input.parse_input_event(e)


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


## Wartet, bis der Ladebildschirm weg ist und ein Weg vorhanden ist.
func _warte_aufbau(hoechstdauer: float) -> bool:
	var start := _uhr
	while _uhr - start < hoechstdauer:
		await get_tree().process_frame
		var szene := get_tree().current_scene
		if szene == null:
			continue
		if not Ladeschirm.ist_sichtbar() and szene.get("verlauf") != null:
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
			print("Level %02d: %-16s %4.0f / %4.0f m | Tode %d | Kisten %d/%d | Früchte %d"
					% [e["nummer"], e["stand"], e["weit"], e["laenge"], e["tode"],
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
