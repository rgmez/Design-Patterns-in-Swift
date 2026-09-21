import DesignPatterns
import Testing

@Suite("Facade")
struct FacadeTests {
    private static let checkoutID = "checkout-4096"
    private static let customerID = "customer-52"
    private static let sku = "grinder-burr-set"
    private static let quantity = 1
    private static let unitPrice = 8_999
    private static let initialStock = 3
    private static let acceptedToken = "card-token-approved"
    private static let declinedToken = "card-token-declined"
    private static let expectedReservationID = "reservation-checkout-4096"
    private static let expectedPaymentID = "payment-checkout-4096"
    private static let expectedOrderID = "order-checkout-4096"

    enum EntryPoint: String, CaseIterable, Sendable,
        CustomTestStringConvertible {
        case checkoutScreen
        case buyAgain
        case paymentRetry

        var testDescription: String { rawValue }
    }

    private static func makeSubmission(
        paymentToken: String = acceptedToken
    ) throws -> CheckoutSubmission {
        try CheckoutSubmission(
            checkoutID: checkoutID,
            customerID: customerID,
            items: [
                try CheckoutLineItem(
                    sku: sku,
                    quantity: quantity,
                    unitPriceInMinorUnits: unitPrice
                )
            ],
            paymentToken: paymentToken
        )
    }

    private static func makeFacade(
        declinedTokens: Set<String> = []
    ) -> CheckoutFacade {
        CheckoutFacade(
            inventory: CheckoutInventory(
                availableQuantityBySKU: [sku: initialStock]
            ),
            payments: CheckoutPayments(declinedTokens: declinedTokens)
        )
    }

    @Test(
        "Every product entry point uses the same placement boundary",
        arguments: EntryPoint.allCases
    )
    func sharesOnePlacementBoundary(_: EntryPoint) throws {
        var checkout = FacadeTests.makeFacade()

        let order = try checkout.placeOrder(
            from: FacadeTests.makeSubmission()
        )

        #expect(order.id == FacadeTests.expectedOrderID)
        #expect(order.reservationID == FacadeTests.expectedReservationID)
        #expect(
            order.paymentAuthorizationID == FacadeTests.expectedPaymentID
        )
        #expect(checkout.orders.orders == [order])
        #expect(
            checkout.analytics.events == [
                .completed(
                    checkoutID: FacadeTests.checkoutID,
                    orderID: FacadeTests.expectedOrderID,
                    totalInMinorUnits: FacadeTests.unitPrice
                )
            ]
        )
    }

    @Test("Inventory rejection stops the facade before payment")
    func stopsAfterInventoryFailure() throws {
        let unavailableQuantity = FacadeTests.initialStock + 1
        let submission = try CheckoutSubmission(
            checkoutID: FacadeTests.checkoutID,
            customerID: FacadeTests.customerID,
            items: [
                try CheckoutLineItem(
                    sku: FacadeTests.sku,
                    quantity: unavailableQuantity,
                    unitPriceInMinorUnits: FacadeTests.unitPrice
                )
            ],
            paymentToken: FacadeTests.acceptedToken
        )
        var checkout = FacadeTests.makeFacade()

        #expect(
            throws: CheckoutError.insufficientStock(sku: FacadeTests.sku)
        ) {
            try checkout.placeOrder(from: submission)
        }

        #expect(checkout.payments.authorizationAttempts == 0)
        #expect(checkout.orders.orders.isEmpty)
        #expect(
            checkout.analytics.events == [
                .failed(
                    checkoutID: FacadeTests.checkoutID,
                    reason: .inventoryUnavailable
                )
            ]
        )
    }

    @Test("Payment decline triggers the facade's one compensation path")
    func compensatesAfterPaymentDecline() throws {
        var checkout = FacadeTests.makeFacade(
            declinedTokens: [FacadeTests.declinedToken]
        )

        #expect(throws: CheckoutError.paymentDeclined) {
            try checkout.placeOrder(
                from: FacadeTests.makeSubmission(
                    paymentToken: FacadeTests.declinedToken
                )
            )
        }

        #expect(checkout.inventory.releaseCount == 1)
        #expect(
            checkout.inventory.availableQuantity(for: FacadeTests.sku)
                == FacadeTests.initialStock
        )
        #expect(
            checkout.inventory.hasReservation(
                id: FacadeTests.expectedReservationID
            ) == false
        )
        #expect(checkout.orders.orders.isEmpty)
        #expect(
            checkout.analytics.events == [
                .failed(
                    checkoutID: FacadeTests.checkoutID,
                    reason: .paymentDeclined
                )
            ]
        )
    }

    @Test("Lower-level components remain available outside the facade")
    func retainsSubsystemAccess() throws {
        var inventory = CheckoutInventory(
            availableQuantityBySKU: [FacadeTests.sku: FacadeTests.initialStock]
        )

        let reservation = try inventory.reserve(
            FacadeTests.makeSubmission().items,
            for: FacadeTests.checkoutID
        )

        #expect(reservation.id == FacadeTests.expectedReservationID)
        #expect(
            inventory.availableQuantity(for: FacadeTests.sku)
                == FacadeTests.initialStock - FacadeTests.quantity
        )
    }
}
