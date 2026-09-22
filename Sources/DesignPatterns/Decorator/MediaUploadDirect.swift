public struct CreatorMediaUpload: Equatable, Sendable {
    public let id: String
    public let destinationPath: String
    public let payload: [UInt8]
    public let contentType: String

    public init(
        id: String,
        destinationPath: String,
        payload: [UInt8],
        contentType: String
    ) throws {
        guard !id.isEmpty else {
            throw MediaUploadError.missingUploadID
        }
        guard destinationPath.hasPrefix("/") else {
            throw MediaUploadError.invalidDestinationPath
        }
        guard !payload.isEmpty else {
            throw MediaUploadError.emptyPayload
        }
        guard !contentType.isEmpty else {
            throw MediaUploadError.missingContentType
        }

        self.id = id
        self.destinationPath = destinationPath
        self.payload = payload
        self.contentType = contentType
    }
}

public struct MediaUploadHTTPRequest: Equatable, Sendable {
    public let method: String
    public let path: String
    public let headers: [String: String]
    public let body: [UInt8]

    public init(
        method: String,
        path: String,
        headers: [String: String],
        body: [UInt8]
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
    }
}

public struct MediaUploadHTTPResponse: Equatable, Sendable {
    public let statusCode: Int
    public let remoteAssetID: String?

    public init(statusCode: Int, remoteAssetID: String? = nil) {
        self.statusCode = statusCode
        self.remoteAssetID = remoteAssetID
    }
}

public enum MediaUploadTransportOutcome: Equatable, Sendable {
    case response(MediaUploadHTTPResponse)
    case connectionLost
}

public struct ScriptedMediaUploadTransport: Equatable, Sendable {
    public private(set) var requests: [MediaUploadHTTPRequest] = []

    private var outcomes: [MediaUploadTransportOutcome]

    public init(outcomes: [MediaUploadTransportOutcome]) {
        self.outcomes = outcomes
    }

    public mutating func send(
        _ request: MediaUploadHTTPRequest
    ) throws -> MediaUploadHTTPResponse {
        requests.append(request)

        guard !outcomes.isEmpty else {
            throw MediaUploadError.transportUnavailable
        }

        switch outcomes.removeFirst() {
        case let .response(response):
            return response
        case .connectionLost:
            throw MediaUploadError.transportUnavailable
        }
    }
}

public struct MediaUploadReceipt: Equatable, Sendable {
    public let uploadID: String
    public let remoteAssetID: String

    public init(uploadID: String, remoteAssetID: String) {
        self.uploadID = uploadID
        self.remoteAssetID = remoteAssetID
    }
}

public enum MediaUploadMetricOutcome: Equatable, Sendable {
    case completed(remoteAssetID: String)
    case failed(MediaUploadFailureReason)
}

public enum MediaUploadFailureReason: Equatable, Sendable {
    case transportUnavailable
    case rejected(statusCode: Int)
    case malformedSuccess
}

public struct MediaUploadMetric: Equatable, Sendable {
    public let uploadID: String
    public let attemptCount: Int
    public let outcome: MediaUploadMetricOutcome

    public init(
        uploadID: String,
        attemptCount: Int,
        outcome: MediaUploadMetricOutcome
    ) {
        self.uploadID = uploadID
        self.attemptCount = attemptCount
        self.outcome = outcome
    }
}

public struct MediaUploadMetrics: Equatable, Sendable {
    public private(set) var events: [MediaUploadMetric] = []

    public init() {}

    public mutating func record(_ metric: MediaUploadMetric) {
        events.append(metric)
    }
}

public enum MediaUploadError: Error, Equatable, Sendable {
    case missingUploadID
    case invalidDestinationPath
    case emptyPayload
    case missingContentType
    case missingAccessToken
    case invalidRetryLimit
    case transportUnavailable
    case rejected(statusCode: Int)
    case missingRemoteAssetID
}

public struct DirectMediaUploadClient: Equatable, Sendable {
    public private(set) var transport: ScriptedMediaUploadTransport
    public private(set) var metrics = MediaUploadMetrics()

    private let accessToken: String
    private let retryLimit: Int

    public init(
        accessToken: String,
        retryLimit: Int,
        transport: ScriptedMediaUploadTransport
    ) throws {
        guard !accessToken.isEmpty else {
            throw MediaUploadError.missingAccessToken
        }
        guard retryLimit >= 0 else {
            throw MediaUploadError.invalidRetryLimit
        }

        self.accessToken = accessToken
        self.retryLimit = retryLimit
        self.transport = transport
    }

    public mutating func upload(
        _ media: CreatorMediaUpload
    ) throws -> MediaUploadReceipt {
        let request = MediaUploadHTTPRequest(
            method: "POST",
            path: media.destinationPath,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": media.contentType,
                "X-Upload-ID": media.id
            ],
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
                guard attemptCount <= retryLimit else {
                    recordFailure(
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
            recordFailure(
                .rejected(statusCode: response.statusCode),
                uploadID: uploadID,
                attemptCount: attemptCount
            )
            throw MediaUploadError.rejected(statusCode: response.statusCode)
        }
        guard let remoteAssetID = response.remoteAssetID,
              !remoteAssetID.isEmpty else {
            recordFailure(
                .malformedSuccess,
                uploadID: uploadID,
                attemptCount: attemptCount
            )
            throw MediaUploadError.missingRemoteAssetID
        }

        metrics.record(
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

    private mutating func recordFailure(
        _ reason: MediaUploadFailureReason,
        uploadID: String,
        attemptCount: Int
    ) {
        metrics.record(
            MediaUploadMetric(
                uploadID: uploadID,
                attemptCount: attemptCount,
                outcome: .failed(reason)
            )
        )
    }
}
