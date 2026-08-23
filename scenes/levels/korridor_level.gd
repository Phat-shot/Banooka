extends LevelBasis
class_name KorridorLevel
## Gemeinsame Grundlage der Korridor-Level (Level 02 aufwärts).
##
## `LevelBasis` kümmert sich um Kamera, Kistenzähler und Portalsignal.
## Diese Schicht darüber bündelt, was jedes Korridorlevel sonst noch
## gleich macht: Objekte relativ zum Verlauf setzen, dabei die Wegbreite
## an der Stelle beachten, Lücken markieren und unter dem Weg eine
## Absturzzone spannen.
##
## Ein abgeleitetes Level liefert dafür drei Angaben:
##   abschnitte()     – Bodenstreifen wie in `LevelWerkzeuge.korridor()`
##   ende()           – Länge der Strecke in Metern
##   absturz_hoehe()  – ab hier abwärts ist der Sturz tödlich
##
## Die Abschnittsliste ist die einzige Quelle für die Wegbreite: `breite_bei()`
## liest sie aus, damit Objekte nie neben dem Weg landen.
##
## Level 01 ist bewusst nicht umgestellt – es läuft und ist geprüft;
## ein Umbau wäre reines Risiko ohne Gewinn.

const KISTE := preload("res://scenes/crates/Kiste.tscn")
const FRUCHT := preload("res://scenes/fruits/Frucht.tscn")
const WASSER := preload("res://scenes/hazards/Wasser.tscn")
const STACHELN := preload("res://scenes/hazards/Stacheln.tscn")
const STARTPORTAL := preload("res://scenes/portals/StartPortal.tscn")
const ZIELPORTAL := preload("res://scenes/portals/ZielPortal.tscn")


# ------------------------------------------------------------- Haken

## Bodenstreifen des Weges: [{"von", "bis", "breite", "breite_ende"}].
func abschnitte() -> Array:
	return []


## Gesamtlänge der Strecke in Metern.
func ende() -> float:
	return 0.0


## Höhe relativ zum Weg, ab der ein Sturz tödlich ist.
func absturz_hoehe() -> float:
	return -6.0


# ------------------------------------------------------------- Wegbreite

## Wegbreite an dieser Stelle, 0 in einer Lücke.
func breite_bei(strecke: float) -> float:
	for a in abschnitte():
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			var t := inverse_lerp(von, bis, strecke)
			return lerpf(a["breite"], a.get("breite_ende", a["breite"]), t)
	return 0.0


## Größter seitlicher Abstand, bei dem ein Objekt noch sicher auf dem Weg steht.
func rand_bei(strecke: float, sicherheit: float = 1.3) -> float:
	return maxf(breite_bei(strecke) * 0.5 - sicherheit, 0.0)


## Schiebt eine Strecke vom Rand eines Abschnitts weg, damit Objekte nicht
## auf der Abbruchkante stehen.
func weg_von_der_kante(strecke: float, abstand: float) -> float:
	for a in abschnitte():
		var von: float = a["von"]
		var bis: float = a["bis"]
		if strecke >= von and strecke <= bis:
			if bis - von <= abstand * 2.0:
				return (von + bis) * 0.5
			return clampf(strecke, von + abstand, bis - abstand)
	return strecke


# ------------------------------------------------------------- Bauteile

## Plattform relativ zum Verlauf, mit dem Weg mitgedreht.
func plattform(strecke: float, seitlich: float, hoehe: float,
		groesse: Vector3, material: Material) -> StaticBody3D:
	var pos := LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	return LevelWerkzeuge.plattform(geometrie, pos, groesse, material,
			LevelWerkzeuge.drehung(verlauf, strecke))


## Start- und Zielportal an den beiden Enden der Strecke.
func portale_setzen(start: float = 1.0, ziel_vor_ende: float = 4.0) -> void:
	var a := STARTPORTAL.instantiate()
	a.position = LevelWerkzeuge.punkt(verlauf, start, 0.0, 0.1)
	a.rotation.y = LevelWerkzeuge.drehung(verlauf, start)
	objekte.add_child(a)

	var s := ende() - ziel_vor_ende
	var z := ZIELPORTAL.instantiate()
	z.position = LevelWerkzeuge.punkt(verlauf, s, 0.0, 0.1)
	z.rotation.y = LevelWerkzeuge.drehung(verlauf, s)
	objekte.add_child(z)


func kiste(art: Kiste.Art, strecke: float, seitlich: float,
		hoehe: float = 0.5) -> Kiste:
	var k := KISTE.instantiate() as Kiste
	k.art = art
	k.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	k.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(k)
	return k


## Setzt einen Gegner so, dass er beim Patrouillieren nicht vom Weg läuft:
## seitlicher Versatz und Weite werden auf die Wegbreite an dieser Stelle
## begrenzt, die Strecke von der Abbruchkante weggeschoben.
func gegner(szene: PackedScene, strecke: float, seitlich: float,
		weite: float, quer: bool) -> Gegner:
	var g := szene.instantiate() as Gegner
	strecke = weg_von_der_kante(strecke, 2.5)
	var rand := rand_bei(strecke)
	if quer:
		seitlich = clampf(seitlich, -rand * 0.5, rand * 0.5)
		weite = minf(weite, maxf(rand - absf(seitlich), 0.5))
	else:
		seitlich = clampf(seitlich, -rand, rand)
		# Entlang des Weges: Weite so kürzen, dass beide Enden auf dem Weg liegen
		var frei := 99.0
		for a in abschnitte():
			if strecke >= a["von"] and strecke <= a["bis"]:
				frei = minf(strecke - a["von"], a["bis"] - strecke) - 1.0
		weite = minf(weite, maxf(frei, 0.5))
	g.patrouille_weite = weite
	var richtung := LevelWerkzeuge.richtung(verlauf, strecke)
	g.patrouille_achse = richtung.cross(Vector3.UP).normalized() if quer else richtung
	# Position VOR add_child setzen: die Gegner merken sich in _ready()
	# ihre Startposition für die Patrouille.
	g.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.05)
	g.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(g)
	return g


