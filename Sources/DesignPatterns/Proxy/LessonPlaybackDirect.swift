public struct LessonVideo: Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) throws {
        guard !id.isEmpty else {
            throw LessonPlaybackError.missingLessonID
        }
        guard !title.isEmpty else {
            throw LessonPlaybackError.missingLessonTitle
        }

        self.id = id
        self.title = title
    }
}

public struct LessonPlaybackURL: Equatable, Sendable {
    public let value: String

    public init(_ value: String) throws {
        guard value.hasPrefix("https://") else {
            throw LessonPlaybackError.invalidPlaybackURL
        }

        self.value = value
    }
}

public struct LessonPlaybackSession: Equatable, Sendable {
    public let lessonID: String
    public let playbackURL: LessonPlaybackURL

    public init(
        lessonID: String,
        playbackURL: LessonPlaybackURL
    ) {
        self.lessonID = lessonID
        self.playbackURL = playbackURL
    }
}

public enum LessonMediaServiceOutcome: Equatable, Sendable {
    case playbackURL(LessonPlaybackURL)
    case unavailable
}

public enum LessonPlayerOutcome: Equatable, Sendable {
    case started
    case expiredURL
    case unavailable
}

public enum LessonPlaybackError: Error, Equatable, Sendable {
    case missingLessonID
    case missingLessonTitle
    case invalidPlaybackURL
    case accessDenied(lessonID: String)
    case mediaUnavailable
    case playerUnavailable
    case expiredPlaybackURL
}

public struct LessonEntitlements: Equatable, Sendable {
    public private(set) var accessChecks: [String] = []

    private let accessibleLessonIDs: Set<String>

    public init(accessibleLessonIDs: Set<String>) {
        self.accessibleLessonIDs = accessibleLessonIDs
    }

    public mutating func canAccess(lessonID: String) -> Bool {
        accessChecks.append(lessonID)
        return accessibleLessonIDs.contains(lessonID)
    }
}

public struct ScriptedLessonMediaService: Equatable, Sendable {
    public private(set) var requestedLessonIDs: [String] = []

    private var outcomes: [LessonMediaServiceOutcome]

    public init(outcomes: [LessonMediaServiceOutcome]) {
        self.outcomes = outcomes
    }

    public mutating func requestPlaybackURL(
        for lessonID: String
    ) throws -> LessonPlaybackURL {
        requestedLessonIDs.append(lessonID)

        guard !outcomes.isEmpty else {
            throw LessonPlaybackError.mediaUnavailable
        }

        switch outcomes.removeFirst() {
        case let .playbackURL(playbackURL):
            return playbackURL
        case .unavailable:
            throw LessonPlaybackError.mediaUnavailable
        }
    }
}

public struct ScriptedLessonPlayer: Equatable, Sendable {
    public private(set) var attemptedURLs: [LessonPlaybackURL] = []

    private var outcomes: [LessonPlayerOutcome]

    public init(outcomes: [LessonPlayerOutcome]) {
        self.outcomes = outcomes
    }

    public mutating func start(
        lessonID: String,
        playbackURL: LessonPlaybackURL
    ) throws -> LessonPlaybackSession {
        attemptedURLs.append(playbackURL)

        guard !outcomes.isEmpty else {
            throw LessonPlaybackError.playerUnavailable
        }

        switch outcomes.removeFirst() {
        case .started:
            return LessonPlaybackSession(
                lessonID: lessonID,
                playbackURL: playbackURL
            )
        case .expiredURL:
            throw LessonPlaybackError.expiredPlaybackURL
        case .unavailable:
            throw LessonPlaybackError.playerUnavailable
        }
    }
}

public struct DirectLessonPlaybackModel: Equatable, Sendable {
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

    public mutating func play(
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
