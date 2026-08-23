extends StaticBody3D
class_name Kiste
## Kiste in neun Ausführungen – ein Skript für alle Arten.
##
## Die Art wird im Inspektor über `art` eingestellt, die Optik baut das
## Skript in `_ready()` prozedural auf (Holzkorpus, Kantenstreben, Symbol).
##
## Treffer werden über die Area3D "Trefferzone" erkannt: Sie fragt jeden
## Physikschritt `spieler.angriffe()` ab (siehe scripts/angriff.gd).
## Zusätzlich ruft die Schockwelle des Bauchplatschers bei allen Kisten
## im Umkreis `zerbrechen(Angriff.SLAM)` auf.

## Die neun Kistenarten.
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

## Angriffsarten, die eine Holzkiste direkt zerbrechen.
const ZERBRECHENDE_ANGRIFFE := Angriff.SPIN | Angriff.SLIDE | Angriff.SLAM

@export var art: Art = Art.NORMAL

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

## Gemeinsame Metallkopien mit gedämpftem Metallanteil (siehe _mattes_metall).
static var _metall_kopien: Dictionary = {}


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


## Baut Korpus, Beschläge und Symbol als ein einziges Mesh auf.
func _baue_optik() -> void:
	_korpus_material = _material_fuer_art()

	var holz := SurfaceTool.new()
	var rahmen := SurfaceTool.new()
	var metall := SurfaceTool.new()
	var akzent := SurfaceTool.new()
	for st: SurfaceTool in [holz, rahmen, metall, akzent]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_baue_kern(rahmen)
	_baue_leisten(rahmen)
	_baue_bretter(holz, rahmen)
	_baue_beschlaege(metall)
	_baue_symbol(rahmen, metall, akzent)

	var gitter := ArrayMesh.new()
	var flaechen: Array = [
		[holz, _korpus_material],
		[rahmen, _rahmen_material()],
		[metall, _metall_material()],
	]
	if art != Art.NORMAL:
		flaechen.append([akzent, _akzent_material()])

	var korpus := MeshInstance3D.new()
	korpus.name = "Korpus"
	var materialien: Array[Material] = []
	for f in flaechen:
		var st: SurfaceTool = f[0]
		st.index()
		var teil := st.commit()
		if teil == null or teil.get_surface_count() == 0:
			continue                      # leere Materialgruppe überspringen
		gitter.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
				teil.surface_get_arrays(0))
		materialien.append(f[1])
	korpus.mesh = gitter
	for i in materialien.size():
		korpus.set_surface_override_material(i, materialien[i])
	_modell.add_child(korpus)

	_baue_beschriftung()


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
func _baue_symbol(rahmen: SurfaceTool, metall: SurfaceTool, akzent: SurfaceTool) -> void:
	match art:
		Art.FRUCHT_MEHRFACH:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_fruechte(akzent, tf))
		Art.LEBEN:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_leben(akzent, tf))
		Art.FEDER:
			_sym_feder(akzent)
		Art.SPRUNG:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_sprung(akzent, tf))
			_sym_sprungteller(metall, akzent)
		Art.TNT:
			_sym_zuendschnur(akzent, rahmen)
		Art.NITRO:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_nitro(akzent, tf))
			_sym_ventil(akzent, metall)
		Art.EISEN:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_eisen(akzent, tf))
		Art.CHECKPOINT:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_checkpoint(akzent, rahmen, tf))
			_sym_fahne(akzent, rahmen)
		Art.SCHUTZ:
			_auf_seiten(func(tf: Transform3D) -> void: _sym_schutz(akzent, tf))
		_:
			pass


## Ruft `bau` mit dem Transform jeder der vier Seitenflächen auf.
## Ursprung liegt auf der Brettfläche, +X rechts, +Y oben, +Z nach außen.
func _auf_seiten(bau: Callable) -> void:
	for seite in SEITEN:
		bau.call(Transform3D(Basis(seite[1], Vector3.UP, seite[0]),
				seite[0] * BRETT_AUSSEN))


## Drei Früchte als Relief im eingelassenen Feld.
func _sym_fruechte(st: SurfaceTool, tf: Transform3D) -> void:
	var stellen: Array = [[-0.150, 0.095, 0.055], [0.0, 0.115, 0.075],
			[0.150, 0.095, 0.055]]
	for s in stellen:
		Kistengeometrie.kuppel(st, Vector3.ZERO, s[1], s[2], 10, 3, UV_METALL,
				tf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
				Vector3(s[0], 0.0, -0.022)))


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


