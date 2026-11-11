# Template Method Composition Review

Review date: 2026-11-11

Bonus 008 implements the strongest smaller Swift alternative to the reading-list
Template Method: one ordinary value whose fixed import function receives a
decode-and-select closure.

## Executable comparison

`TemplateMethodCompositionTests` defines a test-only
`HigherOrderImporter`. Its public-shaped operation owns the same order as the
class template:

1. reject empty input;
2. call one provider decode-and-select closure;
3. normalize the complete candidate batch;
4. remove stored and in-batch duplicates;
5. append once; and
6. build the source-aware report.

The focused tests prove that this composition produces the same normalized
result shape and preserves atomicity when a later candidate is invalid. A
higher-order function can therefore protect the safety rail; inheritance is not
the only encoding of a fixed algorithm.

The comparator duplicates the small rail in the test target to make its API and
behavior reviewable. It is not a second production implementation or a
line-count benchmark.

## Decision

**Use Template Method** for this closed set of three named, built-in importers
when callers benefit from one nominal importer type and the module must prevent
subclassing or replacement of the final operation. Each subclass can vary only
the file-scoped decode-and-select hook.

Prefer the higher-order composition when:

- the variation is local to one call site;
- callers need to inject or assemble providers dynamically;
- value semantics are preferable to a stateless class hierarchy; or
- external providers must supply the decode operation.

The function alternative is not less safe by nature. Its safety depends on
keeping the fixed rail private and exposing only the intended operation, just as
the class design depends on a final method and an inaccessible hook.

## Cost and reversal

The canonical design pays for one superclass and three subclasses to obtain a
shared nominal type and module-controlled variation. Swift has no abstract
classes, so the base hook must still fail safely even though normal construction
cannot reach it.

Replace the hierarchy with the higher-order value if runtime or external
provider composition becomes a requirement, or if the common base type has no
real consumer. Keep direct functions for one or two providers while their order
remains easy to review.

## Verification

```sh
swift test -Xswiftc -warnings-as-errors --filter TemplateMethodCompositionTests
swift test -Xswiftc -warnings-as-errors --filter TemplateMethod
```
