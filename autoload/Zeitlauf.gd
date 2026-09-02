extends Node
## Zeitmodus: Uhr, Zeitkisten und Zeitrelikte.
## Als Autoload unter dem Namen "Zeitlauf" registriert.
##
## Der Zeitmodus ist eine zweite Art, dasselbe Level zu spielen: Statt
## alles einzusammeln zählt nur, wie schnell man durchkommt. Er wird in
## den Einstellungen ein- und ausgeschaltet (`aktiv`) und gilt dann für
## jedes betretene Level.
##
## DIE ZEITKISTEN. Im Zeitmodus stehen im Level Kisten mit einer Uhr und
## einer Zahl darauf (`Kiste.Art.ZEIT`). Wer sie zerschlägt, hält die Uhr
## für so viele Sekunden an – sie zählt nicht rückwärts, sie steht still.
## Das ist der Unterschied, auf den es ankommt: Eine Kiste, die Zeit
## abzieht, belohnt Umwege; eine Kiste, die die Uhr anhält, belohnt den
## Weg, der ohnehin der schnellste ist. Deshalb ersetzen die Zeitkisten
## gewöhnliche Kisten AUF dem Weg (siehe `LevelBasis._zeitkisten_setzen()`)
## und stehen nie abseits davon.
##
## DER TOD BEENDET DEN LAUF. Er setzt ihn nicht zurück, denn ein Tod
## kurz vor dem Ziel wäre sonst die schnellste Abkürzung; und er lässt
## ihn auch nicht weiterlaufen, denn das Level baut sich beim Respawn bis
## zum Checkpoint wieder auf und man liefe dieselbe Strecke ein zweites
## Mal. Wer stirbt, spielt das Level normal zu Ende und beginnt den
## Zeitlauf beim nächsten Betreten neu.
##
## DIE RICHTZEIT kommt vom Level (`LevelBasis.zielzeit()`), das sie in
## der Regel aus seiner Streckenlänge ableitet. Drei Stufen hängen daran:
## Saphir für die Richtzeit, Gold für 85 %, Platin für 72 % davon.

## Die Uhr hat sich geändert (auch beim Einfrieren).
signal zeit_geaendert(sekunden: float, frost: float)
## Ein Lauf hat begonnen oder geendet – die Anzeige blendet sich ein.
signal lauf_geaendert(laeuft: bool)
## Der Zeitmodus wurde ein- oder ausgeschaltet.
signal modus_geaendert(an: bool)

enum Stufe { KEINE, SAPHIR, GOLD, PLATIN }

## Tempo, mit dem die Richtzeit aus der Streckenlänge gerechnet wird.
## `RUN_SPEED` aus dem Physikvertrag – die reine Laufzeit.
const LAUFTEMPO := 8.5
## Aufschlag auf die reine Laufzeit: Springen, Warten auf einen Takt,
## Gegner, Umwege zu Kisten.
##
## 2,8 heißt: Ein Level, das man in einem Zug durchlaufen könnte, gibt fast
## die dreifache Laufzeit. Das ist bewusst großzügig – die erste Stufe soll
## beim zweiten, dritten Anlauf fallen, nicht erst nach dem zwanzigsten.
## Die Zahl ist geschätzt und nicht erspielt; wer ein Level durchmisst und
## es besser weiß, überschreibt sie dort mit `LevelBasis.zielzeit()`.
const ZEITFAKTOR := 2.8
## Für Level ohne Verlauf (Flugniveau) bleibt nur eine feste Richtzeit.
const RICHTZEIT_ERSATZ := 150.0

## Ritt- und Rennlevel kleben auf der Levelkurve und laufen von selbst –
## mit 11 bis 21 m/s, nicht mit 8,5. Und sie haben keine Umwege: Wer auf
## einer Schiene sitzt, kann nicht stehen bleiben, um eine Kiste
## mitzunehmen. Beides zusammen macht die Laufformel dort unbrauchbar –
## Level 04 bekäme nach ihr 129 Sekunden für einen Ritt, der 26 dauert,
## und das Relikt wäre geschenkt.
const RITTTEMPO := 15.0
const RITT_FAKTOR := 1.5

const GOLD_ANTEIL := 0.85
const PLATIN_ANTEIL := 0.72

## Farben der drei Stufen – auch das Portal im Portalraum nutzt sie.
const STUFEN_FARBEN := {
	Stufe.SAPHIR: Color(0.35, 0.62, 0.98),
	Stufe.GOLD: Color(1.0, 0.78, 0.26),
	Stufe.PLATIN: Color(0.86, 0.94, 1.0),
}

