extends KorridorLevel
## Level 04 – "Katzensprung"
##
## Ein Ritt-Level: Der Beuteldachs sitzt auf einer Wildkatze, die von
## selbst rennt und dabei immer schneller wird. Gelenkt wird nur quer zum
## Weg, gesprungen wie gewohnt. Anhalten oder umkehren geht nicht.
##
## Das ändert, was ein Hindernis ist. Zu Fuß weicht man aus, indem man
## stehen bleibt; hier bleibt nur die Seite. Deshalb steht nie die ganze
## Breite zu, sondern immer genau eine Lücke – die Aufgabe ist, sie früh
## genug zu sehen. Steine und Stämme stehen abwechselnd links, rechts und
## in der Mitte, damit das Ausweichen einen Rhythmus bekommt.
##
## Abschnitte (Strecke auf der Kurve):
##     0 –  60  Anlauf     – weit gestellte Hindernisse, langsames Tempo
##    60 – 130  Enge       – dichtere Folge, erste Sprunglücken
##   130 – 210  Sturzbach  – Lücken über dem Bach, versetzte Stämme
##   210 – 280  Galopp     – Höchsttempo, Hindernisse im Wechseltakt
##   280 – 320  Auslauf    – Ziel
##
## Kisten zerbrechen im Vorbeirennen, dafür sorgt `Reiter.angriffe()`.
## Gegner gibt es keine: bei 19 m/s ist eine patrouillierende Kröte keine
## Aufgabe mehr, sondern Zufall.

const STEIN := preload("res://scenes/props/Stein.tscn")
const BAUM := preload("res://scenes/props/Baum.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")

const M_ANLAUF := 0.0
const M_ENGE := 60.0
const M_BACH := 130.0
const M_GALOPP := 210.0
const M_AUSLAUF := 280.0
const M_ENDE := 320.0

const SCHLUCHT_HOEHE := -11.0   ## Grund der Schlucht, reine Kulisse
const ABSTURZ := -5.0

## Wie weit vor dem Ziel die Steuerung abgegeben wird.
const AUSLAUF := 8.0


const STRECKE := [
	# --- Anlauf: durchgehend, nur Hindernisse ---
	{"von": 0.0, "bis": 60.0, "breite": 12.0},
	# --- Enge: schmaler, eine erste Lücke ---
	{"von": 60.0, "bis": 96.0, "breite": 10.0},
	{"von": 101.0, "bis": 130.0, "breite": 10.0},
	# --- Sturzbach: drei Lücken hintereinander ---
	{"von": 130.0, "bis": 154.0, "breite": 11.0},
	{"von": 159.0, "bis": 180.0, "breite": 10.0},
	{"von": 185.0, "bis": 210.0, "breite": 11.0},
	# --- Galopp: weit, dafür dichte Hindernisse ---
	{"von": 210.0, "bis": 246.0, "breite": 13.0},
	{"von": 251.0, "bis": 280.0, "breite": 12.0},
	# --- Auslauf ---
	{"von": 280.0, "bis": 320.0, "breite": 14.0},
]

var _reiter: Reiter


func abschnitte() -> Array:
	return STRECKE


func ende() -> float:
	return M_ENDE


func absturz_hoehe() -> float:
	return ABSTURZ


func _bauschritte() -> Array:
	return [
		{"text": "Schlucht wird vermessen", "tun": _verlauf_anlegen},
		{"text": "Grund der Schlucht", "tun": _grund_bauen},
		{"text": "Pfad wird gebahnt", "tun": _boden_bauen},
		{"text": "Absturzzone", "tun": _absturz_spannen},
		{"text": "Felsen und Stämme", "tun": _hindernisse_setzen},
		{"text": "Kisten werden gestapelt", "tun": _kisten_setzen},
		{"text": "Früchte werden verteilt", "tun": _fruechte_setzen},
		{"text": "Rastplätze", "tun": _checkpoints_setzen},
		{"text": "Wald am Rand", "tun": _deko_bauen},
		{"text": "Die Katze wird gesattelt", "tun": _reiter_einrichten},
	]


# =========================================================== Verlauf

