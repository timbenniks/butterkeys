#!/usr/bin/env bash
# Build, Developer-sign (no hardened runtime), install to /Applications, reset TCC.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IDENTITY="${CODE_SIGN_IDENTITY:-Apple Development: tbenniks@gmail.com (U72ZU3UVH6)}"
CONFIGURATION="${1:-Debug}"
DERIVED="$ROOT/.derivedData"
DEST="/Applications/ButterKeys.app"
BUNDLE_ID="com.timbeniks.ButterKeys"

command -v xcodegen >/dev/null || { echo "brew install xcodegen" >&2; exit 1; }

xcodegen generate

xcodebuild \
  -scheme ButterKeys \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  build

APP_SRC="$DERIVED/Build/Products/$CONFIGURATION/ButterKeys.app"
[[ -d "$APP_SRC" ]] || { echo "Missing $APP_SRC" >&2; exit 1; }

pkill -x ButterKeys 2>/dev/null || true
sleep 0.3

# Clear stale TCC approvals tied to older signatures / paths.
tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
tccutil reset ListenEvent "$BUNDLE_ID" >/dev/null 2>&1 || true

rm -rf "$DEST"
cp -R "$APP_SRC" "$DEST"

# No --options runtime: hardened runtime often breaks local Accessibility trust checks.
codesign --force --deep \
  --entitlements "$ROOT/Config/ButterKeys.entitlements" \
  --sign "$IDENTITY" \
  "$DEST"

# Hide other copies so System Settings doesn't grant the wrong binary.
shopt -s nullglob
for other in "$HOME"/Library/Developer/Xcode/DerivedData/ButterKeys-*/Build/Products/*/ButterKeys.app; do
  [[ "$(realpath "$other")" == "$(realpath "$DEST")" ]] && continue
  mv "$other" "${other}.disabled" 2>/dev/null || true
done

echo "Installed:"
codesign -dv --verbose=2 "$DEST" 2>&1 | grep -E 'Authority|TeamIdentifier|flags|Identifier' || true

echo
echo "IMPORTANT — permissions were reset. Re-enable them on THIS copy only:"
echo "  1. System Settings → Privacy & Security → Input Monitoring"
echo "     Click + → /Applications/ButterKeys.app → toggle ON"
echo "  2. System Settings → Privacy & Security → Accessibility"
echo "     Click + → /Applications/ButterKeys.app → toggle ON"
echo "  3. Quit ButterKeys (menu bar) and open /Applications/ButterKeys.app again"
echo

open "$DEST"
sleep 1
open -R "$DEST"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" 2>/dev/null || true
