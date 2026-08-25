#!/usr/bin/env bash
# Fotografiert jede Pose einer Figur.
#
#   bash werkzeuge/figur.sh <Zielverzeichnis> [Datei] [schraeg|vorne|seite|fuesse] [Clip]
#
# Beispiele:
#   bash werkzeuge/figur.sh /tmp/posen
#   bash werkzeuge/figur.sh /tmp/schuhe cash_banooka_rc.glb fuesse Walk
#
# Godot zeichnet im Headless-Modus nicht. Deshalb wird wie bei foto.sh ein
# echtes Fenster weit außerhalb des sichtbaren Bereichs geöffnet.

set -uo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FIGUR_BILD="${1:?Zielverzeichnis angeben}"
export MODELLTEST_DATEI="${2:-cash_banooka_rc.glb}"
export FIGUR_KAMERA="${3:-schraeg}"
export FIGUR_CLIP="${4:-}"

mkdir -p "$FIGUR_BILD"
timeout 300 godot --headless --path "$PROJEKT" --import >/dev/null 2>&1
timeout 300 godot --path "$PROJEKT" res://werkzeuge/Figurpruefung.tscn \
	--display-driver x11 --rendering-driver opengl3 \
	--resolution 900x900 --position 4000,4000 2>&1 \
	| grep -vE 'Godot Engine|OpenGL API|^\s*$'
