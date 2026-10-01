#!/usr/bin/env bash
# Sucht Ruckler beim Laufen (werkzeuge/ruckelprobe.gd): dieselbe Zickzack-
# fahrt zweimal, Bildzeiten je Bild. Braucht einen echten Renderer; ohne
# DISPLAY startet das Skript selbst einen unsichtbaren X-Server.
#
#   bash werkzeuge/ruckelprobe.sh                      # Rechnerweg, 640x360
#   RUCKEL_REDUZIERT=1 bash werkzeuge/ruckelprobe.sh   # wie die App auf dem Handy
#   RUCKEL_VORWAERMEN=0 …                              # ohne Rundgang (Vergleich)
#   RUCKEL_AUFLOESUNG=1280x720 …
#
# Kleine Auflösung mit Absicht: Unter llvmpipe kostet jeder Bildpunkt
# Rechenzeit, und die Ruckler (Shader übersetzen) sollen sich vom
# gewöhnlichen Bild abheben. Läuft auf einer Kopie mit leerem user://
# (wie ein erster Start nach der Installation).
#
# Rückgabe: Exit-Code des Godot-Laufs (124 = Zeitlimit).

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
		STARTER=(xvfb-run -a -s "-screen 0 1280x720x24")
	else
		echo "ABBRUCH: kein Bildschirm (DISPLAY leer) und kein xvfb-run."
		exit 2
	fi
fi
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_ruckel_XXXXXX")"
NUTZER="$(mktemp -d "${TMPDIR:-/tmp}/banooka_ruckel_user_XXXXXX")"
trap 'rm -rf "$ZIEL" "$NUTZER"' EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"
timeout 300 "$GODOT" --headless --path "$ZIEL" --import >/dev/null 2>&1
XDG_DATA_HOME="$NUTZER" ${STARTER[@]+"${STARTER[@]}"} timeout "${RUCKEL_ZEITLIMIT:-1800}" \
	"$GODOT" --path "$ZIEL" res://werkzeuge/Ruckelprobe.tscn \
	--display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
	--resolution "${RUCKEL_AUFLOESUNG:-640x360}" --position 4000,4000 --fixed-fps 30 2>&1 \
	| grep --line-buffered -vE 'Godot Engine|V-Sync mode|at: set_use_vsync|^\s*$'
exit "${PIPESTATUS[0]}"
}
