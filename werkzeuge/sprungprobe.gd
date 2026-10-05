extends Node
## Sprungprobe: Tragen die Pflichtsprünge eines Levels? (Plan P14)
##
## Aufruf (macht `pruefe.sh` in Stufe 4 für jedes Level, das mitmacht, und
## im vollen Lauf für die Werkstatt):
##   godot --headless --fixed-fps 60 --path . res://werkzeuge/Sprungprobe.tscn \
##       -- res://scenes/levels/Level01.tscn
## Mit `--fixed-fps 60` ist jedes Bild genau ein Physikschritt: Die Probe
## läuft so schnell, wie der Rechner rechnet, und misst bei jedem Lauf
## dasselbe. Ohne den Schalter liefe sie in Echtzeit (rund drei Minuten).
##
## OPT-IN wie die Proben in `level_check.gd`: Geprüft wird nur ein Level,
## das `sprungfaelle() -> Array[Dictionary]` anbietet. Alle anderen melden
## sich ohne Prüfung ab.
##
## Gemessen wird der Mensch, der einfach durchläuft: Die echte Figur rennt
## mit vollem Tempo auf die Lücke zu und springt an einer festen Stelle ab,
## Taste gehalten, Richtung gehalten, kein Doppelsprung. Eine Reihe von
## Absprungstellen im Abstand von 0,25 m ergibt das ABSPRUNGFENSTER: die
## zusammenhängenden Stellen um die Kante, von denen aus die Figur auf
## festem Boden landet (nicht tot, nicht tiefer als 1,5 m unter dem
## Absprung). Gegner gibt es dabei nicht – die Probe misst Sprünge, keine
## Kämpfe.
##
## FEHLER, wenn
##   * der Absprung an der KANTE nicht trägt: Wer bis an den Rand läuft
##     und dort springt wie an jeder anderen Lücke, darf nicht sterben. So
##     ertrank man an der Furt (Welle 6: Kantensprung hinter den ersten
##     Stein, vom Rand des ersten Steins in die Lücke vor dem Ufer);
##   * das Fenster kürzer ist als FENSTER_MIN (1,25 m, gut 0,15 s Lauf).
## Ausgabe je Stelle: "+<s>" gelandet bei s, "x" tot oder in die Lücke
## gefallen, "k" zu kurz (vor `landung`), "?" nie abgesprungen oder nie
## gelandet (etwa vor dem Mooslog hängen geblieben).
##
## Ein Fall (Dictionary aus `sprungfaelle()`):
##   name      Bezeichnung in der Ausgabe
##   start     Vector2(s, q): hier wird die Figur abgesetzt
##   kante     s der Absprungkante (Ende des Bodens, Rand des Steins)
##   von       erste Absprungstelle (s); die Reihe läuft von der Kante in
##             Schritten von 0,25 m bis hierher zurück, dazu eine Stelle
##             0,25 m hinter der Kante (die Figur steht dort noch mit dem
##             Rand ihrer Kapsel)
##   ziel      optional Vector2(s, q): geradewegs auf diesen Punkt zu (und
##             darüber hinaus) statt dem Weg entlang auf der Querlage von
##             `start` – für Diagonalen von Stein zu Stein
##   landung   optional: s, ab dem eine Landung zählt (die andere Seite der
##             Lücke). Wer davor aufkommt – auf einem Wulst in der Lücke,
##             am Fuß der Gegenwand –, ist nicht hinübergekommen, auch wenn
##             er nicht stirbt ("k" in der Ausgabe).
## Die Absprungstellen zählen als Strecke `s` auf dem Levelverlauf, auch
## auf der Diagonale.
##
## ARTEN (Feld `art`, Baukasten Raum 1 §1.7). Ohne `art` läuft ein Fall
## genau wie oben beschrieben – das ist `einfach`, und die Fälle von
## Level 01 tragen kein Feld, ihre Ausgabe bleibt Zeile für Zeile dieselbe.
##   einfach       Sprung an der Stelle, Taste gehalten (Vorgabe)
##   doppel        dazu ein Doppelsprung `doppel_t` Sekunden nach dem
##                 Absprung. Die Taste geht EIN Bild vorher los und wird
##                 dann neu gedrückt – wie bei einem Menschen, der zweimal
##                 drückt; der Jump-Cut greift dabei, wo er greift. Je Zeit
##                 eine eigene Reihe "<name> @0.20s"
##   slide         Slide `slide_vor` m vor der Stelle angetippt, an der Stelle
##                 gesprungen (aus dem Slide heraus: Slide-Sprung)
##   slide_doppel  beides: Slide, Slide-Sprung, Doppelsprung
##   duck          Slide an der Stelle angetippt, vor einem Duckdurchlass
##                 (`kante` = seine Stirn). Gut ist nur ein Versuch, der ohne
##                 Stolpern UND ohne Krabbeln bis `landung` kommt; "+<s>"
##                 nennt dort, wo der Slide endete. "s" gestolpert, "c" durch,
##                 aber gekrabbelt (Zwangskrabbeln, weil der Slide unter dem
##                 Riegel ausging)
##   huerde        Sprung an der Stelle über eine Stolperzone (`kante` = ihre
##                 Vorderkante); gut, wer ohne Stolpern bis `landung` kommt,
##                 "+<s>" nennt die Landung. Wer zu kurz springt, landet davor
##                 und läuft hinein ("s")
##   ueberlauf     kein Sprung: von `start` bis `bis` laufen und lebend
##                 ankommen (Wechten, Bruchplatten). Ein Versuch, kein Fenster.
##                 Angekommen ist nur, wer dort nicht tiefer als `tief_erlaubt`
##                 unter dem Boden am Ziel steht – der wird vor dem Lauf unter
##                 (`bis`, Querlage von `start`) gemessen wie beim Absetzen,
##                 mit einem Strahl von 4 m über der Kurve: `bis` also nicht
##                 unter eine Brücke legen, sonst gilt deren Oberseite. Wer
##                 durchbricht und unten weiterläuft, ist "x"; ein Weg, der
##                 bergab führt, zählt dagegen nicht als Sturz
##   bewegt        wie einfach, aber gelandet ist erst, wer danach `halt`
##                 Bilder mit gehaltenem Stick auf dem Boden bleibt – auf
##                 einem Floß rutscht man sonst nach der Landung über den Rand
## Bei duck und huerde muss nicht die Kante tragen (dort stolpert jeder);
## das Fenster sind die zusammenhängenden guten Stellen um die letzte gute
## vor der Kante, und die Reihe endet an der Kante.
##
## Weitere Felder, alle freiwillig:
##   schritt           Abstand der Absprungstellen (Vorgabe 0,25). Hinter der
##                     Kante reicht die Reihe immer HINTER_KANTE weit. Feiner
##                     als 0,25 nur zum Messen gegen gerechnete Fenster – die
##                     Entwürfe rechnen mit 0,05 m
##   fenster_min       Vorgabe FENSTER_MIN (1,25)
##   tief_erlaubt      so tief unter dem Absprung zählt eine Landung noch
##                     (Vorgabe ZU_TIEF, 1,5): Fangleisten unter einer Lücke.
##                     Bei ueberlauf: so tief unter dem Boden am Ziel
##   pflicht           false: Kür. Mängel stehen als "KÜR" da und zählen nicht
##   darf_nicht_tragen true: FEHLER, sobald irgendeine Stelle trägt (die Lücke,
##                     über die man nur mit dem Doppelsprung kommt); kein Fenster
##   doppel_t          Sekunden bis zum Doppelsprung, Vorgabe DOPPEL_T
##   slide_vor         Vorgabe SLIDE_VOR (2,0 m, wie die Messbank von L05)
##   halt              Bilder nach der Landung, Vorgabe HALT_BEWEGT bei
##                     `bewegt`, sonst 0 (sofort loslassen, wie bisher)
##   bis               nur ueberlauf: Ziel der Strecke (Vorgabe `kante`)
## Für duck und huerde ist `landung` das Ziel hinter dem Hindernis (Vorgabe
## `kante` + 3).
##
## RUHE. Vor jedem Versuch ruft die Probe `pruefruhe()` des Levels, wenn es
## eine hat: Sie hält an, was von selbst läuft (Keiler, Taktgefahren, eine
## Stromuhr auf festem Wert). Der Aufruf kommt ein Bild nach dem Ende des
## vorigen Versuchs, also NACH dem `nach_tod` eines Todes – was ein Level
## dort neu startet, hält `pruefruhe` gleich wieder an. Was `nach_tod` erst
## Bilder später anstößt (Timer, await), kommt danach und muss von
## `pruefruhe` selbst abgefangen werden. Mehrmals hintereinander gerufen
## werden darf `pruefruhe` ohnehin (LevelCheck tut das).
## Jeder Fall mit Feld `art` – auch `"art": "einfach"` – setzt dazu die
## Figur still (`_beruhigen`): Nach einem Tod ist sie 1,2 s unverwundbar,
## `Spieler.stolpern()` übergeht einen Unverwundbaren, `schaden_nehmen()`
## ebenso – der nächste Versuch an einer Hürde liefe sonst glatt durch, ein
## Sprung in Stacheln zählte als Landung. Fälle ohne `art` (Level 01)
## lassen das wie bisher und messen Zeile für Zeile gleich.

