# Changelog

All notable changes to ButterKeys are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-07-24

### Added

- Teach-from-selection (`⌃⌥T` / menu) to save personal typo → correction rules
- **Taught only** auto-correct mode (default): only explicit / taught rules fire
- Full editors for Rules, Dictionary, and Applications (add / edit / remove in-content)
- Skip auto-correct when the user backspaces inside the current word (editing, not finishing a typo)
- Insert a space when a correction is glued to a period (`Hello.teh` → `Hello. the`)
- Backspace learning wired into the live keystroke path; accepting suggestions creates real rules
- Direct-distribution release pipeline (`scripts/release.sh`): Developer ID sign, notarize, staple, DMG
- Sparkle in-app updates (GitHub Releases appcast)
- Correction HUD feedback and optional sound
- Short-token safety so common Dutch words are not “corrected” to English
- Code-safe mode for IDEs (Cursor, VS Code, Xcode, JetBrains)

### Changed

- Confidence presets: Taught only / Conservative / Balanced / Enthusiastic
- IDE defaults use code-safe mode instead of fully disabled
- Learning settings lead with teach-first guidance

### Privacy

- Local-first; update checks contact only the Sparkle feed URL; typing data never leaves the Mac
