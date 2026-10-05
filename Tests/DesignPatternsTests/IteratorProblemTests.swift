import DesignPatterns
import Testing

@Suite("Iterator problem")
struct IteratorProblemTests {
    private static let firstCursor = "cursor-page-2"
    private static let secondCursor = "cursor-page-3"
    private static let retryDelay = 30
    private static let sunrise = LibraryPhoto(
        id: "photo-001",
        filename: "sunrise.heic"
    )
    private static let harbour = LibraryPhoto(
        id: "photo-002",
        filename: "harbour.heic"
    )
    private static let market = LibraryPhoto(
        id: "photo-003",
        filename: "market.heic"
    )

    private static func page(
        _ photos: [LibraryPhoto],
        nextCursor: String?
    ) -> PhotoLibraryPageOutcome {
        .page(
            PhotoLibraryPage(
                photos: photos,
                nextCursor: nextCursor
            )
        )
    }

    private static func makeScreen(
        outcomes: [PhotoLibraryPageOutcome]
    ) -> DirectPhotoLibraryScreen {
        DirectPhotoLibraryScreen(
            api: ScriptedPhotoLibraryAPI(outcomes: outcomes)
        )
    }

    @Suite("Page loading")
    struct PageLoading {
        @Test("Keeps a partial page and its continuation inside the screen")
        func loadsPartialPage() async throws {
            var screen = IteratorProblemTests.makeScreen(
                outcomes: [
                    IteratorProblemTests.page(
                        [IteratorProblemTests.sunrise],
                        nextCursor: IteratorProblemTests.firstCursor
                    )
                ]
            )

            try await screen.loadNextPage()

            #expect(screen.photos == [IteratorProblemTests.sunrise])
            #expect(screen.canLoadNextPage)
            #expect(screen.api.requestedCursors == [nil])
        }

        @Test("Preserves page order and stops after the terminal page")
        func reachesTerminalPage() async throws {
            var screen = IteratorProblemTests.makeScreen(
                outcomes: [
                    IteratorProblemTests.page(
                        [IteratorProblemTests.sunrise],
                        nextCursor: IteratorProblemTests.firstCursor
                    ),
                    IteratorProblemTests.page(
                        [IteratorProblemTests.harbour],
                        nextCursor: IteratorProblemTests.secondCursor
                    ),
                    IteratorProblemTests.page(
                        [IteratorProblemTests.market],
                        nextCursor: nil
                    )
                ]
            )

            try await screen.loadNextPage()
            try await screen.loadNextPage()
            try await screen.loadNextPage()
            try await screen.loadNextPage()

            #expect(
                screen.photos == [
                    IteratorProblemTests.sunrise,
                    IteratorProblemTests.harbour,
                    IteratorProblemTests.market
                ]
            )
            #expect(screen.canLoadNextPage == false)
            #expect(
                screen.api.requestedCursors == [
                    nil,
                    IteratorProblemTests.firstCursor,
                    IteratorProblemTests.secondCursor
                ]
            )
        }

        @Test("Completes an empty library after one request")
        func completesEmptyLibrary() async throws {
            var screen = IteratorProblemTests.makeScreen(
                outcomes: [
                    IteratorProblemTests.page([], nextCursor: nil)
                ]
            )

            try await screen.loadNextPage()
            try await screen.loadNextPage()

            #expect(screen.photos.isEmpty)
            #expect(screen.canLoadNextPage == false)
            #expect(screen.api.requestedCursors == [nil])
        }
    }

    @Suite("Rate limiting")
    struct RateLimiting {
        @Test("Retries the same cursor without losing visible photos")
        func retriesCurrentPage() async throws {
            var screen = IteratorProblemTests.makeScreen(
                outcomes: [
                    IteratorProblemTests.page(
                        [IteratorProblemTests.sunrise],
                        nextCursor: IteratorProblemTests.firstCursor
                    ),
                    .rateLimited(
                        retryAfterSeconds: IteratorProblemTests.retryDelay
                    ),
                    IteratorProblemTests.page(
                        [IteratorProblemTests.harbour],
                        nextCursor: nil
                    )
                ]
            )
            try await screen.loadNextPage()

            await #expect(
                throws: PhotoLibraryError.rateLimited(
                    retryAfterSeconds: IteratorProblemTests.retryDelay
                )
            ) {
                try await screen.loadNextPage()
            }

            #expect(screen.photos == [IteratorProblemTests.sunrise])
            #expect(screen.canLoadNextPage)

            try await screen.loadNextPage()

            #expect(
                screen.photos == [
                    IteratorProblemTests.sunrise,
                    IteratorProblemTests.harbour
                ]
            )
            #expect(
                screen.api.requestedCursors == [
                    nil,
                    IteratorProblemTests.firstCursor,
                    IteratorProblemTests.firstCursor
                ]
            )
        }
    }
}
