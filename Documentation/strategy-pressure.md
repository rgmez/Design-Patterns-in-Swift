# Strategy Pressure: A Partner-Sponsored Delivery Policy

Pressure-review date: 2026-08-21

Day 012 keeps the direct ranking function and adds the first requirement that
puts independent policy knowledge inside it. Strategy is still not introduced;
this document records the evidence that the next day must evaluate.

## The requirement that changed

A commerce team sells sponsored placement for a delivery partner. During a
campaign, checkout must rank eligible fulfillment options by the partner score
returned with the campaign configuration. The score is not a delivery
attribute, can change without a new fulfillment response, and is not available
for every option.

The ranking contract now has to support both the original operational
preferences and a campaign preference:

- Lowest cost, earliest arrival, and lowest carbon remain ascending rankings.
- Partner-sponsored ranks the highest campaign score first.
- An option with no campaign score receives `0` and stays deterministic by
  stable option identity when scores tie.
- Campaign updates must change ordering without changing checkout code or the
  fulfillment response.

## Direct Swift extension

`DeliveryRankingContext` carries the campaign's app-owned score map. The direct
implementation remains one pure `rankDeliveryOptions` function and one
exhaustive `switch` over `DeliverySortPreference`:

1. Existing callers without campaign data use an empty context.
2. The new case reads scores by `DeliveryOption.id` and sorts descending.
3. The same identity tie-breaker keeps output stable for equal or missing
   scores.

This is still honest Swift for a small, closed set of policies. The API is
explicit about the extra input, and no protocol, class, closure registry, or
runtime discovery mechanism is needed yet.

## Observable pressure

The new behavior exposes costs that did not exist on Day 011:

1. `rankDeliveryOptions` now owns two independent policy shapes: local integer
   attributes and an externally supplied campaign dictionary.
2. The central `switch` must know that partner scores sort in the opposite
   direction and must define the missing-score fallback.
3. A campaign release can change the score source and its fallback semantics
   without changing delivery data, but the ranking function still changes when
   the policy's input contract changes.
4. Tests need a second fixture dimension: the same fulfillment options must be
   ranked against multiple campaign snapshots to prove the policy can vary.

The pressure is therefore independent policy variation with independent data
and release cadence, not merely a fourth enum case. Day 013 must determine
whether a minimal Strategy boundary reduces this coupling. It should reject the
pattern if an injected comparison closure or a small enum extension remains
clearer.

## What still does not justify Strategy

The example does not justify a protocol for every sort operation. All policies
still operate synchronously on the same value array, the policy set is known at
compile time, and the campaign map is a small app-owned value. A protocol would
be premature if the next requirement is only another local field or another
enum case.

## Verification

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter StrategyTests
```

The current suite retains the campaign evidence and demonstrates that two
snapshots change ordering without mutating fulfillment values or the ranker.

## Day 012 decision

The direct implementation remains the current solution, but it now carries a
credible pressure point: independently changing campaign policy data is
entering a central conditional. Day 013 may introduce only the minimum Strategy
structure if it removes a measurable cost from that boundary.

## Day 013 resolution

The [canonical Strategy guide](../Behavioral%20Patterns/Strategy/README.md)
records the verified replacement. `DeliveryRankingStrategy` now owns the score
function, direction, and immutable campaign snapshot, while the ranker owns only
sorting. This removes the preference switch and generic context without adding
a protocol or one concrete type per policy.
