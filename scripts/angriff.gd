extends RefCounted
class_name Angriff
## Angriffsarten des Spielers als Bitmaske.
##
## Gegner und Kisten fragen `spieler.angriffe()` ab und prüfen mit `&`,
## ob die für sie passende Angriffsart aktiv ist. Zusätzliche Bedingungen
## (z. B. "von oben") prüft das Ziel selbst anhand der Position.

const KEINER := 0
const SPIN := 1       ## Spin-Attacke läuft
const SLIDE := 2      ## Slide läuft
const SLAM := 4       ## Bauchplatscher läuft (in der Luft, nach unten)
const FALLEN := 8     ## Spieler fällt schnell genug zum Draufspringen

## Fallgeschwindigkeit, ab der FALLEN gesetzt wird.
## Bewusst großzügiger als die -4.0 der Demo: mit -4.0 zählte ein Treffer
## erst bei ordentlichem Fall, und weil move_and_slide beim Aufsetzen
## vel.y sofort auf 0 zieht, kam das Bit oft gar nicht an.
const FALL_SCHWELLE := -2.0

## Lesbare Namen für Debug-Ausgaben.
static func als_text(maske: int) -> String:
	var teile: Array[String] = []
	if maske & SPIN:
		teile.append("Spin")
	if maske & SLIDE:
		teile.append("Slide")
	if maske & SLAM:
		teile.append("Bauchplatscher")
	if maske & FALLEN:
		teile.append("Fallen")
	return "+".join(teile) if not teile.is_empty() else "keiner"
