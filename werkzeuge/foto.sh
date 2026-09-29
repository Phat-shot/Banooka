#!/usr/bin/env bash
# Rendert Bilder eines Levels als PNG.
#
#   bash werkzeuge/foto.sh <Zielverzeichnis> [verfolger|seite|orbit|nah] [Strecken]
#
# Beispiele:
#   bash werkzeuge/foto.sh /tmp/bilder
#   bash werkzeuge/foto.sh /tmp/bilder seite 24,59,130
#   FOTO_LEVEL=res://scenes/hub/Hub.tscn bash werkzeuge/foto.sh /tmp/bilder orbit 0,90,180
#   FOTO_ARGS="--fixed-fps 30" bash werkzeuge/foto.sh /tmp/bilder verfolger 4,50,112
#
# Modi: verfolger (Spielkamera am Korridor), seite (quer darauf),
#       orbit (Kamera umkreist die Szene – für Räume und Menüs),
#       nah (dicht an der Figur).
# Szenen ohne Korridorverlauf wechseln automatisch in den Orbit-Modus.
# Die übrigen FOTO_*-Variablen (Level, Wartezeit, Zeitmodus, Kostentabelle
# …) liest foto.gd; sie stehen dort im Kopf. Für den festen Vorher/Nachher-
# Bildersatz gibt es werkzeuge/schaufenster.sh.
#
# Zusätzlich liest dieses Skript:
#   GODOT          Godot-Programm, Vorgabe `godot` aus dem PATH
#   FOTO_ARGS      weitere Godot-Argumente, z. B. "--fixed-fps 30". Damit
#                  dauert jedes Bild genau 1/30 s Spielzeit, egal wie
#                  langsam der Rechner zeichnet: Einblendungen, Partikel und
#                  Kamerafahrten stehen bei jedem Lauf gleich, und nur so
#                  sind Vorher/Nachher-Bilder vergleichbar. FOTO_WARTEN zählt
#                  dann Spielzeit (24 Bilder = 0,8 s); der Splash braucht
#                  >= 60, sonst ist er mitten in der Einblendung.
#   FOTO_KOPIE     bereits importierte Projektkopie. Kopieren und Import
#                  entfallen dann – schaufenster.sh rendert so mehrere
#                  Szenen aus EINER Kopie. Die Kopie wird nicht gelöscht.
#   FOTO_ZEITLIMIT Sekunden, nach denen der Renderlauf abgebrochen wird
#                  (Vorgabe 300); unter Software-GL mit vielen Stellen höher.
#
# Godot zeichnet im Headless-Modus nicht (dort gibt es nur den
# Dummy-Renderer). Deshalb läuft das über einen echten Bildschirm; das
# Fenster wird weit außerhalb des sichtbaren Bereichs geöffnet, stört
# also nicht. Ohne DISPLAY (Server, Container, CI) startet das Skript
# selbst einen unsichtbaren X-Server über xvfb-run – gezeichnet wird dann
# mit Mesa/llvmpipe, langsam (2–3 Bilder/s), aber pixelgenau.
# Gearbeitet wird auf einer Kopie des Projekts, damit parallele Läufe
# sich nicht über den .godot-Cache stören.
#
# Rückgabe: Exit-Code des Godot-Laufs (124 = Zeitlimit), 2 = Abbruch vorab.

set -uo pipefail

