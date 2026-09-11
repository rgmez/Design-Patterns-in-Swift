import Foundation

public actor SessionObservationCenter {
    private var continuations: [String: AsyncStream<UserSession>.Continuation] = [:]

    public init() {}

    public func stream() -> AsyncStream<UserSession> {
        let subscriptionID = UUID().uuidString
        let (stream, continuation) = AsyncStream<UserSession>.makeStream()
        continuations[subscriptionID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.remove(subscriptionID)
            }
        }
        return stream
    }

    public func publish(_ session: UserSession) {
        continuations.values.forEach { continuation in
            continuation.yield(session)
        }
    }

    private func remove(_ subscriptionID: String) {
        continuations.removeValue(forKey: subscriptionID)
    }
}

public actor ObservedSessionController {
    public private(set) var currentSession: UserSession = .signedOut

    private let observationCenter: SessionObservationCenter

    public init(observationCenter: SessionObservationCenter) {
        self.observationCenter = observationCenter
    }

    public func sessionStream() async -> AsyncStream<UserSession> {
        await observationCenter.stream()
    }

    public func transition(to session: UserSession) async {
        guard session != currentSession else { return }

        currentSession = session
        await observationCenter.publish(session)
    }
}
