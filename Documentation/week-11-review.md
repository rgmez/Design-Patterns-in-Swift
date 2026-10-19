# Template Method and Flyweight Review

Review date: 2026-10-19

This review closes Internal Day 077 by rechecking whether Template Method earns
inheritance over composition and whether Flyweight has enough quantitative
evidence to justify shared reference state.

## Decision matrix

| Question | Template Method | Flyweight |
| --- | --- | --- |
| What changes? | Three built-in providers vary decoding and eligibility inside one fixed import sequence | 20,000 annotations stop retaining equivalent decoded artwork per location |
| Stable boundary | One final import operation owns six ordered safety decisions | One request-scoped catalogue owns at most one immutable artwork resource per used category |
| Variable state | Provider payload decoding and candidate selection | Location identifier, title, coordinate, crowd status, and accessible summary |
| Simpler default | Direct functions or one composed function while the sequence is small or externally configurable | Direct annotation values or framework-owned asset sharing while repetition is immaterial |
| Evidence required | Repeated orchestration can drift and callers must not reorder it | Exact retained payload reduction must outweigh lookup and lifetime costs |

## Template Method decision

The direct implementation remains the correct starting point for one or two
providers. Shared normalization and deduplication helpers already remove the
ordinary implementation repetition without inheritance. A higher-order
function also remains the smaller answer when a caller needs to supply a local
variation or when external provider extensibility is a requirement.

Inheritance wins narrowly for the verified three-provider boundary. Safari,
Pocket, and Raindrop repeat six decisions whose order carries the behavior:
validate input, translate provider errors, normalize the complete eligible
batch, remove canonical duplicates, append once, and report counts from the
same run. `ReadingListImportTemplate.importEntries(from:into:)` is final, and
the subclasses can vary only one file-scoped decode-and-select hook. The public
base class is not open, its initializer is file-scoped, and no application can
add a subclass that silently replaces the sequence.

That restriction is the reason to accept the superclass coupling. Protocol
defaults would leave the workflow replaceable, while a closure bundle would
make the three named built-in formats less explicit. If selection,
normalization, persistence, or reporting must vary independently, composition
becomes safer again and this Template Method should not grow more hooks.

The hierarchy remains stateless after construction. `ReadingListLibrary` keeps
value semantics, mutation occurs only after complete normalization, and
concurrency ownership stays outside the example. An abstract-method trap,
provider registry, repository, configurable stage graph, and unchecked
`Sendable` conformance remain unjustified.

## Flyweight justification

The direct builder and the final builder use the same deterministic 32 × 32
RGBA decoder, category descriptors, location order, and accessibility inputs.
The representative workload therefore compares the ownership boundary rather
than two different rendering policies:

| Evidence | Direct builder | Flyweight builder | Reduction |
| --- | ---: | ---: | ---: |
| Artwork objects | 20,000 | 4 | 19,996 |
| Icon decodes | 20,000 | 4 | 19,996 |
| Decoded pixel payload | 81,920,000 bytes | 16,384 bytes | 81,903,616 bytes |
| Decoded pixel payload | 78.125 MiB | 0.015625 MiB | 78.109375 MiB |

The shared representation removes 99.98% of the modeled decoded pixel payload.
This is an exact count for the arrays owned by the example, not an RSS or total
process-memory claim. Object headers, array capacity, allocator behavior,
strings, renderer copies, and platform caches are deliberately excluded.

The cost remains bounded and visible: derive the used-category set, build at
most four resources, perform one expected-constant-time dictionary lookup per
annotation, and decode those resources again for a future map build. The
catalogue is scoped to one request, so the example does not introduce a global
cache, eviction policy, synchronization, test reset, or Singleton lifetime.

`FestivalMarkerArtwork` is the immutable intrinsic state. Each
`FestivalMapAnnotation` retains unique extrinsic map and accessibility state.
Sharing mutable selection, tint, animation, or crowd data would invalidate the
boundary; those values must remain in the context.

## Classification and avoided complexity

Template Method is not Strategy: the complete algorithm is not selected at
runtime, and only one provider-specific step varies inside a fixed order. It is
not Factory Method either, because subclasses do not choose a product to
construct. Composition remains preferable as soon as the stages become
independently variable.

Flyweight is not a generic cache: its key set is the closed venue-category enum,
all resources are created before annotation assembly, and there are no misses,
evictions, or cross-build retention. It is the opposite of Prototype at the
intrinsic boundary: annotations deliberately share one immutable object rather
than create independently mutable copies. It is not Singleton because each map
build owns a fresh catalogue.

No production type or test changed during this review. Extra hooks, a provider
protocol, a generic pipeline, an actor-backed image cache, a weak table, a
repository, and dependency-injection machinery would add capabilities that the
verified requirements do not ask for.

## Documentation and visual review

Both canonical guides retain the app problem, direct baseline, turning point,
participants, Swift walkthrough, execution commands, tests, trade-offs,
alternatives, explicit `When not to use it` guidance, and concrete source
links. Their Mermaid diagrams use real domain types, include an explanatory
paragraph, and provide an accessible equivalent.

The existing 1672 × 941 headers were compared with the approved Adapter
reference. Both retain the upper-left typographic hierarchy, upper-right
original RG mark, charcoal/red/orange palette, subtle grid, and detailed lower
technical scene. Template Method uses three provider entrances converging on
one fixed processing rail; Flyweight uses four resource cartridges serving a
large field of unique pins. They belong to the same collection, so regenerating
either asset would add risk without improving the visual system.

## Validation

```sh
swift test -Xswiftc -warnings-as-errors --filter TemplateMethod
swift test -Xswiftc -warnings-as-errors --filter Flyweight
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
git diff --check
git check-ignore -v Editorial/
```

- Template Method passes 16 tests in 8 suites; Flyweight passes 13 tests in 5
  suites.
- The full build succeeds and the warning-as-error suite passes 292 tests in
  155 suites.
- The repository has no `.swiftlint.yml`, so no project SwiftLint gate exists
  for this review.
- Concrete local Markdown links resolve; external URLs and heading anchors are
  outside this check.
- Mermaid fences, diagram types, and domain identifiers match the
  implementations. Mermaid CLI is unavailable, so parser validation is not
  claimed.
- Both editorial headers have the required 1672 × 941 dimensions and pass the
  five-part visual comparison.
- CodeGraph is not initialized. This review used scoped source, tests, and
  canonical guides; no index was created implicitly.
- `Editorial/` remains ignored and outside the commit.

## Readiness decision

Day 077 is complete without adding production ceremony. Template Method keeps
one closed, non-overridable sequence only because three built-in providers
repeat six behaviorally significant decisions; composition remains the default
outside that boundary. Flyweight keeps request-scoped immutable sharing because
the verified fixture avoids 81,903,616 decoded pixel bytes for the cost of one
bounded lookup per annotation.

Day 078 will define the direct Visitor problem. It has not started. Day 077 is
not a publication milestone, so no LinkedIn draft is created or changed.
