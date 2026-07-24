# Cutting ButterKeys v1.0.0

Checklist for the first notarized tester release.

## Prerequisites (one-time)

1. **Developer ID Application** certificate installed in Keychain  
   (Apple Developer → Certificates → Developer ID Application)  
   Currently this machine only has *Apple Development* — notarized Gatekeeper installs need Developer ID.
2. **notarytool** profile:

```bash
xcrun notarytool store-credentials ButterKeys-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id 38S7FN2F8A \
  --password app-specific-password
```

3. Sparkle keys (already generated locally):

```bash
./scripts/setup-sparkle-keys.sh
# Back up secrets/sparkle_ed_private_key off-machine
```

4. GitHub repo `timbenniks/butterkeys` with Releases enabled (adjust feed URL in `project.yml` if the repo name differs).

## Build & notarize

```bash
./scripts/version.sh                 # expect 1.0.0 (1)
./scripts/release.sh                 # full sign + notarize + DMG + appcast
```

Dry-run (no notarization — useful while waiting on Developer ID):

```bash
./scripts/release.sh --dry-run
```

## Publish

```bash
gh release create v1.0.0 \
  --title "ButterKeys 1.0.0" \
  --notes-file dist/RELEASE_NOTES.md \
  dist/ButterKeys-1.0.0.dmg \
  dist/updates/appcast.xml
```

Ensure `appcast.xml` is attached so this URL resolves:

`https://github.com/timbenniks/butterkeys/releases/latest/download/appcast.xml`

## Invite

Send [TESTER_INVITE.md](TESTER_INVITE.md) to 3–5 people. Ask them to run [RELEASE_QA.md](RELEASE_QA.md) lightly and file issues with the templates.

## Soak

You run the notarized build daily for ~1 week before a broader public link. Log false positives as issues.

## Status

| Step | Status |
|---|---|
| Version 1.0.0 locked | Ready |
| Release script | Ready |
| Sparkle keys | Ready (local Keychain + `secrets/`) |
| Developer ID + notarize | **Blocked until Developer ID cert is installed** |
| GitHub Release v1.0.0 | Pending notarized DMG |
| Tester invites | Pending Release |
