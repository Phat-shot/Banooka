#!/usr/bin/env bash
# Schaufenster: der feste Bildersatz für Vorher/Nachher-Vergleiche –
# Splash, Hub und Level 01 aus immer denselben Blickwinkeln, mit den
# Kosten (Draw-Calls, Primitive, VRAM) jedes Bildes.
#
#   bash werkzeuge/schaufenster.sh <Zielordner>              # Arbeitsstand  -> <Ziel>/jetzt/
#   VORHER=HEAD bash werkzeuge/schaufenster.sh <Zielordner>  # Stand von HEAD -> <Ziel>/vorher/
#   SCHAUFENSTER_TEILE=hub,l01 bash werkzeuge/schaufenster.sh <Zielordner>
#
# Üblicher Ablauf einer Verschönerung:
#   1. VORHER=HEAD bash werkzeuge/schaufenster.sh /tmp/schau
#      (geht auch noch nach der Arbeit – HEAD ändert sich ja nicht,
#      solange nichts eingecheckt ist)
#   2. arbeiten
#   3. bash werkzeuge/schaufenster.sh /tmp/schau
#   -> /tmp/schau/vergleich_<teil>.png (vorher | jetzt | Differenz) und
#      die Tabelle "Draw-Calls vorher -> jetzt" am Ende der Ausgabe.
#   Nur einen Teil neu rendern: SCHAUFENSTER_TEILE=l01 …
#
# Teile (Name: Szene, Modus, Stellen):
#   splash    Splash.tscn, zwei Aufnahmen im Abstand von 70 Bildern
#             (die Einblendung ist dann fertig, die Kamera ist gewandert)
#   hub       Hub.tscn, verfolger 0,14,60 (Rundgang aus hub.gd)
#   l01       Level01, verfolger 4,30,50,75,112,136,170,192,216,233
#             (alle Abschnitte, vom Waldrand bis zum Ziel)
#   l01seite  Level01, seite 50,170 (Blick quer auf den Weg)
#   l01nah    Level01, nah 30 (Figur und Umgebung aus der Nähe)
#
# Ausgabe unter <Ziel>/<seite>/ – seite ist "jetzt" oder mit VORHER "vorher":
#   <teil>/*.png      die Aufnahmen; ein Lauf des Teils ersetzt sie alle
#   <teil>/werte.tsv  Kosten je Bild, von foto.gd geschrieben (FOTO_WERTE)
#   werte.tsv         alle Teile zusammen, Spalten:
#                     teil bild draw objekte primitive vram_mb knoten
#   <teil>.png        Kontaktbogen (werkzeuge/kontaktbogen.py)
# und sobald beide Seiten da sind:
#   <Ziel>/vergleich_<teil>.png   Zeile für Zeile vorher | jetzt | Differenz
#
# Warum ein fester Satz: Verglichen wird nur, was unter gleichen
# Bedingungen entstanden ist. Deshalb
#   - läuft Godot mit --fixed-fps 30: Jedes Bild ist genau 1/30 s
#     Spielzeit, egal ob eine Grafikkarte oder llvmpipe zeichnet –
#     Einblendungen, Partikel und Kamerafahrten stehen bei jedem Lauf gleich;
#   - werden FOTO_*-Variablen aus der Umgebung verworfen (bis auf
#     FOTO_BUDGET_DRAW). Ein vergessenes FOTO_STATUS=1 in der Shell hätte
#     sonst die halbe Vorher-Reihe verdorben.
#
# VORHER=<git-ref> rendert den Stand dieses Commits aus `git archive` –
# das Arbeitsverzeichnis bleibt unberührt. Werkzeug von heute, Spiel von
# damals: foto.gd und Foto.tscn kommen aus dem Arbeitsstand, damit auch
# alte Stände Kostenwerte liefern. Passt das heutige foto.gd nicht zu
# einem sehr alten Stand, nimmt das Skript dessen eigenes (dann ohne Kosten).
#
# Eine Projektkopie, EIN Import, dann ein foto.sh-Lauf je Teil
# (FOTO_KOPIE). Ohne DISPLAY startet foto.sh selbst einen unsichtbaren
# X-Server (xvfb-run). Dauer unter llvmpipe mit 4 Kernen: um 6 min.
#
# Umgebung: GODOT (Vorgabe godot), VORHER, SCHAUFENSTER_TEILE,
#           SCHAUFENSTER_ZEITLIMIT (s je Teil, Vorgabe 900), FOTO_BUDGET_DRAW.
# Rückgabe: 0 = alle Teile haben Bilder, 1 = mindestens ein Teil ohne,
#           2 = Abbruch vorab.