## Zündschnur auf der TNT-Kiste.
func _sym_zuendschnur(akzent: SurfaceTool, rahmen: SurfaceTool) -> void:
	Kistengeometrie.zylinder(rahmen, Vector3(0.0, 0.52, 0.0), 0.10, 0.09, 0.05, 10, UV_METALL)
	var dreh := Transform3D(Basis(Vector3.FORWARD, 0.35), Vector3(0.0, 0.60, 0.0))
	Kistengeometrie.zylinder(akzent, Vector3(0.0, 0.06, 0.0), 0.026, 0.02, 0.16, 8,
			UV_METALL, dreh)
	Kistengeometrie.kuppel(akzent, Vector3(0.0, 0.14, 0.0), 0.05, 0.05, 10, 3, UV_METALL, dreh)


## Warnkreuz im eingelassenen Feld der Nitrokiste.
func _sym_nitro(st: SurfaceTool, tf: Transform3D) -> void:
	for vz: float in [-1.0, 1.0]:
		Kistengeometrie.schraeg_quader(st, Vector3(0.0, 0.0, -0.012),
				Vector3(0.165, 0.034, 0.026), vz * PI * 0.25, 0.01, UV_METALL, tf)


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
		_:
			return Materialbibliothek.kistenholz(Farben.HOLZ)


## Material der Kantenleisten, des Kerns und der eingelassenen Felder.
func _rahmen_material() -> StandardMaterial3D:
	match art:
		Art.EISEN, Art.SPRUNG:
			return _mattes_metall(Farben.KISTE_EISEN.darkened(0.35))
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
			return Materialbibliothek.leuchtend(Farben.FRUCHT, 0.35)
		Art.LEBEN:
			return Materialbibliothek.leuchtend(Color(0.96, 1.0, 0.94), 0.25)
		Art.FEDER, Art.EISEN:
			return _mattes_metall(Farben.FELS_HELL)
		Art.SPRUNG:
			return Materialbibliothek.leuchtend(Color(0.86, 0.95, 1.0), 0.5)
		Art.SCHUTZ:
			return Materialbibliothek.leuchtend(Color(0.82, 0.95, 1.0), 0.6)
		Art.TNT:
			return Materialbibliothek.einfarbig(Color(0.10, 0.08, 0.07), 0.6)
		Art.NITRO:
			return Materialbibliothek.einfarbig(Color(0.05, 0.09, 0.05), 0.5)
		Art.CHECKPOINT:
			return Materialbibliothek.einfarbig(Color(0.96, 0.98, 0.94), 0.7)
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
		schild.position = SEITEN[i][0] * 0.442
		schild.rotation_degrees = Vector3(0.0, SEITEN_DREHUNG[i], 0.0)
		_modell.add_child(schild)
		_beschriftungen.append(schild)


## Kisten mit eingelassener Fläche in der mittleren Brettreihe.
func _hat_feld() -> bool:
	return art == Art.TNT or art == Art.FEDER or art == Art.NITRO \
			or art == Art.FRUCHT_MEHRFACH


## Symbol je Art. Leerer Text = keine Beschriftung.
func _symboltext() -> String:
	match art:
		Art.FEDER:
			return str(_spruenge_uebrig)
		Art.TNT:
			return "TNT"
		_:
			return ""


func _symbolfarbe() -> Color:
	match art:
		Art.TNT:
			return Color(1.0, 0.94, 0.85)
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
				_modell.position = Vector3(
						sin(_zeit * 47.0) * heftig, 0.0, cos(_zeit * 39.0) * heftig)
		Art.FEDER:
			_modell.position.y = sin(_zeit * 3.0) * 0.02


func _physics_process(delta: float) -> void:
	if _zerstoert:
		return
	_abprall_sperre = maxf(_abprall_sperre - delta, 0.0)

	if art == Art.TNT and _countdown >= 0.0:
		_countdown -= delta
		_setze_beschriftung(str(maxi(int(ceil(_countdown)), 0)))
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
		Art.FEDER:
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				_feder_absprung(spieler)
		Art.NITRO:
			# Nur echte Berührung ist tödlich – Drüberspringen bleibt erlaubt.
			if _beruehrt(spieler):
				_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
				spieler.schaden_nehmen()
		Art.TNT:
			if _countdown < 0.0 and ((maske & ZERBRECHENDE_ANGRIFFE) != 0 or von_oben):
				_countdown = TNT_ZEIT
				_setze_beschriftung(str(int(TNT_ZEIT)))
			if von_oben and _abprall_sperre <= 0.0:
				_abprall_sperre = ABPRALL_SPERRE
				spieler.abprallen()
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

