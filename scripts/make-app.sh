#!/usr/bin/env bash
# Builds an ad-hoc-signed build/Nudge.app. macOS only.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != "Darwin" ]; then
    echo "make-app.sh builds the macOS app and only runs on macOS." >&2
    exit 1
fi

swift build -c release
bin_dir="$(swift build -c release --show-bin-path)"
app="build/Nudge.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Nudge" "$app/Contents/MacOS/Nudge"
cp Support/Info.plist "$app/Contents/Info.plist"

# App icon: every standard size (16 to 512, @1x and @2x) from the 1024x1024 master.
master="Support/AppIcon/AppIcon-1024.png"
if [ ! -f "$master" ]; then
    echo "$master is missing. Run scripts/make-icon-master.sh (needs rsvg-convert) and commit the PNG." >&2
    exit 1
fi
iconset="build/AppIcon.iconset"
rm -rf "$iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$master" --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -z "$((size * 2))" "$((size * 2))" "$master" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$iconset"

codesign --force --sign - "$app"

echo "Built $app. Open it with: open $app"
