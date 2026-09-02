extends RefCounted
class_name Farben
## Zentrale Farbpalette. Alle Materialien greifen hierauf zu, damit das
## Spiel farblich zusammenpasst.
##
## Hinweis zur Helligkeit: Das Level beleuchtet die Welt mit Himmels-Ambiente
## (bläulich, Energie 0.85) und filmischem Tonemapping. Dunkle, wenig
## gesättigte Töne kippen dadurch ins Graublaue – Erde sah deshalb aus wie
## Asphalt. Die Erd- und Holztöne sind daher bewusst hell und warm
## gehalten, damit sie im Bild noch als Erde ankommen.

# Wald – Rinde und Blattwerk
const RINDE := Color(0.33, 0.22, 0.13)
const RINDE_HELL := Color(0.54, 0.39, 0.24)
const RINDE_DUNKEL := Color(0.17, 0.11, 0.06)
const LAUB_DUNKEL := Color(0.16, 0.34, 0.13)
const LAUB := Color(0.22, 0.47, 0.16)
const LAUB_HELL := Color(0.41, 0.66, 0.24)
const LAUB_GELB := Color(0.62, 0.68, 0.24)
## Farbtupfer im Blattwerk. In den Vorlagen sitzt zwischen dem Grün immer
## ein Magenta- oder Gelbfleck, sonst wird der Rand eine grüne Masse.
const BLUETE_MAGENTA := Color(0.60, 0.16, 0.38)

# Wald – Grasflächen
const GRAS := Color(0.27, 0.50, 0.18)
const GRAS_HELL := Color(0.51, 0.72, 0.27)
const GRAS_DUNKEL := Color(0.14, 0.31, 0.10)
const GRAS_TROCKEN := Color(0.63, 0.62, 0.28)

# Wald – Erde und Weg
const ERDE := Color(0.44, 0.31, 0.19)
const ERDE_HELL := Color(0.68, 0.53, 0.33)
const ERDE_DUNKEL := Color(0.26, 0.17, 0.10)
const WEG := Color(0.63, 0.48, 0.29)
const WEG_HELL := Color(0.88, 0.73, 0.48)
const WEG_DUNKEL := Color(0.42, 0.29, 0.17)
const LAUBSTREU := Color(0.63, 0.44, 0.20)
const LAUBSTREU_ROT := Color(0.60, 0.36, 0.17)

# Wald – Fels
const FELS := Color(0.50, 0.47, 0.42)
const FELS_HELL := Color(0.64, 0.61, 0.55)
const FELS_DUNKEL := Color(0.34, 0.31, 0.28)
const FELS_WARM := Color(0.60, 0.49, 0.35)
const FLECHTE := Color(0.62, 0.68, 0.50)
const MOOS := Color(0.21, 0.36, 0.14)
const MOOS_HELL := Color(0.35, 0.53, 0.21)
const KIES := Color(0.54, 0.51, 0.46)
const KIES_HELL := Color(0.76, 0.73, 0.67)

# Wasser
const WASSER := Color(0.13, 0.42, 0.52)
const WASSER_HELL := Color(0.35, 0.72, 0.78)

# Kisten
const HOLZ := Color(0.71, 0.40, 0.11)
const HOLZ_DUNKEL := Color(0.35, 0.20, 0.06)
const HOLZ_FUGE := Color(0.15, 0.08, 0.03)
## Fragezeichenkiste: eigenes Gelb. Vorher war sie eine gewöhnliche
## Holzkiste mit drei kleinen Früchten darauf – im Spiel nicht von einer
## normalen Kiste zu unterscheiden.
const KISTE_FRAGE := Color(0.93, 0.68, 0.10)
const KISTE_LEBEN := Color(0.26, 0.80, 0.40)
const KISTE_TNT := Color(0.80, 0.16, 0.13)
const KISTE_NITRO := Color(0.10, 0.55, 0.25)
const KISTE_FEDER := Color(0.95, 0.75, 0.20)
const KISTE_SPRUNG := Color(0.30, 0.55, 0.95)
const KISTE_EISEN := Color(0.55, 0.57, 0.62)
const KISTE_CHECKPOINT := Color(0.27, 0.80, 0.42)
const KISTE_SCHUTZ := Color(0.30, 0.68, 0.95)
## Zeitkiste: Violett ist die einzige Farbe, die im Kistenregal noch frei
## war – Gelb gehört der Feder, Blau dem Schutz, Grün dem Checkpoint.
const KISTE_ZEIT := Color(0.62, 0.40, 0.85)
const ROST := Color(0.46, 0.24, 0.11)
const ROST_HELL := Color(0.66, 0.38, 0.16)

