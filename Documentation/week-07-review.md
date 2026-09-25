# Facade and Decorator Review

Review date: 2026-09-25

This review closes Internal Day 049 by checking checkout compensation ownership,
upload policy composition, error propagation, and the simpler alternatives.

## Responsibility matrix

| Question | Facade | Decorator |
| --- | --- | --- |
| What changes? | Three clients stop duplicating one subsystem workflow | Five deployment profiles select independently optional upload policies |
| Public boundary | One checkout placement operation | The same upload operation at every layer |
| Mutation owner | The facade owns inventory, payment, order, and analytics values | Each wrapper owns its policy and wrapped value |
| Failure owner | The facade releases inventory after payment decline and rethrows | Retry handles connection loss; other failures propagate through the stack |
| Simpler default | A direct sequence for one client | A direct upload client for one fixed policy |

## Facade findings

`CheckoutFacade` reserves inventory before authorizing payment, creates an order
only after both succeed, and records one terminal outcome. Inventory failure
stops payment. Payment decline releases the reservation before the original
error escapes. Subsystems remain independently usable, while private setters
prevent clients from replacing the facade's coordinated state.

No production change is justified for this narrow synchronous operation. The
canonical Mermaid previously drew compensation directly from payments to
inventory; it now routes the failure through the facade, which owns cleanup.

The example is an in-memory collaboration, not a distributed transaction.
Checkout identifiers must identify distinct placement attempts: the subsystem
does not implement duplicate-request protection or durable compensation. Copies
of the facade own independent state. The entry-point parameterized test exercises
the same facade operation under three labels; it is not UI integration coverage
for three implemented screens.

## Decorator findings and correction

The production composition places metrics outside authentication and retry, so
one logical upload produces one terminal event. Moving metrics inside retry
produces attempt-level events. HTTP rejection and malformed success must escape
unchanged, without another send. The transport owns actual send counts; the
retry wrapper owns the decision to forward again.

Review found those last two responsibilities were accidentally coupled:
`RetryingMediaUpload` compared its limit with `MediaUploadCall.attemptCount`.
A conforming client that throws `transportUnavailable` before a transport send
does not increment that count. The wrapper could therefore forward forever.

The correction uses one local remaining-retry counter per invocation. It adds
no type or abstraction and leaves send counts available for metrics. A bounded
test client throws a different terminal error if forwarding exceeds the allowed
budget, so the regression test fails deterministically on the old behavior
instead of hanging. Additional tests prove fresh budgets and metric counts on
successive uploads and terminal malformed-success propagation.

The Mermaid return path now passes through every wrapper instead of jumping
directly from the API to the app. The guide explains the independent budget.

Metrics intentionally support the example's typed operational failures. This
is not a universal error logger for arbitrary external conformers. Nested retry
wrappers can multiply forwarding budgets; production composes exactly one.

## Test and documentation hygiene

Strict SwiftLint found two overly nested scenario types in the problem suites.
Both moved up to their outer suite namespace without changing their cases or
disabling the rule.

The canonical guides retain requirements, direct baselines, pressure evidence,
participants, execution commands, tests, trade-offs, alternatives, and explicit
`When not to use it` guidance. Facade and Decorator remain different intents:
coordinating distinct subsystems does not require a shared wrapper interface;
stacking upload behavior does not justify a universal subsystem facade.

The existing 1672 × 941 headers were visually compared with the approved Adapter
reference: upper-left hierarchy, upper-right RG mark, charcoal/warm palette, and
industrial detail remain recognizable as one collection. Logo framing differs
slightly across the existing images; this review does not regenerate assets.
The technical diagrams, rather than the editorial scenes, define exact ownership
and execution order. Captions and accessible descriptions remain present.

## Validation

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict --no-cache Sources Tests
git diff --check
git check-ignore -v Editorial/
```

- Full Swift build succeeds; 153 tests across 78 suites pass.
- Compiler warnings are treated as errors.
- SwiftLint strict mode: zero violations across 59 files.
- Concrete local Markdown file links resolve, excluding README template
  placeholders. External URLs and heading anchors are outside this check.
- Both changed Mermaid blocks have checked delimiters, declared endpoints,
  domain names, and manually reviewed ownership. Mermaid CLI is unavailable;
  no renderer/parser validation is claimed.
- The initial sandboxed test command could not write Swift caches. Build and
  tests passed after approved execution with cache access.
- CodeGraph is not initialized; the review used the guides' explicit source
  paths. No index was created without an answer to the initialization question.
- `Editorial/` remains ignored and outside the commit.

## Readiness decision

Day 049 is complete with a focused retry fix, regression coverage, lint fixes,
and corrected diagrams. There is no need for a middleware engine, type erasure,
subsystem protocols, or a larger commerce facade.

Day 050 will define the direct Proxy problem; it has not started. Day 049 is not
a publication milestone, so no LinkedIn draft is created or changed.
