# Bridge Pressure: One Channel, Three Purpose Edits

Pressure-review date: 2026-08-26

This document records Day 016 of the Bridge cycle. It adds one real delivery
requirement to the direct implementation from Day 015 and measures the cost
without introducing Bridge, a protocol hierarchy, or channel classes.

## Requirement that changed

The commerce app must now offer SMS for security alerts, order updates, and
promotional reminders. The SMS provider requires a registered sender ID, and
promotional messages must include opt-out copy. Existing push, email, and
in-app behavior must remain unchanged.

This is a channel requirement, not a new notification purpose. Product meaning
still belongs to security, order, and promotion; SMS adds delivery policy that
all three purposes must understand in the direct design.

## Direct implementation retained

`NotificationChannel` gains an `sms` case and `NotificationDispatch` gains the
optional `senderID` required by that channel. Each purpose-specific helper keeps
its exhaustive channel switch and adds an SMS branch:

```swift
private func prepareOrderUpdate(
    _ request: NotificationRequest,
    for channel: NotificationChannel
) -> NotificationDispatch {
    switch channel {
    // Existing push, email, and inbox branches...
    case .sms:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Order update: \(request.title)",
            body: request.body,
            senderID: "RGSHOP"
        )
    }
}
```

The result is still ordinary Swift with closed enums, immutable values, and
compiler-checked switches. No new abstraction has been added merely to avoid a
few lines.

## Measured pressure

The product matrix grows from three purposes by three channels to three by
four: 9 combinations become 12, a 33% increase caused by one channel.

The source change is scattered across both axes:

1. Add one channel enum case.
2. Extend the shared dispatch value with an SMS-only field.
3. Add one branch to the security-purpose switch.
4. Add one branch to the order-purpose switch.
5. Add one branch to the promotion-purpose switch.
6. Repeat the sender policy in all three branches while keeping promotional
   opt-out copy purpose-specific.

The compiler usefully identifies every missing branch, but it cannot prevent a
purpose from assigning the wrong sender or accidentally adding SMS policy to an
email. A fifth channel would require another edit in every purpose helper. A
fourth purpose would require a new helper that knows all four channels. The
number of edits therefore grows along the opposite axis even when only one
business capability changes.

## Executable evidence

[`BridgeTests.swift`](../Tests/DesignPatternsTests/BridgeTests.swift)
now uses Swift Testing parameterization so every one of the 12 combinations is
reported independently. Its focused suites verify:

- every purpose can produce every channel;
- `sound`, `subject`, and `senderID` remain on their applicable channels;
- all SMS purposes use the registered sender;
- only promotional SMS adds opt-out copy;
- the app-owned request remains unchanged.

Run the evidence with:

```sh
swift test -Xswiftc -warnings-as-errors --filter BridgeProblemTests
```

## Why a smaller fix is not enough

A shared SMS helper could remove the repeated `senderID` literal, and that would
be a sensible local cleanup. It would not change the structural cost: adding a
channel would still require editing every purpose switch, while adding a
purpose would still require encoding every channel. A dictionary of closures
would move the same matrix into registration code and weaken exhaustive compiler
checking. A larger enum payload would make the output model more precise but
would not separate how a purpose composes content from how a channel delivers
it.

The pressure is not raw line count. It is the change direction: channel policy
is copied into purpose-owned branches, so independently changing axes are no
longer independently editable.

## Boundary carried into Day 017

Day 017 introduced Bridge only after preserving these verified rules while
making each axis change in one place. The smallest acceptable design had to:

- keep purpose-specific content separate from channel delivery policy;
- add or replace a channel without modifying every purpose;
- keep asynchronous delivery explicit and testable without network services;
- avoid a class-per-combination hierarchy, mutable context, factory, registry,
  or protocol with only one implementation;
- retain value semantics wherever reference identity is unnecessary.

The resulting implementation completed the canonical README, Mermaid diagram,
RG editorial header, trade-offs, alternatives, and `When not to use it`
guidance. See the [canonical Bridge guide](../Structural%20Patterns/Bridge/README.md).

## Day 016 decision

SMS proves a repeatable coupling cost rather than a hypothetical preference for
patterns. The direct solution still passed and remained readable at 12
combinations, but one channel change touched every purpose and leaked provider
policy into each branch. That evidence justified the minimal Bridge completed
on Day 017.
