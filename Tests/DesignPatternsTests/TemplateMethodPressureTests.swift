import DesignPatterns
import Foundation
import Testing

@Suite("Template Method pressure")
struct TemplateMethodPressureTests {
    private static let existingEntry = ReadingListEntry(
        title: "Saved before import",
        canonicalURL: "https://example.com/already-saved"
    )
    private static let importedEntry = ReadingListEntry(
        title: "Structured concurrency",
        canonicalURL: "https://example.com/structured-concurrency"
    )
    private static let invalidURL = "not a URL"
    private static let importer = DirectReadingListImporter()
    private static let raindropPayload = Data(
        """
        {
          "items": [
            {
              "title": "  Structured concurrency  ",
              "link": "HTTPS://EXAMPLE.COM/structured-concurrency#tasks",
              "type": "article",
              "removed": false
            },
            {
              "title": "Duplicate article",
              "link": "https://example.com/structured-concurrency",
              "type": "article",
              "removed": false
            },
            {
              "title": "Project home",
              "link": "https://example.com/project",
              "type": "link",
              "removed": false
            },
            {
              "title": "Removed article",
              "link": "https://example.com/removed",
              "type": "article",
              "removed": true
            }
          ]
        }
        """.utf8
    )
    private static let invalidRaindropPayload = Data(
        """
        {
          "items": [
            {
              "title": "Valid before invalid",
              "link": "https://example.com/valid",
              "type": "article",
              "removed": false
            },
            {
              "title": "Broken article",
              "link": "not a URL",
              "type": "article",
              "removed": false
            }
          ]
        }
        """.utf8
    )

    @Suite("Provider growth")
    struct ProviderGrowth {
        @Test("Raindrop repeats the stable pipeline around its own projection")
        func importsActiveArticles() throws {
            var library = ReadingListLibrary(
                entries: [TemplateMethodPressureTests.existingEntry]
            )

            let report = try TemplateMethodPressureTests.importer
                .importRaindropExport(
                    TemplateMethodPressureTests.raindropPayload,
                    into: &library
                )

            #expect(
                library.entries == [
                    TemplateMethodPressureTests.existingEntry,
                    TemplateMethodPressureTests.importedEntry
                ]
            )
            #expect(
                report == ReadingListImportReport(
                    source: .raindrop,
                    decodedRecordCount: 4,
                    eligibleRecordCount: 2,
                    insertedCount: 1,
                    duplicateCount: 1
                )
            )
        }
    }

    @Suite("Stable safety rails")
    struct StableSafetyRails {
        @Test("Raindrop validates before attempting provider decoding")
        func validatesBeforeDecoding() {
            var library = ReadingListLibrary()

            #expect(
                throws: ReadingListImportError.emptyPayload(source: .raindrop)
            ) {
                try TemplateMethodPressureTests.importer
                    .importRaindropExport(Data(), into: &library)
            }
            #expect(library.entries.isEmpty)
        }

        @Test("Raindrop maps decoding failures before persistence")
        func mapsDecodingFailure() {
            var library = ReadingListLibrary(
                entries: [TemplateMethodPressureTests.existingEntry]
            )
            let originalLibrary = library

            #expect(
                throws: ReadingListImportError.unreadablePayload(
                    source: .raindrop
                )
            ) {
                try TemplateMethodPressureTests.importer.importRaindropExport(
                    Data("not json".utf8),
                    into: &library
                )
            }
            #expect(library == originalLibrary)
        }

        @Test("Raindrop normalizes the complete batch before persistence")
        func preservesAtomicPersistence() {
            var library = ReadingListLibrary(
                entries: [TemplateMethodPressureTests.existingEntry]
            )
            let originalLibrary = library

            #expect(
                throws: ReadingListImportError.invalidURL(
                    TemplateMethodPressureTests.invalidURL
                )
            ) {
                try TemplateMethodPressureTests.importer.importRaindropExport(
                    TemplateMethodPressureTests.invalidRaindropPayload,
                    into: &library
                )
            }
            #expect(library == originalLibrary)
        }
    }
}
