#!/usr/bin/env bash
# Fotografiert eine Floßfahrt von der Seite.
#
#   bash werkzeuge/fahrtschau.sh <Zielverzeichnis> [Levelszene] [Flossnummer]
#
# Godot zeichnet im Headless-Modus nicht; deshalb läuft das wie foto.sh
# über ein Fenster weit außerhalb des sichtbaren Bereichs.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FAHRT_ZIEL="${1:?Zielverzeichnis angeben}"
SZENE="${2:-res://scenes/levels/Level03.tscn}"
export FAHRT_FLOSS="${3:-0}"

mkdir -p "$FAHRT_ZIEL"
timeout 300 godot --headless --path "$PROJEKT" --import >/dev/null 2>&1
timeout 300 godot --path "$PROJEKT" res://werkzeuge/Fahrtschau.tscn \
	--display-driver x11 --rendering-driver opengl3 \
	--resolution 1280x720 --position 4000,4000 -- "$SZENE" 2>&1 \
	| grep -vE 'Godot Engine|OpenGL API|^\s*$'
