# Adapter and Strategy Review

Review date: 2026-08-24

This review closes Internal Day 014. It validates the first two complete pattern
cycles together and records the decision boundary that keeps Strategy distinct
from State and Bridge before the Bridge cycle begins.

## Review scope

- Build and test the complete Swift Package with compiler warnings as errors.
- Run SwiftLint in strict mode across the canonical source and test trees.
- Recheck local Markdown links and both canonical Mermaid diagrams.
- Compare the Adapter and Strategy headers with the approved visual reference.
- Review public APIs, tests, and documentation for avoidable abstractions.
- Confirm that `Editorial/` remains ignored and outside the Git diff.

## Pattern boundary matrix

| Question | Adapter | Strategy | State | Bridge |
| --- | --- | --- | --- | --- |
| What varies? | An external interface and vocabulary | One selected algorithm | Behavior allowed by the current lifecycle state | Two dimensions that evolve independently |
| What triggers the choice? | Composition selects one vendor integration | A caller selects one ranking policy | A valid transition changes the object's state | Composition combines one abstraction with one implementation |
| Does behavior transition itself? | No | No | Yes | No |
| How many variation axes matter? | One incompatible boundary per vendor | One algorithm family | One lifecycle with constrained transitions | Two independently growing axes |
| Current or planned app example | AtlasPay or BorealPay authorization | Delivery-option ranking | Resumable encrypted upload | Notification purpose × delivery channel |
| Prefer direct Swift when… | One stable SDK has a local mapping | A small enum or closure keeps policies clear | An enum and pure transition function express every valid state | One axis is fixed or the combinations do not grow independently |

The decisive distinction is ownership of change. Adapter owns translation at an
external boundary. Strategy owns one replaceable ranking behavior selected by a
caller. State would own valid lifecycle transitions and state-dependent
behavior. Bridge would compose notification purpose and transport so either axis
can grow without multiplying concrete combinations.

## Adapter review

`CheckoutPaymentService` depends on the app-owned `PaymentAuthorizing` contract
because two incompatible vendor implementations already exist. The protocol is
therefore a real integration boundary and composition seam, not a mock-only
abstraction. AtlasPay and BorealPay request, result, and error mapping stays in
their adapters; checkout owns only domain validation and delegation.

No factory, provider registry, generic repository, retry layer, or protocol for
domain values is justified. Provider selection remains ordinary composition
code. The test suite covers both translations, domain-error containment,
validation before SDK invocation, and provider substitution.

## Strategy review

`DeliveryRankingStrategy` is one immutable `Sendable` value containing a scoring
function and direction. It replaces the central preference switch and keeps an
immutable campaign snapshot beside the behavior that interprets it. A protocol
and four concrete types would not reduce coupling for these synchronous integer
scorers.

The ranker neither remembers state nor transitions between behaviors, so this is
not State. It varies one ranking algorithm over one stable operation, so it is
not Bridge. The test suite covers the built-in policies, deterministic ties,
value preservation, missing campaign scores, and changed campaign snapshots.

## Visual and documentation review

Both final headers are 1672 × 941. Against the approved Adapter reference they
preserve the upper-left type hierarchy, upper-right original RG logo, closed
charcoal/red/white palette, left-to-right technical flow, and restrained detail.
Adapter uses a translation housing; Strategy uses a selector and three ranking
lanes. They read as one collection while explaining different responsibilities.

The canonical READMEs contain descriptive alt text, one-sentence captions,
domain-named Mermaid diagrams, accessible descriptions, executable commands,
trade-offs, alternatives, `When not to use it`, and links to concrete source and
test files. The diagrams use a structural relationship flow for Adapter and a
behavioral sequence for Strategy.

## Complexity decision

The review found no production code that should be added or removed. The useful
abstractions are exactly one app-owned integration protocol for two vendors and
one value-based strategy boundary for four policies. Keeping vendor selection,
ranking selection, and test fixtures as ordinary composition avoids factories,
registries, inheritance hierarchies, mutable contexts, and lifecycle machinery.

## Verification

Run from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict Sources Tests
git diff --check
git check-ignore -v Editorial/
```

Results:

- The full build completed with compiler warnings treated as errors.
- The complete Swift Testing run passed 13 tests across 9 suites.
- SwiftLint reported 0 violations across all 13 files under `Sources` and
  `Tests`.
- Every non-template local Markdown link resolves. The teaching template was
  checked separately because its `[pattern]` and `path/to/...` placeholders are
  intentionally not repository paths.
- Each canonical README contains exactly one Mermaid block. Local structural
  validation confirmed the Adapter flow relationships, Strategy participants,
  message endpoints, and balanced sequence loop; a manual review confirmed that
  every label matches the current Swift implementation.
- Both headers pass the five-part visual comparison and the required 1672 × 941
  dimensions.
- `git diff --check` passed, and `Editorial/` remains ignored.

## Readiness decision

Adapter and Strategy remain complete and correctly classified. The next work
unit is Day 015: define the direct notification solution and acceptance criteria
that will test whether two independently changing axes can eventually earn
Bridge. This review does not introduce or pre-approve Bridge.
