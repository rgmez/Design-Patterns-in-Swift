import DesignPatterns
import Testing

@Suite("Bridge")
struct BridgeTests {
    private static let recipientID = "customer-42"
    private static let request = NotificationRequest(
        recipientID: recipientID,
        purpose: .orderUpdate,
        title: "Your order is ready",
        body: "Collect it before 18:00."
    )

    struct PurposeScenario: Sendable, CustomTestStringConvertible {
        let purpose: NotificationPurpose
        let label: String

        var testDescription: String { purpose.rawValue }
    }

    private static let purposeScenarios = [
        PurposeScenario(purpose: .securityAlert, label: "Security alert"),
        PurposeScenario(purpose: .orderUpdate, label: "Order update"),
        PurposeScenario(purpose: .promotionalReminder, label: "Offer")
    ]

    @Suite("Independent axes")
    struct IndependentAxes {
        @Test(
            "Composes each purpose without knowing its channel",
            arguments: BridgeTests.purposeScenarios
        )
        func composesPurpose(_ scenario: PurposeScenario) {
            let content = makeNotificationPurposeComposer(for: scenario.purpose)
                .compose(BridgeTests.request)

            #expect(content.purpose == scenario.purpose)
            #expect(content.categoryLabel == scenario.label)
            #expect(content.title == BridgeTests.request.title)
            #expect(content.body == BridgeTests.request.body)
        }

        @Test(
            "Delivers every purpose through every channel",
            arguments: NotificationPurpose.allCases,
            NotificationChannel.allCases
        )
        func deliversProductMatrix(
            purpose: NotificationPurpose,
            channel: NotificationChannel
        ) async throws {
            let recorder = DispatchRecorder()
            let bridge = NotificationBridge(
                purpose: purpose,
                delivery: BridgeTests.delivery(for: channel, recorder: recorder)
            )

            let receipt = try await bridge.send(
                NotificationRequest(
                    recipientID: BridgeTests.recipientID,
                    purpose: purpose,
                    title: BridgeTests.request.title,
                    body: BridgeTests.request.body
                )
            )

            #expect(receipt == NotificationDeliveryReceipt(
                recipientID: BridgeTests.recipientID,
                channel: channel
            ))
            #expect((await recorder.values).count == 1)
            #expect(await recorder.values.first?.channel == channel)
        }
    }

    @Suite("Channel policies")
    struct ChannelPolicies {
        @Test("Keeps transport metadata on its owning channel")
        func keepsMetadataLocal() async throws {
            let push = try await BridgeTests.dispatch(for: .push, request: BridgeTests.request)
            let email = try await BridgeTests.dispatch(for: .email, request: BridgeTests.request)
            let inbox = try await BridgeTests.dispatch(for: .inAppInbox, request: BridgeTests.request)
            let sms = try await BridgeTests.dispatch(for: .sms, request: BridgeTests.request)

            #expect(push.sound == .default)
            #expect(push.subject == nil)
            #expect(push.senderID == nil)
            #expect(email.subject == "Order update: Your order is ready")
            #expect(email.sound == nil)
            #expect(email.senderID == nil)
            #expect(inbox.sound == nil)
            #expect(inbox.subject == nil)
            #expect(inbox.senderID == nil)
            #expect(sms.senderID == "RGSHOP")
            #expect(sms.sound == nil)
            #expect(sms.subject == nil)
        }

        @Test("Preserves security urgency and promotional opt-out copy")
        func preservesPurposeRules() async throws {
            let securityRequest = NotificationRequest(
                recipientID: BridgeTests.recipientID,
                purpose: .securityAlert,
                title: "New sign-in",
                body: "A new device signed in."
            )
            let promotionRequest = NotificationRequest(
                recipientID: BridgeTests.recipientID,
                purpose: .promotionalReminder,
                title: "Weekend savings",
                body: "Save 20% on selected items."
            )

            let security = try await BridgeTests.dispatch(for: .push, request: securityRequest)
            let email = try await BridgeTests.dispatch(for: .email, request: promotionRequest)
            let sms = try await BridgeTests.dispatch(for: .sms, request: promotionRequest)

            #expect(security.title == "Security alert: New sign-in")
            #expect(security.sound == .critical)
            #expect(email.subject == "Offer: Weekend savings")
            #expect(email.body.hasSuffix("Manage preferences in the app."))
            #expect(sms.body.hasSuffix("Reply STOP to opt out."))
        }
    }

    @Suite("Async boundary")
    struct AsyncBoundary {
        @Test("Propagates a channel failure to the caller")
        func propagatesFailure() async {
            let delivery = PushNotificationDelivery { _ in
                throw TestDeliveryError.unavailable
            }
            let bridge = NotificationBridge(purpose: .orderUpdate, delivery: delivery)

            await #expect(throws: TestDeliveryError.unavailable) {
                try await bridge.send(BridgeTests.request)
            }
        }

        @Test("Does not mutate the app-owned request")
        func preservesInputValue() async throws {
            let request = BridgeTests.request
            let bridge = NotificationBridge(
                purpose: request.purpose,
                delivery: InAppInboxDelivery()
            )

            _ = try await bridge.send(request)

            #expect(request == BridgeTests.request)
        }
    }

    private static func dispatch(
        for channel: NotificationChannel,
        request: NotificationRequest
    ) async throws -> NotificationDispatch {
        let recorder = DispatchRecorder()
        let bridge = NotificationBridge(
            purpose: request.purpose,
            delivery: delivery(for: channel, recorder: recorder)
        )
        _ = try await bridge.send(request)
        return try #require(await recorder.values.first)
    }

    private static func delivery(
        for channel: NotificationChannel,
        recorder: DispatchRecorder
    ) -> any NotificationChannelDelivering {
        let dispatch: NotificationDispatching = { value in
            await recorder.record(value)
        }

        switch channel {
        case .push:
            return PushNotificationDelivery(dispatch: dispatch)
        case .email:
            return EmailNotificationDelivery(dispatch: dispatch)
        case .inAppInbox:
            return InAppInboxDelivery(dispatch: dispatch)
        case .sms:
            return SMSNotificationDelivery(dispatch: dispatch)
        }
    }
}

private actor DispatchRecorder {
    private(set) var values: [NotificationDispatch] = []

    func record(_ value: NotificationDispatch) {
        values.append(value)
    }
}

private enum TestDeliveryError: Error, Equatable, Sendable {
    case unavailable
}