const SCHRITT := 0.25
const FENSTER_MIN := 1.25
## Tiefer als das unter dem Absprung gelandet: in die Lücke gefallen.
const ZU_TIEF := 1.5
## Längster Versuch in Physikschritten (10 s).
const VERSUCH_MAX := 600
## Bodenstrahl beim Absetzen: fester Boden und Spielergrenze.
const BODEN_MASKE := 1 | LevelWerkzeuge.SPIELERGRENZE
## So weit reicht die Reihe hinter die Kante (die Figur steht dort noch mit
## dem Rand ihrer Kapsel). Bei `schritt` 0,25 genau die eine Stelle von früher.
const HINTER_KANTE := 0.25
## Die Arten (siehe Kopf).
const ARTEN: Array[String] = ["einfach", "doppel", "slide", "slide_doppel", "duck",
		"huerde", "ueberlauf", "bewegt"]
## Doppelsprung so viele Sekunden nach dem Absprung (Entwurf L02 §2: 0,20 ist
## der Fall, auf den die Pflichtlücken gerechnet sind, 0,33 der Scheitel).
const DOPPEL_T: Array[float] = [0.20, 0.25, 0.33]
## Slide so weit vor dem Absprung angetippt (Messbank L05).
const SLIDE_VOR := 2.0
## Bilder mit gehaltenem Stick nach der Landung auf einem bewegten Träger
## (Entwurf L03: Wer landet, läuft weiter – zehn Bilder muss das Deck tragen).
const HALT_BEWEGT := 10
## Ohne `landung` liegt das Ziel hinter Durchlass oder Hürde so weit hinter
## der Kante.
const DURCHGANG_ZIEL := 3.0

