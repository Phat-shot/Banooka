#!/usr/bin/env python3
"""Baut einer glTF-Figur neue Animationsclips aus beschriebenen Posen.

Der Grund für dieses Werkzeug: Wir brauchen Clips, die unsere Figur noch
nicht mitbringt (Hangeln und seine zwei Abwandlungen). Von Hand
Quaternionen zu schreiben ist aussichtslos – niemand sieht einer Zahlen-
folge an, ob ein Arm nach oben zeigt.

Deshalb wird eine Pose hier als **Zielrichtung je Knochen** beschrieben:
"Der Oberarm soll auf seinen Nachfolger hin nach oben zeigen." Das Werkzeug
rechnet daraus die lokale Drehung aus.

    knochen -> Richtung im Modellraum, in die der Knochen auf sein Kind
               zeigen soll. +Y ist oben, +Z ist vorn (die Figur schaut
               nach +Z, siehe assets/modelle/LIESMICH.md), +X ist links.

Knochen ohne Kind im Skelett (Kopf, Hände, Füße) haben keine Richtung, die
sich zeigen ließe; sie bekommen stattdessen einen Euler-Zuschlag in Grad
auf ihre Ruhedrehung.

    python3 werkzeuge/clip_bauen.py assets/modelle/cash_banooka_rc.glb
"""
import json
import math
import struct
import array
import sys


# ---------------------------------------------------------------- Datei

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


# ------------------------------------------------------------ Rechnerei

def norm(v):
    laenge = math.sqrt(sum(c * c for c in v))
    if laenge < 1e-9:
        return [0.0, 1.0, 0.0]
    return [c / laenge for c in v]


def kreuz(a, b):
    return [a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0]]


def punktprodukt(a, b):
    return sum(a[i] * b[i] for i in range(3))


def quat_mal(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz]


def quat_norm(q):
    laenge = math.sqrt(sum(c * c for c in q))
    return [c / laenge for c in q] if laenge > 1e-9 else [0.0, 0.0, 0.0, 1.0]


def quat_inv(q):
    return [-q[0], -q[1], -q[2], q[3]]


def quat_dreh(v, q):
    """Dreht einen Vektor mit einem Quaternion."""
    qv = [q[0], q[1], q[2]]
    t = [2.0 * c for c in kreuz(qv, v)]
    return [v[i] + q[3] * t[i] + kreuz(qv, t)[i] for i in range(3)]


def quat_von_nach(von, nach):
    """Kürzeste Drehung, die `von` auf `nach` legt."""
    a, b = norm(von), norm(nach)
    d = punktprodukt(a, b)
    if d > 0.999999:
        return [0.0, 0.0, 0.0, 1.0]
    if d < -0.999999:
        # Gegenrichtung: irgendeine Achse quer dazu nehmen
        achse = kreuz(a, [1.0, 0.0, 0.0])
        if punktprodukt(achse, achse) < 1e-6:
            achse = kreuz(a, [0.0, 0.0, 1.0])
        achse = norm(achse)
        return [achse[0], achse[1], achse[2], 0.0]
    achse = kreuz(a, b)
    w = 1.0 + d
    return quat_norm([achse[0], achse[1], achse[2], w])


def quat_von_euler(grad):
    """Euler in Grad (X, dann Y, dann Z) als Quaternion."""
    qx = [math.sin(math.radians(grad[0]) / 2), 0.0, 0.0,
          math.cos(math.radians(grad[0]) / 2)]
    qy = [0.0, math.sin(math.radians(grad[1]) / 2), 0.0,
          math.cos(math.radians(grad[1]) / 2)]
    qz = [0.0, 0.0, math.sin(math.radians(grad[2]) / 2),
          math.cos(math.radians(grad[2]) / 2)]
    return quat_norm(quat_mal(quat_mal(qz, qy), qx))


# ------------------------------------------------------------- Skelett

