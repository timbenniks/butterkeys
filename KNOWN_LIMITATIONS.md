# Known limitations

ButterKeys fails safe: when uncertain, original text is left unchanged.

## Event taps

- macOS may disable a `CGEventTap` under load or after permission changes. ButterKeys attempts recovery; a restart may still be required.
- Some apps consume events before a listen-only tap can observe them reliably.

## Accessibility and secure input

- `IsSecureEventInputEnabled()` covers system secure entry; not every custom password field sets AX secure subroles correctly.
- Accessibility trust can be revoked while running; monitoring pauses until restored.

## Application compatibility

- Electron / Chromium text controls vary; synthetic Unicode insertion may be less reliable than in AppKit fields.
- Games, remote desktop, and VM consoles are excluded by default and may still behave oddly if re-enabled.
- Code editors (Xcode, VS Code, Cursor, JetBrains, …) default to **code-safe** mode: motor-pattern fixes only, not full prose autocorrect. Enabling prose mode there can corrupt identifiers.

## Languages

- Scoring and the bundled dictionary are English-biased.
- Short unknown tokens (≤4 letters) are treated conservatively so common words in other languages (e.g. Dutch `met`, `kan`, `nog`) are less often “corrected” into English.
- Full multilingual / IME-aware correction is not implemented yet.
- Composed text / IME sessions are not fully modeled; the buffer resets on input-source changes.

## Replacement and undo

- Primary path uses synthetic CGEvents; clipboard fallback is optional and off by default.
- Host-app Undo (⌘Z) is not guaranteed to reverse ButterKeys corrections; use **Control-Option-Z** or the menu bar undo.
- Extremely fast typing during a replacement window can race the synthetic sequence (fail-safe leaves text alone when state is unclear).
- Early-space / split-word fixes (e.g. `hav ebeen`) are not applied in code-safe mode.

## Learning

- Primary path: select a typo and press **⌃⌥T** (or menu → Teach) to save an explicit rule.
- Manual correction detection watches backspace-then-retype on the live keystroke path. It only stores compact token pairs, then offers suggestions that become real rules when accepted.
- `learningRepetitionThreshold` in Settings drives when observations become pending suggestions.

## Distribution and updates

- Mac App Store sandboxing is likely incompatible with global event taps for v1; direct distribution is the supported path.
- Notarization and Hardened Runtime are required for smooth Gatekeeper installs on other Macs.
- Sparkle contacts only the configured HTTPS appcast URL. Update traffic never includes typing data.

## Performance

- Dictionary candidate scans are bounded but can grow with dictionary size; keep bundled lists compact.
- Never put SQLite or file I/O on the event-tap callback thread (architecture enforces this; do not regress).

Keep this file updated when new platform quirks are confirmed.
