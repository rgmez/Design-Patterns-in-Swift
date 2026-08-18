# Adapter Problem: Payment SDK Boundary

Problem-definition date: 2026-08-18

This document defines Day 008 of the Adapter cycle. It fixes the app problem, the first vendor boundary, the smallest direct Swift solution, and the acceptance criteria before any pattern structure is introduced.

## Product scenario

A commerce app must authorize a card payment before placing an order. Checkout owns domain data and needs one domain outcome: an authorization that can be attached to the order, or a payment failure that it can present or retry appropriately.

The first release uses a fictional third-party SDK named `AtlasPaySDK`. Its API cannot be changed and its types must be treated like imported vendor types rather than app-owned models.

The scope is intentionally narrow:

- Authorize one payment for one checkout attempt.
- Use the order identifier as the vendor idempotency reference.
- Preserve integer minor units so amount conversion cannot lose precision.
- Map the SDK's terminal approval or failure into an app-owned result.
- Do not model capture, refunds, saved cards, authentication challenges, or provider selection.

## App-owned contract

Checkout begins with these domain values:

| Type | Data | Meaning |
| --- | --- | --- |
| `PaymentRequest` | `orderID`, `amountInMinorUnits`, `currency`, `paymentToken` | The payment checkout wants to authorize. |
| `PaymentAuthorization` | `paymentID`, `orderID` | Proof that the order may proceed. |
| `PaymentError` | `declined`, `temporarilyUnavailable`, `invalidRequest` | The failures checkout understands and can act on. |

`currency` is an app-owned ISO 4217 code. `amountInMinorUnits` must be greater than zero, and `paymentToken` must not be empty. Those are domain preconditions rather than AtlasPay rules.

## Incompatible AtlasPay boundary

The SDK exposes a concrete asynchronous client and vendor-specific models:

| AtlasPay type | Relevant API | Incompatibility |
| --- | --- | --- |
| `AtlasPayClient` | `submit(_:) async throws -> AtlasChargeResult` | Checkout would depend on a concrete vendor client. |
| `AtlasChargeRequest` | `merchantReference`, `minorAmount`, `currencyCode`, `sourceToken` | Labels and ownership differ from `PaymentRequest`. |
| `AtlasChargeResult` | `chargeID`, `status` | Approval is encoded as a vendor status rather than a domain authorization. |
| `AtlasChargeStatus` | `approved`, `rejected(reasonCode:)` | Rejection reasons use vendor codes checkout does not understand. |
| `AtlasPayError` | `invalidSource`, `transportFailure`, `serviceUnavailable` | The error taxonomy does not match `PaymentError`. |

The SDK contract is asynchronous, but the incompatibility is semantic rather than syntactic: request fields, result states, and failures all use AtlasPay's vocabulary.

## Direct Swift first

With one provider used in one place, the clearest implementation is a concrete `CheckoutPaymentService` that stores `AtlasPayClient`. Its `authorize(_:)` method performs three local steps:

1. Validate the app-owned request before calling the SDK.
2. Construct `AtlasChargeRequest` directly from `PaymentRequest` and await `submit(_:)`.
3. Switch over the AtlasPay result and errors at the same call site to return `PaymentAuthorization` or throw `PaymentError`.

The direct implementation needs no app payment protocol, adapter, provider enum, factory, type erasure, or shared vendor abstraction. A small private mapping function is acceptable if it improves readability, but it remains owned by the concrete checkout service.

This solution is preferable while AtlasPay is the only stable integration because every transformation is visible in one place and there is no demonstrated variation to abstract.

## Acceptance criteria

The direct implementation added on Day 009 must make these behaviors executable through Swift Testing:

1. A valid `PaymentRequest` sends exactly one Atlas request with the order ID, minor-unit amount, currency code, and payment token mapped without loss or substitution.
2. An approved Atlas charge returns `PaymentAuthorization` with the vendor charge ID and the original order ID.
3. An Atlas rejection returns `PaymentError.declined` without exposing its vendor reason code to checkout.
4. Atlas transport and service-availability failures return `PaymentError.temporarilyUnavailable`.
5. An invalid amount or empty token returns `PaymentError.invalidRequest` and does not call the SDK.
6. Tests observe requests and domain outcomes; they do not assert `print` output, timing, or private mapping helpers.

The test double may stand in for the external client boundary required to run deterministic tests. It must not become a general-purpose payment abstraction before the second-provider pressure is demonstrated.

## Evidence required on Day 009

Day 009 will implement this direct solution first. It will then introduce the concrete requirement for a second provider and record exactly where provider request types, result states, errors, and test setup force checkout to branch or change.

Adapter is justified only if that evidence shows vendor concepts escaping the integration boundary or repeated mapping that a single boundary can own. If a local function still contains the incompatibility clearly, the pattern must be rejected.

## Initial visual thesis

**Thesis:** One checkout contract; incompatible SDK connections stay outside the app's payment flow.

**Scene:** A single app-owned payment connector enters a precise conversion module. The opposite side exposes a visibly incompatible industrial connector representing the vendor SDK. The flow runs left to right, with the conversion boundary as the only focal point.

The approved `Documentation/Assets/Brand/adapter-header-reference.png` already demonstrates this composition. Day 010 will verify the final header against the visual contract rather than generating a competing asset during problem definition.

## Day 008 decision

The problem and direct solution are sufficiently concrete to implement. No Adapter has earned its place yet. Day 009 must first prove the pressure created by the second provider.
