# Privacy

Your typing stays on your Mac.

ButterKeys processes a small amount of recent typing locally so it can detect recurring mistakes.

It does not send your typing anywhere, store complete sentences, or monitor secure password fields.

When learning is enabled, ButterKeys saves small correction pairs such as “soem” → “some”.

## What is stored

| Data | Purpose |
|---|---|
| Explicit rules | User and seeded smoothers |
| Learned typo pairs | Compact source → replacement stats |
| Motor pattern aggregates | Key-confusion signals (no full text) |
| Correction history (optional) | Recent compact corrections, default 30-day retention |
| App policies | Per-app modes / exclusions |
| Settings | Preferences only |

## What is never stored

- Full sentences or paragraphs
- Raw keystroke logs
- Passwords / secure field contents
- Clipboard contents
- Rolling buffer contents (memory-only)

## Network

Correction does not use the network. The app avoids networking entitlements for typing.

Sparkle may contact the configured HTTPS update feed (`SUFeedURL`) to check for new versions. That traffic contains no typing data, correction history, or diagnostics. You can ignore update prompts; corrections keep working offline.

## User controls

Settings → Privacy provides export, delete history, delete learned data, and delete all ButterKeys data.
