public enum SupportUploadAttachmentCategory: Hashable, Sendable {
    case diagnostics
    case screenshots
    case screenRecording
}

public struct RedactedSupportDiagnostics: Equatable, Sendable {
    public let payload: [UInt8]

    public init(payload: [UInt8]) {
        self.payload = payload
    }
}

public struct SupportScreenshot: Equatable, Sendable {
    public let filename: String
    public let payload: [UInt8]

    public init(filename: String, payload: [UInt8]) {
        self.filename = filename
        self.payload = payload
    }
}

public struct SupportScreenRecording: Equatable, Sendable {
    public let filename: String
    public let payload: [UInt8]

    public init(filename: String, payload: [UInt8]) {
        self.filename = filename
        self.payload = payload
    }
}

public enum SupportUploadPartKind: Equatable, Sendable {
    case message
    case diagnostics
    case screenshot(filename: String)
    case screenRecording(filename: String)
}

public struct SupportUploadPart: Equatable, Sendable {
    public let kind: SupportUploadPartKind
    public let contentType: String
    public let payload: [UInt8]

    fileprivate init(
        kind: SupportUploadPartKind,
        contentType: String,
        payload: [UInt8]
    ) {
        self.kind = kind
        self.contentType = contentType
        self.payload = payload
    }
}

public enum SupportUploadRequestError: Error, Equatable, Sendable {
    case emptyMessage
    case invalidMaximumPayloadSize
    case consentRequired(for: SupportUploadAttachmentCategory)
    case payloadTooLarge(actualBytes: Int, maximumBytes: Int)
    case requestAlreadyBuilt
}

public struct SupportUploadRequest: Equatable, Sendable {
    public let ticketID: String
    public let parts: [SupportUploadPart]
    public let totalPayloadSizeInBytes: Int

    fileprivate init(ticketID: String, parts: [SupportUploadPart]) {
        self.ticketID = ticketID
        self.parts = parts
        totalPayloadSizeInBytes = parts.reduce(0) { $0 + $1.payload.count }
    }
}

public struct SupportUploadRequestBuilder: Sendable {
    private let ticketID: String
    private let maximumPayloadSizeInBytes: Int
    private var parts: [SupportUploadPart]
    private var consentedCategories = Set<SupportUploadAttachmentCategory>()
    private var isBuilt = false

    public init(
        ticketID: String,
        message: String,
        maximumPayloadSizeInBytes: Int
    ) throws {
        guard maximumPayloadSizeInBytes > 0 else {
            throw SupportUploadRequestError.invalidMaximumPayloadSize
        }
        guard message.contains(where: { !$0.isWhitespace }) else {
            throw SupportUploadRequestError.emptyMessage
        }

        let messagePart = SupportUploadPart(
            kind: .message,
            contentType: "text/plain; charset=utf-8",
            payload: Array(message.utf8)
        )
        try Self.validatePayloadSize(
            messagePart.payload.count,
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )

        self.ticketID = ticketID
        self.maximumPayloadSizeInBytes = maximumPayloadSizeInBytes
        parts = [messagePart]
    }

    public mutating func grantConsent(
        for category: SupportUploadAttachmentCategory
    ) throws {
        try requireOpenBuilder()
        consentedCategories.insert(category)
    }

    public mutating func addDiagnostics(
        _ diagnostics: RedactedSupportDiagnostics
    ) throws {
        try requireConsent(for: .diagnostics)
        try append(
            SupportUploadPart(
                kind: .diagnostics,
                contentType: "application/json",
                payload: diagnostics.payload
            )
        )
    }

    public mutating func addScreenshot(_ screenshot: SupportScreenshot) throws {
        try requireConsent(for: .screenshots)
        try append(
            SupportUploadPart(
                kind: .screenshot(filename: screenshot.filename),
                contentType: "image/png",
                payload: screenshot.payload
            )
        )
    }

    public mutating func addScreenRecording(
        _ screenRecording: SupportScreenRecording
    ) throws {
        try requireConsent(for: .screenRecording)
        try append(
            SupportUploadPart(
                kind: .screenRecording(filename: screenRecording.filename),
                contentType: "video/mp4",
                payload: screenRecording.payload
            )
        )
    }

    public mutating func build() throws -> SupportUploadRequest {
        try requireOpenBuilder()
        isBuilt = true
        return SupportUploadRequest(ticketID: ticketID, parts: parts)
    }

    private func requireOpenBuilder() throws {
        guard !isBuilt else {
            throw SupportUploadRequestError.requestAlreadyBuilt
        }
    }

    private func requireConsent(
        for category: SupportUploadAttachmentCategory
    ) throws {
        try requireOpenBuilder()
        guard consentedCategories.contains(category) else {
            throw SupportUploadRequestError.consentRequired(for: category)
        }
    }

    private mutating func append(_ part: SupportUploadPart) throws {
        let actualSize = parts.reduce(0) { $0 + $1.payload.count }
            + part.payload.count
        try Self.validatePayloadSize(
            actualSize,
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )
        parts.append(part)
    }

    private static func validatePayloadSize(
        _ actualSize: Int,
        maximumPayloadSizeInBytes: Int
    ) throws {
        guard actualSize <= maximumPayloadSizeInBytes else {
            throw SupportUploadRequestError.payloadTooLarge(
                actualBytes: actualSize,
                maximumBytes: maximumPayloadSizeInBytes
            )
        }
    }
}
