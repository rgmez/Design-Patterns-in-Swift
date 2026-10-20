import DesignPatterns
import Testing

@Suite("Visitor problem")
struct VisitorProblemTests {
    private static let auditor = DirectDocumentAccessibilityAuditor()
    private static let decorativeDocumentTitle = "Editorial divider"
    private static let decorativeImageID = "image-divider"
    private static let decorativeAssetName = "warm-red-divider"
    private static let accessibleDocument = PublishingDocument(
        title: "Barcelona accessibility guide",
        nodes: [
            .paragraph(
                PublishingParagraph(
                    id: "heading-introduction",
                    text: "A city guide for every reader",
                    role: .heading(level: 1)
                )
            ),
            .paragraph(
                PublishingParagraph(
                    id: "paragraph-introduction",
                    text: "Plan a step-free route through the old town.",
                    role: .body
                )
            ),
            .link(
                PublishingLink(
                    id: "link-route-planner",
                    label: "Open the step-free route planner",
                    destination: "/routes/step-free"
                )
            ),
            .image(
                PublishingImage(
                    id: "image-ramp-map",
                    assetName: "gothic-quarter-ramp-map",
                    alternativeText: "Map marking the accessible ramp entrance",
                    isDecorative: false
                )
            ),
            .table(
                PublishingTable(
                    id: "table-museum-hours",
                    caption: "Accessible museum opening hours",
                    columnHeaders: ["Museum", "Step-free hours"],
                    rows: [
                        ["History Museum", "10:00–18:00"],
                        ["Design Museum", "10:00–20:00"]
                    ]
                )
            )
        ]
    )

    @Suite("Complete documents")
    struct CompleteDocuments {
        @Test("Accepts a document whose concrete nodes satisfy their rules")
        func acceptsAccessibleDocument() {
            let report = VisitorProblemTests.auditor.audit(
                VisitorProblemTests.accessibleDocument
            )

            #expect(report.passes)
            #expect(report.findings.isEmpty)
        }

        @Test("Preserves source order while auditing every concrete node")
        func reportsNodeSpecificFailuresInOrder() {
            let document = PublishingDocument(
                title: "Incomplete city guide",
                nodes: [
                    .paragraph(
                        PublishingParagraph(
                            id: "paragraph-empty",
                            text: "   ",
                            role: .body
                        )
                    ),
                    .link(
                        PublishingLink(
                            id: "link-ambiguous",
                            label: "Read more",
                            destination: "/accessibility"
                        )
                    ),
                    .image(
                        PublishingImage(
                            id: "image-entrance",
                            assetName: "museum-entrance",
                            alternativeText: nil,
                            isDecorative: false
                        )
                    ),
                    .table(
                        PublishingTable(
                            id: "table-opening-hours",
                            caption: nil,
                            columnHeaders: [],
                            rows: []
                        )
                    )
                ]
            )

            let report = VisitorProblemTests.auditor.audit(document)

            #expect(!report.passes)
            #expect(
                report.findings == [
                    .emptyParagraph(nodeID: "paragraph-empty"),
                    .ambiguousLinkLabel(nodeID: "link-ambiguous"),
                    .missingAlternativeText(nodeID: "image-entrance"),
                    .missingTableCaption(nodeID: "table-opening-hours"),
                    .missingTableHeaders(nodeID: "table-opening-hours")
                ]
            )
        }
    }

    @Suite("Cross-node rules")
    struct CrossNodeRules {
        @Test("Finds a heading level skipped across intervening body copy")
        func reportsSkippedHeadingLevel() {
            let document = PublishingDocument(
                title: "Museum guide",
                nodes: [
                    .paragraph(
                        PublishingParagraph(
                            id: "heading-overview",
                            text: "Museum overview",
                            role: .heading(level: 1)
                        )
                    ),
                    .paragraph(
                        PublishingParagraph(
                            id: "paragraph-overview",
                            text: "Practical information for your visit.",
                            role: .body
                        )
                    ),
                    .paragraph(
                        PublishingParagraph(
                            id: "heading-tickets",
                            text: "Accessible ticket desk",
                            role: .heading(level: 3)
                        )
                    )
                ]
            )

            #expect(
                VisitorProblemTests.auditor.audit(document).findings == [
                    .skippedHeadingLevel(
                        nodeID: "heading-tickets",
                        from: 1,
                        to: 3
                    )
                ]
            )
        }

        @Test("Reports every table row whose shape differs from its headers")
        func reportsInconsistentTableRows() {
            let document = PublishingDocument(
                title: "Transport guide",
                nodes: [
                    .table(
                        PublishingTable(
                            id: "table-stations",
                            caption: "Step-free stations",
                            columnHeaders: ["Station", "Lift", "Platform"],
                            rows: [
                                ["Sants", "Yes"],
                                ["Passeig de Gràcia", "Yes", "2"],
                                ["Catalunya", "No", "1", "North"]
                            ]
                        )
                    )
                ]
            )

            #expect(
                VisitorProblemTests.auditor.audit(document).findings == [
                    .inconsistentTableRow(
                        nodeID: "table-stations",
                        row: 0,
                        expectedColumns: 3,
                        actualColumns: 2
                    ),
                    .inconsistentTableRow(
                        nodeID: "table-stations",
                        row: 2,
                        expectedColumns: 3,
                        actualColumns: 4
                    )
                ]
            )
        }
    }

    @Suite("Image semantics")
    struct ImageSemantics {
        @Test("Allows decorative images without alternative text")
        func acceptsSilentDecorativeImage() {
            let document = PublishingDocument(
                title: VisitorProblemTests.decorativeDocumentTitle,
                nodes: [
                    .image(
                        PublishingImage(
                            id: VisitorProblemTests.decorativeImageID,
                            assetName: VisitorProblemTests.decorativeAssetName,
                            alternativeText: nil,
                            isDecorative: true
                        )
                    )
                ]
            )

            #expect(VisitorProblemTests.auditor.audit(document).passes)
        }

        @Test("Rejects alternative text that would announce decoration")
        func rejectsDescribedDecoration() {
            let document = PublishingDocument(
                title: VisitorProblemTests.decorativeDocumentTitle,
                nodes: [
                    .image(
                        PublishingImage(
                            id: VisitorProblemTests.decorativeImageID,
                            assetName: VisitorProblemTests.decorativeAssetName,
                            alternativeText: "Decorative red divider",
                            isDecorative: true
                        )
                    )
                ]
            )

            #expect(
                VisitorProblemTests.auditor.audit(document).findings == [
                    .redundantAlternativeText(
                        nodeID: VisitorProblemTests.decorativeImageID
                    )
                ]
            )
        }
    }
}