var _level: Node
var _spieler: CharacterBody3D
var _verlauf: Curve3D
var _tot := false
var _fehler := 0


func _ready() -> void:
	var pfad := "res://scenes/levels/Level01.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			pfad = arg
	# Die Probe misst immer dieselbe Fassung, egal was in `user://` steht.
	Zeitlauf.aktiv = false
	_level = (load(pfad) as PackedScene).instantiate()
	var fertig := [false]
	if _level.has_signal("aufbau_fertig"):
		_level.connect("aufbau_fertig", func() -> void: fertig[0] = true)
	else:
		fertig[0] = true
	add_child(_level)
	var name_kurz := pfad.get_file().get_basename()
	if not _level.has_method("sprungfaelle"):
		print("=== Sprungprobe %s: keine Sprungfälle (nicht angemeldet) ===" % name_kurz)
		get_tree().quit(0)
		return
	var gewartet := 0
	while not fertig[0] and gewartet < 3600:
		gewartet += 1
		await get_tree().physics_frame
	_spieler = get_tree().get_first_node_in_group("spieler") as CharacterBody3D
	var verlauf: Variant = _level.get("verlauf")
	if _spieler == null or not verlauf is Curve3D:
		print("  FEHLER  Sprungprobe: keine Figur oder kein Levelverlauf")
		get_tree().quit(1)
		return
	_verlauf = verlauf as Curve3D
	_spieler.connect("gestorben", func() -> void: _tot = true)
	for g in get_tree().get_nodes_in_group("gegner"):
		g.queue_free()
	for f in 3:
		await get_tree().physics_frame

	print("=== Sprungprobe %s ===" % name_kurz)
	var faelle: Array = _level.call("sprungfaelle")
	if faelle.is_empty():
		# Angemeldet, aber nichts geliefert: Das ist ein Fehler im Level
		# (oder ein Skriptfehler in `sprungfaelle`), kein Freispruch.
		_fehler += 1
		print("  FEHLER  sprungfaelle() lieferte keinen einzigen Fall")
	for fall: Dictionary in faelle:
		await _fall_pruefen(fall)
	print("=== Sprungprobe: %d Fälle, %d Fehler ===" % [faelle.size(), _fehler])
	get_tree().quit(1 if _fehler > 0 else 0)


