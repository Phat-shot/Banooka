#!/usr/bin/env bash
# Sucht Ruckler beim Laufen (werkzeuge/ruckelprobe.gd): dieselbe Zickzack-
# fahrt zweimal, Bildzeiten je Bild. Braucht einen echten Renderer; ohne
# DISPLAY startet das Skript selbst einen unsichtbaren X-Server.
#
#   bash werkzeuge/ruckelprobe.sh                      # Rechnerweg, 640x360
#   RUCKEL_REDUZIERT=1 bash werkzeuge/ruckelprobe.sh   # wie die App auf dem Handy
#   RUCKEL_VORWAERMEN=0 …                              # ohne Rundgang (Vergleich)
#   RUCKEL_AUFLOESUNG=1280x720 …
#   RUCKEL_LEVEL=res://scenes/hub/Hub.tscn …          # Portalraum (eigene Fahrt)
#   RUCKEL_KOPIE=<importierte Kopie> …                # ohne Kopieren und Import
#
# Die übrigen RUCKEL_*-Variablen (Besuche, Spielstand, Schwelle) stehen im
# Kopf von ruckelprobe.gd.
#
# Kleine Auflösung mit Absicht: Unter llvmpipe kostet jeder Bildpunkt
# Rechenzeit, und die Ruckler (Shader übersetzen) sollen sich vom
# gewöhnlichen Bild abheben. Läuft auf einer Kopie mit leerem user://
# (wie ein erster Start nach der Installation) und ohne den Shader-Speicher
# von Mesa (MESA_SHADER_CACHE_DISABLE): Der liegt sonst in ~/.cache und
# behält übersetzte Shader über Läufe hinweg, auch die anderer Läufe auf
# demselben Rechner – ein zweiter Lauf der Probe übersetzte dann kaum noch
# etwas (Portalraum vor dem Rundgang, bis zum Ausblenden des Ladeschirms:
# 27,3 s ohne den Speicher, 7,6 s mit gefülltem). RUCKEL_MESA_SPEICHER=1
# lässt ihn an.
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
NUTZER="$(mktemp -d "${TMPDIR:-/tmp}/banooka_ruckel_user_XXXXXX")"
if [ -n "${RUCKEL_KOPIE:-}" ]; then
	# Wie FOTO_KOPIE in foto.sh: eine schon importierte Kopie, die bleibt.
	if [ ! -f "$RUCKEL_KOPIE/project.godot" ]; then
		echo "ABBRUCH: RUCKEL_KOPIE=$RUCKEL_KOPIE ist kein Godot-Projekt."
		exit 2
	fi
	ZIEL="$RUCKEL_KOPIE"
	trap 'rm -rf "$NUTZER"' EXIT
else
	ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_ruckel_XXXXXX")"
	trap 'rm -rf "$ZIEL" "$NUTZER"' EXIT
	cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
	rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"
	timeout 300 "$GODOT" --headless --path "$ZIEL" --import >/dev/null 2>&1
fi
if [ "${RUCKEL_MESA_SPEICHER:-0}" != 1 ]; then
	export MESA_SHADER_CACHE_DISABLE=true
fi
XDG_DATA_HOME="$NUTZER" ${STARTER[@]+"${STARTER[@]}"} timeout "${RUCKEL_ZEITLIMIT:-1800}" \
	"$GODOT" --path "$ZIEL" res://werkzeuge/Ruckelprobe.tscn \
	--display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
	--resolution "${RUCKEL_AUFLOESUNG:-640x360}" --position 4000,4000 --fixed-fps 30 2>&1 \
	| grep --line-buffered -vE 'Godot Engine|V-Sync mode|at: set_use_vsync|^\s*$'
exit "${PIPESTATUS[0]}"
}
