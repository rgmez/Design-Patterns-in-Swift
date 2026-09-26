import DesignPatterns
import Testing

@Suite("Proxy pressure")
struct ProxyPressureTests {
    private static let lessonID = "lesson-swift-concurrency"
    private static let lessonTitle = "Isolating mutable state"
    private static let initialURLValue =
        "https://media.example.com/lesson-swift-concurrency?token=old"
    private static let refreshedURLValue =
        "https://media.example.com/lesson-swift-concurrency?token=new"

    private static let entryPoints = PressureEntryPoint.allCases

    private static func makeLesson() throws -> LessonVideo {
        try LessonVideo(id: lessonID, title: lessonTitle)
    }

    private static func makeURL(
        _ value: String = initialURLValue
    ) throws -> LessonPlaybackURL {
        try LessonPlaybackURL(value)
    }

    private static func exercise(
        _ entryPoint: PressureEntryPoint,
        accessibleLessonIDs: Set<String> = [lessonID],
        serviceOutcomes: [LessonMediaServiceOutcome],
        playerOutcomes: [LessonPlayerOutcome]
    ) throws -> PressureObservation {
        let entitlements = LessonEntitlements(
            accessibleLessonIDs: accessibleLessonIDs
        )
        let mediaService = ScriptedLessonMediaService(
            outcomes: serviceOutcomes
        )
        let player = ScriptedLessonPlayer(outcomes: playerOutcomes)
        let lesson = try makeLesson()

        switch entryPoint {
        case .continueWatching:
            var shortcut = DirectContinueWatchingShortcut(
                entitlements: entitlements,
                mediaService: mediaService,
                player: player
            )
            let outcome = capture {
                try shortcut.resume(lesson)
            }
            return PressureObservation(
                outcome: outcome,
                accessChecks: shortcut.entitlements.accessChecks,
                requestedLessonIDs: shortcut.mediaService.requestedLessonIDs,
                attemptedURLs: shortcut.player.attemptedURLs
            )
        case .nextLessonAutoplay:
            var autoplay = DirectNextLessonAutoplay(
                entitlements: entitlements,
                mediaService: mediaService,
                player: player
            )
            let outcome = capture {
                try autoplay.startNextLesson(lesson)
            }
            return PressureObservation(
                outcome: outcome,
                accessChecks: autoplay.entitlements.accessChecks,
                requestedLessonIDs: autoplay.mediaService.requestedLessonIDs,
                attemptedURLs: autoplay.player.attemptedURLs
            )
        }
    }

    private static func capture(
        _ operation: () throws -> LessonPlaybackSession
    ) -> PressureOutcome {
        do {
            return .started(try operation())
        } catch let error as LessonPlaybackError {
            return .failed(error)
        } catch {
            Issue.record("Unexpected playback error: \(error)")
            return .unexpectedFailure
        }
    }

    @Suite("Access control")
    struct AccessControl {
        @Test(
            "Every entry point denies access before requesting media",
            arguments: ProxyPressureTests.entryPoints
        )
        func deniesBeforeRemoteWork(
            _ entryPoint: PressureEntryPoint
        ) throws {
            let playbackURL = try ProxyPressureTests.makeURL()
            let observation = try ProxyPressureTests.exercise(
                entryPoint,
                accessibleLessonIDs: [],
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.started]
            )

            #expect(
                observation.outcome == .failed(
                    .accessDenied(lessonID: ProxyPressureTests.lessonID)
                )
            )
            #expect(
                observation.accessChecks == [ProxyPressureTests.lessonID]
            )
            #expect(observation.requestedLessonIDs.isEmpty)
            #expect(observation.attemptedURLs.isEmpty)
        }
    }

    @Suite("URL lifecycle")
    struct URLLifecycle {
        @Test(
            "Every entry point replaces one expired URL",
            arguments: ProxyPressureTests.entryPoints
        )
        func refreshesOnce(
            _ entryPoint: PressureEntryPoint
        ) throws {
            let initialURL = try ProxyPressureTests.makeURL()
            let refreshedURL = try ProxyPressureTests.makeURL(
                ProxyPressureTests.refreshedURLValue
            )
            let observation = try ProxyPressureTests.exercise(
                entryPoint,
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .started]
            )

            #expect(
                observation.outcome == .started(
                    LessonPlaybackSession(
                        lessonID: ProxyPressureTests.lessonID,
                        playbackURL: refreshedURL
                    )
                )
            )
            #expect(
                observation.requestedLessonIDs
                    == [
                        ProxyPressureTests.lessonID,
                        ProxyPressureTests.lessonID
                    ]
            )
            #expect(observation.attemptedURLs == [initialURL, refreshedURL])
        }

        @Test(
            "Every entry point stops after the replacement also expires",
            arguments: ProxyPressureTests.entryPoints
        )
        func boundsRefresh(
            _ entryPoint: PressureEntryPoint
        ) throws {
            let initialURL = try ProxyPressureTests.makeURL()
            let refreshedURL = try ProxyPressureTests.makeURL(
                ProxyPressureTests.refreshedURLValue
            )
            let observation = try ProxyPressureTests.exercise(
                entryPoint,
                serviceOutcomes: [
                    .playbackURL(initialURL),
                    .playbackURL(refreshedURL)
                ],
                playerOutcomes: [.expiredURL, .expiredURL]
            )

            #expect(observation.outcome == .failed(.expiredPlaybackURL))
            #expect(observation.requestedLessonIDs.count == 2)
            #expect(observation.attemptedURLs == [initialURL, refreshedURL])
        }

        @Test(
            "Every entry point preserves non-expiration player failures",
            arguments: ProxyPressureTests.entryPoints
        )
        func doesNotRefreshPlayerFailure(
            _ entryPoint: PressureEntryPoint
        ) throws {
            let playbackURL = try ProxyPressureTests.makeURL()
            let observation = try ProxyPressureTests.exercise(
                entryPoint,
                serviceOutcomes: [.playbackURL(playbackURL)],
                playerOutcomes: [.unavailable]
            )

            #expect(observation.outcome == .failed(.playerUnavailable))
            #expect(
                observation.requestedLessonIDs
                    == [ProxyPressureTests.lessonID]
            )
            #expect(observation.attemptedURLs == [playbackURL])
        }
    }
}

enum PressureEntryPoint: CaseIterable, Sendable {
    case continueWatching
    case nextLessonAutoplay
}

extension PressureEntryPoint: CustomTestStringConvertible {
    var testDescription: String {
        switch self {
        case .continueWatching:
            "Continue Watching"
        case .nextLessonAutoplay:
            "Next Lesson autoplay"
        }
    }
}

private enum PressureOutcome: Equatable, Sendable {
    case started(LessonPlaybackSession)
    case failed(LessonPlaybackError)
    case unexpectedFailure
}

private struct PressureObservation: Equatable, Sendable {
    let outcome: PressureOutcome
    let accessChecks: [String]
    let requestedLessonIDs: [String]
    let attemptedURLs: [LessonPlaybackURL]
}