## Lange, weit gezogene Kurven – bei 19 m/s wäre eine enge Kurve nicht
## mehr zu lesen, bevor man drinsteckt.
func _verlauf_anlegen() -> void:
	verlauf = LevelWerkzeuge.kurve_aus_punkten([
		Vector3(0, 0, 6),
		Vector3(0, 0, -30),
		Vector3(2, 0, -66),        # sanfte Rechtsdrift
		Vector3(14, 0, -100),
		Vector3(34, 1, -126),
		Vector3(60, 1, -142),      # Sturzbach
		Vector3(90, 2, -148),
		Vector3(120, 2, -142),     # Linksbogen
		Vector3(146, 3, -124),
		Vector3(164, 4, -98),
		Vector3(172, 5, -68),      # Galopp
		Vector3(170, 6, -36),
		Vector3(160, 6, -6),
	])


func _boden_bauen() -> void:
	LevelWerkzeuge.korridor(geometrie, verlauf, STRECKE, {
		"oben": Materialbibliothek.waldweg(),
		"kante": Materialbibliothek.gras(),
		"klippe": Materialbibliothek.fels(),
	}, {"tiefe": 8.0, "schritt": 1.4, "kante_hoehe": 0.34, "kante_breite": 0.8})
	luecken_markieren()


func _grund_bauen() -> void:
	var flaeche := PlaneMesh.new()
	flaeche.size = Vector2(340.0, 340.0)
	var mi := MeshInstance3D.new()
	mi.name = "Schluchtgrund"
	mi.mesh = flaeche
	mi.material_override = Materialbibliothek.fels()
	mi.position = LevelWerkzeuge.punkt(verlauf, M_ENDE * 0.5, 0.0, SCHLUCHT_HOEHE)
	geometrie.add_child(mi)


func _absturz_spannen() -> void:
	absturzzonen(20.0, 80.0)


# =========================================================== Hindernisse

## Ein Hindernis ist eine Zone, kein Körper: Der Reiter klebt auf der
## Kurve und würde gegen einen festen Körper nur hängen bleiben, statt
## abgeworfen zu werden.
func _hindernis(strecke: float, seitlich: float, breite: float,
		als_stamm: bool) -> void:
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.0)
	zone.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	zone.body_entered.connect(_auf_hindernis)
	# Gruppe und Kennwerte, damit sich die Strecke von außen prüfen lässt:
	# ob überall eine Lücke bleibt und wie viel Zeit zum Reagieren ist.
	zone.add_to_group("hindernis")
	zone.set_meta("strecke", strecke)
	zone.set_meta("seitlich", seitlich)
	zone.set_meta("breite", breite)
	objekte.add_child(zone)

	var hoehe := 1.1 if als_stamm else 1.6
	var form := CollisionShape3D.new()
	var kasten := BoxShape3D.new()
	kasten.size = Vector3(breite, hoehe, 1.4)
	form.shape = kasten
	form.position.y = hoehe * 0.5
	zone.add_child(form)

	# Optik: Stämme liegen quer, Felsen stehen als Brocken
	if als_stamm:
		var stamm := MeshInstance3D.new()
		var walze := CylinderMesh.new()
		walze.top_radius = hoehe * 0.45
		walze.bottom_radius = hoehe * 0.45
		walze.height = breite
		walze.radial_segments = 10
		stamm.mesh = walze
		stamm.material_override = Materialbibliothek.rinde()
		stamm.rotation.z = PI * 0.5
		stamm.position.y = hoehe * 0.45
		zone.add_child(stamm)
	else:
		var brocken := STEIN.instantiate() as Stein
		brocken.groesse = breite * 0.75
		brocken.kollision = false     # die Zone entscheidet, nicht der Körper
		brocken.bemoost = true
		brocken.saat = int(strecke * 7.0) + 1
		zone.add_child(brocken)


