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


## Optik für Einträge aus `Level01.BEGEHBARES` mit "optik": "saum" – die
## Böden der Vorsprünge im Hangweg (`Level01.VORSPRUNG_62` …): Oberseite
## auf Deckenhöhe bis zur Lippe, die Felsstirn darunter gehört zum
## FELS_AB-Profil (`rand_profil` meldet dort "vorsprung"). Wird als Kind
## des Körpers eingehängt; null heißt grauer Platzhalter.
static func optik(_level: Level01, _eintrag: Dictionary) -> Node3D:
	return null
