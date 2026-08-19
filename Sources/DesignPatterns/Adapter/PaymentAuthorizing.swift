public protocol PaymentAuthorizing: Sendable {
    func authorize(_ request: PaymentRequest) async throws -> PaymentAuthorization
}
