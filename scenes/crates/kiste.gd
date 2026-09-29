extends StaticBody3D
class_name Kiste
## Kiste in dreizehn Ausführungen – ein Skript für alle Arten.
##
## Die Art wird im Inspektor über `art` eingestellt, die Optik baut das
## Skript in `_ready()` prozedural auf (Holzkorpus, Kantenstreben, Symbol).
##
## Treffer werden über die Area3D "Trefferzone" erkannt: Sie fragt jeden
## Physikschritt `spieler.angriffe()` ab (siehe scripts/angriff.gd).
## Zusätzlich ruft die Schockwelle des Bauchplatschers bei allen Kisten
## im Umkreis `zerbrechen(Angriff.SLAM)` auf.
##
## UMRISS und AUSLOESER gehören zusammen – das einzige Paar, bei dem eine
## Kiste eine andere schaltet (Kistenvertrag, `doku/level-vorbilder.md`):
## Der Umriss ist ein weißes Gerippe, durch das man hindurchgeht; fällt
## irgendwo im Level der Auslöser, werden ALLE Umrisse zu echten Kisten,
## auf denen man steht. Damit ist ein und dieselbe Kiste erst Kulisse und
## dann Weg – das Muster „ein Hindernis, zwei Rollen".

## Die dreizehn Kistenarten.
##
## Neue Arten kommen ANS ENDE: `LevelBasis` merkt sich im Bauplan den
## Zahlenwert von `art`, und der darf sich nicht verschieben.
enum Art {
	NORMAL,           ## Holzkiste, gibt 1 Frucht
	FRUCHT_MEHRFACH,  ## Holzkiste, gibt 5 Früchte
	LEBEN,            ## gibt ein Extraleben
	FEDER,            ## Sprungkiste: 10 Absprünge, je 1 Frucht
	SPRUNG,           ## reine Sprungfeder, unzerstörbar
	TNT,              ## Countdown 3 s, dann Explosion
	NITRO,            ## explodiert bei jeder Berührung
	EISEN,            ## unzerbrechlich, reine Plattform
	CHECKPOINT,       ## setzt den Respawn-Punkt
	SCHUTZ,           ## gibt eine Schutzladung (bis zu drei stapelbar)
	UMRISS,           ## weißer Umriss, körperlos – wartet auf den Auslöser
	AUSLOESER,        ## Ausrufezeichen: macht alle Umrisse des Levels echt
	ZEIT,             ## Zeitkiste: hält im Zeitmodus die Uhr an
}

# --- Kennwerte ---
const FEDER_SPRUENGE := 10        ## Absprünge der Federkiste
const FEDER_ABPRALL := 15.0       ## Absprunghöhe der Federkiste
const SPRUNG_ABPRALL := 20.0      ## Absprunghöhe der Sprungfeder
const ABPRALL_SPERRE := 0.25      ## Pause zwischen zwei Absprüngen (s)
const TNT_ZEIT := 3.0             ## Countdown der TNT-Kiste
const TNT_RADIUS := 3.0           ## Wirkradius der TNT-Explosion
const NITRO_RADIUS := 2.5         ## Wirkradius der Nitro-Explosion
const FRUECHTE_MEHRFACH := 5      ## Früchte der Mehrfachkiste

# --- Farben des Umriss-Paares ---
# Sie stehen hier und nicht in `Farben`, weil sie nur für dieses Paar
# gelten und der Kistenvertrag sie wörtlich vorgibt: „weißer Umriss,
# körperlos" und „Orange mit gelbem Zeichen".
const UMRISS_WEISS := Color(0.90, 0.96, 1.0)
const AUSLOESER_ORANGE := Color(0.98, 0.38, 0.02)
const AUSLOESER_ZEICHEN := Color(1.0, 0.86, 0.16)
## Halbe Dicke der zwölf Umrisskanten.
const UMRISS_KANTE := 0.05

## Angriffsarten, die eine Holzkiste direkt zerbrechen.
const ZERBRECHENDE_ANGRIFFE := Angriff.SPIN | Angriff.SLIDE | Angriff.SLAM

@export var art: Art = Art.NORMAL
## Standzeit der Zeitkiste in Sekunden – die Zahl, die auf ihr steht.
## Nur für `Art.ZEIT`.
@export_range(1, 9, 1) var zeit_wert := 2

@onready var _modell: Node3D = $Modell
@onready var _trefferzone: Area3D = $Trefferzone

## Restliche Absprünge der Federkiste.
var _spruenge_uebrig := FEDER_SPRUENGE
## Restzeit des TNT-Countdowns (< 0 = nicht gestartet).
var _countdown := -1.0
## Sperre gegen doppelte Absprünge im selben Moment.
var _abprall_sperre := 0.0
## Verhindert doppeltes Zerbrechen/Explodieren.
var _zerstoert := false
## Beschriftungen auf den vier Seiten (für Zahlen, die sich ändern).
var _beschriftungen: Array[Label3D] = []
## Material des Korpus (bei Nitro eine eigene Kopie zum Pulsieren).
var _korpus_material: StandardMaterial3D = null
var _zeit := 0.0
## Umrisskiste: Steht sie schon körperlich da?
##
## Bewusst KEIN @export: `LevelBasis` sichert im Bauplan nur die
## Exportwerte, dieser Zustand würde einen Tod also ohnehin nicht
## überleben. Er soll es auch nicht – siehe `_umrissstand_pruefen()`.
var _koerperlich := false
## Das weiße Gerippe der Umrisskiste und sein eigenes Material.
var _umriss: MeshInstance3D = null
var _umriss_stoff: StandardMaterial3D = null

## Gemeinsame Metallkopien mit gedämpftem Metallanteil (siehe _mattes_metall).
static var _metall_kopien: Dictionary = {}

# --- Fertige Netze je Kistenart (siehe `_netz_holen`) ---
# Das Netz hängt nur an der Art, nicht an der einzelnen Kiste: 43 Kisten
# in Level 01 bauten vorher 43-mal dieselbe Geometrie, jede für sich.
# Die Caches überleben Szenenwechsel (wie `_metall_kopien`) und halten
# deshalb nur Ressourcen, keine Knoten.
static var _korpus_netze: Dictionary[int, ArrayMesh] = {}
## Welche Materialrolle (ROLLE_*) auf welcher Fläche des Korpus liegt –
## leere Gruppen fallen weg, die Flächennummer ist also nicht die Rolle.
static var _korpus_rollen: Dictionary[int, PackedInt32Array] = {}
static var _schatten_netze: Dictionary[int, ArrayMesh] = {}
static var _umriss_netz: ArrayMesh = null

## Materialrollen der Korpusflächen, in dieser Reihenfolge gebaut.
## Level 25 streicht Fläche 0 und 1 um (`_nitro_anstrich`) – die
## Reihenfolge Holz, Rahmen, Metall, Akzent darf sich nicht ändern.
enum { ROLLE_HOLZ, ROLLE_RAHMEN, ROLLE_METALL, ROLLE_AKZENT }

# --- Federn und Zünden (reine Optik, siehe `_form_anwenden`) ---
## Stauchung des Modells: > 0 gedrückt, < 0 gestreckt.
var _stauch := 0.0
## Gleichmäßiges Anschwellen (TNT-Takt), 1 = Ruhe.
var _schwell := 1.0
## Höhenversatz aus dem Wippen der Federkiste.
var _grund_y := 0.0
var _feder_tween: Tween = null
## Letzte angezeigte Zahl des TNT-Countdowns (für den Takt).
var _tnt_zahl := -1
## Eigene Materialkopie der gezündeten TNT-Kiste, die im Takt aufglüht.
var _blinkstoff: StandardMaterial3D = null
var _blink_basis := 0.0


func _ready() -> void:
	add_to_group("kisten")
	collision_layer = 1
	collision_mask = 0
	_trefferzone.collision_layer = 0
	_trefferzone.collision_mask = 2      # nur den Spieler beachten
	_trefferzone.monitoring = true
	_baue_optik()
	# Eisenkisten reagieren auf gar nichts – Abfrage kann entfallen.
	if art == Art.EISEN:
		set_physics_process(false)
	# Nur diese drei Arten bewegen sich pro Bild.
	set_process(art == Art.NITRO or art == Art.TNT or art == Art.FEDER)
	if art == Art.NITRO or art == Art.TNT:
		Explosion.vorwaermen(self)
	if art == Art.UMRISS:
		add_to_group("umrisskisten")
		_koerperlich_setzen(false)
		# Ob sie das bleibt, hängt am Auslöser – und der steht in diesem
		# Moment vielleicht noch gar nicht in der Welt. Deshalb erst am
		# Ende des Bildes nachsehen.
		_umrissstand_pruefen.call_deferred()
	elif art == Art.AUSLOESER:
		# Ein Auslöser, der neu entsteht, ist ein Auslöser, der noch nicht
		# gefallen ist: Nach einem Tod stellt `LevelBasis` ihn wieder hin,
		# und dann müssen auch die Umrisse wieder verschwinden – auch die,
		# die niemand zerschlagen hat und die deshalb nicht neu gebaut
		# werden. Sonst bliebe ein Weg offen, den man nicht bezahlt hat.
		_umrisse_verbergen.call_deferred()


