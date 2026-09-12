# 👀 Observer

![A central session signal source feeds three active receiver modules while a fourth disconnects independently](../../Documentation/Assets/Patterns/behavioral/observer-header.png)

*One confirmed session change reaches every active receiver while a
shorter-lived subscriber can detach without disrupting the others.*

**Category:** Behavioral

## 🎯 The app problem

A commerce app owns one authenticated session, while account UI, cart
ownership, synchronization, analytics, and short-lived screens must react to
confirmed sign-in and sign-out changes. Direct calls are clear while every
consumer shares the controller's lifetime. A screen that appears and
disappears creates an independent subscription lifetime.

## 🪶 Start with direct Swift

[`SessionChangeDirect.swift`](../../Sources/DesignPatterns/Observer/SessionChangeDirect.swift)
keeps the first solution as an exhaustive switch with concrete collaborators.
That is the right choice for a fixed consumer set: there is no registration,
cancellation, buffering, or ordering policy to explain.

## ⚡ The turning point

The pressure review in
[`observer-pressure.md`](../../Documentation/observer-pressure.md) adds a
short-lived session screen. The direct controller must gain another concrete
property and callback, and the screen cannot unregister itself from the source.

## 🧭 Pattern intent

Observer separates the session source from receivers whose lifetimes vary. The
source gives each receiver the current snapshot, then publishes confirmed state
changes while that receiver independently chooses when to consume and cancel.

## 🧩 Participants and responsibilities

| App role | Swift type | Responsibility |
| --- | --- | --- |
| Session source and subscription boundary | [`ObservedSessionController`](../../Sources/DesignPatterns/Observer/SessionObservation.swift) | Owns the current session and continuation registry in one actor-isolated ordering domain. |
| Receiver | `AsyncStream<UserSession>` | Lets each consumer control iteration and cancellation. |

## ⚙️ How the Swift implementation works

1. A consumer requests an `AsyncStream` from the controller.
2. Without suspending, the actor registers its continuation and enqueues the
   current session, so a transition cannot fall between snapshot and
   subscription.
3. The controller stores a different confirmed session and yields it to every
   active continuation.
4. Cancelling a consumer terminates its stream and removes only its
   continuation; publishing also prunes any already terminated entry.

## 🗺️ Diagram

```mermaid
sequenceDiagram
    participant A as Account screen
    participant Source as ObservedSessionController
    participant B as Sync worker
    A->>Source: sessionStream()
    Source-->>A: current session snapshot
    B->>Source: sessionStream()
    Source-->>B: current session snapshot
    Source->>Source: Store confirmed session
    Source-->>A: yield(session)
    Source-->>B: yield(session)
    A-->>Source: Cancellation / termination
    Source->>Source: Remove A continuation
```

The controller owns both the source-of-truth transition and subscription order.
It gives every receiver a current snapshot before later changes, and the screen
can terminate without affecting the sync worker.

**Accessible description:** An account screen and a sync worker independently
subscribe to one session controller and immediately receive its current state.
The controller then sends the same confirmed changes to both. When the screen
cancels, the controller removes only that continuation; the sync worker remains
subscribed.

## ▶️ Run the example

From the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
```

## 🧪 Tests

```sh
swift test -Xswiftc -warnings-as-errors --filter ObserverTests
```

The tests prove current-state delivery to late subscribers, fan-out to active
subscribers, duplicate filtering, bounded buffering, independent cancellation,
and terminated-subscription cleanup in
[`ObserverTests.swift`](../../Tests/DesignPatternsTests/ObserverTests.swift).

## ⚖️ Trade-offs

### What improves

- Receivers can subscribe and terminate independently.
- One actor orders the current state and continuation registry without a
  read-then-subscribe race.
- Swift provides the asynchronous sequence and termination model.

### What it costs

- Delivery becomes asynchronous and requires consumption tasks.
- Buffering, cancellation, and receiver lifetime are now part of the design.
- A slow consumer may skip intermediate snapshots because the stream retains
  only the newest pending value.
- The controller allocates and retains one continuation per active subscriber.

## 🔀 Alternatives considered

| Alternative | Prefer it when | Why it does not meet this example now |
| --- | --- | --- |
| Direct callbacks | The receiver set and lifetimes are fixed. | A disappearing screen cannot unregister from the direct source. |
| Swift Observation | UI reads one observable model directly. | This example needs multiple independent async consumers and cancellation. |
| Custom notification framework | A product has verified cross-module event semantics. | It would duplicate `AsyncStream` without a demonstrated need. |

## 🚫 When not to use it

- When a view can read one observable session model directly.
- When one local closure is clearer than a subscription registry.
- When asynchronous buffering and cancellation would obscure a synchronous
  state update.

## 🗂️ Source map

- [`SessionChangeDirect.swift`](../../Sources/DesignPatterns/Observer/SessionChangeDirect.swift)
  — direct baseline and measured pressure.
- [`SessionObservation.swift`](../../Sources/DesignPatterns/Observer/SessionObservation.swift)
  — actor-isolated source, current snapshot, and AsyncStream boundary.
- [`ObserverProblemTests.swift`](../../Tests/DesignPatternsTests/ObserverProblemTests.swift)
  — direct baseline behavior.
- [`ObserverPressureTests.swift`](../../Tests/DesignPatternsTests/ObserverPressureTests.swift)
  — lifecycle pressure.
- [`ObserverTests.swift`](../../Tests/DesignPatternsTests/ObserverTests.swift)
  — subscription, duplicate, and cancellation semantics.
