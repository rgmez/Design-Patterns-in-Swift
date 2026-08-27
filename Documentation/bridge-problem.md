# Bridge Problem: Notification Purpose and Delivery Channel

Problem-definition date: 2026-08-25

Pressure evidence: [Day 016 review](bridge-pressure.md)

This document defines Day 015 of the Bridge cycle. It fixes the notification
problem and the direct Swift baseline before any Bridge structure is introduced.
The completed solution is documented in the [canonical Bridge guide](../Structural%20Patterns/Bridge/README.md).

## Product scenario

A commerce app sends three kinds of customer communication:

- Security alerts when an account or payment needs immediate attention.
- Order updates when fulfillment changes the customer's next action.
- Promotional reminders for offers the customer may opt out of.

Each message can travel through push, email, or an in-app inbox. Product teams
change message purposes independently from the channels: a new alert may be
required without adding a new transport, while a new transport must support the
existing purposes without rewriting their business meaning.

The example prepares a delivery instruction but does not send network requests.
Transport clients, authorization, retries, localization, and user preferences
are outside this teaching unit. Keeping the boundary pure makes the product
matrix observable without timing or external services.

## Requirements and invariants

`NotificationRequest` is app-owned and contains the recipient, purpose, title,
and message body. The baseline `prepareNotification(_:for:)` must:

1. Preserve the recipient and the requested channel.
2. Produce a non-empty title and body for every purpose-channel pair.
3. Add channel-specific fields only where they make sense: push has a sound,
   email has a subject, and the in-app inbox has neither.
4. Keep security alerts urgent, order updates factual, and promotional email
   explicit about preference management.
5. Return a value without mutating the request or relying on an external
   service.

The output is a single app-owned `NotificationDispatch`. Its optional fields
are intentional domain constraints: `subject` is meaningful for email and
`sound` is meaningful for push.

## Direct Swift first

The smallest complete solution is an exhaustive `switch` over the purpose,
followed by one small channel switch for each purpose. The nine combinations
remain visible in [`NotificationDelivery.swift`](../Sources/DesignPatterns/Bridge/NotificationDelivery.swift):

```swift
switch request.purpose {
case .securityAlert:
    prepareSecurityAlert(request, for: channel)
case .orderUpdate:
    prepareOrderUpdate(request, for: channel)
case .promotionalReminder:
    preparePromotionalReminder(request, for: channel)
}
```

This direct implementation has useful properties while the matrix is small:
the compiler shows every closed case, the product rules are local, and there is
no protocol, class hierarchy, factory, registry, or mutable notification
context. The tests exercise the matrix rather than inspecting a private helper
or printed output.

## Acceptance tests

[`BridgeTests.swift`](../Tests/DesignPatternsTests/BridgeTests.swift)
verifies that:

- all nine combinations produce a valid dispatch with the original recipient;
- security push uses critical sound and no email subject;
- order email uses an order subject and no push sound;
- promotional preference copy appears on email only;
- preparing a dispatch does not mutate the input value.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter BridgeProblemTests
```

## Pressure measured on Day 016

The direct `switch` is still the right choice for this day. Bridge should earn
its place only if both axes remain open and the matrix starts duplicating work:

- a new purpose must edit every channel branch;
- a new channel must repeat formatting and policy for every purpose;
- channel integration details begin leaking into purpose rules or their tests;
- the number of combinations grows faster than the rules each combination
  actually needs.

Day 016 added SMS as one channel requirement. The matrix grew from 9 to 12
combinations, `NotificationDispatch` gained an SMS-only field, and every
purpose-specific switch required a new branch. The [pressure review](bridge-pressure.md)
records the edits, alternatives, and boundary for Day 017. Bridge remains
absent until the pattern can reduce that verified coupling.

## Initial visual thesis

**Thesis:** One notification purpose can cross several delivery channels;
independent change needs a clear boundary.

**Scene:** Three dark notification rails run left to right from a compact
purpose selector. Security, order, and promotion signal tiles enter the same
central routing boundary, then emerge as push, email, and inbox delivery
instructions. The central boundary is the focal point; the rails show the
two-axis product matrix without decorative devices or fake interface chrome.

The completed Bridge header is [`bridge-header.png`](Assets/Patterns/structural/bridge-header.png).
It follows the shared visual contract in [`Documentation/visual-style.md`](visual-style.md)
and uses the approved Adapter header only as the composition reference.

## Day 015 decision

The notification matrix is concrete, executable, and covered by acceptance
tests. The direct value-and-switch solution remains intentionally in place.
Bridge has not been introduced; Day 016 must prove that the matrix creates
avoidable complexity before the axes are separated.
