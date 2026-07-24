# Changelog

All notable changes to ButterKeys are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-07-23

### Added

- Direct-distribution release pipeline (`scripts/release.sh`): Developer ID sign, notarize, staple, DMG
- Sparkle in-app updates (GitHub Releases appcast)
- Version display in Settings → About / Advanced
- Redacted diagnostics copy for tester support
- Correction HUD feedback and optional sound
- Short-token safety so common Dutch words are not “corrected” to English
- Broader code-safe strategies in IDEs (e.g. Cursor) for motor typos like `writigg` → `writing`
- Release QA checklist, download notes, and GitHub issue templates

### Changed

- IDE defaults use code-safe mode instead of fully disabled
- Signing docs cover the scripted release path

### Privacy

- Update checks contact only the Sparkle feed URL; typing data never leaves the Mac
