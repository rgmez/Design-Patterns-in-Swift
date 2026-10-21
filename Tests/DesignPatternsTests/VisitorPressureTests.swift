import DesignPatterns
import Testing

@Suite("Visitor pressure")
struct VisitorPressureTests {
    private static let extractor = DirectDocumentPlainTextExtractor()
    private static let inventory = DirectDocumentLocalizationInventory()
    private static let document = PublishingDocument(
        title: "Barcelona accessibility guide",
        nodes: [
            .paragraph(
                PublishingParagraph(
                    id: "heading-introduction",
                    text: "A city guide for every reader",
                    role: .heading(level: 1)
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
                    rows: [["History Museum", "10:00–18:00"]]
                )
            )
        ]
    )

    @Suite("Plain-text extraction")
    struct PlainTextExtraction {
        @Test("Preserves source order while flattening every node kind")
        func extractsSearchableText() {
            let text = VisitorPressureTests.extractor.text(
                from: VisitorPressureTests.document
            )

            #expect(
                text == """
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

        @Test("Keeps decorative image copy out of search and share text")
        func excludesDecorativeImages() {
            let document = PublishingDocument(
                title: "Editorial divider",
                nodes: [
                    .image(
                        PublishingImage(
                            id: "image-divider",
                            assetName: "warm-red-divider",
                            alternativeText: "Decorative red divider",
                            isDecorative: true
                        )
                    )
                ]
            )

            #expect(
                VisitorPressureTests.extractor.text(from: document)
                    == "Editorial divider"
            )
        }
    }

    @Suite("Localization inventory")
    struct LocalizationInventory {
        @Test("Records authored copy with node and asset metadata")
        func inventoriesLocalizableFields() {
            let entries = VisitorPressureTests.inventory.entries(
                in: VisitorPressureTests.document
            )

            #expect(
                entries == [
                    PublishingLocalizationEntry(
                        nodeID: nil,
                        field: .documentTitle,
                        sourceText: "Barcelona accessibility guide"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "heading-introduction",
                        field: .paragraphText,
                        sourceText: "A city guide for every reader"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "link-route-planner",
                        field: .linkLabel,
                        sourceText: "Open the step-free route planner"
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
                        field: .tableColumnHeader(index: 1),
                        sourceText: "Step-free hours"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "table-museum-hours",
                        field: .tableCell(row: 0, column: 0),
                        sourceText: "History Museum"
                    ),
                    PublishingLocalizationEntry(
                        nodeID: "table-museum-hours",
                        field: .tableCell(row: 0, column: 1),
                        sourceText: "10:00–18:00"
                    )
                ]
            )
        }

        @Test("Skips missing and blank author-written strings")
        func omitsEmptyFields() {
            let document = PublishingDocument(
                title: "Draft guide",
                nodes: [
                    .paragraph(
                        PublishingParagraph(
                            id: "paragraph-empty",
                            text: "  ",
                            role: .body
                        )
                    ),
                    .image(
                        PublishingImage(
                            id: "image-divider",
                            assetName: "warm-red-divider",
                            alternativeText: nil,
                            isDecorative: true
                        )
                    )
                ]
            )

            #expect(
                VisitorPressureTests.inventory.entries(in: document) == [
                    PublishingLocalizationEntry(
                        nodeID: nil,
                        field: .documentTitle,
                        sourceText: "Draft guide"
                    )
                ]
            )
        }
    }
}
