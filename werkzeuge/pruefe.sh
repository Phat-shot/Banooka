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
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_check_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT

cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

# Meldungen des Dummy-Renderers im Headless-Modus sind keine Projektfehler
RAUSCHEN='mesh_get_surface_count|Parameter "m" is null|texture_free|Condition "!texture" is true'

echo "--- 1/2 Import und Parse-Prüfung ---"
IMPORT="$(timeout 300 godot --headless --path "$ZIEL" --import 2>&1 \
	| grep -E "SCRIPT ERROR|Parse Error|ERROR:|Cannot|Invalid" \
	| grep -Ev "$RAUSCHEN")"
if [ -n "$IMPORT" ]; then
	echo "$IMPORT"
else
	echo "keine Parse-Fehler"
fi

echo "--- 2/2 Szenen laden und instanziieren ---"
SZENEN="$(timeout 300 godot --headless --path "$ZIEL" res://werkzeuge/SzenenCheck.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN")"
echo "$SZENEN" | grep -E "ok:|FEHLER|SCRIPT ERROR|ERROR:|Szenen geprüft|Szenen-Check"

if [ -n "$IMPORT" ] || echo "$SZENEN" | grep -qE "FEHLER|SCRIPT ERROR"; then
	echo "ERGEBNIS: FEHLER GEFUNDEN"
	exit 1
fi
echo "ERGEBNIS: SAUBER"
exit 0
