# Build ButterKeys, a local macOS typing correction assistant

Build a native macOS menu bar application called **ButterKeys**.

ButterKeys monitors keyboard input across macOS applications and corrects recurring typing mistakes in real time. It is designed around personal motor-pattern mistakes rather than generic spellchecking.

Examples of mistakes it should handle:

```text
teh → the
htis → this
loosk → looks
yoru → your
soem → some
jsut → just
gove → give
buidl → build
writign → writing
somethign → something
typoes → typos
int he app → in the app
typin gthis → typing this
```

ButterKeys must be local-first, private, fast, conservative, extensible, and easy to disable.

Primary tagline:

```text
Typing, but smoother.
```

## Product goals

ButterKeys should:

1. Monitor typing across most macOS applications.
2. Detect recurring personal typo patterns.
3. Correct high-confidence mistakes automatically.
4. Learn from repeated manual corrections.
5. Understand motor-pattern errors, not only dictionary misspellings.
6. Avoid passwords, secure input, terminals, code editors, and excluded apps.
7. Work entirely offline.
8. Never store full sentences or raw keystroke logs.
9. Feel instantaneous and invisible during normal typing.
10. Allow every automatic correction to be undone immediately.
11. Provide a polished native menu bar and settings interface.
12. Use restrained butter-themed humour throughout the experience.
13. Keep the correction engine modular so new detectors can be added easily.

The application must not rely on cloud AI services.

## Platform and technical stack

Use:

- macOS 14 or newer
- Swift 6
- SwiftUI
- AppKit where necessary
- Core Graphics `CGEventTap`
- Accessibility APIs
- Input Monitoring permission
- SQLite using GRDB.swift
- Swift Package Manager
- Xcode
- `MenuBarExtra`
- `OSLog`
- `ServiceManagement` for launch at login
- XCTest or Swift Testing

Do not use:

- Electron
- React Native
- Flutter
- web views
- cloud inference
- remote analytics
- online spellcheck services

Support Apple Silicon as the priority.

Intel support is desirable where practical.

Suggested bundle identifier:

```text
com.timbeniks.ButterKeys
```

Suggested executable name:

```text
ButterKeys
```

Suggested database filename:

```text
butterkeys.sqlite
```

## Product personality

ButterKeys should feel:

- native
- calm
- warm
- friendly
- private
- lightweight
- trustworthy
- polished
- slightly whimsical

The humour must never obscure:

- privacy information
- security state
- permission requirements
- correction behaviour
- error messages
- whether monitoring is active

Butter jokes should feel like seasoning, not the entire meal.

## Core architecture

Use a modular architecture.

```text
ButterKeys
├── App
│   ├── ButterKeysApp
│   ├── AppState
│   ├── MenuBarController
│   ├── WindowCoordinator
│   ├── PermissionCoordinator
│   └── LaunchAtLoginManager
│
├── Input
│   ├── KeyboardEventMonitor
│   ├── KeyboardEventProcessor
│   ├── KeyboardLayoutTranslator
│   ├── InputSourceMonitor
│   ├── InputBuffer
│   ├── KeystrokeTimingTracker
│   ├── ModifierState
│   └── SyntheticEventGuard
│
├── CorrectionEngine
│   ├── CorrectionCoordinator
│   ├── CorrectionCandidate
│   ├── CandidateGenerator
│   ├── CandidateScorer
│   ├── ConfidencePolicy
│   ├── ContextScorer
│   └── CorrectionStrategy
│
├── Strategies
│   ├── ExplicitRuleStrategy
│   ├── AdjacentTranspositionStrategy
│   ├── ShortPermutationStrategy
│   ├── NearbyKeySubstitutionStrategy
│   ├── NGGNStrategy
│   ├── EarlySpaceStrategy
│   ├── ShiftedBoundaryStrategy
│   ├── ExtraCharacterStrategy
│   ├── MissingCharacterStrategy
│   ├── DuplicateCharacterStrategy
│   └── PhraseRuleStrategy
│
├── Context
│   ├── ActiveApplicationMonitor
│   ├── FocusedElementInspector
│   ├── SecureInputDetector
│   ├── TextContextProvider
│   ├── ApplicationProfile
│   ├── ExclusionPolicy
│   └── SensitiveContextPolicy
│
├── Replacement
│   ├── TextReplacementExecutor
│   ├── SyntheticEventEmitter
│   ├── ClipboardReplacementExecutor
│   ├── CorrectionTransaction
│   └── ButterUndoManager
│
├── Learning
│   ├── ManualCorrectionDetector
│   ├── TypoPatternLearner
│   ├── PatternConfidenceTracker
│   ├── UserRejectionTracker
│   └── SuggestionCoordinator
│
├── Language
│   ├── LocalDictionary
│   ├── WordFrequencyStore
│   ├── PhraseFrequencyStore
│   ├── KeyboardAdjacencyMap
│   ├── DamerauLevenshtein
│   └── CasePatternPreserver
│
├── Persistence
│   ├── DatabaseManager
│   ├── DatabaseMigrator
│   ├── CorrectionRuleRepository
│   ├── LearnedPatternRepository
│   ├── CorrectionHistoryRepository
│   ├── ApplicationPolicyRepository
│   └── SettingsRepository
│
├── UI
│   ├── MenuBar
│   │   ├── MenuBarView
│   │   ├── MenuBarStatusIcon
│   │   └── LastCorrectionView
│   ├── Onboarding
│   │   ├── WelcomeView
│   │   ├── PrivacyExplanationView
│   │   ├── PermissionView
│   │   └── TypingTestView
│   ├── Settings
│   │   ├── GeneralSettingsView
│   │   ├── RulesView
│   │   ├── LearningView
│   │   ├── ApplicationsView
│   │   ├── HistoryView
│   │   ├── PrivacyView
│   │   └── AdvancedView
│   └── Components
│       ├── CorrectionRow
│       ├── ConfidenceBadge
│       ├── ApplicationPicker
│       └── EmptyStateView
│
└── Resources
    ├── Dictionary
    ├── PhraseData
    ├── Localizable.strings
    ├── Assets.xcassets
    └── DefaultRules.json
```

