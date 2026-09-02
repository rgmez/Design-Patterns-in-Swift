import DesignPatterns
import Testing

@Suite("Builder problem")
struct BuilderProblemTests {
    struct MissingConsentScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let category: SupportUploadAttachmentCategory
        let diagnostics: RedactedSupportDiagnostics?
        let screenshots: [SupportScreenshot]
        let screenRecording: SupportScreenRecording?

        var testDescription: String { name }
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
    private static let fullConsent = SupportUploadConsent(
        allowsDiagnostics: true,
        allowsScreenshots: true,
        allowsScreenRecording: true
    )
    private static let generousPayloadLimit = 1_024
    private static let missingConsentScenarios = [
        MissingConsentScenario(
            name: "diagnostics",
            category: .diagnostics,
            diagnostics: diagnostics,
            screenshots: [],
            screenRecording: nil
        ),
        MissingConsentScenario(
            name: "screenshots",
            category: .screenshots,
            diagnostics: nil,
            screenshots: screenshots,
            screenRecording: nil
        ),
        MissingConsentScenario(
            name: "screen recording",
            category: .screenRecording,
            diagnostics: nil,
            screenshots: [],
            screenRecording: screenRecording
        )
    ]

    @Suite("Conditional assembly")
    struct ConditionalAssembly {
        @Test("Creates a valid message-only request")
        func createsMessageOnlyRequest() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                message: BuilderProblemTests.message,
                maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
            )

            #expect(request.ticketID == BuilderProblemTests.ticketID)
            #expect(request.parts.map(\.kind) == [.message])
            #expect(request.parts.map(\.payload) == [BuilderProblemTests.messagePayload])
            #expect(
                request.totalPayloadSizeInBytes
                    == BuilderProblemTests.messagePayload.count
            )
        }

        @Test("Appends consented attachments in deterministic multipart order")
        func appendsAttachmentsInOrder() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                message: BuilderProblemTests.message,
                diagnostics: BuilderProblemTests.diagnostics,
                screenshots: BuilderProblemTests.screenshots,
                screenRecording: BuilderProblemTests.screenRecording,
                consent: BuilderProblemTests.fullConsent,
                maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
            )

            #expect(
                request.parts.map(\.kind) == [
                    .message,
                    .diagnostics,
                    .screenshot(filename: "checkout.png"),
                    .screenshot(filename: "spinner.png"),
                    .screenRecording(filename: "freeze.mp4")
                ]
            )
            #expect(request.parts.map(\.contentType) == [
                "text/plain; charset=utf-8",
                "application/json",
                "image/png",
                "image/png",
                "video/mp4"
            ])
        }
    }

    @Suite("Privacy")
    struct Privacy {
        @Test(
            "Rejects attachments without category-specific consent",
            arguments: BuilderProblemTests.missingConsentScenarios
        )
        func rejectsMissingConsent(_ scenario: MissingConsentScenario) {
            #expect(
                throws: SupportUploadRequestError.consentRequired(
                    for: scenario.category
                )
            ) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    message: BuilderProblemTests.message,
                    diagnostics: scenario.diagnostics,
                    screenshots: scenario.screenshots,
                    screenRecording: scenario.screenRecording,
                    maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
                )
            }
        }
    }

    @Suite("Validation")
    struct Validation {
        @Test("Rejects a blank support message")
        func rejectsBlankMessage() {
            #expect(throws: SupportUploadRequestError.emptyMessage) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    message: "   ",
                    maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
                )
            }
        }

        @Test("Rejects a non-positive configured payload limit")
        func rejectsInvalidPayloadLimit() {
            #expect(throws: SupportUploadRequestError.invalidMaximumPayloadSize) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    message: BuilderProblemTests.message,
                    maximumPayloadSizeInBytes: 0
                )
            }
        }

        @Test("Accepts a payload at the exact configured limit")
        func acceptsExactLimit() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                message: BuilderProblemTests.message,
                maximumPayloadSizeInBytes: BuilderProblemTests.messagePayload.count
            )

            #expect(
                request.totalPayloadSizeInBytes
                    == BuilderProblemTests.messagePayload.count
            )
        }

        @Test("Reports the measured size when the payload is too large")
        func rejectsOversizedPayload() {
            let limit = BuilderProblemTests.messagePayload.count - 1

            #expect(
                throws: SupportUploadRequestError.payloadTooLarge(
                    actualBytes: BuilderProblemTests.messagePayload.count,
                    maximumBytes: limit
                )
            ) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    message: BuilderProblemTests.message,
                    maximumPayloadSizeInBytes: limit
                )
            }
        }
    }
}
