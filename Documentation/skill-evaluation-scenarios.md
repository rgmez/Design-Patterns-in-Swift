# Independent Skill Evaluation Scenarios

Design date: 2026-11-04

This document closes Internal Day 093 by defining the first realistic decision
scenarios for the future `choose-swift-design-pattern` skill. The scenarios are
not implementation exercises and do not extend the catalogue. They test whether
the skill can apply the [evidence gate](skill-decision-signals.md) to unfamiliar
app domains without copying the repository's payment, backup, notification, or
product-sharing examples.

The prompts are intentionally separated from their evaluation criteria. A
forward-test agent should receive one prompt and the skill under test, but not
the expected verdict, rubric, catalogue source, or another scenario's result.
The evaluator should score observable reasoning rather than exact headings or
wording.

## Shared response contract

Every scenario asks for one reviewable decision. A satisfactory response must:

1. identify current, observable app pressure rather than speculative growth;
2. state the direct Swift design that should be tried or retained;
3. give one verdict: a named pattern, no pattern yet, or insufficient evidence;
4. explain which responsibility moves and what complexity the decision adds;
5. reject the closest alternative with one discriminating reason; and
6. name the concrete requirement that would reverse the verdict.

The response must not return a menu of patterns when the supplied facts are
sufficient. It may ask for one missing fact only when that fact would materially
change the decision.

## Scenario A — Carrier SDK boundary

### Prompt for the skill

> An iOS retail app currently requests delivery quotes from the Northstar
> carrier SDK. Northstar takes a callback-based request containing grams and
> postal codes, returns its own status object, and reports vendor error codes.
> The team is adding the Meridian SDK, which uses async/await, decimal kilograms,
> a different address model, and thrown errors. Checkout must continue to work
> only with the app's `DeliveryQuote`, `ShipmentID`, and domain errors; no carrier
> types may escape the integration module. The current checkout view model
> switches on the selected carrier and maps both SDKs itself, so provider rules
> and error translations are already duplicated in its tests. Recommend the
> smallest Swift design that addresses the current pressure. Include the direct
> baseline, one verdict, the responsibility boundary, the closest alternative,
> and the evidence that would reverse your decision.

### Expected decision evidence

- **Verdict:** Adapter.
- **Pressure:** two external providers disagree on requests, units, results,
  errors, and asynchronous contracts while the app requires one stable domain
  vocabulary.
- **Direct baseline:** one provider call with local result and error mapping was
  sufficient before the second incompatible provider arrived.
- **Moved responsibility:** each provider boundary translates between its SDK
  and one app-owned operation; checkout no longer branches on vendors or imports
  their types.
- **Verification:** the same checkout behavior accepts either provider, vendor
  errors become domain errors, invalid app input does not invoke an SDK, and no
  SDK type crosses the boundary.
- **Closest alternative:** Facade loses because the problem is incompatible
  vocabulary and contracts, not a simpler entry point to a subsystem the app
  already understands. Mediator loses because no peers react to each other over
  time.
- **Reversal signal:** return to a direct call and local mapping if there is one
  simple, stable provider and the app can intentionally understand its API.

A response fails this scenario if it adds a provider registry, factory, use-case
layer, or generic networking abstraction without evidence that those owners are
needed.

## Scenario B — Offline map lifecycle

### Prompt for the skill

> An offline-map download starts with a single `Phase` enum. The feature now
> supports pause, resume, cancellation, background network loss, retry from a
> saved checkpoint, package verification, and a low-storage failure. The screen,
> background worker, and retry policy each switch on the phase separately.
> Recent changes allowed `resume` during verification and showed a retry action
> after a terminal cancellation because the three switches disagreed. Callers
> send events such as `start`, `pause`, `networkLost`, `downloadFinished`, and
> `verificationFailed`; callers do not choose a behavior implementation. Decide
> the smallest Swift design that should own valid transitions, available UI
> actions, and the worker's next operation. Include the direct baseline, one
> verdict, the responsibility boundary, the closest alternative, and the
> evidence that would reverse your decision.

### Expected decision evidence

- **Verdict:** State.
- **Pressure:** valid transitions, available actions, and worker behavior change
  together according to event history, and duplicated switches now permit
  contradictory decisions.
- **Direct baseline:** one closed enum plus a pure reducer remains the first
  choice while transitions and derived behavior stay local and reviewable.
- **Moved responsibility:** the download context delegates each event and
  phase-specific behavior to one owner for the current phase; transitions cannot
  be selected arbitrarily by a caller.
- **Verification:** legal event sequences reach the expected phases, illegal
  events leave state unchanged, UI actions and worker decisions agree, and a
  retry preserves the checkpoint.
- **Closest alternative:** Strategy loses because no caller selects a policy;
  lifecycle history selects the behavior. Builder loses because an existing
  download changes behavior rather than constructing a value that does not yet
  exist.
