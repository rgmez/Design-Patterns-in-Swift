import DesignPatterns
import Testing

@Suite("Builder pressure")
struct BuilderProblemTests {
    struct MissingConsentScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let category: SupportUploadAttachmentCategory
        let step: SupportUploadAssemblyStep

        var testDescription: String { name }
    }

    struct InvalidOrderScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let steps: [SupportUploadAssemblyStep]
        let error: SupportUploadRequestError

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
    private static let generousPayloadLimit = 1_024
    private static let missingConsentScenarios = [
        MissingConsentScenario(
            name: "diagnostics",
            category: .diagnostics,
            step: .diagnostics(diagnostics)
        ),
        MissingConsentScenario(
            name: "screenshots",
            category: .screenshots,
            step: .screenshot(screenshots[0])
        ),
        MissingConsentScenario(
            name: "screen recording",
            category: .screenRecording,
            step: .screenRecording(screenRecording)
        )
    ]
    private static let invalidOrderScenarios = [
        InvalidOrderScenario(
            name: "consent before message",
            steps: [.grantConsent(for: .diagnostics), .message(message), .finalize],
            error: .messageMustBeFirst
        ),
        InvalidOrderScenario(
            name: "message repeated",
            steps: [.message(message), .message(message), .finalize],
            error: .duplicateMessage
        ),
        InvalidOrderScenario(
            name: "step after finalization",
            steps: [.message(message), .finalize, .grantConsent(for: .diagnostics)],
            error: .stepAfterFinalization
        ),
        InvalidOrderScenario(
            name: "missing finalization",
            steps: [.message(message)],
            error: .requestNotFinalized
        )
    ]

    @Suite("Ordered assembly")
    struct OrderedAssembly {
        @Test("Creates a finalized message-only request")
        func createsMessageOnlyRequest() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                steps: [
                    .message(BuilderProblemTests.message),
                    .finalize
                ],
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

        @Test("Preserves accepted attachment order before finalization")
        func appendsAttachmentsInStepOrder() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                steps: [
                    .message(BuilderProblemTests.message),
                    .grantConsent(for: .diagnostics),
                    .diagnostics(BuilderProblemTests.diagnostics),
                    .grantConsent(for: .screenshots),
                    .screenshot(BuilderProblemTests.screenshots[0]),
                    .screenshot(BuilderProblemTests.screenshots[1]),
                    .grantConsent(for: .screenRecording),
                    .screenRecording(BuilderProblemTests.screenRecording),
                    .finalize
                ],
                maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
            )

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
    }

    @Suite("Privacy")
    struct Privacy {
        @Test(
            "Rejects an attachment whose consent step has not occurred",
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
                    steps: [
                        .message(BuilderProblemTests.message),
                        scenario.step,
                        .finalize
                    ],
                    maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
                )
            }
        }
    }

    @Suite("Construction order")
    struct ConstructionOrder {
        @Test(
            "Rejects representable but invalid step sequences",
            arguments: BuilderProblemTests.invalidOrderScenarios
        )
        func rejectsInvalidOrder(_ scenario: InvalidOrderScenario) {
            #expect(throws: scenario.error) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    steps: scenario.steps,
                    maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
                )
            }
        }
    }

    @Suite("Validation")
    struct Validation {
        @Test("Rejects a blank first message")
        func rejectsBlankMessage() {
            #expect(throws: SupportUploadRequestError.emptyMessage) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    steps: [.message("   "), .finalize],
                    maximumPayloadSizeInBytes: BuilderProblemTests.generousPayloadLimit
                )
            }
        }

        @Test("Rejects a non-positive configured payload limit")
        func rejectsInvalidPayloadLimit() {
            #expect(throws: SupportUploadRequestError.invalidMaximumPayloadSize) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    steps: [.message(BuilderProblemTests.message), .finalize],
                    maximumPayloadSizeInBytes: 0
                )
            }
        }

        @Test("Accepts a finalized payload at the exact configured limit")
        func acceptsExactLimit() throws {
            let request = try SupportUploadRequest(
                ticketID: BuilderProblemTests.ticketID,
                steps: [.message(BuilderProblemTests.message), .finalize],
                maximumPayloadSizeInBytes: BuilderProblemTests.messagePayload.count
            )

            #expect(
                request.totalPayloadSizeInBytes
                    == BuilderProblemTests.messagePayload.count
            )
        }

        @Test("Rejects an oversized initial message")
        func rejectsOversizedMessage() {
            let limit = BuilderProblemTests.messagePayload.count - 1

            #expect(
                throws: SupportUploadRequestError.payloadTooLarge(
                    actualBytes: BuilderProblemTests.messagePayload.count,
                    maximumBytes: limit
                )
            ) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    steps: [.message(BuilderProblemTests.message), .finalize],
                    maximumPayloadSizeInBytes: limit
                )
            }
        }

        @Test("Rejects an oversized attachment before finalization")
        func rejectsOversizedAttachmentImmediately() {
            let actualSize = BuilderProblemTests.messagePayload.count
                + BuilderProblemTests.diagnostics.payload.count
            let limit = actualSize - 1

            #expect(
                throws: SupportUploadRequestError.payloadTooLarge(
                    actualBytes: actualSize,
                    maximumBytes: limit
                )
            ) {
                try SupportUploadRequest(
                    ticketID: BuilderProblemTests.ticketID,
                    steps: [
                        .message(BuilderProblemTests.message),
                        .grantConsent(for: .diagnostics),
                        .diagnostics(BuilderProblemTests.diagnostics)
                    ],
                    maximumPayloadSizeInBytes: limit
                )
            }
        }
    }
}