class Skelett:
    """Knochenbaum einer glTF-Figur samt Ruhelage."""

    def __init__(self, js):
        self.js = js
        self.nodes = js["nodes"]
        self.joints = js["skins"][0]["joints"]
        self.name_zu_node = {}
        for ni in self.joints:
            self.name_zu_node[self.nodes[ni].get("name")] = ni
        self.eltern = {}
        for i, n in enumerate(self.nodes):
            for k in n.get("children", []):
                self.eltern[k] = i
        # Reihenfolge von oben nach unten, damit Eltern vor Kindern posiert
        # werden – anders ginge es nicht, weil die Zielrichtung im
        # Modellraum gilt und dafür die Elterndrehung bekannt sein muss.
        self.reihenfolge = sorted(self.joints, key=self._tiefe)
        self.kinder = {ni: [k for k in self.nodes[ni].get("children", [])
                            if k in self.joints] for ni in self.joints}

    def _tiefe(self, ni):
        t = 0
        while ni in self.eltern:
            ni = self.eltern[ni]
            t += 1
        return t

    def ruhe(self, ni):
        n = self.nodes[ni]
        return (list(n.get("translation", [0, 0, 0])),
                list(n.get("rotation", [0, 0, 0, 1])))


def pose_rechnen(sk, ziele, zuschlaege):
    """Rechnet eine Pose in lokale Drehungen je Knochen um.

    `ziele`      Knochenname -> Richtung im Modellraum, in die er auf sein
                 Kind zeigen soll.
    `zuschlaege` Knochenname -> Euler-Zuschlag in Grad auf die Ruhedrehung.

    Zurück kommt {Knochenname: Quaternion}. Knochen ohne Eintrag behalten
    ihre Ruhedrehung.
    """
    lokal = {}
    welt_drehung = {}
    for ni in sk.reihenfolge:
        name = sk.nodes[ni].get("name")
        _, ruhe_rot = sk.ruhe(ni)
        eltern_welt = welt_drehung.get(sk.eltern.get(ni), [0.0, 0.0, 0.0, 1.0])

        drehung = list(ruhe_rot)
        if name in ziele and sk.kinder[ni]:
            # Kind in Elternraum: Ruhedrehung mal Kindversatz.
            kind = sk.kinder[ni][0]
            kind_lokal = list(sk.nodes[kind].get("translation", [0, 0, 0]))
            richtung_ruhe = norm(kind_lokal)
            # Zielrichtung aus dem Modellraum in den Elternraum holen.
            ziel_eltern = quat_dreh(norm(ziele[name]), quat_inv(eltern_welt))
            drehung = quat_von_nach(richtung_ruhe, ziel_eltern)
        if name in zuschlaege:
            drehung = quat_norm(quat_mal(drehung, quat_von_euler(zuschlaege[name])))

        lokal[name] = drehung
        welt_drehung[ni] = quat_norm(quat_mal(eltern_welt, drehung))
    return lokal


# -------------------------------------------------------------- Schreiben

class Anhang:
    """Sammelt neue Puffersichten und Accessoren."""

    def __init__(self, js, bin_):
        self.js = js
        self.bin = bin_
        self.js.setdefault("animations", [])

    def _accessor(self, werte, typ, komponenten):
        # Auf 4 Byte ausrichten, sonst mag es mancher Lader nicht.
        while len(self.bin) % 4:
            self.bin.append(0)
        start = len(self.bin)
        arr = array.array('f', [w for v in werte for w in v])
        self.bin.extend(arr.tobytes())
        self.js["bufferViews"].append({
            "buffer": 0, "byteOffset": start, "byteLength": len(arr) * 4})
        self.js["accessors"].append({
            "bufferView": len(self.js["bufferViews"]) - 1,
            "componentType": 5126, "count": len(werte), "type": typ,
            "min": [min(v[i] for v in werte) for i in range(komponenten)],
            "max": [max(v[i] for v in werte) for i in range(komponenten)],
        })
        return len(self.js["accessors"]) - 1

    def zeiten(self, liste):
        return self._accessor([[t] for t in liste], "SCALAR", 1)

    def quats(self, liste):
        return self._accessor(liste, "VEC4", 4)

    def vec3(self, liste):
        return self._accessor(liste, "VEC3", 3)


