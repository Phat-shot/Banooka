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
#   l01       Level01, verfolger 4,31,46,70,101,119,140,176,212,249,275.5
#             (Start, Enthüllung, Kanzel, Käfer an der Stufe, Pforte,
#             Fallkerbe, Terrassen, Furt, G1, Oberwurzel, Ziel – das
#             Zielportal bei 283 steht dort vor der Figur, nicht hinter ihr)
#   l01seite  Level01, seite 60,186 (Felswand; Wiese und Stammfuß)
#   l01nah    Level01, nah 53.5 (Rasen und Lippe aus der Nähe; hinter den
#             Kisten bei 52, auf denen die Figur sonst stünde)
#
# Nur auf Wunsch (SCHAUFENSTER_TEILE=wache usw.), nicht im vollen Satz:
#   wache     Level01 verfolger 4,101,212,275.5 und seite 186, Hub
#             verfolger 14 – sechs Bilder aus drei Läufen, alle Stellen aus
#             den Teilen oben. Der Wächter beim Neubau von Raum 1: Level 01
#             und der Portalraum teilen Kamera, Gelände, Wald und Shader mit
#             den neuen Leveln, dürfen sich dabei aber um keinen Bildpunkt
#             ändern. Sechs Bilder statt siebzehn, weil diese Prüfung nach
#             JEDEM Paket läuft (Start, Pforte, G1, Ziel, Stammfuß von der
#             Seite, Portalraum). Die Bildnamen tragen den Lauf vorn
#             (l01_, l01seite_, hub_) – verfolger_00_… aus Level 01 und
#             Portalraum wären sonst nicht auseinanderzuhalten.
#   l05       Level05, verfolger 8,60,140,218,280,296 – die Messtore des
#             Neubaus (Entwurf L05 §9.3, §12 P1: Start mit schlafendem
#             Keiler, Hohlweg, Terrassen, Fluderjoche, Wehr, Ziel)
#   l05seite  Level05, seite 40,150,240 (Lösswände und Hohlwegkrone,
#             Terrassenhang, Tobel mit Südwand – die Nähte von Saum und
#             Gelände)
#   l05nah    Level05, nah 76,138,196,230,286,299 – Lippen, Stirnen und
#             Ufer der Lücken L1, L2, L4, L5, L6 und das Wegende aus der
#             Nähe. Die Seitkamera steht hinter der Krone des Sonnenhangs
#             und zeigt vom Hohlweg wenig; was Saum, Wegbauten und Wasser an
#             den Lücken ändern, zeigt erst dieser Teil.
#   Mit l05, l05seite und l05nah vergleicht jedes Paket des Neubaus von
#   Level 05 seinen Stand mit dem des vorigen (VORHER=<Commit des
#   Vorpakets>).
#
# Ausgabe unter <Ziel>/<seite>/ – seite ist "jetzt" oder mit VORHER "vorher":
#   <teil>/*.png      die Aufnahmen; ein Lauf des Teils ersetzt sie alle
#   <teil>/werte.tsv  Kosten je Bild, von foto.gd geschrieben (FOTO_WERTE)
#   werte.tsv         alle Teile zusammen, Spalten:
#                     teil bild draw objekte primitive vram_mb knoten
#   <teil>.png        Kontaktbogen (werkzeuge/kontaktbogen.py)
# und sobald beide Seiten da sind:
#   <Ziel>/vergleich_<teil>.png   Zeile für Zeile vorher | jetzt | Differenz
#   "Gleichheit vorher -> jetzt"  am Ende der Ausgabe, je Bild: die Kosten
#                     als Differenz und die Bildpunkte – "gleich", wenn
#                     keiner abweicht (ImageChops.difference(…).getbbox()
#                     ist None), sonst die mittlere Abweichung (0–255, wie im
#                     Vergleichsbogen, aber auf vier Stellen: gerundet auf
#                     eine stünde dort bei 0,04 schon "0.0"), die größte und
#                     der Anteil abweichender Bildpunkte. Je Teil eine
#                     Schlusszeile; "im Rahmen" heißt draw ±2, objekte,
#                     primitive und knoten gleich, vram ±0,5 MB.
#
# Warum ein fester Satz: Verglichen wird nur, was unter gleichen
# Bedingungen entstanden ist. Deshalb
#   - läuft Godot mit --fixed-fps 30: Jedes Bild ist genau 1/30 s
#     Spielzeit, egal ob eine Grafikkarte oder llvmpipe zeichnet –
#     Einblendungen, Partikel und Kamerafahrten stehen bei jedem Lauf gleich;
#   - werden FOTO_*-Variablen aus der Umgebung verworfen (bis auf
#     FOTO_BUDGET_DRAW). Ein vergessenes FOTO_STATUS=1 in der Shell hätte
#     sonst die halbe Vorher-Reihe verdorben;
#   - läuft jeder Lauf mit leerem Benutzerordner (user://), also ohne
#     Spielstand und mit der Standardfigur;
#   - würfelt jeder Lauf mit demselben Startwert (FOTO_SAAT=1). Früchte
#     und Gegner ziehen ihre Phase aus dem Zufall, den Godot bei jedem
#     Start neu mischt. Ohne festen Startwert war von drei Läufen
#     desselben Stands kein Bild mit einem anderen pixelgleich (Früchte,
#     Spinne, Käfer, Pfeil im Portalraum; mittlere Abweichung bis 1,25),
#     mit ihm sind es zwei Läufe in allen sechs Bildern des Teils wache.
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

