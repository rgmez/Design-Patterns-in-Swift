import DesignPatterns
import Testing

@Suite("Facade problem")
struct FacadeProblemTests {
    private static let checkoutID = "checkout-1042"
    private static let customerID = "customer-17"
    private static let coffeeSKU = "coffee-beans-1kg"
    private static let filterSKU = "paper-filters-100"
    private static let coffeeQuantity = 2
    private static let filterQuantity = 1
    private static let coffeePrice = 1_299
    private static let filterPrice = 499
    private static let initialCoffeeStock = 4
    private static let initialFilterStock = 10
    private static let acceptedToken = "card-token-approved"
    private static let declinedToken = "card-token-declined"
    private static let expectedTotal = 3_097
    private static let expectedReservationID = "reservation-checkout-1042"
    private static let expectedPaymentID = "payment-checkout-1042"
    private static let expectedOrderID = "order-checkout-1042"

    private static func makeItems(
        coffeeQuantity: Int = FacadeProblemTests.coffeeQuantity
    ) throws -> [CheckoutLineItem] {
        [
            try CheckoutLineItem(
                sku: coffeeSKU,
                quantity: coffeeQuantity,
                unitPriceInMinorUnits: coffeePrice
            ),
            try CheckoutLineItem(
                sku: filterSKU,
                quantity: filterQuantity,
                unitPriceInMinorUnits: filterPrice
            )
        ]
    }

    private static func makeSubmission(
        coffeeQuantity: Int = FacadeProblemTests.coffeeQuantity,
        paymentToken: String = FacadeProblemTests.acceptedToken
    ) throws -> CheckoutSubmission {
        try CheckoutSubmission(
            checkoutID: checkoutID,
            customerID: customerID,
            items: makeItems(coffeeQuantity: coffeeQuantity),
            paymentToken: paymentToken
        )
    }

    private static func makeScreen(
        declinedTokens: Set<String> = []
    ) -> DirectCheckoutScreen {
        DirectCheckoutScreen(
            inventory: CheckoutInventory(
                availableQuantityBySKU: [
                    coffeeSKU: initialCoffeeStock,
                    filterSKU: initialFilterStock
                ]
            ),
            payments: CheckoutPayments(declinedTokens: declinedTokens)
        )
    }