const STUFEN_NAMEN := {
	Stufe.KEINE: "",
	Stufe.SAPHIR: "Saphir",
	Stufe.GOLD: "Gold",
	Stufe.PLATIN: "Platin",
}

## Ist der Zeitmodus gewählt? Wird von `Einstellungen` gesetzt und dort
## auch gespeichert.
var aktiv := false:
	set(an):
		if aktiv == an:
			return
		aktiv = an
		if not an:
			abbrechen()
		modus_geaendert.emit(an)

## Läuft gerade ein Lauf?
var laeuft := false
## Verstrichene Zeit des laufenden Versuchs in Sekunden.
var zeit := 0.0
## Restliche Standzeit der Uhr in Sekunden (aus Zeitkisten).
var frost := 0.0
## Richtzeit des laufenden Levels (Saphirgrenze) in Sekunden.
var richtzeit := 0.0
## Nummer des Levels, für das der Lauf zählt.
var level := 0


func _ready() -> void:
	set_process(false)
	GameState.level_zuruecksetzen.connect(_auf_tod)


func _process(delta: float) -> void:
	if not laeuft:
		return
	# Die eingefrorene Zeit wird nicht "nachgeholt": Was die Kiste
	# geschenkt hat, bleibt geschenkt, auch wenn der Rest des Bildes
	# schon zur nächsten Sekunde gehört.
	if frost > 0.0:
		frost = maxf(frost - delta, 0.0)
		zeit_geaendert.emit(zeit, frost)
		return
	zeit += delta
	zeit_geaendert.emit(zeit, 0.0)


# ------------------------------------------------------------- Ablauf

## Beginnt einen Lauf. `richt` ist die Saphirgrenze in Sekunden.
func beginnen(level_nummer: int, richt: float) -> void:
	if not aktiv:
		return
	level = level_nummer
	richtzeit = maxf(richt, 1.0)
	zeit = 0.0
	frost = 0.0
	laeuft = true
	set_process(true)
	lauf_geaendert.emit(true)
	zeit_geaendert.emit(0.0, 0.0)
	GameState.zeige_nachricht("Zeitlauf!", 1.6)


## Beendet den Lauf am Ziel und gibt die gelaufene Zeit zurück.
## Ohne laufenden Lauf ist die Rückgabe negativ.
func beenden() -> float:
	if not laeuft:
		return -1.0
	laeuft = false
	set_process(false)
	lauf_geaendert.emit(false)
	return zeit


## Bricht den Lauf ab, ohne ihn zu werten.
func abbrechen() -> void:
	if not laeuft:
		return
	laeuft = false
	set_process(false)
	lauf_geaendert.emit(false)


## Eine Zeitkiste ist zerbrochen: Die Uhr steht `sekunden` lang still.
## Mehrere Kisten kurz hintereinander addieren ihre Standzeit.
func einfrieren(sekunden: float) -> void:
	if not laeuft:
		return
	frost += maxf(sekunden, 0.0)
	Klang.spiele("frucht", 1.55)
	zeit_geaendert.emit(zeit, frost)


## Der Spieler ist gestorben – der Lauf ist hin.
func _auf_tod(_von_vorn: bool) -> void:
	if not laeuft:
		return
	abbrechen()
	GameState.zeige_nachricht("Zeitlauf beendet", 1.8)


# ------------------------------------------------------------- Wertung

## Welche Stufe ergibt diese Zeit bei dieser Richtzeit?
func stufe_fuer(gelaufen: float, richt: float) -> Stufe:
	if gelaufen <= 0.0 or richt <= 0.0:
		return Stufe.KEINE
	if gelaufen <= richt * PLATIN_ANTEIL:
		return Stufe.PLATIN
	if gelaufen <= richt * GOLD_ANTEIL:
		return Stufe.GOLD
	if gelaufen <= richt:
		return Stufe.SAPHIR
	return Stufe.KEINE


## Zeit als "1:23,45" – Minuten nur, wenn es welche gibt.
static func als_text(sekunden: float) -> String:
	if sekunden < 0.0:
		return "–"
	var minuten := int(sekunden) / 60
	var rest := sekunden - float(minuten * 60)
	if minuten <= 0:
		return ("%.2f" % rest).replace(".", ",")
	return ("%d:%05.2f" % [minuten, rest]).replace(".", ",")


static func stufen_name(stufe: int) -> String:
	return String(STUFEN_NAMEN.get(stufe, ""))


static func stufen_farbe(stufe: int) -> Color:
	return STUFEN_FARBEN.get(stufe, Color(0.7, 0.7, 0.7)) as Color
