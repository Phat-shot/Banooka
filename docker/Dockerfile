# Banooka als fertig ausgelieferte Web-Version.
#
# Stufe 1 baut den Godot-Web-Export, Stufe 2 liefert ihn über nginx aus.
# Das Ergebnis ist ein Abbild, das man nur starten muss – danach ist das
# Spiel im Browser erreichbar, ohne Godot auf dem Zielrechner.
#
#   docker build -f docker/Dockerfile -t banooka .
#   docker run --rm -p 8080:80 banooka
#   → http://localhost:8080

# ----------------------------------------------------------------- Bauen
FROM debian:bookworm-slim AS bauen

ARG GODOT_VERSION=4.7.2
ARG GODOT_RELEASE=${GODOT_VERSION}-stable

# Godot braucht auch im Headless-Modus einige X11- und GL-Bibliotheken,
# weil das offizielle Binary dagegen gelinkt ist.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip gzip \
        libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 \
        libgl1 libglu1-mesa libasound2 fontconfig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /werkzeug

# Editor-Binary
RUN curl -sSL -o godot.zip \
        "https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_linux.x86_64.zip" \
    && unzip -q godot.zip \
    && mv "Godot_v${GODOT_RELEASE}_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm godot.zip

# Export-Templates. Wir entpacken nur die Web-Dateien statt aller ~1 GB.
RUN curl -sSL -o templates.tpz \
        "https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_export_templates.tpz" \
    && mkdir -p "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
    && unzip -j -q templates.tpz 'templates/web*' 'templates/version.txt' \
        -d "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
    && rm templates.tpz

WORKDIR /projekt
COPY . .

# Erst importieren (legt den .godot-Cache an), dann exportieren.
RUN mkdir -p export/web \
    && godot --headless --path . --import 2>&1 | tail -5 \
    && godot --headless --path . --export-release "Web" export/web/index.html 2>&1 | tail -20 \
    && test -f export/web/index.wasm

# Kennung des ausgelieferten Standes, abrufbar unter /fassung.txt.
# Damit lässt sich von außen prüfen, ob wirklich der neue Bau läuft.
ARG BAU_KENNUNG=unbekannt
RUN printf 'Banooka\nBau: %s\nGodot: %s\n' "$BAU_KENNUNG" "$GODOT_VERSION" \
        > export/web/fassung.txt

# Für gzip_static vorkomprimieren: das WebAssembly schrumpft dabei
# von rund 34 MB auf etwa ein Viertel.
RUN find export/web -type f \( -name '*.wasm' -o -name '*.pck' -o -name '*.js' \
        -o -name '*.html' -o -name '*.json' \) \
        -exec gzip -9 -k {} \;

# ------------------------------------------------------------- Ausliefern
FROM nginx:1.27-alpine AS auslieferung

LABEL org.opencontainers.image.title="Banooka" \
      org.opencontainers.image.description="3D-Korridor-Plattformer, im Browser spielbar" \
      org.opencontainers.image.source="https://github.com/Phat-shot/Banooka"

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=bauen /projekt/export/web/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost/gesundheit || exit 1