# Name -> eine Zeile je foto.sh-Lauf: "Szene|FOTO_WARTEN|Modus|Stellen|Präfix".
# Leeres FOTO_WARTEN heißt Vorgabe von foto.gd (24 Bilder = 0,8 s bei
# --fixed-fps 30). Ohne Präfix landen die Bilder wie immer direkt im
# Ordner des Teils; ein Teil aus mehreren Läufen gibt jedem Lauf ein
# Präfix für die Bildnamen.
ALLE_TEILE=(splash hub l01 l01seite l01nah)
# Nur über SCHAUFENSTER_TEILE: Ohne Angabe bleibt es beim bisherigen
# Satz, ohne drei Läufe mehr.
WUNSCH_TEILE=(wache l05 l05seite l05nah)
teil_daten() {
	case "$1" in
	splash)   echo "res://scenes/ui/Splash.tscn|70|verfolger|0,2" ;;
	hub)      echo "res://scenes/hub/Hub.tscn||verfolger|0,14,60" ;;
	l01)      echo "res://scenes/levels/Level01.tscn||verfolger|4,31,46,70,101,119,140,176,212,249,275.5" ;;
	l01seite) echo "res://scenes/levels/Level01.tscn||seite|60,186" ;;
	l01nah)   echo "res://scenes/levels/Level01.tscn||nah|53.5" ;;
	wache)    printf '%s\n' \
			"res://scenes/levels/Level01.tscn||verfolger|4,101,212,275.5|l01_" \
			"res://scenes/levels/Level01.tscn||seite|186|l01seite_" \
			"res://scenes/hub/Hub.tscn||verfolger|14|hub_" ;;
	l05)      echo "res://scenes/levels/Level05.tscn||verfolger|8,60,140,218,280,296" ;;
	l05seite) echo "res://scenes/levels/Level05.tscn||seite|40,150,240" ;;
	l05nah)   echo "res://scenes/levels/Level05.tscn||nah|76,138,196,230,286,299" ;;
	*)        return 1 ;;
	esac
}

TEILE=()
IFS=',' read -r -a WUNSCH <<< "${SCHAUFENSTER_TEILE:-$(IFS=,; echo "${ALLE_TEILE[*]}")}"
for t in "${WUNSCH[@]}"; do
	t="$(echo "$t" | tr -d '[:space:]')"
	[ -z "$t" ] && continue
	if ! teil_daten "$t" >/dev/null; then
		echo "ABBRUCH: unbekannter Teil '$t' (bekannt: ${ALLE_TEILE[*]} ${WUNSCH_TEILE[*]})."
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
# Eigener, leerer Benutzerordner (user://): Spielstände und die Figurwahl
# des Rechners zeigten sonst im Bild – eine fremde Figur und fünf
# geschaffte Level haben schon einmal einen Nachher-Satz verdorben.
# Godot legt user:// unter Linux in $XDG_DATA_HOME ab.
export XDG_DATA_HOME="$BASIS/benutzer"
mkdir -p "$XDG_DATA_HOME"
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

