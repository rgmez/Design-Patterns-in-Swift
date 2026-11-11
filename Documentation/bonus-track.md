# Bonus Track: Harden the Examples

Start date: 2026-11-11

The first 100 days produced a complete, executable catalogue. This bonus track
does not reopen all 23 examples or add new patterns. It addresses the concrete
teaching risks found during the final usefulness review:

- historical examples can still be mistaken for the canonical implementation;
- eight canonical examples are useful only while their narrow boundary remains
  explicit; and
- a few trade-offs are documented but could be demonstrated more directly with
  executable comparisons or measurements.

## Operating rule

Every bonus change must improve a reader's decision, not merely add detail.

A change is accepted only when it identifies the current ambiguity, preserves
the smallest direct Swift baseline, adds observable evidence, and names the
condition that would reverse the conclusion. Documentation alone is enough when
the problem is navigation or interpretation. Code is required only when a test
or measurement can resolve a real uncertainty.

Work on one stage at a time. A stage is complete only after its relevant tests,
links, documentation, and complete diff have been reviewed.

## Release relationship

The bonus track started before a v1.0 tag or release was approved. The Day 099
release candidate remains the validated baseline, but it no longer describes
the final repository `HEAD`. Release approval is paused until Bonus 010 reruns
the repository-wide gates and refreshes the candidate evidence. The track does
not authorize a tag, release, pull request, or publication.

## Scope

The track contains ten independently reviewable stages:

| Stage | Focus | Evidence required before completion |
| --- | --- | --- |
| Bonus 001 | Historical isolation | Every superseded document and Swift file points to the canonical guide and cannot be mistaken for package-backed evidence. |
| Bonus 002 | Factory Method | Make the creation-closure alternative executable and prove whether provider-owned workflow creation still earns the pattern. |
| Bonus 003 | Singleton | Reduce the shared lookup to the narrowest visibility the runtime callback permits and verify ordinary clients remain injected. |
| Bonus 004 | Flyweight | Separate deterministic retained-payload evidence from allocator, framework-cache, and process-RSS claims. |
| Bonus 005 | Interpreter | Make the handoff boundary to maintained parser infrastructure executable without expanding the current grammar. |
| Bonus 006 | Mediator | Prove that local section rules remain outside the coordination boundary and define the signal for a god-object split. |
| Bonus 007 | Memento | Quantify snapshot growth under the bounded history and document when deltas or a persistence model should replace full snapshots. |
| Bonus 008 | Template Method | Implement the higher-order-function alternative beside the current pressure and compare which API best protects the invariant order. |
| Bonus 009 | Visitor | Demonstrate the cheap operation-extension direction and the deliberate cost of adding an element kind. |
| Bonus 010 | Final review | Re-run the suite, links, diagrams, and example-quality checklist; retain only improvements supported by evidence. |

The outcome of a stage may be to keep the current implementation. A bonus stage
fails if it invents a new requirement merely to make the named pattern look
stronger.

## Bonus 001 decision

The historical files remain valuable as evidence of the repository's starting
point, but they are not runnable catalogue entries. Moving or deleting them
would erase useful review context and create unnecessary link churn. Leaving
them unlabelled lets a reader encounter a misclassified example before its
tested replacement.

Bonus 001 therefore keeps the files in place and adds three safeguards:

1. one [historical example map](historical-examples.md) states what each old
   example actually demonstrates;
2. every historical Markdown document links to its canonical replacement; and
3. every historical Swift file declares that it is excluded from the package
   and points readers to the package-backed source.

No runtime code, test behavior, canonical guide, or visual changes in this
stage.
