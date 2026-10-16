#!/usr/bin/env bash
# Wegmaske: CPU (scripts/wegmaske.gd) gegen GPU (wald_gemeinsam.gdshaderinc).
#
#   bash werkzeuge/wegmaskenprobe.sh
#
# Zeichnet mit einem echten Renderer (ohne DISPLAY über xvfb-run, wie
# foto.sh) eine Testebene von oben und vergleicht 20 Bildpunkte mit der
# CPU-Maske (Grenze 0,02). Ohne Bildschirm prüft die Probe nur die
# Konstanten. pruefe.sh ruft beides auf. Arbeitet auf einer Kopie, oder
# auf der importierten Kopie in MASKE_KOPIE (die bleibt stehen).
#
# Rückgabe: 0 = gleich, 1 = Abweichung, 2 = Abbruch vorab.
set -uo pipefail
{
PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	exit 2
fi
STARTER=()
if [ -z "${DISPLAY:-}" ]; then
	if command -v xvfb-run >/dev/null 2>&1; then
		STARTER=(xvfb-run -a -s "-screen 0 640x480x24")
	else
		echo "ABBRUCH: kein Bildschirm (DISPLAY leer) und kein xvfb-run."
		exit 2
	fi
fi
if [ -n "${MASKE_KOPIE:-}" ]; then
	ZIEL="$MASKE_KOPIE"
else
	ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_maske_XXXXXX")"
	trap 'rm -rf "$ZIEL"' EXIT
	cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
	rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"
	timeout 300 "$GODOT" --headless --path "$ZIEL" --import >/dev/null 2>&1
fi
# `timeout` hinter xvfb-run, wie in foto.sh: So räumt xvfb-run seinen
# X-Server auch nach einem Zeitablauf weg.
${STARTER[@]+"${STARTER[@]}"} timeout 180 "$GODOT" --path "$ZIEL" \
	res://werkzeuge/Wegmaskenprobe.tscn \
	--display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
	--resolution 320x320 --position 4000,4000 2>&1 \
	| grep -vE 'Godot Engine|V-Sync mode|at: set_use_vsync|^\s*$'
exit "${PIPESTATUS[0]}"
}
