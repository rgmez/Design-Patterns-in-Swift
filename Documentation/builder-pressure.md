# Builder Pressure: Ordered Support Upload Assembly

Pressure-review date: 2026-09-03

This document records Day 026 of the Builder cycle. It extends the direct
privacy-aware support upload with a real multi-screen construction flow and
measures the resulting order and validation pressure before introducing
Builder.

## The requirement that changed

The support request is no longer assembled only after one form submit. The app
collects it across several screens: the customer writes the message, grants
category-specific consent immediately before selecting private material, adds
attachments, reviews the measured payload, and explicitly finalizes the
request.

The product requires four construction invariants:

1. The message opens the sequence and can occur only once.
2. Consent for a category must occur before its first attachment.
3. The byte limit is checked after each accepted payload, not only after the
   customer leaves the review screen.
4. Finalization occurs exactly once and no later step may mutate the sealed
   request.

These are construction rules. Transport, upload retries, persistence, raw-log
redaction, and media transcoding remain outside the example.

## Direct Swift extension retained

The Day 026 solution models UI events as a closed
`SupportUploadAssemblyStep` enum and passes the complete sequence into the
request initializer:

```swift
let request = try SupportUploadRequest(
    ticketID: ticketID,
    steps: [
        .message(message),
        .grantConsent(for: .diagnostics),
        .diagnostics(redactedDiagnostics),
        .finalize
    ],
    maximumPayloadSizeInBytes: uploadLimit
)
```

An exhaustive `switch` processes those values in order. It tracks accepted
parts, granted consent categories, and finalization state while checking the
payload after every append. There is still no builder type, builder protocol,
director, fluent API, reference-backed accumulator, or staged generic graph.

The solution is executable and keeps the final request immutable. It is also
honest about its weakness: `[SupportUploadAssemblyStep]` can express sequences
the product forbids, and the initializer signature cannot teach a caller which
sequence is valid.

## Measured pressure

The direct API now exposes six step cases. Four distinct invalid order families
remain representable and require runtime errors:

- consent or an attachment before the message;
- a second message;
- any step after finalization;
- a sequence with no finalization.

The processing switch also owns three category-specific consent branches plus
three pieces of mutable bookkeeping: accepted parts, consented categories, and
whether the request is finalized. Adding a new attachment category requires a
new step case, consent mapping, multipart mapping, size validation, and tests in
the same central processor.

The problem is not that the initializer has many parameters. It is that its raw
step collection accepts four invalid order families and leaks the construction
state machine to every caller. Correct sequences rely on documentation and
runtime rejection instead of an API that guides the normal path.

## Executable evidence

[`BuilderProblemTests.swift`](../Tests/DesignPatternsTests/BuilderProblemTests.swift)
now verifies:

- a finalized message-only request;
- deterministic part order for a full consented sequence;
- all three category-specific consent failures;
- four parameterized invalid construction orders;
- blank-message and invalid-limit rejection;
- exact-limit acceptance;
- immediate oversize rejection before finalization.

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter BuilderProblemTests
```

## Smaller alternatives considered

A larger memberwise initializer or more default arguments cannot represent
events that arrive over time. A helper function would only move the same raw
step array and validation switch. A separate `SupportUploadDraft` value would
already be a stateful construction object under a less explicit name.

A staged generic builder could make every invalid order unrepresentable, but it
would multiply types for a small teaching example and make optional attachments
awkward. Day 027 should prefer one concrete value builder whose initializer
requires the message, whose attachment methods validate consent and size, and
whose `build()` operation is the only way to produce `SupportUploadRequest`.
Runtime validation should remain for privacy and byte-limit rules that types do
not usefully encode.

## What still does not justify Builder

If all upload values arrive atomically, the Day 025 throwing initializer is
still simpler. A builder is not justified by optional parameters, readable
default arguments, or the desire for chained syntax. It earns its place here
only because construction now spans ordered interactions and intermediate
validation has observable product behavior.

## Day 026 decision

The direct step enum proves the new workflow without prematurely adding a
pattern, but it makes four invalid order families public and centralizes every
intermediate rule. Builder has now earned consideration for Day 027. The next
day may replace the raw sequence with one concrete value builder; it must not
add a protocol, director, dependency container, or staged-type hierarchy unless
new evidence requires one.
