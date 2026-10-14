import Foundation

public enum ReadingListImportSource: Equatable, Sendable {
    case safari
    case pocket
}

public enum ReadingListImportError: Error, Equatable, Sendable {
    case emptyPayload(source: ReadingListImportSource)
    case unreadablePayload(source: ReadingListImportSource)
    case invalidURL(String)
}

public struct ReadingListEntry: Equatable, Sendable {
    public let title: String
    public let canonicalURL: String

    public init(
        title: String,
        canonicalURL: String
    ) {
        precondition(!title.isEmpty, "A reading-list entry needs a title")
        precondition(!canonicalURL.isEmpty, "A reading-list entry needs a URL")

        self.title = title
        self.canonicalURL = canonicalURL
    }
}

public struct ReadingListLibrary: Equatable, Sendable {
    public private(set) var entries: [ReadingListEntry]

    public init(entries: [ReadingListEntry] = []) {
        precondition(
            Set(entries.map(\.canonicalURL)).count == entries.count,
            "A reading-list library cannot contain duplicate URLs"
        )

        self.entries = entries
    }

    mutating func append(contentsOf newEntries: [ReadingListEntry]) {
        entries.append(contentsOf: newEntries)
    }
}

public struct ReadingListImportReport: Equatable, Sendable {
    public let source: ReadingListImportSource
    public let decodedRecordCount: Int
    public let eligibleRecordCount: Int
    public let insertedCount: Int
    public let duplicateCount: Int

    public init(
        source: ReadingListImportSource,
        decodedRecordCount: Int,
        eligibleRecordCount: Int,
        insertedCount: Int,
        duplicateCount: Int
    ) {
        self.source = source
        self.decodedRecordCount = decodedRecordCount
        self.eligibleRecordCount = eligibleRecordCount
        self.insertedCount = insertedCount
        self.duplicateCount = duplicateCount
    }
}

public struct DirectReadingListImporter: Sendable {
    public init() {}

    public func importSafariArchive(
        _ payload: Data,
        into library: inout ReadingListLibrary
    ) throws -> ReadingListImportReport {
        try validate(payload, source: .safari)

        let archive: SafariReadingListArchive
        do {
            archive = try PropertyListDecoder().decode(
                SafariReadingListArchive.self,
                from: payload
            )
        } catch {
            throw ReadingListImportError.unreadablePayload(source: .safari)
        }

        let candidates = archive.bookmarks
            .filter(\.isReadingListItem)
            .map {
                ReadingListCandidate(
                    title: $0.title,
                    urlString: $0.url
                )
            }
        let normalizedEntries = try candidates.map(normalize)
        let uniqueEntries = entriesNotAlreadyStored(
            normalizedEntries,
            in: library
        )
        library.append(contentsOf: uniqueEntries)

        return ReadingListImportReport(
            source: .safari,
            decodedRecordCount: archive.bookmarks.count,
            eligibleRecordCount: candidates.count,
            insertedCount: uniqueEntries.count,
            duplicateCount: normalizedEntries.count - uniqueEntries.count
        )
    }

    public func importPocketExport(
        _ payload: Data,
        into library: inout ReadingListLibrary
    ) throws -> ReadingListImportReport {
        try validate(payload, source: .pocket)

        let export: PocketReadingListExport
        do {
            export = try JSONDecoder().decode(
                PocketReadingListExport.self,
                from: payload
            )
        } catch {
            throw ReadingListImportError.unreadablePayload(source: .pocket)
        }

        let candidates = export.items
            .filter { $0.status == .unread }
            .map {
                ReadingListCandidate(
                    title: $0.resolvedTitle,
                    urlString: $0.resolvedURL
                )
            }
        let normalizedEntries = try candidates.map(normalize)
        let uniqueEntries = entriesNotAlreadyStored(
            normalizedEntries,
            in: library
        )
        library.append(contentsOf: uniqueEntries)

        return ReadingListImportReport(
            source: .pocket,
            decodedRecordCount: export.items.count,
            eligibleRecordCount: candidates.count,
            insertedCount: uniqueEntries.count,
            duplicateCount: normalizedEntries.count - uniqueEntries.count
        )
    }

    private func validate(
        _ payload: Data,
        source: ReadingListImportSource
    ) throws {
        guard !payload.isEmpty else {
            throw ReadingListImportError.emptyPayload(source: source)
        }
    }

    private func normalize(
        _ candidate: ReadingListCandidate
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
        let title = trimmedTitle.isEmpty ? host : trimmedTitle

        return ReadingListEntry(
            title: title,
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

private struct ReadingListCandidate {
    let title: String
    let urlString: String
}

private struct SafariReadingListArchive: Decodable {
    let bookmarks: [SafariBookmark]
}

private struct SafariBookmark: Decodable {
    let title: String
    let url: String
    let isReadingListItem: Bool
}

private struct PocketReadingListExport: Decodable {
    let items: [PocketItem]
}

private struct PocketItem: Decodable {
    enum Status: String, Decodable {
        case unread
        case archived
    }

    let resolvedTitle: String
    let resolvedURL: String
    let status: Status

    private enum CodingKeys: String, CodingKey {
        case resolvedTitle = "resolved_title"
        case resolvedURL = "resolved_url"
        case status
    }
}
