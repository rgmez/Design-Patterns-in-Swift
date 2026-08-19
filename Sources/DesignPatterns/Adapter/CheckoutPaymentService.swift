public enum CheckoutPaymentProvider: Sendable {
    case atlas(AtlasPayClient)
    case boreal(BorealPayGateway)
}

public struct CheckoutPaymentService: Sendable {
    private let provider: CheckoutPaymentProvider

    public init(provider: CheckoutPaymentProvider) {
        self.provider = provider
    }

    public func authorize(_ request: PaymentRequest) async throws -> PaymentAuthorization {
        guard request.amountInMinorUnits > 0, !request.paymentToken.isEmpty else {
            throw PaymentError.invalidRequest
        }

        switch provider {
        case let .atlas(client):
            return try await authorizeWithAtlas(request, client: client)
        case let .boreal(gateway):
            return try await authorizeWithBoreal(request, gateway: gateway)
        }
    }

    private func authorizeWithAtlas(
        _ request: PaymentRequest,
        client: AtlasPayClient
    ) async throws -> PaymentAuthorization {
        let atlasRequest = AtlasChargeRequest(
            merchantReference: request.orderID,
            minorAmount: request.amountInMinorUnits,
            currencyCode: request.currency,
            sourceToken: request.paymentToken
        )

        do {
            let result = try await client.submit(atlasRequest)

            switch result.status {
            case .approved:
                return PaymentAuthorization(
                    paymentID: result.chargeID,
                    orderID: request.orderID
                )
            case .rejected:
                throw PaymentError.declined
            }
        } catch let error as PaymentError {
            throw error
        } catch let error as AtlasPayError {
            switch error {
            case .invalidSource:
                throw PaymentError.invalidRequest
            case .transportFailure, .serviceUnavailable:
                throw PaymentError.temporarilyUnavailable
            }
        } catch {
            throw PaymentError.temporarilyUnavailable
        }
    }

    private func authorizeWithBoreal(
        _ request: PaymentRequest,
        gateway: BorealPayGateway
    ) async throws -> PaymentAuthorization {
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
