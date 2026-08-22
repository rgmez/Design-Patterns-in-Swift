# Strategy Problem: Delivery Promise Ranking

Problem-definition date: 2026-08-20

This document defines Day 011 of the Strategy cycle. It fixes the checkout
problem, the direct Swift implementation, the acceptance criteria, and the
visual thesis before any Strategy boundary is introduced.

## Product scenario

A commerce app receives several fulfillment options for the current basket.
Checkout must present the same options in a different order according to a user
setting or an active product experiment:

- Lowest cost puts the smallest delivery fee first.
- Earliest arrival puts the shortest estimate first.
- Lowest carbon puts the smallest emissions estimate first.

The selection is available at runtime before the screen renders. It changes
only ordering: eligibility, labels, checkout selection, and booking stay outside
this example.

## App-owned values

`DeliveryOption` contains the normalized values needed by all three rankings:

| Value | Meaning |
| --- | --- |
| `id` | Stable fulfillment-option identity used as a deterministic tie-breaker. |
| `feeInMinorUnits` | Delivery fee without floating-point currency conversion. |
| `estimatedArrivalDays` | Whole-day estimate already normalized by fulfillment. |
| `carbonGrams` | Whole-gram emissions estimate supplied by fulfillment. |

The ranking operation does not validate or enrich these values. Its input is a
normalized fulfillment response, and its output is a reordered copy. A future
need for network data or basket-specific scoring is pressure to assess, not a
reason to add dependencies today.

## Direct Swift first

The smallest complete solution is `DeliverySortPreference`, an enum with three
cases, and the pure `rankDeliveryOptions(_:by:)` function. The function uses one
exhaustive `switch` to select the integer key and sorts ascending. Equal primary
values use `DeliveryOption.id` so repeated ranking cannot produce an ambiguous
order.

There is no protocol, existential, class hierarchy, type erasure, factory, or
mutable ranking object. The policy set is closed, all policies consume the same
data, and the compiler shows every supported choice in one place. This direct
implementation is the preferred design until a concrete requirement makes that
central switch costly.

## Acceptance criteria

The Day 011 implementation and Swift Testing suite prove:

1. Lowest-cost ranking orders options by `feeInMinorUnits`.
2. Earliest-arrival ranking orders the same options by
   `estimatedArrivalDays`.
3. Lowest-carbon ranking orders the same options by `carbonGrams`.
4. A runtime preference can select any ranking without changing the option
   values or rebuilding the input.
5. Equal primary values are ordered deterministically by stable option identity.
6. Ranking returns a reordered value and does not mutate the fulfillment
   response.

## Evidence required on Day 012

Day 012 introduced one credible product requirement that cannot be reduced
to another local integer key without making the central conditional own
independent policy dependencies or release cadence. Candidate pressure includes
a partner-funded score that needs basket context or an experiment policy
delivered independently from the three built-in choices.

The implemented evidence is recorded in the [Strategy pressure review](strategy-pressure.md).

That day must identify the actual edits, setup, and tests forced into this
function. If an added enum case or injected comparison closure remains clearer,
Strategy must not be introduced.

## Initial visual thesis

**Thesis:** One set of delivery promises; checkout can route it through the
ranking lane that matches the current intent.

**Scene:** Three dark fulfillment rails receive the same compact set of delivery
tokens from the left. A precise red selector routes them through cost, arrival,
or carbon ordering and recombines them as one ranked line on the right. The
selector is the focal point; the rails express alternative behavior, not state
transitions or two-dimensional product combinations.

Day 013 will generate and compose the final header only after the Strategy
implementation and its wording are verified. Until then, this thesis is the
reviewable visual specification; it is not a claim that the pattern has earned
its place.

## Day 011 decision

Runtime ranking is concrete and executable, but Strategy has not earned any
additional structure. The enum and pure function remain the correct solution at
the end of this day.
