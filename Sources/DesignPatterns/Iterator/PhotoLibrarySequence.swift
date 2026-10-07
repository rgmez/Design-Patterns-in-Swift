public struct PhotoLibrarySequence: AsyncSequence, Sendable {
    public typealias Element = LibraryPhoto

    public struct AsyncIterator: AsyncIteratorProtocol, Sendable {
        private var api: ScriptedPhotoLibraryAPI
        private var bufferedPhotos: [LibraryPhoto] = []
        private var bufferedIndex = 0
        private var nextCursor: String?
        private var reachedEnd = false

        public var requestedCursors: [String?] {
            api.requestedCursors
        }

        fileprivate init(api: ScriptedPhotoLibraryAPI) {
            self.api = api
        }

        public mutating func next() async throws -> LibraryPhoto? {
            while true {
                try Task.checkCancellation()

                if bufferedIndex < bufferedPhotos.count {
                    let photo = bufferedPhotos[bufferedIndex]
                    bufferedIndex += 1
                    return photo
                }

                guard !reachedEnd else { return nil }

                let page = try await api.fetchPage(after: nextCursor)
                try Task.checkCancellation()

                bufferedPhotos = page.photos
                bufferedIndex = 0
                nextCursor = page.nextCursor
                reachedEnd = page.nextCursor == nil
            }
        }
    }

    private let api: ScriptedPhotoLibraryAPI

    public init(api: ScriptedPhotoLibraryAPI) {
        self.api = api
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(api: api)
    }
}
