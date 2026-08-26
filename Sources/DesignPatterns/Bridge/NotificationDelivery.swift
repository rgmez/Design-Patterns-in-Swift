public enum NotificationPurpose: String, CaseIterable, Equatable, Sendable {
    case securityAlert
    case orderUpdate
    case promotionalReminder
}

public enum NotificationChannel: String, CaseIterable, Equatable, Sendable {
    case push
    case email
    case inAppInbox
    case sms
}

public enum NotificationSound: String, Equatable, Sendable {
    case critical
    case `default`
    case silent
}

public struct NotificationRequest: Equatable, Sendable {
    public let recipientID: String
    public let purpose: NotificationPurpose
    public let title: String
    public let body: String

    public init(
        recipientID: String,
        purpose: NotificationPurpose,
        title: String,
        body: String
    ) {
        self.recipientID = recipientID
        self.purpose = purpose
        self.title = title
        self.body = body
    }
}

public struct NotificationDispatch: Equatable, Sendable {
    public let recipientID: String
    public let channel: NotificationChannel
    public let title: String
    public let body: String
    public let subject: String?
    public let sound: NotificationSound?
    public let senderID: String?

    public init(
        recipientID: String,
        channel: NotificationChannel,
        title: String,
        body: String,
        subject: String? = nil,
        sound: NotificationSound? = nil,
        senderID: String? = nil
    ) {
        self.recipientID = recipientID
        self.channel = channel
        self.title = title
        self.body = body
        self.subject = subject
        self.sound = sound
        self.senderID = senderID
    }
}

public func prepareNotification(
    _ request: NotificationRequest,
    for channel: NotificationChannel
) -> NotificationDispatch {
    switch request.purpose {
    case .securityAlert:
        prepareSecurityAlert(request, for: channel)
    case .orderUpdate:
        prepareOrderUpdate(request, for: channel)
    case .promotionalReminder:
        preparePromotionalReminder(request, for: channel)
    }
}

private func prepareSecurityAlert(
    _ request: NotificationRequest,
    for channel: NotificationChannel
) -> NotificationDispatch {
    switch channel {
    case .push:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Security alert: \(request.title)",
            body: request.body,
            sound: .critical
        )
    case .email:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: request.title,
            body: request.body,
            subject: "Security alert: \(request.title)"
        )
    case .inAppInbox:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Security alert: \(request.title)",
            body: request.body
        )
    case .sms:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Security alert: \(request.title)",
            body: request.body,
            senderID: "RGSHOP"
        )
    }
}

private func prepareOrderUpdate(
    _ request: NotificationRequest,
    for channel: NotificationChannel
) -> NotificationDispatch {
    switch channel {
    case .push:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Order update: \(request.title)",
            body: request.body,
            sound: .default
        )
    case .email:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: request.title,
            body: request.body,
            subject: "Order update: \(request.title)"
        )
    case .inAppInbox:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Order update: \(request.title)",
            body: request.body
        )
    case .sms:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Order update: \(request.title)",
            body: request.body,
            senderID: "RGSHOP"
        )
    }
}

private func preparePromotionalReminder(
    _ request: NotificationRequest,
    for channel: NotificationChannel
) -> NotificationDispatch {
    switch channel {
    case .push:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "New offer: \(request.title)",
            body: request.body,
            sound: .silent
        )
    case .email:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: request.title,
            body: "\(request.body) Manage preferences in the app.",
            subject: "Offer: \(request.title)"
        )
    case .inAppInbox:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Offer: \(request.title)",
            body: request.body
        )
    case .sms:
        NotificationDispatch(
            recipientID: request.recipientID,
            channel: channel,
            title: "Offer: \(request.title)",
            body: "\(request.body) Reply STOP to opt out.",
            senderID: "RGSHOP"
        )
    }
}
