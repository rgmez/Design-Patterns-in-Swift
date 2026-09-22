import DesignPatterns
import Testing

@Suite("Decorator problem")
struct DecoratorProblemTests {
    private static let uploadID = "upload-2048"
    private static let destinationPath = "/v1/media/videos"
    private static let payload: [UInt8] = [0x52, 0x47, 0x2D, 0x56]
    private static let contentType = "video/mp4"
    private static let accessToken = "creator-access-token"
    private static let remoteAssetID = "asset-8801"
    private static let defaultRetryLimit = 2

    private static let successfulResponse = MediaUploadHTTPResponse(
        statusCode: 201,
        remoteAssetID: remoteAssetID
    )

    private static func makeUpload() throws -> CreatorMediaUpload {
        try CreatorMediaUpload(
            id: uploadID,
            destinationPath: destinationPath,
            payload: payload,
            contentType: contentType
        )
    }

    private static func makeClient(
        retryLimit: Int = defaultRetryLimit,
        outcomes: [MediaUploadTransportOutcome]
    ) throws -> DirectMediaUploadClient {
        try DirectMediaUploadClient(
            accessToken: accessToken,
            retryLimit: retryLimit,
            transport: ScriptedMediaUploadTransport(outcomes: outcomes)
        )
    }

    private static var expectedRequest: MediaUploadHTTPRequest {
        MediaUploadHTTPRequest(
            method: "POST",
            path: destinationPath,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": contentType,
                "X-Upload-ID": uploadID
            ],
            body: payload
        )
    }

    @Suite("Successful upload")
    struct SuccessfulUpload {
        @Test("Authenticates and sends the media request")
        func authenticatesRequest() throws {
            var client = try DecoratorProblemTests.makeClient(
                outcomes: [.response(DecoratorProblemTests.successfulResponse)]
            )

            let receipt = try client.upload(
                DecoratorProblemTests.makeUpload()
            )

            #expect(
                receipt == MediaUploadReceipt(
                    uploadID: DecoratorProblemTests.uploadID,
                    remoteAssetID: DecoratorProblemTests.remoteAssetID
                )
            )
            #expect(
                client.transport.requests
                    == [DecoratorProblemTests.expectedRequest]
            )
        }

        @Test("Records one terminal success metric")
        func recordsSuccess() throws {
            var client = try DecoratorProblemTests.makeClient(
                outcomes: [.response(DecoratorProblemTests.successfulResponse)]
            )

            _ = try client.upload(DecoratorProblemTests.makeUpload())

            #expect(
                client.metrics.events == [
                    MediaUploadMetric(
                        uploadID: DecoratorProblemTests.uploadID,
                        attemptCount: 1,
                        outcome: .completed(
                            remoteAssetID: DecoratorProblemTests.remoteAssetID
                        )
                    )
                ]
            )
        }
    }

    @Suite("Retry policy")
    struct RetryPolicy {
        @Test("Retries a transient connection failure")
        func retriesConnectionFailure() throws {
            var client = try DecoratorProblemTests.makeClient(
                outcomes: [
                    .connectionLost,
                    .response(DecoratorProblemTests.successfulResponse)
                ]
            )

            _ = try client.upload(DecoratorProblemTests.makeUpload())

            #expect(
                client.transport.requests == [
                    DecoratorProblemTests.expectedRequest,
                    DecoratorProblemTests.expectedRequest
                ]
            )
            #expect(client.metrics.events.first?.attemptCount == 2)
        }

        @Test("Stops after the configured retry budget")
        func exhaustsRetryBudget() throws {
            let retryLimit = 2
            let expectedAttemptCount = retryLimit + 1
            var client = try DecoratorProblemTests.makeClient(
                retryLimit: retryLimit,
                outcomes: Array(
                    repeating: .connectionLost,
                    count: expectedAttemptCount
                )
            )

            #expect(throws: MediaUploadError.transportUnavailable) {
                try client.upload(DecoratorProblemTests.makeUpload())
            }
            #expect(client.transport.requests.count == expectedAttemptCount)
            #expect(
                client.metrics.events == [
                    MediaUploadMetric(
                        uploadID: DecoratorProblemTests.uploadID,
                        attemptCount: expectedAttemptCount,
                        outcome: .failed(.transportUnavailable)
                    )
                ]
            )
        }
    }

    @Suite("Terminal rejection")
    struct TerminalRejection {
        @Test("Does not retry an HTTP rejection")
        func doesNotRetryRejection() throws {
            let rejectedStatusCode = 401
            var client = try DecoratorProblemTests.makeClient(
                outcomes: [
                    .response(
                        MediaUploadHTTPResponse(
                            statusCode: rejectedStatusCode
                        )
                    ),
                    .response(DecoratorProblemTests.successfulResponse)
                ]
            )

            #expect(
                throws: MediaUploadError.rejected(
                    statusCode: rejectedStatusCode
                )
            ) {
                try client.upload(DecoratorProblemTests.makeUpload())
            }
            #expect(client.transport.requests.count == 1)
            #expect(
                client.metrics.events == [
                    MediaUploadMetric(
                        uploadID: DecoratorProblemTests.uploadID,
                        attemptCount: 1,
                        outcome: .failed(
                            .rejected(statusCode: rejectedStatusCode)
                        )
                    )
                ]
            )
        }

        @Test("Rejects a successful response without an asset identifier")
        func rejectsMalformedSuccess() throws {
            var client = try DecoratorProblemTests.makeClient(
                outcomes: [
                    .response(MediaUploadHTTPResponse(statusCode: 201))
                ]
            )

            #expect(throws: MediaUploadError.missingRemoteAssetID) {
                try client.upload(DecoratorProblemTests.makeUpload())
            }
            #expect(
                client.metrics.events.first?.outcome
                    == .failed(.malformedSuccess)
            )
        }
    }
}

