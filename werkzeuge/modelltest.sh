#!/usr/bin/env bash
# Prüft den Weg für eigene glTF-Figuren von Ende zu Ende.
#
#   bash werkzeuge/modelltest.sh
#
# Geprüft werden beide Wege:
#   1. mitgeliefert (res://assets/modelle) – zählt für APK und Browser
#   2. zur Laufzeit hinzugelegt (user://modelle) – der Dateidialog-Weg
#
# Beim ersten Lauf wird eine Probefigur nach assets/modelle geschrieben.

set -uo pipefail
PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAUSCHEN='mesh_get_surface_count|Parameter "m" is null|texture_free|Condition|Leaked|PagedAllocator|ObjectDB|RID allocations|instance_notify_deleted'

if [ ! -f "$PROJEKT/assets/modelle/pruefling.glb" ]; then
	echo "--- Probefigur anlegen ---"
	MODELLTEST=schreiben godot --headless --path "$PROJEKT" \
		res://werkzeuge/Modelltest.tscn 2>&1 | grep -Ev "$RAUSCHEN" | grep -E "Probefigur|FEHLER"
	godot --headless --path "$PROJEKT" --import >/dev/null 2>&1
fi

godot --headless --path "$PROJEKT" res://werkzeuge/Modelltest.tscn 2>&1 \
	| grep -Ev "$RAUSCHEN"
