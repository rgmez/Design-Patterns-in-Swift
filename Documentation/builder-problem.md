# Builder Problem: Privacy-Aware Support Upload

Problem-definition date: 2026-09-02

This document defines Day 025 of the Builder cycle. It fixes the real support
upload problem, keeps the first solution direct, and records acceptance tests
and a visual thesis before any Builder type or stepwise construction API is
introduced.

## Product scenario

An app lets a customer open a support ticket after checkout fails. The customer
must provide a message and may attach redacted diagnostics, screenshots, and one
screen recording. Each attachment category has separate consent, and the upload
must stay below the support API's configured payload limit.

The example stops at an app-owned multipart request. HTTP boundaries, retry,
authentication, compression, persistence, and the support vendor SDK are outside
this teaching unit because they do not help decide whether Builder belongs in
the construction flow.

## Requirements and invariants

The direct implementation in
[`SupportUploadRequest.swift`](../Sources/DesignPatterns/Builder/SupportUploadRequest.swift)
must:

1. Require a non-blank support message.
2. Accept diagnostics only as `RedactedSupportDiagnostics`; raw logs are not a
   representable input to this boundary.
3. Require independent consent for diagnostics, screenshots, and recording.
4. Preserve screenshot order while assembling message, diagnostics, screenshots,
   and recording into deterministic multipart order.
5. Reject the completed request when its measured payload exceeds the configured
   byte limit, while accepting an exact-boundary payload.
6. Keep inputs and the final request as immutable, `Sendable` values.

The reported size covers part payloads, not transport headers or multipart
boundary bytes. A production encoder must add its own framing overhead before
enforcing a wire-level limit.

## Direct Swift first

All data is available when the customer taps Submit, so one throwing value
initializer remains the clearest construction API:

```swift
let request = try SupportUploadRequest(
    ticketID: ticketID,
    message: message,
    diagnostics: redactedDiagnostics,
    screenshots: selectedScreenshots,
    screenRecording: recording,
    consent: consent,
    maximumPayloadSizeInBytes: uploadLimit
)
```

The initializer validates the whole value once, then uses ordinary conditional
appends to create the ordered parts. Default arguments keep message-only tickets
small. There is no builder protocol, director, reference-backed accumulator,
fluent API, or partially valid request type. Those additions would duplicate a
construction flow that currently fits in one place and completes atomically.

Specific input types carry useful privacy meaning without adding abstraction:
the initializer can accept redacted diagnostics, but it has no raw-diagnostics
overload that a caller might choose accidentally.

## Acceptance tests

[`BuilderProblemTests.swift`](../Tests/DesignPatternsTests/BuilderProblemTests.swift)
uses Swift Testing to verify:

- a message-only request has one text part;
- consented optional inputs produce deterministic multipart ordering;
- each attachment category fails independently without its consent;
- a blank message and a non-positive configured limit are rejected;
- the exact payload limit succeeds and an oversized request reports both sizes.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter BuilderProblemTests
```

## Evidence required on Day 026

Builder has not earned a place merely because this initializer has several
parameters. Day 026 must add a credible product constraint where construction
actually spans ordered steps—for example, diagnostics must be redacted before
they can be attached, recording finalization changes the size budget, or a final
manifest can only be produced after every accepted attachment is known.

The pressure review must identify which invalid intermediate states or repeated
validation branches the direct initializer permits or hides. If a smaller
validated value, an enum, a helper function, or default arguments keep the flow
atomic and readable, the Builder pattern should still be rejected.

## Initial visual thesis

**Thesis:** One support upload is assembled from consent-gated parts, but it is
valid only after privacy and size checks close the package.

**Scene:** A dark horizontal assembly rail carries a message card through three
optional gated bays: redacted diagnostics, screenshots, and recording. Each bay
has a precise warm-red consent latch. The accepted parts converge into one
sealed multipart package on a scale at the right; rejected parts stop at their
gate. The rail expresses conditional construction, while the final scale makes
whole-request validation the single focal point.

Day 027 may turn this scene into the final Builder header under the shared
[`visual-style.md`](visual-style.md) contract. Until then, no editorial header is
needed.

## Day 025 decision

The support upload has conditional assembly and meaningful privacy rules, but
all required values still arrive together. A throwing initializer plus immutable
values is the least complex correct solution. Builder remains deliberately
absent until Day 026 produces verified step-order or intermediate-validation
pressure.