# Alles in EINEM Block bis zum exit: Bash liest ein Skript stückweise,
# während es läuft. Wird die Datei mitten in einem minutenlangen Lauf
# geändert (Editor, git checkout), läse Bash danach an der alten Stelle
# weiter – mitten in einer Zeile. Einen Block liest Bash vorab ganz ein.
{

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FOTO_ZIEL="${1:?Zielverzeichnis angeben}"
export FOTO_MODUS="${2:-verfolger}"
export FOTO_STELLEN="${3:-}"
export FOTO_LEVEL="${FOTO_LEVEL:-res://scenes/levels/Level01.tscn}"
export FOTO_ZEITMODUS="${FOTO_ZEITMODUS:-0}"

# Wie in pruefe.sh: Ohne Godot schlug früher jeder Aufruf still fehl, und
# das Einzige, was man bemerkte, waren fehlende Bilder.
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	echo "Godot in den PATH legen oder GODOT=/pfad/zu/godot setzen."
	exit 2
fi

# Godot soll über X11 zeichnen. Ohne DISPLAY meldet es nur "X11 Display is
# not available", weicht auf Wayland aus und scheitert dort ebenfalls –
# also selbst einen unsichtbaren X-Server mitbringen. Ist schon einer da
# (Desktop, oder der Aufrufer hat xvfb-run vorangestellt), bleibt alles
# wie gehabt.
STARTER=()
if [ -z "${DISPLAY:-}" ]; then
	if command -v xvfb-run >/dev/null 2>&1; then
		STARTER=(xvfb-run -a -s "-screen 0 1280x720x24")
	elif [ -z "${WAYLAND_DISPLAY:-}" ]; then
		echo "ABBRUCH: kein Bildschirm (DISPLAY leer) und kein xvfb-run."
		echo "xvfb installieren (Debian/Ubuntu: apt install xvfb libgl1-mesa-dri)."
		exit 2
	fi
fi

# Zusätzliche Godot-Argumente bewusst als Wörter zerlegt, damit
# FOTO_ARGS="--fixed-fps 30" als zwei Argumente ankommt.
read -r -a ZUSATZ <<< "${FOTO_ARGS:-}"

# Meldungen, die beim Import den Grund für fehlende Bilder verraten.
# `-A1` nimmt die Folgezeile mit, dort steht Datei und Zeile ("at: …").
SKRIPTFEHLER='SCRIPT ERROR|Parse Error'

# Pfade absolut machen: Godot wechselt mit --path in die Projektkopie, ein
# relatives Ziel landete dort – und wurde mit der Kopie gelöscht.
mkdir -p "$FOTO_ZIEL"
FOTO_ZIEL="$(cd "$FOTO_ZIEL" && pwd)"
case "${FOTO_WERTE:-/}" in
/*) ;;
*) export FOTO_WERTE="$PWD/$FOTO_WERTE" ;;
esac
if [ -n "${FOTO_KOPIE:-}" ]; then
	if [ ! -f "$FOTO_KOPIE/project.godot" ]; then
		echo "ABBRUCH: FOTO_KOPIE=$FOTO_KOPIE ist kein Godot-Projekt."
		exit 2
	fi
	ZIEL="$FOTO_KOPIE"
else
	ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_foto_XXXXXX")"
	trap 'rm -rf "$ZIEL"' EXIT
	cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
	rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"

	# Früher ging die ganze Importausgabe nach /dev/null. Ein Parse-Fehler
	# zeigte sich dann nur als leeres Zielverzeichnis, ohne jeden Hinweis.
	IMPORT="$(timeout 300 "$GODOT" --headless --path "$ZIEL" --import 2>&1 \
		| grep -E -A1 "$SKRIPTFEHLER" | grep -v '^--$')"
	if [ -n "$IMPORT" ]; then
		echo "$IMPORT"
		echo "HINWEIS: Der Import meldet Skriptfehler – fehlende oder falsche Bilder kommen vermutlich daher."
	fi
fi

# `timeout` steht HINTER xvfb-run: Bricht es ab, beendet es nur Godot, und
# xvfb-run räumt seinen X-Server ordentlich weg. Anders herum bliebe bei
# jedem Zeitablauf ein verwaister Xvfb zurück.
# Ausgefiltert werden nur Kopfzeile, Leerzeilen und die V-Sync-Warnung, die
# jeder Xvfb-Lauf wirft (Mesa kann dort kein V-Sync). Die Zeile
# "OpenGL API …" bleibt stehen: Sie sagt, ob llvmpipe oder eine echte
# Grafikkarte gezeichnet hat. --line-buffered, damit jede Aufnahmezeile
# sofort erscheint und nicht erst am Ende eines minutenlangen Laufs.
# Die Form ${A[@]+"${A[@]}"} hält leere Listen unter `set -u` auch im
# alten Bash 3 (macOS) aus.
${STARTER[@]+"${STARTER[@]}"} timeout "${FOTO_ZEITLIMIT:-300}" "$GODOT" --path "$ZIEL" \
	res://werkzeuge/Foto.tscn \
	--display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
	--resolution 1280x720 --position 4000,4000 ${ZUSATZ[@]+"${ZUSATZ[@]}"} 2>&1 \
	| grep --line-buffered -vE 'Godot Engine|V-Sync mode|at: set_use_vsync|^\s*$'
STATUS=${PIPESTATUS[0]}
if [ "$STATUS" = 124 ]; then
	echo "ABBRUCH: Zeitlimit von ${FOTO_ZEITLIMIT:-300} s erreicht (FOTO_ZEITLIMIT erhöhen)."
fi
exit "$STATUS"
}
