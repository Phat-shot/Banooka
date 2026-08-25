#!/usr/bin/env python3
"""Bindet verirrte Hautgewichte einer glTF-Figur an den richtigen Knochen.

Beim Erzeugen von cash_banooka_rc.glb sind Gewichte an fremde Knochen
geraten. Das fällt im Standbild nicht auf, reißt aber in Bewegung lange
Zipfel durch das Bild. Zwei Fälle werden erkannt:

1. Sohle an der Hand: Die äußeren Sohlenkanten hingen mit Gewicht 1,00 an
   Hand_L bzw. Hand_R. Beim Armschwung riss es die Sohle bis zur Hand
   hinauf – im Bild eine schwarze Platte vom Fuß bis über den Kopf.
   Umgebunden wird jedes Handgewicht unterhalb der Knöchel; die Seite
   ergibt sich aus dem Vorzeichen von x.

2. Arm am Bein: Am rechten Unterarm hingen zwei Punkte an UpperLeg_R,
   weil im Ruhestand der Arm dicht neben dem Oberschenkel liegt. Beim
   Sprung blieben sie an der Hüfte, während die Nachbarn mit dem Arm
   hochgingen – ein dünner Faden quer durchs Bild. Verglichen wird nur
   Arm gegen Bein: Die beiden berühren einander an dieser Figur nirgends,
   also ist jede Beinbindung inmitten von Armgewicht (und umgekehrt) ein
   Fehler. Rumpfknochen bleiben unangetastet, ihre Übergänge zu Arm und
   Bein sind gewollt.

    python3 werkzeuge/gewichte_richten.py assets/modelle/cash_banooka_rc.glb
"""
import json
import struct
import array
import sys

GRENZE = 0.25  # Höhe, unter der ein Punkt zum Fuß gehört (Knöchel bei ~0,14 m)

ARM = ("Shoulder", "UpperArm", "LowerArm", "Hand")
BEIN = ("UpperLeg", "LowerLeg", "Foot")


def gliedmass(knochen):
    """Arm, Bein oder Rumpf – gröber als der Knochen, aber genau genug."""
    if knochen.startswith(ARM):
        return "Arm"
    if knochen.startswith(BEIN):
        return "Bein"
    return "Rumpf"


def laden(pfad):
    d = open(pfad, 'rb').read()
    jlen = struct.unpack('<I', d[12:16])[0]
    js = json.loads(d[20:20 + jlen].decode('utf-8'))
    boff = 20 + jlen
    blen = struct.unpack('<I', d[boff:boff + 4])[0]
    return js, bytearray(d[boff + 8:boff + 8 + blen])


def sichern(pfad, js, bin_):
    kopf = json.dumps(js, separators=(',', ':')).encode('utf-8')
    kopf += b' ' * ((4 - len(kopf) % 4) % 4)
    rumpf = bytes(bin_) + b'\x00' * ((4 - len(bin_) % 4) % 4)
    open(pfad, 'wb').write(
        b'glTF' + struct.pack('<II', 2, 12 + 8 + len(kopf) + 8 + len(rumpf))
        + struct.pack('<I', len(kopf)) + b'JSON' + kopf
        + struct.pack('<I', len(rumpf)) + b'BIN\x00' + rumpf)


