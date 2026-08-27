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

/// Semantic content is produced by the purpose axis before a channel adds transport policy.
public struct NotificationContent: Equatable, Sendable {
    public let recipientID: String
    public let title: String
    public let body: String
    public let categoryLabel: String
    public let purpose: NotificationPurpose

    public init(
        recipientID: String,
        title: String,
        body: String,
        categoryLabel: String,
        purpose: NotificationPurpose
    ) {
        self.recipientID = recipientID
        self.title = title
        self.body = body
        self.categoryLabel = categoryLabel
        self.purpose = purpose
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

public struct NotificationDeliveryReceipt: Equatable, Sendable {
    public let recipientID: String
    public let channel: NotificationChannel

    public init(recipientID: String, channel: NotificationChannel) {
        self.recipientID = recipientID
        self.channel = channel
    }
}
