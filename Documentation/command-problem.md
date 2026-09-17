# Command Problem: Reversible Video Timeline Edits

Problem-definition date: 2026-09-16

This document defines Internal Day 039. It fixes the editor operations, the
direct Swift baseline, acceptance evidence, and the initial visual thesis before
the Command pattern is considered.

## Product scenario

A mobile video editor lets a creator trim recorded footage, move it on the
timeline, split one clip into two, and attach a caption. These edits can arrive
from toolbar buttons today; the product roadmap also requires multi-step undo
and redo, keyboard shortcuts, and optional offline replay to a collaborative
editing service.

The example operates on frame indexes so its results are exact and deterministic.
Media decoding, playback, rendering, file storage, collaboration transport, UI,
and conflict resolution are outside this teaching unit. The behavior under
review is how an accepted edit changes the timeline and what information remains
available to reverse or replay it.

## Operations and invariants

| Edit | Required input | Observable result |
| --- | --- | --- |
| Trim | Clip, source start, duration | The clip references the requested valid source range. |
| Move | Clip, timeline start | The source range stays unchanged at a new non-negative position. |
| Caption | Clip, optional text | The clip owns the latest caption value. |
| Split | Clip, interior source frame, new ID | Two contiguous clips cover the original source and timeline ranges. |

The direct implementation must preserve these invariants:

1. Clip identifiers remain unique within a timeline.
2. A source range has positive duration and stays inside its media asset.
3. A timeline start cannot be negative.
4. A split occurs strictly inside the clip and creates no gap or overlap.
5. A rejected edit leaves both the timeline and undo availability unchanged.
6. One successful edit retains exactly one complete previous timeline snapshot.

## Direct Swift first

[`VideoTimelineDirect.swift`](../Sources/DesignPatterns/Command/VideoTimelineDirect.swift)
uses `TimelineClip` and `VideoTimeline` values plus a concrete
`DirectTimelineEditor`. Each toolbar action calls a focused editor method. The
editor applies the mutation to a candidate value and commits it only after
validation succeeds.

One optional `previousTimeline` snapshot provides one-step undo. This is
deliberately not Command: there is no command protocol, type erasure, stored
closure, invoker, operation queue, or separate object for each edit. Swift value
semantics make the complete snapshot easy to understand and protect rejected
edits from partial mutation.

For one-level undo, this is the better design. The snapshot does not need to know
how trim differs from split, and each UI action remains an ordinary method call.
The cost is equally explicit: a second successful edit replaces the first
snapshot, undo consumes that snapshot, and no redo or replayable intent exists.

## Acceptance tests

[`CommandProblemTests.swift`](../Tests/DesignPatternsTests/CommandProblemTests.swift)
uses Swift Testing to verify:

- trim, move, caption, and split outcomes independently;
- split continuity across source and timeline ranges;
- restoration of the complete value before the latest edit;
- the intentional one-level limit after consecutive edits;
- rejection of duplicate IDs and invalid source or timeline boundaries;
- atomic rejection of a missing clip and an invalid split boundary.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter CommandProblemTests
```

## Evidence required on Day 040

Command has not earned an abstraction merely because an editor has actions.
Day 040 must add a credible requirement for a sequence of edits that can be
undone and redone, invoked without a toolbar, or queued while collaboration is
offline. The pressure review must make the missing intent observable:

- What state does each edit need to reverse itself without snapshotting the
  entire timeline?
- Can toolbar, keyboard, and replay paths use one operation definition without
  duplicating their switches and arguments?
- What must be serialized for offline replay, and what must stay local?
- Does a bounded value-state history remain safer and simpler than operation
  objects for this timeline size?

If snapshots provide the required history with acceptable memory and there is
no need to replay intent, the direct design should stay. Day 041 may introduce
Command only if edit-owned execution and reversal reduce the demonstrated
branching or retained-state cost.

The implemented evidence is recorded in the
[Command pressure review](command-pressure.md). It keeps the Day 039 editor
unchanged, then adds a separate bounded snapshot history and three direct input
routes so their retention and duplication costs remain explicit.

## Initial visual thesis

**Thesis:** A timeline edit is easy to apply directly; reusable history requires
the intent and the exact reversal state to travel together.

**Scene:** A dark precision editing rail runs left to right beneath one bright
warm-red playhead. Four mechanical edit tools cut, slide, divide, and label a
strip of footage. Behind the latest edit sits one complete charcoal film-strip
snapshot in a single rollback cradle; older cradles are visibly absent. The
limited history is understandable without labels and foreshadows why replayable
edit capsules may later be justified.

The final Day 041 header should keep this edit-capsule and timeline metaphor if
the measured pressure justifies Command. Its Mermaid should explain execution,
undo, redo, and queue ownership precisely rather than repeat the illustration.

## Day 039 decision

The editor problem is real and executable, but Command has not earned its types.
Focused methods and one previous value remain the smallest correct design while
the product requires only one-step undo from one toolbar path.
