#!/usr/bin/env python3
"""Lichtprobe: Richtung jedes Richtungslichts in jeder Szene.

    python3 werkzeuge/lichtprobe.py [projektordner]

Liest alle `.tscn` und druckt für jedes `DirectionalLight3D` die Richtung,
in die das Licht läuft (`-basis.z`), seine Höhe über dem Horizont, den
Azimut der Quelle und die Energie:

    scenes/levels/Level11.tscn   Sonne   licht (+0.69,-0.53,-0.49)  hoch 32°  aus -55°  E 1.0

Höhe: positiv = Licht von oben. Azimut: Richtung ZUR Quelle in der
Waagerechten, 0° = +Z (hinter der Kamera, solange der Weg nach -Z läuft),
90° = +X (rechts davon).

WARUM ES DAS GIBT. `.tscn` speichert eine `Transform3D` zeilenweise:
`Transform3D(a, b, c, d, e, f, g, h, i, x, y, z)` sind die ZEILEN der
Basis, `basis.z` ist also `(c, f, i)`. Wer eine Drehung spaltenweise
abschreibt, bekommt die transponierte Basis – und eine Sonne, die von
unten scheint. Im Bild fällt das kaum auf: Der Weg liegt dann nur im
Umgebungslicht, und die Schatten landen an den Unterseiten. So standen
Level 01 bis 25 fast alle eine Weile (ARCHITEKTUR.md, „Sonnen prüfen").

Rückgabe 1, sobald ein Licht MIT Schatten von unten kommt. Aufhelllichter
von unten ohne Schatten (gegen schwarze Unterseiten) sind erlaubt – ein
schattenwerfendes Licht von unten ist es nie: Es legt seine Schatten an
die Decken, nicht auf den Weg. Lichter, die erst ein Skript baut
(`splash_kulisse.gd`, `optionen.gd`, `level01/stimmung.gd`), sieht die
Probe nicht.
"""

from __future__ import annotations

import math
import os
import re
import sys

# Der Rumpf eines Knotens endet vor der nächsten Zeile, die mit „[" beginnt.
# Das erste Zeichen einer Rumpfzeile darf kein Zeilenumbruch sein: Sonst
# frisst `.*` nach einer Leerzeile den nächsten Kopf mit, und der Rumpf läuft
# bis ans Dateiende – die Probe sähe nur das erste Licht jeder Szene.
KNOTEN = re.compile(
    r'\[node name="([^"]+)" type="DirectionalLight3D"[^\]]*\]\n'
    r'((?:[^\[\n][^\n]*\n|\n)*)')


def lichter(text: str):
    """(name, richtung, energie, schatten) je Richtungslicht der Szene."""
    for treffer in KNOTEN.finditer(text):
        name, rumpf = treffer.group(1), treffer.group(2)
        form = re.search(r"transform = Transform3D\(([^)]*)\)", rumpf)
        if form is None:
            richtung = (0.0, 0.0, -1.0)
        else:
            v = [float(x) for x in form.group(1).split(",")]
            richtung = (-v[2], -v[5], -v[8])
        laenge = math.sqrt(sum(c * c for c in richtung)) or 1.0
        richtung = tuple(c / laenge for c in richtung)
        energie = re.search(r"light_energy = ([-0-9.e]+)", rumpf)
        schatten = re.search(r"shadow_enabled = true", rumpf) is not None
        yield name, richtung, float(energie.group(1)) if energie else 1.0, schatten


def main() -> int:
    wurzel = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else
                             os.path.join(os.path.dirname(__file__), ".."))
    falsch = 0
    for ordner, unter, dateien in os.walk(wurzel):
        unter[:] = sorted(u for u in unter if not u.startswith("."))
        for datei in sorted(dateien):
            if not datei.endswith(".tscn"):
                continue
            pfad = os.path.join(ordner, datei)
            with open(pfad, encoding="utf-8") as f:
                text = f.read()
            for name, d, energie, schatten in lichter(text):
                hoehe = math.degrees(math.asin(max(-1.0, min(1.0, -d[1]))))
                azimut = math.degrees(math.atan2(-d[0], -d[2]))
                hinweis = ""
                if d[1] >= 0.0:
                    hinweis = "  VON UNTEN" + (" (mit Schatten)" if schatten else "")
                    if schatten:
                        falsch += 1
                print("%-34s %-12s licht (%+.2f,%+.2f,%+.2f)  hoch %3.0f°  aus %+4.0f°  E %s%s" % (
                    os.path.relpath(pfad, wurzel), name, d[0], d[1], d[2],
                    hoehe, azimut, ("%g" % energie), hinweis))
    print("%d schattenwerfende Lichter von unten" % falsch)
    return 1 if falsch else 0


if __name__ == "__main__":
    sys.exit(main())
