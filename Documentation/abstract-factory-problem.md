# Abstract Factory Problem: Regional Commerce Service Families

Problem-definition date: 2026-08-30

Pressure evidence added: 2026-08-31

This document defines Day 022 of the Abstract Factory cycle. It fixes the
regional commerce problem, keeps the first solution direct, and records the
acceptance tests and visual thesis before any factory protocol is introduced.
The completed solution is documented in the
[canonical Abstract Factory guide](../Creational%20Patterns/Abstract%20Factory/README.md).

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

The original acceptance evidence evolved into
[`AbstractFactoryTests.swift`](../Tests/DesignPatternsTests/AbstractFactoryTests.swift),
which verifies:

- EU and LATAM composition roots create coherent service families;
- each family calculates its own tax and payment reference;
- mixed-region services are rejected before checkout completes;
- non-payable orders are rejected;
- calculating checkout does not mutate the order value.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter AbstractFactoryTests
```

## Pressure observed on Day 023

Abstract Factory should earn its place only when selecting family members
independently becomes a recurring source of invalid combinations or duplicated
composition code. The [pressure review](abstract-factory-pressure.md) measures
that cost without adding a factory protocol merely because the names “EU” and
“LATAM” exist:

- the three service products now have independent region selectors;
- the composition root must repeat one regional decision across all three;
- two regions and three independent selectors expose 16 declared assemblies,
  of which only two are coherent.

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

Day 024 completes the final
[`abstract-factory-header.png`](Assets/Patterns/creational/abstract-factory-header.png)
under the shared contract in [`visual-style.md`](visual-style.md). It retains
the approved RG composition and uses controlled three-module assembly rather
than a generic factory icon.

## Day 024 resolution

The original direct `RegionalServices` value and composition-root switch were
executable, small, and covered by acceptance tests. Day 023 retained direct
selection while making its repetition and invalid-member matrix executable.
Day 024 introduces one `RegionalCommerceFactory` boundary and two concrete
value factories only after that evidence: standard callers now select one
complete family instead of assembling three independently chosen products.