Keep all correction logic outside UI code.

Every correction strategy should conform to a shared protocol.

Conceptual example:

```swift
protocol CorrectionStrategy {
    var identifier: String { get }

    func candidates(
        for context: CorrectionContext
    ) -> [CorrectionCandidate]
}
```

## Global keyboard monitoring

Implement global keyboard monitoring using a Core Graphics event tap.

Listen for:

- key down
- flags changed
- relevant key up events where necessary

The event tap should:

- inspect keyboard input
- maintain a small rolling buffer
- identify word boundaries
- track timing between keys
- distinguish physical events from ButterKeys-generated events
- allow events to pass through unchanged by default
- suppress or replace events only when necessary
- recover if macOS disables the event tap

The event callback must remain extremely lightweight.

Do not:

- query SQLite inside the callback
- perform dictionary scans inside the callback
- block on the main thread
- write logs containing typed content
- call Accessibility APIs repeatedly from the callback

Pass lightweight normalized event data into a dedicated serial processing queue.

Use preloaded in-memory rule and dictionary caches.

## Keyboard layout handling

Do not assume a US keyboard layout.

Use the active macOS input source and translate key codes through the current keyboard layout.

Handle:

- alphabetic characters
- spaces
- punctuation
- shift
- caps lock
- option-modified characters
- delete
- forward delete where possible
- arrows
- tab
- return
- escape
- command shortcuts
- control shortcuts

Do not interpret text while Command or Control shortcuts are active.

Reset the rolling buffer when:

- the input source changes
- the active application changes
- the focused element changes significantly
- the user clicks elsewhere
- unsupported cursor movement occurs
- secure input starts
- monitoring pauses

Initially optimize language correction for English while remaining keyboard-layout aware.

## Input buffer

Maintain only the minimum text required for correction.

Suggested limits:

- current token
- previous token
- current phrase fragment
- approximately 100 recent characters maximum
- recent key timings
- recent deletion sequence

The rolling buffer must never be persisted.

Track:

- typed characters
- word boundaries
- punctuation
- backspaces
- cursor movement
- modifier state
- timestamps
- active application
- physical versus synthetic input
- possible manual correction sequences

Reset conservatively whenever text state becomes uncertain.

It is better to miss a correction than corrupt text.

## Correction timing

Prefer correction at safe boundaries.

Evaluate corrections after:

- space
- punctuation
- return
- tab
- completion of a high-confidence phrase pattern

Avoid aggressively rewriting text while the user is still forming a word.

For phrase-boundary mistakes such as:

```text
int he app
```

wait until enough context exists to determine:

```text
in the app
```

with high confidence.

## Correction candidate model

Each correction candidate should include:

```text
original text
replacement text
affected range
strategy identifier
confidence score
explanation
word-boundary requirement
application compatibility
automatic or suggestion-only recommendation
```

Suggested Swift structure:

```swift
struct CorrectionCandidate: Sendable {
    let original: String
    let replacement: String
    let affectedRange: Range<Int>
    let strategyID: String
    let confidence: Double
    let explanation: String
    let requiresBoundary: Bool
}
```

## Correction confidence

Use deterministic scoring for version one.

Suggested thresholds:

```text
0.00 to 0.59: no action
0.60 to 0.84: suggestion only
0.85 to 1.00: automatic correction
```

Allow internal configuration of thresholds.

Advanced settings may expose:

```text
Conservative
Balanced
Enthusiastic
```

Default to Balanced, but bias toward conservative behaviour.

## Candidate scoring

Consider:

- dictionary validity
- original word frequency
- candidate word frequency
- phrase frequency
- Damerau-Levenshtein distance
- number of moved characters
- adjacent-key likelihood
- user-specific correction history
- acceptance count
- undo count
- manual correction count
- timing between keystrokes
- case pattern
- surrounding token context
- active application mode
- whether the source token may be technical
- whether the candidate is a proper noun
- whether the token contains mixed case or symbols
- whether the input resembles code

Prior personal correction history should strongly influence ambiguous corrections.

Repeated undo should strongly lower confidence.

## Local dictionary

Bundle a permissively licensed English dictionary and word-frequency dataset.

Document:

- dataset source
- license
- attribution
- preprocessing steps

Load a compact optimized structure at application startup.

Possible structures:

- trie
- memory-mapped index
- normalized hash table
- frequency-ranked dictionary

Do not repeatedly parse a large text file while typing.

Support custom user words.

Allow users to mark a word as:

```text
Never correct this
Add to my dictionary
Treat as a name
```

## Typo categories

### 1. Explicit personal rules

Allow direct rules such as:

```text
teh → the
htis → this
yoru → your
loosk → looks
```

Rules should support:

- enabled or disabled
- case preservation
- whole-word matching
- phrase matching
- global scope
- app-specific scope
- automatic mode
- suggestion-only mode
- never-correct mode

