#!/usr/bin/env bash
# Rendert Bilder eines Levels als PNG.
#
#   bash werkzeuge/foto.sh <Zielverzeichnis> [verfolger|seite] [Strecken]
#
# Beispiele:
#   bash werkzeuge/foto.sh /tmp/bilder
#   bash werkzeuge/foto.sh /tmp/bilder seite 24,59,130
#   FOTO_LEVEL=res://scenes/hub/Hub.tscn bash werkzeuge/foto.sh /tmp/bilder orbit 0,90,180
#
# ACHTUNG: "verfolger" zeigt derzeit unabhängig von der angegebenen Strecke
# die Startstelle – die Spielkamera zieht dem versetzten Spieler nicht nach.
# Für Aufnahmen an bestimmten Stellen "seite" oder "nah" benutzen.
#
# Modi: verfolger (Spielkamera am Korridor), seite (quer darauf),
#       orbit (Kamera umkreist die Szene – für Räume und Menüs).
# Szenen ohne Korridorverlauf wechseln automatisch in den Orbit-Modus.
#
# Godot zeichnet im Headless-Modus nicht (dort gibt es nur den
# Dummy-Renderer). Deshalb läuft das über einen echten Bildschirm; das
# Fenster wird weit außerhalb des sichtbaren Bereichs geöffnet, stört
# also nicht. Gearbeitet wird auf einer Kopie des Projekts, damit
# parallele Läufe sich nicht über den .godot-Cache stören.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FOTO_ZIEL="${1:?Zielverzeichnis angeben}"
export FOTO_MODUS="${2:-verfolger}"
export FOTO_STELLEN="${3:-}"
export FOTO_LEVEL="${FOTO_LEVEL:-res://scenes/levels/Level01.tscn}"

mkdir -p "$FOTO_ZIEL"
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_foto_XXXXXX")"
trap 'rm -rf "$ZIEL"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

timeout 300 godot --headless --path "$ZIEL" --import >/dev/null 2>&1
timeout 300 godot --path "$ZIEL" res://werkzeuge/Foto.tscn \
	--display-driver x11 --rendering-driver opengl3 \
	--resolution 1280x720 --position 4000,4000 2>&1 \
	| grep -vE 'Godot Engine|OpenGL API|^\s*$'
