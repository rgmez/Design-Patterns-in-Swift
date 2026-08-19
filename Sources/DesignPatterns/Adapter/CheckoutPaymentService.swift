public struct CheckoutPaymentService: Sendable {
    private let authorizer: any PaymentAuthorizing

    public init(authorizer: any PaymentAuthorizing) {
        self.authorizer = authorizer
    }

    public func authorize(_ request: PaymentRequest) async throws -> PaymentAuthorization {
        guard request.amountInMinorUnits > 0, !request.paymentToken.isEmpty else {
            throw PaymentError.invalidRequest
        }

        return try await authorizer.authorize(request)
    }
}
