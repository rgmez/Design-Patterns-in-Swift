import DesignPatterns
import Testing

@Suite("Observer pressure")
struct ObserverPressureTests {
    @Test("A short-lived screen needs a new controller callback")
    func directFanOutKnowsTheScreen() {
        let screen = SessionScreenModel()
        let controller = SessionController(
            accountHeader: AccountHeaderModel(),
            cartSession: CartSession(),
            syncSchedule: AccountSyncSchedule(),
            analytics: SessionAnalyticsLog(),
            sessionScreen: screen
        )

        controller.transition(
            to: .signedIn(userID: "user-42", displayName: "Ava")
        )
        #expect(screen.state == .signedIn(displayName: "Ava"))

        screen.disappear()
        controller.transition(to: .signedOut)

        #expect(screen.state == .signedOut)
    }

    @Test("The direct source cannot unregister a screen callback")
    func disappearingScreenStillRequiresSourceKnowledge() {
        let screen = SessionScreenModel()
        let controller = SessionController(
            accountHeader: AccountHeaderModel(),
            cartSession: CartSession(),
            syncSchedule: AccountSyncSchedule(),
            analytics: SessionAnalyticsLog(),
            sessionScreen: screen
        )

        controller.transition(
            to: .signedIn(userID: "user-42", displayName: "Ava")
        )
        screen.disappear()
        controller.transition(to: .signedOut)

        #expect(screen.state == .signedOut)
    }
}
