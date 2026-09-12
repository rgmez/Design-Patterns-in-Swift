# Prototype and Observer Review

Review date: 2026-09-12

This review closes Internal Day 035. It validates the two Week 5 examples
together, repairs the lifecycle gaps found after Observer's first solution, and
records why graph-copy ownership and subscription ownership require different
boundaries.

## Review scope

- Re-run the complete package with compiler warnings treated as errors.
- Validate Prototype's fresh identities, subtype-owned copying, link remapping,
  and deliberate immutable-resource sharing.
- Validate Observer's initial snapshot, transition ordering, bounded buffering,
  independent cancellation, and continuation cleanup.
- Review every canonical README section, command, local link, Mermaid block,
  accessible description, caption, and editorial header.
- Confirm that `Editorial/` remains ignored and outside the Git index.

## Ownership boundary matrix

| Question | Prototype | Observer |
| --- | --- | --- |
| What varies? | Runtime block type and its local copy policy | Receiver set and subscription lifetime |
| What owns shared coordination? | The document allocates the complete old-to-new ID map | One actor orders session state and subscriptions |
| What remains local? | Each block copies its subtype state and sharing policy | Each receiver owns iteration and cancellation |
| What must never happen? | A copied link targets the source graph or mutable blocks remain shared | A transition falls between reading current state and registering the stream |
| Simpler default | Swift value assignment or one direct copy switch | Direct calls, one closure, or Swift Observation |

## Prototype review

Prototype remains correctly scoped to the reference-backed document graph.
Ordinary value assignment is still the documented default for configurations
made from structs, enums, and copy-on-write collections.

The canonical graph copier performs only graph-wide work: it rejects duplicate
source IDs, allocates every copied ID before subtype dispatch, and passes one
complete `EditableDocumentCopyContext` to each block. Concrete block types own
their mutable state, link remapping, or immutable-resource sharing policy. The
extension test continues to add a quote block without editing
`duplicateEditableDocument(_:)`, which is the measured benefit that justifies
Prototype here.

No registry, factory, base class, generic cloning framework, or blind deep-copy
rule was added during this review.

## Observer correction

The first Observer solution separated session state and continuation storage
across two actors. That version delivered future transitions but did not give a
late subscriber the already confirmed session required by the Day 033 screen
scenario. Reading `currentSession` and subscribing in two calls would also leave
a transition-sized race between those operations.

`ObservedSessionController` now owns both values inside one actor. Its
`sessionStream()` method has no suspension point: it registers the continuation
and enqueues the current session before the actor can accept another operation.
`transition(to:)` stores a different session and yields it from the same
isolation domain. This removes the second actor and closes the race without a
lock, replay framework, custom observer protocol, or `@unchecked Sendable`.

Each stream keeps only the newest pending snapshot. Cancelling one consumer
terminates that stream without affecting another active receiver. Termination
removes its continuation asynchronously, while the next publication also
prunes terminated entries defensively. The internal subscription count exists
only as a package test seam and is not part of the public API.

## Documentation and visual review

- Observer's canonical guide now lives under `Behavioral Patterns/Observer`,
  matching its GoF category and the behavioral asset directory.
- The root status names all eight completed pattern cycles and links every
  weekly review through Day 035.
- Both canonical guides contain the required problem, direct solution, turning
  point, intent, participants, implementation, Mermaid, execution, tests,
  trade-offs, alternatives, `When not to use it`, and source map sections.
- Both Mermaid diagrams use real domain and Swift names and have equivalent
  accessible descriptions.
- Prototype and Observer headers retain the approved 1672 × 941 dimensions,
  closed palette, typographic hierarchy, original RG logo, alt text, and
  one-sentence caption.

## Process note

Observer's final cycle is represented by separate implementation,
buffering-correction, and visual-completion commits, and the Day 033 commit does
not use the optional `Part 2 of 3` suffix. Those are historical process
irregularities, not reasons to rewrite published branch history. This review
records them and keeps the corrective work in one new Day 035 commit.

## Verification

Run from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors --filter Prototype
swift test -Xswiftc -warnings-as-errors --filter ObserverTests
swift test -Xswiftc -warnings-as-errors
```

Results:

- Prototype: 11 tests across its problem, pressure, and canonical suites.
- Observer solution: 5 focused tests, including current-state replay and
  independent cancellation with continuation-count cleanup.
- The Observer suite passed 20 consecutive executions without sleeps or
  serialized test execution.
- Complete package: 68 tests with compiler warnings treated as errors.
- SwiftLint 0.63.2 strict mode reports no violations in either changed Swift
  file.
- No broken local Markdown links, whitespace errors, untracked review debris,
  or tracked `Editorial/` files.

## Readiness decision

Prototype and Observer are complete, correctly classified, and explicit about
their ownership costs. The repository is ready for Internal Day 036: define a
direct upload or checkout lifecycle and the invalid transitions that may later
justify State. This review does not begin that example.

Internal Day 035 is not a publication milestone. No LinkedIn draft is created,
renamed, or updated by this review.
