extends Node
class_name Leuchtmarker
## Lässt im Dunkellevel das Wichtige von selbst leuchten (Steckbrief 5-3).
##
## Der `Lichtkreis` nimmt dem Level das Licht; damit verschwinden aber
## nicht nur die Wände, sondern auch alles, was der Spieler treffen soll.
## Im Vorbild leuchten Kisten und Edelsteine deshalb aus sich heraus. Das
## ist keine Verzierung, sondern die Bedingung dafür, dass ein
## Dunkellevel überhaupt spielbar ist: Sichtbar bleibt, was man braucht –
## Kisten, Früchte, Wegkanten. Alles andere darf im Schwarz verschwinden.
##
## Nur statische Methoden, es muss also nichts in den Baum gehängt werden:
##     Leuchtmarker.markieren(self, ["kisten", "fruechte"], 1.4)
##     Leuchtmarker.knoten_markieren(kante, 0.8, Farben.KRISTALL_BLAU)
##
## WARUM ÜBERALL DUPLIZIERT WIRD:
## Materialien sind in Godot geteilte Ressourcen, und die
## `Materialbibliothek` reicht bewusst immer dieselbe Instanz heraus –
## alle Holzkisten des ganzen Spiels zeigen auf ein einziges
## `StandardMaterial3D`. Würde hier direkt `emission_enabled` gesetzt,
## glühten die Kisten in Level 01 im hellen Wald mit, und sie täten es
## auch nach dem Verlassen des Dunkellevels weiter, weil die Ressource im
## Cache überlebt. Deshalb bekommt jedes markierte Objekt eine eigene
## Kopie. Die Kopie ist flach (`duplicate()` ohne Argument): Texturen
## bleiben gemeinsam genutzt, kopiert werden nur die Einstellungen. Eine
## tiefe Kopie würde jede Rauschtextur je Kiste neu im Speicher ablegen.

## Merkzeichen am markierten Knoten, damit zweimaliges Markieren (etwa
## nach einem Checkpoint-Neuaufbau) nicht doppelt kopiert.
const MERKMAL := "leuchtmarker"

## Unterhalb dieser Helligkeit taugt die Eigenfarbe nicht als Leuchtfarbe –
## ein schwarz glühendes Objekt bleibt schwarz.
const MINDESTHELLE := 0.18


## Markiert alle Knoten der genannten Gruppen unterhalb von `wurzel`.
##
## `gruppen` sind Gruppennamen aus dem Projekt, üblich sind `"kisten"`
## und `"fruechte"`. `staerke` ist der Leuchtwert (rund 1.0 bis 2.0);
## `farbe` mit Alpha 0 heißt: Jedes Objekt leuchtet in seiner eigenen
## Farbe – eine Frucht orange, eine Checkpointkiste grün. Das ist meist
## richtig, weil die Farbe im Dunkeln die einzige Auskunft darüber ist,
## womit man es zu tun hat.
##
## Gibt die Anzahl der tatsächlich markierten Knoten zurück, damit ein
## Prüfwerkzeug messen kann, ob im Level auch wirklich etwas leuchtet.
static func markieren(wurzel: Node, gruppen: Array[String], staerke: float,
		farbe := Color(0, 0, 0, 0)) -> int:
	if wurzel == null or gruppen.is_empty():
		return 0
	var zahl := 0
	var stapel: Array[Node] = [wurzel]
	while not stapel.is_empty():
		var knoten: Node = stapel.pop_back()
		for kind in knoten.get_children():
			stapel.push_back(kind)
		if _gehoert_zu(knoten, gruppen) and knoten_markieren(knoten, staerke, farbe):
			zahl += 1
	return zahl


