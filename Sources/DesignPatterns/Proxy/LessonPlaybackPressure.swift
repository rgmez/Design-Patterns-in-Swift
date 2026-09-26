public struct DirectContinueWatchingShortcut: Equatable, Sendable {
    public private(set) var entitlements: LessonEntitlements
    public private(set) var mediaService: ScriptedLessonMediaService
    public private(set) var player: ScriptedLessonPlayer

    public init(
        entitlements: LessonEntitlements,
        mediaService: ScriptedLessonMediaService,
        player: ScriptedLessonPlayer
    ) {
        self.entitlements = entitlements
        self.mediaService = mediaService
        self.player = player
    }

    public mutating func resume(
        _ lesson: LessonVideo
    ) throws -> LessonPlaybackSession {
        guard entitlements.canAccess(lessonID: lesson.id) else {
            throw LessonPlaybackError.accessDenied(lessonID: lesson.id)
        }

        let initialURL = try mediaService.requestPlaybackURL(for: lesson.id)

        do {
            return try player.start(
                lessonID: lesson.id,
                playbackURL: initialURL
            )
        } catch LessonPlaybackError.expiredPlaybackURL {
            let refreshedURL = try mediaService.requestPlaybackURL(
                for: lesson.id
            )
            return try player.start(
                lessonID: lesson.id,
                playbackURL: refreshedURL
            )
        }
    }
}

public struct DirectNextLessonAutoplay: Equatable, Sendable {
    public private(set) var entitlements: LessonEntitlements
    public private(set) var mediaService: ScriptedLessonMediaService
    public private(set) var player: ScriptedLessonPlayer

    public init(
        entitlements: LessonEntitlements,
        mediaService: ScriptedLessonMediaService,
        player: ScriptedLessonPlayer
    ) {
        self.entitlements = entitlements
        self.mediaService = mediaService
        self.player = player
    }

    public mutating func startNextLesson(
        _ lesson: LessonVideo
    ) throws -> LessonPlaybackSession {
        guard entitlements.canAccess(lessonID: lesson.id) else {
            throw LessonPlaybackError.accessDenied(lessonID: lesson.id)
        }

        let initialURL = try mediaService.requestPlaybackURL(for: lesson.id)

        do {
            return try player.start(
                lessonID: lesson.id,
                playbackURL: initialURL
            )
        } catch LessonPlaybackError.expiredPlaybackURL {
            let refreshedURL = try mediaService.requestPlaybackURL(
                for: lesson.id
            )
            return try player.start(
                lessonID: lesson.id,
                playbackURL: refreshedURL
            )
        }
    }
}
