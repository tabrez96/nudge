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

# App icon: every standard size from the 1024px master, packed into AppIcon.icns.
iconset_dir="$(mktemp -d)"
trap 'rm -rf "$iconset_dir"' EXIT
iconset="$iconset_dir/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Support/AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -z "$((size * 2))" "$((size * 2))" Support/AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$app"

echo "Built $app. Open it with: open $app"
