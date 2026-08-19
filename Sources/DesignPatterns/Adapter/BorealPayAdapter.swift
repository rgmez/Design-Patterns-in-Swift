public struct BorealPayAdapter: PaymentAuthorizing {
    private let gateway: BorealPayGateway

    public init(gateway: BorealPayGateway) {
        self.gateway = gateway
    }

    public func authorize(_ request: PaymentRequest) async throws -> PaymentAuthorization {
        let borealInput = BorealAuthorizationInput(
            reference: request.orderID,
            amount: request.amountInMinorUnits,
            isoCurrency: request.currency,
            credential: request.paymentToken
        )

        do {
            let response = try await gateway.authorize(payment: borealInput)

            switch response {
            case let .accepted(transactionReference):
                return PaymentAuthorization(
                    paymentID: transactionReference,
                    orderID: request.orderID
                )
            case .denied:
                throw PaymentError.declined
            case .pending:
                throw PaymentError.temporarilyUnavailable
            }
        } catch let error as PaymentError {
            throw error
        } catch let error as BorealPayFailure {
            switch error {
            case .invalidCredential:
                throw PaymentError.invalidRequest
            case .networkInterrupted, .gatewayBusy:
                throw PaymentError.temporarilyUnavailable
            }
        } catch {
            throw PaymentError.temporarilyUnavailable
        }
    }
}
