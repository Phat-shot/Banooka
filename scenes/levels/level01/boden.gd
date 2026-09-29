extends RefCounted
class_name L01Boden
## Level 01, Modul „Boden": Wegdecke und Lückenlippen (Plan Abschnitt 8.1).
##
## Rohbau-Stub. Eigentümer ist das Paket „wegboden"; der Vertrag steht in
## `level01.gd` unter „Module".
##
## `stoff()` liefert den Stoff der Wegdecke je Eintrag in
## `Level01.ABSCHNITTE`. Einträge mit demselben Stoff-Objekt teilen sich ein
## Netz – wer je Abschnitt eigene Uniforms (Kronenlicht) braucht, liefert
## eigene Stoffe und bezahlt dafür je einen Zeichenaufruf. Die Decke trägt
## UV2 = (quer / halbe Breite, Strecke), siehe `LevelWerkzeuge.korridor`
## mit "uv_quer".


## Stoff der Wegdecke für einen Eintrag aus `Level01.ABSCHNITTE`.
## null heißt: Der Rohbau nimmt `Materialbibliothek.waldweg()`.
static func stoff(_level: Level01, _abschnitt: Dictionary) -> Material:
	return Materialbibliothek.waldweg()


## Bauschritte (Lückenlippen), je {"text": String, "tun": Callable}.
static func bauschritte(_level: Level01) -> Array:
	return []
