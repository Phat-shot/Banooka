extends Node3D
class_name Bonusraum
## Der Bonusraum – die dritte Ebene des Belohnungsvertrags.
##
## Ein Level hat drei Ebenen: ankommen, alle Kisten, und den Bonusraum.
## Die dritte fehlte bei uns ganz. Der Vertrag (`doku/level-vorbilder.md`,
## „Die fünf Verträge", Punkt 5) verlangt: ein eigener kleiner Raum in
## eigener Gestaltung, betreten über gesammelte Marken, OHNE Todesstrafe,
## und dort liegt ein guter Teil der Kisten.
##
##
## WARUM DER RAUM IM LEVEL STEHT UND KEINE EIGENE SZENE IST
##
## Das ist die eine Entscheidung, an der alles hängt. `LevelBasis` zählt
## die Kisten mit `_kisten_zaehlen()` über `get_tree()` – also über den
## ganzen Szenenbaum – und zwar EINMAL, nachdem alle `_bauschritte()`
## durch sind. Danach merkt sich `_bauplan_erfassen()` jede Kiste samt
## Elternknoten, um sie nach einem Tod wieder aufzustellen.
##
## Daraus folgt zwingend: Wer will, dass die Bonuskisten in
## `GameState.kisten_gesamt` mitzählen, muss sie in DIESEN Baum hängen,
## und zwar während der Bauschritte. Ein Szenenwechsel in eine eigene
## Bonusszene würde `kisten_gesamt` auf den Stand der Bonusszene setzen,
## den Bauplan des Levels wegwerfen, den Checkpoint verlieren und beim
## Rückweg das ganze Level neu aufbauen – für einen Raum von dreißig
## Metern. Ohne mitzählen wäre „alle Kisten" mit Bonusraum überhaupt nicht
## erreichbar, weil `kisten_gesamt` die Bonuskisten gar nicht kennt.
##
## Also steht der Raum WEIT ABSEITS im selben Baum (siehe `ABSEITS`), und
## der Wechsel dorthin ist ein Versetzen, kein Szenenwechsel. Zählung,
## Neuaufbau nach dem Tod und der Kistenzähler im HUD kommen damit
## geschenkt – es ist kein einziger Sonderfall nötig.
##
##
## KEINE TODESSTRAFE
##
## Der Raum kennt keinen Tod, statt ihn nachträglich zu verzeihen.
## `Spieler.sterben()` zieht ohne Umweg ein Leben ab; das ließe sich von
## außen nicht abfangen. Deshalb gibt es hier nichts, woran man sterben
## könnte: keine Gegner, keine Stacheln, keine TNT- oder Nitrokisten. Es
## bleibt der Sturz über die Kante – und den fängt `Fangzone` weit
## oberhalb von `Spieler.TODESHOEHE` (−12 m) ab. Wer hinunterfällt,
## verliert kein Leben, sondern nur den Rest des Bonusraums und steht
## wieder im Level. Das ist zugleich der zweite Ausgang: Man kann
## jederzeit springen, wenn man genug hat.
##
##
## RÜCKKEHR
##
## Beim Betreten werden Ort und Blickrichtung des Spielers gemerkt und
## beim Verlassen wiederhergestellt – der Levellauf geht dort weiter, wo
## er unterbrochen wurde. Der Checkpoint des Levels wird für die Dauer
## des Besuchs beiseitegelegt und auf den Raumeingang gesetzt, damit ein
## unvorhergesehener Tod nicht ins Nichts neben dem Raum führt.
##
##
## WAS EIN ZWEITES LEVEL TUN MUSS
##
## Drei Zeilen, kein Umbau:
##
##   1. In `_bauschritte()` einen Schritt aufnehmen – irgendwo, Haupt-
##      sache innerhalb der Bauschritte, denn erst danach wird gezählt:
##          {"text": "Marken und Bonusraum", "tun": _bonus_bauen},
##   2. Den Schritt schreiben:
##          func _bonus_bauen() -> void:
##              Bonusraum.einbauen(self, [
##                      Vector3(44.0, 3.0, 1.2),
##                      Vector3(195.0, 8.6, 1.4),
##                      Vector3(254.0, 3.0, 4.0),
##              ], 316.0, -5.0, "Wurzelgewölbe")
##      Je Marke ein Vector3(Strecke, seitlicher Versatz, Höhe über dem
##      Weg), danach Strecke und Versatz des Tors und der Name, der auf
##      dem Banner im Raum steht.
##   3. Nichts weiter. Der Raum baut sich selbst, hängt sich selbst ein,
##      und seine Kisten zählen von allein mit.
##
## Zu beachten ist nur eines: Das Tor gehört NEBEN den Weg, nicht darauf –
## es hat einen Riegel, solange Marken fehlen. Und `ABSEITS` muss vom
## Level weit genug weg liegen (x nahe null, weil die Verfolgerkamera im
## kurvenlosen Betrieb um x = 0 herum arbeitet).

