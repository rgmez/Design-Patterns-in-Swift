# Abstract Factory Pressure: Independently Selected Regional Services

Pressure-review date: 2026-08-31

This document records Day 023 of the Abstract Factory cycle. It extends the
direct regional-commerce solution with independently delivered service settings
and measures the resulting invalid combinations. Abstract Factory is not
introduced yet.

## The requirement that changed

The white-label configuration service now rolls out tax, payment, and receipt
policies independently. This supports staged regional migrations, but the app
receives four decisions instead of one: the tenant's expected region and one
region choice for each of the three service products.

Checkout must still reject a mixed family. An EU tenant cannot calculate VAT,
authorize through the LATAM payment policy, and issue an EU receipt merely
because those three settings arrived successfully.

## Direct Swift extension retained

`RegionalServiceSelection` keeps the independently supplied settings as an
app-owned value. Three direct selector functions map a region to one concrete
tax calculator, payment authorizer, or receipt formatter. The composition root
then assembles `RegionalServices` from those independent choices:

```swift
RegionalServices(
    region: selection.expectedRegion,
    taxCalculator: makeRegionalTaxCalculator(for: selection.taxRegion),
    paymentAuthorizer: makeRegionalPaymentAuthorizer(for: selection.paymentRegion),
    receiptFormatter: makeRegionalReceiptFormatter(for: selection.receiptRegion)
)
```

The normal `makeRegionalServices(for:)` path remains safe only by repeating the
same region four times. There is still no abstract factory protocol, concrete
factory type, registry, service locator, or dependency container.

## Measured pressure

Two regions across three independently selectable products create eight member
combinations for each declared region. Across both declared regions, the direct
configuration surface exposes 16 assemblies:

- 2 are coherent complete families;
- 14 are invalid cross-region combinations;
- 3 separate switches repeat the same regional decision;
- adding a third region requires editing every product selector;
- adding a fourth product creates another selector and doubles the combination
  space to 32 while adding only two valid families.

The problem is not switch length. It is that compatibility is checked only
after independently chosen products have already been assembled. The type
system and creation API do not make the complete-family invariant the default.

## Executable evidence

The Day 023 evidence was captured by the former problem suite. The completed
[`AbstractFactoryTests.swift`](../Tests/DesignPatternsTests/AbstractFactoryTests.swift)
preserves the two valid families as parameterized cases and verifies the new
complete-family boundary. The measured baseline remains: only two of the 16
assemblies were coherent, while checkout rejected all 14 mixed families.

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter AbstractFactoryTests
```

## Alternatives still worth considering

A single closed `CommerceRegion` switch returning an immutable
`RegionalServices` value remains simpler when all regional settings deploy
together. Making `RegionalServices` construction private could also enforce
coherence without an Abstract Factory when callers only need the aggregate
value and concrete product types never vary independently.

A Simple Factory can select that one aggregate value. It becomes Abstract
Factory only when clients need a family of related products behind stable
creation operations and multiple concrete families must guarantee compatible
members.

## Day 024 resolution

The direct solution remained correct and warning-free, but independent
selection turned one regional decision into three switches and admitted 14
invalid assemblies for only two valid families. Day 024 replaces those selectors
with the smallest complete-family boundary: one `RegionalCommerceFactory`
protocol and two concrete value factories. `RegionalServices` construction is
module-owned, while checkout retains a defensive coherence check for external
factory conformers. See the
[canonical guide](../Creational%20Patterns/Abstract%20Factory/README.md) for the
implementation, diagram, costs, and alternatives.
