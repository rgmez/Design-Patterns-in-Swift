public struct MediaUploadCall: Sendable {
    fileprivate var headers: [String: String]
    public fileprivate(set) var attemptCount = 0

    fileprivate init(media: CreatorMediaUpload) {
        headers = [
            "Content-Type": media.contentType,
            "X-Upload-ID": media.id
        ]
    }
}

public protocol MediaUploadClient: Sendable {
    mutating func upload(
        _ media: CreatorMediaUpload,
        call: inout MediaUploadCall
    ) throws -> MediaUploadReceipt
}

public extension MediaUploadClient {
    mutating func upload(
        _ media: CreatorMediaUpload
    ) throws -> MediaUploadReceipt {
        var call = MediaUploadCall(media: media)
        return try upload(media, call: &call)
    }
}

public struct TransportMediaUploadClient: MediaUploadClient {
    public private(set) var transport: ScriptedMediaUploadTransport

    public init(transport: ScriptedMediaUploadTransport) {
        self.transport = transport
    }

    public mutating func upload(
        _ media: CreatorMediaUpload,
        call: inout MediaUploadCall
    ) throws -> MediaUploadReceipt {
        let request = MediaUploadHTTPRequest(
            method: "POST",
            path: media.destinationPath,
            headers: call.headers,
            body: media.payload
        )
        call.attemptCount += 1

        let response = try transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw MediaUploadError.rejected(statusCode: response.statusCode)
        }
        guard let remoteAssetID = response.remoteAssetID,
              !remoteAssetID.isEmpty else {
            throw MediaUploadError.missingRemoteAssetID
        }

        return MediaUploadReceipt(
            uploadID: media.id,
            remoteAssetID: remoteAssetID
        )
    }
}

public struct AuthenticatedMediaUpload<Wrapped: MediaUploadClient>:
    MediaUploadClient {
    public private(set) var wrapped: Wrapped

    private let accessToken: String

    public init(
        accessToken: String,
        wrapped: Wrapped
    ) throws {
        guard !accessToken.isEmpty else {
            throw MediaUploadError.missingAccessToken
        }

        self.accessToken = accessToken
        self.wrapped = wrapped
    }

    public mutating func upload(
        _ media: CreatorMediaUpload,
        call: inout MediaUploadCall
    ) throws -> MediaUploadReceipt {
        call.headers["Authorization"] = "Bearer \(accessToken)"
        return try wrapped.upload(media, call: &call)
    }
}

public struct RetryingMediaUpload<Wrapped: MediaUploadClient>:
    MediaUploadClient {
    public private(set) var wrapped: Wrapped

    private let retryLimit: Int

    public init(
        retryLimit: Int,
        wrapped: Wrapped
    ) throws {
        guard retryLimit >= 0 else {
            throw MediaUploadError.invalidRetryLimit
        }

        self.retryLimit = retryLimit
        self.wrapped = wrapped
    }

    public mutating func upload(
        _ media: CreatorMediaUpload,
        call: inout MediaUploadCall
    ) throws -> MediaUploadReceipt {
        while true {
            do {
                return try wrapped.upload(media, call: &call)
            } catch MediaUploadError.transportUnavailable {
                guard call.attemptCount <= retryLimit else {
                    throw MediaUploadError.transportUnavailable
                }
            }
        }
    }
}

public struct MeasuredMediaUpload<Wrapped: MediaUploadClient>:
    MediaUploadClient {
    public private(set) var wrapped: Wrapped
    public private(set) var metrics = MediaUploadMetrics()

    public init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }

    public mutating func upload(
        _ media: CreatorMediaUpload,
        call: inout MediaUploadCall
    ) throws -> MediaUploadReceipt {
        do {
            let receipt = try wrapped.upload(media, call: &call)
            metrics.record(
                MediaUploadMetric(
                    uploadID: media.id,
                    attemptCount: call.attemptCount,
                    outcome: .completed(
                        remoteAssetID: receipt.remoteAssetID
                    )
                )
            )
            return receipt
        } catch let error as MediaUploadError {
            if let reason = failureReason(for: error) {
                metrics.record(
                    MediaUploadMetric(
                        uploadID: media.id,
                        attemptCount: call.attemptCount,
                        outcome: .failed(reason)
                    )
                )
            }
            throw error
        }
    }

    private func failureReason(
        for error: MediaUploadError
    ) -> MediaUploadFailureReason? {
        switch error {
        case .transportUnavailable:
            .transportUnavailable
        case let .rejected(statusCode):
            .rejected(statusCode: statusCode)
        case .missingRemoteAssetID:
            .malformedSuccess
        case .missingUploadID,
             .invalidDestinationPath,
             .emptyPayload,
             .missingContentType,
             .missingAccessToken,
             .invalidRetryLimit:
            nil
        }
    }
}
