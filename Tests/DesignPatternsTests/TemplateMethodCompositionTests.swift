@testable import DesignPatterns
import Foundation
import Testing

@Suite("Template Method composition alternative")
struct TemplateMethodCompositionTests {
    private struct Candidate {
        let title: String
        let urlString: String
    }

    private struct Batch {
        let decodedRecordCount: Int
        let candidates: [Candidate]
    }

    private struct HigherOrderImporter {
        let source: ReadingListImportSource
        let decodeEligibleCandidates: (Data) throws -> Batch

        func importEntries(
            from payload: Data,
            into library: inout ReadingListLibrary
        ) throws -> ReadingListImportReport {
            guard !payload.isEmpty else {
                throw ReadingListImportError.emptyPayload(source: source)
            }

            let batch = try decodeEligibleCandidates(payload)
            let normalizedEntries = try batch.candidates.map(normalize)
            let uniqueEntries = entriesNotAlreadyStored(
                normalizedEntries,
                in: library
            )
            library.append(contentsOf: uniqueEntries)

            return ReadingListImportReport(
                source: source,
                decodedRecordCount: batch.decodedRecordCount,
                eligibleRecordCount: batch.candidates.count,
                insertedCount: uniqueEntries.count,
                duplicateCount: normalizedEntries.count - uniqueEntries.count
            )
        }

        private func normalize(
            _ candidate: Candidate
        ) throws -> ReadingListEntry {
            let rawURL = candidate.urlString.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard var components = URLComponents(string: rawURL),
                  let scheme = components.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  let host = components.host?.lowercased(),
                  !host.isEmpty else {
                throw ReadingListImportError.invalidURL(candidate.urlString)
            }

            components.scheme = scheme
            components.host = host
            components.fragment = nil
            if components.path == "/" {
                components.path = ""
            }
            if (scheme == "https" && components.port == 443)
                || (scheme == "http" && components.port == 80) {
                components.port = nil
            }

            guard let canonicalURL = components.url?.absoluteString else {
                throw ReadingListImportError.invalidURL(candidate.urlString)
            }

            let trimmedTitle = candidate.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return ReadingListEntry(
                title: trimmedTitle.isEmpty ? host : trimmedTitle,
                canonicalURL: canonicalURL
            )
        }

        private func entriesNotAlreadyStored(
            _ entries: [ReadingListEntry],
            in library: ReadingListLibrary
        ) -> [ReadingListEntry] {
            var knownURLs = Set(library.entries.map(\.canonicalURL))
            return entries.filter { entry in
                knownURLs.insert(entry.canonicalURL).inserted
            }
        }
    }

    private static let nonemptyPayload = Data([0x01])
    private static let expectedEntry = ReadingListEntry(
        title: "example.com",
        canonicalURL: "https://example.com/async"
    )

    @Suite("Fixed higher-order rail")
    struct FixedHigherOrderRail {
        @Test("Produces the same normalized report through one decode closure")
        func matchesTemplateBehavior() throws {
            let importer = HigherOrderImporter(source: .pocket) { _ in
                Batch(
                    decodedRecordCount: 2,
                    candidates: [
                        Candidate(
                            title: "",
                            urlString: "HTTPS://EXAMPLE.COM/async#tasks"
                        )
                    ]
                )
            }
            var library = ReadingListLibrary()

            let report = try importer.importEntries(
                from: TemplateMethodCompositionTests.nonemptyPayload,
                into: &library
            )

            #expect(library.entries == [TemplateMethodCompositionTests.expectedEntry])
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

        @Test("Normalizes the complete batch before one atomic append")
        func preservesAtomicity() {
            let importer = HigherOrderImporter(source: .raindrop) { _ in
                Batch(
                    decodedRecordCount: 2,
                    candidates: [
                        Candidate(
                            title: "Valid",
                            urlString: "https://example.com/valid"
                        ),
                        Candidate(
                            title: "Broken",
                            urlString: "not a URL"
                        )
                    ]
                )
            }
            var library = ReadingListLibrary(
                entries: [TemplateMethodCompositionTests.expectedEntry]
            )
            let originalLibrary = library

            #expect(throws: ReadingListImportError.invalidURL("not a URL")) {
                try importer.importEntries(
                    from: TemplateMethodCompositionTests.nonemptyPayload,
                    into: &library
                )
            }
            #expect(library == originalLibrary)
        }
    }
}
