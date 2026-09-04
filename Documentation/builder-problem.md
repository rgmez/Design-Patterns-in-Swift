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

The Day 025 direct implementation established that the support upload must:

1. Require a non-blank support message.
2. Accept diagnostics only as `RedactedSupportDiagnostics`; raw logs are not a
   representable input to this boundary.
3. Require independent consent for diagnostics, screenshots, and recording.
4. Preserve screenshot order while assembling message, diagnostics, screenshots,
   and recording into deterministic multipart order.
5. Reject the completed request when its measured payload exceeds the configured
   byte limit, while accepting an exact-boundary payload.
6. Keep inputs and the final request as immutable, `Sendable` values.

Day 026 preserves these rules and adds ordered, intermediate construction. The
current implementation lives in
[`SupportUploadRequest.swift`](../Sources/DesignPatterns/Builder/SupportUploadRequest.swift),
and the added evidence is documented in the
[Builder pressure review](builder-pressure.md).

The reported size covers part payloads, not transport headers or multipart
boundary bytes. A production encoder must add its own framing overhead before
enforcing a wire-level limit.

## Day 025 direct Swift baseline

When all data was available at Submit time, one throwing value initializer was
the clearest construction API:

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

That baseline validated the whole value once, then used ordinary conditional
appends to create the ordered parts. Default arguments kept message-only tickets
small. Day 026 replaces this API with a direct enum of UI construction steps so
the new ordered workflow can be measured before choosing a pattern.

Specific input types carry useful privacy meaning without adding abstraction:
the initializer can accept redacted diagnostics, but it has no raw-diagnostics
overload that a caller might choose accidentally.

## Day 025 acceptance baseline

The initial Swift Testing suite verified:

- a message-only request has one text part;
- consented optional inputs produce deterministic multipart ordering;
- each attachment category fails independently without its consent;
- a blank message and a non-positive configured limit are rejected;
- the exact payload limit succeeds and an oversized request reports both sizes.

The Day 025 and Day 026 suites established this baseline before the raw step API
was removed. The current
[`BuilderTests.swift`](../Tests/DesignPatternsTests/BuilderTests.swift) preserves
the product invariants against the final construction boundary. Run it with:

```sh
swift test -Xswiftc -warnings-as-errors --filter BuilderTests
```

## Day 026 resolution

The support flow now spans ordered UI interactions: message, consent, attachment
selection, intermediate byte-limit checks, and explicit finalization. The
direct step enum proves the behavior, but admits four invalid order families
and makes the initializer interpret a public construction state machine. The
[pressure review](builder-pressure.md) records the measurements and the narrow
boundary proposed for Day 027.

## Initial visual thesis

**Thesis:** One support upload is assembled from consent-gated parts, but it is
valid only after privacy and size checks close the package.

**Scene:** A dark horizontal assembly rail carries a message card through three
optional gated bays: redacted diagnostics, screenshots, and recording. Each bay
has a precise warm-red consent latch. The accepted parts converge into one
sealed multipart package on a scale at the right; rejected parts stop at their
gate. The rail expresses conditional construction, while the final scale makes
whole-request validation the single focal point.

Day 027 turns this thesis into the final
[`builder-header.png`](Assets/Patterns/creational/builder-header.png) under the
shared [`visual-style.md`](visual-style.md) contract. The scene keeps the three
consent gates, left-to-right part assembly, and one sealed request on a payload
gauge.

## Day 025 decision

The support upload had conditional assembly and meaningful privacy rules, but
all required values still arrived together. A throwing initializer plus
immutable values was the least complex correct solution. Day 026 then added
verified step-order and intermediate-validation pressure. Day 027 resolves it
with the one concrete value builder documented in the
[canonical Builder guide](../Creational%20Patterns/Builder/README.md).
