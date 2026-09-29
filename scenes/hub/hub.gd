extends Node3D
## Portalraum: eine große Halle, um die sich fünf Räume mit je fünf
## Levelportalen legen – ein Raum je Abschnitt (25 Level).
##
## Aufbau (alles prozedural in `_ready()`, die .tscn bleibt schlank):
##   * die Halle ist ein breites Bogenstück, gepflastert, mit einem
##     Mittelstein, dessen fünf Strahlen den Fortschritt je Raum zeigen
##   * darum liegen fünf Raumsektoren, jeder mit Torbogen, Namen und fünf
##     Portalen unter einer gemeinsamen Bogenreihe
##   * Mauern ringsum, damit niemand herausfallen kann; hinter der
##     Nordmauer Hügel und Baumkronen
##
## Warum ein Bogen und kein Kreis:
## Die Verfolgerkamera hält einen festen Winkel und steht immer südlich
## (+Z) des Spielers. Läge ein Raum südlich der Halle, liefe der Spieler
## auf die Kamera zu und seine Portale lägen HINTER ihr. Deshalb liegen
## alle fünf Räume nördlich der Halle, aufgereiht auf einem weiten Bogen
## um den Punkt `BOGEN_MITTE`. Jeder Raum wird "ins Bild hinein" betreten,
## und alle Portale schauen dem Spieler entgegen.
##
## Die Süd- und Seitenmauern sind einseitige Flächen, die nur nach innen
## zeigen. Von außen sind sie unsichtbar – so schaut die Kamera auch dann in
## den Raum, wenn sie hinter einer Mauer steht. Aus demselben Grund haben
## NUR die Rückwände der Räume Körper (Sockel, Gesims, Deckfläche,
## Wandpfeiler): Hinter der Nordmauer steht die Kamera nie. Eine Deckfläche
## auf der Südmauer läge dagegen als Balken quer über dem Bild – die Kamera
## steht beim Start 1,6 m über ihr, 4 m davor.
##
## LICHT (Hub.tscn): Die Sonne steht tief im Nordosten (gut 30 Grad hoch),
## hinter den Räumen. Die Rückwände liegen dadurch im Schatten und rahmen
## die leuchtenden Portale dunkel ein, der Hallenboden liegt in der Sonne –
## Lesbarkeitsvertrag: dunkler Rahmen, helle Lauffläche. Ein schwaches,
## kühles Himmelslicht kommt von Südwesten, von der Kameraseite: Es hebt
## die beschatteten, der Kamera zugewandten Wände und Bögen gerade so weit
## an, dass man ihren Stein noch sieht, und wirft keinen Schatten. Vorher
## schien es von unter dem Horizont nach oben und erreichte den Boden nie.
## Leuchten entsteht über das Glühen der Umgebung (Glow), nicht über
## Punktlichter: Unter gl_compatibility kostet jedes Punktlicht jedes
## Objekt in seiner Reichweite einen weiteren Durchgang, und ab acht
## Lichtern je Netz fallen welche weg. Was glühen soll, ist deshalb heller
## als 1 (Ringe, Flammen, Siegel, Strahlen des Mittelsteins); alles andere
## bleibt darunter.
##
## KOSTEN: Wiederkehrende Teile (Pflaster, Säulen und Bögen, Wandhalter,
## Fahnen, Flammen, Fortschrittssteine, Brüstung) sind je Raum oder für den
## ganzen Saal zu EINEM Netz zusammengefasst. Das Sperrgitter vor einem Raum
## bestand aus 43 Einzelnetzen, die Gitter vor 20 Portalen aus weiteren
## hundert – jetzt ist es ein Schleier aus einem Netz.
##
## TORPFEILER: Steht einer zwischen Kamera und Figur, löst er sich samt
## Fahne, Halter und Flamme in ein Pixelraster auf (`_torpfeiler_aufloesen`).
##
## WICHTIG: Position immer VOR `add_child()` setzen.

const BAUM := preload("res://scenes/props/Baum.tscn")
const STEIN := preload("res://scenes/props/Stein.tscn")
const KLEINZEUG := preload("res://scenes/props/Kleinzeug.tscn")
const GRASFELD := preload("res://scenes/props/Gras.tscn")
const WURZELPROP := preload("res://scenes/props/Wurzel.tscn")
const STAUB := preload("res://scenes/props/Staub.tscn")
const LAUBTREIBEN := preload("res://scenes/props/Laubtreiben.tscn")
const HORIZONT := preload("res://scenes/props/Horizont.tscn")

## Mittelpunkt des Bogens. Liegt weit südlich, außerhalb des Raums.
const BOGEN_MITTE := Vector3(0.0, 0.0, 36.0)
const RAUM_WINKEL := 21.0      ## Grad zwischen zwei Raummitten
const SEKTOR_HALB := 10.5      ## halbe Öffnung eines Raums in Grad
const SEITE := 52.5            ## äußerster Winkel (2,5 Räume je Seite)
const HALLE_R := 29.0          ## Südkante der Halle
const UEBERGANG_R := 41.0      ## Grenze Halle / Räume
const AUSSEN_R := 56.0         ## Nordmauer
const TOR_R := 41.6            ## Torbögen
const PORTAL_R := 51.0         ## Portalreihe
const PORTAL_ABSTAND := 3.6    ## seitlicher Abstand zweier Portale in Metern
const START_R := 33.5          ## Startplatz des Spielers

const WAND_HOEHE := 5.6
const KRANZ_HOEHE := 0.5
## Die Trennmauern zwischen den Räumen. Höher als der höchste erreichbare
## Sprung (Slide-Sprung 2,8 m plus Doppelsprung 1,4 m = 4,2 m) – sonst
## steht die Figur oben auf der Mauer statt davor.
const TEILER_HOEHE := 4.6
const TEILER_DICKE := 0.9
const SPERRE_HOEHE := 4.2      ## Siegel vor einem gesperrten Raum
const TOR_HOEHE := 6.2         ## Torpfeiler

## Ab diesem Abstand zur Kamera ist eine Torbeschriftung voll sichtbar;
## darunter blendet sie aus, damit sie beim Durchlaufen nicht das Bild
## zustellt.
const SCHRIFT_FERN := 19.0
const SCHRIFT_NAH := 11.0

# --- Pflaster ---
const PFLASTER_Y := 0.075      ## Oberkante der Steine
## Unterkante der Fase. Flach (gut 25 Grad): Eine steile Fase stand der
## tiefen Sonne fast senkrecht entgegen und zog um jeden Stein eine helle
## Linie – zusammen ein Gitter über die ganze Halle.
const PFLASTER_FUSS := 0.05
const FUGE_Y := 0.03           ## Fugenbett
## Schmale Fugen, schmale Fasen: Mit 9 cm fast schwarzer Fuge und heller
## Fase um jeden Stein las sich der Boden wie Rechenpapier und war das
## Unruhigste im Bild – lauter als die Portale.
const FUGE := 0.03             ## halbe Fugenbreite
const FASE := 0.05             ## waagerechte Breite der Kantenfase
const PLATTE_LAENGE := 1.7     ## mittlere Steinlänge entlang des Bogens
const PLATTEN_BAENDER := 9     ## Steinreihen zwischen Süd- und Torkante
## Warmer, heller Grundton des Pflasters: Die Lauffläche ist das Hellste
## und am wenigsten Gesättigte im Bild (Lesbarkeitsvertrag).
const PFLASTER_TON := Color(1.0, 0.96, 0.9)
const MITTELSTEIN_R := 3.45
const LEITLINIE_Y := 0.088

# --- Bogenreihe über den Portalen ---
const BOGEN_INNEN := 1.34
const BOGEN_AUSSEN := 1.74
const BOGEN_TIEFE := 0.56
const BOGEN_STEINE := 9
const BOGEN_ANSATZ := 20.0     ## Grad über der Waagerechten, wo der Bogen aufsitzt

# --- Torschmuck ---
const HALTER_Y := 2.9          ## Feuerschale am Torpfeiler
const FAHNE_OBEN := 5.95
const FAHNE_LAENGE := 2.0
const FAHNE_BREITE := 0.86

## Farben der Räume 4 und 5, aus ihren Leveln übernommen (level16.gd,
## level18.gd, level21.gd) – ein Raum soll aussehen wie das, was hinter
## seinen Toren liegt. Vorher trug Raum 4 noch Eiskristalle und Raum 5
## Lavarisse aus der Zeit, als sie „Frostkronen" und „Glutkessel" hießen.
const KANALGRUEN := Color(0.122, 0.298, 0.247)
const ROSTORANGE := Color(0.576, 0.282, 0.106)
const MESSING := Color(0.384, 0.306, 0.161)
const DSCHUNGEL := Color(0.10, 0.36, 0.18)
const DSCHUNGEL_HELL := Color(0.26, 0.56, 0.22)
const SAND := Color(0.78, 0.65, 0.42)
const SANDSTEIN := Color(0.61, 0.35, 0.14)
const SANDSTEIN_HELL := Color(0.80, 0.62, 0.36)

## Messington für den Rahmen der Siegeltafel.
const SIEGELRAHMEN := Color(0.62, 0.5, 0.3)
## Platzhalter für „keine Scheitelfarbe".
const KEINE_FARBE := Color(0.0, 0.0, 0.0, 0.0)
## Merkt sich (je Speicherplatz), welche Räume schon offen gesehen wurden.
## Ein Raum, der seit dem letzten Besuch aufgegangen ist, bekommt einmal
## das Entsiegeln zu sehen. Nur Laufzeit – nichts davon wird gespeichert.
const GESEHEN_META := "portalraum_offene_raeume_%d"

## Die sechs Flächen eines Hexaeders: Ecken 0–3 unten, 4–7 oben, jeweils
## im Umlauf.
const _SEITEN := [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5],
		[2, 3, 7, 6], [3, 0, 4, 7]]

## Siegel vor einem verschlossenen Raum: ein Schleier aus Licht mit
## Rautengitter, der nach oben ausläuft, in der Mitte ein Schloss-Zeichen.
## Kühles Violett statt Warnrot – Rot ist im Spiel die Farbe der Gefahr, und
## das Gitter mit rotem Band las sich beim ersten Betreten wie ein Gefängnis.
## Gemischt, nicht additiv: Vor dem sonnigen Boden brennte Additiv zu Weiß.
## UV.x = Meter entlang des Bogens, UV.y = 0 (Boden) bis 1 (Oberkante).
const SIEGEL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 farbe : source_color = vec4(0.55, 0.45, 0.85, 1.0);
uniform float laenge = 14.0;
uniform float hoehe = 4.2;
uniform float zeichen_y = 2.4;
uniform float deckkraft = 1.0;

float _linie(float d, float breite) {
	return 1.0 - smoothstep(breite * 0.5, breite, d);
}

void fragment() {
	vec2 p = vec2(UV.x, UV.y * hoehe);
	// Rautengitter mit 0,9 m Maschen
	float a = abs(fract((p.x + p.y) / 0.9) - 0.5);
	float b = abs(fract((p.x - p.y) / 0.9) - 0.5);
	float gitter = max(_linie(0.5 - a, 0.08), _linie(0.5 - b, 0.08));
	// Langsame Lichtwelle, die nach oben steigt
	float welle = 0.5 + 0.5 * sin(p.y * 2.2 - TIME * 1.3 + p.x * 0.35);
	float oben = 1.0 - smoothstep(0.3, 1.0, UV.y);
	// smoothstep nur mit steigenden Kanten: umgekehrt ist es in GLSL ES 3.0
	// undefiniert, und manche Mobiltreiber rechnen dann Unsinn.
	float seiten = smoothstep(0.0, 0.5, p.x) * (1.0 - smoothstep(laenge - 0.5, laenge, p.x));

	// Siegel: zwei Ringe und ein Schlüsselloch
	vec2 q = p - vec2(laenge * 0.5, zeichen_y);
	float r = length(q);
	float ring = _linie(abs(r - 0.8), 0.09) + _linie(abs(r - 0.62), 0.05);
	float loch = 1.0 - smoothstep(0.13, 0.16, length(q - vec2(0.0, 0.1)));
	float keil = step(abs(q.x), 0.05 + (0.1 - q.y) * 0.2) * step(-0.3, q.y) * step(q.y, 0.1);
	float zeichen = clamp(ring + loch + keil, 0.0, 1.0);

	float g = gitter * (0.16 + 0.3 * welle);
	// Das Zeichen glüht in der Farbe des Siegels. Mit einem weißen Anteil las
	// es sich wie ein Symbol aus dem Menü, nicht wie ein Siegel im Raum.
	vec3 licht = farbe.rgb * (0.6 + 1.2 * g) + (farbe.rgb * 1.2 + vec3(0.15)) * zeichen;
	ALBEDO = licht;
	ALPHA = clamp(((0.1 + 0.08 * welle) + g) * oben + zeichen * 0.92, 0.0, 1.0)
			* seiten * deckkraft;
}
"""

## Leitlinien im Pflaster: Lichtpulse laufen vom Mittelstein zu jedem
## offenen Raum. Gemischt, nicht additiv: Auf dem hellen Pflaster brannte
## ein additiver Puls zu einem weißen Strich aus, jetzt behält er die Farbe
## des Raums. UV.x = Meter ab dem Mittelstein, UV.y = 0..1 quer,
## UV2.x = 0..1 entlang der Linie, COLOR = Farbe des Raums.
const LAUFLICHT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float tempo = 0.4;
uniform float abstand = 3.2;
uniform float staerke = 1.5;

void fragment() {
	// Der Kopf jedes Pulses liegt vorn (zum Raum hin), der Schweif dahinter.
	float s = fract(UV.x / abstand - TIME * tempo);
	float puls = pow(s, 5.0) * (1.0 - smoothstep(0.94, 1.0, s));
	float quer = 1.0 - abs(UV.y * 2.0 - 1.0);
	float enden = smoothstep(0.0, 0.06, UV2.x) * (1.0 - smoothstep(0.9, 1.0, UV2.x));
	ALBEDO = COLOR.rgb * staerke;
	ALPHA = 0.85 * puls * smoothstep(0.0, 0.6, quer) * enden;
}
"""

## Gemeinsamer Teil der Shader für den Torschmuck (Flammen, Fahnen,
## Halter): Jedes Teil löst sich mit seinem Torpfeiler auf. Die Weite kommt
## je Torseite aus einer Liste; der Vertex-Shader liest sie (dort ist
## beliebiges Indizieren überall erlaubt) und reicht sie weiter.
const AUFLOESEN_GLSL := """
// Auflösen vor der Kamera (siehe `_torpfeiler_aufloesen`): je Torseite
// die Weite der Überblendung, 0 = ganz da. Dasselbe Pixelraster wie Godots
// Distance Fade am Pfeiler selbst – Pfeiler, Fahne, Halter und Flamme
// lösen sich gemeinsam auf.
uniform float aufloesen[10];

float _weite(float seite) {
	int i = int(seite + 0.5);
	return (i >= 0 && i < 10) ? aufloesen[i] : 0.0;
}

bool _weg(float bis, vec3 ansicht, vec2 pixel) {
	if (bis <= 0.02) {
		return false;
	}
	float deckung = smoothstep(0.0, bis, length(ansicht));
	return deckung < 0.001
			|| deckung < fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}
"""

## Flammen der Feuerschalen – alle in EINEM MultiMesh. Die Form entsteht im
## Shader (Tropfen mit flackernder Spitze), gedreht wird nur um die
## Senkrechte: Eine Flamme kippt nicht, wenn die Kamera von oben schaut.
## Instanzfarbe: RGB = Flammenfarbe, Alpha = Phase. Die Instanzgröße ist
## die der Flamme; das Viereck ist größer, denn um die Flamme liegt ein
## weicher Hof aus Licht – ohne ihn waren es harte kleine Kerzentropfen.
##
## Vormultipliertes Alpha: Die Flamme deckt (Alpha = Form), der Hof hat
## Alpha 0 und wird nur addiert. So hellt er Pfeiler und Fahne auf, ohne
## sie grau zu überdecken – beides in EINEM Zeichenaufruf.
const FLAMME_SHADER := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, cull_disabled, depth_draw_never, shadows_disabled,
		fog_disabled, skip_vertex_transform;

const float HOF_BREITE = 2.4;   // Viereck = 2,4 Flammenbreiten
const float HOF_UNTEN = 0.45;   // reicht so weit unter den Fuß …
const float HOF_OBEN = 1.5;     // … und so weit hinauf (in Flammenhöhen)
const float HOF_MITTE = 0.45;
const float HOF_HOCH = 0.9;

varying vec3 ton;
varying float phase;
// Flammenkoordinaten: x -1..1 über die Flammenbreite, y 0 (Fuß) bis 1 (Spitze)
varying vec2 fl;
varying float weite;

