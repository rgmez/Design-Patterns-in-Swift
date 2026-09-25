import DesignPatterns
import Testing

@Suite("Proxy problem")
struct ProxyProblemTests {
    private static let lessonID = "lesson-swift-concurrency"
    private static let lessonTitle = "Isolating mutable state"
    private static let initialURLValue =
        "https://media.example.com/lesson-swift-concurrency?token=old"
    private static let refreshedURLValue =
        "https://media.example.com/lesson-swift-concurrency?token=new"

    private static func makeLesson() throws -> LessonVideo {
        try LessonVideo(id: lessonID, title: lessonTitle)
    }

    private static func makeURL(
        _ value: String = initialURLValue
    ) throws -> LessonPlaybackURL {
        try LessonPlaybackURL(value)
    }

    private static func makeModel(
        accessibleLessonIDs: Set<String> = [lessonID],
        serviceOutcomes: [LessonMediaServiceOutcome],
        playerOutcomes: [LessonPlayerOutcome]
    ) -> DirectLessonPlaybackModel {
        DirectLessonPlaybackModel(
            entitlements: LessonEntitlements(
                accessibleLessonIDs: accessibleLessonIDs
            ),
            mediaService: ScriptedLessonMediaService(
                outcomes: serviceOutcomes
            ),
            player: ScriptedLessonPlayer(outcomes: playerOutcomes)
        )
    }

    @Suite("Authorized playback")
    struct AuthorizedPlayback {
        @Test("Starts playback with one authorized media URL")
        func startsPlayback() throws {
            let playbackURL = try ProxyProblemTests.makeURL()
            var model = ProxyProblemTests.makeModel(
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            let session = try model.play(ProxyProblemTests.makeLesson())

            #expect(
                session == LessonPlaybackSession(
                    lessonID: ProxyProblemTests.lessonID,
                    playbackURL: playbackURL
                )
            )
            #expect(
                model.entitlements.accessChecks
                    == [ProxyProblemTests.lessonID]
            )
            #expect(
                model.mediaService.requestedLessonIDs
                    == [ProxyProblemTests.lessonID]
            )
            #expect(model.player.attemptedURLs == [playbackURL])
        }

        @Test("Propagates media service unavailability before playback")
        func propagatesServiceFailure() throws {
            var model = ProxyProblemTests.makeModel(
                serviceOutcomes: [.unavailable],
                playerOutcomes: [.started]
            )

            #expect(throws: LessonPlaybackError.mediaUnavailable) {
                try model.play(ProxyProblemTests.makeLesson())
            }
            #expect(model.player.attemptedURLs.isEmpty)
        }

        @Test("Does not refresh a non-expiration player failure")
        func doesNotRefreshPlayerFailure() throws {
            let playbackURL = try ProxyProblemTests.makeURL()
            var model = ProxyProblemTests.makeModel(
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.unavailable]
            )

            #expect(throws: LessonPlaybackError.playerUnavailable) {
                try model.play(ProxyProblemTests.makeLesson())
            }
            #expect(model.mediaService.requestedLessonIDs.count == 1)
            #expect(model.player.attemptedURLs == [playbackURL])
        }
    }

    @Suite("Access control")
    struct AccessControl {
        @Test("Denies playback before requesting remote media")
        func deniesBeforeRemoteRequest() throws {
            let playbackURL = try ProxyProblemTests.makeURL()
            var model = ProxyProblemTests.makeModel(
                accessibleLessonIDs: [],
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            #expect(
                throws: LessonPlaybackError.accessDenied(
                    lessonID: ProxyProblemTests.lessonID
                )
            ) {
                try model.play(ProxyProblemTests.makeLesson())
            }
            #expect(
                model.entitlements.accessChecks
                    == [ProxyProblemTests.lessonID]
            )
            #expect(model.mediaService.requestedLessonIDs.isEmpty)
            #expect(model.player.attemptedURLs.isEmpty)
        }
    }

    @Suite("Expired URL")
    struct ExpiredURL {
        @Test("Refreshes once and starts with the replacement URL")
        func refreshesOnce() throws {
            let initialURL = try ProxyProblemTests.makeURL()
            let refreshedURL = try ProxyProblemTests.makeURL(
                ProxyProblemTests.refreshedURLValue
            )
            var model = ProxyProblemTests.makeModel(
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .started]
            )

            let session = try model.play(ProxyProblemTests.makeLesson())

            #expect(session.playbackURL == refreshedURL)
            #expect(
                model.mediaService.requestedLessonIDs
                    == [
                        ProxyProblemTests.lessonID,
                        ProxyProblemTests.lessonID
                    ]
            )
            #expect(
                model.player.attemptedURLs == [initialURL, refreshedURL]
            )
        }

        @Test("Stops after one refresh when the replacement also expired")
        func boundsRefresh() throws {
            let initialURL = try ProxyProblemTests.makeURL()
            let refreshedURL = try ProxyProblemTests.makeURL(
                ProxyProblemTests.refreshedURLValue
            )
            var model = ProxyProblemTests.makeModel(
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .expiredURL]
            )

            #expect(throws: LessonPlaybackError.expiredPlaybackURL) {
                try model.play(ProxyProblemTests.makeLesson())
            }
            #expect(model.mediaService.requestedLessonIDs.count == 2)
            #expect(
                model.player.attemptedURLs == [initialURL, refreshedURL]
            )
        }
    }
}

extension ProxyProblemTests {
    struct InvalidInput: Sendable, CustomTestStringConvertible {
        let name: String
        let operation: @Sendable () throws -> Void
        let expectedError: LessonPlaybackError

        var testDescription: String { name }
    }

    @Suite("Input validation")
    struct InputValidation {
        private static let scenarios = [
            InvalidInput(
                name: "missing lesson identifier",
                operation: {
                    _ = try LessonVideo(
                        id: "",
                        title: ProxyProblemTests.lessonTitle
                    )
                },
                expectedError: .missingLessonID
            ),
            InvalidInput(
                name: "missing lesson title",
                operation: {
                    _ = try LessonVideo(
                        id: ProxyProblemTests.lessonID,
                        title: ""
                    )
                },
                expectedError: .missingLessonTitle
            ),
            InvalidInput(
                name: "non-HTTPS playback URL",
                operation: {
                    _ = try LessonPlaybackURL("http://media.example.com/video")
                },
                expectedError: .invalidPlaybackURL
            )
        ]

        @Test("Rejects malformed playback input", arguments: scenarios)
        func rejectsMalformedInput(_ input: InvalidInput) {
            #expect(throws: input.expectedError) {
                try input.operation()
            }
        }
    }
}
