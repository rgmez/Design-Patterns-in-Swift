# Mediator Pressure: Independently Owned Checkout Sections

Pressure-review date: 2026-10-12

Internal Day 068 changes the ownership boundary from Day 067. Address entry,
delivery-window selection, promotion entry, and payment selection now have
separate stateful modules. This models a checkout assembled from independently
maintained sections, each of which can also be exercised without the whole form.
The original value-semantic form remains the preferable baseline when that
ownership requirement does not exist.

## New product requirement

The promotion section offers an explicit customer action: prefer a delivery
window compatible with the entered promotion. It keeps the current window if
eligible, otherwise requests the first eligible window in display order. The
preference stays active across address and window changes until the customer
clears or replaces the code. Entering a code alone never changes the window.

This introduces a reverse interaction. Delivery changes refresh promotion
eligibility, but promotion can now request another delivery choice. Payment
must follow the final choice, including when that choice changes synchronously
inside a callback. A discarded payment is never silently restored.

There is no remote refresh, UI framework, pricing engine, payment authorization,
navigation, persistence, concurrency, or asynchronous event delivery in this
example. These synchronous reference types belong to one checkout and are not
shared across tasks.

## Direct implementation under pressure

[`DeliveryCheckoutPressure.swift`](../Sources/DesignPatterns/Mediator/DeliveryCheckoutPressure.swift)
contains four concrete modules and an explicit composition root:

- `CheckoutAddressModule` owns the address and announces changes.
- `CheckoutDeliveryModule` owns zone filtering and slot validity.
- `CheckoutPaymentModule` owns payment availability and selection validity.
- `CheckoutPromotionModule` owns codes, eligibility, and the customer preference.
- `DirectDeliveryCheckoutModules` installs the direct callback graph and exposes
  the same read-only snapshot shape as Day 067.

The composition root has three callback assignments and four directed participant
dependencies: address → delivery, delivery → payment, delivery → promotion,
and promotion → delivery. Weak captures prevent these installed callbacks from
keeping participant modules alive after their owning checkout is released.
They do not solve interaction ordering or prevent feedback loops.

## Measured coordination cost

| Signal | Day 067 | Day 068 |
| --- | ---: | ---: |
| Stateful reference-semantic participants | 0 | 4 |
| Installed cross-module callbacks | 0 | 3 |
| Directed participant dependencies | 0 | 4 |
| Bidirectional participant pairs | 0 | 1 |
| Callback cycles | 0 | 1 |
| Coordination sites requiring reentry awareness | 0 | 2 |

These are source-level counts for the installed graph, not runtime profiling or
a claim about performance. The two reentry-sensitive sites are the delivery
selection's unchanged-value guard and the composition root's delivery callback.

## Verified feedback risk

Two details are necessary for the direct graph to stay coherent:

1. Delivery selection returns successfully without notifying when the requested
   slot is already selected. Promotion refresh can request that same eligible
   slot again; notifying unchanged selections would recurse through delivery →
   promotion → delivery indefinitely.
2. The delivery callback updates payment **before** refreshing promotion.
   Promotion may synchronously correct the selected slot. Updating payment after
   that refresh would overwrite the nested callback's final availability with
   the outer callback's stale slot.

The acceptance suite selects express while a scheduled-delivery preference is
active. Promotion redirects the checkout to evening, and payment must expose
evening's card and cash options rather than express's card-only options. It also
verifies that cash discarded during the intermediate express update stays
cleared. The example contains the guards; it does not execute unbounded recursion
as a test or leave a known failing checkout in the package.

```mermaid
sequenceDiagram
    actor Customer
    participant Delivery
    participant Payment
    participant Promotion
    Customer->>Delivery: select express
    Delivery->>Payment: expose card; discard cash
    Delivery->>Promotion: refresh with express
    Promotion->>Delivery: request eligible evening window
    Delivery->>Payment: expose card and cash
    Delivery->>Promotion: refresh with evening
    Promotion->>Delivery: request evening again
    Delivery-->>Promotion: unchanged; no notification
```

An accessible equivalent is: express selection first invalidates cash, then
refreshes promotion. The active preference requests evening, whose nested update
replaces payment availability. A repeated evening request stops at the unchanged
selection guard. When callbacks return, the final snapshot uses evening and has
no payment selected.

## Acceptance evidence

[`MediatorPressureTests.swift`](../Tests/DesignPatternsTests/MediatorPressureTests.swift)
verifies address invalidation, unavailable choices, unknown promotions, promotion
requests, corrective callback ordering, preference across zones, preference
removal, unavailable eligible windows, unchanged-selection notification
suppression, and release of participants after the checkout goes away. Every test
owns a fresh checkout; no global mutable state or timing assumption is required.

```sh
swift test -Xswiftc -warnings-as-errors --filter Mediator
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

## Boundary for Day 069

Mediator has earned consideration for the interaction graph. A focused mediator
should replace direct participant-to-participant routing, make corrective-update
ordering explicit, and preserve these acceptance outcomes. Its responsibilities
should stop at coordinating address, delivery, promotion, and payment changes.

Local validation remains with the participants: delivery knows its supported
zones, payment rejects unavailable methods, and promotion evaluates its offers.
The mediator must not absorb these rules, calculate prices, initiate networking,
authorize payment, or own navigation. A universal event bus, one protocol per
section, and a mediator that merely forwards every event have not been justified.

If one team still owns four fixed values in one simple form, Day 067 remains a
clearer solution. This pressure example depends on independent section ownership
and the explicit promotion-driven reverse interaction; section count alone does
not establish a need for Mediator.

## Day 068 decision

The direct module graph is runnable and coherent, but its correctness now relies
on callback order and an unchanged-selection guard across a bidirectional pair.
Day 069 may introduce one focused interaction boundary to make that policy easier
to change and verify. It should preserve participant validation and demonstrate
an improvement over both this graph and the simpler original form.