""" + AUFLOESEN_GLSL + """
void vertex() {
	ton = COLOR.rgb;
	phase = COLOR.a * 6.2831;
	weite = _weite(INSTANCE_CUSTOM.r);
	float breite = length(MODEL_MATRIX[0].xyz);
	float hoehe = length(MODEL_MATRIX[1].xyz);
	vec3 fuss = MODEL_MATRIX[3].xyz;
	vec3 zur_kamera = normalize(INV_VIEW_MATRIX[3].xyz * vec3(1.0, 0.0, 1.0)
			- fuss * vec3(1.0, 0.0, 1.0) + vec3(0.0001));
	vec3 rechts = normalize(cross(vec3(0.0, 1.0, 0.0), zur_kamera));
	fl = vec2(VERTEX.x * 2.0 * HOF_BREITE, mix(-HOF_UNTEN, HOF_OBEN, VERTEX.y + 0.5));
	vec3 welt = fuss + rechts * fl.x * 0.5 * breite + vec3(0.0, fl.y * hoehe, 0.0);
	VERTEX = (VIEW_MATRIX * vec4(welt, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(zur_kamera, 0.0)).xyz);
}

void fragment() {
	if (_weg(weite, VERTEX, FRAGCOORD.xy)) {
		discard;
	}
	vec2 p = fl;
	float t = TIME * 7.0 + phase;
	// Die Spitze zuckt, der Fuß bleibt ruhig.
	float y = p.y / (0.84 + 0.09 * sin(t) + 0.05 * sin(t * 2.3 + 1.0));
	float x = p.x + sin(t * 0.8 + p.y * 5.0) * 0.14 * p.y;
	float yc = clamp(y, 0.0, 1.0);
	float w = 0.95 * pow(1.0 - yc, 1.15) * sqrt(clamp(yc * 5.0, 0.0, 1.0));
	float kante = abs(x) / max(w, 0.001);
	float form = (1.0 - smoothstep(0.6, 1.0, kante)) * step(0.0, y) * step(y, 1.0);
	float kern = (1.0 - smoothstep(0.0, 0.65, kante)) * (1.0 - smoothstep(0.1, 0.65, y));
	vec3 flamme = mix(ton, vec3(1.0, 0.94, 0.78), kern * 0.55) * (1.25 + 1.1 * kern);
	// Hof: weiche Ellipse um die Flammenmitte, am Rand des Vierecks auf null.
	vec2 h = vec2(p.x / HOF_BREITE, (p.y - HOF_MITTE) / HOF_HOCH);
	float d = length(h);
	float hof = exp(-d * d * 4.0) * (1.0 - smoothstep(0.7, 1.0, d));
	hof *= 0.9 + 0.1 * sin(t * 0.9);
	ALBEDO = flamme * form + ton * hof * 0.42;
	ALPHA = form;
}
"""

## Fahnen an den Torpfeilern, alle Fahnen des Saals in einem Netz. Der Stoff
## bewegt sich im Vertex-Shader (unten mehr als oben), das Wappen des Raums
## entsteht im Fragment-Shader aus einfachen Formen – keine Textur.
## UV = 0..1 (y nach unten), UV2.x = Wappen (0 Blatt, 1 Tropfen, 2 Turm,
## 3 Zahnrad, 4 Sonne), UV2.y = Phase, COLOR.rgb = Grundton,
## COLOR.a = Torseite (siehe `_seitenfarbe`).
const FAHNE_SHADER := """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 zier : source_color = vec4(0.96, 0.86, 0.58, 1.0);
varying float wappen;
varying float weite;

""" + AUFLOESEN_GLSL + """
float _flaeche(float d) {
	return 1.0 - smoothstep(-0.006, 0.006, d);
}

float _zeichen(vec2 q, float art) {
	float r = length(q);
	float w = atan(q.y, q.x);
	if (art < 0.5) {
		// Blatt: Linse aus zwei Kreisen, dazu der Stiel
		float blatt = max(length(q - vec2(0.12, 0.0)), length(q + vec2(0.12, 0.0))) - 0.24;
		float stiel = max(abs(q.x) - 0.012, abs(q.y - 0.22) - 0.07);
		return _flaeche(min(blatt, stiel));
	} else if (art < 1.5) {
		// Tropfen: runder Bauch, Spitze nach oben
		float bauch = length(q - vec2(0.0, 0.06)) - 0.15;
		float spitze = max(abs(q.x) - (q.y + 0.24) * 0.46, max(-0.24 - q.y, q.y - 0.05));
		return _flaeche(min(bauch, spitze));
	} else if (art < 2.5) {
		// Turm mit Zinnen
		float schaft = max(abs(q.x) - 0.12, abs(q.y - 0.03) - 0.18);
		float zinnen = max(abs(q.x) - 0.16, abs(q.y + 0.19) - 0.05);
		float luecke = step(0.5, fract((q.x + 0.16) / 0.107));
		float tor = max(abs(q.x) - 0.045, abs(q.y - 0.15) - 0.06);
		return _flaeche(max(min(schaft, zinnen + luecke), -tor));
	} else if (art < 3.5) {
		// Zahnrad
		float zahn = step(0.5, fract(w * 8.0 / 6.2831));
		return _flaeche(max(r - (0.15 + 0.05 * zahn), 0.065 - r));
	}
	// Sonne
	float strahl = step(0.55, fract(w * 12.0 / 6.2831));
	float kern = r - 0.1;
	float kranz = max(max(r - 0.23, 0.14 - r), strahl - 0.5);
	return _flaeche(min(kern, kranz));
}

void vertex() {
	wappen = UV2.x;
	weite = _weite(COLOR.a * 16.0 - 1.0);
	float frei = UV.y * UV.y;
	float t = TIME * 1.4 + UV2.y * 6.2831;
	VERTEX += NORMAL * (sin(t + UV.y * 2.6) * 0.09 + sin(t * 1.7 + UV.x * 3.0) * 0.03) * frei;
}

void fragment() {
	if (_weg(weite, VERTEX, FRAGCOORD.xy)) {
		discard;
	}
	vec2 uv = UV;
	// Schwalbenschwanz unten
	float kerbe = 0.9 + abs(uv.x - 0.5) * 0.2;
	if (uv.y > kerbe) {
		discard;
	}
	float rand = max(max(step(uv.x, 0.07), step(0.93, uv.x)),
			max(step(uv.y, 0.045), step(kerbe - 0.045, uv.y)));
	vec2 q = (uv - vec2(0.5, 0.34)) * vec2(1.0, 2.3);
	float zeichen = _zeichen(q, wappen);
	vec3 grund = COLOR.rgb * (0.9 + 0.1 * sin(uv.y * 40.0));
	vec3 stoff = mix(grund, zier.rgb, max(rand * 0.85, zeichen));
	ALBEDO = stoff;
	// Ein Hauch Eigenleuchten: Die Sonne steht hinter den Toren, und im
	// Gegenlicht las sich jede Fahne fast schwarz – Raumfarbe und Wappen
	// waren weg. So scheint der Stoff wie von hinten durchleuchtet.
	EMISSION = stoff * 0.28;
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
}
"""

## Halter, Schalen und Fahnenstangen am Torpfeiler, alle in einem Netz.
## Wie ein StandardMaterial mit Scheitelfarbe (sRGB), nur dass sich jeder
## Halter mit seinem Pfeiler auflösen kann. COLOR.a = Torseite.
const HALTER_SHADER := """
shader_type spatial;

varying vec3 ton;
varying float weite;

""" + AUFLOESEN_GLSL + """
void vertex() {
	vec3 c = COLOR.rgb;
	ton = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92),
			lessThan(c, vec3(0.04045)));
	weite = _weite(COLOR.a * 16.0 - 1.0);
}

