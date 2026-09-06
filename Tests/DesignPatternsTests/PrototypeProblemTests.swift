import DesignPatterns
import Testing

@Suite("Prototype problem")
struct PrototypeProblemTests {
    private static let sourceTitle = "Weekly product update"
    private static let copiedTitle = "Release retrospective"
    private static let sourceFontName = "New York"
    private static let copiedFontName = "SF Pro"
    private static let summarySectionID = "summary"
    private static let sourceSummaryHeading = "This week"
    private static let copiedSummaryHeading = "What shipped"
    private static let sourceSummaryParagraph = "Checkout reliability improved."
    private static let copiedSummaryParagraph = "Version 4.2 reached production."
    private static let sourceConfiguration = DocumentConfiguration(
        title: sourceTitle,
        textStyle: DocumentTextStyle(
            fontName: sourceFontName,
            alignment: .leading
        ),
        sections: [
            DocumentSectionConfiguration(
                id: summarySectionID,
                heading: sourceSummaryHeading,
                paragraphs: [sourceSummaryParagraph]
            )
        ]
    )

    @Suite("Ordinary value copies")
    struct OrdinaryValueCopies {
        @Test("Starts as the same complete configuration")
        func startsEquivalent() {
            let copy = PrototypeProblemTests.sourceConfiguration

            #expect(copy == PrototypeProblemTests.sourceConfiguration)
        }

        @Test("Keeps top-level edits independent")
        func keepsTopLevelEditsIndependent() {
            var copy = PrototypeProblemTests.sourceConfiguration

            copy.title = PrototypeProblemTests.copiedTitle

            #expect(
                PrototypeProblemTests.sourceConfiguration.title
                    == PrototypeProblemTests.sourceTitle
            )
            #expect(copy.title == PrototypeProblemTests.copiedTitle)
        }

        @Test("Keeps nested style edits independent")
        func keepsNestedStyleEditsIndependent() {
            var copy = PrototypeProblemTests.sourceConfiguration

            copy.textStyle.fontName = PrototypeProblemTests.copiedFontName
            copy.textStyle.alignment = .centered

            #expect(
                PrototypeProblemTests.sourceConfiguration.textStyle
                    == DocumentTextStyle(
                        fontName: PrototypeProblemTests.sourceFontName,
                        alignment: .leading
                    )
            )
            #expect(
                copy.textStyle
                    == DocumentTextStyle(
                        fontName: PrototypeProblemTests.copiedFontName,
                        alignment: .centered
                    )
            )
        }

        @Test("Keeps nested collection edits independent")
        func keepsNestedCollectionEditsIndependent() throws {
            var copy = PrototypeProblemTests.sourceConfiguration
            let sectionIndex = try #require(
                copy.sections.firstIndex {
                    $0.id == PrototypeProblemTests.summarySectionID
                }
            )

            copy.sections[sectionIndex].heading =
                PrototypeProblemTests.copiedSummaryHeading
            copy.sections[sectionIndex].paragraphs.append(
                PrototypeProblemTests.copiedSummaryParagraph
            )

            #expect(
                PrototypeProblemTests.sourceConfiguration.sections
                    == [
                        DocumentSectionConfiguration(
                            id: PrototypeProblemTests.summarySectionID,
                            heading: PrototypeProblemTests.sourceSummaryHeading,
                            paragraphs: [
                                PrototypeProblemTests.sourceSummaryParagraph
                            ]
                        )
                    ]
            )
            #expect(
                copy.sections[sectionIndex]
                    == DocumentSectionConfiguration(
                        id: PrototypeProblemTests.summarySectionID,
                        heading: PrototypeProblemTests.copiedSummaryHeading,
                        paragraphs: [
                            PrototypeProblemTests.sourceSummaryParagraph,
                            PrototypeProblemTests.copiedSummaryParagraph
                        ]
                    )
            )
        }
    }
}
