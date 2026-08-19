# Adapter Pressure: A Second Payment SDK

Pressure-review date: 2026-08-19

Day 009 implements the direct Swift solution from the
[Adapter problem](adapter-problem.md), then adds the first concrete requirement
that makes the integration boundary harder to contain. It intentionally stops
before introducing Adapter.

## The requirement that changed

Checkout must now support `BorealPaySDK` for a second regional deployment. The
provider is selected once at composition time; a customer never chooses a
provider during checkout. Both integrations must preserve the same app-owned
`PaymentRequest`, `PaymentAuthorization`, and `PaymentError` behavior.

Boreal is incompatible with Atlas in different ways:

| Concern | AtlasPaySDK | BorealPaySDK | Checkout outcome |
| --- | --- | --- | --- |
| Operation | `submit(_:)` | `authorize(payment:)` | `authorize(_:)` |
| Input | `AtlasChargeRequest` | `BorealAuthorizationInput` | `PaymentRequest` |
| Success ID | `chargeID` | Associated `transactionReference` | `paymentID` |
| Decline | `rejected(reasonCode:)` | `denied(code:)` | `declined` |
| Retryable state | Thrown SDK errors | `pending` or thrown SDK errors | `temporarilyUnavailable` |

The second SDK is not difficult because its syntax differs. It is difficult
because it gives different meanings and ownership to requests, results, and
failures that checkout needs to treat uniformly.

## Direct implementation

[`CheckoutPaymentService`](../Sources/DesignPatterns/Adapter/CheckoutPaymentService.swift)
still owns the complete operation. An app-owned `CheckoutPaymentProvider` enum
stores either concrete SDK client, and `authorize(_:)` switches over it. Each
branch constructs one vendor request and translates all vendor outcomes back to
the domain.

This is the smallest honest extension of the one-provider implementation. It
adds no payment protocol, adapter type, factory, type erasure, repository, or
provider selection logic at runtime. Input validation also remains shared before
the switch.

## Observable pressure

The direct solution works and all acceptance tests pass, but the second vendor
produces four concrete costs:

1. `CheckoutPaymentProvider`, an app-owned composition type, imports and stores
   `AtlasPayClient` and `BorealPayGateway` directly. Vendor replacement changes
   app-owned code.
2. `CheckoutPaymentService.authorize(_:)` branches by provider before it can
   perform the same domain operation. Every new SDK adds another branch.
3. The service owns two request mappings, two success mappings, and two complete
   vendor error taxonomies. These are integration decisions, not checkout
   policy.
4. Tests must construct a provider-specific client and know which request type
   to record. A checkout test cannot supply one domain-level payment substitute.

The cost is visible in source rather than forecast: adding Boreal required one
new enum case and a second mapping path inside the checkout service. Vendor type
and case names now appear throughout its provider storage and mapping branches.
A third provider would modify the same enum and service again.

## What does not justify Adapter

Different method labels alone do not justify a pattern. Neither do asynchronous
calls, test doubles, or a desire to hide every third-party import. With one
stable provider, the Atlas-only local mapping described on Day 008 remains
shorter and easier to navigate than an abstraction.

The pressure is specifically the combination of immediate provider variation
and integration knowledge inside app-owned checkout code. Day 010 may introduce
one domain operation at that boundary only if it removes the provider switch and
mappings from `CheckoutPaymentService` without moving provider selection into
business logic.

## Verification

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter AdapterPressureTests
```

[`AdapterPressureTests`](../Tests/DesignPatternsTests/AdapterPressureTests.swift)
verify lossless request mapping, approval mapping, hidden vendor decline codes,
retryable infrastructure failures, validation before SDK invocation, and the
second provider's distinct request and result path.

## Day 009 decision

Adapter has now earned consideration: checkout changes whenever a payment SDK is
added or replaced, even though its domain operation is stable. The next day must
test whether two minimal SDK-specific adapters reduce that coupling. It must not
add a factory or a broader payment framework.
