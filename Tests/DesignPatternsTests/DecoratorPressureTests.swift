import DesignPatterns
import Testing

@Suite("Decorator pressure")
struct DecoratorPressureTests {
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

    private static func makeClient(
        authenticatesRequests: Bool,
        retriesConnectionLoss: Bool,
        recordsMetrics: Bool,
        outcomes: [MediaUploadTransportOutcome]
    ) throws -> FlagConfiguredMediaUploadClient {
        try FlagConfiguredMediaUploadClient(
            behaviors: MediaUploadBehaviorSelection(
                authenticatesRequests: authenticatesRequests,
                retriesConnectionLoss: retriesConnectionLoss,
                recordsMetrics: recordsMetrics
            ),
            accessToken: authenticatesRequests ? accessToken : nil,
            retryLimit: retryLimit,
            transport: ScriptedMediaUploadTransport(outcomes: outcomes)
        )
    }

    @Test("Production upload authenticates, retries, and measures once")
    func productionProfile() throws {
        var client = try DecoratorPressureTests.makeClient(
            authenticatesRequests: true,
            retriesConnectionLoss: true,
            recordsMetrics: true,
            outcomes: [
                .connectionLost,
                .response(DecoratorPressureTests.successfulResponse)
            ]
        )

        _ = try client.upload(DecoratorPressureTests.makeUpload())

        #expect(client.transport.requests.count == 2)
        #expect(
            client.transport.requests.allSatisfy {
                $0.headers["Authorization"]
                    == "Bearer \(DecoratorPressureTests.accessToken)"
            }
        )
        #expect(
            client.metrics.events == [
                MediaUploadMetric(
                    uploadID: DecoratorPressureTests.uploadID,
                    attemptCount: 2,
                    outcome: .completed(
                        remoteAssetID: DecoratorPressureTests.remoteAssetID
                    )
                )
            ]
        )
    }

    @Test("Pre-signed upload retries without adding Bearer authentication")
    func preSignedProfile() throws {
        var client = try DecoratorPressureTests.makeClient(
            authenticatesRequests: false,
            retriesConnectionLoss: true,
            recordsMetrics: true,
            outcomes: [
                .connectionLost,
                .response(DecoratorPressureTests.successfulResponse)
            ]
        )

        _ = try client.upload(DecoratorPressureTests.makeUpload())

        #expect(client.transport.requests.count == 2)
        #expect(
            client.transport.requests.allSatisfy {
                $0.headers["Authorization"] == nil
            }
        )
        #expect(client.metrics.events.first?.attemptCount == 2)
    }

    @Test("Metered-network upload authenticates but does not retry")
    func meteredNetworkProfile() throws {
        var client = try DecoratorPressureTests.makeClient(
            authenticatesRequests: true,
            retriesConnectionLoss: false,
            recordsMetrics: true,
            outcomes: [
                .connectionLost,
                .response(DecoratorPressureTests.successfulResponse)
            ]
        )

        #expect(throws: MediaUploadError.transportUnavailable) {
            try client.upload(DecoratorPressureTests.makeUpload())
        }

        #expect(client.transport.requests.count == 1)
        #expect(
            client.metrics.events == [
                MediaUploadMetric(
                    uploadID: DecoratorPressureTests.uploadID,
                    attemptCount: 1,
                    outcome: .failed(.transportUnavailable)
                )
            ]
        )
    }

    @Test("Telemetry opt-out preserves retry without recording a metric")
    func telemetryOptOutProfile() throws {
        var client = try DecoratorPressureTests.makeClient(
            authenticatesRequests: true,
            retriesConnectionLoss: true,
            recordsMetrics: false,
            outcomes: [
                .connectionLost,
                .response(DecoratorPressureTests.successfulResponse)
            ]
        )

        let receipt = try client.upload(DecoratorPressureTests.makeUpload())

        #expect(receipt.remoteAssetID == DecoratorPressureTests.remoteAssetID)
        #expect(client.transport.requests.count == 2)
        #expect(client.metrics.events.isEmpty)
    }

    @Test("Minimal preview upload adds no optional behavior")
    func minimalPreviewProfile() throws {
        var client = try DecoratorPressureTests.makeClient(
            authenticatesRequests: false,
            retriesConnectionLoss: false,
            recordsMetrics: false,
            outcomes: [.response(DecoratorPressureTests.successfulResponse)]
        )

        _ = try client.upload(DecoratorPressureTests.makeUpload())

        let request = try #require(client.transport.requests.first)
        #expect(request.headers["Authorization"] == nil)
        #expect(client.transport.requests.count == 1)
        #expect(client.metrics.events.isEmpty)
    }

    @Test("Authentication still requires a token when selected")
    func validatesConditionalAuthenticationConfiguration() {
        #expect(throws: MediaUploadError.missingAccessToken) {
            try FlagConfiguredMediaUploadClient(
                behaviors: MediaUploadBehaviorSelection(
                    authenticatesRequests: true,
                    retriesConnectionLoss: false,
                    recordsMetrics: false
                ),
                retryLimit: DecoratorPressureTests.retryLimit,
                transport: ScriptedMediaUploadTransport(outcomes: [])
            )
        }
    }
}
