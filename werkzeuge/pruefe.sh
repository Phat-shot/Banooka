#!/usr/bin/env bash
# Prüft das Godot-Projekt auf Parse- und Laufzeitfehler.
#
# Die Prüfung läuft auf einer Kopie des Projekts, damit sich mehrere
# gleichzeitige Prüfläufe nicht über den .godot-Cache in die Quere kommen.
#
# Aufruf:  bash werkzeuge/pruefe.sh
# Rückgabe: 0 = sauber, 1 = Fehler gefunden

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ohne Godot prüft dieses Skript gar nichts – und meldete früher trotzdem
# "SAUBER", weil jeder Aufruf still fehlschlug und die Ausgabe leer blieb.
# Eine leere Ausgabe ist hier aber kein Beweis, sondern nur Schweigen.
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	echo "Godot in den PATH legen oder GODOT=/pfad/zu/godot setzen."
	exit 2
fi
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_check_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT

cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

# Meldungen des Dummy-Renderers im Headless-Modus sind keine Projektfehler
RAUSCHEN='mesh_get_surface_count|Parameter "m" is null|texture_free|Condition "!texture" is true'

echo "--- 1/4 Import und Parse-Prüfung ---"
IMPORT="$(timeout 300 "$GODOT" --headless --path "$ZIEL" --import 2>&1 \
	| grep -E "SCRIPT ERROR|Parse Error|ERROR:|Cannot|Invalid" \
	| grep -Ev "$RAUSCHEN")"
if [ -n "$IMPORT" ]; then
	echo "$IMPORT"
else
	echo "keine Parse-Fehler"
fi

echo "--- 2/4 Szenen laden und instanziieren ---"
SZENEN="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/SzenenCheck.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$SZENEN" | grep -E "ok:|FEHLER|SCRIPT ERROR|ERROR:|Szenen geprüft|Szenen-Check"

# Jedes gebaute Level, nicht nur das erste. Mit sieben Leveln ist eine
# Prüfung, die nur Level 01 ansieht, kaum noch eine Prüfung.
# PRUEF_LEVEL=01,03 grenzt bei Bedarf ein.
echo "--- 3/4 Level geometrisch prüfen ---"
LEVEL=""
NUMMERN="${PRUEF_LEVEL:-}"
if [ -z "$NUMMERN" ]; then
	NUMMERN="$(ls "$ZIEL"/scenes/levels/Level*.tscn 2>/dev/null \
		| sed -E 's#.*/Level([0-9]+)\.tscn#\1#' | sort | tr '\n' ',')"
fi
for NR in ${NUMMERN//,/ }; do
	SZENE="res://scenes/levels/Level${NR}.tscn"
	[ -f "$ZIEL/scenes/levels/Level${NR}.tscn" ] || continue
	TEIL="$(timeout 300 "$GODOT" --headless --path "$ZIEL" \
		res://werkzeuge/LevelCheck.tscn -- "$SZENE" 2>&1 | grep -Ev "$RAUSCHEN")"
	LEVEL="$LEVEL
$TEIL"
	echo "$TEIL" | grep -E "FEHLER|geprüft|Problem|Absturzzone|schwebt|steckt|==="
done

# Was nur in Bewegung zu prüfen ist: das Krabbeln (Halten statt Umschalten,
# Zwang unter tiefen Decken, kein Knochen unter dem Boden), die
# Wasserplattformen (tragen sie den Spieler wirklich mit?), das Hangeln und
# die Deckungsflecken (hält der Schwarm wirklich ab, oder leuchtet der
# Fleck nur?). Eine Regel, die keine Prüfung hat, ist eine Behauptung.
echo "--- 4/4 Krabbeln, Böden, Hangeln, Deckung, Dunkelheit, Zeitmodus ---"
KRIECH="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Kriechtest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$KRIECH" | grep -E "krabbelt|Abweichungen"
FLOSS="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Flosstest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$FLOSS" | grep -E "abgesetzt|Fahrt:|Sinken:|Abweichungen"
HANGELN="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Hangeltest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$HANGELN" | grep -E "springt|haengt|hangelt|laesst|faellt|laeuft darunter|Fall-Ged|Abweichungen"
DECKUNG="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Deckungstest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$DECKUNG" | grep -E "Fleck|drueber|Abweichungen"
DUNKEL="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Dunkeltest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$DUNKEL" | grep -E "markiert|zerschlagen|Abweichungen"

UMRISS="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Umrisstest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$UMRISS" | grep -E "Umrisskisten|koerperlich|Ausloeser|zaehlt|Abweichungen"

# Der Zeitmodus baut das Level um (Zeitkisten an Stelle von Holzkisten) und
# hängt an Uhr, Tod und Spielstand. Nichts davon ist im Bild zu sehen, also
# muss es gemessen werden.
ZEIT="$(timeout 300 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Zeitprobe.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$ZEIT" | grep -E "Zeitkisten|Uhr|Standzeit|Bestzeit|Lauf|Stufe|Abweichungen"

if [ -n "$IMPORT" ] || echo "$SZENEN" | grep -qE "FEHLER|SCRIPT ERROR" \
		|| echo "$LEVEL" | grep -qE "FEHLER" \
		|| echo "$KRIECH" | grep -qE "FALSCH|IM BODEN" \
		|| echo "$FLOSS" | grep -qE "steht nicht|blieb zurueck|haengt in der Luft" \
		|| echo "$HANGELN" | grep -qE "NEIN" \
		|| echo "$DECKUNG" | grep -qE "FALSCH" \
		|| echo "$DUNKEL" | grep -qE "FALSCH" \
		|| echo "$UMRISS" | grep -qE "NEIN" \
		|| echo "$ZEIT" | grep -qE "NEIN"; then
	echo "ERGEBNIS: FEHLER GEFUNDEN"
	exit 1
fi
echo "ERGEBNIS: SAUBER"
exit 0
