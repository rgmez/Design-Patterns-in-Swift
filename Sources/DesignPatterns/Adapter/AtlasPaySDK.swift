public struct AtlasChargeRequest: Equatable, Sendable {
    public let merchantReference: String
    public let minorAmount: Int
    public let currencyCode: String
    public let sourceToken: String

    public init(
        merchantReference: String,
        minorAmount: Int,
        currencyCode: String,
        sourceToken: String
    ) {
        self.merchantReference = merchantReference
        self.minorAmount = minorAmount
        self.currencyCode = currencyCode
        self.sourceToken = sourceToken
    }
}

public struct AtlasChargeResult: Equatable, Sendable {
    public let chargeID: String
    public let status: AtlasChargeStatus

    public init(chargeID: String, status: AtlasChargeStatus) {
        self.chargeID = chargeID
        self.status = status
    }
}

public enum AtlasChargeStatus: Equatable, Sendable {
    case approved
    case rejected(reasonCode: String)
}

public enum AtlasPayError: Error, Equatable, Sendable {
    case invalidSource
    case transportFailure
    case serviceUnavailable
}

public struct AtlasPayClient: Sendable {
    private let submitCharge: @Sendable (AtlasChargeRequest) async throws -> AtlasChargeResult

    public init(
        submitCharge: @escaping @Sendable (AtlasChargeRequest) async throws -> AtlasChargeResult
    ) {
        self.submitCharge = submitCharge
    }

    public func submit(_ request: AtlasChargeRequest) async throws -> AtlasChargeResult {
        try await submitCharge(request)
    }
}
