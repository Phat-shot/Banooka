extends Node
## Prüfwerkzeug für das Tonsystem (autoload/Klang.gd).
##
## Erzeugt alle Klänge einmal und misst sie nach: Dauer, Abtastrate,
## Spitzenpegel und Effektivwert. Damit ist belegt, dass kein Klang still
## ist (Spitze nahe 0) und keiner übersteuert (Spitze am Anschlag 1.0) –
## beides hört man im Spiel erst, wenn es zu spät ist.
##
## Aufruf:  bash werkzeuge/klangprobe.sh

## Ab hier gilt ein Klang als still.
const STILL := 0.01
## Ab hier gilt ein Klang als übersteuert.
const UEBERSTEUERT := 0.999
## Erwartete Länge eines Spielgeräusches in Sekunden.
const KUERZESTE := 0.03
const LAENGSTE := 2.0


func _ready() -> void:
	var fehler := 0
	var namen := Klang.namen()
	print("=== Klangprobe: %d Klänge ===" % namen.size())
	print("%-14s %8s %8s %10s %9s %8s  %s"
			% ["Name", "Dauer/s", "Werte", "Abtastrate", "Spitze", "dBFS", "Effektivwert"])

	for name in namen:
		var strom := Klang.strom(name)
		if strom == null:
			print("FEHLER: %s hat keinen Strom" % name)
			fehler += 1
			continue

		var daten := strom.data
		var anzahl := daten.size() / 2      # 16 Bit, mono
		var dauer := float(anzahl) / float(strom.mix_rate)
		var spitze := 0.0
		var summe := 0.0
		for i in anzahl:
			var wert := float(daten.decode_s16(i * 2)) / 32768.0
			spitze = maxf(spitze, absf(wert))
			summe += wert * wert
		var effektiv := sqrt(summe / maxf(float(anzahl), 1.0))

		print("%-14s %8.3f %8d %10d %9.4f %8.2f  %.4f"
				% [name, dauer, anzahl, strom.mix_rate, spitze,
				linear_to_db(maxf(spitze, 0.00001)), effektiv])

		if strom.format != AudioStreamWAV.FORMAT_16_BITS:
			print("  FEHLER: %s ist nicht 16-bittig" % name)
			fehler += 1
		if strom.mix_rate != Klang.ABTASTRATE:
			print("  FEHLER: %s hat eine fremde Abtastrate" % name)
			fehler += 1
		if spitze < STILL:
			print("  FEHLER: %s ist praktisch still" % name)
			fehler += 1
		if spitze > UEBERSTEUERT:
			print("  FEHLER: %s übersteuert" % name)
			fehler += 1
		if dauer < KUERZESTE or dauer > LAENGSTE:
			print("  FEHLER: %s ist %.3f s lang" % [name, dauer])
			fehler += 1

	# Einmal alles abspielen: Im Headless-Betrieb hört das niemand, es
	# zeigt aber, dass Abspielen keine Fehler wirft und die Stimmen
	# reichen. Die Sperre gegen Doppelklänge wird dafür kurz umgangen,
	# indem jeder Klang nur einmal drankommt.
	for name in namen:
		Klang.spiele(name)

	await get_tree().process_frame
	print("=== %d Klänge geprüft, %d Fehler ===" % [namen.size(), fehler])
	get_tree().quit(1 if fehler > 0 else 0)