# ---------------------------------------------------------------- Optik

## Aufbau der Kiste (halbe Kantenlänge 0.5):
##   * Kern         – dunkler Innenkasten, sichtbar in den Fugen
##   * Rahmen       – zwölf angefaste Kantenleisten
##   * Bretter      – je Seite drei Bretter mit Fugen dazwischen
##   * Beschläge    – Eckbleche mit Nieten aus Metall
##   * Symbol       – plastisches Relief bzw. eingelassenes Feld
##
## Alles landet in EINEM Mesh mit vier Materialflächen: ein Knoten statt
## vierzig, vier Zeichenaufrufe statt vierzig. Bei 43 Kisten im Level
## macht das den Unterschied.
##
## Den Schatten wirft ein zweites Netz mit nur EINER Fläche (der
## „Schattenriss", dieselbe Geometrie). Die Sonne zeichnet ihre Schatten
## in vier Stufen, und in jeder Stufe kostet jede Fläche einen eigenen
## Zeichenaufruf – der Korpus allein kostete so bis zu sechzehn. Die Form
## des Schattens bleibt dieselbe, nur die Materialien fehlen, und die
## sieht die Schattenkarte ohnehin nicht.

const KERN := 0.41          ## halbe Kantenlänge des Innenkastens
const BRETT_AUSSEN := 0.455 ## Vorderkante der Bretter
const BRETT_TIEFE := 0.06   ## Dicke eines Brettes
const BRETT_BREIT := 0.40   ## halbe Brettlänge
const BRETT_HOCH := 0.125   ## halbe Bretthöhe
const REIHE_Y := 0.275      ## Abstand der äußeren Brettreihen zur Mitte
const LEISTE := 0.05        ## halbe Dicke der Kantenleisten
const FASE := 0.016         ## Kantenfase
const BLECH := 0.095        ## halbe Kantenlänge eines Eckblechs
const BLECH_ECKE := 0.335   ## Sitz der Eckbleche auf der Fläche
const FELD_BREIT := 0.245   ## halbe Breite des eingelassenen Feldes
const ZEICHEN_Z := 0.016    ## Zeichen stehen so weit vor der Brettfläche
const ZEICHEN_TIEFE := 0.024
const FELD_TIEF := 0.395    ## Vorderkante des eingelassenen Feldes
const UV_HOLZ := 2.5        ## Texturwiederholung auf dem Holz
const UV_METALL := 7.0      ## Texturwiederholung auf Metall (feines Korn)

## Die vier Seitenflächen als Paar (Außenrichtung, Rechts-Richtung).
const SEITEN := [
	[Vector3(0.0, 0.0, 1.0), Vector3(1.0, 0.0, 0.0)],
	[Vector3(0.0, 0.0, -1.0), Vector3(-1.0, 0.0, 0.0)],
	[Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0)],
	[Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0)],
]
## Drehung der Beschriftung passend zu SEITEN.
const SEITEN_DREHUNG := [0.0, 180.0, 90.0, -90.0]


## Baut Korpus, Schattenriss, Aufschrift und – beim Umriss – das Gerippe.
func _baue_optik() -> void:
	_korpus_material = _material_fuer_art()
	_netz_holen()

	var korpus := MeshInstance3D.new()
	korpus.name = "Korpus"
	korpus.mesh = _korpus_netze[int(art)]
	# Den Schatten wirft der Schattenriss (siehe Kopf dieses Abschnitts).
	korpus.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rollen: PackedInt32Array = _korpus_rollen[int(art)]
	for i in rollen.size():
		korpus.set_surface_override_material(i, _material_fuer_rolle(rollen[i]))
	_modell.add_child(korpus)

	# Unter `_modell`, damit der Schatten mitfedert und mit dem Modell
	# verschwindet (der Umriss blendet `_modell` aus). Ohne eigenes
	# Material: Der `Leuchtmarker` lässt ihn dann in Ruhe.
	var riss := MeshInstance3D.new()
	riss.name = "Schattenriss"
	riss.mesh = _schatten_netze[int(art)]
	riss.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_modell.add_child(riss)

	_baue_aufschrift()
	_baue_beschriftung()
	if art == Art.UMRISS:
		_baue_umriss()


## Baut Korpus- und Schattennetz dieser Kistenart, falls es sie noch
## nicht gibt.
func _netz_holen() -> void:
	if _korpus_netze.has(int(art)):
		return
	var holz := SurfaceTool.new()
	var rahmen := SurfaceTool.new()
	var metall := SurfaceTool.new()
	var akzent := SurfaceTool.new()
	var gruppen: Array[SurfaceTool] = [holz, rahmen, metall, akzent]
	for st in gruppen:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_baue_kern(rahmen)
	_baue_leisten(rahmen)
	_baue_bretter(holz, rahmen)
	_baue_beschlaege(metall)
	_baue_symbol(rahmen, metall, akzent)

	var gitter := ArrayMesh.new()
	var rollen := PackedInt32Array()
	for rolle in gruppen.size():
		if rolle == ROLLE_AKZENT and art == Art.NORMAL:
			continue
		var st := gruppen[rolle]
		st.index()
		var teil := st.commit()
		if teil == null or teil.get_surface_count() == 0:
			continue                      # leere Materialgruppe überspringen
		gitter.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
				teil.surface_get_arrays(0))
		rollen.append(rolle)

	# Schattenriss: alle Flächen in einer.
	var riss := SurfaceTool.new()
	for i in gitter.get_surface_count():
		riss.append_from(gitter, i, Transform3D.IDENTITY)
	riss.index()

	_korpus_netze[int(art)] = gitter
	_korpus_rollen[int(art)] = rollen
	_schatten_netze[int(art)] = riss.commit()


func _material_fuer_rolle(rolle: int) -> Material:
	match rolle:
		ROLLE_HOLZ:
			return _korpus_material
		ROLLE_RAHMEN:
			return _rahmen_material()
		ROLLE_METALL:
			return _metall_material()
		_:
			return _akzent_material()


## Das weiße Gerippe: zwölf dünne Kanten, sonst nichts.
##
## Es steht NEBEN dem fertigen Korpus, nicht an seiner Stelle. Beides wird
## einmal gebaut und beim Auslösen nur umgeschaltet – eine Kiste, die
## mitten im Spiel ihr Mesh neu aufbaut, würde genau in dem Moment
## stocken, in dem der Spieler hinschaut.
func _baue_umriss() -> void:
	if _umriss_netz == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for achse in 3:
			var u := (achse + 1) % 3
			var w := (achse + 2) % 3
			var halb := Vector3.ONE * UMRISS_KANTE
			# Die senkrechten Pfosten laufen durch, die Querriegel stoßen an –
			# sonst überlagern sich an jeder Ecke zwei durchscheinende Körper
			# und die Ecken leuchten heller als die Kanten.
			halb[achse] = 0.5 if achse == 1 else 0.5 - UMRISS_KANTE * 2.0
			for su: float in [-1.0, 1.0]:
				for sw: float in [-1.0, 1.0]:
					var mitte := Vector3.ZERO
					mitte[u] = su * (0.5 - UMRISS_KANTE)
					mitte[w] = sw * (0.5 - UMRISS_KANTE)
					Kistengeometrie.quader(st, mitte, halb, 0.0, 1.0)
		st.index()
		_umriss_netz = st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Umriss"
	mi.mesh = _umriss_netz
	_umriss_stoff = _umriss_material()
	mi.material_override = _umriss_stoff
	# Was nicht da ist, wirft keinen Schatten.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_umriss = mi


## Weiß, durchscheinend, selbstleuchtend – auch im Gewitterlevel lesbar.
## Eigene Kopie, weil der Umriss atmet (siehe `_process`) und die
## Bibliothek ihre Materialien an alle austeilt.
func _umriss_material() -> StandardMaterial3D:
	var m := Materialbibliothek.transparent(
			UMRISS_WEISS, 1.1).duplicate() as StandardMaterial3D
	m.albedo_color.a = 0.55
	return m


## Dunkler Innenkasten – man sieht ihn durch die Fugen zwischen den Brettern.
func _baue_kern(st: SurfaceTool) -> void:
	Kistengeometrie.quader(st, Vector3.ZERO, Vector3.ONE * KERN, 0.0, UV_HOLZ)


