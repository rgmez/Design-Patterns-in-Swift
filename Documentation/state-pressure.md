# State Pressure: One Backup, Competing Truths

Pressure-review date: 2026-09-13

Internal Day 037 adds two consumers that must act on the encrypted-backup
lifecycle: the screen chooses one primary button, while a background worker
chooses the next automatic operation. The direct phase enum from Day 036 still
protects the transition function, but a persisted flag snapshot introduced for
those consumers can describe states that the lifecycle itself forbids.

## The requirement that changed

The app must restore enough status after process termination for two independent
surfaces:

- the backup screen offers Start, Pause, Resume, or Retry;
- the background worker prepares, encrypts, or uploads without consulting UI.

The first direct integration models that codable record with six booleans in
[`BackupUploadFlagSnapshot`](../Sources/DesignPatterns/State/BackupUploadPressure.swift).
Each consumer then interprets those flags in its own ordered branch chain.
There is deliberately no protocol, state object, context, delegate, command
queue, or side-effect framework on this pressure day.

## The impossible-state budget

Six independent booleans encode 64 combinations. Only seven shapes correspond
to this lifecycle: all flags false for Ready, or exactly one flag for each of
Preparing, Encrypting, Uploading, Paused, Failed, and Completed. The remaining
57 combinations are structurally representable even though the product cannot
explain them.

The problem is not merely an unattractive data model. A snapshot with both
`isUploading` and `isPaused` produces two observable decisions:

```swift
let snapshot = BackupUploadFlagSnapshot(
    isUploading: true,
    isPaused: true
)

backupUploadPrimaryAction(for: snapshot)       // .resume
backupUploadBackgroundOperation(for: snapshot) // .upload
```

The UI prioritizes Paused and tells the user that transfer is suspended. The
worker prioritizes Uploading and keeps transferring bytes. Reordering either
branch only chooses which interpretation wins; it does not make the snapshot
valid.

A second contradiction, `needsRetry && isCompleted`, makes one record terminal
and recoverable at the same time. The UI happens to hide its button because
Completed is checked first, but another consumer can reverse the priority and
reach a different answer.

## Repeated phase branching

The direct example now has three owners of phase knowledge:

1. `transitionBackupUpload(from:on:)` decides legal lifecycle transitions.
2. `backupUploadPrimaryAction(for:)` decides the screen action.
3. `backupUploadBackgroundOperation(for:)` decides automatic work.

The first branch is exhaustive over `BackupUploadPhase`; the other two branch
over a weaker parallel representation. Adding a phase-specific rule now means
finding every decision site and keeping its precedence aligned. The duplication
is behavior ownership, not duplicated syntax: UI and worker legitimately return
different result types, but both need one authoritative answer to “what state
is this backup in?”

## Executable evidence

[`StatePressureTests.swift`](../Tests/DesignPatternsTests/StatePressureTests.swift)
keeps each fixture isolated and verifies:

- coherent lifecycle snapshots produce the intended UI and worker decisions;
- Uploading plus Paused makes the UI offer Resume while work continues;
- Completed plus Retry remains representable despite violating terminal-state
  semantics.

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter StatePressureTests
```

## Smaller alternatives still in contention

Encoding `BackupUploadPhase` directly would remove impossible flag combinations
without introducing State. Computed properties or free functions over that enum
could also keep the two new decisions type-safe. This remains the preferred
answer while all phase-dependent behavior stays cohesive and closed.

A transition table would centralize event pairs, but would not naturally own
the different UI and worker result types. Strategy would inject one
interchangeable decision policy; it would not model a backup whose accepted
events and behavior change after each transition.

Day 038 compared those smaller options with State. The pattern earned private
types because putting transitions, UI actions, and worker behavior beside each
concrete state removed the parallel flag model and narrowed the change
boundary. The [canonical guide](../Behavioral%20Patterns/State/README.md)
documents why the context remains a value type and why the only all-phase
switch now belongs to typed persistence restoration.

## Day 037 decision

Independent booleans are rejected as the lifecycle authority because they admit
57 impossible combinations and let consumers disagree through branch order.
The safe Day 036 enum remains the current source of truth. State is now a
credible candidate, but Day 038 still has to prove that it improves on enum
methods rather than merely distributing the existing switch.

## Day 038 resolution

[`BackupUpload`](../Sources/DesignPatterns/State/BackupUpload.swift) owns one
private state existential. Its seven private implementations keep accepted
events, primary screen action, and background operation together. `Codable`
persists the typed `BackupUploadPhase`, so invalid flag combinations never enter
the canonical model. The original enum reducer remains documented as the
smaller choice when transitions are the only varying behavior.
