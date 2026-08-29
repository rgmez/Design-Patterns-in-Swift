# Bridge and Factory Method Review

Review date: 2026-08-29

This review closes Internal Day 021. It validates the Bridge and Factory Method
cycles together, checks their boundaries against nearby patterns, and records
which abstractions remain deliberately absent before Abstract Factory begins.

## Review scope

- Build and test the complete Swift Package with compiler warnings as errors.
- Run SwiftLint in strict mode across the canonical source and test trees.
- Recheck local Markdown links and the Bridge and Factory Method Mermaid diagrams.
- Compare both editorial headers with the approved Adapter reference.
- Review public APIs, tests, and documentation for avoidable abstractions.
- Confirm that `Editorial/` remains ignored and outside the Git diff.

## Pattern boundary matrix

| Question | Bridge | Factory Method | Adapter | Strategy | Abstract Factory |
| --- | --- | --- | --- | --- | --- |
| What varies? | Notification purpose and delivery channel | Provider workflow and parser creation | Incompatible external vocabulary | One delivery-ranking algorithm | A family of compatible service products |
| What triggers the choice? | Composition combines one purpose with one channel | A provider workflow owns `makeParser()` | The composition root selects a vendor boundary | A caller selects one ranking policy | A tenant or environment selects one complete family |
| Does behavior transition itself? | No | No | No | No | No |
| How many variation axes matter? | Two independently changing axes | One workflow axis with a creator-owned product choice | One external boundary per integration | One algorithm family | Multiple related product axes that must stay compatible |
| Current or planned app example | Notification purpose x delivery channel | Bank statement provider x parser | AtlasPay or BorealPay authorization | Delivery-option ranking | Planned tenant service families |
| Prefer direct Swift when... | The matrix is small and both axes change together | Preparation and parsing are closed and centralized | One SDK has a local mapping | A small enum or closure keeps policies clear | Products can be constructed independently without invalid combinations |

The decisive distinction is the ownership of change. Bridge keeps two app-owned
dimensions independently replaceable. Factory Method keeps one shared import
operation while each provider workflow chooses the parser it creates. Adapter
translates an external contract, Strategy replaces one algorithm, and Abstract
Factory is only justified when several products must be selected as a coherent
family.

## Bridge review

`NotificationBridge` composes one purpose composer with one asynchronous channel
delivery value. Purpose types own semantic labels and content; channel types own
subjects, sounds, sender IDs, opt-out copy, and the dispatch boundary. The
12-case product matrix is therefore represented by composition rather than a
type for every purpose-channel pair.

The protocol boundaries are justified by three purpose implementations, four
channel implementations, and the injected async transport seam used by tests.
There is no provider registry, mutable notification context, factory hierarchy,
or retry layer hidden in the example. The composition-root switch is a closed
selection helper, not a second pattern.

Bridge is not Strategy because neither axis is one interchangeable algorithm.
It is not Adapter because the channel implementations are app-owned policies,
not translations of incompatible vendor APIs. Decorator and Proxy remain
possible additions around a stable delivery value for concerns such as metrics,
caching, or access control, but they are outside this scenario.

## Factory Method review

`BankStatementImportWorkflow` owns the shared import operation and its stable
normalized result. Northstar, Mercado Sur, and Lumen workflows each prepare
their provider envelope and choose a parser in `makeParser()`. This keeps the
provider-specific preparation and parser pairing together while preserving one
app-owned import contract.

The provider switch in `importBankStatement(_:)` is composition code. It does
not make this a Simple Factory: the relevant creation decision happens inside
each concrete workflow, after the workflow's preparation step. It is not
Abstract Factory because each provider creates one parser product rather than a
coherent family of related products. It is not Template Method because no
inheritance skeleton is required; the creators are small value types with a
shared protocol extension for the common operation.

No parser registry, runtime discovery, dependency container, or generic import
repository is justified. A fourth provider that only adds a format would still
be better served by a direct switch or Simple Factory; the creator boundary is
earned only while provider workflow preparation and parser construction evolve
together.

## Visual and documentation review

Both final headers are 1672 x 941. Compared with the approved Adapter
reference, they preserve the upper-left type hierarchy, upper-right original RG
logo, charcoal/white/red/orange palette, central technical scene, and restrained
industrial detail. Bridge uses independent notification rails; Factory Method
uses controlled bank-feed preparation and parser selection. The metaphors differ
without introducing a second visual system.

The canonical READMEs contain descriptive alt text, one-sentence captions,
domain-named Mermaid diagrams, accessible descriptions, executable commands,
tests, trade-offs, alternatives, `When not to use it`, and links to concrete
source and test files. Bridge uses a sequence diagram because the asynchronous
handoff matters; Factory Method uses a creation flow because creator and parser
ownership matters.

## Complexity decision

The review found no production-code changes to make. The useful abstractions are
exactly the two-axis Bridge composition and the creator-owned Factory Method.
Keeping selection at the composition root and retaining immutable domain values
avoids registries, inheritance, mutable contexts, service locators, and
class-per-combination designs. The historical direct baselines remain available
through the earlier commits and pressure documents, so the canonical source does
not need comparative dead code.

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
- The complete Swift Testing run passed 31 tests across 18 suites.
- SwiftLint reported 0 violations across 20 files under `Sources` and `Tests`.
- Every non-template local Markdown link resolves. The teaching template was
  checked separately because its placeholders are intentionally not paths.
- Each canonical README contains exactly one Mermaid block. Structural review
  confirmed that Bridge names the current purpose/channel types and async
  dispatch path, while Factory Method names the current workflows, parser
  contract, preparation step, and normalized result.
- Both headers pass the five-part visual comparison and the required 1672 x 941
  dimensions.
- `git diff --check` passed, and `Editorial/` remains ignored.

## Readiness decision

Bridge and Factory Method are complete and correctly classified. The repository
is ready for Internal Day 022: define the Abstract Factory problem with two
coherent service families. This review does not introduce or pre-approve that
pattern, and it does not start the next day.
