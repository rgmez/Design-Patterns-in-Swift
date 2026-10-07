import DesignPatterns
import Testing

@Suite("Iterator")
struct IteratorTests {
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
    private static let station = LibraryPhoto(
        id: "photo-004",
        filename: "station.heic"
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

    @Test("Presents one ordered stream across remote page boundaries")
    func presentsOrderedStream() async throws {
        let sequence = PhotoLibrarySequence(
            api: ScriptedPhotoLibraryAPI(
                outcomes: [
                    Self.page([Self.sunrise], nextCursor: Self.firstCursor),
                    Self.page([], nextCursor: Self.secondCursor),
                    Self.page(
                        [Self.harbour, Self.market],
                        nextCursor: nil
                    )
                ]
            )
        )
        var photos: [LibraryPhoto] = []

        for try await photo in sequence {
            photos.append(photo)
        }

        #expect(photos == [Self.sunrise, Self.harbour, Self.market])
    }

    @Test("Hides cursors and crosses an empty intermediate page")
    func crossesEmptyIntermediatePage() async throws {
        let sequence = PhotoLibrarySequence(
            api: ScriptedPhotoLibraryAPI(
                outcomes: [
                    Self.page([Self.sunrise], nextCursor: Self.firstCursor),
                    Self.page([], nextCursor: Self.secondCursor),
                    Self.page([Self.harbour], nextCursor: nil)
                ]
            )
        )
        var iterator = sequence.makeAsyncIterator()

        let firstPhoto = try await iterator.next()
        let secondPhoto = try await iterator.next()
        let end = try await iterator.next()
        let repeatedEnd = try await iterator.next()

        #expect(firstPhoto == Self.sunrise)
        #expect(secondPhoto == Self.harbour)
        #expect(end == nil)
        #expect(repeatedEnd == nil)
        #expect(
            iterator.requestedCursors == [
                nil,
                Self.firstCursor,
                Self.secondCursor
            ]
        )
    }

    @Test("Keeps retry policy outside the iterator")
    func keepsRetryPolicyAtConsumer() async throws {
        let sequence = PhotoLibrarySequence(
            api: ScriptedPhotoLibraryAPI(
                outcomes: [
                    Self.page([Self.sunrise], nextCursor: Self.firstCursor),
                    .rateLimited(retryAfterSeconds: Self.retryDelay),
                    Self.page([Self.harbour], nextCursor: nil)
                ]
            )
        )
        var iterator = sequence.makeAsyncIterator()

        let firstPhoto = try await iterator.next()
        await #expect(
            throws: PhotoLibraryError.rateLimited(
                retryAfterSeconds: Self.retryDelay
            )
        ) {
            try await iterator.next()
        }
        let retriedPhoto = try await iterator.next()

        #expect(firstPhoto == Self.sunrise)
        #expect(retriedPhoto == Self.harbour)
        #expect(
            iterator.requestedCursors == [
                nil,
                Self.firstCursor,
                Self.firstCursor
            ]
        )
    }

    @Test("Stops remote work when a consumer exits early")
    func stopsWhenConsumerExitsEarly() async throws {
        let sequence = PhotoLibrarySequence(
            api: ScriptedPhotoLibraryAPI(
                outcomes: [
                    Self.page(
                        [Self.sunrise, Self.harbour],
                        nextCursor: Self.firstCursor
                    ),
                    Self.page(
                        [Self.market, Self.station],
                        nextCursor: Self.secondCursor
                    ),
                    Self.page([], nextCursor: nil)
                ]
            )
        )
        var iterator = sequence.makeAsyncIterator()
        var selectedPhotos: [LibraryPhoto] = []

        while selectedPhotos.count < 3,
              let photo = try await iterator.next() {
            selectedPhotos.append(photo)
        }

        #expect(
            selectedPhotos == [Self.sunrise, Self.harbour, Self.market]
        )
        #expect(iterator.requestedCursors == [nil, Self.firstCursor])
    }

    @Test("Checks cancellation before requesting the first page")
    func checksCancellationBeforeFetching() async {
        let sequence = PhotoLibrarySequence(
            api: ScriptedPhotoLibraryAPI(
                outcomes: [
                    Self.page([Self.sunrise], nextCursor: nil)
                ]
            )
        )
        let task = Task {
            var iterator = sequence.makeAsyncIterator()
            withUnsafeCurrentTask { currentTask in
                currentTask?.cancel()
            }

            do {
                _ = try await iterator.next()
                Issue.record("A cancelled iterator unexpectedly produced a photo")
            } catch is CancellationError {
                // Cancellation is the expected terminal result.
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            return iterator.requestedCursors
        }

        let requestedCursors = await task.value

        #expect(requestedCursors.isEmpty)
    }
}