set -uo pipefail

# Alles in EINEM Block bis zum exit: Bash liest ein Skript stückweise,
# während es läuft. Wird die Datei mitten in einem minutenlangen Lauf
# geändert (Editor, git checkout), läse Bash danach an der alten Stelle
# weiter – mitten in einer Zeile. Einen Block liest Bash vorab ganz ein.
{

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIELORDNER="${1:?Zielordner angeben}"
mkdir -p "$ZIELORDNER"
# Absolut, weil Godot sich mit --path in die Projektkopie begibt und ein
# relativer Pfad dort ins Leere zeigte.
ZIELORDNER="$(cd "$ZIELORDNER" && pwd)"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "ABBRUCH: '$GODOT' nicht gefunden."
	echo "Godot in den PATH legen oder GODOT=/pfad/zu/godot setzen."
	exit 2
fi
export GODOT
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] \
		&& ! command -v xvfb-run >/dev/null 2>&1; then
	echo "ABBRUCH: kein Bildschirm (DISPLAY leer) und kein xvfb-run."
	echo "xvfb installieren (Debian/Ubuntu: apt install xvfb libgl1-mesa-dri)."
	exit 2
fi

for v in $(compgen -e | grep '^FOTO_'); do
	[ "$v" = FOTO_BUDGET_DRAW ] || unset "$v"
done

# Name -> "Szene|FOTO_WARTEN|Modus|Stellen". Leeres FOTO_WARTEN heißt
# Vorgabe von foto.gd (24 Bilder = 0,8 s bei --fixed-fps 30).
ALLE_TEILE=(splash hub l01 l01seite l01nah)
teil_daten() {
	case "$1" in
	splash)   echo "res://scenes/ui/Splash.tscn|70|verfolger|0,2" ;;
	hub)      echo "res://scenes/hub/Hub.tscn||verfolger|0,14,60" ;;
	l01)      echo "res://scenes/levels/Level01.tscn||verfolger|4,30,50,75,112,136,170,192,216,233" ;;
	l01seite) echo "res://scenes/levels/Level01.tscn||seite|50,170" ;;
	l01nah)   echo "res://scenes/levels/Level01.tscn||nah|30" ;;
	*)        return 1 ;;
	esac
}

TEILE=()
IFS=',' read -r -a WUNSCH <<< "${SCHAUFENSTER_TEILE:-$(IFS=,; echo "${ALLE_TEILE[*]}")}"
for t in "${WUNSCH[@]}"; do
	t="$(echo "$t" | tr -d '[:space:]')"
	[ -z "$t" ] && continue
	if ! teil_daten "$t" >/dev/null; then
		echo "ABBRUCH: unbekannter Teil '$t' (bekannt: ${ALLE_TEILE[*]})."
		exit 2
	fi
	TEILE+=("$t")
done

START=$SECONDS
BASIS="$(mktemp -d "${TMPDIR:-/tmp}/banooka_schau_XXXXXX")"
trap 'rm -rf "$BASIS"' EXIT
KOPIE="$BASIS/projekt"
ALT="$BASIS/altes_werkzeug"
mkdir -p "$KOPIE" "$ALT"
WERKZEUG=(werkzeuge/foto.gd werkzeuge/foto.gd.uid werkzeuge/Foto.tscn)

