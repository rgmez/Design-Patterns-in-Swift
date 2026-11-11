# 100-Day Retrospective

Retrospective date: 2026-11-11

This document closes Internal Day 100 and the first version of the pragmatic
Swift patterns programme. The goal was never to maximize pattern usage. It was
to make every added boundary answer one question: what concrete app pressure
does this structure own better than direct Swift?

## What the programme delivered

The release candidate now contains one complete, executable teaching system:

- all 23 Gang of Four patterns use realistic app domains rather than generic
  products, creators, or managers;
- one Swift Package compiles 64 source files and exercises the examples with
  350 tests in 188 Swift Testing suites across 59 test files;
- every pattern has one canonical guide, one RG editorial header, one
  domain-specific Mermaid diagram, explicit trade-offs, and a `When not to use
  it` decision;
- one three-day control case concludes that a pure function and
  `URLComponents` remain better than Builder;
- the `choose-swift-design-pattern` skill reuses the catalogue's evidence gate
  without turning the catalogue into a recommendation quota; and
- 106 focused commits preserve the progression from the first roadmap to the
  qualified v1.0 release candidate and this retrospective.

The numbers establish coverage and reproducibility. The more important result
is that each guide also records the losing alternative and the evidence that
would reverse its decision.

## What became simpler

### One decision sequence replaced pattern-first teaching

Every pattern followed the same sequence:

1. model one real app requirement with the smallest direct Swift solution;
2. introduce one credible product or integration change;
3. observe coupling, invalid states, repeated ownership, lifecycle risk, or a
   measurable resource cost;
4. add the smallest boundary that moves that pressure to a clearer owner; and
5. record the new cost and the point at which the direct solution still wins.

This sequence made pattern choice reviewable without forcing the
implementations into one shape. A value type, closure, enum, actor,
`AsyncSequence`, protocol, or class can express the same responsibility
boundary when its domain requires it.

### One package boundary replaced target-per-pattern ceremony

The examples compile in one library target and run in one test target. Their
domains remain independent through folders and names, not through dozens of
package products or a framework above the catalogue. This keeps full-suite
validation cheap and makes accidental dependencies visible without inventing
module boundaries that the examples do not need.

### Documentation owns the common structure

Consistency belongs in the canonical README contract, visual system, quality
gates, and roadmap. Runtime code stays specific to its app problem. That split
made the catalogue navigable while preserving the different reasons that
Adapter, State, Flyweight, or Memento exist.

## What was rejected

The programme deliberately did not add:

- a shared `Pattern` protocol, registry, taxonomy runtime, or universal
  participant hierarchy;
- a dependency-injection container, coordinator layer, repository layer, or
  use-case layer shared by unrelated examples;
- one Swift type for every participant box in a textbook diagram;
- a named pattern when an enum, function, initializer, value type, actor, or
  platform API already owned the behavior;
- a public post for every internal day;
- a diagram generator or a second visual system; or
- an automatic tag, release, pull request, or LinkedIn publication.

These omissions are not unfinished infrastructure. They are scope boundaries
that keep the catalogue about decisions instead of ceremony.

Several historical examples also needed conceptual correction rather than a
cosmetic rewrite. A centralized switch was not promoted as Factory Method; one
concrete family did not justify Abstract Factory; one varying algorithm did not
demonstrate Bridge; and value assignment was considered before Prototype. The
replacement examples were retained only after tests and documentation made
their distinct change pressure observable.

## What was learned

### Ownership separates neighbouring patterns

Similar diagrams are a weak decision tool. The more reliable questions are:

- Who selects the behavior: the caller, event history, or an independent axis?
- Does every wrapper participate, does one substitute guard access, or does a
  chain stop after one handler takes responsibility?
- Is creation varying one product inside a workflow, one coherent family, or
  the ordered construction of one value?
- Is an external vocabulary being translated, a subsystem being simplified,
  or peer state being coordinated?

Those questions separated Strategy/State/Bridge,
Decorator/Proxy/Chain of Responsibility,
Factory Method/Abstract Factory/Builder, and Adapter/Facade/Mediator more
reliably than participant names.

### The pattern verdict and the Swift representation are different decisions

Choosing State does not automatically require one protocol and one concrete
type per state. Choosing Strategy does not require a class hierarchy. The
pattern identifies where behavior belongs; the implementation chooses the
smallest Swift representation that preserves that ownership and its tests.

This distinction also improved the pattern-selection skill. Its forward tests
could choose the right responsibility boundary without prescribing types that
the prompt did not ask for.

### A no-pattern result is necessary evidence

The product-share URL case remained one immutable request and one pure
`URLComponents` function after localization was added. It gained neither
ordered stages nor reusable partial construction state. Keeping it direct
proved that the programme's gate could reject a plausible pattern even after
three days of investigation.

A catalogue in which every example ends with a pattern cannot validate its own
selection rule.

### Visual and editorial consistency should not leak into runtime design

The shared header composition, palette, captions, accessible diagram
descriptions, and README structure make the series coherent. The Swift
examples do not need a common runtime abstraction to achieve that coherence.

## Remaining limitations

- Mermaid blocks passed repository-wide structural checks, but renderer-level
  validation is still unavailable because Mermaid CLI is not installed.
- The examples are learning-sized app slices. Their tests prove the documented
  responsibilities and trade-offs, not production readiness for a specific
  backend, persistence system, or UI lifecycle.
- The initial skill evaluation uses a deliberately small scenario set. Its six
  passing forward tests support the current workflow but do not establish
  universal pattern-selection accuracy.
- Historical examples remain beside the canonical guides when they still
  provide context. Readers should use the root index and each canonical
  `README.md` as the source of truth.

## Recommendation for the next iteration

Do not begin a second catalogue by choosing more pattern names.

Collect real Swift app problems first, preserve their direct solutions, and
accept a new teaching unit only when one of these investigations produces
observable pressure:

1. **Concurrency ownership:** actor reentrancy, cancellation, or task lifetime
   creates behavior that direct structured concurrency does not keep clear.
2. **Apple-platform state flow:** Observation, `AsyncSequence`, navigation, or
   restoration responsibilities become duplicated across genuine consumers.
3. **Composition roots:** dependency assembly across app, extension, preview,
   and test entry points develops a measurable consistency or lifetime risk.
4. **Persistence and synchronization:** offline work, conflict resolution, or
   event history demands an explicit boundary beyond a value model and one
   storage client.

These are candidate problem areas, not pre-approved patterns. Each should pass
the same direct-baseline, evidence, neighbour, cost, and reversal checks before
the roadmap names a solution.

## Final readiness decision

Internal Day 100 is complete when this retrospective, the final roadmap state,
the root index, and the private Public Day 028 draft have been validated
together. The v1.0 candidate is then ready for explicit human approval.

No tag, GitHub release, pull request, or LinkedIn publication is authorized by
this retrospective. The next action is review: approve the exact release
operation separately, or open a new evidence-led roadmap for one of the
candidate problem areas.