## Markiert einen einzelnen Knoten samt allem, was darunter hängt.
##
## Für alles, was in keiner Gruppe steht: Wegkanten, Warnbalken, der
## Rahmen einer Lücke. Gibt zurück, ob etwas zu markieren war.
static func knoten_markieren(knoten: Node, staerke: float,
		farbe := Color(0, 0, 0, 0)) -> bool:
	if knoten == null or knoten.has_meta(MERKMAL):
		return false
	var getroffen := false
	var stapel: Array[Node] = [knoten]
	while not stapel.is_empty():
		var k: Node = stapel.pop_back()
		for kind in k.get_children():
			stapel.push_back(kind)
		if k is GeometryInstance3D:
			getroffen = _flaechen_leuchten(k as GeometryInstance3D, staerke,
					farbe) or getroffen
	if getroffen:
		knoten.set_meta(MERKMAL, true)
	return getroffen


static func _gehoert_zu(knoten: Node, gruppen: Array[String]) -> bool:
	for gruppe in gruppen:
		if knoten.is_in_group(gruppe):
			return true
	return false


## Gibt allen Flächen eines Sichtkörpers ein Eigenleuchten.
##
## Godot kennt drei Stellen, an denen ein Material hängen kann, und sie
## haben eine feste Rangfolge: `material_override` schlägt alles, dann
## das Material der einzelnen Fläche, zuletzt das im Mesh gespeicherte.
## Beide Wege kommen im Projekt vor – Früchte setzen ein
## `material_override`, Kisten setzen Flächenmaterialien.
static func _flaechen_leuchten(koerper: GeometryInstance3D, staerke: float,
		farbe: Color) -> bool:
	if koerper.material_override != null:
		var ersatz := _leuchtende_kopie(koerper.material_override, staerke, farbe)
		if ersatz == null:
			return false
		koerper.material_override = ersatz
		return true

	var netz := koerper as MeshInstance3D
	if netz == null or netz.mesh == null:
		return false
	var getroffen := false
	for i in netz.mesh.get_surface_count():
		var alt: Material = netz.get_surface_override_material(i)
		if alt == null:
			alt = netz.mesh.surface_get_material(i)
		var neu := _leuchtende_kopie(alt, staerke, farbe)
		if neu != null:
			netz.set_surface_override_material(i, neu)
			getroffen = true
	return getroffen


## Kopiert ein Material und schaltet das Leuchten ein.
##
## `null` als Rückgabe heißt „nicht angefasst": Bei einem `ShaderMaterial`
## (Wasser, Portale) wüsste man nicht, welcher Uniform das Leuchten wäre –
## solche Flächen bleiben, wie sie sind.
static func _leuchtende_kopie(alt: Material, staerke: float,
		farbe: Color) -> StandardMaterial3D:
	var vorlage := alt as StandardMaterial3D
	if vorlage == null:
		return null

	var ton := farbe
	if ton.a <= 0.0:
		ton = vorlage.emission if vorlage.emission_enabled else vorlage.albedo_color
	# Eine dunkle Eigenfarbe taugt nicht: Eine braune Holzkiste, die in
	# Braun glüht, bleibt im Schwarz unsichtbar. Dann wird aufgehellt,
	# statt auf eine Einheitsfarbe umzustellen – der Farbton trägt ja die
	# Auskunft, um welche Art Kiste es sich handelt.
	if ton.get_luminance() < MINDESTHELLE:
		ton = ton.lightened(0.55)

	var neu := vorlage.duplicate() as StandardMaterial3D
	neu.emission_enabled = true
	neu.emission = Color(ton.r, ton.g, ton.b)
	# Mit Textur leuchtet die Zeichnung mit: Eine Kiste, die als flacher
	# Farbklecks glüht, verliert im Dunkeln ihre Kanten und damit die
	# Auskunft, wie groß sie ist und wo sie aufhört.
	if vorlage.albedo_texture != null and neu.emission_texture == null:
		neu.emission_texture = vorlage.albedo_texture
	var bisher := vorlage.emission_energy_multiplier if vorlage.emission_enabled else 0.0
	neu.emission_energy_multiplier = maxf(bisher, staerke)
	return neu
