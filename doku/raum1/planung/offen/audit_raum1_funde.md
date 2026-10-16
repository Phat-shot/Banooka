# Raum 1 – bestätigte Audit-Funde (gegen b67450e)

Gefunden von drei Audits (Level 01, Portalraum/Spielfluss, Baukasten), jeder Fund unabhängig reproduziert. Noch NICHT behoben. B1, H11, B3, B4 gehören zur L05-Schluss-Doku, der Rest in eine eigene Behebung (Hub, Spielfluss, GameState, L01, Werkzeuge). H5 und L01-A1 sind derselbe Fund.

## B1 – mittel

**Ort:** scenes/levels/level05/wegbauten.gd:341 in b67450e (im Arbeitsbaum :380): Schlüssel "l05_wegbauten_" + schluessel. Kommentar :343–351 („Die Netze hängen nur an den Daten des Levels und am Code“). Abhängigkeit über level.gelaende.hoehe an :1722 und :1796 (im Arbeitsbaum schon an :606, :650, :2094, :2188) → L05Gelaende.hoehe → feld.hoehe_bei; das Raster hängt an gelaende.gd:464 (`HANDY` 1,4 bei Effekte.reduziert). Verletzte Regel: scripts/bauspeicher.gd:46–47.

**Befund:** Der Bauspeicher-Schlüssel der L05-Wegbauten nennt die Fassung (Handy oder Desktop) nicht. Der Inhalt hängt aber über die gezeichnete Geländehöhe an Effekte.reduziert. Ein Lauf im anderen Modus mit demselben user:// lädt deshalb die Steinnetze der anderen Fassung, und zwar in beiden Richtungen. Damit ist die Regel aus bauspeicher.gd verletzt („der SCHLÜSSEL muss alles nennen … `Effekte.reduziert`“), und der Kopfkommentar stimmt nicht. Im ausgelieferten Spiel ist reduziert heute je Gerät fest (Effekte._vorbelegung, der Schalter ist erst geplant). Betroffen sind deshalb jetzt die Prüfläufe mit gemeinsamem user:// (FOTO_REDUZIERT, BAUZEIT_REDUZIERT, RUCKEL_REDUZIERT, also die Handy-Abnahmen von L05), sobald es den Optionsschalter gibt auch das Spiel. Weder der Arbeitsbaum noch l05_runde3_unfertig.patch ändern den Schlüssel.

**Beleg:** Selbst nachgestellt auf einer eigenen git-archive-Kopie von b67450e mit eigener Probe (verif/steinprobe.gd: Level05 bis aufbau_fertig, seed 1, --fixed-fps 60, headless; je MeshInstance unter „Wegbauten“ ein Hash über die Ecken plus AABB). Fünf Läufe: a) Handy frisch in X1, b) danach Desktop in X1, c) Desktop frisch in X2, d) Handy frisch in X3, e) danach Handy in X2.
- b gegen c: genau 3 Netze verschieden, B Hohlweg/Stein (v3023), C Terrassen/Stein (v1596) und D Tobel/Stein (v7296). Bei D ist die AABB 16,74625 statt 16,98058 m hoch.
- b gegen d: identisch bis auf die Zeile „reduziert“.
- e gegen c: identisch bis auf „reduziert“, die Gegenrichtung ist also ebenso falsch.
- Holz, Kranz, E und Laternen sind in allen Läufen gleich.
- l05_wegbauten_a…e.res sind nach Lauf b unverändert (mtime 11:34:16 vorher wie nachher). Lauf b hat also aus dem Speicher gelesen.
Dateien: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/b1/ (a_handy_vorlauf.txt, b_voll_nach_handy.txt, c_voll_frisch.txt, d_handy_frisch.txt, e_handy_nach_voll.txt, a_files.txt, b_files.txt). Probe: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/kopie/verif/steinprobe.gd.

**Vorschlag:** In der laufenden L05-Arbeit `_abschnitt` die Fassung in den Schlüssel nehmen: "l05_wegbauten_" + ("handy" if Effekte.reduziert else "voll") + "_" + schluessel, wie saum.gd:198 und wasser.gd:372. Den Kommentar :343–351 berichtigen. Danach die Steinprobe wiederholen (verif/steinprobe.gd mit Steinprobe.tscn in eine Projektkopie legen). Abnahme: Desktop nach Handy im selben user:// ist zeilengleich mit Desktop frisch, Handy nach Desktop zeilengleich mit Handy frisch.

## B2 – mittel

**Ort:** werkzeuge/pruefe.sh:50–65 (Stufe 3 nur scenes/levels/Level*.tscn) und :72–203 (Stufe 4 ohne Baukastenprobe; die Werkstatt nur in der Sprungprobe, :123). Dazu waechter.md §7 und werkzeuge/schaufenster.sh.

**Befund:** Kein Standardlauf prüft, ob die Bausteine in scripts/gemeinsam noch bitgleich mit den L01-Originalen rechnen, also weder pruefe.sh noch Wächter W noch schaufenster.sh. Level 01 und der Portalraum laden keinen Baustein. Deshalb können die Bilder und L01-Logs von W eine Baukasten-Änderung grundsätzlich nicht sehen. Den LevelCheck der Werkstatt (Stationen 30–38) ruft keine Stufe auf.

**Beleg:** Zählung `grep -c -i baukastenprobe`: pruefe.sh 0, schaufenster.sh 0, waechter.md 0, waechter_logs.sh 0.

Ladeumfang mit eigener Probe (verif/umfang.gd; ResourceLoader.has_cached über alle .gd nach load und nach dem vollen Aufbau):
- Level01: 70 Skripte, 0 aus scripts/gemeinsam.
- Hub: 52 Skripte, 0 aus scripts/gemeinsam.
- Level05: lädt alle 10 Bausteine.

Gegenprobe auf einer Kopie mit wegdecke.gd `KRONEN_UEBERGANG` 1,5 → 1,6:
- Baukastenprobe: „=== Baukastenprobe: 119708 Vergleiche, 45 Abweichungen ===“, Rückgabe 1, 12,6 s.
- Original zum Vergleich: 0 Abweichungen, Rückgabe 0, 12,4 s.
- Dieselbe geänderte Kopie im vollen pruefe.sh: „ERGEBNIS: SAUBER“, Rückgabe 0, 731 s. Darin liefen LevelCheck aller Level, Werkstatt-Sprungprobe (22 Fälle, 0 Fehler), Jagdprobe (24 Fälle, 0 Fehler), Wahrzeichen- und Wegmaskenprobe.

