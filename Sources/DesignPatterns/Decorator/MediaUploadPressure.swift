public struct MediaUploadBehaviorSelection: Equatable, Sendable {
    public let authenticatesRequests: Bool
    public let retriesConnectionLoss: Bool
    public let recordsMetrics: Bool

    public init(
        authenticatesRequests: Bool,
        retriesConnectionLoss: Bool,
        recordsMetrics: Bool
    ) {
        self.authenticatesRequests = authenticatesRequests
        self.retriesConnectionLoss = retriesConnectionLoss
        self.recordsMetrics = recordsMetrics
    }
}

public struct FlagConfiguredMediaUploadClient: Equatable, Sendable {
    public private(set) var transport: ScriptedMediaUploadTransport
    public private(set) var metrics = MediaUploadMetrics()

    private let behaviors: MediaUploadBehaviorSelection
    private let accessToken: String?
    private let retryLimit: Int

    public init(
        behaviors: MediaUploadBehaviorSelection,
        accessToken: String? = nil,
        retryLimit: Int,
        transport: ScriptedMediaUploadTransport
    ) throws {
        guard retryLimit >= 0 else {
            throw MediaUploadError.invalidRetryLimit
        }

        if behaviors.authenticatesRequests {
            guard let accessToken, !accessToken.isEmpty else {
                throw MediaUploadError.missingAccessToken
            }
            self.accessToken = accessToken
        } else {
            self.accessToken = nil
        }

        self.behaviors = behaviors
        self.retryLimit = retryLimit
        self.transport = transport
    }

    public mutating func upload(
        _ media: CreatorMediaUpload
    ) throws -> MediaUploadReceipt {
        var headers = [
            "Content-Type": media.contentType,
            "X-Upload-ID": media.id
        ]
        if let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }

        let request = MediaUploadHTTPRequest(
            method: "POST",
            path: media.destinationPath,
            headers: headers,
            body: media.payload
        )
        var attemptCount = 0

        while true {
            attemptCount += 1

            do {
                let response = try transport.send(request)
                return try finish(
                    response,
                    for: media.id,
                    attemptCount: attemptCount
                )
            } catch MediaUploadError.transportUnavailable {
                guard behaviors.retriesConnectionLoss,
                      attemptCount <= retryLimit else {
                    recordFailureIfEnabled(
                        .transportUnavailable,
                        uploadID: media.id,
                        attemptCount: attemptCount
                    )
                    throw MediaUploadError.transportUnavailable
                }
            }
        }
    }

    private mutating func finish(
        _ response: MediaUploadHTTPResponse,
        for uploadID: String,
        attemptCount: Int
    ) throws -> MediaUploadReceipt {
        guard (200..<300).contains(response.statusCode) else {
            let reason = MediaUploadFailureReason.rejected(
                statusCode: response.statusCode
            )
            recordFailureIfEnabled(
                reason,
                uploadID: uploadID,
                attemptCount: attemptCount
            )
            throw MediaUploadError.rejected(statusCode: response.statusCode)
        }
        guard let remoteAssetID = response.remoteAssetID,
              !remoteAssetID.isEmpty else {
            recordFailureIfEnabled(
                .malformedSuccess,
                uploadID: uploadID,
                attemptCount: attemptCount
            )
            throw MediaUploadError.missingRemoteAssetID
        }

        recordIfEnabled(
            MediaUploadMetric(
                uploadID: uploadID,
                attemptCount: attemptCount,
                outcome: .completed(remoteAssetID: remoteAssetID)
            )
        )
        return MediaUploadReceipt(
            uploadID: uploadID,
            remoteAssetID: remoteAssetID
        )
    }

    private mutating func recordFailureIfEnabled(
        _ reason: MediaUploadFailureReason,
        uploadID: String,
        attemptCount: Int
    ) {
        recordIfEnabled(
            MediaUploadMetric(
                uploadID: uploadID,
                attemptCount: attemptCount,
                outcome: .failed(reason)
            )
        )
    }

    private mutating func recordIfEnabled(_ metric: MediaUploadMetric) {
        guard behaviors.recordsMetrics else {
            return
        }
        metrics.record(metric)
    }
}
