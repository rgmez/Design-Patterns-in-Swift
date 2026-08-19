public struct AtlasPayAdapter: PaymentAuthorizing {
    private let client: AtlasPayClient

    public init(client: AtlasPayClient) {
        self.client = client
    }

    public func authorize(_ request: PaymentRequest) async throws -> PaymentAuthorization {
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
}
