extends RefCounted
class_name L01Weltenbaum
## Level 01, Modul „Weltenbaum": der Riese und die Wurzelwendel
## (Plan Abschnitte 5E, 5F, 11).
##
## Rohbau-Stub. Eigentümer ist das Paket „weltenbaum"; der Vertrag steht in
## `level01.gd` unter „Module". Maße in `Level01.WELTENBAUM`.


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(_level: Level01) -> Array:
	return []


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "weltenbaum"
## (Innenflanke, Rindenwulst, Oberwurzel, Wurzelkörper). Wird als Kind des
## Körpers eingehängt, passgenau auf die Kollision; null heißt grauer
## Platzhalter.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	return null
