import DesignPatterns
import Foundation
import Testing

@Suite("Template Method")
struct TemplateMethodTests {
    private static let existingEntry = ReadingListEntry(
        title: "Already saved",
        canonicalURL: "https://example.com/swift"
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
              <key>title</key><string>  Swift article  </string>
              <key>url</key><string>HTTPS://EXAMPLE.COM/swift#section</string>
              <key>isReadingListItem</key><true/>
            </dict>
            <dict>
              <key>title</key><string>Ordinary bookmark</string>
              <key>url</key><string>https://example.com/home</string>
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
              "resolved_url": "https://EXAMPLE.com/async/",
              "status": "unread"
            },
            {
              "resolved_title": "Archived",
              "resolved_url": "https://example.com/archive",
              "status": "archived"
            }
          ]
        }
        """.utf8
    )
    private static let raindropPayload = Data(
        """
        {
          "items": [
            {
              "title": "Structured concurrency",
              "link": "https://example.com/concurrency#tasks",
              "type": "article",
              "removed": false
            },
            {
              "title": "Removed article",
              "link": "https://example.com/removed",
              "type": "article",
              "removed": true
            },
            {
              "title": "Project home",
              "link": "https://example.com/project",
              "type": "link",
              "removed": false
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
              "title": "Valid first",
              "link": "https://example.com/valid",
              "type": "article",
              "removed": false
            },
            {
              "title": "Broken second",
              "link": "not a URL",
              "type": "article",
              "removed": false
            }
          ]
        }
        """.utf8
    )

    @Test("Safari varies decoding and selection inside the fixed import order")
    func importsSafariReadingListBookmarks() throws {
        let importer: ReadingListImportTemplate = SafariReadingListImporter()
        var library = ReadingListLibrary()

        let report = try importer.importEntries(
            from: Self.safariPayload,
            into: &library
        )

        #expect(
            library.entries == [
                ReadingListEntry(
                    title: "Swift article",
                    canonicalURL: "https://example.com/swift"
                )
            ]
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

    @Test("Pocket uses the shared title fallback after its own filtering")
    func importsUnreadPocketItems() throws {
        let importer: ReadingListImportTemplate = PocketReadingListImporter()
        var library = ReadingListLibrary()

        let report = try importer.importEntries(
            from: Self.pocketPayload,
            into: &library
        )

        #expect(
            library.entries == [
                ReadingListEntry(
                    title: "example.com",
                    canonicalURL: "https://example.com/async/"
                )
            ]
        )
        #expect(report.decodedRecordCount == 2)
        #expect(report.eligibleRecordCount == 1)
    }

    @Test("Raindrop keeps only active articles before shared processing")
    func importsActiveRaindropArticles() throws {
        let importer: ReadingListImportTemplate = RaindropReadingListImporter()
        var library = ReadingListLibrary()

        let report = try importer.importEntries(
            from: Self.raindropPayload,
            into: &library
        )

        #expect(
            library.entries == [
                ReadingListEntry(
                    title: "Structured concurrency",
                    canonicalURL: "https://example.com/concurrency"
                )
            ]
        )
        #expect(report.decodedRecordCount == 3)
        #expect(report.eligibleRecordCount == 1)
    }

    @Test("The template removes stored and in-batch canonical duplicates")
    func deduplicatesBeforeAppending() throws {
        let payload = Data(
            """
            {
              "items": [
                {
                  "resolved_title": "Stored duplicate",
                  "resolved_url": "https://example.com/swift#later",
                  "status": "unread"
                },
                {
                  "resolved_title": "Batch duplicate",
                  "resolved_url": "https://example.com/swift",
                  "status": "unread"
                },
                {
                  "resolved_title": "New article",
                  "resolved_url": "https://example.com/new",
                  "status": "unread"
                }
              ]
            }
            """.utf8
        )
        var library = ReadingListLibrary(entries: [Self.existingEntry])

        let report = try PocketReadingListImporter().importEntries(
            from: payload,
            into: &library
        )

        #expect(library.entries.count == 2)
        #expect(library.entries.last?.canonicalURL == "https://example.com/new")
        #expect(report.insertedCount == 1)
        #expect(report.duplicateCount == 2)
    }

    @Test("Normalization finishes for the whole batch before persistence")
    func keepsPersistenceAtomic() {
        var library = ReadingListLibrary(entries: [Self.existingEntry])
        let originalLibrary = library

        #expect(throws: ReadingListImportError.invalidURL("not a URL")) {
            try RaindropReadingListImporter().importEntries(
                from: Self.invalidRaindropPayload,
                into: &library
            )
        }
        #expect(library == originalLibrary)
    }

    @Test("Validation and decoding errors retain the concrete source")
    func mapsFailuresToTheProvider() {
        var library = ReadingListLibrary()

        #expect(throws: ReadingListImportError.emptyPayload(source: .safari)) {
            try SafariReadingListImporter().importEntries(
                from: Data(),
                into: &library
            )
        }
        #expect(
            throws: ReadingListImportError.unreadablePayload(source: .pocket)
        ) {
            try PocketReadingListImporter().importEntries(
                from: Data("not json".utf8),
                into: &library
            )
        }
        #expect(library.entries.isEmpty)
    }
}
