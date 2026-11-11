# Memento Storage Review

Review date: 2026-11-11

Bonus 007 quantifies both dimensions of full-snapshot growth: draft content and
history depth. The measurement keeps Memento's representation boundary honest
without introducing an unearned delta log.

## Executable growth model

`MementoTests.OpaqueExternalHistory` now proves:

1. encoded bytes grow monotonically between drafts containing 0, 50, and 250
   stops; and
2. four same-length title edits over the same 250-stop itinerary retain exactly
   four times the bytes of one checkpoint.

The second case changes only the title. It demonstrates that Memento captures
complete state regardless of edit size. This is the expected pattern behavior,
not an implementation accident.

The existing representative fixture records 8,774 encoded bytes for one
250-stop snapshot and 35,096 bytes for four checkpoints on the current
Swift/macOS runner. Exact JSON byte counts are fixture evidence, not a stable
wire-format promise. The durable invariants are monotonic content growth,
linear depth growth for equal-size snapshots, and the configured history bound.

## Why full snapshots still win

The current product needs at most four checkpoints. A complete snapshot keeps:

- restoration atomic;
- compatibility validation with the originator;
- checkpoint ordering independent from edit semantics; and
- failure behavior free from partial replay or compaction.

Memento was introduced because external history must not know the editor's
private schema. It was not introduced as a storage optimization.

## Delta or operation-log threshold

Evaluate reversible operations, deltas, or an operation log only when measured
product data shows all of these pressures:

- typical drafts are large enough that full checkpoints breach a defined
  memory or storage budget;
- history depth must increase materially beyond the current bound;
- most edits touch a small fraction of the complete state; and
- the team can own replay ordering, compaction, versioning, and partial-failure
  recovery.

If checkpoints must survive process death, app upgrades, synchronization, or
sharing, use an explicit versioned persistence/document boundary instead. An
opaque runtime memento should not disguise durable user data.

## Decision and reversal

**Use Memento** for bounded, scene-owned restore points that outlive one editor
instance while keeping its schema private. Full snapshots remain the simpler
and safer representation at the measured scale.

Reverse the representation—not necessarily the ownership boundary—when the
quantified thresholds above become true. The caretaker may still own opaque
history even if the originator later produces deltas internally.

## Verification

```sh
swift test -Xswiftc -warnings-as-errors --filter MementoTests
swift test -Xswiftc -warnings-as-errors --filter Memento
```
