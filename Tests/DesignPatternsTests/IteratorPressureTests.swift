import DesignPatterns
import Testing

@Suite("Iterator pressure")
struct IteratorPressureTests {
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

    private static var traversalOutcomes: [PhotoLibraryPageOutcome] {
        [
            page([sunrise], nextCursor: firstCursor),
            page([], nextCursor: secondCursor),
            page([harbour, market], nextCursor: nil)
        ]
    }

    @Suite("Background metadata indexing")
    struct BackgroundMetadataIndexing {
        @Test("Traverses an empty intermediate page until the missing cursor")
        func traversesUntilTerminalCursor() async throws {
            var job = DirectPhotoMetadataIndexingJob(
                api: ScriptedPhotoLibraryAPI(
                    outcomes: IteratorPressureTests.traversalOutcomes
                )
            )

            try await job.indexAllPhotos()

            #expect(
                job.indexedPhotos == [
                    IteratorPressureTests.sunrise,
                    IteratorPressureTests.harbour,
                    IteratorPressureTests.market
                ]
            )
            #expect(job.isComplete)
            #expect(
                job.api.requestedCursors == [
                    nil,
                    IteratorPressureTests.firstCursor,
                    IteratorPressureTests.secondCursor
                ]
            )
        }

        @Test("Treats rate limiting as a terminal job failure")
        func propagatesRateLimit() async {
            var job = DirectPhotoMetadataIndexingJob(
                api: ScriptedPhotoLibraryAPI(
                    outcomes: [
                        .rateLimited(
                            retryAfterSeconds: IteratorPressureTests.retryDelay
                        )
                    ]
                )
            )

            await #expect(
                throws: PhotoLibraryError.rateLimited(
                    retryAfterSeconds: IteratorPressureTests.retryDelay
                )
            ) {
                try await job.indexAllPhotos()
            }

            #expect(job.indexedPhotos.isEmpty)
            #expect(job.isComplete == false)
            #expect(job.api.requestedCursors == [nil])
        }

        @Test("Stops before remote work when its task is cancelled")
        func honorsCancellation() async {
            let task = Task {
                var job = DirectPhotoMetadataIndexingJob(
                    api: ScriptedPhotoLibraryAPI(
                        outcomes: IteratorPressureTests.traversalOutcomes
                    )
                )
                withUnsafeCurrentTask { currentTask in
                    currentTask?.cancel()
                }

                do {
                    try await job.indexAllPhotos()
                    Issue.record("A cancelled indexing job unexpectedly completed")
                } catch is CancellationError {
                    // Cancellation is the expected terminal result for this job.
                } catch {
                    Issue.record("Unexpected error: \(error)")
                }
                return job
            }

            let cancelledJob = await task.value

            #expect(cancelledJob.indexedPhotos.isEmpty)
            #expect(cancelledJob.isComplete == false)
            #expect(cancelledJob.api.requestedCursors.isEmpty)
        }
    }

    @Suite("Early photo selection")
    struct EarlyPhotoSelection {
        @Test("Stops after its requested count without draining the library")
        func stopsEarly() async throws {
            var workflow = DirectPhotoSelectionWorkflow(
                api: ScriptedPhotoLibraryAPI(
                    outcomes: [
                        IteratorPressureTests.page(
                            [
                                IteratorPressureTests.sunrise,
                                IteratorPressureTests.harbour
                            ],
                            nextCursor: IteratorPressureTests.firstCursor
                        ),
                        IteratorPressureTests.page(
                            [
                                IteratorPressureTests.market,
                                IteratorPressureTests.station
                            ],
                            nextCursor: IteratorPressureTests.secondCursor
                        ),
                        IteratorPressureTests.page(
                            [],
                            nextCursor: nil
                        )
                    ]
                )
            )

            let selection = try await workflow.selectFirst(3)

            #expect(
                selection == [
                    IteratorPressureTests.sunrise,
                    IteratorPressureTests.harbour,
                    IteratorPressureTests.market
                ]
            )
            #expect(workflow.reachedLibraryEnd == false)
            #expect(
                workflow.api.requestedCursors == [
                    nil,
                    IteratorPressureTests.firstCursor
                ]
            )
        }

        @Test("Retries one rate limit with the same cursor")
        func retriesRateLimitOnce() async throws {
            var workflow = DirectPhotoSelectionWorkflow(
                api: ScriptedPhotoLibraryAPI(
                    outcomes: [
                        IteratorPressureTests.page(
                            [IteratorPressureTests.sunrise],
                            nextCursor: IteratorPressureTests.firstCursor
                        ),
                        .rateLimited(
                            retryAfterSeconds: IteratorPressureTests.retryDelay
                        ),
                        IteratorPressureTests.page(
                            [IteratorPressureTests.harbour],
                            nextCursor: nil
                        )
                    ]
                )
            )

            let selection = try await workflow.selectFirst(2)

            #expect(
                selection == [
                    IteratorPressureTests.sunrise,
                    IteratorPressureTests.harbour
                ]
            )
            #expect(workflow.reachedLibraryEnd)
            #expect(
                workflow.api.requestedCursors == [
                    nil,
                    IteratorPressureTests.firstCursor,
                    IteratorPressureTests.firstCursor
                ]
            )
        }

        @Test("Propagates a second rate limit instead of retrying forever")
        func boundsRateLimitRetry() async {
            var workflow = DirectPhotoSelectionWorkflow(
                api: ScriptedPhotoLibraryAPI(
                    outcomes: [
                        .rateLimited(
                            retryAfterSeconds: IteratorPressureTests.retryDelay
                        ),
                        .rateLimited(
                            retryAfterSeconds: IteratorPressureTests.retryDelay
                        )
                    ]
                )
            )

            await #expect(
                throws: PhotoLibraryError.rateLimited(
                    retryAfterSeconds: IteratorPressureTests.retryDelay
                )
            ) {
                try await workflow.selectFirst(1)
            }

            #expect(workflow.selectedPhotos.isEmpty)
            #expect(workflow.reachedLibraryEnd == false)
            #expect(workflow.api.requestedCursors == [nil, nil])
        }

        @Test("Stops before remote work when its task is cancelled")
        func honorsCancellation() async {
            let task = Task {
                var workflow = DirectPhotoSelectionWorkflow(
                    api: ScriptedPhotoLibraryAPI(
                        outcomes: IteratorPressureTests.traversalOutcomes
                    )
                )
                withUnsafeCurrentTask { currentTask in
                    currentTask?.cancel()
                }

                do {
                    _ = try await workflow.selectFirst(1)
                    Issue.record("A cancelled selection unexpectedly completed")
                } catch is CancellationError {
                    // Cancellation is the expected terminal result here too.
                } catch {
                    Issue.record("Unexpected error: \(error)")
                }
                return workflow
            }

            let cancelledWorkflow = await task.value

            #expect(cancelledWorkflow.selectedPhotos.isEmpty)
            #expect(cancelledWorkflow.reachedLibraryEnd == false)
            #expect(cancelledWorkflow.api.requestedCursors.isEmpty)
        }
    }
}
