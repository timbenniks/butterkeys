# Release QA checklist

Run before inviting testers or cutting a notarized build. Check each item on a clean Mac (or a VM) when possible.

## Install

- [ ] DMG opens; ButterKeys.app and Applications symlink visible
- [ ] Gatekeeper accepts the notarized app (no “unidentified developer” block)
- [ ] App launched from **Applications**, not from the DMG
- [ ] First launch shows onboarding / permission guidance

## Permissions

- [ ] ButterKeys appears under **Input Monitoring** and can be enabled
- [ ] ButterKeys appears under **Accessibility** and can be enabled
- [ ] After both grants: quit and reopen from Applications
- [ ] Menu bar shows smoothing / active status (not “needs permission”)

## Core corrections (Notes or TextEdit)

- [ ] `teh ` → `the `
- [ ] `soem ` → `some `
- [ ] `jsut ` → `just `
- [ ] `writign ` → `writing `
- [ ] Undo via **⌃⌥Z** or menu bar restores the original
- [ ] Correction HUD and/or sound fire when those settings are enabled

## Safety

- [ ] Terminal: no automatic corrections
- [ ] Password field / secure input: monitoring pauses / no corrections
- [ ] WhatsApp (or similar) Dutch short words (`met`, `kan`, `nog`, `soms`) are **not** swapped to English
- [ ] Cursor / VS Code: `teh` or `writigg` can correct (code-safe); identifiers are not mangled aggressively

## Updates & offline

- [ ] Settings → Check for Updates… opens Sparkle UI (or reports up to date)
- [ ] With network off: corrections still work; update check fails softly
- [ ] Launch at login works after reboot (if enabled)

## Diagnostics

- [ ] Settings → Advanced shows event tap, frontmost app, last correction
- [ ] “Copy redacted diagnostics” pastes status without sentences/keystroke logs

## Regression

- [ ] `./scripts/version.sh` matches About version
- [ ] Unit tests green locally / CI
- [ ] [KNOWN_LIMITATIONS.md](../../KNOWN_LIMITATIONS.md) still accurate

## Sign-off

| Role | Name | Date |
|---|---|---|
| Builder | | |
| Soak tester | | |