## Ein Fall: je nach Art eine Reihe, eine Reihe je Doppelsprungzeit oder
## (Überlauf) ein einzelner Versuch.
func _fall_pruefen(fall: Dictionary) -> void:
	var art: String = fall.get("art", "einfach")
	if not ARTEN.has(art):
		_fehler += 1
		print("  FEHLER  %s: unbekannte Art \"%s\"" % [String(fall.get("name", "?")), art])
		return
	if art == "ueberlauf":
		await _ueberlauf_pruefen(fall)
		return
	if art == "doppel" or art == "slide_doppel":
		var zeiten: Array = fall.get("doppel_t", DOPPEL_T)
		for t: Variant in zeiten:
			await _reihe_pruefen(fall, art, float(t))
		return
	await _reihe_pruefen(fall, art, -1.0)


## Eine Reihe von Absprungstellen und ihr Fenster. `doppel_t` < 0: ohne
## Doppelsprung.
func _reihe_pruefen(fall: Dictionary, art: String, doppel_t: float) -> void:
	var name: String = fall["name"]
	if doppel_t >= 0.0:
		name = "%s @%.2fs" % [name, doppel_t]
	var kante: float = fall["kante"]
	var von: float = fall["von"]
	var schritt: float = fall.get("schritt", SCHRITT)
	var pflicht: bool = fall.get("pflicht", true)
	# Durchlass und Hürde: Wer an der Kante drückt, stolpert immer – die
	# Reihe endet dort, und nicht die Kante muss tragen.
	var durchgang := art == "duck" or art == "huerde"
	# Stellen: hinter der Kante, die Kante, dann zurück bis `von`.
	var stellen: Array[float] = []
	if not durchgang:
		for i in range(roundi(HINTER_KANTE / schritt), 0, -1):
			stellen.append(kante + schritt * float(i))
	stellen.append(kante)
	var s := kante - schritt
	while s >= von - 0.001:
		stellen.append(s)
		s -= schritt
	stellen.reverse()
	var zeile := "SPRUNG %-24s" % name
	var gut: Array[bool] = []
	for stelle in stellen:
		var ergebnis := await _versuch(fall, art, stelle, doppel_t)
		zeile += " %.2f%s" % [stelle, ergebnis]
		gut.append(ergebnis.begins_with("+"))
	print(zeile)
	if bool(fall.get("darf_nicht_tragen", false)):
		var tragend: Array[String] = []
		for i in stellen.size():
			if gut[i]:
				tragend.append("%.2f" % stellen[i])
		if tragend.is_empty():
			print("SPRUNG %-24s trägt an keiner Stelle, wie verlangt" % name)
		else:
			_melden(pflicht, "%s: trägt bei %s, darf aber nicht tragen"
					% [name, ", ".join(tragend)])
		return
	# Fenster: die zusammenhängenden tragenden Stellen um die Kante – bei
	# Durchlass und Hürde um die letzte gute Stelle davor.
	var anker := stellen.find(kante)
	if durchgang:
		anker = gut.rfind(true)
		if anker < 0:
			_melden(pflicht, "%s: Kein Versuch kommt sauber hindurch" % name)
			return
	elif not gut[anker]:
		_melden(pflicht, "%s: Der Absprung an der Kante (s %.2f) trägt nicht" % [name, kante])
		return
	var a := anker
	while a > 0 and gut[a - 1]:
		a -= 1
	var b := anker
	while b < stellen.size() - 1 and gut[b + 1]:
		b += 1
	var weite := stellen[b] - stellen[a]
	var bis_rand := " (ganze Reihe)" if a == 0 else ""
	var fenster_min: float = fall.get("fenster_min", FENSTER_MIN)
	if weite < fenster_min - 0.001:
		_melden(pflicht, "%s: Absprungfenster %.2f – %.2f nur %.2f m (mindestens %.2f)"
				% [name, stellen[a], stellen[b], weite, fenster_min])
		return
	var ende := "Kante %.2f trägt" % kante
	if durchgang:
		ende = "Kante %.2f" % kante
	# Mit `art` dazu die Lage zur Kante – so stehen die Fenster in den
	# Entwürfen. Die Fälle von Level 01 haben kein `art` und bleiben gleich.
	if fall.has("art"):
		ende += ", zur Kante %+.2f … %+.2f" % [stellen[a] - kante, stellen[b] - kante]
	print("SPRUNG %-24s Fenster %.2f – %.2f (%.2f m%s), %s" % [name,
			stellen[a], stellen[b], weite, bis_rand, ende])