## Zwölf angefaste Kantenleisten: vier senkrechte Pfosten, acht Querriegel.
func _baue_leisten(st: SurfaceTool) -> void:
	for achse in 3:
		var u := (achse + 1) % 3
		var w := (achse + 2) % 3
		var halb := Vector3(LEISTE, LEISTE, LEISTE)
		# Die senkrechten Pfosten laufen durch, die Querriegel stoßen daran an.
		halb[achse] = 0.5 if achse == 1 else 0.46
		for su: float in [-1.0, 1.0]:
			for sw: float in [-1.0, 1.0]:
				var mitte := Vector3.ZERO
				mitte[u] = su * (0.5 - LEISTE)
				mitte[w] = sw * (0.5 - LEISTE)
				Kistengeometrie.quader(st, mitte, halb, FASE, UV_HOLZ)


## Je Seite drei Bretter mit Fugen; bei Kisten mit Feld ist die mittlere
## Reihe geteilt und gibt den Blick auf die eingelassene Fläche frei.
func _baue_bretter(holz: SurfaceTool, rahmen: SurfaceTool) -> void:
	for seite in SEITEN:
		_brettreihe(holz, rahmen, seite[0], seite[1], Vector3.UP, _hat_feld())
	_brettreihe(holz, rahmen, Vector3.UP, Vector3.RIGHT, Vector3.BACK, false)
	_brettreihe(holz, rahmen, Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD, false)


func _brettreihe(holz: SurfaceTool, rahmen: SurfaceTool, aus: Vector3,
		rechts: Vector3, hoch: Vector3, mit_feld: bool) -> void:
	var tf := Transform3D(Basis(rechts, hoch, aus), aus * (BRETT_AUSSEN - BRETT_TIEFE * 0.5))
	# Leichter Tiefenversatz je Reihe – so wirft jede Fuge einen Schatten.
	var versatz: Array[float] = [0.0, 0.006, -0.004]
	for i in 3:
		var y := (float(i) - 1.0) * REIHE_Y
		var halb := Vector3(BRETT_BREIT, BRETT_HOCH, BRETT_TIEFE * 0.5)
		if i == 1 and mit_feld:
			var rest := (BRETT_BREIT - FELD_BREIT) * 0.5
			for vz: float in [-1.0, 1.0]:
				Kistengeometrie.quader(holz,
						Vector3(vz * (FELD_BREIT + rest), y, versatz[i]),
						Vector3(rest, BRETT_HOCH, BRETT_TIEFE * 0.5), FASE, UV_HOLZ, tf)
			continue
		Kistengeometrie.quader(holz, Vector3(0.0, y, versatz[i]), halb, FASE, UV_HOLZ, tf)

	if mit_feld:
		# Eingelassene Fläche hinter der Lücke
		var tief := Transform3D(Basis(rechts, hoch, aus), aus * FELD_TIEF)
		Kistengeometrie.quader(rahmen, Vector3.ZERO,
				Vector3(FELD_BREIT + 0.015, BRETT_HOCH + 0.015, 0.04), 0.008, UV_HOLZ, tief)


## Eckbleche mit Niete auf den vier Seiten und oben.
func _baue_beschlaege(st: SurfaceTool) -> void:
	var flaechen: Array = []
	for seite in SEITEN:
		flaechen.append([seite[0], seite[1], Vector3.UP])
	flaechen.append([Vector3.UP, Vector3.RIGHT, Vector3.BACK])
	for f in flaechen:
		var tf := Transform3D(Basis(f[1], f[2], f[0]), f[0] * BRETT_AUSSEN)
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				var mitte := Vector3(sx * BLECH_ECKE, sy * BLECH_ECKE, 0.012)
				Kistengeometrie.quader(st, mitte, Vector3(BLECH, BLECH, 0.012),
						0.006, UV_METALL, tf)
				Kistengeometrie.kuppel(st, Vector3.ZERO, 0.029, 0.024, 8, 2, UV_METALL,
						tf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
						mitte + Vector3(0.0, 0.0, 0.012)))


# ---------------------------------------------------------------- Symbole

## Symbol je Art – plastisch, damit es nicht wie ein aufgeklebter Zettel wirkt.
## Nur Geometrie: Das Netz wird je Art EINMAL gebaut und geteilt (siehe
## `_netz_holen`); was jede Kiste selbst braucht, steht in `_baue_aufschrift`.
func _baue_symbol(rahmen: SurfaceTool, metall: SurfaceTool, akzent: SurfaceTool) -> void:
	match art:
		Art.LEBEN:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_leben(akzent, tf))
		Art.FEDER:
			_sym_feder(akzent)
		Art.SPRUNG:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_sprung(akzent, tf))
			_sym_sprungteller(metall, akzent)
		Art.TNT:
			# Der Schriftzug kommt aus `_baue_beschriftung()`, weil er im
			# Countdown zur Zahl wird. Ein zweites, festes "TNT" stand
			# früher davor und verdeckte genau diese Zahl.
			_sym_zuendschnur(rahmen, metall)
		Art.NITRO:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_totenkopf(akzent, rahmen, tf))
			_sym_ventil(akzent, metall)
		Art.EISEN:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_eisen(akzent, tf))
		Art.CHECKPOINT:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_checkpoint(akzent, rahmen, tf))
			_sym_fahne(akzent, rahmen)
		Art.SCHUTZ:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_schutz(akzent, tf))
		Art.AUSLOESER:
			_sym_ausloeser(akzent, metall)
		Art.ZEIT:
			# Die Zahl steht im eingelassenen Feld (siehe `_symboltext()`),
			# das Zifferblatt obenauf – wie bei der Auslöserkiste, weil die
			# Kamera von schräg oben schaut und man im Lauf keine Zeit hat,
			# die Seitenflächen zu lesen.
			_sym_zifferblatt(metall, akzent)
		_:
			pass


## Feste Schrift auf den Seiten – je Kiste eigene Knoten, deshalb nicht
## im geteilten Netz.
func _baue_aufschrift() -> void:
	match art:
		Art.FRUCHT_MEHRFACH:
			_beschriften("?", 0.44, Color(0.16, 0.10, 0.03))
		Art.NITRO:
			# Totenkopf oben, Schriftzug darunter – wie in den Vorlagen.
			_beschriften("NITRO", 0.105, Color(1.0, 0.98, 0.92), -0.095)
		Art.AUSLOESER:
			# Dasselbe Verfahren wie beim Fragezeichen: eine echte Schrift
			# statt eines Reliefs aus Balken (Begründung bei `_beschriften`).
			_beschriften("!", 0.44, AUSLOESER_ZEICHEN)
		_:
			pass


## Ruft `bau` mit dem Transform jeder der vier Seitenflächen auf.
## Ursprung liegt auf der Brettfläche, +X rechts, +Y oben, +Z nach außen.
func _auf_seiten(bau: Callable) -> void:
	for seite in SEITEN:
		bau.call(Transform3D(Basis(seite[1], Vector3.UP, seite[0]),
				seite[0] * BRETT_AUSSEN))


## Totenkopf auf der Nitrokiste, zusätzlich zum Schriftzug.
##
## Schädel und Kiefer im hellen Akzent, Augenhöhlen und Nase dunkel
## darüber. Die Augen nehmen ein knappes Drittel der Schädelbreite ein –
## kleiner blieb aus Spielentfernung nur ein weißer Fleck übrig.
func _sym_totenkopf(akzent: SurfaceTool, rahmen: SurfaceTool,
		tf: Transform3D) -> void:
	var vorn := ZEICHEN_Z + ZEICHEN_TIEFE * 0.5 + 0.004
	Kistengeometrie.quader(akzent, Vector3(0.0, 0.128, ZEICHEN_Z),
			Vector3(0.160, 0.110, ZEICHEN_TIEFE), 0.036, UV_METALL, tf)
	Kistengeometrie.quader(akzent, Vector3(0.0, 0.048, ZEICHEN_Z),
			Vector3(0.078, 0.058, ZEICHEN_TIEFE), 0.018, UV_METALL, tf)
	for vz: float in [-1.0, 1.0]:
		Kistengeometrie.quader(rahmen, Vector3(vz * 0.038, 0.136, vorn),
				Vector3(0.052, 0.052, 0.016), 0.016, UV_METALL, tf)
	Kistengeometrie.quader(rahmen, Vector3(0.0, 0.092, vorn),
			Vector3(0.024, 0.028, 0.016), 0.006, UV_METALL, tf)
	for vz: float in [-1.0, 1.0]:
		Kistengeometrie.quader(rahmen, Vector3(vz * 0.019, 0.048, vorn),
				Vector3(0.011, 0.058, 0.016), 0.004, UV_METALL, tf)


