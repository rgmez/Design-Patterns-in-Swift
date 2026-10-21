import Foundation

public struct DirectDocumentPlainTextExtractor: Sendable {
    public init() {}

    public func text(
        from document: PublishingDocument
    ) -> String {
        var lines = [document.title]

        for node in document.nodes {
            switch node {
            case let .paragraph(paragraph):
                append(paragraph.text, to: &lines)
            case let .link(link):
                append(link.label, to: &lines)
            case let .image(image):
                guard !image.isDecorative else {
                    continue
                }
                append(image.alternativeText, to: &lines)
            case let .table(table):
                append(table.caption, to: &lines)
                append(table.columnHeaders.joined(separator: " | "), to: &lines)
                for row in table.rows {
                    append(row.joined(separator: " | "), to: &lines)
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private func append(
        _ candidate: String?,
        to lines: inout [String]
    ) {
        guard let candidate else {
            return
        }

        let trimmed = candidate.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !trimmed.isEmpty {
            lines.append(trimmed)
        }
    }
}

public enum PublishingLocalizationField: Equatable, Sendable {
    case documentTitle
    case paragraphText
    case linkLabel
    case imageAlternativeText(assetName: String)
    case tableCaption
    case tableColumnHeader(index: Int)
    case tableCell(row: Int, column: Int)
}

public struct PublishingLocalizationEntry: Equatable, Sendable {
    public let nodeID: String?
    public let field: PublishingLocalizationField
    public let sourceText: String

    public init(
        nodeID: String?,
        field: PublishingLocalizationField,
        sourceText: String
    ) {
        self.nodeID = nodeID
        self.field = field
        self.sourceText = sourceText
    }
}

public struct DirectDocumentLocalizationInventory: Sendable {
    public init() {}

    public func entries(
        in document: PublishingDocument
    ) -> [PublishingLocalizationEntry] {
        var entries: [PublishingLocalizationEntry] = []
        append(
            document.title,
            nodeID: nil,
            field: .documentTitle,
            to: &entries
        )

        for node in document.nodes {
            switch node {
            case let .paragraph(paragraph):
                append(
                    paragraph.text,
                    nodeID: paragraph.id,
                    field: .paragraphText,
                    to: &entries
                )
            case let .link(link):
                append(
                    link.label,
                    nodeID: link.id,
                    field: .linkLabel,
                    to: &entries
                )
            case let .image(image):
                append(
                    image.alternativeText,
                    nodeID: image.id,
                    field: .imageAlternativeText(
                        assetName: image.assetName
                    ),
                    to: &entries
                )
            case let .table(table):
                appendTable(table, to: &entries)
            }
        }

        return entries
    }

    private func appendTable(
        _ table: PublishingTable,
        to entries: inout [PublishingLocalizationEntry]
    ) {
        append(
            table.caption,
            nodeID: table.id,
            field: .tableCaption,
            to: &entries
        )

        for (index, header) in table.columnHeaders.enumerated() {
            append(
                header,
                nodeID: table.id,
                field: .tableColumnHeader(index: index),
                to: &entries
            )
        }

        for (rowIndex, row) in table.rows.enumerated() {
            for (columnIndex, cell) in row.enumerated() {
                append(
                    cell,
                    nodeID: table.id,
                    field: .tableCell(
                        row: rowIndex,
                        column: columnIndex
                    ),
                    to: &entries
                )
            }
        }
    }

    private func append(
        _ candidate: String?,
        nodeID: String?,
        field: PublishingLocalizationField,
        to entries: inout [PublishingLocalizationEntry]
    ) {
        guard let candidate else {
            return
        }

        let trimmed = candidate.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !trimmed.isEmpty {
            entries.append(
                PublishingLocalizationEntry(
                    nodeID: nodeID,
                    field: field,
                    sourceText: trimmed
                )
            )
        }
    }
}
