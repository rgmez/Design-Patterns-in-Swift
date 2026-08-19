public struct BorealAuthorizationInput: Equatable, Sendable {
    public let reference: String
    public let amount: Int
    public let isoCurrency: String
    public let credential: String

    public init(
        reference: String,
        amount: Int,
        isoCurrency: String,
        credential: String
    ) {
        self.reference = reference
        self.amount = amount
        self.isoCurrency = isoCurrency
        self.credential = credential
    }
}

public enum BorealAuthorizationResponse: Equatable, Sendable {
    case accepted(transactionReference: String)
    case denied(code: Int)
    case pending
}

public enum BorealPayFailure: Error, Equatable, Sendable {
    case invalidCredential
    case networkInterrupted
    case gatewayBusy
}

public struct BorealPayGateway: Sendable {
    private let authorizePayment: @Sendable (BorealAuthorizationInput) async throws
        -> BorealAuthorizationResponse

    public init(
        authorizePayment: @escaping @Sendable (BorealAuthorizationInput) async throws
            -> BorealAuthorizationResponse
    ) {
        self.authorizePayment = authorizePayment
    }

    public func authorize(
        payment input: BorealAuthorizationInput
    ) async throws -> BorealAuthorizationResponse {
        try await authorizePayment(input)
    }
}
