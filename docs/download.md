# Download ButterKeys (early testers)

**Typing, but smoother.** Local-first typing correction for macOS 14+.

## Get the app

1. Download the latest **`ButterKeys-*.dmg`** from [GitHub Releases](https://github.com/timbenniks/butterkeys/releases/latest).
2. Open the DMG and drag **ButterKeys** into **Applications**.
3. Eject the DMG, then open ButterKeys from Applications (not from the disk image).

## Permissions (required)

ButterKeys needs two macOS permissions. Grant them for the copy in `/Applications` only:

1. **System Settings → Privacy & Security → Input Monitoring** → enable ButterKeys  
2. **System Settings → Privacy & Security → Accessibility** → enable ButterKeys  
3. Quit ButterKeys completely and open it again from Applications

If corrections never fire, you are usually looking at the wrong binary (Xcode DerivedData) or a permission that was not re-granted after a re-sign.

## Quick test

In Notes, type `teh` and a space. It should become `the`. Undo with **Control-Option-Z**.

## What to expect

- High-confidence personal typos are smoothed automatically
- Short foreign words (e.g. Dutch) are left alone more often
- Code editors use a narrower “code-safe” mode
- Optional HUD + sound when a correction applies (Settings → General)
- In-app updates via Sparkle (Settings → Check for Updates…)

## Privacy

Your typing stays on your Mac. Update checks only hit the release feed.  
Details: [Privacy](privacy/PRIVACY.md) · [Known limitations](../KNOWN_LIMITATIONS.md)

## Feedback

Please file issues with the templates:

- [False positive](https://github.com/timbenniks/butterkeys/issues/new?template=false-positive.md) — corrected something it shouldn’t have  
- [Missed correction](https://github.com/timbenniks/butterkeys/issues/new?template=missed-correction.md) — should have corrected but didn’t  
- [Install / permissions](https://github.com/timbenniks/butterkeys/issues/new?template=install-permissions.md)

Or use **Settings → About → Report a problem**.

For support, you can also paste **Settings → Advanced → Copy redacted diagnostics** (no sentences or raw keystrokes).