- **Reversal signal:** retain or return to the enum reducer if all transitions,
  actions, and effects can again live in one small exhaustive switch without
  duplicated phase knowledge.

A response fails this scenario if it treats each event as a Command, exposes
phase mutation to callers, or creates public state classes that leak lifecycle
mechanics outside the feature.

## Scenario C — Campaign invite URL

### Prompt for the skill

> A share sheet creates a campaign invite URL from an immutable input containing
> an invite code, locale, optional referral code, and optional campaign source.
> Every value is available at the call site at the same time. A throwing
> initializer validates the code and locale, and one pure function uses
> `URLComponents` to produce the URL. Product has asked for one more optional
> query item. The team proposes a fluent Builder so future parameters can be
> chained. There are no screens that collect partial data, no required ordering,
> no reusable draft, and no asynchronous approval step. Should the feature adopt
> a design pattern now? Provide the direct design, one verdict, the cost of the
> proposed alternative, and the concrete evidence that would reverse the
> decision.

### Expected decision evidence

- **Verdict:** no pattern yet.
- **Pressure assessment:** another optional value does not create construction
  stages, invalid transitions, shared state, or a second change axis.
- **Direct design:** keep one validated immutable input and a stateless function
  backed by `URLComponents`.
- **Avoided complexity:** a Builder would introduce mutable partial lifetime,
  ordering questions, a finalization method, and more invalid intermediate
  states without protecting a product invariant.
- **Closest alternative:** Builder becomes relevant only for observable staged
  construction; a larger initializer or fluent syntax is not sufficient.
- **Verification:** equivalent inputs produce equivalent URLs, optional query
  items are encoded correctly, invalid inputs fail before URL generation, and
  calls cannot leak state into one another.
- **Reversal signal:** reconsider Builder when data arrives across ordered
  screens or asynchronous approvals, intermediate transitions require
  validation, and the final immutable request must not exist before sealing.

A response fails this scenario if it recommends Builder for readability,
future-proofing, or argument count alone, or if it offers several patterns
instead of an explicit no-pattern verdict.

## Scenario D — Document export axes

### Prompt for the skill

> A design-review app exports the same document for three intents: a lightweight
> review copy, a color-managed print proof, and a signed archival package. The
> content team owns what each intent includes. A platform team independently
> supports three destinations: a local file, a shared workspace, and a print
> vendor API; each destination owns authorization, transport metadata, and
> delivery errors. Any intent must work with any destination selected at runtime.
> New intents and destinations ship on separate roadmaps, and the current design
> has started producing one type and branch set per intent-destination pair. The
> team is split between Strategy and Bridge. Decide which design, if either, fits
> the demonstrated pressure. Include the direct baseline, one verdict, the two
> ownership boundaries, why the neighboring pattern loses, and the evidence that
> would reverse your decision.

### Expected decision evidence

- **Verdict:** Bridge.
- **Pressure:** export intent and delivery destination are independent change
  axes that combine at runtime; pair-specific types create Cartesian growth.
- **Direct baseline:** two enums and focused switches are sufficient while both
  axes are small, closed, and changed together.
- **Moved responsibility:** the export abstraction owns intent-specific content,
  while the delivery implementation owns destination-specific transport. They
  compose without either axis knowing every case in the other.
- **Verification:** all intent-destination combinations work, adding a new
  destination changes no intent implementation, adding an intent changes no
  destination, and destination failures remain transport-domain errors.
- **Closest alternative:** Strategy models one caller-selected policy over one
  operation. It becomes the better fit if only the export algorithm varies and
  destination is stable data rather than an independently evolving behavior
  family.
- **Reversal signal:** keep or return to enums, functions, or one Strategy when
  one axis is closed or stops changing independently.

A response fails this scenario if it describes Bridge only as two protocols,
keeps pair-specific concrete exports, or recommends Strategy without accounting
for the second independently owned axis.

## Forward-test protocol for Day 097

These scenarios are specifications, not successful test results. Day 097 should
run each prompt in a fresh context against the then-current skill and store raw
outputs outside the versioned documentation tree. The evaluating agent may
receive this document only after producing its answer.

Score each response against the shared contract and its scenario criteria. Do
not require exact type names, a fixed number of types, or catalogue wording.
Record unsupported abstractions, invented requirements, missing reversal
signals, and incorrect neighbor distinctions. A scenario passes only when the
verdict and the reasoning boundary are both correct; naming the expected pattern
by accident is insufficient.

## Scope boundary and next step

No production source, test, pattern README, or visual changes in this design
day. The scenarios reuse only the catalogue's verified decision boundaries and
deliberately change domains so later validation can reveal overfitting.

Internal Day 094 will initialize `.codex/skills/choose-swift-design-pattern`
with the official skill tooling. It has not started here, and these evaluation
scenarios must not be copied into the skill's instructions or references.
