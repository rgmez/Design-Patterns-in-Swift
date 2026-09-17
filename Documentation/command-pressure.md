# Command Pressure: History Without Reusable Intent

Pressure-review date: 2026-09-17

Internal Day 040 adds multi-step undo and redo, keyboard invocation, and
offline replay to the video timeline from Day 039. The implementation remains
direct: complete timeline values provide history, and each input surface
translates its own edit representation into editor method calls. There is no
command protocol, type erasure, stored execution closure, invoker, or general
operation queue.

## The requirements that changed

One previous timeline is no longer enough. A creator must be able to:

- undo and redo several accepted edits in order;
- start the same trim, move, caption, or split from the toolbar or a keyboard
  shortcut;
- serialize accepted edit intent while collaboration is offline and replay it
  later;
- discard the redo branch when a new edit follows an undo;
- keep history bounded rather than retaining the whole editing session.

The media model and its validation rules do not change. Rejected edits still
leave the timeline and history untouched.

## Direct snapshot history retained

[`DirectTimelineHistoryEditor`](../Sources/DesignPatterns/Command/VideoTimelinePressure.swift)
stores bounded arrays of complete `VideoTimeline` values. Every successful edit
pushes the previous timeline onto the undo stack and clears redo. Undo and redo
move whole values between the two stacks.

This is still a strong default in Swift. Value semantics make restoration
atomic, and the history does not need to know how trim differs from split. The
implementation also keeps the simpler Day 039 `DirectTimelineEditor` intact for
the one-step requirement.

The retained-state cost is now observable. After five edits to a 1,000-clip
timeline, a four-entry history limit retains 4,000 clip entries and evicts the
oldest snapshot. This is a structural count, not a byte estimate: strings and
other storage may share backing memory, while mutating an array value can still
trigger copy-on-write allocation. The count is enough to show that history
grows with `timeline size × undo depth`, not with the state actually changed by
each edit.

## Reuse duplicates the edit vocabulary

The direct input router uses three deliberately separate values:

- `TimelineToolbarEdit` for toolbar actions;
- `TimelineKeyboardEdit` for shortcuts;
- `QueuedTimelineEdit` for codable offline records.

Each value repeats the same four cases and each route repeats the same four-way
dispatch into the editor. The result is 12 branches for four operations across
three entry paths. Adding a fifth operation requires a new case and a new
dispatch branch in every path even when execution and reversal rules are
identical.

`QueuedTimelineEdit` serializes only portable intent and arguments. Timeline
snapshots remain local and are not uploaded as collaboration records. That
boundary is useful, but the queued value cannot execute or reverse itself; the
router still owns a third copy of the edit switch.

## Executable evidence

[`CommandPressureTests.swift`](../Tests/DesignPatternsTests/CommandPressureTests.swift)
uses Swift Testing to verify:

- three complete snapshots undo and redo in the correct order;
- a new edit after undo invalidates the redo branch;
- five edits respect a four-entry limit while retaining 4,000 clip entries;
- a rejected edit leaves the timeline, undo depth, and redo depth untouched;
- toolbar, keyboard, and replay routes produce the same four-edit result;
- queued intent survives a `Codable` round trip without serializing local
  history.

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter CommandPressureTests
```

## Smaller alternatives still in contention

A bounded value history remains the better design when timelines are small,
undo depth is shallow, and collaboration sends final state rather than edit
intent. It gives atomic restoration with fewer concepts than Command.

A single enum shared by every input path could remove the three route-specific
representations. Once that value also owns execution and the focused state
needed for reversal, however, it is the minimal Swift form of Command rather
than merely a routing enum. Day 041 must judge that concrete design, not add a
protocol hierarchy by default.

`UndoManager` can integrate with Apple UI undo conventions, but closure-based
registrations are not a portable offline replay format. A closure array has the
same limitation and makes equality, serialization, and diagnostics harder.
Persisting every timeline snapshot would replay state rather than user intent
and would multiply storage and compatibility costs.

## Boundary carried into Day 041

Command may replace the direct pressure implementation only if the result:

- gives toolbar, keyboard, and replay one edit representation;
- stores only the focused prior state each edit needs to reverse itself;
- preserves bounded undo and redo ordering, including redo invalidation;
- serializes portable intent without serializing local reversal state;
- keeps timeline validation in the timeline rather than duplicating it in
  command types;
- avoids a command class per trivial setter, a generic bus, middleware,
  macros, runtime registration, or speculative collaboration machinery.

## Day 040 decision

Complete value snapshots remain correct, but the new scale and replay
requirements expose two repeatable costs: retained history grows with the full
timeline, and edit vocabulary is copied across every invoker. Command is now a
credible candidate because executable, reversible intent could reduce both
costs. Day 041 must still prove that a focused value representation is clearer
than keeping the snapshot stacks and duplicated switches.