LevelCheck Werkstatt.tscn läuft sauber („=== 0 Fehler, 0 Warnungen ===“, 31 s), ließe sich also aufnehmen. Der Arbeitsbaum ändert gerade scripts/gemeinsam/wegdecke.gd (Option lippen_stein_hoch); genau solche Änderungen sieht heute kein Standardlauf.

Logs: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/b2/ (bk_original.log, bk_gegenprobe.log, pruefe_gegenprobe.log, levelcheck_werkstatt.log, umfang.txt).

Nebenbeobachtung ohne Bezug zum Audit: 1 von 10 Läufen mit load(Level05.tscn) meldete einmal einen Parse Error in Sumpfkroete.tscn/level01.gd. In 9 Wiederholungen trat er nicht wieder auf, Ursache ungeklärt (die Platte war zeitweise knapp).

**Vorschlag:** Die Baukastenprobe fest in pruefe.sh Stufe 4 aufnehmen. FEHLER, wenn die Abweichungen nicht 0 sind oder die Schlusszeile „=== Baukastenprobe: N Vergleiche, M Abweichungen ===“ fehlt; gemessen kostet das rund 13 s. LevelCheck Werkstatt.tscn in Stufe 3 aufnehmen (rund 31 s). Beides in waechter.md §7 (Ablauf je Paket) nachtragen.

## B4 – mittel

**Ort:** README.md:135–137, CLAUDE.md:70–71 (im Arbeitsbaum gleich), ARCHITEKTUR.md:121–124; dagegen scenes/levels/level05.gd:785, scenes/levels/level05/jagd.gd:212, :220–224, :228, :233–235, :456–460 und :134–138; dazu doku/raum1/planung/entscheidungen.md und STAND.md.

**Befund:** Die Doku nennt für Level 05 Werte, die der Code nicht hat:
- README nennt die Richtzeit 48 s, der Code hat ZIELZEIT 32,0.
- README und ARCHITEKTUR sagen „läuft immer mit TEMPO 7,4“ und „nie weiter als 15 m zurück“.
- CLAUDE.md sagt „festes Tempo knapp unter dem Lauftempo“.

Der Code holt dagegen mit AUFHOL_TEMPO 10,5 m/s auf, schneller als die Figur mit 8,5. Hinter der Staffel läuft er bis DECKEL_HOECHST 16 m/s (`clampf(_figur_tempo + DECKEL_ZUSCHLAG, AUFHOL_TEMPO, DECKEL_HOECHST)`), dazu kommt eine Abstands-Staffel 15/12/9,5/8/14/10/7,5 m. jagd.gd:137 vermerkt selbst „Dem Nutzer vorzulegen“, aber weder entscheidungen.md (R1–R5, K1) noch STAND.md führt den Punkt. Nur die Jury-Liste (offen/l05_jury_runde3.md:81/85/89) sagt „mit dem Nutzer klären“. Ob die Jagd so bleibt, entscheidet der Nutzer; der Befund ist der Widerspruch.

**Beleg:** Selbst gelesen in b67450e; CLAUDE.md und entscheidungen.md sind im Arbeitsbaum gleich (diff leer). Gemessen widerspricht die Jagdprobe im pruefe-Lauf auch dem „nie weiter als 15 m“: „JAGD Dauer-Slide … 190–236 Mittel 15.16, höchstens 16.00 m (Grenze 16.5)“. Log: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/b2/pruefe_gegenprobe.log. Dieser Lauf lief auf der Gegenproben-Kopie; die geänderte Konstante wirkt nur auf das Kronenlicht der Wegdecke, nicht auf die Jagd.

**Vorschlag:** Die offene Nutzerentscheidung „Keiler holt schneller als die Figur auf (10,5 bis 16 m/s), Staffel statt 15 m“ in entscheidungen.md oder STAND.md aufnehmen. Die Richtzeit in README sofort auf 32 s berichtigen. CLAUDE.md, ARCHITEKTUR.md und den README-Satz zur Jagd nach der Entscheidung auf den Code ziehen.

## H1 – mittel

**Ort:** scenes/hub/hub.gd:2373-2376 (_deko_wurzelwald, zwei WURZELPROP mit Kollision); scenes/props/wurzel.gd:101 (_kollisionsbox)

**Befund:** Bestätigt. Wer gegen die beiden begehbaren Wurzelbögen vor den Toren von Raum 1 läuft, verklemmt sich an ihnen. Ursache ist die Wurzelkollision: Gegenprobe mit abgeschalteten Kollisionsformen an derselben Stelle ergibt 0 von 8 blockierten Richtungen. Die Ruckelprobe im Portalraum wertet einen Durchgang mit stehender Figur trotzdem aus und meldet die verfehlten Wegpunkte nur in einer Zeile.

**Beleg:** Eigene Kopie b67450e (v2/kopie), headless, Physik 60 Hz. ruckel_hl_neu.log: „23 Wegpunkte nicht erreicht“, Figur steht ab Bild 303 bis Bild 5301 auf (-29.9, -0.4). ruckel_hl_mitte.log: 1 verfehlt. klemme.log: An der Audit-Stelle (-29.93 | 0.001 | -0.38) sind mit Wurzelkollision alle 8 Richtungen blockiert (je 0,5 s, je 0,00 m). Ohne Wurzelkollision kommt die Figur je 4,0–4,25 m weit. Sweep mit 2×36 Anläufen aus 3,5 m, in zwei Läufen je 6 Klemmstellen (mindestens 3 von 8 Richtungen blockiert). Der Anlauf aus 310° endet laufend genau an der Audit-Stelle (-29.934 | -0.379), dort sind 7 von 8 Richtungen blockiert, nur 315° ist frei. Ein Sprung befreit (y 1,48, 5,85 m). Am zweiten Bogen, Anlauf 340°: 7 von 8 blockiert, der Sprung gewinnt keine Höhe, frei ist nur eine Richtung. Zustand an der Klemme: boden=true, velocity 0, get_last_motion 0, als Kontakt nur der Boden. Die Klemmstellen streuen von Lauf zu Lauf. Logs unter …/verif_portal/v2/logs/ (klemme.log, ruckel_hl_neu.log, ruckel_hl_mitte.log).