const MARKE := preload("res://scenes/bonus/Marke.tscn")
const BONUSTOR := preload("res://scenes/bonus/Bonustor.tscn")
const KISTE := preload("res://scenes/crates/Kiste.tscn")

## Wohin der Raum gestellt wird – weit außerhalb jedes Levelverlaufs.
## x bleibt bei null: Ohne Kurve stellt sich die Verfolgerkamera auf
## `p.x * seiten_faktor`, rechnet also um den Nullpunkt herum.
const ABSEITS := Vector3(0.0, 0.0, 640.0)

# ------------------------------------------------------------ Gestaltung
# Der Raum soll ein BRUCH sein. Level 18 ist warm, offen, grün und rot,
# mit Himmel darüber; also ist der Bonusraum kühl, geschlossen, türkis und
# blau, ohne Himmel. Wer hineintritt, soll im ersten Bild sehen, dass er
# woanders ist – nicht erst am Kistenzähler.

## Türkis der Marken, des Tors und der Kristalle – dieselbe Farbe, damit
## der Raum die Farbe einlöst, für die man gesammelt hat.
const TON := Marke.TON
## Zweiter, tieferer Ton. Ohne ihn wird die Höhle einfarbig.
const TON_TIEF := Color(0.26, 0.50, 0.88)
## Kühler, dunkler Fels. Nach dem Lesbarkeitsvertrag ist die größte Fläche
## dunkel und die begehbare Fläche das Hellste im Bild.
const FELS := Color(0.17, 0.21, 0.27)
const FELS_HELL := Color(0.80, 0.84, 0.88)
## Ein wenig Wurzelbraun von oben – der Raum liegt unter dem Dschungel,
## das soll man sehen.
const WURZEL := Color(0.24, 0.17, 0.12)

# ------------------------------------------------------------ Maße
const HOEHLE_RADIUS := 30.0
const HOEHLE_HOEHE := 22.0
## Eintritt und Ausgang, in Raumkoordinaten.
const EINSTIEG := Vector3(0.0, 1.1, 15.5)
const AUSGANG := Vector3(0.0, 1.3, -16.0)
## Oberkante der Fangzone. Weit über `Spieler.TODESHOEHE` (−12 m).
const FANGKANTE := -3.0

## Wie viele Marken das Tor öffnen.
@export var marken_noetig := 3
## Name des Raums – steht auf dem Banner über dem Eingang.
@export var banner := "Wurzelgewölbe"

var _level: Node3D = null
var _tor: Bonustor = null
var _gefunden := 0
var _offen := false
var _drin := false
## Kurze Sperre nach der Rückkehr. Der Spieler landet wieder MITTEN im
## Tor – ohne sie meldete das Tor sofort den nächsten Durchgang und man
## käme aus dem Raum nicht mehr heraus.
var _tor_sperre := 0

var _boden: Node3D
var _kisten: Node3D
var _schmuck: Node3D

# Was beim Betreten beiseitegelegt und beim Verlassen zurückgegeben wird.
var _rueckkehr := Vector3.ZERO
var _rueckkehr_blick := 0.0
var _checkpoint_vorher := Vector3.ZERO
var _umgebung_vorher: Environment = null
var _welt: WorldEnvironment = null
var _sonne: DirectionalLight3D = null
var _kamera: Camera3D = null
var _kamera_kurve := NodePath()
var _kamera_seitenblick := 0.0

var _eigene_umgebung: Environment = null


