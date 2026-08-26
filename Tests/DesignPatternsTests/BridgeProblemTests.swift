import DesignPatterns
import Testing

@Suite("Bridge problem")
struct BridgeProblemTests {
    private static let recipientID = "customer-42"
    private static let smsSenderID = "RGSHOP"
    private static let request = NotificationRequest(
        recipientID: recipientID,
        purpose: .orderUpdate,
        title: "Your order is ready",
        body: "Collect it before 18:00."
    )

    @Suite("Product matrix")
    struct ProductMatrix {
        @Test(
            "Prepares every purpose and channel combination",
            arguments: NotificationPurpose.allCases,
            NotificationChannel.allCases
        )
        func preparesDispatch(
            purpose: NotificationPurpose,
            channel: NotificationChannel
        ) {
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

        @Test("Keeps delivery-only fields on their channel")
        func channelFields() {
            let push = prepareNotification(BridgeProblemTests.request, for: .push)
            let email = prepareNotification(BridgeProblemTests.request, for: .email)
            let inbox = prepareNotification(BridgeProblemTests.request, for: .inAppInbox)
            let sms = prepareNotification(BridgeProblemTests.request, for: .sms)

            #expect(push.sound != nil)
            #expect(push.subject == nil)
            #expect(push.senderID == nil)
            #expect(email.sound == nil)
            #expect(email.subject != nil)
            #expect(email.senderID == nil)
            #expect(inbox.sound == nil)
            #expect(inbox.subject == nil)
            #expect(inbox.senderID == nil)
            #expect(sms.sound == nil)
            #expect(sms.subject == nil)
            #expect(sms.senderID == BridgeProblemTests.smsSenderID)
        }
    }

    @Suite("Purpose rules")
    struct PurposeRules {
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
                recipientID: BridgeProblemTests.recipientID,
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
    }

    @Suite("SMS pressure")
    struct SMSPressure {
        @Test(
            "Uses the provider sender for every purpose",
            arguments: NotificationPurpose.allCases
        )
        func senderID(purpose: NotificationPurpose) {
            let request = NotificationRequest(
                recipientID: BridgeProblemTests.request.recipientID,
                purpose: purpose,
                title: BridgeProblemTests.request.title,
                body: BridgeProblemTests.request.body
            )

            let dispatch = prepareNotification(request, for: .sms)

            #expect(dispatch.senderID == BridgeProblemTests.smsSenderID)
            #expect(dispatch.subject == nil)
            #expect(dispatch.sound == nil)
        }

        @Test("Adds SMS opt-out copy to promotions only")
        func promotionalOptOut() {
            let promotionalRequest = NotificationRequest(
                recipientID: BridgeProblemTests.request.recipientID,
                purpose: .promotionalReminder,
                title: BridgeProblemTests.request.title,
                body: BridgeProblemTests.request.body
            )

            let promotion = prepareNotification(promotionalRequest, for: .sms)
            let order = prepareNotification(BridgeProblemTests.request, for: .sms)

            #expect(promotion.body.hasSuffix("Reply STOP to opt out."))
            #expect(order.body == BridgeProblemTests.request.body)
        }
    }

    @Suite("Value semantics")
    struct ValueSemantics {
        @Test("Does not mutate the app-owned request")
        func preservesInputValue() {
            let request = BridgeProblemTests.request

            _ = prepareNotification(request, for: .push)

            #expect(request == BridgeProblemTests.request)
        }
    }
}
