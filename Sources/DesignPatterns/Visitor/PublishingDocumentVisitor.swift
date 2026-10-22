import Foundation

public protocol PublishingDocumentVisiting: AnyObject {
    func visitDocumentTitle(_ title: String)
    func visit(_ paragraph: PublishingParagraph)
    func visit(_ link: PublishingLink)
    func visit(_ image: PublishingImage)
    func visit(_ table: PublishingTable)
}

public protocol PublishingDocumentElement: Sendable {
    func accept(_ visitor: any PublishingDocumentVisiting)
}

extension PublishingParagraph: PublishingDocumentElement {
    public func accept(_ visitor: any PublishingDocumentVisiting) {
        visitor.visit(self)
    }
}

extension PublishingLink: PublishingDocumentElement {
    public func accept(_ visitor: any PublishingDocumentVisiting) {
        visitor.visit(self)
    }
}

extension PublishingImage: PublishingDocumentElement {
    public func accept(_ visitor: any PublishingDocumentVisiting) {
        visitor.visit(self)
    }
}

extension PublishingTable: PublishingDocumentElement {
    public func accept(_ visitor: any PublishingDocumentVisiting) {
        visitor.visit(self)
    }
}

public struct PublishingArticle: Sendable {
    public let title: String
    public let elements: [any PublishingDocumentElement]

    public init(
        title: String,
        elements: [any PublishingDocumentElement]
    ) {
        precondition(!title.isEmpty, "A publishing article needs a title")

        self.title = title
        self.elements = elements
    }

    public func accept(_ visitor: any PublishingDocumentVisiting) {
        visitor.visitDocumentTitle(title)
        for element in elements {
            element.accept(visitor)
        }
    }
}

public final class PublishingAccessibilityVisitor: PublishingDocumentVisiting {
    public private(set) var findings: [DocumentAccessibilityFinding] = []
    private var previousHeadingLevel = 0

    public var report: DocumentAccessibilityReport {
        DocumentAccessibilityReport(findings: findings)
    }

    public init() {}

    public func visitDocumentTitle(_ title: String) {}

    public func visit(_ paragraph: PublishingParagraph) {
        if paragraph.text.normalizedPublishingText.isEmpty {
            findings.append(.emptyParagraph(nodeID: paragraph.id))
        }

        guard case let .heading(level) = paragraph.role else {
            return
        }

        if level > previousHeadingLevel + 1 {
            findings.append(
                .skippedHeadingLevel(
                    nodeID: paragraph.id,
                    from: previousHeadingLevel,
                    to: level
                )
            )
        }
        previousHeadingLevel = level
    }

    public func visit(_ link: PublishingLink) {
        let ambiguousLabels = ["click here", "link", "more", "read more"]
        let label = link.label.normalizedPublishingText.lowercased()

        if label.isEmpty || ambiguousLabels.contains(label) {
            findings.append(.ambiguousLinkLabel(nodeID: link.id))
        }
    }

    public func visit(_ image: PublishingImage) {
        let alternativeText = image.alternativeText?
            .normalizedPublishingText ?? ""

        if image.isDecorative, !alternativeText.isEmpty {
            findings.append(.redundantAlternativeText(nodeID: image.id))
        } else if !image.isDecorative, alternativeText.isEmpty {
            findings.append(.missingAlternativeText(nodeID: image.id))
        }
    }

    public func visit(_ table: PublishingTable) {
        let caption = table.caption?.normalizedPublishingText ?? ""
        if caption.isEmpty {
            findings.append(.missingTableCaption(nodeID: table.id))
        }

        let hasUsableHeaders = !table.columnHeaders.isEmpty
            && table.columnHeaders.allSatisfy {
                !$0.normalizedPublishingText.isEmpty
            }
        if !hasUsableHeaders {
            findings.append(.missingTableHeaders(nodeID: table.id))
        }

        guard !table.columnHeaders.isEmpty else {
            return
        }

        for (index, row) in table.rows.enumerated()
        where row.count != table.columnHeaders.count {
            findings.append(
                .inconsistentTableRow(
                    nodeID: table.id,
                    row: index,
                    expectedColumns: table.columnHeaders.count,
                    actualColumns: row.count
                )
            )
        }
    }
}

public final class PublishingPlainTextVisitor: PublishingDocumentVisiting {
    private var lines: [String] = []

    public var text: String {
        lines.joined(separator: "\n")
    }

    public init() {}

    public func visitDocumentTitle(_ title: String) {
        lines.append(title)
    }

    public func visit(_ paragraph: PublishingParagraph) {
        append(paragraph.text)
    }

    public func visit(_ link: PublishingLink) {
        append(link.label)
    }

    public func visit(_ image: PublishingImage) {
        guard !image.isDecorative else {
            return
        }
        append(image.alternativeText)
    }

    public func visit(_ table: PublishingTable) {
        append(table.caption)
        append(table.columnHeaders.joined(separator: " | "))
        for row in table.rows {
            append(row.joined(separator: " | "))
        }
    }

    private func append(_ candidate: String?) {
        guard let candidate else {
            return
        }

        let normalized = candidate.normalizedPublishingText
        if !normalized.isEmpty {
            lines.append(normalized)
        }
    }
}

public final class PublishingLocalizationVisitor: PublishingDocumentVisiting {
    public private(set) var entries: [PublishingLocalizationEntry] = []

    public init() {}

    public func visitDocumentTitle(_ title: String) {
        append(title, nodeID: nil, field: .documentTitle)
    }

    public func visit(_ paragraph: PublishingParagraph) {
        append(
            paragraph.text,
            nodeID: paragraph.id,
            field: .paragraphText
        )
    }

    public func visit(_ link: PublishingLink) {
        append(link.label, nodeID: link.id, field: .linkLabel)
    }

    public func visit(_ image: PublishingImage) {
        append(
            image.alternativeText,
            nodeID: image.id,
            field: .imageAlternativeText(assetName: image.assetName)
        )
    }

    public func visit(_ table: PublishingTable) {
        append(table.caption, nodeID: table.id, field: .tableCaption)

        for (index, header) in table.columnHeaders.enumerated() {
            append(
                header,
                nodeID: table.id,
                field: .tableColumnHeader(index: index)
            )
        }

        for (rowIndex, row) in table.rows.enumerated() {
            for (columnIndex, cell) in row.enumerated() {
                append(
                    cell,
                    nodeID: table.id,
                    field: .tableCell(row: rowIndex, column: columnIndex)
                )
            }
        }
    }

    private func append(
        _ candidate: String?,
        nodeID: String?,
        field: PublishingLocalizationField
    ) {
        guard let candidate else {
            return
        }

        let normalized = candidate.normalizedPublishingText
        if !normalized.isEmpty {
            entries.append(
                PublishingLocalizationEntry(
                    nodeID: nodeID,
                    field: field,
                    sourceText: normalized
                )
            )
        }
    }
}

private extension String {
    var normalizedPublishingText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