def clip_schreiben(js, bin_, sk, name, dauer, bilder, hueft_versatz):
    """Schreibt einen Clip aus einer Folge von Posen.

    `bilder` ist eine Liste von (zeit, ziele, zuschlaege).
    `hueft_versatz` eine Liste von (zeit, [x, y, z]) auf die Ruhelage.
    """
    # Bestehenden Clip gleichen Namens entfernen, damit das Werkzeug
    # mehrfach laufen kann, ohne Karteileichen zu hinterlassen.
    js["animations"] = [a for a in js.get("animations", [])
                        if a.get("name") != name]

    anhang = Anhang(js, bin_)
    posen = [pose_rechnen(sk, ziele, zuschlaege)
             for (_, ziele, zuschlaege) in bilder]
    zeiten = [z for (z, _, _) in bilder]

    # Nur Knochen aufnehmen, die sich überhaupt bewegen – sonst bläht der
    # Clip die Datei mit lauter Ruhespuren auf.
    bewegt = set()
    for name_knochen in posen[0]:
        werte = [p[name_knochen] for p in posen]
        _, ruhe_rot = sk.ruhe(sk.name_zu_node[name_knochen])
        for w in werte:
            if any(abs(w[i] - ruhe_rot[i]) > 0.0005 for i in range(4)):
                bewegt.add(name_knochen)
                break

    kanaele = []
    sampler = []
    zeit_acc = anhang.zeiten(zeiten)
    for name_knochen in sorted(bewegt):
        werte = [posen[i][name_knochen] for i in range(len(posen))]
        # Kurzen Weg erzwingen: Zwei Nachbarbilder dürfen nicht durch die
        # Gegenhalbkugel laufen, sonst dreht sich ein Arm einmal ganz herum.
        for i in range(1, len(werte)):
            if sum(werte[i][j] * werte[i - 1][j] for j in range(4)) < 0.0:
                werte[i] = [-c for c in werte[i]]
        sampler.append({"input": zeit_acc,
                        "output": anhang.quats(werte),
                        "interpolation": "LINEAR"})
        kanaele.append({"sampler": len(sampler) - 1,
                        "target": {"node": sk.name_zu_node[name_knochen],
                                   "path": "rotation"}})

    if hueft_versatz:
        hueft_node = sk.joints[0]
        ruhe_t, _ = sk.ruhe(hueft_node)
        h_zeiten = [z for (z, _) in hueft_versatz]
        h_werte = [[ruhe_t[i] + v[i] for i in range(3)]
                   for (_, v) in hueft_versatz]
        sampler.append({"input": anhang.zeiten(h_zeiten),
                        "output": anhang.vec3(h_werte),
                        "interpolation": "LINEAR"})
        kanaele.append({"sampler": len(sampler) - 1,
                        "target": {"node": hueft_node, "path": "translation"}})

    js["animations"].append({"name": name, "channels": kanaele,
                             "samplers": sampler})
    return len(kanaele)


def puffer_nachziehen(js, bin_):
    js["buffers"][0]["byteLength"] = len(bin_)


# ------------------------------------------------- Unsere Hangel-Clips

## Die Figur schaut nach +Z, +Y ist oben, +X ist links (LIESMICH.md).
def _spiegel(v):
    return [-v[0], v[1], v[2]]


def hangen_ziele(schwung, beine_hoch=0.0, spreizen=0.0):
    """Grundhaltung am Gitter.

    `schwung`     -1..1, Pendeln der Beine nach vorn und hinten.
    `beine_hoch`  0..1, Knie zur Brust ziehen (das "Krabbeln" im Hängen).
    `spreizen`    0..1, Beine seitlich herausschleudern (Drehschlag).
    """
    arm_l = [0.30, 1.0, 0.02]
    unterarm_l = [0.10, 1.0, 0.0]
    schulter_l = [1.0, 0.34, 0.0]

    # Oberschenkel: hängend nach unten, angezogen nach vorn und oben.
    ober = [spreizen * 0.9, -1.0 + beine_hoch * 1.55,
            schwung * 0.30 + beine_hoch * 1.05]
    # Unterschenkel: hängend fast senkrecht. Angezogen klappt er nach
    # HINTEN UND OBEN – nur so kommen die Fersen zum Gesäß und es sieht
    # nach Anziehen aus statt nach Sitzen. Ein Unterschenkel, der beim
    # Anziehen weiter nach unten zeigt, ergibt eine Hockhaltung.
    unter = [spreizen * 0.5, -1.0 + beine_hoch * 1.45,
             -schwung * 0.18 - beine_hoch * 1.30]

    ziele = {
        "Hips": [0.0, 1.0, schwung * 0.06],
        "Spine": [0.0, 1.0, -schwung * 0.05],
        "Chest": [0.0, 1.0, 0.0],
        "Neck": [0.0, 1.0, 0.10],
        "Shoulder_L": schulter_l,
        "Shoulder_R": _spiegel(schulter_l),
        "UpperArm_L": arm_l,
        "UpperArm_R": _spiegel(arm_l),
        "LowerArm_L": unterarm_l,
        "LowerArm_R": _spiegel(unterarm_l),
        "UpperLeg_L": ober,
        "UpperLeg_R": _spiegel(ober),
        "LowerLeg_L": unter,
        "LowerLeg_R": _spiegel(unter),
    }
    return ziele


