public enum AudioSessionPurpose: Equatable, Sendable {
    case recording
    case previewPlayback
}

public struct AudioSessionRequest: Equatable, Sendable {
    public let ownerID: String
    public let purpose: AudioSessionPurpose

    public init(ownerID: String, purpose: AudioSessionPurpose) {
        precondition(
            !ownerID.isEmpty,
            "An audio-session owner needs an identifier"
        )

        self.ownerID = ownerID
        self.purpose = purpose
    }
}

public protocol SystemAudioSessionApplying: Actor {
    func activate(for purpose: AudioSessionPurpose) async throws
    func deactivate() async throws
}

public enum AudioSessionControllerError: Error, Equatable, Sendable {
    case occupied(activeOwnerID: String, requestedOwnerID: String)
    case inactive
    case notOwner(activeOwnerID: String, requestedOwnerID: String)
}

public actor AudioSessionController {
    public static let shared = AudioSessionController(
        systemSession: ProcessSystemAudioSession()
    )

    private enum State {
        case inactive
        case activating(AudioSessionRequest)
        case active(AudioSessionRequest)
        case deactivating(AudioSessionRequest)

        var request: AudioSessionRequest? {
            switch self {
            case .inactive:
                nil
            case let .activating(request),
                 let .active(request),
                 let .deactivating(request):
                request
            }
        }
    }

    private let systemSession: any SystemAudioSessionApplying
    private var state = State.inactive

    private init(systemSession: any SystemAudioSessionApplying) {
        self.systemSession = systemSession
    }

    package static func isolated(
        systemSession: any SystemAudioSessionApplying
    ) -> AudioSessionController {
        AudioSessionController(systemSession: systemSession)
    }

    public func acquire(_ request: AudioSessionRequest) async throws {
        guard case .inactive = state else {
            throw occupiedError(for: request.ownerID)
        }

        state = .activating(request)

        do {
            try await systemSession.activate(for: request.purpose)
            state = .active(request)
        } catch {
            state = .inactive
            throw error
        }
    }

    public func release(ownerID: String) async throws {
        guard case let .active(request) = state else {
            if case .inactive = state {
                throw AudioSessionControllerError.inactive
            }
            throw occupiedError(for: ownerID)
        }
        guard request.ownerID == ownerID else {
            throw AudioSessionControllerError.notOwner(
                activeOwnerID: request.ownerID,
                requestedOwnerID: ownerID
            )
        }

        state = .deactivating(request)

        do {
            try await systemSession.deactivate()
            state = .inactive
        } catch {
            state = .active(request)
            throw error
        }
    }

    public func activeRequest() -> AudioSessionRequest? {
        guard case let .active(request) = state else {
            return nil
        }
        return request
    }

    private func occupiedError(
        for requestedOwnerID: String
    ) -> AudioSessionControllerError {
        guard let activeOwnerID = state.request?.ownerID else {
            preconditionFailure("Only a reserved session can be occupied")
        }
        return .occupied(
            activeOwnerID: activeOwnerID,
            requestedOwnerID: requestedOwnerID
        )
    }
}

public struct LegacyPreviewResumeCallback: Sendable {
    package let controller: AudioSessionController

    public init() {
        controller = .shared
    }

    package init(controller: AudioSessionController) {
        self.controller = controller
    }

    public func resumePreview(ownerID: String) async throws {
        try await controller.acquire(
            AudioSessionRequest(
                ownerID: ownerID,
                purpose: .previewPlayback
            )
        )
    }
}

private actor ProcessSystemAudioSession: SystemAudioSessionApplying {
    private var activePurpose: AudioSessionPurpose?

    func activate(for purpose: AudioSessionPurpose) {
        activePurpose = purpose
    }

    func deactivate() {
        activePurpose = nil
    }
}