void fragment() {
	if (_weg(weite, VERTEX, FRAGCOORD.xy)) {
		discard;
	}
	ALBEDO = ton;
	ROUGHNESS = 0.55;
	METALLIC = 0.35;
}
"""


## Rundgang nur für die Bildvorschau (`werkzeuge/foto.sh`): Das Werkzeug
## setzt den Spieler auf diese Kurve und fotografiert mit der Spielkamera.
## Für das Spiel selbst hat die Kurve keine Bedeutung.
var verlauf: Curve3D

var _geometrie: Node3D
var _objekte: Node3D
var _deko: Node3D
var _beschriftungen: Array[Label3D] = []
## Getönte Abwandlungen geteilter Materialien, einmal je Szene gebaut.
var _stoffe: Dictionary[String, Material] = {}
## Wird beim Bauen auf alle UVs addiert – so zeigt jeder Pflasterstein
## einen anderen Ausschnitt der Felstextur.
var _uv_versatz := Vector2.ZERO
## Orte der Torpfeiler (für die Schattenkanten im Pflaster).
var _torpfeiler: Array[Vector3] = []

# --- Sammler für den Torschmuck aller Räume (siehe `_baue_torschmuck`) ---
var _st_halter: SurfaceTool
var _st_fahnen: SurfaceTool
var _st_perlen_hell: SurfaceTool
var _st_perlen_matt: SurfaceTool
var _flammen: Array[Transform3D] = []
var _flammenfarben: Array[Color] = []
## Räume, die in diesem Besuch entsiegelt werden (Index 0-basiert).
var _entsiegeln: Array[int] = []
## Die zehn Torpfeiler, die sich vor der Kamera auflösen können, und die
## Sammelnetz-Materialien, die ihre Werte als Liste bekommen (Halter,
## Fahnen, Flammen – jedes Teil trägt die Nummer seiner Torseite).
var _torseiten: Array[Torseite] = []
var _aufloesen := PackedFloat32Array()
var _aufloesstoffe: Array[ShaderMaterial] = []
var _seite_nr := 0
var _flammenseiten: Array[int] = []
var _spieler_knoten: Node3D = null
var _siegel_neu: Dictionary[int, MeshInstance3D] = {}

static var _shader: Dictionary[String, Shader] = {}


## Ein Torpfeiler samt Kragstein und Kappe, der sich in ein Pixelraster
## auflöst, wenn er der Kamera den Blick auf die Figur verstellt.
class Torseite:
	var ort := Vector2.ZERO
	var stoffe: Array[StandardMaterial3D] = []
	var durchsicht := 0.0


func _ready() -> void:
	_geometrie = _gruppe("Geometrie")
	_objekte = _gruppe("Objekte")
	_deko = _gruppe("Deko")

	_st_halter = _neuer_bauer()
	_st_fahnen = _neuer_bauer()
	_st_perlen_hell = _neuer_bauer()
	_st_perlen_matt = _neuer_bauer()
	_offene_raeume_abgleichen()

	_baue_boden()
	_baue_mauern()
	_baue_umland()

	for i in Spielfluss.RAEUME:
		_baue_raum(i, raumwinkel(i))
	_baue_torschmuck()
	_baue_hallenluft()
	# Dieselben dunklen Bildecken wie in Level 01, nur schwächer und kühler:
	# Sie rahmen die leuchtenden Tore, ohne die HUD-Ecken zu schlucken.
	Bildrahmen.einsetzen(self, 0.25, Color(0.03, 0.03, 0.05), 0.03)

	_baue_rundgang()
	_spieler_setzen()
	_wegweiser_setzen()
	# Der Portalraum ist der einzige Ort, an dem gespeichert wird.
	Spielfluss.speichern()
	# Der Portalraum wird über den Ladebildschirm betreten – er steht jetzt.
	Ladeschirm.verbergen()
	_nach_dem_einblenden()


## Pfeil über dem Spieler, der auf das nächste offene Portal zeigt.
func _wegweiser_setzen() -> void:
	var pfeil := Wegweiser.new()
	pfeil.name = "Wegweiser"
	_objekte.add_child(pfeil)


func _gruppe(bezeichnung: String) -> Node3D:
	var knoten := Node3D.new()
	knoten.name = bezeichnung
	add_child(knoten)
	return knoten


## Mittelwinkel eines Raums (0-basiert). Raum 3 liegt geradeaus.
static func raumwinkel(index: int) -> float:
	return (float(index) - 2.0) * RAUM_WINKEL


# ------------------------------------------------------------- Hilfsmittel

## Punkt in Bogenkoordinaten: `grad` um `BOGEN_MITTE`, 0° zeigt nach -Z
## (ins Bild hinein), positive Winkel nach rechts.
static func ort(grad: float, radius: float, hoehe := 0.0) -> Vector3:
	var t := deg_to_rad(grad)
	return BOGEN_MITTE + Vector3(sin(t) * radius, hoehe, -cos(t) * radius)


## Wie `ort`, aber um einen beliebigen Mittelpunkt (Mittelstein).
static func _um(mitte: Vector3, grad: float, radius: float, hoehe: float) -> Vector3:
	var t := deg_to_rad(grad)
	return Vector3(mitte.x + sin(t) * radius, hoehe, mitte.z - cos(t) * radius)


## Platz in einem Raum: `tiefe` = Abstand vom Bogenmittelpunkt,
## `seitlich` = Meter rechts der Raummitte.
static func stelle(grad_mitte: float, tiefe: float, seitlich: float,
		hoehe := 0.0) -> Vector3:
	return ort(grad_mitte + rad_to_deg(seitlich / tiefe), tiefe, hoehe)


## Drehung um Y, sodass die +Z-Achse eines Objekts nach außen zeigt.
static func nach_aussen(grad: float) -> float:
	return PI - deg_to_rad(grad)


## Waagerechte Richtung von der Bogenmitte nach außen.
static func _aussen(grad: float) -> Vector3:
	var t := deg_to_rad(grad)
	return Vector3(sin(t), 0.0, -cos(t))


## Waagerechte Richtung entlang des Bogens (nach rechts).
static func _quer(grad: float) -> Vector3:
	var t := deg_to_rad(grad)
	return Vector3(cos(t), 0.0, sin(t))


## Winkel eines Punkts um die Bogenmitte (Umkehrung von `ort`).
static func _winkel_von(p: Vector3) -> float:
	return rad_to_deg(atan2(p.x - BOGEN_MITTE.x, BOGEN_MITTE.z - p.z))


func _neuer_bauer() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		normale: Vector3, farbe := KEINE_FARBE) -> void:
	var n := normale.normalized()
	# Godot zeichnet die Vorderseite bei Punkten im Uhrzeigersinn.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tausch := b
		b = c
		c = tausch
	for p: Vector3 in [a, b, c]:
		if farbe.a > 0.0:
			st.set_color(farbe)
		st.set_normal(n)
		if absf(n.y) > 0.7:
			st.set_uv(Vector2(p.x, p.z) * 0.25 + _uv_versatz)
		else:
			st.set_uv(Vector2(p.x + p.z, -p.y) * 0.25 + _uv_versatz)
		st.add_vertex(p)


func _viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normale: Vector3, farbe := KEINE_FARBE) -> void:
	_dreieck(st, a, b, c, normale, farbe)
	_dreieck(st, b, d, c, normale, farbe)


## Beliebiger konvexer Block aus acht Ecken (0–3 unten, 4–7 oben, jeweils
## im Umlauf). Die Normalen zeigen immer vom Schwerpunkt weg.
func _hexaeder(st: SurfaceTool, e: PackedVector3Array, farbe := KEINE_FARBE,
		ohne_boden := false) -> void:
	var schwerpunkt := Vector3.ZERO
	for p in e:
		schwerpunkt += p
	schwerpunkt /= float(e.size())
	for i in _SEITEN.size():
		if ohne_boden and i == 0:
			continue
		var f: Array = _SEITEN[i]
		var a := e[int(f[0])]
		var b := e[int(f[1])]
		var c := e[int(f[2])]
		var d := e[int(f[3])]
		var n := (c - a).cross(d - b)
		if n.length_squared() < 1e-10:
			continue
		n = n.normalized()
		if n.dot((a + b + c + d) * 0.25 - schwerpunkt) < 0.0:
			n = -n
		_dreieck(st, a, b, c, n, farbe)
		_dreieck(st, a, c, d, n, farbe)


## Quader mit Mitte, Größe und Drehung. Ohne Boden: Er steht auf etwas.
func _kasten(st: SurfaceTool, mitte: Vector3, groesse: Vector3, basis: Basis,
		farbe := KEINE_FARBE, ohne_boden := true) -> void:
	var h := groesse * 0.5
	var e := PackedVector3Array()
	for y: float in [-1.0, 1.0]:
		for xz: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			e.append(mitte + basis * Vector3(xz.x * h.x, y * h.y, xz.y * h.z))
	_hexaeder(st, e, farbe, ohne_boden)


## Waagerechtes Bogenstück als Boden.
func _bogenflaeche(st: SurfaceTool, r_innen: float, r_aussen: float,
		von: float, bis: float, hoehe: float, schritte: int) -> void:
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		_viereck(st, ort(g0, r_innen, hoehe), ort(g0, r_aussen, hoehe),
				ort(g1, r_innen, hoehe), ort(g1, r_aussen, hoehe), Vector3.UP)


## Röhre aus `seiten` Flächen von `von` nach `bis`.
func _rohr(st: SurfaceTool, von: Vector3, bis: Vector3, radius: float,
		seiten: int = 8) -> void:
	var achse := (bis - von).normalized()
	var hilf := Vector3.UP if absf(achse.y) < 0.9 else Vector3.RIGHT
	var u := achse.cross(hilf).normalized()
	var v := achse.cross(u).normalized()
	for i in seiten:
		var w0 := TAU * float(i) / float(seiten)
		var w1 := TAU * float(i + 1) / float(seiten)
		var r0 := (u * cos(w0) + v * sin(w0)) * radius
		var r1 := (u * cos(w1) + v * sin(w1)) * radius
		var n := (r0 + r1).normalized()
		_viereck(st, von + r0, bis + r0, von + r1, bis + r1, n)


func _flaeche_anhaengen(elternteil: Node3D, st: SurfaceTool, material: Material,
		bezeichnung: String, schatten := true) -> MeshInstance3D:
	st.index()
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = bezeichnung
	mi.mesh = mesh
	mi.material_override = material
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(mi)
	return mi


## Instanziiert ein Prop, setzt seine Werte und hängt es ein.
## Position wird vor `add_child()` gesetzt – sonst springen Props zurück.
func _prop(szene: PackedScene, pos: Vector3, werte: Dictionary = {},
		drehung := 0.0) -> Node3D:
	var knoten := szene.instantiate() as Node3D
	for schluessel in werte:
		knoten.set(schluessel, werte[schluessel])
	knoten.position = pos
	knoten.rotation.y = drehung
	_deko.add_child(knoten)
	return knoten


func _quader(elternteil: Node3D, pos: Vector3, groesse: Vector3,
		material: Material, drehung := 0.0, schatten := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = groesse
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation.y = drehung
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elternteil.add_child(mi)
	return mi


## Getönte Abwandlung eines geteilten Materials. Die Bibliothek gibt geteilte
## Materialien heraus, die NIE verändert werden dürfen – deshalb eine flache
## Kopie (Texturen bleiben geteilt, es entsteht keine neue Textur).
func _getoent(grund: StandardMaterial3D, ton: Color, schluessel: String) -> StandardMaterial3D:
	if _stoffe.has(schluessel):
		return _stoffe[schluessel] as StandardMaterial3D
	var m := grund.duplicate() as StandardMaterial3D
	m.albedo_color = ton
	_stoffe[schluessel] = m
	return m


## Material mit Scheitelfarbe (für zusammengefasste Netze in mehreren Tönen).
func _scheitelstoff(grund: StandardMaterial3D, ton: Color, schluessel: String) -> StandardMaterial3D:
	var m := _getoent(grund, ton, schluessel)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	return m


static func _shader_holen(schluessel: String, code: String) -> Shader:
	if not _shader.has(schluessel):
		var s := Shader.new()
		s.code = code
		_shader[schluessel] = s
	return _shader[schluessel]


## Schatten für ein Prop samt Unterbau abschalten (Kulisse hinter Mauern).
func _ohne_schatten(knoten: Node) -> void:
	if knoten is GeometryInstance3D:
		(knoten as GeometryInstance3D).cast_shadow = \
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for kind in knoten.get_children():
		_ohne_schatten(kind)


## Neues Material für alle Netze unter einem Prop (Kollision bleibt).
func _umfaerben(knoten: Node, stoff: Material) -> void:
	if knoten is MeshInstance3D:
		(knoten as MeshInstance3D).material_override = stoff
	for kind in knoten.get_children():
		_umfaerben(kind, stoff)


# --------------------------------------------------------------- Grundriss

## Böden: Pflaster für die Halle, ein Bogenstück je Raum. Die Kollision
## übernimmt ein einziger flacher Kasten unter allem – das ist deutlich
## billiger als eine Trimesh-Kollision je Fläche.
func _baue_boden() -> void:
	var koerper := StaticBody3D.new()
	koerper.name = "Boden"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	koerper.position = Vector3(0.0, -0.75, BOGEN_MITTE.z - AUSSEN_R * 0.5)
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(AUSSEN_R * 2.0, 1.5, AUSSEN_R + 4.0)
	form.shape = box
	koerper.add_child(form)
	_geometrie.add_child(koerper)

	# Sockel: ragt unter den Mauern hervor. Die Kamera steht beim Laufen
	# oft außerhalb der Mauern – ohne diesen Rand sähe sie dort ins Leere.
	# Wiese statt Fels: Der Saal liegt in einer Landschaft, nicht auf einer
	# grauen Platte. Dunkel und matt – in der Sonne leuchtete sie sonst als
	# grelle, leere Rasenfläche unter der Südkante und sah begehbar aus.
	var sockel := _neuer_bauer()
	_bogenflaeche(sockel, HALLE_R - 7.0, AUSSEN_R + 3.5, -SEITE - 6.0,
			SEITE + 6.0, -0.09, 22)
	_flaeche_anhaengen(_geometrie, sockel, _getoent(Materialbibliothek.gras(),
			Color(0.32, 0.36, 0.25), "wiese"), "Sockel", false)

	# Fugenbett: derselbe Stein, nur dunkler. Moosgrün zeichnete ein grelles
	# Gitter über die Halle, fast schwarze Erde ein hartes – so trennt die
	# Fuge die Steine, ohne selbst zum Muster zu werden.
	var halle := _neuer_bauer()
	_bogenflaeche(halle, HALLE_R, UEBERGANG_R + 0.6, -SEITE, SEITE, FUGE_Y, 30)
	_flaeche_anhaengen(_geometrie, halle, Materialbibliothek.einfarbig(
			PFLASTER_TON.darkened(0.55), 0.95), "Hallenboden", false)

	for i in Spielfluss.RAEUME:
		var grad := raumwinkel(i)
		var breite := _torbreite()
		for vorzeichen: float in [-1.0, 1.0]:
			_torpfeiler.append(stelle(grad, TOR_R, vorzeichen * breite * 0.5))

	var pflaster := _neuer_bauer()
	var einlage := _neuer_bauer()
	var strahlen := _neuer_bauer()
	var pulse := _neuer_bauer()
	_baue_pflaster(pflaster)
	_baue_randstein(pflaster)
	_baue_bruestung()
	_baue_schwellen(pflaster)
	_baue_mittelstein(pflaster, einlage, strahlen)
	_baue_leitlinien(einlage, pulse)
	_uv_versatz = Vector2.ZERO

	# Das Pflaster wirft keinen Schatten (es liegt flach), empfängt aber.
	# Heller als der rohe Fels, aber nicht die hellste Fläche im Bild – die
	# gehört den Portalen. Mit 1,2 blendete der Boden in der Sonne.
	var pflasterstoff := _scheitelstoff(Materialbibliothek.fels(),
			Color(1.06, 1.03, 0.98), "pflaster")
	# Niedrige Texturfrequenz: Auf einem 1,7-m-Stein wirkte das Felsmuster
	# unruhig wie Geröll; so trägt jeder Stein nur ruhige, große Flecken.
	pflasterstoff.uv1_scale = Vector3(0.3, 0.3, 1.0)
	_flaeche_anhaengen(_geometrie, pflaster, pflasterstoff, "Pflaster", false)
	_flaeche_anhaengen(_geometrie, einlage,
			Materialbibliothek.einfarbig(Color(0.72, 0.56, 0.28), 0.4, 0.45),
			"Messing", false)
	var strahlstoff := StandardMaterial3D.new()
	strahlstoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strahlstoff.vertex_color_use_as_albedo = true
	strahlstoff.vertex_color_is_srgb = true
	# Über 1: Nur die Strahlen geschaffter Räume sollen glühen, deren
	# Scheitelfarbe ist deshalb voll, die der übrigen gedämpft.
	strahlstoff.albedo_color = Color(1.6, 1.6, 1.6)
	_flaeche_anhaengen(_geometrie, strahlen, strahlstoff, "Mittelstein_Strahlen", false)
	var pulsstoff := ShaderMaterial.new()
	pulsstoff.shader = _shader_holen("lauflicht", LAUFLICHT_SHADER)
	_flaeche_anhaengen(_geometrie, pulse, pulsstoff, "Leitlinien", false)


## Pflaster der Halle: neun Steinreihen im Verband, jeder Stein mit Fase
## und eigenem Ton. EIN Netz für die ganze Halle (rund 3500 Dreiecke).
##
## Die Scheitelfarbe trägt drei Dinge, die sonst Licht kosten würden:
##   * Streuung: kein Stein gleicht dem Nachbarn (hell/dunkel, warm/kühl)
##   * Verdeckung: dunkler an der Südkante und um die Torpfeiler
##   * Laufspuren: heller in den fünf Achsen zu den Räumen – ein
##     ausgetretener Weg, der unaufdringlich zum Tor führt
## Die Werte bleiben ruhig (0,9–1,0): Der Boden soll kein Muster werden.
func _baue_pflaster(st: SurfaceTool) -> void:
	var zufall := RandomNumberGenerator.new()
	zufall.seed = 20260928
	var mittelpunkt := ort(0.0, START_R)
	var r0 := HALLE_R
	var r1 := UEBERGANG_R + 0.6
	var tiefe := (r1 - r0) / float(PLATTEN_BAENDER)
	for band in PLATTEN_BAENDER:
		var ri := r0 + tiefe * float(band)
		var ra := ri + tiefe
		var rm := (ri + ra) * 0.5
		var g := -SEITE
		# Versetzte Fugen wie im Mauerverband: Das erste Stück jeder Reihe
		# ist verschieden lang.
		var laenge := PLATTE_LAENGE * zufall.randf_range(0.35, 1.0)
		while g < SEITE - 0.01:
			var g1 := minf(g + rad_to_deg(laenge / rm), SEITE)
			# Kein Splitter am Ende: den Rest dem letzten Stein zuschlagen.
			if deg_to_rad(SEITE - g1) * rm < PLATTE_LAENGE * 0.45:
				g1 = SEITE
			var zentrum := ort((g + g1) * 0.5, rm)
			var ton := _plattenfarbe(zufall, zentrum, rm)
			var hoehe := PFLASTER_Y + zufall.randf_range(-0.006, 0.006)
			_uv_versatz = Vector2(zufall.randf(), zufall.randf()) * 4.0
			# Unter dem Mittelstein liegt kein Pflaster.
			if zentrum.distance_to(mittelpunkt) > MITTELSTEIN_R - 0.9:
				_platte(st, BOGEN_MITTE, ri, ra, g, g1, ton, hoehe)
			g = g1
			laenge = PLATTE_LAENGE * zufall.randf_range(0.75, 1.25)


func _plattenfarbe(zufall: RandomNumberGenerator, zentrum: Vector3, rm: float) -> Color:
	var hell := zufall.randf_range(0.9, 1.0)
	var ton := zufall.randf_range(-1.0, 1.0)
	var farbe := Color(PFLASTER_TON.r * hell * (1.0 + 0.04 * ton),
			PFLASTER_TON.g * hell, PFLASTER_TON.b * hell * (1.0 - 0.06 * ton))
	if rm < HALLE_R + 1.0:
		farbe = farbe.darkened(0.14)
	for pfeiler in _torpfeiler:
		var d := Vector2(zentrum.x - pfeiler.x, zentrum.z - pfeiler.z).length()
		if d < 1.8:
			farbe = farbe.darkened(0.18 * (1.0 - d / 1.8))
	var g := _winkel_von(zentrum)
	for i in Spielfluss.RAEUME:
		var seitlich := absf(deg_to_rad(g - raumwinkel(i))) * rm
		if seitlich < 1.1 and rm > START_R - 1.0:
			farbe = farbe.lightened(0.07 * (1.0 - seitlich / 1.1))
	return farbe


## Vier Ecken eines Bogensteins um `mitte`: innen-von, innen-bis,
## außen-bis, außen-von. `einzug` in Metern rückt alle Kanten nach innen.
func _plattenecken(mitte: Vector3, ri: float, ra: float, g0: float, g1: float,
		einzug: float, y: float) -> PackedVector3Array:
	var di := rad_to_deg(einzug / maxf(ri, 0.05))
	var da := rad_to_deg(einzug / maxf(ra, 0.05))
	return PackedVector3Array([_um(mitte, g0 + di, ri, y), _um(mitte, g1 - di, ri, y),
			_um(mitte, g1 - da, ra, y), _um(mitte, g0 + da, ra, y)])


## Ein Bogenstein mit Fase: Deckfläche plus vier schräge Kanten bis kurz
## über das Fugenbett. Die Fasen fangen das Streiflicht – daran liest man
## die Steine, nicht an einer Textur.
func _platte(st: SurfaceTool, mitte: Vector3, ri: float, ra: float, g0: float,
		g1: float, farbe: Color, hoehe: float, fuss := PFLASTER_FUSS) -> void:
	var unten := _plattenecken(mitte, ri + FUGE, ra - FUGE, g0, g1, FUGE, fuss)
	var oben := _plattenecken(mitte, ri + FUGE + FASE, ra - FUGE - FASE, g0, g1,
			FUGE + FASE, hoehe)
	_dreieck(st, oben[0], oben[1], oben[2], Vector3.UP, farbe)
	_dreieck(st, oben[0], oben[2], oben[3], Vector3.UP, farbe)
	# Dunkler als die Deckfläche: Die der Sonne zugewandte Fase bekommt fast
	# doppelt so viel Licht und wäre sonst heller als der Stein selbst.
	var kante := farbe.darkened(0.28)
	for k in 4:
		var k1 := (k + 1) % 4
		var a := unten[k]
		var b := unten[k1]
		var c := oben[k1]
		var d := oben[k]
		var n := (b - a).cross(d - a)
		if n.length_squared() < 1e-10:
			continue
		n = n.normalized()
		if n.y < 0.0:
			n = -n
		_dreieck(st, a, b, c, n, kante)
		_dreieck(st, a, c, d, n, kante)


## Niedriger Randstein an der Südkante. Die Südmauer ist von der Kamera aus
## unsichtbar (einseitig); ohne Randstein endete das Pflaster im Nichts.
## Er liegt ganz im Kollisionskasten der Mauer – niemand stolpert darüber.
func _baue_randstein(st: SurfaceTool) -> void:
	var stuecke := 64
	var innen := HALLE_R - 0.8
	var aussen := HALLE_R
	for i in stuecke:
		var g0 := lerpf(-SEITE, SEITE, float(i) / float(stuecke))
		var g1 := lerpf(-SEITE, SEITE, float(i + 1) / float(stuecke))
		var ton := PFLASTER_TON.darkened(0.12 + 0.06 * float(i % 3) / 2.0)
		var e := PackedVector3Array()
		for y: float in [-0.09, 0.3]:
			var ecken := _plattenecken(BOGEN_MITTE, innen, aussen, g0, g1, 0.02, y)
			e.append_array(ecken)
		_hexaeder(st, e, ton, true)


## Steinbrüstung auf dem Randstein: Die Südmauer ist unsichtbar, und ohne
## Brüstung sah die Wiese dahinter begehbar aus – bis man gegen die
## unsichtbare Wand lief. Jetzt sieht man die Grenze, bevor man sie
## erreicht. Sie steht ganz im Kollisionskasten der Mauer (27,8 bis 29 m
## vom Bogenmittelpunkt) und ist so niedrig, dass die Kamera beim Start
## darüber hinwegschaut. EIN Netz, ohne Schatten – der fiele nach Süden
## auf die Wiese, wo ihn niemand braucht.
func _baue_bruestung() -> void:
	var st := _neuer_bauer()
	var r := HALLE_R - 0.4
	var laenge := deg_to_rad(SEITE * 2.0) * r
	# Docken im Abstand von gut einem halben Meter, alle neun ein Pfosten
	var docken := int(laenge / 0.58)
	for i in docken + 1:
		var g := lerpf(-SEITE + 0.6, SEITE - 0.6, float(i) / float(docken))
		var basis := Basis(Vector3.UP, nach_aussen(g))
		var fuss := ort(g, r, 0.3)
		if i % 9 == 0:
			_kasten(st, fuss + Vector3.UP * 0.36, Vector3(0.38, 0.72, 0.38), basis)
			_kasten(st, fuss + Vector3.UP * 0.79, Vector3(0.46, 0.14, 0.46), basis)
			continue
		_kasten(st, fuss + Vector3.UP * 0.06, Vector3(0.2, 0.12, 0.2), basis)
		_kasten(st, fuss + Vector3.UP * 0.33, Vector3(0.12, 0.42, 0.12), basis)
		_kasten(st, fuss + Vector3.UP * 0.58, Vector3(0.18, 0.08, 0.18), basis)
	# Handlauf
	var stuecke := 72
	for i in stuecke:
		var g0 := lerpf(-SEITE + 0.4, SEITE - 0.4, float(i) / float(stuecke))
		var g1 := lerpf(-SEITE + 0.4, SEITE - 0.4, float(i + 1) / float(stuecke))
		var e := PackedVector3Array()
		for y: float in [0.92, 1.04]:
			e.append_array(_plattenecken(BOGEN_MITTE, r - 0.15, r + 0.15, g0, g1, 0.0, y))
		_hexaeder(st, e, KEINE_FARBE, false)
	_flaeche_anhaengen(_geometrie, st, _baustein(), "Bruestung", false)


## Schwellen: eine Steinstufe unter jedem Tor, über die Grenze Halle/Raum.
func _baue_schwellen(st: SurfaceTool) -> void:
	for i in Spielfluss.RAEUME:
		var grad := raumwinkel(i)
		var halb := rad_to_deg((_torbreite() * 0.5 - 0.5) / TOR_R)
		var ton := PFLASTER_TON.darkened(0.04)
		_platte(st, BOGEN_MITTE, TOR_R - 0.45, TOR_R + 0.45, grad - halb, grad + halb,
				ton, 0.1, 0.0)


## Mittelstein: eine runde Steinscheibe mitten in der Halle. Fünf Strahlen
## zeigen zu den fünf Räumen – glühend, wenn der Raum geschafft ist,
## farbig, wenn er offen ist, dunkel, solange er versiegelt ist. Der
## Fortschritt steht damit auf dem Boden, lesbar aus jeder Ecke der Halle.
func _baue_mittelstein(st: SurfaceTool, einlage: SurfaceTool, strahlen: SurfaceTool) -> void:
	var m := ort(0.0, START_R)
	_uv_versatz = Vector2(1.3, 2.1)
	# Äußerer Ring aus sechzehn Steinen, etwas heller als das Pflaster
	var ring := 16
	for i in ring:
		var a0 := 360.0 * float(i) / float(ring)
		var a1 := 360.0 * float(i + 1) / float(ring)
		var ton := PFLASTER_TON.lightened(0.1 if i % 2 == 0 else 0.04)
		_platte(st, m, MITTELSTEIN_R - 0.55, MITTELSTEIN_R, a0, a1, ton, 0.105, 0.05)
	# Innenfeld: zehn Fächersteine, etwas dunkler als der Ring – Grund für
	# die Strahlen, aber kein Loch im Boden.
	var innen_r := MITTELSTEIN_R - 0.58
	var faecher := 10
	for i in faecher:
		var a0 := 360.0 * float(i) / float(faecher) + 18.0
		var a1 := 360.0 * float(i + 1) / float(faecher) + 18.0
		var ton := PFLASTER_TON.darkened(0.16 if i % 2 == 0 else 0.1)
		_platte(st, m, 0.45, innen_r, a0, a1, ton, 0.095, 0.05)
	# Messingreif um den Stein
	for i in 48:
		var a0 := 360.0 * float(i) / 48.0
		var a1 := 360.0 * float(i + 1) / 48.0
		_viereck(einlage, _um(m, a0, MITTELSTEIN_R + 0.02, 0.09),
				_um(m, a0, MITTELSTEIN_R + 0.14, 0.09),
				_um(m, a1, MITTELSTEIN_R + 0.02, 0.09),
				_um(m, a1, MITTELSTEIN_R + 0.14, 0.09), Vector3.UP)

	for i in Spielfluss.RAEUME:
		var ziel := ort(raumwinkel(i), TOR_R)
		var richtung := Vector3(ziel.x - m.x, 0.0, ziel.z - m.z).normalized()
		var seite := richtung.cross(Vector3.UP)
		var ton := _strahlfarbe(i)
		var y := 0.1
		var fuss := m + richtung * 0.6 + Vector3.UP * y
		var spitze := m + richtung * (innen_r - 0.1) + Vector3.UP * y
		var bauch := m + richtung * 1.25 + Vector3.UP * y
		_dreieck(strahlen, fuss, bauch + seite * 0.26, spitze, Vector3.UP, ton)
		_dreieck(strahlen, fuss, spitze, bauch - seite * 0.26, Vector3.UP, ton)
	# Buckel in der Mitte
	var buckel := PFLASTER_TON.lightened(0.12)
	var ecken := 8
	for i in ecken:
		var a0 := 360.0 * float(i) / float(ecken) + 22.5
		var a1 := 360.0 * float(i + 1) / float(ecken) + 22.5
		_dreieck(st, _um(m, 0.0, 0.0, 0.17), _um(m, a0, 0.36, 0.17),
				_um(m, a1, 0.36, 0.17), Vector3.UP, buckel)
		var u0 := _um(m, a0, 0.5, 0.095)
		var u1 := _um(m, a1, 0.5, 0.095)
		var o0 := _um(m, a0, 0.36, 0.17)
		var o1 := _um(m, a1, 0.36, 0.17)
		var nrm := (u1 - u0).cross(o0 - u0).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		_viereck(st, u0, u1, o0, o1, nrm, buckel.darkened(0.08))


## Farbe eines Strahls im Mittelstein, je nach Stand des Raums.
func _strahlfarbe(index: int) -> Color:
	var raum := index + 1
	if Spielfluss.raum_abgeschlossen(raum) and Spielfluss.raum_offen(raum):
		return _akzent(index).lerp(Farben.ERFOLG_SCHEIN, 0.35)
	if Spielfluss.raum_offen(raum):
		return _akzent(index).darkened(0.3)
	# Mal 1,6 im Material – so bleibt es dunkler Stein und wird nicht lila.
	return Color(0.12, 0.11, 0.13)


## Leitlinien: ein Messingband im Pflaster vom Mittelstein zu jedem Tor.
## Bei offenen Räumen laufen darüber Lichtpulse zum Tor hin.
func _baue_leitlinien(einlage: SurfaceTool, pulse: SurfaceTool) -> void:
	var m := ort(0.0, START_R)
	for i in Spielfluss.RAEUME:
		var ziel := ort(raumwinkel(i), TOR_R - 0.6)
		var richtung := Vector3(ziel.x - m.x, 0.0, ziel.z - m.z)
		var laenge := richtung.length()
		richtung = richtung.normalized()
		var seite := richtung.cross(Vector3.UP)
		var von := m + richtung * (MITTELSTEIN_R + 0.2)
		var strecke := laenge - MITTELSTEIN_R - 0.2
		var bis := von + richtung * strecke
		var h := 0.075
		_viereck(einlage, von - seite * h + Vector3.UP * 0.086,
				von + seite * h + Vector3.UP * 0.086,
				bis - seite * h + Vector3.UP * 0.086,
				bis + seite * h + Vector3.UP * 0.086, Vector3.UP)
		if not Spielfluss.raum_offen(i + 1):
			continue
		# Pulsband: kaum breiter als das Messing.
		var b := 0.11
		var ton := _akzent(i)
		var schritte := maxi(int(strecke / 2.0), 1)
		for s in schritte:
			var t0 := float(s) / float(schritte)
			var t1 := float(s + 1) / float(schritte)
			var p0 := von + richtung * strecke * t0 + Vector3.UP * LEITLINIE_Y
			var p1 := von + richtung * strecke * t1 + Vector3.UP * LEITLINIE_Y
			for ecke: Array in [[p0 - seite * b, Vector2(strecke * t0, 0.0), t0],
					[p0 + seite * b, Vector2(strecke * t0, 1.0), t0],
					[p1 + seite * b, Vector2(strecke * t1, 1.0), t1],
					[p0 - seite * b, Vector2(strecke * t0, 0.0), t0],
					[p1 + seite * b, Vector2(strecke * t1, 1.0), t1],
					[p1 - seite * b, Vector2(strecke * t1, 0.0), t1]]:
				pulse.set_color(ton)
				pulse.set_normal(Vector3.UP)
				pulse.set_uv(ecke[1] as Vector2)
				pulse.set_uv2(Vector2(float(ecke[2]), 0.0))
				pulse.add_vertex(ecke[0] as Vector3)


## Mauern: Kollision für alle, Sichtflächen für Süd- und Seitenmauern. Die
## Rückwände der Räume baut `_baue_rueckwand` je Raum.
func _baue_mauern() -> void:
	var wand := _neuer_bauer()
	var kranz := _neuer_bauer()
	var koerper := StaticBody3D.new()
	koerper.name = "Mauerkollision"
	koerper.collision_layer = 1
	koerper.collision_mask = 0

	# Nordmauer (Bogen, Blick nach innen = zur Bogenmitte): nur Kollision
	_bogenmauer(null, null, koerper, AUSSEN_R, -SEITE, SEITE, 26, true)
	# Südmauer hinter dem Startplatz
	_bogenmauer(wand, kranz, koerper, HALLE_R, -SEITE, SEITE, 16, false)
	# Seitenmauern
	for vorzeichen in [-1.0, 1.0]:
		var g: float = SEITE * float(vorzeichen)
		var t := deg_to_rad(g)
		var innen := Vector3(cos(t), 0.0, sin(t)) * -float(vorzeichen)
		_gerade_mauer(wand, kranz, koerper, ort(g, HALLE_R), ort(g, AUSSEN_R), innen)

	_flaeche_anhaengen(_geometrie, wand, Materialbibliothek.fels(),
			"Aussenmauer", false)
	_flaeche_anhaengen(_geometrie, kranz,
			Materialbibliothek.einfarbig(Farben.FELS_WARM, 0.85), "Mauerkranz", false)
	_geometrie.add_child(koerper)

	for i in Spielfluss.RAEUME:
		_baue_rueckwand(i, raumwinkel(i))


func _bogenmauer(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		radius: float, von: float, bis: float, schritte: int,
		zur_mitte: bool) -> void:
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		var p0 := ort(g0, radius)
		var p1 := ort(g1, radius)
		var radial := (p0 + p1) * 0.5 - BOGEN_MITTE
		radial.y = 0.0
		var innen := -radial.normalized() if zur_mitte else radial.normalized()
		_mauerstueck(wand, kranz, koerper, p0, p1, innen)


func _gerade_mauer(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		von: Vector3, bis: Vector3, innen: Vector3) -> void:
	var schritte := maxi(int(von.distance_to(bis) / 6.0), 1)
	for i in schritte:
		var p0 := von.lerp(bis, float(i) / float(schritte))
		var p1 := von.lerp(bis, float(i + 1) / float(schritte))
		_mauerstueck(wand, kranz, koerper, p0, p1, innen)


## Ein Mauerabschnitt: Fläche nach innen, heller Kranz obenauf, Kollision.
## Ohne Bauer (`wand` null) entsteht nur die Kollision.
func _mauerstueck(wand: SurfaceTool, kranz: SurfaceTool, koerper: StaticBody3D,
		p0: Vector3, p1: Vector3, innen: Vector3) -> void:
	var unten := WAND_HOEHE - KRANZ_HOEHE
	if wand != null:
		_viereck(wand, p0, p0 + Vector3.UP * unten, p1, p1 + Vector3.UP * unten, innen)
		_viereck(kranz, p0 + Vector3.UP * unten, p0 + Vector3.UP * WAND_HOEHE,
				p1 + Vector3.UP * unten, p1 + Vector3.UP * WAND_HOEHE, innen)

	var mitte := (p0 + p1) * 0.5
	var laenge := p0.distance_to(p1)
	var form := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(laenge + 0.4, WAND_HOEHE + 2.0, 1.2)
	form.shape = box
	form.position = mitte - innen * 0.6 + Vector3.UP * WAND_HOEHE * 0.5
	form.rotation.y = atan2(-innen.x, -innen.z)
	koerper.add_child(form)


## Profil der Rückwand von unten nach oben: [Versatz nach außen, Höhe].
## Sockel (springt vor), Wandfläche (liegt zurück), Gesims, Krone mit
## Deckfläche. Alles hinter der Vorderkante des Sockels liegt im
## Kollisionskasten der Mauer – die Figur stößt nirgends in Stein.
const WANDPROFIL := [
	[0.0, -0.05], [0.0, 0.55], [0.14, 0.68],
	[0.14, 4.78],
	[-0.12, 4.92], [-0.12, 5.12], [0.0, 5.2], [0.0, WAND_HOEHE], [1.0, WAND_HOEHE],
]
## Welche Profilabschnitte zur Krone (zweites Material) gehören.
const PROFIL_KRONE := [0, 1, 3, 4, 5, 6, 7]


## Rückwand eines Raums mit Körper und eigenem Stoff: Wurzelfels im Wald,
## nasser Stein im Sumpf, Zinnen über der Steinfeste, Rost und Rohre,
## Sandstein mit Leuchtband. Die Wandpfeiler stehen hinter den Säulen der
## Bogenreihe – so entsteht Tiefe statt einer flachen Kulisse.
func _baue_rueckwand(index: int, grad: float) -> void:
	var wand := _neuer_bauer()
	var krone := _neuer_bauer()
	var von := grad - SEKTOR_HALB
	var bis := grad + SEKTOR_HALB
	var schritte := 7
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		for k in WANDPROFIL.size() - 1:
			var a: Array = WANDPROFIL[k]
			var b: Array = WANDPROFIL[k + 1]
			var ua := float(a[0])
			var va := float(a[1])
			var ub := float(b[0])
			var vb := float(b[1])
			var gm := (g0 + g1) * 0.5
			var n := _aussen(gm) * -(vb - va) + Vector3.UP * (ub - ua)
			var ziel := krone if PROFIL_KRONE.has(k) else wand
			_viereck(ziel, ort(g0, AUSSEN_R + ua, va), ort(g0, AUSSEN_R + ub, vb),
					ort(g1, AUSSEN_R + ua, va), ort(g1, AUSSEN_R + ub, vb), n)

	# Wandpfeiler hinter den Säulen der Bogenreihe (die äußeren stecken in
	# den Trennmauern und fallen weg)
	var n_level := Spielfluss.LEVEL_JE_RAUM
	for k in range(1, n_level):
		var seitlich := (float(k) - float(n_level) * 0.5) * PORTAL_ABSTAND
		var winkel := grad + rad_to_deg(seitlich / PORTAL_R)
		var fuss := ort(winkel, AUSSEN_R + 0.07, 0.55)
		var basis := Basis(Vector3.UP, nach_aussen(winkel))
		_kasten(wand, fuss + Vector3.UP * (4.78 - 0.55) * 0.5,
				Vector3(0.95, 4.78 - 0.55, 0.14), basis)

	# Raumeigenes an der Wand
	match index:
		2:
			# Zinnen über der Steinfeste
			var zinnen := 12
			for z in zinnen:
				var g := lerpf(von + 0.6, bis - 0.6, (float(z) + 0.5) / float(zinnen))
				var basis := Basis(Vector3.UP, nach_aussen(g))
				_kasten(krone, ort(g, AUSSEN_R + 0.45, WAND_HOEHE + 0.35),
						Vector3(0.85, 0.7, 0.9), basis)
		3:
			_baue_rohre(grad, von, bis)
		4:
			_baue_leuchtband(von, bis)

	var wandmi := _flaeche_anhaengen(_geometrie, wand, _wandstoff(index),
			"Rueckwand%d" % (index + 1))
	var kronenmi := _flaeche_anhaengen(_geometrie, krone, _kronenstoff(index),
			"Wandkrone%d" % (index + 1))
	# Die Sonne steht hinter den Rückwänden: Ihr Schatten fällt in den Raum
	# und legt die Portalreihe ins Halbdunkel. Beidseitig, weil die Flächen
	# nur nach innen zeigen und das Licht von außen kommt.
	for mi in [wandmi, kronenmi]:
		if mi != null:
			(mi as MeshInstance3D).cast_shadow = \
					GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED


func _wandstoff(index: int) -> Material:
	match index:
		0:
			return Materialbibliothek.wurzelfels()
		1:
			return _getoent(Materialbibliothek.fels(), Color(0.74, 0.84, 0.82), "fels_nass")
		2:
			return _getoent(Materialbibliothek.fels(), Color(1.05, 1.0, 0.94), "fels_feste")
		3:
			return Materialbibliothek.metall(Farben.ROST)
		_:
			return _getoent(Materialbibliothek.fels(), Color(1.3, 0.98, 0.66), "sandstein")


func _kronenstoff(index: int) -> Material:
	match index:
		0, 1:
			return Materialbibliothek.moos()
		2:
			return Materialbibliothek.einfarbig(Farben.FELS_WARM, 0.85)
		3:
			return Materialbibliothek.einfarbig(KANALGRUEN.lerp(Farben.FELS_DUNKEL, 0.3), 0.7)
		_:
			return Materialbibliothek.einfarbig(SANDSTEIN_HELL, 0.9)


## Rostige Rohre an der Rückwand von „Rost und Ranken", mit Flanschen.
func _baue_rohre(grad: float, von: float, bis: float) -> void:
	var st := _neuer_bauer()
	for hoehe: float in [1.25, 3.2]:
		var schritte := 8
		for i in schritte:
			var g0 := lerpf(von + 0.5, bis - 0.5, float(i) / float(schritte))
			var g1 := lerpf(von + 0.5, bis - 0.5, float(i + 1) / float(schritte))
			var r := 0.2 if hoehe < 2.0 else 0.14
			# Halb in der Wand: Die Figur läuft an der Rückwand entlang und
			# soll nicht in ein Rohr ohne Kollision hineinlaufen.
			_rohr(st, ort(g0, AUSSEN_R + 0.14, hoehe), ort(g1, AUSSEN_R + 0.14, hoehe), r)
			var mitte := ort(g0, AUSSEN_R + 0.14, hoehe)
			var achse := (ort(g1, AUSSEN_R, 0.0) - ort(g0, AUSSEN_R, 0.0)).normalized()
			_rohr(st, mitte - achse * 0.06, mitte + achse * 0.06, r + 0.06)
	# Zwei Fallrohre in den Boden
	for seitlich: float in [-4.6, 4.9]:
		var oben := stelle(grad, AUSSEN_R + 0.14, seitlich, 3.2)
		_rohr(st, oben + Vector3.DOWN * 3.3, oben, 0.14)
	_flaeche_anhaengen(_geometrie, st, Materialbibliothek.metall(Farben.ROST), "Rohre")


## Leuchtband unter dem Gesims von „Sand und Neon". Ungeschattet und heller
## als 1: Es glüht, auch wo die Wand im Schatten liegt.
func _baue_leuchtband(von: float, bis: float) -> void:
	var st := _neuer_bauer()
	var schritte := 10
	for i in schritte:
		var g0 := lerpf(von, bis, float(i) / float(schritte))
		var g1 := lerpf(von, bis, float(i + 1) / float(schritte))
		var gm := (g0 + g1) * 0.5
		for band: Array in [[4.55, 4.68], [1.0, 1.08]]:
			var y0 := float(band[0])
			var y1 := float(band[1])
			_viereck(st, ort(g0, AUSSEN_R + 0.12, y0), ort(g0, AUSSEN_R + 0.12, y1),
					ort(g1, AUSSEN_R + 0.12, y0), ort(g1, AUSSEN_R + 0.12, y1), -_aussen(gm))
	var stoff := StandardMaterial3D.new()
	stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Knapp über der Glühschwelle (0,95): Es glüht, aber der Ton bleibt
	# Cyan. Mit 1,9 brannte es nach Glühen und Tonemapping zu Weiß aus.
	var c := Neonmaterial.NEON_CYAN
	stoff.albedo_color = Color(c.r * 1.1, c.g * 1.1, c.b * 1.1)
	_flaeche_anhaengen(_geometrie, st, stoff, "Leuchtband", false)


# ---------------------------------------------------------------- Umland

## Hinter der Nordmauer: eine Hügelkette und Baumkronen. Die Kamera schaut
## so flach, dass über der Mauer ein Streifen frei bleibt – vorher zeigte er
## die graue Grundfarbe des Himmels. Die Bäume ragen über die Mauer: Der
## Saal steht in einem Wald, nicht in der Leere.
func _baue_umland() -> void:
	var horizont := HORIZONT.instantiate() as Horizont
	horizont.name = "Huegel"
	horizont.radius = 82.0
	horizont.hoehe = 13.0
	horizont.zacken = 58
	horizont.fuss = -2.0
	horizont.saat = 5150
	# Nah satt und dunkel, fern im Dunst des Himmels (Horizontfarbe in
	# Hub.tscn) – so staffeln sich die Hügel, statt als blasse Zacken
	# nebeneinander zu stehen.
	horizont.farbe_nah = Color(0.30, 0.36, 0.26)
	horizont.farbe_fern = Color(0.80, 0.74, 0.64)
	horizont.boden_farbe = Color(0.30, 0.34, 0.24)
	horizont.position = BOGEN_MITTE
	_deko.add_child(horizont)

	# Je Raum zwei bis drei Bäume hinter der Mauer, passend zum Raum.
	var baeume := [
		# [Winkel, Radius, Art, Höhe, Laubfarbe]
		[-50.0, 66.0, Baum.Art.LAUBBAUM, 10.0, Farben.LAUB],
		[-42.0, 69.0, Baum.Art.LAUBBAUM, 11.0, Farben.LAUB_DUNKEL],
		[-34.0, 65.5, Baum.Art.LAUBBAUM, 9.5, Farben.LAUB],
		[-26.5, 67.0, Baum.Art.TOTHOLZ, 9.0, Farben.LAUB],
		[-16.0, 68.0, Baum.Art.LAUBBAUM, 10.0, Farben.MOOS],
		[-6.0, 69.5, Baum.Art.NADELBAUM, 11.5, Farben.NADEL_FROST],
		[5.5, 66.0, Baum.Art.NADELBAUM, 10.0, Farben.LAUB_DUNKEL],
		[15.0, 68.5, Baum.Art.NADELBAUM, 11.0, Farben.NADEL_FROST],
		[24.5, 66.5, Baum.Art.LAUBBAUM, 10.5, DSCHUNGEL],
		[33.0, 69.0, Baum.Art.LAUBBAUM, 11.0, DSCHUNGEL],
		[41.5, 66.0, Baum.Art.TOTHOLZ, 8.5, Farben.LAUB],
		[49.0, 67.5, Baum.Art.TOTHOLZ, 9.0, Farben.LAUB],
	]
	for i in baeume.size():
		var b: Array = baeume[i]
		var baum := _prop(BAUM, ort(float(b[0]), float(b[1])), {
			"art": b[2], "hoehe": float(b[3]), "laubfarbe": b[4],
			"saat": 900 + i, "kollision": false, "staerke": 1.1,
		})
		# Hinter der Mauer wirft kein Baum einen sichtbaren Schatten – die
		# Schattenkarte spart hier zwölf mal zwei Netze.
		_ohne_schatten(baum)


# ------------------------------------------------------------------- Räume

func _baue_raum(index: int, grad: float) -> void:
	var raum := Node3D.new()
	raum.name = "Raum%d" % (index + 1)
	_objekte.add_child(raum)

	var boden := _neuer_bauer()
	_bogenflaeche(boden, UEBERGANG_R, AUSSEN_R,
			grad - SEKTOR_HALB, grad + SEKTOR_HALB, 0.0, 8)
	_flaeche_anhaengen(_geometrie, boden, _bodenmaterial(index),
			"Raumboden%d" % (index + 1))

	# Trennmauer zum rechten Nachbarn (die linke gehört zum Nachbarn)
	if index < Spielfluss.RAEUME - 1:
		_baue_trennmauer(grad + SEKTOR_HALB)

	_baue_torbogen(index, grad)
	if not Spielfluss.raum_offen(index + 1):
		_baue_sperre(index, grad)
	elif _entsiegeln.has(index):
		_siegel_neu[index] = _baue_siegel(raum, index, grad)

	var nummern := Spielfluss.level_im_raum(index + 1)
	for i in nummern.size():
		var seitlich := (float(i) - 2.0) * PORTAL_ABSTAND
		var winkel := grad + rad_to_deg(seitlich / PORTAL_R)
		var portal := Levelportal.new()
		portal.nummer = nummern[i]
		portal.name = "Portal%02d" % nummern[i]
		portal.eigene_pfeiler = false
		portal.akzent = _akzent(index)
		portal.wirbel = _wirbelfarben(index)
		portal.position = ort(winkel, PORTAL_R)
		portal.rotation.y = -deg_to_rad(winkel)
		raum.add_child(portal)
	_baue_bogenreihe(index, grad)

	match index:
		0:
			_deko_wurzelwald(grad)
		1:
			_deko_nebelsuempfe(grad)
		2:
			_deko_felsenschlucht(grad)
		3:
			_deko_rost_und_ranken(grad)
		_:
			_deko_sand_und_neon(grad)


## Siegel vor einem noch gesperrten Raum.
##
## Die Portale dahinter schlafen ohnehin, aber ein Raum, den man betreten
## kann und in dem dann nichts geht, liest sich wie ein Fehler. Das Siegel
## sagt vorher, woran es liegt: Erst den Raum davor abschließen.
##
## Die Kollision ist unverändert die des alten Gitters (13 ineinander
## greifende Kästen), nur die Optik ist neu: EIN Schleiernetz statt 43
## Stäben, Riegeln und Warnbandstücken, dazu eine Steintafel.
##
## Im Debugmodus wird es gar nicht erst gebaut – dort ist alles offen.
func _baue_sperre(index: int, grad: float) -> void:
	var sperre := Node3D.new()
	sperre.name = "Sperre%d" % (index + 1)
	_objekte.add_child(sperre)

	var koerper := StaticBody3D.new()
	koerper.name = "Riegel"
	koerper.collision_layer = 1
	koerper.collision_mask = 0
	sperre.add_child(koerper)

	var staebe := 13
	for i in staebe:
		var t := float(i) / float(staebe - 1)
		var winkel := lerpf(grad - SEKTOR_HALB + 0.4, grad + SEKTOR_HALB - 0.4, t)
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		# Die Kästen greifen ineinander, sonst schlüpft man zwischen zwei
		# Stäben hindurch – der Spieler ist schmaler als der Stababstand.
		kasten.size = Vector3(1.4, SPERRE_HOEHE, 0.7)
		form.shape = kasten
		form.position = ort(winkel, TOR_R, SPERRE_HOEHE * 0.5)
		form.rotation.y = nach_aussen(winkel)
		koerper.add_child(form)

	_baue_siegel(sperre, index, grad)

	# Steintafel mit dem Grund, vor dem Siegel. Groß genug, um sie aus der
	# Hallenmitte zu lesen: Das alte rote Warnband war nicht zu übersehen,
	# eine kleine Tafel schon – und dann weiß man nicht, warum es nicht
	# weitergeht.
	var tafel := _quader(sperre, ort(grad, TOR_R - 0.3, 1.3),
			Vector3(4.2, 1.45, 0.14),
			_getoent(Materialbibliothek.fels(), Color(0.46, 0.44, 0.45), "siegeltafel"),
			nach_aussen(grad))
	tafel.name = "Tafel"
	var rahmen := Materialbibliothek.einfarbig(SIEGELRAHMEN, 0.5, 0.4)
	_quader(sperre, ort(grad, TOR_R - 0.3, 2.06), Vector3(4.4, 0.1, 0.2), rahmen,
			nach_aussen(grad))
	_quader(sperre, ort(grad, TOR_R - 0.3, 0.54), Vector3(4.4, 0.1, 0.2), rahmen,
			nach_aussen(grad))

	# Zwei Zeilen, zwei Schriften: oben das Wort in Gold, darunter der Grund.
	# Die Breite muss in den Sektor passen – bei 96 pt und 0,012 m je Pixel
	# war ein Schriftzug früher so breit wie der ganze Raum und ragte über
	# die Trennmauern in die Nachbarräume.
	var kopf := _tafelschrift("Versiegelt", &"titel", 64, Farben.UI_GOLD_HELL)
	kopf.position = ort(grad, TOR_R - 0.39, 1.74)
	sperre.add_child(kopf)
	kopf.rotation.y = nach_aussen(grad) + PI
	var grund := _tafelschrift("Erst %s abschließen"
			% Spielfluss.RAUM_NAMEN[maxi(index - 1, 0)], &"fett", 44, Farben.UI_HELL)
	grund.width = 3.9 / grund.pixel_size
	grund.autowrap_mode = TextServer.AUTOWRAP_WORD
	grund.line_spacing = -6.0
	grund.position = ort(grad, TOR_R - 0.39, 1.06)
	sperre.add_child(grund)
	grund.rotation.y = nach_aussen(grad) + PI


## Schrift auf der Siegeltafel: flach an der Tafel, nur von vorn lesbar.
func _tafelschrift(inhalt: String, art: StringName, groesse: int,
		farbe: Color) -> Label3D:
	var schild := Label3D.new()
	schild.text = inhalt
	schild.font = UiStil.schrift(art)
	schild.font_size = groesse
	schild.pixel_size = 0.0072
	schild.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	schild.modulate = farbe
	schild.outline_size = 12
	schild.outline_modulate = Farben.UI_KONTUR
	schild.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	schild.double_sided = false
	schild.no_depth_test = false
	return schild



## Der Siegelschleier eines Raums: ein Bogenband über die ganze Raumbreite.
func _baue_siegel(eltern: Node3D, index: int, grad: float) -> MeshInstance3D:
	var st := _neuer_bauer()
	var von := grad - SEKTOR_HALB + 0.3
	var bis := grad + SEKTOR_HALB - 0.3
	var schritte := 16
	var laenge := deg_to_rad(bis - von) * TOR_R
	for i in schritte:
		var t0 := float(i) / float(schritte)
		var t1 := float(i + 1) / float(schritte)
		var g0 := lerpf(von, bis, t0)
		var g1 := lerpf(von, bis, t1)
		var n := -_aussen((g0 + g1) * 0.5)
		for ecke: Array in [[g0, 0.0, t0], [g0, 1.0, t0], [g1, 1.0, t1],
				[g0, 0.0, t0], [g1, 1.0, t1], [g1, 0.0, t1]]:
			st.set_normal(n)
			st.set_uv(Vector2(float(ecke[2]) * laenge, float(ecke[1])))
			st.add_vertex(ort(float(ecke[0]), TOR_R, float(ecke[1]) * SPERRE_HOEHE))
	var stoff := ShaderMaterial.new()
	stoff.shader = _shader_holen("siegel", SIEGEL_SHADER)
	stoff.set_shader_parameter("farbe", _siegelfarbe(index))
	stoff.set_shader_parameter("laenge", laenge)
	stoff.set_shader_parameter("hoehe", SPERRE_HOEHE)
	stoff.set_shader_parameter("zeichen_y", 2.75)
	return _flaeche_anhaengen(eltern, st, stoff, "Siegel", false)


## Kühler Siegelton: Raumfarbe mit Violett (der Zeitkiste) gemischt. Nie
## Grün (offen) und nie Gold (geschafft) – beides hieße „hier geht's rein".
func _siegelfarbe(index: int) -> Color:
	return _akzent(index).lerp(Farben.KISTE_ZEIT, 0.55).darkened(0.1)


func _baue_trennmauer(grad: float) -> void:
	var von := UEBERGANG_R - 1.0
	var bis := AUSSEN_R
	var mitte := (von + bis) * 0.5
	LevelWerkzeuge.plattform(_geometrie, ort(grad, mitte, TEILER_HOEHE * 0.5),
			Vector3(TEILER_DICKE, TEILER_HOEHE, bis - von),
			_baustein(), nach_aussen(grad))
	_quader(_geometrie, ort(grad, mitte, TEILER_HOEHE + 0.09),
			Vector3(TEILER_DICKE + 0.2, 0.18, bis - von),
			Materialbibliothek.einfarbig(Farben.FELS_WARM, 0.85),
			nach_aussen(grad), false)


func _bodenmaterial(index: int) -> Material:
	match index:
		0:
			return Materialbibliothek.gras()
		1:
			return Materialbibliothek.waldboden()
		2:
			return Materialbibliothek.fels()
		3:
			# Nasser, grünlicher Stein – Kanal und Dschungel
			return _getoent(Materialbibliothek.fels(), Color(0.6, 0.74, 0.64), "fels_kanal")
		_:
			return _getoent(Materialbibliothek.waldweg(), Color(1.22, 1.1, 0.88), "sand")


## Akzentfarbe eines Raums – Siegel, Strahlen, Leitlinien, Fahnen und die
## schlafenden Portale greifen sie auf.
func _akzent(index: int) -> Color:
	match index:
		0:
			return Farben.LAUB_HELL
		1:
			return Farben.WASSER_HELL
		2:
			return Farben.FELS_WARM
		3:
			return ROSTORANGE.lightened(0.2)
		_:
			return Neonmaterial.NEON_CYAN


## Wirbel in den offenen Toren eines Raums: [Grundton, Kern, Saum]. Der
## Ring bleibt grün (offen), der Wirbel trägt die Welt dahinter: frisches
## Grün im Wald, Moorwasser im Sumpf, Himmelblau über der Feste (Wolkensteg,
## Abendruinen), Rost mit Kanalwasser im Kern, Cyan mit Magenta-Saum bei
## Sand und Neon. Kein Gold – das gehört dem Schein geschaffter Tore.
func _wirbelfarben(index: int) -> PackedColorArray:
	match index:
		0:
			return PackedColorArray([Color(0.40, 0.88, 0.45), Color(0.03, 0.14, 0.06),
					Color(0.86, 1.0, 0.70)])
		1:
			return PackedColorArray([Color(0.26, 0.76, 0.78), Color(0.02, 0.09, 0.13),
					Color(0.74, 1.0, 0.94)])
		2:
			return PackedColorArray([Color(0.50, 0.62, 1.0), Color(0.05, 0.06, 0.20),
					Color(0.88, 0.92, 1.0)])
		3:
			return PackedColorArray([Color(0.92, 0.44, 0.20), Color(0.03, 0.10, 0.08),
					Color(0.62, 1.0, 0.86)])
		_:
			return PackedColorArray([Color(0.22, 0.88, 1.0), Color(0.10, 0.02, 0.16),
					Color(1.0, 0.50, 0.90)])


## Farbe der Flammen in den Feuerschalen eines offenen Raums.
func _flammenfarbe(index: int) -> Color:
	if Spielfluss.raum_abgeschlossen(index + 1):
		return Farben.ERFOLG_SCHEIN.lerp(Farben.GLUT, 0.35)
	match index:
		1:
			return Color(0.45, 1.0, 0.78)     # Irrlicht über dem Sumpf
		4:
			return Neonmaterial.NEON_CYAN
		_:
			return Farben.GLUT


## Behauener Stein für alles Gebaute im Saal (Torpfeiler, Trennmauern,
## Bogenreihen): derselbe Fels, wärmer und heller. Der rohe Fels bleibt
## Außenmauern und Rückwänden – gebaut und gewachsen lesen sich getrennt.
func _baustein() -> StandardMaterial3D:
	return _getoent(Materialbibliothek.fels(), Color(1.16, 1.07, 0.94), "baustein")


func _torbreite() -> float:
	return 2.0 * (TOR_R * deg_to_rad(SEKTOR_HALB) - 1.0)


## Eigene Kopie eines Materials für EINEN Torpfeiler, die sich auflösen
## kann: Pixelraster nach Kameraabstand (Distance Fade, Dither). Das ist
## undurchsichtig gezeichnet – keine Sortierung, der Schatten bleibt. Ruht
## der Pfeiler, reicht die Überblendung nur 1 cm weit, er ist also ganz
## da; `_torpfeiler_aufloesen` zieht sie bei Bedarf weit auf. Nur Werte
## ändern sich, nie der Modus – sonst übersetzte Godot mitten im Spiel
## einen neuen Shader.
func _aufloesbar(grund: StandardMaterial3D) -> StandardMaterial3D:
	var m := grund.duplicate() as StandardMaterial3D
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	m.distance_fade_min_distance = 0.0
	m.distance_fade_max_distance = 0.01
	return m


## Torbogen am Eingang eines Raums, darüber Name und Fortschritt.
func _baue_torbogen(index: int, grad: float) -> void:
	var stein := _baustein()
	var breite := _torbreite()
	var drehung := nach_aussen(grad)
	var offen := Spielfluss.raum_offen(index + 1)
	var fertig := offen and Spielfluss.raum_abgeschlossen(index + 1)

	# Kein durchgehender Sturz: Die Kamera steht beim Durchlaufen genau
	# hinter dem Tor, ein Querbalken läge dann quer über der Bildmitte.
	# Stattdessen zwei Pfeiler mit kurzen Kragsteinen, die Mitte bleibt frei.
	# Die Kappen liegen auf Kamerahöhe: Beim Durchlaufen des Tors füllt eine
	# davon das halbe Bild. Deshalb glüht nur die eines geschafften Raums,
	# die übrigen sind Stein mit einem Hauch Raumfarbe.
	# Die Kappe ist behauener Stein mit einem Hauch Raumfarbe – eine flache,
	# helle Farbe las sich aus der Nähe wie ein unfertiger Klotz.
	var kappe: StandardMaterial3D
	if fertig:
		kappe = Materialbibliothek.leuchtend(Farben.ERFOLG_SCHEIN, 1.1)
	elif offen:
		kappe = _getoent(Materialbibliothek.fels(), Color(1.0, 0.93, 0.82).lerp(
				_akzent(index), 0.18), "kappe%d" % index)
	else:
		kappe = _getoent(Materialbibliothek.fels(), Color(0.62, 0.6, 0.6), "kappe_zu")
	for vorzeichen in [-1.0, 1.0]:
		var seite: float = float(vorzeichen) * breite * 0.5
		var torseite := Torseite.new()
		var fusspunkt := stelle(grad, TOR_R, seite)
		torseite.ort = Vector2(fusspunkt.x, fusspunkt.z)
		var pfeilerstein := _aufloesbar(stein)
		var kappenstein := _aufloesbar(kappe)
		torseite.stoffe = [pfeilerstein, kappenstein]
		_seite_nr = _torseiten.size()
		_torseiten.append(torseite)
		var pfeiler := LevelWerkzeuge.plattform(_geometrie,
				stelle(grad, TOR_R, seite, TOR_HOEHE * 0.5),
				Vector3(1.0, TOR_HOEHE, 1.0), pfeilerstein, drehung)
		pfeiler.name = "Torpfeiler"
		# Kurze Kragsteine: Die langen (2,8 m) lagen beim Durchlaufen des Tors
		# auf Kamerahöhe und deckten Tor 01 fast ganz zu.
		_quader(_geometrie, stelle(grad, TOR_R, seite - vorzeichen * 0.35,
				TOR_HOEHE + 0.24), Vector3(1.5, 0.48, 1.1), pfeilerstein, drehung)
		_quader(_geometrie, stelle(grad, TOR_R, seite, TOR_HOEHE + 0.6),
				Vector3(1.12, 0.2, 1.12), kappenstein, drehung, false)
		_baue_feuerschale(index, grad, seite, offen)
		_baue_fahne(index, grad, seite, float(vorzeichen))

	for vorzeichen in [-1.0, 1.0]:
		var fuss: float = float(vorzeichen) * (breite * 0.5 - 1.2)
		_prop(STEIN, stelle(grad, TOR_R - 1.4, fuss), {
			"groesse": 0.85, "brocken": 2, "bemoost": index == 0,
			"saat": 101 + index * 2 + int(vorzeichen)})

	# Höhe und Größe sind knapp bemessen: Die Verfolgerkamera steht 6,4 m
	# über dem Spieler und schaut 31 Grad nach unten, ihr oberer Bildrand
	# liegt damit fast waagerecht. Mit den früheren 96 pt auf 6,2 m Höhe
	# ragte der Schriftzug oben aus dem Bild und war halb abgeschnitten.
	var beschriftung := Label3D.new()
	beschriftung.text = Spielfluss.RAUM_NAMEN[index]
	beschriftung.font = UiStil.schrift(&"titel")
	beschriftung.font_size = 72
	beschriftung.outline_size = 18
	beschriftung.pixel_size = 0.0095
	beschriftung.double_sided = false
	beschriftung.modulate = _akzent(index).lightened(0.45) if offen \
			else Color(0.78, 0.76, 0.8)
	beschriftung.outline_modulate = Farben.UI_KONTUR
	beschriftung.position = ort(grad, TOR_R, 6.3)
	beschriftung.rotation.y = -deg_to_rad(grad)
	_geometrie.add_child(beschriftung)
	_beschriftungen.append(beschriftung)

	_baue_fortschritt(index, grad)


## Fünf Steine in der Schwelle jedes Tors, einer je Level: golden glühend,
## wenn geschafft, in der Raumfarbe, wenn offen, dunkel, solange versiegelt.
## Sie ersetzen die Zeile „x / 5 geschafft" – dieselbe Auskunft, ohne Lesen.
## Im Boden statt in der Luft: Unter dem Raumnamen schwebten sie genau in
## Höhe der Portalnummern und zogen beim Durchlaufen quer durchs Bild.
func _baue_fortschritt(index: int, grad: float) -> void:
	var nummern := Spielfluss.level_im_raum(index + 1)
	var offen := Spielfluss.raum_offen(index + 1)
	var basis := Basis(Vector3.UP, -deg_to_rad(grad))
	for k in nummern.size():
		var seitlich := (float(k) - 2.0) * 0.85
		var mitte := stelle(grad, TOR_R, seitlich, 0.1)
		var geschafft := Spielfluss.geschafft.has(nummern[k])
		var ziel := _st_perlen_hell if geschafft else _st_perlen_matt
		var ton := Color.WHITE
		if not geschafft:
			ton = _akzent(index).darkened(0.15) if offen else Color(0.2, 0.19, 0.21)
		_oktaeder(ziel, mitte, Vector3(0.2, 0.09, 0.2), basis, ton)


## Doppelpyramide (acht Flächen) – ein geschliffener Stein.
func _oktaeder(st: SurfaceTool, mitte: Vector3, halb: Vector3, basis: Basis,
		ton: Color) -> void:
	var oben := mitte + basis * Vector3(0.0, halb.y, 0.0)
	var unten := mitte - basis * Vector3(0.0, halb.y, 0.0)
	var ring := [basis * Vector3(halb.x, 0.0, 0.0), basis * Vector3(0.0, 0.0, halb.z),
			basis * Vector3(-halb.x, 0.0, 0.0), basis * Vector3(0.0, 0.0, -halb.z)]
	for i in 4:
		var a: Vector3 = mitte + (ring[i] as Vector3)
		var b: Vector3 = mitte + (ring[(i + 1) % 4] as Vector3)
		for spitze: Vector3 in [oben, unten]:
			var n := (a - mitte + b - mitte + spitze - mitte).normalized()
			_dreieck(st, a, b, spitze, n, ton)


## Feuerschale am Torpfeiler (Halter und Schale in einem Sammelnetz, die
## Flamme als Instanz im Flammen-MultiMesh). Kein Punktlicht: Die Flamme
## glüht über den Glow. Ein versiegelter Raum hat kalte Schalen – schon
## von weitem sieht man, welche Tore brennen.
func _baue_feuerschale(index: int, grad: float, seite: float, offen: bool) -> void:
	var nach_innen := -_aussen(grad)
	var fuss := stelle(grad, TOR_R, seite, HALTER_Y)
	var vorn := fuss + nach_innen * 0.5
	var schale := vorn + nach_innen * 0.42
	var basis := Basis(Vector3.UP, nach_aussen(grad))
	var eisen := _seitenfarbe(Color(0.2, 0.18, 0.17))
	# Halter: waagerechter Arm und schräge Strebe
	_kasten(_st_halter, (vorn + schale) * 0.5 + Vector3.DOWN * 0.08,
			Vector3(0.1, 0.1, 0.46), basis, eisen, false)
	_kasten(_st_halter, vorn + nach_innen * 0.16 + Vector3.DOWN * 0.34,
			Vector3(0.08, 0.5, 0.08), basis * Basis(Vector3.RIGHT, deg_to_rad(-38.0)),
			eisen, false)
	# Schale: achtseitiger Kegelstumpf, oben offen
	var seiten := 8
	for i in seiten:
		var w0 := TAU * float(i) / float(seiten)
		var w1 := TAU * float(i + 1) / float(seiten)
		var u0 := schale + Vector3(cos(w0) * 0.13, -0.12, sin(w0) * 0.13)
		var u1 := schale + Vector3(cos(w1) * 0.13, -0.12, sin(w1) * 0.13)
		var o0 := schale + Vector3(cos(w0) * 0.3, 0.1, sin(w0) * 0.3)
		var o1 := schale + Vector3(cos(w1) * 0.3, 0.1, sin(w1) * 0.3)
		var n := (Vector3(cos(w0 + PI / float(seiten)), 0.0,
				sin(w0 + PI / float(seiten))) * 0.8 + Vector3.DOWN * 0.6).normalized()
		_viereck(_st_halter, u0, o0, u1, o1, n, eisen)
		# Innenseite (Glut, wenn der Raum offen ist)
		var glut := Farben.GLUT.darkened(0.3) if offen else Color(0.12, 0.11, 0.1)
		_viereck(_st_halter, u0, o0, u1, o1, -n, _seitenfarbe(glut))
	if not offen:
		return
	var flamme := Transform3D(Basis.from_scale(Vector3(0.84, 1.33, 1.0)),
			schale + Vector3.UP * 0.02)
	if Spielfluss.raum_abgeschlossen(index + 1):
		flamme = flamme.scaled_local(Vector3(1.2, 1.25, 1.0))
	_flammen.append(flamme)
	_flammenseiten.append(_seite_nr)
	var ton := _flammenfarbe(index)
	_flammenfarben.append(Color(ton.r, ton.g, ton.b, fposmod(seite * 0.37 + grad * 0.05, 1.0)))


## Fahne am Torpfeiler, oberhalb der Feuerschale. Sie trägt das Wappen des
## Raums und hängt über dem Kopf der Figur – im Weg ist sie nie.
func _baue_fahne(index: int, grad: float, seite: float, vorzeichen: float) -> void:
	var nach_innen := -_aussen(grad)
	var quer := _quer(grad)
	var mitte := stelle(grad, TOR_R, seite) + nach_innen * 0.54
	var ton := _fahnenfarbe(index)
	if not Spielfluss.raum_offen(index + 1):
		ton = ton.lerp(Color(0.2, 0.2, 0.22), 0.6)
	ton = _seitenfarbe(ton)
	var reihen := 10
	var phase := fposmod(float(index) * 0.23 + vorzeichen * 0.31, 1.0)
	for r in reihen:
		var v0 := float(r) / float(reihen)
		var v1 := float(r + 1) / float(reihen)
		var y0 := FAHNE_OBEN - v0 * FAHNE_LAENGE
		var y1 := FAHNE_OBEN - v1 * FAHNE_LAENGE
		var l := mitte - quer * FAHNE_BREITE * 0.5
		var rr := mitte + quer * FAHNE_BREITE * 0.5
		for ecke: Array in [[l, y0, 0.0, v0], [rr, y0, 1.0, v0], [rr, y1, 1.0, v1],
				[l, y0, 0.0, v0], [rr, y1, 1.0, v1], [l, y1, 0.0, v1]]:
			_st_fahnen.set_color(ton)
			_st_fahnen.set_normal(nach_innen)
			_st_fahnen.set_uv(Vector2(float(ecke[2]), float(ecke[3])))
			_st_fahnen.set_uv2(Vector2(float(index), phase))
			_st_fahnen.add_vertex((ecke[0] as Vector3) + Vector3.UP * float(ecke[1]))
	# Stange über der Fahne
	var eisen := _seitenfarbe(Color(0.2, 0.18, 0.17))
	_kasten(_st_halter, mitte + Vector3.UP * (FAHNE_OBEN + 0.04),
			Vector3(FAHNE_BREITE + 0.2, 0.06, 0.06), Basis(Vector3.UP, nach_aussen(grad)),
			eisen, false)


## Scheitelfarbe für den Torschmuck der gerade gebauten Torseite: Alpha
## trägt deren Nummer ((n + 1) / 16, übersteht auch 8 Bit je Kanal).
func _seitenfarbe(ton: Color) -> Color:
	return Color(ton.r, ton.g, ton.b, (float(_seite_nr) + 1.0) / 16.0)


## Grundton der Fahne eines Raums – satter als der Akzent, damit das
## goldene Wappen darauf steht.
func _fahnenfarbe(index: int) -> Color:
	match index:
		0:
			return Color(0.17, 0.36, 0.12)
		1:
			return Color(0.1, 0.32, 0.37)
		2:
			return Color(0.46, 0.12, 0.1)
		3:
			return Color(0.5, 0.22, 0.07)
		_:
			return Color(0.2, 0.11, 0.4)


## Legt die Sammelnetze des Torschmucks aller Räume an: Halter und Schalen,
## Fahnen, Fortschrittssteine und die Flammen.
func _baue_torschmuck() -> void:
	_aufloesen.resize(_torseiten.size())
	_aufloesen.fill(0.0)
	var halterstoff := ShaderMaterial.new()
	halterstoff.shader = _shader_holen("halter", HALTER_SHADER)
	_flaeche_anhaengen(_geometrie, _st_halter, halterstoff, "Feuerschalen")
	_aufloesstoffe.append(halterstoff)

	var fahnenstoff := ShaderMaterial.new()
	fahnenstoff.shader = _shader_holen("fahne", FAHNE_SHADER)
	_flaeche_anhaengen(_geometrie, _st_fahnen, fahnenstoff, "Fahnen", false)
	_aufloesstoffe.append(fahnenstoff)

	_flaeche_anhaengen(_geometrie, _st_perlen_hell,
			Materialbibliothek.leuchtend(Farben.ERFOLG_SCHEIN, 2.0),
			"Fortschritt_geschafft", false)
	var matt := StandardMaterial3D.new()
	matt.vertex_color_use_as_albedo = true
	matt.vertex_color_is_srgb = true
	matt.roughness = 0.35
	matt.metallic_specular = 0.8
	_flaeche_anhaengen(_geometrie, _st_perlen_matt, matt, "Fortschritt_offen", false)

	if _flammen.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	# Eigene Daten: R = Torseite (zum Auflösen mit dem Pfeiler)
	mm.use_custom_data = true
	var viereck := QuadMesh.new()
	viereck.size = Vector2.ONE
	mm.mesh = viereck
	mm.instance_count = _flammen.size()
	var huelle := AABB()
	for i in _flammen.size():
		mm.set_instance_transform(i, _flammen[i])
		mm.set_instance_color(i, _flammenfarben[i])
		mm.set_instance_custom_data(i, Color(float(_flammenseiten[i]), 0.0, 0.0, 0.0))
		var p := _flammen[i].origin
		huelle = AABB(p, Vector3.ZERO) if i == 0 else huelle.expand(p)
	var flammen := MultiMeshInstance3D.new()
	flammen.name = "Flammen"
	flammen.multimesh = mm
	var stoff := ShaderMaterial.new()
	stoff.shader = _shader_holen("flamme", FLAMME_SHADER)
	flammen.material_override = stoff
	_aufloesstoffe.append(stoff)
	flammen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Die Form entsteht erst im Shader – die Hülle muss sie samt Hof
	# umfassen (bis zu zwei Flammenhöhen über dem Fuß).
	flammen.custom_aabb = huelle.grow(2.8)
	_geometrie.add_child(flammen)


## Jedes Bild: Torpfeiler vor der Figur auflösen, und die Torbeschriftungen
## ausblenden, wenn die Kamera dicht davor steht – sonst legt sich der
## Schriftzug beim Durchlaufen über das halbe Bild.
func _process(delta: float) -> void:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var kamera_ort := kamera.global_position
	_torpfeiler_aufloesen(kamera_ort, delta)
	for schild in _beschriftungen:
		if not is_instance_valid(schild):
			continue
		var abstand := schild.global_position.distance_to(kamera_ort)
		var sicht := clampf(
				(abstand - SCHRIFT_NAH) / (SCHRIFT_FERN - SCHRIFT_NAH), 0.0, 1.0)
		schild.modulate.a = sicht
		# Der Umriss hat seine eigene Deckkraft – sonst bliebe ein schwarzer
		# Schattenriss stehen, während die Schrift schon weg ist.
		schild.outline_modulate.a = sicht * Farben.UI_KONTUR.a


## Ein Torpfeiler, der zwischen Kamera und Figur steht, löst sich auf.
##
## Die Kamera steht immer südlich der Figur. Läuft man durch ein Tor oder
## daran entlang, stand ein 6 m hoher Pfeiler mitten im Bild – er füllte
## ein Drittel davon und verdeckte genau die Tore, zu denen man wollte.
## Gemessen wird waagerecht: Wie weit liegt der Pfeiler seitlich neben der
## Linie Kamera–Figur? Nah an der Kamera deckt er mehr vom Bild, dort darf
## er weiter seitlich stehen.
##
## Aufgelöst ist er nicht weg: Die Überblendung reicht dann 26 m weit, bei
## gut 10 m Abstand steht noch ein Drittel der Pixel, und was näher an der
## Kamera ist, verschwindet mehr.
func _torpfeiler_aufloesen(kamera_ort: Vector3, delta: float) -> void:
	if _spieler_knoten == null or not is_instance_valid(_spieler_knoten):
		_spieler_knoten = get_tree().get_first_node_in_group("spieler") as Node3D
		if _spieler_knoten == null:
			return
	var k := Vector2(kamera_ort.x, kamera_ort.z)
	var f := Vector2(_spieler_knoten.global_position.x, _spieler_knoten.global_position.z)
	var strecke := f - k
	var laenge := strecke.length()
	if laenge < 0.5:
		return
	var richtung := strecke / laenge
	var geaendert := false
	for n in _torseiten.size():
		var seite := _torseiten[n]
		var rel := seite.ort - k
		var tiefe := rel.dot(richtung)
		var quer := absf(rel.cross(richtung))
		var ziel := 0.0
		if tiefe > -0.5 and tiefe < laenge + 0.4:
			var grenze := lerpf(3.4, 1.5, clampf(tiefe / laenge, 0.0, 1.0))
			ziel = clampf((grenze - quer) / 0.9, 0.0, 1.0)
		var neu := move_toward(seite.durchsicht, ziel, delta * 3.0)
		if is_equal_approx(neu, seite.durchsicht):
			continue
		seite.durchsicht = neu
		var weite := 0.01 if neu <= 0.001 else lerpf(5.0, 26.0, neu)
		for stoff in seite.stoffe:
			stoff.distance_fade_max_distance = weite
		if n < _aufloesen.size():
			_aufloesen[n] = weite
			geaendert = true
	if geaendert:
		for stoff in _aufloesstoffe:
			stoff.set_shader_parameter("aufloesen", _aufloesen)


## Bogenreihe über den fünf Portalen eines Raums: sechs Säulen, fünf Bögen,
## alles EIN Netz. Die Säulen umschließen genau die Pfeilerkästen der
## Portale (je zwei Nachbarkästen teilen sich eine Säule) – vorher standen
## zwei Pfeiler ineinander, mit gleich hohen Kappen in derselben Ebene.
## Kollision hat die Bogenreihe keine eigene; die bleibt bei den Portalen.
func _baue_bogenreihe(index: int, grad: float) -> void:
	var st := _neuer_bauer()
	var n := Spielfluss.LEVEL_JE_RAUM
	for k in n + 1:
		var seitlich := (float(k) - float(n) * 0.5) * PORTAL_ABSTAND
		var winkel := grad + rad_to_deg(seitlich / PORTAL_R)
		var basis := Basis(Vector3.UP, -deg_to_rad(winkel))
		var fuss := ort(winkel, PORTAL_R)
		_kasten(st, fuss + Vector3.UP * 0.15, Vector3(0.96, 0.3, 0.96), basis)
		_kasten(st, fuss + Vector3.UP * 0.97, Vector3(0.78, 1.34, 0.78), basis)
		_kasten(st, fuss + Vector3.UP * 1.75, Vector3(0.98, 0.22, 0.98), basis)
	for i in n:
		var seitlich := (float(i) - float(n - 1) * 0.5) * PORTAL_ABSTAND
		var winkel := grad + rad_to_deg(seitlich / PORTAL_R)
		var basis := Basis(Vector3.UP, -deg_to_rad(winkel))
		_bogen(st, ort(winkel, PORTAL_R, Levelportal.MITTE_Y), basis)
	var mi := _flaeche_anhaengen(_geometrie, st, _baustein(),
			"Bogenreihe%d" % (index + 1))
	if mi != null:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Ein Bogen aus keilförmigen Steinen um die Ringmitte, mit Schlussstein.
func _bogen(st: SurfaceTool, mitte: Vector3, basis: Basis) -> void:
	var fuge := 1.3
	for j in BOGEN_STEINE:
		var a0 := lerpf(BOGEN_ANSATZ, 180.0 - BOGEN_ANSATZ, float(j) / float(BOGEN_STEINE))
		var a1 := lerpf(BOGEN_ANSATZ, 180.0 - BOGEN_ANSATZ,
				float(j + 1) / float(BOGEN_STEINE))
		a0 += fuge * 0.5
		a1 -= fuge * 0.5
		var schluss := j == BOGEN_STEINE / 2
		var aussen := BOGEN_AUSSEN + (0.14 if schluss else 0.0)
		var tiefe := BOGEN_TIEFE + (0.1 if schluss else 0.0)
		var e := PackedVector3Array()
		for z: float in [-tiefe * 0.5, tiefe * 0.5]:
			for rw: Vector2 in [Vector2(BOGEN_INNEN, a0), Vector2(BOGEN_INNEN, a1),
					Vector2(aussen, a1), Vector2(aussen, a0)]:
				var w := deg_to_rad(rw.y)
				e.append(mitte + basis * Vector3(cos(w) * rw.x, sin(w) * rw.x, z))
		_hexaeder(st, e)


# -------------------------------------------------------------- Ausstattung

func _deko_wurzelwald(grad: float) -> void:
	_prop(BAUM, stelle(grad, 54.0, -8.2), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 7.6, "saat": 11,
		"laubfarbe": Farben.LAUB, "staerke": 1.1})
	_prop(BAUM, stelle(grad, 54.5, 8.4), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 6.9, "saat": 12,
		"laubfarbe": Farben.LAUB_HELL})
	# Vorne links steht bewusst kein Baum: Der Wurzelwald liegt ganz außen,
	# die Kamera schaut schräg hinein – eine Krone an dieser Stelle würde
	# genau das offene Tor 01 verdecken.
	_prop(KLEINZEUG, stelle(grad, 44.8, -7.4),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 1.1, "saat": 13})
	_prop(BAUM, stelle(grad, 45.2, 8.0), {
		"art": Baum.Art.LAUBBAUM, "hoehe": 7.1, "saat": 14})

	_prop(WURZELPROP, stelle(grad, 45.5, -2.4),
			{"spannweite": 4.2, "hoehe": 1.0, "saat": 21}, deg_to_rad(grad + 70.0))
	_prop(WURZELPROP, stelle(grad, 46.5, 2.8),
			{"spannweite": 3.6, "hoehe": 0.9, "saat": 22}, deg_to_rad(grad - 50.0))

	for i in 2:
		_prop(GRASFELD, stelle(grad, 47.5 + float(i) * 1.5, -3.5 + float(i) * 7.0), {
			"flaeche": Vector2(6.5, 6.5), "anzahl": 55, "mindestdichte": 1.0,
			"hoechstzahl": 60, "saat": 30 + i})
	_prop(KLEINZEUG, stelle(grad, 43.5, 3.6),
			{"art": Kleinzeug.Art.FARN, "groesse": 0.9, "saat": 41})
	_prop(KLEINZEUG, stelle(grad, 44.0, -4.2),
			{"art": Kleinzeug.Art.FARN, "groesse": 0.8, "saat": 42})
	_prop(KLEINZEUG, stelle(grad, 48.5, 5.5),
			{"art": Kleinzeug.Art.PILZ, "groesse": 0.7, "saat": 43})

	# Vorhof zu Level 01, dem Aushängeschild: Zwei Wurzelbögen wachsen hinter
	# dem Tor aus der Wand und rahmen es wie in der Wurzelschlucht selbst.
	# Ohne Kollision – sie stehen hinter der Portalebene, wo niemand läuft.
	var winkel01 := grad + rad_to_deg(-2.0 * PORTAL_ABSTAND / PORTAL_R)
	_prop(WURZELPROP, stelle(grad, PORTAL_R + 1.4, -2.0 * PORTAL_ABSTAND - 0.2), {
		"spannweite": 4.6, "hoehe": 3.5, "dicke": 0.5, "saat": 23,
		"kollision": false}, -deg_to_rad(winkel01))
	_prop(WURZELPROP, stelle(grad, PORTAL_R + 2.3, -2.0 * PORTAL_ABSTAND + 0.5), {
		"spannweite": 3.4, "hoehe": 4.2, "dicke": 0.36, "saat": 24,
		"kollision": false}, -deg_to_rad(winkel01) + 0.35)
	# Blüten als Farbtupfer: Magenta und Gelb, wie am Rand der Schlucht
	for i in 6:
		var seitlich := -8.0 + float(i) * 3.2
		_prop(KLEINZEUG, stelle(grad, 49.2 + float(i % 2) * 0.6, seitlich), {
			"art": Kleinzeug.Art.BLUME, "groesse": 0.55 + 0.1 * float(i % 3),
			"saat": 44 + i, "eigene_farbe": true,
			"farbe": Farben.BLUETE_MAGENTA if i % 2 == 0 else Farben.LAUB_GELB})
	# Glühwürmchen über dem Gras und ein Lichtschacht voller Pollen vor 01
	_prop(STAUB, stelle(grad, 47.5, 0.0), {
		"raum": Vector3(15.0, 2.6, 8.0), "anzahl": 36, "groesse": 0.075,
		"farbe": Color(0.8, 1.0, 0.45), "steiggeschwindigkeit": 0.05,
		"wirbel": 0.8, "wirbel_tempo": 0.3, "funkeln": 1.0, "deckkraft": 1.1,
		"saat": 301})
	_prop(STAUB, stelle(grad, 49.4, -2.0 * PORTAL_ABSTAND), {
		"raum": Vector3(2.6, 5.5, 2.2), "anzahl": 40, "groesse": 0.05,
		"farbe": Color(1.0, 0.92, 0.66), "steiggeschwindigkeit": 0.16,
		"deckkraft": 0.9, "saat": 302})
	_prop(LAUBTREIBEN, stelle(grad, 47.0, 0.0), {
		"flaeche": Vector2(14.0, 9.0), "anzahl": 18, "hoehe": 2.4,
		"windrichtung": _quer(grad), "saat": 303})


func _deko_nebelsuempfe(grad: float) -> void:
	_prop(BAUM, stelle(grad, 54.0, -7.8), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 6.4, "saat": 51, "staerke": 1.2})
	_prop(BAUM, stelle(grad, 54.5, 7.6), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 5.8, "saat": 52, "staerke": 1.1})
	_prop(BAUM, stelle(grad, 44.8, 7.9), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 5.2, "saat": 53})
	_prop(BAUM, stelle(grad, 45.2, -8.0), {
		"art": Baum.Art.TOTHOLZ, "hoehe": 6.0, "saat": 54, "staerke": 1.3})

	# Stille, dunkle Tümpel mit bemoostem Rand. Nicht spiegelglatt: Die
	# Sonne steht hinter den Räumen, ihr Glanz auf glattem Wasser lag genau
	# im Blick der Kamera und machte aus jedem Tümpel eine blasse Scheibe.
	var wasser := Materialbibliothek.einfarbig(
			Farben.WASSER.lerp(Farben.FELS_DUNKEL, 0.8).darkened(0.45), 0.45)
	var schlamm := Materialbibliothek.einfarbig(
			Farben.MOOS.lerp(Farben.ERDE_DUNKEL, 0.45), 0.95)
	for eintrag in [[45.0, -2.2, 2.6], [48.0, 4.4, 2.0], [54.5, -1.5, 2.4]]:
		var e: Array = eintrag
		for rand in [true, false]:
			var scheibe := CylinderMesh.new()
			scheibe.top_radius = float(e[2]) + (0.55 if rand else 0.0)
			scheibe.bottom_radius = scheibe.top_radius
			scheibe.height = 0.08
			scheibe.radial_segments = 24
			scheibe.rings = 0
			var tuempel := MeshInstance3D.new()
			tuempel.mesh = scheibe
			tuempel.material_override = schlamm if rand else wasser
			tuempel.position = stelle(grad, float(e[0]), float(e[1]),
					0.015 if rand else 0.03)
			tuempel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_deko.add_child(tuempel)

	for i in 4:
		_prop(KLEINZEUG, stelle(grad, 43.5 + float(i) * 2.2, -6.0 + float(i) * 3.6),
				{"art": Kleinzeug.Art.PILZ, "groesse": 0.75, "saat": 61 + i})
	_prop(KLEINZEUG, stelle(grad, 49.0, 7.0),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 1.0, "saat": 66})
	# Nebelschwaden über den Tümpeln und Irrlichter
	_prop(STAUB, stelle(grad, 48.5, 0.0), {
		"raum": Vector3(15.0, 1.3, 12.0), "anzahl": 14, "groesse": 1.1,
		"groessen_streuung": 0.4, "farbe": Color(0.72, 0.86, 0.82),
		"deckkraft": 0.07, "steiggeschwindigkeit": 0.02, "wirbel": 0.6,
		"funkeln": 0.0, "saat": 311})
	_prop(STAUB, stelle(grad, 48.0, 0.0), {
		"raum": Vector3(14.0, 2.4, 9.0), "anzahl": 22, "groesse": 0.08,
		"farbe": Color(0.45, 1.0, 0.8), "steiggeschwindigkeit": 0.04,
		"wirbel": 1.0, "wirbel_tempo": 0.25, "funkeln": 1.0, "deckkraft": 1.0,
		"saat": 312})


func _deko_felsenschlucht(grad: float) -> void:
	var brocken := [
		[54.5, -8.0, 2.8], [54.0, 8.2, 2.4], [44.5, -6.6, 2.0],
		[45.0, 6.8, 2.2], [48.0, -3.2, 1.2], [47.0, 3.4, 1.4],
	]
	for i in brocken.size():
		var b: Array = brocken[i]
		_prop(STEIN, stelle(grad, float(b[0]), float(b[1])), {
			"groesse": float(b[2]), "brocken": 3, "bemoost": false,
			"saat": 71 + i, "zerklueftung": 0.4})

	# Zwei schlanke Felsnadeln rahmen die Portalreihe
	for vorzeichen in [-1.0, 1.0]:
		var seite: float = float(vorzeichen) * 8.6
		var nadel := MeshInstance3D.new()
		var kegel := CylinderMesh.new()
		kegel.top_radius = 0.25
		kegel.bottom_radius = 1.1
		kegel.height = 5.4
		kegel.radial_segments = 7
		kegel.rings = 1
		nadel.mesh = kegel
		nadel.material_override = Materialbibliothek.fels()
		nadel.position = stelle(grad, 54.8, seite, 2.7)
		_deko.add_child(nadel)
	_prop(KLEINZEUG, stelle(grad, 43.5, 1.5),
			{"art": Kleinzeug.Art.BUSCH, "groesse": 0.8, "saat": 78})
	# Rieselnder Staub vor den Felsen
	_prop(STAUB, stelle(grad, 48.0, 0.0), {
		"raum": Vector3(15.0, 5.0, 9.0), "anzahl": 30, "groesse": 0.045,
		"farbe": Farben.FELS_HELL.lightened(0.2), "steiggeschwindigkeit": -0.12,
		"deckkraft": 0.6, "funkeln": 0.3, "saat": 321})


## Raum 4: Kanal, Rost und Grün. Die vier Nadelbäume stehen dort, wo vorher
## die Frostbäume standen, mit derselben Kollision – nur dunkler, wie
## Dschungel im Schatten.
func _deko_rost_und_ranken(grad: float) -> void:
	for eintrag in [[54.5, -8.2, 8.0, 81], [54.0, 8.0, 7.2, 82],
			[44.8, -7.9, 6.6, 83], [45.2, 8.0, 7.0, 84]]:
		var e: Array = eintrag
		_prop(BAUM, stelle(grad, float(e[0]), float(e[1])), {
			"art": Baum.Art.NADELBAUM, "hoehe": float(e[2]), "saat": int(e[3]),
			"laubfarbe": DSCHUNGEL})

	# Kanalrinne vor der Rückwand, mit Rostgitter darüber – begehbar wie
	# der Boden daneben (sie liegt flach auf ihm), keine eigene Kollision.
	var rinne := _neuer_bauer()
	_bogenflaeche(rinne, AUSSEN_R - 2.2, AUSSEN_R - 0.05, grad - SEKTOR_HALB + 0.5,
			grad + SEKTOR_HALB - 0.5, 0.02, 8)
	_flaeche_anhaengen(_deko, rinne, Materialbibliothek.einfarbig(
			Farben.WASSER.lerp(KANALGRUEN, 0.5).darkened(0.35), 0.12, 0.2),
			"Kanalrinne", false)
	var gitter := _neuer_bauer()
	var staebe := 26
	for i in staebe:
		var g := lerpf(grad - SEKTOR_HALB + 0.7, grad + SEKTOR_HALB - 0.7,
				(float(i) + 0.5) / float(staebe))
		var basis := Basis(Vector3.UP, nach_aussen(g))
		_kasten(gitter, ort(g, AUSSEN_R - 1.12, 0.06), Vector3(0.07, 0.08, 2.1), basis)
	for r: float in [AUSSEN_R - 2.1, AUSSEN_R - 0.2]:
		var schritte := 8
		for s in schritte:
			var g0 := lerpf(grad - SEKTOR_HALB + 0.5, grad + SEKTOR_HALB - 0.5,
					float(s) / float(schritte))
			var g1 := lerpf(grad - SEKTOR_HALB + 0.5, grad + SEKTOR_HALB - 0.5,
					float(s + 1) / float(schritte))
			_rohr(gitter, ort(g0, r, 0.08), ort(g1, r, 0.08), 0.06, 4)
	_flaeche_anhaengen(_deko, gitter, Materialbibliothek.metall(Farben.ROST),
			"Kanalgitter", false)

	for i in 5:
		_prop(KLEINZEUG, stelle(grad, 44.0 + float(i % 3) * 2.4, -7.0 + float(i) * 3.5), {
			"art": Kleinzeug.Art.FARN if i % 2 == 0 else Kleinzeug.Art.BUSCH,
			"groesse": 0.9 + 0.15 * float(i % 2), "saat": 85 + i,
			"eigene_farbe": true, "farbe": DSCHUNGEL_HELL if i % 2 == 0 else DSCHUNGEL})
	# Aufsteigende Sporen, grünlich
	_prop(STAUB, stelle(grad, 48.0, 0.0), {
		"raum": Vector3(15.0, 4.0, 9.0), "anzahl": 28, "groesse": 0.06,
		"farbe": Color(0.6, 1.0, 0.45), "steiggeschwindigkeit": 0.18,
		"deckkraft": 0.8, "funkeln": 0.7, "saat": 331})


## Raum 5: Sand und Neon. Die Felsbrocken bleiben mit ihrer Kollision an
## ihrem Platz, bekommen aber Sandsteinfarbe. Statt Glutrissen und zwei
## Punktlichtern: zwei Obelisken mit Leuchtbändern und Leuchtlinien im Sand.
func _deko_sand_und_neon(grad: float) -> void:
	var sandstein := _getoent(Materialbibliothek.fels(), Color(1.5, 1.12, 0.72), "sandstein_brocken")
	var brocken := [[54.5, -8.0, 2.4], [54.0, 8.0, 2.1], [44.5, -6.4, 1.8],
			[45.0, 6.6, 2.0], [49.5, -8.4, 1.5], [50.5, 8.6, 1.3]]
	for i in brocken.size():
		var b: Array = brocken[i]
		var stein := _prop(STEIN, stelle(grad, float(b[0]), float(b[1])), {
			"groesse": float(b[2]), "brocken": 3, "bemoost": false,
			"saat": 91 + i, "zerklueftung": 0.44})
		_umfaerben(stein, sandstein)

	# Knapp über der Glühschwelle, wie das Leuchtband: Neon soll farbig
	# glühen, nicht weiß ausbrennen.
	var leuchten := StandardMaterial3D.new()
	leuchten.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var m := Neonmaterial.NEON_MAGENTA
	leuchten.albedo_color = Color(m.r * 1.3, m.g * 1.3, m.b * 1.3)
	var cyan := StandardMaterial3D.new()
	cyan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var c := Neonmaterial.NEON_CYAN
	cyan.albedo_color = Color(c.r * 1.05, c.g * 1.05, c.b * 1.05)

	# Obelisken hinten links und rechts, mit zwei Leuchtringen
	var stein_st := _neuer_bauer()
	var band_st := _neuer_bauer()
	for vorzeichen: float in [-1.0, 1.0]:
		var fuss := stelle(grad, 54.2, vorzeichen * 1.5 * PORTAL_ABSTAND)
		var basis := Basis(Vector3.UP, nach_aussen(grad) + PI * 0.25)
		_kasten(stein_st, fuss + Vector3.UP * 0.2, Vector3(1.6, 0.4, 1.6), basis)
		var e := PackedVector3Array()
		for y: float in [0.4, 5.6]:
			var halb := 0.56 if y < 1.0 else 0.3
			for xz: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				e.append(fuss + basis * Vector3(xz.x * halb, y, xz.y * halb))
		_hexaeder(stein_st, e, KEINE_FARBE, true)
		# Spitze
		var spitze := fuss + Vector3.UP * 6.25
		for i in 4:
			var a := e[4 + i]
			var b := e[4 + (i + 1) % 4]
			var n := ((a + b) * 0.5 - fuss - Vector3.UP * 5.6 + Vector3.UP * 0.4).normalized()
			_dreieck(stein_st, a, b, spitze, n)
		for band: float in [2.2, 4.2]:
			var t := (band - 0.4) / 5.2
			var halb := lerpf(0.56, 0.3, t) + 0.02
			_kasten(band_st, fuss + Vector3.UP * band, Vector3(halb * 2.0, 0.12, halb * 2.0),
					basis)
	_flaeche_anhaengen(_deko, stein_st, sandstein, "Obelisken")
	# Ein Kasten um den Sockel: Hinter die Portalreihe kommt man mit einem
	# Sprung über die Pfeilerkästen, und durch einen Obelisken zu laufen
	# sähe aus wie ein Fehler.
	for vorzeichen: float in [-1.0, 1.0]:
		var koerper := StaticBody3D.new()
		koerper.name = "Obelisk"
		koerper.collision_layer = 1
		koerper.collision_mask = 0
		koerper.position = stelle(grad, 54.2, vorzeichen * 1.5 * PORTAL_ABSTAND, 2.8)
		koerper.rotation.y = nach_aussen(grad) + PI * 0.25
		var form := CollisionShape3D.new()
		var kasten := BoxShape3D.new()
		kasten.size = Vector3(1.2, 5.6, 1.2)
		form.shape = kasten
		koerper.add_child(form)
		_deko.add_child(koerper)
	_flaeche_anhaengen(_deko, band_st, leuchten, "Obeliskbaender", false)

	# Leuchtlinie im Sand hinter der Portalreihe. Vor den Toren liegt keine:
	# Quer über den Vorplatz sah sie aus wie eine Hilfslinie aus dem Editor,
	# gestrichelt wie eine Fahrbahnmarkierung.
	var linien := _neuer_bauer()
	for r: float in [PORTAL_R + 2.4]:
		var schritte := 12
		for s in schritte:
			var g0 := lerpf(grad - SEKTOR_HALB + 0.6, grad + SEKTOR_HALB - 0.6,
					float(s) / float(schritte))
			var g1 := lerpf(grad - SEKTOR_HALB + 0.6, grad + SEKTOR_HALB - 0.6,
					float(s + 1) / float(schritte))
			_viereck(linien, ort(g0, r - 0.05, 0.025), ort(g0, r + 0.05, 0.025),
					ort(g1, r - 0.05, 0.025), ort(g1, r + 0.05, 0.025), Vector3.UP)
	_flaeche_anhaengen(_deko, linien, cyan, "Leuchtlinien", false)

	_prop(LAUBTREIBEN, stelle(grad, 47.5, 0.0), {
		"flaeche": Vector2(15.0, 9.0), "anzahl": 26, "hoehe": 0.8, "groesse": 0.09,
		"farbe_a": SAND, "farbe_b": SANDSTEIN_HELL, "windrichtung": _quer(grad),
		"tempo": 1.6, "saat": 341})
	_prop(STAUB, stelle(grad, 50.0, 0.0), {
		"raum": Vector3(15.0, 4.5, 6.0), "anzahl": 26, "groesse": 0.05,
		"farbe": Color(0.55, 1.0, 1.0), "steiggeschwindigkeit": 0.35,
		"deckkraft": 0.9, "funkeln": 0.8, "saat": 342})


## Sonnenstäubchen in der Halle – vor den dunklen Toren sichtbar, über dem
## hellen Pflaster verschwinden sie wie echter Staub.
func _baue_hallenluft() -> void:
	for i in 3:
		var g := -24.0 + float(i) * 24.0
		_prop(STAUB, ort(g, 37.5, -0.3), {
			"raum": Vector3(14.0, 6.0, 5.0), "anzahl": 40, "groesse": 0.045,
			"farbe": Color(1.0, 0.9, 0.68), "deckkraft": 0.55,
			"steiggeschwindigkeit": 0.1, "saat": 351 + i})


# ------------------------------------------------------------------ Spieler

## Weg für die Bildvorschau: von der Halle in jeden Raum und zurück. Er
## folgt dem Hallenbogen – eine gerade Sehne zwischen zwei Räumen lief
## früher durch die Südmauer und zeigte die Halle von einem Platz aus, den
## der Spieler nie erreicht.
func _baue_rundgang() -> void:
	var punkte: Array[Vector3] = [ort(0.0, START_R, 0.9)]
	var winkel := 0.0
	for i in Spielfluss.RAEUME:
		var grad := raumwinkel(i)
		var schritte := maxi(int(absf(grad - winkel) / 7.0), 1)
		for s in range(1, schritte + 1):
			punkte.append(ort(lerpf(winkel, grad, float(s) / float(schritte)),
					START_R, 0.9))
		punkte.append(ort(grad, PORTAL_R - 2.5, 0.9))
		punkte.append(ort(grad, START_R, 0.9))
		winkel = grad
	verlauf = LevelWerkzeuge.kurve_aus_punkten(punkte, 0.0)


## Abgleich, welche Räume schon offen gesehen wurden. Beim ersten Besuch
## der Sitzung gilt alles Offene als gesehen (kein Entsiegeln nach dem
## Laden); danach bekommt jeder neu geöffnete Raum sein Entsiegeln.
func _offene_raeume_abgleichen() -> void:
	var wurzel := get_tree().root
	var schluessel := GESEHEN_META % Spielfluss.aktueller_slot
	var erster_besuch := not wurzel.has_meta(schluessel)
	var gesehen: Array[int] = []
	if not erster_besuch:
		var alt: Variant = wurzel.get_meta(schluessel)
		if alt is Array:
			for raum: Variant in alt as Array:
				gesehen.append(int(raum))
	# Ein gesehener Raum, der jetzt zu ist, heißt: neues Spiel auf diesem
	# Platz. Dann von vorn, ohne Entsiegeln.
	for raum in gesehen:
		if not Spielfluss.raum_offen(raum):
			erster_besuch = true
			gesehen.clear()
			# Auch das zuletzt betretene Level gehört zum alten Stand.
			wurzel.remove_meta(Levelportal.letztes_level_schluessel())
			break
	for i in Spielfluss.RAEUME:
		if not Spielfluss.raum_offen(i + 1) or gesehen.has(i + 1):
			continue
		if not erster_besuch:
			_entsiegeln.append(i)
		gesehen.append(i + 1)
	wurzel.set_meta(schluessel, gesehen)


## Startwinkel: vor dem Raum, um den es gerade geht.
##   1. Wird ein Raum gerade entsiegelt, davor – das ist der Moment.
##   2. Nach einem Level vor dessen Raum: Man kommt dort heraus, wo man
##      hineinging. Gemerkt wird je Speicherplatz, und nur ein offener Raum
##      zählt – nach einem neuen Spiel stand man sonst vor dem versiegelten
##      Raum, in dem man auf dem alten Stand zuletzt war.
##   3. Sonst vor dem letzten offenen, noch nicht abgeschlossenen Raum.
##      Beim neuen Spiel ist das der Wurzelwald mit Tor 01 – vorher stand
##      man vor dem vergitterten Tor der Steinfeste.
func _startwinkel() -> float:
	if not _entsiegeln.is_empty():
		return raumwinkel(int(_entsiegeln.max()))
	var zuletzt := int(get_tree().root.get_meta(Levelportal.letztes_level_schluessel(), 0))
	if zuletzt >= 1 and zuletzt <= Spielfluss.LEVEL_GESAMT:
		var raum := Spielfluss.raum_von_level(zuletzt)
		if Spielfluss.raum_offen(raum):
			return raumwinkel(raum - 1)
	for i in range(Spielfluss.RAEUME - 1, -1, -1):
		if Spielfluss.raum_offen(i + 1) and not Spielfluss.raum_abgeschlossen(i + 1):
			return raumwinkel(i)
	return 0.0


func _spieler_setzen() -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	if spieler == null:
		return
	var winkel := _startwinkel()
	spieler.global_position = ort(winkel, START_R, 0.9)
	if spieler.has_method("setze_blickrichtung"):
		spieler.call("setze_blickrichtung", -deg_to_rad(winkel))
	GameState.level_starten(spieler.global_position)
	var kamera := get_viewport().get_camera_3d()
	if kamera != null and kamera.has_method("sofort_ausrichten"):
		kamera.call("sofort_ausrichten")


## Was erst nach dem Ausblenden des Ladebildschirms zu sehen sein soll:
## die Ankunft der Figur und das Entsiegeln neu geöffneter Räume.
func _nach_dem_einblenden() -> void:
	var spieler := get_tree().get_first_node_in_group("spieler") as Node3D
	var ankunft := spieler.global_position if spieler != null else Vector3.INF
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree():
		return
	# Nur wenn die Figur noch am Startplatz steht (die Bildvorschau setzt
	# sie gleich woandershin).
	if spieler != null and is_instance_valid(spieler) \
			and spieler.global_position.distance_to(ankunft) < 1.5:
		var fuss := ankunft + Vector3.DOWN * 0.8
		Effekte.lichtsaeule(self, fuss, Farben.PORTAL_START, 4.5, 0.8, 0.9)
		Effekte.ring(self, fuss + Vector3.UP * 0.05, Farben.PORTAL_START, 2.2, 0.45)
	if _siegel_neu.is_empty():
		return
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	for index: int in _siegel_neu:
		var schleier := _siegel_neu[index]
		if schleier == null:
			continue
		var stoff := schleier.material_override as ShaderMaterial
		var zeichen := ort(raumwinkel(index), TOR_R - 0.2, 2.75)
		Effekte.aufblitzen(self, zeichen, _siegelfarbe(index).lightened(0.4), 3.2, 0.35)
		Effekte.funken(self, zeichen, _siegelfarbe(index).lightened(0.3), 28, 5.0, 0.22)
		var tween := create_tween()
		tween.tween_method(func(wert: float) -> void:
				stoff.set_shader_parameter("deckkraft", wert), 1.0, 0.0, 1.4) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# Ein durchsichtiges Netz kostet weiter Füllrate – danach weg damit.
		tween.tween_callback(schleier.queue_free)
	Klang.spiele("portal", 1.1)
	var namen := PackedStringArray()
	for index: int in _siegel_neu:
		namen.append(String(Spielfluss.RAUM_NAMEN[index]))
	GameState.zeige_nachricht(_aufzaehlung(namen)
			+ (" sind offen!" if namen.size() > 1 else " ist offen!"), 2.2)


## „A", „A und B", „A, B und C".
static func _aufzaehlung(namen: PackedStringArray) -> String:
	if namen.size() <= 1:
		return "".join(namen)
	return ", ".join(namen.slice(0, namen.size() - 1)) + " und " + namen[namen.size() - 1]
