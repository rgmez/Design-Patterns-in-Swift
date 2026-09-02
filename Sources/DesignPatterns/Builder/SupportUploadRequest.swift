public enum SupportUploadAttachmentCategory: Equatable, Sendable {
    case diagnostics
    case screenshots
    case screenRecording
}

public struct SupportUploadConsent: Equatable, Sendable {
    public let allowsDiagnostics: Bool
    public let allowsScreenshots: Bool
    public let allowsScreenRecording: Bool

    public init(
        allowsDiagnostics: Bool = false,
        allowsScreenshots: Bool = false,
        allowsScreenRecording: Bool = false
    ) {
        self.allowsDiagnostics = allowsDiagnostics
        self.allowsScreenshots = allowsScreenshots
        self.allowsScreenRecording = allowsScreenRecording
    }
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
}

public struct SupportUploadRequest: Equatable, Sendable {
    public let ticketID: String
    public let parts: [SupportUploadPart]
    public let totalPayloadSizeInBytes: Int

    public init(
        ticketID: String,
        message: String,
        diagnostics: RedactedSupportDiagnostics? = nil,
        screenshots: [SupportScreenshot] = [],
        screenRecording: SupportScreenRecording? = nil,
        consent: SupportUploadConsent = SupportUploadConsent(),
        maximumPayloadSizeInBytes: Int
    ) throws {
        guard message.contains(where: { !$0.isWhitespace }) else {
            throw SupportUploadRequestError.emptyMessage
        }
        guard maximumPayloadSizeInBytes > 0 else {
            throw SupportUploadRequestError.invalidMaximumPayloadSize
        }

        try Self.validateConsent(
            consent,
            diagnostics: diagnostics,
            screenshots: screenshots,
            screenRecording: screenRecording
        )

        var parts = [
            SupportUploadPart(
                kind: .message,
                contentType: "text/plain; charset=utf-8",
                payload: Array(message.utf8)
            )
        ]

        if let diagnostics {
            parts.append(
                SupportUploadPart(
                    kind: .diagnostics,
                    contentType: "application/json",
                    payload: diagnostics.payload
                )
            )
        }
        parts.append(contentsOf: screenshots.map(Self.makeScreenshotPart))
        if let screenRecording {
            parts.append(
                SupportUploadPart(
                    kind: .screenRecording(filename: screenRecording.filename),
                    contentType: "video/mp4",
                    payload: screenRecording.payload
                )
            )
        }

        let totalPayloadSizeInBytes = parts.reduce(0) { $0 + $1.payload.count }
        guard totalPayloadSizeInBytes <= maximumPayloadSizeInBytes else {
            throw SupportUploadRequestError.payloadTooLarge(
                actualBytes: totalPayloadSizeInBytes,
                maximumBytes: maximumPayloadSizeInBytes
            )
        }

        self.ticketID = ticketID
        self.parts = parts
        self.totalPayloadSizeInBytes = totalPayloadSizeInBytes
    }

    private static func validateConsent(
        _ consent: SupportUploadConsent,
        diagnostics: RedactedSupportDiagnostics?,
        screenshots: [SupportScreenshot],
        screenRecording: SupportScreenRecording?
    ) throws {
        if diagnostics != nil, !consent.allowsDiagnostics {
            throw SupportUploadRequestError.consentRequired(for: .diagnostics)
        }
        if !screenshots.isEmpty, !consent.allowsScreenshots {
            throw SupportUploadRequestError.consentRequired(for: .screenshots)
        }
        if screenRecording != nil, !consent.allowsScreenRecording {
            throw SupportUploadRequestError.consentRequired(for: .screenRecording)
        }
    }

    private static func makeScreenshotPart(
        _ screenshot: SupportScreenshot
    ) -> SupportUploadPart {
        SupportUploadPart(
            kind: .screenshot(filename: screenshot.filename),
            contentType: "image/png",
            payload: screenshot.payload
        )
    }
}
