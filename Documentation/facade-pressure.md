# Facade Pressure: One Checkout Use Case, Three Entry Points

Pressure-review date: 2026-09-20

Internal Day 044 adds two credible ways to place the same order: a **Buy Again**
shortcut from order history and a payment-retry banner after a previous decline.
The implementation remains deliberately direct so the duplicated subsystem
knowledge is executable before Facade is introduced.

## The requirement that changed

Checkout placement is no longer owned by one screen. Three product surfaces now
start the same use case:

- the checkout screen submits the current cart;
- order history reconstructs a submission for **Buy Again**;
- a payment-retry banner submits the same checkout with a replacement token.

Their presentation and input preparation differ, but placement does not. Every
entry point must reserve all items, authorize the exact total, create the linked
order, release the reservation after a decline, and record one terminal event.

## Direct duplication retained

[`CheckoutPressure.swift`](../Sources/DesignPatterns/Facade/CheckoutPressure.swift)
adds `DirectBuyAgainShortcut` and `DirectPaymentRetryBanner`. Each client stores
the same four concrete subsystems and repeats the orchestration already present
in `DirectCheckoutScreen`:

1. reserve inventory;
2. record an inventory failure and stop when reservation fails;
3. authorize payment;
4. release the reservation and record failure when authorization declines;
5. create the order and record completion after both earlier steps succeed.

There is still no `CheckoutFacade`, subsystem protocol, coordinator, generic
pipeline, service locator, or workflow engine. The duplication is intentional:
extracting it during the pressure day would hide the evidence that must justify
tomorrow's boundary.

## Measured pressure

The three direct clients now expose:

- **12 subsystem dependency slots:** four concrete components in each client;
- **three copies of one five-stage workflow;**
- **three payment-decline compensation branches;**
- **three terminal analytics decision points;**
- intermediate reservation and authorization identifiers in every client.

The count matters more than the line total. Changing reservation cleanup,
moving terminal analytics after durable order creation, or adding another
placement invariant now requires three synchronized edits. A missed edit is a
partial-failure bug, not cosmetic duplication.

The presentation surfaces do not benefit from knowing `CheckoutInventory`,
`CheckoutPayments`, `CheckoutOrders`, `CheckoutAnalytics`,
`CheckoutInventoryReservation`, or `CheckoutPaymentAuthorization`. They only
need one product operation that returns a `CheckoutOrder` or throws the domain
failure.

## Executable evidence

[`FacadePressureTests.swift`](../Tests/DesignPatternsTests/FacadePressureTests.swift)
uses isolated in-memory components and Swift Testing to verify that both new
entry points:

- create an order linked to the inventory reservation and payment authorization;
- apply stock changes only through the successful placement sequence;
- release stock and remove the reservation after payment declines;
- create no order after a decline;
- record the same terminal analytics semantics as the original screen.

Together with `FacadeProblemTests`, the tests prove all three clients preserve
the same success and compensation rules. Run the focused evidence with:

```sh
swift test -Xswiftc -warnings-as-errors --filter FacadePressureTests
```

## Why this is Facade pressure

The changing dimension is the number of clients, not interchangeable algorithms
or wrappers. Strategy would let a caller choose an algorithm but would not hide
the subsystem sequence. Decorator would wrap one interface with optional
behavior but would make ordering part of the wrapper chain. A coordinator or
workflow engine would add lifecycle or generic execution responsibilities that
this one bounded operation does not need.

A narrow Facade can present checkout placement as the single product operation
the clients already perceive while keeping the subsystem APIs available to
other use cases such as stock display or payment-method validation. It should
not absorb cart editing, input reconstruction, navigation, UI state, retries,
or every commerce service.

## Smaller alternatives still in contention

A private helper function could remove the copied method body. That is a valid
no-pattern outcome when all components remain local values and there is no
stable object boundary to inject. It becomes less useful here because the four
subsystems carry coordinated mutable state that the caller must pass in and
recover after both success and failure.

A closure containing `placeOrder` would hide the choreography from each UI
surface, but it would obscure which long-lived checkout state it captures and
would provide a weaker testing and dependency boundary. A use-case value with
one operation is viable; in GoF vocabulary, when it deliberately offers a
simplified entry point over these subsystem objects, that value is the minimal
Facade this example is evaluating.

## Boundary carried into Day 045

Facade may replace the pressure implementation only if it:

- exposes one narrow `placeOrder(from:)` operation;
- owns ordering, identifier handoff, compensation, and terminal analytics;
- returns the domain `CheckoutOrder` and preserves existing domain errors;
- removes subsystem knowledge from all three product clients;
- retains lower-level subsystem access where another use case genuinely needs it;
- does not become a service locator, screen model, retry engine, or commerce god
  object;
- avoids protocols unless an external boundary or immediate variation requires
  one.

## Day 044 decision

The direct design remains correct, but three clients now repeat 12 subsystem
dependencies, three workflow copies, and three compensation branches. Facade is
a credible candidate because one stable placement boundary can centralize risky
partial-failure knowledge without hiding unrelated subsystem capabilities. Day
045 must prove that it can do so with one small type rather than adding a new
layer hierarchy.