Case preservation examples:

```text
teh → the
Teh → The
TEH → THE
```

Do not preserve bizarre mixed-case patterns unless explicitly configured.

### 2. Adjacent-letter transpositions

Detect reversed adjacent characters.

Examples:

```text
hte → the
htis → this
soem → some
jsut → just
adn → and
wiht → with
loosk → looks
yoru → your
```

Only correct automatically when:

- the source token is unknown or substantially less likely
- one adjacent swap creates a common valid word
- the candidate frequency is much higher
- surrounding context does not contradict it
- the confidence threshold is met

Use key timing as supporting evidence.

If two keys were pressed within a very small interval and arrived reversed, increase transposition confidence.

### 3. Short multi-character permutations

Handle mistakes where the intended letters are present but more than one adjacent swap is required.

Examples:

```text
buidl → build
freind → friend
recieve → receive
```

Use:

- bounded Damerau-Levenshtein distance
- character multiset comparison
- known personal patterns
- limited candidate generation
- frequency ranking

Do not generate every possible permutation.

For short words, consider candidates within a maximum distance of two edits.

For longer words, use indexed dictionary lookup rather than brute force.

### 4. Nearby-key substitutions

Handle recurring substitutions caused by nearby keys.

The user frequently mixes the `i`, `o`, and `p` keys.

Examples:

```text
gove → give
gove me → give me
pnto → into
woth → with
```

Do not globally replace every `o` with `i`.

Use a keyboard adjacency map and candidate scoring.

For:

```text
gove
```

the engine should determine that:

```text
give
```

is a much more likely word, differs by one nearby-key substitution, and fits common phrase contexts such as:

```text
give me
give this
give it
```

Nearby-key substitution confidence should consider:

- physical adjacency on the active keyboard layout
- candidate frequency
- phrase context
- repeated personal history
- whether the source is a valid word
- whether the replacement changes meaning

Because `love`, `move`, and `gave` are valid words, do not make aggressive substitutions without context.

Support a personal key-confusion profile.

Example stored relationship:

```text
i ↔ o
o ↔ p
i ↔ p
```

The learning system should infer which key pairs are commonly confused.

### 5. `gn` and `ng` pattern

Add a specialized detector for words where the intended `ng` sequence is typed as `gn`.

Examples:

```text
writign → writing
somethign → something
workign → working
buildign → building
nothign → nothing
```

Do not blindly replace all `gn` sequences.

Preserve legitimate words such as:

```text
gnome
gnostic
signature
magnet
signal
design
```

Candidate scoring should consider:

- suffix structures
- valid word forms
- common `-ing` endings
- dictionary frequency
- surrounding context
- personal correction history

The strategy should understand that:

```text
writign
```

is likely a mistyped `writing`, while:

```text
gnome
```

is already valid.

### 6. Early-space mistakes

Detect when space is pressed before the final character of the previous word.

Examples:

```text
typin gthis → typing this
somethin gelse → something else
buildin ga feature → building a feature
writin gabout → writing about
```

Evaluate moving the first character of the next token to the end of the previous token.

Only apply when both reconstructed tokens become substantially more likely.

Example:

```text
typin gthis
```

Candidates:

```text
typing this
typin gthis
```

Prefer `typing this` because both resulting words are valid and common.

### 7. Shifted-boundary mistakes

Detect when a letter intended for the next word appears at the end of the previous word.

Examples:

```text
int he → in the
fort he → for the
wit hthe → with the
andthe → and the
```

Evaluate:

- moving the final character of the previous token to the next token
- moving one or more characters across a space
- inserting a missing space
- shifting a boundary one character left or right

Example:

```text
int he app
```

should become:

```text
in the app
```

when context is prose.

Do not alter legitimate programming uses such as:

```text
int he = 4;
```

Code editors should remain excluded by default.

In prose mode, tokens such as `int` followed by `he` and a common noun strongly support `in the`.

### 8. Extra-character mistakes

Handle accidental extra letters.

Examples:

```text
typoes → typos
thhe → the
writting → writing
commment → comment
```

Use:

- edit distance
- duplicate-key timing
- dictionary frequency
- morphological patterns
- personal history

Be conservative when both source and candidate are valid words.

### 9. Missing-character mistakes

Handle missing letters.

Examples:

```text
implmentation → implementation
recgnize → recognize
becase → because
langauge → language
```

Use bounded dictionary candidates and frequency scoring.

Do not autocorrect technical identifiers.

### 10. Duplicate-key mistakes

Detect keys accidentally pressed twice.

Examples:

```text
thhe → the
commment → comment
appplication → application
```

Increase confidence when duplicate keystrokes occur within a very short timing window.

### 11. Phrase rules

Support phrase-level rules.

Examples:

```text
base don → based on
int he → in the
fort he → for the
```

Phrase rules must:

- match complete token boundaries
- preserve capitalization
- support app scope
- avoid modifying code contexts
- be inspectable in settings

Do not implement phrase correction as unrestricted substring replacement.

## Applying corrections

Use correction transactions.

A correction transaction should record:

- original text
- replacement text
- number of affected characters
- boundary character
- active application
- timestamp
- strategy
- confidence
- whether clipboard fallback was used

### Primary replacement method

Use synthetic Core Graphics keyboard events.

For a completed-word correction:

1. Let the user complete the word and type the boundary.
2. Evaluate the token.
3. Suppress or remove the boundary where needed.
4. Emit the required backspaces.
5. Insert the corrected text.
6. Reinsert the boundary.
7. Store a short-lived undo transaction.