## Aufschrift auf allen vier Seiten.
##
## Zuerst waren "?" und "TNT" als Relief aus Balken gebaut. Bei
## Kistengröße lief das nicht: Ein Strich, der dick genug ist, um eine
## Kante zu werfen, ist zugleich so dick, dass die Lücken im Zeichen
## zulaufen – aus dem Fragezeichen wurde ein Klumpen. Eine echte Schrift
## löst genau das, ist aus jeder Entfernung eindeutig und entspricht den
## Vorlagen, die ihre Kisten ebenfalls beschriften.
func _beschriften(text: String, hoehe: float, farbe: Color,
		versatz_y: float = 0.0) -> void:
	for seite in SEITEN:
		var schild := Label3D.new()
		schild.text = text
		schild.font_size = 128
		schild.pixel_size = hoehe / 128.0
		schild.modulate = farbe
		schild.outline_size = 22
		schild.outline_modulate = Color(0.04, 0.03, 0.02, 0.85)
		schild.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		schild.double_sided = false
		schild.shaded = true
		schild.no_depth_test = false
		# Liegt flach auf dem Brett, ein Schatten davon wäre nicht zu sehen –
		# gezeichnet würde er trotzdem, in jeder der vier Schattenstufen.
		schild.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Etwas vor der Brettfläche, damit die Schrift nicht in den
		# Brettern flimmert.
		schild.position = seite[0] * (BRETT_AUSSEN + 0.012) \
				+ Vector3.UP * versatz_y
		add_child(schild)
		schild.basis = Basis(seite[1], Vector3.UP, seite[0])


## Erhabenes Kreuz für die Lebenskiste.
## Schutz: ein Wappenschild, aus vier nach unten schmaler werdenden Lagen
## aufgebaut. Aus der Spielkamera reicht die Silhouette – ein feiner
## gezeichnetes Wappen wäre bei dieser Größe nicht zu erkennen.
func _sym_schutz(st: SurfaceTool, tf: Transform3D) -> void:
	var lagen := [
		{"y": 0.075, "b": 0.190, "h": 0.055},
		{"y": 0.020, "b": 0.175, "h": 0.058},
		{"y": -0.040, "b": 0.130, "h": 0.060},
		{"y": -0.092, "b": 0.062, "h": 0.048},
	]
	for lage in lagen:
		Kistengeometrie.quader(st, Vector3(0.0, lage["y"], 0.018),
				Vector3(lage["b"], lage["h"], 0.022), 0.008, UV_METALL, tf)


func _sym_leben(st: SurfaceTool, tf: Transform3D) -> void:
	Kistengeometrie.quader(st, Vector3(0.0, 0.0, 0.018),
			Vector3(0.055, 0.185, 0.022), 0.01, UV_METALL, tf)
	Kistengeometrie.quader(st, Vector3(0.0, 0.0, 0.018),
			Vector3(0.185, 0.055, 0.022), 0.01, UV_METALL, tf)


## Sprungfeder oben auf der Federkiste (die Zahl steht im Feld darunter).
func _sym_feder(st: SurfaceTool) -> void:
	var radien: Array[float] = [0.24, 0.205, 0.17, 0.135]
	for i in radien.size():
		var y := 0.50 + 0.045 * float(i)
		Kistengeometrie.zylinder(st, Vector3(0.0, y, 0.0), radien[i],
				radien[i] * 0.92, 0.028, 12, UV_METALL)
	Kistengeometrie.zylinder(st, Vector3(0.0, 0.70, 0.0), 0.15, 0.15, 0.035, 12, UV_METALL)


## Doppelter Aufwärtspfeil für die Sprungfeder.
func _sym_sprung(st: SurfaceTool, tf: Transform3D) -> void:
	for y: float in [-0.20, 0.06]:
		for vz: float in [-1.0, 1.0]:
			Kistengeometrie.schraeg_quader(st,
					Vector3(vz * 0.10, y, 0.02), Vector3(0.155, 0.036, 0.024),
					-vz * 0.66, 0.012, UV_METALL, tf)


## Metallteller obenauf – zeigt, dass man hier abspringt.
func _sym_sprungteller(metall: SurfaceTool, akzent: SurfaceTool) -> void:
	Kistengeometrie.zylinder(metall, Vector3(0.0, 0.525, 0.0), 0.31, 0.31, 0.05, 16, UV_METALL)
	Kistengeometrie.zylinder(akzent, Vector3(0.0, 0.565, 0.0), 0.16, 0.13, 0.04, 12, UV_METALL)


## Zündschnur auf der TNT-Kiste. Die Schnur ist dunkel (Rahmenmaterial),
## damit der helle Akzent allein dem Schriftzug gehört.
func _sym_zuendschnur(rahmen: SurfaceTool, metall: SurfaceTool) -> void:
	Kistengeometrie.zylinder(metall, Vector3(0.0, 0.52, 0.0), 0.10, 0.09, 0.05, 10, UV_METALL)
	var dreh := Transform3D(Basis(Vector3.FORWARD, 0.35), Vector3(0.0, 0.60, 0.0))
	Kistengeometrie.zylinder(rahmen, Vector3(0.0, 0.06, 0.0), 0.026, 0.02, 0.16, 8,
			UV_METALL, dreh)
	Kistengeometrie.kuppel(rahmen, Vector3(0.0, 0.14, 0.0), 0.05, 0.05, 10, 3, UV_METALL, dreh)


## Gelbe Signalkuppel oben auf der Auslöserkiste.
##
## Die Kamera schaut von schräg oben auf den Korridor – ein Zeichen, das
## nur an den vier Seiten steht, sieht man dort am schlechtesten. Deshalb
## trägt gerade diese Kiste ihr Signal auch obenauf.
func _sym_ausloeser(akzent: SurfaceTool, metall: SurfaceTool) -> void:
	Kistengeometrie.zylinder(metall, Vector3(0.0, 0.525, 0.0), 0.17, 0.15,
			0.05, 12, UV_METALL)
	Kistengeometrie.kuppel(akzent, Vector3(0.0, 0.55, 0.0), 0.13, 0.11, 12, 3,
			UV_METALL)


## Zifferblatt oben auf der Zeitkiste: heller Teller, zwölf Marken auf
## dem Rand und zwei Zeiger. Der große Zeiger steht auf zwei Uhr, der
## kleine auf zwölf – eine stehende Uhr, und genau das tut die Kiste.
func _sym_zifferblatt(metall: SurfaceTool, akzent: SurfaceTool) -> void:
	Kistengeometrie.zylinder(metall, Vector3(0.0, 0.515, 0.0), 0.30, 0.30,
			0.03, 16, UV_METALL)
	Kistengeometrie.zylinder(akzent, Vector3(0.0, 0.545, 0.0), 0.265, 0.265,
			0.022, 16, UV_METALL)
	# Stundenmarken auf dem Rand
	for i in 12:
		var winkel := TAU * float(i) / 12.0
		var lang := i % 3 == 0
		var r := 0.215
		# Ort UND Ausrichtung kommen aus derselben Drehung: `quader` legt
		# `mitte` durch `tf`, die Marke muss also im gedrehten System
		# stehen (0, y, r) und nicht schon selbst um den Kreis gerechnet
		# sein – sonst dreht sie zweimal und sitzt beim doppelten Winkel.
		Kistengeometrie.quader(metall, Vector3(0.0, 0.560, r),
				Vector3(0.016, 0.008, 0.040 if lang else 0.024),
				0.004, UV_METALL,
				Transform3D(Basis(Vector3.UP, winkel), Vector3.ZERO))
	# Zeiger: lang auf zwei Uhr, kurz auf zwölf
	Kistengeometrie.quader(metall, Vector3(0.0, 0.566, 0.085),
			Vector3(0.014, 0.010, 0.090), 0.004, UV_METALL,
			Transform3D(Basis(Vector3.UP, TAU / 6.0), Vector3.ZERO))
	Kistengeometrie.quader(metall, Vector3(0.0, 0.566, 0.055),
			Vector3(0.016, 0.010, 0.060), 0.004, UV_METALL)
	Kistengeometrie.kuppel(metall, Vector3(0.0, 0.566, 0.0), 0.030, 0.020,
			10, 2, UV_METALL)


## Ventilstutzen oben auf der Nitrokiste.
func _sym_ventil(akzent: SurfaceTool, metall: SurfaceTool) -> void:
	Kistengeometrie.zylinder(metall, Vector3(0.0, 0.53, 0.0), 0.11, 0.09, 0.06, 10, UV_METALL)
	Kistengeometrie.zylinder(akzent, Vector3(0.0, 0.575, 0.0), 0.05, 0.05, 0.05, 8, UV_METALL)


## Diagonale Verstrebung – macht die Eisenkiste sofort erkennbar.
func _sym_eisen(st: SurfaceTool, tf: Transform3D) -> void:
	for vz: float in [-1.0, 1.0]:
		Kistengeometrie.schraeg_quader(st, Vector3(0.0, 0.0, 0.016),
				Vector3(0.34, 0.038, 0.02), vz * PI * 0.25, 0.01, UV_METALL, tf)
	Kistengeometrie.kuppel(st, Vector3.ZERO, 0.075, 0.045, 10, 3, UV_METALL,
			tf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, 0.02)))


