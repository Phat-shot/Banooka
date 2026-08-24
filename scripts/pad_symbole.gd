extends RefCounted
class_name PadSymbole
## Die vier Symboltasten eines PlayStation-Controllers, gezeichnet statt
## geladen – das Projekt kommt ohne fremde Assets aus.
##
## Eine Stelle für Farbe, Zeichen und Klartext, damit die virtuelle
## Touch-Steuerung und die Statustafel dasselbe zeigen. Geführt wird alles
## unter dem Namen der Spielaktion, nicht unter dem Tastennamen:
##
##   jump   ✕ Kreuz      slide  ○ Kreis
##   spin   □ Viereck    status △ Dreieck

const FARBEN := {
	"jump": Color(0.42, 0.60, 0.98),
	"slide": Color(0.94, 0.38, 0.40),
	"spin": Color(0.96, 0.51, 0.78),
	"status": Color(0.36, 0.86, 0.62),
}

## Klartextname der Taste, für Legenden.
const TASTEN := {
	"jump": "Kreuz",
	"slide": "Kreis",
	"spin": "Viereck",
	"status": "Dreieck",
}


## Zeichnet das Symbol mittig um `mitte`, eingepasst in den Radius `r`.
static func zeichne(auf: CanvasItem, aktion: String, mitte: Vector2, r: float,
		farbe: Color, strich: float) -> void:
	match aktion:
		"jump":   # Kreuz
			var d := r * 0.78
			auf.draw_line(mitte + Vector2(-d, -d), mitte + Vector2(d, d), farbe, strich, true)
			auf.draw_line(mitte + Vector2(d, -d), mitte + Vector2(-d, d), farbe, strich, true)
		"slide":  # Kreis
			auf.draw_arc(mitte, r * 0.85, 0.0, TAU, 40, farbe, strich, true)
		"spin":   # Viereck
			var s := r * 0.72
			auf.draw_rect(Rect2(mitte - Vector2(s, s), Vector2(s * 2.0, s * 2.0)),
					farbe, false, strich)
		"status":  # Dreieck
			var h := r * 0.95
			auf.draw_polyline(PackedVector2Array([
				mitte + Vector2(0.0, -h),
				mitte + Vector2(h * 0.92, h * 0.72),
				mitte + Vector2(-h * 0.92, h * 0.72),
				mitte + Vector2(0.0, -h),
			]), farbe, strich, true)


## Farbe einer Aktion, mit Rückfall auf Weiß.
static func farbe(aktion: String) -> Color:
	return FARBEN.get(aktion, Color.WHITE)
