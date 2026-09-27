public protocol LessonPlayback: Sendable {
    mutating func play(
        _ lesson: LessonVideo
    ) throws -> LessonPlaybackSession
}

public struct RemoteLessonPlayback: LessonPlayback, Sendable {
    public private(set) var mediaService: ScriptedLessonMediaService
    public private(set) var player: ScriptedLessonPlayer

    public init(
        mediaService: ScriptedLessonMediaService,
        player: ScriptedLessonPlayer
    ) {
        self.mediaService = mediaService
        self.player = player
    }

    public mutating func play(
        _ lesson: LessonVideo
    ) throws -> LessonPlaybackSession {
        let playbackURL = try mediaService.requestPlaybackURL(
            for: lesson.id
        )
        return try player.start(
            lessonID: lesson.id,
            playbackURL: playbackURL
        )
    }
}

public struct EntitledLessonPlaybackProxy<Subject: LessonPlayback>:
    LessonPlayback {
    public private(set) var entitlements: LessonEntitlements
    public private(set) var subject: Subject

    public init(
        entitlements: LessonEntitlements,
        subject: Subject
    ) {
        self.entitlements = entitlements
        self.subject = subject
    }

    public mutating func play(
        _ lesson: LessonVideo
    ) throws -> LessonPlaybackSession {
        guard entitlements.canAccess(lessonID: lesson.id) else {
            throw LessonPlaybackError.accessDenied(lessonID: lesson.id)
        }

        do {
            return try subject.play(lesson)
        } catch LessonPlaybackError.expiredPlaybackURL {
            return try subject.play(lesson)
        }
    }
}