Synthetic events must be tagged or tracked to prevent feedback loops.

### Clipboard fallback

For complex phrase replacements, support an optional clipboard-based fallback.

The fallback must:

- preserve the current clipboard
- record the pasteboard change count
- insert replacement text
- restore the prior clipboard only if the user has not changed it
- avoid sensitive applications
- be disabled by default where unnecessary
- never persist clipboard contents
- never log clipboard contents

Prefer synthetic Unicode events where reliable.

## Undo behaviour

Every automatic correction must be reversible.

Support:

- dedicated global ButterKeys undo shortcut
- undo from the menu bar
- a short-lived last-correction transaction
- optional integration with host-app undo where reliable

Suggested default shortcut:

```text
Control-Option-Z
```

Undo must restore the exact original text.

If a user repeatedly undoes the same correction:

1. reduce the pair confidence
2. change it to suggestion-only
3. eventually disable automatic correction
4. offer a clear rule control

Suggested message:

```text
This correction keeps getting undone.
ButterKeys will stop applying it automatically.
```

Actions:

```text
Suggest only
Disable rule
Keep correcting
```

## Learning from manual corrections

ButterKeys should detect likely manual correction sequences.

Example:

1. User types `implemnetation`.
2. User presses backspace several times.
3. User types `implementation`.
4. The replacement occurs in the same token position and shortly afterward.

Store only:

- source token
- replacement token
- occurrence count
- acceptance count
- undo count
- confidence
- correction category
- optional app bundle identifier
- first-seen timestamp
- last-seen timestamp

Never store:

- complete sentences
- surrounding paragraphs
- passwords
- clipboard contents
- entire window contents
- raw key history

After several observations, show:

```text
You often change “implemnetation” to “implementation”.
Smooth this automatically?
```

Actions:

```text
Always smooth
Suggest first
Not this one
Never change this
```

## Personal motor-pattern learning

ButterKeys should learn higher-level patterns, not only exact word pairs.

Examples:

```text
ng is often typed as gn
i is often replaced by o
o is often replaced by p
adjacent letters are frequently reversed
spaces are often pressed one character early
```

Store aggregated pattern statistics without storing full text.

Example model:

```text
pattern type: nearby-key substitution
source key: i
observed key: o
count: 18
confidence: 0.82
```

Use these statistics as scoring signals.

Do not automatically create broad replacement rules solely from a key-level pattern.

They should only increase confidence for dictionary-valid candidates.

## Secure input and sensitive contexts

ButterKeys must stop processing meaningful text when secure keyboard entry is active.

Do not process or store typing in:

- password fields
- macOS authentication prompts
- password managers
- secure text fields
- banking apps by default
- terminal applications
- SSH clients
- remote desktop applications
- virtual machines
- code editors by default
- development consoles
- games

Default exclusion list:

```text
com.apple.Terminal
com.googlecode.iterm2
dev.warp.Warp-Stable
com.1password.1password
com.agilebits.onepassword7
com.apple.keychainaccess
com.microsoft.VSCode
com.todesktop.230313mzl4w4u92
com.jetbrains.*
com.apple.dt.Xcode
com.github.wez.wezterm
net.kovidgoyal.kitty
com.parallels.desktop.console
com.vmware.fusion
com.microsoft.rdc.macos
```

Support wildcard-like bundle matching where needed.

The app must provide:

- default exclusions
- user-added exclusions
- per-app profiles
- temporary pause in current app

## Application modes

Support per-app modes.

### Disabled

No monitoring or correction.

### Plain text

Only direct and extremely high-confidence rules.

### Prose

Full correction engine.

### Code-safe

Only user-approved explicit replacements and selected typo rules.

No phrase restructuring.

No dictionary-based word substitutions unless manually approved.

### Custom

User-configurable strategies and thresholds.

Recommended defaults:

```text
Mail: Prose
Messages: Prose
Notes: Prose
Safari: Prose
Slack: Prose
ChatGPT: Prose
Xcode: Disabled
VS Code: Disabled
Terminal: Disabled
Password managers: Disabled
```

## Privacy requirements

ButterKeys must operate entirely offline.

It must include:

- no analytics SDK
- no advertising SDK
- no remote logging
- no cloud spellcheck
- no online dictionary lookups
- no account system
- no telemetry containing typed text
- no raw keystroke persistence
- no full-sentence persistence
- no clipboard persistence

Persist only:

- user rules
- learned typo pairs
- aggregated pattern statistics
- limited compact correction history
- settings
- excluded apps

Add a privacy screen with:

```text
Your typing stays on your Mac.
```

Supporting copy:

```text
ButterKeys processes a small amount of recent typing locally so it can detect recurring mistakes.

It does not send your typing anywhere, store complete sentences, or monitor secure password fields.

When learning is enabled, ButterKeys saves small correction pairs such as “soem” → “some”.
```

Optional lighter line:

```text
Your words are not going into the cloud, the fridge, or anywhere else.
```

Keep the direct explanation more prominent.

## Network protection

The app should not need network access.

Add development safeguards that make accidental network use obvious.

Where practical:

- avoid networking entitlements
- isolate any future update-checking component
- document every network-capable dependency
- include a test or audit confirming no networking framework is used in the correction engine

A future update checker must remain completely separate from typing data.

## Permissions onboarding

Create a polished onboarding flow.

### Step 1: Welcome

