import Foundation

public actor ObservedSessionController {
    public private(set) var currentSession: UserSession = .signedOut

    private var continuations: [
        UUID: AsyncStream<UserSession>.Continuation
    ] = [:]

    var activeSubscriptionCount: Int {
        continuations.count
    }

    public init() {}

    public func sessionStream() -> AsyncStream<UserSession> {
        let subscriptionID = UUID()
        let (stream, continuation) = AsyncStream<UserSession>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.remove(subscriptionID)
            }
        }
        continuations[subscriptionID] = continuation
        _ = continuation.yield(currentSession)
        return stream
    }

    public func transition(to session: UserSession) {
        guard session != currentSession else { return }

        currentSession = session

        let terminatedSubscriptionIDs = continuations.compactMap { subscriptionID, continuation in
            if case .terminated = continuation.yield(session) {
                return subscriptionID
            }
            return nil
        }
        terminatedSubscriptionIDs.forEach { subscriptionID in
            continuations.removeValue(forKey: subscriptionID)
        }
    }

    private func remove(_ subscriptionID: UUID) {
        continuations.removeValue(forKey: subscriptionID)
    }
}
