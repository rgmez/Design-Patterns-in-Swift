# 🔎 Mediator Responsibility Review

<a id="mediator-responsibility-review"></a>

Review date: 2026-11-11

Bonus 006 verifies that `DeliveryCheckoutMediator` owns interaction order, not the business rules of its participants, and defines when that coordination boundary should be split.

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [Reading guide](../README.md#reading-guide)

## Current ownership

The mediator installs three routes and owns one corrective sequence:

1. address changes refresh delivery;
2. delivery changes reconcile promotion before committing payment state; and
3. promotion may request a delivery correction through the mediator.

It does not decide which zones a slot supports, which payment methods a slot accepts, whether a promotion code exists, or which slots are eligible for that offer.

## Executable evidence

`MediatorTests.ParticipantOwnedRules` constructs every domain participant without a mediator:

- `CheckoutDeliveryModule` filters slots by zone and rejects an unavailable selection;
- `CheckoutPaymentModule` rejects unavailable methods and clears a selection invalidated by the new slot; and
- `CheckoutPromotionModule` evaluates eligibility and requests an eligible slot through its callback.

Those tests complement the integration suites. A failing standalone participant test points to a local domain rule. A passing participant test plus a failing checkout snapshot points to coordination order.

## God-object boundary

Do not split the mediator because it reaches an arbitrary line count. Split or replace responsibilities when one of these observable signals appears:

| Signal | Required response |
| --- | --- |
| The mediator starts filtering zones, validating payment methods, evaluating offer codes, or calculating discounts. | Move the rule back to its participant or a focused domain value. |
| Two independent interaction clusters no longer share an ordering invariant. | Give each cluster its own mediator or direct composition root. |
| Networking, persistence, payment authorization, analytics, or navigation enters the coordination method. | Put the side effect behind a separate application boundary; keep form coordination synchronous and local. |
| Coordination crosses tasks or must survive suspension. | Replace the boolean reentry guard with an explicit isolation and transaction model; do not treat this synchronous mediator as concurrency control. |
| Most participants become passive data bags while the mediator decides their behavior. | Restore participant ownership or return to one cohesive value-semantic form. |

The current example triggers none of these signals. It has four independently testable participants, zero domain-rule branches in the mediator, no external side effects, and one synchronous ordering invariant.

## Decision and reversal

**Use Mediator** while delivery and promotion can correct one another and payment must observe their final selection. The mediator earns its place by owning this order, not by owning every checkout rule.

Return to direct callbacks when the reverse interaction disappears. Return to one value-semantic form when a single owner controls all four fields. Introduce a different application or concurrency boundary if external effects or suspension become real requirements.

## Verification

```sh
swift test -Xswiftc -warnings-as-errors --filter "MediatorTests/ParticipantOwnedRules"
swift test -Xswiftc -warnings-as-errors --filter Mediator
```