```text
Welcome to ButterKeys

Typing, but smoother.

ButterKeys quietly fixes the recurring little mistakes your fingers make before your brain can stop them.
```

### Step 2: Privacy

Explain that processing is local and full text is not stored.

### Step 3: Input Monitoring

```text
ButterKeys needs Input Monitoring so it can notice typing mistakes across your apps.

Keystrokes are processed locally and are not stored as a typing log.
```

Include a button that opens the correct macOS System Settings pane.

### Step 4: Accessibility

```text
ButterKeys needs Accessibility permission so it can replace a typo with corrected text.

It only makes changes when a correction has enough confidence.
```

### Step 5: Permission verification

Poll or refresh permission state safely.

Do not repeatedly nag if permission is denied.

### Step 6: Local typing test

Provide a safe native text field.

Prompt:

```text
Try typing one of these:

teh
soem
jsut
gove me
buidl
writign
int he app
```

Success state:

```text
Smooth.

ButterKeys is working.
```

### Step 7: Enable monitoring

Show:

```text
ButterKeys is ready to smooth.
```

## Menu bar interface

Use a native monochrome menu bar icon.

Suggested menu:

```text
ButterKeys: Smooth

Smoothed today: 24

Last smooth
soem → some

Undo last smooth
Pause for 15 minutes
Pause for 1 hour
Pause until tomorrow
Pause in this app
Stop smoothing

Open ButterKeys
Settings
Quit ButterKeys
```

Possible active states:

```text
ButterKeys is smoothing
Typing is smooth
Smooth mode is on
ButterKeys is ready
```

Possible paused states:

```text
ButterKeys is resting
Smoothing paused
ButterKeys is chilled
```

Do not use unclear jokes for security-sensitive states.

Secure input should say:

```text
ButterKeys is paused for secure input.
```

Permission problem should say:

```text
ButterKeys needs permission to smooth typing.
```

## Main application window

Use a native SwiftUI settings-style window.

Use a sidebar with:

- General
- Rules
- Learning
- Applications
- History
- Privacy
- Advanced

Avoid a corporate analytics dashboard aesthetic.

### General

Include:

- Enable ButterKeys
- Launch at login
- Correction confidence
- Dedicated undo shortcut
- Show correction feedback
- Play subtle correction sound
- Keep limited correction history
- Butter level

### Rules

Suggested heading:

```text
Your smoothers
```

Show:

- typed form
- corrected form
- rule type
- confidence
- times used
- app scope
- enabled state
- automatic or suggest-only

Allow:

- add
- edit
- delete
- pause
- search
- import
- export
- convert learned pattern into explicit rule

Button:

```text
Add smoother
```

Underlying code may continue calling these correction rules.

### Learning

Include:

- Learn from manual corrections
- Learn motor patterns
- Minimum repetitions before suggestion
- Pending suggestions
- Rejected patterns
- Clear learned data

Pending suggestion example:

```text
You often change “gove” to “give”.
Smooth this automatically?
```

### Applications

Include:

- installed application list
- detected app icon
- bundle identifier
- active mode
- enabled strategies
- confidence override
- add application
- reset defaults

Allow the user to choose:

```text
Disabled
Plain text
Prose
Code-safe
Custom
```

### History

Suggested heading:

```text
Smoothing history
```

Show compact records:

- timestamp
- source token
- replacement token
- application
- strategy
- confidence
- undone status

Allow:

- search
- filter by app
- filter by strategy
- clear history
- disable history

Default retention:

```text
30 days
```

Do not store surrounding sentence content.

### Privacy

Include:

- local-processing explanation
- secure-input explanation
- stored-data breakdown
- open data folder
- export learned rules
- delete history
- delete learned data
- delete all data

Primary destructive action:

```text
Delete all ButterKeys data
```

### Advanced

Include:

- automatic correction threshold
- suggestion threshold
- event tap diagnostics
- permission diagnostics
- dictionary information
- phrase model information
- synthetic event mode
- clipboard fallback toggle
- debug logging toggle
- reset correction engine

Debug views must redact typed content.

## Butter level

Centralize all user-facing copy.

Do not hard-code playful language across views.

Use localized string keys or a copy provider.

Implement a setting:

```text
Butter level
```

Options:

### Plain

```text
Correction applied
Correction history
Pause corrections
Automatic corrections
```

### Lightly buttered

Default.

```text
Smoothed
Smoothing history
Pause smoothing
Automatic smoothing
```

### Extra buttery

```text
Another typo melted away
ButterKeys caught a slippery one
Your typing is nicely buttered
Smooth as toast
```

Even in Extra buttery mode, keep these areas direct:

- privacy
- permissions
- errors
- security
- destructive actions
- monitoring status

## Correction feedback

Do not display a notification for every correction by default.

Optional subtle feedback:

```text
soem → some
```

Possible lightly buttered messages:

```text
Smoothed.
That slipped.
Back in the right order.
```

Possible extra buttery messages:

```text
Another typo melted away.
ButterKeys caught a slippery one.
Letters successfully unjumbled.
Freshly smoothed.
```

Use a small temporary indicator.

Do not interrupt typing focus.

## Empty states

Rules:

```text
No personal smoothers yet.

ButterKeys will suggest one when it notices a recurring pattern.
```

History:

```text
Nothing smoothed yet.

Either your typing is flawless or ButterKeys has just arrived.
```

Learning:

```text
No new patterns yet.

Keep typing. Your fingers will provide research.
```

Applications:

```text
No additional excluded apps.

ButterKeys already avoids secure fields and sensitive applications.
```

