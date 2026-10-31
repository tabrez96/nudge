#!/usr/bin/env bash
# Packs build/Nudge.app into build/Nudge-<version>.dmg. macOS only. Run scripts/make-app.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != "Darwin" ]; then
    echo "make-dmg.sh builds the macOS disk image and only runs on macOS." >&2
    exit 1
fi

app="build/Nudge.app"
if [ ! -d "$app" ]; then
    echo "$app not found. Run scripts/make-app.sh first." >&2
    exit 1
fi
codesign --verify --strict "$app"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
dmg="build/Nudge-$version.dmg"

staging="$(mktemp -d)"
mount_dir="$(mktemp -d)"
cleanup() {
    hdiutil detach "$mount_dir" -quiet 2>/dev/null || true
    rm -rf "$staging" "$mount_dir"
}
trap cleanup EXIT

ditto "$app" "$staging/Nudge.app"
ln -s /Applications "$staging/Applications"

rm -f "$dmg" "$dmg.sha256"
hdiutil create -volname "Nudge" -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg"
hdiutil verify "$dmg"

# Mount it read-only and check what a user will see.
hdiutil attach "$dmg" -readonly -nobrowse -noautoopen -mountpoint "$mount_dir" -quiet
test -x "$mount_dir/Nudge.app/Contents/MacOS/Nudge"
test -L "$mount_dir/Applications"
codesign --verify --strict "$mount_dir/Nudge.app"
hdiutil detach "$mount_dir" -quiet

(cd build && shasum -a 256 "$(basename "$dmg")" > "$(basename "$dmg").sha256")

echo "Built $dmg. Open it with: open $dmg"
