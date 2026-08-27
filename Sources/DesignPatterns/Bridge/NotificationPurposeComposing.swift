public protocol NotificationPurposeComposing: Sendable {
    var purpose: NotificationPurpose { get }
    func compose(_ request: NotificationRequest) -> NotificationContent
}

public struct SecurityAlertComposer: NotificationPurposeComposing {
    public let purpose = NotificationPurpose.securityAlert

    public init() {}

    public func compose(_ request: NotificationRequest) -> NotificationContent {
        NotificationContent(
            recipientID: request.recipientID,
            title: request.title,
            body: request.body,
            categoryLabel: "Security alert",
            purpose: purpose
        )
    }
}

public struct OrderUpdateComposer: NotificationPurposeComposing {
    public let purpose = NotificationPurpose.orderUpdate

    public init() {}

    public func compose(_ request: NotificationRequest) -> NotificationContent {
        NotificationContent(
            recipientID: request.recipientID,
            title: request.title,
            body: request.body,
            categoryLabel: "Order update",
            purpose: purpose
        )
    }
}

public struct PromotionalReminderComposer: NotificationPurposeComposing {
    public let purpose = NotificationPurpose.promotionalReminder

    public init() {}

    public func compose(_ request: NotificationRequest) -> NotificationContent {
        NotificationContent(
            recipientID: request.recipientID,
            title: request.title,
            body: request.body,
            categoryLabel: "Offer",
            purpose: purpose
        )
    }
}

public func makeNotificationPurposeComposer(
    for purpose: NotificationPurpose
) -> any NotificationPurposeComposing {
    switch purpose {
    case .securityAlert:
        SecurityAlertComposer()
    case .orderUpdate:
        OrderUpdateComposer()
    case .promotionalReminder:
        PromotionalReminderComposer()
    }
}