## Error states

Permission missing:

```text
ButterKeys cannot smooth typing yet.

Enable Input Monitoring and Accessibility in System Settings.
```

Event tap stopped:

```text
ButterKeys lost access to keyboard events.

Restore permissions or restart ButterKeys.
```

Database failure:

```text
ButterKeys could not save this correction.

Typing will continue normally.
```

Secure input:

```text
ButterKeys is paused for secure input.
```

Correction failure:

```text
ButterKeys could not safely apply that correction.

Your original text was left unchanged.
```

Always fail safely.

## Data model

Use SQLite with migrations.

Suggested tables:

```sql
CREATE TABLE correction_rules (
    id TEXT PRIMARY KEY NOT NULL,
    source TEXT NOT NULL,
    replacement TEXT NOT NULL,
    match_type TEXT NOT NULL,
    preserve_case INTEGER NOT NULL DEFAULT 1,
    case_sensitive INTEGER NOT NULL DEFAULT 0,
    app_bundle_id TEXT,
    application_mode TEXT,
    behaviour TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE learned_patterns (
    id TEXT PRIMARY KEY NOT NULL,
    source TEXT NOT NULL,
    replacement TEXT NOT NULL,
    pattern_type TEXT NOT NULL,
    observed_count INTEGER NOT NULL DEFAULT 0,
    accepted_count INTEGER NOT NULL DEFAULT 0,
    undo_count INTEGER NOT NULL DEFAULT 0,
    confidence REAL NOT NULL DEFAULT 0,
    app_bundle_id TEXT,
    status TEXT NOT NULL,
    first_seen_at DATETIME NOT NULL,
    last_seen_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE motor_patterns (
    id TEXT PRIMARY KEY NOT NULL,
    pattern_type TEXT NOT NULL,
    source_value TEXT NOT NULL,
    observed_value TEXT NOT NULL,
    occurrence_count INTEGER NOT NULL DEFAULT 0,
    confidence REAL NOT NULL DEFAULT 0,
    first_seen_at DATETIME NOT NULL,
    last_seen_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE correction_history (
    id TEXT PRIMARY KEY NOT NULL,
    source TEXT NOT NULL,
    replacement TEXT NOT NULL,
    correction_type TEXT NOT NULL,
    app_bundle_id TEXT,
    confidence REAL NOT NULL,
    was_undone INTEGER NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE application_policies (
    id TEXT PRIMARY KEY NOT NULL,
    bundle_identifier TEXT NOT NULL UNIQUE,
    display_name TEXT,
    mode TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE custom_words (
    id TEXT PRIMARY KEY NOT NULL,
    word TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    created_at DATETIME NOT NULL
);
```

```sql
CREATE TABLE settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
);
```

Use migrations from the first commit.

## Initial bundled rules and fixtures

Seed conservative common rules:

```text
teh → the
hte → the
htis → this
tihs → this
yoru → your
loosk → looks
adn → and
wiht → with
soem → some
jsut → just
```

Add the following as personal examples and test fixtures:

```text
gove → give
buidl → build
writign → writing
somethign → something
workign → working
buildign → building
typoes → typos
base don → based on
int he → in the
```

Do not force every example into a globally active direct replacement rule.

Where possible, allow the appropriate correction strategy to detect it.

For example:

```text
soem → some
```

should be detected by the adjacent transposition strategy.

```text
gove → give
```

should be detected by the nearby-key substitution strategy plus phrase context.

```text
buidl → build
```

should be detected by the short permutation strategy.

```text
writign → writing
```

should be detected by the `gn` and `ng` strategy.

```text
int he → in the
```

should be detected by the shifted-boundary strategy.

```text
typoes → typos
```

should be detected by the extra-character strategy.

## Test fixtures

Add unit and integration fixtures for all observed patterns.

### Adjacent transpositions

```text
I made soem changes
I made some changes

Please jsut fix this
Please just fix this

Htis should work
This should work
```

### Nearby-key substitutions

```text
Please gove me the file
Please give me the file

Can you gove this a title?
Can you give this a title?
```

Add ambiguous cases that must not be changed without context:

```text
I love this
I love this

Move the file
Move the file

He gave me the file
He gave me the file
```

### Multi-character permutations

```text
Please buidl the app
Please build the app

Can we buidl this?
Can we build this?
```

### `gn` and `ng`

```text
I am writign this message
I am writing this message

This is somethign useful
This is something useful

We are buildign the app
We are building the app
```

Legitimate cases:

```text
The gnome is here
The gnome is here

This is a signature
This is a signature

The magnet is strong
The magnet is strong
```

### Shifted spaces

```text
There are jokes int he app
There are jokes in the app

We should include this fort he user
We should include this for the user

I wrote it wit hthe new keyboard
I wrote it with the new keyboard
```

### Early spaces

```text
I am typin gthis now
I am typing this now

We are buildin ga feature
We are building a feature
```

### Extra characters

```text
I keep making typoes
I keep making typos

This has thhe wrong word
This has the wrong word
```

### Combined sentence fixtures

```text
Please gove me the full prompt, not jsut the update.
Please give me the full prompt, not just the update.

We could create soem butter jokes int he app.
We could create some butter jokes in the app.

Can we buidl this and fix the typoes?
Can we build this and fix the typos?

I am writign somethign int he app.
I am writing something in the app.
```

## Manual correction learning tests

Test sequences such as:

```text
type: implemnetation
delete: 8 characters
type: mentation
result: implementation
```

