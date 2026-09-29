extends RefCounted
class_name Bildtakt
## Wo ein Körper in DIESEM Bild gezeichnet wird – für alles, was im
## Bildtakt (`_process`) einem Körper folgt, der sich im Physiktakt bewegt:
## Kameras, Bodenfleck, Schutzmasken, Wegweiser, Lichtkreis, Magnetfrüchte.
##
## Die Regel dahinter steht in ARCHITEKTUR.md unter „Bildtakt und
## Physiktakt": Godot zeichnet Physikkörper zwischen ihren letzten beiden
## Schritten interpoliert. Wer ihnen im Bildtakt folgt, muss diesen
## gezeichneten Ort lesen und nicht `global_position` (den Stand des
## letzten Physikschritts, eine Treppe mit 60 Stufen je Sekunde).
##
## Warum nicht einfach `get_global_transform_interpolated()`: Godot 4.7
## rechnet den interpolierten Ort EINMAL zu Beginn des Bildes aus
## (SceneTreeFTI) und gibt danach diesen Merkwert zurück. Wird der Körper
## im selben Bild noch versetzt – Respawn aus einem Zeitgeber, Bonusraum,
## Portal –, liefert die Abfrage bis zum nächsten Bild den ALTEN Ort, auch
## nach `reset_physics_interpolation()`. Eine Kamera, die in diesem
## Augenblick `sofort_ausrichten()` ruft, sprang an die Absturzstelle und
## flöge von dort eine halbe Sekunde lang zurück. Liegen Merkwert und
## wirklicher Ort weiter auseinander, als sich irgendetwas im Spiel in
## einem Physikschritt bewegt, gilt deshalb der wirkliche Ort.

## Mehr als das legt nichts im Spiel in einem Physikschritt (1/60 s) zurück:
## Slide 13,5 m/s, Bauchplatscher 30 m/s, Karts und Flieger um 20 m/s –
## das sind höchstens 0,5 m. Was weiter auseinanderliegt, ist ein Versetzen.
const VERSETZT := 2.0


## Gezeichnete Lage von `ziel` in diesem Bild.
static func lage(ziel: Node3D) -> Transform3D:
	var jetzt := ziel.global_transform
	# Ohne Interpolation (etwa die Figur im Portalsog, die ein Tween trägt)
	# wird genau `global_transform` gezeichnet. Der Merkwert hinge hier
	# sogar ein Bild zurück: Für Knoten, die im Bildtakt bewegt werden,
	# rechnet Godot ihn erst am Ende des Bildes.
	if not ziel.is_physics_interpolated_and_enabled():
		return jetzt
	var bild := ziel.get_global_transform_interpolated()
	if bild.origin.distance_squared_to(jetzt.origin) > VERSETZT * VERSETZT:
		return jetzt
	return bild


## Gezeichneter Ort von `ziel` in diesem Bild.
static func ort(ziel: Node3D) -> Vector3:
	return lage(ziel).origin
