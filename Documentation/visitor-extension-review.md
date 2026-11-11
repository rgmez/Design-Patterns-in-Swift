# Visitor Extension-Direction Review

Review date: 2026-11-11

Bonus 009 makes Visitor's asymmetric change cost explicit without inventing a
fifth publishing element.

## Cheap direction: add an operation

`VisitorTests.ExtensionDirection` defines an
`OutboundDestinationVisitor` in the test target. It implements the existing
visitor surface, traverses the canonical article, and collects link destinations
without changing:

- `PublishingParagraph`, `PublishingLink`, `PublishingImage`, or
  `PublishingTable`;
- their `accept` implementations;
- `PublishingArticle`; or
- the three production visitors.

The test is executable proof of the extension direction the pattern optimizes.
The new operation remains one cohesive type and existing element code stays
closed.

## Expensive direction: add an element kind

The current production change surface contains:

| Surface | Current count | Change required for a new element |
| --- | ---: | --- |
| Visitor protocol | 1 | Add one concrete overload. |
| Element forwarding extensions | 4 | Add the new element's `accept` forwarding. |
| Production visitors | 3 | Implement the new overload in every visitor. |
| External/test visitors | Open-ended | Every conformer must implement the new requirement. |

This cost is compiler-enforced. A partially updated visitor does not produce a
runtime failure; it fails protocol conformance at build time. Adding a fake
video, quote, or code-block element merely to create that diff would manufacture
a product requirement and permanently enlarge the example.

The `ElementKindVisitor` test instead verifies that the present dispatch surface
is complete and ordered: title, paragraph, link, image, and table.

## Decision and reversal

**Use Visitor** while whole-document operations grow and paragraph, link,
image, and table remain the stable element family. The three production
operations already justify centralizing concrete dispatch.

Return to the exhaustive enum when operations stop growing or element kinds
change with comparable frequency. Prefer intrinsic methods when new behavior is
a rule of the element itself rather than an external publishing operation.

Do not hide the expensive direction with default no-op visitor methods: that
would let a new element compile while existing operations silently ignore it.

## Verification

```sh
swift test -Xswiftc -warnings-as-errors --filter "VisitorTests/ExtensionDirection"
swift test -Xswiftc -warnings-as-errors --filter Visitor
```
