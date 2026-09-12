import DesignPatterns
import Testing

@Suite("Observer solution")
struct ObserverTests {
    @Test("Delivers one session change to every active subscriber")
    func publishesToActiveSubscribers() async {
        let center = SessionObservationCenter()
        let controller = ObservedSessionController(observationCenter: center)
        let firstStream = await controller.sessionStream()
        let secondStream = await controller.sessionStream()
        var firstIterator = firstStream.makeAsyncIterator()
        var secondIterator = secondStream.makeAsyncIterator()

        let session = UserSession.signedIn(
            userID: "user-42",
            displayName: "Ava"
        )
        await controller.transition(to: session)

        #expect(await firstIterator.next() == session)
        #expect(await secondIterator.next() == session)
    }

    @Test("Filters duplicate snapshots before publishing")
    func filtersDuplicates() async {
        let center = SessionObservationCenter()
        let controller = ObservedSessionController(observationCenter: center)
        let stream = await controller.sessionStream()
        var iterator = stream.makeAsyncIterator()
        let session = UserSession.signedIn(
            userID: "user-42",
            displayName: "Ava"
        )

        await controller.transition(to: session)
        await controller.transition(to: session)

        #expect(await iterator.next() == session)
    }

    @Test("Keeps only the newest pending session for a slow subscriber")
    func boundsPendingDelivery() async {
        let center = SessionObservationCenter()
        let controller = ObservedSessionController(observationCenter: center)
        let stream = await controller.sessionStream()
        var iterator = stream.makeAsyncIterator()
        let signedIn = UserSession.signedIn(
            userID: "user-42",
            displayName: "Ava"
        )

        await controller.transition(to: signedIn)
        await controller.transition(to: .signedOut)

        #expect(await iterator.next() == .signedOut)
    }

    @Test("Cancelling a subscriber stops its stream")
    func cancelsIndependently() async {
        let center = SessionObservationCenter()
        let controller = ObservedSessionController(observationCenter: center)
        let stream = await controller.sessionStream()
        let waitingTask = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        waitingTask.cancel()
        #expect(await waitingTask.value == nil)

        await controller.transition(
            to: .signedIn(userID: "user-42", displayName: "Ava")
        )
        #expect(await waitingTask.value == nil)
    }
}
