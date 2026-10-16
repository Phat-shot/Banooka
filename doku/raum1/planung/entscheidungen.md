# Nutzerentscheidungen P0 (verbindlich, gehen allen Entwürfen und dem Baukastenplan vor)

- R1 (L02): **Spurbindung in 2D: JA.** In der Seitenansicht wird die Eingabe auf die Wegachse gelegt (Seitenanteil ≥ 0,5). Reine Steuerung, keine Physikänderung. CLAUDE.md bekommt dazu eine Zeile (Steuerung).
- R2 (L04): **tempo_max 19 → 15 und Rastplatz-Tempo: JA.** reiter.gd bleibt unverändert; Level04.tscn setzt tempo_max 15, das Level setzt an jedem Rastplatz tempo_start.
- R3 (L05): **Slide-Sprung als Kür: JA.** Slide unter Durchlässen ist Pflicht; der Slide-Sprung belohnt (Abkürzung/Geheimnis), wird nie erzwungen.
- R4 (alle): **Modellbudget: bis ~24 neue CC0-Modelle** (nicht nur 9). G4 übernimmt die volle Wunschliste aus den vier Entwürfen (dedupliziert, rund 24 Dateien, Quaternius/Kenney, CC0), Ersatzlösungen aus baukasten.md §4 Nr. 10 entfallen, wo das echte Modell kommt. .pck-Zuwachs messen und berichten.
- R5 (Figur cash_banooka_rc.glb): offen, wird separat mit dem Nutzer geklärt; die Datei wurde vom Nutzer selbst eingecheckt. Nicht anfassen.

# Koordinator-Entscheidungen (nicht vom Nutzer, sachlich begründet)
- K1 (L05, 06.10.): Kaltlade-Grenze 8 s gilt für den Spielweg aus dem Portalraum (gemessen 4,85–5,06 s). Bauzeitprobe mit L05 allein darf kalt bis 8,5 s (Median); warm ≤ 4 s. Kein Arbeitsfaden-Umbau mit Verklemmungsrisiko.
- Offen für später: L06-Richtzeit enthält 4,5 s Wartezeit nach dem Ziel (78 s aus 59 s Bot-Dauer) – mit Spieltest-Feld "uhr" nachmessen.
