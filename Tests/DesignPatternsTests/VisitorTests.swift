import DesignPatterns
import Testing

@Suite("Visitor")
struct VisitorTests {
    private static let article = PublishingArticle(
        title: "Barcelona accessibility guide",
        elements: [
            PublishingParagraph(
                id: "heading-introduction",
                text: "A city guide for every reader",
                role: .heading(level: 1)
            ),
            PublishingLink(
                id: "link-route-planner",
                label: "Open the step-free route planner",
                destination: "/routes/step-free"
            ),
            PublishingImage(
                id: "image-ramp-map",
                assetName: "gothic-quarter-ramp-map",
                alternativeText: "Map marking the accessible ramp entrance",
                isDecorative: false
            ),
            PublishingTable(
                id: "table-museum-hours",
                caption: "Accessible museum opening hours",
                columnHeaders: ["Museum", "Step-free hours"],
                rows: [["History Museum", "10:00–18:00"]]
            )
        ]
    )

    @Test("Each element dispatches to its concrete visitor overload in source order")
    func dispatchesConcreteElements() {
        let visitor = ElementKindVisitor()

        VisitorTests.article.accept(visitor)

        #expect(visitor.visits == ["title", "paragraph", "link", "image", "table"])
    }

    @Test("A new operation crosses all existing elements without editing them")
    func addsOperationWithoutChangingElements() {
        let visitor = OutboundDestinationVisitor()

        VisitorTests.article.accept(visitor)

        #expect(visitor.destinations == ["/routes/step-free"])
    }

    @Suite("Accessibility visitor")
    struct Accessibility {
        @Test("Preserves cross-element heading state and finding order")
        func auditsConcreteElements() {
            let article = PublishingArticle(
                title: "Incomplete city guide",
                elements: [
                    PublishingParagraph(
                        id: "heading-overview",
                        text: "Museum overview",
                        role: .heading(level: 1)
                    ),
                    PublishingParagraph(
                        id: "paragraph-empty",
                        text: "  ",
                        role: .body
                    ),
                    PublishingParagraph(
                        id: "heading-tickets",
                        text: "Accessible ticket desk",
                        role: .heading(level: 3)
                    ),
                    PublishingLink(
                        id: "link-ambiguous",
                        label: "Read more",
                        destination: "/accessibility"
                    ),
                    PublishingImage(
                        id: "image-entrance",
                        assetName: "museum-entrance",
                        alternativeText: nil,
                        isDecorative: false
                    ),
                    PublishingTable(
                        id: "table-opening-hours",
                        caption: nil,
                        columnHeaders: ["Museum", "Hours"],
                        rows: [["History Museum"]]
                    )
                ]
            )
            let visitor = PublishingAccessibilityVisitor()

            article.accept(visitor)

            #expect(
                visitor.report.findings == [
                    .emptyParagraph(nodeID: "paragraph-empty"),
                    .skippedHeadingLevel(
                        nodeID: "heading-tickets",
                        from: 1,
                        to: 3
                    ),
                    .ambiguousLinkLabel(nodeID: "link-ambiguous"),
                    .missingAlternativeText(nodeID: "image-entrance"),
                    .missingTableCaption(nodeID: "table-opening-hours"),
                    .inconsistentTableRow(
                        nodeID: "table-opening-hours",
                        row: 0,
                        expectedColumns: 2,
                        actualColumns: 1
                    )
                ]
            )
        }

        @Test("Accepts an article that satisfies every concrete rule")
        func acceptsAccessibleArticle() {
            let visitor = PublishingAccessibilityVisitor()

            VisitorTests.article.accept(visitor)

            #expect(visitor.report.passes)
        }
    }

    @Suite("Plain-text visitor")
    struct PlainText {
        @Test("Flattens all concrete elements in article order")
        func extractsSearchableText() {
            let visitor = PublishingPlainTextVisitor()

            VisitorTests.article.accept(visitor)

            #expect(
                visitor.text == """
                Barcelona accessibility guide
                A city guide for every reader
                Open the step-free route planner
                Map marking the accessible ramp entrance
                Accessible museum opening hours
                Museum | Step-free hours
                History Museum | 10:00–18:00
                """
            )
        }

        @Test("Keeps decorative image copy out of plain text")
        func excludesDecorativeImages() {
            let article = PublishingArticle(
                title: "Editorial divider",
                elements: [
                    PublishingImage(
                        id: "image-divider",
                        assetName: "warm-red-divider",
                        alternativeText: "Decorative red divider",
                        isDecorative: true
                    )
                ]
            )
            let visitor = PublishingPlainTextVisitor()

            article.accept(visitor)

            #expect(visitor.text == "Editorial divider")
        }
    }

    @Suite("Localization visitor")
    struct Localization {
        @Test("Retains field metadata while skipping blank authored copy")
        func inventoriesLocalizableFields() {
            let article = PublishingArticle(
                title: "Draft guide",
                elements: [
                    PublishingParagraph(
                        id: "paragraph-empty",
                        text: "  ",
                        role: .body
                    ),
                    PublishingImage(
                        id: "image-ramp-map",
                        assetName: "gothic-quarter-ramp-map",
                        alternativeText: "Map marking the accessible ramp entrance",
                        isDecorative: false
                    ),
                    PublishingTable(
                        id: "table-museum-hours",
                        caption: "Accessible museum opening hours",
                        columnHeaders: ["Museum"],
                        rows: [["History Museum"]]
                    )
                ]
            )
            let visitor = PublishingLocalizationVisitor()

            article.accept(visitor)

            #expect(
                visitor.entries == [
                    PublishingLocalizationEntry(
                        nodeID: nil,
                        field: .documentTitle,
                        sourceText: "Draft guide"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "image-ramp-map",
                        field: .imageAlternativeText(
                            assetName: "gothic-quarter-ramp-map"
                        ),
                        sourceText: "Map marking the accessible ramp entrance"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "table-museum-hours",
                        field: .tableCaption,
                        sourceText: "Accessible museum opening hours"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "table-museum-hours",
                        field: .tableColumnHeader(index: 0),
                        sourceText: "Museum"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "table-museum-hours",
                        field: .tableCell(row: 0, column: 0),
                        sourceText: "History Museum"
                    )
                ]
            )
        }
    }
}

private final class ElementKindVisitor: PublishingDocumentVisiting {
    private(set) var visits: [String] = []

    func visitDocumentTitle(_ title: String) {
        visits.append("title")
    }

    func visit(_ paragraph: PublishingParagraph) {
        visits.append("paragraph")
    }

    func visit(_ link: PublishingLink) {
        visits.append("link")
    }

    func visit(_ image: PublishingImage) {
        visits.append("image")
    }

    func visit(_ table: PublishingTable) {
        visits.append("table")
    }
}

private final class OutboundDestinationVisitor: PublishingDocumentVisiting {
    private(set) var destinations: [String] = []

    func visitDocumentTitle(_ title: String) {}
    func visit(_ paragraph: PublishingParagraph) {}

    func visit(_ link: PublishingLink) {
        destinations.append(link.destination)
    }

    func visit(_ image: PublishingImage) {}
    func visit(_ table: PublishingTable) {}
}