if [ -n "${VORHER:-}" ]; then
	SEITE=vorher
	if ! git -C "$PROJEKT" rev-parse --verify --quiet "${VORHER}^{commit}" >/dev/null; then
		echo "ABBRUCH: VORHER=$VORHER ist kein Commit in $PROJEKT."
		exit 2
	fi
	if ! git -C "$PROJEKT" archive "$VORHER" | tar -x -C "$KOPIE"; then
		echo "ABBRUCH: git archive $VORHER fehlgeschlagen."
		exit 2
	fi
	for f in "${WERKZEUG[@]}"; do
		[ -f "$KOPIE/$f" ] && cp "$KOPIE/$f" "$ALT/"
		[ -f "$PROJEKT/$f" ] && cp "$PROJEKT/$f" "$KOPIE/$f"
	done
	echo "=== vorher: $VORHER ($(git -C "$PROJEKT" log -1 --format='%h %s' "$VORHER")) ==="
else
	SEITE=jetzt
	cp -r "$PROJEKT"/. "$KOPIE"/ 2>/dev/null
	rm -rf "$KOPIE/.godot" "$KOPIE/.git" "$KOPIE/export"
	# Liegt der Zielordner im Projekt, wären die alten Bilder sonst Teil
	# der Kopie – und Godot importierte sie alle mit.
	case "$ZIELORDNER/" in
	"$PROJEKT"/*) rm -rf "$KOPIE/${ZIELORDNER#"$PROJEKT"/}" ;;
	esac
	echo "=== jetzt: Arbeitsstand von $PROJEKT ==="
fi
SEITENORDNER="$ZIELORDNER/$SEITE"
mkdir -p "$SEITENORDNER"

IMPORT="$(timeout 600 "$GODOT" --headless --path "$KOPIE" --import 2>&1 \
	| grep -E -A1 'SCRIPT ERROR|Parse Error' | grep -v '^--$')"
if [ -n "$IMPORT" ]; then
	echo "$IMPORT"
	echo "HINWEIS: Der Import meldet Skriptfehler – fehlende oder falsche Bilder kommen vermutlich daher."
fi
echo "(Kopie und Import: $((SECONDS - START)) s)"

# Ein foto.sh-Lauf für einen Teil; Ausgabe live und in lauf.log.
rendere_teil() {
	local teil="$1" aus="$2" level warten modus stellen
	IFS='|' read -r level warten modus stellen <<< "$(teil_daten "$teil")"
	FOTO_KOPIE="$KOPIE" FOTO_LEVEL="$level" FOTO_WARTEN="$warten" \
		FOTO_WERTE="$aus/werte.tsv" FOTO_ARGS="--fixed-fps 30" \
		FOTO_ZEITLIMIT="${SCHAUFENSTER_ZEITLIMIT:-900}" \
		bash "$PROJEKT/werkzeuge/foto.sh" "$aus" "$modus" "$stellen" 2>&1 \
		| tee "$BASIS/lauf.log"
}

FEHLT=0
ALTES_WERKZEUG=0
for teil in "${TEILE[@]}"; do
	aus="$SEITENORDNER/$teil"
	mkdir -p "$aus"
	rm -f "$aus"/*.png "$aus/werte.tsv"
	IFS='|' read -r level _ modus stellen <<< "$(teil_daten "$teil")"
	echo "=== $SEITE/$teil: ${level##*/} $modus $stellen ==="
	t0=$SECONDS
	rendere_teil "$teil" "$aus"
	if [ "$SEITE" = vorher ] && [ "$ALTES_WERKZEUG" = 0 ] \
			&& ! ls "$aus"/*.png >/dev/null 2>&1 \
			&& grep -q 'res://werkzeuge/foto.gd' "$BASIS/lauf.log" \
			&& [ -f "$ALT/foto.gd" ]; then
		echo "HINWEIS: Das heutige foto.gd passt nicht zu $VORHER – weiter mit dessen eigenem (ohne Kostenwerte)."
		cp "$ALT"/* "$KOPIE/werkzeuge/"
		ALTES_WERKZEUG=1
		rendere_teil "$teil" "$aus"
	fi
	if ! ls "$aus"/*.png >/dev/null 2>&1; then
		echo "FEHLER: $teil hat keine Bilder geliefert."
		FEHLT=1
	fi
	echo "($teil: $((SECONDS - t0)) s)"
done

# Gesamttabelle aus allen vorhandenen Teilen – auch aus früheren Läufen,
# wenn diesmal nur ein Teil neu gerendert wurde.
{
	printf 'teil\tbild\tdraw\tobjekte\tprimitive\tvram_mb\tknoten\n'
	for teil in "${ALLE_TEILE[@]}"; do
		f="$SEITENORDNER/$teil/werte.tsv"
		[ -f "$f" ] && awk -v t="$teil" 'NR > 1 { print t "\t" $0 }' "$f"
	done
} > "$SEITENORDNER/werte.tsv"

echo "=== Kosten ($SEITE) ==="
awk -F'\t' 'NR > 1 { printf "  %-9s %-22s draw %5d  obj %5d  prim %5dk  vram %6.1f MB  knoten %5d\n",
	$1, $2, $3, $4, int($5 / 1000 + 0.5), $6, $7 }' "$SEITENORDNER/werte.tsv"

V="$ZIELORDNER/vorher/werte.tsv"
J="$ZIELORDNER/jetzt/werte.tsv"
if [ -f "$V" ] && [ -f "$J" ]; then
	echo "=== Draw-Calls vorher -> jetzt ==="
	awk -F'\t' 'FNR == 1 { next }
		NR == FNR { d[$1 FS $2] = $3; p[$1 FS $2] = $5; next }
		($1 FS $2) in d { k = $1 FS $2
			printf "  %-9s %-22s draw %5d -> %5d (%+5d)   prim %5dk -> %5dk\n",
				$1, $2, d[k], $3, $3 - d[k], int(p[k] / 1000 + 0.5), int($5 / 1000 + 0.5) }' "$V" "$J"
fi

# Kontaktbögen: python3 mit Pillow, sonst uvx (holt Pillow einmalig).
PY=()
if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' 2>/dev/null; then
	PY=(python3)
elif command -v uvx >/dev/null 2>&1; then
	PY=(uvx -q --with pillow python)
fi
if [ ${#PY[@]} -eq 0 ]; then
	echo "HINWEIS: kein Pillow (pip install pillow, oder uv installieren) – Kontaktbögen übersprungen."
else
	echo "=== Kontaktbögen ==="
	for teil in "${TEILE[@]}"; do
		ls "$SEITENORDNER/$teil"/*.png >/dev/null 2>&1 || continue
		"${PY[@]}" "$PROJEKT/werkzeuge/kontaktbogen.py" "$SEITENORDNER/$teil" \
			-o "$SEITENORDNER/$teil.png" \
			|| echo "HINWEIS: Kontaktbogen für $teil fehlgeschlagen."
		if [ -d "$ZIELORDNER/vorher/$teil" ] && [ -d "$ZIELORDNER/jetzt/$teil" ]; then
			"${PY[@]}" "$PROJEKT/werkzeuge/kontaktbogen.py" --vergleich --diff \
				--breite 480 "$ZIELORDNER/vorher/$teil" "$ZIELORDNER/jetzt/$teil" \
				-o "$ZIELORDNER/vergleich_$teil.png" \
				|| echo "HINWEIS: Vergleichsbogen für $teil fehlgeschlagen."
		fi
	done
fi

echo "=== Schaufenster $SEITE fertig in $((SECONDS - START)) s: $SEITENORDNER ==="
exit "$FEHLT"
}
