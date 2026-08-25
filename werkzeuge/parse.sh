#!/usr/bin/env bash
# Schnelle Parse-Prüfung des Projekts – ohne den gemeinsamen .godot-Cache
# anzufassen.
#
#   bash werkzeuge/parse.sh
#
# Gedacht für parallele Arbeit: Mehrere Läufe gleichzeitig stören einander
# nicht, weil jeder auf einer eigenen Kopie arbeitet. `godot --import` im
# Projektordner selbst würde den Cache der anderen zerschießen.
#
# Zwei Stufen, weil eine nicht reicht: `--import` übersetzt NICHT jedes
# Skript. Ein "Inference on Variant" – in Godot 4.7 eine Meldung auf
# Fehlerstufe – rutschte dabei durch und fiel erst beim Laden der Szene auf.
# Deshalb lädt Stufe 2 jede .gd-Datei wirklich.
#
# Rückgabe: 0 = sauber, 1 = Fehler gefunden.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	exit 2
fi

ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_parse_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

RAUSCHEN='mesh_get_surface_count|Parameter "m" is null|texture_free|Condition "!texture" is true'
AUSGABE="$(timeout 300 "$GODOT" --headless --path "$ZIEL" --import 2>&1 \
	| grep -E "SCRIPT ERROR|Parse Error|ERROR:|Cannot|Invalid" \
	| grep -Ev "$RAUSCHEN")"

if [ -n "$AUSGABE" ]; then
	echo "$AUSGABE"
	echo "ERGEBNIS: PARSE-FEHLER"
	exit 1
fi

LADEN="$(timeout 300 "$GODOT" --headless --path "$ZIEL" \
	res://werkzeuge/Ladeprobe.tscn 2>&1 | grep -Ev "$RAUSCHEN")"
echo "$LADEN" | grep -E "FEHLER|Ladeprobe:"
if echo "$LADEN" | grep -qE "FEHLER|SCRIPT ERROR|Parse Error"; then
	echo "$LADEN" | grep -E "SCRIPT ERROR|Parse Error" | head -20
	echo "ERGEBNIS: LADEFEHLER"
	exit 1
fi
echo "ERGEBNIS: SAUBER (Parse und Laden)"
exit 0
