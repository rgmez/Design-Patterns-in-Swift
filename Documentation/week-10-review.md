# Composite and Mediator Review

Review date: 2026-10-13

This review closes Internal Day 070 by checking recursive traversal, value and
reference ownership, corrective interaction order, participant responsibility,
and the simpler Swift alternatives.

## Responsibility matrix

| Question | Composite | Mediator |
| --- | --- | --- |
| What changes? | Three clients stop repeating the file-or-folder walk | Four independent checkout modules stop coordinating through a callback cycle |
| Public boundary | One component operation yields located files from either a leaf or container | One checkout interaction owner wires participant events and exposes their coherent snapshot |
| State owner | Value components own children; each traversal derives fresh contextual paths | Participants own domain state; the mediator owns only interaction order and reentry suppression |
| Completion rule | Preserve depth-first child order and visit every descendant exactly once | Resolve promotion's final delivery choice before validating payment once |
| Simpler default | An indirect enum or recursive function for a closed tree with few consumers | One value-semantic form or one-way callbacks while one owner remains clear |

## Composite findings

`WorkspaceFolder.fileLocations` asks each child for its locations, prefixes a
new path value, and flattens results in child order. Offline preview, search,
and cleanup consume the same structural result but retain their separate
download, indexing, and local-storage policies. Opening remains a concrete
`WorkspaceFile` operation rather than a meaningless component requirement.

The new ownership regression places the same `Briefing` subtree under two
different visit folders. Each root produces its own complete paths while the
shared subtree still reports paths rooted at `Briefing`. This proves that
traversal derives contextual values instead of installing parent links or
mutating reusable children.

The example deliberately trusts an app-owned acyclic value tree and eagerly
materializes locations. Cycle detection, parent references, mutation APIs, and
a lazy traversal abstraction would add requirements the in-memory workspace
does not have. A remotely paginated or very large hierarchy should use a
`Sequence` or `AsyncSequence` rather than extending this component operation.

## Mediator findings

`DeliveryCheckoutMediator` routes three participant callbacks through one
bounded synchronous operation. Promotion may request a corrected delivery
window; nested delivery notification is suppressed, promotion is refreshed
with the corrected choice, and payment sees only that final window. Address,
delivery, promotion, and payment validation remain in their existing modules.

The new responsibility regression applies a valid promotion to an incompatible
express selection and verifies that neither delivery nor payment changes. The
promotion reports its local ineligibility until the customer explicitly opts
into an eligible window. The mediator therefore coordinates declared events;
it does not infer extra business actions or become the owner of promotion
policy.

The mediator strongly owns its modules, while their installed closures capture
it weakly; the existing release test still proves the callback graph does not
retain the checkout. The callbacks remain publicly replaceable for teaching
visibility, so the composition root must own their installation. Hiding them
behind delegate setters or adding a colleague protocol would harden an API that
has no external consumer in this example.

## Classification and avoided complexity

Composite and Mediator both remove repeated knowledge from clients, but their
boundaries are unrelated. Composite owns a part-whole traversal shared by peer
components. Mediator owns the order of interactions among independent stateful
participants. Neither pattern should absorb the feature policies that consume
its result.

Composite is not Decorator: a folder aggregates siblings instead of wrapping
one component to add behavior. Its eager walk is also not Iterator, because all
three current clients consume the complete small hierarchy. Mediator is not
Observer: its callbacks participate in one ordered invariant rather than
broadcasting independent notifications. It is not Facade either, because the
important events originate inside participants rather than only at one client
entry point.

No production types changed in this review. Parent pointers, a generic tree
fold, a visitor, event bus, async transaction layer, colleague protocol, and
god coordinator remain unjustified.

## Documentation and visual review

Both canonical guides retain the app problem, direct baseline, measured
pressure, participants, Swift walkthrough, execution commands, tests,
trade-offs, alternatives, and explicit `When not to use it` guidance. Their
source and test links resolve, and each Mermaid diagram uses domain names with
an explanatory paragraph and accessible equivalent.

The existing 1672 × 941 headers were compared with the approved Adapter
reference. Both retain the upper-left hierarchy, upper-right original RG mark,
charcoal/red/orange palette, technical grid, and detailed lower-band scene.
Composite uses one traversal rail through a nested folder; Mediator routes four
independent controls through one central plate. They remain coherent with the
collection, so regenerating either asset would add risk without improving the
system.

## Validation

```sh
swift test -Xswiftc -warnings-as-errors --filter Composite
swift test -Xswiftc -warnings-as-errors --filter Mediator
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict --no-cache Sources Tests
git diff --check
git check-ignore -v Editorial/
```

- Composite passes 14 tests in 10 suites; Mediator passes 27 tests in 12 suites,
  including the two new responsibility and ownership regressions.
- The full build succeeds and the warning-as-error suite passes 263 tests in
  142 suites.
- SwiftLint strict mode reports zero violations across 95 Swift files.
- Concrete local Markdown links resolve; external URLs and heading anchors are
  outside this check.
- Mermaid delimiters, diagram types, and domain identifiers were checked
  against the implementations. Mermaid CLI is unavailable, so no parser
  validation is claimed.
- Both editorial headers have the required 1672 × 941 dimensions and pass the
  five-part visual comparison.
- CodeGraph is not initialized. The review used scoped source, tests, and
  canonical guides; no index was created during this review.
- `Editorial/` remains ignored and outside the commit.

## Readiness decision

Day 070 is complete with two focused regression tests and no production
abstraction changes. Composite keeps recursive structure in value components
and feature policy in clients. Mediator keeps domain validation in participants
and owns only the bounded ordering needed to reach one coherent final choice.

Day 071 will define the direct Template Method problem. It has not started.
Day 070 is not a publication milestone, so no LinkedIn draft is created or
changed.