def hangen_zuschlaege(schwung, kopf_ab=0.0):
    return {
        "Head": [kopf_ab * 14.0, schwung * 10.0, 0.0],
        # Füße locker hängen lassen – gestreckte Spitzen lesen sich als
        # "hängt", angewinkelte als "steht".
        "Foot_L": [-26.0, 0.0, 0.0],
        "Foot_R": [-26.0, 0.0, 0.0],
    }


def clips_bauen(pfad):
    js, bin_ = laden(pfad)
    sk = Skelett(js)

    # --- Hang: ruhiges Pendeln, 1,4 s, Schleife -------------------------
    bilder = []
    hueften = []
    schritte = 8
    for i in range(schritte + 1):
        t = 1.4 * i / schritte
        s = math.sin(TAU * i / schritte)
        bilder.append((t, hangen_ziele(s), hangen_zuschlaege(s * 0.4)))
        # Die Hüfte so weit absenken, dass die Hände genau auf
        # Hangelgitter.GRIFF_HOEHE (1,55 m über den Sohlen) landen – dort
        # greift das Spiel den Griffpunkt ab. Ohne das griffe die Figur
        # sichtbar durch die Sprossen hindurch. Dazu ein leichtes Auf und
        # Ab, weil die Arme nachgeben.
        hueften.append((t, [0.0, GRIFF_ABSENKUNG - 0.02 * abs(s), 0.0]))
    n = clip_schreiben(js, bin_, sk, "Hang", 1.4, bilder, hueften)
    print("  Hang       %2d Spuren" % n)

    # --- HangDuck: Knie zur Brust, kurzes Wippen ------------------------
    bilder = []
    hueften = []
    schritte = 6
    for i in range(schritte + 1):
        t = 1.0 * i / schritte
        s = math.sin(TAU * i / schritte)
        hoch = 0.82 + 0.10 * s
        bilder.append((t, hangen_ziele(s * 0.25, beine_hoch=hoch),
                       hangen_zuschlaege(s * 0.2, kopf_ab=0.7)))
        hueften.append((t, [0.0, GRIFF_ABSENKUNG, 0.0]))
    n = clip_schreiben(js, bin_, sk, "HangDuck", 1.0, bilder, hueften)
    print("  HangDuck   %2d Spuren" % n)

    # --- HangSpin: Beine herausschleudern und herumziehen ---------------
    # Kein Rundumdrehen des ganzen Körpers: Wer sich mit den Händen
    # festhält, kann nicht um die eigene Achse kreiseln. Der Schlag kommt
    # aus den Beinen, die waagerecht herumgerissen werden.
    bilder = []
    hueften = []
    schritte = 8
    for i in range(schritte + 1):
        t = 0.4 * i / schritte
        w = TAU * i / schritte
        ziele = hangen_ziele(math.cos(w) * 0.9, beine_hoch=0.45,
                             spreizen=abs(math.sin(w)) * 1.0)
        # Hüfte mitdrehen, damit die Beine wirklich herumkommen.
        ziele["Hips"] = [math.sin(w) * 0.18, 1.0, math.cos(w) * 0.10]
        zuschlaege = hangen_zuschlaege(0.0)
        zuschlaege["Head"] = [0.0, math.sin(w) * 26.0, 0.0]
        bilder.append((t, ziele, zuschlaege))
        hueften.append((t, [math.sin(w) * 0.05, GRIFF_ABSENKUNG - 0.02, 0.0]))
    n = clip_schreiben(js, bin_, sk, "HangSpin", 0.4, bilder, hueften)
    print("  HangSpin   %2d Spuren" % n)

    puffer_nachziehen(js, bin_)
    sichern(pfad, js, bin_)
    return sk, js


