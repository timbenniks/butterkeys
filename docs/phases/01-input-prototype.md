# Phase 01 — Input prototype

**Status:** Done

## Scope

- Native `MenuBarExtra` app shell
- Input Monitoring + Accessibility permission detection
- `CGEventTap` with recovery
- Rolling in-memory buffer, timing, synthetic event guard
- Active app / secure input / exclusion policy
- Pause / resume
- Redacted diagnostics

## Success criteria

- [ ] Keystrokes observed in Notes (no persistence)
- [ ] Secure input pauses processing
- [ ] App switch resets buffer
- [ ] No perceptible typing latency

## Risks

See `KNOWN_LIMITATIONS.md` — event tap reliability, secure input detection, Electron apps.