**Vorschlag:** Die beiden Bögen vor der Portalreihe mit "kollision": false bauen, wie die Vorhof-Bögen hinter Tor 01, oder sie aus dem Laufweg nehmen. Zusätzlich sollte ruckelprobe.gd einen Durchgang mit verfehlten Wegpunkten als UNGÜLTIG kennzeichnen. Abnahme: Ruckelprobe Hub mit Stand neu und mitte meldet 0 verfehlte Wegpunkte, und der Klemm-Sweep findet 0 Stellen.

## H2 – mittel

**Ort:** autoload/Spielfluss.gd:103/240 (freigeschaltet linear), :385-400 slot_daten „raum“; scenes/ui/splash.gd:392 und :621-641; autoload/Ladeschirm.gd:240-243; scenes/ui/statustafel.gd:404-405

**Befund:** Bestätigt. Freigeschaltet wird raumweise (level_offen), alle Anzeigen lesen aber den linearen Zähler freigeschaltet. Nach einem neuen Spiel sind 5 Level offen, angezeigt wird 1. Nach L05 wird 6 angezeigt, obwohl L06 versiegelt ist. Die Slotzeile nennt dann „Nebelsümpfe“ als Raum.

**Beleg:** fluss.log (Probe vprobe.gd, Fall fluss). Neues Spiel: level_offen=[1,2,3,4,5], Ladeschirm-Kicker „1 VON 25 LEVELN FREIGESCHALTET“, Statustafel „Freigeschaltet 1 / 25 Level“, Splash-Rauten hell nur [1]. Nach L01: Kicker „2 VON 25“, Rauten hell nur [2]. Nach L01+L05: raum_offen(2)=false, Kicker „6 VON 25“, Statustafel „6 / 25“, slot_daten raum=„Nebelsümpfe“, Rauten hell [2,3,4,6], also 6 als offen und 5 nicht. Gerenderter Startbildschirm nach neuem Spiel, bilder/splash_neues_spiel.png: „1 von 25 Leveln freigeschaltet · 0 geschafft“ und genau eine offene Raute.

**Vorschlag:** Eine Abfrage Spielfluss.offene_level() einführen, die level_offen zählt, und für Speicherplätze dieselbe Raumlogik aus den gespeicherten geschafft-Daten. Splash-Zeile, Rautenreihe (hell = level_offen), Ladeschirm-Kicker und Statustafel darauf umstellen. Raum im Slot ist der höchste offene Raum.

## H3 – mittel

**Ort:** autoload/GameState.gd:171-178 (_zum_portalraum_nach_game_over); scenes/ui/statustafel.gd:153-172 (setzen), :274 (_neu_starten)

**Befund:** Bestätigt. In den 2,5 s nach GAME OVER lässt sich die Statustafel öffnen (Gruppen auswertung und uebergang sind leer) und „Neu starten“ wählen. zum_level setzt dabei aktuelles_level wieder auf dieselbe Nummer. Der alte Timer schickt den Spieler deshalb mitten im Neustart in den Portalraum.

**Beleg:** gameover_l01.log: GAME OVER bei 33,32, Tafel über die Aktion pause offen bei 33,86 (Baum angehalten), Neu starten bei 34,17, Ladeschirm „Wurzelschlucht“ bei 34,53, danach Ladeschirm „Portalraum“ mit aktuelles_level=0 bei 36,53, Ende Hub. gameover_l05.log: GAME OVER bei 29,94, Neu starten bei 30,77, Ladeschirm „Hauerjagd“ bei 30,85, „Portalraum“ bei 32,46, Ende Hub. Die ERROR-Meldung des Renderers aus dem Audit war headless nicht zu prüfen.

**Vorschlag:** Den Game-Over-Wechsel an einen Wechselzähler in Spielfluss binden, den jeder _wechseln-Aufruf erhöht; der Timer wechselt nur, wenn der Zähler seit dem Tod gleich ist. Alternativ die Statustafel während der Game-Over-Pause sperren, wie bei „auswertung“.

## H4 – mittel

**Ort:** autoload/Spielfluss.gd:236/239/251 (level_abschliessen nutzt GameState.fruechte); autoload/GameState.gd:115-122 (frucht_einsammeln zieht je Extraleben 100 ab)

**Befund:** Bestätigt. Gutgeschrieben wird nur der Rest nach Abzug der Extraleben. Das trifft Rekord, Gesamtzahl und Zielkarte. Damit widerspricht der Code seinem eigenen Kommentar „Gesammelte Früchte über den ganzen Spielstand hinweg“. Außerdem schlägt ein Lauf mit 99 Früchten einen mit 209 im Rekord.

**Beleg:** fruechte_l01.log: 120 lose Früchte, aus Kisten 89, zusammen 209. Nach dem Einsammeln GameState.fruechte=9, Leben 6->8. fruechte_gesamt 0->9, geschafft[1].fruechte=9, Auswertung „fruechte“=9. fruechte_l05.log: 119+56=175, gutgeschrieben 75. Echter Bot-Lauf (spieltest_rt.log, spielstand_1.cfg): L01 mit zwei Extraleben gespeichert als "fruechte": 16, Gesamt 99.

**Vorschlag:** GameState einen Zähler „im Versuch gesammelt“ ohne Abzug führen lassen, zurückgesetzt in neu_beginnen und bei Game Over. level_abschliessen und die Auswertung nutzen ihn. Der HUD-Zähler x/100 bleibt.

## H5 – mittel

**Ort:** scenes/levels/level01.gd (kein zielzeit()); scenes/levels/level_basis.gd:351-361 (287 m / 8,5 × 2,8 = 94,54 s)

**Befund:** Bestätigt. Die Richtzeit von L01 ist der nicht erspielte Platzhalter der Formel. Ein todesfreier Bot-Lauf liegt mit 38 s weit unter der Platin-Grenze 68,07 s; Platin ist damit geschenkt. L05 und L06 wurden wegen desselben Befunds von Hand gesetzt.

**Beleg:** spieltest_rt.log (Bot in Echtzeit, headless, eigene Kopie): „Level 01: geschafft … Tode 0, Uhr 38.0 s“, Weg 287 m. Daraus Richtzeit 94,54 s, Gold 80,36 s, Platin 68,07 s (Zeitlauf.gd: LAUFTEMPO 8,5, ZEITFAKTOR 2,8, PLATIN_ANTEIL 0,72). Der Lauf war nicht im Zeitmodus; dort hielten die Zeitkisten die Uhr zusätzlich an, die Zeit würde also eher kürzer. ARCHITEKTUR.md nennt die Formel selbst „nicht erspielt“.