func frucht(strecke: float, seitlich: float, hoehe: float = 0.9) -> Node3D:
	var f := FRUCHT.instantiate()
	f.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	objekte.add_child(f)
	return f


func fruechte_reihe(von: float, bis: float, anzahl: int,
		seitlich: float, hoehe: float = 0.9) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		frucht(lerpf(von, bis, t), seitlich, hoehe)


## Bogen aus Früchten über eine Lücke – belohnt den Sprung mit Höhe.
func fruechte_bogen(von: float, bis: float, anzahl: int, seitlich: float,
		scheitel: float = 2.6) -> void:
	for i in anzahl:
		var t := float(i) / maxf(float(anzahl - 1), 1.0)
		frucht(lerpf(von, bis, t), seitlich, 0.9 + sin(t * PI) * scheitel)


func wasser(strecke: float, flaeche: Vector2, hoehe: float,
		seitlich: float = 0.0) -> Wasser:
	var w := WASSER.instantiate() as Wasser
	w.flaeche = flaeche
	w.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, hoehe)
	w.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(w)
	return w


func stacheln(strecke: float, seitlich: float, flaeche: Vector2,
		einfahrbar: bool) -> Stacheln:
	var st := STACHELN.instantiate() as Stacheln
	st.flaeche = flaeche
	st.einfahrbar = einfahrbar
	st.versatz = fmod(strecke, 2.0)
	st.position = LevelWerkzeuge.punkt(verlauf, strecke, seitlich, 0.02)
	st.rotation.y = LevelWerkzeuge.drehung(verlauf, strecke)
	objekte.add_child(st)
	return st


# ------------------------------------------------------------- Absturz

## Spannt unter dem ganzen Weg eine Zone, die den Spieler sterben lässt.
## In Stücken, weil ein einzelner Kasten einem kurvigen Verlauf nicht folgt.
func absturzzonen(schritt: float = 18.0, breite: float = 70.0) -> void:
	var s := 0.0
	while s < ende():
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = 2
		var form := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(breite, 5.0, schritt + 4.0)
		form.shape = box
		zone.add_child(form)
		zone.position = LevelWerkzeuge.punkt(verlauf, s + schritt * 0.5,
				0.0, absturz_hoehe() - 2.5)
		zone.rotation.y = LevelWerkzeuge.drehung(verlauf, s + schritt * 0.5)
		zone.body_entered.connect(_auf_absturz)
		geometrie.add_child(zone)
		s += schritt


func _auf_absturz(koerper: Node3D) -> void:
	if koerper.is_in_group("spieler") and koerper.has_method("sterben"):
		koerper.call("sterben")


# ------------------------------------------------------------- Lücken

## Markiert beide Seiten jeder Lücke, damit Löcher von weitem auffallen.
func luecken_markieren(pfosten_farbe: Color = Farben.HOLZ_DUNKEL) -> void:
	var liste := abschnitte()
	for i in liste.size() - 1:
		var a: Dictionary = liste[i]
		var naechster: Dictionary = liste[i + 1]
		if naechster["von"] - a["bis"] > 0.5:
			warnbalken(a["bis"] - 0.5, a.get("breite_ende", a["breite"]), pfosten_farbe)
			warnbalken(naechster["von"] + 0.5, naechster["breite"], pfosten_farbe)


## Zwei Pfosten mit Warnstreifen links und rechts, knapp vor der Kante.
func warnbalken(strecke: float, breite: float,
		pfosten_farbe: Color = Farben.HOLZ_DUNKEL) -> void:
	var holz := Materialbibliothek.kistenholz(pfosten_farbe)
	var streifen := Materialbibliothek.leuchtend(Color(1.0, 0.85, 0.25), 0.5)
	var halb := breite * 0.5 - 0.55
	var dreh := LevelWerkzeuge.drehung(verlauf, strecke)

	for seite: float in [-1.0, 1.0]:
		var gruppe := Node3D.new()
		gruppe.position = LevelWerkzeuge.punkt(verlauf, strecke, seite * halb, 0.45)
		gruppe.rotation.y = dreh
		deko.add_child(gruppe)

		var zylinder := CylinderMesh.new()
		zylinder.top_radius = 0.09
		zylinder.bottom_radius = 0.11
		zylinder.height = 1.1
		zylinder.radial_segments = 8
		var pfosten := MeshInstance3D.new()
		pfosten.mesh = zylinder
		pfosten.position.y = 0.55
		pfosten.material_override = holz
		gruppe.add_child(pfosten)

		var band := BoxMesh.new()
		band.size = Vector3(0.26, 0.2, 0.26)
		var schild := MeshInstance3D.new()
		schild.mesh = band
		schild.position.y = 1.0
		schild.material_override = streifen
		gruppe.add_child(schild)
