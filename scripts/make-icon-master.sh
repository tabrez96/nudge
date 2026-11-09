#!/usr/bin/env bash
# Renders design/brand/mark.svg into Support/AppIcon/AppIcon-1024.png, the master that make-app.sh turns into
# AppIcon.icns. Run it again whenever the mark changes. Needs rsvg-convert (librsvg 2.52 or newer).
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v rsvg-convert >/dev/null 2>&1; then
    echo "rsvg-convert not found. Install librsvg (apt-get install librsvg2-bin, or brew install librsvg)." >&2
    exit 1
fi

mkdir -p Support/AppIcon
# macOS icon grid: the tile is 824x824, centred on a transparent 1024x1024 canvas.
rsvg-convert design/brand/mark.svg \
    --width 824 --height 824 \
    --page-width 1024 --page-height 1024 \
    --left 100 --top 100 \
    --format png \
    --output Support/AppIcon/AppIcon-1024.png

echo "Wrote Support/AppIcon/AppIcon-1024.png"