# Spieler und Effekte
const FELL := Color(0.94, 0.44, 0.13)
const FELL_BAUCH := Color(0.98, 0.85, 0.66)
const FELL_DUNKEL := Color(0.62, 0.24, 0.06)
const NASE := Color(0.15, 0.11, 0.10)
const SPIN_RING := Color(1.0, 0.88, 0.40)
const FRUCHT := Color(1.0, 0.55, 0.13)
const FRUCHT_BLATT := Color(0.30, 0.60, 0.22)
const PORTAL_START := Color(0.35, 0.85, 0.55)
const PORTAL_ZIEL := Color(0.40, 0.85, 1.0)
const WARNUNG := Color(1.0, 0.30, 0.20)
## Edelsteine für die beiden Kunststücke je Level und der Schein um ein
## geschafftes Portal.
const EDELSTEIN_KISTEN := Color(0.40, 0.85, 1.0)     ## alle Kisten
const EDELSTEIN_OHNE_TOD := Color(1.0, 0.34, 0.42)   ## ohne einen Tod
const ERFOLG_SCHEIN := Color(1.0, 0.80, 0.38)

# Himmel und Nebel
# --- Sumpf (Level 03) ---
const MOOR := Color(0.20, 0.26, 0.17)          ## nasser Torfboden
const MOOR_HELL := Color(0.36, 0.42, 0.25)
const MOOR_DUNKEL := Color(0.11, 0.15, 0.10)
const TUEMPEL := Color(0.14, 0.28, 0.20)       ## trübes Standwasser
const TUEMPEL_HELL := Color(0.32, 0.52, 0.36)
const SCHILF := Color(0.52, 0.55, 0.28)
const ALGE := Color(0.34, 0.56, 0.24)
const BOHLE := Color(0.38, 0.29, 0.18)         ## verwittertes Steg-Holz

# --- Winter (Level 02) ---
const SCHNEE := Color(0.90, 0.93, 0.97)
const SCHNEE_HELL := Color(0.98, 0.99, 1.00)
const SCHNEE_SCHATTEN := Color(0.64, 0.73, 0.86)
const FIRN := Color(0.80, 0.85, 0.92)          ## festgetretener Trittschnee
const EIS := Color(0.52, 0.78, 0.88)
const EIS_HELL := Color(0.79, 0.94, 0.98)
const EIS_DUNKEL := Color(0.24, 0.48, 0.63)
const NADEL_FROST := Color(0.17, 0.34, 0.30)   ## verschneite Nadelbäume
const EIS_TIEF := Color(0.16, 0.34, 0.52)      ## Schluchtwand aus altem Eis
const FROSTFELS := Color(0.36, 0.42, 0.52)     ## Fels unter der Schneedecke
## Schluchtwand im Schnee: warmer Fels. In den Vorlagen ist im Eislevel
## nur das Eis kalt – der Fels bleibt braun-ocker, sonst wird das ganze
## Bild einfarbig blau.
const SCHLUCHTFELS := Color(0.58, 0.45, 0.35)
const SCHLUCHTFELS_HELL := Color(0.82, 0.68, 0.52)
## Schluchtwand im Wald: satter Erdton. Die Vorlagen halten den Waldgrund
## warm und dunkel, das Grün sitzt obenauf und am Wegrand.
const SCHLUCHTFELS_WALD := Color(0.46, 0.34, 0.22)
const SCHLUCHTFELS_WALD_HELL := Color(0.70, 0.55, 0.34)
const KRISTALL_BLAU := Color(0.38, 0.82, 1.0)
const KRISTALL_VIOLETT := Color(0.66, 0.48, 0.98)
const GLUT := Color(1.0, 0.58, 0.16)           ## Feuerschalen als Gegenfarbe
## Gegnerkörper im Schnee. Bewusst dunkel und satt: Auf weißem Grund
## verschwindet alles Helle, und die Referenzbilder zeigen durchweg
## dunkle Silhouetten mit hellen Akzenten nur dort, wo die Gefahr sitzt.
const FROSTTIER := Color(0.19, 0.26, 0.40)
const FROSTTIER_HELL := Color(0.34, 0.44, 0.60)
const FROSTTIER_BAUCH := Color(0.62, 0.70, 0.82)

const HIMMEL_OBEN := Color(0.29, 0.51, 0.72)
const HIMMEL_UNTEN := Color(0.62, 0.74, 0.78)
const NEBEL := Color(0.55, 0.66, 0.66)
