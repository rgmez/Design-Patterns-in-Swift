public enum UserSession: Equatable, Sendable {
    case signedOut
    case signedIn(userID: String, displayName: String)
}

public enum AccountHeaderState: Equatable, Sendable {
    case signedOut
    case signedIn(displayName: String)
}

public final class AccountHeaderModel {
    public private(set) var state: AccountHeaderState = .signedOut

    public init() {}

    fileprivate func showSignedIn(displayName: String) {
        state = .signedIn(displayName: displayName)
    }

    fileprivate func showSignedOut() {
        state = .signedOut
    }
}

public enum CartOwner: Equatable, Sendable {
    case guest
    case account(userID: String)
}

public final class CartSession {
    public private(set) var owner: CartOwner = .guest

    public init() {}

    fileprivate func attach(to userID: String) {
        owner = .account(userID: userID)
    }

    fileprivate func detachAccount() {
        owner = .guest
    }
}

public final class AccountSyncSchedule {
    public private(set) var scheduledUserID: String?

    public init() {}

    fileprivate func schedule(for userID: String) {
        scheduledUserID = userID
    }

    fileprivate func cancel() {
        scheduledUserID = nil
    }
}

public enum SessionAnalyticsEvent: Equatable, Sendable {
    case signedIn(userID: String)
    case signedOut
}

public final class SessionAnalyticsLog {
    public private(set) var events: [SessionAnalyticsEvent] = []

    public init() {}

    fileprivate func record(_ event: SessionAnalyticsEvent) {
        events.append(event)
    }
}

public final class SessionController {
    public private(set) var currentSession: UserSession = .signedOut

    private let accountHeader: AccountHeaderModel
    private let cartSession: CartSession
    private let syncSchedule: AccountSyncSchedule
    private let analytics: SessionAnalyticsLog

    public init(
        accountHeader: AccountHeaderModel,
        cartSession: CartSession,
        syncSchedule: AccountSyncSchedule,
        analytics: SessionAnalyticsLog
    ) {
        self.accountHeader = accountHeader
        self.cartSession = cartSession
        self.syncSchedule = syncSchedule
        self.analytics = analytics
    }

    public func transition(to session: UserSession) {
        guard session != currentSession else { return }

        currentSession = session

        switch session {
        case .signedOut:
            accountHeader.showSignedOut()
            cartSession.detachAccount()
            syncSchedule.cancel()
            analytics.record(.signedOut)
        case let .signedIn(userID, displayName):
            accountHeader.showSignedIn(displayName: displayName)
            cartSession.attach(to: userID)
            syncSchedule.schedule(for: userID)
            analytics.record(.signedIn(userID: userID))
        }
    }
}
