import Foundation

public final class DocumentMediaResource {
    public let assetID: String
    public let filename: String

    public init(assetID: String, filename: String) {
        self.assetID = assetID
        self.filename = filename
    }
}

public class EditableDocumentBlock {
    public let id: String

    fileprivate init(id: String) {
        self.id = id
    }
}

public final class EditableTextBlock: EditableDocumentBlock {
    public var body: String

    public init(id: String, body: String) {
        self.body = body
        super.init(id: id)
    }
}

public final class EditableChecklistBlock: EditableDocumentBlock {
    public var items: [String]

    public init(id: String, items: [String]) {
        self.items = items
        super.init(id: id)
    }
}

public final class EditableLinkBlock: EditableDocumentBlock {
    public var targetBlockID: String

    public init(id: String, targetBlockID: String) {
        self.targetBlockID = targetBlockID
        super.init(id: id)
    }
}

public final class EditableMediaBlock: EditableDocumentBlock {
    public let resource: DocumentMediaResource

    public init(id: String, resource: DocumentMediaResource) {
        self.resource = resource
        super.init(id: id)
    }
}

public struct EditableDocument {
    public var title: String
    public var blocks: [EditableDocumentBlock]

    public init(title: String, blocks: [EditableDocumentBlock]) {
        self.title = title
        self.blocks = blocks
    }
}

public enum EditableDocumentCopyError: Error, Equatable {
    case duplicateBlockID(String)
    case missingInternalLinkTarget(String)
    case unsupportedBlockKind(String)
}

public func duplicateEditableDocument(
    _ source: EditableDocument
) throws -> EditableDocument {
    var copiedIDs: [String: String] = [:]
    var copiedEntries: [(block: EditableDocumentBlock, copiedID: String)] = []
    var allocatedIDs = Set(source.blocks.map(\.id))

    for block in source.blocks {
        guard copiedIDs[block.id] == nil else {
            throw EditableDocumentCopyError.duplicateBlockID(block.id)
        }

        var copiedID = UUID().uuidString
        while !allocatedIDs.insert(copiedID).inserted {
            copiedID = UUID().uuidString
        }
        copiedIDs[block.id] = copiedID
        copiedEntries.append((block: block, copiedID: copiedID))
    }

    let copiedBlocks = try copiedEntries.map { entry -> EditableDocumentBlock in
        let block = entry.block
        let copiedID = entry.copiedID

        switch block {
        case let textBlock as EditableTextBlock:
            return EditableTextBlock(id: copiedID, body: textBlock.body)
        case let checklistBlock as EditableChecklistBlock:
            return EditableChecklistBlock(
                id: copiedID,
                items: checklistBlock.items
            )
        case let linkBlock as EditableLinkBlock:
            guard let copiedTargetID = copiedIDs[linkBlock.targetBlockID] else {
                throw EditableDocumentCopyError.missingInternalLinkTarget(
                    linkBlock.targetBlockID
                )
            }
            return EditableLinkBlock(
                id: copiedID,
                targetBlockID: copiedTargetID
            )
        case let mediaBlock as EditableMediaBlock:
            return EditableMediaBlock(
                id: copiedID,
                resource: mediaBlock.resource
            )
        default:
            throw EditableDocumentCopyError.unsupportedBlockKind(
                String(reflecting: type(of: block))
            )
        }
    }

    return EditableDocument(title: source.title, blocks: copiedBlocks)
}
