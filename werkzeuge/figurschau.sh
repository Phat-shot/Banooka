#!/usr/bin/env bash
# Fotografiert den Beuteldachs in seinen Haltungen und den Schutz in
# seinen Stufen, unter dem Licht von Level 01 (siehe figurschau.gd).
#
#   bash werkzeuge/figurschau.sh <Zielverzeichnis> [posen,gesicht,ruecken,schutz,lauf]
#
# Ohne DISPLAY startet das Skript einen unsichtbaren X-Server (xvfb-run).
# `--fixed-fps 30`: jedes Bild 1/30 s Spielzeit, die Bilder sind
# wiederholbar.

set -uo pipefail
{
PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${1:?Zielverzeichnis angeben}"
FIGURSCHAU_BILD="$(cd "$1" && pwd)"
export FIGURSCHAU_BILD
export FIGURSCHAU_TEILE="${2:-}"
GODOT="${GODOT:-godot}"

STARTER=()
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
	STARTER=(xvfb-run -a -s "-screen 0 1280x720x24")
fi

timeout 300 "$GODOT" --headless --path "$PROJEKT" --import 2>&1 \
	| grep -E -A1 'SCRIPT ERROR|Parse Error' | grep -v '^--$'
${STARTER[@]+"${STARTER[@]}"} timeout "${FIGURSCHAU_ZEITLIMIT:-600}" "$GODOT" \
	--path "$PROJEKT" res://werkzeuge/Figurschau.tscn \
	--display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
	--resolution 1280x720 --position 4000,4000 --fixed-fps 30 2>&1 \
	| grep --line-buffered -vE 'Godot Engine|V-Sync mode|at: set_use_vsync|^\s*$'
exit "${PIPESTATUS[0]}"
}
