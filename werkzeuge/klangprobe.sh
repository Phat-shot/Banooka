#!/usr/bin/env bash
# Misst alle im Code erzeugten Klänge nach (siehe werkzeuge/klangprobe.gd).
#
# Läuft wie pruefe.sh auf einer Kopie des Projekts, damit sich parallele
# Läufe nicht über den .godot-Cache in die Quere kommen.
#
# Aufruf:  bash werkzeuge/klangprobe.sh
# Rückgabe: 0 = alle Klänge in Ordnung, 1 = mindestens einer auffällig

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	exit 2
fi

ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_klang_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

timeout 300 "$GODOT" --headless --path "$ZIEL" --import >/dev/null 2>&1

AUSGABE="$(timeout 120 "$GODOT" --headless --path "$ZIEL" res://werkzeuge/Klangprobe.tscn 2>&1)"
ERGEBNIS=$?
echo "$AUSGABE" | grep -E "Klangprobe|Name +Dauer|FEHLER|geprüft|^[a-z]+ +[0-9]"

if [ "$ERGEBNIS" -ne 0 ]; then
	echo "ERGEBNIS: AUFFÄLLIGE KLÄNGE"
	exit 1
fi
echo "ERGEBNIS: ALLE KLÄNGE IN ORDNUNG"
exit 0
