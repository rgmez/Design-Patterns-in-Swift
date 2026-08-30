# Abstract Factory Problem: Regional Commerce Service Families

Problem-definition date: 2026-08-30

This document defines Day 022 of the Abstract Factory cycle. It fixes the
regional commerce problem, keeps the first solution direct, and records the
acceptance tests and visual thesis before any factory protocol is introduced.

## Product scenario

A white-label commerce app runs the same checkout flow for two regional
configurations:

- EU uses a VAT calculator, card authorization policy, and standard receipt.
- LATAM uses an IVA calculator, Pix authorization policy, and fiscal receipt.

The checkout flow should not know how a region implements tax, payment, or
receipts. Those services are a family: selecting one region should provide all
three compatible members. This example keeps the services local and deterministic;
network gateways, tax tables, localization, and persistence are outside the
teaching boundary.

## Requirements and invariants

`RegionalCheckoutOrder` is an app-owned value. `RegionalServices` contains the
three concrete service policies selected at the composition root. The baseline
must:

1. Assemble one EU family and one LATAM family with matching regional identity.
2. Calculate a regional tax, total, payment reference, and receipt without
   changing the order.
3. Reject a service value that mixes members from different regions.
4. Reject an order whose subtotal is not payable.
5. Keep all selection explicit and executable without protocols or a class tree.

## Direct Swift first

The smallest complete solution is a `RegionalServices` value plus one
composition-root `switch`:

```swift
switch region {
case .europeanUnion:
    RegionalServices(region: .europeanUnion, taxCalculator: .euVAT,
                     paymentAuthorizer: .euCard,
                     receiptFormatter: .euStandard)
case .latam:
    RegionalServices(region: .latam, taxCalculator: .latamIVA,
                     paymentAuthorizer: .latamPix,
                     receiptFormatter: .latamFiscal)
}
```

The checkout operation consumes the concrete value and verifies that all three
members report the selected region. With only two regions and three services,
the direct switch keeps construction visible and avoids a protocol hierarchy,
factory registry, or mutable context. The deliberate weakness is also visible:
callers can still construct a cross-region value by hand and rely on runtime
validation.

## Acceptance tests

[`AbstractFactoryProblemTests.swift`](../Tests/DesignPatternsTests/AbstractFactoryProblemTests.swift)
verifies:

- EU and LATAM composition roots create coherent service families;
- each family calculates its own tax and payment reference;
- mixed-region services are rejected before checkout completes;
- non-payable orders are rejected;
- calculating checkout does not mutate the order value.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter AbstractFactoryProblemTests
```

## Pressure required on Day 023

Abstract Factory should earn its place only when selecting family members
independently becomes a recurring source of invalid combinations or duplicated
composition code. Day 023 must measure that pressure rather than adding a
factory protocol because the names “EU” and “LATAM” exist:

- another regional deployment should require a complete family, not three
  unrelated switches;
- a new service product should be added to every family without allowing a
  partial configuration;
- tests should be able to prove family compatibility without enumerating every
  cross-region combination manually.

If the app keeps one family, a compile-time-fixed configuration, or a single
value that already enforces coherence, the direct composition root remains the
clearer design.

## Initial visual thesis

**Thesis:** A region selects one coherent checkout family; its tax, payment, and
receipt services must travel together.

**Scene:** Two dark regional rails enter from the left, one marked EU and one
marked LATAM. Each rail carries three distinct service modules—tax, payment,
receipt—toward one checkout boundary, where a complete family exits as one
order result. The paired rails and the locked three-module bundles show family
coherence; a visibly crossed module is the single warning signal for the
invalid-combination pressure reserved for Day 023.

The final Abstract Factory header belongs to Day 024. It must follow the shared
visual contract in [`visual-style.md`](visual-style.md), retain the approved RG
composition, and use a construction/assembly metaphor rather than a generic
factory icon.

## Day 022 decision

The direct `RegionalServices` value and composition-root switch are executable,
small, and covered by acceptance tests. Abstract Factory is not introduced
until the next day demonstrates repeated family assembly and invalid-member
combinations as measurable costs.
