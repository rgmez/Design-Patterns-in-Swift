import DesignPatterns
import Testing

@Suite("Prototype pressure")
struct PrototypePressureTests {
    private static let documentTitle = "Release plan"
    private static let textBlockID = "overview"
    private static let checklistBlockID = "launch-checklist"
    private static let linkBlockID = "overview-link"
    private static let mediaBlockID = "hero-image"
    private static let mediaAssetID = "asset-42"
    private static let mediaFilename = "launch-hero.heic"
    private static let sourceText = "Prepare version 4.2."
    private static let editedText = "Prepare version 4.3."
    private static let checklistItems = ["Archive", "Upload", "Verify"]

    private static func makeDocument() -> EditableDocument {
        let mediaResource = DocumentMediaResource(
            assetID: mediaAssetID,
            filename: mediaFilename
        )

        return EditableDocument(
            title: documentTitle,
            blocks: [
                EditableTextBlock(id: textBlockID, body: sourceText),
                EditableChecklistBlock(
                    id: checklistBlockID,
                    items: checklistItems
                ),
                EditableLinkBlock(
                    id: linkBlockID,
                    targetBlockID: textBlockID
                ),
                EditableMediaBlock(id: mediaBlockID, resource: mediaResource)
            ]
        )
    }

    @Suite("Ordinary reference assignment")
    struct OrdinaryReferenceAssignment {
        @Test("Shares mutable blocks with the source document")
        func sharesMutableBlocks() throws {
            let source = PrototypePressureTests.makeDocument()
            let assignedCopy = source
            let sourceTextBlock = try #require(
                source.blocks[0] as? EditableTextBlock
            )
            let assignedTextBlock = try #require(
                assignedCopy.blocks[0] as? EditableTextBlock
            )

            assignedTextBlock.body = PrototypePressureTests.editedText

            #expect(sourceTextBlock === assignedTextBlock)
            #expect(sourceTextBlock.body == PrototypePressureTests.editedText)
        }
    }

    @Suite("Centralized direct duplication")
    struct CentralizedDirectDuplication {
        @Test("Creates fresh editable identities and independent state")
        func createsIndependentBlocks() throws {
            let source = PrototypePressureTests.makeDocument()
            let duplicate = try duplicateEditableDocument(source)
            let sourceTextBlock = try #require(
                source.blocks[0] as? EditableTextBlock
            )
            let copiedTextBlock = try #require(
                duplicate.blocks[0] as? EditableTextBlock
            )

            copiedTextBlock.body = PrototypePressureTests.editedText

            #expect(sourceTextBlock !== copiedTextBlock)
            #expect(sourceTextBlock.id != copiedTextBlock.id)
            #expect(sourceTextBlock.body == PrototypePressureTests.sourceText)
            #expect(copiedTextBlock.body == PrototypePressureTests.editedText)
        }

        @Test("Preserves runtime block kinds and subtype state")
        func preservesSubtypeState() throws {
            let duplicate = try duplicateEditableDocument(
                PrototypePressureTests.makeDocument()
            )
            let copiedTextBlock = try #require(
                duplicate.blocks[0] as? EditableTextBlock
            )
            let copiedChecklistBlock = try #require(
                duplicate.blocks[1] as? EditableChecklistBlock
            )

            #expect(copiedTextBlock.body == PrototypePressureTests.sourceText)
            #expect(
                copiedChecklistBlock.items
                    == PrototypePressureTests.checklistItems
            )
        }

        @Test("Remaps internal links while sharing immutable media")
        func appliesGraphCopyPolicy() throws {
            let source = PrototypePressureTests.makeDocument()
            let duplicate = try duplicateEditableDocument(source)
            let sourceMediaBlock = try #require(
                source.blocks[3] as? EditableMediaBlock
            )
            let copiedTextBlock = try #require(
                duplicate.blocks[0] as? EditableTextBlock
            )
            let copiedLinkBlock = try #require(
                duplicate.blocks[2] as? EditableLinkBlock
            )
            let copiedMediaBlock = try #require(
                duplicate.blocks[3] as? EditableMediaBlock
            )

            #expect(
                copiedLinkBlock.targetBlockID
                    == copiedTextBlock.id
            )
            #expect(
                copiedLinkBlock.targetBlockID
                    != PrototypePressureTests.textBlockID
            )
            #expect(sourceMediaBlock.resource === copiedMediaBlock.resource)
        }
    }
}