## Zielflaggen-Karo auf der Checkpointkiste.
func _sym_checkpoint(akzent: SurfaceTool, rahmen: SurfaceTool, tf: Transform3D) -> void:
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var st := akzent if sx * sy > 0.0 else rahmen
			Kistengeometrie.quader(st, Vector3(sx * 0.075, sy * 0.075, 0.016),
					Vector3(0.072, 0.072, 0.02), 0.008, UV_METALL, tf)


## Kleine Zielflagge oben auf der Checkpointkiste.
func _sym_fahne(akzent: SurfaceTool, rahmen: SurfaceTool) -> void:
	Kistengeometrie.zylinder(rahmen, Vector3(-0.22, 0.68, 0.22), 0.024, 0.02, 0.38, 8, UV_METALL)
	for i in 2:
		for j in 2:
			var st := akzent if (i + j) % 2 == 0 else rahmen
			Kistengeometrie.quader(st, Vector3(-0.14 + float(i) * 0.09,
					0.80 - float(j) * 0.09, 0.22), Vector3(0.045, 0.045, 0.009),
					0.006, UV_METALL)


# ---------------------------------------------------------------- Materialien

## Farbe und Material des Bretterkorpus.
func _material_fuer_art() -> StandardMaterial3D:
	match art:
		Art.FRUCHT_MEHRFACH:
			return Materialbibliothek.kistenholz(Farben.KISTE_FRAGE)
		Art.LEBEN:
			return Materialbibliothek.kistenholz(Farben.KISTE_LEBEN)
		Art.FEDER:
			return Materialbibliothek.kistenholz(Farben.KISTE_FEDER)
		Art.CHECKPOINT:
			return Materialbibliothek.kistenholz(Farben.KISTE_CHECKPOINT)
		Art.SCHUTZ:
			return Materialbibliothek.kistenholz(Farben.KISTE_SCHUTZ)
		Art.TNT:
			return Materialbibliothek.kistenholz(Farben.KISTE_TNT)
		Art.NITRO:
			# Eigene Kopie mit Eigenleuchten, damit das Pulsieren keine
			# anderen Kisten stört – die Maserung bleibt dabei erhalten.
			var m := Materialbibliothek.kistenholz(
					Farben.KISTE_NITRO).duplicate() as StandardMaterial3D
			m.emission_enabled = true
			m.emission = Farben.KISTE_NITRO
			m.emission_energy_multiplier = 0.2
			return m
		Art.SPRUNG:
			return _mattes_metall(Farben.KISTE_SPRUNG)
		Art.EISEN:
			return _mattes_metall(Farben.KISTE_EISEN)
		Art.AUSLOESER:
			return Materialbibliothek.kistenholz(AUSLOESER_ORANGE)
		Art.ZEIT:
			return Materialbibliothek.kistenholz(Farben.KISTE_ZEIT)
		_:
			# Auch die ausgelöste Umrisskiste landet hier: Sobald sie da
			# ist, ist sie eine gewöhnliche Holzkiste, und sie soll auch
			# so aussehen. Das Weiß gehört dem Zustand, nicht der Kiste.
			return Materialbibliothek.kistenholz(Farben.HOLZ)


## Material der Kantenleisten, des Kerns und der eingelassenen Felder.
func _rahmen_material() -> StandardMaterial3D:
	match art:
		Art.EISEN, Art.SPRUNG:
			return _mattes_metall(Farben.KISTE_EISEN.darkened(0.35))
		Art.FRUCHT_MEHRFACH:
			return Materialbibliothek.kistenholz(Farben.KISTE_FRAGE.darkened(0.55))
		Art.LEBEN:
			return Materialbibliothek.kistenholz(Farben.KISTE_LEBEN.darkened(0.48))
		Art.CHECKPOINT:
			return Materialbibliothek.kistenholz(Farben.KISTE_CHECKPOINT.darkened(0.5))
		Art.SCHUTZ:
			return Materialbibliothek.kistenholz(Farben.KISTE_SCHUTZ.darkened(0.5))
		Art.TNT:
			return Materialbibliothek.kistenholz(Farben.KISTE_TNT.darkened(0.52))
		Art.NITRO:
			return Materialbibliothek.kistenholz(Farben.KISTE_NITRO.darkened(0.55))
		Art.FEDER:
			return Materialbibliothek.kistenholz(Farben.KISTE_FEDER.darkened(0.5))
		Art.AUSLOESER:
			return Materialbibliothek.kistenholz(AUSLOESER_ORANGE.darkened(0.55))
		Art.ZEIT:
			return Materialbibliothek.kistenholz(Farben.KISTE_ZEIT.darkened(0.55))
		_:
			return Materialbibliothek.kistenholz(Farben.HOLZ_DUNKEL)


## Material der Eckbleche und Nieten.
func _metall_material() -> StandardMaterial3D:
	if art == Art.EISEN or art == Art.SPRUNG:
		return _mattes_metall(Farben.FELS_HELL)
	return _mattes_metall(Farben.KISTE_EISEN)


## Metall aus der Bibliothek mit gedämpftem Metallanteil.
##
## `Materialbibliothek.metall()` ist voll metallisch (0.85). Ohne
## Spiegelungssonde hat solches Metall nichts zu spiegeln und wird im
## Bild fast schwarz. Für Beschläge zählt aber die Form, nicht der
## Spiegel – deshalb hier eine Kopie mit weniger Metallanteil.
static func _mattes_metall(farbe: Color) -> StandardMaterial3D:
	var schluessel := farbe.to_html()
	if not _metall_kopien.has(schluessel):
		var m := Materialbibliothek.metall(farbe).duplicate() as StandardMaterial3D
		m.metallic = 0.3
		m.roughness = 0.45
		_metall_kopien[schluessel] = m
	return _metall_kopien[schluessel]


## Material des Symbols.
func _akzent_material() -> StandardMaterial3D:
	match art:
		Art.FRUCHT_MEHRFACH:
			# Dunkel auf Gelb – die Vorlagen setzen das Fragezeichen als
			# schwarzes Zeichen auf die helle Fläche, nicht umgekehrt.
			return Materialbibliothek.einfarbig(Color(0.14, 0.09, 0.03), 0.55)
		Art.LEBEN:
			return Materialbibliothek.leuchtend(Color(0.96, 1.0, 0.94), 0.25)
		Art.FEDER, Art.EISEN:
			return _mattes_metall(Farben.FELS_HELL)
		Art.SPRUNG:
			return Materialbibliothek.leuchtend(Color(0.86, 0.95, 1.0), 0.5)
		Art.SCHUTZ:
			return Materialbibliothek.leuchtend(Color(0.82, 0.95, 1.0), 0.6)
		Art.TNT:
			# Heller Schriftzug auf dem roten Korpus, wie in den Vorlagen.
			return Materialbibliothek.einfarbig(Color(0.97, 0.94, 0.86), 0.55)
		Art.NITRO:
			# Knochenweiß für den Totenkopf.
			return Materialbibliothek.einfarbig(Color(0.94, 0.96, 0.90), 0.5)
		Art.CHECKPOINT:
			return Materialbibliothek.einfarbig(Color(0.96, 0.98, 0.94), 0.7)
		Art.AUSLOESER:
			# Die Kuppel leuchtet leicht: Sie ist der einzige Knopf im
			# Spiel, und man soll sie auch im Regen und im Dunkeln finden.
			return Materialbibliothek.leuchtend(AUSLOESER_ZEICHEN, 0.55)
		Art.ZEIT:
			# Helles Zifferblatt: Im Zeitlauf sieht man die Kiste meist nur
			# im Vorbeilaufen, und dann muss der Teller obenauf tragen.
			return Materialbibliothek.leuchtend(Color(0.96, 0.98, 1.0), 0.5)
		_:
			return Materialbibliothek.einfarbig(Farben.HOLZ_DUNKEL, 0.8)


# ---------------------------------------------------------------- Beschriftung

## Nur TNT und Feder tragen Text – die Zahl ändert sich zur Laufzeit und
## sitzt deshalb als Label3D in der eingelassenen Fläche.
func _baue_beschriftung() -> void:
	var text := _symboltext()
	if text == "":
		return
	for i in SEITEN.size():
		var schild := Label3D.new()
		schild.text = text
		schild.font_size = 60
		schild.pixel_size = 0.0034
		schild.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		schild.double_sided = false
		schild.modulate = _symbolfarbe()
		schild.outline_size = 10
		schild.outline_modulate = Color(0.06, 0.05, 0.04, 0.95)
		schild.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		schild.position = SEITEN[i][0] * 0.442
		schild.rotation_degrees = Vector3(0.0, SEITEN_DREHUNG[i], 0.0)
		_modell.add_child(schild)
		_beschriftungen.append(schild)


