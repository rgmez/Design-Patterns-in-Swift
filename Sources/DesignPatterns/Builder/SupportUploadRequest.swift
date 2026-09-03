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

public enum SupportUploadAssemblyStep: Equatable, Sendable {
    case message(String)
    case grantConsent(for: SupportUploadAttachmentCategory)
    case diagnostics(RedactedSupportDiagnostics)
    case screenshot(SupportScreenshot)
    case screenRecording(SupportScreenRecording)
    case finalize
}

public enum SupportUploadRequestError: Error, Equatable, Sendable {
    case emptyMessage
    case invalidMaximumPayloadSize
    case messageMustBeFirst
    case duplicateMessage
    case consentRequired(for: SupportUploadAttachmentCategory)
    case payloadTooLarge(actualBytes: Int, maximumBytes: Int)
    case stepAfterFinalization
    case requestNotFinalized
}

public struct SupportUploadRequest: Equatable, Sendable {
    public let ticketID: String
    public let parts: [SupportUploadPart]
    public let totalPayloadSizeInBytes: Int

    public init(
        ticketID: String,
        steps: [SupportUploadAssemblyStep],
        maximumPayloadSizeInBytes: Int
    ) throws {
        guard maximumPayloadSizeInBytes > 0 else {
            throw SupportUploadRequestError.invalidMaximumPayloadSize
        }

        var parts = try Self.makeInitialParts(from: steps.first)
        try Self.validatePayloadSize(
            parts,
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )
        var consentedCategories = Set<SupportUploadAttachmentCategory>()
        var isFinalized = false

        for step in steps.dropFirst() {
            try Self.apply(
                step,
                to: &parts,
                consentedCategories: &consentedCategories,
                isFinalized: &isFinalized,
                maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
            )
        }
        guard isFinalized else {
            throw SupportUploadRequestError.requestNotFinalized
        }

        self.ticketID = ticketID
        self.parts = parts
        self.totalPayloadSizeInBytes = Self.payloadSize(of: parts)
    }

    private static func makeInitialParts(
        from step: SupportUploadAssemblyStep?
    ) throws -> [SupportUploadPart] {
        guard case .message(let message) = step else {
            throw SupportUploadRequestError.messageMustBeFirst
        }
        guard message.contains(where: { !$0.isWhitespace }) else {
            throw SupportUploadRequestError.emptyMessage
        }

        return [
            SupportUploadPart(
                kind: .message,
                contentType: "text/plain; charset=utf-8",
                payload: Array(message.utf8)
            )
        ]
    }

    private static func apply(
        _ step: SupportUploadAssemblyStep,
        to parts: inout [SupportUploadPart],
        consentedCategories: inout Set<SupportUploadAttachmentCategory>,
        isFinalized: inout Bool,
        maximumPayloadSizeInBytes: Int
    ) throws {
        guard !isFinalized else {
            throw SupportUploadRequestError.stepAfterFinalization
        }

        switch step {
        case .message:
            throw SupportUploadRequestError.duplicateMessage
        case .grantConsent(let category):
            consentedCategories.insert(category)
        case .diagnostics(let diagnostics):
            try requireConsent(.diagnostics, in: consentedCategories)
            try append(
                SupportUploadPart(
                    kind: .diagnostics,
                    contentType: "application/json",
                    payload: diagnostics.payload
                ),
                to: &parts,
                maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
            )
        case .screenshot(let screenshot):
            try requireConsent(.screenshots, in: consentedCategories)
            try append(
                makeScreenshotPart(screenshot),
                to: &parts,
                maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
            )
        case .screenRecording(let screenRecording):
            try requireConsent(.screenRecording, in: consentedCategories)
            try append(
                SupportUploadPart(
                    kind: .screenRecording(filename: screenRecording.filename),
                    contentType: "video/mp4",
                    payload: screenRecording.payload
                ),
                to: &parts,
                maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
            )
        case .finalize:
            isFinalized = true
        }
    }

    private static func requireConsent(
        _ category: SupportUploadAttachmentCategory,
        in consentedCategories: Set<SupportUploadAttachmentCategory>
    ) throws {
        guard consentedCategories.contains(category) else {
            throw SupportUploadRequestError.consentRequired(for: category)
        }
    }

    private static func append(
        _ part: SupportUploadPart,
        to parts: inout [SupportUploadPart],
        maximumPayloadSizeInBytes: Int
    ) throws {
        let actualSize = payloadSize(of: parts) + part.payload.count
        try validatePayloadSize(
            actualSize,
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )
        parts.append(part)
    }

    private static func payloadSize(of parts: [SupportUploadPart]) -> Int {
        parts.reduce(0) { $0 + $1.payload.count }
    }

    private static func validatePayloadSize(
        _ parts: [SupportUploadPart],
        maximumPayloadSizeInBytes: Int
    ) throws {
        try validatePayloadSize(
            payloadSize(of: parts),
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )
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
