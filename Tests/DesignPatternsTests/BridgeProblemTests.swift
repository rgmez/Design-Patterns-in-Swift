import DesignPatterns
import Testing

@Suite("Bridge problem")
struct BridgeProblemTests {
    private static let request = NotificationRequest(
        recipientID: "customer-42",
        purpose: .orderUpdate,
        title: "Your order is ready",
        body: "Collect it before 18:00."
    )

    @Test("Prepares every purpose and channel combination")
    func preparesProductMatrix() {
        for purpose in NotificationPurpose.allCases {
            for channel in NotificationChannel.allCases {
                let dispatch = prepareNotification(
                    NotificationRequest(
                        recipientID: BridgeProblemTests.request.recipientID,
                        purpose: purpose,
                        title: BridgeProblemTests.request.title,
                        body: BridgeProblemTests.request.body
                    ),
                    for: channel
                )

                #expect(dispatch.recipientID == BridgeProblemTests.request.recipientID)
                #expect(dispatch.channel == channel)
                #expect(!dispatch.title.isEmpty)
                #expect(!dispatch.body.isEmpty)
            }
        }
    }

    @Test("Uses critical push delivery for security alerts")
    func securityPush() {
        let dispatch = prepareNotification(
            NotificationRequest(
                recipientID: BridgeProblemTests.request.recipientID,
                purpose: .securityAlert,
                title: "New sign-in",
                body: "A new device signed in."
            ),
            for: .push
        )

        #expect(dispatch.title == "Security alert: New sign-in")
        #expect(dispatch.body == "A new device signed in.")
        #expect(dispatch.subject == nil)
        #expect(dispatch.sound == .critical)
    }

    @Test("Uses an email subject for order updates")
    func orderEmail() {
        let dispatch = prepareNotification(BridgeProblemTests.request, for: .email)

        #expect(dispatch.title == BridgeProblemTests.request.title)
        #expect(dispatch.subject == "Order update: Your order is ready")
        #expect(dispatch.body == BridgeProblemTests.request.body)
        #expect(dispatch.sound == nil)
    }

    @Test("Keeps promotional preference copy on email only")
    func promotionalEmail() {
        let request = NotificationRequest(
            recipientID: "customer-42",
            purpose: .promotionalReminder,
            title: "Weekend savings",
            body: "Save 20% on selected items."
        )

        let email = prepareNotification(request, for: .email)
        let inbox = prepareNotification(request, for: .inAppInbox)

        #expect(email.subject == "Offer: Weekend savings")
        #expect(email.body.hasSuffix("Manage preferences in the app."))
        #expect(inbox.subject == nil)
        #expect(inbox.body == request.body)
    }

    @Test("Does not mutate the app-owned request")
    func preservesInputValue() {
        let request = BridgeProblemTests.request

        _ = prepareNotification(request, for: .push)

        #expect(request == BridgeProblemTests.request)
    }
}