Verify that ButterKeys records only the compact pair:

```text
implemnetation → implementation
```

Do not persist the surrounding sentence.

Test repeated observations and confirm:

- first occurrence: record only
- second occurrence: increase confidence
- configurable threshold reached: show suggestion
- user accepts: create learned automatic rule
- user undoes repeatedly: downgrade or disable

## Synthetic event filtering tests

Verify that:

1. ButterKeys sees a physical typo.
2. ButterKeys emits replacement events.
3. Replacement events are marked as synthetic.
4. Synthetic events do not re-enter correction evaluation.
5. No infinite correction loop occurs.

## Exclusion tests

Verify that correction is disabled in:

- Terminal
- Xcode
- VS Code
- password managers
- secure fields
- apps manually excluded by the user

Verify that switching back to Notes or Mail restores prose correction.

## Performance requirements

The keyboard event callback must remain extremely lightweight.

Targets:

- no perceivable typing lag
- event callback work below approximately 1 millisecond
- correction evaluation off the callback thread
- bounded in-memory buffers
- no database access inside the callback
- no synchronous disk access during keystroke handling
- no dictionary file parsing during typing

Use `os_signpost` or equivalent instrumentation in debug builds.

Track:

- event callback duration
- candidate-generation duration
- replacement duration
- event tap disable and recovery counts

Do not log user text in performance traces.

## Logging

Use structured local logging with `OSLog`.

Never log:

- full typed text
- rolling buffer contents
- passwords
- clipboard contents
- full sentences

Allow debug logging for:

- event tap state
- permission state
- strategy identifiers
- candidate confidence values
- correction rule IDs
- performance timings
- synthetic event filtering
- redacted token lengths

Provide an optional developer mode that displays redacted diagnostics.

Example:

```text
Candidate generated
strategy: adjacent_transposition
source_length: 4
replacement_length: 4
confidence: 0.94
```

## Accessibility and permission failure handling

Handle these states cleanly:

- Input Monitoring not granted
- Accessibility not granted
- one permission granted but not the other
- permission revoked while running
- event tap disabled by timeout
- secure keyboard entry enabled
- Accessibility element unavailable
- target app rejects synthetic input

The app should continue running without crashing.

When correction cannot be applied safely, leave the original text untouched.

## Visual direction

ButterKeys should feel like a charming native Mac utility.

Use:

- standard macOS typography
- system materials
- native spacing
- restrained animation
- SF Symbols where appropriate
- clear light and dark mode support

Avoid:

- web-dashboard layouts
- oversized cards
- excessive gradients
- cartoon-heavy UI
- skeuomorphic butter textures
- greasy or sticky imagery

## Icon direction

The app icon should combine:

- a rounded keyboard keycap
- a small pat of butter
- a subtle melting or smoothing detail
- a friendly macOS utility aesthetic

Possible concepts:

### Butter key

A rounded keycap with a small pat of butter melting over one corner.

### Sliding letters

Two letters moving smoothly into the correct order with a subtle butter-like trail.

### BK keycaps

Two overlapping keycaps containing `B` and `K`, joined by a small butter pat.

### Butter cursor

A text cursor or caret shaped subtly like a butter knife.

Avoid:

- photorealistic butter
- complex illustrations that disappear at small sizes
- low-contrast yellow on white
- overly childish mascot art
- tiny text inside the icon

## Colour direction

Suggested palette:

```text
Butter yellow
Warm cream
Toast brown
Soft charcoal
Muted cornflower blue
```

Use these mainly for branding and illustrations.

Keep standard controls native.

## Menu bar icon states

Create monochrome menu bar variants.

```text
Active: clean butter-key silhouette
Paused: small pause mark
Permission issue: small warning mark
Secure input: small lock
Disabled: hollow or dimmed key
```

The icon must remain legible at native menu bar sizes.

## Statistics

Possible statistics:

```text
Smoothed today
Smoothed this week
Most common slip
Corrections undone
New patterns learned
```

Example:

```text
Smoothed today: 37
Favourite slip: soem → some
New patterns learned: 2
```

Do not produce fake precision for time saved.

If time saved is included, label it clearly as an estimate.

## Import and export

Support JSON import and export for:

- explicit rules
- learned typo pairs
- custom words
- app policies

Do not include correction history unless the user explicitly selects it.

Export format should be versioned.

Example:

```json
{
  "formatVersion": 1,
  "rules": [
    {
      "source": "soem",
      "replacement": "some",
      "mode": "automatic",
      "scope": "global"
    }
  ]
}
```

Validate imported files and reject malformed data safely.

## Launch at login

Use `SMAppService`.

Provide a standard setting:

```text
Launch ButterKeys at login
```

Do not install background daemons unless technically necessary.

The app should remain a visible menu bar utility.

## Distribution

Prepare for:

- local development
- signed release builds
- Apple notarization
- direct distribution outside the Mac App Store
- `.dmg` packaging

Document:

- required permissions
- entitlements
- signing steps
- notarization steps
- Hardened Runtime configuration
- privacy implications
- known macOS limitations

Investigate Mac App Store sandbox restrictions, but optimize the initial product for direct distribution.

Do not assume Mac App Store distribution is feasible for the first release.

## Development phases

### Phase 1: Input prototype

Build:

- native menu bar application
- Input Monitoring permission detection
- Accessibility permission detection
- event tap
- active app detection
- rolling buffer
- synthetic event tagging
- pause and resume
- redacted debug diagnostics

Success criteria:

- keystrokes can be observed in Notes
- keystrokes are not persisted
- secure input pauses processing
- switching apps resets state safely
- no visible typing latency

### Phase 2: Explicit rules

Build:

- SQLite setup and migrations
- direct correction rules
- completed-word detection
- synthetic text replacement
- undo
- rule management UI
- exclusions

Success criteria:

```text
teh → the
soem → some
jsut → just
```

work reliably in Notes and Mail.

### Phase 3: Pattern engine

Build:

- adjacent transpositions
- nearby-key substitutions
- `gn` and `ng`
- short permutations
- extra characters
- missing characters
- duplicate characters
- confidence scoring

Success criteria:

```text
gove me → give me
buidl → build
writign → writing
typoes → typos
```

work with appropriate confidence.

### Phase 4: Boundary correction

Build:

- early-space strategy
- shifted-boundary strategy
- phrase frequency support
- multi-token replacement transactions

Success criteria:

```text
typin gthis → typing this
int he app → in the app
```

work in prose contexts without altering code.

### Phase 5: Learning

Build:

- manual correction detection
- compact typo-pair storage
- suggestion workflow
- motor-pattern aggregation
- confidence adaptation
- undo penalties

Success criteria:

- ButterKeys notices repeated corrections
- suggested rules can be accepted or rejected
- repeated undo lowers confidence
- no full sentence is stored

### Phase 6: Product polish

Build:

- onboarding
- full settings UI
- app modes
- history
- privacy tools
- Butter level
- launch at login
- app icon
- signing and notarization documentation

## Acceptance criteria

The MVP is complete when:

1. The user can install and launch ButterKeys.
2. The user can grant Input Monitoring and Accessibility permissions.
3. ButterKeys monitors typing in common prose apps.
4. Typing `teh ` produces `the `.
5. Typing `soem ` produces `some `.
6. Typing `jsut ` produces `just `.
7. Typing `gove me` can produce `give me`.
8. Typing `buidl ` can produce `build `.
9. Typing `writign ` produces `writing `.
10. Typing `typoes ` can produce `typos `.
11. Typing `int he app` can produce `in the app`.
12. Typing `typin gthis` can produce `typing this`.
13. Legitimate words such as `gnome`, `signature`, and `magnet` remain unchanged.
14. Valid words such as `love`, `move`, and `gave` are not incorrectly changed.
15. Code editors and terminals are excluded by default.
16. Secure text fields are never processed.
17. Every automatic correction can be undone.
18. Repeated undo reduces correction confidence.
19. The user can create, edit, disable, and delete rules.
20. The user can add custom dictionary words.
21. ButterKeys works without internet access.
22. No raw keystroke logs are persisted.
23. No complete sentences are persisted.
24. The rolling text buffer remains memory-only.
25. Synthetic replacement events do not create loops.
26. Typing has no perceptible latency.
27. The menu bar clearly shows active, paused, secure, and permission states.
28. The product is named ButterKeys throughout.
29. Butter-themed copy is restrained and configurable.
30. Privacy and security copy remains direct.
31. The project builds cleanly in Xcode.
32. Unit and integration tests pass.
33. The README explains setup, architecture, permissions, privacy, and limitations.
34. Signing and notarization steps are documented.
35. The app fails safely by leaving original text untouched when uncertain.

## Known technical risks to investigate

Document and test these early:

- reliability of global event taps across macOS versions
- Accessibility permission behaviour
- secure keyboard entry detection
- custom text controls in Electron apps
- synthetic Unicode insertion behaviour
- cursor and selection changes
- IME and composed-text compatibility
- clipboard fallback reliability
- host-app undo interactions
- event tap timeout recovery
- active keyboard layout changes
- password-field detection
- sandbox and distribution constraints

Do not hide limitations.

Create a `KNOWN_LIMITATIONS.md` file and keep it updated.

## README requirements

The README should include:

- project overview
- screenshots or placeholders
- architecture
- setup instructions
- dependency installation
- Xcode build steps
- permission setup
- privacy model
- correction engine overview
- data storage overview
- test instructions
- release build instructions
- signing instructions
- notarization instructions
- known limitations
- roadmap
- bundled dataset attribution
- contribution guidelines

## Deliverables

Produce:

- complete Xcode project
- all Swift source files
- SQLite migrations
- bundled default rules
- dictionary integration
- phrase-frequency integration or a clean placeholder interface
- unit tests
- integration tests
- onboarding flow
- menu bar UI
- settings UI
- icon placeholders
- README
- privacy documentation
- entitlements documentation
- signing and notarization notes
- `KNOWN_LIMITATIONS.md`
- phased roadmap

## Implementation order

Start with a working vertical slice.

The first usable slice should:

1. launch as a menu bar app
2. verify permissions
3. observe typing in Notes
4. detect a completed token
5. correct `teh` to `the`
6. undo the correction
7. avoid processing synthetic events
8. disable itself in Terminal
9. store no complete sentence
10. expose a small redacted diagnostics panel

After that slice works reliably, add the pattern strategies one at a time.

Do not build the entire settings UI before proving that global monitoring, safe replacement, undo, and exclusion handling work.

## Final product principle

ButterKeys should never feel like an aggressive autocorrect system.

It should behave like a quiet personal typing layer that learns how this specific user’s fingers slip and gently smooths those mistakes away.

The guiding principle is:

```text
When confident, smooth it.
When uncertain, leave it alone.
```

This one is complete and ends at the actual final principle rather than an ominous dangling “For”.