# ====================================================== Einbau ins Level

## Baut Raum, Tor und Marken in ein Korridorlevel ein.
##
## `marken` ist eine Liste aus Vector3(Strecke, seitlicher Versatz, Höhe
## über dem Weg), `tor_strecke`/`tor_seitlich` sagen, wo das Tor steht.
## Rückgabe ist der Raum.
static func einbauen(level: KorridorLevel, marken: Array,
		tor_strecke: float, tor_seitlich := 0.0, raumname := "",
		abseits := ABSEITS) -> Bonusraum:
	var raum := Bonusraum.new()
	raum.name = "Bonusraum"
	raum._level = level
	raum.marken_noetig = maxi(marken.size(), 1)
	# Der Name muss VOR dem Einhängen stehen: Das Banner entsteht in
	# `_ready()`, ein späteres Umbenennen käme zu spät.
	if not raumname.is_empty():
		raum.banner = raumname
	raum.position = abseits
	level.add_child(raum)

	# --- Das Tor, seitlich am Weg ---
	var tor := BONUSTOR.instantiate() as Bonustor
	# Das Tor schaut zur Wegmitte: `drehung()` legt die lokale -Z-Achse in
	# Laufrichtung, die lokale +X-Achse also auf die Seite mit positivem
	# Versatz. Ein Tor links vom Weg muss folglich um +90° gedreht werden.
	var quer := 0.0
	if absf(tor_seitlich) > 0.01:
		quer = PI * 0.5 * (-1.0 if tor_seitlich > 0.0 else 1.0)
	tor.position = LevelWerkzeuge.punkt(level.verlauf, tor_strecke,
			tor_seitlich, 0.0)
	tor.rotation.y = LevelWerkzeuge.drehung(level.verlauf, tor_strecke) + quer
	level.objekte.add_child(tor)
	raum._tor = tor
	tor.durchschritten.connect(raum._auf_tor)
	tor.stand_setzen(0, raum.marken_noetig)

	# --- Die Marken im Level ---
	for eintrag: Vector3 in marken:
		var m := MARKE.instantiate() as Marke
		m.raum = raum
		m.position = LevelWerkzeuge.punkt(level.verlauf, eintrag.x,
				eintrag.y, eintrag.z)
		level.objekte.add_child(m)

	return raum


# ====================================================== Aufbau des Raums

func _ready() -> void:
	add_to_group("bonusraeume")
	_boden = _gruppe("Boden")
	_kisten = _gruppe("Kisten")
	_schmuck = _gruppe("Schmuck")
	_hoehle_bauen()
	_plateau_bauen()
	_schmuck_bauen()
	_kisten_setzen()
	_ausgang_bauen()
	_fangzone_bauen()
	_banner_bauen()
	# Ohne Level ist der Raum sein eigener Schauplatz (Prüfstand, Foto).
	# Dann bringt er seine Umgebung gleich selbst mit, sonst stünde er im
	# Vorgabehimmel und sähe aus wie ein Steinbruch bei Tag.
	if _level == null:
		var welt := WorldEnvironment.new()
		welt.name = "Umgebung"
		welt.environment = _umgebung_bauen()
		add_child(welt)


func _gruppe(bezeichnung: String) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	add_child(knoten)
	return knoten


