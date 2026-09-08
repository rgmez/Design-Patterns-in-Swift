import DesignPatterns
import Testing

@Suite("Prototype")
struct PrototypeTests {
    @Test("Lets a new block type preserve itself without changing the document copier")
    func delegatesCopyingToTheRuntimeBlockType() throws {
        let sourceQuote = EditableQuoteBlock(
            id: "launch-quote",
            quote: "Ship the smallest honest abstraction."
        )
        let source = EditableDocument(
            title: "Release notes",
            blocks: [sourceQuote]
        )

        let duplicate = try duplicateEditableDocument(source)
        let copiedQuote = try #require(
            duplicate.blocks.first as? EditableQuoteBlock
        )

        #expect(sourceQuote !== copiedQuote)
        #expect(sourceQuote.id != copiedQuote.id)
        #expect(copiedQuote.quote == sourceQuote.quote)
    }

    @Test("Rejects duplicate source identities before copying")
    func rejectsDuplicateBlockIDs() {
        let source = EditableDocument(
            title: "Invalid graph",
            blocks: [
                EditableTextBlock(id: "reused", body: "First"),
                EditableTextBlock(id: "reused", body: "Second")
            ]
        )

        #expect(
            throws: EditableDocumentCopyError.duplicateBlockID("reused")
        ) {
            try duplicateEditableDocument(source)
        }
    }

    @Test("Rejects an internal link outside the copied graph")
    func rejectsMissingInternalLinkTargets() {
        let source = EditableDocument(
            title: "Invalid graph",
            blocks: [
                EditableLinkBlock(
                    id: "broken-link",
                    targetBlockID: "missing-block"
                )
            ]
        )

        #expect(
            throws: EditableDocumentCopyError.missingInternalLinkTarget(
                "missing-block"
            )
        ) {
            try duplicateEditableDocument(source)
        }
    }
}

private final class EditableQuoteBlock: EditableDocumentBlock {
    let id: String
    var quote: String

    init(id: String, quote: String) {
        self.id = id
        self.quote = quote
    }

    func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock {
        guard let copiedID = context.copiedID(for: id) else {
            throw EditableDocumentCopyError.missingBlockID(id)
        }

        return EditableQuoteBlock(id: copiedID, quote: quote)
    }
}