func _auf_hindernis(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("schaden_nehmen"):
		koerper.call("schaden_nehmen")


## Die Hindernisse stehen nach Muster: Erst einzeln und weit auseinander,
## dann paarweise mit einer Lücke, zuletzt im Wechseltakt. Zwischen zwei
## Hindernissen liegen nie weniger als 14 m – bei Höchsttempo sind das
## knapp drei Viertel Sekunden zum Reagieren.
func _hindernisse_setzen() -> void:
	# ---------- Anlauf: eines nach dem anderen, viel Platz ----------
	_hindernis(20.0, -3.0, 3.0, false)
	_hindernis(36.0, 3.2, 3.0, false)
	_hindernis(52.0, 0.0, 3.4, true)

	# ---------- Enge: zwei Sperren, dazwischen muss man durch ----------
	_hindernis(68.0, -3.6, 3.2, false)
	_hindernis(68.0, 3.6, 3.2, false)
	_hindernis(84.0, 0.0, 4.0, true)
	_hindernis(108.0, -3.4, 3.2, true)
	_hindernis(122.0, 3.4, 3.2, false)

	# ---------- Sturzbach: Hindernisse dicht vor den Lücken ----------
	_hindernis(142.0, 0.0, 3.6, true)
	_hindernis(168.0, -3.2, 3.0, false)
	_hindernis(196.0, 3.2, 3.0, false)
	_hindernis(204.0, -3.0, 3.0, true)

	# ---------- Galopp: Wechseltakt bei Höchsttempo ----------
	_hindernis(218.0, -4.2, 3.6, false)
	_hindernis(232.0, 4.2, 3.6, false)
	_hindernis(244.0, 0.0, 4.2, true)
	_hindernis(262.0, -4.0, 3.6, true)
	_hindernis(276.0, 4.0, 3.6, false)


# =========================================================== Kisten

## Kisten stehen in Reihen längs des Weges: im Vorbeirennen zerbrechen
## sie ohnehin, die Aufgabe ist nur, die richtige Spur zu treffen.
func _kisten_setzen() -> void:
	_kistenreihe(8.0, 5, 0.0)
	_kistenreihe(28.0, 4, -3.0)
	_kistenreihe(44.0, 4, 3.0)
	_kistenreihe(74.0, 5, 0.0)
	_kistenreihe(88.0, 4, -2.6)
	_kistenreihe(114.0, 4, 2.6)
	_kistenreihe(134.0, 5, 0.0)
	_kistenreihe(174.0, 4, 2.8)
	_kistenreihe(190.0, 4, -2.8)
	_kistenreihe(224.0, 5, 3.4)
	_kistenreihe(254.0, 5, -3.4)
	_kistenreihe(268.0, 4, 0.0)
	_kistenreihe(286.0, 6, 0.0)

	# Ein Extraleben kurz vor dem Ziel, gut sichtbar in der Mitte
	kiste(Kiste.Art.LEBEN, 300.0, 0.0)
	# Schutz vor den beiden dichtesten Hindernisfolgen
	kiste(Kiste.Art.SCHUTZ, 64.0, 0.0)
	kiste(Kiste.Art.SCHUTZ, 212.0, 0.0)


func _kistenreihe(von: float, anzahl: int, seitlich: float) -> void:
	for i in anzahl:
		kiste(Kiste.Art.NORMAL, von + i * 1.6, seitlich)


# =========================================================== Früchte

func _fruechte_setzen() -> void:
	fruechte_reihe(4.0, 18.0, 8, 0.0)
	fruechte_reihe(22.0, 34.0, 7, -3.0)
	fruechte_reihe(38.0, 50.0, 7, 3.0)
	fruechte_reihe(56.0, 66.0, 6, 0.0)
	fruechte_reihe(70.0, 82.0, 7, 0.0)
	# Über jede Lücke ein Bogen: er zeigt, wo abgesprungen werden muss
	fruechte_bogen(95.0, 102.0, 6, 0.0, 3.4)
	fruechte_reihe(106.0, 120.0, 7, -2.6)
	fruechte_reihe(132.0, 150.0, 8, 0.0)
	fruechte_bogen(153.0, 160.0, 6, 0.0, 3.6)
	fruechte_reihe(164.0, 178.0, 7, 2.8)
	fruechte_bogen(179.0, 186.0, 6, 0.0, 3.6)
	fruechte_reihe(192.0, 208.0, 8, -2.8)
	fruechte_reihe(212.0, 242.0, 12, 0.0)
	fruechte_bogen(245.0, 252.0, 6, 0.0, 3.8)
	fruechte_reihe(258.0, 278.0, 9, 3.4)
	fruechte_reihe(284.0, 314.0, 12, 0.0)


# =========================================================== Checkpoints

## Rastplätze: eine Zone quer über den Weg, die dem Reiter seine Strecke
## als Rückkehrpunkt meldet. Die Checkpoint-Kiste aus den Laufleveln
## taugt hier nicht – sie merkt sich eine Weltposition, der Reiter
## braucht aber eine Strecke auf der Kurve.
func _checkpoints_setzen() -> void:
	for s: float in [60.0, 130.0, 210.0, 280.0]:
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		zone.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, 1.2)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(20.0, 5.0, 1.5)
		form.shape = kasten
		zone.add_child(form)
		zone.body_entered.connect(_auf_checkpoint.bind(s))
		objekte.add_child(zone)

		# Zwei Wimpel als sichtbare Marke
		for seite: float in [-1.0, 1.0]:
			var mast := MeshInstance3D.new()
			var stange := CylinderMesh.new()
			stange.top_radius = 0.07
			stange.bottom_radius = 0.09
			stange.height = 2.6
			mast.mesh = stange
			mast.material_override = Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)
			mast.position = LevelWerkzeuge.punkt(verlauf, s,
					seite * (breite_bei(s) * 0.5 - 0.7), 1.3)
			deko.add_child(mast)

			var fahne := MeshInstance3D.new()
			var tuch := BoxMesh.new()
			tuch.size = Vector3(0.9, 0.55, 0.06)
			fahne.mesh = tuch
			fahne.material_override = Materialbibliothek.leuchtend(
					Farben.PORTAL_START, 0.8)
			fahne.position = mast.position + Vector3(0.0, 1.0, 0.0)
			fahne.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
			deko.add_child(fahne)