## Kisten mit eingelassener Fläche in der mittleren Brettreihe.
func _hat_feld() -> bool:
	return art == Art.TNT or art == Art.FEDER or art == Art.NITRO \
			or art == Art.FRUCHT_MEHRFACH or art == Art.AUSLOESER \
			or art == Art.ZEIT


## Symbol je Art. Leerer Text = keine Beschriftung.
func _symboltext() -> String:
	match art:
		Art.FEDER:
			return str(_spruenge_uebrig)
		Art.TNT:
			return "TNT"
		Art.ZEIT:
			return str(zeit_wert)
		_:
			return ""


func _symbolfarbe() -> Color:
	match art:
		Art.TNT:
			return Color(1.0, 0.94, 0.85)
		Art.ZEIT:
			return Color(1.0, 0.98, 0.92)
		_:
			return Color(0.99, 0.95, 0.86)


## Setzt den Text aller vier Beschriftungen.
func _setze_beschriftung(text: String) -> void:
	for schild in _beschriftungen:
		if is_instance_valid(schild):
			schild.text = text


# ---------------------------------------------------------------- Ablauf

func _process(delta: float) -> void:
	_zeit += delta
	if _zerstoert or not is_instance_valid(_modell):
		return
	match art:
		Art.NITRO:
			# Warnendes Pulsieren
			var puls := 0.5 + 0.5 * sin(_zeit * 6.0)
			if _korpus_material != null:
				_korpus_material.emission_energy_multiplier = 0.08 + puls * 0.34
			_modell.scale = Vector3.ONE * (1.0 + puls * 0.04)
		Art.TNT:
			if _countdown >= 0.0:
				# Wackeln, je knapper die Zeit, desto heftiger
				var heftig := 0.03 + (1.0 - _countdown / TNT_ZEIT) * 0.05
				_modell.position.x = sin(_zeit * 47.0) * heftig
				_modell.position.z = cos(_zeit * 39.0) * heftig
				_form_anwenden()
		Art.FEDER:
			_grund_y = sin(_zeit * 3.0) * 0.02
			_form_anwenden()
		Art.UMRISS:
			# Der Umriss atmet. Ein weißes Gerippe, das still steht, liest
			# sich als Deko; eines, das langsam heller und dunkler wird,
			# als etwas, das noch aussteht.
			if _umriss_stoff != null:
				var atem := 0.5 + 0.5 * sin(_zeit * 2.4)
				_umriss_stoff.emission_energy_multiplier = 0.7 + atem * 0.9
				_umriss_stoff.albedo_color.a = 0.40 + atem * 0.30


func _physics_process(delta: float) -> void:
	if _zerstoert:
		return
	_abprall_sperre = maxf(_abprall_sperre - delta, 0.0)

	if art == Art.TNT and _countdown >= 0.0:
		_countdown -= delta
		var zahl := maxi(int(ceil(_countdown)), 0)
		_setze_beschriftung(str(zahl))
		if zahl != _tnt_zahl and zahl > 0:
			_tnt_zahl = zahl
			_tnt_takt()
		if _countdown <= 0.0:
			_explodieren(TNT_RADIUS, Farben.KISTE_TNT, true)
			return

	var spieler := _spieler_in_zone()
	if spieler == null:
		return
	_auf_spieler(spieler)


## Sucht den Spieler in der Trefferzone.
func _spieler_in_zone() -> Spieler:
	for koerper in _trefferzone.get_overlapping_bodies():
		if koerper is Spieler:
			return koerper as Spieler
	return null


## Echte Berührung: Der Spieler steht an oder auf der Kiste.
## Die Trefferzone reicht bewusst höher (damit ein schneller Fall erkannt
## wird, bevor die Landung `velocity.y` auf 0 setzt) – für die Nitrokiste
## ist das zu großzügig, deshalb hier die enge Prüfung.
func _beruehrt(spieler: Spieler) -> bool:
	var ab: Vector3 = spieler.global_position - global_position
	return absf(ab.x) < 0.88 and absf(ab.z) < 0.88 and ab.y > -1.35 and ab.y < 0.6


## Wertet die Angriffe des Spielers aus.
func _auf_spieler(spieler: Spieler) -> void:
	var maske: int = spieler.angriffe()
	# "Draufspringen": fällt schnell genug UND ist über der Kistenmitte.
	var von_oben: bool = (maske & Angriff.FALLEN) != 0 \
			and spieler.global_position.y > global_position.y + 0.4

	match art:
		Art.EISEN:
			pass
		Art.SPRUNG:
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				spieler.abprallen(SPRUNG_ABPRALL)
				_federn(0.4)
		Art.FEDER:
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				_feder_absprung(spieler)
				_federn(0.35)
		Art.NITRO:
			# Nur echte Berührung ist tödlich – Drüberspringen bleibt erlaubt.
			if _beruehrt(spieler):
				_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
				spieler.schaden_nehmen()
		Art.TNT:
			if _countdown < 0.0 and ((maske & ZERBRECHENDE_ANGRIFFE) != 0 or von_oben):
				_zuenden()
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				spieler.abprallen()
				_federn(0.3)
		_:
			if (maske & ZERBRECHENDE_ANGRIFFE) != 0 or von_oben:
				zerbrechen(maske)


## Ein Absprung von der Federkiste: 1 Frucht, danach ein Sprung weniger.
func _feder_absprung(spieler: Spieler) -> void:
	spieler.abprallen(FEDER_ABPRALL)
	_spruenge_uebrig -= 1
	Frucht.streuen(get_parent(), global_position, 1)
	if _spruenge_uebrig <= 0:
		_zerbrechen_ausfuehren(0)
	else:
		_setze_beschriftung(str(_spruenge_uebrig))


# ---------------------------------------------------------------- Schnittstelle

## True, wenn diese Kiste im Kistenzähler des Levels mitzählt.
## Checkpoint-, Sprung- und Eisenkisten zählen nicht.
##
## DIE UMRISSKISTE ZÄHLT MIT, UND ZWAR VON ANFANG AN – auch solange sie
## nur ein Gerippe ist. Nachgesehen in `LevelBasis._kisten_zaehlen()`:
## Die Gesamtzahl wird EINMAL beim Aufbau ermittelt und danach nie wieder;
## `GameState.kisten_gesamt` ist für den Rest des Levels eine feste Zahl.
## Eine Kiste, die erst später mitzählte, hätte also zwei Folgen: Der
## Zähler in der Anzeige spränge mitten im Level von „40" auf „44", und
## wer vorher alle übrigen Kisten geholt hat, bekäme „Alle Kisten!"
## gemeldet, das ihm gleich darauf wieder abhandenkäme. Zählt sie dagegen
## von Anfang an mit, steht die Zahl fest und sagt genau das, was das
## Vorbild sagen will: Ohne den Auslöser gibt es keine hundert Prozent.
func zaehlt_mit() -> bool:
	return art != Art.CHECKPOINT and art != Art.SPRUNG and art != Art.EISEN


# ------------------------------------------------- Umriss und Auslöser