# Ein foto.sh-Lauf je Zeile von teil_daten; Ausgabe live und in lauf.log.
# Ein Lauf mit Präfix zeichnet in einen eigenen Ordner; danach wandern
# seine Bilder und Kostenzeilen mit dem Präfix im Namen zum Teil. Ohne
# Präfix (jeder Teil aus EINEM Lauf) bleibt es beim Aufruf wie zuvor.
rendere_teil() {
	local teil="$1" aus="$2" zeile level warten modus stellen praefix ort bild
	local laeufe=()
	while IFS= read -r zeile; do
		[ -n "$zeile" ] && laeufe+=("$zeile")
	done < <(teil_daten "$teil")
	: > "$BASIS/lauf.log"
	for zeile in ${laeufe[@]+"${laeufe[@]}"}; do
		IFS='|' read -r level warten modus stellen praefix <<< "$zeile"
		ort="$aus"
		if [ -n "$praefix" ]; then
			ort="$BASIS/lauf_$praefix"
			rm -rf "$ort"
			mkdir -p "$ort"
		fi
		FOTO_KOPIE="$KOPIE" FOTO_LEVEL="$level" FOTO_WARTEN="$warten" \
			FOTO_WERTE="$ort/werte.tsv" FOTO_ARGS="--fixed-fps 30" FOTO_SAAT=1 \
			FOTO_ZEITLIMIT="${SCHAUFENSTER_ZEITLIMIT:-900}" \
			bash "$PROJEKT/werkzeuge/foto.sh" "$ort" "$modus" "$stellen" 2>&1 \
			| tee -a "$BASIS/lauf.log"
		[ -n "$praefix" ] || continue
		for bild in "$ort"/*.png; do
			[ -f "$bild" ] && mv "$bild" "$aus/$praefix${bild##*/}"
		done
		if [ -f "$ort/werte.tsv" ]; then
			[ -f "$aus/werte.tsv" ] || head -n 1 "$ort/werte.tsv" > "$aus/werte.tsv"
			awk -v p="$praefix" 'BEGIN { FS = OFS = "\t" } NR > 1 { $1 = p $1; print }' \
				"$ort/werte.tsv" >> "$aus/werte.tsv"
		fi
	done
}

