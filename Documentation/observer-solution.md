# Observer Solution: AsyncStream with Independent Lifetimes

Solution-definition date: 2026-09-11

Day 034 introduced the smallest subscription boundary justified by the pressure
review. Day 035 closes the initial-snapshot gap by keeping the current session
and Swift's `AsyncStream` continuation registry inside one actor.

## Implementation

[`SessionObservation.swift`](../Sources/DesignPatterns/Observer/SessionObservation.swift)
contains one `ObservedSessionController` actor. It owns the source-of-truth
session, registers one continuation per subscriber, enqueues the current value
when each stream is created, filters equal snapshots, and publishes only actual
transitions.

The subscription method has no suspension point. Registration and initial
delivery therefore finish in the same actor-isolated operation, so a confirmed
transition cannot fall into a read-then-subscribe gap. A second actor or custom
observer protocol would add indirection without improving that guarantee.

## Visual completion

The final [Observer editorial header](Assets/Patterns/behavioral/observer-header.png)
keeps the signal-distribution metaphor established on Day 032. One industrial
source feeds three active receivers through an explicit manifold, while a
fourth receiver disconnects at its own boundary without interrupting the
others. The composed image preserves the approved 16:9 layout, closed charcoal
and warm-red palette, upper-left hierarchy, original RG logo, and restrained
technical detail.

## Semantics made explicit

- A subscription is registered and receives the current snapshot before the
  controller actor accepts another operation.
- Delivery is ordered by the same actor: a transition is stored before it is
  published.
- Every active subscriber receives the same session value.
- Equal snapshots produce no event.
- A slow subscriber keeps only the newest pending value, including when a newer
  transition replaces its unconsumed initial snapshot.
- A subscriber can cancel its consuming task without changing other streams.
- Termination removes that continuation; a later publication also prunes a
  terminated entry defensively.
- The session and registry share actor isolation; no `@unchecked Sendable`
  escape hatch or shared mutable global state is needed.

## Day 034 decision

Observer is appropriate here because receivers have independent lifetimes and
must cancel without editing the session owner. `AsyncStream` is enough of a
boundary; a broader event framework would be ceremony without additional
verified behavior.

Day 035 removed the separate observation-center actor. Keeping state and
subscriptions together closes the initial-value race and uncertainties about
cross-actor message ordering while reducing the implementation by one type.