**Vorschlag:** level01.gd bekommt zielzeit() nach dem Muster von L05/L06: todesfreie Uhr (Spieltest-Feld „uhr“, gemessen 38,0 s) × 1,3, mit Luft. Ändert keine Pixel. Danach Zeittafel und Doku nachziehen.

## H6 – mittel

**Ort:** autoload/Spielfluss.gd:332-333 (vorladen_naechstes = LEVEL_SZENEN[freigeschaltet-1]); scenes/hub/hub.gd:578; Begründung K1 in scenes/levels/level05.gd:978-984

**Befund:** Bestätigt. Vorgeladen wird nach dem linearen Zähler. Nach L05 lädt der Portalraum Level06, obwohl Raum 2 versiegelt ist; das widerspricht dem eigenen Kommentar „sonst das höchste offene“. L05 wird nur vorgeladen, wenn L04 das höchste geschaffte Level ist. Im heutigen Spielweg L01 → Hub → L05 ist L05 nie vorgeladen, die Begründung von K1 („meist schon vorgeladen“) trägt dort also nicht. Was nie abgeholt wird, bleibt im Lader liegen.

**Beleg:** fluss.log: Neues Spiel → L01=IN_PROGRESS. Nach L01 → L02=IN_PROGRESS. Nach L01+L05 → L02=LOADED und L06=LOADED, L05=INVALID. Nur L05 → freigeschaltet 6, L06 LOADED. Ungeprüft: die Ladezeit von L05 mit und ohne Vorladen; die Maschine lief unter Last 5–9.

**Vorschlag:** Vorladen am Tor festmachen: Das offene Tor, dem sich die Figur nähert (_naehe > 0), ruft Spielfluss.vorladen(). Ersatzweise das kleinste offene, nicht geschaffte Level, nie eines mit level_offen()==false. Danach die Ladezeit im Spielweg L01 → Hub → L05 ohne Last messen und K1 neu belegen.

## L01-A1 – mittel

**Ort:** scenes/levels/level01.gd (kein zielzeit()-Override) -> LevelBasis._richtzeit() (level_basis.gd:351-360), Zeitlauf.gd ZEITFAKTOR 2,8; festgeschrieben in doku/level01-neubau.md §3 (Z. 118f.) und P1-Abnahme (Z. 927: 'Die Richtzeit ist 94–95 s')

**Befund:** Im Zeitmodus von Level 01 sind die Stufen wirkungslos. Saphir liegt bei 94,54 s, Gold bei 80,36 s, Platin bei 68,07 s. Die reine Laufzeit über 287 m beträgt 287 / 8,5 = 33,8 s, die Platin-Grenze ist also doppelt so lang. Ein Lauf ohne Tod liegt bei rund 37–38 s auf der Rohuhr, auch ohne eine einzige Zeitkiste. Damit fällt Platin, sobald man ohne Tod durchkommt. Der Raum-1-Plan (doku/raum1/planung/baukasten.md §4 Nr. 13) hält selbst fest, dass die Formel 'jede Stufe geschenkt' gibt, und schreibt für L02–L05 eine Richtzeit von 1,3 × Bot vor. Die L05-Jury hat denselben Fall als Mangel gewertet (level05.gd:757f.). Level 01 ist das einzige Raum-1-Level, das noch auf der Formel steht.

**Beleg:** Eigene Kopie von b67450e (verif_l01/kopie, Import ohne Fehler). Eigene Probe kopie/werkzeuge/verifprobe.gd mit VERIF_MODUS=zeit, headless; Log logs/zeit_probe_voll.log: 'Laenge 286.99 m, zielzeit() 0.00, _richtzeit 94.54, Zeitlauf.richtzeit 94.54' und 'Saphir 94.54 Gold 80.36 Platin 68.07'.

Bot-Läufe headless mit --fixed-fps 60 und Zeitmodus, spiel/h_zeit1..4/protokoll.txt. Nur in der Testkopie war das Hintergrundladen abgeschaltet, weil der Dummy-Renderer im Ladefaden nicht lädt. Bis zum ersten Tod verlaufen alle 4 Läufe identisch:
- Uhrstart bei 12,7 s.
- Zeitkisten +2, +3, +1.
- Sturz an der Furt (s 167) bei 34,1 s, also nach 21,4 s Rohzeit; die Zeitlauf-Uhr stand dabei bei 15,4 s.
- h_zeit1: vom Respawn am CP 166 bis 'Level geschafft!' 16,4 s (49,3 -> 65,7 s), einschließlich Respawn.
- Summe ≈ 37,8 s Rohzeit. Das passt zu den 37,5 s des Audits.

Einen todesfreien Lauf habe ich selbst NICHT erhalten. Headless stürzt der Bot an der Furt in 4 von 4 Läufen. Ein xvfb-Lauf mit --fixed-fps 60 kam nur mit 3 Spielsekunden je 10 Minuten voran und wurde abgebrochen. Die Meldung '30,45 – Platin' ist darum nicht selbst nachgestellt; Richtzeit und Laufzeiten sind es.

**Vorschlag:** Wie im Audit: Level01.zielzeit() überschreiben, mit 1,3 × Bot-Uhr aus todesfreien Läufen mit 60 Hz. Mit 37,5 s ergibt das ≈ 49 s, also Gold ≈ 41,7 s und Platin ≈ 35,3 s. Kleine Korrektur zur Begründung im Audit: L05 nutzt in b67450e nicht 1,3 × Bot, sondern 32 s aus dem Dauer-Slide-Lauf plus 2,4 s Luft. Für 1,3 × Bot ist baukasten.md §4 Nr. 13 die richtige Referenz. Mitzuziehen sind die Abnahmezeile in doku/level01-neubau.md (Z. 118f., 927) und der GLAETTUNG-Kommentar in level01.gd:84. Weil der Wert im abgenommenen Entwurf steht, vorher Rückfrage beim Koordinator bzw. Nutzer. Ohne Zeitmodus bleibt das Bild unverändert, denn Zeitlauf.beginnen kehrt bei aktiv=false sofort zurück.

## B3 – leicht

