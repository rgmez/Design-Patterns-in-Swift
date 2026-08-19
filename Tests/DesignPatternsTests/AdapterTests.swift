import DesignPatterns
import Testing

@Suite("Adapter")
struct AdapterTests {
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

    @Suite("Atlas adapter")
    struct Atlas {
        @Test("Maps Atlas approval to the checkout contract")
        func mapsApproval() async throws {
            let recorder = RequestRecorder<AtlasChargeRequest>()
            let client = AtlasPayClient { request in
                await recorder.record(request)
                return AtlasChargeResult(chargeID: "atlas-charge-7", status: .approved)
            }
            let service = CheckoutPaymentService(authorizer: AtlasPayAdapter(client: client))

            let authorization = try await service.authorize(AdapterTests.validRequest)

            #expect(authorization == PaymentAuthorization(
                paymentID: "atlas-charge-7",
                orderID: AdapterTests.orderID
            ))
            #expect(await recorder.values == [
                AtlasChargeRequest(
                    merchantReference: AdapterTests.orderID,
                    minorAmount: AdapterTests.amountInMinorUnits,
                    currencyCode: AdapterTests.currency,
                    sourceToken: AdapterTests.paymentToken
                )
            ])
        }

        @Test("Translates Atlas rejection without leaking its reason code")
        func mapsRejection() async {
            let client = AtlasPayClient { _ in
                AtlasChargeResult(
                    chargeID: "atlas-charge-8",
                    status: .rejected(reasonCode: "A17")
                )
            }
            let service = CheckoutPaymentService(authorizer: AtlasPayAdapter(client: client))

            await AdapterTests.expectPaymentError(.declined) {
                try await service.authorize(AdapterTests.validRequest)
            }
        }
    }

    @Suite("Boreal adapter")
    struct Boreal {
        @Test("Maps Boreal approval through the same checkout contract")
        func mapsApproval() async throws {
            let recorder = RequestRecorder<BorealAuthorizationInput>()
            let gateway = BorealPayGateway { input in
                await recorder.record(input)
                return .accepted(transactionReference: "boreal-payment-3")
            }
            let service = CheckoutPaymentService(authorizer: BorealPayAdapter(gateway: gateway))

            let authorization = try await service.authorize(AdapterTests.validRequest)

            #expect(authorization == PaymentAuthorization(
                paymentID: "boreal-payment-3",
                orderID: AdapterTests.orderID
            ))
            #expect(await recorder.values == [
                BorealAuthorizationInput(
                    reference: AdapterTests.orderID,
                    amount: AdapterTests.amountInMinorUnits,
                    isoCurrency: AdapterTests.currency,
                    credential: AdapterTests.paymentToken
                )
            ])
        }

        @Test("Maps Boreal pending state to a retryable domain error")
        func mapsPending() async {
            let gateway = BorealPayGateway { _ in .pending }
            let service = CheckoutPaymentService(authorizer: BorealPayAdapter(gateway: gateway))

            await AdapterTests.expectPaymentError(.temporarilyUnavailable) {
                try await service.authorize(AdapterTests.validRequest)
            }
        }
    }

    @Suite("Checkout boundary")
    struct Checkout {
        @Test("Rejects invalid input before invoking an adapter", arguments: [
            PaymentRequest(
                orderID: AdapterTests.orderID,
                amountInMinorUnits: 0,
                currency: AdapterTests.currency,
                paymentToken: AdapterTests.paymentToken
            ),
            PaymentRequest(
                orderID: AdapterTests.orderID,
                amountInMinorUnits: AdapterTests.amountInMinorUnits,
                currency: AdapterTests.currency,
                paymentToken: ""
            )
        ])
        func validatesRequest(_ request: PaymentRequest) async {
            let recorder = RequestRecorder<AtlasChargeRequest>()
            let client = AtlasPayClient { request in
                await recorder.record(request)
                return AtlasChargeResult(chargeID: "unexpected", status: .approved)
            }
            let service = CheckoutPaymentService(authorizer: AtlasPayAdapter(client: client))

            await AdapterTests.expectPaymentError(.invalidRequest) {
                try await service.authorize(request)
            }
            #expect(await recorder.values.isEmpty)
        }

        @Test("Can swap providers without changing checkout")
        func swapsProviderAtCompositionRoot() async throws {
            let atlasClient = AtlasPayClient { _ in
                AtlasChargeResult(chargeID: "atlas-charge-9", status: .approved)
            }
            let borealGateway = BorealPayGateway { _ in
                .accepted(transactionReference: "boreal-payment-4")
            }

            let atlasAuthorization = try await CheckoutPaymentService(
                authorizer: AtlasPayAdapter(client: atlasClient)
            ).authorize(AdapterTests.validRequest)
            let borealAuthorization = try await CheckoutPaymentService(
                authorizer: BorealPayAdapter(gateway: borealGateway)
            ).authorize(AdapterTests.validRequest)

            #expect(atlasAuthorization.paymentID == "atlas-charge-9")
            #expect(borealAuthorization.paymentID == "boreal-payment-4")
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