func _auf_checkpoint(koerper: Node3D, s: float) -> void:
	if koerper is Reiter:
		(koerper as Reiter).setze_checkpoint(s)
		GameState.zeige_nachricht("Rastplatz", 1.2)


# =========================================================== Kulisse

func _deko_bauen() -> void:
	var wuerfel := randi()
	seed(40401)
	for i in 90:
		var s := randf_range(-8.0, M_ENDE + 8.0)
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var baum := BAUM.instantiate() as Baum
		baum.art = Baum.Art.NADELBAUM if i % 3 == 0 else Baum.Art.LAUBBAUM
		baum.hoehe = randf_range(6.0, 13.0)
		baum.staerke = randf_range(0.7, 1.2)
		baum.saat = 9000 + i
		baum.kollision = false
		baum.position = LevelWerkzeuge.punkt(verlauf, s,
				seite * randf_range(9.0, 32.0), SCHLUCHT_HOEHE + randf_range(0.0, 2.0))
		deko.add_child(baum)

	for i in 40:
		var s := randf_range(2.0, M_ENDE - 2.0)
		var rand := rand_bei(s, 0.5)
		if rand < 1.5:
			continue
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var horst := GRASFELD.instantiate() as Grasfeld
		horst.flaeche = Vector2(3.5, 3.5)
		horst.saat = 9500 + i
		horst.position = LevelWerkzeuge.punkt(verlauf, s, seite * rand, 0.0)
		deko.add_child(horst)
	seed(wuerfel)


# =========================================================== Reiter

## Der Reiter braucht drei Auskünfte vom Level: die Kurve, wie weit er
## seitlich darf und wo Boden ist. Ohne die letzte Auskunft liefe er über
## Lücken hinweg, als wäre nichts – er fällt ja nicht, er klebt auf der
## Kurve.
func _reiter_einrichten() -> void:
	_reiter = get_tree().get_first_node_in_group("spieler") as Reiter
	if _reiter == null:
		push_warning("Level 04 ohne Reiter – ist Reiter.tscn in der Szene?")
		return
	_reiter.verlauf = verlauf
	_reiter.seiten_grenze = func(s: float) -> float: return rand_bei(s, 1.1)
	_reiter.boden_pruefer = func(s: float) -> bool: return breite_bei(s) > 0.0
	_reiter.ziel_strecke = M_ENDE - AUSLAUF
	_reiter.strecke = 2.0
	if not _reiter.ziel_erreicht.is_connected(_auf_ziel):
		_reiter.ziel_erreicht.connect(_auf_ziel)


func _auf_ziel() -> void:
	_reiter.gesperrt = true
	GameState.zeige_nachricht("Geschafft!", 3.0)
	_auf_level_geschafft()