## Überlauf: ein Versuch ohne Sprung, von `start` bis `bis`.
func _ueberlauf_pruefen(fall: Dictionary) -> void:
	var name: String = fall["name"]
	var start: Vector2 = fall["start"]
	var bis: float = fall.get("bis", fall.get("kante", start.x))
	var ergebnis := await _versuch(fall, "ueberlauf", INF, -1.0)
	print("SPRUNG %-24s Überlauf %.2f → %.2f: %s" % [name, start.x, bis, ergebnis])
	if not ergebnis.begins_with("+"):
		_melden(bool(fall.get("pflicht", true)),
				"%s: Wer ohne Sprung von %.2f bis %.2f läuft, kommt nicht an (%s)"
				% [name, start.x, bis, ergebnis])


## Mangel melden: als FEHLER, bei `pflicht: false` als Kür ohne Folgen.
func _melden(pflicht: bool, text: String) -> void:
	if pflicht:
		_fehler += 1
		print("  FEHLER  " + text)
	else:
		print("  KÜR     " + text + " (keine Pflicht)")


## Ein Versuch: bei `start` absetzen, anlaufen, bei `absprung` springen
## (Arten: siehe Kopf). Rückgabe wie im Kopf beschrieben ("+<s>", "x",
## "k", "?", dazu "s" und "c" bei Durchlass und Hürde).
func _versuch(fall: Dictionary, art: String, absprung: float, doppel_t: float) -> String:
	var start: Vector2 = fall["start"]
	var ziel: Vector2 = fall.get("ziel", Vector2(NAN, NAN))
	var landung: float = fall.get("landung", -INF)
	var tief: float = fall.get("tief_erlaubt", ZU_TIEF)
	var halt := int(fall.get("halt", HALT_BEWEGT if art == "bewegt" else 0))
	var durchgang := art == "duck" or art == "huerde"
	# Wo der Versuch zu Ende ist, wenn nicht mit der Landung: hinter dem
	# Hindernis bzw. am Ende des Überlaufs.
	var ziel_s := INF
	if durchgang:
		ziel_s = fall.get("landung", float(fall["kante"]) + DURCHGANG_ZIEL)
	elif art == "ueberlauf":
		ziel_s = fall.get("bis", fall.get("kante", start.x))
	var mit_sprung := art != "duck" and art != "ueberlauf"
	var mit_slide := art == "slide" or art == "slide_doppel" or art == "duck"
	var slide_ab := absprung
	if art == "slide" or art == "slide_doppel":
		slide_ab = absprung - float(fall.get("slide_vor", SLIDE_VOR))
	# Doppelsprung: so viele Bilder nach dem Absprung, losgelassen eins vorher.
	var doppel_bild := -1
	if doppel_t >= 0.0:
		doppel_bild = maxi(roundi(doppel_t * Engine.physics_ticks_per_second), 2)

	if _level.has_method("pruefruhe"):
		# Erst ein Bild abwarten: Nach einem Tod läuft der Rücksetzer des
		# Levels aufgeschoben (`LevelBasis._auf_zuruecksetzen`), also erst
		# NACH dem Ende des vorigen Versuchs – und `nach_tod` darf die Ruhe
		# wieder aufheben. Ohne das Bild hob `nach_tod` die Ruhe nach jedem
		# Tod wieder auf, bevor der Versuch begann (gemessen: im selben
		# Physikbild nach `pruefruhe`). Nur in diesem Zweig, damit Level 01
		# Bild für Bild gleich läuft.
		await get_tree().physics_frame
		_level.call("pruefruhe")
	InputHub.zuruecksetzen()
	GameState.leben = 50
	_spieler.set("can_djump", false)
	if fall.has("art"):
		_beruhigen()
	_spieler.velocity = Vector3.ZERO
	_spieler.global_position = _abstellen(start)
	_spieler.reset_physics_interpolation()
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")
	for f in 10:
		await get_tree().physics_frame
	# Diagonale: Richtung auf einen Punkt weit hinter dem Ziel, damit sie
	# sich nicht umkehrt, wenn die Figur das Ziel überfliegt.
	var fern := Vector3.INF
	if not is_nan(ziel.x):
		var a := LevelWerkzeuge.punkt_frei(_verlauf, start.x, start.y)
		var b := LevelWerkzeuge.punkt_frei(_verlauf, ziel.x, ziel.y)
		var richtung := b - a
		richtung.y = 0.0
		fern = a + richtung.normalized() * 60.0
	_tot = false
	# Überlauf: der Boden am Ziel, gemessen, bevor unterwegs etwas bricht.
	var y_ziel := NAN
	if art == "ueberlauf":
		y_ziel = _abstellen(Vector2(ziel_s, start.y)).y
	var gesprungen := false
	var in_luft := false
	var y_start := _spieler.global_position.y
	var sprung_bild := -1
	var slide_bild := -1
	var slide_ende := NAN
	var s_land := NAN
	var gekrabbelt := false
	# >= 0: gelandet, der Stick bleibt noch so viele Bilder gehalten.
	var halt_rest := -1
	for f in VERSUCH_MAX:
		var s := _verlauf.get_closest_offset(_spieler.global_position)
		var hin := fern
		if fern == Vector3.INF:
			hin = LevelWerkzeuge.punkt_frei(_verlauf, s + 3.0, start.y)
		var d := hin - _spieler.global_position
		d.y = 0.0
		InputHub.touch_bewegung = _eingabe_fuer(d.normalized())
		if mit_slide:
			# Angetippt, nicht gehalten: Wer die Taste hält, krabbelt nach
			# dem Slide weiter (player.gd, `_kriechen_pruefen`).
			if slide_bild < 0 and s >= slide_ab and _spieler.is_on_floor():
				InputHub.touch_slide(true)
				slide_bild = f
			elif slide_bild >= 0 and f == slide_bild + 1:
				InputHub.touch_slide(false)
		if mit_sprung and not gesprungen and s >= absprung and _spieler.is_on_floor():
			InputHub.touch_sprung(true)
			gesprungen = true
			sprung_bild = f
			y_start = _spieler.global_position.y
		elif doppel_bild > 0 and gesprungen:
			if f == sprung_bild + doppel_bild - 1:
				InputHub.touch_sprung(false)
			elif f == sprung_bild + doppel_bild and not _spieler.is_on_floor():
				InputHub.touch_sprung(true)
		await get_tree().physics_frame
		if _tot:
			InputHub.zuruecksetzen()
			return "x"
		if durchgang and _stolpert():
			InputHub.zuruecksetzen()
			return "s"
		if slide_bild >= 0 and is_nan(slide_ende) and not _gleitet():
			slide_ende = _verlauf.get_closest_offset(_spieler.global_position)
		if _krabbelt():
			gekrabbelt = true
		if halt_rest >= 0:
			if _spieler.global_position.y < y_start - tief:
				InputHub.zuruecksetzen()
				return "x"
			halt_rest -= 1
			if halt_rest == 0:
				InputHub.zuruecksetzen()
				return ("+%.1f" % s_land) if _spieler.is_on_floor() else "x"
			continue
		if gesprungen and not _spieler.is_on_floor():
			in_luft = true
		if in_luft and _spieler.is_on_floor():
			if durchgang or halt > 0:
				# Gelandet, aber noch nicht fertig: hinter dem Hindernis
				# ankommen bzw. den Stick noch halten.
				in_luft = false
				InputHub.touch_sprung(false)
				if _spieler.global_position.y < y_start - tief:
					InputHub.zuruecksetzen()
					return "x"
				s_land = _verlauf.get_closest_offset(_spieler.global_position)
				if not durchgang:
					if s_land < landung:
						InputHub.zuruecksetzen()
						return "k"
					halt_rest = halt
					continue
			else:
				InputHub.zuruecksetzen()
				if _spieler.global_position.y < y_start - tief:
					return "x"
				var s_auf := _verlauf.get_closest_offset(_spieler.global_position)
				if s_auf < landung:
					return "k"
				return "+%.1f" % s_auf
		# Angekommen ist, wer hinter dem Ziel wieder auf den Beinen steht –
		# ein Slide, der über das Ziel hinausträgt, läuft erst aus.
		if ziel_s < INF and _spieler.is_on_floor() and not _krabbelt() and not _gleitet() \
				and _verlauf.get_closest_offset(_spieler.global_position) >= ziel_s:
			InputHub.zuruecksetzen()
			if gekrabbelt:
				return "c"
			if art == "duck":
				return "+%.1f" % slide_ende
			if art == "huerde":
				return "+%.1f" % s_land
			if _spieler.global_position.y < y_ziel - tief:
				# Unter dem Ziel angekommen: durchgebrochen, unten weiter.
				return "x"
			return "+%.1f" % _verlauf.get_closest_offset(_spieler.global_position)
		if _spieler.global_position.y < y_start - maxf(4.0, tief + 1.0):
			InputHub.zuruecksetzen()
			return "x"
	InputHub.zuruecksetzen()
	return "?"