extension DecoratorProblemTests {
    @Suite("Input validation")
    struct InputValidation {
        struct InvalidUploadScenario: Sendable, CustomTestStringConvertible {
            let name: String
            let id: String
            let path: String
            let payload: [UInt8]
            let contentType: String
            let expectedError: MediaUploadError

            var testDescription: String { name }
        }

        private static let scenarios = [
            InvalidUploadScenario(
                name: "missing upload identifier",
                id: "",
                path: DecoratorProblemTests.destinationPath,
                payload: DecoratorProblemTests.payload,
                contentType: DecoratorProblemTests.contentType,
                expectedError: .missingUploadID
            ),
            InvalidUploadScenario(
                name: "non-absolute destination path",
                id: DecoratorProblemTests.uploadID,
                path: "v1/media/videos",
                payload: DecoratorProblemTests.payload,
                contentType: DecoratorProblemTests.contentType,
                expectedError: .invalidDestinationPath
            ),
            InvalidUploadScenario(
                name: "empty payload",
                id: DecoratorProblemTests.uploadID,
                path: DecoratorProblemTests.destinationPath,
                payload: [],
                contentType: DecoratorProblemTests.contentType,
                expectedError: .emptyPayload
            ),
            InvalidUploadScenario(
                name: "missing content type",
                id: DecoratorProblemTests.uploadID,
                path: DecoratorProblemTests.destinationPath,
                payload: DecoratorProblemTests.payload,
                contentType: "",
                expectedError: .missingContentType
            )
        ]

        @Test("Rejects an invalid upload", arguments: scenarios)
        func rejectsInvalidUpload(_ scenario: InvalidUploadScenario) {
            #expect(throws: scenario.expectedError) {
                try CreatorMediaUpload(
                    id: scenario.id,
                    destinationPath: scenario.path,
                    payload: scenario.payload,
                    contentType: scenario.contentType
                )
            }
        }

        @Test("Rejects an empty access token")
        func rejectsEmptyAccessToken() {
            #expect(throws: MediaUploadError.missingAccessToken) {
                try DirectMediaUploadClient(
                    accessToken: "",
                    retryLimit: DecoratorProblemTests.defaultRetryLimit,
                    transport: ScriptedMediaUploadTransport(outcomes: [])
                )
            }
        }

        @Test("Rejects a negative retry limit")
        func rejectsNegativeRetryLimit() {
            #expect(throws: MediaUploadError.invalidRetryLimit) {
                try DirectMediaUploadClient(
                    accessToken: DecoratorProblemTests.accessToken,
                    retryLimit: -1,
                    transport: ScriptedMediaUploadTransport(outcomes: [])
                )
            }
        }
    }
}
