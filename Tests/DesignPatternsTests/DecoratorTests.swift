import DesignPatterns
import Testing

@Suite("Decorator")
struct DecoratorTests {
    private static let uploadID = "upload-2048"
    private static let destinationPath = "/v1/media/videos"
    private static let payload: [UInt8] = [0x52, 0x47, 0x2D, 0x56]
    private static let contentType = "video/mp4"
    private static let accessToken = "creator-access-token"
    private static let remoteAssetID = "asset-8801"
    private static let retryLimit = 2

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

    private static func makeTransport(
        outcomes: [MediaUploadTransportOutcome]
    ) -> TransportMediaUploadClient {
        TransportMediaUploadClient(
            transport: ScriptedMediaUploadTransport(outcomes: outcomes)
        )
    }

    @Test("Production composes one measured, authenticated retry pipeline")
    func composesProductionPipeline() throws {
        var client = MeasuredMediaUpload(
            wrapped: try AuthenticatedMediaUpload(
                accessToken: DecoratorTests.accessToken,
                wrapped: RetryingMediaUpload(
                    retryLimit: DecoratorTests.retryLimit,
                    wrapped: DecoratorTests.makeTransport(
                        outcomes: [
                            .connectionLost,
                            .response(DecoratorTests.successfulResponse)
                        ]
                    )
                )
            )
        )

        let receipt = try client.upload(DecoratorTests.makeUpload())

        #expect(receipt.remoteAssetID == DecoratorTests.remoteAssetID)
        #expect(
            client.wrapped.wrapped.wrapped.transport.requests.count == 2
        )
        #expect(
            client.wrapped.wrapped.wrapped.transport.requests.allSatisfy {
                $0.headers["Authorization"]
                    == "Bearer \(DecoratorTests.accessToken)"
            }
        )
        #expect(
            client.metrics.events == [
                MediaUploadMetric(
                    uploadID: DecoratorTests.uploadID,
                    attemptCount: 2,
                    outcome: .completed(
                        remoteAssetID: DecoratorTests.remoteAssetID
                    )
                )
            ]
        )
    }

    @Test("Moving metrics inside retry records transport attempts")
    func makesOrderConsequencesVisible() throws {
        var client = try AuthenticatedMediaUpload(
            accessToken: DecoratorTests.accessToken,
            wrapped: RetryingMediaUpload(
                retryLimit: DecoratorTests.retryLimit,
                wrapped: MeasuredMediaUpload(
                    wrapped: DecoratorTests.makeTransport(
                        outcomes: [
                            .connectionLost,
                            .response(DecoratorTests.successfulResponse)
                        ]
                    )
                )
            )
        )

        _ = try client.upload(DecoratorTests.makeUpload())

        #expect(
            client.wrapped.wrapped.metrics.events == [
                MediaUploadMetric(
                    uploadID: DecoratorTests.uploadID,
                    attemptCount: 1,
                    outcome: .failed(.transportUnavailable)
                ),
                MediaUploadMetric(
                    uploadID: DecoratorTests.uploadID,
                    attemptCount: 2,
                    outcome: .completed(
                        remoteAssetID: DecoratorTests.remoteAssetID
                    )
                )
            ]
        )
    }

    @Test("Pre-signed uploads omit authentication without flags")
    func composesPreSignedPipeline() throws {
        var client = MeasuredMediaUpload(
            wrapped: try RetryingMediaUpload(
                retryLimit: DecoratorTests.retryLimit,
                wrapped: DecoratorTests.makeTransport(
                    outcomes: [
                        .connectionLost,
                        .response(DecoratorTests.successfulResponse)
                    ]
                )
            )
        )

        _ = try client.upload(DecoratorTests.makeUpload())

        #expect(
            client.wrapped.wrapped.transport.requests.allSatisfy {
                $0.headers["Authorization"] == nil
            }
        )
        #expect(client.metrics.events.first?.attemptCount == 2)
    }

    @Test("Metered uploads omit retry without conditional state")
    func composesMeteredNetworkPipeline() throws {
        var client = MeasuredMediaUpload(
            wrapped: try AuthenticatedMediaUpload(
                accessToken: DecoratorTests.accessToken,
                wrapped: DecoratorTests.makeTransport(
                    outcomes: [.connectionLost]
                )
            )
        )

        #expect(throws: MediaUploadError.transportUnavailable) {
            try client.upload(DecoratorTests.makeUpload())
        }

        #expect(client.wrapped.wrapped.transport.requests.count == 1)
        #expect(
            client.metrics.events.first?.outcome
                == .failed(.transportUnavailable)
        )
    }

    @Test("Telemetry opt-out omits metrics without disabling retry")
    func composesTelemetryOptOutPipeline() throws {
        var client = try AuthenticatedMediaUpload(
            accessToken: DecoratorTests.accessToken,
            wrapped: RetryingMediaUpload(
                retryLimit: DecoratorTests.retryLimit,
                wrapped: DecoratorTests.makeTransport(
                    outcomes: [
                        .connectionLost,
                        .response(DecoratorTests.successfulResponse)
                    ]
                )
            )
        )

        let receipt = try client.upload(DecoratorTests.makeUpload())

        #expect(receipt.remoteAssetID == DecoratorTests.remoteAssetID)
        #expect(client.wrapped.wrapped.transport.requests.count == 2)
    }

    @Test("Preview uses the transport component without wrappers")
    func composesPreviewPipeline() throws {
        var client = DecoratorTests.makeTransport(
            outcomes: [.response(DecoratorTests.successfulResponse)]
        )

        let receipt = try client.upload(DecoratorTests.makeUpload())

        #expect(receipt.remoteAssetID == DecoratorTests.remoteAssetID)
        let request = try #require(client.transport.requests.first)
        #expect(request.headers["Authorization"] == nil)
        #expect(client.transport.requests.count == 1)
    }

    @Test("HTTP rejection stays terminal inside a retry wrapper")
    func doesNotRetryHTTPRejection() throws {
        let rejectedStatusCode = 413
        var client = MeasuredMediaUpload(
            wrapped: try RetryingMediaUpload(
                retryLimit: DecoratorTests.retryLimit,
                wrapped: DecoratorTests.makeTransport(
                    outcomes: [
                        .response(
                            MediaUploadHTTPResponse(
                                statusCode: rejectedStatusCode
                            )
                        ),
                        .response(DecoratorTests.successfulResponse)
                    ]
                )
            )
        )

        #expect(
            throws: MediaUploadError.rejected(
                statusCode: rejectedStatusCode
            )
        ) {
            try client.upload(DecoratorTests.makeUpload())
        }

        #expect(client.wrapped.wrapped.transport.requests.count == 1)
        #expect(
            client.metrics.events.first?.outcome
                == .failed(.rejected(statusCode: rejectedStatusCode))
        )
    }
}
