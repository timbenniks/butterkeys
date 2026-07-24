# Dictionary attribution

## word_frequencies.tsv

Compact English word list curated for ButterKeys offline correction.

- Purpose: local dictionary membership + relative frequency signals
- License: CC0 / public-domain style curated subset for this project
- Preprocessing: lowercased tokens, tab-separated `word<TAB>frequency`, Zipf-like weights in 0–1
- Not a full corpus dump; includes fixture words required by the test suite

No network access is used to refresh this file at runtime.
