# Phase 03 — Pattern engine

**Status:** Done

## Scope

- Adjacent transposition, nearby-key, NGGN, short permutation
- Extra / missing / duplicate character strategies
- Local dictionary + frequency + Damerau-Levenshtein
- CandidateScorer + ConfidencePolicy

## Success criteria

- [ ] `gove me` → `give me`, `buidl` → `build`, `writign` → `writing`, `typoes` → `typos`
- [ ] `love` / `move` / `gave` / `gnome` unchanged without strong context
