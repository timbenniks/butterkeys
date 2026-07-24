#!/usr/bin/env bash
# Build, Developer ID–sign, notarize, staple, package DMG, and prepare Sparkle appcast assets.
#
# Required env / one-time setup:
#   DEVELOPER_ID_APPLICATION  e.g. "Developer ID Application: Tim Benniks (TEAMID)"
#   NOTARY_PROFILE            notarytool keychain profile name (default: ButterKeys-notary)
#   TEAM_ID                   Apple Team ID (default: 38S7FN2F8A)
#   SPARKLE_PRIVATE_KEY_FILE  path to Sparkle edDSA private key (from setup-sparkle-keys.sh)
#
# Flags:
#   --skip-notarize   Sign + DMG only (local smoke)
#   --dry-run         Print steps without notarizing / uploading
#   --bump-build      Increment CURRENT_PROJECT_VERSION before building
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="Release"
DERIVED="$ROOT/.derivedData-release"
DIST="$ROOT/dist"
BUNDLE_ID="com.timbeniks.ButterKeys"
TEAM_ID="${TEAM_ID:-38S7FN2F8A}"
NOTARY_PROFILE="${NOTARY_PROFILE:-ButterKeys-notary}"
ENTITLEMENTS="$ROOT/Config/ButterKeys.entitlements"

SKIP_NOTARIZE=0
DRY_RUN=0
BUMP_BUILD=0

for arg in "$@"; do
  case "$arg" in
    --skip-notarize) SKIP_NOTARIZE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --bump-build) BUMP_BUILD=1 ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
  esac
done