    @Suite("Successful checkout")
    struct SuccessfulCheckout {
        @Test("Coordinates inventory, payment, order, and analytics")
        func coordinatesSubsystems() throws {
            let submission = try FacadeProblemTests.makeSubmission()
            var screen = FacadeProblemTests.makeScreen()

            let order = try screen.placeOrder(from: submission)

            #expect(order.id == FacadeProblemTests.expectedOrderID)
            #expect(
                order.reservationID
                    == FacadeProblemTests.expectedReservationID
            )
            #expect(
                order.paymentAuthorizationID
                    == FacadeProblemTests.expectedPaymentID
            )
            #expect(
                order.totalInMinorUnits
                    == FacadeProblemTests.expectedTotal
            )
            #expect(screen.inventory.reservationAttempts == 1)
            #expect(screen.payments.authorizationAttempts == 1)
            #expect(screen.orders.orders == [order])
        }

        @Test("Decrements stock and keeps the successful reservation")
        func keepsSuccessfulReservation() throws {
            var screen = FacadeProblemTests.makeScreen()

            _ = try screen.placeOrder(
                from: FacadeProblemTests.makeSubmission()
            )

            #expect(
                screen.inventory.availableQuantity(
                    for: FacadeProblemTests.coffeeSKU
                )
                    == FacadeProblemTests.initialCoffeeStock
                        - FacadeProblemTests.coffeeQuantity
            )
            #expect(
                screen.inventory.hasReservation(
                    id: FacadeProblemTests.expectedReservationID
                )
            )
            #expect(screen.inventory.releaseCount == 0)
        }

        @Test("Records one completion after order creation")
        func recordsCompletion() throws {
            var screen = FacadeProblemTests.makeScreen()

            _ = try screen.placeOrder(
                from: FacadeProblemTests.makeSubmission()
            )

            #expect(
                screen.analytics.events == [
                    .completed(
                        checkoutID: FacadeProblemTests.checkoutID,
                        orderID: FacadeProblemTests.expectedOrderID,
                        totalInMinorUnits: FacadeProblemTests.expectedTotal
                    )
                ]
            )
        }
    }

    @Suite("Failed checkout")
    struct FailedCheckout {
        @Test("Stops before payment when inventory is insufficient")
        func stopsAfterInventoryFailure() throws {
            let unavailableQuantity = FacadeProblemTests.initialCoffeeStock + 1
            var screen = FacadeProblemTests.makeScreen()

            #expect(
                throws: CheckoutError.insufficientStock(
                    sku: FacadeProblemTests.coffeeSKU
                )
            ) {
                try screen.placeOrder(
                    from: FacadeProblemTests.makeSubmission(
                        coffeeQuantity: unavailableQuantity
                    )
                )
            }
            #expect(screen.inventory.reservationAttempts == 1)
            #expect(screen.payments.authorizationAttempts == 0)
            #expect(screen.orders.orders.isEmpty)
            #expect(
                screen.analytics.events == [
                    .failed(
                        checkoutID: FacadeProblemTests.checkoutID,
                        reason: .inventoryUnavailable
                    )
                ]
            )
        }

        @Test("Rejects duplicate lines whose combined quantity exceeds stock")
        func aggregatesDuplicateLineQuantities() throws {
            let firstLineQuantity = 3
            let secondLineQuantity = 2
            let items = [
                try CheckoutLineItem(
                    sku: FacadeProblemTests.coffeeSKU,
                    quantity: firstLineQuantity,
                    unitPriceInMinorUnits: FacadeProblemTests.coffeePrice
                ),
                try CheckoutLineItem(
                    sku: FacadeProblemTests.coffeeSKU,
                    quantity: secondLineQuantity,
                    unitPriceInMinorUnits: FacadeProblemTests.coffeePrice
                )
            ]
            let submission = try CheckoutSubmission(
                checkoutID: FacadeProblemTests.checkoutID,
                customerID: FacadeProblemTests.customerID,
                items: items,
                paymentToken: FacadeProblemTests.acceptedToken
            )
            var screen = FacadeProblemTests.makeScreen()

            #expect(
                throws: CheckoutError.insufficientStock(
                    sku: FacadeProblemTests.coffeeSKU
                )
            ) {
                try screen.placeOrder(from: submission)
            }
            #expect(
                screen.inventory.availableQuantity(
                    for: FacadeProblemTests.coffeeSKU
                ) == FacadeProblemTests.initialCoffeeStock
            )
            #expect(screen.payments.authorizationAttempts == 0)
        }

        @Test("Releases inventory and skips the order after a declined payment")
        func compensatesForDeclinedPayment() throws {
            var screen = FacadeProblemTests.makeScreen(
                declinedTokens: [FacadeProblemTests.declinedToken]
            )

            #expect(throws: CheckoutError.paymentDeclined) {
                try screen.placeOrder(
                    from: FacadeProblemTests.makeSubmission(
                        paymentToken: FacadeProblemTests.declinedToken
                    )
                )
            }
            #expect(screen.payments.authorizationAttempts == 1)
            #expect(screen.payments.authorizations.isEmpty)
            #expect(screen.orders.orders.isEmpty)
            #expect(screen.inventory.releaseCount == 1)
            #expect(
                screen.inventory.availableQuantity(
                    for: FacadeProblemTests.coffeeSKU
                ) == FacadeProblemTests.initialCoffeeStock
            )
            #expect(
                screen.inventory.hasReservation(
                    id: FacadeProblemTests.expectedReservationID
                ) == false
            )
            #expect(
                screen.analytics.events == [
                    .failed(
                        checkoutID: FacadeProblemTests.checkoutID,
                        reason: .paymentDeclined
                    )
                ]
            )
        }
    }
}

extension FacadeProblemTests {
    struct InvalidItemScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let sku: String
        let quantity: Int
        let price: Int

        var testDescription: String { name }
    }

    @Suite("Input validation")
    struct InputValidation {

        private static let invalidItemScenarios = [
            InvalidItemScenario(
                name: "missing SKU",
                sku: "",
                quantity: FacadeProblemTests.coffeeQuantity,
                price: FacadeProblemTests.coffeePrice
            ),
            InvalidItemScenario(
                name: "zero quantity",
                sku: FacadeProblemTests.coffeeSKU,
                quantity: 0,
                price: FacadeProblemTests.coffeePrice
            ),
            InvalidItemScenario(
                name: "zero price",
                sku: FacadeProblemTests.coffeeSKU,
                quantity: FacadeProblemTests.coffeeQuantity,
                price: 0
            )
        ]

        @Test(
            "Rejects invalid line items",
            arguments: invalidItemScenarios
        )
        func rejectsInvalidItem(_ scenario: InvalidItemScenario) {
            #expect(
                throws: CheckoutError.invalidLineItem(sku: scenario.sku)
            ) {
                try CheckoutLineItem(
                    sku: scenario.sku,
                    quantity: scenario.quantity,
                    unitPriceInMinorUnits: scenario.price
                )
            }
        }

        @Test("Rejects a checkout without items")
        func rejectsEmptyCart() {
            #expect(throws: CheckoutError.emptyCart) {
                try CheckoutSubmission(
                    checkoutID: FacadeProblemTests.checkoutID,
                    customerID: FacadeProblemTests.customerID,
                    items: [],
                    paymentToken: FacadeProblemTests.acceptedToken
                )
            }
        }
    }
}
