import Foundation

public class ReadingListImportTemplate {
    public let source: ReadingListImportSource

    fileprivate init(source: ReadingListImportSource) {
        self.source = source
    }

    public final func importEntries(
        from payload: Data,
        into library: inout ReadingListLibrary
    ) throws -> ReadingListImportReport {
        guard !payload.isEmpty else {
            throw ReadingListImportError.emptyPayload(source: source)
        }

        let batch = try decodeEligibleCandidates(from: payload)
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

    fileprivate func decodeEligibleCandidates(
        from payload: Data
    ) throws -> DecodedReadingListBatch {
        throw ReadingListImportError.unreadablePayload(source: source)
    }

    private func normalize(
        _ candidate: TemplateReadingListCandidate
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

public final class SafariReadingListImporter: ReadingListImportTemplate {
    public init() {
        super.init(source: .safari)
    }

    fileprivate override func decodeEligibleCandidates(
        from payload: Data
    ) throws -> DecodedReadingListBatch {
        let archive: TemplateSafariReadingListArchive
        do {
            archive = try PropertyListDecoder().decode(
                TemplateSafariReadingListArchive.self,
                from: payload
            )
        } catch {
            throw ReadingListImportError.unreadablePayload(source: source)
        }

        return DecodedReadingListBatch(
            decodedRecordCount: archive.bookmarks.count,
            candidates: archive.bookmarks
                .filter(\.isReadingListItem)
                .map {
                    TemplateReadingListCandidate(
                        title: $0.title,
                        urlString: $0.url
                    )
                }
        )
    }
}

public final class PocketReadingListImporter: ReadingListImportTemplate {
    public init() {
        super.init(source: .pocket)
    }

    fileprivate override func decodeEligibleCandidates(
        from payload: Data
    ) throws -> DecodedReadingListBatch {
        let export: TemplatePocketReadingListExport
        do {
            export = try JSONDecoder().decode(
                TemplatePocketReadingListExport.self,
                from: payload
            )
        } catch {
            throw ReadingListImportError.unreadablePayload(source: source)
        }

        return DecodedReadingListBatch(
            decodedRecordCount: export.items.count,
            candidates: export.items
                .filter { $0.status == .unread }
                .map {
                    TemplateReadingListCandidate(
                        title: $0.resolvedTitle,
                        urlString: $0.resolvedURL
                    )
                }
        )
    }
}

public final class RaindropReadingListImporter: ReadingListImportTemplate {
    public init() {
        super.init(source: .raindrop)
    }

    fileprivate override func decodeEligibleCandidates(
        from payload: Data
    ) throws -> DecodedReadingListBatch {
        let export: TemplateRaindropReadingListExport
        do {
            export = try JSONDecoder().decode(
                TemplateRaindropReadingListExport.self,
                from: payload
            )
        } catch {
            throw ReadingListImportError.unreadablePayload(source: source)
        }

        return DecodedReadingListBatch(
            decodedRecordCount: export.items.count,
            candidates: export.items
                .filter { $0.type == .article && !$0.removed }
                .map {
                    TemplateReadingListCandidate(
                        title: $0.title,
                        urlString: $0.link
                    )
                }
        )
    }
}

fileprivate struct DecodedReadingListBatch {
    let decodedRecordCount: Int
    let candidates: [TemplateReadingListCandidate]
}

fileprivate struct TemplateReadingListCandidate {
    let title: String
    let urlString: String
}

private struct TemplateSafariReadingListArchive: Decodable {
    let bookmarks: [TemplateSafariBookmark]
}

private struct TemplateSafariBookmark: Decodable {
    let title: String
    let url: String
    let isReadingListItem: Bool
}

private struct TemplatePocketReadingListExport: Decodable {
    let items: [TemplatePocketItem]
}

private struct TemplatePocketItem: Decodable {
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

private struct TemplateRaindropReadingListExport: Decodable {
    let items: [TemplateRaindropItem]
}

private struct TemplateRaindropItem: Decodable {
    enum ItemType: String, Decodable {
        case article
        case link
    }

    let title: String
    let link: String
    let type: ItemType
    let removed: Bool
}
