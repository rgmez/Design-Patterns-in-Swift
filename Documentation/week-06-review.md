# State and Command Review

Review date: 2026-09-19

This review closes Internal Day 042. It validates the State and Command cycles
together, confirms their mutation and ownership boundaries, and records why a
lifecycle state and a reversible user operation solve different app problems.

## Review scope

- Build and test the complete Swift Package with compiler warnings as errors.
- Re-run the State and Command problem, pressure, and canonical suites.
- Verify invalid-transition and rejected-command atomicity.
- Inspect undo, redo, persistence, and validation ownership.
- Compare complete timeline snapshots with focused reversal records without
  presenting structural counts as byte measurements.
- Recheck canonical README sections, commands, local links, Mermaid blocks,
  accessible descriptions, captions, and editorial headers.
- Run SwiftLint in strict mode and confirm `Editorial/` remains ignored and
  outside the Git index.

## Behavioral boundary matrix

| Question | State | Command |
| --- | --- | --- |
| What varies? | Legal transitions, screen action, and worker operation for the current backup phase | One requested timeline edit and the focused data needed to reverse it |
| Who initiates change? | An event is offered to the current lifecycle state | Toolbar, keyboard, or replay submits a portable command value |
| What owns mutation order? | `BackupUpload` installs a returned state only after successful handling | `TimelineCommandEditor` commits a candidate timeline and moves entries between bounded undo and redo stacks |
| What is persisted? | One validated `BackupUploadPhase` snapshot | Portable `TimelineCommand` intent; local reversal state is deliberately not codable |
| What must remain unchanged after rejection? | Phase, screen action, and worker operation | Timeline, undo depth, redo depth, and any existing redo branch |
| Simpler default | Enum plus pure reducer or computed properties | Direct method, one previous value, or bounded whole-value snapshots |

## State review

State remains justified by three behavior families that change together per
phase: accepted events, the primary screen action, and the background worker
operation. Seven private state implementations keep those decisions beside the
phase that owns them. The public `BackupUpload` context remains a value type,
and the state protocol remains private; callers cannot inject arbitrary phases
or depend on concrete state objects.

Invalid events are explicit errors. `handle(_:)` obtains a complete next state
before assigning it, so a rejected event cannot partially change the context.
Uploading also rejects regressed progress, incomplete completion, and a blank
remote identifier before transition. Persistence encodes the typed public
phase and validates its associated data while restoring the matching private
state. The restoration switch is a serialization boundary, not a second owner
of ongoing lifecycle behavior.

The six-boolean pressure model still provides useful executable evidence: it
admits 64 combinations for seven meaningful lifecycle shapes, leaving 57
invalid combinations. It does not leak into the canonical implementation.

No transition table, public state hierarchy, side-effect handler layer, or
workflow framework is justified. The direct enum reducer remains the preferred
design whenever transitions are the only behavior that varies.

## Command review

Command remains justified by two measured pressures that the direct editor
cannot solve together. Three input surfaces repeat four edit cases and 12
dispatch branches. A four-entry snapshot history for a 1,000-clip timeline
retains 4,000 clip entries.

The canonical `TimelineCommand` replaces those input-specific vocabularies with
one closed, codable enum. Execution still delegates clip identity, source
range, position, and split validation to `VideoTimeline`. The command reads
only the accepted edit's prior fields and returns a private reversal record.
`TimelineCommandEditor` is the sole owner of history order, eviction, redo
invalidation, and the current timeline.

Candidate mutation protects both execution and reversal. A rejected command
cannot change the timeline or either stack, and a no-op command does not clear
an existing redo branch. Undo applies a focused inverse before moving the entry
to redo. Redo executes the original portable intent again and captures a fresh
inverse for the current timeline.

The retained-state comparison is intentionally structural. Four bounded
snapshots contain 4,000 clip entries; the canonical history contains four
reversal records. Move, trim, and caption retain primitive prior fields, while
split retains one original clip. Swift copy-on-write, string storage, and enum
layout mean this is not a byte or heap-allocation benchmark. It is sufficient
evidence that canonical history grows with accepted edit count rather than
`timeline size × undo depth`.

No command protocol, class per edit, generic bus, middleware chain, macro,
runtime registry, or remote conflict-resolution model is justified. Whole
snapshots remain the safer alternative when the document is small or a focused
inverse would be harder to trust.

## State and Command are not interchangeable

State answers: **what behavior is valid now because previous events moved the
lifecycle here?** The caller does not choose Uploading or Failed as an
interchangeable policy.

Command answers: **what operation should be executed, queued, replayed, or
reversed?** The input surface deliberately chooses a trim, move, caption, or
split value. Undo and redo are history operations owned by the editor, not
concrete State implementations for the timeline.

Using Command for backup events would add replayable operation values without
removing phase-owned behavior. Using State for the four timeline edits would
misclassify caller-selected intent as an internal lifecycle. The examples
therefore share candidate mutation and explicit errors but not pattern intent.

## Documentation and visual review

- The root status lists ten completed pattern cycles and now links every weekly
  review through Day 042.
- Both canonical guides contain the required app problem, direct solution,
  turning point, intent, participants, implementation, diagram, execution,
  tests, trade-offs, alternatives, `When not to use it`, and source map.
- State uses a Mermaid state diagram with domain phases and legal transitions.
  Command uses a Mermaid sequence showing input, editor, portable intent,
  timeline validation, focused undo, and redo. Each has an equivalent
  accessible description.
- Both headers are 1672 × 941 and retain the approved upper-left hierarchy,
  upper-right original RG logo, matte charcoal background, closed warm palette,
  and one behavioral metaphor. State shows a gated legal lifecycle; Command
  shows focused edit capsules moving through a bounded reversible history.

## Complexity decision

The review found no production-code change to make. State already keeps phase
behavior private and typed without replacing the public value model. Command
already keeps portable intent separate from local reversal state without a
protocol hierarchy. Their direct baselines and pressure implementations remain
executable evidence, so the canonical implementations do not need additional
comparison APIs or speculative infrastructure.

## Verification

Run from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors --filter 'StateProblemTests|StatePressureTests|StateTests'
swift test -Xswiftc -warnings-as-errors --filter 'CommandProblemTests|CommandPressureTests|CommandTests'
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict --no-cache Sources Tests
git diff --check
git check-ignore -v Editorial/
```

Results:

- The full build completed with compiler warnings treated as errors.
- State: 21 tests across 10 problem, pressure, and canonical suites.
- Command: 23 tests across 11 problem, pressure, and canonical suites.
- The complete Swift Testing run passed 112 tests across 61 suites.
- SwiftLint strict mode reported 0 violations across 46 files.
- All concrete local Markdown links resolve; the template's intentional
  placeholders are excluded from that check.
- Each canonical README contains exactly one structurally valid Mermaid block
  with real domain names and an accessible description.
- Both headers pass the five-part visual comparison and have the required
  1672 × 941 dimensions.
- `git diff --check` passes, and `Editorial/` remains ignored.

## Readiness decision

State and Command are complete, correctly classified, and explicit about
invalid mutation, retained state, and simpler alternatives. The repository is
ready for Internal Day 043: define the direct checkout orchestration problem
that may later justify Facade. This review does not design that checkout or
start the next pattern.

Internal Day 042 is not a publication milestone. No LinkedIn draft is created,
renamed, or updated by this review.
