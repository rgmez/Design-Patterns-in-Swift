# Memento and Iterator Review

Review date: 2026-10-08

This review closes Internal Day 063 by checking snapshot ownership, atomic
restoration, asynchronous termination, error propagation, cancellation, and the
simpler Swift alternatives.

## Responsibility matrix

| Question | Memento | Iterator |
| --- | --- | --- |
| What changes? | A scene-owned history outlives an itinerary editor without learning its private schema | Three consumers stop repeating cursor advancement, buffering, and termination |
| Public boundary | An opaque restore point created and interpreted by the editor | Swift's native `AsyncSequence` and one concrete asynchronous iterator |
| State owner | The editor owns capture and restoration; history owns only retention order | Each iterator owns its cursor, page buffer, and terminal flag |
| Failure rule | Decode and validate before replacing state or consuming history | Propagate the source error before changing cursor or terminal state |
| Simpler default | Value assignment or a private bounded array for one editor lifetime | An array for loaded data or one screen-owned cursor for one-page actions |

## Memento findings

`ItineraryDraftEditor.makeMemento()` serializes one complete private
`SnapshotV1` before handing the sealed value to `ItineraryDraftHistory`. The
history can bound, order, measure, and return restore points, but its source does
not name the snapshot schema or any draft field.

The new ownership regression saves a checkpoint, mutates every kind of editor
state, and then restores the captured preview. It proves that history retained
the state at capture time rather than an alias to the editor's later state. The
existing recreation, LIFO eviction, byte-growth, unsupported-version, and
malformed-payload cases continue to prove bounded ownership and atomic failure.

The design still does not promise durable persistence. Exposing memento bytes,
adding a repository, or building a migration registry would introduce storage
and compatibility policy that the current same-runtime history does not need.
For one editor lifetime, the direct private value stack remains smaller.

## Iterator findings

`PhotoLibrarySequence.AsyncIterator.next()` checks cancellation before examining
its buffer or starting remote work. It fetches only when the current page is
exhausted, commits page state only after a successful post-fetch cancellation
check, continues through empty nonterminal pages, and returns repeated `nil`
without another request after the terminal cursor.

The new cancellation regression fetches one page containing two photos,
delivers the first, cancels the consumer task, and asks for the second. The
buffered photo is not delivered and the next cursor is never requested. Together
with the existing same-cursor retry test, this confirms that neither a typed
source error nor cooperative cancellation silently advances traversal state.

The iterator remains pull-driven and sequential. An `AsyncThrowingStream`,
producer task, actor, prefetch queue, or generic paginator would create lifetime,
buffering, and shared-state decisions absent from the product requirements.
Retry, accumulation, and early exit remain consumer policy.

## Classification and ownership

Both patterns preserve state across time, but they solve opposite ownership
problems. Memento captures a complete state value so a caretaker can return it
later without understanding it. Iterator keeps mutable traversal state alive
inside one consumer-owned cursor and reveals elements incrementally without
capturing the complete source.

Memento is not Command: it records what state existed, not what operation to
replay. Iterator is not Observer: one consumer explicitly pulls the next value;
there is no shared broadcast source or subscription lifetime. These boundaries
keep recovery, retry, and cancellation policy with the owners that can make the
corresponding product decisions.

## Documentation and visual review

Both canonical guides retain the app problem, direct baseline, measured
pressure, participants, Swift walkthrough, execution commands, tests,
trade-offs, alternatives, and explicit `When not to use it` guidance. Their
local source and test links resolve, and each Mermaid sequence uses real domain
names with an explanatory paragraph and accessible equivalent.

The existing 1672 × 941 headers were compared with the approved Adapter
reference. Both preserve the upper-left hierarchy, upper-right original RG
mark, charcoal/red/orange palette, subtle grid, and detailed lower-band scene.
Memento uses a bounded snapshot magazine and return path; Iterator uses one
continuous film transport across page boundaries. They remain coherent with
the collection, so regeneration would add risk without improving the system.

## Validation

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict --no-cache Sources Tests
git diff --check
git check-ignore -v Editorial/
```

- The canonical solution suites pass 12 tests in 4 suites, including the new
  ownership and buffered-cancellation regressions. The complete Memento and
  Iterator review passes 30 tests in 16 suites.
- The full build succeeds and the warning-as-error suite passes 222 tests in
  120 suites.
- SwiftLint strict mode reports zero violations across 83 Swift files.
- Concrete local Markdown links resolve; deliberate placeholders in the README
  template, external URLs, and heading anchors are outside this check.
- Mermaid delimiters, diagram type, and domain identifiers were checked against
  the implementations. Mermaid CLI is unavailable, so no parser validation is
  claimed.
- Both editorial headers have the required 1672 × 941 dimensions and pass the
  five-part visual comparison.
- CodeGraph is not initialized. The review used the already scoped source,
  tests, and canonical guides; no index was created during this review.
- `Editorial/` remains ignored and outside the commit.

## Readiness decision

Day 063 is complete with focused regression coverage and no production
abstraction changes. Memento keeps capture and compatibility with the editor;
Iterator keeps cursor, buffer, termination, and cancellation with each
traversal. Neither durable history nor an asynchronous producer has earned a
place.

Day 064 will define the direct Composite problem. It has not started. Day 063
is not a publication milestone, so no LinkedIn draft is created or changed.
