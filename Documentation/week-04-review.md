# Abstract Factory and Builder Review

Review date: 2026-09-05

This review closes Internal Day 028. It validates the Abstract Factory and
Builder cycles together, inspects both construction APIs for accidental
ceremony, and records the direct Swift alternatives that should remain the
default before Prototype begins.

## Review scope

- Build and test the complete Swift Package with compiler warnings as errors.
- Run SwiftLint in strict mode across the canonical source and test trees.
- Recheck local Markdown links and both canonical Mermaid diagrams.
- Compare both editorial headers with the approved Adapter reference.
- Review public construction APIs, validation boundaries, and tests for
  avoidable abstractions or invalid states.
- Confirm that `Editorial/` remains ignored and outside the Git diff.

## Construction boundary matrix

| Question | Abstract Factory | Builder | Direct Swift alternative |
| --- | --- | --- | --- |
| What is created? | One compatible regional family with three service products | One immutable multipart support request | One aggregate or throwing initializer |
| What pressure earns the pattern? | Independently selected family members expose 14 invalid assemblies for two valid families | Ordered UI events expose four invalid sequence families and require immediate consent and byte checks | All values arrive together and one validation pass is sufficient |
| Where does mutable state live? | Nowhere; factories and products are values | Only inside the retained builder draft | In local form state before one atomic initializer call |
| What becomes impossible for normal callers? | Constructing `RegionalServices` member by member | Omitting or repeating the required message, appending after build, or producing a partial request | Nothing beyond invariants enforced by the initializer |
| What remains a runtime contract? | A public custom factory can still return a mixed family | Consent, payload size, and the sealed-builder state | All validation performed by the initializer |
| What was deliberately rejected? | Product protocols, a factory registry, and a factory-of-factories | A builder protocol, director, fluent reference object, and staged generic graph | Extra construction types without demonstrated change pressure |

The decisive difference is the shape of construction. Abstract Factory chooses
one complete family from multiple compatible product axes. Builder retains the
verified intermediate state of one product while inputs arrive over time.
Neither is a more elaborate spelling of Factory Method, whose creator owns the
choice of one product inside a shared workflow.

## Abstract Factory review

`RegionalCommerceFactory` contains only the three creation operations needed by
checkout and the region identity used to verify their compatibility. The EU and
LATAM concrete factories are stateless values; the products remain enums rather
than gaining one protocol hierarchy per tax, payment, and receipt policy.

`RegionalServices` has a `fileprivate` initializer. Normal clients therefore
choose a region or provide one complete factory instead of coordinating three
product selectors. The defensive `isCoherent` check remains justified because
the public factory protocol is an intentional extension and test seam: Swift's
type system cannot prove that a custom conformer returns three semantically
matching enum cases.

A closed switch returning one aggregate is still the preferred solution when
the family is fixed and changes atomically. The protocol becomes useful here
only because multiple complete families are immediate and the creation
operations vary together. No registry, dependency container, product protocol,
or runtime discovery layer is required.

## Builder review

`SupportUploadRequestBuilder` starts with the required message, so callers
cannot express a draft with no first part or add a second message. Its named
mutating operations correspond to real support-flow events and reject missing
consent or excessive bytes before changing the ordered part list. `build()` is
the only product boundary and seals that builder value.

The builder remains a `struct`. Copying a draft intentionally creates an
independent branch rather than shared mutable state, and the tests make that
behavior explicit. The `isBuilt` flag is not a lifecycle framework: it enforces
the product requirement that the same retained construction value cannot accept
private data after finalization.

No builder protocol is justified by one product shape. A director would replay
interactive UI decisions that the screens already own, fluent chaining would
misrepresent inputs arriving at different times, and a staged generic builder
would multiply types while consent and payload size would still need runtime
validation. When all inputs are present on one Submit action, the documented
throwing initializer remains clearer.

## Visual and documentation review

Both final headers are 1672 x 941. Against the approved Adapter reference, they
retain the upper-left hierarchy, upper-right original RG logo, matte charcoal
background, restrained red and orange accents, and one central industrial
metaphor. Abstract Factory routes one regional choice into a coherent
three-product family; Builder moves message and attachment parts through
ordered assembly stations into one sealed request.

Each canonical README contains descriptive alt text, a one-sentence caption,
one domain-named Mermaid flowchart, an equivalent accessible description,
verified commands, tests, trade-offs, alternatives, `When not to use it`, and
links to concrete source and test files. The diagrams explain different
construction shapes without duplicating the editorial scenes.

## Complexity decision

The review found no production-code simplification to make. Abstract Factory
keeps three compatible creation decisions behind one family boundary without
adding product protocols. Builder keeps only the mutable state required between
real UI steps without adding a director or protocol. Their direct alternatives
remain prominent in both guides so readers do not adopt either pattern for
parameter count, naming style, or hypothetical extensibility.

The historical direct baselines and pressure documents explain the transition,
so the canonical source does not retain comparative constructors or raw step
languages. This avoids two parallel APIs and keeps each example focused on one
pattern.

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
- The complete Swift Testing run passed 47 tests across 27 suites.
- SwiftLint reported 0 violations across 24 files under `Sources` and `Tests`.
- All 203 concrete local Markdown links resolve. Template placeholders were
  excluded because they are intentionally not repository paths.
- Each canonical README contains exactly one Mermaid block. Structural review
  confirmed that Abstract Factory shows one region selecting a complete family,
  while Builder shows consent-gated parts crossing one final product boundary.
- Both headers pass the five-part visual comparison and match the required
  1672 x 941 dimensions.
- `git diff --check` passed, and `Editorial/` remains ignored.

## Readiness decision

Abstract Factory and Builder are complete, distinct, and no more abstract than
their demonstrated construction pressures require. The repository is ready for
Internal Day 029: begin with Swift value-copy semantics and define the reference
boundary that could earn Prototype. This review does not design that graph or
start the next pattern.
