extends RefCounted
class_name L01Gelaende
## Level 01, Modul „Gelände": Tal, Knoll, Wurzelgruben, Randhügel
## (Plan Abschnitt 8.4).
##
## Rohbau-Stub. Eigentümer ist das Paket „gelaende"; der Vertrag steht in
## `level01.gd` unter „Module". Das Gelände trägt keine Kollision: Stürze
## sollen in die Todeszonen fallen.


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(_level: Level01) -> Array:
	return []


## Geländehöhe (Welt-Y) an einer Stelle. Der Stub liefert den Talboden.
static func hoehe(_x: float, _z: float) -> float:
	return 4.0


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "gelaende"
## (Wurzelwiese, Wiesenboden unter G1). Wird als Kind des Körpers
## eingehängt; null heißt grauer Platzhalter. Wer die Fläche im
## Höhenfeld selbst zeichnet, liefert einen leeren Node3D.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	return null
