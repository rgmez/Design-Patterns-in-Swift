import Foundation

public final class DocumentMediaResource {
    public let assetID: String
    public let filename: String

    public init(assetID: String, filename: String) {
        self.assetID = assetID
        self.filename = filename
    }
}

public protocol EditableDocumentBlock: AnyObject {
    var id: String { get }

    func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock
}

public struct EditableDocumentCopyContext {
    private let copiedIDs: [String: String]

    fileprivate init(copiedIDs: [String: String]) {
        self.copiedIDs = copiedIDs
    }

    public func copiedID(for sourceBlockID: String) -> String? {
        copiedIDs[sourceBlockID]
    }
}

public final class EditableTextBlock: EditableDocumentBlock {
    public let id: String
    public var body: String

    public init(id: String, body: String) {
        self.id = id
        self.body = body
    }

    public func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock {
        guard let copiedID = context.copiedID(for: id) else {
            throw EditableDocumentCopyError.missingBlockID(id)
        }

        return EditableTextBlock(id: copiedID, body: body)
    }
}

public final class EditableChecklistBlock: EditableDocumentBlock {
    public let id: String
    public var items: [String]

    public init(id: String, items: [String]) {
        self.id = id
        self.items = items
    }

    public func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock {
        guard let copiedID = context.copiedID(for: id) else {
            throw EditableDocumentCopyError.missingBlockID(id)
        }

        return EditableChecklistBlock(id: copiedID, items: items)
    }
}

public final class EditableLinkBlock: EditableDocumentBlock {
    public let id: String
    public var targetBlockID: String

    public init(id: String, targetBlockID: String) {
        self.id = id
        self.targetBlockID = targetBlockID
    }

    public func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock {
        guard let copiedID = context.copiedID(for: id) else {
            throw EditableDocumentCopyError.missingBlockID(id)
        }
        guard let copiedTargetID = context.copiedID(for: targetBlockID) else {
            throw EditableDocumentCopyError.missingInternalLinkTarget(
                targetBlockID
            )
        }

        return EditableLinkBlock(
            id: copiedID,
            targetBlockID: copiedTargetID
        )
    }
}

public final class EditableMediaBlock: EditableDocumentBlock {
    public let id: String
    public let resource: DocumentMediaResource

    public init(id: String, resource: DocumentMediaResource) {
        self.id = id
        self.resource = resource
    }

    public func copy(
        using context: EditableDocumentCopyContext
    ) throws -> any EditableDocumentBlock {
        guard let copiedID = context.copiedID(for: id) else {
            throw EditableDocumentCopyError.missingBlockID(id)
        }

        return EditableMediaBlock(id: copiedID, resource: resource)
    }
}

public struct EditableDocument {
    public var title: String
    public var blocks: [any EditableDocumentBlock]

    public init(title: String, blocks: [any EditableDocumentBlock]) {
        self.title = title
        self.blocks = blocks
    }
}

public enum EditableDocumentCopyError: Error, Equatable {
    case duplicateBlockID(String)
    case missingBlockID(String)
    case missingInternalLinkTarget(String)
}

public func duplicateEditableDocument(
    _ source: EditableDocument
) throws -> EditableDocument {
    var copiedIDs: [String: String] = [:]
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
    }

    let context = EditableDocumentCopyContext(copiedIDs: copiedIDs)
    let copiedBlocks = try source.blocks.map {
        try $0.copy(using: context)
    }

    return EditableDocument(title: source.title, blocks: copiedBlocks)
}
