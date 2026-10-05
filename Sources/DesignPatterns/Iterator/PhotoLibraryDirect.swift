public struct LibraryPhoto: Equatable, Sendable {
    public let id: String
    public let filename: String

    public init(id: String, filename: String) {
        precondition(!id.isEmpty, "A remote photo needs an identifier")
        precondition(!filename.isEmpty, "A remote photo needs a filename")
        self.id = id
        self.filename = filename
    }
}

public struct PhotoLibraryPage: Equatable, Sendable {
    public let photos: [LibraryPhoto]
    public let nextCursor: String?

    public init(
        photos: [LibraryPhoto],
        nextCursor: String?
    ) {
        self.photos = photos
        self.nextCursor = nextCursor
    }
}

public enum PhotoLibraryPageOutcome: Equatable, Sendable {
    case page(PhotoLibraryPage)
    case rateLimited(retryAfterSeconds: Int)
}

public enum PhotoLibraryError: Error, Equatable, Sendable {
    case rateLimited(retryAfterSeconds: Int)
    case missingScriptedResponse
}

public struct ScriptedPhotoLibraryAPI: Equatable, Sendable {
    public private(set) var requestedCursors: [String?] = []

    private var outcomes: [PhotoLibraryPageOutcome]

    public init(outcomes: [PhotoLibraryPageOutcome]) {
        self.outcomes = outcomes
    }

    public mutating func fetchPage(
        after cursor: String?
    ) async throws -> PhotoLibraryPage {
        await Task.yield()
        try Task.checkCancellation()

        requestedCursors.append(cursor)

        guard !outcomes.isEmpty else {
            throw PhotoLibraryError.missingScriptedResponse
        }

        switch outcomes.removeFirst() {
        case let .page(page):
            return page
        case let .rateLimited(retryAfterSeconds):
            throw PhotoLibraryError.rateLimited(
                retryAfterSeconds: retryAfterSeconds
            )
        }
    }
}

public struct DirectPhotoLibraryScreen: Equatable, Sendable {
    public private(set) var api: ScriptedPhotoLibraryAPI
    public private(set) var photos: [LibraryPhoto] = []
    public private(set) var canLoadNextPage = true

    private var nextCursor: String?

    public init(api: ScriptedPhotoLibraryAPI) {
        self.api = api
    }

    public mutating func loadNextPage() async throws {
        guard canLoadNextPage else { return }

        let page = try await api.fetchPage(after: nextCursor)

        photos.append(contentsOf: page.photos)
        nextCursor = page.nextCursor
        canLoadNextPage = page.nextCursor != nil
    }
}