## Die Höhle: ein liegender Zylinder von innen.
##
## Von innen sichtbar durch `CULL_FRONT` – das ist billiger und
## fugenfreier, als eine Schale aus umgedrehten Flächen zu bauen. Der
## Boden des Zylinders fehlt mit Absicht: Unter dem Plateau soll nichts
## sein, denn der Sturz ist der zweite Ausgang.
func _hoehle_bauen() -> void:
	var schale := CylinderMesh.new()
	schale.top_radius = HOEHLE_RADIUS
	schale.bottom_radius = HOEHLE_RADIUS
	schale.height = HOEHLE_HOEHE
	schale.radial_segments = 32
	schale.rings = 4
	schale.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.name = "Schale"
	mi.mesh = schale
	mi.material_override = _innenstoff(FELS)
	mi.position = Vector3(0.0, HOEHLE_HOEHE * 0.5 - 2.0, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_boden.add_child(mi)


## Der begehbare Weg durch den Raum: drei Platten, jede eine Stufe höher.
##
## Nach dem Lesbarkeitsvertrag ist die begehbare Fläche das Hellste im
## Bild; die Höhle ringsum ist der dunkle Rahmen. Die beiden Simse hängen
## frei über dem Nichts – nur mit einem Sprung zu haben, und genau dort
## stehen die Kisten, für die man den Raum betreten hat.
func _plateau_bauen() -> void:
	var stoff := _felsstoff(FELS_HELL)
	_platte(Vector3(0.0, -0.5, 11.5), Vector3(11.0, 1.0, 13.0), stoff)
	_platte(Vector3(0.0, -0.1, 0.0), Vector3(13.0, 1.0, 12.0), stoff)
	_platte(Vector3(0.0, 0.3, -11.5), Vector3(11.0, 1.0, 13.0), stoff)
	# Die beiden Simse: 1,2 m höher und 1 m Luft dazwischen – ein Sprung,
	# kein Schritt.
	_platte(Vector3(-9.5, 1.1, 2.0), Vector3(4.0, 1.0, 7.0), stoff)
	_platte(Vector3(9.5, 1.1, -2.0), Vector3(4.0, 1.0, 7.0), stoff)


func _platte(mitte: Vector3, groesse: Vector3, stoff: Material) -> void:
	LevelWerkzeuge.plattform(_boden, mitte, groesse, stoff)


## Kristalle, Wurzeln und Licht.
##
## Die Kristalle stehen am Rand des Weges und unten im Schacht: Am Rand
## zeichnen sie die Kante nach, im Schacht geben sie der Tiefe einen
## Maßstab. Ohne sie wäre das Nichts unter dem Plateau eine schwarze
## Fläche, und eine schwarze Fläche liest sich nicht als Tiefe.
func _schmuck_bauen() -> void:
	seed(18640)
	# --- Kristalle an den Wegkanten ---
	for i in 26:
		var seite: float = -1.0 if i % 2 == 0 else 1.0
		var z := randf_range(-17.0, 17.0)
		var x := seite * randf_range(4.8, 6.6)
		var hoch := randf_range(0.8, 2.6)
		_kristall(Vector3(x, 0.1, z), hoch, randf_range(0.14, 0.34),
				TON if i % 3 else TON_TIEF)
	# --- Zacken aus der Tiefe, im Ring um das Plateau ---
	for i in 22:
		var winkel := TAU * float(i) / 22.0 + randf() * 0.2
		var r := randf_range(13.0, 25.0)
		var hoch := randf_range(9.0, 20.0)
		_kristall(Vector3(cos(winkel) * r, -16.0, sin(winkel) * r), hoch,
				randf_range(0.7, 1.8), TON_TIEF if i % 3 else TON)
	# --- Wurzeln aus der Decke: der Dschungel liegt darüber ---
	var rinde := Materialbibliothek.rinde().duplicate() as StandardMaterial3D
	rinde.albedo_color = WURZEL
	for i in 14:
		var winkel := TAU * float(i) / 14.0 + 0.3
		# Erst ab 14 m: Näher am Mittelpunkt hinge ein Strang mitten durch
		# den Weg oder durch einen der Simse.
		var r := randf_range(14.0, 27.0)
		var laenge := randf_range(5.0, 13.0)
		var strang := CylinderMesh.new()
		strang.top_radius = randf_range(0.22, 0.5)
		strang.bottom_radius = 0.06
		strang.height = laenge
		strang.radial_segments = 6
		var mi := MeshInstance3D.new()
		mi.mesh = strang
		mi.material_override = rinde
		mi.position = Vector3(cos(winkel) * r, HOEHLE_HOEHE - 2.0 - laenge * 0.5,
				sin(winkel) * r)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_schmuck.add_child(mi)

	# --- Licht. Es kommt aus dem Raum selbst, nicht von oben: In einer
	# Höhle gibt es keine Sonne, und genau das macht den Bruch aus.
	#
	# Über dem Weg hängen BLASSE Lichter, an den Rändern türkise. Das ist
	# der Lesbarkeitsvertrag: Die begehbare Fläche muss das Hellste und am
	# wenigsten Gesättigte im Bild sein. Türkis über dem Weg sah zwar
	# stimmungsvoll aus, zog den Weg aber farblich mit dem Rand gleich –
	# und wo der Weg aufhört, muss die Helligkeit aufhören. ---
	for stelle: Vector3 in [Vector3(0.0, 5.0, 12.0), Vector3(0.0, 5.0, 0.0),
			Vector3(0.0, 5.0, -12.0)]:
		var weg := OmniLight3D.new()
		weg.light_color = Color(0.88, 0.94, 0.96)
		weg.light_energy = 2.6
		weg.omni_range = 20.0
		weg.shadow_enabled = false
		weg.position = stelle
		_schmuck.add_child(weg)
	for stelle: Vector3 in [Vector3(-9.5, 3.4, 2.0), Vector3(9.5, 3.4, -2.0),
			Vector3(0.0, -8.0, 0.0), Vector3(0.0, 12.0, 0.0)]:
		var rand := OmniLight3D.new()
		rand.light_color = TON.lerp(TON_TIEF, 0.35)
		rand.light_energy = 2.2
		rand.omni_range = 28.0
		rand.shadow_enabled = false
		rand.position = stelle
		_schmuck.add_child(rand)


func _kristall(fuss: Vector3, hoehe: float, dicke: float, ton: Color) -> void:
	var zacken := CylinderMesh.new()
	zacken.top_radius = 0.0
	zacken.bottom_radius = dicke
	zacken.height = hoehe
	zacken.radial_segments = 6
	zacken.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = zacken
	mi.material_override = Materialbibliothek.kristall(ton)
	mi.position = fuss + Vector3.UP * hoehe * 0.5
	mi.rotation = Vector3(randf_range(-0.16, 0.16), randf() * TAU,
			randf_range(-0.16, 0.16))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_schmuck.add_child(mi)


## Zwanzig Kisten – ein Drittel dessen, was im Level selbst steht.
##
## Sie liegen bewusst nicht in einer Reihe auf dem Weg: sechs stehen
## unten, sechs auf den beiden Simsen (nur mit Sprung), fünf als Stapel in
## der Mitte, drei am Ausgang. Das ist der Kistenvertrag – eine Kiste
## steht dort, wo sie einen von der sicheren Linie wegholt.
##
## Keine TNT-, Nitro- oder Federkiste: In einem Raum ohne Todesstrafe darf
## nichts stehen, was töten oder über die Kante schleudern kann.
func _kisten_setzen() -> void:
	# Ankunftsplatte (Oberkante 0)
	for x: float in [-2.6, 0.0, 2.6]:
		_kiste(Kiste.Art.NORMAL, Vector3(x, 0.5, 13.5))
	_kiste(Kiste.Art.NORMAL, Vector3(-2.6, 0.5, 9.5))
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, Vector3(0.0, 0.5, 9.5))
	_kiste(Kiste.Art.NORMAL, Vector3(2.6, 0.5, 9.5))

	# Die beiden Simse (Oberkante 1,6) – nur im Sprung erreichbar
	for z: float in [4.0, 2.0, 0.0]:
		_kiste(Kiste.Art.NORMAL, Vector3(-9.5, 2.1, z))
	_kiste(Kiste.Art.NORMAL, Vector3(9.5, 2.1, 0.0))
	_kiste(Kiste.Art.FRUCHT_MEHRFACH, Vector3(9.5, 2.1, -2.0))
	_kiste(Kiste.Art.NORMAL, Vector3(9.5, 2.1, -4.0))

	# Stapel in der Mitte (Oberkante 0,4). Die obere Reihe steht
	# absichtlich in der Luft – auf den unteren Kisten.
	for x: float in [-2.4, 0.0, 2.4]:
		_kiste(Kiste.Art.NORMAL, Vector3(x, 0.9, 0.0))
	for x: float in [-1.2, 1.2]:
		_kiste(Kiste.Art.NORMAL, Vector3(x, 1.9, 0.0), true)

	# Ausgangsplatte (Oberkante 0,8)
	_kiste(Kiste.Art.NORMAL, Vector3(-2.6, 1.3, -9.0))
	_kiste(Kiste.Art.NORMAL, Vector3(2.6, 1.3, -9.0))
	_kiste(Kiste.Art.LEBEN, Vector3(0.0, 1.3, -12.5))


