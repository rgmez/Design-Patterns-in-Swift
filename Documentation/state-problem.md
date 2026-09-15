# State Problem: Resumable Encrypted Backup Uploads

Problem-definition date: 2026-09-13

This document defines Internal Day 036. It fixes the backup lifecycle, its
legal and illegal transitions, the direct Swift baseline, acceptance evidence,
and the initial visual thesis before the State pattern is considered.

## Product scenario

A secure backup app prepares local files, encrypts them, uploads the encrypted
payload, and stores the remote backup identifier. Mobile connectivity can
disappear during transfer, so the user must be able to pause, resume, and retry
without restarting bytes that were already accepted.

The example begins after the user has selected the backup contents. File I/O,
cryptography, network transport, persistence, background execution, and UI are
outside this teaching unit. The behavior under review is the lifecycle contract
that coordinates those boundaries.

## Lifecycle and invariants

The direct implementation represents these phases:

| Phase | Data owned by the phase | Accepted next events |
| --- | --- | --- |
| Ready | None | Start |
| Preparing | None | Preparation finished or failure |
| Encrypting | None | Encryption finished or failure |
| Uploading | Uploaded and total bytes | Progress, pause, failure, or finish |
| Paused | Preserved upload progress | Resume |
| Failed | Failure and recovery point | Retry |
| Completed | Remote backup identifier | None |

The transition function must preserve these invariants:

1. Preparation happens before encryption, and encryption before upload.
2. Upload progress stays between zero and the encrypted payload size.
3. Reported progress never moves backwards.
4. Pause and retry preserve the last accepted upload checkpoint.
5. Completion requires every byte and a non-blank remote backup identifier.
6. Completed uploads are terminal.
7. Unsupported event-and-phase pairs fail explicitly without changing state.

## Direct Swift first

[`BackupUploadDirect.swift`](../Sources/DesignPatterns/State/BackupUploadDirect.swift)
uses value types, one phase enum, one event enum, and the pure
`transitionBackupUpload(from:on:)` entry point. Its exhaustive phase switch
routes to private phase-local functions that list every legal event and send
every other pair to one explicit `invalidTransition` error.

This is deliberately not the State pattern. There are no state classes,
protocols, context object, mutable controller, delegates, side-effect handlers,
or transition table. The phase value carries only the checkpoint data that is
valid for that phase, and the caller owns any I/O around the pure reducer.

At this size, the switch is a feature: the complete lifecycle fits in one place
and can be reviewed without dynamic dispatch. Replacing it with seven types
would distribute a still-small rule set before independent state behavior has
been demonstrated.

## Explicit invalid transitions

The baseline rejects concrete product mistakes rather than treating unexpected
events as no-ops. Examples include pausing before work starts, resuming while
preparing, completing during encryption, restarting a completed backup,
finishing a partial upload, and reporting fewer uploaded bytes than the last
checkpoint.

These failures matter because a silent no-op could leave UI, persistence, and
background work disagreeing about what happened. The caller receives a domain
error and the original phase remains unchanged because the reducer has no
mutable state.

## Acceptance tests

[`StateProblemTests.swift`](../Tests/DesignPatternsTests/StateProblemTests.swift)
uses Swift Testing to verify:

- the complete preparation-to-completion path;
- pause and resume preserving upload progress;
- retry after a connection failure preserving the recovery checkpoint;
- four invalid lifecycle jumps through one parameterized test;
- rejection of incomplete completion and a blank remote identifier;
- rejection of regressed, negative, oversized, or zero-total progress.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter StateProblemTests
```

## Evidence verified on Days 037–038

State did not earn a protocol merely because the app has seven phases. Day 037
introduced a credible requirement that made state-specific behavior and
transition ownership harder to maintain around the direct reducer. The
[pressure review](state-pressure.md) records the executable evidence, and the
[canonical guide](../Behavioral%20Patterns/State/README.md) documents the
smallest accepted State boundary.

The pressure review answers:

- Which new command or side effect repeats phase checks outside the reducer?
- Can flag-based UI or persistence projections represent contradictory states?
- Does adding one phase require editing unrelated transition branches?
- Can an enum and pure function still keep the lifecycle clearer than dynamic
  state objects?

The direct reducer remains the preferred alternative when transitions are the
only varying behavior. Day 038 introduced private State types only after screen
actions, worker operations, and persistence proved that their phase knowledge
changed together.

## Initial visual thesis

**Thesis:** One encrypted backup moves through one legal corridor; each stage
unlocks only the commands that are safe there.

**Scene:** A dark industrial transfer rail runs left to right through preparation,
encryption, upload, pause, recovery, and completion gates. One warm-red encrypted
payload advances along the rail while mechanical interlocks block invalid jumps.
The upload and recovery chambers share one visible checkpoint marker, making
resume-without-restart understandable without labels.

The final Day 038 header keeps this gated-lifecycle metaphor. Its Mermaid
explains state transitions and rejected commands precisely rather than
repeating the editorial scene.

## Day 036 decision

The lifecycle is real and executable, but the State pattern has not earned its
types. One enum and pure transition function remain the smallest design while
all rules fit coherently in one exhaustive switch.
