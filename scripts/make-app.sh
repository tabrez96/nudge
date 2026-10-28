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
codesign --force --sign - "$app"

echo "Built $app. Open it with: open $app"