FEHLT=0
ALTES_WERKZEUG=0
for teil in "${TEILE[@]}"; do
	aus="$SEITENORDNER/$teil"
	mkdir -p "$aus"
	rm -f "$aus"/*.png "$aus/werte.tsv"
	# Szene, Modus, Stellen je Lauf; mehrere Läufe mit " + " dazwischen.
	echo "=== $SEITE/$teil: $(teil_daten "$teil" | awk -F'|' '{ n = split($1, p, "/")
		printf "%s%s %s %s", (NR > 1 ? " + " : ""), p[n], $3, $4 }') ==="
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
	for teil in "${ALLE_TEILE[@]}" "${WUNSCH_TEILE[@]}"; do
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

# Gleichheit als Zahl, sobald beide Seiten eines Teils da sind. Der
# Vergleichsbogen zeigt Unterschiede fürs Auge, seine Abweichung steht
# auf eine Stelle gerundet – 0,04 hieße dort "0.0", und ein Bild mit drei
# geänderten Bildpunkten sähe aus wie ein gleiches. Wer "unverändert"
# verlangt (der Wächter beim Neubau von Raum 1), braucht die Zahl.
if [ ${#PY[@]} -gt 0 ]; then
	"${PY[@]}" - "$ZIELORDNER" "${TEILE[@]}" <<'PYTHON' \
		|| echo "HINWEIS: Gleichheitsprüfung fehlgeschlagen."
from __future__ import annotations

import csv
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

# So weit darf ein Kostenwert wandern und gilt noch als unverändert – der
# Spielraum des Wächters beim Neubau von Raum 1. Gemessen haben fünf
# Läufe desselben Stands (Teil wache) in keinem der fünf Werte einen
# Unterschied gezeigt; der Spielraum für draw und vram ist also Vorsicht,
# kein beobachtetes Rauschen.
RAHMEN = {"draw": 2.0, "objekte": 0.0, "primitive": 0.0, "vram_mb": 0.5, "knoten": 0.0}
SPALTEN = (("draw", "draw", 5), ("objekte", "obj", 5), ("primitive", "prim", 7),
           ("vram_mb", "vram", 5), ("knoten", "knoten", 6))


def werte(ordner: Path) -> dict[str, dict[str, str]]:
    datei = ordner / "werte.tsv"
    if not datei.is_file():
        return {}
    with datei.open(newline="", encoding="utf-8") as f:
        return {z["bild"]: z for z in csv.DictReader(f, delimiter="\t")}


def zahl(zeile: dict[str, str] | None, spalte: str) -> float | None:
    try:
        return float(zeile[spalte]) if zeile else None
    except (KeyError, ValueError):
        return None


def pixel(a_pfad: Path, b_pfad: Path) -> tuple[bool, float, str]:
    """(gleich, mittlere Abweichung, Text)."""
    a = Image.open(a_pfad).convert("RGB")
    b = Image.open(b_pfad).convert("RGB")
    if a.size != b.size:
        return False, 255.0, f"Größe {a.size[0]}x{a.size[1]} -> {b.size[0]}x{b.size[1]}"
    diff = ImageChops.difference(a, b)
    if diff.getbbox() is None:
        return True, 0.0, "gleich"
    mittel = sum(ImageStat.Stat(diff).mean) / 3
    r, g, bl = diff.split()
    staerkste = ImageChops.lighter(ImageChops.lighter(r, g), bl)
    anteil = 100.0 * (1.0 - staerkste.histogram()[0] / (a.size[0] * a.size[1]))
    return False, mittel, (f"abw {mittel:.4f} (max {staerkste.getextrema()[1]}, "
                           f"{anteil:.3f} % der Bildpunkte)")


ziel = Path(sys.argv[1])
kopf = False
for teil in sys.argv[2:]:
    v, j = ziel / "vorher" / teil, ziel / "jetzt" / teil
    if not (v.is_dir() and j.is_dir()):
        continue
    namen = sorted({p.name for p in v.glob("*.png")} | {p.name for p in j.glob("*.png")})
    if not namen:
        continue
    if not kopf:
        print("=== Gleichheit vorher -> jetzt ===")
        print(f"  {'teil':<9} {'bild':<28} " + " ".join(f"{k:>{b}} " for _, k, b in SPALTEN)
              + " bildpunkte")
        kopf = True
    wv, wj = werte(v), werte(j)
    gleich, groesste, im_rahmen = 0, 0.0, True
    for name in namen:
        pv, pj = v / name, j / name
        if not (pv.is_file() and pj.is_file()):
            print(f"  {teil:<9} {name:<28} fehlt {'vorher' if not pv.is_file() else 'jetzt'}")
            im_rahmen = False
            continue
        felder = []
        for spalte, _, breite in SPALTEN:
            a, b = zahl(wv.get(name), spalte), zahl(wj.get(name), spalte)
            if a is None or b is None:
                felder.append(f"{'-':>{breite}}!")
                im_rahmen = False
                continue
            d = b - a
            # "!" hinter dem Wert: außerhalb des Rahmens
            drin = abs(d) <= RAHMEN[spalte] + 1e-6
            im_rahmen = im_rahmen and drin
            felder.append((f"{d:>+{breite}.1f}" if spalte == "vram_mb" else f"{round(d):>+{breite}d}")
                          + (" " if drin else "!"))
        ist_gleich, mittel, text = pixel(pv, pj)
        gleich += ist_gleich
        groesste = max(groesste, mittel)
        print(f"  {teil:<9} {name:<28} " + " ".join(felder) + f" {text}")
    print(f"  -> {teil}: {gleich} von {len(namen)} Bildern pixelgleich"
          + ("" if gleich == len(namen) else f", größte mittlere Abweichung {groesste:.4f}")
          + "; Kosten " + ("im Rahmen" if im_rahmen else "AUSSERHALB des Rahmens")
          + " (draw ±2, obj/prim/knoten gleich, vram ±0,5 MB)")
PYTHON
fi

echo "=== Schaufenster $SEITE fertig in $((SECONDS - START)) s: $SEITENORDNER ==="
exit "$FEHLT"
}