## Aus dem Umriss wird eine echte Kiste. Ruft die Auslöserkiste.
func erscheinen() -> void:
	if art != Art.UMRISS or _koerperlich or _zerstoert:
		return
	_koerperlich_setzen(true)
	# Kurzes Aufploppen: Der Spieler steht oft weit weg vom Auslöser und
	# soll die Bewegung im Augenwinkel mitbekommen.
	_modell.scale = Vector3.ONE * 0.55
	var t := create_tween()
	t.tween_property(_modell, "scale", Vector3.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ein Funkenkranz in der Farbe des Gerippes: Aus der Ferne ist das
	# Aufploppen allein nur ein Zucken, die Funken sieht man. Kurz verzögert:
	# Alle Umrisse erscheinen im selben Bild wie der Bruch des Auslösers,
	# und so konkurrieren sie nicht mit dessen Stößen um die Grenze je Bild.
	t.parallel().tween_callback(func() -> void:
			Effekte.funken(self, global_position, UMRISS_WEISS, 8, 2.8, 0.18)) \
			.set_delay(0.03)


## Zurück zum Gerippe. Ruft ein Auslöser, der neu in die Welt kommt.
func verbergen() -> void:
	if art != Art.UMRISS or not _koerperlich or _zerstoert:
		return
	_koerperlich_setzen(false)
	# Falls das Aufploppen noch läuft: Die Kiste soll nicht in halber
	# Größe wieder auftauchen, wenn sie das nächste Mal erscheint.
	_modell.scale = Vector3.ONE


## Schaltet zwischen „noch nicht da" und „echte Kiste".
##
## Körperlos heißt hier `collision_layer = 0`: Der Spieler prüft Schicht 1,
## und was auf keiner Schicht liegt, ist für ihn Luft. Die Kollisionsform
## bleibt dabei unangetastet – sie abzuschalten hieße, mitten in einer
## laufenden Physikabfrage am Physikserver zu drehen, und genau dorthin
## fällt der Neuaufbau nach einem Tod.
func _koerperlich_setzen(an: bool) -> void:
	_koerperlich = an
	collision_layer = 1 if an else 0
	set_physics_process(an)      # körperlos gibt es nichts zu treffen
	set_process(not an)          # dafür atmet der Umriss
	_modell.visible = an
	if _umriss != null:
		_umriss.visible = not an


## Der Auslöser ist gefallen – alle Umrisse des Levels werden echt.
func _umrisse_ausloesen() -> void:
	for knoten in get_tree().get_nodes_in_group("umrisskisten"):
		var k := knoten as Kiste
		if k != null and is_instance_valid(k) and not k.is_queued_for_deletion():
			k.erscheinen()


## Alle Umrisse des Levels warten wieder.
func _umrisse_verbergen() -> void:
	for knoten in get_tree().get_nodes_in_group("umrisskisten"):
		var k := knoten as Kiste
		if k != null and is_instance_valid(k) and not k.is_queued_for_deletion():
			k.verbergen()


## Sieht nach, ob dieser Umriss überhaupt noch auf etwas wartet.
##
## Nach einem Tod baut `LevelBasis` Kisten und Gegner aus dem Bauplan NEU
## auf – die frische Kiste weiß nichts davon, dass ihr Auslöser längst
## zerschlagen ist. Ein gemerkter Schalter wäre hier die falsche Lösung:
## Der Neuaufbau stellt je nach Stand beim letzten Checkpoint auch den
## Auslöser wieder hin, und dann müsste der Schalter wieder zurück.
##
## Der Auslöser IST der Zustand. Steht er noch irgendwo im Level, wartet
## der Umriss; ist er fort, ist der Umriss körperlich – und zwar still,
## ohne Ploppen, weil er in dieser Welt nie etwas anderes war. Damit
## stimmt beides: Wer nach dem Auslösen stirbt, findet seinen Weg wieder
## vor; wer davor stirbt, muss den Auslöser erneut suchen.
##
## Eine Umrisskiste ohne jeden Auslöser im Level steht deshalb sofort
## körperlich da. Das ist Absicht: Sonst hinge im Level eine Kiste, die
## niemand je erreichen kann, und die hundert Prozent wären unmöglich.
func _umrissstand_pruefen() -> void:
	if art != Art.UMRISS or _koerperlich or _zerstoert:
		return
	if not _ausloeser_steht_noch():
		_koerperlich_setzen(true)


func _ausloeser_steht_noch() -> bool:
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var k := knoten as Kiste
		if k == null or not is_instance_valid(k) or k.is_queued_for_deletion():
			continue
		if k.art == Art.AUSLOESER:
			return true
	return false


## Von außen aufgerufen (z. B. Schockwelle des Bauchplatschers oder eine
## Explosion). `art_treffer` ist eine Angriff-Konstante, 0 = Umgebung.
## Jede Kistenart entscheidet selbst, ob sie darauf reagiert.
func zerbrechen(art_treffer: int = 0) -> void:
	if _zerstoert:
		return
	match art:
		Art.EISEN, Art.SPRUNG:
			return                       # unzerstörbar
		Art.UMRISS:
			# Was nicht da ist, zerbricht auch nicht – weder durch die
			# Schockwelle des Bauchplatschers noch durch die Explosion
			# nebenan. Sonst räumte eine TNT-Kette Kisten fort, die der
			# Spieler nie hätte anfassen können.
			if _koerperlich:
				_zerbrechen_ausfuehren(art_treffer)
		Art.NITRO:
			# Aus der Ferne gezündet: gefahrlos für den Spieler.
			_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
		Art.TNT:
			if art_treffer == 0:
				_explodieren(TNT_RADIUS, Farben.KISTE_TNT, true)   # Kettenreaktion
			elif _countdown < 0.0:
				_zuenden()
		_:
			_zerbrechen_ausfuehren(art_treffer)


# ---------------------------------------------------------------- Federn und Zünden
# Alles hier ist reine Optik: Kollision, Trefferzone und Abprallhöhe
# bleiben, wie sie sind. Bewegt wird nur `_modell`.

## Die Kiste federt unter dem Absprung nach: erst gedrückt, dann elastisch
## zurück. So sieht man, WOHER der Schwung kommt – eine starre Kiste, von
## der die Figur zwanzig Meter hochfliegt, wirkt wie ein Fehler.
func _federn(staerke: float) -> void:
	if _zerstoert:
		return
	if _feder_tween != null and _feder_tween.is_valid():
		_feder_tween.kill()
	_feder_tween = create_tween()
	_feder_tween.tween_method(_stauch_setzen, staerke, 0.0, 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Effekte.ring(self, global_position + Vector3.UP * 0.53,
			Color(1.0, 0.97, 0.88, 0.55), 0.95, 0.22)


func _stauch_setzen(wert: float) -> void:
	_stauch = wert
	_form_anwenden()


func _schwell_setzen(wert: float) -> void:
	_schwell = wert
	_form_anwenden()


## Setzt Größe und Höhe des Modells aus Stauchung, Anschwellen und Wippen.
## Gestaucht wird zum Boden hin, nicht zur Mitte: Die Unterkante bleibt
## stehen, sonst schwebte eine gedrückte Kiste über dem Weg.
func _form_anwenden() -> void:
	if not is_instance_valid(_modell):
		return
	var hoch := (1.0 - _stauch) * _schwell
	var breit := (1.0 + _stauch * 0.5) * _schwell
	_modell.scale = Vector3(breit, hoch, breit)
	_modell.position.y = _grund_y + (hoch - 1.0) * 0.5


## Startet den Countdown der TNT-Kiste.
func _zuenden() -> void:
	_countdown = TNT_ZEIT
	_tnt_zahl = int(TNT_ZEIT)
	_setze_beschriftung(str(_tnt_zahl))
	# Die Zündschnur glimmt. Erst jetzt angelegt, nicht in `_baue_optik()`:
	# Der `Leuchtmarker` kopiert beim Aufbau sonst auch ihr Material.
	var schnur := Transform3D(Basis(Vector3.FORWARD, 0.35), Vector3(0.0, 0.60, 0.0))
	Effekte.dauerfunken(_modell, schnur * Vector3(0.0, 0.19, 0.0))
	_tnt_takt()


## Ein Schlag des Countdowns: Die Kiste schwillt kurz an und glüht auf.
## Die Zahl allein liest man im Lauf nicht; den Takt spürt man.
func _tnt_takt() -> void:
	var t := create_tween()
	t.tween_method(_schwell_setzen, 1.14, 1.0, 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var stoff := _blinkstoff_holen()
	if stoff != null:
		var g := create_tween()
		g.tween_property(stoff, "emission_energy_multiplier", _blink_basis,
				0.35).from(_blink_basis + 3.0)
	# Ein Glutschlag über der Kiste: Die Funken der Zündschnur allein sind
	# aus Spielentfernung kaum zu sehen, der Takt soll es sein.
	Effekte.aufblitzen(self, global_position + Vector3.UP * 0.7, Farben.GLUT, 0.6, 0.1)


## Eigene Kopie des Korpusmaterials zum Aufglühen. Das TNT-Holz aus der
## Bibliothek teilen sich alle TNT-Kisten des Spiels – glühte es selbst,
## glühten sie alle mit. Kopiert wird, was der Korpus gerade trägt (im
## Dunkellevel die leuchtende Kopie), damit nichts verloren geht.
func _blinkstoff_holen() -> StandardMaterial3D:
	if _blinkstoff != null:
		return _blinkstoff
	var korpus := _modell.get_node_or_null("Korpus") as MeshInstance3D
	if korpus == null:
		return null
	var vorlage := korpus.get_surface_override_material(0) as StandardMaterial3D
	if vorlage == null:
		return null
	var m := vorlage.duplicate() as StandardMaterial3D
	if m.emission_enabled:
		_blink_basis = m.emission_energy_multiplier
	else:
		_blink_basis = 0.0
		m.emission_enabled = true
		m.emission = Color(1.0, 0.78, 0.55)
		m.emission_energy_multiplier = 0.0
		# Mit der Maserung als Leuchtbild (multipliziert, nicht addiert)
		# glüht das Holz rot auf, statt eine flache Farbfläche zu werden.
		m.emission_texture = m.albedo_texture
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	korpus.set_surface_override_material(0, m)
	_blinkstoff = m
	return m


# ---------------------------------------------------------------- Intern

## Belohnung ausschütten, Trümmer erzeugen und verschwinden.
func _zerbrechen_ausfuehren(_art_treffer: int) -> void:
	if _zerstoert:
		return
	_zerstoert = true

	# Der Klang trägt die Belohnung mit: Der Dreiklang des Checkpoints und
	# das helle Glöckchen von Leben und Schutz sollen sich hörbar vom
	# gewöhnlichen Holzknacken abheben.
	match art:
		Art.CHECKPOINT:
			Klang.spiele("checkpoint")
		Art.LEBEN, Art.SCHUTZ:
			Klang.spiele("kiste")
			Klang.spiele("frucht", 1.35)
		Art.AUSLOESER:
			# Tiefes Glöckchen unter dem Holzknacken: Es passiert etwas
			# weiter weg, und man soll hinsehen.
			Klang.spiele("kiste")
			Klang.spiele("frucht", 0.7)
		_:
			Klang.spiele("kiste")

	# Die eigenen Stöße VOR allem, was die Kiste auslöst: `Effekte` nimmt
	# je Bild nur acht an (Reihenfolge = Rang, siehe `_truemmer`). Der
	# Auslöser weckt unten alle Umrisse, und die sprühen selbst Funken –
	# zuerst angelegt, hätten sie ihm seinen weiten Ring weggenommen.
	_truemmer()

	match art:
		Art.CHECKPOINT:
			# Zählt nicht im Kistenzähler, setzt dafür den Respawn-Punkt.
			GameState.setze_checkpoint(global_position + Vector3.UP * 0.6)
		Art.LEBEN:
			GameState.kiste_zerbrochen()
			GameState.leben += 1
			GameState.leben_geaendert.emit(GameState.leben)
			GameState.zeige_nachricht("Extraleben!", 1.5)
		Art.SCHUTZ:
			GameState.kiste_zerbrochen()
			GameState.schutz_aufnehmen()
		Art.FRUCHT_MEHRFACH:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, FRUECHTE_MEHRFACH)
		Art.FEDER:
			GameState.kiste_zerbrochen()
			# Noch nicht abgeholte Früchte gibt es beim Zerbrechen dazu.
			if _spruenge_uebrig > 0:
				Frucht.streuen(get_parent(), global_position, _spruenge_uebrig)
		Art.ZEIT:
			# Sie zählt und gibt eine Frucht wie jede Holzkiste – ihr
			# eigentlicher Wert ist die Standzeit der Uhr. Außerhalb des
			# Zeitmodus steht sie gar nicht erst im Level.
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, 1)
			Zeitlauf.einfrieren(float(zeit_wert))
			GameState.zeige_nachricht("+%d s" % zeit_wert, 0.9)
		Art.AUSLOESER:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, 1)
			# VOR dem `queue_free()` weiter unten – danach hinge der Aufruf
			# an einem Knoten, der schon aus dem Baum genommen wird.
			_umrisse_ausloesen()
			GameState.zeige_nachricht("Die Umrisse werden fest!", 1.8)
		_:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, 1)

	queue_free()