func _kiste(art: Kiste.Art, stelle: Vector3, schwebt := false) -> void:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	if schwebt:
		# Sonst meldet `werkzeuge/level_check.gd` sie als Kiste ohne Boden.
		k.add_to_group("schwebende_kisten")
	k.position = stelle
	_kisten.add_child(k)


## Der Rückweg: ein Ring am Ende des Raums.
##
## Er sieht aus wie ein Portal, ist aber keins – ein Zielportal würde das
## Level abschließen. Hier geht es zurück in den Lauf.
func _ausgang_bauen() -> void:
	var ring := Area3D.new()
	ring.name = "Rueckweg"
	ring.collision_layer = 0
	ring.collision_mask = 2
	ring.position = AUSGANG
	var form := CylinderShape3D.new()
	form.radius = 1.3
	form.height = 3.0
	var kollision := CollisionShape3D.new()
	kollision.shape = form
	ring.add_child(kollision)
	_schmuck.add_child(ring)
	ring.body_entered.connect(func(koerper: Node3D) -> void:
		if koerper.is_in_group("spieler"):
			verlassen("Zurück auf der Strecke"))

	var reif := TorusMesh.new()
	reif.inner_radius = 1.25
	reif.outer_radius = 1.5
	reif.rings = 28
	reif.ring_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = reif
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	mi.material_override = Materialbibliothek.leuchtend(TON, 2.4)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.add_child(mi)

	var scheibe := CylinderMesh.new()
	scheibe.top_radius = 1.25
	scheibe.bottom_radius = 1.25
	scheibe.height = 0.05
	scheibe.radial_segments = 28
	var si := MeshInstance3D.new()
	si.mesh = scheibe
	si.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	si.material_override = Materialbibliothek.transparent(TON.lightened(0.3), 1.2)
	si.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.add_child(si)

	_schrift("Zurück", AUSGANG + Vector3.UP * 3.4, TON, 72)