TYP = {5121: ('B', 1), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}
KOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def richten(pfad):
    js, bin_ = laden(pfad)

    def spanne(i):
        a = js["accessors"][i]
        bv = js["bufferViews"][a["bufferView"]]
        c, sz = TYP[a["componentType"]]
        k = KOMP[a["type"]]
        s = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        return a, c, sz, k, s

    def lese(i):
        a, c, sz, k, s = spanne(i)
        arr = array.array(c)
        arr.frombytes(bytes(bin_[s:s + a["count"] * k * sz]))
        return [list(arr[j * k:(j + 1) * k]) for j in range(a["count"])]

    def schreibe(i, werte):
        a, c, sz, k, s = spanne(i)
        arr = array.array(c, [w for v in werte for w in v])
        bin_[s:s + len(arr) * sz] = arr.tobytes()

    joints = js["skins"][0]["joints"]
    namen = [js["nodes"][i].get("name") for i in joints]
    idx = {n: i for i, n in enumerate(namen)}
    mats = [m.get("name") for m in js["materials"]]

    # Jede JOINTS_0-Sicht nur einmal anfassen, auch wenn sie geteilt wäre.
    erledigt = set()
    gesamt = 0
    for pr in js["meshes"][0]["primitives"]:
        aj = pr["attributes"]["JOINTS_0"]
        if aj in erledigt:
            continue
        erledigt.add(aj)
        P = lese(pr["attributes"]["POSITION"])
        J = lese(aj)
        W = lese(pr["attributes"]["WEIGHTS_0"])
        I = [v[0] for v in lese(pr["indices"])]

        sohlen = 0
        for n in range(len(P)):
            if P[n][1] >= GRENZE:
                continue
            for b in range(len(J[n])):
                if not namen[J[n][b]].startswith("Hand_"):
                    continue
                J[n][b] = idx["Foot_L" if P[n][0] > 0.0 else "Foot_R"]
                sohlen += 1

        # Netznachbarn über die Dreiecksliste. Punkte auf derselben Stelle
        # gelten als derselbe Punkt, sonst zerfällt das Netz an den UV-Nähten
        # in Inseln und jede Insel wäre ihr eigener Nachbar.
        ort = {}
        for n in range(len(P)):
            ort.setdefault(tuple(round(c, 4) for c in P[n]), []).append(n)
        gleiche = [ort[tuple(round(c, 4) for c in P[n])] for n in range(len(P))]
        nachbar = [set() for _ in P]
        for t in range(0, len(I), 3):
            ecken = I[t:t + 3]
            for a in ecken:
                for b in ecken:
                    if a != b:
                        nachbar[a].add(b)
        for n in range(len(P)):
            for m in list(gleiche[n]):
                nachbar[n] |= nachbar[m]

        ausreisser = 0
        ANTEIL = 0.25  # so wenig darf das eigene Gliedmaß rundum noch wiegen
        for n in range(len(P)):
            umfeld = {}
            for m in nachbar[n]:
                if m in gleiche[n]:
                    continue
                for j, w in zip(J[m], W[m]):
                    if w > 0.0:
                        umfeld[j] = umfeld.get(j, 0.0) + w
            if not umfeld:
                continue
            waage = {"Arm": 0.0, "Bein": 0.0}
            for j, w in umfeld.items():
                g = gliedmass(namen[j])
                if g in waage:
                    waage[g] += w
            zusammen = waage["Arm"] + waage["Bein"]
            if zusammen <= 0.0:
                continue
            for b in range(len(J[n])):
                if W[n][b] <= 0.0:
                    continue
                g = gliedmass(namen[J[n][b]])
                if g not in waage or waage[g] / zusammen > ANTEIL:
                    continue
                andere = "Bein" if g == "Arm" else "Arm"
                ziel = max((j for j in umfeld if gliedmass(namen[j]) == andere),
                           key=lambda j: umfeld[j])
                print("     (%+.3f %+.3f %+.3f) %s -> %s"
                      % (P[n][0], P[n][1], P[n][2], namen[J[n][b]], namen[ziel]))
                J[n][b] = ziel
                ausreisser += 1

        if sohlen or ausreisser:
            schreibe(aj, J)
        gesamt += sohlen + ausreisser
        print("  %-14s %d Sohlengewichte von der Hand auf den Fuß, "
              "%d Gewichte vom falschen Gliedmaß umgebunden"
              % (mats[pr["material"]], sohlen, ausreisser))

    if gesamt:
        sichern(pfad, js, bin_)
    print("insgesamt %d Gewichte umgebunden" % gesamt)
    return gesamt


if __name__ == "__main__":
    richten(sys.argv[1] if len(sys.argv) > 1
            else "assets/modelle/cash_banooka_rc.glb")
