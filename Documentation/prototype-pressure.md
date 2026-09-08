# Prototype Pressure: Copying an Identity-Rich Document Graph

Pressure-review date: 2026-09-07

This document records Day 030 of the Prototype cycle. It introduces the
smallest reference-backed document graph needed to expose what ordinary Swift
assignment cannot provide, then keeps the first correct copy operation direct
and centralized before considering Prototype.

## The requirement that changed

The editor no longer duplicates only value configuration. A document now owns
four independently evolving block kinds:

- a text block with editable body content;
- a checklist block with its own mutable item collection;
- an internal link block that targets another block by identity;
- a media block that points to one immutable uploaded asset.

The editor keeps stable block references while focus, selection, and observation
move between views. Converting those live objects back into one nested value enum
would remove the reference problem, but it would also change the identity model
that the product now requires.

## Why assignment stops being a copy

[`EditableDocument`](../Sources/DesignPatterns/Prototype/EditableDocumentGraph.swift)
is a value containing an array of reference-backed blocks. Assigning the outer
value copies the title and array storage, but both arrays still contain the same
four objects:

```swift
let assignedCopy = source
if let text = assignedCopy.blocks[0] as? EditableTextBlock {
    text.body = "Prepare version 4.3."
}
```

The source text changes as well because both documents own the same text-block
reference. The focused tests measure this explicitly: all editable state behind
that reference is shared even though the outer document is a struct.

## Direct Swift extension retained

`duplicateEditableDocument(_:)` performs the first correct graph duplication as
one ordinary function. It creates an old-to-new identifier map, then uses one
exhaustive type switch to rebuild every mutable block:

```swift
switch block {
case let textBlock as EditableTextBlock:
    return EditableTextBlock(id: copiedID, body: textBlock.body)
case let checklistBlock as EditableChecklistBlock:
    return EditableChecklistBlock(id: copiedID, items: checklistBlock.items)
// Link and media branches follow the same centralized policy.
}
```

The routine satisfies the graph rules fixed on Day 029:

1. Every copied block has fresh object and domain identity.
2. Editing the copied text does not mutate the source.
3. Concrete block kinds and their type-specific state survive the copy.
4. Internal links point to copied block identifiers.
5. The immutable media resource is deliberately shared rather than duplicated.

No cloning protocol, `clone()` method, copy context, registry, factory, or
serialization round trip exists yet.

## Measured pressure

The direct operation works, but preserving runtime block kinds centralizes four
concrete reconstruction branches in one function. A fifth block kind requires
editing this switch even when the new subtype already owns all of its state and
construction rules. Forgetting that edit reaches the explicit
`unsupportedBlockKind` failure instead of producing a valid duplicate.

The link branch also needs the identifier map while the media branch follows a
different ownership policy. This makes a blind recursive deep copy incorrect:
links would retain source identities or immutable media bytes would be copied
without benefit. The pressure is therefore not object creation cost. It is the
need for each runtime block kind to preserve itself within one shared graph-copy
context without a central function learning every subtype.

| Observable operation | Mutable block object | Runtime kind and state | Internal link | Media resource |
| --- | --- | --- | --- | --- |
| Ordinary assignment | Shared | Preserved by sharing | Points into same graph | Shared |
| Central direct duplication | Fresh | Preserved by four type branches | Remapped | Shared by policy |
| Required extensible duplication | Fresh | Preserved by owning subtype | Remapped through shared context | Shared by policy |

## Executable evidence

[`PrototypePressureTests.swift`](../Tests/DesignPatternsTests/PrototypePressureTests.swift)
uses isolated fixtures to verify:

- an ordinary assignment exposes the same mutable text-block reference;
- the centralized operation creates fresh editable object and domain identity;
- editing copied text leaves its source untouched;
- text and checklist runtime kinds keep their type-specific state;
- an internal link targets the copied text block;
- source and duplicate deliberately retain the same immutable media resource.

Run the focused evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter PrototypePressureTests
```

## Smaller alternatives considered

A closed enum with associated values would make block kinds exhaustive and use
value copying naturally. It remains the better design when blocks do not need
stable reference identity across editor owners. Here it would change an already
required observation and selection contract merely to avoid defining copy
semantics.

Encoding and decoding the graph would hide the same subtype registry in a
serializer, make internal identity repair implicit, and duplicate the immutable
media description. `NSCopying` would add Objective-C conventions without
expressing the graph context or the media-sharing policy.

The centralized function remains preferable if the four block kinds form a
small, closed set. Prototype earns consideration only because concrete kinds
vary independently and each new kind otherwise expands the same reconstruction
switch. The completed [canonical Prototype guide](../Creational%20Patterns/Prototype/README.md)
shows the smaller extensible boundary and keeps this direct implementation as
the evidence that justified it.

## Day 030 decision

Ordinary assignment is rejected at the reference boundary because an edit to a
supposed copy mutates the source. The direct centralized duplication was correct
for this day, and its four subtype branches identified the extension pressure
precisely. Day 031 moved only subtype-specific copying behind the explicit
`EditableDocumentBlock.copy(using:)` capability while retaining one small graph
context for identity remapping and deliberate media sharing.
