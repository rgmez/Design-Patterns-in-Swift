# Observer Pressure: A Session Screen Outlives the Direct Fan-Out

Pressure-definition date: 2026-09-10

Day 033 adds a realistic fifth consumer: a session screen whose lifetime is
shorter than the authenticated session. The direct implementation remains
executable, but the new requirement makes its ownership problem visible.

## The new consumer

`SessionScreenModel` represents a screen that appears and disappears while the
session controller continues to live. It needs the current session when it is
visible, but it must not remain a permanent collaborator of the session owner.

The direct solution adds an optional `sessionScreen` property and another call
inside both branches of `SessionController.transition(to:)`. This is locally
small, but every new lifecycle-sensitive consumer now requires editing the
source of truth and deciding how its registration and removal should work.

## Observable pressure

The pressure tests in
[`ObserverPressureTests.swift`](../Tests/DesignPatternsTests/ObserverPressureTests.swift)
prove that:

- the screen receives a confirmed session transition;
- disappearing changes the screen's local state, but does not unregister it
  from the controller;
- the controller still knows the screen's concrete type and calls it directly.

The example intentionally does not pretend that a no-op after disappearance is
subscription management. The source still owns the callback and the screen
cannot cancel delivery at the boundary.

## Questions that now matter

- Can the screen stop receiving changes without changing `SessionController`?
- Can two screens subscribe and cancel independently?
- Does one slow consumer delay the others?
- Are duplicate session snapshots filtered once, at the source?

For this pressure, a standard `AsyncStream` is sufficient. A custom event bus,
notification name registry, or protocol hierarchy would add machinery that the
example has not earned.

## Day 033 decision

The direct four-call fan-out was correct while every consumer shared the
controller's lifetime. A shorter-lived screen creates a real registration and
cancellation boundary, so Observer is now justified for the variable consumer
set. Day 034 will use an actor-isolated `AsyncStream` broadcaster and preserve
the source's duplicate filtering.
