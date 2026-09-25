import DesignPatterns
import Testing

@Suite("Decorator policy boundaries")
struct DecoratorBoundaryTests {
    private static let retryLimit = 2
    private static let remoteAssetID = "asset-boundary"

    private static func makeUpload() throws -> CreatorMediaUpload {
        try CreatorMediaUpload(
            id: "upload-boundary",
            destinationPath: "/media",
            payload: [1],
            contentType: "video/mp4"
        )
    }

    private struct FailingUpload: MediaUploadClient {
        var calls = 0

        mutating func upload(
            _ media: CreatorMediaUpload,
            call: inout MediaUploadCall
        ) throws -> MediaUploadReceipt {
            calls += 1
            if calls > DecoratorBoundaryTests.retryLimit + 1 {
                throw MediaUploadError.missingRemoteAssetID
            }
            throw MediaUploadError.transportUnavailable
        }
    }

    @Suite("Retry ownership")
    struct RetryOwnership {
        @Test("Retry bounds forwarding even when the wrapped client never sends")
        func boundsFailuresBeforeTransport() throws {
            var client = try RetryingMediaUpload(
                retryLimit: DecoratorBoundaryTests.retryLimit,
                wrapped: FailingUpload()
            )

            #expect(throws: MediaUploadError.transportUnavailable) {
                try client.upload(DecoratorBoundaryTests.makeUpload())
            }
            #expect(client.wrapped.calls == DecoratorBoundaryTests.retryLimit + 1)
        }

        @Test("Every logical upload gets a fresh retry budget and metric count")
        func resetsBetweenUploads() throws {
            let response = MediaUploadHTTPResponse(
                statusCode: 201,
                remoteAssetID: DecoratorBoundaryTests.remoteAssetID
            )
            var client = MeasuredMediaUpload(
                wrapped: try RetryingMediaUpload(
                    retryLimit: 1,
                    wrapped: TransportMediaUploadClient(
                        transport: ScriptedMediaUploadTransport(outcomes: [
                            .connectionLost, .response(response),
                            .connectionLost, .response(response)
                        ])
                    )
                )
            )

            let first = try client.upload(DecoratorBoundaryTests.makeUpload())
            let second = try client.upload(DecoratorBoundaryTests.makeUpload())

            #expect(first.remoteAssetID == DecoratorBoundaryTests.remoteAssetID)
            #expect(second.remoteAssetID == DecoratorBoundaryTests.remoteAssetID)
            #expect(client.metrics.events.map(\.attemptCount) == [2, 2])
            #expect(client.wrapped.wrapped.transport.requests.count == 4)
        }

        @Test("Malformed success is terminal and measured once")
        func propagatesMalformedSuccess() throws {
            var client = MeasuredMediaUpload(
                wrapped: try RetryingMediaUpload(
                    retryLimit: DecoratorBoundaryTests.retryLimit,
                    wrapped: TransportMediaUploadClient(
                        transport: ScriptedMediaUploadTransport(outcomes: [
                            .response(MediaUploadHTTPResponse(statusCode: 201))
                        ])
                    )
                )
            )

            #expect(throws: MediaUploadError.missingRemoteAssetID) {
                try client.upload(DecoratorBoundaryTests.makeUpload())
            }
            #expect(client.wrapped.wrapped.transport.requests.count == 1)
            #expect(client.metrics.events.count == 1)
            #expect(client.metrics.events.first?.outcome == .failed(.malformedSuccess))
        }
    }
}
