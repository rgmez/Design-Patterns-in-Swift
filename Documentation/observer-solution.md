# Observer Solution: AsyncStream with Independent Lifetimes

Solution-definition date: 2026-09-11

Day 034 introduces the smallest subscription boundary justified by the
pressure review. `SessionObservationCenter` uses Swift's standard
`AsyncStream`, while an actor owns the mutable continuation registry.

## Implementation

[`SessionObservation.swift`](../Sources/DesignPatterns/Observer/SessionObservation.swift)
contains two focused actors:

- `SessionObservationCenter` stores one continuation per subscriber, yields the
  same confirmed value to all active subscribers, and removes a subscription
  when its stream terminates.
- `ObservedSessionController` owns the source-of-truth session, filters equal
  snapshots, and publishes only actual transitions.

The center does not invent a notification name system or a custom observer
protocol. `AsyncStream` provides buffering, iteration, and termination; the
example adds only the fan-out registry that the multiple-consumer requirement
needs.

## Semantics made explicit

- Delivery is ordered by the controller's actor: a transition is stored before
  it is published.
- Every active subscriber receives the same session value.
- Equal snapshots produce no event.
- A slow subscriber keeps only the newest pending value, bounding retained
  session snapshots to one per subscription.
- A subscriber can cancel its consuming task without changing other streams.
- The registry is actor-isolated; no `@unchecked Sendable` escape hatch or
  shared mutable global state is needed.

## Day 034 decision

Observer is appropriate here because receivers have independent lifetimes and
must cancel without editing the session owner. `AsyncStream` is enough of a
boundary; a broader event framework would be ceremony without additional
verified behavior.
