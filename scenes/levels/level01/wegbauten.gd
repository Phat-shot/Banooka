extends RefCounted
class_name L01Wegbauten
## Level 01, Modul „Wegbauten": Setpieces am Weg (Plan Abschnitte 5A–5D).
##
## Rohbau-Stub. Eigentümer ist das Paket „wegbauten"; der Vertrag steht in
## `level01.gd` unter „Module". Orte in `Level01.TORE`,
## `Level01.RAHMENBAUM_STELLEN` und `Level01.BEGEHBARES`.


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(_level: Level01) -> Array:
	return []


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "wegbauten"
## (Startboden, Mooslog, Kanzel, Moosbank, Pforte, Furtsteine, Findlings-
## turm, Wurzelknie …). Wird als Kind des Körpers eingehängt, passgenau auf
## die Kollision; null heißt grauer Platzhalter.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	return null