TAU = math.pi * 2.0

## Wie weit die Hüfte gegenüber der Ruhelage sinkt, damit die Hände auf
## 1,55 m über den Sohlen zu liegen kommen. Ohne Absenkung landen sie bei
## 1,66 m und griffen 11 cm über der Sprosse ins Leere.
GRIFF_ABSENKUNG = -0.13


def nachmessen(sk, js, clipname, zeitanteil=0.0):
    """Rechnet eine Pose des Clips durch und meldet, wo die Glieder landen.

    Ohne das ist eine Pose nicht zu beurteilen: Ob die Hände über dem Kopf
    stehen, sieht man Quaternionen nicht an.
    """
    anim = [a for a in js["animations"] if a.get("name") == clipname][0]
    bin_ = sk._bin
    lokal = {}
    verschoben = {}
    for kanal in anim["channels"]:
        ziel = kanal["target"]
        s = anim["samplers"][kanal["sampler"]]
        name = sk.nodes[ziel["node"]].get("name")
        if ziel["path"] == "rotation":
            werte = _lese_vec(js, bin_, s["output"], 4)
            i = min(int(zeitanteil * (len(werte) - 1)), len(werte) - 1)
            lokal[name] = werte[i]
        elif ziel["path"] == "translation":
            # Die Verschiebespur MUSS mitgelesen werden: Die Hüfte trägt
            # den ganzen Körper, und genau über sie wird die Griffhöhe
            # eingestellt. Ohne sie misst die Probe an der Änderung vorbei.
            werte = _lese_vec(js, bin_, s["output"], 3)
            i = min(int(zeitanteil * (len(werte) - 1)), len(werte) - 1)
            verschoben[name] = werte[i]

    welt = {}
    for ni in sk.reihenfolge:
        name = sk.nodes[ni].get("name")
        t, r = sk.ruhe(ni)
        r = lokal.get(name, r)
        t = verschoben.get(name, t)
        eltern = sk.eltern.get(ni)
        if eltern in welt:
            ep, er = welt[eltern]
            pos = [ep[i] + quat_dreh(t, er)[i] for i in range(3)]
            rot = quat_norm(quat_mal(er, r))
        else:
            pos, rot = list(t), list(r)
        welt[ni] = (pos, rot)
    return {sk.nodes[ni].get("name"): welt[ni][0] for ni in sk.joints}


def _lese_vec(js, bin_, index, breite):
    a = js["accessors"][index]
    bv = js["bufferViews"][a["bufferView"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    arr = array.array('f')
    arr.frombytes(bytes(bin_[start:start + a["count"] * breite * 4]))
    return [list(arr[i * breite:(i + 1) * breite]) for i in range(a["count"])]


if __name__ == "__main__":
    ziel = sys.argv[1] if len(sys.argv) > 1 \
        else "assets/modelle/cash_banooka_rc.glb"
    print("=== Clips bauen in %s ===" % ziel)
    sk, js = clips_bauen(ziel)
    # Neu einlesen, um genau das zu messen, was in der Datei steht.
    js2, bin2 = laden(ziel)
    sk2 = Skelett(js2)
    sk2._bin = bin2
    for clip in ["Hang", "HangDuck", "HangSpin"]:
        orte = nachmessen(sk2, js2, clip, 0.0)
        print("  %-9s Hand_L %s  Fuss_L %s  Kopf %s"
              % (clip,
                 str([round(c, 2) for c in orte["Hand_L"]]),
                 str([round(c, 2) for c in orte["Foot_L"]]),
                 str([round(c, 2) for c in orte["Head"]])))
