# Interpreter Parser Handoff

Review date: 2026-11-11

Bonus 005 turns the handoff from the bounded support-query Interpreter to
maintained parser infrastructure into executable rejection evidence. It does
not extend the grammar or choose a dependency before the product needs one.

## Current boundary

The hand-written parser owns one deliberately small language:

- whitespace-separated terms combined with AND;
- `status` and `assignee` fields;
- one non-nested status group with local OR;
- fixed domain vocabularies; and
- one positioned diagnostic per rejected query.

This is enough structure to justify separating parsing from interpretation, but
not enough to justify a tokenizer, recursive AST, precedence table, recovery
engine, or parser-combinator dependency.

## Executable handoff matrix

`InterpreterTests.MaintainedParserHandoff` supplies one representative query
for each infrastructure threshold:

| Product requirement | Representative query | Current deterministic result |
| --- | --- | --- |
| Nested groups | `status:((open|waiting)|closed)` | Reject the outer operator after the first group. |
| Operator precedence | `status:open\|status:waiting` | Reject global OR at its exact delimiter. |
| Quoted values | `status:"open waiting"` | Reject the quoted token as unsupported vocabulary. |
| Escaped whitespace | `assignee:agent\\ robin` | Reject the escaped token instead of inventing tokenization rules. |
| Multi-error recovery | `status:(\|) assignee:` | Return the first positioned error and stop before recovery. |

These tests are not acceptance criteria for those features. They protect the
opposite invariant: adding one of them as a real requirement must not quietly
grow the current scanner.

## Handoff decision

Adopt maintained parsing infrastructure when any matrix row changes from
invalid input to supported product behavior, or when the grammar must be shared
with another client or server implementation.

At that point, the infrastructure should own tokenization, recursion,
precedence, escaping, and recovery. The app can still own
`SupportTicketFilterExpression`, domain vocabulary, and interpretation if those
values remain useful. Replacing parser mechanics does not require discarding the
domain expression model.

Do not select a library in advance. The relevant choice depends on the first
real requirement: parser combinators may suit a small recursive grammar, while
a generated or shared grammar may need different tooling.

## Verification and reversal

```sh
swift test -Xswiftc -warnings-as-errors --filter "InterpreterTests/MaintainedParserHandoff"
swift test -Xswiftc -warnings-as-errors --filter Interpreter
```

**Use Interpreter** while the bounded language remains inspectable and the
hand-written parser has one shallow composition level. Replace only the parser
mechanics when a handoff trigger becomes supported behavior. Return to direct
field predicates if grouped syntax and positioned diagnostics disappear.