## Fängt jeden Sturz ab, lange bevor `Spieler.TODESHOEHE` erreicht ist.
## Das ist die ganze Umsetzung von „ohne Todesstrafe": kein Tod, keine
## Strafe – nur ein früher Ausgang.
func _fangzone_bauen() -> void:
	var zone := Area3D.new()
	zone.name = "Fangzone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	var form := BoxShape3D.new()
	form.size = Vector3(180.0, 40.0, 180.0)
	var kollision := CollisionShape3D.new()
	kollision.shape = form
	zone.add_child(kollision)
	zone.position = Vector3(0.0, FANGKANTE - 20.0, 0.0)
	add_child(zone)
	zone.body_entered.connect(func(koerper: Node3D) -> void:
		if koerper.is_in_group("spieler"):
			verlassen("Hinausgefallen – kein Leben verloren"))


## Das Banner über dem Eingang. In den Vorbildern trägt der Bonusraum
## seinen eigenen Namen; das ist die halbe Aussage, dass man woanders ist.
func _banner_bauen() -> void:
	var tafel := MeshInstance3D.new()
	var quader := BoxMesh.new()
	quader.size = Vector3(8.0, 1.3, 0.35)
	tafel.mesh = quader
	tafel.material_override = _felsstoff(FELS.lightened(0.12))
	tafel.position = Vector3(0.0, 7.2, 6.5)
	_schmuck.add_child(tafel)
	# Ein leuchtender Streifen unter der Tafel – ohne ihn ist sie im
	# Dunkeln ein Balken, der quer im Raum hängt, und kein Schild.
	var strich := MeshInstance3D.new()
	var leiste := BoxMesh.new()
	leiste.size = Vector3(8.0, 0.12, 0.42)
	strich.mesh = leiste
	strich.material_override = Materialbibliothek.leuchtend(TON, 2.4)
	strich.position = Vector3(0.0, 6.5, 6.5)
	strich.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_schmuck.add_child(strich)
	# Die Schrift steht VOR der Tafel, auf der Seite, von der man kommt.
	_schrift(banner, Vector3(0.0, 7.2, 6.9), TON, 110)