## Explosion: zerstört Kisten im Umkreis und ggf. den Spieler.
func _explodieren(wirkradius: float, ton: Color, trifft_spieler: bool) -> void:
	if _zerstoert:
		return
	_zerstoert = true

	var elternteil := get_parent()
	var pos := global_position
	GameState.kiste_zerbrochen()
	Klang.spiele("explosion")
	Explosion.erzeugen(elternteil, pos, wirkradius, ton)
	# Die Bretter der Kiste selbst fliegen mit – eine Explosion, aus der
	# nichts herausfliegt, liest sich als Lichteffekt, nicht als Kiste.
	_bretter_werfen(pos)
	Effekte.erschuettern(self, 0.7, pos)

	var spieler := get_tree().get_first_node_in_group("spieler") as Spieler
	if spieler != null and spieler.global_position.distance_to(pos) < wirkradius * 2.0:
		# Nah dran: ein warmer Schleier über dem Bild. Weiter weg genügt
		# das Wackeln, sonst blitzte jede ferne Kettenreaktion ins Bild.
		Effekte.bildblitz(self, Color(1.0, 0.6, 0.3, 0.3), 0.25)

	# Nachbarkisten mitreißen
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var nachbar := knoten as Kiste
		if nachbar == null or nachbar == self or not is_instance_valid(nachbar):
			continue
		if nachbar.global_position.distance_to(pos) <= wirkradius:
			nachbar.zerbrechen(0)

	if trifft_spieler:
		if spieler != null and spieler.global_position.distance_to(pos) < wirkradius:
			spieler.schaden_nehmen()

	queue_free()


## Das Material, aus dem die Splitter sind: das, was der Korpus gerade
## trägt. Im Dunkellevel ist das die leuchtende Kopie aus `Leuchtmarker`
## (sonst flögen dort schwarze Bretter davon), in Level 25 der
## Nitroanstrich der Treppe. Es wird nur referenziert, nie verändert.
func _bruchstoff() -> Material:
	var korpus := _modell.get_node_or_null("Korpus") as MeshInstance3D
	if korpus != null:
		var stoff := korpus.get_surface_override_material(0)
		if stoff != null:
			return stoff
	if _korpus_material != null:
		return _korpus_material
	return Materialbibliothek.kistenholz(Farben.HOLZ)


## Die Kiste fliegt auseinander: Bretter im Bogen, Staub am Boden, ein
## kurzer Lichtblitz – und je nach Art ein Farbakzent obenauf.
##
## Kein Kamerawackeln: Level 01 hat 43 Kisten, und was bei jeder wackelt,
## wackelt bald bei keiner mehr spürbar. Gewackelt wird nur bei TNT und
## Nitro (oben) und beim Bauchplatscher (Spieler).
##
## Reihenfolge = Rang: `Effekte` nimmt je Bild nur acht neue Stöße an.
## Bricht ein Bauchplatscher mehrere Kisten zugleich, fallen zuerst Staub
## und Blitz der hinteren weg, nicht die Bretter und nicht der Akzent, der
## sagt, WAS da zerbrochen ist.
func _truemmer() -> void:
	var mitte := global_position
	var boden := mitte + Vector3.DOWN * 0.5
	_bretter_werfen(mitte)
	_bruch_akzent(mitte, boden)
	# Halb durchsichtig und kaum aufgehellt: Voll deckend lag der Staub wie
	# helle Wattebäusche auf dem dunklen Weg.
	Effekte.staubwolke(self, boden, 0.6, Color(Farben.HOLZ.lightened(0.2), 0.6))
	Effekte.aufblitzen(self, mitte + Vector3.UP * 0.1, Color(1.0, 0.9, 0.7), 1.4, 0.12)


## Die Bretter der Kiste fliegen davon. Weniger, aber größer als die
## Vorgabe von `Effekte.splitter`: Dort lasen sie sich neben einer
## Meterkiste wie Zweige.
func _bretter_werfen(mitte: Vector3) -> void:
	var bretter := Effekte.splitter(self, mitte, _bruchstoff(), 8)
	if bretter != null:
		bretter.scale_amount_min = 1.1
		bretter.scale_amount_max = 1.6


## Farbakzent je Kistenart – derselbe Ton wie die Kiste, damit man auch
## im Augenwinkel sieht, was man gerade bekommen hat.
func _bruch_akzent(mitte: Vector3, boden: Vector3) -> void:
	var flach := boden + Vector3.UP * 0.06
	match art:
		Art.CHECKPOINT:
			# Der stärkste Moment einer Kiste: Hier geht es nach einem Tod
			# weiter. Eine Lichtsäule sieht man auch vom Rand des Bildes.
			Effekte.lichtsaeule(self, boden, Farben.KISTE_CHECKPOINT)
			Effekte.ring(self, flach, Farben.KISTE_CHECKPOINT.lightened(0.3), 1.5, 0.4)
		Art.LEBEN:
			Effekte.funken(self, mitte, Farben.KISTE_LEBEN.lightened(0.3), 16, 5.5,
					0.22, 50.0)
		Art.SCHUTZ:
			Effekte.funken(self, mitte, Farben.KISTE_SCHUTZ.lightened(0.3), 16, 5.5,
					0.22, 50.0)
		Art.FRUCHT_MEHRFACH:
			Effekte.funken(self, mitte, Farben.KISTE_FRAGE, 12, 4.5)
		Art.ZEIT:
			Effekte.funken(self, mitte, Farben.KISTE_ZEIT.lightened(0.3), 14, 4.5)
			Effekte.ring(self, flach, Farben.KISTE_ZEIT.lightened(0.2), 1.2, 0.35)
		Art.AUSLOESER:
			# Der Ring läuft weit hinaus: Es passiert etwas im ganzen Level.
			Effekte.ring(self, flach, AUSLOESER_ORANGE, 3.0, 0.4)
			Effekte.funken(self, mitte, AUSLOESER_ZEICHEN, 20, 6.0)
		_:
			pass