**Ort:** ARCHITEKTUR.md (Bauspeicher-Block :940–946, sonst kein Abschnitt zum Baukasten); README.md:169–185 (Prüfen) und :600–643 (Projektbaum); doku/raum1/planung/offen/l05_doku_zwischenstand.patch

**Befund:** README nennt ARCHITEKTUR.md die „verbindlichen Schnittstellen“ (:640). Dort fehlt aber der ganze Baukasten in scripts/gemeinsam (10 Bausteine) samt der neuen Bauspeicher-API:
- vorladen, vorrechnen, vorrechnen_wert, vorrechnen_an, faeden() und vorrechnungen_verwerfen().
- Klang.strom, GelaendeSaum.stoff_variante, die Findling-Optionen ecke und fuge_tiefe sowie die Rollen M19–M24.

README beschreibt Stufe 4 von pruefe.sh ohne Sprung-, Jagd-, Wahrzeichen- und Wegmaskenprobe, der Projektbaum kennt scripts/gemeinsam nicht. Das ist nur eine Lücke, kein Funktionsfehler. Dass die Doku offen ist, steht schon in STAND.md:33–36 („Erst nach der letzten Jury neu schreiben“). Neu ist: Auch der bereitliegende Patch reicht inhaltlich nicht und ist veraltet. Daher leicht; es betrifft vor allem die spätere Arbeit an L02–04.

**Beleg:** Zählung in b67450e, ARCHITEKTUR.md (1738 Zeilen):
- Je 0 Treffer: Wegdaten, GelaendeBau, Bachband, Nebelstoff, Waldrahmen, Baumfabrik, Rasenbau, Stimmungsregler, scripts/gemeinsam, vorrechnen, faeden, vorrechnungen_verwerfen, strom, stoff_variante, fuge_tiefe, M19, M24.
- „Wegdecke“ (1) und „Kanten“ (2) kommen nur als Wörter vor (:994, :995, :1596).
- Dagegen bauspeicher.gd: vorladen :128, vorrechnen :188, vorrechnen_wert :202, faeden :209, vorrechnungen_verwerfen :227, vorrechnen_an :80. Ebenso Klang.gd:195 `func strom`, gelaende_saum.gd:783 stoff_variante, findling.gd:75/391 fuge_tiefe, fremdmodelle.gd:367/473/506 M19–M24.

README: jagdprobe, wahrzeichenprobe und baukastenprobe je 0 Treffer (ebenso in ARCHITEKTUR).

Doku-Patch:
- Er bringt die Bausteintabelle (+Zeilen 103–141).
- Er hat 0 Treffer für vorrechnen und Fäden; Klang kommt nur als „in Klang.gd“ vor (Z. 31).
- Sein README-Teil (Z. 182–220) ändert nur den L05-Absatz, und zwar mit „Richtzeit … 15 s“, „15 bis 11 m“ und „Stand R1“, gegen ZIELZEIT 32.0 im Code.

**Vorschlag:** Den Abschnitt „Baukasten für Raum 1“ aus dem Patch übernehmen, getrennt vom L05-Teil. Ergänzen um:
- die Bauspeicher-Fadenschnittstelle samt der Erzeuger-Regel aus bauspeicher.gd,
- Klang.strom,
- GelaendeSaum.stoff_variante,
- die Findling-Optionen ecke und fuge_tiefe,
- die Rollen M19–M24.

README „Prüfen“ (Stufe 4 vollständig) und den Projektbaum (scripts/gemeinsam, die Proben) nachziehen. Den L05-Teil erst nach der Jury neu schreiben.

## H10 – leicht

**Ort:** werkzeuge/spieltest.sh:30-40 und :65-71 (STAND fest auf $HOME/.local/share/…); werkzeuge/spieltest.gd:175-177 (Kommentar)

**Befund:** Teilweise bestätigt, Teile (b) und (c). (b) Das Skript sichert und löscht die Spielstände unter $HOME/.local/share/godot/app_userdata/Banooka. Godot schreibt bei gesetztem XDG_DATA_HOME aber nach $XDG_DATA_HOME/godot/app_userdata/Banooka. Der Lauf schreibt dort Platz 1 ohne Sicherung. (c) Der Kommentar „Geschrieben wird dabei nichts … der Bot wählt keinen“ ist falsch, denn der Bot beginnt auf Platz 1. Teil (a), kein xvfb-Start, ist eine im Kopf des Skripts benannte Annahme (echtes Fenster), also kein Fehler. Teil (d), 0,9 s Wartezeit, trat nur mit --fixed-fps auf, das das Werkzeug nicht verwendet; im Echtzeitlauf lief es durch.

**Beleg:** udir: OS.get_user_data_dir() ist mit XDG_DATA_HOME …/tmp.iACs4w7kz6/godot/app_userdata/Banooka, ohne XDG /root/.local/share/godot/app_userdata/Banooka. Echter Bot-Lauf (spieltest_rt.log, TEST_LEVEL=1,5): Danach liegt spielstand_1.cfg im XDG-Ordner (183 Byte, freigeschaltet=6, geschafft 1 und 5, fruechte=99). Ohne DISPLAY meldet Godot mit x11 „X11 Display is not available“.

