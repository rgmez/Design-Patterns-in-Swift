import DesignPatterns
import Foundation
import Testing

@Suite("Template Method problem")
struct TemplateMethodProblemTests {
    private static let existingTitle = "Swift concurrency field notes"
    private static let existingURL = "https://example.com/swift-concurrency"
    private static let newPocketTitle = "Testing async sequences"
    private static let newPocketURL = "https://example.com/async-sequences/"
    private static let invalidURL = "not a URL"
    private static let importer = DirectReadingListImporter()
    private static let existingEntry = ReadingListEntry(
        title: existingTitle,
        canonicalURL: existingURL
    )
    private static let safariPayload = Data(
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>bookmarks</key>
          <array>
            <dict>
              <key>title</key><string>  Swift concurrency field notes  </string>
              <key>url</key><string>HTTPS://EXAMPLE.COM/swift-concurrency#resume</string>
              <key>isReadingListItem</key><true/>
            </dict>
            <dict>
              <key>title</key><string>Team home page</string>
              <key>url</key><string>https://example.com/team</string>
              <key>isReadingListItem</key><false/>
            </dict>
          </array>
        </dict>
        </plist>
        """.utf8
    )
    private static let pocketPayload = Data(
        """
        {
          "items": [
            {
              "resolved_title": "",
              "resolved_url": "https://EXAMPLE.com/async-sequences/",
              "status": "unread"
            },
            {
              "resolved_title": "Finished article",
              "resolved_url": "https://example.com/archive",
              "status": "archived"
            }
          ]
        }
        """.utf8
    )
    private static let duplicatePocketPayload = Data(
        """
        {
          "items": [
            {
              "resolved_title": "Already saved",
              "resolved_url": "https://example.com/swift-concurrency#later",
              "status": "unread"
            },
            {
              "resolved_title": "Duplicate in this export",
              "resolved_url": "https://example.com/swift-concurrency",
              "status": "unread"
            },
            {
              "resolved_title": "Testing async sequences",
              "resolved_url": "https://example.com/async-sequences/",
              "status": "unread"
            }
          ]
        }
        """.utf8
    )
    private static let invalidPocketPayload = Data(
        """
        {
          "items": [
            {
              "resolved_title": "Valid before invalid",
              "resolved_url": "https://example.com/valid",
              "status": "unread"
            },
            {
              "resolved_title": "Broken URL",
              "resolved_url": "not a URL",
              "status": "unread"
            }
          ]
        }
        """.utf8
    )

    @Suite("Safari archive")
    struct SafariArchive {
        @Test("Imports only Reading List bookmarks through the ordered pipeline")
        func importsReadingListBookmarks() throws {
            var library = ReadingListLibrary()

            let report = try TemplateMethodProblemTests.importer
                .importSafariArchive(
                    TemplateMethodProblemTests.safariPayload,
                    into: &library
                )

            #expect(
                library.entries == [TemplateMethodProblemTests.existingEntry]
            )
            #expect(
                report == ReadingListImportReport(
                    source: .safari,
                    decodedRecordCount: 2,
                    eligibleRecordCount: 1,
                    insertedCount: 1,
                    duplicateCount: 0
                )
            )
        }
    }

    @Suite("Pocket export")
    struct PocketExport {
        @Test("Imports unread items and derives a title from the normalized host")
        func importsUnreadItems() throws {
            var library = ReadingListLibrary()

            let report = try TemplateMethodProblemTests.importer
                .importPocketExport(
                    TemplateMethodProblemTests.pocketPayload,
                    into: &library
                )

            #expect(
                library.entries == [
                    ReadingListEntry(
                        title: "example.com",
                        canonicalURL: TemplateMethodProblemTests.newPocketURL
                    )
                ]
            )
            #expect(
                report == ReadingListImportReport(
                    source: .pocket,
                    decodedRecordCount: 2,
                    eligibleRecordCount: 1,
                    insertedCount: 1,
                    duplicateCount: 0
                )
            )
        }
    }

    @Suite("Shared pipeline rules")
    struct SharedPipelineRules {
        @Test("Deduplicates against stored and earlier imported URLs")
        func deduplicatesBeforePersistence() throws {
            var library = ReadingListLibrary(
                entries: [TemplateMethodProblemTests.existingEntry]
            )

            let report = try TemplateMethodProblemTests.importer
                .importPocketExport(
                    TemplateMethodProblemTests.duplicatePocketPayload,
                    into: &library
                )

            #expect(
                library.entries == [
                    TemplateMethodProblemTests.existingEntry,
                    ReadingListEntry(
                        title: TemplateMethodProblemTests.newPocketTitle,
                        canonicalURL: TemplateMethodProblemTests.newPocketURL
                    )
                ]
            )
            #expect(report.insertedCount == 1)
            #expect(report.duplicateCount == 2)
        }

        @Test("Rejects an invalid URL without partially changing the library")
        func keepsPersistenceAtomic() {
            var library = ReadingListLibrary(
                entries: [TemplateMethodProblemTests.existingEntry]
            )
            let originalLibrary = library

            #expect(
                throws: ReadingListImportError.invalidURL(
                    TemplateMethodProblemTests.invalidURL
                )
            ) {
                try TemplateMethodProblemTests.importer.importPocketExport(
                    TemplateMethodProblemTests.invalidPocketPayload,
                    into: &library
                )
            }
            #expect(library == originalLibrary)
        }

        @Test("Rejects an empty payload before provider decoding")
        func rejectsEmptyPayload() {
            var library = ReadingListLibrary()

            #expect(
                throws: ReadingListImportError.emptyPayload(source: .safari)
            ) {
                try TemplateMethodProblemTests.importer.importSafariArchive(
                    Data(),
                    into: &library
                )
            }
            #expect(library.entries.isEmpty)
        }

        @Test("Maps malformed data to its provider without mutating storage")
        func identifiesUnreadableProviderPayload() {
            var library = ReadingListLibrary(
                entries: [TemplateMethodProblemTests.existingEntry]
            )
            let originalLibrary = library

            #expect(
                throws: ReadingListImportError.unreadablePayload(source: .pocket)
            ) {
                try TemplateMethodProblemTests.importer.importPocketExport(
                    Data("not json".utf8),
                    into: &library
                )
            }
            #expect(library == originalLibrary)
        }
    }
}
