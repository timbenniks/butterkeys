# ButterKeys phases

Phased roadmap derived from [spec.md](../spec.md). Build order follows the vertical-slice principle: prove monitoring → replacement → undo → exclusions before expanding UI and learning.

| Phase | Name | Status | Goal |
|-------|------|--------|------|
| 01 | Input prototype | Done | Menu bar app, permissions, event tap, buffer, exclusions |
| 02 | Explicit rules | Done | SQLite, direct rules, synthetic replace, undo |
| 03 | Pattern engine | Done | Strategies + confidence scoring |
| 04 | Boundary correction | Done | Early-space, shifted-boundary, phrases |
| 05 | Learning | Done | Manual correction detection, suggestions, undo penalties |
| 06 | Product polish | Done | Onboarding, settings, privacy, docs, packaging notes |

## Phase completion checklist

Before marking a phase done:

1. Success criteria in the phase doc are met or explicitly deferred with rationale.
2. Correction logic stays outside UI code.
3. No typed content logged or persisted beyond compact pairs/history.
4. Unit tests for new strategies/fixtures pass.
5. Event-tap callback remains lightweight (no SQLite/dictionary I/O).
6. Update this table and the phase doc status.

## Principle

```text
When taught or confident, smooth it.
When uncertain, leave it alone.
```

Default auto-correct is **Taught only** (explicit / taught rules). Speculative pattern strategies are opt-in via Conservative / Balanced / Enthusiastic.