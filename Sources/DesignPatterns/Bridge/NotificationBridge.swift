/// Joins purpose-specific content with an independently replaceable delivery channel.
public struct NotificationBridge: Sendable {
    private let composer: any NotificationPurposeComposing
    private let delivery: any NotificationChannelDelivering

    public init<C: NotificationPurposeComposing, D: NotificationChannelDelivering>(
        composer: C,
        delivery: D
    ) {
        self.composer = composer
        self.delivery = delivery
    }

    public init<D: NotificationChannelDelivering>(
        purpose: NotificationPurpose,
        delivery: D
    ) {
        self.init(
            composer: makeNotificationPurposeComposer(for: purpose),
            delivery: delivery
        )
    }

    public func send(_ request: NotificationRequest) async throws -> NotificationDeliveryReceipt {
        let content = composer.compose(request)
        return try await delivery.deliver(content)
    }
}
