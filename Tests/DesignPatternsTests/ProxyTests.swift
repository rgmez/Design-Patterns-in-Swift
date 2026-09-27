import DesignPatterns
import Testing

@Suite("Proxy")
struct ProxyTests {
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

    private static func makeSubject(
        serviceOutcomes: [LessonMediaServiceOutcome],
        playerOutcomes: [LessonPlayerOutcome]
    ) -> RemoteLessonPlayback {
        RemoteLessonPlayback(
            mediaService: ScriptedLessonMediaService(
                outcomes: serviceOutcomes
            ),
            player: ScriptedLessonPlayer(outcomes: playerOutcomes)
        )
    }

    private static func makeProxy(
        accessibleLessonIDs: Set<String> = [lessonID],
        serviceOutcomes: [LessonMediaServiceOutcome],
        playerOutcomes: [LessonPlayerOutcome]
    ) -> EntitledLessonPlaybackProxy<RemoteLessonPlayback> {
        EntitledLessonPlaybackProxy(
            entitlements: LessonEntitlements(
                accessibleLessonIDs: accessibleLessonIDs
            ),
            subject: makeSubject(
                serviceOutcomes: serviceOutcomes,
                playerOutcomes: playerOutcomes
            )
        )
    }

    @Suite("Shared playback boundary")
    struct SharedPlaybackBoundary {
        @Test("The real subject performs one remote playback attempt")
        func subjectPerformsOneAttempt() throws {
            let playbackURL = try ProxyTests.makeURL()
            var subject = ProxyTests.makeSubject(
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            let session = try subject.play(ProxyTests.makeLesson())

            #expect(session.playbackURL == playbackURL)
            #expect(
                subject.mediaService.requestedLessonIDs
                    == [ProxyTests.lessonID]
            )
            #expect(subject.player.attemptedURLs == [playbackURL])
        }

        @Test("The proxy substitutes for the subject on the same operation")
        func proxySubstitutesForSubject() throws {
            let playbackURL = try ProxyTests.makeURL()
            var playback = ProxyTests.makeProxy(
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            let session = try playback.play(ProxyTests.makeLesson())

            #expect(
                session == LessonPlaybackSession(
                    lessonID: ProxyTests.lessonID,
                    playbackURL: playbackURL
                )
            )
            #expect(
                playback.entitlements.accessChecks
                    == [ProxyTests.lessonID]
            )
        }
    }

    @Suite("Access control")
    struct AccessControl {
        @Test("Denied access never reaches the real subject")
        func deniesBeforeSubjectWork() throws {
            let playbackURL = try ProxyTests.makeURL()
            var playback = ProxyTests.makeProxy(
                accessibleLessonIDs: [],
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            #expect(
                throws: LessonPlaybackError.accessDenied(
                    lessonID: ProxyTests.lessonID
                )
            ) {
                try playback.play(ProxyTests.makeLesson())
            }
            #expect(
                playback.entitlements.accessChecks
                    == [ProxyTests.lessonID]
            )
            #expect(playback.subject.mediaService.requestedLessonIDs.isEmpty)
            #expect(playback.subject.player.attemptedURLs.isEmpty)
        }
    }

    @Suite("URL lifecycle")
    struct URLLifecycle {
        @Test("One expired URL invokes the real subject once more")
        func refreshesOnce() throws {
            let initialURL = try ProxyTests.makeURL()
            let refreshedURL = try ProxyTests.makeURL(
                ProxyTests.refreshedURLValue
            )
            var playback = ProxyTests.makeProxy(
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .started]
            )

            let session = try playback.play(ProxyTests.makeLesson())

            #expect(session.playbackURL == refreshedURL)
            #expect(
                playback.entitlements.accessChecks
                    == [ProxyTests.lessonID]
            )
            #expect(
                playback.subject.mediaService.requestedLessonIDs
                    == [ProxyTests.lessonID, ProxyTests.lessonID]
            )
            #expect(
                playback.subject.player.attemptedURLs
                    == [initialURL, refreshedURL]
            )
        }

        @Test("A second expiration remains terminal")
        func boundsRefresh() throws {
            let initialURL = try ProxyTests.makeURL()
            let refreshedURL = try ProxyTests.makeURL(
                ProxyTests.refreshedURLValue
            )
            var playback = ProxyTests.makeProxy(
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .expiredURL]
            )

            #expect(throws: LessonPlaybackError.expiredPlaybackURL) {
                try playback.play(ProxyTests.makeLesson())
            }
            #expect(
                playback.subject.mediaService.requestedLessonIDs.count == 2
            )
            #expect(
                playback.subject.player.attemptedURLs
                    == [initialURL, refreshedURL]
            )
        }
    }

    @Suite("Failure propagation")
    struct FailurePropagation {
        @Test("Media unavailability stops before the player")
        func preservesMediaFailure() throws {
            var playback = ProxyTests.makeProxy(
                serviceOutcomes: [.unavailable],
                playerOutcomes: [.started]
            )

            #expect(throws: LessonPlaybackError.mediaUnavailable) {
                try playback.play(ProxyTests.makeLesson())
            }
            #expect(playback.subject.player.attemptedURLs.isEmpty)
        }

        @Test("A non-expiration player failure is not retried")
        func preservesPlayerFailure() throws {
            let playbackURL = try ProxyTests.makeURL()
            var playback = ProxyTests.makeProxy(
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.unavailable]
            )

            #expect(throws: LessonPlaybackError.playerUnavailable) {
                try playback.play(ProxyTests.makeLesson())
            }
            #expect(
                playback.subject.mediaService.requestedLessonIDs
                    == [ProxyTests.lessonID]
            )
            #expect(playback.subject.player.attemptedURLs == [playbackURL])
        }
    }
}
