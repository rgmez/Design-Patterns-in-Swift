import DesignPatterns
import Testing

@Suite("Observer problem")
struct ObserverProblemTests {
    private static let userID = "user-42"
    private static let displayName = "Ava"
    private static let signedInSession = UserSession.signedIn(
        userID: userID,
        displayName: displayName
    )

    private struct Fixture {
        let accountHeader = AccountHeaderModel()
        let cartSession = CartSession()
        let syncSchedule = AccountSyncSchedule()
        let analytics = SessionAnalyticsLog()
        let controller: SessionController

        init() {
            controller = SessionController(
                accountHeader: accountHeader,
                cartSession: cartSession,
                syncSchedule: syncSchedule,
                analytics: analytics
            )
        }
    }

    @Suite("Direct session transitions")
    struct DirectSessionTransitions {
        @Test("Updates every known consumer after sign-in")
        func signsIn() {
            let fixture = Fixture()

            fixture.controller.transition(
                to: ObserverProblemTests.signedInSession
            )

            #expect(
                fixture.controller.currentSession
                    == ObserverProblemTests.signedInSession
            )
            #expect(
                fixture.accountHeader.state
                    == .signedIn(
                        displayName: ObserverProblemTests.displayName
                    )
            )
            #expect(
                fixture.cartSession.owner
                    == .account(userID: ObserverProblemTests.userID)
            )
            #expect(
                fixture.syncSchedule.scheduledUserID
                    == ObserverProblemTests.userID
            )
            #expect(
                fixture.analytics.events
                    == [.signedIn(userID: ObserverProblemTests.userID)]
            )
        }

        @Test("Returns every known consumer to signed-out state")
        func signsOut() {
            let fixture = Fixture()
            fixture.controller.transition(
                to: ObserverProblemTests.signedInSession
            )

            fixture.controller.transition(to: .signedOut)

            #expect(fixture.controller.currentSession == .signedOut)
            #expect(fixture.accountHeader.state == .signedOut)
            #expect(fixture.cartSession.owner == .guest)
            #expect(fixture.syncSchedule.scheduledUserID == nil)
            #expect(
                fixture.analytics.events
                    == [
                        .signedIn(userID: ObserverProblemTests.userID),
                        .signedOut
                    ]
            )
        }

        @Test("Ignores a repeated session snapshot")
        func ignoresDuplicateSession() {
            let fixture = Fixture()
            fixture.controller.transition(
                to: ObserverProblemTests.signedInSession
            )

            fixture.controller.transition(
                to: ObserverProblemTests.signedInSession
            )

            #expect(
                fixture.analytics.events
                    == [.signedIn(userID: ObserverProblemTests.userID)]
            )
        }
    }
}