command -v xcodegen >/dev/null || { echo "brew install xcodegen" >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode required" >&2; exit 1; }

chmod +x "$ROOT/scripts/version.sh" "$ROOT/scripts/setup-sparkle-keys.sh" 2>/dev/null || true

if [[ "$BUMP_BUILD" == "1" ]]; then
  "$ROOT/scripts/version.sh" bump-build
fi

MARKETING="$("$ROOT/scripts/version.sh" | awk '{print $1}')"
BUILD="$("$ROOT/scripts/version.sh" | sed -E 's/.*\(([0-9]+)\).*/\1/')"
VERSION_TAG="v${MARKETING}"
DMG_NAME="ButterKeys-${MARKETING}.dmg"
ZIP_NAME="ButterKeys-${MARKETING}.zip"

echo "==> ButterKeys release ${MARKETING} (build ${BUILD})"

# Resolve Developer ID
if [[ -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  DEVELOPER_ID_APPLICATION="$(
    security find-identity -v -p codesigning 2>/dev/null \
      | awk -F'"' '/Developer ID Application/ {print $2; exit}'
  )"
fi

if [[ -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  cat >&2 <<'EOF'
No Developer ID Application identity found.

Create one in Apple Developer → Certificates → Developer ID Application,
install it in Keychain, then re-run:

  export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
  ./scripts/release.sh

For a local signed smoke build without notarization you still need Developer ID
(or pass --dry-run to only build unsigned Release output into dist/).
EOF
  if [[ "$DRY_RUN" != "1" ]]; then
    exit 1
  fi
  echo "==> Continuing in --dry-run without Developer ID (unsigned Release build)"
fi

# Ensure Sparkle public key is present for the feed
if [[ -f "$ROOT/Config/SparklePublicEDKey.xcconfig" ]]; then
  # shellcheck disable=SC1090
  source <(grep -E '^SPARKLE_PUBLIC_ED_KEY' "$ROOT/Config/SparklePublicEDKey.xcconfig" | sed 's/ = /=/')
  export SPARKLE_PUBLIC_ED_KEY
fi

if [[ -z "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  echo "==> Sparkle public key missing — running setup-sparkle-keys.sh"
  "$ROOT/scripts/setup-sparkle-keys.sh" || true
  if [[ -f "$ROOT/Config/SparklePublicEDKey.xcconfig" ]]; then
    SPARKLE_PUBLIC_ED_KEY="$(sed -n 's/^SPARKLE_PUBLIC_ED_KEY = //p' "$ROOT/Config/SparklePublicEDKey.xcconfig")"
    export SPARKLE_PUBLIC_ED_KEY
  fi
fi

xcodegen generate

rm -rf "$DERIVED"
mkdir -p "$DIST/updates"

BUILD_ARGS=(
  -scheme ButterKeys
  -configuration "$CONFIGURATION"
  -destination 'platform=macOS'
  -derivedDataPath "$DERIVED"
  MARKETING_VERSION="$MARKETING"
  CURRENT_PROJECT_VERSION="$BUILD"
  ENABLE_HARDENED_RUNTIME=YES
)

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  BUILD_ARGS+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION"
    DEVELOPMENT_TEAM="$TEAM_ID"
  )
else
  BUILD_ARGS+=(CODE_SIGN_IDENTITY="-")
fi

if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  BUILD_ARGS+=(SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_ED_KEY")
fi

echo "==> xcodebuild Release"
xcodebuild "${BUILD_ARGS[@]}" build

APP_SRC="$DERIVED/Build/Products/$CONFIGURATION/ButterKeys.app"
[[ -d "$APP_SRC" ]] || { echo "Missing $APP_SRC" >&2; exit 1; }

APP_DST="$DIST/ButterKeys.app"
rm -rf "$APP_DST"
cp -R "$APP_SRC" "$APP_DST"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo "==> codesign (Developer ID + hardened runtime)"
  codesign --force --deep --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP_DST"

  codesign --verify --deep --strict --verbose=2 "$APP_DST"
fi

if [[ "$SKIP_NOTARIZE" == "0" && "$DRY_RUN" == "0" && -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo "==> Zip for notarization"
  ZIP_PATH="$DIST/$ZIP_NAME"
  rm -f "$ZIP_PATH"
  ditto -c -k --keepParent "$APP_DST" "$ZIP_PATH"

  echo "==> notarytool submit (profile: $NOTARY_PROFILE)"
  xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

  echo "==> stapler staple"
  xcrun stapler staple "$APP_DST"
  xcrun stapler validate "$APP_DST"
else
  echo "==> Skipping notarization (dry-run or --skip-notarize)"
fi

echo "==> Create DMG"
DMG_PATH="$DIST/$DMG_NAME"
STAGE="$DIST/dmg-stage"
rm -rf "$STAGE" "$DMG_PATH"
mkdir -p "$STAGE"
cp -R "$APP_DST" "$STAGE/ButterKeys.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "ButterKeys" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" && "$SKIP_NOTARIZE" == "0" && "$DRY_RUN" == "0" ]]; then
  echo "==> Sign + notarize DMG"
  codesign --force --sign "$DEVELOPER_ID_APPLICATION" "$DMG_PATH"
  DMG_ZIP="$DIST/${DMG_NAME}.zip"
  ditto -c -k "$DMG_PATH" "$DMG_ZIP"
  xcrun notarytool submit "$DMG_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  rm -f "$DMG_ZIP"
fi

# Sparkle appcast assets
UPDATES="$DIST/updates"
cp "$DMG_PATH" "$UPDATES/"

SIGN_UPDATE=""
GENERATE_APPCAST=""
for candidate in \
  "$DERIVED/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" \
  "$DERIVED/SourcePackages/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework/Versions/B/Resources/../../../../../bin/sign_update" \
  "$(find "$DERIVED/SourcePackages" -name sign_update -type f 2>/dev/null | head -1)"; do
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    SIGN_UPDATE="$candidate"
    break
  fi
done
GENERATE_APPCAST="$(find "$DERIVED/SourcePackages" -name generate_appcast -type f 2>/dev/null | head -1 || true)"

PRIVATE_KEY="${SPARKLE_PRIVATE_KEY_FILE:-$ROOT/secrets/sparkle_ed_private_key}"

if [[ -n "$GENERATE_APPCAST" && -f "$PRIVATE_KEY" ]]; then
  echo "==> generate_appcast"
  "$GENERATE_APPCAST" --ed-key-file "$PRIVATE_KEY" "$UPDATES"
elif [[ -n "$SIGN_UPDATE" && -f "$PRIVATE_KEY" ]]; then
  echo "==> sign_update (manual appcast stub)"
  SIG="$("$SIGN_UPDATE" --ed-key-file "$PRIVATE_KEY" "$UPDATES/$DMG_NAME")"
  LENGTH="$(stat -f%z "$UPDATES/$DMG_NAME")"
  PUB_DATE="$(date -u '+%a, %d %b %Y %H:%M:%S +0000')"
  cat > "$UPDATES/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>ButterKeys</title>
    <language>en</language>
    <item>
      <title>Version ${MARKETING}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${MARKETING}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[<p>ButterKeys ${MARKETING} — see CHANGELOG.md</p>]]></description>
      <enclosure
        url="https://github.com/timbenniks/butterkeys/releases/download/${VERSION_TAG}/${DMG_NAME}"
        length="${LENGTH}"
        type="application/octet-stream"
        ${SIG}
      />
    </item>
  </channel>
</rss>
EOF
else
  cat > "$UPDATES/README.md" <<EOF
# Sparkle updates folder

Place \`${DMG_NAME}\` here and run Sparkle \`generate_appcast\` after:

  ./scripts/setup-sparkle-keys.sh

Private key expected at: secrets/sparkle_ed_private_key
EOF
  echo "==> Appcast skipped (missing Sparkle tools or private key)"
fi

cat > "$DIST/RELEASE_NOTES.md" <<EOF
# ButterKeys ${MARKETING} (build ${BUILD})

See [CHANGELOG.md](../CHANGELOG.md).

## Install

1. Open \`${DMG_NAME}\`
2. Drag ButterKeys to Applications
3. Open from Applications (not the DMG)
4. Enable Input Monitoring + Accessibility
5. Quit and reopen ButterKeys

## Publish

\`\`\`bash
gh release create ${VERSION_TAG} \\
  --title "ButterKeys ${MARKETING}" \\
  --notes-file dist/RELEASE_NOTES.md \\
  dist/${DMG_NAME} \\
  dist/updates/appcast.xml
\`\`\`

Upload \`appcast.xml\` as a release asset named \`appcast.xml\` so the feed URL resolves:

\`https://github.com/timbenniks/butterkeys/releases/latest/download/appcast.xml\`
EOF

echo
echo "Done. Artifacts in $DIST"
echo "  App:  $APP_DST"
echo "  DMG:  $DMG_PATH"
echo "  Notes: $DIST/RELEASE_NOTES.md"
if [[ "$DRY_RUN" == "1" || -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo
  echo "NOTE: Notarized public builds require Developer ID + notarytool profile '$NOTARY_PROFILE'."
fi
