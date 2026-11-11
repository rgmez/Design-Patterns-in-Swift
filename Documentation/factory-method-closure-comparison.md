# Factory Method Closure Comparison

Review date: 2026-11-11

This Bonus 002 review tests the nearest Swift alternative to the canonical bank
import Factory Method: one value configured with a payload-preparation closure
and a parser-creation closure.

The question is not whether Swift can replace a factory method with a closure.
It can. The question is which owner should keep provider preparation paired with
the parser created for that prepared representation.

## Direct baseline

The original exhaustive switch remains the smallest solution while the provider
set is closed. Each case prepares its payload and parses it immediately. No
protocol or closure bundle improves one short, stable selection point.

A creation closure becomes plausible when callers need to inject parser
creation. Parser creation alone does not remove the central preparation switch,
so the executable comparison uses two closures:

```swift
ClosureConfiguredWorkflow(
    provider: .northstar,
    preparePayload: northstarPreparation,
    makeParser: northstarParserCreation
)
```

This shape can reproduce the canonical workflow through one reusable
configuration value. A production closure design would still need to own the
provider-specific preparation and parser behavior somewhere.

## Executable evidence

`FactoryMethodProblemTests.CreationClosureAlternative` proves both sides of the
comparison:

1. correctly paired Northstar closures produce exactly the same
   `BankStatementImport` as the canonical creator workflow; and
2. the same configuration surface can pair Northstar preparation with the
   Mercado Sur parser, producing a runtime `unsupportedPayload` failure.

The test deliberately reuses the canonical provider operations as closure
bodies. That isolates who owns their pairing; it is not a line-count comparison
and does not claim that the provider behavior disappears in a closure design.

The second test does not claim that a concrete creator cannot be implemented
incorrectly. It shows that a closure-configured call site must own and preserve
two related decisions. The module-supplied concrete creators make that pairing
part of one named provider workflow, so ordinary call sites select one workflow
instead of assembling its parts.

## Decision

**Use Factory Method.** The current pressure is not parser selection by itself.
Each provider owns preparation plus creation inside one shared import workflow.
The factory method keeps those responsibilities together and leaves normalized
result construction in the shared operation.

| Option | Prefer it when | Why it loses or wins here |
| --- | --- | --- |
| Exhaustive switch | Providers are closed and preparation remains short. | Still the best baseline; it loses only when provider workflows need independent ownership. |
| Parser-creation closure | Only parser construction varies at one local call site. | Does not own provider preparation. |
| Preparation plus creation closures | Dynamic injection is required and the composition root should configure both behaviors. | Reproduces the result through one configurator, but still needs provider behavior and exposes its pairing to the caller. |
| Factory Method creator | A provider owns preparation and the product it creates inside a shared workflow. | Wins for the documented requirement by giving the pair one named owner. |

## Cost and reversal condition

Factory Method retains one protocol, three creator values, a parser contract,
and one composition-root switch. Swift closures would be smaller if the two
decisions became local configuration rather than provider-owned behavior.

Replace the creators with the direct switch or a closure when preparation
disappears, every provider uses the same preparation, the provider set is
permanently closed, or clients genuinely need to construct workflows from
independent behaviors. Do not add another creator merely because another file
format exists.

## Verification

```sh
swift test -Xswiftc -warnings-as-errors --filter "FactoryMethodProblemTests/CreationClosureAlternative"
swift test -Xswiftc -warnings-as-errors --filter "Factory Method"
```

The first command runs the nearest-alternative comparison. The second preserves
the complete creator, workflow, input-boundary, and value-semantics evidence.
