# Prototype Problem: Duplicating an Editable Document

Problem-definition date: 2026-09-06

This document defines Day 029 of the Prototype cycle. It begins with Swift's
ordinary value-copy semantics, records the real document-duplication boundary,
and fixes acceptance criteria before an explicit cloning API is considered.

## Product scenario

A collaborative writing app lets an editor duplicate a reusable document and
adapt the copy for a new release. Today the reusable input is a configuration:
a title, text style, and ordered section values. The copied configuration must
start with the same content, then evolve without changing its source.

The next product step turns that flat configuration into an editable document
graph. Blocks retain identity while the editor observes them, internal links
point to other blocks, and different block kinds carry different mutable state.
Large media payloads remain immutable resources that copies should share rather
than duplicate.

Network collaboration, persistence, conflict resolution, layout, and media
upload are outside this teaching unit. They do not help decide where copying
changes from a language feature into a domain operation.

## Requirements and invariants

The direct implementation in
[`DocumentConfiguration.swift`](../Sources/DesignPatterns/Prototype/DocumentConfiguration.swift)
must:

1. Represent the current title, text style, and ordered sections entirely with
   value types.
2. Let ordinary assignment produce an initially equivalent configuration.
3. Keep top-level edits to the copy independent from the source.
4. Keep nested style edits independent from the source.
5. Keep edits to arrays and their section values independent while preserving
   section order and identifiers.
6. Remain `Equatable` and `Sendable` without a cloning protocol or `clone()`
   method.

The future editable graph adds stricter duplication semantics:

1. Every mutable block in the duplicate receives fresh identity.
2. Editing any copied block cannot mutate the corresponding source block.
3. Runtime block kind and kind-specific state are preserved.
4. Internal links are remapped to copied block identities, never left pointing
   into the source graph.
5. Immutable media resources remain shared deliberately.

These graph rules define controlled deep copying: neither blindly sharing every
reference nor recursively copying every object is correct.

## Direct Swift first

For the current value-only configuration, assignment is the complete copy
operation:

```swift
var releaseNotes = weeklyUpdate
releaseNotes.title = "Release retrospective"
releaseNotes.sections[0].heading = "What shipped"
```

Swift copies the enclosing structures as values. Its standard collections use
copy-on-write internally, so changing the copied section array does not change
the source array. No client-visible Prototype abstraction is needed to obtain
the required independence.

Adding `NSCopying`, a `Cloning` protocol, a `clone()` method, or a class hierarchy
here would merely rename assignment and make a language guarantee look like a
domain-specific capability.

## Acceptance tests

[`PrototypeProblemTests.swift`](../Tests/DesignPatternsTests/PrototypeProblemTests.swift)
uses Swift Testing to verify that an ordinary value copy:

- starts equivalent to its source;
- can change its title without changing the source title;
- can change nested style values without changing the source style;
- can append and edit nested section content without changing the source array.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter PrototypeProblemTests
```

The graph acceptance rules above remain product requirements, not simulated
passing tests. Day 030 must introduce the smallest credible reference-backed
graph needed to expose ordinary assignment's sharing and subtype-preservation
failures.

## Evidence required on Day 030

Prototype has not earned a place because users can duplicate a document. Day
030 must measure the failure at the reference boundary and distinguish three
operations that are easy to conflate:

- assigning a reference and sharing every mutable node;
- recursively copying nodes while accidentally erasing subtype-specific state
  or retaining links into the source graph;
- controlled duplication that copies editable identity while sharing immutable
  media by policy.

If replacing reference-backed blocks with value types keeps editor identity,
observation, and internal links clear, the explicit pattern should still be
rejected.

The completed [Day 030 pressure review](prototype-pressure.md) now demonstrates
that assignment shares the mutable block objects and that a correct direct copy
needs four centralized subtype branches. It also verifies internal-link
remapping and deliberate immutable-media sharing without introducing a cloning
protocol.

## Initial visual thesis

**Thesis:** Value configurations split cleanly by assignment; an identity-rich
document graph needs a controlled copy boundary.

**Scene:** A dark document rail enters from the left as one compact stack of
value cards and splits into two independent stacks without a machine between
them. Farther right, a connected graph of distinct text, checklist, link, and
media modules reaches a precision duplication gate. Editable nodes exit with
new warm-red identity marks, internal links stay inside the copied graph, and
one heavy immutable media cartridge remains connected to both sides.

Day 031 may turn this scene into the final Prototype header under the shared
[`visual-style.md`](visual-style.md) contract. Until then, no editorial header
is needed.

## Day 029 decision

The current configuration needs independent copies, but Swift value semantics
already provide them. The implementation deliberately stops at three small
value types. Prototype remains absent until the editable graph proves a real
need to preserve runtime kinds, remap internal identity, and share selected
immutable resources.