## Von außen aufgerufen (z. B. Schockwelle des Bauchplatschers oder eine
## Explosion). `art_treffer` ist eine Angriff-Konstante, 0 = Umgebung.
## Jede Kistenart entscheidet selbst, ob sie darauf reagiert.
## True, wenn diese Kiste im Kistenzähler des Levels mitzählt.
## Checkpoint-, Sprung- und Eisenkisten zählen nicht.
func zaehlt_mit() -> bool:
	return art != Art.CHECKPOINT and art != Art.SPRUNG and art != Art.EISEN


func zerbrechen(art_treffer: int = 0) -> void:
	if _zerstoert:
		return
	match art:
		Art.EISEN, Art.SPRUNG:
			return                       # unzerstörbar
		Art.NITRO:
			# Aus der Ferne gezündet: gefahrlos für den Spieler.
			_explodieren(NITRO_RADIUS, Farben.KISTE_NITRO, false)
		Art.TNT:
			if art_treffer == 0:
				_explodieren(TNT_RADIUS, Farben.KISTE_TNT, true)   # Kettenreaktion
			elif _countdown < 0.0:
				_countdown = TNT_ZEIT
				_setze_beschriftung(str(int(TNT_ZEIT)))
		_:
			_zerbrechen_ausfuehren(art_treffer)


# ---------------------------------------------------------------- Intern

## Belohnung ausschütten, Trümmer erzeugen und verschwinden.
func _zerbrechen_ausfuehren(_art_treffer: int) -> void:
	if _zerstoert:
		return
	_zerstoert = true

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
		_:
			GameState.kiste_zerbrochen()
			Frucht.streuen(get_parent(), global_position, 1)

	_truemmer()
	queue_free()


## Explosion: zerstört Kisten im Umkreis und ggf. den Spieler.
func _explodieren(wirkradius: float, ton: Color, trifft_spieler: bool) -> void:
	if _zerstoert:
		return
	_zerstoert = true

	var elternteil := get_parent()
	var pos := global_position
	GameState.kiste_zerbrochen()
	Explosion.erzeugen(elternteil, pos, wirkradius, ton)

	# Nachbarkisten mitreißen
	for knoten in get_tree().get_nodes_in_group("kisten"):
		var nachbar := knoten as Kiste
		if nachbar == null or nachbar == self or not is_instance_valid(nachbar):
			continue
		if nachbar.global_position.distance_to(pos) <= wirkradius:
			nachbar.zerbrechen(0)

	if trifft_spieler:
		var spieler := get_tree().get_first_node_in_group("spieler") as Spieler
		if spieler != null and spieler.global_position.distance_to(pos) < wirkradius:
			spieler.schaden_nehmen()

	queue_free()


## Ein paar Bruchstücke, die wegfliegen und nach etwa einer Sekunde vergehen.
func _truemmer() -> void:
	var elternteil := get_parent()
	if elternteil == null or not is_instance_valid(elternteil):
		return

	var wurzel := Node3D.new()
	wurzel.name = "Truemmer"
	elternteil.add_child(wurzel)
	wurzel.global_position = global_position

	var mat := _korpus_material if _korpus_material != null \
			else Materialbibliothek.kistenholz(Farben.HOLZ)
	var ziele: Array[Vector3] = []
	for i in 8:
		var stueck := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3.ONE * randf_range(0.18, 0.3)
		stueck.mesh = m
		stueck.material_override = mat
		var richtung := Vector3(randf() * 2.0 - 1.0, randf() * 0.9 + 0.3,
				randf() * 2.0 - 1.0).normalized()
		stueck.position = richtung * 0.25
		wurzel.add_child(stueck)
		ziele.append(richtung * randf_range(1.0, 1.8) + Vector3.DOWN * 0.7)

	var t := wurzel.create_tween()
	t.set_parallel(true)
	var i2 := 0
	for stueck in wurzel.get_children():
		var knoten := stueck as Node3D
		t.tween_property(knoten, "position", ziele[i2], 0.9).set_ease(Tween.EASE_OUT)
		t.tween_property(knoten, "rotation",
				Vector3(randf() * TAU, randf() * TAU, randf() * TAU), 0.9)
		t.tween_property(knoten, "scale", Vector3.ZERO, 0.35).set_delay(0.55)
		i2 += 1
	t.chain().tween_callback(wurzel.queue_free)