**Vorschlag:** STAND aus ${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Banooka ableiten. Den Kommentar in spieltest.gd berichtigen (Platz 1 wird geschrieben). Optional xvfb-run wie in foto.sh einbauen und nach dem Start mit _warte_szene("Hub", 40) statt fest 0,9 s warten.

## H11 – leicht

**Ort:** README.md:138; ARCHITEKTUR.md:408-410; doku/level05-neubau.md:8, :926, :1279, :1291; doku/raum1/planung/offen/l05_doku_zwischenstand.patch

**Befund:** Bestätigt. Die Doku nennt für L05 andere Richtzeiten als der Code, und ARCHITEKTUR verschweigt, dass L05 seine Richtzeit von Hand setzt. Der Doku-Zwischenstand-Patch würde einen weiteren veralteten Wert (15 s) eintragen.

**Beleg:** Im Code: level05.gd:785 ZIELZEIT := 32.0. README.md:138 nennt „Richtzeit im Zeitmodus 48 s“. ARCHITEKTUR.md:408-410 sagt, nur Level 06 und 22 setzen ihre Richtzeit von Hand. level05-neubau.md:8 nennt „seit R1 15 s“, :926 „48 s“, :1279/:1291 „37 s“. Der Patch schreibt „Richtzeit im Zeitmodus 15 s“ (Patch-Zeilen 202-203, 319).

**Vorschlag:** In der Schluss-Doku den dann gültigen Wert (heute 32 s) eintragen. ARCHITEKTUR um L05 ergänzen, nach H5 auch um L01. Den Zwischenstand-Patch nicht unverändert anwenden.

## H12 – leicht

**Ort:** project.godot [application] (quit_on_go_back nicht gesetzt, also true); keine Behandlung von go_back_requested bzw. NOTIFICATION_WM_GO_BACK_REQUEST; export_presets.cfg:43 Android-Preset, README:486ff (CI baut APK)

**Befund:** Bestätigt; auf einem echten Gerät ungeprüft. Die Zurück-Anfrage des Hauptfensters beendet das Spiel sofort, auch mitten im Level. Gespeichert wird nur im Portalraum, der Fortschritt seit dem letzten Besuch dort geht also verloren. Auf Android kann eine Rand-Wischgeste neben dem Touch-Joystick das auch versehentlich auslösen.

**Beleg:** zurueck.log: quit_on_go_back=true, auto_accept_quit=true. Im laufenden Level 01 beendet get_tree().root.go_back_requested.emit() das Programm. Die Kontrollzeile „nach 30 Bildern noch da“ wird nicht mehr ausgegeben, rc=0. grep findet keine Behandlung von go_back im Code.

**Vorschlag:** application/config/quit_on_go_back=false setzen. Zurück öffnet im Level die Statustafel und führt im Portalraum zum Hauptmenü.

## H7 – leicht

**Ort:** scenes/hub/levelportal.gd:473-489 (_baue_geschafft_schild), :495-525 (_baue_schein: Außenradius 1,05+0,17·4,6=1,83 m > MITTE_Y 1,25 m), :534-555 (_baue_bestzeit, pixel_size 0,0032); hub.gd:2035 (Raumname) gegen _baue_edelstein

**Befund:** Bestätigt. Das Schild „GESCHAFFT“ geht auf der überstrahlten Goldscheibe unter. Die Bestzeit ist etwa 6 px hoch, bei L01 bleibt von 1:41,37 nur „41,37“ zu sehen, also ein falscher Wert. Unter der Scheibe liegt ein heller, eckiger Fleck: Der additive Scheinring reicht rechnerisch 0,58 m unter den Boden. Sind alle fünf Tore geschafft, überdecken die Steine über 03–05 den Raumnamen „Wurzelwald“.

**Beleg:** Eigene Bilder bei 1280×720 unter …/verif_portal/v2/bilder/. bild_portal05_nah.png und zoom_bild_p05.png: 42,2 % der Scheibenfläche fast weiß (min-Kanal > 235), vom Schild nur ein schwacher Rest „ESCHAF“, Bestzeit „22,41“ etwa 6 px, heller eckiger Block unten. zoom_bild_p01.png: nur „41,37“ sichtbar. voll1_halle_start.png und voll1_halle_r36.png (Handyweg): Steine zwischen den Buchstaben von „Wurzelwald“.

**Vorschlag:** Schild über die Scheibe setzen oder mit dunklem Hof und eigener render_priority versehen. Den Scheinring nicht unter den Boden reichen lassen (Außenradius ≤ MITTE_Y oder Ring unten beschneiden). Bestzeit größer (pixel_size etwa 0,006), mit Kontur und frei vom Schlussstein. Steinhöhe so wählen, dass der Raumname frei bleibt. Der Wächter-Teil wache (Portalraum ohne geschaffte Tore) bleibt gleich.

## H9 – leicht

**Ort:** scenes/ui/hud.gd:1043 (Titelkarte: UiStil.raute mit r = 6·strich, sobald lang > 1); scripts/ui_stil.gd:752-760 (raute → draw_colored_polygon)

**Befund:** Bestätigt. Sobald die Linie der Titelkarte länger als 1 px ist, wird die Raute gezeichnet, ihr Radius kann dann aber noch weit unter 0,1 px liegen. Godot meldet dann „ERROR: Invalid polygon data, triangulation failed.“ Ob es passiert, hängt davon ab, wie viel Zeit im ersten Bild nach der Tween-Verzögerung übrig ist.

**Beleg:** raute.log: Einzeltest bei (523,7 | 412,3) mit r ≤ 0,05 gibt den ERROR, r ≥ 0,1 nicht. Echte Titelkarte von L01 („Wurzelschlucht“, Textbreite 356 px, die Raute erscheint ab strich 0,00287): strich 0,004 (r 0,024) und 0,003 (r 0,018) geben den ERROR, 0,01 (r 0,06) nicht. Das Fenster strich 0,0029–0,01 entspricht bei 60 Hz etwa 0,4–1,5 ms Restzeit, also einigen Prozent je Levelstart. Das passt zu 1 Meldung bei 11 Levelstarts im Audit.

**Vorschlag:** In UiStil.raute bei r < 0,5 px nichts zeichnen, oder in der Titelkarte die Raute erst ab strich ≥ 0,1 zeichnen.

## L01-A3 – leicht

**Ort:** scenes/levels/level_basis.gd _zeitkisten_setzen() (:385-399, jede dritte NORMAL-Kiste in Baumreihenfolge) mit scenes/levels/level01.gd KISTEN (:725-727, :745-747; Einträge mit "auf")

**Befund:** Im Zeitmodus stehen 2 der 14 Zeitkisten in Geheimnissen neben dem Weg:
- Findlingsturm: KISTEN s 190,4 q +6,8, +2 s, 3,0 m über der Wegdecke. Der Weg ist dort 12 m breit (±6), die Kiste steht also außerhalb.
- Oberwurzel: s 255,5 q −6,0, +2 s, 4,28 m über der Decke. Der Weg ist dort 8 m breit (±4).

Das verletzt die ausdrückliche Regel in Zeitlauf.gd (Kopf) und LevelBasis: Zeitkisten ersetzen Kisten AUF dem Weg und stehen nie abseits. Die L05-Jury R2 hat genau das als Mangel 2 gewertet (level05.gd:559-566). Zählung und Funktion stimmen.

**Beleg:** verifprobe.gd mit VERIF_MODUS=zeit, headless, Level 01 mit Zeitlauf.aktiv. Log verif_l01/logs/zeit_probe_voll.log:
- 'Zeitkisten 14, zusammen 27 s; zaehlende Kisten 57, GameState 57'.
- 'ZEIT +2 s: Eintrag s 190.4 q 6.8 auf 'Findlingsturm' … ueber Decke 3.00 m, Wegbreite 12.00'.
- 'ZEIT +2 s: Eintrag s 255.5 q -6.0 auf 'Oberwurzel' … ueber Decke 4.28 m, Wegbreite 8.00'.
- Die übrigen 12 stehen alle 0,00 m über der Decke und innerhalb der Wegbreite.

Die Werte decken sich mit dem Audit, das die Mitte der Kiste gemessen hat (+0,5 m: 3,50 bzw. 4,78). Ich habe von Hand nachgezählt: Die 30. und die 39. NORMAL-Kiste in der Reihenfolge von KISTEN sind genau diese beiden. Ob der Umweg weniger als 2 s kostet, also Umwege tatsächlich belohnt, habe ich nicht gemessen.

**Vorschlag:** Ohne geteilte Datei, wie in Level 05: KISTEN in level01.gd in Zählreihenfolge umsortieren, sodass Geheimnis-Kisten nie auf jede dritte NORMAL-Stelle fallen. Level 05 macht es so (level05.gd:559-570). Alternativ das Opt-in mit Null-Pfad aus dem Audit (Meta 'abseits'). Beim Umsortieren mit Wächter W prüfen, dass das Schaufenster pixelgleich bleibt. Es rendert ohne Zeitmodus, nur die Reihenfolge der Knoten ändert sich.

## L01-A4 – leicht

**Ort:** Level 01 Pforte s 101,5: BEGEHBARES 'Pforte links/rechts' (level01.gd:436-441, Kasten s 99,5–103,5, q ±2,2…±3,75, Oberkante 2,6 m, Ebene 16, vom Kamerastrahl ausgenommen nach K2)

**Befund:** Hinter der Pforte verdecken die Pfortenfelsen die Figur, wenn sie am Rand läuft (s 103,6–106, q ±3,1).
- Links ist die Figur im Bild ganz unsichtbar.
- Rechts schaut nur der Kopf über den Felsen.

Die Kamera zieht nicht nach, weil Ebene 16 vom Sichtstrahl ausgenommen ist. Bestätigt wird nur der Teil zur Pforte; der Teil zu den Kistenstapeln steht unter 'verworfen'.

**Beleg:** Eigene Strahlprobe (verifprobe.gd mit VERIF_MODUS=kamera, headless): echte KorridorKamera, Figur gesetzt, sofort_ausrichten und 45 Physikbilder, dann ein Strahl von der Kamera zu Brust (+0,9 m) und Kopf (+1,5 m) gegen alle Ebenen. Log verif_l01/logs/kamera_probe_voll.log:
- s 103,6 / 104 / 105 bei q −3,1: Brust und Kopf verdeckt durch 'Pforte links (Ebene 16, 7,4/8,1 m)'.
- s 106: nur die Brust verdeckt.
- s 107: frei.
- Rechts (q +3,1) gilt dasselbe mit 'Pforte rechts'.
- Gegenprobe frei: q 0 bei s 104 sowie q ±2,0 bei s 105.

Renders mit foto.sh, FOTO_SAAT=1, --fixed-fps 30, FOTO_SEITLICH:
- verif_l01/bild/links31/verfolger_01_104.png: Figur nicht zu sehen.
- verif_l01/bild/rechts31/verfolger_00_104.png: nur der orange Kopf über dem rechten Felsen.

**Vorschlag:** Bewusster Eingriff, der Bildpunkte in Level 01 ändert, mit neuem Schaufenster-Vergleich. Zwei Möglichkeiten: die Pfortenfelsen hinter der Torlinie (s > 102) innen niedriger machen oder abschrägen, oder nur die oberen Felsteile auf Ebene 8 legen. K2 nicht aufweichen, denn es verhindert, dass die Kamera vor die Figur springt. Die Sichtschlauch-Probe in LevelCheck findet Verdeckung durch Ebene 16 grundsätzlich nicht; eine Probe für Figur-Verdeckung wäre die Absicherung.

## L01-A5 – leicht

**Ort:** Level 01 Desktop-Kosten gegen doku/level01-neubau.md §13 (Z. 784: '≤ 750k Primitive (Schatten eingerechnet)') und P14-Abnahme (Z. 1098); README.md Z. 94

**Befund:** Am Desktop liegt Level 01 an 5 der 11 Verfolger-Stationen über dem eigenen Budget von 750k Primitiven, höchstens 785k bei s 140 (+4,7 %). README.md Z. 94 nennt 'höchstens rund 0,64 Mio. Primitive'; die Zahl ist veraltet. Draw-Calls (208–361, ≤ 700) und VRAM (128,6 MB, ≤ 140) halten.

**Beleg:** foto.sh in der Verif-Kopie (b67450e), FOTO_SAAT=1, --fixed-fps 30, Desktop; Dateien verif_l01/bild/werte_kosten.tsv und werte_rest.tsv.
- Über 750k: s 4 760 997, s 31 779 052, s 101 751 296, s 119 779 915, s 140 784 964.
- Darunter: s 46 707 254, s 70 737 707, s 176 652 070, s 212 512 549, s 249 583 471, s 275,5 676 128.
- Die Werte für 4, 31, 101, 119 und 140 sind byte-gleich mit denen des Audits.
- 46, 70 und 275 weichen um 1–2 % ab, weil eine andere Stationenfolge im selben Lauf lag; keine der Abweichungen kreuzt die Grenze.

**Vorschlag:** Den Verursacher je Station messen, etwa mit FOTO_ASSETS=0 oder durch Ausblenden einzelner Module. Danach entweder unter 750k senken (bewusster, pixeländernder Eingriff) oder das Budget für Level 01 ausdrücklich anheben. In jedem Fall die README-Zahl (Z. 94) korrigieren.

## Verworfen

- **H8:** Das ist ein Optimierungswunsch, kein Fehler. Für den Portalraum gibt es keine festgelegte Draw-Call-Grenze; das Audit sagt das selbst. Die 450 gelten für die Levelpakete (baukasten.md:427-428, level05-neubau.md:666), und das Ziel ≤ 405 ist im Fund neu gesetzt. Dass die Zahl mit dem Fortschritt steigt, folgt aus dem Entwurf (Steine, Schilder, Schein je geschafftem Tor). Ein spürbarer Schaden ist nicht belegt: Die Ruckelprobe des Audits zeigt im Stand 0 Ruckler. Ich habe den Handyweg nicht nachgemessen. Auf dem Rechnerweg sehe ich bei allen fünf geschafften Toren 390 (Eingang) bzw. 414 (Startradius vor Raum 1) Draw-Calls (logs/bild_alle2.log). Will man eine Grenze für den Portalraum, ist das eine Entscheidung für den Nutzer und kein Mangel.
- **L01-A2:** Die Zahlen habe ich reproduziert, einen Fehler im Sinne einer verbindlichen Grenze nicht. K1 gilt laut entscheidungen.md ausdrücklich für L05. Das Audit schreibt selbst, der Koordinator müsse erst entscheiden, ob K1 auch für L01 gilt. Das ist eine Entscheidungsfrage, kein belegter Mangel. Das eigene Budget von L01 (level01-neubau.md §13: 'Ladezeit höchstens doppelt so lang wie heute') ist relativ, und eine Bezugsmessung von vor dem Neubau gibt es nicht. Gegen die letzte dokumentierte Messung (README: erster Start 11,2 s, jeder weitere 7,7 s) liegt der Stand bei etwa ×1,4 bzw. ×1,0–1,15, also unter ×2.

Eigene Messung, Bauzeitprobe in der Verif-Kopie, Last 1,5–4,3, Log verif_l01/logs/bauzeit.log:
- Kalt, L01 allein: 15,7 / 16,5 / 15,4 s (Audit: 17,9–18,3).
- Runde 2 im selben Prozess (das 'warm' des Audits): 4,2 / 4,5 / 4,5 s.
- Echtes Warm (neuer Prozess, Bauspeicher gefüllt): 7,9 / 7,9 / 8,9 s.
- Spielweg Portalraum -> L01, kalt: 11,4 / 11,7 s (Audit: 14,0–16,3); warm: 7,5 / 6,9 s.

An K1 gemessen (8 / 8,5 / 4 s) lägen alle Werte darüber. Ob die Grenze auch für L01 gelten soll, entscheidet der Koordinator.
- **L01-A4 (Teil Kistenstapel s 21 q −4,4 und s 96 q −3,5):** Nachgestellt, aber kein Mangel. Die Kollisionsstrahlen treffen den Stapel bei s 21,5–23 und 96,5–98, und zwar die Brust. In den Renders bleiben aber Kopf und Ohren über dem Stapel sichtbar (verif_l01/bild/links44/verfolger_00_022.png), bei s 97 auch Kopf und Schulter neben ihm (verif_l01/bild/links31/verfolger_00_097.png). Die Figur ist also jederzeit zu finden. Es geht um 1–2 m direkt hinter einem zerbrechlichen Hindernis, und die Stapel wurden bewusst an den Rand gesetzt, damit die Kamera nicht vor die Figur springt (level01.gd:678-682, :701-702; K3).
- **B5:** Selbst nachgemessen, aber kein Fehler.

Was stimmt:
- Level06, Level11 und Level17 laden jetzt wegdaten.gd mit (L11: 72 → 73 Skripte). Das korridor_level.gd von 052641f lädt es nicht.
- Übersetzungskosten, je 30× neu übersetzt, Median, bei Systemlast ~5,5: korridor_level.gd 146 → 199 ms, wegdaten.gd 83 ms. Das sind rund +0,13 s je kaltem Laden.
- Das ganze load(Level11.tscn) ließ sich unter der Last nicht auflösen. Abwechselnd 6×: 052641f Median 2222 ms (1831–2470), b67450e 2073 ms (1977–2552).

Warum kein Fehler: Das Verhalten ist gleich, und die Bauteile in korridor_level.gd für alle Level sind so geplant (baukasten.md:397). Den Spielweg lädt der Portalraum vor (Spielfluss.vorladen_naechstes, hub.gd:578).

Die vorgeschlagene Abhilfe greift nicht: korridor_level.gd ruft Wegdaten auch statisch auf (:1064, :1073, :1086, :1219, :1232, :1245: Wegdaten.prisma und schnittnetz). wegdaten.gd lädt also auch mit untypisiertem `weg`, und das widerspräche zudem der Typregel.

Als bewusst hingenommene Ladekosten vermerken, nicht beheben.

Belege: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/b5/ (umfang_last.txt, zeiten_l11.txt, uebersetzen.txt).
- **B6:** Nachgestellt mit Kopien, in denen `gdscript/warnings/shadowed_variable_base_class=2` steht:
- b67450e meldet 86 Überdeckungen, 052641f 71.
- Neu ist der Art nach nur „weg“ an level05.gd:1645 und level17.gd:729; level17.gd ist seit 052641f unverändert.

Trotzdem kein Fehler:
- Beide lokalen Variablen sind eng begrenzt und werden richtig benutzt (L05: Vector3 der Stolpersperre, L17: float der Torzeit). Ein falscher Zugriff auf das Member wäre am Typ gescheitert.
- Das Projekt hat keine Warnungsregel, und 71 Meldungen derselben Klasse gab es schon vorher (z. B. Klang.gd „name“).
- Die Ladeprobe meldet 208 Skripte, 0 nicht ladbar.

Das Umbenennen in level05.gd ist reine Pflege und kann nebenbei passieren.

Belege: /tmp/claude-0/-home-user-Banooka/f8e2cf50-8cf6-5473-86d0-6f45f3a66218/scratchpad/raum1/abschluss/verif_baukasten/b6/ (lade_kopie.log, lade_kopie_alt.log, text_*.txt).
- **B7:** Kein Fehler, sondern die eingeführte Schreibweise des Projekts. „Ebene 16“ als Bitwert steht schon in 052641f, also vor dem Baukasten:
- level01.gd:47, :520, :1105
- level_check.gd:23, :27
- bodenschatten.gd:20, :24
- level01-neubau.md:209 ff.

Daneben steht dort die förmliche Definition „Kollisionsebene 5 (Wert 16)“ (level_werkzeuge.gd:1052, level01.gd:78, level-vorbilder.md:998).

Nirgends ist ein falscher Wert gesetzt: Alle Körper nehmen LevelWerkzeuge.SPIELERGRENZE (korridor_level.gd:1052, :1216), und kein .tscn hat collision_layer 16 oder 32768. Eine einheitliche Schreibweise wäre Geschmack, nicht die Behebung eines Mangels.
