import DesignPatterns
import Testing

@Suite("Builder")
struct BuilderTests {
    enum AttachmentScenario: Sendable, CustomTestStringConvertible {
        case diagnostics
        case screenshot
        case screenRecording

        var category: SupportUploadAttachmentCategory {
            switch self {
            case .diagnostics:
                .diagnostics
            case .screenshot:
                .screenshots
            case .screenRecording:
                .screenRecording
            }
        }

        var testDescription: String {
            switch self {
            case .diagnostics:
                "diagnostics"
            case .screenshot:
                "screenshot"
            case .screenRecording:
                "screen recording"
            }
        }

        func add(to builder: inout SupportUploadRequestBuilder) throws {
            switch self {
            case .diagnostics:
                try builder.addDiagnostics(BuilderTests.diagnostics)
            case .screenshot:
                try builder.addScreenshot(BuilderTests.screenshots[0])
            case .screenRecording:
                try builder.addScreenRecording(BuilderTests.screenRecording)
            }
        }
    }

    private static let ticketID = "support-42"
    private static let message = "Checkout freezes after payment"
    private static let messagePayload = Array(message.utf8)
    private static let diagnostics = RedactedSupportDiagnostics(
        payload: [0x7B, 0x7D]
    )
    private static let screenshots = [
        SupportScreenshot(filename: "checkout.png", payload: [0x01, 0x02]),
        SupportScreenshot(filename: "spinner.png", payload: [0x03])
    ]
    private static let screenRecording = SupportScreenRecording(
        filename: "freeze.mp4",
        payload: [0x04, 0x05, 0x06]
    )
    private static let generousPayloadLimit = 1_024
    private static let attachmentScenarios: [AttachmentScenario] = [
        .diagnostics,
        .screenshot,
        .screenRecording
    ]

    @Suite("Construction")
    struct Construction {
        @Test("Builds a message-only request")
        func buildsMessageOnlyRequest() throws {
            var builder = try BuilderTests.makeBuilder()

            let request = try builder.build()

            #expect(request.ticketID == BuilderTests.ticketID)
            #expect(request.parts.map(\.kind) == [.message])
            #expect(request.parts.map(\.payload) == [BuilderTests.messagePayload])
            #expect(
                request.totalPayloadSizeInBytes
                    == BuilderTests.messagePayload.count
            )
        }

        @Test("Preserves accepted attachment order")
        func preservesAttachmentOrder() throws {
            var builder = try BuilderTests.makeBuilder()
            try builder.grantConsent(for: .diagnostics)
            try builder.addDiagnostics(BuilderTests.diagnostics)
            try builder.grantConsent(for: .screenshots)
            try builder.addScreenshot(BuilderTests.screenshots[0])
            try builder.addScreenshot(BuilderTests.screenshots[1])
            try builder.grantConsent(for: .screenRecording)
            try builder.addScreenRecording(BuilderTests.screenRecording)

            let request = try builder.build()

            #expect(request.parts.map(\.kind) == [
                .message,
                .diagnostics,
                .screenshot(filename: "checkout.png"),
                .screenshot(filename: "spinner.png"),
                .screenRecording(filename: "freeze.mp4")
            ])
            #expect(request.parts.map(\.contentType) == [
                "text/plain; charset=utf-8",
                "application/json",
                "image/png",
                "image/png",
                "video/mp4"
            ])
        }

        @Test("Seals the builder after producing the request")
        func sealsAfterBuild() throws {
            var builder = try BuilderTests.makeBuilder()
            _ = try builder.build()

            #expect(throws: SupportUploadRequestError.requestAlreadyBuilt) {
                try builder.grantConsent(for: .diagnostics)
            }
            #expect(throws: SupportUploadRequestError.requestAlreadyBuilt) {
                try builder.build()
            }
        }
    }

    @Suite("Privacy")
    struct Privacy {
        @Test(
            "Rejects attachments before category consent",
            arguments: BuilderTests.attachmentScenarios
        )
        func rejectsMissingConsent(_ scenario: AttachmentScenario) throws {
            var builder = try BuilderTests.makeBuilder()

            #expect(
                throws: SupportUploadRequestError.consentRequired(
                    for: scenario.category
                )
            ) {
                try scenario.add(to: &builder)
            }
        }
    }

    @Suite("Validation")
    struct Validation {
        @Test("Rejects a blank initial message")
        func rejectsBlankMessage() {
            #expect(throws: SupportUploadRequestError.emptyMessage) {
                try BuilderTests.makeBuilder(message: "   ")
            }
        }

        @Test("Rejects a non-positive configured payload limit")
        func rejectsInvalidPayloadLimit() {
            #expect(throws: SupportUploadRequestError.invalidMaximumPayloadSize) {
                try BuilderTests.makeBuilder(maximumPayloadSizeInBytes: 0)
            }
        }

        @Test("Accepts an initial message at the exact configured limit")
        func acceptsExactLimit() throws {
            var builder = try BuilderTests.makeBuilder(
                maximumPayloadSizeInBytes: BuilderTests.messagePayload.count
            )

            let request = try builder.build()

            #expect(
                request.totalPayloadSizeInBytes
                    == BuilderTests.messagePayload.count
            )
        }

        @Test("Rejects an oversized initial message")
        func rejectsOversizedMessage() {
            let limit = BuilderTests.messagePayload.count - 1

            #expect(
                throws: SupportUploadRequestError.payloadTooLarge(
                    actualBytes: BuilderTests.messagePayload.count,
                    maximumBytes: limit
                )
            ) {
                try BuilderTests.makeBuilder(
                    maximumPayloadSizeInBytes: limit
                )
            }
        }

        @Test("Rejects an oversized attachment immediately")
        func rejectsOversizedAttachmentImmediately() throws {
            let actualSize = BuilderTests.messagePayload.count
                + BuilderTests.diagnostics.payload.count
            let limit = actualSize - 1
            var builder = try BuilderTests.makeBuilder(
                maximumPayloadSizeInBytes: limit
            )
            try builder.grantConsent(for: .diagnostics)

            #expect(
                throws: SupportUploadRequestError.payloadTooLarge(
                    actualBytes: actualSize,
                    maximumBytes: limit
                )
            ) {
                try builder.addDiagnostics(BuilderTests.diagnostics)
            }
        }
    }

    @Suite("Value semantics")
    struct ValueSemantics {
        @Test("Keeps copied construction state independent")
        func keepsCopiesIndependent() throws {
            var original = try BuilderTests.makeBuilder()
            var copy = original
            try copy.grantConsent(for: .diagnostics)
            try copy.addDiagnostics(BuilderTests.diagnostics)

            let originalRequest = try original.build()
            let copiedRequest = try copy.build()

            #expect(originalRequest.parts.map(\.kind) == [.message])
            #expect(copiedRequest.parts.map(\.kind) == [.message, .diagnostics])
        }
    }

    private static func makeBuilder(
        message: String = BuilderTests.message,
        maximumPayloadSizeInBytes: Int = BuilderTests.generousPayloadLimit
    ) throws -> SupportUploadRequestBuilder {
        try SupportUploadRequestBuilder(
            ticketID: ticketID,
            message: message,
            maximumPayloadSizeInBytes: maximumPayloadSizeInBytes
        )
    }
}