func _schrift(text: String, stelle: Vector3, ton: Color, groesse: int) -> void:
	var schild := Label3D.new()
	schild.text = text
	schild.font_size = groesse
	schild.outline_size = groesse / 4
	schild.outline_modulate = Color(0.02, 0.05, 0.06, 1.0)
	schild.modulate = ton
	schild.pixel_size = 0.006
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.position = stelle
	_schmuck.add_child(schild)


# ------------------------------------------------------------ Materialien

func _felsstoff(farbe: Color) -> StandardMaterial3D:
	var m := Materialbibliothek.fels().duplicate() as StandardMaterial3D
	m.albedo_color = farbe
	return m


## Derselbe Fels, aber von innen zu sehen: die Vorderseiten fallen weg.
func _innenstoff(farbe: Color) -> StandardMaterial3D:
	var m := _felsstoff(farbe)
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	return m


## Die Umgebung des Raums: kein Himmel, kein Sonnenlicht, dichter kühler
## Dunst. Der Dunst liegt HINTER dem Geschehen (Lesbarkeitsvertrag) – bei
## dieser Dichte ist die Nahzone bis rund zwölf Meter unberührt, die
## Höhlenwand in dreißig Metern aber schon halb verschluckt.
func _umgebung_bauen() -> Environment:
	if _eigene_umgebung != null:
		return _eigene_umgebung
	var u := Environment.new()
	u.background_mode = Environment.BG_COLOR
	u.background_color = Color(0.02, 0.05, 0.07)
	u.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	u.ambient_light_color = Color(0.26, 0.44, 0.52)
	u.ambient_light_energy = 1.0
	u.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	u.tonemap_exposure = 1.15
	u.fog_enabled = true
	u.fog_light_color = Color(0.08, 0.18, 0.24)
	u.fog_light_energy = 0.6
	u.fog_density = 0.026
	u.fog_sky_affect = 0.0
	u.glow_enabled = true
	u.glow_intensity = 0.7
	u.glow_bloom = 0.15
	_eigene_umgebung = u
	return u


# ====================================================== Marken und Tor

## Wird von jeder eingesammelten `Marke` gerufen.
func marke_aufnehmen() -> void:
	if _offen:
		return
	_gefunden += 1
	if _tor != null and is_instance_valid(_tor):
		_tor.stand_setzen(_gefunden, marken_noetig)
	if _gefunden < marken_noetig:
		GameState.zeige_nachricht("Marke %d/%d gefunden"
				% [_gefunden, marken_noetig], 1.8)
		return
	_offen = true
	if _tor != null and is_instance_valid(_tor):
		_tor.oeffnen()
	GameState.zeige_nachricht("Alle Marken – das Bonustor steht offen", 2.8)


func _auf_tor() -> void:
	# Doppelt geprüft: Das Tor meldet nur im offenen Zustand, aber der
	# Raum ist die Stelle, an der die Bedingung wirklich hängt.
	if not _offen or Time.get_ticks_msec() < _tor_sperre:
		return
	betreten(get_tree().get_first_node_in_group("spieler") as Node3D)


# ====================================================== Hin und zurück

func betreten(spieler: Node3D) -> void:
	if _drin or spieler == null or not is_instance_valid(spieler):
		return
	_drin = true
	_rueckkehr = spieler.global_position
	_rueckkehr_blick = spieler.rotation.y
	# Der Checkpoint des Levels wird beiseitegelegt: Solange der Spieler
	# hier drin ist, soll ein Respawn ihn nicht 600 m weit weg ins Level
	# werfen. Direkt gesetzt, nicht über `GameState.setze_checkpoint()` –
	# das würde `checkpoint_gesetzt` melden, und `LevelBasis` schriebe den
	# Kistenstand fest, als wäre eine Checkpointkiste zerschlagen worden.
	_checkpoint_vorher = GameState.checkpoint
	GameState.checkpoint = to_global(EINSTIEG)
	_umgebung_tauschen()
	_kamera_freistellen()
	_versetzen(spieler, to_global(EINSTIEG), 0.0)
	Klang.spiele("checkpoint", 0.85)
	GameState.zeige_nachricht("Bonusraum: %s" % banner, 2.6)


