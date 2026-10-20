import Foundation

public enum PublishingParagraphRole: Equatable, Sendable {
    case body
    case heading(level: Int)
}

public struct PublishingParagraph: Equatable, Sendable {
    public let id: String
    public let text: String
    public let role: PublishingParagraphRole

    public init(
        id: String,
        text: String,
        role: PublishingParagraphRole
    ) {
        precondition(!id.isEmpty, "A paragraph needs an identifier")
        if case let .heading(level) = role {
            precondition(
                (1...6).contains(level),
                "A heading level must be between 1 and 6"
            )
        }

        self.id = id
        self.text = text
        self.role = role
    }
}

public struct PublishingLink: Equatable, Sendable {
    public let id: String
    public let label: String
    public let destination: String

    public init(
        id: String,
        label: String,
        destination: String
    ) {
        precondition(!id.isEmpty, "A link needs an identifier")
        precondition(!destination.isEmpty, "A link needs a destination")

        self.id = id
        self.label = label
        self.destination = destination
    }
}

public struct PublishingImage: Equatable, Sendable {
    public let id: String
    public let assetName: String
    public let alternativeText: String?
    public let isDecorative: Bool

    public init(
        id: String,
        assetName: String,
        alternativeText: String?,
        isDecorative: Bool
    ) {
        precondition(!id.isEmpty, "An image needs an identifier")
        precondition(!assetName.isEmpty, "An image needs an asset name")

        self.id = id
        self.assetName = assetName
        self.alternativeText = alternativeText
        self.isDecorative = isDecorative
    }
}

public struct PublishingTable: Equatable, Sendable {
    public let id: String
    public let caption: String?
    public let columnHeaders: [String]
    public let rows: [[String]]

    public init(
        id: String,
        caption: String?,
        columnHeaders: [String],
        rows: [[String]]
    ) {
        precondition(!id.isEmpty, "A table needs an identifier")

        self.id = id
        self.caption = caption
        self.columnHeaders = columnHeaders
        self.rows = rows
    }
}

public enum PublishingDocumentNode: Equatable, Sendable {
    case paragraph(PublishingParagraph)
    case link(PublishingLink)
    case image(PublishingImage)
    case table(PublishingTable)
}

public struct PublishingDocument: Equatable, Sendable {
    public let title: String
    public let nodes: [PublishingDocumentNode]

    public init(
        title: String,
        nodes: [PublishingDocumentNode]
    ) {
        precondition(!title.isEmpty, "A publishing document needs a title")

        self.title = title
        self.nodes = nodes
    }
}

public enum DocumentAccessibilityFinding: Equatable, Sendable {
    case emptyParagraph(nodeID: String)
    case skippedHeadingLevel(nodeID: String, from: Int, to: Int)
    case ambiguousLinkLabel(nodeID: String)
    case missingAlternativeText(nodeID: String)
    case redundantAlternativeText(nodeID: String)
    case missingTableCaption(nodeID: String)
    case missingTableHeaders(nodeID: String)
    case inconsistentTableRow(
        nodeID: String,
        row: Int,
        expectedColumns: Int,
        actualColumns: Int
    )
}

public struct DocumentAccessibilityReport: Equatable, Sendable {
    public let findings: [DocumentAccessibilityFinding]

    public var passes: Bool {
        findings.isEmpty
    }

    public init(findings: [DocumentAccessibilityFinding]) {
        self.findings = findings
    }
}

public struct DirectDocumentAccessibilityAuditor: Sendable {
    public init() {}

    public func audit(
        _ document: PublishingDocument
    ) -> DocumentAccessibilityReport {
        var findings: [DocumentAccessibilityFinding] = []
        var previousHeadingLevel = 0

        for node in document.nodes {
            switch node {
            case let .paragraph(paragraph):
                findings.append(
                    contentsOf: auditParagraph(
                        paragraph,
                        previousHeadingLevel: &previousHeadingLevel
                    )
                )
            case let .link(link):
                findings.append(contentsOf: auditLink(link))
            case let .image(image):
                findings.append(contentsOf: auditImage(image))
            case let .table(table):
                findings.append(contentsOf: auditTable(table))
            }
        }

        return DocumentAccessibilityReport(findings: findings)
    }

    private func auditParagraph(
        _ paragraph: PublishingParagraph,
        previousHeadingLevel: inout Int
    ) -> [DocumentAccessibilityFinding] {
        var findings: [DocumentAccessibilityFinding] = []

        if paragraph.text.trimmedForAccessibility.isEmpty {
            findings.append(.emptyParagraph(nodeID: paragraph.id))
        }

        guard case let .heading(level) = paragraph.role else {
            return findings
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

        return findings
    }

    private func auditLink(
        _ link: PublishingLink
    ) -> [DocumentAccessibilityFinding] {
        let ambiguousLabels = ["click here", "link", "more", "read more"]
        let label = link.label.trimmedForAccessibility.lowercased()

        guard !label.isEmpty, !ambiguousLabels.contains(label) else {
            return [.ambiguousLinkLabel(nodeID: link.id)]
        }

        return []
    }

    private func auditImage(
        _ image: PublishingImage
    ) -> [DocumentAccessibilityFinding] {
        let alternativeText = image.alternativeText?
            .trimmedForAccessibility ?? ""

        if image.isDecorative, !alternativeText.isEmpty {
            return [.redundantAlternativeText(nodeID: image.id)]
        }
        if !image.isDecorative, alternativeText.isEmpty {
            return [.missingAlternativeText(nodeID: image.id)]
        }

        return []
    }

    private func auditTable(
        _ table: PublishingTable
    ) -> [DocumentAccessibilityFinding] {
        var findings: [DocumentAccessibilityFinding] = []
        let caption = table.caption?.trimmedForAccessibility ?? ""

        if caption.isEmpty {
            findings.append(.missingTableCaption(nodeID: table.id))
        }

        let hasUsableHeaders = !table.columnHeaders.isEmpty
            && table.columnHeaders.allSatisfy {
                !$0.trimmedForAccessibility.isEmpty
            }
        if !hasUsableHeaders {
            findings.append(.missingTableHeaders(nodeID: table.id))
        }

        guard !table.columnHeaders.isEmpty else {
            return findings
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

        return findings
    }
}

private extension String {
    var trimmedForAccessibility: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
