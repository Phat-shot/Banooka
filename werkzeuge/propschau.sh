#!/usr/bin/env bash
# Fotografiert die Bewegungs-Props einzeln – mehrere Aufnahmen je Prop,
# damit sich die Bewegung zwischen den Bildern ablesen lässt.
#
#   bash werkzeuge/propschau.sh <Zielverzeichnis> [staub|laub|voegel|alle]
#
# Wie foto.sh: Godot zeichnet headless nicht, deshalb läuft das über ein
# echtes X11-Fenster weit außerhalb des sichtbaren Bereichs. Gearbeitet wird
# auf einer Kopie des Projekts, damit parallele Läufe sich nicht über den
# .godot-Cache stören.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROPSCHAU_ZIEL="${1:?Zielverzeichnis angeben}"
WAS="${2:-alle}"
export PROPSCHAU_BILDER="${PROPSCHAU_BILDER:-3}"
export PROPSCHAU_PAUSE="${PROPSCHAU_PAUSE:-1.2}"

mkdir -p "$PROPSCHAU_ZIEL"
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_propschau_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

timeout 300 godot --headless --path "$ZIEL" --import >/dev/null 2>&1

ARTEN="$WAS"
if [ "$WAS" = "alle" ]; then
	ARTEN="staub laub voegel"
fi

for ART in $ARTEN; do
	PROPSCHAU="$ART" timeout 300 godot --path "$ZIEL" res://werkzeuge/Propschau.tscn \
		--display-driver x11 --rendering-driver opengl3 \
		--resolution 1280x720 --position 4000,4000 2>&1 \
		| grep -vE 'Godot Engine|OpenGL API|^\s*$'
done
