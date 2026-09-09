# Observer Problem: Propagating Authenticated-Session Changes

Problem-definition date: 2026-09-09

This document defines Day 032 of the Observer cycle. It fixes the real session
change, the direct Swift implementation, the acceptance criteria, and the
initial visual thesis before any subscription mechanism is introduced.

## Product scenario

A commerce app owns one current authenticated session. When a customer signs in
or out, four existing parts of the app must react to the confirmed change:

- the account header switches between the guest state and the customer's name;
- the cart changes between guest and account ownership;
- account synchronization starts for the signed-in user or stops on logout;
- analytics records one event for each actual transition.

The authentication request itself, token storage, cart merging, network sync,
screen navigation, and analytics transport are outside this teaching unit. The
example begins after authentication has produced a confirmed `UserSession`.

## Requirements and invariants

The direct implementation in
[`SessionChangeDirect.swift`](../Sources/DesignPatterns/Observer/SessionChangeDirect.swift)
must:

1. Keep the confirmed session as the source of truth.
2. Deliver each actual sign-in to the four currently known consumers.
3. Return those consumers to their signed-out state after logout.
4. Avoid duplicate side effects when the same session snapshot arrives twice.
5. Complete delivery synchronously so tests observe one deterministic result.
6. Use concrete collaborators without a subscription protocol, notification
   center, stream, or custom event framework.

The four consumers deliberately expose different domain outcomes. Treating
them as one generic callback shape would hide their real responsibilities and
would introduce abstraction before variation exists.

## Direct Swift first

`SessionController.transition(to:)` owns one exhaustive switch and invokes the
four known collaborators explicitly. Sign-in passes only the values each
consumer needs; sign-out resets or cancels their corresponding work.

This arrangement is intentionally coupled, but it is also local and easy to
read. All consumers live for as long as the controller, delivery is synchronous,
and the set of reactions is fixed. Under those constraints, an Observer would
replace four obvious calls with registration, lifetime, and cancellation rules
that the product does not yet need.

No protocol is required: there is no external boundary, test seam, or immediate
variation in any consumer. The acceptance tests inspect the concrete state
changes rather than mock whether methods were invoked.

## Acceptance tests

[`ObserverProblemTests.swift`](../Tests/DesignPatternsTests/ObserverProblemTests.swift)
uses Swift Testing to verify that:

- a sign-in updates account UI, cart ownership, sync scheduling, and analytics;
- a logout returns all four consumers to their signed-out outcomes;
- repeating the same session records no second transition event, proving the
  direct fan-out was skipped.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter ObserverProblemTests
```

These tests prove the baseline only. They do not simulate subscription
lifetimes, cancellation, slow consumers, reentrancy, or cross-actor delivery.

## Evidence required on Day 033

Observer has not earned a place merely because four values change after login.
Day 033 must add a credible consumer whose lifetime is shorter than the session
owner, then show the concrete coupling or failure caused by direct callbacks.

The pressure review must make the following questions observable:

- Which source edits are required every time a consumer is added or removed?
- Can a screen stop receiving changes when it disappears without leaking it?
- Does one consumer's work delay or prevent delivery to the others?
- Are duplicate delivery, cancellation, and ordering semantics explicit?

If a view can read the session directly through Swift Observation, or one local
closure remains clearer, the broader Observer mechanism should still be
rejected. If independent event delivery is justified, Day 034 should prefer a
standard `AsyncStream` boundary over a custom notification framework.

## Initial visual thesis

**Thesis:** One confirmed session change feeds four clear app reactions; the
direct wiring is honest while every receiver has the same lifetime.

**Scene:** A dark authentication latch on the left changes from guest to a
single warm-red account token. Four exposed copper traces leave the latch and
feed an account nameplate, a cart ownership clasp, a sync rotor, and an event
counter across the central rail. The wiring is tidy and readable, but every
trace is physically terminated inside the session unit, foreshadowing the cost
of adding receivers with different lifetimes.

Day 034 must keep this signal-distribution metaphor if the measured pressure
justifies Observer. The final editorial header should show the session source
and independently attached receivers; its Mermaid should explain delivery and
cancellation precisely rather than repeat the illustration.

## Day 032 decision

Session propagation is real and executable, but Observer has not earned a
subscription boundary. Four direct calls remain the smallest complete design
while the consumer set and lifetime are fixed.
