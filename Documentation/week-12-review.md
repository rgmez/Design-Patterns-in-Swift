# Visitor and Interpreter Review

Review date: 2026-10-26

This review closes Internal Day 084 by checking that Visitor extends in the
direction the publishing product actually changes and that Interpreter remains
a bounded language rather than growing a speculative grammar or general AST.

## Decision matrix

| Question | Visitor | Interpreter |
| --- | --- | --- |
| What changes? | Whole-document publishing operations grow over four stable element kinds | One saved support query combines bounded status and assignee terms |
| Stable boundary | Paragraph, link, image, and table dispatch through one operation protocol | Whitespace-separated terms use outer AND; only a status value may contain local OR |
| Variable state | Each visitor owns its accumulator and any cross-element traversal state | Parsed expressions hold status alternatives or one assignee alias |
| Simpler default | One exhaustive enum switch while operations remain few | One field switch while filters remain independent atoms |
| Reconsider when | Element kinds change as often as operations | Nesting, precedence, escaping, recovery, or shared grammar becomes a real requirement |

## Visitor extension direction

The direct enum remains the correct starting point for one accessibility
operation. It keeps four cases visible in one exhaustive switch and lets the
compiler identify every operation affected by a new element. Visitor earns its
boundary only after plain-text extraction and localization inventory make the
opposite change direction concrete: three operations repeat three traversals,
three type switches, and twelve branches while the element family remains
unchanged.

The final design keeps that asymmetry explicit. `PublishingArticle.accept(_:)`
walks one ordered existential collection. Each of the four concrete values has
one small `accept` implementation, and `PublishingDocumentVisiting` contains one
overload per value. A new outbound-link operation in the tests conforms to the
existing protocol without editing the elements. A new video element would have
to change the protocol and every visitor, so it is deliberately not an easy
extension.

The three visitors do not share a result abstraction. Accessibility owns
ordered findings and heading state, plain text owns normalized lines, and
localization owns entries with node and table metadata. Keeping those mutable
accumulators in separate single-use reference types avoids casts, `Any` results,
a generic fold with four closures at every call site, and a shared conditional
pipeline that would conflate different decorative-image policies.

That benefit remains narrow. If the element family starts growing, the enum and
exhaustive switches regain the advantage. If only one or two operations remain,
the two protocols and dynamic dispatch are unnecessary. A result-associated
visitor, operation registry, type erasure layer, superclass, visitor factory,
actor, or asynchronous traversal would add capabilities this publishing example
does not need.

## Interpreter grammar boundary

The direct filter remains the smallest correct design for independent
`field:value` atoms. The pattern becomes useful only when
`status:(open|waiting)` adds a local composition scope and the editor requires
positioned diagnostics. At that point parsing shape, source offsets, vocabulary
validation, and immediate filtering would otherwise remain coupled in one
scanner.

The final representation is intentionally smaller than a general AST:

- `SupportTicketQuery` stores one ordered array of expressions and interprets
  query-wide AND with `allSatisfy`.
- `SupportTicketFilterExpression` has only status and assignee cases.
- A status expression stores a `Set<SupportTicketStatus>` for local OR instead
  of introducing a recursive binary operator.
- `SupportTicketAssigneeExpression` distinguishes only the current agent and an
  unassigned ticket; the injected identifier never becomes global state.
- `SupportTicketQueryParser` scans the source once and reports zero-based
  positions through a fixed error vocabulary.

The tests preserve the semantic edges that make this boundary reviewable: a
blank query is an empty conjunction, repeated fields remain conjunctive,
alternative order never changes inbox order, grouped assignees are rejected,
and nine syntax or vocabulary failures retain exact positions. Parsing happens
once before the original ticket array is filtered.

There is no recursive group, operator precedence, global OR, NOT, escaping,
quoted value, range, free-text term, formatter, multi-error recovery, tokenizer
object graph, parser combinator layer, expression protocol hierarchy, visitor,
registry, repository, or asynchronous pipeline. If any of nesting, precedence,
escaping, recovery, or a grammar shared across clients becomes real, this
hand-written parser should be replaced by maintained parsing infrastructure
rather than extended into an accidental language platform.

## Classification and avoided complexity

Visitor is not Strategy: three operations coexist, produce unrelated results,
and specialize behavior across concrete element types instead of selecting one
algorithm behind one contract. It is not Iterator because article traversal is
already trivial; double dispatch, not element production, is the reason for the
boundary. It is not Composite because the article is flat and no uniform
part-whole operation is required.

Interpreter is not a generic Specification layer: the product owns a textual
language whose source must be parsed and diagnosed. It is not Chain of
Responsibility because every term participates instead of one handler claiming
the request. It does not need Composite because the accepted grammar rejects
recursive structure, and the status alternatives are one terminal value rather
than child expressions.

No production type or test changed during this review. The direct and pressure
implementations remain executable evidence rather than parallel application
architectures. Removing them would discard the verified comparison that explains
why each pattern was introduced; extending them with shared abstractions would
make that comparison less honest.

## Documentation and visual review

Both canonical guides retain the app problem, direct baseline, turning point,
participants, Swift walkthrough, execution commands, tests, trade-offs,
alternatives, explicit `When not to use it` guidance, concrete source links,
caption, and descriptive image text. Their Mermaid sequence diagrams use the
real domain types, explain what to observe, and include an accessible equivalent.

The existing 1672 × 941 headers were compared with the approved Adapter
reference. Both preserve the upper-left typographic hierarchy, upper-right RG
mark, charcoal/red/orange palette, subtle technical grid, and detailed lower
scene. Visitor sends operations through a stable publishing rail; Interpreter
splits one bounded query path into local alternatives before recombining it.
Their metaphors, composition, hierarchy, logo treatment, and detail remain part
of the same collection, so regenerating either asset would add risk without
improving the visual system.

## Validation

```sh
swift test -Xswiftc -warnings-as-errors --filter Visitor
swift test -Xswiftc -warnings-as-errors --filter Interpreter
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
git diff --check
git check-ignore -v Editorial/
```

- Visitor passes 17 tests in 11 suites; Interpreter passes 23 tests in 10
  suites.
- The full build succeeds and the warning-as-error suite passes 332 tests in
  176 suites.
- The repository has no `.swiftlint.yml`, so no project SwiftLint gate exists
  for this review.
- Concrete local links resolve across 119 consumable Markdown files. The five
  intentionally fictitious paths in `pattern-readme-template.md` are excluded
  from that count.
- All 45 Mermaid fences are closed and begin with a supported diagram
  declaration. Mermaid CLI is unavailable, so renderer-level validation is not
  claimed.
- Both editorial headers have the required 1672 × 941 dimensions and pass the
  five-part visual comparison against the byte-identical local Adapter reference.
- CodeGraph is not initialized. This review used scoped source, tests, and
  canonical guides; no index was created implicitly.
- `Editorial/` remains ignored, contains no tracked files, and stays outside the
  commit.

## Readiness decision

Day 084 is complete without production changes. Visitor keeps double dispatch
only because operations have demonstrably outgrown a stable element family, and
its expensive element-extension direction is documented rather than hidden.
Interpreter keeps one non-recursive value-semantic representation for a grammar
with exactly one local OR scope; every plausible general-language feature stays
outside the boundary or triggers a parser-library decision.

Day 085 will define the process-unique platform resource that may justify
Singleton while preserving explicit ownership. It has not started. Day 084 is
not a publication milestone, so no LinkedIn draft is created or changed.
