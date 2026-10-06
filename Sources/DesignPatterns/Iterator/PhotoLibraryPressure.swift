public struct DirectPhotoMetadataIndexingJob: Equatable, Sendable {
    public private(set) var api: ScriptedPhotoLibraryAPI
    public private(set) var indexedPhotos: [LibraryPhoto] = []
    public private(set) var isComplete = false

    private var nextCursor: String?

    public init(api: ScriptedPhotoLibraryAPI) {
        self.api = api
    }

    public mutating func indexAllPhotos() async throws {
        while !isComplete {
            try Task.checkCancellation()
            let page = try await api.fetchPage(after: nextCursor)
            try Task.checkCancellation()

            indexedPhotos.append(contentsOf: page.photos)
            nextCursor = page.nextCursor
            isComplete = page.nextCursor == nil
        }
    }
}

public struct DirectPhotoSelectionWorkflow: Equatable, Sendable {
    public private(set) var api: ScriptedPhotoLibraryAPI
    public private(set) var selectedPhotos: [LibraryPhoto] = []
    public private(set) var reachedLibraryEnd = false

    private var nextCursor: String?

    public init(api: ScriptedPhotoLibraryAPI) {
        self.api = api
    }

    public mutating func selectFirst(
        _ requestedPhotoCount: Int
    ) async throws -> [LibraryPhoto] {
        precondition(
            requestedPhotoCount > 0,
            "A photo selection needs at least one requested photo"
        )

        while selectedPhotos.count < requestedPhotoCount
            && !reachedLibraryEnd {
            try Task.checkCancellation()
            let page = try await fetchPageWithOneRateLimitRetry()
            try Task.checkCancellation()

            let remainingCount = requestedPhotoCount - selectedPhotos.count
            selectedPhotos.append(
                contentsOf: page.photos.prefix(remainingCount)
            )
            nextCursor = page.nextCursor
            reachedLibraryEnd = page.nextCursor == nil
        }

        return selectedPhotos
    }

    private mutating func fetchPageWithOneRateLimitRetry(
    ) async throws -> PhotoLibraryPage {
        do {
            return try await api.fetchPage(after: nextCursor)
        } catch PhotoLibraryError.rateLimited {
            try Task.checkCancellation()
            return try await api.fetchPage(after: nextCursor)
        }
    }
}
