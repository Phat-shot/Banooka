#!/usr/bin/env python3
"""Hebt Clips einer glTF-Figur auf die Sohlenebene.

Nach assets/modelle/LIESMICH.md liegt der Ursprung einer Figur unter der
Fußsohle: y = 0 ist der Boden. Hält sich ein Clip nicht daran, verschwindet
die Figur beim Abspielen ein Stück im Boden – beim Krabbeln fiel das auf.

Gemessen wird der tiefste Knochen über den ganzen Clip hinweg (Vorwärts-
kinematik über das Skelett, dicht abgetastet). Liegt er unter null, wird
die Verschiebespur der Hüfte um genau diesen Betrag angehoben. Clips, die
ohnehin über dem Boden bleiben (Sitzen, Reiten), bleiben unberührt.

    python3 werkzeuge/clips_richten.py assets/modelle/cash_banooka_rc.glb
"""
import json
import struct
import array
import math
import sys

ABTASTUNG = 64   # so viele Stellen je Clip
SCHWELLE = 0.002  # darunter lohnt das Anheben nicht


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
        return a, c, sz, k, bv.get("byteOffset", 0) + a.get("byteOffset", 0)

    def lese(i):
        a, c, sz, k, s = spanne(i)
        arr = array.array(c)
        arr.frombytes(bytes(bin_[s:s + a["count"] * k * sz]))
        return [list(arr[j * k:(j + 1) * k]) for j in range(a["count"])]

    def schreibe(i, werte):
        a, c, sz, k, s = spanne(i)
        arr = array.array(c, [w for v in werte for w in v])
        bin_[s:s + len(arr) * sz] = arr.tobytes()
        a["min"] = [min(v[j] for v in werte) for j in range(k)]
        a["max"] = [max(v[j] for v in werte) for j in range(k)]

    nodes = js["nodes"]
    eltern = {}
    for i, n in enumerate(nodes):
        for k in n.get("children", []):
            eltern[k] = i
    joints = js["skins"][0]["joints"]

    def matrix(t, q, s):
        x, y, z, w = q
        m = [1 - 2 * (y * y + z * z), 2 * (x * y + z * w), 2 * (x * z - y * w), 0,
             2 * (x * y - z * w), 1 - 2 * (x * x + z * z), 2 * (y * z + x * w), 0,
             2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x * x + y * y), 0,
             0, 0, 0, 1]
        for c in range(3):
            for r in range(3):
                m[c * 4 + r] *= s[c]
        m[12], m[13], m[14] = t
        return m

    def mul(a, b):
        r = [0.0] * 16
        for c in range(4):
            for z in range(4):
                r[c * 4 + z] = sum(a[k * 4 + z] * b[c * 4 + k] for k in range(4))
        return r

    def probe(werte, zeiten, t, art):
        """Wert einer Spur zur Zeit t. Schritt oder linear, mehr braucht es nicht."""
        if t <= zeiten[0]:
            return list(werte[0])
        if t >= zeiten[-1]:
            return list(werte[-1])
        i = 0
        while i + 1 < len(zeiten) and zeiten[i + 1] < t:
            i += 1
        if art == "STEP":
            return list(werte[i])
        f = (t - zeiten[i]) / max(zeiten[i + 1] - zeiten[i], 1e-9)
        a, b = werte[i], werte[i + 1]
        if len(a) == 4:  # Drehung: kurzer Weg, danach normieren
            if sum(a[j] * b[j] for j in range(4)) < 0.0:
                b = [-v for v in b]
            v = [a[j] + (b[j] - a[j]) * f for j in range(4)]
            laenge = math.sqrt(sum(c * c for c in v)) or 1.0
            return [c / laenge for c in v]
        return [a[j] + (b[j] - a[j]) * f for j in range(len(a))]

    gehoben = 0
    for anim in js.get("animations", []):
        name = anim.get("name", "?")
        spuren = {}
        dauer = 0.0
        for kanal in anim["channels"]:
            ziel = kanal["target"]
            if "node" not in ziel:
                continue
            probe_ = anim["samplers"][kanal["sampler"]]
            zeiten = [z[0] for z in lese(probe_["input"])]
            werte = lese(probe_["output"])
            art = probe_.get("interpolation", "LINEAR")
            spuren[(ziel["node"], ziel["path"])] = (zeiten, werte, art)
            dauer = max(dauer, zeiten[-1] if zeiten else 0.0)
        if not spuren:
            continue

        tiefste = None
        wo = ""
        for i in range(ABTASTUNG + 1):
            t = dauer * i / ABTASTUNG
            welt = {}

            def global_von(ni):
                if ni in welt:
                    return welt[ni]
                n = nodes[ni]
                tr = spuren.get((ni, "translation"))
                ro = spuren.get((ni, "rotation"))
                sc = spuren.get((ni, "scale"))
                pos = probe(tr[1], tr[0], t, tr[2]) if tr else n.get("translation", [0, 0, 0])
                dre = probe(ro[1], ro[0], t, ro[2]) if ro else n.get("rotation", [0, 0, 0, 1])
                ska = probe(sc[1], sc[0], t, sc[2]) if sc else n.get("scale", [1, 1, 1])
                m = matrix(pos, dre, ska)
                if ni in eltern:
                    m = mul(global_von(eltern[ni]), m)
                welt[ni] = m
                return m

            for ni in joints:
                y = global_von(ni)[13]
                if tiefste is None or y < tiefste:
                    tiefste = y
                    wo = nodes[ni].get("name")

        if tiefste is None or tiefste >= -SCHWELLE:
            print("  %-10s tiefster Knochen %+.3f m (%s) – bleibt" % (name, tiefste or 0.0, wo))
            continue

        # Hüfte anheben. Hat sie keine eigene Verschiebespur, bekommt sie eine
        # über den Ruhewert, sonst wäre der Clip nicht zu erreichen.
        wurzel = joints[0]
        hub = -tiefste
        spur = spuren.get((wurzel, "translation"))
        if spur is None:
            nodes[wurzel].setdefault("translation", [0.0, 0.0, 0.0])
            nodes[wurzel]["translation"][1] += hub
            print("  %-10s tiefster Knochen %+.3f m (%s) -> Ruhelage um %.3f m gehoben"
                  % (name, tiefste, wo, hub))
        else:
            for kanal in anim["channels"]:
                z = kanal["target"]
                if z.get("node") == wurzel and z.get("path") == "translation":
                    aus = anim["samplers"][kanal["sampler"]]["output"]
                    werte = lese(aus)
                    for v in werte:
                        v[1] += hub
                    schreibe(aus, werte)
            print("  %-10s tiefster Knochen %+.3f m (%s) -> Spur um %.3f m gehoben"
                  % (name, tiefste, wo, hub))
        gehoben += 1

    if gehoben:
        sichern(pfad, js, bin_)
    print("%d Clips angehoben" % gehoben)
    return gehoben


if __name__ == "__main__":
    richten(sys.argv[1] if len(sys.argv) > 1
            else "assets/modelle/cash_banooka_rc.glb")