## Zurück ins Level, an genau die Stelle, an der man weg ist.
func verlassen(meldung := "Zurück auf der Strecke") -> void:
	if not _drin:
		return
	_drin = false
	_tor_sperre = Time.get_ticks_msec() + 1500
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	GameState.checkpoint = _checkpoint_vorher
	_umgebung_zurueck()
	_kamera_zurueck()
	if spieler != null and is_instance_valid(spieler):
		_versetzen(spieler, _rueckkehr, _rueckkehr_blick)
	Klang.spiele("landung", 0.8)
	GameState.zeige_nachricht(meldung, 2.0)


## Setzt die Figur um und nimmt die Kamera mit.
##
## `reset_physics_interpolation()` ist Pflicht: Ohne das zieht Godot eine
## Spur über 600 m vom alten zum neuen Ort. Die kurze Sperre danach
## verhindert, dass ein noch gedrückter Knopf im neuen Raum sofort einen
## Sprung auslöst.
func _versetzen(spieler: Node3D, wohin: Vector3, blick: float) -> void:
	if spieler is CharacterBody3D:
		(spieler as CharacterBody3D).velocity = Vector3.ZERO
	if "gesperrt" in spieler:
		spieler.set("gesperrt", true)
	spieler.global_position = wohin
	spieler.rotation.y = blick
	spieler.reset_physics_interpolation()
	if spieler.has_method("setze_blickrichtung"):
		spieler.call("setze_blickrichtung", blick)
	var kamera := _spielkamera()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")
	_sperre_loesen(spieler)


func _sperre_loesen(spieler: Node3D) -> void:
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(spieler) and "gesperrt" in spieler:
		spieler.set("gesperrt", false)


# ------------------------------------------------------------ Kamera

func _spielkamera() -> Camera3D:
	var v := get_viewport()
	return v.get_camera_3d() if v != null else null


## Nimmt der Verfolgerkamera die Levelkurve weg.
##
## Die Korridorkamera fährt auf dem `Path3D` des Levels. Der liegt 600 m
## entfernt; ohne diesen Schritt stünde die Kamera im Dschungel und
## zeigte den Bonusraum überhaupt nicht. Ohne Kurve fällt sie in ihren
## geraden Betrieb zurück – und darauf ist der Raum gebaut: Er läuft
## entlang -Z und liegt um x = 0 herum.
func _kamera_freistellen() -> void:
	_kamera = _spielkamera()
	if _kamera == null or not ("kurve_pfad" in _kamera):
		return
	_kamera_kurve = _kamera.get("kurve_pfad")
	_kamera_seitenblick = float(_kamera.get("seitenblick"))
	_kamera.set("kurve_pfad", NodePath())
	_kamera.set("_kurve_knoten", null)
	_kamera.set("seitenblick", 0.0)


func _kamera_zurueck() -> void:
	if _kamera == null or not is_instance_valid(_kamera):
		return
	if not ("kurve_pfad" in _kamera):
		return
	# Erst den Zeiger leeren, dann den Pfad setzen: Die Kamera holt sich
	# den Knoten nur nach, solange sie keinen hat.
	_kamera.set("_kurve_knoten", null)
	_kamera.set("kurve_pfad", _kamera_kurve)
	_kamera.set("seitenblick", _kamera_seitenblick)


# ------------------------------------------------------------ Umgebung

func _umgebung_tauschen() -> void:
	if _level == null:
		return
	_welt = _finde_umgebung()
	if _welt != null:
		_umgebung_vorher = _welt.environment
		_welt.environment = _umgebung_bauen()
	_sonne = _finde_sonne()
	if _sonne != null:
		_sonne.visible = false


func _umgebung_zurueck() -> void:
	if _welt != null and is_instance_valid(_welt) and _umgebung_vorher != null:
		_welt.environment = _umgebung_vorher
	if _sonne != null and is_instance_valid(_sonne):
		_sonne.visible = true


func _finde_umgebung() -> WorldEnvironment:
	for k in _level.get_children():
		if k is WorldEnvironment:
			return k as WorldEnvironment
	return null


func _finde_sonne() -> DirectionalLight3D:
	for k in _level.get_children():
		if k is DirectionalLight3D:
			return k as DirectionalLight3D
	return null
