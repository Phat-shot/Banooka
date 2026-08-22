#!/usr/bin/env python3
"""Lokaler Webserver für den Godot-Web-Export von Banooka.

Ein Godot-Web-Export lässt sich nicht per Doppelklick öffnen: Browser
blockieren WebAssembly über file://. Dieses Skript liefert den Export
über http:// aus und setzt zusätzlich die Cross-Origin-Isolation-Header,
damit auch ein Export MIT Thread-Unterstützung funktioniert.

Aufruf:
    python3 werkzeuge/web_server.py [Port] [--no-open]
"""

import http.server
import socketserver
import sys
import webbrowser
from pathlib import Path

EXPORT_VERZEICHNIS = Path(__file__).resolve().parent.parent / "export" / "web"
STANDARD_PORT = 8060


class BanookaHandler(http.server.SimpleHTTPRequestHandler):
    """Liefert den Export aus und ergänzt die nötigen Header."""

    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript",
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(EXPORT_VERZEICHNIS), **kwargs)

    def end_headers(self):
        # Nötig für SharedArrayBuffer, falls der Export Threads nutzt
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format, *args):
        pass  # Konsole ruhig halten


class BanookaServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main() -> int:
    argumente = [a for a in sys.argv[1:] if a != "--no-open"]
    browser_oeffnen = "--no-open" not in sys.argv
    port = int(argumente[0]) if argumente else STANDARD_PORT

    if not (EXPORT_VERZEICHNIS / "index.html").exists():
        print(f"Kein Web-Export in {EXPORT_VERZEICHNIS} gefunden.")
        print("Zuerst exportieren – siehe README.md, Abschnitt 'Im Browser starten'.")
        return 1

    adresse = f"http://localhost:{port}/"
    with BanookaServer(("", port), BanookaHandler) as server:
        print(f"Banooka läuft auf {adresse}  (Beenden mit Strg+C)", flush=True)
        if browser_oeffnen:
            webbrowser.open(adresse)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServer beendet.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
