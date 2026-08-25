#!/usr/bin/env bash
# Fotografiert die hängende Figur am Hangelgitter.
#
#   bash werkzeuge/hangelbild.sh /tmp/hangeln.png
#
# Godot zeichnet im Headless-Modus nicht; deshalb wie bei foto.sh ein
# Fenster weit außerhalb des sichtbaren Bereichs, und wie bei parse.sh auf
# einer Kopie, damit der gemeinsame .godot-Cache unangetastet bleibt.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export HANGEL_BILD="${1:?Zieldatei angeben}"
mkdir -p "$(dirname "$HANGEL_BILD")"

ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_hangeln_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

timeout 300 godot --headless --path "$ZIEL" --import >/dev/null 2>&1
timeout 300 godot --path "$ZIEL" res://werkzeuge/Hangeltest.tscn \
	--display-driver x11 --rendering-driver opengl3 \
	--resolution 1100x700 --position 4000,4000 2>&1 \
	| grep -vE 'Godot Engine|OpenGL API|^\s*$'
