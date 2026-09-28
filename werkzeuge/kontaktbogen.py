#!/usr/bin/env python3
"""Kontaktbogen: legt Bildschirmfotos als Raster auf ein PNG – einzeln
oder als Vorher/Nachher-Gegenüberstellung.

Gedacht für die Bilder aus werkzeuge/foto.sh und werkzeuge/schaufenster.sh.
Ein Blick auf EIN Bild ersetzt zehn einzelne, und Vorher/Nachher liegen
Zeile für Zeile nebeneinander, statt dass man zwischen Dateien hin- und
herblättert und Unterschiede aus dem Gedächtnis vergleicht.

Braucht Pillow. Ist es nicht installiert, geht es ohne Installation über uv:

    uvx --with pillow python werkzeuge/kontaktbogen.py <ordner> [-o bogen.png]
    uvx --with pillow python werkzeuge/kontaktbogen.py \\
        --vergleich <vorher_ordner> <jetzt_ordner> [-o vergleich.png] [--diff]

Einzelbogen:   alle PNGs des Ordners (alphabetisch) im Raster. Vorgabe für
               die Ausgabe ist `<ordner>.png` NEBEN dem Ordner – im Ordner
               selbst würde der nächste Lauf den Bogen mit einlesen.
Vergleich:     je Bildname eine Zeile [vorher | jetzt] (mit --diff dazu
               |jetzt - vorher| × 4). Bilder, die nur auf einer Seite
               existieren, bekommen ein graues Feld "fehlt". Vorgabe für die
               Ausgabe ist `vergleich.png` im aktuellen Verzeichnis.

Beschriftung je Kachel:
  Zeile 1  Dateiname und – wenn im Ordner eine `werte.tsv` von foto.gd
           liegt (FOTO_WERTE) – die Kosten: Draw-Calls und Primitive; im Vergleich mit Differenz zu vorher.
  Zeile 2  Farbwerte des Bildes:
           hell   mittlere Luma, 0 (schwarz) bis 255 (weiß)
           warm   Anteil kräftiger Pixel mit Farbton 330°–60° (Rot bis Gelb)
           kühl   Anteil kräftiger Pixel mit Farbton 180°–260° (Cyan bis Blau)
           "kräftig" heißt Sättigung >= 25 % und Helligkeit >= 15 %; graue
           und fast schwarze Pixel zählen zu keiner Seite. Diese Definition
           ist hier festgelegt – ältere Tabellen in doku/ können anders
           gerechnet sein.
Dieselben Zahlen stehen als Tabelle auf der Standardausgabe, damit Agenten
sie ohne Bildbetrachter vergleichen können.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat
except ImportError:  # pragma: no cover – Hinweis statt Stacktrace
    sys.exit("ABBRUCH: Pillow fehlt. Aufruf: uvx --with pillow python "
             + " ".join(sys.argv))

BESCHRIFTUNG = 40          # Höhe des Textbands unter jeder Kachel (Pixel)
RAND = 6                   # Abstand zwischen den Kacheln
HINTERGRUND = (24, 24, 28)
SCHRIFTFARBE = (235, 235, 235)
BLASS = (160, 160, 170)


def schrift(groesse: int) -> ImageFont.ImageFont:
    """DejaVu, wenn vorhanden (hat Umlaute), sonst Pillows eingebaute."""
    for pfad in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                 "/Library/Fonts/Arial.ttf", "C:/Windows/Fonts/arial.ttf"):
        try:
            return ImageFont.truetype(pfad, groesse)
        except OSError:
            pass
    try:
        return ImageFont.load_default(size=groesse)
    except TypeError:  # Pillow < 10.1 kennt keine Größe
        return ImageFont.load_default()


def lies_werte(ordner: Path) -> dict[str, dict[str, str]]:
    """werte.tsv von foto.gd (FOTO_WERTE) als {bild: {spalte: wert}}."""
    datei = ordner / "werte.tsv"
    if not datei.is_file():
        return {}
    with datei.open(newline="", encoding="utf-8") as f:
        # Mehrere Läufe hängen an dieselbe Datei an; der letzte gilt.
        return {z["bild"]: z for z in csv.DictReader(f, delimiter="\t")
                if z.get("bild")}


def farbwerte(bild: Image.Image) -> tuple[float, float, float]:
    """(hell 0–255, warm %, kühl %) – Definition im Dateikopf."""
    klein = bild.convert("RGB").resize((320, 180))
    hell = ImageStat.Stat(klein.convert("L")).mean[0]
    h, s, v = klein.convert("HSV").split()
    # Pillow bildet 0–360° auf 0–255 ab: 60° = 42,5 · 180° = 127,5 ·
    # 260° = 184,2 · 330° = 233,75.
    kraeftig = ImageChops.multiply(
        s.point(lambda x: 255 if x >= 64 else 0),
        v.point(lambda x: 255 if x >= 38 else 0))
    warm_h = h.point(lambda x: 255 if (x < 43 or x >= 234) else 0)
    kuehl_h = h.point(lambda x: 255 if 128 <= x <= 184 else 0)
    warm = ImageStat.Stat(ImageChops.multiply(warm_h, kraeftig)).mean[0] / 2.55
    kuehl = ImageStat.Stat(ImageChops.multiply(kuehl_h, kraeftig)).mean[0] / 2.55
    return hell, warm, kuehl


def kosten_text(w: dict[str, str] | None, vorher: dict[str, str] | None = None) -> str:
    """Draw-Calls (im Vergleich mit Differenz zu vorher) und Primitive."""
    if not w:
        return ""
    try:
        draw = int(w["draw"])
        delta = f" ({draw - int(vorher['draw']):+d})" if vorher else ""
        return f"draw {draw}{delta} · prim {round(int(w['primitive']) / 1000)}k"
    except (KeyError, ValueError):
        return ""


def kachel(pfad: Path | None, breite: int, zeile1: str, schrift_klein,
           bild: Image.Image | None = None,
           zeile2: str | None = None) -> tuple[Image.Image, tuple[float, float, float] | None]:
    """Eine beschriftete Kachel. `bild` ersetzt das Laden (für die Differenz),
    `zeile2` die Farbwerte – die sagen über ein Differenzbild nichts."""
    hoehe = breite * 9 // 16
    feld = Image.new("RGB", (breite, hoehe + BESCHRIFTUNG), HINTERGRUND)
    zeichner = ImageDraw.Draw(feld)
    werte = None
    if bild is None and pfad is not None and pfad.is_file():
        bild = Image.open(pfad).convert("RGB")
    if bild is not None:
        feld.paste(bild.resize((breite, hoehe), Image.LANCZOS), (0, 0))
        if zeile2 is None:
            werte = farbwerte(bild)
            zeile2 = f"hell {werte[0]:.0f} · warm {werte[1]:.1f} % · kühl {werte[2]:.1f} %"
    else:
        zeichner.rectangle((0, 0, breite - 1, hoehe - 1), fill=(60, 60, 66))
        zeichner.text((breite // 2, hoehe // 2), "fehlt", fill=BLASS,
                      font=schrift_klein, anchor="mm")
        zeile2 = ""
    zeichner.text((6, hoehe + 3), zeile1, fill=SCHRIFTFARBE, font=schrift_klein)
    zeichner.text((6, hoehe + 21), zeile2, fill=BLASS, font=schrift_klein)
    return feld, werte


def raster(kacheln: list[Image.Image], spalten: int, titel: str) -> Image.Image:
    kb, kh = kacheln[0].size
    zeilen = (len(kacheln) + spalten - 1) // spalten
    kopf = 34
    bogen = Image.new("RGB", (spalten * kb + (spalten + 1) * RAND,
                              kopf + zeilen * kh + (zeilen + 1) * RAND), HINTERGRUND)
    ImageDraw.Draw(bogen).text((RAND + 2, 8), titel, fill=SCHRIFTFARBE, font=schrift(18))
    for i, k in enumerate(kacheln):
        x = RAND + (i % spalten) * (kb + RAND)
        y = kopf + RAND + (i // spalten) * (kh + RAND)
        bogen.paste(k, (x, y))
    return bogen


def kurz(ordner: Path) -> str:
    """Die letzten zwei Pfadteile ("vorher/l01") – volle Scratch-Pfade
    sprengten die Titelzeile."""
    teile = ordner.resolve().parts
    return "/".join(teile[-2:])


def pngs(ordner: Path) -> list[Path]:
    return sorted(p for p in ordner.glob("*.png") if p.is_file())


def einzelbogen(ordner: Path, ausgabe: Path, spalten: int, breite: int) -> int:
    bilder = pngs(ordner)
    if not bilder:
        print(f"HINWEIS: keine PNGs in {ordner}")
        return 1
    werte = lies_werte(ordner)
    klein = schrift(14)
    kacheln = []
    print(f"{'bild':<28} {'draw':>6} {'prim':>8} {'hell':>5} {'warm':>6} {'kühl':>6}")
    for p in bilder:
        w = werte.get(p.name)
        k, f = kachel(p, breite, f"{p.name}  {kosten_text(w)}", klein)
        kacheln.append(k)
        draw = w["draw"] if w else "-"
        prim = f"{round(int(w['primitive']) / 1000)}k" if w else "-"
        print(f"{p.name:<28} {draw:>6} {prim:>8} {f[0]:>5.0f} {f[1]:>6.1f} {f[2]:>6.1f}")
    raster(kacheln, min(spalten, len(kacheln)),
           f"{kurz(ordner)}  ({len(bilder)} Bilder)").save(ausgabe)
    print(f"  Kontaktbogen: {ausgabe}")
    return 0


def vergleich(vorher: Path, jetzt: Path, ausgabe: Path, breite: int, mit_diff: bool) -> int:
    namen = sorted({p.name for p in pngs(vorher)} | {p.name for p in pngs(jetzt)})
    if not namen:
        print(f"HINWEIS: keine PNGs in {vorher} oder {jetzt}")
        return 1
    werte_v, werte_j = lies_werte(vorher), lies_werte(jetzt)
    klein = schrift(14)
    kacheln = []
    print(f"{'bild':<28} {'draw vorher':>11} {'jetzt':>6} {'hell vorher':>11} {'jetzt':>6} {'abw':>5}")
    for name in namen:
        pv, pj = vorher / name, jetzt / name
        wv, wj = werte_v.get(name), werte_j.get(name)
        kv, fv = kachel(pv, breite, f"vorher  {name}  {kosten_text(wv)}", klein)
        kj, fj = kachel(pj, breite, f"jetzt  {kosten_text(wj, wv)}", klein)
        kacheln += [kv, kj]
        abw = "-"
        if mit_diff:
            diff = None
            if pv.is_file() and pj.is_file():
                a = Image.open(pv).convert("RGB")
                b = Image.open(pj).convert("RGB").resize(a.size)
                roh = ImageChops.difference(a, b)
                abw = f"{sum(ImageStat.Stat(roh).mean) / 3:.1f}"
                diff = roh.point(lambda x: min(255, x * 4))
            kd, _ = kachel(None, breite, "|jetzt - vorher| × 4", klein, diff,
                           f"mittlere Abweichung {abw} (0–255)")
            kacheln.append(kd)
        print(f"{name:<28} {(wv or {}).get('draw', '-'):>11} {(wj or {}).get('draw', '-'):>6} "
              f"{(f'{fv[0]:.0f}' if fv else '-'):>11} {(f'{fj[0]:.0f}' if fj else '-'):>6} {abw:>5}")
    spalten = 3 if mit_diff else 2
    raster(kacheln, spalten, f"{kurz(vorher)}  gegen  {kurz(jetzt)}").save(ausgabe)
    print(f"  Vergleichsbogen: {ausgabe}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("ordner", nargs="*", type=Path,
                    help="ein Ordner (Einzelbogen) oder mit --vergleich: vorher jetzt")
    ap.add_argument("--vergleich", action="store_true",
                    help="zwei Ordner Zeile für Zeile gegenüberstellen")
    ap.add_argument("--diff", action="store_true",
                    help="im Vergleich eine dritte Spalte |jetzt - vorher| × 4")
    ap.add_argument("-o", "--ausgabe", type=Path, help="Ziel-PNG")
    ap.add_argument("--spalten", type=int, default=2, help="Einzelbogen: Spalten (Vorgabe 2)")
    ap.add_argument("--breite", type=int, default=640, help="Kachelbreite in Pixeln (Vorgabe 640)")
    a = ap.parse_args()
    if a.vergleich:
        if len(a.ordner) != 2:
            ap.error("--vergleich braucht genau zwei Ordner: vorher jetzt")
        return vergleich(a.ordner[0], a.ordner[1], a.ausgabe or Path("vergleich.png"),
                         a.breite, a.diff)
    if len(a.ordner) != 1:
        ap.error("genau einen Ordner angeben (oder --vergleich vorher jetzt)")
    ordner = a.ordner[0].resolve()
    return einzelbogen(ordner, a.ausgabe or ordner.parent / (ordner.name + ".png"), a.spalten, a.breite)


if __name__ == "__main__":
    sys.exit(main())
