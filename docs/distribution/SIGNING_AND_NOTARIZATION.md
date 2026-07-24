# Signing and notarization

ButterKeys is prepared for direct distribution outside the Mac App Store.

## One-time setup

1. **Developer ID Application** certificate in Keychain (Apple Developer → Certificates).
2. **notarytool** keychain profile:

```bash
xcrun notarytool store-credentials ButterKeys-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id 38S7FN2F8A \
  --password app-specific-password
```

3. **Sparkle EdDSA keys** (once):

```bash
./scripts/setup-sparkle-keys.sh
```

Back up `secrets/sparkle_ed_private_key`. The public key is written to `project.yml` / `Config/SparklePublicEDKey.xcconfig`.

## Scripted release (preferred)

```bash
chmod +x scripts/*.sh
./scripts/version.sh                # e.g. 1.0.0 (1)
./scripts/release.sh --bump-build   # or omit --bump-build for first cut
```

Environment overrides:

| Variable | Purpose |
|---|---|
| `DEVELOPER_ID_APPLICATION` | Codesign identity |
| `NOTARY_PROFILE` | notarytool profile (default `ButterKeys-notary`) |
| `TEAM_ID` | Apple Team ID (default `38S7FN2F8A`) |
| `SPARKLE_PRIVATE_KEY_FILE` | Path to Sparkle private key |

Flags:

- `--dry-run` — build Release artifacts without notarizing
- `--skip-notarize` — sign + DMG only
- `--bump-build` — increment `CURRENT_PROJECT_VERSION` first

Artifacts land in `dist/`:

- `ButterKeys.app`
- `ButterKeys-X.Y.Z.dmg`
- `updates/appcast.xml` (when Sparkle tools + private key are present)
- `RELEASE_NOTES.md` with `gh release create` commands

## Development

1. `xcodegen generate`
2. Open `ButterKeys.xcodeproj`
3. Select a Development Team for automatic signing, or use Sign to Run Locally
4. For Input Monitoring / Accessibility testing, prefer `./scripts/install-dev.sh` → `/Applications/ButterKeys.app`

## Manual release build

```bash
xcodegen generate
xcodebuild -scheme ButterKeys -configuration Release -derivedDataPath .derivedData build
```

App output (typical):

`.derivedData/Build/Products/Release/ButterKeys.app`

## Manual signing

1. Use a Developer ID Application certificate
2. Enable Hardened Runtime
3. Keep entitlements from `Config/ButterKeys.entitlements`
4. Codesign the app and embedded frameworks:

```bash
codesign --deep --force --options runtime \
  --entitlements Config/ButterKeys.entitlements \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  path/to/ButterKeys.app
```

Verify:

```bash
codesign --verify --deep --strict --verbose=2 path/to/ButterKeys.app
spctl --assess --type execute -vv path/to/ButterKeys.app
```

## Manual notarization

```bash
ditto -c -k --keepParent path/to/ButterKeys.app ButterKeys.zip
xcrun notarytool submit ButterKeys.zip --keychain-profile ButterKeys-notary --wait
xcrun stapler staple path/to/ButterKeys.app
```

## DMG packaging

`scripts/release.sh` builds a UDZO DMG with the app and an Applications symlink. Notarize the DMG when distributing that container (the script does this when not skipping notarization).

## Sparkle feed

Feed URL (Info.plist `SUFeedURL`):

`https://github.com/timbenniks/butterkeys/releases/latest/download/appcast.xml`

Publish `appcast.xml` and the DMG on each GitHub Release. Update checks never receive typing data.

## Privacy implications

Notarization uploads the binary to Apple for malware scanning. It does not grant Apple access to user typing data at runtime. Typing data never leaves the Mac during normal use.

## Known macOS limitations

See [KNOWN_LIMITATIONS.md](../../KNOWN_LIMITATIONS.md).
