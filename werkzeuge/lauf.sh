#!/usr/bin/env bash
# Startet eine Szene auf einer Wegwerf-Kopie des Projekts.
#
#   bash werkzeuge/lauf.sh res://werkzeuge/Probe.tscn [weitere Argumente]
#
# Warum die Kopie: Ein `godot --import` im Projektordner selbst schreibt den
# gemeinsamen .godot-Cache um. Laufen mehrere Prüfungen gleichzeitig – oder
# arbeiten parallele Agenten am Projekt –, zerschießen sie sich damit
# gegenseitig. Ohne Import kennt Godot die `class_name`-Klassen nicht und
# meldet "Could not find type X in the current scope".

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
SZENE="${1:?Szene angeben, z. B. res://werkzeuge/Probe.tscn}"
shift

ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_lauf_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

timeout 300 "$GODOT" --headless --path "$ZIEL" --import >/dev/null 2>&1
timeout 300 "$GODOT" --headless --path "$ZIEL" "$SZENE" -- "$@" 2>&1 \
	| grep -vE 'mesh_get_surface_count|Parameter "m" is null|texture_free|Condition "!texture" is true|^$'
