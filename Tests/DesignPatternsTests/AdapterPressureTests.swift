import DesignPatterns
import Testing

@Suite("Adapter pressure")
struct AdapterPressureTests {
    private static let orderID = "order-1042"
    private static let amountInMinorUnits = 2_599
    private static let currency = "EUR"
    private static let paymentToken = "checkout-token"
    private static let validRequest = PaymentRequest(
        orderID: orderID,
        amountInMinorUnits: amountInMinorUnits,
        currency: currency,
        paymentToken: paymentToken
    )

    @Suite("Atlas integration")
    struct Atlas {
        @Test("Atlas receives every payment field and maps an approval")
        func mapsRequestAndApproval() async throws {
            let recorder = RequestRecorder<AtlasChargeRequest>()
            let client = AtlasPayClient { request in
                await recorder.record(request)
                return AtlasChargeResult(chargeID: "atlas-charge-7", status: .approved)
            }
            let service = CheckoutPaymentService(provider: .atlas(client))

            let authorization = try await service.authorize(AdapterPressureTests.validRequest)
            let recordedRequests = await recorder.values

            #expect(recordedRequests == [
                AtlasChargeRequest(
                    merchantReference: AdapterPressureTests.orderID,
                    minorAmount: AdapterPressureTests.amountInMinorUnits,
                    currencyCode: AdapterPressureTests.currency,
                    sourceToken: AdapterPressureTests.paymentToken
                )
            ])
            #expect(authorization == PaymentAuthorization(
                paymentID: "atlas-charge-7",
                orderID: AdapterPressureTests.orderID
            ))
        }

        @Test("Atlas rejection hides its vendor reason")
        func mapsRejection() async {
            let client = AtlasPayClient { _ in
                AtlasChargeResult(
                    chargeID: "atlas-charge-8",
                    status: .rejected(reasonCode: "A17")
                )
            }
            let service = CheckoutPaymentService(provider: .atlas(client))

            await AdapterPressureTests.expectPaymentError(.declined) {
                try await service.authorize(AdapterPressureTests.validRequest)
            }
        }

        @Test("Atlas infrastructure failures share one retryable domain error", arguments: [
            AtlasPayError.transportFailure,
            AtlasPayError.serviceUnavailable
        ])
        func mapsInfrastructureFailure(_ vendorError: AtlasPayError) async {
            let client = AtlasPayClient { _ in throw vendorError }
            let service = CheckoutPaymentService(provider: .atlas(client))

            await AdapterPressureTests.expectPaymentError(.temporarilyUnavailable) {
                try await service.authorize(AdapterPressureTests.validRequest)
            }
        }
    }

    @Suite("Boreal integration")
    struct Boreal {
        @Test("Boreal forces a second request and result mapping branch")
        func mapsRequestAndApproval() async throws {
            let recorder = RequestRecorder<BorealAuthorizationInput>()
            let gateway = BorealPayGateway { input in
                await recorder.record(input)
                return .accepted(transactionReference: "boreal-payment-3")
            }
            let service = CheckoutPaymentService(provider: .boreal(gateway))

            let authorization = try await service.authorize(AdapterPressureTests.validRequest)
            let recordedInputs = await recorder.values

            #expect(recordedInputs == [
                BorealAuthorizationInput(
                    reference: AdapterPressureTests.orderID,
                    amount: AdapterPressureTests.amountInMinorUnits,
                    isoCurrency: AdapterPressureTests.currency,
                    credential: AdapterPressureTests.paymentToken
                )
            ])
            #expect(authorization == PaymentAuthorization(
                paymentID: "boreal-payment-3",
                orderID: AdapterPressureTests.orderID
            ))
        }

        @Test("Boreal pending and infrastructure outcomes stay in domain vocabulary")
        func mapsTemporaryFailure() async {
            let gateway = BorealPayGateway { _ in .pending }
            let service = CheckoutPaymentService(provider: .boreal(gateway))

            await AdapterPressureTests.expectPaymentError(.temporarilyUnavailable) {
                try await service.authorize(AdapterPressureTests.validRequest)
            }
        }
    }

    @Suite("Domain validation")
    struct Validation {
        @Test("Invalid domain input never reaches Atlas", arguments: [
            PaymentRequest(
                orderID: AdapterPressureTests.orderID,
                amountInMinorUnits: 0,
                currency: AdapterPressureTests.currency,
                paymentToken: AdapterPressureTests.paymentToken
            ),
            PaymentRequest(
                orderID: AdapterPressureTests.orderID,
                amountInMinorUnits: AdapterPressureTests.amountInMinorUnits,
                currency: AdapterPressureTests.currency,
                paymentToken: ""
            )
        ])
        func doesNotReachAtlas(_ request: PaymentRequest) async {
            let recorder = RequestRecorder<AtlasChargeRequest>()
            let client = AtlasPayClient { request in
                await recorder.record(request)
                return AtlasChargeResult(chargeID: "unexpected", status: .approved)
            }
            let service = CheckoutPaymentService(provider: .atlas(client))

            await AdapterPressureTests.expectPaymentError(.invalidRequest) {
                try await service.authorize(request)
            }
            let recordedRequests = await recorder.values
            #expect(recordedRequests.isEmpty)
        }
    }

    private static func expectPaymentError(
        _ expectedError: PaymentError,
        operation: () async throws -> PaymentAuthorization
    ) async {
        do {
            _ = try await operation()
            Issue.record("Expected \(expectedError), but authorization succeeded")
        } catch let error as PaymentError {
            #expect(error == expectedError)
        } catch {
            Issue.record("Expected \(expectedError), got \(error)")
        }
    }
}

private actor RequestRecorder<Value: Sendable> {
    private(set) var values: [Value] = []

    func record(_ value: Value) {
        values.append(value)
    }
}
