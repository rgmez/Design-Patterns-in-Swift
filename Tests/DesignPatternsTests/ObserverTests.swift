@testable import DesignPatterns
import Testing

@Suite("Observer solution")
struct ObserverTests {
    private static let signedIn = UserSession.signedIn(
        userID: "user-42",
        displayName: "Ava"
    )

    @Suite("Subscription snapshots")
    struct SubscriptionSnapshots {
        @Test("Starts a late subscription with the current session")
        func replaysCurrentSession() async {
            let controller = ObservedSessionController()
            await controller.transition(to: ObserverTests.signedIn)

            let stream = await controller.sessionStream()
            var iterator = stream.makeAsyncIterator()

            #expect(await iterator.next() == ObserverTests.signedIn)
        }

        @Test("Delivers one session change to every active subscriber")
        func publishesToActiveSubscribers() async {
            let controller = ObservedSessionController()
            let firstStream = await controller.sessionStream()
            let secondStream = await controller.sessionStream()
            var firstIterator = firstStream.makeAsyncIterator()
            var secondIterator = secondStream.makeAsyncIterator()

            #expect(await firstIterator.next() == .signedOut)
            #expect(await secondIterator.next() == .signedOut)

            await controller.transition(to: ObserverTests.signedIn)

            #expect(await firstIterator.next() == ObserverTests.signedIn)
            #expect(await secondIterator.next() == ObserverTests.signedIn)
        }

        @Test("Keeps only the newest pending session for a slow subscriber")
        func boundsPendingDelivery() async {
            let controller = ObservedSessionController()
            let stream = await controller.sessionStream()
            var iterator = stream.makeAsyncIterator()

            await controller.transition(to: ObserverTests.signedIn)
            await controller.transition(to: .signedOut)

            #expect(await iterator.next() == .signedOut)
        }
    }

    @Suite("Transition filtering")
    struct TransitionFiltering {
        @Test("Filters duplicate snapshots before publishing")
        func filtersDuplicates() async {
            let controller = ObservedSessionController()
            let stream = await controller.sessionStream()
            var iterator = stream.makeAsyncIterator()

            #expect(await iterator.next() == .signedOut)

            await controller.transition(to: ObserverTests.signedIn)
            await controller.transition(to: ObserverTests.signedIn)

            #expect(await iterator.next() == ObserverTests.signedIn)
        }
    }

    @Suite("Subscription lifecycle")
    struct SubscriptionLifecycle {
        @Test("Cancels one subscriber without affecting another")
        func cancelsIndependently() async {
            let controller = ObservedSessionController()
            let cancelledStream = await controller.sessionStream()
            let activeStream = await controller.sessionStream()
            var cancelledIterator = cancelledStream.makeAsyncIterator()
            var activeIterator = activeStream.makeAsyncIterator()

            #expect(await cancelledIterator.next() == .signedOut)
            #expect(await activeIterator.next() == .signedOut)
            #expect(await controller.activeSubscriptionCount == 2)

            let waitingTask = Task {
                await cancelledIterator.next()
            }

            waitingTask.cancel()
            #expect(await waitingTask.value == nil)

            await controller.transition(to: ObserverTests.signedIn)

            #expect(await activeIterator.next() == ObserverTests.signedIn)
            #expect(await controller.activeSubscriptionCount == 1)
        }
    }
}
