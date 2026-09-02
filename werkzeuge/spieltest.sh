#!/usr/bin/env bash
# Spielt das Spiel selbsttätig durch und legt Bilder ab.
#
#   bash werkzeuge/spieltest.sh <Zielverzeichnis> [Höchstdauer in s] [Projektordner]
#
# Der Bot (werkzeuge/spieltest.gd) wird in einer Projektkopie als Autoload
# eingehängt, damit er Szenenwechsel übersteht. Gestartet wird die echte
# Hauptszene, also derselbe Weg wie beim Spieler: Startbildschirm →
# Portalraum → Level.
#
# Godot zeichnet im Headless-Modus nicht; darum läuft das über die echte
# GPU mit einem Fenster weit außerhalb des sichtbaren Bereichs.
#
# Umgebungsvariablen:
#   TEST_LEVEL   Levelnummern, mit Komma getrennt (Vorgabe: alle gebauten)

set -uo pipefail

WERKZEUGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEST_ZIEL="${1:?Zielverzeichnis angeben}"
export TEST_DAUER="${2:-600}"
PROJEKT="${3:-$(cd "$WERKZEUGE/.." && pwd)}"

mkdir -p "$TEST_ZIEL"
ZIEL="$(mktemp -d "${TMPDIR:-/tmp}/banooka_spieltest_XXXXXX")"
# Der Bot braucht einen frischen Spielstand, damit er bei Level 01 beginnt.
# Der ECHTE Spielstand darf dabei nicht draufgehen: Er wird zur Seite
# gelegt und am Ende zurückgeholt – auch wenn der Lauf abstürzt oder
# abgebrochen wird. Vorher hat dieses Skript ihn gelöscht.
STAND="$HOME/.local/share/godot/app_userdata/Banooka"
SICHERUNG="$(mktemp -d "${TMPDIR:-/tmp}/banooka_stand_XXXXXX")"
aufraeumen() {
	rm -rf "$ZIEL"
	rm -f "$STAND"/spielstand_*.cfg 2>/dev/null
	if compgen -G "$SICHERUNG/spielstand_*.cfg" >/dev/null 2>&1; then
		cp "$SICHERUNG"/spielstand_*.cfg "$STAND"/ 2>/dev/null
		echo "Spielstand wiederhergestellt."
	fi
	rm -rf "$SICHERUNG"
}
trap aufraeumen EXIT
cp -r "$PROJEKT"/. "$ZIEL"/ 2>/dev/null
rm -rf "$ZIEL/.godot" "$ZIEL/.git" "$ZIEL/export"
# Den Bot immer aus diesem Werkzeugordner nehmen, auch wenn das geprüfte
# Projekt eine ältere Fassung mitbringt.
cp "$WERKZEUGE/spieltest.gd" "$ZIEL/werkzeuge/spieltest.gd"

# Bot als letztes Autoload eintragen
python3 - "$ZIEL/project.godot" <<'PY'
import sys
pfad = sys.argv[1]
zeilen = open(pfad, encoding="utf-8").read().split("\n")
neu = 'Spieltest="*res://werkzeuge/spieltest.gd"'
if neu not in zeilen:
    i = zeilen.index("[autoload]") + 1
    # ans Ende des Autoload-Abschnitts, damit die Spiel-Autoloads zuerst stehen
    while i < len(zeilen) and not zeilen[i].startswith("["):
        i += 1
    while i > 0 and zeilen[i - 1].strip() == "":
        i -= 1
    zeilen.insert(i, neu)
open(pfad, "w", encoding="utf-8").write("\n".join(zeilen))
PY

# Frischer Spielstand, damit der Test immer bei Level 01 beginnt –
# der echte wandert so lange in die Sicherung (siehe `aufraeumen`).
if compgen -G "$STAND/spielstand_*.cfg" >/dev/null 2>&1; then
	cp "$STAND"/spielstand_*.cfg "$SICHERUNG"/ 2>/dev/null
	echo "Spielstand gesichert nach $SICHERUNG"
fi
rm -f "$STAND"/spielstand_*.cfg 2>/dev/null

timeout 300 godot --headless --path "$ZIEL" --import >/dev/null 2>&1
timeout $((TEST_DAUER + 90)) godot --path "$ZIEL" \
	--display-driver x11 --rendering-driver opengl3 \
	--resolution 1280x720 --position 4000,4000 2>&1 \
	| tee "$TEST_ZIEL/protokoll.txt" | grep -vE "Godot Engine|OpenGL API|^[[:space:]]*$"
