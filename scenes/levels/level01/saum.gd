extends RefCounted
class_name L01Saum
## Level 01, Modul „Saum": Kanten und Felswände (Plan Abschnitt 8.3).
##
## Rohbau-Stub. Eigentümer ist das Paket „saum"; der Vertrag steht in
## `level01.gd` unter „Module". Die Kanten beschreibt `Level01.RAENDER`,
## einzelne Stellen `Level01.rand_profil()`. Kollision baut der Saum
## keine – die gehört dem Rohbau (Wegdecke, Schultern, Leitlinien).


## Bauschritte, je {"text": String, "tun": Callable}.
static func bauschritte(_level: Level01) -> Array:
	return []