## Figur still setzen (nur Fälle mit `art`, siehe Kopf unter RUHE).
func _beruhigen() -> void:
	for feld: String in ["invuln", "_stolpern", "sliding", "spinning"]:
		_spieler.set(feld, 0.0)
	_spieler.set("slamming", false)
	_spieler.set("kriechen", false)


## Stolpert die Figur gerade? `Spieler._stolpern` ist die Restzeit; ein
## eigenes Signal gibt es nicht, und die Probe soll player.gd nicht ändern.
func _stolpert() -> bool:
	var rest: Variant = _spieler.get("_stolpern")
	return rest is float and float(rest) > 0.0


func _gleitet() -> bool:
	var rest: Variant = _spieler.get("sliding")
	return rest is float and float(rest) > 0.0


func _krabbelt() -> bool:
	return _spieler.get("kriechen") == true


## Fußpunkt auf dem Boden unter (s, q): Bodenstrahl von 4 m darüber.
func _abstellen(sq: Vector2) -> Vector3:
	var p := LevelWerkzeuge.punkt_frei(_verlauf, sq.x, sq.y)
	var anfrage := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 4.0,
			p + Vector3.DOWN * 4.0, BODEN_MASKE, [_spieler.get_rid()])
	var treffer := get_viewport().world_3d.direct_space_state.intersect_ray(anfrage)
	if treffer.is_empty():
		return p + Vector3.UP * 0.3
	return (treffer["position"] as Vector3) + Vector3.UP * 0.05


## Welt-Richtung -> Stick, kamerarelativ wie die echte Steuerung.
func _eingabe_fuer(d: Vector3) -> Vector2:
	var kamera := get_viewport().get_camera_3d()
	var vor := -kamera.global_transform.basis.z
	vor.y = 0.0
	vor = vor.normalized()
	var rechts := kamera.global_transform.basis.x
	rechts.y = 0.0
	rechts = rechts.normalized()
	return Vector2(d.dot(rechts), -d.dot(vor))
