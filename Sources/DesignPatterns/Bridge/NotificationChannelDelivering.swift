public typealias NotificationDispatching = @Sendable (NotificationDispatch) async throws -> Void

public protocol NotificationChannelDelivering: Sendable {
    var channel: NotificationChannel { get }
    func deliver(_ content: NotificationContent) async throws -> NotificationDeliveryReceipt
}

public struct PushNotificationDelivery: NotificationChannelDelivering {
    public let channel = NotificationChannel.push
    private let dispatch: NotificationDispatching

    public init(dispatch: @escaping NotificationDispatching = { _ in }) {
        self.dispatch = dispatch
    }

    public func deliver(_ content: NotificationContent) async throws -> NotificationDeliveryReceipt {
        let output = NotificationDispatch(
            recipientID: content.recipientID,
            channel: channel,
            title: "\(content.categoryLabel): \(content.title)",
            body: content.body,
            sound: sound(for: content.purpose)
        )
        try await dispatch(output)
        return NotificationDeliveryReceipt(recipientID: content.recipientID, channel: channel)
    }

    private func sound(for purpose: NotificationPurpose) -> NotificationSound {
        switch purpose {
        case .securityAlert:
            .critical
        case .orderUpdate:
            .default
        case .promotionalReminder:
            .silent
        }
    }
}

public struct EmailNotificationDelivery: NotificationChannelDelivering {
    public let channel = NotificationChannel.email
    private let dispatch: NotificationDispatching

    public init(dispatch: @escaping NotificationDispatching = { _ in }) {
        self.dispatch = dispatch
    }

    public func deliver(_ content: NotificationContent) async throws -> NotificationDeliveryReceipt {
        let output = NotificationDispatch(
            recipientID: content.recipientID,
            channel: channel,
            title: content.title,
            body: emailBody(for: content),
            subject: "\(content.categoryLabel): \(content.title)"
        )
        try await dispatch(output)
        return NotificationDeliveryReceipt(recipientID: content.recipientID, channel: channel)
    }

    private func emailBody(for content: NotificationContent) -> String {
        guard content.purpose == .promotionalReminder else { return content.body }
        return "\(content.body) Manage preferences in the app."
    }
}

public struct InAppInboxDelivery: NotificationChannelDelivering {
    public let channel = NotificationChannel.inAppInbox
    private let dispatch: NotificationDispatching

    public init(dispatch: @escaping NotificationDispatching = { _ in }) {
        self.dispatch = dispatch
    }

    public func deliver(_ content: NotificationContent) async throws -> NotificationDeliveryReceipt {
        let output = NotificationDispatch(
            recipientID: content.recipientID,
            channel: channel,
            title: "\(content.categoryLabel): \(content.title)",
            body: content.body
        )
        try await dispatch(output)
        return NotificationDeliveryReceipt(recipientID: content.recipientID, channel: channel)
    }
}

public struct SMSNotificationDelivery: NotificationChannelDelivering {
    public let channel = NotificationChannel.sms
    private let dispatch: NotificationDispatching
    private let senderID: String

    public init(
        senderID: String = "RGSHOP",
        dispatch: @escaping NotificationDispatching = { _ in }
    ) {
        self.senderID = senderID
        self.dispatch = dispatch
    }

    public func deliver(_ content: NotificationContent) async throws -> NotificationDeliveryReceipt {
        let output = NotificationDispatch(
            recipientID: content.recipientID,
            channel: channel,
            title: "\(content.categoryLabel): \(content.title)",
            body: smsBody(for: content),
            senderID: senderID
        )
        try await dispatch(output)
        return NotificationDeliveryReceipt(recipientID: content.recipientID, channel: channel)
    }

    private func smsBody(for content: NotificationContent) -> String {
        guard content.purpose == .promotionalReminder else { return content.body }
        return "\(content.body) Reply STOP to opt out."
    }
}
